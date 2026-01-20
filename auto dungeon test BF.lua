--==================================================
-- ZMATRIX | AUTO DUNGEON ALL IN ONE (FINAL)
-- Stable Core Rewrite | Banana UI
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
getgenv().AutoDungeon      = false
getgenv().AutoTPZero       = false
getgenv().AutoStartDungeon = false
getgenv().FastAttack       = false
getgenv().WeaponType       = "Melee"

---------------- SERVICES ----------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer

---------------- UI : DUNGEON ----------------
local S1 = DungeonPage.CreateSection("Auto Dungeon")

S1.CreateToggle({
    Title = "Auto Dungeon",
    Default = false
}, function(v)
    getgenv().AutoDungeon = v
end)

S1.CreateButton({
    Title = "Auto TP 0/4"
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
    Title = "Select Weapon Type",
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

---------------- CONFIG ----------------
local HEIGHT_FARM  = 20
local HEIGHT_GREEN = 7
local SPEED = 0.6

---------------- STATE ----------------
local State = "FARM"
local LastGreenPos = nil

---------------- UTILS ----------------
local function getHRPandHum()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hrp and hum then return hrp, hum end
end

local function LockY(hrp)
    local bp = hrp:FindFirstChild("LOCK_Y")
    if not bp then
        bp = Instance.new("BodyPosition", hrp)
        bp.Name = "LOCK_Y"
        bp.MaxForce = Vector3.new(0, math.huge, 0)
        bp.P = 60000
        bp.D = 1500
    end
    bp.Position = Vector3.new(0, hrp.Position.Y, 0)
end

local function MoveTo(hrp, pos, h)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = hrp.CFrame:Lerp(
        CFrame.new(pos.X, pos.Y + h, pos.Z),
        SPEED
    )
end

---------------- AUTO EQUIP ----------------
local function AutoEquip()
    local char = LP.Character
    if not char then return end
    for _,tool in ipairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local wt = tool:GetAttribute("WeaponType")
            if wt == getgenv().WeaponType then
                tool.Parent = char
                return
            end
        end
    end
end

---------------- TP 0/4 ----------------
local ZeroTarget
local function FindZero()
    local t={}
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local lb=v:FindFirstChildWhichIsA("TextLabel")
            if lb and lb.Text=="0/4" and v.Adornee then
                table.insert(t,v.Adornee)
            end
        end
    end
    if #t>0 then
        return t[math.random(#t)]
    end
end

---------------- DESTROY ----------------
local function FindDestroy()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,t in ipairs(v:GetDescendants()) do
                if t:IsA("TextLabel") and t.Text
                and t.Text:lower():find("destroy") then
                    local p = v.Adornee or v.Parent
                    if p and p:IsA("BasePart") then
                        return p
                    end
                end
            end
        end
    end
end

---------------- ENEMY ----------------
local function FindEnemy(hrp)
    local e = workspace:FindFirstChild("Enemies")
    if not e then return end
    local best, dist = nil, math.huge
    for _,v in ipairs(e:GetChildren()) do
        if v.Name:lower():find("shadow") then continue end
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

local function HasEnemy()
    local e = workspace:FindFirstChild("Enemies")
    if not e then return false end
    for _,v in ipairs(e:GetChildren()) do
        local h = v:FindFirstChild("Humanoid")
        if h and h.Health > 0 then return true end
    end
    return false
end

---------------- GREEN ----------------
local function ScanGreen()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,t in ipairs(v:GetDescendants()) do
                if t:IsA("TextLabel") then
                    local c=t.TextColor3
                    if c.G>c.R and c.G>c.B then
                        local p=v.Adornee or v.Parent
                        if p and p:IsA("BasePart") then
                            return p.Position
                        end
                    end
                end
            end
        end
    end
end

---------------- AUTO START DUNGEON ----------------
local StartRemote
for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") and v.Name:lower():find("start") then
        StartRemote = v
    end
end

---------------- MAIN LOOP ----------------
RunService.Heartbeat:Connect(function()
    local hrp, hum = getHRPandHum()
    if not hrp or not hum then return end

    -- AUTO EQUIP
    AutoEquip()

    -- AUTO TP 0/4
    if getgenv().AutoTPZero then
        if not ZeroTarget then
            ZeroTarget = FindZero()
            if ZeroTarget then
                TweenService:Create(
                    hrp,
                    TweenInfo.new((hrp.Position-ZeroTarget.Position).Magnitude/250),
                    {CFrame = ZeroTarget.CFrame + Vector3.new(0,5,0)}
                ):Play()
            end
        else
            if (hrp.Position-ZeroTarget.Position).Magnitude < 7 then
                VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)
                getgenv().AutoTPZero = false
                ZeroTarget = nil
            end
        end
        return
    end

    if not getgenv().AutoDungeon then return end

    LockY(hrp)

    if hum.Health <= 0 then
        if LastGreenPos then State="RETURN" end
        return
    end

    if State=="RETURN" and LastGreenPos then
        MoveTo(hrp, LastGreenPos, HEIGHT_GREEN)
        if (hrp.Position-LastGreenPos).Magnitude < 10 then
            State="FARM"
        end
        return
    end

    local destroy = FindDestroy()
    if destroy then
        MoveTo(hrp, destroy.Position, HEIGHT_FARM)
        return
    end

    local enemy = FindEnemy(hrp)
    if enemy then
        MoveTo(hrp, enemy.Position, HEIGHT_FARM)
        return
    end

    if not HasEnemy() then
        local g = ScanGreen()
        if g then
            LastGreenPos = g
            State="GREEN"
        end
    end

    if State=="GREEN" and LastGreenPos then
        MoveTo(hrp, LastGreenPos, HEIGHT_GREEN)
    end

    -- AUTO START
    if getgenv().AutoStartDungeon and StartRemote then
        StartRemote:FireServer()
    end
end)

---------------- FAST ATTACK ----------------
-- GIỮ NGUYÊN BẢN BẠN GỬI (KHÔNG SỬA)
-- (bạn đã có sẵn đoạn fast attack)