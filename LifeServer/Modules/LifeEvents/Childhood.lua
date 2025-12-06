--[[
    Childhood Events (Ages 0-12)
    Formative moments that shape personality and hint at future paths

    Integrated with:
    - core milestone tracking via `isMilestone` + milestoneKey
    - career catalog via `hintCareer` on choices + event-level careerTags
    - soft tagging via `stage`, `ageBand`, `category`, `tags`
]]

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
		id = "toddler_tantrum",
		title = "The Terrible Twos",
		emoji = "😤",
		text = "You want a toy at the store, but your parents said no.",
		question = "What do you do?",
		minAge = 2, maxAge = 3,
		baseChance = 0.8,
		cooldown = 2,

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
		baseChance = 0.6,
		cooldown = 3,

		-- META
		stage = STAGE,
		ageBand = "early_childhood",
		category = "relationships",
		tags = { "conflict", "school", "bullying" },
		careerTags = { "social_work" },

		choices = {
			{ text = "Stand up to them", effects = { Happiness = 5 }, setFlags = { brave = true }, feedText = "You stood up to the bully. It was scary, but you earned respect." },
			{ text = "Tell a teacher", effects = { Happiness = 2, Smarts = 2 }, setFlags = { trusts_authority = true }, feedText = "You told an adult. The bully got in trouble." },
			{ text = "Avoid them completely", effects = { Happiness = -3 }, setFlags = { conflict_avoidant = true }, feedText = "You learned which hallways to avoid. Safety first." },
			{ text = "Try to befriend them", effects = { Smarts = 3 }, setFlags = { peacemaker = true }, hintCareer = "social_work", feedText = "You tried to understand why they're mean. Sometimes kindness works." },
		},
	},

	{
		id = "class_pet",
		title = "Classroom Pet",
		emoji = "🐹",
		text = "Your classroom got a new pet hamster! The teacher needs someone to care for it.",
		question = "Do you volunteer?",
		minAge = 6, maxAge = 9,
		baseChance = 0.7,
		cooldown = 5,

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
	{
		id = "discovered_passion",
		title = "Finding Your Passion",
		emoji = "⭐",
		text = "Something really captured your interest and imagination!",
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
		careerTags = { "sports", "creative", "science", "tech", "medical", "entertainment" },

		choices = {
			{ text = "Sports and athletics", effects = { Health = 5, Happiness = 5 }, setFlags = { passionate_athlete = true }, hintCareer = "sports", feedText = "You fell in love with sports!" },
			{ text = "Art and creativity", effects = { Happiness = 7, Looks = 3 }, setFlags = { passionate_artist = true }, hintCareer = "creative", feedText = "Your creative soul awakened!" },
			{ text = "Science and discovery", effects = { Smarts = 7 }, setFlags = { passionate_scientist = true }, hintCareer = "science", feedText = "The mysteries of the universe call to you!" },
			{ text = "Building and creating things", effects = { Smarts = 5, Happiness = 3 }, setFlags = { passionate_builder = true }, hintCareer = "tech", feedText = "You love making things with your hands and mind!" },
			{ text = "Helping and caring for others", effects = { Happiness = 5 }, setFlags = { passionate_helper = true }, hintCareer = "medical", feedText = "You have a natural desire to help others!" },
			{ text = "Music and performance", effects = { Happiness = 7, Looks = 2 }, setFlags = { passionate_performer = true }, hintCareer = "entertainment", feedText = "The stage calls to you!" },
		},
	},

	{
		id = "science_fair",
		title = "Science Fair Project",
		emoji = "🔬",
		text = "It's science fair season! What kind of project will you do?",
		question = "Choose your project:",
		minAge = 7, maxAge = 11,
		baseChance = 0.7,
		cooldown = 3,

		-- META
		stage = STAGE,
		ageBand = "late_childhood",
		category = "school",
		tags = { "science", "project", "school" },
		careerTags = { "science", "tech" },

		choices = {
			{ text = "Volcano eruption", effects = { Smarts = 3, Happiness = 5 }, setFlags = { likes_chemistry = true }, hintCareer = "science", feedText = "Your baking soda volcano was the hit of the fair!" },
			{ text = "Growing plants experiment", effects = { Smarts = 5 }, setFlags = { patient_researcher = true }, hintCareer = "science", feedText = "You carefully documented how different conditions affect plant growth." },
			{ text = "Build a simple robot", effects = { Smarts = 7 }, setFlags = { tech_enthusiast = true }, hintCareer = "tech", feedText = "Your robot impressed the judges. Future engineer!" },
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
		baseChance = 0.5,
		cooldown = 2,

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
		baseChance = 0.5,

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
		baseChance = 0.7,

		-- META
		stage = STAGE,
		ageBand = "late_childhood",
		category = "relationships",
		tags = { "romance", "school", "feelings" },

		choices = {
			{ text = "Write them a secret note", effects = { Happiness = 3 }, setFlags = { romantic_soul = true }, feedText = "You slipped a note to your crush. Heart pounding!" },
			{ text = "Tell your best friend", effects = { Happiness = 3 }, setFlags = { shares_feelings = true }, feedText = "You confided in your best friend about your crush." },
			{ text = "Keep it to yourself", effects = { }, setFlags = { private_person = true }, feedText = "You kept your feelings secret. Some things are just for you." },
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
			{ text = "Spend it on candy and toys", effects = { Happiness = 5, Money = -20 }, setFlags = { spender = true }, feedText = "You enjoy your money while you have it!" },
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
		baseChance = 0.6,
		cooldown = 3,

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
		baseChance = 0.5,
		cooldown = 4,

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
		cooldown = 5,

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
		baseChance = 0.6,
		cooldown = 2,

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
		id = "sports_tryout",
		title = "Youth Sports Tryouts",
		emoji = "⚽",
		text = "Tryouts for a youth sports team are coming up!",
		question = "Which sport do you try out for?",
		minAge = 6, maxAge = 12,
		baseChance = 0.6,
		cooldown = 2,

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
		baseChance = 0.5,

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
		baseChance = 0.7,
		cooldown = 2,

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
		baseChance = 0.5,
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
		text = "You discovered video games and can't stop playing!",
		question = "What's your gaming style?",
		minAge = 6, maxAge = 12,
		oneTime = true,
		baseChance = 0.7,

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
		text = "It's your turn for show and tell at school!",
		question = "What do you bring?",
		minAge = 4, maxAge = 7,
		baseChance = 0.8,
		cooldown = 2,

		stage = STAGE,
		ageBand = "early_childhood",
		category = "school",
		tags = { "school", "presentation", "sharing" },

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
		baseChance = 0.5,
		cooldown = 4,

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
		baseChance = 0.5,
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
		baseChance = 0.7,

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
		baseChance = 0.8,
		cooldown = 1,

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
		cooldown = 4,

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
		cooldown = 2,

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
		baseChance = 0.5,
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
		baseChance = 0.5,
		cooldown = 2,

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
}

return Childhood
