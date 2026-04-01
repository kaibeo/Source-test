-- // KING LEGACY - HYBRID MAX v5 (FIX ALL)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

-- ================= STATE =================
local farming = false
local target = nil
local dodgeTime = 0
local lastDodge = 0
local angle = 0
local hitCount = 0
local maxHit = 2
local switchTarget = false
local mobList = {}
local lastMobScan = 0
local RANGE = 300

local lastRoomZ = 0
local ROOM_MIN_CD = 5
local flyBarRef = nil

-- ================= RESPAWN =================
player.CharacterAdded:Connect(function(c)
    char = c
    humanoid = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    task.wait(2)
end)

-- ================= TOOL =================
local function getTool(keyword)
    for _, v in ipairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.Name:lower():find(keyword) then
            return v
        end
    end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and v.Name:lower():find(keyword) then
            return v
        end
    end
end

local function equip(tool)
    if tool and tool.Parent ~= char then
        humanoid:EquipTool(tool)
        task.wait(0.12)
    end
end

-- ================= AIM =================
local function aim()
    if target and target:FindFirstChild("HumanoidRootPart") then
        root.CFrame = CFrame.new(root.Position, target.HumanoidRootPart.Position)
    end
end

-- ================= INPUT =================
local function press(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

-- ================= DODGE =================
local function dangerous(mob)
    if tick() - lastDodge < 1 then return false end
    for _, v in ipairs(mob:GetDescendants()) do
        if v:IsA("Beam") and v.Enabled then return true end
        if v:IsA("ParticleEmitter") and v.Enabled then
            local p = v.Parent
            if p and p:IsA("BasePart") then
                if (p.Position - root.Position).Magnitude < 70 then
                    return true
                end
            end
        end
    end
end

-- ================= FLYBAR =================
local function getFlyBar()
    if flyBarRef and flyBarRef.Parent then return flyBarRef end
    for _, v in pairs(player.PlayerGui:GetDescendants()) do
        if v.Name == "FlyBar" or v.Name == "FlyBar2" then
            flyBarRef = v
            return v
        end
    end
end

local function getRoomBarScale()
    local bar = getFlyBar()
    if not bar then return 1 end

    local ok, scale = pcall(function()
        local parent = bar.Parent
        if parent and parent.AbsoluteSize.X > 0 then
            return bar.AbsoluteSize.X / parent.AbsoluteSize.X
        end
        return 1
    end)

    if ok then return scale end
    return 1
end

local function hasRoomActive()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if (v:IsA("Part") or v:IsA("MeshPart")) and v.Name:lower():find("room") then
            if (v.Position - root.Position).Magnitude < 200 then
                return true
            end
        end
    end
end

local function shouldUseRoomZ()
    if tick() - lastRoomZ < ROOM_MIN_CD then return false end
    if hasRoomActive() then return false end
    return getRoomBarScale() <= 0.05
end

-- ================= SCAN =================
local function scanMobs()
    if tick() - lastMobScan < 1 then return end
    lastMobScan = tick()
    mobList = {}

    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v ~= char then
            local hum = v:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local d = (root.Position - v.HumanoidRootPart.Position).Magnitude
                if d <= RANGE then
                    table.insert(mobList, v)
                end
            end
        end
    end
end

local function getRandomMob()
    scanMobs()
    if #mobList == 0 then return nil end
    return mobList[math.random(1, #mobList)]
end

-- ================= M1 =================
task.spawn(function()
    while true do
        if farming and target and dodgeTime <= 0 then
            VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
            hitCount += 1
            if hitCount >= maxHit then
                switchTarget = true
                hitCount = 0
            end
        end
        task.wait(0.03)
    end
end)

-- ================= COMBO =================
task.spawn(function()
    while true do
        if farming and target and dodgeTime <= 0 then

            aim()

            -- 🍇 FRUIT
            local fruit = getTool("opop") or getTool("control")
            if fruit then
                equip(fruit)
                aim()

                if shouldUseRoomZ() then
                    press(Enum.KeyCode.Z)
                    lastRoomZ = tick()
                    task.wait(0.8)
                else
                    press(Enum.KeyCode.X)
                    press(Enum.KeyCode.C)
                    press(Enum.KeyCode.V)
                    press(Enum.KeyCode.B)
                    press(Enum.KeyCode.E)
                end
            end

            task.wait(0.25)

            -- ⚔️ SWORD
            local sword = getTool("kioru")
            if sword then
                equip(sword)
                aim()
                press(Enum.KeyCode.Z)
                press(Enum.KeyCode.X)
            end

            task.wait(0.25)
        end
        task.wait(0.05)
    end
end)

-- ================= TARGET SWITCH =================
task.spawn(function()
    while true do
        if farming and switchTarget then
            target = getRandomMob()
            switchTarget = false
        end
        task.wait(0.1)
    end
end)

-- ================= MAIN =================
RunService.RenderStepped:Connect(function(dt)
    if not farming then return end

    if not target then
        target = getRandomMob()
        return
    end

    aim()

    if dangerous(target) then
        dodgeTime = 1.1
        lastDodge = tick()
    end

    if dodgeTime > 0 then
        angle -= 7 * dt
        local pos = target.HumanoidRootPart.Position + Vector3.new(
            math.cos(angle) * 140,
            100,
            math.sin(angle) * 140
        )
        root.CFrame = CFrame.new(pos, target.HumanoidRootPart.Position)
        dodgeTime -= dt
    else
        root.CFrame = CFrame.new(
            target.HumanoidRootPart.Position + Vector3.new(0,7,0),
            target.HumanoidRootPart.Position
        )
    end
end)

print("🔥 FULL FIX v5 READY")
