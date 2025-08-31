local Config = {}

local function LoadConfig()
    Config = exports[GetCurrentResourceName()]:GetConfig()
end

local isMenuOpen = false
local currentDealerData = nil
local currentDealerItems = nil
local playerCoords = nil
local dealerCoords = nil
local dealerBlips = {}
local dealerPeds = {}
local dealerZones = {}
local dealerCooldowns = {}
local lastPurchaseTime = 0
local purchaseCooldown = 1000
local isPlayerLoaded = false
local playerJob = nil
local playerGang = nil
local playerCitizenId = nil
local playerInventory = {}
local playerMoney = 0
local playerBankMoney = 0
local playerItems = {}

local QBCore = nil
local ESX = nil
local framework = nil

RegisterNetEvent('gs-blackmarket:client:openMenu')
RegisterNetEvent('gs-blackmarket:client:closeMenu')
RegisterNetEvent('gs-blackmarket:client:updatePrices')
RegisterNetEvent('gs-blackmarket:client:notifyPlayer')
RegisterNetEvent('gs-blackmarket:client:syncCooldown')

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
        local items = exports.ox_inventory:Items()
        if items[itemName] then
            return items[itemName].name
        end
    elseif inventoryType == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local item = QBCore.Shared.Items[itemName]
        if item then
            return item.image
        end
    elseif inventoryType == 'esx' then
        return itemName
    end
    
    return itemName
end

Citizen.CreateThread(function()
    LoadConfig()
    
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        framework = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        framework = 'esx'
    end
    
    if framework == 'qb' then
        Citizen.CreateThread(function()
            while true do
                if QBCore.Functions.GetPlayerData().citizenid ~= nil then
                    isPlayerLoaded = true
                    playerJob = QBCore.Functions.GetPlayerData().job
                    playerGang = QBCore.Functions.GetPlayerData().gang
                    playerCitizenId = QBCore.Functions.GetPlayerData().citizenid
                    break
                end
                Citizen.Wait(100)
            end
        end)
    elseif framework == 'esx' then
        Citizen.CreateThread(function()
            while ESX.GetPlayerData().job == nil do
                Citizen.Wait(100)
            end
            isPlayerLoaded = true
            playerJob = ESX.GetPlayerData().job
        end)
    end
    
    if Config.ShowBlips then
        for _, dealer in pairs(Config.Dealers) do
            if dealer.blip and dealer.blip.enabled then
                local blip = AddBlipForCoord(dealer.coords.x, dealer.coords.y, dealer.coords.z)
                SetBlipSprite(blip, dealer.blip.sprite or 500)
                SetBlipDisplay(blip, dealer.blip.display or 4)
                SetBlipScale(blip, dealer.blip.scale or 0.7)
                SetBlipColour(blip, dealer.blip.color or 1)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(dealer.blip.label or "Black Market")
                EndTextCommandSetBlipName(blip)
                
                table.insert(dealerBlips, blip)
            end
        end
    end
    
    if Config.ShowPeds then
        Citizen.CreateThread(function()
            for _, dealer in pairs(Config.Dealers) do
                if dealer.ped and dealer.ped.enabled then
                    RequestModel(dealer.ped.model or `a_m_y_mexthug_01`)
                    while not HasModelLoaded(dealer.ped.model or `a_m_y_mexthug_01`) do
                        Citizen.Wait(10)
                    end
                    
                    local ped = CreatePed(4, dealer.ped.model or `a_m_y_mexthug_01`, dealer.coords.x, dealer.coords.y, dealer.coords.z - 1.0, dealer.coords.w or 0.0, false, false)
                    FreezeEntityPosition(ped, true)
                    SetEntityInvincible(ped, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    
                    if dealer.ped.scenario then
                        TaskStartScenarioInPlace(ped, dealer.ped.scenario, 0, true)
                    end
                    
                    table.insert(dealerPeds, ped)
                end
            end
        end)
    end
    
    Citizen.CreateThread(function()
        while true do
            local playerPed = PlayerPedId()
            playerCoords = GetEntityCoords(playerPed)
            
            local isNearDealer = false
            local closestDealer = nil
            local closestDistance = 1000.0
            
            for i, dealer in pairs(Config.Dealers) do
                dealerCoords = vector3(dealer.coords.x, dealer.coords.y, dealer.coords.z)
                local distance = #(playerCoords - dealerCoords)
                
                if distance < closestDistance then
                    closestDistance = distance
                    closestDealer = dealer
                end
                
                if distance < dealer.interactionDistance then
                    isNearDealer = true
                    
                    local canAccess = true
                    
                    if dealer.jobs and #dealer.jobs > 0 then
                        canAccess = false
                        for _, job in pairs(dealer.jobs) do
                            if playerJob and playerJob.name == job then
                                canAccess = true
                                break
                            end
                        end
                    end
                    
                    if dealer.gangs and #dealer.gangs > 0 then
                        canAccess = false
                        for _, gang in pairs(dealer.gangs) do
                            if playerGang and playerGang.name == gang then
                                canAccess = true
                                break
                            end
                        end
                    end
                    
                    local dealerId = dealer.id or i
                    local cooldownTime = dealerCooldowns[dealerId] or 0
                    local currentTime = GetGameTimer()
                    local isOnCooldown = currentTime < cooldownTime
                    
                    if canAccess and not isOnCooldown and not isMenuOpen then
                        DrawText3D(dealerCoords.x, dealerCoords.y, dealerCoords.z, dealer.interactionText or "Press ~g~E~w~ to access Black Market")
                        
                        if IsControlJustReleased(0, 38) then
                            currentDealerData = dealer
                            currentDealerItems = dealer.items
                            OpenBlackMarketMenu()
                        end
                    elseif isOnCooldown then
                        local remainingTime = math.ceil((cooldownTime - currentTime) / 1000)
                        DrawText3D(dealerCoords.x, dealerCoords.y, dealerCoords.z, "Come back later. Cooldown: " .. remainingTime .. "s")
                    elseif not canAccess then
                        DrawText3D(dealerCoords.x, dealerCoords.y, dealerCoords.z, "You don't have access to this dealer")
                    end
                end
            end
            
            Citizen.Wait(isNearDealer and 0 or 500)
        end
    end)
end)

local function ProcessItems(items)
    local processedItems = {}
    for i, item in pairs(items) do
        local newItem = table.clone(item)
        newItem.image = GetItemImage(item.name)
        table.insert(processedItems, newItem)
    end
    return processedItems
end

function OpenBlackMarketMenu()
    if isMenuOpen then return end
    
    isMenuOpen = true
    
    local processedItems = ProcessItems(currentDealerItems)
    
    TriggerServerEvent('gs-blackmarket:server:getPriceMultipliers', currentDealerData.id)
    
    SendNUIMessage({
        action = 'openMenu',
        items = processedItems,
        priceMultipliers = {}
    })
    
    SetNuiFocus(true, true)
end

function CloseBlackMarketMenu()
    if not isMenuOpen then return end
    
    isMenuOpen = false
    currentDealerData = nil
    currentDealerItems = nil
    
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = 'closeMenu'
    })
end

RegisterNUICallback('purchaseItem', function(data, cb)
    if not isMenuOpen or not currentDealerData then
        cb({ success = false, message = "Menu is not open" })
        return
    end
    
    local currentTime = GetGameTimer()
    if currentTime - lastPurchaseTime < purchaseCooldown then
        cb({ success = false, message = "Please wait before making another purchase" })
        return
    end
    
    lastPurchaseTime = currentTime
    
    TriggerServerEvent('gs-blackmarket:server:purchaseItem', {
        dealerId = currentDealerData.id,
        itemName = data.item,
        quantity = data.quantity,
        price = data.price
    })
    
    cb({ success = true, message = "Processing purchase..." })
end)

RegisterNUICallback('checkoutCart', function(data, cb)
    if not isMenuOpen or not currentDealerData then
        cb({ success = false, message = "Menu is not open" })
        return
    end
    
    local currentTime = GetGameTimer()
    if currentTime - lastPurchaseTime < purchaseCooldown then
        cb({ success = false, message = "Please wait before making another purchase" })
        return
    end
    
    lastPurchaseTime = currentTime
    
    TriggerServerEvent('gs-blackmarket:server:checkoutCart', {
        dealerId = currentDealerData.id,
        items = data.items,
        total = data.total
    })
    
    cb({ success = true, message = "Processing checkout..." })
end)

RegisterNUICallback('closeMenu', function(data, cb)
    CloseBlackMarketMenu()
    cb({})
end)

AddEventHandler('gs-blackmarket:client:openMenu', function(dealerId)
    for i, dealer in pairs(Config.Dealers) do
        if dealer.id == dealerId then
            currentDealerData = dealer
            currentDealerItems = dealer.items
            OpenBlackMarketMenu()
            break
        end
    end
end)

AddEventHandler('gs-blackmarket:client:closeMenu', function()
    CloseBlackMarketMenu()
end)

AddEventHandler('gs-blackmarket:client:updatePrices', function(priceMultipliers)
    SendNUIMessage({
        action = 'updatePrices',
        priceMultipliers = priceMultipliers
    })
end)

AddEventHandler('gs-blackmarket:client:notifyPlayer', function(data)
    if framework == 'qb' then
        QBCore.Functions.Notify(data.message, data.type)
    elseif framework == 'esx' then
        ESX.ShowNotification(data.message)
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(data.message)
        DrawNotification(false, false)
    end
end)

AddEventHandler('gs-blackmarket:client:syncCooldown', function(dealerId, cooldownTime)
    dealerCooldowns[dealerId] = GetGameTimer() + (cooldownTime * 1000)
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

function table.clone(org)
    local new = {}
    for key, value in pairs(org) do
        new[key] = value
    end
    return new
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for _, blip in pairs(dealerBlips) do
        RemoveBlip(blip)
    end
    
    for _, ped in pairs(dealerPeds) do
        DeleteEntity(ped)
    end
    
    if isMenuOpen then
        CloseBlackMarketMenu()
    end
end)