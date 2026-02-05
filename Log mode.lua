local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local function Hop(key)
    local url = "http://n1.hanamc.io.vn:25568/jobid/" .. key

    local ok, res = pcall(function()
        return request({ Url = url, Method = "GET" })
    end)
    if not ok or not res or not res.Body then return end

    local cac = HttpService:JSONDecode(res.Body)
    for i, v in cac.JobId do
        for jobid, timestamp in v do
            if jobid ~= game.JobId then
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(
                        game.PlaceId,
                        jobid,
                        Players.LocalPlayer
                    )
                end)
                task.wait(3)
                return
            end
        end
    end
end

local _version = "1.6.63"
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/download/" .. _version .. "/main.lua"
))()

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
    Title = "ZMatrix Hub | Hop Server",
    Icon = "door-open",
    Author = "Kaibeo",
    Folder = "ZMatrix Hub | Hop Server",

    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),

    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    HideSearchBar = true,
    ScrollBarEnabled = false,

    User = { Enabled = true }
})

local InfoTab = Window:Tab({
    Title = "Tab Info",
    Icon = "info",
    Border = true
})

local HopTab = Window:Tab({
    Title = "Tab Hop",
    Icon = "zap",
    Border = true
})

local FarmingTab = Window:Tab({
    Title = "Tab Farming",
    Icon = "wheat",
    Border = true
})

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

local InfoSection = InfoTab:Section({
    Title = "Information",
    Icon = "activity",
    Opened = true
})

InfoSection:Button({
    Title = "Copy Discord",
    Desc = "Copy invite link",
    Icon = "clipboard",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/robloxcity")
        end
    end
})

local ServerStatus = InfoSection:Paragraph({
    Title = "Server Status",
    Desc = "Loading..."
})

local HopSection = HopTab:Section({
    Title = "Hop Server",
})

HopSection:Button({
    Title = "Full Moon",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
    Hop("fullmoon")
    end
})

HopSection:Button({
    Title = "Mirage Island",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
    Hop("mirage")
    end
})

HopSection:Button({
    Title = "Prehistoric Island",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
        Hop("prehistoric")
    end
})

HopSection:Button({
    Title = "Haki Legendary",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
    Hop("legendary-haki")
    end
})

HopSection:Button({
    Title = "Sword Legendary",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
    Hop("sword")
    end
})

HopSection:Button({
    Title = "Dough King",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
    Hop("node")
    end
})

HopSection:Button({
    Title = "Rip Indra",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
        Hop("node")
    end
})

--====================================================
-- FARM BOSS FULL (GRAVITY STYLE | NO TP | Y LOCK SMART)
--====================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
end)

--==================== SETTINGS ====================
local AutoFarmBoss = false
local SelectedBoss = nil

local FlySpeed = 300
local HeightAboveBoss = 25 -- bay cao hơn boss 25m

local LockY = false
local LockedY = nil

--==================== BOSS LIST (GRAVITY) ====================
local BossList = {
    "Hydra Leader",
    "Dough King",
    "Cake Queen",
    "Soul Reaper",
    "Longma",
    "rip_indra True Form",
    "Tyrant of the Skies"
}

--==================== FIND BOSS (FULL MAP) ====================
local function FindBoss(name)
    if not name then return nil end

    -- ưu tiên Enemies
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, v in ipairs(enemies:GetChildren()) do
            if string.lower(v.Name) == string.lower(name) then
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    return v
                end
            end
        end
    end

    -- fallback toàn map
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model")
        and string.lower(v.Name) == string.lower(name) then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            local hum = v:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                return v
            end
        end
    end

    return nil
end

--==================== BAY (KHÔNG TP) ====================
local function FlyTo(cf)
    if not HRP then return end

    local dist = (HRP.Position - cf.Position).Magnitude
    local time = dist / FlySpeed

    TweenService:Create(
        HRP,
        TweenInfo.new(time, Enum.EasingStyle.Linear),
        {CFrame = cf}
    ):Play()
end

--==================== MAIN FARM LOOP ====================
task.spawn(function()
    while task.wait(0.6) do
        if AutoFarmBoss and SelectedBoss then
            local boss = FindBoss(SelectedBoss)

            if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                -- ===== FARMING (KHÓA Y) =====
                LockY = true

                if not LockedY then
                    LockedY = boss.HumanoidRootPart.Position.Y + HeightAboveBoss
                end

                local bossPos = boss.HumanoidRootPart.Position
                local targetPos = Vector3.new(
                    bossPos.X,
                    LockedY, -- 🔒 KHÓA Y KHI BOSS CÒN SỐNG
                    bossPos.Z
                )

                FlyTo(CFrame.new(targetPos))

            else
                -- ===== BOSS CHẾT / DESPAWN =====
                LockY = false
                LockedY = nil
            end
        else
            -- ===== KHÔNG FARM =====
            LockY = false
            LockedY = nil
        end
    end
end)

--==================== UI (TAB FARMING) ====================
local FarmingSection = FarmingTab:Section({
    Title = "Farm Boss (Gravity)",
    Icon = "navigation",
    Opened = true
})

FarmingSection:Dropdown({
    Title = "Select Boss",
    Desc = "Chọn boss cần farm",
    Values = BossList,
    Callback = function(v)
        SelectedBoss = v
    end
})

FarmingSection:Toggle({
    Title = "Auto Farm Boss",
    Desc = "Bay toàn map – khóa Y khi boss sống",
    Default = false,
    Callback = function(v)
        AutoFarmBoss = v
        if not v then
            LockY = false
            LockedY = nil
        end
    end
})

local remote, idremote
for _, v in next, ({game.ReplicatedStorage.Util, game.ReplicatedStorage.Common, game.ReplicatedStorage.Remotes, game.ReplicatedStorage.Assets, game.ReplicatedStorage.FX}) do
    for _, n in next, v:GetChildren() do
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end
    v.ChildAdded:Connect(function(n)
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end)
end
task.spawn(function()
    while task.wait(0.0005) do
        local char = game.Players.LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local parts = {}
        for _, x in ipairs({workspace.Enemies, workspace.Characters}) do
            for _, v in ipairs(x and x:GetChildren() or {}) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if v ~= char and hrp and hum and hum.Health > 0 and (hrp.Position - root.Position).Magnitude <= 60 then
                    for _, _v in ipairs(v:GetChildren()) do
                        if _v:IsA("BasePart") and (hrp.Position - root.Position).Magnitude <= 60 then
                            parts[#parts+1] = {v, _v}
                        end
                    end
                end
            end
        end
        local tool = char:FindFirstChildOfClass("Tool")
        if #parts > 0 and tool and (tool:GetAttribute("WeaponType") == "Melee" or tool:GetAttribute("WeaponType") == "Sword") then
            pcall(function()
                require(game.ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit", true)
                game.ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
                local head = parts[1][1]:FindFirstChild("Head")
                if not head then return end
                game.ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(head, parts, {}, tostring(game.Players.LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15))
                cloneref(remote):FireServer(string.gsub("RE/RegisterHit", ".", function(c)
                    return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
                end),
                bit32.bxor(idremote + 909090, game.ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2), head, parts)
            end)
        end
    end
end)    Name = "Dark",
    Accent = Color3.fromHex("#18181b"),
    Background = Color3.fromHex("#101010"),
    Outline = Color3.fromHex("#FFFFFF"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Button = Color3.fromHex("#52525b"),
    Icon = Color3.fromHex("#a1a1aa"),
})

local Window = WindUI:CreateWindow({
    Title = "ZMatrix Hub | Hop Server",
    Icon = "door-open",
    Author = "Kaibeo",
    Folder = "ZMatrix Hub | Hop Server",

    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),

    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    HideSearchBar = true,
    ScrollBarEnabled = false,

    User = { Enabled = true }
})

local InfoTab = Window:Tab({
    Title = "Tab Info",
    Icon = "info",
    Border = true
})

local HopTab = Window:Tab({
    Title = "Tab Hop",
    Icon = "zap",
    Border = true
})

local FarmingTab = Window:Tab({
    Title = "Tab Farming",
    Icon = "wheat",
    Border = true
})

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

local InfoSection = InfoTab:Section({
    Title = "Information",
    Icon = "activity",
    Opened = true
})

InfoSection:Button({
    Title = "Copy Discord",
    Desc = "Copy invite link",
    Icon = "clipboard",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/robloxcity")
        end
    end
})

local ServerStatus = InfoSection:Paragraph({
    Title = "Server Status",
    Desc = "Loading..."
})

local StatusSection = InfoTab:Section({
    Title = "Event Status",
    Desc = "",
    Icon = "activity",
    Opened = true
})

local FullMoonStatus = StatusSection:Paragraph({ Title = "Full Moon", Desc = "Checking..." })
local MirageStatus    = StatusSection:Paragraph({ Title = "Mirage Island", Desc = "Checking..." })
local PrehistoricStatus = StatusSection:Paragraph({ Title = "Prehistoric Island", Desc = "Checking..." })
local RipIndraStatus  = StatusSection:Paragraph({ Title = "Rip Indra", Desc = "Checking..." })
local DoughKingStatus = StatusSection:Paragraph({ Title = "Dough King", Desc = "Checking..." })

local function HasFullMoon()
    return Lighting:FindFirstChild("MoonTextureId") ~= nil
end

local function HasMirage()
    return workspace:FindFirstChild("MirageIsland") ~= nil
end

local function HasPrehistoric()
    return workspace:FindFirstChild("PrehistoricIsland") ~= nil
end

local function HasRipIndra()
    return workspace:FindFirstChild("RipIndra") ~= nil
end

local function HasDoughKing()
    return workspace:FindFirstChild("DoughKing") ~= nil
end

task.spawn(function()
    while task.wait(1) do
        -- Server info
        local ping = 0
        pcall(function()
            ping = math.floor(
                Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            )
        end)

        ServerStatus:SetDesc(
            "Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers ..
            "\nPing: " .. ping .. " ms" ..
            "\nJobId: " .. game.JobId
        )
        FullMoonStatus:SetDesc(HasFullMoon() and "🟢 Active" or "🔴 Inactive")
        MirageStatus:SetDesc(HasMirage() and "🟢 Found" or "🔴 Not Found")
        PrehistoricStatus:SetDesc(HasPrehistoric() and "🟢 Found" or "🔴 Not Found")
        RipIndraStatus:SetDesc(HasRipIndra() and "🟢 Spawned" or "🔴 Not Spawned")
        DoughKingStatus:SetDesc(HasDoughKing() and "🟢 Available" or "🔴 Not Available")
    end
end)

local HopSection = HopTab:Section({
    Title = "Hop Server",
})

HopSection:Button({
    Title = "Full Moon",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
    Hop("fullmoon")
    end
})

HopSection:Button({
    Title = "Mirage Island",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
    Hop("mirage")
    end
})

HopSection:Button({
    Title = "Prehistoric Island",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
        Hop("prehistoric")
    end
})

HopSection:Button({
    Title = "Haki Legendary",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
    Hop("legendary-haki")
    end
})

HopSection:Button({
    Title = "Sword Legendary",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
    Hop("sword")
    end
})

HopSection:Button({
    Title = "Dough King",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
    Hop("node")
    end
})

HopSection:Button({
    Title = "Rip Indra",
    Desc = "Click to join server",
    Icon = "mouse",
    Callback = function()
        Hop("node")
    end
})

--====================================================
-- FARM BOSS FULL (GRAVITY STYLE | NO TP | Y LOCK SMART)
--====================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
end)

--==================== SETTINGS ====================
local AutoFarmBoss = false
local SelectedBoss = nil

local FlySpeed = 300
local HeightAboveBoss = 25 -- bay cao hơn boss 25m

local LockY = false
local LockedY = nil

--==================== BOSS LIST (GRAVITY) ====================
local BossList = {
    "Hydra Leader",
    "Dough King",
    "Cake Queen",
    "Soul Reaper",
    "Longma",
    "rip_indra True Form",
    "Tyrant of the Skies"
}

--==================== FIND BOSS (FULL MAP) ====================
local function FindBoss(name)
    if not name then return nil end

    -- ưu tiên Enemies
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, v in ipairs(enemies:GetChildren()) do
            if string.lower(v.Name) == string.lower(name) then
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    return v
                end
            end
        end
    end

    -- fallback toàn map
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model")
        and string.lower(v.Name) == string.lower(name) then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            local hum = v:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                return v
            end
        end
    end

    return nil
end

--==================== BAY (KHÔNG TP) ====================
local function FlyTo(cf)
    if not HRP then return end

    local dist = (HRP.Position - cf.Position).Magnitude
    local time = dist / FlySpeed

    TweenService:Create(
        HRP,
        TweenInfo.new(time, Enum.EasingStyle.Linear),
        {CFrame = cf}
    ):Play()
end

--==================== MAIN FARM LOOP ====================
task.spawn(function()
    while task.wait(0.6) do
        if AutoFarmBoss and SelectedBoss then
            local boss = FindBoss(SelectedBoss)

            if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                -- ===== FARMING (KHÓA Y) =====
                LockY = true

                if not LockedY then
                    LockedY = boss.HumanoidRootPart.Position.Y + HeightAboveBoss
                end

                local bossPos = boss.HumanoidRootPart.Position
                local targetPos = Vector3.new(
                    bossPos.X,
                    LockedY, -- 🔒 KHÓA Y KHI BOSS CÒN SỐNG
                    bossPos.Z
                )

                FlyTo(CFrame.new(targetPos))

            else
                -- ===== BOSS CHẾT / DESPAWN =====
                LockY = false
                LockedY = nil
            end
        else
            -- ===== KHÔNG FARM =====
            LockY = false
            LockedY = nil
        end
    end
end)

--==================== UI (TAB FARMING) ====================
local FarmingSection = FarmingTab:Section({
    Title = "Farm Boss (Gravity)",
    Icon = "navigation",
    Opened = true
})

FarmingSection:Dropdown({
    Title = "Select Boss",
    Desc = "Chọn boss cần farm",
    Values = BossList,
    Callback = function(v)
        SelectedBoss = v
    end
})

FarmingSection:Toggle({
    Title = "Auto Farm Boss",
    Desc = "Bay toàn map – khóa Y khi boss sống",
    Default = false,
    Callback = function(v)
        AutoFarmBoss = v
        if not v then
            LockY = false
            LockedY = nil
        end
    end
})

local remote, idremote
for _, v in next, ({game.ReplicatedStorage.Util, game.ReplicatedStorage.Common, game.ReplicatedStorage.Remotes, game.ReplicatedStorage.Assets, game.ReplicatedStorage.FX}) do
    for _, n in next, v:GetChildren() do
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end
    v.ChildAdded:Connect(function(n)
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end)
end
task.spawn(function()
    while task.wait(0.0005) do
        local char = game.Players.LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local parts = {}
        for _, x in ipairs({workspace.Enemies, workspace.Characters}) do
            for _, v in ipairs(x and x:GetChildren() or {}) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if v ~= char and hrp and hum and hum.Health > 0 and (hrp.Position - root.Position).Magnitude <= 60 then
                    for _, _v in ipairs(v:GetChildren()) do
                        if _v:IsA("BasePart") and (hrp.Position - root.Position).Magnitude <= 60 then
                            parts[#parts+1] = {v, _v}
                        end
                    end
                end
            end
        end
        local tool = char:FindFirstChildOfClass("Tool")
        if #parts > 0 and tool and (tool:GetAttribute("WeaponType") == "Melee" or tool:GetAttribute("WeaponType") == "Sword") then
            pcall(function()
                require(game.ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit", true)
                game.ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
                local head = parts[1][1]:FindFirstChild("Head")
                if not head then return end
                game.ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(head, parts, {}, tostring(game.Players.LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15))
                cloneref(remote):FireServer(string.gsub("RE/RegisterHit", ".", function(c)
                    return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
                end),
                bit32.bxor(idremote + 909090, game.ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2), head, parts)
            end)
        end
    end
end)
