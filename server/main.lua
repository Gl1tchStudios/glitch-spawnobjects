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

    if #ignoreSceneTypes > 0 then
        local placeholders = string.rep("?,", #ignoreSceneTypes):sub(1, -2)

        MySQL.query('SELECT * FROM synced_objects WHERE (sceneType NOT IN (' .. placeholders .. ') OR sceneType IS NULL)', ignoreSceneTypes, function(result)
            TriggerClientEvent('glitch-spawnobjects:receiveSyncedObjects', src, result)
        end)
    else
        MySQL.query('SELECT * FROM synced_objects', {}, function(result)
            TriggerClientEvent('glitch-spawnobjects:receiveSyncedObjects', src, result)
        end)
    end
end)

RegisterNetEvent("glitch-spawnobjects:createNewSyncedObject", function(model, data, sceneType)
    local src = source
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

            if sceneType then
                sceneType = string.lower(sceneType)
            end

            MySQL.insert('INSERT INTO synced_objects (model, posX, posY, posZ, rotX, rotY, rotZ, identifier, sceneType) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                model, posX, posY, posZ, rotX, rotY, rotZ, identifier, sceneType
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
                        identifier = identifier
                    }
                    TriggerClientEvent("glitch-spawnobjects:addNewSyncedProp", -1, newProp)

                    sendDiscordLog(src, "Synced Objects", GetPlayerName(src).." ["..steamIdentifier.."] ("..src..") placed a synced object (" .. model .. ") at position: (" .. posX .. ", " .. posY .. ", " .. posZ .. ") and rotation: (" .. rotX .. ", " .. rotY .. ", " .. rotZ .. ") with id: ("..insertId..")")
                else
                    TriggerClientEvent('ox_lib:notify', src, {title = '', description = "An error occurred while creating a synced object!", type = "error", duration = 5000})
                end
            end)
        else
            TriggerClientEvent('ox_lib:notify', src, {title = '', description = "Invalid data received.", type = "error", duration = 5000})
        end
    end
end)

RegisterNetEvent("glitch-spawnobjects:updateSyncedObject", function(model, data, objectID)
    local src = source
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
                    TriggerClientEvent("glitch-spawnobjects:addNewSyncedProp", -1, updatedProp)

                    sendDiscordLog(src, "Synced Objects", GetPlayerName(src).." ["..steamIdentifier.."] ("..src..") updated a synced object (" .. model .. ") at position: (" .. posX .. ", " .. posY .. ", " .. posZ .. ") and rotation: (" .. rotX .. ", " .. rotY .. ", " .. rotZ .. ") with id: ("..objectID..")")
                else
                    TriggerClientEvent('ox_lib:notify', src, {title = '', description = "An error occurred while updating the synced object!", type = "error", duration = 5000})
                end
            end)
        else
            TriggerClientEvent('ox_lib:notify', src, {title = '', description = "Invalid data received.", type = "error", duration = 5000})
        end
    end
end)

RegisterServerEvent("glitch-spawnobjects:deleteSyncedObject")
AddEventHandler("glitch-spawnobjects:deleteSyncedObject", function(id)
    local src = source
    local steamIdentifier = nil

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.sub(id, 1, 6) == "steam:" then
            steamIdentifier = id
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

                            sendDiscordLog(src, "Synced Objects", GetPlayerName(src).." ["..steamIdentifier.."] ("..src..") deleted a synced object (" .. model .. ") at position: (" .. posX .. ", " .. posY .. ", " .. posZ .. ") with id: ("..id..")")
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
end)