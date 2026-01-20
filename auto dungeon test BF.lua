--==================================================
-- ZMATRIX | AUTO DUNGEON FULL FINAL (TP FIX)
-- Banana UI | PC + Mobile | Delta OK
--==================================================

---------------- UI ----------------
local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/kaibeo/Updatetest/refs/heads/main/UiBanana%20G%E1%BB%91c.lua"
))()

local Main = Library.CreateMain({ Desc = "ZMatrix Auto Dungeon" })

local DungeonPage = Main.CreatePage({
    Page_Name = "Dungeon",
    Page_Title = "Dungeon"
})

local SettingPage = Main.CreatePage({
    Page_Name = "Settings",
    Page_Title = "Settings"
})

---------------- GLOBAL FLAGS ----------------
getgenv().AutoDungeon      = false
getgenv().AutoTPZero       = false
getgenv().AutoStartDungeon = false
getgenv().FastAttack       = false
getgenv().DungeonMode      = "Normal"
getgenv().WeaponType       = "Melee"

---------------- SERVICES ----------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

---------------- UI : DUNGEON ----------------
local S1 = DungeonPage.CreateSection("Auto Dungeon")

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

---------------- UI : SETTINGS ----------------
local S2 = SettingPage.CreateSection("Combat")

S2.CreateToggle({Title="Fast Attack",Default=false},function(v)
    getgenv().FastAttack=v
end)

---------------- CONFIG ----------------
local HEIGHT_FARM  = 20
local HEIGHT_GREEN = 7
local SPEED        = 0.6

---------------- STATE ----------------
local State = "FARM"              -- FARM / GREEN / RETURN
local LastGreenPos = nil
local ZeroTarget = nil
local IsTeleporting = false   -- 🔥 FIX TP

---------------- UTILS ----------------
local function getHRPandHum()
    local c = LP.Character
    if not c then return end
    return c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

local function LockY(hrp)
    if hrp:FindFirstChild("LOCK_Y") then return end
    local bp = Instance.new("BodyPosition")
    bp.Name = "LOCK_Y"
    bp.MaxForce = Vector3.new(0,math.huge,0)
    bp.P = 60000
    bp.D = 1500
    bp.Position = Vector3.new(0,hrp.Position.Y,0)
    bp.Parent = hrp
end

-- MOVE: KHÔNG XOAY THEO NGƯỜI / QUÁI / CAMERA
local function MoveTo(hrp,pos,height)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    local _,ry,_ = hrp.CFrame:ToEulerAnglesYXZ()
    hrp.CFrame = hrp.CFrame:Lerp(
        CFrame.new(Vector3.new(pos.X,pos.Y+height,pos.Z)) * CFrame.Angles(0,ry,0),
        SPEED
    )
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
                            return p.Position
                        end
                    end
                end
            end
        end
    end
end

---------------- ENEMY ----------------
local function IsShadow(n)
    return n:lower():find("shadow")
end

local function FindEnemy(hrp)
    local e=workspace:FindFirstChild("Enemies")
    if not e then return end
    local best,dist=nil,math.huge
    for _,v in ipairs(e:GetChildren()) do
        if not IsShadow(v.Name) then
            local h=v:FindFirstChildOfClass("Humanoid")
            local r=v:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health>0 then
                local d=(r.Position-hrp.Position).Magnitude
                if d<dist then dist=d best=r end
            end
        end
    end
    return best
end

local function HasEnemy()
    local e=workspace:FindFirstChild("Enemies")
    if not e then return false end
    for _,v in ipairs(e:GetChildren()) do
        local h=v:FindFirstChildOfClass("Humanoid")
        if h and h.Health>0 and not IsShadow(v.Name) then
            return true
        end
    end
    return false
end

---------------- DESTROY ----------------
local function FindDestroy()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,t in ipairs(v:GetDescendants()) do
                if t:IsA("TextLabel") and t.Text:lower():find("destroy") then
                    local p=v.Adornee or v.Parent
                    if p and p:IsA("BasePart") then
                        return p.Position
                    end
                end
            end
        end
    end
end

---------------- TP 0/4 ----------------
local function FindZero()
    local list={}
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local lb=v:FindFirstChildWhichIsA("TextLabel")
            if lb and lb.Text=="0/4" and v.Adornee then
                table.insert(list,v.Adornee)
            end
        end
    end
    if #list>0 then return list[math.random(#list)] end
end

---------------- AUTO START ----------------
local StartRemote
for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") and v.Name:lower():find("start") then
        StartRemote=v break
    end
end

---------------- MAIN LOOP ----------------
RunService.Heartbeat:Connect(function()
    local hrp,hum=getHRPandHum()
    if not hrp or not hum then return end

    LockY(hrp)

    -- 🔵 TP RANDOM 0/4 (FIX)
    if getgenv().AutoTPZero then
        if not IsTeleporting then
            IsTeleporting = true
            ZeroTarget = FindZero()

            if ZeroTarget then
                TweenService:Create(
                    hrp,
                    TweenInfo.new((hrp.Position-ZeroTarget.Position).Magnitude/250, Enum.EasingStyle.Linear),
                    {CFrame=ZeroTarget.CFrame+Vector3.new(0,5,0)}
                ):Play()
            else
                getgenv().AutoTPZero=false
                IsTeleporting=false
            end
        elseif ZeroTarget and (hrp.Position-ZeroTarget.Position).Magnitude<7 then
            VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)
            ZeroTarget=nil
            getgenv().AutoTPZero=false
            IsTeleporting=false
        end
        return -- ❗ KHÓA AUTO DUNGEON KHI TP
    end

    if not getgenv().AutoDungeon then return end

    -- DIE → RETURN GREEN
    if hum.Health<=0 then
        if LastGreenPos then State="RETURN" end
        return
    end

    if State=="RETURN" and LastGreenPos then
        MoveTo(hrp,LastGreenPos,HEIGHT_GREEN)
        return
    end

    -- DESTROY PRIORITY
    local d=FindDestroy()
    if d then
        MoveTo(hrp,d,HEIGHT_FARM)
        return
    end

    -- FARM ENEMY
    local e=FindEnemy(hrp)
    if e then
        MoveTo(hrp,e.Position,HEIGHT_FARM)
        return
    end

    -- CLEAR → GREEN
    if not HasEnemy() then
        local g=ScanGreen()
        if g then
            LastGreenPos=g
            MoveTo(hrp,g,HEIGHT_GREEN)
        end
    end

    -- AUTO START
    if getgenv().AutoStartDungeon and StartRemote then
        StartRemote:FireServer(getgenv().DungeonMode)
    end
end)

---------------- FAST ATTACK (USER VERSION - GIỮ NGUYÊN) ----------------
local remote,idremote
for _,v in next,({ReplicatedStorage.Util,ReplicatedStorage.Common,ReplicatedStorage.Remotes,ReplicatedStorage.Assets,ReplicatedStorage.FX}) do
    for _,n in next,v:GetChildren() do
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote,idremote=n,n:GetAttribute("Id")
        end
    end
end

task.spawn(function()
    while task.wait(0.0005) do
        if not getgenv().FastAttack or not getgenv().AutoDungeon then continue end
        local char=LP.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local tool=char:FindFirstChildOfClass("Tool")
        if not tool then continue end
        local wt=tool:GetAttribute("WeaponType")
        if wt~="Melee" and wt~="Sword" then continue end

        local parts={}
        for _,v in ipairs(workspace.Enemies:GetChildren()) do
            local hrp=v:FindFirstChild("HumanoidRootPart")
            local hum=v:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health>0
            and (hrp.Position-root.Position).Magnitude<=60 then
                for _,bp in ipairs(v:GetChildren()) do
                    if bp:IsA("BasePart") then
                        table.insert(parts,{v,bp})
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
                cloneref(remote):FireServer("RE/RegisterHit",idremote,head,parts)
            end)
        end
    end
end)