-- ActivityEvents.lua
-- BitLife-style event cards for activities
-- Rich narrative events that pop up when doing activities

local ActivityEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- GYM / WORKOUT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Gym = {
	-- Success events
	{
		id = "gym_great_session",
		title = "💪 Great Workout!",
		emoji = "💪",
		weight = 30,
		condition = function(state) return true end,
		texts = {
			"You pushed yourself hard at the gym today. The burn feels amazing!",
			"That was an incredible workout session. You can already feel yourself getting stronger.",
			"You crushed your personal best on the bench press today!",
			"The gym was empty and you had all the equipment to yourself. Perfect workout!",
		},
		effects = { Health = {5, 12}, Happiness = {2, 6}, Looks = {1, 4} },
		choices = {
			{ text = "💪 Keep it up!", feed = "You feel stronger already." },
			{ text = "📸 Take a gym selfie", feed = "You posted your gains on social media." },
		},
	},
	{
		id = "gym_met_trainer",
		title = "🏋️ Personal Trainer",
		emoji = "🏋️",
		weight = 15,
		condition = function(state) return (state.Money or 0) > 500 end,
		texts = {
			"A personal trainer at the gym notices your form and offers some tips.",
			"One of the trainers approaches you between sets with some advice.",
		},
		effects = { Health = {3, 8}, Smarts = {1, 3} },
		choices = {
			{ text = "📝 Take their advice", feed = "You learned proper technique.", effects = { Health = 3 } },
			{ text = "💵 Hire them ($200)", feed = "You hired a personal trainer!", cost = 200, effects = { Health = 8, Looks = 5 } },
			{ text = "🙅 I got this", feed = "You continued on your own." },
		},
	},
	{
		id = "gym_injury",
		title = "🤕 Gym Injury",
		emoji = "🤕",
		weight = 10,
		condition = function(state) return true end,
		texts = {
			"You lifted too heavy and felt something pull in your back.",
			"You weren't paying attention and dropped a weight on your foot.",
			"You pushed too hard and hurt your shoulder.",
		},
		effects = { Health = {-8, -20}, Happiness = {-5, -10} },
		category = "disaster",
		choices = {
			{ text = "🏥 Go to the doctor", feed = "The doctor says you need rest.", cost = 300, effects = { Health = 5 } },
			{ text = "🧊 Ice it and rest", feed = "You're taking it easy for a while." },
		},
	},
	{
		id = "gym_crush",
		title = "😍 Gym Crush",
		emoji = "😍",
		weight = 10,
		condition = function(state) return (state.Age or 0) >= 16 end,
		texts = {
			"Someone very attractive keeps glancing at you between sets.",
			"You noticed someone checking you out while you were on the treadmill.",
			"A cute person asked if you were using the machine next to you.",
		},
		effects = { Happiness = {5, 15} },
		choices = {
			{ text = "💬 Strike up a conversation", feed = "You had a nice chat. They seem interested!", effects = { Happiness = 8 } },
			{ text = "😊 Just smile back", feed = "You exchanged smiles. Nice!" },
			{ text = "🎧 Keep working out", feed = "You stayed focused on your gains." },
		},
	},
	{
		id = "gym_progress",
		title = "📈 Fitness Progress",
		emoji = "📈",
		weight = 20,
		condition = function(state) return true end,
		texts = {
			"You looked in the mirror and noticed your progress. You're getting toned!",
			"Your clothes are fitting differently. All that hard work is paying off!",
			"Someone at the gym complimented your transformation.",
		},
		effects = { Happiness = {8, 15}, Looks = {2, 6}, Health = {3, 8} },
		choices = {
			{ text = "😊 Feel proud", feed = "You're proud of your progress!" },
			{ text = "💪 Double down", feed = "Time to work even harder!", effects = { Health = 3 } },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MEDITATION EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Meditation = {
	{
		id = "meditation_peaceful",
		title = "🧘 Inner Peace",
		emoji = "🧘",
		weight = 35,
		texts = {
			"You achieved a deep state of relaxation. Your mind feels clear.",
			"The meditation session was incredibly calming. You feel at peace.",
			"All your stress melted away during the session.",
		},
		effects = { Happiness = {8, 18}, Health = {2, 6} },
		choices = {
			{ text = "☮️ Namaste", feed = "You feel centered and calm." },
			{ text = "🌸 Continue meditating", feed = "You extended your session for extra peace." },
		},
	},
	{
		id = "meditation_epiphany",
		title = "💡 Life Epiphany",
		emoji = "💡",
		weight = 15,
		texts = {
			"During meditation, you had a profound realization about your life.",
			"A moment of clarity hit you - you know exactly what you need to do.",
			"Your mind connected dots you never noticed before.",
		},
		effects = { Happiness = {10, 20}, Smarts = {3, 8} },
		choices = {
			{ text = "📝 Write it down", feed = "You journaled your insights.", effects = { Smarts = 3 } },
			{ text = "🤔 Reflect on it", feed = "This changes everything." },
		},
	},
	{
		id = "meditation_restless",
		title = "😤 Restless Mind",
		emoji = "😤",
		weight = 20,
		texts = {
			"You couldn't focus. Your mind kept wandering to stressful thoughts.",
			"Every little noise distracted you during the session.",
			"You fell asleep instead of meditating.",
		},
		effects = { Happiness = {-2, 2} },
		choices = {
			{ text = "🔄 Try again", feed = "You'll get it next time." },
			{ text = "🤷 Not for me today", feed = "Some days are just harder." },
		},
	},
	{
		id = "meditation_class",
		title = "🏛️ Meditation Class",
		emoji = "🏛️",
		weight = 10,
		condition = function(state) return (state.Money or 0) > 100 end,
		texts = {
			"A local meditation studio is offering a special class.",
			"You found a meditation retreat happening this weekend.",
		},
		effects = { Happiness = {5, 10} },
		choices = {
			{ text = "📿 Join the class ($50)", feed = "The guided meditation was amazing!", cost = 50, effects = { Happiness = 15, Health = 5 } },
			{ text = "🏠 Practice at home", feed = "Free meditation works too." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Party = {
	{
		id = "party_great_time",
		title = "🎉 Epic Party!",
		emoji = "🎉",
		weight = 30,
		texts = {
			"The party was incredible! You danced all night and made new friends.",
			"What a night! Everyone was talking about how fun the party was.",
			"You were the life of the party! People couldn't stop laughing at your jokes.",
		},
		effects = { Happiness = {12, 25} },
		choices = {
			{ text = "🕺 Keep dancing!", feed = "You partied until sunrise!" },
			{ text = "📸 Post party pics", feed = "Your social media blew up!" },
			{ text = "🏠 Head home happy", feed = "What an amazing night." },
		},
	},
	{
		id = "party_drama",
		title = "😱 Party Drama",
		emoji = "😱",
		weight = 15,
		texts = {
			"Someone started a fight at the party and things got heated.",
			"Drama erupted when someone's ex showed up with their new partner.",
			"An argument broke out and ruined the vibe.",
		},
		effects = { Happiness = {-5, 5} },
		choices = {
			{ text = "🛑 Break it up", feed = "You helped calm things down.", effects = { Happiness = 5 } },
			{ text = "🍿 Watch the drama", feed = "This is better than TV!" },
			{ text = "🚪 Leave quietly", feed = "Not your circus, not your monkeys." },
		},
	},
	{
		id = "party_romance",
		title = "💕 Party Romance",
		emoji = "💕",
		weight = 15,
		condition = function(state) return (state.Age or 0) >= 14 end,
		texts = {
			"You locked eyes with someone across the room. Sparks flew!",
			"Someone really attractive started talking to you at the party.",
			"You spent the whole party talking to one person. Chemistry is undeniable.",
		},
		effects = { Happiness = {10, 20} },
		choices = {
			{ text = "📱 Exchange numbers", feed = "You got their number!", effects = { Happiness = 10 } },
			{ text = "💋 Make a move", feed = "Things got romantic...", effects = { Happiness = 15 } },
			{ text = "🙈 Play it cool", feed = "You'll see them around." },
		},
	},
	{
		id = "party_embarrassing",
		title = "😳 Embarrassing Moment",
		emoji = "😳",
		weight = 15,
		texts = {
			"You tripped and fell in front of everyone at the party.",
			"Someone caught you doing something embarrassing on camera.",
			"You said something awkward and now everyone is looking at you.",
		},
		effects = { Happiness = {-8, -15} },
		choices = {
			{ text = "😂 Laugh it off", feed = "Everyone laughed WITH you, not AT you.", effects = { Happiness = 5 } },
			{ text = "😖 Hide in shame", feed = "You'll never live this down." },
		},
	},
	{
		id = "party_network",
		title = "🤝 Networking Opportunity",
		emoji = "🤝",
		weight = 10,
		condition = function(state) return (state.Age or 0) >= 18 end,
		texts = {
			"You met someone important at the party who could help your career.",
			"A business connection introduced themselves to you.",
		},
		effects = { Happiness = {5, 10} },
		choices = {
			{ text = "💼 Talk business", feed = "You made a valuable connection!", effects = { Smarts = 5 } },
			{ text = "🎉 Stay in party mode", feed = "Tonight is for fun, not work." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- STUDY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Study = {
	{
		id = "study_breakthrough",
		title = "📚 Study Breakthrough",
		emoji = "📚",
		weight = 25,
		texts = {
			"Everything finally clicked! You understand the material perfectly now.",
			"You had a breakthrough moment while studying. It all makes sense!",
			"Hours of studying paid off - you feel confident about this subject.",
		},
		effects = { Smarts = {5, 12}, Happiness = {3, 8} },
		choices = {
			{ text = "🎉 Celebrate!", feed = "Hard work pays off!" },
			{ text = "📖 Keep studying", feed = "You're on a roll!", effects = { Smarts = 3 } },
		},
	},
	{
		id = "study_exhausted",
		title = "😴 Study Burnout",
		emoji = "😴",
		weight = 20,
		texts = {
			"You've been studying so long your eyes are starting to cross.",
			"You caught yourself reading the same paragraph five times.",
			"Your brain feels completely fried from all this studying.",
		},
		effects = { Smarts = {1, 4}, Happiness = {-5, -10}, Health = {-2, -5} },
		choices = {
			{ text = "☕ Coffee break", feed = "A quick break helped.", effects = { Happiness = 3 } },
			{ text = "😤 Push through", feed = "No pain, no gain!", effects = { Smarts = 3 } },
			{ text = "🛏️ Call it a night", feed = "Rest is important too." },
		},
	},
	{
		id = "study_group",
		title = "👥 Study Group",
		emoji = "👥",
		weight = 15,
		texts = {
			"Someone invited you to join their study group.",
			"Your classmates are forming a study session.",
		},
		effects = { Smarts = {2, 5}, Happiness = {2, 5} },
		choices = {
			{ text = "📚 Join them", feed = "Studying together helped everyone!", effects = { Smarts = 5, Happiness = 5 } },
			{ text = "🤓 Study alone", feed = "You focus better by yourself." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- READING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Reading = {
	{
		id = "reading_amazing_book",
		title = "📖 Amazing Book",
		emoji = "📖",
		weight = 30,
		texts = {
			"You couldn't put the book down! It was absolutely captivating.",
			"This book completely changed your perspective on life.",
			"You finished the entire book in one sitting. What a story!",
		},
		effects = { Smarts = {3, 8}, Happiness = {8, 15} },
		choices = {
			{ text = "⭐ Rate 5 stars", feed = "You added it to your favorites." },
			{ text = "📢 Recommend it", feed = "You told everyone about this book!" },
		},
	},
	{
		id = "reading_self_help",
		title = "📚 Self-Improvement Book",
		emoji = "📚",
		weight = 15,
		texts = {
			"You read a self-help book that gave you practical life advice.",
			"The book taught you new strategies for success.",
		},
		effects = { Smarts = {5, 10}, Happiness = {2, 5} },
		choices = {
			{ text = "📝 Take notes", feed = "You wrote down the key insights.", effects = { Smarts = 3 } },
			{ text = "✅ Apply the lessons", feed = "Time to make changes!" },
		},
	},
	{
		id = "reading_boring",
		title = "😑 Boring Book",
		emoji = "😑",
		weight = 20,
		texts = {
			"You tried reading but the book was incredibly boring.",
			"You fell asleep after the first chapter.",
			"You couldn't focus on the book at all.",
		},
		effects = { Smarts = {1, 2}, Happiness = {-2, 0} },
		choices = {
			{ text = "🔄 Try a different book", feed = "Maybe the next one will be better." },
			{ text = "📺 Watch TV instead", feed = "Reading isn't for everyone." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- NIGHTCLUB EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Nightclub = {
	{
		id = "nightclub_vip",
		title = "🌟 VIP Treatment",
		emoji = "🌟",
		weight = 10,
		condition = function(state) return (state.Money or 0) > 1000 or (state.Fame or 0) > 30 end,
		texts = {
			"The bouncer recognized you and let you into the VIP section!",
			"Someone bought you drinks all night because they recognized you.",
		},
		effects = { Happiness = {15, 25} },
		choices = {
			{ text = "🍾 Pop bottles", feed = "You lived like a celebrity tonight!", effects = { Happiness = 10 } },
			{ text = "🙏 Stay humble", feed = "You had a great time without showing off." },
		},
	},
	{
		id = "nightclub_fight",
		title = "👊 Club Altercation",
		emoji = "👊",
		weight = 10,
		texts = {
			"Someone bumped into you and spilled your drink. They look aggressive.",
			"A drunk person is getting in your face about something.",
		},
		effects = { Happiness = {-5, 0} },
		category = "danger",
		choices = {
			{ text = "🥊 Fight back", feed = "Things got physical...", triggersCombat = true },
			{ text = "🙅 Walk away", feed = "You de-escalated the situation.", effects = { Happiness = 3 } },
			{ text = "🔊 Get security", feed = "Security handled it." },
		},
	},
	{
		id = "nightclub_dance",
		title = "💃 Dance Floor Magic",
		emoji = "💃",
		weight = 30,
		texts = {
			"Your dance moves are on fire tonight! Everyone is watching.",
			"You and a group of strangers had an epic dance circle.",
			"The DJ played your favorite song and you went all out!",
		},
		effects = { Happiness = {12, 22}, Health = {-2, 0} },
		choices = {
			{ text = "🕺 Keep dancing!", feed = "You danced until your feet hurt!" },
			{ text = "🍹 Take a break", feed = "Hydration is important!" },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- VACATION EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Vacation = {
	{
		id = "vacation_paradise",
		title = "🏝️ Paradise Found",
		emoji = "🏝️",
		weight = 25,
		texts = {
			"The vacation destination exceeded all your expectations! Pure paradise.",
			"You found the perfect beach spot and relaxed all day.",
			"The views here are breathtaking. Best vacation ever!",
		},
		effects = { Happiness = {20, 35}, Health = {5, 15} },
		choices = {
			{ text = "📸 Take photos", feed = "These memories will last forever!" },
			{ text = "🧘 Just relax", feed = "You achieved total relaxation." },
		},
	},
	{
		id = "vacation_adventure",
		title = "🎢 Adventure Time",
		emoji = "🎢",
		weight = 20,
		texts = {
			"You went on an incredible adventure - hiking, zip-lining, the works!",
			"The local tour guide showed you hidden gems most tourists never see.",
		},
		effects = { Happiness = {15, 30}, Health = {2, 8} },
		choices = {
			{ text = "🤙 Try more activities", feed = "You lived life to the fullest!", effects = { Happiness = 10 } },
			{ text = "🏖️ Relax by the pool", feed = "Balance is key." },
		},
	},
	{
		id = "vacation_disaster",
		title = "😰 Vacation Gone Wrong",
		emoji = "😰",
		weight = 10,
		texts = {
			"Your luggage got lost and the hotel overbooked. Nightmare!",
			"You got food poisoning on the first day of your trip.",
			"It rained the entire vacation. So much for beach time.",
		},
		effects = { Happiness = {-10, -20}, Health = {-5, -15} },
		category = "disaster",
		choices = {
			{ text = "😤 Demand a refund", feed = "You got partial compensation.", moneyGain = {100, 500} },
			{ text = "🤷 Make the best of it", feed = "You found the silver lining.", effects = { Happiness = 5 } },
		},
	},
	{
		id = "vacation_romance",
		title = "💘 Vacation Romance",
		emoji = "💘",
		weight = 15,
		condition = function(state) return (state.Age or 0) >= 18 end,
		texts = {
			"You met someone amazing on vacation. The chemistry is undeniable.",
			"A fellow traveler caught your eye. You spent the whole trip together.",
		},
		effects = { Happiness = {15, 30} },
		choices = {
			{ text = "💕 Summer fling", feed = "A beautiful vacation romance.", effects = { Happiness = 15 } },
			{ text = "📱 Stay in touch", feed = "You exchanged contact info. Maybe something real?", effects = { Happiness = 10 } },
			{ text = "✋ Keep it casual", feed = "Nice meeting them, but you're on vacation." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

function ActivityEvents.getRandomEvent(activityType, state)
	local events = ActivityEvents[activityType]
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

function ActivityEvents.applyEffects(state, effects)
	if not effects or not state then return state end
	
	for stat, value in pairs(effects) do
		if type(value) == "table" then
			-- Range: {min, max}
			local change = math.random(value[1], value[2])
			state[stat] = math.clamp((state[stat] or 50) + change, 0, 100)
		else
			-- Fixed value
			state[stat] = math.clamp((state[stat] or 50) + value, 0, 100)
		end
	end
	
	return state
end

return ActivityEvents
