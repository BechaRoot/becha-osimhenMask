current = {
    object,
}
local mathrandom = math.random
RegisterNetEvent('sh-osimhenMask:client:wearMask', function()
    local pPed = PlayerPedId()
    if current.object then
        if DoesEntityExist(current.object) then
            DeleteObject(current.object)
        end
        current.object = nil
    else
        sh.loadAnimDict('clothingtie', function()
            TaskPlayAnim(pPed, 'clothingtie', 'try_tie_positive_a', 3.0, 3.0, 2600, 51, 0, false, false, false)
            Wait(2100)
            sh.spawnObject(model, vec3(1.0, 1.0, 1.0), false, function(obj)
                current.object = obj
                AttachEntityToEntity(current.object, pPed, GetPedBoneIndex(pPed, 31086), 0.047826387707005, 0.12432344019342, 0.025955882617974, -13.0, -86.0, -165.0, 1, 1, 0, 1, 0, 1)
                local netId = NetworkGetNetworkIdFromEntity(current.object)
                SetNetworkIdCanMigrate(netId, false)
            end)
        end)
    end
end)

RegisterNetEvent('sh-osimhenMask:client:unequipMask', function()
    if current.object then
        if DoesEntityExist(current.object) then
            DeleteObject(current.object)
        end
        current.object = nil
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if current.object and DoesEntityExist(current.object) then
            sh.deleteObject(current.object)
        end
    end
end)
