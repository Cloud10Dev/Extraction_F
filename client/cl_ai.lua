-- client/cl_ai.lua · v2 — ox_inventory random weapons + correct ammo per weapon

local spawnedPeds = {}
local aiActive    = false

-- Local fallback weapon pool (used if server doesn't respond in time)
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

-- Ask the server for a random weapon from the ox_inventory item registry.
-- Calls cb({ hash, ammo }) — falls back to local pool after 1200ms.
local function GetRandomOxWeapon(cb)
    local done = false

    RegisterNetEvent('extraction:receiveRandomWeapon', function(data)
        if done then return end
        done = true
        if data and data.hash then
            cb({ hash = data.hash, ammo = data.ammo or 30 })
        else
            cb(FALLBACK_WEAPONS[math.random(#FALLBACK_WEAPONS)])
        end
    end)

    TriggerServerEvent('extraction:getRandomWeapon')

    SetTimeout(1200, function()
        if not done then
            done = true
            cb(FALLBACK_WEAPONS[math.random(#FALLBACK_WEAPONS)])
        end
    end)
end

local function LoadModel(modelHash)
    if not IsModelInCdimage(modelHash) then return false end
    RequestModel(modelHash)
    local t = 0
    while not HasModelLoaded(modelHash) do
        Wait(50); t = t + 50
        if t > 4000 then return false end
    end
    return true
end

local function SpawnAiPed(spawnCoords, wep)
    local modelHash = AI_MODELS[math.random(#AI_MODELS)]
    if not LoadModel(modelHash) then return nil end

    local ox = math.random(-20, 20) + 0.0
    local oy = math.random(-20, 20) + 0.0
    local x, y, z = spawnCoords.x + ox, spawnCoords.y + oy, spawnCoords.z

    local found, gz = GetGroundZFor_3dCoord(x, y, z + 5.0, false)
    if found then z = gz end

    local ped = CreatePed(4, modelHash, x, y, z, math.random(0, 359) + 0.0, true, true)
    SetModelAsNoLongerNeeded(modelHash)
    if not DoesEntityExist(ped) then return nil end

    SetEntityOnGroundProperly(ped)
    SetPedCanRagdoll(ped, true)

    GiveWeaponToPed(ped, wep.hash, wep.ammo, false, true)
    SetCurrentPedWeapon(ped, wep.hash, true)
    SetPedAmmo(ped, wep.hash, wep.ammo)
    SetPedDropsWeaponsWhenDead(ped, true)

    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, math.random(120, 180))
    SetPedArmour(ped, 0)

    SetPedRelationshipGroupHash(ped, GetHashKey('HATES_PLAYER'))
    SetRelationshipBetweenGroups(5, GetHashKey('HATES_PLAYER'), GetHashKey('PLAYER'))
    SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), GetHashKey('HATES_PLAYER'))

    SetPedCombatAbility(ped, 50)
    SetPedCombatRange(ped, 2)
    SetPedCombatMovement(ped, 2)
    SetPedAccuracy(ped, 35)
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

    return ped
end

local function SpawnMatchAI(mapData)
    if not mapData or not mapData.spawns then return end
    aiActive = true
    local count = math.random(5, 9)
    for i = 1, count do
        Wait(math.random(300, 900))
        if not aiActive then break end
        local ref = mapData.spawns[math.random(#mapData.spawns)]
        GetRandomOxWeapon(function(wep)
            if not aiActive then return end
            local ped = SpawnAiPed(vector3(ref.x, ref.y, ref.z), wep)
            if ped then
                table.insert(spawnedPeds, ped)
            end
        end)
    end
end

local function CleanupAI()
    aiActive = false
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    spawnedPeds = {}
end

RegisterNetEvent(Config.Events.MatchTeleport, function(data)
    SetTimeout(3000, function()
        if not inMatch then return end
        local mapCfg = Config.GetMap(data.mapId or 'city_outskirts')
        SpawnMatchAI(mapCfg)
    end)
end)

RegisterNetEvent(Config.Events.RespawnLobby,      function() CleanupAI() end)
RegisterNetEvent(Config.Events.ExtractionSuccess, function() CleanupAI() end)
