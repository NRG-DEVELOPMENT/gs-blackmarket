Config = {}

-- General Settings
Config.Inventory = 'auto'  -- Options: 'auto', 'ox', 'qb', 'esx'
Config.PaymentMethod = 'cash'  -- Options: 'cash', 'bank'
Config.EnableCooldown = true  -- Enable cooldown between purchases
Config.DefaultCooldown = 300  -- Default cooldown in seconds (5 minutes)
Config.EnableLogs = true  -- Enable purchase logs
Config.ShowBlips = true  -- Show dealer blips on map
Config.ShowPeds = true  -- Show dealer peds

-- Price Fluctuation
Config.PriceFluctuation = {
    enabled = true,  -- Enable price fluctuation
    interval = 300000,  -- Interval in ms (5 minutes)
    minChange = 0.01,  -- Minimum price change (1%)
    maxChange = 0.05,  -- Maximum price change (5%)
    minMultiplier = 0.5,  -- Minimum price multiplier (50%)
    maxMultiplier = 1.5  -- Maximum price multiplier (150%)
}

-- Dealers
Config.Dealers = {
    {
        id = "weapons_dealer",
        name = "Weapons Dealer",
        coords = vector4(1248.47, -1580.18, 38.33, 39.94),
        interactionDistance = 2.0,
        interactionText = "Press ~g~E~w~ to access Weapons Dealer",
        cooldown = 600,  -- 10 minutes
        priceFluctuation = true,
        blip = {
            enabled = true,
            sprite = 110,
            color = 1,
            scale = 0.7,
            label = "Weapons Dealer"
        },
        ped = {
            enabled = true,
            model = `g_m_y_mexgoon_01`,
            scenario = "WORLD_HUMAN_SMOKING"
        },
        jobs = {},  -- Empty means available to everyone
        gangs = {},  -- Empty means available to everyone
        items = {
            {
                name = "weapon_pistol",
                label = "Pistol",
                description = "A standard handgun",
                price = 1000,
                image = "weapon_pistol"
            },
            {
                name = "weapon_smg",
                label = "SMG",
                description = "A submachine gun",
                price = 2500,
                image = "weapon_smg"
            },
            {
                name = "weapon_assaultrifle",
                label = "Assault Rifle",
                description = "A powerful assault rifle",
                price = 5000,
                image = "weapon_assaultrifle"
            },
            {
                name = "ammo-9",
                label = "9mm Ammo",
                description = "Standard ammunition for pistols",
                price = 50,
                image = "ammo-9"
            },
            {
                name = "ammo-rifle",
                label = "Rifle Ammo",
                description = "Standard ammunition for rifles",
                price = 100,
                image = "ammo-rifle"
            },
            {
                name = "armor",
                label = "Body Armor",
                description = "Protective vest",
                price = 500,
                image = "armor"
            }
        }
    },
    {
        id = "drug_dealer",
        name = "Drug Dealer",
        coords = vector4(2431.85, 4970.95, 42.35, 44.56),
        interactionDistance = 2.0,
        interactionText = "Press ~g~E~w~ to access Drug Dealer",
        cooldown = 300,  -- 5 minutes
        priceFluctuation = true,
        blip = {
            enabled = true,
            sprite = 140,
            color = 2,
            scale = 0.7,
            label = "Drug Dealer"
        },
        ped = {
            enabled = true,
            model = `a_m_y_mexthug_01`,
            scenario = "WORLD_HUMAN_DRUG_DEALER"
        },
        jobs = {},  -- Empty means available to everyone
        gangs = {},  -- Empty means available to everyone
        items = {
            {
                name = "weed_brick",
                label = "Weed Brick",
                description = "A brick of marijuana",
                price = 500,
                image = "weed_brick"
            },
            {
                name = "coke_brick",
                label = "Cocaine Brick",
                description = "A brick of cocaine",
                price = 1000,
                image = "coke_brick"
            },
            {
                name = "meth",
                label = "Meth",
                description = "Crystal methamphetamine",
                price = 750,
                image = "meth"
            },
            {
                name = "joint",
                label = "Joint",
                description = "A rolled marijuana cigarette",
                price = 50,
                image = "joint"
            },
            {
                name = "rolling_paper",
                label = "Rolling Paper",
                description = "Paper for rolling joints",
                price = 10,
                image = "rolling_paper"
            }
        }
    },
    {
        id = "hacker",
        name = "Hacker",
        coords = vector4(-1082.96, -248.46, 37.76, 206.78),
        interactionDistance = 2.0,
        interactionText = "Press ~g~E~w~ to access Hacker",
        cooldown = 900,  -- 15 minutes
        priceFluctuation = false,
        blip = {
            enabled = true,
            sprite = 521,
            color = 27,
            scale = 0.7,
            label = "Hacker"
        },
        ped = {
            enabled = true,
            model = `ig_lestercrest`,
            scenario = "WORLD_HUMAN_STAND_MOBILE"
        },
        jobs = {},  -- Empty means available to everyone
        gangs = {},  -- Empty means available to everyone
        items = {
            {
                name = "trojan_usb",
                label = "Trojan USB",
                description = "USB drive with hacking software",
                price = 2000,
                image = "trojan_usb"
            },
            {
                name = "laptop",
                label = "Laptop",
                description = "A laptop for hacking",
                price = 3000,
                image = "laptop"
            },
            {
                name = "phone_hack",
                label = "Phone Hacker",
                description = "Device to hack phones",
                price = 1500,
                image = "phone_hack"
            },
            {
                name = "secure_card",
                label = "Secure Card",
                description = "Card for bypassing security systems",
                price = 5000,
                image = "secure_card"
            }
        }
    },
    {
        id = "document_forger",
        name = "Document Forger",
        coords = vector4(1165.55, -3196.68, -39.01, 90.59),
        interactionDistance = 2.0,
        interactionText = "Press ~g~E~w~ to access Document Forger",
        cooldown = 1200,  -- 20 minutes
        priceFluctuation = false,
        blip = {
            enabled = false
        },
        ped = {
            enabled = true,
            model = `a_m_m_business_01`,
            scenario = "WORLD_HUMAN_CLIPBOARD"
        },
        jobs = {},  -- Empty means available to everyone
        gangs = {},  -- Empty means available to everyone
        items = {
            {
                name = "fake_id",
                label = "Fake ID",
                description = "Forged identification document",
                price = 5000,
                image = "fake_id"
            },
            {
                name = "fake_license",
                label = "Fake License",
                description = "Forged driver's license",
                price = 7500,
                image = "fake_license"
            },
            {
                name = "fake_passport",
                label = "Fake Passport",
                description = "Forged passport",
                price = 10000,
                image = "fake_passport"
            }
        }
    },
    {
        id = "vehicle_parts",
        name = "Vehicle Parts Dealer",
        coords = vector4(731.54, -1088.67, 22.17, 84.36),
        interactionDistance = 2.0,
        interactionText = "Press ~g~E~w~ to access Vehicle Parts",
        cooldown = 300,  -- 5 minutes
        priceFluctuation = true,
        blip = {
            enabled = true,
            sprite = 326,
            color = 5,
            scale = 0.7,
            label = "Vehicle Parts"
        },
        ped = {
            enabled = true,
            model = `s_m_m_autoshop_01`,
            scenario = "WORLD_HUMAN_CLIPBOARD"
        },
        jobs = {},  -- Empty means available to everyone
        gangs = {},  -- Empty means available to everyone
        items = {
            {
                name = "turbo",
                label = "Turbo Kit",
                description = "Performance turbo kit",
                price = 15000,
                image = "turbo"
            },
            {
                name = "nitrous",
                label = "Nitrous Oxide",
                description = "NOS system for extra speed",
                price = 10000,
                image = "nitrous"
            },
            {
                name = "engine_parts",
                label = "Engine Parts",
                description = "High-performance engine components",
                price = 7500,
                image = "engine_parts"
            },
            {
                name = "transmission",
                label = "Racing Transmission",
                description = "High-performance transmission",
                price = 12000,
                image = "transmission"
            },
            {
                name = "bulletproof_tires",
                label = "Bulletproof Tires",
                description = "Tires resistant to punctures",
                price = 5000,
                image = "bulletproof_tires"
            }
        }
    }
}