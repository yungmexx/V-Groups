
-- PREVIEW
--https://www.youtube.com/watch?v=GFmJNyde7zk&ab_channel=SpMex

Config = Config or {}

-- FRAMEWORK
Config.Framework = 'auto_detect' --  options: 'auto_detect', 'qb', 'qbox'

-- PROGRESSBAR
Config.UseProgressBar = true -- Used for opening crate. Uses qbcore progress bar

-- COMMAND
Config.HintSettingsCommand = "garbsettings"
Config.EndJobCommand = "endgarbagejob"

-- PED
Config.PedInteract = 'auto_detect' --  options: 'auto_detect', 'qb-target', 'ox_target' 'showhelp'

-- GARBAGE
Config.UseDrawMarker = true -- if false it will use 3d text as the ? (personal preference)
Config.GarbageInteract = 'default' --  options: 'auto_detect', 'default', 'qb-target', 'ox_target' 'v-interact' '3dtext'
Config.GarbageDrop = 'default' --  options: 'auto_detect', 'default', 'v-interact' '3dtext'

-- TRUCK BOOT INTERACT (TRUNK)
Config.BootInteract = 'default' --  options: 'auto_detect', 'default', 'qb-target', 'ox_target' '3dtext'

-- TRUCK
Config.TruckInteract = 'default' --  options: 'auto_detect', 'default', 'v-interact' '3dtext'

-- CUSTOM TARGET NAME
Config.CustomTargetName = 'qb-target' -- Custom Target Resource Name (only applies to qb-target)

-- Notification Type
Config.Notification = 'ox' -- Notification type 'auto_detect', 'qb', 'ox', 'gta'(gta notification)

-- FUEL
Config.Fuel = "auto_detect" --  options: 'auto_detect', 'LegacyFuel', 'ps-fuel'

-- INTERACT KEYS
Config.InteractKey = 38 -- E Key
Config.ToggleTrunk = 47 -- G Key

--
-- Recycling
Config.Key = 38 -- E Key to interact
Config.Wait = 10 -- Time in minutes it takes to respawn the materials
--]]

-- How it works--
-- When you drop off an object, 
-- the last two people who touched it get stored. 
-- If either of them held it for at least 5 seconds, they can get paid. 
-- The base payout is $50, but if both players qualify, 
-- a 1.25 Multiplier teamwork bonus is added. and both players get paid
-- $50 + 1.25 = $62.50

--[[
Base Pay: $50

If only 1 player qualifies:
- That player gets the full $50.

If 2 players qualify (teamwork bonus):
- A 1.25 bonus is added → $50 * 1.25 = $62.50 for both players
--]]

-- If you work as a team then you receive a bonus
-- For example if Player 1 picks up an object holds it for (5 seconds) 
-- then drops it and Player 2 carries it to drop it off then theres a team work bonus 

--Config.BaseReward = 50 -- Amount to pay per item thrown in trunk


Config.HoldObjectTime = 5 -- Carry time to count for a bonus
Config.TeamWorkBonus = 1.25 -- Multiplier to give as a bonus for teamwork


Config.Crate = {
    model = 'xm3_prop_xm3_crate_supp_01a',
    animation = {
        dict = 'anim@heists@box_carry@',
        anim = 'idle',
    },
}


Config.VehSpawn = {
    ["vehicle"] = {
        vehicle = 'trash',
        label = "Garbage Truck Storage",
        coords = {
            [1] = vector4(-324.50, -1527.28, 27.28, 1.97),
            [2] = vector4(-327.61, -1527.28, 27.28, 1.97),
            [3] = vector4(-330.66, -1527.28, 27.28, 1.97),
            [4] = vector4(-333.84, -1527.28, 27.28, 1.97),
            [5] = vector4(-329.29, -1519.12, 27.28, 186.93),
            [6] = vector4(-325.81, -1519.12, 27.28, 186.93),
            [7] = vector4(-322.50, -1519.12, 27.28, 186.93),
            [8] = vector4(-319.55, -1519.12, 27.28, 186.93),
        },
    }
}

Config.GarbageUniform = {
    ["male"] = {
        ["tshirt"] = { componentId = 8, drawableId = 59, textureId = 1 }, -- T-shirt under vest
        ["torso"]  = { componentId = 11, drawableId = 57, textureId = 0 }, -- Vest
        ["arms"]   = { componentId = 3, drawableId = 0, textureId = 0 }, -- Arms (default)
        ["pants"]  = { componentId = 4, drawableId = 36, textureId = 0 }, -- Work pants
        ["shoes"]  = { componentId = 6, drawableId = 12, textureId = 0 }, -- Work boots
        ["hat"]    = { componentId = 0, drawableId = 14, textureId = 0 }, -- Optional cap
        ["bag"]    = { componentId = 5, drawableId = 0, textureId = 0 }, -- Optional bag
    },
    ["female"] = {
        ["tshirt"] = { componentId = 8, drawableId = 36, textureId = 1 },
        ["torso"]  = { componentId = 11, drawableId = 50, textureId = 0 },
        ["arms"]   = { componentId = 3, drawableId = 1, textureId = 0 },
        ["pants"]  = { componentId = 4, drawableId = 35, textureId = 0 },
        ["shoes"]  = { componentId = 6, drawableId = 27, textureId = 0 },
        ["hat"]    = { componentId = 0, drawableId = 14, textureId = 0 },
        ["bag"]    = { componentId = 5, drawableId = 0, textureId = 0 },
    }
}


--  ██╗░░██╗██╗███╗░░██╗████████╗░██████╗
--  ██║░░██║██║████╗░██║╚══██╔══╝██╔════╝
--  ███████║██║██╔██╗██║░░░██║░░░╚█████╗░
--  ██╔══██║██║██║╚████║░░░██║░░░░╚═══██╗
--  ██║░░██║██║██║░╚███║░░░██║░░░██████╔╝
--  ╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░░░╚═╝░░░╚═════╝░

Config.Hints = {
    Vehicle = { -- Hints to do with the vehicle
        VehicleOutline = true,  -- Outlines the vehicle once vehicle spawns (stops outline after player has entered vehicle)
        VehicleDrawMarker = true,  -- Draws a marker above the vehicle once vehicle spawns (stops drawing after player has entered vehicle)
        VehicleGamePlayHint = true,  -- Sets gameplay camera hint on vehicle once vehicle spawns (stops  gameplay cam hint after 5 seconds)
    },
    Items = { -- Hints to do with the spawned props
        ItemsOutline = true, -- Outlines items that are spawned once in range (helpful for finding items)
    },
    Objective = { -- Hints to do with the spawned props
        ObjectiveHints = true, -- Outlines items that are spawned once in range (helpful for finding items)
    },
}




--  ███╗░░██╗░█████╗░████████╗██╗███████╗██╗░█████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
--  ████╗░██║██╔══██╗╚══██╔══╝██║██╔════╝██║██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
--  ██╔██╗██║██║░░██║░░░██║░░░██║█████╗░░██║██║░░╚═╝███████║░░░██║░░░██║██║░░██║██╔██╗██║
--  ██║╚████║██║░░██║░░░██║░░░██║██╔══╝░░██║██║░░██╗██╔══██║░░░██║░░░██║██║░░██║██║╚████║
--  ██║░╚███║╚█████╔╝░░░██║░░░██║██║░░░░░██║╚█████╔╝██║░░██║░░░██║░░░██║╚█████╔╝██║░╚███║
--  ╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝╚═╝░░░░░╚═╝░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝

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


--  ███████╗██╗░░░██╗███████╗██╗░░░░░
--  ██╔════╝██║░░░██║██╔════╝██║░░░░░
--  █████╗░░██║░░░██║█████╗░░██║░░░░░
--  ██╔══╝░░██║░░░██║██╔══╝░░██║░░░░░
--  ██║░░░░░╚██████╔╝███████╗███████╗
--  ╚═╝░░░░░░╚═════╝░╚══════╝╚══════╝

function SetVehicleFuel(veh)
    local fuel = 100.0
    if Config.Fuel == 'ox_fuel' then
        Entity(veh).state.fuel = fuel
    elseif Config.Fuel == 'ndfuel' then
        exports[Config.Fuel]:SetFuel(veh, fuel)
    elseif Config.Fuel == 'ps-fuel' then
        exports[Config.Fuel]:SetFuel(veh, fuel)
    elseif Config.Fuel == 'LegacyFuel' then
        exports["LegacyFuel"]:SetFuel(veh, fuel)
    else
        exports[Config.Fuel]:SetFuel(veh, fuel)
    end
end



--  ██╗░░██╗███████╗██╗░░░██╗░██████╗
--  ██║░██╔╝██╔════╝╚██╗░██╔╝██╔════╝
--  █████═╝░█████╗░░░╚████╔╝░╚█████╗░
--  ██╔═██╗░██╔══╝░░░░╚██╔╝░░░╚═══██╗
--  ██║░╚██╗███████╗░░░██║░░░██████╔╝
--  ╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═════╝░

function GiveCarKeys(veh)
    TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(veh))
end