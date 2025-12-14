--[[
	╔══════════════════════════════════════════════════════════════════════════════╗
	║                         LIFE EVENTS ENGINE v2.0                              ║
	║                     AAA-Quality Event Management System                       ║
	╠══════════════════════════════════════════════════════════════════════════════╣
	║  This is the ENGINE - it loads events from external module files.            ║
	║                                                                              ║
	║  FEATURES:                                                                   ║
	║  • Modular event loading from separate category files                        ║
	║  • Comprehensive contextual requirements (job, partner, flags, stats, etc.)  ║
	║  • Weighted random selection with variety tracking                           ║
	║  • Event history & cooldown management                                       ║
	║  • Dynamic relationship creation                                             ║
	║  • Life stage awareness                                                      ║
	║                                                                              ║
	║  USAGE:                                                                      ║
	║    local LifeEvents = require(path.to.LifeEvents)                           ║
	║    local events = LifeEvents.buildYearQueue(playerState, { maxEvents = 1 }) ║
	║    LifeEvents.EventEngine.completeEvent(eventDef, choiceIndex, state)       ║
	╚══════════════════════════════════════════════════════════════════════════════╝
]]

local LifeEvents = {}

-- ════════════════════════════════════════════════════════════════════════════════════
-- CORE SYSTEMS
-- ════════════════════════════════════════════════════════════════════════════════════

local RANDOM = Random.new()
local AllEvents = {}
local EventsByCategory = {}
local LoadedModules = {}

-- ════════════════════════════════════════════════════════════════════════════════════
-- LIFE STAGES CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════════════

local LifeStages = {
	{ id = "baby",        minAge = 0,  maxAge = 2,   quietChance = 0.2 },
	{ id = "toddler",     minAge = 3,  maxAge = 4,   quietChance = 0.25 },
	{ id = "child",       minAge = 5,  maxAge = 12,  quietChance = 0.35 },
	{ id = "teen",        minAge = 13, maxAge = 17,  quietChance = 0.3 },
	{ id = "young_adult", minAge = 18, maxAge = 29,  quietChance = 0.4 },
	{ id = "adult",       minAge = 30, maxAge = 49,  quietChance = 0.45 },
	{ id = "middle_age",  minAge = 50, maxAge = 64,  quietChance = 0.5 },
	{ id = "senior",      minAge = 65, maxAge = 999, quietChance = 0.55 },
}

-- Category mappings per life stage
-- CRITICAL FIX: Added career_racing and career_hacker to appropriate stages
-- Racing discovery can happen as young as age 10, hacker discovery at age 12
-- CRITICAL FIX: Added "teen" to young_adult to catch late-teen events like graduation
-- CRITICAL FIX: Added career_street, career_police, and assets categories which were MISSING!
-- These categories MUST be included or their events NEVER trigger!
-- ════════════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #26: Added career categories for all job-specific events
-- This ensures tech, medical, finance, office, creative events can trigger
-- ════════════════════════════════════════════════════════════════════════════════════
local StageCategories = {
	baby        = { "childhood", "milestones", "royalty" },
	toddler     = { "childhood", "milestones", "royalty" },
	child       = { "childhood", "milestones", "random", "career_racing", "royalty" },
	teen        = { "teen", "milestones", "relationships", "random", "crime", "career_racing", "career_hacker", "career_service", "career_street", "career", "royalty", "celebrity" },
	young_adult = { "adult", "teen", "milestones", "relationships", "random", "crime", "career_racing", "career_hacker", "career_service", "career_street", "career_police", "career", "career_tech", "career_medical", "career_finance", "career_office", "career_creative", "career_trades", "career_education", "career_military", "assets", "royalty", "celebrity", "mafia" },
	adult       = { "adult", "milestones", "relationships", "random", "crime", "career_racing", "career_hacker", "career_service", "career_street", "career_police", "career", "career_tech", "career_medical", "career_finance", "career_office", "career_creative", "career_trades", "career_education", "career_military", "assets", "royalty", "celebrity", "mafia" },
	middle_age  = { "adult", "senior", "milestones", "relationships", "random", "crime", "career_racing", "career_hacker", "career_police", "career", "career_tech", "career_medical", "career_finance", "career_office", "career_creative", "career_trades", "career_education", "career_military", "assets", "royalty", "celebrity", "mafia" },
	senior      = { "adult", "senior", "milestones", "relationships", "random", "career_racing", "career", "assets", "royalty", "celebrity" },
}

function LifeEvents.getLifeStage(age)
	for _, stage in ipairs(LifeStages) do
		if age >= stage.minAge and age <= stage.maxAge then
			return stage
		end
	end
	return LifeStages[6] -- default to adult
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- MODULE LOADING SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════════

local function safeRequire(moduleInstance)
	local success, result = pcall(function()
		return require(moduleInstance)
	end)
	if success then
		return result
	else
		warn("[LifeEvents] ❌ Failed to require module:", moduleInstance.Name, "-", result)
		return nil
	end
end

local function findModule(moduleName)
	-- Method 1: Direct child of this script (Rojo: init.lua children)
	local child = script:FindFirstChild(moduleName)
	if child and child:IsA("ModuleScript") then
		return child
	end
	
	-- Method 2: Sibling in parent folder
	if script.Parent then
		child = script.Parent:FindFirstChild(moduleName)
		if child and child:IsA("ModuleScript") and child ~= script then
			return child
		end
	end
	
	-- Method 3: Check inside Catalog subfolder (for organized event modules)
	local catalogFolder = script:FindFirstChild("Catalog")
	if catalogFolder then
		child = catalogFolder:FindFirstChild(moduleName)
		if child and child:IsA("ModuleScript") then
			return child
		end
	end
	
	-- Method 4: Check Catalog in parent folder (alternate structure)
	if script.Parent then
		catalogFolder = script.Parent:FindFirstChild("Catalog")
		if catalogFolder then
			child = catalogFolder:FindFirstChild(moduleName)
			if child and child:IsA("ModuleScript") then
				return child
			end
		end
	end
	
	return nil
end

local function loadEventModule(moduleName, categoryName)
	local moduleInstance = findModule(moduleName)
	if not moduleInstance then
		warn("[LifeEvents] ⚠️ Module not found:", moduleName)
		return 0
	end
	
	local moduleData = safeRequire(moduleInstance)
	if not moduleData then
		return 0
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #41-43: Support multiple export formats including premium modules
	-- Premium modules (MafiaEvents, RoyaltyEvents, CelebrityEvents) use .LifeEvents
	-- Standard modules use .events, .Events, or return an array directly
	-- ═══════════════════════════════════════════════════════════════════════════════
	local events = moduleData.events 
		or moduleData.Events 
		or moduleData.LifeEvents  -- CRITICAL FIX: Premium modules use LifeEvents
		or moduleData.GeneralEvents  -- Some modules use GeneralEvents
		or moduleData
	
	if type(events) ~= "table" then
		warn("[LifeEvents] ⚠️ Invalid events format in:", moduleName)
		return 0
	end
	
	-- Ensure it's an array of events
	if events[1] == nil and next(events) ~= nil then
		-- It's a dictionary, not an array - check for nested arrays
		-- CRITICAL FIX #42: CelebrityEvents has events nested in career paths
		-- Try to find and combine all event arrays from the module
		local combinedEvents = {}
		
		-- Check for common event array names
		local possibleArrayNames = { "LifeEvents", "GeneralFameEvents", "events", "Events" }
		for _, arrayName in ipairs(possibleArrayNames) do
			if type(moduleData[arrayName]) == "table" and moduleData[arrayName][1] ~= nil then
				for _, event in ipairs(moduleData[arrayName]) do
					table.insert(combinedEvents, event)
				end
			end
		end
		
		-- If still no events found, skip
		if #combinedEvents == 0 then
			warn("[LifeEvents] ⚠️ Events should be an array in:", moduleName, "- found dictionary without event arrays")
			return 0
		end
		
		events = combinedEvents
	end
	
	local category = categoryName or moduleName:lower()
	EventsByCategory[category] = EventsByCategory[category] or {}
	
	local count = 0
	for _, event in ipairs(events) do
		if event.id then
			event._category = category
			event._source = moduleName
			AllEvents[event.id] = event
			table.insert(EventsByCategory[category], event)
			count += 1
		end
	end
	
	LoadedModules[moduleName] = {
		instance = moduleInstance,
		eventCount = count,
		category = category,
	}
	
	return count
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════════════

function LifeEvents.init()
	AllEvents = {}
	EventsByCategory = {}
	LoadedModules = {}
	
	-- Define module -> category mappings
	local moduleConfig = {
		-- Core event modules (direct children)
		{ name = "Childhood",     category = "childhood" },
		{ name = "Teen",          category = "teen" },
		{ name = "Adult",         category = "adult" },
		{ name = "Senior",        category = "senior" },              -- Senior/retirement events (ages 60+)
		{ name = "Career",        category = "career" },
		{ name = "Relationships", category = "relationships" },
		{ name = "Milestones",    category = "milestones" },
		{ name = "Random",        category = "random" },
		
		-- ══════════════════════════════════════════════════════════════════════════════
		-- MASSIVE EXPANSION MODULES - 300+ new events total
		-- All events use randomized outcomes - NO god mode
		-- ══════════════════════════════════════════════════════════════════════════════
		{ name = "ChildhoodExpanded",  category = "childhood" },      -- 40+ new childhood events (ages 0-12)
		{ name = "TeenExpanded",       category = "teen" },           -- 60+ new teen events (ages 13-17)
		{ name = "AdultExpanded",      category = "adult" },          -- 60+ new adult events (ages 18-60)
		{ name = "SeniorExpanded",     category = "senior" },         -- 35+ new senior events (ages 60+)
		{ name = "RandomExpanded",     category = "random" },         -- 30+ new random life events (any age)
		{ name = "JobSpecificEvents",  category = "career" },         -- 60+ job-specific events per career category
		{ name = "RelationshipsExpanded", category = "relationships" }, -- 25+ expanded relationship events
		{ name = "LifeExperiences",  category = "random" },        -- 30+ life experience events
		{ name = "SchoolExpanded",   category = "childhood" },     -- 30+ school/education events
		{ name = "CommunityEvents",  category = "random" },        -- 30+ community/social events
		{ name = "FinancialEvents",  category = "random" },        -- 25+ financial events
		{ name = "HealthEvents",     category = "health" },        -- 25+ health/wellness events
		{ name = "TravelEvents",     category = "random" },        -- 15+ travel/vacation events
		{ name = "FamilyEvents",     category = "family" },        -- 15+ family/parenting events
		{ name = "HobbyEvents",      category = "hobbies" },       -- 20+ hobby/interest events
		{ name = "SocialMediaEvents", category = "random" },       -- 12+ social media/online events
		{ name = "PetEvents",        category = "pets" },          -- 12+ pet/animal events
		{ name = "LegalEvents",      category = "legal" },         -- 12+ legal/justice events
		{ name = "LifeChallenges",   category = "random" },        -- 18+ life challenge events
		{ name = "SeasonalEvents",   category = "seasonal" },      -- 20+ seasonal/holiday events
		{ name = "MiscEvents",       category = "random" },        -- 18+ miscellaneous events
		{ name = "DailyLifeEvents",  category = "random" },        -- 22+ daily routine events
		{ name = "SpecialMoments",   category = "milestone" },     -- 16+ special moment events
		{ name = "ReputationEvents", category = "social" },        -- 10+ reputation/social events
		{ name = "LuckEvents",       category = "random" },        -- 4+ luck/superstition events
		
		-- Catalog modules (organized event collections)
		{ name = "CareerEvents",   category = "career" },
		{ name = "RomanceEvents",  category = "relationships" },
		{ name = "CrimeEvents",    category = "crime" },
		{ name = "CoreMilestones", category = "milestones" },
		
		-- CRITICAL FIX #716: Progressive Life Events for ages 0-30
		-- Adds 50+ new varied events to prevent repetition
		{ name = "ProgressiveLifeEvents", category = "childhood" },
		
		-- Specialized career paths with minigame integration
		{ name = "RacingEvents",   category = "career_racing" },
		{ name = "HackerEvents",   category = "career_hacker" },
		{ name = "StreetHustlerEvents", category = "career_street" }, -- Street Hustler/Dealer career
		{ name = "PoliceEvents",   category = "career_police" },      -- Law Enforcement career
		{ name = "AssetEvents",    category = "assets" },             -- Asset enjoyment events (cars, properties)
		{ name = "FastFoodEvents", category = "career_service" },     -- Fast food/service industry events
		
		-- ══════════════════════════════════════════════════════════════════════════════
		-- PREMIUM GAMEPASS EVENT MODULES - Require specific gamepasses
		-- ══════════════════════════════════════════════════════════════════════════════
		{ name = "RoyaltyEvents",   category = "royalty" },           -- Royalty gamepass events
		{ name = "CelebrityEvents", category = "celebrity" },         -- Celebrity/Fame gamepass events  
		{ name = "MafiaEvents",     category = "mafia" },             -- Mafia gamepass events
		
		-- ══════════════════════════════════════════════════════════════════════════════
		-- PREMIUM INTEGRATED EVENTS - Events with optional gamepass choices
		-- All players can play, premium choices enhance but don't force purchases
		-- ══════════════════════════════════════════════════════════════════════════════
		{ name = "PremiumIntegratedEvents", category = "random" },    -- 20+ events with tasteful gamepass options
		
		-- ══════════════════════════════════════════════════════════════════════════════
		-- RAPPER & CONTENT CREATOR EXPANSION - MASSIVE career paths
		-- From underground nobody to legendary superstar
		-- ══════════════════════════════════════════════════════════════════════════════
		{ name = "RapperContentCreatorEvents", category = "career_music" }, -- 50+ rapper/creator events
	}
	
	local totalEvents = 0
	local loadedCategories = 0
	
	for _, config in ipairs(moduleConfig) do
		local count = loadEventModule(config.name, config.category)
		if count > 0 then
			totalEvents += count
			loadedCategories += 1
			print(string.format("[LifeEvents] ✅ Loaded %s: %d events", config.name, count))
		end
	end
	
	print(string.format("[LifeEvents] 🎮 Initialized: %d events across %d categories", totalEvents, loadedCategories))
	
	return totalEvents
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- EVENT HISTORY SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════════

local function getEventHistory(state)
	-- BULLETPROOF: Handle nil state
	if not state then
		return {
			occurrences = {},
			lastOccurrence = {},
			completed = {},
			recentCategories = {},
			recentEvents = {},
			lastCategoryOccurrence = {},
		}
	end
	
	-- Ensure EventHistory exists on state
	if type(state.EventHistory) ~= "table" then
		state.EventHistory = {}
	end
	
	local history = state.EventHistory
	
	-- Ensure ALL required fields exist (handles legacy/incomplete history objects)
	history.occurrences = history.occurrences or {}
	history.lastOccurrence = history.lastOccurrence or {}
	history.completed = history.completed or {}
	history.recentCategories = history.recentCategories or {}
	history.recentEvents = history.recentEvents or {}
	history.lastCategoryOccurrence = history.lastCategoryOccurrence or {} -- NEW: Category-based cooldowns
	
	return history
end

local function recordEventShown(state, event)
	-- Guard: invalid inputs
	if not state then
		warn("[LifeEvents] recordEventShown: state is nil")
		return
	end
	if not event or type(event) ~= "table" or not event.id then
		warn("[LifeEvents] recordEventShown: invalid event")
		return
	end
	
	local history = getEventHistory(state)
	if not history then
		warn("[LifeEvents] recordEventShown: could not get event history")
		return
	end
	
	local eventId = event.id
	
	-- Track occurrence count (with nil safety)
	if type(history.occurrences) == "table" then
		history.occurrences[eventId] = (history.occurrences[eventId] or 0) + 1
	end
	
	-- Track when it last occurred
	if type(history.lastOccurrence) == "table" then
		history.lastOccurrence[eventId] = state.Age or 0
	end
	
	-- Mark one-time events as completed
	if event.oneTime and type(history.completed) == "table" then
		history.completed[eventId] = true
	end
	
	-- Track recent categories (for variety)
	if type(history.recentCategories) == "table" then
		local category = event._category or event.category or "general"
		table.insert(history.recentCategories, category)
		while #history.recentCategories > 5 do
			table.remove(history.recentCategories, 1)
		end
	end
	
	-- Track recent events
	if type(history.recentEvents) == "table" then
		table.insert(history.recentEvents, eventId)
		while #history.recentEvents > 10 do
			table.remove(history.recentEvents, 1)
		end
	end
	
	-- CRITICAL: Track category-based cooldowns to prevent spamming
	local eventCategory = event.category or event._category
	if eventCategory then
		history.lastCategoryOccurrence = history.lastCategoryOccurrence or {}
		history.lastCategoryOccurrence[eventCategory] = state.Age or 0
	end
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- CONTEXTUAL ELIGIBILITY SYSTEM
-- This is the CORE logic that prevents random/inappropriate events
-- ════════════════════════════════════════════════════════════════════════════════════

local function canEventTrigger(event, state)
	local age = state.Age or 0
	local history = getEventHistory(state)
	local flags = state.Flags or {}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Dead players should not receive any events!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.IsDead or flags.dead or (state.Stats and state.Stats.Health and state.Stats.Health <= 0) then
		return false -- Dead players can't have events
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #5/#14: PREMIUM GAMEPASS EVENT FILTERING
	-- Events marked as premium-only MUST check for gamepass ownership!
	-- Without this, players without gamepasses could get royalty/mafia/celebrity events!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #61-63: STRICT PREMIUM EVENT FILTERING
	-- Premium events should ONLY trigger for players who have BOTH:
	-- 1. The gamepass ownership
	-- 2. Actually started that premium feature (joined mob, born royal, etc.)
	-- Without this, players could randomly get royal events even if they didn't choose royal!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- ROYALTY events require Royalty gamepass AND actually being royalty
	if event.isRoyalOnly then
		if not flags.royalty_gamepass then
			return false -- Must own Royalty gamepass
		end
		-- CRITICAL FIX #62: Must actually BE royalty, not just own gamepass
		local isActuallyRoyal = flags.is_royalty or flags.royal_birth 
			or (state.RoyalState and state.RoyalState.isRoyal)
		if not isActuallyRoyal then
			return false -- Must have chosen royal at birth or became royal somehow
		end
	end
	
	-- MAFIA events require Mafia gamepass AND being in the mob
	if event.isMafiaOnly then
		if not flags.mafia_gamepass then
			return false -- Must own Mafia gamepass
		end
		
		-- CRITICAL FIX #61/#63: Check if this is an "approach" event vs "member" event
		-- Approach events (mafia_approach) should trigger for gamepass owners who AREN'T in mob yet
		-- All OTHER mafia events require actually being in the mob
		local isApproachEvent = event.id and (
			string.find(event.id, "approach") or 
			string.find(event.id, "recruit") or
			string.find(event.id, "offer_to_join")
		)
		
		if not isApproachEvent then
			-- Regular mafia events - MUST be in the mob
			local isInMob = flags.in_mob or (state.MobState and state.MobState.inMob)
			if not isInMob then
				return false -- Must have joined a crime family first
			end
		else
			-- Approach events - should NOT trigger if already in mob
			local isInMob = flags.in_mob or (state.MobState and state.MobState.inMob)
			if isInMob then
				return false -- Already in mob, don't recruit again
			end
		end
	end
	
	-- CELEBRITY events require Celebrity gamepass AND having a fame career
	if event.isCelebrityOnly then
		if not flags.celebrity_gamepass then
			return false -- Must own Celebrity gamepass
		end
		-- CRITICAL FIX #69: Must actually have a fame career to get career events
		-- General fame events (paparazzi, fans) just need some fame
		local hasActiveFameCareer = flags.fame_career or flags.career_actor 
			or flags.career_musician or flags.career_influencer or flags.career_athlete
			or (state.FameState and state.FameState.careerPath)
		local hasFame = (state.Fame or 0) >= 20
		
		-- Career-specific events need the career, general events just need some fame
		if event.careerPath then
			if not hasActiveFameCareer then
				return false -- Career events need active fame career
			end
		elseif not hasActiveFameCareer and not hasFame then
			return false -- Need either career or natural fame
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #646-650: ROYAL EDUCATION BLOCKING
	-- Royals do NOT attend normal public schools!
	-- They have private tutors, elite boarding schools, and prestigious academies
	-- Block normal school events for royal players
	-- ═══════════════════════════════════════════════════════════════════════════════
	local isRoyal = flags.is_royalty or flags.royal_birth 
		or (state.RoyalState and state.RoyalState.isRoyal)
	
	if isRoyal then
		-- List of normal school event IDs that royals should NOT see
		local normalSchoolEventIds = {
			"starting_school", "first_day_school", "elementary_start", "middle_school_start",
			"high_school_start", "public_school", "first_grade", "kindergarten",
			"school_bully", "homework_help", "cafeteria", "school_detention",
			"school_play", "school_dance", "school_suspension", "normal_education",
			"public_education", "regular_school", "school_registration",
		}
		
		-- Check if this is a normal school event
		local eventId = event.id and event.id:lower() or ""
		local eventTitle = event.title and event.title:lower() or ""
		
		for _, schoolId in ipairs(normalSchoolEventIds) do
			if eventId:find(schoolId) or eventTitle:find(schoolId) then
				-- CRITICAL FIX #647: Only block if event is NOT marked as royal education
				if not event.isRoyalOnly and not event.isRoyalEducation then
					return false -- Royals don't attend normal school!
				end
			end
		end
		
		-- CRITICAL FIX #648: Also check for generic school tags
		if (event.isPublicSchool or event.isNormalSchool) and not event.isRoyalEducation then
			return false -- Block any explicitly public school events
		end
		
		-- CRITICAL FIX #649: Check education type requirements
		if event.requiresEducationType then
			local eduType = event.requiresEducationType:lower()
			if eduType == "public" or eduType == "normal" or eduType == "public_school" then
				return false -- Royals don't have public school education
			end
		end
		
		-- CRITICAL FIX #650: Boost royal education events for royals
		-- (This is handled in the weight calculation section)
	end
	
	-- CRITICAL FIX #436: Check ALL flags in conditions.requiresFlags, not just gamepass flags!
	-- This was causing events like become_boss to trigger without underboss flag,
	-- and prison_respect to trigger when not in prison!
	if event.conditions and event.conditions.requiresFlags then
		for flag, requiredValue in pairs(event.conditions.requiresFlags) do
			local playerHasFlag = flags[flag]
			
			-- If requiredValue is true, player must have the flag
			if requiredValue == true and not playerHasFlag then
				return false -- Missing required flag
			end
			
			-- If requiredValue is false, player must NOT have the flag
			if requiredValue == false and playerHasFlag then
				return false -- Has blocked flag
			end
		end
	end
	
	-- CRITICAL FIX #437: Check conditions.blockedFlags (dict format) 
	-- This is DIFFERENT from cond.blockedFlags (array format) checked below
	if event.conditions and event.conditions.blockedFlags then
		if type(event.conditions.blockedFlags) == "table" then
			-- Check if it's array format or dict format
			if #event.conditions.blockedFlags > 0 then
				-- Array format: {"flag1", "flag2"}
				for _, flag in ipairs(event.conditions.blockedFlags) do
					if flags[flag] then
						return false -- Has blocking flag
					end
				end
			else
				-- Dict format: {flag1 = true, flag2 = true}
				for flag, _ in pairs(event.conditions.blockedFlags) do
					if flags[flag] then
						return false -- Has blocking flag
					end
				end
			end
		end
	end
	
	-- CRITICAL FIX #438: Check minRank and minRespect conditions for mafia events
	if event.conditions then
		-- Check minimum mob rank
		if event.conditions.minRank then
			local mobState = state.MobState
			local currentRank = mobState and mobState.rankIndex or 0
			if currentRank < event.conditions.minRank then
				return false -- Not high enough rank
			end
		end
		
		-- Check minimum respect
		if event.conditions.minRespect then
			local mobState = state.MobState
			local currentRespect = mobState and mobState.respect or 0
			if currentRespect < event.conditions.minRespect then
				return false -- Not enough respect
			end
		end
		
		-- Check minimum heat for mafia
		if event.conditions.minHeat then
			local mobState = state.MobState
			local currentHeat = mobState and mobState.heat or 0
			if currentHeat < event.conditions.minHeat then
				return false -- Not enough heat
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #5: Critically ill/dying players shouldn't get fun events
	-- Only allow health-related, medical, or high-priority events for very sick players
	-- This prevents the weird situation of getting "Travel Opportunity!" while dying
	-- ═══════════════════════════════════════════════════════════════════════════════
	local health = (state.Stats and state.Stats.Health) or state.Health or 50
	if health <= 15 then
		-- Player is critically ill - only allow relevant events
		local eventCategory = event._category or event.category or ""
		local eventId = event.id or ""
		local allowedWhileDying = event.allowedWhileDying
			or event.priority == "high"
			or event.isMilestone
			or eventCategory == "health"
			or eventCategory == "medical"
			or eventCategory == "death"
			or string.find(eventId, "health")
			or string.find(eventId, "illness")
			or string.find(eventId, "death")
			or string.find(eventId, "hospital")
			or string.find(eventId, "doctor")
		
		if not allowedWhileDying then
			return false -- Don't show random events to dying players
		end
	end
	
	-- Flatten conditions if present (some events use conditions.minAge instead of minAge)
	local cond = event.conditions or {}
	local minAge = event.minAge or cond.minAge
	local maxAge = event.maxAge or cond.maxAge
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- INCARCERATION CHECK - CRITICAL FIX
	-- Players in jail cannot receive most events (career, romance, activities, etc.)
	-- Only allow events specifically marked for prison or with category "prison"
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if state.InJail then
		local eventCategory = event._category or event.category or ""
		local allowedInPrison = event.allowedInPrison 
			or eventCategory == "prison" 
			or eventCategory == "crime"
			or (event.id and (
				string.find(event.id, "prison") 
				or string.find(event.id, "jail")
				or string.find(event.id, "inmate")
			))
		
		if not allowedInPrison then
			return false -- Block this event - player is incarcerated
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- HOSPITALIZATION CHECK - CRITICAL FIX
	-- Players in the hospital cannot do normal activities, only medical/recovery events
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if flags.hospitalized then
		local eventCategory = event._category or event.category or ""
		local allowedInHospital = event.allowedInHospital
			or eventCategory == "medical"
			or eventCategory == "recovery"
			or eventCategory == "random" -- Allow random events like recovery
			or (event.id and (
				string.find(event.id, "hospital")
				or string.find(event.id, "recovery")
				or string.find(event.id, "medical")
				or string.find(event.id, "health")
				or string.find(event.id, "injury")
			))
		
		if not allowedInHospital then
			return false -- Block this event - player is hospitalized
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- BASIC CHECKS
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Age range check (check both event.minAge/maxAge and conditions.minAge/maxAge)
	if minAge and age < minAge then return false end
	if maxAge and age > maxAge then return false end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Enforce ageBand restrictions!
	-- Many events set ageBand but it was NEVER enforced, letting kids get adult events
	-- like stock investing, gambling, bankruptcy, etc.
	-- ═══════════════════════════════════════════════════════════════════════════════
	local ageBand = event.ageBand
	if ageBand and ageBand ~= "any" then
		if ageBand == "child" then
			if age > 12 then return false end
		elseif ageBand == "teen" then
			if age < 13 or age > 17 then return false end
		elseif ageBand == "adult" then
			if age < 18 then return false end
		elseif ageBand == "senior" then
			if age < 65 then return false end
		elseif ageBand == "young_adult" then
			if age < 18 or age > 35 then return false end
		elseif ageBand == "middle_age" then
			if age < 35 or age > 64 then return false end
		end
	end
	
	-- One-time event already completed
	if event.oneTime and history.completed[event.id] then
		return false
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #712-715: IMPROVED COOLDOWN & VARIETY SYSTEM
	-- Events need stronger cooldowns to prevent repetition across lives
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- CRITICAL FIX #712: Longer default cooldown for generic events
	local cooldown = event.cooldown or 5 -- Increased from 3 to 5 years
	
	-- CRITICAL FIX #713: Even longer cooldowns for repeating childhood/teen events
	local eventCategory = event._category or event.category or ""
	if eventCategory == "childhood" or eventCategory == "teen" then
		cooldown = event.cooldown or 8 -- Longer cooldowns for formative years events
	end
	
	-- CRITICAL FIX #714: Generic random events need extra-long cooldowns
	if eventCategory == "random" then
		cooldown = event.cooldown or 7
	end
	
	local lastAge = history.lastOccurrence[event.id]
	if lastAge and (age - lastAge) < cooldown then
		return false
	end
	
	-- CRITICAL FIX #715: Track total occurrences to prevent common events from dominating
	local occurCount = history.occurrences[event.id] or 0
	local maxAllowed = event.maxOccurrences or 3 -- Reduced from 10 to 3
	if occurCount >= maxAllowed then
		return false
	end
	
	-- NOTE: Max occurrences is now checked above in CRITICAL FIX #715
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CATEGORY-BASED COOLDOWN - Prevent spamming of similar events
	-- e.g., don't show multiple injury events in quick succession
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	local eventCategory = event.category or event._category
	if eventCategory then
		-- Define category cooldowns (years between events of same category)
		local categoryCooldowns = {
			injury = 3,        -- At least 3 years between injury events
			illness = 2,       -- At least 2 years between illness events
			mental_health = 4, -- At least 4 years between mental health events
			disaster = 5,      -- At least 5 years between disasters
			crime = 2,         -- At least 2 years between crime events
		}
		
		local catCooldown = categoryCooldowns[eventCategory]
		if catCooldown then
			-- Check history.lastCategoryOccurrence
			history.lastCategoryOccurrence = history.lastCategoryOccurrence or {}
			local lastCatAge = history.lastCategoryOccurrence[eventCategory]
			if lastCatAge and (age - lastCatAge) < catCooldown then
				return false -- Too soon for another event of this category
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- FLAG REQUIREMENTS - Check player's life flags
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if event.requiresFlags then
		for flag, requiredValue in pairs(event.requiresFlags) do
			local playerHasFlag = flags[flag]
			
			if requiredValue == true and not playerHasFlag then
				return false -- Missing required flag
			end
			
			if requiredValue == false and playerHasFlag then
				return false -- Has blocked flag
			end
		end
	end
	
	-- Support old "conditions.requiredFlags" format (array of flag names)
	if cond.requiredFlags then
		for _, flag in ipairs(cond.requiredFlags) do
			if not flags[flag] then
				return false
			end
		end
	end
	
	-- CRITICAL FIX #479: Handle blockedByFlags as both array AND dictionary format
	if event.blockedByFlags then
		if #event.blockedByFlags > 0 then
			-- Array format: { "in_prison", "incarcerated" }
			for _, flag in ipairs(event.blockedByFlags) do
				if flags[flag] then
					return false -- Has blocking flag
				end
			end
		else
			-- Dictionary format: { in_prison = true }
			for flag, _ in pairs(event.blockedByFlags) do
				if flags[flag] then
					return false -- Has blocking flag
				end
			end
		end
	end
	
	-- Support old "conditions.blockedFlags" format (array of flag names)
	if cond.blockedFlags then
		for _, flag in ipairs(cond.blockedFlags) do
			if flags[flag] then
				return false
			end
		end
	end
	
	-- Support old "requiresNoJob" field (same as blockedByFlags = {employed})
	-- CRITICAL FIX: Check ALL job indicators to prevent job events for employed players
	if event.requiresNoJob then
		if state.CurrentJob then
			return false -- Has a current job
		end
		if flags.employed or flags.has_job or flags.has_teen_job then
			return false -- Has employment flags
		end
		-- Also check for tech/coding jobs that aren't tracked via flags
		if flags.coder or flags.tech_experience or flags.hacker_experience then
			return false -- Has tech job experience
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- STAT REQUIREMENTS - Check player's stats
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if event.requiresStats then
		local stats = state.Stats or state
		for stat, requirement in pairs(event.requiresStats) do
			local value = stats[stat] or state[stat] or 50
			
			if type(requirement) == "number" then
				if value < requirement then return false end
			elseif type(requirement) == "table" then
				if requirement.min and value < requirement.min then return false end
				if requirement.max and value > requirement.max then return false end
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- JOB/CAREER REQUIREMENTS - No career events if unemployed or retired!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if event.requiresJob then
		if not state.CurrentJob then
			return false -- MUST have a job
		end
		-- CRITICAL FIX: Also block if player is retired (even if CurrentJob wasn't cleared)
		if flags.retired then
			return false -- Retired players shouldn't get job events
		end
		-- CRITICAL FIX #2: Players in prison can't have work events!
		-- Even if they technically still have a "job", they can't go to work from prison
		if flags.in_prison or flags.incarcerated or state.InJail then
			return false -- Can't work from prison
		end
	end
	
	if event.requiresNoJob then
		if state.CurrentJob then
			return false -- MUST NOT have a job
		end
	end
	
	if event.requiresJobCategory then
		if not state.CurrentJob then
			return false
		end
		local jobCat = (state.CurrentJob.category or state.CurrentJob.Category or ""):lower()
		local jobId = (state.CurrentJob.id or ""):lower()
		
		-- CRITICAL FIX #504: Support both string and array for requiresJobCategory
		-- Entertainment careers (rapper, musician, actor, etc.) should NOT get corporate events
		local allowedCategories = event.requiresJobCategory
		if type(allowedCategories) == "string" then
			-- Single category string
			if jobCat ~= allowedCategories:lower() then
				return false
			end
		elseif type(allowedCategories) == "table" then
			-- Array of allowed categories
			local categoryMatch = false
			for _, allowedCat in ipairs(allowedCategories) do
				if jobCat == allowedCat:lower() then
					categoryMatch = true
					break
				end
			end
			if not categoryMatch then
				return false -- Job category not in allowed list
			end
		end
	end
	
	-- CRITICAL FIX #505: Block corporate events for entertainment careers
	-- Rappers, musicians, actors, etc. should NOT get "CEO email" events
	if event.requiresJob and state.CurrentJob then
		local jobCat = (state.CurrentJob.category or state.CurrentJob.Category or ""):lower()
		local jobId = (state.CurrentJob.id or ""):lower()
		
		-- Check if this is an entertainment career
		local isEntertainment = jobCat == "entertainment" or jobCat == "creative" or jobCat == "music"
			or jobId:find("rapper") or jobId:find("musician") or jobId:find("actor")
			or jobId:find("influencer") or jobId:find("youtuber") or jobId:find("streamer")
			or jobId:find("singer") or jobId:find("artist") or jobId:find("celebrity")
		
		-- Block corporate-specific events for entertainment careers
		local eventId = event.id or ""
		local isCorporateEvent = eventId:find("layoff") or eventId:find("fired_for_cause")
			or eventId:find("toxic_coworker") or eventId:find("ceo_") or eventId:find("hr_")
			or eventId:find("office_") or eventId:find("corporate")
		
		if isEntertainment and isCorporateEvent then
			return false -- Entertainment careers don't get corporate events
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- RELATIONSHIP REQUIREMENTS - No marriage events if single!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if event.requiresPartner then
		-- CRITICAL FIX: Check BOTH relationship table AND flags for partner status
		local hasPartnerRelation = state.Relationships and state.Relationships.partner
		local hasPartnerFlag = state.Flags and (state.Flags.has_partner or state.Flags.dating or state.Flags.engaged or state.Flags.married)
		if not hasPartnerRelation and not hasPartnerFlag then
			return false -- MUST have a partner
		end
	end
	
	if event.requiresSingle or event.requiresNoPartner then
		-- CRITICAL FIX: Check BOTH relationship table AND flags for partner status
		local hasPartnerRelation = state.Relationships and state.Relationships.partner
		local hasPartnerFlag = state.Flags and (state.Flags.has_partner or state.Flags.dating or state.Flags.engaged or state.Flags.married)
		if hasPartnerRelation or hasPartnerFlag then
			return false -- MUST be single
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- EDUCATION REQUIREMENTS
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if event.requiresEducation then
		local eduLevels = {
			none = 0, elementary = 1, middle_school = 2, high_school = 3,
			community = 4, associate = 4, bachelor = 5, master = 6,
			law = 7, medical = 7, doctorate = 8, phd = 8
		}
		
		local playerEdu = state.Education or "none"
		local playerLevel = eduLevels[playerEdu:lower()] or 0
		local requiredLevel = eduLevels[event.requiresEducation:lower()] or 0
		
		if playerLevel < requiredLevel then
			return false
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- PREREQUISITE EVENTS - Must have completed certain events first
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if event.requiresEvents then
		for _, reqEventId in ipairs(event.requiresEvents) do
			if not history.completed[reqEventId] and (history.occurrences[reqEventId] or 0) == 0 then
				return false
			end
		end
	end
	
	if event.blockedByEvents then
		for _, blockEventId in ipairs(event.blockedByEvents) do
			if history.completed[blockEventId] or (history.occurrences[blockEventId] or 0) > 0 then
				return false
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #44-46,51: MAFIA-SPECIFIC CONDITION CHECKS
	-- Mafia events use conditions.minRank, conditions.minHeat, conditions.promotionReady
	-- These were NOT being checked, causing events to trigger for wrong rank players!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Check for mob membership requirement (CRITICAL FIX #51)
	if event.requiresMobMembership then
		local mobState = state.MobState
		if not mobState or not mobState.inMob then
			if not flags.in_mob then
				return false -- Must be in a crime family
			end
		end
	end
	
	-- Check minRank condition (CRITICAL FIX #44)
	if cond.minRank then
		local mobState = state.MobState
		local playerRank = 0
		if mobState and mobState.inMob then
			playerRank = mobState.rankIndex or mobState.rankLevel or 1
		end
		if playerRank < cond.minRank then
			return false -- Not high enough rank
		end
	end
	
	-- Check minHeat condition (CRITICAL FIX #45)
	if cond.minHeat then
		local mobState = state.MobState
		local playerHeat = 0
		if mobState then
			playerHeat = mobState.heat or 0
		end
		if playerHeat < cond.minHeat then
			return false -- Not enough heat for this event
		end
	end
	
	-- Check promotionReady condition (CRITICAL FIX #46)
	if cond.promotionReady then
		local mobState = state.MobState
		if not mobState or not mobState.inMob then
			return false -- Not in mob
		end
		-- Check if player has enough respect for next rank
		-- This requires knowledge of rank thresholds
		local respectThresholds = { 0, 100, 500, 2000, 10000 }
		local currentRank = mobState.rankIndex or 1
		local nextRank = currentRank + 1
		local nextThreshold = respectThresholds[nextRank]
		if not nextThreshold then
			return false -- Already at max rank
		end
		if (mobState.respect or 0) < nextThreshold then
			return false -- Not enough respect for promotion
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #47: CUSTOM CHECK CALLBACK - For complex event conditions
	-- Events can define conditions.customCheck as a function for advanced logic
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if cond.customCheck and type(cond.customCheck) == "function" then
		local success, result = pcall(cond.customCheck, state)
		if success then
			if result == false then
				return false -- Custom condition check failed
			end
		end
	end
	
	-- Also support event-level customCheck for convenience
	if event.customCheck and type(event.customCheck) == "function" then
		local success, result = pcall(event.customCheck, state)
		if success then
			if result == false then
				return false -- Custom condition check failed
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CUSTOM ELIGIBILITY FUNCTION - For complex checks (like money thresholds)
	-- CRITICAL FIX: This allows events to have custom logic beyond simple flags
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if event.eligibility and type(event.eligibility) == "function" then
		local success, result = pcall(event.eligibility, state)
		if success then
			if result == false then
				return false -- Custom eligibility check failed
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- RANDOM CHANCE - Final roll (only if all other checks pass)
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if event.baseChance then
		local chance = event.baseChance
		-- Boost chance slightly for never-seen events
		if (history.occurrences[event.id] or 0) == 0 then
			chance = math.min(1, chance * 1.3)
		end
		if RANDOM:NextNumber() > chance then
			return false
		end
	end
	
	return true
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- WEIGHT CALCULATION - Prioritize variety and freshness
-- ════════════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #65/#66/#67: AGE-SPECIFIC MILESTONE EVENTS
-- These are events that MUST trigger at specific ages (DMV, graduation, etc.)
-- ═══════════════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
-- AGE-SPECIFIC GUARANTEED MILESTONE EVENTS
-- These events WILL trigger at specific ages (unless already triggered)
-- This ensures players don't miss important life moments like DMV, graduation, etc.
-- ═══════════════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #717-730: EXPANDED AGE MILESTONE EVENTS
-- More varied milestones at each age to prevent repetition
-- The system will pick ONE eligible event from the list for each age
-- ═══════════════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #736-740: MASSIVELY EXPANDED AGE MILESTONES
-- Each age now has 4-8 possible events to choose from
-- This dramatically reduces repetition across different lives
-- ═══════════════════════════════════════════════════════════════════════════════
local AgeMilestoneEvents = {
	-- BABY/TODDLER (0-4) - Lots of variety in early years
	[0] = { "royal_birth_announcement", "baby_first_smile", "baby_first_laugh", "newborn_checkup", "first_photo", "naming_ceremony" },
	[1] = { "royal_christening", "first_words", "first_steps", "baby_first_food", "baby_teething_pain", "first_birthday", "walk_talk_milestone" },
	[2] = { "toddler_potty_training", "toddler_tantrum", "toddler_language_explosion", "terrible_twos", "playground_adventure", "toddler_art_masterpiece" },
	[3] = { "first_public_appearance", "preschool_start", "imaginary_friend", "toddler_fear_dark", "first_pet_encounter", "bedtime_stories", "princess_prince_phase" },
	[4] = { "toddler_curiosity_incident", "toddler_sibling_dynamics", "toddler_picky_eater", "first_playdate", "learning_colors", "hide_and_seek_champion" },
	
	-- EARLY CHILDHOOD (5-8) - School and discovery
	[5] = { "first_day_kindergarten", "royal_education_choice", "stage_transition_child", "child_reading_discovery", "lost_first_tooth", "first_homework", "making_friends" },
	[6] = { "first_day_school", "first_best_friend", "child_show_and_tell", "child_music_lesson", "elementary_adventure", "learning_to_read", "playground_king" },
	[7] = { "child_playground_adventure", "child_sports_tryout", "child_allowance_lesson", "science_project", "first_crush_maybe", "school_play", "summer_reading" },
	[8] = { "learning_to_ride_bike", "child_video_games_discovery", "child_summer_camp", "sleepover_first", "collector_hobby", "tree_climbing", "neighborhood_explorer" },
	
	-- LATE CHILDHOOD (9-12) - Growing up
	[9] = { "discovered_passion", "child_first_crush", "hobby_discovery", "sports_team", "best_friend_forever", "school_award", "family_vacation" },
	[10] = { "talent_show", "double_digits", "school_competition", "first_cell_phone", "sleepover_party", "childhood_ending", "growing_independence" },
	[11] = { "middle_school_start", "royal_summer_vacation", "friend_group_changes", "new_interests", "voice_changing", "growth_spurt", "independence_growing" },
	[12] = { "elementary_graduation", "growing_up_fast", "teen_transition", "first_dance", "mature_conversations", "childhood_goodbye", "middle_school_life" },
	
	-- EARLY TEEN (13-15) - Identity formation
	[13] = { "stage_transition_teen", "teen_social_media", "talent_discovery", "teen_social_media_debut", "first_crush_serious", "style_change", "friend_drama" },
	[14] = { "class_selection", "teen_study_habits", "teen_friend_drama", "first_relationship", "high_school_prep", "rebel_phase", "identity_question" },
	[15] = { "learning_to_drive", "teen_part_time_job_decision", "teen_future_planning", "sweet_fifteen", "independence_push", "career_dream", "first_car_dream" },
	
	-- LATE TEEN (16-18) - Major milestones
	[16] = { "driving_license", "teen_first_job", "prom_invite", "fame_audition", "teen_first_heartbreak", "sweet_sixteen", "car_obsession", "college_prep" },
	[17] = { "high_school_graduation", "prom_invite", "senior_year", "college_applications", "last_summer", "farewell_friends", "adult_soon" },
	[18] = { "turning_18", "high_school_graduation", "moving_out", "young_adult_move_out", "coming_of_age_ball", "young_adult_adulting_struggle", "legal_adult", "vote_first_time" },
	
	-- YOUNG ADULT (19-24) - Independence and discovery
	[19] = { "college_experience", "young_adult_first_apartment", "new_city_life", "first_roommate", "homesick_blues", "freedom_excitement" },
	[20] = { "young_adult_fitness_resolution", "young_adult_financial_habits", "twenties_begin", "identity_crisis_light", "new_decade_new_me" },
	[21] = { "turning_21_legal_drinking", "first_legal_drink", "royal_military_service", "bar_hopping", "adult_responsibilities", "real_world_hits" },
	[22] = { "young_adult_career_crossroads", "college_graduation", "job_hunting", "degree_celebration", "real_job_search", "career_start" },
	[23] = { "young_adult_relationship_milestone", "first_real_job", "adult_friendship", "living_alone", "budget_reality" },
	[24] = { "quarter_life_reflection", "career_established", "friendship_evolution", "serious_dating", "life_direction" },
	
	-- MID-LATE 20s (25-29) - Settling into adulthood
	[25] = { "quarter_life_crisis", "royal_engagement_pressure", "late_20s_hobby_serious", "mid_twenties_milestone", "career_advancement", "relationship_pressure" },
	[26] = { "late_20s_social_circle_shift", "career_plateau", "friends_marrying", "biological_clock", "life_comparison" },
	[27] = { "late_20s_health_wake_up", "career_advancement", "settling_down_thoughts", "travel_urge", "achievement_review" },
	[28] = { "late_20s_life_assessment", "pre_30_panic", "relationship_milestone", "career_change_consideration", "fitness_focus" },
	[29] = { "approaching_30", "relationship_milestone", "decade_reflection", "bucket_list_rush", "life_audit" },
	
	-- 30s-40s - Established adulthood
	[30] = { "stage_transition_adult", "turning_30", "fame_breakthrough", "dirty_thirty", "real_adult_now", "life_reassessment" },
	[35] = { "royal_charity_focus", "career_peak", "mid_30s_reflection", "biological_deadline", "life_stability", "half_life_crisis" },
	[40] = { "turning_40", "midlife_reflection", "royal_mid_reign", "over_the_hill", "wisdom_gained", "health_priority" },
	
	-- 50s-60s - Later adulthood
	[50] = { "stage_transition_middle_age", "turning_50", "silver_jubilee", "half_century", "empty_nest", "grandparent_maybe" },
	[60] = { "golden_jubilee", "retirement_consideration", "senior_discount", "legacy_thoughts", "health_checks" },
	
	-- 65+ - Senior years
	[65] = { "stage_transition_senior", "retirement_decision", "royal_succession_planning", "medicare_eligible", "golden_years_begin" },
	[70] = { "golden_years", "legacy_planning", "diamond_jubilee", "seven_decades", "life_wisdom", "family_patriarch" },
	[75] = { "platinum_jubilee", "diamond_anniversary_life", "remarkable_longevity", "great_grandparent" },
	[80] = { "eighty_years_young", "centenarian_path", "family_elder", "life_celebration" },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #99/#100: PREMIUM MILESTONE EVENTS
-- These milestone events are for premium gamepass holders
-- ═══════════════════════════════════════════════════════════════════════════════
local PremiumMilestoneEvents = {
	-- Royalty milestones (require is_royalty flag)
	royalty = {
		[0] = "royal_birth_announcement",
		[1] = "royal_christening",
		[3] = "first_public_appearance",
		[6] = "royal_education_choice",
		[18] = "coming_of_age_ball",
		[21] = "royal_military_service",
		[25] = "royal_engagement_pressure",
		[50] = "silver_jubilee",
		[60] = "golden_jubilee",
		[70] = "diamond_jubilee",
		[75] = "platinum_jubilee",
	},
	-- Mafia milestones (require in_mob flag)
	mafia = {
		-- These trigger based on rank/respect, not age
	},
	-- Celebrity milestones (require fame_career flag)
	celebrity = {
		[13] = "talent_discovery",
		[16] = "fame_audition",
		[21] = "first_big_break",
		[25] = "award_nomination",
		[30] = "fame_breakthrough",
		[35] = "career_peak",
		[40] = "comeback_opportunity",
		[50] = "lifetime_achievement",
	},
}

local function isAgeMilestoneEvent(eventId, age)
	local milestones = AgeMilestoneEvents[age]
	if not milestones then return false end
	for _, id in ipairs(milestones) do
		if id == eventId then return true end
	end
	return false
end

local function calculateEventWeight(event, state)
	local history = getEventHistory(state)
	local baseWeight = event.weight or 10
	local weight = baseWeight
	local age = state.Age or 0
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #67: MASSIVE BOOST for age-specific milestone events
	-- Events like DMV at 15-16, graduation at 17-18 should ALWAYS trigger
	-- ═══════════════════════════════════════════════════════════════════════════════
	if isAgeMilestoneEvent(event.id, age) then
		local eventOccurred = (history.occurrences[event.id] or 0) > 0
		if not eventOccurred then
			weight = weight * 100 -- MASSIVE boost to guarantee it triggers
		end
	end
	
	-- BOOST: Never-seen events get priority
	local occurCount = history.occurrences[event.id] or 0
	if occurCount == 0 then
		weight = weight * 2.5
	elseif occurCount == 1 then
		weight = weight * 1.5
	end
	
	-- BOOST: Milestone/priority events
	if event.priority == "high" or event.isMilestone then
		weight = weight * 3
	end
	
	-- BOOST: One-time events that haven't been seen yet
	if event.oneTime and occurCount == 0 then
		weight = weight * 2
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #98: PREMIUM EVENT WEIGHT BOOSTING
	-- Premium events should have higher priority for gamepass holders
	-- This ensures royal/mafia/celebrity events actually trigger
	-- ═══════════════════════════════════════════════════════════════════════════════
	local flags = state.Flags or {}
	
	-- Boost royal events for royal players
	if event.isRoyalOnly then
		local isRoyal = flags.is_royalty or flags.royal_birth or (state.RoyalState and state.RoyalState.isRoyal)
		if isRoyal then
			weight = weight * 3 -- Triple weight for royal events when player is royal
		end
	end
	
	-- Boost mafia events for mob members
	if event.isMafiaOnly then
		local isInMob = flags.in_mob or (state.MobState and state.MobState.inMob)
		if isInMob then
			weight = weight * 3 -- Triple weight for mafia events when player is in mob
		end
	end
	
	-- Boost celebrity events for famous players
	if event.isCelebrityOnly then
		local hasFameCareer = flags.fame_career or (state.FameState and state.FameState.careerPath)
		if hasFameCareer then
			weight = weight * 3 -- Triple weight for celebrity events when player has fame career
		end
	end
	
	-- Extra boost for premium milestone events
	if event.isMilestone then
		if event.isRoyalOnly or event.isMafiaOnly or event.isCelebrityOnly then
			weight = weight * 2 -- Extra boost for premium milestones
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #65/#66: Age-appropriate milestone boosting
	-- Boost events based on how appropriate they are for current age
	-- ═══════════════════════════════════════════════════════════════════════════════
	local minAge = event.minAge or 0
	local maxAge = event.maxAge or 999
	
	-- If event is at its PRIME age, boost it
	local midAge = (minAge + maxAge) / 2
	local ageDistance = math.abs(age - midAge)
	local ageRange = (maxAge - minAge) / 2
	if ageRange > 0 then
		local ageRelevance = 1 - (ageDistance / ageRange)
		if ageRelevance > 0.8 then
			weight = weight * 1.5 -- Prime age for this event
		end
	end
	
	-- REDUCE: Recently seen categories (variety)
	for _, recentCat in ipairs(history.recentCategories or {}) do
		if recentCat == event._category then
			weight = weight * 0.6
			break
		end
	end
	
	-- REDUCE: Recently seen events
	for _, recentId in ipairs(history.recentEvents or {}) do
		if recentId == event.id then
			weight = weight * 0.3
			break
		end
	end
	
	-- REDUCE: Time since last occurrence
	local lastAge = history.lastOccurrence[event.id]
	if lastAge then
		local yearsSince = age - lastAge
		if yearsSince < 3 then
			weight = weight * 0.4
		elseif yearsSince < 5 then
			weight = weight * 0.7
		end
	end
	
	return math.max(weight, 0.1)
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- BUILD YEAR QUEUE - Main event selection logic
-- ════════════════════════════════════════════════════════════════════════════════════

function LifeEvents.buildYearQueue(state, options)
	options = options or {}
	local maxEvents = options.maxEvents or 1
	
	if not state then
		warn("[LifeEvents] buildYearQueue called with nil state")
		return {}
	end
	
	local age = state.Age or 0
	local stage = LifeEvents.getLifeStage(age)
	local selectedEvents = {}
	
	-- Get categories relevant to this life stage
	local categories = StageCategories[stage.id] or { "random" }
	
	-- Add career category only if player has a job
	if state.CurrentJob and age >= 18 then
		local hasCareer = false
		for _, cat in ipairs(categories) do
			if cat == "career" then hasCareer = true break end
		end
		if not hasCareer then
			table.insert(categories, "career")
		end
		
		-- CRITICAL FIX: Add specialized career categories based on job type
		-- This ensures racing drivers get racing events, hackers get hacker events, etc.
		local jobCategory = state.CurrentJob.category or ""
		jobCategory = jobCategory:lower()
		local jobId = (state.CurrentJob.id or ""):lower()
		
		if jobCategory == "racing" then
			local hasRacing = false
			for _, cat in ipairs(categories) do
				if cat == "career_racing" then hasRacing = true break end
			end
			if not hasRacing then
				table.insert(categories, "career_racing")
			end
		elseif jobCategory == "hacker" or jobCategory == "tech" then
			local hasHacker = false
			for _, cat in ipairs(categories) do
				if cat == "career_hacker" then hasHacker = true break end
			end
			if not hasHacker then
				table.insert(categories, "career_hacker")
			end
		-- CRITICAL FIX: Add police career category for law enforcement jobs
		elseif jobCategory == "government" or jobCategory == "law_enforcement" or 
			   jobId:find("police") or jobId:find("detective") or jobId:find("officer") then
			local hasPolice = false
			for _, cat in ipairs(categories) do
				if cat == "career_police" then hasPolice = true break end
			end
			if not hasPolice then
				table.insert(categories, "career_police")
			end
		-- CRITICAL FIX: Add fast food/service career events
		elseif jobCategory == "entry" or jobCategory == "service" or jobCategory == "retail" or
			   jobId:find("fastfood") or jobId:find("waiter") or jobId:find("barista") or
			   jobId:find("cashier") or jobId:find("retail") or jobId:find("server") then
			local hasService = false
			for _, cat in ipairs(categories) do
				if cat == "career_service" then hasService = true break end
			end
			if not hasService then
				table.insert(categories, "career_service")
			end
		end
	end
	
	-- CRITICAL FIX: Add street hustler events if player has hustler flags
	-- Even without a "job", hustlers should get their events
	if state.Flags and (state.Flags.street_hustler or state.Flags.dealer or state.Flags.supplier) then
		local hasStreet = false
		for _, cat in ipairs(categories) do
			if cat == "career_street" then hasStreet = true break end
		end
		if not hasStreet then
			table.insert(categories, "career_street")
		end
	end
	
	-- CRITICAL FIX: Add asset events if player owns any assets
	if state.Assets then
		local hasAssets = false
		for assetType, assetList in pairs(state.Assets) do
			if type(assetList) == "table" and #assetList > 0 then
				hasAssets = true
				break
			end
		end
		if hasAssets then
			local hasAssetCat = false
			for _, cat in ipairs(categories) do
				if cat == "assets" then hasAssetCat = true break end
			end
			if not hasAssetCat then
				table.insert(categories, "assets")
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #68: PREMIUM GAMEPASS EVENT CATEGORIES
	-- Add premium event categories ONLY for players who have the gamepass AND are active in it
	-- This ensures premium events appear in the event pool when appropriate
	-- ═══════════════════════════════════════════════════════════════════════════════
	local flags = state.Flags or {}
	
	-- MAFIA: Only add category if player has gamepass AND is in mob
	if flags.mafia_gamepass or (state.GamepassOwnership and state.GamepassOwnership.Mafia) then
		local isInMob = flags.in_mob or (state.MobState and state.MobState.inMob)
		if isInMob then
			-- Player is in mob - add mafia events
			local hasMafiaCat = false
			for _, cat in ipairs(categories) do
				if cat == "mafia" or cat == "crime" then hasMafiaCat = true break end
			end
			if not hasMafiaCat then
				table.insert(categories, "mafia")
			end
		else
			-- Player NOT in mob yet - only add recruitment events category
			local hasRecruitCat = false
			for _, cat in ipairs(categories) do
				if cat == "mafia_recruit" then hasRecruitCat = true break end
			end
			if not hasRecruitCat then
				table.insert(categories, "mafia_recruit")
			end
		end
	end
	
	-- ROYALTY: Only add category if player has gamepass AND is royalty
	if flags.royalty_gamepass or (state.GamepassOwnership and state.GamepassOwnership.Royalty) then
		local isRoyal = flags.is_royalty or flags.royal_birth or (state.RoyalState and state.RoyalState.isRoyal)
		if isRoyal then
			local hasRoyalCat = false
			for _, cat in ipairs(categories) do
				if cat == "royalty" or cat == "royal" then hasRoyalCat = true break end
			end
			if not hasRoyalCat then
				table.insert(categories, "royalty")
			end
		end
	end
	
	-- CELEBRITY: Only add category if player has gamepass AND has fame career OR natural fame
	if flags.celebrity_gamepass or (state.GamepassOwnership and state.GamepassOwnership.Celebrity) then
		local hasFameCareer = flags.fame_career or flags.career_actor 
			or flags.career_musician or flags.career_influencer or flags.career_athlete
			or (state.FameState and state.FameState.careerPath)
		local hasFame = (state.Fame or 0) >= 10
		
		if hasFameCareer or hasFame then
			local hasCelebCat = false
			for _, cat in ipairs(categories) do
				if cat == "celebrity" or cat == "fame" then hasCelebCat = true break end
			end
			if not hasCelebCat then
				table.insert(categories, "celebrity")
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #105/#116: GUARANTEED PREMIUM EVENT CHECK
	-- For royal/mafia/celebrity players, ensure they get premium events frequently
	-- This runs a 40% chance to force a premium event for engaged premium players
	-- Without this, premium events were being drowned out by regular events!
	-- ═══════════════════════════════════════════════════════════════════════════════
	local history = getEventHistory(state)
	local RANDOM_LOCAL = Random.new()
	
	-- Royal players: 40% chance to get a royal event each year
	local isRoyal = flags.is_royalty or flags.royal_birth or (state.RoyalState and state.RoyalState.isRoyal)
	if isRoyal and RANDOM_LOCAL:NextNumber() < 0.40 then
		local royalEvents = EventsByCategory["royalty"] or {}
		local eligibleRoyalEvents = {}
		
		for _, event in ipairs(royalEvents) do
			if canEventTrigger(event, state) then
				local occurCount = (history.occurrences[event.id] or 0)
				if occurCount == 0 or not event.oneTime then
					table.insert(eligibleRoyalEvents, event)
				end
			end
		end
		
		if #eligibleRoyalEvents > 0 then
			-- Pick a random eligible royal event
			local chosenEvent = eligibleRoyalEvents[RANDOM_LOCAL:NextInteger(1, #eligibleRoyalEvents)]
			table.insert(selectedEvents, chosenEvent)
			recordEventShown(state, chosenEvent)
			return selectedEvents -- Return early - royal event takes priority
		end
	end
	
	-- Mafia players: 35% chance to get a mafia event each year
	local isInMob = flags.in_mob or (state.MobState and state.MobState.inMob)
	if isInMob and RANDOM_LOCAL:NextNumber() < 0.35 then
		local mafiaEvents = EventsByCategory["mafia"] or {}
		local eligibleMafiaEvents = {}
		
		for _, event in ipairs(mafiaEvents) do
			if canEventTrigger(event, state) then
				local occurCount = (history.occurrences[event.id] or 0)
				if occurCount == 0 or not event.oneTime then
					table.insert(eligibleMafiaEvents, event)
				end
			end
		end
		
		if #eligibleMafiaEvents > 0 then
			local chosenEvent = eligibleMafiaEvents[RANDOM_LOCAL:NextInteger(1, #eligibleMafiaEvents)]
			table.insert(selectedEvents, chosenEvent)
			recordEventShown(state, chosenEvent)
			return selectedEvents
		end
	end
	
	-- Celebrity players: 35% chance to get a celebrity event each year
	local hasFameCareer = flags.fame_career or (state.FameState and state.FameState.careerPath)
	if hasFameCareer and RANDOM_LOCAL:NextNumber() < 0.35 then
		local celebEvents = EventsByCategory["celebrity"] or {}
		local eligibleCelebEvents = {}
		
		for _, event in ipairs(celebEvents) do
			if canEventTrigger(event, state) then
				local occurCount = (history.occurrences[event.id] or 0)
				if occurCount == 0 or not event.oneTime then
					table.insert(eligibleCelebEvents, event)
				end
			end
		end
		
		if #eligibleCelebEvents > 0 then
			-- CRITICAL FIX #433: Was using celebEvents instead of eligibleCelebEvents!
			-- This could pick an ineligible event or cause index out of bounds
			local chosenEvent = eligibleCelebEvents[RANDOM_LOCAL:NextInteger(1, #eligibleCelebEvents)]
			table.insert(selectedEvents, chosenEvent)
			recordEventShown(state, chosenEvent)
			return selectedEvents
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #67: GUARANTEED MILESTONE EVENTS
	-- First, check if there's an age-specific milestone that MUST trigger
	-- These are events that should NEVER be skipped (DMV at 16, graduation at 18, etc.)
	-- ═══════════════════════════════════════════════════════════════════════════════
	local guaranteedMilestones = AgeMilestoneEvents[age]
	
	if guaranteedMilestones then
		for _, milestoneId in ipairs(guaranteedMilestones) do
			local event = AllEvents[milestoneId]
			if event then
				-- Check if event already occurred
				local occurCount = (history.occurrences[milestoneId] or 0)
				if occurCount == 0 then
					-- Event hasn't happened yet - check if it can trigger
					if canEventTrigger(event, state) then
						-- GUARANTEED trigger for age-specific milestones!
						table.insert(selectedEvents, event)
						recordEventShown(state, event)
						return selectedEvents -- Return early - milestone takes priority
					end
				end
			end
		end
	end
	
	-- Collect all eligible events
	local candidateEvents = {}
	local priorityEvents = {}
	
	for _, categoryName in ipairs(categories) do
		local categoryEvents = EventsByCategory[categoryName] or {}
		for _, event in ipairs(categoryEvents) do
			if canEventTrigger(event, state) then
				local weight = calculateEventWeight(event, state)
				
				-- CRITICAL FIX: Check if this is an age milestone that hasn't triggered
				local isAgeMilestone = isAgeMilestoneEvent(event.id, age)
				local eventOccurred = (history.occurrences[event.id] or 0) > 0
				
				local candidate = {
					event = event,
					weight = weight,
					isPriority = event.priority == "high" or event.isMilestone or (isAgeMilestone and not eventOccurred),
				}
				
				if candidate.isPriority then
					table.insert(priorityEvents, candidate)
				else
					table.insert(candidateEvents, candidate)
				end
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #735: Use WEIGHTED RANDOM for priority events too!
	-- The old code always picked the highest-weighted event, causing "learning_to_ride_bike"
	-- and other milestone events to repeat every life since they had the same weight boost.
	-- Now we use weighted random selection to pick from ALL eligible milestone events.
	-- ═══════════════════════════════════════════════════════════════════════════════
	if #priorityEvents > 0 then
		-- Use weighted random selection instead of just picking highest weight
		local totalPriorityWeight = 0
		for _, candidate in ipairs(priorityEvents) do
			totalPriorityWeight = totalPriorityWeight + candidate.weight
		end
		
		if totalPriorityWeight > 0 then
			local roll = RANDOM:NextNumber() * totalPriorityWeight
			local cumulative = 0
			
			for _, candidate in ipairs(priorityEvents) do
				cumulative = cumulative + candidate.weight
				if roll <= cumulative then
					table.insert(selectedEvents, candidate.event)
					recordEventShown(state, candidate.event)
					return selectedEvents
				end
			end
		end
		
		-- Fallback: pick first if weighted selection somehow failed
		local chosen = priorityEvents[1]
		table.insert(selectedEvents, chosen.event)
		recordEventShown(state, chosen.event)
		return selectedEvents
	end
	
	-- Check for quiet year (no events)
	local quietChance = stage.quietChance or 0.4
	if #candidateEvents == 0 or RANDOM:NextNumber() < quietChance then
		return {}
	end
	
	-- Weighted random selection
	local totalWeight = 0
	for _, candidate in ipairs(candidateEvents) do
		totalWeight = totalWeight + candidate.weight
	end
	
	if totalWeight <= 0 then
		return {}
	end
	
	for _ = 1, maxEvents do
		if #candidateEvents == 0 then break end
		
		local roll = RANDOM:NextNumber() * totalWeight
		local cumulative = 0
		
		for i, candidate in ipairs(candidateEvents) do
			cumulative = cumulative + candidate.weight
			if roll <= cumulative then
				table.insert(selectedEvents, candidate.event)
				recordEventShown(state, candidate.event)
				
				-- Remove from pool and update total weight
				totalWeight = totalWeight - candidate.weight
				table.remove(candidateEvents, i)
				break
			end
		end
	end
	
	return selectedEvents
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- ACCESSOR FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════════════

function LifeEvents.getEvent(eventId)
	return AllEvents[eventId]
end

function LifeEvents.getAllEvents()
	return AllEvents
end

function LifeEvents.getEventsByCategory(categoryName)
	return EventsByCategory[categoryName] or {}
end

function LifeEvents.getLoadedModules()
	return LoadedModules
end

function LifeEvents.getEventCount()
	local count = 0
	for _ in pairs(AllEvents) do
		count = count + 1
	end
	return count
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- EVENT ENGINE - Handles event completion and outcomes
-- ════════════════════════════════════════════════════════════════════════════════════

local EventEngine = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ASSET MANAGEMENT API
-- These helpers let events add/remove assets consistently (BitLife-style glue)
-- ═══════════════════════════════════════════════════════════════════════════════

function EventEngine.ensureAssetTables(state)
	state.Assets = state.Assets or {}
	state.Assets.Properties = state.Assets.Properties or {}
	state.Assets.Vehicles = state.Assets.Vehicles or {}
	state.Assets.Items = state.Assets.Items or {}
	state.Assets.Crypto = state.Assets.Crypto or {}
	state.Assets.Investments = state.Assets.Investments or {}
	state.Assets.Businesses = state.Assets.Businesses or {}
end

--[[
	EventEngine.addAsset(state, assetType, assetData)
	
	Adds an asset to the player's state.
	
	@param state - The player's LifeState object
	@param assetType - One of: "property", "vehicle", "item", "crypto", "investment", "business"
	@param assetData - Table with asset information:
		{
			id = "unique_id",
			name = "Display Name",
			emoji = "🚗" (optional),
			price = 2500,
			value = 2500,
			condition = 35 (optional, for vehicles),
			acquiredAge = state.Age (optional),
			acquiredYear = state.Year (optional),
			isEventAcquired = true (optional, marks as story-given)
		}
	
	Example:
		EventEngine.addAsset(state, "vehicle", {
			id = "cheap_used_car",
			name = "Cheap Used Car",
			emoji = "🚗",
			price = 2500,
			value = 2500,
			condition = 35,
			acquiredAge = state.Age,
			isEventAcquired = true,
		})
]]
function EventEngine.addAsset(state, assetType, assetData)
	EventEngine.ensureAssetTables(state)
	
	-- Normalize asset type to plural category name
	local categoryMap = {
		property = "Properties",
		properties = "Properties",
		vehicle = "Vehicles",
		vehicles = "Vehicles",
		item = "Items",
		items = "Items",
		crypto = "Crypto",
		investment = "Investments",
		investments = "Investments",
		business = "Businesses",
		businesses = "Businesses",
	}
	
	local category = categoryMap[assetType:lower()]
	if not category then
		warn("[EventEngine] Unknown asset type:", assetType)
		return false
	end
	
	-- Ensure asset has required fields
	local asset = {
		id = assetData.id or (assetType .. "_" .. tostring(RANDOM:NextInteger(10000, 99999))),
		name = assetData.name or "Unknown Asset",
		emoji = assetData.emoji,
		price = assetData.price or 0,
		value = assetData.value or assetData.price or 0,
		condition = assetData.condition,
		acquiredAge = assetData.acquiredAge or (state.Age or 0),
		acquiredYear = assetData.acquiredYear or (state.Year or 2025),
		isEventAcquired = assetData.isEventAcquired,
		income = assetData.income,
	}
	
	-- Use LifeState method if available, otherwise direct insert
	if state.AddAsset and type(state.AddAsset) == "function" then
		state:AddAsset(category, asset)
	else
		state.Assets[category] = state.Assets[category] or {}
		table.insert(state.Assets[category], asset)
	end
	
	return true
end

--[[
	EventEngine.removeAssetById(state, assetType, assetId)
	
	Removes an asset from the player's state by its ID.
	
	@param state - The player's LifeState object
	@param assetType - One of: "property", "vehicle", "item", "crypto", "investment", "business"
	@param assetId - The unique ID of the asset to remove
	
	@returns The removed asset, or nil if not found
]]
function EventEngine.removeAssetById(state, assetType, assetId)
	EventEngine.ensureAssetTables(state)
	
	-- Normalize asset type
	local categoryMap = {
		property = "Properties",
		properties = "Properties",
		vehicle = "Vehicles",
		vehicles = "Vehicles",
		item = "Items",
		items = "Items",
		crypto = "Crypto",
		investment = "Investments",
		investments = "Investments",
		business = "Businesses",
		businesses = "Businesses",
	}
	
	local category = categoryMap[assetType:lower()]
	if not category then
		warn("[EventEngine] Unknown asset type:", assetType)
		return nil
	end
	
	-- Use LifeState method if available
	if state.RemoveAsset and type(state.RemoveAsset) == "function" then
		return state:RemoveAsset(category, assetId)
	end
	
	-- Fallback: direct removal
	local bucket = state.Assets[category]
	if not bucket then return nil end
	
	for i = #bucket, 1, -1 do
		if bucket[i].id == assetId then
			return table.remove(bucket, i)
		end
	end
	
	return nil
end

--[[
	EventEngine.hasAsset(state, assetType, assetId)
	
	Checks if the player owns a specific asset.
	
	@param state - The player's LifeState object
	@param assetType - Asset category (or nil to search all)
	@param assetId - The asset ID to find
	
	@returns true if owned, false otherwise
]]
function EventEngine.hasAsset(state, assetType, assetId)
	EventEngine.ensureAssetTables(state)
	
	local categoryMap = {
		property = "Properties",
		properties = "Properties",
		vehicle = "Vehicles",
		vehicles = "Vehicles",
		item = "Items",
		items = "Items",
		crypto = "Crypto",
		investment = "Investments",
		investments = "Investments",
		business = "Businesses",
		businesses = "Businesses",
	}
	
	-- If no specific type, search all categories
	local categoriesToSearch
	if assetType then
		local category = categoryMap[assetType:lower()]
		if not category then return false end
		categoriesToSearch = { category }
	else
		categoriesToSearch = { "Properties", "Vehicles", "Items", "Crypto", "Investments", "Businesses" }
	end
	
	for _, category in ipairs(categoriesToSearch) do
		local bucket = state.Assets[category]
		if bucket then
			for _, asset in ipairs(bucket) do
				if asset.id == assetId then
					return true
				end
			end
		end
	end
	
	return false
end

--[[
	EventEngine.countAssets(state, assetType)
	
	Counts how many assets the player owns in a category.
	
	@param state - The player's LifeState object
	@param assetType - Asset category (or nil for total count)
	
	@returns number of assets
]]
function EventEngine.countAssets(state, assetType)
	EventEngine.ensureAssetTables(state)
	
	local categoryMap = {
		property = "Properties",
		properties = "Properties",
		vehicle = "Vehicles",
		vehicles = "Vehicles",
		item = "Items",
		items = "Items",
		crypto = "Crypto",
		investment = "Investments",
		investments = "Investments",
		business = "Businesses",
		businesses = "Businesses",
	}
	
	if assetType then
		local category = categoryMap[assetType:lower()]
		if not category then return 0 end
		return #(state.Assets[category] or {})
	end
	
	-- Count all assets
	local total = 0
	for _, category in pairs(state.Assets) do
		if type(category) == "table" then
			total = total + #category
		end
	end
	return total
end

-- Name pools for dynamic relationship creation (EXPANDED - 100+ names each for variety)
local NamePools = {
	male = {
		-- Classic American
		"James", "Michael", "David", "John", "Robert", "Christopher", "Daniel", "Matthew", "Anthony", "Mark",
		"Steven", "Andrew", "Joshua", "Kevin", "Brian", "Ryan", "Justin", "Brandon", "Eric", "Tyler",
		"Alexander", "Jake", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Oliver", "Aiden", "Carter",
		"Sebastian", "Henry", "Owen", "Jack", "Leo", "Nathan", "Logan", "Dylan", "Jayden", "Wyatt",
		"Caleb", "Luke", "Gabriel", "Isaac", "Connor", "Elijah", "Hunter", "Cameron", "Evan", "Austin",
		-- Hispanic/Latino
		"Diego", "Carlos", "Miguel", "Rafael", "Alejandro", "Juan", "Marco", "Antonio", "Luis", "Eduardo",
		"Mateo", "Santiago", "Javier", "Pablo", "Ricardo", "Andres", "Fernando", "Hector", "Oscar", "Victor",
		-- African American
		"Jamal", "Darius", "Malik", "Terrence", "Andre", "DeShawn", "Marcus", "Dante", "Isaiah", "Xavier",
		-- Asian
		"Kenji", "Ryu", "Akira", "Ren", "Sora", "Kai", "Hiro", "Yuto", "Jun", "Tao",
		"Wei", "Chen", "Jin", "Min", "Jae", "Sung", "Arjun", "Raj", "Vikram", "Rahul",
		-- Middle Eastern
		"Amir", "Omar", "Hassan", "Khalid", "Zaid", "Tariq", "Yusuf", "Ahmed", "Ali", "Samir"
	},
	female = {
		-- Classic American
		"Emma", "Olivia", "Sophia", "Isabella", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn", "Abigail",
		"Emily", "Elizabeth", "Sofia", "Avery", "Ella", "Scarlett", "Grace", "Chloe", "Victoria", "Riley",
		"Aria", "Lily", "Zoey", "Hannah", "Layla", "Nora", "Zoe", "Leah", "Hazel", "Luna",
		"Penelope", "Stella", "Aurora", "Violet", "Savannah", "Audrey", "Brooklyn", "Claire", "Skylar", "Paisley",
		"Natalie", "Madison", "Addison", "Eleanor", "Lillian", "Aubrey", "Ellie", "Camila", "Genesis", "Kennedy",
		-- Hispanic/Latino
		"Maria", "Carmen", "Valentina", "Lucia", "Ana", "Rosa", "Elena", "Gabriela", "Natalia", "Isabella",
		"Camila", "Mariana", "Daniela", "Fernanda", "Paula", "Andrea", "Carolina", "Diana", "Adriana", "Alejandra",
		-- African American
		"Aaliyah", "Destiny", "Diamond", "Jasmine", "Imani", "Tiana", "Sierra", "Aisha", "Nia", "Maya",
		-- Asian
		"Sakura", "Yuki", "Mei", "Hana", "Aiko", "Rin", "Mika", "Kaori", "Nanami", "Koharu",
		"Lin", "Mei-Lin", "Jing", "Yuna", "Hye", "Ji-Yeon", "Priya", "Ananya", "Isha", "Diya",
		-- Middle Eastern
		"Fatima", "Zahra", "Leila", "Nadia", "Sara", "Amira", "Yasmin", "Layla", "Mariam", "Aisha"
	}
}

local function generateName(gender)
	local pool = NamePools[gender] or NamePools.male
	return pool[RANDOM:NextInteger(1, #pool)]
end

local function getOppositeGender(playerGender)
	local g = (playerGender or "male"):lower()
	return g == "male" and "female" or "male"
end

function EventEngine.createRelationship(state, relType, options)
	options = options or {}
	state.Relationships = state.Relationships or {}
	
	local age = state.Age or 20
	
	-- CRITICAL FIX: For romance/partner, use "partner" as the ID to prevent duplicates!
	-- Previously, this created BOTH state.Relationships["romance_XXXX"] AND state.Relationships.partner
	-- pointing to the same object, causing duplicate display in RelationshipsScreen
	local id
	if relType == "romance" or relType == "partner" then
		id = "partner"  -- Use consistent ID for partners
	else
		id = relType .. "_" .. tostring(RANDOM:NextInteger(1000, 9999)) .. "_" .. tostring(tick())
	end
	
	local gender
	local name = options.name
	local relAge = age
	
	if relType == "romance" or relType == "partner" then
		gender = getOppositeGender(state.Gender)
		name = name or generateName(gender)
		relAge = math.max(18, age + RANDOM:NextInteger(-5, 5))
	elseif relType == "friend" then
		gender = options.gender or (RANDOM:NextNumber() > 0.5 and "male" or "female")
		name = name or generateName(gender)
		relAge = math.max(5, age + RANDOM:NextInteger(-3, 3))
	else
		gender = options.gender or "male"
		name = name or generateName(gender)
	end
	
	local relationship = {
		id = id,
		name = name,
		type = relType,
		role = options.role or (relType == "romance" and "Partner" or relType:sub(1,1):upper() .. relType:sub(2)),
		relationship = options.startLevel or RANDOM:NextInteger(50, 75),
		age = relAge,
		gender = gender,
		alive = true,
		metAge = state.Age,
		metYear = state.Year or 2025,
	}
	
	-- CRITICAL FIX: Only store in ONE location, not two!
	-- For partners, store at Relationships.partner (which is also Relationships["partner"])
	-- For friends/others, store at Relationships[id]
	if relType == "romance" or relType == "partner" then
		state.Relationships.partner = relationship
		state.Flags = state.Flags or {}
		state.Flags.has_partner = true
	else
		state.Relationships[id] = relationship
	end
	
	return relationship
end

function EventEngine.completeEvent(eventDef, choiceIndex, state)
	-- CRITICAL FIX #115: Full nil safety for event completion
	if not eventDef then
		warn("[EventEngine] Invalid event definition - nil")
		return nil
	end
	if not eventDef.choices then
		warn("[EventEngine] Invalid event definition - no choices:", eventDef.id or "unknown")
		return nil
	end
	if not state then
		warn("[EventEngine] Invalid state - nil")
		return nil
	end
	
	-- CRITICAL FIX #116: Validate choiceIndex is within bounds
	if type(choiceIndex) ~= "number" or choiceIndex < 1 or choiceIndex > #eventDef.choices then
		warn("[EventEngine] Invalid choice index:", choiceIndex, "for event:", eventDef.id, "max:", #eventDef.choices)
		return nil
	end
	
	local choice = eventDef.choices[choiceIndex]
	if not choice then
		warn("[EventEngine] Choice at index is nil:", choiceIndex)
		return nil
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Check per-choice eligibility BEFORE applying effects
	-- This prevents players from selecting choices they can't afford or aren't qualified for
	-- ═══════════════════════════════════════════════════════════════════════════════
	if choice.eligibility and type(choice.eligibility) == "function" then
		local success, eligible, failReason = pcall(choice.eligibility, state)
		if success then
			if eligible == false then
				warn("[EventEngine] Choice eligibility failed:", eventDef.id, "choice:", choiceIndex, "reason:", failReason or "unknown")
				return {
					success = false,
					failed = true,
					failReason = failReason or "You can't select this option right now.",
					eventId = eventDef.id,
					choiceIndex = choiceIndex,
				}
			end
		else
			warn("[EventEngine] Choice eligibility function error:", eligible)
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #502: Check requiresGamepass on choices for premium options
	-- Premium choices (God Mode, Mafia, Celebrity, Royalty) require gamepass ownership
	-- This enables tasteful gamepass integration without forcing purchases
	-- ═══════════════════════════════════════════════════════════════════════════════
	if choice.requiresGamepass then
		local gamepassKey = choice.requiresGamepass
		local flags = state.Flags or {}
		local gamepassOwnership = state.GamepassOwnership or {}
		
		-- Map gamepass keys to flag names
		local gamepassToFlag = {
			GOD_MODE = "god_mode_gamepass",
			MAFIA = "mafia_gamepass",
			CELEBRITY = "celebrity_gamepass",
			ROYALTY = "royalty_gamepass",
			TIME_MACHINE = "time_machine_gamepass",
		}
		local gamepassToOwnership = {
			GOD_MODE = "godMode",
			MAFIA = "mafia",
			CELEBRITY = "celebrity",
			ROYALTY = "royalty",
			TIME_MACHINE = "timeMachine",
		}
		
		local flagName = gamepassToFlag[gamepassKey]
		local ownershipName = gamepassToOwnership[gamepassKey]
		local hasGamepass = flags[flagName] or gamepassOwnership[ownershipName]
		
		if not hasGamepass then
			-- Player doesn't have the required gamepass
			local gamepassNames = {
				GOD_MODE = "God Mode",
				MAFIA = "Mafia",
				CELEBRITY = "Celebrity",
				ROYALTY = "Royalty",
				TIME_MACHINE = "Time Machine",
			}
			local gamepassName = gamepassNames[gamepassKey] or gamepassKey
			local emoji = choice.gamepassEmoji or "🔒"
			
			return {
				success = false,
				failed = true,
				requiresGamepass = true,
				gamepassKey = gamepassKey,
				gamepassName = gamepassName,
				failReason = string.format("%s This premium option requires the %s gamepass!", emoji, gamepassName),
				eventId = eventDef.id,
				choiceIndex = choiceIndex,
			}
		end
		
		-- Also check requiresFlags on premium choices (e.g., must be in mob for mafia options)
		if choice.requiresFlags then
			for flagName, requiredValue in pairs(choice.requiresFlags) do
				local playerHasFlag = flags[flagName]
				if requiredValue == true and not playerHasFlag then
					return {
						success = false,
						failed = true,
						failReason = "You don't meet the requirements for this option.",
						eventId = eventDef.id,
						choiceIndex = choiceIndex,
					}
				end
			end
		end
	end
	
	-- Initialize outcome
	local outcome = {
		eventId = eventDef.id,
		eventTitle = eventDef.title,
		choiceIndex = choiceIndex,
		choiceText = choice.text,
		feedText = choice.feedText or choice.feed or choice.text,
		statChanges = {},
		flagChanges = {},
		moneyChange = 0,
	}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #473: Handle successChance on choices (for risky actions)
	-- Many events use successChance/successMafiaEffect/failMafiaEffect pattern
	-- NOTE: successChance can be 0-1 OR 0-100 format, detect and handle both!
	-- ═══════════════════════════════════════════════════════════════════════════════
	local wasSuccessful = true
	if choice.successChance ~= nil then
		local roll = RANDOM:NextNumber() * 100 -- Roll 0-100
		-- Normalize successChance to 0-100 scale (some events use 0-1, others use 0-100)
		local normalizedChance = choice.successChance
		if normalizedChance <= 1 then
			normalizedChance = normalizedChance * 100
		end
		wasSuccessful = roll < normalizedChance
		outcome.wasSuccessful = wasSuccessful
		outcome.successRoll = roll
		
		if wasSuccessful then
			-- Use success effects if available
			if choice.successFeed then
				outcome.feedText = choice.successFeed
			elseif choice.successFeedText then
				outcome.feedText = choice.successFeedText
			end
			if choice.successMoney then
				-- CRITICAL FIX #529: Protect money from going negative
				state.Money = math.max(0, (state.Money or 0) + choice.successMoney)
				outcome.moneyChange = choice.successMoney
			end
			if choice.successFame then
				state.Fame = (state.Fame or 0) + choice.successFame
			end
			-- CRITICAL FIX #474: Handle successMafiaEffect
			if choice.successMafiaEffect and state.MobState then
				local mEffect = choice.successMafiaEffect
				if mEffect.respect then
					state.MobState.respect = (state.MobState.respect or 0) + mEffect.respect
				end
				if mEffect.money then
					-- CRITICAL FIX #530: Protect mafia money from going negative
					state.Money = math.max(0, (state.Money or 0) + mEffect.money)
					outcome.moneyChange = (outcome.moneyChange or 0) + mEffect.money
				end
				if mEffect.heat then
					state.MobState.heat = math.min(100, (state.MobState.heat or 0) + mEffect.heat)
				end
				if mEffect.heatDecay then
					state.MobState.heat = math.max(0, (state.MobState.heat or 0) - mEffect.heatDecay)
				end
				if mEffect.kills then
					state.MobState.kills = (state.MobState.kills or 0) + mEffect.kills
				end
				if mEffect.rankUp then
					state.MobState.rankLevel = (state.MobState.rankLevel or 1) + 1
				end
			end
		else
			-- Use fail effects if available
			if choice.failFeed then
				outcome.feedText = choice.failFeed
			elseif choice.failFeedText then
				outcome.feedText = choice.failFeedText
			end
			if choice.failMoney then
				state.Money = math.max(0, (state.Money or 0) + choice.failMoney)
				outcome.moneyChange = choice.failMoney
			end
			if choice.failFame then
				state.Fame = math.max(0, (state.Fame or 0) + choice.failFame)
			end
			-- CRITICAL FIX #475: Handle failMafiaEffect
			if choice.failMafiaEffect and state.MobState then
				local mEffect = choice.failMafiaEffect
				if mEffect.respect then
					state.MobState.respect = math.max(0, (state.MobState.respect or 0) + mEffect.respect)
				end
				if mEffect.heat then
					state.MobState.heat = math.min(100, (state.MobState.heat or 0) + mEffect.heat)
				end
				if mEffect.arrested then
					state.InJail = true
					state.JailYearsLeft = mEffect.jailYears or 5
					state.Flags.in_prison = true
					state.Flags.incarcerated = true
					-- Lose job when arrested
					if state.CurrentJob then
						state.CurrentJob = nil
						state.Flags.employed = nil
						state.Flags.has_job = nil
					end
				end
			end
		end
	end
	
	-- Apply stat effects (only if not handled by success/fail above, or if no successChance)
	local effects = choice.effects or choice.deltas or {}
	for stat, change in pairs(effects) do
		local delta = change
		
		-- Handle random ranges
		if type(change) == "table" then
			local min = change.min or change[1] or 0
			local max = change.max or change[2] or 0
			delta = RANDOM:NextInteger(math.min(min, max), math.max(min, max))
		end
		
		outcome.statChanges[stat] = delta
		
		-- Apply to state
		if stat == "Money" or stat == "money" then
			state.Money = math.max(0, (state.Money or 0) + delta)
			outcome.moneyChange = (outcome.moneyChange or 0) + delta
		else
			state.Stats = state.Stats or {}
			local current = state.Stats[stat] or state[stat] or 50
			local newValue = math.clamp(current + delta, 0, 100)
			state.Stats[stat] = newValue
			state[stat] = newValue
		end
	end
	
	-- Apply flag changes
	local flagChanges = choice.setFlags or choice.flags or {}
	state.Flags = state.Flags or {}
	for flag, value in pairs(flagChanges) do
		state.Flags[flag] = value
		outcome.flagChanges[flag] = value
	end
	
	-- CRITICAL FIX: Handle clearFlags (for events like prison escape that need to remove flags)
	local clearFlagChanges = choice.clearFlags or {}
	for flag, _ in pairs(clearFlagChanges) do
		if state.Flags[flag] then
			state.Flags[flag] = nil
			outcome.flagChanges[flag] = nil -- Mark as cleared
		end
	end
	
	-- Career hints
	if choice.hintCareer then
		state.CareerHints = state.CareerHints or {}
		state.CareerHints[choice.hintCareer] = true
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #476: Handle mafiaEffect on choices (for mafia events)
	-- ═══════════════════════════════════════════════════════════════════════════════
	if choice.mafiaEffect then
		local mEffect = choice.mafiaEffect
		state.MobState = state.MobState or {}
		
		if mEffect.respect then
			state.MobState.respect = (state.MobState.respect or 0) + mEffect.respect
		end
		if mEffect.money then
			-- CRITICAL FIX #531: Protect mafia money effect from going negative
			state.Money = math.max(0, (state.Money or 0) + mEffect.money)
			outcome.moneyChange = (outcome.moneyChange or 0) + mEffect.money
		end
		if mEffect.heat then
			state.MobState.heat = math.min(100, (state.MobState.heat or 0) + mEffect.heat)
		end
		if mEffect.heatDecay then
			state.MobState.heat = math.max(0, (state.MobState.heat or 0) - mEffect.heatDecay)
		end
		if mEffect.kills then
			state.MobState.kills = (state.MobState.kills or 0) + mEffect.kills
		end
		if mEffect.rankUp then
			state.MobState.rankLevel = (state.MobState.rankLevel or 1) + 1
			state.MobState.rankIndex = (state.MobState.rankIndex or 1) + 1
		end
		if mEffect.loyalty then
			state.MobState.loyalty = math.clamp((state.MobState.loyalty or 50) + mEffect.loyalty, 0, 100)
		end
		if mEffect.betrayal then
			state.Flags.mob_betrayer = true
		end
		if mEffect.arrested then
			state.InJail = true
			state.JailYearsLeft = mEffect.jailYears or 5
			state.Flags.in_prison = true
			state.Flags.incarcerated = true
			if state.CurrentJob then
				state.CurrentJob = nil
				state.Flags.employed = nil
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #477: Handle royaltyEffect on choices (for royalty events)
	-- ═══════════════════════════════════════════════════════════════════════════════
	if choice.royaltyEffect then
		local rEffect = choice.royaltyEffect
		state.RoyalState = state.RoyalState or {}
		
		if rEffect.popularity then
			state.RoyalState.popularity = math.clamp((state.RoyalState.popularity or 50) + rEffect.popularity, 0, 100)
		end
		if rEffect.scandals then
			state.RoyalState.scandals = (state.RoyalState.scandals or 0) + rEffect.scandals
		end
		if rEffect.wealthGain then
			state.Money = (state.Money or 0) + rEffect.wealthGain
			outcome.moneyChange = (outcome.moneyChange or 0) + rEffect.wealthGain
		end
		if rEffect.wealthCost then
			state.Money = math.max(0, (state.Money or 0) - rEffect.wealthCost)
			outcome.moneyChange = (outcome.moneyChange or 0) - rEffect.wealthCost
		end
		if rEffect.abdicated then
			state.RoyalState.abdicated = true
			state.Flags.abdicated = true
		end
		if rEffect.exiled then
			state.RoyalState.exiled = true
			state.Flags.exiled = true
		end
		if rEffect.stepDown then
			state.RoyalState.steppedDown = true
			state.Flags.stepped_down = true
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #478: Handle fameEffect on choices (for celebrity events)
	-- ═══════════════════════════════════════════════════════════════════════════════
	if choice.fameEffect then
		local fEffect = choice.fameEffect
		if type(fEffect) == "number" then
			-- Simple fame change
			state.Fame = math.clamp((state.Fame or 0) + fEffect, 0, 100)
		else
			-- Object with fame and followers
			if fEffect.fame then
				state.Fame = math.clamp((state.Fame or 0) + fEffect.fame, 0, 100)
			end
			if fEffect.followers then
				state.FameState = state.FameState or {}
				state.FameState.followers = (state.FameState.followers or 0) + fEffect.followers
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- SPECIAL EVENT HANDLING - Relationship creation, etc.
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	local eventId = eventDef.id
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Universal friend creation handler
	-- Any event that sets has_best_friend, has_work_friend, or made_friend flags
	-- should create an actual friend relationship!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if choice.setFlags then
		local friendFlags = { "has_best_friend", "has_work_friend", "made_friend", "has_close_friend" }
		local shouldCreateFriend = false
		local friendType = "Friend"
		
		for _, flag in ipairs(friendFlags) do
			if choice.setFlags[flag] then
				shouldCreateFriend = true
				if flag == "has_work_friend" then
					friendType = "Work Friend"
				elseif flag == "has_best_friend" then
					friendType = "Best Friend"
				end
				break
			end
		end
		
		if shouldCreateFriend then
			local friend = EventEngine.createRelationship(state, "friend", { role = friendType })
			if friend then
				outcome.newRelationship = friend
				-- Update feed text to include friend's name
				if outcome.feedText then
					outcome.feedText = outcome.feedText .. " " .. friend.name .. " became your " .. friendType:lower() .. "!"
				else
					outcome.feedText = friend.name .. " became your " .. friendType:lower() .. "!"
				end
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Auto-create partner for ANY event that sets has_partner flag
	-- Previously only worked for 2 hardcoded events, leaving all other dating events broken!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if choice.setFlags and choice.setFlags.has_partner then
		if not state.Relationships then
			state.Relationships = {}
		end
		-- Only create a new partner if we don't already have one
		if not state.Relationships.partner then
			local partner = EventEngine.createRelationship(state, "romance")
			if partner then
				outcome.newRelationship = partner
				-- Update feed text to include partner's name
				-- MINOR FIX: Added fallback for partner name
				local partnerName = partner.name or partner.Name or "someone special"
				if outcome.feedText then
					outcome.feedText = outcome.feedText .. " You started dating " .. partnerName .. "!"
				else
					outcome.feedText = "You started dating " .. partnerName .. "!"
				end
			end
		end
		-- Ensure dating flag is set
		state.Flags.dating = true
	end
	
	-- Wedding - update partner role
	-- CRITICAL FIX: Handle BOTH wedding_day event AND any event that sets married = true
	if eventId == "wedding_day" then
		if state.Relationships and state.Relationships.partner then
			state.Relationships.partner.role = "Spouse"
			state.Flags.married = true
			state.Flags.engaged = nil
			state.Flags.dating = nil -- No longer just dating!
			-- CRITICAL FIX: Safe access to partner name with fallback
			local partnerName = state.Relationships.partner.name or state.Relationships.partner.Name or "your partner"
			outcome.feedText = "You married " .. partnerName .. "!"
		end
	end
	
	-- CRITICAL FIX: Universal handler for ANY choice that sets married flag
	-- This ensures wedding_planning (Adult.lua) and similar events update relationship properly
	if choice.setFlags and choice.setFlags.married then
		if state.Relationships and state.Relationships.partner then
			state.Relationships.partner.role = "Spouse"
			state.Flags.engaged = nil -- No longer engaged, now married
			state.Flags.dating = nil -- No longer just dating
			-- CRITICAL FIX: Safe access to partner name with fallback
			local partnerName = state.Relationships.partner.name or state.Relationships.partner.Name or "your partner"
			-- Update feed text to include partner name if not already mentioned
			if outcome.feedText and not outcome.feedText:find("married") then
				outcome.feedText = outcome.feedText .. " You and " .. partnerName .. " are officially married!"
			end
		end
	end
	
	-- CRITICAL FIX: Universal handler for ANY choice that sets engaged flag
	if choice.setFlags and choice.setFlags.engaged then
		if state.Relationships and state.Relationships.partner then
			local partnerGender = state.Relationships.partner.gender or "female"
			state.Relationships.partner.role = (partnerGender == "female") and "Fiancée" or "Fiancé"
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #8: Universal breakup handler
	-- Any event that sets recently_single should FULLY clear all relationship state
	-- This prevents bugs where player is "single" but still has has_partner flag
	-- ═══════════════════════════════════════════════════════════════════════════════
	if choice.setFlags and choice.setFlags.recently_single then
		local partnerName = "your partner"
		if state.Relationships and state.Relationships.partner then
			partnerName = state.Relationships.partner.name or state.Relationships.partner.Name or "your partner"
			
			-- Move to ex-partner storage for potential "ex returns" events later
			state.Relationships.last_ex = state.Relationships.partner
			state.Relationships.last_ex.breakupAge = state.Age
			state.Relationships.partner = nil
		end
		
		-- Clear ALL relationship flags to prevent inconsistent state
		state.Flags.has_partner = nil
		state.Flags.dating = nil
		state.Flags.committed_relationship = nil
		state.Flags.married = nil
		state.Flags.engaged = nil
		state.Flags.lives_with_partner = nil
		state.Flags.office_romance = nil
		state.Flags.long_distance = nil
		
		-- Ensure feedText includes the partner name
		if not outcome.feedText or outcome.feedText == "" then
			outcome.feedText = "You and " .. partnerName .. " broke up."
		end
	end
	
	-- MINOR FIX: Also handle divorce specifically (sets divorced flag)
	if choice.setFlags and choice.setFlags.divorced then
		local partnerName = "your spouse"
		if state.Relationships and state.Relationships.partner then
			partnerName = state.Relationships.partner.name or state.Relationships.partner.Name or "your spouse"
			state.Relationships.ex_spouse = state.Relationships.partner
			state.Relationships.ex_spouse.divorceAge = state.Age
			state.Relationships.partner = nil
		end
		
		-- Clear relationship flags
		state.Flags.has_partner = nil
		state.Flags.married = nil
		state.Flags.engaged = nil
		state.Flags.lives_with_partner = nil
		state.Flags.dating = nil
		state.Flags.committed_relationship = nil
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CUSTOM onResolve HANDLER - Execute event-specific logic (asset creation, etc.)
	-- This is the key glue that connects story events to actual state changes!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if choice.onResolve and type(choice.onResolve) == "function" then
		local success, err = pcall(function()
			-- CRITICAL FIX: Check if this choice has a minigame trigger
			-- If so, the onResolve expects (state, minigameResult) signature
			-- Otherwise, it uses the standard (state, choice, eventDef, outcome) signature
			if choice.triggerMinigame then
				-- Minigame events expect minigameResult as second parameter
				-- The minigameResult should be passed in via outcome.minigameResult
				-- For now, simulate a success/fail based on player stats if not provided
				local minigameResult = outcome.minigameResult
				if not minigameResult then
					-- Fallback: Generate result based on player stats
					local relevantStat = 50
					if choice.triggerMinigame == "qte" then
						relevantStat = (state.Stats and state.Stats.Health) or 50
					elseif choice.triggerMinigame == "hacking" then
						relevantStat = (state.Stats and state.Stats.Smarts) or 50
					elseif choice.triggerMinigame == "heist" then
						relevantStat = (state.Stats and state.Stats.Smarts) or 50
					end
					-- Success chance based on stat and difficulty
					local difficulty = choice.minigameOptions and choice.minigameOptions.difficulty or "medium"
					local difficultyMod = { easy = 0.2, medium = 0, hard = -0.2 }
					local successChance = 0.5 + (relevantStat / 200) + (difficultyMod[difficulty] or 0)
					minigameResult = {
						success = RANDOM:NextNumber() < successChance,
						score = relevantStat,
					}
				end
				choice.onResolve(state, minigameResult)
			else
				-- Standard signature for non-minigame events
				choice.onResolve(state, choice, eventDef, outcome)
			end
		end)
		if not success then
			warn("[EventEngine] onResolve handler error for event '" .. (eventDef.id or "unknown") .. "':", err)
		end
	end
	
	-- Also support event-level onComplete handler (runs after any choice)
	if eventDef.onComplete and type(eventDef.onComplete) == "function" then
		local success, err = pcall(function()
			eventDef.onComplete(state, choice, eventDef, outcome)
		end)
		if not success then
			warn("[EventEngine] onComplete handler error for event '" .. (eventDef.id or "unknown") .. "':", err)
		end
	end
	
	return outcome
end

-- Expose the engine
LifeEvents.EventEngine = EventEngine

-- ════════════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #452-455: ENHANCED EVENT WEIGHT CALCULATION
-- Additional weight modifiers for better event balance
-- ════════════════════════════════════════════════════════════════════════════════════

LifeEvents.WeightModifiers = {
	-- Base weights for different event categories
	categoryWeights = {
		milestones = 3.0,  -- High priority
		career = 2.0,
		relationships = 1.8,
		health = 1.5,
		financial = 1.5,
		random = 1.0,
		crime = 0.8,  -- Slightly less common
		mafia = 1.5,  -- Good for mob members
		royalty = 1.5,  -- Good for royals
		celebrity = 1.5,  -- Good for famous
	},
	
	-- Boost events based on player flags
	flagBoosts = {
		employed = { "career", "financial" },
		married = { "relationships" },
		has_children = { "relationships" },
		wealthy = { "financial", "assets" },
		famous = { "celebrity" },
		in_mob = { "mafia", "crime" },
		is_royalty = { "royalty" },
	},
}

function LifeEvents.getWeightModifier(event, state)
	local modifier = 1.0
	local flags = state.Flags or {}
	
	-- Category weight
	local category = event._category or "random"
	modifier = modifier * (LifeEvents.WeightModifiers.categoryWeights[category] or 1.0)
	
	-- Flag-based boosts
	for flag, categories in pairs(LifeEvents.WeightModifiers.flagBoosts) do
		if flags[flag] then
			for _, cat in ipairs(categories) do
				if category == cat then
					modifier = modifier * 1.5
				end
			end
		end
	end
	
	-- Event-specific modifiers
	if event.weightMultiplier then
		modifier = modifier * event.weightMultiplier
	end
	
	return modifier
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #456-458: LIFE STAGE TRANSITION HELPERS
-- Detect and trigger life stage changes
-- ════════════════════════════════════════════════════════════════════════════════════

LifeEvents.LifeStageTransitions = {
	{ fromAge = 2, toAge = 3, fromStage = "baby", toStage = "toddler", event = "stage_toddler" },
	{ fromAge = 4, toAge = 5, fromStage = "toddler", toStage = "child", event = "stage_childhood" },
	{ fromAge = 12, toAge = 13, fromStage = "child", toStage = "teen", event = "stage_teen" },
	{ fromAge = 17, toAge = 18, fromStage = "teen", toStage = "young_adult", event = "stage_adult" },
	{ fromAge = 29, toAge = 30, fromStage = "young_adult", toStage = "adult", event = "stage_thirties" },
	{ fromAge = 49, toAge = 50, fromStage = "adult", toStage = "middle_age", event = "stage_midlife" },
	{ fromAge = 64, toAge = 65, fromStage = "middle_age", toStage = "senior", event = "stage_retirement" },
}

function LifeEvents.checkLifeStageTransition(state, oldAge, newAge)
	for _, transition in ipairs(LifeEvents.LifeStageTransitions) do
		if oldAge <= transition.fromAge and newAge >= transition.toAge then
			return {
				transitioned = true,
				fromStage = transition.fromStage,
				toStage = transition.toStage,
				eventId = transition.event,
			}
		end
	end
	return { transitioned = false }
end

function LifeEvents.getLifeStageEvents(stage)
	local events = {}
	
	-- Get categories for this stage
	local categories = StageCategories[stage]
	if not categories then
		return events
	end
	
	-- Collect events from those categories
	for _, category in ipairs(categories) do
		local categoryEvents = EventsByCategory[category] or {}
		for _, event in ipairs(categoryEvents) do
			table.insert(events, event)
		end
	end
	
	return events
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #459-461: CAREER SKILL REQUIREMENTS SYSTEM
-- Check if player has required skills for jobs
-- ════════════════════════════════════════════════════════════════════════════════════

LifeEvents.CareerSkillRequirements = {
	-- Tech careers
	software_engineer = { Smarts = 70, skills = { "programming" } },
	data_scientist = { Smarts = 75, skills = { "programming", "math" } },
	it_manager = { Smarts = 65, skills = { "programming", "leadership" } },
	
	-- Medical careers
	doctor = { Smarts = 85, education = "medical" },
	nurse = { Smarts = 60, education = "bachelor" },
	surgeon = { Smarts = 90, education = "medical", skills = { "surgery" } },
	
	-- Finance careers
	investment_banker = { Smarts = 75, education = "bachelor", skills = { "finance" } },
	accountant = { Smarts = 65, education = "bachelor" },
	cfo = { Smarts = 80, education = "master", skills = { "finance", "leadership" } },
	
	-- Legal careers
	lawyer = { Smarts = 75, education = "law" },
	judge = { Smarts = 80, education = "law", yearsExperience = 10 },
	
	-- Entertainment careers
	actor = { Looks = 60 },
	model = { Looks = 75 },
	musician = { skills = { "music" } },
	
	-- Leadership
	ceo = { Smarts = 70, skills = { "leadership" }, yearsExperience = 8 },
	politician = { Smarts = 60, Looks = 50, skills = { "public_speaking" } },
}

function LifeEvents.checkCareerRequirements(state, careerId)
	local requirements = LifeEvents.CareerSkillRequirements[careerId]
	if not requirements then
		return true, nil -- No requirements
	end
	
	local missing = {}
	
	-- Check stats
	for stat, minValue in pairs({ Smarts = requirements.Smarts, Looks = requirements.Looks }) do
		if minValue then
			local playerValue = (state.Stats and state.Stats[stat]) or state[stat] or 0
			if playerValue < minValue then
				table.insert(missing, string.format("%s %d+ (have %d)", stat, minValue, playerValue))
			end
		end
	end
	
	-- Check education
	if requirements.education then
		local playerEd = state.Education or "none"
		local edLevels = { none = 0, high_school = 1, associate = 2, bachelor = 3, master = 4, law = 5, medical = 6, phd = 7 }
		
		if (edLevels[playerEd] or 0) < (edLevels[requirements.education] or 0) then
			table.insert(missing, string.format("%s degree required", requirements.education))
		end
	end
	
	-- Check skills
	if requirements.skills then
		local playerSkills = (state.CareerInfo and state.CareerInfo.skills) or {}
		for _, skill in ipairs(requirements.skills) do
			if not playerSkills[skill] then
				table.insert(missing, string.format("%s skill required", skill))
			end
		end
	end
	
	-- Check experience
	if requirements.yearsExperience then
		local yearsAtJob = (state.CareerInfo and state.CareerInfo.yearsAtJob) or 0
		if yearsAtJob < requirements.yearsExperience then
			table.insert(missing, string.format("%d years experience required", requirements.yearsExperience))
		end
	end
	
	if #missing > 0 then
		return false, missing
	end
	
	return true, nil
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #462-464: RELATIONSHIP EVENT REQUIREMENTS
-- Check relationship requirements for events
-- ════════════════════════════════════════════════════════════════════════════════════

function LifeEvents.checkRelationshipRequirements(event, state)
	local requirements = event.relationshipRequirements or event.requiresRelationship
	if not requirements then
		return true
	end
	
	local relationships = state.Relationships or {}
	
	-- Check for specific relationship type
	if type(requirements) == "string" then
		-- Simple requirement like "partner" or "parent"
		if relationships[requirements:lower()] then
			return true
		end
		
		-- Check for partner
		if requirements == "partner" then
			for _, rel in pairs(relationships) do
				if type(rel) == "table" and (rel.type == "romantic" or rel.role == "Partner") then
					if rel.alive ~= false then
						return true
					end
				end
			end
		end
		
		return false
	end
	
	-- Complex requirements
	if type(requirements) == "table" then
		-- Requires any relationship
		if requirements.hasAny then
			for _, rel in pairs(relationships) do
				if type(rel) == "table" and rel.alive ~= false then
					return true
				end
			end
			return false
		end
		
		-- Requires specific type
		if requirements.type then
			for _, rel in pairs(relationships) do
				if type(rel) == "table" and rel.type == requirements.type then
					if rel.alive ~= false then
						-- Check relationship strength if required
						if requirements.minStrength then
							if (rel.relationship or 0) >= requirements.minStrength then
								return true
							end
						else
							return true
						end
					end
				end
			end
			return false
		end
		
		-- Requires minimum count
		if requirements.minCount then
			local count = 0
			for _, rel in pairs(relationships) do
				if type(rel) == "table" and rel.alive ~= false then
					count = count + 1
				end
			end
			return count >= requirements.minCount
		end
	end
	
	return true
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #465: COMPREHENSIVE YEARLY PROGRESSION CHECK
-- Called to process all yearly updates for premium features
-- ════════════════════════════════════════════════════════════════════════════════════

function LifeEvents.processYearlyProgression(state)
	local results = {
		events = {},
		messages = {},
	}
	
	-- Check for life stage transition
	local prevAge = (state.Age or 1) - 1
	local transition = LifeEvents.checkLifeStageTransition(state, prevAge, state.Age)
	if transition.transitioned then
		table.insert(results.messages, string.format("Life Stage: %s → %s", 
			transition.fromStage:gsub("_", " "):gsub("^%l", string.upper),
			transition.toStage:gsub("_", " "):gsub("^%l", string.upper)))
	end
	
	-- Fame career progression
	if state.FameState and state.FameState.careerPath then
		state.FameState.yearsInCareer = (state.FameState.yearsInCareer or 0) + 1
	end
	
	-- Royal reign progression
	if state.RoyalState and state.RoyalState.isMonarch then
		state.RoyalState.reignYears = (state.RoyalState.reignYears or 0) + 1
	end
	
	-- Mafia years progression
	if state.MobState and state.MobState.inMob then
		state.MobState.yearsInMob = (state.MobState.yearsInMob or 0) + 1
	end
	
	-- Career years progression
	if state.CurrentJob then
		state.CareerInfo = state.CareerInfo or {}
		state.CareerInfo.yearsAtJob = (state.CareerInfo.yearsAtJob or 0) + 1
	end
	
	return results
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- AUTO-INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════════════

LifeEvents.init()

return LifeEvents
