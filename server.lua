local QBCore = nil
local ESX = nil
local currentVendorLocation = nil
local currentPriceMultipliers = {}
local lastAlertTime = 0
local lastPriceUpdate = 0
local priceHistory = {}

local function LoadFramework()
    if Config.Framework == 'auto' or Config.Framework == 'qbcore' then
        if GetResourceState('qb-core') == 'started' then
            QBCore = exports['qb-core']:GetCoreObject()
            print('[GS-BlackMarket] QBCore framework detected')
            return 'qbcore'
        end
    end
    
    if Config.Framework == 'auto' or Config.Framework == 'esx' then
        if GetResourceState('es_extended') == 'started' then
            ESX = exports['es_extended']:getSharedObject()
            print('[GS-BlackMarket] ESX framework detected')
            return 'esx'
        end
    end
    
    print('[GS-BlackMarket] No compatible framework found!')
    return nil
end

local framework = LoadFramework()

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

local function SelectRandomVendorLocation()
    if #Config.VendorLocations == 0 then
        print('[GS-BlackMarket] Error: No vendor locations defined in config!')
        return nil
    end
    
    local index = math.random(1, #Config.VendorLocations)
    currentVendorLocation = Config.VendorLocations[index]
    
    return currentVendorLocation
end

local function InitializePriceMultipliers()
    for _, category in pairs(Config.Categories) do
        for _, item in pairs(category.items) do
            currentPriceMultipliers[item.name] = 1.0
            priceHistory[item.name] = {1.0}
        end
    end
end

local function GenerateNewPrice(itemName, currentMultiplier)
    local min = Config.MarketFluctuation.minMultiplier
    local max = Config.MarketFluctuation.maxMultiplier
    
    local history = priceHistory[itemName]
    local lastPrice = history[#history]
    
    local volatility = 0.15
    local maxChange = 0.2
    
    local change = (math.random() * 2 - 1) * volatility
    change = math.max(math.min(change, maxChange), -maxChange)
    
    local newMultiplier = lastPrice + change
    
    if newMultiplier > max then
        newMultiplier = max - math.random() * 0.1
    elseif newMultiplier < min then
        newMultiplier = min + math.random() * 0.1
    end
    
    return newMultiplier
end

local function UpdatePriceMultipliers()
    if not Config.MarketFluctuation.enabled then return end
    
    local currentTime = os.time()
    if (currentTime - lastPriceUpdate) < Config.MarketFluctuation.changeInterval then
        return
    end
    
    lastPriceUpdate = currentTime
    
    for _, category in pairs(Config.Categories) do
        for _, item in pairs(category.items) do
            local newPrice = GenerateNewPrice(item.name, currentPriceMultipliers[item.name])
            currentPriceMultipliers[item.name] = newPrice
            
            if not priceHistory[item.name] then
                priceHistory[item.name] = {}
            end
            
            table.insert(priceHistory[item.name], newPrice)
            
            if #priceHistory[item.name] > 10 then
                table.remove(priceHistory[item.name], 1)
            end
        end
    end
    
    TriggerClientEvent('gs-blackmarket:updatePrices', -1, currentPriceMultipliers)
end

local function GetPlayerMoney(source)
    if framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player.PlayerData.money.cash
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.getMoney()
    end
    return 0
end

local function RemovePlayerMoney(source, amount)
    if framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        Player.Functions.RemoveMoney('cash', amount)
        return true
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeMoney(amount)
        return true
    end
    return false
end

local function AddItemToPlayer(source, item, count)
    if framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player.Functions.AddItem(item, count) then
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], 'add')
            return true
        end
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.canCarryItem(item, count) then
            xPlayer.addInventoryItem(item, count)
            return true
        end
    end
    return false
end

local function IsEnoughPoliceOnline()
    if not Config.PoliceAlert.enabled then return false end
    
    local cops = 0
    
    if framework == 'qbcore' then
        for _, player in pairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(player)
            if Player and table.contains(Config.PoliceJobs, Player.PlayerData.job.name) then
                cops = cops + 1
            end
        end
    elseif framework == 'esx' then
        local xPlayers = ESX.GetPlayers()
        for i=1, #xPlayers do
            local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
            if xPlayer and table.contains(Config.PoliceJobs, xPlayer.job.name) then
                cops = cops + 1
            end
        end
    end
    
    return cops >= Config.PoliceAlert.requiredCops
end


local function IsAlertOnCooldown()
    local currentTime = os.time()
    return (currentTime - lastAlertTime) < Config.PoliceAlert.cooldown
end

local function SetAlertCooldown()
    lastAlertTime = os.time()
end

local function AlertPolice(source, alertType, coords)
    if not Config.PoliceAlert.enabled then return end
    if IsAlertOnCooldown() then return end
    if not IsEnoughPoliceOnline() then return end
    
    SetAlertCooldown()
    
    local alertData = alertType == 'purchase' and Config.Dispatch.blackmarketPurchase or Config.Dispatch.blackmarketPickup
    
    local dispatchSystem = Config.Dispatch.system
    
    if dispatchSystem == 'auto' then
        if GetResourceState('cd_dispatch') == 'started' then
            dispatchSystem = 'cd_dispatch'
        elseif GetResourceState('ps-dispatch') == 'started' then
            dispatchSystem = 'ps-dispatch'
        elseif GetResourceState('qb-dispatch') == 'started' then
            dispatchSystem = 'qb-dispatch'
        elseif GetResourceState('linden_outlawalert') == 'started' then
            dispatchSystem = 'linden_outlawalert'
        else
            dispatchSystem = 'default'
        end
    end
    
    if dispatchSystem == 'cd_dispatch' then
        local data = {
            job = Config.PoliceAlert.policeJobs,
            coords = coords,
            title = alertData.code .. ' - ' .. alertData.description,
            message = Config.PoliceAlert.alertMessage,
            flash = 0,
            unique_id = tostring(math.random(0000000, 9999999)),
            blip = {
                sprite = alertData.blipSprite,
                scale = alertData.blipScale,
                colour = alertData.blipColor,
                flashes = true,
                text = alertData.description,
                time = alertData.blipLength,
                sound = 1,
            }
        }
        TriggerClientEvent('cd_dispatch:AddNotification', -1, data)
        
    elseif dispatchSystem == 'ps-dispatch' then
        local dispatchData = {
            message = alertData.description,
            codeName = alertData.code,
            code = alertData.code,
            icon = 'fas fa-exclamation-triangle',
            priority = 2,
            coords = coords,
            street = 'Unknown Location',
            camId = 0,
            timeOut = alertData.blipLength * 1000,
            jobs = Config.PoliceAlert.policeJobs
        }
        exports['ps-dispatch']:CustomAlert(dispatchData)
        
    elseif dispatchSystem == 'qb-dispatch' then
        TriggerClientEvent('qb-dispatch:client:AddCallBlip', -1, coords, alertData.description, alertData.blipSprite, alertData.blipColor, alertData.blipScale, alertData.blipLength)
        
    elseif dispatchSystem == 'linden_outlawalert' then
        local data = {
            displayCode = alertData.code,
            description = alertData.description,
            isImportant = false,
            recipientList = Config.PoliceAlert.policeJobs,
            length = alertData.blipLength,
            infoM = Config.PoliceAlert.alertMessage,
            info = alertData.description,
            blipSprite = alertData.blipSprite,
            blipColour = alertData.blipColor,
            blipScale = alertData.blipScale,
            blipLength = alertData.blipLength,
            sound = alertData.sound,
            offset = 'false',
            blipflash = 'false'
        }
        TriggerClientEvent('linden_outlawalert:alertToClients', -1, coords, data)
        
    elseif dispatchSystem == 'custom' then
        TriggerEvent(Config.Dispatch.customEvent, {
            type = alertType,
            coords = coords,
            code = alertData.code,
            description = alertData.description,
            sprite = alertData.blipSprite,
            color = alertData.blipColor,
            scale = alertData.blipScale,
            duration = alertData.blipLength
        })
        
    else
        for _, playerId in ipairs(GetPlayers()) do
            local player = tonumber(playerId)
            local hasPoliceJob = false
            
            if framework == 'qbcore' then
                local Player = QBCore.Functions.GetPlayer(player)
                if Player and table.contains(Config.PoliceAlert.policeJobs, Player.PlayerData.job.name) then
                    hasPoliceJob = true
                end
            elseif framework == 'esx' then
                local xPlayer = ESX.GetPlayerFromId(player)
                if xPlayer and table.contains(Config.PoliceAlert.policeJobs, xPlayer.job.name) then
                    hasPoliceJob = true
                end
            end
            
            if hasPoliceJob then
                TriggerClientEvent('gs-blackmarket:policeAlert', player, coords, alertData, Config.PoliceAlert.alertTitle, Config.PoliceAlert.alertMessage)
            end
        end
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    print('[GS-BlackMarket] Initializing black market...')
    SelectRandomVendorLocation()
    InitializePriceMultipliers()
    UpdatePriceMultipliers()
    
    if Config.MarketFluctuation.enabled then
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(60000)
                UpdatePriceMultipliers()
            end
        end)
    end
    
    Citizen.SetTimeout(1000, function()
        print('\n\n')
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print('                      BLACK MARKET LOCATION                         ')
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        
        if currentVendorLocation then
            local coords = currentVendorLocation.coords
            print('^3[GS-BlackMarket] ^0Current black market location: ^2' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z .. '^0')
        else
            print('^1[GS-BlackMarket] ^0No vendor location selected!')
        end
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print('\n')
    end)
end)

RegisterNetEvent('gs-blackmarket:getVendorLocation')
AddEventHandler('gs-blackmarket:getVendorLocation', function()
    local src = source
    TriggerClientEvent('gs-blackmarket:setVendorLocation', src, currentVendorLocation)
end)

RegisterNetEvent('gs-blackmarket:getMarketItems')
AddEventHandler('gs-blackmarket:getMarketItems', function()
    local src = source
    TriggerClientEvent('gs-blackmarket:setMarketItems', src, Config.Categories, currentPriceMultipliers)
end)

RegisterNetEvent('gs-blackmarket:checkoutCart')
AddEventHandler('gs-blackmarket:checkoutCart', function(items)
    local src = source
    
    if not items or #items == 0 then
        TriggerClientEvent('gs-blackmarket:notification', src, 'Your cart is empty', 'error')
        return
    end
    
    local totalPrice = 0
    local itemsToGive = {}
    
    for _, item in ipairs(items) do
        local itemName = item.name
        local quantity = item.quantity
        local price = item.price
        
        local itemExists = false
        local configPrice = 0
        
        for _, category in pairs(Config.Categories) do
            for _, configItem in pairs(category.items) do
                if configItem.name == itemName then
                    itemExists = true
                    configPrice = math.floor(configItem.basePrice * (currentPriceMultipliers[itemName] or 1.0))
                    break
                end
            end
            if itemExists then break end
        end
        
        if not itemExists then
            TriggerClientEvent('gs-blackmarket:notification', src, 'Invalid item in cart', 'error')
            return
        end
        
        if math.abs(configPrice - price) > 1 then
            TriggerClientEvent('gs-blackmarket:notification', src, 'Item prices have changed. Please refresh your cart.', 'error')
            return
        end
        
        totalPrice = totalPrice + (price * quantity)
        table.insert(itemsToGive, {name = itemName, quantity = quantity})
    end
    
    if GetPlayerMoney(src) < totalPrice then
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.notEnoughMoney, 'error')
        return
    end
    
    if RemovePlayerMoney(src, totalPrice) then
        local pickupLocation = Config.PickupLocations[math.random(#Config.PickupLocations)]
        
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.orderPlaced, 'success')
        
        local waitTime = math.random(Config.Delivery.waitTime.min, Config.Delivery.waitTime.max)
        
        TriggerClientEvent('gs-blackmarket:orderPlaced', src, {
            items = itemsToGive,
            location = pickupLocation,
            waitTime = waitTime
        })
        
        if math.random(1, 100) <= Config.PoliceAlert.chanceOnPurchase then
            local playerPed = GetPlayerPed(src)
            local playerCoords = GetEntityCoords(playerPed)
            AlertPolice(src, 'purchase', playerCoords)
        end
    end
end)

RegisterNetEvent('gs-blackmarket:placeOrder')
AddEventHandler('gs-blackmarket:placeOrder', function(itemName, quantity)
    local src = source
    
    local itemData = nil
    local itemPrice = 0
    
    for _, category in pairs(Config.Categories) do
        for _, item in pairs(category.items) do
            if item.name == itemName then
                itemData = item
                itemPrice = math.floor(item.basePrice * (currentPriceMultipliers[itemName] or 1.0))
                break
            end
        end
        if itemData then break end
    end
    
    if not itemData then
        TriggerClientEvent('gs-blackmarket:notification', src, 'Item not found', 'error')
        return
    end
    
    local totalPrice = itemPrice * quantity
    
    if GetPlayerMoney(src) < totalPrice then
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.notEnoughMoney, 'error')
        return
    end
    
    if RemovePlayerMoney(src, totalPrice) then
        local pickupLocation = Config.PickupLocations[math.random(#Config.PickupLocations)]
        
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.orderPlaced, 'success')
        
        local waitTime = math.random(Config.Delivery.waitTime.min, Config.Delivery.waitTime.max)
        
        TriggerClientEvent('gs-blackmarket:orderPlaced', src, {
            item = itemName,
            quantity = quantity,
            location = pickupLocation,
            waitTime = waitTime
        })
        
        if math.random(1, 100) <= Config.PoliceAlert.chanceOnPurchase then
            local playerPed = GetPlayerPed(src)
            local playerCoords = GetEntityCoords(playerPed)
            AlertPolice(src, 'purchase', playerCoords)
        end
    end
end)

RegisterNetEvent('gs-blackmarket:collectOrder')
AddEventHandler('gs-blackmarket:collectOrder', function(orderData)
    local src = source
    local allItemsAdded = true
    
    for _, item in ipairs(orderData.items) do
        if not AddItemToPlayer(src, item.name, item.quantity) then
            allItemsAdded = false
            break
        end
    end
    
    if allItemsAdded then
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.orderCollected, 'success')
        
        if math.random(1, 100) <= Config.PoliceAlert.chanceOnPickup then
            local playerPed = GetPlayerPed(src)
            local playerCoords = GetEntityCoords(playerPed)
            AlertPolice(src, 'pickup', playerCoords)
        end
    else
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.inventoryFull, 'error')
    end
end)

RegisterCommand('blackmarketlocation', function(source, args, rawCommand)
    local src = source
    
    if src > 0 then
        local isAdmin = false
        
        if framework == 'qbcore' then
            isAdmin = QBCore.Functions.HasPermission(src, 'admin')
        elseif framework == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(src)
            isAdmin = xPlayer.getGroup() == 'admin'
        end
        
        if not isAdmin then
            TriggerClientEvent('gs-blackmarket:notification', src, 'You do not have permission to use this command', 'error')
            return
        end
    end
    
    if currentVendorLocation then
        local coords = currentVendorLocation.coords
        if src == 0 then
            print('\n\n')
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
            print('                      BLACK MARKET LOCATION                         ')
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
            print('^3[GS-BlackMarket] ^0Current black market location: ^2' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z .. '^0')
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
            print('\n')
        else
            TriggerClientEvent('gs-blackmarket:notification', src, 'Black Market Location: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z, 'info')
            TriggerClientEvent('gs-blackmarket:setWaypoint', src, coords)
        end
    else
        if src == 0 then
            print('^1[GS-BlackMarket] ^0No vendor location selected!')
        else
            TriggerClientEvent('gs-blackmarket:notification', src, 'No vendor location available', 'error')
        end
    end
end, false)