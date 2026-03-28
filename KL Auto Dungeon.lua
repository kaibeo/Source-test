--// KING LEGACY AUTO FARM FIX FLY FULL

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local HRP = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- SERVICES
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

-- SETTINGS
getgenv().Setting = {
    AutoFarm = true,
    AutoSkill = true,
    AutoHaki = true,
    DodgeSkill = true,
    PullMob = true,
    FastAttack = true,
    Height = 15,
    Speed = 50
}

-- ANTI AFK
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

-- ANTI FALL
humanoid.PlatformStand = true

-- FLY SYSTEM 🔥
local BV = Instance.new("BodyVelocity")
BV.MaxForce = Vector3.new(1e9,1e9,1e9)
BV.Velocity = Vector3.new(0,0,0)
BV.Parent = HRP

local BG = Instance.new("BodyGyro")
BG.MaxTorque = Vector3.new(1e9,1e9,1e9)
BG.P = 1e4
BG.CFrame = HRP.CFrame
BG.Parent = HRP

-- EQUIP
function EquipWeapon()
    for _,v in pairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            v.Parent = char
        end
    end
end

-- GET MOBS
function GetMobs()
    local mobs = {}
    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            table.insert(mobs,v)
        end
    end
    return mobs
end

-- TARGET
function GetTarget()
    local nearest, dist = nil, math.huge

    for _,v in pairs(GetMobs()) do
        if v:FindFirstChild("HumanoidRootPart") then
            local d = (HRP.Position - v.HumanoidRootPart.Position).Magnitude

            if v.Humanoid.MaxHealth > 5000 then
                return v
            end

            if d < dist then
                dist = d
                nearest = v
            end
        end
    end

    return nearest
end

-- ATTACK
function Attack()
    VirtualUser:Button1Down(Vector2.new(0,0))
    task.wait(0.05)
    VirtualUser:Button1Up(Vector2.new(0,0))
end

-- SKILL
function UseSkill()
    VIM:SendKeyEvent(true,"Z",false,game)
    VIM:SendKeyEvent(true,"X",false,game)
    VIM:SendKeyEvent(true,"C",false,game)
    VIM:SendKeyEvent(true,"V",false,game)
end

-- HAKI
function UseHaki()
    VIM:SendKeyEvent(true,"J",false,game)
end

-- PULL MOB
function PullMob(target)
    for _,v in pairs(GetMobs()) do
        if v ~= target and v:FindFirstChild("HumanoidRootPart") then
            if (v.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude < 60 then
                v.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
            end
        end
    end
end

-- DODGE
function Dodge(mob)
    if (HRP.Position - mob.HumanoidRootPart.Position).Magnitude < 6 then
        HRP.CFrame = HRP.CFrame * CFrame.new(0,25,0)
    end
end

-- FAST ATTACK
RunService.RenderStepped:Connect(function()
    if getgenv().Setting.FastAttack then
        pcall(Attack)
    end
end)

-- AUTO SKILL LOOP
task.spawn(function()
    while task.wait(2) do
        if getgenv().Setting.AutoSkill then
            UseSkill()
        end
        if getgenv().Setting.AutoHaki then
            UseHaki()
        end
    end
end)

-- CHECK MOB
function HasMob()
    return #GetMobs() > 0
end

-- MAIN LOOP 🔥
while task.wait() do
    pcall(function()

        if HasMob() then
            local mob = GetTarget()

            if mob and mob:FindFirstChild("HumanoidRootPart") then
                repeat
                    task.wait()

                    EquipWeapon()

                    local targetPos = mob.HumanoidRootPart.Position + Vector3.new(0,getgenv().Setting.Height,0)

                    -- ✈️ BAY THẬT
                    BV.Velocity = (targetPos - HRP.Position).Unit * getgenv().Setting.Speed

                    -- 🎯 KHÓA MẶT
                    BG.CFrame = CFrame.new(HRP.Position, mob.HumanoidRootPart.Position)

                    -- 🧲 GOM QUÁI
                    if getgenv().Setting.PullMob then
                        PullMob(mob)
                    end

                    -- 🛡 NÉ SKILL
                    if getgenv().Setting.DodgeSkill then
                        Dodge(mob)
                    end

                until not mob
                    or not mob:FindFirstChild("Humanoid")
                    or mob.Humanoid.Health <= 0
            end

        else
            repeat task.wait(1) until HasMob()
        end

    end)
end
