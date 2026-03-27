--// REQUEST FIX
local request = request or http_request or syn and syn.request or fluxus and fluxus.request

--// SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

--// WEBHOOK (MỚI)
local webhook = "https://discord.com/api/webhooks/1487094092461768726/e6VF83RjvlXm_RdXjodRrKMbG1i1CdRCl2lb5cW8raSYZhdFEpAn7uAnVGkuBeP7wHvu"

--// CHECK REQUEST
if not request then
    warn("❌ Executor không hỗ trợ HTTP")
    return
end

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

-- 🔍 BOSS (FIX CHUẨN)
local function getBoss()
    for _, v in pairs(workspace:GetDescendants()) do
        local name = string.lower(v.Name)

        if name:find("dough king")
        or name:find("cake prince")
        or name:find("cursed captain")
        or name:find("cake queen")
        or name:find("indra") then
            return v.Name
        end
    end
end

-- 🔍 ISLAND
local function getIsland()
    for _, v in pairs(workspace:GetDescendants()) do
        local name = string.lower(v.Name)

        if name:find("mirage")
        or name:find("prehistoric") then
            return v.Name
        end
    end
end

-- 🚀 STREAM NHẸ
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

    print("📡 SEND:", title, name)

    local data = {
        ["username"] = "Kaibeo Scanner ⚡",
        ["embeds"] = {{
            ["title"] = title.." ["..sea.."]",
            ["color"] = 65280,

            ["description"] =
                "**Name:**\n```"..(name or "N/A").."```\n\n" ..
                "**Players:**\n```"..#Players:GetPlayers().."/12```\n\n" ..
                "**Sea:**\n```"..sea.."```\n\n" ..
                "**JobId:**\n```"..game.JobId.."```",

            ["footer"] = {
                ["text"] = "Fix All Scanner"
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

-- 🧪 TEST WEBHOOK
request({
    Url = webhook,
    Method = "POST",
    Headers = {["Content-Type"] = "application/json"},
    Body = HttpService:JSONEncode({
        content = "✅ SCANNER STARTED"
    })
})

-- ⏳ LOAD
print("⏳ Loading map...")
task.wait(30)

-- 🔁 LOOP
while true do
    print("🔍 Scanning...")

    local sea = getSea()

    if sea ~= "Sea 1" then
        stream()

        local boss = getBoss()
        local island = getIsland()
        local full = isFullMoon()

        print("DEBUG:", boss, island, full)

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
    else
        print("❌ Skip Sea 1")
    end

    task.wait(120)
end
