-- ============================================
-- 🍎 FRUIT FARM COMPLETE V2
-- Auto Tween + Collect + Store + Server Hop
-- ============================================

-- ============================================
-- SERVICES & VARIABLES
-- ============================================

local plr = game.Players.LocalPlayer
local Character = plr.Character
local Root = plr.Character.HumanoidRootPart
local replicated = game:GetService("ReplicatedStorage")
local TW = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- Config
local Sec = 0.1
local API_URL = "https://dragonstorosudiohop.up.railway.app"
local CHECK_INTERVAL = 5 -- Check fruit mỗi 5 giây
local AUTO_HOP = true -- Tự động hop nếu không tìm được fruit

-- State Variables
local _G_TwFruits = false
local _G_InstanceF = false
local _G_StoreF = false
local FruitFound = true
local LastFruitCheckTime = 0

-- ============================================
-- NOTIFICATION SYSTEM
-- ============================================

local function Notify(title, text, duration)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title or "🍎 Fruit Farm",
            Text = text or "",
            Duration = duration or 5
        })
    end)
end

-- ============================================
-- SERVER HOP API
-- ============================================

local function Hop(eventType)
    if not eventType then
        return
    end
    
    local url = API_URL .. "/?key=" .. HttpService:UrlEncode(eventType)      
    Notify("🔄 Server Hop", "Đang lấy danh sách server...", 3)  
    
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
        Notify("❌ Lỗi Hop", "Không thể kết nối API", 5)  
        return  
    end  
    
    local success, data = pcall(function()  
        return HttpService:JSONDecode(res.Body)  
    end)  
    
    if not success then  
        Notify("❌ Lỗi Hop", "Lỗi đọc dữ liệu API", 5)  
        return  
    end  
    
    local servers = data["Make By Dragons Toro"] or {}  
    
    if data.total == 0 or #servers == 0 then  
        Notify("❌ Lỗi Hop", "Hết Servers", 6)  
        return  
    end  
    
    Notify("📊 Server Hop", "Tìm thấy " .. #servers .. " server", 3)  
    
    local serverQueue = {}
    for i, server in ipairs(servers) do
        local joinId = server.joinId
        if joinId and joinId ~= "" and joinId ~= game.JobId then
            table.insert(serverQueue, joinId)
        end
    end
    
    if #serverQueue == 0 then
        Notify("❌ Lỗi Hop", "Không có server khả dụng", 5)
        return
    end
    
    local joinSuccess = false
    local currentJobId = game.JobId    
    
    local function CheckJoinSuccess()
        if game.JobId ~= currentJobId then
            joinSuccess = true
            Notify("✅ Hop Thành Công", "Server: " .. game.JobId, 5)
            return true
        end
        return false
    end
    
    local function TryJoin(joinId)
        if joinSuccess then return false end        
        Notify("🔄 Server Hop", "Đang join: " .. joinId, 2)        
        pcall(function()
            local Browser = replicated:WaitForChild("__ServerBrowser")
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
            Notify("⚠️ Server Hop", "Server đầy, chuyển tiếp...", 1)            
            task.wait(0.1)
        end      
        if not joinSuccess then
            Notify("❌ Server Hop", "Hết server khả dụng", 5)
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
        Notify("❌ Server Hop", "Timeout - Không tìm được server", 5)
    end
end

-- ============================================
-- FRUIT DETECTION SYSTEM
-- ============================================

local function CheckFruitInServer()
    local fruitCount = 0
    for _, obj in pairs(workspace:GetChildren()) do
        if string.find(obj.Name, "Fruit") then
            fruitCount = fruitCount + 1
        end
    end
    return fruitCount > 0, fruitCount
end

local function AutoHopIfNoFruit()
    local found, count = CheckFruitInServer()
    
    if found then
        FruitFound = true
        Notify("✅ Fruit Found", "Tìm thấy " .. count .. " fruit trong server", 3)
    else
        FruitFound = false
        Notify("❌ No Fruit", "Không tìm thấy fruit, đang hop server...", 5)
        
        if AUTO_HOP then
            task.wait(2)
            Hop("fruits")
        end
    end
end

-- ============================================
-- TELEPORT/TWEEN FUNCTION
-- ============================================

function _tp(p)
    local block = Root
    local distance = (block.Position - p.Position).Magnitude
    local tweenInfo = TweenInfo.new(distance / 300, Enum.EasingStyle.Linear)
    local tween = TW:Create(block, tweenInfo, {CFrame = p})
    
    tween:Play()
    
    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do 
            task.wait()
            if not _G_TwFruits then 
                tween:Cancel() 
            end
        end
    end)
    
    return tween
end

-- ============================================
-- AUTO TWEEN TO FRUIT
-- ============================================

spawn(function()
    while wait(Sec) do
        if _G_TwFruits then
            pcall(function()
                for _, x1 in pairs(workspace:GetChildren()) do
                    if string.find(x1.Name, "Fruit") then 
                        _tp(x1.Handle.CFrame) 
                    end
                end
            end)
        end
    end
end)

-- ============================================
-- AUTO COLLECT FRUIT
-- ============================================

local function collectFruits(Success)
  if Success then
    local Character = plr.Character
    for _, v1 in pairs(workspace:GetChildren()) do
      if string.find(v1.Name, "Fruit") then 
        v1.Handle.CFrame = Character.HumanoidRootPart.CFrame 
      end
    end
  end
end

spawn(function()
  while wait(Sec) do
    if _G_InstanceF then
      pcall(function() collectFruits(_G_InstanceF) end)
    end
  end
end)

-- ============================================
-- AUTO STORE FRUIT
-- ============================================

local function UpdStFruit()
  for z, x in next, plr.Backpack:GetChildren() do
    StoreFruit = x:FindFirstChild("EatRemote", true)
    if StoreFruit then
      replicated.Remotes.CommF_:InvokeServer(
        "StoreFruit",
        StoreFruit.Parent:GetAttribute("OriginalName"),
        plr.Backpack:FindFirstChild(x.Name)
      )
    end
  end
end

spawn(function()
  while wait(Sec) do
    if _G_StoreF then
      pcall(function() UpdStFruit() end)
    end
  end
end)

-- ============================================
-- AUTO FRUIT CHECK & HOP
-- ============================================

spawn(function()
    while true do
        wait(CHECK_INTERVAL)
        if _G_InstanceF then -- Chỉ check khi farming
            local found, count = CheckFruitInServer()
            if not found then
                Notify("⚠️ Fruit Farm", "Không tìm thấy fruit, hop server...", 5)
                _G_InstanceF = false
                _G_StoreF = false
                task.wait(1)
                Hop("fruits")
                break
            end
        end
    end
end)

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function EquipWeapon(text)
  if not text then return end
  if plr.Backpack:FindFirstChild(text) then
    plr.Character.Humanoid:EquipTool(plr.Backpack:FindFirstChild(text))
  end
end

local function DropFruits()
  for _, v3 in next, plr.Backpack:GetChildren() do
    if string.find(v3.Name, "Fruit") then
      EquipWeapon(v3.Name) 
      wait(.1)
      if plr.PlayerGui.Main.Dialogue.Visible == true then 
        plr.PlayerGui.Main.Dialogue.Visible = false 
      end 
      EquipWeapon(v3.Name) 
      pcall(function()
        plr.Character:FindFirstChild(v3.Name).EatRemote:InvokeServer("Drop")
      end)
    end
  end
  for a, b2 in pairs(plr.Character:GetChildren()) do
    if string.find(b2.Name, "Fruit") then 
      EquipWeapon(b2.Name) 
      wait(.1)
      if plr.PlayerGui.Main.Dialogue.Visible == true then 
        plr.PlayerGui.Main.Dialogue.Visible = false 
      end 
      EquipWeapon(b2.Name) 
      pcall(function()
        plr.Character:FindFirstChild(b2.Name).EatRemote:InvokeServer("Drop")
      end)
    end
  end
end

-- ============================================
-- MAIN CONTROL FUNCTIONS
-- ============================================

function StartAutoFarm(duration)
  print("🎯 [FARM] Starting Auto Fruit Farm...")
  Notify("🎯 Farm Started", "Bắt đầu thu thập fruit", 3)
  
  -- Check fruit trước
  AutoHopIfNoFruit()
  
  if not FruitFound then
    Notify("❌ Farm Failed", "Không tìm được fruit", 5)
    return
  end
  
  -- Start all features
  _G_TwFruits = true
  wait(1)
  _G_InstanceF = true
  wait(1)
  _G_StoreF = true
  
  print("✓ All features enabled!")
  print("📊 Farming for " .. (duration or "∞") .. " seconds...")
  
  if duration then
    wait(duration)
    StopAutoFarm()
  end
end

function StopAutoFarm()
  print("🛑 [FARM] Stopping Auto Fruit Farm...")
  Notify("🛑 Farm Stopped", "Dừng thu thập fruit", 3)
  _G_TwFruits = false
  _G_InstanceF = false
  _G_StoreF = false
  print("✓ All features disabled")
end

function ManualHop(eventType)
  StopAutoFarm()
  task.wait(1)
  Hop(eventType or "fruits")
end

-- ============================================
-- PRINT HELP
-- ============================================

function PrintHelp()
  print("=====================================")
  print("🍎 FRUIT FARM COMPLETE V2 - HELP 🍎")
  print("=====================================")
  print("")
  print("📌 MAIN FEATURES:")
  print("├─ _G_TwFruits = true/false    | Auto Tween to Fruit")
  print("├─ _G_InstanceF = true/false   | Auto Collect Fruit")
  print("└─ _G_StoreF = true/false      | Auto Store Fruit")
  print("")
  print("🎯 AUTO FARM (All-in-One):")
  print("├─ StartAutoFarm()             | Farm vô thời hạn")
  print("├─ StartAutoFarm(60)           | Farm 60 giây")
  print("└─ StopAutoFarm()              | Dừng farm")
  print("")
  print("🔄 SERVER HOP:")
  print("├─ Hop('fruits')               | Hop tìm fruit")
  print("├─ ManualHop()                 | Hop + Stop farm")
  print("└─ CheckFruitInServer()        | Check fruit hiện tại")
  print("")
  print("🛠️ TOOLS:")
  print("├─ DropFruits()                | Vứt tất cả fruit")
  print("└─ PrintHelp()                 | Show help")
  print("")
  print("⚙️ CONFIG:")
  print("├─ AUTO_HOP = " .. tostring(AUTO_HOP) .. "        | Auto hop nếu không tìm fruit")
  print("├─ CHECK_INTERVAL = " .. CHECK_INTERVAL .. "       | Check fruit mỗi N giây")
  print("└─ Sec = " .. Sec .. "           | Loop interval")
  print("")
  print("=====================================")
end

-- ============================================
-- USAGE EXAMPLES
-- ============================================

--[[
  ✅ EXAMPLE 1: Quick Start
  =========================
  StartAutoFarm(120)     -- Farm 2 phút, tự động hop nếu không có fruit
  
  ✅ EXAMPLE 2: Manual Mode  
  =========================
  _G_TwFruits = true     -- Tween đến fruit
  wait(5)
  _G_InstanceF = true    -- Collect
  wait(10)
  _G_StoreF = true       -- Store
  wait(5)
  StopAutoFarm()         -- Stop tất cả
  
  ✅ EXAMPLE 3: Check & Hop
  =========================
  local found = CheckFruitInServer()
  if not found then
    ManualHop("fruits")  -- Hop tìm fruit
  end
  
  ✅ EXAMPLE 4: Loop Farm
  =======================
  while true do
    StartAutoFarm(300)   -- Farm 5 phút
    wait(10)             -- Chờ 10 giây
    if not CheckFruitInServer() then
      Notify("No Fruit", "Tìm kiếm server mới...", 5)
      ManualHop("fruits")
      break
    end
  end
--]]

-- ============================================
-- STARTUP
-- ============================================

print("")
print("🍎🍎🍎 FRUIT FARM COMPLETE V2 🍎🍎🍎")
print("")
Notify("✅ Loaded", "Fruit Farm Complete V2 Ready!", 5)
PrintHelp()
