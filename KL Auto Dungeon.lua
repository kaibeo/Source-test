-- // KING LEGACY - FINAL FIX ALL (NO SKILL WHEN DODGE)

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
local lastControlZ = 0

-- ================== MOB ==================
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
local function aimLock(target)
    if not target then return end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if hrp then
        root.CFrame = CFrame.new(root.Position, hrp.Position)
    end
end

-- ================== EQUIP ==================
local function equipTool(keyword)
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(keyword) then
            character.Humanoid:EquipTool(tool)
            return true
        end
    end
end

-- ================== DODGE ==================
local function isDangerous(mob)
    if not mob then return false end
    if tick() - lastDodgeTime < 1 then return false end

    for _, v in ipairs(mob:GetDescendants()) do
        if (v:IsA("Beam") and v.Enabled) or
           (v:IsA("ParticleEmitter") and v.Enabled) or
           (v:IsA("Sound") and v.Playing) then
            lastDodgeTime = tick()
            lastSkillTick = tick()
            return true
        end
    end

    if tick() - lastSkillTick < 0.5 then return true end
    return false
end

-- ================== COMBO ==================
spawn(function()
    while true do
        if farming and currentTarget then

            -- 🛡️ ĐANG NÉ → DỪNG
            if dodgeTime > 0 then
                task.wait(0.05)
                continue
            end

            aimLock(currentTarget)

            -- 🔵 FRUIT
            equipTool("fruit")

            if tostring(player.Data.DevilFruit.Value):lower():find("control") then
                if tick() - lastControlZ > 60 then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                    lastControlZ = tick()
                end
            end

            for _, key in ipairs({"X","C","V","B"}) do
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
            end

            task.wait(0.2)

            -- nếu giữa chừng bị né → dừng
            if dodgeTime > 0 then continue end

            -- ⚔️ SWORD
            equipTool("sword")

            for _, key in ipairs({"Z","X"}) do
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
            end

            task.wait(0.2)
        end
        task.wait(0.05)
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
    aimLock(currentTarget)

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

        root.CFrame = CFrame.new(hrp.Position + offset, hrp.Position)
        dodgeTime = dodgeTime - dt

    else
        root.CFrame = CFrame.new(hrp.Position + Vector3.new(0,7,0), hrp.Position)
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

print("🔥 FINAL FIXED SCRIPT READY")
