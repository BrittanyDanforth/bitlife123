-- CombatSystem.lua
-- BitLife-style combat system with hit locations and attack types
-- Premium interactive fighting with choices, outcomes, and consequences

local CombatSystem = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HIT LOCATIONS - Where you can target your opponent
-- ═══════════════════════════════════════════════════════════════════════════════
CombatSystem.HitLocations = {
	{
		id = "head",
		name = "Head",
		emoji = "🧠",
		damage = { min = 15, max = 35 },
		accuracy = 55,
		critChance = 25,
		knockoutChance = 15,
		description = "High damage, risky to land"
	},
	{
		id = "face",
		name = "Face",
		emoji = "👊",
		damage = { min = 12, max = 28 },
		accuracy = 60,
		critChance = 20,
		knockoutChance = 12,
		description = "Can cause serious damage"
	},
	{
		id = "jaw",
		name = "Jaw",
		emoji = "😬",
		damage = { min = 18, max = 40 },
		accuracy = 50,
		critChance = 30,
		knockoutChance = 20,
		description = "Sweet spot for knockouts"
	},
	{
		id = "chin",
		name = "Chin",
		emoji = "🫢",
		damage = { min = 16, max = 35 },
		accuracy = 55,
		critChance = 28,
		knockoutChance = 18,
		description = "The button - lights out!"
	},
	{
		id = "body",
		name = "Body",
		emoji = "💪",
		damage = { min = 10, max = 22 },
		accuracy = 75,
		critChance = 10,
		knockoutChance = 3,
		description = "Reliable, wears them down"
	},
	{
		id = "ribs",
		name = "Ribs",
		emoji = "🦴",
		damage = { min = 12, max = 25 },
		accuracy = 70,
		critChance = 15,
		knockoutChance = 5,
		description = "Body shot to the ribs"
	},
	{
		id = "stomach",
		name = "Stomach",
		emoji = "😫",
		damage = { min = 8, max = 20 },
		accuracy = 80,
		critChance = 8,
		knockoutChance = 2,
		description = "Knocks the wind out"
	},
	{
		id = "legs",
		name = "Legs",
		emoji = "🦵",
		damage = { min = 6, max = 15 },
		accuracy = 85,
		critChance = 5,
		knockoutChance = 0,
		description = "Slows them down"
	},
	{
		id = "groin",
		name = "Groin",
		emoji = "😱",
		damage = { min = 20, max = 45 },
		accuracy = 45,
		critChance = 40,
		knockoutChance = 10,
		isDirty = true,
		description = "Dirty but effective"
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ATTACK TYPES - How you attack
-- ═══════════════════════════════════════════════════════════════════════════════
CombatSystem.AttackTypes = {
	{
		id = "punch",
		name = "Punch",
		emoji = "👊",
		damageMod = 1.0,
		accuracyMod = 1.0,
		speedMod = 1.0,
		description = "Standard punch"
	},
	{
		id = "jab",
		name = "Jab",
		emoji = "🥊",
		damageMod = 0.7,
		accuracyMod = 1.3,
		speedMod = 1.5,
		description = "Quick, high accuracy"
	},
	{
		id = "hook",
		name = "Hook",
		emoji = "🪝",
		damageMod = 1.3,
		accuracyMod = 0.85,
		speedMod = 0.8,
		description = "Powerful swing"
	},
	{
		id = "uppercut",
		name = "Uppercut",
		emoji = "⬆️",
		damageMod = 1.5,
		accuracyMod = 0.7,
		speedMod = 0.7,
		knockoutBonus = 15,
		description = "Rising power punch"
	},
	{
		id = "kick",
		name = "Kick",
		emoji = "🦶",
		damageMod = 1.2,
		accuracyMod = 0.9,
		speedMod = 0.85,
		description = "Powerful leg attack"
	},
	{
		id = "knee",
		name = "Knee Strike",
		emoji = "🦵",
		damageMod = 1.4,
		accuracyMod = 0.75,
		speedMod = 0.8,
		closeRange = true,
		description = "Devastating at close range"
	},
	{
		id = "elbow",
		name = "Elbow",
		emoji = "💪",
		damageMod = 1.35,
		accuracyMod = 0.8,
		speedMod = 0.9,
		cutChance = 30,
		description = "Sharp, can cut"
	},
	{
		id = "headbutt",
		name = "Headbutt",
		emoji = "🤕",
		damageMod = 1.6,
		accuracyMod = 0.6,
		speedMod = 0.7,
		isDirty = true,
		selfDamage = 10,
		description = "Dirty, hurts both"
	},
	{
		id = "bite",
		name = "Bite",
		emoji = "🦷",
		damageMod = 0.8,
		accuracyMod = 0.5,
		speedMod = 0.6,
		isDirty = true,
		infectionChance = 10,
		description = "Desperate and dirty"
	},
	{
		id = "push",
		name = "Push",
		emoji = "🤲",
		damageMod = 0.3,
		accuracyMod = 1.4,
		speedMod = 1.2,
		knockbackChance = 60,
		description = "Create distance"
	},
	{
		id = "grapple",
		name = "Grapple",
		emoji = "🤼",
		damageMod = 0.5,
		accuracyMod = 0.8,
		speedMod = 0.6,
		holdChance = 40,
		description = "Try to take them down"
	},
	{
		id = "dropkick",
		name = "Dropkick",
		emoji = "🦘",
		damageMod = 2.0,
		accuracyMod = 0.4,
		speedMod = 0.5,
		knockbackChance = 80,
		selfFallChance = 60,
		description = "High risk, high reward"
	},
	{
		id = "haymaker",
		name = "Haymaker",
		emoji = "💥",
		damageMod = 2.0,
		accuracyMod = 0.5,
		speedMod = 0.4,
		knockoutBonus = 25,
		description = "Big swing for the fences"
	},
	{
		id = "slap",
		name = "Slap",
		emoji = "🖐️",
		damageMod = 0.4,
		accuracyMod = 1.5,
		speedMod = 1.4,
		humiliationDamage = true,
		description = "More humiliating than painful"
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- DEFENSIVE ACTIONS
-- ═══════════════════════════════════════════════════════════════════════════════
CombatSystem.DefenseActions = {
	{
		id = "block",
		name = "Block",
		emoji = "🛡️",
		damageReduction = 0.6,
		successChance = 75,
		description = "Reduce incoming damage"
	},
	{
		id = "dodge",
		name = "Dodge",
		emoji = "💨",
		damageReduction = 1.0,  -- Complete avoidance if successful
		successChance = 50,
		counterOpportunity = true,
		description = "Try to avoid the attack"
	},
	{
		id = "parry",
		name = "Parry",
		emoji = "🤺",
		damageReduction = 0.9,
		successChance = 40,
		counterOpportunity = true,
		counterDamageBonus = 0.5,
		description = "Deflect and counter"
	},
	{
		id = "clinch",
		name = "Clinch",
		emoji = "🤗",
		damageReduction = 0.5,
		successChance = 60,
		slowsOpponent = true,
		description = "Hold them close"
	},
	{
		id = "run",
		name = "Run Away",
		emoji = "🏃",
		escapeChance = 70,
		cowardice = true,
		description = "Try to escape"
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIGHT CONTEXTS - Different scenarios
-- ═══════════════════════════════════════════════════════════════════════════════
CombatSystem.FightContexts = {
	{
		id = "street_random",
		title = "Street Confrontation",
		emoji = "🌆",
		descriptions = {
			"A stranger bumped into you and wants to fight!",
			"Someone doesn't like the way you looked at them.",
			"Road rage escalated into a physical confrontation.",
			"A drunk person is looking for trouble.",
		}
	},
	{
		id = "school_bully",
		title = "School Fight",
		emoji = "🏫",
		descriptions = {
			"The school bully wants to teach you a lesson.",
			"A classmate challenged you to fight after school.",
			"Someone said something about your family.",
		}
	},
	{
		-- CRITICAL FIX: Changed from "bar" to "club" for Roblox TOS compliance
		id = "club_fight",
		title = "Club Brawl",
		emoji = "🎉",
		descriptions = {
			"Things got heated at the club.",
			"Someone bumped into you on the dance floor and won't apologize.",
			"You caught someone hitting on your date at the club.",
		}
	},
	{
		id = "defense",
		title = "Self Defense",
		emoji = "⚠️",
		descriptions = {
			"Someone is attacking you! Defend yourself!",
			"A mugger wants your wallet.",
			"You're being jumped!",
		}
	},
	{
		id = "revenge",
		title = "Payback Time",
		emoji = "😤",
		descriptions = {
			"You finally confronted the person who wronged you.",
			"Time to settle an old score.",
			"This has been a long time coming.",
		}
	},
	{
		id = "prison",
		title = "Prison Yard Fight",
		emoji = "⛓️",
		descriptions = {
			"Another inmate is testing you.",
			"Someone wants your commissary.",
			"Gang rivalry erupted into violence.",
		}
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- OPPONENT TYPES - Different kinds of opponents
-- ═══════════════════════════════════════════════════════════════════════════════
CombatSystem.OpponentTypes = {
	{
		id = "weak",
		name = "Weak Opponent",
		healthMod = 0.6,
		damageMod = 0.5,
		defenseMod = 0.4,
		aggressiveness = 30,
		descriptions = { "a scrawny person", "someone half your size", "a clearly intoxicated person" }
	},
	{
		id = "average",
		name = "Average Opponent",
		healthMod = 1.0,
		damageMod = 1.0,
		defenseMod = 1.0,
		aggressiveness = 50,
		descriptions = { "someone your size", "an ordinary person", "a regular looking individual" }
	},
	{
		id = "strong",
		name = "Strong Opponent",
		healthMod = 1.3,
		damageMod = 1.4,
		defenseMod = 1.2,
		aggressiveness = 70,
		descriptions = { "a muscular person", "someone clearly trained", "a big intimidating person" }
	},
	{
		id = "trained",
		name = "Trained Fighter",
		healthMod = 1.5,
		damageMod = 1.6,
		defenseMod = 1.8,
		aggressiveness = 80,
		counterChance = 30,
		descriptions = { "someone with fighting experience", "a trained martial artist", "an ex-boxer" }
	},
	{
		id = "armed",
		name = "Armed Opponent",
		healthMod = 1.0,
		damageMod = 2.5,
		defenseMod = 0.8,
		aggressiveness = 90,
		hasWeapon = true,
		descriptions = { "someone with a knife", "a person brandishing a weapon", "an armed attacker" }
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIGHT OUTCOME CONSEQUENCES
-- ═══════════════════════════════════════════════════════════════════════════════
CombatSystem.Outcomes = {
	win = {
		knockout = {
			title = "KNOCKOUT VICTORY!",
			emoji = "🏆",
			happiness = { 5, 15 },
			health = { -5, -15 },
			respect = { 5, 20 },
			texts = {
				"You knocked them out cold! They hit the ground hard.",
				"One perfect shot and it was lights out for them.",
				"They're unconscious before they even knew what happened.",
			}
		},
		decision = {
			title = "You Won the Fight!",
			emoji = "✊",
			happiness = { 3, 10 },
			health = { -10, -25 },
			respect = { 2, 10 },
			texts = {
				"After a tough battle, you emerged victorious.",
				"They finally gave up and walked away.",
				"You beat them down until they couldn't continue.",
			}
		},
		surrender = {
			title = "They Surrendered!",
			emoji = "🏳️",
			happiness = { 5, 12 },
			health = { -2, -8 },
			respect = { 3, 12 },
			texts = {
				"They begged you to stop and surrendered.",
				"They realized they couldn't win and gave up.",
				"They ran away before taking more damage.",
			}
		},
	},
	lose = {
		knockout = {
			title = "You Got KNOCKED OUT!",
			emoji = "💫",
			happiness = { -15, -25 },
			health = { -30, -50 },
			respect = { -5, -15 },
			texts = {
				"Everything went black. You wake up on the ground.",
				"You don't remember what happened after that hit.",
				"One moment you were fighting, the next you were staring at the sky.",
			}
		},
		beaten = {
			title = "You Lost the Fight",
			emoji = "😵",
			happiness = { -10, -20 },
			health = { -20, -40 },
			respect = { -3, -10 },
			texts = {
				"They beat you badly. You're covered in bruises.",
				"You couldn't take any more and had to give up.",
				"They were just too strong. You're lucky it's over.",
			}
		},
	},
	draw = {
		title = "Fight Ended in a Draw",
		emoji = "🤝",
		happiness = { -2, 2 },
		health = { -15, -25 },
		respect = { 0, 5 },
		texts = {
			"You both fought to a standstill. Neither could continue.",
			"Someone broke up the fight before there was a winner.",
			"The cops showed up and you both scattered.",
		}
	},
	escaped = {
		title = "You Got Away!",
		emoji = "🏃",
		happiness = { -5, 5 },
		health = { 0, -5 },
		respect = { -2, -5 },
		coward = true,
		texts = {
			"You managed to escape before things got worse.",
			"You ran and didn't look back.",
			"Living to fight another day is a valid strategy.",
		}
	},
	arrested = {
		title = "Arrested!",
		emoji = "🚔",
		happiness = { -20, -30 },
		legal = true,
		texts = {
			"The cops showed up and arrested you for fighting!",
			"Someone called the police. You're going to jail.",
			"You're being charged with assault.",
		}
	},
	hospitalized = {
		title = "Hospitalized",
		emoji = "🏥",
		happiness = { -25, -40 },
		health = { -40, -60 },
		moneyLoss = { 500, 5000 },
		texts = {
			"You're badly hurt and need emergency medical care.",
			"The ambulance had to take you to the hospital.",
			"You wake up in a hospital bed.",
		}
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMBAT CALCULATION FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

function CombatSystem.calculateDamage(attackType, hitLocation, attackerStats)
	local attack = nil
	local location = nil
	
	-- Find attack type
	for _, a in ipairs(CombatSystem.AttackTypes) do
		if a.id == attackType then
			attack = a
			break
		end
	end
	
	-- Find hit location
	for _, l in ipairs(CombatSystem.HitLocations) do
		if l.id == hitLocation then
			location = l
			break
		end
	end
	
	if not attack or not location then
		return { damage = 10, hit = true, critical = false, knockout = false }
	end
	
	-- Calculate accuracy
	local accuracy = location.accuracy * (attack.accuracyMod or 1.0)
	if attackerStats and attackerStats.Health then
		accuracy = accuracy * (0.7 + (attackerStats.Health / 100) * 0.3)
	end
	
	-- Did we hit?
	local hitRoll = math.random(100)
	local hit = hitRoll <= accuracy
	
	if not hit then
		return { damage = 0, hit = false, critical = false, knockout = false, miss = true }
	end
	
	-- Calculate base damage
	local baseDamage = math.random(location.damage.min, location.damage.max)
	local damage = baseDamage * (attack.damageMod or 1.0)
	
	-- Apply attacker stat bonuses
	if attackerStats then
		if attackerStats.Health then
			damage = damage * (0.8 + (attackerStats.Health / 100) * 0.4)
		end
		if attackerStats.Looks then  -- Looks = physical fitness in this context
			damage = damage * (0.9 + (attackerStats.Looks / 100) * 0.2)
		end
	end
	
	-- Critical hit check
	local critChance = location.critChance + (attack.knockoutBonus or 0)
	local critical = math.random(100) <= critChance
	if critical then
		damage = damage * 1.5
	end
	
	-- Knockout check
	local koChance = location.knockoutChance + (attack.knockoutBonus or 0)
	if critical then koChance = koChance * 1.5 end
	local knockout = math.random(100) <= koChance
	
	return {
		damage = math.floor(damage),
		hit = true,
		critical = critical,
		knockout = knockout,
		cutChance = attack.cutChance,
		selfDamage = attack.selfDamage,
		isDirty = attack.isDirty or location.isDirty,
	}
end

function CombatSystem.getRandomContext()
	return CombatSystem.FightContexts[math.random(#CombatSystem.FightContexts)]
end

function CombatSystem.getRandomOpponent(difficulty)
	difficulty = difficulty or "average"
	local filtered = {}
	
	for _, opp in ipairs(CombatSystem.OpponentTypes) do
		if opp.id == difficulty then
			return opp
		end
		table.insert(filtered, opp)
	end
	
	return filtered[math.random(#filtered)]
end

function CombatSystem.generateFightEvent(context, opponent, state)
	local contextData = context
	if type(context) == "string" then
		for _, c in ipairs(CombatSystem.FightContexts) do
			if c.id == context then
				contextData = c
				break
			end
		end
	end
	
	local opponentData = opponent
	if type(opponent) == "string" then
		for _, o in ipairs(CombatSystem.OpponentTypes) do
			if o.id == opponent then
				opponentData = o
				break
			end
		end
	end
	
	-- Generate event with choices for hit locations and attack types
	local hitLocationChoices = {}
	for i, loc in ipairs(CombatSystem.HitLocations) do
		if i <= 6 then  -- Limit to 6 locations for UI
			table.insert(hitLocationChoices, {
				text = loc.emoji .. " Target " .. loc.name,
				subtext = loc.description,
				locationId = loc.id,
			})
		end
	end
	
	-- Add defensive options
	table.insert(hitLocationChoices, {
		text = "🛡️ Defend / Block",
		subtext = "Reduce incoming damage",
		isDefense = true,
		defenseId = "block",
	})
	table.insert(hitLocationChoices, {
		text = "🏃 Run Away",
		subtext = "Try to escape the fight",
		isDefense = true,
		defenseId = "run",
	})
	
	local event = {
		id = "combat_" .. contextData.id .. "_" .. math.random(10000),
		title = contextData.emoji .. " " .. contextData.title,
		emoji = contextData.emoji,
		text = contextData.descriptions[math.random(#contextData.descriptions)] ..
			"\n\nYou're facing " .. opponentData.descriptions[math.random(#opponentData.descriptions)] .. ".",
		question = "Where do you attack?",
		category = "combat",
		isCombat = true,
		combatData = {
			context = contextData,
			opponent = opponentData,
			round = 1,
			playerHealth = 100,
			opponentHealth = math.floor(100 * opponentData.healthMod),
		},
		choices = hitLocationChoices,
	}
	
	return event
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMBAT ROUND PROCESSING
-- ═══════════════════════════════════════════════════════════════════════════════

function CombatSystem.processRound(combatData, playerChoice, playerStats)
	local result = {
		playerAction = nil,
		opponentAction = nil,
		playerDamageDealt = 0,
		playerDamageReceived = 0,
		combatEnded = false,
		outcome = nil,
		narrative = "",
	}
	
	-- Handle defense/escape
	if playerChoice.isDefense then
		if playerChoice.defenseId == "run" then
			local escapeChance = 70
			if combatData.opponent.aggressiveness then
				escapeChance = escapeChance - (combatData.opponent.aggressiveness / 2)
			end
			
			if math.random(100) <= escapeChance then
				result.combatEnded = true
				result.outcome = CombatSystem.Outcomes.escaped
				result.narrative = "You managed to escape the fight!"
				return result
			else
				result.narrative = "You tried to run but they caught you! "
			end
		elseif playerChoice.defenseId == "block" then
			result.playerAction = "defended"
		end
	else
		-- Player attacks
		local attackType = playerChoice.attackId or "punch"
		local hitLocation = playerChoice.locationId or "body"
		
		local attackResult = CombatSystem.calculateDamage(attackType, hitLocation, playerStats)
		result.playerAction = attackResult
		
		if attackResult.hit then
			result.playerDamageDealt = attackResult.damage
			combatData.opponentHealth = combatData.opponentHealth - attackResult.damage
			
			-- Build narrative
			local hitLoc = nil
			for _, l in ipairs(CombatSystem.HitLocations) do
				if l.id == hitLocation then hitLoc = l break end
			end
			
			if attackResult.critical then
				result.narrative = "CRITICAL HIT! You landed a devastating " .. attackType .. " to their " .. (hitLoc and hitLoc.name or hitLocation) .. "! "
			else
				result.narrative = "You connected with a " .. attackType .. " to their " .. (hitLoc and hitLoc.name or hitLocation) .. ". "
			end
			
			-- Check for knockout
			if attackResult.knockout or combatData.opponentHealth <= 0 then
				result.combatEnded = true
				result.outcome = CombatSystem.Outcomes.win.knockout
				result.narrative = result.narrative .. "They're down and not getting up!"
				return result
			end
		else
			result.narrative = "You swung but missed! "
		end
	end
	
	-- Opponent attacks back (if fight continues)
	if not result.combatEnded then
		local oppAttack = CombatSystem.AttackTypes[math.random(#CombatSystem.AttackTypes)]
		local oppLocation = CombatSystem.HitLocations[math.random(#CombatSystem.HitLocations)]
		
		local oppResult = CombatSystem.calculateDamage(oppAttack.id, oppLocation.id, {
			Health = 100 * combatData.opponent.damageMod,
			Looks = 50,
		})
		result.opponentAction = oppResult
		
		-- Apply defense bonus if player was defending
		if result.playerAction == "defended" then
			oppResult.damage = math.floor(oppResult.damage * 0.4)
			result.narrative = result.narrative .. "Your block absorbed most of the damage. "
		end
		
		if oppResult.hit then
			result.playerDamageReceived = oppResult.damage
			combatData.playerHealth = combatData.playerHealth - oppResult.damage
			
			if oppResult.critical then
				result.narrative = result.narrative .. "They land a brutal " .. oppAttack.name .. " to your " .. oppLocation.name .. "!"
			else
				result.narrative = result.narrative .. "They hit you with a " .. oppAttack.name .. " to the " .. oppLocation.name .. "."
			end
			
			-- Check if player is knocked out
			if oppResult.knockout or combatData.playerHealth <= 0 then
				result.combatEnded = true
				result.outcome = CombatSystem.Outcomes.lose.knockout
				return result
			end
		else
			result.narrative = result.narrative .. "They swung and missed!"
		end
	end
	
	-- Check for drawn out fight
	combatData.round = combatData.round + 1
	if combatData.round > 10 then
		-- Random chance of intervention
		if math.random(100) <= 30 then
			result.combatEnded = true
			result.outcome = CombatSystem.Outcomes.draw
			return result
		end
	end
	
	-- Update health status in narrative
	result.narrative = result.narrative .. "\n\n"
	if combatData.playerHealth > 70 then
		result.narrative = result.narrative .. "You're holding up well."
	elseif combatData.playerHealth > 40 then
		result.narrative = result.narrative .. "You're starting to feel the damage."
	else
		result.narrative = result.narrative .. "You're badly hurt!"
	end
	
	if combatData.opponentHealth > 70 then
		result.narrative = result.narrative .. " They look unfazed."
	elseif combatData.opponentHealth > 40 then
		result.narrative = result.narrative .. " They're showing damage."
	else
		result.narrative = result.narrative .. " They're on their last legs!"
	end
	
	return result
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIGHT OUTCOME APPLICATION
-- ═══════════════════════════════════════════════════════════════════════════════

function CombatSystem.applyOutcome(state, outcome)
	if not outcome or not state then return end
	
	-- Apply happiness change
	if outcome.happiness then
		local happinessChange = math.random(outcome.happiness[1], outcome.happiness[2])
		state.Happiness = math.clamp((state.Happiness or 50) + happinessChange, 0, 100)
	end
	
	-- Apply health change
	if outcome.health then
		local healthChange = math.random(outcome.health[1], outcome.health[2])
		state.Health = math.clamp((state.Health or 100) + healthChange, 0, 100)
	end
	
	-- Apply respect/fame change (if exists)
	if outcome.respect and state.Fame ~= nil then
		local respChange = math.random(outcome.respect[1], outcome.respect[2])
		state.Fame = math.clamp((state.Fame or 0) + respChange, 0, 100)
	end
	
	-- Handle legal consequences
	if outcome.legal then
		state.Flags = state.Flags or {}
		state.Flags.pending_assault_charge = true
	end
	
	-- Handle money loss (hospital bills, etc)
	if outcome.moneyLoss then
		local loss = math.random(outcome.moneyLoss[1], outcome.moneyLoss[2])
		state.Money = math.max(0, (state.Money or 0) - loss)
	end
	
	return state
end

return CombatSystem
