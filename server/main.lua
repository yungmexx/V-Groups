local QBCore = exports['qb-core']:GetCoreObject()
local groups = {}
local playerGroup = {}
local invitedPlayers = {}


-- Sync Group
local function syncGroup(groupId, group)
    if not group or #group == 0 then return end
    local leaderId = group[1].id
    for _, v in ipairs(group) do
        if playerGroup[v.id] == groupId then
            leaderId = group[1].id
            break
        end
    end
    local Player = QBCore.Functions.GetPlayer(leaderId)
    local leaderName = Player and(Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname) or GetPlayerName(leaderId)
    local formatted = {}
    for _, v in ipairs(group) do
        table.insert(formatted, {
            id = v.id,
            name = v.name,
            leader = (v.id == leaderId)
        })
    end
    for _, member in ipairs(group) do
        playerGroup[member.id] = groupId
        TriggerClientEvent("group:client:updateGroup", member.id, groupId, formatted, leaderId, leaderName)
    end
end


-- Invite Player
RegisterNetEvent("group:server:invitePlayer", function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local charinfo = Player.PlayerData.charinfo
    local fullName = charinfo.firstname .. " " .. charinfo.lastname
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    local targetfullName = "a player"
    if targetPlayer then
        local tcharinfo = targetPlayer.PlayerData.charinfo
        targetfullName = tcharinfo.firstname .. " " .. tcharinfo.lastname
    end
    if not playerGroup[src] then
        playerGroup[src] = src
        groups[src] = {
            { id = src, name = fullName }
        }
    end
    invitedPlayers[targetId] = "invited"
    TriggerClientEvent('v-garbage:client:SendNotification', src, 'You have invited '.. targetfullName, 'success', 'bottom', '#141517', '#C1C2C5', 'check', 'green')
    TriggerClientEvent("group:client:receiveInvite", targetId, fullName, playerGroup[src], src)
    TriggerClientEvent("group:client:inviteStatus", src, targetId, "invited")
   -- TriggerClientEvent("group:client:inviteStatus", targetId, src, "invited")
end)

-- Accept Invite
RegisterNetEvent("group:server:acceptInvite", function(targetId)
    local src = source
    if not groups[targetId] then
        groups[targetId] = {}
    end
    playerGroup[src] = targetId
    local Player = QBCore.Functions.GetPlayer(src)
    local charinfo = Player.PlayerData.charinfo
    local fullName = charinfo.firstname .. " " .. charinfo.lastname
    table.insert(groups[targetId], {
        id = src,
        name = fullName
    })
    local group = groups[targetId]
    local leaderId = group[1].id
    invitedPlayers[src] = nil
    syncGroup(targetId, group)
    local targetPlayer = QBCore.Functions.GetPlayer(src)
    local targetfullName = "Player"
    if targetPlayer then
        local tcharinfo = targetPlayer.PlayerData.charinfo
        targetfullName = tcharinfo.firstname .. " " .. tcharinfo.lastname
    end
    TriggerClientEvent('groups:client:joinGroup', src, targetId, group)
    TriggerClientEvent('v-garbage:client:SendNotification', targetId, targetfullName .. ' has joined the group', 'success', 'bottom', '#141517', '#C1C2C5', 'check', 'green')
    TriggerClientEvent('v-garbage:client:SendNotification', src, 'You have joined the group', 'success', 'bottom', '#141517', '#C1C2C5', 'check', 'green')
end)

-- Decline Invite
RegisterNetEvent("group:server:declineInvite", function(inviterId)
    local src = source
    invitedPlayers[src] = nil
    TriggerClientEvent("group:client:inviteStatus", inviterId, src, "invite")
    TriggerClientEvent("group:client:inviteStatus", src, inviterId, "invite")
    local targetPlayer = QBCore.Functions.GetPlayer(src)
    local targetfullName = "Player"
    if targetPlayer then
        local tcharinfo = targetPlayer.PlayerData.charinfo
        targetfullName = tcharinfo.firstname .. " " .. tcharinfo.lastname
    end
    TriggerClientEvent('v-garbage:client:SendNotification', inviterId, targetfullName .. ' declined invitation', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
end)

-- Set Invite Status
RegisterNetEvent("group:server:inviteStatus", function(targetId, status)
    local src = source
    TriggerClientEvent( "group:client:inviteStatus", src, targetId, status)
    TriggerClientEvent("group:client:inviteStatus", targetId, src, status)
end)

-- Kick Player
RegisterNetEvent("group:server:kickPlayer", function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(targetId)
    local charinfo = Player.PlayerData.charinfo
    local fullName = charinfo.firstname .. " " .. charinfo.lastname
    local groupId = playerGroup[src]
    if not groupId then return end
    local group = groups[groupId]
    if not group then return end
    local leaderId = group[1].id
    if src ~= leaderId then return end
    for i = #group, 1, -1 do
        if group[i].id == targetId then
            table.remove(group, i)
            break
        end
    end
    TriggerClientEvent('group:client:inviteStatus', src, targetId, 'invite')
    TriggerClientEvent("group:client:kicked", targetId)
    invitedPlayers[src] = nil
    playerGroup[targetId] = nil
    syncGroup(groupId, group)
    local Player = QBCore.Functions.GetPlayer(src)
    local fullName = "Host"
    if Player then
        local tcharinfo = Player.PlayerData.charinfo
        fullName = tcharinfo.firstname .. " " .. tcharinfo.lastname
    end
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    local targetfullName = "Player"
    if targetPlayer then
        local tcharinfo = targetPlayer.PlayerData.charinfo
        targetfullName = tcharinfo.firstname .. " " .. tcharinfo.lastname
    end
    TriggerEvent("group:server:memberRemoved", targetId)
    TriggerClientEvent("group:client:memberRemoved", targetId)

    TriggerClientEvent('v-garbage:client:SendNotification', targetId, fullName .. ' has kicked you from the group', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
    TriggerClientEvent('v-garbage:client:SendNotification', src, 'You have kicked ' .. targetfullName ..' from the group', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
end)

-- Leave Group
RegisterNetEvent("group:server:leaveGroup", function(targetId)
    local src = source
    local groupId = playerGroup[src]
    if not groupId then return end
    local group = groups[groupId]
    if not group then return end


    for i = #group, 1, -1 do
        if group[i].id == src then
            table.remove(group, i)
            break
        end
    end
    playerGroup[src] = nil


    if #group == 0 then
        groups[groupId] = nil
        return
    end
    local newLeaderId = group[1].id
    local formatted = {}
    for _, v in ipairs(group) do
        table.insert(formatted, {
            id = v.id,
            name = v.name,
            leader = (v.id == newLeaderId)
        })
    end
    groups[groupId] = group
    for _, member in ipairs(group) do
        playerGroup[member.id] = groupId
    end
    local Player = QBCore.Functions.GetPlayer(newLeaderId)
    local leaderName = Player and (Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname) or GetPlayerName(newLeaderId)
    local targetPlayer = QBCore.Functions.GetPlayer(src)
    local targetfullName = "Player"
    if targetPlayer then
        local tcharinfo = targetPlayer.PlayerData.charinfo
        targetfullName = tcharinfo.firstname .. " " .. tcharinfo.lastname
    end
    for _, member in ipairs(group) do
        if member.id ~= src then
            TriggerClientEvent("group:client:updateGroup", member.id, groupId, formatted, newLeaderId, leaderName)
        end
        TriggerClientEvent('group:client:inviteStatus', member.id, targetId, 'invite')
    end

    TriggerEvent("group:server:memberRemoved", src)
    TriggerClientEvent("group:client:memberRemoved", src)
    syncGroup(groupId, group)
    TriggerClientEvent("group:client:leftGroup", src)
    invitedPlayers[src] = nil
    TriggerClientEvent('v-garbage:client:SendNotification', src, 'You have left the group', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
end)

-- Request All Names
RegisterNetEvent("group:server:requestAllNames", function()
    local src = source
    local result = {}
    for _, playerId in ipairs(GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        if Player then
            local charinfo = Player.PlayerData.charinfo
            result[tonumber(playerId)] = charinfo.firstname .. " " .. charinfo.lastname
        else
            result[tonumber(playerId)] = GetPlayerName(playerId)
        end
    end
    TriggerClientEvent("group:client:receiveAllNames", src, result)
end)


-- Get Nearby Name
RegisterNetEvent("group:server:getNearbyName", function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(targetId)
    if not Player then return end
    local charinfo = Player.PlayerData.charinfo
    local fullName = charinfo.firstname .. " " .. charinfo.lastname
    TriggerClientEvent("group:client:receiveNearbyName", src, targetId, fullName)
end)

-- Request Group
RegisterNetEvent("group:server:requestGroup", function()
    local src = source
    local groupId = playerGroup[src] or src
    local group = groups[groupId]
    if not group or #group == 0 then
        group = {
            { id = src, name = GetPlayerName(src) or "Unknown" }
        }
        groups[groupId] = group
        playerGroup[src] = groupId
    end
    local leaderId = group[1] and group[1].id
    for _, v in ipairs(group) do
        playerGroup[v.id] = groupId
    end
    local Player = QBCore.Functions.GetPlayer(leaderId)
    local leaderName = "Unknown"
    if Player then
        local c = Player.PlayerData.charinfo
        leaderName = (c.firstname or "Unknown") .. " " .. (c.lastname or "")
    else
        leaderName = GetPlayerName(leaderId) or "Unknown"
    end
    local formatted = {}
    for _, v in ipairs(group) do
        table.insert(formatted, {
            id = v.id,
            name = v.name or GetPlayerName(v.id) or "Unknown",
            leader = (v.id == leaderId)
        })
    end
    TriggerClientEvent("group:client:updateGroup", src, groupId, formatted, leaderId, leaderName)
end)



RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    print('test')
    local groupId = playerGroup[src]
    if not groupId then return end

    local group = groups[groupId]
    if not group then return end

    -- remove player from group
    for i = #group, 1, -1 do
        if group[i].id == src then
            table.remove(group, i)
            break
        end
    end

    playerGroup[src] = nil

    TriggerEvent("group:server:memberRemoved", src)
    TriggerClientEvent("group:client:memberRemoved", src)


    invitedPlayers[src] = nil

    -- delete group if empty
    if #group == 0 then
        groups[groupId] = nil
        return
    end

    -- reassign leader
    local newLeaderId = group[1].id

    local formatted = {}
    for _, v in ipairs(group) do
        formatted[#formatted + 1] = {
            id = v.id,
            name = v.name,
            leader = (v.id == newLeaderId)
        }
    end

    groups[groupId] = group

    for _, member in ipairs(group) do
        playerGroup[member.id] = groupId
    end

    local Player = QBCore.Functions.GetPlayer(newLeaderId)
    local leaderName = Player and (
        Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    ) or GetPlayerName(newLeaderId)

    for _, member in ipairs(group) do
        TriggerClientEvent("group:client:updateGroup", member.id, groupId, formatted, newLeaderId, leaderName)
    end
end)


AddEventHandler('playerDropped', function(reason)
    print('test')
    local src = source
    local groupId = playerGroup[src]
    if not groupId then return end
    local group = groups[groupId]
    if not group then return end
    for i = #group, 1, -1 do
        if group[i].id == src then
            table.remove(group, i)
            break
        end
    end
    playerGroup[src] = nil
    TriggerEvent("group:server:memberRemoved", src)
    TriggerClientEvent("group:client:memberRemoved", src)
    invitedPlayers[src] = nil
    -- if group is empty → delete it
    if #group == 0 then
        groups[groupId] = nil
        return
    end

    -- if leader left → new leader is first member
    local newLeaderId = group[1].id

    local formatted = {}
    for _, v in ipairs(group) do
        table.insert(formatted, {
            id = v.id,
            name = v.name,
            leader = (v.id == newLeaderId)
        })
    end

    groups[groupId] = group

    -- re-map playerGroup
    for _, member in ipairs(group) do
        playerGroup[member.id] = groupId
    end

    local Player = QBCore.Functions.GetPlayer(newLeaderId)
    local leaderName = Player and (
        Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    ) or GetPlayerName(newLeaderId)

    -- sync remaining members
    for _, member in ipairs(group) do
        TriggerClientEvent("group:client:updateGroup", member.id, groupId, formatted, newLeaderId, leaderName)
    end
end)


-- Get all groups
exports('GetGroups', function()
    return groups
end)

-- Get a player's group id
exports('GetPlayerGroup', function(playerId)
    return playerGroup[playerId]
end)

-- Get full group table
exports('GetGroupMembers', function(groupId)
    groupId = groupId or playerGroup[source]

    if not groupId then
        return {}
    end

    local group = groups[groupId]
    if not group then
        return {}
    end

    local members = {}

    for _, member in ipairs(group) do
        -- supports either format just in case
        if type(member) == "number" then
            members[#members + 1] = member
        elseif type(member) == "table" and member.id then
            members[#members + 1] = member.id
        end
    end

    return members
end)

-- Get leader id
exports('GetGroupLeader', function(groupId)
    local group = groups[groupId]

    if not group or not group[1] then
        return nil
    end

    return group[1].id
end)

-- Get leader name
exports('GetGroupLeaderName', function(groupId)
    local leaderId = exports[GetCurrentResourceName()]:GetGroupLeader(groupId)

    if not leaderId then
        return nil
    end

    local Player = QBCore.Functions.GetPlayer(leaderId)

    if Player then
        local c = Player.PlayerData.charinfo
        return c.firstname .. " " .. c.lastname
    end

    return GetPlayerName(leaderId)
end)

-- Check if player is in group
exports('IsPlayerInGroup', function(playerId)
    return playerGroup[playerId] ~= nil
end)

-- Check if player is group leader
exports('IsGroupLeader', function(playerId)
    local groupId = playerGroup[playerId]

    if not groupId then
        return false
    end

    local group = groups[groupId]

    if not group or not group[1] then
        return false
    end

    return group[1].id == playerId
end)

-- Get group size
exports('GetGroupSize', function(groupId)
    local group = groups[groupId]

    if not group then
        return 0
    end

    return #group
end)

-- Check if group is full
exports('IsGroupFull', function(groupId, maxSize)
    maxSize = maxSize or 4

    local group = groups[groupId]

    if not group then
        return false
    end

    return #group >= maxSize
end)

-- Get invited players
exports('GetInvitedPlayers', function()
    return invitedPlayers
end)

-- Check if player is invited
exports('IsPlayerInvited', function(playerId)
    return invitedPlayers[playerId] ~= nil
end)

-- Get formatted group data
exports('GetFormattedGroup', function(groupId)
    local group = groups[groupId]

    if not group then
        return {}
    end

    local formatted = {}

    local leaderId = group[1] and group[1].id

    for _, member in ipairs(group) do
        table.insert(formatted, {
            id = member.id,
            name = member.name,
            leader = member.id == leaderId
        })
    end

    return formatted
end)