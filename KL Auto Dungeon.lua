-- // KING LEGACY - FINAL SMART FARM + PERFECT DODGE

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

-- ================== STATE ==================
local farming = true
local currentTarget = nil
local currentAngle = 0
local dodgeTime = 0
local lastDodgeTime = 0
local lastSkillTick = 0

-- ================== MOB LIST ==================
local dungeonMobNames = {
    "imprisoned pirate","pirate gunner","bloodbound pirate",
    "imprisoned angel","imprisoned demon",
    "warden","warden's bane","bomb warden","shockwarden","gravity warden",
    "flame warden","dark warden","magma warden","ice warden","light warden",
    "heartbreaker queen","anuvaris","ashen talon",
    "firelord","lightbane","shadowbane","darkbane sentinel",
    "volcanus","ravthus","veyzor",
    "chaos crab","craberno","mike","bomb","shock"
}

-- ================== CHECK MOB ==================
local function isDungeonMob(mob)
    if not mob or not mob:FindFirstChild("Humanoid") then return false end
    if mob.Humanoid.Health <= 0 then return false end
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
    if part then
        root.CFrame = CFrame.new(root.Position, part.Position)
    end
end

-- ================== SMART DODGE ==================
local function isDangerous(mob)
    if not mob then return false end

    if tick() - lastDodgeTime < 1.0 then
        return false
    end

    for _, v in ipairs(mob:GetDescendants()) do

        if v:IsA("Beam") and v.Enabled then
            lastDodgeTime = tick()
            lastSkillTick = tick()
            return true
        end

        if v:IsA("ParticleEmitter") and v.Enabled then
            local parent = v.Parent
            if parent and parent:IsA("BasePart") then
                local dist = (parent.Position - root.Position).Magnitude
                if dist < 60 then
                    lastDodgeTime = tick()
                    lastSkillTick = tick()
                    return true
                end
            end
        end

        if v:IsA("Sound") and v.Playing then
            lastDodgeTime = tick()
            lastSkillTick = tick()
            return true
        end
    end

    if tick() - lastSkillTick < 0.5 then
        return true
    end

    return false
end

-- ================== ATTACK ==================
spawn(function()
    while true do
        if farming and currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then

            aimAtTarget(currentTarget)

            for i = 1,3 do
                VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
            end

            aimAtTarget(currentTarget)

            for _, key in ipairs({"Z","X","C","V"}) do
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
            end
        end
        task.wait(0.04)
    end
end)

-- ================== MAIN ==================
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

-- ================== TOGGLE ==================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        farming = not farming
        print("Farm:", farming)
    end
end)

print("🔥 FINAL SMART FARM + DODGE READY")
