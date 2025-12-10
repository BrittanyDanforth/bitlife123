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

TimeMachine.Options = {
	{
		id = "5_years",
		years = 5,
		label = "Go Back 5 Years",
		emoji = "⏰",
		description = "Return to 5 years ago",
		productKey = "TIME_5_YEARS",
	},
	{
		id = "10_years",
		years = 10,
		label = "Go Back 10 Years",
		emoji = "⏰",
		description = "Return to 10 years ago",
		productKey = "TIME_10_YEARS",
	},
	{
		id = "20_years",
		years = 20,
		label = "Go Back 20 Years",
		emoji = "⏰",
		description = "Return to 20 years ago",
		productKey = "TIME_20_YEARS",
	},
	{
		id = "30_years",
		years = 30,
		label = "Go Back 30 Years",
		emoji = "⏰",
		description = "Return to 30 years ago",
		productKey = "TIME_30_YEARS",
	},
	{
		id = "baby",
		years = -1, -- Special: restart from birth
		label = "Restart as Baby",
		emoji = "👶",
		description = "Start over from age 0 (keep character)",
		productKey = "TIME_BABY",
	},
}

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

return TimeMachine
