-- cl_extraction.lua · v4
-- Extraction is proximity-based: player walks into zone, timer starts automatically.
-- Fixed: use ~n~ for GTA text line breaks (not \n)
inMatch = false
local matchData       = nil
local extractionState = 'idle'
local cancelProgress  = nil

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

                DrawMarker(1,
                    pt.coords.x, pt.coords.y, pt.coords.z,
                    0,0,0, 0,0,0,
                    radius*2, radius*2, 1.5,
                    232, 97, 42, 120,
                    false, true, 2, nil, nil, false)

                -- Use ~n~ for line breaks in GTA native text (not \n)
                CUtils.Draw3DText(ptVec, pt.label .. '~n~Extract')

                if dist < nearestDist then nearestDist = dist; nearest = i end
            end
        end

        if nearest and nearestDist <= radius then
            if extractionState == 'idle' then
                extractionState = 'near'
                CUtils.Notify('Extraction started — stay in zone!', 'success')
                StartExtraction(nearest)
            end
        else
            if extractionState == 'extracting' then
                CancelExtraction('Left extraction zone!')
            elseif extractionState == 'near' then
                extractionState = 'idle'
            end
        end

        ::continue::
    end
end)

function StartExtraction(ptIndex)
    if extractionState ~= 'near' then return end
    extractionState = 'extracting'
    TriggerServerEvent(Config.Events.ExtractionStart, ptIndex)
    CUtils.SendNui('extractionStart', { duration = Config.Extraction.Duration })
    cancelProgress = CUtils.ProgressBar(Config.Extraction.Duration, '', function() end, nil)
end

function CancelExtraction(reason)
    if extractionState ~= 'extracting' then return end
    if cancelProgress then cancelProgress(); cancelProgress = nil end
    extractionState = 'idle'
    TriggerServerEvent(Config.Events.ExtractionCancel)
    CUtils.SendNui('extractionCancel', {})
    CUtils.Notify(reason or 'Extraction cancelled.', 'error')
end

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
