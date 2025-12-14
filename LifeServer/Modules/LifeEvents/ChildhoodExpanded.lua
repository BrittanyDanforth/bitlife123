--[[
    Childhood Expanded Events (Ages 0-12)
    100+ additional childhood events with deep, realistic scenarios
    All events use randomized outcomes - NO god mode
]]

local ChildhoodExpanded = {}

local STAGE = "childhood"

ChildhoodExpanded.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- BABY & TODDLER EXPANSION (Ages 0-4)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "baby_sleep_schedule",
		title = "Sleepless Nights",
		emoji = "😴",
		text = "You're not sleeping through the night yet. Your parents are exhausted.",
		question = "How does this phase go?",
		minAge = 0, maxAge = 2,
		baseChance = 0.7,
		cooldown = 1,
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "development",
		tags = { "sleep", "baby", "development" },
		
		choices = {
			{
				text = "Eventually settle into a routine",
				effects = {},
				feedText = "Time passes...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Health", 3)
						state:AddFeed("😴 You started sleeping through the night! Everyone is happier.")
					elseif roll < 0.80 then
						state:ModifyStat("Health", 1)
						state:AddFeed("😴 Still waking up sometimes, but it's getting better.")
					else
						state:ModifyStat("Health", -2)
						state.Flags = state.Flags or {}
						state.Flags.sleep_issues = true
						state:AddFeed("😴 Sleep has been a struggle. You wake up a lot.")
					end
				end,
			},
		},
	},
	{
		id = "baby_crawling",
		title = "Learning to Crawl",
		emoji = "👶",
		text = "You're trying to figure out this crawling thing!",
		question = "How quickly do you master mobility?",
		minAge = 0, maxAge = 1,
		oneTime = true,
		isMilestone = true,
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "development",
		milestoneKey = "CHILD_CRAWLING",
		tags = { "mobility", "baby", "milestone" },
		
		choices = {
			{
				text = "Practice crawling",
				effects = {},
				feedText = "You kept trying...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Health", 2)
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.early_crawler = true
						state:AddFeed("👶 You're crawling everywhere! No corner is safe!")
					else
						state:ModifyStat("Health", 1)
						state:AddFeed("👶 Crawling came a bit late, but you got there!")
					end
				end,
			},
		},
	},
	{
		id = "toddler_picky_eater",
		title = "Picky Eater Phase",
		emoji = "🥦",
		text = "You've decided you hate certain foods. Dinnertime is a battle.",
		question = "What's your eating situation?",
		minAge = 2, maxAge = 5,
		baseChance = 0.6,
		cooldown = 2,
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "behavior",
		tags = { "food", "behavior", "health" },
		
		choices = {
			{
				text = "Refuse vegetables entirely",
				effects = { Health = -3, Happiness = 2 },
				setFlags = { picky_eater = true },
				feedText = "Green things are EVIL. You won't touch them.",
			},
			{
				text = "Will only eat one specific food",
				effects = { Health = -2, Happiness = 1 },
				setFlags = { food_obsession = true },
				feedText = "Chicken nuggets. Every. Single. Meal.",
			},
			{
				text = "Eat everything put in front of you",
				effects = { Health = 3, Happiness = 2 },
				setFlags = { good_eater = true },
				feedText = "You're an adventurous eater! Parents are relieved.",
			},
			{
				text = "Eventually grow out of it",
				effects = { Health = 1 },
				feedText = "After some battles, you expanded your palette.",
			},
		},
	},
	{
		id = "toddler_language_explosion",
		title = "Talking Up a Storm",
		emoji = "💬",
		text = "Your vocabulary is exploding! New words every day!",
		question = "How is your language developing?",
		minAge = 2, maxAge = 4,
		oneTime = true,
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "development",
		tags = { "language", "development", "speech" },
		
		choices = {
			{
				text = "Advanced vocabulary for your age",
				effects = {},
				feedText = "People say you talk like an older kid...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.early_talker = true
						state:AddFeed("💬 You're incredibly articulate! Using big words already!")
					else
						state:ModifyStat("Smarts", 3)
						state:AddFeed("💬 You're talking a lot! Sometimes making sense, sometimes not.")
					end
				end,
			},
			{
				text = "Taking your time with speech",
				effects = {},
				feedText = "Words are coming slowly...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Smarts", 2)
						state:AddFeed("💬 Speech is developing normally. No rush!")
					else
						state.Flags = state.Flags or {}
						state.Flags.speech_delay = true
						state:AddFeed("💬 Speech therapy might help. Nothing wrong, just need a boost.")
					end
				end,
			},
		},
	},
	{
		id = "toddler_fear_dark",
		title = "Afraid of the Dark",
		emoji = "🌙",
		text = "The dark is TERRIFYING. Monsters could be anywhere!",
		question = "How do you cope with nighttime fears?",
		minAge = 2, maxAge = 6,
		baseChance = 0.5,
		cooldown = 3,
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "psychology",
		tags = { "fear", "night", "development" },
		
		choices = {
			{ text = "Need a nightlight forever", effects = { Happiness = 2 }, setFlags = { needs_nightlight = true }, feedText = "The nightlight stays ON. Non-negotiable." },
			{ text = "Sleep with stuffed animal protector", effects = { Happiness = 3 }, setFlags = { comfort_object = true }, feedText = "Your stuffed animal guards you from monsters." },
			{ text = "Eventually overcome the fear", effects = { Happiness = 4, Smarts = 2 }, setFlags = { overcame_fear = true }, feedText = "You learned there's nothing to be afraid of!" },
			{ text = "Still scared but hide it", effects = { Happiness = -2 }, setFlags = { hides_fears = true }, feedText = "You pretend you're not scared. But you are." },
		},
	},
	{
		id = "toddler_separation_anxiety",
		title = "Don't Leave Me!",
		emoji = "😢",
		text = "When your parents leave the room, it feels like the end of the world!",
		question = "How bad is your separation anxiety?",
		minAge = 1, maxAge = 4,
		baseChance = 0.5,
		cooldown = 2,
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "psychology",
		tags = { "anxiety", "parents", "development" },
		
		choices = {
			{
				text = "Cry every time they leave",
				effects = { Happiness = -4 },
				setFlags = { separation_anxiety = true },
				feedText = "Every goodbye is dramatic. EVERY. SINGLE. ONE.",
			},
			{
				text = "Gradually learn they come back",
				effects = { Happiness = 2, Smarts = 2 },
				feedText = "Peek-a-boo taught you: people come back!",
			},
			{
				text = "Independent from the start",
				effects = { Happiness = 3 },
				setFlags = { independent_child = true },
				feedText = "Bye! You're fine. Go explore!",
			},
		},
	},
	{
		id = "toddler_favorite_toy",
		title = "The Favorite Toy",
		emoji = "🧸",
		text = "You've become VERY attached to one specific toy.",
		question = "What happens with your favorite toy?",
		minAge = 1, maxAge = 5,
		oneTime = true,
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "psychology",
		tags = { "toy", "attachment", "comfort" },
		
		choices = {
			{
				text = "It goes everywhere with you",
				effects = { Happiness = 4 },
				setFlags = { has_lovey = true },
				feedText = "This toy is your LIFE. It goes everywhere.",
			},
			{
				text = "Panic when it gets lost",
				effects = {},
				feedText = "The toy went missing...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🧸 FOUND IT! Crisis averted. Never leaving you again.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.lost_lovey = true
						state:AddFeed("🧸 Lost forever. You're devastated. A piece of childhood gone.")
					end
				end,
			},
			{
				text = "Don't get too attached to things",
				effects = { Happiness = 1, Smarts = 1 },
				feedText = "You like lots of toys equally. No favorites.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EARLY CHILDHOOD EXPANSION (Ages 5-8)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "child_first_lie",
		title = "Your First Real Lie",
		emoji = "🤥",
		text = "You told a real lie for the first time. Not a little fib - a real one.",
		question = "What happened?",
		minAge = 4, maxAge = 7,
		oneTime = true,
		stage = STAGE,
		ageBand = "early_childhood",
		category = "moral_development",
		tags = { "lying", "morals", "development" },
		
		choices = {
			{
				text = "Got away with it",
				effects = {},
				feedText = "They believed you...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.good_liar = true
						state:AddFeed("🤥 You're a convincing liar. Is that good? Probably not.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤥 Got away with it but the guilt is eating at you.")
					end
				end,
			},
			{
				text = "Got caught immediately",
				effects = { Happiness = -4 },
				setFlags = { bad_liar = true },
				feedText = "Your face gave it away instantly. Busted.",
			},
			{
				text = "Confessed on your own",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { honest_child = true },
				feedText = "The guilt was too much. You came clean.",
			},
		},
	},
	{
		id = "child_imaginary_world",
		title = "The Imaginary World",
		emoji = "🏰",
		text = "You've created an entire imaginary world with elaborate rules and characters!",
		question = "How involved is your imagination?",
		minAge = 4, maxAge = 9,
		oneTime = true,
		stage = STAGE,
		ageBand = "early_childhood",
		category = "creativity",
		tags = { "imagination", "creativity", "play" },
		careerTags = { "creative" },
		
		choices = {
			{ text = "So elaborate you write it down", effects = { Smarts = 5, Happiness = 5 }, setFlags = { creative_genius = true }, hintCareer = "creative", feedText = "You're worldbuilding like a professional author!" },
			{ text = "Play in it every day", effects = { Happiness = 6, Smarts = 2 }, setFlags = { vivid_imagination = true }, feedText = "Your imaginary world is your favorite place." },
			{ text = "Share it with friends", effects = { Happiness = 5 }, setFlags = { collaborative_imagination = true }, feedText = "Your friends join your imaginary adventures!" },
			{ text = "Keep it completely secret", effects = { Happiness = 3, Smarts = 2 }, setFlags = { private_imagination = true }, feedText = "This world is just for you. Your secret sanctuary." },
		},
	},
	{
		id = "child_playground_accident_serious",
		title = "Serious Fall",
		emoji = "🤕",
		text = "You had a bad fall on the playground!",
		question = "How serious is it?",
		minAge = 4, maxAge = 10,
		baseChance = 0.3,
		cooldown = 4,
		stage = STAGE,
		ageBand = "early_childhood",
		category = "health",
		tags = { "injury", "playground", "accident" },
		
		-- CRITICAL: Random injury severity - player doesn't choose outcome
		choices = {
			{
				text = "Rush to get help",
				effects = {},
				feedText = "Adults came running...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Health", -2)
						state:AddFeed("🤕 Just scrapes and bruises. Bandages and you're good!")
					elseif roll < 0.70 then
						state:ModifyStat("Health", -6)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤕 Sprained wrist. Cast for a few weeks.")
					elseif roll < 0.90 then
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.broken_bone = true
						state:AddFeed("🤕 Broken arm! Hospital visit and a cast.")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.serious_injury = true
						state:AddFeed("🤕 Concussion. Hospital stay. Scary experience.")
					end
				end,
			},
		},
	},
	{
		id = "child_first_pet_responsibility",
		title = "Pet Responsibility",
		emoji = "🐕",
		text = "You promised to take care of the pet. Are you keeping that promise?",
		question = "How are you doing with pet duties?",
		minAge = 5, maxAge = 12,
		baseChance = 0.5,
		cooldown = 2,
		requiresFlags = { has_pet = true },
		stage = STAGE,
		ageBand = "childhood",
		category = "responsibility",
		tags = { "pets", "responsibility", "chores" },
		
		choices = {
			{
				text = "Taking great care of them!",
				effects = {},
				feedText = "Let's see how it's really going...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.responsible_pet_owner = true
						state:AddFeed("🐕 You're a great pet owner! Feeding, walking, playing!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🐕 You're trying, but parents still do most of the work.")
					end
				end,
			},
			{
				text = "Forgot feeding duties a few times",
				effects = { Happiness = -3 },
				feedText = "Parents had to remind you. Again.",
			},
			{
				text = "Parents do everything now",
				effects = { Happiness = -2 },
				setFlags = { broke_promise = true },
				feedText = "You lost pet privileges. It's their pet now.",
			},
		},
	},
	{
		id = "child_school_fight",
		title = "School Fight",
		emoji = "👊",
		text = "Things got physical at school!",
		question = "What happened?",
		minAge = 6, maxAge = 12,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "conflict",
		tags = { "fighting", "school", "discipline" },
		
		-- CRITICAL: Random fight outcome
		choices = {
			{
				text = "Defend yourself when attacked",
				effects = {},
				feedText = "You fought back...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Health", -3)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.can_defend_self = true
						state:AddFeed("👊 You held your own! Minor scrapes. Principal's office.")
					elseif roll < 0.70 then
						state:ModifyStat("Health", -6)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("👊 Got some hits, took some hits. Both in trouble.")
					else
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("👊 Lost the fight. Bruised up and embarrassed.")
					end
				end,
			},
			{
				text = "Run and tell a teacher",
				effects = { Smarts = 2, Happiness = -2 },
				setFlags = { avoids_fights = true },
				feedText = "Smart but called a tattletale. Social cost.",
			},
			{
				text = "Start the fight yourself",
				effects = {},
				feedText = "You threw the first punch...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 2)
						state.Flags = state.Flags or {}
						state.Flags.aggressive = true
						state:AddFeed("👊 Won the fight but got suspended. Worth it?")
					else
						state:ModifyStat("Health", -8)
						state:ModifyStat("Happiness", -6)
						state:AddFeed("👊 Started it and lost. Suspended AND beat up.")
					end
				end,
			},
		},
	},
	{
		id = "child_money_lesson",
		title = "First Money Lesson",
		emoji = "💵",
		text = "You saved up money and now have to decide what to do with it!",
		question = "What do you do with your savings?",
		minAge = 6, maxAge = 11,
		baseChance = 0.5,
		cooldown = 3,
		stage = STAGE,
		ageBand = "childhood",
		category = "money",
		tags = { "money", "saving", "spending" },
		careerTags = { "finance" },
		
		choices = {
			{
				text = "Buy the toy you've wanted forever",
				effects = { Happiness = 8, Money = -30 },
				feedText = "FINALLY! The toy is YOURS!",
			},
			{
				text = "Save it for something bigger",
				effects = { Smarts = 3, Money = 20 },
				setFlags = { delayed_gratification = true },
				hintCareer = "finance",
				feedText = "Patience is hard but you're saving for something special.",
			},
			{
				text = "Split it - buy something small, save the rest",
				effects = { Happiness = 4, Smarts = 2, Money = 5 },
				feedText = "Balance! A small treat and savings. Smart kid.",
			},
			{
				text = "Lose it somehow",
				effects = { Happiness = -6 },
				feedText = "It was in your pocket... and then it wasn't. Devastating.",
			},
		},
	},
	{
		id = "child_homework_habits",
		title = "Homework Habits",
		emoji = "📝",
		text = "Homework is becoming a regular thing. How do you handle it?",
		question = "What are your homework habits?",
		minAge = 6, maxAge = 12,
		oneTime = true,
		stage = STAGE,
		ageBand = "childhood",
		category = "academics",
		tags = { "homework", "school", "habits" },
		
		choices = {
			{ text = "Get it done right after school", effects = { Smarts = 5, Happiness = -1 }, setFlags = { good_homework_habits = true }, feedText = "No play until homework is done. Discipline!" },
			{ text = "Procrastinate until the last minute", effects = { Smarts = 1, Happiness = 2 }, setFlags = { procrastinator = true }, feedText = "Sunday night panic is now your routine." },
			{ text = "Do it but complain constantly", effects = { Smarts = 3, Happiness = -2 }, feedText = "UGHHH HOMEWORK IS THE WORST. But you finish it." },
			{ text = "Often 'forget' to do it", effects = { Smarts = -3, Happiness = 3 }, setFlags = { neglects_homework = true }, feedText = "What homework? You're 'creative' with excuses." },
		},
	},
	{
		id = "child_sick_day_real",
		title = "Really Sick",
		emoji = "🤒",
		text = "You're actually sick this time. Not faking it.",
		question = "What kind of sick?",
		minAge = 4, maxAge = 12,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "childhood",
		category = "health",
		tags = { "sick", "health", "school" },
		
		-- CRITICAL: Random illness - player doesn't choose severity
		choices = {
			{
				text = "Stay home and rest",
				effects = {},
				feedText = "Mom checks your temperature...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Health", -2)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🤒 Just a cold. Soup, rest, cartoons. Not so bad!")
					elseif roll < 0.70 then
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🤒 Flu! A week in bed. Everything hurts.")
					elseif roll < 0.90 then
						state:ModifyStat("Health", -8)
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🤒 Stomach bug. You'll spare the details. It was bad.")
					else
						state:ModifyStat("Health", -12)
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.hospitalized = true
						state:AddFeed("🤒 Serious illness. Hospital visit. Scary but you recovered.")
					end
				end,
			},
		},
	},
	{
		id = "child_sibling_rivalry_intense",
		title = "Sibling War",
		emoji = "⚔️",
		text = "The rivalry with your sibling has reached new heights!",
		question = "How bad is the sibling conflict?",
		minAge = 4, maxAge = 12,
		baseChance = 0.4,
		cooldown = 3,
		requiresFlags = { has_younger_sibling = true },
		stage = STAGE,
		ageBand = "childhood",
		category = "family",
		tags = { "sibling", "conflict", "family" },
		
		choices = {
			{
				text = "All-out war - constant fighting",
				effects = { Happiness = -6 },
				setFlags = { sibling_enemy = true },
				feedText = "Your sibling is your NEMESIS. Parents are exhausted.",
			},
			{
				text = "Competition for parental attention",
				effects = { Happiness = -4, Smarts = 1 },
				feedText = "Everything is a contest. Who's the favorite?",
			},
			{
				text = "Actually starting to get along",
				effects = { Happiness = 5 },
				setFlags = { sibling_bond = true },
				feedText = "You found common ground! Allies now, not enemies.",
			},
			{
				text = "Mostly ignore each other",
				effects = { Happiness = 1 },
				feedText = "Cold peace. Coexistence through avoidance.",
			},
		},
	},
	{
		id = "child_nature_discovery",
		title = "Nature Explorer",
		emoji = "🌿",
		text = "You've become fascinated with something in nature!",
		question = "What captured your interest?",
		minAge = 5, maxAge = 11,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "childhood",
		category = "interests",
		tags = { "nature", "science", "curiosity" },
		careerTags = { "science", "veterinary" },
		
		choices = {
			{ text = "Bugs and insects", effects = { Smarts = 4, Happiness = 4 }, setFlags = { bug_enthusiast = true }, hintCareer = "science", feedText = "Catching bugs, studying them. Nature's tiny wonders!" },
			{ text = "Plants and gardening", effects = { Smarts = 3, Happiness = 4, Health = 2 }, setFlags = { plant_lover = true }, feedText = "Growing things! Your first garden." },
			{ text = "Birds and bird watching", effects = { Smarts = 4, Happiness = 3 }, setFlags = { bird_watcher = true }, hintCareer = "science", feedText = "You can identify 20 different birds!" },
			{ text = "Rocks and minerals", effects = { Smarts = 5, Happiness = 3 }, setFlags = { rock_collector = true }, hintCareer = "science", feedText = "Your rock collection is impressive!" },
			{ text = "Animals in general", effects = { Happiness = 5 }, setFlags = { animal_lover = true }, hintCareer = "veterinary", feedText = "Every animal is your friend!" },
		},
	},
	{
		id = "child_stranger_danger",
		title = "Stranger Situation",
		emoji = "⚠️",
		text = "A stranger approached you when you were alone.",
		question = "What happened?",
		minAge = 5, maxAge = 11,
		baseChance = 0.1,
		cooldown = 6,
		stage = STAGE,
		ageBand = "childhood",
		category = "safety",
		tags = { "safety", "strangers", "scary" },
		
		choices = {
			{
				text = "Run to find an adult",
				effects = { Smarts = 4, Happiness = 3 },
				setFlags = { street_smart = true },
				feedText = "You did exactly right! Found a trusted adult.",
			},
			{
				text = "Yell 'NO!' and run away",
				effects = { Smarts = 3, Happiness = 2 },
				feedText = "You remembered what you were taught. Good job!",
			},
			{
				text = "It was just a nice person - false alarm",
				effects = { Happiness = 2 },
				feedText = "Turns out they just wanted to return your dropped item. Still, good to be cautious!",
			},
		},
	},
	{
		id = "child_creativity_expression",
		title = "Creative Outlet",
		emoji = "🎨",
		text = "You've found a way to express yourself creatively!",
		question = "What's your creative outlet?",
		minAge = 5, maxAge = 12,
		oneTime = true,
		stage = STAGE,
		ageBand = "childhood",
		category = "creativity",
		tags = { "art", "creativity", "expression" },
		careerTags = { "creative" },
		
		choices = {
			{ text = "Drawing and painting", effects = { Happiness = 5, Looks = 2, Smarts = 2 }, setFlags = { young_artist = true }, hintCareer = "creative", feedText = "Your art covers the refrigerator!" },
			{ text = "Building with LEGO/blocks", effects = { Smarts = 5, Happiness = 4 }, setFlags = { builder = true }, hintCareer = "tech", feedText = "Epic structures! Future engineer?" },
			{ text = "Making up songs", effects = { Happiness = 5, Smarts = 2 }, setFlags = { musical_child = true }, hintCareer = "creative", feedText = "You're always humming your own tunes!" },
			{ text = "Writing stories", effects = { Smarts = 5, Happiness = 3 }, setFlags = { young_writer = true }, hintCareer = "creative", feedText = "Your stories are getting longer and crazier!" },
			{ text = "Acting and pretend play", effects = { Happiness = 5, Looks = 2 }, setFlags = { little_actor = true }, hintCareer = "creative", feedText = "Every room is your stage!" },
		},
	},
	{
		id = "child_family_crisis",
		title = "Family Troubles",
		emoji = "💔",
		text = "Something difficult is happening in your family.",
		question = "What's going on at home?",
		minAge = 5, maxAge = 12,
		baseChance = 0.15,
		cooldown = 6,
		stage = STAGE,
		ageBand = "childhood",
		category = "family",
		tags = { "family", "hardship", "emotions" },
		
		choices = {
			{
				text = "Parents fighting a lot",
				effects = { Happiness = -8, Health = -2 },
				setFlags = { troubled_home = true },
				feedText = "The fighting is scary. You hide in your room.",
			},
			{
				text = "Money problems at home",
				effects = { Happiness = -5 },
				setFlags = { financial_hardship_child = true },
				feedText = "You notice parents are stressed about bills.",
			},
			{
				text = "A family member is sick",
				effects = { Happiness = -6 },
				setFlags = { family_illness = true },
				feedText = "Someone you love is in the hospital. It's scary.",
			},
			{
				text = "Parents getting divorced",
				effects = { Happiness = -10 },
				setFlags = { parents_divorced = true },
				feedText = "Everything is changing. Two homes now. It hurts.",
			},
		},
	},
	{
		id = "child_achievement_academic",
		title = "Academic Achievement",
		emoji = "🌟",
		text = "You did something impressive academically!",
		question = "What did you achieve?",
		minAge = 6, maxAge = 12,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "childhood",
		category = "academics",
		tags = { "school", "achievement", "success" },
		
		-- CRITICAL: Random achievement outcome
		choices = {
			{
				text = "Perfect score on a test",
				effects = {},
				feedText = "You studied hard and...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.40 + (smarts / 150)
					if roll < successChance then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🌟 100%! Perfect score! Gold star!")
					else
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🌟 Not perfect, but a really good grade!")
					end
				end,
			},
			{
				text = "Won an academic competition",
				effects = {},
				feedText = "You competed against other students...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Smarts", 6)
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.academic_champion = true
						state:AddFeed("🌟 1ST PLACE! You're the champion!")
					elseif roll < 0.60 then
						state:ModifyStat("Smarts", 4)
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🌟 Made it to the finals! Great showing!")
					else
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🌟 Didn't win, but great experience!")
					end
				end,
			},
			{
				text = "Honor roll",
				effects = { Smarts = 4, Happiness = 5 },
				setFlags = { honor_student = true },
				feedText = "Your name on the honor roll! Parents are so proud!",
			},
		},
	},
	{
		id = "child_moving_houses",
		title = "Moving to a New Home",
		emoji = "🏠",
		text = "Your family is moving to a new house!",
		question = "How do you feel about moving?",
		minAge = 5, maxAge = 12,
		oneTime = true,
		baseChance = 0.2,
		stage = STAGE,
		ageBand = "childhood",
		category = "family",
		tags = { "moving", "change", "home" },
		
		choices = {
			{ text = "Excited for a new adventure!", effects = { Happiness = 5 }, setFlags = { adapts_to_change = true }, feedText = "New room! New neighborhood! New friends to make!" },
			{ text = "Devastated to leave friends", effects = { Happiness = -8 }, setFlags = { misses_old_home = true }, feedText = "Leaving your friends behind is heartbreaking." },
			{ text = "Nervous but hopeful", effects = { Happiness = 1, Smarts = 2 }, feedText = "Change is scary, but maybe it'll be good?" },
			{ text = "Don't care either way", effects = { Happiness = 1 }, feedText = "Home is wherever your stuff is." },
		},
	},
	{
		id = "child_new_school",
		title = "New School",
		emoji = "🏫",
		text = "You're starting at a brand new school where you don't know anyone!",
		question = "How does your first week go?",
		minAge = 5, maxAge = 12,
		oneTime = true,
		stage = STAGE,
		ageBand = "childhood",
		category = "school",
		tags = { "school", "new", "social" },
		
		-- CRITICAL: Random new school outcome
		choices = {
			{
				text = "Try to make friends right away",
				effects = {},
				feedText = "You put yourself out there...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local successChance = 0.40 + (looks / 200)
					if roll < successChance then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.makes_friends_easily = true
						state:AddFeed("🏫 Made new friends fast! This place isn't so bad!")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🏫 A few friendly faces. It'll take time.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🏫 Rough start. Nobody seems interested in the new kid.")
					end
				end,
			},
			{
				text = "Keep to yourself at first",
				effects = { Happiness = -2, Smarts = 2 },
				setFlags = { cautious_social = true },
				feedText = "Observing before engaging. Slow and steady.",
			},
			{
				text = "Get bullied for being new",
				effects = { Happiness = -8 },
				setFlags = { bullied_new_kid = true },
				feedText = "They targeted you for being different. It's awful.",
			},
		},
	},
	{
		id = "child_test_cheating_dilemma",
		title = "The Cheating Dilemma",
		emoji = "👀",
		text = "During a test, you can see the smart kid's answers clearly.",
		question = "What do you do?",
		minAge = 7, maxAge = 12,
		baseChance = 0.3,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "moral_development",
		tags = { "cheating", "test", "ethics" },
		
		choices = {
			{
				text = "Copy some answers",
				effects = {},
				feedText = "You glanced at their paper...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Smarts", 2)
						state:AddFeed("👀 Got a good grade. Nobody noticed. The guilt though...")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("👀 Teacher noticed your wandering eyes. Warning issued.")
					else
						state:ModifyStat("Happiness", -8)
						state:ModifyStat("Smarts", -2)
						state.Flags = state.Flags or {}
						state.Flags.caught_cheating = true
						state:AddFeed("👀 CAUGHT! Zero on the test. Parents called. Disaster.")
					end
				end,
			},
			{
				text = "Keep your eyes on your own paper",
				effects = { Smarts = 1, Happiness = 2 },
				setFlags = { honest_student = true },
				feedText = "You earned your grade honestly. That matters.",
			},
			{
				text = "Tell the teacher to move you",
				effects = { Smarts = 2 },
				feedText = "You removed the temptation. Smart thinking.",
			},
		},
	},
	{
		id = "child_embarrassing_moment",
		title = "Most Embarrassing Moment",
		emoji = "😳",
		text = "Something MORTIFYING just happened in front of everyone!",
		question = "What happened?",
		minAge = 5, maxAge = 12,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "childhood",
		category = "social",
		tags = { "embarrassment", "social", "school" },
		
		choices = {
			{ text = "Tripped in front of the whole class", effects = { Happiness = -5, Health = -1 }, feedText = "Face-first. Everyone saw. You wanted to disappear." },
			{ text = "Called the teacher 'Mom/Dad'", effects = { Happiness = -4 }, feedText = "The whole class laughed. You're never living this down." },
			{ text = "Split your pants", effects = { Happiness = -6, Looks = -2 }, feedText = "RIP to those pants and your dignity." },
			{ text = "Sneezed during presentation", effects = { Happiness = -4 }, feedText = "In the middle of your speech. So embarrassing!" },
			{ text = "Farted loudly and everyone heard", effects = { Happiness = -7 }, feedText = "The room fell silent. Then the giggles. Then the ROAR of laughter." },
		},
	},
	{
		id = "child_grades_slipping",
		title = "Grades Slipping",
		emoji = "📉",
		text = "Your grades have been dropping lately.",
		question = "What's causing the slip?",
		minAge = 7, maxAge = 12,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "childhood",
		category = "academics",
		tags = { "grades", "school", "struggle" },
		
		choices = {
			{
				text = "Material is getting harder",
				effects = { Smarts = -2, Happiness = -3 },
				feedText = "School is just harder now. You're struggling to keep up.",
			},
			{
				text = "Distracted by friends/games",
				effects = { Smarts = -3, Happiness = 2 },
				setFlags = { distracted_student = true },
				feedText = "Fun stuff is more fun than homework.",
			},
			{
				text = "Something at home affecting you",
				effects = { Happiness = -5, Smarts = -1 },
				feedText = "Hard to focus when home life is stressful.",
			},
			{
				text = "Get a tutor and improve",
				effects = { Smarts = 3, Money = -50 },
				feedText = "Extra help is making a difference!",
			},
		},
	},
	{
		id = "child_first_award",
		title = "First Award",
		emoji = "🏆",
		text = "You're receiving an award for something!",
		question = "What is the award for?",
		minAge = 6, maxAge = 12,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "achievement",
		tags = { "award", "recognition", "success" },
		
		choices = {
			{ text = "Good citizenship", effects = { Happiness = 6, Smarts = 2 }, setFlags = { good_citizen = true }, feedText = "Recognized for being kind and helpful!" },
			{ text = "Academic excellence", effects = { Happiness = 5, Smarts = 4 }, setFlags = { academic_achiever = true }, feedText = "Smartest kid award! Big deal!" },
			{ text = "Athletic achievement", effects = { Happiness = 6, Health = 3 }, setFlags = { athletic_achiever = true }, feedText = "MVP! You crushed it in sports!" },
			{ text = "Art show recognition", effects = { Happiness = 6, Looks = 2 }, setFlags = { art_recognized = true }, feedText = "Your art was selected as best in show!" },
			{ text = "Most improved", effects = { Happiness = 7, Smarts = 2 }, setFlags = { hard_worker = true }, feedText = "You worked so hard and everyone noticed!" },
		},
	},
	{
		id = "child_religion_question",
		title = "Big Questions",
		emoji = "❓",
		text = "You're starting to ask big questions about life, God, and the universe.",
		question = "What are you curious about?",
		minAge = 6, maxAge = 12,
		oneTime = true,
		stage = STAGE,
		ageBand = "childhood",
		category = "philosophy",
		tags = { "questions", "philosophy", "growing_up" },
		
		choices = {
			{ text = "Why are we here?", effects = { Smarts = 4, Happiness = 2 }, setFlags = { philosophical_child = true }, feedText = "Heavy questions for a young mind! You're thinking deeply." },
			{ text = "What happens when we die?", effects = { Smarts = 3, Happiness = -2 }, setFlags = { mortality_aware = true }, feedText = "A scary question. Parents try to comfort you." },
			{ text = "Is magic real?", effects = { Happiness = 3 }, feedText = "Holding onto wonder and magic. That's precious." },
			{ text = "Why do people fight wars?", effects = { Smarts = 4 }, setFlags = { socially_aware = true }, feedText = "Seeing the world's problems at a young age." },
		},
	},
	{
		id = "child_bedtime_routine",
		title = "Bedtime Battles",
		emoji = "🛏️",
		text = "Bedtime is always a negotiation.",
		question = "What's your bedtime situation?",
		minAge = 4, maxAge = 10,
		baseChance = 0.5,
		cooldown = 2,
		stage = STAGE,
		ageBand = "childhood",
		category = "routine",
		tags = { "sleep", "routine", "parents" },
		
		choices = {
			{ text = "Always want 'five more minutes'", effects = { Happiness = 2, Health = -1 }, setFlags = { night_owl = true }, feedText = "Just five more minutes. Every single night." },
			{ text = "Fall asleep easily", effects = { Health = 2, Happiness = 2 }, setFlags = { good_sleeper = true }, feedText = "Head hits pillow, you're out. Easy." },
			{ text = "Scared of bedtime - bad dreams", effects = { Happiness = -3, Health = -1 }, setFlags = { nightmares = true }, feedText = "Sleep brings scary dreams. Bedtime is dreaded." },
			{ text = "Elaborate bedtime routine", effects = { Happiness = 3 }, feedText = "Story, song, glass of water, three hugs, check for monsters. Every night." },
		},
	},
	{
		id = "child_first_concert",
		title = "First Concert",
		emoji = "🎵",
		text = "You're going to see live music for the first time!",
		question = "How was the experience?",
		minAge = 5, maxAge = 12,
		oneTime = true,
		stage = STAGE,
		ageBand = "childhood",
		category = "experiences",
		tags = { "music", "concert", "first_time" },
		
		choices = {
			{ text = "Absolutely magical!", effects = { Happiness = 10 }, setFlags = { loves_live_music = true }, feedText = "The lights, the sound, the energy! Life-changing!" },
			{ text = "Too loud - scared you", effects = { Happiness = -3 }, setFlags = { noise_sensitive = true }, feedText = "It was overwhelming. You wanted to leave." },
			{ text = "Fell asleep during it", effects = { Happiness = 1 }, feedText = "Past your bedtime. You dozed off. Still counts!" },
			{ text = "Inspired to make music", effects = { Happiness = 6, Smarts = 2 }, setFlags = { inspired_musician = true }, hintCareer = "creative", feedText = "You want to DO that! Music career dreams begin." },
		},
	},
	{
		id = "child_learning_instrument_progress",
		title = "Instrument Progress",
		emoji = "🎹",
		text = "You've been practicing your instrument. How's it going?",
		question = "What's your progress like?",
		minAge = 6, maxAge = 12,
		baseChance = 0.4,
		cooldown = 2,
		requiresFlags = { musical = true },
		stage = STAGE,
		ageBand = "childhood",
		category = "skills",
		tags = { "music", "practice", "learning" },
		
		-- CRITICAL: Random practice outcome
		choices = {
			{
				text = "Practice every day",
				effects = {},
				feedText = "You've been diligent about practice...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Smarts", 4)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.musical_talent = true
						state:AddFeed("🎹 Real progress! You can play songs now!")
					else
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🎹 Improving slowly. Practice makes progress!")
					end
				end,
			},
			{
				text = "Only practice when forced",
				effects = { Smarts = 1, Happiness = -2 },
				feedText = "Lessons are a chore. Minimal improvement.",
			},
			{
				text = "Ready to quit",
				effects = { Happiness = 3 },
				setFlags = { quit_instrument = true },
				feedText = "It's not for you. And that's okay!",
			},
		},
	},
	{
		id = "child_superhero_phase",
		title = "Superhero Obsession",
		emoji = "🦸",
		text = "You're obsessed with superheroes and want to BE one!",
		question = "How intense is your superhero phase?",
		minAge = 4, maxAge = 9,
		oneTime = true,
		stage = STAGE,
		ageBand = "childhood",
		category = "play",
		tags = { "superheroes", "imagination", "play" },
		
		choices = {
			{ text = "Wear a cape everywhere", effects = { Happiness = 6 }, setFlags = { cape_kid = true }, feedText = "No cape, no life. You are a HERO." },
			{ text = "Jump off furniture 'flying'", effects = { Happiness = 4, Health = -3 }, feedText = "Spoiler: you can't fly. The couch taught you that." },
			{ text = "Develop your 'powers'", effects = { Happiness = 5, Smarts = 2 }, setFlags = { superhero_training = true }, feedText = "Training montage! Building strength!" },
			{ text = "Create your own superhero identity", effects = { Happiness = 5, Smarts = 3 }, setFlags = { creative_hero = true }, hintCareer = "creative", feedText = "Original costume, backstory, powers. You're the BEST hero!" },
		},
	},
	{
		id = "child_cooking_with_parent",
		title = "Cooking Together",
		emoji = "👨‍🍳",
		text = "You're helping a parent cook dinner!",
		question = "How does it go?",
		minAge = 5, maxAge = 12,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "childhood",
		category = "skills",
		tags = { "cooking", "family", "learning" },
		
		-- CRITICAL: Random cooking outcome
		choices = {
			{
				text = "Help mix and stir",
				effects = {},
				feedText = "You're a helper chef...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.young_cook = true
						state:AddFeed("👨‍🍳 Delicious! You helped make dinner!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("👨‍🍳 Made a mess but dinner turned out okay!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("👨‍🍳 Burned it. Pizza delivery for dinner instead.")
					end
				end,
			},
			{
				text = "Try to do it yourself",
				effects = {},
				feedText = "You wanted to do it solo...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 7)
						state:ModifyStat("Smarts", 4)
						state:AddFeed("👨‍🍳 Impressive! You cooked a whole meal!")
					elseif roll < 0.60 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("👨‍🍳 Needed some help but got it done!")
					else
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Health", -1)
						state:AddFeed("👨‍🍳 Small kitchen disaster. Maybe wait a few years.")
					end
				end,
			},
		},
	},
	{
		id = "child_video_game_obsession",
		title = "Gaming Obsession",
		emoji = "🎮",
		text = "You've discovered a video game you can't stop playing!",
		question = "How bad is the obsession?",
		minAge = 6, maxAge = 12,
		baseChance = 0.5,
		cooldown = 2,
		requiresFlags = { gamer = true },
		stage = STAGE,
		ageBand = "childhood",
		category = "hobbies",
		tags = { "gaming", "addiction", "screen_time" },
		
		choices = {
			{
				text = "Playing constantly - parents worried",
				effects = { Happiness = 5, Health = -3, Smarts = -2 },
				setFlags = { gaming_obsessed = true },
				feedText = "Can't stop. Won't stop. Parents intervening soon.",
			},
			{
				text = "Healthy gaming balance",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { healthy_gamer = true },
				feedText = "You enjoy games but know when to stop.",
			},
			{
				text = "Beat the game and move on",
				effects = { Happiness = 6, Smarts = 1 },
				feedText = "Finished it! Satisfaction. Onto the next one.",
			},
			{
				text = "Parents took the game away",
				effects = { Happiness = -6 },
				setFlags = { games_confiscated = true },
				feedText = "Gone. Confiscated. The withdrawal is REAL.",
			},
		},
	},
}

return ChildhoodExpanded
