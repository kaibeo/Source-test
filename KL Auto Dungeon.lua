--// SETTINGS
getgenv().Setting = {
    Farm = true,
    AutoKen = true,
    AutoSkill = true,
    DodgeBoss = true,
    ESP = true,
    Speed = 100,
    Height = 10
}

--// SERVICES
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local TweenService = game:GetService("TweenService")
local Vim = game:GetService("VirtualInputManager")

--// SAFE ENEMY FOLDER
function EnemyFolder()
    return workspace:FindFirstChild("Enemies") or workspace
end

--// GET MOBS
function GetMobs()
    local mobs = {}
    for _,v in pairs(EnemyFolder():GetDescendants()) do
        if v:IsA("Model") 
        and v:FindFirstChild("Humanoid") 
        and v:FindFirstChild("HumanoidRootPart")
        and v.Humanoid.Health > 0 then
            table.insert(mobs, v)
        end
    end
    return mobs
end

--// NEAREST
function GetNearestMob()
    local nearest, dist = nil, math.huge
    for _,v in pairs(GetMobs()) do
        local d = (hrp.Position - v.HumanoidRootPart.Position).Magnitude
        if d < dist then
            dist = d
            nearest = v
        end
    end
    return nearest
end

--// HAS MOB
function HasMobs()
    return #GetMobs() > 0
end

--// TWEEN
function TweenTo(cf)
    local dist = (hrp.Position - cf.Position).Magnitude
    local t = math.clamp(dist / Setting.Speed, 0.1, 3)

    local tween = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {
        CFrame = cf
    })
    tween:Play()
    task.wait(t)
end

--// DOOR
function GetDoor()
    local nearest, dist = nil, math.huge
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and (
            v.Name:lower():find("door") or 
            v.Name:lower():find("gate") or
            v.Name:lower():find("exit")
        ) then
            local d = (hrp.Position - v.Position).Magnitude
            if d < dist then
                dist = d
                nearest = v
            end
        end
    end
    return nearest
end

--// ATTACK
function Click()
    Vim:SendMouseButtonEvent(0,0,0,true,game,0)
    Vim:SendMouseButtonEvent(0,0,0,false,game,0)
end

--// SKILL
function Skill()
    if not Setting.AutoSkill then return end
    for _,k in pairs({"Z","X","C","V"}) do
        Vim:SendKeyEvent(true,k,false,game)
        task.wait(0.1)
        Vim:SendKeyEvent(false,k,false,game)
    end
end

--// KEN
function Ken()
    if Setting.AutoKen then
        Vim:SendKeyEvent(true,"E",false,game)
        task.wait(0.1)
        Vim:SendKeyEvent(false,"E",false,game)
    end
end

--// BOSS CHECK
function IsBoss(m)
    return m.Name:lower():find("boss")
end

--// DODGE
function Dodge(m)
    local pos = m.HumanoidRootPart.CFrame * CFrame.new(
        math.random(-20,20),15,math.random(-20,20)
    )
    TweenTo(pos)
end

--// ESP
function AddESP(mob)
    if not Setting.ESP then return end
    if mob:FindFirstChild("Head") and not mob.Head:FindFirstChild("ESP") then
        local bill = Instance.new("BillboardGui", mob.Head)
        bill.Name = "ESP"
        bill.Size = UDim2.new(0,100,0,40)
        bill.AlwaysOnTop = true

        local txt = Instance.new("TextLabel", bill)
        txt.Size = UDim2.new(1,0,1,0)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.new(1,0,0)
        txt.TextScaled = true

        spawn(function()
            while mob and mob.Parent and mob:FindFirstChild("Humanoid") do
                local dist = math.floor((hrp.Position - mob.HumanoidRootPart.Position).Magnitude)
                txt.Text = mob.Name.." | "..math.floor(mob.Humanoid.Health).." | "..dist
                task.wait(0.3)
            end
        end)
    end
end

--// MAIN
spawn(function()
    while Setting.Farm do
        pcall(function()

            Ken()

            if HasMobs() then
                local mob = GetNearestMob()
                if mob then
                    AddESP(mob)

                    if Setting.DodgeBoss and IsBoss(mob) then
                        if mob.Humanoid.MoveDirection.Magnitude == 0 then
                            Dodge(mob)
                        end
                    end

                    local target = mob.HumanoidRootPart.CFrame * CFrame.new(0,Setting.Height,0)
                    TweenTo(target)

                    mob.HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0,-Setting.Height,-2)
                    mob.HumanoidRootPart.CanCollide = false

                    Click()
                    Skill()
                end

            else
                local door = GetDoor()
                if door then
                    TweenTo(door.CFrame * CFrame.new(0,5,0))
                    task.wait(0.5)
                    hrp.CFrame = door.CFrame * CFrame.new(0,0,8)
                end
            end

        end)
        task.wait(0.25)
    end
end)
