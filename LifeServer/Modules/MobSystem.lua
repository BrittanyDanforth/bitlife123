--[[
	MobSystem.lua
	
	Organized crime/Mafia system for BitLife-style game.
	Allows players to join crime families and rise through the ranks.
	
	REQUIRES: Mafia gamepass
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MobSystem = {}
MobSystem.__index = MobSystem

-- ════════════════════════════════════════════════════════════════════════════
-- CRIME FAMILY DEFINITIONS
-- ════════════════════════════════════════════════════════════════════════════

MobSystem.Families = {
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
			{ id = "protection", name = "Protection Racket", risk = 20, reward = { min = 500, max = 2000 }, respect = 5 },
			{ id = "gambling", name = "Run Gambling Ring", risk = 30, reward = { min = 1000, max = 5000 }, respect = 10 },
			{ id = "smuggling", name = "Smuggle Goods", risk = 40, reward = { min = 2000, max = 10000 }, respect = 20 },
			{ id = "heist", name = "Plan a Heist", risk = 60, reward = { min = 10000, max = 100000 }, respect = 50 },
			{ id = "hitjob", name = "Hit Job", risk = 80, reward = { min = 5000, max = 25000 }, respect = 100 },
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
			{ id = "extortion", name = "Extortion", risk = 25, reward = { min = 800, max = 3000 }, respect = 8 },
			{ id = "weapons", name = "Arms Dealing", risk = 45, reward = { min = 3000, max = 15000 }, respect = 25 },
			{ id = "cyber", name = "Cyber Crime", risk = 30, reward = { min = 2000, max = 20000 }, respect = 15 },
			{ id = "kidnapping", name = "Kidnapping", risk = 70, reward = { min = 15000, max = 75000 }, respect = 60 },
			{ id = "assassination", name = "Contract Kill", risk = 85, reward = { min = 10000, max = 50000 }, respect = 120 },
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
			{ id = "pachinko", name = "Pachinko Parlors", risk = 15, reward = { min = 1000, max = 5000 }, respect = 8 },
			{ id = "blackmail", name = "Corporate Blackmail", risk = 35, reward = { min = 5000, max = 25000 }, respect = 20 },
			{ id = "construction", name = "Construction Bid Rigging", risk = 25, reward = { min = 3000, max = 15000 }, respect = 15 },
			{ id = "trafficking", name = "Human Trafficking", risk = 75, reward = { min = 20000, max = 100000 }, respect = 80 },
			{ id = "yubitsume", name = "Enforce Loyalty", risk = 50, reward = { min = 0, max = 0 }, respect = 150 },
		},
		initiation = "You must get the traditional irezumi tattoo and swear the oath of loyalty.",
	},
	
	cartel = {
		id = "cartel",
		name = "Mexican Cartel",
		fullName = "El Cartel de Sinaloa",
		emoji = "🇲🇽",
		description = "Control the drug empire. Money flows like water, but so does blood.",
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
			{ id = "lookout", name = "Lookout Duty", risk = 10, reward = { min = 200, max = 800 }, respect = 3 },
			{ id = "transport", name = "Drug Transport", risk = 40, reward = { min = 5000, max = 20000 }, respect = 20 },
			{ id = "production", name = "Run Drug Lab", risk = 50, reward = { min = 10000, max = 50000 }, respect = 35 },
			{ id = "distribution", name = "Distribution Network", risk = 35, reward = { min = 8000, max = 30000 }, respect = 25 },
			{ id = "territorial", name = "Territory Takeover", risk = 90, reward = { min = 25000, max = 150000 }, respect = 100 },
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
			{ id = "counterfeiting", name = "Counterfeiting", risk = 25, reward = { min = 1500, max = 6000 }, respect = 10 },
			{ id = "piracy", name = "Software Piracy", risk = 20, reward = { min = 2000, max = 10000 }, respect = 8 },
			{ id = "loan_sharking", name = "Loan Sharking", risk = 30, reward = { min = 3000, max = 12000 }, respect = 15 },
			{ id = "smuggling", name = "Smuggling Ring", risk = 55, reward = { min = 15000, max = 60000 }, respect = 40 },
			{ id = "ritual", name = "Blood Oath Ceremony", risk = 40, reward = { min = 0, max = 0 }, respect = 200 },
		},
		initiation = "You must undergo the traditional 36 oaths ceremony and blood oath.",
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- MOB STATE (per player)
-- ════════════════════════════════════════════════════════════════════════════

MobSystem.DefaultMobState = {
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
}

-- ════════════════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════════════════

function MobSystem.new()
	local self = setmetatable({}, MobSystem)
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- MOB STATE MANAGEMENT
-- ════════════════════════════════════════════════════════════════════════════

function MobSystem:initMobState(lifeState)
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

function MobSystem:getMobState(lifeState)
	return self:initMobState(lifeState)
end

-- ════════════════════════════════════════════════════════════════════════════
-- JOIN/LEAVE MOB
-- ════════════════════════════════════════════════════════════════════════════

function MobSystem:canJoinMob(lifeState)
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

function MobSystem:joinFamily(lifeState, familyId)
	local canJoin, reason = self:canJoinMob(lifeState)
	if not canJoin then
		return false, reason
	end
	
	local family = self.Families[familyId]
	if not family then
		return false, "Unknown crime family."
	end
	
	local mobState = self:getMobState(lifeState)
	mobState.inMob = true
	mobState.familyId = familyId
	mobState.rankIndex = 1
	mobState.respect = 0
	mobState.loyalty = 100
	mobState.yearsInMob = 0
	
	return true, "You've joined " .. family.name .. " as a " .. family.ranks[1].name .. "!"
end

function MobSystem:leaveFamily(lifeState)
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

function MobSystem:getAvailableOperations(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return {}
	end
	
	local family = self.Families[mobState.familyId]
	local available = {}
	
	-- Higher ranks unlock more operations
	for i, op in ipairs(family.operations) do
		if i <= mobState.rankIndex + 1 then
			table.insert(available, op)
		end
	end
	
	return available
end

function MobSystem:doOperation(lifeState, operationId)
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

function MobSystem:getCurrentRank(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return nil
	end
	
	local family = self.Families[mobState.familyId]
	return family.ranks[mobState.rankIndex]
end

function MobSystem:getNextRank(lifeState)
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

function MobSystem:checkRankUp(lifeState)
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
		mobState.rankIndex = mobState.rankIndex + 1
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

function MobSystem:onYearPass(lifeState)
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
	
	return events
end

-- ════════════════════════════════════════════════════════════════════════════
-- SERIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

function MobSystem:serialize(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return { inMob = false }
	end
	
	local family = self.Families[mobState.familyId]
	local currentRank = family.ranks[mobState.rankIndex]
	local nextRank = self:getNextRank(lifeState)
	
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
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- UTILITIES
-- ════════════════════════════════════════════════════════════════════════════

function MobSystem:formatMoney(amount)
	if amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	else
		return tostring(amount)
	end
end

function MobSystem:getFamilyList()
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

-- ════════════════════════════════════════════════════════════════════════════
-- SINGLETON INSTANCE
-- ════════════════════════════════════════════════════════════════════════════

local instance = MobSystem.new()

return instance
