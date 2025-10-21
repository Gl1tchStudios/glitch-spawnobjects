local function fetchPredefinedProps()
    if not Config.enablePredefinedProps or not Config.predefinedPropsUrl then
        return
    end

    PerformHttpRequest(Config.predefinedPropsUrl, function(statusCode, response, headers)
        if statusCode == 200 and response then
            local props = {}
            local count = 0
            
            -- Parse the INI file - each line is an object name
            for line in response:gmatch("[^\r\n]+") do
                -- Skip empty lines and comments
                if line ~= "" and not line:match("^%s*;") and not line:match("^%s*%[") then
                    local objectName = line:match("^%s*(.-)%s*$") -- Trim whitespace
                    if objectName and objectName ~= "" then
                        table.insert(props, {
                            value = objectName,
                            label = objectName
                        })
                        count = count + 1
                    end
                end
            end
            
            Config.predefinedProps = props
            
            if Config.Debug then
                print(string.format("^2[glitch-spawnobjects]^7 Successfully loaded %d objects from GitHub", count))
            end
            
            TriggerClientEvent('glitch-spawnobjects:receivePredefinedProps', -1, props)
        else
            print(string.format("^1[glitch-spawnobjects]^7 Failed to fetch object list from GitHub (Status: %s)", statusCode))
        end
    end, 'GET')
end

CreateThread(function()
    Wait(1000)
    fetchPredefinedProps()
end)

lib.callback.register('glitch-spawnobjects:getPredefinedProps', function(source)
    return Config.predefinedProps
end)

local function isAllowedAccess(src)
    if Config.permissionSystem == "everyone" then
        return true
    elseif Config.permissionSystem == "ace" then
        return IsPlayerAceAllowed(src, Config.acePermission)
    elseif Config.permissionSystem == "discord" then
        local ids = GetPlayerIdentifiers(src)
        for _, id in ipairs(ids) do
            if string.match(id, "discord:") then
                local discordId = string.gsub(id, "discord:", "")
                for _, role in ipairs(Config.allowedDiscordAccess) do
                    -- YOU ARE REQUIRED TO ADD YOUR OWN DISCORD PERMISSION CHECKING LOGIC HERE
                    return true
                end
            end
        end
        return false
    elseif Config.permissionSystem == "steam" then
        for i = 0, GetNumPlayerIdentifiers(src) - 1 do
            local id = GetPlayerIdentifier(src, i)
            if string.sub(id, 1, 6) == "steam:" then
                for _, allowedId in ipairs(Config.allowedSteamIDs) do
                    if id == allowedId then
                        return true
                    end
                end
            end
        end
        return false
    elseif Config.permissionSystem == "license" then
        local identifiers = GetPlayerIdentifiers(src)
        for _, id in pairs(identifiers) do
            if string.match(id, "license:") then
                for _, allowedLicense in ipairs(Config.allowedLicenses) do
                    if id == allowedLicense then
                        return true
                    end
                end
            end
        end
        return false
    end
    
    return false
end

lib.callback.register('glitch-spawnobjects:checkPermission', function(source)
    local src = source
    return isAllowedAccess(src)
end)

RegisterNetEvent('glitch-spawnobjects:requestSyncedObjects')
AddEventHandler('glitch-spawnobjects:requestSyncedObjects', function()
    local src = source
    local ignoreSceneTypes = Config.ignoreSceneType or {}
    local currentTime = os.time()

    if #ignoreSceneTypes > 0 then
        local placeholders = string.rep("?,", #ignoreSceneTypes):sub(1, -2)
        local queryParams = {}
        
        for i, sceneType in ipairs(ignoreSceneTypes) do
            queryParams[i] = sceneType
        end
        queryParams[#queryParams + 1] = currentTime

        MySQL.query('SELECT * FROM synced_objects WHERE (sceneType NOT IN (' .. placeholders .. ') OR sceneType IS NULL) AND (expiryTime IS NULL OR expiryTime > ?)', 
            queryParams, function(result)
            TriggerClientEvent('glitch-spawnobjects:receiveSyncedObjects', src, result)
        end)
    else
        MySQL.query('SELECT * FROM synced_objects WHERE (expiryTime IS NULL OR expiryTime > ?)', {currentTime}, function(result)
            TriggerClientEvent('glitch-spawnobjects:receiveSyncedObjects', src, result)
        end)
    end
end)

local function createSyncedObject(src, model, data, sceneType, duration)
    local steamIdentifier = nil

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.sub(id, 1, 6) == "steam:" then
            steamIdentifier = id
            break
        end
    end

    if isAllowedAccess(src) then
        if model and data and data.position and data.rotation then
            local posX, posY, posZ = data.position.x, data.position.y, data.position.z
            local rotX, rotY, rotZ = data.rotation.x, data.rotation.y, data.rotation.z
            local identifier = steamIdentifier
            local sceneType = (sceneType and sceneType ~= "") and sceneType or nil
            local expiryTime = nil
            
            if duration and duration > 0 then
                expiryTime = os.time() + (duration * 60)
            end

            if sceneType then
                sceneType = string.lower(sceneType)
            end

            MySQL.insert('INSERT INTO synced_objects (model, posX, posY, posZ, rotX, rotY, rotZ, identifier, sceneType, expiryTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                model, posX, posY, posZ, rotX, rotY, rotZ, identifier, sceneType, expiryTime
            }, function(insertId)
                if insertId then
                    local newProp = {
                        id = insertId,
                        model = model,
                        sceneType = sceneType,
                        posX = posX,
                        posY = posY,
                        posZ = posZ,
                        rotX = rotX,
                        rotY = rotY,
                        rotZ = rotZ,
                        identifier = identifier,
                        expiryTime = expiryTime
                    }
                    TriggerClientEvent("glitch-spawnobjects:addNewSyncedObject", -1, newProp)

                    local durationInfo = ""
                    if expiryTime then
                        local remainingTime = math.ceil((expiryTime - os.time()) / 60)
                        durationInfo = " | Duration: " .. (duration or 0) .. " minutes | Expires at: " .. os.date("%Y-%m-%d %H:%M:%S", expiryTime) .. " | Remaining: " .. remainingTime .. " minutes"
                    else
                        durationInfo = " | Duration: Permanent"
                    end
                    
                    local sceneInfo = sceneType and (" | Scene Type: " .. sceneType) or " | Scene Type: None"
                    
                    sendDiscordLog(src, "Synced Objects", "**OBJECT PLACED**\n" ..
                        "Player: " .. GetPlayerName(src) .. " [" .. steamIdentifier .. "] (" .. src .. ")\n" ..
                        "Model: " .. model .. "\n" ..
                        "Position: (" .. posX .. ", " .. posY .. ", " .. posZ .. ")\n" ..
                        "Rotation: (" .. rotX .. ", " .. rotY .. ", " .. rotZ .. ")\n" ..
                        "Object ID: " .. insertId .. sceneInfo .. durationInfo)
                else
                    TriggerClientEvent('ox_lib:notify', src, {title = '', description = "An error occurred while creating a synced object!", type = "error", duration = 5000})
                end
            end)
        else
            TriggerClientEvent('ox_lib:notify', src, {title = '', description = "Invalid data received.", type = "error", duration = 5000})
        end
    end
end

RegisterNetEvent("glitch-spawnobjects:createNewSyncedObject", function(model, data, sceneType, duration)
    local src = source
    createSyncedObject(src, model, data, sceneType, duration)
end)

local function updateSyncedObject(src, model, data, objectID)
    local steamIdentifier = nil

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.sub(id, 1, 6) == "steam:" then
            steamIdentifier = id
            break
        end
    end

    if isAllowedAccess(src) then
        if model and data and data.position and data.rotation then
            local posX, posY, posZ = data.position.x, data.position.y, data.position.z
            local rotX, rotY, rotZ = data.rotation.x, data.rotation.y, data.rotation.z
            local identifier = steamIdentifier

            MySQL.update('UPDATE synced_objects SET posX = ?, posY = ?, posZ = ?, rotX = ?, rotY = ?, rotZ = ?, identifier = ? WHERE id = ? AND model = ?', {
                posX, posY, posZ, rotX, rotY, rotZ, identifier, objectID, model
            }, function(rowsAffected)
                if rowsAffected > 0 then
                    local updatedProp = {
                        id = objectID,
                        model = model,
                        posX = posX,
                        posY = posY,
                        posZ = posZ,
                        rotX = rotX,
                        rotY = rotY,
                        rotZ = rotZ,
                        identifier = identifier
                    }
                    TriggerClientEvent("glitch-spawnobjects:addNewSyncedObject", -1, updatedProp)

                    sendDiscordLog(src, "Synced Objects", "**OBJECT UPDATED**\n" ..
                        "Player: " .. GetPlayerName(src) .. " [" .. steamIdentifier .. "] (" .. src .. ")\n" ..
                        "Model: " .. model .. "\n" ..
                        "New Position: (" .. posX .. ", " .. posY .. ", " .. posZ .. ")\n" ..
                        "New Rotation: (" .. rotX .. ", " .. rotY .. ", " .. rotZ .. ")\n" ..
                        "Object ID: " .. objectID)
                else
                    TriggerClientEvent('ox_lib:notify', src, {title = '', description = "An error occurred while updating the synced object!", type = "error", duration = 5000})
                end
            end)
        else
            TriggerClientEvent('ox_lib:notify', src, {title = '', description = "Invalid data received.", type = "error", duration = 5000})
        end
    end
end

RegisterNetEvent("glitch-spawnobjects:updateSyncedObject", function(model, data, objectID)
    local src = source
    updateSyncedObject(src, model, data, objectID)
end)

local function deleteSyncedObject(src, id)
    local steamIdentifier = nil

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local identifier = GetPlayerIdentifier(src, i)
        if string.sub(identifier, 1, 6) == "steam:" then
            steamIdentifier = identifier
            break
        end
    end

    if isAllowedAccess(src) then
        if id then
            MySQL.query("SELECT * FROM synced_objects WHERE `id` = ?", {id}, function(result)
                if result[1] then
                    local object = result[1]
                    local model = object.model
                    local posX, posY, posZ = object.posX, object.posY, object.posZ

                    MySQL.query("DELETE FROM synced_objects WHERE `id` = ?", {id}, function(deleteResult)
                        if deleteResult then
                            TriggerClientEvent("glitch-spawnobjects:receiveDeletedSyncedObject", -1, id)
                            TriggerClientEvent('ox_lib:notify', src, {title = '', description = "The synced object ("..model..") was successfully removed.", type = "success", duration = 5000})

                            local expiryInfo = ""
                            if object.expiryTime then
                                expiryInfo = "\nExpiry Time: " .. os.date("%Y-%m-%d %H:%M:%S", object.expiryTime)
                            else
                                expiryInfo = "\nDuration: Permanent"
                            end
                            
                            local sceneInfo = object.sceneType and ("\nScene Type: " .. object.sceneType) or "\nScene Type: None"
                            
                            sendDiscordLog(src, "Synced Objects", "**OBJECT DELETED**\n" ..
                                "Player: " .. GetPlayerName(src) .. " [" .. steamIdentifier .. "] (" .. src .. ")\n" ..
                                "Model: " .. model .. "\n" ..
                                "Position: (" .. posX .. ", " .. posY .. ", " .. posZ .. ")\n" ..
                                "Object ID: " .. id .. sceneInfo .. expiryInfo)
                        else
                            TriggerClientEvent('ox_lib:notify', src, {title = '', description = "Error occured while deleting the synced object ("..model..")", type = "error", duration = 5000})
                        end
                    end)
                else
                    TriggerClientEvent('ox_lib:notify', src, {title = '', description = "Error occured while deleting the synced object.", type = "error", duration = 5000})
                end
            end)
        end
    end
end

RegisterServerEvent("glitch-spawnobjects:deleteSyncedObject")
AddEventHandler("glitch-spawnobjects:deleteSyncedObject", function(id)
    local src = source
    deleteSyncedObject(src, id)
end)

CreateThread(function()
    while true do
        Wait(60000)
        
        local currentTime = os.time()
        
        MySQL.query('SELECT id, model, posX, posY, posZ, identifier, sceneType, expiryTime FROM synced_objects WHERE expiryTime IS NOT NULL AND expiryTime <= ?', {currentTime}, function(expiredObjects)
            if expiredObjects and #expiredObjects > 0 then
                local expiredIds = {}
                local logDetails = {}
                
                for _, obj in ipairs(expiredObjects) do
                    table.insert(expiredIds, obj.id)
                    table.insert(logDetails, string.format("ID: %s | Model: %s | Pos: (%.2f, %.2f, %.2f) | Creator: %s | Scene: %s | Expired: %s", 
                        obj.id, obj.model, obj.posX, obj.posY, obj.posZ, 
                        obj.identifier or "Unknown", obj.sceneType or "None", 
                        os.date("%Y-%m-%d %H:%M:%S", obj.expiryTime)))
                end
                
                local placeholders = string.rep("?,", #expiredIds):sub(1, -2)
                MySQL.query('DELETE FROM synced_objects WHERE id IN (' .. placeholders .. ')', expiredIds, function(deleteResult)
                    if deleteResult then
                        for _, objId in ipairs(expiredIds) do
                            TriggerClientEvent("glitch-spawnobjects:receiveDeletedSyncedObject", -1, objId)
                        end
                        
                        if Config.Debug then
                            print(string.format("^3[Glitch Spawn Objects] Cleaned up %d expired objects:^0", #expiredIds))
                            for _, detail in ipairs(logDetails) do
                                print("^3  " .. detail .. "^0")
                            end
                        end
                        
                        if #expiredIds > 0 then
                            local discordMessage = "**AUTOMATIC CLEANUP**\n" ..
                                "Removed " .. #expiredIds .. " expired objects:\n```\n"
                            for _, detail in ipairs(logDetails) do
                                discordMessage = discordMessage .. detail .. "\n"
                            end
                            discordMessage = discordMessage .. "```"
                            sendDiscordLog(nil, "Synced Objects", discordMessage)
                        end
                    end
                end)
            end
        end)
    end
end)

-- Exports
exports('createObject', function(src, model, data, sceneType, duration)
    return createSyncedObject(src, model, data, sceneType, duration)
end)

exports('updateObject', function(src, model, data, objectID)
    return updateSyncedObject(src, model, data, objectID)
end)

exports('deleteObject', function(src, id)
    return deleteSyncedObject(src, id)
end)