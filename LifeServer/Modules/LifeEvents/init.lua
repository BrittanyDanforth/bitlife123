local LifeEvents = {}

local EventEngine = require(script.EventEngine)
local CareerSystem = require(script.CareerSystem)

LifeEvents.EventRegistry = {}
LifeEvents.EventList = {}
LifeEvents.Initialized = false

local function addEventsFromModule(moduleScript)
	local ok, moduleEvents = pcall(require, moduleScript)
	if not ok then
		warn("[LifeEvents] Failed to load events from", moduleScript.Name, moduleEvents)
		return
	end

	if typeof(moduleEvents) ~= "table" then
		return
	end

	if moduleEvents.events then
		moduleEvents = moduleEvents.events
	elseif moduleEvents.Events then
		moduleEvents = moduleEvents.Events
	end

	for _, event in ipairs(moduleEvents) do
		local normalized = EventEngine.normalizeEvent(event)
		table.insert(LifeEvents.EventList, normalized)
		LifeEvents.EventRegistry[normalized.id] = normalized
	end
end

function LifeEvents.initialize()
	if LifeEvents.Initialized then
		return
	end

	local catalogFolder = script:WaitForChild("Catalog")
	for _, moduleScript in ipairs(catalogFolder:GetChildren()) do
		if moduleScript:IsA("ModuleScript") then
			addEventsFromModule(moduleScript)
		end
	end

	LifeEvents.Initialized = true
	print(string.format("[LifeEvents] Loaded %d events across %d modules.", #LifeEvents.EventList, #catalogFolder:GetChildren()))
end

LifeEvents.initialize()

function LifeEvents.getEvent(id)
	return LifeEvents.EventRegistry[id]
end

function LifeEvents.getAllEvents()
	return LifeEvents.EventList
end

function LifeEvents.selectEventsForYear(state, options)
	return EventEngine.selectYearEvents(LifeEvents.EventList, state, options)
end

function LifeEvents.processChoice(eventId, choiceIndex, state)
	local eventDef = LifeEvents.getEvent(eventId)
	if not eventDef then
		return nil, "Unknown event"
	end
	return EventEngine.completeEvent(eventDef, choiceIndex, state)
end

function LifeEvents.buildYearQueue(state, options)
	options = options or {}
	local queue = LifeEvents.selectEventsForYear(state, { maxEvents = options.maxEvents or 2 })
	return queue
end

function LifeEvents.getStats()
	return EventEngine.EventStats
end

LifeEvents.CareerSystem = CareerSystem
LifeEvents.EventEngine = EventEngine

return LifeEvents
