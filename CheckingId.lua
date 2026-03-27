--// SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
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

-- 🚀 ULTRA STREAM (ĐỨNG YÊN VẪN QUÉT)
local function ultraStream()
    local plr = Players.LocalPlayer

    for i = 1, 2 do
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

-- 📤 SEND
local function send(eventType, name)
    local key = eventType .. (name or "")
    if sentEvents[key] then return end
    sentEvents[key] = true

    local webhook = webhooks[eventType]
    if not webhook then return end

    request({
        Url = webhook,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({
            content = eventType.." | "..(name or "").." | "..game.JobId
        })
    })
end

-- 🔁 SERVER HOP
local function serverHop()
    local placeId = game.PlaceId
    local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?limit=100"

    local data = HttpService:JSONDecode(game:HttpGet(url))

    for _, v in pairs(data.data) do
        if v.playing < v.maxPlayers then
            TeleportService:TeleportToPlaceInstance(placeId, v.id)
            task.wait(2)
        end
    end
end

-- 🔁 MAIN LOOP
while true do
    local sea = getSea()

    -- ❌ bỏ Sea 1
    if sea == "Sea 1" then
        serverHop()
        task.wait(5)
        continue
    end

    -- ⏳ LOAD MAP
    task.wait(math.random(30,60))

    ultraStream()

    local found = false
    local full = isFullMoon()
    local boss, bossName = hasBoss()
    local island, islandName = hasIsland()

    -- 🌕
    if full and sea == "Sea 3" then
        send("moon")
        found = true

    -- 👹
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

            found = true
        end

    -- 🏝️
    elseif island then
        local name = string.lower(islandName)

        if name:find("mirage") then
            send("mirage", islandName)
        elseif name:find("prehistoric") then
            send("prehistoric", islandName)
        end

        found = true
    end

    -- ❌ không có → hop
    if not found then
        serverHop()
    end

    task.wait(5)
end
