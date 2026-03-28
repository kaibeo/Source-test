--[[
    King Legacy - Dungeon Farm Helper (client-side)
    - Ưu tiên quái có dấu hiệu màu đỏ / đầu lâu trên đầu
    - Bay bám theo quái trong dungeon, hạn chế độ trễ bằng Heartbeat
    - Khóa mặt vào đầu quái lúc bắt đầu engage
    - Tự né skill cơ bản bằng strafe + đổi cao độ khi phát hiện nguy hiểm gần
    - Khi farm xong mục tiêu sẽ bỏ khóa trục Y (unlock Y)

    Lưu ý:
    + Script chỉ tự chạy khi nhân vật ở trong dungeon (lọc theo tên map/model)
    + Đây là helper mẫu, bạn có thể chỉnh SETTINGS bên dưới theo ping/FPS của bạn
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer

local SETTINGS = {
    Enabled = true,

    -- Dungeon filter: chỉ chạy khi tìm thấy model chứa các từ khóa này trong workspace
    DungeonKeywords = { "dungeon", "raid", "castle", "instance" },

    -- Targeting
    MaxTargetDistance = 450,
    RequireRedOrSkull = true,

    -- Follow / fly
    FollowDistance = 5.5,
    BaseHeight = 10,
    SmoothFollow = 0.35, -- 0..1 (cao = bám nhanh hơn)

    -- Combat
    AutoAttackKey = Enum.KeyCode.Z, -- fallback nếu game dùng key skill cơ bản
    AttackInterval = 0.08,

    -- Evade
    EvadeScanRadius = 36,
    EvadeStrafeRadius = 7,
    EvadeHeightBoost = 9,
    EvadeCooldown = 0.9,

    Verbose = false,
}

local state = {
    target = nil,
    lastAttack = 0,
    lastEvade = 0,
    strafeSign = 1,
    yUnlocked = true,
}

local function log(...)
    if SETTINGS.Verbose then
        print("[DungeonFarm]", ...)
    end
end

local function charParts()
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, hrp, hum
end

local function isAlive(model)
    if not model then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    return hum and hum.Health > 0 and hrp
end

local function hasRedOrSkullMarker(mob)
    if not mob then return false end

    for _, obj in ipairs(mob:GetDescendants()) do
        if obj:IsA("Highlight") then
            local c = obj.FillColor
            if c and c.R > 0.8 and c.G < 0.3 and c.B < 0.3 then
                return true
            end
        elseif obj:IsA("BillboardGui") then
            local name = string.lower(obj.Name)
            if name:find("skull") or name:find("dau") or name:find("head") then
                return true
            end
            for _, guiChild in ipairs(obj:GetDescendants()) do
                if guiChild:IsA("ImageLabel") then
                    local img = string.lower(guiChild.Image or "")
                    if img:find("skull") then
                        return true
                    end
                end
                if guiChild:IsA("TextLabel") then
                    local t = string.lower(guiChild.Text or "")
                    if t:find("☠") or t:find("skull") then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function findDungeonRoot()
    for _, inst in ipairs(Workspace:GetChildren()) do
        local lower = string.lower(inst.Name)
        for _, kw in ipairs(SETTINGS.DungeonKeywords) do
            if lower:find(kw) then
                return inst
            end
        end
    end
    return nil
end

local function inDungeon()
    local dungeon = findDungeonRoot()
    if not dungeon then
        return false
    end

    local _, hrp = charParts()
    if not hrp then return false end

    local p = hrp.Position
    local inBox = false

    for _, part in ipairs(dungeon:GetDescendants()) do
        if part:IsA("BasePart") then
            local localPos = part.CFrame:PointToObjectSpace(p)
            local half = part.Size * 0.5
            if math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y + 30 and math.abs(localPos.Z) <= half.Z then
                inBox = true
                break
            end
        end
    end

    return inBox
end

local function isMob(model)
    if model == LP.Character then return false end
    if not model:IsA("Model") then return false end

    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end

    local lname = string.lower(model.Name)
    if lname:find("player") then return false end

    return hum.Health > 0
end

local function chooseTarget()
    local _, myHRP = charParts()
    if not myHRP then return nil end

    local best, bestScore = nil, math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isMob(obj) then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local dist = (hrp.Position - myHRP.Position).Magnitude
            if dist <= SETTINGS.MaxTargetDistance then
                local passMarker = (not SETTINGS.RequireRedOrSkull) or hasRedOrSkullMarker(obj)
                if passMarker then
                    local score = dist
                    if hasRedOrSkullMarker(obj) then
                        score -= 40
                    end
                    if score < bestScore then
                        best = obj
                        bestScore = score
                    end
                end
            end
        end
    end

    return best
end

local function isDangerProjectile(part)
    if not part:IsA("BasePart") then return false end
    if part:IsDescendantOf(LP.Character) then return false end

    local lower = string.lower(part.Name)
    if lower:find("skill") or lower:find("projectile") or lower:find("slash") or lower:find("hitbox") or lower:find("aoe") then
        return true
    end

    local v = part.AssemblyLinearVelocity.Magnitude
    if v > 70 and part.Size.Magnitude > 1.5 then
        return true
    end

    return false
end

local function shouldEvade(myHRP)
    local now = tick()
    if now - state.lastEvade < SETTINGS.EvadeCooldown then
        return false
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and isDangerProjectile(obj) then
            if (obj.Position - myHRP.Position).Magnitude <= SETTINGS.EvadeScanRadius then
                state.lastEvade = now
                state.strafeSign *= -1
                return true
            end
        end
    end

    return false
end

local function getHeadOrRoot(target)
    return target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
end

local function quickAttack()
    local now = tick()
    if now - state.lastAttack < SETTINGS.AttackInterval then
        return
    end
    state.lastAttack = now

    pcall(function()
        game:GetService("VirtualInputManager"):SendKeyEvent(true, SETTINGS.AutoAttackKey, false, game)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, SETTINGS.AutoAttackKey, false, game)
    end)
end

RunService.Heartbeat:Connect(function(dt)
    if not SETTINGS.Enabled then return end

    local char, myHRP, myHum = charParts()
    if not char or not myHRP or not myHum or myHum.Health <= 0 then
        state.target = nil
        return
    end

    if not inDungeon() then
        state.target = nil
        state.yUnlocked = true
        return
    end

    if not isAlive(state.target) then
        state.target = chooseTarget()
        if state.target then
            state.yUnlocked = false -- khóa y lúc bắt đầu bám quái
            log("Target:", state.target.Name)
        else
            state.yUnlocked = true
            return
        end
    end

    local target = state.target
    local targetPart = getHeadOrRoot(target)
    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    if not targetPart or not targetHRP then
        state.target = nil
        state.yUnlocked = true
        return
    end

    local evadeNow = shouldEvade(myHRP)

    local targetPos = targetHRP.Position
    local forward = targetHRP.CFrame.LookVector
    local right = targetHRP.CFrame.RightVector * (SETTINGS.EvadeStrafeRadius * state.strafeSign)

    local wantedPos = targetPos - (forward * SETTINGS.FollowDistance) + Vector3.new(0, SETTINGS.BaseHeight, 0)

    if evadeNow then
        wantedPos += right + Vector3.new(0, SETTINGS.EvadeHeightBoost, 0)
    end

    local alpha = math.clamp(SETTINGS.SmoothFollow * (dt * 60), 0, 1)
    local smoothPos = myHRP.Position:Lerp(wantedPos, alpha)

    -- Khóa mặt vào đầu quái lúc đầu: luôn lookAt Head/Root
    local lookPos = targetPart.Position

    if state.yUnlocked then
        -- Sau khi farm xong mục tiêu thì bỏ khóa y
        local _, currentHRP = charParts()
        if currentHRP then
            smoothPos = Vector3.new(smoothPos.X, currentHRP.Position.Y, smoothPos.Z)
        end
    end

    myHRP.CFrame = CFrame.new(smoothPos, lookPos)

    quickAttack()
end)

print("[DungeonFarm] Loaded: bám quái đỏ/đầu lâu trong dungeon, có né skill + unlock Y sau khi xong mục tiêu.")
