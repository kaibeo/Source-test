local Lumina = loadstring(game:HttpGet("https://raw.githubusercontent.com/ugmoddev/LuminaLibrary/refs/heads/main/LuminaLibrary.luau"))()

local Window = Lumina:CreateWindow({
    Title = "Ryzen Hub [ Hop Finder ]",
    Version = "v0.5 beta version",
    Size = UDim2.new(0, 750, 0, 480)
})

local MainTab = Window:MakeTab({ Title = "Hop Finder", Icon = "compass" })
local InfoTab = Window:MakeTab({ Title = "Info", Icon = "home" })
local SettingsTab = Window:MakeTab({ Title = "Settings", Icon = "settings" })

local MiscGroup = Window:MakeDropdownTab({ Title = "Theme" })
local ThemeTab = MiscGroup:MakeTab({ Title = "Theme Settings" })

-- ==================== THEME TAB ====================
ThemeTab:AddSection({ Title = "Presets" })

ThemeTab:AddLabel({ Text = "Choose a built-in theme" })

ThemeTab:AddDropdown({
    Title = "Theme Preset",
    Options = {
    "Dark", "Light", "Midnight", "Forest", "Emerald", "Mint", "Sage",
    "Ocean", "Sky", "DeepBlue", "Arctic", "Crimson", "Rose", "Cherry",
    "Pink", "Blush", "Violet", "Lavender", "Plum", "Sunset", "Amber",
    "Gold", "Peach", "Chocolate", "Coffee", "Cream", "PastelBlue",
    "PastelPink", "PastelGreen", "PastelPurple", "NeonBlue", "NeonGreen",
    "NeonPink", "NeonOrange", "Matrix", "Dracula", "Nord", "Solarized",
    "Gruvbox", "Paper", "Monochrome", "Silver", "Graphite", "Sakura",
    "Aurora", "Galaxy", "Candy", "Oceanic", "Desert", "Tropical", "Winter"
    },
    Default = "Dark",
    Callback = function(selected)
        Window:SetTheme(selected)
        Lumina:Notify({ Title = "Theme", Text = "Switched to " .. selected .. " theme.", Duration = 2 })
    end
})

ThemeTab:AddSection({ Title = "Custom Colors (RGB 0-255)" })

ThemeTab:AddLabel({ Text = "These only apply while the 'Custom' preset is active." })

local function AddColorSliders(tab, label, themeKey, defaultColor)
    tab:AddSection({ Title = label })
    local r, g, b = math.floor(defaultColor.R * 255), math.floor(defaultColor.G * 255), math.floor(defaultColor.B * 255)

    local function pushColor()
        Window:SetCustomColor(themeKey, Color3.fromRGB(r, g, b))
    end

    tab:AddSlider({
        Title = label .. " - Red",
        Min = 0, Max = 255, Default = r,
        Callback = function(v) r = v; pushColor() end
    })
    tab:AddSlider({
        Title = label .. " - Green",
        Min = 0, Max = 255, Default = g,
        Callback = function(v) g = v; pushColor() end
    })
    tab:AddSlider({
        Title = label .. " - Blue",
        Min = 0, Max = 255, Default = b,
        Callback = function(v) b = v; pushColor() end
    })
end

AddColorSliders(ThemeTab, "Accent", "Accent", Color3.fromRGB(85, 170, 255))
AddColorSliders(ThemeTab, "Background", "Main", Color3.fromRGB(30, 30, 35))
AddColorSliders(ThemeTab, "Sidebar", "Sidebar", Color3.fromRGB(25, 25, 30))

ThemeTab:AddSection({ Title = "Utility" })
ThemeTab:AddButton({
    Title = "Reset Custom Theme To Dark",
    Callback = function()
        Window:SetCustomColor("Main", Color3.fromRGB(30, 30, 35))
        Window:SetCustomColor("Sidebar", Color3.fromRGB(25, 25, 30))
        Window:SetCustomColor("Header", Color3.fromRGB(20, 20, 25))
        Window:SetCustomColor("Accent", Color3.fromRGB(85, 170, 255))
        Window:SetCustomColor("Element", Color3.fromRGB(40, 40, 45))
        Window:SetCustomColor("Outline", Color3.fromRGB(60, 60, 65))
        Lumina:Notify({ Title = "Theme", Text = "Custom theme reset.", Duration = 2 })
    end
})

-- ==================== HOP FINDER TAB ====================
MainTab:AddSection({ Title = "Island - Full Moon Finder" })

MainTab:AddButton({
    Title = "Full Moon",
    Callback = function()
        Hop("fullmoon")
    end
})

MainTab:AddButton({
    Title = "Mirage Island",
    Callback = function()
        Hop("mirage")
    end
})

MainTab:AddButton({
    Title = "Prehistoric Island",
    Callback = function()
        Hop("prehistoric")
    end
})

MainTab:AddButton({
    Title = "Kitsune Island",
    Callback = function()
        Hop("kitsune")
    end
})

MainTab:AddSection({ Title = "Haki Finder" })

MainTab:AddButton({
    Title = "Haki Pure Red",
    Callback = function()
        Hop("hakipurered")
    end
})

MainTab:AddButton({
    Title = "Haki Snow White",
    Callback = function()
        Hop("hakisnowwhite")
    end
})

MainTab:AddButton({
    Title = "Haki Winter Sky",
    Callback = function()
        Hop("hakiwintersky")
    end
})

MainTab:AddSection({ Title = "Sword Finder" })

MainTab:AddButton({
    Title = "Sword Shizu",
    Callback = function()
        Hop("swordshizu")
    end
})

MainTab:AddButton({
    Title = "Sword Oroshi",
    Callback = function()
        Hop("swordoroshi")
    end
})

MainTab:AddButton({
    Title = "Sword Saishi",
    Callback = function()
        Hop("swordsaishi")
    end
})

MainTab:AddSection({ Title = "Boss Finder" })

MainTab:AddButton({
    Title = "Darkbeard",
    Callback = function()
        Hop("darkbeard")
    end
})

MainTab:AddButton({
    Title = "Soul Reaper",
    Callback = function()
        Hop("soulreaper")
    end
})

MainTab:AddButton({
    Title = "Cursed Captain",
    Callback = function()
        Hop("cursedcaptain")
    end
})

MainTab:AddButton({
    Title = "rip_indra",
    Callback = function()
        Hop("ripindra")
    end
})

MainTab:AddButton({
    Title = "Tyrant of the Skies",
    Callback = function()
        Hop("tyrantoftheskies")
    end
})

MainTab:AddButton({
    Title = "Dough King",
    Callback = function()
        Hop("doughking")
    end
})

MainTab:AddSection({ Title = "Event Finder" })

MainTab:AddButton({
    Title = "Pirate Raid",
    Callback = function()
        Hop("pirateraid")
    end
})

MainTab:AddButton({
    Title = "Fruits",
    Callback = function()
        Hop("fruits")
    end
})

-- ==================== INFO TAB ====================
InfoTab:AddSection({ Title = "About" })

InfoTab:AddLabel({ Text = "Ryzen Hub - Advanced Blox Fruits Script" })

InfoTab:AddLabel({ Text = "Made by RC Team\n\nMembers:\n• Kaibeo\n• Dragon Toro\n\nDeveloped by Vietnamese Team" })

InfoTab:AddSection({ Title = "Server Information" })

InfoTab:AddButton({
    Title = "Copy Server Job-Id",
    Callback = function()
        local jobId = game.JobId ~= "" and game.JobId or "Studio"
        setclipboard(jobId)
        Lumina:Notify({ Title = "Copied", Text = "Job-Id copied to clipboard!", Duration = 3 })
    end
})

InfoTab:AddButton({
    Title = "Copy Discord Link",
    Callback = function()
        setclipboard("https://discord.gg/your-discord-link")
        Lumina:Notify({ Title = "Discord", Text = "Discord link copied to clipboard!", Duration = 3 })
    end
})

-- ==================== SETTINGS TAB ====================
SettingsTab:AddSection({ Title = "UI Configuration" })

SettingsTab:AddButton({
    Title = "Unload UI",
    Callback = function()
        Lumina:Notify({ Title = "Unloaded", Text = "Destroying UI...", Duration = 2 })
        task.wait(2)
        -- Destroy UI
    end
})

SettingsTab:AddSection({ Title = "Info" })

SettingsTab:AddLabel({
    Text = "Ryzen Hub Premium v1.6.66\nV0.5 Beta Version"
})

-- ==================== HOP FUNCTION ====================
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local API_URL = "https://dragonstorostudiohop.up.railway.app"
local Browser = ReplicatedStorage:WaitForChild("__ServerBrowser")

local function Notify(text, time)
    pcall(function()
        Lumina:Notify({
            Title = "Hop System",
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
        Notify("❌ Không thể kết nối API", 5)  
        return  
    end  
    
    local success, data = pcall(function()  
        return HttpService:JSONDecode(res.Body)  
    end)  
    
    if not success then  
        Notify("❌ Lỗi đọc dữ liệu API", 5)  
        return  
    end  
    
    local servers = data["Make By RC team"] or {}  
    
    if data.total == 0 or #servers == 0 then  
        Notify("❌ Hết Servers - Server full", 6)  
        return  
    end  
    
    Notify("✅ Tìm thấy " .. #servers .. " server", 3)  
    
    local serverQueue = {}
    for i, server in ipairs(servers) do
        local joinId = server.joinId
        if joinId and joinId ~= "" and joinId ~= game.JobId then
            table.insert(serverQueue, joinId)
        end
    end
    
    if #serverQueue == 0 then
        Notify("❌ Không có server khả dụng", 5)
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

-- ==================== FPS COUNTER ====================
local FPS = 0
local lastUpdate = tick()
local frameCount = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    
    if now - lastUpdate >= 1 then
        FPS = math.floor(frameCount / (now - lastUpdate))
        frameCount = 0
        lastUpdate = now
    end
end)

-- ==================== STARTUP NOTIFICATION ====================
Lumina:Notify({
    Title = "Ryzen Hub",
    Text = "✅ Loading Script Success v" .. _version,
    Duration = 5
})

print("🚀 Ryzen Hub loaded successfully!")
print("📊 Version: v" .. _version)
print("💡 Using Lumina UI Library")
