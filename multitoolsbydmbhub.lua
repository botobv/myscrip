-- MULTI TOOL v4 FINAL - Delta Executor Mobile
-- [FLING] Touch Fling + Anti-Fling + Teleport Player
-- [RING]  Super Ring Parts + Godmode
-- [FLY]   Muffin V3 Logic (Mobile)
-- [AIM]   Aimlock + ESP — LOCKED ke Game ID 136801880565837
-- [CREDS] Credits

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- =====================
-- GAME ID CHECK
-- =====================
local ALLOWED_GAME_ID = 136801880565837
local aimUnlocked     = (game.PlaceId == ALLOWED_GAME_ID)

-- =====================
-- NETWORK OWNERSHIP
-- =====================
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity  = Vector3.new(14.46262424, 14.46262424, 14.46262424)
    }
    Network.RetainPart = function(Part)
        if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(Workspace) then
            table.insert(Network.BaseParts, Part)
            Part.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
            Part.CanCollide = false
        end
    end
    local function EnablePartControl()
        LocalPlayer.ReplicationFocus = Workspace
        RunService.Heartbeat:Connect(function()
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            for _, Part in pairs(Network.BaseParts) do
                if Part:IsDescendantOf(Workspace) then
                    Part.Velocity = Network.Velocity
                end
            end
        end)
    end
    EnablePartControl()
end

if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
    local d = Instance.new("Decal")
    d.Name   = "juisdfj0i32i0eidsuf0iok"
    d.Parent = ReplicatedStorage
end

-- =====================
-- STATE
-- =====================
local flingEnabled   = false
local flingPower     = 500
local flingMovel     = 0.1
local antiFlingConns = {}

local ringEnabled = false
local ringParts   = {}

local godEnabled = false
local godConn    = nil
local fallConn   = nil

local flyEnabled    = false
local flySpeed      = 50
local flyAttachment = nil
local flyLV         = nil
local flyAO         = nil

local aimbotEnabled = false
local espEnabled    = false
local aimMode       = "SMOOTH"
local espAdornments = {}

-- =====================
-- ANTI-FLING (auto)
-- =====================
local function setupAntiChar(character)
    local function dc(part)
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    for _, p in ipairs(character:GetChildren()) do dc(p) end
    local ca = character.ChildAdded:Connect(dc)
    local cs = RunService.Stepped:Connect(function()
        if not character:IsDescendantOf(Workspace) then return end
        for _, p in ipairs(character:GetChildren()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end)
    character.Destroying:Connect(function() ca:Disconnect(); cs:Disconnect() end)
end

local function trackPlayer(player)
    if player == LocalPlayer then return end
    local c = player.CharacterAdded:Connect(setupAntiChar)
    if player.Character then setupAntiChar(player.Character) end
    antiFlingConns[player] = c
end

local function untrackPlayer(player)
    if antiFlingConns[player] then
        antiFlingConns[player]:Disconnect()
        antiFlingConns[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do trackPlayer(p) end
Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(untrackPlayer)

-- =====================
-- FLING LOOP
-- =====================
coroutine.wrap(function()
    while true do
        RunService.Heartbeat:Wait()
        if flingEnabled then
            local c   = LocalPlayer.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local vel = hrp.Velocity
                hrp.Velocity = vel * (flingPower * 10) + Vector3.new(0, flingPower * 100, 0)
                RunService.RenderStepped:Wait()
                if c and c.Parent and hrp and hrp.Parent then hrp.Velocity = vel end
                RunService.Stepped:Wait()
                if c and c.Parent and hrp and hrp.Parent then
                    hrp.Velocity = vel + Vector3.new(0, flingMovel * flingPower, 0)
                    flingMovel   = flingMovel * -1
                end
            end
        end
    end
end)()

-- =====================
-- RING PARTS
-- =====================
local RING_RADIUS  = 60
local RING_HEIGHT  = 80
local RING_ROTSPD  = 3
local RING_ATTRACT = 1200

local function retainRingPart(part)
    if part:IsA("BasePart") and not part.Anchored and part:IsDescendantOf(Workspace) then
        if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then return false end
        part.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
        part.CanCollide = false
        return true
    end
    return false
end

local function addRingPart(part)
    if retainRingPart(part) and not table.find(ringParts, part) then
        table.insert(ringParts, part)
    end
end

local function removeRingPart(part)
    local i = table.find(ringParts, part)
    if i then table.remove(ringParts, i) end
end

for _, p in pairs(Workspace:GetDescendants()) do addRingPart(p) end
Workspace.DescendantAdded:Connect(addRingPart)
Workspace.DescendantRemoving:Connect(removeRingPart)

RunService.Heartbeat:Connect(function()
    if not ringEnabled then return end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local center = hrp.Position
    for _, part in pairs(ringParts) do
        if part and part.Parent and not part.Anchored then
            local pos      = part.Position
            local angle    = math.atan2(pos.Z - center.Z, pos.X - center.X)
            local newAngle = angle + math.rad(RING_ROTSPD)
            local dist     = math.min(RING_RADIUS, (Vector3.new(pos.X, center.Y, pos.Z) - center).Magnitude)
            local target   = Vector3.new(
                center.X + math.cos(newAngle) * dist,
                center.Y + (RING_HEIGHT * math.abs(math.sin((pos.Y - center.Y) / RING_HEIGHT))),
                center.Z + math.sin(newAngle) * dist
            )
            part.Velocity = (target - part.Position).Unit * RING_ATTRACT
        end
    end
end)

-- =====================
-- GODMODE
-- =====================
local function enableGod()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.MaxHealth = math.huge
    hum.Health    = math.huge
    godConn  = RunService.Heartbeat:Connect(function()
        if hum and hum.Parent then hum.Health = math.huge end
    end)
    fallConn = hum.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Freefall then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Landed,      false)
        elseif new == Enum.HumanoidStateType.Landed then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Landed,      true)
        end
    end)
end

local function disableGod()
    if godConn  then godConn:Disconnect();  godConn  = nil end
    if fallConn then fallConn:Disconnect(); fallConn = nil end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.MaxHealth = 100; hum.Health = 100
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed,      true)
    end
end

-- =====================
-- FLY (Muffin V3)
-- =====================
local Controls
pcall(function()
    local PM = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
    Controls = PM:GetControls()
end)

local function setupFlyPhysics()
    task.defer(function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root or not flyEnabled then return end
        if flyAttachment then flyAttachment:Destroy() end
        hum.PlatformStand    = true
        flyAttachment        = Instance.new("Attachment", root)
        flyLV                = Instance.new("LinearVelocity", flyAttachment)
        flyLV.MaxForce       = 9e9
        flyLV.VectorVelocity = Vector3.zero
        flyLV.Attachment0    = flyAttachment
        flyAO                = Instance.new("AlignOrientation", flyAttachment)
        flyAO.MaxTorque      = 9e9
        flyAO.Responsiveness = 200
        flyAO.RigidityEnabled = false
        flyAO.Mode           = Enum.OrientationAlignmentMode.OneAttachment
        flyAO.Attachment0    = flyAttachment
    end)
end

local function disableFly()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end
    flyLV = nil; flyAO = nil
end

RunService.RenderStepped:Connect(function(dt)
    if not flyEnabled or not flyLV or not flyAO or not Controls then return end
    local mv  = Controls:GetMoveVector()
    local dir = Vector3.zero
    if mv.Magnitude > 0 then
        dir = (Camera.CFrame.LookVector * -mv.Z) + (Camera.CFrame.RightVector * mv.X)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space)
    or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
        dir = dir + Vector3.new(0,1,0)
    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    or     UserInputService:IsKeyDown(Enum.KeyCode.ButtonB) then
        dir = dir - Vector3.new(0,1,0)
    end
    flyLV.VectorVelocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
    flyAO.CFrame = flyAO.CFrame:Lerp(Camera.CFrame, 1 - math.exp(-20 * dt))
end)

-- =====================
-- AIMLOCK + ESP CORE
-- =====================
local function isVisible(targetPart)
    local origin    = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local distance  = (targetPart.Position - origin).Magnitude
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = Workspace:Raycast(origin, direction * distance, rayParams)
    if result and result.Instance then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

local function getAllTargets()
    local targets = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and char:FindFirstChild("Head")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if char and hum and hum.Health > 0 and head and hrp then
                table.insert(targets, {char=char, head=head, hrp=hrp, hum=hum, player=player})
            end
        end
    end
    return targets
end

local function getVisibleTargets()
    local out = {}
    for _, t in pairs(getAllTargets()) do
        if isVisible(t.head) then table.insert(out, t) end
    end
    return out
end

local function getClosestTarget(targets)
    local closest, shortest = nil, math.huge
    for _, t in pairs(targets) do
        local dist = (t.head.Position - Camera.CFrame.Position).Magnitude
        if dist < shortest then shortest = dist; closest = t end
    end
    return closest
end

local function clearESP()
    for _, a in pairs(espAdornments) do pcall(function() a:Destroy() end) end
    espAdornments = {}
end

coroutine.wrap(function()
    while true do
        RunService.RenderStepped:Wait()
        if not aimUnlocked or not aimbotEnabled then continue end
        local target = getClosestTarget(getVisibleTargets())
        if not target then continue end
        local targetPos = target.head.Position
        if aimMode == "SNAP" then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)) end
            end)
        else
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), 0.15)
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)) end
            end)
        end
    end
end)()

coroutine.wrap(function()
    while true do
        RunService.RenderStepped:Wait()
        if not aimUnlocked then continue end
        if not espEnabled then
            if #espAdornments > 0 then clearESP() end
            continue
        end
        clearESP()
        for _, t in pairs(getAllTargets()) do
            local col = isVisible(t.head) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,100,0)
            local box = Instance.new("BoxHandleAdornment")
            box.Adornee = t.hrp; box.AlwaysOnTop = true; box.ZIndex = 5
            box.Size = Vector3.new(4,6,4); box.Transparency = 0.3
            box.Color3 = col; box.Parent = t.char
            local corner = Instance.new("BoxHandleAdornment")
            corner.Adornee = t.hrp; corner.AlwaysOnTop = true; corner.ZIndex = 6
            corner.Size = Vector3.new(4.2,6.2,4.2); corner.Transparency = 0.7
            corner.Color3 = col; corner.Parent = t.char
            table.insert(espAdornments, box)
            table.insert(espAdornments, corner)
        end
    end
end)()

-- =====================
-- GUI
-- =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "MultiToolGUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ok = pcall(function() ScreenGui.Parent = CoreGui end)
if not ok then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size             = UDim2.new(0, 240, 0, 340)
MainFrame.Position         = UDim2.new(0.5, -120, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.Draggable        = true
MainFrame.Parent           = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Thickness = 1.5
mainStroke.Color     = Color3.fromRGB(60, 60, 100)

local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size               = UDim2.new(1, -70, 1, 0)
TitleLbl.Position           = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text               = "⚡ MULTI TOOL v4"
TitleLbl.Font               = Enum.Font.GothamBold
TitleLbl.TextSize            = 14
TitleLbl.TextColor3          = Color3.fromRGB(200, 200, 255)
TitleLbl.TextXAlignment      = Enum.TextXAlignment.Left
TitleLbl.Parent              = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 26, 0, 22)
MinBtn.Position         = UDim2.new(1, -58, 0, 7)
MinBtn.Text             = "-"
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.TextSize         = 16
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
MinBtn.TextColor3       = Color3.fromRGB(200, 200, 255)
MinBtn.BorderSizePixel  = 0
MinBtn.Parent           = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 26, 0, 22)
CloseBtn.Position         = UDim2.new(1, -28, 0, 7)
CloseBtn.Text             = "✕"
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 13
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.BorderSizePixel  = 0
CloseBtn.Parent           = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Tab Bar (5 tabs, 42px each)
local TabBar = Instance.new("Frame")
TabBar.Size                   = UDim2.new(1, -12, 0, 30)
TabBar.Position               = UDim2.new(0, 6, 0, 40)
TabBar.BackgroundTransparency = 1
TabBar.Parent                 = MainFrame

local tabLayout         = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding       = UDim.new(0, 3)
tabLayout.Parent        = TabBar

local ContentArea = Instance.new("Frame")
ContentArea.Size                   = UDim2.new(1, -14, 1, -82)
ContentArea.Position               = UDim2.new(0, 7, 0, 76)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent                 = MainFrame

local TAB_COLOR = {
    FLING = Color3.fromRGB(0, 130, 230),
    RING  = Color3.fromRGB(210, 40, 40),
    FLY   = Color3.fromRGB(130, 60, 210),
    AIM   = Color3.fromRGB(255, 80, 0),
    CREDS = Color3.fromRGB(180, 150, 0),
}
local TAB_NAMES = {"FLING", "RING", "FLY", "AIM", "CREDS"}
local tabBtns   = {}
local tabPanels = {}

local function makePanelBtn(name)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 42, 1, 0)
    btn.Text             = name
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 10
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
    btn.TextColor3       = Color3.fromRGB(140, 140, 165)
    btn.BorderSizePixel  = 0
    btn.Parent           = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local function makePanel()
    local f = Instance.new("Frame")
    f.Size                   = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Visible                = false
    f.Parent                 = ContentArea
    return f
end

local function mkBtn(parent, text, yPos, accentColor)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, 36)
    btn.Position         = UDim2.new(0, 0, 0, yPos)
    btn.Text             = text
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
    btn.TextColor3       = Color3.fromRGB(210, 210, 230)
    btn.BorderSizePixel  = 0
    btn.Parent           = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", btn)
    s.Thickness = 1
    s.Color     = accentColor or Color3.fromRGB(55, 55, 80)
    return btn
end

local function mkLbl(parent, text, yPos, color, h, size)
    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 0, h or 20)
    lbl.Position               = UDim2.new(0, 0, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = text
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = size or 11
    lbl.TextColor3             = color or Color3.fromRGB(120, 120, 145)
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextWrapped            = true
    lbl.Parent                 = parent
    return lbl
end

for _, name in ipairs(TAB_NAMES) do
    tabBtns[name]   = makePanelBtn(name)
    tabPanels[name] = makePanel()
end

local function switchTab(name)
    for _, n in ipairs(TAB_NAMES) do
        tabPanels[n].Visible = n == name
        if n == name then
            tabBtns[n].BackgroundColor3 = TAB_COLOR[n]
            tabBtns[n].TextColor3       = Color3.fromRGB(255,255,255)
        else
            tabBtns[n].BackgroundColor3 = Color3.fromRGB(22,22,36)
            tabBtns[n].TextColor3       = Color3.fromRGB(140,140,165)
        end
    end
end

for _, name in ipairs(TAB_NAMES) do
    local n = name
    tabBtns[n].MouseButton1Click:Connect(function() switchTab(n) end)
end

-- ===========================
-- TAB FLING
-- ===========================
local fP  = tabPanels["FLING"]
local col = TAB_COLOR["FLING"]

local pwrRow = Instance.new("Frame")
pwrRow.Size                   = UDim2.new(1, 0, 0, 32)
pwrRow.BackgroundTransparency = 1
pwrRow.Parent                 = fP

local pwrLbl = Instance.new("TextLabel")
pwrLbl.Size                   = UDim2.new(0, 48, 1, 0)
pwrLbl.BackgroundTransparency = 1
pwrLbl.Text                   = "PWR:"
pwrLbl.Font                   = Enum.Font.GothamBold
pwrLbl.TextSize               = 13
pwrLbl.TextColor3             = col
pwrLbl.Parent                 = pwrRow

local pwrBox = Instance.new("TextBox")
pwrBox.Size             = UDim2.new(0, 90, 0.78, 0)
pwrBox.Position         = UDim2.new(0, 52, 0.11, 0)
pwrBox.BackgroundColor3 = Color3.fromRGB(18, 28, 46)
pwrBox.BorderSizePixel  = 0
pwrBox.Text             = "500"
pwrBox.Font             = Enum.Font.Gotham
pwrBox.TextSize         = 13
pwrBox.TextColor3       = col
pwrBox.Parent           = pwrRow
Instance.new("UICorner", pwrBox).CornerRadius = UDim.new(0, 6)
local ps = Instance.new("UIStroke", pwrBox); ps.Color = col; ps.Thickness = 1

local flingBtn = mkBtn(fP, "FLING: OFF", 38, col)
mkLbl(fP, "● Anti-Fling aktif otomatis", 82, Color3.fromRGB(0, 220, 130), 20, 11)

local divLbl = mkLbl(fP, "── TELEPORT TO PLAYER ──", 106, Color3.fromRGB(70,70,100), 18, 10)
divLbl.TextXAlignment = Enum.TextXAlignment.Center

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size                 = UDim2.new(1, 0, 0, 120)
playerScroll.Position             = UDim2.new(0, 0, 0, 126)
playerScroll.BackgroundColor3     = Color3.fromRGB(14, 14, 22)
playerScroll.BorderSizePixel      = 0
playerScroll.ScrollBarThickness   = 4
playerScroll.ScrollBarImageColor3 = col
playerScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
playerScroll.Parent               = fP
Instance.new("UICorner", playerScroll).CornerRadius = UDim.new(0, 8)

local listLayout   = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.Parent  = playerScroll

local function populatePlayerList()
    for _, child in ipairs(playerScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size             = UDim2.new(1, -6, 0, 32)
            btn.Text             = "⟶  " .. p.Name
            btn.Font             = Enum.Font.GothamBold
            btn.TextSize         = 12
            btn.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
            btn.TextColor3       = Color3.fromRGB(180, 210, 255)
            btn.TextXAlignment   = Enum.TextXAlignment.Left
            btn.BorderSizePixel  = 0
            btn.Parent           = playerScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            local pad = Instance.new("UIPadding", btn)
            pad.PaddingLeft = UDim.new(0, 8)
            btn.MouseButton1Click:Connect(function()
                local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local tgt   = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if myHRP and tgt then myHRP.CFrame = tgt.CFrame + Vector3.new(0, 3, 0) end
            end)
        end
    end
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
end

populatePlayerList()
Players.PlayerAdded:Connect(function()    task.wait(0.1); populatePlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.1); populatePlayerList() end)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
end)

pwrBox.FocusLost:Connect(function(entered)
    if entered then
        local v = tonumber(pwrBox.Text)
        if v and v > 0 then flingPower = math.min(v, 5000); pwrBox.Text = tostring(flingPower) end
    end
end)

flingBtn.MouseButton1Click:Connect(function()
    flingEnabled = not flingEnabled
    flingBtn.Text             = flingEnabled and "FLING: ON" or "FLING: OFF"
    flingBtn.BackgroundColor3 = flingEnabled and Color3.fromRGB(0, 70, 160) or Color3.fromRGB(22, 22, 36)
end)

-- ===========================
-- TAB RING
-- ===========================
local rP   = tabPanels["RING"]
local col2 = TAB_COLOR["RING"]

local ringBtn = mkBtn(rP, "Ring Parts: OFF", 0,  col2)
local godBtn  = mkBtn(rP, "Godmode: OFF",    44, col2)
mkLbl(rP, "Ring: radius 60 | height 80 | speed 3", 94,  Color3.fromRGB(90,90,115), 28, 11)
mkLbl(rP, "Godmode: max HP + anti fall damage",     120, Color3.fromRGB(90,90,115), 28, 11)

ringBtn.MouseButton1Click:Connect(function()
    ringEnabled = not ringEnabled
    ringBtn.Text             = ringEnabled and "Ring Parts: ON" or "Ring Parts: OFF"
    ringBtn.BackgroundColor3 = ringEnabled and Color3.fromRGB(155, 25, 25) or Color3.fromRGB(22, 22, 36)
end)

godBtn.MouseButton1Click:Connect(function()
    godEnabled = not godEnabled
    if godEnabled then enableGod() else disableGod() end
    godBtn.Text             = godEnabled and "Godmode: ON" or "Godmode: OFF"
    godBtn.BackgroundColor3 = godEnabled and Color3.fromRGB(155, 25, 25) or Color3.fromRGB(22, 22, 36)
end)

-- ===========================
-- TAB FLY
-- ===========================
local flP  = tabPanels["FLY"]
local col3 = TAB_COLOR["FLY"]

local spdRow = Instance.new("Frame")
spdRow.Size                   = UDim2.new(1, 0, 0, 34)
spdRow.BackgroundTransparency = 1
spdRow.Parent                 = flP

local function mkSpdBtn(txt, xPos)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, 34, 1, 0)
    b.Position         = UDim2.new(0, xPos, 0, 0)
    b.Text             = txt
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 18
    b.BackgroundColor3 = Color3.fromRGB(28, 28, 46)
    b.TextColor3       = Color3.fromRGB(200, 180, 255)
    b.BorderSizePixel  = 0
    b.Parent           = spdRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local spdMinus = mkSpdBtn("-", 0)
local spdLbl   = Instance.new("TextLabel")
spdLbl.Size                   = UDim2.new(1, -76, 1, 0)
spdLbl.Position               = UDim2.new(0, 38, 0, 0)
spdLbl.BackgroundTransparency = 1
spdLbl.Text                   = "SPD: 50"
spdLbl.Font                   = Enum.Font.GothamBold
spdLbl.TextSize               = 14
spdLbl.TextColor3             = Color3.fromRGB(210, 190, 255)
spdLbl.Parent                 = spdRow
local spdPlus = mkSpdBtn("+", 192)

local flyBtn = mkBtn(flP, "Fly: OFF", 42, col3)
mkLbl(flP, "Analog kiri = gerak | Jump = naik | Shift = turun", 86, Color3.fromRGB(90,90,115), 32, 11)
mkLbl(flP, "Butuh PlayerModule (default game)", 116, Color3.fromRGB(70,70,95), 20, 11)

spdMinus.MouseButton1Click:Connect(function()
    flySpeed = math.max(10, flySpeed - 10); spdLbl.Text = "SPD: " .. flySpeed
end)
spdPlus.MouseButton1Click:Connect(function()
    flySpeed = math.min(300, flySpeed + 10); spdLbl.Text = "SPD: " .. flySpeed
end)
flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    if flyEnabled then setupFlyPhysics() else disableFly() end
    flyBtn.Text             = flyEnabled and "Fly: ON" or "Fly: OFF"
    flyBtn.BackgroundColor3 = flyEnabled and Color3.fromRGB(100, 40, 175) or Color3.fromRGB(22, 22, 36)
end)

-- ===========================
-- TAB AIM
-- ===========================
local aP   = tabPanels["AIM"]
local col4 = TAB_COLOR["AIM"]

if not aimUnlocked then
    local li = mkLbl(aP, "🔒", 28, Color3.fromRGB(255,80,0), 38, 26)
    li.TextXAlignment = Enum.TextXAlignment.Center
    local lm = mkLbl(aP, "Hanya tersedia di map Flick!", 72, Color3.fromRGB(180,90,40), 32, 12)
    lm.TextXAlignment = Enum.TextXAlignment.Center
    local li2 = mkLbl(aP, "ID: 136801880565837", 108, Color3.fromRGB(100,100,130), 20, 10)
    li2.TextXAlignment = Enum.TextXAlignment.Center
    mkLbl(aP, "Buka script di map yang benar.", 132, Color3.fromRGB(80,80,110), 32, 10)
else
    mkLbl(aP, "✅ Flick Map Terdeteksi", 0, Color3.fromRGB(0,220,100), 20, 11)
    local aimBtn  = mkBtn(aP, "AIMLOCK: OFF", 24, col4)
    local modeBtn = mkBtn(aP, "MODE: SMOOTH", 68, col4)
    local espBtn  = mkBtn(aP, "ESP: OFF",    112, col4)
    mkLbl(aP, "Hijau = visible | Orange = behind wall", 156, Color3.fromRGB(90,90,115), 20, 10)
    mkLbl(aP, "SNAP = instant | SMOOTH = lerp 0.15",    174, Color3.fromRGB(90,90,115), 20, 10)

    aimBtn.MouseButton1Click:Connect(function()
        aimbotEnabled = not aimbotEnabled
        aimBtn.Text             = aimbotEnabled and "AIMLOCK: ON" or "AIMLOCK: OFF"
        aimBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(200,60,0) or Color3.fromRGB(22,22,36)
    end)
    modeBtn.MouseButton1Click:Connect(function()
        aimMode = aimMode == "SMOOTH" and "SNAP" or "SMOOTH"
        modeBtn.Text             = "MODE: " .. aimMode
        modeBtn.BackgroundColor3 = aimMode == "SNAP" and Color3.fromRGB(180,40,0) or Color3.fromRGB(22,22,36)
    end)
    espBtn.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        if not espEnabled then clearESP() end
        espBtn.Text             = espEnabled and "ESP: ON" or "ESP: OFF"
        espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(200,60,0) or Color3.fromRGB(22,22,36)
    end)
end

-- ===========================
-- TAB CREDITS
-- ===========================
local cP   = tabPanels["CREDS"]
local gold = Color3.fromRGB(255, 200, 0)
local dim  = Color3.fromRGB(110, 110, 140)
local wht  = Color3.fromRGB(210, 210, 230)

-- DmbHub — paling gede, paling atas
local dmbLbl = Instance.new("TextLabel")
dmbLbl.Size               = UDim2.new(1, 0, 0, 44)
dmbLbl.Position           = UDim2.new(0, 0, 0, 0)
dmbLbl.BackgroundTransparency = 1
dmbLbl.Text               = "DmbHub"
dmbLbl.Font               = Enum.Font.GothamBold
dmbLbl.TextSize            = 34
dmbLbl.TextColor3          = gold
dmbLbl.TextXAlignment      = Enum.TextXAlignment.Center
dmbLbl.Parent              = cP

local subLbl = Instance.new("TextLabel")
subLbl.Size               = UDim2.new(1, 0, 0, 14)
subLbl.Position           = UDim2.new(0, 0, 0, 44)
subLbl.BackgroundTransparency = 1
subLbl.Text               = "owner & fling original"
subLbl.Font               = Enum.Font.Gotham
subLbl.TextSize            = 10
subLbl.TextColor3          = Color3.fromRGB(160, 130, 0)
subLbl.TextXAlignment      = Enum.TextXAlignment.Center
subLbl.Parent              = cP

-- divider
local div1 = Instance.new("Frame")
div1.Size             = UDim2.new(1, 0, 0, 1)
div1.Position         = UDim2.new(0, 0, 0, 64)
div1.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
div1.BorderSizePixel  = 0
div1.Parent           = cP

-- credit rows helper
local function credRow(icon, label, name, yPos, nameCol)
    local row = Instance.new("Frame")
    row.Size                   = UDim2.new(1, 0, 0, 26)
    row.Position               = UDim2.new(0, 0, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent                 = cP

    local iconL = Instance.new("TextLabel")
    iconL.Size               = UDim2.new(0, 18, 1, 0)
    iconL.BackgroundTransparency = 1
    iconL.Text               = icon
    iconL.Font               = Enum.Font.GothamBold
    iconL.TextSize            = 12
    iconL.TextColor3          = dim
    iconL.Parent              = row

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0, 90, 1, 0)
    lbl.Position           = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize            = 11
    lbl.TextColor3          = dim
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    lbl.Parent              = row

    local namL = Instance.new("TextLabel")
    namL.Size               = UDim2.new(0, 90, 1, 0)
    namL.Position           = UDim2.new(0, 112, 0, 0)
    namL.BackgroundTransparency = 1
    namL.Text               = name
    namL.Font               = Enum.Font.GothamBold
    namL.TextSize            = 12
    namL.TextColor3          = nameCol or wht
    namL.TextXAlignment      = Enum.TextXAlignment.Left
    namL.Parent              = row
end

credRow("🎯", "Fling & Auto-Fling", "DmbHub",     70,  gold)
credRow("💫", "Super Ring Parts",   "lukas",       98,  wht)
credRow("✈️", "Fly FE Logic",       "Muffin",     126,  wht)
credRow("🔫", "Aimlock & ESP",      "potato.sys", 154,  Color3.fromRGB(180,220,180))

-- divider 2
local div2 = Instance.new("Frame")
div2.Size             = UDim2.new(1, 0, 0, 1)
div2.Position         = UDim2.new(0, 0, 0, 186)
div2.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
div2.BorderSizePixel  = 0
div2.Parent           = cP

-- compiled by
local compLbl = Instance.new("TextLabel")
compLbl.Size               = UDim2.new(1, 0, 0, 16)
compLbl.Position           = UDim2.new(0, 0, 0, 192)
compLbl.BackgroundTransparency = 1
compLbl.Text               = "compiled & built by"
compLbl.Font               = Enum.Font.Gotham
compLbl.TextSize            = 10
compLbl.TextColor3          = dim
compLbl.TextXAlignment      = Enum.TextXAlignment.Center
compLbl.Parent              = cP

local taterLbl = Instance.new("TextLabel")
taterLbl.Size               = UDim2.new(1, 0, 0, 22)
taterLbl.Position           = UDim2.new(0, 0, 0, 208)
taterLbl.BackgroundTransparency = 1
taterLbl.Text               = "🥔 tater"
taterLbl.Font               = Enum.Font.GothamBold
taterLbl.TextSize            = 14
taterLbl.TextColor3          = Color3.fromRGB(180, 140, 80)
taterLbl.TextXAlignment      = Enum.TextXAlignment.Center
taterLbl.Parent              = cP

-- ===========================
-- MINIMIZE / CLOSE
-- ===========================
local minimized = false
local fullH     = UDim2.new(0, 240, 0, 340)
local miniH     = UDim2.new(0, 240, 0, 36)

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MainFrame:TweenSize(minimized and miniH or fullH, "Out", "Quad", 0.25, true)
    MinBtn.Text         = minimized and "+" or "-"
    TabBar.Visible      = not minimized
    ContentArea.Visible = not minimized
end)

CloseBtn.MouseButton1Click:Connect(function()
    disableFly()
    clearESP()
    aimbotEnabled = false
    espEnabled    = false
    ScreenGui:Destroy()
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if flyEnabled then setupFlyPhysics() end
    if godEnabled then enableGod() end
end)

switchTab("FLING")
