local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local Enemies = workspace:FindFirstChild("Enemies") or ReplicatedStorage:FindFirstChild("Enemies")
local CollectionService = game:GetService("CollectionService")
local Sea1IDs = {2753915549, 85211729168715}
local Sea2IDs = {4442272183, 79091703265657}
local Sea3IDs = {7449423635, 100117331123089}
local function isSea1() return table.find(Sea1IDs, game.PlaceId) ~= nil end
local function isSea2() return table.find(Sea2IDs, game.PlaceId) ~= nil end
local function isSea3() return table.find(Sea3IDs, game.PlaceId) ~= nil end
local sentFullMoon = false
local sentElite = false
local previousSword = nil
local sentLegendarySword = false
local PrehistoricSpawned = false
local MirageSpawned = false
local KitsuneSpawned = false
local sentNearFullMoon = false
local sentFruit = false
local sentDoughKing = false
local sentTyrantoftheSkies = false
local sentRipIndra = false
local sentCursedCaptain = false
local sentGreybeard2 = false
local sentDarkbeard = false 
local sentCakePrince = false
local sentSoulReaper = false
local sentBossEvent = false
local previousColor = nil
local sentHakiLegendary = false
local FrozenSpawned = false
local LeviathanSpawned = false
local previousHakiName = nil
local previousSea = nil
local lastBerryKey = ""
local player = Players.LocalPlayer
local pirateRaidCooldown = false
local lastPirateRaidSent = 0
local PIRATE_RAID_COOLDOWN = 20
local joinScript = string.format(
    'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)',
    game.PlaceId, game.JobId
)
local encodedJobId = tostring(game.JobId)
local WEBHOOK_URLS = {
    FullMoon = "https://discord.com/api/webhooks/1486382838256373800/t0dDpQd-NWa0obYARcM7F1DNy6bwAiljC4bf2J9Q0GvxEVOoMZepabIcXUXwuACeBOkW",
    MirageIsland = "https://discord.com/api/webhooks/1486382849622802634/DqPjA6RaQy2z4Wxw_tLsddltYB0dJgG4A_zx36LGqRax8pq8yakmE4DQAcfv6Mhb5Dv2",
    PrehistoricIsland = "https://discord.com/api/webhooks/1487094080646418522/uLAiVJFOxWqs7D0ad1or2Por13heNzT2gB9XvvMUyBUZTO-ErxfdDSpMbxeb8VLAYbV3",
    FruitSpawning = "https://discord.com/api/webhooks/1450106655663722561/7rKAfN94pF00lGBVDNEalIIHPgUU5Zdyn1GtOBfvsyIatkwzMGJpkc2PXcVNcbOB7nWY",
    SwordsLegendary = "https://discord.com/api/webhooks/1450106656724746414/pPhArZ3lZCd5VFgdAvfMm0jPjxLwj4x8BMid_AOkZ1JGmcQpctOrem5iS4csJEdFMcw0",
    HakiLegendary = "https://discord.com/api/webhooks/1450106657110626379/jih1LyuVJWG0d77ijpNfVb8Hr0ggpwE6IhIC6jPsbpCXjfzQ24IZ0P5KKUJygAyVHNy7",
    BossRaid = "https://discord.com/api/webhooks/1487094092461768726/e6VF83RjvlXm_RdXjodRrKMbG1i1CdRCl2lb5cW8raSYZhdFEpAn7uAnVGkuBeP7wHvu",
    BossNormal = "https://discord.com/api/webhooks/1487094092461768726/e6VF83RjvlXm_RdXjodRrKMbG1i1CdRCl2lb5cW8raSYZhdFEpAn7uAnVGkuBeP7wHvu",
    DoughKing = "https://discord.com/api/webhooks/1487094102016262174/hbrqq79VXzlFDg3jGSNxO_AgexagFiiYINXQSB2bwvjv_igkJWB3eXMagO17tJTF2xbe",
    RipIndra = "https://discord.com/api/webhooks/1487094102016262174/hbrqq79VXzlFDg3jGSNxO_AgexagFiiYINXQSB2bwvjv_igkJWB3eXMagO17tJTF2xbe",
    PirateRaid = "https://discord.com/api/webhooks/1487094102016262174/hbrqq79VXzlFDg3jGSNxO_AgexagFiiYINXQSB2bwvjv_igkJWB3eXMagO17tJTF2xbe",
    CakePrince = "https://discord.com/api/webhooks/1487094102016262174/hbrqq79VXzlFDg3jGSNxO_AgexagFiiYINXQSB2bwvjv_igkJWB3eXMagO17tJTF2xbe",
    SoulRipper = "https://discord.com/api/webhooks/1487094102016262174/hbrqq79VXzlFDg3jGSNxO_AgexagFiiYINXQSB2bwvjv_igkJWB3eXMagO17tJTF2xbe",
    BossEvent = "https://discord.com/api/webhooks/1487094092461768726/e6VF83RjvlXm_RdXjodRrKMbG1i1CdRCl2lb5cW8raSYZhdFEpAn7uAnVGkuBeP7wHvu",
    CursedCaptain = "https://discord.com/api/webhooks/1487094102016262174/hbrqq79VXzlFDg3jGSNxO_AgexagFiiYINXQSB2bwvjv_igkJWB3eXMagO17tJTF2xbe"}
local THUMBNAIL_URL = ""
local function fastHttpRequest(webhookUrl, options)
    options = options or {}
    options.Url = webhookUrl
    local requestFunc =
        (syn and syn.request) or
        request or
        http_request or
        (fluxus and fluxus.request) or
        (krnl and krnl.request)
    if requestFunc then
        task.spawn(function()
            local success, response = pcall(function()
                return requestFunc({
                    Url = options.Url,
                    Method = options.Method or "POST",
                    Headers = options.Headers or {
                        ["Content-Type"] = "application/json"
                    },
                    Body = options.Body and
                        (typeof(options.Body) == "table"
                            and HttpService:JSONEncode(options.Body)
                            or options.Body)
                        or ""})
            end)
            if options.Callback then
                options.Callback(success, response)
            end
        end)
        return true
    end
    if HttpService and HttpService.PostAsync then
        task.spawn(function()
            local success, response = pcall(function()
                return HttpService:PostAsync(
                    options.Url,
                    options.Body and
                        (typeof(options.Body) == "table"
                            and HttpService:JSONEncode(options.Body)
                            or options.Body)
                        or "",
                    Enum.HttpContentType.ApplicationJson
                )
            end)
            if options.Callback then
                options.Callback(success, response)
            end
        end)
        return true
    end
    warn("Không có HTTP method nào khả dụng")
    return false
end
local function createEmbedTemplate(title, color, fields)
    return {
        ["embeds"] = {{
            ["title"] = title or "Ziner Hub Notification",
            ["color"] = color or tonumber(0xc4f244),
            ["thumbnail"] = { ["url"] = THUMBNAIL_URL },
            ["fields"] = fields,
            ["footer"] = {["text"] = "Notify Blox Fruits Ziner Hub"},
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}}
end
local function createCommonFields(mainField, playerCount, currentSea)
    local fields = {
        {["name"] = mainField.name, ["value"] = "```" .. mainField.value .. "```", ["inline"] = mainField.inline or true},
        {["name"] = "**__Player Count:__**", ["value"] = "```" .. playerCount .. "/12```", ["inline"] = true},
        {["name"] = "**__World:__**", ["value"] = "```" .. currentSea .. "```", ["inline"] = true},
        {["name"] = "**__PlaceId::__**", ["value"] = "```" .. game.PlaceId .. "```", ["inline"] = true},
        {["name"] = "**__Job ID:__**", ["value"] = encodedJobId, ["inline"] = true},
        {["name"] = "**__Join Script:__**", ["value"] = joinScript, ["inline"] = true}}
    return fields
end
local function sendFastWebhook(eventName, title, mainField, currentSea)
    local playerCount = #Players:GetPlayers()
    local fields = createCommonFields(mainField, playerCount, currentSea)
    local data = createEmbedTemplate(title, tonumber(0xc4f244), fields)    
    local jsonData = HttpService:JSONEncode(data)    
    local webhookUrl = WEBHOOK_URLS[eventName]
    if webhookUrl then
        fastHttpRequest(webhookUrl, {
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
    end
end
local function FullMoonWebhook()
    sendFastWebhook("FullMoon", "Ziner Hub Notification", 
        {name = "**__Moon Phase:__**", value = "Full Moon 100%"}, "Sea 3")
end
local function sendPrehistoricWebhook()
    sendFastWebhook("PrehistoricIsland", "Ziner Hub Notification",
        {name = "**__Prehistoric Island Status:__**", value = "Prehistoric Island spawned ✅"}, "Sea 3")
end
local function MirageWebhook()
    sendFastWebhook("MirageIsland", "Ziner Hub Notification",
        {name = "**__Mirage Island Status:__**", value = "Mirage Island Spawned ✅"}, "Sea 3")
end
local function sendBerryWebhook()
    local currentSea = isSea1() and "Sea 1" or isSea2() and "Sea 2" or isSea3() and "Sea 3" or "Unknown Sea"
    local bushes = CollectionService:GetTagged("BerryBush")
    local berrySet = {}
    
    for _, bush in ipairs(bushes) do
        for _, value in pairs(bush:GetAttributes()) do
            if typeof(value) == "string" and value ~= "" then
                berrySet[value] = true
            end
        end
    end
     local berryList = {}
    for name in pairs(berrySet) do
        table.insert(berryList, name)
    end
    table.sort(berryList)    
    sendFastWebhook("BerriesFruit", "Ziner Hub Notification",
        {name = "**__Berries Fruits:__**", value = table.concat(berryList, ", "), inline = false}, currentSea)
end
local function sendFruitWebhook(fruitName)
    local currentSea = isSea1() and "Sea 1" or isSea2() and "Sea 2" or isSea3() and "Sea 3" or "Unknown Sea"
    sendFastWebhook("FruitSpawning", "Ziner Hub Notification",
        {name = "**__Fruits Spawned:__**", value = fruitName}, currentSea)
end
local function senddoughkingWebhook()
    sendFastWebhook("DoughKing", "Ziner Hub Notification",
        {name = "**__Status Boss Dough King:__**", value = "Dough King Spawned ✅"}, "Sea 3")
end
local function sendRipIndraWebhook()
    sendFastWebhook("RipIndra", "Ziner Hub Notification",
        {name = "**__Status Boss Rip Indra:__**", value = "Rip Indra True Form Spawned ✅"}, "Sea 3")
end
local function sendSoulReaperWebhook()
    sendFastWebhook("SoulRipper", "Ziner Hub Notification",
        {name = "**__Status Boss Soul Reaper:__**", value = "Soul Reaper Spawned ✅"}, "Sea 3")
end
local function sendCakePrinceWebhook()
    sendFastWebhook("CakePrince", "Ziner Hub Notification",
        {name = "**__Status Boss Cake Prince:__**", value = "Cake Prince Spawned ✅"}, "Sea 3")
end
local function sendCursedCaptainWebhook()
    sendFastWebhook("CursedCaptain", "Ziner Hub Notification",
        {name = "**__Status Boss Cursed Captain:__**", value = "Cursed Captain Spawned ✅"}, "Sea 2")
end
local function sendLegendarySwordWebhook(swordName)
    sendFastWebhook("SwordsLegendary", "Ziner Hub Notification",
        {name = "**__Sword Legendary:__**", value = swordName}, "Sea 2")
end
local function sendHakiLegendaryWebhook(colorName)
    local currentSea = isSea2() and "Sea 2" or isSea3() and "Sea 3" or "Unknown Sea"
    sendFastWebhook("HakiLegendary", "Ziner Hub Notification",
        {name = "**__Name Haki Legendary:__**", value = colorName}, currentSea)
end
local function sendBossEventWebhook(bossName)
    sendFastWebhook("BossEvent", "Ziner Hub Notification",
        {name = "**__Status Boss " .. bossName .. ":__**", value = bossName .. " Spawned ✅"}, "Sea 3")
end
local function sendBossAllWebhook(BossAllName)
    local currentSea = isSea1() and "Sea 1" or isSea2() and "Sea 2" or isSea3() and "Sea 3" or "Unknown"
    sendFastWebhook("BossRaid", "Ziner Hub Notification",
        {name = "*__Name Boss:__**", value = BossAllName .. " Spawned ✅"}, currentSea)
end
local function sendPirateRaidWebhook(raidMessage)
    local currentSea = isSea1() and "Sea 1" or isSea2() and "Sea 2" or isSea3() and "Sea 3" or "Unknown"
    sendFastWebhook("PirateRaid", "Ziner Hub Notification",
        {name = "**__Pirate Raid:__**", value = raidMessage, inline = false}, currentSea)
end
local function sendBossNormalWebhook(spawnedBosses)
    local currentSea = isSea1() and "Sea 1" or isSea2() and "Sea 2" or isSea3() and "Sea 3" or "Unknown"
    sendFastWebhook("BossNormal", "Ziner Hubb Notification",
        {name = "**__Name Boss Normal__**", value = table.concat(spawnedBosses, ", "), inline = false}, currentSea)
end
local BossList = {
    ["Sea 1"] = {
        "The Saw", "The Gorilla King", "Bobby", "Yeti", "Mob Leader", 
        "Vice Admiral", "Warden", "Chief Warden", "Swan", "Magma Admiral", 
        "Fishman Lord", "Wysper", "Thunder God", "Cyborg", "Saber Expert"},
    ["Sea 2"] = {
        "Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral", 
        "Cursed Captain", "Darkbeard", "Order", "Awakened Ice Admiral", "Tide Keeper"},
    ["Sea 3"] = {
        "Stone", "Island Empress", "Rocket Admiral", "Captain Elephant", 
        "Beautiful Pirate", "rip_indra True Form", "Longma", "Soul Reaper", 
        "Cake Queen", "Cake Prince", "Dough King"}}
   local BossList2 = {
    ["Sea2"] = {"Cursed Captain"},
    ["Sea3"] = {"Cake Prince", "rip_indra True Form", "Dough King", "Soul Reaper"}}
local sentBosses = {}
local sentBoss2 = {}
local lastNormalBossCheck = 0
local NORMAL_BOSS_COOLDOWN = 30
local function CheckNotify(searchText)
    local player = Players.LocalPlayer
    if not player then return false end    
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return false end    
    local notifications = gui:FindFirstChild("Notifications")
    if not notifications then return false end    
    for _, v in pairs(notifications:GetChildren()) do
        if v and v:IsA("TextLabel") and v.Text then
            if string.find(string.lower(v.Text), searchText:lower()) then
                return true
            end
        end
    end
    return false
end
task.spawn(function()
    while true do
        task.wait(1)
        if isSea2() and not sentCursedCaptain then
            if (ReplicatedStorage:FindFirstChild("Cursed Captain") ~= nil) or (Enemies and Enemies:FindFirstChild("Cursed Captain") ~= nil) then
                sendCursedCaptainWebhook()
                sentCursedCaptain = true
                task.wait(30)
                sentCursedCaptain = false
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(1)
        if isSea3() and not sentCakePrince then
            if (ReplicatedStorage:FindFirstChild("Cake Prince") ~= nil) or (Enemies and Enemies:FindFirstChild("Cake Prince") ~= nil) then
                sendCakePrinceWebhook()
                sentCakePrince = true
                task.wait(30)
                sentCakePrince = false
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(1)
        if isSea3() and not sentRipIndra then
            if (ReplicatedStorage:FindFirstChild("rip_indra True Form") ~= nil) or (Enemies and Enemies:FindFirstChild("rip_indra True Form") ~= nil) then
                sendRipIndraWebhook()
                sentRipIndra = true
                task.wait(30)
                sentRipIndra = false
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(1)
        if isSea3() and not sentDoughKing then
            if (ReplicatedStorage:FindFirstChild("Dough King") ~= nil) or (Enemies and Enemies:FindFirstChild("Dough King") ~= nil) then
                senddoughkingWebhook()
                sentDoughKing = true
                task.wait(30)
                sentDoughKing = false
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(1)
        if isSea3() and not sentSoulReaper then
            if (ReplicatedStorage:FindFirstChild("Soul Reaper") ~= nil) or (Enemies and Enemies:FindFirstChild("Soul Reaper") ~= nil) then
                sendSoulReaperWebhook()
                sentSoulReaper = true
                task.wait(30)
                sentSoulReaper = false
            end
        end
    end
end)
task.spawn(function()
    while task.wait(2) do
        if isSea3() then
            local sky = Lighting:FindFirstChildOfClass("Sky")
            if sky then
                if sky.MoonTextureId == "http://www.roblox.com/asset/?id=9709149431" then
                    if not sentFullMoon then
                        sentFullMoon = true
                        FullMoonWebhook()
                    end
                else
                    sentFullMoon = false
                end               
                if sky.MoonTextureId == "http://www.roblox.com/asset/?id=9709149052" then
                    if not sentNearFullMoon then
                        sentNearFullMoon = true
                        NearFullMoonWeb()
                    end
                else
                    sentNearFullMoon = false
                end
            end
        end
    end
end)
task.spawn(function()
    while task.wait(2) do
        local locations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
        if locations then
            local Prehistoric = locations:FindFirstChild("Prehistoric Island")
            if Prehistoric then
                if not PrehistoricSpawned then
                    PrehistoricSpawned = true
                    sendPrehistoricWebhook()
                end
            else
                PrehistoricSpawned = false
            end
            local Mirage = locations:FindFirstChild("Mirage Island")
            if Mirage then
                if not MirageSpawned then
                    MirageSpawned = true
                    MirageWebhook()
                end
            else
                MirageSpawned = false
            end            
            local Kitsune = locations:FindFirstChild("Kitsune Island")
            if Kitsune then
                if not KitsuneSpawned then
                    KitsuneSpawned = true
                    KitsuneWebhook()
                end
            else
                KitsuneSpawned = false
            end
        end
    end
end)
task.spawn(function()
    while task.wait(2) do
        if not sentFruit then
            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Tool") and string.find(v.Name:lower(), "fruit") then
                    local handle = v:FindFirstChild("Handle")
                    if handle then
                        sendFruitWebhook(v.Name)
                        sentFruit = true
                        task.wait(30)
                        sentFruit = false
                        break
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while task.wait(2) do
        if isSea2() then
            local currentSword = nil
            local success, result
            
            for i = 1, 3 do
                success, result = pcall(function()
                    if ReplicatedStorage and ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_") then
                        return ReplicatedStorage.Remotes.CommF_:InvokeServer("LegendarySwordDealer", tostring(i))
                    end
                    return nil
                end)               
                if success and result then
                    if i == 1 then currentSword = "Shizu"
                    elseif i == 2 then currentSword = "Oroshi"
                    elseif i == 3 then currentSword = "Saishi" end
                    break
                end
            end            
            if currentSword and currentSword ~= previousSword and not sentLegendarySword then
                sendLegendarySwordWebhook(currentSword)
                previousSword = currentSword
                sentLegendarySword = true
                task.wait(30)
                sentLegendarySword = false
            elseif not currentSword and previousSword then
                previousSword = nil
            end
        end
    end
end)
task.spawn(function()
    while task.wait(2) do
        local currentSea = isSea2() and "Sea 2" or isSea3() and "Sea 3" or nil        
        if currentSea then
            local currentColor = nil
            local success, result            
            for i = 1, 3 do
                success, result = pcall(function()
                    if ReplicatedStorage and ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_") then
                        return ReplicatedStorage.Remotes.CommF_:InvokeServer("ColorsDealer", tostring(i))
                    end
                    return nil
                end)               
                if success and result then
                    if i == 1 then currentColor = "Snow White"
                    elseif i == 2 then currentColor = "Pure Red"
                    elseif i == 3 then currentColor = "Winter Sky" end
                    break
                end
            end          
            if currentColor and (currentColor ~= previousColor or currentSea ~= previousSea) and not sentHakiLegendary then
                sendHakiLegendaryWebhook(currentColor)
                previousColor = currentColor
                previousSea = currentSea
                sentHakiLegendary = true
                task.wait(30)
                sentHakiLegendary = false
            elseif not currentColor and previousColor then
                previousColor = nil
                previousSea = nil
            end
        end
    end
end)
task.spawn(function()
    while task.wait(2) do
        local currentHakiName = nil
        local success, result        
        for i = 1, 100 do
            success, result = pcall(function()
                if ReplicatedStorage and ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_") then
                    return ReplicatedStorage.Remotes.CommF_:InvokeServer("ColorsDealer", tostring(i))
                end
                return nil
            end)         
            if success and type(result) == "string" and result ~= "" then
                currentHakiName = result
                break
            end
        end        
        if currentHakiName and currentHakiName ~= previousHakiName then
            sendHakiWebhook(currentHakiName)
            previousHakiName = currentHakiName
            task.wait(30)
            previousHakiName = nil
        end
    end
end)
task.spawn(function()
    while task.wait(0.5) do
        if not pirateRaidCooldown then
            local raidDetected = false
            local raidMessage = ""           
            if isSea3() then
                if CheckNotify("Pirates have been spotted approaching the castle!") then
                    raidDetected = true
                    raidMessage = "Pirates have been spotted approaching the castle!"
                elseif CheckNotify("The pirates are raiding Castle on the Sea!") then
                    raidDetected = true
                    raidMessage = "The pirates are raiding Castle on the Sea!"
                end
            end            
            if raidDetected then
                local currentTime = tick()
                if (currentTime - lastPirateRaidSent) > PIRATE_RAID_COOLDOWN then
                    sendPirateRaidWebhook(raidMessage)
                    lastPirateRaidSent = currentTime
                    pirateRaidCooldown = true
                    task.wait(PIRATE_RAID_COOLDOWN)
                    pirateRaidCooldown = false
                end
            end
        end
    end
end)
task.spawn(function()
    while task.wait(2) do
        local currentTime = tick()
        if currentTime - lastNormalBossCheck > NORMAL_BOSS_COOLDOWN then
            local currentSea = isSea1() and "Sea 1" or isSea2() and "Sea 2" or isSea3() and "Sea 3" or nil
            if currentSea and BossList[currentSea] then
                local spawnedBosses = {}
                local availableBosses = BossList[currentSea]                
                for _, bossName in pairs(availableBosses) do
                    if (ReplicatedStorage:FindFirstChild(bossName) ~= nil) or
                       (Enemies and Enemies:FindFirstChild(bossName) ~= nil) then
                        if not sentBosses[bossName] then
                            table.insert(spawnedBosses, bossName)
                            sentBosses[bossName] = true
                        end
                    else
                        sentBosses[bossName] = nil
                    end
                end                
                if #spawnedBosses > 0 then
                    sendBossNormalWebhook(spawnedBosses)
                end                
                lastNormalBossCheck = currentTime
            end
        end
    end
end)
task.spawn(function()
    local selectedBoss = "Unbound Werewolf"
    while task.wait(2) do
        if isSea3() and not sentBossEvent then
            if (ReplicatedStorage:FindFirstChild(selectedBoss) ~= nil) or (Enemies and Enemies:FindFirstChild(selectedBoss) ~= nil) then
                sendBossEventWebhook(selectedBoss)
                sentBossEvent = true
                task.wait(60)
                sentBossEvent = false
            end
        end
    end
end)
task.spawn(function()
    while task.wait(2) do
        local sea = isSea1() and "Sea1" or isSea2() and "Sea2" or isSea3() and "Sea3"
        if sea and BossList2[sea] then
            for _, bossName in ipairs(BossList2[sea]) do
                if not sentBoss2[bossName] then
                    local found = (ReplicatedStorage:FindFirstChild(bossName) ~= nil) or
                                  (Enemies and Enemies:FindFirstChild(bossName) ~= nil)
                    if found then
                        sendBossAllWebhook(bossName)
                        sentBoss2[bossName] = true
                        task.wait(30)
                        sentBoss2[bossName] = false
                    end
                end
            end
        end
    end
end)

print("Ziner Hub Notify Stars")
