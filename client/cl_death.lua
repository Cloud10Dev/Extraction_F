-- cl_death.lua · Death detection, instant bucket return
CreateThread(function()
    local isDead = false
    while true do
        Wait(500)
        local dead = IsEntityDead(PlayerPedId())
        if dead and not isDead then
            isDead = true
            if inMatch then
                -- Immediately notify server — server will restore bucket and fire RespawnLobby
                TriggerServerEvent(Config.Events.PlayerDied)
                -- Show death screen right away
                SendNUIMessage({ action = 'playerDied', payload = {} })
            end
        elseif not dead and isDead then
            isDead = false
        end
    end
end)
