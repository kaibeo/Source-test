--// KING LEGACY AUTO FARM DUNGEON FULL VIP

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local HRP = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- SETTINGS
local HEIGHT = 12
local DISTANCE = 2500
local ATTACK_DELAY = 0.05

-- SERVICES
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

-- ANTI FALL
humanoid:ChangeState(11)

-- EQUIP WEAPON
function EquipWeapon()
    for _, v in pairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            v.Parent = char
        end
    end
end

-- GET ALL MOBS
function GetMobs()
    local mobs = {}
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 then
                table.insert(mobs, v)
            end
        end
    end
    return mobs
end

-- ƯU TIÊN BOSS
function GetTarget()
    local mobs = GetMobs()
    local nearest = nil
    local minDist = math.huge

    for _, v in pairs(mobs) do
        local dist = (HRP.Position - v.HumanoidRootPart.Position).Magnitude
        
        -- Ưu tiên boss (máu cao)
        if v.Humanoid.MaxHealth > 5000 then
            return v
        end

        if dist < minDist and dist <= DISTANCE then
            minDist = dist
            nearest = v
        end
    end

    return nearest
end

-- CHECK CÒN QUÁI
function HasMob()
    return #GetMobs() > 0
end

-- ATTACK
function Attack()
    VirtualUser:Button1Down(Vector2.new(0,0))
    task.wait(ATTACK_DELAY)
    VirtualUser:Button1Up(Vector2.new(0,0))
end

-- FAST ATTACK (song song)
RunService.RenderStepped:Connect(function()
    pcall(function()
        Attack()
    end)
end)

-- AUTO FARM LOOP
while task.wait() do
    pcall(function()

        if HasMob() then
            local mob = GetTarget()

            if mob then
                repeat
                    task.wait()

                    EquipWeapon()

                    local mobHRP = mob.HumanoidRootPart

                    -- 🔥 BAY + LOCK MẶT
                    HRP.CFrame = CFrame.new(
                        mobHRP.Position + Vector3.new(0, HEIGHT, 0),
                        mobHRP.Position
                    )

                until not mob
                    or not mob:FindFirstChild("Humanoid")
                    or mob.Humanoid.Health <= 0
            end

        else
            -- 💤 HẾT TẦNG → CHỜ WAVE MỚI
            repeat task.wait(1) until HasMob()
        end

    end)
end
