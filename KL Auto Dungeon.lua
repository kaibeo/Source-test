-- // KING LEGACY DUNGEON FARM - FARM 1 CON XONG DỪNG + NHÌN XUỐNG ĐẤT
-- UPDATE: Chỉ farm 1 con đỏ → dừng, nhìn thẳng xuống đất (không nhìn lên)
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
local hasFarmedOne = false

-- ================== KIỂM TRA MÀU XANH LÁ (KHÔNG FARM) ==================
local function hasGreenMark(mob)
    local head = mob:FindFirstChild("Head")
    if not head then return false end
    for _, gui in ipairs(head:GetDescendants()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            for _, child in ipairs(gui:GetDescendants()) do
                if child:IsA("ImageLabel") or child:IsA("Frame") then
                    local color = child.ImageColor3 or child.BackgroundColor3
                    if color and color.G > 0.75 and color.R < 0.25 and color.B < 0.25 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ================== KIỂM TRA MÀU ĐỎ + ĐẦU LÂU ĐỎ ==================
local function hasRedMarkOrRedSkull(mob)
    local head = mob:FindFirstChild("Head")
    if not head then return false end
    for _, gui in ipairs(head:GetDescendants()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            for _, child in ipairs(gui:GetDescendants()) do
                if child:IsA("ImageLabel") or child:IsA("Frame") then
                    local color = child.ImageColor3 or child.BackgroundColor3
                    if color and color.R > 0.75 and color.G < 0.25 and color.B < 0.25 then
                        return true
                    end
                end
            end
        end
    end

    local nameLower = mob.Name:lower()
    if string.find(nameLower, "firelord") or string.find(nameLower, "pirate gunner") or 
       string.find(nameLower, "elite") or string.find(nameLower, "boss") then
        return true
    end
    return false
end

local function isMarkedMob(mob)
    if not mob or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 then
        return false
    end
    if mob == character then return false end
    if hasGreenMark(mob) then return false end
    if hasRedMarkOrRedSkull(mob) then return true end
    return false
end

local function getClosestMarkedMob()
    local mobs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isMarkedMob(obj) and obj:FindFirstChild("HumanoidRootPart") then
            table.insert(mobs, obj)
        end
    end

    local closest = nil
    local shortest = math.huge
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
    if farming or hasFarmedOne then return end
    farming = true
    currentTarget = nil
    hasFarmedOne = false

    startAttackLoop()

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not farming then return end
        if hasFarmedOne then
            stopFarming()
            return
        end

        local target = getClosestMarkedMob()
        if target and target:FindFirstChild("HumanoidRootPart") then
            currentTarget = target
            local hrp = target.HumanoidRootPart

            -- BAY SÁT ĐẦU +5
            local aboveHead = hrp.Position + Vector3.new(0, hrp.Size.Y + 5, 0)

            -- SỬA: NHÌN THẲNG XUỐNG ĐẤT (nhìn thẳng vào quái bên dưới)
            root.CFrame = CFrame.new(aboveHead, hrp.Position)

            -- Nếu quái chết → farm xong 1 con, dừng
            if target.Humanoid.Health <= 0 then
                hasFarmedOne = true
            end
        else
            currentTarget = nil
        end
    end)

    print("✅ FARM 1 CON ĐÃ BẬT!")
    print("   • Farm 1 con đỏ xong → dừng hẳn (dù còn quái)")
    print("   • Bay sát đầu + nhìn thẳng xuống đất")
    print("   • Chỉ spam M1")
end

local function stopFarming()
    farming = false
    if heartbeatConn then heartbeatConn:Disconnect() end
    currentTarget = nil
    print("⛔ Farm đã dừng!")
end

-- Toggle F (bật lại để farm con tiếp theo)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        if farming then
            stopFarming()
        else
            hasFarmedOne = false
            startFarming()
        end
    end
end)

-- TỰ ĐỘNG FARM NGAY KHI EXECUTE
print("🚀 SCRIPT FARM 1 CON ĐÃ LOAD!")
print("Đang tự động farm 1 con đỏ ngay bây giờ...")
startFarming()

print("Nhấn **F** để TẮT / BẬT farm con tiếp theo")
