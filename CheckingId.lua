--// SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

--// WEBHOOK
local webhook = "https://discord.com/api/webhooks/1486382838256373800/t0dDpQd-NWa0obYARcM7F1DNy6bwAiljC4bf2J9Q0GvxEVOoMZepabIcXUXwuACeBOkW"

--// DATA
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
    return Lighting.ClockTime >= 0 and Lighting.ClockTime <= 1
end

-- 🔍 BOSS (FIX NHẸ)
local function hasBoss()
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "Dough King"
        or v.Name == "Cake Prince"
        or v.Name == "Cursed Captain"
        or v.Name == "Cake Queen"
        or v.Name == "rip_indra True Form" then
            return true, v.Name
        end
    end
    return false
end

-- 🔍 ISLAND (FIX NHẸ)
local function hasIsland()
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "Mirage Island"
        or v.Name == "Prehistoric Island" then
            return true, v.Name
        end
    end
    return false
end

-- 📤 SEND
local function send(msg)
    if sentEvents[msg] then return end
    sentEvents[msg] = true

    request({
        Url = webhook,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({
            content = msg .. " | " .. game.JobId
        })
    })
end

-- ⏳ LOAD
print("⏳ Loading...")
task.wait(30)

-- 🔁 LOOP
while true do
    print("🔍 Scanning...")

    local sea = getSea()

    if sea ~= "Sea 1" then
        local full = isFullMoon()
        local boss, bossName = hasBoss()
        local island, islandName = hasIsland()

        if full and sea == "Sea 3" then
            send("🌕 FULL MOON")

        elseif boss then
            send("👹 " .. bossName)

        elseif island then
            send("🏝️ " .. islandName)
        end
    end

    task.wait(120)
end
