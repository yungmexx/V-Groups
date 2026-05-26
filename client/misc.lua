
RegisterNetEvent("v-garbage:client:SendNotification")
AddEventHandler("v-garbage:client:SendNotification", function(description, type, position, backgroundColor, color, icon, iconColor)
    SendNotification(description, type, position, backgroundColor, color, icon, iconColor)
end)


function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.55, 0.55)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        SetTextCentre(true)

        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end