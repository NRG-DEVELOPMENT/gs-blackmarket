local Config = {}

local function LoadConfig()
    Config = exports[GetCurrentResourceName()]:GetConfig()
end

local priceMultipliers = {}
local dealerCooldowns = {}
local playerPurchaseHistory = {}

local QBCore = nil
local ESX = nil
local framework = nil

Citizen.CreateThread(function()
    LoadConfig()
    
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        framework = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        framework = 'esx'
    end
    
    for _, dealer in pairs(Config.Dealers) do
        local dealerId = dealer.id
        priceMultipliers[dealerId] = {}
        
        for _, item in pairs(dealer.items) do
            priceMultipliers[dealerId][item.name] = 1.0
        end
    end
    
    if Config.PriceFluctuation and Config.PriceFluctuation.enabled then
        StartPriceFluctuation()
    end
end)

function StartPriceFluctuation()
    Citizen.CreateThread(function()
        while true do
            for _, dealer in pairs(Config.Dealers) do
                local dealerId = dealer.id
                
                if dealer.priceFluctuation == false then
                    goto continue
                end
                
                for _, item in pairs(dealer.items) do
                    local itemName = item.name
                    local currentMultiplier = priceMultipliers[dealerId][itemName] or 1.0
                    
                    local minChange = Config.PriceFluctuation.minChange or 0.01
                    local maxChange = Config.PriceFluctuation.maxChange or 0.05
                    local change = math.random() * (maxChange - minChange) + minChange
                    
                    if math.random() < 0.5 then
                        change = -change
                    end
                    
                    local newMultiplier = currentMultiplier + change
                    
                    local minMultiplier = Config.PriceFluctuation.minMultiplier or 0.5
                    local maxMultiplier = Config.PriceFluctuation.maxMultiplier or 1.5
                    newMultiplier = math.max(minMultiplier, math.min(maxMultiplier, newMultiplier))
                    
                    priceMultipliers[dealerId][itemName] = newMultiplier
                end
                
                ::continue::
            end
            
            Citizen.Wait(Config.PriceFluctuation.interval or 300000)
        end
    end)
end

function GetPlayerMoney(source, moneyType)
    if framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.Functions.GetMoney(moneyType)
        end
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if moneyType == 'cash' then
                return xPlayer.getMoney()
            elseif moneyType == 'bank' then
                return xPlayer.getAccount('bank').money
            end
        end
    end
    return 0
end

function RemovePlayerMoney(source, amount, moneyType)
    if framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            Player.Functions.RemoveMoney(moneyType, amount)
            return true
        end
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if moneyType == 'cash' then
                xPlayer.removeMoney(amount)
                return true
            elseif moneyType == 'bank' then
                xPlayer.removeAccountMoney('bank', amount)
                return true
            end
        end
    end
    return false
end

function AddItemToPlayer(source, itemName, quantity)
    if framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            if Player.Functions.AddItem(itemName, quantity) then
                TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'add', quantity)
                return true
            end
        end
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if xPlayer.canCarryItem(itemName, quantity) then
                xPlayer.addInventoryItem(itemName, quantity)
                return true
            else
                return false, "Cannot carry item"
            end
        end
    end
    return false
end

function CanPlayerCarryItem(source, itemName, quantity)
    if framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return true
        end
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.canCarryItem(itemName, quantity)
        end
    end
    return false
end

function GetItemLabel(itemName)
    if framework == 'qb' then
        local item = QBCore.Shared.Items[itemName]
        if item then
            return item.label
        end
    elseif framework == 'esx' then
        local item = ESX.GetItemLabel(itemName)
        if item then
            return item
        end
    end
    return itemName
end

function CheckDealerAccess(source, dealerId)
    local dealer = nil
    
    for _, d in pairs(Config.Dealers) do
        if d.id == dealerId then
            dealer = d
            break
        end
    end
    
    if not dealer then
        return false, "Dealer not found"
    end
    
    local cooldownTime = dealerCooldowns[dealerId] or 0
    local currentTime = os.time()
    if currentTime < cooldownTime then
        local remainingTime = cooldownTime - currentTime
        return false, "Dealer is on cooldown for " .. remainingTime .. " seconds"
    end
    
    if dealer.jobs and #dealer.jobs > 0 then
        local hasJob = false
        local playerJob = GetPlayerJob(source)
        
        for _, job in pairs(dealer.jobs) do
            if playerJob == job then
                hasJob = true
                break
            end
        end
        
        if not hasJob then
            return false, "You don't have the required job"
        end
    end
    
    if dealer.gangs and #dealer.gangs > 0 then
        local hasGang = false
        local playerGang = GetPlayerGang(source)
        
        for _, gang in pairs(dealer.gangs) do
            if playerGang == gang then
                hasGang = true
                break
            end
        end
        
        if not hasGang then
            return false, "You don't have the required gang"
        end
    end
    
    return true
end

function GetPlayerJob(source)
    if framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.job.name
        end
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.job.name
        end
    end
    return nil
end

function GetPlayerGang(source)
    if framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.gang.name
        end
    elseif framework == 'esx' then
        return nil
    end
    return nil
end

function SetDealerCooldown(dealerId)
    local dealer = nil
    
    for _, d in pairs(Config.Dealers) do
        if d.id == dealerId then
            dealer = d
            break
        end
    end
    
    if not dealer then return end
    
    local cooldownTime = dealer.cooldown or Config.DefaultCooldown or 300
    dealerCooldowns[dealerId] = os.time() + cooldownTime
    
    TriggerClientEvent('gs-blackmarket:client:syncCooldown', -1, dealerId, cooldownTime)
end

RegisterServerEvent('gs-blackmarket:server:getPriceMultipliers')
RegisterServerEvent('gs-blackmarket:server:purchaseItem')
RegisterServerEvent('gs-blackmarket:server:checkoutCart')

AddEventHandler('gs-blackmarket:server:getPriceMultipliers', function(dealerId)
    local source = source
    
    TriggerClientEvent('gs-blackmarket:client:updatePrices', source, priceMultipliers[dealerId] or {})
end)

AddEventHandler('gs-blackmarket:server:purchaseItem', function(data)
    local source = source
    local dealerId = data.dealerId
    local itemName = data.itemName
    local quantity = data.quantity
    local price = data.price
    
    local hasAccess, accessError = CheckDealerAccess(source, dealerId)
    if not hasAccess then
        TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
            type = 'error',
            message = accessError
        })
        return
    end
    
    local moneyType = Config.PaymentMethod or 'cash'
    local playerMoney = GetPlayerMoney(source, moneyType)
    
    if playerMoney < price then
        TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
            type = 'error',
            message = "You don't have enough money"
        })
        return
    end
    
    if not CanPlayerCarryItem(source, itemName, quantity) then
        TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
            type = 'error',
            message = "You can't carry this item"
        })
        return
    end
    
    if not RemovePlayerMoney(source, price, moneyType) then
        TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
            type = 'error',
            message = "Failed to process payment"
        })
        return
    end
    
    local success, errorMessage = AddItemToPlayer(source, itemName, quantity)
    if not success then
        TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
            type = 'error',
            message = errorMessage or "Failed to add item"
        })
        return
    end
    
    local playerIdentifier = GetPlayerIdentifier(source)
    if not playerPurchaseHistory[playerIdentifier] then
        playerPurchaseHistory[playerIdentifier] = {}
    end
    
    table.insert(playerPurchaseHistory[playerIdentifier], {
        dealerId = dealerId,
        itemName = itemName,
        quantity = quantity,
        price = price,
        timestamp = os.time()
    })
    
    if Config.EnableCooldown then
        SetDealerCooldown(dealerId)
    end
    
    local itemLabel = GetItemLabel(itemName)
    TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
        type = 'success',
        message = "Purchased " .. quantity .. "x " .. itemLabel
    })
    
    if Config.EnableLogs then
        local logMessage = GetPlayerName(source) .. " purchased " .. quantity .. "x " .. itemName .. " for $" .. price
        print("[GS-BlackMarket] " .. logMessage)
    end
end)

AddEventHandler('gs-blackmarket:server:checkoutCart', function(data)
    local source = source
    local dealerId = data.dealerId
    local items = data.items
    local total = data.total
    
    local hasAccess, accessError = CheckDealerAccess(source, dealerId)
    if not hasAccess then
        TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
            type = 'error',
            message = accessError
        })
        return
    end
    
    local moneyType = Config.PaymentMethod or 'cash'
    local playerMoney = GetPlayerMoney(source, moneyType)
    
    if playerMoney < total then
        TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
            type = 'error',
            message = "You don't have enough money"
        })
        return
    end
    
    for _, item in pairs(items) do
        if not CanPlayerCarryItem(source, item.name, item.quantity) then
            TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
                type = 'error',
                message = "You can't carry all these items"
            })
            return
        end
    end
    
    if not RemovePlayerMoney(source, total, moneyType) then
        TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
            type = 'error',
            message = "Failed to process payment"
        })
        return
    end
    
    local allItemsAdded = true
    local failedItems = {}
    
    for _, item in pairs(items) do
        local success, errorMessage = AddItemToPlayer(source, item.name, item.quantity)
        if not success then
            allItemsAdded = false
            table.insert(failedItems, {
                name = item.name,
                error = errorMessage
            })
        end
    end
    
    local playerIdentifier = GetPlayerIdentifier(source)
    if not playerPurchaseHistory[playerIdentifier] then
        playerPurchaseHistory[playerIdentifier] = {}
    end
    
    for _, item in pairs(items) do
        table.insert(playerPurchaseHistory[playerIdentifier], {
            dealerId = dealerId,
            itemName = item.name,
            quantity = item.quantity,
            price = item.price * item.quantity,
            timestamp = os.time()
        })
    end
    
    if Config.EnableCooldown then
        SetDealerCooldown(dealerId)
    end
    
    if allItemsAdded then
        TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
            type = 'success',
            message = "Purchase completed successfully"
        })
    else
        TriggerClientEvent('gs-blackmarket:client:notifyPlayer', source, {
            type = 'error',
            message = "Some items could not be added to your inventory"
        })
    end
    
    if Config.EnableLogs then
        local logMessage = GetPlayerName(source) .. " purchased multiple items for $" .. total
        print("[GS-BlackMarket] " .. logMessage)
    end
end)

function GetPlayerIdentifier(source)
    if framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.citizenid
        end
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.identifier
        end
    end
    return tostring(source)
end

exports('GetConfig', function()
    return Config
end)