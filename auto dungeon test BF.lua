--==================================================
-- AUTO DUNGEON FULL FINAL (NO MISSING FEATURES)
-- Destroy Priority | Green Auto | Die Return | Shadow Skip
-- Fast Attack: KEEP USER VERSION
-- PC + Mobile | Delta OK
--==================================================

---------------- SERVICES ----------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer

---------------- CONFIG ----------------
local HEIGHT_FARM   = 20   -- farm / destroy
local HEIGHT_GREEN  = 7    -- green / return
local MOVE_SPEED    = 0.6
local TELEPORT_DIST = 180

---------------- STATE ----------------
local LastGreenPos = nil
local LastHRPPos = nil
local ReturnAfterDie = false

local IgnoredEnemies = {}
local DamageCheck = {}

---------------- SAFE GET ----------------
local function getHRPandHum()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hrp and hum then
        return hrp, hum
    end
end

---------------- LOCK Y ----------------
local function LockY(hrp)
    local bp = hrp:FindFirstChild("LOCK_Y")
    if not bp then
        bp = Instance.new("BodyPosition")
        bp.Name = "LOCK_Y"
        bp.MaxForce = Vector3.new(0, math.huge, 0)
        bp.P = 60000
        bp.D = 1500
        bp.Parent = hrp
    end
    bp.Position = Vector3.new(0, hrp.Position.Y, 0)
end

---------------- MOVE ----------------
local function MoveTo(hrp, pos, height)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = hrp.CFrame:Lerp(
        CFrame.new(pos.X, pos.Y + height, pos.Z),
        MOVE_SPEED
    )
end

---------------- FIND DESTROY ----------------
local function FindNearestDestroy()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, dist = nil, math.huge
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,t in ipairs(v:GetDescendants()) do
                if t:IsA("TextLabel") and t.Text and t.Text:lower():find("destroy") then
                    local part = v.Adornee or v.Parent
                    if part and part:IsA("BasePart") then
                        local d = (part.Position - hrp.Position).Magnitude
                        if d < dist then
                            dist = d
                            nearest = part
                        end
                    end
                end
            end
        end
    end
    return nearest
end

---------------- SCAN GREEN (COLOR ONLY) ----------------
local function ScanGreen()
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") then
            for _,t in ipairs(v:GetDescendants()) do
                if t:IsA("TextLabel") then
                    local c = t.TextColor3
                    if c.G > c.R and c.G > c.B then
                        local part = v.Adornee or v.Parent
                        if part and part:IsA("BasePart") then
                            LastGreenPos = part.Position
                        end
                    end
                end
            end
        end
    end
end

---------------- BUG ENEMY CHECK ----------------
local function IsBugEnemy(model)
    if IgnoredEnemies[model] then return true end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return true end

    local now = os.clock()
    local data = DamageCheck[model]
    if not data then
        DamageCheck[model] = {hp = hum.Health, tick = now}
        return false
    end

    if now - data.tick >= 1.5 then
        if hum.Health >= data.hp - 1 then
            IgnoredEnemies[model] = true
            DamageCheck[model] = nil
            return true
        else
            data.hp = hum.Health
            data.tick = now
        end
    end
    return false
end

---------------- FIND ENEMY ----------------
local function FindNearestEnemy(hrp)
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local best, dist = nil, math.huge
    for _,v in ipairs(enemies:GetChildren()) do
        local hum = v:FindFirstChildOfClass("Humanoid")
        local r = v:FindFirstChild("HumanoidRootPart")
        if hum and r and hum.Health > 0 then
            if v.Name:lower():find("shadow") then
                IgnoredEnemies[v] = true
                continue
            end
            if IsBugEnemy(v) then
                continue
            end
            local d = (r.Position - hrp.Position).Magnitude
            if d < dist then
                dist = d
                best = r
            end
        end
    end
    return best
end

---------------- MAIN LOOP ----------------
RunService.Heartbeat:Connect(function()
    local hrp, hum = getHRPandHum()
    if not hrp or not hum then return end

    LockY(hrp)

    -- DIE
    if hum.Health <= 0 then
        if LastGreenPos then ReturnAfterDie = true end
        return
    end

    -- TELEPORT MAP
    if LastHRPPos and (hrp.Position - LastHRPPos).Magnitude > TELEPORT_DIST then
        ReturnAfterDie = false
    end
    LastHRPPos = hrp.Position

    -- RETURN AFTER DIE
    if ReturnAfterDie and LastGreenPos then
        MoveTo(hrp, LastGreenPos, HEIGHT_GREEN)
        if (hrp.Position - LastGreenPos).Magnitude < 10 then
            ReturnAfterDie = false
        end
        return
    end

    -- DESTROY PRIORITY
    local destroy = FindNearestDestroy()
    if destroy then
        MoveTo(hrp, destroy.Position, HEIGHT_FARM)
        return
    end

    -- FARM ENEMY
    local enemy = FindNearestEnemy(hrp)
    if enemy then
        MoveTo(hrp, enemy.Position, HEIGHT_FARM)
        return
    end

    -- GO GREEN
    ScanGreen()
    if LastGreenPos then
        MoveTo(hrp, LastGreenPos, HEIGHT_GREEN)
    end
end)