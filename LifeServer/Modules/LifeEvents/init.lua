--[[
	LifeEvents/init.lua
	
	CONSOLIDATED Event system for BitLife-style game.
	Loads events from external module files and provides event engine.
	
	Usage:
		local LifeEvents = require(LifeEventsFolder:WaitForChild("init"))
		local events = LifeEvents.buildYearQueue(playerState, { maxEvents = 1 })
		LifeEvents.EventEngine.completeEvent(eventDef, choiceIndex, state)
]]

local LifeEvents = {}

local RANDOM = Random.new()

-- Master event registry
local AllEvents = {}
local EventsByCategory = {}

-- ════════════════════════════════════════════════════════════════════════════
-- LIFE STAGES
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
-- LOAD EXTERNAL EVENT MODULES
-- ════════════════════════════════════════════════════════════════════════════

local function safeRequire(moduleScript)
	local success, result = pcall(function()
		return require(moduleScript)
	end)
	if success then
		return result
	else
		warn("[LifeEvents] Failed to load module:", moduleScript.Name, result)
		return nil
	end
end

-- Load all external event modules
local ExternalModules = {}
local moduleFolder = script

-- Try to load each external module
local moduleNames = {"Childhood", "Teen", "Adult", "Career", "Relationships", "Milestones", "Random"}
for _, moduleName in ipairs(moduleNames) do
	local moduleScript = moduleFolder:FindFirstChild(moduleName)
	if moduleScript then
		local moduleData = safeRequire(moduleScript)
		if moduleData and moduleData.events then
			ExternalModules[moduleName:lower()] = moduleData.events
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

local function registerEvents(events, categoryName)
	EventsByCategory[categoryName] = EventsByCategory[categoryName] or {}
	local count = 0
	
	for _, event in ipairs(events) do
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
	local categoryCount = 0
	
	-- Load from external modules
	for moduleName, events in pairs(ExternalModules) do
		local count = registerEvents(events, moduleName)
		total += count
		categoryCount += 1
	end
	
	print(string.format("[LifeEvents] Loaded %d events across %d categories.", total, categoryCount))
	return total
end

-- Auto-init
LifeEvents.init()

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT HISTORY TRACKING
-- ════════════════════════════════════════════════════════════════════════════

local function getEventHistory(state)
	state.EventHistory = state.EventHistory or {
		occurrences = {},
		lastOccurrence = {},
		completed = {},
		recentCategories = {},
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
	
	table.insert(history.recentCategories, event._category or "general")
	if #history.recentCategories > 5 then
		table.remove(history.recentCategories, 1)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- ELIGIBILITY CHECKS - THIS IS THE CORE CONTEXTUAL LOGIC
-- ════════════════════════════════════════════════════════════════════════════

local function canEventTrigger(event, state)
	local age = state.Age or 0
	local history = getEventHistory(state)
	
	-- Age check
	if event.minAge and age < event.minAge then return false end
	if event.maxAge and age > event.maxAge then return false end
	
	-- One-time event check
	if event.oneTime and history.completed[event.id] then
		return false
	end
	
	-- Cooldown check
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
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- CONTEXTUAL REQUIREMENTS - MUST ALIGN WITH PLAYER'S LIFE SITUATION
	-- ═══════════════════════════════════════════════════════════════════════
	
	-- Check required flags (e.g., has_best_friend, college_bound, etc.)
	if event.requiresFlags then
		local flags = state.Flags or {}
		for flag, required in pairs(event.requiresFlags) do
			if required == true and not flags[flag] then 
				return false -- Missing required flag
			end
			if required == false and flags[flag] then 
				return false -- Has blocked flag
			end
		end
	end
	
	-- Check required stats (e.g., Smarts >= 60)
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
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- JOB/CAREER REQUIREMENTS - NO RANDOM CAREER EVENTS IF UNEMPLOYED!
	-- ═══════════════════════════════════════════════════════════════════════
	
	-- Check if event requires having a job
	if event.requiresJob then
		local hasJob = state.CurrentJob ~= nil
		if not hasJob then 
			return false -- Cannot trigger career events without a job
		end
	end
	
	-- Check if event requires NOT having a job (for job seeking events)
	if event.requiresNoJob then
		local hasJob = state.CurrentJob ~= nil
		if hasJob then 
			return false -- Cannot trigger unemployment events while employed
		end
	end
	
	-- Check if event requires specific job category (tech, medical, law, etc.)
	if event.requiresJobCategory then
		local hasJob = state.CurrentJob ~= nil
		if not hasJob then 
			return false -- Need a job first
		end
		local jobCategory = state.CurrentJob.category or ""
		if jobCategory ~= event.requiresJobCategory then
			return false -- Wrong job category
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- RELATIONSHIP REQUIREMENTS - NO MARRIAGE PROPOSALS IF SINGLE!
	-- ═══════════════════════════════════════════════════════════════════════
	
	-- Check if event requires having a partner
	if event.requiresPartner then
		local hasPartner = state.Relationships and state.Relationships.partner
		if not hasPartner then 
			return false -- Cannot trigger partner events without a partner
		end
	end
	
	-- Check if event requires being single (no partner)
	if event.requiresSingle then
		local hasPartner = state.Relationships and state.Relationships.partner
		if hasPartner then
			return false -- Cannot trigger single events while in relationship
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- EDUCATION REQUIREMENTS - NO COLLEGE EVENTS WITHOUT COLLEGE!
	-- ═══════════════════════════════════════════════════════════════════════
	
	-- Check if event requires education level
	if event.requiresEducation then
		local edu = state.Education or "none"
		local eduLevels = { 
			none = 0, 
			elementary = 1, 
			middle_school = 2, 
			high_school = 3, 
			community = 4, 
			bachelor = 5, 
			master = 6, 
			law = 7, 
			medical = 7, 
			phd = 8 
		}
		local playerLevel = eduLevels[edu] or 0
		local requiredLevel = eduLevels[event.requiresEducation] or 0
		if playerLevel < requiredLevel then 
			return false -- Need higher education
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- RANDOM CHANCE CHECK - Last, after all contextual checks pass
	-- ═══════════════════════════════════════════════════════════════════════
	
	if event.baseChance then
		if RANDOM:NextNumber() > (event.baseChance or 1) then
			return false
		end
	end
	
	return true
end

local function getEventWeight(event, state)
	local history = getEventHistory(state)
	local weight = event.weight or 10
	
	-- Boost never-seen events
	local occurCount = history.occurrences[event.id] or 0
	if occurCount == 0 then
		weight = weight * 2.5
	end
	
	-- Boost milestone/priority events
	if event.priority == "high" or event.isMilestone then
		weight = weight * 3
	end
	
	-- Reduce weight for recently-seen categories
	local recentCats = history.recentCategories or {}
	for _, cat in ipairs(recentCats) do
		if cat == event._category then
			weight = weight * 0.5
			break
		end
	end
	
	-- Reduce weight for recently-seen events
	local lastAge = history.lastOccurrence[event.id]
	if lastAge then
		local yearsSince = (state.Age or 0) - lastAge
		if yearsSince < 5 then
			weight = weight * (0.3 + (yearsSince / 10))
		end
	end
	
	return math.max(weight, 1)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CATEGORY SELECTION - Which event pools are relevant to player's age/situation
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
		
		-- Only include career events if player has a job
		if state.CurrentJob then
			table.insert(categories, "career")
		end
	end
	
	return categories
end

-- ════════════════════════════════════════════════════════════════════════════
-- BUILD YEAR QUEUE - Main entry point for selecting events
-- ════════════════════════════════════════════════════════════════════════════

function LifeEvents.buildYearQueue(state, options)
	options = options or {}
	local maxEvents = options.maxEvents or 1 -- BitLife style: 1 event max per year
	
	if not state then return {} end
	
	local selectedEvents = {}
	local candidateEvents = {}
	
	local categories = getRelevantCategories(state)
	
	-- Collect all eligible events from relevant categories
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
	
	if #candidateEvents == 0 then
		return {}
	end
	
	-- Separate priority (milestone) events from regular events
	local priorityEvents = {}
	local regularEvents = {}
	
	for _, candidate in ipairs(candidateEvents) do
		if candidate.priority then
			table.insert(priorityEvents, candidate)
		else
			table.insert(regularEvents, candidate)
		end
	end
	
	-- Priority events (milestones) always trigger if available
	if #priorityEvents > 0 then
		-- Pick the highest weighted priority event
		table.sort(priorityEvents, function(a, b) return a.weight > b.weight end)
		local chosen = priorityEvents[1]
		table.insert(selectedEvents, chosen.event)
		recordEventShown(state, chosen.event)
		return selectedEvents -- Just return the milestone, don't stack more events
	end
	
	-- For regular events: chance of a "quiet year" with no events
	local age = state.Age or 0
	local quietChance = 0.4
	if age <= 4 then
		quietChance = 0.3 -- More things happen in early childhood
	elseif age <= 12 then
		quietChance = 0.4
	elseif age <= 17 then
		quietChance = 0.35
	else
		quietChance = 0.5 -- Adult years are often routine
	end
	
	if RANDOM:NextNumber() < quietChance then
		return {} -- Quiet year, no event
	end
	
	-- Select ONE regular event using weighted random selection
	if #regularEvents > 0 then
		local totalWeight = 0
		for _, candidate in ipairs(regularEvents) do
			totalWeight = totalWeight + candidate.weight
		end
		
		local roll = RANDOM:NextNumber() * totalWeight
		local cumulative = 0
		
		for _, candidate in ipairs(regularEvents) do
			cumulative = cumulative + candidate.weight
			if roll <= cumulative then
				table.insert(selectedEvents, candidate.event)
				recordEventShown(state, candidate.event)
				break
			end
		end
	end
	
	return selectedEvents
end

function LifeEvents.getEvent(eventId)
	return AllEvents[eventId]
end

function LifeEvents.getAllEvents()
	return AllEvents
end

function LifeEvents.getEventsByCategory(categoryName)
	return EventsByCategory[categoryName] or {}
end

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT ENGINE - Handles event completion and stat changes
-- ════════════════════════════════════════════════════════════════════════════

local EventEngine = {}

-- Name pools for generating relationship names
local MaleNames = {"James", "Michael", "David", "John", "Robert", "Chris", "Daniel", "Matthew", "Anthony", "Mark", "Steven", "Andrew", "Joshua", "Kevin", "Brian", "Ryan", "Justin", "Brandon", "Eric", "Tyler", "Alex", "Jake", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Oliver", "Aiden", "Carter"}
local FemaleNames = {"Emma", "Olivia", "Sophia", "Isabella", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn", "Abigail", "Emily", "Elizabeth", "Sofia", "Avery", "Ella", "Scarlett", "Grace", "Chloe", "Victoria", "Riley", "Aria", "Lily", "Zoey", "Hannah", "Layla", "Nora", "Zoe", "Leah", "Hazel", "Luna"}

local function generateName(gender)
	if gender == "female" then
		return FemaleNames[RANDOM:NextInteger(1, #FemaleNames)]
	else
		return MaleNames[RANDOM:NextInteger(1, #MaleNames)]
	end
end

local function getOppositeGender(playerGender)
	if playerGender == "male" or playerGender == "Male" then
		return "female"
	else
		return "male"
	end
end

local function createRelationship(state, relType, customName)
	state.Relationships = state.Relationships or {}
	
	local id = relType .. "_" .. tostring(RANDOM:NextInteger(1000, 9999))
	local age = state.Age or 20
	local gender = "male"
	local name = customName
	
	-- For romance, use opposite gender
	if relType == "romance" or relType == "partner" then
		gender = getOppositeGender(state.Gender or "male")
		name = name or generateName(gender)
		-- Romance partners are around the same age
		age = math.max(18, age + RANDOM:NextInteger(-5, 5))
	elseif relType == "friend" then
		-- Friends can be any gender
		gender = RANDOM:NextNumber() > 0.5 and "male" or "female"
		name = name or generateName(gender)
		age = math.max(5, age + RANDOM:NextInteger(-3, 3))
	end
	
	local relationship = {
		id = id,
		name = name,
		type = relType,
		role = relType == "romance" and "Partner" or (relType == "friend" and "Friend" or relType),
		relationship = RANDOM:NextInteger(50, 75), -- Starting relationship level
		age = age,
		gender = gender,
		alive = true,
		metAge = state.Age,
	}
	
	state.Relationships[id] = relationship
	
	-- For romance, also set as "partner" for easy access
	if relType == "romance" then
		state.Relationships.partner = relationship
	end
	
	return relationship
end

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
	
	-- Apply stat effects
	local effects = choice.effects or choice.deltas or {}
	for stat, change in pairs(effects) do
		local delta = change
		if type(change) == "table" then
			local min = change.min or change[1] or 0
			local max = change.max or change[2] or 0
			delta = RANDOM:NextInteger(min, max)
		end
		
		outcome.statChanges[stat] = delta
		
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
	
	-- ═══════════════════════════════════════════════════════════════════
	-- RELATIONSHIP CREATION BASED ON EVENT
	-- ═══════════════════════════════════════════════════════════════════
	
	local eventId = eventDef.id or ""
	state.Relationships = state.Relationships or {}
	
	-- Friend-making events (childhood best friend)
	if eventId == "first_best_friend" then
		if choiceIndex >= 1 and choiceIndex <= 4 then -- All positive choices make a friend
			local friend = createRelationship(state, "friend")
			outcome.feedText = outcome.feedText .. " " .. friend.name .. " became your best friend!"
			outcome.newRelationship = friend
		end
	end
	
	-- New friendship (adult)
	if eventId == "new_friendship" then
		if choiceIndex == 1 or choiceIndex == 4 then -- "Invite to hang out" or "Share something personal"
			local friend = createRelationship(state, "friend")
			outcome.feedText = outcome.feedText .. " You became friends with " .. friend.name .. "!"
			outcome.newRelationship = friend
		end
	end
	
	-- Dating app - creates a new partner
	if eventId == "dating_app" then
		if choiceIndex == 1 then -- "Met someone special"
			if not state.Relationships.partner then
				local partner = createRelationship(state, "romance")
				outcome.feedText = "You matched with " .. partner.name .. " and hit it off!"
				outcome.newRelationship = partner
				state.Flags.dating = true
				state.Flags.has_partner = true
			end
		end
	end
	
	-- High school romance
	if eventId == "high_school_romance" then
		if choiceIndex == 1 then -- "Ask them out"
			if not state.Relationships.partner then
				local partner = createRelationship(state, "romance")
				outcome.feedText = "You asked " .. partner.name .. " out and they said yes!"
				outcome.newRelationship = partner
				state.Flags.dating = true
				state.Flags.has_partner = true
			end
		end
	end
	
	-- Serious relationship - deepens existing relationship
	if eventId == "serious_relationship" then
		local partner = state.Relationships.partner
		if partner then
			if choiceIndex == 1 then -- "Commit fully"
				partner.relationship = math.min(100, (partner.relationship or 50) + 20)
				state.Flags.committed_relationship = true
				outcome.feedText = "Your relationship with " .. partner.name .. " is now rock solid!"
			elseif choiceIndex == 4 then -- "End the relationship"
				state.Relationships.partner = nil
				state.Relationships[partner.id] = nil
				state.Flags.has_partner = nil
				state.Flags.dating = nil
				state.Flags.recently_single = true
				outcome.feedText = "You broke up with " .. partner.name .. "."
			else
				partner.relationship = math.min(100, (partner.relationship or 50) + 5)
			end
		end
	end
	
	-- First crush (childhood) - just a flag, no real relationship
	if eventId == "first_crush" or eventId == "first_crush_kid" then
		if choiceIndex == 1 or choiceIndex == 2 then
			state.Flags.had_first_crush = true
		end
	end
	
	-- Marriage proposal - requires existing partner
	if eventId == "marriage_proposal" then
		local partner = state.Relationships.partner
		if partner then
			if choiceIndex == 1 or choiceIndex == 3 then -- They said yes
				state.Flags.engaged = true
				partner.role = "Fiancé"
				outcome.feedText = partner.name .. " said YES! You're engaged!"
			elseif choiceIndex == 2 then -- They said no
				state.Relationships.partner = nil
				state.Relationships[partner.id] = nil
				state.Flags.proposal_rejected = true
				outcome.feedText = partner.name .. " said no. The relationship ended."
			end
		end
	end
	
	-- Wedding creates marriage
	if eventId == "wedding_day" then
		local partner = state.Relationships.partner
		if partner then
			state.Flags.married = true
			state.Flags.engaged = nil
			partner.role = "Spouse"
			outcome.feedText = "You married " .. partner.name .. "!"
		end
	end
	
	return outcome
end

LifeEvents.EventEngine = EventEngine

return LifeEvents
