--================== WAIT LOAD (FIX HOP BUG) ==================
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
repeat task.wait()
until lp
and lp:FindFirstChild("leaderstats")
and lp.leaderstats:FindFirstChild("Level")

--================== SERVICES ==================
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera

--================== SETTINGS ==================
local ENABLE = true

-- Fly
local SPEED = 60
local OFFSET = Vector3.new(0,0,-4)
local WAIT_AFTER_TARGET = 1.2

-- M1
local M1_MIN, M1_MAX = 2,3
local M1_DELAY = 0.25

-- Level
local MAX_LEVEL_DIFF = 300

-- Aim / Look
local AIM_ENABLED = true
local LOOK_ENABLED = true
local AIM_PART = "HumanoidRootPart"
local AIM_SMOOTH = 0.18
local PREDICTION = 0.12
local MAX_LOOK_DISTANCE = 300

--================== GLOBAL ==================
_G.CurrentTarget = nil
local VisitedPlayers = {}

--================== UTILS ==================
local function isMarine()
    return lp.Team and lp.Team.Name and string.lower(lp.Team.Name):find("marine")
end

local function getLevel(plr)
    local stats = plr:FindFirstChild("leaderstats")
    local lvl = stats and stats:FindFirstChild("Level")
    return (lvl and tonumber(lvl.Value)) or nil
end

--================== SERVER HOP ==================
local function serverHop()
    local placeId = game.PlaceId
    local cursor = ""
    repeat
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?limit=100"
            ..(cursor ~= "" and "&cursor="..cursor or "")
        local data = HttpService:JSONDecode(game:HttpGet(url))
        for _, s in pairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(placeId, s.id, lp)
                return
            end
        end
        cursor = data.nextPageCursor or ""
    until cursor == ""
end

--================== GET TARGET (FIXED) ==================
local function getTarget()
    local list = {}
    local myLevel = getLevel(lp)

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= lp
        and not VisitedPlayers[plr.UserId]
        and plr.Character
        and plr.Character:FindFirstChild("Humanoid")
        and plr.Character:FindFirstChild("HumanoidRootPart") then

            -- Team rule
            if isMarine() and plr.Team == lp.Team then
                continue
            end

            -- Level rule (chỉ lọc khi có level)
            local lv = getLevel(plr)
            if myLevel and lv then
                if math.abs(lv - myLevel) > MAX_LEVEL_DIFF then
                    continue
                end
            end

            table.insert(list, plr)
        end
    end

    if #list > 0 then
        return list[math.random(#list)]
    end
    return nil
end

--================== FLY ==================
local function flyTo(hrpTarget)
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dist = (hrp.Position - hrpTarget.Position).Magnitude
    local time = math.clamp(dist / SPEED, 0.6, 1.8)

    TweenService:Create(
        hrp,
        TweenInfo.new(time, Enum.EasingStyle.Linear),
        {CFrame = hrpTarget.CFrame * CFrame.new(OFFSET)}
    ):Play()
    task.wait(time)
end

--================== M1 ==================
local function doM1(count)
    for _=1,count do
        VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0)
        VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0)
        task.wait(M1_DELAY)
    end
end

--================== MAIN COMBAT LOOP ==================
task.spawn(function()
    while ENABLE do
        pcall(function()
            local target = getTarget()
            if not target then
                task.wait(2)
                if next(VisitedPlayers) ~= nil then
                    serverHop()
                end
                return
            end

            local char = target.Character
            local hum = char.Humanoid
            local oldHp = hum.Health

            _G.CurrentTarget = target
            flyTo(char.HumanoidRootPart)

            -- test PvP
            doM1(math.random(M1_MIN,M1_MAX))
            task.wait(0.3)

            -- PvP OFF → skip
            if hum.Health >= oldHp then
                VisitedPlayers[target.UserId] = true
                _G.CurrentTarget = nil
                return
            end

            -- PvP ON → kill
            while hum.Health > 0 and ENABLE do
                flyTo(char.HumanoidRootPart)
                doM1(2)
                task.wait(0.2)
            end

            _G.CurrentTarget = nil
        end)
        task.wait(WAIT_AFTER_TARGET)
    end
end)

--================== ESP ALL PLAYERS ==================
local ESP_CACHE = {}

local function createESP(plr)
    if plr == lp or ESP_CACHE[plr] then return end

    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0,220,0,55)
    gui.StudsOffset = Vector3.new(0,3,0)
    gui.AlwaysOnTop = true

    local name = Instance.new("TextLabel",gui)
    name.Size = UDim2.new(1,0,0.5,0)
    name.BackgroundTransparency = 1
    name.TextScaled = true
    name.Font = Enum.Font.GothamBold
    name.TextStrokeTransparency = 0

    local info = Instance.new("TextLabel",gui)
    info.Position = UDim2.new(0,0,0.5,0)
    info.Size = UDim2.new(1,0,0.5,0)
    info.BackgroundTransparency = 1
    info.TextScaled = true
    info.Font = Enum.Font.Gotham
    info.TextStrokeTransparency = 0

    ESP_CACHE[plr] = {Gui=gui,Name=name,Info=info}

    local function attach(c)
        local hrp = c:WaitForChild("HumanoidRootPart",5)
        if hrp then gui.Parent = hrp end
    end
    if plr.Character then attach(plr.Character) end
    plr.CharacterAdded:Connect(attach)
end

for _,p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

RunService.RenderStepped:Connect(function()
    local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    for plr,data in pairs(ESP_CACHE) do
        local c = plr.Character
        local h = c and c:FindFirstChild("Humanoid")
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if h and hrp then
            local d = (myHrp.Position-hrp.Position).Magnitude
            data.Gui.Enabled = true
            data.Name.Text = plr.Name
            data.Name.TextColor3 =
                (_G.CurrentTarget==plr) and Color3.fromRGB(255,0,0)
                or ((plr.Team==lp.Team) and Color3.fromRGB(0,170,255) or Color3.fromRGB(255,80,80))
            data.Info.Text = string.format("%.0f m | %.0f HP | Lv.%s",d,h.Health,getLevel(plr) or "?")
        else
            data.Gui.Enabled=false
        end
    end
end)

--================== LOOK / AIM (STARE TARGET) ==================
RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED and not LOOK_ENABLED then return end
    local t = _G.CurrentTarget
    if not t or not t.Character then return end
    local part = t.Character:FindFirstChild(AIM_PART)
    local hum = t.Character:FindFirstChild("Humanoid")
    if not part or not hum or hum.Health<=0 then return end

    if (Camera.CFrame.Position-part.Position).Magnitude > MAX_LOOK_DISTANCE then return end

    local vel = part.AssemblyLinearVelocity or Vector3.zero
    local pos = part.Position + vel * PREDICTION
    Camera.CFrame = Camera.CFrame:Lerp(
        CFrame.new(Camera.CFrame.Position,pos),
        AIM_SMOOTH
    )
end)