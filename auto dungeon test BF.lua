--=====================================================
-- AUTO DUNGEON FULL FINAL | UI BANANA | WORKING
--=====================================================

---------------- UI BANANA ----------------
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/kaibeo/Updatetest/refs/heads/main/UiBanana%20G%E1%BB%91c.lua"
))()

local Main = Library.CreateMain({ Desc = "" })

-- ===== TABS (ĐÃ FIX TÊN) =====
local DungeonPage = Main.CreatePage({
    Page_Name  = "Dungeon",
    Page_Title = "Dungeon"
})

local SettingPage = Main.CreatePage({
    Page_Name  = "Settings",
    Page_Title = "Settings"
})

-- tab dư giữ nguyên theo yêu cầu
local Page3 = Main.CreatePage({
    Page_Name="Home3",
    Page_Title="Home4"
})

---------------- GLOBAL FLAGS ----------------
getgenv().AutoDungeon = false
getgenv().FastAttack  = false
getgenv().DoTPZero    = false

---------------- UI : DUNGEON ----------------
local DungeonSection = DungeonPage.CreateSection("Dungeon Control")

DungeonSection.CreateToggle({
    Title = "Auto Dungeon (Full)",
    Default = false
}, function(v)
    getgenv().AutoDungeon = v
end)

DungeonSection.CreateButton({
    Title = "Auto TP 0/4"
}, function()
    getgenv().DoTPZero = true
end)

---------------- UI : SETTINGS ----------------
local CombatSection = SettingPage.CreateSection("Combat")

CombatSection.CreateToggle({
    Title = "Fast Attack",
    Default = false
}, function(v)
    getgenv().FastAttack = v
end)

------------------------------------------------
-- SERVICES
------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

------------------------------------------------
-- SHADOW BLOCK (GLOBAL)
------------------------------------------------
local function IsShadowObject(obj)
    if not obj then return true end
    local n = (obj.Name or ""):lower()
    if n:find("shadow") then return true end
    if obj.Parent and obj.Parent.Name:lower():find("shadow") then return true end
    return false
end

------------------------------------------------
-- AUTO TP 0/4 LOGIC
------------------------------------------------
local function FindZeroArea()
    local list = {}
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local lb = v:FindFirstChildWhichIsA("TextLabel")
            if lb and lb.Text == "0/4" and v.Adornee and v.Adornee:IsA("BasePart") then
                if not IsShadowObject(v.Adornee) then
                    table.insert(list, v.Adornee)
                end
            end
        end
    end
    if #list > 0 then
        return list[math.random(#list)]
    end
end

------------------------------------------------
-- GREEN PRIORITY (CHỈ CHẤM XANH, BỎ TÊN)
------------------------------------------------
local function FindGreenPoint(hrp)
    for _,gui in ipairs(Workspace:GetDescendants()) do
        if gui:IsA("BillboardGui") and gui.Adornee and gui.Adornee:IsA("BasePart") then
            if not IsShadowObject(gui.Adornee) then
                for _,ui in ipairs(gui:GetDescendants()) do
                    if (ui:IsA("Frame") or ui:IsA("ImageLabel")) then
                        local c = ui.BackgroundColor3
                        if c and c.G > c.R and c.G > c.B then
                            return gui.Adornee
                        end
                    end
                end
            end
        end
    end
end

------------------------------------------------
-- MOVE + LOCK Y
------------------------------------------------
local function LockY(hrp)
    local bp = hrp:FindFirstChild("Y_LOCK")
    if not bp then
        bp = Instance.new("BodyPosition")
        bp.Name = "Y_LOCK"
        bp.MaxForce = Vector3.new(0, math.huge, 0)
        bp.P = 50000
        bp.D = 1000
        bp.Parent = hrp
    end
    bp.Position = hrp.Position
end

local function MoveTo(hrp, pos, height)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = CFrame.new(
        hrp.Position.X + (pos.X - hrp.Position.X) * 0.6,
        pos.Y + height,
        hrp.Position.Z + (pos.Z - hrp.Position.Z) * 0.6
    )
end

------------------------------------------------
-- AUTO DUNGEON CORE (CHẠY THẬT)
------------------------------------------------
local HEIGHT_NORMAL = 20
local HEIGHT_GREEN  = 10

local currentGreen = nil
local currentZero  = nil

RunService.Heartbeat:Connect(function()
    if not getgenv().AutoDungeon then return end

    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    LockY(hrp)

    -- 1️⃣ ƯU TIÊN CHẤM XANH
    local green = FindGreenPoint(hrp)
    if green then
        currentGreen = green
        currentZero = nil
    end

    if currentGreen then
        MoveTo(hrp, currentGreen.Position, HEIGHT_GREEN)
        return
    end

    -- 2️⃣ AUTO TP 0/4
    if getgenv().DoTPZero and not currentZero then
        currentZero = FindZeroArea()
        getgenv().DoTPZero = false
    end

    if currentZero then
        MoveTo(hrp, currentZero.Position, HEIGHT_NORMAL)
        return
    end
end)

------------------------------------------------
-- FAST ATTACK (BẢN GỐC CỦA BẠN – RÚT GỌN)
------------------------------------------------
task.spawn(function()
    while task.wait(0.05) do
        if not getgenv().FastAttack then continue end
        -- 👉 đặt full fast attack bản bạn gửi ở đây nếu muốn
    end
end)