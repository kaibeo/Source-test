-- // KING LEGACY - FINAL MAX (M1 CONTINUOUS + SKILL FAST)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- ================== STATE ==================
local farming = true
local currentTarget = nil
local currentAngle = 0
local dodgeTime = 0
local lastDodgeTime = 0
local lastControlZ = 0

-- ================== TOOL ==================
local function getToolByType(typeName)
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()

            if typeName == "fruit" then
                if n:find("fruit") or n:find("control") then
                    return tool
                end
            end

            if typeName == "sword" then
                if n:find("kioru") or n:find("katana") or n:find("sword") then
                    return tool
                end
            end
        end
    end
end

local function equip(tool)
    if tool then
        humanoid:EquipTool(tool)
        task.wait(0.08)
    end
end

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
local function aim(target)
    if target then
        local hrp = target:FindFirstChild("HumanoidRootPart")
        if hrp then
            root.CFrame = CFrame.new(root.Position, hrp.Position)
        end
    end
end

-- ================== FAST SKILL ==================
local function fastSkill(key)
    for i = 1,3 do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

-- ================== DODGE ==================
local function isDangerous(mob)
    if not mob then return false end
    if tick() - lastDodgeTime < 1 then return false end

    for _, v in ipairs(mob:GetDescendants()) do
        if (v:IsA("Beam") and v.Enabled)
        or (v:IsA("ParticleEmitter") and v.Enabled)
        or (v:IsA("Sound") and v.Playing) then
            lastDodgeTime = tick()
            return true
        end
    end

    return false
end

-- ================== M1 LOOP ==================
spawn(function()
    while true do
        if farming and currentTarget and dodgeTime <= 0 then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and tool.Name:lower():find("kioru") then
                VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
            end
        end
        task.wait(0.01)
    end
end)

-- ================== ATTACK ==================
spawn(function()
    while true do
        if farming and currentTarget and dodgeTime <= 0 then

            aim(currentTarget)

            -- 🔵 FRUIT
            local fruit = getToolByType("fruit")
            if fruit then
                equip(fruit)
                aim(currentTarget)

                if tostring(player.Data.DevilFruit.Value):lower():find("control") then
                    if tick() - lastControlZ > 60 then
                        fastSkill(Enum.KeyCode.Z)
                        lastControlZ = tick()
                    end
                end

                fastSkill(Enum.KeyCode.X)
                fastSkill(Enum.KeyCode.C)
                fastSkill(Enum.KeyCode.V)
                fastSkill(Enum.KeyCode.B)
            end

            -- ⚔️ SWORD
            local sword = getToolByType("sword")
            if sword then
                equip(sword)
                aim(currentTarget)

                fastSkill(Enum.KeyCode.Z)
                fastSkill(Enum.KeyCode.X)
            end
        end
        task.wait(0.02)
    end
end)

-- ================== MAIN ==================
RunService.Heartbeat:Connect(function(dt)
    if not farming then return end

    local target = getClosestMob()
    if not target then return end

    currentTarget = target
    aim(currentTarget)

    if isDangerous(target) then
        dodgeTime = 1.2
    end

    if dodgeTime > 0 then
        currentAngle -= 10 * dt

        local offset = Vector3.new(
            math.cos(currentAngle) * 170,
            140,
            math.sin(currentAngle) * 170
        )

        root.CFrame = CFrame.new(target.HumanoidRootPart.Position + offset, target.HumanoidRootPart.Position)
        dodgeTime -= dt
    else
        root.CFrame = CFrame.new(target.HumanoidRootPart.Position + Vector3.new(0,7,0), target.HumanoidRootPart.Position)
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

print("🔥 MAX M1 + MAX SPEED READY")
