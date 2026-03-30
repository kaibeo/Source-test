-- // KING LEGACY - FULL FARM MAX SPEED + AUTO DODGE 70M + FULL MOB

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

local farming = false
local currentTarget = nil
local lastTarget = nil
local currentAngle = 0
local dodgeTime = 0

-- ================== FULL MOB LIST ==================
local dungeonMobNames = {
    "imprisoned pirate","pirate gunner","bloodbound pirate",
    "imprisoned angel","imprisoned demon",
    "warden","warden's bane","bomb warden","shockwarden","gravity warden",
    "flame warden","dark warden","magma warden","ice warden","light warden",
    "heartbreaker queen","anuvaris","ashen talon",
    "firelord","lightbane","shadowbane","darkbane sentinel",
    "volcanus","ravthus","veyzor",
    "chaos crab","craberno",
    "mike","bomb","shock"
}

local function isDungeonMob(mob)
    if not mob or not mob:FindFirstChild("Humanoid") then return false end
    if mob.Humanoid.Health <= 0 then return false end
    if mob == character then return false end

    local name = mob.Name:lower()

    for _, v in ipairs(dungeonMobNames) do
        if name:find(v) then
            return true
        end
    end

    -- fallback (tránh miss)
    if mob:FindFirstChild("HumanoidRootPart") then
        return true
    end

    return false
end

local function getClosestMob()
    local closest, dist = nil, math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and isDungeonMob(v) and v:FindFirstChild("HumanoidRootPart") then
            local d = (root.Position - v.HumanoidRootPart.Position).Magnitude
            if d < dist then
                dist = d
                closest = v
            end
        end
    end
    return closest
end

-- ================== DETECT SKILL ==================
local function isDangerous(mob)
    if not mob then return false end
    for _, v in ipairs(mob:GetDescendants()) do
        if v:IsA("ParticleEmitter") and v.Enabled then
            return true
        end
        if v:IsA("Beam") then
            return true
        end
        local n = v.Name:lower()
        if n:find("skill") or n:find("ultimate") or n:find("kill") then
            return true
        end
    end
    return false
end

-- ================== ATTACK ==================
local function attack()
    spawn(function()
        while farming do
            if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
                local hrp = currentTarget.HumanoidRootPart

                -- aim chuẩn
                root.CFrame = CFrame.new(root.Position, hrp.Position)

                -- ⚡ M1 MAX SPEED
                for i = 1,4 do
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                end

                -- ⚡ Skill spam nhanh
                for _, key in ipairs({"Z","X","C","V"}) do
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
                end
            end
            task.wait(0.05)
        end
    end)
end

-- ================== FARM ==================
local function startFarm()
    if farming then return end
    farming = true
    attack()

    RunService.Heartbeat:Connect(function(dt)
        if not farming then return end

        local target = getClosestMob()
        if not target or not target:FindFirstChild("HumanoidRootPart") then return end

        currentTarget = target
        local hrp = target.HumanoidRootPart

        -- reset khi đổi target
        if target ~= lastTarget then
            currentAngle = 0
            lastTarget = target
        end

        -- detect skill → né
        if isDangerous(target) then
            dodgeTime = 2
        end

        local height = 4
        local radius = 6
        local speed = 4

        -- 🛡️ né skill → bay 70m
        if dodgeTime > 0 then
            height = 70
            radius = 15
            speed = 10
            dodgeTime = dodgeTime - dt
        end

        currentAngle = currentAngle - speed * dt

        local offset = Vector3.new(
            math.cos(currentAngle) * radius,
            height,
            math.sin(currentAngle) * radius
        )

        local targetPos = hrp.Position + offset

        -- 🚀 bay mượt nhanh (không TP giật)
        root.CFrame = root.CFrame:Lerp(
            CFrame.new(targetPos, hrp.Position),
            0.5
        )
    end)

    print("🔥 FULL FARM: MAX SPEED + DODGE 70M + NO MISS MOB")
end

local function stopFarm()
    farming = false
    print("⛔ STOP")
end

-- toggle F
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        if farming then stopFarm() else startFarm() end
    end
end)

-- auto start
startFarm()
