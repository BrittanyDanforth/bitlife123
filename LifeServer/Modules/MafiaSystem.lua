--[[
	MafiaSystem.lua (Renamed from MafiaSystem.lua)
	
	Organized crime/Mafia system for BitLife-style game.
	Allows players to join crime families and rise through the ranks.
	
	REQUIRES: Mafia gamepass (ID: 1626238769)
	
	CRITICAL FIX #101: Renamed from MafiaSystem to MafiaSystem for clarity
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MafiaSystem = {}
MafiaSystem.__index = MafiaSystem

-- ════════════════════════════════════════════════════════════════════════════
-- CRIME FAMILY DEFINITIONS
-- ════════════════════════════════════════════════════════════════════════════

MafiaSystem.Families = {
	italian = {
		id = "italian",
		name = "Italian Mafia",
		fullName = "La Cosa Nostra",
		emoji = "🇮🇹",
		description = "The traditional organized crime family. Honor, loyalty, and family above all.",
		color = Color3.fromRGB(239, 68, 68),
		colorDark = Color3.fromRGB(185, 28, 28),
		ranks = {
			{ id = "associate", name = "Associate", level = 1, respect = 0, emoji = "👤" },
			{ id = "soldier", name = "Soldier", level = 2, respect = 100, emoji = "🔫" },
			{ id = "capo", name = "Caporegime", level = 3, respect = 500, emoji = "💰" },
			{ id = "underboss", name = "Underboss", level = 4, respect = 2000, emoji = "🎩" },
			{ id = "boss", name = "Boss", level = 5, respect = 10000, emoji = "👑" },
		},
		operations = {
			{ id = "protection", name = "Protection Racket", emoji = "🛡️", risk = 20, reward = { min = 500, max = 2000 }, respect = 5, description = "Collect envelopes from local businesses.", rankRequired = 1, category = "income" },
			{ id = "numbers", name = "Numbers Game", emoji = "🎲", risk = 25, reward = { min = 1200, max = 4000 }, respect = 8, description = "Rig a neighborhood lottery.", rankRequired = 1, category = "income" },
			{ id = "gambling", name = "Run Gambling Ring", emoji = "🎰", risk = 30, reward = { min = 1000, max = 5000 }, respect = 10, description = "Operate an underground casino night.", rankRequired = 2, category = "income" },
			{ id = "loan_shark", name = "Shylock Loans", emoji = "💵", risk = 35, reward = { min = 3000, max = 12000 }, respect = 18, description = "Collect interest from desperate borrowers.", rankRequired = 2, category = "finance" },
			{ id = "smuggling", name = "Smuggle Goods", emoji = "📦", risk = 40, reward = { min = 2000, max = 10000 }, respect = 20, description = "Sneak contraband through the docks.", rankRequired = 3, category = "logistics" },
			{ id = "heist", name = "Plan a Heist", emoji = "🏦", risk = 60, reward = { min = 10000, max = 100000 }, respect = 50, description = "Coordinate a high-stakes robbery.", rankRequired = 4, category = "score" },
			{ id = "silencer", name = "Silence a Witness", emoji = "🎯", risk = 80, reward = { min = 5000, max = 25000 }, respect = 100, description = "Make sure someone can't testify.", rankRequired = 5, category = "enforcement" },
		},
		initiation = "You must prove your loyalty by completing a task for the family.",
	},
	
	russian = {
		id = "russian",
		name = "Russian Bratva",
		fullName = "Bratva (The Brotherhood)",
		emoji = "🇷🇺",
		description = "The ruthless eastern European syndicate. Strength and fear are your weapons.",
		color = Color3.fromRGB(59, 130, 246),
		colorDark = Color3.fromRGB(29, 78, 216),
		ranks = {
			{ id = "shestyorka", name = "Shestyorka", level = 1, respect = 0, emoji = "👤" },
			{ id = "bratok", name = "Bratok", level = 2, respect = 100, emoji = "🔫" },
			{ id = "brigadier", name = "Brigadier", level = 3, respect = 500, emoji = "💰" },
			{ id = "avtoritet", name = "Avtoritet", level = 4, respect = 2000, emoji = "🎩" },
			{ id = "pakhan", name = "Pakhan", level = 5, respect = 10000, emoji = "👑" },
		},
		operations = {
			{ id = "intimidation", name = "Street Intimidation", emoji = "🤐", risk = 25, reward = { min = 800, max = 3000 }, respect = 8, description = "Shake down kiosks for protection cash.", rankRequired = 1, category = "income" },
			{ id = "black_market", name = "Black Market Deal", emoji = "🛰️", risk = 35, reward = { min = 2000, max = 9000 }, respect = 15, description = "Move counterfeit goods through the ports.", rankRequired = 1, category = "logistics" },
			{ id = "cyber", name = "Cyber Crime", emoji = "💻", risk = 30, reward = { min = 2000, max = 20000 }, respect = 15, description = "Deploy a ransomware payload.", rankRequired = 2, category = "tech" },
			{ id = "weapons", name = "Arms Dealing", emoji = "🔫", risk = 45, reward = { min = 3000, max = 15000 }, respect = 25, description = "Broker a weapons shipment.", rankRequired = 3, category = "logistics" },
			{ id = "ransom", name = "High-Value Ransom", emoji = "💼", risk = 70, reward = { min = 15000, max = 75000 }, respect = 60, description = "Grab a VIP and negotiate ransom.", rankRequired = 4, category = "score" },
			{ id = "enforcer_hit", name = "Enforcer Job", emoji = "🕶️", risk = 85, reward = { min = 10000, max = 50000 }, respect = 120, description = "Handle a problem for the boss.", rankRequired = 5, category = "enforcement" },
		},
		initiation = "To join the Bratva, you must show no fear. Complete an act of violence.",
	},
	
	yakuza = {
		id = "yakuza",
		name = "Japanese Yakuza",
		fullName = "The Yamaguchi-gumi",
		emoji = "🇯🇵",
		description = "Honor and tradition guide the way. The path of the samurai lives on.",
		color = Color3.fromRGB(139, 92, 246),
		colorDark = Color3.fromRGB(109, 40, 217),
		ranks = {
			{ id = "shatei", name = "Shatei", level = 1, respect = 0, emoji = "👤" },
			{ id = "wakashu", name = "Wakashu", level = 2, respect = 100, emoji = "🔫" },
			{ id = "shateigashira", name = "Shateigashira", level = 3, respect = 500, emoji = "💰" },
			{ id = "wakagashira", name = "Wakagashira", level = 4, respect = 2000, emoji = "🎩" },
			{ id = "oyabun", name = "Oyabun", level = 5, respect = 10000, emoji = "👑" },
		},
		operations = {
			{ id = "pachinko", name = "Pachinko Parlors", emoji = "🎰", risk = 15, reward = { min = 1000, max = 5000 }, respect = 8, description = "Siphon coins from arcades.", rankRequired = 1, category = "income" },
			{ id = "night_market", name = "Night Market Fees", emoji = "🀄", risk = 20, reward = { min = 1500, max = 6000 }, respect = 10, description = "Tax the street vendors.", rankRequired = 1, category = "income" },
			{ id = "blackmail", name = "Corporate Blackmail", emoji = "📂", risk = 35, reward = { min = 5000, max = 25000 }, respect = 20, description = "Leak photos unless they pay.", rankRequired = 2, category = "finance" },
			{ id = "construction", name = "Construction Bid Rigging", emoji = "🏗️", risk = 25, reward = { min = 3000, max = 15000 }, respect = 15, description = "Control major contracts.", rankRequired = 3, category = "logistics" },
			{ id = "art_smuggling", name = "Art Smuggling", emoji = "🖼️", risk = 45, reward = { min = 7000, max = 30000 }, respect = 35, description = "Move stolen art overseas.", rankRequired = 4, category = "logistics" },
			{ id = "international_smuggling", name = "International Smuggling", emoji = "🚢", risk = 75, reward = { min = 20000, max = 100000 }, respect = 80, description = "Massive contraband operation overseas.", rankRequired = 5, category = "score" },
			{ id = "yubitsume", name = "Enforce Loyalty", emoji = "🩸", risk = 50, reward = { min = 0, max = 0 }, respect = 150, description = "Make an example with yubitsume.", rankRequired = 5, category = "discipline" },
		},
		initiation = "You must get the traditional irezumi tattoo and swear the oath of loyalty.",
	},
	
	cartel = {
		id = "cartel",
		name = "Mexican Cartel",
		fullName = "El Cartel de Sinaloa",
		emoji = "🇲🇽",
		description = "Control the smuggling empire. Money flows like water, but so does blood.",
		color = Color3.fromRGB(34, 197, 94),
		colorDark = Color3.fromRGB(22, 163, 74),
		ranks = {
			{ id = "halcon", name = "Halcon", level = 1, respect = 0, emoji = "👤" },
			{ id = "sicario", name = "Sicario", level = 2, respect = 100, emoji = "🔫" },
			{ id = "lugarteniente", name = "Lugarteniente", level = 3, respect = 500, emoji = "💰" },
			{ id = "capo", name = "Capo", level = 4, respect = 2000, emoji = "🎩" },
			{ id = "jefe", name = "El Jefe", level = 5, respect = 10000, emoji = "👑" },
		},
		operations = {
			{ id = "lookout", name = "Lookout Duty", emoji = "👀", risk = 10, reward = { min = 200, max = 800 }, respect = 3, description = "Watch the border crossings.", rankRequired = 1, category = "support" },
			{ id = "mule_run", name = "Courier Run", emoji = "🧳", risk = 25, reward = { min = 2000, max = 7000 }, respect = 10, description = "Move product across town.", rankRequired = 1, category = "logistics" },
			{ id = "transport", name = "Cargo Transport", emoji = "🚛", risk = 40, reward = { min = 5000, max = 20000 }, respect = 20, description = "Escort a major shipment.", rankRequired = 2, category = "logistics" },
			{ id = "production", name = "Run Operations", emoji = "⚗️", risk = 50, reward = { min = 10000, max = 50000 }, respect = 35, description = "Oversee the production facility.", rankRequired = 3, category = "finance" },
			{ id = "distribution", name = "Distribution Network", emoji = "📦", risk = 35, reward = { min = 8000, max = 30000 }, respect = 25, description = "Expand the regional network.", rankRequired = 4, category = "logistics" },
			{ id = "facility_expansion", name = "Facility Expansion", emoji = "🏭", risk = 55, reward = { min = 12000, max = 60000 }, respect = 40, description = "Build a new hidden facility.", rankRequired = 4, category = "finance" },
			{ id = "territorial", name = "Territory Takeover", emoji = "🌎", risk = 90, reward = { min = 25000, max = 150000 }, respect = 100, description = "Seize a rival's territory.", rankRequired = 5, category = "enforcement" },
		},
		initiation = "Prove yourself by making a successful run across the border.",
	},
	
	triad = {
		id = "triad",
		name = "Chinese Triad",
		fullName = "The 14K Triad",
		emoji = "🇨🇳",
		description = "The Heaven and Earth Society. Ancient traditions meet modern crime.",
		color = Color3.fromRGB(249, 115, 22),
		colorDark = Color3.fromRGB(194, 65, 12),
		ranks = {
			{ id = "lantern", name = "Blue Lantern", level = 1, respect = 0, emoji = "👤" },
			{ id = "fortyNiner", name = "49er", level = 2, respect = 100, emoji = "🔫" },
			{ id = "redPole", name = "Red Pole", level = 3, respect = 500, emoji = "💰" },
			{ id = "deputy", name = "Deputy", level = 4, respect = 2000, emoji = "🎩" },
			{ id = "dragonHead", name = "Dragon Head", level = 5, respect = 10000, emoji = "👑" },
		},
		operations = {
			{ id = "counterfeiting", name = "Counterfeit Bills", emoji = "💷", risk = 25, reward = { min = 1500, max = 6000 }, respect = 10, description = "Print stacks of fake cash.", rankRequired = 1, category = "income" },
			{ id = "piracy", name = "Software Piracy", emoji = "💾", risk = 20, reward = { min = 2000, max = 10000 }, respect = 8, description = "Duplicate movies and games.", rankRequired = 1, category = "tech" },
			{ id = "loan_sharking", name = "Loan Sharking", emoji = "📉", risk = 30, reward = { min = 3000, max = 12000 }, respect = 15, description = "Collect brutal interest payments.", rankRequired = 2, category = "finance" },
			{ id = "nightclub_take", name = "Nightclub Takeover", emoji = "🎤", risk = 35, reward = { min = 5000, max = 22000 }, respect = 22, description = "Seize control of a nightclub.", rankRequired = 3, category = "violence" },
			{ id = "smuggling", name = "Smuggling Ring", emoji = "🚢", risk = 55, reward = { min = 15000, max = 60000 }, respect = 40, description = "Move contraband along the coast.", rankRequired = 4, category = "logistics" },
			{ id = "ritual", name = "Blood Oath Ceremony", emoji = "🩸", risk = 40, reward = { min = 0, max = 0 }, respect = 200, description = "Enforce loyalty through ritual.", rankRequired = 5, category = "discipline" },
		},
		initiation = "You must undergo the traditional 36 oaths ceremony and blood oath.",
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- MOB STATE (per player)
-- ════════════════════════════════════════════════════════════════════════════

MafiaSystem.DefaultMobState = {
	inMob = false,
	familyId = nil,
	rankIndex = 1,
	respect = 0,
	notoriety = 0, -- Police awareness
	kills = 0,
	earnings = 0,
	yearsInMob = 0,
	operationsCompleted = 0,
	operationsFailed = 0,
	betrayals = 0,
	loyalty = 100,
	territories = {},
	crew = {}, -- NPCs under your command
	heat = 0, -- Current wanted level
	lastEvent = nil,
}

-- ════════════════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem.new()
	local self = setmetatable({}, MafiaSystem)
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- MOB STATE MANAGEMENT
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:initMobState(lifeState)
	if not lifeState.MobState then
		lifeState.MobState = {}
		for k, v in pairs(self.DefaultMobState) do
			if type(v) == "table" then
				lifeState.MobState[k] = {}
			else
				lifeState.MobState[k] = v
			end
		end
	end
	return lifeState.MobState
end

function MafiaSystem:getMobState(lifeState)
	return self:initMobState(lifeState)
end

-- ════════════════════════════════════════════════════════════════════════════
-- JOIN/LEAVE MOB
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:canJoinMob(lifeState)
	local mobState = self:getMobState(lifeState)
	
	-- Already in a mob
	if mobState.inMob then
		return false, "You're already in a crime family!"
	end
	
	-- Age requirement
	if lifeState.Age < 18 then
		return false, "You must be at least 18 to join the mob."
	end
	
	-- Not in jail
	if lifeState.InJail then
		return false, "You can't join from jail!"
	end
	
	return true, nil
end

function MafiaSystem:joinFamily(lifeState, familyId)
	local canJoin, reason = self:canJoinMob(lifeState)
	if not canJoin then
		return false, reason
	end
	
	local family = self.Families[familyId]
	if not family then
		return false, "Unknown crime family."
	end
	
	local mobState = self:getMobState(lifeState)
	-- CRITICAL FIX #7: Set all state fields that client expects
	mobState.inMob = true
	mobState.familyId = familyId
	mobState.familyName = family.name
	mobState.familyEmoji = family.emoji
	mobState.rankIndex = 1
	mobState.rankLevel = 1
	mobState.rankName = family.ranks[1].name
	mobState.rankEmoji = family.ranks[1].emoji
	mobState.respect = 0
	mobState.loyalty = 100
	mobState.heat = 0
	mobState.yearsInMob = 0
	mobState.operationsCompleted = 0
	mobState.operationsFailed = 0
	mobState.earnings = 0
	mobState.kills = 0
	
	return true, "You've joined " .. family.name .. " as a " .. family.ranks[1].name .. "!"
end

function MafiaSystem:leaveFamily(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return false, "You're not in a crime family."
	end
	
	local family = self.Families[mobState.familyId]
	
	-- Leaving has consequences!
	local consequences = {}
	
	-- High rank = harder to leave
	if mobState.rankIndex >= 3 then
		-- Risk of being killed
		local deathRisk = mobState.rankIndex * 15
		if math.random(100) <= deathRisk then
			return false, "The family doesn't let high-ranking members leave alive... You've been eliminated!", { death = true }
		end
		table.insert(consequences, "A hit has been put out on you!")
	end
	
	-- Reset mob state
	mobState.inMob = false
	mobState.familyId = nil
	mobState.rankIndex = 1
	mobState.respect = 0
	mobState.loyalty = 0
	
	return true, "You've left " .. family.name .. ". Watch your back...", consequences
end

-- ════════════════════════════════════════════════════════════════════════════
-- OPERATIONS (Criminal Activities)
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:getAvailableOperations(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return {}
	end
	
	local family = self.Families[mobState.familyId]
	local available = {}
	
	-- Higher ranks unlock more operations
	local rankGate = mobState.rankIndex + 1
	for i, op in ipairs(family.operations) do
		local required = op.rankRequired or i
		if required <= rankGate then
			table.insert(available, op)
		end
	end
	
	return available
end

function MafiaSystem:doOperation(lifeState, operationId)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return false, "You're not in a crime family!", nil
	end
	
	if lifeState.InJail then
		return false, "You can't do operations from jail!", nil
	end
	
	local family = self.Families[mobState.familyId]
	local operation = nil
	
	for _, op in ipairs(family.operations) do
		if op.id == operationId then
			operation = op
			break
		end
	end
	
	if not operation then
		return false, "Unknown operation.", nil
	end
	
	-- Calculate success
	local baseChance = 100 - operation.risk
	local rankBonus = mobState.rankIndex * 5
	local successChance = math.min(95, baseChance + rankBonus)
	
	local roll = math.random(100)
	local success = roll <= successChance
	
	local result = {
		operation = operation.name,
		success = success,
		money = 0,
		respect = 0,
		heat = 0,
		message = "",
	}
	
	if success then
		-- Calculate rewards
		result.money = math.random(operation.reward.min, operation.reward.max)
		result.respect = operation.respect + math.random(0, 10)
		result.heat = math.floor(operation.risk / 10)
		
		-- Apply rewards
		lifeState.Money = (lifeState.Money or 0) + result.money
		mobState.respect = mobState.respect + result.respect
		mobState.heat = math.min(100, mobState.heat + result.heat)
		mobState.earnings = mobState.earnings + result.money
		mobState.operationsCompleted = mobState.operationsCompleted + 1
		
		result.message = string.format(
			"Operation successful! You earned $%s and gained %d respect.",
			self:formatMoney(result.money),
			result.respect
		)
		
		-- Check for rank up
		local rankUpMsg = self:checkRankUp(lifeState)
		if rankUpMsg then
			result.message = result.message .. "\n\n" .. rankUpMsg
			result.promoted = true
		end
	else
		-- Failed operation
		result.heat = math.floor(operation.risk / 5)
		mobState.heat = math.min(100, mobState.heat + result.heat)
		mobState.operationsFailed = mobState.operationsFailed + 1
		
		-- Risk of arrest
		local arrestChance = operation.risk / 2
		if math.random(100) <= arrestChance then
			local jailYears = math.ceil(operation.risk / 20)
			lifeState.InJail = true
			lifeState.JailYearsLeft = jailYears
			result.message = string.format(
				"Operation failed! You got caught and sentenced to %d years in prison!",
				jailYears
			)
			result.arrested = true
		else
			result.message = "Operation failed! You barely escaped, but the heat is on."
		end
	end
	
	return true, result.message, result
end

-- ════════════════════════════════════════════════════════════════════════════
-- RANK SYSTEM
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:getCurrentRank(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return nil
	end
	
	local family = self.Families[mobState.familyId]
	return family.ranks[mobState.rankIndex]
end

function MafiaSystem:getNextRank(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return nil
	end
	
	local family = self.Families[mobState.familyId]
	if mobState.rankIndex >= #family.ranks then
		return nil -- Already at top
	end
	
	return family.ranks[mobState.rankIndex + 1]
end

function MafiaSystem:checkRankUp(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return nil
	end
	
	local family = self.Families[mobState.familyId]
	local nextRank = self:getNextRank(lifeState)
	
	if not nextRank then
		return nil -- Already at top
	end
	
	if mobState.respect >= nextRank.respect then
		-- CRITICAL FIX #9: Update all rank fields for client consistency
		mobState.rankIndex = mobState.rankIndex + 1
		mobState.rankLevel = mobState.rankIndex
		mobState.rankName = nextRank.name
		mobState.rankEmoji = nextRank.emoji
		return string.format(
			"🎉 You've been promoted to %s %s!",
			nextRank.emoji,
			nextRank.name
		)
	end
	
	return nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- YEARLY UPDATE
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:onYearPass(lifeState)
	local mobState = self:getMobState(lifeState)
	local events = {}
	
	if not mobState.inMob then
		return events
	end
	
	mobState.yearsInMob = mobState.yearsInMob + 1
	
	-- Heat decays over time
	mobState.heat = math.max(0, mobState.heat - 10)
	
	-- Random mob events
	local roll = math.random(100)
	
	if roll <= 5 then
		-- Family war
		table.insert(events, {
			type = "war",
			message = "⚔️ Your family is at war with a rival organization!",
		})
	elseif roll <= 10 then
		-- Police crackdown
		if mobState.heat > 50 then
			table.insert(events, {
				type = "crackdown",
				message = "🚔 Police are cracking down on organized crime. Lay low!",
			})
			mobState.heat = math.min(100, mobState.heat + 20)
		end
	elseif roll <= 15 then
		-- Loyalty test
		table.insert(events, {
			type = "loyalty",
			message = "🤫 The family is testing your loyalty...",
		})
	elseif roll <= 20 then
		-- Tribute payment
		local tribute = math.floor(mobState.respect * 10)
		if lifeState.Money >= tribute then
			lifeState.Money = lifeState.Money - tribute
			mobState.loyalty = math.min(100, mobState.loyalty + 5)
			table.insert(events, {
				type = "tribute",
				message = string.format("💰 You paid $%s in tribute to the boss.", self:formatMoney(tribute)),
			})
		else
			mobState.loyalty = math.max(0, mobState.loyalty - 20)
			table.insert(events, {
				type = "tribute_failed",
				message = "😰 You couldn't pay tribute. The family is not pleased...",
			})
		end
	end
	
	-- Low loyalty consequences
	if mobState.loyalty < 30 then
		local betrayalChance = 100 - mobState.loyalty
		if math.random(100) <= betrayalChance / 2 then
			table.insert(events, {
				type = "betrayal",
				message = "⚠️ The family suspects you might be disloyal...",
			})
		end
	end
	
	if #events > 0 then
		mobState.lastEvent = events[#events].message
	end
	
	return events
end

-- ════════════════════════════════════════════════════════════════════════════
-- SERIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:serialize(lifeState)
	local mobState = self:getMobState(lifeState)
	
	-- CRITICAL FIX #14: Handle nil or empty mobState
	if not mobState or not mobState.inMob then
		return { 
			inMob = false,
			familyId = nil,
			familyName = nil,
			familyEmoji = nil,
			rankLevel = 1,
			rankName = nil,
			rankEmoji = nil,
			respect = 0,
			loyalty = 100,
			heat = 0,
			yearsInMob = 0,
			operationsCompleted = 0,
			earnings = 0,
			kills = 0,
			operations = {},
		}
	end
	
	local family = self.Families[mobState.familyId]
	if not family then
		return { inMob = false, operations = {} }
	end
	
	local currentRank = family.ranks[mobState.rankIndex or 1]
	local nextRank = self:getNextRank(lifeState)
	local operationsSummary = {}
	local rankGate = (mobState.rankIndex or 1) + 1
	for idx, op in ipairs(family.operations) do
		local required = op.rankRequired or idx
		if required <= rankGate then
			table.insert(operationsSummary, {
				id = op.id,
				name = op.name,
				emoji = op.emoji,
				description = op.description,
				category = op.category,
				risk = op.risk,
				respect = op.respect,
				minReward = op.reward.min,
				maxReward = op.reward.max,
				rankRequired = required,
			})
		end
	end
	
	return {
		inMob = true,
		familyId = mobState.familyId,
		familyName = family.name,
		familyEmoji = family.emoji,
		familyColor = { family.color.R, family.color.G, family.color.B },
		rankName = currentRank.name,
		rankEmoji = currentRank.emoji,
		rankLevel = mobState.rankIndex,
		maxRank = #family.ranks,
		respect = mobState.respect,
		nextRankRespect = nextRank and nextRank.respect or nil,
		notoriety = mobState.notoriety,
		heat = mobState.heat,
		loyalty = mobState.loyalty,
		kills = mobState.kills,
		earnings = mobState.earnings,
		yearsInMob = mobState.yearsInMob,
		operationsCompleted = mobState.operationsCompleted,
		lastEvent = mobState.lastEvent,
		operations = operationsSummary,
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- UTILITIES
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:formatMoney(amount)
	if amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	else
		return tostring(amount)
	end
end

function MafiaSystem:getFamilyList()
	local list = {}
	for id, family in pairs(self.Families) do
		table.insert(list, {
			id = id,
			name = family.name,
			fullName = family.fullName,
			emoji = family.emoji,
			description = family.description,
			color = { family.color.R, family.color.G, family.color.B },
			colorDark = { family.colorDark.R, family.colorDark.G, family.colorDark.B },
		})
	end
	return list
end

-- CRITICAL FIX #13: Removed duplicate serialize function
-- The comprehensive serialize function is defined above (lines 558-610)

-- ════════════════════════════════════════════════════════════════════════════
-- SINGLETON INSTANCE
-- ════════════════════════════════════════════════════════════════════════════

local instance = MafiaSystem.new()

return instance
