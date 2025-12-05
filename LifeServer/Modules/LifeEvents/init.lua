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
local StageCategories = {
	baby        = { "childhood", "milestones" },
	toddler     = { "childhood", "milestones" },
	child       = { "childhood", "milestones", "random" },
	teen        = { "teen", "milestones", "relationships", "random", "crime" },
	young_adult = { "adult", "milestones", "relationships", "random", "crime" },
	adult       = { "adult", "milestones", "relationships", "random", "crime" },
	middle_age  = { "adult", "milestones", "relationships", "random", "crime" },
	senior      = { "adult", "milestones", "relationships", "random" },
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
	
	-- Support multiple export formats
	local events = moduleData.events or moduleData.Events or moduleData
	if type(events) ~= "table" then
		warn("[LifeEvents] ⚠️ Invalid events format in:", moduleName)
		return 0
	end
	
	-- Ensure it's an array of events
	if events[1] == nil and next(events) ~= nil then
		-- It's a dictionary, not an array - skip
		warn("[LifeEvents] ⚠️ Events should be an array in:", moduleName)
		return 0
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
		{ name = "Career",        category = "career" },
		{ name = "Relationships", category = "relationships" },
		{ name = "Milestones",    category = "milestones" },
		{ name = "Random",        category = "random" },
		
		-- Catalog modules (organized event collections)
		{ name = "CareerEvents",   category = "career" },
		{ name = "RomanceEvents",  category = "relationships" },
		{ name = "CrimeEvents",    category = "crime" },
		{ name = "CoreMilestones", category = "milestones" },
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
		local category = event._category or "general"
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
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- CONTEXTUAL ELIGIBILITY SYSTEM
-- This is the CORE logic that prevents random/inappropriate events
-- ════════════════════════════════════════════════════════════════════════════════════

local function canEventTrigger(event, state)
	local age = state.Age or 0
	local history = getEventHistory(state)
	local flags = state.Flags or {}
	
	-- Flatten conditions if present (some events use conditions.minAge instead of minAge)
	local cond = event.conditions or {}
	local minAge = event.minAge or cond.minAge
	local maxAge = event.maxAge or cond.maxAge
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- BASIC CHECKS
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Age range check (check both event.minAge/maxAge and conditions.minAge/maxAge)
	if minAge and age < minAge then return false end
	if maxAge and age > maxAge then return false end
	
	-- One-time event already completed
	if event.oneTime and history.completed[event.id] then
		return false
	end
	
	-- Cooldown check (years since last occurrence)
	local cooldown = event.cooldown or 3
	local lastAge = history.lastOccurrence[event.id]
	if lastAge and (age - lastAge) < cooldown then
		return false
	end
	
	-- Max occurrences limit
	local maxOccur = event.maxOccurrences or 10
	local occurCount = history.occurrences[event.id] or 0
	if occurCount >= maxOccur then
		return false
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
	
	if event.blockedByFlags then
		for flag, _ in pairs(event.blockedByFlags) do
			if flags[flag] then
				return false -- Has blocking flag
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
	if event.requiresNoJob and (state.CurrentJob or flags.employed) then
		return false
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
	-- JOB/CAREER REQUIREMENTS - No career events if unemployed!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if event.requiresJob then
		if not state.CurrentJob then
			return false -- MUST have a job
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
		local jobCat = state.CurrentJob.category or state.CurrentJob.Category or ""
		if jobCat:lower() ~= event.requiresJobCategory:lower() then
			return false -- Wrong job category
		end
	end
	
	-- Deterministic career gating: performance and tenure
	if event.requiresCareer then
		local req = event.requiresCareer
		if not state.CurrentJob then
			return false
		end
		local perf = (state.CareerInfo and state.CareerInfo.performance) or 0
		local years = (state.CareerInfo and state.CareerInfo.yearsAtJob) or 0
		if req.minPerformance and perf < req.minPerformance then
			return false
		end
		if req.maxPerformance and perf > req.maxPerformance then
			return false
		end
		if req.minYearsAtJob and years < req.minYearsAtJob then
			return false
		end
		if req.maxYearsAtJob and years > req.maxYearsAtJob then
			return false
		end
		if req.category then
			local jobCat = state.CurrentJob.category or ""
			if jobCat:lower() ~= tostring(req.category):lower() then
				return false
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- RELATIONSHIP REQUIREMENTS - No marriage events if single!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if event.requiresPartner then
		local hasPartner = state.Relationships and state.Relationships.partner
		if not hasPartner then
			return false -- MUST have a partner
		end
	end
	
	if event.requiresSingle or event.requiresNoPartner then
		local hasPartner = state.Relationships and state.Relationships.partner
		if hasPartner then
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

local function calculateEventWeight(event, state)
	local history = getEventHistory(state)
	local baseWeight = event.weight or 10
	local weight = baseWeight
	
	-- Career realism: scale career event weight by performance and progress
	if event._category == "career" and state.CurrentJob then
		local perf = (state.CareerInfo and state.CareerInfo.performance) or 50
		local prog = (state.CareerInfo and state.CareerInfo.promotionProgress) or 0
		-- Normalize factors: performance 0..100 -> 0.5..1.5, progress 0..100 -> 0.5..1.5
		local perfFactor = 0.5 + (perf / 100)
		local progFactor = 0.5 + (prog / 100)
		weight = weight * perfFactor * progFactor
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
		local yearsSince = (state.Age or 0) - lastAge
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
	end
	
	-- Collect all eligible events
	local candidateEvents = {}
	local priorityEvents = {}
	
	for _, categoryName in ipairs(categories) do
		local categoryEvents = EventsByCategory[categoryName] or {}
		for _, event in ipairs(categoryEvents) do
			if canEventTrigger(event, state) then
				local weight = calculateEventWeight(event, state)
				local candidate = {
					event = event,
					weight = weight,
					isPriority = event.priority == "high" or event.isMilestone,
				}
				
				if candidate.isPriority then
					table.insert(priorityEvents, candidate)
				else
					table.insert(candidateEvents, candidate)
				end
			end
		end
	end
	
	-- Priority events (milestones) always trigger first
	if #priorityEvents > 0 then
		table.sort(priorityEvents, function(a, b) return a.weight > b.weight end)
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

-- Utility: fetch an event definition by id (for backend chaining)
function LifeEvents.getEventById(eventId)
	return AllEvents[eventId]
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

-- Name pools for dynamic relationship creation
local NamePools = {
	male = {
		"James", "Michael", "David", "John", "Robert", "Christopher", "Daniel",
		"Matthew", "Anthony", "Mark", "Steven", "Andrew", "Joshua", "Kevin",
		"Brian", "Ryan", "Justin", "Brandon", "Eric", "Tyler", "Alexander",
		"Jake", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Oliver", "Aiden",
		"Carter", "Sebastian", "Henry", "Owen", "Jack", "Leo", "Nathan"
	},
	female = {
		"Emma", "Olivia", "Sophia", "Isabella", "Mia", "Charlotte", "Amelia",
		"Harper", "Evelyn", "Abigail", "Emily", "Elizabeth", "Sofia", "Avery",
		"Ella", "Scarlett", "Grace", "Chloe", "Victoria", "Riley", "Aria",
		"Lily", "Zoey", "Hannah", "Layla", "Nora", "Zoe", "Leah", "Hazel",
		"Luna", "Penelope", "Stella", "Aurora", "Violet", "Savannah", "Audrey"
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
	local id = relType .. "_" .. tostring(RANDOM:NextInteger(1000, 9999)) .. "_" .. tostring(tick())
	
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
	
	state.Relationships[id] = relationship
	
	-- Set as partner if it's a romance
	if relType == "romance" or relType == "partner" then
		state.Relationships.partner = relationship
		state.Flags = state.Flags or {}
		state.Flags.has_partner = true
	end
	
	return relationship
end

function EventEngine.completeEvent(eventDef, choiceIndex, state)
	if not eventDef or not eventDef.choices then
		warn("[EventEngine] Invalid event definition")
		return nil
	end
	
	local choice = eventDef.choices[choiceIndex]
	if not choice then
		warn("[EventEngine] Invalid choice index:", choiceIndex)
		return nil
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
	
	-- Apply stat effects
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
			outcome.moneyChange = delta
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
	
	-- Career hints
	if choice.hintCareer then
		state.CareerHints = state.CareerHints or {}
		state.CareerHints[choice.hintCareer] = true
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- SPECIAL EVENT HANDLING - Relationship creation, etc.
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	local eventId = eventDef.id
	
	-- Friend-making events
	if eventId == "first_best_friend" or eventId == "new_friendship" then
		if choice.setFlags and choice.setFlags.has_best_friend then
			local friend = EventEngine.createRelationship(state, "friend")
			outcome.feedText = outcome.feedText .. " " .. friend.name .. " became your friend!"
			outcome.newRelationship = friend
		end
	end
	
	-- Romance events - create partner
	if (eventId == "dating_app" or eventId == "high_school_romance") and choiceIndex == 1 then
		if not state.Relationships or not state.Relationships.partner then
			local partner = EventEngine.createRelationship(state, "romance")
			outcome.feedText = "You started dating " .. partner.name .. "!"
			outcome.newRelationship = partner
			state.Flags.dating = true
		end
	end
	
	-- Wedding - update partner role
	if eventId == "wedding_day" then
		if state.Relationships and state.Relationships.partner then
			state.Relationships.partner.role = "Spouse"
			state.Flags.married = true
			state.Flags.engaged = nil
			outcome.feedText = "You married " .. state.Relationships.partner.name .. "!"
		end
	end
	
	-- Breakup events
	if choice.setFlags and choice.setFlags.recently_single then
		if state.Relationships and state.Relationships.partner then
			local partnerName = state.Relationships.partner.name
			state.Relationships.partner = nil
			state.Flags.has_partner = nil
			state.Flags.dating = nil
			state.Flags.committed_relationship = nil
			outcome.feedText = "You and " .. partnerName .. " broke up."
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CUSTOM onResolve HANDLER - Execute event-specific logic (asset creation, etc.)
	-- This is the key glue that connects story events to actual state changes!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if choice.onResolve and type(choice.onResolve) == "function" then
		local success, err = pcall(function()
			choice.onResolve(state, choice, eventDef, outcome)
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
	
	-- Optional injury support at the choice level for AAA specificity
	if choice.injury and type(choice.injury) == "table" then
		if state.ApplyInjury then
			local success, injuryOrErr = pcall(function()
				return state:ApplyInjury(choice.injury)
			end)
			if success and injuryOrErr then
				local inj = injuryOrErr
				local injText = string.format(" Injury: %s %s (%s).", tostring(inj.severity or "minor"), tostring(inj.location or "arm"), tostring(inj.cause or "accident"))
				outcome.feedText = (outcome.feedText or (choice.text or eventDef.title or "Event")) .. injText
			else
				warn("[EventEngine] Failed to apply injury for event '" .. (eventDef.id or "unknown") .. "':", injuryOrErr)
			end
		end
	end
	
	-- Story chaining hint (non-breaking): surface nextEventId in outcome for the backend to enqueue
	if choice.nextEventId or eventDef.nextEventId then
		outcome.nextEventId = choice.nextEventId or eventDef.nextEventId
	end
	
	-- Debug summary for event resolution
	if outcome and outcome.eventId then
		print(string.format("[EventEngine] Resolved '%s' choice #%d -> money %+d, flags %+d, stats %+d%s",
			outcome.eventId,
			outcome.choiceIndex or -1,
			outcome.moneyChange or 0,
			(outcome.flagChanges and (function(t) local c=0 for _ in pairs(t) do c+=1 end return c end)(outcome.flagChanges)) or 0,
			(outcome.statChanges and (function(t) local c=0 for _ in pairs(t) do c+=1 end return c end)(outcome.statChanges)) or 0,
			outcome.nextEventId and (" next=" .. outcome.nextEventId) or ""
		))
	end
	return outcome
end

-- Expose the engine
LifeEvents.EventEngine = EventEngine

-- ════════════════════════════════════════════════════════════════════════════════════
-- AUTO-INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════════════

LifeEvents.init()

return LifeEvents
