--// SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera

--// PLAYER
local lp = Players.LocalPlayer

--// GLOBAL TARGET (AIM + COMBAT)
_G.CurrentTarget = nil

--// SETTINGS
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

-- Aim
local AIM_ENABLED = true
local AIM_PART = "HumanoidRootPart"
local AIM_SMOOTH = 0.18
local PREDICTION = 0.12
local MAX_AIM_DISTANCE = 300
local FOV_RADIUS = 120

-- ESP
local ESP_ENABLED = true
local MAX_ESP_DISTANCE = 3000

--// UTILS
local VisitedPlayers = {}

local function isMarine()
    return lp.Team and lp.Team.Name and string.lower(lp.Team.Name):find("marine")
end

local function getLevel(plr)
    local stats = plr:FindFirstChild("leaderstats")
    local lvl = stats and stats:FindFirstChild("Level")
    return lvl and lvl.Value or nil
end

--// SERVER HOP
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

--// GET TARGET
local function getTarget()
    local list = {}
    local myLv = getLevel(lp)
    if not myLv then return nil end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= lp
        and not VisitedPlayers[plr.UserId]
        and plr.Character
        and plr.Character:FindFirstChild("Humanoid")
        and plr.Character:FindFirstChild("HumanoidRootPart") then

            if isMarine() and plr.Team == lp.Team then continue end

            local lv = getLevel(plr)
            if not lv or math.abs(lv - myLv) > MAX_LEVEL_DIFF then continue end

            table.insert(list, plr)
        end
    end

    if #list > 0 then
        return list[math.random(#list)]
    end
end

--// FLY
local function flyTo(hrpTarget)
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dist = (hrp.Position - hrpTarget.Position).Magnitude
    local time = math.clamp(dist / SPEED, 0.6, 1.8)

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(time, Enum.EasingStyle.Linear),
        {CFrame = hrpTarget.CFrame * CFrame.new(OFFSET)}
    )
    tween:Play()
    tween.Completed:Wait()
end

--// M1
local function doM1(count)
    for _=1,count do
        VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0)
        VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0)
        task.wait(M1_DELAY)
    end
end

--// MAIN COMBAT LOOP
task.spawn(function()
    while ENABLE do
        pcall(function()
            local target = getTarget()
            if not target then
                serverHop()
                return
            end

            local char = target.Character
            local hum = char.Humanoid
            local oldHp = hum.Health

            _G.CurrentTarget = target
            flyTo(char.HumanoidRootPart)

            doM1(math.random(M1_MIN,M1_MAX))
            task.wait(0.3)

            VisitedPlayers[target.UserId] = true

            if hum.Health >= oldHp then
                _G.CurrentTarget = nil
                return
            end

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

--// ESP
local ESP_CACHE = {}

local function createESP(plr)
    if plr == lp or ESP_CACHE[plr] then return end
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0,200,0,50)
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
Players.PlayerRemoving:Connect(function(p)
    if ESP_CACHE[p] then ESP_CACHE[p].Gui:Destroy() ESP_CACHE[p]=nil end
end)

RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then return end
    local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    for plr,data in pairs(ESP_CACHE) do
        local c = plr.Character
        local h = c and c:FindFirstChild("Humanoid")
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if h and hrp then
            local d = (myHrp.Position-hrp.Position).Magnitude
            data.Gui.Enabled = d <= MAX_ESP_DISTANCE
            data.Name.Text = plr.Name
            data.Name.TextColor3 = (plr.Team==lp.Team) and Color3.fromRGB(0,170,255) or Color3.fromRGB(255,80,80)
            data.Info.Text = string.format("%.0f m | %.0f HP | Lv.%s",d,h.Health,getLevel(plr) or "?")
        else
            data.Gui.Enabled=false
        end
    end
end)

--// AIM FOV
local FOV = Drawing.new("Circle")
FOV.Color = Color3.fromRGB(255,255,255)
FOV.Thickness = 1.5
FOV.NumSides = 64
FOV.Filled = false

local function center()
    local v = Camera.ViewportSize
    return Vector2.new(v.X/2,v.Y/2)
end

RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED then FOV.Visible=false return end
    FOV.Visible=true
    FOV.Radius=FOV_RADIUS
    FOV.Position=center()

    local t = _G.CurrentTarget
    if not t or not t.Character or not t.Character:FindFirstChild(AIM_PART) then return end
    local part = t.Character[AIM_PART]
    if (Camera.CFrame.Position-part.Position).Magnitude > MAX_AIM_DISTANCE then return end

    local vel = part.AssemblyLinearVelocity or Vector3.zero
    local pos = part.Position + vel*PREDICTION
    Camera.CFrame = Camera.CFrame:Lerp(
        CFrame.new(Camera.CFrame.Position,pos),
        AIM_SMOOTH
    )
end)
