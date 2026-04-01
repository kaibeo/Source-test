-- // KING LEGACY - HYBRID MAX v4
-- ✅ OpOp Z (Zone Control) tự động khi FlyBar hết
-- ✅ Fruit: OpOp/Control TRƯỚC - Sword: Kioru V2 SAU
-- ✅ Random quái 300 studs - 2 hit rồi đổi con
-- ✅ M1 + Skill song song
-- ✅ Auto respawn + GUI
-- Executor: Delta

local Players             = game:GetService("Players")
local Workspace           = game:GetService("Workspace")
local RunService          = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player   = Players.LocalPlayer
local char     = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root     = char:WaitForChild("HumanoidRootPart")

-- ================= STATE =================
local farming    = false
local target     = nil
local dodgeTime  = 0
local lastDodge  = 0
local angle      = 0
local hitCount   = 0
local maxHit     = 2
local switchTarget = false
local mobList    = {}
local lastMobScan = 0
local RANGE      = 300

-- Room Z cooldown (phòng trường hợp FlyBar lỗi)
local lastRoomZ  = 0
local ROOM_MIN_CD = 5  -- tối thiểu 5 giây giữa 2 lần dùng Z

-- ================= AUTO RESPAWN =================
player.CharacterAdded:Connect(function(newChar)
    char     = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    root     = newChar:WaitForChild("HumanoidRootPart")
    task.wait(2)
    print("[KL] Respawned - tiếp tục farm!")
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
    return nil
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

-- ================= SKILL =================
local function press(key)
    VirtualInputManager:SendKeyEvent(true,  key, false, game)
    task.wait(0.09)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

-- ================= DODGE =================
local function dangerous(mob)
    if tick() - lastDodge < 1 then return false end
    if not mob then return false end
    for _, v in ipairs(mob:GetDescendants()) do
        if v:IsA("Beam") and v.Enabled then return true end
        if v:IsA("ParticleEmitter") and v.Enabled then
            local p = v.Parent
            if p and p:IsA("BasePart") then
                if (p.Position - root.Position).Magnitude < 65 then
                    return true
                end
            end
        end
    end
    return false
end

-- ===============================================
--   FLYBAR - THEO DÕI THANH ROOM OPOP
-- ===============================================
local flyBarRef = nil  -- cache reference

local function getFlyBar()
    if flyBarRef and flyBarRef.Parent then
        return flyBarRef
    end

    -- Tìm FlyBar trong PlayerGui
    local paths = {
        -- Path chính từ console log
        {"MainGui", "BaseFrame", "Frame", "ExpFrame", "FlyBar"},
        {"MainGui", "BaseFrame", "Frame", "ExpFrame", "FlyBar2"},
        -- Fallback paths
        {"MainGui", "BaseFrameOG", "Frame", "ExpFrame", "FlyBar"},
        {"MainGui", "BaseFrameOG", "Frame", "ExpFrame", "FlyBar2"},
    }

    for _, path in ipairs(paths) do
        local obj = player.PlayerGui
        local ok  = true
        for _, part in ipairs(path) do
            obj = obj:FindFirstChild(part)
            if not obj then ok = false; break end
        end
        if ok and obj then
            flyBarRef = obj
            print("[KL] ✅ Tìm thấy FlyBar: " .. obj:GetFullName())
            return obj
        end
    end

    -- Tìm kiếm rộng hơn nếu không tìm thấy
    for _, v in pairs(player.PlayerGui:GetDescendants()) do
        if v.Name == "FlyBar" or v.Name == "FlyBar2" then
            flyBarRef = v
            print("[KL] ✅ FlyBar tìm thấy (broad search): " .. v:GetFullName())
            return v
        end
    end

    return nil
end

-- Lấy % thanh Room (0.0 → 1.0)
local function getRoomBarScale()
    local bar = getFlyBar()
    if not bar then return 1 end  -- không tìm thấy → giả sử đầy, không dùng Z

    -- Kiểm tra Size
    local ok, scale = pcall(function()
        return bar.Size.X.Scale
    end)

    if ok then return scale end

    -- Fallback: kiểm tra AbsoluteSize so với Parent
    ok, scale = pcall(function()
        local parent = bar.Parent
        if parent then
            return bar.AbsoluteSize.X / parent.AbsoluteSize.X
        end
        return 1
    end)

    if ok then return scale end
    return 1
end

-- Kiểm tra có nên dùng Z không
local function shouldUseRoomZ()
    if tick() - lastRoomZ < ROOM_MIN_CD then return false end
    local scale = getRoomBarScale()
    return scale <= 0.02  -- FlyBar gần như hết (≤ 2%)
end

-- ===============================================
--   SCAN MOB trong 300 studs
-- ===============================================
local function scanMobs()
    if tick() - lastMobScan < 1 then return end
    lastMobScan = tick()
    mobList = {}

    for _, v in ipairs(Workspace:GetDescendants()) do
        if not v:IsA("Model") then continue end
        if not v:FindFirstChild("HumanoidRootPart") then continue end
        if v == char then continue end

        local isPlayer = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character == v then isPlayer = true; break end
        end
        if isPlayer then continue end

        local hum = v:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local d = (root.Position - v.HumanoidRootPart.Position).Magnitude
        if d <= RANGE then
            table.insert(mobList, v)
        end
    end
end

-- ===============================================
--   RANDOM MOB
-- ===============================================
local function getRandomMob()
    scanMobs()

    local alive = {}
    for _, v in ipairs(mobList) do
        if v.Parent then
            local hum = v:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(alive, v)
            end
        end
    end

    if #alive == 0 then return nil end
    if #alive == 1 then return alive[1] end

    local filtered = {}
    for _, v in ipairs(alive) do
        if v ~= target then
            table.insert(filtered, v)
        end
    end

    if #filtered == 0 then return alive[1] end
    return filtered[math.random(1, #filtered)]
end

-- ===============================================
--   LOOP 1: M1 SPAM + ĐẾM HIT
-- ===============================================
task.spawn(function()
    while true do
        if farming and target and dodgeTime <= 0
           and humanoid and humanoid.Health > 0 then

            local hum = target:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 or not target.Parent then
                target   = getRandomMob()
                hitCount = 0
                task.wait(0.1)
                continue
            end

            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)

                hitCount = hitCount + 1
                if hitCount >= maxHit then
                    switchTarget = true
                    hitCount     = 0
                end
            end
        end
        task.wait(0.05)
    end
end)

-- ===============================================
--   LOOP 2: SKILL (OpOp TRƯỚC, Kioru V2 SAU)
--   Z OpOp chỉ dùng khi FlyBar hết
-- ===============================================
task.spawn(function()
    while true do
        if farming and target and dodgeTime <= 0
           and humanoid and humanoid.Health > 0
           and target:FindFirstChild("HumanoidRootPart") then

            aim()

            -- ✅ OpOp FRUIT TRƯỚC
            local fruit = getTool("opop")
                       or getTool("op op")
                       or getTool("op-op")
                       or getTool("control")
            if fruit then
                equip(fruit)
                aim()

                -- ✅ Z (Zone Control) chỉ khi FlyBar hết
                if shouldUseRoomZ() then
                    print("[KL] 🔵 Room hết - Dùng Z Zone Control!")
                    press(Enum.KeyCode.Z)
                    lastRoomZ = tick()
                    task.wait(0.3)
                end

                -- X, C, V, B dùng bình thường
                press(Enum.KeyCode.X)  -- Stonecraft
                task.wait(0.1)
                press(Enum.KeyCode.C)  -- Electroheart
                task.wait(0.1)
                press(Enum.KeyCode.V)  -- Task Pillar
                task.wait(0.1)
                press(Enum.KeyCode.B)  -- Blink
                task.wait(0.1)
                press(Enum.KeyCode.E)  -- Fusion Cut
                task.wait(0.2)
            end

            -- ⚔️ KIORU V2 SAU
            local sword = getTool("kioru")
            if sword then
                equip(sword)
                aim()
                press(Enum.KeyCode.Z)  -- Echo Strike
                task.wait(0.1)
                press(Enum.KeyCode.X)  -- Biohazard Bolt
                task.wait(0.2)
            end

            -- Đổi sang con random mới sau mỗi lượt skill
            local newMob = getRandomMob()
            if newMob then
                target       = newMob
                hitCount     = 0
                switchTarget = false
            end

        end
        task.wait(0.05)
    end
end)

-- ===============================================
--   LOOP 3: Switch target từ M1
-- ===============================================
task.spawn(function()
    while true do
        task.wait(0.1)
        if farming and switchTarget then
            local newMob = getRandomMob()
            if newMob then
                target       = newMob
                hitCount     = 0
                switchTarget = false
            end
        end
    end
end)

-- ===============================================
--   MAIN LOOP (Di chuyển + Dodge)
-- ===============================================
RunService.RenderStepped:Connect(function(dt)
    if not farming then return end
    if not root or not root.Parent then return end
    if not humanoid or humanoid.Health <= 0 then return end

    if not target then
        target = getRandomMob()
        if not target then return end
    end

    if not target.Parent then
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
            math.cos(angle) * 130,
            95,
            math.sin(angle) * 130
        )
        root.CFrame = CFrame.new(pos, target.HumanoidRootPart.Position)
        dodgeTime  -= dt
    else
        root.CFrame = CFrame.new(
            target.HumanoidRootPart.Position + Vector3.new(0, 7, 0),
            target.HumanoidRootPart.Position
        )
    end
end)

-- ===============================================
--   GUI
-- ===============================================
local old = player.PlayerGui:FindFirstChild("KLFarmGUI")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name         = "KLFarmGUI"
sg.ResetOnSpawn = false
sg.Parent       = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size                   = UDim2.new(0, 240, 0, 160)
frame.Position               = UDim2.new(0, 15, 0, 15)
frame.BackgroundColor3       = Color3.fromRGB(12, 12, 20)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel        = 0
frame.Active                 = true
frame.Draggable              = true
frame.Parent                 = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local st = Instance.new("UIStroke", frame)
st.Color = Color3.fromRGB(255, 100, 0); st.Thickness = 1.5

-- Title
local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(200, 60, 0)
title.TextColor3       = Color3.new(1, 1, 1)
title.Text             = "👑  KING LEGACY FARM v4"
title.TextScaled       = true
title.Font             = Enum.Font.GothamBold
title.BorderSizePixel  = 0
title.Parent           = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

-- Target
local targetLbl = Instance.new("TextLabel")
targetLbl.Size                   = UDim2.new(1, -10, 0, 22)
targetLbl.Position               = UDim2.new(0, 5, 0, 34)
targetLbl.BackgroundTransparency = 1
targetLbl.TextColor3             = Color3.fromRGB(255, 210, 80)
targetLbl.Text                   = "🎯 Target: --"
targetLbl.TextScaled             = true
targetLbl.Font                   = Enum.Font.Gotham
targetLbl.Parent                 = frame

-- Mob count
local mobLbl = Instance.new("TextLabel")
mobLbl.Size                   = UDim2.new(1, -10, 0, 22)
mobLbl.Position               = UDim2.new(0, 5, 0, 58)
mobLbl.BackgroundTransparency = 1
mobLbl.TextColor3             = Color3.fromRGB(150, 220, 255)
mobLbl.Text                   = "👾 Mob 300s: 0"
mobLbl.TextScaled             = true
mobLbl.Font                   = Enum.Font.Gotham
mobLbl.Parent                 = frame

-- Room bar status
local roomLbl = Instance.new("TextLabel")
roomLbl.Size                   = UDim2.new(1, -10, 0, 22)
roomLbl.Position               = UDim2.new(0, 5, 0, 82)
roomLbl.BackgroundTransparency = 1
roomLbl.TextColor3             = Color3.fromRGB(100, 200, 255)
roomLbl.Text                   = "🔵 Room: --"
roomLbl.TextScaled             = true
roomLbl.Font                   = Enum.Font.Gotham
roomLbl.Parent                 = frame

-- Button
local btn = Instance.new("TextButton")
btn.Size             = UDim2.new(1, -10, 0, 38)
btn.Position         = UDim2.new(0, 5, 0, 116)
btn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
btn.TextColor3       = Color3.new(1, 1, 1)
btn.Text             = "▶  Bắt đầu Farm"
btn.TextScaled       = true
btn.Font             = Enum.Font.GothamBold
btn.BorderSizePixel  = 0
btn.Parent           = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

btn.MouseButton1Click:Connect(function()
    farming = not farming
    if farming then
        btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        btn.Text             = "⏹  Dừng Farm"
        hitCount             = 0
        switchTarget         = false
        flyBarRef            = nil  -- reset cache

        task.spawn(function()
            -- Equip OpOp ngay khi bật
            local fruit = getTool("opop")
                       or getTool("op op")
                       or getTool("op-op")
                       or getTool("control")
            if fruit then
                equip(fruit)
                print("[KL] ✅ Đã equip OpOp Fruit!")
            else
                print("[KL] ⚠️ Không tìm thấy OpOp/Control Fruit!")
            end

            -- Tìm FlyBar ngay
            task.wait(1)
            local bar = getFlyBar()
            if bar then
                print("[KL] ✅ FlyBar sẵn sàng theo dõi!")
            else
                print("[KL] ⚠️ Không tìm thấy FlyBar - Z sẽ không tự dùng!")
            end
        end)

    else
        btn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
        btn.Text             = "▶  Bắt đầu Farm"
        target               = nil
        hitCount             = 0
        switchTarget         = false
    end
end)

-- Cập nhật UI
task.spawn(function()
    while true do
        task.wait(0.4)
        if farming then
            -- Target
            local tName = target and target.Name or "Đang tìm..."
            local hum   = target and target:FindFirstChildOfClass("Humanoid")
            local hp    = hum and math.floor(hum.Health) or 0
            targetLbl.Text = "🎯 " .. tName .. "  HP:" .. hp

            -- Mob count
            mobLbl.Text = "👾 Mob 300s: " .. #mobList
                .. "  Hit: " .. hitCount .. "/" .. maxHit

            -- Room bar
            local scale = getRoomBarScale()
            local pct   = math.floor(scale * 100)
            local roomStatus = pct <= 2 and "⚡ HẾT - Z!" or ("🔵 " .. pct .. "%")
            roomLbl.Text = "Room Zone: " .. roomStatus
            roomLbl.TextColor3 = pct <= 2
                and Color3.fromRGB(255, 80, 80)
                or  Color3.fromRGB(100, 200, 255)
        else
            targetLbl.Text = "🎯 Target: --"
            mobLbl.Text    = "👾 Mob 300s: 0"
            roomLbl.Text   = "🔵 Room: --"
        end
    end
end)

print("╔══════════════════════════════════╗")
print("║  KING LEGACY HYBRID MAX v4       ║")
print("║  Z OpOp khi FlyBar hết    ✅     ║")
print("║  Fruit TRƯỚC Sword        ✅     ║")
print("║  Random mob 300 studs     ✅     ║")
print("║  2 hit + skill đổi con    ✅     ║")
print("║  M1 + Skill song song     ✅     ║")
print("╚══════════════════════════════════╝")
print("✅ Nhấn nút GUI để bắt đầu!")
