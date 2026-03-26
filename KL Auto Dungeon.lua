--// SETTINGS
getgenv().Farm = true
getgenv().Speed = 120
getgenv().Height = 12
getgenv().SafeDistance = 20

--// SERVICES
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local TweenService = game:GetService("TweenService")
local Vim = game:GetService("VirtualInputManager")

--// FUNCTIONS

function TweenTo(cf)
    local dist = (hrp.Position - cf.Position).Magnitude
    local t = dist / getgenv().Speed

    local tween = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {
        CFrame = cf
    })
    tween:Play()
    tween.Completed:Wait()
end

function GetMobs()
    local mobs = {}
    for i,v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            table.insert(mobs, v)
        end
    end
    return mobs
end

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

function HasMobs()
    return #GetMobs() > 0
end

function GetDoor()
    local nearest, dist = nil, math.huge
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and (
            string.find(v.Name:lower(),"door") or 
            string.find(v.Name:lower(),"gate") or
            string.find(v.Name:lower(),"exit")
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

function UseKen()
    Vim:SendKeyEvent(true,"E",false,game)
    task.wait(0.1)
    Vim:SendKeyEvent(false,"E",false,game)
end

function IsBoss(mob)
    return mob.Name:lower():find("boss")
end

function Dodge(mob)
    local offset = Vector3.new(
        math.random(-getgenv().SafeDistance,getgenv().SafeDistance),
        15,
        math.random(-getgenv().SafeDistance,getgenv().SafeDistance)
    )
    TweenTo(mob.HumanoidRootPart.CFrame * CFrame.new(offset))
end

function Attack()
    Vim:SendMouseButtonEvent(0,0,0,true,game,0)
    Vim:SendMouseButtonEvent(0,0,0,false,game,0)
end

--// MAIN AI
spawn(function()
    while getgenv().Farm do
        pcall(function()

            UseKen()

            if HasMobs() then
                local mob = GetNearestMob()
                if mob then
                    local mobHRP = mob.HumanoidRootPart

                    -- né boss
                    if IsBoss(mob) and mob.Humanoid.MoveDirection.Magnitude == 0 then
                        Dodge(mob)
                    end

                    -- bay tới
                    local target = mobHRP.CFrame * CFrame.new(0,getgenv().Height,0)
                    TweenTo(target)

                    -- giữ trên đầu + bring nhẹ
                    mobHRP.CFrame = hrp.CFrame * CFrame.new(0,-getgenv().Height,-2)
                    mobHRP.CanCollide = false

                    Attack()
                end

            else
                -- qua phòng mới
                local door = GetDoor()
                if door then
                    TweenTo(door.CFrame * CFrame.new(0,5,0))
                    task.wait(0.5)
                    hrp.CFrame = door.CFrame * CFrame.new(0,0,6)
                end
            end

        end)
        task.wait(0.2)
    end
end)
