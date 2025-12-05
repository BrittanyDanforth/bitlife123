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
		text = "You're learning to ride a bike!",
		question = "How does it go?",
		minAge = 5, maxAge = 8,
		oneTime = true,
		isMilestone = true,

		-- META
		stage = STAGE,
		ageBand = "early_childhood",
		category = "skills",
		milestoneKey = "CHILD_LEARNED_BIKE",
		tags = { "mobility", "outdoors", "independence" },

		choices = {
			{ text = "Got it on the first try!", effects = { Happiness = 8, Health = 3 }, setFlags = { natural_athlete = true }, feedText = "You're a natural! Freedom on two wheels!" },
			{ text = "Fell a lot, but kept trying", effects = { Happiness = 5, Health = -2 }, setFlags = { persistent = true }, feedText = "You got some scrapes, but you never gave up!" },
			{ text = "Needed training wheels for a while", effects = { Happiness = 3 }, setFlags = { cautious_learner = true }, feedText = "You took your time, but you got there." },
			{ text = "Too scared, gave up", effects = { Happiness = -3 }, setFlags = { bike_phobia = true }, feedText = "Bikes aren't for everyone... yet." },
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
			{ 
				text = "Computer/coding camp", 
				effects = { Smarts = 7 }, 
				setFlags = { coder = true }, 
				hintCareer = "tech", 
				feedText = "You learned to code! The digital world opens up.",
				onResolve = function(state)
					-- CRITICAL: Build coding interest for gradual career unlock
					state.Interests = state.Interests or {}
					state.Interests.coding = math.min(100, (state.Interests.coding or 0) + 25)
					state.Interests.programming = math.min(100, (state.Interests.programming or 0) + 20)
					state.Interests.tech = math.min(100, (state.Interests.tech or 0) + 15)
				end,
			},
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
}

return Childhood
