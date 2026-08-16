-- sv_instance.lua · Bucket management, match lifecycle
Instances = Instances or {}
PlayerInstance = PlayerInstance or {}
PlayerOriginalBucket = PlayerOriginalBucket or {}
NextBucketId = NextBucketId or 1000

local function AllocateBucket()
    NextBucketId = NextBucketId + 1
    return NextBucketId
end

local function BuildExtractionPoints(mapCfg)
    local pts = {}
    for i, ep in ipairs(mapCfg.extractionPts) do
        pts[i] = { coords = ep.coords, label = ep.label, active = true }
    end
    return pts
end

function GetPlayerMatch(src)
    return PlayerInstance[src]
end

function GetInstance(matchId)
    return matchId and Instances[matchId] or nil
end

local function CheckMatchEnd(matchId)
    local inst = Instances[matchId]
    if not inst or inst.state ~= 'active' then return end
    local remaining = 0
    for _, ps in pairs(inst.players) do
        if ps.alive and not ps.extracted then remaining = remaining + 1 end
    end
    if remaining <= 0 then TriggerEvent('extraction:internal:endMatch', matchId) end
end

function SetPlayerExtracted(src)
    local matchId = PlayerInstance[src]
    if not matchId then return end
    local inst = Instances[matchId]
    if not inst or not inst.players[src] then return end
    inst.players[src].extracted = true
    inst.players[src].alive     = false
    PlayerInstance[src] = nil
    local origBucket = PlayerOriginalBucket[src] or 0
    SetPlayerRoutingBucket(src, origBucket)
    PlayerOriginalBucket[src] = nil
    CheckMatchEnd(matchId)
end

local function BuildPartyMembers(players)
    local members = {}
    for _, src in ipairs(players) do
        members[#members+1] = { src = src, name = GetPlayerName(src) or ('Player#'..src) }
    end
    return members
end

AddEventHandler('extraction:internal:createMatch', function(players, mapId)
    local mapCfg  = Config.GetMap(mapId)
    local matchId = 'match_'..Utils.GenId(10)
    local bucketId = AllocateBucket()
    local partyMembers = BuildPartyMembers(players)

    local inst = {
        id            = matchId,
        bucketId      = bucketId,
        mapId         = mapId or 'city_outskirts',
        players       = {},
        state         = 'active',
        extractionPts = BuildExtractionPoints(mapCfg),
    }

    for _, src in ipairs(players) do
        PlayerOriginalBucket[src] = GetPlayerRoutingBucket(src)
        inst.players[src] = { alive = true, extracted = false }
        PlayerInstance[src] = matchId
        SetPlayerRoutingBucket(src, bucketId)
    end

    SetRoutingBucketPopulationEnabled(bucketId, false)
    Instances[matchId] = inst

    -- Send matchFound to all players
    for _, src in ipairs(players) do
        TriggerClientEvent(Config.Events.MatchFound, src, {
            matchId      = matchId,
            countdown    = Config.Match.MatchStartDelay,
            totalPlayers = #players,
            mapName      = mapCfg.name,
        })
    end

    SetTimeout(Config.Match.MatchStartDelay * 1000, function()
        for i, src in ipairs(players) do
            local spawns = mapCfg.spawns
            local spawn  = spawns[((i-1) % #spawns)+1]
            TriggerClientEvent(Config.Events.MatchTeleport, src, {
                matchId      = matchId,
                coords       = { x=spawn.x, y=spawn.y, z=spawn.z, w=spawn.w },
                extractPts   = inst.extractionPts,
                ffEnabled    = Config.Gameplay.FriendlyFire,
                bucketId     = bucketId,
                mapId        = inst.mapId,
                zone         = mapCfg.zone,
                partyMembers = partyMembers,
            })
        end
    end)
end)

AddEventHandler('extraction:internal:endMatch', function(matchId)
    local inst = Instances[matchId]
    if not inst or inst.state == 'ending' then return end
    inst.state = 'ending'
    for src, ps in pairs(inst.players) do
        local origBucket = PlayerOriginalBucket[src] or 0
        SetPlayerRoutingBucket(src, origBucket)
        PlayerOriginalBucket[src] = nil
        if ps.alive then
            TriggerClientEvent(Config.Events.RespawnLobby, src)
        end
    end
    SetRoutingBucketPopulationEnabled(inst.bucketId, false)
    SetTimeout(1000, function()
        for src, _ in pairs(inst.players) do
            PlayerInstance[src] = nil
        end
        Instances[matchId] = nil
    end)
end)

RegisterNetEvent(Config.Events.PlayerDied, function()
    local src     = source
    local matchId = PlayerInstance[src]
    if not matchId then return end
    local inst = Instances[matchId]
    if not inst or not inst.players[src] then return end
    inst.players[src].alive = false
    -- Restore bucket immediately on death
    local origBucket = PlayerOriginalBucket[src] or 0
    SetPlayerRoutingBucket(src, origBucket)
    PlayerOriginalBucket[src] = nil
    PlayerInstance[src] = nil
    -- Small delay so bucket transfer completes before teleport
    SetTimeout(800, function()
        TriggerClientEvent(Config.Events.RespawnLobby, src)
        CheckMatchEnd(matchId)
    end)
end)
