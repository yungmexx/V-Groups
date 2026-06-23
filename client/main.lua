local isUiOpen = false
local nearbyPlayers = {}
local groupMembers = {}
local playerNames = {}
local currentLeaderId = nil
local currentLeaderName = nil
local playerStatus = {}
local currentInviterId = nil
local currentGroupId = nil


--  ███████╗██╗░░░██╗███╗░░██╗░█████╗░████████╗██╗░█████╗░███╗░░██╗
--  ██╔════╝██║░░░██║████╗░██║██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
--  █████╗░░██║░░░██║██╔██╗██║██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║
--  ██╔══╝░░██║░░░██║██║╚████║██║░░██╗░░░██║░░░██║██║░░██║██║╚████║
--  ██║░░░░░╚██████╔╝██║░╚███║╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
--  ╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝


local function isInGroup(playerId)
    for _, member in pairs(groupMembers) do
        if member.id == playerId then
            return true
        end
    end
    return false
end


local function updateNearbyPlayers()
    nearbyPlayers = {}
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= myPed then
            local coords = GetEntityCoords(targetPed)
            local distance = #(myCoords - coords)
            if distance <= 10.0 then
                local serverId = GetPlayerServerId(player)
                if not isInGroup(serverId) then
                    local inviteState = playerStatus[serverId] or "invite"
                    if not playerNames[serverId] then
                        TriggerServerEvent("group:server:getNearbyName", serverId)
                    end
                    local name = playerNames[serverId] or GetPlayerName(player) or ("ID: " .. serverId)
                    local data = {
                        id = serverId,
                        name = name or "Unknown",
                        distance = math.floor(distance * 10) / 10,
                        status = inviteState or nil
                    }
                    table.insert(nearbyPlayers, data)
                end
            end
        end
    end
    SendNUIMessage({
        action = "setNearbyPlayers",
        players = nearbyPlayers
    })
end

local function toggleGroupUi(state)
    if state ~= nil then
        isUiOpen = state
    else
        isUiOpen = not isUiOpen
    end
    SetNuiFocus(isUiOpen, isUiOpen)
    SendNUIMessage({
        action = "toggle",
        state = isUiOpen
    })
    CreateThread(function()
        while isUiOpen do
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                if ped ~= myPed then
                    local coords = GetEntityCoords(ped)
                    local distance = #(myCoords - coords)
                    if distance <= 10.0 then
                        local serverId = GetPlayerServerId(player)
                        DrawText3D(coords.x, coords.y, coords.z + 1.0, tostring(serverId))
                    end
                end
            end
            Wait(0)
        end
    end)
    if isUiOpen then
        playerStatus = {}
        TriggerServerEvent("group:server:requestAllNames")
        TriggerServerEvent("group:server:requestGroup")
        SendNUIMessage({
            action = "setMyId",
            id = GetPlayerServerId(PlayerId())
        })
        Wait(100)
        updateNearbyPlayers()
    end
end



--  ███╗░░██╗██╗░░░██╗██╗  ░█████╗░░█████╗░██╗░░░░░██╗░░░░░██████╗░░█████╗░░█████╗░██╗░░██╗
--  ████╗░██║██║░░░██║██║  ██╔══██╗██╔══██╗██║░░░░░██║░░░░░██╔══██╗██╔══██╗██╔══██╗██║░██╔╝
--  ██╔██╗██║██║░░░██║██║  ██║░░╚═╝███████║██║░░░░░██║░░░░░██████╦╝███████║██║░░╚═╝█████═╝░
--  ██║╚████║██║░░░██║██║  ██║░░██╗██╔══██║██║░░░░░██║░░░░░██╔══██╗██╔══██║██║░░██╗██╔═██╗░
--  ██║░╚███║╚██████╔╝██║  ╚█████╔╝██║░░██║███████╗███████╗██████╦╝██║░░██║╚█████╔╝██║░╚██╗
--  ╚═╝░░╚══╝░╚═════╝░╚═╝  ░╚════╝░╚═╝░░╚═╝╚══════╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝

RegisterNUICallback("close", function(_, cb)
    isUiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "toggle",
        state = false
    })
    cb("ok")
end)

RegisterNUICallback("invitePlayer", function(data, cb)
    local playerId = data.playerId
    TriggerServerEvent("group:server:invitePlayer", playerId)
    cb("ok")
end)


RegisterNUICallback("acceptInvite", function(data, cb)
    if not isUiOpen then
        SetNuiFocus(false, false)
    end
    TriggerServerEvent("group:server:acceptInvite", data.groupId)
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
    end
    SendNUIMessage({
        action = "hideInvite"
    })
    
    currentInviteGroup = nil
    currentInviterId = nil
    TriggerEvent('v-garbage:client:SendNotification', 'You have declined the invite', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
    cb("ok")
end)

RegisterNUICallback("leaveGroup", function(data, cb)
    TriggerServerEvent("group:server:leaveGroup", data.playerId)
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
    TriggerEvent('v-garbage:client:SendNotification', 'You have received an invite', 'success', 'bottom', '#141517', '#C1C2C5', 'check', 'green')
end)


RegisterNetEvent("group:client:updateGroup")
AddEventHandler("group:client:updateGroup", function(groupId, groupData, leaderId, leaderName)
    local myId = GetPlayerServerId(PlayerId())
    if not leaderId then
        leaderId = myId
        leaderName = GetPlayerName(PlayerId())
    end
    groupMembers = groupData or {}
    currentLeaderId = leaderId
    currentLeaderName = leaderName
    currentGroupId = groupId
    SendNUIMessage({
        action = "setGroupMembers",
        members = groupMembers,
        leader = currentLeaderId,
        leaderName = currentLeaderName
    })
    updateNearbyPlayers()
end)

RegisterNetEvent("group:client:inviteStatus", function(playerId, status)
    print(playerStatus[playerId])
    print(status)
    if not status then
        playerStatus[playerId] = nil
    else
        playerStatus[playerId] = status
    end
    updateNearbyPlayers()
end)

RegisterNetEvent("group:client:leftGroup", function()
    groupMembers = {}
    groupLeaderId = nil
    currentLeaderId = nil
    currentLeaderName = nil
    SendNUIMessage({
        action = "setGroupMembers",
        members = {},
        leader = nil,
        leaderName = nil
    })
    currentGroupId = nil
    TriggerServerEvent("group:server:requestAllNames")
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
    groupMembers = {}
    groupLeaderId = nil
    currentLeaderId = nil
    currentLeaderName = nil
    SendNUIMessage({
        action = "setGroupMembers",
        members = {},
        leader = nil,
        leaderName = nil
    })
    currentGroupId = nil
    TriggerServerEvent("group:server:requestAllNames")
    TriggerServerEvent("group:server:requestGroup")
    SendNUIMessage({
        action = "setMyId",
        id = GetPlayerServerId(PlayerId())
    })
    Wait(100)
    updateNearbyPlayers()
end)


RegisterNetEvent("group:client:receiveAllNames", function(data)
    playerNames = data
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
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if isUiOpen then
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                if ped ~= myPed then
                    local coords = GetEntityCoords(ped)
                    local distance = #(myCoords - coords)
                    if distance <= 10.0 then
                        local serverId = GetPlayerServerId(player)
                        DrawText3D(coords.x, coords.y, coords.z + 1.0, tostring(serverId))
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)


CreateThread(function()
    Wait(1000)
    TriggerServerEvent("group:server:requestGroup")
    SendNUIMessage({
        action = "setMyId",
        id = GetPlayerServerId(PlayerId())
    })
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    TriggerServerEvent("group:server:requestGroup")
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    groupMembers = {}
    currentGroupId = nil
    currentLeaderId = nil
    currentLeaderName = nil
    playerStatus = {}

    SendNUIMessage({
        action = "setGroupMembers",
        members = {},
        leader = nil,
        leaderName = nil
    })
end)


--  ░█████╗░░█████╗░███╗░░░███╗███╗░░░███╗░█████╗░███╗░░██╗██████╗░
--  ██╔══██╗██╔══██╗████╗░████║████╗░████║██╔══██╗████╗░██║██╔══██╗
--  ██║░░╚═╝██║░░██║██╔████╔██║██╔████╔██║███████║██╔██╗██║██║░░██║
--  ██║░░██╗██║░░██║██║╚██╔╝██║██║╚██╔╝██║██╔══██║██║╚████║██║░░██║
--  ╚█████╔╝╚█████╔╝██║░╚═╝░██║██║░╚═╝░██║██║░░██║██║░╚███║██████╔╝
--  ░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

RegisterCommand("group", function()
    toggleGroupUi(true)
end)


--  ███████╗██╗░░██╗██████╗░░█████╗░██████╗░████████╗░██████╗
--  ██╔════╝╚██╗██╔╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
--  █████╗░░░╚███╔╝░██████╔╝██║░░██║██████╔╝░░░██║░░░╚█████╗░
--  ██╔══╝░░░██╔██╗░██╔═══╝░██║░░██║██╔══██╗░░░██║░░░░╚═══██╗
--  ███████╗██╔╝╚██╗██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██████╔╝
--  ╚══════╝╚═╝░░╚═╝╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═════╝░

exports('GetGroupID', function()
    return currentGroupId
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
exports('OpenGroup', function(state)
    toggleGroupUi(state)
end)

-- Get my current group data
exports('GetCurrentGroupData', function()
    return {
        members = groupMembers,
        leaderId = currentLeaderId,
        leaderName = currentLeaderName
    }
end)
