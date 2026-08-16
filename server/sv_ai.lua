-- server/sv_ai.lua · v2
-- Passes back to a per-call event name to avoid handler collisions

local pool = {}

local function RebuildPool()
    pool = {}
    local ok, items = pcall(function() return exports.ox_inventory:Items() end)
    if ok and items then
        for name, _ in pairs(items) do
            if type(name) == 'string' and name:sub(1, 7) == 'weapon_' then
                pool[#pool + 1] = { name = name, hash = GetHashKey(name:upper()), ammo = 30 }
            end
        end
    end
    if #pool == 0 then
        pool = {
            { hash = GetHashKey('WEAPON_PISTOL'),       ammo = 24 },
            { hash = GetHashKey('WEAPON_SMG'),          ammo = 30 },
            { hash = GetHashKey('WEAPON_ASSAULTRIFLE'), ammo = 30 },
            { hash = GetHashKey('WEAPON_PUMPSHOTGUN'),  ammo = 8  },
        }
    end
end

AddEventHandler('onResourceStart', function(r)
    if r == GetCurrentResourceName() then
        Wait(1500)
        RebuildPool()
    end
end)

-- Client sends the unique event name to reply to (avoids handler collisions)
RegisterNetEvent('extraction:getRandomWeapon', function(replyEvent)
    if #pool == 0 then RebuildPool() end
    local src = source
    local chosen = pool[math.random(#pool)]
    TriggerClientEvent(replyEvent or 'extraction:receiveRandomWeapon', src, chosen)
end)
