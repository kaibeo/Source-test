--================== WAIT LOAD ==================
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
repeat task.wait()
until lp
and lp.Character
and lp:FindFirstChild("leaderstats")
and lp.leaderstats:FindFirstChild("Level")

--================== SERVICES ==================
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera

-- Optional services (PC vs Mobile)
local VIM = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil
local VU  = pcall(function() return game:GetService("VirtualUser") end) and game:GetService("VirtualUser") or nil

--================== SETTINGS ==================
local ENABLE = true
local OFFSET = Vector3.new(0,0,-3)
local WAIT_AFTER_TARGET = 1.0
local MAX_LEVEL_DIFF = 300

-- Aim / Look (cross-platform)
local LOOK_ENABLED = true
local LOOK_PART = "HumanoidRootPart"
local LOOK_PREDICTION = 0.1
local MAX_LOOK_DISTANCE = 300
local LOOK_SMOOTH = 0.2

--================== GLOBAL ==================
_G.CurrentTarget = nil
local Visited = {}

--================== UTILS ==================
local function isMarine()
    return lp.Team and lp.Team.Name and string.lower(lp.Team.Name):find("marine")
end

local function getLevel(plr)
    local stats = plr:FindFirstChild("leaderstats")
    local lv = stats and stats:FindFirstChild("Level")
    return lv and tonumber(lv.Value) or nil
end

--================== SERVER HOP ==================
local function serverHop()
    local pid = game.PlaceId
    local cursor = ""
    repeat
        local url = "https://games.roblox.com/v1/games/"..pid.."/servers/Public?limit=100"
            ..(cursor ~= "" and "&cursor="..cursor or "")
        local data = HttpService:JSONDecode(game:HttpGet(url))
        for _, s in pairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(pid, s.id, lp)
                return
            end
        end
        cursor = data.nextPageCursor or ""
    until cursor == ""
end

--================== TARGET ==================
local function getTarget()
    local list = {}
    local myLv = getLevel(lp)

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= lp
        and not Visited[plr.UserId]
        and plr.Character
        and plr.Character:FindFirstChild("Humanoid")
        and plr.Character:FindFirstChild("HumanoidRootPart") then

            if isMarine() and plr.Team == lp.Team then continue end

            local lv = getLevel(plr)
            if myLv and lv and math.abs(lv - myLv) > MAX_LEVEL_DIFF then
                continue
            end

            table.insert(list, plr)
        end
    end

    if #list > 0 then
        return list[math.random(#list)]
    end
end

--================== MOVE ==================
local function tpTo(hrp)
    local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if myHrp then
        myHrp.CFrame = hrp.CFrame * CFrame.new(OFFSET)
    end
end

--================== M1 (AUTO PC/MOBILE) ==================
local function doM1(count)
    for i = 1, count do
        if VIM then
            -- PC
            VIM:SendMouseButtonEvent(0,0,0,true,game,0)
            VIM:SendMouseButtonEvent(0,0,0,false,game,0)
        elseif VU then
            -- Mobile
            VU:Button1Down(Vector2.new(0,0), Camera.CFrame)
            task.wait(0.05)
            VU:Button1Up(Vector2.new(0,0), Camera.CFrame)
        end
        task.wait(0.25)
    end
end

--================== LOOK AT TARGET ==================
RunService.RenderStepped:Connect(function()
    if not LOOK_ENABLED then return end
    local t = _G.CurrentTarget
    if not t or not t.Character then return end
    local part = t.Character:FindFirstChild(LOOK_PART)
    local hum = t.Character:FindFirstChild("Humanoid")
    if not part or not hum or hum.Health <= 0 then return end
    if (Camera.CFrame.Position - part.Position).Magnitude > MAX_LOOK_DISTANCE then return end

    local vel = part.AssemblyLinearVelocity or Vector3.zero
    local pos = part.Position + vel * LOOK_PREDICTION
    Camera.CFrame = Camera.CFrame:Lerp(
        CFrame.new(Camera.CFrame.Position, pos),
        LOOK_SMOOTH
    )
end)

--================== ESP ALL PLAYERS ==================
local ESP = {}
local function makeESP(plr)
    if plr == lp or ESP[plr] then return end
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0,220,0,55)
    gui.StudsOffset = Vector3.new(0,3,0)
    gui.AlwaysOnTop = true

    local name = Instance.new("TextLabel", gui)
    name.Size = UDim2.new(1,0,0.5,0)
    name.BackgroundTransparency = 1
    name.TextScaled = true
    name.Font = Enum.Font.GothamBold
    name.TextStrokeTransparency = 0

    local info = Instance.new("TextLabel", gui)
    info.Position = UDim2.new(0,0,0.5,0)
    info.Size = UDim2.new(1,0,0.5,0)
    info.BackgroundTransparency = 1
    info.TextScaled = true
    info.Font = Enum.Font.Gotham
    info.TextStrokeTransparency = 0

    ESP[plr] = {Gui=gui,Name=name,Info=info}

    local function attach(c)
        local hrp = c:WaitForChild("HumanoidRootPart",5)
        if hrp then gui.Parent = hrp end
    end
    if plr.Character then attach(plr.Character) end
    plr.CharacterAdded:Connect(attach)
end

for _,p in pairs(Players:GetPlayers()) do makeESP(p) end
Players.PlayerAdded:Connect(makeESP)
Players.PlayerRemoving:Connect(function(p)
    if ESP[p] then ESP[p].Gui:Destroy() ESP[p]=nil end
end)

RunService.RenderStepped:Connect(function()
    local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    for plr,data in pairs(ESP) do
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
            data.Info.Text = string.format("%.0f m | %.0f HP | Lv.%s", d, h.Health, getLevel(plr) or "?")
        else
            data.Gui.Enabled = false
        end
    end
end)

--================== MAIN LOOP ==================
task.spawn(function()
    while ENABLE do
        local target = getTarget()
        if not target then
            task.wait(2)
            if next(Visited) then serverHop() end
            continue
        end

        local char = target.Character
        local hum = char.Humanoid
        local oldHp = hum.Health

        _G.CurrentTarget = target
        tpTo(char.HumanoidRootPart)

        -- Test PvP
        doM1(2)
        task.wait(0.4)

        if hum.Health >= oldHp then
            -- PvP OFF
            Visited[target.UserId] = true
            _G.CurrentTarget = nil
            task.wait(WAIT_AFTER_TARGET)
            continue
        end

        -- PvP ON -> kill
        while hum.Health > 0 and ENABLE do
            tpTo(char.HumanoidRootPart)
            doM1(2)
            task.wait(0.2)
        end

        _G.CurrentTarget = nil
        task.wait(WAIT_AFTER_TARGET)
    end
end)