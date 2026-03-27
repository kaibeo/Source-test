-- WAIT LOAD
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer.Character
repeat task.wait() until game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

local Speed = 150
local Height = 5
local HitboxSize = 12

-- 🔥 HITBOX FIX (GIỮ LIÊN TỤC)
spawn(function()
    while task.wait(0.1) do
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
                if v.Humanoid.Health > 0 then
                    v.HumanoidRootPart.Size = Vector3.new(HitboxSize,HitboxSize,HitboxSize)
                    v.HumanoidRootPart.CanCollide = false
                end
            end
        end
    end
end)

-- 🔥 TÌM QUÁI (MATCH CHUẨN)
function GetMob(name)
    local closest, dist = nil, math.huge

    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") 
        and string.find(string.lower(v.Name), string.lower(name))
        and v:FindFirstChild("HumanoidRootPart")
        and v:FindFirstChild("Humanoid") then
            
            if v.Humanoid.Health > 0 then
                local d = (LocalPlayer.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                
                if d < dist then
                    dist = d
                    closest = v
                end
            end
        end
    end

    return closest
end

-- 🔥 BAY KHÔNG BỊ BUG
function FlyTo(cf)
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hrp.CFrame = hrp.CFrame:Lerp(cf, 0.2) -- 🔥 không tween → không đứng
end

-- 🔥 FAST ATTACK LIÊN TỤC
spawn(function()
    while task.wait() do
        pcall(function()
            VirtualUser:Button1Down(Vector2.new(0,0))
            VirtualUser:Button1Up(Vector2.new(0,0))
        end)
    end
end)

-- 🔥 LOCK TARGET
local Target = nil

-- MAIN
spawn(function()
    while task.wait() do
        
        if not Target or Target.Humanoid.Health <= 0 then
            Target = GetMob("Frost Rogue") -- ⚠️ đổi theo map nếu cần
        end

        if Target then
            local pos = Target.HumanoidRootPart.Position
            local cf = CFrame.new(pos + Vector3.new(0,Height,0), pos)

            FlyTo(cf)
        end
    end
end)
