--// SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

--// WEBHOOK (CỦA BẠN)
local webhook = "https://discord.com/api/webhooks/1486382838256373800/t0dDpQd-NWa0obYARcM7F1DNy6bwAiljC4bf2J9Q0GvxEVOoMZepabIcXUXwuACeBOkW"

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

-- 🚀 STREAM XA
local function ultraStream()
    local plr = Players.LocalPlayer
    for i = 1,2 do
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                pcall(function()
                    plr:RequestStreamAroundAsync(v.Position)
                end)
            end
        end
        task.wait(0.5)
    end
end

-- 🔍 BOSS
local function hasBoss()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            for _, b in pairs(bosses) do
                if string.lower(v.Name) == string.lower(b) then
                    return true, b
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
                    if part and part.Position.Magnitude > 3000 then
                        return true, i
                    end
                end
            end
        end
    end
    return false
end

-- 📤 EMBED
local function sendEmbed(title, name, color)
    local key = title .. (name or "")
    if sentEvents[key] then return end
    sentEvents[key] = true

    local sea = getSea()

    local data = {
        ["username"] = "Scanner Pro ⚡",
        ["embeds"] = {{
            ["title"] = title .. " ["..sea.."]",
            ["color"] = color,

            ["description"] =
                "**Name:**\n```"..(name or "N/A").."```\n\n" ..
                "**Players:**\n```"..#Players:GetPlayers().."/12```\n\n" ..
                "**Sea:**\n```"..sea.."```\n\n" ..
                "**JobId:**\n```"..game.JobId.."```\n\n" ..
                "**Join Script:**\n```lua\n" ..
                "game:GetService(\"ReplicatedStorage\").__ServerBrowser:InvokeServer(\"teleport\", \""..game.JobId.."\")\n```",

            ["footer"] = {
                ["text"] = "Kaibeo Scanner"
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

-- ⏳ LOAD
task.wait(math.random(30,60))

-- 🔁 LOOP
while true do
    local sea = getSea()

    if sea ~= "Sea 1" then
        ultraStream()

        local full = isFullMoon()
        local boss, bossName = hasBoss()
        local island, islandName = hasIsland()

        -- 🌕
        if full and sea == "Sea 3" then
            sendEmbed("🌕 FULL MOON", nil, 65280)

        -- 👹
        elseif boss then
            local name = string.lower(bossName)

            if not (sea == "Sea 2" and name:find("indra")) then

                if name:find("dough king") then
                    sendEmbed("🍩 DOUGH KING", bossName, 16753920)

                elseif name:find("indra") then
                    sendEmbed("👑 RIP INDRA", bossName, 16711680)

                elseif name:find("cake queen") then
                    sendEmbed("🎂 CAKE QUEEN", bossName, 16711935)

                elseif name:find("cake prince") then
                    sendEmbed("🍰 CAKE PRINCE", bossName, 8388736)

                elseif name:find("cursed captain") then
                    sendEmbed("☠️ CURSED CAPTAIN", bossName, 10038562)
                end
            end

        -- 🏝️
        elseif island then
            local name = string.lower(islandName)

            if name:find("mirage") then
                sendEmbed("🌴 MIRAGE ISLAND", islandName, 3447003)

            elseif name:find("prehistoric") then
                sendEmbed("🦴 PREHISTORIC ISLAND", islandName, 10181046)
            end
        end
    end

    task.wait(120)
end
