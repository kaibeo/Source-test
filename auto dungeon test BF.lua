-- =====================================================
-- AUTO DUNGEON FULL FINAL
-- Green Diamond Priority | Sync Dungeon Mode
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
    Callback = function(v)
        getgenv().DungeonMode = v
    end
})

DungeonTab:Dropdown({
    Name = "Select Weapon Type",
    Options = { "Melee", "Sword", "Fruit" },
    Default = "Melee",
    Callback = function(v)
        getgenv().PreferredWeapon = v
    end
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
    local playerGui = LP:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local gui = playerGui:FindFirstChild("DungeonSettings", true)
    if not gui or not gui.Enabled then return end

    for _,obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextButton") then
            local btnText = (obj.Text or ""):lower()
            local mode = (getgenv().DungeonMode or ""):lower()
            if btnText ~= "" and mode ~= "" and btnText:find(mode) then
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
-- AUTO GREEN CORE (GREEN DIAMOND ONLY)
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
local lastGreenPos = nil
local lastGreenPosAfterDie = nil
local needReturnAfterDie = false
local lastHRPPos = nil
local lastMoveTick = os.clock()
local scanTick = 0
local lastEnemyTime = 0

-- ================== SAFE GET ==================
local function getHRPandHum()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
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
        Vector3.new(
            hrp.Position.X + (pos.X - hrp.Position.X) * speed,
            pos.Y + height,
            hrp.Position.Z + (pos.Z - hrp.Position.Z) * speed
        )
    )
    lastMoveTick = os.clock()
end

-- ================== SCAN GREEN (ICON ONLY) ==================
local function ScanGreen(hrp)
    if os.clock() - scanTick < SCAN_INTERVAL then return end
    scanTick = os.clock()

    for _, gui in ipairs(Workspace:GetDescendants()) do
        if gui:IsA("BillboardGui") then
            local part = gui.Adornee
            if part and part:IsA("BasePart") then
                local flatDist = (Vector3.new(part.Position.X,0,part.Position.Z)
                    - Vector3.new(hrp.Position.X,0,hrp.Position.Z)).Magnitude
                if flatDist <= GREEN_HALF_RANGE then
                    for _, ui in ipairs(gui:GetDescendants()) do
                        if (ui:IsA("Frame") or ui:IsA("ImageLabel")) then
                            local c = ui.BackgroundColor3
                            if c and c.G > c.R and c.G > c.B then
                                lastGreenPos = part.Position
                                GreenLock = true
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ================== ENEMY ==================
local function FindEnemy(hrp)
    local e = Workspace:FindFirstChild("Enemies")
    if not e then return end
    local best, dist = nil, math.huge
    for _,v in ipairs(e:GetChildren()) do
        local h = v:FindFirstChild("Humanoid")
        local r = v:FindFirstChild("HumanoidRootPart")
        if h and r and h.Health > 0 then
            local d = (r.Position - hrp.Position).Magnitude
            if d < dist then
                dist = d
                best = r
            end
        end
    end
    return best
end

-- ================== MAIN LOOP ==================
RunService.Heartbeat:Connect(function()
    if not getgenv().AutoDungeon then return end

    local hrp, hum = getHRPandHum()
    if not hrp or not hum then return end
    LockY(hrp)

    if hum.Health <= 0 then
        if lastGreenPos then
            lastGreenPosAfterDie = lastGreenPos
            needReturnAfterDie = true
        end
        GreenLock = false
        getgenv().IsFarmingEnemy = false
        return
    end

    if lastHRPPos and (hrp.Position - lastHRPPos).Magnitude > TELEPORT_DISTANCE then
        GreenLock = false
        needReturnAfterDie = false
        lastGreenPosAfterDie = nil
    end
    lastHRPPos = hrp.Position

    if os.clock() - lastMoveTick > STUCK_TIME then
        GreenLock = false
    end

    if needReturnAfterDie and lastGreenPosAfterDie then
        MoveTo(hrp, lastGreenPosAfterDie, HEIGHT_GREEN)
        if (hrp.Position - lastGreenPosAfterDie).Magnitude < 10 then
            needReturnAfterDie = false
        end
        return
    end

    if GreenLock and lastGreenPos then
        MoveTo(hrp, lastGreenPos, HEIGHT_GREEN)
        if (hrp.Position - lastGreenPos).Magnitude < 8 then
            GreenLock = false
        end
        return
    end

    local enemy = FindEnemy(hrp)
    if enemy then
        getgenv().IsFarmingEnemy = true
        lastEnemyTime = os.clock()
        MoveTo(hrp, enemy.Position, HEIGHT_NORMAL)
        return
    end

    if getgenv().IsFarmingEnemy and os.clock() - lastEnemyTime > 0.3 then
        getgenv().IsFarmingEnemy = false
    end

    ScanGreen(hrp)
    MoveTo(hrp, hrp.Position, HEIGHT_NORMAL)
end)

-- ================== FAST ATTACK (USER VERSION) ==================
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
    v.ChildAdded:Connect(function(n)
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end)
end

task.spawn(function()
    while task.wait(0.0005) do
        if not getgenv().FastAttack then continue end
        if not getgenv().AutoDungeon then continue end
        if not getgenv().IsFarmingEnemy then continue end

        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        local parts = {}
        for _, x in ipairs({Workspace.Enemies, Workspace.Characters}) do
            for _, v in ipairs(x and x:GetChildren() or {}) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if v ~= char and hrp and hum and hum.Health > 0
                and (hrp.Position - root.Position).Magnitude <= 120 then
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
                local head = parts[1][1]:FindFirstChild("Head")
                if not head then return end
                ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(
                    head, parts, {},
                    tostring(LP.UserId):sub(2,4)..tostring(coroutine.running()):sub(11,15)
                )
                cloneref(remote):FireServer(
                    string.gsub("RE/RegisterHit", ".", function(c)
                        return string.char(bit32.bxor(
                            string.byte(c),
                            math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
                        ))
                    end),
                    bit32.bxor(
                        idremote + 909090,
                        ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2
                    ),
                    head, parts
                )
            end)
        end
    end
end)