--// SETTINGS
getgenv().Setting = {
    Farm = true,
    Height = 10,
    Speed = 70,
    Distance = 3,
    ScanDelay = 0.5,

    Weapons = {
        "Sword",
        "Fruit",
        "Melee"
    }
}

--// SERVICES
local plr = game.Players.LocalPlayer
local Vim = game:GetService("VirtualInputManager")

--// GET CHAR SAFE
function GetChar()
    return plr.Character or plr.CharacterAdded:Wait()
end

--// SAFE HRP
function GetHRP()
    local char = GetChar()
    return char:WaitForChild("HumanoidRootPart")
end

--// GET MOBS SAFE
function GetMobs()
    local mobs = {}

    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") then
            local hum = v:FindFirstChild("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")

            if hum and hrp and hum.Health > 0 then
                table.insert(mobs, v)
            end
        end
    end

    return mobs
end

--// TARGET (ưu tiên boss)
function GetTarget(hrp)
    local boss, normal = nil, nil
    local dist = math.huge

    for _,v in pairs(GetMobs()) do
        local hrp2 = v:FindFirstChild("HumanoidRootPart")
        if hrp2 then
            local d = (hrp.Position - hrp2.Position).Magnitude

            if v.Name:lower():find("boss") then
                if d < dist then
                    boss = v
                    dist = d
                end
            elseif not boss then
                if d < dist then
                    normal = v
                    dist = d
                end
            end
        end
    end

    return boss or normal
end

--// MOVE (ỔN ĐỊNH)
function FlyTo(hrp, pos)
    local dir = (pos - hrp.Position)
    if dir.Magnitude > 1 then
        hrp.Velocity = dir.Unit * Setting.Speed
    end
end

--// LOOK
function LookAt(hrp, pos)
    hrp.CFrame = CFrame.new(hrp.Position, pos)
end

--// CLICK
function Click()
    Vim:SendMouseButtonEvent(0,0,0,true,game,0)
    Vim:SendMouseButtonEvent(0,0,0,false,game,0)
end

--// SKILL
function Skill(key)
    Vim:SendKeyEvent(true,key,false,game)
    task.wait(0.1)
    Vim:SendKeyEvent(false,key,false,game)
end

--// EQUIP
function Equip(name)
    local char = GetChar()
    local tool = plr.Backpack:FindFirstChild(name) or char:FindFirstChild(name)
    if tool then
        char.Humanoid:EquipTool(tool)
        task.wait(0.1)
    end
end

--// COMBO
function DoCombo(mob)
    local hrp = GetHRP()
    local mobHRP = mob.HumanoidRootPart

    LookAt(hrp, mobHRP.Position)

    -- M1
    for i=1,2 do
        Click()
        task.wait(0.1)
    end

    -- skill
    if (hrp.Position - mobHRP.Position).Magnitude < 7 then
        for _,k in pairs({"Z","X","C","V"}) do
            Skill(k)
        end
    end
end

--// CHECK WAVE
function WaveActive()
    return #GetMobs() > 0
end

--// DETECT CAST SKILL
function IsCasting(mob)
    local hum = mob:FindFirstChild("Humanoid")
    local hrp = mob:FindFirstChild("HumanoidRootPart")

    if not hum or not hrp then return false end

    local move = hum.MoveDirection.Magnitude
    local vel = hrp.Velocity.Magnitude

    return (move == 0 and vel < 1)
end

--// DODGE (NHẸ - KHÔNG BUG)
function Dodge(hrp, mob)
    local base = mob.HumanoidRootPart.Position

    local offset = Vector3.new(
        math.random(-15,15),
        15,
        math.random(-15,15)
    )

    hrp.CFrame = CFrame.new(base + offset)
end

--// MAIN
spawn(function()
    while Setting.Farm do
        pcall(function()

            local hrp = GetHRP()

            if WaveActive() then
                local mob = GetTarget(hrp)

                if mob and mob:FindFirstChild("HumanoidRootPart") then
                    local mobHRP = mob.HumanoidRootPart

                    -- 🔴 né nếu đang cast
                    if IsCasting(mob) then
                        Dodge(hrp, mob)
                        task.wait(0.25)
                    else
                        -- 🟢 bay lên đầu
                        local target = mobHRP.Position + Vector3.new(0,Setting.Height,0)
                        FlyTo(hrp, target)

                        -- giữ ổn định
                        hrp.Velocity = hrp.Velocity * 0.9

                        for _,wp in pairs(Setting.Weapons) do
                            Equip(wp)
                            DoCombo(mob)
                        end
                    end
                end

            else
                -- 🔴 HẾT WAVE → ĐỨNG CHỜ
                hrp.Velocity = Vector3.zero
                task.wait(Setting.ScanDelay)
            end

        end)
        task.wait(0.1)
    end
end)
