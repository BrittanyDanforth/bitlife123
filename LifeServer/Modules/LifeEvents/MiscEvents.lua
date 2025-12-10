--[[
    Miscellaneous Events
    Random miscellaneous life events that don't fit other categories
    All events use randomized outcomes - NO god mode
]]

local MiscEvents = {}

local STAGE = "random"

MiscEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- RANDOM ENCOUNTERS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "misc_found_item",
		title = "Found Something",
		emoji = "🔍",
		text = "You found something interesting!",
		question = "What did you find?",
		minAge = 8, maxAge = 100,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "found", "lucky", "discovery" },
		
		-- CRITICAL: Random find outcome
		choices = {
			{
				text = "Check out the discovery",
				effects = {},
				feedText = "Examining the find...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.15 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.lucky_find = true
						state:AddFeed("🔍 JACKPOT! Found something valuable! $500!")
					elseif roll < 0.35 then
						state.Money = (state.Money or 0) + 100
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🔍 Nice find! Worth about $100!")
					elseif roll < 0.60 then
						state.Money = (state.Money or 0) + 20
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🔍 Found some cash! $20 is $20!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🔍 Found something interesting but not valuable. Cool keepsake!")
					end
				end,
			},
		},
	},
	{
		id = "misc_embarrassing_moment",
		title = "Public Embarrassment",
		emoji = "😳",
		text = "Something embarrassing just happened in public!",
		question = "What was the embarrassment?",
		minAge = 8, maxAge = 80,
		baseChance = 0.25,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "embarrassment", "public", "cringe" },
		
		-- CRITICAL: Random embarrassment severity
		choices = {
			{
				text = "Face the embarrassment",
				effects = {},
				feedText = "Cringing hard...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", -2)
						state:AddFeed("😳 Minor embarrassment. People barely noticed.")
					elseif roll < 0.65 then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("😳 Awkward moment. Some people saw. Will haunt you tonight.")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.cringe_memory = true
						state:AddFeed("😳 MORTIFYING! Everyone saw! Will remember this forever!")
					else
						state:ModifyStat("Happiness", 4)
						state:AddFeed("😳 Embarrassing but handled it gracefully! People laughed WITH you!")
					end
				end,
			},
		},
	},
	{
		id = "misc_random_kindness_witness",
		title = "Witnessed Kindness",
		emoji = "💖",
		text = "You witnessed a beautiful act of kindness!",
		question = "How does it affect you?",
		minAge = 5, maxAge = 100,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "kindness", "witness", "humanity" },
		
		choices = {
			{ text = "Faith in humanity restored", effects = { Happiness = 8, Smarts = 2 }, setFlags = { believes_in_good = true }, feedText = "💖 Beautiful moment! People CAN be good! Touched!" },
			{ text = "Inspired to pay it forward", effects = { Happiness = 6, Money = -20 }, feedText = "💖 Immediately helped someone else! Chain of kindness!" },
			{ text = "Nice but cynical", effects = { Happiness = 3 }, feedText = "💖 Sweet moment. Probably staged for social media though." },
		},
	},
	{
		id = "misc_random_rudeness",
		title = "Encountered Rudeness",
		emoji = "😤",
		text = "Someone was incredibly rude to you!",
		question = "How do you respond?",
		minAge = 8, maxAge = 100,
		baseChance = 0.25,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "rude", "conflict", "anger" },
		
		-- CRITICAL: Random response outcome
		choices = {
			{
				text = "Confront them",
				effects = {},
				feedText = "Standing up for yourself...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("😤 They backed down! Standing up felt good!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 1)
						state:AddFeed("😤 It escalated but resolved. Tense moment.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("😤 Made it worse. Should have walked away.")
					end
				end,
			},
			{ text = "Take the high road", effects = { Happiness = 3, Smarts = 2 }, feedText = "😤 Ignored it. Their problem, not yours. Zen." },
			{ text = "Let it ruin your day", effects = { Happiness = -6 }, feedText = "😤 Can't stop thinking about it. Why are people terrible?" },
		},
	},
	{
		id = "misc_strange_coincidence",
		title = "Strange Coincidence",
		emoji = "✨",
		text = "A very strange coincidence just happened!",
		question = "What's the coincidence?",
		minAge = 10, maxAge = 100,
		baseChance = 0.1,
		cooldown = 6,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "coincidence", "fate", "strange" },
		
		choices = {
			{ text = "Thinking about someone, they called", effects = { Happiness = 6, Smarts = 1 }, setFlags = { weird_coincidence = true }, feedText = "✨ Telepathy? Spooky. Glad they reached out!" },
			{ text = "Same outfit as stranger", effects = { Happiness = 4 }, feedText = "✨ Twinning with a random person! Awkward laugh moment!" },
			{ text = "Heard your name said randomly", effects = { Happiness = 3, Smarts = 1 }, feedText = "✨ Someone said your name. Weren't talking about you. Weird." },
			{ text = "Prophetic dream came true", effects = { Happiness = 5, Smarts = 2 }, setFlags = { had_prophetic_dream = true }, feedText = "✨ Dreamed this would happen! Deja vu is real! Freaky!" },
		},
	},
	{
		id = "misc_good_samaritan",
		title = "Good Samaritan Moment",
		emoji = "🦸",
		text = "You have a chance to help a stranger!",
		question = "Do you help?",
		minAge = 12, maxAge = 90,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "kindness",
		tags = { "helping", "samaritan", "kindness" },
		
		-- CRITICAL: Random help outcome
		choices = {
			{
				text = "Help the stranger",
				effects = {},
				feedText = "Stepping up to help...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.good_samaritan = true
						state:AddFeed("🦸 Made a real difference! They were so grateful!")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🦸 Helped but situation was complicated. Did what you could.")
					else
						state:ModifyStat("Happiness", -2)
						state.Money = (state.Money or 0) - 20
						state:AddFeed("🦸 Tried to help but they took advantage. Lesson learned.")
					end
				end,
			},
			{ text = "Mind your own business", effects = { Happiness = -2 }, feedText = "🦸 Walked past. Feel a bit guilty. Hope they're okay." },
		},
	},
	{
		id = "misc_unexpected_compliment",
		title = "Unexpected Compliment",
		emoji = "😊",
		text = "A stranger gave you a genuine compliment!",
		question = "How do you react?",
		minAge = 8, maxAge = 100,
		baseChance = 0.2,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "compliment", "kind", "confidence" },
		
		choices = {
			{ text = "Accept gracefully", effects = { Happiness = 8, Looks = 1 }, setFlags = { confident = true }, feedText = "😊 Thank you! Glowing all day! Made your week!" },
			{ text = "Awkwardly deflect", effects = { Happiness = 4 }, feedText = "😊 'Oh this old thing?' Why can't you just say thanks?!" },
			{ text = "Return the compliment", effects = { Happiness = 6 }, feedText = "😊 Mutual appreciation! Kindness ping-pong!" },
		},
	},
	{
		id = "misc_phone_dead",
		title = "Phone Died",
		emoji = "🔋",
		text = "Your phone died at the worst possible time!",
		question = "How do you handle being disconnected?",
		minAge = 13, maxAge = 80,
		baseChance = 0.25,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "inconvenience",
		tags = { "phone", "technology", "problem" },
		
		-- CRITICAL: Random phone death outcome
		choices = {
			{
				text = "Survive without it",
				effects = {},
				feedText = "Phoneless in the wild...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🔋 Survived! Actually nice to disconnect! Present moment!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🔋 Made it work. Inconvenient but managed.")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🔋 Missed something important! Why didn't I charge it?!")
					end
				end,
			},
			{ text = "Panic and find charger", effects = { Happiness = -2, Money = -10 }, feedText = "🔋 Found a charger! Sweet relief! Never again!" },
		},
	},
	{
		id = "misc_random_smell",
		title = "Random Smell Encounter",
		emoji = "👃",
		text = "A smell triggered a powerful memory!",
		question = "What memory did the smell bring back?",
		minAge = 10, maxAge = 100,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "smell", "memory", "nostalgia" },
		
		choices = {
			{ text = "Childhood memory", effects = { Happiness = 8, Smarts = 1 }, feedText = "👃 Transported back in time! Powerful nostalgia!" },
			{ text = "Memory of loved one", effects = { Happiness = 4 }, feedText = "👃 Bittersweet. Miss them. Grateful for the moment." },
			{ text = "Unpleasant memory", effects = { Happiness = -4 }, feedText = "👃 That smell. That awful memory. Shaking it off." },
		},
	},
	{
		id = "misc_stuck_in_traffic",
		title = "Terrible Traffic",
		emoji = "🚗",
		text = "You're stuck in terrible traffic!",
		question = "How do you handle being stuck?",
		minAge = 16, maxAge = 90,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "inconvenience",
		tags = { "traffic", "frustration", "commute" },
		
		-- CRITICAL: Random traffic outcome
		choices = {
			{
				text = "Patience and podcasts",
				effects = {},
				feedText = "Stuck but coping...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 2)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🚗 Finished a great podcast! Time well spent!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🚗 Still frustrated but didn't lose it. Deep breaths.")
					end
				end,
			},
			{ text = "Road rage", effects = { Happiness = -6, Health = -2 }, setFlags = { road_rage_issues = true }, feedText = "🚗 Lost your cool. Screaming at no one. Blood pressure rising." },
			{ text = "Find alternate route", effects = { Smarts = 2, Happiness = 3 }, feedText = "🚗 Navigation saved you! Found a shortcut! Win!" },
		},
	},
	{
		id = "misc_random_song",
		title = "Perfect Song Moment",
		emoji = "🎵",
		text = "A song you love came on at the perfect moment!",
		question = "How do you react?",
		minAge = 8, maxAge = 100,
		baseChance = 0.25,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "music", "joy", "moment" },
		
		choices = {
			{ text = "Full sing-along", effects = { Happiness = 10, Health = 1 }, feedText = "🎵 BELTING IT OUT! Don't care who's watching! Musical joy!" },
			{ text = "Head bob and smile", effects = { Happiness = 7 }, feedText = "🎵 This song! Perfect timing! Universe gets you!" },
			{ text = "Get emotional", effects = { Happiness = 5 }, feedText = "🎵 The feels hit hard. Music is powerful. Cathartic moment." },
		},
	},
	{
		id = "misc_wifi_problems",
		title = "Internet Outage",
		emoji = "📶",
		text = "Your internet is down!",
		question = "How do you cope without internet?",
		minAge = 10, maxAge = 80,
		baseChance = 0.25,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "inconvenience",
		tags = { "internet", "technology", "frustration" },
		
		-- CRITICAL: Random internet outage outcome
		choices = {
			{
				text = "Wait for it to come back",
				effects = {},
				feedText = "Staring at the router...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📶 Back up quickly! Just a brief outage!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📶 Hours without internet! Forgot how to exist offline!")
					else
						state:ModifyStat("Happiness", -6)
						state.Money = (state.Money or 0) - 50
						state:AddFeed("📶 Had to call ISP. On hold forever. Rage inducing.")
					end
				end,
			},
			{ text = "Go outside", effects = { Happiness = 5, Health = 3 }, feedText = "📶 Forced to go outside! Actually nice! Nature exists!" },
			{ text = "Use mobile data", effects = { Happiness = 2, Money = -20 }, feedText = "📶 Burning through data plan! Desperate times!" },
		},
	},
	{
		id = "misc_unexpected_day_off",
		title = "Unexpected Day Off",
		emoji = "🎉",
		text = "You got an unexpected day off!",
		question = "What do you do with your free day?",
		minAge = 18, maxAge = 80,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "opportunity",
		tags = { "free_time", "day_off", "opportunity" },
		
		choices = {
			{ text = "Sleep in and relax", effects = { Happiness = 10, Health = 4 }, feedText = "🎉 SLEPT IN! Glorious rest! Self-care day!" },
			{ text = "Spontaneous adventure", effects = { Happiness = 12, Money = -50 }, feedText = "🎉 Impromptu trip/activity! Best kind of day!" },
			{ text = "Catch up on errands", effects = { Happiness = 6, Smarts = 2 }, feedText = "🎉 Productive day off! Got so much done!" },
			{ text = "Waste it on nothing", effects = { Happiness = 4 }, feedText = "🎉 Scrolled phone all day. Relaxing I guess?" },
		},
	},
	{
		id = "misc_deja_vu_intense",
		title = "Intense Déjà Vu",
		emoji = "🔄",
		text = "The most intense déjà vu of your life!",
		question = "How do you process it?",
		minAge = 10, maxAge = 100,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "deja_vu", "strange", "reality" },
		
		choices = {
			{ text = "Embrace the glitch", effects = { Happiness = 4, Smarts = 3 }, setFlags = { deja_vu_explorer = true }, feedText = "🔄 Leaning into the strangeness! Reality is weird!" },
			{ text = "Spooked by it", effects = { Happiness = -2 }, feedText = "🔄 That was TOO real. Unsettling. Is this a simulation?" },
			{ text = "Scientific explanation", effects = { Smarts = 4, Happiness = 2 }, feedText = "🔄 Brain glitch. Memory misfiring. Science explains it." },
		},
	},
	{
		id = "misc_wrong_number",
		title = "Wrong Number Call",
		emoji = "📞",
		text = "You got a wrong number call!",
		question = "How does the wrong number go?",
		minAge = 12, maxAge = 100,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "phone", "random", "encounter" },
		
		-- CRITICAL: Random wrong number outcome
		choices = {
			{
				text = "Have a conversation anyway",
				effects = {},
				feedText = "Talking to a stranger...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.random_phone_friend = true
						state:AddFeed("📞 Actually became friends! Strangest connection!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("📞 Nice brief chat. Humans can be delightful!")
					else
						state:ModifyStat("Happiness", -1)
						state:AddFeed("📞 Awkward exchange. They hung up confused.")
					end
				end,
			},
			{ text = "Just hang up", effects = { Happiness = 1 }, feedText = "📞 Wrong number. End of story. Normal day." },
		},
	},
	{
		id = "misc_random_gift",
		title = "Unexpected Gift",
		emoji = "🎁",
		text = "Someone gave you an unexpected gift!",
		question = "What is it?",
		minAge = 5, maxAge = 100,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "gift", "surprise", "kind" },
		
		-- CRITICAL: Random gift value
		choices = {
			{
				text = "Open the gift",
				effects = {},
				feedText = "Unwrapping...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state.Money = (state.Money or 0) + 200
						state:ModifyStat("Happiness", 12)
						state:AddFeed("🎁 AMAZING GIFT! So thoughtful! Worth a lot!")
					elseif roll < 0.55 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🎁 Perfect gift! They know you so well!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🎁 Nice gesture! The thought counts!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🎁 Awkward gift. Smile and say thanks. Will regift.")
					end
				end,
			},
		},
	},
	{
		id = "misc_power_outage",
		title = "Power Outage",
		emoji = "💡",
		text = "The power went out!",
		question = "How do you handle being in the dark?",
		minAge = 5, maxAge = 100,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "inconvenience",
		tags = { "power", "outage", "emergency" },
		
		-- CRITICAL: Random power outage outcome
		choices = {
			{
				text = "Wait it out",
				effects = {},
				feedText = "In the darkness...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💡 Brief outage! Power back quickly!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -2)
						state:AddFeed("💡 Few hours in the dark. Candles and board games!")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", -6)
						state.Money = (state.Money or 0) - 100
						state:AddFeed("💡 Long outage! Lost food in fridge! Miserable!")
					else
						state:ModifyStat("Happiness", -8)
						state.Money = (state.Money or 0) - 300
						state.Flags = state.Flags or {}
						state.Flags.survived_blackout = true
						state:AddFeed("💡 DAYS without power! Survival mode! Traumatic!")
					end
				end,
			},
			{ text = "Go somewhere with power", effects = { Money = -30, Happiness = 3 }, feedText = "💡 Found a cafe/friend's place. Charged devices. Survived!" },
		},
	},
}

return MiscEvents
