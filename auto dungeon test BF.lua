--==================================================
-- ZMATRIX | AUTO DUNGEON FULL FINAL (ALL-IN-ONE)
-- UI: Banana UI
-- Fast Attack: KEEP USER VERSION
-- PC + Mobile | Delta OK
--==================================================

---------------- UI ----------------
local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/kaibeo/Updatetest/refs/heads/main/UiBanana%20G%E1%BB%91c.lua"
))()

local Main = Library.CreateMain({ Desc = "ZMatrix Auto Dungeon" })

local DungeonPage = Main.CreatePage({
    Page_Name = "Dungeon",
    Page_Title = "Dungeon"
})

local SettingPage = Main.CreatePage({
    Page_Name = "Settings",
    Page_Title = "Settings"
})

---------------- GLOBAL FLAGS ----------------
getgenv().AutoDungeon = false
getgenv().FastAttack  = false
getgenv().AutoTPZero  = false
getgenv().AutoStartDungeon = false
getgenv().DungeonMode = "Normal"
getgenv().WeaponType  = "Melee"

---------------- UI : DUNGEON ----------------
local S1 = DungeonPage.CreateSection("Dungeon Control")

S1.CreateToggle({
    Title = "Auto Dungeon",
    Desc  = "Destroy > Farm > Green > Die Return",
    Default = false
}, function(v)
    getgenv().AutoDungeon = v
end)

S1.CreateButton({
    Title = "TP Random 0/4"
}, function()
    getgenv().AutoTPZero = true
end)

S1.CreateToggle({
    Title = "Auto Start Dungeon",
    Default = false
}, function(v)
    getgenv().AutoStartDungeon = v
end)

S1.CreateDropdown({
    Title = "Dungeon Mode",
    List = {"Normal","Hard","Challenge"},
    Default = "Normal"
}, function(v)
    getgenv().DungeonMode = v
end)

S1.CreateDropdown({
    Title = "Weapon Type",
    List = {"Melee","Sword","Fruit"},
    Default = "Melee"
}, function(v)
    getgenv().WeaponType = v
end)

---------------- UI : SETTINGS ----------------
local S2 = SettingPage.CreateSection("Combat")

S2.CreateToggle({
    Title = "Fast Attack",
    Default = false
}, function(v)
    getgenv().FastAttack = v
end)

---------------- SERVICES ----------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer

---------------- CONFIG ----------------
local HEIGHT_FARM   = 20
local HEIGHT_GREEN  = 7
local MOVE_SPEED    = 0.6
local TELEPORT_DIST = 180

---------------- STATE ----------------
local LastGreenPos = nil
local LastHRPPos = nil
local ReturnAfterDie = false
local ZeroTarget = nil

local IgnoredEnemies = {}
local DamageCheck = {}

---------------- SAFE GET ----------------
local function getHRPandHum()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hrp and hum then
        return hrp, hum
    end
end

---------------- LOCK Y ----------------
local function LockY(hrp)
    local bp = hrp:FindFirstChild("LOCK_Y")
    if not bp then
        bp = Instance.new("BodyPosition")
        bp.Name = "LOCK_Y"
        bp.MaxForce = Vector3.new(0, math.huge, 0)
        bp.P = 60000
        bp.D = 1500
        bp.Parent = hrp
    end
    bp.Position = Vector3.new(0, hrp.Position.Y, 0)
end

---------------- MOVE ----------------
local function MoveTo(hrp, pos, height)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = hrp.CFrame:Lerp(
        CFrame.new(pos.X, pos.Y + height, pos.Z),
        MOVE_SPEED
    )
end

---------------- PRESS E ----------------
local function PressE()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

---------------- TP 0/4 ----------------
local function FindZero()
    local list = {}
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local lb = v:FindFirstChildWhichIsA("TextLabel")
            if lb and lb.Text == "0/4" and v.Adornee then
                table.insert(list, v.Adornee)
            end
        end
    end
    if #list > 0 then
        return list[math.random(#list)]
    end
end

---------------- AUTO START ----------------
task.spawn(function()
    while task.wait(1) do
        if not getgenv().AutoStartDungeon then continue end
        local gui = LP.PlayerGui:FindFirstChild("DungeonSettings", true)
        if gui and gui.Enabled then
            local btn = gui:FindFirstChildWhichIsA("TextButton", true)
            if btn then
                firesignal(btn.MouseButton1Click)
                task.wait(3)
            end
        end
    end
end)

---------------- EQUIP WEAPON ----------------
local function EquipWeapon()
    local char = LP.Character
    local bp = LP.Backpack
    if not char or not bp then return end
    for _,tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("WeaponType") == getgenv().WeaponType then
            tool.Parent = char
            return
        end
    end
end

---------------- FIND DESTROY ----------------
local function FindNearestDestroy()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, dist = nil, math.huge
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,t in ipairs(v:GetDescendants()) do
                if t:IsA("TextLabel") and t.Text and t.Text:lower():find("destroy") then
                    local part = v.Adornee or v.Parent
                    if part and part:IsA("BasePart") then
                        local d = (part.Position - hrp.Position).Magnitude
                        if d < dist then
                            dist = d
                            nearest = part
                        end
                    end
                end
            end
        end
    end
    return nearest
end

---------------- GREEN SCAN ----------------
local function ScanGreen()
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,t in ipairs(v:GetDescendants()) do
                if t:IsA("TextLabel") then
                    local c = t.TextColor3
                    if c.G > c.R and c.G > c.B then
                        local part = v.Adornee or v.Parent
                        if part and part:IsA("BasePart") then
                            LastGreenPos = part.Position
                        end
                    end
                end
            end
        end
    end
end

---------------- BUG ENEMY ----------------
local function IsBugEnemy(model)
    if IgnoredEnemies[model] then return true end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return true end
    local now = os.clock()
    local data = DamageCheck[model]
    if not data then
        DamageCheck[model] = {hp = hum.Health, tick = now}
        return false
    end
    if now - data.tick >= 1.5 then
        if hum.Health >= data.hp - 1 then
            IgnoredEnemies[model] = true
            DamageCheck[model] = nil
            return true
        else
            data.hp = hum.Health
            data.tick = now
        end
    end
    return false
end

---------------- FIND ENEMY ----------------
local function FindNearestEnemy(hrp)
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    local best, dist = nil, math.huge
    for _,v in ipairs(enemies:GetChildren()) do
        local hum = v:FindFirstChildOfClass("Humanoid")
        local r = v:FindFirstChild("HumanoidRootPart")
        if hum and r and hum.Health > 0 then
            if v.Name:lower():find("shadow") then
                IgnoredEnemies[v] = true
                continue
            end
            if IsBugEnemy(v) then
                continue
            end
            local d = (r.Position - hrp.Position).Magnitude
            if d < dist then
                dist = d
                best = r
            end
        end
    end
    return best
end

---------------- MAIN LOOP ----------------
RunService.Heartbeat:Connect(function()
    local hrp, hum = getHRPandHum()
    if not hrp or not hum then return end

    EquipWeapon()
    LockY(hrp)

    -- TP 0/4
    if getgenv().AutoTPZero then
        if not ZeroTarget then
            ZeroTarget = FindZero()
            if ZeroTarget then
                local d = (hrp.Position - ZeroTarget.Position).Magnitude
                TweenService:Create(
                    hrp,
                    TweenInfo.new(d/250, Enum.EasingStyle.Linear),
                    {CFrame = ZeroTarget.CFrame + Vector3.new(0,5,0)}
                ):Play()
            end
        else
            if (hrp.Position - ZeroTarget.Position).Magnitude < 7 then
                PressE()
                getgenv().AutoTPZero = false
                ZeroTarget = nil
            end
        end
        return
    end

    if not getgenv().AutoDungeon then return end

    -- DIE
    if hum.Health <= 0 then
        if LastGreenPos then ReturnAfterDie = true end
        return
    end

    -- RETURN AFTER DIE
    if ReturnAfterDie and LastGreenPos then
        MoveTo(hrp, LastGreenPos, HEIGHT_GREEN)
        if (hrp.Position - LastGreenPos).Magnitude < 10 then
            ReturnAfterDie = false
        end
        return
    end

    -- DESTROY
    local destroy = FindNearestDestroy()
    if destroy then
        MoveTo(hrp, destroy.Position, HEIGHT_FARM)
        return
    end

    -- FARM
    local enemy = FindNearestEnemy(hrp)
    if enemy then
        MoveTo(hrp, enemy.Position, HEIGHT_FARM)
        return
    end

    -- GREEN
    ScanGreen()
    if LastGreenPos then
        MoveTo(hrp, LastGreenPos, HEIGHT_GREEN)
    end
end)