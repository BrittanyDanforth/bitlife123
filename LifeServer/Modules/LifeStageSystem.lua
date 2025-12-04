local LifeStageSystem = {}

LifeStageSystem.Stages = {
	INFANT = { id = "infant", minAge = 0, maxAge = 2, emoji = "👶", description = "Discovering the world" },
	TODDLER = { id = "toddler", minAge = 3, maxAge = 5, emoji = "🚼", description = "Learning basics" },
	CHILD = { id = "child", minAge = 6, maxAge = 11, emoji = "🧒", description = "Elementary school years" },
	TWEEN = { id = "tween", minAge = 12, maxAge = 13, emoji = "🧑‍🦱", description = "Early adolescence" },
	TEEN = { id = "teen", minAge = 14, maxAge = 17, emoji = "🧑‍🎓", description = "High school drama" },
	YOUNG_ADULT = { id = "young_adult", minAge = 18, maxAge = 24, emoji = "🧑‍💼", description = "College & first jobs" },
	ADULT = { id = "adult", minAge = 25, maxAge = 39, emoji = "🧑", description = "Career-building" },
	MIDDLE_AGE = { id = "middle_age", minAge = 40, maxAge = 59, emoji = "🧑‍🦳", description = "Family & leadership" },
	SENIOR = { id = "senior", minAge = 60, maxAge = 74, emoji = "👨‍🦳", description = "Retirement dreams" },
	ELDER = { id = "elder", minAge = 75, maxAge = 120, emoji = "👴", description = "Golden years" },
}

LifeStageSystem.StageOrder = {
	LifeStageSystem.Stages.INFANT,
	LifeStageSystem.Stages.TODDLER,
	LifeStageSystem.Stages.CHILD,
	LifeStageSystem.Stages.TWEEN,
	LifeStageSystem.Stages.TEEN,
	LifeStageSystem.Stages.YOUNG_ADULT,
	LifeStageSystem.Stages.ADULT,
	LifeStageSystem.Stages.MIDDLE_AGE,
	LifeStageSystem.Stages.SENIOR,
	LifeStageSystem.Stages.ELDER,
}


LifeStageSystem.EventCategories = {
	family = {},
	health = {},
	school = { minAge = 5, maxAge = 25 },
	social = { minAge = 6 },
	romance = { minAge = 14 },
	work = { minAge = 14 },
	money = { minAge = 13 },
	prison = { requiresFlag = "in_prison" },
	crime = { minAge = 13 },
	political = { minAge = 25 },
	racing = { minAge = 16 },
	art = { minAge = 12 },
	hacking = { minAge = 12 },
	death = { minAge = 0 },
}

local function getStageByAge(age)
	for _, stage in ipairs(LifeStageSystem.StageOrder) do
		if age >= stage.minAge and age <= stage.maxAge then
			return stage
		end
	end
	return LifeStageSystem.StageOrder[#LifeStageSystem.StageOrder]
end

function LifeStageSystem.getStage(age)
	return getStageByAge(age or 0)
end

function LifeStageSystem.getCapabilities(state)
	local age = state.Age or 0
	local stage = getStageByAge(age)
	local flags = state.Flags or {}

	local caps = {
		stage = stage.id,
		canTalk = age >= 2,
		canWalk = age >= 2,
		canAttendSchool = age >= 5 and age < 18 and not flags.dropped_out,
		canDrive = age >= 16 and not flags.in_prison,
		canWorkPartTime = age >= 14 and not flags.in_prison,
		canWorkFullTime = age >= 18 and not flags.in_prison,
		canDate = age >= 16 and not flags.in_prison,
		canMarry = age >= 18 and not flags.in_prison,
		canDrink = age >= 21 and not flags.in_prison,
		canGamble = age >= 21 and not flags.in_prison,
		canDoCrime = age >= 12,
		canVote = age >= 18,
		canRetire = age >= 60,
		canRunForOffice = age >= 25 and not flags.in_prison,
		inSchool = false,
	}

	caps.inSchool = caps.canAttendSchool or flags.college_student
	return caps
end

local function checkFlagRequirement(requirement, state)
	if not requirement then
		return true
	end
	return state.Flags and state.Flags[requirement] == true
end

function LifeStageSystem.isCategoryAllowed(category, state)
	local config = LifeStageSystem.EventCategories[category]
	if not config then
		return true
	end

	local age = state.Age or 0
	if config.minAge and age < config.minAge then
		return false
	end
	if config.maxAge and age > config.maxAge then
		return false
	end
	if config.requiresFlag and not checkFlagRequirement(config.requiresFlag, state) then
		return false
	end
	return true
end

local function checkStatRequirements(requirements, state)
	if not requirements then
		return true
	end
	for stat, value in pairs(requirements) do
		if (state.Stats and state.Stats[stat] or 0) < value then
		 return false
		end
	end
	return true
end

function LifeStageSystem.validateEvent(eventDef, state)
	if not eventDef then
		return false
	end

	local age = state.Age or 0
	local conditions = eventDef.conditions or {}

	local minAge = conditions.minAge or eventDef.minAge
	local maxAge = conditions.maxAge or eventDef.maxAge
	if minAge and age < minAge then
		return false
	end
	if maxAge and age > maxAge then
		return false
	end

	if eventDef.category and not LifeStageSystem.isCategoryAllowed(eventDef.category, state) then
		return false
	end

	if conditions.minStats and not checkStatRequirements(conditions.minStats, state) then
		return false
	end

	if conditions.minMoney and state.Money < conditions.minMoney then
		return false
	end

	if conditions.requiredFlags then
		for _, flag in ipairs(conditions.requiredFlags) do
			if not state.Flags[flag] then
				return false
			end
		end
	end

	if conditions.blockedFlags then
		for _, flag in ipairs(conditions.blockedFlags) do
			if state.Flags[flag] then
				return false
			end
		end
	end

	if conditions.custom and type(conditions.custom) == "function" then
		local success, result = pcall(conditions.custom, state)
		if not success or not result then
			return false
		end
	end

	return true
end

local StageTransitionEvents = {
	[LifeStageSystem.Stages.CHILD.id] = {
		title = "Back to School",
		emoji = "📚",
		text = "You're officially in grade school. Time to learn multiplication tables!",
		category = "milestone",
	},
	[LifeStageSystem.Stages.TEEN.id] = {
		title = "High School Era",
		emoji = "🎓",
		text = "Teenage years begin—friends, drama, and exams await.",
		category = "milestone",
	},
	[LifeStageSystem.Stages.YOUNG_ADULT.id] = {
		title = "Adulthood Unlocked",
		emoji = "🧑‍💼",
		text = "You can vote, move out, and start working full-time.",
		category = "milestone",
	},
	[LifeStageSystem.Stages.MIDDLE_AGE.id] = {
		title = "Midlife Momentum",
		emoji = "🧑‍🦳",
		text = "Careers peak and families grow. How are your goals going?",
		category = "milestone",
	},
	[LifeStageSystem.Stages.SENIOR.id] = {
		title = "Golden Chapter",
		emoji = "👵",
		text = "Retirement planning becomes real. Take care of your health!",
		category = "milestone",
	},
}

function LifeStageSystem.getTransitionEvent(oldAge, newAge)
	local oldStage = getStageByAge(oldAge or 0)
	local newStage = getStageByAge(newAge or 0)
	if oldStage.id == newStage.id then
		return nil
	end

	local template = StageTransitionEvents[newStage.id]
	if not template then
		return nil
	end

	return {
		id = "stage_transition_" .. newStage.id,
		emoji = template.emoji,
		title = template.title,
		text = template.text,
		category = template.category,
		milestone = true,
		choices = {
			{ index = 1, text = "Embrace it", effects = { Happiness = 2 } },
		},
	}
end

local function baseDeathChance(age)
	if age < 50 then
		return 0.001
	elseif age < 65 then
		return 0.01
	elseif age < 80 then
		return 0.05
	elseif age < 90 then
		return 0.15
	else
		return 0.3
	end
end

function LifeStageSystem.calculateDeathChance(state)
	if state.Health <= 0 then
		return 1
	end

	local chance = baseDeathChance(state.Age or 0)
	chance += (100 - (state.Health or 50)) * 0.002

	if state.Flags.terminal_illness then
		chance += 0.15
	end
	if state.Flags.heart_condition then
		chance += 0.05
	end
	if state.Flags.drug_addict then
		chance += 0.04
	end
	if state.Flags.healthy_lifestyle then
		chance -= 0.02
	end

	return math.clamp(chance, 0, 1)
end

local DeathCauses = {
	{ id = "natural_causes", label = "Natural Causes", weight = 5 },
	{ id = "heart_attack", label = "Heart Attack", weight = 3, flag = "heart_condition" },
	{ id = "accident", label = "Accident", weight = 2 },
	{ id = "illness", label = "Illness", weight = 3, flag = "terminal_illness" },
	{ id = "overdose", label = "Overdose", weight = 2, flag = "drug_addict" },
}

local function pickDeathCause(state)
	local bucket = {}
	for _, cause in ipairs(DeathCauses) do
		if not cause.flag or state.Flags[cause.flag] then
			table.insert(bucket, cause)
		end
	end
	if #bucket == 0 then
		return DeathCauses[1]
	end

	local total = 0
	for _, cause in ipairs(bucket) do
		total += cause.weight
	end

	local roll = Random.new():NextNumber() * total
	for _, cause in ipairs(bucket) do
		roll -= cause.weight
		if roll <= 0 then
			return cause
		end
	end
	return bucket[#bucket]
end

function LifeStageSystem.checkDeath(state)
	if state.Health <= 0 then
		return { died = true, cause = "Health Failure", fatal = true }
	end

	local chance = LifeStageSystem.calculateDeathChance(state)
	if Random.new():NextNumber() <= chance then
		local cause = pickDeathCause(state)
		return {
			died = true,
			cause = cause.label,
			id = cause.id,
			year = state.Year,
		}
	end
	return { died = false }
end

return LifeStageSystem
