Config = Config or {}

-- Notifications
-- Options: 'qb', 'ox', 'gta'
Config.Notification = 'gta'


function SendNotification(description, type, position, backgroundColor, color, icon, iconColor)
    if Config.Notification == "qb" then
        if type == 'info' then
            type = 'primary'
        end
        local QBCore = exports["qb-core"]:GetCoreObject()
        QBCore.Functions.Notify(description, type)
    elseif Config.Notification == "ox" then
        lib.notify({
            description = description,
            position = position,
            duration = 5000,
            style = {
                backgroundColor = backgroundColor,
                color = color,
                [".description"] = {
                color = "#909296"
                }
            },
            icon = icon,
            iconColor = iconColor
        })
    else
        ShowNotification(description)
    end
end
