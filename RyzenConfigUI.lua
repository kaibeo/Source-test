--[[
    RYZEN CONFIG UI [Banana Kaitun] v3.1 - HORIZONTAL BAR
    Made by Kaibeo | Server: discord.gg/fdyw76rTuD
    Đặt Script này là LocalScript bên trong StarterGui

    Thanh info ngang, mỏng, gọn:
    - Avatar, FPS, Ping, Giờ, Ngày, Playtime (thời gian chơi từ lúc vào server)
    - Ticker chữ chạy ngang
    - Loading screen animation
    - Nút bật/tắt UI (mở/ẩn thanh chính)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local joinTime = os.clock() -- mốc để tính playtime

-- ===================== COLORS =====================
local COL_BG0    = Color3.fromRGB(10, 10, 11)
local COL_BG1    = Color3.fromRGB(19, 19, 21)
local COL_BG2    = Color3.fromRGB(28, 28, 31)
local COL_LINE   = Color3.fromRGB(42, 42, 46)
local COL_RED    = Color3.fromRGB(224, 38, 63)
local COL_REDDIM = Color3.fromRGB(122, 21, 34)
local COL_TXT    = Color3.fromRGB(232, 230, 227)
local COL_DIM    = Color3.fromRGB(138, 138, 144)
local COL_GREEN  = Color3.fromRGB(61, 220, 132)
local COL_YELLOW = Color3.fromRGB(255, 200, 60)

-- ===================== ROOT GUI =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RyzenConfigUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COL_LINE
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

-- ===================== LOADING SCREEN =====================
local loader = Instance.new("Frame")
loader.Name = "Loader"
loader.Size = UDim2.fromScale(1, 1)
loader.BackgroundColor3 = COL_BG0
loader.BorderSizePixel = 0
loader.ZIndex = 100
loader.Parent = screenGui

local loaderGradient = Instance.new("UIGradient")
loaderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 4, 7)),
    ColorSequenceKeypoint.new(0.5, COL_BG0),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 6, 7)),
})
loaderGradient.Rotation = 90
loaderGradient.Parent = loader

local glowRing = Instance.new("Frame")
glowRing.AnchorPoint = Vector2.new(0.5, 0.5)
glowRing.Position = UDim2.new(0.5, 0, 0.4, 0)
glowRing.Size = UDim2.fromOffset(120, 120)
glowRing.BackgroundColor3 = COL_RED
glowRing.BackgroundTransparency = 0.9
glowRing.ZIndex = 100
glowRing.Parent = loader
corner(glowRing, 60)

local brandMark = Instance.new("TextLabel")
brandMark.BackgroundTransparency = 1
brandMark.Size = UDim2.new(1, 0, 0, 20)
brandMark.Position = UDim2.new(0, 0, 0.32, 0)
brandMark.Text = "C O N F I G   S Y S T E M"
brandMark.TextColor3 = COL_RED
brandMark.Font = Enum.Font.GothamBold
brandMark.TextSize = 13
brandMark.ZIndex = 101
brandMark.Parent = loader

local brandTitle = Instance.new("TextLabel")
brandTitle.BackgroundTransparency = 1
brandTitle.Size = UDim2.new(1, 0, 0, 60)
brandTitle.Position = UDim2.new(0, 0, 0.37, 0)
brandTitle.Text = "RYZEN CONFIG"
brandTitle.TextColor3 = COL_TXT
brandTitle.Font = Enum.Font.GothamBlack
brandTitle.TextSize = 40
brandTitle.ZIndex = 101
brandTitle.Parent = loader

local brandSub = Instance.new("TextLabel")
brandSub.BackgroundTransparency = 1
brandSub.Size = UDim2.new(1, 0, 0, 24)
brandSub.Position = UDim2.new(0, 0, 0.49, 0)
brandSub.Text = "[ BANANA KAITUN ]"
brandSub.TextColor3 = COL_DIM
brandSub.Font = Enum.Font.GothamBold
brandSub.TextSize = 16
brandSub.ZIndex = 101
brandSub.Parent = loader

local barTrack = Instance.new("Frame")
barTrack.Size = UDim2.new(0, 340, 0, 6)
barTrack.Position = UDim2.new(0.5, -170, 0.58, 0)
barTrack.BackgroundColor3 = COL_BG2
barTrack.BorderSizePixel = 0
barTrack.ZIndex = 101
barTrack.Parent = loader
corner(barTrack, 4)
stroke(barTrack, COL_LINE, 1)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = COL_RED
barFill.BorderSizePixel = 0
barFill.ZIndex = 102
barFill.Parent = barTrack
corner(barFill, 4)

local barGlow = Instance.new("UIGradient")
barGlow.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COL_REDDIM),
    ColorSequenceKeypoint.new(1, COL_RED),
})
barGlow.Parent = barFill

local statusMsg = Instance.new("TextLabel")
statusMsg.BackgroundTransparency = 1
statusMsg.Size = UDim2.new(0, 250, 0, 18)
statusMsg.Position = UDim2.new(0.5, -170, 0.61, 6)
statusMsg.TextXAlignment = Enum.TextXAlignment.Left
statusMsg.Text = "Đang khởi tạo module..."
statusMsg.TextColor3 = COL_DIM
statusMsg.Font = Enum.Font.Gotham
statusMsg.TextSize = 12
statusMsg.ZIndex = 101
statusMsg.Parent = loader

local statusPct = Instance.new("TextLabel")
statusPct.BackgroundTransparency = 1
statusPct.Size = UDim2.new(0, 80, 0, 18)
statusPct.Position = UDim2.new(0.5, 90, 0.61, 6)
statusPct.TextXAlignment = Enum.TextXAlignment.Right
statusPct.Text = "0%"
statusPct.TextColor3 = COL_RED
statusPct.Font = Enum.Font.GothamBold
statusPct.TextSize = 12
statusPct.ZIndex = 101
statusPct.Parent = loader

local verLabel = Instance.new("TextLabel")
verLabel.BackgroundTransparency = 1
verLabel.Size = UDim2.new(1, 0, 0, 18)
verLabel.Position = UDim2.new(0, 0, 0.92, 0)
verLabel.Text = "RYZEN CONFIG v3.1 — MADE BY KAIBEO"
verLabel.TextColor3 = COL_DIM
verLabel.Font = Enum.Font.Gotham
verLabel.TextSize = 11
verLabel.ZIndex = 101
verLabel.Parent = loader

local doneBadge = Instance.new("Frame")
doneBadge.AnchorPoint = Vector2.new(0.5, 0.5)
doneBadge.Position = UDim2.new(0.5, 0, 0.4, 0)
doneBadge.Size = UDim2.fromOffset(0, 0)
doneBadge.BackgroundColor3 = COL_GREEN
doneBadge.BackgroundTransparency = 1
doneBadge.ZIndex = 103
doneBadge.Parent = loader
corner(doneBadge, 40)

local doneCheck = Instance.new("TextLabel")
doneCheck.BackgroundTransparency = 1
doneCheck.Size = UDim2.fromScale(1, 1)
doneCheck.Text = "✓"
doneCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
doneCheck.TextTransparency = 1
doneCheck.Font = Enum.Font.GothamBlack
doneCheck.TextSize = 36
doneCheck.ZIndex = 104
doneCheck.Parent = doneBadge

-- ===================== MAIN BAR (HORIZONTAL, WIDE & THIN) =====================
local BAR_WIDTH = 860
local BAR_HEIGHT = 64

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(BAR_WIDTH, BAR_HEIGHT)
main.Position = UDim2.new(0.5, -BAR_WIDTH/2, 0, 20)
main.BackgroundColor3 = COL_BG1
main.BorderSizePixel = 0
main.Visible = false
main.ClipsDescendants = true
main.Parent = screenGui
corner(main, 14)
stroke(main, COL_LINE, 1)

-- Draggable
do
    local dragging, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- accent line trên cùng
local topAccent = Instance.new("Frame")
topAccent.Size = UDim2.new(1, 0, 0, 2)
topAccent.BackgroundColor3 = COL_RED
topAccent.BorderSizePixel = 0
topAccent.Parent = main

local topAccentGrad = Instance.new("UIGradient")
topAccentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COL_REDDIM),
    ColorSequenceKeypoint.new(0.5, COL_RED),
    ColorSequenceKeypoint.new(1, COL_REDDIM),
})
topAccentGrad.Parent = topAccent

-- content row layout ngang
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -16, 1, -6)
content.Position = UDim2.new(0, 8, 0, 4)
content.BackgroundTransparency = 1
content.Parent = main

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
rowLayout.Padding = UDim.new(0, 8)
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Parent = content

-- ===== Avatar + name block =====
local profileBlock = Instance.new("Frame")
profileBlock.Size = UDim2.fromOffset(150, 52)
profileBlock.BackgroundTransparency = 1
profileBlock.LayoutOrder = 1
profileBlock.Parent = content

local avatarImg = Instance.new("ImageLabel")
avatarImg.Size = UDim2.fromOffset(40, 40)
avatarImg.Position = UDim2.new(0, 0, 0.5, -20)
avatarImg.BackgroundColor3 = COL_BG2
local ok, thumb = pcall(function()
    return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
end)
avatarImg.Image = ok and thumb or ""
avatarImg.Parent = profileBlock
corner(avatarImg, 20)
stroke(avatarImg, COL_REDDIM, 2)

local nameLbl = Instance.new("TextLabel")
nameLbl.BackgroundTransparency = 1
nameLbl.Size = UDim2.new(0, 100, 0, 16)
nameLbl.Position = UDim2.new(0, 48, 0, 8)
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.Text = player.DisplayName
nameLbl.TextColor3 = COL_TXT
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextSize = 13
nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
nameLbl.Parent = profileBlock

local userLbl = Instance.new("TextLabel")
userLbl.BackgroundTransparency = 1
userLbl.Size = UDim2.new(0, 100, 0, 14)
userLbl.Position = UDim2.new(0, 48, 0, 26)
userLbl.TextXAlignment = Enum.TextXAlignment.Left
userLbl.Text = "@" .. player.Name
userLbl.TextColor3 = COL_DIM
userLbl.Font = Enum.Font.Gotham
userLbl.TextSize = 11
userLbl.TextTruncate = Enum.TextTruncate.AtEnd
userLbl.Parent = profileBlock

-- divider
local function makeDivider(order)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(0, 1, 1, -12)
    d.BackgroundColor3 = COL_LINE
    d.BorderSizePixel = 0
    d.LayoutOrder = order
    d.Parent = content
    return d
end
makeDivider(2)

-- ===== Compact stat pill =====
local function makeStatPill(order, icon, label)
    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(96, 52)
    pill.BackgroundColor3 = COL_BG2
    pill.LayoutOrder = order
    pill.Parent = content
    corner(pill, 10)
    stroke(pill, COL_LINE, 1)

    local iconLbl = Instance.new("TextLabel")
    iconLbl.BackgroundTransparency = 1
    iconLbl.Size = UDim2.fromOffset(20, 20)
    iconLbl.Position = UDim2.new(0, 8, 0, 8)
    iconLbl.Text = icon
    iconLbl.TextColor3 = COL_RED
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.TextSize = 13
    iconLbl.Parent = pill

    local capLbl = Instance.new("TextLabel")
    capLbl.BackgroundTransparency = 1
    capLbl.Size = UDim2.new(1, -32, 0, 12)
    capLbl.Position = UDim2.new(0, 30, 0, 8)
    capLbl.TextXAlignment = Enum.TextXAlignment.Left
    capLbl.Text = label
    capLbl.TextColor3 = COL_DIM
    capLbl.Font = Enum.Font.Gotham
    capLbl.TextSize = 9
    capLbl.Parent = pill

    local valLbl = Instance.new("TextLabel")
    valLbl.BackgroundTransparency = 1
    valLbl.Size = UDim2.new(1, -16, 0, 18)
    valLbl.Position = UDim2.new(0, 8, 0, 26)
    valLbl.TextXAlignment = Enum.TextXAlignment.Left
    valLbl.Text = "--"
    valLbl.TextColor3 = COL_TXT
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.Parent = pill

    return valLbl
end

local fpsVal      = makeStatPill(3, "⚡", "FPS")
local pingVal     = makeStatPill(4, "📶", "PING")
local clockTime   = makeStatPill(5, "🕒", "GIỜ")
local clockDate   = makeStatPill(6, "📅", "NGÀY")
local playtimeVal = makeStatPill(7, "⏱", "PLAYTIME")

makeDivider(8)

-- ===== Network status (compact) =====
local netBlock = Instance.new("Frame")
netBlock.Size = UDim2.fromOffset(140, 52)
netBlock.BackgroundTransparency = 1
netBlock.LayoutOrder = 9
netBlock.Parent = content

local netDot = Instance.new("Frame")
netDot.Size = UDim2.fromOffset(8, 8)
netDot.Position = UDim2.new(0, 2, 0, 10)
netDot.BackgroundColor3 = COL_GREEN
netDot.Parent = netBlock
corner(netDot, 4)

local netTitle = Instance.new("TextLabel")
netTitle.BackgroundTransparency = 1
netTitle.Size = UDim2.new(1, -18, 0, 14)
netTitle.Position = UDim2.new(0, 18, 0, 4)
netTitle.TextXAlignment = Enum.TextXAlignment.Left
netTitle.Text = "Kết nối"
netTitle.TextColor3 = COL_TXT
netTitle.Font = Enum.Font.GothamBold
netTitle.TextSize = 11
netTitle.Parent = netBlock

local netVal = Instance.new("TextLabel")
netVal.BackgroundTransparency = 1
netVal.Size = UDim2.new(1, -18, 0, 13)
netVal.Position = UDim2.new(0, 18, 0, 20)
netVal.TextXAlignment = Enum.TextXAlignment.Left
netVal.Text = "Đang kiểm tra..."
netVal.TextColor3 = COL_DIM
netVal.Font = Enum.Font.Gotham
netVal.TextSize = 10
netVal.Parent = netBlock

-- ===== Ticker nhỏ bên dưới avatar block, chạy full width mỏng dưới cùng bar (optional strip) =====
local tickerFrame = Instance.new("Frame")
tickerFrame.Size = UDim2.new(1, 0, 0, 16)
tickerFrame.Position = UDim2.new(0, 0, 1, -16)
tickerFrame.BackgroundColor3 = Color3.fromRGB(15, 5, 7)
tickerFrame.BorderSizePixel = 0
tickerFrame.ClipsDescendants = true
tickerFrame.ZIndex = 2
tickerFrame.Parent = main

local tickerText = Instance.new("TextLabel")
tickerText.BackgroundTransparency = 1
tickerText.Size = UDim2.new(0, 900, 1, 0)
tickerText.Position = UDim2.new(0, BAR_WIDTH, 0, 0)
tickerText.Text = "🎮 Config make by Kaibeo   •   Server: discord.gg/fdyw76rTuD   •   RYZEN CONFIG v3.1 [Banana Kaitun]   •   "
tickerText.TextColor3 = COL_DIM
tickerText.Font = Enum.Font.Gotham
tickerText.TextSize = 10
tickerText.TextXAlignment = Enum.TextXAlignment.Left
tickerText.ZIndex = 2
tickerText.Parent = tickerFrame

-- adjust content height to leave room for ticker strip
content.Size = UDim2.new(1, -16, 1, -22)

-- ===================== TOGGLE BUTTON =====================
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Text = ""
toggleBtn.Size = UDim2.fromOffset(40, 40)
toggleBtn.Position = UDim2.new(0, 20, 0, 20)
toggleBtn.BackgroundColor3 = COL_BG1
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 50
toggleBtn.Visible = false
toggleBtn.Parent = screenGui
corner(toggleBtn, 10)
local toggleStroke = stroke(toggleBtn, COL_RED, 1.5)

local toggleGradient = Instance.new("UIGradient")
toggleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 10, 12)),
    ColorSequenceKeypoint.new(1, COL_BG1),
})
toggleGradient.Rotation = 90
toggleGradient.Parent = toggleBtn

local toggleIcon = Instance.new("TextLabel")
toggleIcon.BackgroundTransparency = 1
toggleIcon.Size = UDim2.fromScale(1, 1)
toggleIcon.Text = "⌁"
toggleIcon.TextColor3 = COL_RED
toggleIcon.Font = Enum.Font.GothamBlack
toggleIcon.TextSize = 20
toggleIcon.ZIndex = 51
toggleIcon.Parent = toggleBtn

toggleBtn.MouseEnter:Connect(function()
    TweenService:Create(toggleStroke, TweenInfo.new(0.15), {Thickness = 2}):Play()
    TweenService:Create(toggleIcon, TweenInfo.new(0.15), {TextSize = 22}):Play()
end)
toggleBtn.MouseLeave:Connect(function()
    TweenService:Create(toggleStroke, TweenInfo.new(0.15), {Thickness = 1.5}):Play()
    TweenService:Create(toggleIcon, TweenInfo.new(0.15), {TextSize = 20}):Play()
end)

do
    local dragging, dragStart, startPos
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = toggleBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    toggleBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local uiOpen = true
local function setOpen(open)
    uiOpen = open
    main.Visible = open
end

toggleBtn.MouseButton1Click:Connect(function()
    setOpen(not uiOpen)
end)

-- ===================== LOADING SEQUENCE =====================
local loadSteps = {
    {0.15, "Đang khởi tạo module..."},
    {0.35, "Đang tải giao diện..."},
    {0.60, "Đang kết nối máy chủ..."},
    {0.85, "Đang đồng bộ dữ liệu..."},
    {1.00, "Hoàn tất!"},
}

task.spawn(function()
    for _, step in ipairs(loadSteps) do
        local pct, msg = step[1], step[2]
        statusMsg.Text = msg
        TweenService:Create(barFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
        local elapsed = 0
        while elapsed < 0.35 do
            local dt = task.wait()
            elapsed += dt
            statusPct.Text = math.floor((tonumber(statusPct.Text:gsub("%%","")) or 0) + (pct*100 - (tonumber(statusPct.Text:gsub("%%","")) or 0)) * 0.3) .. "%"
        end
        statusPct.Text = math.floor(pct * 100) .. "%"
        task.wait(0.15)
    end

    -- done badge pop
    TweenService:Create(doneBadge, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(80, 80), BackgroundTransparency = 0}):Play()
    TweenService:Create(doneCheck, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    task.wait(0.6)

    -- fade out loader
    local fadeTargets = {brandMark, brandTitle, brandSub, statusMsg, statusPct, verLabel, glowRing}
    for _, obj in ipairs(fadeTargets) do
        TweenService:Create(obj, TweenInfo.new(0.3), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
    end
    TweenService:Create(doneBadge, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(doneCheck, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(barTrack, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(barFill, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()

    task.wait(0.35)
    TweenService:Create(loader, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    task.wait(0.4)
    loader.Visible = false

    main.Visible = true
    main.Size = UDim2.fromOffset(BAR_WIDTH, 0)
    main.Position = UDim2.new(0.5, -BAR_WIDTH/2, 0, 20)
    TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(BAR_WIDTH, BAR_HEIGHT)}):Play()

    toggleBtn.Visible = true
end)

-- ===================== LIVE UPDATES =====================
-- FPS
local frameCount, fpsTimer = 0, 0
RunService.RenderStepped:Connect(function(dt)
    frameCount += 1
    fpsTimer += dt
    if fpsTimer >= 0.5 then
        local fps = math.floor(frameCount / fpsTimer)
        fpsVal.Text = tostring(fps)
        fpsVal.TextColor3 = fps >= 50 and COL_GREEN or (fps >= 30 and COL_YELLOW or COL_RED)
        frameCount, fpsTimer = 0, 0
    end
end)

-- PING + Clock + Date + Playtime
task.spawn(function()
    while true do
        -- Ping
        local ok2, pingMs = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if ok2 and pingMs then
            local ping = math.floor(pingMs)
            pingVal.Text = ping .. "ms"
            pingVal.TextColor3 = ping <= 80 and COL_GREEN or (ping <= 150 and COL_YELLOW or COL_RED)
        end

        -- Clock (giờ hệ thống máy)
        local t = os.date("*t")
        clockTime.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
        clockDate.Text = string.format("%02d/%02d/%04d", t.day, t.month, t.year)

        -- Playtime (thời gian chơi từ lúc vào server)
        local elapsedSec = math.floor(os.clock() - joinTime)
        local h = math.floor(elapsedSec / 3600)
        local m = math.floor((elapsedSec % 3600) / 60)
        local s = elapsedSec % 60
        if h > 0 then
            playtimeVal.Text = string.format("%dh%02dm", h, m)
        else
            playtimeVal.Text = string.format("%02dm%02ds", m, s)
        end

        -- Network status
        local connected = game:IsLoaded()
        if connected then
            netDot.BackgroundColor3 = COL_GREEN
            netVal.Text = "Ổn định"
            netVal.TextColor3 = COL_DIM
        else
            netDot.BackgroundColor3 = COL_YELLOW
            netVal.Text = "Đang tải..."
            netVal.TextColor3 = COL_YELLOW
        end

        task.wait(1)
    end
end)

-- Ticker scroll loop
task.spawn(function()
    while true do
        local textWidth = tickerText.AbsoluteSize.X
        tickerText.Position = UDim2.new(0, BAR_WIDTH, 0, 0)
        local tween = TweenService:Create(tickerText, TweenInfo.new(14, Enum.EasingStyle.Linear), {Position = UDim2.new(0, -textWidth, 0, 0)})
        tween:Play()
        tween.Completed:Wait()
    end
end)
