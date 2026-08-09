local isUiOpen = false
local nearbyPlayers = {}
local nearbyCache = {}
local activeIds = {}
local groupMembers = {}
local playerNames = {}
local currentLeaderId = nil


local currentLeaderName = nil
local playerStatus = {}
local currentInviterId = nil
local currentGroupId = nil
local cursorActive = true



--  ███████╗██╗░░░██╗███╗░░██╗░█████╗░████████╗██╗░█████╗░███╗░░██╗
--  ██╔════╝██║░░░██║████╗░██║██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
--  █████╗░░██║░░░██║██╔██╗██║██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║
--  ██╔══╝░░██║░░░██║██║╚████║██║░░██╗░░░██║░░░██║██║░░██║██║╚████║
--  ██║░░░░░╚██████╔╝██║░╚███║╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
--  ╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextEntry("STRING")
        AddTextComponentString(text)
        SetTextScale(0.55, 0.55)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        SetTextCentre(true)
        DrawText(_x, _y)
    end
end

local function isInGroup(playerId)
    for _, member in pairs(groupMembers) do
        if member.id == playerId then
            return true
        end
    end
    return false
end


local function clearTable(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

local function updateNearbyPlayers()
    clearTable(nearbyPlayers)
    clearTable(nearbyCache)
    clearTable(activeIds)
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    for _, player in ipairs(GetActivePlayers()) do
        local serverId = GetPlayerServerId(player)
        activeIds[serverId] = true
        local targetPed = GetPlayerPed(player)
        if targetPed ~= myPed then
            local coords = GetEntityCoords(targetPed)
            local dx, dy, dz = coords.x - myCoords.x, coords.y - myCoords.y, coords.z - myCoords.z
            local distSq = dx * dx + dy * dy + dz * dz
            if distSq <= 100.0 then
                nearbyCache[#nearbyCache + 1] = { ped = targetPed, id = serverId }
                if not isInGroup(serverId) then
                    local inviteState = playerStatus[serverId] or "invite"
                    if not playerNames[serverId] then
                        TriggerServerEvent("group:server:getNearbyName", serverId)
                    end
                    local name = playerNames[serverId] or GetPlayerName(player) or ("ID: " .. serverId)
                    local data = {
                        id = serverId,
                        name = name or "Unknown",
                        distance = math.floor(math.sqrt(distSq) * 10) / 10,
                        status = inviteState or nil
                    }
                    table.insert(nearbyPlayers, data)
                end
            end
        end
    end

    for id in pairs(playerNames) do
        if not activeIds[id] then playerNames[id] = nil end
    end
    for id in pairs(playerStatus) do
        if not activeIds[id] then playerStatus[id] = nil end
    end

    SendNUIMessage({
        action = "setNearbyPlayers",
        players = nearbyPlayers
    })
end

local function toggleGroup()
    isUiOpen = not isUiOpen
    cursorActive = true
    SetNuiFocus(isUiOpen, isUiOpen)
    SendNUIMessage({
        action = "toggle",
        state = isUiOpen
    })
    if isUiOpen then
        TriggerServerEvent("group:server:requestGroup")
        SendNUIMessage({
            action = "setMyId",
            id = GetPlayerServerId(PlayerId())
        })
        Wait(100)
        updateNearbyPlayers()
    else
        collectgarbage("collect")
    end
end


local function resetInvites()
    playerStatus = {}
end



--  ███╗░░██╗██╗░░░██╗██╗  ░█████╗░░█████╗░██╗░░░░░██╗░░░░░██████╗░░█████╗░░█████╗░██╗░░██╗
--  ████╗░██║██║░░░██║██║  ██╔══██╗██╔══██╗██║░░░░░██║░░░░░██╔══██╗██╔══██╗██╔══██╗██║░██╔╝
--  ██╔██╗██║██║░░░██║██║  ██║░░╚═╝███████║██║░░░░░██║░░░░░██████╦╝███████║██║░░╚═╝█████═╝░
--  ██║╚████║██║░░░██║██║  ██║░░██╗██╔══██║██║░░░░░██║░░░░░██╔══██╗██╔══██║██║░░██╗██╔═██╗░
--  ██║░╚███║╚██████╔╝██║  ╚█████╔╝██║░░██║███████╗███████╗██████╦╝██║░░██║╚█████╔╝██║░╚██╗
--  ╚═╝░░╚══╝░╚═════╝░╚═╝  ░╚════╝░╚═╝░░╚═╝╚══════╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝

RegisterNUICallback("close", function(_, cb)
    isUiOpen = false
    cursorActive = true
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "toggle",
        state = false
    })
    collectgarbage("collect")
    cb("ok")
end)

RegisterNUICallback("toggleMouse", function(_, cb)
    if isUiOpen then
        cursorActive = not cursorActive
        SetNuiFocus(true, cursorActive)
    end
    cb("ok")
end)

RegisterNUICallback("invitePlayer", function(data, cb)
    local playerId = data.playerId

    TriggerServerEvent(
        "group:server:invitePlayer",
        playerId
    )

    cb("ok")
end)


RegisterNUICallback("acceptInvite", function(data, cb)
    if not isUiOpen then
        SetNuiFocus(false, false)
    end

    TriggerServerEvent(
        "group:server:acceptInvite",
        data.groupId
    )

    SendNUIMessage({
        action = "hideInvite"
    })

    cb("ok")
end)


RegisterNUICallback("declineInvite", function(data, cb)
    if not isUiOpen then
        SetNuiFocus(false, false)
    end

    if currentInviterId then
        TriggerServerEvent(
            "group:server:declineInvite",
            currentInviterId
        )
        TriggerEvent('v-groups:client:SendNotification', 'You have declined the invite', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
    end

    SendNUIMessage({
        action = "hideInvite"
    })

    currentInviteGroup = nil
    currentInviterId = nil
    cb("ok")
end)

RegisterNUICallback("leaveGroup", function(data, cb)
    TriggerServerEvent("group:server:leaveGroup")
    cb("ok")
end)

RegisterNUICallback("kickPlayer", function(data, cb)
    TriggerServerEvent("group:server:kickPlayer", data.playerId)
    cb("ok")
end)


--  ███╗░░██╗███████╗████████╗  ███████╗██╗░░░██╗███████╗███╗░░██╗████████╗
--  ████╗░██║██╔════╝╚══██╔══╝  ██╔════╝██║░░░██║██╔════╝████╗░██║╚══██╔══╝
--  ██╔██╗██║█████╗░░░░░██║░░░  █████╗░░╚██╗░██╔╝█████╗░░██╔██╗██║░░░██║░░░
--  ██║╚████║██╔══╝░░░░░██║░░░  ██╔══╝░░░╚████╔╝░██╔══╝░░██║╚████║░░░██║░░░
--  ██║░╚███║███████╗░░░██║░░░  ███████╗░░╚██╔╝░░███████╗██║░╚███║░░░██║░░░
--  ╚═╝░░╚══╝╚══════╝░░░╚═╝░░░  ╚══════╝░░░╚═╝░░░╚══════╝╚═╝░░╚══╝░░░╚═╝░░░

RegisterNetEvent("group:client:receiveInvite", function(fromName, groupId, inviterId)
    currentInviteGroup = groupId
    currentInviterId = inviterId

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "showInvite",
        fromName = fromName,
        groupId = groupId
    })

    TriggerEvent('v-groups:client:SendNotification', 'You have received an invite', 'success', 'bottom', '#141517', '#C1C2C5', 'check', 'green')
end)


RegisterNetEvent("group:client:updateGroup")
AddEventHandler("group:client:updateGroup", function(groupData, leaderId, leaderName, maxSize, groupId)
    local myId = GetPlayerServerId(PlayerId())
    if not leaderId then
        leaderId = myId
        leaderName = GetPlayerName(PlayerId())
    end
    groupMembers = groupData or {}
    currentLeaderId = leaderId
    currentLeaderName = leaderName
    currentGroupId = groupId or currentGroupId
    SendNUIMessage({
        action = "setGroupMembers",
        members = groupMembers,
        leader = currentLeaderId,
        leaderName = currentLeaderName,
        maxSize = maxSize
    })
    updateNearbyPlayers()
end)

RegisterNetEvent("group:client:inviteStatus", function(playerId, status)
    if not status then
        playerStatus[playerId] = nil
    else
        playerStatus[playerId] = status
    end
    updateNearbyPlayers()
end)

RegisterNetEvent("group:client:leftGroup", function()
    resetInvites()
    groupMembers = {}
    groupLeaderId = nil
    currentLeaderId = nil
    currentLeaderName = nil
    currentGroupId = nil
    SendNUIMessage({
        action = "setGroupMembers",
        members = {},
        leader = nil,
        leaderName = nil
    })
    TriggerServerEvent("group:server:requestGroup")
    SendNUIMessage({
        action = "setMyId",
        id = GetPlayerServerId(PlayerId())
    })
    Wait(100)
    updateNearbyPlayers()
end)


RegisterNetEvent("group:client:receiveNearbyName", function(playerId, name)
    playerNames[playerId] = name
end)


RegisterNetEvent("group:client:kicked", function()
    resetInvites()
    groupMembers = {}
    groupLeaderId = nil
    currentLeaderId = nil
    currentLeaderName = nil
    currentGroupId = nil
    SendNUIMessage({
        action = "setGroupMembers",
        members = {},
        leader = nil,
        leaderName = nil
    })
    TriggerServerEvent("group:server:requestGroup")
    SendNUIMessage({
        action = "setMyId",
        id = GetPlayerServerId(PlayerId())
    })
    Wait(100)
    updateNearbyPlayers()
end)




--  ░█████╗░██████╗░███████╗░█████╗░████████╗███████╗  ████████╗██╗░░██╗██████╗░███████╗░█████╗░██████╗░
--  ██╔══██╗██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔════╝  ╚══██╔══╝██║░░██║██╔══██╗██╔════╝██╔══██╗██╔══██╗
--  ██║░░╚═╝██████╔╝█████╗░░███████║░░░██║░░░█████╗░░  ░░░██║░░░███████║██████╔╝█████╗░░███████║██║░░██║
--  ██║░░██╗██╔══██╗██╔══╝░░██╔══██║░░░██║░░░██╔══╝░░  ░░░██║░░░██╔══██║██╔══██╗██╔══╝░░██╔══██║██║░░██║
--  ╚█████╔╝██║░░██║███████╗██║░░██║░░░██║░░░███████╗  ░░░██║░░░██║░░██║██║░░██║███████╗██║░░██║██████╔╝
--  ░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝  ░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═════╝░

CreateThread(function()
    while true do
        if isUiOpen then
            updateNearbyPlayers()
            Wait(1000)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if isUiOpen then
            if #nearbyCache > 0 then
                for _, entry in ipairs(nearbyCache) do
                    if DoesEntityExist(entry.ped) then
                        local coords = GetEntityCoords(entry.ped)
                        DrawText3D(coords.x, coords.y, coords.z + 1.0, tostring(entry.id))
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)



RegisterNetEvent("v-groups:client:SendNotification")
AddEventHandler("v-groups:client:SendNotification", function(description, type, position, backgroundColor, color, icon, iconColor)
    SendNotification(description, type, position, backgroundColor, color, icon, iconColor)
end)


--  ░█████╗░░█████╗░███╗░░░███╗███╗░░░███╗░█████╗░███╗░░██╗██████╗░
--  ██╔══██╗██╔══██╗████╗░████║████╗░████║██╔══██╗████╗░██║██╔══██╗
--  ██║░░╚═╝██║░░██║██╔████╔██║██╔████╔██║███████║██╔██╗██║██║░░██║
--  ██║░░██╗██║░░██║██║╚██╔╝██║██║╚██╔╝██║██╔══██║██║╚████║██║░░██║
--  ╚█████╔╝╚█████╔╝██║░╚═╝░██║██║░╚═╝░██║██║░░██║██║░╚███║██████╔╝
--  ░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

RegisterCommand("groups", function()
    toggleGroup()
end)


-- Get full group members table
exports('GetGroupMembers', function()
    return groupMembers
end)

-- Get leader server id
exports('GetGroupLeader', function()
    return currentLeaderId
end)

-- Get leader name
exports('GetGroupLeaderName', function()
    return currentLeaderName
end)

-- Get the current group's unique id
exports('GetGroupID', function()
    return currentGroupId
end)

-- Check if local player is leader
exports('IsGroupLeader', function()
    return GetPlayerServerId(PlayerId()) == currentLeaderId
end)

-- Check if a player is in your group
exports('IsPlayerInGroup', function(playerId)
    return isInGroup(playerId)
end)

-- Get group size
exports('GetGroupSize', function()
    return #groupMembers
end)

-- Get nearby players
exports('GetNearbyGroupPlayers', function()
    return nearbyPlayers
end)

-- Get invite/player statuses
exports('GetPlayerStatuses', function()
    return playerStatus
end)

-- Check if UI is open
exports('IsGroupUiOpen', function()
    return isUiOpen
end)

-- Open/close group UI
exports('ToggleGroupUi', function(state)
    if state ~= nil then
        isUiOpen = state
    else
        isUiOpen = not isUiOpen
    end

    cursorActive = true
    SetNuiFocus(isUiOpen, isUiOpen)

    SendNUIMessage({
        action = "toggle",
        state = isUiOpen
    })

    if isUiOpen then
        TriggerServerEvent("group:server:requestGroup")

        SendNUIMessage({
            action = "setMyId",
            id = GetPlayerServerId(PlayerId())
        })

        Wait(100)

        updateNearbyPlayers()
    else
        collectgarbage("collect")
    end
end)

-- Force refresh nearby players
exports('RefreshNearbyPlayers', function()
    updateNearbyPlayers()
end)

-- Open the group UI (no-op if already open)
exports('OpenGroup', function()
    if not isUiOpen then
        toggleGroup()
    end
end)

-- Get my current group data
exports('GetCurrentGroupData', function()
    return {
        members = groupMembers,
        leaderId = currentLeaderId,
        leaderName = currentLeaderName
    }
end)
