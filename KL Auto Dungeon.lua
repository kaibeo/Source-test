-- // KING LEGACY DUNGEON FARM - QUAY VÒNG 7M + TỰ ĐỘNG NÉ KHI QUÁI XẢ SKILL
-- Farm Wiki + Orbit clockwise + Auto dodge khi cast skill
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
local dodgeTime = 0  -- thời gian né (giây)

-- ================== DANH SÁCH TÊN QUÁI TỪ WIKI DUNGEON ==================
local dungeonMobNames = {
    "imprisoned pirate", "pirate gunner", "mike", "shadowbane", "firelord", "lightbane",
    "darkbane sentinel", "volcanus", "ravthus", "bloodbound pirate", "imprisoned angel",
    "imprisoned demon", "warden's bane", "bomb warden", "shockwarden", "anuvaris",
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

-- ================== NHẬN DIỆN QUÁI ĐANG XẢ SKILL ==================
local function isCastingSkill(mob)
    if not mob then return false end
    for _, v in ipairs(mob:GetDescendants()) do
        if v:IsA("ParticleEmitter") and v.Enabled then
            return true
        end
        if v:IsA("Beam") or v:IsA("Trail") then
            return true
        end
        local nameLower = v.Name:lower()
        if nameLower:find("cast") or nameLower:find("skill") or nameLower:find("attack") or nameLower:find("charge") then
            return true
        end
    end
    return false
end

-- Chỉ spam M1
local function startAttackLoop()
    spawn(function()
        while farming do
            if currentTarget and currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health > 0 then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
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

        -- Phát hiện teleport ra ngoài
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

            -- KIỂM TRA CÓ XẢ SKILL KHÔNG
            if isCastingSkill(target) then
                dodgeTime = 1.5  -- né trong 1.5 giây
            end

            -- TÍNH VỊ TRÍ QUAY VÒNG
            currentAngle = currentAngle + (-1.0) * dt   -- tốc độ vừa phải theo kim đồng hồ
            local radius = (dodgeTime > 0) and 12 or 7   -- né thì ra xa 12m
            local heightOffset = 4

            local offsetX = math.cos(currentAngle) * radius
            local offsetZ = math.sin(currentAngle) * radius
            local newPos = hrp.Position + Vector3.new(offsetX, heightOffset, offsetZ)

            -- NẾU ĐANG NÉ → TĂNG TỐC ĐỘ QUAY ĐỘT NGỘT ĐỂ TRÁNH
            if dodgeTime > 0 then
                currentAngle = currentAngle + (-3.0) * dt  -- quay nhanh hơn để né
                dodgeTime = dodgeTime - dt
            end

            -- Di chuyển + nhìn vào giữa quái
            root.CFrame = CFrame.new(newPos, hrp.Position)
        else
            currentTarget = nil
        end
    end)

    print("✅ FARM QUAY VÒNG + TỰ ĐỘNG NÉ ĐÃ BẬT!")
    print("   • Quay vòng quanh quái cách 7m theo kim đồng hồ")
    print("   • Tự động né khi quái xả skill (ra xa 12m + quay nhanh)")
    print("   • Chỉ farm quái có tên trên Wiki Dungeon")
    print("   • Chỉ spam M1")
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
print("🚀 SCRIPT FARM QUAY VÒNG + AUTO NÉ ĐÃ LOAD!")
print("Đang tự động farm ngay bây giờ...")
startFarming()

print("Nhấn **F** để TẮT / BẬT lại nếu cần")
