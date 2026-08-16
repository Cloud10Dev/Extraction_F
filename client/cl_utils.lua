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

function CUtils.Draw3DText(coords, text)
    SetDrawOrigin(coords.x, coords.y, coords.z + 1.0, 0)
    SetTextScale(0.0, 0.35)
    SetTextFont(0)
    SetTextColour(255,255,255,215)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.0,0.0)
    ClearDrawOrigin()
end

function CUtils.ProgressBar(duration, label, onFinish, onCancel)
    local cancelled = false
    CreateThread(function()
        local startTime = GetGameTimer()
        while GetGameTimer() - startTime < (duration * 1000) do
            if cancelled then if onCancel then onCancel() end return end
            local pct = (GetGameTimer() - startTime) / (duration * 1000)
            DrawRect(0.5, 0.92, 0.3, 0.025, 0, 0, 0, 180)
            DrawRect(0.5 - (0.3 * (1 - pct)) / 2, 0.92, 0.3 * pct, 0.025, 0, 180, 80, 220)
            SetTextFont(4)
            SetTextScale(0.4, 0.4)
            SetTextColour(255,255,255,255)
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(label)
            DrawText(0.5, 0.905)
            Wait(0)
        end
        if not cancelled and onFinish then onFinish() end
    end)
    return function() cancelled = true end
end
