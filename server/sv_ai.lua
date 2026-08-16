-- server/sv_ai.lua · v2
-- Accepts evName from client so each weapon request gets its own reply channel.

local pool = {}

local function rebuild()
    pool = {}
    local ok, items = pcall(function() return exports.ox_inventory:Items() end)
    if ok and items then
        for name, _ in pairs(items) do
            if type(name) == 'string' and name:sub(1, 7) == 'weapon_' then
                pool[#pool + 1] = { name = name, hash = GetHashKey(name:upper()), ammo = 30 }
            end
        end
    end
    -- Fallback if ox_inventory has no weapon items registered
    if #pool == 0 then
        pool = {
            { hash = GetHashKey('WEAPON_PISTOL'),         ammo = 24 },
            { hash = GetHashKey('WEAPON_SMG'),             ammo = 30 },
            { hash = GetHashKey('WEAPON_ASSAULTRIFLE'),    ammo = 30 },
            { hash = GetHashKey('WEAPON_CARBINERIFLE'),    ammo = 30 },
            { hash = GetHashKey('WEAPON_PUMPSHOTGUN'),     ammo = 8  },
            { hash = GetHashKey('WEAPON_MICROSMG'),        ammo = 30 },
        }
    end
end

AddEventHandler('onResourceStart', function(r)
    if r == GetCurrentResourceName() then
        Wait(1500)
        rebuild()
        print('[Extraction] AI weapon pool built: ' .. #pool .. ' weapons')
    end
end)

-- evName: the unique client-side event channel to reply on
RegisterNetEvent('extraction:getRandomWeapon', function(evName)
    if not evName or type(evName) ~= 'string' then return end
    if #pool == 0 then rebuild() end
    local chosen = pool[math.random(#pool)]
    TriggerClientEvent(evName, source, { hash = chosen.hash, ammo = chosen.ammo })
end)
