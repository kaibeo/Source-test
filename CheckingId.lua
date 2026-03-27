--// REQUEST FIX (QUAN TRỌNG)
local request = request or http_request or syn and syn.request or fluxus and fluxus.request

--// SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

--// WEBHOOK
local webhook = "https://discord.com/api/webhooks/1486382838256373800/t0dDpQd-NWa0obYARcM7F1DNy6bwAiljC4bf2J9Q0GvxEVOoMZepabIcXUXwuACeBOkW"

--// ANTI DUP
local sent = {}

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
    return t >= 0 and t <= 1
end

-- 🔍 BOSS (SIÊU NHẸ - KHÔNG LỖI)
local function getBoss()
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "Dough King"
        or v.Name == "Cake Prince"
        or v.Name == "Cursed Captain"
        or v.Name == "Cake Queen"
        or v.Name == "rip_indra True Form" then
            return v.Name
        end
    end
end

-- 🔍 ISLAND
local function getIsland()
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "Mirage Island"
        or v.Name == "Prehistoric Island" then
            return v.Name
        end
    end
end

-- 🚀 STREAM NHẸ (KHÔNG LAG)
local function stream()
    local plr = Players.LocalPlayer

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            pcall(function()
                plr:RequestStreamAroundAsync(v.Position)
            end)
        end
    end
end

-- 📤 SEND EMBED
local function send(title, name)
    local key = title..(name or "")
    if sent[key] then return end
    sent[key] = true

    local sea = getSea()

    local data = {
        ["username"] = "Fix Scanner ⚡",
        ["embeds"] = {{
            ["title"] = title.." ["..sea.."]",
            ["color"] = 65280,

            ["description"] =
                "**Name:**\n```"..(name or "N/A").."```\n\n" ..
                "**Players:**\n```"..#Players:GetPlayers().."/12```\n\n" ..
                "**JobId:**\n```"..game.JobId.."```",

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

-- ⏳ LOAD CHẮC CHẮN
print("⏳ Loading map...")
task.wait(30)

-- 🔁 LOOP
while true do
    print("🔍 Scanning...")

    local sea = getSea()

    -- ❌ BỎ SEA 1
    if sea ~= "Sea 1" then

        -- load map nhẹ
        stream()

        local boss = getBoss()
        local island = getIsland()
        local full = isFullMoon()

        -- 🌕
        if full and sea == "Sea 3" then
            send("🌕 FULL MOON")

        -- 👹
        elseif boss then
            send("👹 BOSS", boss)

        -- 🏝️
        elseif island then
            send("🏝️ ISLAND", island)
        end
    end

    task.wait(120) -- 2 phút
end
