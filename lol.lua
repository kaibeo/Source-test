-- // ZMATRIX: ESP + AIM + GIỮ KHOẢNG CÁCH 4–5M + AUTO M1 + ĐỔI TARGET NẾU KHÔNG GÂY DMG
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local VirtualUser  = game:GetService("VirtualUser")
local Workspace    = game:GetService("Workspace")

local LocalPlayer  = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

math.randomseed(tick())

-- LƯU NGƯỜI ĐÃ TỪNG THỬ (UserId)
local TeleportedUsers   = {}  -- [UserId] = true
local ESPData           = {}  -- [Player] = {Char=..., Humanoid=..., Billboard=..., Label=...}

local CurrentTarget      = nil
local TargetHumanoidConn = nil
local LastTargetHealth   = nil
local NoDamageM1Count    = 0

-- THAM SỐ KHOẢNG CÁCH
local MIN_DIST   = 4      -- gần nhất 4 studs
local MAX_DIST   = 5      -- xa nhất 5 studs
local IDEAL_DIST = 4.5    -- cố gắng giữ ~4.5 studs

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------
local function addESPToCharacter(plr, char)
    if not char or not plr or plr == LocalPlayer then return end

    -- Xoá ESP cũ nếu có
    local oldHL = char:FindFirstChild("ZMatrix_ESP")
    if oldHL then oldHL:Destroy() end

    local oldBB = char:FindFirstChild("ZMatrix_ESP_BB")
    if oldBB then oldBB:Destroy() end

    -- Highlight viền vàng
    local hl = Instance.new("Highlight")
    hl.Name = "ZMatrix_ESP"
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
    hl.Adornee = char
    hl.Parent = char

    -- Billboard (tên + khoảng cách + HP)
    local adorneePart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not adorneePart then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "ZMatrix_ESP_BB"
    bb.Size = UDim2.new(0, 200, 0, 60)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = adorneePart
    bb.Parent = char

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Text = plr.Name
    label.Parent = bb

    local humanoid = char:FindFirstChildOfClass("Humanoid")

    ESPData[plr] = {
        Char = char,
        Humanoid = humanoid,
        Billboard = bb,
        Label = label,
    }
end

local function setupESPForPlayer(plr)
    if plr == LocalPlayer then return end

    if plr.Character then
        addESPToCharacter(plr, plr.Character)
    end

    plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        addESPToCharacter(plr, char)
    end)
end

for _, plr in pairs(Players:GetPlayers()) do
    setupESPForPlayer(plr)
end

Players.PlayerAdded:Connect(function(plr)
    setupESPForPlayer(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    ESPData[plr] = nil
    TeleportedUsers[plr.UserId] = nil
    if CurrentTarget == plr then
        CurrentTarget = nil
        NoDamageM1Count = 0
        if TargetHumanoidConn then
            TargetHumanoidConn:Disconnect()
            TargetHumanoidConn = nil
        end
    end
end)

----------------------------------------------------------------
-- TARGET / RANDOM PLAYER
----------------------------------------------------------------
local function getRandomPlayer()
    local candidates = {}

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer
            and plr.Character
            and plr.Character:FindFirstChild("HumanoidRootPart")
            and not TeleportedUsers[plr.UserId]
        then
            table.insert(candidates, plr)
        end
    end

    -- Hết người mới -> reset list, quay vòng lại
    if #candidates == 0 then
        TeleportedUsers = {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer
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
    NoDamageM1Count = 0

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
                -- Có damage -> reset số lần fail
                NoDamageM1Count = 0
            end
            LastTargetHealth = newHealth
        end)
    else
        LastTargetHealth = nil
    end
end

----------------------------------------------------------------
-- UPDATE ESP TEXT
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for plr, data in pairs(ESPData) do
        local char = data.Char
        if not plr or not char or not char.Parent then
            ESPData[plr] = nil
        else
            local humanoid = data.Humanoid
            if not humanoid or not humanoid.Parent then
                humanoid = char:FindFirstChildOfClass("Humanoid")
                data.Humanoid = humanoid
            end

            local targetRoot = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
            if targetRoot and data.Label then
                local dist = 0
                if myRoot then
                    dist = (myRoot.Position - targetRoot.Position).Magnitude
                end

                local hp, maxHp = 0, 0
                if humanoid then
                    hp = humanoid.Health
                    maxHp = humanoid.MaxHealth
                end

                -- Target hiện tại màu đỏ
                if CurrentTarget == plr then
                    data.Label.TextColor3 = Color3.fromRGB(255, 0, 0)
                else
                    data.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                end

                data.Label.Text = string.format(
                    "%s\n[%.0f] studs\nHP: %.0f / %.0f",
                    plr.Name,
                    dist,
                    hp,
                    maxHp
                )
            end
        end
    end
end)

----------------------------------------------------------------
-- LOOP GIỮ KHOẢNG CÁCH 4–5M + AIM
----------------------------------------------------------------
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end

            -- Chưa có target / target hỏng -> tìm target mới
            if (not CurrentTarget)
                or (not CurrentTarget.Character)
                or (not CurrentTarget.Character:FindFirstChild("HumanoidRootPart"))
            then
                local newTarget = getRandomPlayer()
                if newTarget then
                    setTarget(newTarget)
                else
                    return
                end
            end

            local targetChar = CurrentTarget.Character
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            local targetHum  = targetChar and targetChar:FindFirstChildOfClass("Humanoid")

            if not targetRoot or (targetHum and targetHum.Health <= 0) then
                if CurrentTarget then
                    TeleportedUsers[CurrentTarget.UserId] = true -- đánh dấu đã thử
                end
                CurrentTarget = nil
                NoDamageM1Count = 0
                if TargetHumanoidConn then
                    TargetHumanoidConn:Disconnect()
                    TargetHumanoidConn = nil
                end
                return
            end

            local dist = (myRoot.Position - targetRoot.Position).Magnitude

            if dist < MIN_DIST or dist > MAX_DIST then
                -- Đứng sau lưng target, cách IDEAL_DIST
                local backDir = -targetRoot.CFrame.LookVector
                local desiredPos = targetRoot.Position + backDir * IDEAL_DIST + Vector3.new(0, 1.5, 0)

                myRoot.CFrame = CFrame.new(desiredPos, targetRoot.Position)
            else
                -- Đã trong khoảng 4–5m -> chỉ xoay nhìn target
                myRoot.CFrame = CFrame.new(myRoot.Position, targetRoot.Position)
            end

            -- Camera cũng aim theo target
            if Camera then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetRoot.Position)
            end
        end)
    end
end)

----------------------------------------------------------------
-- AUTO M1 + ĐỔI TARGET NẾU 5 LẦN KHÔNG GÂY DMG
----------------------------------------------------------------
task.spawn(function()
    VirtualUser:CaptureController()

    while task.wait(0.25) do -- chỉnh tốc độ M1 ở đây
        pcall(function()
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end

            if (not CurrentTarget)
                or (not CurrentTarget.Character)
                or (not CurrentTarget.Character:FindFirstChild("HumanoidRootPart"))
            then
                return
            end

            local targetChar = CurrentTarget.Character
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local targetHum  = targetChar:FindFirstChildOfClass("Humanoid")

            if not targetRoot or (targetHum and targetHum.Health <= 0) then
                if CurrentTarget then
                    TeleportedUsers[CurrentTarget.UserId] = true
                end
                CurrentTarget = nil
                NoDamageM1Count = 0
                if TargetHumanoidConn then
                    TargetHumanoidConn:Disconnect()
                    TargetHumanoidConn = nil
                end
                return
            end

            -- Đảm bảo đang nhìn vào target trước khi đánh
            myRoot.CFrame = CFrame.new(myRoot.Position, targetRoot.Position)
            if Camera then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetRoot.Position)
            end

            -- M1
            VirtualUser:ClickButton1(Vector2.new())
            NoDamageM1Count = NoDamageM1Count + 1

            -- 5 lần M1 liên tiếp mà không gây dmg (HealthChanged không reset) -> đổi target
            if NoDamageM1Count >= 5 then
                print("[ZMatrix] M1 5 lần không gây dmg -> đổi target khác")
                if CurrentTarget then
                    TeleportedUsers[CurrentTarget.UserId] = true
                end
                CurrentTarget = nil
                NoDamageM1Count = 0
                if TargetHumanoidConn then
                    TargetHumanoidConn:Disconnect()
                    TargetHumanoidConn = nil
                end
            end
        end)
    end
end)