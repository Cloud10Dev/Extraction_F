-- sv_matchmaking.lua  ·  Queue & map-aware matchmaking
QueuedParties = QueuedParties or {}

local function BuildMemberList(party)
    local list = {}
    for src, _ in pairs(party.members) do
        list[#list+1] = {
            src    = src,
            name   = GetPlayerName(src) or ('Player#' .. src),
            leader = src == party.leader,
        }
    end
    return list
end

local function BroadcastQueueState(party)
    local payload = {
        partyId = party.id,
        leader  = party.leader,
        members = BuildMemberList(party),
        mode    = party.mode,
        inQueue = party.inQueue,
        inMatch = party.inMatch,
    }
    for src, _ in pairs(party.members) do
        TriggerClientEvent(Config.Events.PartyUpdate, src, payload)
    end
end

local function EnqueueParty(party)
    QueuedParties[party.id] = { partyId = party.id, joinedAt = os.time() }
    party.inQueue = true
    BroadcastQueueState(party)
end

local function DequeueParty(party)
    QueuedParties[party.id] = nil
    party.inQueue = false
    BroadcastQueueState(party)
end

RegisterNetEvent(Config.Events.QueueJoin, function(data)
    local src   = source
    local mode  = (type(data) == 'table' and data.mode)  or data or 'Solo'
    local mapId = (type(data) == 'table' and data.mapId) or 'city_outskirts'

    local party = GetPlayerParty(src)
    if not party then
        TriggerEvent('extraction:setMode', mode)
        party = GetPlayerParty(src)
    end
    if not party or party.leader ~= src then return end
    if QueuedParties[party.id] then return end

    party.mode  = mode
    party.mapId = mapId
    local count = 0
    for _ in pairs(party.members) do count = count + 1 end
    local cfg = Config.Match.Modes[party.mode]
    if not cfg or count < cfg.min or count > cfg.max then return end
    EnqueueParty(party)
end)

RegisterNetEvent(Config.Events.QueueCancel, function()
    local src = source
    local party = GetPlayerParty(src)
    if not party or party.leader ~= src then return end
    if QueuedParties[party.id] then DequeueParty(party) end
end)

-- Allow client to update selected map before queuing
RegisterNetEvent('extraction:setMap', function(data)
    local src   = source
    local mapId = type(data) == 'table' and data.mapId or 'city_outskirts'
    local party = GetPlayerParty(src)
    if not party then return end
    party.mapId = mapId
    BroadcastQueueState(party)
end)

local function RunMatchmaker()
    local queued = {}
    for partyId, _ in pairs(QueuedParties) do
        local party = Parties[partyId]
        if party then queued[#queued+1] = party end
    end
    if #queued == 0 then return end

    table.sort(queued, function(a, b)
        return (QueuedParties[a.id] and QueuedParties[a.id].joinedAt or 0)
             < (QueuedParties[b.id] and QueuedParties[b.id].joinedAt or 0)
    end)

    -- Group parties by their chosen map
    local byMap = {}
    for _, party in ipairs(queued) do
        local mid = party.mapId or 'city_outskirts'
        byMap[mid] = byMap[mid] or {}
        table.insert(byMap[mid], party)
    end

    for mapId, mapParties in pairs(byMap) do
        local players       = {}
        local matchedParties = {}
        for _, party in ipairs(mapParties) do
            local memberCount = 0
            for _ in pairs(party.members) do memberCount = memberCount + 1 end
            if (#players + memberCount) <= Config.Match.MaxPlayers then
                matchedParties[#matchedParties+1] = party
                for src, _ in pairs(party.members) do
                    players[#players+1] = src
                end
            end
            if #players >= Config.Match.MinPlayers then break end
        end

        if #players >= Config.Match.MinPlayers then
            for _, party in ipairs(matchedParties) do
                DequeueParty(party)
                party.inMatch = true
                BroadcastQueueState(party)
            end
            TriggerEvent('extraction:internal:createMatch', players, mapId)
        end
    end
end

CreateThread(function()
    while true do
        Wait(Config.Match.QueueCheckMs)
        RunMatchmaker()
    end
end)
