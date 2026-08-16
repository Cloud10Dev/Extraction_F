-- cl_extraction.lua · v3
-- Extraction is proximity-based: player walks into zone, timer starts automatically.
-- Player CAN move freely inside the zone. If they leave, extraction cancels.
-- No key press required.
inMatch = false
local matchData       = nil
local extractionState = 'idle'   -- idle | near | extracting
local cancelProgress  = nil
local exfilThread     = nil

RegisterNetEvent(Config.Events.MatchTeleport, function(data)
    matchData       = data
    inMatch         = true
    extractionState = 'idle'
    CUtils.Teleport(vector4(data.coords.x, data.coords.y, data.coords.z, data.coords.w))
    CUtils.Notify('Deployed! Reach an extraction point to escape.', 'success')
    CUtils.SendNui('matchStart', { extractPts = data.extractPts })

    if data.zone then
        CreateThread(function()
            while inMatch do
                Wait(0)
                DrawZone(data.zone)
            end
        end)
    end
end)

function DrawZone(zone)
    if zone.type == 'circle' then
        local c = zone.center
        for i = 0, 31 do
            local a1 = (i/32)     * (math.pi*2)
            local a2 = ((i+1)/32) * (math.pi*2)
            DrawLine(
                c.x + math.cos(a1)*zone.radius, c.y + math.sin(a1)*zone.radius, c.z+0.1,
                c.x + math.cos(a2)*zone.radius, c.y + math.sin(a2)*zone.radius, c.z+0.1,
                232, 97, 42, 180
            )
        end
    elseif zone.type == 'polygon' then
        local v = zone.vertices
        for i = 1, #v do
            local v1 = v[i]; local v2 = v[(i%#v)+1]
            DrawLine(v1.x,v1.y,v1.z+0.1, v2.x,v2.y,v2.z+0.1, 232,97,42,180)
        end
    end
end

-- ─── Main extraction loop ───────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(inMatch and 0 or 500)
        if not inMatch or not matchData then goto continue end

        local ped    = PlayerPedId()
        local myPos  = GetEntityCoords(ped)
        local radius = Config.Extraction.PointRadius
        local nearest, nearestDist = nil, math.huge

        for i, pt in ipairs(matchData.extractPts) do
            if pt.active then
                local ptVec = vector3(pt.coords.x, pt.coords.y, pt.coords.z)
                local dist  = #(myPos - ptVec)

                -- Draw marker
                DrawMarker(1,
                    pt.coords.x, pt.coords.y, pt.coords.z,
                    0,0,0, 0,0,0,
                    radius*2, radius*2, 1.5,
                    232, 97, 42, 120,
                    false, true, 2, nil, nil, false)

                -- Label: no key prompt anymore
                CUtils.Draw3DText(ptVec, pt.label .. '\nExtract')

                if dist < nearestDist then nearestDist = dist; nearest = i end
            end
        end

        -- ── Proximity detection ─────────────────────────────────────────────
        if nearest and nearestDist <= radius then
            -- Just entered zone
            if extractionState == 'idle' then
                extractionState = 'near'
                CUtils.Notify('Extraction started — stay in zone!', 'success')
                StartExtraction(nearest)
            end
        else
            -- Player left zone while extracting → cancel
            if extractionState == 'extracting' then
                CancelExtraction('Left extraction zone!')
            elseif extractionState == 'near' then
                -- edge case: started but server didn't respond yet
                extractionState = 'idle'
            end
        end

        ::continue::
    end
end)

-- ─── Start extraction ───────────────────────────────────────────────────────
function StartExtraction(ptIndex)
    if extractionState ~= 'near' then return end
    extractionState = 'extracting'
    -- Player can still move — no freeze
    TriggerServerEvent(Config.Events.ExtractionStart, ptIndex)
    CUtils.SendNui('extractionStart', { duration = Config.Extraction.Duration })
    cancelProgress = CUtils.ProgressBar(Config.Extraction.Duration, 'Extracting — stay in zone...', function() end, nil)
end

-- ─── Cancel extraction ──────────────────────────────────────────────────────
function CancelExtraction(reason)
    if extractionState ~= 'extracting' then return end
    if cancelProgress then cancelProgress(); cancelProgress = nil end
    extractionState = 'idle'
    TriggerServerEvent(Config.Events.ExtractionCancel)
    CUtils.SendNui('extractionCancel', {})
    CUtils.Notify(reason or 'Extraction cancelled.', 'error')
end

-- ─── Server events ──────────────────────────────────────────────────────────
RegisterNetEvent(Config.Events.ExtractionSuccess, function()
    if cancelProgress then cancelProgress(); cancelProgress = nil end
    extractionState = 'idle'
    inMatch         = false
    matchData       = nil
    CUtils.SendNui('extractionSuccess', {})
end)

RegisterNetEvent(Config.Events.ExtractionFail, function(reason)
    if cancelProgress then cancelProgress(); cancelProgress = nil end
    extractionState = 'idle'
    CUtils.Notify(reason or 'Extraction failed.', 'error')
    CUtils.SendNui('extractionFail', { reason = reason })
end)

RegisterNetEvent(Config.Events.OpenStash, function(stashData)
    local opened = exports.ox_inventory:openInventory('stash', {
        id    = stashData.id,
        owner = stashData.owner,
    })
    if opened == false then CUtils.Notify('Stash failed to open.', 'error') end
end)

RegisterNetEvent(Config.Events.RespawnLobby, function()
    inMatch         = false
    matchData       = nil
    extractionState = 'idle'
    if cancelProgress then cancelProgress(); cancelProgress = nil end
    local spawn = Config.LobbySpawns[math.random(1, #Config.LobbySpawns)]
    CUtils.Teleport(spawn)
    CUtils.Notify('Returned to lobby.', 'info')
    CUtils.SendNui('returnedToLobby', {})
end)

RegisterCommand('teststash', function()
    TriggerServerEvent('extraction:requestOpenStash')
end, false)
