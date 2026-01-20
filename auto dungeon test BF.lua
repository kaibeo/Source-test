-- =====================================================
-- AUTO DUNGEON FULL FINAL
-- Base: AUTO GREEN CORE (USER)
-- PC + Mobile | Delta X | Stable
-- =====================================================

-- ================== LOAD WINDUI ==================
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "Auto Dungeon",
    Icon = "home",
    Author = "Final Build",
})

local DungeonTab = Window:Tab({ Name = "Dungeon", Icon = "swords" })
local SettingTab = Window:Tab({ Name = "Setting", Icon = "settings" })

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

DungeonTab:Button({
    Name = "TP Random (0/4)",
    Callback = function()
        local TweenService = game:GetService("TweenService")
        local lp = game.Players.LocalPlayer
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local areas = {}
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BillboardGui") then
                local lb = v:FindFirstChildWhichIsA("TextLabel")
                if lb and lb.Text == "0/4" and v.Adornee and v.Adornee:IsA("BasePart") then
                    table.insert(areas, v.Adornee)
                end
            end
        end
        if #areas == 0 then return end

        local t = areas[math.random(#areas)]
        TweenService:Create(
            hrp,
            TweenInfo.new((hrp.Position - t.Position).Magnitude / 250, Enum.EasingStyle.Linear),
            {CFrame = t.CFrame + Vector3.new(0,5,0)}
        ):Play()
    end
})

DungeonTab:Toggle({
    Name = "Auto Start Dungeon",
    Callback = function(v) getgenv().AutoStartDungeon = v end
})

DungeonTab:Dropdown({
    Name = "Select Dungeon Mode",
    Options = {
        {Name="Normal",Value="Normal"},
        {Name="Hard",Value="Hard"},
        {Name="Challenge",Value="Challenge"}
    },
    Default = "Normal",
    Callback = function(v) getgenv().DungeonMode = v end
})

DungeonTab:Dropdown({
    Name = "Select Weapon Type",
    Options = {
        {Name="Melee",Value="Melee"},
        {Name="Sword",Value="Sword"},
        {Name="Fruit",Value="Fruit"}
    },
    Default = "Melee",
    Callback = function(v) getgenv().PreferredWeapon = v end
})

SettingTab:Toggle({
    Name = "Fast Attack",
    Callback = function(v) getgenv().FastAttack = v end
})

-- ================== SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- =====================================================
-- ===== AUTO GREEN CORE (GIỮ NGUYÊN)
-- =====================================================
local HEIGHT_NORMAL = 20
local HEIGHT_GREEN  = 10
local BASE_SPEED = 0.55
local FAST_SPEED = 0.75
local TELEPORT_DISTANCE = 180
local GREEN_HALF_RANGE = 500
local SCAN_INTERVAL = 0.15
local STUCK_TIME = 1.2

local State = "SEARCH_GREEN"
local lastGreenPos = nil
local lastHRPPos = nil
local lastMoveTick = os.clock()
local scanTick = 0

local function getHRPandHum()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp and hum then
        return hrp, hum
    end
end

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

local function ScanGreen(hrp)
    if os.clock() - scanTick < SCAN_INTERVAL then return end
    scanTick = os.clock()

    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local part = v.Adornee or v.Parent
            if part and part:IsA("BasePart") then
                local dx = math.abs(part.Position.X - hrp.Position.X)
                local dz = math.abs(part.Position.Z - hrp.Position.Z)
                if dx <= GREEN_HALF_RANGE and dz <= GREEN_HALF_RANGE then
                    for _,ui in ipairs(v:GetDescendants()) do
                        if ui:IsA("TextLabel") then
                            local c = ui.TextColor3
                            if c.G > c.R and c.G > c.B then
                                lastGreenPos = part.Position
                                State = "MOVE_GREEN"
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

-- =====================================================
-- ===== FARM / DESTROY / FILTER
-- =====================================================
local function IsShadow(name)
    return name:lower():find("shadow")
end

local function FindDestroy()
    local e = workspace:FindFirstChild("Enemies")
    if not e then return end
    for _,v in ipairs(e:GetChildren()) do
        if v.Name:lower():find("destroy") then
            local h = v:FindFirstChild("Humanoid")
            local r = v:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then
                return r
            end
        end
    end
end

local function FindEnemy(hrp)
    local e = workspace:FindFirstChild("Enemies")
    if not e then return end
    local best, dist = nil, math.huge
    for _,v in ipairs(e:GetChildren()) do
        if not IsShadow(v.Name) then
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
    end
    return best
end

-- =====================================================
-- ===== MAIN AUTO DUNGEON LOOP
-- =====================================================
RunService.Heartbeat:Connect(function()
    if not getgenv().AutoDungeon then return end

    local hrp, hum = getHRPandHum()
    if not hrp or not hum then return end

    -- DIE
    if hum.Health <= 0 then
        State = "RETURN_AFTER_DIE"
        getgenv().IsFarmingEnemy = false
        return
    end

    -- TELEPORT
    if lastHRPPos and (hrp.Position - lastHRPPos).Magnitude > TELEPORT_DISTANCE then
        State = "SEARCH_GREEN"
    end
    lastHRPPos = hrp.Position

    -- STUCK
    if os.clock() - lastMoveTick > STUCK_TIME then
        State = "SEARCH_GREEN"
    end

    -- DESTROY
    local destroy = FindDestroy()
    if destroy then
        getgenv().IsFarmingEnemy = true
        MoveTo(hrp, destroy.Position, HEIGHT_NORMAL)
        return
    end

    -- FARM ENEMY
    local enemy = FindEnemy(hrp)
    if enemy then
        getgenv().IsFarmingEnemy = true
        MoveTo(hrp, enemy.Position, HEIGHT_NORMAL)
        return
    else
        getgenv().IsFarmingEnemy = false
    end

    -- RETURN AFTER DIE
    if State == "RETURN_AFTER_DIE" and lastGreenPos then
        MoveTo(hrp, lastGreenPos, HEIGHT_GREEN)
        return
    end

    -- MOVE GREEN
    if State == "MOVE_GREEN" and lastGreenPos then
        MoveTo(hrp, lastGreenPos, HEIGHT_GREEN)
        return
    end

    -- SEARCH GREEN
    ScanGreen(hrp)
    MoveTo(hrp, hrp.Position, HEIGHT_NORMAL)
end)

-- =====================================================
-- ===== FAST ATTACK (USER VERSION – FIXED)
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
        for _, x in ipairs({workspace.Enemies, workspace.Characters}) do
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
        if #parts > 0 and tool
        and (tool:GetAttribute("WeaponType") == "Melee"
          or tool:GetAttribute("WeaponType") == "Sword") then
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