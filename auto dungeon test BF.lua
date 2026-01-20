--=====================================================
-- AUTO DUNGEON FULL FINAL | UI BANANA | ALL FEATURES
--=====================================================

---------------- UI BANANA ----------------
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/kaibeo/Updatetest/refs/heads/main/UiBanana%20G%E1%BB%91c.lua"
))()

local Main = Library.CreateMain({ Desc = "" })

local DungeonPage = Main.CreatePage({ Page_Name="Dungeon", Page_Title="Dungeon" })
local SettingPage = Main.CreatePage({ Page_Name="Settings", Page_Title="Settings" })
local Page3 = Main.CreatePage({ Page_Name="Home3", Page_Title="Home4" })

---------------- GLOBAL FLAGS ----------------
getgenv().AutoDungeon      = false
getgenv().AutoStartDungeon = false
getgenv().FastAttack       = false
getgenv().DungeonMode      = "Normal"
getgenv().PreferredWeapon  = "Melee"
getgenv().IsFarmingEnemy   = false

---------------- UI : DUNGEON ----------------
local S = DungeonPage.CreateSection("Dungeon Control")

S.CreateToggle({Title="Auto Dungeon (Full)",Default=false},function(v)
    getgenv().AutoDungeon=v
end)

S.CreateToggle({Title="Auto Start Dungeon",Default=false},function(v)
    getgenv().AutoStartDungeon=v
end)

S.CreateDropdown({
    Title="Dungeon Mode",
    List={"Normal","Hard","Challenge"},
    Default="Normal"
},function(v)
    getgenv().DungeonMode=v
end)

S.CreateDropdown({
    Title="Weapon Type",
    List={"Melee","Sword","Fruit"},
    Default="Melee"
},function(v)
    getgenv().PreferredWeapon=v
end)

S.CreateButton({Title="Auto TP 0/4"},function()
    _G.StartTPZero()
end)

---------------- UI : SETTINGS ----------------
local S2 = SettingPage.CreateSection("Combat")
S2.CreateToggle({Title="Fast Attack",Default=false},function(v)
    getgenv().FastAttack=v
end)

------------------------------------------------
-- SERVICES
------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

------------------------------------------------
-- UTIL
------------------------------------------------
local function IsShadow(name)
    return name and name:lower():find("shadow")
end

local function getHRP()
    local c=LP.Character
    return c and c:FindFirstChild("HumanoidRootPart"),
           c and c:FindFirstChildOfClass("Humanoid")
end

------------------------------------------------
-- AUTO START + SELECT MODE
------------------------------------------------
task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().AutoStartDungeon then continue end
        local gui = LP.PlayerGui:FindFirstChild("DungeonSettings",true)
        if not gui or not gui.Enabled then continue end

        for _,b in ipairs(gui:GetDescendants()) do
            if b:IsA("TextButton") then
                local t=(b.Text or ""):lower()
                if t:find(getgenv().DungeonMode:lower()) then
                    pcall(function() firesignal(b.MouseButton1Click) end)
                end
            end
        end

        task.wait(0.3)

        for _,b in ipairs(gui:GetDescendants()) do
            if b:IsA("TextButton") and (b.Text or ""):lower():find("start") then
                pcall(function() firesignal(b.MouseButton1Click) end)
                task.wait(2)
            end
        end
    end
end)

------------------------------------------------
-- AUTO EQUIP WEAPON
------------------------------------------------
local function AutoEquip()
    local c=LP.Character
    local bp=LP:FindFirstChild("Backpack")
    if not c or not bp then return end
    for _,t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and t:GetAttribute("WeaponType")==getgenv().PreferredWeapon then
            pcall(function() c.Humanoid:EquipTool(t) end)
            return
        end
    end
end
LP.CharacterAdded:Connect(function()
    task.wait(1)
    AutoEquip()
end)

------------------------------------------------
-- TP 0/4 + AUTO E
------------------------------------------------
local ZeroTarget=nil
local ZeroTween=nil

local function IsInDungeon()
    return Workspace:FindFirstChild("Enemies")~=nil
end

local function FindZero()
    local list={}
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local lb=v:FindFirstChildWhichIsA("TextLabel")
            if lb and lb.Text=="0/4" and v.Adornee and v.Adornee:IsA("BasePart") then
                if not IsShadow(v.Adornee.Name) then
                    table.insert(list,v.Adornee)
                end
            end
        end
    end
    if #list>0 then return list[math.random(#list)] end
end

local function PressE()
    VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)
end

function _G.StartTPZero()
    if IsInDungeon() then return end
    ZeroTarget=FindZero()
    if not ZeroTarget then return end

    local hrp=getHRP()
    if not hrp then return end

    if ZeroTween then pcall(function() ZeroTween:Cancel() end) end
    local d=(hrp.Position-ZeroTarget.Position).Magnitude
    ZeroTween=TweenService:Create(
        hrp,
        TweenInfo.new(d/250,Enum.EasingStyle.Linear),
        {CFrame=ZeroTarget.CFrame+Vector3.new(0,5,0)}
    )
    ZeroTween:Play()
end

------------------------------------------------
-- FARM / DESTROY / GREEN
------------------------------------------------
local HEIGHT_NORMAL=20
local HEIGHT_GREEN=10
local SPEED=0.6
local lastGreen=nil
local afterDieGreen=nil
local needReturn=false

local function LockY(hrp)
    local bp=hrp:FindFirstChild("Y_LOCK")
    if not bp then
        bp=Instance.new("BodyPosition",hrp)
        bp.Name="Y_LOCK"
        bp.MaxForce=Vector3.new(0,math.huge,0)
        bp.P=60000
        bp.D=1200
    end
    bp.Position=hrp.Position
end

local function MoveTo(hrp,pos,h)
    hrp.AssemblyLinearVelocity=Vector3.zero
    hrp.CFrame=CFrame.new(
        hrp.Position.X+(pos.X-hrp.Position.X)*SPEED,
        pos.Y+h,
        hrp.Position.Z+(pos.Z-hrp.Position.Z)*SPEED
    )
end

local function FindDestroy()
    local e=Workspace:FindFirstChild("Enemies")
    if not e then return end
    for _,v in ipairs(e:GetChildren()) do
        if v.Name:lower():find("destroy") then
            local h=v:FindFirstChild("Humanoid")
            local r=v:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health>0 then return r end
        end
    end
end

local function FindEnemy(hrp)
    local e=Workspace:FindFirstChild("Enemies")
    if not e then return end
    local best,dist=nil,math.huge
    for _,v in ipairs(e:GetChildren()) do
        if not IsShadow(v.Name) then
            local h=v:FindFirstChild("Humanoid")
            local r=v:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health>0 then
                local d=(r.Position-hrp.Position).Magnitude
                if d<dist then dist,best=d,r end
            end
        end
    end
    return best
end

local function FindGreen(hrp)
    for _,g in ipairs(Workspace:GetDescendants()) do
        if g:IsA("BillboardGui") and g.Adornee then
            for _,ui in ipairs(g:GetDescendants()) do
                if ui:IsA("Frame") or ui:IsA("ImageLabel") then
                    local c=ui.BackgroundColor3
                    if c and c.G>c.R and c.G>c.B then
                        lastGreen=g.Adornee.Position
                        return
                    end
                end
            end
        end
    end
end

------------------------------------------------
-- MAIN LOOP
------------------------------------------------
RunService.Heartbeat:Connect(function()
    if not getgenv().AutoDungeon then return end
    local hrp,hum=getHRP()
    if not hrp or not hum then return end
    LockY(hrp)

    if ZeroTarget then
        if (hrp.Position-ZeroTarget.Position).Magnitude<8 then
            PressE()
            ZeroTarget=nil
        end
        return
    end

    if hum.Health<=0 then
        if lastGreen then
            afterDieGreen=lastGreen
            needReturn=true
        end
        return
    end

    if needReturn and afterDieGreen then
        MoveTo(hrp,afterDieGreen,HEIGHT_GREEN)
        if (hrp.Position-afterDieGreen).Magnitude<10 then
            needReturn=false
        end
        return
    end

    local d=FindDestroy()
    if d then
        getgenv().IsFarmingEnemy=true
        MoveTo(hrp,d.Position,HEIGHT_NORMAL)
        return
    end

    local e=FindEnemy(hrp)
    if e then
        getgenv().IsFarmingEnemy=true
        MoveTo(hrp,e.Position,HEIGHT_NORMAL)
        return
    end

    getgenv().IsFarmingEnemy=false
    FindGreen(hrp)
    if lastGreen then
        MoveTo(hrp,lastGreen,HEIGHT_GREEN)
    end
end)

------------------------------------------------
-- FAST ATTACK (ĐÚNG BẢN BẠN GỬI)
------------------------------------------------
local remote,idremote
for _,v in next,{ReplicatedStorage.Util,ReplicatedStorage.Common,
ReplicatedStorage.Remotes,ReplicatedStorage.Assets,ReplicatedStorage.FX} do
    for _,n in next,v:GetChildren() do
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote,idremote=n,n:GetAttribute("Id")
        end
    end
end

task.spawn(function()
    while task.wait(0.0005) do
        if not getgenv().FastAttack or not getgenv().IsFarmingEnemy then continue end
        local char=LP.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local parts={}
        for _,x in ipairs({Workspace.Enemies,Workspace.Characters}) do
            for _,v in ipairs(x and x:GetChildren() or {}) do
                local hrp=v:FindFirstChild("HumanoidRootPart")
                local hum=v:FindFirstChild("Humanoid")
                if v~=char and hrp and hum and hum.Health>0
                and (hrp.Position-root.Position).Magnitude<=120 then
                    for _,bp in ipairs(v:GetChildren()) do
                        if bp:IsA("BasePart") then
                            parts[#parts+1]={v,bp}
                        end
                    end
                end
            end
        end
        local tool=char:FindFirstChildOfClass("Tool")
        if #parts>0 and tool then
            pcall(function()
                require(ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit",true)
                ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
                local head=parts[1][1]:FindFirstChild("Head")
                if not head then return end
                ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(
                    head,parts,{},
                    tostring(LP.UserId):sub(2,4)..tostring(coroutine.running()):sub(11,15)
                )
                cloneref(remote):FireServer(
                    string.gsub("RE/RegisterHit",".",function(c)
                        return string.char(bit32.bxor(
                            string.byte(c),
                            math.floor(workspace:GetServerTimeNow()/10%10)+1))
                    end),
                    bit32.bxor(
                        idremote+909090,
                        ReplicatedStorage.Modules.Net.seed:InvokeServer()*2),
                    head,parts)
            end)
        end
    end
end)