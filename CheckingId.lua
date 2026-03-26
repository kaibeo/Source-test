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

-- 💾 MEMORY
local sentEvents = {}
local lastScan = 0

-- 🌍 SEA
local function getSea()
    local id = game.PlaceId
    if id == 4442272183 then return "Sea 2"
    elseif id == 7449423635 then return "Sea 3"
    else return "Sea 1" end
end

-- 🌕 FULL MOON (PRO)
local function isFullMoon()
    local t = Lighting.ClockTime
    
    -- check time + darkness
    if t >= 0 and t <= 1 then
        if Lighting.Brightness <= 2 then
            return true
        end
    end
    
    return false
end

-- 🔍 BOSS (ANTI FAKE)
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

-- 🔍 ISLAND (ANTI FAKE PRO)
local function hasIsland()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") then
            
            for _, i in pairs(islands) do
                if string.lower(v.Name) == string.lower(i) then
                    
                    local part = v:FindFirstChildWhichIsA("BasePart")
                    
                    if part then
                        local pos = part.Position.Magnitude
                        local size = part.Size.Magnitude
                        
                        -- chống island ảo
                        if pos > 3000 and size > 80 then
                            return true, i
                        end
                    end
                end
            end
        end
    end
    return false
end

-- 📤 EMBED (ĐẸP)
local function send(event, name)
    local key = event .. (name or "")
    if sentEvents[key] then return end
    sentEvents[key] = true

    local sea = getSea()

    local data = {
        ["username"] = "Scanner Pro ⚡",
        ["embeds"] = {{
            ["title"] = event.." ["..sea.."]",
            ["color"] = (event == "🌕 FULL MOON" and 65280)
                      or (event == "🔥 BOSS" and 16711680)
                      or 3447003,

            ["description"] =
                "**Event:**\n```"..event.."```\n\n" ..
                "**Name:**\n```"..(name or "N/A").."```\n\n" ..
                "**Players:**\n```"..#Players:GetPlayers().."/12```\n\n" ..
                "**JobId:**\n```"..game.JobId.."```\n\n" ..
                "**Join:**\n```lua\n" ..
                "game:GetService(\"ReplicatedStorage\").__ServerBrowser:InvokeServer(\"teleport\", \""..game.JobId.."\")\n```",

            ["footer"] = {["text"] = "Scanner Pro Max"},
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

-- 🚀 STREAM FIX (LOAD XA)
local function streamFix()
    pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                Players.LocalPlayer:RequestStreamAroundAsync(v.Position)
            end
        end
    end)
end

-- ⏳ LOAD MAP (QUAN TRỌNG)
local loadTime = math.random(30,60)
print("Loading map: "..loadTime.."s")
task.wait(loadTime)

-- 🔁 LOOP
while true do
    -- chống spam scan
    if tick() - lastScan >= 120 then
        lastScan = tick()

        -- load lại vùng xa
        streamFix()

        local sea = getSea()
        local full = isFullMoon()
        local boss, bossName = hasBoss()
        local island, islandName = hasIsland()

        -- 🌕 FULL MOON (ưu tiên cao nhất)
        if full and sea == "Sea 3" then
            send("🌕 FULL MOON")

        -- 👹 BOSS
        elseif boss then
            if not (sea == "Sea 2" and string.lower(bossName):find("indra")) then
                send("🔥 BOSS", bossName)
            end

        -- 🏝️ ISLAND
        elseif island then
            send("🏝️ ISLAND", islandName)
        end
    end

    task.wait(1)
end
