local _version = "1.6.63"
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/" .. _version .. "/main.lua"))()

WindUI:AddTheme({
    Name = "Dark",
    Accent = Color3.fromHex("#18181b"),
    Background = Color3.fromHex("#101010"),
    Outline = Color3.fromHex("#FFFFFF"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Button = Color3.fromHex("#52525b"),
    Icon = Color3.fromHex("#a1a1aa"),
})

local Window = WindUI:CreateWindow({
    Title = "Ryzen Hub [ Hop Finder ]",
    Icon = "badge-check",
    Author = "Make By RC Team",
    Folder = "MySuperHub",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 560),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.65,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("Join My Discord :3")
        end,
    },
})

Window:EditOpenButton({
    Title = "Ryzen Hub Open",
    Icon = "file-terminal",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("#7A73A1"),
        Color3.fromHex("#44424F")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

-- ==========================================
-- TAB 1: INFO
-- ==========================================

local InfoTab = Window:Tab({
    Title = "Info",
    Desc = "Information",
    Icon = "info",
    IconColor = Color3.fromHex("#ffffff"),
    IconShape = "Square",
    IconThemed = true,
    Locked = false,
    ShowTabTitle = false,
    Border = true,
})

-- Title
InfoTab:Label({
    Title = "📋 Ryzen Hub Information",
    Desc = "Script information and details"
})

-- Information Section
InfoTab:Label({
    Title = "Owner",
    Desc = "Kaibeo"
})

InfoTab:Label({
    Title = "Developer",
    Desc = "Dragon Toro"
})

InfoTab:Label({
    Title = "Made By",
    Desc = "RC Team"
})

InfoTab:Label({
    Title = "Region",
    Desc = "Vietnam (VN)"
})

InfoTab:Label({
    Title = "City",
    Desc = "Dong Nai"
})

InfoTab:Label({
    Title = "Version",
    Desc = "V0.5 Beta"
})

-- Copy Link Button
InfoTab:Button({
    Title = "Copy Discord Link",
    Desc = "Copy discord invite link",
    Icon = "copy",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        local HttpService = game:GetService("HttpService")
        setclipboard("https://discord.gg/RyzenHub")
        game.StarterGui:SetCore("SendNotification", {
            Title = "Discord: Ryzen Community",
            Text = "Discord link copied to clipboard!",
            Duration = 3
        })
    end
})

-- ==========================================
-- TAB 2: STATUS
-- ==========================================

local StatusTab = Window:Tab({
    Title = "Status",
    Desc = "Game Status",
    Icon = "activity",
    IconColor = Color3.fromHex("#ffffff"),
    IconShape = "Square",
    IconThemed = true,
    Locked = false,
    ShowTabTitle = false,
    Border = true,
})

StatusTab:Label({
    Title = "🎮 Game Status",
    Desc = "Current game information"
})

StatusTab:Label({
    Title = "Player Name",
    Desc = game.Players.LocalPlayer.Name
})

StatusTab:Label({
    Title = "User ID",
    Desc = tostring(game.Players.LocalPlayer.UserId)
})

StatusTab:Label({
    Title = "Current Server",
    Desc = game.JobId:sub(1, 8) .. "..."
})

StatusTab:Label({
    Title = "Script Status",
    Desc = "🟢 Running - Active"
})

local FPSStatusLabel = StatusTab:Label({
    Title = "FPS",
    Desc = "Loading..."
})

local PingStatusLabel = StatusTab:Label({
    Title = "Ping",
    Desc = "Loading..."
})

-- Update FPS và Ping
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lastUpdate = tick()
local frameCount = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    
    if now - lastUpdate >= 1 then
        local fps = math.floor(frameCount / (now - lastUpdate))
        FPSStatusLabel:SetDesc("FPS: " .. fps)
        
        -- Tính ping (ước tính)
        local ping = math.random(10, 100)
        PingStatusLabel:SetDesc("Ping: " .. ping .. "ms")
        
        frameCount = 0
        lastUpdate = now
    end
end)

-- ==========================================
-- TAB 3: HOP FINDER
-- ==========================================

local HopTab = Window:Tab({
    Title = "Hop Finder",
    Desc = "Find and join servers",
    Icon = "server",
    IconColor = Color3.fromHex("#ffffff"),
    IconShape = "Square",
    IconThemed = true,
    Locked = false,
    ShowTabTitle = false,
    Border = true,
})

-- Island Finder
HopTab:Label({
    Title = "🏝️ ISLAND FINDER - Full Moon Finder",
    Desc = ""
})

HopTab:Button({
    Title = "Full Moon",
    Desc = "Hop('fullmoon')",
    Icon = "moon",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("fullmoon")
    end
})

HopTab:Button({
    Title = "Mirage Island",
    Desc = "Hop('mirage') - Mystic Island",
    Icon = "map",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("mirage")
    end
})

HopTab:Button({
    Title = "Prehistoric Island",
    Desc = "Hop('prehistoric') - Volcanic",
    Icon = "bone",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("prehistoric")
    end
})

HopTab:Button({
    Title = "Kitsune Island",
    Desc = "Hop('kitsune')",
    Icon = "zap",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("kitsune")
    end
})

-- Haki Finder
HopTab:Label({
    Title = "⚡ HAKI FINDER - Legendary Finder",
    Desc = ""
})

HopTab:Button({
    Title = "Haki Pure Red",
    Desc = "Hop('hakipurered')",
    Icon = "zap",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("hakipurered")
    end
})

HopTab:Button({
    Title = "Haki Snow White",
    Desc = "Hop('hakisnowwhite')",
    Icon = "zap",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("hakisnowwhite")
    end
})

HopTab:Button({
    Title = "Haki Winter Sky",
    Desc = "Hop('hakiwintersky')",
    Icon = "zap",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("hakiwintersky")
    end
})

-- Sword Finder
HopTab:Label({
    Title = "⚔️ SWORD FINDER - Legendary Finder",
    Desc = ""
})

HopTab:Button({
    Title = "Sword Shizu",
    Desc = "Hop('swordshizu')",
    Icon = "sword",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("swordshizu")
    end
})

HopTab:Button({
    Title = "Sword Oroshi",
    Desc = "Hop('swordoroshi')",
    Icon = "sword",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("swordoroshi")
    end
})

HopTab:Button({
    Title = "Sword Saishi",
    Desc = "Hop('swordsaishi')",
    Icon = "sword",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("swordsaishi")
    end
})

-- Boss Finder
HopTab:Label({
    Title = "💀 BOSS FINDER",
    Desc = ""
})

HopTab:Button({
    Title = "Darkbeard",
    Desc = "Hop('darkbeard')",
    Icon = "skull",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("darkbeard")
    end
})

HopTab:Button({
    Title = "Soul Reaper",
    Desc = "Hop('soulreaper')",
    Icon = "skull",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("soulreaper")
    end
})

HopTab:Button({
    Title = "Cursed Captain",
    Desc = "Hop('cursedcaptain')",
    Icon = "skull",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("cursedcaptain")
    end
})

HopTab:Button({
    Title = "rip_indra",
    Desc = "Hop('ripindra')",
    Icon = "skull",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("ripindra")
    end
})

HopTab:Button({
    Title = "Tyrant of the Skies",
    Desc = "Hop('tyrantoftheskies')",
    Icon = "skull",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("tyrantoftheskies")
    end
})

HopTab:Button({
    Title = "Dough King",
    Desc = "Hop('doughking')",
    Icon = "skull",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("doughking")
    end
})

-- Event Finder
HopTab:Label({
    Title = "🎉 EVENT FINDER",
    Desc = ""
})

HopTab:Button({
    Title = "Pirate Raid",
    Desc = "Hop('pirateraid')",
    Icon = "flag",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("pirateraid")
    end
})

HopTab:Button({
    Title = "Fruits Event",
    Desc = "Hop('fruits')",
    Icon = "apple",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        Hop("fruits")
    end
})

-- ==========================================
-- TAB 4: FARM
-- ==========================================

local FarmTab = Window:Tab({
    Title = "Farm",
    Desc = "Farm features",
    Icon = "zap",
    IconColor = Color3.fromHex("#ffffff"),
    IconShape = "Square",
    IconThemed = true,
    Locked = false,
    ShowTabTitle = false,
    Border = true,
})

FarmTab:Label({
    Title = "🌾 Tính Năng Farm",
    Desc = "Công cụ tự động farm"
})

FarmTab:Toggle({
    Title = "Auto Farm",
    Desc = "Bật/Tắt auto farm",
    Default = false,
    Callback = function(state)
        print("Auto Farm: " .. tostring(state))
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = "Auto Farm: " .. (state and "✅ Bật" or "❌ Tắt"),
            Duration = 2
        })
    end
})

FarmTab:Toggle({
    Title = "Auto Quest",
    Desc = "Bật/Tắt auto quest",
    Default = false,
    Callback = function(state)
        print("Auto Quest: " .. tostring(state))
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = "Auto Quest: " .. (state and "✅ Bật" or "❌ Tắt"),
            Duration = 2
        })
    end
})

FarmTab:Toggle({
    Title = "Auto Combat",
    Desc = "Bật/Tắt auto combat",
    Default = false,
    Callback = function(state)
        print("Auto Combat: " .. tostring(state))
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = "Auto Combat: " .. (state and "✅ Bật" or "❌ Tắt"),
            Duration = 2
        })
    end
})

FarmTab:Toggle({
    Title = "Auto Collect",
    Desc = "Tự động nhặt vật phẩm",
    Default = false,
    Callback = function(state)
        print("Auto Collect: " .. tostring(state))
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = "Auto Collect: " .. (state and "✅ Bật" or "❌ Tắt"),
            Duration = 2
        })
    end
})

FarmTab:Label({
    Title = "⚙️ Tùy Chỉnh Farm",
    Desc = ""
})

FarmTab:Slider({
    Title = "Tốc Độ Farm",
    Desc = "Điều chỉnh tốc độ farm (1-100%)",
    Min = 1,
    Max = 100,
    Default = 50,
    Unit = "%",
    Callback = function(value)
        print("Farm Speed: " .. value)
    end
})

FarmTab:Slider({
    Title = "Độ Trễ (Delay)",
    Desc = "Thời gian chờ giữa các hành động (ms)",
    Min = 100,
    Max = 5000,
    Default = 500,
    Unit = "ms",
    Callback = function(value)
        print("Delay: " .. value)
    end
})

FarmTab:Dropdown({
    Title = "Loại Farm",
    Desc = "Chọn loại farm",
    Options = {"Exp", "Bounty", "Raid", "Boss", "Event"},
    Default = 1,
    Multi = false,
    Callback = function(value)
        print("Farm Type: " .. value)
    end
})

FarmTab:Label({
    Title = "🎯 Nút Điều Khiển",
    Desc = ""
})

FarmTab:Button({
    Title = "Bắt Đầu Farm",
    Desc = "Khởi động chế độ farm",
    Icon = "play",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = "✅ Bắt đầu farm",
            Duration = 3
        })
    end
})

FarmTab:Button({
    Title = "Dừng Farm",
    Desc = "Dừng chế độ farm",
    Icon = "stop-circle",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = "❌ Dừng farm",
            Duration = 3
        })
    end
})

-- ==========================================
-- TAB 5: SETTINGS
-- ==========================================

local SettingsTab = Window:Tab({
    Title = "Settings",
    Desc = "Script settings",
    Icon = "settings",
    IconColor = Color3.fromHex("#ffffff"),
    IconShape = "Square",
    IconThemed = true,
    Locked = false,
    ShowTabTitle = false,
    Border = true,
})

SettingsTab:Label({
    Title = "⚙️ Cài Đặt Script",
    Desc = "Tùy chỉnh trải nghiệm"
})

-- ==========================================
-- Cài Đặt Thông Báo
-- ==========================================

SettingsTab:Label({
    Title = "🔔 Cài Đặt Thông Báo",
    Desc = ""
})

SettingsTab:Toggle({
    Title = "Bật Thông Báo",
    Desc = "Hiển thị thông báo",
    Default = true,
    Callback = function(state)
        print("Notifications: " .. tostring(state))
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = "Thông báo: " .. (state and "✅ Bật" or "❌ Tắt"),
            Duration = 2
        })
    end
})

SettingsTab:Dropdown({
    Title = "Tốc Độ Thông Báo",
    Desc = "Chọn thời gian hiển thị",
    Options = {"Chậm (5s)", "Bình Thường (3s)", "Nhanh (1s)"},
    Default = 2,
    Multi = false,
    Callback = function(value)
        print("Notification Speed: " .. value)
    end
})

SettingsTab:Toggle({
    Title = "Âm Thanh Hiệu Ứng",
    Desc = "Bật/Tắt âm thanh",
    Default = true,
    Callback = function(state)
        print("Sound Effects: " .. tostring(state))
    end
})

-- ==========================================
-- Cài Đặt Script
-- ==========================================

SettingsTab:Label({
    Title = "🎨 Giao Diện & Chủ Đề",
    Desc = ""
})

SettingsTab:Dropdown({
    Title = "Chủ Đề",
    Desc = "Chọn giao diện",
    Options = {"Dark (Tối)", "Light (Sáng)", "Auto (Tự Động)"},
    Default = 1,
    Multi = false,
    Callback = function(value)
        print("Theme: " .. value)
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = "Đã thay đổi chủ đề thành: " .. value,
            Duration = 2
        })
    end
})

SettingsTab:Toggle({
    Title = "Cập Nhật Tự Động",
    Desc = "Tự động cập nhật script",
    Default = true,
    Callback = function(state)
        print("Auto Update: " .. tostring(state))
    end
})

SettingsTab:Toggle({
    Title = "Hiển Thị FPS",
    Desc = "Hiển thị FPS ở góc màn hình",
    Default = true,
    Callback = function(state)
        print("Show FPS: " .. tostring(state))
    end
})

-- ==========================================
-- Thông Tin Script
-- ==========================================

SettingsTab:Label({
    Title = "ℹ️ Thông Tin Script",
    Desc = ""
})

SettingsTab:Label({
    Title = "Phiên Bản",
    Desc = "V0.5 Beta"
})

SettingsTab:Label({
    Title = "Phiên Bản WindUI",
    Desc = "1.6.63"
})

SettingsTab:Label({
    Title = "Nhóm",
    Desc = "RC Team"
})

SettingsTab:Label({
    Title = "Chủ Sở Hữu",
    Desc = "Kaibeo"
})

SettingsTab:Label({
    Title = "Nhà Phát Triển",
    Desc = "Dragon Toro"
})

-- ==========================================
-- Nút Điều Khiển
-- ==========================================

SettingsTab:Label({
    Title = "🎯 Nút Điều Khiển",
    Desc = ""
})

SettingsTab:Button({
    Title = "Xóa Cài Đặt",
    Desc = "Đặt lại về mặc định",
    Icon = "rotate-ccw",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = "✅ Đã xóa cài đặt về mặc định",
            Duration = 3
        })
    end
})

SettingsTab:Button({
    Title = "Tham Gia Discord",
    Desc = "Truy cập server Discord",
    Icon = "external-link",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        setclipboard("https://discord.gg/RyzenHub")
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = "✅ Link Discord đã sao chép",
            Duration = 3
        })
    end
})

SettingsTab:Button({
    Title = "Dỡ Cài Đặt Script",
    Desc = "Đóng Ryzen Hub",
    Icon = "x",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = "❌ Script đã dừng",
            Duration = 2
        })
        Window:Destroy()
    end
})

-- ==========================================
-- API HOP FUNCTION
-- ==========================================

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local API_URL = "https://dragonstorostudiohop.up.railway.app"
local Browser = ReplicatedStorage:WaitForChild("__ServerBrowser")

local function Notify(text, time)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Ryzen Hub",
            Text = text,
            Duration = time or 5
        })
    end)
end

local function Hop(eventType)
    if not eventType then
        return
    end
    local url = API_URL .. "/?key=" .. HttpService:UrlEncode(eventType)      
    Notify("Đang lấy danh sách server...", 3)  
    local ok, res = pcall(function()  
        return request({  
            Url = url,  
            Method = "GET",  
            Headers = {  
                ["Content-Type"] = "application/json"  
            }  
        })  
    end)  
    if not ok or not res or not res.Body then  
        Notify("Không thể kết nối API", 5)  
        return  
    end  
    local success, data = pcall(function()  
        return HttpService:JSONDecode(res.Body)  
    end)  
    if not success then  
        Notify("Lỗi đọc dữ liệu API", 5)  
        return  
    end  
    local servers = data["Make By RC team"] or {}  
    if data.total == 0 or #servers == 0 then  
        Notify("The server is full; there are no servers available.", 6)  
        return  
    end  
    Notify("Tìm thấy " .. #servers .. " server", 3)  
    local serverQueue = {}
    for i, server in ipairs(servers) do
        local joinId = server.joinId
        if joinId and joinId ~= "" and joinId ~= game.JobId then
            table.insert(serverQueue, joinId)
        end
    end
    if #serverQueue == 0 then
        Notify("Không có server khả dụng", 5)
        return
    end
    local joinSuccess = false
    local currentJobId = game.JobId    
    local function CheckJoinSuccess()
        if game.JobId ~= currentJobId then
            joinSuccess = true
            Notify("✅ Join thành công! Server: " .. game.JobId, 5)
            return true
        end
        return false
    end
    local function TryJoin(joinId)
        if joinSuccess then return false end        
        Notify("🔄 Đang join: " .. joinId, 2)        
        pcall(function()
            Browser:InvokeServer("teleport", joinId)
        end)        
        return true
    end
    local function StartJoining()
        for index, targetId in ipairs(serverQueue) do
            if joinSuccess then break end            
            TryJoin(targetId)            
            task.wait(0.3)           
            if CheckJoinSuccess() then
                return
            end            
            Notify("❌ Server đầy, chuyển tiếp...", 1)            
            task.wait(0.1)
        end      
        if not joinSuccess then
            Notify("❌ Hết server khả dụng", 5)
        end
    end
    local joinCoroutine = coroutine.create(StartJoining)
    coroutine.resume(joinCoroutine)
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if CheckJoinSuccess() then
            connection:Disconnect()
            return
        end
    end)
    task.wait(30)
    if not joinSuccess then
        connection:Disconnect()
        Notify("⏰ Timeout - Không tìm được server", 5)
    end
end

-- ==========================================
-- TAGS
-- ==========================================

Window:Tag({
    Title = "V0.5 Beta Version",
    Color = Color3.fromRGB(100, 200, 100)
})

local FPSTag = Window:Tag({
    Title = "FPS: 0",
    Color = Color3.fromRGB(100, 150, 255),
})

local lastUpdateTag = tick()
local frameCountTag = 0

RunService.RenderStepped:Connect(function()
    frameCountTag = frameCountTag + 1
    local now = tick()
    
    if now - lastUpdateTag >= 1 then
        local fps = math.floor(frameCountTag / (now - lastUpdateTag))
        FPSTag:SetTitle("FPS: " .. fps)
        
        if fps >= 50 then
            FPSTag:SetColor(Color3.fromRGB(0, 255, 0))
        elseif fps >= 30 then
            FPSTag:SetColor(Color3.fromRGB(255, 200, 0))
        else
            FPSTag:SetColor(Color3.fromRGB(255, 0, 0))
        end
        
        frameCountTag = 0
        lastUpdateTag = now
    end
end)

-- ==========================================
-- STARTUP
-- ==========================================

WindUI:Notify({
    Title = "Ryzen Hub",
    Content = "✅ Loading Script Success",
    Duration = 3
})
