-- =====================================================
-- AUTO DUNGEON FULL | WINDUI (RELEASE)
-- Destroy chạy chung Auto Dungeon
-- Fast Attack = USER VERSION
-- PC + Mobile + Delta X OK
-- =====================================================

-- ===== LOAD WINDUI (RELEASE) =====
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "ZM Beta TEST",
    Icon = "home",
    Author = "Full Logic",
})

-- ===== TABS =====
local DungeonTab = Window:Tab({ Name = "Dungeon", Icon = "swords" })
local SettingTab = Window:Tab({ Name = "Setting", Icon = "settings" })

-- ===== GLOBAL FLAGS =====
getgenv().AutoDungeon       = false
getgenv().AutoStartDungeon  = false
getgenv().FastAttack        = false
getgenv().DungeonMode       = "Normal"
getgenv().PreferredWeapon   = "Melee"

-- ===== UI : TAB DUNGEON =====
DungeonTab:Toggle({
    Name = "Auto Dungeon",
    Default = false,
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

        local target = areas[math.random(#areas)]
        TweenService:Create(
            hrp,
            TweenInfo.new((hrp.Position-target.Position).Magnitude/250, Enum.EasingStyle.Linear),
            {CFrame = target.CFrame + Vector3.new(0,5,0)}
        ):Play()
    end
})

DungeonTab:Toggle({
    Name = "Auto Start Dungeon",
    Default = false,
    Callback = function(v) getgenv().AutoStartDungeon = v end
})

-- 🔽 DROPDOWN CHỌN MODE (PHẢI HIỆN)
DungeonTab:Dropdown({
    Name = "Select Dungeon Mode",
    Default = "Normal",
    Options = { "Normal", "Hard", "Challenge" },
    Callback = function(v) getgenv().DungeonMode = v end
})

-- 🔽 DROPDOWN CHỌN VŨ KHÍ (PHẢI HIỆN)
DungeonTab:Dropdown({
    Name = "Select Weapon Type",
    Default = "Melee",
    Options = { "Melee", "Sword", "Fruit" },
    Callback = function(v) getgenv().PreferredWeapon = v end
})

-- ===== UI : TAB SETTING =====
SettingTab:Toggle({
    Name = "Fast Attack",
    Default = false,
    Callback = function(v) getgenv().FastAttack = v end
})

-- =====================================================
-- SERVICES
-- =====================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

-- =====================================================
-- AUTO DUNGEON CORE (Destroy + Farm + Green)
-- =====================================================
local HEIGHT_FARM  = 18   -- bay trên đầu quái
local HEIGHT_GREEN = 10   -- hạ thấp khi tới chấm xanh
local HEIGHT_IDLE  = 20
local SPEED        = 0.6

local lastGreenPos = nil

local function IsShadow(name)
    return (name or ""):lower():find("shadow") ~= nil
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

local function FindNearestEnemy()
    local e = workspace:FindFirstChild("Enemies")
    if not e then return end
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local best, dist = nil, math.huge
    for _,v in ipairs(e:GetChildren()) do
        if not IsShadow(v.Name) then
            local h = v:FindFirstChild("Humanoid")
            local r = v:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then
                local d = (r.Position - root.Position).Magnitude
                if d < dist then
                    dist = d
                    best = r
                end
            end
        end
    end
    return best
end

local function ScanGreen(hrp)
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local lb = v:FindFirstChildWhichIsA("TextLabel", true)
            local part = v.Adornee
            if lb and part and part:IsA("BasePart") then
                local c = lb.TextColor3
                if c.G > c.R and c.G > c.B then
                    lastGreenPos = part.Position
                    return
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not getgenv().AutoDungeon then return end
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 1️⃣ DESTROY (ưu tiên tuyệt đối)
    local destroy = FindDestroy()
    if destroy then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = hrp.CFrame:Lerp(
            CFrame.new(destroy.Position + Vector3.new(0, HEIGHT_FARM, 0)),
            SPEED
        )
        return
    end

    -- 2️⃣ FARM QUÁI
    local enemy = FindNearestEnemy()
    if enemy then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = hrp.CFrame:Lerp(
            CFrame.new(enemy.Position + Vector3.new(0, HEIGHT_FARM, 0)),
            SPEED
        )
        return
    end

    -- 3️⃣ CHẤM XANH
    ScanGreen(hrp)
    if lastGreenPos then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = hrp.CFrame:Lerp(
            CFrame.new(lastGreenPos + Vector3.new(0, HEIGHT_GREEN, 0)),
            SPEED
        )
        return
    end

    -- 4️⃣ HOVER
    hrp.CFrame = hrp.CFrame:Lerp(
        CFrame.new(hrp.Position.X, HEIGHT_IDLE, hrp.Position.Z),
        SPEED
    )
end)

-- =====================================================
-- AUTO START DUNGEON + MODE
-- =====================================================
local StartRemote
for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") and v.Name:lower():find("start") then
        StartRemote = v
    end
end

task.spawn(function()
    while task.wait(1) do
        if not getgenv().AutoStartDungeon then continue end
        local gui = lp.PlayerGui:FindFirstChild("DungeonSettings", true)
        if not (gui and gui.Enabled) then continue end

        for _,b in ipairs(gui:GetDescendants()) do
            if b:IsA("TextButton") and b.Text
            and b.Text:lower():find(getgenv().DungeonMode:lower()) then
                pcall(function() b:MouseButton1Click() end)
                task.wait(0.3)
                break
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
task.spawn(function()
    while task.wait(0.6) do
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local bp = lp:FindFirstChild("Backpack")
        if not hum or not bp then continue end

        local cur = char:FindFirstChildOfClass("Tool")
        local function typeOf(t)
            local wt = t:GetAttribute("WeaponType")
            if wt == "Melee" or wt == "Sword" then return wt end
            return "Fruit"
        end

        if cur and typeOf(cur) == getgenv().PreferredWeapon then continue end
        for _,tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and typeOf(tool) == getgenv().PreferredWeapon then
                hum:EquipTool(tool)
                break
            end
        end
    end
end)

-- =====================================================
-- FAST ATTACK (USER VERSION - TOGGLE)
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

        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local parts = {}
        for _, x in ipairs({workspace.Enemies, workspace.Characters}) do
            for _, v in ipairs(x and x:GetChildren() or {}) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if v ~= char and hrp and hum and hum.Health > 0
                and (hrp.Position - root.Position).Magnitude <= 60 then
                    for _, _v in ipairs(v:GetChildren()) do
                        if _v:IsA("BasePart") then
                            parts[#parts+1] = {v, _v}
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
                    tostring(lp.UserId):sub(2,4)..tostring(coroutine.running()):sub(11,15)
                )
                if remote and idremote then
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
                end
            end)
        end
    end
end)