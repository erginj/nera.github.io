local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local seeds = {
    "Carrot","Strawberry","Blueberry","Orange Tulip","Tomato","Corn",
    "Daffodil","Watermelon","Pumpkin","Apple","Bamboo","Coconut",
    "Cactus","Dragon Fruit","Mango","Grape","Mushroom","Pepper",
    "Cacao","Beanstalk","Ember Lily"
}

local Window = WindUI:CreateWindow({
    Title = "RINGTA SCRIPTS",
    Icon = "star",
    Author = "ringta",
    Theme = "Dark",
    Size = UDim2.fromOffset(500, 350),
    HasOutline = true,
})

Window:EditOpenButton({
    Title = "Open RINGTA SCRIPTS",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 6),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(255, 255, 255)),
    Draggable = true,
})

local AutobuyTab = Window:Tab({ Title = "Autobuy", Icon = "shopping-cart" })

local autobuy_selected = {}
for _, seed in ipairs(seeds) do
    autobuy_selected[seed] = false
end

local autobuy_running = false
local autobuy_thread

-- Main switch at the very top
AutobuyTab:Toggle({
    Title = "⚡ AUTOBUY (Main Switch)",
    Icon = "zap", 
    Default = false,
    Callback = function(state)
        autobuy_running = state
        if autobuy_running then
            autobuy_thread = task.spawn(function()
                while autobuy_running do
                    for seed, selected in pairs(autobuy_selected) do
                        if selected then
                            ReplicatedStorage.GameEvents.BuySeedStock:FireServer(seed)
                            task.wait(0.1)
                        end
                    end
                    task.wait(0.2)
                end
            end)
        else
            if autobuy_thread then
                task.cancel(autobuy_thread)
                autobuy_thread = nil
            end
        end
    end
})

-- Divider/section to visually group the seed toggles
AutobuyTab:Section({ Title = "Select seeds to autobuy:" })

-- Individual toggles for each seed
for _, seed in ipairs(seeds) do
    AutobuyTab:Toggle({
        Title = seed,
        Default = false,
        Callback = function(state)
            autobuy_selected[seed] = state
        end
    })
end

-- Money section remains at the bottom
local leaderstats = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:WaitForChild("leaderstats")
local shecklesStat = leaderstats:FindFirstChild("Sheckles") or leaderstats:WaitForChild("Sheckles")
local moneySection = AutobuyTab:Section({
    Title = "💸 Sheckles: " .. tostring(shecklesStat.Value)
})

spawn(function()
    while true do
        if moneySection and moneySection.SetTitle then
            moneySection:SetTitle("💸 Sheckles: " .. tostring(shecklesStat.Value))
        end
        wait(1)
    end
end)


-- Assumes you already have WindUI, seeds table, etc. from your main script!

local AutoplantTab = Window:Tab({ Title = "Autoplant", Icon = "leaf" })

local autoplant_selected = {}
for _, seed in ipairs(seeds) do
    autoplant_selected[seed] = false
end

local autoplant_running = false
local autoplant_thread

AutoplantTab:Toggle({
    Title = "⚡ AUTOPLANT (Main Switch)",
    Icon = "zap",
    Default = false,
    Callback = function(state)
        autoplant_running = state
        if autoplant_running then
            autoplant_thread = task.spawn(function()
                local function get_autoplant_list()
                    local t = {}
                    for _, seed in ipairs(seeds) do
                        if autoplant_selected[seed] then
                            table.insert(t, seed)
                        end
                    end
                    return t
                end

                local function getMyFarm()
                    for _, farm in pairs(workspace.Farm:GetChildren()) do
                        local data = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
                        if data and data:FindFirstChild("Owner") and data.Owner.Value == LocalPlayer.Name then
                            return farm
                        end
                    end
                    return nil
                end

                local function getCanPlantParts()
                    local myFarm = getMyFarm()
                    local canPlant = {}
                    if myFarm then
                        local plantLocations = myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plant_Locations")
                        if plantLocations then
                            for _, part in ipairs(plantLocations:GetDescendants()) do
                                if part:IsA("BasePart") and part.Name:find("Can_Plant") then
                                    table.insert(canPlant, part)
                                end
                            end
                        end
                    end
                    return canPlant
                end

                local function getRandomPosition(part)
                    local offset = Vector3.new(
                        math.random(-part.Size.X/2, part.Size.X/2),
                        0,
                        math.random(-part.Size.Z/2, part.Size.Z/2)
                    )
                    return part.Position + offset + Vector3.new(0, 2, 0)
                end

                local function getSeedTool(seedName)
                    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                        if item:GetAttribute("ITEM_TYPE") == "Seed" and item:GetAttribute("Seed") == seedName then
                            return item
                        end
                    end
                    local char = LocalPlayer.Character
                    if char then
                        for _, item in ipairs(char:GetChildren()) do
                            if item:IsA("Tool") and item:GetAttribute("ITEM_TYPE") == "Seed" and item:GetAttribute("Seed") == seedName then
                                return item
                            end
                        end
                    end
                    return nil
                end

                local function equipSeed(tool)
                    if tool and LocalPlayer.Character then
                        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid and tool.Parent ~= LocalPlayer.Character then
                            humanoid:EquipTool(tool)
                            task.wait(0.07)
                        end
                    end
                end

                local function isInventoryFull()
                    return #LocalPlayer.Backpack:GetChildren() >= 200
                end

                while autoplant_running do
                    if isInventoryFull() then
                        WindUI:Notify({ Title = "Autoplant", Content = "Backpack is full! Waiting..." })
                        repeat
                            task.wait(0.5)
                        until not isInventoryFull() or not autoplant_running
                    end
                    if not autoplant_running then break end

                    local list = get_autoplant_list()
                    if #list == 0 then
                        task.wait(0.7)
                        continue
                    end

                    local plantParts = getCanPlantParts()
                    if #plantParts == 0 then
                        task.wait(0.7)
                        continue
                    end

                    for _, seedName in ipairs(list) do
                        local tool = getSeedTool(seedName)
                        if tool then
                            equipSeed(tool)
                            -- Try to plant at random spots up to N times
                            local maxTries = #plantParts * 2
                            for i = 1, maxTries do
                                if not autoplant_running or isInventoryFull() then return end
                                local spot = plantParts[math.random(1, #plantParts)]
                                local pos = getRandomPosition(spot)
                                -- Try to plant
                                ReplicatedStorage.GameEvents.Plant_RE:FireServer(pos, seedName)
                                task.wait(0.12)
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- Divider label
AutoplantTab:Section({ Title = "Select seeds to autoplant:" })

for _, seed in ipairs(seeds) do
    AutoplantTab:Toggle({
        Title = seed,
        Default = false,
        Callback = function(state)
            autoplant_selected[seed] = state
        end
    })
end


-- AUTOFARM TAB (WindUI version, plug into your script after seeds/Window/ReplicatedStorage/LocalPlayer are defined)
local UserInputService = game:GetService("UserInputService")

local AutofarmTab = Window:Tab({ Title = "Autofarm", Icon = "tractor" })

-- === AUTOFARM LABEL ===
AutofarmTab:Section({ Title = "Autofarm Features" })

-- === AUTOCOLLECT ===
local collecting = false
local collect_thread

local function getMyFarm()
    for _, farm in pairs(workspace.Farm:GetChildren()) do
        local data = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
        if data and data:FindFirstChild("Owner") and data.Owner.Value == LocalPlayer.Name then
            return farm
        end
    end
end

local function getMyHarvestableCrops()
    local myFarm, crops = getMyFarm(), {}
    if myFarm then
        local plants = myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plants_Physical")
        if plants then
            for _, plant in pairs(plants:GetChildren()) do
                for _, part in pairs(plant:GetDescendants()) do
                    local pr = part:IsA("BasePart") and part:FindFirstChildOfClass("ProximityPrompt")
                    if pr then pr.MaxActivationDistance = 1000 table.insert(crops, part) break end
                end
            end
        end
    end
    return crops
end

local function autoCollectLoop()
    local tp_interval, pr_delay = 7, 0.1
    while collecting do
        local crops = getMyHarvestableCrops()
        if #crops > 0 then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local crop = crops[math.random(1, #crops)]
            if hrp and crop then hrp.CFrame = CFrame.new(crop.Position + Vector3.new(0, 3, 0)) end
            for _, c in ipairs(crops) do
                local pr = c:FindFirstChildOfClass("ProximityPrompt")
                if pr then pcall(function() fireproximityprompt(pr) end) task.wait(pr_delay) end
            end
        end
        task.wait(tp_interval)
    end
end

AutofarmTab:Toggle({
    Title = "Autocollect (auto-harvest crops)",
    Icon = "recycle",
    Default = false,
    Callback = function(state)
        collecting = state
        if collecting then
            collect_thread = task.spawn(autoCollectLoop)
        else
            if collect_thread then
                task.cancel(collect_thread)
                collect_thread = nil
            end
        end
    end
})

-- === AUTOSELL INTERVAL SLIDER & TOGGLE ===
local autosell_interval = 5 -- default seconds
AutofarmTab:Section({ Title = "Autosell every "..tostring(autosell_interval).." seconds" })
local sectionObj = nil

-- WindUI does not always have a true slider, so a dropdown can be used for intervals:
local interval_choices = {}
for i=1,60 do table.insert(interval_choices, tostring(i)) end

AutofarmTab:Dropdown({
    Title = "Set Autosell Interval (seconds)",
    Values = interval_choices,
    Default = tostring(autosell_interval),
    Callback = function(v)
        autosell_interval = tonumber(v)
        if sectionObj and sectionObj.SetTitle then
            sectionObj:SetTitle("Autosell every "..tostring(autosell_interval).." seconds")
        end
    end
})

local autosell_running = false
local autosell_thread

AutofarmTab:Toggle({
    Title = "Autosell",
    Icon = "dollar-sign",
    Default = false,
    Callback = function(state)
        autosell_running = state
        if autosell_running then
            autosell_thread = task.spawn(function()
                local GE = ReplicatedStorage.GameEvents
                while autosell_running do
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local pos = hrp.CFrame
                        if workspace:FindFirstChild("Tutorial_Points") and workspace.Tutorial_Points:FindFirstChild("Tutorial_Point_2") then
                            hrp.CFrame = workspace.Tutorial_Points.Tutorial_Point_2.CFrame
                            task.wait(0.2)
                            GE.Sell_Inventory:FireServer()
                            task.wait(0.2)
                            hrp.CFrame = pos
                        end
                    end
                    for i = 1, autosell_interval do
                        if not autosell_running then break end
                        task.wait(1)
                    end
                end
            end)
        else
            if autosell_thread then
                task.cancel(autosell_thread)
                autosell_thread = nil
            end
        end
    end
})



local gears = {
    "Watering Can",
    "Trowel",
    "Recall Wrench",
    "Basic Sprinkler",
    "Advanced Sprinkler",
    "Godly Sprinkler",
    "Lightning Rod",
    "Master Sprinkler",
}

local GearsTab = Window:Tab({ Title = "Gears", Icon = "wrench" })

local autobuy_gear_selected = {}
for _, gear in ipairs(gears) do
    autobuy_gear_selected[gear] = false
end

local autobuy_gear_running = false
local autobuy_gear_thread

GearsTab:Toggle({
    Title = "⚡ AUTOBUY GEARS (Main Switch)",
    Icon = "zap",
    Default = false,
    Callback = function(state)
        autobuy_gear_running = state
        if autobuy_gear_running then
            autobuy_gear_thread = task.spawn(function()
                while autobuy_gear_running do
                    for gear, selected in pairs(autobuy_gear_selected) do
                        if selected then
                            ReplicatedStorage.GameEvents.BuyGearStock:FireServer(gear)
                            task.wait(0.15)
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

GearsTab:Section({ Title = "Select gears to autobuy:" })

for _, gear in ipairs(gears) do
    GearsTab:Toggle({
        Title = gear,
        Default = false,
        Callback = function(state)
            autobuy_gear_selected[gear] = state
        end
    })
end


local honeyShopItems = {
    "Flower Seed Pack",
    "Nectarine",
    "Hive Fruit",
    "Honey Sprinkler",
    "Bee Egg",
    "Bee Crate",
    "Honey Comb",
    "Bee Chair",
    "Honey Torch",
    "Honey Walkway"
}

local EventsTab = Window:Tab({ Title = "Events", Icon = "gift" })

-- Main Autobuy Honey Shop Items Toggle (like Autobuy Seeds)
local autobuy_honey_selected = {}
for _, item in ipairs(honeyShopItems) do
    autobuy_honey_selected[item] = false
end
local autobuy_honey_running = false
local autobuy_honey_thread

EventsTab:Toggle({
    Title = "⚡ AUTOBUY HONEY SHOP ITEMS (Main Switch)",
    Icon = "zap",
    Default = false,
    Callback = function(state)
        autobuy_honey_running = state
        if autobuy_honey_running then
            autobuy_honey_thread = task.spawn(function()
                while autobuy_honey_running do
                    for item, selected in pairs(autobuy_honey_selected) do
                        if selected then
                            ReplicatedStorage.GameEvents.BuyEventShopStock:FireServer(item)
                            task.wait(0.15)
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            if autobuy_honey_thread then
                task.cancel(autobuy_honey_thread)
                autobuy_honey_thread = nil
            end
        end
    end
})

EventsTab:Section({ Title = "Select Honey Shop Items:" })
for _, item in ipairs(honeyShopItems) do
    EventsTab:Toggle({
        Title = item,
        Default = false,
        Callback = function(state)
            autobuy_honey_selected[item] = state
        end
    })
end

EventsTab:Section({ Title = "Shop & Collect Actions:" })

-- Open Shop UI Button (one-time action)
EventsTab:Button({
    Title = "Open Shop UI",
    Icon = "shopping-bag",
    Callback = function()
        local Players = game:GetService("Players")
        local localPlayer = Players.LocalPlayer
        local shop = localPlayer.PlayerGui:FindFirstChild("HoneyEventShop_UI")
        if shop then
            shop.Enabled = not shop.Enabled
        else
            warn("HoneyEventShop_UI not found in PlayerGui!")
        end
    end
})


EventsTab:Section({ Title = "Event ESP / Automation:" })

-- Mutation ESP Toggle
local mutEspRunning = false
local mutEspThread
EventsTab:Toggle({
    Title = "Mutation ESP",
    Icon = "eye",
    Default = false,
    Callback = function(state)
        mutEspRunning = state
        local function clr()
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BillboardGui") and v.Name == "MutationESP" then v:Destroy() end
            end
        end
        local c = {
            Wet=Color3.fromRGB(100,200,255),Gold=Color3.fromRGB(255,215,0),Frozen=Color3.fromRGB(135,206,235),
            Rainbow=Color3.fromRGB(255,0,255),Choc=Color3.fromRGB(120,72,0),Chilled=Color3.fromRGB(170,230,255),
            Shocked=Color3.fromRGB(255,255,100),Moonlit=Color3.fromRGB(150,100,255),Bloodlit=Color3.fromRGB(200,10,60),
            Celestial=Color3.fromRGB(200,255,255),Disco=Color3.fromRGB(255,120,255),Zombified=Color3.fromRGB(80,255,100),
            Plasma=Color3.fromRGB(60,255,255),["Honey Glazed"]=Color3.fromRGB(255,200,75),Pollinated=Color3.fromRGB(225,255,130)
        }
        if mutEspRunning then
            mutEspThread = task.spawn(function()
                local mutations = {
                    "Wet","Gold","Frozen","Rainbow","Choc","Chilled","Shocked","Moonlit","Bloodlit","Celestial",
                    "Disco","Zombified","Plasma","Honey Glazed","Pollinated"
                }
                while mutEspRunning do
                    clr()
                    local function getMyFarm()
                        for _,farm in ipairs(workspace.Farm:GetChildren()) do
                            local d = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
                            if d and d:FindFirstChild("Owner") and d.Owner.Value == game.Players.LocalPlayer.Name then
                                return farm
                            end
                        end
                    end
                    local g = getMyFarm()
                    if g then
                        local pl = g.Important:FindFirstChild("Plants_Physical")
                        if pl then
                            for _, pt in ipairs(pl:GetChildren()) do
                                local fnd = {}
                                for _, mm in ipairs(mutations) do
                                    if pt:GetAttribute(mm) then table.insert(fnd, mm) end
                                end
                                if #fnd > 0 then
                                    local bp = pt:FindFirstChildWhichIsA("BasePart") or pt.PrimaryPart
                                    if bp then
                                        local gui = Instance.new("BillboardGui")
                                        gui.Name = "MutationESP"
                                        gui.Adornee = bp
                                        gui.Size = UDim2.new(0, 100, 0, 20)
                                        gui.AlwaysOnTop = true
                                        gui.StudsOffset = Vector3.new(0, 6, 0)
                                        local lbl = Instance.new("TextLabel", gui)
                                        lbl.Size = UDim2.new(1, 0, 1, 0)
                                        lbl.BackgroundTransparency = 1
                                        lbl.Text = table.concat(fnd, " + ")
                                        lbl.TextColor3 = c[fnd[1]] or Color3.new(1,1,1)
                                        lbl.TextScaled = false
                                        lbl.TextSize = 12
                                        lbl.Font = Enum.Font.GothamBold
                                        gui.Parent = bp
                                    end
                                end
                            end
                        end
                    end
                    task.wait(5)
                end
                clr()
            end)
        else
            if mutEspThread then
                task.cancel(mutEspThread)
                mutEspThread = nil
            end
            clr()
        end
    end
})

-- Honey ESP Toggle
local honeyEspRunning = false
local honeyEspThread
EventsTab:Toggle({
    Title = "Honey ESP",
    Icon = "sun",
    Default = false,
    Callback = function(state)
        honeyEspRunning = state
        local mutationName = "Pollinated"
        local mutationColor = Color3.fromRGB(255, 225, 80)
        local function clearESP()
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BillboardGui") and v.Name=="MutationESP" then v:Destroy() end
            end
        end
        local function getMyFarm()
            for _,farm in ipairs(workspace.Farm:GetChildren()) do
                local d = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
                if d and d:FindFirstChild("Owner") and d.Owner.Value == game.Players.LocalPlayer.Name then
                    return farm
                end
            end
        end
        local function showPollinatedESP()
            clearESP()
            local myFarm = getMyFarm()
            if not myFarm then return end
            local plants = myFarm.Important and myFarm.Important:FindFirstChild("Plants_Physical")
            if not plants then return end
            for _,plant in ipairs(plants:GetChildren()) do
                if plant:GetAttribute(mutationName) then
                    for _,bp in ipairs(plant:GetDescendants()) do
                        if bp:IsA("BasePart") then
                            local gui = Instance.new("BillboardGui")
                            gui.Name = "MutationESP"
                            gui.Adornee = bp
                            gui.Size = UDim2.new(0, 100, 0, 20)
                            gui.AlwaysOnTop = true
                            gui.StudsOffset = Vector3.new(0, 6, 0)
                            local lbl = Instance.new("TextLabel", gui)
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.Text = mutationName
                            lbl.TextColor3 = mutationColor
                            lbl.TextSize = 13
                            lbl.Font = Enum.Font.GothamBold
                            gui.Parent = bp
                        end
                    end
                end
            end
        end
        if honeyEspRunning then
            honeyEspThread = task.spawn(function()
                while honeyEspRunning do
                    showPollinatedESP()
                    task.wait(5)
                end
            end)
        else
            if honeyEspThread then
                task.cancel(honeyEspThread)
                honeyEspThread = nil
            end
            clearESP()
        end
    end
})


EventsTab:Section({ Title = "Auto Honey Farm" })

local AutoCollectHoneyEnabled = false
local AutoGivePlantsEnabled = false

-- Honey Collect Only Toggle
local honeyCollecting = false
local honeyCollectThread
EventsTab:Toggle({
    Title = "Honey Collect Only",
    Icon = "droplet",
    Default = false,
    Callback = function(state)
        honeyCollecting = state
        if honeyCollecting then
            honeyCollectThread = task.spawn(function()
                local Players = game:GetService("Players")
                local localPlayer = Players.LocalPlayer
                local function isInventoryFull()
                    return #localPlayer.Backpack:GetChildren() >= 200
                end
                local function getMyFarm()
                    for _,farm in ipairs(workspace.Farm:GetChildren()) do
                        local d = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
                        if d and d:FindFirstChild("Owner") and d.Owner.Value == localPlayer.Name then
                            return farm
                        end
                    end
                end
                local function getMyHoneyCrops()
                    local myFarm = getMyFarm()
                    local crops = {}
                    if myFarm then
                        local plants = myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plants_Physical")
                        if plants then
                            for _, plant in ipairs(plants:GetChildren()) do
                                for _, part in ipairs(plant:GetDescendants()) do
                                    if part:IsA("BasePart") and part:FindFirstChildOfClass("ProximityPrompt") then
                                        local parPlant = part.Parent
                                        if parPlant and (parPlant:GetAttribute("Honey Glazed") or parPlant:GetAttribute("Pollinated")) then
                                            table.insert(crops, part)
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end
                    return crops
                end
                while honeyCollecting do
                    if isInventoryFull() then
                        repeat
                            task.wait(0.5)
                        until not isInventoryFull() or not honeyCollecting
                    end
                    if not honeyCollecting then break end
                    local crops = getMyHoneyCrops()
                    for _, crop in ipairs(crops) do
                        if not honeyCollecting or isInventoryFull() then return end
                        local char = localPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and crop and crop.Parent then
                            hrp.CFrame = CFrame.new(crop.Position + Vector3.new(0, 3, 0))
                            task.wait(0.15)
                            local prompt = crop:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then
                                pcall(function() fireproximityprompt(prompt) end)
                                task.wait(0.1)
                            end
                        end
                    end
                    task.wait(0.2)
                end
            end)
        else
            if honeyCollectThread then
                task.cancel(honeyCollectThread)
                honeyCollectThread = nil
            end
        end
    end
})

local function getHoneyMachineData()
    local success, result = pcall(function()
        local DataService = require(ReplicatedStorage.Modules.DataService)
        local data = DataService:GetData()
        if data and data.HoneyMachine then
            return data.HoneyMachine
        end
        return nil
    end)
    if success then return result else return nil end
end

local function findHoneyMachine()
    local honeyMachine = workspace.Interaction.UpdateItems:FindFirstChild("HoneyCombpressor", true)
    if not honeyMachine then
        honeyMachine = ReplicatedStorage.Modules.UpdateService:FindFirstChild("HoneyCombpressor", true)
    end
    return honeyMachine
end

local autoCollectHoneyThread
local autoGivePlantsThread

local function collectHoney()
    local honeyMachine = findHoneyMachine()
    if not honeyMachine then return false end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = honeyMachine.Spout.Jar.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.7)
        local HoneyMachineService_RE = ReplicatedStorage.GameEvents:FindFirstChild("HoneyMachineService_RE")
        if HoneyMachineService_RE then
            for i = 1, 3 do
                HoneyMachineService_RE:FireServer("MachineInteract")
                task.wait(0.25)
            end
            return true
        end
    end
    return false
end

local function compressPlants()
    local honeyMachine = findHoneyMachine()
    if not honeyMachine then return false end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = honeyMachine.HoneyFill.Outer.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.7)
        local HoneyMachineService_RE = ReplicatedStorage.GameEvents:FindFirstChild("HoneyMachineService_RE")
        if HoneyMachineService_RE then
            for i = 1, 2 do
                HoneyMachineService_RE:FireServer("MachineInteract")
                task.wait(0.25)
            end
            return true
        end
    end
    return false
end

local function autoCollectHoney()
    if autoCollectHoneyThread then return end
    autoCollectHoneyThread = task.spawn(function()
        while AutoCollectHoneyEnabled do
            task.wait(2)
            local honeyData = getHoneyMachineData()
            if honeyData then
                if honeyData.HoneyStored > 0 then
                    if collectHoney() then
                        WindUI:Notify({ Title = "Autohoney", Content = "Collected " .. honeyData.HoneyStored .. " honey!" })
                        task.wait(0.5)
                    end
                elseif honeyData.PlantWeight >= 10 and honeyData.TimeLeft <= 0 then
                    if compressPlants() then
                        WindUI:Notify({ Title = "Autohoney", Content = "Started honey compression process!" })
                        task.wait(1)
                    end
                end
            end
        end
        autoCollectHoneyThread = nil
    end)
end

local function getAllPollinatedTools()
    local found = {}
    -- Backpack
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("Pollinated") then
            table.insert(found, tool)
        end
    end
    -- Equipped
    if LocalPlayer.Character then
        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("Pollinated") then
                table.insert(found, tool)
            end
        end
    end
    return found
end

local function equipTool(tool)
    if tool and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and tool.Parent ~= LocalPlayer.Character then
            humanoid:EquipTool(tool)
            task.wait(0.2)
        end
    end
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(1, i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

local function autoGivePlants()
    if autoGivePlantsThread then return end
    autoGivePlantsThread = task.spawn(function()
        while AutoGivePlantsEnabled do
            local honeyData = getHoneyMachineData()
            if honeyData and honeyData.TimeLeft <= 0 and honeyData.PlantWeight < 10 and honeyData.HoneyStored <= 0 then
                local pollinatedTools = getAllPollinatedTools()
                if #pollinatedTools == 0 then
                    WindUI:Notify({ Title = "Autohoney", Content = "No pollinated fruit found in inventory!" })
                    task.wait(2)
                else
                    shuffle(pollinatedTools)
                    for _, tool in ipairs(pollinatedTools) do
                        if not AutoGivePlantsEnabled then break end
                        equipTool(tool)
                        local tryStart = tick()
                        local sent = false
                        while AutoGivePlantsEnabled and (tick() - tryStart) < 5 do
                            local HoneyMachineService_RE = ReplicatedStorage.GameEvents:FindFirstChild("HoneyMachineService_RE")
                            if HoneyMachineService_RE then
                                HoneyMachineService_RE:FireServer("MachineInteract")
                            end
                            local stillThere = false
                            if LocalPlayer.Character then
                                for _, t in ipairs(LocalPlayer.Character:GetChildren()) do
                                    if t == tool then
                                        stillThere = true
                                        break
                                    end
                                end
                            end
                            if not stillThere then
                                sent = true
                                break
                            end
                            task.wait(1)
                        end
                        if sent then
                            WindUI:Notify({ Title = "Autohoney", Content = "Pollinated fruit sent to honey machine!" })
                            task.wait(1)
                            break
                        else
                            WindUI:Notify({ Title = "Autohoney", Content = "Current fruit could not be sent. Swapping fruit!" })
                            task.wait(0.5)
                        end
                    end
                end
            else
                task.wait(1)
            end
        end
        autoGivePlantsThread = nil
    end)
end

EventsTab:Toggle({
    Title = "Auto Collect Honey",
    Icon = "droplet",
    Default = false,
    Callback = function(state)
        AutoCollectHoneyEnabled = state
        if state then
            autoCollectHoney()
        else
            if autoCollectHoneyThread then
                task.cancel(autoCollectHoneyThread)
                autoCollectHoneyThread = nil
            end
        end
    end
})

EventsTab:Toggle({
    Title = "Auto Give Plants",
    Icon = "leaf",
    Default = false,
    Callback = function(state)
        AutoGivePlantsEnabled = state
        if state then
            autoGivePlants()
        else
            if autoGivePlantsThread then
                task.cancel(autoGivePlantsThread)
                autoGivePlantsThread = nil
            end
        end
    end
})


local CraftingTab = Window:Tab({ Title = "Crafting", Icon = "hammer" })

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CraftingRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("CraftingGlobalObjectService")
local CraftingBench = workspace:WaitForChild("Interaction"):WaitForChild("UpdateItems"):WaitForChild("NewCrafting"):WaitForChild("EventCraftingWorkBench")

local recipes = {
    "Berry Blusher Sprinkler",
    "Tropical Mist Sprinkler",
    "Spice Spritzer Sprinkler",
    "Sweet Soaker Sprinkler",
    "Flower Froster Sprinkler",
    "Stalk Sprout Sprinkler",
    "Mutation Spray Choc",
    "Mutation Spray Pollinated",
    "Mutation Spray Shocked",
    "Honey Crafters Crate",
    "Anti Bee Egg",
    "Pack Bee"
}

local selectedRecipe = recipes[1]
local recipeSection = CraftingTab:Section({ Title = "Current recipe: " .. selectedRecipe })

-- Divider: Pick what to craft
CraftingTab:Divider({ Text = "Select Recipe to Craft" })
CraftingTab:Dropdown({
    Title = "Select Recipe",
    Values = recipes,
    Default = selectedRecipe,
    Callback = function(val)
        selectedRecipe = val
        recipeSection:SetTitle("Current recipe: " .. selectedRecipe)
        WindUI:Notify({ Title = "Crafting", Content = "Selected recipe: " .. selectedRecipe })
    end
})

-- Divider: Start autocraft
CraftingTab:Divider({ Text = "Autocraft" })

local autocraftThread
CraftingTab:Toggle({
    Title = "Autocraft (Set & Skip Time for Selected)",
    Icon = "zap",
    Default = false,
    Callback = function(enabled)
        if enabled then
            autocraftThread = task.spawn(function()
                while enabled do
                    -- Set the recipe
                    local setArgs = {
                        "SetRecipe",
                        CraftingBench,
                        "GearEventWorkbench",
                        selectedRecipe
                    }
                    CraftingRemote:FireServer(unpack(setArgs))
                    task.wait(0.15)
                    -- Skip crafting time
                    local skipArgs = {
                        "Claim",
                        CraftingBench,
                        "GearEventWorkbench",
                        1
                    }
                    CraftingRemote:FireServer(unpack(skipArgs))
                    task.wait(2.5)
                end
            end)
        else
            if autocraftThread then
                task.cancel(autocraftThread)
                autocraftThread = nil
            end
        end
    end
})

-- Divider: Event skips
CraftingTab:Divider({ Text = "Event Gear/Seed Skips" })

local gearSkipThread
CraftingTab:Toggle({
    Title = "Auto Skip Gear Crafting Time (Event Bench)",
    Icon = "clock",
    Default = false,
    Callback = function(state)
        if state then
            gearSkipThread = task.spawn(function()
                while true do
                    local args = {
                        [1] = "Claim",
                        [2] = workspace.Interaction.UpdateItems.NewCrafting.EventCraftingWorkBench,
                        [3] = "GearEventWorkbench",
                        [4] = 1
                    }
                    game:GetService("ReplicatedStorage").GameEvents.CraftingGlobalObjectService:FireServer(unpack(args))
                    task.wait(2.5)
                end
            end)
        else
            if gearSkipThread then
                task.cancel(gearSkipThread)
                gearSkipThread = nil
            end
        end
    end
})

local seedSkipThread
CraftingTab:Toggle({
    Title = "Auto Skip Seed Crafting Time (Event Bench)",
    Icon = "clock",
    Default = false,
    Callback = function(state)
        if state then
            seedSkipThread = task.spawn(function()
                while true do
                    local args = {
                        [1] = "Claim",
                        [2] = workspace.Interaction.UpdateItems.NewCrafting.SeedEventCraftingWorkBench,
                        [3] = "SeedEventWorkbench",
                        [4] = 1
                    }
                    game:GetService("ReplicatedStorage").GameEvents.CraftingGlobalObjectService:FireServer(unpack(args))
                    task.wait(2.5)
                end
            end)
        else
            if seedSkipThread then
                task.cancel(seedSkipThread)
                seedSkipThread = nil
            end
        end
    end
})



local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })


-- Notification Section
local notifSection = SettingsTab:Section({ Title = "" })

-- Webhook Input
local webhookBox
SettingsTab:Section({ Title = "Webhook (optional, for Discord notifications, etc.):" })
webhookBox = SettingsTab:Input({
    Title = "Webhook URL",
    Default = "",
    Placeholder = "Paste your Discord webhook URL here...",
    Callback = function(text)
        -- You can access .Text on webhookBox if needed elsewhere
    end
})

local HttpService = game:GetService("HttpService")

-- Join Low Server Button
SettingsTab:Button({
    Title = "Join Low Server",
    Icon = "cloud",
    Callback = function()
        notifSection:SetTitle("Searching for low server...")
        local minPlayers, bestId = math.huge, nil
        local placeId = game.PlaceId
        local cursor = ""
        local function fetchServers()
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
            if cursor ~= "" then url = url.."&cursor="..cursor end
            local response = game:HttpGet(url)
            local data = HttpService:JSONDecode(response)
            for _, server in ipairs(data.data or {}) do
                if server.playing < minPlayers and server.playing > 0 and not server.full then
                    minPlayers = server.playing
                    bestId = server.id
                end
            end
            cursor = data.nextPageCursor or ""
            return cursor ~= ""
        end
        for i=1,3 do if not fetchServers() then break end end
        if bestId then
            notifSection:SetTitle("Teleporting to low server...")
            game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, bestId)
        else
            notifSection:SetTitle("No suitable server found!")
        end
    end
})

-- Delete Other Farms Button
SettingsTab:Button({
    Title = "Delete Other Farms",
    Icon = "trash",
    Callback = function()
        local myName = game.Players.LocalPlayer.Name
        for _, farm in ipairs(workspace.Farm:GetChildren()) do
            local data = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
            if data and data:FindFirstChild("Owner") and data.Owner.Value ~= myName then
                farm:Destroy()
            end
        end
        notifSection:SetTitle("Other farms deleted.")
    end
})

-- Reduce Lag Button
SettingsTab:Button({
    Title = "Reduce Lag",
    Icon = "activity",
    Callback = function()
        pcall(function()
            local l=game:GetService("Lighting")
            l.GlobalShadows=false l.FogEnd=1e10 l.Brightness=0 l.EnvironmentDiffuseScale=0 l.EnvironmentSpecularScale=0 l.OutdoorAmbient=Color3.new(0,0,0)
            local t=workspace:FindFirstChildOfClass("Terrain")
            if t then t.WaterWaveSize=0 t.WaterWaveSpeed=0 t.WaterReflectance=0 t.WaterTransparency=1 end
            for _,v in pairs(game:GetDescendants()) do
                if v:IsA("Decal")or v:IsA("Texture")or v:IsA("ShirtGraphic")or v:IsA("Accessory")or v:IsA("Clothing")then v:Destroy()
                elseif v:IsA("ParticleEmitter")or v:IsA("Trail")then v.Enabled=false
                elseif v:IsA("Explosion")then v.Visible=false
                elseif v:IsA("MeshPart")or v:IsA("Part")or v:IsA("UnionOperation")then v.Material=Enum.Material.SmoothPlastic v.Reflectance=0 v.CastShadow=false end
            end
            workspace.StreamingEnabled=true workspace.StreamingMinRadius=32 workspace.StreamingTargetRadius=64
            settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 settings().Rendering.EditQualityLevel=Enum.QualityLevel.Level01
            for _,o in pairs(workspace:GetDescendants())do
                if o:IsA("BasePart")then pcall(function()o.TextureID=""end) o.CastShadow=false end
                if o:IsA("ParticleEmitter")or o:IsA("Beam")or o:IsA("Trail")then o.Enabled=false end
                if o:IsA("BasePart")and(o.Name=="Wall"or o.Name=="ColorWall")then o:Destroy()end
            end
        end)
        notifSection:SetTitle("Lag reduced!")
    end
})

-- PETS/EGGS TAB (WINDUI VERSION, PART 1)
local PetsTab = Window:Tab({ Title = "Pets/Eggs", Icon = "gift" })

-- State
local AutoFeedPetEnabled = false
local SelectedPlantsToFeed = {}
local PetEggESPEnabled = false
local espCache = {}
local activeEggs = {}
local PetFeedingIndex = 1
local LastFruitIndex = 1

local function getPetServices()
    local ok, result = pcall(function()
        if ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("PetServices") then
            local PetServices = ReplicatedStorage.Modules.PetServices
            local ActivePetsService = require(PetServices:FindFirstChild("ActivePetsService"))
            local PetsService = require(PetServices:FindFirstChild("PetsService"))
            return { ActivePetsService = ActivePetsService, PetsService = PetsService }
        end
        return nil
    end)
    return ok and result or nil
end

local function petNeedsFood(petUUID)
    local ok, result = pcall(function()
        local DataService = require(ReplicatedStorage.Modules.DataService)
        local data = DataService:GetData()
        if not data or not data.PetsData then return true end
        local petInventory = data.PetsData.PetInventory
        if not petInventory or not petInventory.Data then return true end
        local petData = petInventory.Data[petUUID]
        if not petData then return true end
        local PetRegistry = require(ReplicatedStorage.Data.PetRegistry)
        local PetList = PetRegistry.PetList
        local petTypeData = PetList[petData.PetType]
        if not petTypeData then return true end
        local defaultHunger = petTypeData.DefaultHunger or 100
        local currentHunger = petData.PetData.Hunger or 0
        local hungerPercentage = currentHunger / defaultHunger
        return hungerPercentage < 0.9
    end)
    return ok and result or true
end

local function getActivePets()
    local petServices = getPetServices()
    if not petServices then return {} end
    local ok, result = pcall(function()
        local PetUtilities
        if ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("PetServices") then
            PetUtilities = require(ReplicatedStorage.Modules.PetServices:FindFirstChild("PetUtilities"))
        end
        if not PetUtilities then return {} end
        local DataService = require(ReplicatedStorage.Modules.DataService)
        local data = DataService:GetData()
        if not data or not data.PetsData then return {} end
        local PetRegistry = require(ReplicatedStorage.Data.PetRegistry)
        local PetList = PetRegistry.PetList
        local equippedPets = data.PetsData.EquippedPets or {}
        local activePets = {}
        local petsFromUtilities = PetUtilities:GetPetsSortedByAge(LocalPlayer, 0, false, true)
        for _, petData in pairs(petsFromUtilities) do
            local petTypeData = PetList[petData.PetType]
            local defaultHunger = petTypeData and petTypeData.DefaultHunger or 100
            local currentHunger = petData.PetData.Hunger or 0
            local hungerPercentage = currentHunger / defaultHunger
            local needsFood = hungerPercentage < 0.9
            table.insert(activePets, {
                uuid = petData.UUID,
                petType = petData.PetType or "Unknown",
                petData = petData.PetData,
                isEquipped = true,
                currentHunger = currentHunger,
                maxHunger = defaultHunger,
                hungerPercentage = hungerPercentage,
                needsFood = needsFood,
            })
        end
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:GetAttribute("OWNER") == LocalPlayer.Name and obj:GetAttribute("UUID") and obj:HasTag("PetTargetable") then
                local alreadyHave = false
                for _, existing in pairs(activePets) do
                    if existing.uuid == obj:GetAttribute("UUID") then
                        alreadyHave = true
                        existing.object = obj
                        break
                    end
                end
                if not alreadyHave then
                    local stillNeedsFood = petNeedsFood(obj:GetAttribute("UUID"))
                    table.insert(activePets, {
                        uuid = obj:GetAttribute("UUID"),
                        petType = obj:GetAttribute("PetType") or "Unknown",
                        object = obj,
                        isEquipped = true,
                        currentHunger = 0,
                        maxHunger = 100,
                        hungerPercentage = 0,
                        needsFood = stillNeedsFood,
                    })
                end
            end
        end
        return activePets
    end)
    return ok and result or {}
end

local function getPlayerFruits()
    local fruits = {}
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") and tool:HasTag("FruitTool") then
                table.insert(fruits, tool.Name)
            end
        end
    end
    if LocalPlayer.Backpack then
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:HasTag("FruitTool") then
                table.insert(fruits, tool.Name)
            end
        end
    end
    local uniqueFruits, seen = {}, {}
    for _, fruit in pairs(fruits) do
        if not seen[fruit] then
            seen[fruit] = true
            table.insert(uniqueFruits, fruit)
        end
    end
    return uniqueFruits
end

local function feedPetsWithPlants()
    local petServices = getPetServices()
    if not petServices then return false end
    local activePets = getActivePets()
    if #activePets == 0 then
        WindUI:Notify({Title="Pets",Content="No active pets found!"})
        return false
    end
    local hungryPets = {}
    for _, pet in pairs(activePets) do
        if pet.needsFood then
            table.insert(hungryPets, pet)
        end
    end
    if #hungryPets == 0 then
        WindUI:Notify({Title="Pets",Content="All pets are well-fed!"})
        return false
    end
    local availableFruits = {}
    for plantName, selected in pairs(SelectedPlantsToFeed) do
        if selected then
            local hasFruit, fruitTool = false, nil
            if LocalPlayer.Character then
                for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
                    if tool:IsA("Tool") and tool:HasTag("FruitTool") and tool.Name == plantName then
                        hasFruit, fruitTool = true, tool
                        break
                    end
                end
            end
            if not hasFruit and LocalPlayer.Backpack then
                for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool:HasTag("FruitTool") and tool.Name == plantName then
                        hasFruit, fruitTool = true, tool
                        break
                    end
                end
            end
            if hasFruit and fruitTool then
                table.insert(availableFruits, { name = plantName, tool = fruitTool })
            end
        end
    end
    if #availableFruits == 0 then
        WindUI:Notify({Title="Pets",Content="No selected fruits found in inventory!"})
        return false
    end
    local fedCount = 0
    for _, fruitData in pairs(availableFruits) do
        if fruitData.tool.Parent ~= LocalPlayer.Character then
            LocalPlayer.Character.Humanoid:EquipTool(fruitData.tool)
            task.wait(0.5)
        end
        for _, pet in pairs(hungryPets) do
            if not AutoFeedPetEnabled then break end
            if petNeedsFood(pet.uuid) then
                local ok = pcall(function() petServices.ActivePetsService:Feed(pet.uuid) end)
                if ok then
                    fedCount = fedCount + 1
                    task.wait(0.6)
                end
            end
        end
        if AutoFeedPetEnabled then task.wait(0.7) end
    end
    if fedCount > 0 then
        WindUI:Notify({Title="Pets",Content="Fed "..fedCount.." hungry pets!"})
    else
        WindUI:Notify({Title="Pets",Content="No pets were fed!"})
    end
    return fedCount > 0
end

local function autoFeedPetsInOrder()
    if not AutoFeedPetEnabled then return end
    spawn(function()
        while AutoFeedPetEnabled do
            task.wait(2)
            local petServices = getPetServices()
            if not petServices then task.wait(3) continue end
            local activePets = getActivePets()
            if #activePets == 0 then task.wait(3) continue end
            local hungryPets = {}
            for _, pet in pairs(activePets) do
                if pet.hungerPercentage and pet.hungerPercentage < 0.7 then
                    table.insert(hungryPets, pet)
                end
            end
            if #hungryPets == 0 then task.wait(5) continue end
            local availableFruits = {}
            for plantName, selected in pairs(SelectedPlantsToFeed) do
                if selected then
                    local hasFruit, fruitTool = false, nil
                    if LocalPlayer.Character then
                        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
                            if tool:IsA("Tool") and tool:HasTag("FruitTool") and tool.Name == plantName then
                                hasFruit, fruitTool = true, tool
                                break
                            end
                        end
                    end
                    if not hasFruit and LocalPlayer.Backpack then
                        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                            if tool:IsA("Tool") and tool:HasTag("FruitTool") and tool.Name == plantName then
                                hasFruit, fruitTool = true, tool
                                break
                            end
                        end
                    end
                    if hasFruit and fruitTool then
                        table.insert(availableFruits, { name = plantName, tool = fruitTool })
                    end
                end
            end
            if #availableFruits == 0 then task.wait(3) continue end
            if PetFeedingIndex > #hungryPets then PetFeedingIndex = 1 end
            if LastFruitIndex > #availableFruits then LastFruitIndex = 1 end
            local currentPet = hungryPets[PetFeedingIndex]
            local currentFruit = availableFruits[LastFruitIndex]
            if currentPet and currentFruit then
                if currentFruit.tool.Parent ~= LocalPlayer.Character then
                    LocalPlayer.Character.Humanoid:EquipTool(currentFruit.tool)
                    task.wait(0.3)
                end
                local currentTool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                if currentTool and currentTool:HasTag("FruitTool") then
                    pcall(function()
                        petServices.ActivePetsService:Feed(currentPet.uuid)
                    end)
                end
                PetFeedingIndex = PetFeedingIndex + 1
                if PetFeedingIndex > #hungryPets then
                    LastFruitIndex = LastFruitIndex + 1
                    if LastFruitIndex > #availableFruits then
                        LastFruitIndex = 1
                    end
                    PetFeedingIndex = 1
                end
            end
        end
    end)
end

local function autoFeedPets()
    if not AutoFeedPetEnabled then return end
    autoFeedPetsInOrder()
end

local petFruitsDropdown
local function updateFruitsDropdown()
    local playerFruits = getPlayerFruits()
    if #playerFruits > 0 then
        petFruitsDropdown:SetValues(playerFruits)
        WindUI:Notify({Title="Fruits",Content="Found " .. #playerFruits .. " fruits in inventory!"})
    else
        petFruitsDropdown:SetValues({ "No fruits found" })
        WindUI:Notify({Title="Fruits",Content="No fruits found in inventory!"})
    end
end

-- UI: Auto Feed Pets
local AutoFeedSection = PetsTab:Section({ Title = "Auto Feed Pets" })
petFruitsDropdown = AutoFeedSection:Dropdown({
    Title = "Fruits to Feed",
    Values = getPlayerFruits(),
    Multi = true,
    Callback = function(Value)
        SelectedPlantsToFeed = {}
        for _, v in pairs(Value) do
            SelectedPlantsToFeed[v] = true
        end
    end,
})
AutoFeedSection:Button({
    Title = "🔄 Refresh Fruit List",
    Callback = updateFruitsDropdown
})
AutoFeedSection:Toggle({
    Title = "Auto Feed Pets (<70%)",
    Default = false,
    Callback = function(Value)
        AutoFeedPetEnabled = Value
        if Value then autoFeedPets() end
    end,
})
AutoFeedSection:Button({
    Title = "Feed Pets Now",
    Callback = feedPetsWithPlants
})

-- PETS/EGGS TAB (WINDUI VERSION, PART 2) -- Pet Info, Pet Detection, ESP, etc.

-- Pet Information Section
local petInfoSection = PetsTab:Section({ Title = "Pet Information" })

petInfoSection:Button({
    Title = "Show Active Pets",
    Callback = function()
        local pets = getActivePets()
        if #pets == 0 then
            WindUI:Notify({Title="Pets",Content="No active pets found"})
            return
        end
        local msg = {}
        for i, pet in ipairs(pets) do
            local percent = pet.hungerPercentage and math.floor(pet.hungerPercentage*100) or 0
            table.insert(msg, ("%d. %s (%d%% Hunger)%s"):format(
                i, pet.petType or "?", percent, (pet.needsFood and " [NEEDS FOOD]" or "")
            ))
            if i >= 5 then
                table.insert(msg, "... and more")
                break
            end
        end
        WindUI:Notify({Title="Active Pets",Content=table.concat(msg,"\n")})
    end
})

petInfoSection:Button({
    Title = "Show Available Fruits",
    Callback = function()
        local fruits = getPlayerFruits()
        local msg = #fruits == 0 and "No fruits found in inventory" or table.concat(fruits, ", ")
        WindUI:Notify({Title="Fruits",Content=msg})
    end
})

-- Pet Detection/ESP Section
local petESPSection = PetsTab:Section({ Title = "Pet/Egg ESP" })

local cs = game:GetService("CollectionService")
local espConnections = {}

local function clearPetEggESP()
    for _, gui in pairs(espCache) do
        if gui and gui.Parent then gui:Destroy() end
    end
    espCache = {}
    for _, conn in ipairs(espConnections) do
        if conn then conn:Disconnect() end
    end
    espConnections = {}
end

local function addEggESP(obj)
    if obj:GetAttribute("OWNER") ~= LocalPlayer.Name then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "PetEggESP"
    bb.Adornee = obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart or obj
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    local label = Instance.new("TextLabel")
    label.Parent = bb
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = obj:GetAttribute("EggName") or "Egg"
    label.TextColor3 = Color3.new(0, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    bb.Parent = obj
    espCache[obj] = bb
end

petESPSection:Toggle({
    Title = "Pet Egg ESP",
    Default = false,
    Callback = function(state)
        PetEggESPEnabled = state
        clearPetEggESP()
        if state then
            for _, obj in pairs(cs:GetTagged("PetEggServer")) do
                addEggESP(obj)
            end
            table.insert(espConnections, cs:GetInstanceAddedSignal("PetEggServer"):Connect(addEggESP))
            table.insert(espConnections, cs:GetInstanceRemovedSignal("PetEggServer"):Connect(function(obj)
                if espCache[obj] then espCache[obj]:Destroy() espCache[obj]=nil end
            end))
            WindUI:Notify({Title="ESP",Content="Pet Egg ESP enabled"})
        else
            WindUI:Notify({Title="ESP",Content="Pet Egg ESP disabled"})
        end
    end
})

-- PETS/EGGS TAB (WINDUI VERSION, PART 3) -- Pet List, Utility, (add more features as needed)

-- Pet List (for info/reference)
local KnownPetList = {
    "Dog","Golden Lab","Bunny","Black Bunny","Cat","Orange Tabby","Deer","Spotted Deer","Monkey","Silver Monkey",
    "Chicken","Rooster","Pig","Turtle","Cow","Snail","Giant Ant","Dragonfly","Polar Bear","Panda","Sea Otter",
    "Caterpillar","Praying Mantis","Hedgehog","Kiwi","Mole","Frog","Echo Frog","Owl","Night Owl","Raccoon",
    "Grey Mouse","Squirrel","Brown Mouse","Red Giant Ant","Red Fox","Chicken Zombie","Blood Hedgehog","Blood Kiwi",
    "Blood Owl","Moon Cat","Bee","Honey Bee","Petal Bee","Golden Bee","Bear Bee","Queen Bee","Firefly","Red Dragon"
}

-- Check if player owns any known pets
local function checkPlayerPets()
    local foundPets, allActivePets = {}, {}
    local ok, petsFromUtilities = pcall(function()
        if not ReplicatedStorage:FindFirstChild("Modules") then return {} end
        local Modules = ReplicatedStorage.Modules
        if not Modules:FindFirstChild("PetServices") then return {} end
        local PetServices = Modules.PetServices
        if not PetServices:FindFirstChild("PetUtilities") then return {} end
        local PetUtilities = require(PetServices.PetUtilities)
        if not PetUtilities then return {} end
        if not Modules:FindFirstChild("DataService") then return {} end
        local DataService = require(Modules.DataService)
        local data = DataService:GetData()
        if not data or not data.PetsData then return {} end
        local PetRegistry = require(ReplicatedStorage.Data.PetRegistry)
        local PetList = PetRegistry.PetList
        local pets = PetUtilities:GetPetsSortedByAge(LocalPlayer, 0, false, true)
        local processedPets = {}
        for _, petData in pairs(pets) do
            local petTypeData = PetList[petData.PetType]
            local defaultHunger = petTypeData and petTypeData.DefaultHunger or 100
            local currentHunger = (petData.PetData and petData.PetData.Hunger) or 0
            local hungerPercentage = currentHunger / defaultHunger
            local age = (petData.PetData and petData.PetData.Age) or 0
            local isKnownPet = false
            for _, knownPet in pairs(KnownPetList) do
                if petData.PetType == knownPet then isKnownPet = true break end
            end
            table.insert(processedPets, {
                uuid = petData.UUID,
                name = petData.PetType,
                type = petData.PetType,
                age = age,
                currentHunger = currentHunger,
                maxHunger = defaultHunger,
                hungerPercentage = hungerPercentage,
                isKnownPet = isKnownPet,
                location = "Farm Area",
            })
        end
        return processedPets
    end)
    if ok and petsFromUtilities then
        for _, pet in pairs(petsFromUtilities) do
            table.insert(allActivePets, pet)
            if pet.isKnownPet then
                table.insert(foundPets, pet)
            end
        end
    end
    return foundPets, allActivePets
end

-- Pet Utility Section
local petUtilitySection = PetsTab:Section({ Title = "Pet Utility" })

petUtilitySection:Button({
    Title = "Check for Known Pets",
    Callback = function()
        local knownPets, allActivePets = checkPlayerPets()
        if #knownPets > 0 then
            local msg = {}
            for i, pet in ipairs(knownPets) do
                local hunger = pet.hungerPercentage and math.floor(pet.hungerPercentage*100) or 0
                table.insert(msg, ("%d. %s (%d%% Hunger)%s"):format(i, pet.name or "?", hunger, (hunger < 70 and " [NEEDS FOOD]" or "")))
                if i >= 5 then
                    table.insert(msg, "... and more")
                    break
                end
            end
            WindUI:Notify({Title="My Known Pets",Content=table.concat(msg,"\n")})
        elseif #allActivePets > 0 then
            WindUI:Notify({Title="Pets",Content="No known pets found, but you have "..#allActivePets.." active pets."})
        else
            WindUI:Notify({Title="Pets",Content="You have no active pets."})
        end
    end
})



-- Example: Manual Pet Egg ESP Clear
petUtilitySection:Button({
    Title = "Clear Pet Egg ESP",
    Callback = function()
        clearPetEggESP()
        WindUI:Notify({Title="ESP",Content="Cleared all Pet Egg ESP overlays."})
    end
})


-- PETS/EGGS TAB (WINDUI VERSION, PART 4) -- Advanced actions, manual triggers, more utilities

-- Advanced Section: Manual Triggers / Actions
local advancedSection = PetsTab:Section({ Title = "Advanced Actions" })

-- Manual Pet Feeding Cycle Trigger
advancedSection:Button({
    Title = "Cycle Feed All Pets (Once)",
    Callback = function()
        local prevState = AutoFeedPetEnabled
        AutoFeedPetEnabled = true
        feedPetsWithPlants()
        AutoFeedPetEnabled = prevState
    end
})

-- Manual ESP Refresh
advancedSection:Button({
    Title = "Refresh Pet Egg ESP",
    Callback = function()
        if PetEggESPEnabled then
            clearPetEggESP()
            for _, obj in pairs(cs:GetTagged("PetEggServer")) do
                addEggESP(obj)
            end
            WindUI:Notify({Title="ESP",Content="Pet Egg ESP refreshed."})
        end
    end
})

-- Example: Mass unequip all fruits from character (utility)
advancedSection:Button({
    Title = "Unequip All Fruits",
    Callback = function()
        if LocalPlayer.Character then
            for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
                if tool:IsA("Tool") and tool:HasTag("FruitTool") then
                    tool.Parent = LocalPlayer.Backpack
                end
            end
            WindUI:Notify({Title="Fruits",Content="All fruits unequipped."})
        end
    end
})

-- Example: Show count of all fruits in backpack
advancedSection:Button({
    Title = "Show Fruit Counts (Backpack)",
    Callback = function()
        local fruitCounts = {}
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:HasTag("FruitTool") then
                fruitCounts[tool.Name] = (fruitCounts[tool.Name] or 0) + 1
            end
        end
        local items = {}
        for fruit, count in pairs(fruitCounts) do
            table.insert(items, fruit .. ": " .. count)
        end
        WindUI:Notify({Title="Backpack Fruits",Content=next(items) and table.concat(items, "\n") or "No fruits found."})
    end
})




local HttpService = game:GetService("HttpService")
local webhookReq = (syn and syn.request) or (http and http.request) or http_request or request or httprequest
local localPlayer = game:GetService("Players").LocalPlayer

local WebhookTab = Window:Tab({ Title = "Webhook", Icon = "send" })

-- Notification section for feedback
local notifSection = WebhookTab:Section({ Title = "" })

-- Input for webhook URL
local webhookUrl = ""
WebhookTab:Input({
    Title = "Discord Webhook URL",
    Placeholder = "Paste your Discord webhook here...",
    Value = "",
    Callback = function(text)
        webhookUrl = text
    end
})

-- Slider for interval (WindUI correct layout)
local minValue, maxValue = 1, 60
local sliderValue = 3
WebhookTab:Slider({
    Title = "Send notification interval (minutes)",
    Desc = "How many minutes between Discord webhook sends.",
    Value = {
        Min = minValue,
        Max = maxValue,
        Default = sliderValue
    },
    Callback = function(val)
        sliderValue = val
        notifSection:SetTitle(("Send notification every %d minute%s"):format(
            sliderValue, sliderValue == 1 and "" or "s"))
    end
})
notifSection:SetTitle(("Send notification every %d minute%s"):format(
    sliderValue, sliderValue == 1 and "" or "s"))

-- === WEBHOOK LOGIC (CUMULATIVE GAINS ONLY, EXCLUDING STARTING ITEMS/SEEDS) ===
local leaderstats = localPlayer:WaitForChild("leaderstats")
local shecklesStat = leaderstats:WaitForChild("Sheckles")

local webhookActive = false
local trackerThread = nil
local sessionStart = tick()
local startingInventory = {}
local cumulativeGained = {}

local function getBaseName(name)
    local base = name:match("^(.-) %b[]")
    if base then return base end
    base = name:match("^(.-)%[")
    if base then return base:sub(1, -2) end
    return name
end

local function getCurrentInventory()
    local counts = {}
    for _, item in ipairs(localPlayer.Backpack:GetChildren()) do
        local rawName = item:GetAttribute("Seed") or item.Name
        local baseName = getBaseName(rawName)
        counts[baseName] = (counts[baseName] or 0) + 1
    end
    return counts
end

local function updateCumulativeGained()
    local current = getCurrentInventory()
    for item, count in pairs(current) do
        local startCount = startingInventory[item] or 0
        local gainedNow = count - startCount
        if gainedNow > 0 then
            cumulativeGained[item] = math.max(cumulativeGained[item] or 0, gainedNow)
        end
    end
end

local function formatTotalsGained()
    local lines = {}
    for item, gained in pairs(cumulativeGained) do
        if gained > 0 then
            table.insert(lines, ("%s: %d"):format(item, gained))
        end
    end
    table.sort(lines)
    return #lines > 0 and table.concat(lines, "\n") or "No new items/seeds gained."
end

local function fmt(n)
    if n >= 1e9 then return ("%.2fB"):format(n/1e9)
    elseif n >= 1e6 then return ("%.2fM"):format(n/1e6)
    elseif n >= 1e3 then return ("%.2fK"):format(n/1e3)
    else return tostring(n)
    end
end

local function sendWebhook(username, currentMoney, uptime)
    if webhookUrl == "" then return end
    local embed = {
        title = ("%s's Garden Gained Items/Seeds"):format(username),
        color = 0x48db6a,
        fields = {
            { name = "Total Money", value = fmt(currentMoney), inline = false },
            { name = "Items/Seeds Gained", value = ("```%s```"):format(formatTotalsGained()), inline = false },
            { name = "Session Uptime", value = uptime, inline = false }
        }
    }
    local payload = { embeds = {embed} }
    local success, err = pcall(function()
        webhookReq{
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        }
    end)
    if success then
        notifSection:SetTitle("✅ Webhook sent!")
    else
        notifSection:SetTitle("❌ Failed to send webhook.")
    end
end

local function startWebhook()
    webhookActive = true
    notifSection:SetTitle("Webhook tracking started.")
    sessionStart = tick()
    if trackerThread then
        task.cancel(trackerThread)
    end
    startingInventory = getCurrentInventory()
    cumulativeGained = {}
    trackerThread = task.spawn(function()
        while webhookActive do
            for i = 1, sliderValue * 60 do
                if not webhookActive then return end
                task.wait(1)
                updateCumulativeGained()
            end
            local nowMoney = shecklesStat.Value
            local uptime = os.date("!%X", math.floor(tick() - sessionStart))
            sendWebhook(localPlayer.Name, nowMoney, uptime)
        end
    end)
end

local function stopWebhook()
    webhookActive = false
    notifSection:SetTitle("Webhook tracking stopped.")
    if trackerThread then
        task.cancel(trackerThread)
        trackerThread = nil
    end
end

WebhookTab:Toggle({
    Title = "Webhook Tracking",
    Desc = "Toggle to enable/disable sending Discord webhooks.",
    Value = false,
    Callback = function(state)
        if state then
            if webhookUrl == "" or not webhookUrl:find("discord.com/api/webhooks/") then
                notifSection:SetTitle("❌ Please enter a valid Discord webhook URL!")
                return
            end
            startWebhook()
        else
            stopWebhook()
        end
    end
})
