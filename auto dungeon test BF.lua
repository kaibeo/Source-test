-- =====================================================
-- AUTO DUNGEON FULL SCRIPT | WINDUI (RELEASE)
-- PC + Mobile + Delta X OK
-- =====================================================

-- LOAD WINDUI (RELEASE – ỔN ĐỊNH)
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

-- WINDOW
local Window = WindUI:CreateWindow({
    Title = "Auto Dungeon",
    Icon = "home",
    Author = "Auto Script",
})

local MainTab     = Window:Tab({ Name = "Main",     Icon = "home" })
local TeleportTab = Window:Tab({ Name = "Teleport", Icon = "map"  })
local DungeonTab  = Window:Tab({ Name = "Dungeon",  Icon = "swords" })
local StatusTab   = Window:Tab({ Name = "Status",   Icon = "info" })

-- =====================================================
-- GLOBAL
-- =====================================================
getgenv().AutoDungeon      = false
getgenv().FastAttack       = false
getgenv().AutoStartDungeon = false
getgenv().DungeonMode      = "Normal"
getgenv().PreferredWeapon  = "Melee"

-- =====================================================
-- UI
-- =====================================================
MainTab:Toggle({
    Name = "AUTO DUNGEON",
    Default = false,
    Callback = function(v)
        getgenv().AutoDungeon = v
    end
})

MainTab:Toggle({
    Name = "FAST ATTACK",
    Default = false,
    Callback = function(v)
        getgenv().FastAttack = v
    end
})

DungeonTab:Toggle({
    Name = "AUTO START DUNGEON",
    Default = false,
    Callback = function(v)
        getgenv().AutoStartDungeon = v
    end
})

DungeonTab:Dropdown({
    Name = "SELECT DUNGEON MODE",
    Default = "Normal",
    Options = { "Normal", "Hard", "Challenge" },
    Callback = function(v)
        getgenv().DungeonMode = v
    end
})

DungeonTab:Dropdown({
    Name = "SELECT WEAPON TYPE",
    Default = "Melee",
    Options = { "Melee", "Sword", "Fruit" },
    Callback = function(v)
        getgenv().PreferredWeapon = v
    end
})

local StatusLabel = StatusTab:Label({
    Text = "STATE: IDLE"
})

-- =====================================================
-- SERVICES
-- =====================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- =====================================================
-- AUTO DUNGEON (CHẤM XANH)
-- =====================================================
local HEIGHT_NORMAL = 20
local HEIGHT_GREEN  = 10
local MOVE_SPEED = 0.6
local GREEN_RANGE = 500
local scanTick = 0

local function getHRPandHum()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp and hum then
        return hrp, hum
    end
end

local function MoveTo(hrp, pos, height)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = CFrame.new(
        Vector3.new(
            hrp.Position.X + (pos.X - hrp.Position.X) * MOVE_SPEED,
            pos.Y + height,
            hrp.Position.Z + (pos.Z - hrp.Position.Z) * MOVE_SPEED
        )
    )
end

local lastGreenPos = nil

local function ScanGreen(hrp)
    if os.clock() - scanTick < 0.15 then return end
    scanTick = os.clock()

    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local part = v.Adornee or v.Parent
            if part and part:IsA("BasePart") then
                if math.abs(part.Position.X - hrp.Position.X) <= GREEN_RANGE
                and math.abs(part.Position.Z - hrp.Position.Z) <= GREEN_RANGE then
                    for _,ui in ipairs(v:GetDescendants()) do
                        if ui:IsA("TextLabel") then
                            local c = ui.TextColor3
                            if c.G > c.R and c.G > c.B then
                                lastGreenPos = part.Position
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not getgenv().AutoDungeon then return end
    local hrp, hum = getHRPandHum()
    if not hrp or not hum then return end

    ScanGreen(hrp)

    if lastGreenPos then
        StatusLabel:SetText("STATE: GREEN")
        MoveTo(hrp, lastGreenPos, HEIGHT_GREEN)
    else
        StatusLabel:SetText("STATE: HOVER")
        MoveTo(hrp, hrp.Position, HEIGHT_NORMAL)
    end
end)

-- =====================================================
-- TP RANDOM AREA 0/4
-- =====================================================
local function GetZeroAreas()
    local list = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local label = v:FindFirstChildWhichIsA("TextLabel")
            if label and label.Text == "0/4" then
                local part = v.Adornee
                if part and part:IsA("BasePart") then
                    table.insert(list, part)
                end
            end
        end
    end
    return list
end

TeleportTab:Button({
    Name = "TP RANDOM AREA (0/4)",
    Callback = function()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local areas = GetZeroAreas()
        if #areas == 0 then
            warn("❌ Không có khu 0/4")
            return
        end

        local target = areas[math.random(#areas)]
        local distance = (hrp.Position - target.Position).Magnitude
        local time = math.max(distance / 250, 0.1)

        TweenService:Create(
            hrp,
            TweenInfo.new(time, Enum.EasingStyle.Linear),
            {CFrame = target.CFrame + Vector3.new(0,5,0)}
        ):Play()
    end
})

-- =====================================================
-- AUTO START DUNGEON + MODE
-- =====================================================
local StartRemote
for _, v in pairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") and v.Name:lower():find("start") then
        StartRemote = v
    end
end

task.spawn(function()
    while task.wait(1) do
        if not getgenv().AutoStartDungeon then continue end

        local gui = lp.PlayerGui:FindFirstChild("DungeonSettings", true)
        if not (gui and gui.Enabled) then continue end

        for _,btn in ipairs(gui:GetDescendants()) do
            if btn:IsA("TextButton") and btn.Text then
                if btn.Text:lower():find(getgenv().DungeonMode:lower()) then
                    pcall(function()
                        btn:Activate()
                        btn:MouseButton1Click()
                    end)
                    task.wait(0.3)
                    break
                end
            end
        end

        if StartRemote then
            StartRemote:FireServer()
            task.wait(3)
        end
    end
end)

-- =====================================================
-- AUTO EQUIP WEAPON
-- =====================================================
local EquipTick = 0

local function GetWeaponType(tool)
    local t = tool:GetAttribute("WeaponType")
    if t == "Melee" or t == "Sword" then
        return t
    end
    return "Fruit"
end

task.spawn(function()
    while task.wait(0.5) do
        if os.clock() - EquipTick < 1.5 then continue end
        EquipTick = os.clock()

        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then continue end

        local current = char:FindFirstChildOfClass("Tool")
        if current and GetWeaponType(current) == getgenv().PreferredWeapon then
            continue
        end

        local bp = lp:FindFirstChild("Backpack")
        if not bp then continue end

        for _,tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and GetWeaponType(tool) == getgenv().PreferredWeapon then
                hum:EquipTool(tool)
                break
            end
        end
    end
end)

-- =====================================================
-- FAST ATTACK (GIỮ NGUYÊN – ỔN ĐỊNH)
-- =====================================================
local remote, idremote
for _, v in next, ({
    ReplicatedStorage.Util,
    ReplicatedStorage.Common,
    ReplicatedStorage.Remotes,
    ReplicatedStorage.Assets,
    ReplicatedStorage.FX
}) do
    for _, n in next, v:GetChildren() do
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end
end

task.spawn(function()
    while task.wait(0.05) do
        if not getgenv().FastAttack then continue end

        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local parts = {}
        for _, x in ipairs({Workspace.Enemies, Workspace.Characters}) do
            for _, v in ipairs(x and x:GetChildren() or {}) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if v ~= char and hrp and hum and hum.Health > 0
                and (hrp.Position - root.Position).Magnitude <= 60 then
                    for _, bp in ipairs(v:GetChildren()) do
                        if bp:IsA("BasePart") then
                            parts[#parts+1] = {v, bp}
                        end
                    end
                end
            end
        end

        local tool = char:FindFirstChildOfClass("Tool")
        if #parts > 0 and tool then
            pcall(function()
                require(ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit", true)
                ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
            end)
        end
    end
end)