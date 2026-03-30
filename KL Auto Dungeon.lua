-- // KING LEGACY - FINAL STABLE FARM + SMART DODGE

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
local currentAngle = 0
local dodgeTime = 0
local lastSkillTick = 0
local lastDodgeTime = 0

-- ================== MOB LIST ==================
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
        if plr.Character == model then return true end
    end
    return false
end

-- ================== MOB CHECK ==================
local function isDungeonMob(mob)
    if not mob or not mob:FindFirstChild("Humanoid") then return false end
    if mob.Humanoid.Health <= 0 then return false end
    if isPlayerCharacter(mob) then return false end
    if mob == character then return false end
    if not mob:FindFirstChild("HumanoidRootPart") then return false end

    local name = mob.Name:lower()
    for _, v in ipairs(dungeonMobNames) do
        if name:find(v) then return true end
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

-- ================== AIM ==================
local function aimAtTarget(target)
    if not target then return end
    local part = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
    if not part then return end

    root.CFrame = CFrame.new(root.Position, part.Position)
end

-- ================== DETECT SKILL ==================
local function isDangerous(mob)
    if not mob then return false end

    if tick() - lastDodgeTime < 1.2 then
        return false
    end

    for _, v in ipairs(mob:GetDescendants()) do

        if v:IsA("Beam") and v.Enabled then
            lastSkillTick = tick()
            lastDodgeTime = tick()
            return true
        end

        if v:IsA("ParticleEmitter") and v.Enabled then
            local parent = v.Parent
            if parent and parent:IsA("BasePart") then
                if (parent.Position - root.Position).Magnitude < 50 then
                    lastSkillTick = tick()
                    lastDodgeTime = tick()
                    return true
                end
            end
        end

        if v:IsA("Sound") and v.Playing then
            lastSkillTick = tick()
            lastDodgeTime = tick()
            return true
        end
    end

    if tick() - lastSkillTick < 0.6 then
        return true
    end

    return false
end

-- ================== ATTACK ==================
local function attack()
    spawn(function()
        while farming do
            if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then

                aimAtTarget(currentTarget)

                for i = 1,4 do
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                end

                aimAtTarget(currentTarget)

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
        aimAtTarget(currentTarget)

        if isDangerous(target) then
            dodgeTime = 1.2
        end

        if dodgeTime > 0 then
            currentAngle = currentAngle - 10 * dt

            local offset = Vector3.new(
                math.cos(currentAngle) * 170,
                140,
                math.sin(currentAngle) * 170
            )

            local pos = hrp.Position + offset

            root.CFrame = root.CFrame:Lerp(
                CFrame.new(pos, hrp.Position),
                0.75
            )

            dodgeTime = dodgeTime - dt

        else
            local pos = hrp.Position + Vector3.new(0, 7, 0)

            root.CFrame = CFrame.new(pos, hrp.Position)

            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    print("🔥 FINAL: STABLE FARM + SMART DODGE 170M")
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        farming = not farming
        if farming then startFarm() end
    end
end)

startFarm()
