-- sv_extraction.lua · Extraction logic — stash opens AFTER bucket restore
ActiveExtractions = ActiveExtractions or {}

local function GetStashOwner(src)
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:find('license:') == 1 then return identifier end
    end
    return tostring(src)
end

local function EnsureExtractionStash(src)
    local owner   = GetStashOwner(src)
    local stashId = Config.StashPrefix..owner
    exports.ox_inventory:RegisterStash(stashId, 'Extraction Stash', Config.Stash.Slots, Config.Stash.MaxWeight, owner)
    return stashId, owner
end

AddEventHandler('playerJoining', function()
    local src = source
    EnsureExtractionStash(src)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, pid in ipairs(GetPlayers()) do EnsureExtractionStash(tonumber(pid)) end
end)

local function CancelExtraction(src, reason)
    if not ActiveExtractions[src] then return end
    ActiveExtractions[src] = nil
    TriggerClientEvent(Config.Events.ExtractionFail, src, reason or 'Extraction cancelled.')
end

local function FinishExtraction(src, matchId)
    ActiveExtractions[src] = nil
    -- Restore bucket first, THEN send success + open stash
    SetPlayerExtracted(src)
    -- Notify party teammates
    NotifyPartyOfExtraction(src)
    -- Fire extraction success to client
    TriggerClientEvent(Config.Events.ExtractionSuccess, src, {})
    -- Wait for client to process bucket restore, then open stash
    SetTimeout(1500, function()
        local stashId, owner = EnsureExtractionStash(src)
        TriggerClientEvent(Config.Events.OpenStash, src, { id = stashId, owner = owner })
    end)
end

RegisterNetEvent(Config.Events.ExtractionStart, function(ptIndex)
    local src     = source
    local matchId = GetPlayerMatch(src)
    if not matchId then TriggerClientEvent(Config.Events.ExtractionFail, src, 'Not in a match.'); return end
    local inst = GetInstance(matchId)
    if not inst or inst.state ~= 'active' then TriggerClientEvent(Config.Events.ExtractionFail, src, 'Match not active.'); return end
    local ps = inst.players[src]
    if not ps or not ps.alive then TriggerClientEvent(Config.Events.ExtractionFail, src, 'You are not alive.'); return end
    local pt = inst.extractionPts[tonumber(ptIndex or 0)]
    if not pt or not pt.active then TriggerClientEvent(Config.Events.ExtractionFail, src, 'Extraction point unavailable.'); return end
    if ActiveExtractions[src] then return end

    ActiveExtractions[src] = { matchId = matchId, ptIndex = ptIndex, startedAt = GetGameTimer() }
    CreateThread(function()
        local startTime = GetGameTimer()
        while ActiveExtractions[src] do
            Wait(250)
            local ci = GetInstance(matchId)
            if not ci or ci.state ~= 'active' then CancelExtraction(src, 'Match ended.'); return end
            local cp = ci.players[src]
            if not cp or not cp.alive then CancelExtraction(src, 'You died.'); return end
            if GetGameTimer() - startTime >= Config.Extraction.Duration * 1000 then
                FinishExtraction(src, matchId); return
            end
        end
    end)
end)

RegisterNetEvent(Config.Events.ExtractionCancel, function()
    CancelExtraction(source, 'You moved or were interrupted.')
end)

-- Manual stash open (debug / NPC)
RegisterNetEvent('extraction:requestOpenStash', function()
    local src = source
    local stashId, owner = EnsureExtractionStash(src)
    TriggerClientEvent(Config.Events.OpenStash, src, { id = stashId, owner = owner })
end)
