--==================================================
-- ZMATRIX | AUTO DUNGEON FULL FINAL (STABLE)
-- UI: Banana UI
-- PC + Mobile | Delta X OK
--==================================================

---------------- UI ----------------
local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/kaibeo/Updatetest/refs/heads/main/UiBanana%20G%E1%BB%91c.lua"
))()

local Main = Library.CreateMain({ Desc = "" })

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
local S = DungeonPage.CreateSection("Dungeon Control")

S.CreateToggle({
    Title="Auto Dungeon (Full)",
    Desc="Farm + Destroy + Green",
    Default=false
},function(v)
    getgenv().AutoDungeon = v
end)

S.CreateButton({
    Title="Auto TP 0/4"
},function()
    getgenv().AutoTPZero = true
end)

S.CreateToggle({
    Title="Auto Start Dungeon",
    Desc="Auto select mode & start",
    Default=false
},function(v)
    getgenv().AutoStartDungeon = v
end)

S.CreateDropdown({
    Title="Dungeon Mode",
    Desc="Select mode",
    List={"Normal","Hard","Challenge"},
    Default="Normal",
    Search=false,
    Selected=false
},function(v)
    getgenv().DungeonMode = v
end)

S.CreateDropdown({
    Title="Weapon Type",
    Desc="Auto equip & keep weapon",
    List={"Melee","Sword","Fruit"},
    Default="Melee",
    Search=false,
    Selected=false
},function(v)
    getgenv().WeaponType = v
end)

---------------- UI : SETTINGS ----------------
local S2 = SettingPage.CreateSection("Combat")

S2.CreateToggle({
    Title="Fast Attack",
    Desc="Fast attack dungeon",
    Default=false
},function(v)
    getgenv().FastAttack = v
end)

---------------- CORE VAR ----------------
local ZeroTarget = nil
local ZeroTween  = nil
local LastGreen  = nil

local HEIGHT_FARM  = 20
local HEIGHT_GREEN = 10
local SPEED = 0.6

---------------- HELPERS ----------------
local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function PressE()
    VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)
end

---------------- AUTO EQUIP (FORCE) ----------------
local function ForceEquipWeapon()
    local char = LP.Character
    local hum = getHum()
    local backpack = LP:FindFirstChild("Backpack")
    if not char or not hum or not backpack then return end

    local want = getgenv().WeaponType
    local current = char:FindFirstChildOfClass("Tool")

    if current then
        local curType = current:GetAttribute("WeaponType")
        if want == "Fruit" and not curType then return end
        if curType == want then return end
    end

    for _,tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local tType = tool:GetAttribute("WeaponType")

            if tType and tType == want then
                hum:EquipTool(tool)
                return
            end

            if want == "Fruit" and not tType then
                hum:EquipTool(tool)
                return
            end
        end
    end
end

---------------- FIND 0/4 ----------------
local function FindZero()
    local list = {}
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local lb = v:FindFirstChildWhichIsA("TextLabel")
            if lb and lb.Text=="0/4" and v.Adornee then
                table.insert(list,v.Adornee)
            end
        end
    end
    if #list > 0 then
        return list[math.random(#list)]
    end
end

---------------- AUTO CLICK MODE ----------------
local function AutoSelectDungeonMode()
    local gui = LP.PlayerGui:FindFirstChild("DungeonSettings", true)
    if not gui or not gui.Enabled then return end

    for _,btn in ipairs(gui:GetDescendants()) do
        if btn:IsA("TextButton") then
            local t = btn.Text:lower()
            if getgenv().DungeonMode=="Normal" and t:find("normal") then
                firesignal(btn.MouseButton1Click)
            elseif getgenv().DungeonMode=="Hard" and t:find("hard") then
                firesignal(btn.MouseButton1Click)
            elseif getgenv().DungeonMode=="Challenge" and t:find("challenge") then
                firesignal(btn.MouseButton1Click)
            end
        end
    end
end

local function AutoClickStartDungeon()
    local gui = LP.PlayerGui:FindFirstChild("DungeonSettings", true)
    if not gui or not gui.Enabled then return end

    for _,btn in ipairs(gui:GetDescendants()) do
        if btn:IsA("TextButton") and btn.Text:lower():find("start") then
            firesignal(btn.MouseButton1Click)
            return
        end
    end
end

task.spawn(function()
    while task.wait(0.4) do
        if getgenv().AutoStartDungeon then
            AutoSelectDungeonMode()
            task.wait(0.2)
            AutoClickStartDungeon()
        end
    end
end)

---------------- MAIN LOOP ----------------
RunService.Heartbeat:Connect(function()
    local hrp = getHRP()
    if not hrp then return end

    -- FORCE EQUIP
    if getgenv().AutoDungeon or getgenv().AutoStartDungeon then
        ForceEquipWeapon()
    end

    -- 🔵 TP 0/4 (HIGHEST PRIORITY)
    if getgenv().AutoTPZero then
        if not ZeroTarget then
            ZeroTarget = FindZero()
            if ZeroTarget then
                local d = (hrp.Position-ZeroTarget.Position).Magnitude
                ZeroTween = TweenService:Create(
                    hrp,
                    TweenInfo.new(d/250,Enum.EasingStyle.Linear),
                    {CFrame = ZeroTarget.CFrame + Vector3.new(0,5,0)}
                )
                ZeroTween:Play()
            end
        else
            if (hrp.Position-ZeroTarget.Position).Magnitude < 7 then
                PressE()
                getgenv().AutoTPZero = false
                ZeroTarget = nil
            end
        end
        return
    end

    if not getgenv().AutoDungeon then return end

    -- 🟢 GREEN POINT
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,t in ipairs(v:GetDescendants()) do
                if t:IsA("TextLabel") then
                    local c=t.TextColor3
                    if c.G>c.R and c.G>c.B then
                        if v.Adornee then
                            LastGreen=v.Adornee.Position
                        end
                    end
                end
            end
        end
    end

    if LastGreen then
        hrp.CFrame = CFrame.new(
            hrp.Position:Lerp(
                Vector3.new(
                    LastGreen.X,
                    LastGreen.Y+HEIGHT_GREEN,
                    LastGreen.Z
                ),
                SPEED
            )
        )
    end
end)

---------------- FAST ATTACK (USER VERSION) ----------------
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
        if not getgenv().FastAttack or not getgenv().AutoDungeon then continue end
        local char=LP.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local parts={}
        for _,v in ipairs((workspace:FindFirstChild("Enemies") or {}):GetChildren()) do
            local hrp=v:FindFirstChild("HumanoidRootPart")
            local hum=v:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health>0 and
            (hrp.Position-root.Position).Magnitude<=120 then
                for _,bp in ipairs(v:GetChildren()) do
                    if bp:IsA("BasePart") then
                        table.insert(parts,{v,bp})
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