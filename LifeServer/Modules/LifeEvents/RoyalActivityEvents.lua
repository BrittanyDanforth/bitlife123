-- RoyalActivityEvents.lua
-- BitLife-style event cards for Royal activities
-- Premium events for Royalty gamepass holders

local RoyalActivityEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROYAL DUTIES
-- ═══════════════════════════════════════════════════════════════════════════════
RoyalActivityEvents.RoyalDuty = {
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
			{ text = "💰 Make a large donation", feed = "Your generosity made headlines!", cost = 10000, effects = { Fame = 15, Happiness = 10 } },
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
			{ text = "⚖️ Sue for defamation", feed = "Your lawyers are on it.", cost = 50000, effects = { Fame = 10 } },
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
		condition = function(state) return (state.RoyalRank or 0) >= 3 end,  -- Higher ranking royals
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
	
	local validEvents = {}
	local totalWeight = 0
	
	for _, event in ipairs(events) do
		local valid = true
		if event.condition and not event.condition(state) then
			valid = false
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
		if type(value) == "table" then
			local change = math.random(value[1], value[2])
			state[stat] = math.clamp((state[stat] or 50) + change, 0, 100)
		else
			state[stat] = math.clamp((state[stat] or 50) + value, 0, 100)
		end
	end
	
	return state
end

return RoyalActivityEvents
