lib.locale()
local objectList = {}

local function isAllowedAccess()
    local hasPermission = lib.callback.await('glitch-spawnobjects:checkPermission', false)
    return hasPermission
end

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        local tasks = {}

        for index, object in pairs(objectList) do
            local objectCoords = vector3(object.posX, object.posY, object.posZ)
            local dist = #(playerCoords - objectCoords)
            
            if dist < Config.renderDistance then
                if not object.isRendered then
                    table.insert(tasks, function()
                        RequestModel(object.model)
                        while not HasModelLoaded(object.model) do Wait(0) end

                        local obj = CreateObject(object.model, object.posX, object.posY, object.posZ, false, false, false)
                        SetEntityCoords(obj, object.posX, object.posY, object.posZ, false, false, false, false)
                        SetEntityRotation(obj, object.rotX, object.rotY, object.rotZ, 2, true)
                        SetEntityAlpha(obj, 0)
                        FreezeEntityPosition(obj, true)

                        object.isRendered = true
                        object.object = obj

                        for i = 0, 255, 51 do
                            Wait(50)
                            SetEntityAlpha(obj, i, false)
                        end

                        SetModelAsNoLongerNeeded(object.model)

                        if Config.Debug then
                            print(string.format("^2[DEBUG] Rendered Object: %s (ID: %s) at %.2f, %.2f, %.2f^0", 
                                object.model, object.id or "Unknown", object.posX, object.posY, object.posZ))
                        end
                    end)
                end
            elseif object.isRendered then
                if DoesEntityExist(object.object) then
                    local objToRemove = object.object
                    object.isRendered = false
                    object.object = nil
                    CreateThread(function()
                        removeObject(objToRemove)

                        if Config.Debug then
                            print(string.format("^1[DEBUG] Removed Object: %s (ID: %s) from %.2f, %.2f, %.2f^0", 
                                object.model, object.id or "Unknown", object.posX, object.posY, object.posZ))
                        end
                    end)
                end
            end
        end

        for _, task in ipairs(tasks) do
            CreateThread(task)
        end

        Wait(1000)
    end
end)

local reportedInvalidModels = {}

CreateThread(function()
    while Config.Debug do
        for _, object in pairs(objectList) do
            if object.isRendered and object.object then
                DrawMarker(
                    2,
                    object.posX, object.posY, object.posZ,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.1, 0.1, 420.0,
                    255, 0, 0, 200,
                    false, true, 2, false, nil, nil, false
                )
            end

            local isValidModel = IsModelValid(object.model) or IsModelValid(GetHashKey(object.model))
            if not isValidModel and not reportedInvalidModels[object.model] then
                reportedInvalidModels[object.model] = true
                print(string.format("^1[DEBUG] Invalid Model: %s (ID: %s) at %.2f, %.2f, %.2f^0", 
                    object.model, object.id or "Unknown", object.posX, object.posY, object.posZ))
            end
        end
        Wait(0)
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        TriggerServerEvent('glitch-spawnobjects:requestSyncedObjects')

        if Config.enablePredefinedProps then
            CreateThread(function()
                Config.predefinedProps = lib.callback.await('glitch-spawnobjects:getPredefinedProps', false)
            end)
        end

        Wait(3000)
        TriggerEvent("chat:addSuggestion", "/"..Config.commands.spawnObject, "Spawn a synced object.")
		TriggerEvent("chat:addSuggestion", "/"..Config.commands.syncedObjects, "Open the synced objects menu.")
    end
end)

RegisterNetEvent('glitch-spawnobjects:receivePredefinedProps')
AddEventHandler('glitch-spawnobjects:receivePredefinedProps', function(props)
    Config.predefinedProps = props
end)

RegisterNetEvent('glitch-spawnobjects:receiveSyncedObjects')
AddEventHandler('glitch-spawnobjects:receiveSyncedObjects', function(props)
    objectList = props
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, object in pairs(objectList) do
            if object.isRendered then
                removeObject(object.object)
            end
        end
    end
end)

RegisterNetEvent("glitch-spawnobjects:addNewSyncedObject", function(newProp)
    local updated = false

    for index, prop in ipairs(objectList) do
        if prop.id == newProp.id and prop.model == newProp.model then
            removeObject(prop.object)
            prop.posX = newProp.posX
            prop.posY = newProp.posY
            prop.posZ = newProp.posZ
            prop.rotX = newProp.rotX
            prop.rotY = newProp.rotY
            prop.rotZ = newProp.rotZ
            prop.identifier = newProp.identifier
            prop.isRendered = false
            updated = true
            break
        end
    end

    if not updated then
        table.insert(objectList, newProp)
    end
end)

RegisterNetEvent("glitch-spawnobjects:receiveDeletedSyncedObject", function(id)
    for _, object in pairs(objectList) do
        if id == object.id then
            removeObject(object.object)
            table.remove(objectList, _)
        end
    end
end)

function openSyncObject(object)
    local options = {}
    local closestObject = GetClosestObjectOfType(object.posX, object.posY, object.posZ, 3.0, object.model, false)
    local objectEntity = object.object or locale('unknown_entity')
    local sceneType = object.sceneType or locale('null')

    if closestObject ~= 0 then
        SetEntityDrawOutline(closestObject, true)
    else
        lib.notify({title = "", description = locale('unable_locate_entity'), type = "error"})
    end

    table.insert(options, {title = locale('objectid'), description = object.id.." ("..objectEntity..")", icon = 'box', onSelect = function() copyInfomation(closestObject, object.id) end})
    table.insert(options, {title = locale('model'), description = object.model, icon = 'box', onSelect = function() copyInfomation(closestObject, object.model) end})
    table.insert(options, {title = locale('creator'), description = object.identifier, icon = 'box', onSelect = function() copyInfomation(closestObject, object.identifier) end})
    table.insert(options, {title = locale('scene_type'), description = sceneType, icon = 'box', onSelect = function() copyInfomation(closestObject, sceneType) end})
    table.insert(options, {title = locale('position'), description = object.posX..", "..object.posY..", "..object.posZ, icon = 'box', onSelect = function() copyInfomation(closestObject, object.posX..", "..object.posY..", "..object.posZ) end})
    table.insert(options, {title = locale('rotation_label'), description = object.rotX..", "..object.rotY..", "..object.rotZ, icon = 'box', onSelect = function() copyInfomation(closestObject, object.rotX..", "..object.rotY..", "..object.rotZ) end})
    table.insert(options, {title = locale('move_synced_object'), description = "", icon = 'up-down-left-right', onSelect = function() moveSyncedObject(object) end})
    table.insert(options, {title = locale('delete_synced_object'), description = "", icon = 'fa-solid fa-times', onSelect = function() deleteSyncedObject(object.id) end})


    lib.registerContext({
        id = 'syncedObject',
        title = string.format(locale('synced_object_title'), object.model),
        menu = "syncedObjects",
        options = options,
        onExit = function()
            SetEntityDrawOutline(closestObject, false)
        end,
        onBack = function()
            SetEntityDrawOutline(closestObject, false)
        end,
    })
    lib.showContext('syncedObject')
end

function copyInfomation(closestObject, info)
    lib.notify({title = "", description = locale('copied_clipboard'), type = "success"})
    lib.setClipboard(info)
    SetEntityDrawOutline(closestObject, false)
end

function deleteSyncedObject(objectId)
    TriggerServerEvent("glitch-spawnobjects:deleteSyncedObject", objectId)
end

function moveSyncedObject(object)
    if object.isRendered then
        removeObject(object.object)

        local obj = CreateObject(GetHashKey(object.model), object.posX, object.posY, object.posZ, false, false, false)
        SetEntityCoords(obj, object.posX, object.posY, object.posZ, false, false, false, false)
        SetEntityRotation(obj, object.rotX, object.rotY, object.rotZ, 2, true)
        local data = useGizmo(obj)

        if data then
            removeObject(obj)
            TriggerServerEvent("glitch-spawnobjects:updateSyncedObject", object.model, data, object.id)
        end
    else
        lib.notify({title = "", description = locale('object_not_visible'), type = "error"})
    end
end

function isObjectRendered(posX, posY, posZ)
    for index, object in pairs(objectList) do
        if object.posX == posX and object.posY == posY and object.posZ == posZ then
            return object.isRendered or false
        end
    end
    return locale('unknown')
end

RegisterCommand(Config.commands.spawnObject, function()
    if isAllowedAccess() then
        local inputFields = {}
        
        if Config.enablePredefinedProps then
            if not Config.predefinedProps or #Config.predefinedProps == 0 then
                lib.notify({title = "", description = locale('props_not_loaded'), type = "warning", duration = 3000})
                return
            end
            
            table.insert(inputFields, {
                type = 'input',
                label = locale('note_label'),
                description = locale('model_selection_note'),
                disabled = true,
                default = locale('model_selection_note_default')
            })
            
            table.insert(inputFields, {
                type = 'select',
                label = locale('predefined_model_label'),
                description = locale('predefined_model_description'),
                options = Config.predefinedProps,
                icon = 'box',
                searchable = true,
                clearable = true
            })
        end

        table.insert(inputFields, {
            type = 'input',
            label = Config.enablePredefinedProps and locale('custom_model_label') or locale('model_label'),
            description = Config.enablePredefinedProps and locale('custom_model_description') or locale('model_description'),
        })
        
        table.insert(inputFields, {
            type = 'input',
            label = locale('scene_type_label'),
            description = locale('scene_type_description')
        })
        
        table.insert(inputFields, {
            type = 'number',
            label = 'Duration (minutes)',
            description = 'How long the object should exist (leave empty for permanent)',
            min = 1,
            max = Config.maxDuration
        })
        
        local input = lib.inputDialog(locale('synced_object_dialog'), inputFields)

        if not input then return end

        local model, sceneType, duration
        
        if Config.enablePredefinedProps then
            local predefinedModel = input[2]
            local manualModel = input[3]
            sceneType = input[4]
            duration = input[5]
            
            if predefinedModel and predefinedModel ~= "" and manualModel and manualModel ~= "" then
                lib.notify({title = "", description = locale('both_model_fields_error'), type = "error"})
                return
            end
            
            if (not predefinedModel or predefinedModel == "") and (not manualModel or manualModel == "") then
                lib.notify({title = "", description = locale('no_model_selected_error'), type = "error"})
                return
            end
            
            model = (predefinedModel and predefinedModel ~= "") and predefinedModel or manualModel
        else
            model = input[1]
            sceneType = input[2]
            duration = input[3]
        end

        if not IsModelValid(model) then
            lib.notify({title = "", description = string.format(locale('invalid_model'), model), type = "error"})
            return
        end

        local offset = GetEntityCoords(cache.ped) + GetEntityForwardVector(cache.ped) * 3
        lib.requestModel(GetHashKey(model))
        local obj = CreateObject(GetHashKey(model), offset.x, offset.y, offset.z, false, false, false)
        SetEntityCoords(obj, offset.x, offset.y, offset.z, false, false, false, false)
        local data = useGizmo(obj)
        removeObject(obj)
        SetModelAsNoLongerNeeded(GetHashKey(model))

        if data then    
            TriggerServerEvent("glitch-spawnobjects:createNewSyncedObject", model, data, sceneType, duration)
        end
    else
        lib.notify({title = "", description = locale('invalid_permission'), type = "error", duration = 3000})
    end
end)

local currentPage = 1
RegisterCommand(Config.commands.syncedObjects, function()
    if isAllowedAccess() then
        local options = {}

        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)

        local function calculateDistance(x1, y1, z1, x2, y2, z2)
            return Vdist(x1, y1, z1, x2, y2, z2)
        end

        table.sort(objectList, function(a, b)
            local distanceA = calculateDistance(playerPos.x, playerPos.y, playerPos.z, a.posX, a.posY, a.posZ)
            local distanceB = calculateDistance(playerPos.x, playerPos.y, playerPos.z, b.posX, b.posY, b.posZ)
            return distanceA < distanceB
        end)

        local totalPages = math.ceil(#objectList / Config.itemsPerPage)

        local function getPageObjects(page)
            local startIdx = (page - 1) * Config.itemsPerPage + 1
            local endIdx = math.min(page * Config.itemsPerPage, #objectList)
            local pageObjects = {}

            for i = startIdx, endIdx do
                local object = objectList[i]
                local isObjectRendered = isObjectRendered(object.posX, object.posY, object.posZ)
                local sceneType = object.sceneType or locale('null')

                table.insert(pageObjects, {
                    title = object.model,
                    description = string.format(locale('creator_rendered'), object.identifier, tostring(isObjectRendered)),
                    icon = 'box',
                    metadata = {
                        {label = locale('objectid_metadata'), value = object.id},
                        {label = locale('model'), value = object.model},
                        {label = locale('creator'), value = object.identifier},
                        {label = locale('scene_type'), value = sceneType},
                        {label = locale('position'), value = object.posX..", "..object.posY..", "..object.posZ},
                        {label = locale('rotation_label'), value = object.rotX..", "..object.rotY..", "..object.rotZ},
                    },
                    onSelect = function() openSyncObject(object) end
                })
            end

            if page > 1 then
                table.insert(pageObjects, {
                    title = locale('previous_page'),
                    icon = "arrow-left",
                    onSelect = function()
                        currentPage = currentPage - 1
                        showPage(currentPage)
                    end
                })
            end

            if page < totalPages then
                table.insert(pageObjects, {
                    title = locale('next_page'),
                    icon = "arrow-right",
                    onSelect = function()
                        currentPage = currentPage + 1
                        showPage(currentPage) 
                    end
                })
            end

            return pageObjects
        end

        function showPage(page) 
            local pageObjects = getPageObjects(page)
            lib.registerContext({
                id = 'syncedObjects',
                title = string.format(locale('synced_objects_title'), page, totalPages),
                options = pageObjects
            })
            lib.showContext('syncedObjects')
        end

        showPage(currentPage)
    else
        lib.notify({title = "", description = locale('invalid_permission'), type = "error", duration = 3000})
    end
end)

function removeObject(entity)
    NetworkRequestControlOfEntity(entity)
    local timeout = 2000
    while timeout > 0 and not NetworkHasControlOfEntity(entity) do
        Wait(100)
        timeout = timeout - 100
    end
    SetEntityAsMissionEntity(entity, true, true)
    local timeout = 2000
    while timeout > 0 and not IsEntityAMissionEntity(entity) do
        Wait(100)
        timeout = timeout - 100
    end
    Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(entity))
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
        if DoesEntityExist(entity) then
            return false
        else
            return true
        end
    else
        return true
    end
end

exports('getClosestObject', function(coords, maxDistance)
    if not coords then
        coords = GetEntityCoords(cache.ped)
    end
    
    if not maxDistance then
        maxDistance = math.huge
    end
    
    local closestObject = nil
    local closestDistance = maxDistance
    
    for _, object in pairs(objectList) do
        local objectCoords = vector3(object.posX, object.posY, object.posZ)
        local distance = #(coords - objectCoords)
        
        if distance < closestDistance then
            closestDistance = distance
            closestObject = object
        end
    end
    
    return closestObject, closestDistance
end)