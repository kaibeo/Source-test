local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ========== CẤU HÌNH ==========
local CONFIG = {
    FarmEnabled = true,
    NoClip = true,          -- Bay xuyên tường khi di chuyển
    FlySpeed = 80,          -- Tốc độ bay tới khu vực farm
    CollectRadius = 15,     -- Bán kính thu thập hoa
    AutoReturnHive = true,  -- Tự về tổ khi đầy mật
    DebugMode = false,
    
    -- Vị trí các khu farm hoa phổ biến
    FarmZones = {
        {name = "Dandelion Field", pos = Vector3.new(-200, 10, -200)},
        {name = "Sunflower Field", pos = Vector3.new(100, 10, -150)},
        {name = "Mushroom Field", pos = Vector3.new(-50, 10, 200)},
        {name = "Bamboo Field", pos = Vector3.new(300, 10, 50)},
        {name = "Blue Flower Field", pos = Vector3.new(-300, 10, 100)},
        {name = "Clover Field", pos = Vector3.new(0, 10, -50)},
    },
    
    -- Vị trí tổ ong (Hive)
    HivePosition = Vector3.new(0, 10, 0),
    
    -- Khu farm hiện tại (index)
    CurrentZone = 1,
}

-- ========== BIẾN TOÀN CỤC ==========
local isFarming = false
local isFlying = false
local noclipEnabled = false
local bodyVelocity = nil
local bodyGyro = nil

-- ========== NOCLIP (ĐI XUYÊN) ==========
local function enableNoclip()
    noclipEnabled = true
    RunService.Stepped:Connect(function()
        if noclipEnabled and character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    noclipEnabled = false
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ========== HÀM BAY ==========
local function flyTo(targetPos, speed, callback)
    isFlying = true
    
    -- Bật noclip khi bay
    if CONFIG.NoClip then
        enableNoclip()
    end
    
    -- Tạo BodyVelocity & BodyGyro nếu chưa có
    if not bodyVelocity then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = rootPart
    end
    
    if not bodyGyro then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bodyGyro.D = 100
        bodyGyro.Parent = rootPart
    end
    
    -- Bay tới điểm đích
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not rootPart or not rootPart.Parent then
            connection:Disconnect()
            return
        end
        
        local distance = (rootPart.Position - targetPos).Magnitude
        
        if distance <= 5 then
            -- Đã tới nơi
            bodyVelocity.Velocity = Vector3.zero
            connection:Disconnect()
            isFlying = false
            
            -- Tắt noclip khi đã tới nơi
            if CONFIG.NoClip then
                task.wait(0.5)
                disableNoclip()
            end
            
            if callback then callback() end
        else
            -- Tính hướng bay
            local direction = (targetPos - rootPart.Position).Unit
            bodyVelocity.Velocity = direction * speed
            bodyGyro.CFrame = CFrame.lookAt(rootPart.Position, targetPos)
        end
    end)
end

-- ========== THU THẬP HOA ==========
local function collectFlowers()
    -- Tìm tất cả các hoa trong workspace
    local workspace = game:GetService("Workspace")
    local collected = 0
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if not isFarming then break end
        
        -- Kiểm tra các hoa (Pollen, Flower...)
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("flower") or name:find("pollen") or name:find("dandelion") 
               or name:find("sunflower") or name:find("mushroom") or name:find("clover")
               or name:find("bamboo") or name:find("blue") or name:find("red") then
                
                local objPos
                if obj:IsA("Model") and obj.PrimaryPart then
                    objPos = obj.PrimaryPart.Position
                elseif obj:IsA("BasePart") then
                    objPos = obj.Position
                end
                
                if objPos then
                    local dist = (rootPart.Position - objPos).Magnitude
                    if dist <= CONFIG.CollectRadius then
                        -- Teleport tới hoa để thu thập
                        rootPart.CFrame = CFrame.new(objPos + Vector3.new(0, 2, 0))
                        task.wait(0.1)
                        collected = collected + 1
                    end
                end
            end
        end
    end
    
    return collected
end

-- ========== FARM LOOP CHÍNH ==========
local function startFarming()
    isFarming = true
    print("[BeeSwarm Farm] 🐝 Bắt đầu farm hoa!")
    
    while isFarming do
        local zone = CONFIG.FarmZones[CONFIG.CurrentZone]
        
        if not zone then
            CONFIG.CurrentZone = 1
            zone = CONFIG.FarmZones[1]
        end
        
        print("[BeeSwarm Farm] 🌸 Đang bay tới: " .. zone.name)
        
        -- Bay tới khu farm (có noclip)
        local arrived = false
        flyTo(zone.pos, CONFIG.FlySpeed, function()
            arrived = true
        end)
        
        -- Chờ tới nơi
        while not arrived and isFarming do
            task.wait(0.1)
        end
        
        if not isFarming then break end
        
        print("[BeeSwarm Farm] ✅ Đã tới " .. zone.name .. " - Bắt đầu thu hoạch!")
        
        -- Thu thập hoa trong khu vực (sweep)
        local farmTime = 15  -- Giây farm mỗi khu
        local startTime = tick()
        
        while tick() - startTime < farmTime and isFarming do
            -- Di chuyển qua lại trong khu farm để thu hoạch
            local sweepPositions = {
                zone.pos + Vector3.new(-20, 0, -20),
                zone.pos + Vector3.new(20, 0, -20),
                zone.pos + Vector3.new(20, 0, 20),
                zone.pos + Vector3.new(-20, 0, 20),
                zone.pos,
            }
            
            for _, sweepPos in ipairs(sweepPositions) do
                if not isFarming or tick() - startTime >= farmTime then break end
                
                local sweepArrived = false
                flyTo(sweepPos, CONFIG.FlySpeed * 0.7, function()
                    sweepArrived = true
                end)
                
                while not sweepArrived and isFarming do
                    task.wait(0.1)
                end
                
                local collected = collectFlowers()
                if CONFIG.DebugMode then
                    print("[Debug] Thu thập: " .. collected .. " hoa tại " .. tostring(sweepPos))
                end
                
                task.wait(1)
            end
        end
        
        -- Chuyển sang khu tiếp theo
        CONFIG.CurrentZone = CONFIG.CurrentZone % #CONFIG.FarmZones + 1
        print("[BeeSwarm Farm] 🔄 Chuyển sang khu farm tiếp theo...")
        
        task.wait(2)
    end
    
    print("[BeeSwarm Farm] ⏹️ Đã dừng farm!")
end

-- ========== DỪNG FARM ==========
local function stopFarming()
    isFarming = false
    isFlying = false
    disableNoclip()
    
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    
    print("[BeeSwarm Farm] ❌ Đã tắt script farm!")
end

-- ========== GUI ĐƠN GIẢN ==========
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BeeSwarmFarmGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 280)
    frame.Position = UDim2.new(0, 10, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    title.TextColor3 = Color3.fromRGB(0, 0, 0)
    title.Text = "🐝 Bee Farm Script"
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 30)
    statusLabel.Position = UDim2.new(0, 5, 0, 50)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Text = "Status: Đang dừng"
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = frame
    
    -- Zone label
    local zoneLabel = Instance.new("TextLabel")
    zoneLabel.Size = UDim2.new(1, -10, 0, 30)
    zoneLabel.Position = UDim2.new(0, 5, 0, 85)
    zoneLabel.BackgroundTransparency = 1
    zoneLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    zoneLabel.Text = "Zone: -"
    zoneLabel.TextScaled = true
    zoneLabel.Font = Enum.Font.Gotham
    zoneLabel.Parent = frame
    
    -- Nút Start/Stop Farm
    local farmBtn = Instance.new("TextButton")
    farmBtn.Size = UDim2.new(1, -20, 0, 45)
    farmBtn.Position = UDim2.new(0, 10, 0, 125)
    farmBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    farmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    farmBtn.Text = "▶ Bắt đầu Farm"
    farmBtn.TextScaled = true
    farmBtn.Font = Enum.Font.GothamBold
    farmBtn.Parent = frame
    Instance.new("UICorner", farmBtn).CornerRadius = UDim.new(0, 8)
    
    -- Nút NoClip Toggle
    local noclipBtn = Instance.new("TextButton")
    noclipBtn.Size = UDim2.new(1, -20, 0, 40)
    noclipBtn.Position = UDim2.new(0, 10, 0, 180)
    noclipBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    noclipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    noclipBtn.Text = "🔵 NoClip: TẮT"
    noclipBtn.TextScaled = true
    noclipBtn.Font = Enum.Font.GothamBold
    noclipBtn.Parent = frame
    Instance.new("UICorner", noclipBtn).CornerRadius = UDim.new(0, 8)
    
    -- Nút đổi zone
    local zoneBtn = Instance.new("TextButton")
    zoneBtn.Size = UDim2.new(1, -20, 0, 35)
    zoneBtn.Position = UDim2.new(0, 10, 0, 230)
    zoneBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 200)
    zoneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    zoneBtn.Text = "🔄 Đổi Zone Farm"
    zoneBtn.TextScaled = true
    zoneBtn.Font = Enum.Font.GothamBold
    zoneBtn.Parent = frame
    Instance.new("UICorner", zoneBtn).CornerRadius = UDim.new(0, 8)
    
    -- === SỰ KIỆN ===
    farmBtn.MouseButton1Click:Connect(function()
        if isFarming then
            stopFarming()
            farmBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            farmBtn.Text = "▶ Bắt đầu Farm"
            statusLabel.Text = "Status: Đang dừng"
        else
            task.spawn(startFarming)
            farmBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            farmBtn.Text = "⏹ Dừng Farm"
            statusLabel.Text = "Status: 🟢 Đang farm..."
        end
    end)
    
    noclipBtn.MouseButton1Click:Connect(function()
        CONFIG.NoClip = not CONFIG.NoClip
        if CONFIG.NoClip then
            noclipBtn.Text = "🔵 NoClip: BẬT"
            noclipBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            enableNoclip()
        else
            noclipBtn.Text = "🔵 NoClip: TẮT"
            noclipBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
            disableNoclip()
        end
    end)
    
    zoneBtn.MouseButton1Click:Connect(function()
        CONFIG.CurrentZone = CONFIG.CurrentZone % #CONFIG.FarmZones + 1
        local zone = CONFIG.FarmZones[CONFIG.CurrentZone]
        zoneLabel.Text = "Zone: " .. zone.name
        print("[BeeSwarm Farm] Đổi sang zone: " .. zone.name)
    end)
    
    -- Cập nhật zone label liên tục
    task.spawn(function()
        while true do
            task.wait(1)
            local zone = CONFIG.FarmZones[CONFIG.CurrentZone]
            if zone then
                zoneLabel.Text = "Zone: " .. zone.name
            end
            if isFarming then
                statusLabel.Text = "Status: 🟢 Đang farm..."
            else
                statusLabel.Text = "Status: ⭕ Dừng"
            end
        end
    end)
end

-- ========== KHỞI ĐỘNG ==========
createGUI()
print("=================================")
print("🐝 Bee Swarm Farm Script Loaded!")
print("✅ NoClip: BAY XUYÊN QUA VẬT THỂ")
print("🌸 Zones: " .. #CONFIG.FarmZones .. " khu farm")
print("=================================")
