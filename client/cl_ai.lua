-- client/cl_ai.lua · v5
-- Respects Config.Gameplay.EnableAI flag.
-- No inMatch guard — fires 4s after MatchTeleport unconditionally (if AI enabled).

if not Config.Gameplay.EnableAI then return end

local spawnedPeds = {}
local aiActive    = false

local FALLBACK_WEAPONS = {
    { hash = `WEAPON_PISTOL`,         ammo = 24 },
    { hash = `WEAPON_PISTOL_MK2`,     ammo = 30 },
    { hash = `WEAPON_APPISTOL`,       ammo = 18 },
    { hash = `WEAPON_MICROSMG`,       ammo = 30 },
    { hash = `WEAPON_SMG`,            ammo = 30 },
    { hash = `WEAPON_SMG_MK2`,        ammo = 32 },
    { hash = `WEAPON_COMBATPDW`,      ammo = 30 },
    { hash = `WEAPON_CARBINERIFLE`,   ammo = 30 },
    { hash = `WEAPON_ASSAULTRIFLE`,   ammo = 30 },
    { hash = `WEAPON_PUMPSHOTGUN`,    ammo = 8  },
    { hash = `WEAPON_HEAVYSHOTGUN`,   ammo = 8  },
    { hash = `WEAPON_SAWNOFFSHOTGUN`, ammo = 8  },
}

local AI_MODELS = {
    `s_m_y_cop_01`,
    `g_m_y_lost_01`,
    `g_m_y_famca_01`,
    `g_m_y_ballaorig_01`,
    `g_m_m_ghetto_01`,
    `a_m_y_skater_01`,
}

local function GetRandomOxWeapon(cb)
    local done   = false
    local evName = 'extraction:rwep_' .. tostring(GetGameTimer()) .. '_' .. tostring(math.random(9999))
    RegisterNetEvent(evName)
    local handler
    handler = AddEventHandler(evName, function(data)
        if done then return end
        done = true
        RemoveEventHandler(handler)
        if data and data.hash then
            cb({ hash = data.hash, ammo = data.ammo or 30 })
        else
            cb(FALLBACK_WEAPONS[math.random(#FALLBACK_WEAPONS)])
        end
    end)
    TriggerServerEvent('extraction:getRandomWeapon', evName)
    SetTimeout(1500, function()
        if not done then
            done = true
            cb(FALLBACK_WEAPONS[math.random(#FALLBACK_WEAPONS)])
        end
    end)
end

local function LoadModel(h)
    if not IsModelInCdimage(h) then return false end
    RequestModel(h)
    local t = 0
    while not HasModelLoaded(h) do
        Wait(50); t = t + 50
        if t > 5000 then return false end
    end
    return true
end

local function SpawnAiPed(coords, wep)
    local model = AI_MODELS[math.random(#AI_MODELS)]
    if not LoadModel(model) then return end

    local angle = math.random() * math.pi * 2
    local dist  = math.random(10, 30) + 0.0
    local x = coords.x + math.cos(angle) * dist
    local y = coords.y + math.sin(angle) * dist
    local z = coords.z

    local found, gz = GetGroundZFor_3dCoord(x, y, z + 10.0, false)
    if found then z = gz end

    local ped = CreatePed(4, model, x, y, z, math.random(0, 359) + 0.0, true, true)
    SetModelAsNoLongerNeeded(model)
    if not DoesEntityExist(ped) then return end

    SetEntityOnGroundProperly(ped)
    SetPedCanRagdoll(ped, true)
    GiveWeaponToPed(ped, wep.hash, wep.ammo, false, true)
    SetCurrentPedWeapon(ped, wep.hash, true)
    SetPedAmmo(ped, wep.hash, wep.ammo)
    SetPedDropsWeaponsWhenDead(ped, true)
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, math.random(120, 180))
    SetPedArmour(ped, 0)

    local playerGroup = GetHashKey('PLAYER')
    local hatesGroup  = GetHashKey('HATES_PLAYER')
    SetPedRelationshipGroupHash(ped, hatesGroup)
    SetRelationshipBetweenGroups(5, hatesGroup, playerGroup)
    SetRelationshipBetweenGroups(5, playerGroup, hatesGroup)

    SetPedCombatAbility(ped, 50)
    SetPedCombatRange(ped, 2)
    SetPedCombatMovement(ped, 2)
    SetPedAccuracy(ped, 40)
    SetPedAlertness(ped, 3)
    SetPedSeeingRange(ped, 80.0)
    SetPedHearingRange(ped, 60.0)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5,  true)
    SetPedCombatAttributes(ped, 0,  true)
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, false)
    SetPedCanBeTargetted(ped, true)
    TaskCombatPed(ped, PlayerPedId(), 0, 16)

    table.insert(spawnedPeds, ped)
end

local function SpawnWave(spawnOrigin)
    aiActive = true
    local count = math.random(5, 9)
    CreateThread(function()
        for i = 1, count do
            Wait(math.random(500, 1200))
            if not aiActive then break end
            GetRandomOxWeapon(function(wep)
                if aiActive then SpawnAiPed(spawnOrigin, wep) end
            end)
        end
    end)
end

local function CleanupPeds()
    aiActive = false
    for _, p in ipairs(spawnedPeds) do
        if DoesEntityExist(p) then DeleteEntity(p) end
    end
    spawnedPeds = {}
end

RegisterNetEvent(Config.Events.MatchTeleport, function(data)
    CleanupPeds()
    local origin = vector3(data.coords.x, data.coords.y, data.coords.z)
    SetTimeout(4000, function()
        SpawnWave(origin)
    end)
end)

RegisterNetEvent(Config.Events.RespawnLobby,      function() CleanupPeds() end)
RegisterNetEvent(Config.Events.ExtractionSuccess, function() CleanupPeds() end)
RegisterNetEvent('extraction:aiCleanup',          function() CleanupPeds() end)
