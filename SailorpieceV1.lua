-- WAIT LOAD FULL
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer.Character
repeat task.wait() until game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- CONFIG
local Config = {

    {Max=98, NPC=Vector3.new(171.49,16.33,-212.62), Mob="Thief [Lv.10]", Quest="Thief Hunter"},
    {Max=249, NPC=Vector3.new(171.49,16.33,-212.62), Mob="Thief boss [Lv.25]", Quest="Thief boss"},
    {Max=499, NPC=Vector3.new(-518.14,-1.40,433.11), Mob="Monkey [Lv.250]", Quest="MonkeyQuest"},
    {Max=749, NPC=Vector3.new(-467.49,18.80,478.43), Mob="Monkey boss [Lv.500]", Quest="Monkey boss"},
    {Max=999, NPC=Vector3.new(-688.78,-2.43,-458.35), Mob="Desert bandit [Lv.750]", Quest="DesertQuest"},
    {Max=1499, NPC=Vector3.new(-860.95,-4.22,-385.72), Mob="Desert [Lv.1000]", Quest="DesertBoss"},
    {Max=1999, NPC=Vector3.new(-388.48,-1.67,-946.65), Mob="Frost Rogue", Quest="FrostQuest"}

}

local Speed = 150
local Height = 5
local HitboxSize = 12

-- LEVEL FIX
function GetLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    if data and data:FindFirstChild("Level") then
        return data.Level.Value
    end
    return 1
end

-- CHỌN MAP
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
                v.HumanoidRootPart.Transparency = 0.7
                v.HumanoidRootPart.CanCollide = false
            end
        end
    end
end

-- TÌM QUÁI (FIX ALL GAME)
function GetMob(name)
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == name and v:FindFirstChild("Humanoid") then
            if v.Humanoid.Health > 0 then
                return v
            end
        end
    end
end

-- QUEST CHECK
function HasQuest()
    return LocalPlayer.PlayerGui:FindFirstChild("Quest")
end

-- NHẤN E
function PressE()
    VirtualInputManager:SendKeyEvent(true,"E",false,game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false,"E",false,game)
end

-- PROXIMITY PROMPT
function TriggerPrompt()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            fireproximityprompt(v)
        end
    end
end

-- NHẬN QUEST (FIX ALL)
function GetQuest(cfg)
    FlyTo(CFrame.new(cfg.NPC))
    task.wait(1)
    
    for i=1,3 do
        PressE()
        TriggerPrompt()
        task.wait(0.5)
    end
end

-- AUTO FARM
spawn(function()
    while task.wait() do
        
        local cfg = GetConfig()
        Hitbox()
        
        if not HasQuest() then
            GetQuest(cfg)
        end
        
        local mob = GetMob(cfg.Mob)
        
        if mob and mob:FindFirstChild("HumanoidRootPart") then
            repeat task.wait()
                
                local pos = mob.HumanoidRootPart.Position
                local cf = CFrame.new(pos + Vector3.new(0,Height,0), pos)
                
                FlyTo(cf)
                
                VirtualUser:Button1Down(Vector2.new(0,0))
                VirtualUser:Button1Up(Vector2.new(0,0))
                
            until not mob or mob.Humanoid.Health <= 0
        end
    end
end)
