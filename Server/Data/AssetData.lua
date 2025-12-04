-- AssetData.lua - Properties, Vehicles, and Items
-- All purchasable assets with values and effects

local AssetData = {}

--============================================================================
-- PROPERTIES
--============================================================================
AssetData.Properties = {
    -- STARTER HOMES
    studio_apartment = {
        id = "studio_apartment",
        name = "Studio Apartment",
        description = "Small but cozy starter place",
        type = "apartment",
        category = "starter",
        price = 80000,
        downPayment = 16000,
        monthlyMortgage = 600,
        annualTax = 1200,
        maintenance = 100,
        appreciationRate = 0.02,
        happiness = 5,
        prestige = 1,
        canRent = true,
        rentPrice = 1200
    },
    
    one_bedroom = {
        id = "one_bedroom",
        name = "1-Bedroom Apartment",
        description = "Perfect for a single person or couple",
        type = "apartment",
        category = "starter",
        price = 150000,
        downPayment = 30000,
        monthlyMortgage = 1000,
        annualTax = 2000,
        maintenance = 150,
        appreciationRate = 0.025,
        happiness = 8,
        prestige = 2,
        canRent = true,
        rentPrice = 1800
    },
    
    -- REGULAR HOMES
    starter_house = {
        id = "starter_house",
        name = "Starter Home",
        description = "A modest single-family home",
        type = "house",
        category = "regular",
        price = 250000,
        downPayment = 50000,
        monthlyMortgage = 1500,
        annualTax = 3500,
        maintenance = 300,
        appreciationRate = 0.03,
        happiness = 12,
        prestige = 3,
        bedrooms = 3,
        bathrooms = 2
    },
    
    suburban_house = {
        id = "suburban_house",
        name = "Suburban Family Home",
        description = "Classic suburban living with a yard",
        type = "house",
        category = "regular",
        price = 400000,
        downPayment = 80000,
        monthlyMortgage = 2200,
        annualTax = 5000,
        maintenance = 400,
        appreciationRate = 0.03,
        happiness = 18,
        prestige = 5,
        bedrooms = 4,
        bathrooms = 2.5
    },
    
    -- LUXURY HOMES
    luxury_condo = {
        id = "luxury_condo",
        name = "Luxury Condo",
        description = "High-rise living with amenities",
        type = "condo",
        category = "luxury",
        price = 800000,
        downPayment = 160000,
        monthlyMortgage = 4500,
        annualTax = 10000,
        maintenance = 800,
        appreciationRate = 0.025,
        happiness = 25,
        prestige = 8,
        bedrooms = 3,
        bathrooms = 3,
        amenities = {"Pool", "Gym", "Doorman"}
    },
    
    mansion = {
        id = "mansion",
        name = "Mansion",
        description = "Living large in luxury",
        type = "mansion",
        category = "luxury",
        price = 3000000,
        downPayment = 600000,
        monthlyMortgage = 15000,
        annualTax = 40000,
        maintenance = 5000,
        appreciationRate = 0.02,
        happiness = 40,
        prestige = 15,
        bedrooms = 8,
        bathrooms = 6,
        amenities = {"Pool", "Home Theater", "Wine Cellar", "Guest House"}
    },
    
    penthouse = {
        id = "penthouse",
        name = "Penthouse Suite",
        description = "The ultimate city living",
        type = "penthouse",
        category = "ultra_luxury",
        price = 5000000,
        downPayment = 1000000,
        monthlyMortgage = 25000,
        annualTax = 60000,
        maintenance = 8000,
        appreciationRate = 0.015,
        happiness = 50,
        prestige = 20,
        bedrooms = 5,
        bathrooms = 5,
        amenities = {"Private Elevator", "Rooftop Terrace", "Panoramic Views"}
    },
    
    castle = {
        id = "castle",
        name = "Castle",
        description = "Live like royalty in an actual castle",
        type = "castle",
        category = "ultra_luxury",
        price = 25000000,
        downPayment = 5000000,
        monthlyMortgage = 100000,
        annualTax = 200000,
        maintenance = 50000,
        appreciationRate = 0.01,
        happiness = 60,
        prestige = 40,
        bedrooms = 20,
        bathrooms = 15,
        amenities = {"Moat", "Tower", "Ballroom", "Dungeon", "Helipad"}
    },
    
    -- VACATION PROPERTIES
    beach_house = {
        id = "beach_house",
        name = "Beach House",
        description = "Oceanfront getaway",
        type = "vacation",
        category = "vacation",
        price = 1200000,
        downPayment = 240000,
        monthlyMortgage = 6500,
        annualTax = 15000,
        maintenance = 3000,
        appreciationRate = 0.02,
        happiness = 30,
        prestige = 10,
        canRent = true,
        rentPrice = 5000
    },
    
    ski_chalet = {
        id = "ski_chalet",
        name = "Ski Chalet",
        description = "Mountain retreat",
        type = "vacation",
        category = "vacation",
        price = 900000,
        downPayment = 180000,
        monthlyMortgage = 5000,
        annualTax = 12000,
        maintenance = 2500,
        appreciationRate = 0.02,
        happiness = 25,
        prestige = 8,
        canRent = true,
        rentPrice = 4000
    },
    
    private_island = {
        id = "private_island",
        name = "Private Island",
        description = "Your own paradise",
        type = "island",
        category = "ultra_luxury",
        price = 50000000,
        downPayment = 10000000,
        monthlyMortgage = 200000,
        annualTax = 500000,
        maintenance = 100000,
        appreciationRate = 0.01,
        happiness = 80,
        prestige = 50
    }
}

--============================================================================
-- VEHICLES
--============================================================================
AssetData.Vehicles = {
    -- ECONOMY
    used_sedan = {
        id = "used_sedan",
        name = "Used Sedan",
        description = "Gets you from A to B",
        type = "car",
        category = "economy",
        price = 8000,
        annualInsurance = 800,
        annualMaintenance = 1200,
        fuelCost = 150, -- Monthly
        depreciationRate = 0.15,
        happiness = 5,
        prestige = 1
    },
    
    compact_car = {
        id = "compact_car",
        name = "Compact Car",
        description = "Reliable and fuel efficient",
        type = "car",
        category = "economy",
        price = 20000,
        annualInsurance = 1200,
        annualMaintenance = 800,
        fuelCost = 100,
        depreciationRate = 0.12,
        happiness = 8,
        prestige = 2
    },
    
    -- MID-RANGE
    suv = {
        id = "suv",
        name = "SUV",
        description = "Space and capability",
        type = "car",
        category = "midrange",
        price = 45000,
        annualInsurance = 1800,
        annualMaintenance = 1000,
        fuelCost = 200,
        depreciationRate = 0.10,
        happiness = 12,
        prestige = 4
    },
    
    pickup_truck = {
        id = "pickup_truck",
        name = "Pickup Truck",
        description = "Work and play utility",
        type = "truck",
        category = "midrange",
        price = 50000,
        annualInsurance = 1600,
        annualMaintenance = 1200,
        fuelCost = 250,
        depreciationRate = 0.10,
        happiness = 12,
        prestige = 4
    },
    
    -- LUXURY
    luxury_sedan = {
        id = "luxury_sedan",
        name = "Luxury Sedan",
        description = "Premium comfort and style",
        type = "car",
        category = "luxury",
        price = 80000,
        annualInsurance = 3000,
        annualMaintenance = 2000,
        fuelCost = 200,
        depreciationRate = 0.15,
        happiness = 20,
        prestige = 8
    },
    
    sports_car = {
        id = "sports_car",
        name = "Sports Car",
        description = "Speed and style",
        type = "car",
        category = "luxury",
        price = 120000,
        annualInsurance = 5000,
        annualMaintenance = 3000,
        fuelCost = 300,
        depreciationRate = 0.15,
        happiness = 25,
        prestige = 10
    },
    
    -- SUPERCARS
    supercar = {
        id = "supercar",
        name = "Supercar",
        description = "Peak automotive engineering",
        type = "car",
        category = "supercar",
        price = 300000,
        annualInsurance = 15000,
        annualMaintenance = 10000,
        fuelCost = 400,
        depreciationRate = 0.10,
        happiness = 35,
        prestige = 15
    },
    
    hypercar = {
        id = "hypercar",
        name = "Hypercar",
        description = "The ultimate driving machine",
        type = "car",
        category = "supercar",
        price = 2000000,
        annualInsurance = 50000,
        annualMaintenance = 30000,
        fuelCost = 500,
        depreciationRate = 0.05,
        happiness = 50,
        prestige = 25
    },
    
    -- MOTORCYCLES
    motorcycle = {
        id = "motorcycle",
        name = "Motorcycle",
        description = "Freedom on two wheels",
        type = "motorcycle",
        category = "motorcycle",
        price = 15000,
        annualInsurance = 1000,
        annualMaintenance = 500,
        fuelCost = 50,
        depreciationRate = 0.10,
        happiness = 15,
        prestige = 3,
        deathRisk = 0.001 -- Per year
    },
    
    sport_bike = {
        id = "sport_bike",
        name = "Sport Bike",
        description = "Fast and dangerous",
        type = "motorcycle",
        category = "motorcycle",
        price = 30000,
        annualInsurance = 2500,
        annualMaintenance = 1000,
        fuelCost = 80,
        depreciationRate = 0.12,
        happiness = 20,
        prestige = 5,
        deathRisk = 0.003
    },
    
    -- BOATS
    speedboat = {
        id = "speedboat",
        name = "Speedboat",
        description = "Fun on the water",
        type = "boat",
        category = "boat",
        price = 50000,
        annualInsurance = 2000,
        annualMaintenance = 3000,
        storage = 200, -- Monthly
        depreciationRate = 0.08,
        happiness = 20,
        prestige = 6
    },
    
    yacht = {
        id = "yacht",
        name = "Yacht",
        description = "Sailing in style",
        type = "boat",
        category = "boat",
        price = 500000,
        annualInsurance = 15000,
        annualMaintenance = 25000,
        crew = 50000, -- Annual
        depreciationRate = 0.05,
        happiness = 40,
        prestige = 18
    },
    
    superyacht = {
        id = "superyacht",
        name = "Superyacht",
        description = "Floating palace",
        type = "boat",
        category = "boat",
        price = 20000000,
        annualInsurance = 400000,
        annualMaintenance = 1000000,
        crew = 500000,
        depreciationRate = 0.03,
        happiness = 60,
        prestige = 40
    },
    
    -- AIRCRAFT
    private_jet = {
        id = "private_jet",
        name = "Private Jet",
        description = "Travel the world in luxury",
        type = "aircraft",
        category = "aircraft",
        price = 10000000,
        annualInsurance = 200000,
        annualMaintenance = 500000,
        crew = 300000,
        depreciationRate = 0.08,
        happiness = 50,
        prestige = 35
    },
    
    helicopter = {
        id = "helicopter",
        name = "Helicopter",
        description = "Beat traffic forever",
        type = "aircraft",
        category = "aircraft",
        price = 3000000,
        annualInsurance = 80000,
        annualMaintenance = 100000,
        depreciationRate = 0.08,
        happiness = 35,
        prestige = 20
    }
}

--============================================================================
-- ITEMS / ACCESSORIES
--============================================================================
AssetData.Items = {
    -- JEWELRY
    watch = {
        id = "watch",
        name = "Luxury Watch",
        description = "A fine timepiece",
        category = "jewelry",
        price = 5000,
        happiness = 5,
        prestige = 2,
        appreciationRate = 0.02
    },
    
    diamond_ring = {
        id = "diamond_ring",
        name = "Diamond Ring",
        description = "Sparkling diamond",
        category = "jewelry",
        price = 15000,
        happiness = 8,
        prestige = 4,
        appreciationRate = 0.01
    },
    
    designer_jewelry = {
        id = "designer_jewelry",
        name = "Designer Jewelry Set",
        description = "High-end jewelry collection",
        category = "jewelry",
        price = 50000,
        happiness = 15,
        prestige = 8,
        appreciationRate = 0.02
    },
    
    -- TECH
    gaming_setup = {
        id = "gaming_setup",
        name = "Gaming Setup",
        description = "Ultimate gaming rig",
        category = "tech",
        price = 5000,
        happiness = 10,
        prestige = 1,
        depreciationRate = 0.30
    },
    
    home_theater = {
        id = "home_theater",
        name = "Home Theater System",
        description = "Movie theater at home",
        category = "tech",
        price = 20000,
        happiness = 12,
        prestige = 3,
        depreciationRate = 0.15
    },
    
    -- PETS
    dog = {
        id = "dog",
        name = "Dog",
        description = "Man's best friend",
        category = "pet",
        price = 1000,
        annualCost = 1500,
        happiness = 15,
        prestige = 0
    },
    
    cat = {
        id = "cat",
        name = "Cat",
        description = "Independent companion",
        category = "pet",
        price = 500,
        annualCost = 1000,
        happiness = 10,
        prestige = 0
    },
    
    horse = {
        id = "horse",
        name = "Horse",
        description = "Majestic equine companion",
        category = "pet",
        price = 15000,
        annualCost = 10000,
        happiness = 20,
        prestige = 5
    },
    
    exotic_pet = {
        id = "exotic_pet",
        name = "Exotic Pet",
        description = "Unique and rare animal",
        category = "pet",
        price = 10000,
        annualCost = 5000,
        happiness = 15,
        prestige = 3,
        legal = false
    },
    
    -- COLLECTIBLES
    art_collection = {
        id = "art_collection",
        name = "Art Collection",
        description = "Fine art pieces",
        category = "collectible",
        price = 100000,
        happiness = 10,
        prestige = 10,
        appreciationRate = 0.05
    },
    
    wine_collection = {
        id = "wine_collection",
        name = "Wine Collection",
        description = "Rare vintage wines",
        category = "collectible",
        price = 50000,
        happiness = 5,
        prestige = 5,
        appreciationRate = 0.03
    },
    
    -- MISC
    designer_wardrobe = {
        id = "designer_wardrobe",
        name = "Designer Wardrobe",
        description = "High-end fashion collection",
        category = "fashion",
        price = 30000,
        happiness = 10,
        prestige = 5,
        looks = 5,
        depreciationRate = 0.20
    }
}

--============================================================================
-- HELPER FUNCTIONS
--============================================================================

-- Get property by ID
function AssetData.GetProperty(propertyId)
    return AssetData.Properties[propertyId]
end

-- Get vehicle by ID
function AssetData.GetVehicle(vehicleId)
    return AssetData.Vehicles[vehicleId]
end

-- Get item by ID
function AssetData.GetItem(itemId)
    return AssetData.Items[itemId]
end

-- Calculate property current value
function AssetData.CalculatePropertyValue(property, yearsOwned)
    local baseValue = property.price
    local rate = property.appreciationRate or 0.02
    return math.floor(baseValue * (1 + rate) ^ yearsOwned)
end

-- Calculate vehicle current value
function AssetData.CalculateVehicleValue(vehicle, yearsOwned)
    local baseValue = vehicle.price
    local rate = vehicle.depreciationRate or 0.10
    return math.floor(baseValue * (1 - rate) ^ yearsOwned)
end

-- Get affordable properties
function AssetData.GetAffordableProperties(money)
    local affordable = {}
    for id, property in pairs(AssetData.Properties) do
        if property.downPayment <= money then
            table.insert(affordable, property)
        end
    end
    return affordable
end

-- Get affordable vehicles
function AssetData.GetAffordableVehicles(money)
    local affordable = {}
    for id, vehicle in pairs(AssetData.Vehicles) do
        if vehicle.price <= money then
            table.insert(affordable, vehicle)
        end
    end
    return affordable
end

-- Calculate total annual cost
function AssetData.CalculateAnnualCost(asset)
    local cost = 0
    
    if asset.annualTax then cost = cost + asset.annualTax end
    if asset.maintenance then cost = cost + (asset.maintenance * 12) end
    if asset.monthlyMortgage then cost = cost + (asset.monthlyMortgage * 12) end
    if asset.annualInsurance then cost = cost + asset.annualInsurance end
    if asset.annualMaintenance then cost = cost + asset.annualMaintenance end
    if asset.fuelCost then cost = cost + (asset.fuelCost * 12) end
    if asset.storage then cost = cost + (asset.storage * 12) end
    if asset.crew then cost = cost + asset.crew end
    if asset.annualCost then cost = cost + asset.annualCost end
    
    return cost
end

return AssetData
