-- // KING LEGACY DUNGEON FARM - BAY LÊN ĐẦU + MẶT XUỐNG ĐẤT + M1 + Z X C V
-- Made for you by Grok - Paste vào Executor (Fluxus, Delta, Solara, v.v.)

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

-- ================== CHỈNH ĐIỀU KIỆN QUÁI CÓ ĐÁNH DẤU Ở ĐÂY ==================
local function isMarkedMob(mob)
    if not mob or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 then
        return false
    end
    if mob == character then return false end

    -- ================== CÁCH NHẬN BIẾT QUÁI CÓ ĐÁNH DẤU ==================
    -- Bạn chỉnh ở đây cho phù hợp với Dungeon hiện tại:
    -- Ví dụ 1: Có Highlight (thường quái đánh dấu sẽ có)
    if mob:FindFirstChild("Highlight") then return true end
    
    -- Ví dụ 2: Tên quái chứa từ "Dungeon", "Elite", "Boss", "Marked"
    -- if string.find(mob.Name:lower(), "dungeon") or string.find(mob.Name:lower(), "elite") or string.find(mob.Name:lower(), "marked") then return true end
    
    -- Ví dụ 3: Có BillboardGui trên đầu (thường là mark)
    if mob:FindFirstChild("Head") and mob.Head:FindFirstChild("BillboardGui") then return true end

    -- Mặc định: farm TẤT CẢ quái (bạn xóa 2 dòng dưới nếu muốn chỉ farm quái có mark)
    return true
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

-- Spam M1 + Skill Z X C V
local function startAttackLoop()
    spawn(function()
        while farming do
            if currentTarget and currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health > 0 then
                -- M1 (vũ khí)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)  -- nhấn trái
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1) -- thả

                -- Skill trái Z X C V
                for _, key in ipairs({"Z", "X", "C", "V"}) do
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                    task.wait(0.08)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
                    task.wait(0.05)
                end
            end
            task.wait(0.25) -- tốc độ farm, chỉnh nhỏ hơn nếu muốn nhanh hơn
        end
    end)
end

-- Main farm loop (Heartbeat giữ vị trí bay lên đầu + mặt xuống đất)
local function startFarming()
    if farming then return end
    farming = true
    currentTarget = nil

    startAttackLoop()

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not farming then return end

        local target = getClosestMarkedMob()
        if target and target:FindFirstChild("HumanoidRootPart") then
            currentTarget = target
            local hrp = target.HumanoidRootPart

            -- BAY LÊN ĐẦU QUÁI
            local aboveHead = hrp.Position + Vector3.new(0, hrp.Size.Y + 10, 0)

            -- MẶT XUỐNG ĐẤT (rotate CFrame nhìn thẳng xuống)
            local downCFrame = CFrame.new(aboveHead) * CFrame.Angles(math.rad(90), 0, 0)

            root.CFrame = downCFrame
        else
            currentTarget = nil
        end
    end)

    print("✅ FARM DUNGEON KING LEGACY ĐÃ BẬT!")
    print("   • Bay lên đầu quái + mặt xuống đất")
    print("   • Spam M1 + Skill Z X C V")
    print("   Nhấn F để tắt/bật")
end

local function stopFarming()
    farming = false
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    currentTarget = nil
    print("⛔ Farm đã tắt!")
end

-- Toggle bằng phím F
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        if farming then
            stopFarming()
        else
            startFarming()
        end
    end
end)

print("🚀 SCRIPT FARM DUNGEON KING LEGACY ĐÃ LOAD XONG!")
print("Nhấn **F** để BẬT / TẮT farm")
print("Đảm bảo bạn đã equip vũ khí + trái trước khi bật!")
