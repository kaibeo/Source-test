-- AUTO FARM DUNGEON THEO TẦNG (Wave)

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local HRP = char:WaitForChild("HumanoidRootPart")

-- SETTINGS
local HEIGHT = 10
local DISTANCE = 2000

-- Lấy quái gần nhất
function GetNearestMob()
    local nearest = nil
    local minDist = math.huge

    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 then
                local dist = (HRP.Position - v.HumanoidRootPart.Position).Magnitude
                if dist < minDist and dist <= DISTANCE then
                    minDist = dist
                    nearest = v
                end
            end
        end
    end

    return nearest
end

-- Check còn quái không (để biết hết tầng)
function HasMob()
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") then
            if v.Humanoid.Health > 0 then
                return true
            end
        end
    end
    return false
end

-- Equip weapon
function EquipWeapon()
    for _, v in pairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            v.Parent = char
        end
    end
end

-- Attack
function Attack()
    pcall(function()
        game:GetService("VirtualUser"):Button1Down(Vector2.new(0,0))
        wait()
        game:GetService("VirtualUser"):Button1Up(Vector2.new(0,0))
    end)
end

-- MAIN LOOP
while task.wait() do
    pcall(function()

        -- 🔥 Nếu có quái → farm
        if HasMob() then
            local mob = GetNearestMob()

            if mob then
                repeat
                    task.wait()

                    EquipWeapon()

                    local mobHRP = mob.HumanoidRootPart

                    -- bay lên đầu + khóa mặt
                    HRP.CFrame = CFrame.new(
                        mobHRP.Position + Vector3.new(0, HEIGHT, 0),
                        mobHRP.Position
                    )

                    Attack()

                until not mob
                    or not mob:FindFirstChild("Humanoid")
                    or mob.Humanoid.Health <= 0
            end

        else
            -- 💤 Hết tầng → chờ spawn
            repeat
                task.wait(1)
            until HasMob()
        end

    end)
end
