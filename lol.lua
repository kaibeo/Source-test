-- ZMATRIX AIMBOT COMBAT: ENEMY ONLY + 4 WEAPON TYPES (MELEE / SWORD / FRUIT / GUN)
-- MELEE: M1 + (tùy, có thể thêm skill)
-- SWORD / FRUIT / GUN: CHỈ XÀI SKILL (Z,X,C,V)

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local Workspace      = game:GetService("Workspace")
local VirtualUser    = game:GetService("VirtualUser")
local TweenService   = game:GetService("TweenService")

local LocalPlayer    = Players.LocalPlayer
local Camera         = Workspace.CurrentCamera
local Vim            = game:GetService("VirtualInputManager")

math.randomseed(tick())

----------------------------------------------------------------
-- ===== CẤU HÌNH TÊN VŨ KHÍ THEO LOẠI =====
----------------------------------------------------------------
local MELEE_LIST = {
    "Combat",
    "Black Leg",
    "Electric",
    "Dragon Talon",
    "Superhuman",
}

local SWORD_LIST = {
    "Saber",
    "Dark Blade",
    "Yoru",
    "Katana",
}

local FRUIT_LIST = {
    "Light-Light",
    "Dough-Dough",
    "Flame-Flame",
}

local GUN_LIST = {
    "Slingshot",
    "Refined Slingshot",
    "Kabucha",
}

-- skill dùng cho Sword / Fruit / Gun
local SKILL_KEYS = {
    Enum.KeyCode.Z,
    Enum.KeyCode.X,
    Enum.KeyCode.C,
    Enum.KeyCode.V,
}

-- cooldown đơn giản (giây) cho từng skill
local SKILL_COOLDOWN = {
    [Enum.KeyCode.Z] = 2,
    [Enum.KeyCode.X] = 4,
    [Enum.KeyCode.C] = 6,
    [Enum.KeyCode.V] = 8,
}

local LastSkillCast = {}

----------------------------------------------------------------
-- THAM SỐ KHOẢNG CÁCH
----------------------------------------------------------------
local MIN_DIST   = 3.5  -- thấp nhất
local MAX_DIST   = 4.5  -- cao nhất
local IDEAL_DIST = 4    -- cố giữ khoảng 4m

----------------------------------------------------------------
-- BIẾN CHUNG
----------------------------------------------------------------
local TeleportedUsers   = {}  -- [UserId] = true (người đã thử)
local CurrentTarget      = nil
local TargetHumanoidConn = nil
local LastTargetHealth   = nil
local NoDamageCount      = 0   -- số lần attack mà không giảm HP
local CurrentMoveTween   = nil

----------------------------------------------------------------
-- HÀM TIỆN ÍCH
----------------------------------------------------------------
local function isInList(name, list)
    if not name then return false end
    for _, v in ipairs(list) do
        if string.lower(v) == string.lower(name) then
            return true
        end
    end
    return false
end

local function getToolCategory(tool)
    if not tool or not tool.Name then
        return nil
    end

    local name = tool.Name

    if isInList(name, MELEE_LIST) then
        return "Melee"
    elseif isInList(name, SWORD_LIST) then
        return "Sword"
    elseif isInList(name, FRUIT_LIST) then
        return "Fruit"
    elseif isInList(name, GUN_LIST) then
        return "Gun"
    end

    return nil
end

local function isEnemy(plr)
    -- Nếu game có Team: chỉ đánh khác team
    if LocalPlayer.Team and plr.Team then
        return plr.Team ~= LocalPlayer.Team
    end
    -- Nếu không có team -> coi như enemy hết
    return true
end

local function getRandomEnemy()
    local candidates = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer
            and isEnemy(plr)
            and plr.Character
            and plr.Character:FindFirstChild("HumanoidRootPart")
            and not TeleportedUsers[plr.UserId]
        then
            table.insert(candidates, plr)
        end
    end

    if #candidates == 0 then
        TeleportedUsers = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer
                and isEnemy(plr)
                and plr.Character
                and plr.Character:FindFirstChild("HumanoidRootPart")
            then
                table.insert(candidates, plr)
            end
        end
    end

    if #candidates > 0 then
        return candidates[math.random(1, #candidates)]
    end

    return nil
end

local function setTarget(plr)
    if TargetHumanoidConn then
        TargetHumanoidConn:Disconnect()
        TargetHumanoidConn = nil
    end

    CurrentTarget = plr
    NoDamageCount = 0

    if CurrentMoveTween then
        CurrentMoveTween:Cancel()
        CurrentMoveTween = nil
    end

    if not plr or not plr.Character then
        LastTargetHealth = nil
        return
    end

    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        LastTargetHealth = hum.Health
        TargetHumanoidConn = hum.HealthChanged:Connect(function(newHealth)
            if CurrentTarget ~= plr then return end

            if LastTargetHealth and newHealth < LastTargetHealth - 0.1 then
                -- có damage -> reset đếm fail
                NoDamageCount = 0
            end
            LastTargetHealth = newHealth
        end)
    else
        LastTargetHealth = nil
    end
end

local function dropTarget(reason)
    if CurrentTarget then
        TeleportedUsers[CurrentTarget.UserId] = true
    end
    CurrentTarget = nil
    NoDamageCount = 0

    if TargetHumanoidConn then
        TargetHumanoidConn:Disconnect()
        TargetHumanoidConn = nil
    end
    if CurrentMoveTween then
        CurrentMoveTween:Cancel()
        CurrentMoveTween = nil
    end

    if reason then
        print("[ZMatrix] Đổi target:", reason)
    end
end

----------------------------------------------------------------
-- AIM + BAY GIỮ 4M
----------------------------------------------------------------
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            if (not CurrentTarget)
                or (not isEnemy(CurrentTarget))
                or (not CurrentTarget.Character)
                or (not CurrentTarget.Character:FindFirstChild("HumanoidRootPart"))
            then
                local newT = getRandomEnemy()
                if newT then
                    setTarget(newT)
                else
                    return
                end
            end

            local tChar = CurrentTarget.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum  = tChar and tChar:FindFirstChildOfClass("Humanoid")

            if not tRoot or (tHum and tHum.Health <= 0) then
                dropTarget("Target chết / invalid")
                return
            end

            local dist = (root.Position - tRoot.Position).Magnitude

            -- luôn aim vào người
            root.CFrame = CFrame.new(root.Position, tRoot.Position)
            if Camera then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, tRoot.Position)
            end

            if dist < MIN_DIST or dist > MAX_DIST then
                local backDir = -tRoot.CFrame.LookVector
                local desiredPos = tRoot.Position + backDir * IDEAL_DIST + Vector3.new(0, 1.5, 0)
                local targetCf = CFrame.new(desiredPos, tRoot.Position)

                if CurrentMoveTween then
                    CurrentMoveTween:Cancel()
                end

                CurrentMoveTween = TweenService:Create(
                    root,
                    TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                    {CFrame = targetCf}
                )
                CurrentMoveTween:Play()
            end
        end)
    end
end)

----------------------------------------------------------------
-- HÀM BẤM SKILL (Z,X,C,V)
----------------------------------------------------------------
local function pressKey(keyCode)
    Vim:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.05)
    Vim:SendKeyEvent(false, keyCode, false, game)
end

local function castSkillsForTool(cat)
    local now = tick()

    for _, key in ipairs(SKILL_KEYS) do
        local cd = SKILL_COOLDOWN[key] or 2
        local last = LastSkillCast[key] or 0

        if now - last >= cd then
            -- tùy loại vũ khí m có thể custom tại đây, vd:
            -- nếu cat == "Gun" và key == Enum.KeyCode.V thì bỏ qua, ...
            pressKey(key)
            LastSkillCast[key] = now
            -- slight delay giữa skill
            task.wait(0.08)
        end
    end
end

----------------------------------------------------------------
-- AUTO ATTACK: MELEE M1, CÒN LẠI DÙNG SKILL
----------------------------------------------------------------
task.spawn(function()
    VirtualUser:CaptureController()

    while task.wait(0.2) do
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            if (not CurrentTarget)
                or (not CurrentTarget.Character)
                or (not CurrentTarget.Character:FindFirstChild("HumanoidRootPart"))
                or (not isEnemy(CurrentTarget))
            then
                return
            end

            local tChar = CurrentTarget.Character
            local tRoot = tChar:FindFirstChild("HumanoidRootPart")
            local tHum  = tChar:FindFirstChildOfClass("Humanoid")

            if not tRoot or (tHum and tHum.Health <= 0) then
                dropTarget("Target chết / invalid (attack loop)")
                return
            end

            -- chắc chắn vẫn aim vào người trước khi đánh
            root.CFrame = CFrame.new(root.Position, tRoot.Position)
            if Camera then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, tRoot.Position)
            end

            local currentTool = char:FindFirstChildOfClass("Tool")
            local category    = getToolCategory(currentTool)

            if not category then
                -- không biết loại vũ khí -> khỏi đánh
                return
            end

            if category == "Melee" then
                -- MELEE: M1 + (nếu muốn có thể thêm skill riêng)
                VirtualUser:ClickButton1(Vector2.new())
                NoDamageCount = NoDamageCount + 1
            else
                -- SWORD / FRUIT / GUN: CHỈ XÀI SKILL
                castSkillsForTool(category)
                NoDamageCount = NoDamageCount + 1
            end

            -- Nếu đánh nhiều lần mà HP không giảm -> đổi người
            if NoDamageCount >= 5 then
                dropTarget("5 lần attack không gây dmg")
            end
        end)
    end
end)