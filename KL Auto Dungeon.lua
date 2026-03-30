-- // KING LEGACY DUNGEON FARM - FIX KHÔNG TP + BAY MƯỢT + M1 NHANH

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
local heartbeatConn = nil
local currentAngle = 0
local dodgeTime = 0

-- ================== MOB ==================
local dungeonMobNames = {
    "imprisoned pirate","pirate gunner","bloodbound pirate","imprisoned angel",
    "imprisoned demon","warden's bane","mike","shadowbane","firelord","lightbane",
    "darkbane sentinel","volcanus","ravthus","bomb warden","shockwarden","anuvaris",
    "heartbreaker queen","gravity warden","ashen talon","flame warden","dark warden",
    "magma warden","ice warden","light warden","veyzor","chaos crab","craberno",
    "warden","bomb","shock"
}

local function isDungeonMob(mob)
    if not mob or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 then return false end
    if mob == character then return false end
    local nameLower = mob.Name:lower()
    for _, keyword in ipairs(dungeonMobNames) do
        if nameLower:find(keyword) then return true end
    end
    return false
end

local function getClosestDungeonMob()
    local closest, shortest = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isDungeonMob(obj) and obj:FindFirstChild("HumanoidRootPart") then
            local dist = (root.Position - obj.HumanoidRootPart.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = obj
            end
        end
    end
    return closest
end

-- ================== DETECT SKILL ==================
local function isTargetingPlayer(mob)
    if not mob then return false end
    for _, v in ipairs(mob:GetDescendants()) do
        if v:IsA("ParticleEmitter") and v.Enabled then
            return true
        end
        local n = v.Name:lower()
        if n:find("skill") or n:find("ultimate") then
            return true
        end
    end
    return false
end

-- ================== ATTACK ==================
local function startAttackLoop()
    spawn(function()
        while farming do
            if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
                local hrp = currentTarget.HumanoidRootPart

                -- aim chuẩn
                root.CFrame = CFrame.new(root.Position, hrp.Position)

                -- M1 SIÊU NHANH
                for i = 1,2 do
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                end

                -- Skill
                for _, key in ipairs({"Z","X","C","V"}) do
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
                end
            end
            task.wait(0.1)
        end
    end)
end

-- ================== FARM ==================
local function startFarming()
    if farming then return end
    farming = true
    currentTarget = nil
    lastTarget = nil
    currentAngle = 0

    startAttackLoop()

    heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not farming then return end

        local target = getClosestDungeonMob()

        if target and target:FindFirstChild("HumanoidRootPart") then
            currentTarget = target
            local hrp = target.HumanoidRootPart

            -- FIX: đổi target → reset góc (tránh đứng im)
            if target ~= lastTarget then
                currentAngle = 0
                lastTarget = target
            end

            -- né skill
            if isTargetingPlayer(target) then
                dodgeTime = 1.5
            end

            -- quay vòng
            local speed = (dodgeTime > 0) and 3 or 1.5
            currentAngle = currentAngle - speed * dt

            local radius = (dodgeTime > 0) and 12 or 7
            local height = 4

            dodgeTime = math.max(0, dodgeTime - dt)

            local offset = Vector3.new(
                math.cos(currentAngle) * radius,
                height,
                math.sin(currentAngle) * radius
            )

            local targetPos = hrp.Position + offset

            -- FIX: BAY MƯỢT (KHÔNG TP)
            root.CFrame = root.CFrame:Lerp(
                CFrame.new(targetPos, hrp.Position),
                0.25
            )
        end
    end)

    print("✅ FARM MƯỢT + KHÔNG TP + M1 NHANH!")
end

local function stopFarming()
    farming = false
    if heartbeatConn then heartbeatConn:Disconnect() end
    print("⛔ STOP")
end

-- Toggle F
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        if farming then stopFarming() else startFarming() end
    end
end)

startFarming()
