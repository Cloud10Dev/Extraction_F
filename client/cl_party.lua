-- cl_party.lua · Party, queue, NUI bridge
local menuOpen   = false
local partyState = nil

local function GetMapsPayload()
    local maps = {}
    for _, m in ipairs(Config.Maps) do
        maps[#maps+1] = { id = m.id, name = m.name, label = m.label, players = m.players }
    end
    return maps
end

local function OpenMenu()
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action  = 'open',
        payload = {
            party = partyState,
            maps  = GetMapsPayload(),
        }
    })
end

local function CloseMenu()
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterKeyMapping('partymenu', 'Open Operations Menu', 'keyboard', 'F7')
RegisterCommand('partymenu', function() if menuOpen then CloseMenu() else OpenMenu() end end, false)
RegisterCommand('party',     function() if menuOpen then CloseMenu() else OpenMenu() end end, false)

RegisterNetEvent(Config.Events.PartyUpdate, function(data)
    partyState = data
    SendNUIMessage({ action = 'partyUpdate', payload = { party = data } })
end)

RegisterNetEvent('extraction:notification', function(msg, kind)
    CUtils.Notify(msg, kind or 'info')
    SendNUIMessage({ action = 'notification', payload = { msg = msg, type = kind } })
end)

RegisterNetEvent(Config.Events.MatchFound, function(data)
    SendNUIMessage({ action = 'matchFound', payload = data })
    CUtils.Notify('Match found! Deploying in '..(data.countdown or 5)..'s…', 'success')
    CloseMenu()
end)

RegisterNetEvent(Config.Events.PartyInvite, function(data)
    SendNUIMessage({ action = 'incomingInvite', payload = data })
    CUtils.Notify(data.fromName..' invited you to a fireteam (F7).', 'info')
end)

RegisterNUICallback('closeMenu',     function(_, cb) CloseMenu(); cb({}) end)
RegisterNUICallback('openMenu',      function(_, cb) OpenMenu(); cb('ok') end)
RegisterNUICallback('invitePlayer',  function(data, cb) TriggerServerEvent(Config.Events.PartyInvite, tonumber(data.targetSrc)); cb({}) end)
RegisterNUICallback('acceptInvite',  function(data, cb) TriggerServerEvent(Config.Events.PartyInviteAccept, data.inviteKey); cb({}) end)
RegisterNUICallback('declineInvite', function(data, cb) TriggerServerEvent(Config.Events.PartyInviteDecline, data.inviteKey); cb({}) end)
RegisterNUICallback('leaveParty',    function(_, cb) TriggerServerEvent(Config.Events.PartyLeave); cb({}) end)
RegisterNUICallback('queueJoin',     function(data, cb) TriggerServerEvent(Config.Events.QueueJoin, { mode = data.mode, mapId = data.mapId }); cb({}) end)
RegisterNUICallback('queueCancel',   function(_, cb) TriggerServerEvent(Config.Events.QueueCancel); cb({}) end)
RegisterNUICallback('setMode',       function(data, cb) TriggerServerEvent('extraction:setMode', data.mode); cb({}) end)
RegisterNUICallback('setMap',        function(data, cb) TriggerServerEvent('extraction:setMap', { mapId = data.mapId }); cb({}) end)
RegisterNUICallback('kickMember',    function(data, cb) TriggerServerEvent(Config.Events.PartyKick, tonumber(data.targetSrc)); cb({}) end)
RegisterNUICallback('openStash',     function(_, cb)
    TriggerServerEvent('extraction:requestOpenStash')
    cb({})
end)
