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

-- Tab 1
local tab1 = Window:CreateTab({
    Title = "info",
    Icon = "info"
})

-- Tab 2
local tab2 = Window:CreateTab({
    Title = "Status",
    Icon = "activity"
})

-- Tab 3
local tab3 = Window:CreateTab({
    Title = "Hop Finder",
    Icon = "server"
})

-- Tab 4
local tab4 = Window:CreateTab({
    Title = "Farm",
    Icon = "shovel"
})

-- Tab 5
local tab5 = Window:CreateTab({
    Title = "Setting",
    Icon = "settings"
})

tab1:CreateButton({
    Title = "Copy Discord Link",
    Callback = function()
        setclipboard("https://discord.gg/your-discord-link")
        print("Discord link copied!")
    end
})

tab1:CreateLabel({
    Title = "Ryzen Hub",
    Text = "Advanced Blox Fruits Script developed by Vietnamese team"
})

tab1:CreateLabel({
    Title = "About",
    Text = "Made by RC Team\n\nMembers:\nKaibeo\nDragon toro\n\nThis script is created and developed by Vietnamese developers"
})

-- Button Hop
tab3:CreateLabel({
    Title = "Island - Full Moon Finder",
    Text = ""
})

tab3:CreateButton({
    Title = "Full Moon",
    Callback = function()
        Hop("fullmoon")
    end
})

tab3:CreateButton({
    Title = "Mirage Island",
    Callback = function()
        Hop("mirage")
    end
})

tab3:CreateButton({
    Title = "Prehistoric Island",
    Callback = function()
        Hop("prehistoric")
    end
})

tab3:CreateButton({
    Title = "Kitsune Island",
    Callback = function()
        Hop("kitsune")
    end
})

-- Haki Finder
tab3:CreateLabel({
    Title = "Haki Finder",
    Text = ""
})

tab3:CreateButton({
    Title = "Haki Pure Red",
    Callback = function()
        Hop("hakipurered")
    end
})

tab3:CreateButton({
    Title = "Haki Snow White",
    Callback = function()
        Hop("hakisnowwhite")
    end
})

tab3:CreateButton({
    Title = "Haki Winter Sky",
    Callback = function()
        Hop("hakiwintersky")
    end
})

-- Sword Finder
tab3:CreateLabel({
    Title = "Sword Finder",
    Text = ""
})

tab3:CreateButton({
    Title = "Sword Shizu",
    Callback = function()
        Hop("swordshizu")
    end
})

tab3:CreateButton({
    Title = "Sword Oroshi",
    Callback = function()
        Hop("swordoroshi")
    end
})

tab3:CreateButton({
    Title = "Sword Saishi",
    Callback = function()
        Hop("swordsaishi")
    end
})

-- Boss Finder
tab3:CreateLabel({
    Title = "Boss Finder",
    Text = ""
})

tab3:CreateButton({
    Title = "Darkbeard",
    Callback = function()
        Hop("darkbeard")
    end
})

tab3:CreateButton({
    Title = "Soul Reaper",
    Callback = function()
        Hop("soulreaper")
    end
})

tab3:CreateButton({
    Title = "Cursed Captain",
    Callback = function()
        Hop("cursedcaptain")
    end
})

tab3:CreateButton({
    Title = "rip_indra",
    Callback = function()
        Hop("ripindra")
    end
})

tab3:CreateButton({
    Title = "Tyrant of the Skies",
    Callback = function()
        Hop("tyrantoftheskies")
    end
})

tab3:CreateButton({
    Title = "Dough King",
    Callback = function()
        Hop("doughking")
    end
})

-- Event Finder
tab3:CreateLabel({
    Title = "Event Finder",
    Text = ""
})

tab3:CreateButton({
    Title = "Pirate Raid",
    Callback = function()
        Hop("pirateraid")
    end
})

tab3:CreateButton({
    Title = "Fruits",
    Callback = function()
        Hop("fruits")
    end
})

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local API_URL = "https://dragonstorostudiohop.up.railway.app"
local Browser = ReplicatedStorage:WaitForChild("__ServerBrowser")
local function Notify(text, time)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Api Hop Servers",
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
        Notify("The server is full; there are no servers available.\nHết Servers", 6)  
        return  
    end  
    Notify("Tìm thấy "..#servers.." server", 3)  
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
                return -- Thoát ngay khi join thành công
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

Window:Tag({
    Title = "V0.5 Beta Vesion",
    Color = Color3.fromRGB(100, 200, 100)
})
-- your tag
local FPSTag = Window:Tag({
    Title = "FPS: 0",
    Color = Color3.fromRGB(100, 150, 255),
})
 
local RunService = game:GetService("RunService")
local lastUpdate = tick()
local frameCount = 0
 
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    
    if now - lastUpdate >= 1 then
        local fps = math.floor(frameCount / (now - lastUpdate))
        FPSTag:SetTitle("FPS: " .. fps)
        
        if fps >= 50 then
            FPSTag:SetColor(Color3.fromRGB(0, 255, 0)) -- Green
        elseif fps >= 30 then
            FPSTag:SetColor(Color3.fromRGB(255, 200, 0)) -- Yellow
        else
            FPSTag:SetColor(Color3.fromRGB(255, 0, 0)) -- Red
        end
        
        
        frameCount = 0
        lastUpdate = now
    end
end)

WindUI:Notify({
    Title = "Ryzen Hub",
    Content = "Loading Script Success",
    Duration = 3
})