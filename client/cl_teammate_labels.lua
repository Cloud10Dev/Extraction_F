-- cl_teammate_labels.lua
-- Draws name + health bar above teammates' heads. Fades with distance.

local MAX_DIST     = 50.0   -- beyond this: fully invisible
local FADE_START   = 30.0   -- start fading at this distance
local LABEL_HEIGHT = 1.15   -- metres above ped origin

local function GetAlpha(dist)
    if dist >= MAX_DIST   then return 0   end
    if dist <= FADE_START then return 215 end
    local t = (dist - FADE_START) / (MAX_DIST - FADE_START)
    return math.floor(215 * (1.0 - t))
end

local function DrawHealthBar(x, y, health, alpha)
    -- health 0-100 mapped to a small bar
    local barW  = 0.035
    local barH  = 0.004
    local fillW = barW * (health / 100.0)

    -- background
    DrawRect(x, y + 0.012, barW, barH, 0, 0, 0, math.floor(alpha * 0.6))
    -- health fill  (green → yellow → red)
    local r, g = 200, 168
    if health > 60 then
        r, g = 78, 201   -- green
    elseif health > 30 then
        r, g = 200, 168  -- gold
    else
        r, g = 217, 79   -- red
    end
    DrawRect(x - (barW - fillW) / 2, y + 0.012, fillW, barH, r, g, 75, alpha)
end

CreateThread(function()
    while true do
        Wait(0)
        -- Only draw while in a match to save performance
        if not inMatch then Wait(500) goto continue end

        local myPed = PlayerPedId()
        local mySrc = GetPlayerServerId(PlayerId())

        for _, pid in ipairs(GetActivePlayers()) do
            local targetSrc = GetPlayerServerId(pid)
            if targetSrc == mySrc then goto skip end  -- skip self

            local ped = GetPlayerPed(pid)
            if not DoesEntityExist(ped) then goto skip end
            if IsEntityDead(ped)        then goto skip end

            local pedCoords = GetEntityCoords(ped)
            local dist      = #(GetEntityCoords(myPed) - pedCoords)
            local alpha     = GetAlpha(dist)
            if alpha <= 0 then goto skip end

            -- Project 3D world pos to 2D screen
            local labelPos = vector3(pedCoords.x, pedCoords.y, pedCoords.z + LABEL_HEIGHT)
            local onScreen, sx, sy = World3dToScreen2d(labelPos.x, labelPos.y, labelPos.z)
            if not onScreen then goto skip end

            -- Health (0–200 native → 0–100%)
            local rawHp  = GetEntityHealth(ped)
            local maxHp  = GetEntityMaxHealth(ped)
            local health = math.floor(((rawHp - 100) / math.max(maxHp - 100, 1)) * 100)
            health = math.max(0, math.min(100, health))

            local name = GetPlayerName(pid) or ('Player#' .. targetSrc)

            -- Name text  (Rajdhani-style via game font 4)
            SetTextScale(0.0, 0.28)
            SetTextFont(4)
            SetTextColour(200, 168, 75, alpha)   -- gold accent
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(name)
            DrawText(sx, sy - 0.018)

            -- Distance tag  (tiny, muted)
            SetTextScale(0.0, 0.20)
            SetTextFont(4)
            local distAlpha = math.floor(alpha * 0.6)
            SetTextColour(180, 175, 165, distAlpha)
            SetTextEntry('STRING')
            AddTextComponentString(string.format('%.0fm', dist))
            DrawText(sx, sy - 0.002)

            DrawHealthBar(sx, sy, health, alpha)

            ::skip::
        end

        ::continue::
    end
end)
