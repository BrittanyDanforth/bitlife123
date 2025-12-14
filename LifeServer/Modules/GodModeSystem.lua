--[[
	GodModeSystem.lua
	
	Comprehensive god mode system for BitLife-style game.
	Allows players with the God Mode gamepass to edit their stats anytime.
	
	Features:
	- Edit Happiness, Health, Smarts, Looks (0-100)
	- Edit Fame level
	- Change character name
	- Change gender presentation
	- Clear criminal record
	- Cure diseases
	- Remove addictions
	- Modify wealth (within limits)
	- Edit fertility
	- Reset relationships
	
	REQUIRES: God Mode gamepass (ID: 1628050729)
	
	This is a PREMIUM feature - full implementation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GodModeSystem = {}
GodModeSystem.__index = GodModeSystem

-- ════════════════════════════════════════════════════════════════════════════
-- EDITABLE STATS CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

GodModeSystem.EditableStats = {
	{
		key = "Happiness",
		emoji = "😊",
		name = "Happiness",
		min = 0,
		max = 100,
		description = "Your overall mood and life satisfaction",
		category = "core",
	},
	{
		key = "Health",
		emoji = "❤️",
		name = "Health",
		min = 0,
		max = 100,
		description = "Physical health and vitality",
		category = "core",
	},
	{
		key = "Smarts",
		emoji = "🧠",
		name = "Smarts",
		min = 0,
		max = 100,
		description = "Intelligence, wisdom, and knowledge",
		category = "core",
	},
	{
		key = "Looks",
		emoji = "✨",
		name = "Looks",
		min = 0,
		max = 100,
		description = "Physical attractiveness",
		category = "core",
	},
	{
		key = "Fame",
		emoji = "⭐",
		name = "Fame",
		min = 0,
		max = 100,
		description = "Public recognition and celebrity status",
		category = "social",
	},
	-- CRITICAL FIX #187: Money editing in God Mode
	{
		key = "Money",
		emoji = "💰",
		name = "Money",
		min = 0,
		max = 999999999999, -- Up to 999 billion
		description = "Edit your bank balance directly",
		category = "financial",
		isMoney = true, -- Flag to indicate this is money, not a 0-100 stat
	},
	-- CRITICAL FIX #188: Fertility editing in God Mode
	{
		key = "Fertility",
		emoji = "👶",
		name = "Fertility",
		min = 0,
		max = 100,
		description = "Ability to have children",
		category = "health",
	},
}

GodModeSystem.EditableProperties = {
	{
		key = "name",
		emoji = "📝",
		name = "Character Name",
		type = "string",
		maxLength = 40,
		description = "Change your character's name",
		category = "identity",
	},
	{
		key = "gender",
		emoji = "👤",
		name = "Gender",
		type = "select",
		options = { "Male", "Female", "Nonbinary" },
		description = "Change gender presentation",
		category = "identity",
	},
}

GodModeSystem.ClearableFlags = {
	{
		key = "criminal_record",
		emoji = "📋",
		name = "Criminal Record",
		description = "Clear your criminal history",
		category = "legal",
		relatedFlags = { "convicted_felon", "arrested", "prison_record", "on_probation" },
	},
	{
		key = "diseases",
		emoji = "💊",
		name = "All Diseases",
		description = "Cure all current diseases",
		category = "health",
		relatedFlags = { "has_std", "has_cancer", "chronic_illness", "terminal_illness", "mental_illness" },
	},
	{
		key = "addictions",
		emoji = "🚭",
		name = "All Addictions",
		description = "Remove all addictions",
		category = "health",
		relatedFlags = { "alcoholic", "drug_addict", "gambling_addict", "nicotine_addict" },
	},
	{
		key = "debt",
		emoji = "💳",
		name = "All Debt",
		description = "Clear education and other debts",
		category = "financial",
		affectsEducationDebt = true,
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════════════════

function GodModeSystem.new()
	local self = setmetatable({}, GodModeSystem)
	self.editHistory = {} -- Track edits per player
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- STAT EDITING
-- ════════════════════════════════════════════════════════════════════════════

function GodModeSystem:canEdit(player, gamepassSystem)
	if not gamepassSystem then
		return false, "System not available"
	end
	
	local hasGodMode = gamepassSystem:hasGodMode(player)
	if not hasGodMode then
		return false, "God Mode gamepass required"
	end
	
	return true, nil
end

function GodModeSystem:editStat(lifeState, statKey, newValue)
	-- Validate stat key
	local statConfig = nil
	for _, stat in ipairs(self.EditableStats) do
		if stat.key == statKey then
			statConfig = stat
			break
		end
	end
	
	if not statConfig then
		return false, "Invalid stat: " .. tostring(statKey)
	end
	
	-- Clamp value
	newValue = math.clamp(tonumber(newValue) or 0, statConfig.min, statConfig.max)
	newValue = math.floor(newValue)
	
	-- CRITICAL FIX #189: Handle Money specially (not a 0-100 stat)
	if statKey == "Money" or statConfig.isMoney then
		lifeState.Money = newValue
		-- Track edit
		if lifeState.GodModeState then
			lifeState.GodModeState.editsThisLife = (lifeState.GodModeState.editsThisLife or 0) + 1
			lifeState.GodModeState.lastEditAge = lifeState.Age
		end
		return true, string.format("%s %s set to %s", statConfig.emoji, statConfig.name, self:formatMoney(newValue))
	end
	
	-- CRITICAL FIX #190: Handle Fertility specially
	if statKey == "Fertility" then
		lifeState.Fertility = newValue
		lifeState.Flags = lifeState.Flags or {}
		if newValue == 0 then
			lifeState.Flags.infertile = true
			lifeState.Flags.can_have_children = nil
		else
			lifeState.Flags.infertile = nil
			lifeState.Flags.can_have_children = true
		end
		if lifeState.GodModeState then
			lifeState.GodModeState.editsThisLife = (lifeState.GodModeState.editsThisLife or 0) + 1
			lifeState.GodModeState.lastEditAge = lifeState.Age
		end
		return true, string.format("%s %s set to %d%%", statConfig.emoji, statConfig.name, newValue)
	end
	
	-- Apply to state
	if lifeState.Stats and lifeState.Stats[statKey] ~= nil then
		lifeState.Stats[statKey] = newValue
	end
	if lifeState[statKey] ~= nil then
		lifeState[statKey] = newValue
	end
	
	-- Special handling for Fame
	if statKey == "Fame" then
		lifeState.Fame = newValue
		-- Update fame state if it exists
		if lifeState.FameState then
			if newValue >= 30 then
				lifeState.FameState.isFamous = true
			else
				lifeState.FameState.isFamous = false
			end
		end
	end
	
	-- CRITICAL FIX #191: Sync both Stats table and root property
	if lifeState.Stats then
		lifeState.Stats[statKey] = newValue
	end
	lifeState[statKey] = newValue
	
	-- Track edit
	if lifeState.GodModeState then
		lifeState.GodModeState.editsThisLife = (lifeState.GodModeState.editsThisLife or 0) + 1
		lifeState.GodModeState.lastEditAge = lifeState.Age
	end
	
	return true, string.format("%s %s set to %d%%", statConfig.emoji, statConfig.name, newValue)
end

function GodModeSystem:editMultipleStats(lifeState, statsTable)
	local results = {}
	local successCount = 0
	
	for statKey, newValue in pairs(statsTable) do
		local success, message = self:editStat(lifeState, statKey, newValue)
		table.insert(results, {
			stat = statKey,
			success = success,
			message = message,
		})
		if success then
			successCount = successCount + 1
		end
	end
	
	return successCount > 0, results
end

-- ════════════════════════════════════════════════════════════════════════════
-- PROPERTY EDITING
-- ════════════════════════════════════════════════════════════════════════════

function GodModeSystem:editName(lifeState, newName)
	if not newName or type(newName) ~= "string" then
		return false, "Invalid name"
	end
	
	-- Trim and limit length
	newName = newName:gsub("^%s+", ""):gsub("%s+$", "")
	if newName == "" then
		return false, "Name cannot be empty"
	end
	
	newName = newName:sub(1, 40)
	lifeState.Name = newName
	
	return true, "📝 Name changed to: " .. newName
end

function GodModeSystem:editGender(lifeState, newGender)
	local validGenders = { Male = true, Female = true, Nonbinary = true }
	
	if not newGender or type(newGender) ~= "string" then
		return false, "Invalid gender"
	end
	
	-- Normalize
	local normalized = newGender:sub(1,1):upper() .. newGender:sub(2):lower()
	
	if not validGenders[normalized] then
		return false, "Invalid gender. Must be Male, Female, or Nonbinary"
	end
	
	lifeState.Gender = normalized
	
	return true, "👤 Gender changed to: " .. normalized
end

function GodModeSystem:editMoney(lifeState, newAmount)
	local amount = tonumber(newAmount)
	if not amount then
		return false, "Invalid amount"
	end
	
	-- Allow any positive amount for god mode users
	amount = math.max(0, math.floor(amount))
	lifeState.Money = amount
	
	local formatted = ""
	if amount >= 1000000000 then
		formatted = string.format("$%.1fB", amount / 1000000000)
	elseif amount >= 1000000 then
		formatted = string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		formatted = string.format("$%.1fK", amount / 1000)
	else
		formatted = "$" .. tostring(amount)
	end
	
	return true, "💰 Money set to: " .. formatted
end

-- ════════════════════════════════════════════════════════════════════════════
-- FLAG CLEARING
-- ════════════════════════════════════════════════════════════════════════════

function GodModeSystem:clearCriminalRecord(lifeState)
	local flags = lifeState.Flags or {}
	
	-- CRITICAL FIX #172: Comprehensive criminal record clearing
	local criminalFlags = {
		-- Record types
		"criminal_record", "convicted_felon", "arrested", "prison_record",
		"juvenile_record", "sealed_record", "expunged_record",
		-- Legal status
		"on_probation", "on_parole", "warrant", "fugitive", "felon",
		"sex_offender", "registered_offender",
		-- Crime types
		"murderer", "thief", "drug_dealer", "violent_criminal",
		"assault_conviction", "robbery_conviction", "fraud_conviction",
		"dui_conviction", "drug_conviction", "theft_conviction",
		"burglary_conviction", "arson_conviction", "kidnapping_conviction",
		-- General criminal flags
		"in_prison", "jail_time", "prison_time", "incarcerated",
		"escaped_prisoner", "on_the_run",
		"gang_member", "organized_crime", "mafia_record",
	}
	
	for _, flag in ipairs(criminalFlags) do
		flags[flag] = nil
	end
	
	lifeState.Flags = flags
	
	-- CRITICAL FIX #173: Clear jail state completely
	lifeState.InJail = false
	lifeState.JailYearsLeft = 0
	lifeState.JailTime = nil
	lifeState.PrisonSentence = nil
	
	-- CRITICAL FIX #174: Clear mob/mafia criminal flags if in organized crime
	if lifeState.MobState then
		lifeState.MobState.heat = 0
		lifeState.MobState.notoriety = 0
	end
	
	return true, "📋 Criminal record completely cleared! Fresh start!"
end

function GodModeSystem:cureDiseases(lifeState)
	local flags = lifeState.Flags or {}
	
	-- CRITICAL FIX #168: Expanded disease list to include all health conditions
	local diseaseFlags = {
		-- STDs
		"has_std", "hiv_positive", "hepatitis", "herpes", "chlamydia", "gonorrhea",
		-- Cancer and serious diseases
		"has_cancer", "cancer", "tumor", "leukemia",
		-- Chronic conditions
		"chronic_illness", "terminal_illness", "chronic_pain",
		"diabetes", "heart_disease", "lung_disease", "kidney_disease", "liver_disease",
		-- Mental health
		"mental_illness", "depression", "anxiety", "bipolar", "schizophrenia",
		"ptsd", "ocd", "adhd", "insomnia", "eating_disorder",
		-- Physical conditions
		"injured", "seriously_injured", "hospitalized", "disabled", "paralyzed",
		"broken_bone", "concussion", "chronic_fatigue",
		-- Misc health issues
		"food_poisoning", "allergic_reaction", "sick", "ill", "bedridden",
		"prolonged_illness", "immune_compromised",
	}
	
	for _, flag in ipairs(diseaseFlags) do
		flags[flag] = nil
	end
	
	lifeState.Flags = flags
	
	-- CRITICAL FIX #169: Boost health and sync both stat locations
	if lifeState.Stats then
		lifeState.Stats.Health = 100
		lifeState.Health = 100
	else
		lifeState.Health = 100
	end
	
	return true, "💊 All diseases and conditions cured! Health restored to 100%"
end

function GodModeSystem:removeAddictions(lifeState)
	local flags = lifeState.Flags or {}
	
	-- CRITICAL FIX #170: Expanded addiction list to cover all substances
	local addictionFlags = {
		-- Substance addictions
		"alcoholic", "alcohol_addiction", "heavy_drinker",
		"drug_addict", "cocaine_addiction", "heroin_addiction", "meth_addiction",
		"pill_addiction", "prescription_addiction", "opioid_addiction",
		"nicotine_addict", "smoking_addiction", "vaping_addiction",
		"marijuana_addiction", "weed_addiction",
		-- Behavioral addictions
		"gambling_addict", "gambling_addiction", "casino_addiction",
		"shopping_addiction", "spending_addiction",
		"gaming_addiction", "social_media_addiction", "phone_addiction",
		"porn_addiction", "sex_addiction",
		-- General flags
		"addicted", "substance_abuse", "recovering_addict", "rehab_needed",
		"overdosed", "withdrawal", "in_rehab",
	}
	
	for _, flag in ipairs(addictionFlags) do
		flags[flag] = nil
	end
	
	lifeState.Flags = flags
	
	-- CRITICAL FIX #171: Clear addiction state data if exists
	if lifeState.Addictions then
		lifeState.Addictions = {}
	end
	
	-- Boost happiness and sync
	if lifeState.Stats then
		lifeState.Stats.Happiness = math.min(100, (lifeState.Stats.Happiness or 50) + 25)
		lifeState.Happiness = lifeState.Stats.Happiness
	else
		lifeState.Happiness = math.min(100, (lifeState.Happiness or 50) + 25)
	end
	
	return true, "🚭 All addictions removed! Feeling free and happy!"
end

function GodModeSystem:clearDebt(lifeState)
	-- CRITICAL FIX #175: Clear ALL types of debt
	
	-- Clear education debt
	if lifeState.EducationData then
		lifeState.EducationData.Debt = 0
	end
	
	-- CRITICAL FIX #176: Clear mortgage debt
	local flags = lifeState.Flags or {}
	flags.mortgage_debt = nil
	flags.has_mortgage = nil
	
	-- Clear car loan
	flags.car_loan = nil
	flags.has_car_loan = nil
	
	-- Clear credit card debt
	flags.credit_card_debt = nil
	flags.has_credit_card_debt = nil
	
	-- Clear medical debt
	flags.medical_debt = nil
	flags.has_medical_debt = nil
	
	-- Clear general debt flags
	flags.in_debt = nil
	flags.bankrupt = nil
	flags.loan_default = nil
	flags.has_student_loans = nil
	flags.collections = nil
	flags.wage_garnishment = nil
	flags.struggling_financially = nil
	
	lifeState.Flags = flags
	
	-- CRITICAL FIX #177: Clear any debt amounts stored elsewhere
	if lifeState.Debts then
		lifeState.Debts = {}
	end
	
	return true, "💳 All debts cleared! Financially free!"
end

function GodModeSystem:clearAllNegativeFlags(lifeState)
	local results = {}
	
	local success1, msg1 = self:clearCriminalRecord(lifeState)
	table.insert(results, msg1)
	
	local success2, msg2 = self:cureDiseases(lifeState)
	table.insert(results, msg2)
	
	local success3, msg3 = self:removeAddictions(lifeState)
	table.insert(results, msg3)
	
	local success4, msg4 = self:clearDebt(lifeState)
	table.insert(results, msg4)
	
	return true, table.concat(results, " ")
end

-- ════════════════════════════════════════════════════════════════════════════
-- RELATIONSHIP EDITING
-- ════════════════════════════════════════════════════════════════════════════

function GodModeSystem:setRelationshipLevel(lifeState, relationshipId, newLevel)
	-- CRITICAL FIX #124: Full nil safety for relationship editing
	if not lifeState then
		return false, "No life state"
	end
	if not lifeState.Relationships then
		lifeState.Relationships = {}
		return false, "No relationships"
	end
	
	-- CRITICAL FIX #125: Handle string and number IDs
	local rel = lifeState.Relationships[relationshipId]
	if not rel and type(relationshipId) == "string" then
		-- Try to find by name
		for id, relationship in pairs(lifeState.Relationships) do
			if type(relationship) == "table" and relationship.name == relationshipId then
				rel = relationship
				break
			end
		end
	end
	
	if not rel or type(rel) ~= "table" then
		return false, "Relationship not found"
	end
	
	newLevel = math.clamp(tonumber(newLevel) or 50, 0, 100)
	rel.relationship = newLevel
	
	return true, string.format("💕 Relationship with %s set to %d%%", rel.name or "Unknown", newLevel)
end

function GodModeSystem:maxAllRelationships(lifeState)
	if not lifeState.Relationships then
		return false, "No relationships"
	end
	
	local count = 0
	for id, rel in pairs(lifeState.Relationships) do
		if type(rel) == "table" then
			rel.relationship = 100
			-- CRITICAL FIX #178: Also heal relationship wounds/flags
			rel.angry = nil
			rel.mad = nil
			rel.hurt = nil
			rel.jealous = nil
			rel.grudge = nil
			count = count + 1
		end
	end
	
	return true, string.format("💕 Maximized %d relationships to 100%%!", count)
end

-- CRITICAL FIX #179: Add function to resurrect dead family members
function GodModeSystem:reviveDeadRelatives(lifeState)
	if not lifeState.Relationships then
		return false, "No relationships"
	end
	
	local count = 0
	for id, rel in pairs(lifeState.Relationships) do
		if type(rel) == "table" and rel.alive == false then
			rel.alive = true
			rel.deathAge = nil
			rel.deathCause = nil
			rel.relationship = math.max(rel.relationship or 50, 50)
			count = count + 1
		end
	end
	
	if count > 0 then
		return true, string.format("✨ Revived %d deceased family members!", count)
	else
		return false, "No deceased relatives to revive"
	end
end

-- CRITICAL FIX #180: Add function to fix negative stats
function GodModeSystem:fixNegativeStats(lifeState)
	lifeState.Stats = lifeState.Stats or {}
	local fixed = 0
	
	-- Fix any negative or out-of-range stats
	for _, stat in ipairs({"Happiness", "Health", "Smarts", "Looks"}) do
		if lifeState.Stats[stat] and lifeState.Stats[stat] < 0 then
			lifeState.Stats[stat] = 0
			lifeState[stat] = 0
			fixed = fixed + 1
		elseif lifeState.Stats[stat] and lifeState.Stats[stat] > 100 then
			lifeState.Stats[stat] = 100
			lifeState[stat] = 100
			fixed = fixed + 1
		end
	end
	
	-- Fix fame
	if lifeState.Fame and lifeState.Fame < 0 then
		lifeState.Fame = 0
		fixed = fixed + 1
	end
	
	-- Fix money
	if lifeState.Money and lifeState.Money < 0 then
		lifeState.Money = 0
		fixed = fixed + 1
	end
	
	if fixed > 0 then
		return true, string.format("🔧 Fixed %d out-of-range values", fixed)
	else
		return true, "✅ All values are within normal range"
	end
end

-- CRITICAL FIX #181: Get out of jail free
function GodModeSystem:releaseFromJail(lifeState)
	if not lifeState.InJail then
		return false, "You're not in jail"
	end
	
	lifeState.InJail = false
	lifeState.JailYearsLeft = 0
	lifeState.JailTime = nil
	lifeState.PrisonSentence = nil
	
	-- Clear prison-related flags
	local flags = lifeState.Flags or {}
	flags.in_prison = nil
	flags.incarcerated = nil
	flags.serving_time = nil
	flags.on_death_row = nil
	flags.life_sentence = nil
	lifeState.Flags = flags
	
	-- Restore education if suspended
	if lifeState.EducationData and lifeState.EducationData.StatusBeforeJail then
		lifeState.EducationData.Status = lifeState.EducationData.StatusBeforeJail
		lifeState.EducationData.StatusBeforeJail = nil
	end
	
	return true, "🔓 Released from jail! You're free!"
end

-- CRITICAL FIX #184: Add function to make player instantly famous
function GodModeSystem:makeFamous(lifeState)
	lifeState.Fame = 100
	lifeState.FameState = lifeState.FameState or {}
	lifeState.FameState.isFamous = true
	lifeState.FameState.fameLevel = "Legend"
	lifeState.FameState.followers = 10000000
	
	-- Set famous flags
	lifeState.Flags = lifeState.Flags or {}
	lifeState.Flags.famous = true
	lifeState.Flags.celebrity = true
	lifeState.Flags.famous_social_media = true
	
	return true, "⭐ You're now legendary famous with 10M followers!"
end

-- CRITICAL FIX #185: Add function to become rich instantly
function GodModeSystem:makeRich(lifeState, amount)
	amount = amount or 1000000000 -- Default to 1 billion
	lifeState.Money = amount
	
	-- Set wealthy flags
	lifeState.Flags = lifeState.Flags or {}
	lifeState.Flags.wealthy = true
	lifeState.Flags.billionaire = true
	lifeState.Flags.self_made_millionaire = true
	
	return true, string.format("💎 You now have $%s!", self:formatMoney(amount))
end

-- CRITICAL FIX #186: Format money helper
function GodModeSystem:formatMoney(amount)
	if not amount then return "$0" end
	if amount >= 1000000000 then
		return string.format("%.1fB", amount / 1000000000)
	elseif amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	else
		return tostring(amount)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- CAREER EDITING
-- ════════════════════════════════════════════════════════════════════════════

function GodModeSystem:setCareerPerformance(lifeState, performanceLevel)
	if not lifeState.CareerInfo then
		return false, "No career info"
	end
	
	performanceLevel = math.clamp(tonumber(performanceLevel) or 50, 0, 100)
	lifeState.CareerInfo.performance = performanceLevel
	lifeState.CareerInfo.promotionProgress = math.min(100, performanceLevel)
	
	return true, string.format("📈 Career performance set to %d%%", performanceLevel)
end

function GodModeSystem:clearCareer(lifeState)
	if lifeState.ClearCareer then
		lifeState:ClearCareer()
	else
		lifeState.CurrentJob = nil
		lifeState.CareerInfo = lifeState.CareerInfo or {}
		lifeState.CareerInfo.performance = 0
		lifeState.CareerInfo.promotionProgress = 0
		lifeState.CareerInfo.yearsAtJob = 0
	end
	
	return true, "💼 Career cleared"
end

-- ════════════════════════════════════════════════════════════════════════════
-- PRESET CONFIGURATIONS
-- ════════════════════════════════════════════════════════════════════════════

GodModeSystem.Presets = {
	{
		id = "perfect",
		name = "Perfect Life",
		emoji = "✨",
		description = "Max all stats, clear all negatives",
		apply = function(self, lifeState)
			lifeState.Stats.Happiness = 100
			lifeState.Stats.Health = 100
			lifeState.Stats.Smarts = 100
			lifeState.Stats.Looks = 100
			lifeState.Happiness = 100
			lifeState.Health = 100
			lifeState.Smarts = 100
			lifeState.Looks = 100
			lifeState.Fame = 100
			self:clearAllNegativeFlags(lifeState)
			return true, "✨ Perfect life applied!"
		end,
	},
	-- CRITICAL FIX #301: Enhanced Billionaire preset with proper flags
	{
		id = "rich",
		name = "Billionaire",
		emoji = "💎",
		description = "Set money to $1 billion with billionaire status",
		apply = function(self, lifeState)
			lifeState.Money = 1000000000 -- $1 billion
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.billionaire = true
			lifeState.Flags.wealthy = true
			lifeState.Flags.self_made_millionaire = true
			lifeState.Flags.financial_success = true
			lifeState.Flags.upper_class = true
			return true, "💎 You're now a BILLIONAIRE with $1,000,000,000!"
		end,
	},
	-- CRITICAL FIX #302: Instant Millionaire preset (more accessible)
	{
		id = "millionaire",
		name = "Millionaire",
		emoji = "💰",
		description = "Set money to $10 million",
		apply = function(self, lifeState)
			lifeState.Money = 10000000 -- $10 million
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.millionaire = true
			lifeState.Flags.wealthy = true
			lifeState.Flags.financial_success = true
			return true, "💰 You're now a millionaire with $10,000,000!"
		end,
	},
	{
		id = "famous",
		name = "Famous",
		emoji = "⭐",
		description = "Max fame to 100 with 10M followers",
		apply = function(self, lifeState)
			lifeState.Fame = 100
			lifeState.FameState = lifeState.FameState or {}
			lifeState.FameState.isFamous = true
			lifeState.FameState.fameLevel = "Legend"
			lifeState.FameState.followers = 10000000
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.famous = true
			lifeState.Flags.celebrity = true
			lifeState.Flags.famous_social_media = true
			return true, "⭐ You're now legendary famous with 10M followers!"
		end,
	},
	{
		id = "healthy",
		name = "Peak Health",
		emoji = "💪",
		description = "Max health, cure all diseases",
		apply = function(self, lifeState)
			lifeState.Stats.Health = 100
			lifeState.Health = 100
			self:cureDiseases(lifeState)
			self:removeAddictions(lifeState)
			return true, "💪 Peak physical condition!"
		end,
	},
	{
		id = "genius",
		name = "Genius",
		emoji = "🧠",
		description = "Max smarts to 100",
		apply = function(self, lifeState)
			lifeState.Stats.Smarts = 100
			lifeState.Smarts = 100
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.genius = true
			lifeState.Flags.highly_intelligent = true
			return true, "🧠 You're now a genius!"
		end,
	},
	{
		id = "fresh_start",
		name = "Fresh Start",
		emoji = "🔄",
		description = "Clear all negative flags",
		apply = function(self, lifeState)
			return self:clearAllNegativeFlags(lifeState)
		end,
	},
	-- CRITICAL FIX #303: Mafia Boss preset
	{
		id = "mafia_boss",
		name = "Mafia Boss",
		emoji = "🔫",
		description = "Become a powerful mob boss instantly",
		apply = function(self, lifeState)
			lifeState.MobState = lifeState.MobState or {}
			lifeState.MobState.inMob = true
			lifeState.MobState.familyId = "italian"
			lifeState.MobState.familyName = "Italian Mafia"
			lifeState.MobState.familyEmoji = "🇮🇹"
			lifeState.MobState.rankIndex = 5
			lifeState.MobState.rankLevel = 5
			lifeState.MobState.rankName = "Boss"
			lifeState.MobState.rankEmoji = "👑"
			lifeState.MobState.respect = 15000
			lifeState.MobState.loyalty = 100
			lifeState.MobState.heat = 0
			lifeState.MobState.earnings = 5000000
			lifeState.Money = (lifeState.Money or 0) + 10000000
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.in_mob = true
			lifeState.Flags.mob_boss = true
			lifeState.Flags.mafia_member = true
			return true, "🔫👑 You are now THE BOSS of the Italian Mafia!"
		end,
	},
	-- CRITICAL FIX #304: Royalty preset
	{
		id = "royalty",
		name = "Become Royalty",
		emoji = "👑",
		description = "Become the King/Queen of a country",
		apply = function(self, lifeState)
			lifeState.RoyalState = lifeState.RoyalState or {}
			lifeState.RoyalState.isRoyal = true
			lifeState.RoyalState.isMonarch = true
			lifeState.RoyalState.country = "monaco"
			lifeState.RoyalState.countryName = "Monaco"
			lifeState.RoyalState.countryEmoji = "🇲🇨"
			lifeState.RoyalState.title = (lifeState.Gender == "Male") and "King" or "Queen"
			lifeState.RoyalState.lineOfSuccession = 0
			lifeState.RoyalState.popularity = 85
			lifeState.RoyalState.wealth = 500000000
			lifeState.Money = 500000000
			lifeState.Fame = 90
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.is_royalty = true
			lifeState.Flags.is_monarch = true
			return true, string.format("👑 You are now the %s of Monaco!", lifeState.RoyalState.title)
		end,
	},
}

function GodModeSystem:applyPreset(lifeState, presetId)
	for _, preset in ipairs(self.Presets) do
		if preset.id == presetId then
			return preset.apply(self, lifeState)
		end
	end
	return false, "Preset not found"
end

-- ════════════════════════════════════════════════════════════════════════════
-- SERIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

function GodModeSystem:getEditableStatsInfo()
	return self.EditableStats
end

function GodModeSystem:getEditablePropertiesInfo()
	return self.EditableProperties
end

function GodModeSystem:getClearableFlagsInfo()
	return self.ClearableFlags
end

function GodModeSystem:getPresetsInfo()
	local info = {}
	for _, preset in ipairs(self.Presets) do
		table.insert(info, {
			id = preset.id,
			name = preset.name,
			emoji = preset.emoji,
			description = preset.description,
		})
	end
	return info
end

function GodModeSystem:serializeForClient()
	return {
		editableStats = self:getEditableStatsInfo(),
		editableProperties = self:getEditablePropertiesInfo(),
		clearableFlags = self:getClearableFlagsInfo(),
		presets = self:getPresetsInfo(),
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #192-200: GOD MODE EVENT CARD OPTIONS
-- These are premium options that appear in event popups (greyed out if no God Mode)
-- Buying God Mode unlocks these special choices in event cards!
-- ════════════════════════════════════════════════════════════════════════════

-- God Mode options for different event categories
GodModeSystem.EventCardOptions = {
	-- Health events - cure instantly
	health = {
		{
			id = "god_mode_cure",
			text = "⚡ Cure Instantly (God Mode)",
			emoji = "⚡",
			description = "Use your divine powers to instantly cure any illness",
			action = "cure_disease",
			requiresGodMode = true,
		},
		{
			id = "god_mode_max_health",
			text = "⚡ Restore Full Health (God Mode)",
			emoji = "💪",
			description = "Restore your health to 100%",
			action = "max_health",
			requiresGodMode = true,
		},
	},
	-- Relationship events - instant success
	relationship = {
		{
			id = "god_mode_charm",
			text = "⚡ Use Irresistible Charm (God Mode)",
			emoji = "💕",
			description = "Guarantee they say yes to anything",
			action = "charm_success",
			requiresGodMode = true,
		},
		{
			id = "god_mode_fix_relationship",
			text = "⚡ Instantly Fix Relationship (God Mode)",
			emoji = "❤️‍🩹",
			description = "Repair any damaged relationship to 100%",
			action = "max_relationship",
			requiresGodMode = true,
		},
	},
	-- Career events - instant promotion
	career = {
		{
			id = "god_mode_promotion",
			text = "⚡ Force Promotion (God Mode)",
			emoji = "📈",
			description = "Instantly get promoted regardless of performance",
			action = "instant_promotion",
			requiresGodMode = true,
		},
		{
			id = "god_mode_salary",
			text = "⚡ Demand Huge Raise (God Mode)",
			emoji = "💰",
			description = "Triple your current salary",
			action = "triple_salary",
			requiresGodMode = true,
		},
	},
	-- Legal/crime events - escape consequences
	legal = {
		{
			id = "god_mode_escape",
			text = "⚡ Escape Justice (God Mode)",
			emoji = "🏃",
			description = "Avoid all legal consequences",
			action = "escape_jail",
			requiresGodMode = true,
		},
		{
			id = "god_mode_clear_record",
			text = "⚡ Erase Criminal Record (God Mode)",
			emoji = "📋",
			description = "Completely wipe your criminal history",
			action = "clear_record",
			requiresGodMode = true,
		},
	},
	-- Financial events - instant wealth
	financial = {
		{
			id = "god_mode_money",
			text = "⚡ Create Money (God Mode)",
			emoji = "🤑",
			description = "Generate $1 million out of thin air",
			action = "create_money",
			amount = 1000000,
			requiresGodMode = true,
		},
		{
			id = "god_mode_clear_debt",
			text = "⚡ Clear All Debt (God Mode)",
			emoji = "💳",
			description = "Erase all your debts instantly",
			action = "clear_debt",
			requiresGodMode = true,
		},
	},
	-- Mafia events - special mob powers
	-- CRITICAL FIX #211-220: Expanded Mafia God Mode Options
	mafia = {
		{
			id = "god_mode_respect",
			text = "⚡ Demand Respect (God Mode)",
			emoji = "👑",
			description = "Instantly gain 500 respect",
			action = "add_respect",
			amount = 500,
			requiresGodMode = true,
		},
		{
			id = "god_mode_clear_heat",
			text = "⚡ Eliminate Heat (God Mode)",
			emoji = "❄️",
			description = "Clear all police heat instantly",
			action = "clear_heat",
			requiresGodMode = true,
		},
		{
			id = "god_mode_rank_up",
			text = "⚡ Force Rank Up (God Mode)",
			emoji = "🎖️",
			description = "Instantly rise to the next rank",
			action = "rank_up",
			requiresGodMode = true,
		},
		{
			id = "god_mode_become_boss",
			text = "⚡ Seize Control as Boss (God Mode)",
			emoji = "🔫👑",
			description = "Instantly become the Boss of your family",
			action = "become_mafia_boss",
			requiresGodMode = true,
		},
		{
			id = "god_mode_max_loyalty",
			text = "⚡ Max Loyalty (God Mode)",
			emoji = "🤝",
			description = "Set loyalty to 100% - the family trusts you completely",
			action = "max_loyalty",
			requiresGodMode = true,
		},
		{
			id = "god_mode_operation_success",
			text = "⚡ Guarantee Success (God Mode)",
			emoji = "✅",
			description = "This operation will succeed with max rewards",
			action = "operation_success",
			requiresGodMode = true,
		},
		{
			id = "god_mode_mafia_money",
			text = "⚡ Skim $1M (God Mode)",
			emoji = "💵",
			description = "Take $1 million from family earnings (no consequences)",
			action = "mafia_money",
			amount = 1000000,
			requiresGodMode = true,
		},
		{
			id = "god_mode_eliminate_rival",
			text = "⚡ Eliminate Rival (God Mode)",
			emoji = "💀",
			description = "Take out a rival with no heat or consequences",
			action = "eliminate_rival",
			requiresGodMode = true,
		},
		{
			id = "god_mode_leave_mob_safe",
			text = "⚡ Leave Safely (God Mode)",
			emoji = "🚪",
			description = "Leave the mob with no consequences - keep your money",
			action = "leave_mob_safely",
			requiresGodMode = true,
		},
		{
			id = "god_mode_max_notoriety",
			text = "⚡ Legendary Status (God Mode)",
			emoji = "⭐",
			description = "Become a legendary figure in the underworld",
			action = "max_notoriety",
			requiresGodMode = true,
		},
	},
	-- Royalty events - royal powers
	royalty = {
		{
			id = "god_mode_popularity",
			text = "⚡ Max Popularity (God Mode)",
			emoji = "👸",
			description = "Boost royal popularity to 100%",
			action = "max_popularity",
			requiresGodMode = true,
		},
		{
			id = "god_mode_no_scandal",
			text = "⚡ Cover Up Scandal (God Mode)",
			emoji = "🤫",
			description = "Make any scandal disappear",
			action = "clear_scandal",
			requiresGodMode = true,
		},
		{
			id = "god_mode_become_monarch",
			text = "⚡ Seize the Throne (God Mode)",
			emoji = "👑",
			description = "Instantly become the ruling monarch",
			action = "become_monarch",
			requiresGodMode = true,
		},
	},
	-- Celebrity events - fame powers
	celebrity = {
		{
			id = "god_mode_viral",
			text = "⚡ Go Viral (God Mode)",
			emoji = "📱",
			description = "Instantly gain 1 million followers",
			action = "add_followers",
			amount = 1000000,
			requiresGodMode = true,
		},
		{
			id = "god_mode_award",
			text = "⚡ Win Award (God Mode)",
			emoji = "🏆",
			description = "Guarantee winning the award",
			action = "win_award",
			requiresGodMode = true,
		},
	},
	-- General - universal powers
	general = {
		{
			id = "god_mode_perfect_outcome",
			text = "⚡ Perfect Outcome (God Mode)",
			emoji = "✨",
			description = "Guarantee the best possible result",
			action = "perfect_outcome",
			requiresGodMode = true,
		},
	},
}

-- Get God Mode options for an event card
function GodModeSystem:getEventCardOptions(eventDef, hasGodMode)
	local options = {}
	local category = eventDef.category or eventDef._category or "general"
	
	-- Get category-specific options
	local categoryOptions = self.EventCardOptions[category] or self.EventCardOptions["general"]
	
	for _, option in ipairs(categoryOptions) do
		table.insert(options, {
			id = option.id,
			text = option.text,
			emoji = option.emoji,
			description = option.description,
			action = option.action,
			amount = option.amount,
			requiresGodMode = true,
			isLocked = not hasGodMode, -- GREYED OUT if no God Mode
			lockedReason = not hasGodMode and "Requires God Mode Gamepass" or nil,
		})
	end
	
	-- Also add general options
	if category ~= "general" then
		for _, option in ipairs(self.EventCardOptions["general"]) do
			table.insert(options, {
				id = option.id,
				text = option.text,
				emoji = option.emoji,
				description = option.description,
				action = option.action,
				requiresGodMode = true,
				isLocked = not hasGodMode,
				lockedReason = not hasGodMode and "Requires God Mode Gamepass" or nil,
			})
		end
	end
	
	return options
end

-- Execute a God Mode event card option
function GodModeSystem:executeEventCardOption(lifeState, optionId)
	-- Find the option
	local option = nil
	for category, options in pairs(self.EventCardOptions) do
		for _, opt in ipairs(options) do
			if opt.id == optionId then
				option = opt
				break
			end
		end
		if option then break end
	end
	
	if not option then
		return false, "Invalid God Mode option"
	end
	
	-- Execute the action
	local action = option.action
	local message = ""
	
	if action == "cure_disease" then
		return self:cureDiseases(lifeState)
	elseif action == "max_health" then
		return self:editStat(lifeState, "Health", 100)
	elseif action == "charm_success" then
		-- Set flag for next relationship interaction
		lifeState.Flags = lifeState.Flags or {}
		lifeState.Flags.god_mode_charm_active = true
		return true, "💕 Your charm is irresistible! They'll say yes!"
	elseif action == "max_relationship" then
		return self:maxAllRelationships(lifeState)
	elseif action == "instant_promotion" then
		if lifeState.CareerInfo then
			lifeState.CareerInfo.promotionProgress = 100
			lifeState.CareerInfo.performance = 100
		end
		lifeState.Flags = lifeState.Flags or {}
		lifeState.Flags.god_mode_promotion_pending = true
		return true, "📈 Promotion guaranteed on your next work day!"
	elseif action == "triple_salary" then
		if lifeState.CurrentJob and lifeState.CurrentJob.salary then
			lifeState.CurrentJob.salary = lifeState.CurrentJob.salary * 3
			return true, string.format("💰 Salary tripled to $%s!", self:formatMoney(lifeState.CurrentJob.salary))
		end
		return false, "No current job to increase salary"
	elseif action == "escape_jail" then
		return self:releaseFromJail(lifeState)
	elseif action == "clear_record" then
		return self:clearCriminalRecord(lifeState)
	elseif action == "create_money" then
		local amount = option.amount or 1000000
		lifeState.Money = (lifeState.Money or 0) + amount
		return true, string.format("🤑 Created $%s out of thin air!", self:formatMoney(amount))
	elseif action == "clear_debt" then
		return self:clearDebt(lifeState)
	elseif action == "add_respect" then
		if lifeState.MobState then
			lifeState.MobState.respect = (lifeState.MobState.respect or 0) + (option.amount or 500)
			return true, string.format("👑 Gained %d respect!", option.amount or 500)
		end
		return false, "Not in a crime family"
	elseif action == "clear_heat" then
		if lifeState.MobState then
			lifeState.MobState.heat = 0
			return true, "❄️ All heat eliminated! The cops have forgotten you."
		end
		return false, "Not in a crime family"
	elseif action == "rank_up" then
		if lifeState.MobState and lifeState.MobState.inMob then
			lifeState.MobState.rankIndex = math.min(5, (lifeState.MobState.rankIndex or 1) + 1)
			lifeState.MobState.rankLevel = lifeState.MobState.rankIndex
			-- Update rank name and emoji based on index
			local rankNames = {"Associate", "Soldier", "Caporegime", "Underboss", "Boss"}
			local rankEmojis = {"👤", "🔫", "💰", "🎩", "👑"}
			lifeState.MobState.rankName = rankNames[lifeState.MobState.rankIndex] or "Associate"
			lifeState.MobState.rankEmoji = rankEmojis[lifeState.MobState.rankIndex] or "👤"
			return true, string.format("🎖️ Promoted to %s %s!", lifeState.MobState.rankEmoji, lifeState.MobState.rankName)
		end
		return false, "Not in a crime family"
	-- CRITICAL FIX #221-230: NEW MAFIA GOD MODE ACTIONS
	elseif action == "become_mafia_boss" then
		if lifeState.MobState and lifeState.MobState.inMob then
			lifeState.MobState.rankIndex = 5
			lifeState.MobState.rankLevel = 5
			lifeState.MobState.rankName = "Boss"
			lifeState.MobState.rankEmoji = "👑"
			lifeState.MobState.respect = math.max(lifeState.MobState.respect or 0, 10000)
			lifeState.MobState.loyalty = 100
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.mob_boss = true
			lifeState.Flags.underboss = nil
			lifeState.Flags.is_capo = true
			return true, "👑 You are now the BOSS! The entire family answers to you!"
		end
		return false, "Not in a crime family"
	elseif action == "max_loyalty" then
		if lifeState.MobState then
			lifeState.MobState.loyalty = 100
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.trusted_by_boss = true
			lifeState.Flags.inner_circle = true
			return true, "🤝 Loyalty maxed! The family trusts you completely!"
		end
		return false, "Not in a crime family"
	elseif action == "operation_success" then
		lifeState.Flags = lifeState.Flags or {}
		lifeState.Flags.god_mode_operation_guaranteed = true
		return true, "✅ Your next operation is guaranteed to succeed with maximum rewards!"
	elseif action == "mafia_money" then
		local amount = option.amount or 1000000
		lifeState.Money = (lifeState.Money or 0) + amount
		if lifeState.MobState then
			lifeState.MobState.earnings = (lifeState.MobState.earnings or 0) + amount
		end
		return true, string.format("💵 Skimmed $%s from family earnings with no consequences!", self:formatMoney(amount))
	elseif action == "eliminate_rival" then
		if lifeState.MobState and lifeState.MobState.inMob then
			lifeState.MobState.respect = (lifeState.MobState.respect or 0) + 100
			lifeState.MobState.kills = (lifeState.MobState.kills or 0) + 1
			-- NO heat increase - God Mode protects you
			return true, "💀 Rival eliminated with divine protection! +100 respect, no heat!"
		end
		return false, "Not in a crime family"
	elseif action == "leave_mob_safely" then
		if lifeState.MobState and lifeState.MobState.inMob then
			-- Keep all money and stats
			local earnings = lifeState.MobState.earnings or 0
			
			-- Reset mob state but keep money
			lifeState.MobState.inMob = false
			lifeState.MobState.familyId = nil
			lifeState.MobState.heat = 0
			
			-- Clear mob-related flags
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.in_mob = nil
			lifeState.Flags.mob_boss = nil
			lifeState.Flags.underboss = nil
			lifeState.Flags.is_capo = nil
			lifeState.Flags.mob_fugitive = nil
			lifeState.Flags.hit_on_you = nil
			
			return true, string.format("🚪 Left the mob safely! Kept $%s in earnings. The family respected your decision.", self:formatMoney(earnings))
		end
		return false, "Not in a crime family"
	elseif action == "max_notoriety" then
		if lifeState.MobState and lifeState.MobState.inMob then
			lifeState.MobState.notoriety = 100
			lifeState.MobState.respect = math.max(lifeState.MobState.respect or 0, 5000)
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.legendary_mobster = true
			lifeState.Flags.feared = true
			return true, "⭐ You are now a LEGENDARY figure in the underworld! Everyone knows your name!"
		end
		return false, "Not in a crime family"
	elseif action == "max_popularity" then
		if lifeState.RoyalState then
			lifeState.RoyalState.popularity = 100
			return true, "👸 Royal popularity maxed at 100%!"
		end
		return false, "Not royalty"
	elseif action == "clear_scandal" then
		if lifeState.RoyalState then
			lifeState.RoyalState.scandals = 0
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.scandal = nil
			lifeState.Flags.royal_scandal = nil
			return true, "🤫 All scandals covered up successfully!"
		end
		return false, "Not royalty"
	elseif action == "become_monarch" then
		if lifeState.RoyalState and lifeState.RoyalState.isRoyal then
			lifeState.RoyalState.isMonarch = true
			lifeState.RoyalState.lineOfSuccession = 0
			local gender = (lifeState.Gender or "Male"):lower()
			lifeState.RoyalState.title = gender == "male" and "King" or "Queen"
			return true, string.format("👑 You are now the %s! Long may you reign!", lifeState.RoyalState.title)
		end
		return false, "Not royalty"
	elseif action == "add_followers" then
		lifeState.FameState = lifeState.FameState or {}
		lifeState.FameState.followers = (lifeState.FameState.followers or 0) + (option.amount or 1000000)
		lifeState.Fame = math.min(100, (lifeState.Fame or 0) + 20)
		return true, string.format("📱 Gained %s followers! Fame increased!", self:formatMoney(option.amount or 1000000))
	elseif action == "win_award" then
		lifeState.FameState = lifeState.FameState or {}
		lifeState.FameState.awards = lifeState.FameState.awards or {}
		table.insert(lifeState.FameState.awards, {
			name = "God Mode Award",
			year = lifeState.Year or 2025,
		})
		lifeState.Fame = math.min(100, (lifeState.Fame or 0) + 15)
		return true, "🏆 Award won! Your fame increases!"
	elseif action == "perfect_outcome" then
		lifeState.Flags = lifeState.Flags or {}
		lifeState.Flags.god_mode_perfect_outcome = true
		return true, "✨ The universe bends to your will! Perfect outcome guaranteed!"
	end
	
	return false, "Unknown action"
end

-- CRITICAL FIX #201: Edit Age (within limits)
function GodModeSystem:editAge(lifeState, newAge)
	local currentAge = lifeState.Age or 0
	newAge = math.clamp(tonumber(newAge) or currentAge, 0, 120)
	newAge = math.floor(newAge)
	
	local ageDiff = newAge - currentAge
	
	lifeState.Age = newAge
	lifeState.Year = (lifeState.Year or 2025) + ageDiff
	
	-- Track edit
	if lifeState.GodModeState then
		lifeState.GodModeState.editsThisLife = (lifeState.GodModeState.editsThisLife or 0) + 1
		lifeState.GodModeState.lastEditAge = newAge
	end
	
	return true, string.format("🕐 Age changed to %d", newAge)
end

-- CRITICAL FIX #202: Set max skills for career
function GodModeSystem:maxSkills(lifeState)
	lifeState.CareerInfo = lifeState.CareerInfo or {}
	lifeState.CareerInfo.skills = lifeState.CareerInfo.skills or {}
	
	local skillTypes = {"communication", "leadership", "technical", "creativity", "sales", "management"}
	for _, skill in ipairs(skillTypes) do
		lifeState.CareerInfo.skills[skill] = 100
	end
	
	lifeState.CareerInfo.performance = 100
	
	return true, "🎯 All skills maxed to 100%!"
end

-- CRITICAL FIX #203: Get current health conditions for display
function GodModeSystem:getHealthConditions(lifeState)
	local conditions = {}
	local flags = lifeState.Flags or {}
	
	-- Check all disease/condition flags
	local conditionMap = {
		-- STDs
		has_std = { name = "STD", emoji = "🦠", severity = "serious" },
		hiv_positive = { name = "HIV Positive", emoji = "🩸", severity = "critical" },
		hepatitis = { name = "Hepatitis", emoji = "🦠", severity = "serious" },
		herpes = { name = "Herpes", emoji = "🦠", severity = "chronic" },
		chlamydia = { name = "Chlamydia", emoji = "🦠", severity = "treatable" },
		gonorrhea = { name = "Gonorrhea", emoji = "🦠", severity = "treatable" },
		-- Cancer
		has_cancer = { name = "Cancer", emoji = "🎗️", severity = "critical" },
		cancer = { name = "Cancer", emoji = "🎗️", severity = "critical" },
		tumor = { name = "Tumor", emoji = "🎗️", severity = "serious" },
		leukemia = { name = "Leukemia", emoji = "🎗️", severity = "critical" },
		-- Chronic conditions
		chronic_illness = { name = "Chronic Illness", emoji = "💊", severity = "chronic" },
		terminal_illness = { name = "Terminal Illness", emoji = "⚠️", severity = "terminal" },
		diabetes = { name = "Diabetes", emoji = "💉", severity = "chronic" },
		heart_disease = { name = "Heart Disease", emoji = "❤️‍🩹", severity = "serious" },
		lung_disease = { name = "Lung Disease", emoji = "🫁", severity = "serious" },
		kidney_disease = { name = "Kidney Disease", emoji = "💊", severity = "serious" },
		liver_disease = { name = "Liver Disease", emoji = "💊", severity = "serious" },
		-- Mental health
		mental_illness = { name = "Mental Illness", emoji = "🧠", severity = "chronic" },
		depression = { name = "Depression", emoji = "😔", severity = "chronic" },
		anxiety = { name = "Anxiety", emoji = "😰", severity = "chronic" },
		bipolar = { name = "Bipolar Disorder", emoji = "🔄", severity = "chronic" },
		schizophrenia = { name = "Schizophrenia", emoji = "🧠", severity = "serious" },
		ptsd = { name = "PTSD", emoji = "😖", severity = "chronic" },
		ocd = { name = "OCD", emoji = "🔁", severity = "chronic" },
		adhd = { name = "ADHD", emoji = "⚡", severity = "chronic" },
		insomnia = { name = "Insomnia", emoji = "😴", severity = "chronic" },
		eating_disorder = { name = "Eating Disorder", emoji = "🍽️", severity = "serious" },
		-- Physical
		injured = { name = "Injured", emoji = "🩹", severity = "temporary" },
		seriously_injured = { name = "Seriously Injured", emoji = "🏥", severity = "serious" },
		hospitalized = { name = "Hospitalized", emoji = "🏥", severity = "serious" },
		disabled = { name = "Disabled", emoji = "♿", severity = "permanent" },
		paralyzed = { name = "Paralyzed", emoji = "♿", severity = "permanent" },
		broken_bone = { name = "Broken Bone", emoji = "🦴", severity = "temporary" },
		-- Misc
		sick = { name = "Sick", emoji = "🤒", severity = "temporary" },
		prolonged_illness = { name = "Prolonged Illness", emoji = "🤒", severity = "chronic" },
		food_poisoning = { name = "Food Poisoning", emoji = "🤢", severity = "temporary" },
	}
	
	for flag, info in pairs(conditionMap) do
		if flags[flag] then
			table.insert(conditions, {
				id = flag,
				name = info.name,
				emoji = info.emoji,
				severity = info.severity,
			})
		end
	end
	
	return conditions
end

-- CRITICAL FIX #204: Get current addictions for display
function GodModeSystem:getAddictions(lifeState)
	local addictions = {}
	local flags = lifeState.Flags or {}
	
	local addictionMap = {
		alcoholic = { name = "Alcoholism", emoji = "🍺", severity = "serious" },
		alcohol_addiction = { name = "Alcohol Addiction", emoji = "🍺", severity = "serious" },
		drug_addict = { name = "Drug Addiction", emoji = "💊", severity = "critical" },
		cocaine_addiction = { name = "Cocaine Addiction", emoji = "❄️", severity = "critical" },
		heroin_addiction = { name = "Heroin Addiction", emoji = "💉", severity = "critical" },
		meth_addiction = { name = "Meth Addiction", emoji = "💊", severity = "critical" },
		pill_addiction = { name = "Pill Addiction", emoji = "💊", severity = "serious" },
		opioid_addiction = { name = "Opioid Addiction", emoji = "💊", severity = "critical" },
		nicotine_addict = { name = "Nicotine Addiction", emoji = "🚬", severity = "moderate" },
		smoking_addiction = { name = "Smoking Addiction", emoji = "🚬", severity = "moderate" },
		gambling_addict = { name = "Gambling Addiction", emoji = "🎰", severity = "serious" },
		gambling_addiction = { name = "Gambling Addiction", emoji = "🎰", severity = "serious" },
		marijuana_addiction = { name = "Marijuana Addiction", emoji = "🌿", severity = "moderate" },
		gaming_addiction = { name = "Gaming Addiction", emoji = "🎮", severity = "moderate" },
		social_media_addiction = { name = "Social Media Addiction", emoji = "📱", severity = "moderate" },
		shopping_addiction = { name = "Shopping Addiction", emoji = "🛍️", severity = "moderate" },
	}
	
	for flag, info in pairs(addictionMap) do
		if flags[flag] then
			table.insert(addictions, {
				id = flag,
				name = info.name,
				emoji = info.emoji,
				severity = info.severity,
			})
		end
	end
	
	return addictions
end

-- ════════════════════════════════════════════════════════════════════════════
-- SINGLETON INSTANCE
-- ════════════════════════════════════════════════════════════════════════════

local instance = GodModeSystem.new()

return instance
