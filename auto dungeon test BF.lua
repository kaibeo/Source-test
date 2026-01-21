--==================================================
-- ZMATRIX | AUTO DUNGEON FULL FINAL (STABLE)
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
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
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
local LastGreenPos = nil
local State = "FARM"
local TP_Target = nil
local TP_Active = false

---------------- UTILS ----------------
local function getChar()
    local c = LP.Character
    if not c then return end
    return c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

---------------- LOCK / UNLOCK Y ----------------
local function LockY(hrp)
    if hrp:FindFirstChild("LOCK_Y") then return end
    local bp = Instance.new("BodyPosition")
    bp.Name="LOCK_Y"
    bp.MaxForce=Vector3.new(0,math.huge,0)
    bp.P=60000
    bp.D=1500
    bp.Position=Vector3.new(0,hrp.Position.Y,0)
    bp.Parent=hrp
end

local function UnlockY(hrp)
    local bp = hrp:FindFirstChild("LOCK_Y")
    if bp then bp:Destroy() end
end

local function MoveTo(hrp,pos,height)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = hrp.CFrame:Lerp(
        CFrame.new(pos.X,pos.Y+height,pos.Z),
        SPEED
    )
end

---------------- AUTO EQUIP ----------------
local function AutoEquip()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    for _,tool in ipairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("WeaponType")==getgenv().WeaponType then
            hum:EquipTool(tool)
            return
        end
    end
end

---------------- GREEN SCAN (NO PLAYER) ----------------
local function ScanGreen()
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local adornee=v.Adornee
            if adornee and adornee:IsA("BasePart") then
                local model=adornee:FindFirstAncestorOfClass("Model")
                if model and Players:GetPlayerFromCharacter(model) then continue end
                for _,t in ipairs(v:GetDescendants()) do
                    if t:IsA("TextLabel") then
                        local c=t.TextColor3
                        if c.G>c.R and c.G>c.B then
                            LastGreenPos=adornee.Position
                            return
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

local function FindDestroy()
    local enemies=Workspace:FindFirstChild("Enemies")
    if not enemies then return end
    local nearest,dist=nil,math.huge
    for _,v in ipairs(enemies:GetChildren()) do
        local hum=v:FindFirstChildOfClass("Humanoid")
        local hrp=v:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health>0 then
            for _,d in ipairs(v:GetDescendants()) do
                if d:IsA("BillboardGui") then
                    for _,t in ipairs(d:GetDescendants()) do
                        if t:IsA("TextLabel") and t.Text
                        and t.Text:lower():find("destroy") then
                            local d2=(hrp.Position-(select(1,getChar())).Position).Magnitude
                            if d2<dist then
                                dist=d2
                                nearest=hrp
                            end
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local function FindEnemy(hrp)
    local e=Workspace:FindFirstChild("Enemies")
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
    local e=Workspace:FindFirstChild("Enemies")
    if not e then return false end
    for _,v in ipairs(e:GetChildren()) do
        local h=v:FindFirstChildOfClass("Humanoid")
        if h and h.Health>0 and not IsShadow(v.Name) then return true end
    end
    return false
end

---------------- MAIN LOOP ----------------
RunService.Heartbeat:Connect(function()
    local hrp,hum=getChar()
    if not hrp or not hum then return end

    ScanGreen()

    if getgenv().AutoDungeon then
        AutoEquip()
    end

    if not getgenv().AutoDungeon then
        UnlockY(hrp)
        return
    end

    -- DIE
    if hum.Health<=0 then
        if LastGreenPos then State="RETURN" end
        UnlockY(hrp)
        return
    end

    -- RETURN
    if State=="RETURN" and LastGreenPos then
        UnlockY(hrp)
        MoveTo(hrp,LastGreenPos,HEIGHT_GREEN)
        if (hrp.Position-LastGreenPos).Magnitude<10 then
            State="FARM"
        end
        return
    end

    -- DESTROY PRIORITY
    local d=FindDestroy()
    if d then
        LockY(hrp)
        MoveTo(hrp,d.Position,HEIGHT_FARM)
        return
    end

    -- FARM ENEMY
    local e=FindEnemy(hrp)
    if e then
        LockY(hrp)
        MoveTo(hrp,e.Position,HEIGHT_FARM)
        return
    end

    -- CLEAR → GREEN
    if not HasEnemy() and LastGreenPos then
        UnlockY(hrp)
        MoveTo(hrp,LastGreenPos,HEIGHT_GREEN)
        return
    end

    UnlockY(hrp)
end)

----------------------------------------------------------------
-- FAST ATTACK (NGUYÊN BẢN USER – KHÔNG SỬA)
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

        local parts={}
        for _,x in ipairs({workspace.Enemies,workspace.Characters}) do
            for _,v in ipairs(x and x:GetChildren() or {}) do
                local hrp=v:FindFirstChild("HumanoidRootPart")
                local hum=v:FindFirstChild("Humanoid")
                if v~=char and hrp and hum and hum.Health>0
                and (hrp.Position-root.Position).Magnitude<=60 then
                    for _,bp in ipairs(v:GetChildren()) do
                        if bp:IsA("BasePart") then
                            parts[#parts+1]={v,bp}
                        end
                    end
                end
            end
        end

        local tool=char:FindFirstChildOfClass("Tool")
        if #parts>0 and tool
        and (tool:GetAttribute("WeaponType")=="Melee"
        or tool:GetAttribute("WeaponType")=="Sword") then
            pcall(function()
                require(ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit",true)
                ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
                local head=parts[1][1]:FindFirstChild("Head")
                if not head then return end
                ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(
                    head,parts,{},tostring(LP.UserId)
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
                    head,parts
                )
            end)
        end
    end
end)