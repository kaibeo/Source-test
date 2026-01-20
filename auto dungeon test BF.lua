--==================================================
-- ZMATRIX | AUTO DUNGEON FULL FINAL (FIX FARM STOP)
-- UI: Banana UI
-- PC + Mobile | Delta OK
--==================================================

---------------- UI ----------------
local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/kaibeo/Updatetest/refs/heads/main/UiBanana%20G%E1%BB%91c.lua"
))()

local Main = Library.CreateMain({ Desc = "ZMatrix Auto Dungeon" })

local DungeonPage = Main.CreatePage({Page_Name="Dungeon",Page_Title="Dungeon"})
local SettingPage = Main.CreatePage({Page_Name="Settings",Page_Title="Settings"})

---------------- FLAGS ----------------
getgenv().AutoDungeon = false
getgenv().FastAttack  = false
getgenv().AutoTPZero  = false
getgenv().AutoStartDungeon = false
getgenv().DungeonMode = "Normal"
getgenv().WeaponType  = "Melee"

---------------- UI ----------------
local S1 = DungeonPage.CreateSection("Dungeon Control")

S1.CreateToggle({Title="Auto Dungeon",Default=false},function(v)
    getgenv().AutoDungeon=v
end)

S1.CreateButton({Title="TP Random 0/4"},function()
    getgenv().AutoTPZero=true
end)

S1.CreateToggle({Title="Auto Start Dungeon",Default=false},function(v)
    getgenv().AutoStartDungeon=v
end)

S1.CreateDropdown({
    Title="Dungeon Mode",
    List={"Normal","Hard","Challenge"},
    Default="Normal"
},function(v)
    getgenv().DungeonMode=v
end)

S1.CreateDropdown({
    Title="Weapon Type",
    List={"Melee","Sword","Fruit"},
    Default="Melee"
},function(v)
    getgenv().WeaponType=v
end)

local S2 = SettingPage.CreateSection("Combat")
S2.CreateToggle({Title="Fast Attack",Default=false},function(v)
    getgenv().FastAttack=v
end)

---------------- SERVICES ----------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

---------------- CONFIG ----------------
local HEIGHT_FARM  = 20
local HEIGHT_GREEN = 7
local SPEED = 0.6

---------------- STATE ----------------
local LastGreenPos = nil
local ReturnAfterDie = false
local ZeroTarget = nil
local IgnoredEnemies = {}
local DamageCheck = {}
local IsFarming = false   -- 🔑 FIX CHÍNH

---------------- UTILS ----------------
local function getHRPandHum()
    local c=LP.Character
    if not c then return end
    local hrp=c:FindFirstChild("HumanoidRootPart")
    local hum=c:FindFirstChildOfClass("Humanoid")
    if hrp and hum then return hrp,hum end
end

local function LockY(hrp)
    local bp=hrp:FindFirstChild("LOCKY")
    if not bp then
        bp=Instance.new("BodyPosition",hrp)
        bp.Name="LOCKY"
        bp.MaxForce=Vector3.new(0,math.huge,0)
        bp.P=60000
        bp.D=1500
    end
    bp.Position=Vector3.new(0,hrp.Position.Y,0)
end

local function MoveTo(hrp,pos,h)
    hrp.AssemblyLinearVelocity=Vector3.zero
    hrp.AssemblyAngularVelocity=Vector3.zero
    hrp.CFrame=hrp.CFrame:Lerp(
        CFrame.new(pos.X,pos.Y+h,pos.Z),
        SPEED
    )
end

local function EquipWeapon()
    local c=LP.Character
    local bp=LP.Backpack
    if not c or not bp then return end
    if c:FindFirstChildOfClass("Tool") then return end
    for _,t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and t:GetAttribute("WeaponType")==getgenv().WeaponType then
            t.Parent=c
            return
        end
    end
end

local function PressE()
    VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)
end

---------------- TP 0/4 ----------------
local function FindZero()
    local t={}
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local lb=v:FindFirstChildWhichIsA("TextLabel")
            if lb and lb.Text=="0/4" and v.Adornee then
                table.insert(t,v.Adornee)
            end
        end
    end
    if #t>0 then return t[math.random(#t)] end
end

---------------- AUTO START ----------------
task.spawn(function()
    while task.wait(1) do
        if not getgenv().AutoStartDungeon then continue end
        local gui=LP.PlayerGui:FindFirstChild("DungeonSettings",true)
        if gui and gui.Enabled then
            local btn=gui:FindFirstChildWhichIsA("TextButton",true)
            if btn then firesignal(btn.MouseButton1Click) end
        end
    end
end)

---------------- DESTROY ----------------
local function FindDestroy()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,t in ipairs(v:GetDescendants()) do
                if t:IsA("TextLabel") and t.Text:lower():find("destroy") then
                    local p=v.Adornee or v.Parent
                    if p and p:IsA("BasePart") then
                        return p
                    end
                end
            end
        end
    end
end

---------------- GREEN ----------------
local function ScanGreen()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,t in ipairs(v:GetDescendants()) do
                if t:IsA("TextLabel") then
                    local c=t.TextColor3
                    if c.G>c.R and c.G>c.B then
                        local p=v.Adornee or v.Parent
                        if p and p:IsA("BasePart") then
                            LastGreenPos=p.Position
                        end
                    end
                end
            end
        end
    end
end

---------------- FARM ----------------
local function IsBugEnemy(m)
    if IgnoredEnemies[m] then return true end
    local h=m:FindFirstChildOfClass("Humanoid")
    if not h then return true end
    local d=DamageCheck[m]
    if not d then
        DamageCheck[m]={hp=h.Health,t=os.clock()}
        return false
    end
    if os.clock()-d.t>1.5 then
        if h.Health>=d.hp-1 then
            IgnoredEnemies[m]=true
            DamageCheck[m]=nil
            return true
        else
            d.hp=h.Health
            d.t=os.clock()
        end
    end
    return false
end

local function FindEnemy(hrp)
    local e=workspace:FindFirstChild("Enemies")
    if not e then return end
    local best,dist=nil,math.huge
    for _,v in ipairs(e:GetChildren()) do
        if v.Name:lower():find("shadow") then
            IgnoredEnemies[v]=true
            continue
        end
        local h=v:FindFirstChildOfClass("Humanoid")
        local r=v:FindFirstChild("HumanoidRootPart")
        if h and r and h.Health>0 and not IsBugEnemy(v) then
            local d=(r.Position-hrp.Position).Magnitude
            if d<dist then dist=d best=r end
        end
    end
    return best
end

---------------- MAIN LOOP ----------------
RunService.Heartbeat:Connect(function()
    local hrp,hum=getHRPandHum()
    if not hrp or not hum then return end

    EquipWeapon()
    LockY(hrp)

    -- TP 0/4
    if getgenv().AutoTPZero then
        if not ZeroTarget then
            ZeroTarget=FindZero()
            if ZeroTarget then
                TweenService:Create(
                    hrp,
                    TweenInfo.new((hrp.Position-ZeroTarget.Position).Magnitude/250),
                    {CFrame=ZeroTarget.CFrame+Vector3.new(0,5,0)}
                ):Play()
            end
        elseif (hrp.Position-ZeroTarget.Position).Magnitude<7 then
            PressE()
            getgenv().AutoTPZero=false
            ZeroTarget=nil
            task.delay(1,function() getgenv().AutoDungeon=true end)
        end
        return
    end

    -- DIE
    if hum.Health<=0 then
        if LastGreenPos then ReturnAfterDie=true end
        return
    end

    -- RETURN AFTER DIE
    if ReturnAfterDie and LastGreenPos then
        MoveTo(hrp,LastGreenPos,HEIGHT_GREEN)
        if (hrp.Position-LastGreenPos).Magnitude<10 then
            ReturnAfterDie=false
        end
        return
    end

    if not getgenv().AutoDungeon then return end

    IsFarming = false -- 🔑 reset mỗi frame

    local d=FindDestroy()
    if d then
        IsFarming = true
        MoveTo(hrp,d.Position,HEIGHT_FARM)
        return
    end

    local e=FindEnemy(hrp)
    if e then
        IsFarming = true
        MoveTo(hrp,e.Position,HEIGHT_FARM)
        return
    end

    -- CHỈ GREEN KHI CLEAR
    if not IsFarming then
        ScanGreen()
        if LastGreenPos then
            MoveTo(hrp,LastGreenPos,HEIGHT_GREEN)
        end
    end
end)

---------------- FAST ATTACK (USER VERSION – KEEP) ----------------
-- (GIỮ NGUYÊN LOGIC BẠN GỬI)
local remote,idremote
for _,v in next,({
    ReplicatedStorage.Util,
    ReplicatedStorage.Common,
    ReplicatedStorage.Remotes,
    ReplicatedStorage.Assets,
    ReplicatedStorage.FX
}) do
    for _,n in next,v:GetChildren() do
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote,idremote=n,n:GetAttribute("Id")
        end
    end
end

task.spawn(function()
    while task.wait(0.0005) do
        if not getgenv().FastAttack then continue end
        local char=LP.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local tool=char:FindFirstChildOfClass("Tool")
        if not tool then continue end
        local wt=tool:GetAttribute("WeaponType")
        if wt~="Melee" and wt~="Sword" then continue end

        local parts={}
        for _,x in ipairs({workspace.Enemies}) do
            for _,v in ipairs(x:GetChildren()) do
                local hrp=v:FindFirstChild("HumanoidRootPart")
                local hum=v:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health>0 and
                (hrp.Position-root.Position).Magnitude<=60 then
                    for _,bp in ipairs(v:GetChildren()) do
                        if bp:IsA("BasePart") then
                            table.insert(parts,{v,bp})
                        end
                    end
                end
            end
        end

        if #parts>0 then
            pcall(function()
                require(ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit",true)
                ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
                local head=parts[1][1]:FindFirstChild("Head")
                if not head then return end
                ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(
                    head,parts,{},tostring(LP.UserId)
                )
                cloneref(remote):FireServer(
                    "RE/RegisterHit",
                    idremote,
                    head,parts
                )
            end)
        end
    end
end)