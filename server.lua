local QBCore = nil
local ESX = nil
local currentVendorLocation = nil
local currentPriceMultipliers = {}
local lastAlertTime = 0

-- Framework Detection
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

-- Helper function to check if value exists in table
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Select Random Vendor Location
local function SelectRandomVendorLocation()
    if #Config.VendorLocations == 0 then
        print('[GS-BlackMarket] Error: No vendor locations defined in config!')
        return nil
    end
    
    local index = math.random(1, #Config.VendorLocations)
    currentVendorLocation = Config.VendorLocations[index]
    
    return currentVendorLocation
end

-- Initialize Price Multipliers
local function InitializePriceMultipliers()
    for _, category in pairs(Config.Categories) do
        for _, item in pairs(category.items) do
            currentPriceMultipliers[item.name] = 1.0
        end
    end
end

-- Update Price Multipliers
local function UpdatePriceMultipliers()
    if not Config.MarketFluctuation.enabled then return end
    
    for _, category in pairs(Config.Categories) do
        for _, item in pairs(category.items) do
            local min = Config.MarketFluctuation.minMultiplier
            local max = Config.MarketFluctuation.maxMultiplier
            currentPriceMultipliers[item.name] = math.random() * (max - min) + min
        end
    end
    
    TriggerClientEvent('gs-blackmarket:updatePrices', -1, currentPriceMultipliers)
end

-- Get Player Money
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

-- Remove Player Money
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

-- Add Item to Player
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

-- Check if enough police are online
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


-- Check if alert is on cooldown
local function IsAlertOnCooldown()
    local currentTime = os.time()
    return (currentTime - lastAlertTime) < Config.PoliceAlert.cooldown
end

-- Set alert cooldown
local function SetAlertCooldown()
    lastAlertTime = os.time()
end

-- Send alert to police
local function AlertPolice(source, alertType, coords)
    if not Config.PoliceAlert.enabled then return end
    if IsAlertOnCooldown() then return end
    if not IsEnoughPoliceOnline() then return end
    
    -- Set the alert on cooldown
    SetAlertCooldown()
    
    -- Get alert data based on type
    local alertData = alertType == 'purchase' and Config.Dispatch.blackmarketPurchase or Config.Dispatch.blackmarketPickup
    
    -- Determine which dispatch system to use
    local dispatchSystem = Config.Dispatch.system
    
    if dispatchSystem == 'auto' then
        -- Auto-detect dispatch system
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
    
    -- Send alert based on dispatch system
    if dispatchSystem == 'cd_dispatch' then
        -- CD Dispatch
        local data = {
            job = Config.PoliceAlert.policeJobs, -- jobs that will get the alerts
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
        -- PS Dispatch
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
        -- QB Dispatch
        TriggerClientEvent('qb-dispatch:client:AddCallBlip', -1, coords, alertData.description, alertData.blipSprite, alertData.blipColor, alertData.blipScale, alertData.blipLength)
        
    elseif dispatchSystem == 'linden_outlawalert' then
        -- Linden's Outlaw Alert
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
        -- Custom dispatch system
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
        -- Default alert system (basic)
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

-- Resource Start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- Initialize the market
    print('[GS-BlackMarket] Initializing black market...')
    SelectRandomVendorLocation()
    InitializePriceMultipliers()
    UpdatePriceMultipliers()
    
    -- Schedule price updates
    if Config.MarketFluctuation.enabled then
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(Config.MarketFluctuation.changeInterval * 1000)
                UpdatePriceMultipliers()
            end
        end)
    end
    
    -- Print location at the end with visual separation for better visibility
    Citizen.SetTimeout(1000, function()
        print('\n\n')
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print('                      BLACK MARKET LOCATION                         ')
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        
        if currentVendorLocation then
            local coords = currentVendorLocation.coords
            print('^3[GS-BlackMarket] ^0Current black market location: ^2' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z .. '^0')
        else
            print('^1[GS-BlackMarket] ^0No vendor location selected!')
        end
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print('\n')
    end)
end)

-- Get Current Vendor Location
RegisterNetEvent('gs-blackmarket:getVendorLocation')
AddEventHandler('gs-blackmarket:getVendorLocation', function()
    local src = source
    TriggerClientEvent('gs-blackmarket:setVendorLocation', src, currentVendorLocation)
end)

-- Get Market Items
RegisterNetEvent('gs-blackmarket:getMarketItems')
AddEventHandler('gs-blackmarket:getMarketItems', function()
    local src = source
    TriggerClientEvent('gs-blackmarket:setMarketItems', src, Config.Categories, currentPriceMultipliers)
end)

-- Update the checkout cart event handler in server.lua
RegisterNetEvent('gs-blackmarket:checkoutCart')
AddEventHandler('gs-blackmarket:checkoutCart', function(items)
    local src = source
    
    -- Check if items is nil or empty
    if not items or #items == 0 then
        TriggerClientEvent('gs-blackmarket:notification', src, 'Your cart is empty', 'error')
        return
    end
    
    local totalPrice = 0
    local itemsToGive = {}
    
    -- Calculate total price and validate items
    for _, item in ipairs(items) do
        local itemName = item.name
        local quantity = item.quantity
        local price = item.price
        
        -- Validate item exists in config
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
        
        -- Validate price hasn't changed
        if math.abs(configPrice - price) > 1 then -- Allow for small rounding differences
            TriggerClientEvent('gs-blackmarket:notification', src, 'Item prices have changed. Please refresh your cart.', 'error')
            return
        end
        
        totalPrice = totalPrice + (price * quantity)
        table.insert(itemsToGive, {name = itemName, quantity = quantity})
    end
    
    -- Check if player has enough money
    if GetPlayerMoney(src) < totalPrice then
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.notEnoughMoney, 'error')
        return
    end
    
    -- Process payment
    if RemovePlayerMoney(src, totalPrice) then
        -- Select random pickup location
        local pickupLocation = Config.PickupLocations[math.random(#Config.PickupLocations)]
        
        -- Notify player
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.orderPlaced, 'success')
        
        -- Schedule delivery
        local waitTime = math.random(Config.Delivery.waitTime.min, Config.Delivery.waitTime.max)
        
        -- Send order details to client
        TriggerClientEvent('gs-blackmarket:orderPlaced', src, {
            items = itemsToGive,
            location = pickupLocation,
            waitTime = waitTime
        })
        
        -- Chance to alert police about the purchase
        if math.random(1, 100) <= Config.PoliceAlert.chanceOnPurchase then
            local playerPed = GetPlayerPed(src)
            local playerCoords = GetEntityCoords(playerPed)
            AlertPolice(src, 'purchase', playerCoords)
        end
    end
end)

-- Place Order
RegisterNetEvent('gs-blackmarket:placeOrder')
AddEventHandler('gs-blackmarket:placeOrder', function(itemName, quantity)
    local src = source
    
    -- Find the item in the config
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
    
    -- Check if player has enough money
    if GetPlayerMoney(src) < totalPrice then
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.notEnoughMoney, 'error')
        return
    end
    
    -- Process payment
    if RemovePlayerMoney(src, totalPrice) then
        -- Select random pickup location
        local pickupLocation = Config.PickupLocations[math.random(#Config.PickupLocations)]
        
        -- Notify player
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.orderPlaced, 'success')
        
        -- Schedule delivery
        local waitTime = math.random(Config.Delivery.waitTime.min, Config.Delivery.waitTime.max)
        
        -- Send order details to client
        TriggerClientEvent('gs-blackmarket:orderPlaced', src, {
            item = itemName,
            quantity = quantity,
            location = pickupLocation,
            waitTime = waitTime
        })
        
        -- Chance to alert police about the purchase
        if math.random(1, 100) <= Config.PoliceAlert.chanceOnPurchase then
            local playerPed = GetPlayerPed(src)
            local playerCoords = GetEntityCoords(playerPed)
            AlertPolice(src, 'purchase', playerCoords)
        end
    end
end)

-- Collect Order
RegisterNetEvent('gs-blackmarket:collectOrder')
AddEventHandler('gs-blackmarket:collectOrder', function(orderData)
    local src = source
    local allItemsAdded = true
    
    -- Add items to player inventory
    for _, item in ipairs(orderData.items) do
        if not AddItemToPlayer(src, item.name, item.quantity) then
            allItemsAdded = false
            break
        end
    end
    
    if allItemsAdded then
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.orderCollected, 'success')
        
        -- Chance to alert police about the pickup
        if math.random(1, 100) <= Config.PoliceAlert.chanceOnPickup then
            local playerPed = GetPlayerPed(src)
            local playerCoords = GetEntityCoords(playerPed)
            AlertPolice(src, 'pickup', playerCoords)
        end
    else
        TriggerClientEvent('gs-blackmarket:notification', src, Config.Notifications.inventoryFull, 'error')
    end
end)

-- Command to print current black market location (for admins)
RegisterCommand('blackmarketlocation', function(source, args, rawCommand)
    local src = source
    
    -- Check if player is admin (you might want to add your own admin check here)
    if src > 0 then -- If executed by a player
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
    
    -- Print location
    if currentVendorLocation then
        local coords = currentVendorLocation.coords
        if src == 0 then -- Console
            print('\n\n')
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
            print('                      BLACK MARKET LOCATION                         ')
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
            print('^3[GS-BlackMarket] ^0Current black market location: ^2' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z .. '^0')
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
            print('\n')
        else -- Player
            TriggerClientEvent('gs-blackmarket:notification', src, 'Black Market Location: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z, 'info')
            -- Set waypoint for admin
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
