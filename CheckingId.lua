--// SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

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

-- 🌕 Moon
local function getMoon()
    local phase = 5
    local timeLeft = math.random(5,15)
    return phase == 5, timeLeft
end

-- 🔍 CHECK
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

local function hasIsland()
    for _, v in pairs(workspace:GetChildren()) do
        for _, i in pairs(islands) do
            if string.lower(v.Name) == string.lower(i) then
                return true, i
            end
        end
    end
    return false
end

-- 📜 JOIN SCRIPT (KHÔNG PLACEID)
local function getJoinScript()
    return "game:GetService(\"ReplicatedStorage\").__ServerBrowser:InvokeServer(\"teleport\", \"" .. game.JobId .. "\")"
end

-- 📤 EMBED
local function sendEmbed(eventType, name, extra)
    local playerCount = #Players:GetPlayers()
    local jobId = game.JobId

    local title, color, main

    if eventType == "boss" then
        title = "🔥 Boss Spawn"
        color = 16711680
        main = "**[👹] Boss:**\n```" .. name .. "```"

    elseif eventType == "island" then
        title = "🏝️ Special Island"
        color = 65280
        main = "**[🌴] Island:**\n```" .. name .. "```"

    elseif eventType == "moon" then
        title = "🌕 Full Moon"
        color = 65280
        main =
            "**[🌕] Moon Phase:**\n```Full Moon 100%```\n\n" ..
            "**[🌙] End Moon:**\n```" .. extra .. " Minute(s)```"
    end

    local data = {
        ["username"] = "Notify Rc3",
        ["embeds"] = {{
            ["title"] = title,
            ["color"] = color,

            ["description"] =
                main .. "\n\n" ..

                "**[👤] Player Count:**\n```" .. playerCount .. "/12```\n\n" ..

                "**[🔗] Job ID:**\n```" .. jobId .. "```\n\n" ..

                "**[📜] Join Script (Copy Mobile):**\n```lua\n" ..
                getJoinScript() .. "\n```",

            ["footer"] = {
                ["text"] = "Event Scanner System"
            },

            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }

    request({
        Url = webhook,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(data)
    })
end

-- 🔁 LOOP
while task.wait(5) do
    if not sent then
        local boss, bossName = hasBoss()
        local island, islandName = hasIsland()
        local full, timeLeft = getMoon()

        if boss then
            sendEmbed("boss", bossName)
            sent = true

        elseif island then
            sendEmbed("island", islandName)
            sent = true

        elseif full then
            sendEmbed("moon", "Full Moon", timeLeft)
            sent = true
        end
    end
end