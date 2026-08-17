--[[
	Kaitun BF - Player Info & Item Tracker UI (v2 - Wide Layout)
	Bigger, wider (horizontal) layout: left sidebar for profile/stats,
	right side for tabs (Profile / Items).
	Place this as a LocalScript inside StarterPlayerScripts (or StarterGui)
]]

local Players = game:GetService("Players")
local Players_LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- ================= CONFIG =================
-- Edit this table to change the items you're tracking.
-- status: true = owned (green), false = missing (red)
local ITEM_LIST = {
	{name = "Dragon Trident", status = true},
	{name = "Dark Coat", status = false},
	{name = "Soul Guitar", status = false},
	{name = "Yeti Coat", status = true},
	{name = "Dough Fruit", status = false},
	{name = "Kilo Fruit", status = true},
	{name = "Buddy Sword", status = false},
	{name = "Cursed Dual Katana", status = false},
}

-- Player stats (wire these up to real values from your game/leaderstats)
local PLAYER_DATA = {
	displayName = Players_LocalPlayer.DisplayName,
	level = 2450,
	world = "World 3 - Third Sea",
	timeGame = "182h 40m",
	beli = "12.4M",
	fragments = "3,200",
}

-- ================= COLORS =================
local COL_BG        = Color3.fromRGB(22, 22, 26)
local COL_SIDEBAR   = Color3.fromRGB(26, 26, 31)
local COL_PANEL     = Color3.fromRGB(32, 32, 38)
local COL_PANEL_ALT = Color3.fromRGB(40, 40, 47)
local COL_ACCENT    = Color3.fromRGB(90, 160, 255)
local COL_ACCENT_2  = Color3.fromRGB(120, 190, 255)
local COL_TEXT      = Color3.fromRGB(238, 238, 243)
local COL_SUBTEXT   = Color3.fromRGB(165, 165, 176)
local COL_GREEN     = Color3.fromRGB(76, 209, 130)
local COL_RED       = Color3.fromRGB(235, 87, 87)
local COL_STROKE    = Color3.fromRGB(56, 56, 64)

-- ================= HELPERS =================
local function corner(inst, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = inst
	return c
end

local function stroke(inst, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or COL_STROKE
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function pad(inst, l, t, r, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l or 10)
	p.PaddingTop = UDim.new(0, t or 10)
	p.PaddingRight = UDim.new(0, r or 10)
	p.PaddingBottom = UDim.new(0, b or 10)
	p.Parent = inst
	return p
end

local function gradient(inst, c1, c2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rotation or 90
	g.Parent = inst
	return g
end

local function newLabel(props)
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextColor3 = COL_TEXT
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	for k, v in pairs(props) do
		lbl[k] = v
	end
	return lbl
end

local function countOwned()
	local owned = 0
	for _, item in ipairs(ITEM_LIST) do
		if item.status then owned += 1 end
	end
	return owned
end

-- ================= ROOT GUI =================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KaitunBF_UI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 10
screenGui.Parent = Players_LocalPlayer:WaitForChild("PlayerGui")

-- Main container (bigger, WIDE / horizontal layout)
local MAIN_W, MAIN_H = 800, 420
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(MAIN_W, MAIN_H)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = COL_BG
main.BorderSizePixel = 0
main.Active = true
main.Parent = screenGui
corner(main, 16)
stroke(main, COL_STROKE, 1)

local mainPad = 12
pad(main, mainPad, mainPad, mainPad, mainPad)

local mainLayout = Instance.new("UIListLayout")
mainLayout.FillDirection = Enum.FillDirection.Horizontal
mainLayout.Padding = UDim.new(0, 12)
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Parent = main

-- Draggable behavior (drag from the header area / whole frame)
do
	local dragging, dragStart, startPos
	local UIS = game:GetService("UserInputService")
	main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ============ TOGGLE BUTTON (show / hide the whole UI) ============
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.fromOffset(46, 46)
toggleBtn.Position = UDim2.fromOffset(20, 20)
toggleBtn.BackgroundColor3 = COL_ACCENT
toggleBtn.AutoButtonColor = false
toggleBtn.Text = "☰"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 20
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.ZIndex = 50
toggleBtn.Parent = screenGui
corner(toggleBtn, 23)
stroke(toggleBtn, COL_STROKE, 1)
gradient(toggleBtn, Color3.fromRGB(100, 170, 255), Color3.fromRGB(70, 130, 220), 90)

local uiVisible = true
local function refreshToggleLook()
	toggleBtn.Text = uiVisible and "✕" or "☰"
end
refreshToggleLook()

toggleBtn.MouseButton1Click:Connect(function()
	uiVisible = not uiVisible
	main.Visible = uiVisible
	refreshToggleLook()
end)

local CONTENT_H = MAIN_H - (mainPad * 2) -- 396
local SIDEBAR_W = 220
local GAP = 12
local CONTENT_W_OFFSET = -(SIDEBAR_W + GAP)

-- ============ LEFT SIDEBAR (Profile / Avatar / Stats) ============
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.fromOffset(SIDEBAR_W, CONTENT_H)
sidebar.BackgroundColor3 = COL_SIDEBAR
sidebar.BorderSizePixel = 0
sidebar.LayoutOrder = 1
sidebar.Parent = main
corner(sidebar, 14)
stroke(sidebar, COL_STROKE, 1)
gradient(sidebar, Color3.fromRGB(30, 30, 36), Color3.fromRGB(22, 22, 27), 100)
pad(sidebar, 14, 16, 14, 14)

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.FillDirection = Enum.FillDirection.Vertical
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.Padding = UDim.new(0, 10)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar

-- Avatar button (click to swap headshot / bust)
local avatarBtn = Instance.new("ImageButton")
avatarBtn.Name = "AvatarButton"
avatarBtn.Size = UDim2.fromOffset(88, 88)
avatarBtn.BackgroundColor3 = COL_PANEL_ALT
avatarBtn.AutoButtonColor = false
avatarBtn.Image = ""
avatarBtn.LayoutOrder = 1
avatarBtn.Parent = sidebar
corner(avatarBtn, 44) -- circular
stroke(avatarBtn, COL_ACCENT, 2)

local function loadAvatar()
	local userId = Players_LocalPlayer.UserId
	local success, result = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
	end)
	if success then
		avatarBtn.Image = result
	end
end
loadAvatar()

local showingHeadshot = true
avatarBtn.MouseButton1Click:Connect(function()
	local userId = Players_LocalPlayer.UserId
	showingHeadshot = not showingHeadshot
	local thumbType = showingHeadshot and Enum.ThumbnailType.HeadShot or Enum.ThumbnailType.AvatarBust
	local ok, result = pcall(function()
		return Players:GetUserThumbnailAsync(userId, thumbType, Enum.ThumbnailSize.Size180x180)
	end)
	if ok then
		local tween = TweenService:Create(avatarBtn, TweenInfo.new(0.12), {ImageTransparency = 1})
		tween:Play()
		tween.Completed:Wait()
		avatarBtn.Image = result
		TweenService:Create(avatarBtn, TweenInfo.new(0.12), {ImageTransparency = 0}):Play()
	end
end)

-- Name pill (centered, below avatar)
local nameBtn = Instance.new("TextButton")
nameBtn.Name = "NameButton"
nameBtn.Size = UDim2.new(1, 0, 0, 28)
nameBtn.BackgroundColor3 = COL_PANEL_ALT
nameBtn.AutoButtonColor = false
nameBtn.Text = ""
nameBtn.LayoutOrder = 2
nameBtn.Parent = sidebar
corner(nameBtn, 8)
stroke(nameBtn, COL_STROKE, 1)

local nameText = newLabel({
	Name = "NameText",
	Size = UDim2.new(1, 0, 1, 0),
	Text = PLAYER_DATA.displayName,
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = COL_TEXT,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextTruncate = Enum.TextTruncate.AtEnd,
})
nameText.Parent = nameBtn

local levelLbl = newLabel({
	Name = "Level",
	Size = UDim2.new(1, 0, 0, 18),
	Text = "Level " .. tostring(PLAYER_DATA.level),
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = COL_ACCENT_2,
	TextXAlignment = Enum.TextXAlignment.Center,
	LayoutOrder = 3,
})
levelLbl.Parent = sidebar

local worldLbl = newLabel({
	Name = "World",
	Size = UDim2.new(1, 0, 0, 16),
	Text = PLAYER_DATA.world,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = COL_SUBTEXT,
	TextXAlignment = Enum.TextXAlignment.Center,
	LayoutOrder = 4,
})
worldLbl.Parent = sidebar

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 1)
divider.BackgroundColor3 = COL_STROKE
divider.BorderSizePixel = 0
divider.LayoutOrder = 5
divider.Parent = sidebar

-- Stat rows (stacked, full width, roomy now that layout is wider)
local function sideStat(labelText, valueText, color, order)
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, 0, 0, 40)
	box.BackgroundColor3 = COL_PANEL_ALT
	box.LayoutOrder = order
	box.Parent = sidebar
	corner(box, 8)
	pad(box, 10, 4, 10, 4)

	local lbl = newLabel({
		Size = UDim2.new(1, 0, 0, 14),
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 10,
		TextColor3 = COL_SUBTEXT,
	})
	lbl.Parent = box

	local val = newLabel({
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 15),
		Text = valueText,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = color or COL_TEXT,
	})
	val.Parent = box

	return box
end

sideStat("PLAYTIME", PLAYER_DATA.timeGame, COL_SUBTEXT, 6)
sideStat("BELI", PLAYER_DATA.beli, Color3.fromRGB(255, 210, 90), 7)
sideStat("FRAGMENTS", PLAYER_DATA.fragments, Color3.fromRGB(180, 140, 255), 8)

-- ============ RIGHT SIDE (Tabs + Pages) ============
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, CONTENT_W_OFFSET, 1, 0)
content.BackgroundTransparency = 1
content.LayoutOrder = 2
content.Parent = main

local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.Padding = UDim.new(0, 10)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

-- ============ HORIZONTAL TAB MENU (Profile / Items) ============
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, 0, 0, 36)
tabBar.BackgroundColor3 = COL_PANEL
tabBar.LayoutOrder = 1
tabBar.Parent = content
corner(tabBar, 10)
stroke(tabBar, COL_STROKE, 1)
pad(tabBar, 4, 4, 4, 4)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

local tabButtons = {}
local function createTab(labelText, key, order)
	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. key
	btn.Size = UDim2.new(0.5, -2, 1, 0)
	btn.BackgroundColor3 = COL_PANEL_ALT
	btn.AutoButtonColor = false
	btn.Text = labelText
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.TextColor3 = COL_SUBTEXT
	btn.LayoutOrder = order
	btn.Parent = tabBar
	corner(btn, 7)
	tabButtons[key] = btn
	return btn
end

local tabProfile = createTab("PROFILE", "profile", 1)
local tabItems = createTab("ITEMS", "items", 2)

-- ============ PAGE CONTAINER ============
local TAB_H = 36
local pageContainer = Instance.new("Frame")
pageContainer.Name = "PageContainer"
pageContainer.Size = UDim2.new(1, 0, 1, -(TAB_H + 10))
pageContainer.BackgroundTransparency = 1
pageContainer.LayoutOrder = 2
pageContainer.Parent = content

-- ---- PROFILE PAGE ----
local profilePage = Instance.new("Frame")
profilePage.Name = "ProfilePage"
profilePage.Size = UDim2.new(1, 0, 1, 0)
profilePage.BackgroundColor3 = COL_PANEL
profilePage.Visible = true
profilePage.Parent = pageContainer
corner(profilePage, 12)
stroke(profilePage, COL_STROKE, 1)
pad(profilePage, 16, 16, 16, 16)

local profilePageLbl = newLabel({
	Size = UDim2.new(1, 0, 0, 22),
	Text = "Player Summary",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = COL_TEXT,
})
profilePageLbl.Parent = profilePage

-- Card grid: Level / World / Playtime / Beli / Fragments / Weapon Progress
local summaryGrid = Instance.new("Frame")
summaryGrid.Name = "SummaryGrid"
summaryGrid.Size = UDim2.new(1, 0, 1, -32)
summaryGrid.Position = UDim2.fromOffset(0, 32)
summaryGrid.BackgroundTransparency = 1
summaryGrid.Parent = profilePage

local summaryGridLayout = Instance.new("UIGridLayout")
summaryGridLayout.CellSize = UDim2.new(0.5, -6, 0, 72)
summaryGridLayout.CellPadding = UDim2.new(0, 12, 0, 12)
summaryGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
summaryGridLayout.Parent = summaryGrid

local function summaryCard(labelText, valueText, color, order)
	local box = Instance.new("Frame")
	box.BackgroundColor3 = COL_PANEL_ALT
	box.LayoutOrder = order
	box.Parent = summaryGrid
	corner(box, 10)
	stroke(box, COL_STROKE, 1)
	pad(box, 14, 12, 14, 12)

	local lbl = newLabel({
		Size = UDim2.new(1, 0, 0, 14),
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 10,
		TextColor3 = COL_SUBTEXT,
	})
	lbl.Parent = box

	local val = newLabel({
		Name = "Value",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 20),
		Text = valueText,
		Font = Enum.Font.GothamBold,
		TextSize = 17,
		TextColor3 = color or COL_TEXT,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	val.Parent = box

	return box
end

summaryCard("LEVEL", tostring(PLAYER_DATA.level), COL_ACCENT_2, 1)
summaryCard("WORLD", PLAYER_DATA.world, COL_TEXT, 2)
summaryCard("PLAYTIME", PLAYER_DATA.timeGame, COL_SUBTEXT, 3)
summaryCard("BELI", PLAYER_DATA.beli, Color3.fromRGB(255, 210, 90), 4)
summaryCard("FRAGMENTS", PLAYER_DATA.fragments, Color3.fromRGB(180, 140, 255), 5)

-- Weapon progress card (label + numbers + progress bar)
local progressCard = Instance.new("Frame")
progressCard.Name = "ProgressCard"
progressCard.BackgroundColor3 = COL_PANEL_ALT
progressCard.LayoutOrder = 6
progressCard.Parent = summaryGrid
corner(progressCard, 10)
stroke(progressCard, COL_STROKE, 1)
pad(progressCard, 14, 12, 14, 12)

local progressLbl = newLabel({
	Size = UDim2.new(1, -60, 0, 14),
	Text = "WEAPON PROGRESS",
	Font = Enum.Font.GothamMedium,
	TextSize = 10,
	TextColor3 = COL_SUBTEXT,
})
progressLbl.Parent = progressCard

local progressValueLbl = newLabel({
	Name = "Value",
	Size = UDim2.new(0, 60, 0, 14),
	Position = UDim2.new(1, -60, 0, 0),
	Text = countOwned() .. " / " .. #ITEM_LIST,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = COL_ACCENT_2,
	TextXAlignment = Enum.TextXAlignment.Right,
})
progressValueLbl.Parent = progressCard

local progressTrack = Instance.new("Frame")
progressTrack.Name = "Track"
progressTrack.Size = UDim2.new(1, 0, 0, 8)
progressTrack.Position = UDim2.fromOffset(0, 26)
progressTrack.BackgroundColor3 = COL_PANEL
progressTrack.BorderSizePixel = 0
progressTrack.Parent = progressCard
corner(progressTrack, 4)

local progressFill = Instance.new("Frame")
progressFill.Name = "Fill"
progressFill.Size = UDim2.new(#ITEM_LIST > 0 and (countOwned() / #ITEM_LIST) or 0, 0, 1, 0)
progressFill.BackgroundColor3 = COL_GREEN
progressFill.BorderSizePixel = 0
progressFill.Parent = progressTrack
corner(progressFill, 4)
gradient(progressFill, Color3.fromRGB(90, 220, 150), COL_GREEN, 0)

-- ---- ITEMS PAGE ----
local itemsPage = Instance.new("Frame")
itemsPage.Name = "ItemsPage"
itemsPage.Size = UDim2.new(1, 0, 1, 0)
itemsPage.BackgroundTransparency = 1
itemsPage.Visible = false
itemsPage.Parent = pageContainer

local itemsPageLayout = Instance.new("UIListLayout")
itemsPageLayout.FillDirection = Enum.FillDirection.Vertical
itemsPageLayout.Padding = UDim.new(0, 8)
itemsPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
itemsPageLayout.Parent = itemsPage

-- ============ WEAPON STATUS BAR (inside Items page) ============
local weaponBar = Instance.new("Frame")
weaponBar.Name = "WeaponStatusBar"
weaponBar.Size = UDim2.new(1, 0, 0, 32)
weaponBar.BackgroundColor3 = COL_PANEL
weaponBar.LayoutOrder = 1
weaponBar.Parent = itemsPage
corner(weaponBar, 8)
stroke(weaponBar, COL_STROKE, 1)
pad(weaponBar, 12, 0, 12, 0)

local weaponLbl = newLabel({
	Size = UDim2.new(1, 0, 1, 0),
	Text = "Weapon Progress:  " .. countOwned() .. " / " .. #ITEM_LIST .. " owned",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = COL_TEXT,
})
weaponLbl.Parent = weaponBar

local function updateProfileProgress()
	local owned = countOwned()
	progressValueLbl.Text = owned .. " / " .. #ITEM_LIST
	local pct = (#ITEM_LIST > 0) and (owned / #ITEM_LIST) or 0
	TweenService:Create(progressFill, TweenInfo.new(0.2), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
end
updateProfileProgress()

-- ============ HORIZONTAL FILTER MENU (All / Owned / Missing) ============
local filterBar = Instance.new("Frame")
filterBar.Name = "FilterBar"
filterBar.Size = UDim2.new(1, 0, 0, 28)
filterBar.BackgroundColor3 = COL_PANEL
filterBar.LayoutOrder = 2
filterBar.Parent = itemsPage
corner(filterBar, 8)
stroke(filterBar, COL_STROKE, 1)
pad(filterBar, 4, 4, 4, 4)

local filterLayout = Instance.new("UIListLayout")
filterLayout.FillDirection = Enum.FillDirection.Horizontal
filterLayout.Padding = UDim.new(0, 4)
filterLayout.SortOrder = Enum.SortOrder.LayoutOrder
filterLayout.Parent = filterBar

local filterButtons = {}
local function createFilterBtn(labelText, key, order)
	local btn = Instance.new("TextButton")
	btn.Name = "Filter_" .. key
	btn.Size = UDim2.new(0.333, -3, 1, 0)
	btn.BackgroundColor3 = COL_PANEL_ALT
	btn.AutoButtonColor = false
	btn.Text = labelText
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 11
	btn.TextColor3 = COL_SUBTEXT
	btn.LayoutOrder = order
	btn.Parent = filterBar
	corner(btn, 6)
	filterButtons[key] = btn
	return btn
end

local filterAll = createFilterBtn("ALL", "all", 1)
local filterOwned = createFilterBtn("OWNED", "owned", 2)
local filterMissing = createFilterBtn("MISSING", "missing", 3)

-- ============ ITEM LIST (2-column grid — makes use of the extra width) ============
local listContainer = Instance.new("Frame")
listContainer.Name = "ListContainer"
listContainer.Size = UDim2.new(1, 0, 1, -(32 + 28 + 16)) -- fills remaining space in itemsPage
listContainer.BackgroundColor3 = COL_PANEL
listContainer.LayoutOrder = 3
listContainer.Parent = itemsPage
corner(listContainer, 12)
stroke(listContainer, COL_STROKE, 1)
pad(listContainer, 8, 8, 8, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ItemScroll"
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = COL_ACCENT
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = listContainer

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.5, -4, 0, 36)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = scroll

local function createItemRow(item, order)
	local row = Instance.new("Frame")
	row.Name = item.name
	row.BackgroundColor3 = COL_PANEL_ALT
	row.LayoutOrder = order
	row.ClipsDescendants = true
	row.Parent = scroll
	corner(row, 8)
	pad(row, 14, 0, 10, 0)

	-- colored accent strip along the left edge (status at a glance)
	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(0, 4, 1, 0)
	accent.BorderSizePixel = 0
	accent.BackgroundColor3 = item.status and COL_GREEN or COL_RED
	accent.ZIndex = 2
	accent.Parent = row

	local nameLbl = newLabel({
		Size = UDim2.new(1, -80, 1, 0),
		Text = item.name,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = COL_TEXT,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	nameLbl.Parent = row

	-- status chip (right side) — soft tinted background + colored text, cleaner look
	local pill = Instance.new("Frame")
	pill.Name = "Pill"
	pill.Size = UDim2.fromOffset(72, 22)
	pill.Position = UDim2.new(1, -72, 0.5, -11)
	pill.BackgroundColor3 = item.status and COL_GREEN or COL_RED
	pill.BackgroundTransparency = 0.85
	pill.Parent = row
	corner(pill, 11)
	stroke(pill, item.status and COL_GREEN or COL_RED, 1)

	local pillLbl = newLabel({
		Name = "PillText",
		Size = UDim2.new(1, 0, 1, 0),
		Text = item.status and "✓  OWNED" or "✕  MISSING",
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = item.status and COL_GREEN or COL_RED,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	pillLbl.Parent = pill

	return row
end

for i, item in ipairs(ITEM_LIST) do
	local row = createItemRow(item, i)
	row:SetAttribute("Owned", item.status)
end

-- ============ TAB SWITCHING LOGIC ============
local function setActiveTab(key)
	for tKey, btn in pairs(tabButtons) do
		if tKey == key then
			btn.BackgroundColor3 = COL_ACCENT
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = COL_PANEL_ALT
			btn.TextColor3 = COL_SUBTEXT
		end
	end
	profilePage.Visible = (key == "profile")
	itemsPage.Visible = (key == "items")
end

tabProfile.MouseButton1Click:Connect(function()
	setActiveTab("profile")
end)
tabItems.MouseButton1Click:Connect(function()
	setActiveTab("items")
end)

setActiveTab("profile")

-- ============ FILTER SWITCHING LOGIC ============
local function setActiveFilter(key)
	for fKey, btn in pairs(filterButtons) do
		if fKey == key then
			btn.BackgroundColor3 = COL_ACCENT
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = COL_PANEL_ALT
			btn.TextColor3 = COL_SUBTEXT
		end
	end
	for _, row in ipairs(scroll:GetChildren()) do
		if row:IsA("Frame") then
			local owned = row:GetAttribute("Owned")
			if key == "all" then
				row.Visible = true
			elseif key == "owned" then
				row.Visible = owned == true
			elseif key == "missing" then
				row.Visible = owned == false
			end
		end
	end
end

filterAll.MouseButton1Click:Connect(function()
	setActiveFilter("all")
end)
filterOwned.MouseButton1Click:Connect(function()
	setActiveFilter("owned")
end)
filterMissing.MouseButton1Click:Connect(function()
	setActiveFilter("missing")
end)

setActiveFilter("all")

-- ============ Public API to update item status at runtime ============
local Kaitun = {}

function Kaitun.SetItemStatus(itemName, ownedBool)
	local row = scroll:FindFirstChild(itemName)
	if not row then return end
	row:SetAttribute("Owned", ownedBool)

	local color = ownedBool and COL_GREEN or COL_RED

	local accent = row:FindFirstChild("Accent")
	if accent then accent.BackgroundColor3 = color end

	local pill = row:FindFirstChild("Pill")
	if pill then
		pill.BackgroundColor3 = color
		local st = pill:FindFirstChildOfClass("UIStroke")
		if st then st.Color = color end
		local lbl = pill:FindFirstChild("PillText")
		if lbl then
			lbl.Text = ownedBool and "✓  OWNED" or "✕  MISSING"
			lbl.TextColor3 = color
		end
	end

	-- update progress labels (weapon bar + profile page)
	for _, item in ipairs(ITEM_LIST) do
		if item.name == itemName then item.status = ownedBool end
	end
	local owned = countOwned()
	weaponLbl.Text = "Weapon Progress:  " .. owned .. " / " .. #ITEM_LIST .. " owned"
	updateProfileProgress()
end

return Kaitun
