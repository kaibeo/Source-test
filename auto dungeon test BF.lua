-- ===== AUTO DUNGEON + FAST ATTACK (ONE BUTTON | STABLE) =====

-- UI LIB
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"
))()

local Window = Library:CreateWindow({
    Title = "Auto Dungeon",
    Center = true,
    AutoShow = true,
})

local MainTab = Window:AddTab("Main")
local StatusTab = Window:AddTab("Status")

getgenv().AutoDungeon = false
getgenv().FastAttack = false

MainTab:AddToggle("AutoDungeon", {
    Text = "AUTO DUNGEON",
    Default = false,
    Callback = function(v)
        getgenv().AutoDungeon = v
        getgenv().FastAttack = v -- 🔗 bật dungeon = bật fast attack
    end
})

local StatusLabel = StatusTab:AddLabel("STATE: OFF")

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

-- ===== CONFIG =====
local HEIGHT_NORMAL = 20
local HEIGHT_GREEN  = 10
local MOVE_SPEED = 0.6
local TELEPORT_DISTANCE = 180
local GREEN_HALF_RANGE = 500
local SCAN_INTERVAL = 0.15

-- ===== STATE =====
local State = "OFF"
local lastGreenPos = nil
local lastHRPPos = nil
local scanTick = 0

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

-- ===== MOVE (LOCK Y | NO LOOK) =====
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
                                State = "GREEN"
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ===== MAIN MOVE LOOP =====
RunService.Heartbeat:Connect(function()
    if not getgenv().AutoDungeon then
        State = "OFF"
        StatusLabel:SetText("STATE: OFF")
        return
    end

    local hrp, hum = getHRPandHum()
    if not hrp or not hum then return end

    if hum.Health <= 0 then
        State = "RETURN_GREEN"
        return
    end

    if lastHRPPos and (hrp.Position - lastHRPPos).Magnitude > TELEPORT_DISTANCE then
        State = "SEARCH"
    end
    lastHRPPos = hrp.Position

    if State == "RETURN_GREEN" and lastGreenPos then
        StatusLabel:SetText("STATE: RETURN_GREEN")
        MoveTo(hrp, lastGreenPos, HEIGHT_GREEN)
        return
    end

    ScanGreen(hrp)
    if State == "GREEN" and lastGreenPos then
        StatusLabel:SetText("STATE: GREEN")
        MoveTo(hrp, lastGreenPos, HEIGHT_GREEN)
        return
    end

    StatusLabel:SetText("STATE: HOVER")
    MoveTo(hrp, hrp.Position, HEIGHT_NORMAL)
end)

-- =================================================================
-- ====================== FAST ATTACK (FIXED) ======================
-- =================================================================

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
    while task.wait(0.05) do -- ✅ FIX: an toàn, vẫn rất nhanh
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