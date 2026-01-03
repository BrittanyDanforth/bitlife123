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
		baseChance = 0.4, -- CRITICAL FIX: Reduced from 0.7
		cooldown = 4, -- CRITICAL FIX: Increased from 1 to prevent spam
		oneTime = true, -- CRITICAL FIX: Sleep patterns only discussed once
		stage = STAGE,
		ageBand = "baby_toddler",
		category = "development",
		tags = { "sleep", "baby", "development" },
		blockedByFlags = { sleep_issues_discussed = true },
		
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.35,
		cooldown = 4,
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
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.35,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "money",
		tags = { "money", "saving", "spending" },
		careerTags = { "finance" },
		
		choices = {
		{
			text = "Buy the toy you've wanted forever ($30)",
			effects = { Happiness = 8, Money = -30 },
			feedText = "FINALLY! The toy is YOURS!",
			eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30" end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4,
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
		cooldown = 4,
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
		baseChance = 0.4,
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
		baseChance = 0.4,
		cooldown = 4,
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
		baseChance = 0.45,
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
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4,
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
		baseChance = 0.4,
		cooldown = 4,
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
			text = "Get a tutor and improve (parents pay)",
			effects = { Smarts = 3 },
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
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #702: NEW DYNAMIC CHILDHOOD EVENTS
	-- User feedback: "ensure stuff u do actually has stuff popup for it in future"
	-- These events have CONSEQUENCES that affect later life!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "child_promise_to_friend",
		title = "A Promise Made",
		emoji = "🤝",
		text = "Your best friend is moving away. You promise to stay in touch forever.",
		question = "Will you keep this promise?",
		minAge = 8, maxAge = 12,
		oneTime = true,
		stage = STAGE,
		ageBand = "childhood",
		category = "friendship",
		tags = { "promise", "friendship", "moving" },
		triggersFollowUp = true,
		
		choices = {
			{
				text = "Promise to write every week",
				effects = { Happiness = 3 },
				setFlags = { promised_friend_letters = true, made_important_promise = true },
				feedText = "🤝 You swore to stay best friends forever!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.childhood_promise_age = state.Age
				end,
			},
			{
				text = "Cry and say goodbye",
				effects = { Happiness = -5 },
				setFlags = { lost_childhood_friend = true },
				feedText = "😢 It's so hard to say goodbye...",
			},
		},
	},
	{
		id = "child_secret_spot",
		title = "Secret Hideout",
		emoji = "🏚️",
		text = "You discovered a secret spot! An abandoned treehouse, hidden cave, or empty lot.",
		question = "What becomes of your secret spot?",
		minAge = 7, maxAge = 11,
		oneTime = true,
		stage = STAGE,
		ageBand = "childhood",
		category = "adventure",
		tags = { "secret", "adventure", "hideout" },
		
		choices = {
			{
				text = "Make it your personal hideaway",
				effects = { Happiness = 8 },
				setFlags = { had_secret_spot = true, values_privacy = true },
				feedText = "🏚️ Your special place! No adults allowed!",
			},
			{
				text = "Share it with friends",
				effects = { Happiness = 10 },
				setFlags = { had_secret_clubhouse = true, shares_with_friends = true },
				feedText = "🏚️ The coolest clubhouse ever! Secret password required!",
			},
			{
				text = "Tell your parents (they said it's dangerous)",
				effects = { Happiness = -3, Smarts = 2 },
				setFlags = { obedient_child = true },
				feedText = "🏚️ Adults ruined it. But you stayed safe.",
			},
		},
	},
	{
		id = "child_saved_animal",
		title = "Rescued Animal",
		emoji = "🐦",
		text = "You found an injured bird/animal! It's hurt and needs help!",
		question = "What do you do?",
		minAge = 5, maxAge = 12,
		oneTime = true,
		stage = STAGE,
		ageBand = "childhood",
		category = "empathy",
		tags = { "animals", "rescue", "kindness" },
		hintCareer = "veterinary",
		
		choices = {
			{
				text = "Nurse it back to health",
				effects = {},
				feedText = "You tried your best to help...",
				setFlags = { rescued_animal = true },
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.animal_healer = true
						state.Flags.compassionate = true
						state:AddFeed("🐦 It recovered! You released it back into the wild!")
					else
						state:ModifyStat("Happiness", -5)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.learned_about_loss = true
						state:AddFeed("🐦 Despite your efforts, it didn't make it. You learned about loss.")
					end
				end,
			},
			{
				text = "Take it to a vet",
				effects = { Smarts = 3 },
				setFlags = { trusts_professionals = true },
				feedText = "🐦 The vet took care of it. Smart choice!",
			},
		},
	},
	{
		id = "child_standing_up_to_bully",
		title = "Facing the Bully",
		emoji = "💪",
		text = "A bully is picking on a smaller kid. Nobody else is helping.",
		question = "What do you do?",
		minAge = 7, maxAge = 12,
		oneTime = true,
		stage = STAGE,
		ageBand = "childhood",
		category = "courage",
		tags = { "bully", "courage", "standing_up" },
		
		choices = {
			{
				text = "Stand up to the bully",
				effects = {},
				feedText = "You stepped in...",
				setFlags = { stood_up_to_bully = true },
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.brave = true
						state.Flags.defender = true
						state:AddFeed("💪 The bully backed down! You're a hero!")
					else
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.brave = true
						state.Flags.took_a_beating = true
						state:AddFeed("💪 Got beat up but earned everyone's respect. Worth it.")
					end
				end,
			},
			{
				text = "Get an adult",
				effects = { Smarts = 3 },
				setFlags = { seeks_help = true },
				feedText = "💪 Got a teacher. The bully got in trouble.",
			},
			{
				text = "Walk away",
				effects = { Happiness = -4 },
				setFlags = { avoided_conflict = true },
				feedText = "💪 You kept walking. The guilt sticks with you.",
			},
		},
	},
	{
		id = "child_big_lie",
		title = "The Big Lie",
		emoji = "🤥",
		text = "You did something wrong and your parents are asking about it. If you lie, you might get away with it...",
		question = "Do you tell the truth?",
		minAge = 6, maxAge = 12,
		baseChance = 0.35,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "morality",
		tags = { "honesty", "lying", "consequences" },
		
		choices = {
			{
				text = "Tell the truth",
				effects = { Smarts = 3 },
				setFlags = { honest_child = true },
				feedText = "🤥 Got in trouble but parents respected your honesty.",
			},
			{
				text = "Lie and deny everything",
				effects = {},
				feedText = "You lied...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.good_liar = true
						state:AddFeed("🤥 Got away with it! The guilt fades... eventually.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.caught_lying = true
						state:AddFeed("🤥 CAUGHT! Double punishment for lying!")
					end
				end,
			},
			{
				text = "Blame a sibling",
				effects = {},
				setFlags = { blamed_sibling = true },
				feedText = "You pointed fingers...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🤥 Your sibling took the fall. You monster.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags.sibling_hates_you = true
						state:AddFeed("🤥 The truth came out. Your sibling will NEVER forget this.")
					end
				end,
			},
		},
	},
	{
		id = "child_talent_discovered",
		title = "Hidden Talent",
		emoji = "✨",
		text = "You discovered something you're naturally good at!",
		question = "What's your hidden talent?",
		minAge = 5, maxAge = 11,
		oneTime = true,
		stage = STAGE,
		ageBand = "childhood",
		category = "discovery",
		tags = { "talent", "discovery", "skills" },
		
		choices = {
			{
				text = "Amazing at drawing/art",
				effects = { Happiness = 8, Smarts = 3 },
				setFlags = { artistic_talent = true, creative = true },
				hintCareer = "arts",
				feedText = "✨ You can draw anything! Natural artist!",
			},
			{
				text = "Natural athlete",
				effects = { Happiness = 8, Health = 5 },
				setFlags = { athletic_talent = true, natural_athlete = true },
				hintCareer = "sports",
				feedText = "✨ Fastest, strongest, most coordinated! Sports star potential!",
			},
			{
				text = "Math/Science whiz",
				effects = { Happiness = 6, Smarts = 8 },
				setFlags = { academic_talent = true, math_genius = true },
				hintCareer = "stem",
				feedText = "✨ Numbers make sense to you! Future scientist?",
			},
			{
				text = "Natural performer/entertainer",
				effects = { Happiness = 8, Looks = 2 },
				setFlags = { performer_talent = true, natural_performer = true },
				hintCareer = "entertainment",
				feedText = "✨ You love being on stage! Star in the making!",
			},
			{
				text = "Amazing with animals",
				effects = { Happiness = 6, Smarts = 2 },
				setFlags = { animal_talent = true, animal_whisperer = true },
				hintCareer = "veterinary",
				feedText = "✨ Animals just trust you! Dr. Dolittle vibes!",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- NEW ENGAGING SCHOOL EVENTS - Makes ages 5-18 less repetitive!
	-- User feedback: "NO LIKE CLASSMATE HITS U OR SOMEBODY ASKS TO CHEAT OFF UR PAPER"
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "school_copy_homework",
		title = "Homework Helper?",
		emoji = "📝",
		text = "A classmate slides up to you before class. 'Hey, can I copy your homework? I totally forgot to do it. Please? I'll owe you one!'",
		question = "What do you do?",
		minAge = 6, maxAge = 12,
		baseChance = 0.4,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "school",
		tags = { "homework", "cheating", "social", "ethics" },
		blockedByFlags = { in_prison = true, dropped_out = true },
		
		choices = {
			{
				text = "Let them copy it",
				effects = {},
				feedText = "You handed over your homework...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 30 then
						-- Teacher catches you both
						state:ModifyStat("Happiness", -8)
						state:ModifyStat("Smarts", -2)
						state.Flags.caught_helping_cheat = true
						state:AddFeed("📝 BUSTED! Teacher noticed identical answers. Both in trouble!")
					elseif roll <= 60 then
						-- They're grateful, friendship boost
						state:ModifyStat("Happiness", 4)
						state.Flags.helped_classmate = true
						state:AddFeed("📝 They're SO grateful! You made a friend. Just don't tell anyone...")
					else
						-- They got away but feel weird about it
						state:ModifyStat("Happiness", 1)
						state:AddFeed("📝 They copied it. Felt kinda wrong but whatever.")
					end
				end,
			},
			{
				text = "Say no, do your own work",
				effects = { Smarts = 2 },
				setFlags = { honest_student = true },
				feedText = "📝 You said no. They were annoyed but you did the right thing.",
			},
			{
				text = "Let them copy but change a few answers",
				effects = {},
				feedText = "You're sneaky...",
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 50 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📝 Smart! They didn't notice the changes. You're safe!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("📝 They got a bad grade and blamed you! Drama!")
					end
				end,
			},
			{
				text = "Tell them you'll help them study instead",
				effects = { Smarts = 3, Happiness = 3 },
				setFlags = { good_tutor = true },
				feedText = "📝 You offered to help them learn. They were impressed!",
			},
		},
	},
	{
		id = "school_classmate_hits_you",
		title = "Punched!",
		emoji = "👊",
		text = "Out of NOWHERE, a classmate punches you! Maybe you bumped into them, maybe they're having a bad day, maybe they just don't like your face. Either way - OW!",
		question = "What do you do?",
		minAge = 6, maxAge = 12,
		baseChance = 0.45,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "conflict",
		tags = { "fighting", "bullying", "school", "conflict" },
		blockedByFlags = { in_prison = true, dropped_out = true },
		
		choices = {
			{
				text = "Hit them back!",
				effects = {},
				feedText = "You swung back...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 40 then
						-- You won the fight
						state:ModifyStat("Health", -3)
						state:ModifyStat("Happiness", 5)
						state.Flags.can_fight = true
						state.Flags.stood_up_for_self = true
						state:AddFeed("👊 You won! They won't mess with you again. Both suspended though.")
					elseif roll <= 70 then
						-- Draw
						state:ModifyStat("Health", -6)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("👊 You both got hits in. Teachers broke it up. Double suspension.")
					else
						-- You lost
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -8)
						state.Flags.lost_fight = true
						state:AddFeed("👊 Ouch... you lost. Bruised ego and bruised face.")
					end
				end,
			},
			{
				text = "Tell a teacher immediately",
				effects = { Happiness = -2 },
				feedText = "You reported the assault...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 60 then
						state:ModifyStat("Happiness", 3)
						state.Flags.reported_bully = true
						state:AddFeed("👊 Teacher believed you! The other kid got in BIG trouble.")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags.tattletale = true
						state:AddFeed("👊 You snitched but now you're known as a tattletale...")
					end
				end,
			},
			{
				text = "Just take it and walk away",
				effects = { Happiness = -6 },
				setFlags = { bullied = true, non_confrontational = true },
				feedText = "👊 You walked away. The shame hurts more than the punch.",
			},
			{
				text = "Cry and make a scene",
				effects = {},
				feedText = "The tears came flowing...",
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 50 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("👊 Your crying brought adults running. They got in trouble!")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.crybaby_reputation = true
						state:AddFeed("👊 You cried and now everyone calls you a crybaby. Great.")
					end
				end,
			},
		},
	},
	{
		id = "school_teacher_accuses",
		title = "Falsely Accused!",
		emoji = "😡",
		text = "The teacher is FURIOUS. 'I KNOW it was YOU who [threw that paper ball/drew on the desk/started the commotion]!' But it WASN'T you! Someone else did it!",
		question = "How do you respond?",
		minAge = 6, maxAge = 12,
		baseChance = 0.35,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "school",
		tags = { "teacher", "accusation", "injustice", "school" },
		blockedByFlags = { in_prison = true, dropped_out = true },
		
		choices = {
			{
				text = "Defend yourself calmly",
				effects = {},
				feedText = "You tried to explain...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random(100) + (smarts / 5)
					state.Flags = state.Flags or {}
					if roll >= 60 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state.Flags.cleared_name = true
						state:AddFeed("😡 You explained calmly and the teacher believed you! Justice!")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags.wrongly_punished = true
						state:AddFeed("😡 Teacher didn't believe you. Detention anyway. Life is unfair.")
					end
				end,
			},
			{
				text = "Point out who really did it",
				effects = {},
				feedText = "You pointed at the real culprit...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 40 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("😡 The real culprit was caught! Sweet vindication!")
					elseif roll <= 70 then
						state:ModifyStat("Happiness", -3)
						state.Flags.snitch_reputation = true
						state:AddFeed("😡 They got in trouble but now everyone thinks you're a snitch.")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("😡 The other kid denied it and had 'witnesses'. Now you're in DOUBLE trouble!")
					end
				end,
			},
			{
				text = "Just accept the punishment",
				effects = { Happiness = -5 },
				setFlags = { wrongly_punished = true, pushover = true },
				feedText = "😡 You took the fall for something you didn't do. That's gonna sting for a while.",
			},
			{
				text = "Get angry and argue back",
				effects = {},
				feedText = "You lost your temper...",
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 30 then
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.stood_up_to_authority = true
						state:AddFeed("😡 Your passion convinced the teacher to investigate. You were cleared!")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.disrespected_teacher = true
						state:AddFeed("😡 Now you're in trouble for the original thing AND for being disrespectful. Oops.")
					end
				end,
			},
		},
	},
	{
		id = "school_bathroom_incident",
		title = "Bathroom Ambush",
		emoji = "🚽",
		text = "You went to the bathroom between classes. Some older kids followed you in. The door closes behind them. This doesn't feel good...",
		question = "What happens?",
		minAge = 7, maxAge = 12,
		baseChance = 0.4,
		cooldown = 5,
		stage = STAGE,
		ageBand = "childhood",
		category = "conflict",
		tags = { "bullying", "bathroom", "school", "danger" },
		blockedByFlags = { in_prison = true, dropped_out = true, bathroom_incident_done = true },
		
		choices = {
			{
				text = "They demand your lunch money",
				effects = {},
				feedText = "They want your money...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.bathroom_incident_done = true
					local roll = math.random(100)
					if roll <= 40 then
						-- You give it up
						state:ModifyStat("Happiness", -8)
						state.Money = math.max(0, (state.Money or 0) - 5)
						state.Flags.extorted = true
						state:AddFeed("🚽 You handed over $5. They laughed and left. You're shaking.")
					elseif roll <= 70 then
						-- You refuse and they back down
						state:ModifyStat("Happiness", 2)
						state.Flags.stood_up_to_bully = true
						state:AddFeed("🚽 You said NO. They looked surprised and backed off. Respect.")
					else
						-- They take it by force
						state:ModifyStat("Happiness", -10)
						state:ModifyStat("Health", -5)
						state.Money = math.max(0, (state.Money or 0) - 10)
						state.Flags.robbed_at_school = true
						state:AddFeed("🚽 They took everything. Pushed you down too. This is traumatic.")
					end
				end,
			},
			{
				text = "They just want to talk (intimidate)",
				effects = {},
				feedText = "They got in your face...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.bathroom_incident_done = true
					local roll = math.random(100)
					if roll <= 50 then
						state:ModifyStat("Happiness", -5)
						state.Flags.intimidated = true
						state:AddFeed("🚽 They just wanted to scare you. It worked. You're rattled.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🚽 Turns out they just wanted directions? Weird but okay.")
					end
				end,
			},
			{
				text = "A teacher walks in and saves you",
				effects = { Happiness = 5 },
				feedText = "🚽 Perfect timing! A teacher walked in and the kids scattered. Lucky!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.bathroom_incident_done = true
				end,
			},
			{
				text = "You manage to slip past them and run",
				effects = {},
				feedText = "You made a break for it...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.bathroom_incident_done = true
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random(100) + (health / 4)
					if roll >= 50 then
						state:ModifyStat("Happiness", 3)
						state.Flags.quick_escape = true
						state:AddFeed("🚽 You squeezed past them and RAN! Made it to safety!")
					else
						state:ModifyStat("Happiness", -6)
						state:ModifyStat("Health", -3)
						state:AddFeed("🚽 You tried to run but they grabbed you. Now they're extra mad.")
					end
				end,
			},
		},
	},
	{
		id = "school_rumor_spreading",
		title = "Rumors About You!",
		emoji = "🗣️",
		text = "You overhear kids whispering and pointing at you. Someone started a RUMOR about you! They're saying you [wet the bed/have a crush on the teacher/picked your nose and ate it]!",
		question = "How do you handle this?",
		minAge = 6, maxAge = 12,
		baseChance = 0.35,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "social",
		tags = { "rumors", "social", "reputation", "school" },
		blockedByFlags = { in_prison = true, dropped_out = true },
		
		choices = {
			{
				text = "Laugh it off and own it",
				effects = {},
				feedText = "You decided to embrace it...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random(100) + (looks / 5)
					state.Flags = state.Flags or {}
					if roll >= 55 then
						state:ModifyStat("Happiness", 6)
						state.Flags.confident = true
						state:AddFeed("🗣️ You laughed along. Everyone thought you were cool about it! Rumor died.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🗣️ You tried to laugh but it came out awkward. Rumor persists.")
					end
				end,
			},
			{
				text = "Confront the person who started it",
				effects = {},
				feedText = "You faced them directly...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 40 then
						state:ModifyStat("Happiness", 5)
						state.Flags.confronted_bully = true
						state:AddFeed("🗣️ You called them out. They backed down. People respect you now.")
					elseif roll <= 70 then
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🗣️ They denied it. Now it's your word against theirs.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags.more_rumors = true
						state:AddFeed("🗣️ They started ANOTHER rumor about you being aggressive!")
					end
				end,
			},
			{
				text = "Tell a teacher or parent",
				effects = {},
				feedText = "You reported it to an adult...",
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 60 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🗣️ The adult had a talk with everyone. Rumor stopped.")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.tattletale = true
						state:AddFeed("🗣️ Now you're known as someone who runs to adults. Social cost.")
					end
				end,
			},
			{
				text = "Start a rumor about THEM",
				effects = {},
				feedText = "You decided to fight fire with fire...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 40 then
						state:ModifyStat("Happiness", 4)
						state.Flags.rumor_starter = true
						state:AddFeed("🗣️ Your counter-rumor DESTROYED them! Sweet revenge!")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags.troublemaker = true
						state:AddFeed("🗣️ It backfired. Now you're known as someone who spreads rumors too.")
					end
				end,
			},
		},
	},
	{
		id = "school_cafeteria_incident",
		title = "Cafeteria Chaos!",
		emoji = "🍽️",
		text = "You're eating lunch when suddenly - SPLAT! Someone's food lands on you! Was it an accident? On purpose? Either way, your shirt is ruined and EVERYONE is looking!",
		question = "What do you do?",
		minAge = 6, maxAge = 12,
		baseChance = 0.45,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "social",
		tags = { "cafeteria", "food", "embarrassment", "school" },
		blockedByFlags = { in_prison = true, dropped_out = true },
		
		choices = {
			{
				text = "Throw food back at them!",
				effects = {},
				feedText = "FOOD FIGHT!",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 30 then
						state:ModifyStat("Happiness", 8)
						state.Flags.started_food_fight = true
						state:AddFeed("🍽️ EPIC FOOD FIGHT! The whole cafeteria joined in! Legendary!")
					elseif roll <= 60 then
						state:ModifyStat("Happiness", 2)
						state:ModifyStat("Looks", -2)
						state:AddFeed("🍽️ You got them good! But also detention. Worth it?")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags.cafeteria_banned = true
						state:AddFeed("🍽️ You missed and hit a teacher. Suspended from cafeteria for a week!")
					end
				end,
			},
			{
				text = "Play it cool, accidents happen",
				effects = { Happiness = -2, Looks = -3 },
				setFlags = { mature_response = true },
				feedText = "🍽️ You shrugged it off. Cleaned up and moved on. Very mature.",
			},
			{
				text = "Get upset and demand an apology",
				effects = {},
				feedText = "You confronted them...",
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 50 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🍽️ They apologized! Turns out it really was an accident.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🍽️ They laughed at you. Now you're embarrassed AND angry.")
					end
				end,
			},
			{
				text = "Leave and call your parent to bring new clothes",
				effects = { Happiness = -4, Looks = 5 },
				feedText = "🍽️ Parent came with fresh clothes. Crisis averted but you missed lunch.",
			},
		},
	},
	{
		id = "school_group_project",
		title = "Group Project Nightmare",
		emoji = "📊",
		text = "The teacher assigned a GROUP PROJECT. You're stuck with kids who don't want to do ANY work. The project is due tomorrow and they've done NOTHING!",
		question = "What do you do?",
		minAge = 7, maxAge = 12,
		baseChance = 0.35,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "school",
		tags = { "project", "teamwork", "frustration", "school" },
		blockedByFlags = { in_prison = true, dropped_out = true },
		
		choices = {
			{
				text = "Do the whole thing yourself",
				effects = {},
				feedText = "You pulled an all-nighter...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random(100) + (smarts / 4)
					state.Flags = state.Flags or {}
					if roll >= 60 then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Health", -2)
						state.Flags.reliable_worker = true
						state:AddFeed("📊 You did it all! A+ but you're EXHAUSTED. They don't deserve credit.")
					else
						state:ModifyStat("Happiness", -8)
						state:ModifyStat("Health", -3)
						state:AddFeed("📊 You tried but ran out of time. C grade. Everyone's disappointed.")
					end
				end,
			},
			{
				text = "Tell the teacher your partners aren't helping",
				effects = {},
				feedText = "You reported the situation...",
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 50 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("📊 Teacher believed you! You got graded individually. Fair!")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.snitch_reputation = true
						state:AddFeed("📊 Teacher made you work it out. Now your group hates you.")
					end
				end,
			},
			{
				text = "Threaten to tell unless they help NOW",
				effects = {},
				feedText = "You laid down the law...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 60 then
						state:ModifyStat("Happiness", 5)
						state.Flags.takes_charge = true
						state:AddFeed("📊 It worked! They scrambled and actually helped. Good grade!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("📊 They called your bluff and still did nothing. Ugh.")
					end
				end,
			},
			{
				text = "Accept the bad grade together",
				effects = { Happiness = -5, Smarts = -2 },
				feedText = "📊 You all failed together. At least you're not alone in this disaster.",
			},
		},
	},
	{
		id = "school_caught_passing_notes",
		title = "Caught Passing Notes!",
		emoji = "📝",
		text = "You were passing a note to your friend when the teacher snatched it! They're reading it out loud to the WHOLE CLASS!",
		question = "What was in the note?",
		minAge = 7, maxAge = 12,
		baseChance = 0.45,
		cooldown = 4,
		stage = STAGE,
		ageBand = "childhood",
		category = "school",
		tags = { "notes", "embarrassment", "teacher", "school" },
		blockedByFlags = { in_prison = true, dropped_out = true },
		
		choices = {
			{
				text = "Just doodles and silly drawings",
				effects = { Happiness = -3 },
				feedText = "📝 Embarrassing but not horrible. Teacher was not amused. Confiscated.",
			},
			{
				text = "Gossip about another student",
				effects = {},
				feedText = "The gossip was exposed...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 50 then
						state:ModifyStat("Happiness", -10)
						state.Flags.gossip_exposed = true
						state:AddFeed("📝 DISASTER! The person you wrote about heard EVERYTHING. Social death.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📝 Teacher read it but didn't say the names. Close call!")
					end
				end,
			},
			{
				text = "A secret crush confession",
				effects = {},
				feedText = "Your crush was revealed...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random(100) + (looks / 5)
					state.Flags = state.Flags or {}
					if roll >= 60 then
						state:ModifyStat("Happiness", 5)
						state.Flags.crush_knows = true
						state:AddFeed("📝 Your crush smiled at you after! Maybe this was good?")
					else
						state:ModifyStat("Happiness", -12)
						state.Flags.publicly_humiliated = true
						state:AddFeed("📝 Everyone laughed. Your crush looked HORRIFIED. You want to disappear.")
					end
				end,
			},
			{
				text = "A mean joke about the teacher",
				effects = {},
				feedText = "The teacher read their own roast...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state:ModifyStat("Happiness", -8)
					state.Flags.disrespected_teacher = true
					state:AddFeed("📝 Teacher was NOT happy. Detention plus a call home. You're in deep trouble.")
				end,
			},
		},
	},
}

return ChildhoodExpanded
