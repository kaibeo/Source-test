--// SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

--// WEBHOOKS
local webhooks = {
    moon = "https://discord.com/api/webhooks/1486382838256373800/t0dDpQd-NWa0obYARcM7F1DNy6bwAiljC4bf2J9Q0GvxEVOoMZepabIcXUXwuACeBOkW",

    doughKing = "https://discord.com/api/webhooks/1487094092461768726/e6VF83RjvlXm_RdXjodRrKMbG1i1CdRCl2lb5cW8raSYZhdFEpAn7uAnVGkuBeP7wHvu",
    indra = "https://discord.com/api/webhooks/1487094092461768726/e6VF83RjvlXm_RdXjodRrKMbG1i1CdRCl2lb5cW8raSYZhdFEpAn7uAnVGkuBeP7wHvu",
    cakeQueen = "https://discord.com/api/webhooks/1487094092461768726/e6VF83RjvlXm_RdXjodRrKMbG1i1CdRCl2lb5cW8raSYZhdFEpAn7uAnVGkuBeP7wHvu",
    cakePrince = "https://discord.com/api/webhooks/1487094092461768726/e6VF83RjvlXm_RdXjodRrKMbG1i1CdRCl2lb5cW8raSYZhdFEpAn7uAnVGkuBeP7wHvu",
    cursed = "https://discord.com/api/webhooks/1487094092461768726/e6VF83RjvlXm_RdXjodRrKMbG1i1CdRCl2lb5cW8raSYZhdFEpAn7uAnVGkuBeP7wHvu",

    mirage = "https://discord.com/api/webhooks/1486382849622802634/DqPjA6RaQy2z4Wxw_tLsddltYB0dJgG4A_zx36LGqRax8pq8yakmE4DQAcfv6Mhb5Dv2",
    prehistoric = "https://discord.com/api/webhooks/1487094080646418522/uLAiVJFOxWqs7D0ad1or2Por13heNzT2gB9XvvMUyBUZTO-ErxfdDSpMbxeb8VLAYbV3"
}

--// DATA
local bosses = {
    "Dough King",
    "rip_indra True Form",
    "Cake Queen",
    "Cake Prince",
    "Cursed Captain"
}

local islands = {
    "Mirage Island",
    "Prehistoric Island"
}

local sentEvents = {}

-- 🌍 SEA
local function getSea()
    local id = game.PlaceId
    if id == 4442272183 then return "Sea 2"
    elseif id == 7449423635 then return "Sea 3"
    else return "Sea 1" end
end

-- 🌕 FULL MOON
local function isFullMoon()
    local t = Lighting.ClockTime
    return t >= 0 and t <= 1 and Lighting.Brightness <= 2
end

-- 🚀 ULTRA STREAM
local function ultraStream()
    local plr = Players.LocalPlayer
    local char = plr.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local radius = 50000
    local step = 6000

    for x = -radius, radius, step do
        for z = -radius, radius, step do
            local pos = root.Position + Vector3.new(x, 0, z)

            pcall(function()
                plr:RequestStreamAroundAsync(pos)
            end)

            task.wait(0.01)
        end
    end
end

-- 🔍 BOSS
local function hasBoss()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            for _, b in pairs(bosses) do
                if string.lower(v.Name) == string.lower(b) then
                    local hrp = v:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp.Position.Magnitude > 1000 then
                        return true, b
                    end
                end
            end
        end
    end
    return false
end

-- 🔍 ISLAND
local function hasIsland()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") then
            for _, i in pairs(islands) do
                if string.lower(v.Name) == string.lower(i) then
                    local part = v:FindFirstChildWhichIsA("BasePart")
                    if part then
                        if part.Position.Magnitude > 3000 and part.Size.Magnitude > 80 then
                            return true, i
                        end
                    end
                end
            end
        end
    end
    return false
end

-- 📤 SEND
local function send(eventType, name)
    local key = eventType .. (name or "")
    if sentEvents[key] then return end
    sentEvents[key] = true

    local webhook = webhooks[eventType]
    if not webhook then return end

    local sea = getSea()

    local data = {
        ["username"] = "Scanner Ultra ⚡",
        ["embeds"] = {{
            ["title"] = eventType.." ["..sea.."]",

            ["description"] =
                "**Name:**\n```"..(name or "N/A").."```\n\n" ..
                "**Players:**\n```"..#Players:GetPlayers().."/12```\n\n" ..
                "**Sea:**\n```"..sea.."```\n\n" ..
                "**JobId:**\n```"..game.JobId.."```\n\n" ..
                "**Join:**\n```lua\n" ..
                "game:GetService(\"ReplicatedStorage\").__ServerBrowser:InvokeServer(\"teleport\", \""..game.JobId.."\")\n```",

            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }

    request({
        Url = webhook,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(data)
    })
end

-- ⏳ LOAD MAP
task.wait(math.random(30,60))

-- 🔁 LOOP
while true do
    local sea = getSea()

    -- ❌ BỎ SEA 1
    if sea == "Sea 1" then
        task.wait(120)
        continue
    end

    ultraStream()

    local full = isFullMoon()
    local boss, bossName = hasBoss()
    local island, islandName = hasIsland()

    -- 🌕 FULL MOON
    if full and sea == "Sea 3" then
        send("moon")

    -- 👹 BOSS
    elseif boss then
        local name = string.lower(bossName)

        if not (sea == "Sea 2" and name:find("indra")) then

            if name:find("dough king") then
                send("doughKing", bossName)

            elseif name:find("indra") then
                send("indra", bossName)

            elseif name:find("cake queen") then
                send("cakeQueen", bossName)

            elseif name:find("cake prince") then
                send("cakePrince", bossName)

            elseif name:find("cursed captain") then
                send("cursed", bossName)
            end
        end

    -- 🏝️ ISLAND
    elseif island then
        local name = string.lower(islandName)

        if name:find("mirage") then
            send("mirage", islandName)

        elseif name:find("prehistoric") then
            send("prehistoric", islandName)
        end
    end

    task.wait(120)
end
