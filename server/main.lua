local groups = {}
local playerGroup = {}
local invitedPlayers = {}
local maxgroupsize = 4

local function syncGroup(groupId, group)
    if not group or #group == 0 then return end
    local leaderId = group[1].id
    for _, v in ipairs(group) do
        if playerGroup[v.id] == groupId then
            leaderId = group[1].id
            break
        end
    end
    local xPlayer = GetPlayer(leaderId)
    local leaderName = xPlayer and
        (xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname)
        or GetPlayerName(leaderId)
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
        TriggerClientEvent(
            "group:client:updateGroup",
            member.id,
            formatted,
            leaderId,
            leaderName,
            maxgroupsize,
            groupId
        )
    end
end

RegisterNetEvent("group:server:getNearbyName", function(targetId)
    local src = source
    local Player = GetPlayer(targetId)
    if not Player then return end
    local charinfo = Player.PlayerData.charinfo
    local fullName = charinfo.firstname .. " " .. charinfo.lastname
    TriggerClientEvent(
        "group:client:receiveNearbyName",
        src,
        targetId,
        fullName
    )
end)


RegisterNetEvent("group:server:invitePlayer", function(targetId)
    local src = source
    if targetId == src then return end

    local Player = GetPlayer(src)
    if not Player then return end
    local charinfo = Player.PlayerData.charinfo
    local fullName = charinfo.firstname .. " " .. charinfo.lastname

    local targetPlayer = GetPlayer(targetId)
    if not targetPlayer then return end
    local tcharinfo = targetPlayer.PlayerData.charinfo
    local targetfullName = tcharinfo.firstname .. " " .. tcharinfo.lastname

    if not playerGroup[src] then
        playerGroup[src] = src
        groups[src] = {
            { id = src, name = fullName }
        }
    end

    local groupId = playerGroup[src]
    local group = groups[groupId] or {}

    if #group >= maxgroupsize then
        TriggerClientEvent('v-groups:client:SendNotification', src, 'Your group is full', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
        return
    end

    invitedPlayers[targetId] = { from = src, groupId = groupId }
    TriggerClientEvent('v-groups:client:SendNotification', src, 'You have invited '.. targetfullName, 'success', 'bottom', '#141517', '#C1C2C5', 'check', 'green')
    TriggerClientEvent(
        "group:client:receiveInvite",
        targetId,
        fullName,
        groupId,
        src
    )
    TriggerClientEvent("group:client:inviteStatus", src, targetId, "invited")
    TriggerClientEvent("group:client:inviteStatus", targetId, src, "invited")
end)

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
    local xPlayer = GetPlayer(leaderId)
    local leaderName = "Unknown"
    if xPlayer then
        local c = xPlayer.PlayerData.charinfo
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
    TriggerClientEvent("group:client:updateGroup", src, formatted, leaderId, leaderName, maxgroupsize, groupId)
end)


RegisterNetEvent("group:server:acceptInvite", function(targetId)
    local src = source
    local invite = invitedPlayers[src]
    if not invite or invite.groupId ~= targetId or invite.from == src then
        return
    end

    local group = groups[targetId]
    if not group then
        invitedPlayers[src] = nil
        return
    end

    if #group >= maxgroupsize then
        invitedPlayers[src] = nil
        TriggerClientEvent('v-groups:client:SendNotification', src, 'That group is full', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
        return
    end

    local Player = GetPlayer(src)
    if not Player then return end
    local charinfo = Player.PlayerData.charinfo
    local fullName = charinfo.firstname .. " " .. charinfo.lastname

    local oldGroupId = playerGroup[src]
    if oldGroupId and oldGroupId ~= targetId then
        local oldGroup = groups[oldGroupId]
        if oldGroup then
            for i = #oldGroup, 1, -1 do
                if oldGroup[i].id == src then
                    table.remove(oldGroup, i)
                    break
                end
            end
            if #oldGroup == 0 then
                groups[oldGroupId] = nil
            else
                syncGroup(oldGroupId, oldGroup)
            end
        end
    end

    playerGroup[src] = targetId
    table.insert(group, {
        id = src,
        name = fullName
    })
    invitedPlayers[src] = nil
    syncGroup(targetId, group)

    TriggerClientEvent('v-groups:client:SendNotification', targetId, fullName .. ' has joined the group', 'success', 'bottom', '#141517', '#C1C2C5', 'check', 'green')
    TriggerClientEvent('v-groups:client:SendNotification', src, 'You have joined the group', 'success', 'bottom', '#141517', '#C1C2C5', 'check', 'green')
end)


RegisterNetEvent("group:server:declineInvite", function(inviterId)
    local src = source

    local invite = invitedPlayers[src]
    if invite then
        inviterId = invite.from
    end

    invitedPlayers[src] = nil

    if not inviterId then return end

    TriggerClientEvent(
        "group:client:inviteStatus",
        inviterId,
        src,
        "invite"
    )

    TriggerClientEvent(
        "group:client:inviteStatus",
        src,
        inviterId,
        "invite"
    )

    local targetPlayer = GetPlayer(src)
    local targetfullName = "Player"
    if targetPlayer then
        local tcharinfo = targetPlayer.PlayerData.charinfo
        targetfullName = tcharinfo.firstname .. " " .. tcharinfo.lastname
    end
    TriggerClientEvent('v-groups:client:SendNotification', inviterId, targetfullName .. ' declined invitation', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
end)


RegisterNetEvent("group:server:kickPlayer", function(targetId)
    local src = source
    if targetId == src then return end

    local groupId = playerGroup[src]
    if not groupId then return end
    local group = groups[groupId]
    if not group or not group[1] then return end
    local leaderId = group[1].id
    if src ~= leaderId then return end

    local removed = false
    for i = #group, 1, -1 do
        if group[i].id == targetId then
            table.remove(group, i)
            removed = true
            break
        end
    end
    if not removed then return end

    TriggerClientEvent(
        'group:client:inviteStatus',
        src,
        targetId,
        'invite'
    )
    TriggerClientEvent("group:client:kicked", targetId)
    invitedPlayers[targetId] = nil
    playerGroup[targetId] = nil

    syncGroup(groupId, group)

    local Player = GetPlayer(src)
    local fullName = "Host"
    if Player then
        local tcharinfo = Player.PlayerData.charinfo
        fullName = tcharinfo.firstname .. " " .. tcharinfo.lastname
    end

    local targetPlayer = GetPlayer(targetId)
    local targetfullName = "Player"
    if targetPlayer then
        local tcharinfo = targetPlayer.PlayerData.charinfo
        targetfullName = tcharinfo.firstname .. " " .. tcharinfo.lastname
    end

    TriggerClientEvent('v-groups:client:SendNotification', targetId, fullName .. ' has kicked you from the group', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
    TriggerClientEvent('v-groups:client:SendNotification', src, 'You have kicked ' .. targetfullName ..' from the group', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
end)


RegisterNetEvent("group:server:leaveGroup", function()
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
    invitedPlayers[src] = nil
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
    local xPlayer = GetPlayer(newLeaderId)
    local leaderName = xPlayer and
        (xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname)
        or GetPlayerName(newLeaderId)



    local targetPlayer = GetPlayer(src)
    local targetfullName = "Player"
    if targetPlayer then
        local tcharinfo = targetPlayer.PlayerData.charinfo
        targetfullName = tcharinfo.firstname .. " " .. tcharinfo.lastname
    end

    for _, member in ipairs(group) do
        TriggerClientEvent(
            "group:client:updateGroup",
            member.id,
            formatted,
            newLeaderId,
            leaderName,
            maxgroupsize,
            groupId
        )
    end

    TriggerClientEvent("group:client:leftGroup", src)
    invitedPlayers[src] = nil
    syncGroup(groupId, group)
    TriggerClientEvent('v-groups:client:SendNotification', src, 'You have left the group', 'error', 'bottom', '#141517', '#C1C2C5', 'x', 'red')
end)


AddEventHandler('playerDropped', function()
    local src = source

    invitedPlayers[src] = nil
    for target, invite in pairs(invitedPlayers) do
        if type(invite) == "table" and invite.from == src then
            invitedPlayers[target] = nil
        end
    end

    local groupId = playerGroup[src]
    if not groupId then return end

    local group = groups[groupId]
    playerGroup[src] = nil
    if not group then return end

    for i = #group, 1, -1 do
        if group[i].id == src then
            table.remove(group, i)
            break
        end
    end

    if #group == 0 then
        groups[groupId] = nil
        return
    end

    groups[groupId] = group
    syncGroup(groupId, group)
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

    return groups[groupId] or {}
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

    local Player = GetPlayer(leaderId)

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
