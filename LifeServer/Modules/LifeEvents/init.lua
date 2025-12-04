--[[
	LifeEvents/init.lua
	
	Event system that integrates with LifeBackend.
	Provides smart event selection with cooldowns, variety, and story tracking.
	
	Usage:
		local LifeEvents = require(LifeEventsFolder:WaitForChild("init"))
		local events = LifeEvents.buildYearQueue(playerState, { maxEvents = 2 })
		LifeEvents.EventEngine.completeEvent(eventDef, choiceIndex, state)
]]

local LifeEvents = {}

-- Load event pool modules
local ChildhoodPool = require(script:WaitForChild("Childhood"))
local TeenPool = require(script:WaitForChild("Teen"))
local AdultPool = require(script:WaitForChild("Adult"))
local CareerPool = require(script:WaitForChild("Career"))
local RelationshipPool = require(script:WaitForChild("Relationships"))
local MilestonePool = require(script:WaitForChild("Milestones"))
local RandomPool = require(script:WaitForChild("Random"))

-- Master event registry (id -> event)
local AllEvents = {}
local EventsByCategory = {}

local RANDOM = Random.new()

-- ════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

local function registerEvents(pool, categoryName)
	if not pool or not pool.events then return 0 end
	
	EventsByCategory[categoryName] = EventsByCategory[categoryName] or {}
	local count = 0
	
	for _, event in ipairs(pool.events) do
		event._category = categoryName
		AllEvents[event.id] = event
		table.insert(EventsByCategory[categoryName], event)
		count += 1
	end
	
	return count
end

function LifeEvents.init()
	AllEvents = {}
	EventsByCategory = {}
	
	local total = 0
	total += registerEvents(ChildhoodPool, "childhood")
	total += registerEvents(TeenPool, "teen")
	total += registerEvents(AdultPool, "adult")
	total += registerEvents(CareerPool, "career")
	total += registerEvents(RelationshipPool, "relationships")
	total += registerEvents(MilestonePool, "milestones")
	total += registerEvents(RandomPool, "random")
	
	print(string.format("[LifeEvents] Loaded %d events across %d categories.", total, #EventsByCategory))
	return total
end

-- Auto-init on require
LifeEvents.init()

-- ════════════════════════════════════════════════════════════════════════════
-- LIFE STAGE HELPERS
-- ════════════════════════════════════════════════════════════════════════════

local LifeStages = {
	{ id = "baby",       minAge = 0,  maxAge = 2 },
	{ id = "toddler",    minAge = 3,  maxAge = 4 },
	{ id = "child",      minAge = 5,  maxAge = 12 },
	{ id = "teen",       minAge = 13, maxAge = 17 },
	{ id = "young_adult", minAge = 18, maxAge = 29 },
	{ id = "adult",      minAge = 30, maxAge = 49 },
	{ id = "middle_age", minAge = 50, maxAge = 64 },
	{ id = "senior",     minAge = 65, maxAge = 999 },
}

local function getLifeStage(age)
	for _, stage in ipairs(LifeStages) do
		if age >= stage.minAge and age <= stage.maxAge then
			return stage.id
		end
	end
	return "adult"
end

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT HISTORY TRACKING
-- ════════════════════════════════════════════════════════════════════════════

local function getEventHistory(state)
	state.EventHistory = state.EventHistory or {
		occurrences = {},     -- eventId -> count
		lastOccurrence = {},  -- eventId -> age when last occurred
		completed = {},       -- eventId -> true (for one-time events)
		recentCategories = {}, -- last N categories shown
	}
	return state.EventHistory
end

local function recordEventShown(state, event)
	local history = getEventHistory(state)
	local eventId = event.id
	
	history.occurrences[eventId] = (history.occurrences[eventId] or 0) + 1
	history.lastOccurrence[eventId] = state.Age
	
	if event.oneTime then
		history.completed[eventId] = true
	end
	
	-- Track recent categories for variety
	table.insert(history.recentCategories, event._category or "general")
	if #history.recentCategories > 5 then
		table.remove(history.recentCategories, 1)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT ELIGIBILITY CHECKS
-- ════════════════════════════════════════════════════════════════════════════

local function canEventTrigger(event, state)
	local age = state.Age or 0
	local history = getEventHistory(state)
	
	-- Age check
	if event.minAge and age < event.minAge then return false end
	if event.maxAge and age > event.maxAge then return false end
	
	-- Life stage check
	if event.lifeStage then
		local currentStage = getLifeStage(age)
		if type(event.lifeStage) == "table" then
			local found = false
			for _, stage in ipairs(event.lifeStage) do
				if stage == currentStage then found = true; break end
			end
			if not found then return false end
		elseif event.lifeStage ~= currentStage then
			return false
		end
	end
	
	-- One-time event already completed
	if event.oneTime and history.completed[event.id] then
		return false
	end
	
	-- Cooldown check (default 3 years between same event)
	local cooldown = event.cooldown or 3
	local lastAge = history.lastOccurrence[event.id]
	if lastAge and (age - lastAge) < cooldown then
		return false
	end
	
	-- Max occurrences check
	local maxOccur = event.maxOccurrences or 5
	local count = history.occurrences[event.id] or 0
	if count >= maxOccur then
		return false
	end
	
	-- Prerequisite events
	if event.requiresEvents then
		for _, reqId in ipairs(event.requiresEvents) do
			if not history.completed[reqId] and not history.occurrences[reqId] then
				return false
			end
		end
	end
	
	-- Blocked by events
	if event.blockedByEvents then
		for _, blockId in ipairs(event.blockedByEvents) do
			if history.completed[blockId] then
				return false
			end
		end
	end
	
	-- Flag requirements
	if event.requiresFlags then
		local flags = state.Flags or {}
		for flag, required in pairs(event.requiresFlags) do
			if required == true and not flags[flag] then return false end
			if required == false and flags[flag] then return false end
		end
	end
	
	-- Stat requirements
	if event.requiresStats then
		local stats = state.Stats or state
		for stat, req in pairs(event.requiresStats) do
			local value = stats[stat] or state[stat] or 50
			if type(req) == "number" and value < req then return false end
			if type(req) == "table" then
				if req.min and value < req.min then return false end
				if req.max and value > req.max then return false end
			end
		end
	end
	
	-- Education requirements
	if event.requiresEducation then
		local eduRanks = { none=0, high_school=1, community=2, bachelor=3, master=4, law=5, medical=5, phd=6 }
		local playerEdu = eduRanks[state.Education or "none"] or 0
		local reqEdu = eduRanks[event.requiresEducation] or 0
		if playerEdu < reqEdu then return false end
	end
	
	-- Career requirements
	if event.requiresJob then
		local currentJob = state.CurrentJob
		if not currentJob then return false end
		local jobId = currentJob.id or currentJob
		if type(event.requiresJob) == "string" and jobId ~= event.requiresJob then
			return false
		end
	end
	
	if event.requiresJobCategory then
		local currentJob = state.CurrentJob
		if not currentJob then return false end
		local category = currentJob.category
		if category ~= event.requiresJobCategory then return false end
	end
	
	-- In jail check
	if event.requiresNotInJail and state.InJail then
		return false
	end
	
	-- Random chance (for variety)
	if event.baseChance then
		if RANDOM:NextNumber() > (event.baseChance or 1) then
			return false
		end
	end
	
	return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT WEIGHT CALCULATION
-- ════════════════════════════════════════════════════════════════════════════

local function getEventWeight(event, state)
	local history = getEventHistory(state)
	local weight = event.weight or 10
	
	-- Boost weight for never-seen events
	local occurCount = history.occurrences[event.id] or 0
	if occurCount == 0 then
		weight = weight * 2.5
	end
	
	-- Priority events get big boost
	if event.priority == "high" or event.isMilestone then
		weight = weight * 3
	end
	
	-- Reduce weight if category was shown recently
	local recentCats = history.recentCategories or {}
	for _, cat in ipairs(recentCats) do
		if cat == event._category then
			weight = weight * 0.5
			break
		end
	end
	
	-- Reduce weight for recently occurred events
	local lastAge = history.lastOccurrence[event.id]
	if lastAge then
		local yearsSince = (state.Age or 0) - lastAge
		if yearsSince < 5 then
			weight = weight * (0.3 + (yearsSince / 10))
		end
	end
	
	-- Boost career-relevant events
	if event.requiresJobCategory and state.CurrentJob then
		local jobCat = state.CurrentJob.category
		if jobCat == event.requiresJobCategory then
			weight = weight * 1.5
		end
	end
	
	return math.max(weight, 1)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CATEGORY SELECTION BY AGE
-- ════════════════════════════════════════════════════════════════════════════

local function getRelevantCategories(state)
	local age = state.Age or 0
	local categories = {}
	
	-- Age-based categories
	if age <= 4 then
		table.insert(categories, "childhood")
		table.insert(categories, "milestones")
	elseif age <= 12 then
		table.insert(categories, "childhood")
		table.insert(categories, "milestones")
		table.insert(categories, "random")
	elseif age <= 17 then
		table.insert(categories, "teen")
		table.insert(categories, "milestones")
		table.insert(categories, "relationships")
		table.insert(categories, "random")
	else
		table.insert(categories, "adult")
		table.insert(categories, "milestones")
		table.insert(categories, "relationships")
		table.insert(categories, "random")
		
		-- Career events if employed
		if state.CurrentJob then
			table.insert(categories, "career")
		end
	end
	
	return categories
end

-- ════════════════════════════════════════════════════════════════════════════
-- BUILD YEAR QUEUE - Main entry point for LifeBackend
-- ════════════════════════════════════════════════════════════════════════════

function LifeEvents.buildYearQueue(state, options)
	options = options or {}
	local maxEvents = options.maxEvents or 2
	
	if not state then return {} end
	
	local age = state.Age or 0
	local selectedEvents = {}
	local candidateEvents = {}
	
	-- Get relevant categories
	local categories = getRelevantCategories(state)
	
	-- Collect eligible events from relevant categories
	for _, catName in ipairs(categories) do
		local catEvents = EventsByCategory[catName] or {}
		for _, event in ipairs(catEvents) do
			if canEventTrigger(event, state) then
				local weight = getEventWeight(event, state)
				table.insert(candidateEvents, {
					event = event,
					weight = weight,
					priority = event.priority == "high" or event.isMilestone,
				})
			end
		end
	end
	
	-- No events available
	if #candidateEvents == 0 then
		return {}
	end
	
	-- Separate priority and regular events
	local priorityEvents = {}
	local regularEvents = {}
	
	for _, candidate in ipairs(candidateEvents) do
		if candidate.priority then
			table.insert(priorityEvents, candidate)
		else
			table.insert(regularEvents, candidate)
		end
	end
	
	-- Add priority events first (milestones, stage transitions)
	for _, candidate in ipairs(priorityEvents) do
		if #selectedEvents < maxEvents then
			table.insert(selectedEvents, candidate.event)
			recordEventShown(state, candidate.event)
		end
	end
	
	-- Weighted random selection for remaining slots
	if #selectedEvents < maxEvents and #regularEvents > 0 then
		local totalWeight = 0
		for _, candidate in ipairs(regularEvents) do
			totalWeight = totalWeight + candidate.weight
		end
		
		local attempts = 0
		local usedCategories = {}
		
		while #selectedEvents < maxEvents and #regularEvents > 0 and attempts < 50 do
			attempts += 1
			local roll = RANDOM:NextNumber() * totalWeight
			local cumulative = 0
			
			for i, candidate in ipairs(regularEvents) do
				cumulative = cumulative + candidate.weight
				if roll <= cumulative then
					local cat = candidate.event._category
					
					-- Skip if we already have an event from this category
					if usedCategories[cat] then
						break
					end
					
					-- Check not already selected
					local alreadySelected = false
					for _, selected in ipairs(selectedEvents) do
						if selected.id == candidate.event.id then
							alreadySelected = true
							break
						end
					end
					
					if not alreadySelected then
						table.insert(selectedEvents, candidate.event)
						recordEventShown(state, candidate.event)
						usedCategories[cat] = true
						
						-- Remove from pool
						totalWeight = totalWeight - candidate.weight
						table.remove(regularEvents, i)
					end
					break
				end
			end
		end
	end
	
	return selectedEvents
end

-- ════════════════════════════════════════════════════════════════════════════
-- GET SPECIFIC EVENT
-- ════════════════════════════════════════════════════════════════════════════

function LifeEvents.getEvent(eventId)
	return AllEvents[eventId]
end

function LifeEvents.getEventsByCategory(categoryName)
	return EventsByCategory[categoryName] or {}
end

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT ENGINE - Handles choice resolution
-- ════════════════════════════════════════════════════════════════════════════

local EventEngine = {}

function EventEngine.completeEvent(eventDef, choiceIndex, state)
	if not eventDef or not eventDef.choices then
		return nil
	end
	
	local choice = eventDef.choices[choiceIndex]
	if not choice then
		return nil
	end
	
	local outcome = {
		eventId = eventDef.id,
		choiceIndex = choiceIndex,
		feedText = choice.feed or choice.feedText or choice.text,
		statChanges = {},
		flagChanges = {},
	}
	
	-- Apply stat effects (supports both 'effects' and 'deltas' keys)
	local effects = choice.effects or choice.deltas or {}
	for stat, change in pairs(effects) do
		local delta = change
		if type(change) == "table" then
			-- Random range { min, max } or { 1, 2 }
			local min = change.min or change[1] or 0
			local max = change.max or change[2] or 0
			delta = RANDOM:NextInteger(min, max)
		end
		
		outcome.statChanges[stat] = delta
		
		-- Apply to state
		if stat == "Money" or stat == "money" then
			state.Money = math.max(0, (state.Money or 0) + delta)
		elseif stat == "Happiness" or stat == "Health" or stat == "Smarts" or stat == "Looks" then
			local stats = state.Stats or state
			local current = stats[stat] or 50
			stats[stat] = math.clamp(current + delta, 0, 100)
			state[stat] = stats[stat]
		end
	end
	
	-- Apply flag changes
	local flagChanges = choice.setFlags or choice.flags or {}
	for flag, value in pairs(flagChanges) do
		state.Flags = state.Flags or {}
		state.Flags[flag] = value
		outcome.flagChanges[flag] = value
	end
	
	-- Career hints
	if choice.hintCareer then
		state.CareerHints = state.CareerHints or {}
		state.CareerHints[choice.hintCareer] = true
	end
	
	-- Story arc unlocks
	if choice.unlocksStoryArc then
		state.StoryArcs = state.StoryArcs or {}
		table.insert(state.StoryArcs, choice.unlocksStoryArc)
	end
	
	return outcome
end

LifeEvents.EventEngine = EventEngine

-- ════════════════════════════════════════════════════════════════════════════
-- DEBUG
-- ════════════════════════════════════════════════════════════════════════════

function LifeEvents.debugListEvents()
	for id, event in pairs(AllEvents) do
		print(string.format("  [%s] %s (age %d-%d) cat=%s", 
			id, 
			event.title or "Untitled",
			event.minAge or 0,
			event.maxAge or 999,
			event._category or "?"
		))
	end
end

return LifeEvents
