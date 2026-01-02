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
		text = "You spotted something on the ground!",
		question = "Do you pick it up?",
		minAge = 8, maxAge = 100,
		baseChance = 0.4,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "found", "lucky", "discovery" },
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL FIX #1012: Added more choice options including decline
		choices = {
			{
				text = "Check it out!",
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
			{
				text = "Leave it alone",
				effects = {},
				feedText = "🔍 You walked past. Not worth the trouble.",
			},
			{
				text = "Turn it in to lost and found",
				effects = { Smarts = 1 },
				feedText = "🔍 Good citizen! Maybe karma will reward you later.",
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
		baseChance = 0.455,
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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "kindness", "witness", "humanity" },
		
		choices = {
			{ text = "Faith in humanity restored", effects = { Happiness = 8, Smarts = 2 }, setFlags = { believes_in_good = true }, feedText = "💖 Beautiful moment! People CAN be good! Touched!" },
			{ 
				text = "Inspired to pay it forward", 
				effects = { Happiness = 6 }, 
				feedText = "💖 Immediately helped someone else! Chain of kindness!",
				eligibility = function(state) return (state.Money or 0) >= 20, "💸 Can't afford to help right now" end,
			},
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
		baseChance = 0.455,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddFeed then state:AddFeed("🦸 Helped but situation was complicated. Did what you could.") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 20)
						if state.AddFeed then state:AddFeed("🦸 Tried to help but they took advantage. Lesson learned.") end
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
		baseChance = 0.45,
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
		baseChance = 0.455,
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
			{ text = "Panic and find charger ($10)", effects = { Happiness = -2, Money = -10 }, feedText = "🔋 Found a charger! Sweet relief! Never again!", eligibility = function(state) return (state.Money or 0) >= 10, "💸 Need $10 for charger" end },
		},
	},
	{
		id = "misc_random_smell",
		title = "Random Smell Encounter",
		emoji = "👃",
		text = "A smell triggered a powerful memory!",
		question = "What memory did the smell bring back?",
		minAge = 10, maxAge = 100,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.55,
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
		baseChance = 0.455,
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
		baseChance = 0.455,
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
						if state.ModifyStat then state:ModifyStat("Happiness", -3) end
						if state.AddFeed then state:AddFeed("📶 Hours without internet! Forgot how to exist offline!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -6) end
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 50)
						if state.AddFeed then state:AddFeed("📶 Had to call ISP. On hold forever. Rage inducing.") end
					end
				end,
			},
			{ text = "Go outside", effects = { Happiness = 5, Health = 3 }, feedText = "📶 Forced to go outside! Actually nice! Nature exists!" },
			{ text = "Use mobile data ($20)", effects = { Happiness = 2, Money = -20 }, feedText = "📶 Burning through data plan! Desperate times!", eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20 for extra data" end },
		},
	},
	{
		id = "misc_unexpected_day_off",
		title = "Unexpected Day Off",
		emoji = "🎉",
		text = "You got an unexpected day off!",
		question = "What do you do with your free day?",
		minAge = 18, maxAge = 80,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "opportunity",
		tags = { "free_time", "day_off", "opportunity" },
		
		choices = {
			{ text = "Sleep in and relax", effects = { Happiness = 10, Health = 4 }, feedText = "🎉 SLEPT IN! Glorious rest! Self-care day!" },
			{ text = "Spontaneous adventure ($50)", effects = { Happiness = 12, Money = -50 }, feedText = "🎉 Impromptu trip/activity! Best kind of day!", eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 for adventure" end },
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
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
						if state.ModifyStat then state:ModifyStat("Happiness", -6) end
						state.Money = math.max(0, (state.Money or 0) - 100)
						if state.AddFeed then state:AddFeed("💡 Long outage! Lost food in fridge! Miserable!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -8) end
						state.Money = math.max(0, (state.Money or 0) - 300)
						state.Flags = state.Flags or {}
						state.Flags.survived_blackout = true
						if state.AddFeed then state:AddFeed("💡 DAYS without power! Survival mode! Traumatic!") end
					end
				end,
			},
			{ text = "Go somewhere with power ($30)", effects = { Money = -30, Happiness = 3 }, feedText = "💡 Found a cafe/friend's place. Charged devices. Survived!", eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30 for cafe" end },
		},
	},
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EXPANDED MISC EVENTS - More variety for every playthrough!
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "misc_random_act_kindness",
		title = "Random Act of Kindness",
		emoji = "💝",
		text = "Someone did something unexpectedly kind for you!",
		textVariants = {
			"A stranger paid for your coffee in the drive-thru!",
			"Someone held the door and complimented your outfit!",
			"A person helped you when you dropped your groceries!",
			"Someone gave up their seat for you on the bus!",
		},
		question = "How do you respond?",
		minAge = 8, maxAge = 100,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		category = "social",
		tags = { "kindness", "strangers", "positive" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "💖 Pay it forward!",
				effects = { Happiness = 10, Money = -10 },
				setFlags = { pays_it_forward = true },
				feedText = "💝 You did something kind for someone else! The kindness chain continues!",
			},
			{ text = "😊 Thank them warmly", effects = { Happiness = 8 }, feedText = "💝 Made eye contact, smiled, said thank you. Simple but meaningful." },
			{ text = "Barely notice", effects = { Happiness = 3 }, feedText = "💝 Didn't fully appreciate it in the moment. Reflected on it later." },
		},
	},
	{
		id = "misc_phone_died",
		title = "Phone Died!",
		emoji = "📱",
		text = "Your phone just died at the WORST possible time!",
		textVariants = {
			"0% battery. No charger. Lost without your phone.",
			"Phone screen goes black. Can't call anyone!",
			"Should've charged it. Phone is completely dead.",
		},
		question = "How do you cope?",
		minAge = 12, maxAge = 80,
		baseChance = 0.20,
		cooldown = 4,
		stage = STAGE,
		category = "inconvenience",
		tags = { "phone", "technology", "frustration" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "😤 This is a DISASTER!",
				effects = { Happiness = -8 },
				feedText = "📱 Completely lost without your phone. Modern life is hard.",
			},
			{
				text = "🙄 Annoying but manageable",
				effects = { Happiness = -3 },
				feedText = "📱 Inconvenient but you figured it out. Remember physical maps?",
			},
			{
				text = "🧘 Actually kind of freeing!",
				effects = { Happiness = 5 },
				setFlags = { phone_detox = true },
				feedText = "📱 Disconnected from screens. Noticed things you usually miss!",
			},
		},
	},
	{
		id = "misc_perfect_parking",
		title = "Perfect Parking Spot!",
		emoji = "🅿️",
		text = "You found the PERFECT parking spot right in front!",
		textVariants = {
			"Someone pulled out just as you arrived. Prime spot!",
			"Right in front of the store. No walking required!",
			"The universe blessed you with parking today!",
		},
		question = "How lucky do you feel?",
		minAge = 16, maxAge = 100,
		baseChance = 0.12,
		cooldown = 5,
		stage = STAGE,
		category = "luck",
		tags = { "parking", "driving", "lucky" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{ text = "🙌 YES! Today is my day!", effects = { Happiness = 8 }, setFlags = { lucky_parker = true }, feedText = "🅿️ Perfect parking energy! Everything's going your way!" },
			{ text = "Nice, saved some walking", effects = { Happiness = 4 }, feedText = "🅿️ Convenient! Quick errand time." },
		},
	},
	{
		id = "misc_nostalgia_moment",
		title = "Nostalgia Hit",
		emoji = "🥹",
		text = "Something triggered a powerful wave of nostalgia!",
		textVariants = {
			"A song from your childhood started playing. Instant time travel.",
			"You smelled something that transported you to the past.",
			"Found an old photo. The memories came flooding back.",
			"Revisited a place from your childhood. Smaller than you remember.",
		},
		question = "How do you feel?",
		minAge = 15, maxAge = 100,
		baseChance = 0.15,
		cooldown = 4,
		stage = STAGE,
		category = "emotional",
		tags = { "nostalgia", "memories", "emotions" },
		
		choices = {
			{
				text = "😢 Bittersweet tears",
				effects = { Happiness = 5 },
				setFlags = { nostalgic_soul = true },
				feedText = "🥹 Good memories mixed with longing for simpler times. Crying a little.",
			},
			{
				text = "😊 Warm fuzzy feelings",
				effects = { Happiness = 10 },
				feedText = "🥹 What a beautiful trip down memory lane! Grateful for the past!",
			},
			{
				text = "😐 Try not to dwell",
				effects = { Happiness = 2, Smarts = 2 },
				feedText = "🥹 Nice memories but living in the present is important.",
			},
		},
	},
	{
		id = "misc_long_line",
		title = "Endless Line!",
		emoji = "🚶",
		text = "You're stuck in the LONGEST line ever!",
		textVariants = {
			"The line wraps around the building. This is going to take forever.",
			"Who ARE all these people?! The wait is ridiculous!",
			"You've been standing here for 20 minutes. Barely moved.",
		},
		question = "How do you handle it?",
		minAge = 8, maxAge = 100,
		baseChance = 0.18,
		cooldown = 4,
		stage = STAGE,
		category = "inconvenience",
		tags = { "waiting", "patience", "frustration" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{ text = "😤 Get visibly frustrated", effects = { Happiness = -5, Health = -2 }, feedText = "🚶 Blood pressure rising. This is UNACCEPTABLE!" },
			{ text = "📱 Phone time!", effects = { Happiness = 2 }, feedText = "🚶 Scrolled through everything. Time flew by actually." },
			{ text = "💬 Chat with others in line", effects = { Happiness = 6 }, setFlags = { friendly_stranger = true }, feedText = "🚶 Made a new friend! The line brought you together!" },
			{ text = "🚶 Leave. Not worth it.", effects = { Happiness = 3 }, feedText = "🚶 Nope. You'll come back another day. Time is valuable." },
		},
	},
	{
		id = "misc_perfect_weather",
		title = "Perfect Weather Day!",
		emoji = "☀️",
		text = "The weather today is absolutely PERFECT!",
		textVariants = {
			"Clear skies, perfect temperature, light breeze. Chef's kiss!",
			"This is the kind of day people write songs about!",
			"Everyone's outside enjoying this incredible weather!",
		},
		question = "How do you spend this beautiful day?",
		minAge = 5, maxAge = 100,
		baseChance = 0.12,
		cooldown = 6,
		stage = STAGE,
		category = "positive",
		tags = { "weather", "outdoors", "happiness" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{ text = "☀️ Spend ALL day outside!", effects = { Happiness = 12, Health = 5 }, feedText = "☀️ Soaked in every minute of this perfect day! Recharged!" },
			{ text = "🏠 Stay inside anyway", effects = { Happiness = -3 }, feedText = "☀️ Looked out the window. Should've gone outside. Regrets." },
			{ text = "📸 Take pictures!", effects = { Happiness = 8 }, feedText = "☀️ Captured the beauty! Great content for memories!" },
		},
	},
	{
		id = "misc_weird_dream",
		title = "Bizarre Dream!",
		emoji = "💭",
		text = "You had the WEIRDEST dream last night!",
		textVariants = {
			"You dreamed you could fly but kept forgetting how!",
			"Everyone in your dream had the wrong face!",
			"You were late for something but the location kept changing!",
			"Teeth falling out, being chased, showing up naked - classic stress dream!",
		},
		question = "What do you make of it?",
		minAge = 8, maxAge = 100,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		category = "experience",
		tags = { "dreams", "sleep", "weird" },
		
		choices = {
			{ text = "🔮 Must mean something!", effects = { Happiness = 2 }, setFlags = { believes_in_dreams = true }, feedText = "💭 Looked up dream meanings. Apparently teeth = anxiety!" },
			{ text = "🧠 Just random brain stuff", effects = { Smarts = 2 }, feedText = "💭 Dreams are just your brain processing the day. Interesting though!" },
			{ text = "📓 Write it down!", effects = { Smarts = 3, Happiness = 3 }, setFlags = { dream_journaler = true }, feedText = "💭 Started a dream journal! Fascinating patterns emerging!" },
		},
	},
	{
		id = "misc_unexpected_compliment",
		title = "Unexpected Compliment!",
		emoji = "✨",
		text = "A stranger just gave you a genuine compliment!",
		textVariants = {
			"'Excuse me, I just had to say - you have great style!'",
			"Someone stopped to tell you that you have a nice smile!",
			"'Hey, you look really confident. Keep it up!'",
			"A stranger complimented your hair/outfit/energy!",
		},
		question = "How does it make you feel?",
		minAge = 10, maxAge = 100,
		baseChance = 0.12,
		cooldown = 5,
		stage = STAGE,
		category = "social",
		tags = { "compliment", "confidence", "social" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{ text = "😊 My whole day is made!", effects = { Happiness = 12, Looks = 2 }, feedText = "✨ Walking on air! Confidence boosted! GLOWING!" },
			{ text = "😳 Awkward but nice", effects = { Happiness = 6 }, feedText = "✨ Didn't know how to respond but appreciated it!" },
			{ text = "🤔 Were they being genuine?", effects = { Happiness = 3 }, feedText = "✨ Skeptical at first but... probably genuine. Nice." },
		},
	},
}

return MiscEvents
