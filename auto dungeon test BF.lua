--==================================================
-- ZMATRIX | AUTO DUNGEON FULL FINAL (FULL FEATURES)
-- Banana UI | PC + Mobile | Delta OK
--==================================================

---------------- UI ----------------
local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/kaibeo/Updatetest/refs/heads/main/UiBanana%20G%E1%BB%91c.lua"
))()

local Main = Library.CreateMain({ Desc = "ZMatrix Auto Dungeon" })
local DungeonPage = Main.CreatePage({ Page_Name="Dungeon", Page_Title="Dungeon" })
local SettingPage = Main.CreatePage({ Page_Name="Settings", Page_Title="Settings" })

---------------- GLOBAL ----------------
getgenv().AutoDungeon = false
getgenv().AutoTP = false
getgenv().AutoStartDungeon = false
getgenv().FastAttack = false
getgenv().DungeonMode = "Normal"
getgenv().WeaponType = "Melee"

---------------- SERVICES ----------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

---------------- UI ----------------
local D = DungeonPage.CreateSection("Dungeon Control")

D.CreateToggle({Title="Auto Dungeon",Default=false},function(v)
    getgenv().AutoDungeon=v
end)

D.CreateButton({Title="TP Random (<4/4)"},function()
    getgenv().AutoTP=true
end)

D.CreateToggle({Title="Auto Start Dungeon",Default=false},function(v)
    getgenv().AutoStartDungeon=v
end)

D.CreateDropdown({
    Title="Dungeon Mode",
    List={"Normal","Hard","Challenge"},
    Default="Normal"
},function(v)
    getgenv().DungeonMode=v
end)

D.CreateDropdown({
    Title="Weapon Type",
    List={"Melee","Sword","Fruit"},
    Default="Melee"
},function(v)
    getgenv().WeaponType=v
end)

local S = SettingPage.CreateSection("Combat")
S.CreateToggle({Title="Fast Attack",Default=false},function(v)
    getgenv().FastAttack=v
end)

---------------- CONFIG ----------------
local HEIGHT_FARM = 20
local HEIGHT_GREEN = 7
local SPEED = 0.6

---------------- STATE ----------------
local LastGreenPos=nil
local State="FARM"
local TP_Target=nil
local TP_Active=false

---------------- UTILS ----------------
local function getChar()
    local c=LP.Character
    if not c then return end
    return c:FindFirstChild("HumanoidRootPart"),c:FindFirstChildOfClass("Humanoid")
end

local function LockY(hrp)
    if hrp:FindFirstChild("LOCK_Y") then return end
    local bp=Instance.new("BodyPosition")
    bp.Name="LOCK_Y"
    bp.MaxForce=Vector3.new(0,math.huge,0)
    bp.P=60000
    bp.D=1500
    bp.Position=Vector3.new(0,hrp.Position.Y,0)
    bp.Parent=hrp
end

local function MoveTo(hrp,pos,height)
    hrp.AssemblyLinearVelocity=Vector3.zero
    hrp.AssemblyAngularVelocity=Vector3.zero
    hrp.CFrame=hrp.CFrame:Lerp(
        CFrame.new(pos.X,pos.Y+height,pos.Z),
        SPEED
    )
end

---------------- AUTO EQUIP WEAPON ----------------
local function AutoEquip()
    local char=LP.Character
    if not char then return end
    for _,tool in ipairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local wt=tool:GetAttribute("WeaponType")
            if wt==getgenv().WeaponType then
                char.Humanoid:EquipTool(tool)
                return
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
                            return
                        end
                    end
                end
            end
        end
    end
end

---------------- ENEMY ----------------
local function IsShadow(n) return n:lower():find("shadow") end

local function FindDestroy()
    local e=workspace:FindFirstChild("Enemies")
    if not e then return end
    for _,v in ipairs(e:GetChildren()) do
        if v.Name:lower():find("destroy") then
            local h=v:FindFirstChildOfClass("Humanoid")
            local r=v:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health>0 then return r end
        end
    end
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
        if h and h.Health>0 and not IsShadow(v.Name) then return true end
    end
    return false
end

---------------- TP RANDOM <4/4 ----------------
local function FindRandomDungeon()
    local list={}
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local lb=v:FindFirstChildWhichIsA("TextLabel")
            if lb and lb.Text then
                local a,b=lb.Text:match("(%d+)/(%d+)")
                a=tonumber(a) b=tonumber(b)
                if a and b and a<b then
                    local p=v.Adornee or v.Parent
                    if p and p:IsA("BasePart") then
                        table.insert(list,p.Position)
                    end
                end
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
    local hrp,hum=getChar()
    if not hrp or not hum then return end
    LockY(hrp)

    if getgenv().AutoDungeon then
        AutoEquip()
    end

    -- TP RANDOM
    if getgenv().AutoTP then
        if not TP_Active then
            TP_Active=true
            TP_Target=FindRandomDungeon()
            if TP_Target then
                TweenService:Create(
                    hrp,
                    TweenInfo.new((hrp.Position-TP_Target).Magnitude/250),
                    {CFrame=CFrame.new(TP_Target.X,TP_Target.Y+10,TP_Target.Z)}
                ):Play()
            else
                getgenv().AutoTP=false
                TP_Active=false
            end
        elseif TP_Target and
        math.abs(hrp.Position.X-TP_Target.X)<6 and
        math.abs(hrp.Position.Z-TP_Target.Z)<6 then
            VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)
            getgenv().AutoTP=false
            TP_Active=false
        end
        return
    end

    if not getgenv().AutoDungeon then return end

    -- DIE
    if hum.Health<=0 then
        if LastGreenPos then State="RETURN" end
        return
    end

    if State=="RETURN" and LastGreenPos then
        MoveTo(hrp,LastGreenPos,HEIGHT_GREEN)
        return
    end

    local d=FindDestroy()
    if d then MoveTo(hrp,d.Position,HEIGHT_FARM) return end

    local e=FindEnemy(hrp)
    if e then MoveTo(hrp,e.Position,HEIGHT_FARM) return end

    if not HasEnemy() then
        if LastGreenPos then
            MoveTo(hrp,LastGreenPos,HEIGHT_GREEN)
        else
            ScanGreen()
        end
    end

    if getgenv().AutoStartDungeon and StartRemote then
        StartRemote:FireServer(getgenv().DungeonMode)
    end
end)

----------------------------------------------------------------
-- FAST ATTACK (NGUYÊN BẢN USER – KHÔNG SỬA LOGIC)
----------------------------------------------------------------
local remote,idremote
for _, v in next, ({
    ReplicatedStorage.Util,
    ReplicatedStorage.Common,
    ReplicatedStorage.Remotes,
    ReplicatedStorage.Assets,
    ReplicatedStorage.FX
}) do
    for _, n in next, v:GetChildren() do
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end
    v.ChildAdded:Connect(function(n)
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end)
end

task.spawn(function()
    while task.wait(0.0005) do
        if not getgenv().FastAttack or not getgenv().AutoDungeon then continue end

        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local parts = {}
        for _, x in ipairs({workspace.Enemies, workspace.Characters}) do
            for _, v in ipairs(x and x:GetChildren() or {}) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if v ~= char and hrp and hum and hum.Health > 0
                and (hrp.Position - root.Position).Magnitude <= 60 then
                    for _, _v in ipairs(v:GetChildren()) do
                        if _v:IsA("BasePart") then
                            parts[#parts+1] = {v, _v}
                        end
                    end
                end
            end
        end

        local tool = char:FindFirstChildOfClass("Tool")
        if #parts > 0 and tool and
        (tool:GetAttribute("WeaponType")=="Melee" or tool:GetAttribute("WeaponType")=="Sword") then
            pcall(function()
                require(ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit", true)
                ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
                local head = parts[1][1]:FindFirstChild("Head")
                if not head then return end
                ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(
                    head, parts, {},
                    tostring(LP.UserId):sub(2,4)..tostring(coroutine.running()):sub(11,15)
                )
                cloneref(remote):FireServer(
                    string.gsub("RE/RegisterHit",".",function(c)
                        return string.char(bit32.bxor(
                            string.byte(c),
                            math.floor(workspace:GetServerTimeNow()/10%10)+1
                        ))
                    end),
                    bit32.bxor(idremote+909090,
                        ReplicatedStorage.Modules.Net.seed:InvokeServer()*2),
                    head, parts
                )
            end)
        end
    end
end)