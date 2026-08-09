QBCore = nil
ESX = nil

if Config.Framework == 'auto_detect' then
    if GetResourceState("qb-core") == "started" or GetResourceState("qbx_core") == "started" then
        QBCore = exports["qb-core"]:GetCoreObject()
    elseif GetResourceState("es_extended") == "started" then
        ESX = exports["es_extended"]:getSharedObject()
    end
elseif Config.Framework == 'qb' or Config.Framework == 'qbox' then
    QBCore = exports["qb-core"]:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports["es_extended"]:getSharedObject()
end


--  ░██████╗░██████╗░░█████╗░░█████╗░██████╗░███████╗
--  ██╔═══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝
--  ██║██╗██║██████╦╝██║░░╚═╝██║░░██║██████╔╝█████╗░░
--  ╚██████╔╝██╔══██╗██║░░██╗██║░░██║██╔══██╗██╔══╝░░
--  ░╚═██╔═╝░██████╦╝╚█████╔╝╚█████╔╝██║░░██║███████╗
--  ░░░╚═╝░░░╚═════╝░░╚════╝░░╚════╝░╚═╝░░╚═╝╚══════╝


GetPlayer = function(src)
    if QBCore then
        return QBCore.Functions.GetPlayer(src)
    else
        return ESX.GetPlayerFromId(src)
    end
end
