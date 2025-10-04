local function getSteamAvatarURL(steamID, callback)
    local steamApiKey = GetConvar("steam_webApiKey", "DEFAULT_API_KEY")
    if not steamApiKey or steamApiKey == "DEFAULT_API_KEY" then
        print("Steam Web API Key is not set. Please set it in the server configuration.")
        callback(nil)
        return
    end

    local url = "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=" .. steamApiKey .. "&steamids=" .. steamID
    
    PerformHttpRequest(url, function(err, text, headers)
        if err == 200 then
            local data = json.decode(text)
            if data.response and data.response.players and data.response.players[1] then
                local avatarURL = data.response.players[1].avatarfull
                callback(avatarURL)
            else
                callback(nil)
            end
        else
            callback(nil)
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
end

function sendDiscordLog(source, title, message)
    local webhook = getApiKey('discordWebhook')
    if not webhook or webhook == '' or webhook == 'YOUR_DISCORD_WEBHOOK_API_KEY_HERE' then
        print("Discord webhook URL is not set. Please set it in apiKeys.lua.")
        return
    end
    
    if not source or source == 0 then
        local embed = {
            {
                ["title"] = title,
                ["description"] = message,
                ["color"] = 0x9370DB,
                ["footer"] = {
                    ["text"] = "Glitch Studios • " .. os.date("%B %d, %Y %I:%M:%S %p")
                }
            }
        }
        
        PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
            username = 'Glitch Studios',
            embeds = embed
        }), { ['Content-Type'] = 'application/json' })
        
        return
    end
    
    local playerName = GetPlayerName(source) or "Unknown"
    local authorName = playerName .. " | " .. tostring(source)

    local rawIdentifiers = {}
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        local prefix, value = id:match("([^:]+):(.+)")
        rawIdentifiers[prefix] = rawIdentifiers[prefix] or {}
        table.insert(rawIdentifiers[prefix], value)
    end

    local steamID = rawIdentifiers.steam and rawIdentifiers.steam[1]

    if steamID then
        getSteamAvatarURL(tonumber(steamID, 16), function(avatarURL)
            local steamProfile = steamID and ("https://steamcommunity.com/profiles/" .. tonumber(steamID, 16)) or nil
            local discordTag = rawIdentifiers.discord and rawIdentifiers.discord[1] and ("<@" .. rawIdentifiers.discord[1] .. ">") or nil

            local accountsSection = {}
            if steamProfile then table.insert(accountsSection, "Steam: " .. steamProfile) end
            if discordTag then table.insert(accountsSection, "Discord: " .. discordTag) end

            local identLines = {}
            for k, v in pairs(rawIdentifiers) do
                if k ~= "ip" then
                    for i, val in ipairs(v) do
                        local key = k
                        if k == "license" and i == 2 then key = "license2" end
                        table.insert(identLines, "[" .. key .. ":" .. val .. "]")
                    end
                end
            end

            local embed = {
                {
                    ["author"] = {
                        ["name"] = authorName,
                        ["icon_url"] = avatarURL
                    },
                    ["title"] = title,
                    ["description"] = message,
                    ["color"] = 0x9370DB,
                    ["fields"] = {},
                    ["footer"] = {
                        ["text"] = "Glitch Studios • " .. os.date("%B %d, %Y %I:%M:%S %p")
                    }
                }
            }

            if #accountsSection > 0 then
                table.insert(embed[1].fields, {
                    ["name"] = "Accounts",
                    ["value"] = table.concat(accountsSection, "\n"),
                    ["inline"] = false
                })
            end

            if #identLines > 0 then
                table.insert(embed[1].fields, {
                    ["name"] = "Identifiers",
                    ["value"] = "```\n" .. table.concat(identLines, " ") .. "\n```",
                    ["inline"] = false
                })
            end

            PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
                username = 'Glitch Studios',
                embeds = embed
            }), { ['Content-Type'] = 'application/json' })
        end)
    end
end