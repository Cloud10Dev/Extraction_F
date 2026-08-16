-- sv_party.lua · Party management (party persists after extraction)
Parties = Parties or {}
PlayerParty = PlayerParty or {}
PendingInvites = PendingInvites or {}

local function BuildMemberList(party)
    local list = {}
    for src, _ in pairs(party.members) do
        list[#list+1] = {
            src    = src,
            name   = GetPlayerName(src) or ('Player#'..src),
            leader = src == party.leader,
        }
    end
    return list
end

local function SendPartyUpdate(party)
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

local function CreateParty(src)
    local id = Utils.GenId(8)
    Parties[id] = {
        id      = id,
        leader  = src,
        members = { [src] = true },
        mode    = 'Solo',
        inQueue = false,
        inMatch = false,
    }
    PlayerParty[src] = id
    return Parties[id]
end

function GetPlayerParty(src)
    local pid = PlayerParty[src]
    return pid and Parties[pid] or nil
end

-- LeaveParty is only called explicitly — NOT on extraction/match end
local function LeaveParty(src)
    local party = GetPlayerParty(src)
    if not party then return end
    party.members[src] = nil
    PlayerParty[src] = nil
    TriggerClientEvent(Config.Events.PartyUpdate, src, nil)
    local remaining = {}
    for member, _ in pairs(party.members) do remaining[#remaining+1] = member end
    if #remaining == 0 then Parties[party.id] = nil; return end
    if party.leader == src then party.leader = remaining[1] end
    SendPartyUpdate(party)
end

function NotifyPartyOfExtraction(extractedSrc)
    local party = GetPlayerParty(extractedSrc)
    if not party then return end
    local name = GetPlayerName(extractedSrc) or ('Player#'..extractedSrc)
    for src, _ in pairs(party.members) do
        if src ~= extractedSrc then
            TriggerClientEvent('extraction:notification', src, name..' has extracted successfully.', 'success')
        end
    end
end

RegisterNetEvent(Config.Events.PartyInvite, function(targetSrc)
    local src = source
    targetSrc = tonumber(targetSrc)
    if not targetSrc or not GetPlayerName(targetSrc) or targetSrc == src then return end
    local party = GetPlayerParty(src) or CreateParty(src)
    if party.leader ~= src then return end
    if PlayerParty[targetSrc] then return end
    local count = 0
    for _ in pairs(party.members) do count = count + 1 end
    local modeCfg = Config.Match.Modes[party.mode] or Config.Match.Modes.Squad
    if count >= modeCfg.max then return end
    local key = ('%s_%s'):format(src, targetSrc)
    PendingInvites[key] = { from = src, to = targetSrc, partyId = party.id, expireAt = os.time()+30 }
    TriggerClientEvent(Config.Events.PartyInvite, targetSrc, {
        inviteKey = key, fromSrc = src,
        fromName  = GetPlayerName(src), partyId = party.id, mode = party.mode,
    })
end)

RegisterNetEvent(Config.Events.PartyInviteAccept, function(inviteKey)
    local src = source
    local invite = PendingInvites[inviteKey]
    if not invite or invite.to ~= src or os.time() > invite.expireAt then
        PendingInvites[inviteKey] = nil; return
    end
    local party = Parties[invite.partyId]
    if not party then return end
    party.members[src] = true
    PlayerParty[src] = party.id
    PendingInvites[inviteKey] = nil
    SendPartyUpdate(party)
end)

RegisterNetEvent(Config.Events.PartyInviteDecline, function(inviteKey)
    PendingInvites[inviteKey] = nil
end)

RegisterNetEvent(Config.Events.PartyLeave, function()
    LeaveParty(source)
end)

RegisterNetEvent(Config.Events.PartyKick, function(targetSrc)
    local src = source
    local party = GetPlayerParty(src)
    if not party or party.leader ~= src then return end
    targetSrc = tonumber(targetSrc)
    if targetSrc and party.members[targetSrc] then LeaveParty(targetSrc) end
end)

RegisterNetEvent('extraction:setMode', function(mode)
    local src = source
    local party = GetPlayerParty(src) or CreateParty(src)
    if party.leader ~= src then return end
    if Config.Match.Modes[mode] then
        party.mode = mode
        SendPartyUpdate(party)
    end
end)

-- Only disband on player disconnect, not on match end
AddEventHandler('playerDropped', function() LeaveParty(source) end)
