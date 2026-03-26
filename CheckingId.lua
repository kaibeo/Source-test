--// SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

--// CONFIG
local webhook = "https://discord.com/api/webhooks/1486382838256373800/t0dDpQd-NWa0obYARcM7F1DNy6bwAiljC4bf2J9Q0GvxEVOoMZepabIcXUXwuACeBOkW"

local bosses = {
    "Dough King",
    "rip_indra True Form",
    "Cake Queen"
}

local islands = {
    "Mirage Island",
    "Prehistoric Island"
}

local sent = false

-- 🌍 DETECT SEA
local function getSea()
    local id = game.PlaceId

    if id == 2753915549 then
        return "Sea 1"
    elseif id == 4442272183 then
        return "Sea 2"
    elseif id == 7449423635 then
        return "Sea 3"
    end

    return "Unknown"
end

-- 🌕 FULL MOON (REAL)
local function isFullMoon()
    local t = Lighting.ClockTime
    return t >= 0 and t <= 1
end

-- 🔍 CHECK BOSS
local function hasBoss()
    for _, v in pairs(workspace:GetDescendants()) do
        for _, b in pairs(bosses) do
            if string.lower(v.Name) == string.lower(b) then
                return true, b
            end
        end
    end
    return false
end

-- 🔍 CHECK ISLAND
local function hasIsland()
    for _, v in pairs(workspace:GetDescendants()) do
        for _, i in pairs(islands) do
            if string.lower(v.Name) == string.lower(i) then
                return true, i
            end
        end
    end
    return false
end

-- 📤 EMBED
local function sendEmbed(eventType, name)
    local playerCount = #Players:GetPlayers()
    local jobId = game.JobId
    local sea = getSea()

    local title, color, main

    if eventType == "moon" then
        title = "🌕 Full Moon ["..sea.."]"
        color = 65280
        main = "**[🌕] Moon Phase:**\n```Full Moon 100%```"

    elseif eventType == "boss" then
        title = "🔥 Boss Found ["..sea.."]"
        color = 16711680
        main = "**[👹] Boss:**\n```" .. name .. "```"

    elseif eventType == "island" then
        title = "🏝️ Special Island ["..sea.."]"
        color = 3447003
        main = "**[🌴] Island:**\n```" .. name .. "```"
    end

    local data = {
        ["username"] = "Kaibeo Scanner ⚡",
        ["embeds"] = {{
            ["title"] = title,
            ["color"] = color,

            ["description"] =
                main .. "\n\n" ..

                "**[👤] Player Count:**\n```" .. playerCount .. "/12```\n\n" ..

                "**[🌍] Sea:**\n```" .. sea .. "```\n\n" ..

                "**[🔗] Job ID:**\n```" .. jobId .. "```\n\n" ..

                "**[📜] Join Script:**\n```lua\n" ..
                "game:GetService(\"ReplicatedStorage\").__ServerBrowser:InvokeServer(\"teleport\", \"" .. jobId .. "\")\n```",

            ["footer"] = {
                ["text"] = "Scanner System | Final"
            },

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

-- ⏳ CHỜ LOAD MAP
task.wait(5)

-- 🔁 LOOP
while task.wait(5) do
    if not sent then
        local sea = getSea()

        local full = isFullMoon()
        local boss, bossName = hasBoss()
        local island, islandName = hasIsland()

        -- 🌕 FULL MOON (CHỈ SEA 3)
        if full and sea == "Sea 3" then
            sendEmbed("moon")
            sent = true

        -- 👹 BOSS
        elseif boss then
            -- ❌ chặn rip_indra ở Sea 2
            if sea == "Sea 2" and string.lower(bossName):find("indra") then
                -- bỏ qua
            else
                sendEmbed("boss", bossName)
                sent = true
            end

        -- 🏝️ ISLAND
        elseif island then
            sendEmbed("island", islandName)
            sent = true
        end
    end
end
