-- // KING LEGACY DUNGEON FARM - QUAY VÒNG KIM ĐỒNG HỒ 7M + M1 + SKILL KIẾM & TRÁI
-- Lấy quái làm trung tâm, quay clockwise, spam M1 + Z X C V + Auto né kill skill
-- Paste vào Executor → Execute là farm luôn!

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
local heartbeatConn = nil
local lastPosition = root.Position
local currentAngle = 0
local dodgeTime = 0

-- ================== DANH SÁCH TÊN QUÁI TỪ WIKI DUNGEON ==================
local dungeonMobNames = {
    "imprisoned pirate", "pirate gunner", "bloodbound pirate", "imprisoned angel",
    "imprisoned demon", "warden's bane", "mike", "shadowbane", "firelord", "lightbane",
    "darkbane sentinel", "volcanus", "ravthus", "bomb warden", "shockwarden", "anuvaris",
    "heartbreaker queen", "gravity warden", "ashen talon", "flame warden", "dark warden",
    "magma warden", "ice warden", "light warden", "veyzor", "chaos crab", "craberno",
    "warden", "bomb", "shock"
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
    local mobs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isDungeonMob(obj) and obj:FindFirstChild("HumanoidRootPart") then
            table.insert(mobs, obj)
        end
    end
    local closest, shortest = nil, math.huge
    local myPos = root.Position
    for _, mob in ipairs(mobs) do
        local dist = (myPos - mob.HumanoidRootPart.Position).Magnitude
        if dist < shortest then
            shortest = dist
            closest = mob
        end
    end
    return closest
end

-- ================== NHẬN DIỆN QUÁI XẢ KILL SKILL LÊN PLAYER ==================
local function isTargetingPlayer(mob)
    if not mob then return false end
    for _, v in ipairs(mob:GetDescendants()) do
        if v:IsA("Beam") and v.Attachment0 and v.Attachment1 then
            if (v.Attachment1.WorldPosition - root.Position).Magnitude < 25 then
                return true
            end
        end
        if (v:IsA("ParticleEmitter") and v.Enabled) or v:IsA("Trail") then
            if (v.WorldPosition - root.Position).Magnitude < 20 then
                return true
            end
        end
        local n = v.Name:lower()
        if n:find("kill") or n:find("oneshot") or n:find("ultimate") or n:find("cast") or n:find("skill") then
            return true
        end
    end
    return false
end

-- Spam M1 (kiếm) + Skill trái Z X C V
local function startAttackLoop()
    spawn(function()
        while farming do
            if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") and currentTarget.Humanoid.Health > 0 then
                local hrp = currentTarget.HumanoidRootPart
                -- Aim chính xác trước khi spam skill
                root.CFrame = CFrame.new(root.Position, hrp.Position)

                -- M1 (kiếm)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)

                -- Skill trái Z X C V
                for _, key in ipairs({"Z", "X", "C", "V"}) do
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                    task.wait(0.08)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
                    task.wait(0.05)
                end
            end
            task.wait(0.18)
        end
    end)
end

local function startFarming()
    if farming then return end
    farming = true
    currentTarget = nil
    lastPosition = root.Position
    currentAngle = 0
    dodgeTime = 0

    startAttackLoop()

    heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not farming then return end

        -- Phát hiện bị tele ra ngoài dungeon
        local currentPos = root.Position
        if (currentPos - lastPosition).Magnitude > 200 then
            stopFarming()
            print("🚪 BỊ DỊCH CHUYỂN RA NGOÀI → Farm tự động dừng!")
            return
        end
        lastPosition = currentPos

        local target = getClosestDungeonMob()

        if target and target:FindFirstChild("HumanoidRootPart") then
            currentTarget = target
            local hrp = target.HumanoidRootPart

            -- Né khi quái xả kill skill lên player
            if isTargetingPlayer(target) then
                dodgeTime = 2.0
            end

            -- QUAY VÒNG THEO CHIỀU KIM ĐỒNG HỒ - LẤY QUÁI LÀM TRUNG TÂM
            currentAngle = currentAngle + (-1.0) * dt   -- tốc độ vừa phải (1 vòng \~6-7 giây)
            local radius = (dodgeTime > 0) and 12 or 7   -- né thì ra xa 12m
            local heightOffset = 4

            if dodgeTime > 0 then
                currentAngle = currentAngle + (-3.0) * dt   -- quay nhanh hơn để né
                dodgeTime = dodgeTime - dt
            end

            local offsetX = math.cos(currentAngle) * radius
            local offsetZ = math.sin(currentAngle) * radius
            local newPos = hrp.Position + Vector3.new(offsetX, heightOffset, offsetZ)

            -- Di chuyển + nhìn vào quái (aim skill)
            root.CFrame = CFrame.new(newPos, hrp.Position)
        else
            currentTarget = nil
        end
    end)

    print("✅ FARM QUAY VÒNG KIM ĐỒNG HỒ ĐÃ BẬT!")
    print("   • Lấy quái làm trung tâm, quay theo chiều kim đồng hồ cách 7m")
    print("   • Spam M1 (kiếm) + skill trái Z X C V liên tục")
    print("   • Tự động né khi quái xả kill skill lên player")
    print("   • Chỉ farm quái có tên trên Wiki Dungeon")
end

local function stopFarming()
    farming = false
    if heartbeatConn then heartbeatConn:Disconnect() end
    currentTarget = nil
    print("⛔ Farm đã dừng!")
end

-- Toggle F
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        if farming then stopFarming() else startFarming() end
    end
end)

-- TỰ ĐỘNG FARM NGAY KHI EXECUTE
print("🚀 SCRIPT FARM QUAY VÒNG 7M + M1 + SKILL KIẾM & TRÁI ĐÃ LOAD!")
print("Đang tự động farm ngay bây giờ...")
startFarming()

print("Nhấn **F** để TẮT / BẬT lại nếu cần")
