loadstring(game:HttpGet('https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main_example.lua'))()

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

-- ================== DANH SÁCH QUÁI ==================
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
    if not mob or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 then return false end
    if mob == character then return false end
    local name = mob.Name:lower()
    for _, v in ipairs(dungeonMobNames) do
        if name:find(v) then return true end
    end
    return false
end

local function getClosestMob()
    local closest, dist = nil, math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and isDungeonMob(v) and v:FindFirstChild("HumanoidRootPart") then
            local d = (root.Position - v.HumanoidRootPart.Position).Magnitude
            if d < dist then dist = d closest = v end
        end
    end
    return closest
end

local function aimAtTarget(target)
    if not target then return end
    local part = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
    if part then root.CFrame = CFrame.new(root.Position, part.Position) end
end

local function isDangerous(mob)
    if not mob or tick() - lastDodgeTime < 1.2 then return false end
    for _, v in ipairs(mob:GetDescendants()) do
        if (v:IsA("Beam") and v.Enabled) or 
           (v:IsA("ParticleEmitter") and v.Enabled) or 
           (v:IsA("Sound") and v.Playing) then
            lastDodgeTime = tick()
            return true
        end
    end
    return false
end

local attackConnection

local function startAttackLoop()
    if attackConnection then return end
    attackConnection = spawn(function()
        while farming do
            if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
                aimAtTarget(currentTarget)
                -- M1
                VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                -- Skill Z X C V
                for _, key in ipairs({"Z","X","C","V"}) do
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                    task.wait(0.08)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
                end
            end
            task.wait(0.05)
        end
    end)
end

local heartbeatConn
local function startFarm()
    if farming then return end
    farming = true
    currentAngle = 0
    dodgeTime = 0
    startAttackLoop()

    heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not farming then return end

        local target = getClosestMob()
        if not target or not target:FindFirstChild("HumanoidRootPart") then
            currentTarget = nil
            return
        end

        local hrp = target.HumanoidRootPart
        currentTarget = target

        if isDangerous(target) then dodgeTime = 1.8 end

        currentAngle = currentAngle - 1.0 * dt
        local radius = dodgeTime > 0 and 12 or 7
        local heightOffset = 4

        if dodgeTime > 0 then
            currentAngle = currentAngle - 4.0 * dt
            dodgeTime = dodgeTime - dt
        end

        local offsetX = math.cos(currentAngle) * radius
        local offsetZ = math.sin(currentAngle) * radius
        local newPos = hrp.Position + Vector3.new(offsetX, heightOffset, offsetZ)

        root.CFrame = CFrame.new(newPos, hrp.Position)
    end)
end

local function stopFarm()
    farming = false
    if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
    currentTarget = nil
end

-- ================== WINDUI ==================
local Window = library:CreateWindow("King Legacy Farm - By Grok")

local Tab = Window:CreateTab("Dungeon Farm")

Tab:CreateToggle({
    Title = "🚀 Bật Farm Cách 7m",
    Description = "Quay vòng kim đồng hồ + Né kill skill",
    Default = false,
    Callback = function(state)
        if state then
            startFarm()
            print("✅ FARM ĐÃ BẬT (Cách 7m)")
        else
            stopFarm()
            print("⛔ FARM ĐÃ TẮT")
        end
    end
})

Tab:CreateButton({
    Title = "Nhấn F để bật/tắt nhanh",
    Description = "Phím tắt dự phòng",
    Callback = function()
        farming = not farming
        if farming then startFarm() else stopFarm() end
    end
})

Tab:CreateLabel("Farm đang dùng: Quay vòng 7m theo kim đồng hồ")

print("🚀 WINDUI FARM ĐÃ LOAD XONG!")
print("Mở WindUI → Tab 'Dungeon Farm' → Bật toggle để farm")
