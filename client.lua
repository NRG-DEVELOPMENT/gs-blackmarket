local QBCore = nil
local ESX = nil
local currentVendorLocation = nil
local currentPriceMultipliers = {}
local activeOrder = nil
local pickupBlip = nil
local pickupPed = nil
local vendorPed = nil
local currentCategory = nil

-- Animation Functions
function PlayTransactionAnimation()
    local playerPed = PlayerPedId()
    local animDict = "mp_common"
    local animName = "givetake1_a"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 0, 0, false, false, false)
    Citizen.Wait(1000)
    ClearPedTasks(playerPed)
end

function PlayPhoneAnimation(duration)
    local playerPed = PlayerPedId()
    local animDict = "cellphone@"
    local animName = "cellphone_text_read_base"
    local prop = "prop_npc_phone_02"
    local propBone = 28422
    
    -- Load animation dictionary
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end
    
    -- Create and attach phone prop
    local x, y, z = table.unpack(GetEntityCoords(playerPed))
    local phoneModel = GetHashKey(prop)
    
    RequestModel(phoneModel)
    while not HasModelLoaded(phoneModel) do
        Citizen.Wait(10)
    end
    
    local phoneObj = CreateObject(phoneModel, x, y, z + 0.2, true, true, true)
    local boneIndex = GetPedBoneIndex(playerPed, propBone)
    
    AttachEntityToEntity(phoneObj, playerPed, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    -- Play animation
    TaskPlayAnim(playerPed, animDict, animName, 3.0, -1, -1, 50, 0, false, false, false)
    
    -- Wait for specified duration
    Citizen.Wait(duration)
    
    -- Clean up
    DeleteObject(phoneObj)
    ClearPedTasks(playerPed)
end

function PlayPickupAnimation()
    local playerPed = PlayerPedId()
    local animDict = "mp_am_hold_up"
    local animName = "purchase_beerbox_shopkeeper"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 0, 0, false, false, false)
    Citizen.Wait(1000)
    ClearPedTasks(playerPed)
end

-- Animation Event Handlers
RegisterNetEvent('gs-blackmarket:playVendorAnimation')
AddEventHandler('gs-blackmarket:playVendorAnimation', function()
    if vendorPed then
        local animDict = "mp_common"
        local animName = "givetake1_b"
        
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(10)
        end
        
        TaskPlayAnim(vendorPed, animDict, animName, 8.0, -8.0, -1, 0, 0, false, false, false)
        Citizen.Wait(1000)
        if vendorPed then
            if currentVendorLocation and currentVendorLocation.scenario then
                TaskStartScenarioInPlace(vendorPed, currentVendorLocation.scenario, 0, true)
            else
                ClearPedTasks(vendorPed)
            end
        end
    end
end)

RegisterNetEvent('gs-blackmarket:playPickupPedAnimation')
AddEventHandler('gs-blackmarket:playPickupPedAnimation', function()
    if pickupPed then
        local animDict = "mp_am_hold_up"
        local animName = "holdup_victim_20s_bag_drop"
        
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(10)
        end
        
        TaskPlayAnim(pickupPed, animDict, animName, 8.0, -8.0, -1, 0, 0, false, false, false)
        Citizen.Wait(1000)
        if pickupPed and activeOrder and activeOrder.location then
            if activeOrder.location.scenario then
                TaskStartScenarioInPlace(pickupPed, activeOrder.location.scenario, 0, true)
            else
                ClearPedTasks(pickupPed)
            end
        end
    end
end)

-- Framework Detection
local function LoadFramework()
    if Config.Framework == 'auto' or Config.Framework == 'qbcore' then
        if GetResourceState('qb-core') == 'started' then
            QBCore = exports['qb-core']:GetCoreObject()
            return 'qbcore'
        end
    end
    
    if Config.Framework == 'auto' or Config.Framework == 'esx' then
        if GetResourceState('es_extended') == 'started' then
            ESX = exports['es_extended']:getSharedObject()
            return 'esx'
        end
    end
    
    return nil
end

-- Target System Detection
local function SetupTargetSystem()
    local targetSystem = Config.Target
    
    if targetSystem == 'auto' then
        if GetResourceState('ox_target') == 'started' then
            targetSystem = 'ox'
        elseif GetResourceState('qb-target') == 'started' then
            targetSystem = 'qb'
        else
            print('[GS-BlackMarket] No target system found, defaulting to basic interaction')
            targetSystem = 'basic'
        end
    end
    
    return targetSystem
end

local framework = LoadFramework()
local targetSystem = SetupTargetSystem()

-- Notification Function
function ShowNotification(message, type)
    if framework == 'qbcore' then
        QBCore.Functions.Notify(message, type)
    elseif framework == 'esx' then
        ESX.ShowNotification(message)
    else
        -- Fallback notification
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

-- Get the appropriate ped model for the current category
local function GetCurrentCategoryPed()
    if not currentCategory then return Config.DefaultPed end
    
    for _, category in pairs(Config.Categories) do
        if category.name == currentCategory then
            return category.ped
        end
    end
    
    return Config.DefaultPed
end

-- Create Vendor Ped
local function CreateVendorPed()
    if not currentVendorLocation then return end
    
    -- Get the ped model based on configuration
    local pedModel
    if Config.UseCategoryPeds then
        pedModel = GetCurrentCategoryPed()
    else
        pedModel = currentVendorLocation.ped or Config.DefaultPed
    end
    
    local model = GetHashKey(pedModel)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    vendorPed = CreatePed(4, model, 
        currentVendorLocation.coords.x, 
        currentVendorLocation.coords.y, 
        currentVendorLocation.coords.z - 1.0, 
        currentVendorLocation.heading, 
        false, 
        true
    )
    
    SetEntityAsMissionEntity(vendorPed, true, true)
    SetBlockingOfNonTemporaryEvents(vendorPed, true)
    SetPedDiesWhenInjured(vendorPed, false)
    SetPedCanPlayAmbientAnims(vendorPed, true)
    SetPedCanRagdollFromPlayerImpact(vendorPed, false)
    SetEntityInvincible(vendorPed, true)
    FreezeEntityPosition(vendorPed, true)
    
    if currentVendorLocation.scenario then
        TaskStartScenarioInPlace(vendorPed, currentVendorLocation.scenario, 0, true)
    end
    
    -- Setup target interaction
    if targetSystem == 'ox' then
        exports.ox_target:addLocalEntity(vendorPed, {
            {
                name = 'gs_blackmarket_vendor',
                icon = 'fas fa-shopping-bag',
                label = 'Access Black Market',
                onSelect = function()
                    OpenBlackMarketMenu()
                end,
                distance = 2.0
            }
        })
    elseif targetSystem == 'qb' then
        exports['qb-target']:AddTargetEntity(vendorPed, {
            options = {
                {
                    type = "client",
                    icon = 'fas fa-shopping-bag',
                    label = 'Access Black Market',
                    action = function()
                        OpenBlackMarketMenu()
                    end,
                }
            },
            distance = 2.0
        })
    else
        -- Basic interaction
        Citizen.CreateThread(function()
            local textShown = false
            while vendorPed do
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                local pedCoords = GetEntityCoords(vendorPed)
                local dist = #(coords - pedCoords)
                
                if dist < 2.0 then
                    if not textShown then
                        textShown = true
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to access the Black Market')
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    end
                    
                    if IsControlJustReleased(0, 38) then -- E key
                        OpenBlackMarketMenu()
                    end
                else
                    textShown = false
                end
                
                Citizen.Wait(0)
            end
        end)
    end
end

-- Create Pickup Ped
local function CreatePickupPed(location)
    local model = GetHashKey(location.ped)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    pickupPed = CreatePed(4, model, 
        location.coords.x, 
        location.coords.y, 
        location.coords.z - 1.0, 
        location.heading, 
        false, 
        true
    )
    
    SetEntityAsMissionEntity(pickupPed, true, true)
    SetBlockingOfNonTemporaryEvents(pickupPed, true)
    SetPedDiesWhenInjured(pickupPed, false)
    SetPedCanPlayAmbientAnims(pickupPed, true)
    SetPedCanRagdollFromPlayerImpact(pickupPed, false)
    SetEntityInvincible(pickupPed, true)
    FreezeEntityPosition(pickupPed, true)
    
    if location.scenario then
        TaskStartScenarioInPlace(pickupPed, location.scenario, 0, true)
    end
    
    -- Setup target interaction
    if targetSystem == 'ox' then
        exports.ox_target:addLocalEntity(pickupPed, {
            {
                name = 'gs_blackmarket_pickup',
                icon = 'fas fa-box',
                label = 'Collect Package',
                onSelect = function()
                    CollectOrder()
                end,
                distance = 2.0
            }
        })
    elseif targetSystem == 'qb' then
        exports['qb-target']:AddTargetEntity(pickupPed, {
            options = {
                {
                    type = "client",
                    icon = 'fas fa-box',
                    label = 'Collect Package',
                    action = function()
                        CollectOrder()
                    end,
                }
            },
            distance = 2.0
        })
    else
        -- Basic interaction
        Citizen.CreateThread(function()
            local textShown = false
            while pickupPed do
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                local pedCoords = GetEntityCoords(pickupPed)
                local dist = #(coords - pedCoords)
                
                if dist < 2.0 then
                    if not textShown then
                        textShown = true
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to collect your package')
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    end
                    
                    if IsControlJustReleased(0, 38) then -- E key
                        CollectOrder()
                    end
                else
                    textShown = false
                end
                
                Citizen.Wait(0)
            end
        end)
    end
end

-- Get item image from the inventory system
local function GetItemImage(itemName)
    local inventoryType = Config.Inventory
    
    if inventoryType == 'auto' then
        if GetResourceState('ox_inventory') == 'started' then
            inventoryType = 'ox'
        elseif GetResourceState('qb-inventory') == 'started' then
            inventoryType = 'qb'
        elseif GetResourceState('es_extended') == 'started' then
            inventoryType = 'esx'
        end
    end
    
    if inventoryType == 'ox' then
        -- For ox_inventory
        local items = exports.ox_inventory:Items()
        if items[itemName] then
            return items[itemName].name
        end
    elseif inventoryType == 'qb' then
        -- For qb-inventory
        local QBCore = exports['qb-core']:GetCoreObject()
        local item = QBCore.Shared.Items[itemName]
        if item then
            return item.image
        end
    elseif inventoryType == 'esx' then
        -- For ESX inventory (default to item name)
        return itemName
    end
    
    return itemName
end

-- Create Pickup Blip
local function CreatePickupBlip(coords)
    if pickupBlip then
        RemoveBlip(pickupBlip)
    end
    
    pickupBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(pickupBlip, Config.Delivery.blipSettings.sprite)
    SetBlipColour(pickupBlip, Config.Delivery.blipSettings.color)
    SetBlipScale(pickupBlip, Config.Delivery.blipSettings.scale)
    SetBlipAsShortRange(pickupBlip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Delivery.blipSettings.label)
    EndTextCommandSetBlipName(pickupBlip)
end

-- Remove Pickup Elements
local function CleanupPickup()
    if pickupBlip then
        RemoveBlip(pickupBlip)
        pickupBlip = nil
    end
    
    if pickupPed then
        DeletePed(pickupPed)
        pickupPed = nil
    end
    
    activeOrder = nil
end

-- Open Black Market Menu
function OpenBlackMarketMenu()
    -- Show loading spinner first
    SendNUIMessage({
        action = 'openMenu',
        loading = true
    })
    
    -- Request market items from server
    TriggerServerEvent('gs-blackmarket:getMarketItems')
end

-- Collect Order
function CollectOrder()
    if not activeOrder then return end
    
    -- Play pickup animation
    PlayPickupAnimation()
    
    TriggerServerEvent('gs-blackmarket:collectOrder', {
        items = activeOrder.items
    })
    
    CleanupPickup()
end

-- Default police alert handler (for when no dispatch system is available)
RegisterNetEvent('gs-blackmarket:policeAlert')
AddEventHandler('gs-blackmarket:policeAlert', function(coords, alertData, title, message)
    -- Create alert blip
    local alpha = 250
    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, 50.0)
    
    SetBlipHighDetail(blip, true)
    SetBlipColour(blip, alertData.blipColor)
    SetBlipAlpha(blip, alpha)
    SetBlipAsShortRange(blip, true)
    
    -- Create marker blip
    local markerBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(markerBlip, alertData.blipSprite)
    SetBlipColour(markerBlip, alertData.blipColor)
    SetBlipScale(markerBlip, alertData.blipScale)
    SetBlipAsShortRange(markerBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(title)
    EndTextCommandSetBlipName(markerBlip)
    
    -- Show notification
    ShowNotification(title .. ': ' .. message)
    
    -- Remove blips after duration
    Citizen.CreateThread(function()
        local endTime = GetGameTimer() + (Config.PoliceAlert.blipDuration * 1000)
        local fadeTime = endTime - 5000
        
        while GetGameTimer() < endTime do
            Citizen.Wait(100)
            
            if GetGameTimer() > fadeTime then
                local newAlpha = math.floor((endTime - GetGameTimer()) / 5000 * 250)
                SetBlipAlpha(blip, newAlpha)
            end
        end
        
        RemoveBlip(blip)
        RemoveBlip(markerBlip)
    end)
end)

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('placeOrder', function(data, cb)
    -- Play transaction animation
    PlayTransactionAnimation()
    
    TriggerServerEvent('gs-blackmarket:placeOrder', data.item, data.quantity)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('checkoutCart', function(data, cb)
    local items = data.items
    
    if not items or #items == 0 then
        ShowNotification("Your cart is empty", "error")
        cb('ok')
        return
    end
    
    -- Play phone animation (ordering)
    PlayPhoneAnimation(3000)
    
    -- Wait for animation to complete before sending the event
    Citizen.SetTimeout(3000, function()
        TriggerServerEvent('gs-blackmarket:checkoutCart', items)
    end)
    
    cb('ok')
end)

RegisterNUICallback('changeCategory', function(data, cb)
    currentCategory = data.category
    
    -- Update the vendor ped if using category-specific peds
    if Config.UseCategoryPeds and vendorPed then
        DeletePed(vendorPed)
        CreateVendorPed()
    end
    
    cb('ok')
end)

-- Events
RegisterNetEvent('gs-blackmarket:notification')
AddEventHandler('gs-blackmarket:notification', function(message, type)
    ShowNotification(message, type)
end)

RegisterNetEvent('gs-blackmarket:setVendorLocation')
AddEventHandler('gs-blackmarket:setVendorLocation', function(location)
    currentVendorLocation = location
    
    if vendorPed then
        DeletePed(vendorPed)
        vendorPed = nil
    end
    
    CreateVendorPed()
end)

RegisterNetEvent('gs-blackmarket:setMarketItems')
AddEventHandler('gs-blackmarket:setMarketItems', function(cats, multipliers)
    -- Process items and add images
    for _, category in pairs(cats) do
        for _, item in pairs(category.items) do
            item.image = GetItemImage(item.name)
        end
    end
    
    -- Send complete data to NUI
    SendNUIMessage({
        action = 'openMenu',
        categories = cats,
        priceMultipliers = multipliers,
        config = Config.UI
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('gs-blackmarket:updatePrices')
AddEventHandler('gs-blackmarket:updatePrices', function(multipliers)
    currentPriceMultipliers = multipliers
end)

RegisterNetEvent('gs-blackmarket:orderPlaced')
AddEventHandler('gs-blackmarket:orderPlaced', function(orderData)
    activeOrder = orderData
    
    -- Wait for delivery time
    Citizen.SetTimeout(orderData.waitTime * 1000, function()
        -- Create pickup point
        CreatePickupBlip(orderData.location.coords)
        CreatePickupPed(orderData.location)
        
        -- Notify player
        ShowNotification(Config.Notifications.orderReady, 'success')
    end)
end)

-- Resource Start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- Request vendor location from server
    Citizen.Wait(1000) -- Wait for server to initialize
    TriggerServerEvent('gs-blackmarket:getVendorLocation')
end)

RegisterNetEvent('playerSpawned')
AddEventHandler('playerSpawned', function()
    -- Request vendor location from server when player spawns
    TriggerServerEvent('gs-blackmarket:getVendorLocation')
end)


AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- Clean up resources
    if vendorPed then
        DeleteEntity(vendorPed)
        vendorPed = nil
    end
    
    CleanupPickup()
end)
