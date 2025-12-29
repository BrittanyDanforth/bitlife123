--[[
    Life Experiences Events
    Random life experiences and special moments
    All events use randomized outcomes - NO god mode
]]

local LifeExperiences = {}

local STAGE = "random"

LifeExperiences.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- ONCE IN A LIFETIME EXPERIENCES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "exp_eclipse_viewing",
		title = "Rare Eclipse",
		emoji = "🌑",
		text = "A rare solar/lunar eclipse is happening in your area!",
		question = "Do you watch the eclipse?",
		minAge = 5, maxAge = 100,
		baseChance = 0.05,
		cooldown = 4,
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "nature", "rare", "experience" },
		
		choices = {
			{ text = "Watch it with proper glasses", effects = { Happiness = 10, Smarts = 2 }, setFlags = { saw_eclipse = true }, feedText = "🌑 Breathtaking! Once in a lifetime moment!" },
			{ text = "Miss it entirely", effects = { Happiness = -3 }, feedText = "🌑 Forgot about it. Regret when everyone talks about it." },
			{ text = "Try to look without protection", effects = { Happiness = 4, Health = -8 }, setFlags = { damaged_eyes = true }, feedText = "🌑 SAW IT but... your vision is damaged. Bad choice." },
		},
	},
	{
		id = "exp_natural_disaster_witness",
		title = "Witnessing Nature's Power",
		emoji = "⛈️",
		text = "You witnessed an intense natural phenomenon!",
		question = "What did you see?",
		minAge = 8, maxAge = 100,
		baseChance = 0.1,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "nature", "witness", "powerful" },
		
		choices = {
			{ text = "Incredible lightning storm", effects = { Happiness = 6, Smarts = 2 }, feedText = "⛈️ Nature's light show. Terrifying and beautiful." },
			{ text = "Massive waves/flooding", effects = { Happiness = -4, Smarts = 2 }, setFlags = { flood_witness = true }, feedText = "⛈️ The power of water. Humbling and scary." },
			{ text = "Earthquake tremors", effects = { Happiness = -3, Smarts = 2 }, setFlags = { felt_earthquake = true }, feedText = "⛈️ Ground shaking. Primal fear. Never forget it." },
			{ text = "Breathtaking aurora", effects = { Happiness = 10, Smarts = 2 }, setFlags = { saw_aurora = true }, feedText = "⛈️ Northern lights! Magical. Life-changing beauty." },
		},
	},
	{
		id = "exp_brush_with_fame",
		title = "Brush with Fame",
		emoji = "⭐",
		text = "You had a random interaction with someone famous!",
		question = "How did the encounter go?",
		minAge = 10, maxAge = 90,
		baseChance = 0.08,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "fame", "celebrity", "encounter" },
		
		-- CRITICAL: Random celebrity interaction
		choices = {
			{
				text = "Play it cool",
				effects = {},
				feedText = "Acting casual...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.met_celebrity = true
						state:AddFeed("⭐ Had a nice chat! They were so normal and cool!")
					else
						state:ModifyStat("Happiness", 4)
						state:AddFeed("⭐ Brief polite exchange. Still counts!")
					end
				end,
			},
			{
				text = "Fanboy/fangirl moment",
				effects = {},
				feedText = "Can't contain your excitement...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("⭐ They were so gracious about your enthusiasm! Photo together!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("⭐ Scared them off. Too intense. Cringe memories.")
					end
				end,
			},
			{
				text = "Don't recognize them at first",
				effects = { Happiness = 5, Smarts = 2 },
				feedText = "⭐ Talked normally then realized. They appreciated being treated like a regular person!",
			},
		},
	},
	{
		id = "exp_life_flashing",
		title = "Life Flashing Before Eyes",
		emoji = "💫",
		text = "You had a near-miss that made your life flash before your eyes!",
		question = "How did you process this experience?",
		minAge = 16, maxAge = 90,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "near_death", "perspective", "life" },
		
		choices = {
			{ text = "Reassess priorities completely", effects = { Happiness = 5, Smarts = 5 }, setFlags = { life_epiphany = true }, feedText = "💫 Changed everything. Life is too short for BS." },
			{ text = "Shake it off and continue", effects = { Happiness = 2 }, feedText = "💫 Scary moment but life goes on." },
			{ text = "Develop anxiety about it", effects = { Happiness = -6, Health = -2 }, setFlags = { near_death_anxiety = true }, feedText = "💫 Can't stop thinking about 'what if'. PTSD symptoms." },
			{ text = "Become more adventurous", effects = { Happiness = 4, Health = -1 }, setFlags = { yolo_attitude = true }, feedText = "💫 YOLO! Taking more risks. Living fully!" },
		},
	},
	{
		id = "exp_bucket_list_item",
		title = "Bucket List Achievement",
		emoji = "✅",
		text = "You accomplished something on your bucket list!",
		question = "What did you achieve?",
		minAge = 18, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "achievement",
		tags = { "bucket_list", "achievement", "goals" },
		
		eligibility = function(state)
			local money = state.Money or 0
			local health = (state.Stats and state.Stats.Health) or 50
			if money < 500 and health < 40 then
				return false, "Need resources for bucket list items"
			end
			return true
		end,
		
		choices = {
			{ 
				-- CRITICAL FIX: Show price and add per-choice eligibility check
				text = "Visited dream destination ($1,500)", 
				effects = { Happiness = 15, Money = -1500 }, 
				setFlags = { traveled_dream_place = true }, 
				feedText = "✅ The trip of a lifetime! Everything you imagined!",
				eligibility = function(state)
					if (state.Money or 0) < 1500 then
						return false, "Can't afford $1,500 dream trip"
					end
					return true
				end,
			},
			{ 
				-- CRITICAL FIX: Show price and add per-choice eligibility check
				text = "Met a personal hero ($200)", 
				effects = { Happiness = 12, Money = -200 }, 
				setFlags = { met_hero = true }, 
				feedText = "✅ They were even better in person. Inspired!",
				eligibility = function(state)
					if (state.Money or 0) < 200 then
						return false, "Can't afford $200 to meet hero"
					end
					return true
				end,
			},
			{ 
				-- CRITICAL FIX: Show price and add per-choice eligibility check
				text = "Learned a lifelong dream skill ($300)", 
				effects = { Happiness = 10, Smarts = 5, Money = -300 }, 
				setFlags = { learned_dream_skill = true }, 
				feedText = "✅ Finally! Something you always wanted to do!",
				eligibility = function(state)
					if (state.Money or 0) < 300 then
						return false, "Can't afford $300 for classes"
					end
					return true
				end,
			},
			{ 
				-- CRITICAL FIX: Show price and add per-choice eligibility check
				text = "Accomplished a physical feat ($500)", 
				effects = { Happiness = 12, Health = 3, Money = -500 }, 
				setFlags = { physical_achievement = true }, 
				feedText = "✅ Your body did that! Marathon/climb/swim - DONE!",
				eligibility = function(state)
					if (state.Money or 0) < 500 then
						return false, "Can't afford $500 entry fees"
					end
					return true
				end,
			},
			{
				-- CRITICAL FIX: FREE OPTION to prevent player lock!
				text = "Cross off something that doesn't cost money",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { small_achievement = true },
				feedText = "✅ Reconnected with an old friend, watched a sunrise, wrote a letter - some bucket list items are priceless!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- DAILY LIFE EXPERIENCES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "exp_perfect_day",
		title = "Perfect Day",
		emoji = "☀️",
		text = "Everything is just going RIGHT today!",
		question = "What made today perfect?",
		minAge = 8, maxAge = 100,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "good_day", "happiness", "life" },
		
		choices = {
			{ text = "Everything aligned - work, people, weather", effects = { Happiness = 12, Health = 2 }, feedText = "☀️ One of those rare perfect days. Savoring it." },
			{ text = "Accomplishment that felt great", effects = { Happiness = 10, Smarts = 2 }, feedText = "☀️ Finished something big. Riding that high!" },
			{ text = "Quality time with loved ones", effects = { Happiness = 12 }, feedText = "☀️ Perfect moments with people who matter." },
			{ text = "Just good vibes for no reason", effects = { Happiness = 8 }, feedText = "☀️ No explanation. Just happy. Enjoy it!" },
		},
	},
	{
		id = "exp_terrible_day",
		title = "Terrible, Horrible, No Good Day",
		emoji = "😞",
		text = "Everything that could go wrong today, did.",
		question = "How do you cope with this awful day?",
		minAge = 8, maxAge = 100,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "bad_day", "coping", "life" },
		
		choices = {
			{ text = "Cry it out and go to bed early", effects = { Happiness = -4, Health = 2 }, feedText = "😞 Sometimes you just need to cry. Reset tomorrow." },
			{ text = "Vent to someone who listens", effects = { Happiness = -2, Smarts = 1 }, feedText = "😞 Getting it out helped. They understood." },
			{ text = "Comfort eat/drink", effects = { Happiness = 2, Health = -3 }, feedText = "😞 Ice cream and/or wine. Temporary fix." },
			{ text = "Power through and pretend it's fine", effects = { Happiness = -6 }, setFlags = { bottled_emotions = true }, feedText = "😞 Stuffing it down. It'll come out eventually." },
		},
	},
	{
		id = "exp_deja_vu",
		title = "Intense Déjà Vu",
		emoji = "🔄",
		text = "You had the most intense déjà vu moment!",
		question = "What was the déjà vu like?",
		minAge = 10, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "weird", "deja_vu", "experience" },
		
		choices = {
			{ text = "Eerie - like you'd lived this before", effects = { Happiness = 2, Smarts = 2 }, feedText = "🔄 So vivid. Are we in a simulation?" },
			{ text = "Brief - just a weird brain glitch", effects = { Happiness = 1 }, feedText = "🔄 Brain being weird. Science explains it. Mostly." },
			{ text = "Take it as a sign", effects = { Happiness = 3, Smarts = 1 }, setFlags = { believes_in_signs = true }, feedText = "🔄 The universe is trying to tell you something!" },
			{ text = "Freaks you out", effects = { Happiness = -2 }, feedText = "🔄 That was unsettling. Reality felt unstable." },
		},
	},
	{
		id = "exp_random_act_kindness",
		title = "Random Act of Kindness",
		emoji = "💖",
		text = "You did something kind for a stranger!",
		question = "What kind act did you do?",
		minAge = 8, maxAge = 100,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "kindness",
		tags = { "kindness", "giving", "good_deed" },
		
		choices = {
			{ text = "Paid for their coffee/food", effects = { Happiness = 8 }, setFlags = { kind_person = true }, feedText = "💖 Their reaction made your day! Pay it forward!" },
			{ text = "Helped with something heavy/difficult", effects = { Happiness = 6, Health = -1 }, feedText = "💖 Jumped in to help. They were so grateful!" },
			{ text = "Gave genuine compliment", effects = { Happiness = 5 }, feedText = "💖 Simple words that clearly meant a lot to them." },
			{ text = "Donated money to someone in need", effects = { Happiness = 7 }, feedText = "💖 Direct help. Made a real difference." },
		},
	},
	{
		id = "exp_awkward_moment",
		title = "Peak Awkward Moment",
		emoji = "😬",
		text = "You had a supremely awkward experience!",
		question = "What was the awkward situation?",
		minAge = 10, maxAge = 80,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "awkward", "embarrassing", "social" },
		
		choices = {
			{ text = "Waved at someone who wasn't waving at you", effects = { Happiness = -3 }, feedText = "😬 Played it off like you were stretching. They knew." },
			{ text = "Said 'you too' when inappropriate", effects = { Happiness = -3 }, feedText = "😬 'Enjoy your meal' - 'You too!' They're the waiter." },
			{ text = "Called someone wrong name multiple times", effects = { Happiness = -4 }, feedText = "😬 They finally corrected you. SO embarrassing." },
			{ text = "Bathroom accident situation", effects = { Happiness = -6 }, feedText = "😬 We don't talk about what happened. Ever." },
			{ text = "Sent message to wrong person", effects = { Happiness = -5 }, feedText = "😬 The message was ABOUT them. Crisis." },
		},
	},
	{
		id = "exp_major_coincidence",
		title = "Incredible Coincidence",
		emoji = "🎲",
		text = "An unbelievable coincidence just happened!",
		question = "What was the coincidence?",
		minAge = 10, maxAge = 100,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "coincidence", "fate", "luck" },
		
		choices = {
			{ text = "Ran into someone from your past in unlikely place", effects = { Happiness = 6 }, setFlags = { weird_coincidence = true }, feedText = "🎲 Small world! What are the odds?!" },
			{ text = "Thought of someone then they called", effects = { Happiness = 4 }, feedText = "🎲 Telepathy? Coincidence? Spooky either way." },
			{ text = "Found exactly what you needed by chance", effects = { Happiness = 8, Money = 50 }, feedText = "🎲 Universe providing! Right place, right time!" },
			{ text = "Matching experiences with a stranger", effects = { Happiness = 5 }, feedText = "🎲 Same hometown, same obscure hobby - instant connection!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- LEARNING EXPERIENCES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "exp_learn_hard_lesson",
		title = "Learned the Hard Way",
		emoji = "💡",
		text = "You learned an important lesson the hard way.",
		question = "What lesson did you learn?",
		minAge = 10, maxAge = 80,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "growth",
		tags = { "lesson", "learning", "growth" },
		
		choices = {
			{ text = "Trust must be earned, not given", effects = { Smarts = 4, Happiness = -2 }, setFlags = { trust_carefully = true }, feedText = "💡 Burned by misplaced trust. Won't happen again." },
			{ text = "You can't please everyone", effects = { Smarts = 3, Happiness = 3 }, setFlags = { self_acceptance = true }, feedText = "💡 Stop trying. Their opinion isn't your concern." },
			{ text = "Money comes and goes", effects = { Smarts = 4, Happiness = 2 }, setFlags = { money_perspective = true }, feedText = "💡 Lost some money. Learned it's not everything." },
			{ text = "Health isn't guaranteed", effects = { Smarts = 3, Health = 2, Happiness = 2 }, setFlags = { health_aware = true }, feedText = "💡 Take care of your body. It's the only one you get." },
			{ text = "Time is the real currency", effects = { Smarts = 5, Happiness = 3 }, setFlags = { time_aware = true }, feedText = "💡 You can always make more money. Can't make more time." },
		},
	},
	{
		id = "exp_skill_development",
		title = "New Skill Progress",
		emoji = "📈",
		text = "You've been working on a new skill!",
		question = "How is your skill development going?",
		minAge = 8, maxAge = 90,
		baseChance = 0.555,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "growth",
		tags = { "skill", "learning", "improvement" },
		
		-- CRITICAL: Random skill progress outcome
		choices = {
			{
				text = "Practice consistently",
				effects = {},
				feedText = "Putting in the hours...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.skilled = true
						state:AddFeed("📈 Major breakthrough! Suddenly clicked!")
					elseif roll < 0.85 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📈 Steady progress. Getting better slowly.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📈 Plateau. Frustrating lack of progress.")
					end
				end,
			},
			{
				text = "Take lessons/courses",
				effects = { Money = -100 },
				feedText = "Investing in education...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Smarts", 6)
						state:ModifyStat("Happiness", 4)
						state:AddFeed("📈 Great instruction! Learning accelerated!")
					else
						state:ModifyStat("Smarts", 2)
						state:AddFeed("📈 Course was okay. Some useful tips.")
					end
				end,
			},
			{
				text = "Give up - too hard",
				effects = { Happiness = -3 },
				setFlags = { quitter = true },
				feedText = "📈 Not meant for this. Moving on.",
			},
		},
	},
	{
		id = "exp_world_event_witness",
		title = "Historic Event",
		emoji = "📺",
		text = "A major world event is happening right now.",
		question = "How do you experience this historic moment?",
		minAge = 10, maxAge = 100,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "history", "world", "event" },
		
		choices = {
			{ text = "Glued to the news", effects = { Smarts = 3, Happiness = -2 }, setFlags = { witnessed_history = true }, feedText = "📺 Watching history unfold. Overwhelming." },
			{ text = "Avoid the news - too much", effects = { Happiness = 2, Health = 1 }, setFlags = { news_avoidant = true }, feedText = "📺 Protecting your peace. Can't handle more." },
			{ text = "Discuss with everyone", effects = { Smarts = 2 }, feedText = "📺 Deep conversations. Everyone processing together." },
			{ text = "Document your reaction", effects = { Smarts = 2, Happiness = 2 }, feedText = "📺 Journal/video. Future you will want to remember how you felt." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- UNEXPECTED SITUATIONS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "exp_wrong_place_right_time",
		title = "Wrong Place, Right Time",
		emoji = "✨",
		text = "Being somewhere you weren't supposed to be led to something great!",
		question = "What happened by accident?",
		minAge = 15, maxAge = 80,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "luck", "serendipity", "opportunity" },
		
		choices = {
			{ text = "Met someone important", effects = { Happiness = 8, Smarts = 2 }, setFlags = { serendipity_connection = true }, feedText = "✨ Chance encounter changed everything!" },
			{ text = "Found amazing opportunity", effects = { Happiness = 10, Money = 200 }, feedText = "✨ Right place, right time. Doors opened!" },
			{ text = "Witnessed something incredible", effects = { Happiness = 8 }, feedText = "✨ Saw something you'll never forget." },
			{ text = "Avoided disaster by being elsewhere", effects = { Happiness = 6, Health = 2 }, setFlags = { lucky_escape = true }, feedText = "✨ If you'd been where planned... scary." },
		},
	},
	{
		id = "exp_stranger_wisdom",
		title = "Stranger's Wisdom",
		emoji = "🧙",
		text = "A random stranger said something that really stuck with you.",
		question = "What did they say?",
		minAge = 15, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "growth",
		tags = { "wisdom", "stranger", "insight" },
		
		choices = {
			{ text = "Exactly what you needed to hear", effects = { Happiness = 8, Smarts = 4 }, setFlags = { received_wisdom = true }, feedText = "🧙 How did they know? Changed your perspective." },
			{ text = "Made you question your choices", effects = { Happiness = 2, Smarts = 3 }, feedText = "🧙 Uncomfortable truth. But you needed it." },
			{ text = "Encouraged you at lowest point", effects = { Happiness = 10, Health = 2 }, feedText = "🧙 Angel in disguise. Kept you going." },
			{ text = "Weird but somehow profound", effects = { Happiness = 4, Smarts = 2 }, feedText = "🧙 Made no sense at first. Now it does." },
		},
	},
	{
		id = "exp_technology_fail",
		title = "Technology Disaster",
		emoji = "💻",
		text = "Technology has failed you spectacularly!",
		question = "What went wrong?",
		minAge = 10, maxAge = 90,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "misfortune",
		tags = { "technology", "fail", "frustration" },
		
		-- CRITICAL: Random tech failure
		choices = {
			{
				text = "Deal with the tech crisis",
				effects = {},
				feedText = "Attempting to fix it...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("💻 Lost some data but recovered most. Close call.")
					elseif roll < 0.55 then
						state:ModifyStat("Happiness", -5)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 100)
						state:AddFeed("💻 Needed repair/replacement. $100 gone.")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", -8)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 300)
						state.Flags = state.Flags or {}
						state.Flags.lost_data = true
						state:AddFeed("💻 Major failure. Lost important files. Heartbreaking.")
					else
						state:ModifyStat("Happiness", -10)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 500)
						state:AddFeed("💻 Complete disaster. Expensive replacement needed.")
					end
				end,
			},
		},
	},
	{
		id = "exp_pleasant_surprise",
		title = "Pleasant Surprise",
		emoji = "🎁",
		text = "Something unexpectedly wonderful happened!",
		question = "What was the surprise?",
		minAge = 5, maxAge = 100,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "surprise", "good_news", "luck" },
		
		choices = {
			{ text = "Unexpected gift", effects = { Happiness = 8, Money = 50 }, feedText = "🎁 Someone thought of you! So touching!" },
			{ text = "Good news you didn't expect", effects = { Happiness = 10 }, feedText = "🎁 Life-changing good news! Celebration!" },
			{ text = "Reunited with lost item", effects = { Happiness = 7 }, feedText = "🎁 Found something you thought was gone forever!" },
			{ text = "Spontaneous adventure opportunity", effects = { Happiness = 8 }, feedText = "🎁 Said yes to something random. Best decision!" },
		},
	},
	{
		id = "exp_nostalgia_wave",
		title = "Nostalgia Wave",
		emoji = "🕰️",
		text = "Something triggered intense nostalgia for the past.",
		question = "What brought on the nostalgia?",
		minAge = 18, maxAge = 100,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "nostalgia", "memory", "past" },
		
		choices = {
			{ text = "A song from your past", effects = { Happiness = 5 }, feedText = "🕰️ Transported back in time. The feels hit hard." },
			{ text = "Finding old photos", effects = { Happiness = 6, Smarts = 1 }, feedText = "🕰️ Look how young you were! Memories flooding back." },
			{ text = "Visiting somewhere from childhood", effects = { Happiness = 7 }, setFlags = { nostalgic_visit = true }, feedText = "🕰️ Smaller than you remembered. Bittersweet." },
			{ text = "A smell that triggered memories", effects = { Happiness = 5 }, feedText = "🕰️ That specific smell. Instantly back to that moment." },
		},
	},
	{
		id = "exp_confronting_fear",
		title = "Confronting a Fear",
		emoji = "😰",
		text = "You faced something you've always been afraid of!",
		question = "How did confronting the fear go?",
		minAge = 10, maxAge = 80,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "growth",
		tags = { "fear", "courage", "growth" },
		
		-- CRITICAL: Random fear confrontation outcome
		choices = {
			{
				text = "Face it head on",
				effects = {},
				feedText = "Confronting your fear...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.conquered_fear = true
						state:AddFeed("😰 YOU DID IT! Fear conquered! Empowered!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("😰 Survived it! Still scared but did it!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("😰 Panicked and retreated. Not ready yet.")
					end
				end,
			},
			{
				text = "Avoid it again",
				effects = { Happiness = -2 },
				setFlags = { avoiding_fears = true },
				feedText = "😰 Not today. Maybe not ever.",
			},
		},
	},
	{
		id = "exp_creative_inspiration",
		title = "Creative Inspiration Strike",
		emoji = "💡",
		text = "Creative inspiration hit you out of nowhere!",
		question = "What did you create?",
		minAge = 10, maxAge = 100,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "creativity",
		tags = { "creativity", "inspiration", "art" },
		
		choices = {
			{ text = "Write something meaningful", effects = { Smarts = 4, Happiness = 6 }, setFlags = { creative_writer = true }, feedText = "💡 Words flowed! Created something real and true!" },
			{ text = "Make visual art", effects = { Smarts = 2, Happiness = 6, Looks = 1 }, setFlags = { visual_artist = true }, feedText = "💡 Your vision became reality! Beautiful!" },
			{ text = "Compose/play music", effects = { Smarts = 3, Happiness = 7 }, setFlags = { musical_creator = true }, feedText = "💡 The melody in your head is now real!" },
			{ text = "Build/craft something", effects = { Smarts = 4, Happiness = 5 }, setFlags = { maker = true }, feedText = "💡 Hands created what mind envisioned! Proud!" },
			{ text = "Forget it before you could capture it", effects = { Happiness = -4 }, feedText = "💡 Gone. That amazing idea slipped away. Tragic." },
		},
	},
	{
		id = "exp_question_everything",
		title = "Existential Moment",
		emoji = "🤔",
		text = "Deep questions about life, universe, and everything hit you.",
		question = "How do you handle existential thoughts?",
		minAge = 14, maxAge = 100,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "psychology",
		tags = { "existential", "philosophy", "deep" },
		
		choices = {
			{ text = "Embrace the uncertainty", effects = { Smarts = 5, Happiness = 3 }, setFlags = { philosophically_minded = true }, feedText = "🤔 Not knowing is okay. Wonder is beautiful." },
			{ text = "Spiral into existential dread", effects = { Happiness = -6, Smarts = 2 }, setFlags = { existential_crisis = true }, feedText = "🤔 Nothing matters. Everything matters. Overwhelmed." },
			{ text = "Find comfort in something bigger", effects = { Happiness = 5, Smarts = 1 }, setFlags = { spiritually_curious = true }, feedText = "🤔 Faith, nature, connection - something grounds you." },
			{ text = "Focus on the present moment", effects = { Happiness = 4, Health = 2 }, setFlags = { present_focused = true }, feedText = "🤔 Here and now is all we have. That's enough." },
		},
	},
	{
		id = "exp_overheard_conversation",
		title = "Overheard Conversation",
		emoji = "👂",
		text = "You accidentally overheard something you shouldn't have!",
		question = "What did you hear?",
		minAge = 12, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "overheard", "secret", "awkward" },
		
		choices = {
			{ text = "Someone talking about you", effects = {}, feedText = "Hearing your name...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("👂 They were saying nice things! Unexpected validation!")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("👂 Not kind words. That stings. Can't unhear it.")
					end
				end,
			},
			{ text = "A secret you shouldn't know", effects = { Smarts = 2, Happiness = -2 }, setFlags = { knows_secret = true }, feedText = "👂 Knowledge you can't un-know. Burden of secrets." },
			{ text = "Hilarious strangers' drama", effects = { Happiness = 4 }, feedText = "👂 Better than any reality show. Free entertainment!" },
			{ text = "Something that helped you", effects = { Happiness = 5, Smarts = 2 }, feedText = "👂 Useful information! Accidentally fortunate!" },
		},
	},
	{
		id = "exp_personal_record",
		title = "Personal Record",
		emoji = "🏅",
		text = "You achieved a personal best at something!",
		question = "What record did you break?",
		minAge = 10, maxAge = 90,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "achievement",
		tags = { "achievement", "personal_best", "progress" },
		
		choices = {
			{ text = "Physical fitness milestone", effects = { Happiness = 8, Health = 5 }, setFlags = { fitness_milestone = true }, feedText = "🏅 Faster, stronger, better! Body exceeded expectations!" },
			{ text = "Mental/cognitive achievement", effects = { Happiness = 7, Smarts = 4 }, setFlags = { mental_milestone = true }, feedText = "🏅 Brain power! Problem solved you couldn't before!" },
			{ text = "Social breakthrough", effects = { Happiness = 8 }, setFlags = { social_milestone = true }, feedText = "🏅 Connection you never thought possible! Growth!" },
			{ text = "Financial milestone", effects = { Happiness = 8, Money = 100 }, setFlags = { financial_milestone = true }, feedText = "🏅 Money goals! Saved/earned more than ever!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CONSEQUENTIAL EVENTS - Dynamic events based on PAST player choices
	-- User complaint: "game so boring and shallow, what you do has no impact"
	-- These events reference past decisions and create ripple effects!
	-- ══════════════════════════════════════════════════════════════════════════════
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- FRIEND BETRAYAL CONSEQUENCES
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "conseq_friend_revenge",
		title = "An Old Friend Remembers",
		emoji = "😤",
		text = "Someone you wronged in the past has found a way to get back at you...",
		question = "How do you respond?",
		minAge = 16, maxAge = 80,
		baseChance = 0.6,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "consequence",
		tags = { "consequence", "revenge", "past_actions" },
		-- Only shows if player betrayed a friend
		requiresAnyFlags = { betrayed_friend = true, wronged_friend = true, stole_from_friend = true, bad_friend = true },
		
		choices = {
			{
				text = "Apologize sincerely",
				effects = { Happiness = -3 },
				feedText = "Eating humble pie...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.4 then
						state:ModifyStat("Happiness", 8)
						state.Flags.made_amends = true
						state.Flags.betrayed_friend = nil
						state:AddFeed("😤 They accepted your apology. Friendship might be salvageable.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("😤 They didn't forgive you. The damage is done. They spread rumors.")
					end
				end,
			},
			{
			text = "Deny everything",
			effects = {},
			feedText = "Playing innocent...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.3 then
					state:AddFeed("😤 They couldn't prove it. You got away... for now.")
				else
					state:ModifyStat("Happiness", -8)
					-- CRITICAL FIX: Prevent negative money
					state.Money = math.max(0, (state.Money or 0) - math.random(500, 2000))
					state:AddFeed("😤 Your reputation took a hit! They told everyone what you did.")
				end
			end,
		},
			{
				text = "Make it right financially",
				effects = { Money = -1000 },
				feedText = "Money talks...",
				onResolve = function(state)
					state:ModifyStat("Happiness", 5)
					state.Flags.betrayed_friend = nil
					state:AddFeed("😤 It cost you, but you've made amends. Debt settled.")
				end,
			},
		},
	},
	
	{
		id = "conseq_kindness_returned",
		title = "A Friend Remembers Your Kindness",
		emoji = "🤝",
		text = "Someone you helped in the past wants to return the favor!",
		question = "What kind of help do they offer?",
		minAge = 18, maxAge = 80,
		baseChance = 0.6,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "consequence",
		tags = { "consequence", "reward", "past_actions", "friendship" },
		-- Only shows if player was a good friend
		requiresAnyFlags = { helped_friend = true, good_friend = true, generous = true, supported_friend = true, gave_money_to_friend = true },
		
		choices = {
			{
				text = "They offer financial help",
				effects = {},
				feedText = "Friends help friends...",
				onResolve = function(state)
					local amount = math.random(1000, 5000)
					state.Money = (state.Money or 0) + amount
					state:ModifyStat("Happiness", 10)
					state:AddFeed("🤝 They paid you back and then some! $" .. amount .. " received. Karma is real!")
				end,
			},
			{
				text = "They provide a valuable connection",
				effects = { Smarts = 3 },
				setFlags = { powerful_connection = true },
				feedText = "🤝 They introduced you to someone important. Doors opening!",
			},
			{
				text = "They share an opportunity with you",
				effects = {},
				feedText = "Opportunity knocking...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.5 then
						state.Money = (state.Money or 0) + math.random(2000, 8000)
						state:ModifyStat("Happiness", 12)
						state:AddFeed("🤝 The opportunity paid off! Your kindness has returned tenfold!")
					else
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🤝 Good opportunity! Didn't work out financially but you made a new contact.")
					end
				end,
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRIME HISTORY CONSEQUENCES
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "conseq_criminal_past_haunts",
		title = "Your Past Catches Up",
		emoji = "👮",
		text = "Someone recognized you from your criminal days...",
		question = "What happens?",
		minAge = 21, maxAge = 80,
		baseChance = 0.5,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "consequence",
		tags = { "consequence", "crime", "past_actions" },
		-- Only shows if player has criminal history
		requiresAnyFlags = { has_criminal_record = true, ex_convict = true, committed_crime = true, went_to_prison = true },
		
		choices = {
			{
				text = "It's a former victim",
				effects = {},
				feedText = "Face to face with the past...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.3 then
					state:ModifyStat("Happiness", -10)
					state:ModifyStat("Health", -5)
					state:AddFeed("👮 They attacked you! The confrontation was ugly. You deserved it.")
				elseif roll < 0.6 then
					state:ModifyStat("Happiness", -8)
					state:AddFeed("👮 They called the cops. Old charges reopened. Lawyer fees incoming.")
					-- CRITICAL FIX: Prevent negative money
					state.Money = math.max(0, (state.Money or 0) - math.random(2000, 5000))
				else
					state:ModifyStat("Happiness", 5)
					state:AddFeed("👮 They've forgiven you. A weight lifted from your conscience.")
					state.Flags = state.Flags or {}
					state.Flags.redeemed = true
				end
			end,
			},
			{
				text = "A detective is digging into cold cases",
				effects = { Happiness = -5 },
				feedText = "👮 You're being watched. Old crimes don't always stay buried...",
				setFlags = { being_investigated = true },
			},
			{
				text = "A former accomplice resurfaces",
				effects = {},
				feedText = "Old partner in crime...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.4 then
						state:AddFeed("👮 They want to do 'one more job.' Danger ahead.")
						state.Flags.recruited_for_crime = true
					elseif roll < 0.7 then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("👮 They're threatening to talk unless you pay up. Blackmail.")
						state.Flags.being_blackmailed = true
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("👮 They just wanted to catch up. Going straight now, like you.")
					end
				end,
			},
		},
	},
	
	{
		id = "conseq_escaped_prison_life",
		title = "Life on the Run",
		emoji = "🏃",
		text = "Being an escaped convict is exhausting. Every day is a struggle to stay hidden.",
		question = "How do you handle life as a fugitive?",
		minAge = 18, maxAge = 80,
		baseChance = 0.55, -- CRITICAL FIX: Reduced from 0.8 to prevent spam
		cooldown = 5, -- CRITICAL FIX: Increased to prevent spam
		stage = STAGE,
		ageBand = "any",
		category = "consequence",
		tags = { "consequence", "prison", "escape", "fugitive" },
		-- CRITICAL FIX: Check ANY escape flag variation for compatibility
		requiresAnyFlags = { escaped_prison = true, escaped_prisoner = true, fugitive = true, on_the_run = true },
		blockedByFlags = { in_prison = true, new_identity = true, fled_country = true },
		
		choices = {
			{
				text = "Keep moving - new city",
				effects = { Happiness = -3, Money = -500 },
				feedText = "🏃 Another bus ticket. Another cheap motel. The running never stops.",
			},
			{
				text = "Get fake papers",
				effects = { Money = -2000 },
				feedText = "Buying a new identity...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.6 then
						state:ModifyStat("Happiness", 8)
						state.Flags.new_identity = true
						state:AddFeed("🏃 New identity acquired! You can breathe easier... for now.")
					else
						state:ModifyStat("Happiness", -10)
						state:AddFeed("🏃 The forger was an undercover cop! You've been caught!")
						state.Flags.escaped_prison = nil
						state.Flags.in_prison = true
						state.JailYearsLeft = (state.JailYearsLeft or 0) + 5
					end
				end,
			},
			{
				text = "Turn yourself in",
				effects = { Happiness = -5 },
				feedText = "🏃 The running is over. You're going back to face the music.",
				onResolve = function(state)
					state.Flags.escaped_prison = nil
					state.Flags.in_prison = true
					state.JailYearsLeft = (state.JailYearsLeft or 0) + 2
					state:AddFeed("🏃 Surrendered to authorities. Extra time added for the escape.")
				end,
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CAREER DECISION CONSEQUENCES
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "conseq_quit_dramatically",
		title = "Your Old Boss Remembers",
		emoji = "😠",
		text = "That dramatic exit from your last job? It's coming back to haunt you.",
		question = "What's the fallout?",
		minAge = 21, maxAge = 65,
		baseChance = 0.55,
		cooldown = 4,
		stage = STAGE,
		ageBand = "adult",
		category = "consequence",
		tags = { "consequence", "career", "past_actions" },
		-- Only shows if player quit badly
		requiresAnyFlags = { quit_dramatically = true, burned_bridges = true, bad_exit = true },
		
		choices = {
			{
				text = "Bad reference costs you a new job",
				effects = { Happiness = -10 },
				feedText = "😠 They told your new potential employer EVERYTHING. Offer rescinded.",
			},
			{
				text = "You run into your old boss",
				effects = {},
				feedText = "Face to face again...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.5 then
						state:ModifyStat("Happiness", -8)
						state:AddFeed("😠 Awkward! They made a scene. Embarrassing confrontation.")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("😠 They've moved on. Nodded politely. Water under the bridge?")
						state.Flags.burned_bridges = nil
					end
				end,
			},
			{
				text = "Industry blacklist",
				effects = { Happiness = -15 },
				feedText = "😠 Word got around. You're unofficially blacklisted in the industry.",
				setFlags = { industry_blacklist = true },
			},
		},
	},
	
	{
		id = "conseq_mentor_success",
		title = "Your Protégé Thrives",
		emoji = "🌟",
		text = "That person you mentored at work? They're now incredibly successful and remember you!",
		question = "How does this help you?",
		minAge = 30, maxAge = 80,
		baseChance = 0.5,
		cooldown = 5,
		oneTime = true,
		stage = STAGE,
		ageBand = "adult",
		category = "consequence",
		tags = { "consequence", "career", "past_actions", "mentor" },
		-- Only shows if player mentored someone
		requiresAnyFlags = { mentored_someone = true, was_mentor = true, trained_successor = true },
		
		choices = {
			{
				text = "They offer you a position",
				effects = {},
				feedText = "Student becomes the master...",
				onResolve = function(state)
					state:ModifyStat("Happiness", 15)
					state.Money = (state.Money or 0) + 10000
					state:AddFeed("🌟 They offered you a senior role at their company! Signing bonus included!")
					state.Flags.great_job_offer = true
				end,
			},
			{
				text = "They invest in your venture",
				effects = { Money = 50000 },
				feedText = "🌟 They believed in you! $50,000 investment to help you start something!",
			},
			{
				text = "They publicly credit you",
				effects = { Happiness = 12 },
				setFlags = { industry_respect = true, famous_mentor = true },
				feedText = "🌟 In interviews, they always mention you. Your reputation soars!",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- RELATIONSHIP CONSEQUENCES
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "conseq_ex_encounter",
		title = "Blast From the Past",
		emoji = "💔",
		text = "You ran into your ex. The one who got away... or the one you ran from?",
		question = "How does it go?",
		minAge = 20, maxAge = 70,
		baseChance = 0.5,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "consequence",
		tags = { "consequence", "romance", "past_actions" },
		-- Only shows if player had a breakup
		requiresAnyFlags = { has_ex = true, divorced = true, broke_someones_heart = true, was_heartbroken = true },
		
		choices = {
			{
				text = "They're doing better than you",
				effects = { Happiness = -8 },
				feedText = "💔 They look amazing. Happy. Successful. Without you. Ouch.",
			},
			{
				text = "Closure at last",
				effects = { Happiness = 8 },
				feedText = "💔 A mature conversation. Both of you have grown. Healing complete.",
				onResolve = function(state)
					state.Flags.has_closure = true
					state.Flags.heartbreak = nil
				end,
			},
			{
				text = "Old feelings resurface",
				effects = { Happiness = -3 },
				feedText = "💔 Your heart flutters. Your mind races. Do you still...? Complicated.",
				setFlags = { unresolved_feelings = true },
			},
			{
				text = "They want you back",
				effects = {},
				feedText = "Second chances...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.5 then
						state:ModifyStat("Happiness", 12)
						state:AddFeed("💔 You reunited! Maybe this time it'll work...")
						state.Flags.reconciled_with_ex = true
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("💔 You politely declined. That chapter is closed. It felt good to be wanted though.")
					end
				end,
			},
		},
	},
	
	{
		id = "conseq_cheating_exposed",
		title = "Your Secret is Out",
		emoji = "💣",
		text = "That affair you thought no one knew about? Someone found out...",
		question = "What happens now?",
		minAge = 21, maxAge = 70,
		baseChance = 0.7,
		cooldown = 5,
		oneTime = true,
		stage = STAGE,
		ageBand = "adult",
		category = "consequence",
		tags = { "consequence", "romance", "past_actions", "cheating" },
		-- CRITICAL FIX: Check for ANY cheating flag - affair, cheater, emotional_affair
		requiresAnyFlags = { cheater = true, affair = true, emotional_affair = true },
		blockedByFlags = { affair_exposed = true, in_prison = true },
		
		choices = {
			{
				text = "Your partner confronts you",
				effects = { Happiness = -15 },
				setFlags = { affair_exposed = true },
				feedText = "💣 The trust is shattered. Your relationship may not survive this.",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.6 then
						state:AddFeed("💣 They left you. The affair cost you your marriage.")
						state.Flags.divorced = true
						state.Flags.married = nil
					else
						state:AddFeed("💣 They're devastated but want to try counseling. Trust will take years to rebuild.")
						state.Flags.in_couples_therapy = true
					end
				end,
			},
			{
				text = "The other person's partner finds out",
				effects = { Happiness = -10 },
				setFlags = { affair_exposed = true },
				feedText = "💣 They showed up at your door. Scene was made. Everyone knows now.",
			},
			{
				text = "Blackmail attempt",
				effects = { Happiness = -8 },
				feedText = "💣 Someone knows and wants money to stay quiet. Pay or be exposed?",
				setFlags = { being_blackmailed = true },
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- GENERAL KARMA EVENTS
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "conseq_good_karma",
		title = "The Universe Pays Back",
		emoji = "✨",
		text = "Something wonderful happened to you out of nowhere!",
		question = "What stroke of luck?",
		minAge = 16, maxAge = 100,
		baseChance = 0.5,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "consequence",
		tags = { "consequence", "karma", "luck", "reward" },
		-- Only shows if player has been generally good
		requiresAnyFlags = { good_person = true, charitable = true, helped_stranger = true, volunteer = true, kind_soul = true },
		blockedByFlags = { evil = true, cruel = true },
		
		choices = {
			{
				text = "Anonymous gift",
				effects = {},
				feedText = "Mysterious benefactor...",
				onResolve = function(state)
					local amount = math.random(1000, 10000)
					state.Money = (state.Money or 0) + amount
					state:ModifyStat("Happiness", 15)
					state:AddFeed("✨ A check arrived in the mail! $" .. amount .. "! No return address. Just 'Thank you'.")
				end,
			},
			{
				text = "Perfect timing",
				effects = { Happiness = 10 },
				feedText = "✨ You were in exactly the right place at the right time. Life just worked out perfectly today.",
			},
			{
				text = "Dream opportunity",
				effects = { Happiness = 12 },
				setFlags = { lucky_break = true },
				feedText = "✨ The opportunity you'd been waiting for just fell into your lap! Stars aligned!",
			},
		},
	},
	
	{
		id = "conseq_bad_karma",
		title = "The Universe Remembers",
		emoji = "⚡",
		text = "Bad luck keeps finding you. Almost like... karma?",
		question = "What goes wrong?",
		minAge = 16, maxAge = 100,
		baseChance = 0.5,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "consequence",
		tags = { "consequence", "karma", "bad_luck" },
		-- Only shows if player has been generally bad
		requiresAnyFlags = { cruel = true, selfish = true, mean = true, hurt_innocent = true, evil = true },
		blockedByFlags = { good_person = true, redeemed = true },
		
		choices = {
			{
				text = "Everything breaks down",
				effects = { Happiness = -8, Money = -500 },
				feedText = "⚡ Car troubles, phone died, lost wallet. All in the same day. The universe is sending a message.",
			},
			{
				text = "Public humiliation",
				effects = { Happiness = -10 },
				feedText = "⚡ Something embarrassing happened in front of everyone. People are talking.",
			},
		{
			text = "Lost something valuable",
			effects = { Happiness = -8 },
			feedText = "⚡ Something important to you is just... gone. Can't find it anywhere.",
			onResolve = function(state)
				-- CRITICAL FIX: Prevent negative money
				state.Money = math.max(0, (state.Money or 0) - math.random(200, 1000))
				state:AddFeed("⚡ Had to replace it. Expensive and frustrating.")
			end,
		},
		},
	},
	
{
	id = "conseq_reputation_precedes",
	title = "Your Reputation Precedes You",
	emoji = "📢",
	text = "Everywhere you go, people seem to already know about you...",
	question = "What have they heard?",
	minAge = 21, maxAge = 80,
	baseChance = 0.45,
	cooldown = 3,
	stage = STAGE,
	ageBand = "adult",
	category = "consequence",
	tags = { "consequence", "reputation", "past_actions" },
	-- CRITICAL FIX: Event should only appear if player has SOME reputation!
	eligibility = function(state)
		local flags = state.Flags or {}
		local hasReputation = flags.rags_to_riches or flags.self_made or flags.successful_entrepreneur
			or flags.charitable or flags.philanthropist or flags.generous
			or flags.has_criminal_record or flags.scandal or flags.controversial
			or flags.industry_expert or flags.accomplished or flags.promoted_multiple_times
			or flags.famous or flags.celebrity or flags.well_known
		if not hasReputation then
			return false, "No notable reputation yet"
		end
		return true
	end,
	
	choices = {
		{
			text = "Your success story",
			effects = { Happiness = 10 },
			feedText = "📢 They've heard how you climbed from nothing. Inspiration!",
			eligibility = function(state)
				if not (state.Flags and (state.Flags.rags_to_riches or state.Flags.self_made or state.Flags.successful_entrepreneur)) then
					return false, "You don't have a success story to share yet"
				end
				return true
			end,
		},
		{
			text = "Your generous acts",
			effects = { Happiness = 8 },
			feedText = "📢 Word of your charity work has spread. People thank you!",
			eligibility = function(state)
				if not (state.Flags and (state.Flags.charitable or state.Flags.philanthropist or state.Flags.generous)) then
					return false, "You haven't been notably generous yet"
				end
				return true
			end,
		},
		{
			text = "Your dark past",
			effects = { Happiness = -8 },
			feedText = "📢 They know what you did. The whispers follow you everywhere.",
			eligibility = function(state)
				if not (state.Flags and (state.Flags.has_criminal_record or state.Flags.scandal or state.Flags.controversial)) then
					return false, "You don't have a dark past to speak of"
				end
				return true
			end,
		},
		{
			text = "Your professional expertise",
			effects = { Happiness = 6, Smarts = 2 },
			feedText = "📢 You're known as an expert in your field. Respect!",
			eligibility = function(state)
				if not (state.Flags and (state.Flags.industry_expert or state.Flags.accomplished or state.Flags.promoted_multiple_times)) then
					return false, "You haven't established professional expertise yet"
				end
				return true
			end,
		},
		{
			-- CRITICAL FIX: Default option so event is always completable!
			text = "Just general awareness",
			effects = { Happiness = 3 },
			feedText = "📢 People recognize your face but can't quite place you. Mild fame!",
		},
	},
},

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: MORE CONSEQUENCE EVENTS FOR BETTER WIRING
	-- These events make past actions matter and improve replayability
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "conseq_old_promise_remembered",
		title = "A Promise You Made",
		emoji = "🤝",
		text = "Years ago, you made a promise to someone. They've come to collect.",
		question = "What did you promise?",
		minAge = 20, maxAge = 70,
		baseChance = 0.3,
		cooldown = 10,
		oneTime = true,
		category = "consequence",
		tags = { "consequence", "promise", "past_actions" },
		requiresAnyFlags = { made_important_promise = true, promised_friend_letters = true, promised_to_help = true },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "To help them when they needed it",
				effects = {},
				feedText = "Now they need help...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.5 then
						state.Money = math.max(0, (state.Money or 0) - 2000)
						state:ModifyStat("Happiness", 10)
						state.Flags.kept_promise = true
						state:AddFeed("🤝 You helped them like you promised. They'll never forget your loyalty!")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags.broke_promise = true
						state:AddFeed("🤝 You couldn't help. They understand, but the friendship is strained.")
					end
				end,
			},
			{
				text = "To be at their wedding",
				effects = { Happiness = 8 },
				setFlags = { attended_friend_wedding = true },
				feedText = "🤝 You made it to their wedding! They cried when they saw you there.",
			},
			{
				text = "To never forget them",
				effects = { Happiness = 5 },
				feedText = "Reconnecting after years apart...",
				onResolve = function(state)
					state:ModifyStat("Happiness", 8)
					state.Flags = state.Flags or {}
					state.Flags.reconnected_old_friend = true
					state:AddFeed("🤝 After all these years, they tracked you down. The friendship reignites!")
				end,
			},
		},
	},
	{
		id = "conseq_childhood_bully_reunion",
		title = "The Bully Returns",
		emoji = "😬",
		text = "You ran into your childhood bully after all these years...",
		question = "How do you handle this?",
		minAge = 25, maxAge = 60,
		baseChance = 0.2,
		cooldown = 15,
		oneTime = true,
		category = "consequence",
		tags = { "consequence", "childhood", "confrontation" },
		requiresAnyFlags = { was_bullied = true, had_bully = true, bully_victim = true },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "Confront them about the past",
				effects = {},
				feedText = "Time to face this...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.4 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.bully_apologized = true
						state:AddFeed("😬 They apologized! Said they were dealing with stuff at home. Closure feels good.")
					elseif roll < 0.7 then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("😬 They don't even remember you. Somehow that's worse.")
					else
						state:ModifyStat("Happiness", 8)
						state:AddFeed("😬 They're a total mess now. You've clearly won at life.")
					end
				end,
			},
			{
				text = "Take the high road",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { took_high_road = true },
				feedText = "😬 You smiled and moved on. You're better than them anyway.",
			},
			{
				text = "Walk away - not worth your energy",
				effects = { Happiness = 3 },
				feedText = "😬 You pretended not to see them. Some battles aren't worth fighting.",
			},
		},
	},
	{
		id = "conseq_reckless_driving_consequences",
		title = "Your Driving Catches Up",
		emoji = "🚗",
		text = "Your reckless driving habits have finally caught up to you...",
		question = "What happened?",
		minAge = 18, maxAge = 70,
		baseChance = 0.4,
		cooldown = 8,
		oneTime = true,
		category = "consequence",
		tags = { "consequence", "driving", "reckless" },
		requiresAnyFlags = { reckless_driver = true, speeding_tickets_incoming = true, bad_driver = true },
		blockedByFlags = { in_prison = true, good_driver = true },
		
		choices = {
			{
				text = "Major accident (your fault)",
				effects = { Health = -20, Happiness = -15, Money = -5000 },
				setFlags = { caused_accident = true, learned_lesson_driving = true },
				feedText = "🚗 You caused a serious accident. Hospital bills and guilt forever.",
			},
			{
				text = "License suspended",
				effects = { Happiness = -10 },
				setFlags = { license_suspended = true },
				feedText = "🚗 Too many points. No driving for 6 months. Life just got harder.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.has_license = nil -- Temporarily lose license
					state.Flags.drivers_license = nil
				end,
			},
			{
				text = "Close call that scared you straight",
				effects = { Happiness = -5, Smarts = 3 },
				setFlags = { scared_straight = true, safe_driver = true },
				feedText = "🚗 Almost killed someone. Never driving recklessly again.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.reckless_driver = nil -- No longer reckless
				end,
			},
		},
	},
	{
		id = "conseq_academic_achievement_payoff",
		title = "Your Studies Paid Off!",
		emoji = "🎓",
		text = "All those years of hard work in school? They're paying dividends!",
		question = "What opportunity arose?",
		minAge = 22, maxAge = 45,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		category = "consequence",
		tags = { "consequence", "education", "reward" },
		requiresAnyFlags = { honors_graduate = true, academic_achiever = true, valedictorian = true, straight_A_student = true },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "Recruited for dream job",
				effects = { Happiness = 20 },
				setFlags = { dream_job_offer = true },
				feedText = "🎓 Your academic record caught their attention. Dream company wants YOU!",
				onResolve = function(state)
					state.Money = (state.Money or 0) + 10000 -- Signing bonus
					state:AddFeed("🎓 $10,000 signing bonus! Hard work finally paying off!")
				end,
			},
			{
				text = "Scholarship for grad school",
				effects = { Happiness = 15, Smarts = 5 },
				setFlags = { grad_school_scholarship = true },
				feedText = "🎓 Full ride to graduate school! Your future is bright!",
			},
			{
				text = "Mentorship from industry leader",
				effects = { Happiness = 12, Smarts = 3 },
				setFlags = { has_powerful_mentor = true },
				feedText = "🎓 A CEO saw your thesis. They want to mentor you personally!",
			},
		},
	},
	{
		id = "conseq_athletic_past_benefits",
		title = "Your Athletic Past",
		emoji = "💪",
		text = "Those years of sports are still benefiting you!",
		question = "How does your athletic background help?",
		minAge = 25, maxAge = 60,
		baseChance = 0.3,
		cooldown = 12,
		oneTime = true,
		category = "consequence",
		tags = { "consequence", "sports", "health" },
		requiresAnyFlags = { athletic = true, sports_champion = true, varsity_athlete = true, sports_star = true },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "Health advantage in later life",
				effects = { Health = 15, Happiness = 10 },
				feedText = "💪 Your body remembers those years of training. You're healthier than most your age!",
			},
			{
				text = "Networking with old teammates",
				effects = { Happiness = 8 },
				setFlags = { valuable_network = true },
				feedText = "💪 Old teammate is now a CEO. You've got an 'in' at their company!",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.5 then
						state.Money = (state.Money or 0) + 5000
						state:AddFeed("💪 They helped you land a great opportunity! +$5,000!")
					end
				end,
			},
			{
				text = "Coaching the next generation",
				effects = { Happiness = 12, Smarts = 2 },
				setFlags = { youth_coach = true, giving_back = true },
				feedText = "💪 You're coaching kids now. Passing on what you learned feels amazing!",
			},
		},
	},
	{
		id = "conseq_artistic_talent_recognized",
		title = "Your Art Gets Noticed",
		emoji = "🎨",
		text = "That creative hobby you've nurtured? Someone important saw it!",
		question = "What opportunity appeared?",
		minAge = 18, maxAge = 65,
		baseChance = 0.25,
		cooldown = 12,
		oneTime = true,
		category = "consequence",
		tags = { "consequence", "art", "creative", "opportunity" },
		requiresAnyFlags = { artistic = true, creative = true, talented_artist = true, musician = true, musical_talent = true },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "Gallery wants to feature your work",
				effects = { Happiness = 18, Looks = 3 },
				setFlags = { gallery_featured = true },
				feedText = "🎨 Your first gallery showing! People are buying your work!",
				onResolve = function(state)
					local earnings = math.random(2000, 8000)
					state.Money = (state.Money or 0) + earnings
					state:AddFeed(string.format("🎨 Sold several pieces! +$%d!", earnings))
				end,
			},
			{
				text = "Hired for creative project",
				effects = { Happiness = 15 },
				setFlags = { professional_artist = true },
				feedText = "🎨 A company wants to pay you for your art! Dream come true!",
				onResolve = function(state)
					state.Money = (state.Money or 0) + 5000
				end,
			},
			{
				text = "Teaching workshops",
				effects = { Happiness = 10, Money = 1000 },
				setFlags = { art_teacher = true },
				feedText = "🎨 People want to learn from YOU! Teaching workshops on the side!",
			},
		},
	},
}

return LifeExperiences
