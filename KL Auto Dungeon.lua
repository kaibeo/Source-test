-- ============================================================
-- KING LEGACY - FULL DUNGEON FARM v6
-- ✅ Auto vào dungeon + TP cổng
-- ✅ OpOp Z 60s cooldown tự động
-- ✅ Fruit TRƯỚC Sword (OpOp → Kioru V2)
-- ✅ Fast Attack + Random mob 300 studs
-- ✅ 2 hit rồi đổi con
-- ✅ M1 + Skill song song
-- ✅ Auto respawn + Auto retry dungeon
-- ✅ GUI đầy đủ + kéo được
-- Executor: Delta
-- ============================================================

local Players             = game:GetService("Players")
local Workspace           = game:GetService("Workspace")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player   = Players.LocalPlayer
local char     = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root     = char:WaitForChild("HumanoidRootPart")

-- ══════════════════════════════════════════
--              CONFIG
-- ══════════════════════════════════════════
local CONFIG = {
    -- Attack
    AttackRange  = 18,
    AttackDelay  = 0.065,
    MaxHit       = 2,
    MobRange     = 300,

    -- Movement
    NoClip       = true,
    StepDelay    = 0.03,
    AntiTP       = true,

    -- Room Z
    RoomCD       = 60,   -- 60 giây = thời gian Room OpOp

    -- Dungeon
    AutoDungeon  = true,
    AutoPortal   = true,
    PortalWait   = 4,
    ClearDelay   = 4,
    AutoRetry    = true,

    -- Portal keywords
    PortalNames  = {
        "dungeon","portal","gate","enter","door",
        "entrance","warp","next","stage","floor",
        "boss","raid","arena","chamber","tomb",
    },
}

-- ══════════════════════════════════════════
--              STATE
-- ══════════════════════════════════════════
local S = {
    farming      = false,
    target       = nil,
    lastSetPos   = nil,
    antiTP       = false,
    hitCount     = 0,
    switchTarget = false,
    mobList      = {},
    lastScan     = 0,
    lastRoomZ    = 0,
    roomEnd      = 0,
    portalHistory= {},
    currentPortal= nil,
    phase        = "IDLE",
    wave         = 0,
    stats = {kills=0, deaths=0, hits=0, drops=0, portals=0, dungeons=0},
    status       = "Đang dừng",
}

-- ══════════════════════════════════════════
--              UTILITY
-- ══════════════════════════════════════════
local function log(msg)
    S.status = msg
    print("[KL v6] "..msg)
end

local function getChar()
    char     = player.Character
    if char then
        humanoid = char:FindFirstChildOfClass("Humanoid")
        root     = char:FindFirstChild("HumanoidRootPart")
    end
    return char and humanoid and root
end

local function isAlive()
    return getChar() and humanoid and humanoid.Health > 0
end

local function distTo(pos)
    if not root then return math.huge end
    return (root.Position - pos).Magnitude
end

-- ══════════════════════════════════════════
--              NOCLIP
-- ══════════════════════════════════════════
RunService.Stepped:Connect(function()
    if CONFIG.NoClip and char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- ══════════════════════════════════════════
--           ANTI TELEPORT BACK
-- ══════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.08)
        if S.antiTP and S.lastSetPos and root and S.farming then
            if (root.Position - S.lastSetPos).Magnitude > 18 then
                root.CFrame = CFrame.new(S.lastSetPos)
            end
        end
    end
end)

-- ══════════════════════════════════════════
--           TELEPORT STEP
-- ══════════════════════════════════════════
local function teleportTo(pos, fast)
    if not isAlive() then return end
    local steps = fast and 5 or 10
    local start = root.Position
    for i = 1, steps do
        if not isAlive() or not S.farming then return end
        local lp = start:Lerp(pos, i/steps)
        lp = Vector3.new(lp.X, math.max(lp.Y, 4), lp.Z)
        S.lastSetPos = lp
        root.CFrame  = CFrame.new(lp)
        task.wait(CONFIG.StepDelay)
    end
end

-- ══════════════════════════════════════════
--              TOOL
-- ══════════════════════════════════════════
local function getTool(kw)
    for _, v in ipairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.Name:lower():find(kw) then return v end
    end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and v.Name:lower():find(kw) then return v end
    end
    return nil
end

local function equip(tool)
    if tool and tool.Parent ~= char then
        humanoid:EquipTool(tool)
        task.wait(0.12)
    end
end

-- ══════════════════════════════════════════
--              AIM
-- ══════════════════════════════════════════
local function aim()
    if S.target and S.target:FindFirstChild("HumanoidRootPart") then
        root.CFrame = CFrame.new(root.Position, S.target.HumanoidRootPart.Position)
    end
end

-- ══════════════════════════════════════════
--              PRESS KEY
-- ══════════════════════════════════════════
local function press(key)
    VirtualInputManager:SendKeyEvent(true,  key, false, game)
    task.wait(0.09)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

-- ══════════════════════════════════════════
--              DODGE
-- ══════════════════════════════════════════
local lastDodge = 0
local dodgeTime = 0
local angle     = 0

local function dangerous(mob)
    if tick() - lastDodge < 1 then return false end
    if not mob then return false end
    for _, v in ipairs(mob:GetDescendants()) do
        if v:IsA("Beam") and v.Enabled then return true end
        if v:IsA("ParticleEmitter") and v.Enabled then
            local p = v.Parent
            if p and p:IsA("BasePart") then
                if (p.Position - root.Position).Magnitude < 65 then return true end
            end
        end
    end
    return false
end

-- ══════════════════════════════════════════
--           ROOM Z (60s cooldown)
-- ══════════════════════════════════════════
local function shouldUseZ()
    if S.lastRoomZ == 0 then return true end
    return tick() - S.lastRoomZ >= CONFIG.RoomCD
end

local function useRoomZ()
    log("🔵 Room hết - Dùng Z Zone Control!")
    press(Enum.KeyCode.Z)
    S.lastRoomZ = tick()
    S.roomEnd   = tick() + CONFIG.RoomCD
end

local function roomTimeLeft()
    return math.max(0, math.floor(S.roomEnd - tick()))
end

-- ══════════════════════════════════════════
--           SCAN MOB 300 STUDS
-- ══════════════════════════════════════════
local function scanMobs()
    if tick() - S.lastScan < 1 then return end
    S.lastScan = tick()
    S.mobList  = {}

    for _, v in ipairs(Workspace:GetDescendants()) do
        if not v:IsA("Model") or v == char then continue end
        if not v:FindFirstChild("HumanoidRootPart") then continue end

        local isPlayer = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character == v then isPlayer = true; break end
        end
        if isPlayer then continue end

        local hum = v:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local d = distTo(v.HumanoidRootPart.Position)
        if d <= CONFIG.MobRange then
            table.insert(S.mobList, v)
        end
    end
end

-- ══════════════════════════════════════════
--           RANDOM MOB
-- ══════════════════════════════════════════
local function getRandomMob()
    scanMobs()
    local alive = {}
    for _, v in ipairs(S.mobList) do
        if v.Parent then
            local hum = v:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(alive, v)
            end
        end
    end
    if #alive == 0 then return nil end
    if #alive == 1 then return alive[1] end
    local filtered = {}
    for _, v in ipairs(alive) do
        if v ~= S.target then table.insert(filtered, v) end
    end
    if #filtered == 0 then return alive[1] end
    return filtered[math.random(1, #filtered)]
end

-- ══════════════════════════════════════════
--           KIỂM TRA HẾT MOB
-- ══════════════════════════════════════════
local function isAreaCleared()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if not v:IsA("Model") or v == char then continue end
        local hum  = v:FindFirstChildOfClass("Humanoid")
        local root2= v:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health <= 0 or not root2 then continue end
        local isPlayer = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character == v then isPlayer = true; break end
        end
        if isPlayer then continue end
        if distTo(root2.Position) < 500 then return false end
    end
    return true
end

-- ══════════════════════════════════════════
--           NHẶT DROP
-- ══════════════════════════════════════════
local function collectDrops()
    log("🎁 Nhặt drop...")
    local keywords = {"drop","beli","chest","fragment","accessory","item","reward","loot"}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if not isAlive() or not S.farming then break end
        local name = obj.Name:lower()
        for _, kw in pairs(keywords) do
            if name:find(kw) then
                local pos = obj:IsA("BasePart") and obj.Position
                    or (obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position)
                if pos and distTo(pos) < 100 then
                    teleportTo(pos + Vector3.new(0,2,0), true)
                    task.wait(0.2)
                    S.stats.drops = S.stats.drops + 1
                end
                break
            end
        end
    end
end

-- ══════════════════════════════════════════
--           PORTAL SYSTEM
-- ══════════════════════════════════════════
local function findPortals()
    local portals = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if not obj.Parent then continue end
        local name    = obj.Name:lower()
        local isPortal = false
        for _, kw in pairs(CONFIG.PortalNames) do
            if name:find(kw) then isPortal = true; break end
        end
        if not isPortal then continue end

        local part = obj:IsA("BasePart") and obj
            or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")))
        if not part then continue end

        -- Bỏ qua cổng đã vào
        local visited = false
        for _, vPos in pairs(S.portalHistory) do
            if (part.Position - vPos).Magnitude < 25 then visited = true; break end
        end
        if visited then continue end

        local d = distTo(part.Position)
        if d < 1000 then
            table.insert(portals, {
                obj  = obj,
                part = part,
                pos  = part.Position,
                dist = d,
                name = obj.Name,
            })
        end
    end
    table.sort(portals, function(a,b) return a.dist < b.dist end)
    return portals
end

local function enterPortal(portal)
    if not portal or not isAlive() then return false end
    log("🚪 Vào cổng: "..portal.name)

    table.insert(S.portalHistory, portal.pos)
    if #S.portalHistory > 15 then table.remove(S.portalHistory, 1) end

    teleportTo(portal.pos + Vector3.new(0,3,0))
    task.wait(0.3)
    teleportTo(portal.pos)
    task.wait(0.3)

    -- Fire remote interact
    pcall(function()
        local remotes = {
            "EnterDungeon","DungeonEnter","InteractPortal",
            "UsePortal","ActivatePortal","EnterGate",
            "OpenDoor","NextFloor","NextWave","NextStage",
        }
        for _, rName in pairs(remotes) do
            local r = ReplicatedStorage:FindFirstChild(rName, true)
            if r and r:IsA("RemoteEvent") then
                r:FireServer(portal.obj)
                task.wait(0.2)
            end
        end
    end)

    S.stats.portals   = S.stats.portals + 1
    S.currentPortal   = portal
    log("✅ Đã vào cổng! Chờ load...")
    task.wait(CONFIG.PortalWait)
    return true
end

local function handlePortal()
    if not CONFIG.AutoPortal then return false end
    log("🔍 Tìm cổng dungeon...")
    local portals = findPortals()
    if #portals == 0 then
        log("❌ Không tìm thấy cổng - reset history...")
        if #S.portalHistory > 5 then S.portalHistory = {} end
        task.wait(3)
        return false
    end
    log("🚪 Tìm thấy "..#portals.." cổng")
    return enterPortal(portals[1])
end

-- ══════════════════════════════════════════
--     LOOP 1: M1 SPAM (độc lập)
-- ══════════════════════════════════════════
task.spawn(function()
    while true do
        if S.farming and S.target and dodgeTime <= 0
           and humanoid and humanoid.Health > 0 then

            local hum = S.target:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 or not S.target.Parent then
                S.target   = getRandomMob()
                S.hitCount = 0
                task.wait(0.1)
                goto continue
            end

            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                VirtualInputManager:SendMouseButtonEvent(0,0,0,true,  game,1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0,0,0,false, game,1)
                S.stats.hits = S.stats.hits + 1
                S.hitCount   = S.hitCount + 1

                if S.hitCount >= CONFIG.MaxHit then
                    S.switchTarget = true
                    S.hitCount     = 0
                end
            end
        end
        ::continue::
        task.wait(CONFIG.AttackDelay)
    end
end)

-- ══════════════════════════════════════════
--     LOOP 2: SKILL (OpOp → Kioru V2)
-- ══════════════════════════════════════════
task.spawn(function()
    while true do
        if S.farming and S.target and dodgeTime <= 0
           and humanoid and humanoid.Health > 0
           and S.target:FindFirstChild("HumanoidRootPart") then

            aim()

            -- ✅ OPOP FRUIT TRƯỚC
            local fruit = getTool("opop")
                       or getTool("op op")
                       or getTool("op-op")
                       or getTool("control")
            if fruit then
                equip(fruit)
                aim()

                -- Z khi Room hết (60s)
                if shouldUseZ() then
                    useRoomZ()
                    task.wait(0.4)
                end

                press(Enum.KeyCode.X) -- Stonecraft
                task.wait(0.1)
                press(Enum.KeyCode.C) -- Electroheart
                task.wait(0.1)
                press(Enum.KeyCode.V) -- Task Pillar
                task.wait(0.1)
                press(Enum.KeyCode.B) -- Blink
                task.wait(0.1)
                press(Enum.KeyCode.E) -- Fusion Cut
                task.wait(0.2)
            end

            -- ⚔️ KIORU V2 SAU
            local sword = getTool("kioru")
            if sword then
                equip(sword)
                aim()
                press(Enum.KeyCode.Z) -- Echo Strike
                task.wait(0.1)
                press(Enum.KeyCode.X) -- Biohazard Bolt
                task.wait(0.2)
            end

            -- Đổi con sau mỗi lượt skill
            local newMob = getRandomMob()
            if newMob then
                S.target       = newMob
                S.hitCount     = 0
                S.switchTarget = false
            end
        end
        task.wait(0.05)
    end
end)

-- ══════════════════════════════════════════
--     LOOP 3: Switch target từ M1
-- ══════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.1)
        if S.farming and S.switchTarget then
            local newMob = getRandomMob()
            if newMob then
                S.target       = newMob
                S.hitCount     = 0
                S.switchTarget = false
            end
        end
    end
end)

-- ══════════════════════════════════════════
--     MAIN LOOP: Di chuyển + Dodge + Dungeon
-- ══════════════════════════════════════════
local function startAttackLoop()
    -- Attack loop đã chạy ở trên
end

local function dungeonLoop()
    log("🎮 Bắt đầu farm dungeon!")

    -- Vào cổng đầu tiên
    handlePortal()

    while S.farming do
        -- Respawn
        if not isAlive() then
            S.stats.deaths = S.stats.deaths + 1
            log("💀 Chết ("..S.stats.deaths..") - Chờ respawn...")
            S.target = nil
            task.wait(4)
            if true then
                pcall(function()
                    local r = ReplicatedStorage:FindFirstChild("Respawn")
                    if r then r:FireServer() end
                end)
                task.wait(3)
                getChar()
                handlePortal()
            end
            continue
        end

        -- Cập nhật target
        S.target = S.target or getRandomMob()

        if S.target then
            local hum = S.target:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 or not S.target.Parent then
                S.stats.kills = S.stats.kills + 1
                S.target      = getRandomMob()
                collectDrops()
            else
                log("⚔️ "..S.target.Name.." | HP:"..math.floor(hum.Health)
                    .." | Wave:"..S.wave)
            end
        else
            -- Không có mob
            log("✅ Clear! Kiểm tra cổng tiếp...")
            collectDrops()
            task.wait(CONFIG.ClearDelay)

            S.target = getRandomMob()
            if not S.target then
                -- Thực sự hết mob → tìm cổng
                if CONFIG.AutoPortal then
                    S.wave = S.wave + 1
                    local entered = handlePortal()
                    if not entered and CONFIG.AutoRetry then
                        log("🔄 Retry dungeon mới...")
                        S.stats.dungeons = S.stats.dungeons + 1
                        S.wave           = 0
                        S.portalHistory  = {}
                        task.wait(2)
                        handlePortal()
                    end
                end
            end
        end

        task.wait(0.1)
    end

    log("⏹ Đã dừng farm!")
    S.phase = "IDLE"
end

-- ══════════════════════════════════════════
--     RENDER LOOP: Di chuyển + Dodge
-- ══════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
    if not S.farming then return end
    if not root or not root.Parent then return end
    if not humanoid or humanoid.Health <= 0 then return end

    if not S.target then
        S.target = getRandomMob()
        if not S.target then return end
    end

    if not S.target.Parent then
        S.target = getRandomMob()
        return
    end

    aim()

    if dangerous(S.target) then
        dodgeTime = 1.1
        lastDodge = tick()
    end

    if dodgeTime > 0 then
        angle -= 7 * dt
        local pos = S.target.HumanoidRootPart.Position + Vector3.new(
            math.cos(angle) * 130, 95, math.sin(angle) * 130
        )
        root.CFrame = CFrame.new(pos, S.target.HumanoidRootPart.Position)
        dodgeTime  -= dt
    else
        root.CFrame = CFrame.new(
            S.target.HumanoidRootPart.Position + Vector3.new(0,7,0),
            S.target.HumanoidRootPart.Position
        )
    end
end)

-- ══════════════════════════════════════════
--     AUTO RESPAWN
-- ══════════════════════════════════════════
player.CharacterAdded:Connect(function(newChar)
    char     = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    root     = newChar:WaitForChild("HumanoidRootPart")
    task.wait(2)
    log("🔄 Respawned!")
end)

-- ══════════════════════════════════════════
--                  GUI
-- ══════════════════════════
local old = player.PlayerGui:FindFirstChild("KLv6GUI")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name         = "KLv6GUI"
sg.ResetOnSpawn = false
sg.Parent       = player.PlayerGui

-- Main frame
local frame = Instance.new("Frame")
frame.Size                   = UDim2.new(0, 260, 0, 320)
frame.Position               = UDim2.new(0, 15, 0, 15)
frame.BackgroundColor3       = Color3.fromRGB(10,10,18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel        = 0
frame.Active                 = true
frame.Draggable              = true
frame.Parent                 = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(255,80,0); stroke.Thickness = 2

-- Title
local title = Instance.new("Frame")
title.Size             = UDim2.new(1,0,0,36)
title.BackgroundColor3 = Color3.fromRGB(200,50,0)
title.BorderSizePixel  = 0
title.Parent           = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0,14)
local titleLbl = Instance.new("TextLabel")
titleLbl.Size             = UDim2.new(1,0,1,0)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3       = Color3.new(1,1,1)
titleLbl.Text             = "👑  KING LEGACY DUNGEON v6"
titleLbl.TextScaled       = true
titleLbl.Font             = Enum.Font.GothamBold
titleLbl.Parent           = title

-- Helper tạo label
local function mkLbl(posY, color)
    local l = Instance.new("TextLabel")
    l.Size                   = UDim2.new(1,-10,0,22)
    l.Position               = UDim2.new(0,5,0,posY)
    l.BackgroundTransparency = 1
    l.TextColor3             = color or Color3.new(1,1,1)
    l.TextScaled             = true
    l.Font                   = Enum.Font.Gotham
    l.Parent                 = frame
    return l
end

local lTarget  = mkLbl(42,  Color3.fromRGB(255,210,80))
local lMob     = mkLbl(66,  Color3.fromRGB(150,220,255))
local lRoom    = mkLbl(90,  Color3.fromRGB(100,200,255))
local lCD      = mkLbl(114, Color3.fromRGB(200,255,200))
local lPortal  = mkLbl(138, Color3.fromRGB(200,150,255))
local lStats   = mkLbl(162, Color3.fromRGB(180,255,180))
lStats.Size    = UDim2.new(1,-10,0,44)

lTarget.Text  = "🎯 Target: --"
lMob.Text     = "👾 Mob: 0"
lRoom.Text    = "🔵 Room: --"
lCD.Text      = "⏱ Z CD: sẵn sàng"
lPortal.Text  = "🚪 Portal: --"
lStats.Text   = "☠0  💀0  🎁0  👊0"

-- Helper tạo button
local function mkBtn(text, posY, color)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(1,-10,0,38)
    b.Position         = UDim2.new(0,5,0,posY)
    b.BackgroundColor3 = color
    b.TextColor3       = Color3.new(1,1,1)
    b.Text             = text
    b.TextScaled       = true
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.Parent           = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    return b
end

local farmBtn   = mkBtn("▶  Bắt đầu Farm",     215, Color3.fromRGB(40,160,40))
local portalBtn = mkBtn("🚪  Auto Portal: BẬT", 260, Color3.fromRGB(100,40,180))
local noclipBtn = mkBtn("🔵  NoClip: BẬT",      305, Color3.fromRGB(0,120,200))

-- Sự kiện
farmBtn.MouseButton1Click:Connect(function()
    S.farming = not S.farming
    if S.farming then
        farmBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
        farmBtn.Text             = "⏹  Dừng Farm"
        S.antiTP                 = CONFIG.AntiTP
        S.hitCount               = 0
        S.switchTarget           = false
        S.lastRoomZ              = 0
        S.portalHistory          = {}
        S.wave                   = 0

        task.spawn(function()
            -- Equip OpOp ngay
            local fruit = getTool("opop") or getTool("op op")
                       or getTool("op-op") or getTool("control")
            if fruit then equip(fruit); log("✅ Đã equip OpOp!") end
            task.wait(0.5)
            dungeonLoop()
        end)
    else
        farmBtn.BackgroundColor3 = Color3.fromRGB(40,160,40)
        farmBtn.Text             = "▶  Bắt đầu Farm"
        S.antiTP                 = false
        S.target                 = nil
        S.hitCount               = 0
    end
end)

portalBtn.MouseButton1Click:Connect(function()
    CONFIG.AutoPortal = not CONFIG.AutoPortal
    portalBtn.Text    = CONFIG.AutoPortal
        and "🚪  Auto Portal: BẬT"
        or  "🚪  Auto Portal: TẮT"
    portalBtn.BackgroundColor3 = CONFIG.AutoPortal
        and Color3.fromRGB(100,40,180)
        or  Color3.fromRGB(50,20,80)
end)

noclipBtn.MouseButton1Click:Connect(function()
    CONFIG.NoClip   = not CONFIG.NoClip
    noclipBtn.Text  = CONFIG.NoClip and "🔵  NoClip: BẬT" or "🔵  NoClip: TẮT"
    noclipBtn.BackgroundColor3 = CONFIG.NoClip
        and Color3.fromRGB(0,180,100)
        or  Color3.fromRGB(80,80,80)
end)

-- Update UI
task.spawn(function()
    while true do
        task.wait(0.4)
        if S.farming then
            local t    = S.target
            local hum  = t and t:FindFirstChildOfClass("Humanoid")
            local hp   = hum and math.floor(hum.Health) or 0
            local tName= t and t.Name or "Đang tìm..."

            lTarget.Text = "🎯 "..tName.."  HP:"..hp
            lMob.Text    = "👾 Mob 300s: "..#S.mobList
                .."  Hit:"..S.hitCount.."/"..CONFIG.MaxHit

            -- Room
            local tl = roomTimeLeft()
            if S.lastRoomZ == 0 then
                lRoom.Text       = "🔵 Room: Chưa bật"
                lRoom.TextColor3 = Color3.fromRGB(200,200,200)
            elseif tl > 0 then
                lRoom.Text       = "🟢 Room: "..tl.."s còn lại"
                lRoom.TextColor3 = Color3.fromRGB(100,255,100)
            else
                lRoom.Text       = "🔴 Room: Hết! Dùng Z ngay!"
                lRoom.TextColor3 = Color3.fromRGB(255,80,80)
            end

            -- Z CD
            local cd = math.max(0, math.floor(CONFIG.RoomCD-(tick()-S.lastRoomZ)))
            if S.lastRoomZ == 0 or cd == 0 then
                lCD.Text       = "⚡ Z: Sẵn sàng!"
                lCD.TextColor3 = Color3.fromRGB(100,255,100)
            else
                lCD.Text       = "⏱ Z CD: "..cd.."s"
                lCD.TextColor3 = Color3.fromRGB(200,255,200)
            end

            -- Portal
            lPortal.Text = "🚪 Portal:"..S.stats.portals
                .."  Wave:"..S.wave
                .."  Dungeon:"..S.stats.dungeons

            -- Stats
            lStats.Text = string.format(
                "☠%d  💀%d  🎁%d  👊%d",
                S.stats.kills, S.stats.deaths,
                S.stats.drops, S.stats.hits
            )

            -- Track kill
            if t and t:FindFirstChildOfClass("Humanoid") then
                local h = t:FindFirstChildOfClass("Humanoid")
                if h and h.Health <= 0 then
                    S.stats.kills = S.stats.kills + 1
                    S.target      = nil
                end
            end
        else
            lTarget.Text = "🎯 Target: --"
            lMob.Text    = "👾 Mob: 0"
            lPortal.Text = "🚪 Portal: --"
        end
    end
end)

-- ══════════════════════════════════════════
--              KHỞI ĐỘNG
-- ══════════════════════════════════════════
print("╔════════════════════════════════════╗")
print("║  KING LEGACY FULL DUNGEON v6       ║")
print("║  Auto Dungeon + Portal      ✅     ║")
print("║  Z OpOp 60s cooldown        ✅     ║")
print("║  OpOp TRƯỚC Kioru V2        ✅     ║")
print("║  Random mob 300s, 2hit đổi  ✅     ║")
print("║  M1 + Skill song song       ✅     ║")
print("║  Auto Dodge + Respawn       ✅     ║")
print("╚════════════════════════════════════╝")
print("✅ Nhấn nút GUI để bắt đầu!")
