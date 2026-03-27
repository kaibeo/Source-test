-- WAIT LOAD
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer.Character
repeat task.wait() until game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- CONFIG
local Config = {
    {Max=98, NPC=Vector3.new(171.49,16.33,-212.62), Mob="Thief [Lv.10]"},
    {Max=249, NPC=Vector3.new(171.49,16.33,-212.62), Mob="Thief boss [Lv.25]"},
    {Max=499, NPC=Vector3.new(-518.14,-1.40,433.11), Mob="Monkey [Lv.250]"},
    {Max=749, NPC=Vector3.new(-467.49,18.80,478.43), Mob="Monkey boss [Lv.500]"},
    {Max=999, NPC=Vector3.new(-688.78,-2.43,-458.35), Mob="Desert bandit [Lv.750]"},
    {Max=1499, NPC=Vector3.new(-860.95,-4.22,-385.72), Mob="Desert [Lv.1000]"},
    {Max=1999, NPC=Vector3.new(-388.48,-1.67,-946.65), Mob="Frost Rogue"}
}

local Speed = 150
local Height = 5
local HitboxSize = 10

-- LEVEL FIX (đa hệ)
function GetLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    if data and data:FindFirstChild("Level") then
        return data.Level.Value
    end
    
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _,v in pairs(ls:GetChildren()) do
            if v.Name:lower():find("level") then
                return v.Value
            end
        end
    end
    
    return 1
end

-- CONFIG SELECT
function GetConfig()
    local lv = GetLevel()
    for _,v in pairs(Config) do
        if lv <= v.Max then
            return v
        end
    end
    return Config[#Config]
end

-- BAY
function FlyTo(cf)
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local dist = (hrp.Position - cf.Position).Magnitude
    local tween = TweenService:Create(hrp, TweenInfo.new(dist/Speed), {CFrame = cf})
    tween:Play()
    tween.Completed:Wait()
end

-- HITBOX
function Hitbox()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
            if v.Humanoid.Health > 0 then
                v.HumanoidRootPart.Size = Vector3.new(HitboxSize,HitboxSize,HitboxSize)
                v.HumanoidRootPart.CanCollide = false
            end
        end
    end
end

-- TÌM QUÁI (chuẩn hơn)
function GetMob(name)
    local closest = nil
    local dist = math.huge
    
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == name and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
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

-- CHECK QUEST UI
function HasQuest()
    return LocalPlayer.PlayerGui:FindFirstChild("Quest")
end

-- NHẤN E (CHỈ GẦN NPC)
function TryGetQuest(npcPos)
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local dist = (hrp.Position - npcPos).Magnitude
    
    if dist < 10 then
        VirtualInputManager:SendKeyEvent(true,"E",false,game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false,"E",false,game)
    end
end

-- MAIN
spawn(function()
    while task.wait() do
        
        local cfg = GetConfig()
        Hitbox()
        
        if not HasQuest() then
            FlyTo(CFrame.new(cfg.NPC))
            task.wait(1)
            TryGetQuest(cfg.NPC) -- ✅ không spam nữa
        else
            local mob = GetMob(cfg.Mob)
            
            if mob then
                repeat task.wait()
                    
                    local pos = mob.HumanoidRootPart.Position
                    local cf = CFrame.new(pos + Vector3.new(0,Height,0), pos)
                    
                    FlyTo(cf)
                    
                    VirtualUser:Button1Down(Vector2.new(0,0))
                    VirtualUser:Button1Up(Vector2.new(0,0))
                    
                until not mob or mob.Humanoid.Health <= 0
            end
        end
    end
end)
