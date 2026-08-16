-- server/sv_ai.lua · NEW FILE
-- Picks a random weapon from the ox_inventory item registry and sends it to
-- the requesting client via the extraction:receiveRandomWeapon net event.

local pool = {}

local function RebuildPool()
    pool = {}
    local ok, items = pcall(function() return exports.ox_inventory:Items() end)
    if ok and items then
        for name, _ in pairs(items) do
            if type(name) == 'string' and name:sub(1, 7) == 'weapon_' then
                -- GetHashKey works server-side in FiveM
                local hash = GetHashKey(name:upper())
                table.insert(pool, { name = name, hash = hash, ammo = 30 })
            end
        end
    end
    -- Hard-coded fallback so AI always arms itself even if ox_inventory is unavailable
    if #pool == 0 then
        pool = {
            { hash = GetHashKey('WEAPON_PISTOL'),         ammo = 24 },
            { hash = GetHashKey('WEAPON_SMG'),            ammo = 30 },
            { hash = GetHashKey('WEAPON_ASSAULTRIFLE'),   ammo = 30 },
            { hash = GetHashKey('WEAPON_PUMPSHOTGUN'),    ammo = 8  },
            { hash = GetHashKey('WEAPON_CARBINERIFLE'),   ammo = 30 },
            { hash = GetHashKey('WEAPON_HEAVYSHOTGUN'),   ammo = 8  },
        }
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Wait briefly so ox_inventory finishes its own startup
        SetTimeout(1500, function() RebuildPool() end)
    end
end)

RegisterNetEvent('extraction:getRandomWeapon', function()
    if #pool == 0 then RebuildPool() end
    local src    = source
    local chosen = pool[math.random(#pool)]
    TriggerClientEvent('extraction:receiveRandomWeapon', src, {
        hash = chosen.hash,
        ammo = chosen.ammo,
        name = chosen.name,
    })
end)
