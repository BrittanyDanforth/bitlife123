-- LifeBackend.lua (ServerScript)
-- Main backend for BitLife-style game with smart event selection
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ════════════════════════════════════════════════════════════════════════════
-- REQUIRE LIFE EVENTS MODULE
-- The module should be at ServerScriptService.LifeServer.Modules.LifeEvents
-- ════════════════════════════════════════════════════════════════════════════

local LifeEvents
local function loadLifeEvents()
	-- Try ServerScriptService first (preferred location for server modules)
	local ok, err = pcall(function()
		local LifeServer = ServerScriptService:FindFirstChild("LifeServer")
		if LifeServer then
			local Modules = LifeServer:FindFirstChild("Modules")
			if Modules then
				local LifeEventsFolder = Modules:FindFirstChild("LifeEvents")
				if LifeEventsFolder then
					local init = LifeEventsFolder:FindFirstChild("init")
					if init then
						LifeEvents = require(init)
						return
					end
				end
			end
		end
		
		-- Fallback: try ReplicatedStorage
		local rsEvents = ReplicatedStorage:FindFirstChild("LifeEvents")
		if rsEvents then
			LifeEvents = require(rsEvents)
			return
		end
		
		error("LifeEvents module not found in ServerScriptService or ReplicatedStorage")
	end)
	
	if not ok then
		warn("[LifeBackend] Failed to load LifeEvents:", err)
		-- Create a minimal fallback
		LifeEvents = {
			init = function() print("[LifeEvents] Using fallback (empty)") end,
			buildYearQueue = function() return {} end,
			getEvent = function() return nil end,
			EventEngine = {
				completeEvent = function() return nil end
			}
		}
	end
end

loadLifeEvents()

-- Initialize event system
if LifeEvents.init then
	LifeEvents.init()
end

print("[LifeBackend] LifeEvents module loaded successfully")

-- ════════════════════════════════════════════════════════════════════════════
-- REMOTES SETUP
-- ════════════════════════════════════════════════════════════════════════════

local remotesFolder = ReplicatedStorage:FindFirstChild("LifeRemotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "LifeRemotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function createRemote(name, className)
	className = className or "RemoteEvent"
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote
end

-- Core remotes
local RequestAgeUp = createRemote("RequestAgeUp")
local PresentEvent = createRemote("PresentEvent")
local SubmitChoice = createRemote("SubmitChoice")
local SyncState = createRemote("SyncState")
local SetLifeInfo = createRemote("SetLifeInfo")
local MinigameResult = createRemote("MinigameResult")
local MinigameStart = createRemote("MinigameStart")
local ResetLife = createRemote("ResetLife")

-- ════════════════════════════════════════════════════════════════════════════
-- PLAYER DATA MANAGEMENT
-- ════════════════════════════════════════════════════════════════════════════

local PlayerData = {} -- userId -> data

local function createNewLife()
	return {
		-- Core stats
		Name = nil,
		Gender = nil,
		Age = 0,
		Money = 0,
		Happiness = 75,
		Health = 100,
		Smarts = 50,
		Looks = 50,
		
		-- Stats alias for compatibility
		Stats = nil, -- Will be set below
		
		-- Education
		Education = "none",
		GPA = 0,
		
		-- Career
		CurrentJob = nil,
		JobCategory = nil,
		JobSalary = 0,
		Experience = 0,
		YearsAtJob = 0,
		
		-- Relationships (simplified for now)
		RelationshipStatus = "single",
		
		-- Flags - track story choices and states
		Flags = {},
		
		-- Career hints from childhood (influences job availability)
		CareerHints = {},
		
		-- Story arcs the player is on
		StoryArcs = {},
		
		-- Assets
		Assets = {
			Properties = {},
			Vehicles = {},
			Items = {},
			Investments = {},
		},
		
		-- Event history
		EventHistory = {
			occurrences = {},     -- eventId -> count
			lastOccurrence = {},  -- eventId -> age when last occurred
			completed = {},       -- eventId -> true (for one-time events)
			choices = {},         -- eventId -> choiceIndex (last choice made)
			recentCategories = {}, -- track recent categories for variety
			feed = {},            -- array of { age, year, text }
		},
		
		-- Current event queue
		EventQueue = {},
		CurrentEventIndex = 0,
	}
end

local function getPlayerData(player)
	local userId = player.UserId
	if not PlayerData[userId] then
		PlayerData[userId] = createNewLife()
		-- Create Stats alias pointing to self for compatibility
		PlayerData[userId].Stats = PlayerData[userId]
	end
	return PlayerData[userId]
end

-- ════════════════════════════════════════════════════════════════════════════
-- STAT HELPERS
-- ════════════════════════════════════════════════════════════════════════════

local function clampStat(value, min, max)
	min = min or 0
	max = max or 100
	return math.clamp(value, min, max)
end

local function applyStatChanges(data, changes)
	for stat, delta in pairs(changes) do
		if stat == "Money" or stat == "money" then
			data.Money = math.max(0, (data.Money or 0) + delta)
		elseif stat == "Happiness" or stat == "Health" or stat == "Smarts" or stat == "Looks" then
			data[stat] = clampStat((data[stat] or 50) + delta)
		end
	end
end

local function applyFlagChanges(data, changes)
	data.Flags = data.Flags or {}
	for flag, value in pairs(changes) do
		data.Flags[flag] = value
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- LIFE STAGE TRANSITIONS
-- ════════════════════════════════════════════════════════════════════════════

local LifeStages = {
	{ id = "baby",       minAge = 0,  maxAge = 2,  name = "Baby" },
	{ id = "toddler",    minAge = 3,  maxAge = 4,  name = "Toddler" },
	{ id = "child",      minAge = 5,  maxAge = 12, name = "Child" },
	{ id = "teen",       minAge = 13, maxAge = 17, name = "Teenager" },
	{ id = "young_adult", minAge = 18, maxAge = 29, name = "Young Adult" },
	{ id = "adult",      minAge = 30, maxAge = 49, name = "Adult" },
	{ id = "middle_age", minAge = 50, maxAge = 64, name = "Middle-Aged" },
	{ id = "senior",     minAge = 65, maxAge = 999, name = "Senior" },
}

local function getLifeStage(age)
	for _, stage in ipairs(LifeStages) do
		if age >= stage.minAge and age <= stage.maxAge then
			return stage
		end
	end
	return LifeStages[6] -- adult fallback
end

local function getStageTransitionEvent(prevAge, newAge)
	local prevStage = getLifeStage(prevAge)
	local newStage = getLifeStage(newAge)
	
	if prevStage.id ~= newStage.id then
		-- Stage changed! Generate a transition event
		return {
			id = "stage_transition_" .. newStage.id,
			title = "A New Chapter",
			emoji = "🎂",
			text = string.format("You are now a %s!", newStage.name),
			question = "How do you feel about this new stage of life?",
			choices = {
				{ text = "Excited for what's ahead!", effects = { Happiness = 5 }, feed = string.format("You embraced becoming a %s.", newStage.name) },
				{ text = "A bit nervous", effects = { Happiness = -2, Smarts = 2 }, feed = string.format("Growing up is scary sometimes. You're now a %s.", newStage.name) },
				{ text = "Ready for the challenges", effects = { Health = 2, Smarts = 2 }, feed = string.format("You're ready to face life as a %s.", newStage.name) },
			},
			oneTime = true,
			isMilestone = true,
			priority = "high",
			_category = "milestones",
		}
	end
	
	return nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- YEARLY UPDATES (natural stat changes)
-- ════════════════════════════════════════════════════════════════════════════

local function applyYearlyChanges(data)
	local age = data.Age
	
	-- Health decay with age
	if age > 40 then
		local decay = math.floor((age - 40) / 10)
		data.Health = clampStat(data.Health - decay)
	end
	
	-- Natural happiness fluctuation
	local happinessChange = math.random(-3, 3)
	data.Happiness = clampStat(data.Happiness + happinessChange)
	
	-- Education progression
	if age >= 5 and age <= 18 and data.Education == "none" then
		data.Education = "elementary"
	end
	if age >= 13 and data.Education == "elementary" then
		data.Education = "middle_school"
	end
	if age >= 15 and data.Education == "middle_school" then
		data.Education = "high_school"
	end
	
	-- Job income
	if data.CurrentJob then
		local salary = data.JobSalary or 0
		data.Money = data.Money + math.floor(salary / 12) -- Monthly paycheck approximation
		data.YearsAtJob = (data.YearsAtJob or 0) + 1
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT SELECTION & PRESENTATION
-- ════════════════════════════════════════════════════════════════════════════

local function selectEventsForPlayer(data)
	-- BitLife style: Usually just 1 event per year, occasionally 0
	-- Stage transitions are shown as notifications, not choice events
	local events = LifeEvents.buildYearQueue(data, { maxEvents = 1 })
	
	-- Check for stage transition - this is shown as a feed message, not an event
	local prevAge = data.Age - 1
	if prevAge >= 0 then
		local prevStage = getLifeStage(prevAge)
		local newStage = getLifeStage(data.Age)
		
		if prevStage.id ~= newStage.id then
			-- Record stage transition in feed (shown as notification, not event)
			data.StageTransition = {
				from = prevStage.name,
				to = newStage.name,
				message = string.format("You are now a %s!", newStage.name)
			}
		end
	end
	
	return events
end

local function presentNextEvent(player, data)
	if data.CurrentEventIndex >= #data.EventQueue then
		-- No more events, sync state
		print(string.format("[LifeBackend] Event queue complete for %s", player.Name))
		data.EventQueue = {}
		data.CurrentEventIndex = 0
		
		-- Build feed text including stage transition if applicable
		local feedText = string.format("Age %d • Year %d", data.Age, 2025 + data.Age)
		if data.StageTransition then
			feedText = data.StageTransition.message .. "\n" .. feedText
			data.StageTransition = nil -- Clear after showing
		end
		
		SyncState:FireClient(player, data, feedText)
		return
	end
	
	data.CurrentEventIndex = data.CurrentEventIndex + 1
	local event = data.EventQueue[data.CurrentEventIndex]
	
	if not event then
		SyncState:FireClient(player, data)
		return
	end
	
	-- Build event payload for client
	local payload = {
		id = event.id,
		title = event.title or "Life Event",
		emoji = event.emoji or "🙂",
		text = event.text or "",
		question = event.question or "What do you do?",
		choices = {},
		category = event._category or event.category,
		showRelationship = event.showRelationship,
		relationName = event.relationName,
		relationship = event.relationship,
	}
	
	-- Build choices
	for i, choice in ipairs(event.choices or {}) do
		table.insert(payload.choices, {
			index = i,
			text = choice.text,
			minigame = choice.minigame,
		})
	end
	
	-- Generate feed text for age milestone (include stage transition if first event)
	local ageFeedText = nil
	if data.CurrentEventIndex == 1 then
		if data.StageTransition then
			ageFeedText = string.format("%s\nYou are now %d years old. (%d)", 
				data.StageTransition.message, data.Age, 2025 + data.Age)
			data.StageTransition = nil -- Clear after showing
		else
			ageFeedText = string.format("You are now %d years old. (%d)", data.Age, 2025 + data.Age)
		end
	end
	
	print(string.format("[LifeBackend] Presenting event '%s' to %s", event.id, player.Name))
	
	PresentEvent:FireClient(player, payload, ageFeedText)
end

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT HANDLERS
-- ════════════════════════════════════════════════════════════════════════════

-- Age up request
RequestAgeUp.OnServerEvent:Connect(function(player)
	local data = getPlayerData(player)
	
	-- Don't allow age up if waiting for event choices
	if #data.EventQueue > 0 and data.CurrentEventIndex < #data.EventQueue then
		return
	end
	
	-- Check if dead
	if data.Flags.dead or data.Health <= 0 then
		return
	end
	
	-- Increment age
	data.Age = data.Age + 1
	print(string.format("[LifeBackend] Age up requested by %s (Age %d, Year %d)", 
		player.Name, data.Age, 2025 + data.Age))
	
	-- Apply yearly changes
	applyYearlyChanges(data)
	
	-- Check for death from old age or health
	if data.Health <= 0 then
		data.Flags.dead = true
		data.CauseOfDeath = "Health depleted"
		SyncState:FireClient(player, data, "Your health has failed...", {
			fatal = true,
			showPopup = true,
			emoji = "💀",
			title = "Life Ended",
			body = "Your health depleted and you passed away.",
			cause = "Health depleted",
		})
		return
	end
	
	-- Natural death chance increases with age
	if data.Age > 70 then
		local deathChance = (data.Age - 70) / 100
		if data.Health < 30 then
			deathChance = deathChance * 2
		end
		if math.random() < deathChance then
			data.Flags.dead = true
			data.CauseOfDeath = "Natural causes"
			SyncState:FireClient(player, data, "You passed away peacefully...", {
				fatal = true,
				showPopup = true,
				emoji = "🕊️",
				title = "Rest in Peace",
				body = string.format("At age %d, you passed away peacefully of natural causes.", data.Age),
				cause = "Natural causes",
			})
			return
		end
	end
	
	-- Select events for this year (BitLife style: usually just 1 event)
	local events = selectEventsForPlayer(data)
	
	if #events > 0 then
		data.EventQueue = events
		data.CurrentEventIndex = 0
		
		-- Log which event was queued
		print(string.format("[LifeBackend] Event for %s: %s", player.Name, events[1].id))
		
		presentNextEvent(player, data)
	else
		-- No events this year, just sync state with stage transition if applicable
		local feedText
		if data.StageTransition then
			feedText = string.format("%s\nAge %d • Year %d", 
				data.StageTransition.message, data.Age, 2025 + data.Age)
			data.StageTransition = nil
		else
			feedText = string.format("Age %d • Nothing eventful happened this year.", data.Age)
		end
		SyncState:FireClient(player, data, feedText)
	end
end)

-- Submit choice for event
SubmitChoice.OnServerEvent:Connect(function(player, eventId, choiceIndex)
	local data = getPlayerData(player)
	
	if #data.EventQueue == 0 then
		return
	end
	
	local currentEvent = data.EventQueue[data.CurrentEventIndex]
	if not currentEvent or currentEvent.id ~= eventId then
		warn("[LifeBackend] Event mismatch:", eventId, "vs", currentEvent and currentEvent.id)
		return
	end
	
	print(string.format("[LifeBackend] Resolving event %s for %s with choice #%d", 
		eventId, player.Name, choiceIndex))
	
	-- Process the choice using EventEngine
	local outcome = LifeEvents.EventEngine.completeEvent(currentEvent, choiceIndex, data)
	
	if outcome then
		-- Apply stat changes (EventEngine may have already done this, but let's be safe)
		if outcome.statChanges then
			applyStatChanges(data, outcome.statChanges)
		end
		
		-- Apply flag changes
		if outcome.flagChanges then
			applyFlagChanges(data, outcome.flagChanges)
		end
		
		-- Record in history
		data.EventHistory.occurrences[eventId] = (data.EventHistory.occurrences[eventId] or 0) + 1
		data.EventHistory.lastOccurrence[eventId] = data.Age
		data.EventHistory.choices[eventId] = choiceIndex
		
		-- Mark one-time events as completed
		if currentEvent.oneTime then
			data.EventHistory.completed[eventId] = true
		end
		
		-- Add to feed
		if outcome.feedText then
			table.insert(data.EventHistory.feed, {
				age = data.Age,
				year = 2025 + data.Age,
				text = outcome.feedText,
			})
		end
		
		-- Check for death from event
		if data.Health <= 0 then
			data.Flags.dead = true
			data.CauseOfDeath = outcome.feedText or "Unknown causes"
			SyncState:FireClient(player, data, outcome.feedText, {
				fatal = true,
				showPopup = true,
				emoji = "💀",
				title = "Life Ended",
				body = outcome.feedText or "Something fatal happened.",
				cause = outcome.feedText,
			})
			return
		end
	end
	
	-- Check if there are more events
	if data.CurrentEventIndex < #data.EventQueue then
		print(string.format("[LifeBackend] Advancing to next event in queue (%d/%d) for %s", 
			data.CurrentEventIndex + 1, #data.EventQueue, player.Name))
		presentNextEvent(player, data)
	else
		-- All events done, sync state
		print(string.format("[LifeBackend] Event queue complete for %s", player.Name))
		data.EventQueue = {}
		data.CurrentEventIndex = 0
		SyncState:FireClient(player, data, outcome and outcome.feedText)
	end
end)

-- Set life info (name/gender from intro)
SetLifeInfo.OnServerEvent:Connect(function(player, name, gender)
	local data = getPlayerData(player)
	data.Name = name
	data.Gender = gender
	
	print(string.format("[LifeBackend] Life info set for %s: %s (%s)", 
		player.Name, name, gender))
	
	-- Add birth entry to feed
	table.insert(data.EventHistory.feed, {
		age = 0,
		year = 2025,
		text = string.format("%s was born. A new life begins!", name),
	})
	
	SyncState:FireClient(player, data, "A new life begins!")
end)

-- Reset life
ResetLife.OnServerEvent:Connect(function(player)
	local userId = player.UserId
	
	print(string.format("[LifeBackend] Resetting life for %s", player.Name))
	
	-- Create completely new life
	PlayerData[userId] = createNewLife()
	PlayerData[userId].Stats = PlayerData[userId]
	
	-- Notify client
	SyncState:FireClient(player, PlayerData[userId], "A new life begins...")
end)

-- Player setup
Players.PlayerAdded:Connect(function(player)
	local data = getPlayerData(player)
	
	-- Short delay to let client load
	task.delay(1, function()
		SyncState:FireClient(player, data)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Could save data here
	PlayerData[player.UserId] = nil
end)

print("[LifeServer] ✅ LifeBackend initialized")
