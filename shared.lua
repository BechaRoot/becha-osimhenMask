if IsDuplicityVersion() then --server
    RegisterCommand(cfg.unequipCommand, function(src)
        TriggerClientEvent('sh-osimhenMask:client:unequipMask', src)
    end)

    if framework == 'esx' then
        CreateThread(function()
            while not ESX do
                Wait(0)
            end

            ESX.RegisterUsableItem(cfg.itemName, function(src)
                TriggerClientEvent('sh-osimhenMask:client:wearMask', src)
            end)
        end)
    elseif framework == 'qb' then
        CreateThread(function()
            while not QBCore do
                Wait(0)
            end

            QBCore.Functions.CreateUseableItem(cfg.itemName, function(src)
                TriggerClientEvent('sh-osimhenMask:client:wearMask', src)
            end)
        end)
    end
end
