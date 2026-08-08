--[[
    Ryzen Config v3.4
    Made by Kaibeo | Discord: https://discord.gg/azuKW4VNJP

    Tính năng:
    - Loading toàn màn hình (progress bar giả lập)
    - Notify "Loading thành công" kèm thanh thời gian ~3s
    - Nút bật/tắt UI (ON/OFF) nổi góc màn hình
    - Menu ngang nhỏ (tabs)
    - Avatar Roblox + tên người chơi
    - Hiển thị FPS / Ping realtime
    - Ngày giờ + dòng chữ chạy ngang (marquee) hiện notify

    Cách dùng: Paste vào LocalScript (StarterGui / StarterPlayerScripts)
    hoặc chạy qua executor.
]]

local Players          = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Stats             = game:GetService("Stats")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local CONFIG = {
    Name = "Ryzen Config",
    Version = "v3.4",
    Author = "Kaibeo",
    Discord = "https://discord.gg/azuKW4VNJP",
    AccentColor = Color3.fromRGB(88, 101, 242), -- xanh discord-ish
    BgColor = Color3.fromRGB(18, 18, 22),
    PanelColor = Color3.fromRGB(24, 24, 30),
    LoadingTime = 3, -- giây
}

------------------------------------------------------------
-- ROOT GUI
------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RyzenConfig_" .. HttpService:GenerateGUID(false)
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game:GetService("CoreGui")
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

------------------------------------------------------------
-- UTIL: bo góc, viền, gradient, tween
------------------------------------------------------------
local function corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = inst
    return c
end

local function stroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or CONFIG.AccentColor
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.4
    s.Parent = inst
    return s
end

local function tween(inst, props, time, style, dir)
    local t = TweenService:Create(inst, TweenInfo.new(
        time or 0.25,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    ), props)
    t:Play()
    return t
end

------------------------------------------------------------
-- ================= 1. LOADING SCREEN =================
------------------------------------------------------------
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.new(1, 0, 1, 0)
LoadingFrame.BackgroundColor3 = CONFIG.BgColor
LoadingFrame.BorderSizePixel = 0
LoadingFrame.ZIndex = 100
LoadingFrame.Parent = ScreenGui

-- Logo / tiêu đề chính giữa
local LogoLabel = Instance.new("TextLabel")
LogoLabel.Name = "LogoLabel"
LogoLabel.BackgroundTransparency = 1
LogoLabel.Size = UDim2.new(0, 500, 0, 60)
LogoLabel.Position = UDim2.new(0.5, -250, 0.5, -90)
LogoLabel.Text = CONFIG.Name
LogoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoLabel.Font = Enum.Font.GothamBlack
LogoLabel.TextSize = 40
LogoLabel.ZIndex = 101
LogoLabel.Parent = LoadingFrame

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Name = "VersionLabel"
VersionLabel.BackgroundTransparency = 1
VersionLabel.Size = UDim2.new(0, 500, 0, 24)
VersionLabel.Position = UDim2.new(0.5, -250, 0.5, -34)
VersionLabel.Text = CONFIG.Version .. "  •  made by " .. CONFIG.Author
VersionLabel.TextColor3 = CONFIG.AccentColor
VersionLabel.Font = Enum.Font.GothamMedium
VersionLabel.TextSize = 16
VersionLabel.ZIndex = 101
VersionLabel.Parent = LoadingFrame

-- Thanh loading (progress bar)
local BarBg = Instance.new("Frame")
BarBg.Name = "BarBg"
BarBg.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
BarBg.Size = UDim2.new(0, 400, 0, 10)
BarBg.Position = UDim2.new(0.5, -200, 0.5, 10)
BarBg.BorderSizePixel = 0
BarBg.ZIndex = 101
BarBg.Parent = LoadingFrame
corner(BarBg, 5)

local BarFill = Instance.new("Frame")
BarFill.Name = "BarFill"
BarFill.BackgroundColor3 = CONFIG.AccentColor
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BorderSizePixel = 0
BarFill.ZIndex = 102
BarFill.Parent = BarBg
corner(BarFill, 5)

local PercentLabel = Instance.new("TextLabel")
PercentLabel.BackgroundTransparency = 1
PercentLabel.Size = UDim2.new(0, 400, 0, 20)
PercentLabel.Position = UDim2.new(0.5, -200, 0.5, 26)
PercentLabel.Text = "Đang tải... 0%"
PercentLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
PercentLabel.Font = Enum.Font.Gotham
PercentLabel.TextSize = 14
PercentLabel.ZIndex = 101
PercentLabel.Parent = LoadingFrame

local DiscordLabel = Instance.new("TextLabel")
DiscordLabel.BackgroundTransparency = 1
DiscordLabel.Size = UDim2.new(0, 500, 0, 20)
DiscordLabel.Position = UDim2.new(0.5, -250, 1, -50)
DiscordLabel.Text = "Discord: " .. CONFIG.Discord
DiscordLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
DiscordLabel.Font = Enum.Font.Gotham
DiscordLabel.TextSize = 13
DiscordLabel.ZIndex = 101
DiscordLabel.Parent = LoadingFrame

------------------------------------------------------------
-- ================ 2. NOTIFY (toast) SYSTEM ================
------------------------------------------------------------
local NotifyHolder = Instance.new("Frame")
NotifyHolder.Name = "NotifyHolder"
NotifyHolder.BackgroundTransparency = 1
NotifyHolder.Size = UDim2.new(0, 320, 1, 0)
NotifyHolder.Position = UDim2.new(1, -335, 0, 0)
NotifyHolder.ZIndex = 200
NotifyHolder.Parent = ScreenGui

local NotifyList = Instance.new("UIListLayout")
NotifyList.Padding = UDim.new(0, 8)
NotifyList.VerticalAlignment = Enum.VerticalAlignment.Top
NotifyList.HorizontalAlignment = Enum.HorizontalAlignment.Center
NotifyList.SortOrder = Enum.SortOrder.LayoutOrder
NotifyList.Parent = NotifyHolder

local function CreateNotify(title, text, duration)
    duration = duration or 3

    local Toast = Instance.new("Frame")
    Toast.Name = "Toast"
    Toast.BackgroundColor3 = CONFIG.PanelColor
    Toast.Size = UDim2.new(0, 300, 0, 64)
    Toast.Position = UDim2.new(0, 20, 0, 20) -- sẽ được UIListLayout xử lý vị trí
    Toast.BackgroundTransparency = 1
    Toast.ZIndex = 201
    Toast.Parent = NotifyHolder
    corner(Toast, 8)
    stroke(Toast, CONFIG.AccentColor, 1, 0.6)

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(0, 4, 1, 0)
    Bar.BackgroundColor3 = CONFIG.AccentColor
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 202
    Bar.BackgroundTransparency = 1
    Bar.Parent = Toast
    corner(Bar, 8)

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position = UDim2.new(0, 16, 0, 8)
    TitleLbl.Size = UDim2.new(1, -28, 0, 18)
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = title
    TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.TextSize = 14
    TitleLbl.TextTransparency = 1
    TitleLbl.ZIndex = 202
    TitleLbl.Parent = Toast

    local TextLbl = Instance.new("TextLabel")
    TextLbl.BackgroundTransparency = 1
    TextLbl.Position = UDim2.new(0, 16, 0, 26)
    TextLbl.Size = UDim2.new(1, -28, 0, 18)
    TextLbl.Font = Enum.Font.Gotham
    TextLbl.Text = text
    TextLbl.TextColor3 = Color3.fromRGB(190, 190, 200)
    TextLbl.TextXAlignment = Enum.TextXAlignment.Left
    TextLbl.TextSize = 12
    TextLbl.TextTransparency = 1
    TextLbl.ZIndex = 202
    TextLbl.Parent = Toast

    -- thanh thời gian (progress countdown) ở đáy toast
    local TimeBarBg = Instance.new("Frame")
    TimeBarBg.Size = UDim2.new(1, -16, 0, 3)
    TimeBarBg.Position = UDim2.new(0, 8, 1, -8)
    TimeBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    TimeBarBg.BackgroundTransparency = 1
    TimeBarBg.BorderSizePixel = 0
    TimeBarBg.ZIndex = 202
    TimeBarBg.Parent = Toast
    corner(TimeBarBg, 2)

    local TimeBarFill = Instance.new("Frame")
    TimeBarFill.Size = UDim2.new(1, 0, 1, 0)
    TimeBarFill.BackgroundColor3 = CONFIG.AccentColor
    TimeBarFill.BackgroundTransparency = 1
    TimeBarFill.BorderSizePixel = 0
    TimeBarFill.ZIndex = 203
    TimeBarFill.Parent = TimeBarBg
    corner(TimeBarFill, 2)

    -- fade in
    tween(Toast, {BackgroundTransparency = 0}, 0.25)
    tween(Bar, {BackgroundTransparency = 0}, 0.25)
    tween(TitleLbl, {TextTransparency = 0}, 0.25)
    tween(TextLbl, {TextTransparency = 0}, 0.25)
    tween(TimeBarBg, {BackgroundTransparency = 0.3}, 0.25)
    tween(TimeBarFill, {BackgroundTransparency = 0}, 0.25)

    tween(TimeBarFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        tween(Toast, {BackgroundTransparency = 1}, 0.3)
        tween(Bar, {BackgroundTransparency = 1}, 0.3)
        tween(TitleLbl, {TextTransparency = 1}, 0.3)
        tween(TextLbl, {TextTransparency = 1}, 0.3)
        tween(TimeBarBg, {BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        Toast:Destroy()
    end)
end

------------------------------------------------------------
-- ================ 3. MAIN UI (khung chính) ================
------------------------------------------------------------
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 560, 0, 360)
Main.Position = UDim2.new(0.5, -280, 0.5, -180)
Main.BackgroundColor3 = CONFIG.BgColor
Main.BorderSizePixel = 0
Main.Visible = false -- ẩn cho tới khi loading xong
Main.ZIndex = 10
Main.Parent = ScreenGui
corner(Main, 10)
stroke(Main, Color3.fromRGB(45, 45, 55), 1, 0.3)

------------------------------------------------------------
-- 3.1 TOP BAR: avatar + tên + fps/ping + ngày giờ
------------------------------------------------------------
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 52)
TopBar.BackgroundColor3 = CONFIG.PanelColor
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 11
TopBar.Parent = Main
corner(TopBar, 10)

-- che góc dưới bo tròn thừa
local TopBarMask = Instance.new("Frame")
TopBarMask.Size = UDim2.new(1, 0, 0, 12)
TopBarMask.Position = UDim2.new(0, 0, 1, -12)
TopBarMask.BackgroundColor3 = CONFIG.PanelColor
TopBarMask.BorderSizePixel = 0
TopBarMask.ZIndex = 11
TopBarMask.Parent = TopBar

-- Avatar
local AvatarFrame = Instance.new("ImageLabel")
AvatarFrame.Name = "AvatarFrame"
AvatarFrame.Size = UDim2.new(0, 36, 0, 36)
AvatarFrame.Position = UDim2.new(0, 10, 0.5, -18)
AvatarFrame.BackgroundColor3 = Color3.fromRGB(40,40,48)
AvatarFrame.ZIndex = 12
AvatarFrame.Parent = TopBar
corner(AvatarFrame, 18)
stroke(AvatarFrame, CONFIG.AccentColor, 1.5, 0.2)

local userId = LocalPlayer.UserId
local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size100x100
local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
AvatarFrame.Image = content

local NameLabel = Instance.new("TextLabel")
NameLabel.BackgroundTransparency = 1
NameLabel.Position = UDim2.new(0, 56, 0, 6)
NameLabel.Size = UDim2.new(0, 200, 0, 18)
NameLabel.Font = Enum.Font.GothamBold
NameLabel.Text = LocalPlayer.DisplayName
NameLabel.TextColor3 = Color3.fromRGB(255,255,255)
NameLabel.TextXAlignment = Enum.TextXAlignment.Left
NameLabel.TextSize = 14
NameLabel.ZIndex = 12
NameLabel.Parent = TopBar

local UserNameLabel = Instance.new("TextLabel")
UserNameLabel.BackgroundTransparency = 1
UserNameLabel.Position = UDim2.new(0, 56, 0, 24)
UserNameLabel.Size = UDim2.new(0, 200, 0, 16)
UserNameLabel.Font = Enum.Font.Gotham
UserNameLabel.Text = "@" .. LocalPlayer.Name
UserNameLabel.TextColor3 = Color3.fromRGB(150,150,160)
UserNameLabel.TextXAlignment = Enum.TextXAlignment.Left
UserNameLabel.TextSize = 11
UserNameLabel.ZIndex = 12
UserNameLabel.Parent = TopBar

-- FPS / Ping
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Name = "StatsLabel"
StatsLabel.BackgroundTransparency = 1
StatsLabel.Position = UDim2.new(1, -190, 0, 6)
StatsLabel.Size = UDim2.new(0, 130, 0, 18)
StatsLabel.Font = Enum.Font.GothamMedium
StatsLabel.Text = "FPS: 0 | Ping: 0ms"
StatsLabel.TextColor3 = Color3.fromRGB(120, 220, 140)
StatsLabel.TextXAlignment = Enum.TextXAlignment.Right
StatsLabel.TextSize = 12
StatsLabel.ZIndex = 12
StatsLabel.Parent = TopBar

-- Ngày giờ
local ClockLabel = Instance.new("TextLabel")
ClockLabel.Name = "ClockLabel"
ClockLabel.BackgroundTransparency = 1
ClockLabel.Position = UDim2.new(1, -190, 0, 24)
ClockLabel.Size = UDim2.new(0, 130, 0, 16)
ClockLabel.Font = Enum.Font.Gotham
ClockLabel.Text = os.date("%d/%m/%Y  %H:%M:%S")
ClockLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
ClockLabel.TextXAlignment = Enum.TextXAlignment.Right
ClockLabel.TextSize = 11
ClockLabel.ZIndex = 12
ClockLabel.Parent = TopBar

------------------------------------------------------------
-- 3.2 MENU NGANG (tabs nhỏ)
------------------------------------------------------------
local MenuBar = Instance.new("Frame")
MenuBar.Name = "MenuBar"
MenuBar.Size = UDim2.new(1, -20, 0, 30)
MenuBar.Position = UDim2.new(0, 10, 0, 58)
MenuBar.BackgroundColor3 = CONFIG.PanelColor
MenuBar.BorderSizePixel = 0
MenuBar.ZIndex = 11
MenuBar.Parent = Main
corner(MenuBar, 8)

local MenuLayout = Instance.new("UIListLayout")
MenuLayout.FillDirection = Enum.FillDirection.Horizontal
MenuLayout.Padding = UDim.new(0, 4)
MenuLayout.VerticalAlignment = Enum.VerticalAlignment.Center
MenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
MenuLayout.Parent = MenuBar

local MenuPadding = Instance.new("UIPadding")
MenuPadding.PaddingLeft = UDim.new(0, 6)
MenuPadding.PaddingTop = UDim.new(0, 3)
MenuPadding.Parent = MenuBar

local tabNames = {"Combat", "Visual", "Player", "Misc", "Config"}
local tabButtons = {}
local ContentPages = {}

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -20, 1, -160)
ContentArea.Position = UDim2.new(0, 10, 0, 96)
ContentArea.BackgroundColor3 = CONFIG.PanelColor
ContentArea.BorderSizePixel = 0
ContentArea.ZIndex = 11
ContentArea.Parent = Main
corner(ContentArea, 8)

local function selectTab(name)
    for tName, btn in pairs(tabButtons) do
        local active = tName == name
        tween(btn, {BackgroundColor3 = active and CONFIG.AccentColor or CONFIG.PanelColor}, 0.15)
        btn.TextLabel.TextColor3 = active and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,160)
    end
    for pName, page in pairs(ContentPages) do
        page.Visible = pName == name
    end
end

for i, tabName in ipairs(tabNames) do
    local Btn = Instance.new("TextButton")
    Btn.Name = tabName
    Btn.Size = UDim2.new(0, 90, 1, -6)
    Btn.BackgroundColor3 = CONFIG.PanelColor
    Btn.AutoButtonColor = false
    Btn.Text = ""
    Btn.ZIndex = 12
    Btn.LayoutOrder = i
    Btn.Parent = MenuBar
    corner(Btn, 6)

    local Lbl = Instance.new("TextLabel")
    Lbl.Name = "TextLabel"
    Lbl.BackgroundTransparency = 1
    Lbl.Size = UDim2.new(1, 0, 1, 0)
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.Text = tabName
    Lbl.TextColor3 = Color3.fromRGB(150, 150, 160)
    Lbl.TextSize = 12
    Lbl.ZIndex = 13
    Lbl.Parent = Btn

    Btn.TextLabel = Lbl
    tabButtons[tabName] = Btn

    local Page = Instance.new("Frame")
    Page.Name = tabName .. "Page"
    Page.Size = UDim2.new(1, -16, 1, -16)
    Page.Position = UDim2.new(0, 8, 0, 8)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ZIndex = 12
    Page.Parent = ContentArea

    local PageLabel = Instance.new("TextLabel")
    PageLabel.BackgroundTransparency = 1
    PageLabel.Size = UDim2.new(1, 0, 0, 20)
    PageLabel.Font = Enum.Font.GothamBold
    PageLabel.Text = tabName .. " Settings"
    PageLabel.TextColor3 = Color3.fromRGB(255,255,255)
    PageLabel.TextXAlignment = Enum.TextXAlignment.Left
    PageLabel.TextSize = 14
    PageLabel.ZIndex = 13
    PageLabel.Parent = Page

    ContentPages[tabName] = Page

    Btn.MouseButton1Click:Connect(function()
        selectTab(tabName)
    end)
end

selectTab(tabNames[1])

------------------------------------------------------------
-- 3.3 NGÀY GIỜ + NOTIFY CHẠY NGANG (marquee) ở đáy Main
------------------------------------------------------------
local Marquee = Instance.new("Frame")
Marquee.Name = "Marquee"
Marquee.Size = UDim2.new(1, -20, 0, 26)
Marquee.Position = UDim2.new(0, 10, 1, -34)
Marquee.BackgroundColor3 = CONFIG.PanelColor
Marquee.BorderSizePixel = 0
Marquee.ClipsDescendants = true
Marquee.ZIndex = 11
Marquee.Parent = Main
corner(Marquee, 6)

local MarqueeText = Instance.new("TextLabel")
MarqueeText.Name = "MarqueeText"
MarqueeText.BackgroundTransparency = 1
MarqueeText.Size = UDim2.new(0, 1000, 1, 0)
MarqueeText.Position = UDim2.new(0, 0, 0, 0)
MarqueeText.Font = Enum.Font.GothamMedium
MarqueeText.Text = ("        %s %s by %s   |   Server Discord: %s   |   %s        "):format(
    CONFIG.Name, CONFIG.Version, CONFIG.Author, CONFIG.Discord, os.date("%d/%m/%Y %H:%M:%S")
)
MarqueeText.TextColor3 = CONFIG.AccentColor
MarqueeText.TextSize = 13
MarqueeText.TextXAlignment = Enum.TextXAlignment.Left
MarqueeText.ZIndex = 12
MarqueeText.Parent = Marquee

-- chạy chữ ngang liên tục
task.spawn(function()
    while Marquee.Parent do
        local textWidth = MarqueeText.TextBounds.X
        MarqueeText.Position = UDim2.new(0, Marquee.AbsoluteSize.X, 0, 0)
        local dist = textWidth + Marquee.AbsoluteSize.X
        local speed = 90 -- px/giây
        local dur = dist / speed
        local tw = TweenService:Create(MarqueeText, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
            Position = UDim2.new(0, -textWidth, 0, 0)
        })
        tw:Play()
        tw.Completed:Wait()
    end
end)

------------------------------------------------------------
-- 3.4 NÚT ĐÓNG (X) trên TopBar
------------------------------------------------------------
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -36, 0, 13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.TextColor3 = Color3.fromRGB(220, 100, 100)
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 12
CloseBtn.Parent = TopBar
corner(CloseBtn, 13)

------------------------------------------------------------
-- ============= 4. NÚT TOGGLE UI (ON / OFF) =============
------------------------------------------------------------
local ToggleHolder = Instance.new("Frame")
ToggleHolder.Name = "ToggleHolder"
ToggleHolder.Size = UDim2.new(0, 90, 0, 34)
ToggleHolder.Position = UDim2.new(0, 20, 0, 20)
ToggleHolder.BackgroundColor3 = CONFIG.PanelColor
ToggleHolder.BorderSizePixel = 0
ToggleHolder.ZIndex = 50
ToggleHolder.Visible = false -- hiện sau khi load xong
ToggleHolder.Parent = ScreenGui
corner(ToggleHolder, 17)
stroke(ToggleHolder, CONFIG.AccentColor, 1, 0.3)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Text = ""
ToggleBtn.ZIndex = 51
ToggleBtn.Parent = ToggleHolder

local ToggleDot = Instance.new("Frame")
ToggleDot.Size = UDim2.new(0, 26, 0, 26)
ToggleDot.Position = UDim2.new(0, 4, 0.5, -13)
ToggleDot.BackgroundColor3 = CONFIG.AccentColor
ToggleDot.ZIndex = 52
ToggleDot.Parent = ToggleHolder
corner(ToggleDot, 13)

local ToggleLabel = Instance.new("TextLabel")
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Size = UDim2.new(1, -34, 1, 0)
ToggleLabel.Position = UDim2.new(0, 34, 0, 0)
ToggleLabel.Font = Enum.Font.GothamBold
ToggleLabel.Text = "ON"
ToggleLabel.TextColor3 = Color3.fromRGB(255,255,255)
ToggleLabel.TextSize = 13
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ToggleLabel.ZIndex = 52
ToggleLabel.Parent = ToggleHolder

local uiVisible = true
local function setUIState(state)
    uiVisible = state
    if state then
        tween(ToggleDot, {Position = UDim2.new(0, 4, 0.5, -13)}, 0.2)
        tween(ToggleHolder, {BackgroundColor3 = CONFIG.PanelColor}, 0.2)
        ToggleLabel.Text = "ON"
        Main.Visible = true
    else
        tween(ToggleDot, {Position = UDim2.new(1, -30, 0.5, -13)}, 0.2)
        tween(ToggleHolder, {BackgroundColor3 = Color3.fromRGB(50, 20, 20)}, 0.2)
        ToggleLabel.Text = "OFF"
        Main.Visible = false
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    setUIState(not uiVisible)
end)

CloseBtn.MouseButton1Click:Connect(function()
    setUIState(false)
end)

------------------------------------------------------------
-- Kéo thả UI chính (drag) từ TopBar
------------------------------------------------------------
do
    local dragging, dragStart, startPos
    local UserInputService = game:GetService("UserInputService")

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

------------------------------------------------------------
-- ============= 5. FPS / PING / CLOCK UPDATE LOOP =============
------------------------------------------------------------
do
    local frameCount = 0
    local lastCheck = tick()
    local currentFPS = 0

    RunService.RenderStepped:Connect(function()
        frameCount += 1
        local now = tick()
        if now - lastCheck >= 1 then
            currentFPS = frameCount
            frameCount = 0
            lastCheck = now
        end
    end)

    task.spawn(function()
        while true do
            local ping = 0
            local ok, result = pcall(function()
                return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            if ok then ping = math.floor(result) end

            StatsLabel.Text = string.format("FPS: %d | Ping: %dms", currentFPS, ping)

            -- màu theo hiệu năng
            if currentFPS >= 50 then
                StatsLabel.TextColor3 = Color3.fromRGB(120, 220, 140)
            elseif currentFPS >= 25 then
                StatsLabel.TextColor3 = Color3.fromRGB(230, 200, 100)
            else
                StatsLabel.TextColor3 = Color3.fromRGB(230, 100, 100)
            end

            ClockLabel.Text = os.date("%d/%m/%Y  %H:%M:%S")

            task.wait(1)
        end
    end)
end

------------------------------------------------------------
-- ============= 6. LOADING SEQUENCE =============
------------------------------------------------------------
task.spawn(function()
    local steps = {
        {0.15, "Đang khởi tạo..."},
        {0.35, "Đang tải cấu hình..."},
        {0.60, "Đang kết nối server..."},
        {0.85, "Đang chuẩn bị giao diện..."},
        {1.00, "Hoàn tất!"},
    }

    local elapsed = 0
    for _, step in ipairs(steps) do
        local target, text = step[1], step[2]
        PercentLabel.Text = text .. " " .. math.floor(target * 100) .. "%"
        tween(BarFill, {Size = UDim2.new(target, 0, 1, 0)}, CONFIG.LoadingTime / #steps, Enum.EasingStyle.Quad)
        task.wait(CONFIG.LoadingTime / #steps)
    end

    -- ẩn màn hình loading
    tween(LoadingFrame, {BackgroundTransparency = 1}, 0.4)
    tween(LogoLabel, {TextTransparency = 1}, 0.3)
    tween(VersionLabel, {TextTransparency = 1}, 0.3)
    tween(PercentLabel, {TextTransparency = 1}, 0.3)
    tween(DiscordLabel, {TextTransparency = 1}, 0.3)
    tween(BarBg, {BackgroundTransparency = 1}, 0.3)
    tween(BarFill, {BackgroundTransparency = 1}, 0.3)
    task.wait(0.45)
    LoadingFrame.Visible = false

    -- hiện UI chính + nút toggle
    Main.Visible = true
    ToggleHolder.Visible = true

    -- notify loading thành công, thanh thời gian 3s
    CreateNotify("Loading thành công", "Ryzen Config " .. CONFIG.Version .. " đã sẵn sàng!", 3)
end)

print("[Ryzen Config] UI Loaded - v" .. CONFIG.Version .. " by " .. CONFIG.Author)
