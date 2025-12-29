--[[
    Property Events - CRITICAL FIX #933
    Home and property-based events
    Includes: Break-ins, renovations, parties, neighbors, maintenance, etc.
    
    CRITICAL: These events ONLY trigger when player has a home!
    All events have proper eligibility checks to prevent random popups.
    
    Property tiers:
    - Rental: Apartments, rented homes (HousingState.status == "renter")
    - Starter: Basic homes (value < 150000)
    - Standard: Normal homes (value 150000-400000)
    - Upscale: Nice homes (value 400000-800000)
    - Luxury: Mansions/estates (value 800000-2000000)
    - Mega: Celebrity mansions (value 2000000+)
]]

local PropertyEvents = {}

-- Stage for event system
local STAGE = "property"

-- Helper function to check if player owns property
local function ownsProperty(state)
    if not state then return false end
    
    local housing = state.HousingState or {}
    local flags = state.Flags or {}
    
    if housing.status == "owner" or housing.status == "royal_palace" then
        return true
    end
    
    if flags.homeowner or flags.has_property or flags.owns_home then
        return true
    end
    
    if state.Assets and state.Assets.Properties and #state.Assets.Properties > 0 then
        return true
    end
    
    return false
end

-- Helper to get property tier
local function getPropertyTier(state)
    if not state then return nil, nil end
    if not ownsProperty(state) then return nil, nil end
    
    local housing = state.HousingState or {}
    if housing.status == "royal_palace" then
        return "mega", "Royal Palace"
    end
    
    -- Check Assets.Properties
    if state.Assets and state.Assets.Properties and #state.Assets.Properties > 0 then
        local property = state.Assets.Properties[1]
        if not property then return "standard", "your home" end
        
        local value = property.value or property.price or 100000
        local name = property.name or "your home"
        
        if value >= 2000000 then return "mega", name
        elseif value >= 800000 then return "luxury", name
        elseif value >= 400000 then return "upscale", name
        elseif value >= 150000 then return "standard", name
        else return "starter", name end
    end
    
    return "standard", "your home"
end

-- Check if player is a renter
local function isRenter(state)
    if not state then return false end
    local housing = state.HousingState or {}
    return housing.status == "renter" or housing.status == "renting"
end

-- Check if player has ANY housing (owner or renter)
local function hasHousing(state)
    if not state then return false end
    return ownsProperty(state) or isRenter(state)
end

-- CRITICAL: Master eligibility check that ALL property events must pass
local function masterPropertyEligibility(state)
    if not state then return false, "No state" end
    
    -- Must have housing
    if not hasHousing(state) then
        return false, "No housing"
    end
    
    -- Can't be in prison
    local flags = state.Flags or {}
    if flags.in_prison or flags.incarcerated or flags.jailed then
        return false, "In prison"
    end
    
    -- Can't be dead
    if flags.dead or flags.is_dead then
        return false, "Dead"
    end
    
    -- Can't be homeless
    if flags.homeless then
        return false, "Homeless"
    end
    
    -- Must be adult (18+)
    local age = state.Age or 0
    if age < 18 then
        return false, "Too young"
    end
    
    return true, nil
end

PropertyEvents.events = {
    -- ══════════════════════════════════════════════════════════════════════════════
    -- HOME BREAK-IN EVENTS
    -- CRITICAL: All events use masterPropertyEligibility to prevent wrong triggers
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "property_home_invasion",
        title = "Home Break-In!",
        emoji = "🏚️",
        text = "You come home to find your door forced open! Someone broke in!",
        textVariants = {
            "Your neighbor called - they saw someone breaking into your place!",
            "The alarm is going off! Someone tried to break in!",
            "You notice your window is smashed - there was a burglary attempt!",
            "Something feels wrong... your door is unlocked and things are moved...",
        },
        question = "What do you find?",
        minAge = 18, maxAge = 90,
        baseChance = 0.10,  -- REDUCED - rare event
        cooldown = 10,      -- INCREASED - don't spam break-ins
        stage = STAGE,
        category = "property",
        tags = { "crime", "home", "burglary" },
        blockedByFlags = { in_prison = true, incarcerated = true, homeless = true, dead = true, is_dead = true },
        eligibility = function(state)
            local canTrigger, reason = masterPropertyEligibility(state)
            if not canTrigger then return false, reason end
            return true
        end,
        
        choices = {
            {
                text = "Assess the damage",
                effects = {},
                feedText = "Looking around...",
                onResolve = function(state)
                    local tier, propertyName = getPropertyTier(state)
                    local roll = math.random()
                    
                    -- Better properties = more to steal, but also better security
                    local hasAlarm = (state.Flags or {}).home_security or (state.Flags or {}).alarm_system
                    local securityBonus = hasAlarm and 0.30 or 0
                    
                    if roll < 0.25 + securityBonus then
                        -- Nothing stolen (security worked or they got scared)
                        state:ModifyStat("Happiness", -3)
                        state:AddFeed("🏚️ Luckily nothing was stolen! They got scared off. Still unsettling...")
                        state.Flags = state.Flags or {}
                        state.Flags.break_in_survivor = true
                    elseif roll < 0.60 + (securityBonus / 2) then
                        -- Minor theft
                        local loss = math.random(200, 800)
                        state.Money = math.max(0, (state.Money or 0) - loss)
                        state:ModifyStat("Happiness", -10)
                        state:AddFeed(string.format("🏚️ Some electronics and cash stolen! Lost about $%d worth. Feel violated.", loss))
                    elseif roll < 0.90 then
                        -- Major theft
                        local loss = math.random(1500, 5000)
                        state.Money = math.max(0, (state.Money or 0) - loss)
                        state:ModifyStat("Happiness", -20)
                        state:AddFeed(string.format("🏚️ Major burglary! Lost $%d in valuables! Devastated!", loss))
                    else
                        -- Insurance claim successful
                        state:ModifyStat("Happiness", -8)
                        local payout = math.random(2000, 4000)
                        state.Money = (state.Money or 0) + payout
                        state:AddFeed(string.format("🏚️ Items stolen but insurance paid out $%d! Silver lining.", payout))
                    end
                end,
            },
            {
                text = "Call the police immediately",
                effects = { Happiness = -5 },
                feedText = "🏚️ Police are investigating. They'll do what they can. Feeling unsafe.",
            },
			{
				text = "Install a security system ($500)",
				effects = { Money = -500 },
				feedText = "🏚️ Never again! Installed a top-notch security system.",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Can't afford security system ($500)" end,
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.home_security = true
					state.Flags.alarm_system = true
				end,
			},
			{
				text = "Just be more vigilant",
				effects = { Happiness = -3 },
				feedText = "🏚️ Can't afford a security system but you'll be more careful. Triple-check the locks!",
			},
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- HOME RENOVATION EVENTS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "property_renovation_opportunity",
        title = "Home Renovation Opportunity",
        emoji = "🔨",
        text = "A contractor offers to renovate part of your home at a good price.",
        textVariants = {
            "Your kitchen is looking dated. Time for an upgrade?",
            "That bathroom could really use a remodel...",
            "You've been dreaming about that home office conversion.",
            "The contractor has an opening - renovation time?",
        },
        question = "Renovate your home?",
        minAge = 25, maxAge = 80,
        baseChance = 0.15,  -- REDUCED
        cooldown = 8,       -- INCREASED
        stage = STAGE,
        category = "property",
        tags = { "renovation", "home", "investment" },
        blockedByFlags = { in_prison = true, incarcerated = true, homeless = true, dead = true, is_dead = true },
        eligibility = function(state)
            local canTrigger, reason = masterPropertyEligibility(state)
            if not canTrigger then return false, reason end
            if not ownsProperty(state) then return false, "Need to own a home" end
            if (state.Money or 0) < 5000 then return false, "Need at least $5000" end
            return true
        end,
        
        choices = {
            {
                text = "Full renovation ($15,000)",
                effects = { Money = -15000 },
                feedText = "Major renovation underway...",
                eligibility = function(state) return (state.Money or 0) >= 15000, "Need $15,000" end,
                onResolve = function(state)
                    local roll = math.random()
                    
                    if roll < 0.70 then
                        -- Great renovation
                        state:ModifyStat("Happiness", 20)
                        state.Flags = state.Flags or {}
                        state.Flags.renovated_home = true
                        
                        -- Increase property value
                        if state.Assets and state.Assets.Properties and #state.Assets.Properties > 0 then
                            state.Assets.Properties[1].value = (state.Assets.Properties[1].value or 100000) + 25000
                        end
                        
                        state:AddFeed("🔨 STUNNING TRANSFORMATION! Home value increased by $25,000! Worth every penny!")
                    elseif roll < 0.90 then
                        -- Okay renovation
                        state:ModifyStat("Happiness", 10)
                        state:AddFeed("🔨 Renovation looks good! Nice improvement. Home feels fresh!")
                    else
                        -- Problems
                        state:ModifyStat("Happiness", -5)
                        state.Money = math.max(0, (state.Money or 0) - 3000)
                        state:AddFeed("🔨 Contractor found hidden issues - extra $3,000 in unexpected costs! Ugh!")
                    end
                end,
            },
            {
                text = "Minor updates ($5,000)",
                effects = { Money = -5000 },
                feedText = "🔨 Some paint, new fixtures, minor repairs. Freshened up the place nicely!",
                eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Need $5,000 for updates" end,
                onResolve = function(state)
                    state:ModifyStat("Happiness", 8)
                end,
            },
            {
                text = "DIY it over time",
                effects = { Happiness = 3 },
                feedText = "🔨 You'll do it yourself! YouTube tutorials here we come!",
            },
            {
                text = "Not interested right now",
                effects = {},
                feedText = "🔨 Maybe another time. The house is fine as is.",
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- HOUSE PARTY EVENTS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "property_throw_party",
        title = "Party at Your Place!",
        emoji = "🎉",
        text = "Friends are suggesting you host a party at your place!",
        textVariants = {
            "It's been a while since you threw a good party!",
            "Your place would be perfect for a get-together!",
            "Everyone's asking - when's the next party at yours?",
        },
        question = "Host a party?",
        minAge = 21, maxAge = 60,
        baseChance = 0.20,  -- REDUCED
        cooldown = 6,       -- INCREASED
        stage = STAGE,
        category = "property",
        tags = { "party", "social", "home" },
        blockedByFlags = { in_prison = true, incarcerated = true, homeless = true, dead = true, is_dead = true },
        eligibility = function(state)
            local canTrigger, reason = masterPropertyEligibility(state)
            if not canTrigger then return false, reason end
            return true
        end,
        
        choices = {
            {
                text = "Throw an epic house party! ($300)",
                effects = { Money = -300 },
                feedText = "Party time!",
                eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 for party" end,
                onResolve = function(state)
                    local tier, propertyName = getPropertyTier(state)
                    local roll = math.random()
                    
                    -- Better house = better party
                    local partyBonus = 0
                    if tier == "mega" then partyBonus = 15
                    elseif tier == "luxury" then partyBonus = 10
                    elseif tier == "upscale" then partyBonus = 5
                    end
                    
                    if roll < 0.60 then
                        -- Great party!
                        state:ModifyStat("Happiness", 20 + partyBonus)
                        state.Flags = state.Flags or {}
                        state.Flags.party_host = true
                        state.Flags.popular = true
                        state:AddFeed(string.format("🎉 LEGENDARY PARTY at %s! Everyone's talking about it! So many new friends!", propertyName or "your place"))
                    elseif roll < 0.85 then
                        -- Good party
                        state:ModifyStat("Happiness", 10 + partyBonus)
                        state:AddFeed("🎉 Great party! Good vibes, good people! Tons of fun!")
                    elseif roll < 0.95 then
                        -- Something broke
                        state:ModifyStat("Happiness", 5)
                        state.Money = math.max(0, (state.Money or 0) - 200)
                        state:AddFeed("🎉 Fun party but someone broke something. $200 in damages. Worth it though!")
                    else
                        -- Neighbors complained
                        state:ModifyStat("Happiness", -5)
                        state.Flags = state.Flags or {}
                        state.Flags.noise_complaint = true
                        state:AddFeed("🎉 Party got shut down! Neighbors called noise complaint. Awkward.")
                    end
                end,
            },
            {
                text = "Small dinner party ($100)",
                effects = { Money = -100, Happiness = 12 },
                feedText = "🎉 Intimate gathering with close friends. Great conversations. Perfect evening!",
                eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100" end,
            },
            {
                text = "Just a casual hangout",
                effects = { Happiness = 8 },
                feedText = "🎉 Friends came over, ordered pizza, watched movies. Simple but fun!",
            },
            {
                text = "Not in the mood for hosting",
                effects = {},
                feedText = "🎉 Maybe another time. Your place is your sanctuary.",
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- NEIGHBOR EVENTS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "property_neighbor_conflict",
        title = "Neighbor Dispute",
        emoji = "🏘️",
        text = "Your neighbor is complaining about something you did.",
        textVariants = {
            "Your neighbor says your music was too loud last night.",
            "The neighbor's upset about where you parked.",
            "Someone complained about your lawn being unkempt.",
            "Your neighbor is angry about your dog barking.",
            "There's a fence/property line dispute brewing.",
        },
        question = "How do you handle the conflict?",
        minAge = 18, maxAge = 90,
        baseChance = 0.15,  -- REDUCED
        cooldown = 7,       -- INCREASED
        stage = STAGE,
        category = "property",
        tags = { "neighbor", "conflict", "home" },
        blockedByFlags = { in_prison = true, incarcerated = true, homeless = true, dead = true, is_dead = true },
        eligibility = function(state)
            local canTrigger, reason = masterPropertyEligibility(state)
            if not canTrigger then return false, reason end
            return true
        end,
        
        choices = {
            {
                text = "Apologize and make amends",
                effects = { Happiness = 3 },
                feedText = "🏘️ You apologized. They appreciated it. Neighbors again!",
                onResolve = function(state)
                    state.Flags = state.Flags or {}
                    state.Flags.good_neighbor = true
                end,
            },
            {
                text = "Stand your ground",
                effects = {},
                feedText = "Standing firm...",
                onResolve = function(state)
                    local roll = math.random()
                    if roll < 0.40 then
                        state:ModifyStat("Happiness", 5)
                        state:AddFeed("🏘️ You made your case. They backed off. Boundaries established!")
                    elseif roll < 0.80 then
                        state:ModifyStat("Happiness", -5)
                        state.Flags = state.Flags or {}
                        state.Flags.neighbor_enemy = true
                        state:AddFeed("🏘️ Ongoing feud with the neighbor now. Awkward tension.")
                    else
                        state:ModifyStat("Happiness", -10)
                        state.Money = math.max(0, (state.Money or 0) - 500)
                        state:AddFeed("🏘️ They reported you to HOA/City! $500 fine! Should've just apologized.")
                    end
                end,
            },
            {
                text = "Bring them cookies as peace offering ($20)",
                effects = { Money = -20, Happiness = 8 },
                feedText = "🏘️ Cookies worked magic! They're your friend now! Kill 'em with kindness!",
                eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20 for cookies" end,
                onResolve = function(state)
                    state.Flags = state.Flags or {}
                    state.Flags.good_neighbor = true
                    state.Flags.neighborly = true
                end,
            },
        },
    },
    
    {
        id = "property_new_neighbor",
        title = "New Neighbors!",
        emoji = "📦",
        text = "A moving truck is parked next door - you're getting new neighbors!",
        question = "Do you introduce yourself?",
        minAge = 18, maxAge = 90,
        baseChance = 0.15,  -- REDUCED
        cooldown = 8,       -- INCREASED
        stage = STAGE,
        category = "property",
        tags = { "neighbor", "social", "home" },
        blockedByFlags = { in_prison = true, incarcerated = true, homeless = true, dead = true, is_dead = true },
        eligibility = function(state)
            local canTrigger, reason = masterPropertyEligibility(state)
            if not canTrigger then return false, reason end
            return true
        end,
        
        choices = {
            {
                -- CRITICAL FIX: Show price!
                text = "Welcome them with baked goods ($15)",
                effects = { Money = -15 },
                feedText = "Heading next door...",
                eligibility = function(state) return (state.Money or 0) >= 15, "💸 Need $15 for ingredients" end,
                onResolve = function(state)
                    local roll = math.random()
                    if roll < 0.70 then
                        state:ModifyStat("Happiness", 12)
                        state.Flags = state.Flags or {}
                        state.Flags.neighborly = true
                        state.Flags.good_neighbor = true
                        state:AddFeed("📦 They're amazing! Instant friendship! Best neighbors ever!")
                    elseif roll < 0.90 then
                        state:ModifyStat("Happiness", 5)
                        state:AddFeed("📦 Nice people! Not best friends but good neighbors. Pleasant!")
                    else
                        state:ModifyStat("Happiness", -2)
                        state:AddFeed("📦 They seemed cold. Took the cookies but barely said thanks. Oh well.")
                    end
                end,
            },
            {
                text = "Wave from afar",
                effects = { Happiness = 2 },
                feedText = "📦 You waved. They waved back. Neighborly enough!",
            },
            {
                text = "Mind your own business",
                effects = {},
                feedText = "📦 Not your concern. They'll learn the neighborhood themselves.",
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- HOME MAINTENANCE EVENTS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "property_maintenance_issue",
        title = "Home Maintenance Crisis!",
        emoji = "🔧",
        text = "Something broke in your home and needs immediate attention!",
        textVariants = {
            "The AC/Heater broke down in extreme weather!",
            "There's a leak in the roof!",
            "The water heater died - no hot water!",
            "Pipe burst! Water everywhere!",
            "Major appliance just stopped working!",
        },
        question = "How do you handle it?",
        minAge = 18, maxAge = 90,
        baseChance = 0.20,  -- REDUCED
        cooldown = 6,       -- INCREASED
        stage = STAGE,
        category = "property",
        tags = { "maintenance", "emergency", "home" },
        blockedByFlags = { in_prison = true, incarcerated = true, homeless = true, dead = true, is_dead = true },
        eligibility = function(state)
            local canTrigger, reason = masterPropertyEligibility(state)
            if not canTrigger then return false, reason end
            return true
        end,
        
        choices = {
            {
                text = "Call a professional ($300-800)",
                effects = {},
                feedText = "Calling for help...",
                onResolve = function(state)
                    local isOwner = ownsProperty(state)
                    local cost = math.random(300, 800)
                    
                    if not isOwner then
                        -- Renter - landlord pays
                        state:ModifyStat("Happiness", -3)
                        state:AddFeed("🔧 Landlord is sending someone. Annoying but not your bill!")
                    else
                        -- Owner pays
                        state.Money = math.max(0, (state.Money or 0) - cost)
                        state:ModifyStat("Happiness", -5)
                        state:AddFeed(string.format("🔧 $%d repair bill! Homeownership joys... At least it's fixed.", cost))
                    end
                end,
            },
            {
                text = "Try to fix it yourself",
                effects = {},
                feedText = "DIY mode activated...",
                onResolve = function(state)
                    local smarts = (state.Stats and state.Stats.Smarts) or 50
                    local roll = math.random()
                    
                    if roll < (smarts / 200) + 0.20 then
                        state:ModifyStat("Happiness", 10)
                        state:ModifyStat("Smarts", 2)
                        state.Flags = state.Flags or {}
                        state.Flags.handy = true
                        state:AddFeed("🔧 You fixed it yourself! YouTube tutorials FTW! Saved hundreds!")
                    else
                        state:ModifyStat("Happiness", -10)
                        state.Money = math.max(0, (state.Money or 0) - 600)
                        state:AddFeed("🔧 Made it worse... Had to call emergency repair. $600! Should've called first.")
                    end
                end,
            },
            {
                text = "Ignore it and hope it fixes itself",
                effects = { Happiness = -8 },
                feedText = "🔧 Spoiler: It got worse. Much worse. Living uncomfortably now.",
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- PROPERTY VALUE EVENTS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "property_value_change",
        title = "Property Market News!",
        emoji = "📈",
        text = "There's been a change in the local real estate market...",
        question = "What happened?",
        minAge = 25, maxAge = 90,
        baseChance = 0.12,  -- REDUCED
        cooldown = 8,       -- INCREASED
        stage = STAGE,
        category = "property",
        tags = { "investment", "real_estate", "market" },
        blockedByFlags = { in_prison = true, incarcerated = true, homeless = true, dead = true, is_dead = true },
        eligibility = function(state)
            local canTrigger, reason = masterPropertyEligibility(state)
            if not canTrigger then return false, reason end
            if not ownsProperty(state) then return false, "Need to own property" end
            return true
        end,
        
        choices = {
            {
                text = "Check the news",
                effects = {},
                feedText = "Checking property values...",
                onResolve = function(state)
                    local roll = math.random()
                    
                    if roll < 0.35 then
                        -- Value increased!
                        local increase = math.random(5000, 30000)
                        if state.Assets and state.Assets.Properties and #state.Assets.Properties > 0 then
                            state.Assets.Properties[1].value = (state.Assets.Properties[1].value or 100000) + increase
                        end
                        state:ModifyStat("Happiness", 15)
                        state:AddFeed(string.format("📈 GREAT NEWS! Property value increased by $%d! Smart investment!", increase))
                    elseif roll < 0.65 then
                        -- Stable
                        state:ModifyStat("Happiness", 3)
                        state:AddFeed("📈 Property value holding steady. Stable market.")
                    elseif roll < 0.85 then
                        -- Slight decrease
                        local decrease = math.random(2000, 8000)
                        if state.Assets and state.Assets.Properties and #state.Assets.Properties > 0 then
                            state.Assets.Properties[1].value = math.max(50000, (state.Assets.Properties[1].value or 100000) - decrease)
                        end
                        state:ModifyStat("Happiness", -5)
                        state:AddFeed(string.format("📈 Property value dipped $%d. Market fluctuation. Don't panic.", decrease))
                    else
                        -- Big news
                        local increase = math.random(40000, 80000)
                        if state.Assets and state.Assets.Properties and #state.Assets.Properties > 0 then
                            state.Assets.Properties[1].value = (state.Assets.Properties[1].value or 100000) + increase
                        end
                        state:ModifyStat("Happiness", 25)
                        state:AddFeed(string.format("📈 HOT MARKET! New development nearby skyrocketed your property value by $%d!", increase))
                    end
                end,
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- RENTAL SPECIFIC EVENTS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "property_rent_increase",
        title = "Rent Increase Notice",
        emoji = "📬",
        text = "Your landlord is raising the rent!",
        textVariants = {
            "Annual rent increase notice arrived.",
            "Landlord says rent is going up next month.",
            "Property management announced higher rent.",
        },
        question = "The rent is going up $100/month. What do you do?",
        minAge = 18, maxAge = 70,
        baseChance = 0.20,  -- REDUCED
        cooldown = 6,       -- INCREASED
        stage = STAGE,
        category = "property",
        tags = { "rent", "housing", "cost" },
        blockedByFlags = { in_prison = true, incarcerated = true, homeless = true, dead = true, is_dead = true },
        eligibility = function(state)
            -- CRITICAL: Only for renters
            if not state then return false, "No state" end
            local flags = state.Flags or {}
            if flags.in_prison or flags.dead or flags.is_dead then return false, "Invalid state" end
            if not isRenter(state) then return false, "Must be renting" end
            return true
        end,
        
        choices = {
            {
                text = "Accept it - nowhere else to go",
                effects = { Happiness = -5 },
                feedText = "📬 Stuck paying more. Budget tighter now. The joys of renting.",
            },
            {
                text = "Negotiate with the landlord",
                effects = {},
                feedText = "Trying to negotiate...",
                onResolve = function(state)
                    local smarts = (state.Stats and state.Stats.Smarts) or 50
                    local roll = math.random()
                    
                    if roll < (smarts / 200) + 0.15 then
                        state:ModifyStat("Happiness", 8)
                        state:AddFeed("📬 Negotiated! Only $50 increase! Your charm worked!")
                    else
                        state:ModifyStat("Happiness", -3)
                        state:AddFeed("📬 They wouldn't budge. Full increase it is.")
                    end
                end,
            },
            {
                text = "Start looking for a new place",
                effects = { Happiness = -2 },
                feedText = "📬 Time to apartment hunt. This place isn't worth more money.",
                onResolve = function(state)
                    state.Flags = state.Flags or {}
                    state.Flags.apartment_hunting = true
                end,
            },
            {
                text = "Consider buying a home",
                effects = { Happiness = 2 },
                feedText = "📬 Maybe it's time to stop throwing money at rent. House hunting!",
                onResolve = function(state)
                    state.Flags = state.Flags or {}
                    state.Flags.wants_to_buy_home = true
                end,
            },
        },
    },
}

return PropertyEvents
