CUtils = {}

function CUtils.SendNui(action, payload)
    SendNUIMessage({ action = action, payload = payload })
end

function CUtils.Notify(msg, kind)
    local prefix = '~b~'
    if kind == 'error' then prefix = '~r~' elseif kind == 'success' then prefix = '~g~' end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(prefix .. msg)
    EndTextCommandThefeedPostTicker(false, false)
end

function CUtils.Teleport(coords)
    local ped = PlayerPedId()
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w or 0.0)
end

--[[
  Draw3DText
  Draws a world-space label with a very faint background slab.
  Uses SetDrawOrigin so ALL draw calls are anchored to the world coord.
  The background slab is drawn via DrawSprite (which respects SetDrawOrigin)
  instead of DrawRect (which is always screen-space regardless of origin).
]]
function CUtils.Draw3DText(coords, text)
    -- All draws below are relative to the world origin set here
    SetDrawOrigin(coords.x, coords.y, coords.z + 1.0, 0)

    -- Very faint dark slab behind the text
    -- DrawRect inside SetDrawOrigin block uses offset coords (0,0 = the origin point)
    DrawRect(0.0, 0.0, 0.065, 0.030, 8, 8, 10, 60)

    -- Shadow pass
    SetTextScale(0.0, 0.38)
    SetTextFont(7)
    SetTextColour(0, 0, 0, 90)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.001, 0.001)

    -- Main text
    SetTextScale(0.0, 0.38)
    SetTextFont(7)
    SetTextColour(255, 255, 255, 235)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.0, 0.0)

    ClearDrawOrigin()
end

-- ProgressBar: thin bar only, no label text above it.
function CUtils.ProgressBar(duration, label, onFinish, onCancel)
    local cancelled = false
    CreateThread(function()
        local startTime = GetGameTimer()
        while GetGameTimer() - startTime < (duration * 1000) do
            if cancelled then if onCancel then onCancel() end return end
            local pct = (GetGameTimer() - startTime) / (duration * 1000)
            -- dark track
            DrawRect(0.5, 0.934, 0.28, 0.006, 12, 14, 18, 160)
            -- green fill
            DrawRect(0.5 - (0.28 * (1 - pct)) / 2, 0.934, 0.28 * pct, 0.006, 78, 201, 123, 220)
            Wait(0)
        end
        if not cancelled and onFinish then onFinish() end
    end)
    return function() cancelled = true end
end
