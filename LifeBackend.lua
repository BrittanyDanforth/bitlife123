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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL: Run canonical validator before saving
	-- This ensures we never save ghost states, zombie flags, or invalid data
	-- RVS cleans: premium flags, event chains, relationships, assets, housing, jobs
	-- ═══════════════════════════════════════════════════════════════════════════════
	print("[LifeBackend] Running pre-save validation...")
	self:validateStateConsistency(state)
	self:validateRecursiveState(state)
	print("[LifeBackend] Pre-save validation complete")

	local serialized = serializeState(state)
	if not serialized then
		warn("[LifeBackend] Cannot save - serialization failed")
		return false
	end

	local key = "Player_" .. player.UserId

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #960: Use UpdateAsync instead of SetAsync to prevent race conditions!
	-- SetAsync can cause data loss if player saves twice quickly or leaves during save
	-- UpdateAsync is atomic and handles concurrent writes safely
	-- ═══════════════════════════════════════════════════════════════════════════════
	local success, err = pcall(function()
		store:UpdateAsync(key, function(oldData)
			-- If no old data or new data is newer, use new data
			-- This prevents overwriting newer saves with older data
			if not oldData then
				return serialized
			end
			
			-- Compare ages - only save if newer
			local oldAge = oldData.Age or 0
			local newAge = serialized.Age or 0
			
			-- If new data is older (somehow), keep old data
			if newAge < oldAge then
				warn("[LifeBackend] ⚠️ Skipping save - old data is newer!")
				return nil -- Return nil to abort the update
			end
			
			return serialized
		end)
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #507: Added forceBypassCooldown parameter for direct user clicks!
-- When user clicks a gamepass button, they should ALWAYS see the Roblox prompt!
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:promptGamepassPurchase(player, gamepassKey, forceBypassCooldown)
	if not player then
		return false, "no_player"
	end

	local success, promptSuccess, reason, extra = pcall(function()
		return GamepassSystem:promptGamepass(player, gamepassKey, forceBypassCooldown)
	end)

	if not success then
		warn(string.format("[LifeBackend] Failed to prompt %s purchase: %s", tostring(gamepassKey), tostring(promptSuccess)))
		return false, "error"
	end
	
	return promptSuccess, reason, extra
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: Show Time Machine offer popup BEFORE prompting purchase
-- User complaint: "It just prompts the gamepass, no UI explaining what it does!"
-- This shows a nice popup explaining the Time Machine before the purchase prompt
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:showTimeMachineOffer(player, context)
	if not player or not self.remotes or not self.remotes.ShowResult then
		return
	end
	
	local emoji, title, body
	
	if context == "jail" then
		emoji = "⏰"
		title = "Time Machine Can Help!"
		body = "🚔 Going to jail?\n\n⏰ The TIME MACHINE lets you go back in time and UNDO this!\n\n✨ Rewind your life before you got caught!\n✨ Make different choices!\n✨ Avoid jail completely!\n\n🎮 Get unlimited rewinds with the Time Machine gamepass!"
	elseif context == "death" then
		emoji = "⏰"
		title = "Don't Want To Die?"
		body = "💀 Your life is ending...\n\n⏰ The TIME MACHINE can save you!\n\n✨ Go back 5, 10, or 20 years!\n✨ Make different choices!\n✨ Live a longer, better life!\n\n🎮 Get unlimited rewinds with the Time Machine gamepass!"
	else
		emoji = "⏰"
		title = "Time Machine"
		body = "⏰ Go back in time and change your past!\n\n✨ Undo mistakes!\n✨ Try different life paths!\n✨ Unlimited rewinds!\n\n🎮 Get the Time Machine gamepass!"
	end
	
	-- Show the popup
	self.remotes.ShowResult:FireClient(player, {
		emoji = emoji,
		title = title,
		body = body,
		isPositive = true,
	})
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: Clear conflicting premium states to prevent "Mobster Prince" bug
-- When a player enters one premium path, clear flags from other paths
-- Also clears conflicting housing when becoming royalty
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:clearConflictingPremiumStates(state, newPath)
	if not state then return end
	state.Flags = state.Flags or {}
	
	if newPath == "royalty" then
		-- Clear mafia state
		state.Flags.in_mob = nil
		state.Flags.mafia_member = nil
		state.Flags.chose_mafia_path = nil
		state.Flags.joined_mob = nil
		if state.MobState then
			state.MobState = nil
		end
		-- Clear celebrity state (unless they're famous through royalty)
		if not state.Flags.royal_fame then
			state.Flags.fame_career = nil
			state.Flags.chose_celebrity_path = nil
		end
		-- CRITICAL FIX: Clear old housing when becoming royalty (they move to palace!)
		state.Flags.renting = nil
		state.Flags.has_apartment = nil
		state.Flags.has_own_place = nil
		state.Flags.homeless = nil
		state.Flags.living_with_parents = nil
		-- Update housing state
		state.HousingState = state.HousingState or {}
		state.HousingState.status = "royal_palace"
		state.HousingState.type = "palace"
		state.HousingState.rent = 0
		-- Clear old apartment from Assets
		if state.Assets and state.Assets.Properties then
			local newProperties = {}
			for _, prop in ipairs(state.Assets.Properties) do
				-- Keep only non-rental properties
				if not (prop.id and (prop.id:find("apartment") or prop.id:find("residence") or prop.id == "current_residence")) then
					table.insert(newProperties, prop)
				end
			end
			state.Assets.Properties = newProperties
		end
	elseif newPath == "mafia" then
		-- Clear royalty state
		state.Flags.is_royalty = nil
		state.Flags.royal_birth = nil
		state.Flags.dating_royalty = nil
		state.Flags.royal_romance = nil
		state.Flags.chose_royalty_path = nil
		state.Flags.royal_by_marriage = nil
		if state.RoyalState then
			state.RoyalState = nil
		end
		-- Clear celebrity state
		state.Flags.fame_career = nil
		state.Flags.chose_celebrity_path = nil
	elseif newPath == "celebrity" then
		-- Clear mafia state
		state.Flags.in_mob = nil
		state.Flags.mafia_member = nil
		state.Flags.chose_mafia_path = nil
		state.Flags.joined_mob = nil
		if state.MobState then
			state.MobState = nil
		end
		-- Clear royalty state
		state.Flags.is_royalty = nil
		state.Flags.royal_birth = nil
		state.Flags.dating_royalty = nil
		state.Flags.royal_romance = nil
		state.Flags.chose_royalty_path = nil
		state.Flags.royal_by_marriage = nil
		if state.RoyalState then
			state.RoyalState = nil
		end
	end
	
	-- Update primary_wish_type to ensure consistency
	state.Flags.primary_wish_type = newPath
	
	print("[LifeBackend] Cleared conflicting premium states, new path:", newPath)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: Comprehensive state consistency validator
-- Runs on every state sync to catch and fix any inconsistent states
-- Prevents: multiple paths active, conflicting relationship states, ghost flags
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:validateStateConsistency(state)
	if not state then return end
	state.Flags = state.Flags or {}
	local flags = state.Flags
	local age = state.Age or 0
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FIX #1: PREMIUM PATH MUTEX - Only ONE premium path can be active
	-- ═══════════════════════════════════════════════════════════════════════
	local isRoyalty = flags.is_royalty or flags.royal_birth or (state.RoyalState and state.RoyalState.isRoyal)
	local isInMob = flags.in_mob or (state.MobState and state.MobState.inMob)
	local isFamous = flags.is_famous or flags.fame_career or (state.FameState and state.FameState.careerPath)
	
	local activePaths = 0
	if isRoyalty then activePaths = activePaths + 1 end
	if isInMob then activePaths = activePaths + 1 end
	if isFamous then activePaths = activePaths + 1 end
	
	-- If multiple paths are active, use primary_wish_type to determine which to keep
	if activePaths > 1 then
		warn("[StateValidator] CONFLICT: Multiple premium paths active! Resolving based on primary_wish_type")
		local primaryWish = flags.primary_wish_type
		
		if primaryWish == "royalty" then
			-- Keep royalty, clear others
			self:clearConflictingPremiumStates(state, "royalty")
		elseif primaryWish == "mafia" then
			-- Keep mafia, clear others
			self:clearConflictingPremiumStates(state, "mafia")
		elseif primaryWish == "celebrity" then
			-- Keep celebrity, clear others
			self:clearConflictingPremiumStates(state, "celebrity")
		else
			-- No primary wish set - use priority: royalty > mafia > celebrity
			if isRoyalty then
				self:clearConflictingPremiumStates(state, "royalty")
			elseif isInMob then
				self:clearConflictingPremiumStates(state, "mafia")
			else
				self:clearConflictingPremiumStates(state, "celebrity")
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FIX #2: RELATIONSHIP STATE MUTEX - Cannot be married+single+engaged+widowed
	-- ═══════════════════════════════════════════════════════════════════════
	local married = flags.married
	local engaged = flags.engaged
	local single = flags.single
	local widowed = flags.widowed
	local hasPartner = flags.has_partner
	
	-- Priority: married > engaged > dating > single/widowed
	if married then
		flags.engaged = nil
		flags.single = nil
		-- Keep widowed if it applies to a previous marriage
	elseif engaged then
		flags.married = nil
		flags.single = nil
		flags.widowed = nil -- Can't be widowed if engaged to someone new
	elseif hasPartner or flags.dating_royalty or flags.royal_romance then
		flags.single = nil
		flags.married = nil
		flags.engaged = nil
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FIX #3: FINANCIAL FLAG CLEANUP - Clear broke flags if player has money
	-- ═══════════════════════════════════════════════════════════════════════
	local money = state.Money or 0
	if money >= 10000 then
		flags.struggling_financially = nil
		flags.broke = nil
		flags.poor = nil
		flags.is_broke = nil
		-- Also reset years broke counter
		if state.HousingState then
			state.HousingState.yearsWithoutPayingRent = 0
			state.HousingState.yearsBroke = nil
		end
	elseif money < 100 and age >= 18 then
		-- CRITICAL FIX #912: Player is BROKE - prompt money boost!
		-- This is a HIGH CONVERSION moment - they need money!
		flags.broke = true
		flags.struggling_financially = true
		-- Note: Actual prompt happens in advanceYear to avoid spam
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FIX #4: INHERITANCE AGE GATE - Children can't receive direct inheritance
	-- ═══════════════════════════════════════════════════════════════════════
	if age < 18 and money > 500000 then
		-- Excessive money for a child - it should be in a trust
		flags.has_trust_fund = true
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FIX #5: DEATH STATE - Cannot be dead and alive simultaneously
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.dead or flags.is_dead then
		flags.is_alive = nil
		-- Don't allow age ups if dead
		state.canAgeUp = false
	else
		flags.is_alive = true
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FIX #6: JAIL STATE CONSISTENCY
	-- ═══════════════════════════════════════════════════════════════════════
	if state.InJail then
		flags.in_prison = true
		flags.incarcerated = true
	else
		if (state.JailYearsLeft or 0) <= 0 then
			flags.in_prison = nil
			flags.incarcerated = nil
			state.InJail = false
			state.JailYearsLeft = 0
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FIX #7: CLEANUP DEAD FAMILY MEMBERS from active relationships
	-- ═══════════════════════════════════════════════════════════════════════
	if state.Relationships then
		for relId, rel in pairs(state.Relationships) do
			if type(rel) == "table" then
				-- If they're marked deceased, ensure they can't be interacted with romantically
				if rel.deceased or rel.dead then
					rel.alive = false
					-- Clear active romantic status if partner is dead
					if relId == "partner" and not flags.widowed then
						flags.widowed = true
						flags.has_partner = nil
						flags.dating = nil
					end
				end
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FIX #8: FAME STATE VALIDATION - Can't be famous without proper setup
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.is_famous then
		-- Ensure FameState exists
		state.FameState = state.FameState or {}
		if not state.FameState.careerPath and not state.FameState.currentStage then
			-- Ghost fame flag - clear it
			warn("[StateValidator] Ghost fame flag detected - clearing")
			flags.is_famous = nil
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FIX #9: PALACE/HOUSING VALIDATION - Palace requires royalty
	-- ═══════════════════════════════════════════════════════════════════════
	if state.HousingState and state.HousingState.status == "royal_palace" then
		if not isRoyalty and not flags.is_royalty then
			warn("[StateValidator] Ghost palace status detected - resetting to with_parents")
			state.HousingState.status = "with_parents"
			state.HousingState.type = "family_home"
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FIX #10: GODMODE PROMPT TRACKING - Prevent spam
	-- ═══════════════════════════════════════════════════════════════════════
	-- Reset god_mode_offer_count if it's getting too high
	if (flags.god_mode_offer_count or 0) > 5 then
		flags.god_mode_offer_count = 0
	end
	
	print("[StateValidator] Consistency check complete")
end

-- ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
-- RECURSIVE VALIDATOR SYSTEM (RVS) - DEEP STRUCTURAL REPAIR
-- This system performs comprehensive validation across ALL game systems:
-- - Premium path integrity (flags match actual state and event history)
-- - Event chain completion (incomplete chains are detected and resolved)
-- - Ghost entity cleanup (dead relatives, duplicate assets, orphan flags)
-- - Housing/title synchronization
-- - Occupation history cleanup
-- - Fame/royalty/mafia path validation
-- ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
-- ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- AAA FIX: RATE-LIMITED INTEGRITY CHECKS
-- Only run full validation:
-- - On load
-- - After major actions (marriage, time machine, prison release, purchase)
-- - On save
-- NOT every tick / every remote
-- ═══════════════════════════════════════════════════════════════════════════════
local RVS_MIN_INTERVAL = 30 -- Minimum seconds between full RVS runs
local RVS_FORCE_INTERVAL = 300 -- Force RVS after 5 minutes regardless

-- Master recursive validator function - runs all sub-validators
-- Now with rate-limiting to prevent performance issues
function LifeBackend:validateRecursiveState(state, forceRun)
	if not state then return 0 end
	
	-- Rate limiting check
	state.Flags = state.Flags or {}
	local currentTime = os.time()
	local lastCheck = state.Flags._last_rvs_check or 0
	local timeSinceLastCheck = currentTime - lastCheck
	
	-- Skip if checked recently (unless forced)
	if not forceRun and timeSinceLastCheck < RVS_MIN_INTERVAL then
		-- Quick sanity checks only (no full validation)
		return self:quickSanityCheck(state)
	end
	
	-- Update last check time
	state.Flags._last_rvs_check = currentTime
	
	-- Reduce log spam - only print on major validation events
	local shouldLog = forceRun or timeSinceLastCheck > RVS_FORCE_INTERVAL
	if shouldLog then
		print("[RVS] ═══════════════════════════════════════════════════════════════")
		print("[RVS] Starting Recursive Validator System...")
		print("[RVS] ═══════════════════════════════════════════════════════════════")
	end
	
	local fixes = 0
	
	-- Run all validators in order
	fixes = fixes + self:validatePremiumFlags(state)
	fixes = fixes + self:validateEventChains(state)
	fixes = fixes + self:reconcileEventChains(state)    -- Event chain recovery
	fixes = fixes + self:clearGhostRelationships(state)
	fixes = fixes + self:syncHousingAndTitles(state)
	fixes = fixes + self:enforceOneOccupation(state)
	fixes = fixes + self:validateFameState(state)
	fixes = fixes + self:validateRoyalMarriage(state)
	fixes = fixes + self:cleanDuplicateAssets(state)
	fixes = fixes + self:validateChildState(state)
	fixes = fixes + self:validateMilestones(state)       -- Milestone validation
	fixes = fixes + self:validateEducationSystem(state)  -- AAA: Education validation
	fixes = fixes + self:validateAssetOwnership(state)   -- AAA: Asset sync
	fixes = fixes + self:validatePrisonState(state)      -- AAA: Prison sync
	
	if shouldLog or fixes > 0 then
		print(string.format("[RVS] Validation complete. Total fixes applied: %d", fixes))
		print("[RVS] ═══════════════════════════════════════════════════════════════")
	end
	
	return fixes
end

-- Quick sanity check for when we skip full RVS
-- Only checks for truly broken states that cause immediate crashes
function LifeBackend:quickSanityCheck(state)
	if not state then return 0 end
	local fixes = 0
	
	-- Ensure critical tables exist
	state.Flags = state.Flags or {}
	state.Stats = state.Stats or { Health = 50, Happiness = 50, Smarts = 50, Looks = 50 }
	state.Relationships = state.Relationships or {}
	state.Assets = state.Assets or {}
	state.EducationData = state.EducationData or {}
	state.CareerInfo = state.CareerInfo or {}
	state.EventHistory = state.EventHistory or {}
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- AAA FIX: Comprehensive stat type validation
	-- Prevents arithmetic errors from boolean/string stats
	-- ═══════════════════════════════════════════════════════════════════════
	local function validateStat(val, default)
		if type(val) == "number" then
			return math.max(0, math.min(100, val))
		elseif type(val) == "boolean" then
			return val and 75 or 25
		elseif type(val) == "string" then
			return tonumber(val) or default
		end
		return default
	end
	
	-- Ensure Stats are all valid numbers in 0-100 range
	state.Stats.Health = validateStat(state.Stats.Health, 50)
	state.Stats.Happiness = validateStat(state.Stats.Happiness, 50)
	state.Stats.Smarts = validateStat(state.Stats.Smarts, 50)
	state.Stats.Looks = validateStat(state.Stats.Looks, 50)
	
	-- Sync stat shortcuts (ALWAYS keep in sync)
	state.Health = state.Stats.Health
	state.Happiness = state.Stats.Happiness
	state.Smarts = state.Stats.Smarts
	state.Looks = state.Stats.Looks
	
	-- Ensure Money is valid number (not boolean!)
	if type(state.Money) ~= "number" then
		if type(state.Money) == "boolean" then
			state.Money = state.Money and 1000 or 0
		elseif type(state.Money) == "string" then
			state.Money = tonumber(state.Money) or 0
		else
			state.Money = 0
		end
		fixes = fixes + 1
	end
	
	-- Ensure Money is not negative (unless debt is allowed in special cases)
	if state.Money < -1000000 then
		state.Money = -1000000 -- Cap at -1M (max debt)
		fixes = fixes + 1
	end
	
	-- Ensure Age is valid
	if type(state.Age) ~= "number" or state.Age < 0 then
		state.Age = 0
		fixes = fixes + 1
	end
	if state.Age > 120 then
		state.Age = 120 -- Cap at 120 years old
		fixes = fixes + 1
	end
	
	-- Ensure Year is valid
	if type(state.Year) ~= "number" then
		state.Year = 2025
		fixes = fixes + 1
	end
	
	-- AAA FIX: Fame level should be 0-100
	if state.Fame then
		if type(state.Fame) ~= "number" then
			state.Fame = 0
			fixes = fixes + 1
		else
			state.Fame = math.max(0, math.min(100, state.Fame))
		end
	end
	
	-- AAA FIX: JailYearsLeft can't be negative
	if state.JailYearsLeft and state.JailYearsLeft < 0 then
		state.JailYearsLeft = 0
		state.InJail = false
		fixes = fixes + 1
	end
	
	-- AAA FIX: Sync InJail with JailYearsLeft
	if state.InJail and (not state.JailYearsLeft or state.JailYearsLeft <= 0) then
		state.InJail = false
		state.JailYearsLeft = 0
		state.Flags.in_prison = nil
		state.Flags.incarcerated = nil
		fixes = fixes + 1
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- PREMIUM FLAGS VALIDATOR
-- Checks if premium flags (is_royalty, in_mob, is_famous) have valid backing
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:validatePremiumFlags(state)
	local fixes = 0
	local flags = state.Flags or {}
	local history = state.EventHistory or {}
	local completedEvents = history.completed or {}
	local occurrences = history.occurrences or {}
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- ROYALTY FLAG VALIDATION
	-- is_royalty should only be true if:
	-- 1. Player was born royal (royal_birth flag)
	-- 2. Player married royalty (married + married_to_royalty flags)
	-- 3. Player has valid RoyalState
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.is_royalty then
		local hasValidRoyalSource = false
		
		-- Check: Born royal
		if flags.royal_birth then
			hasValidRoyalSource = true
		end
		
		-- Check: Married into royalty
		if flags.married and flags.married_to_royalty then
			hasValidRoyalSource = true
		end
		
		-- Check: Valid RoyalState
		if state.RoyalState and state.RoyalState.isRoyal then
			hasValidRoyalSource = true
		end
		
		-- Check: Dating royalty (engaged, not married yet) - NOT full royalty
		if flags.dating_royalty and not flags.married_to_royalty then
			hasValidRoyalSource = false -- Dating ≠ Being royalty
			if not flags.married_to_royalty then
				warn("[RVS] Ghost royalty flag: is_royalty without marriage - clearing")
				flags.is_royalty = nil
				flags.royal_by_marriage = nil
				if state.RoyalState then
					state.RoyalState.isRoyal = false
				end
				fixes = fixes + 1
			end
		end
		
		if not hasValidRoyalSource then
			warn("[RVS] Ghost royalty flag: No valid royal source - clearing")
			flags.is_royalty = nil
			flags.royal_birth = nil
			flags.royal_by_marriage = nil
			if state.RoyalState then
				state.RoyalState = nil
			end
			-- Reset housing if it was set to palace
			if state.HousingState and state.HousingState.status == "royal_palace" then
				state.HousingState.status = "with_parents"
				state.HousingState.type = "family_home"
			end
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- MAFIA FLAG VALIDATION
	-- in_mob should only be true if:
	-- 1. Player has valid MobState with inMob = true
	-- 2. Player completed a mob joining event
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.in_mob then
		local hasValidMobSource = false
		
		-- Check: Valid MobState
		if state.MobState and state.MobState.inMob then
			hasValidMobSource = true
		end
		
		-- Check: Completed mob event
		local mobEventCompleted = completedEvents["premium_wish_mafia_approach"] or
			completedEvents["mafia_recruitment"] or
			completedEvents["mafia_approach"] or
			(occurrences["premium_wish_mafia_approach"] or 0) > 0
		
		if mobEventCompleted then
			hasValidMobSource = true
		end
		
		if not hasValidMobSource then
			warn("[RVS] Ghost mafia flag: No valid mob source - clearing")
			flags.in_mob = nil
			flags.mafia_member = nil
			state.MobState = nil
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FAME FLAG VALIDATION
	-- is_famous should only be true if:
	-- 1. Player has valid FameState with careerPath
	-- 2. Player has fame level >= 50
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.is_famous or flags.fame_career then
		local hasValidFameSource = false
		
		-- Check: Valid FameState with career
		if state.FameState and state.FameState.careerPath then
			hasValidFameSource = true
		end
		
		-- Check: High fame level
		if (state.Fame or 0) >= 50 then
			hasValidFameSource = true
		end
		
		-- Check: Completed fame event
		local fameEventCompleted = completedEvents["premium_wish_fame_discovery"] or
			completedEvents["celebrity_discovery"] or
			(occurrences["premium_wish_fame_discovery"] or 0) > 0
		
		if fameEventCompleted then
			hasValidFameSource = true
		end
		
		if not hasValidFameSource then
			warn("[RVS] Ghost fame flag: No valid fame source - clearing")
			flags.is_famous = nil
			flags.fame_career = nil
			flags.celebrity = nil
			if state.FameState then
				state.FameState.careerPath = nil
			end
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- PRIMARY WISH TYPE VALIDATION
	-- Ensure primary_wish_type matches actual state
	-- ═══════════════════════════════════════════════════════════════════════
	local primaryWish = flags.primary_wish_type
	if primaryWish then
		local wishMatchesState = false
		
		if primaryWish == "royalty" then
			wishMatchesState = flags.is_royalty or flags.dating_royalty or flags.palace_wish
		elseif primaryWish == "mafia" then
			wishMatchesState = flags.in_mob or flags.power_wish
		elseif primaryWish == "celebrity" then
			wishMatchesState = flags.is_famous or flags.fame_career or flags.fame_wish
		end
		
		-- If wish exists but no progression, check if they should still have events trigger
		if not wishMatchesState then
			-- Keep the wish - player may still be waiting for follow-up event
			-- But clear if they're too old for wish events
			local age = state.Age or 0
			if age > 40 then
				warn("[RVS] Primary wish expired: Player too old for wish events - clearing")
				flags.primary_wish_type = nil
				fixes = fixes + 1
			end
		end
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT CHAIN VALIDATOR
-- Detects incomplete event chains and resolves them
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:validateEventChains(state)
	local fixes = 0
	local flags = state.Flags or {}
	local history = state.EventHistory or {}
	local occurrences = history.occurrences or {}
	local age = state.Age or 0
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- ROYAL ROMANCE CHAIN VALIDATION
	-- If dating_royalty is true but no proposal happened after 5+ years
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.dating_royalty and not flags.married_to_royalty then
		local datingYears = flags.dating_royalty_years or 0
		
		-- If dating for 10+ years without proposal, relationship ended
		if datingYears >= 10 then
			warn("[RVS] Royal romance stale: 10+ years without marriage - ending relationship")
			flags.dating_royalty = nil
			flags.royal_romance = nil
			flags.has_partner = nil
			flags.dating_royalty_years = nil
			-- Clear the royal partner
			if state.Relationships and state.Relationships.partner then
				-- AAA FIX: Nil safety check
				local partner = state.Relationships.partner
				if type(partner) == "table" and partner.isRoyalty then
					state.Relationships.partner = nil
				end
			end
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- WISH FULFILLMENT CHAIN VALIDATION
	-- If wish was made but follow-up never happened
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.palace_wish and not flags.dating_royalty and not flags.is_royalty then
		-- Check if encounter event was completed
		local encounterOccurred = (occurrences["premium_wish_royalty_encounter"] or 0) > 0
		
		if not encounterOccurred and age > 35 then
			warn("[RVS] Royal wish expired: Never encountered royalty by age 35 - clearing wish")
			flags.palace_wish = nil
			flags.royal_fantasies = nil
			if flags.primary_wish_type == "royalty" then
				flags.primary_wish_type = nil
			end
			fixes = fixes + 1
		end
	end
	
	if flags.power_wish and not flags.in_mob then
		local approachOccurred = (occurrences["premium_wish_mafia_approach"] or 0) > 0
		
		if not approachOccurred and age > 35 then
			warn("[RVS] Mafia wish expired: Never approached by age 35 - clearing wish")
			flags.power_wish = nil
			flags.fascinated_by_power = nil
			if flags.primary_wish_type == "mafia" then
				flags.primary_wish_type = nil
			end
			fixes = fixes + 1
		end
	end
	
	if flags.fame_wish and not flags.is_famous and not flags.fame_career then
		local discoveryOccurred = (occurrences["premium_wish_fame_discovery"] or 0) > 0
		
		if not discoveryOccurred and age > 35 then
			warn("[RVS] Fame wish expired: Never discovered by age 35 - clearing wish")
			flags.fame_wish = nil
			flags.star_dreams = nil
			if flags.primary_wish_type == "celebrity" then
				flags.primary_wish_type = nil
			end
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- ENGAGEMENT WITHOUT MARRIAGE VALIDATION
	-- If engaged but never married after 3+ years
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.engaged and not flags.married then
		local engagedAge = flags.engaged_at_age or (age - 3)
		local yearsEngaged = age - engagedAge
		
		if yearsEngaged >= 5 then
			warn("[RVS] Stale engagement: 5+ years engaged without marriage - ending")
			flags.engaged = nil
			flags.engaged_at_age = nil
			fixes = fixes + 1
		end
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- GHOST RELATIONSHIP CLEANER
-- Removes dead, orphaned, or invalid relationship entries
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:clearGhostRelationships(state)
	local fixes = 0
	local flags = state.Flags or {}
	
	if not state.Relationships then return fixes end
	
	local validRelationships = {}
	local hasLivingPartner = false
	local hasLivingSpouse = false
	
	for relId, rel in pairs(state.Relationships) do
		if type(rel) == "table" then
			local isValid = true
			local reason = nil
			
			-- ═══════════════════════════════════════════════════════════
			-- Check for ghost entries
			-- ═══════════════════════════════════════════════════════════
			
			-- Ghost: Dead but marked alive
			if (rel.deceased or rel.dead) and rel.alive then
				rel.alive = false
				fixes = fixes + 1
			end
			
			-- Ghost: No name or ID
			if not rel.name and not rel.id then
				isValid = false
				reason = "No identifier"
			end
			
			-- Ghost: Impossible age (negative or very old for a child)
			if rel.age and rel.age < -5 then
				isValid = false
				reason = "Impossible age"
			end
			
			-- Ghost: Child marked as spouse
			if rel.Type == "Child" and (rel.role == "Spouse" or rel.role == "Partner") then
				rel.role = nil
				fixes = fixes + 1
			end
			
			-- AAA FIX: Validate relationship score is a number
			if rel.relationship and type(rel.relationship) ~= "number" then
				if type(rel.relationship) == "boolean" then
					rel.relationship = rel.relationship and 75 or 25
				else
					rel.relationship = 50
				end
				fixes = fixes + 1
			end
			
			-- AAA FIX: Bound relationship to 0-100
			if rel.relationship and type(rel.relationship) == "number" then
				rel.relationship = math.max(0, math.min(100, rel.relationship))
			elseif not rel.relationship then
				rel.relationship = 50 -- Default relationship value
			end
			
			-- AAA FIX: Validate yearsKnown
			if rel.yearsKnown and rel.yearsKnown < 0 then
				rel.yearsKnown = 0
				fixes = fixes + 1
			end
			
			-- AAA FIX: Dead relationships should be in deceased_partners if romantic
			if (rel.deceased or rel.dead) then
				if rel.Type == "Spouse" or rel.Type == "Partner" or rel.role == "Spouse" or rel.role == "Partner" or relId == "spouse" or relId == "partner" then
					-- Move to deceased partners collection
					state.DeceasedPartners = state.DeceasedPartners or {}
					if not state.DeceasedPartners[rel.name or relId] then
						state.DeceasedPartners[rel.name or relId] = {
							name = rel.name,
							diedAt = rel.diedAt or (state.Age or 0),
							relationship = rel.relationship or 50,
							wasSpouse = (rel.role == "Spouse" or rel.Type == "Spouse" or relId == "spouse"),
						}
						-- Set widowed if was spouse
						if rel.role == "Spouse" or rel.Type == "Spouse" or relId == "spouse" then
							flags.widowed = true
						end
					end
					-- Remove from active relationships
					isValid = false
					reason = "Moved to deceased partners"
				end
			end
			
			-- Track living romantic partners
			if rel.alive ~= false and not rel.deceased and not rel.dead then
				if relId == "partner" or rel.Type == "Partner" then
					hasLivingPartner = true
				end
				if relId == "spouse" or rel.Type == "Spouse" or rel.role == "Spouse" then
					hasLivingSpouse = true
				end
			end
			
			if isValid then
				validRelationships[relId] = rel
			else
				-- Only log if it's an unusual removal (not just deceased partner migration)
				if reason ~= "Moved to deceased partners" then
					-- Debug only, no warn spam
					-- print(string.format("[RVS] Removing ghost relationship: %s (%s)", tostring(relId), reason))
				end
				fixes = fixes + 1
			end
		else
			-- Invalid entry (not a table)
			fixes = fixes + 1
		end
	end
	
	state.Relationships = validRelationships
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Sync flags with actual relationships
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.has_partner and not hasLivingPartner then
		-- Only log once per session to reduce spam
		if not flags._ghost_partner_logged then
			print("[RVS] Ghost has_partner flag - clearing (will only log once)")
			flags._ghost_partner_logged = true
		end
		flags.has_partner = nil
		fixes = fixes + 1
	end
	
	if flags.married and not hasLivingSpouse then
		-- Check if widowed
		if not flags.widowed then
			-- Only log once per session to reduce spam
			if not flags._ghost_married_logged then
				print("[RVS] Ghost married flag without spouse - setting widowed (will only log once)")
				flags._ghost_married_logged = true
			end
			flags.widowed = true
			flags.married = nil
			fixes = fixes + 1
		end
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- HOUSING AND TITLES SYNCHRONIZATION
-- Ensures housing status matches player's actual status
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:syncHousingAndTitles(state)
	local fixes = 0
	local flags = state.Flags or {}
	
	state.HousingState = state.HousingState or {}
	local housing = state.HousingState
	local age = state.Age or 0
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Royal Palace requires actual royalty
	-- ═══════════════════════════════════════════════════════════════════════
	if housing.status == "royal_palace" then
		local isActuallyRoyal = flags.is_royalty or flags.royal_birth or
			(state.RoyalState and state.RoyalState.isRoyal)
		
		if not isActuallyRoyal then
			warn("[RVS] Ghost palace: Not actually royal - resetting housing")
			housing.status = age < 18 and "with_parents" or "renter"
			housing.type = age < 18 and "family_home" or "apartment"
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Homeless validation
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.homeless then
		-- Can't be homeless with money - but lower threshold to $5k (realistic)
		if (state.Money or 0) >= 5000 then
			-- Don't warn every time, only fix silently
			flags.homeless = nil
			housing.status = "renter"
			housing.type = "apartment"
			housing.rent = math.min(1200, math.floor((state.Money or 0) * 0.2))
			fixes = fixes + 1
		end
		
		-- Can't be homeless and own property
		local hasProperties = state.Assets and state.Assets.Properties and #state.Assets.Properties > 0
		if flags.homeowner or flags.has_property or hasProperties then
			flags.homeless = nil
			housing.status = "owner"
			housing.type = state.Assets and state.Assets.Properties and state.Assets.Properties[1] and 
				state.Assets.Properties[1].type or "house"
			housing.rent = 0
			fixes = fixes + 1
		end
		
		-- Can't be homeless if living in car
		local hasVehicles = state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0
		if hasVehicles and housing.status == "homeless" then
			housing.status = "living_in_car"
			housing.type = "vehicle"
			housing.rent = 0
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- AAA FIX: Sync housing with owned properties
	-- CRITICAL FIX: Also clear ALL transitional/homeless flags when owning property
	-- User complaint: "Housing doesn't update when I buy a house"
	-- ═══════════════════════════════════════════════════════════════════════
	if state.Assets and state.Assets.Properties and #state.Assets.Properties > 0 then
		local primaryHome = state.Assets.Properties[1]
		if housing.status ~= "owner" and housing.status ~= "royal_palace" then
			housing.status = "owner"
			housing.type = primaryHome.type or primaryHome.name or "house"
			housing.propertyId = primaryHome.id
			housing.value = primaryHome.value or primaryHome.price
			housing.rent = 0
			flags.homeowner = true
			flags.has_property = true
			flags.has_home = true
			flags.has_own_place = true
			-- CRITICAL: Clear ALL housing flags that shouldn't exist with property ownership
			flags.homeless = nil
			flags.couch_surfing = nil
			flags.living_in_car = nil
			flags.using_shelter = nil
			flags.in_transitional_housing = nil
			flags.at_risk_homeless = nil
			flags.eviction_notice = nil
			flags.living_with_parents = nil
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Children always live with parents
	-- ═══════════════════════════════════════════════════════════════════════
	if age < 18 and not flags.emancipated then
		if housing.status ~= "with_parents" and housing.status ~= "royal_palace" then
			if not flags.is_royalty then
				housing.status = "with_parents"
				housing.type = "family_home"
				housing.rent = 0
				fixes = fixes + 1
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- RoyalState title validation
	-- ═══════════════════════════════════════════════════════════════════════
	if state.RoyalState and state.RoyalState.isRoyal then
		-- Ensure title is set
		if not state.RoyalState.title then
			state.RoyalState.title = state.Gender == "Female" and "Princess" or "Prince"
			fixes = fixes + 1
		end
		
		-- Married royalty gets consort title
		if flags.married_to_royalty and not flags.royal_birth then
			local expectedTitle = state.Gender == "Female" and "Princess Consort" or "Prince Consort"
			if state.RoyalState.title ~= expectedTitle then
				state.RoyalState.title = expectedTitle
				fixes = fixes + 1
			end
		end
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- OCCUPATION ENFORCER
-- Ensures only ONE occupation is active and clears conflicting job histories
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:enforceOneOccupation(state)
	local fixes = 0
	local flags = state.Flags or {}
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Royalty can't have regular jobs
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.is_royalty or (state.RoyalState and state.RoyalState.isRoyal) then
		if state.CurrentJob then
			warn("[RVS] Royalty with regular job - clearing job")
			-- Store as previous career
			flags.previous_career = state.CurrentJob.title or state.CurrentJob.name
			state.CurrentJob = nil
			flags.employed = nil
			flags.has_job = nil
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Clear conflicting career flags
	-- ═══════════════════════════════════════════════════════════════════════
	local activeCareerTypes = {}
	
	if flags.is_royalty then table.insert(activeCareerTypes, "royalty") end
	if flags.in_mob then table.insert(activeCareerTypes, "mafia") end
	if flags.fame_career then table.insert(activeCareerTypes, "fame") end
	if state.CurrentJob then table.insert(activeCareerTypes, "regular") end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- AAA FIX: Multiple career types are VALID in many cases:
	-- - Mafia + regular job = cover job (realistic)
	-- - Fame + regular job = working artist/struggling artist (realistic)
	-- - Royalty + fame = Prince Harry style (realistic)
	-- Only fix truly incompatible combinations, NO logging for valid combinations
	-- ═══════════════════════════════════════════════════════════════════════════════
	if #activeCareerTypes > 1 then
		local primary = flags.primary_wish_type
		local needsFix = false
		
		-- Royalty is EXCLUSIVE of regular jobs (they don't work normal jobs)
		if (primary == "royalty" or flags.is_royalty) and state.CurrentJob then
			state.CurrentJob = nil
			flags.employed = nil
			flags.has_job = nil
			needsFix = true
			fixes = fixes + 1
		end
		
		-- All other combinations are VALID - no warnings, no fixes needed:
		-- - Fame + regular job = struggling artist with day job (VALID)
		-- - Mafia + regular job = cover job for criminal activities (VALID)
		-- - Fame + mafia = celebrity criminal (VALID if rare)
		
		-- REMOVED: Logging completely - these combinations are valid game states
		-- The old "[RVS] Multiple career types detected" warning was spam
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Clear impossible job states
	-- ═══════════════════════════════════════════════════════════════════════
	if state.CurrentJob then
		local age = state.Age or 0
		
		-- Can't have a job if too young
		if age < 14 then
			-- Only log once per session to reduce spam
			if not flags._child_job_cleared then
				print("[RVS] Child with job - clearing (will only log once)")
				flags._child_job_cleared = true
			end
			state.CurrentJob = nil
			flags.employed = nil
			flags.has_job = nil
			fixes = fixes + 1
		end
		
		-- Can't work in prison
		if state.InJail then
			if not state.CurrentJob.isPrisonJob then
				warn("[RVS] Employed while in prison - clearing job")
				flags.was_employed_before_jail = true
				flags.previous_job_id = state.CurrentJob.id
				state.CurrentJob = nil
				flags.employed = nil
				fixes = fixes + 1
			end
		end
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- FAME STATE VALIDATOR
-- Ensures fame status has valid backing
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:validateFameState(state)
	local fixes = 0
	local flags = state.Flags or {}
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FameState exists but no career path - ghost state
	-- ═══════════════════════════════════════════════════════════════════════
	if state.FameState then
		local fameState = state.FameState
		
		-- Must have career path to have subscribers/followers
		if not fameState.careerPath then
			if (fameState.subscribers or 0) > 0 or (fameState.followers or 0) > 0 then
				-- Ghost fame state - clear silently (no warn spam)
				state.FameState = nil
				flags.is_famous = nil
				flags.fame_career = nil
				flags.celebrity = nil
				fixes = fixes + 1
			end
		end
		
		-- Current stage can't be 0 or negative
		if fameState.currentStage and fameState.currentStage <= 0 then
			fameState.currentStage = 1
			fixes = fixes + 1
		end
		
		-- AAA FIX: Validate followers/subscribers are numbers, not booleans
		if type(fameState.subscribers) == "boolean" then
			fameState.subscribers = fameState.subscribers and 100 or 0
			fixes = fixes + 1
		end
		if type(fameState.followers) == "boolean" then
			fameState.followers = fameState.followers and 100 or 0
			fixes = fixes + 1
		end
		
		-- AAA FIX: Ensure fame level is bounded
		if fameState.level then
			fameState.level = math.max(0, math.min(100, fameState.level or 0))
		end
		
		-- AAA FIX: monthlyIncome should be a number
		if type(fameState.monthlyIncome) == "boolean" then
			fameState.monthlyIncome = 0
			fixes = fixes + 1
		end
		
		-- AAA FIX: Calculate estimated income if missing
		if not fameState.monthlyIncome and fameState.careerPath then
			local subs = fameState.subscribers or 0
			local followers = fameState.followers or 0
			local totalAudience = subs + followers
			-- Rough estimate: $1 per 1000 audience per month
			fameState.monthlyIncome = math.floor(totalAudience / 1000)
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Fame flags without FameState
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.fame_career and not state.FameState then
		-- Don't warn, just fix silently
		flags.fame_career = nil
		fixes = fixes + 1
	end
	
	-- AAA FIX: is_famous without any fame backing
	if flags.is_famous then
		local hasFameBacking = state.FameState or 
			(state.Fame and state.Fame >= 50) or
			flags.fame_career or flags.celebrity or flags.movie_star or flags.pop_star
		if not hasFameBacking then
			flags.is_famous = nil
			fixes = fixes + 1
		end
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- ROYAL MARRIAGE VALIDATOR
-- Ensures royal marriage chain completed properly
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:validateRoyalMarriage(state)
	local fixes = 0
	local flags = state.Flags or {}
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- married_to_royalty requires both married and a royal spouse
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.married_to_royalty then
		if not flags.married then
			warn("[RVS] married_to_royalty without married flag - clearing")
			flags.married_to_royalty = nil
			flags.royal_by_marriage = nil
			flags.is_royalty = nil
			fixes = fixes + 1
		end
		
		-- Check for royal spouse
		local hasRoyalSpouse = false
		if state.Relationships then
			for relId, rel in pairs(state.Relationships) do
				if type(rel) == "table" then
					if rel.isRoyalty and (rel.role == "Spouse" or rel.role == "Royal Spouse" or relId == "spouse") then
						hasRoyalSpouse = true
						break
					end
				end
			end
		end
		
		if not hasRoyalSpouse then
			warn("[RVS] married_to_royalty without royal spouse - clearing")
			flags.married_to_royalty = nil
			flags.royal_by_marriage = nil
			-- Don't clear is_royalty if they might be born royal
			if not flags.royal_birth then
				flags.is_royalty = nil
			end
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- dating_royalty requires a royal partner
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.dating_royalty then
		local hasRoyalPartner = false
		-- AAA FIX: Type check partner before accessing properties
		local partner = state.Relationships and state.Relationships.partner
		if partner and type(partner) == "table" and partner.isRoyalty then
			hasRoyalPartner = true
		end
		
		if not hasRoyalPartner then
			flags.dating_royalty = nil
			flags.royal_romance = nil
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- AAA FIX: Validate RoyalState structure
	-- ═══════════════════════════════════════════════════════════════════════
	if state.RoyalState then
		local royal = state.RoyalState
		
		-- Ensure isRoyal matches flag
		if flags.is_royalty and not royal.isRoyal then
			royal.isRoyal = true
			fixes = fixes + 1
		elseif royal.isRoyal and not flags.is_royalty and not flags.royal_birth then
			-- RoyalState says royal but no flag
			flags.is_royalty = true
			fixes = fixes + 1
		end
		
		-- Validate numeric fields
		if type(royal.popularity) == "boolean" then
			royal.popularity = royal.popularity and 75 or 50
			fixes = fixes + 1
		end
		if type(royal.dutiesCompleted) == "boolean" then
			royal.dutiesCompleted = royal.dutiesCompleted and 5 or 0
			fixes = fixes + 1
		end
		if type(royal.scandals) == "boolean" then
			royal.scandals = royal.scandals and 1 or 0
			fixes = fixes + 1
		end
		
		-- Ensure title exists for royals
		if royal.isRoyal and not royal.title then
			if flags.royal_birth then
				royal.title = state.Gender == "Female" and "Princess" or "Prince"
			elseif flags.married_to_royalty then
				royal.title = state.Gender == "Female" and "Princess Consort" or "Prince Consort"
			else
				royal.title = "Royal"
			end
			fixes = fixes + 1
		end
		
		-- Ensure country exists
		if royal.isRoyal and not royal.country then
			royal.country = "United Kingdom"
			fixes = fixes + 1
		end
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- DUPLICATE ASSET CLEANER
-- Removes duplicate properties, vehicles, items from assets
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:cleanDuplicateAssets(state)
	local fixes = 0
	
	if not state.Assets then return fixes end
	
	local function removeDuplicates(assetList)
		if not assetList then return {}, 0 end
		
		local seen = {}
		local unique = {}
		local dupeCount = 0
		
		for _, asset in ipairs(assetList) do
			local key = asset.id or asset.name or tostring(asset)
			if not seen[key] then
				seen[key] = true
				table.insert(unique, asset)
			else
				dupeCount = dupeCount + 1
			end
		end
		
		return unique, dupeCount
	end
	
	-- Clean Properties
	if state.Assets.Properties then
		local cleaned, dupes = removeDuplicates(state.Assets.Properties)
		if dupes > 0 then
			warn(string.format("[RVS] Removed %d duplicate properties", dupes))
			state.Assets.Properties = cleaned
			fixes = fixes + dupes
		end
	end
	
	-- Clean Vehicles
	if state.Assets.Vehicles then
		local cleaned, dupes = removeDuplicates(state.Assets.Vehicles)
		if dupes > 0 then
			warn(string.format("[RVS] Removed %d duplicate vehicles", dupes))
			state.Assets.Vehicles = cleaned
			fixes = fixes + dupes
		end
	end
	
	-- Clean Items
	if state.Assets.Items then
		local cleaned, dupes = removeDuplicates(state.Assets.Items)
		if dupes > 0 then
			warn(string.format("[RVS] Removed %d duplicate items", dupes))
			state.Assets.Items = cleaned
			fixes = fixes + dupes
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Validate owns_property flag
	-- ═══════════════════════════════════════════════════════════════════════
	local flags = state.Flags or {}
	local hasProperty = state.Assets.Properties and #state.Assets.Properties > 0
	
	if flags.owns_property and not hasProperty then
		warn("[RVS] Ghost owns_property flag - clearing")
		flags.owns_property = nil
		fixes = fixes + 1
	end
	
	if hasProperty and not flags.owns_property then
		flags.owns_property = true
		fixes = fixes + 1
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- CHILD STATE VALIDATOR
-- Ensures children can't have inappropriate flags/states
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:validateChildState(state)
	local fixes = 0
	local flags = state.Flags or {}
	local age = state.Age or 0
	
	-- Children are under 18
	if age < 18 then
		-- ═══════════════════════════════════════════════════════════════════
		-- Children can't be married
		-- ═══════════════════════════════════════════════════════════════════
		if flags.married then
			warn("[RVS] Child married - clearing")
			flags.married = nil
			flags.engaged = nil
			fixes = fixes + 1
		end
		
		-- ═══════════════════════════════════════════════════════════════════
		-- Children can't own houses (property is held in trust)
		-- ═══════════════════════════════════════════════════════════════════
		if flags.homeowner then
			flags.homeowner = nil
			flags.has_trust_fund = true
			fixes = fixes + 1
		end
		
		-- ═══════════════════════════════════════════════════════════════════
		-- Children can't be homeless (wards of state)
		-- ═══════════════════════════════════════════════════════════════════
		if flags.homeless then
			warn("[RVS] Child homeless - placing with foster care")
			flags.homeless = nil
			flags.in_foster_care = true
			state.HousingState = state.HousingState or {}
			state.HousingState.status = "foster_care"
			fixes = fixes + 1
		end
		
		-- ═══════════════════════════════════════════════════════════════════
		-- Children with money should have trust fund flag
		-- ═══════════════════════════════════════════════════════════════════
		if (state.Money or 0) >= 100000 and not flags.has_trust_fund then
			flags.has_trust_fund = true
			fixes = fixes + 1
		end
		
		-- ═══════════════════════════════════════════════════════════════════
		-- Clear broke flags for children (parents support them)
		-- ═══════════════════════════════════════════════════════════════════
		if flags.broke or flags.struggling_financially or flags.is_broke or flags.poor then
			flags.broke = nil
			flags.struggling_financially = nil
			flags.is_broke = nil
			flags.poor = nil
			if state.HousingState then
				state.HousingState.yearsWithoutPayingRent = 0
				state.HousingState.yearsBroke = nil
			end
			fixes = fixes + 1
		end
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT CHAIN RECONCILER
-- Detects incomplete event chains and either retries or force-closes them
-- This prevents ghost states from persisting when follow-up events fail
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:reconcileEventChains(state)
	local fixes = 0
	local flags = state.Flags or {}
	local history = state.EventHistory or {}
	local age = state.Age or 0
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- ROYALTY CHAIN RECONCILIATION
	-- Chain: wish -> encounter -> dating -> proposal -> marriage
	-- ═══════════════════════════════════════════════════════════════════════
	local royalChain = {
		hasWish = flags.palace_wish or flags.royal_fantasies,
		hasEncounter = flags.dating_royalty or flags.royal_romance,
		hasProposal = flags.received_royal_proposal,
		hasMarriage = flags.married_to_royalty or flags.is_royalty,
	}
	
	-- Stuck: Dating but no proposal after many years
	if royalChain.hasEncounter and not royalChain.hasMarriage then
		local datingYears = flags.dating_royalty_years or 0
		
		if datingYears >= 7 and age >= 25 then
			-- Force-inject proposal next year
			flags.force_royal_proposal = true
			print("[EventReconciler] Royal chain stuck: Force-scheduling proposal")
			fixes = fixes + 1
		end
	end
	
	-- Stuck: Has royalty flag but no spouse
	if flags.is_royalty and not flags.royal_birth then
		local hasRoyalSpouse = false
		if state.Relationships then
			for _, rel in pairs(state.Relationships) do
				if type(rel) == "table" and rel.isRoyalty and (rel.role == "Spouse" or rel.role == "Royal Spouse") then
					hasRoyalSpouse = true
					break
				end
			end
		end
		
		if not hasRoyalSpouse and not flags.married_to_royalty then
			-- Ghost royalty - clear it
			warn("[EventReconciler] Ghost royalty state: Married to royalty without spouse - clearing")
			flags.is_royalty = nil
			flags.royal_by_marriage = nil
			if state.RoyalState then
				state.RoyalState.isRoyal = false
			end
			-- Reset housing
			if state.HousingState and state.HousingState.status == "royal_palace" then
				state.HousingState.status = age < 18 and "with_parents" or "renter"
				state.HousingState.type = age < 18 and "family_home" or "apartment"
			end
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- MAFIA CHAIN RECONCILIATION
	-- Chain: wish/approach -> join -> rise ranks
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.in_mob and not state.MobState then
		-- Ghost mob flag without MobState - initialize properly
		state.MobState = {
			inMob = true,
			rank = "Associate",
			rankIndex = 1,
			rankLevel = 1,
			rankName = "Associate",
			rankEmoji = "👤",
			reputation = 10,
			respect = 0,
			loyalty = 100,
			heat = 0,
			territory = 0,
			yearsInMob = 0,
			operationsCompleted = 0,
			operationsThisYear = 0,
			joinedAt = state.Age or 18,
		}
		fixes = fixes + 1
	end
	
	if state.MobState and state.MobState.inMob and not flags.in_mob then
		-- MobState exists but flag missing
		flags.in_mob = true
		flags.mafia_member = true
		fixes = fixes + 1
	end
	
	-- AAA FIX: Validate MobState values are numbers, not booleans
	if state.MobState then
		local mob = state.MobState
		if type(mob.respect) == "boolean" then
			mob.respect = mob.respect and 100 or 0
			fixes = fixes + 1
		end
		if type(mob.loyalty) == "boolean" then
			mob.loyalty = mob.loyalty and 100 or 50
			fixes = fixes + 1
		end
		if type(mob.heat) == "boolean" then
			mob.heat = mob.heat and 50 or 0
			fixes = fixes + 1
		end
		if type(mob.territory) == "boolean" then
			mob.territory = mob.territory and 1 or 0
			fixes = fixes + 1
		end
		-- Ensure rank index is valid
		if mob.rankIndex and type(mob.rankIndex) ~= "number" then
			mob.rankIndex = 1
			fixes = fixes + 1
		elseif mob.rankIndex and (mob.rankIndex < 1 or mob.rankIndex > 5) then
			mob.rankIndex = math.max(1, math.min(5, mob.rankIndex))
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- FAME CHAIN RECONCILIATION
	-- Chain: wish/discovery -> career path -> rise stages
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.fame_career and not state.FameState then
		-- Ghost fame career flag without FameState
		warn("[EventReconciler] Ghost fame flag: fame_career without FameState - clearing")
		flags.fame_career = nil
		flags.is_famous = nil
		fixes = fixes + 1
	end
	
	if state.FameState and state.FameState.careerPath and not flags.fame_career then
		-- FameState exists but flag missing
		flags.fame_career = true
		fixes = fixes + 1
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- PREGNANCY CHAIN RECONCILIATION
	-- Can't be pregnant in prison or if too old
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.pregnant then
		if state.InJail then
			warn("[EventReconciler] Pregnant in prison - clearing")
			flags.pregnant = nil
			fixes = fixes + 1
		end
		if age >= 55 then
			warn("[EventReconciler] Too old for pregnancy - clearing")
			flags.pregnant = nil
			fixes = fixes + 1
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- SCHOOL/EDUCATION CHAIN RECONCILIATION
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.in_college and age < 18 then
		-- Can't be in college under 18 (unless genius/prodigy)
		if not flags.child_prodigy then
			flags.in_college = nil
			flags.in_school = true
			fixes = fixes + 1
		end
	end
	
	if flags.in_school and age >= 18 then
		-- Should have graduated
		if not flags.dropped_out then
			flags.graduated_high_school = true
		end
		flags.in_school = nil
		fixes = fixes + 1
	end
	
	-- AAA FIX: Validate EducationData consistency
	if state.EducationData then
		local edu = state.EducationData
		
		-- Can't be in college with degree
		if edu.inCollege and edu.degreeLevel and edu.degreeLevel ~= "none" then
			-- Already has degree but still flagged as in college
			edu.inCollege = false
			flags.in_college = nil
			flags.graduated_college = true
			fixes = fixes + 1
		end
		
		-- Debt should be a number
		if type(edu.Debt) == "boolean" then
			edu.Debt = edu.Debt and 50000 or 0
			fixes = fixes + 1
		end
		
		-- Years should be bounded
		if edu.yearsCompleted and edu.yearsCompleted < 0 then
			edu.yearsCompleted = 0
			fixes = fixes + 1
		end
		if edu.yearsCompleted and edu.yearsCompleted > 10 then
			-- Can't be in college for 10+ years without graduating or dropping out
			if not edu.degreeLevel then
				edu.droppedOut = true
				edu.inCollege = false
				flags.in_college = nil
				flags.dropped_out_college = true
				fixes = fixes + 1
			end
		end
		
		-- GPA should be bounded 0-4
		if edu.GPA then
			edu.GPA = math.max(0, math.min(4, edu.GPA))
		end
	end
	
	-- AAA FIX: in_college flag sync with EducationData
	if flags.in_college then
		state.EducationData = state.EducationData or {}
		if not state.EducationData.inCollege then
			state.EducationData.inCollege = true
			fixes = fixes + 1
		end
	elseif state.EducationData and state.EducationData.inCollege then
		-- EducationData says in college but flag missing
		flags.in_college = true
		fixes = fixes + 1
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- DEATH/LIFE CHAIN RECONCILIATION
	-- Can't be alive and dead simultaneously
	-- ═══════════════════════════════════════════════════════════════════════
	if flags.dead or flags.is_dead then
		if flags.is_alive then
			flags.is_alive = nil
			fixes = fixes + 1
		end
		-- Dead people can't be pregnant
		if flags.pregnant then
			flags.pregnant = nil
			fixes = fixes + 1
		end
		-- Dead people can't be dating
		if flags.dating or flags.has_partner then
			flags.dating = nil
			fixes = fixes + 1
		end
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- MILESTONE VALIDATOR
-- Ensures milestones are properly marked based on actual achievements
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:validateMilestones(state)
	local fixes = 0
	local flags = state.Flags or {}
	local milestones = state.Milestones or {}
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- "Became Royalty" milestone requires actual royalty
	-- ═══════════════════════════════════════════════════════════════════════
	if milestones["became_royalty"] and not flags.is_royalty and not flags.royal_birth then
		warn("[MilestoneValidator] Ghost royalty milestone - clearing")
		milestones["became_royalty"] = nil
		fixes = fixes + 1
	end
	
	-- Set milestone if missing but achieved
	if (flags.is_royalty or flags.royal_birth) and not milestones["became_royalty"] then
		milestones["became_royalty"] = { age = state.Age, year = os.date("%Y") }
		fixes = fixes + 1
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- "Joined Mafia" milestone requires actual mob membership
	-- ═══════════════════════════════════════════════════════════════════════
	if milestones["joined_mafia"] and not flags.in_mob then
		warn("[MilestoneValidator] Ghost mafia milestone - clearing")
		milestones["joined_mafia"] = nil
		fixes = fixes + 1
	end
	
	if flags.in_mob and not milestones["joined_mafia"] then
		milestones["joined_mafia"] = { age = state.Age, year = os.date("%Y") }
		fixes = fixes + 1
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- "Became Famous" milestone requires actual fame
	-- ═══════════════════════════════════════════════════════════════════════
	if milestones["became_famous"] and not flags.is_famous and not flags.fame_career then
		warn("[MilestoneValidator] Ghost fame milestone - clearing")
		milestones["became_famous"] = nil
		fixes = fixes + 1
	end
	
	if (flags.is_famous or flags.fame_career) and not milestones["became_famous"] then
		milestones["became_famous"] = { age = state.Age, year = os.date("%Y") }
		fixes = fixes + 1
	end
	
	state.Milestones = milestones
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- AAA FIX: EDUCATION SYSTEM VALIDATOR
-- Ensures education data is consistent with flags and age
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:validateEducationSystem(state)
	local fixes = 0
	local flags = state.Flags or {}
	local age = state.Age or 0
	
	state.EducationData = state.EducationData or {}
	local edu = state.EducationData
	
	-- Children under 5 can't be in school
	if age < 5 then
		if flags.in_school then
			flags.in_school = nil
			fixes = fixes + 1
		end
		if flags.in_college then
			flags.in_college = nil
			edu.inCollege = nil
			fixes = fixes + 1
		end
	end
	
	-- Under 18 can't be in college (unless special cases)
	if age < 16 and flags.in_college then
		flags.in_college = nil
		edu.inCollege = nil
		fixes = fixes + 1
	end
	
	-- Sync in_college flag with EducationData
	if flags.in_college and not edu.inCollege then
		edu.inCollege = true
		edu.Status = edu.Status or "enrolled"
		fixes = fixes + 1
	elseif edu.inCollege and not flags.in_college then
		flags.in_college = true
		fixes = fixes + 1
	end
	
	-- GPA must be bounded 0-4
	if edu.GPA then
		if type(edu.GPA) ~= "number" then
			edu.GPA = tonumber(edu.GPA) or 2.5
			fixes = fixes + 1
		else
			edu.GPA = math.max(0, math.min(4, edu.GPA))
		end
	end
	
	-- Debt must be a number
	if edu.Debt then
		if type(edu.Debt) ~= "number" then
			edu.Debt = tonumber(edu.Debt) or 0
			fixes = fixes + 1
		end
		if edu.Debt < 0 then
			edu.Debt = 0
			fixes = fixes + 1
		end
	end
	
	-- yearsCompleted bounds
	if edu.yearsCompleted then
		if type(edu.yearsCompleted) ~= "number" then
			edu.yearsCompleted = 0
			fixes = fixes + 1
		else
			edu.yearsCompleted = math.max(0, math.min(20, edu.yearsCompleted))
		end
	end
	
	-- Validate degree flags match degreeLevel
	if edu.degreeLevel then
		if edu.degreeLevel >= 1 then flags.has_diploma = true end
		if edu.degreeLevel >= 2 then flags.has_associate = true end
		if edu.degreeLevel >= 3 then flags.has_degree = true; flags.has_bachelor = true end
		if edu.degreeLevel >= 4 then flags.has_master = true end
		if edu.degreeLevel >= 5 then flags.has_phd = true end
	end
	
	-- Can't be both dropped out AND graduated
	if flags.dropped_out_high_school and flags.has_diploma then
		flags.dropped_out_high_school = nil
		fixes = fixes + 1
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- AAA FIX: ASSET OWNERSHIP VALIDATOR
-- Ensures asset flags match actual owned assets
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:validateAssetOwnership(state)
	local fixes = 0
	local flags = state.Flags or {}
	
	state.Assets = state.Assets or {}
	local assets = state.Assets
	
	-- Count owned vehicles
	local vehicleCount = 0
	if assets.Vehicles then
		for _, v in ipairs(assets.Vehicles) do
			if type(v) == "table" and (v.owned or v.id) then
				vehicleCount = vehicleCount + 1
			end
		end
	end
	
	-- Sync vehicle flags
	if vehicleCount > 0 then
		if not flags.has_car and not flags.has_vehicle then
			flags.has_car = true
			flags.has_vehicle = true
			fixes = fixes + 1
		end
	else
		if flags.has_car then
			flags.has_car = nil
			fixes = fixes + 1
		end
		if flags.has_vehicle then
			flags.has_vehicle = nil
			fixes = fixes + 1
		end
	end
	
	-- Count owned properties
	local propertyCount = 0
	if assets.Properties then
		for _, p in ipairs(assets.Properties) do
			if type(p) == "table" and (p.owned or p.id) then
				propertyCount = propertyCount + 1
			end
		end
	end
	
	-- Sync property flags
	if propertyCount > 0 then
		if not flags.homeowner and not flags.has_property then
			flags.homeowner = true
			flags.has_property = true
			fixes = fixes + 1
		end
		-- Can't be homeless with property
		if flags.homeless then
			flags.homeless = nil
			fixes = fixes + 1
		end
	else
		if flags.homeowner then
			flags.homeowner = nil
			fixes = fixes + 1
		end
		if flags.has_property then
			flags.has_property = nil
			fixes = fixes + 1
		end
	end
	
	-- Calculate and sync NetWorth
	local totalWorth = (state.Money or 0)
	
	if assets.Vehicles then
		for _, v in ipairs(assets.Vehicles) do
			if type(v) == "table" and v.value then
				totalWorth = totalWorth + (type(v.value) == "number" and v.value or 0)
			end
		end
	end
	
	if assets.Properties then
		for _, p in ipairs(assets.Properties) do
			if type(p) == "table" and p.value then
				totalWorth = totalWorth + (type(p.value) == "number" and p.value or 0)
			end
		end
	end
	
	if assets.Investments then
		for _, i in ipairs(assets.Investments) do
			if type(i) == "table" and i.value then
				totalWorth = totalWorth + (type(i.value) == "number" and i.value or 0)
			end
		end
	end
	
	-- Subtract debts
	if state.EducationData and state.EducationData.Debt then
		totalWorth = totalWorth - (state.EducationData.Debt or 0)
	end
	if flags.mortgage_debt and type(flags.mortgage_debt) == "number" then
		totalWorth = totalWorth - flags.mortgage_debt
	end
	if flags.credit_card_debt and type(flags.credit_card_debt) == "number" then
		totalWorth = totalWorth - flags.credit_card_debt
	end
	
	state.NetWorth = totalWorth
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- AAA FIX: PRISON STATE VALIDATOR
-- Ensures prison state is consistent
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:validatePrisonState(state)
	local fixes = 0
	local flags = state.Flags or {}
	
	-- If InJail, ensure all prison flags set
	if state.InJail then
		if not flags.in_prison then
			flags.in_prison = true
			fixes = fixes + 1
		end
		if not flags.incarcerated then
			flags.incarcerated = true
			fixes = fixes + 1
		end
		
		-- JailYearsLeft must be positive
		if not state.JailYearsLeft or state.JailYearsLeft <= 0 then
			state.InJail = false
			flags.in_prison = nil
			flags.incarcerated = nil
			fixes = fixes + 1
		end
		
		-- Can't work while in prison (cleared job)
		if flags.employed or flags.has_job then
			-- Save job info before clearing
			if state.CurrentJob and not (state.CareerInfo and state.CareerInfo.lastJobBeforeJail) then
				state.CareerInfo = state.CareerInfo or {}
				state.CareerInfo.lastJobBeforeJail = state.CurrentJob
			end
			state.CurrentJob = nil
			flags.employed = nil
			flags.has_job = nil
			fixes = fixes + 1
		end
	else
		-- Not in jail - clear all prison flags
		if flags.in_prison then
			flags.in_prison = nil
			fixes = fixes + 1
		end
		if flags.incarcerated then
			flags.incarcerated = nil
			fixes = fixes + 1
		end
		
		-- JailYearsLeft should be 0 or nil
		if state.JailYearsLeft and state.JailYearsLeft > 0 then
			state.JailYearsLeft = 0
			fixes = fixes + 1
		end
	end
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- AAA FIX: ASSET VALIDATOR
-- Ensures all assets have valid structure and values
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:validateAssets(state)
	local fixes = 0
	local flags = state.Flags or {}
	
	state.Assets = state.Assets or {}
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Vehicle Validation
	-- ═══════════════════════════════════════════════════════════════════════
	if state.Assets.Vehicles then
		local validVehicles = {}
		
		for i, vehicle in ipairs(state.Assets.Vehicles) do
			local isValid = true
			
			-- Must have some identifier
			if not vehicle.id and not vehicle.name then
				isValid = false
			end
			
			-- Value must be a number and non-negative
			if vehicle.value then
				if type(vehicle.value) ~= "number" then
					vehicle.value = tonumber(vehicle.value) or 0
					fixes = fixes + 1
				end
				if vehicle.value < 0 then
					vehicle.value = 0
					fixes = fixes + 1
				end
			else
				vehicle.value = 0
			end
			
			-- Condition should be 0-100
			if vehicle.condition then
				if type(vehicle.condition) ~= "number" then
					vehicle.condition = 50
					fixes = fixes + 1
				else
					vehicle.condition = math.max(0, math.min(100, vehicle.condition))
				end
			end
			
			-- Ensure purchasePrice exists for profit/loss calculations
			if not vehicle.purchasePrice and vehicle.value then
				vehicle.purchasePrice = vehicle.value
				fixes = fixes + 1
			end
			
			if isValid then
				table.insert(validVehicles, vehicle)
			else
				fixes = fixes + 1
			end
		end
		
		state.Assets.Vehicles = validVehicles
		
		-- Sync flags
		if #validVehicles > 0 then
			flags.has_vehicle = true
			flags.has_car = true
		else
			flags.has_vehicle = nil
			flags.has_car = nil
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Property Validation
	-- ═══════════════════════════════════════════════════════════════════════
	if state.Assets.Properties then
		local validProperties = {}
		
		for i, property in ipairs(state.Assets.Properties) do
			local isValid = true
			
			-- Must have some identifier
			if not property.id and not property.name then
				isValid = false
			end
			
			-- Value must be a number and non-negative
			if property.value then
				if type(property.value) ~= "number" then
					property.value = tonumber(property.value) or 0
					fixes = fixes + 1
				end
				if property.value < 0 then
					property.value = 0
					fixes = fixes + 1
				end
			else
				property.value = 100000 -- Default home value
			end
			
			-- Mortgage should be a number
			if property.mortgage then
				if type(property.mortgage) ~= "number" then
					property.mortgage = tonumber(property.mortgage) or 0
					fixes = fixes + 1
				end
				if property.mortgage < 0 then
					property.mortgage = 0
					fixes = fixes + 1
				end
			end
			
			if isValid then
				table.insert(validProperties, property)
			else
				fixes = fixes + 1
			end
		end
		
		state.Assets.Properties = validProperties
		
		-- Sync flags
		if #validProperties > 0 then
			flags.homeowner = true
			flags.has_property = true
		else
			flags.homeowner = nil
			flags.has_property = nil
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Investment Validation  
	-- ═══════════════════════════════════════════════════════════════════════
	if state.Assets.Investments then
		local validInvestments = {}
		
		for i, inv in ipairs(state.Assets.Investments) do
			local isValid = true
			
			-- Value and shares must be numbers
			if inv.value and type(inv.value) ~= "number" then
				inv.value = tonumber(inv.value) or 0
				fixes = fixes + 1
			end
			if inv.shares and type(inv.shares) ~= "number" then
				inv.shares = tonumber(inv.shares) or 0
				fixes = fixes + 1
			end
			
			-- Can't have negative value
			if inv.value and inv.value < 0 then
				inv.value = 0
				fixes = fixes + 1
			end
			
			if isValid and inv.value and inv.value > 0 then
				table.insert(validInvestments, inv)
			end
		end
		
		state.Assets.Investments = validInvestments
	end
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- Net Worth Calculation
	-- ═══════════════════════════════════════════════════════════════════════
	local totalAssetValue = 0
	
	-- Add cash
	totalAssetValue = totalAssetValue + (state.Money or 0)
	
	-- Add vehicles
	if state.Assets.Vehicles then
		for _, v in ipairs(state.Assets.Vehicles) do
			totalAssetValue = totalAssetValue + (v.value or 0)
		end
	end
	
	-- Add properties (minus mortgages)
	if state.Assets.Properties then
		for _, p in ipairs(state.Assets.Properties) do
			totalAssetValue = totalAssetValue + (p.value or 0) - (p.mortgage or 0)
		end
	end
	
	-- Add investments
	if state.Assets.Investments then
		for _, inv in ipairs(state.Assets.Investments) do
			totalAssetValue = totalAssetValue + (inv.value or 0)
		end
	end
	
	-- Subtract debts
	if state.EducationData and state.EducationData.Debt then
		totalAssetValue = totalAssetValue - (state.EducationData.Debt or 0)
	end
	if flags.credit_card_debt and type(flags.credit_card_debt) == "number" then
		totalAssetValue = totalAssetValue - flags.credit_card_debt
	end
	
	state.NetWorth = totalAssetValue
	
	return fixes
end

-- ════════════════════════════════════════════════════════════════════════════
-- FULL INTEGRITY CHECK
-- Runs ALL validators in proper order for complete state healing
-- ════════════════════════════════════════════════════════════════════════════
function LifeBackend:fullIntegrityCheck(state)
	if not state then return 0 end
	
	print("[FullIntegrityCheck] ═══════════════════════════════════════════════")
	print("[FullIntegrityCheck] Starting comprehensive state healing...")
	
	local totalFixes = 0
	
	-- Phase 1: Basic consistency
	totalFixes = totalFixes + self:validateStateConsistency(state)
	
	-- Phase 2: Premium flag validation
	totalFixes = totalFixes + self:validatePremiumFlags(state)
	
	-- Phase 3: Event chain reconciliation
	totalFixes = totalFixes + self:reconcileEventChains(state)
	
	-- Phase 4: Relationship cleanup
	totalFixes = totalFixes + self:clearGhostRelationships(state)
	
	-- Phase 5: Housing and titles
	totalFixes = totalFixes + self:syncHousingAndTitles(state)
	
	-- Phase 6: Occupation validation
	totalFixes = totalFixes + self:enforceOneOccupation(state)
	
	-- Phase 7: Fame state validation
	totalFixes = totalFixes + self:validateFameState(state)
	
	-- Phase 8: Royal marriage validation
	totalFixes = totalFixes + self:validateRoyalMarriage(state)
	
	-- Phase 9: Asset cleanup
	totalFixes = totalFixes + self:cleanDuplicateAssets(state)
	
	-- Phase 10: Child state validation
	totalFixes = totalFixes + self:validateChildState(state)
	
	-- Phase 11: Milestone validation
	totalFixes = totalFixes + self:validateMilestones(state)
	
	-- Phase 12: AAA FIX - Comprehensive asset validation
	totalFixes = totalFixes + self:validateAssets(state)
	
	print(string.format("[FullIntegrityCheck] Complete. Total fixes: %d", totalFixes))
	print("[FullIntegrityCheck] ═══════════════════════════════════════════════")
	
	return totalFixes
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
			function(player, years) return self:executeTimeMachineAction(player, years) end,
			function(player) return self:executeJailRelease(player) end,
			function(player) return self:executeStatBoost(player) end,  -- CRITICAL FIX #922: Stat boost handler
			function(player, action) return self:executeExtraLife(player, action) end  -- CRITICAL FIX #923: Extra life handler
		)
		return result
	end
	print("[LifeBackend] ProcessReceipt handler set up for Developer Products")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #922: STAT BOOST - Instantly boost all stats by +25!
-- Called when player purchases STAT_BOOST product
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:executeStatBoost(player)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end
	
	-- Initialize stats if needed
	state.Stats = state.Stats or { Health = 50, Happiness = 50, Smarts = 50, Looks = 50 }
	
	-- Boost ALL stats by 25!
	local boostAmount = 25
	local oldHealth = state.Stats.Health or 50
	local oldHappiness = state.Stats.Happiness or 50
	local oldSmarts = state.Stats.Smarts or 50
	local oldLooks = state.Stats.Looks or 50
	
	state.Stats.Health = math.min(100, oldHealth + boostAmount)
	state.Stats.Happiness = math.min(100, oldHappiness + boostAmount)
	state.Stats.Smarts = math.min(100, oldSmarts + boostAmount)
	state.Stats.Looks = math.min(100, oldLooks + boostAmount)
	
	-- Also sync to state.Health etc for consistency
	state.Health = state.Stats.Health
	state.Happiness = state.Stats.Happiness
	state.Smarts = state.Stats.Smarts
	state.Looks = state.Stats.Looks
	
	-- Set flag
	state.Flags = state.Flags or {}
	state.Flags.stat_boosted = true
	state.Flags.times_stat_boosted = (state.Flags.times_stat_boosted or 0) + 1
	
	-- Create dramatic message
	local message = string.format(
		"📈 MIRACLE BOOST! 💪\n\n" ..
		"❤️ Health: %d → %d (+%d)\n" ..
		"😊 Happiness: %d → %d (+%d)\n" ..
		"🧠 Smarts: %d → %d (+%d)\n" ..
		"✨ Looks: %d → %d (+%d)\n\n" ..
		"You feel AMAZING!",
		oldHealth, state.Stats.Health, state.Stats.Health - oldHealth,
		oldHappiness, state.Stats.Happiness, state.Stats.Happiness - oldHappiness,
		oldSmarts, state.Stats.Smarts, state.Stats.Smarts - oldSmarts,
		oldLooks, state.Stats.Looks, state.Stats.Looks - oldLooks
	)
	
	-- Push state with the boost message
	self:pushState(player, "📈 MIRACLE BOOST! All stats increased by +25! You feel INCREDIBLE!")
	
	print("[LifeBackend] STAT_BOOST executed for:", player.Name)
	return { 
		success = true, 
		message = message,
		showPopup = true,
		emoji = "📈",
		title = "💪 MIRACLE BOOST!",
		body = message,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #923: EXTRA LIFE - The AMAZING Second Chance System!
-- 
-- When purchased: Notifies player they have an extra life
-- When used (on death): 
--   - Prevents death entirely
--   - Rolls back age 5-10 years (was in coma/recovery)
--   - Restores health to 100%
--   - Keeps ALL money, assets, relationships
--   - Grants "survivor" flag for unique events
--   - +10 Smarts (near-death wisdom)
--   - Creates dramatic narrative
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:executeExtraLife(player, action)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end
	
	-- If just purchased, notify the player
	if action == "purchased" then
		local lives = GamepassSystem:getExtraLives(player)
		self:pushState(player, string.format("💖 EXTRA LIFE ACQUIRED! You now have %d extra %s ready!", lives, lives == 1 and "life" or "lives"))
		return { success = true, message = "Extra life stored for when you need it most!" }
	end
	
	-- If being used (called from death prevention), do the revival
	if action == "use" then
		return self:performExtraLifeRevival(player, state)
	end
	
	return { success = true, message = "Extra life ready." }
end

-- The actual revival logic - called when player would die but has extra life
function LifeBackend:performExtraLifeRevival(player, state)
	-- Use one extra life
	local used = GamepassSystem:useExtraLife(player)
	if not used then
		return { success = false, message = "No extra lives remaining!" }
	end
	
	-- Calculate how much to roll back age (5-10 years recovery time)
	local currentAge = state.Age or 25
	local yearsInRecovery = RANDOM:NextInteger(5, 10)
	local newAge = math.max(18, currentAge - yearsInRecovery) -- Can't go below 18
	local actualYearsBack = currentAge - newAge
	
	-- Save old values for narrative
	local oldAge = currentAge
	local oldHealth = (state.Stats and state.Stats.Health) or 50
	local deathCause = state.DeathReason or state.CauseOfDeath or "the accident"
	
	-- REVIVE THE CHARACTER!
	state.Age = newAge
	state.Year = (state.Year or 2024) - actualYearsBack
	
	-- Full health restoration
	state.Stats = state.Stats or {}
	state.Stats.Health = 100
	state.Health = 100
	
	-- Boost happiness (glad to be alive!)
	state.Stats.Happiness = math.min(100, (state.Stats.Happiness or 50) + 20)
	
	-- Wisdom from near-death experience (+10 Smarts)
	state.Stats.Smarts = math.min(100, (state.Stats.Smarts or 50) + 10)
	
	-- Clear death flags
	state.Flags = state.Flags or {}
	state.Flags.dead = nil
	state.Flags.is_dead = nil
	state.Flags.is_alive = true
	state.DeathReason = nil
	state.DeathAge = nil
	state.DeathYear = nil
	state.CauseOfDeath = nil
	
	-- Grant survivor flags for unique events!
	state.Flags.survivor = true
	state.Flags.near_death_survivor = true
	state.Flags.cheated_death = true
	state.Flags.second_chance = true
	state.Flags.times_revived = (state.Flags.times_revived or 0) + 1
	state.Flags.last_revival_age = oldAge
	state.Flags.years_lost_to_coma = actualYearsBack
	
	-- Keep ALL money and assets (they're yours!)
	-- Keep ALL relationships (they waited for you!)
	
	-- Generate dramatic revival narrative
	local survivalStories = {
		string.format("💖 MIRACLE! After %d years in a coma, you woke up! The doctors called it a medical miracle.", actualYearsBack),
		string.format("💖 SECOND CHANCE! You flatlined but were revived. After %d years of recovery, you're back stronger than ever!", actualYearsBack),
		string.format("💖 SURVIVOR! Against all odds, you survived %s. %d years of rehabilitation later, you've made a full recovery!", deathCause, actualYearsBack),
		string.format("💖 BACK FROM THE BRINK! You spent %d years fighting for your life. Now you're ready to live it to the fullest!", actualYearsBack),
		string.format("💖 REBORN! What should have killed you only made you stronger. After %d years, you emerged with a new perspective on life.", actualYearsBack),
	}
	local survivalMessage = survivalStories[RANDOM:NextInteger(1, #survivalStories)]
	
	-- Add to year log
	state.YearLog = state.YearLog or {}
	table.insert(state.YearLog, {
		type = "miracle",
		emoji = "💖",
		text = survivalMessage,
		isSpecial = true,
	})
	
	-- Full message for CardPopup
	local fullMessage = string.format(
		"%s\n\n" ..
		"📊 Your Second Chance:\n" ..
		"• Age: %d → %d (-%d years in recovery)\n" ..
		"• Health: %d%% → 100%%\n" ..
		"• Wisdom: +10 🧠 (Near-death insight)\n" ..
		"• All your money, assets & relationships preserved!\n\n" ..
		"🌟 You've unlocked special 'Survivor' life events!",
		survivalMessage, oldAge, newAge, actualYearsBack, oldHealth
	)
	
	-- Push state update
	self:pushState(player, survivalMessage)
	
	print("[LifeBackend] EXTRA_LIFE REVIVAL executed for:", player.Name, "Age rolled back from", oldAge, "to", newAge)
	
	return {
		success = true,
		message = fullMessage,
		revived = true,
		showPopup = true,
		emoji = "💖",
		title = "💖 SECOND CHANCE AT LIFE!",
		body = fullMessage,
		newAge = newAge,
		oldAge = oldAge,
		yearsBack = actualYearsBack,
	}
end

-- Check if player should be saved by extra life (called before death)
function LifeBackend:checkExtraLifeSave(player, state)
	if not player or not GamepassSystem then return false end
	
	-- Check if player has an extra life
	if GamepassSystem:hasExtraLife(player) then
		-- Use the extra life to save them!
		local result = self:performExtraLifeRevival(player, state)
		return result.success, result
	end
	
	return false, nil
end

-- CRITICAL FIX #908: Execute jail release (called from ProcessReceipt after GET_OUT_OF_JAIL purchase)
function LifeBackend:executeJailRelease(player)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end
	
	-- Check if actually in jail
	if not state.InJail then
		return { success = false, message = "You're not in jail!" }
	end
	
	-- Release from jail immediately!
	state.InJail = false
	state.JailYearsLeft = 0
	
	-- Clear ALL prison flags (AAA exhaustive list)
	state.Flags = state.Flags or {}
	state.Flags.in_prison = nil
	state.Flags.incarcerated = nil
	state.Flags.jailed = nil
	state.Flags.serving_time = nil
	state.Flags.prison_sentence = nil
	state.Flags.awaiting_trial = nil
	state.Flags.convicted = nil
	
	-- Clear any prison-related pending events
	if state.PendingEvent and state.PendingEvent.id then
		local eventId = state.PendingEvent.id
		if eventId:find("prison") or eventId:find("jail") or eventId:find("incarcerat") then
			state.PendingEvent = nil
		end
	end
	
	-- Good reputation boost for purchasing freedom
	state.Flags.purchased_freedom = true
	
	-- Push notification to player
	self:pushState(player, "🔓 GET OUT OF JAIL FREE! All charges dropped - you're a free person!")
	
	print("[LifeBackend] GET OUT OF JAIL executed for:", player.Name)
	return { success = true, message = "You're free! All charges dropped." }
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
	-- CRITICAL FIX: Handle nil values to prevent type errors
	local safeValue = tonumber(value) or 0
	local safeMin = tonumber(minValue) or 0
	local safeMax = tonumber(maxValue) or 100
	return math.clamp(safeValue, safeMin, safeMax)
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
	-- CRITICAL FIX: Handle nil and invalid values
	if not amount or type(amount) ~= "number" then
		return "$0"
	end
	if amount >= 1_000_000 then
		return string.format("$%.1fM", amount / 1_000_000)
	elseif amount >= 1_000 then
		return string.format("$%.1fK", amount / 1_000)
	elseif amount < 0 then
		return string.format("-$%.0f", math.abs(amount))
	else
		return "$" .. tostring(math.floor(amount + 0.5))
	end
end

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                        AAA STATE MANAGER SYSTEM                               ║
-- ║  Single source of truth for all stats - GetStat, SetStat, AddStat            ║
-- ║  Prevents direct state mutations and ensures consistency                      ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
local StateManager = {}

-- Safe type coercion for any value
function StateManager.safeNumber(value, default)
	if type(value) == "number" then return value end
	if type(value) == "boolean" then return value and 1 or 0 end
	if type(value) == "string" then return tonumber(value) or default or 0 end
	return default or 0
end

-- Get a stat value safely
function StateManager.GetStat(state, statName)
	if not state then return 0 end
	state.Stats = state.Stats or { Health = 50, Happiness = 50, Smarts = 50, Looks = 50 }
	return StateManager.safeNumber(state.Stats[statName], 50)
end

-- Set a stat value with bounds checking
function StateManager.SetStat(state, statName, value)
	if not state then return end
	state.Stats = state.Stats or { Health = 50, Happiness = 50, Smarts = 50, Looks = 50 }
	local numValue = StateManager.safeNumber(value, 50)
	state.Stats[statName] = math.max(0, math.min(100, numValue))
	-- Keep shortcuts in sync
	if statName == "Health" then state.Health = state.Stats.Health end
	if statName == "Happiness" then state.Happiness = state.Stats.Happiness end
	if statName == "Smarts" then state.Smarts = state.Stats.Smarts end
	if statName == "Looks" then state.Looks = state.Stats.Looks end
end

-- Add to a stat value with bounds checking
function StateManager.AddStat(state, statName, delta)
	if not state then return end
	local current = StateManager.GetStat(state, statName)
	StateManager.SetStat(state, statName, current + StateManager.safeNumber(delta, 0))
end

-- Get money safely
function StateManager.GetMoney(state)
	if not state then return 0 end
	return StateManager.safeNumber(state.Money, 0)
end

-- Set money with validation
function StateManager.SetMoney(state, value)
	if not state then return end
	state.Money = StateManager.safeNumber(value, 0)
end

-- Add money (can be negative for expenses)
function StateManager.AddMoney(state, delta)
	if not state then return end
	state.Money = StateManager.GetMoney(state) + StateManager.safeNumber(delta, 0)
end

-- Get a flag safely (returns nil if not set, not false)
function StateManager.GetFlag(state, flagName)
	if not state or not state.Flags then return nil end
	return state.Flags[flagName]
end

-- Set a flag
function StateManager.SetFlag(state, flagName, value)
	if not state then return end
	state.Flags = state.Flags or {}
	state.Flags[flagName] = value
end

-- Check if flag is truthy
function StateManager.HasFlag(state, flagName)
	return StateManager.GetFlag(state, flagName) ~= nil and StateManager.GetFlag(state, flagName) ~= false
end

-- Get relationship safely
function StateManager.GetRelationship(state, relId)
	if not state or not state.Relationships then return nil end
	return state.Relationships[relId]
end

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                      AAA STATE PATCH SYSTEM                                   ║
-- ║  All state mutations go through patches - enables undo, logging, validation  ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
local StatePatch = {}

function StatePatch.new()
	return {
		stats = {},      -- { Health = +5, Happiness = -10 }
		money = 0,       -- delta
		flags = {},      -- { flag_name = value }
		relationships = {}, -- { relId = { delta = +5 } }
		feed = nil,      -- feed message
		_applied = false,
	}
end

function StatePatch.apply(state, patch)
	if not state or not patch or patch._applied then return false end
	
	-- Apply stat changes
	for statName, delta in pairs(patch.stats or {}) do
		StateManager.AddStat(state, statName, delta)
	end
	
	-- Apply money change
	if patch.money and patch.money ~= 0 then
		StateManager.AddMoney(state, patch.money)
	end
	
	-- Apply flag changes
	for flagName, value in pairs(patch.flags or {}) do
		StateManager.SetFlag(state, flagName, value)
	end
	
	-- Apply relationship changes
	for relId, changes in pairs(patch.relationships or {}) do
		local rel = StateManager.GetRelationship(state, relId)
		if rel and changes.delta then
			rel.relationship = math.max(0, math.min(100, (rel.relationship or 50) + changes.delta))
		end
	end
	
	patch._applied = true
	return true
end

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                  AAA RELATIONSHIP DECAY SYSTEM                                ║
-- ║  Friends get angry if you don't talk to them - like competition game         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
local RelationshipDecaySystem = {}

RelationshipDecaySystem.DECAY_RATES = {
	friend = 3,           -- Friends decay 3 points per year of no contact
	best_friend = 2,      -- Best friends decay slower
	acquaintance = 5,     -- Acquaintances fade faster
	partner = 1,          -- Partners decay very slowly
	ex = 4,               -- Exes fade quickly
}

RelationshipDecaySystem.ANGER_THRESHOLDS = {
	annoyed = 2,          -- 2 years = annoyed
	angry = 4,            -- 4 years = angry
	furious = 6,          -- 6 years = furious (may end friendship)
	estranged = 8,        -- 8 years = friendship over
}

function RelationshipDecaySystem.processYearlyDecay(state)
	if not state or not state.Relationships then return {} end
	
	local currentAge = state.Age or 0
	local decayEvents = {}
	state.Flags = state.Flags or {}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Global cooldown to prevent spam!
	-- User bug: "IT KEEP SPAM SAYING FRIEND SHIPS OVER"
	-- Only ONE decay popup per year maximum!
	-- ═══════════════════════════════════════════════════════════════════════════════
	state._lastDecayPopupAge = state._lastDecayPopupAge or 0
	local alreadyShownThisYear = (state._lastDecayPopupAge == currentAge)
	local hasShownPopupThisCall = false
	
	-- Track friendships to remove AFTER iteration (can't modify during iteration)
	local friendshipsToRemove = {}
	
	for relId, rel in pairs(state.Relationships) do
		if type(rel) == "table" and (rel.type == "friend" or (type(relId) == "string" and relId:find("friend"))) then
			-- Skip if deceased or already estranged
			if rel.deceased or rel.dead or rel.estranged or rel.formerFriend then 
				-- Mark for removal if estranged
				if rel.estranged or rel.formerFriend then
					table.insert(friendshipsToRemove, relId)
				end
				continue 
			end
			
			-- Initialize last contact if missing
			if not rel.lastContact then
				rel.lastContact = rel.metAt or rel.createdAt or (currentAge - 1)
			end
			
			local yearsSinceContact = currentAge - (rel.lastContact or 0)
			
			-- Apply decay based on neglect
			if yearsSinceContact >= 1 then
				local decayRate = RelationshipDecaySystem.DECAY_RATES[rel.subtype or "friend"] or 3
				local totalDecay = decayRate * yearsSinceContact
				rel.relationship = math.max(0, (rel.relationship or 50) - totalDecay)
				
				-- ═══════════════════════════════════════════════════════════════════════════════
				-- CRITICAL FIX: Only show ONE popup per year to prevent spam!
				-- ═══════════════════════════════════════════════════════════════════════════════
				
				-- Friendship ends after too much neglect - PRIORITY CHECK FIRST
				if yearsSinceContact >= RelationshipDecaySystem.ANGER_THRESHOLDS.estranged or rel.relationship <= 0 then
					-- Mark for removal
					table.insert(friendshipsToRemove, relId)
					
					-- Only generate popup if we haven't already shown one
					if not alreadyShownThisYear and not hasShownPopupThisCall then
						table.insert(decayEvents, {
							type = "friendship_ended",
							relId = relId,
							name = rel.name or "Your friend",
							message = string.format("💔 You and %s have drifted apart. The friendship is over.", 
								rel.name or "your friend"),
							yearsSince = yearsSinceContact,
						})
						hasShownPopupThisCall = true
						state._lastDecayPopupAge = currentAge
					end
					
					state.Flags.lost_friend = true
					state.Flags.lost_friend_name = rel.name
					
				-- Generate anger events - only if no popup shown yet
				elseif yearsSinceContact >= RelationshipDecaySystem.ANGER_THRESHOLDS.furious and not rel._announcedFurious then
					if not alreadyShownThisYear and not hasShownPopupThisCall then
						table.insert(decayEvents, {
							type = "friend_furious",
							relId = relId,
							name = rel.name or "Your friend",
							message = string.format("🔥 %s is FURIOUS! \"You never talk to me anymore!\"", 
								rel.name or "Your friend"),
							yearsSince = yearsSinceContact,
							mayEndFriendship = true,
						})
						hasShownPopupThisCall = true
						state._lastDecayPopupAge = currentAge
					end
					rel._announcedFurious = true
					rel.furious = true
					
				elseif yearsSinceContact >= RelationshipDecaySystem.ANGER_THRESHOLDS.angry and not rel._announcedAngry then
					if not alreadyShownThisYear and not hasShownPopupThisCall then
						table.insert(decayEvents, {
							type = "friend_angry",
							relId = relId,
							name = rel.name or "Your friend",
							message = string.format("😡 %s is angry! They feel forgotten and hurt.", 
								rel.name or "Your friend"),
							yearsSince = yearsSinceContact,
						})
						hasShownPopupThisCall = true
						state._lastDecayPopupAge = currentAge
					end
					rel._announcedAngry = true
					rel.angry = true
					
				elseif yearsSinceContact >= RelationshipDecaySystem.ANGER_THRESHOLDS.annoyed and not rel._announcedAnnoyed then
					if not alreadyShownThisYear and not hasShownPopupThisCall then
						table.insert(decayEvents, {
							type = "friend_annoyed",
							relId = relId,
							name = rel.name or "Your friend",
							message = string.format("😤 %s is annoyed you haven't reached out in %d years.", 
								rel.name or "Your friend", yearsSinceContact),
							yearsSince = yearsSinceContact,
						})
						hasShownPopupThisCall = true
						state._lastDecayPopupAge = currentAge
					end
					rel._announcedAnnoyed = true
				end
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Actually REMOVE ended friendships from the relationships list!
	-- User bug: "ENSURE IT ACTUALLY ENDS FRIENDSHIPS"
	-- Previously we just set flags but the relationship stayed in the UI!
	-- ═══════════════════════════════════════════════════════════════════════════════
	for _, relId in ipairs(friendshipsToRemove) do
		local rel = state.Relationships[relId]
		if rel then
			-- Store in former friends for reference (not shown in UI)
			state.FormerFriends = state.FormerFriends or {}
			state.FormerFriends[relId] = {
				name = rel.name,
				endedAt = currentAge,
				reason = "drifted_apart",
			}
			-- Remove from active relationships
			state.Relationships[relId] = nil
		end
	end
	
	return decayEvents
end

-- Record contact with a friend (resets decay timer)
function RelationshipDecaySystem.recordContact(state, relId)
	if not state or not state.Relationships then return end
	local rel = state.Relationships[relId]
	if rel then
		rel.lastContact = state.Age or 0
		rel._announcedAnnoyed = nil
		rel._announcedAngry = nil
		rel._announcedFurious = nil
		rel.angry = nil
		rel.furious = nil
	end
end

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                    AAA JOB INTERVIEW SYSTEM                                   ║
-- ║  Competitive jobs require interviews with choices affecting outcome          ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
local JobInterviewSystem = {}

JobInterviewSystem.QUESTIONS = {
	general = {
		{ 
			question = "Why do you want to work here?",
			options = {
				{ text = "I'm passionate about this field", modifier = 0.15, feedback = "Great answer! Shows genuine interest." },
				{ text = "The salary is great", modifier = -0.1, feedback = "A bit too honest..." },
				{ text = "I need a job", modifier = -0.2, feedback = "Not the enthusiasm they were hoping for." },
				{ text = "To grow my career", modifier = 0.1, feedback = "Professional response." },
			}
		},
		{
			question = "What's your greatest weakness?",
			options = {
				{ text = "I work too hard", modifier = 0.05, feedback = "Classic answer, a bit cliché." },
				{ text = "I'm a perfectionist", modifier = 0.08, feedback = "They've heard this before." },
				{ text = "I sometimes struggle with time management", modifier = 0.1, feedback = "Honest and self-aware!" },
				{ text = "I don't have any", modifier = -0.15, feedback = "That's a red flag." },
			}
		},
		{
			question = "Where do you see yourself in 5 years?",
			options = {
				{ text = "Leading a team here", modifier = 0.12, feedback = "Shows ambition and loyalty." },
				{ text = "Running my own company", modifier = -0.05, feedback = "They worry you'll leave quickly." },
				{ text = "In this same role", modifier = -0.08, feedback = "They want growth mindset." },
				{ text = "Growing with the company", modifier = 0.1, feedback = "Safe and professional." },
			}
		},
	},
	tech = {
		{
			question = "How do you stay updated with technology trends?",
			options = {
				{ text = "I read tech blogs and attend conferences", modifier = 0.15, feedback = "Shows dedication to learning!" },
				{ text = "I learn on the job", modifier = 0, feedback = "Adequate but not impressive." },
				{ text = "I take online courses regularly", modifier = 0.12, feedback = "Proactive approach!" },
				{ text = "I don't, I focus on what I know", modifier = -0.15, feedback = "Tech moves fast..." },
			}
		},
	},
	medical = {
		{
			question = "How do you handle high-pressure situations?",
			options = {
				{ text = "I stay calm and prioritize", modifier = 0.15, feedback = "Essential for healthcare!" },
				{ text = "I sometimes get stressed", modifier = -0.05, feedback = "Honest but concerning." },
				{ text = "I rely on my training", modifier = 0.1, feedback = "Shows preparation." },
				{ text = "I panic internally but appear calm", modifier = 0.05, feedback = "Human but professional." },
			}
		},
	},
	finance = {
		{
			question = "How do you approach risk management?",
			options = {
				{ text = "Conservative with thorough analysis", modifier = 0.12, feedback = "Solid approach." },
				{ text = "Aggressive for maximum returns", modifier = -0.1, feedback = "Too risky for most firms." },
				{ text = "Balanced based on client goals", modifier = 0.15, feedback = "Perfect answer!" },
				{ text = "I follow market trends", modifier = 0, feedback = "Reactive, not proactive." },
			}
		},
	},
}

JobInterviewSystem.BEHAVIORAL_SCENARIOS = {
	{
		scenario = "You notice a coworker making a serious mistake. What do you do?",
		options = {
			{ text = "Privately help them fix it", modifier = 0.15, feedback = "Teamwork and discretion!" },
			{ text = "Report it to management", modifier = -0.05, feedback = "Seen as a snitch." },
			{ text = "Ignore it, not my problem", modifier = -0.2, feedback = "Poor team player." },
			{ text = "Mention it in a team meeting", modifier = -0.1, feedback = "Publicly embarrassing them." },
		}
	},
	{
		scenario = "A client is being unreasonable and rude. How do you handle it?",
		options = {
			{ text = "Stay professional and find a solution", modifier = 0.15, feedback = "Perfect composure!" },
			{ text = "Match their energy", modifier = -0.2, feedback = "Not professional." },
			{ text = "Pass them to a manager", modifier = 0.05, feedback = "Sometimes necessary." },
			{ text = "End the conversation politely", modifier = 0.08, feedback = "Boundary setting." },
		}
	},
}

function JobInterviewSystem.generateInterview(job, state, baseChance)
	local category = (job.category or "general"):lower()
	local questions = JobInterviewSystem.QUESTIONS[category] or JobInterviewSystem.QUESTIONS.general
	
	-- Pick 2-3 questions
	local selectedQuestions = {}
	local shuffled = {}
	for _, q in ipairs(questions) do table.insert(shuffled, q) end
	for _, q in ipairs(JobInterviewSystem.QUESTIONS.general) do table.insert(shuffled, q) end
	
	-- Shuffle
	for i = #shuffled, 2, -1 do
		local j = RANDOM:NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	
	-- Take first 2-3
	local numQuestions = RANDOM:NextInteger(2, 3)
	for i = 1, math.min(numQuestions, #shuffled) do
		table.insert(selectedQuestions, shuffled[i])
	end
	
	-- Add a behavioral scenario
	local scenario = JobInterviewSystem.BEHAVIORAL_SCENARIOS[RANDOM:NextInteger(1, #JobInterviewSystem.BEHAVIORAL_SCENARIOS)]
	
	return {
		jobId = job.id,
		jobName = job.name or job.title,
		company = job.company or "the company",
		salary = job.salary or 0,
		baseChance = baseChance,
		questions = selectedQuestions,
		scenario = scenario,
		stage = 1,
		totalStages = #selectedQuestions + 1,
		modifierAccumulated = 0,
	}
end

function JobInterviewSystem.processResponse(interviewData, stageIndex, optionIndex)
	local stage = interviewData.questions[stageIndex] or interviewData.scenario
	if not stage then return interviewData end
	
	local option = stage.options[optionIndex]
	if option then
		interviewData.modifierAccumulated = (interviewData.modifierAccumulated or 0) + (option.modifier or 0)
		interviewData.lastFeedback = option.feedback
	end
	
	interviewData.stage = (interviewData.stage or 1) + 1
	return interviewData
end

function JobInterviewSystem.calculateFinalChance(interviewData)
	local base = interviewData.baseChance or 0.5
	local modifier = interviewData.modifierAccumulated or 0
	return math.max(0.05, math.min(0.95, base + modifier))
end

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                    AAA CHAIN STATE MANAGER                                    ║
-- ║  Manages premium path chains: Royalty, Mafia, Fame                           ║
-- ║  Ensures only one path active, proper state transitions                       ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
local ChainStateManager = {}

ChainStateManager.PATHS = {
	royalty = {
		stages = { "commoner", "dating_royalty", "engaged_royalty", "married_royalty", "royal_consort", "heir", "monarch" },
		exclusiveWith = { "mafia" }, -- Can't be royalty AND mafia
		stateKey = "RoyalState",
		flagPrefix = "royal_",
	},
	mafia = {
		stages = { "civilian", "approached", "associate", "soldier", "capo", "underboss", "boss" },
		exclusiveWith = { "royalty" },
		stateKey = "MobState",
		flagPrefix = "mob_",
	},
	fame = {
		stages = { "unknown", "hobbyist", "rising", "notable", "famous", "star", "legend" },
		exclusiveWith = {}, -- Fame can coexist with others
		stateKey = "FameState",
		flagPrefix = "fame_",
	},
}

function ChainStateManager.getCurrentPath(state)
	if not state or not state.Flags then return nil end
	
	if state.Flags.is_royalty or state.Flags.royal_birth or (state.RoyalState and state.RoyalState.isRoyal) then
		return "royalty"
	end
	if state.Flags.in_mob or (state.MobState and state.MobState.inMob) then
		return "mafia"
	end
	if state.Flags.fame_career or state.Flags.is_famous or (state.FameState and state.FameState.careerPath) then
		return "fame"
	end
	
	return nil
end

function ChainStateManager.getPathStage(state, pathName)
	local pathConfig = ChainStateManager.PATHS[pathName]
	if not pathConfig then return nil end
	
	local stateObj = state[pathConfig.stateKey]
	if not stateObj then return pathConfig.stages[1] end
	
	return stateObj.currentStage or stateObj.stage or pathConfig.stages[1]
end

function ChainStateManager.advanceStage(state, pathName)
	local pathConfig = ChainStateManager.PATHS[pathName]
	if not pathConfig then return false end
	
	local stateObj = state[pathConfig.stateKey] or {}
	local currentStage = stateObj.currentStage or 1
	
	if currentStage < #pathConfig.stages then
		stateObj.currentStage = currentStage + 1
		stateObj.stageName = pathConfig.stages[currentStage + 1]
		state[pathConfig.stateKey] = stateObj
		return true
	end
	
	return false
end

function ChainStateManager.validateExclusivity(state)
	local currentPath = ChainStateManager.getCurrentPath(state)
	if not currentPath then return 0 end
	
	local pathConfig = ChainStateManager.PATHS[currentPath]
	if not pathConfig then return 0 end
	
	local fixes = 0
	for _, exclusivePath in ipairs(pathConfig.exclusiveWith) do
		local otherConfig = ChainStateManager.PATHS[exclusivePath]
		if otherConfig then
			-- Clear the other path
			if state[otherConfig.stateKey] then
				state[otherConfig.stateKey] = nil
				fixes = fixes + 1
			end
			-- Clear related flags
			if state.Flags then
				for flagName, _ in pairs(state.Flags) do
					if flagName:find(otherConfig.flagPrefix) then
						state.Flags[flagName] = nil
						fixes = fixes + 1
					end
				end
			end
		end
	end
	
	return fixes
end

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                    AAA FEED SYSTEM                                            ║
-- ║  Single unified path for all feed messages                                    ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
local FeedSystem = {}

FeedSystem.MAX_LENGTH = 500
FeedSystem.PRIORITY = {
	critical = 1,    -- Death, major life events
	high = 2,        -- Premium events, milestones
	normal = 3,      -- Regular events
	low = 4,         -- Minor updates
}

function FeedSystem.createFeed(state)
	state._feedQueue = state._feedQueue or {}
	state._feedSeen = state._feedSeen or {}
end

function FeedSystem.addMessage(state, message, priority, emoji)
	if not state or not message or message == "" then return end
	
	FeedSystem.createFeed(state)
	
	-- Dedupe check
	local normalized = message:sub(1, 50)
	if state._feedSeen[normalized] then return end
	state._feedSeen[normalized] = true
	
	table.insert(state._feedQueue, {
		message = message,
		priority = priority or FeedSystem.PRIORITY.normal,
		emoji = emoji,
		timestamp = os.time(),
	})
end

function FeedSystem.flush(state)
	if not state or not state._feedQueue then return "" end
	
	-- Sort by priority
	table.sort(state._feedQueue, function(a, b) return a.priority < b.priority end)
	
	-- Build final message
	local parts = {}
	local totalLength = 0
	
	for _, item in ipairs(state._feedQueue) do
		local msg = item.emoji and (item.emoji .. " " .. item.message) or item.message
		if totalLength + #msg < FeedSystem.MAX_LENGTH then
			table.insert(parts, msg)
			totalLength = totalLength + #msg + 1
		end
	end
	
	-- Clear queue
	state._feedQueue = {}
	state._feedSeen = {}
	
	return table.concat(parts, " ")
end

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                    AAA INTEGRITY SYSTEM                                       ║
-- ║  Rate-limited state validation: on load, after major actions, on save        ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
local IntegritySystem = {}

IntegritySystem.MIN_INTERVAL = 30        -- Minimum 30 seconds between full checks
IntegritySystem.FORCE_INTERVAL = 300     -- Force check every 5 minutes
IntegritySystem.MAJOR_ACTIONS = {
	"marriage", "divorce", "job_change", "prison_release", "time_travel",
	"death", "rebirth", "join_mafia", "become_royalty", "become_famous",
	"buy_property", "bankruptcy", "inheritance",
}

function IntegritySystem.shouldRunFull(state)
	if not state then return false end
	
	local now = os.time()
	local lastRun = state._lastIntegrityCheck or 0
	local timeSince = now - lastRun
	
	-- Force if it's been too long
	if timeSince >= IntegritySystem.FORCE_INTERVAL then
		return true
	end
	
	-- Skip if too recent
	if timeSince < IntegritySystem.MIN_INTERVAL then
		return false
	end
	
	-- Check if major action occurred
	if state._majorActionPending then
		state._majorActionPending = nil
		return true
	end
	
	return false
end

function IntegritySystem.markMajorAction(state, actionType)
	if not state then return end
	state._majorActionPending = actionType
end

function IntegritySystem.recordCheck(state)
	if not state then return end
	state._lastIntegrityCheck = os.time()
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- AAA FIX: Enhanced appendFeed with duplicate prevention
-- Prevents the same message from appearing multiple times in one year
-- ═══════════════════════════════════════════════════════════════════════════════
local function appendFeed(state, message)
	if not state or not message or message == "" then
		return
	end
	
	-- AAA FIX: Track messages to prevent exact duplicates
	state._feedMessages = state._feedMessages or {}
	
	-- Normalize message for comparison (remove leading/trailing spaces)
	local normalizedMessage = message:match("^%s*(.-)%s*$") or message
	
	-- Check for duplicate
	if state._feedMessages[normalizedMessage] then
		return -- Skip duplicate
	end
	
	-- Also check if message is already in PendingFeed (partial match)
	if state.PendingFeed and state.PendingFeed:find(normalizedMessage:sub(1, 30), 1, true) then
		return -- Skip if first 30 chars match something already in feed
	end
	
	-- Mark as seen
	state._feedMessages[normalizedMessage] = true
	
	-- Append message
	if state.PendingFeed and state.PendingFeed ~= "" then
		state.PendingFeed = state.PendingFeed .. " " .. message
	else
		state.PendingFeed = message
	end
	
	-- AAA FIX: Limit feed length to prevent excessively long messages
	if state.PendingFeed and #state.PendingFeed > 1000 then
		state.PendingFeed = state.PendingFeed:sub(1, 997) .. "..."
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
				-- AAA FIX: Nil safety check
				local partner = state.Relationships.partner
				if partner and type(partner) == "table" and partner.id == rel.id then
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

	-- AAA FIX: Enhanced nil safety check
	local partner = state.Relationships.partner
	local partnerInvalid = partner and type(partner) == "table" and partner.id and not state.Relationships[partner.id]
	if shouldClearPartner or partnerInvalid then
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #601: ALWAYS provide a specific death reason
	-- User complaint: "When I died it didn't say a specific reason"
	-- ═══════════════════════════════════════════════════════════════════════════════
	local deathCause = deathInfo and deathInfo.cause
	
	-- If no cause provided, generate one based on age and health
	if not deathCause or deathCause == "" or deathCause == "Unknown causes" or deathCause == "unknown causes" then
		local age = state.Age or 0
		local health = (stats.Health or state.Health or 50)
		
		if age >= 90 then
			-- Very old - natural causes
			local oldAgeReasons = {
				"Old age - passed peacefully",
				"Natural causes at a ripe old age",
				"Died peacefully in their sleep",
				"Heart gave out after a long life",
				"Age-related organ failure",
			}
			deathCause = oldAgeReasons[math.random(1, #oldAgeReasons)]
		elseif age >= 75 then
			local seniorReasons = {
				"Old age",
				"Natural causes",
				"Heart failure",
				"Stroke",
				"Pneumonia",
			}
			deathCause = seniorReasons[math.random(1, #seniorReasons)]
		elseif health < 20 then
			local healthReasons = {
				"Health complications",
				"Organ failure",
				"Critical illness",
				"Medical emergency",
			}
			deathCause = healthReasons[math.random(1, #healthReasons)]
		elseif flags.has_cancer then
			deathCause = "Cancer"
		elseif flags.has_heart_disease or flags.heart_disease then
			deathCause = "Heart disease"
		elseif flags.drug_addiction or flags.substance_abuse then
			deathCause = "Overdose"
		else
			-- Generic but specific
			local genericReasons = {
				"Sudden cardiac arrest",
				"Unexpected illness",
				"Medical complications",
				"Natural causes",
			}
			deathCause = genericReasons[math.random(1, #genericReasons)]
		end
	end
	
	return {
		age = state.Age,
		year = state.Year,
		cause = deathCause,
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
	-- CRITICAL FIX: Added senior_coach position between coach and head_coach
	{ id = "senior_coach", name = "Senior Coach", company = "Sports Organization", emoji = "📋", salary = 85000, minAge = 30, requirement = "bachelor", category = "sports",
		minStats = { Smarts = 55 }, difficulty = 5, 
		requiresFlags = { "coach_experience", "coaching_career" },
		grantsFlags = { "senior_coaching", "coaching_career" },
		description = "Experienced coaching position" },
	{ id = "head_coach", name = "Head Coach", company = "Pro Team", emoji = "📋", salary = 1500000, minAge = 40, requirement = "bachelor", category = "sports",
		minStats = { Smarts = 65 }, difficulty = 8, 
		requiresFlags = { "senior_coaching", "coaching_career" }, -- CRITICAL FIX: Must have senior coaching experience
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
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- INFLUENCER CAREER PATH - COMPLETELY FREE!
	-- CRITICAL FIX #540: User feedback "FREE PLAYERS CANT GET BORED"
	-- Influencer is FREE - everyone wants to be an influencer, keeps them playing!
	-- Celebrity gamepass is for HOLLYWOOD (actors, rappers, musicians)
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "micro_influencer", name = "Micro-Influencer", company = "Social Media", emoji = "📊", salary = 15000, minAge = 14, requirement = nil, category = "entertainment",
		difficulty = 3, requiresFlags = { "content_creator" }, grantsFlags = { "influencer", "small_following" }, isFameCareer = true,
		description = "Building a small but engaged following" },
	{ id = "rising_influencer", name = "Rising Influencer", company = "Social Media", emoji = "📈", salary = 25000, minAge = 15, requirement = nil, category = "entertainment",
		difficulty = 4, requiresFlags = { "influencer" }, grantsFlags = { "growing_audience", "brand_potential" }, isFameCareer = true,
		description = "Your audience is growing fast!" },
	{ id = "established_influencer", name = "Established Influencer", company = "Brand Partnerships", emoji = "🤝", salary = 150000, minAge = 17, requirement = nil, category = "entertainment",
		difficulty = 6, requiresFlags = { "growing_audience" }, grantsFlags = { "brand_deals", "influencer_marketing" }, isFameCareer = true,
		description = "Brands want to work with you!" },
	{ id = "major_influencer", name = "Major Influencer", company = "Management Agency", emoji = "⭐", salary = 750000, minAge = 18, requirement = nil, category = "entertainment",
		difficulty = 7, requiresFlags = { "brand_deals" }, grantsFlags = { "major_following", "celebrity_status" }, isFameCareer = true,
		description = "Millions of followers!" },
	{ id = "mega_influencer", name = "Mega Influencer", company = "Global Brand", emoji = "🌟", salary = 5000000, minAge = 20, requirement = nil, category = "entertainment",
		difficulty = 9, requiresFlags = { "major_following" }, grantsFlags = { "mega_fame", "household_name" }, isFameCareer = true,
		description = "A household name on social media!" },
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- STREAMER CAREER PATH - COMPLETELY FREE!
	-- CRITICAL FIX #540: User feedback "FREE PLAYERS CANT GET BORED"
	-- Streaming is FREE - super popular with young players, keeps them engaged!
	-- They'll want God Mode when stats are low, or Time Machine for mistakes
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "hobbyist_streamer", name = "Hobbyist Streamer", company = "Twitch", emoji = "🎥", salary = 1000, minAge = 13, requirement = nil, category = "entertainment",
		difficulty = 1, grantsFlags = { "streamer", "broadcaster", "pursuing_streaming" }, isFameCareer = true,
		description = "Stream as a hobby - just for fun!" },
	{ id = "new_streamer", name = "New Streamer", company = "Twitch", emoji = "🎮", salary = 3000, minAge = 13, requirement = nil, category = "entertainment",
		difficulty = 1, grantsFlags = { "streamer", "broadcaster", "pursuing_streaming" }, isFameCareer = true,
		description = "Just started streaming" },
	{ id = "affiliate_streamer", name = "Affiliate Streamer", company = "Twitch", emoji = "💜", salary = 8000, minAge = 14, requirement = nil, category = "entertainment",
		difficulty = 3, requiresFlags = { "streamer" }, grantsFlags = { "affiliate", "monetized" }, isFameCareer = true,
		description = "Earned affiliate status!" },
	{ id = "partner_streamer", name = "Partner Streamer", company = "Twitch", emoji = "✅", salary = 15000, minAge = 16, requirement = nil, category = "entertainment",
		difficulty = 5, requiresFlags = { "affiliate" }, grantsFlags = { "partner", "verified_streamer" }, isFameCareer = true,
		description = "Full partner with perks!" },
	{ id = "popular_streamer", name = "Popular Streamer", company = "Multi-Platform", emoji = "📺", salary = 150000, minAge = 17, requirement = nil, category = "entertainment",
		difficulty = 6, requiresFlags = { "partner" }, grantsFlags = { "popular_broadcaster", "streaming_income" }, isFameCareer = true,
		description = "Thousands watch your streams!" },
	{ id = "famous_streamer", name = "Famous Streamer", company = "Exclusive Contract", emoji = "⭐", salary = 1000000, minAge = 18, requirement = nil, category = "entertainment",
		difficulty = 8, requiresFlags = { "popular_broadcaster" }, grantsFlags = { "famous_streamer", "platform_face" }, isFameCareer = true,
		description = "One of the biggest streamers!" },
	{ id = "streaming_legend", name = "Streaming Legend", company = "Hall of Fame", emoji = "👑", salary = 10000000, minAge = 22, requirement = nil, category = "entertainment",
		difficulty = 10, requiresFlags = { "famous_streamer" }, grantsFlags = { "streaming_legend", "icon" }, isFameCareer = true,
		description = "A legend of the streaming world!" },
	
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- ATHLETE CAREER PATH - COMPLETELY FREE!
	-- CRITICAL FIX #540: User feedback "THATS SO BORING FOR FREE PLAYERS"
	-- Athletes are FREE to keep players engaged and having fun!
	-- This hooks players into the game - they buy God Mode/Time Machine later
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "amateur_athlete", name = "Amateur", company = "Local Leagues", emoji = "🏃", salary = 250, minAge = 14, requirement = nil, category = "entertainment",
		difficulty = 2, minStats = { Health = 60 }, grantsFlags = { "athlete", "amateur_status" }, isFameCareer = true,
		description = "Competing at amateur level" },
	{ id = "college_athlete", name = "College Athlete", company = "University", emoji = "🎓", salary = 0, minAge = 18, requirement = nil, category = "entertainment",
		difficulty = 4, minStats = { Health = 70 }, requiresFlags = { "amateur_status" }, grantsFlags = { "college_sports", "scholarship" }, isFameCareer = true,
		description = "Playing for your college team" },
	{ id = "pro_prospect", name = "Pro Prospect", company = "Draft Pool", emoji = "📋", salary = 50000, minAge = 20, requirement = nil, category = "entertainment",
		difficulty = 6, minStats = { Health = 75 }, requiresFlags = { "college_sports" }, grantsFlags = { "draft_eligible", "pro_potential" }, isFameCareer = true,
		description = "Scouts are watching!" },
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
		-- Content Creator / Streaming
		["new content creator"] = "new_influencer",
		["new_content_creator"] = "new_influencer",
		["content creator"] = "new_influencer",
		["hobbyist streamer"] = "hobbyist_streamer",
		["hobbyist_streamer"] = "hobbyist_streamer",
		["streamer"] = "hobbyist_streamer",
		["youtuber"] = "new_influencer",
		["content_creator"] = "new_influencer",
		["vlogger"] = "new_influencer",
		["tiktoker"] = "new_influencer",
		["influencer"] = "new_influencer",
		["new influencer"] = "new_influencer",
		
		-- Esports/Gaming career aliases
		["esports player"] = "casual_gamer",
		["pro gamer"] = "pro_gamer",
		["professional gamer"] = "pro_gamer",
		["gamer"] = "casual_gamer",
		["esports"] = "casual_gamer",
		["esports_player"] = "casual_gamer",
		["gaming pro"] = "pro_gamer",
		
		-- Music/Entertainment aliases
		["underground rapper"] = "underground_rapper",
		["singer"] = "musician_local",
		["performer"] = "musician_local",
		["rapper"] = "underground_rapper",
		["hip hop artist"] = "underground_rapper",
		["hip_hop_artist"] = "underground_rapper",
		["musician"] = "musician_local",
		["music artist"] = "musician_local",
		["band member"] = "musician_local",
		["dj"] = "musician_local",
		
		-- Acting
		["actor"] = "actor_extra",
		["actress"] = "actor_extra",
		["background actor"] = "actor_extra",
		["film actor"] = "actor_extra",
		["tv actor"] = "actor_extra",
		
		-- Tech jobs
		["programmer"] = "junior_developer",
		["coder"] = "junior_developer",
		["software engineer"] = "developer",
		["web developer"] = "web_developer",
		["developer"] = "developer",
		["software developer"] = "developer",
		["it support"] = "it_support",
		["tech support"] = "it_support",
		["computer tech"] = "it_support",
		["hacker"] = "cybersecurity_analyst",
		
		-- Medical
		["doctor"] = "resident_doctor",
		["nurse"] = "nurse",
		["surgeon"] = "surgeon",
		["dentist"] = "dentist",
		["vet"] = "veterinarian",
		["veterinarian"] = "veterinarian",
		["therapist"] = "therapist",
		["psychiatrist"] = "psychiatrist",
		["pharmacist"] = "pharmacist",
		
		-- Legal
		["lawyer"] = "junior_lawyer",
		["attorney"] = "junior_lawyer",
		["paralegal"] = "paralegal",
		["judge"] = "judge",
		
		-- Emergency services
		["cop"] = "police_officer",
		["police"] = "police_officer",
		["firefighter"] = "firefighter",
		["emt"] = "paramedic",
		["paramedic"] = "paramedic",
		
		-- Business
		["manager"] = "office_manager",
		["ceo"] = "ceo",
		["boss"] = "office_manager",
		["executive"] = "project_manager",
		["accountant"] = "junior_accountant",
		["banker"] = "investment_banker_jr",
		
		-- Retail/Service
		["waiter"] = "server",
		["waitress"] = "server",
		["barista"] = "barista",
		["bartender"] = "bartender",
		["cashier"] = "cashier",
		["fast food worker"] = "fastfood",
		["fast food"] = "fastfood",
		["mcdonalds"] = "fastfood",
		
		-- Misc
		["teacher"] = "teacher",
		["pilot"] = "junior_pilot",
		["writer"] = "journalist_jr",
		["journalist"] = "journalist_jr",
		["photographer"] = "photographer",
		["chef"] = "sous_chef",
		["cook"] = "line_cook",
	}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- AAA FIX: REMOVED JOB HANDLING
	-- These jobs were removed for Roblox TOS compliance but players may still try
	-- Return a special marker so handleJobApplication can give a proper message
	-- ═══════════════════════════════════════════════════════════════════════════════
	local removedJobs = {
		["casino_dealer"] = "Gambling jobs were removed to comply with Roblox policies.",
		["casino_worker"] = "Gambling jobs were removed to comply with Roblox policies.",
		["blackjack_dealer"] = "Gambling jobs were removed to comply with Roblox policies.",
		["poker_dealer"] = "Gambling jobs were removed to comply with Roblox policies.",
		["gambler"] = "Gambling jobs were removed to comply with Roblox policies.",
		["loan_shark"] = "This job was removed to comply with Roblox policies.",
	}
	
	local removedMsg = removedJobs[query]
	if removedMsg then
		-- Return a fake job that will be caught by handleJobApplication
		return { 
			id = "_removed_job", 
			name = query, 
			removed = true, 
			removedMessage = removedMsg 
		}
	end
	
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
	
	-- CRITICAL FIX: Missing combat activities (caused "Unknown activity" error)
	pick_fight = {
		stats = { Happiness = -2, Health = -5 },
		feed = "got into a fight",
		cost = 0,
		requiresAge = 14,
		isCombat = true,
		riskOfArrest = 0.15, -- 15% chance of arrest
	},
	club_fight = {
		stats = { Happiness = -3, Health = -8 },
		feed = "got into a club fight",
		cost = 0,
		requiresAge = 21,
		isCombat = true,
		riskOfArrest = 0.25, -- 25% chance of arrest
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: ROMANCE & DATING ACTIVITIES - These were completely missing!
	-- ═══════════════════════════════════════════════════════════════════════════
	look_for_love = { 
		stats = { Happiness = 5 }, 
		feed = "looked for love",
		cost = 0,
		requiresAge = 16,
		requiresSingle = true,
		isRomanceSearch = true, -- Special handler will create partner if lucky
	},
	online_dating = { 
		stats = { Happiness = 3 }, 
		feed = "tried online dating",
		cost = 0,
		requiresAge = 18,
		requiresSingle = true,
		isRomanceSearch = true,
	},
	speed_dating = {
		stats = { Happiness = 4 },
		feed = "went speed dating",
		cost = 50,
		requiresAge = 18,
		requiresSingle = true,
		isRomanceSearch = true,
	},
	go_on_date = {
		stats = { Happiness = 8 },
		feed = "went on a romantic date! 💕",
		cost = 50,
		requiresAge = 16,
		requiresPartner = true,
		relationshipBoostPartner = 8,
	},
	romantic_dinner = {
		stats = { Happiness = 10 },
		feed = "had a romantic dinner! 🍷",
		cost = 150,
		requiresAge = 18,
		requiresPartner = true,
		relationshipBoostPartner = 12,
	},
	spend_time_partner = {
		stats = { Happiness = 6 },
		feed = "spent quality time with your partner! 💞",
		cost = 0,
		requiresAge = 14,
		requiresPartner = true,
		relationshipBoostPartner = 5,
	},
	flirt = {
		stats = { Happiness = 4 },
		feed = "flirted with someone! 😉",
		cost = 0,
		requiresAge = 14,
		requiresSingle = true,
		isRomanceSearch = true,
	},
	propose = {
		stats = { Happiness = 15 },
		feed = "proposed! 💍",
		cost = 500,
		requiresAge = 18,
		requiresPartner = true,
		blockedByFlag = "engaged",
		blockedByFlag2 = "married",
		isProposal = true, -- Special handler
		-- CRITICAL FIX: Add cooldown to prevent proposal spam
		cooldownYears = 1, -- Can only propose once per year
		showResult = true, -- CRITICAL: Force show result card
	},
	plan_wedding = {
		stats = { Happiness = 20 },
		feed = "planned your dream wedding! 💒",
		cost = 5000,
		requiresAge = 18,
		requiresFlag = "engaged",
		blockedByFlag = "married",
		isWedding = true, -- Special handler
		setFlags = { married = true },
	},
	-- Friend activities
	make_friends = {
		stats = { Happiness = 5 },
		feed = "made new friends! 👋",
		cost = 0,
		requiresAge = 5,
		isFriendMaking = true, -- Special handler will create friend
	},
	hang_with_friends = {
		stats = { Happiness = 6 },
		feed = "hung out with friends! 🤝",
		cost = 0,
		requiresAge = 5,
		relationshipBoostFriend = 5,
	},
	friend_trip = {
		stats = { Happiness = 12, Health = 3 },
		feed = "went on a trip with friends! 🚗",
		cost = 500,
		requiresAge = 16,
		relationshipBoostFriend = 10,
	},
	
	tv = { stats = { Happiness = 2 }, feed = "binged a show", cost = 0 },
	games = { stats = { Happiness = 3, Smarts = 1 }, feed = "played video games", cost = 0 },
	movies = { stats = { Happiness = 3 }, feed = "watched a movie", cost = 20 },
	concert = { stats = { Happiness = 5 }, feed = "went to a concert", cost = 150 },
	vacation = { stats = { Happiness = 10, Health = 4 }, feed = "took a vacation", cost = 2000 },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- AAA FIX: Added missing vacation types referenced in events
	-- Users were getting "Choice eligibility failed" because activities didn't exist
	-- ═══════════════════════════════════════════════════════════════════════════
	beach_vacation = { 
		stats = { Happiness = 12, Health = 5 }, 
		feed = "went on a beach vacation!", 
		cost = 500 
	},
	family_vacation = { 
		stats = { Happiness = 10, Health = 3 }, 
		feed = "went on a family vacation!", 
		cost = 800 
	},
	summer_camp = { 
		stats = { Happiness = 8, Health = 4, Smarts = 2 }, 
		feed = "went to summer camp!", 
		cost = 300,
		requiresAge = 6,
		maxAge = 17,
		setFlags = { camp_experience = true, summer_camp = true },
	},
	sports_lessons = {
		stats = { Health = 5, Happiness = 3 },
		feed = "took sports lessons!",
		cost = 100,
		setFlags = { athlete = true },
	},
	swimming_lessons = {
		stats = { Health = 4, Happiness = 3 },
		feed = "took swimming lessons!",
		cost = 100,
		setFlags = { can_swim = true },
	},
	dance_lessons = {
		stats = { Health = 3, Happiness = 4, Looks = 2 },
		feed = "took dance lessons!",
		cost = 100,
		setFlags = { dancer = true, dance_experience = true },
	},
	art_lessons = {
		stats = { Smarts = 2, Happiness = 3 },
		feed = "took art lessons!",
		cost = 100,
		setFlags = { artistic = true, art_experience = true },
	},
	buy_sports_car = {
		stats = { Happiness = 15 },
		feed = "bought a sports car!",
		cost = 5000,
		requiresAge = 16,
		setFlags = { has_car = true, has_sports_car = true },
	},
	tutoring = {
		stats = { Smarts = 5 },
		feed = "got tutoring!",
		cost = 200,
	},
	private_school = {
		stats = { Smarts = 3 },
		feed = "enrolled in private school!",
		cost = 5000,
		requiresAge = 5,
		maxAge = 17,
		setFlags = { private_school = true },
	},
	
	-- CRITICAL FIX: Missing activities from client (caused "Unknown activity" error)
	martial_arts = { stats = { Health = 5, Looks = 2 }, feed = "practiced martial arts", cost = 100 },
	karaoke = { stats = { Happiness = 4 }, feed = "sang karaoke", cost = 20 },
	arcade = { stats = { Happiness = 4, Smarts = 1 }, feed = "played games at the arcade", cost = 30 },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- AAA FIX: FRIEND INTERACTION ACTIVITIES
	-- These reset the friend contact timer to prevent friend anger events
	-- Like the competition game - friends get angry if you don't talk to them!
	-- ═══════════════════════════════════════════════════════════════════════════
	hang_out_friend = {
		stats = { Happiness = 6 },
		feed = "hung out with a friend!",
		cost = 20,
		friendInteraction = true, -- Resets friend contact timer
		relationshipBoostFriend = 5, -- Boosts random friend relationship
	},
	call_friend = {
		stats = { Happiness = 3 },
		feed = "called a friend to catch up!",
		cost = 0,
		friendInteraction = true,
		relationshipBoostFriend = 2,
	},
	text_friend = {
		stats = { Happiness = 2 },
		feed = "texted with friends!",
		cost = 0,
		friendInteraction = true,
		relationshipBoostFriend = 1,
	},
	party_with_friends = {
		stats = { Happiness = 10, Health = -2 },
		feed = "partied with friends!",
		cost = 100,
		requiresAge = 18,
		friendInteraction = true,
		relationshipBoostFriend = 8,
	},
	dinner_with_friend = {
		stats = { Happiness = 5 },
		feed = "had dinner with a friend!",
		cost = 50,
		friendInteraction = true,
		relationshipBoostFriend = 4,
	},
	video_call_friend = {
		stats = { Happiness = 4 },
		feed = "had a video call with a friend!",
		cost = 0,
		friendInteraction = true,
		relationshipBoostFriend = 3,
	},
	movie_with_friend = {
		stats = { Happiness = 5 },
		feed = "watched a movie with a friend!",
		cost = 25,
		friendInteraction = true,
		relationshipBoostFriend = 4,
	},
	road_trip_friends = {
		stats = { Happiness = 12, Health = -1 },
		feed = "went on a road trip with friends!",
		cost = 300,
		requiresAge = 16,
		friendInteraction = true,
		relationshipBoostFriend = 10,
	},
	gaming_session = {
		stats = { Happiness = 5 },
		feed = "had a gaming session with friends!",
		cost = 0,
		friendInteraction = true,
		relationshipBoostFriend = 3,
	},
	study_group = {
		stats = { Happiness = 2, Smarts = 4 },
		feed = "studied with friends!",
		cost = 0,
		requiresAge = 10,
		maxAge = 25,
		friendInteraction = true,
		relationshipBoostFriend = 2,
	},
	reconcile_friend = {
		stats = { Happiness = 8 },
		feed = "made up with an angry friend!",
		cost = 50, -- Gift/apology
		friendReconcile = true, -- Special: fixes angry friend
		relationshipBoostFriend = 15,
	},
	apologize_friend = {
		stats = { Happiness = 3 },
		feed = "apologized to a friend you've been neglecting!",
		cost = 0,
		friendReconcile = true,
		relationshipBoostFriend = 10,
	},
	
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
	-- CRITICAL FIX: DATING ROYALTY ACTIVITIES
	-- For players who are dating a royal but not yet royalty themselves
	-- These are called from the "Dating Royal" tab in ActivitiesScreen
	-- ═══════════════════════════════════════════════════════════════════════════
	royal_date = {
		stats = { Happiness = 8 },
		feed = "went on a romantic date with your royal partner 💑",
		cost = 0,
		requiresFlag = "dating_royalty",
		requiresAge = 16,
		relationshipBonus = 5,
	},
	palace_visit = {
		stats = { Happiness = 10, Looks = 5 },
		feed = "visited the royal palace - what luxury! 🏰",
		cost = 0,
		requiresFlag = "dating_royalty",
		requiresAge = 16,
	},
	meet_royal_family = {
		stats = { Happiness = 3 },
		feed = "met the royal family... hope they like you! 👨‍👩‍👧‍👦",
		cost = 0,
		requiresFlag = "dating_royalty",
		requiresAge = 16,
		relationshipBonus = 3,
		risky = true, -- Can go poorly
	},
	royal_event = {
		stats = { Happiness = 5 },
		feed = "attended a glamorous royal event 🎭",
		cost = 500,
		requiresFlag = "dating_royalty",
		requiresAge = 16,
		fameBonus = 5,
	},
	learn_etiquette = {
		stats = { Smarts = 5, Looks = 3 },
		feed = "learned proper royal etiquette and protocol 📖",
		cost = 200,
		requiresFlag = "dating_royalty",
		requiresAge = 16,
		setFlags = { royal_etiquette = true },
	},
	royal_shopping = {
		stats = { Looks = 8, Happiness = 5 },
		feed = "went on a royal shopping spree! Designer everything! 👗",
		cost = 5000,
		requiresFlag = "dating_royalty",
		requiresAge = 16,
	},
	romantic_getaway = {
		stats = { Happiness = 12 },
		feed = "took a romantic getaway with your royal partner ✈️",
		cost = 10000,
		requiresFlag = "dating_royalty",
		requiresAge = 18,
		relationshipBonus = 8,
	},
	propose_marriage = {
		stats = { Happiness = 20 },
		feed = "proposed marriage to your royal partner! 💍",
		cost = 50000,
		requiresFlag = "dating_royalty",
		requiresAge = 18,
		blockedByFlag = "married",
		isProposal = true, -- Special handler needed
		setFlags = { proposed_to_royal = true },
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
	-- ═══════════════════════════════════════════════════════════════════════════
	-- PETTY CRIMES (low risk) - These set basic criminal flags for career unlocks!
	-- User complaint: "petty crimes like assault pick pocket let u become a smuggler"
	-- ═══════════════════════════════════════════════════════════════════════════
	porch_pirate = { 
		risk = 20, reward = { 30, 200 }, jail = { min = 0.2, max = 1 },
		name = "Porch Pirate", -- CRITICAL FIX: Added name to prevent "Unknown crime"
		grantsFlags = { "petty_criminal", "crime_experience", "criminal_background" },
	},
	shoplift = { 
		risk = 25, reward = { 20, 150 }, jail = { min = 0.5, max = 2 },
		name = "Shoplifting",
		grantsFlags = { "petty_criminal", "crime_experience", "criminal_background" },
	},
	pickpocket = { 
		risk = 35, reward = { 30, 300 }, jail = { min = 0.5, max = 2 }, 
		hasMinigame = true, minigameType = "qte",
		name = "Pickpocketing",
		grantsFlags = { "petty_criminal", "crime_experience", "criminal_background", "street_thief" },
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- VIOLENCE CRIMES - Combat-based
	-- ═══════════════════════════════════════════════════════════════════════════
	assault = { 
		risk = 45, reward = { 0, 500 }, jail = { min = 1, max = 5 }, -- FIXED: Reduced from insane 20-100 years
		name = "Assault",
		hasMinigame = true, minigameType = "combat",
		grantsFlags = { "violent_criminal", "crime_experience", "criminal_background", "assault_record" },
	},
	mugging = { -- CRITICAL FIX: Was missing! Client sends this ID
		risk = 55, reward = { 50, 500 }, jail = { min = 1, max = 4 },
		name = "Mugging",
		hasMinigame = true, minigameType = "combat",
		grantsFlags = { "violent_criminal", "crime_experience", "criminal_background", "robbery_record" },
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- PROPERTY CRIMES (medium risk)
	-- ═══════════════════════════════════════════════════════════════════════════
	burglary = { 
		risk = 50, reward = { 500, 5000 }, jail = { min = 2, max = 5 }, 
		hasMinigame = true, minigameType = "heist",
		name = "Burglary",
		grantsFlags = { "property_criminal", "crime_experience", "criminal_background", "burglary_record" },
	},
	gta = { 
		risk = 60, reward = { 2000, 20000 }, jail = { min = 3, max = 7 }, 
		hasMinigame = true, minigameType = "getaway",
		name = "Grand Theft Auto",
		grantsFlags = { "car_thief", "crime_experience", "criminal_background", "gta_record" },
	},
	car_theft = { 
		risk = 50, reward = { 3000, 15000 }, jail = { min = 2, max = 5 },
		name = "Car Theft",
		hasMinigame = true, minigameType = "getaway",
		grantsFlags = { "car_thief", "crime_experience", "criminal_background" },
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- WHITE COLLAR CRIMES
	-- ═══════════════════════════════════════════════════════════════════════════
	tax_fraud = { 
		risk = 35, reward = { 5000, 50000 }, jail = { min = 1, max = 5 },
		name = "Tax Fraud",
		grantsFlags = { "white_collar_criminal", "crime_experience", "criminal_background", "fraud_record" },
	},
	identity_theft = { 
		risk = 40, reward = { 1000, 20000 }, jail = { min = 2, max = 6 },
		name = "Identity Theft",
		hasMinigame = true, minigameType = "hacking",
		grantsFlags = { "white_collar_criminal", "crime_experience", "criminal_background", "hacker" },
	},
	fraud = { 
		risk = 40, reward = { 2000, 20000 }, jail = { min = 1, max = 5 },
		name = "Fraud",
		grantsFlags = { "white_collar_criminal", "crime_experience", "criminal_background", "fraud_record" },
	},
	embezzlement = { 
		risk = 45, reward = { 10000, 100000 }, jail = { min = 3, max = 10 },
		name = "Embezzlement",
		grantsFlags = { "white_collar_criminal", "crime_experience", "criminal_background" },
	},
	counterfeiting = { 
		risk = 50, reward = { 3000, 25000 }, jail = { min = 2, max = 7 },
		name = "Counterfeiting",
		grantsFlags = { "white_collar_criminal", "crime_experience", "criminal_background" },
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- SERIOUS CRIMES
	-- ═══════════════════════════════════════════════════════════════════════════
	illegal_dealing = { 
		risk = 55, reward = { 500, 10000 }, jail = { min = 3, max = 10 },
		name = "Illegal Dealing",
		grantsFlags = { "dealer", "crime_experience", "criminal_background", "smuggler_potential" },
	},
	smuggling = { 
		risk = 55, reward = { 500, 10000 }, jail = { min = 3, max = 10 },
		name = "Smuggling",
		grantsFlags = { "smuggler", "crime_experience", "criminal_background" },
	},
	extortion = { 
		risk = 60, reward = { 2000, 30000 }, jail = { min = 3, max = 8 },
		name = "Extortion",
		hasMinigame = true, minigameType = "debate",
		grantsFlags = { "extortionist", "crime_experience", "criminal_background", "intimidation_skills" },
	},
	intimidation = { 
		risk = 60, reward = { 2000, 30000 }, jail = { min = 3, max = 8 },
		name = "Intimidation",
		grantsFlags = { "intimidator", "crime_experience", "criminal_background" },
	},
	arson = { 
		risk = 70, reward = { 0, 1000 }, jail = { min = 5, max = 15 },
		name = "Arson",
		hasMinigame = true, minigameType = "qte",
		grantsFlags = { "arsonist", "crime_experience", "criminal_background" },
	},
	hacking = { 
		risk = 45, reward = { 5000, 50000 }, jail = { min = 2, max = 8 }, 
		hasMinigame = true, minigameType = "hacking",
		name = "Hacking",
		grantsFlags = { "hacker", "crime_experience", "criminal_background", "tech_criminal" },
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- MAJOR CRIMES (high risk)
	-- ═══════════════════════════════════════════════════════════════════════════
	bank_robbery = { 
		risk = 80, reward = { 10000, 500000 }, jail = { min = 5, max = 12 }, 
		hasMinigame = true, minigameType = "heist",
		name = "Bank Robbery",
		grantsFlags = { "bank_robber", "crime_experience", "criminal_background", "major_criminal" },
	},
	kidnapping = { 
		risk = 85, reward = { 10000, 200000 }, jail = { min = 10, max = 25 },
		name = "Kidnapping",
		hasMinigame = true, minigameType = "combat",
		grantsFlags = { "kidnapper", "crime_experience", "criminal_background", "major_criminal" },
	},
	ransom = { 
		risk = 85, reward = { 10000, 200000 }, jail = { min = 10, max = 25 },
		name = "Ransom",
		grantsFlags = { "kidnapper", "crime_experience", "criminal_background", "major_criminal" },
	},
	murder = { 
		risk = 95, reward = { 0, 5000 }, jail = { min = 25, max = 100 },
		name = "Murder",
		hasMinigame = true, minigameType = "combat",
		grantsFlags = { "murderer", "crime_experience", "criminal_background", "violent_criminal" },
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- PRISON CRIMES - Can be committed while incarcerated
	-- ═══════════════════════════════════════════════════════════════════════════
	prison_assault = { 
		risk = 60, reward = { 0, 200 }, jail = { min = 1, max = 3 }, 
		isPrisonCrime = true,
		name = "Prison Assault",
	},
	prison_riot = { 
		risk = 80, reward = { 0, 0 }, jail = { min = 2, max = 5 }, 
		isPrisonCrime = true,
		name = "Prison Riot",
	},
	prison_contraband = { 
		risk = 50, reward = { 100, 1000 }, jail = { min = 1, max = 2 }, 
		isPrisonCrime = true,
		name = "Prison Contraband",
	},
	prison_gang_violence = { 
		risk = 70, reward = { 0, 500 }, jail = { min = 2, max = 4 }, 
		isPrisonCrime = true,
		name = "Prison Gang Violence",
	},
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #AAA-MEGA-3: ServiceCareerEvents for entry/service/retail workers
-- Movie ushers, cashiers, servers, etc. don't have office meetings or email overload!
-- They deal with customers, long shifts, and service industry challenges.
-- ═══════════════════════════════════════════════════════════════════════════════
local ServiceCareerEvents = {
	{
		id = "service_rude_customer",
		title = "Difficult Customer",
		emoji = "😤",
		text = "A customer is being incredibly rude and demanding, yelling at you over something minor.",
		question = "How do you handle this?",
		cooldown = 2,
		maxOccurrences = 4,
		choices = {
			{ text = "Stay calm and professional", deltas = { Happiness = -2, Smarts = 2 }, setFlags = { service_professional = true }, feedText = "You kept your cool with a difficult customer." },
			{ text = "Get a manager", deltas = { Happiness = 1 }, feedText = "You let your manager handle the situation." },
			{ text = "Walk away for a moment", deltas = { Happiness = 2 }, feedText = "You took a moment to collect yourself." },
		},
	},
	{
		id = "service_long_shift",
		title = "Double Shift",
		emoji = "😴",
		text = "Your coworker called in sick. Your boss asks if you can cover their shift too.",
		question = "What do you say?",
		cooldown = 3,
		maxOccurrences = 3,
		choices = {
			{ text = "Work the double", deltas = { Happiness = -4, Money = 100 }, setFlags = { service_reliable = true }, feedText = "You worked a grueling double shift." },
			{ text = "Politely decline", deltas = { Happiness = 2 }, feedText = "You protected your personal time." },
			{ text = "Agree but leave early if slow", deltas = { Happiness = 0 }, feedText = "You compromised on staying flexible." },
		},
	},
	{
		id = "service_tip_dispute",
		title = "Tip Dispute",
		emoji = "💵",
		text = "A customer claims they left a big tip but the tip jar is short. They blame you.",
		question = "What do you do?",
		cooldown = 4,
		maxOccurrences = 2,
		choices = {
			{ text = "Apologize even though it's not your fault", deltas = { Happiness = -2 }, feedText = "You apologized to calm the situation." },
			{ text = "Explain you didn't touch their tip", deltas = { Happiness = 1 }, setFlags = { service_honest = true }, feedText = "You stood your ground honestly." },
			{ text = "Ask manager to check cameras", deltas = { Smarts = 2 }, feedText = "You suggested checking the security footage." },
		},
	},
	{
		id = "service_coworker_lazy",
		title = "Slacking Coworker",
		emoji = "😒",
		text = "Your coworker keeps disappearing on breaks while you pick up their slack.",
		question = "What do you do about it?",
		cooldown = 3,
		maxOccurrences = 2,
		choices = {
			{ text = "Confront them directly", deltas = { Happiness = 1 }, setFlags = { service_assertive = true }, feedText = "You called them out on their slacking." },
			{ text = "Tell the manager", deltas = { Happiness = 0 }, feedText = "You reported the issue to management." },
			{ text = "Just keep working harder", deltas = { Happiness = -3 }, setFlags = { service_pushover = true }, feedText = "You said nothing and kept covering for them." },
		},
	},
	{
		id = "service_small_raise",
		title = "Raise Discussion",
		emoji = "💰",
		text = "You've been working here for a while. Time to ask for a raise?",
		question = "How do you approach it?",
		cooldown = 5,
		maxOccurrences = 2,
		choices = {
			{ text = "Ask confidently", deltas = { Happiness = 2, Money = 50 }, setFlags = { service_confident = true }, feedText = "You asked for and got a small raise!" },
			{ text = "Wait for annual review", deltas = { Happiness = -1 }, feedText = "You decided to wait for the formal review process." },
			{ text = "Hint at it casually", deltas = { Happiness = 0 }, feedText = "You dropped some hints about compensation." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #AAA-MEGA-4: CreativeCareerEvents for creative workers
-- Artists, designers, photographers, etc. have different challenges than office workers.
-- NOTE: PR Crisis and brand events should ONLY fire for people with public brands!
-- ═══════════════════════════════════════════════════════════════════════════════
local CreativeCareerEvents = {
	{
		id = "creative_client_revision",
		title = "Client Revisions",
		emoji = "🎨",
		text = "The client wants 'just one more small change' for the tenth time.",
		question = "How do you handle revision requests?",
		cooldown = 2,
		maxOccurrences = 4,
		choices = {
			{ text = "Make all the changes", deltas = { Happiness = -3 }, feedText = "You made all their changes again." },
			{ text = "Explain the revision limit", deltas = { Happiness = 2, Smarts = 2 }, setFlags = { creative_boundaries = true }, feedText = "You professionally explained your revision policy." },
			{ text = "Suggest a compromise", deltas = { Happiness = 1 }, feedText = "You found a middle ground with the client." },
		},
	},
	{
		id = "creative_tight_deadline",
		title = "Tight Deadline",
		emoji = "⏰",
		text = "A major project deadline got moved up by a week. Quality or speed?",
		question = "What do you prioritize?",
		cooldown = 3,
		maxOccurrences = 3,
		choices = {
			{ text = "Crunch to meet deadline", deltas = { Health = -3, Happiness = -2 }, setFlags = { creative_reliable = true }, feedText = "You pulled all-nighters to deliver on time." },
			{ text = "Ask for deadline extension", deltas = { Happiness = 2 }, feedText = "You negotiated more time for quality work." },
			{ text = "Deliver what you can", deltas = { Happiness = 0 }, feedText = "You delivered your best work within the timeframe." },
		},
	},
	{
		id = "creative_portfolio_review",
		title = "Portfolio Review",
		emoji = "📂",
		text = "A potential client wants to see your recent work. Your portfolio is outdated.",
		question = "What do you do?",
		cooldown = 4,
		maxOccurrences = 2,
		choices = {
			{ text = "Update it immediately", deltas = { Happiness = 1, Smarts = 2 }, setFlags = { creative_organized = true }, feedText = "You updated your portfolio and impressed them!" },
			{ text = "Send what you have", deltas = { Happiness = -1 }, feedText = "You sent your outdated portfolio anyway." },
			{ text = "Ask for more time", deltas = { Happiness = 0 }, feedText = "You asked for a few days to prepare." },
		},
	},
	{
		id = "creative_inspiration_block",
		title = "Creative Block",
		emoji = "🧱",
		text = "You're staring at a blank canvas/screen. Nothing is coming to you.",
		question = "How do you break through?",
		cooldown = 2,
		maxOccurrences = 3,
		choices = {
			{ text = "Take a walk outside", deltas = { Health = 2, Happiness = 2 }, feedText = "Fresh air helped clear your mind!" },
			{ text = "Push through", deltas = { Happiness = -2, Smarts = 1 }, feedText = "You forced yourself to work through it." },
			{ text = "Look at others' work for inspiration", deltas = { Smarts = 2 }, setFlags = { creative_research = true }, feedText = "You found inspiration in others' work." },
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
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #AAA-MEGA-2: Entry-level/service/retail events should use
	-- ServiceCareerEvents, NOT OfficeCareerEvents! A movie usher doesn't have
	-- "email overload" or "meeting marathon" - they deal with customers!
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif jobCategory == "entry" or jobCategory == "service" or jobCategory == "retail" then
		eventPool = ServiceCareerEvents
		eventSource = "career_service"
	-- Creative category (acting, music, etc.) - DON'T use office events!
	-- Creative workers have different work environments than cubicle workers
	elseif jobCategory == "creative" then
		eventPool = CreativeCareerEvents
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
	-- CRITICAL FIX #AAA-MEGA-1: ALSO check eligibility functions! Without this, office
	-- events fire for service workers, marketing events fire for movie ushers, etc.
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.EventHistory = state.EventHistory or {}
	local eligibleEvents = {}
	
	for _, template in ipairs(eventPool) do
		local eventId = template.id
		local history = state.EventHistory[eventId]
		local isEligible = true
		
		-- CRITICAL FIX #AAA-MEGA-1: CHECK ELIGIBILITY FUNCTION FIRST!
		-- This prevents office events from firing for service workers,
		-- marketing events from firing for movie ushers, etc.
		if template.eligibility and type(template.eligibility) == "function" then
			local success, result = pcall(template.eligibility, state)
			if not success or not result then
				isEligible = false
			end
		end
		
		-- Check cooldown (default 2 years for career events)
		local cooldown = template.cooldown or 2
		if isEligible and history and history.lastAge then
			local yearsSince = (state.Age or 0) - history.lastAge
			if yearsSince < cooldown then
				isEligible = false
			end
		end
		
		-- Check max occurrences (default 3 for career events)
		local maxOccurrences = template.maxOccurrences or 3
		if isEligible and history and (history.count or 0) >= maxOccurrences then
			isEligible = false
		end
		
		-- Check one-time events
		if isEligible and template.oneTime and history then
			isEligible = false
		end
		
		-- CRITICAL FIX: Check blockedByFlags
		if isEligible and template.blockedByFlags then
			for flagName, _ in pairs(template.blockedByFlags) do
				if state.Flags and state.Flags[flagName] then
					isEligible = false
					break
				end
			end
		end
		
		-- CRITICAL FIX: Check requiresFlags
		if isEligible and template.requiresFlags then
			for _, flagName in ipairs(template.requiresFlags) do
				if not state.Flags or not state.Flags[flagName] then
					isEligible = false
					break
				end
			end
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
	self.remotes.SetEngagementBonus = self:createRemote("SetEngagementBonus", "RemoteEvent") -- For group/like bonus
	self.remotes.MinigameResult = self:createRemote("MinigameResult", "RemoteEvent")
	self.remotes.MinigameStart = self:createRemote("MinigameStart", "RemoteEvent")
	self.remotes.ShowResult = self:createRemote("ShowResult", "RemoteEvent") -- For showing popup messages

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
	-- CRITICAL FEATURE: Continue as your kid on death
	self.remotes.ContinueAsKid = self:createRemote("ContinueAsKid", "RemoteFunction")
	
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

	-- CRITICAL FIX: Now accepts country parameter for country selection feature
	self.remotes.SetLifeInfo.OnServerEvent:Connect(function(player, name, gender, country)
		self:setLifeInfo(player, name, gender, country)
	end)
	
	-- ENGAGEMENT BONUS: Set flag when player joins group or likes game
	-- Grants +25% income bonus on all salary payments
	self.remotes.SetEngagementBonus.OnServerEvent:Connect(function(player, bonusType)
		local state = self:getState(player)
		if state then
			state.Flags = state.Flags or {}
			if bonusType == "group" then
				state.Flags.joined_group = true
				state.Flags.engagement_bonus = true
				print("[LifeBackend] ⭐ Player", player.Name, "joined group - +25% income bonus activated!")
			elseif bonusType == "like" then
				state.Flags.liked_game = true
				state.Flags.engagement_bonus = true
				print("[LifeBackend] ⭐ Player", player.Name, "liked game - +25% income bonus activated!")
			elseif bonusType == "both" then
				state.Flags.joined_group = true
				state.Flags.liked_game = true
				state.Flags.engagement_bonus = true
				print("[LifeBackend] ⭐ Player", player.Name, "engaged (group+like) - +25% income bonus activated!")
			end
		end
	end)

	self.remotes.SubmitChoice.OnServerEvent:Connect(function(player, eventId, choiceIndex)
		self:resolvePendingEvent(player, eventId, choiceIndex)
	end)

	self.remotes.MinigameResult.OnServerEvent:Connect(function(player, won, payload)
		self:handleMinigameResult(player, won, payload)
	end)

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- AAA FIX: Wrap remote handlers with pcall for crash protection
	-- Returns error message instead of crashing the server
	-- ═══════════════════════════════════════════════════════════════════════════════
	local function safeHandler(handler)
		return function(player, ...)
			local success, result = pcall(handler, self, player, ...)
			if success then
				return result
			else
				warn("[LifeBackend] Remote handler error for", player.Name, ":", result)
				return { success = false, message = "An error occurred. Please try again." }
			end
		end
	end

	self.remotes.DoActivity.OnServerInvoke = safeHandler(function(self, player, activityId, bonus)
		return self:handleActivity(player, activityId, bonus)
	end)
	self.remotes.CommitCrime.OnServerInvoke = safeHandler(function(self, player, crimeId, minigameBonus)
		return self:handleCrime(player, crimeId, minigameBonus)
	end)
	self.remotes.DoPrisonAction.OnServerInvoke = safeHandler(function(self, player, actionId)
		return self:handlePrisonAction(player, actionId)
	end)

	self.remotes.ApplyForJob.OnServerInvoke = safeHandler(function(self, player, jobId, interviewScore)
		return self:handleJobApplication(player, jobId, interviewScore)
	end)
	
	-- AAA FIX: Interview result handler for the interview screen system
	self.remotes.SubmitInterviewResult = self:createRemote("SubmitInterviewResult", "RemoteFunction")
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #961: ALL remote handlers MUST use safeHandler to prevent crashes!
	-- Unprotected handlers can crash the entire server if an error occurs
	-- ═══════════════════════════════════════════════════════════════════════════════
	self.remotes.SubmitInterviewResult.OnServerInvoke = safeHandler(function(self, player, interviewData, choices)
		return self:handleInterviewResult(player, interviewData, choices)
	end)
	
	self.remotes.QuitJob.OnServerInvoke = safeHandler(function(self, player, quitStyle)
		return self:handleQuitJob(player, quitStyle)
	end)
	self.remotes.DoWork.OnServerInvoke = safeHandler(function(self, player)
		return self:handleWork(player)
	end)
	self.remotes.RequestPromotion.OnServerInvoke = safeHandler(function(self, player)
		return self:handlePromotion(player)
	end)
	self.remotes.RequestRaise.OnServerInvoke = safeHandler(function(self, player)
		return self:handleRaise(player)
	end)
	self.remotes.GetCareerInfo.OnServerInvoke = safeHandler(function(self, player)
		return self:getCareerInfo(player)
	end)
	
	-- CRITICAL FIX #338: Check job eligibility (education, experience, stats)
	self.remotes.GetJobEligibility.OnServerInvoke = safeHandler(function(self, player)
		return self:getJobEligibility(player)
	end)

	self.remotes.GetEducationInfo.OnServerInvoke = safeHandler(function(self, player)
		return self:getEducationInfo(player)
	end)
	self.remotes.EnrollEducation.OnServerInvoke = safeHandler(function(self, player, programId)
		return self:enrollEducation(player, programId)
	end)

	self.remotes.BuyProperty.OnServerInvoke = safeHandler(function(self, player, assetId)
		return self:handleAssetPurchase(player, "Properties", Properties, assetId)
	end)
	self.remotes.BuyVehicle.OnServerInvoke = safeHandler(function(self, player, assetId)
		return self:handleAssetPurchase(player, "Vehicles", Vehicles, assetId)
	end)
	self.remotes.BuyItem.OnServerInvoke = safeHandler(function(self, player, assetId)
		return self:handleAssetPurchase(player, "Items", ShopItems, assetId)
	end)
	self.remotes.SellAsset.OnServerInvoke = safeHandler(function(self, player, assetId, assetType)
		return self:handleAssetSale(player, assetId, assetType)
	end)
	-- REMOVED: Gambling handler (against Roblox TOS)
	-- Gambling features have been removed to comply with Roblox Terms of Service

	self.remotes.DoInteraction.OnServerInvoke = safeHandler(function(self, player, payload)
		return self:handleInteraction(player, payload)
	end)

	self.remotes.StartPath.OnServerInvoke = safeHandler(function(self, player, pathId)
		return self:startStoryPath(player, pathId)
	end)
	self.remotes.DoPathAction.OnServerInvoke = safeHandler(function(self, player, pathId, actionId)
		return self:performPathAction(player, pathId, actionId)
	end)

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
	
	self.remotes.DoMobOperation.OnServerInvoke = function(player, operationId, modifiers)
		return self:handleMobOperation(player, operationId, modifiers)
	end
	
	self.remotes.CheckGamepass.OnServerInvoke = function(player, gamepassKey)
		return self:checkGamepassOwnership(player, gamepassKey)
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #508: Pass forceBypassCooldown = true for ALL user-initiated prompts!
	-- When a player clicks a gamepass button, they ALWAYS want to buy - never block them!
	-- ═══════════════════════════════════════════════════════════════════════════════
	self.remotes.PromptGamepass.OnServerEvent:Connect(function(player, gamepassKey, forceBypassCooldown)
		-- CRITICAL: Default to true for user-initiated prompts!
		local bypass = (forceBypassCooldown ~= false) -- true unless explicitly false
		self:promptGamepassPurchase(player, gamepassKey, bypass)
	end)
	
	-- CRITICAL FIX #358: Developer Product purchase handler
	self.remotes.PromptProduct.OnServerEvent:Connect(function(player, productKey)
		self:promptProductPurchase(player, productKey)
	end)
	
	self.remotes.UseTimeMachine.OnServerInvoke = function(player, yearsBack)
		return self:handleTimeMachine(player, yearsBack)
	end
	
	-- CRITICAL FEATURE: Continue as Your Kid handler
	self.remotes.ContinueAsKid.OnServerInvoke = function(player, childData)
		return self:handleContinueAsKid(player, childData)
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
	-- CRITICAL FIX: Only pushState, don't appendFeed (avoid duplicate message)
	-- appendFeed would show again at next age-up
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
	-- CRITICAL FIX: Only pushState, don't appendFeed (avoid duplicate message)
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Initialize HousingState for new players
	-- All players start life living with their parents (age 0)
	-- This prevents homeless events from triggering incorrectly
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.HousingState = state.HousingState or {}
	state.HousingState.status = "with_parents"  -- Baby lives with parents
	state.HousingState.type = "family_home"
	state.HousingState.rent = 0  -- No rent when living with parents
	state.HousingState.yearsWithoutPayingRent = 0
	state.HousingState.missedRentYears = 0
	
	-- Set initial housing flags (living with parents)
	state.Flags = state.Flags or {}
	state.Flags.living_with_parents = true
	-- Explicitly ensure NOT set homeless or moved out at birth
	state.Flags.homeless = nil
	state.Flags.moved_out = nil
	state.Flags.has_apartment = nil
	state.Flags.renting = nil
	
	debugPrint(string.format("Created initial state for %s with %d family members", 
		player.Name, countEntries(state.Relationships)))
	debugPrint("  Assets initialized:", state.Assets ~= nil)
	debugPrint("  HousingState:", state.HousingState.status)
	
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
		-- CRITICAL FIX: Sync RoyalState when either RoyalState.isRoyal OR is_royalty flag is set
		-- This prevents the "dream fulfilled but nothing changed" bug
		local isRoyal = (state.RoyalState and state.RoyalState.isRoyal) or 
			(state.Flags and (state.Flags.is_royalty or state.Flags.royal_by_marriage))
		
		if isRoyal then
			-- Ensure RoyalState exists with defaults
			state.RoyalState = state.RoyalState or {}
			state.RoyalState.isRoyal = true
			state.RoyalState.title = state.RoyalState.title or (state.Gender == "Female" and "Princess" or "Prince")
			state.RoyalState.popularity = state.RoyalState.popularity or 50
			state.RoyalState.royalCountry = state.RoyalState.royalCountry or "Monaco"
			serialized.RoyalState = state.RoyalState
			
			-- Also sync flags
			serialized.Flags = serialized.Flags or {}
			serialized.Flags.is_royalty = true
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
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: HOUSING STATE - Client needs this to display living situation!
		-- User complaint: AssetsScreen doesn't show where I'm living
		-- ═══════════════════════════════════════════════════════════════════════════════
		if state.HousingState then
			serialized.HousingState = {
				status = state.HousingState.status or "with_parents",
				type = state.HousingState.type or "family_home",
				rent = state.HousingState.rent or 0,
				yearsWithoutPayingRent = state.HousingState.yearsWithoutPayingRent or 0,
				missedRentYears = state.HousingState.missedRentYears or 0,
				moveInYear = state.HousingState.moveInYear,
				value = state.HousingState.value,
			}
		else
			-- Default housing state for players without one set
			local age = state.Age or 0
			serialized.HousingState = {
				status = age < 18 and "with_parents" or "with_parents", -- Default to with parents
				type = "family_home",
				rent = 0,
				yearsWithoutPayingRent = 0,
				missedRentYears = 0,
			}
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: RUN STATE CONSISTENCY VALIDATOR
	-- This catches and fixes any inconsistent states before syncing to client
	-- Prevents: multiple paths, conflicting relationships, ghost flags, broke+rich
	-- ═══════════════════════════════════════════════════════════════════════════════
	self:validateStateConsistency(state)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- RECURSIVE VALIDATOR SYSTEM (RVS) - Deep structural repair
	-- Runs comprehensive validation across all systems:
	-- - Premium flag integrity (flags backed by actual events/state)
	-- - Event chain completion (incomplete chains detected/resolved)
	-- - Ghost entity cleanup (dead relatives, duplicate assets)
	-- - Housing/title sync, occupation enforcement, fame/royalty validation
	-- ═══════════════════════════════════════════════════════════════════════════════
	self:validateRecursiveState(state)
	
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
			
			-- ═══════════════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX #950: Clear death flags on rejoin!
			-- If player died and rejoins, they should start a NEW life, not be stuck dead!
			-- The death screen should have offered "New Life" option, so if they're back,
			-- they want to start fresh.
			-- ═══════════════════════════════════════════════════════════════════════════════
			if state.Flags.dead or state.Flags.is_dead then
				print("[LifeBackend] 🔄 Player rejoined after death - resetting for new life!")
				
				-- Clear ALL death-related state
				state.Flags.dead = nil
				state.Flags.is_dead = nil
				state.Flags.is_alive = true
				state.DeathReason = nil
				state.DeathAge = nil
				state.DeathYear = nil
				
				-- Reset to a new life (age 0)
				state.Age = 0
				state.Year = os.date("*t").year  -- Current year
				state.BirthYear = state.Year
				
				-- Generate new identity
				local newNames = { "James", "Emma", "Michael", "Sophia", "Daniel", "Olivia", "Liam", "Charlotte", "Noah", "Mia" }
				local lastNames = { "Smith", "Johnson", "Williams", "Brown", "Jones", "Davis", "Miller", "Wilson", "Moore", "Taylor" }
				local firstName = newNames[math.random(1, #newNames)]
				local lastName = lastNames[math.random(1, #lastNames)]
				state.Name = firstName .. " " .. lastName
				state.Gender = math.random() > 0.5 and "Male" or "Female"
				
				-- Reset stats to newborn
				state.Stats = state.Stats or {}
				state.Stats.Health = 100
				state.Stats.Happiness = 75 + math.random(0, 25)
				state.Stats.Smarts = 20 + math.random(0, 40)
				state.Stats.Looks = 30 + math.random(0, 40)
				state.Health = state.Stats.Health
				state.Happiness = state.Stats.Happiness
				state.Smarts = state.Stats.Smarts
				state.Looks = state.Stats.Looks
				
				-- Reset money (small inheritance from past life)
				state.Money = math.random(0, 500)
				
				-- Clear job/career
				state.CurrentJob = nil
				state.CareerInfo = nil
				state.Education = "None"
				
				-- Reset housing to with parents
				state.HousingState = { status = "with_parents", type = "family_home", rent = 0 }
				state.Flags.living_with_parents = true
				state.Flags.moved_out = nil
				state.Flags.has_apartment = nil
				state.Flags.renting = nil
				
				-- Clear most flags but keep gamepasses
				local savedGamepasses = state.GamepassOwnership
				state.Flags = { is_alive = true, new_life = true }
				state.GamepassOwnership = savedGamepasses
				
				-- Generate new family
				state.Relationships = {}
				
				-- Clear special states
				state.RoyalState = nil
				state.MobState = nil
				state.FameState = nil
				state.Fame = 0
				state.Karma = 50
				
				-- Clear assets (new life starts fresh)
				state.Assets = { Properties = {}, Vehicles = {}, Items = {} }
				
				print("[LifeBackend] 🆕 New life created! Name:", state.Name, "as a", state.Gender)
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

function LifeBackend:setLifeInfo(player, nameOrPayload, genderArg, countryArg)
	local state = self:getState(player)
	if not state then
		return
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #105: Support both old (name, gender) and new (payload object) formats
	-- New format: { gender = "Male", isRoyalBirth = true, royalCountry = "uk" }
	-- Also now supports country selection (third argument)
	-- ═══════════════════════════════════════════════════════════════════════════════
	local name, gender, isRoyalBirth, royalCountry, selectedCountry
	
	if type(nameOrPayload) == "table" then
		-- New payload format
		name = nameOrPayload.name
		gender = nameOrPayload.gender
		isRoyalBirth = nameOrPayload.isRoyalBirth
		royalCountry = nameOrPayload.royalCountry
		selectedCountry = nameOrPayload.country
	else
		-- Old format (name, gender, country)
		name = nameOrPayload
		gender = genderArg
		selectedCountry = countryArg
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- COUNTRY SELECTION: Store selected country in state
	-- User requested: "add countries even if it doesn't do much like let u pick country after u pick gender"
	-- ═══════════════════════════════════════════════════════════════════════════════
	local countryMap = {
		usa = "United States",
		uk = "United Kingdom",
		canada = "Canada",
		australia = "Australia",
		germany = "Germany",
		france = "France",
		japan = "Japan",
		brazil = "Brazil",
		mexico = "Mexico",
		italy = "Italy",
		spain = "Spain",
		india = "India",
		china = "China",
		russia = "Russia",
		south_korea = "South Korea",
	}
	
	if selectedCountry and selectedCountry ~= "" then
		state.Country = countryMap[selectedCountry] or selectedCountry or "United States"
	elseif not state.Country then
		state.Country = "United States" -- Default country
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
			-- CRITICAL FIX: Properly handle nil values to prevent string.format errors
			local safeTitle = tostring(title or "Prince/Princess")
			local safeName = tostring(state.Name or "Your Highness")
			local safeCountryName = (country and country.name) and tostring(country.name) or "the Kingdom"
			local safePalace = (country and country.palace) and tostring(country.palace) or "the Palace"
			self:pushState(player, string.format("👑 %s %s of %s takes their first breath in %s!", safeTitle, safeName, safeCountryName, safePalace))
			return
		end
	end
	
	-- CRITICAL FIX: Properly handle nil Name
	local safeBirthName = tostring(state.Name or "Your character")
	self:pushState(player, string.format("%s takes their first breath.", safeBirthName))
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
					-- AAA FIX: Nil safety check
					local partner = state.Relationships.partner
					if partner and type(partner) == "table" and partner.id == rel.id then
						state.Relationships.partner = nil
					end
					state.PendingFeed = (rel.name or "Your partner") .. " couldn't handle the separation and left you."
				end
			end
			
			-- Age up the family member
			rel.age = (rel.age or (state.Age + 20)) + 1
			
			-- ═══════════════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX: More REALISTIC death chances based on age for family members
			-- User complaint: "IM 69 YEARS OLD AND MY PARENTS ARE STILL ALIVE?!??!"
			-- Previous chances were too LOW - by age 95+ survival should be rare
			-- Real-world mortality rates: ~15% at 80, ~25% at 85, ~35% at 90, ~50% at 95
			-- ═══════════════════════════════════════════════════════════════════════════════
			if rel.type == "family" or rel.isFamily then
				local deathChance = 0
				local relAge = rel.age or 0
				
				-- REALISTIC death chances (cumulative survival to 100 should be extremely rare)
				if relAge >= 100 then
					deathChance = 0.70 -- 70% chance at 100+ (most don't live past 100)
				elseif relAge >= 95 then
					deathChance = 0.45 -- 45% chance at 95-99 (supercentenarians are rare)
				elseif relAge >= 90 then
					deathChance = 0.30 -- 30% chance at 90-94 (nonagenarians declining rapidly)
				elseif relAge >= 85 then
					deathChance = 0.18 -- 18% chance at 85-89 (major decline in health)
				elseif relAge >= 80 then
					deathChance = 0.10 -- 10% chance at 80-84 (entering elderly)
				elseif relAge >= 75 then
					deathChance = 0.05 -- 5% chance at 75-79 
				elseif relAge >= 70 then
					deathChance = 0.025 -- 2.5% chance at 70-74
				elseif relAge >= 65 then
					deathChance = 0.012 -- 1.2% chance at 65-69
				elseif relAge >= 60 then
					deathChance = 0.006 -- 0.6% chance at 60-64 (accidents, illness)
				elseif relAge >= 50 then
					deathChance = 0.003 -- 0.3% chance at 50-59 (rare but possible)
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
								text = string.format("Inherited %s from %s's estate", formatMoney(inheritanceAmount) or "$0", tostring(rel.name or "your parent")),
								amount = inheritanceAmount or 0,
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
								text = string.format("Received %s from %s's will", formatMoney(inheritanceAmount or 0) or "$0", tostring(rel.name or "your grandparent")),
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
			
			-- CRITICAL FIX: Ensure all values are safe for string.format
			state.PendingFeed = string.format("💔 Your %s, %s, passed away at age %d. You are now widowed.", 
				tostring(partnerRole or "partner"), tostring(partnerName or "spouse"), tonumber(partnerAge) or 0)
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
		-- CRITICAL FIX: Ensure all values are safe for string.format
		local safeName = tostring(death.name or "family member")
		local safeRole = tostring(roleName or "relative")
		local safeAge = tonumber(death.age) or 0
		local formattedMsg = string.format(msgTemplate, safeName, safeRole, safeAge)
		
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

				-- ═══════════════════════════════════════════════════════════════════════════════
				-- CRITICAL FIX: Clear "in college/university" flags upon graduation
				-- BUG: These flags were not being cleared, causing "College Dorm Room" to appear
				-- in properties even after graduation (when player is 42 and has a partner)
				-- ═══════════════════════════════════════════════════════════════════════════════
				if level ~= "high_school" and level ~= "trade" and level ~= "bootcamp" then
					-- Clear all college/university enrollment flags upon graduation
					state.Flags.in_college = nil
					state.Flags.in_university = nil
					state.Flags.college_student = nil
					state.Flags.university_student = nil
					state.Flags.enrolled_college = nil
					state.Flags.enrolled_university = nil
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
			-- Ensure promotionProgress is a valid number
			local safeProgress = tonumber(info.promotionProgress) or 0
			local baseChance = math.max(0, (safeProgress - 50) / 100)  -- 10% at 60%, 50% at 100%

			if isTalentCareer then
				baseChance = baseChance * 3.0  -- 30% at 60%, 150% (capped to 95%) at 100% for talent careers
			end

			local autoPromoChance = math.min(0.95, math.max(0, baseChance))  -- Cap at 95%, floor at 0%
			
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
											-- CRITICAL FIX: Handle nil values
											state.YearLog = state.YearLog or {}
											local safeOldName = tostring(oldJobName or "previous position")
											local safeNextName = tostring(nextJob.name or "new position")
											local safeSalary = formatMoney((state.CurrentJob and state.CurrentJob.salary) or 0)
											table.insert(state.YearLog, {
												type = "promotion",
												emoji = "🎉",
												text = string.format("Promoted from %s to %s! New salary: $%s", safeOldName, safeNextName, safeSalary),
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
		-- CRITICAL FIX: Ensure maxGain is a valid number
		local safeMaxGain = (type(maxGain) == "number" and maxGain > 0) and maxGain or 1
		local gain = math.max(1, math.floor(safeMaxGain * (1 - currentLevel / 100)))
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
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- ENGAGEMENT BONUS: +25% income for players who joined group & liked the game!
		-- This rewards engaged players and encourages community participation
		-- Check flags set by client when player joins group/likes game
		-- ═══════════════════════════════════════════════════════════════════════════════
		local baseSalary = salary
		local bonusAmount = 0
		local hasEngagementBonus = false
		
		if state.Flags and (state.Flags.joined_group or state.Flags.liked_game or state.Flags.engagement_bonus) then
			hasEngagementBonus = true
			bonusAmount = math.floor(baseSalary * 0.25)
			salary = baseSalary + bonusAmount
		end
		
		self:addMoney(state, salary)
		debugPrint("Salary paid:", salary, "(base:", baseSalary, "+ bonus:", bonusAmount, ") to player. New balance:", state.Money)
		
		-- CRITICAL FIX: Store last paid salary for pension calculation
		-- This ensures retirement events can calculate pension from actual income
		-- (important for fame careers where CurrentJob.salary may be outdated)
		state.CareerInfo = state.CareerInfo or {}
		state.CareerInfo.lastPaidSalary = salary
		
		-- CRITICAL FIX #138: Add salary to YearLog so user sees they got paid!
		-- This was the bug - salary was paid but user didn't see any message
		-- YearLog entries need 'text' field, not 'message' - that's what generateYearSummary looks for
		state.YearLog = state.YearLog or {}
		
		local salaryText
		if hasEngagementBonus then
			salaryText = string.format("Earned %s from your job as %s (+25%% bonus!)", 
				formatMoney(salary or 0) or "$0", 
				tostring(state.CurrentJob.name or "employee"))
		else
			salaryText = string.format("Earned %s from your job as %s", 
				formatMoney(salary or 0) or "$0", 
				tostring(state.CurrentJob.name or "employee"))
		end
		
		table.insert(state.YearLog, {
			type = "salary",
			emoji = hasEngagementBonus and "💰⭐" or "💰",
			text = salaryText,
			amount = salary or 0,
		})
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROPERTY INCOME - Collect passive income from owned real estate
-- CRITICAL FIX: This was completely missing! Properties have income fields but
-- the rental income was never being collected during age up.
-- CRITICAL FIX #600: CHILDREN SHOULD NOT RECEIVE PROPERTY INCOME!
-- User complaint: "I'm 4 years old and getting money from family estate???"
-- Property income should only be paid to adults (18+) who actually manage properties
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:collectPropertyIncome(state)
	-- CRITICAL FIX #600: Children cannot receive property income!
	-- Real-world logic: Minors can't own property or receive rental income
	-- If inherited, it would go into a trust managed by guardians
	local age = state.Age or 0
	if age < 18 then
		-- Children don't receive property income
		-- In reality, this would go to parents/guardians or a trust
		return
	end
	
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Check housing status from both HousingState and Flags!
	-- Previous bug: Renters were treated as "living with parents" because they don't own property
	-- ═══════════════════════════════════════════════════════════════════════════════
	local flags = state.Flags or {}
	local housingState = state.HousingState or {}
	
	-- Player has their own place if they rent OR own
	local hasOwnHousing = hasProperty 
		or flags.moved_out 
		or flags.has_apartment 
		or flags.renting 
		or flags.has_own_place
		or housingState.status == "renter"
		or housingState.status == "owner"
	
	-- Player lives with parents if no housing flags set
	local livesWithParents = not hasOwnHousing 
		or flags.living_with_parents 
		or housingState.status == "with_parents"
	
	-- Is homeless?
	local isHomeless = flags.homeless 
		or flags.living_in_car 
		or flags.couch_surfing
		or housingState.status == "homeless"
	
	-- CRITICAL FIX #318: Young adults (18-22) living situations
	-- If no job and young, they likely live with parents (much lower expenses)
	-- If in college, they have student living expenses (moderate)
	-- If employed, normal adult expenses
	local baseCost = 8000 -- Default $8,000/year minimum for basic living
	local totalExpenses = 0
	local expenseDescription = "living expenses"
	
	-- CRITICAL FIX: Homeless people have very different expense structure
	if isHomeless then
		baseCost = 1000 -- Minimal expenses - survival mode
		totalExpenses = baseCost
		expenseDescription = "survival costs (homeless)"
		-- No rent, but may have medical issues, etc.
	elseif livesWithParents and not hasOwnHousing and age <= 22 then
		-- CRITICAL FIX #318: Young adults without their own housing live with parents
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
	elseif livesWithParents and not hasOwnHousing and age <= 25 then
		-- 23-25 without own housing - still with parents
		baseCost = 2000
		totalExpenses = baseCost
		expenseDescription = "personal expenses (living with family)"
	elseif age <= 25 and not hasJob and hasOwnHousing then
		-- CRITICAL FIX: Young adult with their own place but no job - needs to pay rent!
		-- This was the bug: renters without jobs were treated as with parents
		local rent = housingState.rent or 9000 -- Default $750/month
		baseCost = 4000 -- Base personal expenses
		totalExpenses = baseCost + rent
		expenseDescription = "rent and living costs"
	else
		-- Normal adult with or seeking employment
		totalExpenses = baseCost
		
		-- CRITICAL FIX: Add housing costs based on actual housing situation
		-- Only add rent if player has their own housing (renting) OR doesn't own AND isn't with parents
		if hasProperty then
			-- Owns property - no rent, but has maintenance (handled elsewhere)
			expenseDescription = "homeowner living costs"
		elseif hasOwnHousing and not hasProperty then
			-- Renting - use HousingState rent or calculate based on age
			local rentCost = housingState.rent or 9000 -- Use stored rent or default $750/month
			if age > 30 and (housingState.rent == nil or housingState.rent == 0) then
				rentCost = 12000 -- $1,000/month for established adult
			end
			if age > 45 and (housingState.rent == nil or housingState.rent == 0) then
				rentCost = 15000 -- $1,250/month for established family
			end
			totalExpenses = totalExpenses + rentCost
			expenseDescription = "rent and living costs"
		elseif livesWithParents then
			-- Living with parents - minimal expenses even as older adult
			totalExpenses = math.min(totalExpenses, 3000) -- Cap at $3000 for personal expenses
			expenseDescription = "personal expenses (living with family)"
		else
			-- No clear housing situation - assume needs rent
			local rentCost = 9000 -- Base rent $750/month for starter apartment
			if age > 30 then
				rentCost = 12000 -- $1,000/month for established adult
			end
			if age > 45 then
				rentCost = 15000 -- $1,250/month for established family
			end
			totalExpenses = totalExpenses + rentCost
			expenseDescription = "rent and living costs"
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
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Housing state tracking - User complaint: "$0 for 10+ years but not homeless"
		-- Track years broke to eventually trigger homelessness
		-- ═══════════════════════════════════════════════════════════════════════════════
		state.HousingState = state.HousingState or {}
		state.HousingState.yearsWithoutPayingRent = (state.HousingState.yearsWithoutPayingRent or 0) + 1
		local yearsBroke = state.HousingState.yearsWithoutPayingRent
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Only track eviction if player actually has their own rental housing!
		-- Living with parents = can't be evicted, just awkward freeloading
		-- ═══════════════════════════════════════════════════════════════════════════════
		local canBeEvicted = hasOwnHousing and not hasProperty and not livesWithParents
		
		-- First warning after 2 years (only for renters)
		if yearsBroke == 2 and canBeEvicted then
			state.Flags.eviction_warning = true
			table.insert(state.YearLog, {
				type = "housing",
				emoji = "⚠️",
				text = "You've fallen behind on rent. Your landlord is getting impatient...",
				amount = 0,
			})
		elseif yearsBroke == 3 and canBeEvicted then
			-- Second warning
			state.Flags.eviction_imminent = true
			table.insert(state.YearLog, {
				type = "housing",
				emoji = "🏠",
				text = "Eviction notice received! You have one more year to pay up or you're out!",
				amount = 0,
			})
		elseif yearsBroke >= 4 and canBeEvicted then
			-- After 4+ years broke without owning property = EVICTED and HOMELESS
			if not state.Flags.homeless then
				state.Flags.homeless = true
				state.Flags.evicted = true
				state.Flags.living_with_parents = nil  -- No more support
				state.Flags.renting = nil
				state.Flags.has_apartment = nil
				state.Flags.moved_out = nil
				state.Flags.has_own_place = nil
				state.HousingState.status = "homeless"
				state.HousingState.evictedAt = state.Year or 2025
				
				-- Severe happiness hit
				state.Stats.Happiness = math.max(0, (state.Stats.Happiness or 50) - 30)
				state.Stats.Health = math.max(10, (state.Stats.Health or 50) - 15)
				
				table.insert(state.YearLog, {
					type = "housing",
					emoji = "🏚️",
					text = "EVICTED! After years of not paying rent, you're now homeless. Living on the streets is dangerous...",
					amount = 0,
				})
			end
		elseif yearsBroke >= 3 and livesWithParents then
			-- Living with parents but broke for 3+ years - uncomfortable but not evicted
			table.insert(state.YearLog, {
				type = "housing",
				emoji = "😬",
				text = "Your parents are getting frustrated with you freeloading...",
				amount = 0,
			})
		end
		
		-- CRITICAL FIX #140: Log when player goes broke
		state.YearLog = state.YearLog or {}
		table.insert(state.YearLog, {
			type = "expenses",
			emoji = "💸",
			text = string.format("Couldn't afford $%s in %s - struggling!", formatMoney(totalExpenses), expenseDescription),
			amount = -paidAmount,
		})
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Reset years broke counter if player paid their expenses
	-- Also clear struggling flag when they have money
	-- ═══════════════════════════════════════════════════════════════════════════════
	if currentMoney >= totalExpenses then
		state.HousingState = state.HousingState or {}
		state.HousingState.yearsWithoutPayingRent = 0
		state.Flags = state.Flags or {}
		state.Flags.eviction_warning = nil
		state.Flags.eviction_imminent = nil
		state.Flags.struggling_financially = nil -- CRITICAL FIX: Clear when not broke
	end
	
	-- CRITICAL FIX: Also clear broke flags if player has substantial money
	-- This handles cases like inheritance where player suddenly has money
	if (state.Money or 0) >= 10000 then
		state.Flags = state.Flags or {}
		state.Flags.struggling_financially = nil
		state.Flags.broke = nil
		state.Flags.poor = nil
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
	
	-- CRITICAL FIX: More ways to gain health naturally!
	-- User feedback: "health can be hard to manage and few things gives positive health"
	-- Added more positive health modifiers
	
	-- Regular exerciser gets health boost
	if state.Flags.exercises_regularly or state.Flags.works_out or state.Flags.gym_rat then
		healthChange = healthChange + RANDOM:NextInteger(1, 3)
	end
	
	-- Healthy eater gets health boost  
	if state.Flags.healthy_eater or state.Flags.vegetarian or state.Flags.vegan then
		healthChange = healthChange + RANDOM:NextInteger(0, 2)
	end
	
	-- Good sleep habits
	if state.Flags.good_sleep or state.Flags.early_riser then
		healthChange = healthChange + RANDOM:NextInteger(0, 1)
	end
	
	-- Meditation/mindfulness helps health
	if state.Flags.meditates or state.Flags.zen_master then
		healthChange = healthChange + RANDOM:NextInteger(0, 2)
	end
	
	-- Young people naturally regenerate health slightly (under 40)
	if (state.Age or 0) < 40 and healthChange == 0 then
		-- If no other effects, young people gain 1-2 health naturally
		healthChange = healthChange + RANDOM:NextInteger(1, 2)
	end
	
	-- Middle age (40-60) maintains health
	-- Elderly (60+) may lose health naturally if not active
	if (state.Age or 0) >= 60 and not (state.Flags.fitness_enthusiast or state.Flags.exercises_regularly) then
		healthChange = healthChange - RANDOM:NextInteger(0, 2) -- Slight natural decline
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
-- CRITICAL FIX #18: Relationship Decay + AAA Friend Anger System
-- Uses RelationshipDecaySystem for proper friend anger events like competition
-- Friends get ANGRY if you don't talk to them for years!
-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: User reported "Robert is furious!" showing as feed text, not card popup!
-- These relationship events MUST show as proper card popups, not text in feed!
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyRelationshipDecay(state)
	if not state.Relationships then
		return
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- AAA: Use the RelationshipDecaySystem for friend anger events
	-- This generates proper "friend is angry you haven't talked" events
	-- CRITICAL FIX: Queue these as POPUP events, not just feed text!
	-- ═══════════════════════════════════════════════════════════════════════════════
	local decayEvents = RelationshipDecaySystem.processYearlyDecay(state)
	
	-- CRITICAL FIX: Queue significant events as proper card popups!
	-- These should NOT be feed text - user complained about this!
	state.QueuedRelationshipPopups = state.QueuedRelationshipPopups or {}
	
	-- Process generated decay events - queue important ones as card popups
	for _, event in ipairs(decayEvents) do
		-- CRITICAL FIX: Convert to proper popup format with nice formatting!
		local popupData = nil
		
		if event.type == "friend_annoyed" then
			local safeName = tostring(event.name or "Your friend")
			popupData = {
				emoji = "😤",
				title = "Friend Annoyed",
				body = string.format("%s is annoyed that you haven't reached out in %d years.\n\nThey feel like you've been neglecting the friendship.", 
					safeName, tonumber(event.yearsSince) or 2),
				happiness = -3,
			}
		elseif event.type == "friend_angry" then
			local safeName = tostring(event.name or "Your friend")
			popupData = {
				emoji = "😡",
				title = "Friend is Angry!",
				body = string.format("%s is really upset with you!\n\n\"You haven't talked to me in years! Do you even care about our friendship anymore?\"", 
					safeName),
				happiness = -8,
			}
			state.Flags = state.Flags or {}
			state.Flags.has_angry_friend = true
			state.Flags.angry_friend_name = safeName
			state.Flags.angry_friend_id = event.relId
		elseif event.type == "friend_furious" then
			local safeName = tostring(event.name or "Your friend")
			popupData = {
				emoji = "🔥",
				title = string.format("%s is FURIOUS!", safeName),
				body = string.format("%s confronted you, absolutely livid:\n\n\"You NEVER talk to me anymore! I'm always the one reaching out! What kind of friend are you?!\"\n\nThis friendship is on the verge of ending.", 
					safeName),
				happiness = -15,
			}
		elseif event.type == "friendship_ended" then
			local safeName = tostring(event.name or "Your friend")
			popupData = {
				emoji = "💔",
				title = "Friendship Over",
				body = string.format("After %d years of no contact, you and %s have completely drifted apart.\n\nThe friendship that once meant so much... is now just a memory.", 
					tonumber(event.yearsSince) or 8, safeName),
				happiness = -20,
			}
			state.Flags = state.Flags or {}
			state.Flags.lost_friend = true
			state.Flags.lost_friend_name = safeName
		end
		
		-- Queue the popup if it's a significant event
		if popupData then
			table.insert(state.QueuedRelationshipPopups, popupData)
		end
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
	
	-- Process non-friend relationships (family, romantic, etc.)
	for relId, rel in pairs(state.Relationships) do
		if type(rel) == "table" and rel.alive ~= false then
			-- Skip friends - already handled by RelationshipDecaySystem above
			local isFriend = rel.type == "friend" or (type(relId) == "string" and relId:find("friend"))
			if isFriend then
				-- Skip - already processed
			else
				-- Relationships naturally decay 1-3 points per year without interaction
				local decay = RANDOM:NextInteger(1, 3)
				
				-- Treatment reduces decay - people are supportive
				if inTreatment then
					decay = math.floor(decay * 0.3) -- 70% less decay during treatment
				end
				
				-- Close family decays slower
				if rel.isFamily or rel.type == "family" then
					decay = math.floor(decay * 0.5)
				end
				
				-- Partners decay faster if not married (less commitment)
				if rel.type == "romantic" and not (state.Flags and state.Flags.married) then
					decay = decay + 1
				end
				
				-- Prison causes faster decay (people move on)
				if state.InJail then
					decay = decay * 2
				end
				
				rel.relationship = math.max(0, (rel.relationship or 50) - decay)
				
				-- Very low romantic relationships may end naturally
				if rel.relationship <= 10 and rel.type == "romantic" then
					if RANDOM:NextNumber() < 0.3 then -- 30% chance relationship ends
						rel.alive = false
						rel.ended = true
						rel.endReason = "drifted_apart"
						
						-- CRITICAL FIX: Show as proper popup card, not feed text!
						-- User complained these showed as text in the feed, not card popups
						state.QueuedRelationshipPopups = state.QueuedRelationshipPopups or {}
						table.insert(state.QueuedRelationshipPopups, {
							emoji = "💔",
							title = "Relationship Ended",
							body = string.format("You and %s have drifted apart.\n\nWithout effort to maintain the relationship, the spark just... faded.\n\nThe relationship is over.", 
								rel.name or "your partner"),
							happiness = -25,
						})
						
						-- Clear partner status
						if relId == "partner" then
							state.Flags = state.Flags or {}
							state.Flags.has_partner = nil
							state.Flags.dating = nil
						end
					end
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
-- ═══════════════════════════════════════════════════════════════════════════════
-- AAA HELPER: Safe number extraction from flags
-- Prevents "attempt to perform arithmetic on boolean" crashes
-- Many flags store numbers but may accidentally be set to true/false
-- ═══════════════════════════════════════════════════════════════════════════════
local function safeNumber(value, default)
	if type(value) == "number" then
		return value
	elseif type(value) == "boolean" then
		return default or 0 -- Boolean flags should be 0
	elseif type(value) == "string" then
		return tonumber(value) or default or 0
	end
	return default or 0
end

function LifeBackend:checkBankruptcy(state)
	local totalDebt = 0
	
	-- Calculate total debt with safe number extraction
	if state.EducationData and state.EducationData.Debt then
		totalDebt = totalDebt + safeNumber(state.EducationData.Debt, 0)
	end
	
	-- CRITICAL FIX #21: Include credit card debt and mortgage in total debt calculation
	-- AAA FIX: Use safeNumber to prevent boolean arithmetic crashes
	state.Flags = state.Flags or {}
	if state.Flags.credit_card_debt then
		local ccDebt = safeNumber(state.Flags.credit_card_debt, 0)
		-- If it was a boolean, clear it to prevent future issues
		if type(state.Flags.credit_card_debt) == "boolean" then
			state.Flags.credit_card_debt = nil
			state.Flags.has_credit_card_debt = true -- Use boolean flag for existence
		end
		totalDebt = totalDebt + ccDebt
	end
	if state.Flags.mortgage_debt then
		local mortDebt = safeNumber(state.Flags.mortgage_debt, 0)
		if type(state.Flags.mortgage_debt) == "boolean" then
			state.Flags.mortgage_debt = nil
			state.Flags.has_mortgage = true
		end
		totalDebt = totalDebt + mortDebt
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
	
	-- AAA FIX: Use safeNumber to prevent boolean arithmetic crashes
	local ccDebt = safeNumber(state.Flags.credit_card_debt, 0)
	
	-- Fix corrupted boolean flag
	if type(state.Flags.credit_card_debt) == "boolean" then
		state.Flags.credit_card_debt = nil
		if state.Flags.credit_card_debt == true then
			state.Flags.has_credit_card_debt = true
		end
		return -- No actual debt to process
	end
	
	if ccDebt <= 0 then
		state.Flags.credit_card_debt = nil -- Clean up zero debt
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
		state.Flags.credit_card_debt = math.max(0, safeNumber(state.Flags.credit_card_debt, 0) - minPayment)
		-- Clean up if paid off
		if safeNumber(state.Flags.credit_card_debt, 0) <= 0 then
			state.Flags.credit_card_debt = nil
			state.Flags.has_credit_card_debt = nil
		end
	else
		-- Missed payment - extra penalties
		state.Flags.credit_card_debt = safeNumber(state.Flags.credit_card_debt, 0) + 35 -- Late fee
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
	
	-- AAA FIX: Use safeNumber to prevent boolean arithmetic crashes
	local mortgageDebt = safeNumber(state.Flags.mortgage_debt, 0)
	
	-- Fix corrupted boolean flag
	if type(state.Flags.mortgage_debt) == "boolean" then
		state.Flags.mortgage_debt = nil
		state.Flags.has_mortgage = state.Flags.mortgage_debt
		return -- No actual debt to process
	end
	
	if mortgageDebt <= 0 then
		state.Flags.mortgage_debt = nil -- Clean up zero debt
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
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #924: Check for EXTRA_LIFE before death!
		-- If player has an extra life, use it to save them!
		-- ═══════════════════════════════════════════════════════════════════════════════
		local player = state.player
		if player and GamepassSystem and GamepassSystem:hasExtraLife(player) then
			-- EXTRA LIFE SAVE!
			state.DeathReason = state.DeathReason or "Health complications"
			local saved, result = self:checkExtraLifeSave(player, state)
			if saved then
				-- Don't die - extra life was used!
				print("[checkNaturalDeath] Player saved by EXTRA_LIFE!")
				return -- Exit without setting dead flag
			end
		end
		
		-- No extra life - player dies
		state.Flags.dead = true
		state.DeathReason = state.DeathReason or "Health complications"
		state.DeathAge = age
		state.DeathYear = state.Year
		
		-- CRITICAL FIX #925: Prompt EXTRA_LIFE purchase for next time!
		-- They just died - they might want one for their next character
		if player and self.gamepassSystem then
			task.delay(2, function()
				if player and player.Parent then
					self.gamepassSystem:promptProduct(player, "EXTRA_LIFE")
				end
			end)
		end
		return
	end
	
	-- Critical health warning
	if health <= 10 then
		self:logYearEvent(state, "health",
			"⚠️ Health is critical! Seek medical attention immediately.", "🏥")
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- STRATEGIC GAMEPASS PROMPT #910: When health is critical, offer God Mode!
		-- Perfect conversion moment - they're about to die and want to save their character
		-- ═══════════════════════════════════════════════════════════════════════════════
		state.Flags.near_death = true -- For God Mode eligibility check
		
		-- CRITICAL FIX #911: Prompt God Mode when health is critical (HIGH CONVERSION!)
		if state.player and self.gamepassSystem then
			if not self:checkGamepassOwnership(state.player, "GOD_MODE") then
				task.delay(1, function()
					if state.player and state.player.Parent then
						self.gamepassSystem:promptGamepass(state.player, "GOD_MODE")
					end
				end)
			end
		end
	elseif health <= 25 then
		-- Health low but not critical - still prompt
		if state.player and self.gamepassSystem then
			if not self:checkGamepassOwnership(state.player, "GOD_MODE") then
				-- 30% chance to prompt (not spam)
				if RANDOM:NextNumber() < 0.3 then
					task.delay(2, function()
						if state.player and state.player.Parent then
							self.gamepassSystem:promptGamepass(state.player, "GOD_MODE")
						end
					end)
				end
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #937: Prompt STAT_BOOST when multiple stats are low
	-- This is a strategic monetization moment - player is struggling and wants help
	-- Only prompt occasionally to avoid being annoying
	-- ═══════════════════════════════════════════════════════════════════════════════
	local happiness = state.Stats and state.Stats.Happiness or 50
	local smarts = state.Stats and state.Stats.Smarts or 50
	local looks = state.Stats and state.Stats.Looks or 50
	
	local lowStatCount = 0
	if health < 40 then lowStatCount = lowStatCount + 1 end
	if happiness < 40 then lowStatCount = lowStatCount + 1 end
	if smarts < 40 then lowStatCount = lowStatCount + 1 end
	if looks < 40 then lowStatCount = lowStatCount + 1 end
	
	-- If 2+ stats are below 40, consider prompting STAT_BOOST
	if lowStatCount >= 2 and state.player and self.gamepassSystem then
		-- 15% chance per year to prompt (non-annoying)
		if RANDOM:NextNumber() < 0.15 then
			task.delay(3, function()
				if state.player and state.player.Parent then
					-- Use the cooldown-aware prompt
					self.gamepassSystem:promptProduct(state.player, "STAT_BOOST")
				end
			end)
		end
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
			-- ═══════════════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX #926: Check for EXTRA_LIFE before age-based death!
			-- Even old age can be cheated with an extra life!
			-- ═══════════════════════════════════════════════════════════════════════════════
			local player = state.player
			
			-- Generate death reason first (needed for revival message)
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
			
			-- Check for extra life BEFORE dying!
			if player and GamepassSystem and GamepassSystem:hasExtraLife(player) then
				local saved, result = self:checkExtraLifeSave(player, state)
				if saved then
					-- EXTRA LIFE USED! Player survives the age-related death!
					print("[checkNaturalDeath] Player survived age-based death via EXTRA_LIFE!")
					return -- Exit without completing death
				end
			end
			
			-- No extra life - proceed with death
			state.Flags.dead = true
			state.DeathAge = age
			state.DeathYear = state.Year
			
			-- CRITICAL FIX #927: Prompt EXTRA_LIFE and TIME_MACHINE at death!
			-- This is THE HIGHEST conversion moment
			if player and self.gamepassSystem then
				task.delay(1.5, function()
					if player and player.Parent then
						-- Prompt Extra Life for future use
						self.gamepassSystem:promptProduct(player, "EXTRA_LIFE")
					end
				end)
			end
			
			-- AAA FIX: Comprehensive death cleanup
			self:processDeathCleanup(state)
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- AAA FIX: Comprehensive death state cleanup
-- Ensures all active states are properly terminated on death
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:processDeathCleanup(state)
	if not state then return end
	
	state.Flags = state.Flags or {}
	
	-- Set all death flags
	state.Flags.dead = true
	state.Flags.is_dead = true
	state.Flags.is_alive = nil
	state.Flags.alive = nil
	
	-- Clear all active status flags
	state.Flags.pregnant = nil
	state.Flags.dating = nil
	state.Flags.has_partner = nil
	state.Flags.employed = nil
	state.Flags.has_job = nil
	state.Flags.in_college = nil
	state.Flags.in_school = nil
	state.Flags.in_prison = nil
	state.InJail = false
	state.JailYearsLeft = 0
	
	-- Clear current job
	state.CurrentJob = nil
	
	-- Clear education status
	if state.EducationData then
		state.EducationData.Status = "deceased"
		state.EducationData.inCollege = nil
	end
	
	-- Mark all relationships as widowed/orphaned where appropriate
	if state.Relationships then
		if state.Relationships.partner then
			local partner = state.Relationships.partner
			if type(partner) == "table" then
				partner.widowed = true
				partner.type = "late_spouse"
			end
		end
		
		-- Children become orphaned if both parents dead
		for relId, rel in pairs(state.Relationships) do
			if type(rel) == "table" and rel.type == "child" then
				rel.orphaned = (not state.Flags.has_living_partner)
			end
		end
	end
	
	-- Calculate inheritance for children
	state.Inheritance = {
		total = state.Money or 0,
		distributed = false,
	}
	
	-- Add net worth from assets
	if state.Assets then
		-- Properties
		if state.Assets.Properties then
			for _, prop in ipairs(state.Assets.Properties) do
				if prop.value then
					state.Inheritance.total = state.Inheritance.total + (prop.value or 0)
				end
			end
		end
		-- Vehicles
		if state.Assets.Vehicles then
			for _, vehicle in ipairs(state.Assets.Vehicles) do
				if vehicle.value then
					state.Inheritance.total = state.Inheritance.total + (vehicle.value or 0)
				end
			end
		end
		-- Investments
		if state.Assets.Investments then
			for _, inv in ipairs(state.Assets.Investments) do
				if inv.value then
					state.Inheritance.total = state.Inheritance.total + (inv.value or 0)
				end
			end
		end
	end
	
	-- Generate death summary
	state.DeathSummary = {
		age = state.Age or 0,
		reason = state.DeathReason or "Unknown",
		year = state.Year or 2025,
		netWorth = state.Inheritance.total or 0,
		legacy = {},
	}
	
	-- Build legacy
	if state.Flags.married or state.Flags.was_married then
		table.insert(state.DeathSummary.legacy, "Was married")
	end
	if state.Flags.has_children then
		local childCount = 0
		if state.Relationships then
			for _, rel in pairs(state.Relationships) do
				if type(rel) == "table" and rel.type == "child" then
					childCount = childCount + 1
				end
			end
		end
		if childCount > 0 then
			table.insert(state.DeathSummary.legacy, string.format("Had %d children", childCount))
		end
	end
	if state.Flags.is_royalty or state.Flags.royal_birth then
		table.insert(state.DeathSummary.legacy, "Was royalty")
	end
	if state.Flags.in_mob then
		table.insert(state.DeathSummary.legacy, "Was in the mafia")
	end
	if state.FameState and state.FameState.isFamous then
		table.insert(state.DeathSummary.legacy, "Was famous")
	end
	
	-- Mark major action for integrity
	IntegritySystem.markMajorAction(state, "death")
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
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Send cost/effects data to client for affordability checking!
		-- User feedback: "should just grey them out saying (cant afford)"
		-- The client needs to know the cost to gray out unaffordable choices!
		-- ═══════════════════════════════════════════════════════════════════════════════
		if choice.effects then
			choiceData.effects = {}
			-- Only send Money effect (for affordability) - don't send stat effects
			if choice.effects.Money then
				choiceData.effects.Money = choice.effects.Money
			end
		end
		if choice.cost then
			choiceData.cost = choice.cost
		end
		
		-- Also check eligibility function and mark as unavailable if can't afford
		if choice.eligibility and type(choice.eligibility) == "function" then
			local success, result, reason = pcall(choice.eligibility, state)
			if success and result == false then
				choiceData.unavailable = true
				choiceData.unavailableReason = reason or "Not eligible"
			end
		end
		
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

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Send state update BEFORE showing the event!
	-- User bug: "cash doesn't update until I pick my choice"
	-- Problem: Living expenses were deducted but client still showed OLD money
	-- So player thought they had $400 but actually had $0 after expenses!
	-- Solution: Push state FIRST so player sees their ACTUAL balance
	-- NOTE: Pass nil for feedText - PresentEvent will add it to feed (avoid duplicate!)
	-- ═══════════════════════════════════════════════════════════════════════════════
	self:pushState(player, nil)
	
	-- Now show the event (player can see their actual money when making choice)
	-- feedText is passed here and PresentEvent handler will add it to feed
	self.remotes.PresentEvent:FireClient(player, eventPayload, feedText)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: Re-present an event when player couldn't afford their first choice
-- Keeps the SAME eventId so pendingEvents still works
-- Marks unavailable choices so player knows which ones they can't pick
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:presentEventForRetry(player, eventDef, existingEventId)
	if not eventDef or not existingEventId then
		warn("[LifeBackend] presentEventForRetry called with missing data")
		return
	end
	
	local state = self:getState(player)
	if not state then return end
	
	-- Use the SAME eventId - don't generate a new one!
	local eventId = existingEventId
	
	-- Get the text (might already be processed from first presentation)
	local eventText = eventDef.text or ""
	local eventTitle = eventDef.title or "Life Event"
	local eventQuestion = eventDef.question or "What will you do?"
	
	-- Replace text variables
	local processedText = self:replaceTextVariables(eventText, state)
	local processedTitle = self:replaceTextVariables(eventTitle, state)
	local processedQuestion = self:replaceTextVariables(eventQuestion, state)
	
	-- Add retry message to the text
	processedText = "⚠️ Pick a different option:\n\n" .. processedText
	
	local eventPayload = {
		id = eventId,
		title = processedTitle,
		emoji = eventDef.emoji,
		text = processedText,
		question = processedQuestion,
		category = eventDef.category or "life",
		choices = {},
		isRetry = true, -- Signal to client this is a retry
	}
	
	-- Build choices, marking unavailable ones
	local unavailableChoices = eventDef._unavailableChoices or {}
	local flags = state.Flags or {}
	local gamepassOwnership = state.GamepassOwnership or {}
	
	for index, choice in ipairs(eventDef.choices or {}) do
		local unavailableReason = unavailableChoices[index]
		
		local choiceData = {
			index = index,
			text = self:replaceTextVariables(choice.text or ("Choice " .. index), state),
			minigame = choice.minigame,
		}
		
		-- Mark if this choice is unavailable (player already tried and failed)
		if unavailableReason then
			choiceData.unavailable = true
			choiceData.unavailableReason = unavailableReason
			-- Modify text to show it's unavailable
			choiceData.text = "❌ " .. choiceData.text .. " (Can't afford)"
		end
		
		-- Add premium choice info if this choice requires a gamepass
		if choice.requiresGamepass then
			choiceData.requiresGamepass = choice.requiresGamepass
			choiceData.gamepassEmoji = choice.gamepassEmoji
			
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
		end
		
		eventPayload.choices[index] = choiceData
	end
	
	-- Don't update pendingEvents - it should already have this event stored
	-- Push state first so money display is current (nil to avoid duplicate feed message)
	self:pushState(player, nil)
	-- Then re-send the event to the client (PresentEvent adds the feed message)
	self.remotes.PresentEvent:FireClient(player, eventPayload, "Pick a different option!")
	debugPrint("[LifeBackend] Re-presented event for retry:", eventId)
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
			-- CRITICAL FIX: Nil safety for job.company
			local safeCompany = tostring(job.company or "your workplace")
			if state.CareerInfo and (state.CareerInfo.yearsAtJob or 0) > 0 then
				local years = state.CareerInfo.yearsAtJob
				if years >= 10 then
					table.insert(summaryParts, string.format("You've been at %s for %d years now.", safeCompany, years))
				elseif years >= 5 then
					table.insert(summaryParts, string.format("You're well established at %s.", safeCompany))
				end
			else
				-- Just mention they have a job occasionally
				if RANDOM:NextNumber() < 0.3 then
					table.insert(summaryParts, string.format("Work at %s keeps you busy.", safeCompany))
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
	if not state then return end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #963: Timeout for awaitingDecision to prevent permanent softlock!
	-- If player has been stuck for 60+ seconds, force-clear the flag
	-- This prevents permanent softlock if an event fails to resolve properly
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.awaitingDecision then
		local pending = self.pendingEvents and self.pendingEvents[player.UserId]
		local pendingTimestamp = pending and pending.timestamp or state._awaitingDecisionTimestamp
		local currentTime = os.clock()
		
		if pendingTimestamp and (currentTime - pendingTimestamp) > 60 then
			warn("[LifeBackend] ⚠️ SOFTLOCK DETECTED! Clearing awaitingDecision after 60s timeout for", player.Name)
			state.awaitingDecision = false
			self.pendingEvents[player.UserId] = nil
			-- Continue with age up instead of returning
		else
			-- Track when awaiting started
			if not state._awaitingDecisionTimestamp then
				state._awaitingDecisionTimestamp = currentTime
			end
			debugPrint("Age up blocked - awaiting decision for", player.Name)
			return
		end
	end
	
	-- Clear timestamp tracking
	state._awaitingDecisionTimestamp = nil
	
	if state.Flags and state.Flags.dead then
		debugPrint("Age up ignored for dead player", player.Name)
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
	state.Flags.worked_hard_this_year = nil  -- CRITICAL FIX #931: Reset work hard flag for new year
	state.Flags.noticed_by_boss = nil        -- Reset boss notice flag
	
	-- AAA FIX: Clear feed message tracking for new year (prevents duplicate prevention from persisting)
	state._feedMessages = nil

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
				
				-- CRITICAL FIX: Properly handle nil values to prevent string.format errors
				local safeEmoji = tostring(mobState.rankEmoji or "🎉")
				local safeOldRank = tostring(oldRankName or "Associate")
				local safeNewRank = tostring(mobState.rankName or "Soldier")
				appendFeed(state, string.format("%s You've been promoted from %s to %s!", safeEmoji, safeOldRank, safeNewRank))
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
			-- ═══════════════════════════════════════════════════════════════════════
			-- AAA FIX: Comprehensive prison release cleanup
			-- Clears ALL prison-related flags to prevent ghost prison states
			-- ═══════════════════════════════════════════════════════════════════════
			state.InJail = false
			state.JailYearsLeft = 0
			
			-- Clear ALL prison flags (AAA exhaustive list)
			state.Flags.in_prison = nil
			state.Flags.incarcerated = nil
			state.Flags.jailed = nil
			state.Flags.serving_sentence = nil
			state.Flags.awaiting_trial = nil
			state.Flags.on_trial = nil
			state.Flags.arrested = nil
			state.Flags.awaiting_sentencing = nil
			state.Flags.in_solitary = nil
			state.Flags.prison_fight = nil
			state.Flags.on_work_detail = nil
			state.Flags.in_county_jail = nil
			state.Flags.in_federal_prison = nil
			state.Flags.in_maximum_security = nil
			state.Flags.in_minimum_security = nil
			
			-- Set ex-convict flags for future events
			state.Flags.ex_convict = true
			state.Flags.criminal_record = true
			state.Flags.has_served_time = true
			state.Flags.released_from_prison = true
			
			-- Use IntegritySystem to mark major action
			IntegritySystem.markMajorAction(state, "prison_release")
			
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
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- STRATEGIC GAMEPASS PROMPTS AT KEY LIFE MILESTONES
		-- These are PERFECT conversion moments when players feel invested in their character
		-- ═══════════════════════════════════════════════════════════════════════════════
		
		-- Age 18: Player becomes an adult - perfect time for premium features!
		if state.Age == 18 then
			-- Show Mafia gamepass - they can now join organized crime
			if not self:checkGamepassOwnership(player, "MAFIA") then
				task.delay(2, function()
					if player and player.Parent then
						-- Don't force prompt, just make it available
						-- Let the client know they can now use Mafia features
					end
				end)
			end
		end
		
		-- Age 30: "The Big 3-0" - players often want to boost their character
		if state.Age == 30 then
			-- If player isn't wealthy or famous yet, offer Celebrity gamepass
			local money = state.Money or 0
			local isFamous = state.Flags and (state.Flags.is_famous or state.Flags.celebrity)
			if money < 100000 and not isFamous and not self:checkGamepassOwnership(player, "CELEBRITY") then
				task.delay(2, function()
					if player and player.Parent then
						self:promptGamepassPurchase(player, "CELEBRITY")
					end
				end)
			end
		end
		
		-- Age 50: Middle-age crisis - offer God Mode to boost declining stats
		if state.Age == 50 then
			local health = (state.Stats and state.Stats.Health) or 50
			if health < 70 and not self:checkGamepassOwnership(player, "GOD_MODE") then
				task.delay(2, function()
					if player and player.Parent then
						self:promptGamepassPurchase(player, "GOD_MODE")
					end
				end)
			end
		end
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FEATURE: Continue as Your Kid
-- User requested: "I WANT A CONTINUE AS YOUR KID BUTTON WHEN YOU DIE"
-- Player continues playing as their child, inheriting 70% of assets after taxes
-- Can only be used ONCE per life (cannot infinitely chain through generations)
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:handleContinueAsKid(player, childData)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "No life data found." }
	end
	
	-- Must be dead to continue as kid
	if not state.Flags or not state.Flags.dead then
		return { success = false, message = "You can only continue as your kid after dying." }
	end
	
	-- Cannot chain infinitely - check if already used this feature
	if state.Flags.already_continued_as_kid then
		return { success = false, message = "You can only continue as your child once per life." }
	end
	
	-- Find the child to continue as
	if not childData or not childData.id then
		return { success = false, message = "No child data provided." }
	end
	
	local child = nil
	if state.Relationships then
		child = state.Relationships[childData.id]
		if not child then
			-- Try to find by name
			for relId, rel in pairs(state.Relationships) do
				if type(rel) == "table" and rel.name == childData.name then
					child = rel
					break
				end
			end
		end
	end
	
	if not child then
		return { success = false, message = "Could not find that child." }
	end
	
	-- Verify child is eligible (18+, alive)
	if child.age and child.age < 18 then
		return { success = false, message = "Your child must be 18 or older to continue as them." }
	end
	
	if child.deceased or child.alive == false then
		return { success = false, message = "You cannot continue as a deceased child." }
	end
	
	debugPrint("Player", player.Name, "continuing as their child:", child.name or "Child")
	
	-- Calculate inheritance (70% after taxes/fees)
	local parentMoney = state.Money or 0
	local inheritance = math.floor(parentMoney * 0.7)
	
	-- Store parent name for reference
	local parentName = state.Name or "Parent"
	local parentAge = state.Age or 0
	
	-- Create the new state as the child
	local newState = self:createInitialState(player)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Calculate child's actual age properly
	-- The child's age should be their stored age, not reset to something weird
	-- ═══════════════════════════════════════════════════════════════════════════════
	local childAge = child.age or 18
	if childAge < 18 then
		childAge = 18 -- Minimum age to continue as child
	end
	
	-- Set up child's identity
	newState.Name = child.name or child.Name or "Child of " .. parentName
	newState.Gender = child.gender or "male"
	newState.Age = childAge
	newState.Year = (state.Year or 2025) -- Same year
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #FAMILY-DUP: FIX FAMILY MEMBER DUPLICATION BUG!
	-- User complaint: "WHEN FAMILYS LIKE FATHER OR MOTHER ANOTHER ONE SPAWNS IN SOMEHOW"
	-- The old code was creating random NEW parents via createInitialState, but the
	-- child's actual parent is the deceased player character + their partner!
	-- 
	-- Solution: Clear the randomly generated parents and properly set up:
	-- 1. Deceased parent = the player who just died
	-- 2. Living parent = the player's partner (if they had one)
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Clear the randomly generated parents from createInitialState
	newState.Relationships = newState.Relationships or {}
	newState.Relationships["mother"] = nil
	newState.Relationships["father"] = nil
	
	-- Determine which parent the deceased player was (based on their gender)
	local deceasedIsMotherOrFather = (state.Gender == "Female") and "mother" or "father"
	local otherParentRole = (state.Gender == "Female") and "father" or "mother"
	
	-- Create the deceased parent (the player who just died)
	newState.Relationships[deceasedIsMotherOrFather] = {
		id = deceasedIsMotherOrFather,
		name = parentName,
		type = "family",
		role = (state.Gender == "Female") and "Mother" or "Father",
		relationship = child.relationship or 70,
		age = parentAge,
		gender = (state.Gender == "Female") and "female" or "male",
		alive = false, -- DECEASED
		deceased = true,
		deathYear = state.Year or 2025,
		isFamily = true,
		wasPlayer = true, -- Mark that this was the previous player character
	}
	
	-- Set up the other parent (player's spouse/partner if they had one)
	local partnerData = state.Relationships and (state.Relationships.partner or state.Relationships.spouse)
	if partnerData and type(partnerData) == "table" then
		newState.Relationships[otherParentRole] = {
			id = otherParentRole,
			name = partnerData.name or "Parent",
			type = "family",
			role = (otherParentRole == "mother") and "Mother" or "Father",
			relationship = math.max(40, (partnerData.relationship or 50)),
			age = (partnerData.age or parentAge) + childAge, -- Age them up
			gender = (otherParentRole == "mother") and "female" or "male",
			alive = partnerData.alive ~= false, -- Assume alive unless marked dead
			deceased = partnerData.alive == false,
			isFamily = true,
			wasPartner = true, -- Mark that this was the player's partner
		}
	else
		-- No partner - create a generic other parent (could be unknown/absent)
		local RANDOM = Random.new()
		local nameList = (otherParentRole == "mother") and 
			{"Sarah", "Jessica", "Emily", "Ashley", "Rachel", "Amanda", "Michelle", "Jennifer"} or
			{"Michael", "David", "James", "Robert", "William", "Thomas", "Daniel", "Matthew"}
		local genericName = nameList[RANDOM:NextInteger(1, #nameList)]
		
		newState.Relationships[otherParentRole] = {
			id = otherParentRole,
			name = genericName,
			type = "family",
			role = (otherParentRole == "mother") and "Mother" or "Father",
			relationship = 50,
			age = parentAge + RANDOM:NextInteger(-5, 5) + childAge,
			gender = (otherParentRole == "mother") and "female" or "male",
			alive = true,
			isFamily = true,
		}
	end
	
	-- Adjust grandparent ages based on child's starting age
	for relId, rel in pairs(newState.Relationships) do
		if type(rel) == "table" and rel.age and relId:find("grand") then
			-- Age up grandparents by child's age
			rel.age = rel.age + childAge
			
			-- Check if grandparents should be dead at this age
			if rel.age >= 85 then
				rel.alive = false
				rel.deceased = true
			end
		end
	end
	
	-- Also adjust sibling ages
	for relId, rel in pairs(newState.Relationships) do
		if type(rel) == "table" and (relId:find("brother") or relId:find("sister")) then
			if rel.ageOffset then
				rel.age = childAge + rel.ageOffset
			elseif rel.age then
				rel.age = rel.age + childAge
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Update housing state based on age
	-- If child is 18+, they shouldn't be "living with parents"
	-- ═══════════════════════════════════════════════════════════════════════════════
	newState.HousingState = newState.HousingState or {}
	if childAge >= 18 then
		newState.HousingState.status = "renter"
		newState.HousingState.type = "apartment"
		newState.HousingState.rent = 1000 -- Basic starting rent
		newState.Flags.living_with_parents = nil
		newState.Flags.moved_out = true
	end
	
	-- Inherit money
	newState.Money = inheritance
	
	-- Inherit assets
	newState.Assets = newState.Assets or {}
	if state.Assets then
		-- Inherit properties (and update housing if inheriting a home)
		if state.Assets.Properties and #state.Assets.Properties > 0 then
			newState.Assets.Properties = {}
			for _, prop in ipairs(state.Assets.Properties) do
				table.insert(newState.Assets.Properties, {
					id = prop.id,
					name = prop.name,
					emoji = prop.emoji,
					price = prop.price,
					value = prop.value,
					income = prop.income,
					purchasedAt = childAge,
					inherited = true,
					inheritedFrom = parentName,
				})
			end
			-- Update housing to owner if inherited properties
			newState.HousingState.status = "owner"
			newState.HousingState.type = state.Assets.Properties[1].type or "house"
			newState.HousingState.rent = 0
			newState.Flags.homeowner = true
			newState.Flags.has_property = true
		end
		
		-- Inherit vehicles
		if state.Assets.Vehicles and #state.Assets.Vehicles > 0 then
			newState.Assets.Vehicles = {}
			for _, vehicle in ipairs(state.Assets.Vehicles) do
				table.insert(newState.Assets.Vehicles, {
					id = vehicle.id,
					name = vehicle.name,
					emoji = vehicle.emoji,
					price = vehicle.price,
					value = vehicle.value,
					inherited = true,
					inheritedFrom = parentName,
				})
			end
			newState.Flags.has_vehicle = true
			newState.Flags.has_car = true
		end
	end
	
	-- Mark that this life used the continue feature (can't use again)
	newState.Flags = newState.Flags or {}
	newState.Flags.already_continued_as_kid = true
	newState.Flags.inherited_from_parent = true
	newState.Flags.parent_name = parentName
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Better starting stats based on child's situation
	-- ═══════════════════════════════════════════════════════════════════════════════
	local relationship = child.relationship or 50
	newState.Stats = newState.Stats or {}
	newState.Stats.Happiness = clamp(50 + math.floor(relationship / 5), 20, 80)
	newState.Stats.Health = clamp(100 - math.floor(childAge / 3), 60, 100)
	newState.Stats.Smarts = newState.Stats.Smarts or 50
	newState.Stats.Looks = newState.Stats.Looks or 50
	
	-- Also set shorthand access
	newState.Happiness = newState.Stats.Happiness
	newState.Health = newState.Stats.Health
	newState.Smarts = newState.Stats.Smarts
	newState.Looks = newState.Stats.Looks
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #CHILD-1: Clear ALL old life state when continuing as child
	-- User complaint: "Continue as child is buggy - weird spawning and age issues"
	-- Make sure no data from parent life carries over incorrectly
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Clear education state - child needs their own education journey
	newState.EducationData = {
		Level = childAge >= 18 and "high_school" or nil,
		Status = childAge >= 18 and nil or "enrolled",
		inCollege = false,
		GPA = nil,
		Debt = 0,
	}
	
	-- Set appropriate education flags based on age
	if childAge >= 22 then
		newState.Flags.has_diploma = true
		newState.Flags.graduated_high_school = true
	elseif childAge >= 18 then
		newState.Flags.has_diploma = true
		newState.Flags.graduated_high_school = true
	else
		-- Shouldn't happen since we require age 18+, but safety check
		newState.Flags.in_school = true
	end
	
	-- Clear job/career state - child starts fresh
	newState.CurrentJob = nil
	newState.Career = {}
	newState.CareerInfo = nil
	newState.Flags.employed = nil
	newState.Flags.has_job = nil
	
	-- Clear any premium path states from parent
	newState.Flags.is_royalty = nil
	newState.Flags.royal_birth = nil
	newState.Flags.in_mob = nil
	newState.Flags.fame_career = nil
	newState.Flags.is_famous = nil
	newState.RoyalState = nil
	newState.MobState = nil
	newState.FameState = nil
	
	-- Clear relationship states - child has fresh relationship slate
	newState.Flags.married = nil
	newState.Flags.engaged = nil
	newState.Flags.has_partner = nil
	newState.Flags.dating = nil
	newState.Flags.widowed = nil
	newState.Relationships.partner = nil
	
	-- Clear prison state
	newState.InJail = false
	newState.JailYearsLeft = 0
	newState.Flags.in_prison = nil
	newState.Flags.incarcerated = nil
	newState.Flags.criminal_record = nil -- Give child a clean slate
	
	-- Clear event history so child gets fresh events
	newState.EventHistory = {
		occurrences = {},
		lastOccurrence = {},
		completed = {},
		recentCategories = {},
		recentEvents = {},
		lastCategoryOccurrence = {},
	}
	
	-- Create parent as a memory
	newState.Flags.parent_deceased = true
	newState.Flags.grieving = true
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #INHERIT-1: Add more variety and depth to inheritance experience
	-- User requested: "ENSURE CONTINUE AS KID WORKS BETTER AND ISN'T BORING"
	-- Add special starting flags that create unique events for inherited characters
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Track the size of inheritance (affects story)
	if inheritance >= 500000 then
		newState.Flags.large_inheritance = true
		newState.Flags.wealthy_background = true
	elseif inheritance >= 100000 then
		newState.Flags.moderate_inheritance = true
		newState.Flags.comfortable_background = true
	elseif inheritance >= 10000 then
		newState.Flags.small_inheritance = true
	else
		newState.Flags.minimal_inheritance = true
		newState.Flags.starting_from_scratch = true
	end
	
	-- Track relationship with parent (affects grief events)
	local childRelationship = child.relationship or 50
	if childRelationship >= 80 then
		newState.Flags.close_with_parent = true
		newState.Flags.intense_grief = true
	elseif childRelationship >= 50 then
		newState.Flags.normal_parent_relationship = true
	elseif childRelationship >= 30 then
		newState.Flags.distant_from_parent = true
		newState.Flags.complicated_grief = true
	else
		newState.Flags.estranged_from_parent = true
		newState.Flags.guilt_feelings = true
	end
	
	-- If parent was famous/notorious, child inherits that legacy
	if state.Flags and (state.Flags.famous or state.Flags.celebrity or state.Flags.is_famous) then
		newState.Flags.famous_parent = true
		newState.Flags.celebrity_child = true
	end
	
	if state.Flags and (state.Flags.criminal or state.Flags.has_criminal_record or state.Flags.notorious) then
		newState.Flags.criminal_parent = true
		newState.Flags.parents_shadow = true
	end
	
	if state.Flags and (state.Flags.philanthropist or state.Flags.charitable or state.Flags.community_pillar) then
		newState.Flags.respected_parent = true
		newState.Flags.good_family_name = true
	end
	
	-- Career legacy potential
	if state.CurrentJob and state.CurrentJob.id then
		local parentJob = state.CurrentJob.id:lower()
		if parentJob:find("doctor") or parentJob:find("surgeon") or parentJob:find("medical") then
			newState.Flags.medical_family = true
		elseif parentJob:find("lawyer") or parentJob:find("attorney") then
			newState.Flags.legal_family = true
		elseif parentJob:find("business") or parentJob:find("ceo") or parentJob:find("executive") then
			newState.Flags.business_family = true
		elseif parentJob:find("military") or parentJob:find("army") or parentJob:find("marine") then
			newState.Flags.military_family = true
		elseif parentJob:find("teacher") or parentJob:find("professor") then
			newState.Flags.education_family = true
		end
	end
	
	-- Store the new state
	self.playerStates[player] = newState
	
	-- Clear pending events
	self.pendingEvents[player.UserId] = nil
	
	-- Build a nice starting message
	local genderText = newState.Gender == "female" and "daughter" or "son"
	local message = string.format("You are now %s, age %d, %s of %s. You inherited $%s from your parent's estate.",
		newState.Name, newState.Age, genderText, parentName, formatMoney(inheritance))
	
	debugPrint("Continue as kid complete:", message)
	
	-- Save and push state
	self:pushState(player, message)
	
	return { 
		success = true, 
		message = message,
		newName = newState.Name,
		newAge = newState.Age,
		inheritance = inheritance,
	}
end

function LifeBackend:completeAgeCycle(player, state, feedText, resultData)
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Show relationship decay events as proper card popups!
	-- User reported: "Robert is furious!" was showing as feed text, not card popup
	-- These queued popups should display as actual card popups instead of feed text!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.QueuedRelationshipPopups and #state.QueuedRelationshipPopups > 0 then
		-- Take the first (most important) relationship popup
		local relPopup = table.remove(state.QueuedRelationshipPopups, 1)
		if relPopup and not resultData then
			-- Only show if there's no other resultData (don't override important events)
			resultData = {
				showPopup = true,
				emoji = relPopup.emoji or "💔",
				title = relPopup.title or "Relationship Update",
				body = relPopup.body or "Something happened with a relationship.",
				happiness = relPopup.happiness,
				health = relPopup.health,
				wasSuccess = false,
			}
		end
		-- Clear remaining popups for this year (to avoid spam)
		state.QueuedRelationshipPopups = nil
	end
	
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
		
		-- CRITICAL FIX #913: Prompt Time Machine purchase for non-owners on death!
		-- This is THE HIGHEST CONVERSION moment - player just died and wants to save their character!
		-- CRITICAL FIX: Show helpful popup FIRST explaining what Time Machine does!
		if not hasTimeMachineGamepass and self.gamepassSystem then
			-- Show helpful popup explaining Time Machine FIRST
			task.delay(1, function()
				if player and player.Parent then
					self:showTimeMachineOffer(player, "death")
				end
			end)
			-- Then prompt purchase after player sees the explanation
			task.delay(4, function()
				if player and player.Parent then
					self.gamepassSystem:promptGamepass(player, "TIME_MACHINE")
				end
			end)
		end
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FEATURE: "Continue as Your Kid" on death!
		-- User requested: "I WANT A CONTINUE AS YOUR KID BUTTON WHEN YOU DIE"
		-- Player can continue with their child, inheriting assets but living their own life
		-- Can only use this ONCE per life (not infinitely)
		-- ═══════════════════════════════════════════════════════════════════════════════
		local continueAsKidData = nil
		local canContinueAsKid = false
		local eligibleChild = nil
		
		-- Check if player has any living adult children (18+)
		if state.Relationships and not state.Flags.already_continued_as_kid then
			for relId, rel in pairs(state.Relationships) do
				if type(rel) == "table" then
					local isChild = rel.type == "child" or rel.role == "Child" 
						or relId:find("child") or relId:find("son") or relId:find("daughter")
					local isAlive = rel.alive ~= false and not rel.deceased
					local isAdult = (rel.age or 0) >= 18
					
					if isChild and isAlive and isAdult then
						eligibleChild = {
							id = relId,
							name = rel.name or rel.Name or "Your Child",
							age = rel.age or 18,
							gender = rel.gender or "male",
							relationship = rel.relationship or 50,
						}
						canContinueAsKid = true
						break -- Take first eligible child
					end
				end
			end
		end
		
		if canContinueAsKid and eligibleChild then
			-- Calculate inheritance
			local inheritance = math.floor((state.Money or 0) * 0.7) -- 70% after taxes/fees
			local inheritedAssets = {}
			
			-- Copy real estate
			if state.Assets and state.Assets.Properties then
				for _, prop in ipairs(state.Assets.Properties) do
					table.insert(inheritedAssets, {
						type = "property",
						id = prop.id,
						name = prop.name,
						value = prop.value or prop.price,
					})
				end
			end
			
			-- Copy vehicles
			if state.Assets and state.Assets.Vehicles then
				for _, vehicle in ipairs(state.Assets.Vehicles) do
					table.insert(inheritedAssets, {
						type = "vehicle",
						id = vehicle.id,
						name = vehicle.name,
						value = vehicle.value or vehicle.price,
					})
				end
			end
			
			continueAsKidData = {
				canContinue = true,
				child = eligibleChild,
				inheritance = inheritance,
				inheritedAssets = inheritedAssets,
				parentName = state.Name or "Parent",
				parentNetWorth = state.Money or 0,
			}
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
			-- CRITICAL FEATURE: Continue as kid option
			canContinueAsKid = canContinueAsKid,
			continueAsKidData = continueAsKidData,
		}
	end

	self:pushState(player, feedText, resultData)
end

function LifeBackend:resolvePendingEvent(player, eventId, choiceIndex)
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #962: Clear awaitingDecision on ALL early returns to prevent softlock!
	-- If this function fails for any reason, player should NOT be stuck unable to age up
	-- ═══════════════════════════════════════════════════════════════════════════════
	local function clearAwaitingOnError()
		local state = self:getState(player)
		if state then
			state.awaitingDecision = false
		end
		self.pendingEvents[player.UserId] = nil
	end
	
	local pending = self.pendingEvents[player.UserId]
	if not pending then
		clearAwaitingOnError()
		return
	end
	if pending.activeEventId and pending.activeEventId ~= eventId then
		-- Don't clear for mismatched eventId - might be legitimate queue
		return
	end

	local eventDef
	if pending.queue then
		eventDef = pending.definition or pending.queue[pending.cursor]
	else
		eventDef = pending.definition
	end
	if not eventDef then
		warn("[LifeBackend] No event definition found - clearing to prevent softlock")
		clearAwaitingOnError()
		return
	end

	local choices = eventDef.choices or {}
	local choice = choices[choiceIndex]
	if not choice then
		warn("[LifeBackend] Invalid choice index", choiceIndex, "- clearing to prevent softlock")
		clearAwaitingOnError()
		return
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Check if this choice was already marked unavailable
	-- Prevents player from clicking the same unaffordable choice repeatedly
	-- ═══════════════════════════════════════════════════════════════════════════════
	if eventDef._unavailableChoices and eventDef._unavailableChoices[choiceIndex] then
		local reason = eventDef._unavailableChoices[choiceIndex]
		warn("[LifeBackend] Player tried to select unavailable choice", choiceIndex, ":", reason)
		
		-- Re-show the event so they can pick something else
		self:pushState(player, nil, {
			showPopup = true,
			emoji = "❌",
			title = "Can't Do That!",
			body = reason .. "\n\nPlease pick a different option.",
			wasSuccess = false,
		})
		
		-- Re-present the event after brief delay
		task.delay(0.1, function()
			if self.pendingEvents[player.UserId] then
				self:presentEventForRetry(player, eventDef, eventId)
			end
		end)
		return
	end

	debugPrint(string.format("Resolving event %s for %s with choice #%d", eventId or "unknown", player.Name, choiceIndex))

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
		
		-- CRITICAL FIX: Handle nil values safely
		local safePlayerName = tostring((player and player.Name) or "Unknown")
		local safeMinigame = tostring(choice.triggerMinigame or "unknown")
		debugPrint(string.format("Minigame triggered for %s: %s", safePlayerName, safeMinigame))
		return -- Wait for minigame result
	end

	-- CRITICAL: Track jail state BEFORE event processing to detect incarceration
	local wasInJailBefore = state.InJail or false

	if choice.effects or eventDef.source == "lifeevents" or eventDef.source == "stage" then
		local preStats = table.clone(state.Stats)
		local preMoney = state.Money
		local success, result = pcall(function()
			return EventEngine.completeEvent(eventDef, choiceIndex, state)
		end)
		if not success then
			warn("[LifeBackend] Event resolution error:", result)
		elseif result and result.failed then
			-- ═══════════════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX: When choice fails, RE-SHOW the event so player can pick another!
			-- User feedback: "have it just u click OK and it goes back to let u choose"
			-- 
			-- Flow: Error popup → Click OK → Same event re-appears → Pick different choice
			-- ═══════════════════════════════════════════════════════════════════════════════
			local errorMessage = result.failReason or "You can't select this option right now."
			warn("[LifeBackend] Choice", choiceIndex, "failed eligibility:", errorMessage, "- will re-show event")
			
			-- DON'T clear awaitingDecision or pendingEvents - event stays active!
			-- The pendingEvent is still there, player just needs to pick again
			
			-- Mark this choice as unavailable so UI can gray it out
			eventDef._unavailableChoices = eventDef._unavailableChoices or {}
			eventDef._unavailableChoices[choiceIndex] = errorMessage
			
			-- Send special response that will show error then re-present the event
			self:pushState(player, nil, {
				showPopup = true,
				emoji = "❌",
				title = "Can't Do That!",
				body = errorMessage,
				wasSuccess = false,
				-- After dismissing this popup, re-show the event
				reshowEvent = true,
				reshowEventId = eventId,
			})
			
			-- Schedule re-presenting the event after a brief delay for popup
			-- This gives time for the error popup to show first
			task.delay(0.1, function()
				if self.pendingEvents[player.UserId] then
					-- Re-present the same event with updated unavailable choices info
					self:presentEventForRetry(player, eventDef, eventId)
				end
			end)
			return
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
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- STRATEGIC GAMEPASS PROMPT: When player gets arrested, offer Time Machine!
		-- This is the PERFECT conversion moment - they want to undo the arrest
		-- Only prompt if they don't already own Time Machine
		-- CRITICAL FIX: Show a helpful popup FIRST explaining what Time Machine does!
		-- ═══════════════════════════════════════════════════════════════════════════════
		if not self:checkGamepassOwnership(player, "TIME_MACHINE") then
			-- Show helpful popup explaining Time Machine FIRST
			task.delay(0.5, function()
				if player and player.Parent then
					self:showTimeMachineOffer(player, "jail")
				end
			end)
			-- Then prompt purchase after player sees the explanation
			task.delay(3, function()
				if player and player.Parent then
					self:promptGamepassPurchase(player, "TIME_MACHINE")
				end
			end)
		end
	end

	-- CRITICAL FIX: Use PendingFeed (detailed outcome from onResolve) for popup body
	-- Fall back to feedText (short choice text) only if no detailed outcome was set
	local popupBody = jailPopupBody or state.PendingFeed or feedText
	if popupBody == nil or popupBody == "" then
		popupBody = "Something happened..."
	end
	
	-- CRITICAL FIX: Replace any remaining template variables in popup body
	-- User bug: "it says {{AGE}}! and not correctly working"
	if type(popupBody) == "string" then
		popupBody = popupBody:gsub("{{AGE}}", tostring(state.Age or 0))
		popupBody = popupBody:gsub("{{NAME}}", tostring(state.Name or "You"))
		popupBody = popupBody:gsub("{{MONEY}}", tostring(state.Money or 0))
		popupBody = popupBody:gsub("{{GENDER}}", tostring(state.Gender or "person"))
		-- Parent names
		local motherName, fatherName = "Mom", "Dad"
		if state.Relationships then
			if state.Relationships.mother and state.Relationships.mother.name then
				motherName = state.Relationships.mother.name
			end
			if state.Relationships.father and state.Relationships.father.name then
				fatherName = state.Relationships.father.name
			end
		end
		popupBody = popupBody:gsub("{{MOTHER_NAME}}", motherName)
		popupBody = popupBody:gsub("{{FATHER_NAME}}", fatherName)
		-- Job info
		if state.CurrentJob then
			popupBody = popupBody:gsub("{{JOB_NAME}}", tostring(state.CurrentJob.name or "your job"))
			popupBody = popupBody:gsub("{{COMPANY}}", tostring(state.CurrentJob.company or "the company"))
			popupBody = popupBody:gsub("{{SALARY}}", tostring(state.CurrentJob.salary or 0))
		else
			popupBody = popupBody:gsub("{{JOB_NAME}}", "your job")
			popupBody = popupBody:gsub("{{COMPANY}}", "the company")
			popupBody = popupBody:gsub("{{SALARY}}", "0")
		end
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
	-- CRITICAL FIX: Handle second blockedByFlag check
	if activity.blockedByFlag2 and state.Flags[activity.blockedByFlag2] then
		return { success = false, message = "You've already done this!" }
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: ROMANCE ACTIVITY REQUIREMENTS
	-- Check if the activity requires having a partner or being single
	-- ═══════════════════════════════════════════════════════════════════════════════
	local hasPartner = state.Flags.has_partner or state.Flags.dating or state.Flags.married or
		(state.Relationships and state.Relationships.partner ~= nil) or
		(state.Relationships and state.Relationships.spouse ~= nil)
	
	if activity.requiresPartner and not hasPartner then
		return { success = false, message = "You need to be in a relationship first! Try looking for love." }
	end
	
	if activity.requiresSingle and hasPartner then
		return { success = false, message = "You're already in a relationship!" }
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
			elseif activity.requiresFlag == "dating_royalty" then
				-- Accept multiple ways to be dating royalty
				hasRequiredFlag = state.Flags.royal_romance 
					or (state.Relationships and state.Relationships.partner and state.Relationships.partner.isRoyalty)
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
			elseif activity.requiresFlag == "dating_royalty" then
				helpfulMessage = "You need to be dating a royal first!"
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
	-- CRITICAL FIX: Check activity cooldown to prevent spam (like proposal spam)
	-- User bug: "I CAN SPAM PROPOSE??"
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.cooldownYears and activity.cooldownYears > 0 then
		state.ActivityCooldowns = state.ActivityCooldowns or {}
		local lastUsedAge = state.ActivityCooldowns[activityId]
		local currentAge = state.Age or 0
		if lastUsedAge and (currentAge - lastUsedAge) < activity.cooldownYears then
			local yearsLeft = activity.cooldownYears - (currentAge - lastUsedAge)
			return { 
				success = false, 
				message = string.format("You need to wait %d more year(s) before you can do this again.", math.ceil(yearsLeft))
			}
		end
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
	-- CRITICAL FIX #942: SKIP early risk check for activities with minigames!
	-- The minigame result determines success/failure - don't pre-roll risk here!
	-- This was causing "Plan a Heist success but got caught" bug!
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
		-- CRITICAL FIX #942: Skip early risk check for minigame activities!
		-- For activities with hasMinigame=true, the risk check happens AFTER minigame result
		-- in the mafiaEffect section below (lines 15769+)
		local skipEarlyRiskCheck = activity.hasMinigame or activity.mafiaEffect
		
		if activity.risk and not skipEarlyRiskCheck and RANDOM:NextInteger(1, 100) <= activity.risk then
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
	-- CRITICAL FIX: Record activity cooldown time to prevent spam
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.cooldownYears and activity.cooldownYears > 0 then
		state.ActivityCooldowns = state.ActivityCooldowns or {}
		state.ActivityCooldowns[activityId] = state.Age or 0
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
	-- CRITICAL FIX #800: MINIGAME WIN = GUARANTEED SUCCESS, NO ARREST!
	-- User complaint: "Plan a Heist shows crime successful but says you got caught"
	-- BUG: Code was reducing risk by 80% but STILL rolling for arrest. WRONG!
	-- FIX: If player WON the minigame, they EARNED their success - NO RISK CHECK!
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
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #800: CHECK IF MINIGAME WAS WON FIRST!
		-- If player WON the minigame, they get GUARANTEED SUCCESS with NO ARREST!
		-- Only do risk check if minigame was NOT won or no minigame was played
		-- ═══════════════════════════════════════════════════════════════════════════════
		local minigameWasWon = false
		
		-- Check all possible ways minigame win can be communicated
		if minigameBonus == true then
			minigameWasWon = true
		elseif type(minigameBonus) == "table" then
			if minigameBonus.won or minigameBonus.success or minigameBonus.heistSuccess or minigameBonus.combatWon then
				minigameWasWon = true
			end
		end
		
		-- CRITICAL FIX #801: If minigame was won, SKIP risk check entirely!
		if minigameWasWon then
			-- Player WON the minigame - GUARANTEED success, NO risk of arrest!
			resultMessage = "🎯 " .. resultMessage .. " Your skills paid off - perfect execution!"
			-- Bonus respect for winning the minigame
			state.MobState.respect = (state.MobState.respect or 0) + 10
			-- EXPLICIT: NO JAIL POSSIBLE WHEN MINIGAME IS WON!
			-- Do NOT set gotCaught = true, do NOT check risk, do NOT pass Go, do NOT go to jail!
		elseif activity.risk then
			-- ONLY check risk if minigame was NOT won (or no minigame was played)
			local actualRisk = activity.risk
			
			-- Reduce risk based on player's stats and experience
			local smarts = (state.Stats and state.Stats.Smarts) or 50
			if smarts > 70 then
				actualRisk = actualRisk - math.floor((smarts - 70) / 5)
			end
			if state.MobState.operationsCompleted and state.MobState.operationsCompleted > 10 then
				actualRisk = actualRisk - 5 -- Experienced mobster bonus
			end
			
			-- If minigame was failed, increase risk
			if minigameBonus == false or (type(minigameBonus) == "table" and minigameBonus.failed) then
				actualRisk = actualRisk + 20 -- Failed minigame = higher risk
			end
			
			-- CRITICAL: Make sure actualRisk stays in valid range
			actualRisk = math.max(5, math.min(95, actualRisk))
			
			-- Roll for getting caught
			if RANDOM:NextInteger(1, 100) <= actualRisk then
				-- Got caught doing mafia business
				local jailYears = math.ceil(activity.risk / 15)
				state.InJail = true
				state.JailYearsLeft = jailYears
				state.Flags.in_prison = true
				state.Flags.incarcerated = true
				-- Preserve mob membership when jailed from mafia ops
				if state.Flags.in_mob or (state.MobState and state.MobState.inMob) then
					state.Flags.was_in_mob_before_jail = true
				end
				resultMessage = "🚔 You got caught! Sentenced to " .. jailYears .. " years in prison."
				gotCaught = true
				
				-- CRITICAL FIX #901: Prompt GET OUT OF JAIL purchase when player gets arrested!
				-- This is a PERFECT moment to offer - player just lost everything!
				task.delay(1.5, function()
					if player and player.Parent and self.gamepassSystem then
						self.gamepassSystem:promptProduct(player, "GET_OUT_OF_JAIL")
					end
				end)
			else
				-- CRITICAL: Explicitly show that crime succeeded with NO jail
				resultMessage = "💰 " .. resultMessage .. " Got away clean!"
			end
		end
	end

	-- CRITICAL FIX #311: Don't push state for activities - this was causing screen closures!
	-- The client shows its own result popup via showResult() in ActivitiesScreen
	-- State will sync on next age up naturally
	-- self:pushState(player, resultMessage)  -- DISABLED - was closing ActivitiesScreen
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: DATING ROYALTY ACTIVITIES - Handle relationship and fame bonuses
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.relationshipBonus then
		-- Improve relationship with royal partner
		if state.Relationships and state.Relationships.partner then
			-- AAA FIX: Nil check before accessing partner relationship
			if state.Relationships and state.Relationships.partner then
				state.Relationships.partner.relationship = math.min(100, 
					(state.Relationships.partner.relationship or 50) + activity.relationshipBonus)
			end
		end
	end
	
	if activity.fameBonus then
		state.Fame = math.clamp((state.Fame or 0) + activity.fameBonus, 0, 100)
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- AAA FIX: FRIEND INTERACTION SYSTEM
	-- Like the competition game - friends get angry if you don't talk to them!
	-- These activities reset the friend contact timer and prevent anger events
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.friendInteraction or activity.friendReconcile then
		state.Relationships = state.Relationships or {}
		local friendsFound = 0
		local friendUpdated = nil
		
		-- Find all friends
		local friends = {}
		for relId, rel in pairs(state.Relationships) do
			if type(rel) == "table" then
				local isFriend = rel.type == "friend" or (type(relId) == "string" and relId:find("friend"))
				if isFriend and rel.alive ~= false and not rel.estranged then
					table.insert(friends, { id = relId, rel = rel })
				end
			end
		end
		
		if #friends > 0 then
			-- Pick a random friend to interact with (or priority to angry friend)
			local targetFriend = nil
			
			-- If reconciling, prioritize angry friends
			if activity.friendReconcile then
				for _, f in ipairs(friends) do
					if f.rel.angry or f.rel.furious or f.rel.neglected then
						targetFriend = f
						break
					end
				end
			end
			
			-- Otherwise random friend
			if not targetFriend then
				targetFriend = friends[RANDOM:NextInteger(1, #friends)]
			end
			
			if targetFriend then
				local rel = targetFriend.rel
				
				-- Reset contact timer using RelationshipDecaySystem
				RelationshipDecaySystem.recordContact(state, targetFriend.id)
				
				-- Also set lastContact directly for compatibility
				rel.lastContact = state.Age or 0
				
				-- Clear anger flags if reconciling
				if activity.friendReconcile then
					if rel.angry or rel.furious or rel.neglected then
						rel.angry = nil
						rel.furious = nil
						rel.neglected = nil
						rel._announcedAnnoyed = nil
						rel._announcedAngry = nil
						rel._announcedFurious = nil
						appendFeed(state, string.format("🤝 You made up with %s! Your friendship is saved.", rel.name or "your friend"))
					end
				end
				
				-- Boost relationship
				if activity.relationshipBoostFriend then
					rel.relationship = math.min(100, (rel.relationship or 50) + activity.relationshipBoostFriend)
				end
				
				friendUpdated = rel.name or "your friend"
				
				-- Clear global angry friend flags if this was the angry one
				if state.Flags and state.Flags.angry_friend_id == targetFriend.id then
					state.Flags.has_angry_friend = nil
					state.Flags.angry_friend_name = nil
					state.Flags.angry_friend_id = nil
				end
			end
		else
			-- No friends to interact with
			if not activity.friendReconcile then
				-- Still get happiness from doing the activity alone
				resultMessage = resultMessage .. " (You don't have any friends to do this with though...)"
			else
				resultMessage = "You don't have any angry friends to reconcile with."
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: ROMANCE SEARCH ACTIVITIES (Look for Love, Online Dating, Flirt)
	-- These have a chance to create a new partner relationship
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.isRomanceSearch then
		local looks = (state.Stats and state.Stats.Looks) or 50
		local happiness = (state.Stats and state.Stats.Happiness) or 50
		local baseChance = 0.25 -- 25% base chance to meet someone
		local successChance = baseChance + (looks / 400) + (happiness / 500) -- Max ~55% with high stats
		
		if RANDOM:NextNumber() < successChance then
			-- Success! Create a new partner
			state.Relationships = state.Relationships or {}
			state.Flags = state.Flags or {}
			
			-- CRITICAL FIX: Partner should be OPPOSITE gender by default!
			-- User bug: "As a girl it only lets me romance girls"
			local playerGender = (state.Gender or "male"):lower()
			local partnerIsMale = (playerGender == "female") -- If player is female, partner is male
			local maleNames = {"James", "Michael", "David", "John", "Alex", "Ryan", "Chris", "Brandon", "Tyler", "Jake", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Ben", "Sam", "Will", "Matt", "Nick"}
			local femaleNames = {"Emma", "Olivia", "Sophia", "Ava", "Isabella", "Mia", "Emily", "Grace", "Lily", "Chloe", "Harper", "Aria", "Luna", "Zoe", "Riley", "Ella", "Scarlett", "Victoria", "Madison", "Hannah"}
			local names = partnerIsMale and maleNames or femaleNames
			local partnerName = names[RANDOM:NextInteger(1, #names)]
			
			state.Relationships.partner = {
				id = "partner",
				name = partnerName,
				type = "romantic",
				role = partnerIsMale and "Boyfriend" or "Girlfriend",
				relationship = RANDOM:NextInteger(55, 75),
				age = (state.Age or 20) + RANDOM:NextInteger(-5, 5),
				gender = partnerIsMale and "male" or "female",
				alive = true,
				metAge = state.Age,
				metYear = state.Year or 2025,
			}
			
			state.Flags.has_partner = true
			state.Flags.dating = true
			
			resultMessage = string.format("💕 You met %s! You're now dating!", partnerName)
			self:applyStatChanges(state, { Happiness = 10 }) -- Extra happiness for finding love
		else
			resultMessage = "💔 No luck finding love this time. Keep trying!"
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: PARTNER RELATIONSHIP BOOST (Go on Date, Romantic Dinner, etc.)
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.relationshipBoostPartner then
		local partner = state.Relationships and state.Relationships.partner
		if partner then
			partner.relationship = math.min(100, (partner.relationship or 50) + activity.relationshipBoostPartner)
			local partnerName = partner.name or "your partner"
			resultMessage = string.format("💕 You had a great time with %s! (Relationship +%d)", partnerName, activity.relationshipBoostPartner)
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: FRIEND MAKING ACTIVITY
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.isFriendMaking then
		state.Relationships = state.Relationships or {}
		
		-- Generate new friend
		local isMale = RANDOM:NextNumber() > 0.5
		local maleNames = {"Josh", "Kevin", "Marcus", "Derek", "Evan", "Austin", "Trevor", "Kyle", "Zack", "Blake"}
		local femaleNames = {"Taylor", "Morgan", "Jordan", "Casey", "Alex", "Riley", "Avery", "Quinn", "Peyton", "Skyler"}
		local names = isMale and maleNames or femaleNames
		local friendName = names[RANDOM:NextInteger(1, #names)]
		local friendId = "friend_" .. tostring(os.time()) .. "_" .. RANDOM:NextInteger(1, 9999)
		
		state.Relationships[friendId] = {
			id = friendId,
			name = friendName,
			type = "friend",
			role = "Friend",
			relationship = RANDOM:NextInteger(50, 70),
			age = (state.Age or 20) + RANDOM:NextInteger(-5, 5),
			gender = isMale and "male" or "female",
			alive = true,
			metAge = state.Age,
			lastContact = state.Age,
		}
		
		resultMessage = string.format("👋 You made a new friend: %s!", friendName)
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: WEDDING ACTIVITY - Get married!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.isWedding then
		local partner = state.Relationships and state.Relationships.partner
		if partner then
			-- Convert partner to spouse
			state.Relationships.spouse = partner
			state.Relationships.spouse.type = "spouse"
			state.Relationships.spouse.role = "Spouse"
			state.Relationships.spouse.relationship = math.min(100, (partner.relationship or 70) + 20)
			state.Relationships.partner = nil
			
			-- Set marriage flags
			state.Flags = state.Flags or {}
			state.Flags.married = true
			state.Flags.engaged = nil
			state.Flags.getting_married = nil
			state.Flags.has_partner = true -- Still have a partner (spouse counts)
			state.Flags.dating = nil -- Not dating anymore, married!
			
			local spouseName = state.Relationships.spouse.name or "your spouse"
			resultMessage = string.format("💒 You married %s! Congratulations on your wedding!", spouseName)
			self:applyStatChanges(state, { Happiness = 25 }) -- Wedding happiness boost
		else
			resultMessage = "You need to be engaged to someone first!"
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: ROYAL PROPOSAL - Become royalty through marriage!
	-- This is the culmination of the dating royalty path
	-- ═══════════════════════════════════════════════════════════════════════════════
	if activity.isProposal then
		-- Check if royal partner exists and wants to marry
		local partner = state.Relationships and state.Relationships.partner
		
		-- First handle REGULAR (non-royal) proposals
		if partner and not partner.isRoyalty then
			local relationship = partner.relationship or 50
			local successChance = 0.4 + (relationship / 200) -- 40% base + up to 50% from relationship
			
			if RANDOM:NextNumber() < successChance then
				-- PROPOSAL ACCEPTED!
				state.Flags = state.Flags or {}
				state.Flags.engaged = true
				state.Flags.getting_married = true
				partner.type = "fiance"
				partner.role = "Fiancé"
				partner.relationship = math.min(100, (partner.relationship or 70) + 15)
				
				local partnerName = partner.name or "your partner"
				resultMessage = string.format("💍 %s said YES! You're engaged!", partnerName)
				self:applyStatChanges(state, { Happiness = 20 }) -- Engagement happiness
			else
				-- Proposal rejected
				state.Flags.proposal_rejected = true
				self:applyStatChanges(state, { Happiness = -15 })
				resultMessage = "💔 They said they need more time... Your proposal was rejected."
			end
		-- Then handle royal proposals (existing logic)
		elseif partner and partner.isRoyalty then
			local relationship = partner.relationship or 50
			local successChance = 0.3 + (relationship / 200) -- 30% base + up to 50% from relationship
			
			if state.Flags.royal_etiquette then
				successChance = successChance + 0.15 -- Bonus for learning etiquette
			end
			
			if RANDOM:NextNumber() < successChance then
				-- PROPOSAL ACCEPTED! Become royalty!
				-- CRITICAL FIX: Clear any conflicting premium states first!
				self:clearConflictingPremiumStates(state, "royalty")
				
				state.Flags.married = true
				state.Flags.married_to_royalty = true
				state.Flags.is_royalty = true
				state.Flags.royal_by_marriage = true
				state.Flags.dating_royalty = nil -- No longer just dating
				state.Flags.royal_romance = nil
				
				-- Initialize RoyalState
				state.RoyalState = state.RoyalState or {}
				state.RoyalState.isRoyal = true
				state.RoyalState.royalByMarriage = true
				state.RoyalState.country = partner.royalCountry or "European Kingdom"
				state.RoyalState.title = state.Gender == "Female" and "Princess" or "Prince"
				state.RoyalState.popularity = 60
				state.RoyalState.spouse = partner.name
				
				-- Update partner relationship
				partner.type = "spouse"
				partner.role = "Royal Spouse"
				partner.relationship = 95
				
				-- Big money from royal wedding
				self:addMoney(state, 500000)
				
				resultMessage = "💍👑 THEY SAID YES! You married " .. (partner.name or "your royal partner") .. " and are now ROYALTY! Your fairy tale dreams came true!"
				
				-- Add to year log
				state.YearLog = state.YearLog or {}
				table.insert(state.YearLog, {
					type = "royal_wedding",
					emoji = "👑",
					text = "You married into royalty and became a " .. (state.RoyalState.title or "Royal") .. "!",
				})
			else
				-- Proposal declined (but can try again later)
				resultMessage = "💔 They said they need more time... The royal family has concerns. Keep building your relationship!"
				state.Flags.proposed_to_royal = nil -- Allow trying again
				self:applyStatChanges(state, { Happiness = -15 })
			end
		else
			resultMessage = "💔 You're not dating anyone to propose to!"
		end
	end
	
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
	-- CRITICAL FIX #700: Minigame WIN = GUARANTEED SUCCESS!
	-- User complaint: "crime ones even if successful still jail me"
	-- When a player WINS the minigame, they've EARNED their success - NO JAIL!
	-- ═══════════════════════════════════════════════════════════════════════════════
	local minigameWon = false
	local minigameFailed = false
	
	if minigameBonus == true then
		minigameWon = true
	elseif type(minigameBonus) == "table" then
		-- Handle table format { won = true, success = true, isCombat = true }
		if minigameBonus.won or minigameBonus.success then
			minigameWon = true
		elseif minigameBonus.escaped then
			riskModifier = riskModifier - 15 -- Escaped = significant bonus
		elseif minigameBonus.won == false or minigameBonus.success == false then
			minigameFailed = true
		end
	elseif minigameBonus == false and crime.hasMinigame then
		minigameFailed = true
	end
	
	-- If player WON the minigame, they CANNOT get caught - period!
	if minigameWon then
		-- GUARANTEED SUCCESS - Player earned this through skill!
		local reward = 0
		if crime.reward then
			reward = RANDOM:NextInteger(crime.reward[1] or 0, crime.reward[2] or 100)
			-- Bonus for minigame win!
			reward = math.floor(reward * 1.25)
			self:addMoney(state, reward)
		end
		state.Flags.successful_criminal = true
		state.Flags.criminal_experience = (state.Flags.criminal_experience or 0) + 1
		if (state.Flags.criminal_experience or 0) >= 5 then
			state.Flags.experienced_criminal = true
		end
		
		-- ═══════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Apply grantsFlags from crime catalog!
		-- User complaint: "petty crimes should let u become a smuggler"
		-- This sets criminal_background, crime_experience, etc. for career unlocks
		-- ═══════════════════════════════════════════════════════════════════════════
		if crime.grantsFlags then
			for _, flagName in ipairs(crime.grantsFlags) do
				state.Flags[flagName] = true
			end
		end
		-- Always set these on successful crime
		state.Flags.criminal_record = true
		state.Flags.crime_experience = true
		state.Flags.criminal_background = true
		
		local crimeName = crime.name or crimeId
		local message = string.format("💰 Perfect execution! %s succeeded - you got away clean with $%d!", crimeName, reward)
		self:pushState(player, message)
		return { 
			success = true, 
			caught = false, 
			message = message, 
			money = reward,
			perfectExecution = true,
			crimeName = crimeName,
		}
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Combat-based crimes MUST fail if combat was lost!
	-- User complaint: "I GOT KNOCKED OUT AND IT SAID CRIME SUCCESSFUL"
	-- If you get knocked out trying to assault/mug someone, you LOST - the crime failed!
	-- This is different from minigame-based crimes where failure just increases risk.
	-- ═══════════════════════════════════════════════════════════════════════════════
	local combatCrimes = { assault = true, mugging = true, prison_assault = true, prison_riot = true }
	local isCombatCrime = combatCrimes[crimeId] or (type(minigameBonus) == "table" and minigameBonus.isCombat)
	
	if minigameFailed and isCombatCrime then
		-- You got knocked out! Crime automatically fails + health damage
		local healthLoss = RANDOM:NextInteger(10, 25)
		state.Stats = state.Stats or {}
		local currentHealth = state.Stats.Health or state.Health or 50
		state.Stats.Health = math.max(0, currentHealth - healthLoss)
		state.Health = state.Stats.Health
		
		-- Apply embarrassment/happiness loss
		self:applyStatChanges(state, { Happiness = -15 })
		
		-- Random chance cops were called during the altercation
		local copsCalled = RANDOM:NextInteger(1, 100) <= 25  -- 25% chance someone called cops
		
		if copsCalled then
			local years = RANDOM:NextInteger(crime.jail.min, crime.jail.max)
			state.InJail = true
			state.JailYearsLeft = years
			state.Flags.in_prison = true
			state.Flags.incarcerated = true
			state.Flags.criminal_record = true
			
			-- Lose job when going to prison
			if state.CurrentJob then
				state.CareerInfo = state.CareerInfo or {}
				state.CareerInfo.lastJobBeforeJail = {
					id = state.CurrentJob.id,
					name = state.CurrentJob.name,
					company = state.CurrentJob.company,
					salary = state.CurrentJob.salary,
				}
				state.CurrentJob = nil
				state.Flags.employed = nil
				state.Flags.has_job = nil
			end
			
			-- CRITICAL FIX #902: Prompt GET OUT OF JAIL when arrested from fight!
			task.delay(1.5, function()
				if player and player.Parent and self.gamepassSystem then
					self.gamepassSystem:promptProduct(player, "GET_OUT_OF_JAIL")
				end
			end)
			
			local message = string.format("😵 Embarrassing! They knocked you out cold! Lost %d health. Someone called the cops - you're sentenced to %.1f years!", healthLoss, years)
			self:pushState(player, message)
			return { 
				success = false, 
				caught = true, 
				knockedOut = true,
				message = message, 
				healthLost = healthLoss,
			}
		else
			-- Just got beat up, no cops
			local message = string.format("😵 Humiliating defeat! They fought back and knocked you out! Lost %d health. You limped away embarrassed.", healthLoss)
			self:pushState(player, message)
			return { 
				success = false, 
				caught = false, 
				knockedOut = true,
				message = message, 
				healthLost = healthLoss,
			}
		end
	end
	
	-- If minigame was failed (non-combat), higher risk but still roll
	if minigameFailed then
		riskModifier = riskModifier + 20  -- 20% more likely to get caught
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
		
		-- CRITICAL FIX #903: Prompt GET OUT OF JAIL when arrested from crime!
		-- Player just got caught - PERFECT time to offer instant freedom!
		task.delay(1.5, function()
			if player and player.Parent and self.gamepassSystem then
				self.gamepassSystem:promptProduct(player, "GET_OUT_OF_JAIL")
			end
		end)
		
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
		
		-- ═══════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Apply grantsFlags from crime catalog on success!
		-- User complaint: "petty crimes should let u become a smuggler"
		-- ═══════════════════════════════════════════════════════════════════════════
		if crime.grantsFlags then
			for _, flagName in ipairs(crime.grantsFlags) do
				state.Flags[flagName] = true
			end
		end
		-- Always set these on successful crime
		state.Flags.criminal_record = true
		state.Flags.crime_experience = true
		state.Flags.criminal_background = true
		state.Flags.criminal_experience = (state.Flags.criminal_experience or 0) + 1
		if (state.Flags.criminal_experience or 0) >= 3 then
			state.Flags.experienced_criminal = true
		end
		
		local crimeName = crime.name or crimeId
		local message = string.format("%s succeeded! You gained %s.", crimeName, formatMoney(payout))
		-- CRITICAL FIX: Don't use showPopup - client shows its own result
		self:pushState(player, message)
		return { success = true, caught = false, message = message, money = payout, crimeName = crimeName }
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
		-- CRITICAL FIX: Set ALL escape flag variations for compatibility!
		state.Flags.escaped_prisoner = true
		state.Flags.escaped_prison = true -- For LifeExperiences consequence events
		state.Flags.fugitive = true
		state.Flags.on_the_run = true
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
					-- CRITICAL FIX: Set ALL escape flags for compatibility!
					setFlags = { escaped_prisoner = true, escaped_prison = true, fugitive = true, on_the_run = true, criminal_record = true },
					feedText = "🏃 You escaped prison! Now living as a fugitive.",
				},
				{ 
					text = "Leave the country", 
					effects = { Happiness = 15, Money = -5000 },
					-- CRITICAL FIX: Set ALL escape flags for compatibility!
					setFlags = { escaped_prisoner = true, escaped_prison = true, fugitive = true, on_the_run = true, fled_country = true },
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

function LifeBackend:handleJobApplication(player, jobId, clientInterviewScore)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data not loaded." }
	end
	
	-- CRITICAL FIX: If client already conducted an interview and passed, use that score
	-- clientInterviewScore is passed from OccupationScreen after the interview modal
	local hasClientInterviewScore = clientInterviewScore ~= nil and type(clientInterviewScore) == "number"

	-- CRITICAL FIX #512: Use findJobByInput for flexible job lookup
	-- This allows the client to send job IDs, names, or partial matches
	-- Fixes "Unknown Job" for jobs like "Hobbyist Streamer" and "New Content Creator"
	local job = JobCatalog[jobId] or self:findJobByInput(jobId)
	if not job then
		warn("[LifeBackend] Unknown job application:", jobId)
		return { success = false, message = "That job doesn't seem to exist. Try browsing available jobs." }
	end
	
	-- AAA FIX: Handle removed jobs gracefully
	if job.removed then
		return { 
			success = false, 
			message = job.removedMessage or "This job is no longer available."
		}
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
		-- CRITICAL FIX: Nil safety for job.company
		local safeCompany = tostring(job.company or "this company")
		return { 
			success = false, 
			message = string.format("You already applied to %s this year. Wait until next year to try again.", safeCompany)
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: CLIENT-SIDE INTERVIEW INTEGRATION
	-- If the client already conducted an interview (passed with a score), use that!
	-- Otherwise, for competitive jobs, return interview event for server-side flow
	-- ═══════════════════════════════════════════════════════════════════════════════
	local accepted = false
	
	if hasClientInterviewScore then
		-- Client already did the interview - use their score!
		-- CRITICAL FIX: User reported "I JUST GOT 55% IT SAID I PASSED GOT JOB BUT IT DIDNT GIVE ME JOB"
		-- The client shows "Interview Passed! They've decided to hire you!" at 50%+
		-- Server MUST honor this and actually give the job! Cannot reject after client says hired!
		
		-- If client interview passed (score >= 50), they ARE hired - no RNG!
		-- The interview IS the RNG - passing means you got the job!
		if clientInterviewScore >= 50 then
			-- PASSED INTERVIEW = HIRED! No additional roll needed
			-- This matches what the client displays to the user
			accepted = true
		elseif clientInterviewScore >= 40 then
			-- Close to passing - give them a good chance
			accepted = RANDOM:NextNumber() < 0.70
		elseif clientInterviewScore >= 30 then
			-- Poor interview - low chance
			accepted = RANDOM:NextNumber() < 0.40
		else
			-- Failed interview badly
			accepted = RANDOM:NextNumber() < 0.15
		end
	else
		-- No client interview score - check if we should show server-side interview
		local shouldShowInterview = difficulty >= 4 and (job.salary or 0) >= 40000
		
		if shouldShowInterview then
			-- Generate interview questions/scenarios based on job category
			local interviewData = self:generateInterviewEvent(state, job, finalChance)
			
			-- Return interview event for client to display
			return {
				success = true,
				requiresInterview = true,
				interviewEvent = interviewData,
				jobId = actualJobId,
				jobName = job.name or job.title,
				company = job.company or "the company",
				baseChance = finalChance,
			}
		end
		
		-- Roll for success (for jobs that skip interview)
		local roll = RANDOM:NextNumber()
		accepted = roll < finalChance
	end
	
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

	local feed = string.format("🎉 Congratulations! You were hired as a %s at %s!", tostring(job.name or "employee"), tostring(job.company or "a company"))
	self:pushState(player, feed)
	-- CRITICAL FIX: Return job info for client display
	return { 
		success = true, 
		message = feed,
		jobName = job.name,
		jobTitle = job.name,
		company = job.company,
		salary = job.salary,
		category = job.category,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- AAA INTERVIEW SYSTEM
-- Generates interview events for competitive jobs
-- Like the competition game, gives players choices that affect their chances
-- ═══════════════════════════════════════════════════════════════════════════════

local InterviewQuestions = {
	tech = {
		{
			question = "The interviewer asks you to solve a coding problem on the whiteboard. How do you approach it?",
			choices = {
				{ text = "Think out loud and explain your reasoning", modifier = 0.15, feed = "Your clear communication impressed them!" },
				{ text = "Dive straight into coding", modifier = -0.05, feed = "They wished you'd explained your thought process." },
				{ text = "Ask clarifying questions first", modifier = 0.10, feed = "Great! You showed you think before acting." },
				{ text = "Admit you're nervous and need a moment", modifier = 0.05, feed = "They appreciated your honesty." },
			}
		},
		{
			question = "They ask about a time you dealt with a difficult coworker.",
			choices = {
				{ text = "Share a genuine story with a positive resolution", modifier = 0.12, feed = "Your maturity shone through." },
				{ text = "Say you've never had problems with anyone", modifier = -0.10, feed = "They didn't believe you." },
				{ text = "Complain about your last team", modifier = -0.20, feed = "Red flag! Never badmouth past colleagues." },
				{ text = "Focus on what you learned from the experience", modifier = 0.15, feed = "Perfect answer - growth mindset!" },
			}
		},
	},
	office = {
		{
			question = "The hiring manager asks why you want to leave your current job.",
			choices = {
				{ text = "Looking for growth opportunities", modifier = 0.12, feed = "They liked your ambition." },
				{ text = "My current manager is terrible", modifier = -0.18, feed = "Never complain about past employers!" },
				{ text = "I'm excited about this company's mission", modifier = 0.15, feed = "Your enthusiasm was genuine." },
				{ text = "Better salary", modifier = -0.05, feed = "Honest, but they prefer other motivations." },
			}
		},
		{
			question = "They ask where you see yourself in 5 years.",
			choices = {
				{ text = "Growing with this company in a leadership role", modifier = 0.10, feed = "Shows commitment and ambition." },
				{ text = "Running my own business", modifier = -0.08, feed = "They worry you'll leave soon." },
				{ text = "I'm not sure yet", modifier = -0.05, feed = "They wanted more direction." },
				{ text = "Excelling in this role and mentoring others", modifier = 0.12, feed = "Great balance of growth and contribution!" },
			}
		},
	},
	medical = {
		{
			question = "They ask how you handle high-pressure situations with patients.",
			choices = {
				{ text = "Share a specific example of staying calm", modifier = 0.15, feed = "Your experience reassured them." },
				{ text = "I try not to get stressed", modifier = -0.05, feed = "Too vague - they wanted specifics." },
				{ text = "Focus on the patient, not the pressure", modifier = 0.12, feed = "Patient-first mentality impressed them." },
				{ text = "I delegate when overwhelmed", modifier = 0.08, feed = "Shows good teamwork." },
			}
		},
	},
	generic = {
		{
			question = "The interviewer asks what your greatest weakness is.",
			choices = {
				{ text = "Share a real weakness you're working on", modifier = 0.10, feed = "Your self-awareness impressed them." },
				{ text = "Say you work too hard", modifier = -0.12, feed = "That cliché answer didn't land well." },
				{ text = "Claim you don't have any", modifier = -0.15, feed = "Nobody's perfect - they didn't believe you." },
				{ text = "Mention perfectionism but explain how you manage it", modifier = 0.08, feed = "Good answer with self-awareness." },
			}
		},
		{
			question = "At the end, they ask if you have any questions for them.",
			choices = {
				{ text = "Ask about team culture and growth opportunities", modifier = 0.12, feed = "You showed genuine interest!" },
				{ text = "Ask about salary and vacation days", modifier = -0.08, feed = "A bit premature for those questions." },
				{ text = "Say no, you're good", modifier = -0.15, feed = "That seemed disinterested." },
				{ text = "Ask what success looks like in this role", modifier = 0.15, feed = "Excellent question - they loved it!" },
			}
		},
		{
			question = "The interviewer seems distracted by their phone. What do you do?",
			choices = {
				{ text = "Wait patiently until they're ready", modifier = 0.05, feed = "You stayed professional." },
				{ text = "Clear your throat to get their attention", modifier = 0.02, feed = "Subtle but it worked." },
				{ text = "Ask if they need to handle something first", modifier = 0.10, feed = "Thoughtful and understanding!" },
				{ text = "Get visibly annoyed", modifier = -0.15, feed = "Your frustration showed - not a good look." },
			}
		},
	},
}

function LifeBackend:generateInterviewEvent(state, job, baseChance)
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- AAA INTERVIEW SYSTEM: Multi-stage interview with behavioral questions
	-- Uses JobInterviewSystem for realistic interview experience
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Generate using AAA JobInterviewSystem
	local interviewData = JobInterviewSystem.generateInterview(job, state, baseChance)
	
	-- Build formatted question data for client
	local formattedQuestions = {}
	for i, q in ipairs(interviewData.questions) do
		table.insert(formattedQuestions, {
			question = q.question,
			choices = {},
		})
		for j, opt in ipairs(q.options) do
			table.insert(formattedQuestions[i].choices, {
				text = opt.text,
				modifier = opt.modifier, -- Hidden from player
				feed = opt.feedback,
			})
		end
	end
	
	-- Add behavioral scenario
	if interviewData.scenario then
		table.insert(formattedQuestions, {
			question = interviewData.scenario.scenario,
			isScenario = true,
			choices = {},
		})
		for _, opt in ipairs(interviewData.scenario.options) do
			table.insert(formattedQuestions[#formattedQuestions].choices, {
				text = opt.text,
				modifier = opt.modifier,
				feed = opt.feedback,
			})
		end
	end
	
	return {
		id = "job_interview_" .. (job.id or "unknown"),
		title = "💼 Job Interview: " .. (job.name or "Position"),
		emoji = "💼",
		text = string.format("You're interviewing for the %s position at %s.\n\nThis is a multi-stage interview. Your answers will affect your chances!", 
			job.name or "open", job.company or "the company"),
		questions = formattedQuestions,
		baseChance = baseChance,
		totalStages = #formattedQuestions,
		currentStage = 1,
		jobData = {
			id = job.id,
			name = job.name,
			company = job.company,
			salary = job.salary,
			category = job.category,
		}
	}
end

function LifeBackend:handleInterviewResult(player, interviewData, choices)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data not loaded." }
	end
	
	-- Calculate final chance based on interview answers
	local baseChance = interviewData.baseChance or 0.5
	local modifier = 0
	local feedMessages = {}
	
	for i, choiceIndex in ipairs(choices) do
		local question = interviewData.questions[i]
		if question and question.choices and question.choices[choiceIndex] then
			local choice = question.choices[choiceIndex]
			modifier = modifier + (choice.modifier or 0)
			if choice.feed then
				table.insert(feedMessages, choice.feed)
			end
		end
	end
	
	local finalChance = math.clamp(baseChance + modifier, 0.05, 0.95)
	local accepted = RANDOM:NextNumber() < finalChance
	
	local jobId = interviewData.jobData and interviewData.jobData.id
	local job = JobCatalog[jobId] or interviewData.jobData
	
	-- Track application
	state.JobApplications = state.JobApplications or {}
	state.JobApplications[jobId] = state.JobApplications[jobId] or {}
	state.JobApplications[jobId].attempts = (state.JobApplications[jobId].attempts or 0) + 1
	state.JobApplications[jobId].lastAttempt = state.Age or 0
	state.JobApplications[jobId].rejectedThisYear = not accepted
	
	if not accepted then
		local feedText = table.concat(feedMessages, " ") .. " Unfortunately, they went with another candidate."
		appendFeed(state, feedText)
		
		return {
			success = false,
			message = "The interview went okay, but they chose another candidate. Don't give up!",
			interviewFeedback = feedMessages,
		}
	end
	
	-- SUCCESS! Hired after interview
	local feedText = table.concat(feedMessages, " ") .. " 🎉 You got the job!"
	appendFeed(state, feedText)
	
	-- Apply the job (similar to normal job acceptance)
	return self:applyJobOffer(state, job, player)
end

-- Apply a job offer after successful interview or direct hire
function LifeBackend:applyJobOffer(state, job, player)
	if not state or not job then
		return { success = false, message = "Invalid job data." }
	end
	
	state.CareerInfo = state.CareerInfo or {}
	state.Career = state.Career or {}
	state.Flags = state.Flags or {}
	
	-- Save old job to career history
	if state.CurrentJob then
		state.CareerInfo.careerHistory = state.CareerInfo.careerHistory or {}
		table.insert(state.CareerInfo.careerHistory, {
			title = state.CurrentJob.name,
			company = state.CurrentJob.company,
			salary = state.CurrentJob.salary,
			category = state.CurrentJob.category,
			yearsWorked = state.CareerInfo.yearsAtJob or 0,
			performance = state.CareerInfo.performance or 60,
			reason = "quit",
		})
	end
	
	-- Set up new job
	state.CurrentJob = {
		id = job.id,
		name = job.name or job.title,
		company = job.company or "Unknown Company",
		salary = job.salary or 30000,
		category = job.category or "other",
		experience = 0,
	}
	
	-- Reset career stats for new job
	state.CareerInfo.performance = 60
	state.CareerInfo.promotionProgress = 0
	state.CareerInfo.yearsAtJob = 0
	state.CareerInfo.raises = 0
	state.CareerInfo.promotions = 0
	
	-- Set flags
	state.Flags.employed = true
	state.Flags.has_job = true
	state.Flags.just_hired = true
	state.Flags.recently_single = nil
	
	-- Clear any job-seeking flags
	state.Flags.job_hunting = nil
	state.Flags.unemployed = nil
	
	-- Track career path
	if job.category then
		state.Career.track = job.category
	end
	
	-- Happiness boost from getting hired
	if state.ModifyStat then
		state:ModifyStat("Happiness", 10)
	elseif state.Stats then
		state.Stats.Happiness = math.min(100, (state.Stats.Happiness or 50) + 10)
	end
	
	-- Push state to client
	if player and state.CurrentJob then
		self:pushState(player, string.format("🎉 Congratulations! You're now a %s at %s!", 
			tostring(state.CurrentJob.name or "employee"), tostring(state.CurrentJob.company or "a company")))
	end
	
	return {
		success = true,
		message = string.format("You're now a %s at %s!", tostring(state.CurrentJob and state.CurrentJob.name or "employee"), tostring(state.CurrentJob and state.CurrentJob.company or "a company")),
		job = state.CurrentJob,
	}
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

	local jobName = (state.CurrentJob and state.CurrentJob.name) or "your job"
	local companyName = (state.CurrentJob and state.CurrentJob.company) or "your employer"
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #930: "Work Hard" was paying EXTRA salary on top of annual salary!
-- This caused players to earn 13+ months of pay per year if they clicked Work Hard.
-- FIX: Work Hard now ONLY boosts performance (which leads to raises/promotions)
-- and gives small happiness variations. NO EXTRA SALARY.
-- Your annual salary is paid automatically during age-up.
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:handleWork(player)
	local state = self:getState(player)
	if not state or not state.CurrentJob then
		return { success = false, message = "You need a job first." }
	end
	if state.InJail then
		return { success = false, message = "Get out of prison first." }
	end

	state.CareerInfo = state.CareerInfo or {}
	state.Flags = state.Flags or {}
	
	-- Check if already worked hard this year (prevent spam clicking)
	if state.Flags.worked_hard_this_year then
		return { success = false, message = "You've already put in extra effort this year! Your dedication will show at your next review." }
	end
	
	-- Mark that we worked hard this year
	state.Flags.worked_hard_this_year = true

	-- Working hard improves performance significantly!
	-- Performance affects raises and promotion chances
	local oldPerformance = state.CareerInfo.performance or 60
	local performanceGain = RANDOM:NextInteger(5, 12)
	state.CareerInfo.performance = math.min(100, oldPerformance + performanceGain)
	
	-- Working hard also builds skills
	local skills = state.CareerInfo.skills or {}
	skills.dedication = math.min(100, (skills.dedication or 0) + RANDOM:NextInteger(2, 5))
	skills.work_ethic = math.min(100, (skills.work_ethic or 0) + RANDOM:NextInteger(2, 5))
	state.CareerInfo.skills = skills
	
	-- Small stat changes - hard work can be tiring but sometimes satisfying
	local happinessChange = RANDOM:NextInteger(-3, 5)
	local healthChange = RANDOM:NextInteger(-2, 1) -- Work can be draining
	self:applyStatChanges(state, { Happiness = happinessChange, Health = healthChange })
	
	-- Chance of getting noticed by boss (could lead to faster promotion)
	if RANDOM:NextNumber() < 0.25 then
		state.Flags.noticed_by_boss = true
	end
	
	-- Build the feedback message
	local messages = {
		"💼 You put in extra effort at work! Your performance improved (+%d%%). Your boss takes notice.",
		"💼 You stayed late and went above and beyond! Performance +%d%%. This could help at your next review.",
		"💼 Your dedication is paying off! Performance improved by %d%%. Keep it up!",
		"💼 You worked your hardest! +%d%% performance. Your efforts won't go unnoticed.",
		"💼 Extra hours, extra effort! Performance +%d%%. Promotion material!",
	}
	local message = string.format(messages[RANDOM:NextInteger(1, #messages)], performanceGain)
	
	-- Add tip about how salary works
	if state.CareerInfo.performance >= 85 then
		message = message .. "\n\n⭐ Your performance is excellent! You're due for a raise or promotion soon."
	elseif state.CareerInfo.performance >= 70 then
		message = message .. "\n\n📈 Good performance! Keep working hard for that promotion."
	end
	
	self:pushState(player, message)
	return { success = true, message = message, performanceGain = performanceGain }
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
	-- CRITICAL FIX #802: Full nil safety check before accessing CurrentJob properties
	if not state.CurrentJob then
		return { success = false, message = "You don't have a job to be promoted from!" }
	end
	
	local currentJobId = state.CurrentJob.id
	if not currentJobId then
		-- Fallback: just do salary promotion
		state.CurrentJob.salary = math.floor((state.CurrentJob.salary or 30000) * 1.15)
		local safeSalary = formatMoney(state.CurrentJob.salary or 0)
		local feed = string.format("🎉 Salary promotion! You now earn %s.", safeSalary)
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
		-- CRITICAL FIX: Handle nil values safely
		local safeOldName = tostring(oldJobName or "previous position")
		local safeNewName = tostring(newJobName or "new position")
		local safeSalary = formatMoney((state.CurrentJob and state.CurrentJob.salary) or 0)
		feed = string.format("🎉 MAJOR PROMOTION! You've been promoted from %s to %s! New salary: %s", 
			safeOldName, safeNewName, safeSalary)
		-- Add a flag for major promotion
		state.Flags.major_promotion = true
	else
		-- No title change available (top of career track) - just salary bump
		-- CRITICAL FIX: Nil safety for CurrentJob
		if state.CurrentJob then
			state.CurrentJob.salary = math.floor((state.CurrentJob.salary or 0) * 1.15)
			local safeSalary = formatMoney(state.CurrentJob.salary or 0)
			feed = string.format("🎉 Salary promotion! You now earn %s.", safeSalary)
		else
			feed = "🎉 You received a promotion!"
		end
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

	-- CRITICAL FIX: Nil safety for CurrentJob
	if state.CurrentJob then
		state.CurrentJob.salary = math.floor((state.CurrentJob.salary or 0) * 1.08) -- 8% raise instead of 10%
	end
	info.raises = (info.raises or 0) + 1
	info.performance = clamp((info.performance or 60) + 3, 0, 100)

	local safeSalary = formatMoney((state.CurrentJob and state.CurrentJob.salary) or 0)
	local feed = string.format("💰 Raise approved! Salary is now %s.", safeSalary)
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
		return { success = false, message = string.format("You must be at least %d years old to enroll in %s.", minAge, tostring(program.name or "this program")) }
	end

	if not self:meetsEducationRequirement(state, program.requirement) then
		-- MINOR FIX: More helpful error message with specific requirement
		local requiredText = program.requirement or "a prerequisite degree"
		return { success = false, message = string.format("You need %s to enroll in %s.", tostring(requiredText or "prerequisites"), tostring(program.name or "this program")) }
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #964: Input validation to prevent exploits!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Validate assetId is a string
	if type(assetId) ~= "string" then
		warn("[LifeBackend] EXPLOIT ATTEMPT: Invalid assetId type from", player.Name)
		return { success = false, message = "Invalid request." }
	end
	
	-- Validate assetId length (prevent memory attacks)
	if #assetId > 100 then
		warn("[LifeBackend] EXPLOIT ATTEMPT: AssetId too long from", player.Name)
		return { success = false, message = "Invalid request." }
	end
	
	local state = self:getState(player)
	if not state then
		debugPrint("  FAILED: No state")
		return { success = false, message = "Life data missing." }
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #965: Rate limiting to prevent purchase spam exploits!
	-- Max 3 purchases per second
	-- ═══════════════════════════════════════════════════════════════════════════════
	state._purchaseTimes = state._purchaseTimes or {}
	local currentTime = os.clock()
	
	-- Clean old timestamps (older than 1 second)
	local recentPurchases = {}
	for _, timestamp in ipairs(state._purchaseTimes) do
		if currentTime - timestamp < 1 then
			table.insert(recentPurchases, timestamp)
		end
	end
	state._purchaseTimes = recentPurchases
	
	if #state._purchaseTimes >= 3 then
		warn("[LifeBackend] Rate limit: Too many purchases from", player.Name)
		return { success = false, message = "Slow down! Try again in a moment." }
	end
	table.insert(state._purchaseTimes, currentTime)

	local asset = self:findAssetById(catalog, assetId)
	if not asset then
		debugPrint("  FAILED: Unknown asset")
		return { success = false, message = "Unknown asset." }
	end
	
	-- Validate asset has required fields
	if not asset.price or type(asset.price) ~= "number" then
		warn("[LifeBackend] Invalid asset price for", assetId)
		return { success = false, message = "Asset unavailable." }
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
	local assetPrice = tonumber(asset.price) or 0
	if (state.Money or 0) < assetPrice then
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #HOMELESS-1: Clear homeless flags when buying a property!
	-- Buying a house means you're NO LONGER HOMELESS - clear all related flags
	-- This prevents "you're homeless" events from firing after buying housing
	-- ═══════════════════════════════════════════════════════════════════════════════
	if assetType == "Properties" then
		-- Clear ALL homeless-related and transitional housing flags
		-- CRITICAL FIX: User reported housing situation not updating correctly!
		-- The in_transitional_housing flag wasn't being cleared, so AssetsScreen
		-- would still show "Transitional Housing" even after buying a house
		state.Flags.homeless = nil
		state.Flags.couch_surfing = nil
		state.Flags.living_in_car = nil
		state.Flags.using_shelter = nil
		state.Flags.at_risk_homeless = nil
		state.Flags.eviction_notice = nil
		state.Flags.in_transitional_housing = nil  -- CRITICAL: Was missing!
		state.Flags.living_with_family = nil       -- No longer living with family
		state.Flags.living_with_parents = nil      -- No longer living with parents
		state.Flags.in_foster_care = nil           -- No longer in foster care
		
		-- Set proper housing flags
		state.Flags.has_home = true
		state.Flags.has_own_place = true
		state.Flags.moved_out = true
		
		-- Check if it's an apartment or house for specific flags
		local assetName = (asset.name or ""):lower()
		if assetName:find("apartment") or assetName:find("studio") or assetName:find("condo") or assetName:find("loft") then
			state.Flags.has_apartment = true
			state.Flags.renting = true -- Most apartments are rentals
		else
			state.Flags.has_house = true
			state.Flags.homeowner = true
		end
		
		-- Update HousingState if it exists
		state.HousingState = state.HousingState or {}
		state.HousingState.status = "owner"
		state.HousingState.type = asset.name
		state.HousingState.value = asset.price
		state.HousingState.missedRentYears = 0
		
		debugPrint("  CLEARED HOMELESS FLAGS - Player now owns property:", asset.name)
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #VEHICLE-1: Set vehicle flags when buying a car
	-- ═══════════════════════════════════════════════════════════════════════════════
	if assetType == "Vehicles" then
		state.Flags.has_car = true
		state.Flags.has_vehicle = true
		
		-- Clear living_in_car if they now have proper housing too
		if state.Flags.has_home or state.Flags.has_apartment or state.Flags.has_house then
			state.Flags.living_in_car = nil
		end
		
		debugPrint("  SET VEHICLE FLAGS - Player now owns vehicle:", asset.name)
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

	self:addMoney(state, -(tonumber(asset.price) or 0))
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #980: EXCITING PURCHASE CELEBRATIONS WITH VARIETY!
	-- Not boring "You bought X" - actual exciting, varied messages!
	-- One-time special events for first purchases of each type
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	local feed = ""
	local showPopup = false
	local popupData = nil
	local assetLower = (asset.id or ""):lower()
	
	-- Track first-time purchases for unique celebrations
	state._purchaseCelebrations = state._purchaseCelebrations or {}
	local isFirstOfType = not state._purchaseCelebrations[asset.id]
	state._purchaseCelebrations[asset.id] = true
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- SPECIFIC ASSET CELEBRATIONS - SHOES/SNEAKERS
	-- ═══════════════════════════════════════════════════════════════════════════════
	if assetLower == "sneakers" or assetLower:find("shoe") or assetLower:find("kick") then
		if isFirstOfType then
			local shoeMessages = {
				"👟 FRESH KICKS ALERT! You unbox your new %s and they're FIRE! 🔥 First thing you do is flex on everyone!",
				"👟 New %s! You can SMELL that new shoe smell! Time to walk with CONFIDENCE!",
				"👟 %s secured! You're walking different now. Head high, fresh feet!",
				"👟 The drip is REAL! Your new %s are gonna turn heads!",
			}
			feed = string.format(shoeMessages[RANDOM:NextInteger(1, #shoeMessages)], asset.name)
			state.Flags.got_fresh_kicks = true
			state.Flags.sneakerhead = true
		else
			-- Already bought before - shorter message
			feed = string.format("👟 Added another pair: %s. The collection grows!", asset.name)
		end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- PHONE CELEBRATION - First phone is a MAJOR milestone for teens!
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif assetLower == "iphone" or assetLower:find("phone") then
		if isFirstOfType then
			local phoneMessages = {
				"📱 YOUR FIRST PHONE! A %s! Welcome to the connected world! Group chats, social media, EVERYTHING!",
				"📱 %s unlocked! You can TEXT people now! This changes EVERYTHING!",
				"📱 New %s! First thing: download EVERY app! Time to join the digital age!",
				"📱 %s is YOURS! You immediately created 15 social media accounts!",
			}
			feed = string.format(phoneMessages[RANDOM:NextInteger(1, #phoneMessages)], asset.name)
			showPopup = true
			popupData = {
				emoji = "📱",
				title = "FIRST PHONE! 🎉",
				body = "You're connected now! Social media, texts, apps, games - the world is at your fingertips!",
				wasSuccess = true,
			}
			state.Flags.first_phone_celebrated = true
			state.Flags.connected = true
			state.Flags.has_phone = true
		else
			feed = string.format("📱 Upgraded to: %s! Even faster, even sleeker!", asset.name)
		end
		
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- YACHT CELEBRATION - This should be EPIC!
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif assetLower == "yacht" or assetLower:find("yacht") then
		if isFirstOfType then
			feed = string.format("🛥️ YOU BOUGHT A YACHT!!! A %s! The ultimate flex! You're officially in the BIG leagues! Time to invite everyone for a yacht party!", asset.name)
			showPopup = true
			popupData = {
				emoji = "🛥️",
				title = "YACHT OWNER! 🎉",
				body = "You now own a yacht! The ocean is your playground. Plan parties, go fishing, or just flex on everyone from the deck!",
				wasSuccess = true,
			}
			state.Flags.yacht_party_ready = true
			state.Flags.can_host_yacht_party = true
			-- Yacht gives fame boost
			state.Fame = (state.Fame or 0) + 20
		else
			feed = "🛥️ Added another yacht to your fleet. You're building a navy!"
		end
		
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- SUPERCAR/EXOTIC CAR CELEBRATION
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif asset.tier == "supercar" or asset.tier == "exotic" or assetLower:find("ferrari") or assetLower:find("lambo") or assetLower:find("bugatti") then
		if not state.Flags.first_supercar_celebrated then
			local carMessages = {
				"🏎️ SUPERCAR SECURED! Your new %s roars to life! 0-60 in SECONDS! This is the DREAM!",
				"🏎️ LEGENDARY PURCHASE! A %s! People are gonna stop and STARE!",
				"🏎️ %s is YOURS! The engine purrs like a beast! Time to hit the open road!",
				"🏎️ You did it! A %s! Every kid's dream car is now in YOUR garage!",
			}
			feed = string.format(carMessages[RANDOM:NextInteger(1, #carMessages)], asset.name)
			showPopup = true
			popupData = {
				emoji = "🏎️",
				title = "SUPERCAR UNLOCKED!",
				body = string.format("You now own a %s! Street racers will challenge you. People will take photos. You've MADE IT!", asset.name),
				wasSuccess = true,
			}
			state.Flags.first_supercar_celebrated = true
			state.Flags.supercar_owner = true
			state.Fame = (state.Fame or 0) + 10
		else
			feed = string.format("🏎️ Another supercar: %s! Your garage is STACKED!", asset.name)
		end
		
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- FIRST CAR CELEBRATION
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif assetType == "Vehicles" and not state.Flags.first_car_celebrated then
		local firstCarMessages = {
			"🚗 YOUR FIRST CAR! A %s! FREEDOM! No more asking for rides! The road is YOURS!",
			"🚗 You got your first car! A %s! This changes EVERYTHING! Where to first?",
			"🚗 MILESTONE! Your very own %s! You can go ANYWHERE now!",
			"🚗 First wheels: %s! You sat in the driver's seat for 10 minutes just GRINNING!",
		}
		feed = string.format(firstCarMessages[RANDOM:NextInteger(1, #firstCarMessages)], asset.name)
		showPopup = true
		popupData = {
			emoji = "🚗",
			title = "FIRST CAR! 🎉",
			body = string.format("Your very own %s! No more bumming rides. Freedom awaits!", asset.name),
			wasSuccess = true,
		}
		state.Flags.first_car_celebrated = true
		state.Flags.has_first_car = true
		
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- FIRST HOME CELEBRATION
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif assetType == "Properties" and not state.Flags.first_home_celebrated then
		local homeMessages = {
			"🏠 YOU'RE A HOMEOWNER! Your very own %s! No more rent! This is YOURS!",
			"🏠 MAJOR MILESTONE! You bought a %s! Time to make it HOME!",
			"🏠 Keys in hand to your %s! You walked through every room TWICE just because you COULD!",
			"🏠 %s is YOURS! You immediately started planning what to change!",
		}
		feed = string.format(homeMessages[RANDOM:NextInteger(1, #homeMessages)], asset.name)
		showPopup = true
		popupData = {
			emoji = "🏠",
			title = "HOMEOWNER! 🎉",
			body = string.format("Welcome to your %s! Throw a housewarming party?", asset.name),
			wasSuccess = true,
		}
		state.Flags.first_home_celebrated = true
		
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- MANSION/LUXURY PROPERTY CELEBRATION
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif assetType == "Properties" and (asset.tier == "luxury" or asset.tier == "elite" or asset.tier == "ultra" or assetLower:find("mansion") or assetLower:find("penthouse")) then
		if not state.Flags.luxury_home_celebrated then
			feed = string.format("🏰 LUXURY LIVING! Your %s is STUNNING! Multiple bathrooms! A VIEW! You're living the DREAM!", asset.name)
			showPopup = true
			popupData = {
				emoji = "🏰",
				title = "LUXURY HOME!",
				body = "You've reached the top! Time to host fancy parties and live like royalty!",
				wasSuccess = true,
			}
			state.Flags.luxury_home_celebrated = true
			state.Fame = (state.Fame or 0) + 15
		else
			feed = string.format("🏰 Another luxury property: %s! Real estate mogul!", asset.name)
		end
		
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- GAMING PC/TECH CELEBRATION
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif assetLower == "gaming_pc" or assetLower:find("gaming") then
		if isFirstOfType then
			feed = string.format("🖥️ GAMING SETUP COMPLETE! Your new %s boots up! RGB lights EVERYWHERE! Time to go PRO!", asset.name)
			state.Flags.gaming_setup = true
		else
			feed = string.format("🖥️ Upgraded: %s! Even MORE frames per second!", asset.name)
		end
		
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- JEWELRY CELEBRATION  
	-- ═══════════════════════════════════════════════════════════════════════════════
	elseif asset.tier == "jewelry" or assetLower:find("ring") or assetLower:find("necklace") or assetLower:find("watch") then
		if not state.Flags.bling_owner then
			feed = string.format("💎 BLING! Your new %s sparkles! People notice. You feel FANCY!", asset.name)
			state.Flags.bling_owner = true
		else
			feed = string.format("💎 More shine: %s added to the collection!", asset.name)
		end
		
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- DEFAULT MESSAGES (Still with variety!)
	-- ═══════════════════════════════════════════════════════════════════════════════
	else
		local tierMessages = {
			budget = { "You snagged", "You got yourself", "Picked up" },
			basic = { "You bought", "You grabbed", "You picked up" },
			reliable = { "You purchased", "You invested in", "You acquired" },
			nice = { "You treated yourself to", "Nice! You got", "Sweet purchase:" },
			premium = { "Excellent choice!", "Premium purchase:", "Quality investment:" },
			luxury = { "LUXURY! You now own", "Living the dream with", "Congrats on your" },
			supercar = { "INCREDIBLE!", "LEGENDARY PURCHASE!", "DREAM ACHIEVED!" },
			elite = { "ELITE STATUS!", "TOP TIER!", "BALLER MOVE!" },
			ultra = { "ULTRA WEALTHY!", "NEXT LEVEL!", "ULTIMATE FLEX!" },
			billionaire = { "BILLIONAIRE LIFESTYLE!", "OBSCENE WEALTH!", "MOGUL STATUS!" },
		}
		local messages = tierMessages[asset.tier or "basic"] or tierMessages.basic
		local tierMsg = messages[RANDOM:NextInteger(1, #messages)]
		feed = string.format("%s %s for %s!", tierMsg, tostring(asset.name or "an item"), formatMoney(asset.price or 0))
	end
	
	-- Debug: Check assets before push
	debugPrint("  Before pushState:")
	debugPrint("    state.Assets.Properties:", state.Assets.Properties and #state.Assets.Properties or 0)
	debugPrint("    state.Assets.Vehicles:", state.Assets.Vehicles and #state.Assets.Vehicles or 0)
	debugPrint("    state.Assets.Items:", state.Assets.Items and #state.Assets.Items or 0)
	
	-- Push state with optional popup for major purchases
	if showPopup and popupData then
		popupData.showPopup = true
		self:pushState(player, feed, popupData)
	else
		self:pushState(player, feed)
	end
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

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Normalize assetType from client format to server format
	-- Client sends: "property", "vehicle", "item"
	-- Server expects: "Properties", "Vehicles", "Items"
	-- ═══════════════════════════════════════════════════════════════════════════════
	local assetTypeMap = {
		property = "Properties",
		properties = "Properties",
		Properties = "Properties",
		vehicle = "Vehicles",
		vehicles = "Vehicles",
		Vehicles = "Vehicles",
		item = "Items",
		items = "Items",
		Items = "Items",
		crypto = "Crypto",
		Crypto = "Crypto",
	}
	local normalizedType = assetTypeMap[assetType] or assetType
	
	local bucket = state.Assets[normalizedType]
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

			if normalizedType == "Vehicles" and #bucket == 0 then
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
			elseif normalizedType == "Properties" and #bucket == 0 then
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
				
				-- CRITICAL FIX: Update HousingState when selling last property
				-- Player is now homeless or needs to find a new place!
				state.HousingState = state.HousingState or {}
				local age = state.Age or 18
				if age < 18 then
					-- Underage - back to living with parents
					state.HousingState.status = "with_parents"
					state.HousingState.type = "family_home"
					state.HousingState.rent = 0
				elseif state.Money and state.Money >= 1000 then
					-- Has money - assume they'll rent
					state.HousingState.status = "renter"
					state.HousingState.type = "apartment"
					state.HousingState.rent = math.max(500, math.min(2000, math.floor(state.Money / 20)))
					state.HousingState.moveInYear = state.Year or 2025
					state.HousingState.yearsWithoutPayingRent = 0
					state.Flags.renter = true
				else
					-- No money and sold their home - homeless!
					state.HousingState.status = "homeless"
					state.HousingState.type = "street"
					state.HousingState.rent = 0
					state.Flags.homeless = true
					state.Flags.renter = nil
				end
				state.HousingState.value = nil -- No longer own property
			elseif normalizedType == "Properties" and #bucket > 0 then
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
	state.Flags = state.Flags or {}

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #DEEP-3: Much more diverse name generation
	-- Previous list had only 10 first names - now has 60+ for variety
	-- ═══════════════════════════════════════════════════════════════════════════════
	local maleFirstNames = { 
		"James", "John", "Michael", "David", "Robert", "William", "Daniel", "Matthew", "Anthony", "Mark",
		"Joshua", "Andrew", "Joseph", "Christopher", "Ryan", "Tyler", "Brandon", "Kevin", "Justin", "Jason",
		"Brian", "Eric", "Steven", "Thomas", "Adam", "Nathan", "Charles", "Benjamin", "Timothy", "Patrick"
	}
	local femaleFirstNames = { 
		"Emma", "Olivia", "Sophia", "Isabella", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn", "Abigail",
		"Emily", "Elizabeth", "Sofia", "Ella", "Avery", "Scarlett", "Grace", "Chloe", "Victoria", "Madison",
		"Luna", "Penelope", "Layla", "Riley", "Zoey", "Nora", "Lily", "Eleanor", "Hannah", "Lillian"
	}
	local neutralFirstNames = { "Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Drew", "Quinn", "Jamie", "Avery", "Cameron", "Dakota", "Skyler", "Reese", "Finley" }
	local lastNames = { 
		"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez",
		"Anderson", "Taylor", "Thomas", "Moore", "Jackson", "Martin", "Lee", "Thompson", "White", "Harris",
		"Clark", "Lewis", "Robinson", "Walker", "Hall", "Young", "Allen", "King", "Wright", "Lopez"
	}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Choose gender based on player's gender for romance!
	-- BUG REPORTED: "As a girl it only lets me romance girls"
	-- The issue was random 50/50 gender instead of considering player's gender!
	-- ═══════════════════════════════════════════════════════════════════════════════
	local gender
	if relType == "romance" or relType == "partner" then
		-- Romance: opposite gender by default, ~15% same-gender
		local playerGender = state.Gender or "Male"
		if playerGender == "Female" or playerGender == "female" then
			gender = "male" -- Female player gets male partner by default
			if math.random() < 0.15 then
				gender = "female" -- Same-gender
			end
		else
			gender = "female" -- Male player gets female partner by default
			if math.random() < 0.15 then
				gender = "male" -- Same-gender
			end
		end
	else
		-- Friends/enemies: random gender
		gender = (math.random() > 0.5) and "male" or "female"
	end
	
	local firstName
	if gender == "male" then
		firstName = maleFirstNames[math.random(#maleFirstNames)]
	elseif gender == "female" then
		firstName = femaleFirstNames[math.random(#femaleFirstNames)]
	else
		firstName = neutralFirstNames[math.random(#neutralFirstNames)]
	end
	local randomName = firstName .. " " .. lastNames[math.random(#lastNames)]

	-- CRITICAL FIX: Better age range for romantic partners (especially when old!)
	-- User complaint: "ROMANCE DOSENT WORK SOMETIMES LIKE WHEN OLD"
	local playerAge = state.Age or 20
	local partnerAgeMin = math.max(18, playerAge - 15) -- No more than 15 years younger, min 18
	local partnerAgeMax = math.max(playerAge + 10, 25) -- No more than 10 years older, but at least 25
	
	-- Safety check: ensure min <= max
	if partnerAgeMin > partnerAgeMax then
		partnerAgeMin = 18
		partnerAgeMax = 30
	end
	
	local partnerAge = math.random(partnerAgeMin, partnerAgeMax)

	local newId = string.format("%s_%s_%d", relType, os.time(), math.random(1000, 9999))
	local relationship = {
		id = newId,
		name = randomName,
		type = relType,
		role = relType == "friend" and "Friend" or relType == "romance" and "Partner" or "Person",
		relationship = 60, -- CRITICAL FIX: Start at 60 instead of 50 for more immediate connection
		age = partnerAge,
		gender = gender, -- CRITICAL FIX #DEEP-4: Store gender for UI display
		alive = true,
		metAt = state.Age, -- Track when they met
		lastContact = state.Age, -- Initialize last contact for decay system
	}

	state.Relationships[newId] = relationship

	if relType == "friend" then
		state.Relationships.friends = state.Relationships.friends or {}
		table.insert(state.Relationships.friends, relationship)
	end

	-- CRITICAL FIX: Romance/partner relationships MUST set partner reference and flags!
	-- User complaint: "I CLICK FIND AND PERSON DOSENT SHOWUP EVEN THO IT SAYS I HIT IT OFF"
	-- The issue: createBasicRelationship was NOT setting state.Relationships.partner
	-- So the romance was created but UI couldn't find it!
	if relType == "romance" or relType == "partner" then
		state.Relationships.partner = relationship
		state.Flags.has_partner = true
		state.Flags.dating = true
		state.Flags.recently_single = nil -- Clear this flag if it was set
		debugPrint("[createBasicRelationship] Set partner reference for romance: " .. randomName)
	end
	
	-- CRITICAL FIX #DEEP-5: Also handle enemy creation properly
	if relType == "enemy" then
		state.Relationships.enemies = state.Relationships.enemies or {}
		table.insert(state.Relationships.enemies, relationship)
		relationship.role = "Enemy"
		relationship.relationship = 10 -- Enemies start with low relationship
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
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: "Get Married" action for engaged couples!
		-- After proposing and getting engaged, players need to actually get married!
		-- ═══════════════════════════════════════════════════════════════════════════════
		get_married = {
			delta = 25,
			cost = 10000,
			isSpecial = true,
			showResult = true,
			message = function(state, relationship)
				state.Flags = state.Flags or {}
				
				-- Must be engaged first!
				if not state.Flags.engaged then
					return "💭 You need to propose and get engaged first before getting married!"
				end
				
				-- Check if we can afford the wedding
				local weddingCost = 10000
				if (state.Money or 0) < weddingCost then
					return string.format("💸 You can't afford the wedding! You need $%d but only have $%d.", weddingCost, state.Money or 0)
				end
				
				-- Deduct wedding cost
				state.Money = (state.Money or 0) - weddingCost
				
				-- Get partner name
				local partnerName = (relationship and relationship.name) or "your partner"
				
				-- Convert partner to spouse!
				state.Relationships = state.Relationships or {}
				if state.Relationships.partner then
					state.Relationships.spouse = state.Relationships.partner
					state.Relationships.spouse.type = "spouse"
					state.Relationships.spouse.role = "Spouse"
					state.Relationships.spouse.relationship = math.min(100, (state.Relationships.spouse.relationship or 80) + 20)
					state.Relationships.spouse.marriedAt = state.Age or 25
					state.Relationships.partner = nil -- Clear partner slot
				end
				
				-- Also update the relationship passed to us
				if relationship then
					relationship.type = "spouse"
					relationship.role = "Spouse"
					relationship.relationship = math.min(100, (relationship.relationship or 80) + 20)
					relationship.marriedAt = state.Age or 25
				end
				
				-- Set marriage flags!
				state.Flags.married = true
				state.Flags.engaged = nil
				state.Flags.has_partner = true
				state.Flags.dating = nil
				state.Flags.married_at_age = state.Age or 25
				
				-- Happiness boost!
				if state.ModifyStat then
					state:ModifyStat("Happiness", 30)
				end
				
				return string.format("💒💍 You married %s! Congratulations! 💒💍\n\nThis is the happiest day of your life!", partnerName)
			end,
		},
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: "Have a Kid" action!
		-- User bug: "I DONT HAVE A HAVE A KID OPTION IN RELASHONSHIP"
		-- Partner can say yes or no based on relationship strength!
		-- ═══════════════════════════════════════════════════════════════════════════════
		try_baby = {
			delta = 0, -- Delta applied based on outcome
			isSpecial = true,
			showResult = true,
			cooldownYears = 1, -- Can only try once per year
			message = function(state, relationship)
				state.Flags = state.Flags or {}
				
				-- Must be in a committed relationship
				if not (state.Flags.has_partner or state.Flags.married or state.Flags.engaged) then
					return "💭 You're not in a relationship. Find a partner first!"
				end
				
				-- Calculate if partner agrees
				local relStrength = (relationship and relationship.relationship) or 50
				local acceptChance = 0.2 + (relStrength / 200) -- 20% base + up to 50% from relationship
				
				-- Married couples more likely to agree
				if state.Flags.married then
					acceptChance = acceptChance + 0.25
				elseif state.Flags.engaged then
					acceptChance = acceptChance + 0.15
				end
				
				-- Already have kids? Slightly less likely to want more
				local childCount = state.Flags.child_count or 0
				if childCount >= 3 then
					acceptChance = acceptChance - 0.3
				elseif childCount >= 1 then
					acceptChance = acceptChance - 0.1
				end
				
				local partnerName = (relationship and relationship.name) or "your partner"
				
				if RANDOM:NextNumber() < acceptChance then
					-- Partner agrees! Now check if pregnancy happens
					local pregnancyChance = 0.6 -- 60% base chance
					
					-- Age affects fertility
					local playerAge = state.Age or 25
					if playerAge > 40 then
						pregnancyChance = pregnancyChance - 0.25
					elseif playerAge > 35 then
						pregnancyChance = pregnancyChance - 0.1
					end
					
					if RANDOM:NextNumber() < pregnancyChance then
						-- SUCCESS! Having a baby!
						state.Flags.expecting_baby = true
						state.Flags.baby_due_age = (state.Age or 25) + 1
						state.Flags.child_count = (state.Flags.child_count or 0) + 1
						
						-- Create the baby in relationships!
						state.Relationships = state.Relationships or {}
						local babyId = "child_" .. tostring(state.Flags.child_count)
						local babyGender = RANDOM:NextNumber() < 0.5 and "male" or "female"
						local babyRole = babyGender == "male" and "Son" or "Daughter"
						
						-- Baby names
						local boyNames = {"James", "Oliver", "William", "Benjamin", "Lucas", "Henry", "Alexander", "Mason", "Michael", "Ethan", "Daniel", "Noah", "Logan", "Jackson", "Sebastian"}
						local girlNames = {"Emma", "Olivia", "Ava", "Isabella", "Sophia", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn", "Luna", "Aria", "Chloe", "Penelope", "Layla"}
						local namePool = babyGender == "male" and boyNames or girlNames
						local babyName = namePool[RANDOM:NextInteger(1, #namePool)]
						
						state.Relationships[babyId] = {
							name = babyName,
							type = "family",
							role = babyRole,
							isFamily = true,
							relationship = 100,
							age = 0,
							gender = babyGender,
							alive = true,
							bornAt = state.Age or 25,
						}
						
						-- Happiness boost!
						if state.ModifyStat then
							state:ModifyStat("Happiness", 30)
						end
						
						return string.format("🎉 %s said yes! And... you're having a baby! 👶 Welcome %s to the family!", partnerName, babyName)
					else
						-- Agreed but no pregnancy this time
						return string.format("💕 %s agreed! You're trying... but no baby yet. Keep trying!", partnerName)
					end
				else
					-- Partner doesn't want kids right now
					local declineReasons = {
						"They're not ready for that commitment yet.",
						"They want to focus on career first.",
						"They think you should wait a bit longer.",
						"They want to be more financially stable first.",
						"They're not sure about having kids.",
					}
					local reason = declineReasons[RANDOM:NextInteger(1, #declineReasons)]
					
					-- Small relationship hit
					if relationship then
						relationship.relationship = math.max(0, (relationship.relationship or 50) - 5)
					end
					
					return string.format("😔 %s said not right now. %s", partnerName, reason)
				end
			end,
		},
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Proposal now has proper acceptance/rejection logic!
		-- User bug: "I CAN SPAM PROPOSE?? AND ITS NOT REALLY WORKING WELL HAVING A 
		-- CARDRESULT POPUP OR SOMETHING"
		-- ═══════════════════════════════════════════════════════════════════════════════
		propose = { 
			delta = 0, -- Delta applied based on outcome
			cost = 5000, 
			isProposal = true, -- Flag for special handling
			cooldownYears = 1, -- Prevent spam
			message = function(state, relationship)
				-- Calculate acceptance chance based on relationship strength
				local relStrength = (relationship and relationship.relationship) or 50
				local acceptChance = 0.3 + (relStrength / 200) -- 30% base + up to 50% from relationship
				
				if RANDOM:NextNumber() < acceptChance then
					-- ACCEPTED!
					state.Flags = state.Flags or {}
					state.Flags.engaged = true
					state.Flags.engaged_at_age = state.Age or 0
					state.Flags.committed_relationship = true
					state.Flags.proposal_rejected = nil
					
					-- Update relationship
					if relationship then
						relationship.type = "fiance"
						relationship.role = "Fiancé"
						relationship.relationship = math.min(100, (relationship.relationship or 70) + 20)
					end
					
					local partnerName = (relationship and relationship.name) or "your partner"
					return string.format("💍 %s said YES! You're engaged! 💍", partnerName)
				else
					-- REJECTED
					state.Flags = state.Flags or {}
					state.Flags.proposal_rejected = true
					
					-- Relationship takes a hit
					if relationship then
						relationship.relationship = math.max(0, (relationship.relationship or 50) - 15)
					end
					
					local partnerName = (relationship and relationship.name) or "your partner"
					return string.format("💔 %s said they need more time... Proposal rejected. 💔", partnerName)
				end
			end,
			grant = function(state, relationship)
				-- Stats are applied based on the outcome
				local wasAccepted = state.Flags and state.Flags.engaged
				if wasAccepted then
					state:ModifyStat("Happiness", 25)
				else
					state:ModifyStat("Happiness", -15)
				end
			end,
		},
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

		-- CRITICAL FIX: Ensure relationshipOptions is never nil for romance
		-- User complaint: "ROMANCE DOSENT WORK SOMETIMES LIKE WHEN OLD"
		local relOptions = options.relationshipOptions or {}
		local result = self:createRelationship(state, "romance", relOptions)
		if not result then
			-- Fallback: create a basic partner if createRelationship failed
			debugPrint("[ensureRelationship] createRelationship returned nil for romance, creating basic partner")
			return self:createBasicRelationship(state, "romance")
		end
		return result
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Check interaction cooldown to prevent spam (like proposal spam)
	-- User bug: "I CAN SPAM PROPOSE??"
	-- ═══════════════════════════════════════════════════════════════════════════════
	if action.cooldownYears and action.cooldownYears > 0 then
		state.InteractionCooldowns = state.InteractionCooldowns or {}
		local cooldownKey = relType .. "_" .. actionId
		local lastUsedAge = state.InteractionCooldowns[cooldownKey]
		local currentAge = state.Age or 0
		if lastUsedAge and (currentAge - lastUsedAge) < action.cooldownYears then
			local yearsLeft = action.cooldownYears - (currentAge - lastUsedAge)
			return { 
				success = false, 
				message = string.format("You need to wait %d more year(s) before you can do this again.", math.ceil(yearsLeft)),
				showResult = true,
			}
		end
	end

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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Record interaction cooldown time to prevent spam
	-- ═══════════════════════════════════════════════════════════════════════════════
	if action.cooldownYears and action.cooldownYears > 0 then
		state.InteractionCooldowns = state.InteractionCooldowns or {}
		local cooldownKey = relType .. "_" .. actionId
		state.InteractionCooldowns[cooldownKey] = state.Age or 0
	end

	-- IMPORTANT: do NOT return full state here – the UI should rely on SyncState,
	-- or only use this small payload for local row updates.
	return {
		success = true,
		message = feed,
		targetId = relationship.id,
		relationshipValue = relationship.relationship,
		-- CRITICAL FIX: Flag for client to show a result popup
		showResult = action.isProposal or action.showResult,
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

	local feed = string.format("🌟 You began the %s path!", tostring(path.name or "new"))
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
		local feed = string.format("You completed the %s path!", tostring(path.name or ""))
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
		
		-- CRITICAL FIX: skipClientPopup = true for minigame results!
		-- User complaint: "RESULT LIKE FROM MINIGAMES THE CARD POP UPS TWO TYPES POPUP"
		-- The minigame already showed its own result screen (VICTORY!/YOU LOST)
		-- So we set skipClientPopup = true to prevent a SECOND popup from ShowResult
		local resultData = {
			showPopup = false, -- CRITICAL FIX: Don't show extra popup - minigame already showed result
			skipClientPopup = true, -- CRITICAL FIX: Explicit flag to skip client popup
			wasSuccess = won,
			wasMinigame = true, -- Flag to indicate this was a minigame result
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

function LifeBackend:handleMobOperation(player, operationId, modifiers)
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
	
	modifiers = modifiers or {}
	
	-- CRITICAL FIX: If client already completed a minigame (combat/heist), respect that result!
	-- Don't re-roll success - the minigame already determined the outcome
	local forcedSuccess = nil
	if modifiers.combatCompleted then
		-- Combat minigame was played - respect that result
		forcedSuccess = modifiers.combatWon
		print("[MobOperation] Combat minigame completed. Won:", forcedSuccess)
	elseif modifiers.heistCompleted then
		-- Heist minigame was played - respect that result
		forcedSuccess = modifiers.heistSuccess
		print("[MobOperation] Heist minigame completed. Won:", forcedSuccess)
	end
	
	local success, message, opResult
	
	if forcedSuccess ~= nil then
		-- CRITICAL FIX: Use forced success from minigame result instead of re-rolling!
		success, message, opResult = MafiaSystem:doOperationWithForcedResult(state, operationId, forcedSuccess, modifiers)
	else
		-- Normal operation - roll for success
		success, message, opResult = MafiaSystem:doOperation(state, operationId)
	end
	
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
			
			-- CRITICAL FIX: Properly handle nil values to prevent string.format errors
			local safeTitle = tostring(title or "Royal")
			local safeEmoji = (country and country.emoji) and tostring(country.emoji) or "👑"
			local safeCountryName = (country and country.name) and tostring(country.name) or "the Kingdom"
			local safeWealth = formatMoney(royalWealth or 0)
			table.insert(summaries, string.format("👑 Born as %s of %s %s with %s inheritance!", safeTitle, safeEmoji, safeCountryName, safeWealth))
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
				
				table.insert(summaries, string.format("%s Started %s career as %s!", tostring(path.emoji or "⭐"), tostring(path.name or "new"), tostring(path.firstStage or "beginner")))
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
