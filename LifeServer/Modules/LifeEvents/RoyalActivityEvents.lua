-- RoyalActivityEvents.lua
-- BitLife-style event cards for Royal activities
-- Premium events for Royalty gamepass holders

local RoyalActivityEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS (CRITICAL FIX: Nil-safe operations)
-- ═══════════════════════════════════════════════════════════════════════════════
local function safeModifyStat(state, stat, amount)
	if state and state.ModifyStat then
		state:ModifyStat(stat, amount)
	elseif state and state.Stats then
		state.Stats[stat] = math.clamp((state.Stats[stat] or 50) + amount, 0, 100)
	elseif state then
		state[stat] = math.clamp((state[stat] or 50) + amount, 0, 100)
	end
end

local function safeAddFeed(state, message)
	if state and state.AddFeed then
		state:AddFeed(message)
	end
end

-- CRITICAL FIX: Check if player is actually royalty
local function isActiveRoyal(state)
	if not state then return false end
	
	-- Check flags for royalty status
	local flags = state.Flags or {}
	if flags.is_royalty or flags.royal_by_marriage or flags.born_royal then
		return true
	end
	
	-- Check RoyalState
	if state.RoyalState and state.RoyalState.isRoyal then
		return true
	end
	
	return false
end

-- CRITICAL FIX: Check if player can do royal activities (not in prison!)
local function canDoRoyalActivities(state)
	if not state then return false end
	if not isActiveRoyal(state) then return false end
	
	local flags = state.Flags or {}
	-- Can't do royal duties from prison!
	if flags.in_prison or flags.incarcerated or flags.in_jail then
		return false
	end
	
	return true
end

-- CRITICAL FIX: Get royal rank for activity eligibility
local function getRoyalRank(state)
	if not state then return 0 end
	if state.RoyalState and state.RoyalState.rank then
		return state.RoyalState.rank
	end
	return state.RoyalRank or 1
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROYAL DUTIES
-- ═══════════════════════════════════════════════════════════════════════════════
RoyalActivityEvents.RoyalDuty = {
	-- CRITICAL FIX: Category-wide eligibility - must be royalty!
	eligibility = canDoRoyalActivities,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	requiresFlags = { is_royalty = true }, -- or royal_by_marriage or born_royal
	{
		id = "royal_charity_gala",
		title = "👑 Royal Charity Gala",
		emoji = "👑",
		weight = 25,
		texts = {
			"You attended a prestigious charity gala as the guest of honor.",
			"The royal family hosted a charity event and all eyes were on you.",
			"Dignitaries from around the world attended the royal charity function.",
		},
		effects = { Happiness = {5, 15}, Fame = {3, 8} },
		choices = {
			{ 
			text = "💰 Make a large donation ($10,000)", 
			feed = "Your generosity made headlines!", 
			cost = 10000, 
			effects = { Fame = 15, Happiness = 10 },
			-- CRITICAL FIX: Money eligibility check
			eligibility = function(state) return (state.Money or 0) >= 10000 end,
		},
			{ text = "📢 Give a speech", feed = "Your speech moved the audience.", effects = { Fame = 8 } },
			{ text = "🤝 Network with nobles", feed = "You made valuable connections." },
		},
	},
	{
		id = "royal_state_visit",
		title = "🏰 State Visit",
		emoji = "🏰",
		weight = 20,
		texts = {
			"You represented the royal family on an official state visit.",
			"Foreign dignitaries arrived and you were part of the welcoming ceremony.",
		},
		effects = { Happiness = {3, 10}, Fame = {5, 12} },
		choices = {
			{ text = "🎩 Be perfectly diplomatic", feed = "You were the picture of royal grace.", effects = { Fame = 8 } },
			{ text = "😊 Be warmly welcoming", feed = "Your warmth impressed the visitors.", effects = { Happiness = 10 } },
			{ text = "😎 Show off the kingdom", feed = "You gave them an impressive tour." },
		},
	},
	{
		id = "royal_scandal_rumor",
		title = "📰 Royal Scandal!",
		emoji = "📰",
		weight = 15,
		texts = {
			"The tabloids published a scandalous story about you!",
			"Paparazzi caught something embarrassing on camera.",
			"Rumors are spreading through the royal court about your behavior.",
		},
		effects = { Happiness = {-10, -20}, Fame = {-5, 10} },
		category = "disaster",
		choices = {
			{ text = "🗞️ Issue a statement", feed = "You addressed the rumors directly.", effects = { Fame = 5 } },
			{ text = "🤫 Stay silent", feed = "You let the rumors die down on their own." },
			{ 
			text = "⚖️ Sue for defamation ($50,000)", 
			feed = "Your lawyers are on it.", 
			cost = 50000, 
			effects = { Fame = 10 },
			-- CRITICAL FIX: Money eligibility check
			eligibility = function(state) return (state.Money or 0) >= 50000 end,
		},
		},
	},
	{
		id = "royal_ceremony",
		title = "🎖️ Royal Ceremony",
		emoji = "🎖️",
		weight = 25,
		texts = {
			"You participated in an important royal ceremony.",
			"A traditional royal ritual required your presence.",
			"You bestowed honors on deserving citizens in a grand ceremony.",
		},
		effects = { Happiness = {8, 18}, Fame = {5, 12} },
		choices = {
			{ text = "👑 Embrace tradition", feed = "You performed flawlessly.", effects = { Fame = 8 } },
			{ text = "💭 Modernize it a bit", feed = "Your fresh approach was noticed.", effects = { Happiness = 5 } },
		},
	},
	{
		id = "royal_public_appearance",
		title = "👋 Public Appearance",
		emoji = "👋",
		weight = 30,
		texts = {
			"Crowds gathered to see you during a public walkabout.",
			"You made an appearance at a local community event.",
			"Citizens lined the streets to catch a glimpse of royalty.",
		},
		effects = { Happiness = {5, 12}, Fame = {2, 8} },
		choices = {
			{ text = "🤝 Shake hands with everyone", feed = "The people loved your accessibility!", effects = { Fame = 8, Happiness = 8 } },
			{ text = "👶 Hold a baby", feed = "The photo went viral!", effects = { Fame = 12 } },
			{ text = "🚗 Wave from the car", feed = "You maintained proper royal distance." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROYAL LEISURE
-- ═══════════════════════════════════════════════════════════════════════════════
RoyalActivityEvents.RoyalLeisure = {
	-- CRITICAL FIX: Category-wide eligibility - must be royalty!
	eligibility = canDoRoyalActivities,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	{
		id = "royal_polo",
		title = "🏇 Polo Match",
		emoji = "🏇",
		weight = 25,
		texts = {
			"You played polo with other nobles today.",
			"The annual royal polo tournament is happening.",
		},
		effects = { Happiness = {10, 20}, Health = {2, 8} },
		choices = {
			{ text = "🏆 Play to win", feed = "You showed impressive riding skills!", effects = { Fame = 5 } },
			{ text = "🤝 Play for fun", feed = "Everyone had a wonderful time.", effects = { Happiness = 10 } },
		},
	},
	{
		id = "royal_hunt",
		title = "🦊 Royal Hunt",
		emoji = "🦌",
		weight = 15,
		texts = {
			"A traditional royal hunt was organized on the palace grounds.",
			"Noble guests joined you for a day of hunting.",
		},
		effects = { Happiness = {5, 15}, Health = {3, 8} },
		choices = {
			{ text = "🎯 Hunt traditionally", feed = "A successful hunt!", effects = { Health = 5 } },
			{ text = "📷 Photo hunt only", feed = "You captured wildlife on camera instead.", effects = { Happiness = 8 } },
			{ text = "🦌 Release the animals", feed = "You're known as the compassionate royal.", effects = { Fame = 5 } },
		},
	},
	{
		id = "royal_yacht",
		title = "⛵ Royal Yacht",
		emoji = "⛵",
		weight = 20,
		texts = {
			"You spent the day on the royal yacht.",
			"The family took the yacht for a cruise around the coast.",
		},
		effects = { Happiness = {15, 25} },
		choices = {
			{ text = "🎉 Host a party", feed = "Quite the royal gathering!", effects = { Happiness = 15, Fame = 5 } },
			{ text = "☀️ Relax privately", feed = "Peace and quiet at last." },
		},
	},
	{
		id = "royal_ball",
		title = "💃 Royal Ball",
		emoji = "💃",
		weight = 20,
		texts = {
			"A magnificent ball was held at the palace.",
			"Nobles and diplomats from across the realm gathered for dancing.",
		},
		effects = { Happiness = {12, 22}, Fame = {3, 10} },
		choices = {
			{ text = "💃 Dance the night away", feed = "You were the belle of the ball!", effects = { Happiness = 15 } },
			{ text = "👑 Make royal observations", feed = "You watched and networked strategically.", effects = { Fame = 8 } },
			{ text = "💕 Find a dance partner", feed = "You shared several dances with someone special...", effects = { Happiness = 20 } },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROYAL POLITICS
-- ═══════════════════════════════════════════════════════════════════════════════
RoyalActivityEvents.RoyalPolitics = {
	-- CRITICAL FIX: Category-wide eligibility - must be royalty!
	eligibility = canDoRoyalActivities,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	{
		id = "royal_council",
		title = "🏛️ Royal Council",
		emoji = "🏛️",
		weight = 25,
		texts = {
			"The Royal Council convened to discuss important matters of state.",
			"Advisors gathered to brief you on political situations.",
		},
		effects = { Smarts = {3, 8}, Happiness = {-2, 5} },
		choices = {
			{ text = "📋 Listen carefully", feed = "You're well-informed on state matters.", effects = { Smarts = 5 } },
			{ text = "💬 Share your opinion", feed = "Your input was noted by the council.", effects = { Fame = 3 } },
			{ text = "😴 Zone out", feed = "Politics can be so boring...", effects = { Happiness = -5 } },
		},
	},
	{
		id = "royal_decree",
		title = "📜 Royal Decree",
		emoji = "📜",
		weight = 15,
		-- CRITICAL FIX: Use helper function for rank check
		condition = function(state) return getRoyalRank(state) >= 3 end,  -- Higher ranking royals
		texts = {
			"You have the opportunity to issue a royal decree.",
			"The people await your royal proclamation.",
		},
		effects = { Fame = {5, 15} },
		choices = {
			{ text = "💰 Lower taxes", feed = "The people rejoice!", effects = { Fame = 15, Happiness = 10 } },
			{ text = "🏛️ Fund public works", feed = "Infrastructure improves.", effects = { Fame = 10 } },
			{ text = "🎉 Declare a holiday", feed = "Everyone celebrates!", effects = { Fame = 12, Happiness = 15 } },
		},
	},
	{
		id = "royal_succession_drama",
		title = "👑 Succession Drama",
		emoji = "👑",
		weight = 10,
		texts = {
			"There's talk at court about the line of succession...",
			"A distant relative is challenging your place in the succession.",
		},
		effects = { Happiness = {-10, -5} },
		category = "drama",
		choices = {
			{ text = "⚔️ Assert your claim", feed = "You made your position clear.", effects = { Fame = 5 } },
			{ text = "🤝 Seek allies", feed = "You strengthened your political position." },
			{ text = "🙏 Rise above it", feed = "You refused to engage in petty politics.", effects = { Happiness = 5 } },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROYAL EDUCATION
-- ═══════════════════════════════════════════════════════════════════════════════
RoyalActivityEvents.RoyalEducation = {
	-- CRITICAL FIX: Category-wide eligibility - must be royalty!
	eligibility = canDoRoyalActivities,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	{
		id = "royal_tutor",
		title = "📚 Royal Tutor Session",
		emoji = "📚",
		weight = 30,
		texts = {
			"Your royal tutor arrived for your private lessons.",
			"The finest educators in the kingdom are teaching you today.",
		},
		effects = { Smarts = {5, 12}, Happiness = {-2, 5} },
		choices = {
			{ text = "📖 Study diligently", feed = "You impressed your tutor.", effects = { Smarts = 8 } },
			{ text = "❓ Ask many questions", feed = "Your curiosity serves you well.", effects = { Smarts = 10, Happiness = 3 } },
			{ text = "😴 Daydream", feed = "Royal lessons can be tedious...", effects = { Happiness = -3 } },
		},
	},
	{
		id = "royal_languages",
		title = "🌍 Language Lessons",
		emoji = "🌍",
		weight = 20,
		texts = {
			"Time for your foreign language instruction.",
			"Diplomatic relations require linguistic skills.",
		},
		effects = { Smarts = {3, 8} },
		choices = {
			{ text = "🇫🇷 Learn French", feed = "Très bien!", effects = { Smarts = 5 } },
			{ text = "🇪🇸 Learn Spanish", feed = "¡Excelente!", effects = { Smarts = 5 } },
			{ text = "🇯🇵 Learn Japanese", feed = "素晴らしい!", effects = { Smarts = 6 } },
		},
	},
	{
		id = "royal_etiquette",
		title = "🎩 Etiquette Training",
		emoji = "🎩",
		weight = 25,
		texts = {
			"The royal etiquette instructor is drilling you on proper protocol.",
			"Table manners, greetings, and diplomatic protocol are on today's agenda.",
		},
		effects = { Smarts = {2, 5}, Looks = {1, 4} },
		choices = {
			{ text = "✨ Practice perfectly", feed = "You're the model of royal grace.", effects = { Fame = 3 } },
			{ text = "🙄 It's all so stuffy", feed = "You went through the motions.", effects = { Happiness = -3 } },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

function RoyalActivityEvents.getRandomEvent(activityType, state)
	local events = RoyalActivityEvents[activityType]
	if not events then return nil end
	
	-- CRITICAL FIX: Check category-wide eligibility first
	if events.eligibility and not events.eligibility(state) then
		return nil
	end
	
	-- CRITICAL FIX: Check category-wide blocked flags
	if events.blockedByFlags and state and state.Flags then
		for flag, _ in pairs(events.blockedByFlags) do
			if state.Flags[flag] then
				return nil -- Blocked by flag
			end
		end
	end
	
	-- CRITICAL FIX: Check required flags
	if events.requiresFlags and state then
		local flags = state.Flags or {}
		local hasRequired = false
		for flag, _ in pairs(events.requiresFlags) do
			if flags[flag] or flags.royal_by_marriage or flags.born_royal then
				hasRequired = true
				break
			end
		end
		if not hasRequired and not isActiveRoyal(state) then
			return nil
		end
	end
	
	local validEvents = {}
	local totalWeight = 0
	
	for _, event in ipairs(events) do
		local valid = true
		if event.condition and not event.condition(state) then
			valid = false
		end
		
		-- CRITICAL FIX: Check event-level blocked flags
		if valid and event.blockedByFlags and state and state.Flags then
			for flag, _ in pairs(event.blockedByFlags) do
				if state.Flags[flag] then
					valid = false
					break
				end
			end
		end
		
		if valid then
			table.insert(validEvents, event)
			totalWeight = totalWeight + (event.weight or 10)
		end
	end
	
	if #validEvents == 0 then return nil end
	
	-- Weighted random selection
	local roll = math.random(totalWeight)
	local cumWeight = 0
	
	for _, event in ipairs(validEvents) do
		cumWeight = cumWeight + (event.weight or 10)
		if roll <= cumWeight then
			-- Return a copy with random text selected
			local eventCopy = {}
			for k, v in pairs(event) do
				eventCopy[k] = v
			end
			
			if eventCopy.texts and #eventCopy.texts > 0 then
				eventCopy.text = eventCopy.texts[math.random(#eventCopy.texts)]
			end
			
			return eventCopy
		end
	end
	
	return validEvents[1]
end

function RoyalActivityEvents.applyEffects(state, effects)
	if not effects or not state then return state end
	
	for stat, value in pairs(effects) do
		-- CRITICAL FIX: Handle different stat locations (Stats table vs direct)
		local currentValue = 50
		if state.Stats and state.Stats[stat] ~= nil then
			currentValue = state.Stats[stat]
		elseif state[stat] ~= nil then
			currentValue = state[stat]
		end
		
		local change = 0
		if type(value) == "table" then
			change = math.random(value[1], value[2])
		else
			change = value
		end
		
		-- CRITICAL FIX: Handle special stats like Fame and Money differently
		if stat == "Fame" then
			state.Fame = math.max(0, (state.Fame or 0) + change)
		elseif stat == "Money" then
			state.Money = math.max(0, (state.Money or 0) + change)
		elseif state.Stats then
			state.Stats[stat] = math.clamp((state.Stats[stat] or currentValue) + change, 0, 100)
		else
			state[stat] = math.clamp((state[stat] or currentValue) + change, 0, 100)
		end
	end
	
	return state
end

-- CRITICAL FIX: Process choice costs safely
function RoyalActivityEvents.processChoiceCost(state, choice)
	if not choice or not choice.cost then return true end
	if not state then return false end
	
	local cost = choice.cost
	local money = state.Money or 0
	
	if money < cost then
		return false -- Can't afford
	end
	
	state.Money = money - cost
	return true
end

return RoyalActivityEvents
