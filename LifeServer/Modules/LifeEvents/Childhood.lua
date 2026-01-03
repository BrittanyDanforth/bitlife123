--[[
    Childhood Events (Ages 0-12)
    Formative moments that shape personality and hint at future paths

    Integrated with:
    - core milestone tracking via `isMilestone` + milestoneKey
    - career catalog via `hintCareer` on choices + event-level careerTags
    - soft tagging via `stage`, `ageBand`, `category`, `tags`
]]

-- CRITICAL FIX #CHILDHOOD-1: Add RANDOM definition for consistent random number generation
local RANDOM = Random.new()

local Childhood = {}

local STAGE = "childhood"

Childhood.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- BABY & TODDLER (Ages 0-4)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "first_words",
		title = "First Words",
		emoji = "👶",
		-- ══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #7: Text variations for replayability!
		-- Each life should feel different, not the same scripted experience
		-- ══════════════════════════════════════════════════════════════════════════════
		textVariants = {
			"Your parents are excited - you just spoke your first word!",
			"A magical moment! Everyone gasps as you speak for the first time!",
			"Your parents have been waiting for this... your first word!",
			"The whole family gathers as you attempt to speak your first word!",
			"Your mom grabs her phone to record - you're about to say your first word!",
			"Everyone goes quiet... did you just say something?!",
		},
		text = "Your parents are excited - you just spoke your first word!",
		question = "What did you say?",
		minAge = 1, maxAge = 2,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		-- NEW META
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "development",
		milestoneKey = "CHILD_FIRST_WORDS",
		tags = { "core", "family", "speech", "early_years" },
		careerTags = { "veterinary" },

		choices = {
			{ text = '"Mama"', effects = { Happiness = 5 }, setFlags = { first_word = "mama" }, feedText = "You said your first word: 'Mama'. Your mother was overjoyed." },
			{ text = '"Dada"', effects = { Happiness = 5 }, setFlags = { first_word = "dada" }, feedText = "You said your first word: 'Dada'. Your father beamed with pride." },
			{ text = '"No!"', effects = { Happiness = 3 }, setFlags = { first_word = "no", rebellious_streak = true }, feedText = "Your first word was 'No!' - already showing your independent spirit." },
			{ text = "An attempt at the dog's name", effects = { Happiness = 4 }, setFlags = { first_word = "pet", animal_lover = true }, hintCareer = "veterinary", feedText = "You tried to say the dog's name. Pets already have your heart." },
		},
	},

	{
		id = "first_steps",
		title = "First Steps",
		emoji = "🚶",
		-- CRITICAL FIX #8: Text variations for different first steps experiences!
		textVariants = {
			"You're standing up and ready to take your first steps!",
			"You grab onto the coffee table and pull yourself up... here we go!",
			"Your parents hold their breath as you wobble on your tiny legs!",
			"This is it! You're going to walk for the first time!",
			"The living room becomes your runway. Time to walk!",
			"Everyone watches as you let go of the couch and stand alone!",
		},
		text = "You're standing up and ready to take your first steps!",
		question = "How do you approach this challenge?",
		minAge = 1, maxAge = 2,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		-- META
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "development",
		milestoneKey = "CHILD_FIRST_STEPS",
		tags = { "core", "mobility", "early_years" },

		choices = {
			{ text = "Carefully and cautiously", effects = { Smarts = 2 }, setFlags = { cautious_personality = true }, feedText = "You took careful, measured first steps. Safety first!" },
			{ text = "Boldly charge forward", effects = { Health = -2, Happiness = 5 }, setFlags = { adventurous_spirit = true }, feedText = "You ran before you could walk - and took a tumble. But you got right back up!" },
			{ text = "Wait for encouragement", effects = { Happiness = 3 }, setFlags = { seeks_approval = true }, feedText = "With your parents cheering, you walked right into their arms." },
		},
	},

	{
		id = "toddler_tantrum_store",
		title = "The Terrible Twos",
		emoji = "😤",
		-- CRITICAL FIX #9: Text variations for tantrum scenarios!
		textVariants = {
			"You want a toy at the store, but your parents said no.",
			"You spot the PERFECT toy, but mom shakes her head. No.",
			"That shiny new toy is calling your name, but dad says 'Not today.'",
			"You're at the checkout and see the candy. Your parents say no.",
			"The toy aisle is torture. You NEED that action figure, but it's a no.",
			"Your parents are trying to leave the store, but you've spotted something...",
		},
	text = "You want a toy at the store, but your parents said no.",
	question = "What do you do?",
	minAge = 2, maxAge = 3,
	baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.8 to prevent spam
	cooldown = 5, -- CRITICAL FIX: Increased to prevent spam

		-- META
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "behavior",
		tags = { "family", "store", "impulse_control" },
		careerTags = { "law" },

		choices = {
			{ text = "Throw a massive tantrum", effects = { Happiness = -5 }, setFlags = { throws_tantrums = true }, feedText = "You threw an epic tantrum. Your parents were mortified." },
			{ text = "Pout but accept it", effects = { Happiness = -2, Smarts = 1 }, setFlags = { learns_patience = true }, feedText = "You pouted, but learned that tantrums don't always work." },
			{ text = "Try to negotiate", effects = { Smarts = 3 }, setFlags = { natural_negotiator = true }, hintCareer = "law", feedText = "Even at age 2, you tried to make a deal. Future lawyer?" },
			{ text = "Get distracted by something else", effects = { Happiness = 2 }, feedText = "A shiny object caught your eye. Crisis averted." },
		},
	},

	{
		id = "preschool_start",
		title = "First Day of Preschool",
		emoji = "🎒",
		-- CRITICAL FIX #10: Text variations for preschool experience!
		textVariants = {
			"It's your first day of preschool! Your parents drop you off at the colorful building.",
			"The big day has arrived! Preschool awaits with its finger-paints and nap time.",
			"Your new backpack is ready. Time for your first day of preschool!",
			"The preschool door opens and you see dozens of other tiny humans. Here we go!",
			"Mom gives you one last kiss as she drops you off for your first day of school!",
			"Preschool! A whole new world of crayons, snacks, and playground time awaits!",
		},
		text = "It's your first day of preschool! Your parents drop you off at the colorful building.",
		question = "How do you handle being away from home?",
		minAge = 3, maxAge = 4,
		oneTime = true,
		priority = "high",

		-- META
		stage = STAGE,
		ageBand = "early_childhood",
		category = "school",
		milestoneKey = "CHILD_PRESCHOOL_START",
		tags = { "school", "separation", "social" },

		choices = {
			{ text = "Cry and cling to mom/dad", effects = { Happiness = -5 }, feedText = "The first day was rough. Lots of tears, but you survived." },
			{ text = "March in confidently", effects = { Happiness = 5, Smarts = 2 }, setFlags = { socially_confident = true }, feedText = "You walked in like you owned the place. New friends incoming!" },
			{ text = "Quietly observe the other kids", effects = { Smarts = 3 }, setFlags = { observant = true }, hintCareer = "science", feedText = "You watched everything carefully. An analytical mind is forming." },
			{ text = "Immediately find the art supplies", effects = { Happiness = 5, Looks = 1 }, setFlags = { artistic_interest = true }, hintCareer = "creative", feedText = "You made a beeline for the crayons. A creative soul!" },
		},
	},

	{
		id = "imaginary_friend",
		title = "Imaginary Friend",
		emoji = "👻",
		text = "You've been spending a lot of time talking to your 'invisible friend.'",
		question = "Who is your imaginary friend?",
		minAge = 3, maxAge = 5,
		oneTime = true,
		baseChance = 0.6,

		-- META
		stage = STAGE,
		ageBand = "early_childhood",
		category = "psychology",
		tags = { "imagination", "social", "coping" },
		careerTags = { "creative", "veterinary" },

		choices = {
			{ text = "A brave superhero", effects = { Happiness = 5 }, setFlags = { hero_complex = true }, feedText = "Your imaginary superhero friend makes you feel invincible." },
			{ text = "A wise wizard", effects = { Smarts = 3 }, setFlags = { loves_fantasy = true }, hintCareer = "creative", feedText = "Your wizard friend teaches you 'magic' - really just creative problem solving." },
			{ text = "A friendly animal", effects = { Happiness = 3 }, setFlags = { animal_lover = true }, hintCareer = "veterinary", feedText = "Your animal friend understands you like no human does." },
			{ text = "I don't need imaginary friends", effects = { Smarts = 2 }, setFlags = { pragmatic = true }, feedText = "You prefer real friends. Very practical for your age." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- EARLY CHILDHOOD (Ages 5-8)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "stage_transition_child",
		title = "Starting Elementary School",
		emoji = "🏫",
		text = "You're starting elementary school! This is a big step into the wider world.",
		question = "What are you most excited about?",
		minAge = 5, maxAge = 5,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		-- META
		stage = STAGE,
		ageBand = "early_childhood",
		category = "school",
		milestoneKey = "CHILD_ELEMENTARY_START",
		tags = { "core", "school", "transition" },
		careerTags = { "education", "sports", "creative" },

		choices = {
			{ text = "Making new friends", effects = { Happiness = 5 }, setFlags = { social_focus = true }, feedText = "You're ready to meet tons of new friends!" },
			{ text = "Learning to read", effects = { Smarts = 5 }, setFlags = { academic_focus = true }, hintCareer = "education", feedText = "Books are about to become your best friends." },
			{ text = "Recess and sports", effects = { Health = 3, Happiness = 3 }, setFlags = { athletic_focus = true }, hintCareer = "sports", feedText = "You can't wait to run around the playground!" },
			{ text = "Art class", effects = { Happiness = 4, Looks = 2 }, setFlags = { artistic_focus = true }, hintCareer = "creative", feedText = "You're excited to express yourself creatively." },
		},
	},

	{
		id = "first_best_friend",
		title = "A New Best Friend",
		emoji = "🤝",
		text = "You've been hanging out with a kid from class a lot. They might become your best friend!",
		question = "What do you two do together?",
		minAge = 5, maxAge = 8,
		oneTime = true,

		-- META
		stage = STAGE,
		ageBand = "early_childhood",
		category = "relationships",
		tags = { "friends", "school", "social" },
		careerTags = { "tech", "sports", "science" },

		choices = {
			{ text = "Play imaginative games", effects = { Happiness = 5, Smarts = 2 }, setFlags = { creative_play = true, has_best_friend = true }, feedText = "You and your new best friend create entire worlds together." },
			{ text = "Build things with blocks/Legos", effects = { Smarts = 5, Happiness = 3 }, setFlags = { builder = true, has_best_friend = true }, hintCareer = "tech", feedText = "You're a building team! Engineering minds in the making." },
			{ text = "Play sports outside", effects = { Health = 5, Happiness = 3 }, setFlags = { sporty = true, has_best_friend = true }, hintCareer = "sports", feedText = "You and your friend are always running around outside." },
			{ text = "Read and explore together", effects = { Smarts = 5 }, setFlags = { curious = true, has_best_friend = true }, hintCareer = "science", feedText = "You're partners in curiosity, always discovering new things." },
		},
	},

	{
		id = "losing_tooth",
		title = "First Lost Tooth",
		emoji = "🦷",
		text = "Your first baby tooth fell out!",
		question = "What do you do with it?",
		minAge = 5, maxAge = 7,
		oneTime = true,
		isMilestone = true,

		-- META
		stage = STAGE,
		ageBand = "early_childhood",
		category = "development",
		milestoneKey = "CHILD_FIRST_TOOTH_LOST",
		tags = { "body_change", "family", "money_small" },

		choices = {
			{ text = "Put it under my pillow for the tooth fairy", effects = { Happiness = 5, Money = 5 }, feedText = "The tooth fairy left you some money!" },
			{ text = "Keep it in a special box", effects = { Happiness = 3 }, setFlags = { sentimental = true }, feedText = "You're saving your teeth for some reason." },
			{ text = "Show it off to everyone", effects = { Happiness = 5, Looks = 1 }, feedText = "You proudly showed off your gap-toothed smile!" },
		},
	},

	{
		id = "learned_bike",
		title = "Learning to Ride a Bike",
		emoji = "🚲",
		text = "You're learning to ride a bike! Your parent is holding the back.",
		question = "How do you approach this?",
		minAge = 5, maxAge = 8,
		oneTime = true,
		isMilestone = true,

		-- META
		stage = STAGE,
		ageBand = "early_childhood",
		category = "skills",
		milestoneKey = "CHILD_LEARNED_BIKE",
		tags = { "mobility", "outdoors", "independence" },
		-- CRITICAL FIX: Random outcome based on approach + stats
		choices = {
			{
				text = "Pedal confidently!",
				effects = {},
				feedText = "You pushed forward with confidence...",
				onResolve = function(state)
					-- CRITICAL FIX: Added nil checks for all method calls
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					local successChance = 0.40 + (health / 150)
					if roll < successChance then
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						if state.ModifyStat then state:ModifyStat("Health", 3) end
						state.Flags = state.Flags or {}
						state.Flags.natural_athlete = true
						if state.AddFeed then state:AddFeed("🚲 You're a natural! Freedom on two wheels!") end
					elseif roll < successChance + 0.35 then
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.ModifyStat then state:ModifyStat("Health", -2) end
						state.Flags = state.Flags or {}
						state.Flags.persistent = true
						if state.AddFeed then state:AddFeed("🚲 You fell a few times, but kept trying. You did it!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 2) end
						if state.ModifyStat then state:ModifyStat("Health", -4) end
						if state.AddFeed then state:AddFeed("🚲 Lots of falls... but you'll get it eventually!") end
					end
				end,
			},
			{
				text = "Go slow and careful",
				effects = {},
				feedText = "You took a cautious approach...",
				onResolve = function(state)
					-- CRITICAL FIX: Added nil checks for all method calls
					local roll = math.random()
					if roll < 0.60 then
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						state.Flags = state.Flags or {}
						state.Flags.cautious_learner = true
						if state.AddFeed then state:AddFeed("🚲 Taking your time paid off! You learned safely.") end
					elseif roll < 0.85 then
						if state.ModifyStat then state:ModifyStat("Happiness", 3) end
						if state.AddFeed then state:AddFeed("🚲 Training wheels for a while, but you got there!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("🚲 Still too scared... maybe try again next year.") end
					end
				end,
			},
			{
				text = "I don't want to learn",
				effects = { Happiness = -3 },
				setFlags = { bike_phobia = true },
				feedText = "Bikes aren't for everyone... yet.",
			},
		},
	},

	{
		id = "school_bully",
		title = "Trouble on the Playground",
		emoji = "😠",
		text = "An older kid at school has been picking on you and other kids.",
		question = "How do you handle this?",
		minAge = 6, maxAge = 10,
		baseChance = 0.45, -- CRITICAL FIX: Reduced from 0.6 to prevent spam
		cooldown = 5, -- CRITICAL FIX: Increased from 3
		-- CRITICAL FIX: Add blockedByFlags to prevent random popups
		blockedByFlags = { 
			in_prison = true, 
			dropped_out = true,
			dealt_with_bully = true,  -- Prevent repeat if already dealt with
		},

		-- META
		stage = STAGE,
		ageBand = "early_childhood",
		category = "relationships",
		tags = { "conflict", "school", "bullying" },
		careerTags = { "social_work" },

		choices = {
			{ 
				text = "👊 FIGHT the bully!",
				effects = {},
				feedText = "You decided to fight back...",
				-- CRITICAL FIX: Fight minigame for childhood bully confrontation!
				triggerMinigame = "fight",
				minigameOptions = { difficulty = "easy" },
				onResolve = function(state, minigameResult)
					local won = minigameResult and (minigameResult.success or minigameResult.won)
					state.Flags = state.Flags or {}
					
					if won then
						-- Beat the bully!
						state.Flags.brave = true
						state.Flags.fighter = true
						state:ModifyStat("Happiness", 10)
						state:AddFeed("👊 You WON the fight! The bully never bothered anyone again. You're a HERO!")
					else
						-- Lost the fight
						state.Flags.brave = true
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Health", -5)
						state:AddFeed("👊 You lost the fight, but you were brave for trying. The bully respects you now.")
					end
				end,
			},
		{ text = "Stand up verbally", effects = { Happiness = 5 }, setFlags = { brave = true, dealt_with_bully = true }, feedText = "You stood up to the bully with words. It was scary, but you earned respect." },
		{ text = "Tell a teacher", effects = { Happiness = 2, Smarts = 2 }, setFlags = { trusts_authority = true, dealt_with_bully = true }, feedText = "You told an adult. The bully got in trouble." },
		{ text = "Try to befriend them", effects = { Smarts = 3 }, setFlags = { peacemaker = true, dealt_with_bully = true }, hintCareer = "social_work", feedText = "You tried to understand why they're mean. Sometimes kindness works." },
		},
	},

	{
		id = "class_pet",
		title = "Classroom Pet",
		emoji = "🐹",
		text = "Your classroom got a new pet hamster! The teacher needs someone to care for it.",
		question = "Do you volunteer?",
		minAge = 6, maxAge = 9,
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.7
		cooldown = 5, -- CRITICAL FIX: Increased to prevent spam
		blockedByFlags = { class_pet_done = true }, -- CRITICAL FIX: Prevent repeat

		-- META
		stage = STAGE,
		ageBand = "early_childhood",
		category = "responsibility",
		tags = { "animals", "school", "responsibility" },
		careerTags = { "veterinary" },

		choices = {
			{ text = "Eagerly volunteer", effects = { Happiness = 5 }, setFlags = { responsible = true, animal_lover = true }, hintCareer = "veterinary", feedText = "You became the official hamster caretaker. Such responsibility!" },
			{ text = "Help out sometimes", effects = { Happiness = 3 }, feedText = "You helped take care of the hamster when you could." },
			{ text = "Nah, too much work", effects = { }, feedText = "You preferred to admire the hamster from afar." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- LATE CHILDHOOD (Ages 9-12)
	-- ══════════════════════════════════════════════════════════════════════════════
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: discovered_passion now actually DOES something!
	-- User complaint: "DISCOVERED_PASSION DOES NOTHING BRUH"
	-- Now sets multiple flags AND provides stat bonuses that matter!
	-- These flags will boost related career events and unlock special paths
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "discovered_passion",
		title = "Finding Your Passion",
		emoji = "⭐",
		text = "Something really captured your interest and imagination! This could shape your future!",
		-- CRITICAL FIX: Added text variations for more personalized experience!
		textVariants = {
			"You stayed up way too late doing something you love. This might be your thing!",
			"Your teacher noticed you're really good at something. They think you have talent!",
			"You can't stop thinking about this one thing. It makes you SO happy!",
			"Everyone notices how focused you get when doing this. It's like magic!",
			"You found something that makes time fly by. Hours feel like minutes!",
		},
		question = "What got you excited?",
		minAge = 6, maxAge = 12,
		oneTime = true,
		isMilestone = true,

		-- META
		stage = STAGE,
		ageBand = "late_childhood",
		category = "identity",
		milestoneKey = "CHILD_DISCOVERED_PASSION",
		tags = { "core", "identity", "talent" },
		careerTags = { "sports", "creative", "science", "tech", "medical", "entertainment", "gaming", "writing" },

		-- MAX 5 CHOICES as requested by user
		choices = {
			{ 
				text = "⚽ I LOVE playing sports!", 
				effects = { Health = 10, Happiness = 8 },
				setFlags = { 
					passionate_athlete = true, 
					discovered_passion = true,
					athletic_talent = true,
					sports_interest = true,
					likes_sports = true,
				}, 
				hintCareer = "sports", 
				feedText = "⭐ YES! Sports is YOUR thing! You feel alive on the field!",
			},
			{ 
				text = "💻 I love coding and computers!", 
				effects = { Smarts = 12, Happiness = 6 }, 
				setFlags = { 
					passionate_coder = true,
					discovered_passion = true,
					tech_talent = true,
					coding_interest = true,
					likes_tech = true,
					problem_solver = true,
					future_developer = true,
				}, 
				hintCareer = "tech", 
				feedText = "⭐ CODING is your jam! You speak computer! Future tech genius!",
			},
			{ 
				text = "🔬 I love science experiments!", 
				effects = { Smarts = 12, Happiness = 5 }, 
				setFlags = { 
					passionate_scientist = true,
					discovered_passion = true,
					science_talent = true,
					math_science_talent = true,
					curious_mind = true,
					likes_science = true,
				}, 
				hintCareer = "science", 
				feedText = "⭐ Science is AMAZING! You want to discover how everything works!",
			},
			{ 
				text = "🎮 I love video games!", 
				effects = { Happiness = 10, Smarts = 4 }, 
				setFlags = { 
					passionate_gamer = true,
					discovered_passion = true,
					gaming_interest = true,
					likes_gaming = true,
					competitive = true,
					future_streamer = true,
				}, 
				hintCareer = "gaming", 
				feedText = "⭐ Gaming is your LIFE! Maybe you'll be a streamer or game dev!",
			},
			{ 
				text = "🎵 I love music and performing!", 
				effects = { Happiness = 12, Looks = 4 }, 
				setFlags = { 
					passionate_performer = true,
					discovered_passion = true,
					musical_talent = true,
					natural_performer = true,
					likes_music = true,
					likes_performing = true,
				}, 
				hintCareer = "entertainment", 
				feedText = "⭐ Music moves your SOUL! The stage is calling your name!",
			},
		},
	},

	{
		id = "science_fair",
		title = "Science Fair Project",
		emoji = "🔬",
		text = "It's science fair season! What kind of project will you do?",
		question = "Choose your project:",
		minAge = 7, maxAge = 11,
		baseChance = 0.45,
		cooldown = 5,

		-- META
		stage = STAGE,
		ageBand = "late_childhood",
		category = "school",
		tags = { "science", "project", "school" },
		careerTags = { "science", "tech" },
		blockedByFlags = { in_prison = true },
		
		-- CRITICAL FIX: Wire passion flags! Passionate scientists get bonus outcomes!
		eligibility = function(state)
			local flags = state.Flags or {}
			-- If player has science passion, ALWAYS eligible and will get bonus
			if flags.passionate_scientist or flags.science_interest or flags.math_science_talent then
				return true
			end
			return true -- Everyone can do science fair
		end,

		choices = {
			{ 
				text = "Volcano eruption", 
				effects = { Smarts = 3, Happiness = 5 }, 
				setFlags = { likes_chemistry = true }, 
				hintCareer = "science", 
				feedText = "Your baking soda volcano was the hit of the fair!",
				-- CRITICAL FIX: Bonus for passionate scientists!
				onResolve = function(state)
					local flags = state.Flags or {}
					if flags.passionate_scientist or flags.science_interest then
						state:ModifyStat("Smarts", 5) -- Extra bonus!
						state:AddFeed("🔬 Your passion for science really showed! You won 2nd place!")
					end
				end,
			},
			{ 
				text = "Growing plants experiment", 
				effects = { Smarts = 5 }, 
				setFlags = { patient_researcher = true }, 
				hintCareer = "science", 
				feedText = "You carefully documented how different conditions affect plant growth.",
				onResolve = function(state)
					local flags = state.Flags or {}
					if flags.passionate_scientist or flags.science_interest then
						state:ModifyStat("Smarts", 5)
						state.Flags.science_fair_winner = true
						state:AddFeed("🔬 Your scientific method was PERFECT! You won 1st place!")
					end
				end,
			},
			{ 
				text = "Build a simple robot", 
				effects = { Smarts = 7 }, 
				setFlags = { tech_enthusiast = true }, 
				hintCareer = "tech", 
				feedText = "Your robot impressed the judges. Future engineer!",
				onResolve = function(state)
					local flags = state.Flags or {}
					if flags.passionate_scientist or flags.tech_talent or flags.likes_tech then
						state:ModifyStat("Smarts", 5)
						state.Flags.robotics_winner = true
						state:AddFeed("🤖 Your robot WORKED PERFECTLY! You won Best Technical Project!")
					end
				end,
			},
			{ text = "Skip it", effects = { Smarts = -2 }, feedText = "You didn't participate in the science fair this year." },
		},
	},

	{
		id = "summer_camp",
		title = "Summer Camp",
		emoji = "🏕️",
		text = "Your parents are sending you to summer camp!",
		question = "What kind of camp appeals to you?",
		minAge = 8, maxAge = 12,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

		-- META
		stage = STAGE,
		ageBand = "late_childhood",
		category = "activities",
		tags = { "summer", "camp", "skills" },
		careerTags = { "science", "creative", "sports", "tech" },

		choices = {
			{ text = "Outdoor adventure camp", effects = { Health = 5, Happiness = 5 }, setFlags = { nature_lover = true }, feedText = "You learned to hike, camp, and survive in nature!" },
			{ text = "Science camp", effects = { Smarts = 7 }, setFlags = { science_enthusiast = true }, hintCareer = "science", feedText = "You spent the summer doing cool experiments!" },
			{ text = "Arts camp", effects = { Happiness = 5, Looks = 3 }, setFlags = { artistic = true }, hintCareer = "creative", feedText = "You explored painting, sculpture, and more!" },
			{ text = "Sports camp", effects = { Health = 7, Happiness = 3 }, setFlags = { athlete = true }, hintCareer = "sports", feedText = "You trained hard and improved your athletic skills!" },
			{ text = "Computer/coding camp", effects = { Smarts = 7 }, setFlags = { coder = true }, hintCareer = "tech", feedText = "You learned to code! The digital world opens up." },
		},
	},

	{
		id = "pet_encounter",
		title = "A Pet of Your Own",
		emoji = "🐕",
		text = "Your parents agree to let you have a pet - but you must take care of it yourself.",
		question = "What pet do you choose?",
		minAge = 8, maxAge = 12,
		oneTime = true,
		baseChance = 0.35,

		-- META
		stage = STAGE,
		ageBand = "late_childhood",
		category = "responsibility",
		tags = { "animals", "family", "responsibility" },
		careerTags = { "veterinary" },

		choices = {
			{ text = "A dog", effects = { Happiness = 10, Health = 3 }, setFlags = { has_dog = true, animal_lover = true, has_pet = true }, hintCareer = "veterinary", feedText = "You got a dog! A loyal companion for years to come." },
			{ text = "A cat", effects = { Happiness = 8 }, setFlags = { has_cat = true, animal_lover = true, has_pet = true }, feedText = "You got a cat! Independent, but loving." },
			{ text = "A fish tank", effects = { Happiness = 3, Smarts = 2 }, setFlags = { has_fish = true, has_pet = true }, feedText = "You set up a beautiful fish tank!" },
			{ text = "A hamster or guinea pig", effects = { Happiness = 5 }, setFlags = { has_small_pet = true, animal_lover = true, has_pet = true }, feedText = "Your little furry friend is adorable!" },
		},
	},

	{
		id = "first_crush",
		title = "Butterfly Feelings",
		emoji = "💕",
		text = "You've noticed someone in class makes you feel... different. Your face gets warm when they're around.",
		question = "What do you do about these feelings?",
		minAge = 9, maxAge = 12,
		oneTime = true,
		maxOccurrences = 1,
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.7 to prevent spam
		cooldown = 5, -- CRITICAL FIX: Added cooldown
		-- CRITICAL FIX: Block if already experienced first crush
		blockedByFlags = { had_first_crush = true, in_prison = true, dropped_out = true },

		-- META
		stage = STAGE,
		ageBand = "late_childhood",
		category = "relationships",
		tags = { "romance", "school", "feelings" },

		-- CRITICAL FIX #1001: All choices set had_first_crush for consequence events later!
		choices = {
			{ text = "Write them a secret note", effects = { Happiness = 3 }, setFlags = { romantic_soul = true, had_first_crush = true, experienced_crush = true }, feedText = "You slipped a note to your crush. Heart pounding!" },
			{ text = "Tell your best friend", effects = { Happiness = 3 }, setFlags = { shares_feelings = true, had_first_crush = true, experienced_crush = true }, feedText = "You confided in your best friend about your crush." },
			{ text = "Keep it to yourself", effects = { }, setFlags = { private_person = true, had_first_crush = true, experienced_crush = true }, feedText = "You kept your feelings secret. Some things are just for you." },
			{ text = "Ew, no thanks", effects = { Happiness = 2 }, feedText = "Romance? You've got better things to think about." },
		},
	},

	{
		id = "allowance_decision",
		title = "First Allowance",
		emoji = "💰",
		text = "Your parents started giving you a weekly allowance. What do you do with it?",
		question = "How do you handle your money?",
		minAge = 8, maxAge = 11,
		oneTime = true,

		-- META
		stage = STAGE,
		ageBand = "late_childhood",
		category = "money",
		tags = { "money", "family", "habits" },
		careerTags = { "finance" },

		choices = {
			{ text = "Save it all", effects = { Smarts = 3, Money = 50 }, setFlags = { saver = true }, hintCareer = "finance", feedText = "You save every penny. Future financial whiz!" },
			{ text = "Spend it on candy and toys ($20)", effects = { Happiness = 5, Money = -20 }, setFlags = { spender = true }, feedText = "You enjoy your money while you have it!", eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20" end },
			{ text = "Save some, spend some", effects = { Smarts = 2, Happiness = 3, Money = 25 }, setFlags = { balanced_spender = true }, feedText = "You're learning balance with money." },
			{ text = "Try to invest it somehow", effects = { Smarts = 5, Money = 30 }, setFlags = { entrepreneur = true }, hintCareer = "finance", feedText = "You're already thinking about growing your money!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ADDITIONAL CHILDHOOD EVENTS - AAA QUALITY EXPANSION
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "playground_accident",
		title = "Playground Mishap",
		emoji = "🤕",
		text = "You fell off the monkey bars!",
		question = "Do you tell a grown-up?",
		minAge = 4, maxAge = 10,
		baseChance = 0.4, -- CRITICAL FIX: Reduced from 0.6
		cooldown = 5, -- CRITICAL FIX: Increased
		maxOccurrences = 2, -- Can only fall twice per childhood

		stage = STAGE,
		ageBand = "childhood",
		category = "health",
		tags = { "injury", "playground", "pain" },
		-- CRITICAL FIX: Random injury, not player chosen
		choices = {
			{
				text = "Tell a teacher right away",
				effects = {},
				feedText = "You got help quickly...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Health", -1)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🤕 Just a small scrape. The teacher gave you a cool bandage!")
					elseif roll < 0.70 then
						state:ModifyStat("Health", -4)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🤕 Scraped your knee pretty bad. Got cleaned up at the office.")
					elseif roll < 0.90 then
						state:ModifyStat("Health", -6)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤕 Bruised your arm. Parents called to pick you up.")
					else
						state:ModifyStat("Health", -8)
						state:ModifyStat("Smarts", -1)
						state.Flags = state.Flags or {}
						state.Flags.head_injury = true
						state:AddFeed("🤕 Bumped your head hard. Had to go to the doctor!")
					end
				end,
			},
			{
				text = "Try to be tough and hide it",
				effects = {},
				feedText = "You tried to act like nothing happened...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Health", -2)
						state:AddFeed("🤕 Actually wasn't that bad. You shook it off!")
					elseif roll < 0.60 then
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤕 Your scrapes got worse because you didn't tell anyone.")
					else
						state:ModifyStat("Health", -8)
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🤕 You ended up crying anyway. Should have told someone!")
					end
				end,
			},
		},
	},
	{
		id = "scary_movie",
		title = "The Scary Movie",
		emoji = "😱",
		text = "You accidentally watched a scary movie that was way too intense for your age.",
		question = "How do you react?",
		minAge = 5, maxAge = 10,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

		stage = STAGE,
		ageBand = "childhood",
		category = "psychology",
		tags = { "fear", "movies", "nightmares" },

		choices = {
			{ text = "Can't sleep for weeks", effects = { Health = -4, Happiness = -6 }, setFlags = { easily_scared = true }, feedText = "You had nightmares for weeks. Maybe skip the horror section next time." },
			{ text = "Pretend it didn't scare you", effects = { Happiness = -2 }, setFlags = { hides_feelings = true }, feedText = "You played it cool but still checked under the bed." },
			{ text = "Actually thought it was cool", effects = { Happiness = 3 }, setFlags = { loves_horror = true }, feedText = "You found your love for spooky stuff!" },
			{ text = "Run to your parents", effects = { Happiness = 2 }, feedText = "Mom and Dad made you feel safe again." },
		},
	},
	{
		id = "lost_in_store",
		title = "Lost in the Store",
		emoji = "😰",
		text = "You got separated from your parents at the shopping mall!",
		question = "What do you do?",
		minAge = 3, maxAge = 8,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

		stage = STAGE,
		ageBand = "early_childhood",
		category = "safety",
		tags = { "lost", "scary", "parents" },

		choices = {
			{ text = "Panic and cry loudly", effects = { Happiness = -5 }, feedText = "Your crying helped a store worker find you quickly!" },
			{ text = "Stay calm and find an employee", effects = { Smarts = 4, Happiness = 2 }, setFlags = { stays_calm = true }, feedText = "You remembered what your parents taught you. Smart kid!" },
			{ text = "Start wandering around looking", effects = { Happiness = -3 }, feedText = "You got even more lost before security found you." },
			{ text = "Hide and wait", effects = { Happiness = -4 }, setFlags = { anxious = true }, feedText = "You hid for a while until your frantic parents found you." },
		},
	},
	{
		id = "talent_show",
		title = "School Talent Show",
		emoji = "🎤",
		text = "Your school is having a talent show! Will you participate?",
		question = "What's your act?",
		minAge = 6, maxAge = 12,
		baseChance = 0.45, -- CRITICAL FIX: Reduced from 0.6
		cooldown = 5,
		maxOccurrences = 2, -- CRITICAL FIX: Can only do talent show twice per childhood
		blockedByFlags = { in_prison = true, dropped_out = true },

		stage = STAGE,
		ageBand = "childhood",
		category = "performance",
		tags = { "talent", "performance", "school" },
		careerTags = { "entertainment", "creative" },
		-- CRITICAL FIX: Random performance outcome
		choices = {
			{
				text = "Sing a song",
				effects = {},
				setFlags = { singer = true },
				hintCareer = "entertainment",
				feedText = "You stepped on stage to sing...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Looks", 2)
						state:AddFeed("🎤 Standing ovation! You sang your heart out!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎤 Nice performance! Solid applause from the crowd.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🎤 Your voice cracked... embarrassing but you finished!")
					end
				end,
			},
			{
				text = "Do a magic trick",
				effects = {},
				setFlags = { magician = true },
				feedText = "You prepared your magic act...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🎤 Your magic trick wowed everyone! How did you do that?!")
					elseif roll < 0.80 then
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🎤 Good trick! Some people figured it out but still impressive.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🎤 The trick failed and everyone saw how it worked... oops.")
					end
				end,
			},
			{
				text = "Tell jokes",
				effects = {},
				setFlags = { class_clown = true },
				hintCareer = "entertainment",
				feedText = "You stepped up to do comedy...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🎤 HILARIOUS! Everyone was laughing so hard!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎤 Good laughs! Your timing needs work but fun!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🎤 Silence... those jokes didn't land. Tough crowd.")
					end
				end,
			},
			{
				text = "Play an instrument",
				effects = {},
				setFlags = { musician = true },
				hintCareer = "creative",
				feedText = "You brought your instrument on stage...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local hasSkill = state.Flags and (state.Flags.plays_piano or state.Flags.plays_guitar or state.Flags.musical)
					local successChance = hasSkill and 0.55 or 0.35
					if roll < successChance then
						state:ModifyStat("Smarts", 4)
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🎤 Beautiful! Your musical talent impressed everyone!")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🎤 Nice performance! A few missed notes but good overall.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🎤 Stage fright made you mess up... it was rough.")
					end
				end,
			},
			{
				text = "Too shy to perform",
				effects = { Happiness = -2 },
				setFlags = { stage_fright = true },
				feedText = "You watched from the audience. Maybe next year.",
			},
		},
	},
	{
		id = "new_baby_sibling",
		title = "A New Baby!",
		emoji = "👶",
		text = "Your parents just brought home a new baby sibling!",
		question = "How do you feel about being a big brother/sister?",
		minAge = 3, maxAge = 10,
		oneTime = true,
		baseChance = 0.4,

		stage = STAGE,
		ageBand = "childhood",
		category = "family",
		tags = { "sibling", "baby", "family_change" },

		onResolve = function(state)
			-- Add the baby sibling to relationships
			if state.AddRelationship then
				-- CRITICAL FIX: Use math.random() instead of undefined Random.new()
				local isBoy = math.random() > 0.5
				state:AddRelationship("baby_sibling", {
					id = "baby_sibling",
					name = "Baby",
					type = "family",
					role = isBoy and "Baby Brother" or "Baby Sister",
					relationship = 50,
					age = 0,
					gender = isBoy and "male" or "female",
					alive = true,
					isFamily = true,
				})
			end
		end,

		choices = {
			{ text = "So excited to be a big sibling!", effects = { Happiness = 8 }, setFlags = { loves_sibling = true, has_younger_sibling = true }, feedText = "You can't wait to teach them everything you know!" },
			{ text = "Jealous of the attention they get", effects = { Happiness = -5 }, setFlags = { sibling_rivalry = true, has_younger_sibling = true }, feedText = "You miss being the only child..." },
			{ text = "Curious but cautious", effects = { Happiness = 3, Smarts = 2 }, setFlags = { protective_sibling = true, has_younger_sibling = true }, feedText = "You're learning how to be a good big sibling." },
			{ text = "Want to help take care of them", effects = { Happiness = 5 }, setFlags = { nurturing = true, has_younger_sibling = true }, hintCareer = "medical", feedText = "You're already being so helpful with the baby!" },
		},
	},
	{
		-- CRITICAL FIX: Renamed from "sports_tryout" to "childhood_sports_choice" to avoid duplicate ID
		-- SchoolActivityEvents.lua has sports_tryouts, EarlyLifeEvents has youth_sports_tryout
		id = "childhood_sports_choice",
		title = "Youth Sports Tryouts",
		emoji = "⚽",
		text = "Tryouts for a youth sports team are coming up!",
		question = "Which sport do you try out for?",
		minAge = 6, maxAge = 12,
		baseChance = 0.6,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

		stage = STAGE,
		ageBand = "late_childhood",
		category = "sports",
		tags = { "sports", "team", "competition" },
		careerTags = { "sports" },
		-- CRITICAL FIX: Random tryout outcome - making the team isn't guaranteed
		choices = {
			{
				text = "Soccer",
				effects = {},
				hintCareer = "sports",
				feedText = "You tried out for soccer...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					local makeTeamChance = 0.50 + (health / 150)
					if state.Flags and state.Flags.athlete then makeTeamChance = makeTeamChance + 0.15 end
					if roll < makeTeamChance then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.plays_soccer = true
						state.Flags.team_player = true
						state:AddFeed("⚽ You made the soccer team! Go team!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("⚽ Didn't make the team this year. Keep practicing!")
					end
				end,
			},
			{
				text = "Basketball",
				effects = {},
				hintCareer = "sports",
				feedText = "You tried out for basketball...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					local makeTeamChance = 0.50 + (health / 150)
					if roll < makeTeamChance then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.plays_basketball = true
						state.Flags.team_player = true
						state:AddFeed("🏀 You made the basketball team!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🏀 Cut from the team. Height matters... keep trying!")
					end
				end,
			},
			{
				text = "Baseball/Softball",
				effects = {},
				hintCareer = "sports",
				feedText = "You tried out for baseball...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local makeTeamChance = 0.55 + (health / 200) + (smarts / 300)
					if roll < makeTeamChance then
						state:ModifyStat("Health", 4)
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 1)
						state.Flags = state.Flags or {}
						state.Flags.plays_baseball = true
						state:AddFeed("⚾ Play ball! You made the team!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("⚾ Didn't make it this season. Practice your swing!")
					end
				end,
			},
			{
				text = "Swimming",
				effects = {},
				hintCareer = "sports",
				feedText = "You tried out for the swim team...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					local makeTeamChance = 0.55 + (health / 150)
					if state.Flags and state.Flags.can_swim then makeTeamChance = makeTeamChance + 0.20 end
					if roll < makeTeamChance then
						state:ModifyStat("Health", 6)
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.swimmer = true
						state:AddFeed("🏊 You're on the swim team! Natural in the water!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🏊 Not fast enough for the team this year. Keep swimming!")
					end
				end,
			},
			{
				text = "Not interested in sports",
				effects = { Happiness = 1 },
				feedText = "Organized sports aren't your thing. That's okay!",
			},
		},
	},
	{
		id = "piano_lessons",
		title = "Music Lessons",
		emoji = "🎹",
		text = "Your parents want you to take music lessons.",
		question = "What instrument do you learn?",
		minAge = 5, maxAge = 10,
		oneTime = true,
		baseChance = 0.35,

		stage = STAGE,
		ageBand = "childhood",
		category = "music",
		tags = { "music", "lessons", "skills" },
		careerTags = { "creative", "entertainment" },

		choices = {
			{ text = "Piano", effects = { Smarts = 5, Happiness = 3 }, setFlags = { plays_piano = true, musical = true }, hintCareer = "creative", feedText = "You're learning the piano! Classical training begins." },
			{ text = "Guitar", effects = { Smarts = 3, Happiness = 5, Looks = 2 }, setFlags = { plays_guitar = true, musical = true }, hintCareer = "entertainment", feedText = "You picked up the guitar! Very cool." },
			{ text = "Violin", effects = { Smarts = 6, Happiness = 2 }, setFlags = { plays_violin = true, musical = true }, hintCareer = "creative", feedText = "The violin is challenging but you're determined!" },
			{ text = "Drums", effects = { Happiness = 6, Health = 2 }, setFlags = { plays_drums = true, musical = true }, hintCareer = "entertainment", feedText = "You're the drummer! Your parents might regret this..." },
			{ text = "I don't want lessons", effects = { Happiness = 2 }, feedText = "You'd rather spend time doing other things." },
		},
	},
	{
		id = "loose_tooth_fear",
		title = "Wobbly Tooth Terror",
		emoji = "🦷",
		text = "Your tooth is really loose and wiggling around. It's about to fall out!",
		question = "How do you handle it?",
		minAge = 5, maxAge = 8,
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.7 to prevent spam
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 3, -- Kids lose multiple teeth but not infinite

		stage = STAGE,
		ageBand = "childhood",
		category = "health",
		tags = { "teeth", "growing_up", "fear" },

		choices = {
			{ text = "Pull it out yourself!", effects = { Health = 1, Happiness = 5, Money = 5 }, setFlags = { brave_about_pain = true }, feedText = "You yanked it out! Tooth fairy money incoming!" },
			{ text = "Let it fall out naturally", effects = { Happiness = 3, Money = 5 }, feedText = "It came out while eating an apple. Classic!" },
			{ text = "Too scared to touch it", effects = { Happiness = -2 }, setFlags = { fears_dentist = true }, feedText = "You avoided it for days until it fell out on its own." },
			{ text = "Ask mom/dad to help", effects = { Happiness = 3, Money = 5 }, feedText = "With a quick tug, it was done! Not so bad." },
		},
	},
	{
		id = "spelling_bee",
		title = "The Spelling Bee",
		emoji = "🐝",
		text = "You've been selected to compete in the school spelling bee!",
		question = "How do you prepare?",
		minAge = 7, maxAge = 12,
		baseChance = 0.4,
		cooldown = 3,

		stage = STAGE,
		ageBand = "late_childhood",
		category = "academics",
		tags = { "competition", "school", "spelling" },
		careerTags = { "education", "creative" },
		-- CRITICAL FIX: Random spelling bee outcome based on preparation
		choices = {
			{
				text = "Study the dictionary obsessively",
				effects = { Health = -2 },
				feedText = "You studied for hours every day...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local winChance = 0.40 + (smarts / 150)
					if roll < winChance then
						state:ModifyStat("Smarts", 7)
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.academic_competitor = true
						state.Flags.spelling_champion = true
						state:AddFeed("🐝 You won the spelling bee! E-X-C-E-L-L-E-N-T!")
					elseif roll < winChance + 0.30 then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🐝 Second place! So close to winning!")
					else
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🐝 Tripped up on a tricky word. You tried your best!")
					end
				end,
			},
			{
				text = "Practice casually",
				effects = {},
				feedText = "You prepared a little bit...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local goodChance = 0.25 + (smarts / 200)
					if roll < goodChance then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🐝 Made it to the final rounds! Great job!")
					elseif roll < goodChance + 0.35 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🐝 Did pretty well! Made it past the first round.")
					else
						state:ModifyStat("Smarts", 1)
						state:AddFeed("🐝 Out in the first round. Should have studied more.")
					end
				end,
			},
			{
				text = "Wing it with natural ability",
				effects = {},
				feedText = "You walked in without preparation...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if smarts > 70 and roll < 0.30 then
						state:ModifyStat("Smarts", 4)
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🐝 Natural talent! You did great without studying!")
					elseif roll < 0.40 then
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🐝 Got through a few rounds on instinct!")
					else
						state:ModifyStat("Happiness", -3)
						state.Flags = state.Flags or {}
						state.Flags.performance_anxiety = true
						state:AddFeed("🐝 Blanked on an easy word. Should have prepared!")
					end
				end,
			},
		},
	},
	{
		id = "sleepover_first",
		title = "First Sleepover",
		emoji = "🛏️",
		text = "You're invited to your first sleepover at a friend's house!",
		question = "How does it go?",
		minAge = 6, maxAge = 10,
		oneTime = true,

		stage = STAGE,
		ageBand = "childhood",
		category = "social",
		tags = { "friends", "sleepover", "independence" },

		choices = {
			{ text = "Have an amazing time!", effects = { Happiness = 8 }, setFlags = { loves_sleepovers = true }, feedText = "Best night ever! You stayed up so late!" },
			{ text = "Get homesick and call parents", effects = { Happiness = -3 }, setFlags = { gets_homesick = true }, feedText = "You missed home too much. That's okay, it was your first time." },
			{ text = "Can't fall asleep anywhere else", effects = { Happiness = 2, Health = -2 }, feedText = "You were exhausted the next day but it was worth it!" },
			{ text = "Make even closer friends", effects = { Happiness = 6 }, setFlags = { close_friendships = true }, feedText = "Late night talks made your friendship even stronger!" },
		},
	},
	{
		id = "caught_lying",
		title = "The Big Lie",
		emoji = "🤥",
		text = "You told a lie and your parents found out!",
		question = "What was the lie about?",
		minAge = 5, maxAge = 12,
		baseChance = 0.35,
		cooldown = 3,

		stage = STAGE,
		ageBand = "childhood",
		category = "behavior",
		tags = { "lying", "consequences", "morals" },

		choices = {
			{ text = "Said I didn't eat the cookies", effects = { Happiness = -3 }, feedText = "The chocolate on your face gave you away..." },
			{ text = "Blamed my sibling for something I did", effects = { Happiness = -4 }, setFlags = { blames_others = true }, feedText = "You got caught and had to apologize to everyone." },
			{ text = "Said I did my homework when I didn't", effects = { Smarts = -2, Happiness = -3 }, feedText = "Double trouble - for lying AND not doing homework!" },
			{ text = "Confessed before getting caught", effects = { Happiness = 2, Smarts = 2 }, setFlags = { honest = true }, feedText = "Coming clean felt better than you expected." },
		},
	},
	{
		id = "video_game_discovery",
		title = "Video Game Obsession",
		emoji = "🎮",
		-- CRITICAL FIX #21: Text variations for gaming discovery!
		textVariants = {
			"You discovered video games and can't stop playing!",
			"A friend showed you their video games. You're instantly hooked!",
			"Your parents got you a gaming console. Best present EVER!",
			"You've discovered the world of video games. Time disappears when you play!",
			"Screen time just became your favorite time. Video games are amazing!",
			"You found your new obsession - video games!",
		},
		text = "You discovered video games and can't stop playing!",
		question = "What's your gaming style?",
		minAge = 6, maxAge = 12,
		oneTime = true,
		baseChance = 0.45,

		stage = STAGE,
		ageBand = "childhood",
		category = "hobbies",
		tags = { "gaming", "technology", "hobby" },
		careerTags = { "tech", "entertainment" },

		choices = {
			{ text = "Become a dedicated gamer", effects = { Happiness = 7, Health = -3, Smarts = 2 }, setFlags = { gamer = true, loves_games = true }, hintCareer = "tech", feedText = "Gaming becomes your favorite hobby!" },
			{ text = "Play in moderation", effects = { Happiness = 4, Smarts = 2 }, setFlags = { casual_gamer = true }, feedText = "You enjoy games but keep a healthy balance." },
			{ text = "Get bored of games quickly", effects = { Happiness = 1 }, feedText = "Games aren't really your thing." },
			{ text = "Parents limit screen time strictly", effects = { Happiness = -2, Health = 2 }, setFlags = { limited_screen_time = true }, feedText = "Only 30 minutes a day. You made them count!" },
		},
	},
	{
		id = "show_and_tell",
		title = "Show and Tell",
		emoji = "🧸",
		-- CRITICAL FIX #11: Text variations for show and tell!
		textVariants = {
			"It's your turn for show and tell at school!",
			"The teacher calls your name... it's show and tell time!",
			"You've been waiting all week for this - show and tell day!",
			"Your classmates gather around as you prepare for show and tell!",
			"Today's the day! You get to share something special with the class!",
			"The class goes quiet. All eyes on you for show and tell!",
		},
		text = "It's your turn for show and tell at school!",
		question = "What do you bring?",
		minAge = 4, maxAge = 7,
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.8
		cooldown = 5, -- CRITICAL FIX: Increased

		stage = STAGE,
		ageBand = "early_childhood",
		category = "school",
		tags = { "school", "presentation", "sharing" },
		blockedByFlags = { in_prison = true },

		choices = {
			{ text = "My favorite toy", effects = { Happiness = 5 }, feedText = "Everyone loved your special toy!" },
			{ text = "Something I made", effects = { Happiness = 4, Smarts = 3 }, setFlags = { creative = true }, feedText = "Your handmade creation impressed the class!" },
			{ text = "A cool rock I found", effects = { Happiness = 3, Smarts = 2 }, setFlags = { collector = true }, feedText = "Nature is fascinating! Everyone wanted to see your rock." },
			{ text = "My pet (with permission)", effects = { Happiness = 8 }, setFlags = { has_pet = true }, feedText = "Your pet was the star of show and tell!" },
			{ text = "Forget to bring anything", effects = { Happiness = -4 }, feedText = "You had to improvise. It was awkward." },
		},
	},
	{
		id = "reading_discovery",
		title = "Falling in Love with Reading",
		emoji = "📚",
		text = "You discovered a book series that captured your imagination!",
		question = "What kind of books do you love?",
		minAge = 6, maxAge = 12,
		oneTime = true,
		baseChance = 0.6,

		stage = STAGE,
		ageBand = "childhood",
		category = "literacy",
		tags = { "reading", "imagination", "learning" },
		careerTags = { "education", "creative" },

		choices = {
			{ text = "Fantasy and magic", effects = { Smarts = 5, Happiness = 6 }, setFlags = { bookworm = true, loves_fantasy = true }, hintCareer = "creative", feedText = "You got lost in magical worlds!" },
			{ text = "Mystery and detective stories", effects = { Smarts = 6, Happiness = 4 }, setFlags = { bookworm = true, loves_mystery = true }, feedText = "You're always trying to solve the case before the end!" },
			{ text = "Science and nature books", effects = { Smarts = 7, Happiness = 3 }, setFlags = { bookworm = true, loves_science = true }, hintCareer = "science", feedText = "Non-fiction fascinated you. So many facts to learn!" },
			{ text = "Comics and graphic novels", effects = { Happiness = 5, Smarts = 3 }, setFlags = { loves_comics = true }, feedText = "Pictures and stories combined? Perfect!" },
			{ text = "I don't really like reading", effects = { Happiness = 1 }, feedText = "Books aren't your thing right now." },
		},
	},
	{
		id = "treehouse_adventure",
		title = "The Secret Fort",
		emoji = "🏠",
		text = "You and your friends found a perfect spot for a secret hideout!",
		question = "What kind of hideout do you build?",
		minAge = 7, maxAge = 12,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

		stage = STAGE,
		ageBand = "late_childhood",
		category = "play",
		tags = { "adventure", "creativity", "friends" },

		choices = {
			{ text = "A treehouse in the backyard", effects = { Happiness = 8, Health = 3 }, setFlags = { has_treehouse = true, outdoorsy = true }, feedText = "Your treehouse became legendary in the neighborhood!" },
			{ text = "A blanket fort inside", effects = { Happiness = 6 }, setFlags = { creative_builder = true }, feedText = "The ultimate blanket fort! So cozy." },
			{ text = "A secret club with rules", effects = { Happiness = 5, Smarts = 3 }, setFlags = { natural_leader = true }, feedText = "Your secret club had meetings and everything!" },
			{ text = "A detective headquarters", effects = { Happiness = 5, Smarts = 4 }, setFlags = { detective_dreams = true }, feedText = "You solved neighborhood mysteries from your HQ!" },
		},
	},
	{
		id = "bad_dream",
		title = "Nightmares",
		emoji = "😨",
		text = "You've been having scary dreams lately.",
		question = "How do you cope with the nightmares?",
		minAge = 4, maxAge = 10,
		baseChance = 0.35,
		cooldown = 3,

		stage = STAGE,
		ageBand = "childhood",
		category = "psychology",
		tags = { "dreams", "fear", "coping" },

		choices = {
			{ text = "Sleep with a nightlight", effects = { Happiness = 3 }, setFlags = { needs_nightlight = true }, feedText = "The light helps you feel safe." },
			{ text = "Mom/Dad checks for monsters", effects = { Happiness = 4 }, feedText = "Parents confirmed: no monsters under the bed!" },
			{ text = "Create a dream catcher", effects = { Happiness = 4, Smarts = 2 }, setFlags = { believes_in_magic = true }, feedText = "Your dream catcher works!" },
			{ text = "Face the fear bravely", effects = { Happiness = 5, Smarts = 3 }, setFlags = { brave = true }, feedText = "You learned that nightmares can't really hurt you." },
		},
	},
	{
		id = "swimming_lessons",
		title = "Learning to Swim",
		emoji = "🏊",
		text = "Your parents signed you up for swimming lessons! Time to get in the pool.",
		question = "How do you approach the water?",
		minAge = 4, maxAge = 8,
		oneTime = true,
		baseChance = 0.45,

		stage = STAGE,
		ageBand = "early_childhood",
		category = "skills",
		tags = { "swimming", "water", "skills" },
		careerTags = { "sports" },
		-- CRITICAL FIX: Random swimming lesson outcome
		choices = {
			{
				text = "Jump right in!",
				effects = {},
				feedText = "You dove in with enthusiasm...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					local successChance = 0.45 + (health / 150)
					if roll < successChance then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 7)
						state.Flags = state.Flags or {}
						state.Flags.can_swim = true
						state.Flags.water_confident = true
						state:AddFeed("🏊 You took to water like a fish! Natural swimmer!")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Health", 3)
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.can_swim = true
						state:AddFeed("🏊 Swallowed some water but learned to swim!")
					else
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Health", -2)
						state:AddFeed("🏊 That was scary! Almost drowned but the instructor saved you.")
					end
				end,
			},
			{
				text = "Go slow and steady",
				effects = {},
				feedText = "You took a cautious approach...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Health", 4)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.can_swim = true
						state:AddFeed("🏊 Took a few lessons but you learned to swim!")
					elseif roll < 0.85 then
						state:ModifyStat("Health", 2)
						state:ModifyStat("Happiness", 2)
						state.Flags = state.Flags or {}
						state.Flags.can_swim = true
						state:AddFeed("🏊 Still nervous but you can doggy paddle at least!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🏊 Still working on it... lessons continue next summer.")
					end
				end,
			},
			{
				text = "I don't want to go in!",
				effects = {},
				feedText = "You refused to get in the pool...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 2)
						state.Flags = state.Flags or {}
						state.Flags.can_swim = true
						state:AddFeed("🏊 The instructor convinced you and you actually liked it!")
					else
						state:ModifyStat("Happiness", -4)
						state.Flags = state.Flags or {}
						state.Flags.water_phobia = true
						state:AddFeed("🏊 You cried and refused. Swimming isn't for everyone...")
					end
				end,
			},
		},
	},
	{
		id = "holiday_excitement",
		title = "Holiday Magic",
		emoji = "🎄",
		text = "The holidays are here! You're so excited!",
		question = "What's your favorite part?",
		minAge = 4, maxAge = 10,
		baseChance = 0.45, -- CRITICAL FIX: Reduced from 0.8
		cooldown = 4, -- CRITICAL FIX: Increased from 1 to prevent spam

		stage = STAGE,
		ageBand = "childhood",
		category = "family",
		tags = { "holiday", "family", "tradition" },

		choices = {
			{ text = "The presents!", effects = { Happiness = 8, Money = 20 }, feedText = "You got exactly what you wished for!" },
			{ text = "Family time together", effects = { Happiness = 7 }, setFlags = { family_oriented = true }, feedText = "Being with everyone you love is the best gift." },
			{ text = "The special food", effects = { Happiness = 6, Health = -1 }, feedText = "So many delicious treats!" },
			{ text = "Decorating and traditions", effects = { Happiness = 6 }, setFlags = { loves_traditions = true }, feedText = "The decorations and traditions make everything magical." },
		},
	},
	{
		id = "first_day_anxiety",
		title = "First Day Fears",
		emoji = "😟",
		text = "It's the first day at a new school and you're nervous.",
		question = "How do you handle the anxiety?",
		minAge = 5, maxAge = 11,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

		stage = STAGE,
		ageBand = "childhood",
		category = "school",
		tags = { "anxiety", "school", "new_beginnings" },

		choices = {
			{ text = "Put on a brave face", effects = { Happiness = 4, Smarts = 2 }, setFlags = { adapts_well = true }, feedText = "You walked in with confidence (even if you didn't feel it)." },
			{ text = "Cry and want to go home", effects = { Happiness = -4 }, setFlags = { separation_anxiety = true }, feedText = "It was rough, but it got better." },
			{ text = "Make a new friend immediately", effects = { Happiness = 7 }, setFlags = { makes_friends_easily = true }, feedText = "Within an hour, you had a new best friend!" },
			{ text = "Stay quiet and observe", effects = { Smarts = 4 }, setFlags = { cautious = true }, feedText = "You figured out how things worked before jumping in." },
		},
	},
	{
		id = "dentist_visit",
		title = "Dentist Appointment",
		emoji = "🦷",
		text = "Time for your dentist checkup! You sit in the big chair.",
		question = "How do you feel about the dentist?",
		minAge = 4, maxAge = 12,
		baseChance = 0.6,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

		stage = STAGE,
		ageBand = "childhood",
		category = "health",
		tags = { "dentist", "health", "fear" },
		-- CRITICAL FIX: Random cavity outcome - you don't choose dental health
		choices = {
			{
				text = "Open wide - let's see!",
				effects = {},
				feedText = "The dentist takes a look...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					-- Better health = less likely to have cavities
					local cavityChance = 0.35 - (health / 300)
					if roll < cavityChance then
						state:ModifyStat("Health", 1)
						state:ModifyStat("Happiness", -4)
						state.Money = math.max(0, (state.Money or 0) - 20)
						state:AddFeed("🦷 A cavity! The drilling wasn't fun, but it's over now.")
					elseif roll < cavityChance + 0.15 then
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🦷 Teeth are okay but you need to brush better!")
					else
						state:ModifyStat("Health", 3)
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🦷 Perfect checkup! No cavities! Good brushing!")
					end
				end,
			},
			{
				text = "I'm scared but I'll be brave",
				effects = {},
				feedText = "You're nervous but cooperate...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state:ModifyStat("Health", 1)
						state:ModifyStat("Happiness", -3)
						state.Money = math.max(0, (state.Money or 0) - 20)
						state:AddFeed("🦷 Had a small cavity but you were so brave!")
					elseif roll < 0.50 then
						state:ModifyStat("Happiness", 3)
						state:ModifyStat("Smarts", 1)
						state.Flags = state.Flags or {}
						state.Flags.dentist_friendly = true
						state:AddFeed("🦷 All clear! The dentist gave you a cool toothbrush!")
					else
						state:ModifyStat("Health", 2)
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🦷 Good checkup! Being brave paid off!")
					end
				end,
			},
			{
				text = "I'm too scared!",
				effects = {},
				feedText = "You started crying in the chair...",
				onResolve = function(state)
					local roll = math.random()
					state:ModifyStat("Happiness", -4)
					state.Flags = state.Flags or {}
					state.Flags.fears_dentist = true
					if roll < 0.40 then
						state:AddFeed("🦷 The dentist tried but you wouldn't open your mouth!")
					else
						state:AddFeed("🦷 Cried the whole time but they finished. It's over!")
					end
				end,
			},
		},
	},
	{
		id = "broken_favorite_toy",
		title = "Broken Treasure",
		emoji = "💔",
		text = "Your favorite toy broke!",
		question = "How do you react?",
		minAge = 3, maxAge = 8,
		baseChance = 0.35,
		cooldown = 3,

		stage = STAGE,
		ageBand = "early_childhood",
		category = "emotions",
		tags = { "loss", "emotions", "coping" },

		choices = {
			{ text = "Devastated - cry for hours", effects = { Happiness = -6 }, feedText = "You were heartbroken. That toy meant everything." },
			{ text = "Try to fix it yourself", effects = { Happiness = -2, Smarts = 4 }, setFlags = { resourceful = true }, feedText = "You tried your best to repair it. That's problem-solving!" },
			{ text = "Ask parents to fix it", effects = { Happiness = 3 }, feedText = "Dad fixed it with some tape. Good as new... mostly." },
			{ text = "Move on to a new toy", effects = { Happiness = 2 }, setFlags = { adapts_easily = true }, feedText = "You found a new favorite pretty quickly." },
		},
	},
	{
		id = "caught_in_rain",
		title = "Caught in a Storm",
		emoji = "🌧️",
		text = "You got caught in a sudden rainstorm!",
		question = "What do you do?",
		minAge = 5, maxAge = 12,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

		stage = STAGE,
		ageBand = "childhood",
		category = "weather",
		tags = { "weather", "adventure", "play" },

		choices = {
			{ text = "Jump in all the puddles!", effects = { Happiness = 8, Health = -2 }, setFlags = { loves_rain = true }, feedText = "Splashing in puddles is the best! You're soaked but happy." },
			{ text = "Run home as fast as you can", effects = { Health = 2 }, feedText = "You made it home just in time!" },
			{ text = "Find shelter and wait", effects = { Smarts = 3 }, setFlags = { patient = true }, feedText = "You stayed dry under the awning until it passed." },
			{ text = "Get scared of the thunder", effects = { Happiness = -3 }, setFlags = { fears_storms = true }, feedText = "The thunder was really scary!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EXTENDED CHILDHOOD EVENTS - MORE VARIETY AND DEPTH
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "learning_to_read",
		title = "Learning to Read",
		emoji = "📖",
		text = "You're learning to read! The letters are starting to make sense.",
		question = "How is your reading progress?",
		minAge = 4, maxAge = 6,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		
		stage = STAGE,
		ageBand = "early_childhood",
		category = "development",
		milestoneKey = "CHILD_LEARNED_READ",
		tags = { "literacy", "development", "skills" },
		
		choices = {
			{
				text = "Reading comes naturally!",
				effects = {},
				feedText = "You picked up a book...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.35 + (smarts / 150)
					if roll < successChance then
						state:ModifyStat("Smarts", 8)
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.advanced_reader = true
						state.Flags.can_read = true
						state:AddFeed("📖 You're reading above your grade level! Natural talent!")
					elseif roll < successChance + 0.35 then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.can_read = true
						state:AddFeed("📖 You learned to read! A whole world of books opens up!")
					else
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 2)
						state.Flags = state.Flags or {}
						state.Flags.can_read = true
						state:AddFeed("📖 Reading is coming along. Practice makes perfect!")
					end
				end,
			},
			{
				text = "It's a bit of a struggle",
				effects = {},
				feedText = "You're working hard at reading...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.persistent = true
						state.Flags.can_read = true
						state:AddFeed("📖 Hard work paid off! You're reading now!")
					elseif roll < 0.75 then
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.can_read = true
						state:AddFeed("📖 Still learning, but you're getting there!")
					else
						state:ModifyStat("Smarts", 1)
						state:ModifyStat("Happiness", -2)
						state.Flags = state.Flags or {}
						state.Flags.reading_difficulty = true
						state:AddFeed("📖 Reading is really hard for you. Extra help might be needed.")
					end
				end,
			},
		},
	},
	{
		-- CRITICAL FIX: Renamed from "first_day_kindergarten" to avoid duplicate ID conflict
		-- CoreMilestones has a more elaborate version of this event
		id = "kindergarten_simple",
		title = "First Day of Kindergarten",
		emoji = "🎒",
		-- CRITICAL FIX #20: Text variations for kindergarten start!
		textVariants = {
			"It's your very first day of kindergarten! Everything is new and exciting.",
			"The school bus pulls up. It's your first day of kindergarten!",
			"You're wearing new clothes and carrying a new backpack. Kindergarten begins!",
			"Mom takes pictures as you head to your first day of 'real school'!",
			"The kindergarten classroom is full of colorful things. Your education begins!",
			"Other kids are crying, but you're ready for kindergarten adventure!",
		},
		text = "It's your very first day of kindergarten! Everything is new and exciting.",
		question = "How do you feel about starting school?",
		minAge = 5, maxAge = 5,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		
		stage = STAGE,
		ageBand = "early_childhood",
		category = "school",
		milestoneKey = "CHILD_KINDERGARTEN",
		tags = { "school", "milestone", "social" },
		
		choices = {
			{ text = "So excited to learn!", effects = { Happiness = 7, Smarts = 3 }, setFlags = { loves_school = true }, feedText = "You walked in with a big smile, ready for everything!" },
			{ text = "Nervous but trying", effects = { Happiness = 2, Smarts = 2 }, setFlags = { school_nervous = true }, feedText = "The butterflies in your stomach calmed down by lunchtime." },
			{ text = "Cried when parents left", effects = { Happiness = -4 }, setFlags = { separation_anxiety = true }, feedText = "It was hard, but you made it through the day." },
			{ text = "Made friends immediately", effects = { Happiness = 8 }, setFlags = { social_butterfly = true }, feedText = "By recess, you already had a whole group of friends!" },
		},
	},
	{
		id = "potty_training",
		title = "Big Kid Achievement",
		emoji = "🚽",
		-- CRITICAL FIX #12: Text variations for potty training milestone!
		textVariants = {
			"You've been working on using the potty like a big kid!",
			"Mom says it's time to learn to use the big kid toilet!",
			"The potty chair has become your new challenge!",
			"Your parents are trying to teach you the ways of the bathroom!",
			"No more diapers? Time to try the potty!",
			"It's potty training time! A big milestone awaits!",
		},
		text = "You've been working on using the potty like a big kid!",
		question = "How is the potty training going?",
		minAge = 2, maxAge = 4,
		oneTime = true,
		isMilestone = true,
		
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "development",
		milestoneKey = "CHILD_POTTY_TRAINED",
		tags = { "development", "milestone", "growing_up" },
		
		choices = {
			{
				text = "I'm a natural!",
				effects = {},
				feedText = "Time to try...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.potty_trained = true
						state:AddFeed("🚽 You got it! No more diapers!")
					else
						state:ModifyStat("Happiness", 2)
						state.Flags = state.Flags or {}
						state.Flags.potty_trained = true
						state:AddFeed("🚽 A few accidents but you're getting there!")
					end
				end,
			},
			{
				text = "Still working on it",
				effects = {},
				feedText = "Practice makes perfect...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.potty_trained = true
						state:AddFeed("🚽 Taking a little longer, but you did it!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🚽 Still in training. Everyone learns at their own pace.")
					end
				end,
			},
		},
	},
	{
		id = "learned_numbers",
		title = "Counting Fun",
		emoji = "🔢",
		text = "You're learning to count! Numbers are everywhere.",
		question = "How high can you count?",
		minAge = 3, maxAge = 5,
		oneTime = true,
		
		stage = STAGE,
		ageBand = "early_childhood",
		category = "development",
		tags = { "numbers", "learning", "development" },
		careerTags = { "finance", "science" },
		
		choices = {
			{ text = "All the way to 100!", effects = { Smarts = 6, Happiness = 5 }, setFlags = { math_minded = true }, hintCareer = "finance", feedText = "You counted so high! Numbers are your friend." },
			{ text = "To 20 with help", effects = { Smarts = 4, Happiness = 3 }, feedText = "Twenty fingers and toes to count on!" },
			{ text = "Still learning", effects = { Smarts = 2, Happiness = 2 }, feedText = "One, two, three... you're getting there!" },
		},
	},
	{
		id = "temper_tantrum_public",
		title = "Meltdown",
		emoji = "😭",
		text = "You're having a full meltdown in public!",
		question = "What triggered it?",
		minAge = 2, maxAge = 5,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "behavior",
		tags = { "tantrum", "emotions", "public" },
		
		choices = {
			{ text = "Wanted candy at checkout", effects = { Happiness = -3 }, feedText = "The candy display is evil. You didn't get any." },
			{ text = "Too tired and overstimulated", effects = { Happiness = -4, Health = -1 }, feedText = "You were exhausted. Home and nap time it is." },
			{ text = "Didn't want to leave the park", effects = { Happiness = -3 }, feedText = "Five more minutes was NOT enough." },
			{ text = "Sibling annoyed you", effects = { Happiness = -2 }, setFlags = { sibling_rivalry = true }, feedText = "Your sibling always knows how to push your buttons." },
		},
	},
	{
		id = "first_haircut",
		title = "First Haircut",
		emoji = "✂️",
		text = "Time for your very first haircut! The scissors look scary...",
		question = "How do you handle your first haircut?",
		minAge = 1, maxAge = 3,
		oneTime = true,
		isMilestone = true,
		
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "development",
		milestoneKey = "CHILD_FIRST_HAIRCUT",
		tags = { "haircut", "milestone", "grooming" },
		
		choices = {
			{ text = "Sit still like a big kid", effects = { Happiness = 5, Looks = 2 }, setFlags = { well_behaved = true }, feedText = "You were so brave! Parents saved a lock of hair." },
			{ text = "Cry and squirm", effects = { Happiness = -3, Looks = 1 }, feedText = "It was traumatic but you got through it... eventually." },
			{ text = "Watch cartoons and forget", effects = { Happiness = 3, Looks = 2 }, feedText = "You were distracted and it was over before you knew it!" },
		},
	},
	{
		id = "playground_friend",
		title = "Playground Pal",
		emoji = "🛝",
		text = "You met a new kid at the playground!",
		question = "What do you play together?",
		minAge = 3, maxAge = 7,
		baseChance = 0.6,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "early_childhood",
		category = "social",
		tags = { "friends", "playground", "play" },
		
		choices = {
			{ text = "Tag - you're it!", effects = { Happiness = 5, Health = 3 }, feedText = "You ran around until you were both exhausted!" },
			{ text = "Build a sandcastle together", effects = { Happiness = 4, Smarts = 2 }, setFlags = { cooperative = true }, feedText = "You made the best sandcastle ever!" },
			{ text = "Swings - who can go higher?", effects = { Happiness = 5, Health = 2 }, feedText = "You touched the sky!" },
			{ text = "Too shy to play", effects = { Happiness = -2 }, setFlags = { shy = true }, feedText = "Maybe next time you'll make a friend." },
		},
	},
	{
		-- CRITICAL FIX: Renamed to avoid ID collision with other birthday events
		id = "childhood_birthday_celebration",
		title = "Birthday Celebration",
		emoji = "🎂",
		text = "It's your birthday! Time to celebrate!",
		question = "What kind of party do you want?",
		minAge = 3, maxAge = 12,
		baseChance = 0.4, -- CRITICAL FIX: Reduced to prevent spam
		cooldown = 5, -- CRITICAL FIX: Increased to prevent spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "celebration",
		tags = { "birthday", "party", "celebration" },
		
		choices = {
		{ text = "Big party with all my friends (parents pay)", effects = { Happiness = 10 }, setFlags = { party_person = true }, feedText = "Best birthday ever! So many friends and presents!" },
		{ text = "Small family celebration", effects = { Happiness = 7 }, setFlags = { family_oriented = true }, feedText = "Cozy and special with the people who matter most." },
		{ text = "Special outing instead (parents pay)", effects = { Happiness = 8 }, feedText = "An adventure for your birthday! So memorable." },
		{ text = "Themed costume party (parents pay)", effects = { Happiness = 9, Looks = 2 }, setFlags = { loves_costumes = true }, feedText = "Everyone dressed up! It was magical." },
		},
	},
	{
		id = "school_picture_day",
		title = "Picture Day",
		emoji = "📸",
		text = "It's school picture day! Time to look your best.",
		question = "How does picture day go?",
		minAge = 5, maxAge = 12,
		baseChance = 0.45, -- CRITICAL FIX: Reduced from 0.8
		cooldown = 4, -- CRITICAL FIX: Increased from 1 to prevent spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "school",
		tags = { "photos", "school", "appearance" },
		-- CRITICAL FIX: Random picture outcome
		choices = {
			{
				text = "Smile big!",
				effects = {},
				feedText = "You sat for your photo...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Looks", 1)
						state:AddFeed("📸 Great photo! You're a natural in front of the camera!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📸 Decent photo. Could be worse!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📸 Awkward photo... you blinked. Or had spinach in your teeth.")
					end
				end,
			},
			{
				text = "Make a silly face",
				effects = {},
				feedText = "You couldn't help yourself...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("📸 The photographer actually captured your silly face! Mom isn't happy.")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📸 The photographer made you redo it. Normal face this time.")
					end
				end,
			},
			{
				text = "Forgot it was picture day",
				effects = { Happiness = -4, Looks = -2 },
				feedText = "Wore your messiest clothes and hadn't brushed your hair. Classic.",
			},
		},
	},
	{
		id = "field_trip",
		title = "School Field Trip",
		emoji = "🚌",
		text = "Your class is going on a field trip!",
		question = "Where is the field trip?",
		minAge = 5, maxAge = 12,
		baseChance = 0.6,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "school",
		tags = { "field_trip", "learning", "adventure" },
		careerTags = { "science", "creative" },
		
		choices = {
			{ text = "The zoo!", effects = { Happiness = 8, Smarts = 2 }, setFlags = { animal_lover = true }, hintCareer = "veterinary", feedText = "You loved seeing all the animals! The monkeys were your favorite." },
			{ text = "A museum", effects = { Happiness = 5, Smarts = 5 }, setFlags = { curious_mind = true }, hintCareer = "science", feedText = "So much to learn! You could have stayed all day." },
			{ text = "A farm", effects = { Happiness = 6, Health = 2 }, feedText = "You pet a cow and saw baby chicks!" },
			{ text = "A factory", effects = { Happiness = 4, Smarts = 3 }, feedText = "Interesting to see how things are made!" },
		},
	},
	{
		id = "learned_tie_shoes",
		title = "Shoe Tying Champion",
		emoji = "👟",
		text = "You're learning to tie your own shoelaces!",
		question = "How quickly do you master it?",
		minAge = 4, maxAge = 7,
		oneTime = true,
		isMilestone = true,
		
		stage = STAGE,
		ageBand = "early_childhood",
		category = "development",
		milestoneKey = "CHILD_TIE_SHOES",
		tags = { "skills", "independence", "motor_skills" },
		
		choices = {
			{
				text = "Bunny ears method!",
				effects = {},
				feedText = "You tried the bunny ears...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.can_tie_shoes = true
						state:AddFeed("👟 You mastered the bunny ears! Independence unlocked!")
					elseif roll < 0.85 then
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.can_tie_shoes = true
						state:AddFeed("👟 After many tries, you got it! Sort of...")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("👟 Still tricky. Velcro shoes to the rescue!")
					end
				end,
			},
			{
				text = "The loop-swoop method",
				effects = {},
				feedText = "You tried the classic method...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.45 + (smarts / 200) then
						state:ModifyStat("Smarts", 4)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.can_tie_shoes = true
						state:AddFeed("👟 You're a shoe-tying pro!")
					else
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", 2)
						state.Flags = state.Flags or {}
						state.Flags.can_tie_shoes = true
						state:AddFeed("👟 Took a while, but you figured it out!")
					end
				end,
			},
			{
				text = "I prefer velcro",
				effects = { Happiness = 2 },
				feedText = "Velcro shoes are just easier. Maybe later on the laces.",
			},
		},
	},
	{
		id = "school_lunch",
		title = "The Cafeteria",
		emoji = "🍽️",
		text = "Lunchtime at school! The cafeteria is crowded.",
		question = "What's your lunch routine?",
		minAge = 5, maxAge = 12,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "school",
		tags = { "lunch", "social", "school" },
		
		choices = {
			{ text = "Packed lunch from home", effects = { Happiness = 4, Health = 2 }, feedText = "Mom's sandwiches are the best!" },
			{ text = "School hot lunch", effects = { Happiness = 3 }, feedText = "Mystery meat day... but the chocolate milk makes up for it!" },
			{ text = "Trade food with friends", effects = { Happiness = 5, Smarts = 1 }, setFlags = { negotiator = true }, feedText = "Your snack for their dessert. Fair trade!" },
			{ text = "Eat alone and read", effects = { Smarts = 3, Happiness = -1 }, setFlags = { loner = true }, feedText = "Quiet lunches with a good book." },
		},
	},
	{
		id = "chore_introduction",
		title = "Chore Time",
		emoji = "🧹",
		text = "Your parents want you to start helping with chores around the house.",
		question = "How do you respond to chore duty?",
		minAge = 5, maxAge = 10,
		oneTime = true,
		
		stage = STAGE,
		ageBand = "childhood",
		category = "responsibility",
		tags = { "chores", "responsibility", "family" },
		
		choices = {
			{ text = "Happy to help!", effects = { Happiness = 3, Smarts = 2 }, setFlags = { helpful = true, does_chores = true }, feedText = "You're a big helper now! Maybe there's an allowance in your future..." },
			{ text = "Complain but do them", effects = { Happiness = -2 }, setFlags = { does_chores = true }, feedText = "You grumbled but got it done. Responsibility is hard." },
			{ text = "Do them badly so you won't be asked again", effects = { Smarts = 2 }, setFlags = { strategic = true }, feedText = "You did such a bad job they might not ask again... clever." },
			{ text = "Refuse completely", effects = { Happiness = -4 }, setFlags = { defiant = true }, feedText = "You got in trouble for refusing. There are consequences..." },
		},
	},
	{
		id = "class_project_partner",
		title = "Group Project",
		emoji = "📊",
		text = "You have a group project at school and need to work with a partner.",
		question = "How does the partnership go?",
		minAge = 7, maxAge = 12,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "late_childhood",
		category = "school",
		tags = { "project", "teamwork", "school" },
		-- CRITICAL FIX: Random group project outcome
		choices = {
			{
				text = "Work together great!",
				effects = {},
				feedText = "You started the project...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.team_player = true
						state:AddFeed("📊 Amazing teamwork! You got an A together!")
					elseif roll < 0.80 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📊 Pretty good project! You learned to collaborate.")
					else
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📊 Your partner wasn't great, but you made it work.")
					end
				end,
			},
			{
				text = "Do all the work myself",
				effects = {},
				feedText = "You took charge...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Smarts", 6)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📊 Great grade but you're exhausted. Partners are supposed to help!")
					else
						state:ModifyStat("Smarts", 4)
						state:ModifyStat("Happiness", -4)
						state:AddFeed("📊 Did all the work and the teacher noticed. Partner got in trouble.")
					end
				end,
			},
			{
				text = "Let partner do most of it",
				effects = {},
				feedText = "You let your partner take the lead...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📊 Your partner was great! Good grade with minimal effort.")
					elseif roll < 0.65 then
						state:ModifyStat("Smarts", 1)
						state:AddFeed("📊 Mediocre project. You should have helped more.")
					else
						state:ModifyStat("Smarts", -1)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📊 Bad grade. The teacher knew you didn't contribute.")
					end
				end,
			},
		},
	},
	{
		id = "sick_day_school",
		title = "Too Sick for School",
		emoji = "🤒",
		text = "You woke up not feeling well. Are you really sick or just don't want to go to school?",
		question = "What's really going on?",
		minAge = 5, maxAge = 12,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "health",
		tags = { "sick", "school", "health" },
		-- CRITICAL FIX: Random health check - you can't perfectly fake being sick
		choices = {
			{
				text = "Actually sick - fever and everything",
				effects = {},
				feedText = "Mom checks your temperature...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					-- Lower health = more likely to actually be sick
					local sickChance = 0.70 - (health / 200)
					if roll < sickChance then
						state:ModifyStat("Health", -6)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🤒 You really are sick! Soup, rest, and TV all day.")
					else
						state:ModifyStat("Happiness", -1)
						state:AddFeed("🤒 Just a minor bug. You rest but feel better by afternoon.")
					end
				end,
			},
			{
				text = "Faking it to skip school",
				effects = {},
				feedText = "You pretend to be sick...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local foolParentsChance = 0.30 + (smarts / 200)
					if roll < foolParentsChance then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🤒 Success! A day of freedom! (Don't make it a habit.)")
					elseif roll < foolParentsChance + 0.40 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤒 Parents didn't buy it. Off to school you go!")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.caught_faking = true
						state:AddFeed("🤒 Busted! You got in big trouble for lying.")
					end
				end,
			},
			{
				text = "Anxiety about school",
				effects = { Happiness = -4 },
				setFlags = { school_anxiety = true },
				feedText = "You told your parents you're nervous about something at school. They listened.",
			},
		},
	},
	{
		id = "homework_struggle",
		title = "Homework Headache",
		emoji = "📝",
		text = "You're stuck on a really hard homework assignment!",
		question = "How do you handle the difficult homework?",
		minAge = 6, maxAge = 12,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "school",
		tags = { "homework", "challenge", "learning" },
		
		choices = {
			{
				text = "Keep trying until you get it",
				effects = {},
				feedText = "You kept working at it...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.45 + (smarts / 200) then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.persistent = true
						state:AddFeed("📝 You figured it out! That feeling of accomplishment is amazing!")
					else
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📝 You tried hard but still struggled. At least you learned something.")
					end
				end,
			},
			{
				text = "Ask parents for help",
				effects = { Smarts = 3, Happiness = 2 },
				feedText = "Your parents helped explain it. Teamwork!",
			},
			{
				text = "Ask a friend for answers",
				effects = {},
				feedText = "You asked your friend...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📝 Your friend helped you understand it!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📝 Got the answers but didn't really learn anything...")
					else
						state:ModifyStat("Happiness", -4)
						state.Flags = state.Flags or {}
						state.Flags.caught_cheating = true
						state:AddFeed("📝 Teacher noticed the answers were the same. You got in trouble!")
					end
				end,
			},
			{
				text = "Give up and don't do it",
				effects = { Smarts = -2, Happiness = -3 },
				setFlags = { gives_up_easily = true },
				feedText = "You handed in incomplete homework. The teacher wasn't happy.",
			},
		},
	},
	{
		id = "recess_choices",
		title = "Recess Time!",
		emoji = "🛝",
		text = "The bell rings - it's recess! What do you do?",
		question = "How do you spend recess?",
		minAge = 5, maxAge = 11,
		baseChance = 0.4, -- CRITICAL FIX: Reduced from 0.7
		cooldown = 5, -- CRITICAL FIX: Increased from 1 to prevent spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "play",
		tags = { "recess", "play", "social" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{ text = "Play sports with friends", effects = { Health = 4, Happiness = 5 }, setFlags = { athletic = true }, feedText = "You ran around playing kickball until you were out of breath!" },
			{ text = "Swing on the swings", effects = { Happiness = 5, Health = 2 }, feedText = "Higher and higher! You tried to touch the clouds." },
			{ text = "Play imagination games", effects = { Happiness = 5, Smarts = 2 }, setFlags = { imaginative = true }, feedText = "You and your friends created epic adventures!" },
			{ text = "Stay inside and read", effects = { Smarts = 4, Happiness = 2 }, setFlags = { bookworm = true }, feedText = "The library is quiet and peaceful during recess." },
		},
	},
	{
		id = "new_sibling_adjustment",
		title = "Sibling Struggles",
		emoji = "👶",
		text = "Your younger sibling is driving you crazy!",
		question = "What's the conflict about?",
		minAge = 4, maxAge = 12,
		baseChance = 0.4,
		cooldown = 3,
		requiresFlags = { has_younger_sibling = true },
		
		stage = STAGE,
		ageBand = "childhood",
		category = "family",
		tags = { "sibling", "conflict", "family" },
		
		choices = {
			{ text = "They're touching my stuff!", effects = { Happiness = -4 }, setFlags = { protective_of_things = true }, feedText = "You had to hide your favorite toys. Annoying!" },
			{ text = "They're getting all the attention", effects = { Happiness = -5 }, setFlags = { jealous = true }, feedText = "You feel invisible sometimes. It's not fair." },
			{ text = "Actually started playing together", effects = { Happiness = 5 }, setFlags = { good_sibling = true }, feedText = "You discovered having a sibling can be fun!" },
			{ text = "Had a big fight", effects = { Happiness = -6 }, feedText = "Things got heated. You both got in trouble." },
		},
	},
	{
		id = "learned_ride_scooter",
		title = "Scooter Skills",
		emoji = "🛴",
		text = "You got a scooter! Time to learn to ride it.",
		question = "How do you do on the scooter?",
		minAge = 5, maxAge = 9,
		baseChance = 0.35,
		cooldown = 3,
		
		stage = STAGE,
		ageBand = "childhood",
		category = "skills",
		tags = { "scooter", "balance", "outdoors" },
		-- CRITICAL FIX: Random scooter learning outcome
		choices = {
			{
				text = "Zoom around immediately",
				effects = {},
				feedText = "You pushed off and tried to go fast...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Health", 3)
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.scooter_pro = true
						state:AddFeed("🛴 Natural talent! You're zooming around the neighborhood!")
					elseif roll < 0.75 then
						state:ModifyStat("Health", -3)
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🛴 A few crashes but you got the hang of it!")
					else
						state:ModifyStat("Health", -6)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🛴 Major wipeout! Scraped knee but you'll try again.")
					end
				end,
			},
			{
				text = "Take it slow and careful",
				effects = {},
				feedText = "You started slow...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Health", 2)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.can_ride_scooter = true
						state:AddFeed("🛴 You learned safely! Now you can cruise around.")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🛴 Still practicing but getting more confident!")
					end
				end,
			},
		},
	},
	{
		id = "art_class_project",
		title = "Art Class Creation",
		emoji = "🎨",
		text = "Art class project time! What do you create?",
		question = "What's your masterpiece?",
		minAge = 5, maxAge = 12,
		baseChance = 0.6,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "creative",
		tags = { "art", "creativity", "school" },
		careerTags = { "creative" },
		-- CRITICAL FIX: Random art outcome
		choices = {
			{
				text = "A detailed drawing",
				effects = {},
				hintCareer = "creative",
				feedText = "You focused on your drawing...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Looks", 3)
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.artistic_talent = true
						state:AddFeed("🎨 Incredible! The teacher displayed it on the wall!")
					elseif roll < 0.70 then
						state:ModifyStat("Looks", 1)
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🎨 Nice work! You're proud of your creation.")
					else
						state:ModifyStat("Happiness", 1)
						state:AddFeed("🎨 It didn't turn out like you imagined, but you tried!")
					end
				end,
			},
			{
				text = "A messy finger painting",
				effects = { Happiness = 5, Looks = -1 },
				feedText = "Paint everywhere! Including on you. But it was fun!",
			},
			{
				text = "A creative sculpture",
				effects = {},
				feedText = "You built something with clay and paper...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎨 Your 3D creation impressed everyone!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🎨 It fell apart a bit but the idea was cool!")
					end
				end,
			},
		},
	},
	{
		id = "school_nurse_visit",
		title = "Visit to the Nurse",
		emoji = "🏥",
		text = "You're at the school nurse's office!",
		question = "Why did you need to see the nurse?",
		minAge = 5, maxAge = 12,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "health",
		tags = { "nurse", "health", "school" },
		-- CRITICAL FIX: Random nurse visit - you don't choose what happened to you
		choices = {
			{
				text = "Playground injury",
				effects = {},
				feedText = "The nurse looks at your injury...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Health", -2)
						state:AddFeed("🏥 Just a scrape! Band-aid and you're good to go.")
					elseif roll < 0.80 then
						state:ModifyStat("Health", -5)
						state:AddFeed("🏥 Needed an ice pack for the bruise. No PE today.")
					else
						state:ModifyStat("Health", -8)
						state:AddFeed("🏥 Had to call your parents. This needs more than a band-aid.")
					end
				end,
			},
			{
				text = "Feeling sick during class",
				effects = {},
				feedText = "The nurse checks on you...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Health", -4)
						state:AddFeed("🏥 Parents came to pick you up. Home to rest.")
					elseif roll < 0.70 then
						state:ModifyStat("Health", -2)
						state:AddFeed("🏥 Just needed some water and rest. Back to class!")
					else
						state:AddFeed("🏥 False alarm. You felt better almost immediately.")
					end
				end,
			},
			{
				text = "Headache",
				effects = { Health = -2, Happiness = -1 },
				feedText = "The nurse gave you some water and let you rest. Feeling better now.",
			},
		},
	},
	{
		id = "classroom_disruption",
		title = "Class Clown Moment",
		emoji = "🤡",
		text = "You did something silly that disrupted the whole class!",
		question = "What happened?",
		minAge = 6, maxAge = 12,
		baseChance = 0.4,
		cooldown = 3,
		
		stage = STAGE,
		ageBand = "childhood",
		category = "behavior",
		tags = { "class_clown", "trouble", "school" },
		-- CRITICAL FIX: Random consequences for disruption
		choices = {
			{
				text = "Made everyone laugh",
				effects = {},
				feedText = "The class burst into laughter...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.class_clown = true
						state:AddFeed("🤡 Even the teacher cracked a smile. You're the class hero!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🤡 Got a warning but it was worth it for the laughs.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤡 Teacher wasn't amused. Timeout for you!")
					end
				end,
			},
			{
				text = "Made a huge mess",
				effects = {},
				feedText = "Things got messy...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🤡 Had to clean it up but no real consequences.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🤡 Big trouble! Note sent home to parents.")
					end
				end,
			},
			{
				text = "Got sent to the principal",
				effects = { Happiness = -5 },
				setFlags = { troublemaker = true },
				feedText = "That's a trip to the principal's office. Not fun.",
			},
		},
	},
	{
		id = "learning_alphabet",
		title = "ABC's",
		emoji = "🔤",
		text = "You're learning the alphabet! All 26 letters.",
		question = "How quickly do you learn your ABC's?",
		minAge = 2, maxAge = 5,
		oneTime = true,
		
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "development",
		tags = { "alphabet", "learning", "development" },
		
		choices = {
			{ text = "Sing the ABC song perfectly!", effects = { Smarts = 5, Happiness = 4 }, setFlags = { knows_alphabet = true }, feedText = "A-B-C-D-E-F-G... You've got it memorized!" },
			{ text = "Know most of the letters", effects = { Smarts = 3, Happiness = 3 }, setFlags = { knows_alphabet = true }, feedText = "LMNOP is still a blur but you're getting there!" },
			{ text = "Still learning", effects = { Smarts = 1, Happiness = 2 }, feedText = "Letters are tricky but practice makes perfect!" },
		},
	},
	{
		id = "playground_king",
		title = "King of the Playground",
		emoji = "👑",
		text = "You've become one of the popular kids at recess!",
		question = "How do you use your popularity?",
		minAge = 6, maxAge = 11,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "social",
		tags = { "popularity", "social", "leadership" },
		
		choices = {
			{ text = "Include everyone in games", effects = { Happiness = 6 }, setFlags = { inclusive = true }, feedText = "You made sure nobody was left out. Everyone likes you!" },
			{ text = "Only play with certain kids", effects = { Happiness = 3 }, setFlags = { exclusive = true }, feedText = "You stuck with your close group." },
			{ text = "Pick teams for games", effects = { Happiness = 4, Smarts = 2 }, setFlags = { natural_leader = true }, feedText = "You became the one who organized everything!" },
			{ text = "Use popularity to be mean", effects = { Happiness = -3 }, setFlags = { bully = true }, feedText = "Being mean to others didn't feel as good as you thought..." },
		},
	},
	{
		id = "pet_death",
		title = "Losing a Pet",
		emoji = "🌈",
		text = "Your beloved pet passed away...",
		question = "How do you cope with the loss?",
		minAge = 5, maxAge = 12,
		baseChance = 0.45,
		cooldown = 6,
		requiresFlags = { has_pet = true },
		
		stage = STAGE,
		ageBand = "childhood",
		category = "loss",
		tags = { "death", "grief", "pets" },
		
		onResolve = function(state)
			state.Flags = state.Flags or {}
			state.Flags.has_pet = nil
			state.Flags.has_dog = nil
			state.Flags.has_cat = nil
			state.Flags.has_fish = nil
			state.Flags.has_small_pet = nil
		end,
		
		choices = {
			{ text = "Cry and mourn deeply", effects = { Happiness = -10 }, setFlags = { experienced_loss = true, mourning = true }, feedText = "You'll never forget your friend. It hurts so much." },
			{ text = "Hold a little funeral", effects = { Happiness = -6 }, setFlags = { experienced_loss = true }, feedText = "You said goodbye properly. It helped a little." },
			{ text = "Draw pictures to remember them", effects = { Happiness = -4, Smarts = 2 }, setFlags = { processes_through_art = true }, feedText = "Your drawings help keep their memory alive." },
			{ text = "Ask for a new pet right away", effects = { Happiness = -3 }, feedText = "A new friend can help, but you still miss the old one." },
		},
	},
	{
		id = "grandparent_visit",
		title = "Grandparent Time",
		emoji = "👴",
		text = "Your grandparents are visiting!",
		question = "What do you do together?",
		minAge = 3, maxAge = 12,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "family",
		tags = { "grandparents", "family", "memories" },
		
		choices = {
			{ text = "Listen to their stories", effects = { Happiness = 5, Smarts = 3 }, setFlags = { loves_grandparents = true }, feedText = "Their stories from the old days are fascinating!" },
			{ text = "Bake cookies together", effects = { Happiness = 7 }, feedText = "Nothing beats grandma's cookies. You're learning the secret recipe!" },
			{ text = "Play card games", effects = { Happiness = 5, Smarts = 2 }, feedText = "Go Fish! Or maybe they're teaching you poker..." },
			{ text = "Get spoiled with treats and gifts", effects = { Happiness = 8, Money = 15 }, feedText = "Grandparents always spoil you! Extra dessert and pocket money." },
		},
	},
	{
		id = "caught_curse_word",
		title = "Bad Word!",
		emoji = "🤭",
		text = "You said a bad word and an adult heard you!",
		question = "What happened?",
		minAge = 4, maxAge = 10,
		baseChance = 0.4,
		cooldown = 3,
		
		stage = STAGE,
		ageBand = "childhood",
		category = "behavior",
		tags = { "swearing", "trouble", "learning" },
		
		choices = {
			{ text = "Didn't know it was bad!", effects = { Happiness = -2 }, feedText = "You learned that word means something bad. Good to know!" },
			{ text = "Repeated it from TV", effects = { Happiness = -3 }, feedText = "Maybe don't repeat everything you hear on TV..." },
			{ text = "Heard it from an older kid", effects = { Happiness = -2 }, feedText = "Older kids know bad words. Now you do too." },
			{ text = "Actually knew it was bad", effects = { Happiness = -5 }, setFlags = { rebellious = true }, feedText = "You knew better! Big trouble for that one." },
		},
	},
	{
		id = "childhood_fear",
		title = "Facing a Fear",
		emoji = "😨",
		text = "You have to face one of your fears!",
		question = "What are you afraid of?",
		minAge = 4, maxAge = 10,
		baseChance = 0.4,
		cooldown = 3,
		
		stage = STAGE,
		ageBand = "childhood",
		category = "psychology",
		tags = { "fear", "growth", "courage" },
		-- CRITICAL FIX: Random outcome when facing fears
		choices = {
			{
				text = "The dark",
				effects = {},
				feedText = "You faced the darkness...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.overcame_fear_dark = true
						state:AddFeed("😨 You survived the dark! It's not so scary anymore.")
					else
						state:ModifyStat("Happiness", -3)
						state.Flags = state.Flags or {}
						state.Flags.fears_dark = true
						state:AddFeed("😨 Still scary! Nightlight stays on.")
					end
				end,
			},
			{
				text = "Spiders",
				effects = {},
				feedText = "You encountered a spider...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("😨 You let the spider outside! Not so bad.")
					else
						state:ModifyStat("Happiness", -4)
						state.Flags = state.Flags or {}
						state.Flags.fears_spiders = true
						state:AddFeed("😨 NOPE! Spider fear confirmed. You screamed and ran.")
					end
				end,
			},
			{
				text = "Heights",
				effects = {},
				feedText = "You had to climb high...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", 2)
						state:AddFeed("😨 You looked down and didn't panic! Progress!")
					else
						state:ModifyStat("Happiness", -3)
						state.Flags = state.Flags or {}
						state.Flags.fears_heights = true
						state:AddFeed("😨 Too high! Froze up and needed help getting down.")
					end
				end,
			},
			{
				text = "Dogs",
				effects = {},
				feedText = "You met a big dog...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.animal_lover = true
						state:AddFeed("😨 The dog was friendly! You pet it and now want one!")
					else
						state:ModifyStat("Happiness", -2)
						state.Flags = state.Flags or {}
						state.Flags.fears_dogs = true
						state:AddFeed("😨 It barked at you! Dogs are still scary.")
					end
				end,
			},
		},
	},
	{
		id = "making_up_stories",
		title = "Storyteller",
		emoji = "📖",
		text = "You've been making up elaborate stories and sharing them!",
		question = "What kind of stories do you tell?",
		minAge = 5, maxAge = 11,
		baseChance = 0.4,
		cooldown = 3,
		
		stage = STAGE,
		ageBand = "childhood",
		category = "creative",
		tags = { "storytelling", "imagination", "creative" },
		careerTags = { "creative", "entertainment" },
		
		choices = {
			{ text = "Adventure stories with you as the hero", effects = { Happiness = 5, Smarts = 2 }, setFlags = { storyteller = true }, hintCareer = "creative", feedText = "Your epic tales have everyone listening!" },
			{ text = "Lies that got out of control", effects = { Happiness = -3 }, setFlags = { compulsive_liar = true }, feedText = "Your 'stories' got you in trouble. Some were believed!" },
			{ text = "Funny stories that make people laugh", effects = { Happiness = 6 }, setFlags = { funny = true }, hintCareer = "entertainment", feedText = "Your comedy stories are a hit!" },
			{ text = "Scary stories at sleepovers", effects = { Happiness = 4 }, setFlags = { loves_horror = true }, feedText = "Your scary stories gave everyone nightmares!" },
		},
	},
	{
		id = "childhood_collection",
		title = "Collector's Corner",
		emoji = "🏆",
		text = "You've started collecting something!",
		question = "What do you collect?",
		minAge = 6, maxAge = 12,
		oneTime = true,
		baseChance = 0.35,
		
		stage = STAGE,
		ageBand = "childhood",
		category = "hobbies",
		tags = { "collecting", "hobby", "organization" },
		
		choices = {
			{ text = "Trading cards", effects = { Happiness = 5, Smarts = 2 }, setFlags = { card_collector = true }, feedText = "Your card collection is growing! Gotta catch em all!" },
			{ text = "Rocks and minerals", effects = { Happiness = 4, Smarts = 4 }, setFlags = { rock_collector = true }, hintCareer = "science", feedText = "You're becoming a young geologist!" },
			{ text = "Stuffed animals", effects = { Happiness = 6 }, setFlags = { plushie_collector = true }, feedText = "Your bed is covered in stuffed animals!" },
			{ text = "Coins", effects = { Happiness = 3, Smarts = 3, Money = 10 }, setFlags = { coin_collector = true }, hintCareer = "finance", feedText = "Some of these old coins might be valuable!" },
			{ text = "Bugs (or bug corpses)", effects = { Happiness = 4, Smarts = 3 }, setFlags = { bug_collector = true }, hintCareer = "science", feedText = "Eww but also cool! You're learning about insects." },
		},
	},
	{
		id = "sharing_lesson",
		title = "Learning to Share",
		emoji = "🤝",
		text = "Someone wants to play with your favorite toy!",
		question = "Do you share?",
		minAge = 3, maxAge = 7,
		baseChance = 0.6,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "early_childhood",
		category = "social",
		tags = { "sharing", "social_skills", "empathy" },
		
		choices = {
			{ text = "Share happily", effects = { Happiness = 4, Smarts = 2 }, setFlags = { generous = true }, feedText = "Sharing is caring! You made a friend happy." },
			{ text = "Share reluctantly", effects = { Happiness = 1 }, feedText = "You shared but kept a close eye on it the whole time." },
			{ text = "Refuse to share", effects = { Happiness = 2 }, setFlags = { possessive = true }, feedText = "It's YOUR toy. They can play with something else." },
			{ text = "Take turns instead", effects = { Happiness = 3, Smarts = 3 }, setFlags = { fair = true }, feedText = "Taking turns is a good compromise!" },
		},
	},
	{
		id = "first_loose_tooth_eating",
		title = "Swallowed Tooth!",
		emoji = "🦷",
		text = "You were eating and accidentally swallowed your loose tooth!",
		question = "What do you do about the tooth fairy?",
		minAge = 5, maxAge = 8,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "health",
		tags = { "tooth", "accident", "funny" },
		
		choices = {
			{ text = "Write a letter to the tooth fairy", effects = { Happiness = 5, Money = 5 }, feedText = "The tooth fairy accepted your apology letter!" },
			{ text = "Cry - no tooth fairy visit!", effects = { Happiness = -4 }, feedText = "It's okay, the tooth fairy understood." },
			{ text = "Draw a picture of the tooth instead", effects = { Happiness = 4, Smarts = 2, Money = 5 }, feedText = "Creative solution! The tooth fairy appreciated the art." },
			{ text = "Parents explain teeth dissolve safely", effects = { Happiness = 2, Smarts = 3 }, feedText = "Good to know you won't have a tooth in your tummy forever!" },
		},
	},
	{
		id = "caught_picking_nose",
		title = "Embarrassing Moment",
		emoji = "😳",
		text = "You got caught doing something embarrassing!",
		question = "What happened?",
		minAge = 4, maxAge = 10,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		stage = STAGE,
		ageBand = "childhood",
		category = "embarrassment",
		tags = { "embarrassing", "social", "learning" },
		
		choices = {
			{ text = "Picking your nose", effects = { Happiness = -3, Looks = -1 }, feedText = "Everyone saw! Use a tissue next time!" },
			{ text = "Falling in front of everyone", effects = { Happiness = -3, Health = -1 }, feedText = "Epic wipeout! At least nothing was broken." },
			{ text = "Calling the teacher 'Mom'", effects = { Happiness = -4 }, feedText = "The whole class laughed... you'll never live it down!" },
			{ text = "Wetting your pants", effects = { Happiness = -6 }, setFlags = { embarrassed = true }, feedText = "The worst! But you survived and everyone eventually forgot." },
		},
	},
	{
		id = "first_cooking_attempt",
		title = "Little Chef",
		emoji = "👨‍🍳",
		text = "You tried to make something in the kitchen!",
		question = "What did you attempt to make?",
		minAge = 6, maxAge = 12,
		baseChance = 0.4,
		cooldown = 3,
		
		stage = STAGE,
		ageBand = "childhood",
		category = "skills",
		tags = { "cooking", "independence", "kitchen" },
		-- CRITICAL FIX: Random cooking outcome
		choices = {
			{
				text = "Cereal (the safe choice)",
				effects = {},
				feedText = "You poured yourself cereal...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.80 then
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.can_make_cereal = true
						state:AddFeed("👨‍🍳 Success! You're officially independent at breakfast.")
					else
						state:ModifyStat("Happiness", -1)
						state:AddFeed("👨‍🍳 Spilled milk everywhere but you cleaned it up. Learning!")
					end
				end,
			},
			{
				text = "A sandwich",
				effects = {},
				feedText = "You attempted a sandwich...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.can_make_sandwich = true
						state:AddFeed("👨‍🍳 Pretty good sandwich! Future chef potential!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("👨‍🍳 Messy but edible. You'll get better with practice!")
					end
				end,
			},
			{
				text = "Something on the stove (yikes)",
				effects = {},
				feedText = "You tried using the stove...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Smarts", 4)
						state:AddFeed("👨‍🍳 Incredible! You actually made something good!")
					elseif roll < 0.55 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("👨‍🍳 Burnt but safe. Good learning experience.")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("👨‍🍳 Smoke alarm went off! Parents are not happy.")
					else
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("👨‍🍳 Got a minor burn. Kitchen privileges revoked!")
					end
				end,
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: EXPANDED SPORTS EVENTS WITH BRANCHING PATHS
	-- User feedback: "have some more events that popup that let u be like nah or taking sports more seriously"
	-- These events wire sports interest into future athlete career path
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "sports_interest_growing",
		title = "Getting Serious About Sports",
		emoji = "🏆",
		text = "You've been playing sports for a while now, and your coach noticed something - you're actually pretty good! Your coach wants to talk to your parents about putting you in a more competitive league.",
		question = "How do you feel about taking sports more seriously?",
		minAge = 8, maxAge = 12,
		baseChance = 0.35,
		cooldown = 8,
		requiresFlags = { school_athlete = true },
		blockedByFlags = { quit_sports = true, elite_athlete_kid = true },
		
		choices = {
			{
				text = "YES! I want to be the best!",
				effects = { Happiness = 10, Health = 8 },
				feedText = "You're all in on sports!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.serious_about_sports = true
					state.Flags.elite_athlete_kid = true
					state.Flags.athlete_potential = true
					state:AddFeed("🏆 Your parents sign you up for travel team! Early practices, weekend tournaments - but you're LOVING it!")
				end,
			},
			{
				text = "I like sports but not THAT seriously",
				effects = { Happiness = 5, Health = 3 },
				feedText = "Keeping it casual...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.casual_athlete = true
					state:AddFeed("🏆 You stay on the regular team. Sports are fun but so are other things!")
				end,
			},
			{
				text = "Actually, I'm not that into sports anymore",
				effects = { Happiness = 2 },
				feedText = "Sports aren't really your thing...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.quit_sports = true
					state.Flags.school_athlete = nil
					state:AddFeed("🏆 You tell your coach you're done. More time for other hobbies!")
				end,
			},
		},
	},
	
	{
		id = "sports_talent_discovered",
		title = "Natural Athletic Talent!",
		emoji = "⭐",
		text = "During gym class, the PE teacher pulled you aside. 'Kid, you've got something special. Have you ever thought about joining a sports team?' You haven't really tried sports yet, but apparently you're a natural athlete.",
		question = "Do you want to explore this talent?",
		minAge = 7, maxAge = 11,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		blockedByFlags = { school_athlete = true, quit_sports = true },
		-- CRITICAL FIX: Wire passion flags! If player discovered athletic passion, this is MORE likely!
		eligibility = function(state)
			local flags = state.Flags or {}
			-- If player has passionate_athlete flag, ALWAYS eligible (passion pays off!)
			if flags.passionate_athlete or flags.athletic_talent or flags.sports_interest or flags.likes_sports then
				return true -- Passion makes you eligible regardless of Health!
			end
			-- Otherwise need good health
			local health = (state.Stats and state.Stats.Health) or 50
			return health >= 55
		end,
		-- CRITICAL FIX: Higher weight for passionate athletes
		weight = function(state)
			local flags = state.Flags or {}
			if flags.passionate_athlete or flags.likes_sports then
				return 25 -- Much more likely to trigger!
			end
			return 12 -- Base weight
		end,
		
		choices = {
			{
				text = "Yeah! Let's see what I can do!",
				effects = { Health = 5, Happiness = 8 },
				feedText = "Time to discover your athletic potential!",
				onResolve = function(state)
					local sports = { "soccer", "basketball", "baseball", "track", "swimming" }
					local sport = sports[math.random(#sports)]
					state.Flags = state.Flags or {}
					state.Flags.school_athlete = true
					state.Flags.natural_athlete = true
					state.Flags["plays_" .. sport] = true
					state:AddFeed(string.format("⭐ You tried out for %s and made the team immediately! Coach says you're a natural!", sport))
				end,
			},
			{
				text = "Nah, sports aren't really my thing",
				effects = { Happiness = 2, Smarts = 2 },
				feedText = "You'd rather focus on other interests.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.not_interested_sports = true
					state:AddFeed("⭐ You politely decline. Lots of other ways to be active and have fun!")
				end,
			},
			{
				text = "Maybe later... I'm nervous",
				effects = { Happiness = 1 },
				feedText = "The idea makes you anxious.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.sports_curious = true
					state:AddFeed("⭐ You say maybe next year. The PE teacher nods understandingly.")
				end,
			},
		},
	},
	
	{
		id = "sports_first_competition",
		title = "Your First Big Competition!",
		emoji = "🥇",
		text = "Your first real tournament is this weekend! Your parents took the day off work, grandparents are coming, everyone's excited. The pressure is ON. How do you handle it?",
		question = "Big game nerves - what's your mindset?",
		minAge = 7, maxAge = 13,
		baseChance = 0.4,
		cooldown = 5,
		requiresFlags = { school_athlete = true },
		blockedByFlags = { first_competition_done = true },
		
		choices = {
			{
				text = "I'm SO ready! Let's WIN!",
				effects = { Health = 3 },
				feedText = "You're pumped and confident!",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					state.Flags.first_competition_done = true
					if roll <= 40 then
						state:ModifyStat("Happiness", 15)
						state.Flags.competition_winner = true
						state:AddFeed("🥇 YOU WON! First place! Your family goes CRAZY! Best day ever!")
					elseif roll <= 75 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🥇 You did great! Didn't win but played your heart out. Family is SO proud!")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags.choked_under_pressure = true
						state:AddFeed("🥇 Nerves got the best of you. You froze up. But you learned something important about pressure.")
					end
				end,
			},
			{
				text = "I'm terrified but I'll try my best",
				effects = { Happiness = -2 },
				feedText = "You're nervous but brave...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					state.Flags.first_competition_done = true
					if roll <= 50 then
						state:ModifyStat("Happiness", 10)
						state.Flags.overcame_nerves = true
						state:AddFeed("🥇 Your nerves disappeared once you started! You played amazing!")
					else
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🥇 Shaky start but you pushed through. Character building!")
					end
				end,
			},
			{
				text = "Actually... I don't want to go",
				effects = { Happiness = -8 },
				feedText = "The pressure is too much.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.first_competition_done = true
					state.Flags.skipped_first_competition = true
					state:ModifyStat("Happiness", -10)
					state:AddFeed("🥇 You told your parents you were sick. They know you weren't. Awkward silence in the car.")
				end,
			},
		},
	},
	
	{
		id = "sports_burnout_warning",
		title = "Feeling Burned Out",
		emoji = "😩",
		text = "Practice every day, games every weekend, no time for friends or video games. You used to love this sport but now... you're just tired. Your parents noticed you've been dragging.",
		question = "What do you want to do?",
		minAge = 9, maxAge = 14,
		baseChance = 0.4,
		cooldown = 8,
		requiresFlags = { elite_athlete_kid = true },
		blockedByFlags = { handled_burnout = true, quit_sports = true },
		
		choices = {
			{
				text = "Push through - winners don't quit!",
				effects = { Health = -5 },
				feedText = "No pain no gain...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					state.Flags.handled_burnout = true
					if roll <= 40 then
						state:ModifyStat("Happiness", 5)
						state.Flags.mental_toughness = true
						state:AddFeed("😩 The hard work paid off! You found a second wind and love the sport again!")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags.sports_burnout = true
						state:AddFeed("😩 You're running on empty. Something has to change.")
					end
				end,
			},
			{
				text = "Ask to take a break",
				effects = { Happiness = 5 },
				feedText = "Maybe some time off will help...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.handled_burnout = true
					state.Flags.took_sports_break = true
					state:ModifyStat("Happiness", 8)
					state:AddFeed("😩 Your parents understand. A month off helped you remember why you love the sport!")
				end,
			},
			{
				text = "I want to quit - this isn't fun anymore",
				effects = { Happiness = 3 },
				feedText = "Time to walk away...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.handled_burnout = true
					state.Flags.quit_sports = true
					state.Flags.elite_athlete_kid = nil
					state.Flags.school_athlete = nil
					state:AddFeed("😩 You told coach you're done. It was hard but you feel relieved. Time for new adventures!")
				end,
			},
		},
	},
	
	{
		id = "sports_scholarship_talk",
		title = "Could Sports Be Your Future?",
		emoji = "🎓",
		text = "Your coach pulled your parents aside after the game. 'Your kid has real talent. If they keep at it, a college scholarship could be in their future. Maybe even beyond...' You overhear the conversation.",
		question = "A sports scholarship? Professional athlete? What do you think?",
		minAge = 11, maxAge = 14,
		baseChance = 0.35,
		cooldown = 15,
		oneTime = true,
		requiresFlags = { elite_athlete_kid = true },
		blockedByFlags = { quit_sports = true },
		requiresStats = { Health = 65 },
		
		choices = {
			{
				text = "That's my DREAM! I'm going all in!",
				effects = { Happiness = 15, Health = 5 },
				feedText = "You've found your calling!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.athlete_career_path = true
					state.Flags.scholarship_potential = true
					state.Flags.dreams_of_going_pro = true
					state:AddFeed("🎓 You start training harder than ever! Early morning workouts, special coaching - you're chasing the dream!")
				end,
			},
			{
				text = "Cool but I want other options too",
				effects = { Happiness = 8, Smarts = 3 },
				feedText = "Keeping your options open...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.balanced_athlete = true
					state.Flags.scholarship_potential = true
					state:AddFeed("🎓 You keep playing but also focus on school. Sports AND brains - why not both?")
				end,
			},
			{
				text = "I don't want that kind of pressure",
				effects = { Happiness = 2, Smarts = 2 },
				feedText = "That's too much to think about...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.casual_athlete = true
					state.Flags.elite_athlete_kid = nil
					state:AddFeed("🎓 You tell your parents you just want to play for fun. No pressure. They're supportive.")
				end,
			},
		},
	},

-- ════════════════════════════════════════════════════════════════════════════
-- MASSIVE EXPANSION: NEW CHILDHOOD EVENTS (Ages 5-12)
-- These create rich, varied childhood experiences with lasting impacts
-- ════════════════════════════════════════════════════════════════════════════

	{
		id = "childhood_loose_tooth",
		title = "Loose Tooth!",
		emoji = "🦷",
		textVariants = {
			"Your tooth is wiggling! It's so loose!",
			"One of your baby teeth is about to fall out!",
			"Wiggle wiggle... your tooth is barely hanging on!",
			"The tooth fairy is coming soon!",
		},
		text = "Your tooth is wiggling! It's so loose!",
		question = "How do you handle the loose tooth?",
		minAge = 5, maxAge = 10,
		baseChance = 0.35,
		cooldown = 3,
		category = "childhood",
		tags = { "childhood", "milestone", "teeth" },
		
		choices = {
			{
				text = "😱 Leave it alone!",
				effects = { Happiness = 2 },
				setFlags = { lost_baby_tooth = true },
				feedText = "🦷 It fell out on its own while you were eating! Surprise!",
			},
			{
				text = "✊ Pull it out yourself!",
				effects = { Happiness = 5 },
				setFlags = { lost_baby_tooth = true, brave_kid = true },
				feedText = "🦷 YANK! Out it came! You're so brave! Blood everywhere tho.",
			},
			{
				text = "🍎 Bite an apple!",
				effects = { Happiness = 4, Health = 2 },
				setFlags = { lost_baby_tooth = true, clever_problem_solver = true },
				feedText = "🦷 Apple trick worked! Out came the tooth!",
			},
			{
				text = "💵 Put it under pillow!",
				effects = { Happiness = 6, Money = 5 },
				setFlags = { lost_baby_tooth = true, believes_in_tooth_fairy = true },
				feedText = "🦷 The tooth fairy came! $5! Rich!",
			},
		},
	},

	{
		id = "childhood_school_photo_day",
		title = "School Photo Day!",
		emoji = "📸",
		textVariants = {
			"It's picture day! Everyone's dressed up nice!",
			"School photos are happening! Smile!",
			"Time for your yearbook photo!",
			"Picture day! Looking your best!",
		},
		text = "It's picture day! Everyone's dressed up nice!",
		question = "How does your photo turn out?",
		minAge = 5, maxAge = 12,
		baseChance = 0.45,
		cooldown = 4,
		category = "childhood",
		tags = { "childhood", "school", "photos" },
		
		choices = {
			{
				text = "😁 Perfect smile!",
				effects = { Happiness = 5, Looks = 2 },
				setFlags = { photogenic = true },
				feedText = "📸 Best photo ever! Your parents bought ALL the packages!",
			},
			{
				text = "😬 Awkward face",
				effects = { Happiness = -2, Looks = -1 },
				setFlags = { bad_school_photo = true },
				feedText = "📸 Oh no... this one's going in the 'embarrassing' pile.",
			},
			{
				text = "🤪 Silly face on purpose",
				effects = { Happiness = 6 },
				setFlags = { class_clown = true, funny_photos = true },
				feedText = "📸 Your parents weren't happy but YOU love it!",
			},
			{
				text = "😭 Blink right when they snap",
				effects = { Happiness = -3 },
				setFlags = { blinker_in_photos = true },
				feedText = "📸 Classic blink photo. At least retakes are free!",
			},
		},
	},

	{
		id = "childhood_recess_drama",
		title = "Recess Drama!",
		emoji = "🏃",
		textVariants = {
			"Drama at recess! Someone's being mean!",
			"Things got heated on the playground!",
			"There's a disagreement during recess games!",
			"Playground politics are INTENSE!",
		},
		text = "Drama at recess! Someone's being mean!",
		question = "What's happening?",
		minAge = 6, maxAge = 12,
		baseChance = 0.45,
		cooldown = 3,
		category = "childhood",
		tags = { "childhood", "social", "conflict" },
		
		choices = {
			{
				text = "🤝 Help resolve it",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { peacemaker = true, good_mediator = true },
				feedText = "🏃 You helped everyone calm down! Crisis averted!",
			},
			{
				text = "😤 Take sides",
				effects = { Happiness = 2 },
				setFlags = { loyal_friend = true },
				feedText = "🏃 You backed up your friend! Loyalty points!",
			},
			{
				text = "🚶 Walk away",
				effects = { Happiness = 3 },
				setFlags = { avoids_drama = true },
				feedText = "🏃 Not your problem! You went to play elsewhere.",
			},
			{
				text = "🗣️ Tell a teacher",
				effects = { Happiness = 1, Smarts = 1 },
				setFlags = { rule_follower = true },
				feedText = "🏃 Teacher handled it. The right thing to do!",
			},
		},
	},

	{
		id = "childhood_birthday_party",
		title = "Birthday Party!",
		emoji = "🎂",
		textVariants = {
			"Happy birthday! You're having a party!",
			"It's YOUR special day! Party time!",
			"Birthday party at your house!",
			"Cake, presents, friends - it's your birthday!",
		},
		text = "Happy birthday! You're having a party!",
		question = "What kind of party do you want?",
		minAge = 5, maxAge = 12,
		baseChance = 0.35,
		cooldown = 5,
		category = "childhood",
		tags = { "childhood", "birthday", "social" },
		
		choices = {
			{
				text = "🎈 Big party, all my friends!",
				effects = { Happiness = 10 },
				setFlags = { loves_parties = true, social_butterfly = true },
				feedText = "🎂 BEST PARTY EVER! So many presents! So much cake!",
			},
			{
				text = "👫 Small party, close friends only",
				effects = { Happiness = 7 },
				setFlags = { quality_over_quantity = true, close_friends = true },
				feedText = "🎂 Perfect size! Real friends, real fun!",
			},
			{
				text = "🎮 Gaming/movie party",
				effects = { Happiness = 8 },
				setFlags = { gamer_kid = true },
				feedText = "🎂 Video games and pizza! Best combo!",
			},
			{
				text = "🏠 Just family is fine",
				effects = { Happiness = 5 },
				setFlags = { family_oriented = true, introverted = true },
				feedText = "🎂 Quiet celebration but still special!",
			},
		},
	},

	{
		id = "childhood_first_crush",
		title = "First Crush!",
		emoji = "💕",
		textVariants = {
			"There's someone at school you really like...",
			"Your heart beats faster when THEY walk by!",
			"You think about them ALL the time!",
			"Is this... a crush?!",
		},
		text = "There's someone at school you really like...",
		question = "How do you handle these feelings?",
		minAge = 8, maxAge = 12,
		baseChance = 0.4,
		cooldown = 5,
		oneTime = true,
		category = "childhood",
		tags = { "childhood", "crush", "social" },
		blockedByFlags = { first_crush_happened = true },
		
		choices = {
			{
				text = "😳 Keep it secret forever",
				effects = { Happiness = 3 },
				setFlags = { first_crush_happened = true, keeps_feelings_secret = true },
				feedText = "💕 Your secret is safe. Heart flutters from afar!",
			},
			{
				text = "📝 Write them a note",
				effects = { Happiness = 5 },
				setFlags = { first_crush_happened = true, romantic_soul = true },
				feedText = "💕 'Do you like me? Circle yes or no.' SO brave!",
			},
			{
				text = "👫 Try to become friends first",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { first_crush_happened = true, smart_approach = true },
				feedText = "💕 Playing it cool! Friends first, see what happens!",
			},
			{
				text = "🤷 Crushes are dumb",
				effects = { Happiness = 1, Smarts = 1 },
				setFlags = { first_crush_happened = true, late_bloomer_romance = true },
				feedText = "💕 You're not interested in all that yet. Fair enough!",
			},
		},
	},

	{
		id = "childhood_talent_show",
		title = "School Talent Show!",
		emoji = "🌟",
		textVariants = {
			"The school talent show is coming! Will you perform?",
			"Everyone's showing off their talents! What about you?",
			"Talent show sign-ups! Do you have what it takes?",
			"It's time to shine at the talent show!",
		},
		text = "The school talent show is coming! Will you perform?",
		question = "What do you do?",
		minAge = 6, maxAge = 12,
		baseChance = 0.4,
		cooldown = 5,
		category = "childhood",
		tags = { "childhood", "talent", "performance" },
		
		choices = {
			{
				text = "🎤 Sing a song!",
				effects = { Happiness = 6 },
				setFlags = { performed_in_talent_show = true, likes_singing = true, stage_performer = true },
				feedText = "🌟 You sang your heart out! Standing ovation!",
			},
			{
				text = "🕺 Dance performance!",
				effects = { Happiness = 6, Health = 2 },
				setFlags = { performed_in_talent_show = true, likes_dancing = true, stage_performer = true },
				feedText = "🌟 Your moves were FIRE! The crowd went wild!",
			},
			{
				text = "🎭 Comedy routine!",
				effects = { Happiness = 7 },
				setFlags = { performed_in_talent_show = true, class_clown = true, comedian_potential = true },
				feedText = "🌟 You had everyone DYING laughing!",
			},
			{
				text = "😰 No way, too scary!",
				effects = { Happiness = -2 },
				setFlags = { stage_fright = true },
				feedText = "🌟 You watched from the audience. Maybe next year!",
			},
		},
	},

	{
		id = "childhood_summer_camp",
		title = "Summer Camp!",
		emoji = "🏕️",
		textVariants = {
			"Summer camp time! A whole week away from home!",
			"You're going to camp! Adventures await!",
			"Time for summer camp! Campfires and cabins!",
			"Pack your bags for summer camp!",
		},
		text = "Summer camp time! A whole week away from home!",
		question = "How does camp go?",
		minAge = 7, maxAge = 12,
		baseChance = 0.4,
		cooldown = 5,
		category = "childhood",
		tags = { "childhood", "camp", "summer" },
		
		choices = {
			{
				text = "🏆 Best week ever!",
				effects = { Happiness = 10, Health = 3 },
				setFlags = { loved_summer_camp = true, outdoor_kid = true, makes_friends_easily = true },
				feedText = "🏕️ Made camp friends! Learned survival skills! AMAZING!",
			},
			{
				text = "😢 Homesick the whole time",
				effects = { Happiness = -3 },
				setFlags = { got_homesick = true, attached_to_home = true },
				feedText = "🏕️ You missed home. Called parents crying. They picked you up early.",
			},
			{
				text = "😊 Mixed feelings",
				effects = { Happiness = 5 },
				setFlags = { camp_experience = true },
				feedText = "🏕️ Some fun, some boring. Overall decent experience!",
			},
			{
				text = "😤 Got in trouble",
				effects = { Happiness = 3 },
				setFlags = { camp_rebel = true, troublemaker = true },
				feedText = "🏕️ Pranks, rule-breaking... unforgettable camp stories!",
			},
		},
	},

	{
		id = "childhood_pet_want",
		title = "I Want a Pet!",
		emoji = "🐕",
		textVariants = {
			"You REALLY want a pet! Please please please!",
			"Every kid has a pet but YOU! Not fair!",
			"You've been begging for a pet for MONTHS!",
			"A pet would be your best friend!",
		},
		text = "You REALLY want a pet! Please please please!",
		question = "How do you convince your parents?",
		minAge = 5, maxAge = 12,
		baseChance = 0.4,
		cooldown = 5,
		category = "childhood",
		tags = { "childhood", "pets", "family" },
		blockedByFlags = { has_pet = true },
		
		choices = {
			{
				text = "📋 Make a responsibility plan",
				effects = { Smarts = 3, Happiness = 4 },
				setFlags = { asked_for_pet = true, responsible_approach = true },
				feedText = "🐕 You showed them a feeding schedule, cleaning plan - impressive!",
			},
			{
				text = "😭 Beg non-stop",
				effects = { Happiness = 2 },
				setFlags = { asked_for_pet = true, persistent = true },
				feedText = "🐕 Eventually they caved! Persistence pays off!",
			},
			{
				text = "💰 Offer to save allowance",
				effects = { Smarts = 2, Happiness = 3 },
				setFlags = { asked_for_pet = true, financially_aware = true },
				feedText = "🐕 You showed you're serious about commitment!",
			},
			{
				text = "🤷 Accept 'maybe someday'",
				effects = { Happiness = -2 },
				setFlags = { asked_for_pet = true, patient = true },
				feedText = "🐕 'When you're older' - the classic parent response.",
			},
		},
	},

	{
		id = "childhood_school_play",
		title = "School Play Auditions!",
		emoji = "🎭",
		textVariants = {
			"The school play needs actors! Will you audition?",
			"Drama club is putting on a show! Want a part?",
			"Theater tryouts are happening!",
			"Lights, camera, school play action!",
		},
		text = "The school play needs actors! Will you audition?",
		question = "Do you try out?",
		minAge = 7, maxAge = 12,
		baseChance = 0.4,
		cooldown = 5,
		category = "childhood",
		tags = { "childhood", "theater", "school" },
		
		choices = {
			{
				text = "🌟 Go for the lead role!",
				effects = { Happiness = 6 },
				setFlags = { auditioned_for_play = true, ambitious = true, theater_kid = true },
				feedText = "🎭 You got a main part! Memorizing SO many lines!",
			},
			{
				text = "😊 Any role is fine",
				effects = { Happiness = 5 },
				setFlags = { auditioned_for_play = true, theater_kid = true },
				feedText = "🎭 You're in the play! Small part but still exciting!",
			},
			{
				text = "🔧 Work backstage",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { backstage_crew = true, behind_scenes = true },
				feedText = "🎭 Lights, sound, props - backstage is where the magic happens!",
			},
			{
				text = "😰 Too scary, pass",
				effects = { Happiness = 1 },
				setFlags = { stage_fright = true },
				feedText = "🎭 You'll support from the audience!",
			},
		},
	},

	{
		id = "childhood_music_lessons",
		title = "Music Lessons Offer!",
		emoji = "🎵",
		textVariants = {
			"Your parents offer to get you music lessons!",
			"Want to learn an instrument?",
			"Music school is an option!",
			"You could be a musician!",
		},
		text = "Your parents offer to get you music lessons!",
		question = "What instrument do you pick?",
		minAge = 6, maxAge = 12,
		baseChance = 0.4,
		cooldown = 5,
		oneTime = true,
		category = "childhood",
		tags = { "childhood", "music", "hobbies" },
		careerTags = { "entertainment", "music" },
		blockedByFlags = { started_music_lessons = true },
		
		choices = {
			{
				text = "🎹 Piano - classic!",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { started_music_lessons = true, plays_piano = true, musical_talent = true, instrument_player = true, passionate_performer = true },
				hintCareer = "entertainment",
				feedText = "🎵 Learning piano! It's hard but rewarding!",
			},
			{
				text = "🎸 Guitar - rock star!",
				effects = { Happiness = 6 },
				setFlags = { started_music_lessons = true, plays_guitar = true, musical_talent = true, instrument_player = true, passionate_performer = true },
				hintCareer = "entertainment",
				feedText = "🎵 Guitar lessons! Already dreaming of concerts!",
			},
			{
				text = "🥁 Drums - let's make noise!",
				effects = { Happiness = 7 },
				setFlags = { started_music_lessons = true, plays_drums = true, musical_talent = true, instrument_player = true, passionate_performer = true },
				hintCareer = "entertainment",
				feedText = "🎵 DRUMS! Your neighbors are thrilled (not really)!",
			},
			{
				text = "🙅 No thanks",
				effects = { Happiness = 2 },
				setFlags = { declined_music_lessons = true },
				feedText = "🎵 Music isn't for you right now. That's okay!",
			},
		},
	},

	{
		id = "childhood_science_experiment",
		title = "Science Fair Project!",
		emoji = "🔬",
		textVariants = {
			"Science fair is coming! What will you create?",
			"Time to be a scientist! Project ideas?",
			"The science fair awaits your genius!",
			"Hypothesis time! Science fair project!",
		},
		text = "Science fair is coming! What will you create?",
		question = "What's your project about?",
		minAge = 7, maxAge = 12,
		baseChance = 0.4,
		cooldown = 4,
		category = "childhood",
		tags = { "childhood", "science", "school" },
		careerTags = { "science", "tech", "medical" },
		
		choices = {
			{
				text = "🌋 Volcano! Classic!",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { did_science_fair = true, loves_explosions = true, science_interest = true },
				hintCareer = "science",
				feedText = "🔬 Your volcano ERUPTED! Messy but amazing!",
			},
			{
				text = "🔋 Battery experiment",
				effects = { Happiness = 4, Smarts = 5 },
				setFlags = { did_science_fair = true, future_engineer = true, tech_savvy = true, science_interest = true },
				hintCareer = "tech",
				feedText = "🔬 You made electricity from a potato! GENIUS!",
			},
			{
				text = "🌱 Plant growth study",
				effects = { Happiness = 4, Smarts = 4 },
				setFlags = { did_science_fair = true, nature_lover = true, patient_scientist = true, science_interest = true },
				hintCareer = "science",
				feedText = "🔬 Weeks of observation paid off! Science!",
			},
			{
				text = "😅 Last minute poster",
				effects = { Happiness = 2, Smarts = 1 },
				setFlags = { did_science_fair = true, procrastinator = true },
				feedText = "🔬 Glitter and enthusiasm covered up the lack of effort!",
			},
		},
	},

	{
		id = "childhood_teacher_favorite",
		title = "Teacher's Pet?",
		emoji = "📚",
		textVariants = {
			"Your teacher seems to really like you!",
			"You're answering ALL the questions right!",
			"Teacher always calls on YOU!",
			"Is being teacher's favorite good or bad?",
		},
		text = "Your teacher seems to really like you!",
		question = "How do you feel about the extra attention?",
		minAge = 6, maxAge = 12,
		baseChance = 0.4,
		cooldown = 4,
		category = "childhood",
		tags = { "childhood", "school", "social" },
		requiresStats = { Smarts = 55 },
		
		choices = {
			{
				text = "😊 Love it! I'm smart!",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { teachers_pet = true, proud_student = true },
				feedText = "📚 You love being recognized for your hard work!",
			},
			{
				text = "😰 Embarrassing...",
				effects = { Happiness = -2, Smarts = 1 },
				setFlags = { shy_smart_kid = true },
				feedText = "📚 You wish they'd call on someone else sometimes!",
			},
			{
				text = "😎 Use it to my advantage",
				effects = { Happiness = 4, Smarts = 3 },
				setFlags = { strategic_student = true },
				feedText = "📚 Extra credit opportunities? Don't mind if I do!",
			},
			{
				text = "🤷 Just doing my best",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { humble_student = true },
				feedText = "📚 You just focus on learning. Recognition is a bonus!",
			},
		},
	},

	{
		id = "childhood_sick_day",
		title = "Sick Day!",
		emoji = "🤒",
		textVariants = {
			"You're not feeling well... sick day?",
			"Your stomach hurts! Or does it?",
			"Too sick for school? Maybe!",
			"You don't feel good this morning...",
		},
		text = "You're not feeling well... sick day?",
		question = "Are you really sick?",
		minAge = 5, maxAge = 12,
		baseChance = 0.45,
		cooldown = 3,
		category = "childhood",
		tags = { "childhood", "sick", "school" },
		
		choices = {
			{
				text = "😷 Yes, actually sick",
				effects = { Health = -5, Happiness = -3 },
				setFlags = { actually_sick = true },
				feedText = "🤒 You really are sick. Soup and rest all day.",
			},
			{
				text = "🎭 Faking it for fun day",
				effects = { Happiness = 6, Smarts = 2 },
				setFlags = { faked_sick = true, good_actor = true },
				feedText = "🤒 Oscar-worthy performance! Video games all day!",
			},
			{
				text = "🦸 Push through, go to school",
				effects = { Health = -2, Smarts = 2 },
				setFlags = { tough_kid = true, school_dedicated = true },
				feedText = "🤒 You powered through! But maybe should've stayed home...",
			},
			{
				text = "🤔 Not sure, let parent decide",
				effects = { Happiness = 2 },
				feedText = "🤒 Parent felt your forehead. Verdict: school!",
			},
		},
	},

	{
		id = "childhood_field_trip",
		title = "Field Trip!",
		emoji = "🚌",
		textVariants = {
			"FIELD TRIP DAY! No regular classes!",
			"The class is going somewhere exciting!",
			"Permission slip signed! Field trip time!",
			"Best day ever - field trip!",
		},
		text = "FIELD TRIP DAY! No regular classes!",
		question = "How does the field trip go?",
		minAge = 5, maxAge = 12,
		baseChance = 0.45,
		cooldown = 4,
		category = "childhood",
		tags = { "childhood", "school", "adventure" },
		
		choices = {
			{
				text = "🎉 Best day ever!",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { loves_field_trips = true },
				feedText = "🚌 You learned AND had fun! Perfect combo!",
			},
			{
				text = "🤢 Got bus sick",
				effects = { Happiness = -3, Health = -2 },
				setFlags = { motion_sickness = true },
				feedText = "🚌 The bus ride was rough... but the destination was worth it!",
			},
			{
				text = "😈 Got in trouble",
				effects = { Happiness = 3 },
				setFlags = { field_trip_troublemaker = true },
				feedText = "🚌 Wandered off, touched things you shouldn't... classic field trip!",
			},
			{
				text = "👫 Made a new friend!",
				effects = { Happiness = 6 },
				setFlags = { makes_friends_easily = true },
				feedText = "🚌 Sat next to someone new. Now you're buddies!",
			},
		},
	},

	{
		id = "childhood_video_game_addiction",
		title = "Gaming Obsession!",
		emoji = "🎮",
		textVariants = {
			"You can't stop playing video games!",
			"One more level... one more hour... one more day!",
			"Your parents say you play too much!",
			"Video games are taking over your life!",
		},
		text = "You can't stop playing video games!",
		question = "Can you find balance?",
		minAge = 7, maxAge = 12,
		baseChance = 0.45,
		cooldown = 4,
		category = "childhood",
		tags = { "childhood", "gaming", "hobby" },
		careerTags = { "esports", "tech", "entertainment" },
		
		choices = {
			{
				text = "🎮 Games are life!",
				effects = { Happiness = 5, Smarts = 2, Health = -2 },
				setFlags = { gamer_kid = true, game_obsessed = true, gamer = true, passionate_gamer = true, loves_games = true, gaming_interest = true },
				hintCareer = "entertainment",
				feedText = "🎮 You're SO good at games! Maybe too good...",
			},
			{
				text = "⚖️ Learn to balance",
				effects = { Happiness = 4, Smarts = 3, Health = 1 },
				setFlags = { gamer_kid = true, balanced_gamer = true, gamer = true, loves_games = true },
				hintCareer = "entertainment",
				feedText = "🎮 Games AND homework. Games AND outside time. Balance!",
			},
			{
				text = "📺 Only weekends",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { disciplined_gamer = true, gamer = true },
				feedText = "🎮 Parents made a rule. Weekends only. Fair enough.",
			},
			{
				text = "😤 Get grounded from games",
				effects = { Happiness = -4 },
				setFlags = { game_grounded = true },
				feedText = "🎮 You played too much and now... no games. Disaster!",
			},
		},
	},

	{
		id = "childhood_allowance",
		title = "Allowance Talk!",
		emoji = "💵",
		textVariants = {
			"Your parents offer you an allowance!",
			"Time to learn about money management!",
			"Weekly allowance! What will you do with it?",
			"Your first regular income!",
		},
		text = "Your parents offer you an allowance!",
		question = "What's your money strategy?",
		minAge = 6, maxAge = 12,
		baseChance = 0.4,
		cooldown = 5,
		oneTime = true,
		category = "childhood",
		tags = { "childhood", "money", "learning" },
		careerTags = { "finance", "business" },
		blockedByFlags = { gets_allowance = true },
		
		choices = {
			{
				text = "💰 Save everything!",
				effects = { Happiness = 3, Smarts = 4, Money = 20 },
				setFlags = { gets_allowance = true, childhood_saver = true, financially_responsible = true, future_investor = true, money_smart = true },
				hintCareer = "finance",
				feedText = "💵 Piggy bank growing! You're gonna be RICH!",
			},
			{
				text = "🍬 Spend it immediately!",
				effects = { Happiness = 6, Money = 5 },
				setFlags = { gets_allowance = true, childhood_spender = true },
				feedText = "💵 Candy, toys, MORE candy! Money is for fun!",
			},
			{
				text = "⚖️ Save half, spend half",
				effects = { Happiness = 4, Smarts = 3, Money = 10 },
				setFlags = { gets_allowance = true, balanced_with_money = true, money_smart = true },
				hintCareer = "finance",
				feedText = "💵 Smart strategy! Enjoy now AND plan for later!",
			},
			{
				text = "🎁 Save for something big",
				effects = { Happiness = 5, Smarts = 3, Money = 15 },
				setFlags = { gets_allowance = true, goal_saver = true, money_smart = true, future_investor = true },
				hintCareer = "business",
				feedText = "💵 Eyes on the prize! Saving for that special thing!",
			},
		},
	},

	{
		id = "childhood_sports_tryout",
		title = "Sports Tryouts!",
		emoji = "⚽",
		textVariants = {
			"Sports team tryouts! Can you make the cut?",
			"Time to show your athletic skills!",
			"Want to join a team? Tryouts are today!",
			"Nervous butterflies for tryouts!",
		},
		text = "Sports team tryouts! Can you make the cut?",
		question = "How do tryouts go?",
		minAge = 7, maxAge = 12,
		baseChance = 0.4,
		cooldown = 4,
		category = "childhood",
		tags = { "childhood", "sports", "competition" },
		careerTags = { "sports", "career_nba", "career_nfl" },
		
		choices = {
			{
				text = "🏆 Made the team!",
				effects = { Happiness = 8, Health = 3 },
				setFlags = { on_sports_team = true, athletic_kid = true, team_player = true, sporty_kid = true, athletic = true, school_athlete = true },
				hintCareer = "sports",
				feedText = "⚽ YES! You're on the team! Practice starts Monday!",
			},
			{
				text = "😢 Didn't make it",
				effects = { Happiness = -5 },
				setFlags = { cut_from_team = true, faced_rejection = true },
				feedText = "⚽ Not this time... but you'll try again next year!",
			},
			{
				text = "🔄 Made the B team",
				effects = { Happiness = 4, Health = 2 },
				setFlags = { on_b_team = true, working_up = true, athletic_kid = true, school_athlete = true },
				hintCareer = "sports",
				feedText = "⚽ Not varsity but still on a team! Keep working!",
			},
			{
				text = "😰 Too nervous to try",
				effects = { Happiness = -2 },
				setFlags = { sports_anxiety = true, missed_opportunity = true },
				feedText = "⚽ You chickened out. Maybe next time...",
			},
		},
	},

	{
		id = "childhood_sleepover",
		title = "Sleepover Time!",
		emoji = "🌙",
		textVariants = {
			"Your first sleepover! A whole night at a friend's house!",
			"Sleepover party! Staying up ALL night!",
			"Packing your bag for the sleepover!",
			"Sleeping somewhere other than home!",
		},
		text = "Your first sleepover! A whole night at a friend's house!",
		question = "How does it go?",
		minAge = 7, maxAge = 12,
		baseChance = 0.4,
		cooldown = 4,
		category = "childhood",
		tags = { "childhood", "social", "sleepover" },
		
		choices = {
			{
				text = "🎉 Best night ever!",
				effects = { Happiness = 8 },
				setFlags = { loves_sleepovers = true, good_sleepover = true, social_butterfly = true, extrovert = true },
				feedText = "🌙 Games, snacks, scary stories, no sleep! AMAZING!",
				relationshipEffect = { type = "friend", change = 15 },
			},
			{
				text = "😢 Got homesick, called home",
				effects = { Happiness = -3 },
				setFlags = { sleepover_homesick = true, needs_home_comfort = true, introvert = true },
				feedText = "🌙 You called mom at midnight. They picked you up.",
				relationshipEffect = { type = "family", change = 5 },
			},
			{
				text = "😴 Fell asleep early",
				effects = { Happiness = 3, Health = 2 },
				setFlags = { early_sleeper = true },
				feedText = "🌙 You missed all the late-night fun... but felt great!",
			},
			{
				text = "😤 Drama with friends",
				effects = { Happiness = -2 },
				setFlags = { sleepover_drama = true },
				feedText = "🌙 Someone got upset. Awkward rest of the night.",
				relationshipEffect = { type = "friend", change = -10 },
			},
		},
	},

	{
		id = "childhood_reading_discovery",
		title = "Book Magic!",
		emoji = "📖",
		textVariants = {
			"You discovered a book you can't put down!",
			"Reading is actually... FUN?!",
			"A book series has captured your imagination!",
			"Lost in a story world!",
		},
		text = "You discovered a book you can't put down!",
		question = "What kind of books do you love?",
		minAge = 6, maxAge = 12,
		baseChance = 0.4,
		cooldown = 4,
		category = "childhood",
		tags = { "childhood", "reading", "hobby" },
		careerTags = { "creative", "education", "law" },
		
		choices = {
			{
				text = "🧙 Fantasy adventures!",
				effects = { Happiness = 5, Smarts = 4 },
				setFlags = { bookworm = true, fantasy_lover = true, vivid_imagination = true, loves_reading = true, creative = true },
				hintCareer = "creative",
				feedText = "📖 Magic, dragons, quests - you're hooked!",
			},
			{
				text = "🔍 Mystery stories!",
				effects = { Happiness = 5, Smarts = 5 },
				setFlags = { bookworm = true, mystery_lover = true, analytical_mind = true, loves_reading = true },
				hintCareer = "law",
				feedText = "📖 Solving crimes from your bedroom! Detective vibes!",
			},
			{
				text = "🦸 Superhero comics!",
				effects = { Happiness = 6, Smarts = 3 },
				setFlags = { bookworm = true, comic_lover = true, loves_reading = true },
				hintCareer = "creative",
				feedText = "📖 Pow! Bam! Heroes saving the day! You love it!",
			},
			{
				text = "📚 A little of everything!",
				effects = { Happiness = 4, Smarts = 4 },
				setFlags = { bookworm = true, diverse_reader = true, loves_reading = true, intellectual_child = true },
				hintCareer = "education",
				feedText = "📖 Your library card is getting a workout!",
			},
		},
	},

	{
		id = "childhood_chores",
		title = "Chore Time!",
		emoji = "🧹",
		textVariants = {
			"Time to do your chores!",
			"Your parents added MORE chores!",
			"Cleaning your room... again!",
			"Chores are part of life now!",
		},
		text = "Time to do your chores!",
		question = "How do you approach chores?",
		minAge = 6, maxAge = 12,
		baseChance = 0.45,
		cooldown = 3,
		category = "childhood",
		tags = { "childhood", "responsibility", "home" },
		
		choices = {
			{
				text = "😊 Do them right away",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { responsible_kid = true, good_with_chores = true },
				feedText = "🧹 Done! Now you have free time without guilt!",
			},
			{
				text = "😤 Complain but do them",
				effects = { Happiness = 1 },
				setFlags = { reluctant_worker = true },
				feedText = "🧹 Lots of sighing, but you got it done eventually.",
			},
			{
				text = "🙈 Hide and avoid",
				effects = { Happiness = 4 },
				setFlags = { avoids_chores = true, procrastinator = true },
				feedText = "🧹 Parents can't find you... but they will eventually.",
			},
			{
				text = "💰 Negotiate for extra pay",
				effects = { Happiness = 3, Smarts = 3, Money = 5 },
				setFlags = { negotiator_kid = true, business_minded = true },
				feedText = "🧹 Extra chores for extra cash? Deal!",
			},
		},
	},

	{
		id = "childhood_scary_movie",
		title = "Scary Movie!",
		emoji = "👻",
		textVariants = {
			"Your friends want to watch a scary movie!",
			"There's a horror film everyone's talking about!",
			"Too young for scary movies? Let's find out!",
			"Dare to watch something spooky?",
		},
		text = "Your friends want to watch a scary movie!",
		question = "How brave are you?",
		minAge = 8, maxAge = 12,
		baseChance = 0.4,
		cooldown = 4,
		category = "childhood",
		tags = { "childhood", "movies", "fear" },
		
		choices = {
			{
				text = "😎 Not scared at all!",
				effects = { Happiness = 5 },
				setFlags = { brave_with_scary = true, thrill_seeker = true },
				feedText = "👻 You laughed through the whole thing! Fearless!",
			},
			{
				text = "😨 Watched through fingers",
				effects = { Happiness = 2 },
				setFlags = { scared_of_horror = true },
				feedText = "👻 Mostly didn't see it... but claimed you did!",
			},
			{
				text = "😱 Nightmares for days",
				effects = { Happiness = -4, Health = -2 },
				setFlags = { gets_nightmares = true, sensitive_to_scary = true },
				feedText = "👻 Bad idea. Can't sleep. Everything is scary now.",
			},
			{
				text = "🙅 No way, not watching",
				effects = { Happiness = 1 },
				setFlags = { avoids_scary = true, knows_limits = true },
				feedText = "👻 You sat out. Smart move honestly!",
			},
		},
	},

	{
		id = "childhood_cooking_attempt",
		title = "I Can Cook!",
		emoji = "👨‍🍳",
		textVariants = {
			"You want to try cooking on your own!",
			"How hard can making food be?",
			"Parents are busy - time to be independent!",
			"You've watched enough cooking shows!",
		},
		text = "You want to try cooking on your own!",
		question = "What do you make?",
		minAge = 8, maxAge = 12,
		baseChance = 0.4,
		cooldown = 5,
		category = "childhood",
		tags = { "childhood", "cooking", "independence" },
		careerTags = { "service", "creative" },
		
		choices = {
			{
				text = "🥣 Cereal! (Safe choice)",
				effects = { Happiness = 3 },
				setFlags = { basic_cooking = true },
				feedText = "👨‍🍳 Cereal mastery achieved! Step one complete!",
			},
			{
				text = "🍳 Eggs! (Brave!)",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { learning_to_cook = true, adventurous_cooking = true, cooking_interest = true },
				hintCareer = "service",
				feedText = "👨‍🍳 Scrambled... kinda. Edible though! Progress!",
			},
			{
				text = "🔥 Full meal! (Chaos!)",
				effects = { Happiness = 6, Health = -2 },
				setFlags = { cooking_disaster = true, ambitious = true, cooking_interest = true, talented_cook = true },
				hintCareer = "service",
				feedText = "👨‍🍳 Smoke alarm went off but you tried! A for effort!",
			},
			{
				text = "🍕 Order pizza instead",
				effects = { Happiness = 4, Money = -10 },
				setFlags = { prefers_delivery = true },
				feedText = "👨‍🍳 Cooking is hard. Pizza is easy. Smart!",
			},
		},
	},
}

return Childhood
