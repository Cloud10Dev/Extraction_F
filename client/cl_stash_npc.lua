local npcPed = nil

CreateThread(function()
    local model = joaat(Config.StashNpc.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end

    npcPed = CreatePed(4, model, Config.StashNpc.coords.x, Config.StashNpc.coords.y, Config.StashNpc.coords.z - 1.0, Config.StashNpc.coords.w, false, true)
    SetEntityInvincible(npcPed, true)
    FreezeEntityPosition(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    SetEntityAsMissionEntity(npcPed, true, true)
    TaskStartScenarioInPlace(npcPed, 'WORLD_HUMAN_GUARD_STAND', 0, true)
    SetModelAsNoLongerNeeded(model)
end)

CreateThread(function()
    while true do
        Wait(0)
        if npcPed and not inMatch then
            local ped = PlayerPedId()
            local dist = #(GetEntityCoords(ped) - GetEntityCoords(npcPed))
            if dist <= Config.StashNpc.interactDistance then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to open Extraction Stash')
                EndTextCommandDisplayHelp(0, false, false, -1)
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent('extraction:requestOpenStash')
                    Wait(500)
                end
            else
                Wait(300)
            end
        else
            Wait(500)
        end
    end
end)
