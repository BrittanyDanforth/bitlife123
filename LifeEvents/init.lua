-- LifeEvents/init.lua
-- Comprehensive Event System for BitLife-style game
-- Smart event selection, story tracking, and career linking

local LifeEvents = {}

-- Import event modules
local ChildhoodEvents = require(script:WaitForChild("Childhood"))
local TeenEvents = require(script:WaitForChild("Teen"))
local AdultEvents = require(script:WaitForChild("Adult"))
local CareerEvents = require(script:WaitForChild("Career"))
local RelationshipEvents = require(script:WaitForChild("Relationships"))
local MilestoneEvents = require(script:WaitForChild("Milestones"))

-- All event modules
local EventModules = {
	Childhood = ChildhoodEvents,
	Teen = TeenEvents,
	Adult = AdultEvents,
	Career = CareerEvents,
	Relationships = RelationshipEvents,
	Milestones = MilestoneEvents,
}

-- Master event registry
local AllEvents = {}

-- Initialize and index all events
function LifeEvents.init()
	AllEvents = {}
	local totalCount = 0
	local moduleCount = 0
	
	for moduleName, module in pairs(EventModules) do
		if module.events then
			moduleCount += 1
			for _, event in ipairs(module.events) do
				event._module = moduleName
				AllEvents[event.id] = event
				totalCount += 1
			end
		end
	end
	
	print(string.format("[LifeEvents] Loaded %d events across %d modules.", totalCount, moduleCount))
	return totalCount, moduleCount
end

-- Get event by ID
function LifeEvents.getEvent(eventId)
	return AllEvents[eventId]
end

-- Life stages
local LifeStages = {
	{ name = "baby", minAge = 0, maxAge = 2 },
	{ name = "toddler", minAge = 3, maxAge = 4 },
	{ name = "child", minAge = 5, maxAge = 12 },
	{ name = "teen", minAge = 13, maxAge = 17 },
	{ name = "young_adult", minAge = 18, maxAge = 29 },
	{ name = "adult", minAge = 30, maxAge = 49 },
	{ name = "middle_age", minAge = 50, maxAge = 64 },
	{ name = "senior", minAge = 65, maxAge = 999 },
}

function LifeEvents.getLifeStage(age)
	for _, stage in ipairs(LifeStages) do
		if age >= stage.minAge and age <= stage.maxAge then
			return stage.name
		end
	end
	return "adult"
end

-- Check if event can trigger based on conditions
local function canEventTrigger(event, playerState, eventHistory)
	-- Age check
	local age = playerState.Age or 0
	if event.minAge and age < event.minAge then return false end
	if event.maxAge and age > event.maxAge then return false end
	
	-- Life stage check
	if event.lifeStage then
		local currentStage = LifeEvents.getLifeStage(age)
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
	
	-- Cooldown check - prevent same event from appearing too soon
	local eventCooldown = event.cooldown or 5 -- Default 5 years cooldown
	local lastOccurrence = eventHistory.lastOccurrence[event.id]
	if lastOccurrence and (age - lastOccurrence) < eventCooldown then
		return false
	end
	
	-- Max occurrences check
	local maxOccur = event.maxOccurrences or 3
	local occurCount = eventHistory.occurrences[event.id] or 0
	if occurCount >= maxOccur then
		return false
	end
	
	-- One-time event check
	if event.oneTime and occurCount > 0 then
		return false
	end
	
	-- Prerequisite events check
	if event.requiresEvents then
		for _, reqEventId in ipairs(event.requiresEvents) do
			if not eventHistory.completed[reqEventId] then
				return false
			end
		end
	end
	
	-- Blocked by events check
	if event.blockedByEvents then
		for _, blockEventId in ipairs(event.blockedByEvents) do
			if eventHistory.completed[blockEventId] then
				return false
			end
		end
	end
	
	-- Flag requirements
	if event.requiresFlags then
		for flag, requiredValue in pairs(event.requiresFlags) do
			local playerFlag = playerState.Flags and playerState.Flags[flag]
			if requiredValue == true and not playerFlag then return false end
			if requiredValue == false and playerFlag then return false end
			if type(requiredValue) ~= "boolean" and playerFlag ~= requiredValue then return false end
		end
	end
	
	-- Stat requirements
	if event.requiresStats then
		for stat, requirement in pairs(event.requiresStats) do
			local playerStat = playerState[stat] or 50
			if type(requirement) == "number" then
				if playerStat < requirement then return false end
			elseif type(requirement) == "table" then
				if requirement.min and playerStat < requirement.min then return false end
				if requirement.max and playerStat > requirement.max then return false end
			end
		end
	end
	
	-- Education requirements
	if event.requiresEducation then
		local education = playerState.Education or "none"
		local eduLevel = {
			none = 0,
			elementary = 1,
			middle_school = 2,
			high_school = 3,
			community_college = 4,
			bachelor = 5,
			master = 6,
			doctorate = 7,
			medical = 8,
			law = 8,
		}
		local requiredLevel = eduLevel[event.requiresEducation] or 0
		local playerLevel = eduLevel[education] or 0
		if playerLevel < requiredLevel then return false end
	end
	
	-- Career requirements
	if event.requiresJob then
		local currentJob = playerState.CurrentJob
		if not currentJob then return false end
		if type(event.requiresJob) == "string" and currentJob ~= event.requiresJob then
			return false
		end
		if type(event.requiresJob) == "table" then
			local found = false
			for _, job in ipairs(event.requiresJob) do
				if currentJob == job then found = true; break end
			end
			if not found then return false end
		end
	end
	
	-- Category requirements
	if event.requiresJobCategory then
		local jobCategory = playerState.JobCategory
		if not jobCategory then return false end
		if type(event.requiresJobCategory) == "string" and jobCategory ~= event.requiresJobCategory then
			return false
		end
	end
	
	-- Random chance check (for variety)
	if event.baseChance then
		local roll = math.random()
		local chance = event.baseChance
		
		-- Modify chance based on player traits
		if event.chanceModifiers then
			for stat, modifier in pairs(event.chanceModifiers) do
				local statValue = playerState[stat] or 50
				chance = chance + (modifier * (statValue / 100))
			end
		end
		
		if roll > math.min(chance, 0.95) then return false end
	end
	
	return true
end

-- Calculate event priority/weight
local function getEventWeight(event, playerState, eventHistory)
	local weight = event.weight or 10
	
	-- Boost weight for never-seen events
	local occurCount = eventHistory.occurrences[event.id] or 0
	if occurCount == 0 then
		weight = weight * 2
	end
	
	-- Boost weight for events matching player's story arc
	if event.storyArc and playerState.StoryArcs then
		for _, arc in ipairs(playerState.StoryArcs) do
			if arc == event.storyArc then
				weight = weight * 1.5
				break
			end
		end
	end
	
	-- Boost weight based on trait affinity
	if event.traitAffinity then
		for trait, affinity in pairs(event.traitAffinity) do
			local traitValue = playerState[trait] or 50
			if traitValue > 70 then
				weight = weight * (1 + affinity * 0.5)
			elseif traitValue < 30 then
				weight = weight * (1 - affinity * 0.3)
			end
		end
	end
	
	-- Reduce weight for recently occurred events
	local lastAge = eventHistory.lastOccurrence[event.id]
	if lastAge then
		local yearsSince = (playerState.Age or 0) - lastAge
		if yearsSince < 10 then
			weight = weight * (0.5 + (yearsSince / 20))
		end
	end
	
	return math.max(weight, 1)
end

-- Select events for a given age
function LifeEvents.selectEventsForAge(playerState, eventHistory, maxEvents)
	maxEvents = maxEvents or 2
	local age = playerState.Age or 0
	local selectedEvents = {}
	local candidateEvents = {}
	
	-- Collect all eligible events
	for eventId, event in pairs(AllEvents) do
		if canEventTrigger(event, playerState, eventHistory) then
			local weight = getEventWeight(event, playerState, eventHistory)
			table.insert(candidateEvents, {
				event = event,
				weight = weight,
			})
		end
	end
	
	-- Priority events (milestones, stage transitions) get selected first
	local priorityEvents = {}
	local regularEvents = {}
	
	for _, candidate in ipairs(candidateEvents) do
		if candidate.event.priority == "high" or candidate.event.isMilestone then
			table.insert(priorityEvents, candidate)
		else
			table.insert(regularEvents, candidate)
		end
	end
	
	-- Add priority events first
	for _, candidate in ipairs(priorityEvents) do
		if #selectedEvents < maxEvents then
			table.insert(selectedEvents, candidate.event)
		end
	end
	
	-- Weighted random selection for remaining slots
	if #selectedEvents < maxEvents and #regularEvents > 0 then
		-- Calculate total weight
		local totalWeight = 0
		for _, candidate in ipairs(regularEvents) do
			totalWeight = totalWeight + candidate.weight
		end
		
		-- Select remaining events
		local attempts = 0
		while #selectedEvents < maxEvents and #regularEvents > 0 and attempts < 50 do
			attempts += 1
			local roll = math.random() * totalWeight
			local cumulative = 0
			
			for i, candidate in ipairs(regularEvents) do
				cumulative = cumulative + candidate.weight
				if roll <= cumulative then
					-- Check we haven't already selected this event
					local alreadySelected = false
					for _, selected in ipairs(selectedEvents) do
						if selected.id == candidate.event.id then
							alreadySelected = true
							break
						end
					end
					
					if not alreadySelected then
						table.insert(selectedEvents, candidate.event)
						-- Remove from candidates to prevent re-selection
						totalWeight = totalWeight - candidate.weight
						table.remove(regularEvents, i)
					end
					break
				end
			end
		end
	end
	
	-- Ensure variety - no more than 1 event from same category
	local seenCategories = {}
	local finalEvents = {}
	for _, event in ipairs(selectedEvents) do
		local category = event.category or "general"
		if not seenCategories[category] or event.priority == "high" then
			seenCategories[category] = true
			table.insert(finalEvents, event)
		end
	end
	
	return finalEvents
end

-- Process a choice and get outcomes
function LifeEvents.processChoice(eventId, choiceIndex, playerState)
	local event = AllEvents[eventId]
	if not event then
		warn("[LifeEvents] Unknown event:", eventId)
		return nil
	end
	
	local choice = event.choices and event.choices[choiceIndex]
	if not choice then
		warn("[LifeEvents] Invalid choice index:", choiceIndex, "for event:", eventId)
		return nil
	end
	
	-- Build outcome
	local outcome = {
		eventId = eventId,
		choiceIndex = choiceIndex,
		text = choice.outcomeText or choice.text,
		emoji = choice.outcomeEmoji or event.emoji,
		statChanges = {},
		flagChanges = {},
		unlocks = {},
		feedText = nil,
	}
	
	-- Apply stat effects
	if choice.effects then
		for stat, change in pairs(choice.effects) do
			if type(change) == "number" then
				outcome.statChanges[stat] = change
			elseif type(change) == "table" then
				-- Random range
				local min = change.min or change[1] or 0
				local max = change.max or change[2] or 0
				outcome.statChanges[stat] = math.random(min, max)
			end
		end
	end
	
	-- Apply flag changes
	if choice.setFlags then
		for flag, value in pairs(choice.setFlags) do
			outcome.flagChanges[flag] = value
		end
	end
	
	-- Story arc unlocks
	if choice.unlocksStoryArc then
		outcome.unlocks.storyArc = choice.unlocksStoryArc
	end
	
	-- Career path hints
	if choice.hintCareer then
		outcome.unlocks.careerHint = choice.hintCareer
	end
	
	-- Generate feed text
	if choice.feedText then
		outcome.feedText = choice.feedText
	else
		-- Auto-generate based on effects
		local effects = {}
		if outcome.statChanges.Happiness then
			local h = outcome.statChanges.Happiness
			table.insert(effects, h > 0 and "felt happier" or "felt down")
		end
		if outcome.statChanges.Health then
			local h = outcome.statChanges.Health
			table.insert(effects, h > 0 and "improved health" or "health suffered")
		end
		if outcome.statChanges.Smarts then
			local s = outcome.statChanges.Smarts
			table.insert(effects, s > 0 and "learned something" or "confusion ensued")
		end
		if outcome.statChanges.Money then
			local m = outcome.statChanges.Money
			table.insert(effects, m > 0 and ("earned " .. m) or ("lost " .. math.abs(m)))
		end
		
		if #effects > 0 then
			outcome.feedText = table.concat(effects, ", "):gsub("^%l", string.upper) .. "."
		end
	end
	
	return outcome
end

-- Get stage transition event if applicable
function LifeEvents.getStageTransitionEvent(previousAge, newAge)
	local prevStage = LifeEvents.getLifeStage(previousAge)
	local newStage = LifeEvents.getLifeStage(newAge)
	
	if prevStage ~= newStage then
		local transitionId = "stage_transition_" .. newStage
		return AllEvents[transitionId]
	end
	
	return nil
end

-- Debug: List all events
function LifeEvents.debugListEvents()
	for id, event in pairs(AllEvents) do
		print(string.format("  [%s] %s (age %d-%d)", 
			id, 
			event.title or "Untitled",
			event.minAge or 0,
			event.maxAge or 999
		))
	end
end

return LifeEvents
