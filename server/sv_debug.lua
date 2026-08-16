RegisterCommand('debug_match_info', function(src)
    if src ~= 0 then return end
    print('=== ACTIVE MATCHES ===')
    for matchId, inst in pairs(Instances) do
        local total, alive, extracted = 0, 0, 0
        for _, ps in pairs(inst.players) do
            total = total + 1
            if ps.alive then alive = alive + 1 end
            if ps.extracted then extracted = extracted + 1 end
        end
        print(('%s bucket=%s state=%s total=%s alive=%s extracted=%s'):format(matchId, inst.bucketId, inst.state, total, alive, extracted))
    end
end, true)

RegisterCommand('force_extract', function(src, args)
    if src ~= 0 then return end
    local target = tonumber(args[1])
    if not target then return end
    local matchId = GetPlayerMatch(target)
    if not matchId then return end
    TriggerEvent(Config.Events.ExtractionCancel, target)
end, true)

RegisterCommand('reset_player_match', function(src, args)
    if src ~= 0 then return end
    local target = tonumber(args[1])
    if not target then return end
    SetPlayerRoutingBucket(target, 0)
    TriggerClientEvent(Config.Events.RespawnLobby, target)
end, true)
