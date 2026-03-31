-- // KING LEGACY - HYBRID MAX (FAST + STABLE + DPS MAX)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

-- ================= STATE =================
local farming = true
local target = nil
local dodgeTime = 0
local lastDodge = 0
local lastControlZ = 0
local angle = 0

-- ================= TOOL =================
local function getTool(keyword)
    for _,v in ipairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.Name:lower():find(keyword) then
            return v
        end
    end
end

local function equip(tool)
    if tool and tool.Parent ~= char then
        humanoid:EquipTool(tool)
        task.wait(0.12)
    end
end

-- ================= AIM =================
local function aim()
    if target and target:FindFirstChild("HumanoidRootPart") then
        root.CFrame = CFrame.new(root.Position, target.HumanoidRootPart.Position)
    end
end

-- ================= SKILL =================
local function press(key)
    VirtualInputManager:SendKeyEvent(true,key,false,game)
    task.wait(0.09) -- ⚡ tối ưu
    VirtualInputManager:SendKeyEvent(false,key,false,game)
end

-- ================= DODGE =================
local function dangerous(mob)
    if tick()-lastDodge<1 then return false end

    for _,v in ipairs(mob:GetDescendants()) do
        if v:IsA("Beam") and v.Enabled then return true end

        if v:IsA("ParticleEmitter") and v.Enabled then
            local p=v.Parent
            if p and p:IsA("BasePart") then
                if (p.Position-root.Position).Magnitude<65 then
                    return true
                end
            end
        end
    end
end

-- ================= TARGET =================
local function getMob()
    local closest,dist=nil,math.huge
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            local d=(root.Position-v.HumanoidRootPart.Position).Magnitude
            if d<dist then dist=d closest=v end
        end
    end
    return closest
end

-- ================= M1 LOOP =================
spawn(function()
    while true do
        if farming and target and dodgeTime<=0 then
            local tool=char:FindFirstChildOfClass("Tool")
            if tool and tool.Name:lower():find("kioru") then
                VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                task.wait(0.015)
                VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
            end
        end
        task.wait(0.015)
    end
end)

-- ================= COMBO =================
spawn(function()
    while true do
        if farming and target and dodgeTime<=0 then

            aim()

            -- 🍇 FRUIT
            local fruit=getTool("fruit") or getTool("control")
            if fruit then
                equip(fruit)
                aim()

                if tostring(player.Data.DevilFruit.Value):lower():find("control") then
                    if tick()-lastControlZ>60 then
                        press(Enum.KeyCode.Z)
                        lastControlZ=tick()
                    end
                end

                press(Enum.KeyCode.X)
                press(Enum.KeyCode.C)
                press(Enum.KeyCode.V)
                press(Enum.KeyCode.B)
            end

            task.wait(0.22)

            -- ⚔️ SWORD
            local sword=getTool("kioru")
            if sword then
                equip(sword)
                aim()

                press(Enum.KeyCode.Z)
                press(Enum.KeyCode.X)
            end

            task.wait(0.22)
        end
        task.wait(0.03)
    end
end)

-- ================= MAIN =================
RunService.Heartbeat:Connect(function(dt)
    if not farming then return end

    target=getMob()
    if not target then return end

    aim()

    if dangerous(target) then
        dodgeTime=1.1
        lastDodge=tick()
    end

    if dodgeTime>0 then
        angle-=7*dt

        local pos=target.HumanoidRootPart.Position+Vector3.new(
            math.cos(angle)*130,
            95,
            math.sin(angle)*130
        )

        root.CFrame=CFrame.new(pos,target.HumanoidRootPart.Position)
        dodgeTime-=dt
    else
        root.CFrame=CFrame.new(
            target.HumanoidRootPart.Position+Vector3.new(0,7,0),
            target.HumanoidRootPart.Position
        )
    end
end)

print("🔥 HYBRID MAX READY (FAST + STABLE + DPS)")
