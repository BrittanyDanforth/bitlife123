--[[
    Vehicle Events - CRITICAL FIX #932
    Car-based events that depend on what vehicle you own
    Includes: Racing, traffic incidents, customization, road trips, breakdowns
    
    Vehicle quality tiers:
    - Economy: Old beaters, basic cars (value < 15000)
    - Standard: Normal cars (value 15000-40000)
    - Sport: Fast cars, sports cars (value 40000-100000)
    - Luxury: Premium vehicles (value 100000-250000)
    - Exotic: Supercars, hypercars (value 250000+)
]]

local VehicleEvents = {}

-- Helper function to get player's best vehicle and tier
local function getPlayerVehicle(state)
    if not state.Assets or not state.Assets.Vehicles then
        return nil, nil
    end
    
    local vehicles = state.Assets.Vehicles
    if type(vehicles) ~= "table" or #vehicles == 0 then
        return nil, nil
    end
    
    -- Find the best/most valuable vehicle
    local bestVehicle = vehicles[1]
    for _, v in ipairs(vehicles) do
        if v.value and bestVehicle.value and v.value > bestVehicle.value then
            bestVehicle = v
        end
    end
    
    -- Determine tier
    local value = bestVehicle.value or bestVehicle.price or 10000
    local tier = "economy"
    if value >= 250000 then
        tier = "exotic"
    elseif value >= 100000 then
        tier = "luxury"
    elseif value >= 40000 then
        tier = "sport"
    elseif value >= 15000 then
        tier = "standard"
    end
    
    return bestVehicle, tier
end

-- Check if player has any car
local function hasVehicle(state)
    local flags = state.Flags or {}
    if flags.has_car or flags.owns_car or flags.has_vehicle or flags.has_first_car then
        return true
    end
    if state.Assets and state.Assets.Vehicles then
        if type(state.Assets.Vehicles) == "table" and #state.Assets.Vehicles > 0 then
            return true
        end
    end
    return false
end

VehicleEvents.events = {
    -- ══════════════════════════════════════════════════════════════════════════════
    -- STREET RACING EVENTS - Outcomes depend on car quality!
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "vehicle_street_race_challenge",
        title = "Street Race Challenge!",
        emoji = "🏎️",
        text = "While stopped at a red light, someone in a sports car revs their engine at you challengingly.",
        textVariants = {
            "A flashy car pulls up next to you at the light and the driver gives you a smirk.",
            "Someone in a souped-up ride is clearly trying to race you!",
            "The car next to you revs loudly - it's an invitation to race!",
            "A stranger challenges you to a race at the stoplight!",
        },
        question = "Do you accept the street race?",
        minAge = 18, maxAge = 55,
        baseChance = 0.35,
        cooldown = 4,
        category = "vehicle",
        tags = { "racing", "car", "risk", "street" },
        blockedByFlags = { in_prison = true, incarcerated = true },
        eligibility = function(state)
            return hasVehicle(state), "Need a car to race"
        end,
        
        choices = {
            {
                text = "Accept the challenge! 🏁",
                effects = {},
                feedText = "You rev your engine...",
                onResolve = function(state)
                    local vehicle, tier = getPlayerVehicle(state)
                    local vehicleName = vehicle and vehicle.name or "your car"
                    local roll = math.random()
                    
                    -- Win chances based on vehicle tier
                    local winChance = 0.20 -- Base 20% chance
                    if tier == "exotic" then winChance = 0.85
                    elseif tier == "luxury" then winChance = 0.70
                    elseif tier == "sport" then winChance = 0.60
                    elseif tier == "standard" then winChance = 0.35
                    else winChance = 0.15 end -- economy
                    
                    -- Add some skill variance
                    local smarts = (state.Stats and state.Stats.Smarts) or 50
                    winChance = winChance + (smarts / 500) -- Small boost for smart driving
                    
                    if roll < winChance * 0.7 then
                        -- WIN! Glory and bragging rights
                        state:ModifyStat("Happiness", 15)
                        state.Flags = state.Flags or {}
                        state.Flags.street_racer = true
                        state.Flags.race_winner = true
                        local prize = math.random(100, 500)
                        state.Money = (state.Money or 0) + prize
                        state:AddFeed(string.format("🏎️ YOU WON! %s smoked them! They handed over $%d in shame! What a rush!", vehicleName, prize))
                    elseif roll < winChance then
                        -- Close win
                        state:ModifyStat("Happiness", 10)
                        state.Flags = state.Flags or {}
                        state.Flags.street_racer = true
                        state:AddFeed(string.format("🏎️ Photo finish but YOU WIN! %s barely pulled ahead! Heart pounding!", vehicleName))
                    elseif roll < 0.85 then
                        -- Lost but safe
                        state:ModifyStat("Happiness", -5)
                        state:AddFeed(string.format("🏎️ You lost! %s just couldn't keep up. Embarrassing...", vehicleName))
                    elseif roll < 0.95 then
                        -- Lost AND got a ticket
                        state:ModifyStat("Happiness", -8)
                        state.Money = math.max(0, (state.Money or 0) - 350)
                        state.Flags = state.Flags or {}
                        state.Flags.speeding_ticket = true
                        state:AddFeed("🏎️ Lost the race AND got pulled over! $350 speeding ticket! Terrible decision!")
                    else
                        -- Crash!
                        state:ModifyStat("Happiness", -15)
                        state:ModifyStat("Health", -10)
                        state.Money = math.max(0, (state.Money or 0) - 2000)
                        state:AddFeed(string.format("🏎️ CRASHED! %s is wrecked! Hospital bills and repair costs! Never again!", vehicleName))
                    end
                end,
            },
            {
                text = "Ignore them - not worth the risk",
                effects = { Happiness = 2 },
                feedText = "🏎️ You kept your cool. Smart choice - they sped off and probably got a ticket.",
            },
            {
                text = "Wave them off and laugh",
                effects = { Happiness = 3 },
                feedText = "🏎️ You're not that immature. Let them have their fun alone.",
            },
        },
    },
    
    {
        id = "vehicle_organized_race",
        title = "Underground Racing Event",
        emoji = "🏁",
        text = "You hear about an underground street racing event happening tonight. Big money on the line.",
        question = "Entry fee is $500. Your car determines your class. Join?",
        minAge = 18, maxAge = 50,
        baseChance = 0.25,
        cooldown = 5,
        category = "vehicle",
        tags = { "racing", "underground", "gambling", "risk" },
        blockedByFlags = { in_prison = true, incarcerated = true },
        eligibility = function(state)
            if not hasVehicle(state) then return false, "Need a car to race" end
            if (state.Money or 0) < 500 then return false, "Need $500 entry fee" end
            return true
        end,
        
        choices = {
            {
                text = "Enter the race! ($500)",
                effects = { Money = -500 },
                feedText = "You pay the entry fee and line up...",
                onResolve = function(state)
                    local vehicle, tier = getPlayerVehicle(state)
                    local vehicleName = vehicle and vehicle.name or "your car"
                    local roll = math.random()
                    
                    -- Prize pool varies by tier class
                    local prizePool = 2000
                    local winChance = 0.25 -- Base chance
                    
                    if tier == "exotic" then 
                        prizePool = 15000
                        winChance = 0.50 -- Exotic cars dominate their class
                    elseif tier == "luxury" then 
                        prizePool = 8000
                        winChance = 0.40
                    elseif tier == "sport" then 
                        prizePool = 5000
                        winChance = 0.35
                    elseif tier == "standard" then 
                        prizePool = 3000
                        winChance = 0.30
                    else 
                        prizePool = 1500
                        winChance = 0.20
                    end
                    
                    if roll < winChance then
                        -- First place!
                        state.Money = (state.Money or 0) + prizePool
                        state:ModifyStat("Happiness", 25)
                        state.Flags = state.Flags or {}
                        state.Flags.street_racer = true
                        state.Flags.race_champion = true
                        state:AddFeed(string.format("🏁 FIRST PLACE! %s DOMINATED! Won $%d! You're the champion!", vehicleName, prizePool))
                    elseif roll < winChance * 2 then
                        -- Second place
                        local secondPrize = math.floor(prizePool * 0.4)
                        state.Money = (state.Money or 0) + secondPrize
                        state:ModifyStat("Happiness", 12)
                        state:AddFeed(string.format("🏁 Second place! %s almost won! Took home $%d. Next time!", vehicleName, secondPrize))
                    elseif roll < winChance * 3 then
                        -- Third place
                        local thirdPrize = math.floor(prizePool * 0.2)
                        state.Money = (state.Money or 0) + thirdPrize
                        state:ModifyStat("Happiness", 5)
                        state:AddFeed(string.format("🏁 Third place. %s did okay. Won $%d. Need upgrades!", vehicleName, thirdPrize))
                    elseif roll < 0.90 then
                        -- Didn't place
                        state:ModifyStat("Happiness", -8)
                        state:AddFeed(string.format("🏁 Didn't place. %s couldn't keep up. Lost the entry fee!", vehicleName))
                    else
                        -- Police raid!
                        state:ModifyStat("Happiness", -15)
                        state.Money = math.max(0, (state.Money or 0) - 1000)
                        state.Flags = state.Flags or {}
                        state.Flags.arrested_racing = true
                        state:AddFeed("🏁 POLICE RAID! Everyone scattered! Lost your entry fee + $1000 fine! Close call!")
                    end
                end,
            },
            {
                text = "Watch from the sidelines",
                effects = { Happiness = 5 },
                feedText = "🏁 You watched the races. Exciting! Maybe next time you'll enter.",
            },
            {
                text = "Not my scene - too risky",
                effects = {},
                feedText = "🏁 Illegal racing isn't worth the risk. Good call.",
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- TRAFFIC INCIDENTS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "vehicle_road_rage",
        title = "Road Rage Incident",
        emoji = "😡",
        text = "Someone cut you off dangerously in traffic and then brake-checked you!",
        textVariants = {
            "A driver nearly hit you then flipped you off!",
            "Someone honked at you aggressively for no reason!",
            "A road rager is tailgating you and flashing their lights!",
            "Another driver is screaming obscenities at you through their window!",
        },
        question = "How do you respond?",
        minAge = 18, maxAge = 70,
        baseChance = 0.35,
        cooldown = 4,
        category = "vehicle",
        tags = { "traffic", "conflict", "anger" },
        blockedByFlags = { in_prison = true, incarcerated = true },
        eligibility = function(state)
            return hasVehicle(state), "Need a car"
        end,
        
        choices = {
            {
                text = "Confront them angrily",
                effects = {},
                feedText = "You roll down your window...",
                onResolve = function(state)
                    local roll = math.random()
                    if roll < 0.30 then
                        -- They back down
                        state:ModifyStat("Happiness", 5)
                        state:AddFeed("😡 They backed off! Your intimidation worked! Felt good!")
                    elseif roll < 0.60 then
                        -- Shouting match
                        state:ModifyStat("Happiness", -5)
                        state:ModifyStat("Health", -2)
                        state:AddFeed("😡 Ugly shouting match. Blood pressure through the roof. Not worth it.")
                    elseif roll < 0.85 then
                        -- They have a weapon/threaten
                        state:ModifyStat("Happiness", -10)
                        state:ModifyStat("Health", -3)
                        state:AddFeed("😡 They pulled something from their car! You sped away terrified! Never again!")
                    else
                        -- Physical altercation
                        state:ModifyStat("Happiness", -15)
                        state:ModifyStat("Health", -15)
                        state.Money = math.max(0, (state.Money or 0) - 500)
                        state:AddFeed("😡 It got physical! Fight in the street! Medical bills and regret!")
                    end
                end,
            },
            {
                text = "Take a deep breath and ignore them",
                effects = { Happiness = 3 },
                feedText = "😡 You let it go. Not worth ruining your day over bad drivers.",
            },
            {
                text = "Call the police non-emergency line",
                effects = { Happiness = 2 },
                feedText = "😡 You reported the dangerous driver. Did your civic duty.",
            },
            {
                text = "Change lanes and get away from them",
                effects = { Happiness = 1 },
                feedText = "😡 Smart move. Distance yourself from crazy drivers.",
            },
        },
    },
    
    {
        id = "vehicle_fender_bender",
        title = "Fender Bender!",
        emoji = "💥",
        text = "Someone just rear-ended you at a red light!",
        textVariants = {
            "A distracted driver just hit your car from behind!",
            "You were stopped and WHAM - someone hit you!",
            "Some idiot on their phone just rear-ended you!",
        },
        question = "What do you do?",
        minAge = 18, maxAge = 80,
        baseChance = 0.25,
        cooldown = 5,
        category = "vehicle",
        tags = { "accident", "insurance", "traffic" },
        blockedByFlags = { in_prison = true, incarcerated = true },
        eligibility = function(state)
            return hasVehicle(state), "Need a car"
        end,
        
        choices = {
            {
                text = "Exchange insurance info properly",
                effects = {},
                feedText = "Exchanging information...",
                onResolve = function(state)
                    local roll = math.random()
                    if roll < 0.60 then
                        -- Insurance covers it
                        state:ModifyStat("Happiness", -3)
                        state:AddFeed("💥 Minor damage but insurance covered it. Annoying hassle but resolved.")
                    elseif roll < 0.85 then
                        -- Some out of pocket
                        state:ModifyStat("Happiness", -8)
                        state.Money = math.max(0, (state.Money or 0) - 250)
                        state:AddFeed("💥 Insurance only covered part. $250 deductible. Frustrating day.")
                    else
                        -- They were uninsured
                        state:ModifyStat("Happiness", -12)
                        state.Money = math.max(0, (state.Money or 0) - 1500)
                        state:AddFeed("💥 They had no insurance! Had to pay $1500 for repairs yourself! Infuriating!")
                    end
                end,
            },
            {
                text = "Get upset and yell at them",
                effects = { Happiness = -5, Health = -2 },
                feedText = "💥 You lost your temper. Made the situation worse. Stressful day.",
            },
            {
                text = "Stay calm, take photos, document everything",
                effects = { Happiness = 2 },
                feedText = "💥 You handled it like a pro. Documentation saved you hassle later.",
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- CAR BREAKDOWN EVENTS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "vehicle_breakdown",
        title = "Car Broke Down!",
        emoji = "🔧",
        text = "Your car suddenly died on the side of the road!",
        textVariants = {
            "Smoke is coming from under the hood!",
            "Your car is making terrible grinding noises and won't start!",
            "The engine light came on and the car just... stopped.",
            "You're stranded on the highway with a dead car!",
        },
        question = "What do you do?",
        minAge = 18, maxAge = 80,
        baseChance = 0.30,
        cooldown = 5,
        category = "vehicle",
        tags = { "breakdown", "repair", "emergency" },
        blockedByFlags = { in_prison = true, incarcerated = true },
        eligibility = function(state)
            return hasVehicle(state), "Need a car"
        end,
        
        choices = {
            {
                text = "Call a tow truck and mechanic",
                effects = {},
                feedText = "Waiting for the tow truck...",
                onResolve = function(state)
                    local vehicle, tier = getPlayerVehicle(state)
                    local roll = math.random()
                    
                    -- Repair costs vary by vehicle tier (expensive cars = expensive repairs)
                    local baseCost = 200
                    if tier == "exotic" then baseCost = 2000
                    elseif tier == "luxury" then baseCost = 800
                    elseif tier == "sport" then baseCost = 500
                    elseif tier == "standard" then baseCost = 300
                    end
                    
                    if roll < 0.40 then
                        -- Minor fix
                        local cost = math.floor(baseCost * 0.5)
                        state.Money = math.max(0, (state.Money or 0) - cost)
                        state:ModifyStat("Happiness", -3)
                        state:AddFeed(string.format("🔧 Just a minor issue. $%d to fix. Back on the road!", cost))
                    elseif roll < 0.75 then
                        -- Moderate repair
                        local cost = baseCost
                        state.Money = math.max(0, (state.Money or 0) - cost)
                        state:ModifyStat("Happiness", -8)
                        state:AddFeed(string.format("🔧 Needed significant repair. $%d bill. Ouch!", cost))
                    else
                        -- Major repair
                        local cost = math.floor(baseCost * 2)
                        state.Money = math.max(0, (state.Money or 0) - cost)
                        state:ModifyStat("Happiness", -15)
                        state:AddFeed(string.format("🔧 Major engine work needed! $%d! Consider a new car...", cost))
                    end
                end,
            },
            {
                text = "Try to fix it yourself",
                effects = {},
                feedText = "Looking under the hood...",
                onResolve = function(state)
                    local smarts = (state.Stats and state.Stats.Smarts) or 50
                    local roll = math.random()
                    local canFix = roll < (smarts / 150) -- Smarter = better chance
                    
                    if canFix then
                        state:ModifyStat("Happiness", 8)
                        state:ModifyStat("Smarts", 2)
                        state.Flags = state.Flags or {}
                        state.Flags.car_mechanic = true
                        state:AddFeed("🔧 You figured it out! Fixed it yourself! Saved money and learned something!")
                    else
                        state:ModifyStat("Happiness", -10)
                        state:ModifyStat("Health", -2)
                        state.Money = math.max(0, (state.Money or 0) - 400)
                        state:AddFeed("🔧 Made it worse... Had to call a mechanic anyway. $400 and your pride.")
                    end
                end,
            },
            {
                text = "Call a friend for a ride",
                effects = { Happiness = -2 },
                feedText = "🔧 Friend picked you up. Still need to deal with the car later.",
            },
        },
    },
    
    {
        id = "vehicle_flat_tire",
        title = "Flat Tire!",
        emoji = "🛞",
        text = "You've got a flat tire!",
        question = "How do you handle it?",
        minAge = 18, maxAge = 80,
        baseChance = 0.35,
        cooldown = 4,
        category = "vehicle",
        tags = { "tire", "repair", "roadside" },
        blockedByFlags = { in_prison = true, incarcerated = true },
        eligibility = function(state)
            return hasVehicle(state), "Need a car"
        end,
        
        choices = {
            {
                text = "Change it yourself",
                effects = {},
                feedText = "Getting the spare out...",
                onResolve = function(state)
                    local health = (state.Stats and state.Stats.Health) or 50
                    local roll = math.random()
                    
                    if roll < 0.60 or health > 60 then
                        state:ModifyStat("Happiness", 5)
                        state:ModifyStat("Health", -1) -- Physical labor
                        state:AddFeed("🛞 Changed the tire yourself! Dirty hands but saved money!")
                    else
                        state:ModifyStat("Happiness", -5)
                        state:ModifyStat("Health", -5)
                        state:AddFeed("🛞 Struggled with it. Back hurts. Finally got it done though!")
                    end
                end,
            },
            {
                text = "Call roadside assistance ($50)",
                effects = { Money = -50, Happiness = 2 },
                feedText = "🛞 Roadside assistance handled it. Easy!",
            },
            {
                text = "Flag down help",
                effects = {},
                feedText = "Looking for help...",
                onResolve = function(state)
                    local looks = (state.Stats and state.Stats.Looks) or 50
                    local roll = math.random()
                    
                    if roll < 0.50 or looks > 70 then
                        state:ModifyStat("Happiness", 5)
                        state:AddFeed("🛞 A kind stranger stopped and helped! Faith in humanity restored!")
                    else
                        state:ModifyStat("Happiness", -5)
                        state:AddFeed("🛞 No one stopped. Had to figure it out alone. Disappointing.")
                    end
                end,
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- CAR CUSTOMIZATION & SHOWS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "vehicle_car_show",
        title = "Car Show Invitation",
        emoji = "🚗",
        text = "There's a local car show this weekend. Want to enter your ride?",
        question = "Entry fee is $100. Prizes for winners!",
        minAge = 18, maxAge = 70,
        baseChance = 0.30,
        cooldown = 5,
        category = "vehicle",
        tags = { "car_show", "hobby", "competition" },
        blockedByFlags = { in_prison = true, incarcerated = true },
        eligibility = function(state)
            if not hasVehicle(state) then return false, "Need a car" end
            if (state.Money or 0) < 100 then return false, "Need $100 entry fee" end
            return true
        end,
        
        choices = {
            {
                text = "Enter the show! ($100)",
                effects = { Money = -100 },
                feedText = "Polishing your ride for the show...",
                onResolve = function(state)
                    local vehicle, tier = getPlayerVehicle(state)
                    local vehicleName = vehicle and vehicle.name or "your car"
                    local roll = math.random()
                    
                    -- Better cars have better chances
                    local winChance = 0.15
                    if tier == "exotic" then winChance = 0.60
                    elseif tier == "luxury" then winChance = 0.45
                    elseif tier == "sport" then winChance = 0.35
                    elseif tier == "standard" then winChance = 0.20
                    end
                    
                    if roll < winChance then
                        -- Winner!
                        local prize = 500
                        if tier == "exotic" then prize = 2000
                        elseif tier == "luxury" then prize = 1000
                        elseif tier == "sport" then prize = 750
                        end
                        
                        state.Money = (state.Money or 0) + prize
                        state:ModifyStat("Happiness", 20)
                        state.Flags = state.Flags or {}
                        state.Flags.car_show_winner = true
                        state:AddFeed(string.format("🚗 %s WON BEST IN CLASS! $%d prize! Trophy on the mantle!", vehicleName, prize))
                    elseif roll < winChance * 2 then
                        -- Runner up
                        state.Money = (state.Money or 0) + 200
                        state:ModifyStat("Happiness", 10)
                        state:AddFeed(string.format("🚗 %s placed! Won $200. Great showing!", vehicleName))
                    else
                        -- Didn't place but fun
                        state:ModifyStat("Happiness", 5)
                        state:AddFeed(string.format("🚗 Didn't win but %s got lots of compliments! Fun day!", vehicleName))
                    end
                end,
            },
            {
                text = "Just attend and look at cars",
                effects = { Happiness = 8 },
                feedText = "🚗 Amazing cars everywhere! Got some ideas for your own ride.",
            },
            {
                text = "Not interested in car shows",
                effects = {},
                feedText = "🚗 Car shows aren't your thing. That's okay!",
            },
        },
    },
    
    {
        id = "vehicle_upgrade_offer",
        title = "Car Upgrade Opportunity",
        emoji = "🔧",
        text = "A mechanic friend offers to upgrade your car's performance for a good price.",
        question = "Upgrade costs $800. Could improve your car's value and speed.",
        minAge = 18, maxAge = 60,
        baseChance = 0.25,
        cooldown = 6,
        category = "vehicle",
        tags = { "upgrade", "modification", "performance" },
        blockedByFlags = { in_prison = true, incarcerated = true },
        eligibility = function(state)
            if not hasVehicle(state) then return false, "Need a car" end
            if (state.Money or 0) < 800 then return false, "Need $800" end
            return true
        end,
        
        choices = {
            {
                text = "Do the upgrade! ($800)",
                effects = { Money = -800 },
                feedText = "Upgrading your ride...",
                onResolve = function(state)
                    local roll = math.random()
                    
                    if roll < 0.70 then
                        -- Success!
                        state:ModifyStat("Happiness", 12)
                        state.Flags = state.Flags or {}
                        state.Flags.car_upgraded = true
                        state.Flags.performance_car = true
                        
                        -- Increase vehicle value
                        if state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0 then
                            state.Assets.Vehicles[1].value = (state.Assets.Vehicles[1].value or 10000) + 2000
                        end
                        
                        state:AddFeed("🔧 UPGRADED! Your car is faster and worth more! Those mods are SICK!")
                    elseif roll < 0.90 then
                        -- Partial success
                        state:ModifyStat("Happiness", 5)
                        state:AddFeed("🔧 Upgrade done but not as good as expected. Still an improvement though.")
                    else
                        -- Something went wrong
                        state:ModifyStat("Happiness", -10)
                        state.Money = math.max(0, (state.Money or 0) - 300)
                        state:AddFeed("🔧 Something went wrong! Had to pay extra $300 to fix the damage!")
                    end
                end,
            },
            {
                text = "Keep it stock for now",
                effects = {},
                feedText = "🔧 Maybe another time. Stock is fine.",
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- ROAD TRIP EVENTS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "vehicle_road_trip",
        title = "Road Trip Adventure!",
        emoji = "🛣️",
        text = "Perfect weather for a spontaneous road trip!",
        textVariants = {
            "The open road is calling!",
            "You have some time off - road trip?",
            "Friends are planning a road trip and want you to drive!",
        },
        question = "Take a road trip?",
        minAge = 18, maxAge = 70,
        baseChance = 0.35,
        cooldown = 4,
        category = "vehicle",
        tags = { "travel", "adventure", "road_trip" },
        blockedByFlags = { in_prison = true, incarcerated = true },
        eligibility = function(state)
            if not hasVehicle(state) then return false, "Need a car" end
            if (state.Money or 0) < 200 then return false, "Need at least $200 for gas and food" end
            return true
        end,
        
        choices = {
            {
                text = "Hit the road! ($200)",
                effects = { Money = -200 },
                feedText = "Adventure awaits...",
                onResolve = function(state)
                    local vehicle, tier = getPlayerVehicle(state)
                    local vehicleName = vehicle and vehicle.name or "your car"
                    local roll = math.random()
                    
                    -- Better cars = more comfortable trips
                    local comfortBonus = 0
                    if tier == "luxury" or tier == "exotic" then comfortBonus = 5 end
                    
                    if roll < 0.50 then
                        -- Amazing trip!
                        state:ModifyStat("Happiness", 20 + comfortBonus)
                        state.Flags = state.Flags or {}
                        state.Flags.road_tripper = true
                        state.Flags.adventurous = true
                        state:AddFeed(string.format("🛣️ AMAZING TRIP! %s handled perfectly! Made memories! Best decision!", vehicleName))
                    elseif roll < 0.80 then
                        -- Good trip
                        state:ModifyStat("Happiness", 10 + comfortBonus)
                        state:AddFeed(string.format("🛣️ Great road trip! %s was comfy! Saw cool things!", vehicleName))
                    elseif roll < 0.95 then
                        -- Minor issues
                        state:ModifyStat("Happiness", 3)
                        state.Money = math.max(0, (state.Money or 0) - 100)
                        state:AddFeed("🛣️ Trip was okay but had some car trouble. Cost an extra $100. Still fun though!")
                    else
                        -- Disaster
                        state:ModifyStat("Happiness", -10)
                        state.Money = math.max(0, (state.Money or 0) - 500)
                        state:AddFeed("🛣️ Disaster! Car broke down far from home! $500 in unexpected costs! Never again!")
                    end
                end,
            },
            {
                text = "Staycation instead",
                effects = { Happiness = 5 },
                feedText = "🛣️ Relaxed at home instead. Sometimes that's better.",
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- SPEEDING/POLICE ENCOUNTERS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "vehicle_speeding_ticket",
        title = "Pulled Over!",
        emoji = "🚨",
        text = "Police lights in your rearview mirror! You were going a bit fast...",
        question = "How do you handle the traffic stop?",
        minAge = 18, maxAge = 80,
        baseChance = 0.35,
        cooldown = 4,
        category = "vehicle",
        tags = { "police", "speeding", "ticket" },
        blockedByFlags = { in_prison = true, incarcerated = true },
        eligibility = function(state)
            return hasVehicle(state), "Need a car"
        end,
        
        choices = {
            {
                text = "Be polite and apologetic",
                effects = {},
                feedText = "Being respectful...",
                onResolve = function(state)
                    local looks = (state.Stats and state.Stats.Looks) or 50
                    local roll = math.random()
                    
                    -- Looks and luck affect outcome
                    local warningChance = 0.30 + (looks / 200)
                    
                    if roll < warningChance then
                        state:ModifyStat("Happiness", 8)
                        state:AddFeed("🚨 Officer let you off with a WARNING! Being nice pays off!")
                    elseif roll < 0.85 then
                        state:ModifyStat("Happiness", -5)
                        state.Money = math.max(0, (state.Money or 0) - 200)
                        state.Flags = state.Flags or {}
                        state.Flags.speeding_ticket = true
                        state:AddFeed("🚨 Got a $200 speeding ticket. Could have been worse.")
                    else
                        state:ModifyStat("Happiness", -10)
                        state.Money = math.max(0, (state.Money or 0) - 400)
                        state:AddFeed("🚨 $400 ticket! Officer wasn't having it. Drive slower!")
                    end
                end,
            },
            {
                text = "Try to talk your way out",
                effects = {},
                feedText = "Making excuses...",
                onResolve = function(state)
                    local smarts = (state.Stats and state.Stats.Smarts) or 50
                    local roll = math.random()
                    
                    if roll < (smarts / 300) then
                        state:ModifyStat("Happiness", 10)
                        state.Flags = state.Flags or {}
                        state.Flags.smooth_talker = true
                        state:AddFeed("🚨 Your excuse actually worked! No ticket! You're a smooth talker!")
                    else
                        state:ModifyStat("Happiness", -8)
                        state.Money = math.max(0, (state.Money or 0) - 300)
                        state:AddFeed("🚨 Officer didn't buy it. $300 ticket. Annoyed them with excuses.")
                    end
                end,
            },
            {
                text = "Accept responsibility",
                effects = { Happiness = -3, Money = -250 },
                feedText = "🚨 You owned up to it. $250 ticket. At least you were honest.",
            },
        },
    },
    
    {
        id = "vehicle_car_theft_attempt",
        title = "Car Theft Attempt!",
        emoji = "🚗💨",
        text = "You catch someone trying to break into your car!",
        question = "What do you do?",
        minAge = 18, maxAge = 70,
        baseChance = 0.20,
        cooldown = 6,
        category = "vehicle",
        tags = { "crime", "theft", "confrontation" },
        blockedByFlags = { in_prison = true, incarcerated = true },
        eligibility = function(state)
            return hasVehicle(state), "Need a car"
        end,
        
        choices = {
            {
                text = "Confront the thief!",
                effects = {},
                feedText = "Approaching the thief...",
                onResolve = function(state)
                    local health = (state.Stats and state.Stats.Health) or 50
                    local roll = math.random()
                    
                    if roll < 0.50 then
                        -- Thief runs away
                        state:ModifyStat("Happiness", 10)
                        state.Flags = state.Flags or {}
                        state.Flags.brave = true
                        state:AddFeed("🚗💨 Thief ran off! You scared them away! Car saved!")
                    elseif roll < 0.80 then
                        -- Minor altercation
                        state:ModifyStat("Happiness", 5)
                        state:ModifyStat("Health", -5)
                        state:AddFeed("🚗💨 Short scuffle but you won! Thief fled! A few bruises but worth it!")
                    else
                        -- Thief fights back
                        state:ModifyStat("Happiness", -15)
                        state:ModifyStat("Health", -20)
                        state.Money = math.max(0, (state.Money or 0) - 200)
                        state:AddFeed("🚗💨 Bad idea! Thief fought back! Hospital visit! Car still has damage!")
                    end
                end,
            },
            {
                text = "Call the police immediately",
                effects = {},
                feedText = "Calling 911...",
                onResolve = function(state)
                    local roll = math.random()
                    
                    if roll < 0.40 then
                        state:ModifyStat("Happiness", 5)
                        state:AddFeed("🚗💨 Police arrived fast! Caught the thief! Justice served!")
                    else
                        state:ModifyStat("Happiness", -5)
                        state.Money = math.max(0, (state.Money or 0) - 300)
                        state:AddFeed("🚗💨 Thief got away before police arrived. Minor damage to car. $300 in repairs.")
                    end
                end,
            },
            {
                text = "Set off your car alarm remotely",
                effects = { Happiness = 5 },
                feedText = "🚗💨 Alarm scared them off! No confrontation needed. Smart move!",
            },
        },
    },
}

return VehicleEvents
