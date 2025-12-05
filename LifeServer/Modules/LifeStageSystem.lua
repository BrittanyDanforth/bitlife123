--[[
	LifeStageSystem.lua
	
	Manages life stage transitions and death mechanics.
	Provides stage-based events and natural death checks.
]]

local LifeStageSystem = {}

local RANDOM = Random.new()

-- ════════════════════════════════════════════════════════════════════════════
-- LIFE STAGES
-- ════════════════════════════════════════════════════════════════════════════

local Stages = {
	{ id = "baby",        name = "Baby",        minAge = 0,  maxAge = 2,  emoji = "👶" },
	{ id = "toddler",     name = "Toddler",     minAge = 3,  maxAge = 4,  emoji = "🧒" },
	{ id = "child",       name = "Child",       minAge = 5,  maxAge = 12, emoji = "👧" },
	{ id = "teen",        name = "Teenager",    minAge = 13, maxAge = 17, emoji = "🧑" },
	{ id = "young_adult", name = "Young Adult", minAge = 18, maxAge = 29, emoji = "👨" },
	{ id = "adult",       name = "Adult",       minAge = 30, maxAge = 49, emoji = "👨" },
	{ id = "middle_age",  name = "Middle-Aged", minAge = 50, maxAge = 64, emoji = "👴" },
	{ id = "senior",      name = "Senior",      minAge = 65, maxAge = 999, emoji = "👴" },
}

local StageById = {}
for _, stage in ipairs(Stages) do
	StageById[stage.id] = stage
end

function LifeStageSystem.getStage(age)
	for _, stage in ipairs(Stages) do
		if age >= stage.minAge and age <= stage.maxAge then
			return stage
		end
	end
	return Stages[#Stages] -- Default to senior
end

function LifeStageSystem.getStageById(stageId)
	return StageById[stageId]
end

function LifeStageSystem.getAllStages()
	return Stages
end

-- ════════════════════════════════════════════════════════════════════════════
-- STAGE TRANSITIONS
-- ════════════════════════════════════════════════════════════════════════════

local TransitionEvents = {
	toddler = {
		id = "stage_transition_toddler",
		title = "Growing Up",
		emoji = "🧒",
		text = "You're no longer a baby! You're becoming more independent.",
		question = "How are you developing?",
		priority = "high",
		isMilestone = true,
		choices = {
			{
				text = "Curious about everything",
				effects = { Smarts = 5, Happiness = 3 },
				setFlags = { curious_toddler = true },
				feed = "You asked 'why?' about everything.",
			},
			{
				text = "Very active and energetic",
				effects = { Health = 5, Happiness = 3 },
				setFlags = { active_toddler = true },
				feed = "You never stopped moving!",
			},
			{
				text = "Quiet and observant",
				effects = { Smarts = 3, Happiness = 2 },
				setFlags = { observant_toddler = true },
				feed = "You watched the world with big eyes.",
			},
		},
	},
	
	child = {
		id = "stage_transition_child",
		title = "Starting School",
		emoji = "🎒",
		text = "It's time for elementary school! A whole new world awaits.",
		question = "How do you feel about this adventure?",
		priority = "high",
		isMilestone = true,
		choices = {
			{
				text = "Excited to learn!",
				effects = { Smarts = 5, Happiness = 5 },
				setFlags = { eager_learner = true },
				hintCareer = "education",
				feed = "You couldn't wait to start school!",
			},
			{
				text = "Nervous but ready",
				effects = { Smarts = 3, Happiness = 2 },
				feed = "You took a deep breath and walked in.",
			},
			{
				text = "Just want to make friends",
				effects = { Happiness = 5 },
				setFlags = { social_kid = true },
				feed = "You were most excited about new friends.",
			},
			{
				text = "Would rather stay home",
				effects = { Happiness = -3 },
				setFlags = { homebody = true },
				feed = "School wasn't your idea of fun.",
			},
		},
	},
	
	teen = {
		id = "stage_transition_teen",
		title = "The Teenage Years",
		emoji = "🎓",
		text = "You're officially a teenager! High school awaits.",
		question = "What's your approach to these formative years?",
		priority = "high",
		isMilestone = true,
		choices = {
			{
				text = "Focus on academics",
				effects = { Smarts = 5 },
				setFlags = { academic_teen = true },
				feed = "You're determined to excel in school.",
			},
			{
				text = "Be the social butterfly",
				effects = { Happiness = 5 },
				setFlags = { social_teen = true },
				feed = "Your social life is your priority.",
			},
			{
				text = "Find my passion",
				effects = { Happiness = 3, Smarts = 3 },
				setFlags = { passionate_teen = true },
				feed = "You're on a journey of self-discovery.",
			},
			{
				text = "Just survive it",
				effects = { Happiness = -2 },
				setFlags = { cynical_teen = true },
				feed = "You'll get through this... somehow.",
			},
		},
	},
	
	young_adult = {
		id = "stage_transition_young_adult",
		title = "Adulthood Begins",
		emoji = "🎉",
		text = "You're 18! The world is yours to explore.",
		question = "What's your plan for the future?",
		priority = "high",
		isMilestone = true,
		-- Ensure high school graduation is set when becoming an adult
		onComplete = function(state)
			-- Make sure they have high school education
			if state.Education == "none" or state.Education == nil then
				state.Education = "high_school"
			end
			state.Flags = state.Flags or {}
			state.Flags.is_adult = true
			state.Flags.graduated_high_school = true
			state.Flags.high_school_graduate = true
		end,
		choices = {
			{
				text = "Go to college",
				effects = { Smarts = 5 },
				setFlags = { college_bound = true, plans_for_college = true },
				hintCareer = "professional",
				feed = "Higher education is calling your name.",
			},
			{
				text = "Start working right away",
				effects = { Money = 500 },
				setFlags = { early_worker = true, workforce_bound = true },
				feed = "You're ready to earn your own money.",
			},
			{
				text = "Travel and explore",
				effects = { Happiness = 8 },
				setFlags = { wanderer = true, gap_year = true },
				feed = "You want to see the world before settling down.",
			},
			{
				text = "Figure it out as I go",
				effects = { Happiness = 3 },
				setFlags = { spontaneous = true },
				feed = "You'll take life one day at a time.",
			},
		},
	},
	
	adult = {
		id = "stage_transition_adult",
		title = "The Big 3-0",
		emoji = "🎂",
		text = "You're turning 30! A new decade of life begins.",
		question = "How do you feel about this milestone?",
		priority = "high",
		isMilestone = true,
		choices = {
			{
				text = "Excited for what's ahead",
				effects = { Happiness = 8 },
				feed = "30 is just the beginning!",
			},
			{
				text = "Reflective and grateful",
				effects = { Happiness = 5, Smarts = 2 },
				feed = "You appreciate how far you've come.",
			},
			{
				text = "A little anxious",
				effects = { Happiness = -3 },
				setFlags = { thirty_crisis = true },
				feed = "Where did the time go?",
			},
			{
				text = "Time for big changes",
				effects = { Happiness = 5 },
				setFlags = { reinventing = true },
				feed = "This birthday sparked a transformation.",
			},
		},
	},
	
	middle_age = {
		id = "stage_transition_middle_age",
		title = "Entering Your 50s",
		emoji = "🌟",
		text = "Half a century of life experience! You've seen a lot.",
		question = "What defines this chapter?",
		priority = "high",
		isMilestone = true,
		choices = {
			{
				text = "Wisdom and contentment",
				effects = { Happiness = 8, Smarts = 3 },
				feed = "You've found peace with who you are.",
			},
			{
				text = "Still ambitious",
				effects = { Smarts = 5 },
				setFlags = { still_hungry = true },
				feed = "You're not slowing down anytime soon.",
			},
			{
				text = "Focusing on family",
				effects = { Happiness = 6 },
				setFlags = { family_focused = true },
				feed = "Family is everything now.",
			},
			{
				text = "Dealing with regrets",
				effects = { Happiness = -5 },
				setFlags = { midlife_crisis = true },
				feed = "Some 'what ifs' are haunting you.",
			},
		},
	},
	
	senior = {
		id = "stage_transition_senior",
		title = "The Golden Years",
		emoji = "🌅",
		text = "You're 65! Time to enjoy the fruits of your labor.",
		question = "How do you approach your senior years?",
		priority = "high",
		isMilestone = true,
		choices = {
			{
				text = "Embrace retirement",
				effects = { Happiness = 10 },
				setFlags = { happily_retired = true, retired = true },
				feed = "Retirement is everything you hoped for. Your pension awaits.",
				-- Clear job when choosing full retirement
				onResolve = function(state)
					-- Calculate pension
					local pensionBase = 0
					if state.CurrentJob and state.CurrentJob.salary then
						pensionBase = math.floor(state.CurrentJob.salary * 0.4)
					end
					state.Flags = state.Flags or {}
					state.Flags.pension_amount = pensionBase
					state.Flags.retired = true
					
					-- Clear job
					if state.ClearCareer then
						state:ClearCareer()
					else
						state.CurrentJob = nil
						state.Flags.employed = nil
						state.Flags.has_job = nil
					end
				end,
			},
			{
				text = "Stay active and engaged",
				effects = { Health = 5, Happiness = 5 },
				setFlags = { active_senior = true, semi_retired = true },
				feed = "You refuse to slow down. Part-time work keeps you sharp.",
				-- Semi-retired: reduce hours/salary
				onResolve = function(state)
					if state.CurrentJob and state.CurrentJob.salary then
						state.CurrentJob.salary = math.floor(state.CurrentJob.salary * 0.5)
					end
				end,
			},
			{
				text = "Share your wisdom",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { wise_elder = true, retired = true },
				feed = "You have so much to teach younger generations. Your pension awaits.",
				-- Retire to mentor/teach
				onResolve = function(state)
					local pensionBase = 0
					if state.CurrentJob and state.CurrentJob.salary then
						pensionBase = math.floor(state.CurrentJob.salary * 0.4)
					end
					state.Flags = state.Flags or {}
					state.Flags.pension_amount = pensionBase
					state.Flags.retired = true
					
					if state.ClearCareer then
						state:ClearCareer()
					else
						state.CurrentJob = nil
						state.Flags.employed = nil
						state.Flags.has_job = nil
					end
				end,
			},
			{
				text = "Worry about health",
				effects = { Happiness = -5 },
				setFlags = { health_anxious = true, retired = true },
				feed = "Health concerns weigh on your mind. At least you have pension.",
				-- Anxious retirement
				onResolve = function(state)
					local pensionBase = 0
					if state.CurrentJob and state.CurrentJob.salary then
						pensionBase = math.floor(state.CurrentJob.salary * 0.4)
					end
					state.Flags = state.Flags or {}
					state.Flags.pension_amount = pensionBase
					state.Flags.retired = true
					
					if state.ClearCareer then
						state:ClearCareer()
					else
						state.CurrentJob = nil
						state.Flags.employed = nil
						state.Flags.has_job = nil
					end
				end,
			},
		},
	},
}

function LifeStageSystem.getTransitionEvent(oldAge, newAge)
	local oldStage = LifeStageSystem.getStage(oldAge)
	local newStage = LifeStageSystem.getStage(newAge)
	
	if oldStage.id ~= newStage.id then
		local event = TransitionEvents[newStage.id]
		if event then
			return event
		end
	end
	
	return nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT VALIDATION (used by EventEngine)
-- ════════════════════════════════════════════════════════════════════════════

function LifeStageSystem.validateEvent(event, state)
	if not event or not state then
		return false
	end
	
	local age = state.Age or 0
	local flags = state.Flags or {}
	local stats = state.Stats or state
	
	-- Check conditions table if present
	local conditions = event.conditions or {}
	
	-- Age requirements (from conditions or direct event properties)
	local minAge = conditions.minAge or event.minAge or 0
	local maxAge = conditions.maxAge or event.maxAge or 999
	if age < minAge or age > maxAge then
		return false
	end
	
	-- Required flags (supports both array format and table format)
	local requiredFlags = conditions.requiredFlags or event.requiresFlags
	if requiredFlags then
		for key, value in pairs(requiredFlags) do
			if type(key) == "number" then
				-- Array format: { "flag1", "flag2" } - each value is a flag name
				if not flags[value] then
					return false
				end
			elseif type(value) == "boolean" then
				-- Table format: { flag1 = true, flag2 = false }
				if value == true and not flags[key] then
					return false
				end
				if value == false and flags[key] then
					return false
				end
			else
				-- Nested array format: { flag1 = { "subvalue" } } - unlikely but handle gracefully
				if not flags[key] then
					return false
				end
			end
		end
	end
	
	-- Blocked flags (supports both array format and table format)
	local blockedFlags = conditions.blockedFlags or event.blockedByFlags
	if blockedFlags then
		-- Check if it's a table with key-value pairs or an array
		for key, value in pairs(blockedFlags) do
			if type(key) == "number" then
				-- Array format: { "flag1", "flag2" }
				if flags[value] then
					return false
				end
			else
				-- Table format: { flag1 = true, flag2 = true }
				if value == true and flags[key] then
					return false
				end
			end
		end
	end
	
	-- Stat requirements
	local minStats = conditions.minStats or event.requiresStats
	if minStats then
		for stat, minValue in pairs(minStats) do
			local playerValue = stats[stat] or state[stat] or 50
			if playerValue < minValue then
				return false
			end
		end
	end
	
	return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- DEATH MECHANICS
-- ════════════════════════════════════════════════════════════════════════════

local DeathCauses = {
	-- Natural causes (age-related)
	{ id = "old_age",        cause = "Natural causes",          minAge = 70 },
	{ id = "heart_attack",   cause = "Heart attack",            minAge = 50, healthFactor = 0.3 },
	{ id = "stroke",         cause = "Stroke",                  minAge = 55, healthFactor = 0.25 },
	{ id = "cancer",         cause = "Cancer",                  minAge = 40, baseChance = 0.01 },
	
	-- Lifestyle-related (checked via flags)
	{ id = "overdose",       cause = "Drug overdose",           requiresFlag = "substance_issue", chance = 0.05 },
	{ id = "alcohol",        cause = "Alcohol-related illness", requiresFlag = "heavy_drinker", minAge = 35, chance = 0.02 },
	
	-- Random accidents (very low chance)
	{ id = "accident",       cause = "Tragic accident",         baseChance = 0.001 },
}

function LifeStageSystem.checkDeath(state)
	local age = state.Age or 0
	local health = state.Health or state.Stats.Health or 50
	local flags = state.Flags or {}
	
	-- Health at 0 = immediate death
	if health <= 0 then
		return { died = true, cause = "Health failure" }
	end
	
	-- Very old age = high death chance
	if age >= 100 then
		if RANDOM:NextNumber() < 0.5 then
			return { died = true, cause = "Extraordinarily long life", id = "centenarian" }
		end
	end
	
	-- Check each death cause
	for _, deathType in ipairs(DeathCauses) do
		local canOccur = true
		local chance = deathType.baseChance or 0
		
		-- Age requirement
		if deathType.minAge and age < deathType.minAge then
			canOccur = false
		end
		
		-- Flag requirement
		if deathType.requiresFlag and not flags[deathType.requiresFlag] then
			canOccur = false
		end
		
		-- Calculate chance based on age and health
		if canOccur then
			-- Base age-related chance (increases dramatically after 70)
			if age >= 70 then
				chance = chance + ((age - 70) / 100) * 0.15
			end
			
			-- Health factor (low health increases death chance)
			if deathType.healthFactor then
				if health < 30 then
					chance = chance + deathType.healthFactor * (1 - health/30)
				end
			end
			
			-- Old age natural death
			if deathType.id == "old_age" and age >= 75 then
				chance = chance + ((age - 75) / 100) * 0.2
				if health < 50 then
					chance = chance * 1.5
				end
			end
			
			-- Flag-based deaths
			if deathType.chance and deathType.requiresFlag then
				chance = deathType.chance
			end
			
			-- Roll the dice
			if chance > 0 and RANDOM:NextNumber() < chance then
				return {
					died = true,
					cause = deathType.cause,
					id = deathType.id,
				}
			end
		end
	end
	
	return { died = false }
end

-- ════════════════════════════════════════════════════════════════════════════
-- MILESTONE AGES
-- ════════════════════════════════════════════════════════════════════════════

local MilestoneAges = {
	[1] = "First birthday!",
	[5] = "Starting school",
	[10] = "Double digits!",
	[13] = "Officially a teenager",
	[16] = "Sweet sixteen",
	[18] = "Legal adult",
	[21] = "Can drink legally",
	[30] = "The big 3-0",
	[40] = "The big 4-0",
	[50] = "Half a century",
	[60] = "Entering your 60s",
	[65] = "Retirement age",
	[70] = "Entering your 70s",
	[75] = "Three quarters of a century",
	[80] = "Octogenarian",
	[90] = "Nonagenarian",
	[100] = "Centenarian!",
}

function LifeStageSystem.getMilestoneText(age)
	return MilestoneAges[age]
end

function LifeStageSystem.isMilestoneAge(age)
	return MilestoneAges[age] ~= nil
end

return LifeStageSystem
