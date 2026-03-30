-- // KING LEGACY DUNGEON FARM - KIỂU WUKONG HUB
-- Farm overhead + nhìn thẳng xuống + chỉ M1 + farm đỏ đến khi ra ngoài
-- Paste vào Executor (Fluxus, Delta, Solara...) → Execute là farm luôn!

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

-- ================== KIỂM TRA QUÁI XANH LÁ (KHÔNG FARM) ==================
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

-- ================== KIỂM TRA QUÁI ĐỎ + ĐẦU LÂU ĐỎ (FARM) ==================
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
    if not mob or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 then return false end
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

-- Chỉ spam M1 (kiểu Wukong Hub overhead farm)
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

    startAttackLoop()

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not farming then return end

        -- Phát hiện bị teleport ra ngoài dungeon
        local currentPos = root.Position
        if (currentPos - lastPosition).Magnitude > 200 then
            stopFarming()
            print("🚪 BỊ DỊCH CHUYỂN RA NGOÀI → Farm tự động dừng!")
            return
        end
        lastPosition = currentPos

        local target = getClosestMarkedMob()
        if target and target:FindFirstChild("HumanoidRootPart") then
            currentTarget = target
            local hrp = target.HumanoidRootPart

            -- BAY SÁT ĐẦU +5 + NHÌN THẲNG XUỐNG ĐẤT (chuẩn Wukong Hub)
            local aboveHead = hrp.Position + Vector3.new(0, hrp.Size.Y + 5, 0)
            root.CFrame = CFrame.new(aboveHead, hrp.Position)
        else
            currentTarget = nil
        end
    end)

    print("✅ FARM KIỂU WUKONG HUB ĐÃ BẬT!")
    print("   • Farm overhead + nhìn thẳng xuống đất")
    print("   • Chỉ farm quái ĐỎ & ĐẦU LÂU ĐỎ")
    print("   • Farm tất cả đến khi bị ra ngoài thì dừng")
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
print("🚀 WUKONG HUB STYLE FARM ĐÃ LOAD!")
print("Đang tự động farm ngay bây giờ...")
startFarming()

print("Nhấn **F** để TẮT / BẬT lại nếu cần")end

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
    if farming then return end
    farming = true
    currentTarget = nil
    lastPosition = root.Position

    startAttackLoop()

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not farming then return end

        -- PHÁT HIỆN DỊCH CHUYỂN RA NGOÀI (teleport)
        local currentPos = root.Position
        if (currentPos - lastPosition).Magnitude > 200 then
            stopFarming()
            print("🚪 ĐÃ BỊ DỊCH CHUYỂN RA NGOÀI → Farm tự động dừng!")
            return
        end
        lastPosition = currentPos

        local target = getClosestMarkedMob()
        if target and target:FindFirstChild("HumanoidRootPart") then
            currentTarget = target
            local hrp = target.HumanoidRootPart

            -- BAY SÁT ĐẦU +5
            local aboveHead = hrp.Position + Vector3.new(0, hrp.Size.Y + 5, 0)

            -- NHÌN THẲNG XUỐNG ĐẤT (sửa như bạn yêu cầu)
            root.CFrame = CFrame.new(aboveHead, hrp.Position)
        else
            currentTarget = nil
            -- Hết quái → tự chờ respawn (script vẫn chạy)
        end
    end)

    print("✅ FARM ALL QUÁI ĐỎ ĐÃ BẬT TỰ ĐỘNG!")
    print("   • Farm tất cả quái đỏ + chờ respawn")
    print("   • Bay sát đầu + nhìn thẳng xuống đất")
    print("   • Chỉ spam M1")
    print("   • Tự dừng khi bị dịch chuyển ra ngoài")
end

local function stopFarming()
    farming = false
    if heartbeatConn then heartbeatConn:Disconnect() end
    currentTarget = nil
    print("⛔ Farm đã dừng!")
end

-- Toggle F (bật/tắt thủ công nếu cần)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        if farming then
            stopFarming()
        else
            startFarming()
        end
    end
end)

-- ================== TỰ ĐỘNG FARM NGAY KHI EXECUTE ==================
print("🚀 SCRIPT KING LEGACY FARM ALL ĐÃ LOAD!")
print("Đang tự động farm tất cả quái đỏ ngay bây giờ...")
startFarming()

print("Script sẽ tự dừng khi bạn bị dịch chuyển ra ngoài dungeon!")
print("Nhấn **F** nếu muốn tắt/bật thủ công")
