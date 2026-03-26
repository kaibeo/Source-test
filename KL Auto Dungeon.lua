--// SETTINGS
getgenv().Farm = true
getgenv().Distance = 3
getgenv().Speed = 120

getgenv().Weapons = {
    "Sword",
    "Fruit",
    "Melee"
}

--// SERVICES
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local TweenService = game:GetService("TweenService")
local Vim = game:GetService("VirtualInputManager")

--// GET TARGET (ưu tiên boss)
function GetTarget()
    local boss, normal = nil, nil
    local dist = math.huge

    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model")
        and v:FindFirstChild("Humanoid")
        and v:FindFirstChild("HumanoidRootPart")
        and v.Humanoid.Health > 0 then

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
    end

    return boss or normal
end

--// MOVE (FAST + SMOOTH)
function MoveTo(cf)
    local dist = (hrp.Position - cf.Position).Magnitude
    local t = math.clamp(dist/getgenv().Speed,0.05,0.5)

    local tween = TweenService:Create(hrp, TweenInfo.new(t), {CFrame = cf})
    tween:Play()
    task.wait(t)
end

--// LOOK LOCK
function LookAt(pos)
    hrp.CFrame = CFrame.new(hrp.Position, pos)
end

--// EQUIP FAST
function Equip(name)
    local tool = plr.Backpack:FindFirstChild(name) or char:FindFirstChild(name)
    if tool then
        char.Humanoid:EquipTool(tool)
    end
end

--// FAST CLICK
function ClickFast()
    for i=1,2 do
        Vim:SendMouseButtonEvent(0,0,0,true,game,0)
        Vim:SendMouseButtonEvent(0,0,0,false,game,0)
    end
end

--// FAST SKILL (không delay thừa)
function UseSkills()
    for _,k in pairs({"Z","X","C","V"}) do
        Vim:SendKeyEvent(true,k,false,game)
        task.wait(0.1)
        Vim:SendKeyEvent(false,k,false,game)
    end
end

--// MAIN
spawn(function()
    while getgenv().Farm do
        pcall(function()

            local mob = GetTarget()
            if mob then
                local mobHRP = mob.HumanoidRootPart

                -- vị trí tối ưu (không quá xa)
                local target = mobHRP.CFrame * CFrame.new(0,0,getgenv().Distance)
                MoveTo(target)

                -- lock aim
                LookAt(mobHRP.Position)

                -- combo nhanh
                for _,wp in pairs(getgenv().Weapons) do
                    Equip(wp)

                    ClickFast()
                    UseSkills()
                end
            end

        end)
        task.wait(0.05)
    end
end)
