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

-- Draw3DText: very light background slab behind the text,
-- text is drawn with a tilt (perspective skew via SetDrawOrigin offset)
-- to give a floating 3D billboard feel.
function CUtils.Draw3DText(coords, text)
    -- Derive the camera-facing angle for a slight tilt
    local camRot = GetGameplayCamRot(2)
    local tiltX  = math.rad(-camRot.x * 0.18)   -- lean toward camera

    -- Background slab: very low alpha rect drawn in world space
    local w, h = 0.12, 0.06
    DrawRect(
        0.5 - (w / 2) + 0.001, -- slight horizontal offset for shadow depth
        0.5 - (h / 2),
        w, h,
        0, 0, 0, 55
    )

    SetDrawOrigin(coords.x, coords.y, coords.z + 1.2, 0)
    -- Main label text
    SetTextScale(0.0, 0.40)
    SetTextFont(7)       -- Chalet London (clean narrow font)
    SetTextColour(255, 255, 255, 240)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.0, 0.0)

    -- Subtle shadow pass slightly offset
    SetTextScale(0.0, 0.40)
    SetTextFont(7)
    SetTextColour(0, 0, 0, 80)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.0015, 0.002)

    ClearDrawOrigin()
end

-- ProgressBar: bar only, NO label text drawn above it.
-- Returns a cancel function.
function CUtils.ProgressBar(duration, label, onFinish, onCancel)
    local cancelled = false
    CreateThread(function()
        local startTime = GetGameTimer()
        while GetGameTimer() - startTime < (duration * 1000) do
            if cancelled then if onCancel then onCancel() end return end
            local pct = (GetGameTimer() - startTime) / (duration * 1000)
            -- Only draw the bar rect, nothing else
            DrawRect(0.5, 0.935, 0.28, 0.007, 20, 20, 20, 160)
            DrawRect(0.5 - (0.28 * (1 - pct)) / 2, 0.935, 0.28 * pct, 0.007, 78, 201, 123, 220)
            Wait(0)
        end
        if not cancelled and onFinish then onFinish() end
    end)
    return function() cancelled = true end
end
