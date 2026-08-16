-- cl_ai.lua · AI peds with correct weapons, combat, and looting
local spawnedPeds = {}
local aiActive    = false

local AI_WEAPONS = {
    { hash = `WEAPON_PISTOL`,       ammo = 24  },
    { hash = `WEAPON_MICROSMG`,     ammo = 30  },
    { hash = `WEAPON_APPISTOL`,     ammo = 18  },
    { hash = `WEAPON_SMG`,          ammo = 30  },
    { hash = `WEAPON_CARBINERIFLE`, ammo = 30  },
}

local AI_MODELS = {
    `s_m_y_cop_01`,
    `g_m_y_lost_01`,
    `g_m_y_famca_01`,
    `g_m_y_ballaorig_01`,
    `g_m_m_ghetto_01`,
    `a_m_y_skater_01`,
}

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

local function SpawnAiPed(spawnCoords)
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

    local wep = AI_WEAPONS[math.random(#AI_WEAPONS)]
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
    -- NOTE: SetPedIsTargetPriority removed — not a valid FiveM native

    return ped
end

local function SetupPedCombat(ped)
    if not DoesEntityExist(ped) then return end
    local player = PlayerPedId()
    TaskCombatPed(ped, player, 0, 16)
    CreateThread(function()
        while DoesEntityExist(ped) and not IsPedDead(ped) and aiActive do
            Wait(800)
            if not DoesEntityExist(ped) or IsPedDead(ped) then break end
            local dist = #(GetEntityCoords(ped) - GetEntityCoords(player))
            if dist < 80.0 then
                if not IsPedInCombat(ped, player) then
                    TaskCombatPed(ped, player, 0, 16)
                end
            else
                TaskWanderInArea(ped, GetEntityCoords(ped).x, GetEntityCoords(ped).y, GetEntityCoords(ped).z, 25.0, 2.0, 0.0)
            end
        end
    end)
end

local function SpawnMatchAI(mapData)
    if not mapData or not mapData.spawns then return end
    aiActive = true
    local count = math.random(5, 9)
    for i = 1, count do
        Wait(math.random(300, 900))
        if not aiActive then break end
        local ref = mapData.spawns[math.random(#mapData.spawns)]
        local ped = SpawnAiPed(vector3(ref.x, ref.y, ref.z))
        if ped then
            table.insert(spawnedPeds, ped)
            SetupPedCombat(ped)
        end
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
