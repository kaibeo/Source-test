-- ===== WINDUI AUTO DUNGEON + FAST ATTACK (SEPARATE) =====

-- LOAD WINDUI
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main_example.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "Auto Dungeon",
    Author = "Auto Script",
    Folder = "AutoDungeon",
    Size = UDim2.fromOffset(460, 360)
})

local MainTab = Window:CreateTab("Main", "home")
local StatusTab = Window:CreateTab("Status", "info")

-- ===== GLOBAL SWITCH =====
getgenv().AutoDungeon = false
getgenv().FastAttack = false

-- ===== UI TOGGLES =====
MainTab:CreateToggle({
    Name = "AUTO DUNGEON",
    Default = false,
    Callback = function(v)
        getgenv().AutoDungeon = v
    end
})

MainTab:CreateToggle({
    Name = "FAST ATTACK",
    Default = false,
    Callback = function(v)
        getgenv().FastAttack = v
    end
})

local StatusLabel = StatusTab:CreateLabel("STATE: IDLE")

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

-- ===== CONFIG (AUTO DUNGEON) =====
local HEIGHT_NORMAL = 20
local HEIGHT_GREEN  = 10
local MOVE_SPEED = 0.6
local GREEN_HALF_RANGE = 500
local TELEPORT_DISTANCE = 180
local SCAN_INTERVAL = 0.15

-- ===== AUTO DUNGEON STATE =====
local DungeonState = "IDLE"
local lastGreenPos = nil
local lastHRPPos = nil
local scanTick = 0
local destroyActive = false

-- ===== SAFE GET =====
local function getHRPandHum()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp and hum then
        return hrp, hum
    end
end

-- ===== MOVE (AUTO DUNGEON) =====
local function MoveTo(hrp, pos, height)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = CFrame.new(
        Vector3.new(
            hrp.Position.X + (pos.X - hrp.Position.X) * MOVE_SPEED,
            pos.Y + height,
            hrp.Position.Z + (pos.Z - hrp.Position.Z) * MOVE_SPEED
        )
    )
end

-- ===== SCAN GREEN =====
local function ScanGreen(hrp)
    if os.clock() - scanTick < SCAN_INTERVAL then return end
    scanTick = os.clock()

    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            local part = v.Adornee or v.Parent
            if part and part:IsA("BasePart") then
                local dx = math.abs(part.Position.X - hrp.Position.X)
                local dz = math.abs(part.Position.Z - hrp.Position.Z)
                if dx <= GREEN_HALF_RANGE and dz <= GREEN_HALF_RANGE then
                    for _,ui in ipairs(v:GetDescendants()) do
                        if ui:IsA("TextLabel") then
                            local c = ui.TextColor3
                            if c.G > c.R and c.G > c.B then
                                lastGreenPos = part.Position
                                DungeonState = "GREEN"
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ===== SCAN DESTROY (FLAG ONLY) =====
local function ScanDestroyFlag()
    destroyActive = false
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,ui in ipairs(v:GetDescendants()) do
                if ui:IsA("TextLabel") and ui.Text and ui.Text:lower():find("destroy") then
                    destroyActive = true
                    return
                end
            end
        end
    end
end

-- ===== AUTO DUNGEON LOOP =====
RunService.Heartbeat:Connect(function()
    local hrp, hum = getHRPandHum()
    if not hrp or not hum then return end

    if getgenv().AutoDungeon then
        -- DIE
        if hum.Health <= 0 then
            DungeonState = "RETURN_GREEN"
            StatusLabel:SetText("STATE: RETURN_GREEN")
            return
        end

        -- TELEPORT
        if lastHRPPos and (hrp.Position - lastHRPPos).Magnitude > TELEPORT_DISTANCE then
            DungeonState = "SEARCH"
        end
        lastHRPPos = hrp.Position

        ScanGreen(hrp)
        ScanDestroyFlag()

        if DungeonState == "GREEN" and lastGreenPos then
            StatusLabel:SetText(destroyActive and "STATE: GREEN (DESTROY PHASE)" or "STATE: GREEN")
            MoveTo(hrp, lastGreenPos, HEIGHT_GREEN)
            return
        end

        StatusLabel:SetText("STATE: HOVER")
        MoveTo(hrp, hrp.Position, HEIGHT_NORMAL)
    end
end)

-- ===================================================
-- ================= FAST ATTACK =====================
-- ===================================================

local remote, idremote
for _, v in next, ({
    game.ReplicatedStorage.Util,
    game.ReplicatedStorage.Common,
    game.ReplicatedStorage.Remotes,
    game.ReplicatedStorage.Assets,
    game.ReplicatedStorage.FX
}) do
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
    while task.wait(0.05) do
        if not getgenv().FastAttack then continue end

        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local parts = {}
        for _, x in ipairs({Workspace.Enemies, Workspace.Characters}) do
            for _, v in ipairs(x and x:GetChildren() or {}) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if v ~= char and hrp and hum and hum.Health > 0 and
                   (hrp.Position - root.Position).Magnitude <= 60 then
                    for _, bp in ipairs(v:GetChildren()) do
                        if bp:IsA("BasePart") then
                            parts[#parts+1] = {v, bp}
                        end
                    end
                end
            end
        end

        local tool = char:FindFirstChildOfClass("Tool")
        if #parts > 0 and tool and
           (tool:GetAttribute("WeaponType") == "Melee" or tool:GetAttribute("WeaponType") == "Sword") then
            pcall(function()
                require(game.ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit", true)
                game.ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()

                local head = parts[1][1]:FindFirstChild("Head")
                if not head then return end

                game.ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(
                    head, parts, {},
                    tostring(LP.UserId):sub(2,4) .. tostring(os.clock()):sub(6,10)
                )

                if remote and idremote then
                    cloneref(remote):FireServer(
                        string.gsub("RE/RegisterHit", ".", function(c)
                            return string.char(bit32.bxor(
                                string.byte(c),
                                math.floor(Workspace:GetServerTimeNow() / 10 % 10) + 1
                            ))
                        end),
                        bit32.bxor(
                            idremote + 909090,
                            game.ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2
                        ),
                        head, parts
                    )
                end
            end)
        end
    end
end)