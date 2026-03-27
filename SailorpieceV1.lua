-- LOAD
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer.Character
repeat task.wait() until game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local plr = Players.LocalPlayer

-- SETTINGS
local Height = 5
local HitboxSize = 12

-- 🔥 FARM ZONES
local Zones = {
    {Max=98, Mob="Thief", Pos=Vector3.new(171.49,16.33,-212.62)},
    {Max=249, Mob="Thief boss", Pos=Vector3.new(171.49,16.33,-212.62)},
    {Max=499, Mob="Monkey", Pos=Vector3.new(-518.14,-1.40,433.11)},
    {Max=749, Mob="Monkey boss", Pos=Vector3.new(-467.49,18.80,478.43)},
    {Max=999, Mob="Desert bandit", Pos=Vector3.new(-688.78,-2.43,-458.35)},
    {Max=1499, Mob="Desert", Pos=Vector3.new(-860.95,-4.22,-385.72)},
    {Max=1999, Mob="Frost Rogue", Pos=Vector3.new(-388.48,-1.67,-946.65)}
}

-- 🔥 GET LEVEL (đa hệ)
function GetLevel()
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        for _,v in pairs(ls:GetChildren()) do
            if string.lower(v.Name):find("level") then
                return v.Value
            end
        end
    end

    for _,v in pairs(plr.PlayerGui:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text:find("Cấp") then
            return tonumber(v.Text:match("%d+")) or 1
        end
    end

    return 1
end

-- 🔥 CHỌN ZONE
function GetZone()
    local lv = GetLevel()
    for _,z in ipairs(Zones) do
        if lv <= z.Max then
            return z
        end
    end
    return Zones[#Zones]
end

-- 🔥 FIND MOB
function GetMob(name)
    local closest, dist = nil, math.huge
    
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") 
        and v:FindFirstChild("HumanoidRootPart") 
        and v:FindFirstChild("Humanoid") 
        and not Players:GetPlayerFromCharacter(v) then
            
            if v.Humanoid.Health > 0 then
                
                if string.find(string.lower(v.Name), string.lower(name)) then
                    return v
                end
                
                local d = (plr.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = v
                end
            end
        end
    end
    
    return closest
end

-- 🔥 HITBOX (KHÔNG MẤT)
spawn(function()
    while task.wait(0.1) do
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") 
            and v:FindFirstChild("HumanoidRootPart") 
            and v:FindFirstChild("Humanoid") then
                
                if v.Humanoid.Health > 0 then
                    v.HumanoidRootPart.Size = Vector3.new(HitboxSize,HitboxSize,HitboxSize)
                    v.HumanoidRootPart.CanCollide = false
                end
            end
        end
    end
end)

-- 🔥 FAST ATTACK
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

-- 🔥 MAIN FARM
spawn(function()
    while task.wait() do
        
        local zone = GetZone()
        local hrp = plr.Character.HumanoidRootPart
        
        if not Target or not Target.Parent or Target.Humanoid.Health <= 0 then
            Target = GetMob(zone.Mob)
        end
        
        if Target then
            local pos = Target.HumanoidRootPart.Position
            hrp.CFrame = CFrame.new(pos + Vector3.new(0,Height,0), pos)
        else
            -- 🔥 fallback về bãi quái
            hrp.CFrame = CFrame.new(zone.Pos)
        end
    end
end)
