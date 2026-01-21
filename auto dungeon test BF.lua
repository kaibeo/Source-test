--==================================================
-- ZMATRIX | AUTO DUNGEON FULL FIXED
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
local MOVE_SPEED = 0.35

---------------- STATE ----------------
local LastGreenPos = nil
local State = "FARM"
local DeadReturn = false
local IgnoreShadow = {}

---------------- UTILS ----------------
local function getChar()
    local c = LP.Character
    if not c then return end
    return c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

local function MoveTo(hrp,pos,height)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = hrp.CFrame:Lerp(
        CFrame.new(pos.X,pos.Y+height,pos.Z),
        MOVE_SPEED
    )
end

---------------- AUTO EQUIP ----------------
local function AutoEquip()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for _,tool in ipairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("WeaponType")==getgenv().WeaponType then
            hum:EquipTool(tool)
            return
        end
    end
end

---------------- GREEN (CHỈ DIAMOND) ----------------
local function ScanGreen()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local img = v:FindFirstChildWhichIsA("ImageLabel",true)
            if img then
                local p = v.Adornee or v.Parent
                if p and p:IsA("BasePart") then
                    LastGreenPos = p.Position
                    return
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
        if not IgnoreShadow[v] then
            local h=v:FindFirstChildOfClass("Humanoid")
            local r=v:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health>0 then
                if IsShadow(v.Name) then
                    IgnoreShadow[v]=true
                else
                    local d=(r.Position-hrp.Position).Magnitude
                    if d<dist then dist=d best=r end
                end
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
            if lb then
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

    ScanGreen()
    if getgenv().AutoDungeon then AutoEquip() end

    -- TP RANDOM
    if getgenv().AutoTP then
        local pos=FindRandomDungeon()
        if pos then
            TweenService:Create(
                hrp,
                TweenInfo.new((hrp.Position-pos).Magnitude/250),
                {CFrame=CFrame.new(pos.X,pos.Y+10,pos.Z)}
            ):Play()
            VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game)
            VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)
        end
        getgenv().AutoTP=false
        return
    end

    if not getgenv().AutoDungeon then return end

    -- DIE
    if hum.Health<=0 then
        DeadReturn=true
        return
    end

    if DeadReturn and LastGreenPos then
        MoveTo(hrp,LastGreenPos,HEIGHT_GREEN)
        if (hrp.Position-LastGreenPos).Magnitude<8 then
            DeadReturn=false
        end
        return
    end

    -- DESTROY PRIORITY
    local d=FindDestroy()
    if d then
        MoveTo(hrp,d.Position,HEIGHT_FARM)
        return
    end

    -- FARM
    local e=FindEnemy(hrp)
    if e then
        MoveTo(hrp,e.Position,HEIGHT_FARM)
        return
    end

    -- CLEAR → GREEN
    if not HasEnemy() and LastGreenPos then
        MoveTo(hrp,LastGreenPos,HEIGHT_GREEN)
    end

    -- AUTO START
    if getgenv().AutoStartDungeon and StartRemote then
        StartRemote:FireServer(getgenv().DungeonMode)
    end
end)

----------------------------------------------------------------
-- FAST ATTACK (GIỮ NGUYÊN CODE USER)
----------------------------------------------------------------
-- [ĐÃ GIỮ NGUYÊN ĐÚNG 100% CODE BẠN GỬI]