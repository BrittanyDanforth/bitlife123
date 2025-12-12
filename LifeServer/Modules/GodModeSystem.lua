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
	
	-- Clear all criminal-related flags
	local criminalFlags = {
		"criminal_record", "convicted_felon", "arrested", "prison_record",
		"on_probation", "on_parole", "warrant", "fugitive", "felon",
		"murderer", "thief", "drug_dealer", "violent_criminal",
	}
	
	for _, flag in ipairs(criminalFlags) do
		flags[flag] = nil
	end
	
	lifeState.Flags = flags
	
	-- Clear jail state
	lifeState.InJail = false
	lifeState.JailYearsLeft = 0
	
	return true, "📋 Criminal record cleared!"
end

function GodModeSystem:cureDiseases(lifeState)
	local flags = lifeState.Flags or {}
	
	-- Clear all disease-related flags
	local diseaseFlags = {
		"has_std", "has_cancer", "chronic_illness", "terminal_illness",
		"mental_illness", "depression", "anxiety", "bipolar", "schizophrenia",
		"hiv_positive", "hepatitis", "diabetes", "heart_disease",
	}
	
	for _, flag in ipairs(diseaseFlags) do
		flags[flag] = nil
	end
	
	lifeState.Flags = flags
	
	-- Boost health
	if lifeState.Stats then
		lifeState.Stats.Health = math.min(100, (lifeState.Stats.Health or 50) + 30)
		lifeState.Health = lifeState.Stats.Health
	end
	
	return true, "💊 All diseases cured! Health improved."
end

function GodModeSystem:removeAddictions(lifeState)
	local flags = lifeState.Flags or {}
	
	-- Clear all addiction-related flags
	local addictionFlags = {
		"alcoholic", "drug_addict", "gambling_addict", "nicotine_addict",
		"addicted", "substance_abuse", "recovering_addict", "rehab_needed",
	}
	
	for _, flag in ipairs(addictionFlags) do
		flags[flag] = nil
	end
	
	lifeState.Flags = flags
	
	-- Boost happiness
	if lifeState.Stats then
		lifeState.Stats.Happiness = math.min(100, (lifeState.Stats.Happiness or 50) + 20)
		lifeState.Happiness = lifeState.Stats.Happiness
	end
	
	return true, "🚭 All addictions removed! Happiness improved."
end

function GodModeSystem:clearDebt(lifeState)
	-- Clear education debt
	if lifeState.EducationData then
		lifeState.EducationData.Debt = 0
	end
	
	-- Clear any debt flags
	local flags = lifeState.Flags or {}
	flags.in_debt = nil
	flags.bankrupt = nil
	flags.loan_default = nil
	lifeState.Flags = flags
	
	return true, "💳 All debt cleared!"
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
			count = count + 1
		end
	end
	
	return true, string.format("💕 Maximized %d relationships to 100%%!", count)
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
	{
		id = "rich",
		name = "Billionaire",
		emoji = "💎",
		description = "Set money to $1 billion",
		apply = function(self, lifeState)
			lifeState.Money = 1000000000
			return true, "💎 You're now a billionaire!"
		end,
	},
	{
		id = "famous",
		name = "Famous",
		emoji = "⭐",
		description = "Max fame to 100",
		apply = function(self, lifeState)
			lifeState.Fame = 100
			if lifeState.FameState then
				lifeState.FameState.isFamous = true
				lifeState.FameState.fameLevel = "Legend"
			end
			return true, "⭐ You're now legendary famous!"
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
-- SINGLETON INSTANCE
-- ════════════════════════════════════════════════════════════════════════════

local instance = GodModeSystem.new()

return instance
