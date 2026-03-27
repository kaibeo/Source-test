-- WAIT LOAD
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
    {Max=98, NPC=Vector3.new(171.49,16.33,-212.62), Mob="Thief"},
    {Max=249, NPC=Vector3.new(171.49,16.33,-212.62), Mob="Thief boss"},
    {Max=499, NPC=Vector3.new(-518.14,-1.40,433.11), Mob="Monkey"},
    {Max=749, NPC=Vector3.new(-467.49,18.80,478.43), Mob="Monkey boss"},
    {Max=999, NPC=Vector3.new(-688.78,-2.43,-458.35), Mob="Desert bandit"},
    {Max=1499, NPC=Vector3.new(-860.95,-4.22,-385.72), Mob="Desert"},
    {Max=1999, NPC=Vector3.new(-388.48,-1.67,-946.65), Mob="Frost Rogue"}
}

local Speed = 150
local Height = 5
local HitboxSize = 10

-- LEVEL FIX
function GetLevel()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _,v in pairs(ls:GetChildren()) do
            if string.lower(v.Name):find("level") then
                return v.Value
            end
        end
    end

    for _,v in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text:find("Cấp") then
            return tonumber(v.Text:match("%d+")) or 1
        end
    end

    return 1
end

-- CHỌN MAP
function GetConfig()
    local lv = GetLevel()

    table.sort(Config,function(a,b)
        return a.Max < b.Max
    end)

    for _,v in ipairs(Config) do
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

-- TÌM QUÁI (MATCH LINH HOẠT)
function GetMob(name)
    local closest, dist = nil, math.huge

    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") 
        and string.find(string.lower(v.Name), string.lower(name))
        and v:FindFirstChild("Humanoid")
        and v:FindFirstChild("HumanoidRootPart") then
            
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

-- CHECK QUEST
function HasQuest()
    return LocalPlayer.PlayerGui:FindFirstChild("Quest")
end

-- NHẬN QUEST (KHÔNG SPAM)
function GetQuest(cfg)
    FlyTo(CFrame.new(cfg.NPC))
    task.wait(1)

    VirtualInputManager:SendKeyEvent(true,"E",false,game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false,"E",false,game)
end

-- AUTO COMBAT
function EnableCombat()
    for _,v in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if v:IsA("TextButton") and v.Text == "Chiến đấu" then
            pcall(function()
                firesignal(v.MouseButton1Click)
            end)
        end
    end
end

-- FAST ATTACK
function FastAttack()
    pcall(function()
        VirtualUser:Button1Down(Vector2.new(0,0))
        VirtualUser:Button1Up(Vector2.new(0,0))
    end)
end

-- LOCK TARGET
local Target = nil

-- MAIN
spawn(function()
    while task.wait() do
        
        EnableCombat()
        Hitbox()

        local cfg = GetConfig()

        if not HasQuest() then
            GetQuest(cfg)
        else
            
            if not Target or Target.Humanoid.Health <= 0 then
                Target = GetMob(cfg.Mob)
            end

            if Target then
                repeat task.wait()
                    
                    local pos = Target.HumanoidRootPart.Position
                    local cf = CFrame.new(pos + Vector3.new(0,Height,0), pos)

                    FlyTo(cf)
                    FastAttack()

                until not Target or Target.Humanoid.Health <= 0

                Target = nil
            end
        end
    end
end)
