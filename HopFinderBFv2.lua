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
    Title = "Ziner Hub",
    Icon = "badge-check",
    Author = "Kaibeo",
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
    Title = "Open Ziner Hub",
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
-- TAGS: FPS & PING
-- ==========================================

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
            FPSTag:SetColor(Color3.fromRGB(0, 255, 0))
        elseif fps >= 30 then
            FPSTag:SetColor(Color3.fromRGB(255, 200, 0))
        else
            FPSTag:SetColor(Color3.fromRGB(255, 0, 0))
        end
        frameCount = 0
        lastUpdate = now
    end
end)

local PingTag = Window:Tag({
    Title = "Ping: 0ms",
    Color = Color3.fromRGB(100, 200, 255),
})

task.spawn(function()
    while true do
        local success, ping = pcall(function()
            local Stats = game:GetService("Stats")
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if success and ping then
            PingTag:SetTitle("Ping: " .. ping .. "ms")
            if ping <= 50 then
                PingTag:SetColor(Color3.fromRGB(0, 255, 0))
            elseif ping <= 100 then
                PingTag:SetColor(Color3.fromRGB(255, 200, 0))
            elseif ping <= 200 then
                PingTag:SetColor(Color3.fromRGB(255, 150, 0))
            else
                PingTag:SetColor(Color3.fromRGB(255, 0, 0))
            end
        end
        task.wait(2)
    end
end)

-- ==========================================
-- HOP SERVER LOGIC
-- ==========================================

local reqfunc = request or (http and http.request) or http_request
local httpser = game:GetService("HttpService")
local tpser = game:GetService("TeleportService")

local function getjob(name)
    if not reqfunc then
        warn("[Ziner hub] Executor không hỗ trợ HTTP request")
        return nil
    end
    local bool, tbl = pcall(function()
        return reqfunc({
            Url = "http://n1.hanamc.io.vn:25568/qvuong/api/" .. tostring(name),
            Method = "GET"
        })
    end)
    if not (bool and tbl) then
        warn("[Ziner hub] Không thể gọi API hop: " .. tostring(name))
        return nil
    end
    local ok, decoded = pcall(function()
        return httpser:JSONDecode(tbl.Body)
    end)
    if not ok or not decoded then
        warn("[Ziner Hub] Lỗi parse JSON")
        return nil
    end
    local jobs = {}
    for i, v in pairs(decoded) do
        if i > 5 then break end
        table.insert(jobs, v)
    end
    return jobs
end

local function hopToServer(name)
    task.spawn(function()
        local jobs = getjob(name)
        if not jobs or #jobs < 1 then
            warn("[Ziner hub] Không tìm được server: " .. tostring(name))
            return
        end
        for _, v in ipairs(jobs) do
            if v and v.Job_id and v.place_id then
                if tonumber(game.PlaceId) == tonumber(v.place_id) then
                    pcall(function()
                        tpser:TeleportToPlaceInstance(
                            tonumber(v.place_id),
                            tostring(v.Job_id),
                            game:GetService("Players").LocalPlayer
                        )
                    end)
                    task.wait(1)
                end
            end
        end
    end)
end

-- ==========================================
-- TABS
-- ==========================================

local InfoTab = Window:Tab({
    Title = "Info",
    Desc = "Info Hub",
    Icon = "info",
    IconColor = Color3.fromHex("#ffffff"),
    IconShape = "Square",
    IconThemed = true,
    Locked = false,
    ShowTabTitle = false,
    Border = true,
})

-- ==========================================
-- HOP TAB
-- ==========================================

local HopTab = Window:Tab({
    Title = "Hop Server",
    Desc = "Click to join",
    Icon = "server",
    IconColor = Color3.fromHex("#ffffff"),
    IconShape = "Square",
    IconThemed = true,
    Locked = false,
    ShowTabTitle = false,
    Border = true,
})

HopTab:Button({
    Title = "Hop Server Full Moon",
    Desc = "Auto Join Server Full Moon",
    Icon = "moon",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        hopToServer("fullmoon")
    end
})

HopTab:Button({
    Title = "Hop Server Haki Legendary",
    Desc = "Auto Join Server Haki Legendary",
    Icon = "zap",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        hopToServer("haki")
    end
})

HopTab:Button({
    Title = "Hop Server Sword Legendary",
    Desc = "Auto Join Server Sword Legendary",
    Icon = "sword",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        hopToServer("sword")
    end
})

HopTab:Button({
    Title = "Hop Mirage Island",
    Desc = "Auto Join Mirage Island",
    Icon = "map",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        hopToServer("mirage")
    end
})

HopTab:Button({
    Title = "Hop Server Prehistoric",
    Desc = "Auto Join Server Prehistoric",
    Icon = "bone",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        hopToServer("prehistoric")
    end
})

-- ==========================================
-- MAIN TAB
-- ==========================================

local MainTab = Window:Tab({
    Title = "Main",
    Desc = "Main of script",
    Icon = "house",
    IconColor = Color3.fromHex("#ffffff"),
    IconShape = "Square",
    IconThemed = true,
    Locked = false,
    ShowTabTitle = false,
    Border = true,
})

local SettingFarmSection = MainTab:Section({
    Title = "Setting Farm",
    Desc = "Select method to farm",
    Icon = "settings",
    TextSize = 19,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
    DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05,
    DescTextTransparency = 0.4,
})

-- ==========================================
-- FAST ATTACK
-- ==========================================

local FastAttackEnabled = false
local FastAttackThread = nil

local function StartFastAttack()
    if FastAttackThread then return end
    FastAttackEnabled = true
    FastAttackThread = task.spawn(function()
        local RS = game.ReplicatedStorage
        local N = require(RS.Modules.Net)
        local P = game.Players.LocalPlayer
        local hit = N:RemoteEvent("RegisterHit", true)
        local atk = RS.Modules.Net["RE/RegisterAttack"]
        while FastAttackEnabled do
            task.wait()
            local c = P.Character
            if not c then continue end
            local r = c:FindFirstChild("HumanoidRootPart")
            local t = c:FindFirstChildOfClass("Tool")
            if not (r and t) then continue end
            local id = tostring(P.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15)
            local didy = false
            for _, m in ipairs(workspace.Enemies:GetChildren()) do
                local h, u = m:FindFirstChild("HumanoidRootPart"), m:FindFirstChild("Humanoid")
                if h and u and u.Health > 0 and (h.Position - r.Position).Magnitude <= 60 then
                    if not didy then atk:FireServer() didy = true end
                    hit:FireServer(h, {{m, h}}, nil, nil, id)
                end
            end
            for _, plr in ipairs(game.Players:GetPlayers()) do
                if plr ~= P and plr.Character then
                    local m = plr.Character
                    local h = m:FindFirstChild("HumanoidRootPart")
                    local u = m:FindFirstChild("Humanoid")
                    if h and u and u.Health > 0 and (h.Position - r.Position).Magnitude <= 60 then
                        if not didy then atk:FireServer() didy = true end
                        hit:FireServer(h, {{m, h}}, nil, nil, id)
                    end
                end
            end
        end
    end)
end

local function StopFastAttack()
    FastAttackEnabled = false
    FastAttackThread = nil
end

SettingFarmSection:Toggle({
    Title = "Fast Attack",
    Desc = "Tấn công nhanh không cooldown",
    Icon = "sword",
    Value = false,
    Type = "Toggle",
    Color = Color3.fromRGB(100, 200, 100),
    Locked = false,
    Flag = "fast_attack",
    Callback = function(state)
        if state then StartFastAttack() else StopFastAttack() end
    end
})

local FarmSection = MainTab:Section({
    Title = "Farm",
    Desc = "Farm everything",
    Icon = "apple",
    TextSize = 19,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
    DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05,
    DescTextTransparency = 0.4,
})

FarmSection:Dropdown({
    Title = "Select Boss",
    Desc = "Select Boss you want farm",
    Values = {"1", "2", "3", "4"},
    Value = "none",
    Multi = false,
    Locked = false,
    Flag = "select_boss",
    Callback = function(selected)
        --//script
    end
})

FarmSection:Toggle({
    Title = "Auto Farm Boss",
    Desc = "Auto farm boss chose",
    Icon = "power",
    Value = false,
    Type = "Toggle",
    Locked = false,
    Flag = "auto_farm",
    Callback = function(state)
        --//script
    end
})

FarmSection:Divider()

-- ==========================================
-- TELEPORT TAB
-- ==========================================

local TpTab = Window:Tab({
    Title = "Teleport",
    Desc = "Travel to island, sea, ...",
    Icon = "tree-palm",
    IconColor = Color3.fromHex("#ffffff"),
    IconShape = "Square",
    IconThemed = true,
    Locked = false,
    ShowTabTitle = false,
    Border = true,
})

-- ==========================================
-- FLY LOGIC - SMOOTH
-- Mỗi "bước server" = 60 studs, chờ 0.5s để server chấp nhận.
-- Giữa 2 bước server dùng TweenService animate mượt trên client
-- → nhìn mượt, không giật, không bị server kéo về.
-- ==========================================

local TweenService = game:GetService("TweenService")
local _flyThread = nil
local _isFlying  = false

-- Tốc độ server chấp nhận: 60 studs / 0.5s = 120 studs/s (giới hạn an toàn)
local STEP_DIST = 60    -- studs mỗi bước server
local STEP_TIME = 0.5   -- giây mỗi bước (giữ nguyên để không bị kick)

local function EnableBodyClip(hrp)
    if hrp:FindFirstChild("BodyClip") then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "BodyClip"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
end

local function DisableBodyClip(hrp)
    local bc = hrp:FindFirstChild("BodyClip")
    if bc then bc:Destroy() end
end

local function SetCanCollide(char, state)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = state end
    end
end

local function FlyTo(targetCF)
    if _flyThread then
        pcall(function() task.cancel(_flyThread) end)
        _flyThread = nil
    end

    _isFlying = true
    _flyThread = task.spawn(function()
        local player = game:GetService("Players").LocalPlayer
        local char   = player.Character
        if not char then _isFlying = false return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then _isFlying = false return end

        EnableBodyClip(hrp)
        SetCanCollide(char, false)

        local targetPos = targetCF.Position
        local activeTween = nil

        while _isFlying do
            local curPos   = hrp.Position
            local remaining = (targetPos - curPos).Magnitude
            if remaining < 8 then break end

            -- Tính điểm đến của bước server này
            local dir      = (targetPos - curPos).Unit
            local stepDist = math.min(remaining, STEP_DIST)
            local nextCF   = (remaining <= STEP_DIST)
                and targetCF
                or  CFrame.new(curPos + dir * stepDist)

            -- Hủy tween cũ nếu còn
            if activeTween then activeTween:Cancel() end

            -- Tween mượt tới điểm đó trong STEP_TIME giây
            activeTween = TweenService:Create(
                hrp,
                TweenInfo.new(STEP_TIME, Enum.EasingStyle.Linear),
                { CFrame = nextCF }
            )
            activeTween:Play()

            -- Chờ đúng STEP_TIME để server sync
            task.wait(STEP_TIME)
        end

        if activeTween then activeTween:Cancel() end

        -- Snap chính xác vào đích
        pcall(function() hrp.CFrame = targetCF end)

        SetCanCollide(char, true)
        DisableBodyClip(hrp)
        _isFlying  = false
        _flyThread = nil
    end)
end

-- TỌA ĐỘ ĐẢO
local IslandCoords = {
    -- BIỂN 1
    ["WindMill"]           = CFrame.new(979.79895019531, 16.516613006592, 1429.0466308594),
    ["Marine"]             = CFrame.new(-690.33081054688, 15.09425163269, 1582.2380371094),
    ["Middle Town"]        = CFrame.new(-1612.7957763672, 36.852081298828, 149.12843322754),
    ["Jungle"]             = CFrame.new(-1181.3093261719, 4.7514905929565, 3803.5456542969),
    ["Pirate Village"]     = CFrame.new(944.15789794922, 20.919729232788, 4373.3002929688),
    ["Desert"]             = CFrame.new(1347.8067626953, 104.66806030273, -1319.7370605469),
    ["Snow Island"]        = CFrame.new(-4914.8212890625, 50.963626861572, 4281.0278320313),
    ["MarineFord"]         = CFrame.new(-1427.6203613281, 7.2881078720093, -2792.7722167969),
    ["Colosseum"]          = CFrame.new(-2850.20068, 7.39224768, 5354.99268),
    ["Sky Island 1"]       = CFrame.new(-288.74060058594, 49326.31640625, -35248.59375),
    ["Sky Island 2"]       = CFrame.new(-260.65557861328, 49325.8046875, -35253.5703125),
    ["Sky Island 3"]       = CFrame.new(-380.47927856445, 77.220390319824, 255.82550048828),
    ["Prison"]             = CFrame.new(-11.311455726624, 29.276733398438, 2771.5224609375),
    ["Magma Village"]      = CFrame.new(3780.0302734375, 22.652164459229, -3498.5859375),
    ["Under Water Island"] = CFrame.new(4875.330078125, 5.6519818305969, 734.85021972656),
    ["Fountain City"]      = CFrame.new(-5247.7163085938, 12.883934020996, 8504.96875),
    ["Shank Room"]         = CFrame.new(-380.47927856445, 77.220390319824, 255.82550048828),
    ["Mob Island"]         = CFrame.new(5127.1284179688, 59.501365661621, 4105.4458007813),
    -- BIỂN 2
    ["The Cafe"]           = CFrame.new(-1503.6224365234, 219.7956237793, 1369.3101806641),
    ["Frist Spot"]         = CFrame.new(424.12698364258, 211.16171264648, -427.54049682617),
    ["Dark Area"]          = CFrame.new(-2448.5300292969, 73.016105651855, -3210.6306152344),
    ["Flamingo Mansion"]   = CFrame.new(-5622.033203125, 492.19604492188, -781.78552246094),
    ["Flamingo Room"]      = CFrame.new(753.14288330078, 408.23559570313, -5274.6147460938),
    ["Green Zone"]         = CFrame.new(-6127.654296875, 15.951762199402, -5040.2861328125),
    ["Factory"]            = CFrame.new(4816.8618164063, 8.4599885940552, 2863.8195800781),
    ["Colossuim"]          = CFrame.new(-3032.7641601563, 317.89672851563, -10075.373046875),
    ["Zombie Island"]      = CFrame.new(6148.4116210938, 294.38687133789, -6741.1166992188),
    ["Two Snow Mountain"]  = CFrame.new(-4869.1025390625, 733.46051025391, -2667.0180664063),
    ["Punk Hazard"]        = CFrame.new(2681.2736816406, 1682.8092041016, -7190.9853515625),
    ["Cursed Ship"]        = CFrame.new(-9515.3720703125, 164.00624084473, 5786.0610351562),
    ["Ice Castle"]         = CFrame.new(-290.7376708984375, 6.729952812194824, 5343.5537109375),
    ["Forgotten Island"]   = CFrame.new(-13274.528320313, 531.82073974609, -7579.22265625),
    ["Ussop Island"]       = CFrame.new(-3032.7641601563, 317.89672851563, -10075.373046875),
    ["Mini Sky Island"]    = CFrame.new(-288.74060058594, 49326.31640625, -35248.59375),
    -- BIỂN 3
    ["Mansion"]            = CFrame.new(-9515.3720703125, 164.00624084473, 5786.0610351562),
    ["Port Town"]          = CFrame.new(-260.65557861328, 49325.8046875, -35253.5703125),
    ["Great Tree"]         = CFrame.new(-1884.7747802734375, 19.327526092529297, -11666.8974609375),
    ["Castle On The Sea"]  = CFrame.new(-2062.7475585938, 50.473892211914, -10232.568359375),
    ["MiniSky"]            = CFrame.new(-902.56817626953, 79.93204498291, -10988.84765625),
    ["Hydra Island"]       = CFrame.new(87.94276428222656, 73.55451202392578, -12319.46484375),
    ["Floating Turtle"]    = CFrame.new(-1014.4241943359375, 149.11068725585938, -14555.962890625),
    ["Haunted Castle"]     = CFrame.new(-16542.447265625, 55.68632888793945, 1044.41650390625),
    ["Ice Cream Island"]   = CFrame.new(-1884.7747802734375, 19.327526092529297, -11666.8974609375),
    ["Peanut Island"]      = CFrame.new(87.94276428222656, 73.55451202392578, -12319.46484375),
    ["Cake Island"]        = CFrame.new(-1014.4241943359375, 149.11068725585938, -14555.962890625),
    ["Cocoa Island"]       = CFrame.new(-902.56817626953, 79.93204498291, -10988.84765625),
    ["Candy Island"]       = CFrame.new(-2062.7475585938, 50.473892211914, -10232.568359375),
    ["Tiki Outpost"]       = CFrame.new(-16542.447265625, 55.68632888793945, 1044.41650390625),
}

-- Đảo cần requestEntrance trước khi bay
local IslandEntrance = {
    ["Shank Room"]   = Vector3.new(-281.93707275390625, 306.130615234375, 609.280029296875),
    ["Ussop Island"] = Vector3.new(2284.912109375, 15.152034759521484, 905.48291015625),
}

local AllIslands = {
    "[S1] WindMill","[S1] Marine","[S1] Middle Town","[S1] Jungle","[S1] Pirate Village",
    "[S1] Desert","[S1] Snow Island","[S1] MarineFord","[S1] Colosseum",
    "[S1] Sky Island 1","[S1] Sky Island 2","[S1] Sky Island 3",
    "[S1] Prison","[S1] Magma Village","[S1] Under Water Island",
    "[S1] Fountain City","[S1] Shank Room","[S1] Mob Island",
    "[S2] The Cafe","[S2] Frist Spot","[S2] Dark Area","[S2] Flamingo Mansion","[S2] Flamingo Room",
    "[S2] Green Zone","[S2] Factory","[S2] Colossuim","[S2] Zombie Island","[S2] Two Snow Mountain",
    "[S2] Punk Hazard","[S2] Cursed Ship","[S2] Ice Castle","[S2] Forgotten Island",
    "[S2] Ussop Island","[S2] Mini Sky Island",
    "[S3] Mansion","[S3] Port Town","[S3] Great Tree","[S3] Castle On The Sea","[S3] MiniSky",
    "[S3] Hydra Island","[S3] Floating Turtle","[S3] Haunted Castle","[S3] Ice Cream Island",
    "[S3] Peanut Island","[S3] Cake Island","[S3] Cocoa Island","[S3] Candy Island","[S3] Tiki Outpost",
}

-- ===== SEA SECTION =====
local SeaSection = TpTab:Section({
    Title = "Đổi Biển",
    Desc = "Di chuyển giữa các biển",
    Icon = "ship",
    TextSize = 19,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = true,
    FontWeight = Enum.FontWeight.SemiBold,
    DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05,
    DescTextTransparency = 0.4,
})

SeaSection:Button({
    Title = "Biển 1 (First Sea)",
    Desc = "Teleport về Biển 1",
    Icon = "anchor",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelMain")
        end)
    end
})

SeaSection:Button({
    Title = "Biển 2 (Second Sea)",
    Desc = "Teleport về Biển 2",
    Icon = "anchor",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelDressrosa")
        end)
    end
})

SeaSection:Button({
    Title = "Biển 3 (Third Sea)",
    Desc = "Teleport về Biển 3",
    Icon = "anchor",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelZou")
        end)
    end
})

-- ===== ISLAND SECTION =====
local IslandSection = TpTab:Section({
    Title = "Đảo",
    Desc = "Chọn đảo và bay đến ngay lập tức",
    Icon = "map-pin",
    TextSize = 19,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = true,
    FontWeight = Enum.FontWeight.SemiBold,
    DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05,
    DescTextTransparency = 0.4,
})

local SelectedIsland = AllIslands[1]

IslandSection:Dropdown({
    Title = "Chọn Đảo",
    Desc = "Chọn đảo muốn bay đến",
    Values = AllIslands,
    Value = AllIslands[1],
    Multi = false,
    Locked = false,
    Flag = "select_island",
    Callback = function(val)
        SelectedIsland = val
    end
})

IslandSection:Button({
    Title = "Bay Đến Đảo",
    Desc = "Nhân vật bay từng bước tới đảo (không bị giật về)",
    Icon = "navigation",
    IconAlign = "Right",
    Justify = "Between",
    Callback = function()
        if not SelectedIsland then return end
        local islandName = string.match(SelectedIsland, "%[S%d%] (.+)") or SelectedIsland
        local cf = IslandCoords[islandName]
        if not cf then return end
        -- requestEntrance trước nếu cần
        local entrance = IslandEntrance[islandName]
        if entrance then
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("requestEntrance", entrance)
            end)
            task.wait(0.5)
        end
        FlyTo(cf)
    end
})

-- ==========================================
-- SHOP TAB
-- ==========================================

local ShopTab = Window:Tab({
    Title = "Shop",
    Desc = "Buy Melle, Sword, Haki Color,...",
    Icon = "shopping-cart",
    IconColor = Color3.fromHex("#ffffff"),
    IconShape = "Square",
    IconThemed = true,
    Locked = false,
    ShowTabTitle = false,
    Border = true,
})

local AutoBuySection = ShopTab:Section({
    Title = "Auto Buy",
    Desc = "Auto buy everything",
    Icon = "sword",
    TextSize = 19,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
    DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05,
    DescTextTransparency = 0.4,
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AutoBuyHaki = false
local AutoBuySword = false
local hakiThread = nil
local swordThread = nil

local function StartAutoBuyHaki()
    if hakiThread then return end
    AutoBuyHaki = true
    hakiThread = task.spawn(function()
        while AutoBuyHaki do
            pcall(function()
                ReplicatedStorage.Remotes.CommF:InvokeServer("ColorsDealer", "2")
            end)
            task.wait(1)
        end
    end)
end

local function StopAutoBuyHaki()
    AutoBuyHaki = false
    hakiThread = nil
end

local function StartAutoBuySword()
    if swordThread then return end
    AutoBuySword = true
    swordThread = task.spawn(function()
        while AutoBuySword do
            pcall(function()
                ReplicatedStorage.Remotes.CommF:InvokeServer("LegendarySwordDealer", "1")
                ReplicatedStorage.Remotes.CommF:InvokeServer("LegendarySwordDealer", "2")
                ReplicatedStorage.Remotes.CommF:InvokeServer("LegendarySwordDealer", "3")
            end)
            task.wait(1)
        end
    end)
end

local function StopAutoBuySword()
    AutoBuySword = false
    swordThread = nil
end

AutoBuySection:Toggle({
    Title = "Auto Buy Haki Color",
    Desc = "Turn ON/OFF",
    Icon = "power",
    Value = false,
    Callback = function(state)
        if state then StartAutoBuyHaki() else StopAutoBuyHaki() end
    end
})

AutoBuySection:Toggle({
    Title = "Auto Buy Sword Legendary",
    Desc = "Turn ON/OFF",
    Icon = "power",
    Value = false,
    Callback = function(state)
        if state then StartAutoBuySword() else StopAutoBuySword() end
    end
})
