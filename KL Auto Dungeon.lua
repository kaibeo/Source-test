-- // KING LEGACY AUTO DUNGEON FARM FULL FIX

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

-- ================== CHECK GREEN ==================
local function hasGreenMark(mob)
    local head = mob:FindFirstChild("Head")
    if not head then return false end
    for _, gui in ipairs(head:GetDescendants()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            for _, child in ipairs(gui:GetDescendants()) do
                if child:IsA("ImageLabel") or child:IsA("Frame") then
                    local color = child.ImageColor3 or child.BackgroundColor3
                    if color and color.G > 0.75 and color.R < 0.25 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ================== CHECK RED ==================
local function hasRedMark(mob)
    local head = mob:FindFirstChild("Head")
    if not head then return false end
    for _, gui in ipairs(head:GetDescendants()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            for _, child in ipairs(gui:GetDescendants()) do
                if child:IsA("ImageLabel") or child:IsA("Frame") then
                    local color = child.ImageColor3 or child.BackgroundColor3
                    if color and color.R > 0.75 and color.G < 0.25 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function isMob(mob)
    return mob
    and mob:IsA("Model")
    and mob:FindFirstChild("Humanoid")
    and mob:FindFirstChild("HumanoidRootPart")
    and mob.Humanoid.Health > 0
    and mob ~= character
    and not hasGreenMark(mob)
    and hasRedMark(mob)
end

-- ================== GET CLOSEST ==================
local function getClosestMob()
    local closest, dist = nil, math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if isMob(v) then
            local d = (root.Position - v.HumanoidRootPart.Position).Magnitude
            if d < dist then
                dist = d
                closest = v
            end
        end
    end
    return closest
end

-- ================== AUTO CLICK ==================
local function attack()
    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
    task.wait()
    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
end

-- ================== AUTO SKILL ==================
local function useSkills()
    local keys = {"Z","X","C","V"}
    for _, key in ipairs(keys) do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
        task.wait(0.2)
    end
end

-- ================== FARM ==================
local function startFarm()
    if farming then return end
    farming = true

    -- spam M1
    spawn(function()
        while farming do
            if currentTarget then
                attack()
            end
            task.wait(0.15)
        end
    end)

    -- spam skill
    spawn(function()
        while farming do
            if currentTarget then
                useSkills()
            end
            task.wait(1)
        end
    end)

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not farming then return end

        -- nếu target chết → tìm con khác
        if not currentTarget 
        or not currentTarget:FindFirstChild("Humanoid") 
        or currentTarget.Humanoid.Health <= 0 then
            currentTarget = getClosestMob()
        end

        if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
            local hrp = currentTarget.HumanoidRootPart

            -- bay lên đầu
            local pos = hrp.Position + Vector3.new(0, hrp.Size.Y + 5, 0)

            -- nhìn xuống
            root.CFrame = CFrame.new(pos, hrp.Position)
        end
    end)

    print("✅ AUTO FARM ALL + SKILL ON")
end

local function stopFarm()
    farming = false
    if heartbeatConn then heartbeatConn:Disconnect() end
    currentTarget = nil
    print("⛔ STOP FARM")
end

-- TOGGLE F
UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F then
        if farming then
            stopFarm()
        else
            startFarm()
        end
    end
end)

startFarm()
