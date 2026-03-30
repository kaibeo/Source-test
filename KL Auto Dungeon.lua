-- // KING LEGACY - FULL FARM FINAL (NO PLAYER TARGET)

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

-- ================== CHECK PLAYER ==================
local function isPlayerCharacter(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then
            return true
        end
    end
    return false
end

-- ================== MOB CHECK ==================
local function isDungeonMob(mob)
    if not mob or not mob:FindFirstChild("Humanoid") then return false end
    if mob.Humanoid.Health <= 0 then return false end

    -- ❌ loại player
    if isPlayerCharacter(mob) then return false end
    if mob == character then return false end

    if not mob:FindFirstChild("HumanoidRootPart") then return false end

    local name = mob.Name:lower()

    -- ✅ chỉ lấy mob trong list
    for _, v in ipairs(dungeonMobNames) do
        if name:find(v) then
            return true
        end
    end

    return false
end

-- ================== GET TARGET ==================
local function getClosestMob()
    local closest, dist = nil, math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and isDungeonMob(v) then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (root.Position - hrp.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = v
                end
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

                -- aim
                root.CFrame = CFrame.new(root.Position, hrp.Position)

                -- ⚡ M1 MAX SPEED
                for i = 1,4 do
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                end

                -- ⚡ skill spam
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
        if not target then return end

        local hrp = target:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        currentTarget = target

        -- reset khi đổi target
        if target ~= lastTarget then
            currentAngle = 0
            lastTarget = target
        end

        -- detect skill
        if isDangerous(target) then
            dodgeTime = 2
        end

        local height = 4
        local radius = 6
        local speed = 4

        -- 🛡️ né skill
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

        -- 🚀 bay mượt
        root.CFrame = root.CFrame:Lerp(
            CFrame.new(targetPos, hrp.Position),
            0.5
        )
    end)

    print("🔥 FARM FINAL: KHÔNG ĐÁNH NGƯỜI + MAX SPEED + DODGE 70M")
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
