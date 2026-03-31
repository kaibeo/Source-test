-- // KING LEGACY - CONTINUOUS COMBO (XCVB + ZX + M1)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- ================== STATE ==================
local farming = true
local currentTarget = nil
local dodgeTime = 0
local currentAngle = 0
local lastControlZ = 0

-- ================== TOOL ==================
local function getToolByType(typeName)
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()

            if typeName == "fruit" and (n:find("fruit") or n:find("control")) then
                return tool
            end

            if typeName == "sword" and n:find("kioru") then
                return tool
            end
        end
    end
end

local function equip(tool)
    if tool then
        humanoid:EquipTool(tool)
        task.wait(0.1)
    end
end

-- ================== AIM ==================
local function aim(target)
    if target then
        local hrp = target:FindFirstChild("HumanoidRootPart")
        if hrp then
            root.CFrame = CFrame.new(root.Position, hrp.Position)
        end
    end
end

-- ================== FAST SKILL ==================
local function fastSkill(key)
    for i = 1,2 do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.04)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

-- ================== CONTROL Z ==================
local function useControlZ()
    if tick() - lastControlZ < 60 then return end

    for i = 1,2 do
        aim(currentTarget)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
        task.wait(0.15)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
        task.wait(0.1)
    end

    lastControlZ = tick()
end

-- ================== M1 LOOP ==================
spawn(function()
    while true do
        if farming and currentTarget and dodgeTime <= 0 then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and tool.Name:lower():find("kioru") then
                VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
            end
        end
        task.wait(0.01)
    end
end)

-- ================== COMBO LOOP ==================
spawn(function()
    while true do
        if farming and currentTarget and dodgeTime <= 0 then

            aim(currentTarget)

            -- 🍇 FRUIT (XCVB liên tục)
            local fruit = getToolByType("fruit")
            if fruit then
                equip(fruit)
                aim(currentTarget)

                if tostring(player.Data.DevilFruit.Value):lower():find("control") then
                    useControlZ()
                end

                fastSkill(Enum.KeyCode.X)
                fastSkill(Enum.KeyCode.C)
                fastSkill(Enum.KeyCode.V)
                fastSkill(Enum.KeyCode.B)
            end

            task.wait(0.2)

            -- ⚔️ SWORD (ZX liên tục)
            local sword = getToolByType("sword")
            if sword then
                equip(sword)
                aim(currentTarget)

                fastSkill(Enum.KeyCode.Z)
                fastSkill(Enum.KeyCode.X)
            end

            task.wait(0.2)
        end
        task.wait(0.02)
    end
end)

-- ================== TARGET ==================
local function getClosestMob()
    local closest, dist = nil, math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            local d = (root.Position - v.HumanoidRootPart.Position).Magnitude
            if d < dist then
                dist = d
                closest = v
            end
        end
    end
    return closest
end

-- ================== MAIN ==================
RunService.Heartbeat:Connect(function(dt)
    if not farming then return end

    local target = getClosestMob()
    if not target then return end

    currentTarget = target
    aim(currentTarget)

    if dodgeTime > 0 then
        currentAngle -= 10 * dt
        local offset = Vector3.new(
            math.cos(currentAngle) * 170,
            140,
            math.sin(currentAngle) * 170
        )
        root.CFrame = CFrame.new(target.HumanoidRootPart.Position + offset, target.HumanoidRootPart.Position)
        dodgeTime -= dt
    else
        root.CFrame = CFrame.new(target.HumanoidRootPart.Position + Vector3.new(0,7,0), target.HumanoidRootPart.Position)
    end
end)

print("🔥 CONTINUOUS COMBO READY (XCVB + ZX + M1)")
