--// FARM CHẤM ĐỎ (NO HITBOX - ANTI DETECT)

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local HRP = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- SERVICES
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

-- SETTINGS
getgenv().Setting = {
    Height = 5, -- thấp để đánh trúng
    Speed = 45
}

-- ANTI FALL
humanoid.PlatformStand = true

-- FLY
local BV = Instance.new("BodyVelocity", HRP)
BV.MaxForce = Vector3.new(1e9,1e9,1e9)

local BG = Instance.new("BodyGyro", HRP)
BG.MaxTorque = Vector3.new(1e9,1e9,1e9)
BG.P = 1e4

-- EQUIP
function EquipWeapon()
    for _,v in pairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            v.Parent = char
        end
    end
end

-- 🔴 CHECK CHẤM ĐỎ
function IsRedTarget(mob)
    if mob:FindFirstChild("Highlight") then return true end
    if mob:FindFirstChild("Target") then return true end
    if mob:FindFirstChild("HumanoidRootPart") then
        for _,v in pairs(mob.HumanoidRootPart:GetChildren()) do
            if v:IsA("BillboardGui") then
                return true
            end
        end
    end
    return false
end

-- GET MOB CHẤM ĐỎ
function GetRedMob()
    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            if IsRedTarget(v) then
                return v
            end
        end
    end
    return nil
end

-- ATTACK (fix đánh chắc chắn)
function Attack()
    for _,v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then
            v:Activate()
        end
    end
end

-- SKILL
function Skill()
    VIM:SendKeyEvent(true,"Z",false,game)
    VIM:SendKeyEvent(true,"X",false,game)
    VIM:SendKeyEvent(true,"C",false,game)
    VIM:SendKeyEvent(true,"V",false,game)
end

-- MAIN
RunService.Heartbeat:Connect(function()
    local mob = GetRedMob()

    if mob and mob:FindFirstChild("HumanoidRootPart") then
        EquipWeapon()

        local targetPos = mob.HumanoidRootPart.Position + Vector3.new(0,getgenv().Setting.Height,0)

        -- ✈️ BAY
        BV.Velocity = (targetPos - HRP.Position).Unit * getgenv().Setting.Speed

        -- 🎯 LOCK MẶT
        BG.CFrame = CFrame.new(HRP.Position, mob.HumanoidRootPart.Position)

        -- 🧷 giữ đứng yên tránh lệch hit
        HRP.Velocity = Vector3.new(0,0,0)

        -- ⚔ ĐÁNH
        Attack()

        -- 💥 SKILL
        Skill()
    end
end)
