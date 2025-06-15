-- Ensure game is loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end
repeat task.wait() until game.Players.LocalPlayer.Character and not game.Players.LocalPlayer.PlayerGui:FindFirstChild("LoadingScreenPrefab")
game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("EndDecision"):FireServer(false)

-- Bond counter UI (centered 500x500, discord link at top, bond at bottom)
if not game.CoreGui:FindFirstChild("BondCheck") then
    local gui = Instance.new("ScreenGui")
    gui.Name = "BondCheck"
    gui.Parent = game.CoreGui

    local frame = Instance.new("Frame")
    frame.Name = "Bond"
    frame.Size = UDim2.new(0, 500, 0, 500)
    frame.Position = UDim2.new(0.5, -250, 0.5, -250)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BorderColor3 = Color3.new(0, 0, 0)
    frame.BorderSizePixel = 2
    frame.BackgroundTransparency = 0.18
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.08, 0)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 3
    stroke.Parent = frame

    -- Discord link at top
    local discordLabel = Instance.new("TextLabel")
    discordLabel.Name = "Discord"
    discordLabel.Size = UDim2.new(1, -20, 0, 40)
    discordLabel.Position = UDim2.new(0, 10, 0, 10)
    discordLabel.BackgroundTransparency = 1
    discordLabel.Text = "DISCORD.GG/RINGTA"
    discordLabel.TextSize = 32
    discordLabel.Font = Enum.Font.GothamBold
    discordLabel.TextColor3 = Color3.fromRGB(114, 137, 218)
    discordLabel.TextStrokeTransparency = 0.3
    discordLabel.TextYAlignment = Enum.TextYAlignment.Top
    discordLabel.Parent = frame

    -- Bond amount at bottom
    local bondLabel = Instance.new("TextLabel")
    bondLabel.Name = "BondAmount"
    bondLabel.Size = UDim2.new(1, -40, 0, 64)
    bondLabel.Position = UDim2.new(0, 20, 1, -74)
    bondLabel.BackgroundTransparency = 1
    bondLabel.Text = "Bond Amount: +0"
    bondLabel.TextSize = 48
    bondLabel.Font = Enum.Font.GothamBold
    bondLabel.TextColor3 = Color3.fromRGB(0, 102, 255)
    bondLabel.TextStrokeColor3 = Color3.fromRGB(255,255,255)
    bondLabel.TextStrokeTransparency = 0.4
    bondLabel.TextYAlignment = Enum.TextYAlignment.Bottom
    bondLabel.Parent = frame
end

-- Global bond count
_G.Bond = 0
workspace.RuntimeItems.ChildAdded:Connect(function(v)
    if v.Name:find("Bond") and v:FindFirstChild("Part") then
        v.Destroying:Connect(function() _G.Bond += 1 end)
    end
end)
spawn(function()
    local gui = game.CoreGui:WaitForChild("BondCheck")
    while gui.Parent do
        local lbl = gui.Bond:FindFirstChild("BondAmount")
        if lbl then
            lbl.Text = "Bond Amount: +" .. _G.Bond
        end
        task.wait(0.05)
    end
end)

-- Camera & anchoring setup
local plr = game.Players.LocalPlayer
plr.CameraMode = "Classic"
plr.CameraMaxZoomDistance = math.huge
plr.CameraMinZoomDistance = 30
game.Workspace.CurrentCamera.CameraSubject = plr.Character:FindFirstChild("Humanoid")
plr.Character.HumanoidRootPart.Anchored = true

-- Teleport to Vampire Castle & seat in MaximGun
repeat
    plr.Character.HumanoidRootPart.Anchored = true
    task.wait(0.25)
    plr.Character.HumanoidRootPart.CFrame = CFrame.new(80, 3, -9000)
until workspace.RuntimeItems:FindFirstChild("MaximGun")
task.wait(0.15)
for _, v in ipairs(workspace.RuntimeItems:GetChildren()) do
    if v.Name == "MaximGun" and v:FindFirstChild("VehicleSeat") then
        v.VehicleSeat.Disabled = false
        v.VehicleSeat:SetAttribute("Disabled", false)
        v.VehicleSeat:Sit(plr.Character.Humanoid)
    end
end
task.wait(0.25)
-- Snap to seat
for _, v in ipairs(workspace.RuntimeItems:GetChildren()) do
    if v.Name == "MaximGun" and v:FindFirstChild("VehicleSeat")
    and (plr.Character.HumanoidRootPart.Position - v.VehicleSeat.Position).Magnitude < 400 then
        plr.Character.HumanoidRootPart.CFrame = v.VehicleSeat.CFrame
    end
end
task.wait(0.5)
plr.Character.HumanoidRootPart.Anchored = false
repeat task.wait() until plr.Character:FindFirstChildOfClass("Humanoid").Sit
task.wait(0.25)
plr.Character:FindFirstChildOfClass("Humanoid").Sit = false
task.wait(0.25)
repeat
    for _, v in ipairs(workspace.RuntimeItems:GetChildren()) do
        if v.Name == "MaximGun" and v:FindFirstChild("VehicleSeat")
        and (plr.Character.HumanoidRootPart.Position - v.VehicleSeat.Position).Magnitude < 400 then
            plr.Character.HumanoidRootPart.CFrame = v.VehicleSeat.CFrame
        end
    end
    task.wait(0.05)
until plr.Character:FindFirstChildOfClass("Humanoid").Sit
task.wait(0.45)

-- INSTANT TP TO LOCATIONS & BOND COLLECTION (with delay, special scripts, and collecting 5 blocks under bond)
local positions = {
    Vector3.new(57, 3, 30000), -- 1st
    Vector3.new(57, 3, 28000), -- 2nd
    Vector3.new(57, 3, 26000), -- 3rd
    Vector3.new(57, 3, 24000),
    Vector3.new(57, 3, 22000), Vector3.new(57, 3, 20000),
    Vector3.new(57, 3, 18000), Vector3.new(57, 3, 16000),
    Vector3.new(57, 3, 14000), Vector3.new(57, 3, 12000),
    Vector3.new(57, 3, 10000), Vector3.new(57, 3, 8000),
    Vector3.new(57, 3, 6000), Vector3.new(57, 3, 4000),
    Vector3.new(57, 3, 2000), Vector3.new(57, 3, 0),
    Vector3.new(57, 3, -2000), Vector3.new(57, 3, -4000),
    Vector3.new(57, 3, -6000), Vector3.new(57, 3, -8000),
    Vector3.new(57, 3, -10000), Vector3.new(57, 3, -12000),
    Vector3.new(57, 3, -14000), Vector3.new(57, 3, -16000),
    Vector3.new(57, 3, -18000), Vector3.new(57, 3, -20000),
    Vector3.new(57, 3, -22000), Vector3.new(57, 3, -24000),
    Vector3.new(57, 3, -26000), Vector3.new(57, 3, -28000),
    Vector3.new(57, 3, -30000), Vector3.new(57, 3, -32000),
    Vector3.new(57, 3, -34000), Vector3.new(57, 3, -36000),
    Vector3.new(57, 3, -38000), Vector3.new(57, 3, -40000),
    Vector3.new(57, 3, -42000), Vector3.new(57, 3, -44000),
    Vector3.new(57, 3, -46000), Vector3.new(57, 3, -48000),
    Vector3.new(-434, 3, -48998)
}

local WaitTime = 0.6
local ranHideScript = false

local function TPTo(pos)
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(pos)
    end
end

local function collectBondsAtPosition()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    -- Wait for bonds to load in
    task.wait(0.2)
    for _, v in ipairs(workspace.RuntimeItems:GetChildren()) do
        if v.Name:find("Bond") and v:FindFirstChild("Part") then
            -- Teleport 5 blocks underneath the bond before collecting
            local under = v.Part.Position - Vector3.new(0, 5, 0)
            hrp.CFrame = CFrame.new(under)
            task.wait(0.1)
            -- Then teleport directly to the bond to collect
            hrp.CFrame = v.Part.CFrame
            pcall(function()
                game:GetService("ReplicatedStorage")
                    .Shared.Network.RemotePromise.Remotes.C_ActivateObject:FireServer(v)
            end)
            task.wait(0.05)
        end
    end
end

local function runHideScript()
    if ranHideScript then return end
    ranHideScript = true
    spawn(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local runtimeItems = workspace:FindFirstChild("RuntimeItems")
        local updateInterval = 1

        local function isInRuntimeItems(instance)
            if not runtimeItems then return false end
            return instance:IsDescendantOf(runtimeItems)
        end

        local function hideVisuals(instance)
            if isInRuntimeItems(instance) then return end
            if instance:IsA("BasePart") then
                instance.LocalTransparencyModifier = 1
                instance.CanCollide = false
            elseif instance:IsA("Decal") or instance:IsA("Texture") then
                instance.Transparency = 1
            elseif instance:IsA("Beam") or instance:IsA("Trail") then
                instance.Enabled = false
            end
        end

        while true do
            for _, instance in ipairs(workspace:GetDescendants()) do
                hideVisuals(instance)
            end
            task.wait(updateInterval)
        end
    end)
end

local runService = game:GetService("RunService")
while true do
    if plr.Character:FindFirstChildOfClass("Humanoid").Sit then
        for i, pos in ipairs(positions) do
            TPTo(pos)
            task.wait(WaitTime)
            -- 2nd position: run fly loadstring
            if i == 2 then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/fly.github.io/refs/heads/main/fly.lua"))()
            end
            -- 3rd position: run hide visuals script
            if i == 3 then
                runHideScript()
            end
            collectBondsAtPosition()
            -- Final position: run lowserver loadstring after 6s
            if pos == Vector3.new(-434, 3, -48998) then
                task.wait(6)
                loadstring(game:HttpGet("https://raw.githubusercontent.com/ewewe514/lowserver.github.io/refs/heads/main/lowserver.lua"))()
            end
        end
        -- Optional: break here if you only want to run once
        -- break
    end
    task.wait(0.05)
end
