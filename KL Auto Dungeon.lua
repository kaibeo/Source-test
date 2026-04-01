-- // KING LEGACY - HYBRID MAX (FULL FIXED)
-- ✅ M1 + Skill chạy song song
-- ✅ Fruit dùng trước khi vào dungeon
-- ✅ Lọc player, lọc mob chết
-- ✅ Auto respawn
-- ✅ GUI toggle
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
local farming      = false
local target       = nil
local dodgeTime    = 0
local lastDodge    = 0
local lastControlZ = 0
local angle        = 0

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
        if v:IsA("Beam") and v.Enabled then
            return true
        end
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

-- ================= TARGET =================
local function getMob()
    local closest, dist = nil, math.huge

    for _, v in ipairs(Workspace:GetDescendants()) do
        if not v:IsA("Model") then continue end
        if not v:FindFirstChild("HumanoidRootPart") then continue end
        if v == char then continue end

        -- Bỏ qua player khác
        local isPlayer = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character == v then isPlayer = true; break end
        end
        if isPlayer then continue end

        -- Bỏ qua mob đã chết
        local hum = v:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local d = (root.Position - v.HumanoidRootPart.Position).Magnitude
        if d < dist then
            dist    = d
            closest = v
        end
    end

    return closest
end

-- ===============================================
--   LOOP 1: M1 SPAM (chạy độc lập, không block)
-- ===============================================
task.spawn(function()
    while true do
        if farming and target and dodgeTime <= 0
           and humanoid and humanoid.Health > 0 then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
        end
        task.wait(0.05)
    end
end)

-- ===============================================
--   LOOP 2: SKILL (chạy độc lập, song song M1)
-- ===============================================
task.spawn(function()
    while true do
        if farming and target and dodgeTime <= 0
           and humanoid and humanoid.Health > 0
           and target:FindFirstChild("HumanoidRootPart") then

            aim()

            -- ✅ FRUIT TRƯỚC (ưu tiên khi vào dungeon)
            local fruit = getTool("fruit") or getTool("control")
            if fruit then
                equip(fruit)
                aim()

                -- Z Control: 60 giây 1 lần
                pcall(function()
                    if tostring(player.Data.DevilFruit.Value):lower():find("control") then
                        if tick() - lastControlZ > 60 then
                            press(Enum.KeyCode.Z)
                            lastControlZ = tick()
                        end
                    end
                end)

                press(Enum.KeyCode.X)
                task.wait(0.1)
                press(Enum.KeyCode.C)
                task.wait(0.1)
                press(Enum.KeyCode.V)
                task.wait(0.1)
                press(Enum.KeyCode.B)
                task.wait(0.3)
            end

            -- ⚔️ SWORD SAU
            local sword = getTool("kioru")
            if sword then
                equip(sword)
                aim()
                press(Enum.KeyCode.Z)
                task.wait(0.1)
                press(Enum.KeyCode.X)
                task.wait(0.3)
            end

        end
        task.wait(0.05)
    end
end)

-- ===============================================
--        MAIN LOOP (Di chuyển + Dodge)
-- ===============================================
RunService.RenderStepped:Connect(function(dt)
    if not farming then return end
    if not root or not root.Parent then return end
    if not humanoid or humanoid.Health <= 0 then return end

    target = getMob()
    if not target then return end
    if not target.Parent then target = nil; return end

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
--                    GUI
-- ===============================================
local old = player.PlayerGui:FindFirstChild("KLFarmGUI")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name         = "KLFarmGUI"
sg.ResetOnSpawn = false
sg.Parent       = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size             = UDim2.new(0, 210, 0, 100)
frame.Position         = UDim2.new(0, 15, 0, 15)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel  = 0
frame.Active           = true
frame.Draggable        = true
frame.Parent           = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local st = Instance.new("UIStroke", frame)
st.Color = Color3.fromRGB(255, 100, 0); st.Thickness = 1.5

-- Title
local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(200, 60, 0)
title.TextColor3       = Color3.new(1,1,1)
title.Text             = "👑  KING LEGACY FARM"
title.TextScaled       = true
title.Font             = Enum.Font.GothamBold
title.BorderSizePixel  = 0
title.Parent           = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

-- Status label
local statusLbl = Instance.new("TextLabel")
statusLbl.Size             = UDim2.new(1,-10, 0, 22)
statusLbl.Position         = UDim2.new(0, 5, 0, 32)
statusLbl.BackgroundTransparency = 1
statusLbl.TextColor3       = Color3.fromRGB(180, 255, 180)
statusLbl.Text             = "⭕ Đang dừng"
statusLbl.TextScaled       = true
statusLbl.Font             = Enum.Font.Gotham
statusLbl.Parent           = frame

-- Toggle button
local btn = Instance.new("TextButton")
btn.Size             = UDim2.new(1, -10, 0, 34)
btn.Position         = UDim2.new(0, 5, 0, 58)
btn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
btn.TextColor3       = Color3.new(1,1,1)
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
        statusLbl.Text       = "🟢 Đang farm..."

        -- ✅ Equip Fruit ngay lập tức khi bật farm
        task.spawn(function()
            local fruit = getTool("fruit") or getTool("control")
            if fruit then
                equip(fruit)
                print("[KL] ✅ Đã equip Fruit - sẵn sàng!")
            end
        end)

    else
        btn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
        btn.Text             = "▶  Bắt đầu Farm"
        statusLbl.Text       = "⭕ Đang dừng"
        target               = nil
    end
end)

-- Cập nhật status
task.spawn(function()
    while true do
        task.wait(0.5)
        if farming then
            local tName = target and target.Name or "Đang tìm..."
            statusLbl.Text = "🟢 " .. tName
        end
    end
end)

print("╔══════════════════════════════╗")
print("║  KING LEGACY HYBRID MAX      ║")
print("║  M1 + Skill song song ✅     ║")
print("║  Fruit ưu tiên trước  ✅     ║")
print("║  Auto Dodge + Respawn ✅     ║")
print("╚══════════════════════════════╝")
print("✅ Nhấn nút GUI để bắt đầu!")
