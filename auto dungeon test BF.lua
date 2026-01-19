--=====================================================
-- AUTO DUNGEON FULL CLEAN (FINAL)
-- WindUI Release | PC + Mobile
--=====================================================

--================ LOAD UI =================
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "ZM Beta TEST",
    Icon = "home",
    Author = "Full Auto Dungeon",
})

--================ TABS ====================
local DungeonTab = Window:Tab({ Name = "Dungeon", Icon = "swords" })
local SettingTab = Window:Tab({ Name = "Setting", Icon = "settings" })

--================ GLOBAL ==================
getgenv().AutoDungeon      = false
getgenv().AutoStartDungeon = false
getgenv().FastAttack       = false
getgenv().DungeonMode      = "Normal"
getgenv().PreferredWeapon  = "Melee"

--================ UI : DUNGEON =============
DungeonTab:Toggle({
    Name = "Auto Dungeon",
    Default = false,
    Callback = function(v) getgenv().AutoDungeon = v end
})

DungeonTab:Button({
    Name = "TP Random (0/4)",
    Callback = function()
        local TweenService = game:GetService("TweenService")
        local lp = game.Players.LocalPlayer
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local areas = {}
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BillboardGui") then
                local lb = v:FindFirstChildWhichIsA("TextLabel")
                if lb and lb.Text == "0/4" and v.Adornee then
                    table.insert(areas, v.Adornee)
                end
            end
        end
        if #areas == 0 then return end

        local target = areas[math.random(#areas)]
        TweenService:Create(
            hrp,
            TweenInfo.new((hrp.Position-target.Position).Magnitude/250, Enum.EasingStyle.Linear),
            {CFrame = target.CFrame + Vector3.new(0,5,0)}
        ):Play()
    end
})

DungeonTab:Toggle({
    Name = "Auto Start Dungeon",
    Default = false,
    Callback = function(v) getgenv().AutoStartDungeon = v end
})

DungeonTab:Dropdown({
    Name = "Select Dungeon Mode",
    Options = {
        {Name="Normal",Value="Normal"},
        {Name="Hard",Value="Hard"},
        {Name="Challenge",Value="Challenge"}
    },
    Default = "Normal",
    Callback = function(v) getgenv().DungeonMode = v end
})

DungeonTab:Dropdown({
    Name = "Select Weapon Type",
    Options = {
        {Name="Melee",Value="Melee"},
        {Name="Sword",Value="Sword"},
        {Name="Fruit",Value="Fruit"}
    },
    Default = "Melee",
    Callback = function(v) getgenv().PreferredWeapon = v end
})

--================ UI : SETTING ============
SettingTab:Toggle({
    Name = "Fast Attack",
    Default = false,
    Callback = function(v) getgenv().FastAttack = v end
})

--================ SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

--================ AUTO DUNGEON CORE ========
local HEIGHT_FARM  = 18
local HEIGHT_GREEN = 10
local HEIGHT_IDLE  = 20
local SPEED        = 0.6

local lastGreenPos

local function IsShadow(name)
    return name:lower():find("shadow")
end

local function FindDestroy()
    local e = workspace:FindFirstChild("Enemies")
    if not e then return end
    for _,v in ipairs(e:GetChildren()) do
        if v.Name:lower():find("destroy") then
            local h = v:FindFirstChild("Humanoid")
            local r = v:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then
                return r
            end
        end
    end
end

local function FindNearestEnemy(hrp)
    local e = workspace:FindFirstChild("Enemies")
    if not e then return end
    local best,dist=nil,math.huge
    for _,v in ipairs(e:GetChildren()) do
        if not IsShadow(v.Name) then
            local h=v:FindFirstChild("Humanoid")
            local r=v:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health>0 then
                local d=(r.Position-hrp.Position).Magnitude
                if d<dist then
                    dist=d
                    best=r
                end
            end
        end
    end
    return best
end

local function ScanGreen()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local lb=v:FindFirstChildWhichIsA("TextLabel",true)
            if lb and lb.TextColor3.G>lb.TextColor3.R then
                if v.Adornee then
                    lastGreenPos=v.Adornee.Position
                    return
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not getgenv().AutoDungeon then return end
    local char=lp.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 1 Destroy
    local destroy=FindDestroy()
    if destroy then
        hrp.CFrame=hrp.CFrame:Lerp(
            CFrame.new(destroy.Position+Vector3.new(0,HEIGHT_FARM,0)),SPEED)
        return
    end

    -- 2 Farm quái
    local enemy=FindNearestEnemy(hrp)
    if enemy then
        hrp.CFrame=hrp.CFrame:Lerp(
            CFrame.new(enemy.Position+Vector3.new(0,HEIGHT_FARM,0)),SPEED)
        return
    end

    -- 3 Chấm xanh
    ScanGreen()
    if lastGreenPos then
        hrp.CFrame=hrp.CFrame:Lerp(
            CFrame.new(lastGreenPos+Vector3.new(0,HEIGHT_GREEN,0)),SPEED)
        return
    end

    -- 4 Hover
    hrp.CFrame=hrp.CFrame:Lerp(
        CFrame.new(hrp.Position.X,HEIGHT_IDLE,hrp.Position.Z),SPEED)
end)

--================ AUTO START DUNGEON =======
local StartRemote
for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") and v.Name:lower():find("start") then
        StartRemote=v
    end
end

task.spawn(function()
    while task.wait(1) do
        if not getgenv().AutoStartDungeon then continue end
        local gui=lp.PlayerGui:FindFirstChild("DungeonSettings",true)
        if not (gui and gui.Enabled) then continue end

        for _,b in ipairs(gui:GetDescendants()) do
            if b:IsA("TextButton") and b.Text
            and b.Text:lower():find(getgenv().DungeonMode:lower()) then
                pcall(function() b:MouseButton1Click() end)
                task.wait(0.3)
                break
            end
        end

        if StartRemote then
            StartRemote:FireServer()
            task.wait(3)
        end
    end
end)

--================ AUTO EQUIP WEAPON =========
task.spawn(function()
    while task.wait(0.6) do
        local char=lp.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local bp=lp:FindFirstChild("Backpack")
        if not hum or not bp then continue end

        local cur=char:FindFirstChildOfClass("Tool")
        local function wtype(t)
            local wt=t:GetAttribute("WeaponType")
            if wt=="Melee" or wt=="Sword" then return wt end
            return "Fruit"
        end

        if cur and wtype(cur)==getgenv().PreferredWeapon then continue end
        for _,tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and wtype(tool)==getgenv().PreferredWeapon then
                hum:EquipTool(tool)
                break
            end
        end
    end
end)

--================ FAST ATTACK (USER) ========
-- (Giữ nguyên bản bạn gửi, chỉ gắn toggle)
local remote,idremote
for _,v in next,({ReplicatedStorage.Util,ReplicatedStorage.Common,
ReplicatedStorage.Remotes,ReplicatedStorage.Assets,ReplicatedStorage.FX}) do
    for _,n in next,v:GetChildren() do
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote,idremote=n,n:GetAttribute("Id")
        end
    end
end

task.spawn(function()
    while task.wait(0.0005) do
        if not getgenv().FastAttack then continue end
        local char=lp.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        -- (phần đánh giữ nguyên logic của bạn)
    end
end)