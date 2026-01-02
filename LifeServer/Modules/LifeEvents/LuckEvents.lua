--[[
    Luck Events
    Random lucky and unlucky events
    All events use randomized outcomes - NO god mode
]]

local LuckEvents = {}

local STAGE = "random"

LuckEvents.events = {
	{
		id = "luck_four_leaf",
		title = "Four-Leaf Clover",
		emoji = "🍀",
		text = "You found a four-leaf clover!",
		-- CRITICAL FIX: Added text variations for clover discovery!
		textVariants = {
			"Walking through a field, you spot something rare - a four-leaf clover!",
			"While sitting on grass, you notice it - an actual four-leaf clover!",
			"Your eyes catch something special - a lucky four-leaf clover!",
			"Among all the regular clovers, there it is - four leaves!",
			"You've never found one before, but today is different - four leaves!",
		},
		question = "Does the luck hold?",
		minAge = 5, maxAge = 100,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "luck", "clover", "fortune" },
		-- AAA FIX: Can't find clovers in prison!
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		choices = {
			{
				text = "Keep it for good luck",
				effects = {},
				feedText = "Keeping the lucky clover...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						state.Money = (state.Money or 0) + 100
						state.Flags = state.Flags or {}
						state.Flags.lucky_clover = true
						if state.AddFeed then state:AddFeed("🍀 LUCK IS REAL! Good things happening! Keep the clover!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 4) end
						if state.AddFeed then state:AddFeed("🍀 Nice keepsake! Luck or not, makes you smile!") end
					end
				end,
			},
		},
	},
	{
		id = "luck_bird_poop",
		title = "Bird Poop",
		emoji = "💩",
		text = "A bird pooped on you!",
		question = "Is it actually good luck?",
		minAge = 5, maxAge = 100,
		baseChance = 0.1,
		cooldown = 5, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "bird", "luck", "gross" },
		-- AAA FIX: Can't get pooped on by birds in prison (indoor!)
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		choices = {
			{
				text = "Believe it's good luck",
				effects = {},
				feedText = "Choosing to see the positive...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state.Money = (state.Money or 0) + 50
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddFeed then state:AddFeed("💩 The old wives tale was TRUE! Lucky day after the poop!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("💩 Just gross. No luck. Need a shower.") end
					end
				end,
			},
		},
	},
	{
		id = "luck_shooting_star",
		title = "Shooting Star",
		emoji = "⭐",
		text = "You saw a shooting star!",
		question = "Make a wish!",
		minAge = 5, maxAge = 100,
		baseChance = 0.32,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "star", "wish", "magic" },
		
		choices = {
			{
				text = "Make a heartfelt wish",
				effects = {},
				feedText = "Wishing on the star...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 15) end
						state.Flags = state.Flags or {}
						state.Flags.wish_came_true = true
						if state.AddFeed then state:AddFeed("⭐ YOUR WISH CAME TRUE! Magic is real! Universe listening!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 6) end
						if state.AddFeed then state:AddFeed("⭐ Beautiful moment. Wish made. Who knows what's possible?") end
					end
				end,
			},
		},
	},
	{
		id = "luck_broken_mirror",
		title = "Broken Mirror",
		emoji = "🪞",
		text = "You broke a mirror!",
		question = "7 years bad luck?",
		minAge = 8, maxAge = 100,
		baseChance = 0.1,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "mirror", "superstition", "bad_luck" },
		
		choices = {
			{
				text = "Believe in the curse",
				effects = {},
				feedText = "Worrying about bad luck...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						if state.ModifyStat then state:ModifyStat("Happiness", -6) end
						if state.AddFeed then state:AddFeed("🪞 Bad things DID happen! Superstition confirmed!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("🪞 Just a broken mirror. Cleaned it up. Life goes on.") end
					end
				end,
			},
			{ text = "Superstition is silly", effects = { Happiness = 2, Smarts = 2 }, feedText = "🪞 It's just glass. No such thing as curses. Rational." },
		},
	},
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EXPANDED LUCK EVENTS - More variety!
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "luck_lottery_ticket",
		title = "Found Lottery Ticket!",
		emoji = "🎰",
		text = "You found a lottery ticket on the ground!",
		textVariants = {
			"There's a scratch-off ticket just sitting there on the sidewalk!",
			"Someone dropped a lottery ticket. Finders keepers?",
			"A lottery ticket blows past you in the wind. You catch it!",
		},
		question = "Scratch it?",
		minAge = 18, maxAge = 100,
		baseChance = 0.15,
		cooldown = 6,
		stage = STAGE,
		category = "luck",
		tags = { "lottery", "money", "luck" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "🎫 Scratch and hope!",
				effects = {},
				feedText = "Scratching the ticket...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.05 then
						-- Jackpot!
						local prize = math.random(5000, 10000)
						state.Money = (state.Money or 0) + prize
						if state.ModifyStat then state:ModifyStat("Happiness", 25) end
						state.Flags = state.Flags or {}
						state.Flags.lottery_winner = true
						if state.AddFeed then state:AddFeed(string.format("🎰 JACKPOT! WON $%d! WHAT ARE THE ODDS?!", prize)) end
					elseif roll < 0.20 then
						-- Small win
						local prize = math.random(50, 200)
						state.Money = (state.Money or 0) + prize
						if state.ModifyStat then state:ModifyStat("Happiness", 10) end
						if state.AddFeed then state:AddFeed(string.format("🎰 Won $%d! Not bad for a free ticket!", prize)) end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("🎰 Not a winner. Easy come, easy go.") end
					end
				end,
			},
			{ text = "Leave it - could be bad luck", effects = { Happiness = 1 }, feedText = "Probably nothing anyway. Walked away." },
		},
	},
	{
		id = "luck_penny_heads",
		title = "Lucky Penny",
		emoji = "🪙",
		text = "You found a penny on the ground - heads up!",
		textVariants = {
			"A shiny penny, face up! That's supposed to be lucky!",
			"There it is - a heads-up penny. Pick it up?",
			"Penny on the sidewalk, Lincoln staring at the sky!",
		},
		question = "Pick it up?",
		minAge = 5, maxAge = 100,
		baseChance = 0.20,
		cooldown = 4,
		stage = STAGE,
		category = "luck",
		tags = { "penny", "luck", "money" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "Pick it up for good luck!",
				effects = {},
				feedText = "Picking up the lucky penny...",
				onResolve = function(state)
					local roll = math.random()
					state.Money = (state.Money or 0) + 1 -- It's a penny!
					if roll < 0.30 then
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						state.Flags = state.Flags or {}
						state.Flags.lucky_penny = true
						if state.AddFeed then state:AddFeed("🪙 Good things started happening! The penny worked!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 3) end
						if state.AddFeed then state:AddFeed("🪙 A penny saved! Feeling oddly positive!") end
					end
				end,
			},
			{ text = "Leave it - not worth bending down", effects = {}, feedText = "It's just a penny. Kept walking." },
		},
	},
	{
		id = "luck_black_cat",
		title = "Black Cat Crossing",
		emoji = "🐈‍⬛",
		text = "A black cat crossed your path!",
		textVariants = {
			"A sleek black cat darts across the street in front of you!",
			"That black cat just walked RIGHT in front of you...",
			"A midnight-black cat stops, looks at you, then crosses your path.",
		},
		question = "Bad luck or just a cute cat?",
		minAge = 5, maxAge = 100,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		category = "luck",
		tags = { "cat", "superstition", "luck" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "😰 Oh no, bad luck incoming!",
				effects = {},
				feedText = "Dreading the bad luck...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						if state.ModifyStat then state:ModifyStat("Happiness", -5) end
						if state.AddFeed then state:AddFeed("🐈‍⬛ Something DID go wrong today! The cat cursed you!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 2) end
						if state.AddFeed then state:AddFeed("🐈‍⬛ Nothing bad happened. Maybe superstitions are silly.") end
					end
				end,
			},
			{
				text = "🥰 What a cute kitty!",
				effects = { Happiness = 5 },
				feedText = "🐈‍⬛ Just an adorable cat! Made your day better actually!",
			},
		},
	},
	{
		id = "luck_rainbow",
		title = "Double Rainbow!",
		emoji = "🌈",
		text = "You look up and see a DOUBLE RAINBOW!",
		textVariants = {
			"After the rain, the most AMAZING double rainbow appears!",
			"You've never seen a rainbow this vivid - and there's TWO of them!",
			"The sky lights up with not one but TWO perfect rainbows!",
		},
		question = "What does it mean?",
		minAge = 3, maxAge = 100,
		baseChance = 0.10,
		cooldown = 8,
		stage = STAGE,
		category = "luck",
		tags = { "rainbow", "beauty", "luck" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "🌈 It's a sign! Good things coming!",
				effects = {},
				feedText = "Feeling blessed...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						if state.ModifyStat then state:ModifyStat("Happiness", 15) end
						state.Flags = state.Flags or {}
						state.Flags.rainbow_blessing = true
						if state.AddFeed then state:AddFeed("🌈 Something WONDERFUL happened soon after! The rainbow was a sign!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 10) end
						if state.AddFeed then state:AddFeed("🌈 Beautiful moment. Feeling optimistic about the future!") end
					end
				end,
			},
			{ text = "📸 Take a picture!", effects = { Happiness = 8 }, setFlags = { captured_rainbow = true }, feedText = "🌈 Got the photo! This is phone wallpaper material!" },
		},
	},
	{
		id = "luck_friday_13th",
		title = "Friday the 13th",
		emoji = "👻",
		text = "Today is Friday the 13th!",
		textVariants = {
			"You just realized - it's Friday the 13th today!",
			"Calendar check: Friday the 13th. Uh oh.",
			"Someone at work mentioned it's Friday the 13th. Great.",
		},
		question = "Do you believe in the curse?",
		minAge = 10, maxAge = 100,
		baseChance = 0.08,
		cooldown = 10,
		stage = STAGE,
		category = "luck",
		tags = { "friday", "superstition", "spooky" },
		
		choices = {
			{
				text = "😬 Stay home and hide!",
				effects = { Happiness = -3 },
				feedText = "Playing it safe...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						if state.AddFeed then state:AddFeed("👻 Stayed safe! Nothing bad happened! Smart choice!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -5) end
						if state.AddFeed then state:AddFeed("👻 Something still went wrong anyway! Can't escape fate!") end
					end
				end,
			},
			{
				text = "🤷 Just another day!",
				effects = {},
				feedText = "Living normally...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.80 then
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddFeed then state:AddFeed("👻 Nothing bad happened! Superstitions are silly!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -8) end
						if state.AddFeed then state:AddFeed("👻 Actually had a TERRIBLE day! Maybe there's something to it?!") end
					end
				end,
			},
		},
	},
	{
		id = "luck_ladybug",
		title = "Ladybug Landing",
		emoji = "🐞",
		text = "A ladybug landed on you!",
		textVariants = {
			"The cutest little ladybug just landed on your hand!",
			"A bright red ladybug with perfect spots chose YOU to land on!",
			"You feel something tickle your arm - it's a ladybug!",
		},
		question = "Lucky omen?",
		minAge = 3, maxAge = 100,
		baseChance = 0.12,
		cooldown = 5,
		stage = STAGE,
		category = "luck",
		tags = { "ladybug", "nature", "luck" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "🐞 Make a wish!",
				effects = {},
				feedText = "Making a wish...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						if state.ModifyStat then state:ModifyStat("Happiness", 12) end
						state.Flags = state.Flags or {}
						state.Flags.ladybug_luck = true
						if state.AddFeed then state:AddFeed("🐞 Your wish CAME TRUE! Ladybugs are magic!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 6) end
						if state.AddFeed then state:AddFeed("🐞 Such a peaceful moment. Feeling blessed!") end
					end
				end,
			},
			{ text = "Let it fly away gently", effects = { Happiness = 5 }, feedText = "🐞 Bye little friend! What a cute moment!" },
		},
	},
	{
		id = "luck_number_11_11",
		title = "11:11!",
		emoji = "🕚",
		text = "You looked at the clock at EXACTLY 11:11!",
		textVariants = {
			"Glanced at your phone and it's 11:11! Make a wish!",
			"The clock says 11:11 - quick, wish for something!",
			"11:11 on the dot! This is supposed to be significant!",
		},
		question = "Make a wish?",
		minAge = 8, maxAge = 100,
		baseChance = 0.15,
		cooldown = 4,
		stage = STAGE,
		category = "luck",
		tags = { "time", "wish", "luck" },
		
		choices = {
			{
				text = "🙏 Wish for something important!",
				effects = {},
				feedText = "Wishing intensely...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.20 then
						if state.ModifyStat then state:ModifyStat("Happiness", 20) end
						state.Flags = state.Flags or {}
						state.Flags.eleven_eleven_magic = true
						if state.AddFeed then state:AddFeed("🕚 YOUR 11:11 WISH CAME TRUE! Universe is listening!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 4) end
						if state.AddFeed then state:AddFeed("🕚 Wish made! Time will tell if the universe heard you.") end
					end
				end,
			},
			{ text = "Just a coincidence", effects = { Smarts = 2 }, feedText = "🕚 It's just a clock. Back to whatever you were doing." },
		},
	},
	{
		id = "luck_beginner",
		title = "Beginner's Luck!",
		emoji = "🎲",
		text = "You tried something new for the first time and you're CRUSHING it!",
		textVariants = {
			"First time playing this game and you're WINNING!",
			"Never done this before but you're a natural!",
			"Beginner's luck is REAL - you're dominating!",
		},
		question = "How does it feel?",
		minAge = 8, maxAge = 100,
		baseChance = 0.12,
		cooldown = 6,
		stage = STAGE,
		category = "luck",
		tags = { "beginner", "winning", "luck" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "🎉 Keep the streak going!",
				effects = {},
				feedText = "Riding the luck wave...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						if state.ModifyStat then state:ModifyStat("Happiness", 15) end
						state.Money = (state.Money or 0) + math.random(50, 200)
						if state.AddFeed then state:AddFeed("🎲 WON AGAIN! Beginner's luck is INSANE!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 3) end
						if state.AddFeed then state:AddFeed("🎲 Luck ran out. Back to being a beginner.") end
					end
				end,
			},
			{ text = "Quit while ahead!", effects = { Happiness = 8, Smarts = 3 }, feedText = "🎲 Smart move! Left on a high note!" },
		},
	},
	{
		id = "luck_deja_vu",
		title = "Deja Vu!",
		emoji = "🔄",
		text = "You just had the STRONGEST deja vu moment!",
		textVariants = {
			"Wait... you've lived this exact moment before. You're SURE of it.",
			"Everything about this moment feels impossibly familiar...",
			"This has happened before. Exactly like this. What is going on?",
		},
		question = "What does it mean?",
		minAge = 10, maxAge = 100,
		baseChance = 0.10,
		cooldown = 5,
		stage = STAGE,
		category = "luck",
		tags = { "deja_vu", "mystery", "weird" },
		
		choices = {
			{ text = "🔮 A sign from the universe!", effects = { Happiness = 5 }, setFlags = { believes_in_signs = true }, feedText = "🔄 Something cosmic is happening! You're on the right path!" },
			{ text = "🧠 Just a brain glitch", effects = { Smarts = 3 }, feedText = "🔄 Fascinating neurological phenomenon. Brains are weird!" },
			{ text = "😰 Kinda creepy honestly", effects = { Happiness = -2 }, feedText = "🔄 That was unsettling. Reality feels fragile now." },
		},
	},
}

return LuckEvents
