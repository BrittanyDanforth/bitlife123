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

local function addCause(pool, id, label, weight, condition)
	if condition and weight > 0 then
		table.insert(pool, { id = id, label = label, weight = weight })
	end
end

local function pickDeathCause(state)
	local pool = {}
	local flags = state.Flags or {}
	local age = state.Age or 0
	local fame = state.Fame or 0
	local jobTrack = state.Career and state.Career.track

	addCause(pool, "natural", "Natural Causes", age >= 70 and 6 or 3, true)
	addCause(pool, "heart_attack", "Massive Heart Attack", 4, flags.heart_condition or state.Health <= 15)
	addCause(pool, "terminal_illness", "A Rare Illness", 3, flags.terminal_illness or flags.cancer)
	addCause(pool, "overdose", "Overdose at an Afterparty", 4, flags.drug_addict)
	addCause(pool, "street_crime", "A Late-Night Alley Ambush", 4, flags.crime_boss or flags.gang_member)
	addCause(pool, "prison_fight", "Prison Yard Fight", 3, flags.in_prison)
	addCause(pool, "heist_failure", "A Botched Heist", 3, flags.criminal_mastermind)
	addCause(pool, "motorsport_crash", "High-Speed Racing Crash", 3, jobTrack == "motorsport")
	addCause(pool, "tech_burnout", "Collapsed During a 48-hour Hackathon", 2, jobTrack == "tech")
	addCause(pool, "political_scandal", "Scandal-Induced Breakdown", 2, flags.political_path)
	addCause(pool, "paparazzi_chase", "Paparazzi Highway Pileup", 3, fame >= 70 or flags.famous)
	addCause(pool, "concert_stage", "Fell Off a Festival Stage", 3, fame >= 50 or flags.pop_star)
	addCause(pool, "jet_malfunction", "Private Jet Malfunction", 2, (state.Money or 0) >= 5_000_000)
	addCause(pool, "crypto_implosion", "Stress From a Crypto Implosion", 2, flags.crypto_tycoon)
	addCause(pool, "space_tourist", "Commercial Rocket Mishap", 1, flags.space_tourist)
	addCause(pool, "prison_escape", "Failed Prison Escape", 2, flags.fugitive or flags.escape_artist)
	addCause(pool, "underground_fight", "Underground Fight Gone Wrong", 2, flags.fight_club or flags.boxer)
	addCause(pool, "shark_selfie", "Shark Attack While Taking a Selfie", 1, flags.world_traveler)
	addCause(pool, "mountain_misstep", "Slipped During a Mountain Summit", 2, flags.adventurer)
	addCause(pool, "pet_ferret", "Bitten by a Rabid Ferret", 1, true)
	addCause(pool, "falling_piano", "Crushed by a Falling Piano", 1, true)
	addCause(pool, "meteor", "Struck by a Baby Meteor", 1, true)
	addCause(pool, "gamer_rage", "Slammed the Controller Too Hard", 1, fame >= 30)
	addCause(pool, "treadmill_disaster", "Launch off a Gym Treadmill", 1, flags.gym_rat or flags.fitness_buff)
	addCause(pool, "lottery_stampede", "Lottery Winner Press Stampede", 1, flags.lottery_winner)

	if #pool == 0 then
		addCause(pool, "natural", "Natural Causes", 1, true)
	end

	local total = 0
	for _, cause in ipairs(pool) do
		total += cause.weight
	end

	local roll = Random.new():NextNumber() * total
	for _, cause in ipairs(pool) do
		roll -= cause.weight
		if roll <= 0 then
			return cause
		end
	end
	return pool[#pool]
end

function LifeStageSystem.checkDeath(state)
	local age = state.Age or 0
	if state.Health <= 0 then
		return { died = true, cause = "Health Failure", fatal = true }
	end

	if age < 5 and (state.Health or 0) > 10 then
		-- Protect infants/toddlers from random death rolls unless health already zeroed
		return { died = false }
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
