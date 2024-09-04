sh = {}

sh.debug = function(str)
    if cfg?.debug or not cfg then
        if IsDuplicityVersion() then
            print('[^1sh-scripts^0] - [^1Debug^0]: ' .. str)
        else
            print('[sh-scripts] - [Debug]: ' .. str)
        end
    end
end

if cfg?.locale and cfg?.locales then
    local locales = cfg.locales[cfg.locale]
    setmetatable(locales, { __index = function(self, key)
        return "Error: Missing translation for \"" .. key .. "\""
    end })

    sh._t = function(key)
        return locales[key]
    end
end

dt = function(table, nb)
    if nb == nil then
        nb = 0
    end

    if type(table) == 'table' then
        local s = ''
        for i = 1, nb + 1, 1 do
            s = s .. "    "
        end

        s = '{\n'
        for k, v in pairs(table) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            for i = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. '[' .. k .. '] = ' .. dt(v, nb + 1) .. ',\n'
        end

        for i = 1, nb, 1 do
            s = s .. "    "
        end

        return s .. '}'
    else
        return tostring(table)
    end
end

sh.dt = function(table, w)
    if w then return dt(table) else print(dt(table)) end
end

local fwObj
if cfg?.framework then
    framework = cfg.framework:lower()
else
    local esx = GetResourceState('es_extended'):find('start')
    local qbcore = GetResourceState('qb-core'):find('start')
    if esx then framework = 'esx'
    elseif qbcore then framework = 'qb'
    end
end

CreateThread(function()
    local c = 0
    while not fwObj and c < 1000 do
        c = c + 1
        if framework == 'esx' then
            pcall(function() fwObj = exports['es_extended']:getSharedObject() end)
            if not fwObj then
                TriggerEvent('esx:getSharedObject', function(obj) fwObj = obj end)
            end
            if fwObj then
                ESX = fwObj
                break
            end
        elseif framework == 'qb' or framework == 'qbcore' then
            pcall(function() fwObj = exports['qb-core']:GetCoreObject() end)
            if not fwObj then
                pcall(function() fwObj = exports['qb-core']:GetSharedObject() end)
            end
            if not fwObj then
                TriggerEvent('QBCore:GetObject', function(obj) fwObj = obj end)
            end
            if fwObj then
                QBCore = fwObj
                break
            end
        end
        Wait(0)
    end
end)

if not IsDuplicityVersion() then --client
    sh.notification = function(type, str, length)
        if ESX then
            ESX.ShowNotification(str, type, length)
        elseif QBCore then
            QBCore.Functions.Notify(str, type, length)
        else
            SetNotificationTextEntry('STRING')
            AddTextComponentSubstringPlayerName(str)
            DrawNotification(0, 1)
        end
    end

    RegisterNetEvent(GetCurrentResourceName()..':client:notification', sh.notification)

    sh.serverCallbacks = {}

    sh.triggerCallback = function(name, cb, ...)
        sh.serverCallbacks[name] = cb
        TriggerServerEvent(GetCurrentResourceName()..':server:triggerCallback', name, ...)
    end

    RegisterNetEvent(GetCurrentResourceName()..':client:triggerCallback', function(name, ...)
        if sh.serverCallbacks[name] then
            sh.serverCallbacks[name](...)
            sh.serverCallbacks[name] = nil
        end
    end)

    sh.registerKeyMap = function(data, cb, cb2)
        RegisterCommand('+sh_' .. data.command, function()
            local response = true
            if not (data.useWhileFrontendMenu and data.useWhileFrontendMenu or false) and IsPauseMenuActive() then response = false end
            if not (data.useWhileNuiFocus and data.useWhileNuiFocus or false) and IsNuiFocused() then response = false end
            if cb and type(cb) == 'function' then cb(response) end
        end)
        RegisterCommand('-sh_' .. data.command, function()
            if cb2 and type(cb2) == 'function' then cb2() end
        end)
        if data.key:match('mouse') or data.key:match('iom') then
            RegisterKeyMapping('+sh_' .. data.command, data.description, 'mouse_button', data.key:lower())
        else
            RegisterKeyMapping('+sh_' .. data.command, data.description, 'keyboard', data.key:lower())
        end
        
        Wait(500)
        TriggerEvent('chat:removeSuggestion', ('/+sh_%s'):format(data.command))
        TriggerEvent('chat:removeSuggestion', ('/-sh_%s'):format(data.command))
    end

    sh.drawText3D = function(x, y, z, str, length, r, g, b, a)
        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
        if onScreen then
            local factor = #str / 370
            if length then
                factor = #str / length
            end
            SetTextScale(0.30, 0.30)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextColour(r or 255, g or 255, b or 255, a or 215)
            BeginTextCommandDisplayText('STRING')
            SetTextCentre(1)
            AddTextComponentSubstringPlayerName(str)
            EndTextCommandDisplayText(_x, _y)
            DrawRect(_x, _y + 0.0120, 0.006 + factor, 0.024, 0, 0, 0, 155)
        end
    end

    sh.addBlip = function(coords, sprite, scale, color, str, cb)
        local blip = AddBlipForCoord(coords)
        SetBlipSprite(blip, sprite)
        SetBlipColour(blip, color)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, scale)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(str)
        EndTextCommandSetBlipName(blip)
        if cb then cb(blip) else return blip end
    end

    sh.drawSubtitle = function(str, time)
        BeginTextCommandPrint('STRING')
        AddTextComponentSubstringPlayerName(str)
        EndTextCommandPrint(time or 4000, 1)
    end

    sh.drawBusySpinner = function(str)
        BeginTextCommandBusyspinnerOn('STRING')
        AddTextComponentSubstringPlayerName(str)
        EndTextCommandBusyspinnerOn(3)
    end

    sh.loadAnimDict = function(dict, cb)
        if not HasAnimDictLoaded(dict) then
            RequestAnimDict(dict)

            while not HasAnimDictLoaded(dict) do
                Wait(1)
            end
        end

        if cb then cb() end
        Wait(10)
        RemoveAnimDict(dict)
    end

    sh.loadPtfxAsset = function(asset, cb)
        if not HasNamedPtfxAssetLoaded(asset) then
            RequestNamedPtfxAsset(asset)

            while not HasNamedPtfxAssetLoaded(asset) do
                Wait(1)
            end
        end

        if cb then cb() end
        Wait(10)
        RemovePtfxAsset(asset)
    end

    sh.loadAnimSet = function(set, cb)
        if not HasAnimSetLoaded(set) then
            RequestAnimSet(set)

            while not HasAnimSetLoaded(asset) do
                Wait(1)
            end
        end

        if cb then cb() end
        Wait(10)
        RemoveAnimSet(asset)
    end

    sh.requestModel = function(model, cb)
        model = type(model) == 'number' and model or joaat(model)
        if model and IsModelValid(model) then
            if not HasModelLoaded(model) then
                RequestModel(model)

                while not HasModelLoaded(model) do
                    Wait(0)
                end

                if cb then cb(true) end
                Wait(100)
                SetModelAsNoLongerNeeded(model)
            else
                if cb then cb(true) end
                Wait(100)
                SetModelAsNoLongerNeeded(model)
            end
        else
            print('Model(' .. model .. ') is not valid!')
            if cb then cb(false) end
        end
    end

    sh.spawnObject = function(model, coords, isLocal, cb)
        model = type(model) == 'number' and model or joaat(model)

        sh.requestModel(model, function()
            local obj = CreateObject(model, coords.xyz, not isLocal, true, false)
            SetEntityAsMissionEntity(obj, true, false)
            SetModelAsNoLongerNeeded(model)

            if DoesEntityExist(obj) then
                if cb then cb(obj) else return obj end
            end
        end)
    end

    sh.spawnPed = function(model, coords, heading, isLocal, cb)
        model = type(model) == 'number' and model or joaat(model)

        sh.requestModel(model, function()
            local ped = CreatePed(0, model, coords.xyz, heading, not isLocal, false)
            SetEntityAsMissionEntity(ped, true, false)

            if DoesEntityExist(ped) then
                if cb then cb(ped) else return ped end
            end
        end)
    end

    sh.spawnVehicle = function(model, coords, heading, isLocal, cb)
        model = type(model) == 'number' and model or joaat(model)

        sh.requestModel(model, function()
            local vehicle = CreateVehicle(model, coords.xyz, heading, not isLocal, true)
            local timeout = 0
            if not isLocal then
                local networkId = NetworkGetNetworkIdFromEntity(vehicle)
                SetNetworkIdCanMigrate(networkId, true)
                SetEntityAsMissionEntity(vehicle, true, false)
            end

            SetVehicleHasBeenOwnedByPlayer(vehicle, true)
            SetVehicleNeedsToBeHotwired(vehicle, false)
            SetVehicleDirtLevel(vehicle, 0.0)
            SetVehicleModKit(vehicle, 0)
            SetVehRadioStation(vehicle, 'OFF')
            SetModelAsNoLongerNeeded(model)
            RequestCollisionAtCoord(coords.xyz)

            repeat
                Wait(0)
                timeout = timeout + 1
            until (HasCollisionLoadedAroundEntity(vehicle) or timeout > 2000)

            if DoesEntityExist(vehicle) then
                if cb then cb(vehicle) else return vehicle end
            end
        end)
    end

    sh.deleteObject = function(object, cb)
        SetEntityAsMissionEntity(object, false, true)
        DeleteObject(object)
        if cb then cb() else return end
    end

    sh.deleteVehicle = function(vehicle, cb)
        SetEntityAsMissionEntity(vehicle, false, true)
        DeleteVehicle(vehicle)
        if cb then cb() else return end
    end

    sh.deletePed = function(ped, cb)
        SetEntityAsMissionEntity(ped, false, true)
        DeletePed(ped)
        if cb then cb() else return end
    end

    sh.getVehicles = function()
        return GetGamePool('CVehicle')
    end

    sh.getObjects = function()
        return GetGamePool('CObject')
    end

    sh.getPlayers = function()
        return GetActivePlayers()
    end

    sh.getClosestPed = function(coords)
        local ped = PlayerPedId()
        coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
        local peds = GetGamePool('CPed')
        local closestDistance, closestPed = false
        for i = 1, #peds, 1 do
            local pedCoords = GetEntityCoords(peds[i])
            local distance = #(pedCoords - coords)
            if not closestDistance or closestDistance > distance then
                closestPed = peds[i]
                closestDistance = distance
            end
        end
        return closestPed, closestDistance
    end

    sh.getClosestPeds = function(coords, maxDistance)
        local ped = PlayerPedId()
        local peds = GetGamePool('CPed')
        coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
        local maxDistance = maxDistance or 5
        local closestPeds = {}
        for i = 1, #vehicles, 1 do
            local pedCoords = GetEntityCoords(peds[i])
            if maxDistance >= #(pedCoords - coords) then
                closestPeds[#closestPeds + 1] = peds[i]
            end
        end
        return closestPeds
    end

    sh.getClosestPlayer = function(coords)
        local ped = PlayerPedId()
        coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
        local closestPlayers = sh.getPlayersFromCoords(coords)
        local closestDistance, closestPlayer = false
        for i = 1, #closestPlayers, 1 do
            if closestPlayers[i] ~= PlayerId() and closestPlayers[i] then
                local target = GetPlayerPed(closestPlayers[i])
                local targetCoords = GetEntityCoords(target)
                local distance = #(targetCoords - coords)
                if not closestDistance or closestDistance > distance then
                    closestPlayer = closestPlayers[i]
                    closestDistance = distance
                end
            end
        end
        return closestPlayer, closestDistance
    end

    sh.getPlayersFromCoords = function(coords, maxDistance)
        local players = sh.getPlayers()
        local ped = PlayerPedId()
        coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
        local maxDistance = maxDistance or 5
        local closePlayers = {}
        for _, player in pairs(players) do
            local target = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(target)
            if maxDistance >= #(targetCoords - coords) then
                closePlayers[#closePlayers + 1] = player
            end
        end
        return closePlayers
    end

    sh.getClosestVehicle = function(coords)
        local ped = PlayerPedId()
        local vehicles = GetGamePool('CVehicle')
        local closestDistance, closestVehicle = false
        coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
        for i = 1, #vehicles, 1 do
            local vehicleCoords = GetEntityCoords(vehicles[i])
            local distance = #(vehicleCoords - coords)
            if not closestDistance or closestDistance > distance then
                closestVehicle = vehicles[i]
                closestDistance = distance
            end
        end
        return closestVehicle, closestDistance
    end

    sh.getClosestVehicles = function(coords, maxDistance)
        local ped = PlayerPedId()
        local vehicles = GetGamePool('CVehicle')
        coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
        local maxDistance = maxDistance or 5
        local closestVehicles = {}
        for i = 1, #vehicles, 1 do
            local vehicleCoords = GetEntityCoords(vehicles[i])
            if maxDistance >= #(vehicleCoords - coords) then
                closestVehicles[#closestVehicles + 1] = vehicles[i]
            end
        end
        return closestVehicles
    end

    sh.getClosestObject = function(coords)
        local ped = PlayerPedId()
        local objects = GetGamePool('CObject')
        local closestDistance, closestObject = false
        coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
        for i = 1, #objects, 1 do
            local objectCoords = GetEntityCoords(objects[i])
            local distance = #(objectCoords - coords)
            if not closestDistance or closestDistance > distance then
                closestObject = objects[i]
                closestDistance = distance
            end
        end
        return closestObject, closestDistance
    end

    sh.getClosestObjects = function(coords, maxDistance)
        local ped = PlayerPedId()
        local objects = GetGamePool('CObject')
        coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
        local maxDistance = maxDistance or 5
        local closestObjects = {}
        for i = 1, #objects, 1 do
            local objectCoords = GetEntityCoords(objects[i])
            if maxDistance >= #(objectCoords - coords) then
                closestObjects[#closestObjects + 1] = objects[i]
            end
        end
        return closestObjects
    end

    local duis = {}
    sh.createDui = function(url, width, height, cb)
        width = width or 512
        height = height or 512
        local duiCounter = #duis + 1

        local duiSize = tostring(width) .. 'x' .. tostring(height)
        local generatedDictName = duiSize .. '-dict-' .. tostring(duiCounter)
        local generatedTxtName = duiSize .. '-tx-' .. tostring(duiCounter)
        local duiObject = CreateDui(url, width, height)
        local dictObject = CreateRuntimeTxd(generatedDictName)
        local duiHandle = GetDuiHandle(duiObject)
        local txdObject = CreateRuntimeTextureFromDuiHandle(dictObject, generatedTxtName, duiHandle)

        duis[duiCounter] = {
            -- duiSize = duiSize,
            duiObject = duiObject,
            -- duiHandle = duiHandle,
            -- dictionaryObject = dictObject,
            -- textureObject = txdObject,
            -- textureDictName = generatedDictName,
            -- textureName = generatedTxtName
        }

        local duiData = { id = duiCounter, dictionary = generatedDictName, texture = generatedTxtName }
        if cb then cb(duiData) else return duiData end
    end

    sh.changeDuiUrl = function(id, url)
        if not duis[id] then print('dui not found. id: '..id) return end

        SetDuiUrl(duis[id].duiObject, url)
    end

    local mathpi, mathsin, mathabs, mathcos = math.pi, math.sin, math.abs, math.cos
    local GetForwardVector = function(rotation)
        local rot = (mathpi / 180.0) * rotation
        return vector3(-mathsin(rot.z) * mathabs(mathcos(rot.x)), mathcos(rot.z) * mathabs(mathcos(rot.x)), mathsin(rot.x))
    end

    sh.raycast = function(origin, target, options, ignoreEntity, radius)
        local handle = StartShapeTestSweptSphere(origin.x, origin.y, origin.z, target.x, target.y, target.z, radius, options, ignoreEntity or PlayerPedId(), 0)
        return GetShapeTestResult(handle)
    end

    sh.getEntityPlayerIsLookingAt = function(maxDistance, radius, flag, ignore)
        local maxDistance = maxDistance or 3.0
        local originCoords = GetPedBoneCoords(PlayerPedId(), 31086)
        local forwardVectors = GetForwardVector(GetGameplayCamRot(2))
        local forwardCoords = originCoords + (forwardVectors * maxDistance)

        if not forwardVectors then return end
        local _, hit, targetCoords, _, targetEntity = sh.raycast(originCoords, forwardCoords, flag or 4294967295, ignore, radius or 0.2)
        if not hit and targetEntity == 0 then return end
        local entityType = GetEntityType(targetEntity)
        return targetEntity, entityType, targetCoords
    end

    sh.getEntityInFrontOfEntity = function(entity, maxDistance, radius, flag)
        local maxDistance = maxDistance or 3.0
        local entity = (entity and DoesEntityExist(entity)) and entity or PlayerPedId()
        local forwardVector = GetEntityForwardVector(entity)
        local originCoords = GetEntityCoords(entity)
        local targetCoords = originCoords + (forwardVector * maxDistance)
        local _, hit, _, _, targetEntity = sh.raycast(originCoords, targetCoords, flag or 4294967295, entity, radius or 0.2)
        return targetEntity
    end
else --server
    sh.serverCallbacks = {}

    sh.registerCallback = function(name, cb)
        sh.serverCallbacks[name] = cb
    end

    sh.triggerCallback = function(name, src, cb, ...)
        if sh.serverCallbacks[name] then
            sh.serverCallbacks[name](src, cb, ...)
        else
            sh.debug('This callback(^2' .. name .. '^0) is not registered!')
        end
    end

    RegisterNetEvent(GetCurrentResourceName()..':server:triggerCallback', function(name, ...)
        local src = source

        sh.triggerCallback(name, src, function(...)
            TriggerClientEvent(GetCurrentResourceName()..':client:triggerCallback', src, name, ...)
        end, ...)
    end)

    local manifestFile = LoadResourceFile(GetCurrentResourceName(), 'fxmanifest.lua')
    local loadSqlFuncs = manifestFile:find('/lib/MySQL.lua') and true or false
    if loadSqlFuncs then
        sh.sql = {}
        sh.sql.async = {}
        sh.sql.sync = {}
        if GetResourceState('oxmysql') == 'started' then
            CreateThread(function()
                while not MySQL do
                    Wait(1)
                end

                sh.sql.sync.query = MySQL.query.await
                sh.sql.sync.insert = MySQL.insert.await
                sh.sql.sync.update = MySQL.update.await
                -- sh.sql.sync.single = MySQL.single.await
                sh.sql.sync.scalar = MySQL.scalar.await

                sh.sql.async.query = MySQL.query
                sh.sql.async.insert = MySQL.insert
                sh.sql.async.update = MySQL.update
                -- sh.sql.async.single = MySQL.single
                sh.sql.async.scalar = MySQL.scalar
            end)
        elseif GetResourceState('mysql-async') == 'started' then
            CreateThread(function()
                while not MySQL do
                    Wait(1)
                end
                MySQL.ready(function()
                    sh.sql.sync.query = MySQL.Sync.fetchAll
                    sh.sql.sync.insert = MySQL.Sync.insert
                    sh.sql.sync.update = MySQL.Sync.execute
                    -- sh.sql.sync.single = MySQL.Sync.single
                    sh.sql.sync.scalar = MySQL.Sync.fetchScalar

                    sh.sql.async.query = MySQL.Async.fetchAll
                    sh.sql.async.insert = MySQL.Async.insert
                    sh.sql.async.update = MySQL.Async.execute
                    -- sh.sql.async.single = MySQL.Async.single
                    sh.sql.async.scalar = MySQL.Async.fetchScalar
                end)
            end)
        end
    end

    sh.notification = function(src, type, str, length)
        TriggerClientEvent(GetCurrentResourceName()..':client:notification', src, type, str, length)
    end

    sh.getIdentifiers = function(src, identifiertypes)
        local identifiers = GetPlayerIdentifiers(src)
        local response = {}
        if identifiertypes then
            if type(identifiertypes) == 'table' then
                for _, type in pairs(identifiertypes) do
                    for _, identifier in pairs(identifiers) do
                        if string.find(identifier, type) then
                            response[type] = identifier
                        end
                    end
                end
            else
                for _, identifier in pairs(identifiers) do
                    if string.find(identifier, identifiertypes) then
                        return identifier
                    end
                end
            end
        else
            for _, identifier in pairs(identifiers) do
                if string.find(identifier, 'steam') then
                    return identifier
                end
            end
        end
        return response
    end

    local sanitize = function(str)
        if str then
            local replacements = {
                ['&'] = '&amp;',
                ['<'] = '&lt;',
                ['>'] = '&gt;',
                ['\n'] = '<br/>'
            }

            return str:gsub('[&<>\n]', replacements):gsub(' +', function(s) return ' ' .. ('&nbsp;'):rep(#s - 1) end)
        else
            return nil
        end
    end

    local logColors = {
        ['default'] = 16711680,
        ['blue'] = 25087,
        ['green'] = 762640,
        ['white'] = 16777215,
        ['black'] = 0,
        ['orange'] = 16743168,
        ['lightgreen'] = 65309,
        ['yellow'] = 15335168,
        ['pink'] = 16711900,
        ['red'] = 16711680,
        ['cyan'] = 65535,
    }
    sh.sendLog = function(webhookURL, color, str, imgUrl)
        if webhookURL and webhookURL ~= '' then
            local headers = {
                ['Content-Type'] = 'application/json'
            }
            local data = {
                ["username"] = 'sh-logs',
                ["avatar_url"] = 'https://raw.githubusercontent.com/SH-Scripts/logo/main/logo.png',
                ["embeds"] = { {
                    ["title"] = 'sh-store.tebex.io',
                    ["url"] = 'https://sh-store.tebex.io/',
                    ["color"] = logColors[color] and logColors[color] or logColors['default'],
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
                } },
                ["footer"] = {
                    ["text"] = 'sh-store.tebex.io',
                    ["icon_url"] = 'https://raw.githubusercontent.com/SH-Scripts/logo/main/logo.png'
                }
            }
            data['embeds'][1]['description'] = str
            if imgUrl then
                data['embeds'][1]['image'] = {
                    ['url'] = imgUrl
                }
            end
            PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode(data), headers)
        else
            sh.debug('Webhook URL is empty!')
        end
    end

    sh.sendSelfLog = function(src, webhookURL, color, str, imgUrl)
        if webhookURL and webhookURL ~= '' then
            if src then
                local name = sanitize(GetPlayerName(src))
                local identifiers = sh.getIdentifiers(src, { 'license', 'discord' })
                local text = ''
                if identifiers['license'] then
                    text = text .. '\n**License**: ' .. identifiers['license']
                end
                if identifiers['discord'] then
                    text = text .. '\n**Discord**: <@' .. identifiers['discord']:sub(9) .. '>'
                end
                local headers = {
                    ['Content-Type'] = 'application/json'
                }
                local data = {
                    ["username"] = 'sh-logs',
                    ["avatar_url"] = 'https://raw.githubusercontent.com/SH-Scripts/logo/main/logo.png',
                    ["embeds"] = { {
                        ["title"] = 'sh-store.tebex.io',
                        ["url"] = 'https://sh-store.tebex.io/',
                        ["author"] = {
                            ["name"] = '#' .. src .. ' - ' .. name,
                            ["url"] = 'https://sh-store.tebex.io/',
                        },
                        ["color"] = logColors[color] ~= nil and logColors[color] or logColors['default'],
                        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                        ["footer"] = {
                            ["text"] = 'sh-store.tebex.io',
                            ["icon_url"] = 'https://raw.githubusercontent.com/SH-Scripts/logo/main/logo.png'
                        }
                    } }
                }
                data['embeds'][1]['description'] = text .. '\n' .. str
                if imgUrl then
                    data['embeds'][1]['image'] = {
                        ['url'] = imgUrl
                    }
                end
                PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode(data), headers)
            end
        else
            sh.debug('Webhook URL is empty!')
        end
    end
end
