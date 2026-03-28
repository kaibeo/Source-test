-- // KING LEGACY AUTO DUNGEON FARM - FIX ONLY 1 MOB + SKILL NOT WORKING
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local farming = false
local currentTarget = nil
local heartbeatConn = nil

-- Anti Fall + Noclip nhẹ
local function setupAntiFall()
    spawn(function()
        while farming and character and character.Parent do
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
            task.wait(0.6)
        end
    end)
end

-- Check Red Mark (Enemy trong Dungeon)
local function hasRedMark(mob)
    local head = mob:FindFirstChild("Head") or mob:FindFirstChildWhichIsA("BasePart")
    if not head then return false end
    for _, gui in ipairs(head:GetDescendants()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            for _, child in ipairs(gui:GetDescendants()) do
                if child:IsA("ImageLabel") or child:IsA("Frame") then
                    local color = child.ImageColor3 or child.BackgroundColor3
                    if color and color.R > 0.65 and color.G < 0.35 and color.B < 0.35 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Check Green Mark (Skip quest/safe mob)
local function hasGreenMark(mob)
    local head = mob:FindFirstChild("Head")
    if not head then return false end
    for _, gui in ipairs(head:GetDescendants()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            for _, child in ipairs(gui:GetDescendants()) do
                if child:IsA("ImageLabel") or child:IsA("Frame") then
                    local color = child.ImageColor3 or child.BackgroundColor3
                    if color and color.G > 0.65 and color.R < 0.35 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function isValidMob(mob)
    if not mob or not mob:IsA("Model") then return false end
    local hum = mob:FindFirstChild("Humanoid")
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return false end
    if mob == character then return false end
    if hasGreenMark(mob) then return false end
    return hasRedMark(mob)
end

-- Tìm mob gần nhất (tối ưu + giới hạn khoảng cách)
local function getClosestMob()
    local closest, minDist = nil, math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if isValidMob(v) then
            local dist = (root.Position - v.HumanoidRootPart.Position).Magnitude
            if dist < minDist and dist < 600 then
                minDist = dist
                closest = v
            end
        end
    end
    return closest
end

local function attack()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.04)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function useSkills()
    local keys = {"Z","X","C","V"}
    for _, k in ipairs(keys) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[k], false, game)
        task.wait(0.07)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[k], false, game)
        task.wait(0.18)
    end
end

local function startFarm()
    if farming then return end
    farming = true
    setupAntiFall()

    -- Spam M1
    spawn(function()
        while farming do
            if currentTarget and currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health > 0 then
                attack()
            end
            task.wait(0.11)
        end
    end)

    -- Spam Skill (giảm delay để dùng thường xuyên hơn)
    spawn(function()
        while farming do
            if currentTarget and currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health > 5 then
                useSkills()
            end
            task.wait(0.75)   -- Giảm từ 0.9 xuống để skill dùng nhiều hơn
        end
    end)

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not farming or not root then return end

        -- Kiểm tra target chết hoặc mất → tìm mới NGAY
        if not currentTarget 
           or not currentTarget.Parent 
           or not currentTarget:FindFirstChild("Humanoid") 
           or currentTarget.Humanoid.Health <= 5 then
            
            currentTarget = getClosestMob()
        end

        if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
            local hrp = currentTarget.HumanoidRootPart
            local abovePos = hrp.Position + Vector3.new(0, hrp.Size.Y + 6, 0)
            root.CFrame = CFrame.new(abovePos, hrp.Position)
        end
    end)

    print("✅ AUTO DUNGEON FARM FIXED - Sẽ chuyển mob & spam skill liên tục")
end

local function stopFarm()
    farming = false
    if heartbeatConn then heartbeatConn:Disconnect() end
    currentTarget = nil
    print("⛔ STOP FARM")
end

-- Toggle bằng phím F
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        if farming then
            stopFarm()
        else
            startFarm()
        end
    end
end)

-- Xử lý khi chết/respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    root = newChar:WaitForChild("HumanoidRootPart", 5)
    humanoid = newChar:WaitForChild("Humanoid", 5)
    if farming then
        task.wait(1.5)
        startFarm()
    end
end)

startFarm()  -- Auto bật khi chạy script
