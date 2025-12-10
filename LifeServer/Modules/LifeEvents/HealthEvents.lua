--[[
    Health & Wellness Events
    Comprehensive health experiences across all life stages
    All events use randomized outcomes - NO god mode
]]

local HealthEvents = {}

local STAGE = "random"

HealthEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- PHYSICAL HEALTH
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "health_common_illness",
		title = "Under the Weather",
		emoji = "🤒",
		text = "You're not feeling well!",
		question = "What's wrong?",
		minAge = 3, maxAge = 100,
		baseChance = 0.35,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "illness", "sick", "recovery" },
		
		-- CRITICAL: Random illness severity
		choices = {
			{
				text = "Rest and recover",
				effects = {},
				feedText = "Taking it easy...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					local recoveryChance = 0.40 + (health / 150)
					
					if roll < recoveryChance then
						state:ModifyStat("Health", 2)
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🤒 Quick recovery! Back on your feet!")
					elseif roll < 0.85 then
						state:ModifyStat("Health", -2)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤒 Rough few days but getting better.")
					else
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.prolonged_illness = true
						state:AddFeed("🤒 This is lasting longer than expected. Worry setting in.")
					end
				end,
			},
			{ text = "Push through it", effects = { Health = -3, Happiness = -2, Smarts = 1 }, feedText = "🤒 Working sick. Spreading germs. Delayed recovery." },
			{ text = "Go to doctor", effects = { Money = -50, Health = 3 }, feedText = "🤒 Got proper treatment. Meds helping." },
		},
	},
	{
		id = "health_injury_accident",
		title = "Accident/Injury",
		emoji = "🩹",
		text = "You've been injured!",
		question = "How bad is it?",
		minAge = 5, maxAge = 90,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "injury", "accident", "recovery" },
		
		-- CRITICAL: Random injury severity
		choices = {
			{
				text = "Assess the damage",
				effects = {},
				feedText = "Checking the injury...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Health", -2)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🩹 Minor injury. Bruises and scrapes. Ice and rest.")
					elseif roll < 0.70 then
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -4)
						state.Money = (state.Money or 0) - 100
						state:AddFeed("🩹 Moderate injury. Sprain or strain. Weeks to heal.")
					elseif roll < 0.90 then
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -8)
						state.Money = (state.Money or 0) - 500
						state.Flags = state.Flags or {}
						state.Flags.serious_injury = true
						state:AddFeed("🩹 Serious injury. Broken bone. Surgery needed. Months of recovery.")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -12)
						state.Money = (state.Money or 0) - 2000
						state.Flags = state.Flags or {}
						state.Flags.major_injury = true
						state:AddFeed("🩹 Major trauma. Emergency room. Long rehabilitation ahead.")
					end
				end,
			},
		},
	},
	{
		id = "health_doctor_checkup",
		title = "Doctor Visit",
		emoji = "🏥",
		text = "Time for a health checkup!",
		question = "What do the results show?",
		minAge = 18, maxAge = 100,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "checkup", "doctor", "preventive" },
		
		-- CRITICAL: Random checkup results
		choices = {
			{
				text = "Get your results",
				effects = { Money = -50 },
				feedText = "Waiting for test results...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local age = state.Age or 30
					local roll = math.random()
					local goodResultChance = 0.45 + (health / 200) - (age / 250)
					
					if roll < goodResultChance then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Health", 3)
						state:AddFeed("🏥 All clear! Clean bill of health! Relief!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🏥 Minor concerns. Watch diet and exercise. Manageable.")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", -5)
						state:ModifyStat("Health", -3)
						state.Flags = state.Flags or {}
						state.Flags.health_concerns = true
						state:AddFeed("🏥 Concerning results. Need follow-up tests. Worry.")
					else
						state:ModifyStat("Happiness", -10)
						state:ModifyStat("Health", -8)
						state.Flags = state.Flags or {}
						state.Flags.serious_diagnosis = true
						state:AddFeed("🏥 Serious condition found. Treatment needed. Life-changing news.")
					end
				end,
			},
		},
	},
	{
		id = "health_dental_visit",
		title = "Dentist Time",
		emoji = "🦷",
		text = "Time for a dental checkup!",
		question = "How are your teeth?",
		minAge = 5, maxAge = 100,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "dental", "teeth", "checkup" },
		
		-- CRITICAL: Random dental outcome
		choices = {
			{
				text = "Open wide",
				effects = { Money = -75 },
				feedText = "In the dentist chair...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					
					if roll < 0.45 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🦷 No cavities! Perfect teeth! Gold star!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", -2)
						state.Money = (state.Money or 0) - 100
						state:AddFeed("🦷 One cavity. Filling needed. $100 more.")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", -5)
						state:ModifyStat("Health", -2)
						state.Money = (state.Money or 0) - 300
						state:AddFeed("🦷 Multiple issues. Crown or root canal. $300. Painful.")
					else
						state:ModifyStat("Happiness", -8)
						state:ModifyStat("Health", -3)
						state.Money = (state.Money or 0) - 1000
						state:AddFeed("🦷 Major dental work. Implants or extractions. $1000+. Rough.")
					end
				end,
			},
		},
	},
	{
		id = "health_fitness_journey",
		title = "Fitness Journey",
		emoji = "🏃",
		text = "You're working on getting in shape!",
		question = "How is your fitness journey going?",
		minAge = 12, maxAge = 80,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "fitness",
		tags = { "exercise", "fitness", "health" },
		
		-- CRITICAL: Random fitness progress
		choices = {
			{
				text = "Commit to regular exercise",
				effects = {},
				feedText = "Working out consistently...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Looks", 2)
						state.Flags = state.Flags or {}
						state.Flags.fit = true
						state:AddFeed("🏃 Results showing! Feeling strong and energized!")
					elseif roll < 0.80 then
						state:ModifyStat("Health", 3)
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🏃 Steady progress. Building good habits.")
					else
						state:ModifyStat("Health", 1)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🏃 Plateau. Not seeing results. Frustrating.")
					end
				end,
			},
			{
				text = "Hire personal trainer",
				effects = { Money = -200 },
				feedText = "Training with pro...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.75 then
						state:ModifyStat("Health", 7)
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Looks", 3)
						state:AddFeed("🏃 Amazing results! Trainer pushed you to greatness!")
					else
						state:ModifyStat("Health", 3)
						state:AddFeed("🏃 Good trainer but expensive. Progress is progress.")
					end
				end,
			},
			{ text = "Give up - too hard", effects = { Happiness = -3, Health = -1 }, setFlags = { sedentary = true }, feedText = "🏃 Couch wins. Exercise is hard." },
		},
	},
	{
		id = "health_weight_management",
		title = "Weight Concerns",
		emoji = "⚖️",
		text = "You're thinking about your weight.",
		question = "How do you approach weight management?",
		minAge = 14, maxAge = 90,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "weight", "diet", "health" },
		
		-- CRITICAL: Random weight journey outcome
		choices = {
			{
				text = "Start a diet",
				effects = {},
				feedText = "Changing eating habits...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Looks", 3)
						state.Flags = state.Flags or {}
						state.Flags.healthy_weight = true
						state:AddFeed("⚖️ Success! Hit your goal weight! Feel amazing!")
					elseif roll < 0.60 then
						state:ModifyStat("Health", 3)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("⚖️ Some progress. Slow and steady. Don't give up.")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("⚖️ Yo-yo dieting. Gained it back. Frustrating cycle.")
					else
						state:ModifyStat("Health", -2)
						state:ModifyStat("Happiness", -4)
						state.Flags = state.Flags or {}
						state.Flags.diet_issues = true
						state:AddFeed("⚖️ Unhealthy relationship with food developing. Need help.")
					end
				end,
			},
			{ text = "Accept your body", effects = { Happiness = 5, Health = 1 }, setFlags = { body_positive = true }, feedText = "⚖️ Love yourself as you are. Health at every size!" },
			{ text = "Fad diet", effects = { Health = -2, Happiness = -1 }, feedText = "⚖️ Quick fix failed. Gimmicks don't work long-term." },
		},
	},
	{
		id = "health_allergies",
		title = "Allergy Season",
		emoji = "🤧",
		text = "Allergies are acting up!",
		question = "How bad is it?",
		minAge = 5, maxAge = 90,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "allergies", "seasonal", "health" },
		
		choices = {
			{
				text = "Take antihistamines",
				effects = { Money = -15 },
				feedText = "Medicating...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🤧 Meds working! Symptoms manageable!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🤧 Meds make you drowsy. Lesser of two evils.")
					end
				end,
			},
			{ text = "Suffer through it", effects = { Happiness = -5, Health = -2 }, feedText = "🤧 Sneezing, itching, misery. Toughing it out." },
			{ text = "Allergy shots", effects = { Money = -100, Happiness = 2, Health = 3 }, setFlags = { allergy_treatment = true }, feedText = "🤧 Long-term solution! Building immunity!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MENTAL HEALTH
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "health_anxiety_episode",
		title = "Anxiety Spike",
		emoji = "😰",
		text = "Anxiety is overwhelming you!",
		question = "How do you cope?",
		minAge = 12, maxAge = 90,
		baseChance = 0.25,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "mental_health",
		tags = { "anxiety", "mental_health", "stress" },
		
		-- CRITICAL: Random anxiety coping outcome
		choices = {
			{
				text = "Practice coping techniques",
				effects = {},
				feedText = "Breathing, grounding...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", 2)
						state:AddFeed("😰 Techniques worked! Panic passed. You got this!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 1)
						state:AddFeed("😰 Helped a bit. Still struggling but manageable.")
					else
						state:ModifyStat("Happiness", -4)
						state:ModifyStat("Health", -2)
						state:AddFeed("😰 Couldn't stop it. Full anxiety attack. Exhausted after.")
					end
				end,
			},
			{ text = "Reach out for support", effects = { Happiness = 4, Health = 2 }, feedText = "😰 Talked to someone. Not alone. That helps." },
			{ text = "Avoid triggers (hide)", effects = { Happiness = -3 }, setFlags = { avoiding_anxiety_triggers = true }, feedText = "😰 Hiding makes it worse. Avoidance isn't coping." },
			{ text = "Seek professional help", effects = { Money = -80, Happiness = 6, Health = 3 }, setFlags = { therapy = true }, feedText = "😰 Therapist appointment made. Healing begins." },
		},
	},
	{
		id = "health_depression_bout",
		title = "Feeling Low",
		emoji = "😔",
		text = "Depression is hitting hard.",
		question = "What do you do?",
		minAge = 12, maxAge = 90,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "mental_health",
		tags = { "depression", "mental_health", "sadness" },
		
		-- CRITICAL: Random depression coping outcome
		choices = {
			{
				text = "Fight to do one thing today",
				effects = {},
				feedText = "Getting through the day...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Health", 2)
						state:AddFeed("😔 Did the thing. Small victory. That's enough.")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 1)
						state:AddFeed("😔 Tried. Didn't do much but got through the day.")
					else
						state:ModifyStat("Happiness", -5)
						state:ModifyStat("Health", -3)
						state.Flags = state.Flags or {}
						state.Flags.severe_depression = true
						state:AddFeed("😔 Couldn't get out of bed. Everything feels impossible.")
					end
				end,
			},
			{ text = "Talk to someone you trust", effects = { Happiness = 5, Health = 2 }, feedText = "😔 Opening up helped. Connection matters." },
			{ text = "Isolate", effects = { Happiness = -6, Health = -3 }, setFlags = { isolating = true }, feedText = "😔 Pushing everyone away. Spiral continues." },
			{ text = "Start therapy/medication", effects = { Money = -100, Happiness = 4, Health = 4 }, setFlags = { depression_treatment = true }, feedText = "😔 Getting help. It's okay to not be okay." },
		},
	},
	{
		id = "health_stress_overload",
		title = "Stress Overload",
		emoji = "🤯",
		text = "Stress is piling up beyond manageable levels!",
		question = "How do you handle burnout?",
		minAge = 16, maxAge = 80,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "mental_health",
		tags = { "stress", "burnout", "overwhelm" },
		
		choices = {
			{
				text = "Take a mental health day",
				effects = {},
				feedText = "Taking time off...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 7)
						state:ModifyStat("Health", 4)
						state:AddFeed("🤯 Needed that. Reset. Ready to face things again.")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🤯 Hard to relax but the break helped some.")
					end
				end,
			},
			{ text = "Push through", effects = { Health = -4, Happiness = -4 }, setFlags = { burned_out = true }, feedText = "🤯 Kept going. Running on fumes. Crash incoming." },
			{ text = "Set boundaries", effects = { Happiness = 6, Smarts = 2 }, setFlags = { healthy_boundaries = true }, feedText = "🤯 Said no. Protected your energy. Self-care." },
			{ text = "Unhealthy coping (substance use)", effects = { Happiness = 2, Health = -5 }, setFlags = { unhealthy_coping = true }, feedText = "🤯 Quick fix. Making things worse long-term." },
		},
	},
	{
		id = "health_therapy_session",
		title = "Therapy Progress",
		emoji = "🛋️",
		text = "You're in therapy working on yourself.",
		question = "How is therapy going?",
		minAge = 14, maxAge = 90,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "mental_health",
		tags = { "therapy", "healing", "growth" },
		requiresFlags = { therapy = true },
		
		-- CRITICAL: Random therapy progress
		choices = {
			{
				text = "Have a breakthrough session",
				effects = { Money = -80 },
				feedText = "Processing in therapy...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Health", 5)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.therapy_breakthrough = true
						state:AddFeed("🛋️ BREAKTHROUGH! Connected the dots! Healing!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", 2)
						state:AddFeed("🛋️ Good session. Slow progress but progress.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🛋️ Tough session. Brought up hard stuff. Draining but necessary.")
					end
				end,
			},
		},
	},
	{
		id = "health_meditation_practice",
		title = "Meditation Practice",
		emoji = "🧘",
		text = "Trying to build a meditation habit.",
		question = "How is your practice going?",
		minAge = 10, maxAge = 100,
		baseChance = 0.25,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "wellness",
		tags = { "meditation", "mindfulness", "peace" },
		
		choices = {
			{
				text = "Commit to daily practice",
				effects = {},
				feedText = "Finding your center...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Health", 4)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.meditator = true
						state:AddFeed("🧘 Mind is clearer. Less reactive. Finding peace.")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 3)
						state:ModifyStat("Health", 2)
						state:AddFeed("🧘 Some sessions better than others. Keep trying.")
					else
						state:ModifyStat("Happiness", -1)
						state:AddFeed("🧘 Mind won't quiet. Frustrating. Maybe try guided.")
					end
				end,
			},
			{ text = "Use meditation app", effects = { Money = -10, Happiness = 4, Health = 3 }, feedText = "🧘 App helps! Structure and guidance working!" },
			{ text = "Too restless to meditate", effects = { Happiness = 1 }, feedText = "🧘 Not for everyone. Other ways to find peace." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SLEEP & REST
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "health_sleep_issues",
		title = "Sleep Problems",
		emoji = "😴",
		text = "Your sleep has been off!",
		question = "What's the sleep situation?",
		minAge = 12, maxAge = 90,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "sleep", "insomnia", "rest" },
		
		-- CRITICAL: Random sleep outcome
		choices = {
			{
				text = "Try to fix sleep schedule",
				effects = {},
				feedText = "Working on sleep hygiene...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Health", 4)
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.good_sleeper = true
						state:AddFeed("😴 Sleep is better! Waking up refreshed!")
					elseif roll < 0.75 then
						state:ModifyStat("Health", 1)
						state:AddFeed("😴 Some improvement. Still working on it.")
					else
						state:ModifyStat("Health", -2)
						state:ModifyStat("Happiness", -3)
						state.Flags = state.Flags or {}
						state.Flags.insomnia = true
						state:AddFeed("😴 Can't sleep. Lying awake for hours. Exhausted.")
					end
				end,
			},
			{ text = "Take sleep aids", effects = { Money = -20, Health = -1 }, feedText = "😴 Meds knock you out but groggy mornings.",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("😴 At least getting some sleep. Band-aid solution.")
					else
						state:ModifyStat("Health", -2)
						state.Flags = state.Flags or {}
						state.Flags.sleep_med_dependency = true
						state:AddFeed("😴 Building tolerance. Need stronger dose.")
					end
				end,
			},
			{ text = "See sleep specialist", effects = { Money = -150, Health = 5, Happiness = 4 }, feedText = "😴 Sleep study revealed issues. Treatment helping!" },
		},
	},
	{
		id = "health_vivid_dreams",
		title = "Vivid Dreams",
		emoji = "💭",
		text = "Your dreams have been intense lately!",
		question = "What kind of dreams?",
		minAge = 8, maxAge = 90,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "dreams", "sleep", "subconscious" },
		
		choices = {
			{ text = "Amazingly pleasant dreams", effects = { Happiness = 5, Health = 1 }, feedText = "💭 Woke up feeling wonderful! Dreams like vacation!" },
			{ text = "Nightmares", effects = { Happiness = -4, Health = -1 }, setFlags = { nightmares = true }, feedText = "💭 Woke up scared. Heart pounding. Bad stuff." },
			{ text = "Prophetic/meaningful feeling", effects = { Happiness = 3, Smarts = 2 }, feedText = "💭 Felt significant. What does it mean?" },
			{ text = "Lucid dreaming!", effects = { Happiness = 6, Smarts = 2 }, setFlags = { lucid_dreamer = true }, feedText = "💭 Controlled the dream! Flying! Amazing!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- WELLNESS & LIFESTYLE
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "health_nutrition_focus",
		title = "Nutrition Awareness",
		emoji = "🥗",
		text = "Thinking about your eating habits.",
		question = "What changes do you make?",
		minAge = 15, maxAge = 90,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "wellness",
		tags = { "nutrition", "diet", "health" },
		
		choices = {
			{
				text = "Clean up your diet",
				effects = { Money = -30 },
				feedText = "Eating healthier...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.healthy_eater = true
						state:AddFeed("🥗 Feeling so much better! Energy up! Healthier!")
					else
						state:ModifyStat("Health", 2)
						state:ModifyStat("Happiness", 1)
						state:AddFeed("🥗 Some improvement. Cravings are tough.")
					end
				end,
			},
			{ text = "Go vegetarian/vegan", effects = { Health = 3, Happiness = 4, Money = -20 }, setFlags = { vegetarian = true }, feedText = "🥗 Plant-based life! Feel lighter and cleaner!" },
			{ text = "Keep eating whatever", effects = { Happiness = 2, Health = -1 }, feedText = "🥗 YOLO. Pizza is a vegetable, right?" },
		},
	},
	{
		id = "health_hydration",
		title = "Hydration Reminder",
		emoji = "💧",
		text = "Have you been drinking enough water?",
		question = "How are your hydration habits?",
		minAge = 10, maxAge = 100,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "wellness",
		tags = { "water", "hydration", "health" },
		
		choices = {
			{ text = "Start drinking more water", effects = { Health = 3, Happiness = 2 }, setFlags = { hydrated = true }, feedText = "💧 8 glasses a day! Skin better! More energy!" },
			{ text = "Living on coffee/soda", effects = { Health = -2, Happiness = 1 }, feedText = "💧 Caffeine is technically water, right? Wrong." },
			{ text = "Get a nice water bottle", effects = { Money = -20, Health = 2, Happiness = 3 }, feedText = "💧 Fancy bottle motivates you! Hydration achievement!" },
		},
	},
	{
		id = "health_screen_time",
		title = "Screen Time Awareness",
		emoji = "📱",
		text = "Your screen time has been excessive!",
		question = "What do you do about it?",
		minAge = 8, maxAge = 70,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "wellness",
		tags = { "screens", "digital", "wellness" },
		
		choices = {
			{
				text = "Digital detox attempt",
				effects = {},
				feedText = "Putting down the phone...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Health", 3)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.digital_balanced = true
						state:AddFeed("📱 SUCCESS! Less anxiety! More present! Life is better!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📱 Some progress. Still catching yourself scrolling.")
					else
						state:ModifyStat("Happiness", -1)
						state:AddFeed("📱 Lasted 2 hours. FOMO won. Back to scrolling.")
					end
				end,
			},
			{ text = "Set app limits", effects = { Happiness = 3, Health = 1 }, feedText = "📱 Limits help a bit. At least aware now." },
			{ text = "Embrace the addiction", effects = { Happiness = 1, Health = -2 }, setFlags = { phone_addict = true }, feedText = "📱 This IS life now. Screens forever." },
		},
	},
	{
		id = "health_substance_choice",
		title = "Substance Decision",
		emoji = "🍺",
		text = "Thinking about your relationship with alcohol/substances.",
		question = "What's your approach?",
		minAge = 18, maxAge = 90,
		baseChance = 0.2,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "wellness",
		tags = { "alcohol", "substances", "choices" },
		
		choices = {
			{ text = "Moderation - social only", effects = { Happiness = 3, Health = 0 }, feedText = "🍺 Balanced approach. Enjoy occasionally." },
			{ text = "Cut back significantly", effects = { Happiness = 4, Health = 4, Money = 50 }, setFlags = { sober_curious = true }, feedText = "🍺 Drinking less. Feeling better. Saving money!" },
			{ text = "Go completely sober", effects = { Happiness = 6, Health = 6, Money = 100 }, setFlags = { sober = true }, feedText = "🍺 Sober life! Clarity! Health! Best decision!" },
			{ text = "Overindulging", effects = { Happiness = -2, Health = -5, Money = -50 }, setFlags = { drinking_problem = true }, feedText = "🍺 Drinking too much. This is becoming a problem." },
		},
	},
}

return HealthEvents
