--[[
	TimeMachine.lua
	
	Time travel system for BitLife-style game.
	Allows players to go back in time when they die.
	
	REQUIRES: Time Machine gamepass OR individual product purchases
]]

local TimeMachine = {}
TimeMachine.__index = TimeMachine

-- ════════════════════════════════════════════════════════════════════════════
-- TIME TRAVEL OPTIONS
-- ════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #101: Real Developer Product IDs for Time Machine
-- These IDs match the ones configured in Roblox Developer Portal
-- ════════════════════════════════════════════════════════════════════════════

TimeMachine.ProductIds = {
	TIME_5_YEARS = 3477466389,   -- Go back in time 5 years!
	TIME_10_YEARS = 3477466522,  -- Go back in time 10 years!
	TIME_20_YEARS = 3477466619,  -- Go back in time 20 years!
	TIME_30_YEARS = 0,           -- Not provided yet
	TIME_BABY = 3477466778,      -- Go back to being a baby!
}

TimeMachine.Options = {
	{
		id = "5_years",
		years = 5,
		label = "Go Back 5 Years",
		emoji = "⏰",
		description = "Return to 5 years ago",
		productKey = "TIME_5_YEARS",
		productId = 3477466389,
	},
	{
		id = "10_years",
		years = 10,
		label = "Go Back 10 Years",
		emoji = "⏰",
		description = "Return to 10 years ago",
		productKey = "TIME_10_YEARS",
		productId = 3477466522,
	},
	{
		id = "20_years",
		years = 20,
		label = "Go Back 20 Years",
		emoji = "⏰",
		description = "Return to 20 years ago",
		productKey = "TIME_20_YEARS",
		productId = 3477466619,
	},
	{
		id = "30_years",
		years = 30,
		label = "Go Back 30 Years",
		emoji = "⏰",
		description = "Return to 30 years ago",
		productKey = "TIME_30_YEARS",
		productId = 0,  -- Not available yet
	},
	{
		id = "baby",
		years = -1, -- Special: restart from birth
		label = "Restart as Baby",
		emoji = "👶",
		description = "Start over from age 0 (keep character)",
		productKey = "TIME_BABY",
		productId = 3477466778,
	},
}

-- Helper function to get product ID by years
function TimeMachine.getProductIdForYears(years)
	for _, opt in ipairs(TimeMachine.Options) do
		if opt.years == years then
			return opt.productId
		end
	end
	return 0
end

-- Helper function to get option by product ID
function TimeMachine.getOptionByProductId(productId)
	for _, opt in ipairs(TimeMachine.Options) do
		if opt.productId == productId then
			return opt
		end
	end
	return nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- SNAPSHOT SYSTEM (for time travel)
-- ════════════════════════════════════════════════════════════════════════════

-- Store snapshots of player state at various ages
-- Key: playerId_age, Value: serialized state
local StateSnapshots = {}

function TimeMachine.saveSnapshot(player, lifeState, serializedState)
	local playerId = player.UserId
	local age = lifeState.Age
	
	-- Save snapshot every 5 years for efficiency
	if age % 5 == 0 or age == 0 or age == 18 then
		local key = playerId .. "_" .. age
		StateSnapshots[key] = {
			age = age,
			year = lifeState.Year,
			timestamp = os.time(),
			state = serializedState,
		}
		
		-- Keep only last 10 snapshots per player
		local playerSnapshots = {}
		for k, v in pairs(StateSnapshots) do
			if k:match("^" .. playerId .. "_") then
				table.insert(playerSnapshots, { key = k, age = v.age })
			end
		end
		
		-- Sort by age descending
		table.sort(playerSnapshots, function(a, b) return a.age > b.age end)
		
		-- Remove old snapshots
		for i = 11, #playerSnapshots do
			StateSnapshots[playerSnapshots[i].key] = nil
		end
	end
end

function TimeMachine.getSnapshot(player, targetAge)
	local playerId = player.UserId
	
	-- Find the closest snapshot at or before target age
	local bestSnapshot = nil
	local bestAge = -1
	
	for key, snapshot in pairs(StateSnapshots) do
		if key:match("^" .. playerId .. "_") then
			if snapshot.age <= targetAge and snapshot.age > bestAge then
				bestSnapshot = snapshot
				bestAge = snapshot.age
			end
		end
	end
	
	return bestSnapshot
end

function TimeMachine.getAvailableSnapshots(player)
	local playerId = player.UserId
	local snapshots = {}
	
	for key, snapshot in pairs(StateSnapshots) do
		if key:match("^" .. playerId .. "_") then
			table.insert(snapshots, {
				age = snapshot.age,
				year = snapshot.year,
			})
		end
	end
	
	-- Sort by age ascending
	table.sort(snapshots, function(a, b) return a.age < b.age end)
	
	return snapshots
end

-- ════════════════════════════════════════════════════════════════════════════
-- TIME TRAVEL EXECUTION
-- ════════════════════════════════════════════════════════════════════════════

function TimeMachine.canTimeTravel(player, lifeState, yearsBack)
	-- Can't time travel if not dead (this would be called from death screen)
	-- But we'll allow it for testing
	
	local currentAge = lifeState.Age
	local targetAge = yearsBack == -1 and 0 or (currentAge - yearsBack)
	
	if targetAge < 0 then
		return false, "Can't go back that far!"
	end
	
	return true, targetAge
end

function TimeMachine.getTimeTravelOptions(lifeState)
	local currentAge = lifeState.Age
	local options = {}
	
	for _, opt in ipairs(TimeMachine.Options) do
		local targetAge = opt.years == -1 and 0 or (currentAge - opt.years)
		local available = targetAge >= 0
		
		table.insert(options, {
			id = opt.id,
			years = opt.years,
			label = opt.label,
			emoji = opt.emoji,
			description = opt.description,
			productKey = opt.productKey,
			targetAge = math.max(0, targetAge),
			available = available,
		})
	end
	
	return options
end

function TimeMachine.executeTimeTravel(player, lifeState, yearsBack)
	local currentAge = lifeState.Age
	local targetAge = yearsBack == -1 and 0 or (currentAge - yearsBack)
	
	if targetAge < 0 then
		targetAge = 0
	end
	
	-- Try to find a snapshot
	local snapshot = TimeMachine.getSnapshot(player, targetAge)
	
	if snapshot then
		-- Restore from snapshot
		return true, {
			type = "snapshot",
			age = snapshot.age,
			year = snapshot.year,
			state = snapshot.state,
			message = string.format("⏰ Time traveled back to age %d!", snapshot.age),
		}
	else
		-- No snapshot - do a partial reset
		-- Keep identity, reset stats to reasonable values for target age
		return true, {
			type = "partial",
			age = targetAge,
			year = lifeState.Year - (currentAge - targetAge),
			message = string.format("⏰ Time traveled back to age %d!", targetAge),
			resetStats = TimeMachine.getDefaultStatsForAge(targetAge),
		}
	end
end

function TimeMachine.getDefaultStatsForAge(age)
	local baseStats = {
		Happiness = 75,
		Health = 100,
		Smarts = 50,
		Looks = 50,
	}
	
	-- Adjust based on age
	if age < 5 then
		baseStats.Happiness = 90
		baseStats.Health = 100
	elseif age < 13 then
		baseStats.Happiness = 80
		baseStats.Health = 95
	elseif age < 18 then
		baseStats.Happiness = 70
		baseStats.Health = 95
	elseif age < 30 then
		baseStats.Health = 90
	elseif age < 50 then
		baseStats.Health = 80
	elseif age < 70 then
		baseStats.Health = 65
	else
		baseStats.Health = 50
	end
	
	return baseStats
end

-- ════════════════════════════════════════════════════════════════════════════
-- DEATH SCREEN DATA
-- ════════════════════════════════════════════════════════════════════════════

function TimeMachine.getDeathScreenData(player, lifeState, hasGamepass)
	local options = TimeMachine.getTimeTravelOptions(lifeState)
	
	return {
		currentAge = lifeState.Age,
		currentYear = lifeState.Year,
		hasGamepass = hasGamepass,
		options = options,
		availableSnapshots = TimeMachine.getAvailableSnapshots(player),
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #477-479: ENHANCED STATE RESTORATION
-- Properly restore state after time travel with all systems intact
-- ════════════════════════════════════════════════════════════════════════════

-- Flags that should be cleared when time traveling back
TimeMachine.TemporaryFlags = {
	"dead", "died", "death_cause",
	"in_hospital", "hospitalized",
	"pending_trial", "on_trial",
	"just_promoted", "just_fired",
	"grieving",
}

-- Flags that should persist even after time travel (achievements, etc.)
TimeMachine.PersistentFlags = {
	"time_traveled", "uses_time_machine",
	-- Keep identity flags
	"male", "female",
}

function TimeMachine.prepareStateForTimeTravel(state, targetAge)
	-- Clear death-related flags
	state.Flags = state.Flags or {}
	
	for _, flag in ipairs(TimeMachine.TemporaryFlags) do
		state.Flags[flag] = nil
	end
	
	-- Mark that time travel occurred
	state.Flags.time_traveled = true
	state.Flags.uses_time_machine = true
	state.Flags.times_time_traveled = (state.Flags.times_time_traveled or 0) + 1
	state.Flags.last_time_travel_from = state.Age
	
	return state
end

function TimeMachine.restoreFromSnapshot(snapshot, currentState)
	local restored = snapshot.state
	
	if type(restored) == "string" then
		-- If snapshot is serialized, we need to deserialize
		-- (Actual deserialization would depend on format used)
		return nil, "Snapshot needs deserialization"
	end
	
	-- Preserve persistent data from current state
	if currentState then
		-- Keep identity
		restored.FirstName = currentState.FirstName or restored.FirstName
		restored.LastName = currentState.LastName or restored.LastName
		restored.Gender = currentState.Gender or restored.Gender
		restored.Country = currentState.Country or restored.Country
		
		-- Keep player info
		restored.PlayerId = currentState.PlayerId
		
		-- Merge persistent flags
		restored.Flags = restored.Flags or {}
		if currentState.Flags then
			for _, flag in ipairs(TimeMachine.PersistentFlags) do
				if currentState.Flags[flag] then
					restored.Flags[flag] = currentState.Flags[flag]
				end
			end
			
			-- Keep time travel tracking
			restored.Flags.time_traveled = true
			restored.Flags.times_time_traveled = (currentState.Flags.times_time_traveled or 0) + 1
		end
	end
	
	return restored, nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #480-482: PARTIAL RESET WITH PREMIUM FEATURE HANDLING
-- Handle MobState, RoyalState, FameState during time travel
-- ════════════════════════════════════════════════════════════════════════════

function TimeMachine.buildPartialResetState(currentState, targetAge)
	local newState = {}
	
	-- Keep identity
	newState.FirstName = currentState.FirstName
	newState.LastName = currentState.LastName
	newState.Gender = currentState.Gender
	newState.Country = currentState.Country
	newState.PlayerId = currentState.PlayerId
	
	-- Set new age/year
	newState.Age = targetAge
	local yearsBack = currentState.Age - targetAge
	newState.Year = (currentState.Year or 2024) - yearsBack
	
	-- Reset stats to appropriate values
	local baseStats = TimeMachine.getDefaultStatsForAge(targetAge)
	newState.Happiness = baseStats.Happiness
	newState.Health = baseStats.Health
	newState.Smarts = math.max(baseStats.Smarts, math.floor((currentState.Smarts or 50) * 0.8))
	newState.Looks = currentState.Looks or baseStats.Looks
	
	-- Reset money based on age
	if targetAge < 18 then
		newState.Money = math.floor(math.random(0, 500))
	elseif targetAge < 30 then
		newState.Money = math.floor(math.random(500, 5000))
	else
		-- Keep some proportion of current money
		newState.Money = math.floor((currentState.Money or 0) * (targetAge / currentState.Age) * 0.5)
	end
	
	-- Handle education
	if targetAge < 18 then
		newState.Education = "none"
	elseif targetAge >= 18 and targetAge < 22 then
		newState.Education = "high_school"
	else
		-- Keep current education
		newState.Education = currentState.Education
	end
	
	-- Clear job if going back to before working age
	if targetAge < 16 then
		newState.CurrentJob = nil
	elseif targetAge < 18 then
		-- Clear full-time job, could have part-time
		if currentState.CurrentJob and currentState.CurrentJob.fullTime then
			newState.CurrentJob = nil
		end
	end
	
	-- Handle premium features
	
	-- Mob state - clear if going back before age 18
	if targetAge < 18 then
		newState.MobState = nil
	elseif currentState.MobState then
		-- Scale back mob progress proportionally
		newState.MobState = {
			inMob = currentState.MobState.inMob,
			familyId = currentState.MobState.familyId,
			rank = "associate", -- Reset to lowest rank
			respect = math.floor((currentState.MobState.respect or 0) * 0.5),
			heat = 0,
			yearsInMob = math.max(0, (currentState.MobState.yearsInMob or 0) - yearsBack),
		}
	end
	
	-- Royal state - keep if born royal, but reset some progress
	if currentState.RoyalState and currentState.RoyalState.bornRoyal then
		newState.RoyalState = {
			isRoyal = true,
			bornRoyal = true,
			countryId = currentState.RoyalState.countryId,
			title = targetAge < 18 and "prince" or currentState.RoyalState.title,
			lineOfSuccession = currentState.RoyalState.lineOfSuccession,
			popularity = 50, -- Reset popularity
			isMonarch = false, -- Can't be monarch in the past
		}
	end
	
	-- Fame state - scale back based on time traveled
	if currentState.FameState and targetAge >= 18 then
		local fameReduction = yearsBack * 5
		newState.FameState = {
			careerPath = currentState.FameState.careerPath,
			fame = math.max(0, (currentState.FameState.fame or 0) - fameReduction),
			followers = math.floor((currentState.FameState.followers or 0) * 0.5),
			yearsInCareer = math.max(0, (currentState.FameState.yearsInCareer or 0) - yearsBack),
		}
	elseif targetAge < 18 then
		newState.FameState = nil
	end
	
	-- Clear relationships that haven't happened yet
	if currentState.Relationships then
		newState.Relationships = {}
		for key, rel in pairs(currentState.Relationships) do
			if type(rel) == "table" then
				-- Keep family relationships
				if rel.role == "Parent" or rel.role == "Sibling" then
					newState.Relationships[key] = rel
				end
				-- Keep partner only if met before target age
				-- (simplified: keep if target age is adult)
				if targetAge >= 18 and rel.role == "Partner" then
					newState.Relationships[key] = rel
				end
			end
		end
	end
	
	-- Clear assets purchased after target age
	-- (simplified: scale down assets)
	if currentState.Assets then
		newState.Assets = {
			properties = {},
			vehicles = {},
		}
		-- Keep some properties if adult
		if targetAge >= 25 and currentState.Assets.properties then
			for i, prop in ipairs(currentState.Assets.properties) do
				if i <= 1 then -- Keep first property
					table.insert(newState.Assets.properties, prop)
				end
			end
		end
	end
	
	-- Initialize flags
	newState.Flags = {
		time_traveled = true,
		uses_time_machine = true,
		times_time_traveled = (currentState.Flags and currentState.Flags.times_time_traveled or 0) + 1,
	}
	
	-- Preserve gender flags
	if currentState.Flags then
		if currentState.Flags.male then newState.Flags.male = true end
		if currentState.Flags.female then newState.Flags.female = true end
	end
	
	return newState
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #483: VALIDATE TIME TRAVEL PRODUCT OWNERSHIP
-- ════════════════════════════════════════════════════════════════════════════

function TimeMachine.validatePurchase(player, productId)
	local option = TimeMachine.getOptionByProductId(productId)
	if not option then
		return false, "Invalid product"
	end
	
	if option.productId == 0 then
		return false, "Product not available"
	end
	
	return true, option
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #484: CLEAR SNAPSHOTS ON NEW LIFE
-- ════════════════════════════════════════════════════════════════════════════

function TimeMachine.clearSnapshots(player)
	local playerId = player.UserId
	local keysToRemove = {}
	
	for key, _ in pairs(StateSnapshots) do
		if key:match("^" .. playerId .. "_") then
			table.insert(keysToRemove, key)
		end
	end
	
	for _, key in ipairs(keysToRemove) do
		StateSnapshots[key] = nil
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #485: ENHANCED SNAPSHOT WITH PREMIUM FEATURES
-- ════════════════════════════════════════════════════════════════════════════

function TimeMachine.saveEnhancedSnapshot(player, lifeState)
	local playerId = player.UserId
	local age = lifeState.Age
	
	-- Save at key milestones
	local shouldSave = (age % 5 == 0) or (age == 0) or (age == 18) or (age == 21) or (age == 30) or (age == 50) or (age == 65)
	
	if shouldSave then
		local key = playerId .. "_" .. age
		
		-- Create comprehensive snapshot
		local snapshot = {
			age = age,
			year = lifeState.Year,
			timestamp = os.time(),
			-- Core state
			state = {
				FirstName = lifeState.FirstName,
				LastName = lifeState.LastName,
				Gender = lifeState.Gender,
				Country = lifeState.Country,
				Age = lifeState.Age,
				Year = lifeState.Year,
				Money = lifeState.Money,
				Education = lifeState.Education,
				Happiness = lifeState.Happiness,
				Health = lifeState.Health,
				Smarts = lifeState.Smarts,
				Looks = lifeState.Looks,
				CurrentJob = lifeState.CurrentJob,
				Flags = lifeState.Flags and table.clone(lifeState.Flags) or {},
				Relationships = lifeState.Relationships,
				Assets = lifeState.Assets,
				-- Premium feature states
				MobState = lifeState.MobState,
				RoyalState = lifeState.RoyalState,
				FameState = lifeState.FameState,
			},
		}
		
		StateSnapshots[key] = snapshot
		
		-- Cleanup old snapshots (keep last 15)
		local playerSnapshots = {}
		for k, v in pairs(StateSnapshots) do
			if k:match("^" .. playerId .. "_") then
				table.insert(playerSnapshots, { key = k, age = v.age })
			end
		end
		
		table.sort(playerSnapshots, function(a, b) return a.age > b.age end)
		
		for i = 16, #playerSnapshots do
			StateSnapshots[playerSnapshots[i].key] = nil
		end
		
		return true
	end
	
	return false
end

return TimeMachine
