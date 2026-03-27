-- CONFIG
local Config = {

    Low = {MaxLevel=98, NPC=Vector3.new(171.49,16.33,-212.62), Mob="Thief [Lv.10]", Quest="Thief Hunter"},
    Boss = {MaxLevel=249, NPC=Vector3.new(171.49,16.33,-212.62), Mob="Thief boss [Lv.25]", Quest="Thief boss"},
    Mid = {MaxLevel=499, NPC=Vector3.new(-518.14,-1.40,433.11), Mob="Monkey [Lv.250]", Quest="MonkeyQuest"},
    High = {MaxLevel=749, NPC=Vector3.new(-467.49,18.80,478.43), Mob="Monkey boss [Lv.500]", Quest="Monkey boss"},
    Ultra = {MaxLevel=999, NPC=Vector3.new(-688.78,-2.43,-458.35), Mob="Desert bandit [Lv.750]", Quest="DesertQuest"},
    Mega = {MaxLevel=1499, NPC=Vector3.new(-860.95,-4.22,-385.72), Mob="Desert [Lv.1000]", Quest="DesertBoss"},
    UltraMax = {MaxLevel=1999, NPC=Vector3.new(-388.48,-1.67,-946.65), Mob="Frost Rogue", Quest="FrostQuest"}
}

local Height = 5
local HitboxSize = 12
local Speed = 150 -- ✅ theo yêu cầu

-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- LEVEL
function GetLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    return data and data:FindFirstChild("Level") and data.Level.Value or 1
end

-- CHỌN CONFIG
function GetConfig()
    local lv = GetLevel()
    for _,cfg in pairs(Config) do
        if lv <= cfg.MaxLevel then
            return cfg
        end
    end
end

-- BAY MƯỢT (NO TP)
function FlyTo(cf)
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local dist = (hrp.Position - cf.Position).Magnitude
    local time = dist / Speed
    
    local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {
        CFrame = cf
    })
    
    tween:Play()
    tween.Completed:Wait()
end

-- QUEST
function HasQuest()
    return LocalPlayer.PlayerGui:FindFirstChild("Quest")
end

function GetQuest(cfg)
    FlyTo(CFrame.new(cfg.NPC))
    task.wait(1)
    
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StartQuest", cfg.Quest, 1)
    end)
end

-- TÌM QUÁI
function GetMob(name)
    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == name and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            return v
        end
    end
end

-- HITBOX
function Hitbox()
    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
            if v.Humanoid.Health > 0 then
                v.HumanoidRootPart.Size =
