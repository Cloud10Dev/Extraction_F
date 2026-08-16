Config = {}

-- Multi-Map system: each map has its own spawns, exfil points, and draw zone.
Config.Maps = {
    {
        id      = 'city_outskirts',
        name    = 'City Outskirts',
        label   = 'DEFAULT',
        players = '2-20',
        spawns  = {
            vector4(412.35, -981.12, 30.69, 180.0),
            vector4(425.10, -971.50, 30.69, 90.0),
            vector4(400.00, -990.00, 30.69, 270.0),
            vector4(430.00, -960.00, 30.69, 0.0),
        },
        extractionPts = {
            { coords = vector3(380.0, -940.0, 30.69),  label = 'North Evac' },
            { coords = vector3(450.0, -1010.0, 30.69), label = 'South Gate' },
            { coords = vector3(395.0, -990.0, 30.69),  label = 'Central Drop' },
        },
        zone = {
            type   = 'circle',
            center = vector3(415.0, -980.0, 30.0),
            radius = 120.0,
        },
    },
    {
        id      = 'industrial_port',
        name    = 'Industrial Port',
        label   = 'HARDCORE',
        players = '4-20',
        spawns  = {
            vector4(950.0, -2000.0, 30.0, 0.0),
            vector4(960.0, -2010.0, 30.0, 90.0),
            vector4(940.0, -1990.0, 30.0, 180.0),
        },
        extractionPts = {
            { coords = vector3(930.0, -1970.0, 30.0), label = 'Pier Alpha' },
            { coords = vector3(980.0, -2030.0, 30.0), label = 'Container Yard' },
        },
        zone = {
            type   = 'circle',
            center = vector3(955.0, -2000.0, 30.0),
            radius = 150.0,
        },
    },
    {
        id      = 'downtown_ruins',
        name    = 'Downtown Ruins',
        label   = 'NIGHT OPS',
        players = '2-12',
        spawns  = {
            vector4(200.0, -820.0, 30.0, 90.0),
            vector4(215.0, -835.0, 30.0, 270.0),
        },
        extractionPts = {
            { coords = vector3(185.0, -800.0, 30.0), label = 'Rooftop LZ' },
            { coords = vector3(230.0, -850.0, 30.0), label = 'Alley Exit' },
        },
        zone = {
            type   = 'circle',
            center = vector3(207.0, -828.0, 30.0),
            radius = 100.0,
        },
    },
}

function Config.GetMap(mapId)
    for _, m in ipairs(Config.Maps) do
        if m.id == mapId then return m end
    end
    return Config.Maps[1]
end

Config.Match = {
    MinPlayers      = 2,
    MaxPlayers      = 20,
    QueueCheckMs    = 5000,
    MatchStartDelay = 5,
    Modes = {
        Solo  = { min = 1, max = 1 },
        Duo   = { min = 2, max = 2 },
        Squad = { min = 3, max = 4 },
    }
}

Config.Extraction = {
    Duration       = 10,
    InterruptRange = 5.0,
    PointRadius    = 3.0,
}

Config.Death = {
    DropLootOnDeath = true,
    RespawnDelay    = 7,
}

Config.Gameplay = {
    EnableAI     = true,   -- AI peds enabled
    FriendlyFire = false,
}

Config.Stash = {
    Slots     = 50,
    MaxWeight = 100000,
}

Config.StashPrefix = 'extraction_stash_'

Config.LobbySpawns = {
    vector4(-269.87, -955.89, 31.22, 205.7),
    vector4(-280.05, -965.01, 31.22, 160.2),
    vector4(-256.40, -963.32, 31.22, 95.0),
}

Config.Events = {
    -- Party
    PartyCreate     = 'extraction:partyCreate',
    PartyInvite     = 'extraction:partyInvite',
    PartyAccept     = 'extraction:partyAccept',
    PartyDecline    = 'extraction:partyDecline',
    PartyLeave      = 'extraction:partyLeave',
    PartyUpdate     = 'extraction:partyUpdate',
    IncomingInvite  = 'extraction:incomingInvite',
    -- Matchmaking
    QueueJoin       = 'extraction:queueJoin',
    QueueLeave      = 'extraction:queueLeave',
    QueueUpdate     = 'extraction:queueUpdate',
    -- Match
    MatchTeleport   = 'extraction:matchTeleport',
    MatchCountdown  = 'extraction:matchCountdown',
    -- Extraction
    ExtractionStart   = 'extraction:extractionStart',
    ExtractionSuccess = 'extraction:extractionSuccess',
    ExtractionCancel  = 'extraction:extractionCancel',
    ExtractionFail    = 'extraction:extractionFail',
    -- Death / Respawn
    PlayerDied    = 'extraction:playerDied',
    RespawnLobby  = 'extraction:respawnLobby',
    -- Stash
    OpenStash     = 'extraction:openStash',
}
