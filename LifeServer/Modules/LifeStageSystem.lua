--[[
	LifeStageSystem.lua
	
	Manages life stage transitions and death mechanics.
	Provides stage-based events and natural death checks.
	
	MINOR FIX: Added documentation on life stages
	Life Stages:
	  - Baby (0-2): First experiences, family bonding
	  - Toddler (3-4): Learning, curiosity, first words/steps
	  - Child (5-12): School, friendships, hobbies, family dynamics
	  - Teen (13-17): High school, first jobs, relationships, identity
	  - Young Adult (18-29): College, career start, independence
	  - Adult (30-49): Career peak, family building, home ownership
	  - Middle-Aged (50-64): Career culmination, midlife reflection
	  - Senior (65+): Retirement, legacy, health considerations
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- EXPANDED DEATH CAUSES - BitLife AAA Quality
-- More varied and realistic causes of death with appropriate age/flag checks
-- ═══════════════════════════════════════════════════════════════════════════════
local DeathCauses = {
	-- ═════════════════════════════════════════════════════════════════════════
	-- NATURAL CAUSES (age-related)
	-- ═════════════════════════════════════════════════════════════════════════
	{ id = "old_age",        cause = "peacefully in their sleep", minAge = 75, description = "After a long and full life" },
	{ id = "heart_attack",   cause = "a sudden heart attack", minAge = 55, healthFactor = 0.15, description = "It was sudden and unexpected" },
	{ id = "stroke",         cause = "a stroke", minAge = 60, healthFactor = 0.12, description = "Despite quick medical attention" },
	{ id = "cancer",         cause = "cancer", minAge = 45, baseChance = 0.005, description = "After a brave battle" },
	{ id = "heart_disease",  cause = "heart disease", minAge = 50, healthFactor = 0.10, description = "Years of strain finally caught up" },
	{ id = "dementia",       cause = "complications from dementia", minAge = 70, baseChance = 0.008, description = "The mind faded before the body" },
	{ id = "pneumonia",      cause = "pneumonia", minAge = 65, healthFactor = 0.08, description = "A respiratory illness proved fatal" },
	
	-- ═════════════════════════════════════════════════════════════════════════
	-- LIFESTYLE-RELATED DEATHS (checked via flags)
	-- ═════════════════════════════════════════════════════════════════════════
	{ id = "substance_complications", cause = "complications from poor lifestyle choices", requiresFlag = "substance_issue", chance = 0.03, description = "Bad choices caught up with them" },
	{ id = "liver_failure", cause = "liver failure", requiresFlag = "heavy_drinker", minAge = 40, chance = 0.015, description = "Years of unhealthy habits took their toll" },
	{ id = "lung_disease", cause = "lung disease", requiresFlag = "smoker", minAge = 50, chance = 0.02, description = "Health issues proved fatal" },
	{ id = "obesity",        cause = "complications from obesity", requiresFlag = "obese", minAge = 35, chance = 0.01, description = "Weight issues led to health failure" },
	
	-- ═════════════════════════════════════════════════════════════════════════
	-- ACCIDENTAL DEATHS (rare but possible)
	-- ═════════════════════════════════════════════════════════════════════════
	{ id = "accident",       cause = "a tragic accident", baseChance = 0.0005, description = "An unfortunate turn of fate" },
	{ id = "car_accident",   cause = "a car accident", requiresFlag = "has_car", baseChance = 0.0008, description = "They were driving when it happened" },
	{ id = "drowning",       cause = "drowning", baseChance = 0.0002, description = "A day at the water turned tragic" },
	{ id = "fall",           cause = "injuries from a fall", minAge = 60, healthFactor = 0.05, description = "A simple fall proved fatal" },
	
	-- ═════════════════════════════════════════════════════════════════════════
	-- VIOLENCE/CRIME-RELATED (requires criminal lifestyle flags)
	-- ═════════════════════════════════════════════════════════════════════════
	{ id = "street_danger",  cause = "a dangerous situation", requiresFlag = "crew_member", chance = 0.05, description = "Street life caught up with them" },
	{ id = "prison_fight",   cause = "a prison altercation", requiresFlag = "in_prison", chance = 0.02, description = "Prison is a dangerous place" },
	-- CRITICAL FIX: Don't end players' lives with robbery_gone_wrong if they're IN prison
	-- Also requires they be free (not incarcerated) since robberies happen outside
	{ id = "robbery_gone_wrong", cause = "a robbery gone wrong", requiresFlag = "criminal_record", blockedByFlag = "in_prison", chance = 0.01, description = "Crime doesn't pay" },
	
	-- ═════════════════════════════════════════════════════════════════════════
	-- CAREER-RELATED DEATHS (for dangerous professions)
	-- ═════════════════════════════════════════════════════════════════════════
	{ id = "racing_crash",   cause = "a fatal racing crash", requiresFlag = "pro_racer", chance = 0.008, description = "The track claimed another driver" },
	{ id = "military_kia",   cause = "in combat", requiresFlag = "military_service", chance = 0.005, description = "They died serving their country" },
	
	-- ═════════════════════════════════════════════════════════════════════════
	-- MEDICAL/HEALTH-RELATED (requires prior health flags)
	-- ═════════════════════════════════════════════════════════════════════════
	{ id = "cancer_battle",  cause = "their battle with cancer", requiresFlag = "battling_cancer", chance = 0.15, description = "Cancer won in the end" },
	{ id = "surgery_complications", cause = "surgical complications", requiresFlag = "needs_surgery", chance = 0.03, description = "The operation didn't go as planned" },
	{ id = "traumatic_injury", cause = "injuries sustained", requiresFlag = "traumatic_injury", chance = 0.05, description = "They never fully recovered" },
}

function LifeStageSystem.checkDeath(state)
	local age = state.Age or 0
	local health = state.Health or state.Stats.Health or 50
	local flags = state.Flags or {}
	
	-- Health at 0 = immediate death
	if health <= 0 then
		return { died = true, cause = "Health failure" }
	end
	
	-- CRITICAL FIX: Don't do random death checks for young people (under 45)
	-- unless they have specific life-threatening conditions
	local hasLifeThreateningCondition = flags.battling_cancer or flags.traumatic_injury 
		or flags.substance_issue or flags.heavy_drinker
	
	if age < 45 and not hasLifeThreateningCondition then
		return { died = false }
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
		
		-- CRITICAL FIX: Blocked by flag (e.g., can't die from robbery if in prison)
		if deathType.blockedByFlag and flags[deathType.blockedByFlag] then
			canOccur = false
		end
		
		-- Calculate chance based on age and health
		if canOccur then
			-- Base age-related chance (increases gradually after 70, dramatically after 80)
			if age >= 80 then
				chance = chance + ((age - 80) / 100) * 0.25
			elseif age >= 70 then
				chance = chance + ((age - 70) / 100) * 0.08
			end
			
			-- Health factor (low health increases death chance, but scaled by age)
			-- Younger people are more resilient even with low health
			if deathType.healthFactor then
				if health < 25 then
					-- Scale health factor by age - older = more vulnerable
					local ageMultiplier = math.max(0.3, (age - 40) / 60) -- 0.3 at 40, 1.0 at 100
					chance = chance + deathType.healthFactor * (1 - health/25) * ageMultiplier
				end
			end
			
			-- Old age natural death - more gradual scaling
			if deathType.id == "old_age" then
				if age >= 85 then
					chance = chance + ((age - 85) / 100) * 0.3
				elseif age >= 75 then
					chance = chance + ((age - 75) / 100) * 0.1
				end
				if health < 40 and age >= 75 then
					chance = chance * 1.3
				end
			end
			
			-- Flag-based deaths (lifestyle choices have consequences)
			if deathType.chance and deathType.requiresFlag then
				-- Scale by how long they've had the condition (proxy: age)
				local baseChance = deathType.chance
				if age > 50 then
					chance = baseChance * (1 + (age - 50) / 100)
				else
					chance = baseChance * 0.5 -- Half chance when young
				end
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

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #466-469: ENHANCED STAGE TRANSITION HANDLING
-- ════════════════════════════════════════════════════════════════════════════

-- Process what happens during a stage transition
function LifeStageSystem.onStageTransition(state, fromStage, toStage)
	local results = {
		messages = {},
		statChanges = {},
		flagsSet = {},
	}
	
	state.Flags = state.Flags or {}
	
	-- Track stage history
	state.Flags["reached_" .. toStage.id] = true
	
	-- Set current stage flag
	state.Flags.current_life_stage = toStage.id
	
	-- Stage-specific transitions
	if toStage.id == "young_adult" then
		-- Becoming an adult - ensure graduation
		if not state.Education or state.Education == "none" then
			state.Education = "high_school"
		end
		state.Flags.is_adult = true
		state.Flags.graduated_high_school = true
		table.insert(results.messages, "You've graduated high school!")
		
	elseif toStage.id == "senior" then
		-- Auto-calculate pension if employed
		if state.CurrentJob and state.CurrentJob.salary then
			local pension = math.floor(state.CurrentJob.salary * 0.4)
			state.Flags.eligible_pension = pension
			table.insert(results.messages, string.format("You're eligible for a pension of $%d/year", pension))
		end
		state.Flags.retirement_eligible = true
		
	elseif toStage.id == "teen" then
		-- Can start part-time work
		state.Flags.can_work_part_time = true
		table.insert(results.messages, "You can now get a part-time job!")
	end
	
	-- Clear inappropriate flags
	if toStage.id ~= "baby" and toStage.id ~= "toddler" then
		state.Flags.needs_diaper = nil
		state.Flags.breastfed = nil
	end
	
	return results
end

-- Calculate expected life events for a given stage
function LifeStageSystem.getStageExpectations(stageId)
	local expectations = {
		baby = {
			canWork = false,
			canDate = false,
			canDrive = false,
			canVote = false,
			canDrink = false,
			inSchool = false,
			eventCategories = { "childhood", "family" },
		},
		toddler = {
			canWork = false,
			canDate = false,
			canDrive = false,
			canVote = false,
			canDrink = false,
			inSchool = false,
			eventCategories = { "childhood", "family" },
		},
		child = {
			canWork = false,
			canDate = false,
			canDrive = false,
			canVote = false,
			canDrink = false,
			inSchool = true,
			eventCategories = { "childhood", "school", "family", "hobbies" },
		},
		teen = {
			canWork = true, -- Part-time
			canDate = true,
			canDrive = true, -- At 16
			canVote = false,
			canDrink = false,
			inSchool = true,
			eventCategories = { "teen", "school", "relationships", "family", "hobbies" },
		},
		young_adult = {
			canWork = true,
			canDate = true,
			canDrive = true,
			canVote = true,
			canDrink = true, -- At 21
			inSchool = false, -- Unless in college
			eventCategories = { "career", "relationships", "financial", "family" },
		},
		adult = {
			canWork = true,
			canDate = true,
			canDrive = true,
			canVote = true,
			canDrink = true,
			inSchool = false,
			eventCategories = { "career", "relationships", "financial", "family", "health" },
		},
		middle_age = {
			canWork = true,
			canDate = true,
			canDrive = true,
			canVote = true,
			canDrink = true,
			inSchool = false,
			eventCategories = { "career", "health", "family", "financial" },
		},
		senior = {
			canWork = true, -- Can still work
			canDate = true,
			canDrive = true,
			canVote = true,
			canDrink = true,
			inSchool = false,
			canRetire = true,
			eventCategories = { "senior", "health", "family", "legacy" },
		},
	}
	
	return expectations[stageId] or expectations.adult
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #470-472: INHERITANCE AND LEGACY CALCULATION
-- ════════════════════════════════════════════════════════════════════════════

function LifeStageSystem.calculateInheritance(deceasedState)
	local inheritance = {
		money = 0,
		assets = {},
		totalValue = 0,
	}
	
	-- Cash inheritance (minus funeral costs)
	local funeralCost = 10000
	local estateValue = (deceasedState.Money or 0) - funeralCost
	
	-- Asset values
	local assetTotal = 0
	if deceasedState.Assets then
		if deceasedState.Assets.properties then
			for _, prop in ipairs(deceasedState.Assets.properties) do
				local value = prop.currentValue or prop.purchasePrice or 0
				assetTotal = assetTotal + value
				table.insert(inheritance.assets, {
					type = "property",
					name = prop.name or "Property",
					value = value,
				})
			end
		end
		if deceasedState.Assets.vehicles then
			for _, vehicle in ipairs(deceasedState.Assets.vehicles) do
				local value = vehicle.currentValue or 0
				assetTotal = assetTotal + value
				table.insert(inheritance.assets, {
					type = "vehicle",
					name = vehicle.name or "Vehicle",
					value = value,
				})
			end
		end
	end
	
	inheritance.money = math.max(0, estateValue)
	inheritance.assetValue = assetTotal
	inheritance.totalValue = inheritance.money + assetTotal
	
	return inheritance
end

function LifeStageSystem.calculateLegacyScore(state)
	local score = 0
	
	-- Age lived
	score = score + math.min(state.Age or 0, 100)
	
	-- Wealth accumulated
	local netWorth = (state.Money or 0) + ((state.NetWorth or 0))
	score = score + math.floor(netWorth / 100000) * 10
	
	-- Family
	if state.Relationships then
		for _, rel in pairs(state.Relationships) do
			if type(rel) == "table" then
				if rel.role == "Child" or rel.type == "child" then
					score = score + 20
				elseif rel.role == "Partner" then
					score = score + 15
				end
			end
		end
	end
	
	-- Achievements (flags)
	local flags = state.Flags or {}
	if flags.famous then score = score + 50 end
	if flags.millionaire then score = score + 30 end
	if flags.billionaire then score = score + 100 end
	if flags.was_monarch then score = score + 75 end
	if flags.mob_boss then score = score + 40 end
	if flags.phd then score = score + 25 end
	if flags.homeowner then score = score + 15 end
	
	return score
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #473-475: RETIREMENT INCOME PROCESSING
-- ════════════════════════════════════════════════════════════════════════════

function LifeStageSystem.processRetirementIncome(state)
	if not state.Flags then return 0 end
	if not state.Flags.retired then return 0 end
	
	local income = 0
	
	-- Pension
	if state.Flags.pension_amount then
		income = income + state.Flags.pension_amount
	end
	
	-- Social security (basic minimum for seniors)
	if state.Age and state.Age >= 65 then
		income = income + 15000 -- Base social security
	end
	
	-- Investment income (simplified)
	local savings = state.Money or 0
	local investmentReturn = math.floor(savings * 0.04) -- 4% withdrawal rate
	income = income + investmentReturn
	
	return income
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #476: COMPREHENSIVE EVENT VALIDATION
-- Enhanced validation with education and career checks
-- ════════════════════════════════════════════════════════════════════════════

function LifeStageSystem.validateEventComprehensive(event, state)
	-- First run basic validation
	if not LifeStageSystem.validateEvent(event, state) then
		return false, "Basic validation failed"
	end
	
	local conditions = event.conditions or {}
	
	-- Education requirements
	if conditions.requiresEducation then
		local playerEd = state.Education or "none"
		local requiredEd = conditions.requiresEducation
		
		local edLevels = { 
			none = 0, high_school = 1, associate = 2, 
			bachelor = 3, master = 4, law = 5, medical = 6, phd = 7 
		}
		
		if (edLevels[playerEd] or 0) < (edLevels[requiredEd] or 0) then
			return false, "Education requirement not met"
		end
	end
	
	-- Employment requirements
	if conditions.requiresEmployed and not (state.CurrentJob or (state.Flags and state.Flags.employed)) then
		return false, "Must be employed"
	end
	
	if conditions.requiresUnemployed and (state.CurrentJob or (state.Flags and state.Flags.employed)) then
		return false, "Must be unemployed"
	end
	
	-- Wealth requirements
	if conditions.minMoney and (state.Money or 0) < conditions.minMoney then
		return false, "Not enough money"
	end
	
	-- Premium feature requirements
	if conditions.requiresMob and not (state.MobState and state.MobState.inMob) then
		return false, "Must be in mafia"
	end
	
	if conditions.requiresRoyalty and not (state.RoyalState and state.RoyalState.isRoyal) then
		return false, "Must be royalty"
	end
	
	if conditions.requiresFame and not (state.FameState and state.FameState.careerPath) then
		return false, "Must be famous"
	end
	
	return true, nil
end

return LifeStageSystem
