local LifeBackend = {}
LifeBackend.__index = LifeBackend

local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- ════════════════════════════════════════════════════════════════════════════════
-- DATA PERSISTENCE SYSTEM
-- Auto-saves player progress on leave/rejoin so they continue where they left off
-- ════════════════════════════════════════════════════════════════════════════════

local DATA_STORE_NAME = "BitLifePlayerData_v1"
local playerDataStore = nil

-- Initialize DataStore (wrapped in pcall for Studio testing)
local function initDataStore()
	if playerDataStore then return playerDataStore end
	local success, store = pcall(function()
		return DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)
	if success then
		playerDataStore = store
		print("[LifeBackend] DataStore initialized:", DATA_STORE_NAME)
	else
		warn("[LifeBackend] Failed to initialize DataStore:", store)
	end
	return playerDataStore
end

-- Serialize state for saving (removes non-serializable data)
local function serializeState(state)
	if not state then return nil end

	local serialized = {}

	-- Core info - CRITICAL: Use correct field names
	serialized.Name = state.Name  -- Full name like "John Smith"
	serialized.Gender = state.Gender
	serialized.Age = state.Age
	serialized.Money = state.Money
	serialized.Fame = state.Fame
	serialized.Karma = state.Karma
	serialized.Country = state.Country
	serialized.City = state.City
	serialized.BirthYear = state.BirthYear

	-- Stats table
	if state.Stats then
		serialized.Stats = {
			Health = state.Stats.Health,
			Happiness = state.Stats.Happiness,
			Smarts = state.Stats.Smarts,
			Looks = state.Stats.Looks,
		}
	end

	-- Flags (all of them - they're all serializable)
	if state.Flags then
		serialized.Flags = {}
		for k, v in pairs(state.Flags) do
			if type(v) ~= "function" and type(v) ~= "userdata" then
				serialized.Flags[k] = v
			end
		end
	end

	-- CRITICAL: Add flag to indicate this is restored data (skip intro!)
	serialized.Flags = serialized.Flags or {}
	serialized.Flags.data_restored = true

	-- Career info
	if state.CurrentJob then
		serialized.CurrentJob = state.CurrentJob
	end
	if state.CareerInfo then
		serialized.CareerInfo = state.CareerInfo
	end

	-- Relationships (simplified for storage)
	if state.Relationships then
		serialized.Relationships = {}
		for id, rel in pairs(state.Relationships) do
			if type(rel) == "table" then
				serialized.Relationships[id] = {
					id = rel.id,
					type = rel.type,
					name = rel.name,
					age = rel.age,
					relationship = rel.relationship,
					alive = rel.alive,
					gender = rel.gender,
				}
			end
		end
	end

	-- Premium states
	if state.RoyalState then
		serialized.RoyalState = state.RoyalState
	end
	if state.MobState then
		serialized.MobState = state.MobState
	end
	if state.FameState then
		serialized.FameState = state.FameState
	end

	-- Gamepass ownership (critical for persistence)
	if state.GamepassOwnership then
		serialized.GamepassOwnership = state.GamepassOwnership
	end

	-- Education
	serialized.Education = state.Education

	-- Assets
	if state.Assets then
		serialized.Assets = state.Assets
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #PERSIST-1: Save EventHistory to persist cooldowns and one-time events!
	-- Without this, event cooldowns reset on rejoin and one-time events can repeat!
	-- User complaint: "Events don't trigger properly" - because history was lost on rejoin
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.EventHistory then
		serialized.EventHistory = state.EventHistory
	end

	-- CRITICAL FIX #PERSIST-2: Save FinancialState to track years broke for homeless events
	if state.FinancialState then
		serialized.FinancialState = state.FinancialState
	end

	-- Timestamp for debugging
	serialized._savedAt = os.time()
	serialized._version = 1

	return serialized
end

-- Deserialize state from loaded data
local function deserializeState(data, player)
	if not data then return nil end

	-- Return the data as-is, the onPlayerAdded will merge it with fresh state
	return data
end

-- Save player data to DataStore
function LifeBackend:savePlayerData(player)
	local store = initDataStore()
	if not store then
		warn("[LifeBackend] Cannot save - DataStore not available")
		return false
	end

	local state = self.playerStates[player]
	if not state then
		warn("[LifeBackend] Cannot save - no state for player:", player.Name)
		return false
	end

	local serialized = serializeState(state)
	if not serialized then
		warn("[LifeBackend] Cannot save - serialization failed")
		return false
	end

	local key = "Player_" .. player.UserId

	local success, err = pcall(function()
		store:SetAsync(key, serialized)
	end)

	if success then
		print("[LifeBackend] ✅ Saved data for", player.Name, "Age:", serialized.Age or "?")
		return true
	else
		warn("[LifeBackend] ❌ Failed to save data for", player.Name, "Error:", err)
		return false
	end
end

-- Load player data from DataStore
function LifeBackend:loadPlayerData(player)
	local store = initDataStore()
	if not store then
		print("[LifeBackend] DataStore not available - starting fresh")
		return nil
	end

	local key = "Player_" .. player.UserId

	local success, data = pcall(function()
		return store:GetAsync(key)
	end)

	if success and data then
		print("[LifeBackend] ✅ Loaded saved data for", player.Name, "Age:", data.Age or "?", "Saved at:", data._savedAt or "?")
		return deserializeState(data, player)
	elseif success then
		print("[LifeBackend] No saved data for", player.Name, "- starting new life")
		return nil
	else
		warn("[LifeBackend] ❌ Failed to load data for", player.Name, "Error:", data)
		return nil
	end
end

-- Auto-save all players (for periodic saves and shutdown)
function LifeBackend:saveAllPlayers()
	local savedCount = 0
	for player, state in pairs(self.playerStates) do
		if player and player.Parent then -- Player still in game
			if self:savePlayerData(player) then
				savedCount = savedCount + 1
			end
		end
	end
	print("[LifeBackend] Auto-saved", savedCount, "players")
	return savedCount
end

-- Clear saved data (called when player starts a NEW life/rebirth)
-- This ensures they don't reload their old life when rejoining
function LifeBackend:clearSaveData(player)
	local store = initDataStore()
	if not store then
		warn("[LifeBackend] Cannot clear save - DataStore not available")
		return false
	end

	local key = "Player_" .. player.UserId

	local success, err = pcall(function()
		store:RemoveAsync(key)
	end)

	if success then
		print("[LifeBackend] 🗑️ Cleared saved data for", player.Name, "(starting new life)")
		return true
	else
		warn("[LifeBackend] ❌ Failed to clear save data:", err)
		return false
	end
end

local GamepassSystem

function LifeBackend:checkGamepassOwnership(player, gamepassKey)
	if not player then
		return false
	end

	local success, owns = pcall(function()
		return GamepassSystem:checkOwnership(player, gamepassKey)
	end)

	if not success then
		warn(string.format("[LifeBackend] Failed to check %s ownership: %s", tostring(gamepassKey), tostring(owns)))
		return false
	end

	return owns
end

function LifeBackend:promptGamepassPurchase(player, gamepassKey)
	if not player then
		return
	end

	local success, err = pcall(function()
		GamepassSystem:promptGamepass(player, gamepassKey)
	end)

	if not success then
		warn(string.format("[LifeBackend] Failed to prompt %s purchase: %s", tostring(gamepassKey), tostring(err)))
	end
end

-- CRITICAL FIX #358: Developer Product purchase prompt
function LifeBackend:promptProductPurchase(player, productKey)
	if not player then
		return
	end

	local success, err = pcall(function()
		GamepassSystem:promptProduct(player, productKey)
	end)

	if not success then
		warn(string.format("[LifeBackend] Failed to prompt product %s purchase: %s", tostring(productKey), tostring(err)))
	end
end

-- CRITICAL FIX #360: Set up ProcessReceipt for Developer Products
function LifeBackend:setupProcessReceipt()
	local self = self
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local result = GamepassSystem:processProductReceipt(
			receiptInfo,
			function(player) return self:getState(player) end,
			function(player, years) return self:executeTimeMachineAction(player, years) end
		)
		return result
	end
	print("[LifeBackend] ProcessReceipt handler set up for Developer Products")
end

-- CRITICAL FIX #361: Set up gamepass purchase listener for UI refresh
function LifeBackend:setupGamepassPurchaseListener()
	-- Listen for gamepass purchase completion
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then return end
		
		-- Find which gamepass was purchased
		local GAMEPASS_IDS = {
			ROYALTY = 1626378001,
			GOD_MODE = 1628050729,
			MAFIA = 1626238769,
			CELEBRITY = 1626461980,
			TIME_MACHINE = 1630681215,
		}
		
		local purchasedKey = nil
		for key, id in pairs(GAMEPASS_IDS) do
			if id == gamePassId then
				purchasedKey = key
				break
			end
		end
		
		if purchasedKey then
			print("[LifeBackend] Gamepass purchased:", purchasedKey, "by player:", player.Name)
			
			-- Clear ownership cache to force re-check
			GamepassSystem:notifyGamepassPurchased(player, purchasedKey)
			
			-- CRITICAL FIX #402: Update player state flags AND GamepassOwnership
			local state = self:getState(player)
			if state then
				state.Flags = state.Flags or {}
				state.GamepassOwnership = state.GamepassOwnership or {}
				
				if purchasedKey == "ROYALTY" then
					state.Flags.royalty_gamepass = true
					state.GamepassOwnership.royalty = true
				elseif purchasedKey == "GOD_MODE" then
					state.Flags.god_mode_gamepass = true
					state.GamepassOwnership.godMode = true
					-- CRITICAL FIX #403: Initialize GodModeState when purchased
					state.GodModeState = state.GodModeState or {}
					state.GodModeState.enabled = true
				elseif purchasedKey == "MAFIA" then
					state.Flags.mafia_gamepass = true
					state.GamepassOwnership.mafia = true
				elseif purchasedKey == "CELEBRITY" then
					state.Flags.celebrity_gamepass = true
					state.GamepassOwnership.celebrity = true
				elseif purchasedKey == "TIME_MACHINE" then
					state.Flags.time_machine_gamepass = true
					state.GamepassOwnership.timeMachine = true
				end
			end
			
			-- CRITICAL FIX #359: Notify client that gamepass was purchased
			if self.remotes and self.remotes.GamepassPurchased then
				self.remotes.GamepassPurchased:FireClient(player, purchasedKey)
			end
			
			-- Also push state to refresh UI
			self:pushState(player, "🎉 " .. purchasedKey .. " unlocked!")
		end
	end)
	
	print("[LifeBackend] Gamepass purchase listener set up")
end

-- CRITICAL FIX #360: Execute time machine action (called from ProcessReceipt)
function LifeBackend:executeTimeMachineAction(player, yearsBack)
	-- This is called from ProcessReceipt after a developer product is purchased
	-- It bypasses the gamepass check since the player paid for this specific use
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end
	
	-- Execute the time travel (same logic as handleTimeMachine but without gamepass check)
	local currentAge = state.Age
	local targetAge = yearsBack == -1 and 0 or (currentAge - yearsBack)
	
	if targetAge < 0 then
		targetAge = 0
	end
	
	local yearsRewound = currentAge - targetAge
	
	-- Reset death state
	state.Flags = state.Flags or {}
	state.Flags.dead = nil
	state.DeathReason = nil
	state.DeathAge = nil
	state.DeathYear = nil
	state.CauseOfDeath = nil
	
	-- Reset to target age
	state.Age = targetAge
	state.Year = state.Year - yearsRewound
	
	-- Rewind family members' ages
	if state.Relationships then
		for relId, rel in pairs(state.Relationships) do
			if type(rel) == "table" and rel.age and type(rel.age) == "number" then
				rel.age = rel.age - yearsRewound
				if relId == "mother" or relId == "father" then
					rel.age = math.max(rel.age, 20)
				elseif relId:find("grand") then
					rel.age = math.max(rel.age, 50)
				else
					rel.age = math.max(rel.age, 0)
				end
				
				-- Resurrect family who died after this point
				if rel.deceased and rel.deathAge then
					if rel.age < rel.deathAge then
						rel.alive = true
						rel.deceased = nil
						rel.deathAge = nil
						rel.deathYear = nil
					end
				end
			end
		end
	end
	
	-- Reset stats based on age
	if targetAge == 0 then
		state.Stats = state.Stats or {}
		state.Stats.Happiness = 90
		state.Stats.Health = 100
		state.Health = 100
		state.Happiness = 90
		state.Money = 0
		state.Education = "none"
		state.CurrentJob = nil
		state.Career = {}
	else
		-- Partial reset - restore some stats
		state.Stats = state.Stats or {}
		state.Stats.Health = math.min(100, (state.Stats.Health or 50) + 30)
		state.Health = state.Stats.Health
	end
	
	-- Clear pending action
	GamepassSystem:clearPendingTimeMachine(player)
	
	-- Push state to refresh client
	local feed = string.format("⏰ Time Machine activated! You're now %d years old!", targetAge)
	self:pushState(player, feed)
	
	return { 
		success = true, 
		message = feed,
		newAge = targetAge,
		yearsRewound = yearsRewound
	}
end

--[[
	LifeBackend.lua

	This module implements a stateful BitLife-style backend that powers all of the premium
	client screens in this repository. It owns the authoritative player state, surfaces
	consistent remotes under ReplicatedStorage/LifeRemotes, and generates contextual events
	for 100+ careers, activities, assets, and story paths.

	The goals of this backend are:
	1. Deterministic, career-aware events (no random unrelated popups).
	2. Scalable data-driven catalogs for jobs, activities, crimes, assets, and story paths.
	3. Minute-by-minute stat simulation so every screen can trust the values it displays.
	4. Seamless integration with the existing UI expectations (remote names, payload shapes).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
-- MarketplaceService is defined at top of file (needed early for ProcessReceipt setup)

local ModulesFolder = script:FindFirstChild("Modules") or script.Parent:FindFirstChild("Modules")
assert(ModulesFolder, "[LifeBackend] Missing Modules folder. Expected LifeServer/Modules.")

local LifeState = require(ModulesFolder:WaitForChild("LifeState"))
local LifeStageSystem = require(ModulesFolder:WaitForChild("LifeStageSystem"))
GamepassSystem = require(ModulesFolder:WaitForChild("GamepassSystem"))
-- CRITICAL FIX #101: Renamed MafiaSystem to MafiaSystem for clarity
local MafiaSystem = require(ModulesFolder:WaitForChild("MafiaSystem"))
local LifeEventsFolder = ModulesFolder:WaitForChild("LifeEvents")
local LifeEvents = require(LifeEventsFolder:WaitForChild("init"))
local EventEngine = LifeEvents.EventEngine

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #1: Load premium feature modules
-- These were defined but NEVER required, so their yearly processing never ran!
-- ════════════════════════════════════════════════════════════════════════════
local GodModeSystem = require(ModulesFolder:WaitForChild("GodModeSystem"))
local RoyaltyEvents = nil
local CelebrityEvents = nil

-- CRITICAL FIX #48: Load TimeMachine for snapshot saving
local TimeMachine = nil
pcall(function()
	TimeMachine = require(ModulesFolder:WaitForChild("TimeMachine"))
end)

-- Safe require for premium event modules (they might not exist in all setups)
pcall(function()
	RoyaltyEvents = require(LifeEventsFolder:WaitForChild("RoyaltyEvents"))
end)
pcall(function()
	CelebrityEvents = require(LifeEventsFolder:WaitForChild("CelebrityEvents"))
end)

local RANDOM = Random.new()
local C = nil -- client palette not available on server

local function debugPrint(...)
	print("[LifeBackend]", ...)
end

local function clamp(value, minValue, maxValue)
	return math.clamp(value, minValue or 0, maxValue or 100)
end

local function shallowCopy(source)
	if type(source) ~= "table" then
		return source
	end
	local target = {}
	for key, value in pairs(source) do
		target[key] = value
	end
	return target
end

local function deepCopy(source, seen)
	if type(source) ~= "table" then
		return source
	end
	if seen and seen[source] then
		return seen[source]
	end
	local target = {}
	seen = seen or {}
	seen[source] = target
	for key, value in pairs(source) do
		target[deepCopy(key, seen)] = deepCopy(value, seen)
	end
	return target
end

local function chooseRandom(list)
	if #list == 0 then
		return nil
	end
	return list[RANDOM:NextInteger(1, #list)]
end

local function formatMoney(amount)
	if amount >= 1_000_000 then
		return string.format("$%.1fM", amount / 1_000_000)
	elseif amount >= 1_000 then
		return string.format("$%.1fK", amount / 1_000)
	else
		return "$" .. tostring(math.floor(amount + 0.5))
	end
end

local function countEntries(tbl)
	if type(tbl) ~= "table" then
		return 0
	end
	local count = 0
	for _ in pairs(tbl) do
		count += 1
	end
	return count
end

local function sumAssetList(list)
	if type(list) ~= "table" then
		return 0
	end
	local total = 0
	for _, asset in pairs(list) do
		if type(asset) == "table" then
			local value = asset.value or asset.price or asset.cost or asset.worth or asset.Worth
			if typeof(value) == "number" then
				total += value
			end
		elseif typeof(asset) == "number" then
			total += asset
		end
	end
	return total
end

local function computeNetWorth(state)
	local total = state.Money or 0
	local assets = state.Assets or {}
	total += sumAssetList(assets.Properties)
	total += sumAssetList(assets.Vehicles)
	total += sumAssetList(assets.Items)
	total += sumAssetList(assets.Crypto)
	total += sumAssetList(assets.Businesses)
	total += sumAssetList(assets.Investments)
	return math.max(0, total)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EDUCATION LEVEL FORMATTER - Convert internal IDs to display names
-- ═══════════════════════════════════════════════════════════════════════════════
local EducationDisplayNames = {
	none = "No Formal Education",
	elementary = "Elementary School",
	middle_school = "Middle School",
	high_school = "High School Diploma",
	highschool = "High School Diploma",
	community = "Associate's Degree",
	associate = "Associate's Degree",
	bachelor = "Bachelor's Degree",
	bachelors = "Bachelor's Degree",
	trade = "Trade School Certification",
	bootcamp = "Coding Bootcamp",
	master = "Master's Degree",
	masters = "Master's Degree",
	business = "MBA",
	law = "Law Degree (J.D.)",
	medical = "Medical Degree (M.D.)",
	doctorate = "Doctorate (Ph.D.)",
	phd = "Doctorate (Ph.D.)",
}

local function formatEducation(educationLevel)
	if not educationLevel or educationLevel == "" then
		return "No Formal Education"
	end
	return EducationDisplayNames[educationLevel:lower()] or educationLevel:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest) return first:upper()..rest:lower() end)
end

local function appendFeed(state, message)
	if not state or not message or message == "" then
		return
	end
	if state.PendingFeed and state.PendingFeed ~= "" then
		state.PendingFeed = state.PendingFeed .. " " .. message
	else
		state.PendingFeed = message
	end
end

local function safeLower(value)
	if type(value) ~= "string" then
		return ""
	end
	return string.lower(value)
end

local familyKeywords = { "mother", "father", "mom", "dad", "sister", "brother", "sibling", "grand", "son", "daughter", "child", "parent", "aunt", "uncle", "cousin" }
local romanceKeywords = { "husband", "wife", "spouse", "partner", "boyfriend", "girlfriend", "fiancé", "fiance", "lover" }

local function isFamilyRelationship(rel, relId)
	if type(rel) ~= "table" then
		return false
	end
	if rel.isFamily or rel.is_family then
		return true
	end
	local relType = safeLower(rel.type)
	if relType == "family" then
		return true
	end
	local role = safeLower(rel.role or "")
	for _, keyword in ipairs(familyKeywords) do
		if role:find(keyword, 1, true) then
			return true
		end
	end
	if relId then
		local idLower = safeLower(tostring(relId))
		for _, keyword in ipairs(familyKeywords) do
			if idLower:find(keyword, 1, true) then
				return true
			end
		end
	end
	return false
end

local function isRomanticRelationship(rel)
	if type(rel) ~= "table" then
		return false
	end
	local relType = safeLower(rel.type)
	if relType == "romance" or relType == "partner" or relType == "spouse" then
		return true
	end
	local role = safeLower(rel.role or "")
	for _, keyword in ipairs(romanceKeywords) do
		if role:find(keyword, 1, true) then
			return true
		end
	end
	return false
end

local function pruneRelationshipsForAge(state, targetAge)
	if not state or not state.Relationships then
		return
	end

	local toRemove = {}
	local shouldClearPartner = false

	for relId, rel in pairs(state.Relationships) do
		if type(rel) == "table" then
			local familyRel = isFamilyRelationship(rel, relId)
			local romanticRel = isRomanticRelationship(rel)

			if targetAge < 13 and romanticRel then
				table.insert(toRemove, relId)
				if state.Relationships.partner and state.Relationships.partner.id == rel.id then
					shouldClearPartner = true
				end
			elseif targetAge < 10 and not familyRel then
				table.insert(toRemove, relId)
			end
		end
	end

	for _, relId in ipairs(toRemove) do
		state.Relationships[relId] = nil
	end

	if shouldClearPartner or (state.Relationships.partner and state.Relationships.partner.id and not state.Relationships[state.Relationships.partner.id]) then
		state.Relationships.partner = nil
		state.Flags = state.Flags or {}
		state.Flags.has_partner = nil
		state.Flags.dating = nil
		state.Flags.married = nil
	end
end

local function resetMobStateForAge(state, targetAge)
	if not state or targetAge >= 18 then
		return
	end

	local mobState = MafiaSystem and MafiaSystem:getMobState(state) or (state.MobState or {})
	mobState.inMob = false
	mobState.familyId = nil
	mobState.familyName = nil
	mobState.familyEmoji = nil
	mobState.rankIndex = 1
	mobState.rankLevel = 1
	mobState.rankName = nil
	mobState.rankEmoji = nil
	mobState.respect = 0
	mobState.heat = 0
	mobState.loyalty = 100
	mobState.operationsCompleted = 0
	mobState.operationsFailed = 0
	mobState.earnings = 0

	state.MobState = mobState
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PERSONALITY DESCRIPTION GENERATOR - BitLife AAA Quality
-- Generates personality adjectives based on stats
-- ═══════════════════════════════════════════════════════════════════════════════
local function getPersonalityDescription(stats, flags)
	local traits = {}
	stats = stats or {}
	flags = flags or {}
	
	-- Happiness-based traits
	local happiness = stats.Happiness or 50
	if happiness >= 85 then
		table.insert(traits, "radiantly happy")
	elseif happiness >= 70 then
		table.insert(traits, "cheerful")
	elseif happiness >= 50 then
		table.insert(traits, "content")
	elseif happiness >= 30 then
		table.insert(traits, "melancholic")
	else
		table.insert(traits, "deeply unhappy")
	end
	
	-- Smarts-based traits
	local smarts = stats.Smarts or 50
	if smarts >= 90 then
		table.insert(traits, "brilliant")
	elseif smarts >= 75 then
		table.insert(traits, "intelligent")
	elseif smarts >= 50 then
		table.insert(traits, "reasonably clever")
	elseif smarts >= 30 then
		table.insert(traits, "simple-minded")
	else
		table.insert(traits, "not academically inclined")
	end
	
	-- Health-based traits
	local health = stats.Health or 50
	if health >= 85 then
		table.insert(traits, "remarkably fit")
	elseif health >= 70 then
		table.insert(traits, "healthy")
	elseif health >= 40 then
		table.insert(traits, "of average health")
	elseif health >= 20 then
		table.insert(traits, "in poor health")
	else
		table.insert(traits, "gravely ill")
	end
	
	-- Looks-based traits
	local looks = stats.Looks or 50
	if looks >= 90 then
		table.insert(traits, "stunningly attractive")
	elseif looks >= 75 then
		table.insert(traits, "good-looking")
	elseif looks >= 50 then
		table.insert(traits, "average-looking")
	elseif looks >= 30 then
		table.insert(traits, "plain")
	else
		table.insert(traits, "homely")
	end
	
	-- Flag-based personality additions
	if flags.criminal_record then table.insert(traits, "with a troubled past") end
	if flags.philanthropist then table.insert(traits, "generous") end
	if flags.famous or flags.celebrity then table.insert(traits, "famous") end
	if flags.world_champion or flags.racing_legend then table.insert(traits, "legendary") end
	if flags.retired then table.insert(traits, "retired") end
	
	return traits
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LIFESTYLE SUMMARY GENERATOR - BitLife AAA Quality
-- ═══════════════════════════════════════════════════════════════════════════════
local function getLifestyleSummary(flags)
	local lifestyles = {}
	flags = flags or {}
	
	if flags.heavy_drinker then table.insert(lifestyles, "enjoyed drinking heavily") end
	if flags.substance_issue then table.insert(lifestyles, "struggled with substance abuse") end
	if flags.fitness_enthusiast then table.insert(lifestyles, "was dedicated to fitness") end
	if flags.vegan or flags.vegetarian then table.insert(lifestyles, "followed a plant-based diet") end
	if flags.smoker then table.insert(lifestyles, "was a smoker") end
	if flags.workaholic then table.insert(lifestyles, "was a workaholic") end
	if flags.adventurous then table.insert(lifestyles, "loved adventure") end
	if flags.homebody then table.insert(lifestyles, "preferred staying home") end
	if flags.religious then table.insert(lifestyles, "was deeply religious") end
	if flags.criminal_path then table.insert(lifestyles, "walked the path of crime") end
	if flags.entrepreneur then table.insert(lifestyles, "had an entrepreneurial spirit") end
	if flags.philanthropist then table.insert(lifestyles, "was known for charitable giving") end
	
	return lifestyles
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DEATH OBITUARY GENERATOR - BitLife AAA Quality
-- Generates a full obituary-style death message
-- ═══════════════════════════════════════════════════════════════════════════════
local function generateObituary(state, deathInfo)
	local name = state.Name or "This person"
	local age = state.Age or 0
	local gender = state.Gender or "male"
	local pronoun = gender == "female" and "She" or "He"
	local possessive = gender == "female" and "her" or "his"
	
	local stats = state.Stats or {}
	local flags = state.Flags or {}
	
	local lines = {}
	
	-- Opening line with personality
	local traits = getPersonalityDescription(stats, flags)
	local traitText = ""
	if #traits >= 2 then
		traitText = traits[1] .. " and " .. traits[2]
	elseif #traits == 1 then
		traitText = traits[1]
	else
		traitText = "ordinary"
	end
	
	table.insert(lines, string.format("%s was a %s individual who passed away at age %d.", name, traitText, age))
	
	-- Cause of death
	local cause = deathInfo and deathInfo.cause or "natural causes"
	if cause == "Health failure" then
		cause = "failing health after a long struggle"
	elseif cause == "Natural causes" then
		cause = "peaceful natural causes"
	elseif cause == "Extraordinarily long life" then
		cause = "an extraordinarily long and full life"
	end
	table.insert(lines, string.format("%s died from %s.", pronoun, cause))
	
	-- Education
	local education = formatEducation(state.Education)
	if education ~= "No Formal Education" then
		table.insert(lines, string.format("%s held a %s.", pronoun, education))
	end
	
	-- Career
	if state.CurrentJob and state.CurrentJob.name then
		table.insert(lines, string.format("At the time of death, %s was working as a %s at %s.", 
			pronoun:lower(), state.CurrentJob.name, state.CurrentJob.company or "a local company"))
	elseif flags.retired then
		table.insert(lines, string.format("%s was enjoying %s retirement.", pronoun, possessive))
	elseif flags.unemployed or flags.between_jobs then
		table.insert(lines, string.format("%s was between jobs at the time.", pronoun))
	end
	
	-- Relationships
	local relationshipCount = countEntries(state.Relationships or {})
	if state.Relationships and state.Relationships.partner then
		local partner = state.Relationships.partner
		local partnerRole = partner.role or "partner"
		if flags.married then
			table.insert(lines, string.format("%s was married to %s.", pronoun, partner.name or "their spouse"))
		elseif flags.engaged then
			table.insert(lines, string.format("%s was engaged to %s.", pronoun, partner.name or "their fiancé"))
		else
			table.insert(lines, string.format("%s was in a relationship with %s.", pronoun, partner.name or "someone special"))
		end
	else
		table.insert(lines, string.format("%s was single.", pronoun))
	end
	
	-- Family count
	local familyCount = 0
	local childCount = 0
	for id, rel in pairs(state.Relationships or {}) do
		if type(rel) == "table" then
			if rel.type == "family" or rel.isFamily then
				familyCount = familyCount + 1
			end
			if rel.role and (rel.role:find("Son") or rel.role:find("Daughter") or rel.role:find("Child")) then
				childCount = childCount + 1
			end
		end
	end
	if childCount > 0 then
		table.insert(lines, string.format("%s had %d %s.", pronoun, childCount, childCount == 1 and "child" or "children"))
	end
	
	-- Lifestyle
	local lifestyles = getLifestyleSummary(flags)
	if #lifestyles > 0 then
		local lifestyleText = table.concat(lifestyles, ", ")
		table.insert(lines, string.format("Throughout life, %s %s.", pronoun:lower(), lifestyleText))
	end
	
	-- Net worth
	local netWorth = computeNetWorth(state)
	if netWorth >= 1000000000 then
		table.insert(lines, string.format("%s died a billionaire with a net worth of $%.2fB.", pronoun, netWorth / 1000000000))
	elseif netWorth >= 1000000 then
		table.insert(lines, string.format("%s died a millionaire with a net worth of $%.2fM.", pronoun, netWorth / 1000000))
	elseif netWorth >= 100000 then
		table.insert(lines, string.format("%s left behind a net worth of $%s.", pronoun, formatMoney(netWorth)))
	elseif netWorth > 0 then
		table.insert(lines, string.format("%s had modest savings of $%s.", pronoun, formatMoney(netWorth)))
	else
		table.insert(lines, string.format("%s died penniless.", pronoun))
	end
	
	-- Final stat summary
	table.insert(lines, string.format("\n📊 Final Stats: 😊 %d | ❤️ %d | 🧠 %d | 💎 %d", 
		stats.Happiness or 0, stats.Health or 0, stats.Smarts or 0, stats.Looks or 0))
	
	return table.concat(lines, "\n")
end

local function buildDeathMeta(state, deathInfo)
	local stageData = LifeStageSystem.getStage(state.Age or 0)
	local stats = state.Stats or {}
	local flags = state.Flags or {}
	
	return {
		age = state.Age,
		year = state.Year,
		cause = deathInfo and deathInfo.cause or "Unknown causes",
		causeId = deathInfo and deathInfo.id,
		stage = stageData and stageData.id or "unknown",
		stageName = stageData and stageData.name or "Unknown",
		netWorth = computeNetWorth(state),
		money = state.Money or 0,
		-- Career info
		career = state.CurrentJob and state.CurrentJob.name or (state.Career and state.Career.jobTitle),
		employer = state.CurrentJob and state.CurrentJob.company or (state.Career and state.Career.employer),
		-- Education - FIXED: Use formatted display name
		education = formatEducation(state.Education),
		educationRaw = state.Education,
		-- Stats
		happiness = stats.Happiness or 0,
		health = stats.Health or 0,
		smarts = stats.Smarts or 0,
		looks = stats.Looks or 0,
		-- Personality and lifestyle
		personality = getPersonalityDescription(stats, flags),
		lifestyle = getLifestyleSummary(flags),
		-- Family and relationships
		fame = state.Fame or 0,
		relationshipCount = countEntries(state.Relationships),
		wasMarried = flags.married or false,
		hadChildren = flags.has_children or false,
		-- Legacy flags
		wasRich = computeNetWorth(state) >= 1000000,
		wasFamous = (state.Fame or 0) >= 50,
		wasCriminal = flags.criminal_record or flags.criminal_path or false,
		-- Full obituary text
		obituary = generateObituary(state, deathInfo),
		-- Raw flags for client
		flags = shallowCopy(flags),
	}
end

-- ============================================================================
-- Job Catalog (mirrors OccupationScreen order and IDs)
-- ============================================================================

local JobCatalogList = {
	-- ENTRY LEVEL / PART-TIME (Easy to get - difficulty 1)
	{ id = "fastfood", name = "Fast Food Worker", company = "Burger Palace", emoji = "🍔", salary = 22000, minAge = 14, requirement = nil, category = "entry",
		difficulty = 1, description = "Anyone can flip burgers!" },
	{ id = "retail", name = "Retail Associate", company = "MegaMart", emoji = "🛒", salary = 26000, minAge = 16, requirement = nil, category = "entry",
		difficulty = 1, description = "Helping customers find what they need" },
	{ id = "cashier", name = "Cashier", company = "QuickMart", emoji = "💵", salary = 24000, minAge = 15, requirement = nil, category = "entry",
		difficulty = 1, description = "Ring up customers all day" },
	{ id = "bagger", name = "Grocery Bagger", company = "Fresh Foods", emoji = "🛍️", salary = 18000, minAge = 14, requirement = nil, category = "entry",
		difficulty = 1, description = "Perfect first job for teens" },
	{ id = "movie_usher", name = "Movie Usher", company = "CineMax", emoji = "🎬", salary = 20000, minAge = 14, requirement = nil, category = "entry",
		difficulty = 1, description = "Watch movies and help guests" },
	{ id = "lifeguard", name = "Lifeguard", company = "City Pool", emoji = "🏊", salary = 28000, minAge = 16, requirement = nil, category = "entry",
		difficulty = 2, minStats = { Health = 50 }, description = "Must be able to swim well" },
	{ id = "camp_counselor", name = "Camp Counselor", company = "Summer Camp", emoji = "🏕️", salary = 22000, minAge = 16, requirement = nil, category = "entry",
		difficulty = 1, description = "Fun summer job with kids" },
	{ id = "newspaper_delivery", name = "Newspaper Delivery", company = "Daily News", emoji = "📰", salary = 15000, minAge = 12, requirement = nil, category = "entry",
		difficulty = 1, description = "Early morning route delivery" },
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #51: Added entry_career and career progression jobs
	-- These jobs allow players who get generic first jobs to progress through career tracks
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "entry_career", name = "Associate", company = "Local Company", emoji = "💼", salary = 35000, minAge = 18, requirement = nil, category = "entry",
		difficulty = 2, grantsFlags = { "entry_level_experience", "employed" },
		description = "Generic entry-level career position" },
	{ id = "retail_worker", name = "Retail Associate", company = "RetailMart", emoji = "🛒", salary = 26000, minAge = 16, requirement = nil, category = "entry",
		difficulty = 1, grantsFlags = { "retail_experience", "customer_service" },
		description = "Help customers and stock shelves" },
	{ id = "shift_supervisor", name = "Shift Supervisor", company = "RetailMart", emoji = "👔", salary = 38000, minAge = 20, requirement = "high_school", category = "entry",
		difficulty = 3, requiresFlags = { "retail_experience", "customer_service" }, grantsFlags = { "supervisor_experience", "leadership_basics" },
		description = "Supervise a retail shift - requires retail experience" },
	{ id = "store_manager", name = "Store Manager", company = "RetailMart", emoji = "🏪", salary = 55000, minAge = 24, requirement = "high_school", category = "entry",
		difficulty = 4, requiresFlags = { "supervisor_experience", "leadership_basics" }, grantsFlags = { "management_experience", "store_operations" },
		description = "Manage an entire store - requires supervisor experience" },
	{ id = "district_manager", name = "District Manager", company = "RetailMart Corp", emoji = "🏢", salary = 85000, minAge = 30, requirement = "bachelor", category = "office",
		difficulty = 6, requiresFlags = { "management_experience", "store_operations" }, grantsFlags = { "regional_management", "executive_experience" },
		description = "Manage multiple stores - requires store management experience" },
	{ id = "fast_food_worker", name = "Fast Food Team Member", company = "QuickBurger", emoji = "🍟", salary = 22000, minAge = 14, requirement = nil, category = "entry",
		difficulty = 1, grantsFlags = { "food_service_experience", "customer_service" },
		description = "Work the fryer and register" },
	{ id = "server", name = "Server", company = "Family Restaurant", emoji = "🍽️", salary = 30000, minAge = 16, requirement = nil, category = "service",
		difficulty = 2, grantsFlags = { "food_service_experience", "customer_service", "server_experience" },
		description = "Wait tables and serve customers" },
	{ id = "shift_lead", name = "Shift Lead", company = "QuickBurger", emoji = "🎖️", salary = 35000, minAge = 18, requirement = "high_school", category = "service",
		difficulty = 3, requiresFlags = { "food_service_experience" }, grantsFlags = { "supervisor_experience", "team_leadership" },
		description = "Lead a restaurant shift" },
	{ id = "restaurant_manager", name = "Restaurant Manager", company = "Family Restaurant", emoji = "🍴", salary = 52000, minAge = 24, requirement = "high_school", category = "service",
		difficulty = 5, requiresFlags = { "supervisor_experience", "food_service_experience" }, grantsFlags = { "management_experience", "hospitality_management" },
		description = "Manage the entire restaurant" },

	-- SERVICE
	{ id = "waiter", name = "Waiter/Waitress", company = "The Grand Restaurant", emoji = "🍽️", salary = 32000, minAge = 16, requirement = nil, category = "service" },
	{ id = "bartender", name = "Bartender", company = "The Tipsy Owl", emoji = "🍸", salary = 38000, minAge = 21, requirement = nil, category = "service" },
	{ id = "barista", name = "Barista", company = "Bean Scene", emoji = "☕", salary = 28000, minAge = 16, requirement = nil, category = "service" },
	{ id = "hotel_front_desk", name = "Hotel Receptionist", company = "Grand Hotel", emoji = "🏨", salary = 32000, minAge = 18, requirement = "high_school", category = "service" },
	{ id = "flight_attendant", name = "Flight Attendant", company = "SkyWays Airlines", emoji = "✈️", salary = 55000, minAge = 21, requirement = "high_school", category = "service" },
	{ id = "tour_guide", name = "Tour Guide", company = "City Tours", emoji = "🗺️", salary = 35000, minAge = 18, requirement = "high_school", category = "service" },
	-- REMOVED: Casino Dealer job (gambling against Roblox TOS)
	{ id = "cruise_staff", name = "Cruise Ship Staff", company = "Ocean Voyages", emoji = "🚢", salary = 42000, minAge = 18, requirement = "high_school", category = "service" },
	{ id = "personal_trainer", name = "Personal Trainer", company = "FitLife Gym", emoji = "💪", salary = 48000, minAge = 18, requirement = "high_school", category = "service" },

	-- TRADES - CRITICAL FIX: Physical labor jobs now require health and have proper progression flags!
	{ id = "janitor", name = "Janitor", company = "CleanCo Services", emoji = "🧹", salary = 28000, minAge = 18, requirement = nil, category = "trades",
		difficulty = 1, grantsFlags = { "maintenance_experience", "facility_work" },
		description = "Entry level maintenance work" },
	{ id = "construction", name = "Construction Worker", company = "BuildRight Co", emoji = "👷", salary = 42000, minAge = 18, requirement = nil, category = "trades",
		minStats = { Health = 45 }, difficulty = 2, grantsFlags = { "construction_experience", "labor_skills", "site_work" },
		description = "Physically demanding work" },
	{ id = "electrician_apprentice", name = "Electrician Apprentice", company = "Spark Electric", emoji = "⚡", salary = 35000, minAge = 18, requirement = "high_school", category = "trades",
		difficulty = 3, grantsFlags = { "electrical_training", "apprentice_electrician" },
		description = "Learning electrical trade" },
	{ id = "electrician", name = "Electrician", company = "PowerPro Electric", emoji = "⚡", salary = 62000, minAge = 22, requirement = "high_school", category = "trades",
		difficulty = 4, requiresFlags = { "electrical_training", "apprentice_electrician" }, grantsFlags = { "licensed_electrician", "journeyman_electrician" },
		description = "Licensed journeyman electrician" },
	{ id = "plumber_apprentice", name = "Plumber Apprentice", company = "DrainMaster", emoji = "🔧", salary = 32000, minAge = 18, requirement = "high_school", category = "trades",
		difficulty = 3, grantsFlags = { "plumbing_training", "apprentice_plumber" },
		description = "Learning plumbing trade" },
	{ id = "plumber", name = "Licensed Plumber", company = "FlowRight Plumbing", emoji = "🔧", salary = 58000, minAge = 22, requirement = "high_school", category = "trades",
		difficulty = 4, requiresFlags = { "plumbing_training", "apprentice_plumber" }, grantsFlags = { "licensed_plumber", "journeyman_plumber" },
		description = "Licensed journeyman plumber" },
	{ id = "mechanic", name = "Auto Mechanic", company = "QuickFix Auto", emoji = "🔩", salary = 45000, minAge = 18, requirement = "high_school", category = "trades",
		difficulty = 3, grantsFlags = { "mechanic_experience", "automotive_skills" },
		description = "Repair and maintain vehicles" },
	{ id = "hvac_tech", name = "HVAC Technician", company = "CoolAir Systems", emoji = "❄️", salary = 52000, minAge = 20, requirement = "high_school", category = "trades",
		difficulty = 4, grantsFlags = { "hvac_experience", "climate_control" },
		description = "Install and repair heating/cooling systems" },
	{ id = "welder", name = "Welder", company = "Steel Works Inc", emoji = "🔥", salary = 48000, minAge = 18, requirement = "high_school", category = "trades",
		difficulty = 3, grantsFlags = { "welding_skills", "metalwork" },
		description = "Join metal parts together" },
	{ id = "carpenter", name = "Carpenter", company = "WoodCraft Co", emoji = "🪚", salary = 46000, minAge = 18, requirement = "high_school", category = "trades",
		difficulty = 3, grantsFlags = { "carpentry_skills", "woodworking" },
		description = "Build and repair wooden structures" },
	{ id = "truck_driver", name = "Truck Driver", company = "FastFreight Logistics", emoji = "🚛", salary = 55000, minAge = 21, requirement = "high_school", category = "trades",
		difficulty = 3, grantsFlags = { "cdl_license", "trucking_experience", "logistics" },
		description = "Long-haul freight transportation" },
	{ id = "foreman", name = "Construction Foreman", company = "BuildRight Co", emoji = "🏗️", salary = 72000, minAge = 28, requirement = "high_school", category = "trades",
		difficulty = 5, requiresFlags = { "construction_experience", "labor_skills" }, grantsFlags = { "site_supervisor", "construction_leadership" },
		description = "Supervise construction crews" },

	-- OFFICE - CRITICAL FIX #69: Entry-level office jobs need grantsFlags for progression
	{ id = "receptionist", name = "Receptionist", company = "Corporate Office", emoji = "📞", salary = 32000, minAge = 18, requirement = "high_school", category = "office",
		difficulty = 1, grantsFlags = { "office_experience", "customer_service", "administrative_skills" },
		description = "Entry-level front desk position" },
	{ id = "office_assistant", name = "Office Assistant", company = "Business Solutions", emoji = "📋", salary = 35000, minAge = 18, requirement = "high_school", category = "office",
		difficulty = 1, grantsFlags = { "office_experience", "administrative_skills", "entry_level_experience" },
		description = "Entry-level office support position" },
	{ id = "data_entry", name = "Data Entry Clerk", company = "DataCorp", emoji = "⌨️", salary = 34000, minAge = 18, requirement = "high_school", category = "office",
		difficulty = 1, grantsFlags = { "office_experience", "computer_skills", "data_experience" },
		description = "Entry-level data processing position" },
	{ id = "administrative_assistant", name = "Administrative Assistant", company = "Executive Office", emoji = "📁", salary = 42000, minAge = 20, requirement = "high_school", category = "office",
		difficulty = 2, requiresFlags = { "office_experience" },
		grantsFlags = { "administrative_skills", "organizational_skills", "office_experience" },
		description = "Requires some office experience" },
	-- CRITICAL FIX #70: HR jobs need proper progression flags
	{ id = "hr_coordinator", name = "HR Coordinator", company = "PeopleFirst HR", emoji = "👥", salary = 48000, minAge = 22, requirement = "bachelor", category = "office",
		difficulty = 3, grantsFlags = { "hr_experience", "people_skills", "recruitment_experience" },
		description = "Entry-level HR position" },
	{ id = "hr_manager", name = "HR Manager", company = "PeopleFirst HR", emoji = "👥", salary = 78000, minAge = 28, requirement = "bachelor", category = "office",
		difficulty = 5, requiresFlags = { "hr_experience", "people_skills" },
		grantsFlags = { "hr_management", "employee_relations", "hr_leadership" },
		description = "Requires HR coordinator experience" },
	{ id = "recruiter", name = "Corporate Recruiter", company = "TalentFind Inc", emoji = "🔍", salary = 58000, minAge = 24, requirement = "bachelor", category = "office",
		difficulty = 3, grantsFlags = { "recruitment_experience", "talent_acquisition", "interviewing_skills" },
		description = "Find and hire talent for companies" },
	-- CRITICAL FIX #68: Office management jobs need proper progression flags
	{ id = "office_manager", name = "Office Manager", company = "CorpWorld Inc", emoji = "🏢", salary = 62000, minAge = 26, requirement = "bachelor", category = "office",
		difficulty = 4, requiresFlags = { "office_experience", "administrative_skills" },
		grantsFlags = { "management_experience", "office_management", "team_leadership" },
		description = "Requires office/administrative experience" },
	{ id = "executive_assistant", name = "Executive Assistant", company = "CEO Office", emoji = "👔", salary = 72000, minAge = 26, requirement = "bachelor", category = "office",
		difficulty = 4, requiresFlags = { "office_experience" },
		grantsFlags = { "executive_support", "c_suite_exposure", "organizational_skills" },
		description = "Requires office experience - work directly with executives" },
	{ id = "project_manager", name = "Project Manager", company = "ManageAll Corp", emoji = "📊", salary = 85000, minAge = 28, requirement = "bachelor", category = "office",
		difficulty = 5, requiresFlags = { "team_leadership", "organizational_skills" },
		grantsFlags = { "project_management", "leadership_experience", "cross_functional" },
		description = "Requires leadership experience - lead teams and projects" },
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #63: Executive jobs MUST require management experience
	-- Cannot just apply to be COO without working your way up!
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "operations_director", name = "Operations Director", company = "Global Corp", emoji = "🎯", salary = 145000, minAge = 35, requirement = "master", category = "office",
		difficulty = 7, minStats = { Smarts = 65 },
		requiresFlags = { "management_experience", "project_management", "office_experience" },
		grantsFlags = { "director_experience", "executive_track", "operations_leadership" },
		description = "Requires management/project management experience" },
	{ id = "coo", name = "Chief Operating Officer", company = "Fortune 500", emoji = "🏆", salary = 350000, minAge = 42, requirement = "master", category = "office",
		difficulty = 9, minStats = { Smarts = 75 },
		requiresFlags = { "director_experience", "executive_track", "operations_leadership" },
		grantsFlags = { "c_level", "coo_experience", "executive_leadership" },
		description = "C-suite requires director-level experience - top executive position" },

	-- TECHNOLOGY - CRITICAL FIX #336: Tech jobs require coding/tech skills!
	{ id = "it_support", name = "IT Support Technician", company = "TechHelp Inc", emoji = "🖥️", salary = 45000, minAge = 18, requirement = "high_school", category = "tech",
		difficulty = 2, grantsFlags = { "tech_experience", "it_background" },
		description = "Entry point to tech career" },
	{ id = "junior_developer", name = "Junior Developer", company = "CodeStart Inc", emoji = "💻", salary = 65000, minAge = 21, requirement = "bachelor", category = "tech",
		difficulty = 4, requiresFlags = { "coder", "computer_skills", "tech_experience", "coding_bootcamp" }, grantsFlags = { "developer_experience", "software_engineer" },
		description = "Requires coding skills (code as hobby, computer club, bootcamp)" },
	{ id = "developer", name = "Software Developer", company = "TechStart Inc", emoji = "💻", salary = 95000, minAge = 23, requirement = "bachelor", category = "tech",
		difficulty = 5, requiresFlags = { "developer_experience", "coder" }, grantsFlags = { "mid_level_dev", "software_engineer" },
		description = "Requires junior developer experience" },
	{ id = "senior_developer", name = "Senior Developer", company = "BigTech Corp", emoji = "💻", salary = 145000, minAge = 27, requirement = "bachelor", category = "tech",
		difficulty = 6, requiresFlags = { "mid_level_dev", "developer_experience" }, grantsFlags = { "senior_dev", "tech_leader" },
		description = "Requires software developer experience" },
	{ id = "tech_lead", name = "Tech Lead", company = "BigTech Corp", emoji = "👨‍💻", salary = 175000, minAge = 30, requirement = "bachelor", category = "tech",
		difficulty = 7, requiresFlags = { "senior_dev", "tech_leader" }, grantsFlags = { "tech_lead", "engineering_leadership" },
		description = "Requires senior developer experience" },
	{ id = "software_architect", name = "Software Architect", company = "MegaTech Inc", emoji = "🏗️", salary = 195000, minAge = 32, requirement = "master", category = "tech",
		difficulty = 8, requiresFlags = { "tech_lead", "senior_dev" }, grantsFlags = { "architect" },
		description = "Requires tech lead experience" },
	{ id = "web_developer", name = "Web Developer", company = "WebWorks Studio", emoji = "🌐", salary = 78000, minAge = 22, requirement = "bachelor", category = "tech",
		difficulty = 4, requiresFlags = { "coder", "computer_skills", "tech_experience" }, grantsFlags = { "web_dev", "developer_experience" },
		description = "Requires coding skills" },
	{ id = "mobile_developer", name = "Mobile App Developer", company = "AppFactory", emoji = "📱", salary = 92000, minAge = 23, requirement = "bachelor", category = "tech",
		difficulty = 5, requiresFlags = { "coder", "developer_experience" }, grantsFlags = { "mobile_dev", "app_developer" },
		description = "Requires coding experience" },
	{ id = "data_analyst", name = "Data Analyst", company = "DataDriven Co", emoji = "📈", salary = 72000, minAge = 22, requirement = "bachelor", category = "tech",
		difficulty = 4, minStats = { Smarts = 55 }, grantsFlags = { "data_experience", "analytics" },
		description = "Entry point to data science" },
	{ id = "data_scientist", name = "Data Scientist", company = "AI Innovations", emoji = "🧠", salary = 135000, minAge = 26, requirement = "master", category = "tech",
		difficulty = 6, minStats = { Smarts = 65 }, requiresFlags = { "data_experience", "coder" }, grantsFlags = { "data_scientist", "ml_experience" },
		description = "Requires data analyst experience" },
	{ id = "ml_engineer", name = "Machine Learning Engineer", company = "AI Labs", emoji = "🤖", salary = 165000, minAge = 28, requirement = "master", category = "tech",
		difficulty = 7, minStats = { Smarts = 70 }, requiresFlags = { "data_scientist", "developer_experience" }, grantsFlags = { "ml_engineer", "ai_expert" },
		description = "Requires data science and coding experience" },
	{ id = "cybersecurity_analyst", name = "Cybersecurity Analyst", company = "SecureNet", emoji = "🔐", salary = 95000, minAge = 24, requirement = "bachelor", category = "tech",
		difficulty = 5, requiresFlags = { "tech_experience", "it_background", "coder" }, grantsFlags = { "security_experience", "cybersecurity" },
		description = "Requires IT/tech background" },
	{ id = "security_engineer", name = "Security Engineer", company = "CyberShield", emoji = "🛡️", salary = 140000, minAge = 28, requirement = "bachelor", category = "tech",
		difficulty = 6, requiresFlags = { "security_experience", "cybersecurity" }, grantsFlags = { "security_engineer", "senior_security" },
		description = "Requires cybersecurity experience" },
	{ id = "devops_engineer", name = "DevOps Engineer", company = "CloudOps Inc", emoji = "☁️", salary = 125000, minAge = 26, requirement = "bachelor", category = "tech",
		difficulty = 6, requiresFlags = { "developer_experience", "tech_experience" }, grantsFlags = { "devops", "cloud_engineer" },
		description = "Requires development experience" },
	{ id = "cto", name = "Chief Technology Officer", company = "Tech Giant", emoji = "🚀", salary = 380000, minAge = 38, requirement = "master", category = "tech",
		difficulty = 9, minStats = { Smarts = 80 }, requiresFlags = { "tech_lead", "engineering_leadership" }, grantsFlags = { "c_level", "tech_executive" },
		description = "Requires tech leadership experience" },

	-- MEDICAL - CRITICAL FIX #337: Medical careers need proper progression!
	{ id = "hospital_orderly", name = "Hospital Orderly", company = "City Hospital", emoji = "🏥", salary = 28000, minAge = 18, requirement = nil, category = "medical",
		difficulty = 1, grantsFlags = { "medical_experience", "hospital_work" },
		description = "Entry point to healthcare" },
	{ id = "medical_assistant", name = "Medical Assistant", company = "Family Clinic", emoji = "💉", salary = 36000, minAge = 18, requirement = "high_school", category = "medical",
		difficulty = 2, grantsFlags = { "medical_experience", "clinical_experience" },
		description = "Basic medical support role" },
	{ id = "emt", name = "EMT / Paramedic", company = "City Ambulance", emoji = "🚑", salary = 42000, minAge = 18, requirement = "high_school", category = "medical",
		difficulty = 3, minStats = { Health = 50 }, grantsFlags = { "medical_experience", "emergency_medicine" },
		description = "Emergency medical technician" },
	{ id = "nurse_lpn", name = "Licensed Practical Nurse", company = "Regional Hospital", emoji = "👩‍⚕️", salary = 52000, minAge = 20, requirement = "community", category = "medical",
		difficulty = 3, grantsFlags = { "nursing_experience", "clinical_experience" },
		description = "Licensed practical nursing" },
	{ id = "nurse_rn", name = "Registered Nurse", company = "City Hospital", emoji = "👩‍⚕️", salary = 78000, minAge = 22, requirement = "bachelor", category = "medical",
		difficulty = 4, grantsFlags = { "nursing_experience", "rn_license", "clinical_experience" },
		description = "Registered nursing degree required" },
	{ id = "nurse_practitioner", name = "Nurse Practitioner", company = "Medical Center", emoji = "👩‍⚕️", salary = 118000, minAge = 28, requirement = "master", category = "medical",
		difficulty = 5, requiresFlags = { "nursing_experience", "rn_license" }, grantsFlags = { "advanced_nursing", "np_license" },
		description = "Requires RN experience" },
	{ id = "physical_therapist", name = "Physical Therapist", company = "RehabCare Center", emoji = "🦿", salary = 92000, minAge = 26, requirement = "master", category = "medical",
		difficulty = 5, minStats = { Health = 45 }, grantsFlags = { "pt_license", "clinical_experience" },
		description = "Physical therapy degree required" },
	{ id = "pharmacist", name = "Pharmacist", company = "MediPharm", emoji = "💊", salary = 128000, minAge = 28, requirement = "phd", category = "medical",
		difficulty = 5, minStats = { Smarts = 65 }, grantsFlags = { "pharmacist_license" },
		description = "Pharmacy doctorate required" },
	{ id = "dentist", name = "Dentist", company = "Bright Smiles Dental", emoji = "🦷", salary = 175000, minAge = 28, requirement = "medical", category = "medical",
		difficulty = 6, grantsFlags = { "dentist_license", "medical_professional" },
		description = "Dental degree required" },
	{ id = "doctor_resident", name = "Medical Resident", company = "Teaching Hospital", emoji = "🩺", salary = 65000, minAge = 26, requirement = "medical", category = "medical",
		difficulty = 5, grantsFlags = { "residency_complete", "clinical_experience", "doctor_training" },
		description = "Medical school graduate - residency training" },
	{ id = "doctor", name = "Doctor", company = "City Hospital", emoji = "🩺", salary = 250000, minAge = 30, requirement = "medical", category = "medical",
		difficulty = 6, requiresFlags = { "residency_complete", "doctor_training" }, grantsFlags = { "licensed_doctor", "attending_physician" },
		description = "Requires completed residency" },
	{ id = "surgeon", name = "Surgeon", company = "Medical Center", emoji = "🔪", salary = 420000, minAge = 34, requirement = "medical", category = "medical",
		difficulty = 8, requiresFlags = { "licensed_doctor", "attending_physician" }, grantsFlags = { "surgeon", "surgical_experience" },
		description = "Requires years of doctor experience" },
	{ id = "chief_of_medicine", name = "Chief of Medicine", company = "University Hospital", emoji = "👨‍⚕️", salary = 550000, minAge = 45, requirement = "medical", category = "medical",
		difficulty = 9, requiresFlags = { "licensed_doctor", "attending_physician" }, grantsFlags = { "medical_leadership" },
		description = "Requires extensive medical career" },
	{ id = "psychiatrist", name = "Psychiatrist", company = "Mental Health Center", emoji = "🧠", salary = 280000, minAge = 32, requirement = "medical", category = "medical",
		difficulty = 7, requiresFlags = { "residency_complete" }, grantsFlags = { "psychiatrist", "mental_health_expert" },
		description = "Requires medical residency" },
	{ id = "veterinarian", name = "Veterinarian", company = "Pet Care Clinic", emoji = "🐾", salary = 105000, minAge = 28, requirement = "medical", category = "medical",
		difficulty = 5, grantsFlags = { "vet_license", "animal_medicine" },
		description = "Veterinary degree required" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- LAW - CRITICAL FIX: Law careers require proper progression!
	-- Can't just become a judge without legal experience.
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "legal_assistant", name = "Legal Assistant", company = "Smith & Partners", emoji = "📝", salary = 42000, minAge = 18, requirement = "high_school", category = "law",
		difficulty = 2, grantsFlags = { "legal_experience", "law_firm_experience" },
		description = "Entry point to legal career" },
	{ id = "paralegal", name = "Paralegal", company = "Legal Associates", emoji = "📜", salary = 52000, minAge = 22, requirement = "bachelor", category = "law",
		difficulty = 3, requiresFlags = { "legal_experience", "law_firm_experience" }, grantsFlags = { "paralegal_experience", "legal_research" },
		description = "Requires legal assistant experience or degree" },
	{ id = "associate_lawyer", name = "Associate Attorney", company = "Law Firm LLP", emoji = "⚖️", salary = 95000, minAge = 26, requirement = "law", category = "law",
		difficulty = 5, grantsFlags = { "bar_license", "practicing_attorney", "litigation_experience" },
		description = "Requires law degree and bar exam" },
	{ id = "lawyer", name = "Attorney", company = "Smith & Associates", emoji = "⚖️", salary = 145000, minAge = 28, requirement = "law", category = "law",
		difficulty = 6, requiresFlags = { "bar_license", "practicing_attorney" }, grantsFlags = { "experienced_attorney", "senior_lawyer" },
		description = "Requires experience as associate attorney" },
	{ id = "senior_partner", name = "Senior Partner", company = "Elite Law Firm", emoji = "⚖️", salary = 350000, minAge = 38, requirement = "law", category = "law",
		difficulty = 8, requiresFlags = { "experienced_attorney", "senior_lawyer", "litigation_experience" }, grantsFlags = { "law_firm_partner", "legal_leadership" },
		description = "Requires extensive legal career - partnership level" },
	{ id = "prosecutor", name = "Prosecutor", company = "District Attorney", emoji = "🏛️", salary = 95000, minAge = 28, requirement = "law", category = "law",
		difficulty = 5, grantsFlags = { "prosecution_experience", "courtroom_experience", "criminal_law" },
		description = "Requires law degree - government prosecution" },
	{ id = "public_defender", name = "Public Defender", company = "Public Defender's Office", emoji = "🏛️", salary = 72000, minAge = 26, requirement = "law", category = "law",
		difficulty = 4, grantsFlags = { "defense_experience", "courtroom_experience", "criminal_law" },
		description = "Requires law degree - public defense work" },
	{ id = "judge", name = "Judge", company = "Superior Court", emoji = "👨‍⚖️", salary = 195000, minAge = 45, requirement = "law", category = "law",
		difficulty = 9, requiresFlags = { "experienced_attorney", "courtroom_experience" }, grantsFlags = { "judicial_experience", "judge" },
		description = "Requires extensive legal career - appointed/elected position" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- FINANCE - CRITICAL FIX: Finance careers require proper progression!
	-- Can't just become a hedge fund manager without finance experience.
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "bank_teller", name = "Bank Teller", company = "First National Bank", emoji = "🏦", salary = 34000, minAge = 18, requirement = "high_school", category = "finance",
		difficulty = 2, grantsFlags = { "banking_experience", "financial_services", "customer_service" },
		description = "Entry point to banking career" },
	{ id = "loan_officer", name = "Loan Officer", company = "City Bank", emoji = "💰", salary = 58000, minAge = 22, requirement = "bachelor", category = "finance",
		difficulty = 3, requiresFlags = { "banking_experience", "financial_services" }, grantsFlags = { "loan_experience", "credit_analysis" },
		description = "Requires banking experience" },
	{ id = "accountant_jr", name = "Junior Accountant", company = "Financial Services", emoji = "📊", salary = 52000, minAge = 22, requirement = "bachelor", category = "finance",
		difficulty = 3, grantsFlags = { "accounting_experience", "financial_analysis", "bookkeeping" },
		description = "Entry point to accounting career" },
	{ id = "accountant", name = "Senior Accountant", company = "Big4 Accounting", emoji = "📊", salary = 78000, minAge = 25, requirement = "bachelor", category = "finance",
		difficulty = 4, requiresFlags = { "accounting_experience", "financial_analysis" }, grantsFlags = { "senior_accountant", "audit_experience" },
		description = "Requires junior accountant experience" },
	{ id = "cpa", name = "Certified Public Accountant", company = "CPA Partners", emoji = "📊", salary = 95000, minAge = 28, requirement = "bachelor", category = "finance",
		difficulty = 5, requiresFlags = { "senior_accountant", "accounting_experience" }, grantsFlags = { "cpa_certified", "tax_expert" },
		description = "Requires senior accountant experience and CPA exam" },
	{ id = "financial_analyst", name = "Financial Analyst", company = "Investment Group", emoji = "📈", salary = 85000, minAge = 23, requirement = "bachelor", category = "finance",
		difficulty = 4, minStats = { Smarts = 60 }, grantsFlags = { "financial_analysis", "investment_experience", "market_analysis" },
		description = "Requires analytical skills and finance degree" },
	{ id = "investment_banker_jr", name = "Investment Banking Analyst", company = "Goldman & Partners", emoji = "💹", salary = 120000, minAge = 22, requirement = "bachelor", category = "finance",
		difficulty = 6, minStats = { Smarts = 70 }, grantsFlags = { "investment_banking", "deal_experience", "wall_street" },
		description = "Highly competitive entry-level Wall Street position" },
	{ id = "investment_banker", name = "Investment Banker", company = "Wall Street Bank", emoji = "💹", salary = 225000, minAge = 28, requirement = "master", category = "finance",
		difficulty = 7, requiresFlags = { "investment_banking", "deal_experience" }, grantsFlags = { "senior_banker", "m_and_a_experience" },
		description = "Requires investment banking analyst experience" },
	{ id = "hedge_fund_manager", name = "Hedge Fund Manager", company = "Elite Capital", emoji = "🏦", salary = 750000, minAge = 35, requirement = "master", category = "finance",
		difficulty = 9, minStats = { Smarts = 80 }, requiresFlags = { "senior_banker", "investment_experience", "market_analysis" }, grantsFlags = { "fund_manager", "portfolio_management" },
		description = "Requires extensive investment banking experience" },
	-- REMOVED: Actuary job per user request (boring)
	{ id = "cfo", name = "Chief Financial Officer", company = "Fortune 500", emoji = "💼", salary = 450000, minAge = 42, requirement = "master", category = "finance",
		difficulty = 9, minStats = { Smarts = 80 }, requiresFlags = { "cpa_certified", "senior_accountant", "financial_analysis", "fund_manager" }, grantsFlags = { "c_level", "financial_executive" },
		description = "Requires extensive finance leadership - top executive position" },

	-- CREATIVE
	-- CRITICAL FIX #66: Creative jobs need proper progression flags
	{ id = "graphic_designer_jr", name = "Junior Graphic Designer", company = "Design Studio", emoji = "🎨", salary = 42000, minAge = 21, requirement = "bachelor", category = "creative",
		difficulty = 3, grantsFlags = { "design_experience", "creative_experience", "junior_designer" },
		description = "Entry-level design position" },
	{ id = "graphic_designer", name = "Graphic Designer", company = "Creative Agency", emoji = "🎨", salary = 62000, minAge = 24, requirement = "bachelor", category = "creative",
		difficulty = 4, requiresFlags = { "design_experience", "junior_designer" },
		grantsFlags = { "senior_designer", "creative_experience", "portfolio_experience" },
		description = "Requires junior designer experience" },
	-- CRITICAL FIX #64: Art Director requires design experience
	{ id = "art_director", name = "Art Director", company = "Top Agency", emoji = "🎨", salary = 115000, minAge = 30, requirement = "bachelor", category = "creative",
		difficulty = 6, requiresFlags = { "design_experience", "creative_experience" },
		grantsFlags = { "art_direction", "creative_leadership", "senior_creative" },
		description = "Requires graphic design experience to lead creative teams" },
	{ id = "photographer", name = "Photographer", company = "Photo Studio", emoji = "📷", salary = 48000, minAge = 18, requirement = nil, category = "creative" },
	{ id = "videographer", name = "Videographer", company = "Video Productions", emoji = "🎥", salary = 55000, minAge = 21, requirement = "bachelor", category = "creative" },
	{ id = "journalist_jr", name = "Junior Journalist", company = "City News", emoji = "📰", salary = 38000, minAge = 22, requirement = "bachelor", category = "creative" },
	{ id = "journalist", name = "Journalist", company = "National Times", emoji = "📰", salary = 62000, minAge = 26, requirement = "bachelor", category = "creative" },
	{ id = "editor", name = "Editor", company = "Publishing House", emoji = "✍️", salary = 72000, minAge = 28, requirement = "bachelor", category = "creative" },
	-- CRITICAL FIX #67: Marketing jobs need proper progression flags
	{ id = "social_media_manager", name = "Social Media Manager", company = "Digital Agency", emoji = "📱", salary = 55000, minAge = 22, requirement = "bachelor", category = "creative",
		difficulty = 3, grantsFlags = { "social_media_experience", "digital_marketing", "brand_experience" },
		description = "Manage social media presence for brands" },
	{ id = "marketing_associate", name = "Marketing Associate", company = "AdVenture Agency", emoji = "📈", salary = 52000, minAge = 22, requirement = "bachelor", category = "creative",
		difficulty = 3, grantsFlags = { "marketing_experience", "campaign_experience", "brand_experience" },
		description = "Entry-level marketing position" },
	{ id = "marketing_manager", name = "Marketing Manager", company = "Brand Corp", emoji = "📈", salary = 95000, minAge = 28, requirement = "bachelor", category = "creative",
		difficulty = 5, requiresFlags = { "marketing_experience", "campaign_experience" },
		grantsFlags = { "marketing_leadership", "campaign_success", "senior_marketing" },
		description = "Requires marketing experience" },
	-- CRITICAL FIX #65: CMO requires marketing leadership experience
	{ id = "cmo", name = "Chief Marketing Officer", company = "Fortune 500", emoji = "📢", salary = 320000, minAge = 40, requirement = "master", category = "creative",
		difficulty = 8, minStats = { Smarts = 70 },
		requiresFlags = { "marketing_leadership", "brand_experience", "campaign_success" },
		grantsFlags = { "c_level", "marketing_executive", "brand_executive" },
		description = "C-suite marketing position - requires marketing manager experience" },
	-- CRITICAL FIX #334: Creative careers need proper progression - can't just become movie star!
	{ id = "actor_extra", name = "Background Actor", company = "Hollywood Studios", emoji = "🎭", salary = 25000, minAge = 18, requirement = nil, category = "creative",
		difficulty = 2, minStats = { Looks = 35 }, grantsFlags = { "acting_experience", "film_industry" },
		description = "Entry point to acting career" },
	{ id = "actor", name = "Actor", company = "Talent Agency", emoji = "🎭", salary = 85000, minAge = 21, requirement = nil, category = "creative",
		difficulty = 7, minStats = { Looks = 55 }, requiresFlags = { "acting_experience", "drama_club", "theater_experience", "film_industry" }, grantsFlags = { "professional_actor", "celebrity" },
		description = "Requires acting experience (drama club, background work)" },
	{ id = "movie_star", name = "Movie Star", company = "Major Studios", emoji = "⭐", salary = 2500000, minAge = 25, requirement = nil, category = "creative",
		difficulty = 10, minStats = { Looks = 80 }, requiresFlags = { "professional_actor", "celebrity" }, grantsFlags = { "movie_star", "famous" },
		description = "Requires professional acting career - extreme talent and luck" },
	{ id = "musician_local", name = "Local Musician", company = "Self-Employed", emoji = "🎸", salary = 28000, minAge = 16, requirement = nil, category = "creative",
		difficulty = 3, requiresFlags = { "musician", "plays_instrument", "in_a_band", "music_lessons" }, grantsFlags = { "local_musician", "music_experience" },
		description = "Requires musical ability - local gigs and small venues" },
	{ id = "musician_signed", name = "Signed Musician", company = "Record Label", emoji = "🎸", salary = 95000, minAge = 20, requirement = nil, category = "creative",
		difficulty = 7, requiresFlags = { "local_musician", "music_experience" }, grantsFlags = { "signed_artist", "recording_artist" },
		description = "Requires local musician experience - record label contract" },
	{ id = "pop_star", name = "Pop Star", company = "Global Records", emoji = "🎤", salary = 5000000, minAge = 22, requirement = nil, category = "creative",
		difficulty = 10, minStats = { Looks = 70 }, requiresFlags = { "signed_artist", "recording_artist" }, grantsFlags = { "pop_star", "famous", "celebrity" },
		description = "Requires signed artist career - world-famous musical artist" },

	-- GOVERNMENT
	{ id = "postal_worker", name = "Postal Worker", company = "US Postal Service", emoji = "📮", salary = 45000, minAge = 18, requirement = "high_school", category = "government" },
	{ id = "dmv_clerk", name = "DMV Clerk", company = "Dept of Motor Vehicles", emoji = "🚗", salary = 38000, minAge = 18, requirement = "high_school", category = "government" },
	{ id = "social_worker", name = "Social Worker", company = "Family Services", emoji = "🤝", salary = 52000, minAge = 22, requirement = "bachelor", category = "government" },
	{ id = "probation_officer", name = "Probation Officer", company = "Corrections Dept", emoji = "🔒", salary = 55000, minAge = 22, requirement = "bachelor", category = "government" },
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- GOVERNMENT - CRITICAL FIX #27: Law enforcement and political careers require progression!
	-- Can't just become senator without political experience.
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "police_officer", name = "Police Officer", company = "City Police Dept", emoji = "👮", salary = 62000, minAge = 21, requirement = "high_school", category = "government",
		minStats = { Health = 50 }, difficulty = 3, grantsFlags = { "law_enforcement", "police_experience", "public_service" },
		description = "Must pass police academy fitness test" },
	{ id = "detective", name = "Detective", company = "City Police Dept", emoji = "🔍", salary = 85000, minAge = 28, requirement = "bachelor", category = "government",
		minStats = { Smarts = 55 }, difficulty = 5, requiresFlags = { "police_experience", "law_enforcement" }, grantsFlags = { "detective_experience", "investigator" },
		description = "Requires police officer experience" },
	{ id = "police_chief", name = "Police Chief", company = "City Police Dept", emoji = "👮‍♂️", salary = 145000, minAge = 40, requirement = "bachelor", category = "government",
		minStats = { Smarts = 60 }, difficulty = 7, requiresFlags = { "detective_experience", "law_enforcement" }, grantsFlags = { "police_leadership", "chief_experience" },
		description = "Requires detective/senior officer experience" },
	{ id = "firefighter", name = "Firefighter", company = "Fire Department", emoji = "🚒", salary = 58000, minAge = 18, requirement = "high_school", category = "government",
		minStats = { Health = 60 }, difficulty = 3, grantsFlags = { "firefighter_experience", "first_responder", "public_service" },
		description = "Requires physical fitness test" },
	{ id = "fire_captain", name = "Fire Captain", company = "Fire Department", emoji = "🚒", salary = 95000, minAge = 32, requirement = "high_school", category = "government",
		minStats = { Health = 55 }, difficulty = 4, requiresFlags = { "firefighter_experience", "first_responder" }, grantsFlags = { "fire_leadership" },
		description = "Requires firefighter experience" },
	{ id = "city_council", name = "City Council Member", company = "City Government", emoji = "🏛️", salary = 72000, minAge = 25, requirement = "bachelor", category = "government",
		difficulty = 5, grantsFlags = { "political_experience", "elected_official", "local_politics" },
		description = "Elected local government position" },
	{ id = "mayor", name = "Mayor", company = "City Hall", emoji = "🏛️", salary = 185000, minAge = 35, requirement = "bachelor", category = "government",
		difficulty = 7, requiresFlags = { "political_experience", "local_politics", "elected_official" }, grantsFlags = { "executive_experience", "city_leadership" },
		description = "Requires city council or political experience" },
	{ id = "fbi_agent", name = "FBI Agent", company = "Federal Bureau of Investigation", emoji = "🕵️", salary = 95000, minAge = 25, requirement = "bachelor", category = "government",
		difficulty = 6, minStats = { Smarts = 60, Health = 50 }, grantsFlags = { "federal_agent", "investigation_experience", "security_clearance" },
		description = "Federal law enforcement - rigorous background check" },
	{ id = "cia_agent", name = "CIA Agent", company = "Central Intelligence Agency", emoji = "🕵️‍♂️", salary = 105000, minAge = 26, requirement = "bachelor", category = "government",
		difficulty = 7, minStats = { Smarts = 65 }, grantsFlags = { "intelligence_agent", "covert_ops", "security_clearance" },
		description = "Central Intelligence Agency - top secret clearance required" },
	{ id = "diplomat", name = "Diplomat", company = "State Department", emoji = "🌍", salary = 125000, minAge = 30, requirement = "master", category = "government",
		difficulty = 6, minStats = { Smarts = 60 }, grantsFlags = { "diplomatic_experience", "foreign_service", "international_relations" },
		description = "Foreign service career" },
	{ id = "senator", name = "Senator", company = "US Senate", emoji = "🏛️", salary = 174000, minAge = 35, requirement = "bachelor", category = "government",
		difficulty = 9, minStats = { Smarts = 60 }, requiresFlags = { "political_experience", "elected_official", "executive_experience", "city_leadership", "state_politics" }, grantsFlags = { "national_politics", "senator_status", "legislative_experience" },
		description = "Requires prior political office (mayor, state rep, etc.)" },
	{ id = "president", name = "President", company = "United States", emoji = "🇺🇸", salary = 400000, minAge = 35, requirement = "bachelor", category = "government",
		difficulty = 10, minStats = { Smarts = 70 }, requiresFlags = { "senator_status", "national_politics", "executive_experience" }, grantsFlags = { "president", "commander_in_chief" },
		description = "Requires senator or governor experience - leader of the free world" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- EDUCATION - CRITICAL FIX #26: Education careers require proper progression!
	-- Can't just become a principal without teaching experience.
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "teaching_assistant", name = "Teaching Assistant", company = "Local School", emoji = "📚", salary = 28000, minAge = 18, requirement = "high_school", category = "education",
		difficulty = 2, grantsFlags = { "teaching_experience", "classroom_experience", "school_staff" },
		description = "Entry point to education career" },
	{ id = "substitute_teacher", name = "Substitute Teacher", company = "School District", emoji = "📚", salary = 32000, minAge = 21, requirement = "bachelor", category = "education",
		difficulty = 3, requiresFlags = { "teaching_experience", "classroom_experience" }, grantsFlags = { "substitute_teaching", "teacher_experience" },
		description = "Requires classroom experience" },
	{ id = "teacher", name = "Teacher", company = "Public School", emoji = "👨‍🏫", salary = 52000, minAge = 22, requirement = "bachelor", category = "education",
		difficulty = 4, grantsFlags = { "certified_teacher", "teacher_experience", "classroom_management" },
		description = "Full-time teaching position" },
	{ id = "department_head", name = "Department Head", company = "High School", emoji = "👨‍🏫", salary = 72000, minAge = 32, requirement = "master", category = "education",
		difficulty = 5, requiresFlags = { "certified_teacher", "teacher_experience" }, grantsFlags = { "department_leadership", "curriculum_experience" },
		description = "Requires years of teaching experience" },
	{ id = "principal", name = "School Principal", company = "Local School District", emoji = "🏫", salary = 105000, minAge = 38, requirement = "master", category = "education",
		difficulty = 7, requiresFlags = { "department_leadership", "certified_teacher" }, grantsFlags = { "school_administrator", "education_leadership" },
		description = "Requires department leadership experience" },
	{ id = "superintendent", name = "School Superintendent", company = "School District", emoji = "🏫", salary = 185000, minAge = 45, requirement = "phd", category = "education",
		difficulty = 9, requiresFlags = { "school_administrator", "education_leadership" }, grantsFlags = { "district_leadership", "education_executive" },
		description = "Requires principal/administration experience" },
	{ id = "professor_assistant", name = "Assistant Professor", company = "State University", emoji = "🎓", salary = 72000, minAge = 28, requirement = "phd", category = "education",
		difficulty = 6, grantsFlags = { "academic_research", "university_faculty", "higher_education" },
		description = "Requires PhD and research experience" },
	{ id = "professor", name = "Professor", company = "University", emoji = "🎓", salary = 115000, minAge = 35, requirement = "phd", category = "education",
		difficulty = 7, requiresFlags = { "academic_research", "university_faculty" }, grantsFlags = { "tenured_professor", "research_leader" },
		description = "Requires assistant professor experience" },
	{ id = "dean", name = "Dean", company = "University", emoji = "🎓", salary = 225000, minAge = 45, requirement = "phd", category = "education",
		difficulty = 9, requiresFlags = { "tenured_professor", "research_leader" }, grantsFlags = { "university_administration", "academic_leadership" },
		description = "Requires tenured professor experience" },

	-- SCIENCE - CRITICAL FIX: Science careers need proper progression flags!
	{ id = "lab_technician", name = "Lab Technician", company = "Research Lab", emoji = "🔬", salary = 42000, minAge = 22, requirement = "bachelor", category = "science",
		difficulty = 3, grantsFlags = { "lab_experience", "research_skills", "scientific_method" },
		description = "Entry-level laboratory work" },
	{ id = "research_assistant", name = "Research Assistant", company = "University Lab", emoji = "🔬", salary = 48000, minAge = 22, requirement = "bachelor", category = "science",
		difficulty = 3, requiresFlags = { "lab_experience", "research_skills" }, grantsFlags = { "research_experience", "academic_research", "data_analysis" },
		description = "Assist senior researchers with projects" },
	{ id = "scientist", name = "Scientist", company = "Research Institute", emoji = "🧪", salary = 85000, minAge = 26, requirement = "master", category = "science",
		difficulty = 5, requiresFlags = { "research_experience", "academic_research" }, grantsFlags = { "scientist", "published_researcher", "grant_writing" },
		description = "Conduct independent research" },
	{ id = "senior_scientist", name = "Senior Scientist", company = "BioTech Corp", emoji = "🧪", salary = 125000, minAge = 32, requirement = "phd", category = "science",
		difficulty = 7, requiresFlags = { "scientist", "published_researcher" }, grantsFlags = { "senior_researcher", "research_leadership", "principal_investigator" },
		description = "Lead research projects and mentor junior scientists" },
	{ id = "research_director", name = "Research Director", company = "Innovation Labs", emoji = "🔬", salary = 195000, minAge = 40, requirement = "phd", category = "science",
		difficulty = 8, requiresFlags = { "senior_researcher", "research_leadership" }, grantsFlags = { "research_director", "scientific_leadership" },
		description = "Direct entire research departments" },

	-- SPORTS - CRITICAL FIX #333: Sports careers now require proper progression!
	-- Can't just become professional athlete - need to play sports as kid/teen
	-- CRITICAL FIX: Using OR logic via multiple possible flags in requiresFlags
	{ id = "gym_instructor", name = "Gym Instructor", company = "Fitness Center", emoji = "🏋️", salary = 35000, minAge = 18, requirement = nil, category = "sports",
		minStats = { Health = 60 }, difficulty = 2, 
		grantsFlags = { "fitness_experience", "trainer" },
		description = "Must be in excellent physical shape" },
	{ id = "minor_league", name = "Minor League Player", company = "Farm Team", emoji = "⚾", salary = 45000, minAge = 18, requirement = nil, category = "sports",
		minStats = { Health = 70 }, difficulty = 6, 
		requiresFlags = { "athlete", "school_sports", "plays_soccer", "plays_basketball", "varsity_athlete", "team_player", "camp_athlete" }, -- CRITICAL FIX: Need actual sports background
		grantsFlags = { "minor_league_player", "pro_sports_experience", "professional_athlete_training" },
		description = "Requires high school/college sports experience - must have played organized sports" },
	{ id = "professional_athlete", name = "Professional Athlete", company = "Sports Team", emoji = "🏆", salary = 450000, minAge = 21, requirement = nil, category = "sports",
		minStats = { Health = 80 }, difficulty = 9, 
		requiresFlags = { "minor_league_player", "pro_sports_experience" }, -- CRITICAL FIX: Must go through minor leagues
		grantsFlags = { "pro_athlete", "sports_star", "famous_athlete" },
		description = "Requires minor league experience - elite athletic ability" },
	{ id = "star_athlete", name = "Star Athlete", company = "Champion Team", emoji = "⭐", salary = 8000000, minAge = 24, requirement = nil, category = "sports",
		minStats = { Health = 85 }, difficulty = 10, 
		requiresFlags = { "pro_athlete", "sports_star" }, -- CRITICAL FIX: Must be pro first
		grantsFlags = { "superstar_athlete", "sports_legend", "sports_icon" },
		description = "Requires pro athlete career - world-class ability" },
	{ id = "sports_coach", name = "Sports Coach", company = "High School", emoji = "📋", salary = 55000, minAge = 25, requirement = "bachelor", category = "sports",
		minStats = { Smarts = 45 }, difficulty = 4, 
		requiresFlags = { "athlete", "school_sports", "fitness_experience", "minor_league_player", "pro_athlete", "coach_experience" }, -- CRITICAL FIX: Need athletic background OR coaching experience
		grantsFlags = { "coach_experience", "coaching_career" },
		description = "Requires athletic background - teaching and athletic knowledge" },
	{ id = "head_coach", name = "Head Coach", company = "Pro Team", emoji = "📋", salary = 1500000, minAge = 40, requirement = "bachelor", category = "sports",
		minStats = { Smarts = 65 }, difficulty = 8, 
		requiresFlags = { "coach_experience", "coaching_career" }, -- CRITICAL FIX: Must have coaching experience
		grantsFlags = { "head_coach", "elite_coach" },
		description = "Requires coaching experience - elite coaching position" },

	-- MILITARY - CRITICAL FIX: All military jobs now require fitness and have proper progression flags!
	{ id = "enlisted", name = "Enlisted Soldier", company = "US Army", emoji = "🪖", salary = 35000, minAge = 18, requirement = "high_school", category = "military",
		minStats = { Health = 55 }, difficulty = 3, grantsFlags = { "military_experience", "enlisted", "combat_training" },
		description = "Must pass physical fitness test" },
	{ id = "sergeant", name = "Sergeant", company = "US Army", emoji = "🪖", salary = 55000, minAge = 24, requirement = "high_school", category = "military",
		minStats = { Health = 50 }, difficulty = 4, requiresFlags = { "military_experience", "enlisted" }, grantsFlags = { "nco", "leadership_experience", "combat_veteran" },
		description = "Leadership and combat experience required" },
	{ id = "officer", name = "Military Officer", company = "US Armed Forces", emoji = "🎖️", salary = 75000, minAge = 22, requirement = "bachelor", category = "military",
		minStats = { Health = 50, Smarts = 50 }, difficulty = 5, grantsFlags = { "military_officer", "commissioned", "leadership_experience" },
		description = "Requires degree and fitness" },
	{ id = "captain", name = "Captain", company = "US Armed Forces", emoji = "🎖️", salary = 95000, minAge = 28, requirement = "bachelor", category = "military",
		minStats = { Health = 45, Smarts = 55 }, difficulty = 6, requiresFlags = { "military_officer", "commissioned" }, grantsFlags = { "company_commander", "tactical_leadership" },
		description = "Advanced military leadership" },
	{ id = "colonel", name = "Colonel", company = "US Armed Forces", emoji = "🎖️", salary = 135000, minAge = 38, requirement = "master", category = "military",
		minStats = { Smarts = 60 }, difficulty = 7, requiresFlags = { "company_commander", "tactical_leadership" }, grantsFlags = { "senior_officer", "strategic_command" },
		description = "High command position" },
	{ id = "general", name = "General", company = "Pentagon", emoji = "⭐", salary = 220000, minAge = 50, requirement = "master", category = "military",
		minStats = { Smarts = 70 }, difficulty = 9, requiresFlags = { "senior_officer", "strategic_command" }, grantsFlags = { "general_officer", "top_brass" },
		description = "Top military leadership" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRIMINAL CAREERS - CRITICAL FIX #22: Criminal careers require proper crime background!
	-- Can't just become a crime boss without any criminal history.
	-- Must start with petty crimes and work your way up the underworld ladder.
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "illegal_dealer_street", name = "Street Hustler", company = "The Streets", emoji = "💰", salary = 35000, minAge = 16, requirement = nil, category = "criminal", illegal = true,
		difficulty = 3, 
		requiresFlags = { "petty_criminal", "street_smart", "vandal", "shoplifter", "delinquent", "criminal_tendencies", "bully", "troublemaker" }, -- CRITICAL: Need some criminal background
		grantsFlags = { "street_hustler", "drug_dealer_experience", "criminal_path", "criminal" },
		description = "Entry to crime life - requires history of petty crimes (shoplifting, vandalism, etc.)" },
	{ id = "illegal_dealer", name = "Illegal Dealer", company = "The Organization", emoji = "💰", salary = 100000, minAge = 20, requirement = nil, category = "criminal", illegal = true,
		difficulty = 5,
		requiresFlags = { "street_hustler", "drug_dealer_experience", "criminal_path" }, -- CRITICAL: Must have street hustler experience
		grantsFlags = { "established_dealer", "drug_network", "criminal_connections" },
		description = "Established dealer - requires street hustler experience" },
	{ id = "enforcer", name = "Enforcer", company = "Unknown", emoji = "💪", salary = 180000, minAge = 25, requirement = nil, category = "criminal", illegal = true,
		difficulty = 6, minStats = { Health = 60 },
		requiresFlags = { "criminal_path", "criminal_connections", "violent_crimes", "street_fighter", "brawler" }, -- Need violent background
		grantsFlags = { "enforcer_reputation", "feared", "muscle" },
		description = "Criminal muscle - requires violent crime history" },
	{ id = "crew_member", name = "Crew Member", company = "The Crew", emoji = "🤝", salary = 50000, minAge = 18, requirement = nil, category = "criminal", illegal = true,
		difficulty = 4,
		requiresFlags = { "criminal_path", "street_hustler", "criminal_connections", "street_smart", "in_mob" }, -- Need criminal background or mob membership
		grantsFlags = { "crew_member_status", "organized_crime", "loyalty_tested" },
		description = "Join a criminal crew - requires criminal background or mob membership" },
	{ id = "crew_leader", name = "Crew Leader", company = "The Crew", emoji = "🔥", salary = 140000, minAge = 22, requirement = nil, category = "criminal", illegal = true,
		difficulty = 7, minStats = { Smarts = 50 },
		requiresFlags = { "crew_member_status", "organized_crime", "loyalty_tested" }, -- CRITICAL: Must be crew member first
		grantsFlags = { "crew_leader_status", "criminal_leadership", "respected_criminal" },
		description = "Lead a criminal crew - requires crew member experience" },
	{ id = "crime_boss", name = "Crime Boss", company = "The Syndicate", emoji = "🎩", salary = 500000, minAge = 30, requirement = nil, category = "criminal", illegal = true,
		difficulty = 9, minStats = { Smarts = 65 },
		requiresFlags = { "crew_leader_status", "criminal_leadership", "respected_criminal" }, -- CRITICAL: Must be crew leader first
		grantsFlags = { "crime_boss_status", "syndicate_leader", "kingpin" },
		description = "Run a criminal empire - requires crew leader experience" },
	{ id = "smuggler", name = "Smuggler", company = "Import/Export", emoji = "📦", salary = 85000, minAge = 21, requirement = nil, category = "criminal", illegal = true,
		difficulty = 5,
		requiresFlags = { "criminal_path", "criminal_connections", "street_hustler" }, -- Need criminal network
		grantsFlags = { "smuggling_experience", "international_crime" },
		description = "Run smuggling operations - requires criminal network" },
	{ id = "fence", name = "Fence", company = "Underground Market", emoji = "💎", salary = 75000, minAge = 20, requirement = nil, category = "criminal", illegal = true,
		difficulty = 4,
		requiresFlags = { "criminal_path", "thief", "burglar", "shoplifter", "criminal_connections" }, -- Need theft background
		grantsFlags = { "fence_reputation", "black_market_connections" },
		description = "Deal in stolen goods - requires theft experience" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- RACING CAREER PATH
	-- CRITICAL FIX #332: Racing now requires proper progression through experience flags!
	-- Must start at go-karts, work your way up. Can't just become professional racer!
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "go_kart_racer", name = "Go-Kart Racer", company = "Local Karting League", emoji = "🏎️", salary = 15000, minAge = 12, requirement = nil, category = "racing", 
		minStats = { Health = 50 }, difficulty = 3, grantsFlags = { "karting_experience", "racing_experience" },
		description = "Start your racing career on the track" },
	{ id = "amateur_racer", name = "Amateur Racer", company = "Regional Racing Circuit", emoji = "🏎️", salary = 35000, minAge = 16, requirement = nil, category = "racing",
		minStats = { Health = 60 }, difficulty = 5, requiresFlags = { "karting_experience", "racing_experience" }, grantsFlags = { "amateur_racing", "racing_experience" },
		description = "Compete in regional amateur racing series - requires go-kart experience" },
	{ id = "professional_racer", name = "Professional Racer", company = "National Racing Series", emoji = "🏁", salary = 150000, minAge = 18, requirement = nil, category = "racing",
		minStats = { Health = 70 }, difficulty = 7, requiresFlags = { "amateur_racing" }, grantsFlags = { "pro_racer", "racing_experience" },
		description = "Race professionally - requires amateur racing experience" },
	{ id = "f1_driver", name = "Formula 1 Driver", company = "F1 Racing Team", emoji = "🏆", salary = 2500000, minAge = 21, requirement = nil, category = "racing",
		minStats = { Health = 80 }, difficulty = 9, requiresFlags = { "pro_racer" }, grantsFlags = { "f1_experience", "racing_champion" },
		description = "The pinnacle of motorsport - requires professional racing career" },
	{ id = "racing_legend", name = "Racing Legend", company = "Racing Hall of Fame", emoji = "👑", salary = 15000000, minAge = 28, requirement = nil, category = "racing",
		minStats = { Health = 75 }, difficulty = 10, requiresFlags = { "f1_experience", "racing_champion" }, grantsFlags = { "racing_legend" },
		description = "Multi-champion, legend status - requires F1 experience" },
	{ id = "racing_team_owner", name = "Racing Team Owner", company = "Your Racing Team", emoji = "🏢", salary = 5000000, minAge = 35, requirement = nil, category = "racing",
		difficulty = 6, requiresFlags = { "pro_racer", "racing_experience" }, grantsFlags = { "team_owner" },
		description = "Own and manage a professional racing team - requires racing background" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- HACKER/CYBERSECURITY CAREER PATH
	-- Two branches: White Hat (legit) or Black Hat (criminal)
	-- Requires: High Smarts, tech skills
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- Entry points (shared) - These give experience flags for higher-tier jobs
	{ id = "script_kiddie", name = "Script Kiddie", company = "The Internet", emoji = "👶💻", salary = 1500, minAge = 14, requirement = nil, category = "hacker",
		minStats = { Smarts = 55 }, grantsFlags = { "coder", "tech_experience" }, description = "Learning to hack with pre-made tools - small side gigs" },
	{ id = "freelance_hacker", name = "Freelance Hacker", company = "Dark Web", emoji = "🖥️", salary = 60000, minAge = 18, requirement = nil, category = "hacker",
		minStats = { Smarts = 65 }, requiresFlags = { "coder", "tech_experience" }, grantsFlags = { "hacker_experience" }, description = "Taking small hacking jobs online" },
	
	-- White Hat Path (Legit Cybersecurity)
	{ id = "pen_tester", name = "Penetration Tester", company = "SecureIT Solutions", emoji = "🔓", salary = 95000, minAge = 20, requirement = "high_school", category = "tech",
		minStats = { Smarts = 70 }, description = "Legally hack companies to find vulnerabilities" },
	{ id = "security_consultant", name = "Security Consultant", company = "CyberGuard Inc", emoji = "🛡️", salary = 165000, minAge = 25, requirement = "bachelor", category = "tech",
		minStats = { Smarts = 75 }, description = "Advise companies on cybersecurity" },
	{ id = "ciso", name = "Chief Information Security Officer", company = "Fortune 500", emoji = "🔐", salary = 420000, minAge = 32, requirement = "bachelor", category = "tech",
		minStats = { Smarts = 80 }, description = "Lead security for a major corporation" },
	
	-- Black Hat Path (Criminal Hacker)
	-- CRITICAL FIX: Hacker jobs now require prior coding/tech experience!
	{ id = "black_hat_hacker", name = "Black Hat Hacker", company = "Underground", emoji = "🎭", salary = 200000, minAge = 22, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 75 }, requiresFlags = { "coder", "tech_experience" }, description = "Requires coding experience to hack" },
	{ id = "elite_hacker", name = "Elite Hacker", company = "Anonymous Collective", emoji = "👤", salary = 500000, minAge = 26, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 85 }, requiresFlags = { "hacker_experience" }, grantsFlags = { "elite_hacker_rep", "elite_hacker" }, description = "Must have proven hacking skills" },
	{ id = "cyber_crime_boss", name = "Cyber Crime Boss", company = "The Syndicate", emoji = "💀", salary = 2000000, minAge = 32, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 90 }, requiresFlags = { "elite_hacker_rep" }, grantsFlags = { "cyber_crime_history" }, description = "Must be a known elite hacker" },
	{ id = "ransomware_kingpin", name = "Ransomware Kingpin", company = "Shadow Network", emoji = "☠️", salary = 10000000, minAge = 30, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 95 }, requiresFlags = { "cyber_crime_history" }, description = "Must have cyber crime background" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- ESPORTS CAREER PATH
	-- CRITICAL FIX: Modern gaming career requires proper progression!
	-- Must have gamer flag from childhood/teen gaming hobby to enter this career
	-- Can't just become a $150K pro gamer at 17 without gaming background!
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "casual_gamer", name = "Casual Streamer", company = "Twitch", emoji = "🎮", salary = 5000, minAge = 13, requirement = nil, category = "esports",
		minStats = { Smarts = 40 }, difficulty = 2,
		requiresFlags = { "gamer", "loves_games", "casual_gamer", "tech_savvy" }, -- CRITICAL FIX: Must be a gamer!
		grantsFlags = { "streamer", "content_creator_experience", "esports_experience" },
		description = "Stream games with a small following - requires gaming hobby" },
	{ id = "content_creator", name = "Gaming Content Creator", company = "YouTube Gaming", emoji = "📹", salary = 25000, minAge = 16, requirement = nil, category = "esports",
		minStats = { Smarts = 50 }, difficulty = 4,
		requiresFlags = { "gamer", "streamer", "content_creator_experience", "esports_experience" }, -- CRITICAL FIX: Must have streaming experience
		grantsFlags = { "youtube_gamer", "content_creator", "growing_audience" },
		description = "Create gaming content with growing audience - requires streaming experience" },
	{ id = "pro_gamer", name = "Pro Gamer", company = "Esports Organization", emoji = "🕹️", salary = 65000, minAge = 17, requirement = nil, category = "esports",
		minStats = { Smarts = 60, Health = 50 }, difficulty = 7,
		requiresFlags = { "youtube_gamer", "content_creator", "competitive_gamer", "esports_winner", "esports_experience" }, -- CRITICAL FIX: Need proven competitive gaming history
		grantsFlags = { "pro_gamer", "esports_pro", "signed_gamer" },
		description = "Compete professionally in esports - requires competitive gaming history" },
	{ id = "esports_champion", name = "Esports Champion", company = "World Champions", emoji = "🏆", salary = 350000, minAge = 18, requirement = nil, category = "esports",
		minStats = { Smarts = 70, Health = 55 }, difficulty = 9,
		requiresFlags = { "pro_gamer", "esports_pro", "signed_gamer" }, -- CRITICAL FIX: Must be pro gamer first
		grantsFlags = { "esports_champion", "world_champion_gamer", "gaming_celebrity" },
		description = "World champion esports player - requires professional gaming career" },
	{ id = "gaming_legend", name = "Gaming Legend", company = "Hall of Fame", emoji = "👑", salary = 2000000, minAge = 22, requirement = nil, category = "esports",
		minStats = { Smarts = 75 }, difficulty = 10,
		requiresFlags = { "esports_champion", "world_champion_gamer" }, -- CRITICAL FIX: Must be champion first
		grantsFlags = { "gaming_legend", "esports_legend", "gaming_hall_of_fame" },
		description = "Legendary status in gaming history - requires championship titles" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CELEBRITY/FAME CAREERS - CRITICAL FIX #32-46: Fame career jobs need proper IDs!
	-- These are used by CelebrityEvents.lua for the Celebrity gamepass feature.
	-- Without proper IDs, they show as "Unknown Job" in the UI.
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- RAPPER CAREER PATH - REQUIRES CELEBRITY GAMEPASS
	-- User feedback: "ENSURE IT WORKS FOR BEING A RAPPER OR SOMETHING NOT A YOUTUBER"
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "underground_rapper", name = "Underground Rapper", company = "Independent", emoji = "🎤", salary = 250, minAge = 14, requirement = nil, category = "entertainment",
		difficulty = 2, grantsFlags = { "rapper", "underground_artist", "hip_hop_experience", "pursuing_rap" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Starting your rap career from the underground" },
	{ id = "local_rapper", name = "Local Rapper", company = "Local Scene", emoji = "📍", salary = 3000, minAge = 16, requirement = nil, category = "entertainment",
		difficulty = 4, requiresFlags = { "underground_artist", "rapper" }, grantsFlags = { "local_fame", "music_industry" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Known in your local hip-hop scene" },
	{ id = "buzzing_rapper", name = "Buzzing Rapper", company = "Blog Circuit", emoji = "🔊", salary = 25000, minAge = 17, requirement = nil, category = "entertainment",
		difficulty = 5, requiresFlags = { "local_fame", "rapper" }, grantsFlags = { "buzz", "viral_potential" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "The blogs are talking about you" },
	{ id = "signed_rapper", name = "Signed Rapper", company = "Record Label", emoji = "📝", salary = 125000, minAge = 18, requirement = nil, category = "entertainment",
		difficulty = 6, requiresFlags = { "buzz", "rapper" }, grantsFlags = { "signed_artist", "label_deal" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Signed to a major or indie label" },
	{ id = "hot_rapper", name = "Hot Rapper", company = "Major Label", emoji = "🔥", salary = 500000, minAge = 19, requirement = nil, category = "entertainment",
		difficulty = 7, requiresFlags = { "signed_artist", "rapper" }, grantsFlags = { "charting_artist", "hit_maker" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "You've got multiple hits" },
	{ id = "mainstream_rapper", name = "Mainstream Rapper", company = "Global Records", emoji = "⭐", salary = 3000000, minAge = 20, requirement = nil, category = "entertainment",
		difficulty = 8, requiresFlags = { "charting_artist", "rapper" }, grantsFlags = { "mainstream_fame", "celebrity" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Household name status" },
	{ id = "superstar_rapper", name = "Superstar Rapper", company = "Empire Records", emoji = "💎", salary = 25000000, minAge = 22, requirement = nil, category = "entertainment",
		difficulty = 9, requiresFlags = { "mainstream_fame", "rapper" }, grantsFlags = { "superstar", "mogul" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "One of the biggest names in hip-hop" },
	{ id = "legend_rapper", name = "Hip-Hop Legend", company = "Hall of Fame", emoji = "👑", salary = 90000000, minAge = 28, requirement = nil, category = "entertainment",
		difficulty = 10, requiresFlags = { "superstar", "rapper" }, grantsFlags = { "legend", "goat_status" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "A true legend of hip-hop" },
	
	-- INFLUENCER/CONTENT CREATOR CAREER PATH (Celebrity gamepass)
	{ id = "new_creator", name = "New Creator", company = "Social Media", emoji = "📱", salary = 2000, minAge = 13, requirement = nil, category = "entertainment",
		difficulty = 1, grantsFlags = { "content_creator", "social_media_presence" }, isFameCareer = true,
		description = "Just starting your social media journey" },
	-- CRITICAL FIX #AAA-2: Add alias for client compatibility (client uses new_influencer)
	{ id = "new_influencer", name = "New Content Creator", company = "Instagram/TikTok", emoji = "📱", salary = 5000, minAge = 13, requirement = nil, category = "entertainment",
		difficulty = 1, grantsFlags = { "content_creator", "social_media_presence", "influencer" }, isFameCareer = true,
		description = "Just starting your content creation journey" },
	{ id = "micro_influencer", name = "Micro-Influencer", company = "Social Media", emoji = "📊", salary = 15000, minAge = 14, requirement = nil, category = "entertainment",
		difficulty = 3, requiresFlags = { "content_creator" }, grantsFlags = { "influencer", "small_following" }, isFameCareer = true,
		description = "Building a small but engaged following" },
	{ id = "rising_influencer", name = "Rising Influencer", company = "Social Media", emoji = "📈", salary = 25000, minAge = 15, requirement = nil, category = "entertainment",
		difficulty = 4, requiresFlags = { "influencer" }, grantsFlags = { "growing_audience", "brand_potential" }, isFameCareer = true,
		description = "Your audience is growing fast" },
	{ id = "established_influencer", name = "Established Influencer", company = "Brand Partnerships", emoji = "🤝", salary = 150000, minAge = 17, requirement = nil, category = "entertainment",
		difficulty = 6, requiresFlags = { "growing_audience" }, grantsFlags = { "brand_deals", "influencer_marketing" }, isFameCareer = true,
		description = "Brands want to work with you" },
	{ id = "major_influencer", name = "Major Influencer", company = "Management Agency", emoji = "⭐", salary = 750000, minAge = 18, requirement = nil, category = "entertainment",
		difficulty = 7, requiresFlags = { "brand_deals" }, grantsFlags = { "major_following", "celebrity_status" }, isFameCareer = true,
		description = "Millions of followers" },
	{ id = "mega_influencer", name = "Mega Influencer", company = "Global Brand", emoji = "🌟", salary = 5000000, minAge = 20, requirement = nil, category = "entertainment",
		difficulty = 9, requiresFlags = { "major_following" }, grantsFlags = { "mega_fame", "household_name" }, isFameCareer = true,
		description = "A household name on social media" },
	
	-- STREAMER CAREER PATH (Celebrity gamepass)
	{ id = "hobbyist_streamer", name = "Hobbyist Streamer", company = "Twitch", emoji = "🎥", salary = 1000, minAge = 13, requirement = nil, category = "entertainment",
		difficulty = 1, grantsFlags = { "streamer", "broadcaster", "pursuing_streaming" }, isFameCareer = true,
		description = "Stream as a hobby - just for fun!" },
	{ id = "new_streamer", name = "New Streamer", company = "Twitch", emoji = "🎮", salary = 3000, minAge = 13, requirement = nil, category = "entertainment",
		difficulty = 1, grantsFlags = { "streamer", "broadcaster", "pursuing_streaming" }, isFameCareer = true,
		description = "Just started streaming" },
	{ id = "affiliate_streamer", name = "Affiliate Streamer", company = "Twitch", emoji = "💜", salary = 8000, minAge = 14, requirement = nil, category = "entertainment",
		difficulty = 3, requiresFlags = { "streamer" }, grantsFlags = { "affiliate", "monetized" }, isFameCareer = true,
		description = "Earned affiliate status" },
	{ id = "partner_streamer", name = "Partner Streamer", company = "Twitch", emoji = "✅", salary = 15000, minAge = 16, requirement = nil, category = "entertainment",
		difficulty = 5, requiresFlags = { "affiliate" }, grantsFlags = { "partner", "verified_streamer" }, isFameCareer = true,
		description = "Full partner with perks" },
	{ id = "popular_streamer", name = "Popular Streamer", company = "Multi-Platform", emoji = "📺", salary = 150000, minAge = 17, requirement = nil, category = "entertainment",
		difficulty = 6, requiresFlags = { "partner" }, grantsFlags = { "popular_broadcaster", "streaming_income" }, isFameCareer = true,
		description = "Thousands watch your streams" },
	{ id = "famous_streamer", name = "Famous Streamer", company = "Exclusive Contract", emoji = "⭐", salary = 1000000, minAge = 18, requirement = nil, category = "entertainment",
		difficulty = 8, requiresFlags = { "popular_broadcaster" }, grantsFlags = { "famous_streamer", "platform_face" }, isFameCareer = true,
		description = "One of the biggest streamers" },
	{ id = "streaming_legend", name = "Streaming Legend", company = "Hall of Fame", emoji = "👑", salary = 10000000, minAge = 22, requirement = nil, category = "entertainment",
		difficulty = 10, requiresFlags = { "famous_streamer" }, grantsFlags = { "streaming_legend", "icon" }, isFameCareer = true,
		description = "A legend of the streaming world" },
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- MUSIC CAREER PATH - REQUIRES CELEBRITY GAMEPASS
	-- Entry-level (street performer, local artist) is FREE but signed/pro requires gamepass
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "street_performer", name = "Street Performer", company = "Self-Employed", emoji = "🎸", salary = 275, minAge = 10, requirement = nil, category = "entertainment",
		difficulty = 1, grantsFlags = { "performer", "busker" }, isFameCareer = true,
		description = "Playing for tips on the street" },
	{ id = "local_artist", name = "Local Artist", company = "Local Venues", emoji = "🎤", salary = 3000, minAge = 14, requirement = nil, category = "entertainment",
		difficulty = 3, requiresFlags = { "performer" }, grantsFlags = { "local_musician", "venue_experience" }, isFameCareer = true,
		description = "Known in your local music scene" },
	{ id = "indie_artist", name = "Indie Artist", company = "Independent", emoji = "🎵", salary = 25000, minAge = 16, requirement = nil, category = "entertainment",
		difficulty = 4, requiresFlags = { "local_musician" }, grantsFlags = { "indie_artist", "self_released" }, isFameCareer = true,
		description = "Self-released music gaining traction" },
	{ id = "signed_artist", name = "Signed Artist", company = "Record Label", emoji = "📝", salary = 100000, minAge = 18, requirement = nil, category = "entertainment",
		difficulty = 6, requiresFlags = { "indie_artist" }, grantsFlags = { "signed_artist", "label_support" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Signed to a record label - requires Celebrity Gamepass" },
	{ id = "touring_artist", name = "Touring Artist", company = "Major Label", emoji = "🚌", salary = 350000, minAge = 19, requirement = nil, category = "entertainment",
		difficulty = 7, requiresFlags = { "signed_artist" }, grantsFlags = { "touring_musician", "headliner" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Headlining your own tours" },
	{ id = "platinum_artist", name = "Platinum Artist", company = "Global Records", emoji = "💿", salary = 3000000, minAge = 20, requirement = nil, category = "entertainment",
		difficulty = 8, requiresFlags = { "touring_musician" }, grantsFlags = { "platinum_seller", "award_winner" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Selling millions of records" },
	{ id = "music_superstar", name = "Superstar", company = "Universal Music", emoji = "🌟", salary = 30000000, minAge = 22, requirement = nil, category = "entertainment",
		difficulty = 9, requiresFlags = { "platinum_seller" }, grantsFlags = { "music_superstar", "global_fame" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Global superstar status" },
	{ id = "music_icon", name = "Music Icon", company = "Hall of Fame", emoji = "👑", salary = 90000000, minAge = 28, requirement = nil, category = "entertainment",
		difficulty = 10, requiresFlags = { "music_superstar" }, grantsFlags = { "music_icon", "legend" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "An icon of the music industry" },
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- ACTING CAREER PATH - REQUIRES CELEBRITY GAMEPASS for higher tiers
	-- Entry-level (extra, background actor) is FREE but speaking roles+ require gamepass
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "extra", name = "Extra", company = "Casting Agency", emoji = "👥", salary = 1250, minAge = 6, requirement = nil, category = "entertainment",
		difficulty = 1, grantsFlags = { "actor", "background_work" }, isFameCareer = true,
		description = "Stand in the background of scenes" },
	{ id = "background_actor", name = "Background Actor", company = "Film Studios", emoji = "🎭", salary = 5000, minAge = 12, requirement = nil, category = "entertainment",
		difficulty = 2, requiresFlags = { "actor" }, grantsFlags = { "featured_extra", "set_experience" }, isFameCareer = true,
		description = "Featured background roles" },
	{ id = "bit_part_actor", name = "Bit Part Actor", company = "TV Studios", emoji = "🗣️", salary = 16500, minAge = 16, requirement = nil, category = "entertainment",
		difficulty = 4, requiresFlags = { "featured_extra" }, grantsFlags = { "speaking_role", "sag_card" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Small speaking roles - requires Celebrity Gamepass" },
	{ id = "guest_star", name = "Guest Star", company = "Network TV", emoji = "📺", salary = 50000, minAge = 18, requirement = nil, category = "entertainment",
		difficulty = 5, requiresFlags = { "speaking_role" }, grantsFlags = { "recurring_role", "tv_presence" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Recurring guest appearances on TV shows" },
	{ id = "supporting_actor", name = "Supporting Actor", company = "Film Production", emoji = "🎬", salary = 137500, minAge = 20, requirement = nil, category = "entertainment",
		difficulty = 6, requiresFlags = { "recurring_role" }, grantsFlags = { "film_actor", "award_potential" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Notable supporting roles in films" },
	{ id = "tv_lead", name = "TV Lead", company = "Major Network", emoji = "📺", salary = 350000, minAge = 22, requirement = nil, category = "entertainment",
		difficulty = 7, requiresFlags = { "film_actor" }, grantsFlags = { "lead_actor", "show_star" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Lead your own TV series" },
	{ id = "movie_star_fame", name = "Movie Star", company = "Major Studios", emoji = "🎥", salary = 5500000, minAge = 24, requirement = nil, category = "entertainment",
		difficulty = 8, requiresFlags = { "lead_actor" }, grantsFlags = { "movie_star", "a_lister" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Lead roles in major films" },
	{ id = "a_list_celebrity", name = "A-List Celebrity", company = "Hollywood Elite", emoji = "⭐", salary = 20000000, minAge = 26, requirement = nil, category = "entertainment",
		difficulty = 9, requiresFlags = { "movie_star" }, grantsFlags = { "a_list", "hollywood_royalty" }, isFameCareer = true,
		requiresCelebrityGamepass = true,
		description = "Hollywood's elite" },
	{ id = "hollywood_legend", name = "Hollywood Legend", company = "Hall of Fame", emoji = "👑", salary = 62500000, minAge = 35, requirement = nil, category = "entertainment",
		difficulty = 10, requiresFlags = { "a_list" }, grantsFlags = { "hollywood_legend", "cinema_icon" }, isFameCareer = true,
		description = "An icon of cinema" },
	
	-- ATHLETE CAREER PATH (Celebrity gamepass)
	{ id = "amateur_athlete", name = "Amateur", company = "Local Leagues", emoji = "🏃", salary = 250, minAge = 14, requirement = nil, category = "entertainment",
		difficulty = 2, minStats = { Health = 60 }, grantsFlags = { "athlete", "amateur_status" }, isFameCareer = true,
		description = "Competing at amateur level" },
	{ id = "college_athlete", name = "College Athlete", company = "University", emoji = "🎓", salary = 0, minAge = 18, requirement = nil, category = "entertainment",
		difficulty = 4, minStats = { Health = 70 }, requiresFlags = { "amateur_status" }, grantsFlags = { "college_sports", "scholarship" }, isFameCareer = true,
		description = "Playing for your college team" },
	{ id = "pro_prospect", name = "Pro Prospect", company = "Draft Pool", emoji = "📋", salary = 50000, minAge = 20, requirement = nil, category = "entertainment",
		difficulty = 6, minStats = { Health = 75 }, requiresFlags = { "college_sports" }, grantsFlags = { "draft_eligible", "pro_potential" }, isFameCareer = true,
		description = "Scouts are watching" },
	{ id = "pro_athlete_fame", name = "Professional Athlete", company = "Pro Team", emoji = "🏆", salary = 1000000, minAge = 21, requirement = nil, category = "entertainment",
		difficulty = 7, minStats = { Health = 80 }, requiresFlags = { "pro_potential" }, grantsFlags = { "pro_athlete", "team_player" }, isFameCareer = true,
		description = "Playing professionally" },
	{ id = "star_player", name = "Star Player", company = "Champion Team", emoji = "⭐", salary = 15000000, minAge = 23, requirement = nil, category = "entertainment",
		difficulty = 8, minStats = { Health = 85 }, requiresFlags = { "pro_athlete" }, grantsFlags = { "star_athlete", "mvp_candidate" }, isFameCareer = true,
		description = "One of the best in the league" },
	{ id = "sports_legend", name = "Sports Legend", company = "Hall of Fame", emoji = "👑", salary = 50000000, minAge = 28, requirement = nil, category = "entertainment",
		difficulty = 10, minStats = { Health = 80 }, requiresFlags = { "star_athlete" }, grantsFlags = { "sports_legend", "hall_of_famer" }, isFameCareer = true,
		description = "A legend of the sport" },
	
	-- MODEL CAREER PATH (Celebrity gamepass)
	{ id = "amateur_model", name = "Amateur Model", company = "Local Agency", emoji = "📸", salary = 550, minAge = 14, requirement = nil, category = "entertainment",
		difficulty = 2, minStats = { Looks = 50 }, grantsFlags = { "model", "photogenic" }, isFameCareer = true,
		description = "Starting your modeling career" },
	{ id = "catalog_model", name = "Catalog Model", company = "Retail Brands", emoji = "👗", salary = 15000, minAge = 16, requirement = nil, category = "entertainment",
		difficulty = 3, minStats = { Looks = 60 }, requiresFlags = { "model" }, grantsFlags = { "catalog_work", "commercial_model" }, isFameCareer = true,
		description = "Modeling for catalogs and ads" },
	{ id = "fashion_model", name = "Fashion Model", company = "Fashion Agency", emoji = "👠", salary = 75000, minAge = 17, requirement = nil, category = "entertainment",
		difficulty = 5, minStats = { Looks = 70 }, requiresFlags = { "catalog_work" }, grantsFlags = { "fashion_industry", "runway_ready" }, isFameCareer = true,
		description = "Walking fashion shows" },
	{ id = "top_model", name = "Top Model", company = "Elite Agency", emoji = "✨", salary = 500000, minAge = 18, requirement = nil, category = "entertainment",
		difficulty = 7, minStats = { Looks = 80 }, requiresFlags = { "runway_ready" }, grantsFlags = { "top_model", "magazine_covers" }, isFameCareer = true,
		description = "Top model status" },
	{ id = "supermodel", name = "Supermodel", company = "Global Fashion", emoji = "🌟", salary = 5000000, minAge = 20, requirement = nil, category = "entertainment",
		difficulty = 9, minStats = { Looks = 85 }, requiresFlags = { "top_model" }, grantsFlags = { "supermodel", "fashion_icon" }, isFameCareer = true,
		description = "International supermodel" },
	{ id = "modeling_legend", name = "Modeling Legend", company = "Hall of Fame", emoji = "👑", salary = 20000000, minAge = 28, requirement = nil, category = "entertainment",
		difficulty = 10, minStats = { Looks = 80 }, requiresFlags = { "supermodel" }, grantsFlags = { "modeling_legend", "beauty_icon" }, isFameCareer = true,
		description = "A legend of the fashion world" },
}

local JobCatalog = {}
for _, job in ipairs(JobCatalogList) do
	JobCatalog[job.id] = job
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #691: PromotionOnlyJobs must be defined BEFORE getJobEligibility
-- Was causing "attempt to index nil with 'content_creator'" error at line 6693
-- because it was defined AFTER the function that uses it
-- ═══════════════════════════════════════════════════════════════════════════════
local PromotionOnlyJobs = {
	["racing_legend"] = true, ["racing_team_owner"] = true,
	["star_athlete"] = true, ["sports_legend"] = true, ["team_owner"] = true,
	["movie_star"] = true, ["director"] = true, ["producer"] = true,
	["gaming_legend"] = true, ["esports_team_owner"] = true,
	["music_icon"] = true, ["record_label_owner"] = true,
	["cto"] = true, ["ceo"] = true, ["cfo"] = true, ["cmo"] = true, ["coo"] = true,
	["partner"] = true, ["senior_partner"] = true,
	["chief_of_surgery"] = true, ["hospital_director"] = true,
	["chief_pilot"] = true, ["airline_executive"] = true,
	["cia_director"] = true, ["fbi_director"] = true,
	["senator"] = true, ["governor"] = true, ["president"] = true,
}

function LifeBackend:findJobByInput(query)
	if not query or query == "" then
		return nil
	end
	query = tostring(query):lower()
	
	-- Direct lookup by ID first
	if JobCatalog[query] then
		return JobCatalog[query]
	end
	
	-- Check exact ID match (case insensitive)
	for _, job in pairs(JobCatalog) do
		if job.id and job.id:lower() == query then
			return job
		end
	end
	
	-- Check exact name match (case insensitive)
	for _, job in pairs(JobCatalog) do
		if job.name and job.name:lower() == query then
			return job
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #AAA-3: Handle common ID/name variations
	-- Maps client job IDs/names to server IDs for cases where they don't match exactly
	-- ═══════════════════════════════════════════════════════════════════════════════
	local jobAliases = {
		["new content creator"] = "new_influencer",
		["new_content_creator"] = "new_influencer",
		["content creator"] = "new_influencer",
		["hobbyist streamer"] = "hobbyist_streamer",
		["hobbyist_streamer"] = "hobbyist_streamer",
		["underground rapper"] = "underground_rapper",
		["new influencer"] = "new_influencer",
	}
	
	local aliasedId = jobAliases[query]
	if aliasedId and JobCatalog[aliasedId] then
		return JobCatalog[aliasedId]
	end
	
	-- Partial name match as fallback
	for _, job in pairs(JobCatalog) do
		if job.name and job.name:lower():find(query, 1, true) then
			return job
		end
	end
	
	return nil
end

-- ════════════════════════════════════════════════════════════════════════════════════════════════
-- CAREER TRACKS - Define full career paths from entry-level to top positions
-- Each track is an ordered list where promotions move you up the list
-- ════════════════════════════════════════════════════════════════════════════════════════════════
local CareerTracks = {
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #50: Added entry-level career track for generic first jobs
	-- This ensures players who get "entry_career" jobs can still progress properly
	-- The entry track leads into the office/business track
	-- ═══════════════════════════════════════════════════════════════════════════════
	entry = { "entry_career", "office_assistant", "administrative_assistant", "office_manager", "project_manager" },
	entry_service = { "retail_worker", "cashier", "shift_supervisor", "store_manager", "district_manager" },
	entry_food = { "fast_food_worker", "server", "shift_lead", "restaurant_manager" },
	
	-- Office/Business path
	office = { "receptionist", "office_assistant", "data_entry", "administrative_assistant", "office_manager", "project_manager", "operations_director", "coo" },
	hr = { "hr_coordinator", "recruiter", "hr_manager" },
	
	-- Technology path
	tech_dev = { "it_support", "junior_developer", "developer", "senior_developer", "tech_lead", "software_architect", "cto" },
	tech_web = { "web_developer", "developer", "senior_developer", "tech_lead" },
	tech_mobile = { "mobile_developer", "senior_developer", "tech_lead" },
	tech_data = { "data_analyst", "data_scientist", "ml_engineer" },
	tech_security = { "cybersecurity_analyst", "security_engineer", "ciso" },
	tech_devops = { "devops_engineer", "tech_lead", "cto" },
	
	-- Medical path
	medical_nursing = { "hospital_orderly", "medical_assistant", "nurse_lpn", "nurse_rn", "nurse_practitioner" },
	medical_doctor = { "doctor_resident", "doctor", "surgeon", "chief_of_medicine" },
	medical_other = { "emt", "physical_therapist", "pharmacist", "dentist", "veterinarian", "psychiatrist" },
	
	-- Legal path
	legal = { "legal_assistant", "paralegal", "associate_lawyer", "lawyer", "senior_partner" },
	legal_gov = { "public_defender", "prosecutor", "judge" },
	
	-- Finance path
	finance_banking = { "bank_teller", "loan_officer", "accountant_jr", "accountant", "cpa", "cfo" },
	finance_invest = { "financial_analyst", "investment_banker_jr", "investment_banker", "hedge_fund_manager" },
	
	-- Creative path
	creative_design = { "graphic_designer_jr", "graphic_designer", "art_director" },
	creative_media = { "journalist_jr", "journalist", "editor" },
	creative_marketing = { "social_media_manager", "marketing_associate", "marketing_manager", "cmo" },
	creative_acting = { "actor_extra", "actor", "movie_star" },
	creative_music = { "musician_local", "musician_signed", "pop_star" },
	
	-- Government path
	gov_police = { "police_officer", "detective", "police_chief" },
	gov_fire = { "firefighter", "fire_captain" },
	gov_politics = { "city_council", "mayor", "senator", "president" },
	gov_federal = { "fbi_agent", "cia_agent", "diplomat" },
	
	-- Education path
	education_school = { "teaching_assistant", "substitute_teacher", "teacher", "department_head", "principal", "superintendent" },
	education_university = { "professor_assistant", "professor", "dean" },
	
	-- Science path
	science = { "lab_technician", "research_assistant", "scientist", "senior_scientist", "research_director" },
	
	-- Sports path
	sports_player = { "minor_league", "professional_athlete", "star_athlete" },
	sports_coach = { "gym_instructor", "sports_coach", "head_coach" },
	
	-- Military path
	military_enlisted = { "enlisted", "sergeant" },
	military_officer = { "officer", "captain", "colonel", "general" },
	
	-- Criminal path
	criminal_street = { "illegal_dealer_street", "illegal_dealer", "enforcer", "crew_leader", "crime_boss" },
	criminal_crew = { "crew_member", "crew_leader", "crime_boss" },
	
	-- Hacker paths
	hacker_whitehat = { "script_kiddie", "freelance_hacker", "pen_tester", "security_consultant", "ciso" },
	hacker_blackhat = { "script_kiddie", "freelance_hacker", "black_hat_hacker", "elite_hacker", "cyber_crime_boss", "ransomware_kingpin" },
	
	-- Racing path
	racing = { "go_kart_racer", "amateur_racer", "professional_racer", "f1_driver", "racing_legend" },
	
	-- Esports path
	esports = { "casual_gamer", "content_creator", "pro_gamer", "esports_champion", "gaming_legend" },
	
	-- Trades path
	trades_electric = { "electrician_apprentice", "electrician" },
	trades_plumb = { "plumber_apprentice", "plumber" },
	trades_construct = { "construction", "foreman" },
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #AAA-10: ENTERTAINMENT/CELEBRITY CAREER TRACKS
	-- These were completely missing, causing celebrity careers to never auto-promote!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Rapper career path
	entertainment_rapper = { "underground_rapper", "local_rapper", "buzzing_rapper", "signed_rapper", "hot_rapper", "mainstream_rapper", "superstar_rapper", "legend_rapper" },
	
	-- Influencer/Content creator path  
	entertainment_influencer = { "new_creator", "new_influencer", "micro_influencer", "rising_influencer", "established_influencer", "major_influencer", "mega_influencer" },
	
	-- Streamer path
	entertainment_streamer = { "hobbyist_streamer", "new_streamer", "affiliate_streamer", "partner_streamer", "popular_streamer", "famous_streamer", "streaming_legend" },
	
	-- Musician path
	entertainment_musician = { "street_performer", "local_artist", "indie_artist", "signed_artist", "touring_artist", "famous_artist", "music_legend" },
	
	-- Actor path
	entertainment_actor = { "actor_extra", "actor", "tv_actor", "film_actor", "movie_star", "a_list_actor" },
}

-- Direct promotion mapping for quick lookups (job -> next job)
local PromotionMap = {}
for trackName, trackJobs in pairs(CareerTracks) do
	for i = 1, #trackJobs - 1 do
		PromotionMap[trackJobs[i]] = trackJobs[i + 1]
	end
end

-- Helper function to get the next promotion for any job
local function getNextPromotionJob(jobId)
	return PromotionMap[jobId]
end

-- ============================================================================
-- Activities, Crimes, Prison Actions, and Assets
-- ============================================================================

local ActivityCatalog = {
	read = { stats = { Smarts = 5, Happiness = 2 }, feed = "read a novel", cost = 0 },
	study = { stats = { Smarts = 6 }, feed = "studied hard", cost = 0 },
	meditate = { stats = { Happiness = 5, Health = 2 }, feed = "meditated", cost = 0 },
	gym = { stats = { Health = 6, Looks = 2 }, feed = "hit the gym", cost = 0, unlockFlag = "gym_rat" },
	run = { stats = { Health = 4, Happiness = 1 }, feed = "went on a run", cost = 0 },
	yoga = { stats = { Health = 3, Happiness = 3 }, feed = "did yoga", cost = 0 },
	spa = { stats = { Happiness = 6, Looks = 3 }, feed = "enjoyed a spa day", cost = 200 },
	salon = { stats = { Looks = 4, Happiness = 2 }, feed = "visited the salon", cost = 80 },
	-- CRITICAL FIX: Driver's license activity - sets all license flags
	drivers_license = { 
		stats = { Happiness = 5, Smarts = 2 }, 
		feed = "got your driver's license!", 
		cost = 50,
		setFlags = { has_license = true, drivers_license = true, driver_license = true },
		oneTime = true, -- Can only do this once
		requiresAge = 16,
		blockedByFlag = "has_license", -- Can't get a license if you already have one
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- EDUCATION ACTIVITIES (Like BitLife!) - Go back to school, get GED, etc.
	-- ═══════════════════════════════════════════════════════════════════════════
	get_ged = {
		stats = { Smarts = 10, Happiness = 8 },
		feed = "got your GED! High school equivalent achieved!",
		cost = 150,
		requiresAge = 16,
		requiresFlag = "dropped_out_high_school",
		blockedByFlag = "has_ged",
		setFlags = { has_ged = true, has_ged_or_diploma = true },
		oneTime = true,
	},
	return_high_school = {
		stats = { Smarts = 5, Happiness = 3 },
		feed = "returned to high school to finish your education!",
		cost = 0,
		requiresAge = 14,
		maxAge = 21,
		requiresFlag = "dropped_out_high_school",
		blockedByFlag = "has_diploma",
		setFlags = { returning_student = true, in_school = true, dropped_out_high_school = nil },
		oneTime = true,
	},
	community_college = {
		stats = { Smarts = 8, Happiness = 5 },
		feed = "enrolled in community college!",
		cost = 2000,
		requiresAge = 18,
		requiresFlag = "has_ged_or_diploma",
		blockedByFlag = "in_college",
		setFlags = { in_college = true, community_college = true },
		educationProgram = "community",
		skipCompletionTracking = true,
		oneTime = true,
	},
	university = {
		stats = { Smarts = 10, Happiness = 6 },
		feed = "enrolled in university! 4-year degree program!",
		cost = 5000,
		requiresAge = 18,
		requiresFlag = "has_ged_or_diploma",
		blockedByFlag = "in_university",
		setFlags = { in_university = true, in_college = true },
		educationProgram = "bachelor",
		skipCompletionTracking = true,
		oneTime = true,
	},
	trade_school = {
		stats = { Smarts = 6, Happiness = 5 },
		feed = "enrolled in trade school! Learning practical skills!",
		cost = 3000,
		requiresAge = 18,
		setFlags = { in_trade_school = true, learning_trade = true },
		educationProgram = "trade",
		skipCompletionTracking = true,
		oneTime = true,
	},
	coding_bootcamp = {
		stats = { Smarts = 12, Happiness = 4 },
		feed = "enrolled in a coding bootcamp! Tech skills incoming!",
		cost = 8000,
		requiresAge = 18,
		setFlags = { coding_bootcamp = true, tech_skills = true },
		educationProgram = "bootcamp",
		skipCompletionTracking = true,
		oneTime = true,
	},
	medical_school = {
		stats = { Smarts = 15, Happiness = 3, Health = -5 },
		feed = "enrolled in medical school! Becoming a doctor!",
		cost = 50000,
		requiresAge = 22,
		requiresFlag = "has_degree",
		blockedByFlag = "in_med_school",
		setFlags = { in_med_school = true },
		educationProgram = "medical",
		skipCompletionTracking = true,
		oneTime = true,
	},
	law_school = {
		stats = { Smarts = 14, Happiness = 2 },
		feed = "enrolled in law school! Becoming a lawyer!",
		cost = 40000,
		requiresAge = 22,
		requiresFlag = "has_degree",
		blockedByFlag = "in_law_school",
		setFlags = { in_law_school = true },
		educationProgram = "law",
		skipCompletionTracking = true,
		oneTime = true,
	},
	business_school = {
		stats = { Smarts = 12, Happiness = 4, Money = -500 },
		feed = "enrolled in business school! Getting your MBA!",
		cost = 35000,
		requiresAge = 22,
		requiresFlag = "has_degree",
		blockedByFlag = "in_business_school",
		setFlags = { in_business_school = true },
		educationProgram = "business",
		skipCompletionTracking = true,
		oneTime = true,
	},
	
	party = { stats = { Happiness = 5 }, feed = "partied with friends", cost = 0 },
	hangout = { stats = { Happiness = 3 }, feed = "hung out with friends", cost = 0 },
	nightclub = { stats = { Happiness = 6, Health = -2 }, feed = "went clubbing", cost = 50 },
	host_party = { stats = { Happiness = 8 }, feed = "hosted a party", cost = 300 },
	tv = { stats = { Happiness = 2 }, feed = "binged a show", cost = 0 },
	games = { stats = { Happiness = 3, Smarts = 1 }, feed = "played video games", cost = 0 },
	movies = { stats = { Happiness = 3 }, feed = "watched a movie", cost = 20 },
	concert = { stats = { Happiness = 5 }, feed = "went to a concert", cost = 150 },
	vacation = { stats = { Happiness = 10, Health = 4 }, feed = "took a vacation", cost = 2000 },
	-- CRITICAL FIX: Missing activities from client (caused "Unknown activity" error)
	martial_arts = { stats = { Health = 5, Looks = 2 }, feed = "practiced martial arts", cost = 100 },
	karaoke = { stats = { Happiness = 4 }, feed = "sang karaoke", cost = 20 },
	arcade = { stats = { Happiness = 4, Smarts = 1 }, feed = "played games at the arcade", cost = 30 },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #355: Career Skill-Building Activities
	-- These grant experience flags needed for career progression!
	-- ═══════════════════════════════════════════════════════════════════════════
	
	-- Racing experience (for racing career)
	go_kart_racing = {
		stats = { Health = 4, Happiness = 6 },
		feed = "went go-kart racing and practiced your driving skills!",
		cost = 50,
		requiresAge = 8,
		setFlags = { karting_experience = true, racing_experience = true },
	},
	race_track_visit = {
		stats = { Happiness = 5 },
		feed = "visited the race track and learned about racing!",
		cost = 30,
		requiresAge = 6,
		setFlags = { racing_experience = true },
	},
	
	-- Sports experience (for athletic careers)
	join_school_sports = {
		stats = { Health = 5, Happiness = 4 },
		feed = "joined the school sports team!",
		cost = 50,
		requiresAge = 10,
		maxAge = 18,
		setFlags = { athlete = true, sports_team = true, school_sports = true },
	},
	sports_camp = {
		stats = { Health = 8, Happiness = 5 },
		feed = "attended sports camp and improved your athletic skills!",
		cost = 500,
		requiresAge = 8,
		maxAge = 17,
		setFlags = { athlete = true, sports_team = true },
	},
	varsity_tryouts = {
		stats = { Health = 4, Happiness = 3 },
		feed = "made the varsity team!",
		cost = 0,
		requiresAge = 14,
		maxAge = 18,
		requiresFlag = "school_sports",
		setFlags = { varsity_athlete = true, athlete = true },
	},
	
	-- Coding/Tech experience (for tech careers)
	computer_club = {
		stats = { Smarts = 5, Happiness = 3 },
		feed = "joined the computer club and learned programming!",
		cost = 0,
		requiresAge = 10,
		setFlags = { coder = true, computer_skills = true, tech_experience = true },
	},
	learn_coding = {
		stats = { Smarts = 8, Happiness = 2 },
		feed = "learned to code through online tutorials!",
		cost = 0,
		requiresAge = 10,
		setFlags = { coder = true, computer_skills = true },
	},
	build_computer = {
		stats = { Smarts = 6, Happiness = 4 },
		feed = "built your own computer!",
		cost = 800,
		requiresAge = 12,
		setFlags = { tech_experience = true, computer_skills = true },
	},
	
	-- Music experience (for music careers)
	music_lessons = {
		stats = { Happiness = 4, Smarts = 2 },
		feed = "took music lessons and practiced an instrument!",
		cost = 100,
		requiresAge = 6,
		setFlags = { musician = true, plays_instrument = true, music_lessons = true },
	},
	join_band = {
		stats = { Happiness = 6 },
		feed = "joined a band!",
		cost = 0,
		requiresAge = 12,
		requiresFlag = "plays_instrument",
		setFlags = { in_a_band = true, musician = true },
	},
	play_open_mic = {
		stats = { Happiness = 5 },
		feed = "performed at an open mic night!",
		cost = 0,
		requiresAge = 14,
		requiresFlag = "musician",
		setFlags = { local_musician = true, music_experience = true },
	},
	
	-- Acting experience (for acting careers)
	drama_club = {
		stats = { Happiness = 4, Smarts = 1 },
		feed = "joined the drama club and performed in a play!",
		cost = 0,
		requiresAge = 10,
		setFlags = { drama_club = true, acting_experience = true, theater_experience = true },
	},
	acting_classes = {
		stats = { Happiness = 3, Looks = 1 },
		feed = "took acting classes!",
		cost = 200,
		requiresAge = 8,
		setFlags = { acting_experience = true },
	},
	community_theater = {
		stats = { Happiness = 5 },
		feed = "performed in community theater!",
		cost = 0,
		requiresAge = 12,
		requiresFlag = "acting_experience",
		setFlags = { theater_experience = true, professional_actor = false },
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- BABY/TODDLER PLAY ACTIVITIES (Ages 0-5)
	-- ═══════════════════════════════════════════════════════════════════════════
	play_toys = { stats = { Happiness = 4 }, feed = "played with toys", cost = 0 },
	watch_cartoons = { stats = { Happiness = 3 }, feed = "watched cartoons", cost = 0 },
	play_peekaboo = { stats = { Happiness = 5 }, feed = "played peekaboo", cost = 0 },
	play_blocks = { stats = { Happiness = 3, Smarts = 2 }, feed = "played with blocks", cost = 0 },
	playground = { stats = { Happiness = 5, Health = 2 }, feed = "went to the playground", cost = 0 },
	coloring = { stats = { Happiness = 3 }, feed = "colored a picture", cost = 0 },
	play_dolls = { stats = { Happiness = 3 }, feed = "played with dolls", cost = 0 },
	bubbles = { stats = { Happiness = 4 }, feed = "blew bubbles", cost = 0 },
	nap_time = { stats = { Health = 4, Happiness = 2 }, feed = "took a nap", cost = 0 },
	play_outside = { stats = { Happiness = 4, Health = 3 }, feed = "played outside", cost = 0 },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- BABY MISCHIEF (Ages 0-4) - CRITICAL FIX: Added to server catalog
	-- ═══════════════════════════════════════════════════════════════════════════
	cry_loudly = { stats = { Happiness = 2 }, feed = "cried really loud for attention", cost = 0 },
	throw_food = { stats = { Happiness = 3 }, feed = "threw food everywhere", cost = 0 },
	break_toy = { stats = { Happiness = -1 }, feed = "broke a toy", cost = 0 },
	draw_walls = { stats = { Happiness = 4 }, feed = "drew on the walls", cost = 0 },
	refuse_nap = { stats = { Happiness = 3, Health = -1 }, feed = "refused to take a nap", cost = 0 },
	tantrum = { stats = { Happiness = -2 }, feed = "threw a tantrum", cost = 0 },
	bite_sibling = { stats = { Happiness = 1 }, feed = "bit someone", cost = 0 },
	hide_mom_keys = { stats = { Happiness = 4 }, feed = "hid mom's keys", cost = 0 },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- CHILD MISCHIEF (Ages 5-12) - CRITICAL FIX: Added to server catalog
	-- ═══════════════════════════════════════════════════════════════════════════
	skip_chores = { stats = { Happiness = 4, Smarts = -1 }, feed = "skipped chores", cost = 0 },
	prank_sibling = { stats = { Happiness = 5 }, feed = "pranked a sibling", cost = 0 },
	sneak_candy = { stats = { Happiness = 4, Health = -1 }, feed = "sneaked candy", cost = 0 },
	stay_up_late = { stats = { Happiness = 3, Health = -2 }, feed = "stayed up past bedtime", cost = 0 },
	cheat_test = { stats = { Happiness = -2 }, feed = "cheated on a test", cost = 0, setFlag = "cheater" },
	talk_back = { stats = { Happiness = 1 }, feed = "talked back to parents", cost = 0 },
	blame_sibling = { stats = { Happiness = 2 }, feed = "blamed a sibling", cost = 0 },
	fake_sick = { stats = { Happiness = 4 }, feed = "faked being sick", cost = 0 },
	toilet_paper_house = { stats = { Happiness = 5 }, feed = "toilet papered a house", cost = 0 },
	ring_doorbell_run = { stats = { Happiness = 4, Health = 1 }, feed = "played ding dong ditch", cost = 0 },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- TEEN MISCHIEF (Ages 13-17) - CRITICAL FIX: Added to server catalog
	-- Activities have risk of getting caught with consequences
	-- ═══════════════════════════════════════════════════════════════════════════
	sneak_out = { stats = { Happiness = 6 }, feed = "snuck out at night", cost = 0, setFlag = "rebellious", 
		risk = 25, riskConsequence = "your parents caught you coming back! Grounded!", riskFlag = "grounded" },
	skip_class = { stats = { Happiness = 4, Smarts = -2 }, feed = "skipped class", cost = 0,
		risk = 30, riskConsequence = "the school called your parents!", riskFlag = "truant" },
	party_crash = { stats = { Happiness = 5 }, feed = "crashed a party", cost = 0,
		risk = 20, riskConsequence = "you got kicked out!" },
	fake_id = { stats = { Happiness = 2 }, feed = "got a fake ID", cost = 0, setFlag = "has_fake_id",
		risk = 15, riskConsequence = "the bouncer confiscated it!" },
	vandalize = { stats = { Happiness = 2 }, feed = "vandalized something", cost = 0, setFlag = "vandal",
		risk = 35, riskConsequence = "someone saw you and called the cops!", riskFlag = "criminal_record" },
	bully = { stats = { Happiness = -3 }, feed = "bullied someone", cost = 0, setFlag = "bully",
		risk = 40, riskConsequence = "a teacher witnessed it! You're in big trouble." },
	steal_parents_car = { stats = { Happiness = 6, Health = -2 }, feed = "took parents' car for a joyride", cost = 0,
		risk = 30, riskConsequence = "you crashed it! Your parents are furious.", riskFlag = "in_trouble" },
	break_curfew = { stats = { Happiness = 4 }, feed = "broke curfew", cost = 0,
		risk = 20, riskConsequence = "your parents were waiting up for you!" },
	drink_underage = { stats = { Happiness = 3, Health = -3 }, feed = "drank alcohol underage", cost = 0,
		risk = 25, riskConsequence = "you got sick and your parents found out!" },
	smoke = { stats = { Happiness = 1, Health = -4 }, feed = "tried smoking", cost = 0, setFlag = "smoker",
		risk = 20, riskConsequence = "your parents smelled it on your clothes!" },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: ROYAL DUTIES (Was causing "Unknown Activity" errors)
	-- These activities are called from the Royalty tab in ActivitiesScreen
	-- ═══════════════════════════════════════════════════════════════════════════
	public_appearance = { 
		stats = { Happiness = 5 }, 
		feed = "made a public appearance and waved to the crowds", 
		cost = 0,
		requiresFlag = "is_royalty",
		royaltyEffect = { popularity = 5 },
	},
	charity_visit = { 
		stats = { Happiness = 8, Health = 2 }, 
		feed = "visited a charity and met with beneficiaries", 
		cost = 10000,
		requiresFlag = "is_royalty",
		royaltyEffect = { popularity = 8 },
	},
	state_dinner = { 
		stats = { Happiness = 3, Smarts = 2 }, 
		feed = "hosted a state dinner with foreign dignitaries", 
		cost = 50000,
		requiresFlag = "is_royalty",
		requiresAge = 18,
		royaltyEffect = { popularity = 10 },
	},
	open_parliament = { 
		stats = { Happiness = 2, Smarts = 3 }, 
		feed = "opened Parliament with the traditional ceremony", 
		cost = 0,
		requiresFlag = "is_monarch",
		requiresAge = 21,
		royaltyEffect = { popularity = 12 },
	},
	knight_ceremony = { 
		stats = { Happiness = 10 }, 
		feed = "knighted a deserving citizen", 
		cost = 0,
		requiresFlag = "is_monarch",
		requiresAge = 21,
		royaltyEffect = { popularity = 8 },
	},
	ribbon_cutting = { 
		stats = { Happiness = 4 }, 
		feed = "cut the ribbon at a new building opening", 
		cost = 5000,
		requiresFlag = "is_royalty",
		royaltyEffect = { popularity = 4 },
	},
	royal_tour = { 
		stats = { Happiness = 6, Health = -3 }, 
		feed = "went on a royal tour of the Commonwealth", 
		cost = 100000,
		requiresFlag = "is_royalty",
		requiresAge = 18,
		royaltyEffect = { popularity = 15 },
	},
	royal_wedding = { 
		stats = { Happiness = 15 }, 
		feed = "attended a glamorous royal wedding", 
		cost = 0,
		requiresFlag = "is_royalty",
		royaltyEffect = { popularity = 10 },
	},
	military_review = { 
		stats = { Happiness = 3 }, 
		feed = "reviewed the royal military forces", 
		cost = 0,
		requiresFlag = "is_royalty",
		requiresAge = 16,
		royaltyEffect = { popularity = 6 },
	},
	charity_gala = { 
		stats = { Happiness = 8 }, 
		feed = "hosted a magnificent charity gala", 
		cost = 100000,
		requiresFlag = "is_royalty",
		requiresAge = 18,
		royaltyEffect = { popularity = 10 },
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: MAFIA OPERATIONS (Was causing "Unknown Activity" errors)
	-- These activities are called from the Mafia tab in ActivitiesScreen
	-- ═══════════════════════════════════════════════════════════════════════════
	collect_protection = { 
		stats = { Happiness = 2 }, 
		feed = "collected protection money from local businesses", 
		cost = 0,
		requiresFlag = "in_mob",
		requiresAge = 18,
		mafiaEffect = { respect = 5, heat = 10, money = { 2000, 8000 } },
	},
	contraband_run = { 
		stats = { Happiness = 3, Health = -2 }, 
		feed = "made a contraband delivery run", 
		cost = 0,
		requiresFlag = "in_mob",
		requiresAge = 18,
		mafiaEffect = { respect = 8, heat = 20, money = { 5000, 15000 } },
		risk = 35,
	},
	hit_job = { 
		stats = { Happiness = -5 }, 
		feed = "carried out a hit job for the family", 
		cost = 0,
		requiresFlag = "in_mob",
		requiresAge = 18,
		mafiaEffect = { respect = 20, heat = 40, money = { 15000, 50000 } },
		risk = 50,
		setFlag = "killer",
	},
	heist = { 
		stats = { Happiness = 5 }, 
		feed = "participated in a heist", 
		cost = 0,
		requiresFlag = "in_mob",
		requiresAge = 18,
		mafiaEffect = { respect = 25, heat = 50, money = { 50000, 200000 } },
		risk = 60,
		hasMinigame = true,
		minigameType = "heist",
	},
	intimidate = { 
		stats = { Happiness = 1 }, 
		feed = "intimidated someone for the family", 
		cost = 0,
		requiresFlag = "in_mob",
		requiresAge = 18,
		mafiaEffect = { respect = 10, heat = 15, money = { 1000, 5000 } },
		risk = 25,
	},
	bribe_official = { 
		stats = { Smarts = 2 }, 
		feed = "bribed a government official", 
		cost = 25000,
		requiresFlag = "in_mob",
		requiresAge = 21,
		mafiaEffect = { respect = 15, heat = -10 },
	},
	launder_money = { 
		stats = { Smarts = 3 }, 
		feed = "laundered money through legitimate businesses", 
		cost = 10000,
		requiresFlag = "in_mob",
		requiresAge = 21,
		mafiaEffect = { respect = 10, heat = -5, money = { 20000, 50000 } },
	},
	-- CRITICAL FIX #303: Added remaining mafia operations from ActivitiesScreen
	recruit = { 
		stats = { Happiness = 3 }, 
		feed = "recruited new members for the family", 
		cost = 0,
		requiresFlag = "in_mob",
		requiresAge = 18,
		mafiaEffect = { respect = 8, heat = 5 },
	},
	bribe_cops = { 
		stats = { Happiness = 2 }, 
		feed = "bribed local police to look the other way", 
		cost = 50000,
		requiresFlag = "in_mob",
		requiresAge = 18,
		mafiaEffect = { respect = 5, heat = -20 },
	},
	lay_low = { 
		stats = { Happiness = -2, Health = 2 }, 
		feed = "laid low and stayed out of sight", 
		cost = 0,
		requiresFlag = "in_mob",
		requiresAge = 18,
		mafiaEffect = { heat = -15 },
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: FAME/CELEBRITY ACTIVITIES
	-- These activities are called from the Fame tab in ActivitiesScreen
	-- User bug: "EVERY SINGLE ACTION INSIDE FAME SAYS UNKNOWN ACTIVITY"
	-- ═══════════════════════════════════════════════════════════════════════════
	audition = {
		stats = { Happiness = 3 },
		feed = "went to an audition! Fingers crossed!",
		cost = 0,
		requiresAge = 16,
		fameEffect = { fame = 2, breakthrough_chance = 0.15 },
	},
	social_post = {
		stats = { Happiness = 2 },
		feed = "posted on social media to connect with fans!",
		cost = 0,
		requiresAge = 13,
		fameEffect = { followers = 100, fame = 1 },
	},
	interview = {
		stats = { Happiness = 4, Smarts = 1 },
		feed = "did a media interview!",
		cost = 0,
		requiresAge = 14,
		fameEffect = { fame = 3 },
	},
	photoshoot = {
		stats = { Looks = 3, Happiness = 4 },
		feed = "did a professional photoshoot!",
		cost = 500,
		requiresAge = 16,
		fameEffect = { fame = 4, followers = 500 },
	},
	endorsement = {
		stats = { Happiness = 5 },
		feed = "sought out endorsement deals!",
		cost = 0,
		requiresAge = 18,
		fameEffect = { fame = 2 },
	},
	publicity_stunt = {
		stats = { Happiness = 6 },
		feed = "pulled a publicity stunt to get attention!",
		cost = 5000,
		requiresAge = 18,
		fameEffect = { fame = 8, scandal = 0.2 },
	},
	charity_event = {
		stats = { Happiness = 10, Health = 2 },
		feed = "hosted a charity event!",
		cost = 10000,
		requiresAge = 16,
		fameEffect = { fame = 5, followers = 1000 },
	},
	album_tour = {
		stats = { Happiness = 8, Health = -8 },
		feed = "went on tour! Exhausting but exciting!",
		cost = 50000,
		requiresAge = 18,
		fameEffect = { fame = 10, followers = 5000 },
	},
	-- Additional fame activities
	record_track = {
		stats = { Happiness = 5 },
		feed = "recorded a new track in the studio!",
		cost = 2000,
		requiresAge = 14,
		fameEffect = { fame = 3, followers = 200 },
	},
	release_album = {
		stats = { Happiness = 10 },
		feed = "released a new album!",
		cost = 10000,
		requiresAge = 18,
		fameEffect = { fame = 8, followers = 2000 },
	},
	music_video = {
		stats = { Happiness = 6, Looks = 2 },
		feed = "filmed a music video!",
		cost = 15000,
		requiresAge = 16,
		fameEffect = { fame = 5, followers = 1500 },
	},
	meet_fans = {
		stats = { Happiness = 8 },
		feed = "met with fans at a signing event!",
		cost = 0,
		requiresAge = 14,
		fameEffect = { fame = 2, followers = 500 },
	},
	award_show = {
		stats = { Happiness = 7, Looks = 3 },
		feed = "attended an award show!",
		cost = 5000,
		requiresAge = 18,
		fameEffect = { fame = 4 },
	},
	collab = {
		stats = { Happiness = 6 },
		feed = "collaborated with another artist!",
		cost = 3000,
		requiresAge = 16,
		fameEffect = { fame = 5, followers = 1000 },
	},
	live_stream = {
		stats = { Happiness = 4 },
		feed = "did a live stream for fans!",
		cost = 0,
		requiresAge = 13,
		fameEffect = { fame = 2, followers = 300 },
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #7: RETIREMENT ACTIVITIES
	-- Players should be able to retire from their jobs and receive pension
	-- ═══════════════════════════════════════════════════════════════════════════
	retire = {
		stats = { Happiness = 10, Health = 5 },
		feed = "retired from your career! Time to enjoy life!",
		cost = 0,
		requiresAge = 50, -- Can retire early (with reduced pension)
		requiresFlag = "employed", -- Must have a job to retire from
		setFlags = { retired = true, happily_retired = true },
		clearFlags = { employed = true, has_job = true, has_teen_job = true },
		oneTime = false, -- Can un-retire and re-retire
		isRetirement = true, -- Special handler flag
	},
	early_retire = {
		stats = { Happiness = 12, Health = 8 },
		feed = "took early retirement! Living the dream!",
		cost = 0,
		requiresAge = 40, -- Minimum 40 for early retirement
		maxAge = 49, -- After 50, use normal retire
		requiresFlag = "employed",
		setFlags = { retired = true, happily_retired = true, early_retirement = true },
		clearFlags = { employed = true, has_job = true, has_teen_job = true },
		oneTime = false,
		isRetirement = true,
	},
	work_part_time = {
		stats = { Happiness = 3 },
		feed = "went semi-retired, working part-time!",
		cost = 0,
		requiresAge = 55,
		requiresFlag = "employed",
		setFlags = { semi_retired = true },
		oneTime = false,
		isSemiRetirement = true,
	},
	
	-- Rehab activities for addiction recovery
	go_to_rehab = {
		stats = { Health = 10, Happiness = -5 },
		feed = "checked into rehab to get clean!",
		cost = 5000,
		requiresAge = 14,
		setFlags = { in_rehab = true, seeking_help = true },
	},
	attend_aa = {
		stats = { Health = 5, Happiness = 2 },
		feed = "attended an AA meeting!",
		cost = 0,
		requiresAge = 14,
		setFlags = { attending_aa = true, seeking_help = true },
	},
	complete_rehab = {
		stats = { Health = 15, Happiness = 10 },
		feed = "completed your rehab program! A fresh start!",
		cost = 0,
		requiresAge = 14,
		requiresFlag = "in_rehab",
		setFlags = { completed_rehab = true },
		clearFlags = { in_rehab = true },
		oneTime = false,
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #30: HEALTH & MEDICAL ACTIVITIES
	-- Players need ways to heal and take care of their health
	-- Insurance reduces costs for these activities
	-- ═══════════════════════════════════════════════════════════════════════════
	doctor_visit = {
		stats = { Health = 8, Happiness = 2 },
		feed = "went to the doctor for a checkup!",
		cost = 500, -- Base cost, reduced by insurance
		requiresAge = 0,
		usesInsurance = true, -- Insurance reduces cost
	},
	hospital_treatment = {
		stats = { Health = 25, Happiness = -5 },
		feed = "received treatment at the hospital!",
		cost = 5000, -- Base cost, reduced by insurance
		requiresAge = 0,
		usesInsurance = true,
	},
	therapy_session = {
		stats = { Happiness = 10, Health = 3 },
		feed = "had a therapy session - mental health matters!",
		cost = 200, -- Base cost, reduced by insurance
		requiresAge = 10,
		usesInsurance = true,
	},
	dental_checkup = {
		stats = { Health = 3, Looks = 2 },
		feed = "got your teeth cleaned!",
		cost = 200,
		requiresAge = 3,
		usesInsurance = true,
	},
	get_surgery = {
		stats = { Health = 40, Happiness = -10 },
		feed = "underwent surgery and are recovering!",
		cost = 20000, -- Very expensive without insurance
		requiresAge = 0,
		usesInsurance = true,
	},
	buy_health_insurance = {
		stats = { Happiness = 2 },
		feed = "purchased health insurance coverage!",
		cost = 3000, -- Annual premium
		requiresAge = 18,
		setFlags = { has_health_insurance = true },
		clearFlags = { uninsured = true },
	},
	chiropractor = {
		stats = { Health = 5, Happiness = 3 },
		feed = "visited the chiropractor!",
		cost = 100,
		requiresAge = 16,
		usesInsurance = true,
	},
	physical_therapy = {
		stats = { Health = 10, Happiness = 1 },
		feed = "attended physical therapy!",
		cost = 300,
		requiresAge = 5,
		usesInsurance = true,
	},
}

local CrimeCatalog = {
	-- PETTY CRIMES (low risk)
	porch_pirate = { risk = 20, reward = { 30, 200 }, jail = { min = 0.2, max = 1 } },
	shoplift = { risk = 25, reward = { 20, 150 }, jail = { min = 0.5, max = 2 } },
	pickpocket = { risk = 35, reward = { 30, 300 }, jail = { min = 0.5, max = 2 }, hasMinigame = true, minigameType = "qte" },
	-- PROPERTY CRIMES (medium risk)
	burglary = { risk = 50, reward = { 500, 5000 }, jail = { min = 2, max = 5 }, hasMinigame = true, minigameType = "heist" },
	gta = { risk = 60, reward = { 2000, 20000 }, jail = { min = 3, max = 7 }, hasMinigame = true, minigameType = "getaway" },
	-- MAJOR CRIMES (high risk)
	bank_robbery = { risk = 80, reward = { 10000, 500000 }, jail = { min = 5, max = 12 }, hasMinigame = true, minigameType = "heist" },
	-- EXPANDED CRIMES (CRITICAL FIX: Added more variety)
	tax_fraud = { risk = 35, reward = { 5000, 50000 }, jail = { min = 1, max = 5 } },
	identity_theft = { risk = 40, reward = { 1000, 20000 }, jail = { min = 2, max = 6 } },
	smuggling = { risk = 55, reward = { 500, 10000 }, jail = { min = 3, max = 10 } },
	car_theft = { risk = 50, reward = { 3000, 15000 }, jail = { min = 2, max = 5 } },
	arson = { risk = 70, reward = { 0, 1000 }, jail = { min = 5, max = 15 } },
	intimidation = { risk = 60, reward = { 2000, 30000 }, jail = { min = 3, max = 8 } },
	ransom = { risk = 85, reward = { 10000, 200000 }, jail = { min = 10, max = 25 } },
	assault = { risk = 90, reward = { 0, 5000 }, jail = { min = 20, max = 100 } },
	-- CRITICAL FIX: Added missing crimes from ActivitiesScreen (was causing "Unknown Crime" errors)
	illegal_dealing = { risk = 55, reward = { 500, 10000 }, jail = { min = 3, max = 10 } }, -- Renamed from drug_dealing
	extortion = { risk = 60, reward = { 2000, 30000 }, jail = { min = 3, max = 8 } },
	kidnapping = { risk = 85, reward = { 10000, 200000 }, jail = { min = 10, max = 25 } },
	murder = { risk = 95, reward = { 0, 5000 }, jail = { min = 25, max = 100 } },
	hacking = { risk = 45, reward = { 5000, 50000 }, jail = { min = 2, max = 8 }, hasMinigame = true, minigameType = "hacking" },
	counterfeiting = { risk = 50, reward = { 3000, 25000 }, jail = { min = 2, max = 7 } },
	fraud = { risk = 40, reward = { 2000, 20000 }, jail = { min = 1, max = 5 } },
	embezzlement = { risk = 45, reward = { 10000, 100000 }, jail = { min = 3, max = 10 } },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #8: PRISON CRIMES - Can be committed while incarcerated
	-- Getting caught adds years to sentence instead of starting new sentence
	-- ═══════════════════════════════════════════════════════════════════════════
	prison_assault = { risk = 60, reward = { 0, 200 }, jail = { min = 1, max = 3 }, isPrisonCrime = true },
	prison_riot = { risk = 80, reward = { 0, 0 }, jail = { min = 2, max = 5 }, isPrisonCrime = true },
	prison_contraband = { risk = 50, reward = { 100, 1000 }, jail = { min = 1, max = 2 }, isPrisonCrime = true },
	prison_gang_violence = { risk = 70, reward = { 0, 500 }, jail = { min = 2, max = 4 }, isPrisonCrime = true },
}

local PrisonActions = {
	prison_escape = { description = "Attempt a daring escape", successStat = "Freedom" },
	-- CRITICAL FIX: Added prison_escape_failed handler (called by ActivitiesScreen minigame failure)
	prison_escape_failed = { 
		stats = { Health = -5, Happiness = -10 }, 
		feed = "got caught trying to escape", 
		jailIncrease = 2, -- Add 2 years to sentence for failed escape attempt
	},
	prison_workout = { stats = { Health = 4, Looks = 1 }, feed = "worked out in the yard" },
	prison_study = { stats = { Smarts = 4 }, feed = "studied for a GED" },
	prison_crew = { stats = { Happiness = 2, Health = -3 }, feed = "aligned with a crew", flag = "crew_member" },
	prison_riot = { stats = { Health = -10 }, feed = "started a riot", risk = 70 },
	prison_snitch = { stats = { Health = -5 }, feed = "snitched on someone", risk = 50 },
	prison_appeal = { moneyCost = 5000, feed = "filed an appeal", jailReduction = 1 },
	prison_goodbehavior = { jailReduction = 0.5, feed = "kept a low profile" },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #MEGA-1: COMPREHENSIVE ASSET CATALOGS WITH FULL GAMEPLAY EFFECTS
-- Every asset now has: happiness bonus, status/fame effect, maintenance cost, 
-- unlocked flags, eligibility effects, resale value modifier, and more!
-- ═══════════════════════════════════════════════════════════════════════════════

local Properties = {
	{ 
		id = "studio", 
		name = "Studio Apartment", 
		emoji = "🏢",
		price = 85000, 
		income = 500,
		tier = "starter",
		happinessBonus = 2,      -- Annual happiness boost
		statusBonus = 0,          -- Fame/status points
		maintenanceCost = 1200,   -- Annual maintenance
		resaleModifier = 0.85,    -- Sells for 85% of value
		minAge = 18,
		description = "A cozy starter home in the city",
		grantsFlags = { "homeowner", "has_apartment", "independent" },
		effects = { Happiness = 3 },
	},
	{ 
		id = "1br_condo", 
		name = "1BR Condo", 
		emoji = "🏬",
		price = 175000, 
		income = 1000,
		tier = "nice",
		happinessBonus = 4,
		statusBonus = 1,
		maintenanceCost = 2500,
		resaleModifier = 0.88,
		minAge = 18,
		description = "Modern condo with great amenities",
		grantsFlags = { "homeowner", "condo_owner", "nice_place" },
		effects = { Happiness = 5 },
	},
	{ 
		id = "family_house", 
		name = "Family House", 
		emoji = "🏠",
		price = 350000, 
		income = 2000,
		tier = "comfortable",
		happinessBonus = 6,
		statusBonus = 2,
		maintenanceCost = 5000,
		resaleModifier = 0.90,
		minAge = 18,
		description = "3 bed, 2 bath suburban home",
		grantsFlags = { "homeowner", "house_owner", "suburban_life", "family_home" },
		effects = { Happiness = 8, Health = 2 },
		familyBonus = true,  -- Extra happiness if has family
	},
	{ 
		id = "beach_house", 
		name = "Beach House", 
		emoji = "🏖️",
		price = 1200000, 
		income = 5000,
		tier = "luxury",
		happinessBonus = 10,
		statusBonus = 5,
		maintenanceCost = 15000,
		resaleModifier = 0.92,
		minAge = 21,
		description = "Stunning oceanfront property",
		grantsFlags = { "homeowner", "beach_property", "luxury_lifestyle", "vacation_home" },
		effects = { Happiness = 12, Health = 5 },
		fameBonus = 2,
	},
	{ 
		id = "penthouse", 
		name = "Luxury Penthouse", 
		emoji = "🌆",
		price = 2500000, 
		income = 10000,
		tier = "elite",
		happinessBonus = 15,
		statusBonus = 10,
		maintenanceCost = 30000,
		resaleModifier = 0.93,
		minAge = 21,
		description = "Top floor luxury with city views",
		grantsFlags = { "homeowner", "penthouse_owner", "elite_lifestyle", "high_society" },
		effects = { Happiness = 15, Looks = 3 },
		fameBonus = 5,
	},
	{ 
		id = "mansion", 
		name = "Mansion", 
		emoji = "🏰",
		price = 8500000, 
		income = 25000,
		tier = "ultra",
		happinessBonus = 25,
		statusBonus = 20,
		maintenanceCost = 100000,
		resaleModifier = 0.95,
		minAge = 21,
		description = "Grand estate with pool, tennis court, and staff quarters",
		grantsFlags = { "homeowner", "mansion_owner", "ultra_wealthy", "celebrity_lifestyle", "has_staff" },
		effects = { Happiness = 25, Looks = 5, Health = 3 },
		fameBonus = 10,
		canHostParties = true,
	},
	-- NEW PROPERTIES FOR MORE VARIETY
	{ 
		id = "mobile_home", 
		name = "Mobile Home", 
		emoji = "🚐",
		price = 25000, 
		income = 100,
		tier = "budget",
		happinessBonus = 1,
		statusBonus = -1,
		maintenanceCost = 500,
		resaleModifier = 0.60,
		minAge = 18,
		description = "Affordable mobile living",
		grantsFlags = { "homeowner", "mobile_home" },
		effects = { Happiness = 1 },
	},
	{ 
		id = "townhouse", 
		name = "Townhouse", 
		emoji = "🏘️",
		price = 275000, 
		income = 1500,
		tier = "nice",
		happinessBonus = 5,
		statusBonus = 2,
		maintenanceCost = 3500,
		resaleModifier = 0.89,
		minAge = 18,
		description = "Multi-level urban townhome",
		grantsFlags = { "homeowner", "townhouse_owner" },
		effects = { Happiness = 6, Health = 1 },
	},
	{ 
		id = "lakehouse", 
		name = "Lakehouse", 
		emoji = "🏞️",
		price = 800000, 
		income = 4000,
		tier = "luxury",
		happinessBonus = 12,
		statusBonus = 6,
		maintenanceCost = 12000,
		resaleModifier = 0.91,
		minAge = 21,
		description = "Peaceful lakefront retreat",
		grantsFlags = { "homeowner", "lakehouse_owner", "vacation_home" },
		effects = { Happiness = 10, Health = 8 },
		fameBonus = 3,
	},
	{ 
		id = "island", 
		name = "Private Island", 
		emoji = "🏝️",
		price = 50000000, 
		income = 100000,
		tier = "billionaire",
		happinessBonus = 50,
		statusBonus = 50,
		maintenanceCost = 500000,
		resaleModifier = 0.97,
		minAge = 25,
		description = "Your own private paradise",
		grantsFlags = { "homeowner", "island_owner", "billionaire_lifestyle", "untouchable" },
		effects = { Happiness = 50, Health = 10, Looks = 5 },
		fameBonus = 25,
	},
}

local Vehicles = {
	{ 
		id = "used_civic", 
		name = "Used Honda Civic", 
		emoji = "🚗",
		price = 8000,
		tier = "budget",
		happinessBonus = 1,
		statusBonus = 0,
		maintenanceCost = 800,
		depreciationRate = 0.20,
		fuelCost = 1200,
		resaleModifier = 0.65,
		minAge = 16,
		description = "Reliable used car",
		grantsFlags = { "car_owner", "has_transport" },
		effects = { Happiness = 2 },
	},
	{ 
		id = "camry", 
		name = "Toyota Camry", 
		emoji = "🚙",
		price = 28000,
		tier = "reliable",
		happinessBonus = 3,
		statusBonus = 1,
		maintenanceCost = 1500,
		depreciationRate = 0.15,
		fuelCost = 1500,
		resaleModifier = 0.75,
		minAge = 16,
		description = "Dependable family sedan",
		grantsFlags = { "car_owner", "has_transport", "reliable_car" },
		effects = { Happiness = 4 },
	},
	{ 
		id = "bmw", 
		name = "BMW 3 Series", 
		emoji = "🚘",
		price = 55000,
		tier = "premium",
		happinessBonus = 6,
		statusBonus = 3,
		maintenanceCost = 3500,
		depreciationRate = 0.18,
		fuelCost = 2000,
		resaleModifier = 0.72,
		minAge = 18,
		description = "The Ultimate Driving Machine",
		grantsFlags = { "car_owner", "has_transport", "nice_car", "bmw_owner" },
		effects = { Happiness = 7, Looks = 2 },
		fameBonus = 1,
	},
	{ 
		id = "tesla", 
		name = "Tesla Model S", 
		emoji = "⚡",
		price = 95000,
		tier = "premium",
		happinessBonus = 8,
		statusBonus = 5,
		maintenanceCost = 1500,  -- EVs have lower maintenance
		depreciationRate = 0.22,
		fuelCost = 600,  -- Electricity is cheap
		resaleModifier = 0.70,
		minAge = 18,
		description = "Electric luxury performance",
		grantsFlags = { "car_owner", "has_transport", "nice_car", "tesla_owner", "eco_conscious" },
		effects = { Happiness = 10, Smarts = 2 },
		fameBonus = 2,
	},
	{ 
		id = "porsche", 
		name = "Porsche 911", 
		emoji = "🏎️",
		price = 180000,
		tier = "luxury",
		happinessBonus = 12,
		statusBonus = 8,
		maintenanceCost = 8000,
		depreciationRate = 0.12,  -- Porsche holds value
		fuelCost = 3000,
		resaleModifier = 0.82,
		minAge = 21,
		description = "Iconic sports car perfection",
		grantsFlags = { "car_owner", "has_transport", "luxury_car", "porsche_owner", "car_enthusiast" },
		effects = { Happiness = 15, Looks = 5 },
		fameBonus = 4,
	},
	{ 
		id = "lambo", 
		name = "Lamborghini", 
		emoji = "🦁",
		price = 300000,
		tier = "supercar",
		happinessBonus = 20,
		statusBonus = 15,
		maintenanceCost = 15000,
		depreciationRate = 0.15,
		fuelCost = 5000,
		resaleModifier = 0.78,
		minAge = 21,
		description = "Italian supercar perfection",
		grantsFlags = { "car_owner", "has_transport", "supercar_owner", "lambo_owner", "celebrity_car" },
		effects = { Happiness = 25, Looks = 8 },
		fameBonus = 8,
	},
	{ 
		id = "ferrari", 
		name = "Ferrari F8", 
		emoji = "🐎",
		price = 350000,
		tier = "supercar",
		happinessBonus = 22,
		statusBonus = 18,
		maintenanceCost = 18000,
		depreciationRate = 0.10,  -- Ferraris hold value well
		fuelCost = 5500,
		resaleModifier = 0.85,
		minAge = 21,
		description = "Prancing Horse perfection",
		grantsFlags = { "car_owner", "has_transport", "supercar_owner", "ferrari_owner", "celebrity_car" },
		effects = { Happiness = 28, Looks = 10 },
		fameBonus = 10,
	},
	{ 
		id = "yacht", 
		name = "Yacht", 
		emoji = "🛥️",
		price = 2000000,
		tier = "ultra",
		happinessBonus = 30,
		statusBonus = 25,
		maintenanceCost = 100000,
		depreciationRate = 0.08,
		fuelCost = 20000,
		resaleModifier = 0.75,
		minAge = 25,
		description = "Luxury seafaring vessel",
		grantsFlags = { "yacht_owner", "ultra_wealthy", "boat_owner", "can_sail" },
		effects = { Happiness = 30, Health = 5 },
		fameBonus = 15,
		canHostParties = true,
	},
	{ 
		id = "jet", 
		name = "Private Jet", 
		emoji = "✈️",
		price = 15000000,
		tier = "billionaire",
		happinessBonus = 50,
		statusBonus = 50,
		maintenanceCost = 500000,
		depreciationRate = 0.05,
		fuelCost = 200000,
		resaleModifier = 0.80,
		minAge = 25,
		description = "Ultimate travel luxury",
		grantsFlags = { "jet_owner", "billionaire_lifestyle", "can_fly_private", "elite" },
		effects = { Happiness = 50, Health = 3 },
		fameBonus = 30,
		fastTravel = true,
	},
	-- NEW VEHICLES FOR MORE VARIETY
	{ 
		id = "motorcycle", 
		name = "Motorcycle", 
		emoji = "🏍️",
		price = 12000,
		tier = "budget",
		happinessBonus = 4,
		statusBonus = 1,
		maintenanceCost = 500,
		depreciationRate = 0.15,
		fuelCost = 400,
		resaleModifier = 0.70,
		minAge = 16,
		description = "Freedom on two wheels",
		grantsFlags = { "motorcycle_owner", "has_transport", "biker" },
		effects = { Happiness = 6 },
		riskFactor = 1.5,  -- Higher accident chance
	},
	{ 
		id = "truck", 
		name = "Pickup Truck", 
		emoji = "🛻",
		price = 45000,
		tier = "reliable",
		happinessBonus = 4,
		statusBonus = 1,
		maintenanceCost = 2500,
		depreciationRate = 0.14,
		fuelCost = 3000,
		resaleModifier = 0.78,
		minAge = 16,
		description = "American workhorse",
		grantsFlags = { "car_owner", "has_transport", "truck_owner" },
		effects = { Happiness = 5 },
		utilityBonus = true,
	},
	{ 
		id = "helicopter", 
		name = "Helicopter", 
		emoji = "🚁",
		price = 3000000,
		tier = "ultra",
		happinessBonus = 35,
		statusBonus = 30,
		maintenanceCost = 150000,
		depreciationRate = 0.06,
		fuelCost = 50000,
		resaleModifier = 0.82,
		minAge = 25,
		description = "Beat the traffic entirely",
		grantsFlags = { "helicopter_owner", "ultra_wealthy", "can_fly" },
		effects = { Happiness = 35, Health = 2 },
		fameBonus = 20,
		fastTravel = true,
	},
}

local ShopItems = {
	{ 
		id = "sneakers", 
		name = "Sneakers", 
		emoji = "👟",
		price = 350,
		tier = "basic",
		happinessBonus = 1,
		looksBonus = 2,
		minAge = 10,
		description = "Fresh kicks",
		grantsFlags = { "stylish" },
		effects = { Happiness = 1, Looks = 2 },
	},
	{ 
		id = "iphone", 
		name = "iPhone", 
		emoji = "📱",
		price = 1200,
		tier = "tech",
		happinessBonus = 3,
		smartsBonus = 1,
		minAge = 10,
		description = "Latest smartphone",
		grantsFlags = { "has_phone", "connected", "tech_savvy" },
		effects = { Happiness = 3, Smarts = 1 },
	},
	{ 
		id = "bag", 
		name = "Designer Bag", 
		emoji = "👜",
		price = 2500,
		tier = "fashion",
		happinessBonus = 4,
		looksBonus = 5,
		statusBonus = 2,
		minAge = 14,
		description = "Luxury fashion statement",
		grantsFlags = { "fashionista", "designer_clothes" },
		effects = { Happiness = 4, Looks = 5 },
		fameBonus = 1,
	},
	{ 
		id = "gaming_pc", 
		name = "Gaming PC", 
		emoji = "🖥️",
		price = 3000,
		tier = "tech",
		happinessBonus = 5,
		smartsBonus = 3,
		minAge = 10,
		description = "Ultimate gaming rig",
		grantsFlags = { "gamer", "has_computer", "tech_enthusiast" },
		effects = { Happiness = 8, Smarts = 3 },
		unlocksCareers = { "content_creator", "pro_gamer", "streamer" },
	},
	{ 
		id = "necklace", 
		name = "Gold Necklace", 
		emoji = "📿",
		price = 3500,
		tier = "jewelry",
		happinessBonus = 3,
		looksBonus = 4,
		statusBonus = 2,
		minAge = 16,
		description = "Elegant gold jewelry",
		grantsFlags = { "jewelry_owner", "stylish" },
		effects = { Happiness = 3, Looks = 4 },
		fameBonus = 1,
		appreciates = true,  -- Can increase in value
	},
	{ 
		id = "watch", 
		name = "Designer Watch", 
		emoji = "⌚",
		price = 5000,
		tier = "luxury",
		happinessBonus = 5,
		looksBonus = 6,
		statusBonus = 4,
		minAge = 16,
		description = "Luxury timepiece",
		grantsFlags = { "watch_collector", "stylish", "refined" },
		effects = { Happiness = 5, Looks = 6 },
		fameBonus = 2,
		appreciates = true,
	},
	{ 
		id = "ring", 
		name = "Diamond Ring", 
		emoji = "💍",
		price = 15000,
		tier = "jewelry",
		happinessBonus = 8,
		looksBonus = 5,
		statusBonus = 5,
		minAge = 18,
		description = "Stunning diamond ring",
		grantsFlags = { "jewelry_owner", "diamond_owner" },
		effects = { Happiness = 8, Looks = 5 },
		fameBonus = 3,
		appreciates = true,
		canPropose = true,  -- Can use for marriage proposal
	},
	{ 
		id = "piano", 
		name = "Grand Piano", 
		emoji = "🎹",
		price = 50000,
		tier = "luxury",
		happinessBonus = 10,
		smartsBonus = 5,
		statusBonus = 8,
		minAge = 18,
		description = "Beautiful grand piano",
		grantsFlags = { "piano_owner", "cultured", "musician" },
		effects = { Happiness = 10, Smarts = 5 },
		fameBonus = 4,
		skillBonus = { Music = 10 },
	},
	-- NEW ITEMS FOR MORE VARIETY
	{ 
		id = "laptop", 
		name = "Laptop", 
		emoji = "💻",
		price = 1500,
		tier = "tech",
		happinessBonus = 2,
		smartsBonus = 3,
		minAge = 10,
		description = "Portable computing power",
		grantsFlags = { "has_computer", "can_work_remote" },
		effects = { Happiness = 2, Smarts = 3 },
	},
	{ 
		id = "camera", 
		name = "Professional Camera", 
		emoji = "📸",
		price = 4000,
		tier = "hobby",
		happinessBonus = 4,
		minAge = 14,
		description = "Capture moments professionally",
		grantsFlags = { "photographer", "creative" },
		effects = { Happiness = 5, Smarts = 2 },
		unlocksCareers = { "photographer", "content_creator" },
	},
	{ 
		id = "guitar", 
		name = "Electric Guitar", 
		emoji = "🎸",
		price = 2000,
		tier = "hobby",
		happinessBonus = 5,
		minAge = 10,
		description = "Rock out!",
		grantsFlags = { "plays_guitar", "musician" },
		effects = { Happiness = 6 },
		skillBonus = { Music = 5 },
		unlocksCareers = { "musician_local", "street_performer" },
	},
	{ 
		id = "luxury_watch", 
		name = "Rolex Watch", 
		emoji = "⌚",
		price = 25000,
		tier = "ultra_luxury",
		happinessBonus = 10,
		looksBonus = 8,
		statusBonus = 10,
		minAge = 21,
		description = "Status symbol on your wrist",
		grantsFlags = { "rolex_owner", "high_roller", "luxury_lifestyle" },
		effects = { Happiness = 12, Looks = 8 },
		fameBonus = 5,
		appreciates = true,
	},
	{ 
		id = "art_collection", 
		name = "Art Collection", 
		emoji = "🖼️",
		price = 100000,
		tier = "investment",
		happinessBonus = 8,
		statusBonus = 15,
		minAge = 25,
		description = "Curated fine art pieces",
		grantsFlags = { "art_collector", "cultured", "sophisticated" },
		effects = { Happiness = 8, Smarts = 3 },
		fameBonus = 8,
		appreciates = true,
		appreciationRate = 0.08,  -- 8% annual appreciation
	},
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #15: New luxury items to make money useful!
	-- User feedback: "assets like sneakers, designer bag, are not functional"
	-- These items now unlock events and provide meaningful gameplay benefits
	-- ══════════════════════════════════════════════════════════════════════════════
	{ 
		id = "rare_sneakers", 
		name = "Rare Jordan 1s", 
		emoji = "👟",
		price = 5000,
		tier = "collectible",
		happinessBonus = 6,
		looksBonus = 8,
		statusBonus = 5,
		minAge = 14,
		description = "Limited edition kicks - serious collector's item",
		grantsFlags = { "sneakerhead", "collector", "stylish", "rare_sneaker_owner" },
		effects = { Happiness = 8, Looks = 8 },
		fameBonus = 2,
		appreciates = true,
		appreciationRate = 0.12,  -- Sneakers can appreciate 12%/year
	},
	{ 
		id = "birkin_bag", 
		name = "Hermès Birkin Bag", 
		emoji = "👜",
		price = 50000,
		tier = "ultra_luxury",
		happinessBonus = 12,
		looksBonus = 15,
		statusBonus = 20,
		minAge = 21,
		description = "The holy grail of luxury bags - status symbol",
		grantsFlags = { "elite_fashion", "birkin_owner", "high_society", "fashion_icon" },
		effects = { Happiness = 15, Looks = 15 },
		fameBonus = 10,
		appreciates = true,
		appreciationRate = 0.10,
	},
	{ 
		id = "streaming_setup", 
		name = "Pro Streaming Setup", 
		emoji = "🎙️",
		price = 8000,
		tier = "tech",
		happinessBonus = 8,
		smartsBonus = 2,
		minAge = 14,
		description = "Complete streaming rig - camera, mic, lights, green screen",
		grantsFlags = { "streamer_setup", "content_creator_ready", "can_stream" },
		effects = { Happiness = 10, Smarts = 2 },
		unlocksCareers = { "streamer", "content_creator", "twitch_streamer" },
	},
	{ 
		id = "home_gym", 
		name = "Home Gym Equipment", 
		emoji = "🏋️",
		price = 12000,
		tier = "fitness",
		happinessBonus = 5,
		healthBonus = 10,
		looksBonus = 3,
		minAge = 16,
		description = "Complete home gym - weights, machines, everything you need",
		grantsFlags = { "has_home_gym", "fitness_enthusiast", "gym_rat" },
		effects = { Happiness = 5, Health = 10, Looks = 5 },
	},
	{ 
		id = "hot_tub", 
		name = "Hot Tub", 
		emoji = "🛁",
		price = 15000,
		tier = "luxury",
		happinessBonus = 10,
		healthBonus = 5,
		minAge = 21,
		description = "Perfect for parties or relaxation",
		grantsFlags = { "hot_tub_owner", "luxury_lifestyle", "party_ready" },
		effects = { Happiness = 12, Health = 5 },
		fameBonus = 2,
	},
	{ 
		id = "home_theater", 
		name = "Home Theater System", 
		emoji = "🎬",
		price = 25000,
		tier = "luxury",
		happinessBonus = 12,
		minAge = 21,
		description = "4K projector, surround sound, the works",
		grantsFlags = { "home_theater", "movie_buff", "luxury_lifestyle" },
		effects = { Happiness = 15, Smarts = 2 },
		fameBonus = 3,
	},
	{ 
		id = "crypto_wallet", 
		name = "Hardware Crypto Wallet", 
		emoji = "🔐",
		price = 500,
		tier = "tech",
		happinessBonus = 2,
		smartsBonus = 3,
		minAge = 18,
		description = "Secure your digital assets",
		grantsFlags = { "crypto_investor", "tech_savvy", "future_minded" },
		effects = { Happiness = 2, Smarts = 3 },
		-- This unlocks crypto-related events
	},
	{ 
		id = "patek_philippe", 
		name = "Patek Philippe Watch", 
		emoji = "⌚",
		price = 150000,
		tier = "ultra_luxury",
		happinessBonus = 15,
		looksBonus = 12,
		statusBonus = 25,
		minAge = 30,
		description = "You never own a Patek, you merely hold it for the next generation",
		grantsFlags = { "patek_owner", "ultra_wealthy", "watch_collector", "elite" },
		effects = { Happiness = 20, Looks = 12 },
		fameBonus = 15,
		appreciates = true,
		appreciationRate = 0.15,  -- Pateks appreciate well
	},
	{ 
		id = "wine_collection", 
		name = "Fine Wine Collection", 
		emoji = "🍷",
		price = 75000,
		tier = "investment",
		happinessBonus = 8,
		statusBonus = 12,
		minAge = 21,
		description = "Curated collection of vintage wines",
		grantsFlags = { "wine_collector", "sommelier", "refined_taste", "cultured" },
		effects = { Happiness = 10, Smarts = 2 },
		fameBonus = 5,
		appreciates = true,
		appreciationRate = 0.06,
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #MEGA-13: Comprehensive Education Catalog with INSTITUTIONS and DEGREES
-- The user complained that it showed "Bachelor Degree" instead of university name
-- Now each program has: institution (where you go), degree (what you earn), and name (for display)
-- ═══════════════════════════════════════════════════════════════════════════════
local EducationCatalog = {
	community = { 
		name = "Community College", 
		institution = "City Community College",
		degree = "Associate's Degree",
		cost = 15000, 
		duration = 2, 
		requirement = "high_school", 
		minAge = 18,
		description = "Affordable 2-year college - earn an Associate's degree",
		grantsFlags = { "community_college_student", "college_experience" },
		statBonuses = { Smarts = 8 },
	},
	bachelor = { 
		name = "State University", 
		institution = "State University",
		degree = "Bachelor's Degree",
		cost = 80000, 
		duration = 4, 
		requirement = "high_school", 
		minAge = 18,
		description = "4-year university - earn a Bachelor's degree",
		grantsFlags = { "university_student", "college_experience", "in_college" },
		statBonuses = { Smarts = 15 },
	},
	trade = { 
		name = "Trade School", 
		institution = "Technical Institute",
		degree = "Trade Certification",
		cost = 30000, 
		duration = 2, 
		requirement = "high_school", 
		minAge = 18,
		description = "Learn skilled trades - plumbing, electrical, HVAC, etc.",
		grantsFlags = { "trade_school_student", "learning_trade", "hands_on_skills" },
		statBonuses = { Smarts = 5, Health = 2 },
	},
	bootcamp = { 
		name = "Coding Bootcamp", 
		institution = "TechStack Academy",
		degree = "Developer Certification",
		cost = 12000, 
		duration = 1, 
		requirement = "high_school", 
		minAge = 18,
		description = "Intensive coding program - become a developer fast",
		grantsFlags = { "bootcamp_student", "coding_bootcamp", "tech_skills", "coder" },
		statBonuses = { Smarts = 12 },
	},
	master = { 
		name = "Graduate School", 
		institution = "State University Graduate School",
		degree = "Master's Degree",
		cost = 60000, 
		duration = 2, 
		requirement = "bachelor", 
		minAge = 22,
		description = "Advanced degree - specialize in your field",
		grantsFlags = { "graduate_student", "masters_program" },
		statBonuses = { Smarts = 18 },
	},
	business = { 
		name = "Business School", 
		institution = "Elite Business School",
		degree = "MBA",
		cost = 90000, 
		duration = 2, 
		requirement = "bachelor", 
		minAge = 22,
		description = "Master of Business Administration - leadership track",
		grantsFlags = { "mba_student", "business_education", "executive_track" },
		statBonuses = { Smarts = 15 },
	},
	law = { 
		name = "Law School", 
		institution = "College of Law",
		degree = "Juris Doctor (J.D.)",
		cost = 150000, 
		duration = 3, 
		requirement = "bachelor", 
		minAge = 22,
		description = "Become a lawyer - 3 years of intensive legal study",
		grantsFlags = { "law_student", "legal_education", "bar_eligible" },
		statBonuses = { Smarts = 20 },
	},
	medical = { 
		name = "Medical School", 
		institution = "School of Medicine",
		degree = "Doctor of Medicine (M.D.)",
		cost = 200000, 
		duration = 4, 
		requirement = "bachelor", 
		minAge = 22,
		description = "Become a doctor - 4 years of medical training",
		grantsFlags = { "medical_student", "pre_residency", "medical_education" },
		statBonuses = { Smarts = 25 },
	},
	phd = { 
		name = "PhD Program", 
		institution = "Research University",
		degree = "Doctorate (Ph.D.)",
		cost = 100000, 
		duration = 5, 
		requirement = "master", 
		minAge = 24,
		description = "Highest academic degree - become an expert in your field",
		grantsFlags = { "phd_student", "doctoral_candidate", "researcher" },
		statBonuses = { Smarts = 30 },
	},
}

local EducationRanks = {
	none = 0,
	high_school = 1,
	community = 2,
	trade = 2,
	bootcamp = 2,
	bachelor = 3,
	master = 4,
	business = 4,
	law = 5,
	medical = 5,
	phd = 6,
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #692: ROYAL EDUCATION EQUIVALENCY
	-- Royal education from private tutors, elite boarding schools, and academies
	-- should count as equivalent to (or better than) their civilian counterparts
	-- This allows royals to apply for jobs and enroll in colleges requiring high_school
	-- ═══════════════════════════════════════════════════════════════════════════════
	royal_private = 1,              -- Palace tutors = high school equivalent
	royal_prep = 1,                 -- Elite prep school = high school equivalent
	royal_boarding = 1,             -- Elite boarding school (Eton, etc) = high school equivalent
	royal_boarding_school = 1,      -- Completed boarding school = high school equivalent
	royal_private_secondary = 1,    -- Private secondary education = high school equivalent
	royal_military = 2,             -- Royal Military Academy (Sandhurst) = above high school
	royal_university = 3,           -- Royal university (Oxford, Cambridge) = bachelor equivalent
	private_education = 1,          -- Generic private education = high school equivalent
	elite_prep = 1,                 -- Elite preparatory school = high school equivalent
	boarding_school = 1,            -- Boarding school = high school equivalent
	swiss_finishing = 2,            -- Swiss finishing school = above high school
}

-- ============================================================================
-- Story Paths & Actions
-- ============================================================================

local StoryPaths = {
	political = {
		id = "political",
		name = "Political Career",
		description = "Rise from local office to the presidency.",
		color = C and C.Blue or Color3.fromRGB(59, 130, 246),
		minAge = 25,
		-- FIXED: Synced smarts requirement with StoryPathsScreen (was 65, now 70)
		requirements = { education = "bachelor", smarts = 70 },
		stages = { "local_office", "mayor", "governor", "senator", "president" },
	},
	criminal = {
		id = "criminal",
		name = "Crime Empire",
		description = "Climb the syndicate ranks.",
		color = C and C.Red or Color3.fromRGB(239, 68, 68),
		minAge = 16,
		requirements = {},
		stages = { "hustler", "operator", "lieutenant", "underboss", "boss" },
	},
	-- CRITICAL FIX: Add "mafia" path to match StoryPathsScreen
	-- The client defines a "mafia" path requiring MAFIA gamepass
	mafia = {
		id = "mafia",
		name = "Mafia Boss",
		description = "Rise through the ranks of organized crime.",
		color = C and C.Gray700 or Color3.fromRGB(55, 65, 81),
		minAge = 18,
		requirements = {},
		isPremium = true,
		gamepassKey = "MAFIA",
		stages = { "associate", "soldier", "capo", "underboss", "don" },
	},
	celebrity = {
		id = "celebrity",
		name = "Fame & Fortune",
		description = "Become a world-famous icon.",
		color = C and C.Amber or Color3.fromRGB(245, 158, 11),
		minAge = 14,
		requirements = { looks = 50 },
		stages = { "aspiring", "influencer", "rising_star", "celebrity", "icon" },
	},
	royal = {
		id = "royal",
		name = "Royal Dynasty",
		description = "Charm your way into royalty.",
		color = C and C.Purple or Color3.fromRGB(147, 51, 234),
		minAge = 18,
		-- FIXED: Synced looks requirement with StoryPathsScreen (was 75, now 80)
		requirements = { looks = 80, happiness = 60 },
		stages = { "commoner", "courted", "engaged", "married", "monarch" },
	},
}

local StoryPathActions = {
	political = {
		campaign = { cost = 5000, stats = { Happiness = -2 }, progress = 0.05 },
		debate = { stats = { Smarts = 2 }, progress = 0.04 },
		rally = { cost = 10000, stats = { Happiness = 4 }, progress = 0.06 },
		ad = { cost = 50000, progress = 0.1 },
		scandal = { risk = 40, stats = { Happiness = -6 }, progress = -0.08 },
	},
	criminal = {
		recruit = { stats = { Happiness = 2 }, progress = 0.05 },
		territory = { risk = 45, progress = 0.08 },
		heist = { risk = 60, reward = { 5000, 100000 }, progress = 0.1 },
		bribe = { cost = 25000, progress = 0.05 },
		war = { risk = 80, stats = { Health = -10 }, progress = 0.12 },
	},
	-- CRITICAL FIX: Add mafia path actions
	mafia = {
		collect = { reward = { 2000, 15000 }, progress = 0.04 },
		expand = { risk = 30, progress = 0.06 },
		hit = { risk = 50, stats = { Health = -5 }, progress = 0.08 },
		launder = { cost = 50000, progress = 0.05 },
		war = { risk = 70, stats = { Health = -15 }, progress = 0.12 },
	},
	celebrity = {
		post = { stats = { Happiness = 2 }, progress = 0.04 },
		collab = { stats = { Happiness = 3 }, progress = 0.05 },
		interview = { stats = { Happiness = 4 }, progress = 0.06 },
		scandal = { risk = 30, progress = 0.07 },
		charity = { cost = 10000, stats = { Happiness = 5 }, progress = 0.08 },
	},
	royal = {
		charm = { stats = { Happiness = 3 }, progress = 0.04 },
		etiquette = { stats = { Smarts = 2 }, progress = 0.05 },
		intrigue = { risk = 50, progress = 0.08 },
		heir = { stats = { Happiness = 6 }, progress = 0.1 },
		decree = { stats = { Happiness = -2 }, progress = 0.06 },
	},
}

-- ════════════════════════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: MOVE CAREER EVENT TABLES BEFORE THE FUNCTION THAT USES THEM
-- In Lua, local variables must be defined BEFORE they are referenced!
-- ════════════════════════════════════════════════════════════════════════════════════════════════

local PoliceCareerEvents = {
	{
		id = "police_patrol",
		title = "Suspicious Van",
		emoji = "🚓",
		text = "During a late-night patrol you spot a dark van idling behind a closed electronics store.",
		question = "How do you handle it?",
		choices = {
			{ text = "Call for backup and box them in", deltas = { Happiness = -1 }, setFlags = { police_cautious = true }, feedText = "You waited for backup and safely arrested the crew." },
			{ text = "Approach alone with confidence", deltas = { Health = -5, Happiness = 3 }, setFlags = { police_hero = true }, feedText = "You confronted the suspects solo and earned respect." },
			{ text = "Let it slide", deltas = { Happiness = -3 }, setFlags = { police_corrupt = true }, feedText = "You pretended not to notice the van." },
		},
	},
	{
		id = "police_bribe",
		title = "Traffic Stop Temptation",
		emoji = "🚔",
		text = "You pull over a wealthy executive who quietly offers an envelope to forget about the speeding.",
		question = "Take the envelope?",
		choices = {
			{ text = "Refuse and write the ticket", deltas = { Happiness = 2 }, setFlags = { police_reputable = true }, feedText = "You refused the bribe and wrote the ticket." },
			{ text = "Accept the cash", deltas = { Money = 2500, Happiness = 1 }, setFlags = { police_corrupt = true }, feedText = "You pocketed the envelope. Internal Affairs is now curious." },
		},
	},
	{
		id = "police_riot",
		title = "Crowd Control",
		emoji = "🛡️",
		text = "A protest turns heated. Barricades are shaking and the crowd is chanting your name.",
		question = "What tactic do you try?",
		choices = {
			{ text = "Defuse with calm orders", deltas = { Happiness = 3 }, setFlags = { police_mediator = true }, feedText = "You kept things calm and prevented violence." },
			{ text = "Charge the line", deltas = { Health = -10, Happiness = -2 }, setFlags = { police_hero = true }, feedText = "You pushed the line back but took some hits." },
			{ text = "Wait for SWAT", deltas = { Happiness = -1 }, setFlags = { police_cautious = true }, feedText = "You held position until SWAT arrived." },
		},
	},
}

local TechCareerEvents = {
	{
		id = "tech_deadline",
		title = "Crunch Time",
		emoji = "💻",
		text = "Your team's deadline is tomorrow and the code is still buggy. Your manager wants you to push anyway.",
		question = "What do you do?",
		choices = {
			{ text = "Push the buggy code", deltas = { Happiness = -2 }, setFlags = { tech_rushed = true }, feedText = "You shipped buggy code. Users are complaining." },
			{ text = "Stay late and fix it", deltas = { Health = -3, Happiness = 2, Smarts = 2 }, setFlags = { tech_dedicated = true }, feedText = "You pulled an all-nighter and shipped clean code." },
			{ text = "Request extension", deltas = { Happiness = 1 }, setFlags = { tech_realistic = true }, feedText = "You negotiated a 3-day extension." },
		},
	},
	{
		id = "tech_interview",
		title = "Job Offer",
		emoji = "🚀",
		text = "A competitor reaches out with a job offer paying 40% more than your current salary.",
		question = "How do you respond?",
		choices = {
			{ text = "Accept the offer", deltas = { Money = 15000, Happiness = 3 }, setFlags = { tech_job_hopper = true }, feedText = "You jumped ship for more money." },
			{ text = "Use it to negotiate a raise", deltas = { Money = 5000, Happiness = 2 }, feedText = "You leveraged the offer into a counter-offer." },
			{ text = "Decline and stay loyal", deltas = { Happiness = 1 }, setFlags = { tech_loyal = true }, feedText = "You stayed put for now." },
		},
	},
	{
		id = "tech_security",
		title = "Security Breach",
		emoji = "🔐",
		text = "You discover a critical security vulnerability in production code. Fixing it will delay the release.",
		question = "What's your move?",
		choices = {
			{ text = "Report it immediately", deltas = { Happiness = 2, Smarts = 3 }, setFlags = { tech_ethical = true }, feedText = "You reported the vulnerability and prevented a breach." },
			{ text = "Fix it quietly", deltas = { Smarts = 2 }, feedText = "You patched it without telling anyone." },
			{ text = "Ignore it for now", deltas = { Happiness = -5 }, setFlags = { tech_negligent = true }, feedText = "The vulnerability was exploited weeks later." },
		},
	},
}

local MedicalCareerEvents = {
	{
		id = "medical_emergency",
		title = "Code Blue",
		emoji = "🚑",
		text = "A patient flatlines during your shift. You're the closest medical staff.",
		question = "What do you do?",
		choices = {
			{ text = "Start CPR immediately", deltas = { Health = -2, Happiness = 4 }, setFlags = { medical_hero = true }, feedText = "You saved a life with quick action." },
			{ text = "Call for the crash team", deltas = { Happiness = 1 }, feedText = "You followed protocol and got help." },
			{ text = "Freeze up", deltas = { Happiness = -5, Health = -3 }, setFlags = { medical_anxious = true }, feedText = "You froze and the patient died." },
		},
	},
	{
		id = "medical_ethics",
		title = "Ethical Dilemma",
		emoji = "⚕️",
		text = "A wealthy patient offers you $50,000 to skip them ahead in the transplant list.",
		question = "What do you say?",
		choices = {
			{ text = "Refuse firmly", deltas = { Happiness = 3 }, setFlags = { medical_ethical = true }, feedText = "You refused the bribe and reported the incident." },
			{ text = "Accept the money", deltas = { Money = 50000, Happiness = -2 }, setFlags = { medical_corrupt = true }, feedText = "You took the bribe. Your conscience weighs heavy." },
		},
	},
	{
		id = "medical_mistake",
		title = "Medical Error",
		emoji = "💊",
		text = "You realize you prescribed the wrong dosage to a patient yesterday. They haven't taken it yet.",
		question = "How do you handle it?",
		choices = {
			{ text = "Call them immediately", deltas = { Happiness = 2, Smarts = 2 }, setFlags = { medical_responsible = true }, feedText = "You caught the error in time and fixed it." },
			{ text = "Quietly fix it in the system", deltas = { Happiness = -1 }, feedText = "You corrected the record without telling anyone." },
			{ text = "Hope they don't notice", deltas = { Happiness = -10 }, setFlags = { medical_negligent = true }, feedText = "The patient had a reaction and sued the hospital." },
		},
	},
	{
		id = "medical_grateful_patient",
		title = "Grateful Patient",
		emoji = "💗",
		text = "A patient you treated last month returns to thank you. They say you saved their life.",
		question = "How do you respond?",
		choices = {
			{ text = "Accept their gratitude warmly", deltas = { Happiness = 10 }, setFlags = { medical_compassionate = true }, feedText = "A heartwarming moment that reminds you why you do this." },
			{ text = "Stay professional", deltas = { Happiness = 3, Smarts = 1 }, feedText = "You maintained composure while feeling proud inside." },
		},
	},
	{
		id = "medical_long_shift",
		title = "Double Shift Emergency",
		emoji = "😴",
		text = "Short-staffed. Your supervisor asks you to work a double shift during a patient surge.",
		question = "What do you say?",
		cooldown = 2,
		choices = {
			{ text = "Stay and help", deltas = { Health = -5, Happiness = -2, Money = 300 }, setFlags = { medical_dedicated = true }, feedText = "Exhausted but you powered through. Patients needed you." },
			{ text = "Decline - safety first", deltas = { Happiness = 2, Health = 1 }, feedText = "You need rest to provide good care. Smart call." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #MEGA-6: TRADES CAREER EVENTS
-- Construction, electrician, plumber, mechanic specific events
-- ═══════════════════════════════════════════════════════════════════════════════
local TradesCareerEvents = {
	{
		id = "trades_dangerous_site",
		title = "Dangerous Job Site",
		emoji = "⚠️",
		text = "The job site has serious safety violations. Your boss tells you to ignore them and keep working.",
		question = "What do you do?",
		choices = {
			{ text = "Report to OSHA", deltas = { Happiness = 2 }, setFlags = { trades_whistleblower = true }, feedText = "You reported it. Safety first. Boss is furious but you're protected." },
			{ text = "Refuse to work until fixed", deltas = { Happiness = 3, Money = -100 }, setFlags = { trades_safety_conscious = true }, feedText = "You stood your ground. Eventually got fixed." },
			{ text = "Keep working", deltas = { Health = -5, Money = 50 }, feedText = "You risked it. Got extra pay but feel uneasy." },
		},
	},
	{
		id = "trades_apprentice",
		title = "Teaching the Apprentice",
		emoji = "🔧",
		text = "A new apprentice is assigned to you. They're eager but completely clueless.",
		question = "How do you train them?",
		cooldown = 3,
		choices = {
			{ text = "Be patient and thorough", deltas = { Happiness = 3, Smarts = 2 }, setFlags = { trades_mentor = true }, feedText = "You passed on your knowledge. They're improving fast." },
			{ text = "Sink or swim approach", deltas = { Happiness = 1 }, feedText = "They'll figure it out. You did." },
			{ text = "Do their work for them", deltas = { Happiness = -2, Health = -1 }, feedText = "Easier than explaining. But now you're doing double the work." },
		},
	},
	{
		id = "trades_side_job",
		title = "Cash Side Job",
		emoji = "💵",
		text = "A homeowner offers you $500 cash to do a job on the side - off the books.",
		question = "Do you take it?",
		cooldown = 2,
		choices = {
			{ text = "Take the cash job", deltas = { Money = 500, Happiness = 3 }, setFlags = { trades_side_hustle = true }, feedText = "Easy money. Just don't tell the boss." },
			{ text = "Decline - not worth the risk", deltas = { Happiness = 1 }, feedText = "You stayed legit. Less money but peace of mind." },
			{ text = "Refer them to your company", deltas = { Smarts = 2 }, setFlags = { trades_company_man = true }, feedText = "You brought in new business. Might get a bonus." },
		},
	},
	{
		id = "trades_major_project",
		title = "Big Contract",
		emoji = "🏗️",
		text = "Your company lands a huge contract. Everyone's working overtime.",
		question = "How do you handle the crunch?",
		cooldown = 3,
		choices = {
			{ text = "Work the overtime", deltas = { Money = 800, Health = -3, Happiness = -1 }, feedText = "Paychecks are FAT. Body is tired." },
			{ text = "Stick to your hours", deltas = { Happiness = 2 }, feedText = "Work-life balance is important. Less money but more sanity." },
			{ text = "Lead a crew", deltas = { Money = 400, Smarts = 3 }, setFlags = { trades_foreman_potential = true }, feedText = "You stepped up. Management noticed." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #MEGA-7: FINANCE CAREER EVENTS  
-- Banking, accounting, investment specific events
-- ═══════════════════════════════════════════════════════════════════════════════
local FinanceCareerEvents = {
	{
		id = "finance_insider_tip",
		title = "Insider Information",
		emoji = "📊",
		text = "A colleague slips you insider info about a stock that's about to soar.",
		question = "What do you do?",
		choices = {
			{ text = "Trade on it", deltas = { Money = 15000, Happiness = 3 }, setFlags = { finance_insider_trading = true }, feedText = "Big profits! But you broke the law. Hope no one finds out." },
			{ text = "Report it to compliance", deltas = { Happiness = 2 }, setFlags = { finance_ethical = true }, feedText = "You did the right thing. Colleague got fired." },
			{ text = "Ignore it", deltas = { Happiness = 1 }, feedText = "You stayed out of it. Probably for the best." },
		},
	},
	{
		id = "finance_audit",
		title = "Audit Findings",
		emoji = "🔍",
		text = "During an audit, you discover someone has been cooking the books for years.",
		question = "What do you do?",
		cooldown = 4,
		oneTime = true,
		choices = {
			{ text = "Report to regulators", deltas = { Happiness = 5 }, setFlags = { finance_whistleblower = true }, feedText = "You exposed the fraud. Major scandal but you're a hero." },
			{ text = "Confront the person privately", deltas = { Happiness = 2 }, feedText = "They offered to fix it quietly. You're watching them now." },
			{ text = "Pretend you didn't see it", deltas = { Happiness = -5 }, setFlags = { finance_complicit = true }, feedText = "You closed your eyes. Hope it doesn't come back to haunt you." },
		},
	},
	{
		id = "finance_big_client",
		title = "Whale Client",
		emoji = "💰",
		text = "A high-net-worth client wants YOU to manage their $10M portfolio.",
		question = "How do you respond?",
		cooldown = 3,
		choices = {
			{ text = "Accept confidently", deltas = { Happiness = 8, Money = 2000 }, setFlags = { finance_big_player = true }, feedText = "Major responsibility but huge commissions. Career defining." },
			{ text = "Recommend a senior colleague", deltas = { Happiness = 2 }, setFlags = { finance_humble = true }, feedText = "You played it safe. Maybe too safe?" },
		},
	},
	{
		id = "finance_market_crash",
		title = "Market Crash",
		emoji = "📉",
		text = "The market is crashing. Clients are panicking and calling non-stop.",
		question = "How do you handle the chaos?",
		cooldown = 5,
		choices = {
			{ text = "Stay calm, reassure clients", deltas = { Happiness = -2, Smarts = 3 }, setFlags = { finance_steady = true }, feedText = "You kept your cool when others lost theirs. Clients trust you more." },
			{ text = "Panic with everyone else", deltas = { Happiness = -5, Smarts = -2 }, feedText = "You made some bad calls in the chaos. Costly mistakes." },
			{ text = "Spot opportunities", deltas = { Money = 5000, Smarts = 5 }, setFlags = { finance_opportunist = true }, feedText = "While others panicked, you found undervalued stocks. Smart money." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #MEGA-8: EDUCATION CAREER EVENTS
-- Teacher, professor, administrator specific events
-- ═══════════════════════════════════════════════════════════════════════════════
local EducationCareerEvents = {
	{
		id = "education_difficult_student",
		title = "Challenging Student",
		emoji = "📚",
		text = "A student is constantly disruptive and disrespectful in your class.",
		question = "How do you handle it?",
		cooldown = 2,
		choices = {
			{ text = "Work with them one-on-one", deltas = { Happiness = 3, Health = -1 }, setFlags = { education_patient = true }, feedText = "Extra effort paid off. They're actually smart, just troubled." },
			{ text = "Strict discipline", deltas = { Happiness = 1 }, feedText = "You enforced the rules. Order restored but they resent you." },
			{ text = "Send them to the principal", deltas = { Happiness = -1 }, feedText = "Not your problem anymore. But you wonder if you could have helped." },
		},
	},
	{
		id = "education_breakthrough",
		title = "Teaching Breakthrough",
		emoji = "💡",
		text = "A struggling student finally 'gets it' thanks to your teaching approach.",
		question = "How does this affect you?",
		cooldown = 3,
		choices = {
			{ text = "Feel proud and motivated", deltas = { Happiness = 10 }, setFlags = { education_inspired = true }, feedText = "THIS is why you teach. Powerful moment." },
			{ text = "Just doing your job", deltas = { Happiness = 3, Smarts = 1 }, feedText = "Another day, another lightbulb moment. You're good at this." },
		},
	},
	{
		id = "education_parent_conflict",
		title = "Angry Parent",
		emoji = "😤",
		text = "A parent is furious their child got a bad grade. They're threatening to go to the principal.",
		question = "How do you respond?",
		cooldown = 2,
		choices = {
			{ text = "Stand by your grading", deltas = { Happiness = 2 }, setFlags = { education_firm = true }, feedText = "You explained your standards. They eventually backed down." },
			{ text = "Change the grade to avoid conflict", deltas = { Happiness = -5 }, setFlags = { education_pushover = true }, feedText = "Path of least resistance. But other parents will expect the same." },
			{ text = "Invite them to a meeting", deltas = { Happiness = 3, Smarts = 2 }, setFlags = { education_diplomatic = true }, feedText = "Open communication resolved the issue. Professional handling." },
		},
	},
	{
		id = "education_grant",
		title = "Research Grant Opportunity",
		emoji = "🎓",
		text = "There's a prestigious research grant available. Application deadline is in a week.",
		question = "Do you apply?",
		cooldown = 4,
		choices = {
			{ text = "Apply with strong proposal", deltas = { Smarts = 3, Happiness = 2 }, setFlags = { education_researcher = true }, feedText = "You submitted a compelling proposal. Fingers crossed!" },
			{ text = "Skip it - too busy", deltas = { Happiness = 1 }, feedText = "Maybe next year. Teaching comes first." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #MEGA-9: LEGAL CAREER EVENTS
-- Lawyer, paralegal, judge specific events
-- ═══════════════════════════════════════════════════════════════════════════════
local LegalCareerEvents = {
	{
		id = "legal_guilty_client",
		title = "Guilty Client",
		emoji = "⚖️",
		text = "Your client confesses to you privately that they're guilty of a serious crime.",
		question = "What do you do?",
		cooldown = 4,
		choices = {
			{ text = "Continue their defense", deltas = { Happiness = -2, Money = 2000 }, setFlags = { legal_pragmatic = true }, feedText = "Everyone deserves a defense. That's the law." },
			{ text = "Withdraw from the case", deltas = { Happiness = 3, Money = -1000 }, setFlags = { legal_moral = true }, feedText = "You couldn't do it. Conscience over career." },
			{ text = "Try to negotiate a plea", deltas = { Happiness = 2, Smarts = 3 }, setFlags = { legal_strategic = true }, feedText = "You got them a better deal while serving justice. Best outcome." },
		},
	},
	{
		id = "legal_big_case",
		title = "Career-Defining Case",
		emoji = "🏛️",
		text = "You've been assigned to a high-profile case. The whole firm is watching.",
		question = "How do you approach it?",
		cooldown = 3,
		choices = {
			{ text = "Work around the clock", deltas = { Health = -5, Happiness = 3, Smarts = 5 }, setFlags = { legal_workaholic = true }, feedText = "You won the case! Your reputation soared." },
			{ text = "Collaborate with the team", deltas = { Happiness = 4, Smarts = 3 }, setFlags = { legal_team_player = true }, feedText = "Together you achieved victory. Good leadership material." },
			{ text = "Play it safe", deltas = { Happiness = 1 }, feedText = "Decent outcome. But you didn't stand out." },
		},
	},
	{
		id = "legal_ethics_violation",
		title = "Ethical Violation",
		emoji = "🚫",
		text = "A senior partner asks you to hide evidence that could help the opposing side.",
		question = "What do you do?",
		oneTime = true,
		choices = {
			{ text = "Refuse and report", deltas = { Happiness = 5 }, setFlags = { legal_ethical = true }, feedText = "You reported it to the bar. Partner was sanctioned. Your conscience is clear." },
			{ text = "Do as asked", deltas = { Money = 5000, Happiness = -8 }, setFlags = { legal_corrupt = true }, feedText = "You crossed the line. It haunts you." },
			{ text = "Anonymously leak it", deltas = { Happiness = 3 }, setFlags = { legal_whistleblower = true }, feedText = "The truth came out without your fingerprints. Justice served." },
		},
	},
}

local OfficeCareerEvents = {
	{
		id = "office_credit",
		title = "Stolen Credit",
		emoji = "📊",
		text = "Your manager presents YOUR project to executives as their own idea.",
		question = "What do you do?",
		cooldown = 8, -- CRITICAL FIX: Prevent spam - was happening too often!
		maxOccurrences = 2, -- Maximum 2 times per life
		choices = {
			{ text = "Confront them privately", deltas = { Happiness = 2 }, setFlags = { office_assertive = true }, feedText = "You addressed the issue directly." },
			{ text = "Email the executives with proof", deltas = { Happiness = 3 }, setFlags = { office_bold = true }, feedText = "You exposed the credit theft." },
			{ text = "Let it slide", deltas = { Happiness = -3 }, setFlags = { office_pushover = true }, feedText = "You let your work be stolen." },
		},
	},
	{
		id = "office_gossip",
		title = "Office Gossip",
		emoji = "💬",
		text = "Coworkers are spreading rumors about a colleague's personal life. They want you to join in.",
		question = "What do you do?",
		cooldown = 3, -- CRITICAL FIX: Prevent spam
		maxOccurrences = 2,
		choices = {
			{ text = "Refuse to participate", deltas = { Happiness = 2 }, setFlags = { office_professional = true }, feedText = "You stayed above the gossip." },
			{ text = "Join the conversation", deltas = { Happiness = 1 }, setFlags = { office_gossiper = true }, feedText = "You participated in the gossip." },
			{ text = "Defend the colleague", deltas = { Happiness = 3 }, setFlags = { office_defender = true }, feedText = "You stood up for your colleague." },
		},
	},
	{
		id = "office_overwork",
		title = "Weekend Work",
		emoji = "🏢",
		text = "Your boss asks you to work this weekend. Again. You have family plans.",
		question = "What do you say?",
		-- CRITICAL FIX: Prevent spam with cooldown, max occurrences, and smart eligibility
		cooldown = 3, -- At least 3 years between occurrences
		maxOccurrences = 3, -- Can only happen 3 times total per life
		weight = 3, -- Lower weight = less likely to be picked
		choices = {
			{ text = "Work the weekend", deltas = { Happiness = -4, Money = 200 }, setFlags = { office_workaholic = true }, feedText = "You cancelled plans to work." },
			{ text = "Politely decline", deltas = { Happiness = 3 }, setFlags = { office_boundaries = true }, feedText = "You set healthy boundaries." },
			{ text = "Negotiate half day", deltas = { Happiness = 1, Money = 100 }, feedText = "You compromised on a half day." },
		},
	},
}

local FinanceCareerEvents = {
	{
		id = "finance_insider",
		title = "Insider Trading Tip",
		emoji = "💹",
		text = "A client accidentally shares material non-public information about an upcoming merger.",
		question = "What do you do?",
		choices = {
			{ text = "Report to compliance", deltas = { Happiness = 3 }, setFlags = { finance_ethical = true }, feedText = "You reported the potential violation." },
			{ text = "Trade on the info", deltas = { Money = 50000, Happiness = -2 }, setFlags = { finance_insider_trader = true }, feedText = "You made an illegal trade." },
			{ text = "Pretend you didn't hear", deltas = { Happiness = -1 }, feedText = "You ignored the information." },
		},
	},
	{
		id = "finance_market_crash",
		title = "Market Chaos",
		emoji = "📉",
		text = "The market is crashing. Your clients are panicking and calling non-stop.",
		question = "How do you handle it?",
		choices = {
			{ text = "Calm them down, advise holding", deltas = { Happiness = 2, Smarts = 2 }, setFlags = { finance_steady = true }, feedText = "You kept clients calm during the chaos." },
			{ text = "Sell everything", deltas = { Happiness = -3 }, setFlags = { finance_panic = true }, feedText = "You panic-sold at the bottom." },
			{ text = "Go dark and hide", deltas = { Happiness = -5 }, setFlags = { finance_coward = true }, feedText = "You avoided all calls and lost clients." },
		},
	},
	{
		id = "finance_bonus",
		title = "Bonus Season",
		emoji = "💰",
		text = "Bonuses are announced. Yours is lower than expected, while a less qualified colleague got more.",
		question = "What do you do?",
		choices = {
			{ text = "Negotiate with your boss", deltas = { Money = 5000, Happiness = 2 }, feedText = "You negotiated a bonus adjustment." },
			{ text = "Accept it quietly", deltas = { Happiness = -2 }, feedText = "You accepted the lower bonus." },
			{ text = "Start job hunting", deltas = { Happiness = 1 }, setFlags = { finance_looking = true }, feedText = "You started looking for new opportunities." },
		},
	},
}

function LifeBackend:buildCareerEvent(state)
	local job = state and state.CurrentJob
	if not job or not job.id then
		return nil
	end
	local jobId = string.lower(job.id)
	local jobCategory = (job.category and string.lower(job.category)) or ""
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #47: Career events MUST match job category EXACTLY
	-- OLD BUG: String matching in job IDs caused tech events to fire for non-tech workers
	-- NEW: Only use explicit job category, and validate player has relevant experience flags
	-- This prevents "coding card popped up but I didn't do any coding" issues
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	local eventPool = nil
	local eventSource = nil
	state.Flags = state.Flags or {}
	
	-- CRITICAL: Use ONLY explicit job category for matching - NO string matching!
	-- This ensures career events are truly specific to the player's actual career path
	
	-- Police/Government law enforcement events
	if jobCategory == "government" and (jobId:find("police") or jobId:find("detective") or jobId:find("fbi") or jobId:find("cia")) then
		-- Additional check: must have law enforcement flag
		if state.Flags.law_enforcement or state.Flags.police_experience then
			eventPool = PoliceCareerEvents
			eventSource = "career_police"
		end
	-- Tech events - STRICT: Must have tech category AND coder/tech flags
	elseif jobCategory == "tech" then
		-- CRITICAL FIX #48: Tech events require player to have tech experience flags
		-- This prevents coding events from firing for someone who never learned to code
		if state.Flags.coder or state.Flags.tech_experience or state.Flags.developer_experience or state.Flags.computer_skills then
			eventPool = TechCareerEvents
			eventSource = "career_tech"
		else
			-- Player has tech job but no tech flags - use generic office events instead
			eventPool = OfficeCareerEvents
			eventSource = "career_office_generic"
		end
	-- Medical events - STRICT: Must have medical category
	elseif jobCategory == "medical" then
		if state.Flags.medical_experience or state.Flags.nursing_experience or state.Flags.hospital_work then
			eventPool = MedicalCareerEvents
			eventSource = "career_medical"
		end
	-- Office events - STRICT: Must have office category
	elseif jobCategory == "office" then
		eventPool = OfficeCareerEvents
		eventSource = "career_office"
	-- Finance events - STRICT: Must have finance category
	elseif jobCategory == "finance" then
		if state.Flags.banking_experience or state.Flags.accounting_experience or state.Flags.financial_analysis then
			eventPool = FinanceCareerEvents
			eventSource = "career_finance"
		else
			eventPool = OfficeCareerEvents
			eventSource = "career_office_generic"
		end
	-- Entry-level/service/retail events - use office events as fallback
	elseif jobCategory == "entry" or jobCategory == "service" or jobCategory == "retail" then
		eventPool = OfficeCareerEvents
		eventSource = "career_entry"
	-- Creative category (acting, music, etc.)
	elseif jobCategory == "creative" then
		eventPool = OfficeCareerEvents -- Use generic office events for creative
		eventSource = "career_creative"
	-- Hacker category
	elseif jobCategory == "hacker" then
		if state.Flags.coder or state.Flags.hacker_experience then
			eventPool = TechCareerEvents
			eventSource = "career_hacker"
		end
	-- Racing category - no specific events, skip
	elseif jobCategory == "racing" then
		return nil -- Racing has its own event system
	-- Science category - use tech events if they have analytical skills
	elseif jobCategory == "science" then
		if state.Flags.research_experience or state.Flags.scientific_background then
			eventPool = TechCareerEvents
			eventSource = "career_science"
		end
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #MEGA-10: TRADES CATEGORY - Construction, plumber, electrician, mechanic
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif jobCategory == "trades" or jobCategory == "construction" or jobCategory == "manual" then
		eventPool = TradesCareerEvents
		eventSource = "career_trades"
		-- Set trades experience flag when working in trades
		state.Flags.trades_experience = true
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #MEGA-11: EDUCATION CATEGORY - Teacher, professor, administrator
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif jobCategory == "education" then
		eventPool = EducationCareerEvents
		eventSource = "career_education"
		state.Flags.education_experience = true
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #MEGA-12: LEGAL CATEGORY - Lawyer, paralegal, judge
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif jobCategory == "legal" or jobCategory == "law" then
		eventPool = LegalCareerEvents
		eventSource = "career_legal"
		state.Flags.legal_experience = true
	end
	
	-- CRITICAL FIX #49: If no matching event pool, return nil instead of random events
	-- This prevents career events from firing for incompatible job categories
	if not eventPool or #eventPool == 0 then
		return nil
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #AAA-11: Filter out events that are on cooldown or have maxed occurrences
	-- This was the main cause of event spam - career events weren't respecting cooldowns
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.EventHistory = state.EventHistory or {}
	local eligibleEvents = {}
	
	for _, template in ipairs(eventPool) do
		local eventId = template.id
		local history = state.EventHistory[eventId]
		local isEligible = true
		
		-- Check cooldown (default 2 years for career events)
		local cooldown = template.cooldown or 2
		if history and history.lastAge then
			local yearsSince = (state.Age or 0) - history.lastAge
			if yearsSince < cooldown then
				isEligible = false
			end
		end
		
		-- Check max occurrences (default 3 for career events)
		local maxOccurrences = template.maxOccurrences or 3
		if history and (history.count or 0) >= maxOccurrences then
			isEligible = false
		end
		
		-- Check one-time events
		if template.oneTime and history then
			isEligible = false
		end
		
		if isEligible then
			table.insert(eligibleEvents, template)
		end
	end
	
	-- If no eligible events, return nil
	if #eligibleEvents == 0 then
		return nil
	end
	
	local template = chooseRandom(eligibleEvents)
	if not template then
		return nil
	end
	
	-- Record this event occurrence
	local eventId = template.id
	if not state.EventHistory[eventId] then
		state.EventHistory[eventId] = { count = 0 }
	end
	state.EventHistory[eventId].count = (state.EventHistory[eventId].count or 0) + 1
	state.EventHistory[eventId].lastAge = state.Age or 0
	
	local eventDef = deepCopy(template)
	eventDef.id = template.id .. "_" .. tostring(RANDOM:NextInteger(1000, 999999))
	eventDef.source = eventSource
	eventDef.baseEventId = template.id -- Keep track of base ID for history
	return eventDef
end

-- ============================================================================
-- Event Catalog (contextual story events, per category)
-- ============================================================================

local EventCatalog = {
	childhood = {
		{
			id = "child_schoolyard",
			title = "Schoolyard Antics",
			emoji = "🎒",
			text = "A bully keeps bothering you during recess.",
			question = "How do you respond?",
			choices = {
				{ text = "Tell a teacher", deltas = { Happiness = -2, Smarts = 2 }, flags = { brave = true }, feed = "stood up for yourself at school." },
				{ text = "Stand up to them", deltas = { Health = -1, Happiness = 3 }, feed = "confronted a bully and earned respect." },
				{ text = "Ignore it", deltas = { Happiness = -3 }, feed = "kept your head down at recess." },
			},
		},
		{
			id = "child_sickday",
			title = "Sick Day",
			emoji = "🤒",
			text = "You wake up feeling awful before an exam.",
			question = "What will you do?",
			choices = {
				{ text = "Stay home", deltas = { Health = 4, Smarts = -2 }, feed = "rested at home instead of taking a test." },
				{ text = "Push through", deltas = { Health = -3, Smarts = 2 }, feed = "toughed out an exam while sick." },
			},
		},
	},
	teen = {
		{
			id = "teen_exam",
			title = "Entrance Exam",
			emoji = "📚",
			text = "A prestigious school invites you to take a difficult entrance exam.",
			question = "Do you cram or wing it?",
			choices = {
				{ text = "Study all night", deltas = { Smarts = 4, Health = -2 }, feed = "studied past midnight for an exam." },
				{ text = "Trust your instincts", deltas = { Smarts = 1, Happiness = 2 }, feed = "trusted your instincts on a big exam." },
			},
		},
		{
			id = "teen_party",
			title = "House Party Invite",
			emoji = "🥳",
			text = "Friends invite you to a rowdy party the night before SAT prep.",
			question = "What's the move?",
			choices = {
				{ text = "Stay in and study", deltas = { Smarts = 3, Happiness = -2 }, feed = "skipped a party to study." },
				{ text = "Go anyway", deltas = { Happiness = 4, Smarts = -2 }, feed = "went to a party and memories were made." },
			},
		},
	},
	career_medical = {
		{
			id = "med_shift",
			title = "Chaotic ER Shift",
			emoji = "🏥",
			text = "Three critical patients arrive simultaneously during your ER shift.",
			question = "How do you triage?",
			choices = {
				{ text = "Lead decisively", deltas = { Happiness = -4 }, career = { performance = 8, progress = 6 }, feed = "took charge during a chaotic ER shift." },
				{ text = "Call for help", deltas = { Happiness = -1 }, career = { performance = 4 }, feed = "coordinated with colleagues on a hectic shift." },
			},
		},
		{
			id = "med_mistake",
			title = "Charting Mistake",
			emoji = "🩺",
			text = "You realize a colleague charted the wrong dosage on a patient record.",
			question = "Do you speak up?",
			choices = {
				{ text = "Correct it quietly", deltas = { Smarts = 2 }, career = { performance = 4 }, feed = "caught a dosage error before it was too late." },
				{ text = "Report it formally", deltas = { Happiness = -2 }, career = { performance = 6 }, feed = "reported a medication error to supervisors." },
			},
		},
	},
	career_tech = {
		{
			id = "tech_outage",
			title = "Production Outage",
			emoji = "💻",
			text = "A massive outage hits your product minutes before launch.",
			question = "How do you respond?",
			choices = {
				{ text = "Lead the war room", deltas = { Happiness = -3 }, career = { performance = 7, progress = 5 }, feed = "led the response to a critical outage." },
				{ text = "Patch quietly", deltas = { Smarts = 2 }, career = { performance = 4 }, feed = "froze feature rollout to stabilize prod." },
			},
		},
		{
			id = "tech_opportunity",
			title = "Side Project Buzz",
			emoji = "🚀",
			text = "Your side project gains traction online.",
			question = "Focus on the day job or chase the hype?",
			choices = {
				{ text = "Stay loyal", deltas = { Happiness = -1 }, career = { performance = 3 }, feed = "stayed focused on your employer despite side buzz." },
				{ text = "Pitch it internally", deltas = { Happiness = 2 }, career = { progress = 4 }, feed = "pitched your side project to leadership." },
			},
		},
	},
	career_creative = {
		{
			id = "creative_brief",
			title = "Impossible Brief",
			emoji = "🎨",
			text = "A client wants a full rebrand in two days.",
			question = "What do you propose?",
			choices = {
				{ text = "Push back", deltas = { Happiness = -1 }, career = { performance = 3 }, feed = "stood firm on creative timelines." },
				{ text = "Pull an all-nighter", deltas = { Health = -4, Happiness = 3 }, career = { performance = 5 }, feed = "burned the midnight oil for a demanding client." },
			},
		},
	},
	romance = {
		{
			id = "romance_conflict",
			title = "Heart-to-Heart",
			emoji = "💞",
			text = "Your partner feels neglected during your grind.",
			question = "How do you address it?",
			choices = {
				{ text = "Plan a surprise date", deltas = { Happiness = 4 }, relationships = { delta = 8 }, cost = 200, feed = "put career aside for a surprise date night." },
				{ text = "Explain the hustle", deltas = { Happiness = -1 }, relationships = { delta = 3 }, feed = "had a difficult talk about priorities." },
			},
		},
	},
	crime = {
		{
			id = "crime_dilemma",
			title = "Risky Opportunity",
			emoji = "🕶️",
			text = "An underboss offers you a high-stakes job.",
			question = "Take the gig?",
			choices = {
				{ text = "Take the job", deltas = { Happiness = 3 }, crime = { reward = { 20000, 80000 }, riskBonus = 15 }, feed = "accepted a lucrative, dangerous contract." },
				{ text = "Lay low", deltas = { Happiness = -2 }, feed = "kept a low profile despite pressure." },
			},
		},
	},
	general = {
		{
			id = "general_raise",
			title = "Unexpected Raise",
			emoji = "💰",
			text = "Your manager offers a modest raise if you take on extra responsibilities.",
			question = "Accept?",
			choices = {
				{ text = "Accept", deltas = { Happiness = 2 }, career = { salaryBonus = 0.05 }, feed = "took on extra responsibilities for a raise." },
				{ text = "Decline politely", deltas = { Happiness = -1 }, feed = "protected your work-life balance." },
			},
		},
		{
			id = "general_volunteer",
			title = "Volunteer Day",
			emoji = "🤝",
			text = "Your company sponsors a volunteer event at a local shelter.",
			question = "Do you sign up?",
			choices = {
				{ text = "Absolutely", deltas = { Happiness = 4 }, feed = "volunteered at a community shelter." },
				{ text = "Skip it", deltas = { Happiness = -1 }, feed = "skipped volunteer day to rest." },
			},
		},
	},
}

local function flattenEventPools(triggers)
	local pool = {}
	for _, trigger in ipairs(triggers) do
		local bucket = EventCatalog[trigger]
		if bucket then
			for _, item in ipairs(bucket) do
				table.insert(pool, item)
			end
		end
	end
	if #pool == 0 then
		for _, item in ipairs(EventCatalog.general) do
			table.insert(pool, item)
		end
	end
	return pool
end

-- ============================================================================
-- LifeBackend object construction
-- ============================================================================

function LifeBackend.new()
	local self = setmetatable({}, LifeBackend)
	self.playerStates = {}
	self.pendingEvents = {}
	self.remoteFolder = nil
	self.remotes = {}
	return self
end

-- Remote creation helpers ----------------------------------------------------

function LifeBackend:createRemote(name, className)
	local remote = self.remoteFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = self.remoteFolder
	end
	return remote
end

function LifeBackend:setupRemotes()
	self.remoteFolder = ReplicatedStorage:FindFirstChild("LifeRemotes")
	if not self.remoteFolder then
		self.remoteFolder = Instance.new("Folder")
		self.remoteFolder.Name = "LifeRemotes"
		self.remoteFolder.Parent = ReplicatedStorage
	end

	self.remotes.RequestAgeUp = self:createRemote("RequestAgeUp", "RemoteEvent")
	self.remotes.SyncState = self:createRemote("SyncState", "RemoteEvent")
	self.remotes.PresentEvent = self:createRemote("PresentEvent", "RemoteEvent")
	self.remotes.SubmitChoice = self:createRemote("SubmitChoice", "RemoteEvent")
	self.remotes.SetLifeInfo = self:createRemote("SetLifeInfo", "RemoteEvent")
	self.remotes.MinigameResult = self:createRemote("MinigameResult", "RemoteEvent")
	self.remotes.MinigameStart = self:createRemote("MinigameStart", "RemoteEvent")

	self.remotes.DoActivity = self:createRemote("DoActivity", "RemoteFunction")
	self.remotes.CommitCrime = self:createRemote("CommitCrime", "RemoteFunction")
	self.remotes.DoPrisonAction = self:createRemote("DoPrisonAction", "RemoteFunction")

	self.remotes.ApplyForJob = self:createRemote("ApplyForJob", "RemoteFunction")
	self.remotes.QuitJob = self:createRemote("QuitJob", "RemoteFunction")
	self.remotes.DoWork = self:createRemote("DoWork", "RemoteFunction")
	self.remotes.RequestPromotion = self:createRemote("RequestPromotion", "RemoteFunction")
	self.remotes.RequestRaise = self:createRemote("RequestRaise", "RemoteFunction")
	self.remotes.GetCareerInfo = self:createRemote("GetCareerInfo", "RemoteFunction")
	self.remotes.GetJobEligibility = self:createRemote("GetJobEligibility", "RemoteFunction") -- CRITICAL FIX #338: Check job qualifications
	self.remotes.GetEducationInfo = self:createRemote("GetEducationInfo", "RemoteFunction")
	self.remotes.EnrollEducation = self:createRemote("EnrollEducation", "RemoteFunction")

	self.remotes.BuyProperty = self:createRemote("BuyProperty", "RemoteFunction")
	self.remotes.BuyVehicle = self:createRemote("BuyVehicle", "RemoteFunction")
	self.remotes.BuyItem = self:createRemote("BuyItem", "RemoteFunction")
	self.remotes.SellAsset = self:createRemote("SellAsset", "RemoteFunction")
	-- REMOVED: Gambling remote (against Roblox TOS)
	-- self.remotes.Gamble = self:createRemote("Gamble", "RemoteFunction")

	self.remotes.DoInteraction = self:createRemote("DoInteraction", "RemoteFunction")

	self.remotes.StartPath = self:createRemote("StartPath", "RemoteFunction")
	self.remotes.DoPathAction = self:createRemote("DoPathAction", "RemoteFunction")
	self.remotes.ResetLife = self:createRemote("ResetLife", "RemoteEvent")
	
	-- PREMIUM FEATURES: Organized Crime remotes
	self.remotes.JoinMob = self:createRemote("JoinMob", "RemoteFunction")
	self.remotes.LeaveMob = self:createRemote("LeaveMob", "RemoteFunction")
	self.remotes.DoMobOperation = self:createRemote("DoMobOperation", "RemoteFunction")
	self.remotes.CheckGamepass = self:createRemote("CheckGamepass", "RemoteFunction")
	self.remotes.PromptGamepass = self:createRemote("PromptGamepass", "RemoteEvent")
	self.remotes.PromptProduct = self:createRemote("PromptProduct", "RemoteEvent")  -- CRITICAL FIX #358: Developer product purchases
	self.remotes.GamepassPurchased = self:createRemote("GamepassPurchased", "RemoteEvent")  -- CRITICAL FIX #359: Notify client of purchase
	self.remotes.UseTimeMachine = self:createRemote("UseTimeMachine", "RemoteFunction")
	self.remotes.GodModeEdit = self:createRemote("GodModeEdit", "RemoteFunction")
	-- CRITICAL FIX #60: Add remote to get God Mode configuration (presets, editable stats)
	self.remotes.GetGodModeInfo = self:createRemote("GetGodModeInfo", "RemoteFunction")
	
	-- CRITICAL FIX #13: PREMIUM FEATURES: Royalty remotes
	self.remotes.DoRoyalDuty = self:createRemote("DoRoyalDuty", "RemoteFunction")
	self.remotes.Abdicate = self:createRemote("Abdicate", "RemoteFunction")
	self.remotes.GetRoyalInfo = self:createRemote("GetRoyalInfo", "RemoteFunction")

	-- Event connections
	self.remotes.RequestAgeUp.OnServerEvent:Connect(function(player)
		self:handleAgeUp(player)
	end)

	self.remotes.SetLifeInfo.OnServerEvent:Connect(function(player, name, gender)
		self:setLifeInfo(player, name, gender)
	end)

	self.remotes.SubmitChoice.OnServerEvent:Connect(function(player, eventId, choiceIndex)
		self:resolvePendingEvent(player, eventId, choiceIndex)
	end)

	self.remotes.MinigameResult.OnServerEvent:Connect(function(player, won, payload)
		self:handleMinigameResult(player, won, payload)
	end)

	self.remotes.DoActivity.OnServerInvoke = function(player, activityId, bonus)
		return self:handleActivity(player, activityId, bonus)
	end
	self.remotes.CommitCrime.OnServerInvoke = function(player, crimeId, minigameBonus)
		return self:handleCrime(player, crimeId, minigameBonus)
	end
	self.remotes.DoPrisonAction.OnServerInvoke = function(player, actionId)
		return self:handlePrisonAction(player, actionId)
	end

	self.remotes.ApplyForJob.OnServerInvoke = function(player, jobId)
		return self:handleJobApplication(player, jobId)
	end
	self.remotes.QuitJob.OnServerInvoke = function(player, quitStyle)
		return self:handleQuitJob(player, quitStyle)
	end
	self.remotes.DoWork.OnServerInvoke = function(player)
		return self:handleWork(player)
	end
	self.remotes.RequestPromotion.OnServerInvoke = function(player)
		return self:handlePromotion(player)
	end
	self.remotes.RequestRaise.OnServerInvoke = function(player)
		return self:handleRaise(player)
	end
	self.remotes.GetCareerInfo.OnServerInvoke = function(player)
		return self:getCareerInfo(player)
	end
	
	-- CRITICAL FIX #338: Check job eligibility (education, experience, stats)
	self.remotes.GetJobEligibility.OnServerInvoke = function(player)
		return self:getJobEligibility(player)
	end

	self.remotes.GetEducationInfo.OnServerInvoke = function(player)
		return self:getEducationInfo(player)
	end
	self.remotes.EnrollEducation.OnServerInvoke = function(player, programId)
		return self:enrollEducation(player, programId)
	end

	self.remotes.BuyProperty.OnServerInvoke = function(player, assetId)
		return self:handleAssetPurchase(player, "Properties", Properties, assetId)
	end
	self.remotes.BuyVehicle.OnServerInvoke = function(player, assetId)
		return self:handleAssetPurchase(player, "Vehicles", Vehicles, assetId)
	end
	self.remotes.BuyItem.OnServerInvoke = function(player, assetId)
		return self:handleAssetPurchase(player, "Items", ShopItems, assetId)
	end
	self.remotes.SellAsset.OnServerInvoke = function(player, assetId, assetType)
		return self:handleAssetSale(player, assetId, assetType)
	end
	-- REMOVED: Gambling handler (against Roblox TOS)
	-- Gambling features have been removed to comply with Roblox Terms of Service

	self.remotes.DoInteraction.OnServerInvoke = function(player, payload)
		return self:handleInteraction(player, payload)
	end

	self.remotes.StartPath.OnServerInvoke = function(player, pathId)
		return self:startStoryPath(player, pathId)
	end
	self.remotes.DoPathAction.OnServerInvoke = function(player, pathId, actionId)
		return self:performPathAction(player, pathId, actionId)
	end

	self.remotes.ResetLife.OnServerEvent:Connect(function(player)
		self:resetLife(player)
	end)
	
	-- PREMIUM FEATURES: Organized Crime handlers
	self.remotes.JoinMob.OnServerInvoke = function(player, familyId)
		return self:handleJoinMob(player, familyId)
	end
	
	self.remotes.LeaveMob.OnServerInvoke = function(player)
		return self:handleLeaveMob(player)
	end
	
	self.remotes.DoMobOperation.OnServerInvoke = function(player, operationId)
		return self:handleMobOperation(player, operationId)
	end
	
	self.remotes.CheckGamepass.OnServerInvoke = function(player, gamepassKey)
		return self:checkGamepassOwnership(player, gamepassKey)
	end
	
	self.remotes.PromptGamepass.OnServerEvent:Connect(function(player, gamepassKey)
		self:promptGamepassPurchase(player, gamepassKey)
	end)
	
	-- CRITICAL FIX #358: Developer Product purchase handler
	self.remotes.PromptProduct.OnServerEvent:Connect(function(player, productKey)
		self:promptProductPurchase(player, productKey)
	end)
	
	self.remotes.UseTimeMachine.OnServerInvoke = function(player, yearsBack)
		return self:handleTimeMachine(player, yearsBack)
	end
	
	-- CRITICAL FIX #360: Set up ProcessReceipt for Developer Products (Time Machine)
	self:setupProcessReceipt()
	
	-- CRITICAL FIX #361: Set up gamepass purchase listener for UI refresh
	self:setupGamepassPurchaseListener()

	self.remotes.GodModeEdit.OnServerInvoke = function(player, payload)
		return self:handleGodModeEdit(player, payload)
	end
	
	-- CRITICAL FIX #60: Handler to get God Mode configuration for client UI
	self.remotes.GetGodModeInfo.OnServerInvoke = function(player)
		return self:getGodModeInfo(player)
	end
	
	-- CRITICAL FIX #13: PREMIUM FEATURES: Royalty handlers
	self.remotes.DoRoyalDuty.OnServerInvoke = function(player, dutyId)
		return self:handleRoyalDuty(player, dutyId)
	end
	
	self.remotes.Abdicate.OnServerInvoke = function(player)
		return self:handleAbdication(player)
	end
	
	self.remotes.GetRoyalInfo.OnServerInvoke = function(player)
		return self:getRoyalInfo(player)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #13: ROYALTY SYSTEM HANDLERS
-- ════════════════════════════════════════════════════════════════════════════

function LifeBackend:handleRoyalDuty(player, dutyId)
	if not self:checkGamepassOwnership(player, "ROYALTY") then
		self:promptGamepassPurchase(player, "ROYALTY")
		return { success = false, message = "👑 Royal duties require the Royalty gamepass.", needsGamepass = true }
	end
	
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end
	
	if not state.RoyalState or not state.RoyalState.isRoyal then
		return { success = false, message = "You're not royalty!" }
	end
	
	-- Find the duty
	local duties = {
		state_visit = { name = "State Visit", emoji = "🤝", popularity = { 2, 8 }, cost = 50000, minAge = 18 },
		ribbon_cutting = { name = "Ribbon Cutting Ceremony", emoji = "✂️", popularity = { 1, 5 }, cost = 5000, minAge = 10 },
		charity_gala = { name = "Host Charity Gala", emoji = "🎭", popularity = { 3, 10 }, cost = 100000, minAge = 18 },
		military_parade = { name = "Attend Military Parade", emoji = "🎖️", popularity = { 2, 6 }, cost = 10000, minAge = 16 },
		parliament_opening = { name = "State Opening of Parliament", emoji = "🏛️", popularity = { 1, 5 }, cost = 25000, minAge = 21, requiresMonarch = true },
		hospital_visit = { name = "Hospital Visit", emoji = "🏥", popularity = { 3, 8 }, cost = 2000, minAge = 8 },
		school_visit = { name = "School Visit", emoji = "🏫", popularity = { 2, 6 }, cost = 3000, minAge = 12 },
		knighting_ceremony = { name = "Knighting Ceremony", emoji = "⚔️", popularity = { 2, 5 }, cost = 15000, minAge = 21, requiresMonarch = true },
		environmental_campaign = { name = "Environmental Campaign", emoji = "🌍", popularity = { 2, 7 }, cost = 200000, minAge = 18 },
		sports_event = { name = "Sports Event Appearance", emoji = "🏆", popularity = { 2, 5 }, cost = 10000, minAge = 12 },
		arts_patronage = { name = "Arts Patronage Event", emoji = "🎨", popularity = { 1, 4 }, cost = 25000, minAge = 16 },
		disaster_relief = { name = "Disaster Relief Visit", emoji = "🆘", popularity = { 5, 15 }, cost = 10000, minAge = 16 },
	}
	
	local duty = duties[dutyId]
	if not duty then
		return { success = false, message = "Unknown duty." }
	end
	
	-- CRITICAL FIX #145: Nil safety for duty minAge
	local requiredAge = duty.minAge or 0
	if (state.Age or 0) < requiredAge then
		return { success = false, message = "You must be at least " .. requiredAge .. " to perform this duty." }
	end
	
	-- CRITICAL FIX #146: Nil safety for RoyalState access
	state.RoyalState = state.RoyalState or {}
	if duty.requiresMonarch and not state.RoyalState.isMonarch then
		return { success = false, message = "Only the monarch can perform this duty." }
	end
	
	-- CRITICAL FIX #147: Nil safety for Money and duty cost
	local dutyCost = duty.cost or 0
	if (state.Money or 0) < dutyCost then
		return { success = false, message = "Not enough funds for this duty. Required: $" .. formatMoney(dutyCost) }
	end
	
	-- Deduct cost
	state.Money = (state.Money or 0) - dutyCost
	
	-- CRITICAL FIX #148: Nil safety for popularity range
	local popMin = (duty.popularity and duty.popularity[1]) or 1
	local popMax = (duty.popularity and duty.popularity[2]) or 10
	local popGain = RANDOM:NextInteger(popMin, popMax)
	state.RoyalState.popularity = math.min(100, (state.RoyalState.popularity or 50) + popGain)
	state.RoyalState.dutiesCompleted = (state.RoyalState.dutiesCompleted or 0) + 1
	state.RoyalState.dutyStreak = (state.RoyalState.dutyStreak or 0) + 1
	
	-- Streak bonus
	if state.RoyalState.dutyStreak >= 5 then
		state.RoyalState.popularity = math.min(100, state.RoyalState.popularity + 5)
		popGain = popGain + 5
	end
	
	local message = string.format("%s Completed: %s (+%d popularity)", duty.emoji, duty.name, popGain)
	appendFeed(state, message)
	self:pushState(player, message)
	
	return { 
		success = true, 
		message = message,
		popularityGain = popGain,
		currentPopularity = state.RoyalState.popularity,
	}
end

function LifeBackend:handleAbdication(player)
	if not self:checkGamepassOwnership(player, "ROYALTY") then
		return { success = false, message = "👑 Abdication requires the Royalty gamepass.", needsGamepass = true }
	end
	
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end
	
	if not state.RoyalState or not state.RoyalState.isRoyal then
		return { success = false, message = "You're not royalty!" }
	end
	
	if not state.RoyalState.isMonarch then
		return { success = false, message = "Only the monarch can abdicate. You're still " .. (state.RoyalState.title or "an heir") .. "." }
	end
	
	-- Abdicate
	state.RoyalState.isMonarch = false
	state.RoyalState.popularity = math.max(0, state.RoyalState.popularity - 30)
	
	state.Flags.abdicated = true
	state.Flags.is_monarch = nil
	state.Flags.former_monarch = true
	
	local message = "👑 You have abdicated the throne! The nation is shocked."
	appendFeed(state, message)
	self:pushState(player, message)
	
	return { success = true, message = message }
end

function LifeBackend:getRoyalInfo(player)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end
	
	local hasRoyalty = self:checkGamepassOwnership(player, "ROYALTY")
	
	if not state.RoyalState or not state.RoyalState.isRoyal then
		return {
			success = true,
			isRoyal = false,
			hasGamepass = hasRoyalty,
		}
	end
	
	return {
		success = true,
		isRoyal = true,
		hasGamepass = hasRoyalty,
		royalState = state.RoyalState,
	}
end

function LifeBackend:createInitialState(player)
	local state = LifeState.new(player)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #11: BITIZENSHIP BENEFITS
	-- Players with Bitizenship get bonus starting money and special flags
	-- ═══════════════════════════════════════════════════════════════════════════════
	local hasBitizenship = self:checkGamepassOwnership(player, "BITIZENSHIP")
	if hasBitizenship then
		state.Money = (state.Money or 0) + 10000 -- Start with $10k bonus
		state.Flags = state.Flags or {}
		state.Flags.bitizen = true
		state.Flags.premium_player = true
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #4: Set ALL gamepass ownership flags on character creation
	-- Without this, premium events check flags that are NEVER set!
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.Flags = state.Flags or {}
	state.GamepassOwnership = state.GamepassOwnership or {}
	
	-- Check and set ALL premium gamepass flags
	local hasRoyalty = self:checkGamepassOwnership(player, "ROYALTY")
	if hasRoyalty then
		state.Flags.royalty_gamepass = true
		state.GamepassOwnership.royalty = true
	end
	
	local hasMafia = self:checkGamepassOwnership(player, "MAFIA")
	if hasMafia then
		state.Flags.mafia_gamepass = true  -- CRITICAL FIX #9: This flag was NEVER set!
		state.GamepassOwnership.mafia = true
	end
	
	local hasCelebrity = self:checkGamepassOwnership(player, "CELEBRITY")
	if hasCelebrity then
		state.Flags.celebrity_gamepass = true
		state.GamepassOwnership.celebrity = true
	end
	
	local hasGodMode = self:checkGamepassOwnership(player, "GOD_MODE")
	if hasGodMode then
		state.Flags.god_mode_gamepass = true
		state.GamepassOwnership.godMode = true
		-- CRITICAL FIX #6: God Mode enables stat editing UI, not events
		state.GodModeState = state.GodModeState or {}
		state.GodModeState.enabled = true
	end
	
	local hasTimeMachine = self:checkGamepassOwnership(player, "TIME_MACHINE")
	if hasTimeMachine then
		state.Flags.time_machine_gamepass = true
		state.GamepassOwnership.timeMachine = true
	end
	
	local hasBossMode = self:checkGamepassOwnership(player, "BOSS_MODE")
	if hasBossMode then
		state.Flags.boss_mode_gamepass = true
		state.GamepassOwnership.bossMode = true
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- SERVER-SIDE FAMILY CREATION
	-- Create proper family members so they're part of authoritative state
	-- This prevents the "disappearing family" bug where client-generated defaults
	-- would conflict with server state after interactions.
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	state.Relationships = state.Relationships or {}
	
	-- Generate random names for family members (EXPANDED - 80+ names each for variety)
	local maleNames = {
		-- Classic names
		"James", "Michael", "David", "John", "Robert", "William", "Richard", "Thomas", "Charles", "Daniel",
		"Christopher", "Matthew", "Anthony", "Mark", "Steven", "Andrew", "Joshua", "Kevin", "Brian", "Ryan",
		-- Modern names
		"Liam", "Noah", "Oliver", "Ethan", "Aiden", "Lucas", "Mason", "Logan", "Alexander", "Sebastian",
		"Benjamin", "Henry", "Owen", "Jack", "Carter", "Jayden", "Dylan", "Wyatt", "Luke", "Caleb",
		-- Diverse cultural names
		"Diego", "Carlos", "Miguel", "Rafael", "Alejandro", "Juan", "Marco", "Antonio", "Luis", "Eduardo",
		"Jamal", "Darius", "Malik", "Terrence", "Andre", "DeShawn", "Marcus", "Dante", "Isaiah", "Brandon",
		"Hiroshi", "Takeshi", "Kenji", "Yuki", "Ryu", "Akira", "Kazuki", "Ren", "Sora", "Haruki",
		"Raj", "Arjun", "Vikram", "Rahul", "Amir", "Omar", "Hassan", "Khalid", "Zaid", "Tariq"
	}
	local femaleNames = {
		-- Classic names
		"Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Susan", "Jessica", "Sarah", "Karen",
		"Nancy", "Lisa", "Betty", "Margaret", "Dorothy", "Sandra", "Ashley", "Kimberly", "Donna", "Emily",
		-- Modern names
		"Emma", "Olivia", "Ava", "Isabella", "Sophia", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn",
		"Abigail", "Luna", "Ella", "Scarlett", "Grace", "Chloe", "Victoria", "Aria", "Lily", "Zoey",
		-- Diverse cultural names
		"Maria", "Carmen", "Valentina", "Lucia", "Ana", "Rosa", "Elena", "Gabriela", "Natalia", "Sofia",
		"Aaliyah", "Destiny", "Diamond", "Jasmine", "Imani", "Tiana", "Sierra", "Layla", "Aisha", "Zoe",
		"Sakura", "Yuki", "Mei", "Hana", "Aiko", "Rin", "Mika", "Kaori", "Nanami", "Koharu",
		"Priya", "Ananya", "Isha", "Fatima", "Zahra", "Leila", "Nadia", "Sara", "Amira", "Yasmin"
	}
	
	local function randomName(gender)
		local names = (gender == "male") and maleNames or femaleNames
		return names[RANDOM:NextInteger(1, #names)]
	end
	
	-- Mother (always created)
	local motherAge = 22 + RANDOM:NextInteger(0, 8) -- Mom is 22-30 years older
	state.Relationships["mother"] = {
		id = "mother",
		name = randomName("female"),
		type = "family",
		role = "Mother",
		relationship = 75 + RANDOM:NextInteger(-10, 15),
		age = motherAge,
		gender = "female",
		alive = true,
		isFamily = true,
	}
	
	-- Father (always created)
	local fatherAge = 24 + RANDOM:NextInteger(0, 10) -- Dad is 24-34 years older
	state.Relationships["father"] = {
		id = "father",
		name = randomName("male"),
		type = "family",
		role = "Father",
		relationship = 70 + RANDOM:NextInteger(-10, 15),
		age = fatherAge,
		gender = "male",
		alive = true,
		isFamily = true,
	}
	
	-- Grandparents (50% chance each)
	if RANDOM:NextNumber() > 0.5 then
		local grandmaAge = motherAge + 22 + RANDOM:NextInteger(0, 8)
		state.Relationships["grandmother_maternal"] = {
			id = "grandmother_maternal",
			name = randomName("female"),
			type = "family",
			role = "Grandmother",
			relationship = 65 + RANDOM:NextInteger(-5, 10),
			age = grandmaAge,
			gender = "female",
			alive = grandmaAge < 85,
			isFamily = true,
		}
	end
	
	if RANDOM:NextNumber() > 0.5 then
		local grandpaAge = fatherAge + 24 + RANDOM:NextInteger(0, 10)
		state.Relationships["grandfather_paternal"] = {
			id = "grandfather_paternal",
			name = randomName("male"),
			type = "family",
			role = "Grandfather",
			relationship = 60 + RANDOM:NextInteger(-5, 10),
			age = grandpaAge,
			gender = "male",
			alive = grandpaAge < 82,
			isFamily = true,
		}
	end
	
	-- Siblings (random chance)
	-- CRITICAL FIX #128: Improved sibling relationship generation with proper age handling
	local numSiblings = RANDOM:NextInteger(0, 3)
	for i = 1, numSiblings do
		local isBrother = RANDOM:NextNumber() > 0.5
		local siblingAgeOffset = RANDOM:NextInteger(-5, 8) -- Can be older or younger
		local siblingId = (isBrother and "brother_" or "sister_") .. tostring(i)
		
		-- CRITICAL FIX #129: Determine role based on age offset
		local siblingRole
		if siblingAgeOffset > 0 then
			siblingRole = isBrother and "Older Brother" or "Older Sister"
		elseif siblingAgeOffset < 0 then
			siblingRole = isBrother and "Younger Brother" or "Younger Sister"
		else
			siblingRole = isBrother and "Twin Brother" or "Twin Sister"
		end
		
		-- CRITICAL FIX #130: Store actual sibling age (based on player age 0 at birth)
		-- Older siblings have positive offset, younger have negative (born later)
		local siblingAbsoluteAge = math.max(0, siblingAgeOffset) -- At player's birth, older siblings already exist
		
		state.Relationships[siblingId] = {
			id = siblingId,
			name = randomName(isBrother and "male" or "female"),
			type = "family",
			role = siblingRole,
			relationship = 55 + RANDOM:NextInteger(-10, 20),
			age = siblingAbsoluteAge,
			gender = isBrother and "male" or "female",
			alive = true,
			isFamily = true,
			ageOffset = siblingAgeOffset, -- Store the offset for updating later
			birthOrder = siblingAgeOffset > 0 and "older" or (siblingAgeOffset < 0 and "younger" or "twin"),
		}
	end
	
	-- CRITICAL FIX: Ensure Assets table is properly initialized
	-- This prevents the "state.Assets is NIL" error on client
	state.Assets = state.Assets or {}
	state.Assets.Properties = state.Assets.Properties or {}
	state.Assets.Vehicles = state.Assets.Vehicles or {}
	state.Assets.Items = state.Assets.Items or {}
	state.Assets.Crypto = state.Assets.Crypto or {}
	state.Assets.Investments = state.Assets.Investments or {}
	state.Assets.Businesses = state.Assets.Businesses or {}
	
	debugPrint(string.format("Created initial state for %s with %d family members", 
		player.Name, countEntries(state.Relationships)))
	debugPrint("  Assets initialized:", state.Assets ~= nil)
	
	return state
end

function LifeBackend:getState(player)
	return self.playerStates[player]
end

function LifeBackend:serializeState(state)
	local serialized
	
	if state and state.Serialize then
		serialized = state:Serialize()
		serialized.PendingFeed = nil
		serialized.lastFeed = nil
	else
		serialized = deepCopy(state)
		if serialized then
			serialized.PendingFeed = nil
			serialized.lastFeed = nil
		end
	end
	
	-- CRITICAL FIX: Always ensure Assets is properly structured in serialized output
	-- This fixes the "state.Assets is NIL" error on client
	if serialized then
		serialized.Assets = serialized.Assets or {}
		serialized.Assets.Properties = serialized.Assets.Properties or {}
		serialized.Assets.Vehicles = serialized.Assets.Vehicles or {}
		serialized.Assets.Items = serialized.Assets.Items or {}
		serialized.Assets.Crypto = serialized.Assets.Crypto or {}
		serialized.Assets.Investments = serialized.Assets.Investments or {}
		serialized.Assets.Businesses = serialized.Assets.Businesses or {}
		
		-- Debug: Trace what's being serialized
		debugPrint("[serializeState] Assets in serialized state:")
		debugPrint("  Properties:", #serialized.Assets.Properties)
		debugPrint("  Vehicles:", #serialized.Assets.Vehicles)
		debugPrint("  Items:", #serialized.Assets.Items)

		-- ═══════════════════════════════════════════════════════════════════════════════
		-- PREMIUM FEATURE SERIALIZATION - CRITICAL FIX #21
		-- Ensure all premium states are properly serialized for client
		-- ═══════════════════════════════════════════════════════════════════════════════
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #257: Sync MobState.inMob and Flags.in_mob before serialization
		-- This ensures the client always has consistent data about mob membership
		-- Without this, activities show "don't meet requirements" even when in mob
		-- ═══════════════════════════════════════════════════════════════════════════════
		if state.MobState and state.MobState.inMob then
			state.Flags = state.Flags or {}
			state.Flags.in_mob = true
			state.Flags.mafia_member = true
		elseif state.Flags and state.Flags.in_mob then
			-- Flag says in mob but MobState doesn't - restore MobState
			state.MobState = state.MobState or {}
			if not state.MobState.inMob then
				state.MobState.inMob = true
				state.MobState.rankIndex = state.MobState.rankIndex or 1
				state.MobState.rankLevel = state.MobState.rankLevel or 1
				state.MobState.respect = state.MobState.respect or 0
				state.MobState.loyalty = state.MobState.loyalty or 50
				state.MobState.heat = state.MobState.heat or 0
			end
		end
		
		-- MAFIA STATE
		serialized.MobState = MafiaSystem:serialize(state)
		
		-- CRITICAL FIX #258: Also sync the serialized Flags to include in_mob
		serialized.Flags = serialized.Flags or {}
		if serialized.MobState and serialized.MobState.inMob then
			serialized.Flags.in_mob = true
			serialized.Flags.mafia_member = true
		end
		
		-- ROYALTY STATE
		if state.RoyalState and state.RoyalState.isRoyal then
			serialized.RoyalState = state.RoyalState
		else
			serialized.RoyalState = { isRoyal = false }
		end
		
		-- CELEBRITY/FAME STATE
		-- CRITICAL FIX #USER-31: ALWAYS include full FameState to preserve stats!
		-- Previously only included if careerPath was set, causing stats to be lost
		if state.FameState then
			-- Always pass the full FameState so all stats are preserved
			serialized.FameState = state.FameState
			-- Ensure the fame value is synced
			serialized.FameState.fame = state.Fame or serialized.FameState.fame or 0
		else
			-- Fallback minimal state
			serialized.FameState = { 
				isFamous = false, 
				fame = state.Fame or 0,
				-- Include zeroed stats so client doesn't error
				monthlyListeners = 0,
				totalStreams = 0,
				totalTracks = 0,
				subscribers = 0,
				totalViews = 0,
				totalVideos = 0,
				followers = 0,
				totalPosts = 0,
				totalLikes = 0,
			}
		end
		
		-- GOD MODE STATE
		if state.GodModeState then
			serialized.GodModeState = state.GodModeState
		else
			serialized.GodModeState = { enabled = false }
		end
		
		-- GAMEPASS OWNERSHIP
		serialized.GamepassOwnership = state.GamepassOwnership or {}
	end
	
	return serialized
end

function LifeBackend:pushState(player, feedText, resultData)
	local state = self.playerStates[player]
	if not state then
		return
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #21: Always sync stats before pushing to client
	-- This ensures state.Health == state.Stats.Health, etc.
	-- Without this, client can show different values than server intended
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.Stats = state.Stats or {}
	state.Health = state.Stats.Health or state.Health or 50
	state.Happiness = state.Stats.Happiness or state.Happiness or 50
	state.Smarts = state.Stats.Smarts or state.Smarts or 50
	state.Looks = state.Stats.Looks or state.Looks or 50
	
	-- Also sync Stats from top-level in case they were set directly
	state.Stats.Health = state.Health
	state.Stats.Happiness = state.Happiness
	state.Stats.Smarts = state.Smarts
	state.Stats.Looks = state.Looks
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #22: Ensure employment flags match CurrentJob state
	-- This prevents the "job shows but Work says no job" bug
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.Flags = state.Flags or {}
	if state.CurrentJob and state.CurrentJob.id then
		state.Flags.employed = true
		state.Flags.has_job = true
	else
		state.Flags.employed = nil
		state.Flags.has_job = nil
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #23: Ensure prison flags match InJail state
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.InJail then
		state.Flags.in_prison = true
		state.Flags.incarcerated = true
	else
		state.Flags.in_prison = nil
		state.Flags.incarcerated = nil
	end
	
	state.lastFeed = feedText or state.lastFeed
	self.remotes.SyncState:FireClient(player, self:serializeState(state), feedText, resultData)
end

function LifeBackend:applyStatChanges(state, deltas)
	if not deltas then
		return
	end
	state.Stats = state.Stats or {}
	for stat, delta in pairs(deltas) do
		if stat == "Money" or stat == "money" then
			state.Money = math.max(0, (state.Money or 0) + delta)
		elseif stat == "Health" or stat == "H" then
			state.Stats.Health = clamp((state.Stats.Health or 0) + delta)
			state.Health = state.Stats.Health
		elseif stat == "Happiness" or stat == "Happy" then
			state.Stats.Happiness = clamp((state.Stats.Happiness or 0) + delta)
			state.Happiness = state.Stats.Happiness
		elseif stat == "Smarts" then
			state.Stats.Smarts = clamp((state.Stats.Smarts or 0) + delta)
			state.Smarts = state.Stats.Smarts
		elseif stat == "Looks" then
			state.Stats.Looks = clamp((state.Stats.Looks or 0) + delta)
			state.Looks = state.Stats.Looks
		end
	end
end

-- CRITICAL FIX #9: Safe money operation that prevents negative values
function LifeBackend:addMoney(state, amount)
	if not amount or type(amount) ~= "number" then
		return -- Invalid amount
	end
	
	local currentMoney = state.Money or 0
	if type(currentMoney) ~= "number" then
		currentMoney = 0
	end
	
	-- CRITICAL FIX #9: Prevent negative money values
	local newMoney = currentMoney + amount
	state.Money = math.max(0, math.floor(newMoney)) -- Also ensure integer value
	
	-- CRITICAL FIX #9B: Cap maximum money to prevent overflow issues
	local MAX_MONEY = 999999999999 -- ~1 trillion
	state.Money = math.min(state.Money, MAX_MONEY)
end

-- ============================================================================
-- Player lifecycle
-- ============================================================================

function LifeBackend:onPlayerAdded(player)
	-- CRITICAL FIX #10: Initialize gamepass ownership FIRST before creating state
	-- This ensures ownership is properly cached before any gamepass checks happen
	if GamepassSystem and GamepassSystem.initializePlayerOwnership then
		GamepassSystem:initializePlayerOwnership(player)
	end

	-- ════════════════════════════════════════════════════════════════════════════════
	-- CRITICAL: TRY TO LOAD SAVED DATA FIRST
	-- If player has saved progress, restore it instead of creating new state
	-- ════════════════════════════════════════════════════════════════════════════════
	local savedData = self:loadPlayerData(player)
	local state

	if savedData and savedData.Age and savedData.Age > 0 and savedData.Name then
		-- Player has saved data - restore their progress!
		print("[LifeBackend] 🔄 Restoring saved progress for", player.Name, "- Name:", savedData.Name, "Age:", savedData.Age)

		-- Create base state structure
		state = self:createInitialState(player)

		-- CRITICAL: Restore core identity FIRST
		state.Name = savedData.Name  -- Full name like "John Smith"
		state.Gender = savedData.Gender or state.Gender
		state.Age = savedData.Age
		state.Money = savedData.Money or state.Money
		state.Fame = savedData.Fame or state.Fame
		state.Karma = savedData.Karma or state.Karma
		state.Country = savedData.Country or state.Country
		state.City = savedData.City or state.City
		state.BirthYear = savedData.BirthYear or state.BirthYear

		-- Restore stats
		if savedData.Stats then
			state.Stats = state.Stats or {}
			state.Stats.Health = savedData.Stats.Health or state.Stats.Health
			state.Stats.Happiness = savedData.Stats.Happiness or state.Stats.Happiness
			state.Stats.Smarts = savedData.Stats.Smarts or state.Stats.Smarts
			state.Stats.Looks = savedData.Stats.Looks or state.Stats.Looks
			-- Also sync top-level stats (some code uses state.Health directly)
			state.Health = state.Stats.Health
			state.Happiness = state.Stats.Happiness
			state.Smarts = state.Stats.Smarts
			state.Looks = state.Stats.Looks
		end

		-- Restore flags (CRITICAL for story paths!)
		if savedData.Flags then
			state.Flags = state.Flags or {}
			for k, v in pairs(savedData.Flags) do
				state.Flags[k] = v
			end
		end

		-- Restore career
		if savedData.CurrentJob then
			state.CurrentJob = savedData.CurrentJob
		end
		if savedData.CareerInfo then
			state.CareerInfo = savedData.CareerInfo
		end

		-- Restore relationships
		if savedData.Relationships then
			state.Relationships = savedData.Relationships
		end

		-- Restore premium states
		if savedData.RoyalState then
			state.RoyalState = savedData.RoyalState
		end
		if savedData.MobState then
			state.MobState = savedData.MobState
		end
		if savedData.FameState then
			state.FameState = savedData.FameState
		end

		-- Restore gamepass ownership
		if savedData.GamepassOwnership then
			state.GamepassOwnership = savedData.GamepassOwnership
		end

		-- Restore education
		if savedData.Education then
			state.Education = savedData.Education
		end

		-- Restore assets
		if savedData.Assets then
			state.Assets = savedData.Assets
		end

		-- CRITICAL: Set flag to tell client to SKIP the intro (data was restored)
		state.Flags = state.Flags or {}
		state.Flags.data_restored = true
		state.Flags.intro_complete = true  -- Also set this to skip intro check

		print("[LifeBackend] ✅ Progress restored! Name:", state.Name, "Age:", state.Age, "Money: $" .. (state.Money or 0))
	else
		-- No saved data - create fresh state
		state = self:createInitialState(player)
		print("[LifeBackend] 🆕 New player - starting fresh life for", player.Name)
	end

	self.playerStates[player] = state

	-- CRITICAL FIX #10: Ensure GamepassOwnership is stored in state for persistence
	if state.GamepassOwnership then
		-- Also tell GamepassSystem about any restored ownership from DataStore
		if GamepassSystem and GamepassSystem.restoreOwnershipFromState then
			GamepassSystem:restoreOwnershipFromState(player, state.GamepassOwnership)
		end
	end

	-- CRITICAL FIX #500: DON'T push "A new life begins..." here!
	-- The setLifeInfo function will send the proper birth message.
	-- Sending a message here causes duplicate/overlapping messages at spawn.
	-- Only sync the initial state without a feed message.
	self:pushState(player, nil)
end

function LifeBackend:onPlayerRemoving(player)
	-- ════════════════════════════════════════════════════════════════════════════════
	-- CRITICAL: SAVE PLAYER DATA BEFORE THEY LEAVE
	-- This ensures progress is not lost when leaving/rejoining
	-- ════════════════════════════════════════════════════════════════════════════════
	print("[LifeBackend] 💾 Saving data for", player.Name, "before they leave...")
	self:savePlayerData(player)

	-- Now clear the state
	self.playerStates[player] = nil
	self.pendingEvents[player.UserId] = nil
end

-- CRITICAL FIX: Filter text using Roblox's TextService for custom names
local TextService = game:GetService("TextService")

-- CRITICAL FIX #325: Pre-approved safe names that bypass Roblox filter
-- These are the names we generate in the game, so they're guaranteed safe
local SAFE_FIRST_NAMES = {
	-- Male names
	["James"] = true, ["Michael"] = true, ["Daniel"] = true, ["Alexander"] = true,
	["Liam"] = true, ["Noah"] = true, ["Jackson"] = true, ["Elijah"] = true,
	["Logan"] = true, ["Wyatt"] = true, ["Kai"] = true, ["Rowan"] = true,
	["John"] = true, ["David"] = true, ["Chris"] = true, ["Matthew"] = true,
	["Andrew"] = true, ["Ryan"] = true, ["Tyler"] = true,
	-- Royal male names
	["William"] = true, ["Charles"] = true, ["Edward"] = true, ["Henry"] = true,
	["George"] = true, ["Frederick"] = true, ["Leopold"] = true, ["Albert"] = true,
	["Philip"] = true,
	-- Female names
	["Emma"] = true, ["Sophia"] = true, ["Olivia"] = true, ["Isabella"] = true,
	["Mia"] = true, ["Charlotte"] = true, ["Avery"] = true, ["Camila"] = true,
	["Scarlett"] = true, ["Chloe"] = true, ["Hazel"] = true, ["Naomi"] = true,
	["Emily"] = true, ["Sarah"] = true, ["Jessica"] = true, ["Ashley"] = true,
	["Samantha"] = true, ["Madison"] = true, ["Hannah"] = true,
	-- Royal female names
	["Victoria"] = true, ["Elizabeth"] = true, ["Catherine"] = true, ["Diana"] = true,
	["Margaret"] = true, ["Alexandra"] = true, ["Beatrice"] = true, ["Eugenie"] = true,
}

local SAFE_LAST_NAMES = {
	["Wilson"] = true, ["Brown"] = true, ["Johnson"] = true, ["Williams"] = true,
	["Taylor"] = true, ["Clark"] = true, ["Walker"] = true, ["King"] = true,
	["Adams"] = true, ["Carter"] = true, ["Parker"] = true, ["Reed"] = true,
	["Smith"] = true, ["Jones"] = true, ["Davis"] = true, ["Miller"] = true,
	["Anderson"] = true, ["Thomas"] = true, ["Moore"] = true, ["Martin"] = true,
}

-- Check if a name is from our safe list (first + last name format)
local function isSafeName(name)
	if not name or name == "" then return false end
	
	-- Split into parts
	local parts = {}
	for part in name:gmatch("%S+") do
		table.insert(parts, part)
	end
	
	-- Single name check
	if #parts == 1 then
		return SAFE_FIRST_NAMES[parts[1]] or SAFE_LAST_NAMES[parts[1]]
	end
	
	-- First + Last name check
	if #parts == 2 then
		return SAFE_FIRST_NAMES[parts[1]] and SAFE_LAST_NAMES[parts[2]]
	end
	
	-- First Middle Last check (allow if first and last are safe)
	if #parts >= 2 then
		return SAFE_FIRST_NAMES[parts[1]] and SAFE_LAST_NAMES[parts[#parts]]
	end
	
	return false
end

local function filterText(text, player)
	if not text or text == "" then return text end
	
	-- CRITICAL FIX #325: Skip filtering for pre-approved safe names
	-- This prevents Roblox from hashtagging our generated names
	if isSafeName(text) then
		return text
	end
	
	local success, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	if success then
		return result
	else
		-- If filtering fails, return a sanitized version
		return text:gsub("[^%w%s'-]", ""):sub(1, 30)
	end
end

function LifeBackend:setLifeInfo(player, nameOrPayload, genderArg)
	local state = self:getState(player)
	if not state then
		return
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #105: Support both old (name, gender) and new (payload object) formats
	-- New format: { gender = "Male", isRoyalBirth = true, royalCountry = "uk" }
	-- ═══════════════════════════════════════════════════════════════════════════════
	local name, gender, isRoyalBirth, royalCountry
	
	if type(nameOrPayload) == "table" then
		-- New payload format
		name = nameOrPayload.name
		gender = nameOrPayload.gender
		isRoyalBirth = nameOrPayload.isRoyalBirth
		royalCountry = nameOrPayload.royalCountry
	else
		-- Old format (name, gender)
		name = nameOrPayload
		gender = genderArg
	end
	
	-- CRITICAL FIX #104/#117: Handle empty name - generate random default name
	if name and name ~= "" and name:match("%S") then
		-- CRITICAL FIX: Apply Roblox text filtering to custom names
		local filteredName = filterText(name, player)
		state.Name = filteredName
	else
		-- Generate a default name if none provided
		local maleNames = {"James", "John", "Michael", "David", "Chris", "Matthew", "Daniel", "Andrew", "Ryan", "Tyler"}
		local femaleNames = {"Emily", "Sarah", "Jessica", "Ashley", "Samantha", "Madison", "Hannah", "Olivia", "Emma", "Sophia"}
		
		-- For royalty, use more regal names
		local royalMaleNames = {"William", "Charles", "Edward", "Henry", "George", "Alexander", "Frederick", "Leopold", "Albert", "Philip"}
		local royalFemaleNames = {"Victoria", "Elizabeth", "Catherine", "Charlotte", "Diana", "Margaret", "Alexandra", "Beatrice", "Eugenie", "Sophia"}
		
		local nameList
		if isRoyalBirth then
			nameList = (gender == "Female") and royalFemaleNames or royalMaleNames
		else
			nameList = (gender == "Female") and femaleNames or maleNames
		end
		state.Name = nameList[math.random(#nameList)]
	end
	
	if gender then
		state.Gender = gender
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #106: Handle royal birth from the "Born Royal" button
	-- This is separate from God Mode character customization
	-- ═══════════════════════════════════════════════════════════════════════════════
	if isRoyalBirth then
		-- Verify player has Royalty gamepass
		if self:checkGamepassOwnership(player, "ROYALTY") then
			local royalCountryId = royalCountry or "uk"
			local royalCountries = {
				uk = { id = "uk", name = "United Kingdom", emoji = "🇬🇧", palace = "Buckingham Palace", startingWealth = { min = 50000000, max = 500000000 } },
				spain = { id = "spain", name = "Spain", emoji = "🇪🇸", palace = "Royal Palace of Madrid", startingWealth = { min = 30000000, max = 200000000 } },
				sweden = { id = "sweden", name = "Sweden", emoji = "🇸🇪", palace = "Stockholm Palace", startingWealth = { min = 20000000, max = 150000000 } },
				japan = { id = "japan", name = "Japan", emoji = "🇯🇵", palace = "Imperial Palace", startingWealth = { min = 100000000, max = 800000000 } },
				monaco = { id = "monaco", name = "Monaco", emoji = "🇲🇨", palace = "Prince's Palace", startingWealth = { min = 200000000, max = 1000000000 } },
				saudi = { id = "saudi", name = "Saudi Arabia", emoji = "🇸🇦", palace = "Al-Yamamah Palace", startingWealth = { min = 500000000, max = 5000000000 } },
				belgium = { id = "belgium", name = "Belgium", emoji = "🇧🇪", palace = "Royal Palace of Brussels", startingWealth = { min = 25000000, max = 180000000 } },
				netherlands = { id = "netherlands", name = "Netherlands", emoji = "🇳🇱", palace = "Royal Palace Amsterdam", startingWealth = { min = 30000000, max = 200000000 } },
				norway = { id = "norway", name = "Norway", emoji = "🇳🇴", palace = "Royal Palace Oslo", startingWealth = { min = 25000000, max = 150000000 } },
				denmark = { id = "denmark", name = "Denmark", emoji = "🇩🇰", palace = "Amalienborg Palace", startingWealth = { min = 25000000, max = 150000000 } },
				morocco = { id = "morocco", name = "Morocco", emoji = "🇲🇦", palace = "Royal Palace of Rabat", startingWealth = { min = 80000000, max = 400000000 } },
				jordan = { id = "jordan", name = "Jordan", emoji = "🇯🇴", palace = "Al-Husseiniya Palace", startingWealth = { min = 50000000, max = 300000000 } },
				thailand = { id = "thailand", name = "Thailand", emoji = "🇹🇭", palace = "Grand Palace", startingWealth = { min = 100000000, max = 600000000 } },
			}
			
			local country = royalCountries[royalCountryId] or royalCountries.uk
			local wealthRange = country.startingWealth
			local royalWealth = RANDOM:NextInteger(wealthRange.min, wealthRange.max)
			
			-- Determine title based on gender
			local genderStr = state.Gender or "Male"
			local title = (genderStr == "Female") and "Princess" or "Prince"
			
			-- Initialize royal state
			state.RoyalState = {
				isRoyal = true,
				isMonarch = false,
				country = country.id,
				countryName = country.name,
				countryEmoji = country.emoji,
				palace = country.palace,
				title = title,
				lineOfSuccession = RANDOM:NextInteger(1, 5),
				popularity = 75 + RANDOM:NextInteger(-10, 10),
				scandals = 0,
				dutiesCompleted = 0,
				dutyStreak = 0,
				reignYears = 0,
				wealth = royalWealth,
			}
			
			-- Set money
			state.Money = royalWealth
			
			-- Set flags
			state.Flags = state.Flags or {}
			state.Flags.is_royalty = true
			state.Flags.royal_birth = true
			state.Flags.royal_country = country.id
			state.Flags.wealthy_family = true
			state.Flags.upper_class = true
			state.Flags.famous_family = true
			
			-- Send royal birth message
			self:pushState(player, string.format("👑 %s %s of %s takes their first breath in %s!", title, state.Name or "Your Highness", country.name, country.palace))
			return
		end
	end
	
	self:pushState(player, string.format("%s takes their first breath.", state.Name or "Your character"))
end

-- ============================================================================
-- Age Up & Events
-- ============================================================================

function LifeBackend:advanceRelationships(state)
	if not state.Relationships then
		return
	end
	
	-- CRITICAL FIX: Relationships degrade much faster while in jail!
	-- Prison isolates you from loved ones, causing relationships to suffer
	local isInJail = state.InJail
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Improved family death mechanics
	-- Realistic death chances based on age, not just >95
	-- Proper happiness impact and death notifications
	-- ═══════════════════════════════════════════════════════════════════════════════
	local familyDeaths = {}
	
	for relId, rel in pairs(state.Relationships) do
		if type(rel) == "table" and rel.alive ~= false then
			-- Normal fluctuation: -2 to +3
			-- Jail fluctuation: -8 to -2 (always negative, relationships decay)
			local change
			if isInJail then
				change = RANDOM:NextInteger(-8, -2)
			else
				change = RANDOM:NextInteger(-2, 3)
			end
			rel.relationship = clamp((rel.relationship or 60) + change, 0, 100)
			
			-- Partner might leave if relationship drops too low during jail
			if isInJail and rel.type == "romance" and rel.relationship < 20 then
				if RANDOM:NextNumber() < 0.4 then -- 40% chance partner leaves
					rel.alive = false -- Mark as "gone" (breakup)
					state.Flags.recently_single = true
					state.Flags.has_partner = nil
					if state.Relationships.partner and state.Relationships.partner.id == rel.id then
						state.Relationships.partner = nil
					end
					state.PendingFeed = (rel.name or "Your partner") .. " couldn't handle the separation and left you."
				end
			end
			
			-- Age up the family member
			rel.age = (rel.age or (state.Age + 20)) + 1
			
			-- CRITICAL FIX: Realistic death chances based on age for family members
			-- More graduated death chances instead of just >95 = 20%
			if rel.type == "family" or rel.isFamily then
				local deathChance = 0
				local relAge = rel.age or 0
				
				if relAge >= 100 then
					deathChance = 0.50 -- 50% chance at 100+
				elseif relAge >= 95 then
					deathChance = 0.25 -- 25% chance at 95-99
				elseif relAge >= 90 then
					deathChance = 0.12 -- 12% chance at 90-94
				elseif relAge >= 85 then
					deathChance = 0.06 -- 6% chance at 85-89
				elseif relAge >= 80 then
					deathChance = 0.03 -- 3% chance at 80-84
				elseif relAge >= 75 then
					deathChance = 0.015 -- 1.5% chance at 75-79
				elseif relAge >= 70 then
					deathChance = 0.008 -- 0.8% chance at 70-74
				elseif relAge >= 60 then
					deathChance = 0.003 -- 0.3% chance at 60-69 (accidents, illness)
				end
				
				if deathChance > 0 and RANDOM:NextNumber() < deathChance then
					rel.alive = false
					rel.deceased = true
					rel.deathAge = relAge
					
					-- ═══════════════════════════════════════════════════════════════════════════════
					-- CRITICAL FIX (deep-5): INHERITANCE - Parents leave money when they die!
					-- ═══════════════════════════════════════════════════════════════════════════════
					local inheritanceAmount = 0
					local relRole = (rel.role or ""):lower()
					
					if relRole:find("mother") or relRole:find("father") or relRole:find("parent") then
						-- Parents leave inheritance based on their "wealth" or random amount
						local baseInheritance = rel.wealth or RANDOM:NextInteger(5000, 50000)
						
						-- Upper class parents leave more
						if state.Flags and state.Flags.wealthy_family then
							baseInheritance = baseInheritance * RANDOM:NextInteger(5, 20)
						elseif state.Flags and state.Flags.upper_class then
							baseInheritance = baseInheritance * RANDOM:NextInteger(2, 5)
						end
						
						-- Split among siblings if any exist
						local siblingCount = 0
						for _, otherRel in pairs(state.Relationships) do
							if type(otherRel) == "table" and otherRel.alive ~= false then
								local otherRole = (otherRel.role or ""):lower()
								if otherRole:find("brother") or otherRole:find("sister") or otherRole:find("sibling") then
									siblingCount = siblingCount + 1
								end
							end
						end
						
						inheritanceAmount = math.floor(baseInheritance / (siblingCount + 1))
						
						if inheritanceAmount > 0 then
							self:addMoney(state, inheritanceAmount)
							state.YearLog = state.YearLog or {}
							table.insert(state.YearLog, {
								type = "inheritance",
								emoji = "💰",
								text = string.format("Inherited $%s from %s's estate", formatMoney(inheritanceAmount), rel.name or "your parent"),
								amount = inheritanceAmount,
							})
						end
					elseif relRole:find("grandmother") or relRole:find("grandfather") or relRole:find("grandparent") then
						-- Grandparents may leave smaller inheritance
						local baseInheritance = rel.wealth or RANDOM:NextInteger(1000, 20000)
						inheritanceAmount = math.floor(baseInheritance * RANDOM:NextNumber() * 0.5) -- Random portion
						
						if inheritanceAmount > 500 then
							self:addMoney(state, inheritanceAmount)
							state.YearLog = state.YearLog or {}
							table.insert(state.YearLog, {
								type = "inheritance",
								emoji = "💰",
								text = string.format("Received $%s from %s's will", formatMoney(inheritanceAmount), rel.name or "your grandparent"),
								amount = inheritanceAmount,
							})
						end
					end
					
					table.insert(familyDeaths, {
						name = rel.name or "A loved one",
						role = rel.role or "family member",
						age = relAge,
						id = relId,
						inheritance = inheritanceAmount,
					})
				end
			elseif rel.age > 95 and RANDOM:NextNumber() < 0.2 then
				-- Non-family (old friends etc) still use simple check
				rel.alive = false
				rel.deceased = true
				state.PendingFeed = (rel.name or "A loved one") .. " passed away."
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #4: Handle PARTNER/SPOUSE death SEPARATELY from family deaths
	-- Partner death needs to clear partner data and relationship flags
	-- This was missing, causing deceased partners to still show in relationships!
	-- ═══════════════════════════════════════════════════════════════════════════════
	local partner = state.Relationships.partner
	if partner and type(partner) == "table" and partner.alive ~= false then
		local partnerAge = partner.age or (state.Age + RANDOM:NextInteger(-5, 5))
		local partnerDeathChance = 0
		
		-- CRITICAL FIX #23: Relationship aging respecting death age limits
		if partnerAge >= 100 then
			partnerDeathChance = 0.40
		elseif partnerAge >= 95 then
			partnerDeathChance = 0.20
		elseif partnerAge >= 90 then
			partnerDeathChance = 0.10
		elseif partnerAge >= 85 then
			partnerDeathChance = 0.05
		elseif partnerAge >= 80 then
			partnerDeathChance = 0.025
		elseif partnerAge >= 75 then
			partnerDeathChance = 0.01
		end
		
		if partnerDeathChance > 0 and RANDOM:NextNumber() < partnerDeathChance then
			-- CRITICAL FIX #4: FULLY handle partner death
			local partnerName = partner.name or partner.Name or "Your spouse"
			local partnerRole = partner.role or "partner"
			
			-- Mark partner as deceased
			partner.alive = false
			partner.deceased = true
			partner.deathAge = partnerAge
			
			-- CRITICAL FIX #4: Move to deceased partners list and CLEAR active partner
			state.Relationships.deceased_partners = state.Relationships.deceased_partners or {}
			table.insert(state.Relationships.deceased_partners, {
				name = partnerName,
				role = partnerRole,
				deathAge = partnerAge,
				deathYear = state.Year,
			})
			
			-- CRITICAL FIX #4: CLEAR the partner reference and all related flags!
			state.Relationships.partner = nil
			state.Flags = state.Flags or {}
			state.Flags.has_partner = nil
			state.Flags.married = nil
			state.Flags.engaged = nil
			state.Flags.dating = nil
			state.Flags.lives_with_partner = nil
			state.Flags.widowed = true
			state.Flags.recently_bereaved = true
			state.Flags.lost_spouse = true
			
			-- Significant happiness impact for losing a spouse
			state.Stats = state.Stats or {}
			state.Stats.Happiness = clamp((state.Stats.Happiness or 50) - 35, 0, 100)
			
			state.PendingFeed = string.format("💔 Your %s, %s, passed away at age %d. You are now widowed.", 
				partnerRole, partnerName, partnerAge)
		end
	end
	
	-- CRITICAL FIX: Handle family death notifications with proper emotional impact
	if #familyDeaths > 0 then
		local death = familyDeaths[1] -- Process one death at a time
		local roleName = death.role or "family member"
		local isCloseFamily = (death.id == "mother" or death.id == "father" or 
			death.id:find("brother") or death.id:find("sister"))
		
		-- Happiness impact based on closeness
		if state.ModifyStat then
			if isCloseFamily then
				state:ModifyStat("Happiness", -25)
			else
				state:ModifyStat("Happiness", -10)
			end
		else
			state.Stats = state.Stats or {}
			local impact = isCloseFamily and -25 or -10
			state.Stats.Happiness = clamp((state.Stats.Happiness or 50) + impact, 0, 100)
		end
		
		local messages = {
			"💔 %s (%s, age %d) has passed away. Rest in peace.",
			"😢 Sadly, %s (%s) died at age %d.",
			"🕯️ Your %s, %s, passed away at %d years old.",
		}
		local msgTemplate = messages[RANDOM:NextInteger(1, #messages)]
		local formattedMsg = string.format(msgTemplate, death.name, roleName, death.age)
		
		state.PendingFeed = formattedMsg
		state.Flags = state.Flags or {}
		state.Flags.recently_bereaved = true
		state.Flags["lost_" .. death.id] = true
	end
end

function LifeBackend:updateEducationProgress(state)
	-- CRITICAL FIX: Can't attend school/college while incarcerated!
	-- Education progress is paused during jail time
	if state.InJail then
		return
	end
	
	local eduData = state.EducationData
	if eduData and eduData.Status == "enrolled" then
		-- CRITICAL FIX: Ensure duration is never 0 or nil to prevent instant graduation bug
		-- Duration of 0 would cause 100/0 = infinity, triggering instant "graduation"
		local duration = eduData.Duration
		if not duration or duration <= 0 then
			duration = 4 -- Default to 4 years if not set properly
		end
		local progressPerYear = 100 / duration
		eduData.Progress = clamp((eduData.Progress or 0) + progressPerYear, 0, 100)
		if eduData.Progress >= 100 then
			-- CRITICAL FIX: Only show graduation message for High School and higher
			-- Elementary and Middle School are silent auto-progressions (BitLife-style)
			local level = eduData.Level or ""
			local isPreHighSchool = (level == "elementary" or level == "middle_school" or level == "")
			
			if isPreHighSchool then
				-- Silent progression - just reset progress for next phase
				-- The actual institution transition is handled in LifeState:AdvanceAge()
				eduData.Progress = 0
				-- Don't set status to "completed" - we're still in school
			else
				-- High School and above get proper graduation messages
				eduData.Status = "completed"
				state.Education = eduData.Level
				
				-- ═══════════════════════════════════════════════════════════════════════════════
				-- CRITICAL FIX (deep-2): Store degrees earned in a dedicated list
				-- This ensures all degrees persist and are accessible for job applications
				-- ═══════════════════════════════════════════════════════════════════════════════
				state.DegreesEarned = state.DegreesEarned or {}
				local degreeName = eduData.Degree
				local institutionName = eduData.Institution or "school"
				
				if degreeName then
					table.insert(state.DegreesEarned, {
						degree = degreeName,
						institution = institutionName,
						year = state.Year,
						level = eduData.Level,
						gpa = eduData.GPA,
					})
					state.Flags.has_degree = true
					state.Flags.highest_degree = degreeName
				end
				
				-- ═══════════════════════════════════════════════════════════════════════════════
				-- CRITICAL FIX #MEGA-16: Enhanced graduation with degree display and remaining stat bonuses
				-- Show BOTH institution AND degree earned in the graduation message
				-- ═══════════════════════════════════════════════════════════════════════════════
				if degreeName then
					state.PendingFeed = string.format("🎓 You graduated from %s! Earned: %s", institutionName, degreeName)
				else
					state.PendingFeed = string.format("🎓 You graduated from %s!", institutionName)
				end
				
				-- Apply remaining stat bonuses (70% on completion)
				local program = EducationCatalog[level]
				if program and program.statBonuses then
					local remainingBonus = {}
					for stat, bonus in pairs(program.statBonuses) do
						remainingBonus[stat] = math.ceil(bonus * 0.7)  -- Remaining 70%
					end
					self:applyStatChanges(state, remainingBonus)
				end
				
				-- Set appropriate flags
				state.Flags = state.Flags or {}
				if level == "high_school" then
					state.Flags.graduated_high_school = true
					state.Flags.high_school_graduate = true
					state.Flags.has_ged_or_diploma = true  -- Important for job eligibility
				elseif level == "trade" then
					state.Flags.trade_certified = true
					state.Flags.trades_experience = true
					state.Flags.skilled_worker = true
				elseif level == "bootcamp" then
					state.Flags.bootcamp_graduate = true
					state.Flags.coder = true
					state.Flags.tech_experience = true
					state.Flags.coding_bootcamp = true
				elseif level == "community" or level == "associate" then
					state.Flags.college_graduate = true
					state.Flags.has_associates = true
				elseif level == "bachelor" then
					state.Flags.college_graduate = true
					state.Flags.has_degree = true
					state.Flags.has_bachelors = true
				elseif level == "business" then
					state.Flags.masters_degree = true
					state.Flags.has_degree = true
					state.Flags.has_mba = true
					state.Flags.executive_track = true
				elseif level == "master" then
					state.Flags.masters_degree = true
					state.Flags.has_degree = true
					state.Flags.has_masters = true
				elseif level == "law" then
					state.Flags.law_degree = true
					state.Flags.has_degree = true
					state.Flags.bar_eligible = true
					state.Flags.legal_education = true
				elseif level == "medical" then
					state.Flags.medical_degree = true
					state.Flags.has_degree = true
					state.Flags.medical_education = true
					state.Flags.can_practice_medicine = true
				elseif level == "phd" or level == "doctorate" then
					state.Flags.doctorate = true
					state.Flags.has_degree = true
					state.Flags.has_phd = true
					state.Flags.expert_in_field = true
				end
			end
		end
	end
end

function LifeBackend:tickCareer(state)
	-- CRITICAL: Don't tick career for retired players
	if state.Flags and state.Flags.retired then
		return
	end
	
	-- CRITICAL FIX: Don't tick career while in jail - player loses their job progression
	-- and cannot work while incarcerated
	if state.InJail then
		return
	end
	
	-- Must have a current job to tick career
	if not state.CurrentJob then
		return
	end
	
	state.CareerInfo = state.CareerInfo or {}
	local info = state.CareerInfo
	
	-- Try to get job from catalog, but fallback to CurrentJob data if not found
	-- This handles jobs created by events that aren't in the main JobCatalog
	local catalogJob = JobCatalog[state.CurrentJob.id or state.CurrentJob]
	
	-- For semi-retired, only tick at half rate (less aggressive career progression)
	if state.Flags and state.Flags.semi_retired then
		if RANDOM:NextNumber() < 0.5 then
			return -- Skip half the time
		end
	end
	
	info.yearsAtJob = (info.yearsAtJob or 0) + 1
	-- CRITICAL FIX: Performance can fluctuate more - not always improving
	info.performance = clamp((info.performance or 60) + RANDOM:NextInteger(-5, 5), 0, 100)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #AAA-8: Calculate promotion progress properly - can now reach 100%!
	-- Was capped at ~80% before which caused "80% progress but no promotion" bug
	-- ═══════════════════════════════════════════════════════════════════════════════
	local yearsProgress = math.min((info.yearsAtJob or 0) * 15, 45) -- Up to 45% from years (3 years)
	local perfProgress = (info.performance or 50) * 0.55 -- Up to 55% from performance
	info.promotionProgress = clamp(yearsProgress + perfProgress, 0, 100)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #MOBILE-17: IMPROVED AUTO-PROMOTION when progress hits 80%+
	-- BUG: Players were stuck at 80% because promotion chance was too low (10%)
	-- FIX: Higher chance for entertainment/celebrity careers (they're meant to be fast)
	-- ═══════════════════════════════════════════════════════════════════════════════

	-- Entertainment/celebrity/talent-based careers get FASTER promotions (lower threshold)
	-- These are careers where talent matters more than years of experience
	local jobCategory = (state.CurrentJob.category or ""):lower()
	local jobId = (state.CurrentJob.id or ""):lower()

	local isTalentCareer = jobCategory == "entertainment" or jobCategory == "celebrity" or
		jobCategory == "esports" or jobCategory == "racing" or jobCategory == "sports" or
		jobCategory == "hacker" or jobCategory == "criminal" or
		jobId:find("rapper") or jobId:find("streamer") or jobId:find("influencer") or
		jobId:find("creator") or jobId:find("gamer") or jobId:find("racer") or
		jobId:find("athlete") or jobId:find("musician") or jobId:find("actor")

	-- CRITICAL FIX: Lower threshold for talent careers (60% vs 80% for regular jobs)
	-- Talent careers: 60% progress, 50% performance needed
	-- Regular jobs: 80% progress, 70% performance needed
	local progressThreshold = isTalentCareer and 60 or 80
	local performanceThreshold = isTalentCareer and 50 or 70

	if info.promotionProgress >= progressThreshold and info.performance >= performanceThreshold and (info.yearsAtJob or 0) >= 1 then
		-- Check if we already tried this year
		local lastAutoPromoAge = info.lastAutoPromoAttemptAge or 0
		if (state.Age or 0) > lastAutoPromoAge then
			info.lastAutoPromoAttemptAge = state.Age

			-- CRITICAL FIX: Higher auto-promotion chance, ESPECIALLY for talent-based careers
			local baseChance = (info.promotionProgress - 50) / 100  -- 10% at 60%, 50% at 100%

			if isTalentCareer then
				baseChance = baseChance * 3.0  -- 30% at 60%, 150% (capped to 95%) at 100% for talent careers
			end

			local autoPromoChance = math.min(0.95, baseChance)  -- Cap at 95%
			
			if RANDOM:NextNumber() < autoPromoChance then
				-- Find next job in career track
				local currentJobId = state.CurrentJob and state.CurrentJob.id
				if currentJobId then
					local promoted = false
					local currentCategory = (state.CurrentJob.category and state.CurrentJob.category:lower()) or "entry"
					
					-- Try to find next job in career tracks
					for trackName, trackJobs in pairs(CareerTracks) do
						for i, jobId in ipairs(trackJobs) do
							if jobId == currentJobId then
								local nextJobId = trackJobs[i + 1]
								if nextJobId then
									local nextJob = JobCatalog[nextJobId]
									if nextJob then
										-- Grant flags from current job first
										local currentJob = JobCatalog[currentJobId]
										if currentJob and currentJob.grantsFlags then
											state.Flags = state.Flags or {}
											for _, flag in ipairs(currentJob.grantsFlags) do
												state.Flags[flag] = true
											end
										end
										
										-- Check requirements for next job
										local canPromote = true
										if nextJob.minAge and (state.Age or 0) < nextJob.minAge then
											canPromote = false
										end
										if nextJob.requiresFlags then
											state.Flags = state.Flags or {}
											local hasFlag = false
											for _, flagName in ipairs(nextJob.requiresFlags) do
												if state.Flags[flagName] then
													hasFlag = true
													break
												end
											end
											if not hasFlag then
												canPromote = false
											end
										end
										
										if canPromote then
											-- Apply the promotion!
											local oldJobName = state.CurrentJob.name or "your old job"
											local salaryIncrease = math.floor((nextJob.salary or state.CurrentJob.salary or 30000) * 0.15)
											
											state.CurrentJob = {
												id = nextJob.id,
												name = nextJob.name,
												company = nextJob.company or state.CurrentJob.company,
												salary = nextJob.salary or math.floor((state.CurrentJob.salary or 30000) * 1.20),
												category = nextJob.category or state.CurrentJob.category,
												emoji = nextJob.emoji,
											}
											
											-- Reset promotion progress
											info.promotionProgress = 0
											info.yearsAtJob = 0
											info.promotions = (info.promotions or 0) + 1
											
											-- Set promotion flags
											state.Flags = state.Flags or {}
											state.Flags.just_promoted = true
											state.Flags.promoted_recently = true
											
											-- Grant flags from new job
											if nextJob.grantsFlags then
												for _, flag in ipairs(nextJob.grantsFlags) do
													state.Flags[flag] = true
												end
											end
											
											-- Log the promotion
											state.YearLog = state.YearLog or {}
											table.insert(state.YearLog, {
												type = "promotion",
												emoji = "🎉",
												text = string.format("Promoted from %s to %s! New salary: $%s", 
													oldJobName, nextJob.name, formatMoney(state.CurrentJob.salary)),
											})
											
											promoted = true
											break
										end
									end
								end
								break
							end
						end
						if promoted then break end
					end
				end
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Track career skills based on job category
	-- Skills grow slowly while working in related fields
	-- ═══════════════════════════════════════════════════════════════════════════════
	info.skills = info.skills or {}
	local category = state.CurrentJob.category or "general"
	
	-- Map job categories to skills
	local categorySkills = {
		tech = { Technical = 3, Analytical = 2 },
		office = { Social = 2, Analytical = 1 },
		science = { Analytical = 3, Technical = 2 },
		law = { Social = 2, Analytical = 2 },
		finance = { Analytical = 3, Leadership = 1 },
		medical = { Technical = 2, Analytical = 2, Social = 1 },
		military = { Physical = 3, Leadership = 2 },
		sports = { Physical = 4, Leadership = 1 },
		trades = { Technical = 2, Physical = 2 },
		creative = { Creative = 4, Social = 1 },
		entertainment = { Creative = 3, Social = 2 },
		service = { Social = 3 },
		retail = { Social = 2 },
		food = { Social = 1, Physical = 1 },
		executive = { Leadership = 4, Analytical = 2, Social = 2 },
		management = { Leadership = 3, Social = 2 },
		government = { Leadership = 2, Social = 2, Analytical = 1 },
	}
	
	local skillGrowth = categorySkills[category] or { Social = 1 }
	for skill, maxGain in pairs(skillGrowth) do
		local currentLevel = info.skills[skill] or 0
		-- Diminishing returns at higher levels
		local gain = math.max(1, math.floor(maxGain * (1 - currentLevel / 100)))
		info.skills[skill] = math.min(100, currentLevel + RANDOM:NextInteger(0, gain))
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #137: Actually PAY the salary during age up AND show feed message!
	-- The salary WAS being paid but user couldn't see it because no message was shown
	-- Use catalog job salary if available, otherwise use CurrentJob.salary directly
	-- This ensures event-created jobs (not in catalog) still pay salary
	-- ═══════════════════════════════════════════════════════════════════════════════
	local salary = 0
	if catalogJob and catalogJob.salary then
		salary = catalogJob.salary
	elseif state.CurrentJob.salary then
		salary = state.CurrentJob.salary
	end
	
	if salary > 0 then
		self:addMoney(state, salary)
		debugPrint("Salary paid:", salary, "to player. New balance:", state.Money)
		
		-- CRITICAL FIX: Store last paid salary for pension calculation
		-- This ensures retirement events can calculate pension from actual income
		-- (important for fame careers where CurrentJob.salary may be outdated)
		state.CareerInfo = state.CareerInfo or {}
		state.CareerInfo.lastPaidSalary = salary
		
		-- CRITICAL FIX #138: Add salary to YearLog so user sees they got paid!
		-- This was the bug - salary was paid but user didn't see any message
		-- YearLog entries need 'text' field, not 'message' - that's what generateYearSummary looks for
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "salary",
			emoji = "💰",
			text = string.format("Earned $%s from your job as %s", 
				formatMoney(salary), 
				state.CurrentJob.name or "employee"),
			amount = salary,
		})
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROPERTY INCOME - Collect passive income from owned real estate
-- CRITICAL FIX: This was completely missing! Properties have income fields but
-- the rental income was never being collected during age up.
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:collectPropertyIncome(state)
	-- Properties still generate income even if player is in jail (tenants pay rent)
	-- But player can't BUY or SELL while incarcerated (handled elsewhere)
	
	state.Assets = state.Assets or {}
	local properties = state.Assets.Properties or {}
	
	if #properties == 0 then
		return
	end
	
	local totalIncome = 0
	local propertyDetails = {}
	
	for _, prop in ipairs(properties) do
		-- CRITICAL FIX #18: Handle ALL property types for income
		local income = prop.income or 0
		
		-- If no explicit income, calculate based on property type and value
		if income == 0 and prop.value and prop.value > 0 then
			local propId = (prop.id or ""):lower()
			local propName = (prop.name or ""):lower()
			
			-- Rental properties generate rental income (5-8% of value annually)
			if propId:find("rental") or propId:find("apartment") or propName:find("rental") then
				income = math.floor(prop.value * (RANDOM:NextNumber() * 0.03 + 0.05)) -- 5-8%
			-- Commercial properties generate business income (4-10% of value)
			elseif propId:find("commercial") or propId:find("office") or propId:find("retail") or propId:find("storefront") then
				income = math.floor(prop.value * (RANDOM:NextNumber() * 0.06 + 0.04)) -- 4-10%
			-- Vacation rentals have seasonal income (8-15% but variable)
			elseif propId:find("vacation") or propId:find("cabin") or propId:find("beach") then
				income = math.floor(prop.value * (RANDOM:NextNumber() * 0.07 + 0.08)) -- 8-15%
			-- Primary residence - no rental income (you live there)
			elseif propId:find("house") or propId:find("mansion") or propId:find("penthouse") then
				income = 0 -- No income from primary residence
			end
		end
		
		if income > 0 then
			totalIncome = totalIncome + income
			table.insert(propertyDetails, {name = prop.name or "Property", income = income})
		end
	end
	
	if totalIncome > 0 then
		self:addMoney(state, totalIncome)
		
		-- CRITICAL FIX #141: Use YearLog for property income instead of PendingFeed
		-- This ensures all income/expense info is shown consistently
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "property_income",
			emoji = "🏠",
			text = string.format("Collected $%s in property rental income", formatMoney(totalIncome)),
			amount = totalIncome,
		})
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #10: Vehicle Depreciation System
-- Vehicles lose value over time (10-15% per year) based on condition
-- Without this, cars never lose value and can be sold for purchase price forever
-- CRITICAL FIX #19: Some classic/collector vehicles APPRECIATE instead!
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:tickVehicleDepreciation(state)
	state.Assets = state.Assets or {}
	local vehicles = state.Assets.Vehicles or {}
	
	if #vehicles == 0 then
		return
	end
	
	-- CRITICAL FIX #19: Vehicles that appreciate in value (classics, collectibles)
	local appreciatingVehicles = {
		"classic", "vintage", "antique", "collector", "ferrari_250", 
		"porsche_911", "mustang_1967", "corvette_1963", "shelby_gt500"
	}
	
	for _, vehicle in ipairs(vehicles) do
		if vehicle.value and vehicle.value > 0 then
			local vehicleId = (vehicle.id or ""):lower()
			local vehicleName = (vehicle.name or ""):lower()
			local vehicleTier = (vehicle.tier or ""):lower()
			
			-- CRITICAL FIX #19: Check if this is an appreciating vehicle
			local doesAppreciate = vehicle.appreciates == true
			if not doesAppreciate then
				for _, appreciateKey in ipairs(appreciatingVehicles) do
					if vehicleId:find(appreciateKey) or vehicleName:find(appreciateKey) or vehicleTier == "collector" then
						doesAppreciate = true
						break
					end
				end
			end
			
			if doesAppreciate then
				-- CRITICAL FIX #19: Appreciating vehicles GAIN value (2-8% per year)
				local appreciationRate = RANDOM:NextNumber() * 0.06 + 0.02 -- 2-8%
				local appreciationAmount = math.floor(vehicle.value * appreciationRate)
				vehicle.value = vehicle.value + appreciationAmount
				
				-- Collectors maintain their vehicles well
				if vehicle.condition then
					vehicle.condition = math.min(100, vehicle.condition + RANDOM:NextInteger(0, 2))
				end
			else
				-- Normal depreciation for regular vehicles
				local baseDepreciation = 0.12 -- 12% base
				local conditionMod = vehicle.condition and (1 - vehicle.condition / 200) or 1 -- Poor condition = faster depreciation
				local depreciationRate = baseDepreciation * conditionMod
				
				-- Calculate depreciation
				local depreciationAmount = math.floor(vehicle.value * depreciationRate)
				vehicle.value = math.max(500, vehicle.value - depreciationAmount) -- Minimum $500 scrap value
				
				-- Condition also degrades slightly each year (1-5%)
				if vehicle.condition then
					vehicle.condition = math.max(0, vehicle.condition - RANDOM:NextInteger(1, 5))
				end
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #11: Investment Value Fluctuation
-- Investments should gain or lose value each year based on market conditions
-- Without this, investments are just static numbers
-- CRITICAL FIX #20: Cap returns to prevent unrealistic exponential growth
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:tickInvestments(state)
	state.Assets = state.Assets or {}
	local investments = state.Assets.Investments or {}
	local crypto = state.Assets.Crypto or {}
	
	-- Stock/bond investments: -10% to +15% annually
	for _, inv in ipairs(investments) do
		if inv.value and inv.value > 0 then
			local changePercent = RANDOM:NextNumber() * 0.25 - 0.10 -- -10% to +15%
			local changeAmount = math.floor(inv.value * changePercent)
			local newValue = inv.value + changeAmount
			
			-- CRITICAL FIX #20: Cap maximum growth per year to 3x original purchase price
			local originalPrice = inv.price or inv.value
			local maxValue = originalPrice * 3
			inv.value = math.max(0, math.min(newValue, maxValue))
			
			-- Track total return for display
			inv.totalReturn = inv.value - originalPrice
			inv.returnPercent = originalPrice > 0 and math.floor((inv.value / originalPrice - 1) * 100) or 0
		end
	end
	
	-- Crypto: more volatile, -30% to +50% annually
	for _, coin in ipairs(crypto) do
		if coin.value and coin.value > 0 then
			local changePercent = RANDOM:NextNumber() * 0.80 - 0.30 -- -30% to +50%
			local changeAmount = math.floor(coin.value * changePercent)
			local newValue = coin.value + changeAmount
			
			-- CRITICAL FIX #20: Cap crypto growth to 5x original (still volatile but not infinite)
			local originalPrice = coin.price or coin.value
			local maxValue = originalPrice * 5
			coin.value = math.max(0, math.min(newValue, maxValue))
			
			-- Track total return
			coin.totalReturn = coin.value - originalPrice
			coin.returnPercent = originalPrice > 0 and math.floor((coin.value / originalPrice - 1) * 100) or 0
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #12: Annual Cost of Living Expenses
-- Players should have annual expenses that scale with lifestyle
-- Without this, money only goes up, never down from basic living costs
-- CRITICAL FIX #318: Young adults (18-22) without jobs live with parents = lower expenses
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyLivingExpenses(state)
	-- Don't apply expenses if player is under 18 (parents support them)
	if (state.Age or 0) < 18 then
		return
	end
	
	-- Don't apply expenses in prison (state provides housing/food)
	if state.InJail then
		return
	end
	
	local age = state.Age or 18
	local hasJob = state.Job and state.Job.title and state.Job.title ~= "" and state.Job.title ~= "Unemployed"
	local inCollege = state.Education and (state.Education.inCollege or state.Education.enrolled)
	local hasProperty = state.Assets and state.Assets.Properties and #state.Assets.Properties > 0
	
	-- CRITICAL FIX #318: Young adults (18-22) living situations
	-- If no job and young, they likely live with parents (much lower expenses)
	-- If in college, they have student living expenses (moderate)
	-- If employed, normal adult expenses
	local baseCost = 8000 -- Default $8,000/year minimum for basic living
	local totalExpenses = 0
	local expenseDescription = "living expenses"
	
	if age <= 22 and not hasJob and not hasProperty then
		-- CRITICAL FIX #318: Young adults without jobs live with parents
		if inCollege then
			-- College student: dorm/shared housing, meal plan
			baseCost = 3000 -- Just personal expenses, food plan covered
			totalExpenses = baseCost
			expenseDescription = "college living costs"
		else
			-- Living with parents - minimal expenses
			baseCost = 1500 -- Phone, car insurance, personal items only
			totalExpenses = baseCost
			expenseDescription = "personal expenses (living with family)"
		end
	elseif age <= 25 and not hasJob then
		-- 23-25 without job - struggling but parents may still help
		baseCost = 4000
		totalExpenses = baseCost
		expenseDescription = "basic living costs"
	else
		-- Normal adult with or seeking employment
		totalExpenses = baseCost
		
		-- Add housing costs if no owned property
		if not hasProperty then
			-- CRITICAL FIX #318: Rent scales with age/career stage
			local rentCost = 9000 -- Base rent $750/month for starter apartment
			if age > 30 then
				rentCost = 12000 -- $1,000/month for established adult
			end
			if age > 45 then
				rentCost = 15000 -- $1,250/month for established family
			end
			totalExpenses = totalExpenses + rentCost
		end
	end
	
	-- Add vehicle maintenance if owns vehicles (everyone pays this)
	local numVehicles = state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles or 0
	if numVehicles > 0 then
		totalExpenses = totalExpenses + (numVehicles * 2000) -- $2,000/year per vehicle
	end
	
	-- CRITICAL FIX #152: Count children from relationships instead of ChildCount
	-- state.ChildCount was never being set, so child expenses were always $0!
	-- CRITICAL FIX #21: Living expenses MUST scale with family size properly
	local childCount = 0
	local partnerCount = 0
	if state.Relationships then
		for _, rel in pairs(state.Relationships) do
			if type(rel) == "table" then
				-- Count children
				if rel.isChild or rel.role == "Child" or rel.role == "Son" or rel.role == "Daughter" then
					childCount = childCount + 1
				end
				-- Count partner/spouse
				if rel.role == "Spouse" or rel.role == "Partner" or rel.role == "Fiancé" or rel.role == "Fiancée" then
					partnerCount = 1
				end
			end
		end
	end
	-- Also check the dedicated partner slot
	if state.Relationships and state.Relationships.partner then
		partnerCount = 1
	end
	-- CRITICAL FIX #21: Use Flags.married for backup partner detection
	if (state.Flags and state.Flags.married) and partnerCount == 0 then
		partnerCount = 1
	end
	
	-- CRITICAL FIX #21: Family expenses scale properly
	-- Partner adds to expenses (shared housing but food, utilities, etc.)
	if partnerCount > 0 then
		totalExpenses = totalExpenses + 3000 -- $3,000/year additional for partner
	end
	-- Children are expensive!
	if childCount > 0 then
		-- First child is most expensive (new baby stuff), subsequent are cheaper
		local firstChildCost = 8000 -- $8,000/year for first child
		local additionalChildCost = 5000 -- $5,000/year for additional children
		totalExpenses = totalExpenses + firstChildCost + ((childCount - 1) * additionalChildCost)
		
		-- CRITICAL FIX: School-age children have additional costs
		-- Estimate based on having school-age children (usually if player is 30+)
		if age >= 30 and childCount > 0 then
			totalExpenses = totalExpenses + (childCount * 2000) -- School supplies, activities, etc.
		end
	end
	
	-- Healthcare costs increase with age (only for adults 30+)
	if age > 50 then
		local ageFactor = (age - 50) / 10
		totalExpenses = totalExpenses + math.floor(2000 * ageFactor)
	elseif age > 30 then
		totalExpenses = totalExpenses + 500 -- Small health insurance costs
	end
	
	-- Apply expenses (but don't go below 0)
	local currentMoney = state.Money or 0
	if currentMoney >= totalExpenses then
		state.Money = currentMoney - totalExpenses
		
		-- CRITICAL FIX #139: Log expenses to YearLog so user sees where money went
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "expenses",
			emoji = "🏠",
			text = string.format("Paid $%s in %s", formatMoney(totalExpenses), expenseDescription),
			amount = -totalExpenses,
		})
	else
		-- Can't afford full expenses - go broke but not negative
		local paidAmount = currentMoney
		state.Money = 0
		state.Flags = state.Flags or {}
		state.Flags.struggling_financially = true
		
		-- CRITICAL FIX #140: Log when player goes broke
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "expenses",
			emoji = "💸",
			text = string.format("Couldn't afford $%s in %s - struggling!", formatMoney(totalExpenses), expenseDescription),
			amount = -paidAmount,
		})
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #13: Health Decay from Unhealthy Habits
-- Smoking, drinking, and other bad habits should actually affect health
-- Without this, flags like "smoker" are just cosmetic
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyHabitEffects(state)
	state.Stats = state.Stats or {}
	state.Flags = state.Flags or {}
	
	local healthChange = 0
	local happinessChange = 0
	
	-- Smoking: -1 to -3 health per year, cumulative damage
	if state.Flags.smoker then
		healthChange = healthChange - RANDOM:NextInteger(1, 3)
		-- 5% chance per year of serious illness from smoking
		if RANDOM:NextNumber() < 0.05 then
			state.Flags.smoking_related_illness = true
			healthChange = healthChange - 10
		end
	end
	
	-- Heavy drinking: -1 to -2 health, -2 to +1 happiness (addiction)
	if state.Flags.heavy_drinker then
		healthChange = healthChange - RANDOM:NextInteger(1, 2)
		happinessChange = happinessChange + RANDOM:NextInteger(-2, 1)
		-- 3% chance of liver problems
		if RANDOM:NextNumber() < 0.03 then
			state.Flags.liver_problems = true
			healthChange = healthChange - 8
		end
	end
	
	-- Substance abuse: serious health impact
	if state.Flags.substance_issue or state.Flags.substance_addict then
		healthChange = healthChange - RANDOM:NextInteger(2, 5)
		happinessChange = happinessChange - RANDOM:NextInteger(1, 3)
	end
	
	-- Fitness enthusiast: positive health
	if state.Flags.fitness_enthusiast then
		healthChange = healthChange + RANDOM:NextInteger(1, 2)
	end
	
	-- Apply changes
	if healthChange ~= 0 then
		state.Stats.Health = clamp((state.Stats.Health or 50) + healthChange, 0, 100)
		state.Health = state.Stats.Health
	end
	
	if happinessChange ~= 0 then
		state.Stats.Happiness = clamp((state.Stats.Happiness or 50) + happinessChange, 0, 100)
		state.Happiness = state.Stats.Happiness
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX (deep-11): SPOUSE INCOME
-- If player is married and spouse works, they contribute to household income!
-- This was completely missing - spouses were just decorative
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:collectSpouseIncome(state)
	local partner = state.Relationships and state.Relationships.partner
	if not partner or partner.alive == false then
		return
	end
	
	-- Only married couples share income
	if not (state.Flags and (state.Flags.married or state.Flags.lives_with_partner)) then
		return
	end
	
	-- Check if spouse has a job
	local spouseJob = partner.job or partner.occupation
	local spouseSalary = partner.salary or 0
	
	-- If no explicit job data, estimate based on spouse age and education
	if spouseSalary == 0 then
		local spouseAge = partner.age or state.Age
		
		-- Only working-age spouses contribute
		if spouseAge >= 18 and spouseAge < 65 then
			-- Random chance they have a job (70% employment rate)
			if RANDOM:NextNumber() < 0.70 then
				-- Estimate salary based on factors
				local baseSalary = RANDOM:NextInteger(25000, 60000)
				
				-- Adjust for education
				if partner.education == "college" or partner.educated then
					baseSalary = baseSalary * 1.5
				elseif partner.education == "graduate" or partner.advanced_degree then
					baseSalary = baseSalary * 2.5
				end
				
				-- Adjust for experience (age-based)
				local experienceMod = math.min(1.5, 1 + (spouseAge - 22) * 0.02)
				spouseSalary = math.floor(baseSalary * experienceMod)
				
				-- Store for future reference
				partner.salary = spouseSalary
				partner.job = "Working Professional"
			else
				partner.job = "Not employed"
				partner.salary = 0
			end
		elseif spouseAge >= 65 then
			-- Retired spouse may have pension
			local pension = RANDOM:NextInteger(10000, 30000)
			spouseSalary = pension
			partner.job = "Retired"
			partner.salary = pension
		end
	end
	
	if spouseSalary > 0 then
		self:addMoney(state, spouseSalary)
		
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "spouse_income",
			emoji = "💑",
			text = string.format("%s contributed $%s to household income", 
				partner.name or "Your spouse", 
				formatMoney(spouseSalary)),
			amount = spouseSalary,
		})
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #14: Fame Decay System
-- Fame should gradually decrease without maintenance
-- Without this, once famous always famous
-- CRITICAL FIX #14B: But decay should NOT be aggressive for low fame players!
-- Low fame players (< 20) should have minimal decay to let them build up
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:tickFame(state)
	local fame = state.Fame or 0
	if fame <= 0 then
		return
	end
	
	-- CRITICAL FIX: Low fame players get minimal decay to let them build up
	-- This fixes the issue where new celebrities lost fame before they could grow
	if fame < 10 then
		-- Almost no decay for very low fame - let them establish themselves
		local decayAmount = RANDOM:NextInteger(0, 1)
		state.Fame = math.max(0, fame - decayAmount)
		return
	elseif fame < 20 then
		-- Minimal decay for low fame
		local decayAmount = RANDOM:NextInteger(0, 2)
		state.Fame = math.max(0, fame - decayAmount)
		return
	elseif fame < 40 then
		-- Reduced decay for moderate fame (1-3% per year)
		local decayRate = RANDOM:NextNumber() * 0.02 + 0.01 -- 1-3%
		local decayAmount = math.max(1, math.floor(fame * decayRate))
		state.Fame = math.max(0, fame - decayAmount)
		return
	end
	
	-- Fame naturally decays 3-8% per year without maintenance (reduced from 5-10%)
	local decayRate = RANDOM:NextNumber() * 0.05 + 0.03 -- 3-8%
	local decayAmount = math.floor(fame * decayRate)
	
	-- Active careers that maintain fame slow decay
	if state.CurrentJob then
		local jobId = state.CurrentJob.id or ""
		local fameMaintainingJobs = {
			"actor", "singer", "athlete", "influencer", "model", 
			"tv_host", "youtuber", "politician", "celebrity",
			"rapper", "streamer", "musician", "entertainer", "host"
		}
		for _, job in ipairs(fameMaintainingJobs) do
			if jobId:find(job) then
				decayAmount = math.floor(decayAmount * 0.25) -- 75% slower decay for active careers
				break
			end
		end
	end
	
	-- CRITICAL FIX: Fame state career path also slows decay
	if state.FameState and state.FameState.careerPath then
		decayAmount = math.floor(decayAmount * 0.5) -- 50% slower if in fame career
	end
	
	-- CRITICAL FIX: Royalty and mafia members have slower fame decay (public figures)
	if (state.RoyalState and state.RoyalState.isRoyal) or (state.MobState and state.MobState.inMob) then
		decayAmount = math.floor(decayAmount * 0.6) -- 40% slower
	end
	
	state.Fame = math.max(0, fame - decayAmount)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #15: Education Debt Interest
-- Student loans should accrue interest annually
-- Without this, college debt never grows
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyDebtInterest(state)
	if not state.EducationData or not state.EducationData.Debt then
		return
	end
	
	local debt = state.EducationData.Debt
	if debt <= 0 then
		return
	end
	
	-- 5% annual interest on student loans
	local interest = math.floor(debt * 0.05)
	state.EducationData.Debt = debt + interest
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #36: Annual Education Costs
-- Students need to pay for room, board, books, etc. while enrolled
-- Without this, college is just a one-time tuition payment
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyEducationCosts(state)
	local eduData = state.EducationData
	if not eduData or eduData.Status ~= "enrolled" then
		return
	end
	
	-- CRITICAL FIX: Only apply education costs to POST-HIGH-SCHOOL education!
	-- Elementary, middle school, and high school are FREE (public school)
	-- This was incorrectly charging 5-year-olds for "education expenses"
	local level = eduData.Level or ""
	
	-- These are the ONLY levels that have costs (college and beyond)
	local annualCosts = {
		community = 3000, -- Living expenses while at community college
		bachelor = 8000, -- Room, board, books at university
		master = 6000, -- Graduate students have some funding
		law = 5000, -- Law school has less room/board (often living at home)
		medical = 10000, -- Med students need equipment, books
		phd = 3000, -- PhD students get stipends
	}
	
	-- CRITICAL: If the level is not in our costs table, it's FREE education (K-12)
	-- Do NOT charge for elementary, middle_school, high_school, or unknown levels
	local cost = annualCosts[level]
	if not cost then
		-- This is K-12 education or unknown - no cost!
		return
	end
	
	-- Also verify age - college shouldn't start before 18
	local age = state.Age or 0
	if age < 18 then
		return
	end
	
	local money = state.Money or 0
	
	if money >= cost then
		state.Money = money - cost
		-- CRITICAL FIX #158: Log education costs to YearLog
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "education_cost",
			emoji = "🎓",
			text = string.format("Paid $%s for education expenses", formatMoney(cost)),
			amount = -cost,
		})
	else
		-- Can't afford - add to debt
		local shortfall = cost - money
		state.Money = 0
		eduData.Debt = (eduData.Debt or 0) + shortfall
		state.Flags = state.Flags or {}
		state.Flags.has_student_loans = true
		-- CRITICAL FIX #159: Log student loans to YearLog
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "student_loan",
			emoji = "📚",
			text = string.format("Took out $%s in student loans", formatMoney(shortfall)),
			amount = 0, -- Not a direct expense, just debt
		})
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #16: Pet Lifecycle System
-- Pets age and eventually pass away (dogs ~12-15 years, cats ~15-20 years)
-- Without this, pets live forever once acquired
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:tickPetLifecycle(state)
	state.Flags = state.Flags or {}
	state.PetData = state.PetData or {}
	
	-- Initialize pet ages if not set
	if state.Flags.has_dog and not state.PetData.dogAge then
		state.PetData.dogAge = 1 -- Assume recently adopted
		state.PetData.dogName = state.PetData.dogName or "Buddy"
	end
	if state.Flags.has_cat and not state.PetData.catAge then
		state.PetData.catAge = 1
		state.PetData.catName = state.PetData.catName or "Whiskers"
	end
	
	-- Age dogs and check for death (lifespan 10-15 years)
	-- CRITICAL FIX #24: Force death for very old pets (no dog lives past 20)
	if state.Flags.has_dog and state.PetData.dogAge then
		state.PetData.dogAge = state.PetData.dogAge + 1
		local dogAge = state.PetData.dogAge
		local shouldDie = false
		
		-- CRITICAL FIX #24: GUARANTEED death at 20+ years (world record is ~30, but 20 is very old)
		if dogAge >= 20 then
			shouldDie = true
		elseif dogAge >= 10 then
			local deathChance = (dogAge - 10) / 10 -- Increases each year after 10
			-- CRITICAL FIX #24: Higher base death chance for older dogs
			if dogAge >= 15 then
				deathChance = math.max(deathChance, 0.60) -- At least 60% at 15+
			elseif dogAge >= 13 then
				deathChance = math.max(deathChance, 0.35) -- At least 35% at 13-14
			end
			shouldDie = RANDOM:NextNumber() < deathChance
		end
		
		if shouldDie then
			state.Flags.has_dog = nil
			state.Flags.lost_dog = true
			state.PetData.dogAge = nil
			local dogName = state.PetData.dogName or "your dog"
			self:logYearEvent(state, "pet_death", 
				string.format("💔 %s passed away after %d wonderful years together.", dogName, dogAge), "🐕")
			state.Stats = state.Stats or {}
			state.Stats.Happiness = clamp((state.Stats.Happiness or 50) - 15, 0, 100)
		end
	end
	
	-- Age cats and check for death (lifespan 12-20 years)
	-- CRITICAL FIX #24: Force death for very old cats (no cat lives past 25)
	if state.Flags.has_cat and state.PetData.catAge then
		state.PetData.catAge = state.PetData.catAge + 1
		local catAge = state.PetData.catAge
		local shouldDie = false
		
		-- CRITICAL FIX #24: GUARANTEED death at 25+ years (world record is ~38, but 25 is very old)
		if catAge >= 25 then
			shouldDie = true
		elseif catAge >= 12 then
			local deathChance = (catAge - 12) / 15 -- Cats live longer
			-- CRITICAL FIX #24: Higher base death chance for older cats
			if catAge >= 20 then
				deathChance = math.max(deathChance, 0.65) -- At least 65% at 20+
			elseif catAge >= 17 then
				deathChance = math.max(deathChance, 0.40) -- At least 40% at 17-19
			end
			shouldDie = RANDOM:NextNumber() < deathChance
		end
		
		if shouldDie then
			state.Flags.has_cat = nil
			state.Flags.lost_cat = true
			state.PetData.catAge = nil
			local catName = state.PetData.catName or "your cat"
			self:logYearEvent(state, "pet_death", 
				string.format("💔 %s passed away at age %d. A faithful companion.", catName, catAge), "🐱")
			state.Stats = state.Stats or {}
			state.Stats.Happiness = clamp((state.Stats.Happiness or 50) - 12, 0, 100)
		end
	end
	
	-- Small pets have shorter lifespans (2-5 years)
	-- CRITICAL FIX #24: Force death for very old small pets (hamsters/etc max 7 years)
	if state.Flags.has_small_pet and state.PetData.smallPetAge then
		state.PetData.smallPetAge = state.PetData.smallPetAge + 1
		local petAge = state.PetData.smallPetAge
		local shouldDie = false
		
		-- CRITICAL FIX #24: GUARANTEED death at 7+ years
		if petAge >= 7 then
			shouldDie = true
		elseif petAge >= 3 then
			local deathChance = (petAge - 2) / 5
			-- Higher base chance for older small pets
			if petAge >= 5 then
				deathChance = math.max(deathChance, 0.50)
			end
			shouldDie = RANDOM:NextNumber() < deathChance
		end
		
		if shouldDie then
			state.Flags.has_small_pet = nil
			state.PetData.smallPetAge = nil
			self:logYearEvent(state, "pet_death", "💔 Your small pet passed away.", "🐹")
			state.Stats = state.Stats or {}
			state.Stats.Happiness = clamp((state.Stats.Happiness or 50) - 5, 0, 100)
		end
	elseif state.Flags.has_small_pet and not state.PetData.smallPetAge then
		state.PetData.smallPetAge = 1
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #17: Career Skills Tracking
-- Skills gained from jobs should persist and affect future job applications
-- Without this, experience in a field doesn't help career progression
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:updateCareerSkills(state)
	if not state.CurrentJob then
		return
	end
	
	state.CareerInfo = state.CareerInfo or {}
	state.CareerInfo.skills = state.CareerInfo.skills or {}
	
	local job = state.CurrentJob
	local category = job.category or "general"
	
	-- Gain 1-3 skill points in current category each year
	local skillGain = RANDOM:NextInteger(1, 3)
	state.CareerInfo.skills[category] = (state.CareerInfo.skills[category] or 0) + skillGain
	
	-- Cap skills at 100
	state.CareerInfo.skills[category] = math.min(100, state.CareerInfo.skills[category])
	
	-- Also gain general "work experience" stat
	state.CareerInfo.skills.general = (state.CareerInfo.skills.general or 0) + 1
	state.CareerInfo.skills.general = math.min(100, state.CareerInfo.skills.general)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #18: Relationship Decay Without Interaction
-- Relationships that aren't maintained should slowly decrease
-- Without this, relationships stay at 100 forever once maxed
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyRelationshipDecay(state)
	if not state.Relationships then
		return
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX (deep-9): REDUCE relationship decay while in rehab/hospital
	-- People understand you're getting treatment - they don't abandon you as fast
	-- ═══════════════════════════════════════════════════════════════════════════════
	local inTreatment = state.Flags and (
		state.Flags.in_rehab or 
		state.Flags.hospitalized or 
		state.Flags.in_hospital or 
		state.Flags.recovering or 
		state.Flags.seeking_help or
		state.Flags.attending_aa
	)
	
	for relId, rel in pairs(state.Relationships) do
		if type(rel) == "table" and rel.alive ~= false then
			-- Relationships naturally decay 1-3 points per year without interaction
			local decay = RANDOM:NextInteger(1, 3)
			
			-- CRITICAL FIX (deep-9): Treatment reduces decay - people are supportive
			if inTreatment then
				decay = math.floor(decay * 0.3) -- 70% less decay during treatment
			end
			
			-- Close family decays slower
			if rel.isFamily or rel.type == "family" then
				decay = math.floor(decay * 0.5)
			end
			
			-- Partners decay faster if not married (less commitment)
			if rel.type == "romantic" and not state.Flags.married then
				decay = decay + 1
			end
			
			-- Prison causes faster decay (people move on)
			if state.InJail then
				decay = decay * 2
			end
			
			rel.relationship = math.max(0, (rel.relationship or 50) - decay)
			
			-- Very low relationships may end naturally
			if rel.relationship <= 10 and rel.type == "friend" then
				if RANDOM:NextNumber() < 0.2 then -- 20% chance friendship fades
					rel.alive = false
					rel.ended = true
					rel.endReason = "drifted_apart"
				end
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #19: Property Appreciation/Depreciation
-- Property values should change based on market conditions
-- Without this, properties are just static values
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:tickPropertyValues(state)
	state.Assets = state.Assets or {}
	local properties = state.Assets.Properties or {}
	
	if #properties == 0 then
		return
	end
	
	for _, prop in ipairs(properties) do
		if prop.value and prop.value > 0 then
			-- Properties generally appreciate 2-5% per year, sometimes decline 1-2%
			local changePercent = RANDOM:NextNumber() * 0.06 - 0.01 -- -1% to +5%
			local changeAmount = math.floor(prop.value * changePercent)
			prop.value = math.max(1000, prop.value + changeAmount) -- Minimum $1,000 value
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #20: Bankruptcy Protection System
-- Players with massive debt should face consequences
-- Without this, players can accumulate infinite negative consequences
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:checkBankruptcy(state)
	local totalDebt = 0
	
	-- Calculate total debt
	if state.EducationData and state.EducationData.Debt then
		totalDebt = totalDebt + state.EducationData.Debt
	end
	
	-- CRITICAL FIX #21: Include credit card debt and mortgage in total debt calculation
	state.Flags = state.Flags or {}
	if state.Flags.credit_card_debt then
		totalDebt = totalDebt + (state.Flags.credit_card_debt or 0)
	end
	if state.Flags.mortgage_debt then
		totalDebt = totalDebt + (state.Flags.mortgage_debt or 0)
	end
	
	-- Check if player is in severe financial distress
	local money = state.Money or 0
	local netWorth = computeNetWorth(state)
	
	-- If net worth is severely negative and player has no income
	if netWorth < -100000 and not state.CurrentJob and money <= 0 then
		if not state.Flags.declared_bankruptcy then
			-- First time - opportunity to declare bankruptcy
			state.Flags.financial_crisis = true
			self:logYearEvent(state, "financial", 
				"⚠️ You're in severe financial distress. Consider your options carefully.", "💸")
		end
	end
	
	-- CRITICAL FIX #26: If player has declared bankruptcy, ensure ALL debt is cleared
	-- This fixes the bug where bankruptcy was declared but debt flags remained
	if state.Flags.declared_bankruptcy and state.Flags.bankruptcy_pending then
		-- Clear ALL debt flags
		state.Flags.credit_card_debt = nil
		state.Flags.mortgage_debt = nil
		state.Flags.car_loan_balance = nil
		state.Flags.car_loan_payment = nil
		state.Flags.has_car_loan = nil
		state.Flags.has_student_loans = nil -- Note: student loans can't be discharged IRL, but for gameplay
		state.Flags.student_loan_amount = nil
		state.Flags.debt_collection = nil
		state.Flags.financial_crisis = nil
		state.Flags.bad_debt = nil
		state.Flags.defaulted = nil
		state.Flags.bankruptcy_pending = nil
		
		-- Education debt is partially forgiven (student loans survive bankruptcy IRL, but reduced in game)
		if state.EducationData and state.EducationData.Debt then
			state.EducationData.Debt = math.floor(state.EducationData.Debt * 0.5) -- 50% forgiven
		end
		
		-- Consequences of bankruptcy
		state.Flags.bad_credit = true
		state.Flags.bankruptcy_on_record = true
		state.Flags.credit_score_tanked = true
		
		-- Lose some assets (liquidation)
		if state.Assets then
			-- Keep primary home, but lose luxury items
			if state.Assets.Vehicles and #state.Assets.Vehicles > 1 then
				-- Keep only one vehicle
				local keptVehicle = state.Assets.Vehicles[1]
				state.Assets.Vehicles = { keptVehicle }
				self:logYearEvent(state, "financial", 
					"🚗 Extra vehicles liquidated as part of bankruptcy.", "💸")
			end
		end
		
		self:logYearEvent(state, "financial", 
			"💸 Bankruptcy finalized. Debts discharged but credit is damaged for years.", "⚖️")
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #21: Credit Card Debt Interest
-- Credit card debt should accrue 15-25% annual interest (much higher than student loans)
-- Without this, players can rack up credit card debt without consequences
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyCreditCardInterest(state)
	state.Flags = state.Flags or {}
	
	local ccDebt = state.Flags.credit_card_debt or 0
	if ccDebt <= 0 then
		return
	end
	
	-- Credit card interest is brutal: 18-25% APR
	local interestRate = 0.18 + (RANDOM:NextNumber() * 0.07) -- 18-25%
	local interest = math.floor(ccDebt * interestRate)
	state.Flags.credit_card_debt = ccDebt + interest
	
	-- Minimum payment required ($25 or 2% of balance, whichever is higher)
	local minPayment = math.max(25, math.floor(ccDebt * 0.02))
	local money = state.Money or 0
	
	if money >= minPayment then
		state.Money = money - minPayment
		state.Flags.credit_card_debt = math.max(0, state.Flags.credit_card_debt - minPayment)
	else
		-- Missed payment - extra penalties
		state.Flags.credit_card_debt = state.Flags.credit_card_debt + 35 -- Late fee
		state.Flags.bad_credit = true
		self:logYearEvent(state, "financial", 
			"💳 Missed credit card payment! Late fees and credit damage.", "💸")
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #22: Business Income Collection
-- Owned businesses should generate (or lose) income annually
-- Without this, businesses are static investments
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:collectBusinessIncome(state)
	state.Assets = state.Assets or {}
	local businesses = state.Assets.Businesses or {}
	
	if #businesses == 0 then
		return
	end
	
	local totalIncome = 0
	local totalEmployeeCosts = 0
	
	for _, biz in ipairs(businesses) do
		if biz.value and biz.value > 0 then
			-- ═══════════════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX (deep-18): Business income scales with employees!
			-- More employees = more revenue potential but also higher costs
			-- ═══════════════════════════════════════════════════════════════════════════════
			local employeeCount = biz.employees or 0
			local baseReturn = 0.15 -- 15% base return
			
			-- Employee scaling - more employees = higher potential return
			local employeeBonus = math.min(0.15, employeeCount * 0.01) -- Up to +15% bonus for 15+ employees
			local totalReturn = baseReturn + employeeBonus
			
			-- Business income is volatile: -20% to +40% of value annually
			local performanceMultiplier = RANDOM:NextNumber() * 0.60 - 0.20 -- -20% to +40%
			
			-- Employee productivity affects performance
			if employeeCount > 0 then
				local avgSkill = biz.employeeSkill or RANDOM:NextInteger(40, 80)
				performanceMultiplier = performanceMultiplier * (avgSkill / 60) -- Scale by avg skill
			end
			
			local grossIncome = math.floor(biz.value * performanceMultiplier * totalReturn)
			
			-- Calculate employee costs (salaries)
			local avgSalary = biz.avgEmployeeSalary or 35000
			local employeeCosts = employeeCount * avgSalary
			totalEmployeeCosts = totalEmployeeCosts + employeeCosts
			
			local annualIncome = grossIncome - employeeCosts
			
			-- Track business performance
			biz.lastYearProfit = annualIncome
			biz.lastYearRevenue = grossIncome
			biz.lastYearCosts = employeeCosts
			
			if annualIncome > 0 then
				totalIncome = totalIncome + annualIncome
				-- Good year - business grows
				biz.value = math.floor(biz.value * (1 + RANDOM:NextNumber() * 0.05)) -- Up to 5% growth
				
				-- Businesses can hire more employees when doing well
				if RANDOM:NextNumber() < 0.3 and annualIncome > 50000 then
					biz.employees = (biz.employees or 0) + RANDOM:NextInteger(1, 3)
				end
			elseif annualIncome < 0 then
				-- Bad year - might need to layoff employees
				biz.value = math.max(100, math.floor(biz.value * (1 - RANDOM:NextNumber() * 0.1))) -- Up to 10% decline
				
				-- May have to lay off employees
				if biz.employees and biz.employees > 0 and RANDOM:NextNumber() < 0.4 then
					local layoffs = math.min(biz.employees, RANDOM:NextInteger(1, 3))
					biz.employees = biz.employees - layoffs
				end
			end
		end
	end
	
	if totalIncome > 0 then
		state.Money = (state.Money or 0) + totalIncome
		-- CRITICAL FIX #156: Use YearLog for business income instead of logYearEvent
		-- This ensures it shows up in the feed consistently with other income
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "business_income",
			emoji = "💼",
			text = string.format("Businesses generated $%s in profit", formatMoney(totalIncome)),
			amount = totalIncome,
		})
	elseif totalIncome < 0 then
		-- Business losses
		local loss = math.abs(totalIncome)
		if (state.Money or 0) >= loss then
			state.Money = state.Money - loss
			-- CRITICAL FIX #157: Use YearLog for business losses
			state.YearLog = state.YearLog or {}
			table.insert(state.YearLog, {
				type = "business_loss",
				emoji = "📉",
				text = string.format("Businesses lost $%s this year", formatMoney(loss)),
				amount = -loss,
			})
		else
			state.YearLog = state.YearLog or {}
			table.insert(state.YearLog, {
				type = "business_struggling",
				emoji = "📉",
				text = "Businesses are struggling financially",
				amount = 0,
			})
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #23: Mortgage Payment Tracking
-- Home mortgages should require monthly payments
-- Without this, owning a home has no ongoing cost
-- ═══════════════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX (deep-20): CHILD SUPPORT PAYMENTS
-- Divorced parents must pay child support until children turn 18
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyChildSupport(state)
	if not state.Flags or not state.Flags.pays_child_support then
		return
	end
	
	local childSupportAmount = state.Flags.child_support_amount or 0
	if childSupportAmount <= 0 then
		state.Flags.pays_child_support = nil
		return
	end
	
	-- Check if any children are still minors
	local minorChildCount = 0
	for relId, rel in pairs(state.Relationships or {}) do
		if type(rel) == "table" then
			local role = (rel.role or ""):lower()
			if role:find("son") or role:find("daughter") or role:find("child") then
				if rel.age and rel.age < 18 and rel.alive ~= false then
					minorChildCount = minorChildCount + 1
				end
			end
		end
	end
	
	if minorChildCount == 0 then
		-- All children are adults, no more child support
		state.Flags.pays_child_support = nil
		state.Flags.child_support_amount = nil
		state.Flags.child_support_children = nil
		
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "child_support_ended",
			emoji = "✅",
			text = "Child support obligations have ended - all children are now adults!",
			amount = 0,
		})
		return
	end
	
	-- Recalculate based on current number of minor children
	local perChildAmount = (state.Flags.child_support_children or 1) > 0 and 
		childSupportAmount / state.Flags.child_support_children or childSupportAmount
	local currentPayment = math.floor(perChildAmount * minorChildCount)
	
	-- Deduct child support
	local canPay = math.min(currentPayment, state.Money or 0)
	state.Money = (state.Money or 0) - canPay
	
	state.YearLog = state.YearLog or {}
	if canPay < currentPayment then
		-- Couldn't afford full payment
		state.Flags.child_support_arrears = (state.Flags.child_support_arrears or 0) + (currentPayment - canPay)
		table.insert(state.YearLog, {
			type = "child_support_partial",
			emoji = "⚠️",
			text = string.format("Paid $%s of $%s child support. You're falling behind!", formatMoney(canPay), formatMoney(currentPayment)),
			amount = -canPay,
		})
	else
		table.insert(state.YearLog, {
			type = "child_support",
			emoji = "👶",
			text = string.format("Paid $%s in child support for %d child(ren)", formatMoney(canPay), minorChildCount),
			amount = -canPay,
		})
	end
end

function LifeBackend:applyMortgagePayments(state)
	state.Flags = state.Flags or {}
	
	local mortgageDebt = state.Flags.mortgage_debt or 0
	if mortgageDebt <= 0 then
		return
	end
	
	-- Mortgage interest is typically 3-7% APR
	local interestRate = 0.05 -- 5% average
	local monthlyInterest = math.floor(mortgageDebt * interestRate / 12)
	local monthlyPrincipal = math.floor(mortgageDebt / 360) -- 30-year mortgage
	local annualPayment = (monthlyInterest + monthlyPrincipal) * 12
	
	local money = state.Money or 0
	
	if money >= annualPayment then
		state.Money = money - annualPayment
		state.Flags.mortgage_debt = math.max(0, mortgageDebt - (monthlyPrincipal * 12))
		
		-- CRITICAL FIX #160: Log mortgage payments to YearLog
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "mortgage",
			emoji = "🏠",
			text = string.format("Paid $%s in mortgage", formatMoney(annualPayment)),
			amount = -annualPayment,
		})
		
		if state.Flags.mortgage_debt <= 0 then
			state.Flags.mortgage_debt = nil
			state.Flags.mortgage_paid_off = true
			-- CRITICAL FIX #161: Show mortgage payoff celebration in YearLog
			table.insert(state.YearLog, {
				type = "mortgage_payoff",
				emoji = "🎉",
				text = "Paid off your mortgage! You own your home free and clear!",
				amount = 0,
			})
		end
	else
		-- Can't afford mortgage
		state.Flags.mortgage_trouble = true
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "mortgage_trouble",
			emoji = "⚠️",
			text = "Struggling to make mortgage payments",
			amount = 0,
		})
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #24: Update Child Roles As They Grow
-- Children should transition from "Son/Daughter" to "Teenage" to "Adult"
-- 
-- NOTE: Aging and death checks are ONLY done in advanceRelationships() now!
-- Previously this function duplicated that work, causing:
--   1. Family members aging 2x per year
--   2. Family members getting 2x death rolls per year
-- This was why parents died when the player was only 21-23 years old!
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:ageRelationships(state)
	if not state.Relationships then
		return
	end
	
	for relId, rel in pairs(state.Relationships) do
		if type(rel) == "table" and rel.alive ~= false then
			-- REMOVED: Duplicate aging - advanceRelationships() already ages everyone
			-- REMOVED: Duplicate death checks - advanceRelationships() already handles this
			
			-- Children grow up and their role description changes
			if rel.isChild and rel.age then
				-- Update child role based on age
				if rel.age >= 18 then
					rel.role = rel.gender == "male" and "Adult Son" or "Adult Daughter"
					rel.isChild = nil
					rel.isAdult = true
				elseif rel.age >= 13 then
					rel.role = rel.gender == "male" and "Teenage Son" or "Teenage Daughter"
				end
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #25: Health Insurance Costs
-- Adults without employer health insurance should pay for it
-- Without this, healthcare has no ongoing cost except emergencies
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyHealthInsuranceCosts(state)
	-- Only applies to adults
	if (state.Age or 0) < 18 then
		return
	end
	
	-- Skip if in prison (state provides healthcare)
	if state.InJail then
		return
	end
	
	state.Flags = state.Flags or {}
	
	-- Check if employed (employer provides insurance)
	if state.CurrentJob then
		-- Employed - partial insurance cost
		local employeeShare = 2400 -- $200/month employee contribution
		if (state.Money or 0) >= employeeShare then
			state.Money = state.Money - employeeShare
		end
		state.Flags.has_health_insurance = true
		return
	end
	
	-- Unemployed - need to buy own insurance or go without
	if state.Flags.has_health_insurance then
		-- Self-paid insurance: ~$6000/year for individual
		local insuranceCost = 6000
		if state.Age >= 50 then
			insuranceCost = 9000 -- Higher premiums for older adults
		end
		
		if (state.Money or 0) >= insuranceCost then
			state.Money = state.Money - insuranceCost
		else
			-- Can't afford insurance
			state.Flags.has_health_insurance = nil
			state.Flags.uninsured = true
		end
	else
		-- Uninsured - risk of catastrophic costs
		state.Flags.uninsured = true
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #31: Car Loan Payment System
-- Vehicle purchases can be financed with loans that need monthly payments
-- Without this, car loans are just flags with no financial impact
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyCarLoanPayments(state)
	state.Flags = state.Flags or {}
	
	local carLoanBalance = state.Flags.car_loan_balance or 0
	if carLoanBalance <= 0 then
		return
	end
	
	-- Car loan interest is typically 4-10% APR
	local interestRate = state.Flags.bad_credit and 0.12 or 0.06 -- Higher rate if bad credit
	local monthlyPayment = state.Flags.car_loan_payment or math.floor(carLoanBalance / 48) -- 4-year loan default
	local annualInterest = math.floor(carLoanBalance * interestRate)
	local annualPayment = monthlyPayment * 12
	
	local money = state.Money or 0
	
	if money >= annualPayment then
		state.Money = money - annualPayment
		-- Principal reduction (payment minus interest portion)
		local principalPaid = math.max(0, annualPayment - annualInterest)
		state.Flags.car_loan_balance = math.max(0, carLoanBalance - principalPaid)
		
		if state.Flags.car_loan_balance <= 0 then
			state.Flags.car_loan_balance = nil
			state.Flags.car_loan_payment = nil
			state.Flags.has_car_loan = nil
			self:logYearEvent(state, "financial",
				"🚗 Car loan paid off! The vehicle is fully yours!", "🎉")
		end
	else
		-- Can't afford car payment
		state.Flags.car_payment_trouble = true
		-- Repo risk
		local repoChance = 0.20
		if RANDOM:NextNumber() < repoChance then
			-- Car repossessed
			if state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0 then
				-- Remove the financed vehicle
				for i, v in ipairs(state.Assets.Vehicles) do
					if v.financed then
						table.remove(state.Assets.Vehicles, i)
						break
					end
				end
			end
			state.Flags.car_loan_balance = nil
			state.Flags.car_loan_payment = nil
			state.Flags.has_car_loan = nil
			state.Flags.car_repossessed = true
			state.Flags.bad_credit = true
			self:logYearEvent(state, "financial",
				"🚗 Car repossessed! Couldn't make the payments.", "😔")
		else
			self:logYearEvent(state, "financial",
				"🚗 Warning: Struggling to make car payments!", "⚠️")
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #32: Addiction System with Consequences
-- Addictions should have escalating consequences over time
-- Without this, addictions are just flags with no gameplay impact
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:processAddictions(state)
	state.Flags = state.Flags or {}
	state.Stats = state.Stats or {}
	
	-- CRITICAL FIX #29: Increased addiction recovery chances (were too low!)
	-- Old chances made recovery nearly impossible, frustrating players
	local addictions = {
		smoking = {
			healthCost = 2,
			moneyCost = 1500, -- Pack-a-day habit
			quitDifficulty = 0.18, -- CRITICAL FIX #29: Was 0.15, now 18% chance
		},
		heavy_drinking = {
			healthCost = 3,
			happinessCost = 2,
			moneyCost = 2500,
			quitDifficulty = 0.15, -- CRITICAL FIX #29: Was 0.12, now 15% chance
		},
		alcoholic = {
			healthCost = 5,
			happinessCost = 4,
			moneyCost = 4000,
			quitDifficulty = 0.12, -- CRITICAL FIX #29: Was 0.08, now 12% chance
			canLoseJob = true,
		},
		-- REMOVED: gambling_addiction (against Roblox TOS)
		spending_addiction = {
			happinessCost = 5,
			moneyCost = function(state) return math.floor((state.Money or 0) * 0.10) end, -- Compulsive spending
			quitDifficulty = 0.14,
		},
		substance_user = {
			healthCost = 4,
			happinessCost = 3,
			moneyCost = 3000,
			quitDifficulty = 0.12, -- CRITICAL FIX #29: Was 0.10, now 12% chance
			canGetArrested = true,
		},
		substance_addict = {
			healthCost = 8,
			happinessCost = 6,
			smartsCost = 2,
			moneyCost = 8000,
			quitDifficulty = 0.08, -- CRITICAL FIX #29: Was 0.05, now 8% chance (still hard, but possible)
			canGetArrested = true,
			canOverdose = true,
		},
	}
	
	-- CRITICAL FIX #29B: Boost recovery chance if player has been to rehab or is actively trying to quit
	local rehabBoost = 0
	if state.Flags.in_rehab or state.Flags.attending_aa or state.Flags.seeking_help then
		rehabBoost = 0.15 -- 15% bonus to quit chance if actively seeking help
	end
	if state.Flags.completed_rehab then
		rehabBoost = rehabBoost + 0.10 -- Additional 10% if completed rehab
	end
	
	for addictionName, addiction in pairs(addictions) do
		if state.Flags[addictionName] then
			-- Apply health cost
			if addiction.healthCost then
				state.Stats.Health = clamp((state.Stats.Health or 50) - addiction.healthCost, 0, 100)
			end
			
			-- Apply happiness cost
			if addiction.happinessCost then
				state.Stats.Happiness = clamp((state.Stats.Happiness or 50) - addiction.happinessCost, 0, 100)
			end
			
			-- Apply smarts cost (brain damage from substance abuse)
			if addiction.smartsCost then
				state.Stats.Smarts = clamp((state.Stats.Smarts or 50) - addiction.smartsCost, 0, 100)
			end
			
			-- Apply money cost
			local moneyCost = addiction.moneyCost
			if type(moneyCost) == "function" then
				moneyCost = moneyCost(state)
			end
			state.Money = math.max(0, (state.Money or 0) - moneyCost)
			
			-- Chance to lose job
			if addiction.canLoseJob and state.CurrentJob and RANDOM:NextNumber() < 0.15 then
				state.CurrentJob = nil
				state.Flags.employed = nil
				state.Flags.has_job = nil
				state.Flags.fired_for_addiction = true
				self:logYearEvent(state, "career",
					"💼 Lost job due to addiction problems.", "😔")
			end
			
			-- Chance to get arrested (illegal substances)
			if addiction.canGetArrested and RANDOM:NextNumber() < 0.08 then
				state.Flags.arrested = true
				state.Flags.criminal_record = true
				self:logYearEvent(state, "legal",
					"🚔 Arrested for illegal activity!", "⚠️")
			end
			
			-- Chance to overdose (severe addiction)
			if addiction.canOverdose and RANDOM:NextNumber() < 0.03 then
				state.Stats.Health = clamp((state.Stats.Health or 50) - 30, 0, 100)
				if state.Stats.Health <= 0 then
					state.Flags.dead = true
					state.DeathReason = "Substance overdose"
				else
					state.Flags.overdose_survivor = true
					self:logYearEvent(state, "health",
						"💊 Overdosed but survived. Wake-up call.", "🏥")
				end
			end
			
			-- Random chance to try to quit (with rehab boost)
			-- CRITICAL FIX #29: Apply rehab boost to recovery chance
			local finalQuitChance = addiction.quitDifficulty + rehabBoost
			
			-- CRITICAL FIX #29C: High health and happiness also help recovery
			local healthBonus = ((state.Stats.Health or 50) - 50) / 500 -- Up to +10% at 100 health
			local happinessBonus = ((state.Stats.Happiness or 50) - 50) / 500 -- Up to +10% at 100 happiness
			finalQuitChance = finalQuitChance + healthBonus + happinessBonus
			
			-- Cap at 50% max chance (still need some difficulty)
			finalQuitChance = math.min(0.50, finalQuitChance)
			
			if RANDOM:NextNumber() < finalQuitChance then
				state.Flags[addictionName] = nil
				state.Flags[addictionName .. "_recovered"] = true
				-- Clear rehab flags after successful recovery
				state.Flags.in_rehab = nil
				self:logYearEvent(state, "health",
					string.format("🎉 Overcame %s! A new chapter begins.", addictionName:gsub("_", " ")), "💪")
			end
		end
	end
	
	-- CRITICAL FIX #151: Sync Stats to top-level state after addiction processing
	state.Health = state.Stats.Health
	state.Happiness = state.Stats.Happiness
	state.Smarts = state.Stats.Smarts
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #35: Natural Death System
-- Players should be able to die from old age or very low health
-- Without this, players are effectively immortal
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:checkNaturalDeath(state)
	-- Already dead
	if state.Flags and state.Flags.dead then
		return
	end
	
	state.Stats = state.Stats or {}
	state.Flags = state.Flags or {}
	local age = state.Age or 0
	local health = state.Stats.Health or 50
	
	-- Health-based death (very low health)
	if health <= 0 then
		state.Flags.dead = true
		state.DeathReason = state.DeathReason or "Health complications"
		state.DeathAge = age
		state.DeathYear = state.Year
		return
	end
	
	-- Critical health warning
	if health <= 10 then
		self:logYearEvent(state, "health",
			"⚠️ Health is critical! Seek medical attention immediately.", "🏥")
	end
	
	-- Age-based death chance (increases with age)
	if age >= 65 then
		local baseMortality = 0 -- No random death before 65
		
		-- Life expectancy calculations
		-- 65-70: Very low chance
		-- 70-80: Low chance
		-- 80-90: Moderate chance
		-- 90-100: High chance
		-- 100+: Very high chance
		
		if age >= 65 and age < 70 then
			baseMortality = 0.005 -- 0.5% per year
		elseif age >= 70 and age < 80 then
			baseMortality = 0.02 -- 2% per year
		elseif age >= 80 and age < 90 then
			baseMortality = 0.06 -- 6% per year
		elseif age >= 90 and age < 100 then
			baseMortality = 0.15 -- 15% per year
		elseif age >= 100 then
			baseMortality = 0.30 -- 30% per year
		end
		
		-- Health modifies mortality
		-- Good health (>70) reduces mortality by 50%
		-- Poor health (<30) increases mortality by 100%
		local healthModifier = 1.0
		if health > 70 then
			healthModifier = 0.5
		elseif health < 30 then
			healthModifier = 2.0
		end
		
		-- Lifestyle factors
		local lifestyleModifier = 1.0
		if state.Flags.fitness_enthusiast or state.Flags.healthy_lifestyle then
			lifestyleModifier = lifestyleModifier * 0.7 -- 30% reduction
		end
		if state.Flags.smoking or state.Flags.heavy_drinking then
			lifestyleModifier = lifestyleModifier * 1.5 -- 50% increase
		end
		if state.Flags.substance_addict or state.Flags.alcoholic then
			lifestyleModifier = lifestyleModifier * 2.0 -- 100% increase
		end
		
		local finalMortality = baseMortality * healthModifier * lifestyleModifier
		
		if RANDOM:NextNumber() < finalMortality then
			state.Flags.dead = true
			state.DeathAge = age
			state.DeathYear = state.Year
			
			-- Generate death reason based on age/health
			local deathReasons
			if age >= 90 then
				deathReasons = {
					"Natural causes",
					"Passed peacefully in sleep",
					"Old age",
					"Heart gave out",
				}
			elseif health < 30 then
				deathReasons = {
					"Health complications",
					"Organ failure",
					"Medical emergency",
					"Chronic illness",
				}
			else
				deathReasons = {
					"Natural causes",
					"Heart attack",
					"Stroke",
					"Unexpected illness",
				}
			end
			
			state.DeathReason = deathReasons[RANDOM:NextInteger(1, #deathReasons)]
		end
	end
end

function LifeBackend:generateEvent(player, state)
	local triggers = {}
	if state.Age < 13 then
		table.insert(triggers, "childhood")
	elseif state.Age < 18 then
		table.insert(triggers, "teen")
	end

	if state.CurrentJob then
		local job = JobCatalog[state.CurrentJob.id or state.CurrentJob]
		if job and job.category then
			table.insert(triggers, "career_" .. job.category)
		end
	end

	-- Criminal and Black Hat Hacker careers trigger crime events
	if state.CurrentJob then
		local job = JobCatalog[state.CurrentJob.id or state.CurrentJob]
		if job and (job.category == "criminal" or (job.category == "hacker" and job.illegal)) then
			table.insert(triggers, "crime")
		end
	end
	
	-- Criminal story path also triggers crime events
	if state.ActivePath == "criminal" then
		table.insert(triggers, "crime")
	end

	if state.Relationships and state.Relationships.partner then
		table.insert(triggers, "romance")
	end

	local pool = flattenEventPools(triggers)
	return chooseRandom(pool)
end

-- ============================================================================
-- CRITICAL FIX: Text variable replacement for dynamic content in events
-- Replaces placeholders like {{PARTNER_NAME}}, {{PLAYER_NAME}}, {{AGE}}, etc.
-- ============================================================================
function LifeBackend:replaceTextVariables(text, state)
	if not text or type(text) ~= "string" then
		return text
	end
	
	local result = text
	
	-- Partner name replacement
	if state.Relationships and state.Relationships.partner then
		local partnerName = state.Relationships.partner.name or "your partner"
		result = result:gsub("{{PARTNER_NAME}}", partnerName)
		result = result:gsub("{{PARTNER}}", partnerName)
		result = result:gsub("your partner", partnerName) -- Also replace generic "your partner" with actual name
		result = result:gsub("Your partner", partnerName)
	else
		result = result:gsub("{{PARTNER_NAME}}", "your partner")
		result = result:gsub("{{PARTNER}}", "someone special")
	end
	
	-- Player name replacement  
	local playerName = state.Name or "You"
	local honorific = (state.Gender == "female") and "Ms." or "Mr."
	
	-- CRITICAL FIX: Replace combined patterns FIRST before individual replacements
	result = result:gsub("Mr%./Ms%. %[YOUR NAME%]", honorific .. " " .. playerName)
	result = result:gsub("Mr%./Ms%. {{NAME}}", honorific .. " " .. playerName)
	result = result:gsub("Mr%./Ms%. {{PLAYER_NAME}}", honorific .. " " .. playerName)
	
	-- Then replace standalone patterns
	result = result:gsub("{{PLAYER_NAME}}", playerName)
	result = result:gsub("{{NAME}}", playerName)
	result = result:gsub("%[YOUR NAME%]", playerName)
	result = result:gsub("%[your name%]", playerName)
	result = result:gsub("Mr%./Ms%.", honorific)
	
	-- Age replacement
	local age = state.Age or 0
	result = result:gsub("{{AGE}}", tostring(age))
	-- CRITICAL FIX #102/#109: Also handle %d format for backward compatibility
	result = result:gsub("%%d years old", tostring(age) .. " years old")
	result = result:gsub("At %%d", "At " .. tostring(age))
	
	-- Job/company replacement
	if state.CurrentJob then
		result = result:gsub("{{JOB_NAME}}", state.CurrentJob.name or "your job")
		result = result:gsub("{{COMPANY}}", state.CurrentJob.company or "your employer")
	end
	
	-- Mother/Father name replacement
	-- CRITICAL FIX: Ultra-robust relationship name handling with multiple fallbacks
	local motherName = "Mom"
	local fatherName = "Dad"
	
	-- Try to get parent names from relationships
	local success, extractedNames = pcall(function()
		if state.Relationships then
			-- Try multiple ways to access relationships (in case of different storage formats)
			local mother = state.Relationships.mother or state.Relationships["mother"]
			local father = state.Relationships.father or state.Relationships["father"]
			
			local extractedMom = "Mom"
			local extractedDad = "Dad"
			
			if mother and type(mother) == "table" then
				extractedMom = mother.name or mother.Name or "Mom"
			end
			if father and type(father) == "table" then
				extractedDad = father.name or father.Name or "Dad"
			end
			
			return { mom = extractedMom, dad = extractedDad }
		end
		return { mom = "Mom", dad = "Dad" }
	end)
	
	if success and extractedNames then
		motherName = extractedNames.mom or "Mom"
		fatherName = extractedNames.dad or "Dad"
	end
	
	-- CRITICAL FIX: Friend name lookup with pcall protection
	if state.Relationships then
		pcall(function()
			for relId, rel in pairs(state.Relationships) do
				if type(rel) == "table" and rel.type == "friend" then
					result = result:gsub("{{FRIEND_NAME}}", rel.name or "your friend")
					break
				end
			end
		end)
	end
	
	-- CRITICAL FIX: Always replace placeholders with multiple pattern variations
	-- This prevents {{FATHER_NAME}} from appearing literally in game text
	-- Try both escaped and unescaped patterns for maximum compatibility
	result = result:gsub("{{MOTHER_NAME}}", motherName)
	result = result:gsub("{{FATHER_NAME}}", fatherName)
	-- Escaped pattern versions (Lua pattern special chars)
	result = result:gsub("%%{%%{MOTHER_NAME%%}%%}", motherName)
	result = result:gsub("%%{%%{FATHER_NAME%%}%%}", fatherName)
	-- Generic parent terms
	result = result:gsub("Your mother", motherName)
	result = result:gsub("Your father", fatherName)
	result = result:gsub("your mother", motherName:lower())
	result = result:gsub("your father", fatherName:lower())
	result = result:gsub("Your dad", fatherName)
	result = result:gsub("your dad", fatherName:lower())
	result = result:gsub("Your mom", motherName)
	result = result:gsub("your mom", motherName:lower())
	
	-- Fallback for friend name if no friend found
	result = result:gsub("{{FRIEND_NAME}}", "your friend")
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Add more dynamic placeholders for realistic events
	-- These prevent hardcoded text like "You're 38 with 2 kids"
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Money/salary replacement
	local money = state.Money or 0
	result = result:gsub("{{MONEY}}", formatMoney(money))
	result = result:gsub("{{SAVINGS}}", formatMoney(money))
	if state.CurrentJob then
		result = result:gsub("{{SALARY}}", formatMoney(state.CurrentJob.salary or 0))
		result = result:gsub("{{COMPANY}}", state.CurrentJob.company or "your employer")
	else
		-- CRITICAL FIX: Fallback for SALARY and COMPANY when unemployed
		result = result:gsub("{{SALARY}}", "$0")
		result = result:gsub("{{COMPANY}}", "your last employer")
	end
	
	-- Family status replacement
	local familyParts = {}
	if state.Flags and (state.Flags.has_child or state.Flags.parent) then
		-- CRITICAL FIX #153: Count children from relationships instead of ChildCount
		local childCount = 0
		if state.Relationships then
			for _, rel in pairs(state.Relationships) do
				if type(rel) == "table" and rel.isChild then
					childCount = childCount + 1
				end
			end
		end
		if childCount > 0 then
			table.insert(familyParts, childCount == 1 and "a child" or (childCount .. " kids"))
		else
			table.insert(familyParts, "children")
		end
	end
	if state.Flags and (state.Flags.married or state.Flags.has_partner) then
		table.insert(familyParts, "a spouse")
	end
	if state.Assets and state.Assets.Properties and #state.Assets.Properties > 0 then
		table.insert(familyParts, "a mortgage")
	end
	
	local familyStatus = ""
	if #familyParts > 0 then
		familyStatus = "You're " .. tostring(age) .. " with " .. table.concat(familyParts, " and ") .. "."
	else
		familyStatus = "You're " .. tostring(age) .. " years old."
	end
	result = result:gsub("{{FAMILY_STATUS}}", familyStatus)
	
	-- Life stage
	local stage = "adult"
	if age < 5 then stage = "toddler"
	elseif age < 13 then stage = "child"
	elseif age < 18 then stage = "teenager"
	elseif age < 30 then stage = "young adult"
	elseif age < 50 then stage = "adult"
	elseif age < 65 then stage = "middle-aged"
	else stage = "senior"
	end
	result = result:gsub("{{LIFE_STAGE}}", stage)
	
	-- Years at job
	if state.CareerInfo and state.CareerInfo.yearsAtJob then
		result = result:gsub("{{YEARS_AT_JOB}}", tostring(state.CareerInfo.yearsAtJob))
	else
		result = result:gsub("{{YEARS_AT_JOB}}", "several")
	end
	
	return result
end

function LifeBackend:presentEvent(player, eventDef, feedText)
	if not eventDef then
		self:pushState(player, feedText)
		return
	end
	
	local state = self:getState(player)

	local eventId = (eventDef.id or "event") .. "_" .. HttpService:GenerateGUID(false)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #13: Apply text variations for replayability!
	-- User feedback: "every single life is the same exact stuff"
	-- Each playthrough should have different phrasing of events
	-- ═══════════════════════════════════════════════════════════════════════════════
	local eventText = eventDef.text
	local eventTitle = eventDef.title
	local eventQuestion = eventDef.question
	
	-- Apply text variations if available
	if eventDef.textVariants and type(eventDef.textVariants) == "table" and #eventDef.textVariants > 0 then
		eventText = eventDef.textVariants[math.random(1, #eventDef.textVariants)]
	end
	if eventDef.titleVariants and type(eventDef.titleVariants) == "table" and #eventDef.titleVariants > 0 then
		eventTitle = eventDef.titleVariants[math.random(1, #eventDef.titleVariants)]
	end
	if eventDef.questionVariants and type(eventDef.questionVariants) == "table" and #eventDef.questionVariants > 0 then
		eventQuestion = eventDef.questionVariants[math.random(1, #eventDef.questionVariants)]
	end
	
	-- CRITICAL FIX: Process getDynamicText for events with dynamic content
	if eventDef.getDynamicText and type(eventDef.getDynamicText) == "function" then
		local success, dynamicData = pcall(eventDef.getDynamicText, state)
		if success and dynamicData then
			if dynamicData.text then
				eventText = dynamicData.text
			end
			-- Store dynamic data for use in choice resolution
			eventDef._dynamicData = dynamicData
		end
	end
	
	-- CRITICAL FIX: Replace text variables with actual names
	local processedText = self:replaceTextVariables(eventText, state)
	local processedTitle = self:replaceTextVariables(eventTitle, state)
	local processedQuestion = self:replaceTextVariables(eventQuestion or "What will you do?", state)
	
	local eventPayload = {
		id = eventId,
		title = processedTitle,
		emoji = eventDef.emoji,
		text = processedText,
		question = processedQuestion,
		category = eventDef.category or "life",
		choices = {},
	}

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #503: Include premium choice info in serialization
	-- This allows the client to display premium choices with appropriate styling
	-- (e.g., show gamepass emoji, lock icon for unowned, different color)
	-- ═══════════════════════════════════════════════════════════════════════════════
	local flags = state and state.Flags or {}
	local gamepassOwnership = state and state.GamepassOwnership or {}
	
	for index, choice in ipairs(eventDef.choices or {}) do
		local choiceData = {
			index = index,
			text = self:replaceTextVariables(choice.text or ("Choice " .. index), state),
			minigame = choice.minigame,
		}
		
		-- Add premium choice info if this choice requires a gamepass
		if choice.requiresGamepass then
			choiceData.requiresGamepass = choice.requiresGamepass
			choiceData.gamepassEmoji = choice.gamepassEmoji
			
			-- Check if player owns this gamepass
			local gamepassToFlag = {
				GOD_MODE = "god_mode_gamepass",
				MAFIA = "mafia_gamepass", 
				CELEBRITY = "celebrity_gamepass",
				ROYALTY = "royalty_gamepass",
				TIME_MACHINE = "time_machine_gamepass",
			}
			local gamepassToOwnership = {
				GOD_MODE = "godMode",
				MAFIA = "mafia",
				CELEBRITY = "celebrity",
				ROYALTY = "royalty",
				TIME_MACHINE = "timeMachine",
			}
			
			local flagName = gamepassToFlag[choice.requiresGamepass]
			local ownershipName = gamepassToOwnership[choice.requiresGamepass]
			local hasGamepass = flags[flagName] or gamepassOwnership[ownershipName]
			
			choiceData.hasGamepass = hasGamepass
			
			-- Also check additional flag requirements (e.g., must be in mob for mafia options)
			if choice.requiresFlags and hasGamepass then
				for flagName, requiredValue in pairs(choice.requiresFlags) do
					if requiredValue == true and not flags[flagName] then
						choiceData.hasGamepass = false
						choiceData.missingRequirement = true
						break
					end
				end
			end
		end
		
		eventPayload.choices[index] = choiceData
	end

	local pending = self.pendingEvents[player.UserId] or {}
	pending.activeEventId = eventId
	pending.definition = eventDef
	pending.choices = eventDef.choices
	pending.timestamp = os.clock()
	pending.feedText = feedText or pending.feedText
	self.pendingEvents[player.UserId] = pending

	self.remotes.PresentEvent:FireClient(player, eventPayload, feedText)
end

-- ============================================================================
-- CRITICAL FIX: Log significant events that occur during the year
-- These get used in the year summary instead of random generic messages
-- ============================================================================
function LifeBackend:logYearEvent(state, eventType, description, emoji)
	state.YearLog = state.YearLog or {}
	table.insert(state.YearLog, {
		type = eventType,
		text = description,
		emoji = emoji or "📌",
		age = state.Age,
	})
end

-- ============================================================================
-- CRITICAL FIX: BitLife-style year summaries using ACTUAL event history
-- Uses logged events from the year instead of random generic messages
-- ============================================================================
function LifeBackend:generateYearSummary(state)
	local age = state.Age or 0
	local summaryParts = {}
	local emoji = "📅"
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: First check for actual logged events from this year
	-- This replaces random generic messages with real event descriptions
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.YearLog and #state.YearLog > 0 then
		-- Use actual events that happened
		for _, logEntry in ipairs(state.YearLog) do
			if logEntry.text and logEntry.text ~= "" then
				table.insert(summaryParts, logEntry.text)
				if logEntry.emoji then
					emoji = logEntry.emoji
				end
			end
		end
		-- Clear the year log after using it
		state.YearLog = {}
		
		-- If we have actual events, use them and skip random filler
		if #summaryParts > 0 then
			local maxParts = math.min(#summaryParts, 3)
			local finalParts = {}
			for i = 1, maxParts do
				table.insert(finalParts, summaryParts[i])
			end
			return string.format("%s Age %d: %s", emoji, age, table.concat(finalParts, " "))
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- Fallback: No specific events logged, use context-aware generic summary
	-- These should only appear when genuinely nothing notable happened
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Check for specific life situations first (these ARE real, not random)
	if state.Flags then
		-- Divorce just happened
		if state.Flags.parents_divorced and not state.Flags.divorce_acknowledged then
			table.insert(summaryParts, "Your parents have separated. Your family dynamic has changed.")
			emoji = "💔"
			state.Flags.divorce_acknowledged = true
		end
		
		-- Just got married
		if state.Flags.just_married then
			local partnerName = state.Relationships and state.Relationships.partner and state.Relationships.partner.name or "your partner"
			table.insert(summaryParts, string.format("You married %s!", partnerName))
			emoji = "💒"
			state.Flags.just_married = nil
		end
		
		-- Just had a baby
		if state.Flags.just_had_baby then
			table.insert(summaryParts, "You became a parent!")
			emoji = "👶"
			state.Flags.just_had_baby = nil
		end
		
		-- Just got promoted
		if state.Flags.just_promoted then
			table.insert(summaryParts, "You earned a promotion at work!")
			emoji = "📈"
			state.Flags.just_promoted = nil
		end
	end
	
	-- If we found real situation-based summaries, return them
	if #summaryParts > 0 then
		return string.format("%s Age %d: %s", emoji, age, table.concat(summaryParts, " "))
	end
	
	-- Age-based generic context (only if nothing specific happened)
	local ageContext = ""
	if age <= 4 then
		local toddlerLines = {
			"Another year of growing up.",
			"Learning new things every day.",
			"Time flies when you're little.",
		}
		ageContext = toddlerLines[RANDOM:NextInteger(1, #toddlerLines)]
		emoji = "👶"
	elseif age <= 12 then
		local childLines = {
			"School keeps you busy.",
			"Another year of growing up.",
			"Childhood continues.",
		}
		ageContext = childLines[RANDOM:NextInteger(1, #childLines)]
		emoji = "🧒"
	elseif age <= 17 then
		local teenLines = {
			"Another year of high school.",
			"Teen life continues.",
			"Growing up fast.",
		}
		ageContext = teenLines[RANDOM:NextInteger(1, #teenLines)]
		emoji = "🎒"
	elseif age <= 25 then
		local youngAdultLines = {
			"Building your future.",
			"Young adulthood continues.",
			"Finding your path.",
		}
		ageContext = youngAdultLines[RANDOM:NextInteger(1, #youngAdultLines)]
		emoji = "🌟"
	elseif age <= 40 then
		local adultLines = {
			"Life continues.",
			"Staying busy.",
			"Making progress.",
		}
		ageContext = adultLines[RANDOM:NextInteger(1, #adultLines)]
		emoji = "💼"
	elseif age <= 60 then
		local middleAgeLines = {
			"Wisdom comes with age.",
			"You've learned what matters most.",
			"Life experience is your greatest asset.",
			"The years fly by faster now.",
			"You're in the prime of your life.",
		}
		ageContext = middleAgeLines[RANDOM:NextInteger(1, #middleAgeLines)]
		emoji = "🍷"
	else
		local seniorLines = {
			"You've lived a full life.",
			"Every day is a blessing.",
			"You have stories to tell.",
			"Reflecting on a life well lived.",
			"Cherishing the golden years.",
		}
		ageContext = seniorLines[RANDOM:NextInteger(1, #seniorLines)]
		emoji = "👴"
	end
	
	table.insert(summaryParts, ageContext)
	
	-- Relationship status
	if state.Relationships and state.Relationships.partner then
		local partner = state.Relationships.partner
		local partnerName = partner.name or "your partner"
		local role = partner.role or "Partner"
		
		if state.Flags and state.Flags.married then
			local marriedLines = {
				string.format("Life with %s is good.", partnerName),
				string.format("You and %s are building a life together.", partnerName),
				string.format("Marriage keeps things interesting.", partnerName),
			}
			table.insert(summaryParts, marriedLines[RANDOM:NextInteger(1, #marriedLines)])
		elseif state.Flags and state.Flags.engaged then
			table.insert(summaryParts, string.format("You can't wait to marry %s.", partnerName))
		elseif state.Flags and state.Flags.dating then
			local datingLines = {
				string.format("Dating %s is going well.", partnerName),
				string.format("You enjoy spending time with %s.", partnerName),
			}
			table.insert(summaryParts, datingLines[RANDOM:NextInteger(1, #datingLines)])
		end
	end
	
	-- Job status (only for working-age adults)
	if age >= 18 then
		if state.CurrentJob then
			local job = state.CurrentJob
			if state.CareerInfo and (state.CareerInfo.yearsAtJob or 0) > 0 then
				local years = state.CareerInfo.yearsAtJob
				if years >= 10 then
					table.insert(summaryParts, string.format("You've been at %s for %d years now.", job.company, years))
				elseif years >= 5 then
					table.insert(summaryParts, string.format("You're well established at %s.", job.company))
				end
			else
				-- Just mention they have a job occasionally
				if RANDOM:NextNumber() < 0.3 then
					table.insert(summaryParts, string.format("Work at %s keeps you busy.", job.company))
				end
			end
		elseif age < 65 and not (state.Flags and (state.Flags.retired or state.Flags.in_school)) then
			if RANDOM:NextNumber() < 0.5 then
				table.insert(summaryParts, "You're currently between jobs.")
			end
		end
	end
	
	-- Money situation
	local money = state.Money or 0
	if money < 100 and age >= 18 then
		if RANDOM:NextNumber() < 0.4 then
			table.insert(summaryParts, "Money is tight right now.")
		end
	elseif money > 1000000 then
		if RANDOM:NextNumber() < 0.3 then
			table.insert(summaryParts, "Financial success feels good.")
		end
	end
	
	-- Health comments
	local health = state.Stats and state.Stats.Health or 50
	if health < 30 then
		table.insert(summaryParts, "Your health concerns you.")
	elseif health > 85 and RANDOM:NextNumber() < 0.2 then
		table.insert(summaryParts, "You're feeling great!")
	end
	
	-- Happiness comments
	local happiness = state.Stats and state.Stats.Happiness or 50
	if happiness < 25 then
		if RANDOM:NextNumber() < 0.5 then
			local sadLines = {
				"Things feel harder lately.",
				"You're going through a rough patch.",
				"Life feels heavy sometimes.",
			}
			table.insert(summaryParts, sadLines[RANDOM:NextInteger(1, #sadLines)])
		end
	elseif happiness > 80 and RANDOM:NextNumber() < 0.3 then
		local happyLines = {
			"Life is treating you well.",
			"You're in a good place.",
			"Happiness comes easy these days.",
		}
		table.insert(summaryParts, happyLines[RANDOM:NextInteger(1, #happyLines)])
	end
	
	-- Prison
	if state.InJail then
		emoji = "🔒"
		-- MINOR FIX: Use %.1f for consistent decimal formatting
		summaryParts = { string.format("Behind bars. %.1f years remaining.", state.JailYearsLeft or 0) }
	end
	
	-- Combine parts (max 2-3 sentences to avoid clutter)
	local maxParts = math.min(#summaryParts, 3)
	local finalParts = {}
	for i = 1, maxParts do
		table.insert(finalParts, summaryParts[i])
	end
	
	local summary = table.concat(finalParts, " ")
	if summary == "" then
		summary = "Another year passes."
	end
	
	return string.format("%s Age %d: %s", emoji, age, summary)
end

function LifeBackend:handleAgeUp(player)
	local state = self:getState(player)
	if not state or state.awaitingDecision or (state.Flags and state.Flags.dead) then
		if state and state.Flags and state.Flags.dead then
			debugPrint("Age up ignored for dead player", player.Name)
		end
		return
	end

	debugPrint(string.format("Age up requested by %s (Age %d, Year %d)", player.Name, state.Age or -1, state.Year or 0))

	local oldAge = state.Age
	if state.AdvanceAge then
		state:AdvanceAge()
	else
		state.Age = (state.Age or 0) + 1
		state.Year = (state.Year or 2025) + 1
	end

	-- ════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Clear temporary flags at start of new year
	-- These flags are meant to prevent events immediately after job changes
	-- but should expire so the player can get new job-related events after a year
	-- ════════════════════════════════════════════════════════════════════════════
	state.Flags = state.Flags or {}
	state.Flags.just_quit = nil     -- Allow job events again after quitting
	state.Flags.just_fired = nil    -- Allow job events again after being fired
	state.Flags.just_promoted = nil -- Allow promotion events again
	state.Flags.just_hired = nil    -- Allow new hire events again

	-- ════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #48: Save TimeMachine snapshots for time travel feature
	-- Snapshots are saved every 5 years, at age 0, and at age 18
	-- This allows players with TimeMachine gamepass to travel back in time
	-- ════════════════════════════════════════════════════════════════════════════
	if TimeMachine and state.Age then
		local serializedState = nil
		if state.Serialize then
			serializedState = state:Serialize()
		else
			serializedState = shallowCopy(state)
		end
		TimeMachine.saveSnapshot(player, state, serializedState)
	end

	self:advanceRelationships(state)
	self:updateEducationProgress(state)
	self:tickCareer(state)
	self:collectPropertyIncome(state) -- CRITICAL FIX: Collect passive income from owned properties
	self:collectSpouseIncome(state) -- CRITICAL FIX (deep-11): Spouse contributes to household income
	self:tickVehicleDepreciation(state) -- CRITICAL FIX #10: Vehicles lose value over time
	self:tickInvestments(state) -- CRITICAL FIX #11: Investments fluctuate in value
	self:applyLivingExpenses(state) -- CRITICAL FIX #12: Annual cost of living
	self:applyHabitEffects(state) -- CRITICAL FIX #13: Health effects from habits
	self:tickFame(state) -- CRITICAL FIX #14: Fame decays without maintenance
	self:applyDebtInterest(state) -- CRITICAL FIX #15: Student loan interest
	self:applyEducationCosts(state) -- CRITICAL FIX #36: Annual education costs
	self:tickPetLifecycle(state) -- CRITICAL FIX #16: Pets age and can pass away
	self:updateCareerSkills(state) -- CRITICAL FIX #17: Track career skills
	self:applyRelationshipDecay(state) -- CRITICAL FIX #18: Relationships decay without maintenance
	self:tickPropertyValues(state) -- CRITICAL FIX #19: Property values change
	self:checkBankruptcy(state) -- CRITICAL FIX #20: Check for financial distress
	self:applyCreditCardInterest(state) -- CRITICAL FIX #21: Credit card debt grows with interest
	self:collectBusinessIncome(state) -- CRITICAL FIX #22: Business income/losses
	self:applyMortgagePayments(state) -- CRITICAL FIX #23: Mortgage payments
	self:applyChildSupport(state) -- CRITICAL FIX (deep-20): Child support payments
	self:ageRelationships(state) -- CRITICAL FIX #24: Partners and family age with player
	self:applyHealthInsuranceCosts(state) -- CRITICAL FIX #25: Health insurance costs
	self:applyCarLoanPayments(state) -- CRITICAL FIX #31: Car loan payments
	self:processAddictions(state) -- CRITICAL FIX #32: Addiction consequences
	local mobEvents = MafiaSystem:onYearPass(state)
	if mobEvents and #mobEvents > 0 then
		for _, event in ipairs(mobEvents) do
			if event.message then
				appendFeed(state, event.message)
			end
		end
	end
	
	-- ════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #94: Mafia heat decay system
	-- Heat naturally decreases over time when player is keeping a low profile
	-- This makes the mafia experience more realistic - heat from crimes fades
	-- ════════════════════════════════════════════════════════════════════════════
	if state.MobState and state.MobState.inMob then
		local mobState = state.MobState
		
		-- Heat decays by 5-15% per year when player isn't doing crimes
		if mobState.heat and mobState.heat > 0 then
			local heatDecay = math.random(5, 15)
			mobState.heat = math.max(0, mobState.heat - heatDecay)
			
			if mobState.heat == 0 and (mobState.previousHeat or 0) > 0 then
				appendFeed(state, "🔥 Your heat has fully cooled down. The cops aren't looking for you anymore.")
			end
			mobState.previousHeat = mobState.heat
		end
		
		-- Increment years in mob
		mobState.yearsInMob = (mobState.yearsInMob or 0) + 1
		
		-- CRITICAL FIX #78: Check for mob promotion based on respect
		local respectThresholds = { 0, 100, 300, 600, 1000 }
		local currentRank = mobState.rankIndex or 1
		if currentRank < 5 then
			local nextThreshold = respectThresholds[currentRank + 1]
			if mobState.respect and mobState.respect >= nextThreshold then
				local oldRankName = mobState.rankName
				mobState.rankIndex = currentRank + 1
				mobState.rankLevel = mobState.rankIndex
				
				local rankNames = {"Associate", "Soldier", "Capo", "Underboss", "Boss"}
				local rankEmojis = {"👤", "🔫", "💀", "🎩", "👑"}
				mobState.rankName = rankNames[mobState.rankIndex]
				mobState.rankEmoji = rankEmojis[mobState.rankIndex]
				
				appendFeed(state, string.format("%s You've been promoted from %s to %s!", 
					mobState.rankEmoji, oldRankName, mobState.rankName))
				state.Flags.got_promotion = true
				state.Flags.mob_promoted = true
			end
		end
		
		-- CRITICAL FIX #86: Loyalty decay if player hasn't been active
		if mobState.operationsCompleted == 0 and mobState.yearsInMob > 1 then
			local loyaltyDecay = math.random(1, 5)
			mobState.loyalty = math.max(0, (mobState.loyalty or 100) - loyaltyDecay)
			
			if mobState.loyalty < 30 then
				appendFeed(state, "⚠️ The family is questioning your loyalty. Complete some operations!")
				state.Flags.loyalty_warning = true
			end
		end
		
		-- Reset yearly operation counter for next year
		mobState.operationsThisYear = 0
	end
	
	-- ════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #2: Process yearly ROYALTY updates (popularity, succession, duties)
	-- Without this, royal players never advanced to King, never got jubilees, etc.!
	-- ════════════════════════════════════════════════════════════════════════════
	if RoyaltyEvents and state.RoyalState and state.RoyalState.isRoyal then
		local royalEvents = RoyaltyEvents.processYearlyRoyalUpdates(state)
		if royalEvents and #royalEvents > 0 then
			for _, event in ipairs(royalEvents) do
				if event.message then
					appendFeed(state, event.message)
				end
			end
		end
		
		-- CRITICAL FIX #10: Check for throne succession (become monarch if next in line)
		if state.RoyalState.lineOfSuccession == 1 and not state.RoyalState.isMonarch then
			-- 3% chance per year the monarch passes and you inherit
			if state.Age >= 25 and RANDOM:NextNumber() < 0.03 then
				local success, msg = RoyaltyEvents.becomeMonarch(state)
				if success then
					appendFeed(state, msg)
					state.Flags.throne_ready = nil
					state.Flags.became_monarch = true
				end
			end
		end
		
		-- CRITICAL FIX #19: Royal wealth management - allowance/expenses
		if state.RoyalState.isRoyal then
			local royalIncome = 0
			if state.RoyalState.isMonarch then
				royalIncome = math.random(5000000, 20000000) -- Monarchs get massive income
			else
				royalIncome = math.random(500000, 2000000) -- Princes/Princesses get allowance
			end
			state.Money = (state.Money or 0) + royalIncome
			state.RoyalState.wealth = state.Money
		end
	end
	
	-- ════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #3: Process yearly CELEBRITY/FAME updates (promotions, events)
	-- Without this, famous players never advanced in their careers!
	-- ════════════════════════════════════════════════════════════════════════════
	if CelebrityEvents and state.FameState and state.FameState.careerPath then
		local fameEvents = CelebrityEvents.processYearlyFameUpdates(state)
		if fameEvents and #fameEvents > 0 then
			for _, event in ipairs(fameEvents) do
				if event.message then
					appendFeed(state, event.message)
				end
				-- Handle career promotions
				if event.type == "promotion" then
					state.Flags.got_promotion = true
				end
			end
		end
		
		-- CRITICAL FIX #16: Random endorsement deals for famous players
		if state.Fame and state.Fame >= 40 and RANDOM:NextNumber() < 0.15 then
			local endorsementValue = math.floor(state.Fame * RANDOM:NextInteger(5000, 20000))
			state.Money = (state.Money or 0) + endorsementValue
			if state.FameState.endorsements then
				table.insert(state.FameState.endorsements, {
					year = state.Year,
					value = endorsementValue,
				})
			end
			appendFeed(state, string.format("💰 You received a $%s endorsement deal!", formatMoney(endorsementValue)))
		end
	end
	self:checkNaturalDeath(state) -- CRITICAL FIX #35: Check for natural death
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: IMMEDIATELY handle death if checkNaturalDeath marked player as dead
	-- Without this, player dies but never sees the death screen!
	-- The bug was: checkNaturalDeath sets Flags.dead=true but Health could still be >0
	-- So the health check at the end of handleAgeUp would pass, continuing normal flow
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.Flags and state.Flags.dead then
		state.Health = 0
		state.Stats = state.Stats or {}
		state.Stats.Health = 0
		local deathFeed = string.format("💀 Age %d: %s", state.Age, state.DeathReason or "You passed away.")
		state.awaitingDecision = false
		self:completeAgeCycle(player, state, deathFeed)
		return
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #4: Pay pension to retired players
	-- Retirees should receive annual pension income based on their career history
	-- Without this, retired players had NO income and would slowly go broke!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.Flags and state.Flags.retired then
		local pensionAmount = 0
		
		-- Get pension from stored amount (set during retirement event)
		if state.Flags.pension_amount and type(state.Flags.pension_amount) == "number" then
			pensionAmount = state.Flags.pension_amount
		end
		
		-- CRITICAL FIX: If pension seems suspiciously low, recalculate from better sources
		-- This handles fame careers where state.CurrentJob.salary wasn't updated
		if pensionAmount < 1000 then
			local lastSalary = 0
			
			-- Try lastPaidSalary first (most accurate for fame careers)
			if state.CareerInfo and state.CareerInfo.lastPaidSalary and state.CareerInfo.lastPaidSalary > 0 then
				lastSalary = state.CareerInfo.lastPaidSalary
			-- Try lastJobSalary (stored during retirement)
			elseif state.CareerInfo and state.CareerInfo.lastJobSalary and state.CareerInfo.lastJobSalary > 0 then
				lastSalary = state.CareerInfo.lastJobSalary
			-- Try lastJob.salary
			elseif state.CareerInfo and state.CareerInfo.lastJob and state.CareerInfo.lastJob.salary then
				lastSalary = state.CareerInfo.lastJob.salary
			end
			
			-- If we found a better salary, recalculate pension
			if lastSalary > 0 then
				pensionAmount = math.floor(lastSalary * 0.4) -- 40% of last salary
			end
			
			-- Estimate from net worth if still too low (for wealthy retirees)
			if pensionAmount < 1000 and state.Money and state.Money > 1000000 then
				pensionAmount = math.floor(state.Money * 0.06) -- 6% withdrawal rate
			end
			
			-- Enforce minimum pension
			pensionAmount = math.max(15000, pensionAmount)
			
			-- Store corrected pension for future years
			state.Flags.pension_amount = pensionAmount
		end
		
		-- Pay the pension
		if pensionAmount > 0 then
			self:addMoney(state, pensionAmount)
			debugPrint("Pension paid:", pensionAmount, "to retired player. New balance:", state.Money)
			
			-- CRITICAL FIX #149: Log pension to YearLog so retired players see their income
			state.YearLog = state.YearLog or {}
			table.insert(state.YearLog, {
				type = "pension",
				emoji = "🏖️",
				text = string.format("Received $%s pension", formatMoney(pensionAmount)),
				amount = pensionAmount,
			})
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Removed duplicate family aging and death logic!
	-- Family members are ALREADY aged and checked for death in advanceRelationships()
	-- Having it here too caused:
	--   1. Family members aging 2 years per player year (double speed!)
	--   2. Family members getting TWO death rolls per year (stacking mortality!)
	-- This was why the user's parents died when player was only 21-23 years old!
	-- The detailed death logic in advanceRelationships (lines 1767-1807) is preserved
	-- which has proper graduated death chances based on age.
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Decrement jail sentence each year and auto-release when complete
	-- Without this, prisoners would be stuck forever!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.InJail and state.JailYearsLeft then
		state.JailYearsLeft = state.JailYearsLeft - 1
		
		if state.JailYearsLeft <= 0 then
			-- Sentence complete! Release the prisoner
			state.InJail = false
			state.JailYearsLeft = 0
			state.Flags.in_prison = nil
			state.Flags.incarcerated = nil
			state.Flags.ex_convict = true -- MINOR FIX: Mark as ex-convict for future events
			
			-- ═══════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX #251: Restore mob membership after prison release
			-- The in_mob flag and MobState.inMob must stay synchronized!
			-- Without this, mafia events stop firing after prison release!
			-- ═══════════════════════════════════════════════════════════════════════
			if state.MobState and state.MobState.inMob then
				-- Player was in mob before jail - ensure flag stays set
				state.Flags.in_mob = true
				state.Flags.mafia_member = true
				-- Reduce loyalty slightly for being in prison
				state.MobState.loyalty = math.max(0, (state.MobState.loyalty or 100) - 10)
				-- Reduce heat since you served time
				state.MobState.heat = math.max(0, (state.MobState.heat or 0) - 30)
				debugPrint("Mob membership restored after prison release. Loyalty:", state.MobState.loyalty)
			elseif state.Flags.was_in_mob_before_jail then
				-- Backup flag check - restore mob state if it was saved
				state.Flags.in_mob = true
				state.Flags.mafia_member = true
				state.Flags.was_in_mob_before_jail = nil -- Clear backup flag
				-- Initialize MobState if missing
				if not state.MobState or not state.MobState.inMob then
					state.MobState = state.MobState or {}
					state.MobState.inMob = true
					state.MobState.loyalty = 70 -- Lower loyalty after prison
					state.MobState.heat = 0
				end
				debugPrint("Mob membership restored from backup flag after prison release")
			end
			
			-- ═══════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX #510: Ensure job is cleared and player is notified about job loss
			-- The job was cleared when going to jail, but UI might show stale data
			-- ═══════════════════════════════════════════════════════════════════════
			local hadJobBeforeJail = state.CareerInfo and state.CareerInfo.lastJobBeforeJail
			local lostJobName = hadJobBeforeJail and state.CareerInfo.lastJobBeforeJail.name or nil
			
			-- CRITICAL FIX #510/#536: FORCE clear job and ALL related flags on jail release
			-- This ensures no stale job data remains in the client UI
			state.CurrentJob = nil
			state.Flags.employed = nil
			state.Flags.has_job = nil
			state.Flags.has_teen_job = nil
			state.Flags.working = nil
			
			-- CRITICAL FIX #537: Reset CareerInfo but preserve history
			local careerHistory = state.CareerInfo and state.CareerInfo.careerHistory or {}
			local totalYearsWorked = state.CareerInfo and state.CareerInfo.totalYearsWorked or 0
			state.CareerInfo = {
				performance = 0,
				promotionProgress = 0,
				yearsAtJob = 0,
				raises = 0,
				promotions = 0,
				careerHistory = careerHistory,
				totalYearsWorked = totalYearsWorked,
				skills = state.CareerInfo and state.CareerInfo.skills or {},
			}
			
			-- ═══════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX #7: Resume education that was suspended during incarceration
			-- If player was in college before going to jail, they can now re-enroll
			-- ═══════════════════════════════════════════════════════════════════════
			if state.EducationData and state.EducationData.StatusBeforeJail == "enrolled" then
				state.EducationData.Status = "enrolled"
				state.EducationData.StatusBeforeJail = nil
				if lostJobName then
					state.PendingFeed = string.format("🎉 You've been released from prison! Time served. Your education has been reinstated. You lost your job as %s.", lostJobName)
				else
					state.PendingFeed = "🎉 You've been released from prison! Time served. Your education has been reinstated."
				end
			elseif state.MobState and state.MobState.inMob then
				-- Special message for mob members
				if lostJobName then
					state.PendingFeed = string.format("🎉 You've been released! The family welcomes you back. You lost your job as %s.", lostJobName)
				else
					state.PendingFeed = "🎉 You've been released from prison! The family welcomes you back."
				end
			else
				if lostJobName then
					state.PendingFeed = string.format("🎉 You've been released from prison! Time served. You lost your job as %s - time to start fresh.", lostJobName)
				else
					state.PendingFeed = "🎉 You've been released from prison! Time served."
				end
			end
			
			-- Clear the last job before jail reference now that we've notified the player
			if state.CareerInfo then
				state.CareerInfo.lastJobBeforeJail = nil
			end
			
			debugPrint("Player released from prison after completing sentence:", player.Name)
		else
			state.PendingFeed = string.format("📅 Prison: %.1f years remaining.", state.JailYearsLeft)
		end
	end

	state.Stats = state.Stats or {}
	state.Stats.Health = clamp((state.Stats.Health or 0) - RANDOM:NextInteger(0, 2))
	state.Stats.Happiness = clamp((state.Stats.Happiness or 0) + RANDOM:NextInteger(-1, 2))
	state.Stats.Smarts = clamp((state.Stats.Smarts or 0) + RANDOM:NextInteger(-1, 2))
	state.Health = state.Stats.Health
	state.Happiness = state.Stats.Happiness
	state.Smarts = state.Stats.Smarts

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #142: Generate BitLife-style year summaries that INCLUDE both
	-- PendingFeed (event results) AND YearLog (salary, expenses, income)
	-- Previously YearLog was ignored when PendingFeed existed, hiding salary info!
	-- ═══════════════════════════════════════════════════════════════════════════════
	local feedText
	local yearLogText = ""
	
	-- CRITICAL FIX #143: Process YearLog first to build income/expense summary
	if state.YearLog and #state.YearLog > 0 then
		local logParts = {}
		for _, logEntry in ipairs(state.YearLog) do
			if logEntry.text and logEntry.text ~= "" then
				table.insert(logParts, logEntry.text)
			end
		end
		if #logParts > 0 then
			-- Limit to 3 most important entries
			local maxEntries = math.min(#logParts, 3)
			local finalParts = {}
			for i = 1, maxEntries do
				table.insert(finalParts, logParts[i])
			end
			yearLogText = table.concat(finalParts, ". ") .. "."
		end
		state.YearLog = {} -- Clear after processing
	end
	
	-- CRITICAL FIX #144: Combine PendingFeed with YearLog for complete summary
	if state.PendingFeed and state.PendingFeed ~= "" then
		if yearLogText ~= "" then
			-- Both exist - show event THEN income/expenses
			feedText = string.format("Age %d: %s %s", state.Age, state.PendingFeed, yearLogText)
		else
			feedText = string.format("Age %d: %s", state.Age, state.PendingFeed)
		end
	elseif yearLogText ~= "" then
		-- Only YearLog exists (normal year with just income/expenses)
		feedText = string.format("📅 Age %d: %s", state.Age, yearLogText)
	else
		-- Nothing specific - generate generic summary
		feedText = self:generateYearSummary(state)
	end
	state.PendingFeed = nil

	if state.Health <= 0 then
		state.awaitingDecision = false
		self:completeAgeCycle(player, state, feedText)
		return
	end

	-- BitLife style: ONE event per age up, not multiple stacked events
	local queue = {}

	-- Stage transition -> fold into feed text, not a separate choice event
	local transitionEvent = LifeStageSystem.getTransitionEvent(oldAge, state.Age)
	if transitionEvent then
		local stageName = transitionEvent.title or "a new stage"
		feedText = string.format("🎂 %s\n%s", transitionEvent.text or ("You entered " .. stageName), feedText)
	end

	-- Get just ONE event from the year queue (BitLife style)
	local yearlyEvents = LifeEvents.buildYearQueue(state, { maxEvents = 1 }) or {}
	if #yearlyEvents > 0 then
		local eventDef = yearlyEvents[1]
		eventDef.source = "lifeevents"
		table.insert(queue, eventDef)
	end

	local careerEvent = self:buildCareerEvent(state)
	if careerEvent then
		if #queue == 0 then
			table.insert(queue, careerEvent)
		elseif RANDOM:NextNumber() < 0.4 then
			queue[1] = careerEvent
		end
	end

	if #queue == 0 then
		state.awaitingDecision = false
		self:completeAgeCycle(player, state, feedText)
		return
	end

	if #queue > 0 then
		debugPrint(string.format("Event for %s: %s", player.Name, queue[1].id or "unknown"))
	end

	self.pendingEvents[player.UserId] = {
		queue = queue,
		cursor = 1,
		feedText = feedText,
	}
	state.awaitingDecision = true
	self:presentEvent(player, queue[1], feedText)
end

function LifeBackend:resetLife(player)
	debugPrint("Resetting life for", player.Name)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #7-20: COMPREHENSIVE STATE RESET ON NEW LIFE
	-- Previously, many state fields persisted across lives causing bugs like:
	-- - Old job showing after death
	-- - Old career info persisting
	-- - Old flags affecting new life
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Clear any pending events from previous life
	self.pendingEvents[player.UserId] = nil
	
	-- Clear any pending minigame events
	if self.pendingMinigameEvents then
		self.pendingMinigameEvents[player.UserId] = nil
	end
	
	-- Create a completely fresh state (includes family, gamepass bonuses, etc.)
	local newState = self:createInitialState(player)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #8: Ensure ALL job/career data is reset
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.CurrentJob = nil
	newState.CareerInfo = {
		performance = 0,
		promotionProgress = 0,
		yearsAtJob = 0,
		raises = 0,
		promotions = 0,
		careerHistory = {},
		skills = {},
		totalYearsWorked = 0,
	}
	newState.Career = {
		track = nil,
		education = nil,
	}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #9: Clear ALL employment-related flags
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.Flags = newState.Flags or {}
	newState.Flags.employed = nil
	newState.Flags.has_job = nil
	newState.Flags.has_teen_job = nil
	newState.Flags.between_jobs = nil
	newState.Flags.unemployed = nil
	newState.Flags.retired = nil
	newState.Flags.semi_retired = nil
	newState.Flags.pension_amount = nil
	newState.Flags.happily_retired = nil
	newState.Flags.retirement_eligible = nil
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #10: Clear ALL prison/jail flags
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.InJail = false
	newState.JailYearsLeft = 0
	newState.Flags.in_prison = nil
	newState.Flags.incarcerated = nil
	newState.Flags.serving_time = nil
	newState.Flags.criminal_record = nil
	newState.Flags.ex_convict = nil
	newState.Flags.on_parole = nil
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #11: Reset education to fresh start
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.Education = "none"
	newState.EducationData = {
		Status = "none",
		Level = nil,
		Progress = 0,
		Duration = nil,
		Institution = nil,
		GPA = nil,
		Debt = 0,
		CreditsEarned = 0,
		CreditsRequired = 0,
		Year = 0,
		TotalYears = 0,
	}
	newState.Flags.in_college = nil
	newState.Flags.college_student = nil
	newState.Flags.enrolled_college = nil
	newState.Flags.in_school = nil
	newState.Flags.graduated_high_school = nil
	newState.Flags.has_degree = nil
	newState.Flags.has_student_loans = nil
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #12: Reset premium feature states (but preserve gamepass ownership!)
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Reset MobState (mafia) - but check if in createInitialState it might set up royal birth
	newState.MobState = {
		inMob = false,
		familyId = nil,
		familyName = nil,
		familyEmoji = nil,
		familyColor = nil,
		rankIndex = 1,
		rankLevel = 1,
		rankName = "Associate",
		rankEmoji = "👤",
		respect = 0,
		notoriety = 0,
		heat = 0,
		loyalty = 100,
		kills = 0,
		earnings = 0,
		yearsInMob = 0,
		operationsCompleted = 0,
		operationsFailed = 0,
		operations = {},
		territories = {},
		lastEvent = nil,
	}
	newState.Flags.in_mob = nil
	newState.Flags.mafia_member = nil
	newState.Flags.criminal_lifestyle = nil
	
	-- Reset FameState
	newState.FameState = {
		isFamous = false,
		careerPath = nil,
		careerName = nil,
		currentStage = 1, -- CRITICAL FIX: Lua is 1-indexed, was 0 which caused nil stage lookups
		stageName = nil,
		subType = nil,
		yearsInCareer = 0,
		lastPromotionYear = 0,
		followers = 0,
		endorsements = {},
		awards = {},
		scandals = 0,
		fameLevel = "Unknown",
		monthlyListeners = 0,
		totalStreams = 0,
		totalTracks = 0,
		albumsReleased = 0,
		mixtapesReleased = 0,
		epsReleased = 0,
		showsPerformed = 0,
		toursCompleted = 0,
		collabs = 0,
		battleWins = 0,
		radioPlays = 0,
		blogFeatures = 0,
		viralMoments = 0,
		majorFeatures = 0,
		musicVideos = 0,
		connections = 0,
		style = nil,
		producerConnect = false,
		subscribers = 0,
		totalViews = 0,
		totalVideos = 0,
		viralVideos = 0,
		contentType = nil,
		brandDeals = 0,
		totalPosts = 0,
		totalLikes = 0,
	}
	newState.Fame = 0
	newState.Flags.famous = nil
	newState.Flags.celebrity = nil
	newState.Flags.fame_career = nil
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #13: Clear death state
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.Flags.dead = nil
	newState.CauseOfDeath = nil
	newState.DeathReason = nil
	newState.DeathAge = nil
	newState.DeathYear = nil
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #14: Clear event history (prevents duplicate event issues)
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.EventHistory = {
		occurrences = {},
		lastOccurrence = {},
		completed = {},
		recentCategories = {},
		recentEvents = {},
	}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #15: Clear YearLog (prevents old feed text showing)
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.YearLog = {}
	newState.PendingFeed = nil
	newState.lastFeed = nil
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #16: Reset assets (new life starts with nothing)
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.Assets = {
		Properties = {},
		Vehicles = {},
		Items = {},
		Investments = {},
		Crypto = {},
		Businesses = {},
	}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #17: Clear job application history
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.JobApplications = {}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #18: Clear homeless and bum-life flags
	-- These MUST be cleared or new life starts homeless!
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.Flags.homeless = nil
	newState.Flags.bum_life = nil
	newState.Flags.at_risk_homeless = nil
	newState.Flags.using_shelter = nil
	newState.Flags.has_temp_housing = nil
	newState.Flags.desperate_criminal = nil
	newState.Flags.desperate_job_hunt = nil
	newState.Flags.recovering = nil
	newState.Flags.in_recovery_program = nil
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #19: Clear ALL story path flags
	-- Story paths should NOT persist across lives!
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.ActivePath = nil
	newState.StoryPathProgress = nil
	newState.Flags.pursuing_fame = nil
	newState.Flags.pursuing_politics = nil
	newState.Flags.pursuing_crime = nil
	newState.Flags.pursuing_mafia = nil
	newState.Flags.pursuing_royalty = nil
	newState.Flags.crime_path_active = nil
	newState.Flags.mafia_path_active = nil
	newState.Flags.criminal_aspirant = nil
	newState.Flags.mafia_aspirant = nil
	newState.Flags.royal_aspirant = nil
	newState.Flags.political_aspirant = nil
	newState.Flags.interested_in_crime = nil
	newState.Flags.interested_in_politics = nil
	newState.Flags.interested_in_royalty = nil
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #20: Clear crime-related flags
	-- Criminal history should NOT persist across lives!
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.Flags.petty_criminal = nil
	newState.Flags.street_smart = nil
	newState.Flags.vandal = nil
	newState.Flags.shoplifter = nil
	newState.Flags.delinquent = nil
	newState.Flags.criminal_tendencies = nil
	newState.Flags.troublemaker = nil
	newState.Flags.street_hustler = nil
	newState.Flags.criminal_path = nil
	newState.Flags.criminal = nil
	newState.Flags.criminal_connections = nil
	newState.Flags.violent_crimes = nil
	newState.Flags.thief = nil
	newState.Flags.burglar = nil
	newState.Flags.first_hustle_done = nil
	newState.Flags.has_crew = nil
	newState.Flags.crime_reputation = nil
	newState.Flags.is_underboss = nil
	newState.Flags.is_crime_boss = nil
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #21: Clear royalty-related flags (preserve gamepass ownership)
	-- Royalty STATUS should not persist, but gamepass ownership does
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.Flags.is_royalty = nil
	newState.Flags.royal_birth = nil
	newState.Flags.royal_duties = nil
	newState.Flags.embraced_royalty = nil
	newState.Flags.married_royalty = nil
	-- Reset RoyalState but don't remove it (createInitialState may set up royal birth)
	if not (newState.RoyalState and newState.RoyalState.isRoyal) then
		newState.RoyalState = {
			isRoyal = false,
			title = nil,
			dutiesCompleted = 0,
			publicApproval = 50,
			heirs = {},
		}
	end
	
	-- Store the new state
	self.playerStates[player] = newState

	-- ════════════════════════════════════════════════════════════════════════════════
	-- CRITICAL: Clear saved data when starting a NEW life
	-- This prevents the old life from being restored on rejoin
	-- ════════════════════════════════════════════════════════════════════════════════
	self:clearSaveData(player)

	debugPrint("Life reset complete for", player.Name, "- all state cleared")
	self:pushState(player, "A new life begins...")
end

function LifeBackend:completeAgeCycle(player, state, feedText, resultData)
	local deathInfo
	-- CRITICAL FIX: Check Flags.dead FIRST (set by checkNaturalDeath)
	-- This ensures natural deaths from old age are properly handled
	if state.Flags and state.Flags.dead then
		deathInfo = { died = true, cause = state.DeathReason or state.CauseOfDeath or "Natural causes" }
	elseif state.Health and state.Health <= 0 then
		deathInfo = { died = true, cause = "Health Failure" }
	else
		deathInfo = LifeStageSystem.checkDeath(state)
	end

	if deathInfo and deathInfo.died then
		state.Flags = state.Flags or {}
		if state.SetFlag then
			state:SetFlag("dead", true)
		else
			state.Flags.dead = true
		end
		state.CauseOfDeath = deathInfo.cause
		
		-- Build AAA-quality death summary
		local deathMeta = buildDeathMeta(state, deathInfo)
		
		-- Use the full obituary for the death popup
		feedText = deathMeta.obituary or string.format("You passed away from %s.", deathInfo.cause or "unknown causes")
		
		debugPrint(string.format("Player died: %s (Age %d) cause=%s", state.Name or player.Name, state.Age or -1, deathInfo.cause or "unknown"))
		
		-- ════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #59: Integrate TimeMachine into death handling
		-- Allows players with Time Machine gamepass to travel back in time
		-- ════════════════════════════════════════════════════════════════════════════
		local timeMachineData = nil
		local hasTimeMachineGamepass = self:checkGamepassOwnership(player, "TIME_MACHINE")
		
		if TimeMachine and hasTimeMachineGamepass then
			timeMachineData = TimeMachine.getDeathScreenData(player, state, hasTimeMachineGamepass)
		end
		
		resultData = {
			showPopup = true,
			emoji = "☠️",
			title = string.format("💀 %s (Age %d)", state.Name or "You", state.Age or 0),
			body = feedText,
			wasSuccess = false,
			fatal = true,
			cause = deathInfo.cause,
			deathMeta = deathMeta,
			-- CRITICAL FIX #59: Include time machine options in death screen
			hasTimeMachine = hasTimeMachineGamepass,
			timeMachineData = timeMachineData,
		}
	end

	self:pushState(player, feedText, resultData)
end

function LifeBackend:resolvePendingEvent(player, eventId, choiceIndex)
	local pending = self.pendingEvents[player.UserId]
	if not pending then
		return
	end
	if pending.activeEventId and pending.activeEventId ~= eventId then
		return
	end

	local eventDef
	if pending.queue then
		eventDef = pending.definition or pending.queue[pending.cursor]
	else
		eventDef = pending.definition
	end
	if not eventDef then
		return
	end

	local choices = eventDef.choices or {}
	local choice = choices[choiceIndex]
	if not choice then
		return
	end

	debugPrint(string.format("Resolving event %s for %s with choice #%d", eventDef.id or "unknown", player.Name, choiceIndex))

	local state = self:getState(player)
	if not state then
		return
	end

	-- CRITICAL FIX: Use feedText (what events use), then feed, then text
	local feedText = choice.feedText or choice.feed or choice.text or "Life continues..."
	local resultData
	local effectsSummary = choice.deltas or {}

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Minigame Integration for Career Events (Racing, Hacking, etc.)
	-- If choice triggers a minigame, store pending event and wait for minigame result
	-- ═══════════════════════════════════════════════════════════════════════════════
	if choice.triggerMinigame then
		-- Initialize pending minigame storage
		self.pendingMinigameEvents = self.pendingMinigameEvents or {}
		
		-- Store the event context for when minigame completes
		self.pendingMinigameEvents[player.UserId] = {
			eventDef = eventDef,
			choice = choice,
			choiceIndex = choiceIndex,
			feedText = feedText,
		}
		
		-- Tell client to start the minigame
		local minigamePayload = {
			type = choice.triggerMinigame,
			options = choice.minigameOptions or {},
			eventId = eventDef.id,
		}
		
		-- Clear the pending event queue but keep awaiting decision
		self.pendingEvents[player.UserId] = nil
		-- state.awaitingDecision stays true until minigame completes
		
		-- Fire the minigame start event to client
		if self.remotes.MinigameStart then
			self.remotes.MinigameStart:FireClient(player, minigamePayload)
		else
			-- Fallback: create the remote if it doesn't exist
			local minigameRemote = self:createRemote("MinigameStart", "RemoteEvent")
			minigameRemote:FireClient(player, minigamePayload)
		end
		
		debugPrint(string.format("Minigame triggered for %s: %s", player.Name, choice.triggerMinigame))
		return -- Wait for minigame result
	end

	-- CRITICAL: Track jail state BEFORE event processing to detect incarceration
	local wasInJailBefore = state.InJail or false

	if choice.effects or eventDef.source == "lifeevents" or eventDef.source == "stage" then
		local preStats = table.clone(state.Stats)
		local preMoney = state.Money
		local success, err = pcall(function()
			EventEngine.completeEvent(eventDef, choiceIndex, state)
		end)
		if not success then
			warn("[LifeBackend] Event resolution error:", err)
		end
		effectsSummary = {
			Happiness = (state.Stats.Happiness - preStats.Happiness),
			Health = (state.Stats.Health - preStats.Health),
			Smarts = (state.Stats.Smarts - preStats.Smarts),
			Looks = (state.Stats.Looks - preStats.Looks),
			Money = (state.Money - preMoney),
		}
	else
		self:applyStatChanges(state, choice.deltas)

		if choice.cost and choice.cost > 0 then
			self:addMoney(state, -choice.cost)
			effectsSummary = effectsSummary or {}
			effectsSummary.Money = (effectsSummary.Money or 0) - choice.cost
		end

		if choice.career then
			state.CareerInfo = state.CareerInfo or {}
			local info = state.CareerInfo
			info.performance = clamp((info.performance or 60) + (choice.career.performance or 0))
			info.promotionProgress = clamp((info.promotionProgress or 0) + (choice.career.progress or 0))
			if choice.career.salaryBonus and state.CurrentJob then
				local job = state.CurrentJob
				job.salary = math.floor((job.salary or 0) * (1 + choice.career.salaryBonus))
			end
		end

		if choice.relationships and choice.relationships.delta then
			for _, rel in pairs(state.Relationships or {}) do
				if type(rel) == "table" then
					rel.relationship = clamp((rel.relationship or 50) + choice.relationships.delta, 0, 100)
				end
			end
		end

		if choice.crime then
			local reward = RANDOM:NextInteger(choice.crime.reward[1], choice.crime.reward[2])
			self:addMoney(state, reward)
			effectsSummary = effectsSummary or {}
			effectsSummary.Money = (effectsSummary.Money or 0) + reward
		end
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Handle setFlags and clearFlags in the else branch too!
		-- Without this, dynamically created events (like prison escape) won't have
		-- their flags processed, causing players to stay stuck in prison, etc.
		-- ═══════════════════════════════════════════════════════════════════════════════
		state.Flags = state.Flags or {}
		
		-- Apply setFlags
		if choice.setFlags then
			for flagName, flagValue in pairs(choice.setFlags) do
				state.Flags[flagName] = flagValue
			end
		end
		
		-- Apply clearFlags (remove flags)
		if choice.clearFlags then
			for flagName, _ in pairs(choice.clearFlags) do
				state.Flags[flagName] = nil
			end
		end
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Call eventDef.onComplete for dynamically created events
		-- This ensures custom logic (like freeing from prison) actually runs
		-- ═══════════════════════════════════════════════════════════════════════════════
		if eventDef.onComplete and type(eventDef.onComplete) == "function" then
			local success, err = pcall(function()
				eventDef.onComplete(state, choice, eventDef, {})
			end)
			if not success then
				warn("[LifeBackend] onComplete handler error:", err)
			end
		end
		
		-- Also support choice-level onResolve in else branch
		if choice.onResolve and type(choice.onResolve) == "function" then
			local success, err = pcall(function()
				choice.onResolve(state, choice, eventDef, {})
			end)
			if not success then
				warn("[LifeBackend] choice.onResolve handler error:", err)
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Log this event to the year log for accurate year summaries
	-- This ensures the year summary says what ACTUALLY happened, not random text
	-- ═══════════════════════════════════════════════════════════════════════════════
	if eventDef.id and eventDef.title then
		local logText = choice.feedText or choice.feed or choice.text or eventDef.title
		if logText and logText ~= "" then
			self:logYearEvent(state, eventDef.id, logText, eventDef.emoji)
		end
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Detect if player was JUST incarcerated by this event
	-- Override popup with jail-specific content so user sees "Busted!" not generic text
	-- ═══════════════════════════════════════════════════════════════════════════════
	local justGotIncarcerated = (not wasInJailBefore) and state.InJail
	local jailPopupBody = nil
	local jailPopupTitle = nil
	local jailPopupEmoji = nil

	if justGotIncarcerated then
		-- Player was caught during this event!
		
		-- ═══════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #256: Preserve mob membership when event causes jail
		-- ═══════════════════════════════════════════════════════════════════════
		if state.Flags.in_mob or (state.MobState and state.MobState.inMob) then
			state.Flags.was_in_mob_before_jail = true
			state.Flags.in_prison = true
			state.Flags.incarcerated = true
			debugPrint("Preserved mob membership for event-triggered jail:", player.Name)
		end
		
		-- Try to get the jail message from PendingFeed set by onResolve
		if state.PendingFeed and type(state.PendingFeed) == "string" and state.PendingFeed ~= "" then
			-- Check if the feed text is jail-related (contains relevant keywords)
			local feedLower = state.PendingFeed:lower()
			if feedLower:find("sentenced") or feedLower:find("jail") or feedLower:find("prison") 
				or feedLower:find("arrested") or feedLower:find("caught") or feedLower:find("years") then
				jailPopupBody = state.PendingFeed
			end
		end

		-- Fallback: construct a generic jail message if we couldn't find one
		if not jailPopupBody then
			local yearsText = state.JailYearsLeft and string.format("%.1f years", state.JailYearsLeft) or "some time"
			jailPopupBody = string.format("You were caught and sentenced to %s in prison!", yearsText)
		end

		jailPopupTitle = "Busted!"
		jailPopupEmoji = "🚔"
		feedText = jailPopupBody -- Also update the feed text for the feed display

		debugPrint(string.format("Player %s was incarcerated by event! Jail years: %.1f", player.Name, state.JailYearsLeft or 0))
	end

	-- CRITICAL FIX: Use PendingFeed (detailed outcome from onResolve) for popup body
	-- Fall back to feedText (short choice text) only if no detailed outcome was set
	local popupBody = jailPopupBody or state.PendingFeed or feedText
	if popupBody == nil or popupBody == "" then
		popupBody = "Something happened..."
	end
	
	resultData = {
		showPopup = true,
		emoji = jailPopupEmoji or eventDef.emoji,
		title = jailPopupTitle or eventDef.title,
		body = popupBody,
		happiness = effectsSummary.Happiness,
		health = effectsSummary.Health,
		smarts = effectsSummary.Smarts,
		looks = effectsSummary.Looks,
		money = effectsSummary.Money,
		wasSuccess = not justGotIncarcerated, -- Mark as failure if caught
	}

	if pending.queue then
		pending.cursor = pending.cursor + 1
		if pending.cursor <= #pending.queue then
			pending.definition = pending.queue[pending.cursor]
			self.pendingEvents[player.UserId] = pending
			debugPrint(string.format("Advancing to next event in queue (%d/%d) for %s", pending.cursor, #pending.queue, player.Name))
			self:presentEvent(player, pending.definition, pending.feedText)
			return
		else
			self.pendingEvents[player.UserId] = nil
			state.awaitingDecision = false
			debugPrint(string.format("Event queue complete for %s", player.Name))
			self:completeAgeCycle(player, state, pending.feedText or feedText, resultData)
			return
		end
	end

	self.pendingEvents[player.UserId] = nil
	state.awaitingDecision = false
	self:pushState(player, feedText, resultData)
end

-- ============================================================================
-- Activities / Crimes / Prison
-- ============================================================================

function LifeBackend:handleActivity(player, activityId, bonus)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "No life data loaded." }
	end
	if state.InJail then
		return { success = false, message = "You can't do that behind bars." }
	end
	local activity = ActivityCatalog[activityId]
	if not activity then
		return { success = false, message = "Unknown activity." }
	end

	local isEducationActivity = activity.educationProgram ~= nil

	-- CRITICAL FIX: Check age requirement for activities (like driver's license)
	if activity.requiresAge and (state.Age or 0) < activity.requiresAge then
		return { success = false, message = string.format("You must be at least %d years old.", activity.requiresAge) }
	end
	
	-- CRITICAL FIX: Check maximum age for activities (like returning to high school)
	if activity.maxAge and (state.Age or 0) > activity.maxAge then
		return { success = false, message = string.format("You're too old for this! (Max age: %d)", activity.maxAge) }
	end
	
	-- CRITICAL FIX: Check if blocked by existing flag (e.g., can't get license if already have one)
	state.Flags = state.Flags or {}
	if activity.blockedByFlag and state.Flags[activity.blockedByFlag] then
		return { success = false, message = "You've already done this!" }
	end
	
	-- CRITICAL FIX: Check if activity requires a specific flag (like dropout for GED)
	if activity.requiresFlag then
		local hasRequiredFlag = state.Flags[activity.requiresFlag]
		
		-- CRITICAL FIX #ROYAL-1: Handle royalty flag aliases
		-- Players can be royal via is_royalty, royal_birth, or RoyalState.isRoyal
		-- Activities that require "is_royalty" or "is_monarch" should accept all valid royal states
		if not hasRequiredFlag then
			if activity.requiresFlag == "is_royalty" then
				-- Accept multiple ways to be royalty
				hasRequiredFlag = state.Flags.royal_birth 
					or state.Flags.is_royal 
					or (state.RoyalState and state.RoyalState.isRoyal)
			elseif activity.requiresFlag == "is_monarch" then
				-- Accept multiple ways to be monarch
				hasRequiredFlag = state.Flags.is_king 
					or state.Flags.is_queen 
					or (state.RoyalState and state.RoyalState.isMonarch)
			elseif activity.requiresFlag == "in_mob" then
				-- Accept multiple ways to be in the mob
				hasRequiredFlag = state.Flags.mafia_member 
					or (state.MobState and state.MobState.inMob)
			end
		end
		
		if not hasRequiredFlag then
			-- Provide helpful messages based on which flag is missing
			local helpfulMessage = "You don't meet the requirements for this."
			if activity.requiresFlag == "dropped_out_high_school" then
				helpfulMessage = "This is only for people who dropped out of high school."
			elseif activity.requiresFlag == "has_ged_or_diploma" then
				helpfulMessage = "You need a high school diploma or GED first."
			elseif activity.requiresFlag == "has_degree" then
				helpfulMessage = "You need a college degree first."
			elseif activity.requiresFlag == "is_royalty" then
				helpfulMessage = "This activity is only for royalty."
			elseif activity.requiresFlag == "is_monarch" then
				helpfulMessage = "This activity is only for the King or Queen."
			elseif activity.requiresFlag == "in_mob" then
				helpfulMessage = "This activity requires you to be in the mob."
			end
			return { success = false, message = helpfulMessage }
		end
	end
	
	-- CRITICAL FIX: Check if this is a one-time activity that was already completed
	state.CompletedActivities = state.CompletedActivities or {}
	if activity.oneTime and not activity.skipCompletionTracking and state.CompletedActivities[activityId] then
		return { success = false, message = "You can only do this once!" }
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #30: Health insurance reduces medical costs
	-- Activities with usesInsurance = true get a discount if player has insurance
	-- ═══════════════════════════════════════════════════════════════════════════════
	local actualCost = activity.cost or 0
	if activity.usesInsurance and state.Flags and state.Flags.has_health_insurance then
		-- Insurance covers 70-80% of medical costs
		local insuranceDiscount = 0.75 -- 75% covered by insurance
		actualCost = math.floor(actualCost * (1 - insuranceDiscount))
	end
	
	local shouldChargeCost = (not isEducationActivity) and actualCost > 0
	if shouldChargeCost and (state.Money or 0) < actualCost then
		-- CRITICAL FIX #30: Different message if they don't have insurance
		if activity.usesInsurance and not (state.Flags and state.Flags.has_health_insurance) then
			return { success = false, message = string.format("You can't afford that! Without insurance, it costs $%d. Consider getting health insurance.", activity.cost) }
		end
		return { success = false, message = "You can't afford that right now." }
	end

	if shouldChargeCost then
		self:addMoney(state, -actualCost)
		
		-- If this was a medical expense with insurance, note the savings
		if activity.usesInsurance and state.Flags and state.Flags.has_health_insurance then
			local saved = (activity.cost or 0) - actualCost
			if saved > 0 then
				state.YearLog = state.YearLog or {}
				table.insert(state.YearLog, {
					type = "insurance_savings",
					emoji = "🏥",
					text = string.format("Insurance covered $%s of your medical costs", formatMoney(saved)),
					amount = saved,
				})
			end
		end
	end

	local deltas = shallowCopy(activity.stats or {})
	if bonus then
		for stat, delta in pairs(deltas) do
			deltas[stat] = delta + math.ceil(delta * 0.5)
		end
	end

	self:applyStatChanges(state, deltas)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Handle setFlag for activities (especially mischief activities)
	-- Without this, flags like "cheater", "rebellious", "bully" won't be set
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.Flags = state.Flags or {}
	if activity.setFlag then
		state.Flags[activity.setFlag] = true
	end
	
	-- Handle multiple flags if needed
	if activity.setFlags then
		for flagName, flagValue in pairs(activity.setFlags) do
			state.Flags[flagName] = flagValue
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Some mischief activities have risk of getting caught
	-- E.g., vandalism, bullying, underage drinking may have consequences
	-- ═══════════════════════════════════════════════════════════════════════════════
	local resultMessage = ""
	local gotCaught = false
	
	if isEducationActivity then
		local enrollResult = self:enrollEducation(player, activity.educationProgram, { skipPush = true })
		if not enrollResult or not enrollResult.success then
			return enrollResult or { success = false, message = "Unable to enroll right now." }
		end
		resultMessage = enrollResult.message or "You enrolled in a new program."
	else
		if activity.risk and RANDOM:NextInteger(1, 100) <= activity.risk then
			gotCaught = true
			-- Risk-based consequence (usually for teen mischief)
			if activity.riskConsequence then
				resultMessage = string.format("You %s... but %s", activity.feed or "did it", activity.riskConsequence)
			else
				resultMessage = string.format("You %s... and got caught!", activity.feed or "did it")
			end
			-- Apply negative effects for getting caught
			self:applyStatChanges(state, { Happiness = -5 })
			if activity.riskFlag then
				state.Flags[activity.riskFlag] = true
			end
		else
			resultMessage = string.format("You %s.", activity.feed or "enjoyed the day")
		end
	end
	
	-- CRITICAL FIX: Track one-time activities so they can't be repeated
	if activity.oneTime and not activity.skipCompletionTracking and not isEducationActivity then
		state.CompletedActivities = state.CompletedActivities or {}
		state.CompletedActivities[activityId] = true
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #301: Handle royalty-specific effects from royal duties
	-- Without this, royal activities wouldn't affect popularity/respect
	-- CRITICAL FIX #ROYAL-2: Use RoyalState NOT RoyaltyState (was causing data to be lost!)
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.royaltyEffect then
		state.RoyalState = state.RoyalState or {} -- FIXED: Was incorrectly using RoyaltyState
		local royalEffect = activity.royaltyEffect
		if royalEffect.popularity then
			state.RoyalState.popularity = (state.RoyalState.popularity or 50) + royalEffect.popularity
			state.RoyalState.popularity = math.clamp(state.RoyalState.popularity, 0, 100)
		end
		if royalEffect.respect then
			state.RoyalState.respect = (state.RoyalState.respect or 50) + royalEffect.respect
		end
		if royalEffect.diplomacy then
			state.RoyalState.diplomacy = (state.RoyalState.diplomacy or 50) + royalEffect.diplomacy
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Handle FAME activities (audition, social_post, interview, etc.)
	-- User bug: "EVERY SINGLE ACTION INSIDE FAME SAYS UNKNOWN ACTIVITY"
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.fameEffect then
		state.FameState = state.FameState or {}
		local fameEff = activity.fameEffect
		
		-- Add fame
		if fameEff.fame then
			state.Fame = (state.Fame or 0) + fameEff.fame
			state.Fame = math.clamp(state.Fame, 0, 100)
			state.FameState.fame = state.Fame -- Keep in sync
		end
		
		-- Add followers
		if fameEff.followers then
			local mult = (state.Fame or 0) > 50 and 2 or 1 -- More famous = more follower gain
			state.FameState.followers = (state.FameState.followers or 0) + (fameEff.followers * mult)
		end
		
		-- Breakthrough chance (auditions can lead to big breaks)
		if fameEff.breakthrough_chance and RANDOM:NextNumber() < fameEff.breakthrough_chance then
			local bonus = RANDOM:NextInteger(5, 15)
			state.Fame = math.clamp((state.Fame or 0) + bonus, 0, 100)
			state.FameState.fame = state.Fame
			state.FameState.followers = (state.FameState.followers or 0) + RANDOM:NextInteger(1000, 5000)
			appendFeed(state, "⭐ BREAKTHROUGH! Your audition was a huge success!")
		end
		
		-- Scandal chance (publicity stunts can backfire)
		if fameEff.scandal and RANDOM:NextNumber() < fameEff.scandal then
			state.Fame = math.max(0, (state.Fame or 0) - RANDOM:NextInteger(2, 8))
			state.FameState.fame = state.Fame
			appendFeed(state, "😬 Your stunt backfired! Got some bad press...")
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #7: Handle RETIREMENT activities
	-- This properly transitions player from employed state to retired state
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.isRetirement then
		-- Calculate pension based on current job salary and years worked
		local pensionAmount = 15000 -- Base social security minimum
		if state.CurrentJob and state.CurrentJob.salary then
			local yearsWorked = state.CareerInfo and state.CareerInfo.totalYearsWorked or 0
			yearsWorked = yearsWorked + (state.CareerInfo and state.CareerInfo.yearsAtJob or 0)
			
			-- Pension calculation: 40% of salary + years worked bonus
			-- Early retirement gets reduced pension
			local pensionPercent = 0.4
			if activity.setFlags and activity.setFlags.early_retirement then
				pensionPercent = 0.25 -- 25% for early retirement
			end
			
			pensionAmount = math.floor(state.CurrentJob.salary * pensionPercent)
			pensionAmount = pensionAmount + (yearsWorked * 500) -- $500 per year worked
			pensionAmount = math.max(15000, pensionAmount) -- Minimum pension
		end
		
		-- Store pension amount in flags for annual payment
		state.Flags.pension_amount = pensionAmount
		
		-- Save last job info for records
		if state.CareerInfo then
			state.CareerInfo.lastJob = state.CurrentJob
			state.CareerInfo.lastJobSalary = state.CurrentJob and state.CurrentJob.salary
		end
		
		-- CRITICAL: Clear current job
		state.CurrentJob = nil
		state.Flags.employed = nil
		state.Flags.has_job = nil
		
		resultMessage = string.format("You retired! You'll receive $%s annual pension.", pensionAmount)
	end
	
	-- Handle semi-retirement (working part-time)
	if activity.isSemiRetirement then
		-- Reduce salary but keep job
		if state.CurrentJob and state.CurrentJob.salary then
			state.CurrentJob.salary = math.floor(state.CurrentJob.salary * 0.5) -- Half salary
		end
		resultMessage = "You're now semi-retired, working part-time for reduced salary."
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #302: Handle mafia-specific effects from mob operations
	-- Without this, mafia activities wouldn't affect respect/heat/earnings
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.mafiaEffect then
		state.MobState = state.MobState or {}
		local mafEffect = activity.mafiaEffect
		if mafEffect.respect then
			state.MobState.respect = (state.MobState.respect or 0) + mafEffect.respect
		end
		if mafEffect.heat then
			state.MobState.heat = math.min(100, (state.MobState.heat or 0) + mafEffect.heat)
		end
		if mafEffect.money then
			-- mafiaEffect.money is a {min, max} table
			local moneyEarned = RANDOM:NextInteger(mafEffect.money[1], mafEffect.money[2])
			self:addMoney(state, moneyEarned)
			state.MobState.earnings = (state.MobState.earnings or 0) + moneyEarned
			resultMessage = resultMessage .. " Earned $" .. moneyEarned .. "."
		end
		state.MobState.operationsCompleted = (state.MobState.operationsCompleted or 0) + 1
		
		-- Risk check for mafia operations
		if activity.risk and RANDOM:NextInteger(1, 100) <= activity.risk then
			-- Got caught doing mafia business
			local jailYears = math.ceil(activity.risk / 15)
			state.InJail = true
			state.JailYearsLeft = jailYears
			state.Flags.in_prison = true
			state.Flags.incarcerated = true
			-- CRITICAL FIX #253: Preserve mob membership when jailed from mafia ops
			if state.Flags.in_mob or (state.MobState and state.MobState.inMob) then
				state.Flags.was_in_mob_before_jail = true
			end
			resultMessage = "You got caught! Sentenced to " .. jailYears .. " years in prison."
			gotCaught = true
		end
	end

	-- CRITICAL FIX #311: Don't push state for activities - this was causing screen closures!
	-- The client shows its own result popup via showResult() in ActivitiesScreen
	-- State will sync on next age up naturally
	-- self:pushState(player, resultMessage)  -- DISABLED - was closing ActivitiesScreen
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: RETURN ACTUAL STAT CHANGES TO CLIENT!
	-- User bug: "I CLICKED OK IT DIDNT GIVE THE STAT IT SAID"
	-- The stats ARE applied on server, but client doesn't know what changed!
	-- Now we send the actual stat deltas so client can show them in the popup
	-- ═══════════════════════════════════════════════════════════════════════════════
	local statChanges = {}
	if deltas then
		for stat, amount in pairs(deltas) do
			if amount ~= 0 then
				statChanges[stat] = amount
			end
		end
	end
	
	-- Also include cost in the response if paid
	local moneyCost = shouldChargeCost and actualCost or 0
	
	return { 
		success = true, 
		message = resultMessage, 
		gotCaught = gotCaught,
		-- CRITICAL: Send actual stat changes to client!
		statChanges = statChanges,
		cost = moneyCost,
		activityId = activityId,
		activityName = activity.feed or activityId,
	}
end

function LifeBackend:handleCrime(player, crimeId, minigameBonus)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "No life data loaded." }
	end
	
	local crime = CrimeCatalog[crimeId]
	if not crime then
		return { success = false, message = "Unknown crime." }
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #8: Prison crimes - certain crimes CAN be committed in prison
	-- These add to sentence if caught rather than blocking entirely
	-- ═══════════════════════════════════════════════════════════════════════════════
	local prisonCrimes = {
		prison_assault = true,
		prison_riot = true,
		prison_contraband = true,
		prison_gang_violence = true,
		assault = true, -- Can assault other inmates
	}
	
	if state.InJail then
		if not prisonCrimes[crimeId] then
			return { success = false, message = "You can't commit that crime while in prison. Try prison-specific crimes instead." }
		end
		
		-- Prison crime - higher risk of getting caught (guards everywhere)
		local prisonRoll = RANDOM:NextInteger(0, 100)
		local prisonCaught = prisonRoll < (crime.risk + 30) -- +30% risk in prison
		
		if prisonCaught then
			-- Add years to current sentence instead of starting new sentence
			local additionalYears = RANDOM:NextInteger(1, 5)
			state.JailYearsLeft = (state.JailYearsLeft or 0) + additionalYears
			state.Flags.prison_incident = true
			state.Flags.criminal_record = true
			
			self:applyStatChanges(state, { Happiness = -15, Health = -10 })
			local message = string.format("Guards caught you! %d years added to your sentence.", additionalYears)
			self:pushState(player, message)
			return { success = false, caught = true, message = message, additionalYears = additionalYears }
		else
			-- Got away with it
			local reward = 0
			if crime.reward then
				reward = RANDOM:NextInteger(crime.reward[1] or 0, crime.reward[2] or 100)
				-- Prison rewards are lower (contraband value)
				reward = math.floor(reward * 0.3)
				self:addMoney(state, reward)
			end
			state.Flags.prison_tough = true
			local message = "You got away with it. Your reputation in prison grew."
			if reward > 0 then
				message = string.format("Success! Gained $%d and prison respect.", reward)
			end
			self:pushState(player, message)
			return { success = true, caught = false, message = message, money = reward }
		end
	end

	state.Flags = state.Flags or {}

	local riskModifier = 0
	if state.Flags.criminal_tendencies then
		riskModifier = riskModifier - 10
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX (deep-15): Stats affect crime success rate!
	-- High Smarts = better planning = less likely to get caught
	-- High Health = faster getaway = less likely to get caught
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.Stats = state.Stats or {}
	local smarts = state.Stats.Smarts or state.Smarts or 50
	local health = state.Stats.Health or state.Health or 50
	
	-- Smart criminals plan better (up to -15% risk)
	if smarts >= 80 then
		riskModifier = riskModifier - 15
	elseif smarts >= 70 then
		riskModifier = riskModifier - 10
	elseif smarts >= 60 then
		riskModifier = riskModifier - 5
	elseif smarts < 30 then
		riskModifier = riskModifier + 10 -- Dumb criminals make mistakes
	end
	
	-- Physical crimes benefit from health (getaways, fights, etc.)
	local physicalCrimes = { "assault", "burglary", "gta", "bank_robbery", "car_theft", "prison_assault" }
	local isPhysicalCrime = false
	for _, physCrime in ipairs(physicalCrimes) do
		if crimeId:find(physCrime) then
			isPhysicalCrime = true
			break
		end
	end
	
	if isPhysicalCrime then
		if health >= 80 then
			riskModifier = riskModifier - 10
		elseif health >= 60 then
			riskModifier = riskModifier - 5
		elseif health < 30 then
			riskModifier = riskModifier + 15 -- Unhealthy = slow getaway
		end
	end
	
	-- Experience from prior crimes helps
	if state.Flags.experienced_criminal or state.Flags.criminal_mastermind then
		riskModifier = riskModifier - 10
	elseif state.Flags.criminal_record then
		riskModifier = riskModifier - 5 -- Some experience from past crimes
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Minigame bonus reduces risk of getting caught!
	-- Completing the heist minigame (like cracking a safe) gives you an advantage
	-- ═══════════════════════════════════════════════════════════════════════════════
	if minigameBonus == true then
		riskModifier = riskModifier - 20  -- 20% less likely to get caught
	elseif minigameBonus == false and crime.hasMinigame then
		-- Failed minigame for a crime that has one = higher risk
		riskModifier = riskModifier + 15  -- 15% more likely to get caught
	end

	local roll = RANDOM:NextInteger(0, 100)
	local caught = roll < (crime.risk + riskModifier)

	if caught then
		-- CRITICAL FIX: Use NextInteger, not NextNumber!
		-- NextNumber() returns a 0-1 float, NextInteger(min, max) returns proper integer range
		local years = RANDOM:NextInteger(crime.jail.min, crime.jail.max)
		state.InJail = true
		state.JailYearsLeft = years
		state.Flags.in_prison = true
		state.Flags.incarcerated = true
		
		-- ═══════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #252: Preserve mob membership flag when going to jail
		-- This backup flag ensures we restore in_mob after prison release
		-- ═══════════════════════════════════════════════════════════════════════
		if state.Flags.in_mob or (state.MobState and state.MobState.inMob) then
			state.Flags.was_in_mob_before_jail = true
			debugPrint("Preserved mob membership for jail duration:", player.Name)
		end
		
		-- CRITICAL FIX: Lose job when going to prison!
		-- In BitLife, you get fired when incarcerated. Save last job for potential re-employment.
		if state.CurrentJob then
			state.CareerInfo = state.CareerInfo or {}
			state.CareerInfo.lastJobBeforeJail = {
				id = state.CurrentJob.id,
				name = state.CurrentJob.name,
				company = state.CurrentJob.company,
				salary = state.CurrentJob.salary,
			}
			-- Clear current job
			state.CurrentJob = nil
			state.Flags.employed = nil
			state.Flags.has_job = nil
		end
		
		-- Also pause any education enrollment
		if state.EducationData and state.EducationData.Status == "enrolled" then
			state.EducationData.StatusBeforeJail = "enrolled"
			state.EducationData.Status = "suspended"
		end
		
		self:applyStatChanges(state, { Happiness = -10, Health = -5 })
		-- CRITICAL FIX: Only mention losing job if they actually had one
		local message
		if state.CareerInfo and state.CareerInfo.lastJobBeforeJail then
			message = string.format("You were caught! Sentenced to %.1f years. You lost your job.", years)
		else
			message = string.format("You were caught! Sentenced to %.1f years.", years)
		end
		-- CRITICAL FIX: Don't use showPopup - client shows its own result
		self:pushState(player, message)
		return { success = false, caught = true, message = message }
	else
		local payout = RANDOM:NextInteger(crime.reward[1], crime.reward[2])
		self:addMoney(state, payout)
		self:applyStatChanges(state, { Happiness = 4 })
		local message = string.format("Crime succeeded! You gained %s.", formatMoney(payout))
		-- CRITICAL FIX: Don't use showPopup - client shows its own result
		self:pushState(player, message)
		return { success = true, caught = false, message = message, money = payout }
	end
end

function LifeBackend:handlePrisonAction(player, actionId)
	local state = self:getState(player)
	if not state or not state.InJail then
		return { success = false, message = "You're not currently incarcerated." }
	end

	local action = PrisonActions[actionId]
	if not action then
		return { success = false, message = "Unknown prison action." }
	end

	state.Flags = state.Flags or {}

	if action.moneyCost and (state.Money or 0) < action.moneyCost then
		return { success = false, message = "You can't afford that legal help." }
	end

	if action.moneyCost then
		self:addMoney(state, -action.moneyCost)
	end

	if action.stats then
		self:applyStatChanges(state, action.stats)
	end

	if action.jailReduction then
		state.JailYearsLeft = math.max(0, (state.JailYearsLeft or 0) - action.jailReduction)
	end

	-- CRITICAL FIX: Support for jailIncrease (for failed escape attempts)
	-- NOTE: Client handles showing the popup, so we DON'T send showPopup here
	-- to avoid DOUBLE POPUP bug
	if action.jailIncrease then
		state.JailYearsLeft = (state.JailYearsLeft or 0) + action.jailIncrease
		-- MINOR FIX: Use %.1f for consistent decimal formatting
		local message = string.format("Your escape failed. %.1f years added to your sentence.", action.jailIncrease)
		self:pushState(player, message)
		return { success = false, message = message }
	end

	if action.risk and RANDOM:NextInteger(1, 100) <= action.risk then
		local message = "Guards caught you. Your sentence increased."
		state.JailYearsLeft = (state.JailYearsLeft or 0) + 1
		self:applyStatChanges(state, { Happiness = -5 })
		self:pushState(player, message)
		return { success = false, message = message }
	end

	if actionId == "prison_escape" then
		-- CRITICAL FIX: Prison escape is now determined by the client-side minigame!
		-- The client calls "prison_escape" only after winning the minigame.
		-- So if we get here, the player WON the minigame and should escape!
		
		state.awaitingDecision = true
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: FREE THE PLAYER IMMEDIATELY when they win the minigame!
		-- Don't wait for the choice - they already escaped by winning the minigame.
		-- The event card is just asking what they do AFTER escaping.
		-- ═══════════════════════════════════════════════════════════════════════════════
		state.InJail = false
		state.JailYearsLeft = 0
		state.Flags.in_prison = nil
		state.Flags.incarcerated = nil
		state.Flags.escaped_prisoner = true
		state.Flags.fugitive = true
		state.PendingFeed = nil
		state.YearLog = {}
		
		-- ═══════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #269: Restore mob membership after prison escape
		-- ═══════════════════════════════════════════════════════════════════════════
		if state.MobState and state.MobState.inMob then
			state.Flags.in_mob = true
			state.Flags.mafia_member = true
			state.MobState.heat = math.min(100, (state.MobState.heat or 0) + 20) -- Escaping raises heat
		elseif state.Flags.was_in_mob_before_jail then
			state.Flags.in_mob = true
			state.Flags.mafia_member = true
			state.Flags.was_in_mob_before_jail = nil
			state.MobState = state.MobState or {}
			state.MobState.inMob = true
			state.MobState.heat = math.min(100, (state.MobState.heat or 0) + 20)
		end
		
		-- Player won the minigame - they escape successfully!
		local eventDef = {
			id = "prison_escape_success",
			title = "🎉 Escape Successful!",
			emoji = "🏃",
			text = "Against all odds, you made it over the wall and into freedom! You're now a fugitive - but you're FREE!",
			question = "What's your plan now?",
			-- CRITICAL FIX: Use "success" category so card shows GREEN border!
			category = "success",
			source = "lifeevents",
			choices = {
				{ 
					text = "Lay low and start fresh", 
					effects = { Happiness = 20 },
					setFlags = { escaped_prisoner = true, fugitive = true, criminal_record = true },
					feedText = "🏃 You escaped prison! Now living as a fugitive.",
				},
				{ 
					text = "Leave the country", 
					effects = { Happiness = 15, Money = -5000 },
					setFlags = { escaped_prisoner = true, fugitive = true, fled_country = true },
					feedText = "🏃 You escaped and fled to another country!",
				},
			},
			-- Backup onComplete just to make absolutely sure
			onComplete = function(state, choice, eventDef, outcome)
				-- Ensure flags are set (they should already be, but just in case)
				state.InJail = false
				state.JailYearsLeft = 0
				state.Flags.in_prison = nil
				state.Flags.incarcerated = nil
			end,
		}
		
		-- CRITICAL FIX: Changed feedText to show success
		self:presentEvent(player, eventDef, "🏃 You're FREE! You escaped!")
		return { success = true, message = "Escape successful!" }
	end

	if (state.JailYearsLeft or 0) <= 0 then
		state.InJail = false
		state.Flags.in_prison = nil
		state.Flags.incarcerated = nil
		self:pushState(player, "You're now free!")
		return { success = true, message = "Sentence complete! You're free." }
	end

	local message = action.feed or "You passed some time."
	self:pushState(player, message)
	return { success = true, message = message }
end

-- ============================================================================
-- Career / Education
-- ============================================================================

function LifeBackend:meetsEducationRequirement(state, requirement)
	if not requirement then
		return true
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #693-700: COMPREHENSIVE ROYAL EDUCATION CHECK
	-- Royals may have their education stored in EducationData.Level instead of state.Education
	-- Also check royal flags that indicate completed education
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	local playerEducation = state.Education or "none"
	local playerRank = EducationRanks[playerEducation] or 0
	
	-- CRITICAL FIX #694: Check EducationData.Level for royal education
	if state.EducationData then
		local eduLevel = state.EducationData.Level
		if eduLevel then
			local eduLevelRank = EducationRanks[eduLevel] or 0
			if eduLevelRank > playerRank then
				playerRank = eduLevelRank
			end
		end
		
		-- CRITICAL FIX #695: Royal education flag means at least high school equivalent
		if state.EducationData.isRoyalEducation then
			playerRank = math.max(playerRank, 1) -- At least high school level
		end
	end
	
	-- CRITICAL FIX #696: Check education flags for additional qualifications
	local flags = state.Flags or {}
	
	-- Royal education flags indicate high school equivalent or better
	if flags.private_education or flags.royal_education_started or flags.palace_educated 
		or flags.prep_school_student or flags.boarding_student then
		playerRank = math.max(playerRank, 1) -- At least high school level
	end
	
	-- Graduated flags indicate completed education
	if flags.high_school_graduate or flags.graduated_high_school 
		or flags.royal_graduated or flags.elite_boarding_graduate then
		playerRank = math.max(playerRank, 1) -- Confirmed high school level
	end
	
	-- CRITICAL FIX #697: has_ged counts as high school equivalent
	if flags.has_ged or flags.has_ged_or_diploma then
		playerRank = math.max(playerRank, 1)
	end
	
	-- CRITICAL FIX #698: College-related flags indicate higher education
	if flags.college_bound or flags.in_college then
		-- They're pursuing higher education, so they must have high school
		playerRank = math.max(playerRank, 1)
	end
	
	if flags.college_graduate then
		playerRank = math.max(playerRank, 3) -- Bachelor's level
	end
	
	-- CRITICAL FIX #699: Royal university completion
	if flags.oxford_graduate or flags.cambridge_graduate or flags.st_andrews_graduate 
		or flags.ivy_league_graduate or flags.royal_university_graduate then
		playerRank = math.max(playerRank, 3) -- Bachelor's level
	end
	
	-- CRITICAL FIX #700: Military academy counts as education
	if flags.sandhurst_graduate or flags.military_academy_graduate or flags.officer_candidate then
		playerRank = math.max(playerRank, 2) -- Above high school
	end
	
	local jobRank = EducationRanks[requirement] or 0
	return playerRank >= jobRank
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #338: Get Job Eligibility for ALL jobs
-- Returns a table of job IDs mapped to eligibility info
-- This allows the client to show which jobs are available vs locked
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:getJobEligibility(player)
	local state = self:getState(player)
	if not state then
		return {}
	end
	
	local eligibility = {}
	state.Flags = state.Flags or {}
	state.Stats = state.Stats or {}
	
	for jobId, job in pairs(JobCatalog) do
		local info = {
			eligible = true,
			reasons = {},
			missingFlags = {},
			missingEdu = nil,
			missingStats = {},
			tooYoung = false,
		}
		
		-- Check age requirement
		if (state.Age or 0) < (job.minAge or 0) then
			info.eligible = false
			info.tooYoung = true
			table.insert(info.reasons, string.format("Must be %d+ years old", job.minAge))
		end
		
		-- Check education requirement
		if job.requirement and not self:meetsEducationRequirement(state, job.requirement) then
			info.eligible = false
			info.missingEdu = job.requirement
			local eduNames = { 
				high_school = "High School Diploma", 
				bachelor = "Bachelor's Degree", 
				master = "Master's Degree", 
				phd = "PhD", 
				medical = "Medical Degree", 
				law = "Law Degree", 
				community = "Community College" 
			}
			table.insert(info.reasons, string.format("Requires %s", eduNames[job.requirement] or job.requirement))
		end
		
		-- Check stat requirements
		if job.minStats then
			for statName, minValue in pairs(job.minStats) do
				local playerStat = state.Stats[statName] or state[statName] or 50
				if playerStat < minValue then
					info.eligible = false
					info.missingStats[statName] = { required = minValue, current = playerStat }
					table.insert(info.reasons, string.format("%s too low (%d/%d)", statName, playerStat, minValue))
				end
			end
		end
		
		-- CRITICAL FIX #339: Check experience/flag requirements
		-- This is the key fix - jobs requiring experience will be locked!
		if job.requiresFlags then
			local hasAnyRequiredFlag = false
			for _, flagName in ipairs(job.requiresFlags) do
				if state.Flags[flagName] then
					hasAnyRequiredFlag = true
					break
				end
			end
			
			if not hasAnyRequiredFlag then
				info.eligible = false
				info.missingFlags = job.requiresFlags
				
				-- Provide helpful experience message
				local expMessages = {
					-- Racing career
					karting_experience = "Go-kart racing experience",
					racing_experience = "Racing experience",
					amateur_racing = "Amateur racing experience",
					pro_racer = "Professional racing career",
					f1_experience = "F1 driving experience",
					racing_champion = "Racing championship title",
					-- Sports career
					athlete = "Athletic background",
					sports_team = "School sports experience",
					school_sports = "School sports team participation",
					plays_soccer = "Soccer team experience",
					plays_basketball = "Basketball team experience",
					varsity_athlete = "Varsity sports experience",
					team_player = "Team sports experience",
					camp_athlete = "Sports camp experience",
					minor_league_player = "Minor league experience",
					pro_athlete = "Professional athlete career",
					pro_sports_experience = "Professional sports experience",
					fitness_experience = "Fitness/gym experience",
					trainer = "Trainer experience",
					-- Creative career
					acting_experience = "Acting experience",
					professional_actor = "Professional acting career",
					drama_club = "Drama/theater experience",
					theater_experience = "Theater experience",
					film_industry = "Film industry experience",
					musician = "Musical ability",
					plays_instrument = "Instrument proficiency",
					local_musician = "Local music experience",
					music_experience = "Music performance experience",
					in_a_band = "Band membership",
					music_lessons = "Music education/lessons",
					signed_artist = "Record label contract",
					recording_artist = "Recording artist experience",
					-- Tech career
					coder = "Coding skills",
					computer_skills = "Computer proficiency",
					developer_experience = "Developer experience",
					tech_experience = "Tech industry experience",
					hacker_experience = "Hacking skills",
					tech_lead = "Tech leadership experience",
					engineering_leadership = "Engineering management experience",
					-- Medical career
					nursing_experience = "Nursing experience",
					medical_experience = "Medical field experience",
					clinical_experience = "Clinical experience",
					residency_complete = "Medical residency",
					hospital_work = "Hospital work experience",
					rn_license = "RN nursing license",
					licensed_doctor = "Medical doctor license",
					attending_physician = "Attending physician experience",
					doctor_training = "Medical doctor training",
					-- Coaching/teaching
					coach_experience = "Coaching experience",
					coaching_career = "Coaching career experience",
					-- CRITICAL FIX: ESports career flags
					gamer = "Gaming hobby background",
					loves_games = "Passion for gaming",
					casual_gamer = "Casual gaming experience",
					tech_savvy = "Tech-savvy background",
					streamer = "Streaming experience",
					content_creator_experience = "Content creation experience",
					esports_experience = "Esports experience",
					youtube_gamer = "YouTube gaming content",
					content_creator = "Content creator background",
					growing_audience = "Growing online audience",
					competitive_gamer = "Competitive gaming experience",
					esports_winner = "Esports tournament wins",
					pro_gamer = "Professional gaming career",
					esports_pro = "Esports professional status",
					signed_gamer = "Esports organization contract",
					esports_champion = "Esports championship title",
					world_champion_gamer = "World championship title",
					gaming_celebrity = "Gaming celebrity status",
					-- CRITICAL FIX #22: Criminal career flags
					petty_criminal = "Petty crime background (shoplifting, vandalism)",
					street_smart = "Street smarts (know the criminal underworld)",
					vandal = "Vandalism/graffiti experience",
					shoplifter = "Shoplifting experience",
					delinquent = "Juvenile delinquent background",
					criminal_tendencies = "Criminal tendencies",
					bully = "History of aggressive behavior",
					troublemaker = "Troublemaker reputation",
					street_hustler = "Street hustling experience",
					drug_dealer_experience = "Drug dealing experience",
					criminal_path = "Criminal lifestyle commitment",
					criminal = "Criminal background",
					criminal_connections = "Criminal network connections",
					established_dealer = "Established dealer status",
					violent_crimes = "Violent crime history",
					street_fighter = "Street fighting experience",
					brawler = "Brawler reputation",
					enforcer_reputation = "Enforcer reputation",
					crew_member_status = "Criminal crew membership",
					organized_crime = "Organized crime experience",
					loyalty_tested = "Proven criminal loyalty",
					crew_leader_status = "Crew leadership experience",
					criminal_leadership = "Criminal organization leadership",
					respected_criminal = "Respected in criminal circles",
					thief = "Theft/burglary experience",
					burglar = "Burglary experience",
					in_mob = "Mafia/mob membership",
					-- Hacker career
					elite_hacker_rep = "Elite hacker reputation",
					cyber_crime_history = "Cyber crime background",
					-- CRITICAL FIX: Law career flags
					legal_experience = "Legal industry experience",
					law_firm_experience = "Law firm work experience",
					paralegal_experience = "Paralegal experience",
					legal_research = "Legal research skills",
					bar_license = "Bar exam passed / License to practice",
					practicing_attorney = "Practicing attorney experience",
					litigation_experience = "Litigation experience",
					experienced_attorney = "Senior attorney experience",
					senior_lawyer = "Senior lawyer status",
					law_firm_partner = "Law firm partner status",
					legal_leadership = "Legal leadership experience",
					prosecution_experience = "Prosecution experience",
					defense_experience = "Defense attorney experience",
					courtroom_experience = "Courtroom experience",
					criminal_law = "Criminal law experience",
					judicial_experience = "Judicial experience",
					-- CRITICAL FIX: Finance career flags
					banking_experience = "Banking industry experience",
					financial_services = "Financial services experience",
					customer_service = "Customer service experience",
					loan_experience = "Loan processing experience",
					credit_analysis = "Credit analysis skills",
					accounting_experience = "Accounting experience",
					financial_analysis = "Financial analysis skills",
					bookkeeping = "Bookkeeping experience",
					senior_accountant = "Senior accountant experience",
					audit_experience = "Audit experience",
					cpa_certified = "CPA certification",
					tax_expert = "Tax expertise",
					investment_experience = "Investment experience",
					market_analysis = "Market analysis skills",
					investment_banking = "Investment banking experience",
					deal_experience = "M&A deal experience",
					wall_street = "Wall Street experience",
					senior_banker = "Senior banker status",
					m_and_a_experience = "Mergers & acquisitions experience",
					fund_manager = "Fund management experience",
					portfolio_management = "Portfolio management skills",
					actuary_certified = "Actuary certification",
					risk_analysis = "Risk analysis skills",
					-- CRITICAL FIX #26: Education career flags
					teaching_experience = "Teaching assistant experience",
					classroom_experience = "Classroom experience",
					school_staff = "School staff experience",
					substitute_teaching = "Substitute teaching experience",
					teacher_experience = "Teacher experience",
					certified_teacher = "Certified teacher status",
					classroom_management = "Classroom management skills",
					department_leadership = "Department head experience",
					curriculum_experience = "Curriculum development experience",
					school_administrator = "School administrator experience",
					education_leadership = "Educational leadership experience",
					academic_research = "Academic research experience",
					university_faculty = "University faculty status",
					higher_education = "Higher education experience",
					tenured_professor = "Tenured professor status",
					research_leader = "Research leadership experience",
					-- CRITICAL FIX #27: Government career flags
					law_enforcement = "Law enforcement experience",
					police_experience = "Police officer experience",
					public_service = "Public service experience",
					detective_experience = "Detective experience",
					investigator = "Investigator experience",
					police_leadership = "Police leadership experience",
					firefighter_experience = "Firefighter experience",
					first_responder = "First responder experience",
					fire_leadership = "Fire department leadership",
					political_experience = "Political experience",
					elected_official = "Elected official status",
					local_politics = "Local politics experience",
					executive_experience = "Executive government experience",
					city_leadership = "City leadership experience",
					federal_agent = "Federal agent experience",
					intelligence_agent = "Intelligence agency experience",
					security_clearance = "Security clearance",
					senator_status = "Senator/national legislator status",
					national_politics = "National politics experience",
					state_politics = "State politics experience",
				}
				
				local expText = expMessages[job.requiresFlags[1]] or "Specialized experience"
				table.insert(info.reasons, string.format("Requires %s", expText))
			end
		end
		
		-- Check promotion-only status
		if PromotionOnlyJobs[jobId] then
			info.eligible = false
			info.promotionOnly = true
			table.insert(info.reasons, "Promotion only - can't apply directly")
		end
		
		-- Check criminal record for strict jobs
		if state.Flags.criminal_record then
			local strictCategories = { "law", "government", "finance", "education", "military" }
			for _, cat in ipairs(strictCategories) do
				if job.category == cat then
					info.eligible = false
					info.criminalRecord = true
					table.insert(info.reasons, "Criminal record disqualifies you")
					break
				end
			end
		end
		
		eligibility[jobId] = info
	end
	
	return eligibility
end

-- ============================================================================
-- CRITICAL FIX: Job Rejection Messages for variety and realism
-- ============================================================================
-- MINOR FIX: Expanded rejection messages for more variety
local JobRejectionMessages = {
	generic = {
		"After careful consideration, we've decided to go with another candidate.",
		"Unfortunately, your application was not successful this time.",
		"We appreciate your interest, but we're looking for someone with more experience.",
		"Thank you for applying, but we've filled the position.",
		"Your qualifications don't quite match what we're looking for right now.",
		"We're moving forward with other candidates at this time.",
		"While your application was strong, we found a better fit.",
	},
	lowStats = {
		"You didn't pass the physical fitness requirements.",
		"The aptitude test results weren't quite what we were hoping for.",
		"We need someone with stronger qualifications for this role.",
		"Your skills assessment didn't meet our requirements.",
	},
	competitive = {
		"This position attracted many highly qualified candidates.",
		"Competition for this role was extremely fierce.",
		"We received over 500 applications for this position.",
		"The hiring committee narrowed it down and chose someone else.",
	},
	entry = {
		"Even entry-level positions can be competitive these days!",
		"We're looking for someone with a bit more availability.",
		"Your interview went well, but another candidate edged you out.",
		"Keep applying! The right opportunity will come.",
	},
	-- CRITICAL FIX: Messages for when criminal record affects job chances
	criminalRecord = {
		"The background check revealed some concerns.",
		"We need to go with a candidate without legal issues.",
		"Our policy requires a clean record for this position.",
		"Your qualifications were good, but the background check was problematic.",
	},
}

-- NOTE: PromotionOnlyJobs is defined earlier (after JobCatalog) to fix scope issues

function LifeBackend:handleJobApplication(player, jobId)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data not loaded." }
	end

	-- CRITICAL FIX #512: Use findJobByInput for flexible job lookup
	-- This allows the client to send job IDs, names, or partial matches
	-- Fixes "Unknown Job" for jobs like "Hobbyist Streamer" and "New Content Creator"
	local job = JobCatalog[jobId] or self:findJobByInput(jobId)
	if not job then
		warn("[LifeBackend] Unknown job application:", jobId)
		return { success = false, message = "Unknown job." }
	end
	
	-- Use the actual job ID for further checks (in case client sent a name)
	local actualJobId = job.id
	
	-- CRITICAL FIX: Block direct application to promotion-only positions
	if PromotionOnlyJobs[actualJobId] then
		return { 
			success = false, 
			message = "This position requires years of experience and internal promotion. You can't apply directly." 
		}
	end

	if state.InJail then
		return { success = false, message = "You can't apply while incarcerated." }
	end

	if (state.Age or 0) < job.minAge then
		return { success = false, message = string.format("You must be at least %d years old to apply.", job.minAge) }
	end

	if not self:meetsEducationRequirement(state, job.requirement) then
		local eduNames = { high_school = "a High School Diploma", bachelor = "a Bachelor's Degree", master = "a Master's Degree", 
			phd = "a PhD", medical = "a Medical Degree", law = "a Law Degree", community = "a Community College certificate" }
		local needed = eduNames[job.requirement] or "more education"
		return { success = false, message = string.format("This position requires %s.", needed) }
	end

	-- CRITICAL FIX: Check minStats requirements (for physical/demanding jobs)
	if job.minStats then
		state.Stats = state.Stats or {}
		for statName, minValue in pairs(job.minStats) do
			local playerStat = state.Stats[statName] or state[statName] or 50
			if playerStat < minValue then
				local statDisplayName = statName:gsub("^%l", string.upper)
				local gap = minValue - playerStat
				local severity = gap > 20 and "far below" or (gap > 10 and "below" or "slightly below")
				return { 
					success = false, 
					message = string.format("You're %s the %s requirement (%d needed, you have %d). Work on improving yourself!", severity, statDisplayName, minValue, playerStat) 
				}
			end
		end
	end
	
	-- CRITICAL FIX: Check requiresFlags (for specialized jobs like hacking that need prior experience)
	if job.requiresFlags then
		state.Flags = state.Flags or {}
		local hasRequiredExperience = false
		local requiredFlagNames = {}
		
		for _, flagName in ipairs(job.requiresFlags) do
			table.insert(requiredFlagNames, flagName)
			if state.Flags[flagName] then
				hasRequiredExperience = true
				break -- Only need ONE of the flags
			end
		end
		
		if not hasRequiredExperience then
			-- CRITICAL FIX #335: Provide helpful messages about what experience is needed for ALL career paths
			local experienceMessages = {
				-- Tech/Hacking
				coder = "coding skills (try computer camp or study programming)",
				tech_experience = "tech industry experience (work in IT first)",
				hacker_experience = "hacking experience (start as a script kiddie first)",
				elite_hacker_rep = "elite hacker reputation (prove yourself as a black hat first)",
				cyber_crime_history = "cyber crime background (work your way up the criminal ladder)",
				-- Racing career
				karting_experience = "go-kart racing experience (start racing go-karts as a kid!)",
				racing_experience = "racing experience (you need to race before going pro!)",
				amateur_racing = "amateur racing experience (work your way up from go-karts)",
				pro_racer = "professional racing experience (compete in national racing first)",
				f1_experience = "Formula 1 experience (must be a pro racer first)",
				racing_champion = "racing championship wins (achieve greatness on the track)",
				-- Sports career
				athlete = "athletic experience (join school sports teams as a kid)",
				sports_team = "sports team experience (play on school teams)",
				varsity_athlete = "varsity sports experience (excel at high school sports)",
				school_sports = "school sports background (join teams in school)",
				minor_league_player = "minor league experience (work up from school sports)",
				pro_sports_experience = "professional sports experience (play minor leagues first)",
				pro_athlete = "professional athlete career (you must play pro sports first)",
				sports_star = "sports stardom (become a pro athlete first)",
				coach_experience = "coaching experience (coach at lower levels first)",
				-- Acting career
				acting_experience = "acting experience (try drama club or background acting)",
				drama_club = "drama/theater experience (join drama club in school)",
				theater_experience = "theater experience (perform in plays/shows)",
				film_industry = "film industry experience (work as a background actor first)",
				professional_actor = "professional acting career (work as an actor first)",
				celebrity = "celebrity status (become a successful actor first)",
				-- Music career
				musician = "musical ability (learn an instrument or take music lessons)",
				plays_instrument = "instrument skills (practice music as a hobby)",
				in_a_band = "band experience (play in a band)",
				music_lessons = "formal music training (take music lessons)",
				local_musician = "local music scene experience (play local gigs first)",
				music_experience = "music industry experience (perform at local venues)",
				signed_artist = "record label contract (get signed as an artist first)",
				recording_artist = "recording experience (make music professionally)",
				-- Tech career
				computer_skills = "computer skills (use computers as a hobby, join computer club)",
				coding_bootcamp = "coding bootcamp (complete a programming course)",
				developer_experience = "developer experience (work as a junior developer first)",
				software_engineer = "software engineering background",
				mid_level_dev = "mid-level developer experience (work as a developer first)",
				senior_dev = "senior developer experience (work up from developer)",
				tech_leader = "technical leadership experience",
				tech_lead = "tech lead experience (lead development teams first)",
				engineering_leadership = "engineering leadership background",
				it_background = "IT background (work in tech support first)",
				web_dev = "web development experience",
				mobile_dev = "mobile development experience",
				data_experience = "data analysis experience (work as a data analyst first)",
				analytics = "analytics background",
				data_scientist = "data science experience",
				ml_experience = "machine learning experience",
				security_experience = "security experience (work in cybersecurity first)",
				cybersecurity = "cybersecurity background",
				devops = "DevOps experience",
				-- CRITICAL FIX: ESports career experience messages
				gamer = "gaming hobby (develop gaming skills during childhood/teen years)",
				loves_games = "passion for gaming (be a dedicated gamer as a kid)",
				casual_gamer = "casual gaming background (play games regularly)",
				tech_savvy = "tech-savvy skills (be comfortable with technology)",
				streamer = "streaming experience (start streaming as a casual gamer)",
				content_creator_experience = "content creation experience (start streaming first)",
				esports_experience = "esports experience (compete in gaming tournaments)",
				youtube_gamer = "YouTube gaming presence (build a following)",
				content_creator = "content creator background (grow your gaming channel)",
				growing_audience = "growing online audience (build streaming viewership)",
				competitive_gamer = "competitive gaming experience (win gaming tournaments)",
				esports_winner = "esports tournament wins (prove yourself in competition)",
				pro_gamer = "professional gaming career (work as a pro gamer first)",
				esports_pro = "esports professional status (be signed to an org)",
				signed_gamer = "esports org contract (get signed as pro gamer)",
				esports_champion = "esports championship title (win major tournaments)",
				world_champion_gamer = "world championship status (become a world champion)",
				gaming_celebrity = "gaming celebrity status (achieve fame as a gamer)",
				-- Medical career
				medical_experience = "medical experience (work in healthcare first)",
				nursing_experience = "nursing experience (work as a nurse first)",
				clinical_experience = "clinical experience (work in a medical setting)",
				residency_complete = "completed medical residency",
				surgical_experience = "surgical experience (work as a surgeon first)",
				hospital_work = "hospital work experience (start as orderly or assistant)",
				rn_license = "RN nursing license (complete nursing education)",
				licensed_doctor = "medical doctor license (complete residency)",
				attending_physician = "attending physician experience (practice as doctor first)",
				doctor_training = "medical doctor training (complete medical school)",
				-- CRITICAL FIX #22: Criminal career experience messages
				petty_criminal = "petty crime background (commit minor crimes like shoplifting, vandalism)",
				street_smart = "street smarts (learn the criminal underworld through experience)",
				vandal = "vandalism experience (engage in property destruction)",
				shoplifter = "shoplifting experience (steal from stores)",
				delinquent = "delinquent background (get in trouble as a youth)",
				criminal_tendencies = "criminal tendencies (show willingness to break the law)",
				bully = "aggressive behavior history (intimidate others)",
				troublemaker = "troublemaker reputation (cause problems in your community)",
				street_hustler = "street hustling experience (work as a street hustler first)",
				drug_dealer_experience = "drug dealing experience (sell drugs on the street)",
				criminal_path = "criminal lifestyle (commit to a life of crime)",
				criminal = "criminal background (engage in criminal activities)",
				criminal_connections = "criminal network (build connections in the underworld)",
				established_dealer = "established dealer status (prove yourself in drug trade)",
				violent_crimes = "violent crime history (engage in violence)",
				street_fighter = "street fighting experience (prove yourself in fights)",
				brawler = "brawler reputation (be known for physical violence)",
				enforcer_reputation = "enforcer reputation (be known as muscle)",
				crew_member_status = "crew membership (join a criminal crew first)",
				organized_crime = "organized crime experience (work in criminal organization)",
				loyalty_tested = "proven loyalty (prove yourself to the organization)",
				crew_leader_status = "crew leader experience (lead a criminal crew first)",
				criminal_leadership = "criminal leadership (manage criminal operations)",
				respected_criminal = "criminal respect (earn respect in the underworld)",
				thief = "theft experience (successfully steal from others)",
				burglar = "burglary experience (break into buildings to steal)",
				in_mob = "mafia membership (join the mob first)",
				-- Sports coaching
				fitness_experience = "fitness/gym experience (work as gym instructor first)",
				trainer = "trainer experience (work as a fitness trainer)",
				coaching_career = "coaching career (work as a sports coach first)",
				-- CRITICAL FIX: Law career experience messages
				legal_experience = "legal industry experience (work at a law firm first)",
				law_firm_experience = "law firm experience (start as legal assistant)",
				paralegal_experience = "paralegal experience (work as a paralegal first)",
				legal_research = "legal research skills (gain experience as paralegal)",
				bar_license = "bar license (pass the bar exam after law school)",
				practicing_attorney = "practicing attorney experience (work as associate attorney)",
				litigation_experience = "litigation experience (try cases in court)",
				experienced_attorney = "senior attorney experience (practice law for years)",
				senior_lawyer = "senior lawyer status (be an experienced attorney)",
				courtroom_experience = "courtroom experience (prosecute or defend cases)",
				-- CRITICAL FIX: Finance career experience messages
				banking_experience = "banking experience (start as bank teller)",
				financial_services = "financial services background (work in banking)",
				accounting_experience = "accounting experience (work as junior accountant)",
				financial_analysis = "financial analysis skills (work in finance)",
				senior_accountant = "senior accountant experience (work up from junior)",
				cpa_certified = "CPA certification (pass CPA exam)",
				investment_experience = "investment experience (work in investments)",
				investment_banking = "investment banking experience (work as IB analyst)",
				deal_experience = "deal/M&A experience (close major transactions)",
				senior_banker = "senior banker experience (be a senior investment banker)",
				fund_manager = "fund management experience (manage investment portfolios)",
				market_analysis = "market analysis skills (analyze financial markets)",
				-- CRITICAL FIX #26: Education career experience messages
				teaching_experience = "teaching experience (start as teaching assistant)",
				classroom_experience = "classroom experience (work in a school)",
				teacher_experience = "teacher experience (work as substitute or full teacher)",
				certified_teacher = "certified teacher status (become a full-time teacher)",
				department_leadership = "department head experience (lead a department)",
				school_administrator = "school administrator experience (work as principal)",
				academic_research = "academic research experience (get PhD, do research)",
				university_faculty = "university faculty status (be assistant professor)",
				tenured_professor = "tenured professor status (earn tenure)",
				-- CRITICAL FIX #27: Government career experience messages
				police_experience = "police experience (work as police officer)",
				law_enforcement = "law enforcement experience (serve in police force)",
				detective_experience = "detective experience (work as detective)",
				firefighter_experience = "firefighter experience (serve as firefighter)",
				political_experience = "political experience (hold elected office)",
				elected_official = "elected official status (win an election)",
				local_politics = "local politics experience (serve on city council)",
				executive_experience = "executive experience (serve as mayor or equivalent)",
				senator_status = "senator/legislator status (serve in state or national legislature)",
				national_politics = "national politics experience (serve at national level)",
			}
			
			local helpText = experienceMessages[requiredFlagNames[1]] or "specialized experience in this field"
			return { 
				success = false, 
				message = string.format("This job requires %s. You don't have the necessary background.", helpText)
			}
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Celebrity Gamepass Check for Premium Fame Careers
	-- User feedback: "THE CELEB GAMEPASS DOES NOTHING"
	-- Rapper careers require celebrity gamepass, YouTuber/content creator stays free
	-- ═══════════════════════════════════════════════════════════════════════════════
	if job.requiresCelebrityGamepass then
		state.Flags = state.Flags or {}
		state.GamepassOwnership = state.GamepassOwnership or {}
		local hasCelebGamepass = state.Flags.celebrity_gamepass or 
			state.GamepassOwnership.celebrity or 
			state.GamepassOwnership.Celebrity
		
		if not hasCelebGamepass then
			return { 
				success = false, 
				message = "🌟 This career path requires the Celebrity Gamepass! Purchase it to pursue fame as a rapper, actor, or musician!",
				requiresGamepass = "CELEBRITY",
				gamepassId = 1626461980
			}
		end
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Job Application Rejection System
	-- Not every application should succeed! Add realistic interview/hiring mechanics.
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	state.JobApplications = state.JobApplications or {}
	local appHistory = state.JobApplications[jobId] or { attempts = 0, lastAttempt = 0, rejectedThisYear = false }
	
	-- Cooldown: Can't spam applications to the same job within the same year
	if appHistory.lastAttempt == (state.Age or 0) and appHistory.rejectedThisYear then
		return { 
			success = false, 
			message = string.format("You already applied to %s this year. Wait until next year to try again.", job.company)
		}
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Realistic job application system
	-- Job acceptance should NOT be automatic - difficulty matters!
	-- ═══════════════════════════════════════════════════════════════════════════════
	local difficulty = job.difficulty or 1
	
	-- Base chance calculation - MUCH more realistic now
	-- Scale: 1-10 difficulty where 10 is nearly impossible
	local baseChance
	if difficulty >= 10 then
		baseChance = 0.03 -- 3% - Near impossible (Movie Star, President, Pro Athlete)
	elseif difficulty >= 9 then
		baseChance = 0.08 -- 8% - Elite (CTO, Senator, Music Icon)
	elseif difficulty >= 8 then
		baseChance = 0.12 -- 12% - Very competitive (CEO, Hollywood Actor)
	elseif difficulty >= 7 then
		baseChance = 0.20 -- 20% - Highly competitive (CMO, Recording Artist)
	elseif difficulty >= 6 then
		baseChance = 0.30 -- 30% - Competitive (Detective, Pro Musician)
	elseif difficulty >= 5 then
		baseChance = 0.40 -- 40% - Above average difficulty
	elseif difficulty >= 4 then
		baseChance = 0.50 -- 50% - Moderate difficulty
	elseif difficulty >= 3 then
		baseChance = 0.60 -- 60% - Some competition
	elseif difficulty >= 2 then
		baseChance = 0.70 -- 70% - Entry-level with competition
	else
		baseChance = 0.80 -- 80% - Basic entry jobs anyone can get
	end
	
	-- Experience bonus - REDUCED from original to prevent god-mode
	state.CareerInfo = state.CareerInfo or {}
	local yearsExperience = state.CareerInfo.totalYearsWorked or 0
	local experienceBonus = math.min(0.10, yearsExperience * 0.01) -- Up to +10% for 10+ years experience (was +20%)
	
	-- Industry experience bonus - REDUCED
	if state.Career and state.Career.track == job.category then
		experienceBonus = experienceBonus + 0.08 -- Industry experience helps (was +15%)
	end
	
	-- Stat bonus - REDUCED to prevent stats from overriding difficulty
	state.Stats = state.Stats or {}
	local statBonus = 0
	if job.category == "tech" or job.category == "office" or job.category == "science" or job.category == "law" or job.category == "finance" then
		local smarts = state.Stats.Smarts or state.Smarts or 50
		statBonus = math.clamp((smarts - 50) / 400, -0.10, 0.10) -- +/-10% based on Smarts (was +/-25%)
	elseif job.category == "military" or job.category == "sports" or job.category == "trades" then
		local health = state.Stats.Health or state.Health or 50
		statBonus = math.clamp((health - 50) / 400, -0.10, 0.10) -- +/-10% based on Health (was +/-25%)
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #22: Education GPA affects job applications
	-- Good grades should help you get better jobs, bad grades hurt your chances
	-- ═══════════════════════════════════════════════════════════════════════════════
	local gpaBonus = 0
	if state.EducationData and state.EducationData.GPA then
		local gpa = state.EducationData.GPA or 0
		-- GPA 4.0 = +10% bonus, GPA 2.0 = -5% penalty
		if gpa >= 3.8 then
			gpaBonus = 0.10 -- Summa cum laude - excellent!
		elseif gpa >= 3.5 then
			gpaBonus = 0.07 -- Magna cum laude - very good
		elseif gpa >= 3.0 then
			gpaBonus = 0.03 -- Dean's list - above average
		elseif gpa >= 2.5 then
			gpaBonus = 0 -- Average - no bonus or penalty
		elseif gpa >= 2.0 then
			gpaBonus = -0.05 -- Below average - slight penalty
		else
			gpaBonus = -0.10 -- Poor GPA - significant penalty
		end
		
		-- GPA matters more for competitive jobs
		if difficulty >= 6 then
			gpaBonus = gpaBonus * 1.5 -- 50% more impact for competitive jobs
		end
	elseif state.Flags and state.Flags.honors_student then
		gpaBonus = 0.05 -- Honors flag gives small bonus even without explicit GPA
	elseif state.Flags and state.Flags.valedictorian then
		gpaBonus = 0.10 -- Valedictorian gets significant boost
	end
	
	-- Previous rejection penalty (companies remember bad interviews)
	local rejectionPenalty = math.min(0.20, (appHistory.attempts or 0) * 0.08) -- -8% per previous rejection, max -20%
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #27: Criminal record affects job applications!
	-- Employers run background checks - having a record makes it much harder to get hired
	-- Some jobs (law enforcement, government, finance) outright reject ex-convicts
	-- ═══════════════════════════════════════════════════════════════════════════════
	local criminalPenalty = 0
	if state.Flags and state.Flags.criminal_record then
		-- Jobs that do strict background checks and won't hire ex-convicts
		local strictBackgroundCheckCategories = {
			"law", "government", "finance", "education", "healthcare", "military", "security"
		}
		
		-- CRITICAL FIX #27: Expanded list of specific jobs that require clean records
		local strictBackgroundCheckJobIds = {
			-- Law enforcement
			"police", "officer", "detective", "sheriff", "fbi", "cia", "dea", "marshal", "agent",
			-- Government
			"senator", "congressman", "mayor", "governor", "president", "judge", "prosecutor", "attorney_general",
			"city_council", "state_rep", "diplomat", "ambassador",
			-- Finance
			"banker", "accountant", "auditor", "financial_advisor", "broker", "trader",
			-- Education
			"teacher", "professor", "principal", "dean", "counselor", "coach",
			-- Healthcare
			"doctor", "nurse", "surgeon", "pharmacist", "dentist", "therapist", "emt", "paramedic",
			-- Military/Security
			"soldier", "marine", "pilot", "security_guard", "bodyguard", "guard",
			-- Childcare
			"daycare", "babysitter", "nanny", "childcare",
		}
		
		local isStrictJob = false
		local jobIdLower = job.id and job.id:lower() or ""
		local jobCategoryLower = job.category and job.category:lower() or ""
		
		-- Check category
		for _, category in ipairs(strictBackgroundCheckCategories) do
			if jobCategoryLower == category or jobIdLower:find(category) then
				isStrictJob = true
				break
			end
		end
		
		-- Check specific job IDs
		if not isStrictJob then
			for _, restrictedId in ipairs(strictBackgroundCheckJobIds) do
				if jobIdLower:find(restrictedId) then
					isStrictJob = true
					break
				end
			end
		end
		
		if isStrictJob then
			-- Strict background check jobs won't hire people with records
			return {
				success = false,
				message = "Your background check revealed a criminal record. This position requires a clean record."
			}
		end
		
		-- Other jobs have a penalty but not automatic rejection
		criminalPenalty = 0.30 -- 30% penalty for having a record
		
		-- Fugitives face even harsher penalties
		if state.Flags.fugitive or state.Flags.escaped_prisoner then
			criminalPenalty = 0.50 -- 50% penalty for being a fugitive
		end
	end
	
	-- CRITICAL FIX: Cap maximum chance based on difficulty
	-- Even with perfect stats, difficult jobs should remain difficult
	local maxChance = 1.0 - (difficulty * 0.05) -- difficulty 10 caps at 50%, difficulty 1 caps at 95%
	maxChance = math.clamp(maxChance, 0.30, 0.95)
	
	-- CRITICAL FIX #22: Include GPA bonus in final chance calculation
	local finalChance = math.clamp(baseChance + experienceBonus + statBonus + gpaBonus - rejectionPenalty - criminalPenalty, 0.02, maxChance)
	
	-- Entry-level jobs (no requirements, low salary) - still have some chance of rejection
	if not job.requirement and (job.salary or 0) < 35000 then
		finalChance = math.max(finalChance, 0.65) -- At least 65% chance for basic jobs (was 80%!)
	end
	
	-- Roll for success
	local roll = RANDOM:NextNumber()
	local accepted = roll < finalChance
	
	-- Track application
	state.JobApplications[jobId] = {
		attempts = (appHistory.attempts or 0) + 1,
		lastAttempt = state.Age or 0,
		rejectedThisYear = not accepted,
	}
	
	if not accepted then
		-- Pick a rejection message based on situation
		local messages
		-- CRITICAL FIX: Show criminal record message if that's why they were rejected
		if criminalPenalty > 0 and state.Flags and state.Flags.criminal_record then
			messages = JobRejectionMessages.criminalRecord
		elseif difficulty >= 6 then
			messages = JobRejectionMessages.competitive
		elseif job.minStats then
			messages = JobRejectionMessages.lowStats
		elseif not job.requirement then
			messages = JobRejectionMessages.entry
		else
			messages = JobRejectionMessages.generic
		end
		local msg = messages[RANDOM:NextInteger(1, #messages)]
		
		-- Add encouragement for first rejection
		if appHistory.attempts == 0 then
			msg = msg .. " Don't give up - try again next year or look for other opportunities!"
		elseif appHistory.attempts >= 2 then
			msg = msg .. " Consider gaining more experience or improving your skills before reapplying."
		end
		
		return { success = false, message = msg }
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- SUCCESS! Hired for the job
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Check if illegal job and warn/block based on criminal status
	if job.illegal and not (state.Flags and state.Flags.criminal_path) then
		state.Flags = state.Flags or {}
		state.Flags.criminal_path = true
		state.Flags.criminal = true
	end
	
	state.CareerInfo = state.CareerInfo or {}
	state.Career = state.Career or {}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Save OLD job to career history before replacing
	-- This populates the Career Info screen's career history section
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.CurrentJob then
		state.CareerInfo.careerHistory = state.CareerInfo.careerHistory or {}
		local historyEntry = {
			title = state.CurrentJob.name,
			company = state.CurrentJob.company,
			salary = state.CurrentJob.salary,
			category = state.CurrentJob.category,
			yearsWorked = state.CareerInfo.yearsAtJob or 0,
			performance = state.CareerInfo.performance or 60,
			raises = state.CareerInfo.raises or 0,
			promotions = state.CareerInfo.promotions or 0,
			reason = "quit", -- They left for a new job
			endAge = state.Age or 0,
			endYear = state.Year or 2025,
		}
		table.insert(state.CareerInfo.careerHistory, historyEntry)
		
		-- Track total years worked for experience bonuses
		state.CareerInfo.totalYearsWorked = (state.CareerInfo.totalYearsWorked or 0) + (state.CareerInfo.yearsAtJob or 0)
	end

	state.CurrentJob = {
		id = job.id,
		name = job.name,
		company = job.company,
		salary = job.salary,
		category = job.category,
		difficulty = job.difficulty or 1, -- CRITICAL FIX: Pass difficulty to client
		minStats = job.minStats, -- CRITICAL FIX: Pass stat requirements
	}

	state.CareerInfo.performance = 60
	state.CareerInfo.promotionProgress = 0
	state.CareerInfo.yearsAtJob = 0
	state.CareerInfo.raises = 0
	state.CareerInfo.promotions = 0

	state.Career.track = job.category
	
	-- CRITICAL FIX: Set employment flags and clear retirement-related flags
	state.Flags = state.Flags or {}
	state.Flags.employed = true
	state.Flags.has_job = true
	state.Flags.between_jobs = nil
	state.Flags.unemployed = nil
	
	-- CRITICAL FIX: Set has_teen_job for jobs obtained before age 18
	if (state.Age or 0) < 18 then
		state.Flags.has_teen_job = true
	end
	
	if state.Flags.retired then
		state.Flags.retired = nil
		state.Flags.semi_retired = nil
		state.Flags.pension_amount = nil
	end
	
	-- CRITICAL FIX: Grant experience flags from job (for career progression)
	-- Some jobs grant flags that unlock higher-tier jobs
	if job.grantsFlags then
		for _, flagName in ipairs(job.grantsFlags) do
			state.Flags[flagName] = true
		end
	end
	
	-- CRITICAL FIX #562: Set category-specific career flags
	local jobCategory = (job.category or ""):lower()
	local jobIdLower = (job.id or ""):lower()
	local jobNameLower = (job.name or ""):lower()
	
	if jobCategory == "entertainment" then
		state.Flags.entertainment_experience = true
		state.Flags.fame_career = true
		-- CRITICAL FIX: Set pursuing_fame for ALL entertainment careers!
		-- This enables fame path events to trigger for free players (influencer/streamer)
		-- User feedback: "Story paths don't do much" - events weren't triggering
		state.Flags.pursuing_fame = true
	end
	
	-- CRITICAL FIX: Esports careers are also fame careers!
	if jobCategory == "esports" then
		state.Flags.esports_experience = true
		state.Flags.fame_career = true
		state.Flags.pursuing_fame = true
		state.Flags.gamer = true
		state.Flags.content_creator = true
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #USER-31: Initialize FameState.careerPath for entertainment jobs
	-- WITHOUT THIS, the serialization replaces FameState with a minimal object
	-- and ALL career stats (monthlyListeners, subscribers, etc.) are LOST!
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.FameState = state.FameState or {}
	
	-- CRITICAL FIX #563: Set rapper flags for rapper jobs
	if jobIdLower:find("rapper") or jobNameLower:find("rapper") or jobNameLower:find("hip.?hop") then
		state.Flags.rapper = true
		state.Flags.pursuing_rap = true
		state.Flags.hip_hop_experience = true
		state.Flags.music_experience = true
		-- CRITICAL FIX #USER-31: Set careerPath so FameState gets serialized!
		state.FameState.careerPath = "rapper"
		state.FameState.careerName = job.name
		state.FameState.isFamous = true
		-- Initialize stats if they don't exist
		state.FameState.monthlyListeners = state.FameState.monthlyListeners or 0
		state.FameState.totalStreams = state.FameState.totalStreams or 0
		state.FameState.totalTracks = state.FameState.totalTracks or 0
	end
	
	-- CRITICAL FIX #564: Set streamer/creator flags for those jobs
	if jobIdLower:find("streamer") or jobIdLower:find("creator") or jobIdLower:find("youtuber") or jobIdLower:find("influencer") then
		state.Flags.streamer = true
		state.Flags.content_creator = true
		state.Flags.pursuing_streaming = true
		-- CRITICAL FIX: Also set pursuing_fame to trigger fame path events!
		state.Flags.pursuing_fame = true
		-- CRITICAL FIX #USER-31: Set careerPath so FameState gets serialized!
		if jobIdLower:find("streamer") then
			state.FameState.careerPath = "streamer"
		elseif jobIdLower:find("youtuber") then
			state.FameState.careerPath = "youtuber"
		else
			state.FameState.careerPath = "influencer"
		end
		state.FameState.careerName = job.name
		state.FameState.isFamous = true
		-- Initialize stats if they don't exist
		state.FameState.subscribers = state.FameState.subscribers or 0
		state.FameState.totalViews = state.FameState.totalViews or 0
		state.FameState.totalVideos = state.FameState.totalVideos or 0
	end
	
	-- CRITICAL FIX #565: Set musician flags for music jobs
	if jobIdLower:find("musician") or jobIdLower:find("singer") or (jobIdLower:find("artist") and not jobIdLower:find("rapper")) then
		state.Flags.musician = true
		state.Flags.music_experience = true
		-- CRITICAL FIX #USER-31: Set careerPath so FameState gets serialized!
		state.FameState.careerPath = "musician"
		state.FameState.careerName = job.name
		state.FameState.isFamous = true
	end
	
	-- CRITICAL FIX #566: Set actor flags for acting jobs
	if jobIdLower:find("actor") or jobIdLower:find("actress") or jobNameLower:find("actor") then
		state.Flags.actor = true
		state.Flags.acting_experience = true
		-- CRITICAL FIX #USER-31: Set careerPath so FameState gets serialized!
		state.FameState.careerPath = "actor"
		state.FameState.careerName = job.name
		state.FameState.isFamous = true
	end
	
	-- Clear application history for this job (fresh start)
	state.JobApplications[actualJobId] = nil

	local feed = string.format("🎉 Congratulations! You were hired as a %s at %s!", job.name, job.company)
	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:handleQuitJob(player, quitStyle)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data not loaded." }
	end
	if not state.CurrentJob then
		return { success = false, message = "You're not currently employed." }
	end

	state.CareerInfo = state.CareerInfo or {}
	state.Career = state.Career or {}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Save job to career history before clearing
	-- This populates the Career Info screen's career history section
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.CareerInfo.careerHistory = state.CareerInfo.careerHistory or {}
	
	-- Determine quit reason based on style
	local quitReason = "quit"
	if quitStyle == "dramatic" then
		quitReason = "quit_dramatic"
	elseif quitStyle == "ghost" then
		quitReason = "quit_ghost"
	end
	
	local historyEntry = {
		title = state.CurrentJob.name,
		company = state.CurrentJob.company,
		salary = state.CurrentJob.salary,
		category = state.CurrentJob.category,
		yearsWorked = state.CareerInfo.yearsAtJob or 0,
		performance = state.CareerInfo.performance or 60,
		raises = state.CareerInfo.raises or 0,
		promotions = state.CareerInfo.promotions or 0,
		reason = quitReason,
		endAge = state.Age or 0,
		endYear = state.Year or 2025,
	}
	table.insert(state.CareerInfo.careerHistory, historyEntry)
	
	-- Track total years worked for experience bonuses
	state.CareerInfo.totalYearsWorked = (state.CareerInfo.totalYearsWorked or 0) + (state.CareerInfo.yearsAtJob or 0)

	local jobName = state.CurrentJob.name
	local companyName = state.CurrentJob.company or "your employer"
	state.CurrentJob = nil
	state.CareerInfo.performance = 0
	state.CareerInfo.promotionProgress = 0
	state.CareerInfo.yearsAtJob = 0
	state.Career.track = nil
	
	-- CRITICAL FIX: Clear employment flags properly
	state.Flags = state.Flags or {}
	state.Flags.employed = nil
	state.Flags.has_job = nil
	state.Flags.between_jobs = true
	state.Flags.just_quit = true  -- CRITICAL FIX: Set just_quit flag to prevent job events immediately after quitting
	
	-- BITLIFE-STYLE: Different messages and effects based on quit style
	local feed
	local happinessBonus = 0
	
	if quitStyle == "dramatic" then
		-- Dramatic quit - burned bridges but felt GOOD
		feed = string.format("🔥 You told %s EXACTLY what you think of them. Flipped your desk. Said goodbye to nobody. Walked out like a BOSS. Your ex-coworkers are STILL talking about it. #Legend", companyName)
		happinessBonus = 15
		state.Flags.burned_bridges = true
		state.Flags.epic_quitter = true
	elseif quitStyle == "ghost" then
		-- Ghost - just stopped showing up
		feed = string.format("👻 You just... stopped going to %s. No call. No text. Nothing. They probably filed a missing person report. Your desk stuff is still there. You're officially a ghost.", companyName)
		happinessBonus = 5
		state.Flags.unreliable = true
		state.Flags.ghosted_employer = true
	else
		-- Professional - two week notice
		feed = string.format("✅ You submitted your two-week notice at %s. Your boss looked disappointed but thanked you for your professionalism. Wrote you a great recommendation letter.", companyName)
		happinessBonus = 5
		state.Flags.professional_quitter = true
	end
	
	-- Apply happiness bonus
	state.Stats = state.Stats or {}
	state.Stats.Happiness = math.min(100, (state.Stats.Happiness or 50) + happinessBonus)

	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:handleWork(player)
	local state = self:getState(player)
	if not state or not state.CurrentJob then
		return { success = false, message = "You need a job first." }
	end
	if state.InJail then
		return { success = false, message = "Get out of prison first." }
	end

	state.CareerInfo = state.CareerInfo or {}

	local salary = state.CurrentJob.salary or 0
	local bonus = math.floor(((state.CareerInfo.performance or 50) / 100) * 0.2 * salary)
	local payday = math.floor(salary / 12 + bonus)
	self:addMoney(state, payday)
	self:applyStatChanges(state, { Happiness = RANDOM:NextInteger(-2, 2) })

	-- CRITICAL FIX: Working hard improves performance, but not guaranteed
	-- Performance is the key metric for promotions now (see handlePromotion)
	state.CareerInfo.performance = clamp((state.CareerInfo.performance or 60) + RANDOM:NextInteger(1, 5), 0, 100)

	local message = string.format("Payday! You earned %s.", formatMoney(payday))
	-- CRITICAL FIX: Don't use showPopup here - client already shows result from return value
	-- This was causing DOUBLE popup issue!
	self:pushState(player, message)
	return { success = true, message = message, money = payday }
end

function LifeBackend:handlePromotion(player)
	local state = self:getState(player)
	if not state or not state.CurrentJob then
		return { success = false, message = "You need a job first." }
	end

	state.CareerInfo = state.CareerInfo or {}
	local info = state.CareerInfo
	state.Flags = state.Flags or {}

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Promotions were happening every 1-2 years (way too fast!)
	-- Now require: minimum years at job, good performance, AND random approval chance
	-- This matches BitLife where promotions are rare and based on performance
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Minimum 3 years at current position before eligible for promotion
	local yearsAtJob = info.yearsAtJob or 0
	if yearsAtJob < 3 then
		return { success = false, message = string.format("You need more time in your current role. (%.0f/3 years)", yearsAtJob) }
	end
	
	-- Need good performance (70+)
	local performance = info.performance or 50
	if performance < 70 then
		return { success = false, message = string.format("Your performance needs improvement. (%d%% / 70%% required)", performance) }
	end
	
	-- Cooldown: Can only request promotion once per year
	local lastPromotionRequest = info.lastPromotionRequestAge or 0
	if (state.Age or 0) <= lastPromotionRequest then
		return { success = false, message = "You already asked this year. Try again next year." }
	end
	info.lastPromotionRequestAge = state.Age or 0
	
	-- Random chance based on performance - promotions aren't guaranteed!
	-- 70% performance = 40% chance, 100% performance = 70% chance
	local promotionChance = 0.1 + (performance / 100) * 0.6
	local roll = RANDOM:NextNumber()
	
	if roll > promotionChance then
		-- Denied!
		local denialMessages = {
			"Your manager said 'not this time.' Keep working hard.",
			"The budget for promotions has been frozen. Try again next year.",
			"They're looking for someone with more experience in leadership.",
			"You're doing great, but there's no open positions above you right now.",
		}
		local msg = denialMessages[RANDOM:NextInteger(1, #denialMessages)]
		return { success = false, message = msg }
	end

	-- Promotion granted!
	info.promotionProgress = 0
	info.promotions = (info.promotions or 0) + 1
	state.Flags.just_promoted = true
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #5: Actually change job title on promotion, not just salary!
	-- Use CareerTracks to find the next job in the career path
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #126: Nil safety for job ID access
	local currentJobId = state.CurrentJob and state.CurrentJob.id
	if not currentJobId then
		-- Fallback: just do salary promotion
		state.CurrentJob.salary = math.floor((state.CurrentJob.salary or 30000) * 1.15)
		local feed = string.format("🎉 Salary promotion! You now earn %s.", formatMoney(state.CurrentJob.salary))
		self:pushState(player, feed)
		return { success = true, message = feed }
	end
	
	local promotedToNewTitle = false
	local oldJobName = state.CurrentJob.name or "your old position"
	local newJobName = nil
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #12: First, grant flags from current job before checking next job
	-- This ensures the player has earned the experience flags from their current position
	-- so they can be eligible for promotion to the next level in the career track.
	-- ═══════════════════════════════════════════════════════════════════════════════
	local currentJob = JobCatalog[currentJobId]
	if currentJob and currentJob.grantsFlags then
		state.Flags = state.Flags or {}
		for _, flagToGrant in ipairs(currentJob.grantsFlags) do
			state.Flags[flagToGrant] = true
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #61: Filter career tracks by job category to prevent cross-category promotions
	-- This prevents entry-level workers from being promoted into tech tracks without tech experience
	-- ═══════════════════════════════════════════════════════════════════════════════
	local currentCategory = (state.CurrentJob.category and state.CurrentJob.category:lower()) or "entry"
	
	-- Map categories to allowed career tracks
	local categoryToTracks = {
		entry = { "entry", "entry_service", "entry_food", "office" },
		service = { "entry_service", "entry_food" },
		office = { "office" },
		tech = { "tech_dev", "tech_web", "tech_mobile", "tech_data", "tech_security", "tech_devops" },
		medical = { "medical_nursing", "medical_doctor", "medical_other" },
		legal = { "legal", "legal_gov" },
		finance = { "finance_banking", "finance_invest" },
		creative = { "creative_design", "creative_media", "creative_marketing", "creative_acting", "creative_music" },
		government = { "gov_police", "gov_fire", "gov_politics", "gov_federal" },
		education = { "education_school", "education_university" },
		science = { "science" },
		sports = { "sports_player", "sports_coach" },
		military = { "military_enlisted", "military_officer" },
		esports = { "esports" },
		racing = { "racing" },
		hacker = { "hacker_whitehat", "hacker_blackhat" },
		criminal = { "criminal_street", "criminal_crew" },
	}
	
	local allowedTracks = categoryToTracks[currentCategory] or { "entry", "office" }
	
	-- Find current job's career track and next position - ONLY in allowed tracks!
	for _, trackName in ipairs(allowedTracks) do
		local trackJobs = CareerTracks[trackName]
		if trackJobs then
			for i, jobId in ipairs(trackJobs) do
				if jobId == currentJobId then
					-- Found current job, check if there's a next position
					local nextJobId = trackJobs[i + 1]
					if nextJobId then
						local nextJob = JobCatalog[nextJobId]
						if nextJob then
							-- Check if player meets requirements for next job
							local meetsReqs = true
							local blockReason = nil
							
							-- Check minimum age
							if nextJob.minAge and (state.Age or 0) < nextJob.minAge then
								meetsReqs = false
								blockReason = string.format("You need to be at least %d years old", nextJob.minAge)
							end
							
							-- ═══════════════════════════════════════════════════════════════════
							-- CRITICAL FIX #12: Check requiresFlags for promotion eligibility!
							-- Players MUST have the required flags to be promoted.
							-- This prevents unrealistic promotions (e.g., casual_gamer -> pro_gamer
							-- without competitive gaming experience)
							-- ═══════════════════════════════════════════════════════════════════
							if meetsReqs and nextJob.requiresFlags then
								local hasAnyFlag = false
								for _, reqFlag in ipairs(nextJob.requiresFlags) do
									if state.Flags[reqFlag] then
										hasAnyFlag = true
										break
									end
								end
								if not hasAnyFlag then
									meetsReqs = false
									blockReason = "You need more experience in your field before this promotion"
								end
							end
							
							-- Check minimum stats if specified
							if meetsReqs and nextJob.minStats then
								state.Stats = state.Stats or {}
								for statName, minValue in pairs(nextJob.minStats) do
									local playerStat = state.Stats[statName] or state[statName] or 0
									if playerStat < minValue then
										meetsReqs = false
										blockReason = string.format("Your %s needs to be at least %d", statName, minValue)
										break
									end
								end
							end
							
							if meetsReqs then
								-- PROMOTE to next job!
								-- CRITICAL FIX #62: Preserve category if transitioning from entry to office
								local newCategory = nextJob.category
								if currentCategory == "entry" and newCategory == "office" then
									-- Entry workers can transition to office
									newCategory = "office"
								end
								
								state.CurrentJob = {
									id = nextJob.id,
									name = nextJob.name,
									title = nextJob.name,
									company = state.CurrentJob.company or nextJob.company, -- Keep same company
									salary = math.floor((state.CurrentJob.salary or nextJob.salary) * 1.25), -- 25% raise on title change
									emoji = nextJob.emoji,
									category = newCategory,
									hiredAt = state.Age,
								}
								promotedToNewTitle = true
								newJobName = nextJob.name
								info.yearsAtJob = 0 -- Reset years at job for new position
								info.raises = 0 -- Reset raises for new position
								
								-- Grant flags from the new job
								if nextJob.grantsFlags then
									for _, flagToGrant in ipairs(nextJob.grantsFlags) do
										state.Flags[flagToGrant] = true
									end
								end
							end
						end
					end
					break
				end
			end
		end
		if promotedToNewTitle then break end
	end
	
	local feed
	if promotedToNewTitle and newJobName then
		feed = string.format("🎉 MAJOR PROMOTION! You've been promoted from %s to %s! New salary: %s", 
			oldJobName, newJobName, formatMoney(state.CurrentJob.salary))
		-- Add a flag for major promotion
		state.Flags.major_promotion = true
	else
		-- No title change available (top of career track) - just salary bump
		state.CurrentJob.salary = math.floor((state.CurrentJob.salary or 0) * 1.15)
		feed = string.format("🎉 Salary promotion! You now earn %s.", formatMoney(state.CurrentJob.salary))
	end
	
	info.performance = clamp((info.performance or 60) + 5, 0, 100)
	self:pushState(player, feed)
	return { success = true, message = feed, newJob = promotedToNewTitle and state.CurrentJob or nil }
end

function LifeBackend:handleRaise(player)
	local state = self:getState(player)
	if not state or not state.CurrentJob then
		return { success = false, message = "No employer to ask." }
	end

	state.CareerInfo = state.CareerInfo or {}
	local info = state.CareerInfo

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Add cooldown to prevent raise spam
	-- Can only ask for a raise once per year, similar to promotions
	-- ═══════════════════════════════════════════════════════════════════════════════
	local lastRaiseRequest = info.lastRaiseRequestAge or 0
	if (state.Age or 0) <= lastRaiseRequest then
		return { success = false, message = "You already asked for a raise this year. Try again next year." }
	end
	info.lastRaiseRequestAge = state.Age or 0

	if (info.performance or 0) < 60 then
		return { success = false, message = "Improve your performance before asking. (Need 60%+)" }
	end
	if (info.raises or 0) >= 5 then
		return { success = false, message = "You've maxed out raises for this role. Need a promotion for more." }
	end

	-- CRITICAL FIX: Raise chance based on performance, not just 70% flat
	local performance = info.performance or 60
	local raiseChance = 0.3 + (performance / 100) * 0.4 -- 30-70% based on performance
	local granted = RANDOM:NextNumber() < raiseChance
	
	if not granted then
		info.performance = clamp((info.performance or 60) - 5, 0, 100)
		return { success = false, message = "Raise denied. 'Budget constraints' they said. Maybe next year." }
	end

	state.CurrentJob.salary = math.floor((state.CurrentJob.salary or 0) * 1.08) -- 8% raise instead of 10%
	info.raises = (info.raises or 0) + 1
	info.performance = clamp((info.performance or 60) + 3, 0, 100)

	local feed = string.format("💰 Raise approved! Salary is now %s.", formatMoney(state.CurrentJob.salary))
	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:getCareerInfo(player)
	local state = self:getState(player)
	if not state then
		return { success = false }
	end
	state.CareerInfo = state.CareerInfo or {}
	state.Career = state.Career or {}

	-- CRITICAL FIX #6: Get next promotion job info for client display
	local nextJobId = nil
	local nextJobName = nil
	local nextJobSalary = nil
	if state.CurrentJob and state.CurrentJob.id then
		nextJobId = getNextPromotionJob(state.CurrentJob.id)
		if nextJobId and JobCatalog[nextJobId] then
			local nextJob = JobCatalog[nextJobId]
			nextJobName = nextJob.name
			nextJobSalary = nextJob.salary
		end
	end

	return {
		success = true,
		performance = state.CareerInfo.performance or 0,
		promotionProgress = state.CareerInfo.promotionProgress or 0,
		yearsAtJob = state.CareerInfo.yearsAtJob or 0,
		raises = state.CareerInfo.raises or 0,
		promotions = state.CareerInfo.promotions or 0,
		careerHistory = state.CareerInfo.careerHistory or {},
		skills = state.CareerInfo.skills or {},
		track = state.Career.track,
		totalExperience = state.CareerInfo.totalYearsWorked or 0,
		totalYearsWorked = state.CareerInfo.totalYearsWorked or 0,
		-- CRITICAL FIX #7: Include next promotion info
		promotesTo = nextJobId,
		promotesToName = nextJobName,
		promotesToSalary = nextJobSalary,
		hasPromotion = nextJobId ~= nil,
	}
end

function LifeBackend:getEducationInfo(player)
	local state = self:getState(player)
	if not state then
		return { success = false }
	end
	local edu = state.EducationData or { Status = "none" }
	state.Stats = state.Stats or {}

	local rawGPA
	if edu.GPA ~= nil then
		rawGPA = edu.GPA
	else
		local smarts = state.Stats.Smarts or 0
		rawGPA = math.floor((smarts / 25) * 100) / 100
	end

	return {
		success = true,
		level = state.Education,
		-- CRITICAL FIX: Add human-readable education level display
		levelDisplay = formatEducation(state.Education),
		institution = edu.Institution or "Local School",
		gpa = rawGPA,
		progress = edu.Progress or 0,
		status = edu.Status or "none",
		creditsEarned = edu.CreditsEarned,
		creditsRequired = edu.CreditsRequired,
		year = edu.Year,
		totalYears = edu.TotalYears,
		debt = edu.Debt or 0,
	}
end

function LifeBackend:enrollEducation(player, programId, options)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	options = options or {}
	local skipPush = options.skipPush == true

	local program = EducationCatalog[programId]
	if not program then
		return { success = false, message = "Unknown education program." }
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Prevent multiple education enrollments!
	-- You can't be enrolled in two programs at once - just like real life
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.EducationData and state.EducationData.Status == "enrolled" then
		local currentProgram = state.EducationData.Institution or "a program"
		return { 
			success = false, 
			message = string.format("You're already enrolled in %s! Complete it first or drop out.", currentProgram)
		}
	end

	-- CRITICAL FIX: Check minimum age for enrollment
	local playerAge = state.Age or 0
	local minAge = program.minAge or 18
	if playerAge < minAge then
		return { success = false, message = string.format("You must be at least %d years old to enroll in %s.", minAge, program.name) }
	end

	if not self:meetsEducationRequirement(state, program.requirement) then
		-- MINOR FIX: More helpful error message with specific requirement
		local requiredText = program.requirement or "a prerequisite degree"
		return { success = false, message = string.format("You need %s to enroll in %s.", requiredText, program.name) }
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Allow student loans! Don't block enrollment for not having cash.
	-- Just like real life - students take out loans for education
	-- ═══════════════════════════════════════════════════════════════════════════════
	local prevDebt = (state.EducationData and state.EducationData.Debt) or 0
	local currentMoney = state.Money or 0
	local tuitionCost = program.cost or 0
	local loanNeeded = 0
	
	if currentMoney >= tuitionCost then
		-- Player can pay in full
		self:addMoney(state, -tuitionCost)
	else
		-- Player takes out student loans for the remainder
		loanNeeded = tuitionCost - currentMoney
		if currentMoney > 0 then
			self:addMoney(state, -currentMoney) -- Pay what they can
		end
		-- Loan is added to debt (paid back later)
	end
	-- CRITICAL FIX: Track loan separately from total cost for proper messaging
	local totalDebt = prevDebt + loanNeeded -- Only add the loan portion to debt, not what was paid
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #MEGA-14: Enhanced EducationData with institution AND degree
	-- Now properly tracks: what institution you attend AND what degree you'll earn
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.EducationData = {
		Status = "enrolled",
		Level = programId,
		Progress = 0,
		Duration = program.duration,
		Institution = program.institution or program.name,  -- Where you go
		InstitutionName = program.name,  -- Display name for the program
		Degree = program.degree,  -- What degree you'll earn upon completion
		Debt = totalDebt,
		LoanAmount = loanNeeded,
		Description = program.description,  -- Store description for UI
	}
	state.Career = state.Career or {}
	state.Career.education = programId
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #MEGA-15: Apply education program flags and stat bonuses on enrollment
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.Flags = state.Flags or {}
	
	-- Set student loan flag if they took a loan
	if loanNeeded > 0 then
		state.Flags.has_student_loans = true
		state.Flags.student_loan_amount = (state.Flags.student_loan_amount or 0) + loanNeeded
	end
	
	-- Apply program-specific flags
	if program.grantsFlags then
		for _, flag in ipairs(program.grantsFlags) do
			state.Flags[flag] = true
		end
	end
	
	-- Apply initial stat bonuses (partial - more on completion)
	if program.statBonuses then
		local partialBonus = {}
		for stat, bonus in pairs(program.statBonuses) do
			partialBonus[stat] = math.floor(bonus * 0.3)  -- 30% on enrollment, 70% on completion
		end
		self:applyStatChanges(state, partialBonus)
	end

	-- Create enrollment message showing BOTH institution and future degree
	local feed
	local institutionDisplay = program.institution or program.name
	local degreeDisplay = program.degree or program.name
	if loanNeeded > 0 then
		feed = string.format("🎓 You enrolled at %s! You'll earn: %s. Took out %s in student loans.", 
			institutionDisplay, degreeDisplay, formatMoney(loanNeeded))
	else
		feed = string.format("🎓 You enrolled at %s! You'll earn: %s. Paid tuition in full.", 
			institutionDisplay, degreeDisplay)
	end
	if not skipPush then
		self:pushState(player, feed)
	end
	return { success = true, message = feed }
end

-- ============================================================================
-- Assets
-- ============================================================================
-- NOTE: Gambling features have been REMOVED to comply with Roblox Terms of Service

function LifeBackend:findAssetById(list, assetId)
	-- CRITICAL FIX #127: Nil safety for asset lookup
	if not list or type(list) ~= "table" then
		return nil
	end
	if not assetId then
		return nil
	end
	
	for _, asset in ipairs(list) do
		if asset and asset.id == assetId then
			return asset
		end
	end
	return nil
end

--[[
	handleAssetPurchase - Server-side validation for asset purchases
	
	Validates:
	- Age requirements (must be 18+ for most purchases)
	- Money availability
	- Driver's license for vehicles
	- Prevents godmode by enforcing real checks
]]
function LifeBackend:handleAssetPurchase(player, assetType, catalog, assetId)
	debugPrint("=== ASSET PURCHASE ===")
	debugPrint("  Player:", player.Name, "Type:", assetType, "AssetId:", assetId)
	
	local state = self:getState(player)
	if not state then
		debugPrint("  FAILED: No state")
		return { success = false, message = "Life data missing." }
	end

	local asset = self:findAssetById(catalog, assetId)
	if not asset then
		debugPrint("  FAILED: Unknown asset")
		return { success = false, message = "Unknown asset." }
	end
	
	debugPrint("  Found asset:", asset.name, "Price:", asset.price)

	state.Assets = state.Assets or {}
	state.Flags = state.Flags or {}

	-- Age check for major purchases (properties and vehicles)
	local minAge = asset.minAge or 18
	if assetType == "Properties" then
		minAge = asset.minAge or 21 -- Must be 21+ to buy property
	elseif assetType == "Vehicles" then
		minAge = asset.minAge or 16 -- Must be 16+ for vehicles

		-- Vehicle-specific: require driver's license
		-- CRITICAL FIX: Check ALL possible license flag names for consistency
		local hasLicense = state.Flags and (state.Flags.has_license or state.Flags.drivers_license or state.Flags.driver_license)
		if not hasLicense then
			debugPrint("  FAILED: No driver's license")
			return { success = false, message = "You need a driver's license first!" }
		end
	elseif assetType == "Items" then
		minAge = asset.minAge or 14 -- Shop items can be bought younger
	end

	if (state.Age or 0) < minAge then
		return { success = false, message = string.format("You must be at least %d years old to buy this.", minAge) }
	end

	-- Prison check - can't buy stuff while incarcerated
	if state.InJail then
		return { success = false, message = "You can't make purchases while incarcerated." }
	end

	-- Money check
	if (state.Money or 0) < asset.price then
		return { success = false, message = "You can't afford that." }
	end

	state.Assets[assetType] = state.Assets[assetType] or {}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #12: Check for duplicate items
	-- Prevent buying the same unique item twice (e.g., same house, same car)
	-- ═══════════════════════════════════════════════════════════════════════════════
	local isUniqueAsset = assetType == "Properties" -- Properties are unique (you can't buy the same house twice)
	
	-- Some items can be duplicated (like generic cars), others can't (like a specific mansion)
	if asset.unique == true or isUniqueAsset then
		for _, existingAsset in ipairs(state.Assets[assetType]) do
			if existingAsset.id == asset.id then
				return { success = false, message = "You already own this!" }
			end
		end
	end
	
	-- For non-unique items, still check if player has too many of the same type
	local MAX_SAME_ITEM = 3 -- Can only own up to 3 of the exact same item
	local sameItemCount = 0
	for _, existingAsset in ipairs(state.Assets[assetType]) do
		if existingAsset.id == asset.id then
			sameItemCount = sameItemCount + 1
		end
	end
	if sameItemCount >= MAX_SAME_ITEM then
		return { success = false, message = string.format("You already own %d of these. Try something different!", MAX_SAME_ITEM) }
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #MEGA-2: Store ALL asset data including effects
	-- This allows TickAssets to properly apply all bonuses
	-- ═══════════════════════════════════════════════════════════════════════════════
	local storedAsset = {
		id = asset.id,
		name = asset.name,
		emoji = asset.emoji or "",
		value = asset.price,
		price = asset.price,
		income = asset.income or 0,
		acquiredAge = state.Age,
		acquiredYear = state.Year,
		-- New comprehensive data
		tier = asset.tier or "basic",
		happinessBonus = asset.happinessBonus or 0,
		statusBonus = asset.statusBonus or 0,
		maintenanceCost = asset.maintenanceCost or 0,
		fuelCost = asset.fuelCost or 0,
		resaleModifier = asset.resaleModifier or 0.70,
		depreciationRate = asset.depreciationRate or 0.10,
		fameBonus = asset.fameBonus or 0,
		effects = asset.effects,
		grantsFlags = asset.grantsFlags,
		appreciates = asset.appreciates or false,
		appreciationRate = asset.appreciationRate or 0.03,
		riskFactor = asset.riskFactor,
		canHostParties = asset.canHostParties,
		familyBonus = asset.familyBonus,
		fastTravel = asset.fastTravel,
		canPropose = asset.canPropose,
		skillBonus = asset.skillBonus,
		unlocksCareers = asset.unlocksCareers,
	}
	
	table.insert(state.Assets[assetType], storedAsset)
	
	debugPrint("  SUCCESS: Added to state.Assets." .. assetType)
	debugPrint("    Total items in " .. assetType .. ":", #state.Assets[assetType])
	for i, a in ipairs(state.Assets[assetType]) do
		debugPrint("      [" .. i .. "]", a.id, a.name)
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #MEGA-3: Apply ALL effects immediately upon purchase
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Apply immediate stat effects
	if asset.effects then
		for statName, value in pairs(asset.effects) do
			if state.Stats and state.Stats[statName] then
				state.Stats[statName] = math.min(100, math.max(0, (state.Stats[statName] or 50) + value))
			end
		end
	end
	
	-- Apply flags from asset
	if asset.grantsFlags then
		for _, flagName in ipairs(asset.grantsFlags) do
			state.Flags[flagName] = true
		end
	end
	
	-- Apply fame bonus immediately
	if asset.fameBonus and asset.fameBonus > 0 then
		state.Fame = (state.Fame or 0) + asset.fameBonus
	end
	
	-- Vehicle-specific flags
	if assetType == "Vehicles" then
		state.Flags.has_vehicle = true
		state.Flags.has_car = true
		state.Flags.car_owner = true
		if asset.tier == "supercar" or asset.tier == "ultra" or asset.tier == "billionaire" then
			state.Flags.luxury_car_owner = true
		end
		if asset.id == "yacht" then
			state.Flags.yacht_owner = true
			state.Flags.boat_owner = true
		end
		if asset.id == "jet" then
			state.Flags.jet_owner = true
			state.Flags.can_fly_private = true
		end
		if asset.id == "helicopter" then
			state.Flags.helicopter_owner = true
			state.Flags.can_fly = true
		end
		if asset.id == "motorcycle" then
			state.Flags.motorcycle_owner = true
			state.Flags.biker = true
		end
	-- Property-specific flags
	elseif assetType == "Properties" then
		state.Flags.has_property = true
		state.Flags.homeowner = true
		if asset.tier == "luxury" or asset.tier == "elite" or asset.tier == "ultra" or asset.tier == "billionaire" then
			state.Flags.luxury_homeowner = true
		end
		if asset.id == "mansion" then
			state.Flags.mansion_owner = true
			state.Flags.ultra_wealthy = true
		end
		if asset.id == "penthouse" then
			state.Flags.penthouse_owner = true
		end
		if asset.id == "island" then
			state.Flags.island_owner = true
			state.Flags.billionaire_lifestyle = true
		end
	-- Item-specific flags and career unlocks
	elseif assetType == "Items" then
		if asset.id == "gaming_pc" or asset.id == "laptop" then
			state.Flags.has_computer = true
			state.Flags.tech_savvy = true
		end
		if asset.id == "camera" then
			state.Flags.photographer = true
		end
		if asset.id == "guitar" or asset.id == "piano" then
			state.Flags.musician = true
			state.Flags.plays_instrument = true
		end
		-- Apply skill bonuses
		if asset.skillBonus then
			state.Skills = state.Skills or {}
			for skill, bonus in pairs(asset.skillBonus) do
				state.Skills[skill] = (state.Skills[skill] or 0) + bonus
			end
		end
	end

	self:addMoney(state, -asset.price)
	
	-- Generate feed with tier-specific messaging
	local tierMessages = {
		budget = "You got yourself",
		basic = "You bought",
		reliable = "You purchased",
		nice = "You treated yourself to",
		premium = "Nice! You acquired",
		luxury = "Congrats! You now own",
		supercar = "WOW! You're now the proud owner of",
		elite = "INCREDIBLE! You purchased",
		ultra = "LEGENDARY! You now own",
		billionaire = "BILLIONAIRE STATUS! You bought",
		investment = "Smart investment:",
	}
	local tierMsg = tierMessages[asset.tier or "basic"] or "You purchased"
	local feed = string.format("%s %s for %s!", tierMsg, asset.name, formatMoney(asset.price))
	
	-- Debug: Check assets before push
	debugPrint("  Before pushState:")
	debugPrint("    state.Assets.Properties:", state.Assets.Properties and #state.Assets.Properties or 0)
	debugPrint("    state.Assets.Vehicles:", state.Assets.Vehicles and #state.Assets.Vehicles or 0)
	debugPrint("    state.Assets.Items:", state.Assets.Items and #state.Assets.Items or 0)
	
	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:handleAssetSale(player, assetId, assetType)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	if state.InJail then
		return { success = false, message = "You can't sell assets while incarcerated." }
	end

	state.Assets = state.Assets or {}
	state.Flags = state.Flags or {}

	local bucket = state.Assets[assetType]
	if not bucket then
		return { success = false, message = "You don't own anything like that." }
	end

	for index, asset in ipairs(bucket) do
		if asset.id == assetId then
			-- ═══════════════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX #MEGA-4: Use proper resale modifier and handle appreciation
			-- ═══════════════════════════════════════════════════════════════════════════════
			local resaleModifier = asset.resaleModifier or 0.70
			local currentValue = asset.value or asset.price or 0
			
			-- Check for appreciation (jewelry, art, some properties)
			if asset.appreciates then
				local yearsOwned = (state.Age or 0) - (asset.acquiredAge or 0)
				local appreciationRate = asset.appreciationRate or 0.03
				currentValue = currentValue * (1 + (appreciationRate * yearsOwned))
			end
			
			local payout = math.floor(currentValue * resaleModifier)
			table.remove(bucket, index)
			self:addMoney(state, payout)
			
			-- Remove granted flags if this was the only asset providing them
			if asset.grantsFlags then
				for _, flagName in ipairs(asset.grantsFlags) do
					-- Only remove if no other asset grants this flag
					local stillHasFlag = false
					for _, otherAsset in ipairs(bucket) do
						if otherAsset.grantsFlags then
							for _, otherFlag in ipairs(otherAsset.grantsFlags) do
								if otherFlag == flagName then
									stillHasFlag = true
									break
								end
							end
						end
						if stillHasFlag then break end
					end
					if not stillHasFlag then
						state.Flags[flagName] = nil
					end
				end
			end

			if assetType == "Vehicles" and #bucket == 0 then
				state.Flags.has_vehicle = nil
				state.Flags.has_car = nil
				state.Flags.car_owner = nil
				state.Flags.luxury_car_owner = nil
				-- CRITICAL FIX #25: Clear car loan when selling financed vehicle
				if asset.financed then
					state.Flags.car_loan_balance = nil
					state.Flags.car_loan_payment = nil
					state.Flags.has_car_loan = nil
				end
			elseif assetType == "Properties" and #bucket == 0 then
				state.Flags.has_property = nil
				state.Flags.homeowner = nil
				state.Flags.luxury_homeowner = nil
				-- CRITICAL FIX #25: Clear mortgage when selling last property
				-- When you sell your home, the mortgage is paid off from proceeds
				if state.Flags.mortgage_debt then
					-- Deduct mortgage from sale proceeds
					local mortgageOwed = state.Flags.mortgage_debt or 0
					if payout > mortgageOwed then
						-- Sale covers mortgage, player keeps difference
						state.Money = (state.Money or 0) - mortgageOwed
						-- Note: payout already added above, so just subtract mortgage
					end
					state.Flags.mortgage_debt = nil
					state.Flags.mortgage_trouble = nil
				end
			elseif assetType == "Properties" and #bucket > 0 then
				-- CRITICAL FIX #25: If selling one property but have mortgage, clear if this was the mortgaged one
				if asset.hasMortgage then
					state.Flags.mortgage_debt = nil
					state.Flags.mortgage_trouble = nil
				end
			end

			local feed = string.format("You sold %s for %s.", asset.name or "an asset", formatMoney(payout))
			self:pushState(player, feed)
			return { success = true, message = feed }
		end
	end

	return { success = false, message = "Asset not found." }
end

-- REMOVED: handleGamble function (gambling is against Roblox Terms of Service)
-- All gambling features have been removed from this game

-- ============================================================================
-- Relationships & Interactions
-- ============================================================================

local function inferNameFromId(identifier)
	if type(identifier) ~= "string" or identifier == "" then
		return nil
	end
	local cleaned = identifier:gsub("_", " ")
	return cleaned:sub(1, 1):upper() .. cleaned:sub(2)
end

function LifeBackend:createRelationship(state, relType, options)
	state.Relationships = state.Relationships or {}
	state.Flags = state.Flags or {}
	options = options or {}

	-- Prefer EventEngine for dynamic friend/romance generation
	if EventEngine and EventEngine.createRelationship and not options.id and (relType == "friend" or relType == "romance" or relType == "partner" or relType == "enemy") then
		local success, relationship = pcall(EventEngine.createRelationship, state, relType, options)
		if success and relationship then
			return relationship
		end
		if not success then
			warn("[LifeBackend] EventEngine relationship creation failed:", relationship)
		end
	end

	local newId = options.id or string.format("%s_%s", relType, HttpService:GenerateGUID(false))
	local defaultName = inferNameFromId(options.id) or inferNameFromId(relType) or "Person"
	local relationship = {
		id = newId,
		name = options.name or defaultName,
		type = relType,
		role = options.role or defaultName,
		relationship = options.startLevel or 60,
		age = options.age or state.Age,
		gender = options.gender,
		alive = options.alive ~= false,
	}

	state.Relationships[newId] = relationship

	if relType == "romance" or relType == "partner" then
		state.Relationships.partner = relationship
		state.Flags.has_partner = true
		state.Flags.dating = true
	end

	return relationship
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: Fallback function for relationship creation
-- Used when createRelationship fails for any reason
-- ════════════════════════════════════════════════════════════════════════════════
function LifeBackend:createBasicRelationship(state, relType)
	state.Relationships = state.Relationships or {}

	-- Generate random name
	local firstNames = { "Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Drew", "Quinn", "Jamie", "Avery" }
	local lastNames = { "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis" }
	local randomName = firstNames[math.random(#firstNames)] .. " " .. lastNames[math.random(#lastNames)]

	local newId = string.format("%s_%s_%d", relType, os.time(), math.random(1000, 9999))
	local relationship = {
		id = newId,
		name = randomName,
		type = relType,
		role = relType == "friend" and "Friend" or relType == "romance" and "Partner" or "Person",
		relationship = 50,
		age = (state.Age or 20) + math.random(-5, 5),
		alive = true,
	}

	state.Relationships[newId] = relationship

	if relType == "friend" then
		state.Relationships.friends = state.Relationships.friends or {}
		table.insert(state.Relationships.friends, relationship)
	end

	debugPrint("[createBasicRelationship] Created basic " .. relType .. ": " .. randomName)
	return relationship
end

local InteractionEffects = {
	family = {
		hug = { delta = 6, cost = 0, message = "You hugged them tightly." },
		talk = { delta = 4, message = "You caught up on life." },
		gift = { delta = 5, cost = 100, message = "You bought them a thoughtful gift." },
		argue = { delta = -8, message = "You argued and tensions rose." },
		money = { delta = -2, message = "You asked them for money.", grant = function(state) state.Money = (state.Money or 0) + RANDOM:NextInteger(100, 500) end },
		vacation = { delta = 10, cost = 2000, message = "You took them on a vacation." },
		apologize = { delta = 7, message = "You apologized for past mistakes." },
	},
	romance = {
		date = { delta = 8, cost = 100, message = "You went on a romantic date." },
		gift = { delta = 9, cost = 200, message = "You surprised them with a gift." },
		kiss = { delta = 5, message = "You shared a kiss." },
		propose = { delta = 15, cost = 5000, message = "You proposed!", flags = { engaged = true, committed_relationship = true } },
		breakup = { delta = -999, message = "You ended the relationship.", remove = true, clearFlags = { "has_partner", "dating", "committed_relationship", "married", "engaged" } },
		flirt = { delta = 4, message = "You flirted playfully." },
		compliment = { delta = 3, message = "You complimented them." },
		meet_someone = {
			forceNewRelationship = true,
			requiresSingle = true,
			delta = 10,
			message = function(_, relationship)
				local name = (relationship and relationship.name) or "someone new"
				return string.format("You hit it off with %s!", name)
			end,
		},
	},
	friend = {
		hangout = { delta = 6, message = "You hung out together." },
		gift = { delta = 4, cost = 50, message = "You gave them a small gift." },
		support = { delta = 5, message = "You supported them through a tough time." },
		party = { delta = 7, message = "You partied together." },
		betray = { delta = -15, message = "You betrayed their trust." },
		ghost = { delta = -999, message = "You ghosted them.", remove = true },
		make_friend = {
			forceNewRelationship = true,
			delta = 12,
			message = function(_, relationship)
				local name = (relationship and relationship.name) or "a new friend"
				return string.format("You became friends with %s.", name)
			end,
		},
	},
	enemy = {
		insult = { delta = -6, message = "You insulted them." },
		fight = { delta = -10, message = "You got into a fight.", stats = { Health = -5 } },
		forgive = { delta = 10, message = "You forgave them.", convert = "friend" },
		prank = { delta = -4, message = "You pulled a prank on them." },
		ignore = { delta = 0, message = "You ignored them." },
	},
}

function LifeBackend:ensureRelationship(state, relType, targetId, options)
	options = options or {}
	state.Relationships = state.Relationships or {}

	-- If we have a specific targetId and it exists, return it
	if targetId and state.Relationships[targetId] then
		return state.Relationships[targetId]
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #13: More robust relationship lookup
	-- Sometimes the targetId might not match exactly due to case or formatting
	-- ═══════════════════════════════════════════════════════════════════════════════
	if targetId then
		local targetIdLower = targetId:lower()
		-- Try to find by case-insensitive ID match
		for relId, relationship in pairs(state.Relationships) do
			if type(relId) == "string" and relId:lower() == targetIdLower then
				return relationship
			end
		end
		
		-- Try to find by name match (user might send name instead of ID)
		for relId, relationship in pairs(state.Relationships) do
			if type(relationship) == "table" and relationship.name then
				if relationship.name:lower() == targetIdLower or
				   (relationship.id and relationship.id:lower() == targetIdLower) then
					return relationship
				end
			end
		end
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- FAMILY MEMBER HANDLING
	-- For family types (mother, father, sibling, etc.), do NOT create generic entries.
	-- Family members are created server-side in createInitialState(). If a family
	-- member doesn't exist in state.Relationships, return nil so the client knows
	-- this person doesn't exist (preventing the "deleted family" bug).
	-- ═══════════════════════════════════════════════════════════════════════════════
	if relType == "family" then
		-- CRITICAL FIX #13: Also search by role type for family
		if targetId then
			local targetLower = targetId:lower()
			local familyRoles = {"mother", "father", "grandmother", "grandfather", "brother", "sister", "son", "daughter", "child", "spouse"}
			
			for relId, relationship in pairs(state.Relationships) do
				if type(relationship) == "table" then
					-- Check if this relationship matches the target family member
					local relRole = (relationship.role or ""):lower()
					local relType2 = (relationship.type or ""):lower()
					
					for _, familyRole in ipairs(familyRoles) do
						if targetLower:find(familyRole) and (relRole:find(familyRole) or relType2:find(familyRole)) then
							return relationship
						end
					end
				end
			end
			
			debugPrint(string.format("Family member '%s' not found in state - returning nil", targetId))
		end
		
		-- For generic family requests without targetId, also return nil (don't create randoms)
		return nil
	end

	-- Force create a new relationship if requested
	if options.forceNewRelationship then
		-- CRITICAL FIX: Ensure relationshipOptions is never nil
		local relOptions = options.relationshipOptions or {}
		local result = self:createRelationship(state, relType, relOptions)
		if not result then
			-- Fallback: create a basic relationship if createRelationship failed
			debugPrint("[ensureRelationship] createRelationship returned nil, creating basic friend")
			return self:createBasicRelationship(state, relType)
		end
		return result
	end

	-- Friend: create new friend if no specific target
	if relType == "friend" and not targetId then
		-- CRITICAL FIX: Ensure relationshipOptions is never nil
		local relOptions = options.relationshipOptions or {}
		local result = self:createRelationship(state, "friend", relOptions)
		if not result then
			-- Fallback: create a basic friend if createRelationship failed
			debugPrint("[ensureRelationship] createRelationship returned nil for friend, creating basic")
			return self:createBasicRelationship(state, "friend")
		end
		return result
	end

	-- Romance: find existing partner or create new one
	if relType == "romance" then
		if targetId and state.Relationships[targetId] then
			return state.Relationships[targetId]
		end

		local partner = state.Relationships.partner
		if partner and partner.alive ~= false then
			return partner
		end

		return self:createRelationship(state, "romance", options.relationshipOptions)
	end

	-- Enemy: create new enemy if no specific target
	if relType == "enemy" and not targetId then
		return self:createRelationship(state, "enemy", options.relationshipOptions)
	end

	-- For other relationship types with targetId that doesn't exist, create it
	if targetId and not state.Relationships[targetId] then
		local relOptions = shallowCopy(options.relationshipOptions or {})
		relOptions.id = targetId
		return self:createRelationship(state, relType, relOptions)
	end

	return targetId and state.Relationships[targetId] or nil
end

function LifeBackend:handleInteraction(player, payload)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	if type(payload) ~= "table" then
		return { success = false, message = "Invalid interaction payload." }
	end

	-- CRITICAL FIX #131: Nil safety for payload fields
	local relType = payload.relationshipType or "family"
	local actionId = payload.actionId
	local targetId = payload.targetId
	local targetStrength = tonumber(payload.relationshipStrength)
	
	-- CRITICAL FIX #132: Validate required fields
	if not actionId then
		return { success = false, message = "No action specified." }
	end

	local actionSet = InteractionEffects[relType]
	if not actionSet then
		-- CRITICAL FIX #133: Try fallback to common action sets
		actionSet = InteractionEffects["family"]
		if not actionSet then
			return { success = false, message = "Unknown relationship type." }
		end
	end

	local action = actionSet[actionId]
	if not action then
		-- CRITICAL FIX #134: Try to find action in other sets
		for setName, otherSet in pairs(InteractionEffects) do
			if otherSet[actionId] then
				action = otherSet[actionId]
				break
			end
		end
		if not action then
			return { success = false, message = "Unknown interaction." }
		end
	end

	state.Flags = state.Flags or {}
	state.Relationships = state.Relationships or {}

	-- Single-only actions (meet_someone etc.)
	if action.requiresSingle then
		local partner = state.Relationships.partner
		if partner and partner.alive ~= false then
			return { success = false, message = "You're already in a relationship." }
		end
	end

	-- Money / cost checks
	if action.cost and (state.Money or 0) < action.cost then
		return { success = false, message = "You can't afford that gesture." }
	end

	if action.cost then
		self:addMoney(state, -action.cost)
	end

	local ensureOptions = {
		forceNewRelationship = action.forceNewRelationship,
		relationshipOptions = {
			id = targetId,
			name = payload.targetName,
			role = payload.targetRole,
			startLevel = targetStrength,
		},
	}

	local relationship = self:ensureRelationship(state, relType, targetId, ensureOptions)
	if not relationship then
		return { success = false, message = "No one to interact with." }
	end

	-- Apply relationship strength change
	if action.delta then
		relationship.relationship = clamp((relationship.relationship or 50) + action.delta, -100, 100)
	end

	-- Stat changes
	if action.stats then
		self:applyStatChanges(state, action.stats)
	end

	-- Optional reward / grant
	local grantMessage
	if action.grant then
		local ok, result = pcall(action.grant, state, relationship, payload)
		if not ok then
			warn("[LifeBackend] Interaction grant failed:", result)
		elseif type(result) == "string" then
			grantMessage = result
		elseif type(result) == "table" and result.message then
			grantMessage = result.message
		end
	end

	-- Removal (breakup / ghost, etc.) – ONLY this relationship
	if action.remove then
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX (deep-19 & deep-20): DIVORCE MECHANICS
		-- If married, divorce should split assets and calculate child support!
		-- ═══════════════════════════════════════════════════════════════════════════════
		local wasDivorce = state.Flags and state.Flags.married and relType == "romance"
		
		if wasDivorce then
			state.Flags.divorced = true
			state.Flags.recently_divorced = true
			
			-- ASSET SPLITTING
			local totalAssetValue = 0
			state.Assets = state.Assets or {}
			
			-- Count total asset value
			for _, vehicle in ipairs(state.Assets.Vehicles or {}) do
				totalAssetValue = totalAssetValue + (vehicle.value or vehicle.price or 0)
			end
			for _, property in ipairs(state.Assets.Properties or {}) do
				totalAssetValue = totalAssetValue + (property.value or property.price or 0)
			end
			for _, investment in ipairs(state.Assets.Investments or {}) do
				totalAssetValue = totalAssetValue + (investment.value or 0)
			end
			
			-- Split assets 50/50 (ex-spouse takes half)
			local assetLoss = math.floor(totalAssetValue * 0.5)
			
			-- Also split cash
			local cashLoss = math.floor((state.Money or 0) * 0.5)
			state.Money = (state.Money or 0) - cashLoss
			if state.Money < 0 then state.Money = 0 end
			
			local totalLoss = assetLoss + cashLoss
			
			if totalLoss > 0 then
				state.YearLog = state.YearLog or {}
				table.insert(state.YearLog, {
					type = "divorce_settlement",
					emoji = "💔",
					text = string.format("Lost $%s in divorce settlement", formatMoney(totalLoss)),
					amount = -totalLoss,
				})
			end
			
			-- CHILD SUPPORT - Check for children
			local childCount = 0
			for relId, rel in pairs(state.Relationships) do
				if type(rel) == "table" then
					local role = (rel.role or ""):lower()
					if role:find("son") or role:find("daughter") or role:find("child") then
						if rel.age and rel.age < 18 and rel.alive ~= false then
							childCount = childCount + 1
						end
					end
				end
			end
			
			if childCount > 0 then
				-- Calculate monthly child support based on income
				local monthlySupport = math.floor(((state.CurrentJob and state.CurrentJob.salary) or 30000) * 0.15 / 12)
				local annualSupport = monthlySupport * 12 * childCount
				
				state.Flags.pays_child_support = true
				state.Flags.child_support_amount = annualSupport
				state.Flags.child_support_children = childCount
				
				state.YearLog = state.YearLog or {}
				table.insert(state.YearLog, {
					type = "child_support",
					emoji = "👶",
					text = string.format("Ordered to pay $%s/year in child support for %d child(ren)", formatMoney(annualSupport), childCount),
					amount = -annualSupport,
				})
			end
			
			-- Happiness penalty
			self:applyStatChanges(state, { Happiness = -25 })
		end
		
		if relationship.id and state.Relationships[relationship.id] then
			state.Relationships[relationship.id] = nil
		end

		if relType == "romance" and state.Relationships.partner == relationship then
			-- Store ex for history
			state.Relationships.ex_partners = state.Relationships.ex_partners or {}
			if relationship.name then
				table.insert(state.Relationships.ex_partners, {
					name = relationship.name,
					wasMarried = wasDivorce,
					endedYear = state.Year,
				})
			end
			
			state.Relationships.partner = nil
			state.Flags.has_partner = nil
			state.Flags.dating = nil
			state.Flags.committed_relationship = nil
			state.Flags.married = nil
			state.Flags.engaged = nil
		end
	end

	-- Convert enemy -> friend, etc.
	if action.convert == "friend" then
		relationship.type = "friend"
		relationship.role = "Friend"
	end

	-- Flags
	if action.flag then
		state.Flags[action.flag] = true
	end

	if action.flags then
		for flagName, value in pairs(action.flags) do
			state.Flags[flagName] = value
		end
	end

	if action.clearFlags then
		for _, flagName in ipairs(action.clearFlags) do
			state.Flags[flagName] = nil
		end
	end

	-- Feed message
	local feed
	if type(action.message) == "function" then
		local ok, message = pcall(action.message, state, relationship, action, payload)
		if ok then
			feed = message
		else
			warn("[LifeBackend] Interaction message handler failed:", message)
		end
	end

	feed = feed or grantMessage or action.message or "You interacted."
	self:pushState(player, feed)

	-- IMPORTANT: do NOT return full state here – the UI should rely on SyncState,
	-- or only use this small payload for local row updates.
	return {
		success = true,
		message = feed,
		targetId = relationship.id,
		relationshipValue = relationship.relationship,
	}
end

-- ============================================================================
-- Story Paths
-- ============================================================================

function LifeBackend:startStoryPath(player, pathId)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	local path = StoryPaths[pathId]
	if not path then
		return { success = false, message = "Unknown path." }
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #1: Premium path gamepass checks
	-- Celebrity, Royal, and Mafia paths require gamepasses
	-- ═══════════════════════════════════════════════════════════════════════════════
	local premiumPaths = {
		celebrity = { key = "CELEBRITY", displayName = "Fame Package" },
		royal = { key = "ROYALTY", displayName = "Royalty Pass" },
		mafia = { key = "MAFIA", displayName = "Mafia Boss Pack" },
	}
	
	local premiumInfo = premiumPaths[pathId]
	if premiumInfo then
		if not self:checkGamepassOwnership(player, premiumInfo.key) then
			self:promptGamepassPurchase(player, premiumInfo.key)
			return { 
				success = false, 
				-- MINOR FIX #3: Cleaner gamepass name in error message
				message = "👑 The " .. path.name .. " path requires the " .. premiumInfo.displayName .. " gamepass.",
				needsGamepass = true,
				gamepassKey = premiumInfo.key
			}
		end
	end

	local req = path.requirements or {}

	if (state.Age or 0) < (path.minAge or 0) then
		return { success = false, message = "You're too young for this path." }
	end

	if req.education and not self:meetsEducationRequirement(state, req.education) then
		return { success = false, message = "You need more education first." }
	end

	if req.smarts and (state.Stats and state.Stats.Smarts or 0) < req.smarts then
		return { success = false, message = "You need to be smarter to walk this path." }
	end

	if req.looks and (state.Stats and state.Stats.Looks or 0) < req.looks then
		return { success = false, message = "You need higher looks for this path." }
	end

	if req.happiness and (state.Stats and state.Stats.Happiness or 0) < req.happiness then
		return { success = false, message = "You need to be happier for this path." }
	end

	state.Paths = state.Paths or {}
	state.Paths[pathId] = 0
	state.Paths.active = pathId
	state.ActivePath = pathId
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Set path-specific flags to trigger related events!
	-- User feedback: "Story paths don't do much" - need flags to enable event triggers
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.Flags = state.Flags or {}
	
	if pathId == "celebrity" then
		-- Celebrity/Fame path flags - triggers fame-related events
		state.Flags.pursuing_fame = true
		state.Flags.celebrity_aspirant = true
		state.Flags.interested_in_fame = true
		-- Initialize FameState if not exists
		state.FameState = state.FameState or {
			fame = 0,
			careerPath = "aspiring",
			socialFollowers = 0,
			contentPlatforms = {},
		}
		state.FameState.pursuing = true
		state.FameState.careerPath = state.FameState.careerPath or "aspiring"

		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Assign Content Creator job when starting Fame path!
		-- User feedback: "Fame path doesn't give me new content creator job"
		-- This ensures OccupationScreen shows the job immediately after starting path
		-- ═══════════════════════════════════════════════════════════════════════════════
		local contentCreatorJob = JobCatalog["new_influencer"]
		if contentCreatorJob then
			-- Assign the Content Creator job
			state.CurrentJob = {
				id = contentCreatorJob.id,
				name = contentCreatorJob.name,
				company = contentCreatorJob.company,
				salary = contentCreatorJob.salary,
				category = contentCreatorJob.category,
				difficulty = contentCreatorJob.difficulty or 1,
				minStats = contentCreatorJob.minStats,
			}

			-- Initialize career info
			state.CareerInfo = state.CareerInfo or {}
			state.CareerInfo.performance = 60
			state.CareerInfo.promotionProgress = 0
			state.CareerInfo.yearsAtJob = 0
			state.CareerInfo.raises = 0
			state.CareerInfo.promotions = 0

			-- Set career track
			state.Career = state.Career or {}
			state.Career.track = contentCreatorJob.category

			-- Set employment flags
			state.Flags.employed = true
			state.Flags.has_job = true
			state.Flags.between_jobs = nil
			state.Flags.unemployed = nil

			-- Grant job flags (content_creator, social_media_presence, influencer)
			if contentCreatorJob.grantsFlags then
				for _, flagName in ipairs(contentCreatorJob.grantsFlags) do
					state.Flags[flagName] = true
				end
			end

			print("[FAME PATH] Assigned Content Creator job:", contentCreatorJob.name)
		end
	elseif pathId == "political" then
		-- Political path flags
		state.Flags.pursuing_politics = true
		state.Flags.political_aspirant = true
		state.Flags.interested_in_politics = true
	elseif pathId == "criminal" then
		-- Crime path flags - enables crime empire events
		state.Flags.pursuing_crime = true
		state.Flags.criminal_aspirant = true
		state.Flags.interested_in_crime = true
		state.Flags.crime_path_active = true
	elseif pathId == "mafia" then
		-- CRITICAL FIX: Mafia path flags - enables mafia-specific events
		state.Flags.pursuing_mafia = true
		state.Flags.mafia_aspirant = true
		state.Flags.interested_in_crime = true
		state.Flags.mafia_path_active = true
		-- Initialize MobState for mafia tracking
		state.MobState = state.MobState or {
			inMob = false,
			familyId = nil,
			familyName = nil,
			rankIndex = 0,
			rankLevel = 0,
			rankName = "Outsider",
			respect = 0,
			notoriety = 0,
			heat = 0,
		}
		state.MobState.aspirant = true
	elseif pathId == "royal" then
		-- Royal path flags - NOTE: Does NOT make you royalty!
		-- The Royal path is about PURSUING/MARRYING INTO royalty, not being born royal
		state.Flags.pursuing_royalty = true
		state.Flags.royal_aspirant = true
		state.Flags.interested_in_royalty = true
		-- CRITICAL: Do NOT set is_royalty = true here!
		-- Player must marry into royalty or be born royal to become royalty
	end

	local feed = string.format("🌟 You began the %s path!", path.name)
	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:performPathAction(player, pathId, actionId)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	state.Paths = state.Paths or {}

	if state.Paths.active ~= pathId then
		return { success = false, message = "You're not on that path." }
	end

	local actionSet = StoryPathActions[pathId]
	if not actionSet then
		return { success = false, message = "No actions available." }
	end

	local action = actionSet[actionId]
	if not action then
		return { success = false, message = "Unknown path action." }
	end

	if action.cost and (state.Money or 0) < action.cost then
		return { success = false, message = "Insufficient funds for that move." }
	end

	if action.cost then
		self:addMoney(state, -action.cost)
	end

	if action.stats then
		self:applyStatChanges(state, action.stats)
	end

	local progress = state.Paths[pathId] or 0
	local path = StoryPaths[pathId]
	local stages = path.stages

	if action.reward then
		local payout = RANDOM:NextInteger(action.reward[1], action.reward[2])
		self:addMoney(state, payout)
	end

	if action.risk and RANDOM:NextInteger(1, 100) <= action.risk then
		progress = math.max(0, progress - RANDOM:NextNumber())
		state.Paths[pathId] = progress
		self:pushState(player, "A risky move set you back on your path.", {
			showPopup = true,
			emoji = "⚠️",
			title = "Setback",
			body = "Your risky move caused a setback.",
			wasSuccess = false,
		})
		return { success = false, message = "The move backfired." }
	end

	progress = progress + (action.progress or 0.05)
	if progress >= #stages then
		state.Paths[pathId] = #stages
		state.Paths.active = nil
		state.ActivePath = nil
		local feed = string.format("You completed the %s path!", path.name)
		self:pushState(player, feed, {
			showPopup = true,
			emoji = "🌟",
			title = "Path Complete",
			body = feed,
			wasSuccess = true,
		})
		return { success = true, message = feed }
	end

	state.Paths[pathId] = progress
	self:pushState(player, "You progressed along your path.")
	return { success = true, message = "Progress made." }
end

-- ============================================================================
-- Minigames
-- ============================================================================

function LifeBackend:handleMinigameResult(player, won, payload)
	local state = self:getState(player)
	if not state then
		return
	end
	
	-- CRITICAL FIX: Check if there's a pending event minigame to resolve
	local pending = self.pendingMinigameEvents and self.pendingMinigameEvents[player.UserId]
	if pending and pending.eventDef and pending.choice then
		local choice = pending.choice
		local eventDef = pending.eventDef
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #14: Track stat changes BEFORE and AFTER minigame resolution
		-- User feedback: "minigame result cards not giving stats they say"
		-- The result popup must show the ACTUAL stat changes that were applied!
		-- ═══════════════════════════════════════════════════════════════════════════════
		local preStats = {
			Happiness = state.Stats and state.Stats.Happiness or 50,
			Health = state.Stats and state.Stats.Health or 50,
			Smarts = state.Stats and state.Stats.Smarts or 50,
			Looks = state.Stats and state.Stats.Looks or 50,
		}
		local preMoney = state.Money or 0
		
		-- Create minigame result object
		local minigameResult = {
			success = won,
			won = won,
			payload = payload or {},
		}
		
		-- Execute the onResolve handler with minigame result
		if choice.onResolve and type(choice.onResolve) == "function" then
			local success, err = pcall(function()
				choice.onResolve(state, minigameResult)
			end)
			if not success then
				warn("[LifeBackend] Event minigame onResolve error:", err)
			end
		end
		
		-- Apply base effects from the choice
		if choice.effects then
			self:applyStatChanges(state, choice.effects)
		end
		
		-- Apply setFlags
		if choice.setFlags then
			state.Flags = state.Flags or {}
			for flag, value in pairs(choice.setFlags) do
				state.Flags[flag] = value
			end
		end
		
		-- CRITICAL FIX: Calculate the ACTUAL stat changes that occurred
		local postStats = {
			Happiness = state.Stats and state.Stats.Happiness or 50,
			Health = state.Stats and state.Stats.Health or 50,
			Smarts = state.Stats and state.Stats.Smarts or 50,
			Looks = state.Stats and state.Stats.Looks or 50,
		}
		local postMoney = state.Money or 0
		
		local resultData = {
			showPopup = true,
			wasSuccess = won,
			emoji = won and "🎉" or "😓",
			title = won and "Success!" or "Failed!",
			body = choice.feedText or (won and "You succeeded at the challenge!" or "You failed the challenge."),
			happiness = postStats.Happiness - preStats.Happiness,
			health = postStats.Health - preStats.Health,
			smarts = postStats.Smarts - preStats.Smarts,
			looks = postStats.Looks - preStats.Looks,
			money = postMoney - preMoney,
		}
		
		-- Clear the pending minigame
		self.pendingMinigameEvents[player.UserId] = nil
		
		-- Complete the age cycle with ACTUAL stat changes
		state.awaitingDecision = false
		local feedText = choice.feedText or (won and "You succeeded!" or "You failed.")
		self:completeAgeCycle(player, state, feedText, resultData)
		
		return
	end
	
	-- Fallback for standalone minigames (not event-related)
	if won then
		self:applyStatChanges(state, { Happiness = 3 })
	else
		self:applyStatChanges(state, { Happiness = -2 })
	end
	self:pushState(player, won and "You crushed the minigame!" or "You failed the minigame.")
end

-- ============================================================================
-- PREMIUM FEATURES: Organized Crime / Mob System
-- ============================================================================

-- Crime family definitions
-- Mob operations
function LifeBackend:handleJoinMob(player, familyId)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end

	local canJoin, reason = MafiaSystem:canJoinMob(state)
	if not canJoin then
		return { success = false, message = reason or "You can't join the mob right now." }
	end

	if not self:checkGamepassOwnership(player, "MAFIA") then
		self:promptGamepassPurchase(player, "MAFIA")
		return {
			success = false,
			message = "Organized crime requires the Mafia gamepass.",
			needsGamepass = true,
		}
	end

	local success, message = MafiaSystem:joinFamily(state, familyId)
	if not success then
		return { success = false, message = message or "The family rejected you." }
	end

	local msg = message or "You've joined the crime family."
	self:pushState(player, msg)
	
	return { success = true, message = msg, mobState = MafiaSystem:serialize(state) }
end

function LifeBackend:handleLeaveMob(player)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end

	local success, message, consequences = MafiaSystem:leaveFamily(state)
	if not success then
		return { success = false, message = message or "You can't leave right now." }
	end

	if type(consequences) == "table" and #consequences > 0 then
		appendFeed(state, table.concat(consequences, " "))
	end

	local msg = message or "You left the family. Watch your back..."
	self:pushState(player, msg)
	
	return { success = true, message = msg }
end

function LifeBackend:handleMobOperation(player, operationId)
	-- CRITICAL FIX #12: Check MAFIA gamepass before operations
	if not self:checkGamepassOwnership(player, "MAFIA") then
		self:promptGamepassPurchase(player, "MAFIA")
		return {
			success = false,
			message = "🔫 Organized Crime operations require the Mafia gamepass.",
			needsGamepass = true,
			gamepassKey = "MAFIA"
		}
	end
	
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end
	local success, message, opResult = MafiaSystem:doOperation(state, operationId)
	if success then
		local resp = {
			success = true,
			message = message or "Operation complete!",
			money = opResult and opResult.money,
			respect = opResult and opResult.respect,
			promoted = opResult and opResult.promoted,
		}
		self:pushState(player, resp.message)
		return resp
	end

	local resultPayload = {
		success = false,
		message = message or "The operation failed.",
		arrested = opResult and opResult.arrested,
	}

	if opResult and opResult.arrested then
		self:pushState(player, resultPayload.message)
	end

	return resultPayload
end

function LifeBackend:handleGodModeEdit(player, payload)
	payload = payload or {}
	if not self:checkGamepassOwnership(player, "GOD_MODE") then
		self:promptGamepassPurchase(player, "GOD_MODE")
		return {
			success = false,
			message = "⚡ God Mode requires the God Mode gamepass.",
			needsGamepass = true,
		}
	end

	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	local summaries = {}
	local statsPayload = payload.stats or {}

	local function applyStat(key, value)
		if value == nil then
			return
		end
		local num = tonumber(value)
		if not num then
			return
		end
		num = clamp(math.floor(num + 0.5), 0, 100)
		state.Stats = state.Stats or {}
		state.Stats[key] = num
		state[key] = num
		table.insert(summaries, string.format("%s set to %d%%", key, num))
	end

	applyStat("Happiness", statsPayload.Happiness or payload.Happiness)
	applyStat("Health", statsPayload.Health or payload.Health)
	applyStat("Smarts", statsPayload.Smarts or payload.Smarts)
	applyStat("Looks", statsPayload.Looks or payload.Looks)

	if payload.name and type(payload.name) == "string" then
		local trimmed = payload.name:gsub("^%s+", ""):gsub("%s+$", "")
		if trimmed ~= "" then
			state.Name = trimmed:sub(1, 40)
			table.insert(summaries, "Name updated")
		end
	end

	-- CRITICAL FIX: Store gender with proper capitalization for client compatibility
	if payload.gender and type(payload.gender) == "string" then
		local genderLower = payload.gender:lower()
		if genderLower == "male" then
			state.Gender = "Male"
			table.insert(summaries, "Gender updated")
		elseif genderLower == "female" then
			state.Gender = "Female"
			table.insert(summaries, "Gender updated")
		elseif genderLower == "nonbinary" then
			state.Gender = "Nonbinary"
			table.insert(summaries, "Gender updated")
		end
	end

	if payload.money ~= nil then
		local money = tonumber(payload.money)
		if money then
			state.Money = math.max(0, math.floor(money))
			table.insert(summaries, "Money set to " .. formatMoney(state.Money))
		end
	end

	if payload.clearCareer then
		if state.CurrentJob then
			state:ClearCareer()
			table.insert(summaries, "Career cleared")
		end
	elseif payload.careerId and type(payload.careerId) == "string" and payload.careerId ~= "" then
		local jobData = self:findJobByInput(payload.careerId)
		if jobData then
			state:SetCareer(jobData)
			table.insert(summaries, "Career set to " .. jobData.name)
		else
			return { success = false, message = "Couldn't find a career matching '" .. payload.careerId .. "'." }
		end
	end

	-- GOD MODE CHARACTER CREATION FEATURES
	-- Handle family wealth setting (only during creation - godModeCreate flag)
	if payload.godModeCreate and payload.familyWealth then
		local wealthSettings = {
			["Poor"] = { min = 0, max = 500, flag = "poor_family" },
			["Lower Middle"] = { min = 1000, max = 5000, flag = nil },
			["Middle Class"] = { min = 5000, max = 20000, flag = nil },
			["Upper Middle"] = { min = 50000, max = 100000, flag = "wealthy_parents" },
			["Rich"] = { min = 500000, max = 2000000, flag = "rich_family" },
			["Famous"] = { min = 5000000, max = 10000000, flag = "famous_family" },
		}
		
		local wealth = wealthSettings[payload.familyWealth]
		if wealth then
			local moneyAmount = RANDOM:NextInteger(wealth.min, wealth.max)
			state.Money = moneyAmount
			if wealth.flag then
				state.Flags = state.Flags or {}
				state.Flags[wealth.flag] = true
			end
			-- CRITICAL FIX: Use specific message based on wealth level
			local wealthMessage = "Family wealth set to " .. payload.familyWealth
			if payload.familyWealth == "Famous" then
				wealthMessage = "👑 Born into a famous royal family with $" .. formatMoney(moneyAmount) .. " inheritance!"
			elseif payload.familyWealth == "Rich" then
				wealthMessage = "🏰 Born into a wealthy family with $" .. formatMoney(moneyAmount) .. " trust fund!"
			elseif payload.familyWealth == "Upper Middle" then
				wealthMessage = "🏢 Born into an upper middle class family with $" .. formatMoney(moneyAmount) .. "."
			elseif payload.familyWealth == "Poor" then
				wealthMessage = "🏚️ Born into a poor family. Starting with just $" .. formatMoney(moneyAmount) .. "."
			end
			table.insert(summaries, wealthMessage)
		end
	end
	
	-- CRITICAL FIX #150: Handle starting stats from God Mode creation
	-- Must sync BOTH state.Stats.* AND state.* for consistency!
	if payload.godModeCreate and payload.stats then
		if type(payload.stats) == "table" then
			state.Stats = state.Stats or {}
			-- Apply custom starting stats - sync both locations
			if payload.stats.Happiness then
				local val = math.clamp(tonumber(payload.stats.Happiness) or 50, 0, 100)
				state.Happiness = val
				state.Stats.Happiness = val
			end
			if payload.stats.Health then
				local val = math.clamp(tonumber(payload.stats.Health) or 100, 0, 100)
				state.Health = val
				state.Stats.Health = val
			end
			if payload.stats.Smarts then
				local val = math.clamp(tonumber(payload.stats.Smarts) or 50, 0, 100)
				state.Smarts = val
				state.Stats.Smarts = val
			end
			if payload.stats.Looks then
				local val = math.clamp(tonumber(payload.stats.Looks) or 50, 0, 100)
				state.Looks = val
				state.Stats.Looks = val
			end
			table.insert(summaries, "Starting stats customized")
		end
	end
	
	-- Handle ethnicity setting
	if payload.ethnicity and payload.ethnicity ~= "Random" then
		state.Flags = state.Flags or {}
		state.Flags.ethnicity = payload.ethnicity
		table.insert(summaries, "Ethnicity set to " .. payload.ethnicity)
	end
	
	-- Handle country setting
	if payload.country then
		state.Flags = state.Flags or {}
		state.Flags.country = payload.country
		table.insert(summaries, "Country set to " .. payload.country)
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #7 & #28: ROYAL BIRTH INITIALIZATION
	-- Handle "Born Royal" family wealth option - requires Royalty gamepass
	-- Now also checks for isRoyalBirth flag from character creation
	-- ═══════════════════════════════════════════════════════════════════════════════
	if payload.familyWealth == "Royal" or payload.familyWealth == "Royalty" or payload.bornRoyal or payload.isRoyalBirth then
		if self:checkGamepassOwnership(player, "ROYALTY") then
			-- Initialize royal state
			local royalCountryId = payload.royalCountry or "uk" -- Default to UK
			local royalCountries = {
				uk = { id = "uk", name = "United Kingdom", emoji = "🇬🇧", palace = "Buckingham Palace", startingWealth = { min = 50000000, max = 500000000 } },
				spain = { id = "spain", name = "Spain", emoji = "🇪🇸", palace = "Royal Palace of Madrid", startingWealth = { min = 30000000, max = 200000000 } },
				japan = { id = "japan", name = "Japan", emoji = "🇯🇵", palace = "Imperial Palace", startingWealth = { min = 100000000, max = 800000000 } },
				monaco = { id = "monaco", name = "Monaco", emoji = "🇲🇨", palace = "Prince's Palace", startingWealth = { min = 200000000, max = 1000000000 } },
				saudi = { id = "saudi", name = "Saudi Arabia", emoji = "🇸🇦", palace = "Al-Yamamah Palace", startingWealth = { min = 500000000, max = 5000000000 } },
				sweden = { id = "sweden", name = "Sweden", emoji = "🇸🇪", palace = "Stockholm Palace", startingWealth = { min = 20000000, max = 150000000 } },
				netherlands = { id = "netherlands", name = "Netherlands", emoji = "🇳🇱", palace = "Royal Palace Amsterdam", startingWealth = { min = 30000000, max = 200000000 } },
				belgium = { id = "belgium", name = "Belgium", emoji = "🇧🇪", palace = "Royal Palace of Brussels", startingWealth = { min = 25000000, max = 180000000 } },
				denmark = { id = "denmark", name = "Denmark", emoji = "🇩🇰", palace = "Amalienborg Palace", startingWealth = { min = 25000000, max = 150000000 } },
				norway = { id = "norway", name = "Norway", emoji = "🇳🇴", palace = "Royal Palace Oslo", startingWealth = { min = 25000000, max = 150000000 } },
				morocco = { id = "morocco", name = "Morocco", emoji = "🇲🇦", palace = "Royal Palace of Rabat", startingWealth = { min = 80000000, max = 400000000 } },
				jordan = { id = "jordan", name = "Jordan", emoji = "🇯🇴", palace = "Al-Husseiniya Palace", startingWealth = { min = 50000000, max = 300000000 } },
				thailand = { id = "thailand", name = "Thailand", emoji = "🇹🇭", palace = "Grand Palace", startingWealth = { min = 100000000, max = 600000000 } },
			}
			
			local country = royalCountries[royalCountryId] or royalCountries.uk
			local wealthRange = country.startingWealth
			local royalWealth = RANDOM:NextInteger(wealthRange.min, wealthRange.max)
			
			-- Determine title based on gender
			local gender = state.Gender or "Male"
			local title = (gender == "Female") and "Princess" or "Prince"
			
			-- Initialize royal state
			state.RoyalState = {
				isRoyal = true,
				isMonarch = false,
				country = country.id,
				countryName = country.name,
				countryEmoji = country.emoji,
				palace = country.palace,
				title = title,
				lineOfSuccession = RANDOM:NextInteger(1, 5),
				popularity = 75 + RANDOM:NextInteger(-10, 10),
				scandals = 0,
				dutiesCompleted = 0,
				dutyStreak = 0,
				reignYears = 0,
				wealth = royalWealth,
				awards = {},
				charitiesPatronized = {},
				stateVisits = {},
			}
			
			state.Money = royalWealth
			
			-- Set royal flags
			state.Flags.is_royalty = true
			state.Flags.royal_birth = true
			state.Flags.royal_country = country.id
			state.Flags.wealthy_family = true
			state.Flags.upper_class = true
			state.Flags.famous_family = true
			state.Flags.royalty_gamepass = true
			
			table.insert(summaries, string.format("👑 Born as %s of %s %s with $%s inheritance!", title, country.emoji, country.name, formatMoney(royalWealth)))
		else
			-- No gamepass, prompt purchase
			self:promptGamepassPurchase(player, "ROYALTY")
			table.insert(summaries, "👑 Royal birth requires the Royalty gamepass!")
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #8: CELEBRITY CAREER INITIALIZATION
	-- Handle starting a fame career from character creation - requires Celebrity gamepass
	-- ═══════════════════════════════════════════════════════════════════════════════
	if payload.famePath and payload.famePath ~= "" then
		if self:checkGamepassOwnership(player, "CELEBRITY") then
			local careerPaths = {
				actor = { name = "Acting", emoji = "🎬", firstStage = "Extra", salary = { min = 500, max = 2000 } },
				musician = { name = "Music", emoji = "🎵", firstStage = "Street Performer", salary = { min = 50, max = 500 } },
				influencer = { name = "Social Media", emoji = "📱", firstStage = "New Creator", salary = { min = 0, max = 100 } },
				athlete = { name = "Professional Sports", emoji = "🏆", firstStage = "Amateur", salary = { min = 0, max = 500 } },
				model = { name = "Modeling", emoji = "📸", firstStage = "Amateur Model", salary = { min = 100, max = 1000 } },
			}
			
			local path = careerPaths[payload.famePath]
			if path then
				state.FameState = {
					isFamous = false,
					careerPath = payload.famePath,
					careerName = path.name,
					currentStage = 1,
					stageName = path.firstStage,
					subType = payload.fameSubType,
					yearsInCareer = 0,
					lastPromotionYear = 0,
					followers = 0,
					endorsements = {},
					awards = {},
					scandals = 0,
					fameLevel = "Unknown",
				}
				
				state.CurrentJob = {
					id = payload.famePath .. "_starter",
					name = path.firstStage,
					company = path.name .. " Industry",
					salary = RANDOM:NextInteger(path.salary.min, path.salary.max),
					category = "entertainment",
					isFameCareer = true,
				}
				
				state.Flags.fame_career = true
				state.Flags.entertainment_industry = true
				state.Flags["career_" .. payload.famePath] = true
				state.Flags.employed = true
				state.Flags.has_job = true
				state.Flags.celebrity_gamepass = true
				
				table.insert(summaries, string.format("%s Started %s career as %s!", path.emoji, path.name, path.firstStage))
			end
		else
			self:promptGamepassPurchase(player, "CELEBRITY")
			table.insert(summaries, "⭐ Fame careers require the Celebrity gamepass!")
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #165: GOD MODE QUICK ACTIONS - In-game button support
	-- Handle quickAction from in-game God Mode editor
	-- ═══════════════════════════════════════════════════════════════════════════════
	if payload.quickAction then
		local action = payload.quickAction
		if GodModeSystem then
			if action == "cure_diseases" then
				local success, msg = GodModeSystem:cureDiseases(state)
				table.insert(summaries, msg or "💊 All diseases cured!")
			elseif action == "remove_addictions" then
				local success, msg = GodModeSystem:removeAddictions(state)
				table.insert(summaries, msg or "🚭 All addictions removed!")
			elseif action == "clear_record" then
				local success, msg = GodModeSystem:clearCriminalRecord(state)
				table.insert(summaries, msg or "📋 Criminal record cleared!")
			elseif action == "max_stats" then
				-- CRITICAL FIX #166: Max all stats to 100
				state.Stats = state.Stats or {}
				state.Stats.Happiness = 100
				state.Stats.Health = 100
				state.Stats.Smarts = 100
				state.Stats.Looks = 100
				state.Happiness = 100
				state.Health = 100
				state.Smarts = 100
				state.Looks = 100
				table.insert(summaries, "⬆️ All stats maxed to 100%!")
			elseif action == "clear_debt" then
				local success, msg = GodModeSystem:clearDebt(state)
				table.insert(summaries, msg or "💳 All debt cleared!")
			elseif action == "full_heal" then
				-- CRITICAL FIX #167: Full heal action
				state.Stats = state.Stats or {}
				state.Stats.Health = 100
				state.Health = 100
				-- Also clear health-related flags
				state.Flags = state.Flags or {}
				state.Flags.injured = nil
				state.Flags.seriously_injured = nil
				state.Flags.hospitalized = nil
				table.insert(summaries, "❤️ Fully healed! Health restored to 100%")
			-- CRITICAL FIX #182: Additional quick actions
			elseif action == "max_relationships" then
				local success, msg = GodModeSystem:maxAllRelationships(state)
				table.insert(summaries, msg or "💕 All relationships maxed!")
			elseif action == "revive_family" then
				local success, msg = GodModeSystem:reviveDeadRelatives(state)
				table.insert(summaries, msg or "✨ Revived deceased family!")
			elseif action == "fix_stats" then
				local success, msg = GodModeSystem:fixNegativeStats(state)
				table.insert(summaries, msg or "🔧 Fixed stat values!")
			elseif action == "jail_break" then
				local success, msg = GodModeSystem:releaseFromJail(state)
				table.insert(summaries, msg or "🔓 Released from jail!")
			elseif action == "fresh_start" then
				local success, msg = GodModeSystem:clearAllNegativeFlags(state)
				table.insert(summaries, msg or "🔄 Fresh start applied!")
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #20: GOD MODE PRESETS - Quick preset application
	-- ═══════════════════════════════════════════════════════════════════════════════
	if payload.preset then
		if GodModeSystem then
			local success, msg = GodModeSystem:applyPreset(state, payload.preset)
			if success then
				table.insert(summaries, msg)
			end
		end
	end
	
	-- Handle clearing flags (criminal record, diseases, addictions, debt)
	if payload.clearCriminalRecord then
		if GodModeSystem then
			GodModeSystem:clearCriminalRecord(state)
			table.insert(summaries, "📋 Criminal record cleared!")
		end
	end
	
	if payload.cureDiseases then
		if GodModeSystem then
			GodModeSystem:cureDiseases(state)
			table.insert(summaries, "💊 All diseases cured!")
		end
	end
	
	if payload.removeAddictions then
		if GodModeSystem then
			GodModeSystem:removeAddictions(state)
			table.insert(summaries, "🚭 All addictions removed!")
		end
	end
	
	if payload.clearDebt then
		if GodModeSystem then
			GodModeSystem:clearDebt(state)
			table.insert(summaries, "💳 All debt cleared!")
		end
	end

	if #summaries == 0 then
		return { success = false, message = "No God Mode changes were provided." }
	end

	state.Flags = state.Flags or {}
	state.Flags.god_mode_last_used = os.time()
	
	-- Mark as God Mode created character
	if payload.godModeCreate then
		state.Flags.god_mode_created = true
	end

	local feedText = payload.godModeCreate 
		and "⚡ A custom life begins..." 
		or ("⚡ God Mode update: " .. table.concat(summaries, " • "))
	-- CRITICAL FIX #501: DON'T call appendFeed here!
	-- appendFeed stores to PendingFeed which shows again at Age 1
	-- pushState already sends the message immediately to the client
	-- Calling both causes the message to appear TWICE (now + Age 1)
	self:pushState(player, feedText)

	return { success = true, message = feedText, changes = summaries }
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #60: Get God Mode info for client UI
-- Returns presets, editable stats, and clearable flags for the God Mode screen
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:getGodModeInfo(player)
	local hasGodMode = self:checkGamepassOwnership(player, "GOD_MODE")
	
	if not hasGodMode then
		return {
			success = false,
			hasGamepass = false,
			message = "⚡ God Mode requires the God Mode gamepass.",
		}
	end
	
	local state = self:getState(player)
	local godModeInfo = {
		success = true,
		hasGamepass = true,
	}
	
	-- Get configuration from GodModeSystem
	if GodModeSystem then
		godModeInfo.presets = GodModeSystem:getPresetsInfo()
		godModeInfo.editableStats = GodModeSystem:getEditableStatsInfo()
		godModeInfo.editableProperties = GodModeSystem:getEditablePropertiesInfo()
		godModeInfo.clearableFlags = GodModeSystem:getClearableFlagsInfo()
	else
		-- Fallback if GodModeSystem not loaded
		godModeInfo.presets = {
			{ id = "perfect", name = "Perfect Life", emoji = "✨", description = "Max all stats, clear all negatives" },
			{ id = "rich", name = "Billionaire", emoji = "💎", description = "Set money to $1 billion" },
			{ id = "famous", name = "Famous", emoji = "⭐", description = "Max fame to 100" },
			{ id = "healthy", name = "Peak Health", emoji = "💪", description = "Max health, cure all diseases" },
			{ id = "genius", name = "Genius", emoji = "🧠", description = "Max smarts to 100" },
			{ id = "fresh_start", name = "Fresh Start", emoji = "🔄", description = "Clear all negative flags" },
		}
		godModeInfo.editableStats = {
			{ key = "Happiness", emoji = "😊", name = "Happiness", min = 0, max = 100 },
			{ key = "Health", emoji = "❤️", name = "Health", min = 0, max = 100 },
			{ key = "Smarts", emoji = "🧠", name = "Smarts", min = 0, max = 100 },
			{ key = "Looks", emoji = "✨", name = "Looks", min = 0, max = 100 },
		}
		godModeInfo.editableProperties = {
			{ key = "name", emoji = "📝", name = "Character Name", type = "string" },
			{ key = "gender", emoji = "👤", name = "Gender", type = "select", options = { "Male", "Female", "Nonbinary" } },
		}
		godModeInfo.clearableFlags = {
			{ key = "criminal_record", emoji = "📋", name = "Criminal Record" },
			{ key = "diseases", emoji = "💊", name = "All Diseases" },
			{ key = "addictions", emoji = "🚭", name = "All Addictions" },
			{ key = "debt", emoji = "💳", name = "All Debt" },
		}
	end
	
	-- Include current state info for the UI
	if state then
		godModeInfo.currentStats = {
			Happiness = state.Stats and state.Stats.Happiness or state.Happiness or 50,
			Health = state.Stats and state.Stats.Health or state.Health or 50,
			Smarts = state.Stats and state.Stats.Smarts or state.Smarts or 50,
			Looks = state.Stats and state.Stats.Looks or state.Looks or 50,
		}
		godModeInfo.currentMoney = state.Money or 0
		godModeInfo.currentName = state.Name
		godModeInfo.currentGender = state.Gender
		godModeInfo.currentAge = state.Age
	end
	
	return godModeInfo
end

function LifeBackend:handleTimeMachine(player, yearsBack)
	-- CRITICAL FIX #362: Check for gamepass (unlimited) OR developer product (one-time)
	local hasGamepass = self:checkGamepassOwnership(player, "TIME_MACHINE")
	
	if not hasGamepass then
		-- User doesn't have unlimited gamepass - they need to buy a one-time product
		-- Get the product key for this number of years
		local productKey = GamepassSystem:getProductKeyForYears(yearsBack)
		local productId = GamepassSystem:getProductIdForYears(yearsBack)
		
		if productId and productId > 0 then
			-- Prompt the developer product purchase (one-time use)
			self:promptProductPurchase(player, productKey)
			return { 
				success = false, 
				message = "⏰ Purchase this time travel option!", 
				needsProduct = true,
				productKey = productKey,
				productId = productId,
				yearsBack = yearsBack
			}
		else
			-- Fallback to gamepass prompt if no product available
			self:promptGamepassPurchase(player, "TIME_MACHINE")
			return { 
				success = false, 
				message = "👑 Get the Time Machine pass for unlimited rewinds!", 
				needsGamepass = true,
				gamepassKey = "TIME_MACHINE"
			}
		end
	end
	
	-- User has gamepass - proceed with time travel (unlimited uses)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end
	
	local currentAge = state.Age
	local targetAge = yearsBack == -1 and 0 or (currentAge - yearsBack)
	
	if targetAge < 0 then
		targetAge = 0
	end
	
	local yearsRewound = currentAge - targetAge
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #1: Reset death state - player is no longer dead!
	-- Without this, player would still be "dead" after using Time Machine
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.Flags = state.Flags or {}
	state.Flags.dead = nil
	state.DeathReason = nil
	state.DeathAge = nil
	state.DeathYear = nil
	state.CauseOfDeath = nil
	
	-- Reset to target age
	state.Age = targetAge
	state.Year = state.Year - yearsRewound
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #2: Rewind family members' ages too!
	-- If mom was 80 when you died at 55, going back to baby should make her 25 again
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.Relationships then
		for relId, rel in pairs(state.Relationships) do
			if type(rel) == "table" then
				-- Rewind their age by the same amount
				if rel.age and type(rel.age) == "number" then
					rel.age = rel.age - yearsRewound
					-- Make sure they're at least a reasonable age
					if relId == "mother" or relId == "father" then
						rel.age = math.max(rel.age, 20) -- Parents at least 20
					elseif relId:find("grand") then
						rel.age = math.max(rel.age, 50) -- Grandparents at least 50
					else
						rel.age = math.max(rel.age, 0) -- Others at least 0
					end
				end
				
				-- CRITICAL FIX #3: Resurrect family members who died after this point
				-- If we're going back 30 years, family who died in the last 30 years should be alive
				if rel.deceased and rel.deathAge then
					local theirAgeNow = (rel.age or 0)
					local theirAgeAtDeath = rel.deathAge
					-- If their "current" rewound age is before they died, bring them back
					if theirAgeNow < theirAgeAtDeath then
						rel.alive = true
						rel.deceased = nil
						rel.deathAge = nil
						rel.deathYear = nil
					end
				end
			end
		end
	end

	pruneRelationshipsForAge(state, targetAge)
	resetMobStateForAge(state, targetAge)
	
	-- Reset some stats based on age
	if targetAge == 0 then
		-- Baby reset - full reset
		state.Stats = state.Stats or {}
		state.Stats.Happiness = 90
		state.Stats.Health = 100
		state.Health = 100 -- CRITICAL: Sync both health fields!
		state.Happiness = 90
		state.Money = 0
		state.Education = "none"
		state.CurrentJob = nil
		-- CRITICAL FIX #154: Reset Career to empty table instead of nil to prevent nil access errors
		state.Career = {}
		-- CRITICAL FIX #155: Reset CareerInfo properly on time travel to baby
		state.CareerInfo = state.CareerInfo or {}
		state.CareerInfo.performance = 0
		state.CareerInfo.promotionProgress = 0
		state.CareerInfo.yearsAtJob = 0
		state.CareerInfo.raises = 0
		state.CareerInfo.promotions = 0
		state.CareerInfo.totalYearsWorked = 0
		state.InJail = false
		state.JailYearsLeft = 0
		-- Reset education data
		if state.EducationData then
			state.EducationData = {
				Status = "enrolled",
				Level = "elementary",
				Progress = 0,
				Duration = 5,
			}
		end
		-- CRITICAL FIX #112: Full MobState reset with nil safety
		if state.MobState then
			state.MobState.inMob = false
			state.MobState.family = nil
			state.MobState.familyId = nil
			state.MobState.familyName = nil
			state.MobState.rank = nil
			state.MobState.rankIndex = 1
			state.MobState.rankLevel = 1
			state.MobState.rankName = "Associate"
			state.MobState.rankEmoji = "👤"
			state.MobState.respect = 0
			state.MobState.notoriety = 0
			state.MobState.heat = 0
			state.MobState.loyalty = 100
			state.MobState.kills = 0
			state.MobState.earnings = 0
			state.MobState.yearsInMob = 0
			state.MobState.operationsCompleted = 0
			state.MobState.operationsFailed = 0
		end
		-- CRITICAL FIX #113: Full RoyalState reset on time travel to baby
		if state.RoyalState then
			state.RoyalState.isRoyal = false
			state.RoyalState.isMonarch = false
			state.RoyalState.country = nil
			state.RoyalState.countryName = nil
			state.RoyalState.title = nil
			state.RoyalState.lineOfSuccession = 0
			state.RoyalState.popularity = 0
			state.RoyalState.scandals = 0
			state.RoyalState.dutiesCompleted = 0
			state.RoyalState.reignYears = 0
			state.RoyalState.wealth = 0
		end
		-- CRITICAL FIX #114: Full FameState reset
		if state.FameState then
			state.FameState.isFamous = false
			state.FameState.careerPath = nil
			state.FameState.currentStage = 1 -- CRITICAL FIX: Lua is 1-indexed
			state.FameState.followers = 0
			state.FameState.scandals = 0
			state.FameState.yearsInCareer = 0
		end
		-- Clear most flags but keep some identity ones
		local keepFlags = { gender = state.Flags.gender }
		state.Flags = keepFlags
	else
		-- Partial reset - restore health somewhat
		state.Stats = state.Stats or {}
		state.Stats.Health = math.min(100, (state.Stats.Health or 50) + 30)
		state.Health = state.Stats.Health -- CRITICAL: Sync both health fields!
		state.InJail = false
		state.JailYearsLeft = 0
		state.Flags.in_prison = nil
		state.Flags.incarcerated = nil
	end
	
	local msg = string.format("⏰ Time traveled back to age %d!", targetAge)
	self:pushState(player, msg)
	
	return { success = true, message = msg, newAge = targetAge }
end

-- ============================================================================
-- Initialization Entry Point
-- ============================================================================

function LifeBackend:start()
	self:setupRemotes()
	for _, player in ipairs(Players:GetPlayers()) do
		self:onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(function(player)
		self:onPlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerRemoving(player)
	end)

	-- ════════════════════════════════════════════════════════════════════════════════
	-- CRITICAL: BIND TO CLOSE - Save all players when server shuts down
	-- This prevents data loss during server restarts/shutdowns
	-- ════════════════════════════════════════════════════════════════════════════════
	game:BindToClose(function()
		print("[LifeBackend] 🛑 Server shutting down - saving all player data...")
		self:saveAllPlayers()
		print("[LifeBackend] ✅ All data saved before shutdown")
	end)

	-- ════════════════════════════════════════════════════════════════════════════════
	-- PERIODIC AUTO-SAVE - Save all players every 5 minutes as backup
	-- This provides additional protection against data loss
	-- ════════════════════════════════════════════════════════════════════════════════
	local AUTO_SAVE_INTERVAL = 300 -- 5 minutes in seconds
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)
			print("[LifeBackend] ⏰ Periodic auto-save triggered...")
			self:saveAllPlayers()
		end
	end)

	print("[LifeBackend] ✅ Data persistence system initialized (auto-save every 5 min)")
end

local backendSingleton

return {
	init = function()
		if backendSingleton then
			return backendSingleton
		end
		backendSingleton = LifeBackend.new()
		backendSingleton:start()
		return backendSingleton
	end,
}
