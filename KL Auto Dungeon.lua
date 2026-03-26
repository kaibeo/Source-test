--// SETTINGS
getgenv().Setting = {
    Farm = true,
    Distance = 3,
    Speed = 70,
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

--// CHAR
function GetChar()
    return plr.Character or plr.CharacterAdded:Wait()
end

--// GET MOBS
function GetMobs()
    local mobs = {}

    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model")
        and v:FindFirstChild("Humanoid")
        and v:FindFirstChild("HumanoidRootPart")
        and v.Humanoid.Health > 0 then
            table.insert(mobs, v)
        end
    end

    return mobs
end

--// TARGET (ƯU TIÊN BOSS)
function GetTarget(hrp)
    local boss, normal = nil, nil
    local dist = math.huge

    for _,v in pairs(GetMobs()) do
        local d = (hrp.Position - v.HumanoidRootPart.Position).Magnitude

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

    return boss or normal
end

--// MOVE (LEGIT)
function MoveTo(hrp, pos)
    local dir = (pos - hrp.Position).Unit
    hrp.Velocity = dir * Setting.Speed
end

--// LOOK
function LookAt(hrp, pos)
    hrp.CFrame = CFrame.new(hrp.Position, pos)
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

--// CLICK (M1)
function Click()
    Vim:SendMouseButtonEvent(0,0,0,true,game,0)
    Vim:SendMouseButtonEvent(0,0,0,false,game,0)
end

--// SKILL
function Skill(key)
    Vim:SendKeyEvent(true,key,false,game)
    task.wait(0.12)
    Vim:SendKeyEvent(false,key,false,game)
end

--// COMBO
function DoCombo(mob)
    local hrp = GetChar():WaitForChild("HumanoidRootPart")
    local mobHRP = mob.HumanoidRootPart

    LookAt(hrp, mobHRP.Position)

    -- M1 mở đầu
    for i=1,2 do
        Click()
        task.wait(0.1)
    end

    -- skill gần
    if (hrp.Position - mobHRP.Position).Magnitude < 6 then
        for _,k in pairs({"Z","X","C","V"}) do
            Skill(k)
        end
    end
end

--// CHECK WAVE
function WaveActive()
    return #GetMobs() > 0
end

--// MAIN AI
spawn(function()
    while Setting.Farm do
        pcall(function()

            local char = GetChar()
            local hrp = char:WaitForChild("HumanoidRootPart")

            if WaveActive() then
                -- 🟢 FARM WAVE
                local mob = GetTarget(hrp)
                if mob then
                    local mobHRP = mob.HumanoidRootPart

                    local targetPos = mobHRP.Position + Vector3.new(0,0,Setting.Distance)

                    MoveTo(hrp, targetPos)
                    LookAt(hrp, mobHRP.Position)

                    for _,wp in pairs(Setting.Weapons) do
                        Equip(wp)
                        DoCombo(mob)
                    end
                end

            else
                -- 🔴 HẾT WAVE → ĐỨNG CHỜ
                hrp.Velocity = Vector3.zero
                task.wait(Setting.ScanDelay)

                -- phát hiện wave mới → lao tới ngay
                if WaveActive() then
                    local mob = GetTarget(hrp)
                    if mob then
                        MoveTo(hrp, mob.HumanoidRootPart.Position)
                    end
                end
            end

        end)
        task.wait(0.1)
    end
end)
