Config = {}

-- Framework Configuration
Config.Framework = 'qbcore' --  'esx', 'qbcore'

-- Inventory Configuration
Config.Inventory = 'ox' --  'ox', 'qb'

-- Target Configuration
Config.Target = 'qb' --  'ox', 'qb'

-- Police Jobs Configuration
Config.PoliceJobs = {'police', 'sheriff', 'fbi'} -- Jobs that receive alerts

-- Dispatch Configuration
Config.Dispatch = {
    system = 'ps-dispatch',             -- 'cd_dispatch', 'ps-dispatch', 'qb-dispatch', 'linden_outlawalert', 'custom'
    customEvent = 'your:customDispatchEvent',  -- Only used if system is set to 'custom'
    
    -- Alert details
    blackmarketPurchase = {
        code = '10-31',
        description = 'Suspicious Transaction',
        blipSprite = 67,
        blipColor = 1,
        blipScale = 1.0,
        blipLength = 60,          -- seconds
        sound = '10-31'
    },
    
    blackmarketPickup = {
        code = '10-60',
        description = 'Suspicious Handoff',
        blipSprite = 67,
        blipColor = 1,
        blipScale = 1.0,
        blipLength = 60,          -- seconds
        sound = '10-60'
    }
}

-- UI Configuration
Config.UI = {
    title = "Black Market",
    theme = {
        primary = "#121212",     -- Dark background
        secondary = "#3498db",   -- Blue
        accent = "#9b59b6",      -- Purple
        text = "#ffffff",        -- White
        background = "#0a0a0a"   -- Very dark background
    }
}

-- Ped Configuration
Config.UseCategoryPeds = true -- If true, uses category-specific peds; if false, uses the location's default ped
Config.DefaultPed = "s_m_y_dealer_01" -- Fallback ped model if location has no ped defined

-- Market Configuration
Config.MarketFluctuation = {
    enabled = true,
    minMultiplier = 0.8,  -- Minimum price multiplier
    maxMultiplier = 1.5,  -- Maximum price multiplier
    changeInterval = 3600 -- Seconds between price changes (1 hour)
}

Config.VendorLocations = {
    {
        coords = vector3(2482.5471, 3722.4255, 43.9216),  -- Sandy Shores scrapyard
        heading = 41.9081,
        scenario = "WORLD_HUMAN_SMOKING",
        ped = "g_m_m_chemwork_01"
    },
    {
        coords = vector3(-1134.1439, -1568.7552, 4.4037),  -- Del Perro beach parking lot
        heading = 217.92,
        scenario = "WORLD_HUMAN_LEANING",
        ped = "g_m_y_lost_03"
    },
    {
        coords = vector3(85.86, -1959.48, 20.75),  -- Under Olympic Freeway
        heading = 320.5,
        scenario = "WORLD_HUMAN_STAND_IMPATIENT",
        ped = "s_m_y_dealer_01"
    },
    {
        coords = vector3(453.52, -3077.10, 6.07),  -- Elysian Island warehouse area
        heading = 357.0,
        scenario = "WORLD_HUMAN_CLIPBOARD",
        ped = "s_m_m_dockwork_01"
    },
    {
        coords = vector3(1533.9821, 3797.1023, 34.4516),  
        heading = 289.0539,
        scenario = "WORLD_HUMAN_AA_SMOKE",
        ped = "a_m_m_hillbilly_01"
    }


}


-- Pickup Locations (randomly selected for each order)
Config.PickupLocations = {
    {
        coords = vector3(1543.58, 3592.18, 38.77),
        heading = 115.0,
        scenario = "WORLD_HUMAN_GUARD_STAND",
        ped = "g_m_y_armgoon_02"
    },
    {
        coords = vector3(-1327.48, -1092.47, 6.99),
        heading = 114.5,
        scenario = "WORLD_HUMAN_GUARD_STAND",
        ped = "g_m_y_armgoon_02"
    },
    {
        coords = vector3(2340.65, 3126.46, 48.21),
        heading = 356.84,
        scenario = "WORLD_HUMAN_AA_SMOKE",
        ped = "g_m_y_salvagoon_01"
    },
    
    -- Paleto Bay area
    {
        coords = vector3(-159.95, 6409.42, 31.92),
        heading = 42.87,
        scenario = "WORLD_HUMAN_STAND_IMPATIENT",
        ped = "a_m_m_farmer_01"
    },
    {
        coords = vector3(-578.96, 5321.1, 70.21),
        heading = 339.62,
        scenario = "WORLD_HUMAN_DRUG_DEALERS_HARD",
        ped = "a_m_m_rurmeth_01"
    },
    
    -- Industrial areas
    {
        coords = vector3(1074.89, -2008.44, 32.08),
        heading = 235.14,
        scenario = "WORLD_HUMAN_GUARD_STAND",
        ped = "g_m_m_chemwork_01"
    },
    {
        coords = vector3(414.88, -2052.42, 22.17),
        heading = 54.09,
        scenario = "WORLD_HUMAN_GUARD_STAND",
        ped = "g_m_y_mexgoon_03"
    },
    {
        coords = vector3(760.85, -3195.93, 6.07),
        heading = 265.45,
        scenario = "WORLD_HUMAN_CLIPBOARD",
        ped = "s_m_m_dockwork_01"
    },
    
    -- Urban areas
    {
        coords = vector3(32.15, -1026.76, 29.56),
        heading = 155.24,
        scenario = "WORLD_HUMAN_STAND_IMPATIENT",
        ped = "s_m_y_robber_01"
    },
    {
        coords = vector3(485.48, -1529.43, 29.28),
        heading = 51.68,
        scenario = "WORLD_HUMAN_DRUG_DEALER",
        ped = "g_m_y_ballasout_01"
    },
    {
        coords = vector3(-628.47, -1634.89, 26.04),
        heading = 201.56,
        scenario = "WORLD_HUMAN_SMOKING",
        ped = "g_m_y_famca_01"
    },
    
    -- Secluded areas
    {
        coords = vector3(-1108.53, 4920.92, 217.46),
        heading = 254.87,
        scenario = "WORLD_HUMAN_GUARD_PATROL",
        ped = "g_m_m_armboss_01"
    },
    {
        coords = vector3(2482.51, -384.46, 94.39),
        heading = 82.56,
        scenario = "WORLD_HUMAN_STAND_MOBILE",
        ped = "g_m_y_korean_01"
    }
}

-- Black Market Categories with Specific Peds
Config.Categories = {
    {
        name = "weapons",
        label = "Weapons",
        icon = "gun",
        ped = "g_m_m_armboss_01",
        items = {
            {
                name = "weapon_pistol",
                label = "Pistol",
                description = "Standard 9mm pistol",
                basePrice = 1500
            },
            {
                name = "weapon_smg",
                label = "SMG",
                description = "Compact submachine gun",
                basePrice = 3500
            }
        }
    },
    {
        name = "ammo",
        label = "Ammunition",
        icon = "bullseye",
        ped = "s_m_y_ammucity_01",
        items = {
            {
                name = "pistol_ammo",
                label = "Pistol Ammo",
                description = "9mm ammunition",
                basePrice = 150
            },
            {
                name = "smg_ammo",
                label = "SMG Ammo",
                description = "SMG ammunition",
                basePrice = 250
            }
        }
    },
    {
        name = "drugs",
        label = "Pharmaceuticals",
        icon = "pills",
        ped = "g_m_y_mexgoon_03",
        items = {
            {
                name = "weed_brick",
                label = "Cannabis Package",
                description = "High-grade medicinal herbs",
                basePrice = 2000
            },
            {
                name = "coke_brick",
                label = "Powder Package",
                description = "Pharmaceutical grade powder",
                basePrice = 3500
            }
        }
    },
    {
        name = "tools",
        label = "Tools",
        icon = "tools",
        ped = "s_m_m_highsec_02",
        items = {
            {
                name = "lockpick",
                label = "Advanced Lockpick",
                description = "High quality lockpicking tool",
                basePrice = 500
            },
            {
                name = "hacking_device",
                label = "Hacking Device",
                description = "Electronic security bypass tool",
                basePrice = 1500
            }
        }
    }
}

-- Delivery Configuration
Config.Delivery = {
    waitTime = {min = 10, max = 20}, -- Seconds to wait for delivery (1-3 minutes)
    blipSettings = {
        sprite = 501,
        color = 1,
        scale = 0.8,
        label = "Package Pickup"
    },
    notificationDuration = 10000, -- 10 seconds
}

-- Notification Settings
Config.Notifications = {
    orderPlaced = "Your order has been placed. Wait for coordinates.",
    orderReady = "Your package is ready for pickup. Check your GPS.",
    orderCollected = "Package collected. Be careful with that.",
    notEnoughMoney = "You don't have enough money for this purchase.",
    inventoryFull = "Your pockets are too full to carry this.",
}

-- Police Alert Configuration
Config.PoliceAlert = {
    enabled = false,                -- Enable/disable police alerts
    chanceOnPurchase = 15,         -- Percentage chance of alerting police when placing an order (0-100)
    chanceOnPickup = 25,           -- Percentage chance of alerting police when collecting items (0-100)
    requiredCops = 0,              -- Minimum number of cops online for alerts to trigger
    cooldown = 10 * 60,            -- Cooldown between alerts in seconds (10 minutes)
    blipDuration = 60,             -- How long the alert blip remains on the map (seconds)
    alertTitle = "Suspicious Activity",
    alertMessage = "Reports of suspicious activity possibly related to illegal trading"
}
