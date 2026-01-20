-- =====================================================
-- AUTO DUNGEON FULL FINAL
-- Green Priority + Auto 0/4 (FIXED)
-- PC + Mobile | Delta OK
-- =====================================================

-- ================== LOAD WINDUI ==================
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "ZMatrix | Auto Dungeon",
    Icon = "ghost",
    Folder = "ZM_Dungeon",
    Size = UDim2.fromOffset(580,460),
    Theme = "Dark",
})

local DungeonTab = Window:Tab({ Name = "Dungeon", Icon = "sword" })
local SettingTab = Window:Tab({ Name = "Settings", Icon = "settings" })

-- ================== GLOBAL FLAGS ==================
getgenv().AutoDungeon      = false
getgenv().AutoStartDungeon = false
getgenv().FastAttack       = false
getgenv().DungeonMode      = "Normal"
getgenv().PreferredWeapon  = "Melee"
getgenv().IsFarmingEnemy   = false

-- ================== UI ==================
DungeonTab:Toggle({
    Name = "Auto Dungeon",
    Callback = function(v) getgenv().AutoDungeon = v end
})

DungeonTab:Toggle({
    Name = "Auto Start Dungeon",
    Callback = function(v) getgenv().AutoStartDungeon = v end
})

DungeonTab:Dropdown({
    Name = "Select Dungeon Mode",
    Options = { "Normal", "Hard", "Challenge" },
    Default = "Normal",
    Callback = function(v) getgenv().DungeonMode = v end
})

SettingTab:Toggle({
    Name = "Fast Attack",
    Callback = function(v) getgenv().FastAttack = v end
})

-- ================== SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

-- =====================================================
-- AUTO SELECT DUNGEON MODE (SYNC UI -> GAME GUI)
-- =====================================================
local function AutoSelectDungeonMode()
    local gui = LP.PlayerGui:FindFirstChild("DungeonSettings", true)
    if not gui or not gui.Enabled then return end

    for _,obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextButton") then
            local t = (obj.Text or ""):lower()
            if t:find(getgenv().DungeonMode:lower()) then
                pcall(function()
                    firesignal(obj.MouseButton1Click)
                end)
                return
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.4) do
        if getgenv().AutoStartDungeon then
            AutoSelectDungeonMode()
        end
    end
end)

-- =====================================================
-- AUTO GREEN + AUTO 0/4 CORE
-- =====================================================
local HEIGHT_NORMAL = 20
local HEIGHT_GREEN  = 10
local BASE_SPEED = 0.55
local FAST_SPEED = 0.75
local TELEPORT_DISTANCE = 180
local GREEN_HALF_RANGE = 500
local SCAN_INTERVAL = 0.15
local STUCK_TIME = 1.2

local GreenLock = false
local GoingToZero = false
local lastGreenPos = nil
local lastHRPPos = nil
local scanTick = 0
local lastMoveTick = os.clock()

-- ================== SAFE GET ==================
local function getHRPandHum()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hrp and hum then return hrp, hum end
end

-- ================== LOCK Y ==================
local function LockY(hrp)
    local bp = hrp:FindFirstChild("Y_LOCK")
    if not bp then
        bp = Instance.new("BodyPosition")
        bp.Name = "Y_LOCK"
        bp.MaxForce = Vector3.new(0, math.huge, 0)
        bp.P = 60000
        bp.D = 1200
        bp.Parent = hrp
    end
    bp.Position = Vector3.new(0, hrp.Position.Y, 0)
end

-- ================== MOVE ==================
local function MoveTo(hrp, pos, height)
    local dist = (Vector3.new(pos.X, hrp.Position.Y, pos.Z) - hrp.Position).Magnitude
    local speed = dist > 60 and FAST_SPEED or BASE_SPEED
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = CFrame.new(
        hrp.Position:Lerp(Vector3.new(pos.X, pos.Y + height, pos.Z), speed)
    )
    lastMoveTick = os.clock()
end

-- ================== FIND 0/4 ==================
local function FindZeroArea()
    local list = {}
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local lb = v:FindFirstChildWhichIsA("TextLabel")
            if lb and lb.Text == "0/4" then
                local p = v.Adornee
                if p and p:IsA("BasePart") then
                    table.insert(list, p)
                end
            end
        end
    end
    if #list > 0 then
        return list[math.random(#list)]
    end
end

-- ================== SCAN GREEN (ICON ONLY) ==================
local function ScanGreen(hrp)
    if os.clock() - scanTick < SCAN_INTERVAL then return end
    scanTick = os.clock()

    for _,gui in ipairs(Workspace:GetDescendants()) do
        if gui:IsA("BillboardGui") then
            local p = gui.Adornee
            if p and p:IsA("BasePart") then
                if (Vector3.new(p.Position.X,0,p.Position.Z)
                    - Vector3.new(hrp.Position.X,0,hrp.Position.Z)).Magnitude <= GREEN_HALF_RANGE then
                    for _,ui in ipairs(gui:GetDescendants()) do
                        if (ui:IsA("Frame") or ui:IsA("ImageLabel")) then
                            local c = ui.BackgroundColor3
                            if c and c.G > c.R and c.G > c.B then
                                lastGreenPos = p.Position
                                GreenLock = true
                                GoingToZero = false
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ================== MAIN LOOP ==================
RunService.Heartbeat:Connect(function()
    if not getgenv().AutoDungeon then return end

    local hrp, hum = getHRPandHum()
    if not hrp or not hum then return end
    LockY(hrp)

    -- TELEPORT MAP RESET
    if lastHRPPos and (hrp.Position - lastHRPPos).Magnitude > TELEPORT_DISTANCE then
        GreenLock = false
        GoingToZero = false
        lastGreenPos = nil
    end
    lastHRPPos = hrp.Position

    -- 🔒 GREEN PRIORITY
    if GreenLock and lastGreenPos then
        MoveTo(hrp, lastGreenPos, HEIGHT_GREEN)
        if (hrp.Position - lastGreenPos).Magnitude < 8 then
            GreenLock = false
        end
        return
    end

    -- 🟦 AUTO GO 0/4
    if not lastGreenPos then
        if not GoingToZero then
            local z = FindZeroArea()
            if z then GoingToZero = true end
        end
        if GoingToZero then
            local z = FindZeroArea()
            if z then
                MoveTo(hrp, z.Position, HEIGHT_NORMAL)
                return
            else
                GoingToZero = false
            end
        end
    end

    -- 🔍 SEARCH GREEN
    ScanGreen(hrp)
    MoveTo(hrp, hrp.Position, HEIGHT_NORMAL)
end)