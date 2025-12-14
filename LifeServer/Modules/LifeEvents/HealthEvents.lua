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
						-- CRITICAL FIX #532: Prevent money going negative
						state.Money = math.max(0, (state.Money or 0) - 100)
						state:AddFeed("🩹 Moderate injury. Sprain or strain. Weeks to heal.")
					elseif roll < 0.90 then
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -8)
						-- CRITICAL FIX #533: Prevent money going negative
						state.Money = math.max(0, (state.Money or 0) - 500)
						state.Flags = state.Flags or {}
						state.Flags.serious_injury = true
						state:AddFeed("🩹 Serious injury. Broken bone. Surgery needed. Months of recovery.")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -12)
						-- CRITICAL FIX #534: Prevent money going negative, add medical debt flag
						local medCost = 2000
						if (state.Money or 0) < medCost then
							state.Flags = state.Flags or {}
							state.Flags.medical_debt = true
						end
						state.Money = math.max(0, (state.Money or 0) - medCost)
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
						-- CRITICAL FIX #535: Prevent money going negative
						state.Money = math.max(0, (state.Money or 0) - 100)
						state:AddFeed("🦷 One cavity. Filling needed. $100 more.")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", -5)
						state:ModifyStat("Health", -2)
						-- CRITICAL FIX #536: Prevent money going negative
						state.Money = math.max(0, (state.Money or 0) - 300)
						state:AddFeed("🦷 Multiple issues. Crown or root canal. $300. Painful.")
					else
						state:ModifyStat("Happiness", -8)
						state:ModifyStat("Health", -3)
						-- CRITICAL FIX #537: Prevent money going negative
						state.Money = math.max(0, (state.Money or 0) - 1000)
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
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #231-250: DISEASE DIAGNOSIS CARDS
	-- These events show exactly what illness the player has when diagnosed
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "health_diagnosis_cold_flu",
		title = "🤒 Diagnosis: Cold or Flu",
		emoji = "🤒",
		text = "The doctor has diagnosed you with a cold or flu virus!",
		question = "Your diagnosis: Common Cold/Flu\n\nSymptoms: Runny nose, cough, fever, body aches\nSeverity: Mild to Moderate\nRecovery Time: 1-2 weeks\n\nWhat do you want to do?",
		minAge = 3, maxAge = 100,
		baseChance = 0.15,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "cold", "flu", "illness" },
		isDiagnosisCard = true,
		diagnosisType = "cold_flu",
		
		choices = {
			{ text = "Rest at home", effects = { Health = 3, Happiness = -2 }, setFlags = { has_cold = true }, feedText = "🤒 Resting at home. Should recover in a week." },
			{ text = "Take medication", effects = { Money = -30, Health = 5, Happiness = 1 }, feedText = "🤒 Over-the-counter meds helping with symptoms." },
			{ text = "Push through it", effects = { Health = -3, Happiness = -4 }, setFlags = { prolonged_illness = true }, feedText = "🤒 Made it worse by not resting. Recovery delayed." },
		},
	},
	{
		id = "health_diagnosis_diabetes",
		title = "💉 Diagnosis: Diabetes",
		emoji = "💉",
		text = "After testing, the doctor has diagnosed you with diabetes.",
		question = "Your diagnosis: TYPE 2 DIABETES\n\n🩸 Blood Sugar: Elevated\n⚠️ Severity: Chronic Condition\n💊 Treatment: Lifestyle changes + medication\n\nThis is a lifelong condition that requires management.",
		minAge = 25, maxAge = 100,
		baseChance = 0.05,
		cooldown = 100, -- Only diagnose once
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "diabetes", "chronic" },
		isDiagnosisCard = true,
		diagnosisType = "diabetes",
		oneTime = true,
		maxOccurrences = 1,
		eligibility = function(state)
			local health = (state.Stats and state.Stats.Health) or 50
			local flags = state.Flags or {}
			return health < 60 and not flags.diabetes
		end,
		
		choices = {
			{
				text = "Accept treatment plan",
				effects = { Happiness = -5, Health = -10 },
				setFlags = { diabetes = true, chronic_illness = true, on_medication = true },
				feedText = "💉 Diabetes diagnosis. Started insulin and lifestyle changes.",
			},
			{
				text = "Get second opinion",
				effects = { Money = -200, Happiness = -3 },
				feedText = "💉 Second doctor confirmed. You have diabetes.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.diabetes = true
					state.Flags.chronic_illness = true
				end,
			},
			{
				text = "Deny and ignore it",
				effects = { Health = -15 },
				setFlags = { diabetes = true, untreated_condition = true },
				feedText = "💉 Ignoring diabetes is dangerous. Condition will worsen.",
			},
		},
	},
	{
		id = "health_diagnosis_heart_disease",
		title = "❤️‍🩹 Diagnosis: Heart Disease",
		emoji = "❤️‍🩹",
		text = "Cardiac tests have revealed a serious condition.",
		question = "Your diagnosis: HEART DISEASE\n\n💔 Condition: Coronary Artery Disease\n⚠️ Severity: SERIOUS\n🏥 Treatment Required: Yes\n💊 Medication: Blood thinners, statins\n\nThis requires immediate lifestyle changes.",
		minAge = 40, maxAge = 100,
		baseChance = 0.04,
		cooldown = 100,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "heart", "serious" },
		isDiagnosisCard = true,
		diagnosisType = "heart_disease",
		oneTime = true,
		maxOccurrences = 1,
		eligibility = function(state)
			local health = (state.Stats and state.Stats.Health) or 50
			local age = state.Age or 30
			local flags = state.Flags or {}
			return (age > 45 and health < 55) and not flags.heart_disease
		end,
		
		choices = {
			{
				text = "Start treatment immediately",
				effects = { Happiness = -10, Money = -500, Health = -15 },
				setFlags = { heart_disease = true, chronic_illness = true, on_heart_medication = true },
				feedText = "❤️‍🩹 Heart disease diagnosed. On medication and strict diet now.",
			},
			{
				text = "Get bypass surgery if needed",
				effects = { Happiness = -15, Money = -5000, Health = 5 },
				setFlags = { heart_disease = true, had_heart_surgery = true },
				feedText = "❤️‍🩹 Underwent heart surgery. Long recovery ahead.",
			},
		},
	},
	{
		id = "health_diagnosis_cancer",
		title = "🎗️ Diagnosis: Cancer",
		emoji = "🎗️",
		text = "The biopsy results have come back. The news is serious.",
		question = "Your diagnosis: CANCER DETECTED\n\n🔬 Finding: Malignant cells detected\n⚠️ Severity: CRITICAL\n🏥 Treatment: Chemotherapy/Radiation/Surgery\n⏰ Early detection increases survival rate\n\nThis is a life-changing diagnosis.",
		minAge = 20, maxAge = 100,
		baseChance = 0.02,
		cooldown = 100,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "cancer", "critical" },
		isDiagnosisCard = true,
		diagnosisType = "cancer",
		oneTime = true,
		maxOccurrences = 1,
		eligibility = function(state)
			local flags = state.Flags or {}
			return not flags.has_cancer and not flags.cancer_survivor
		end,
		
		choices = {
			{
				text = "Fight it - start treatment",
				effects = { Happiness = -20, Money = -10000, Health = -25 },
				setFlags = { has_cancer = true, cancer = true, in_treatment = true, fighting_cancer = true },
				feedText = "🎗️ Cancer diagnosis. Starting chemotherapy. Fight of your life.",
				onResolve = function(state)
					-- 60% chance of survival with treatment
					local roll = math.random()
					if roll < 0.60 then
						state.Flags.cancer_survivor = true
						state.Flags.in_remission = true
						state:AddFeed("🎗️ After months of treatment, you're in remission! You beat it!")
					else
						state.Flags.terminal_illness = true
						state:AddFeed("🎗️ Treatment isn't working as hoped. This is serious.")
					end
				end,
			},
			{
				text = "Refuse treatment (accept fate)",
				effects = { Happiness = -30, Health = -40 },
				setFlags = { has_cancer = true, terminal_illness = true, refusing_treatment = true },
				feedText = "🎗️ Choosing to live remaining time without treatment.",
			},
		},
	},
	{
		id = "health_diagnosis_depression",
		title = "😔 Diagnosis: Clinical Depression",
		emoji = "😔",
		text = "After evaluation, the psychiatrist has made a diagnosis.",
		question = "Your diagnosis: CLINICAL DEPRESSION\n\n🧠 Type: Major Depressive Disorder\n⏰ Duration: You've been struggling for a while\n💊 Treatment: Therapy + possible medication\n\nMental health is real health. Help is available.",
		minAge = 12, maxAge = 100,
		baseChance = 0.08,
		cooldown = 100,
		stage = STAGE,
		ageBand = "any",
		category = "mental_health",
		tags = { "diagnosis", "depression", "mental_health" },
		isDiagnosisCard = true,
		diagnosisType = "depression",
		oneTime = true,
		maxOccurrences = 1,
		eligibility = function(state)
			local happiness = (state.Stats and state.Stats.Happiness) or 50
			local flags = state.Flags or {}
			return happiness < 35 and not flags.depression
		end,
		
		choices = {
			{
				text = "Start therapy and medication",
				effects = { Money = -100, Happiness = 5, Health = 3 },
				setFlags = { depression = true, mental_illness = true, depression_treatment = true, therapy = true },
				feedText = "😔 Depression diagnosed. Starting treatment. It gets better.",
			},
			{
				text = "Try therapy only",
				effects = { Money = -80, Happiness = 3 },
				setFlags = { depression = true, mental_illness = true, therapy = true },
				feedText = "😔 Starting therapy for depression. Taking the first step.",
			},
			{
				text = "Deny the diagnosis",
				effects = { Happiness = -10, Health = -5 },
				setFlags = { depression = true, untreated_depression = true },
				feedText = "😔 Refusing to accept the diagnosis. The struggle continues.",
			},
		},
	},
	{
		id = "health_diagnosis_anxiety",
		title = "😰 Diagnosis: Anxiety Disorder",
		emoji = "😰",
		text = "Your symptoms have been evaluated by a mental health professional.",
		question = "Your diagnosis: GENERALIZED ANXIETY DISORDER\n\n🧠 Type: GAD (Generalized Anxiety Disorder)\n⚡ Symptoms: Constant worry, panic attacks, restlessness\n💊 Treatment: Therapy, possible medication\n\nAnxiety is treatable. You don't have to live like this.",
		minAge = 12, maxAge = 100,
		baseChance = 0.07,
		cooldown = 100,
		stage = STAGE,
		ageBand = "any",
		category = "mental_health",
		tags = { "diagnosis", "anxiety", "mental_health" },
		isDiagnosisCard = true,
		diagnosisType = "anxiety",
		oneTime = true,
		maxOccurrences = 1,
		eligibility = function(state)
			local flags = state.Flags or {}
			return not flags.anxiety and (flags.stressed or flags.panic_attacks or flags.nervous)
		end,
		
		choices = {
			{
				text = "Start treatment",
				effects = { Money = -100, Happiness = 5 },
				setFlags = { anxiety = true, mental_illness = true, anxiety_treatment = true },
				feedText = "😰 Anxiety diagnosed. Starting therapy and learning coping strategies.",
			},
			{
				text = "Try medication",
				effects = { Money = -50, Happiness = 3, Health = 1 },
				setFlags = { anxiety = true, on_anxiety_meds = true },
				feedText = "😰 Anti-anxiety medication prescribed. Taking the edge off.",
			},
		},
	},
	{
		id = "health_diagnosis_std",
		title = "🦠 Diagnosis: STI Detected",
		emoji = "🦠",
		text = "Your test results are back. You've contracted an STI.",
		question = "Your diagnosis: SEXUALLY TRANSMITTED INFECTION\n\n🔬 Status: Positive\n⚠️ Type: Bacterial/Viral STI detected\n💊 Treatment: Antibiotics/Antivirals available\n🩺 Follow-up: Required\n\nPlease inform recent partners.",
		minAge = 16, maxAge = 80,
		baseChance = 0.05,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "std", "sexual_health" },
		isDiagnosisCard = true,
		diagnosisType = "std",
		eligibility = function(state)
			local flags = state.Flags or {}
			return flags.sexually_active and not flags.always_safe and not flags.has_std
		end,
		
		choices = {
			{
				text = "Get treated immediately",
				effects = { Money = -200, Happiness = -10, Health = 5 },
				setFlags = { had_std = true },
				feedText = "🦠 STI treated with antibiotics. Cured! Be more careful.",
			},
			{
				text = "Ignore it (dangerous!)",
				effects = { Health = -15, Happiness = -5 },
				setFlags = { has_std = true, untreated_std = true },
				feedText = "🦠 Ignoring an STI is dangerous. Will get worse.",
			},
		},
	},
	{
		id = "health_diagnosis_hiv",
		title = "🩸 Diagnosis: HIV Positive",
		emoji = "🩸",
		text = "The HIV test results have come back positive.",
		question = "Your diagnosis: HIV POSITIVE\n\n🩸 Status: HIV Positive\n⚠️ Severity: LIFELONG CONDITION\n💊 Treatment: Antiretroviral therapy (ART)\n✅ With treatment: Normal life expectancy possible\n\nThis is treatable. You can live a full life.",
		minAge = 18, maxAge = 80,
		baseChance = 0.01,
		cooldown = 100,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "hiv", "serious" },
		isDiagnosisCard = true,
		diagnosisType = "hiv",
		oneTime = true,
		maxOccurrences = 1,
		eligibility = function(state)
			local flags = state.Flags or {}
			return not flags.hiv_positive
		end,
		
		choices = {
			{
				text = "Start antiretroviral treatment",
				effects = { Money = -300, Happiness = -15, Health = -5 },
				setFlags = { hiv_positive = true, chronic_illness = true, on_art_treatment = true },
				feedText = "🩸 HIV positive. Starting ART. With treatment, you can live normally.",
			},
			{
				text = "Seek support groups",
				effects = { Happiness = -10, Health = -3 },
				setFlags = { hiv_positive = true, hiv_support = true },
				feedText = "🩸 Finding community and support. You're not alone in this.",
				onResolve = function(state)
					state.Flags.on_art_treatment = true
				end,
			},
		},
	},
	{
		id = "health_diagnosis_broken_bone",
		title = "🦴 Diagnosis: Broken Bone",
		emoji = "🦴",
		text = "The X-ray confirms it - you have a fracture.",
		question = "Your diagnosis: BONE FRACTURE\n\n🦴 Type: Fracture detected\n📍 Location: [varies]\n⏰ Recovery: 6-8 weeks\n🏥 Treatment: Cast/splint required\n\nNo heavy lifting for a while!",
		minAge = 5, maxAge = 90,
		baseChance = 0.08,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "injury", "bone" },
		isDiagnosisCard = true,
		diagnosisType = "broken_bone",
		
		choices = {
			{
				text = "Get it set and wear the cast",
				effects = { Money = -500, Health = -5, Happiness = -5 },
				setFlags = { broken_bone = true, in_cast = true },
				feedText = "🦴 Bone set, cast on. 6 weeks of limited mobility.",
			},
			{
				text = "Surgery if needed",
				effects = { Money = -3000, Health = 5, Happiness = -8 },
				setFlags = { had_bone_surgery = true },
				feedText = "🦴 Needed surgery to fix properly. Pins and plates inserted.",
			},
		},
	},
	{
		id = "health_checkup_results_detailed",
		title = "📋 Detailed Health Report",
		emoji = "📋",
		text = "Your comprehensive health checkup results are ready!",
		question = "Your Health Report Card:",
		minAge = 18, maxAge = 100,
		baseChance = 0.15,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "checkup", "report", "detailed" },
		isDiagnosisCard = true,
		diagnosisType = "checkup",
		
		-- Dynamic question based on health state
		preProcess = function(state, eventDef)
			local health = (state.Stats and state.Stats.Health) or 50
			local flags = state.Flags or {}
			local conditions = {}
			
			-- Check for existing conditions
			if flags.diabetes then table.insert(conditions, "💉 Diabetes: Managed") end
			if flags.heart_disease then table.insert(conditions, "❤️‍🩹 Heart Disease: Monitoring") end
			if flags.depression then table.insert(conditions, "😔 Depression: " .. (flags.depression_treatment and "In Treatment" or "Untreated")) end
			if flags.anxiety then table.insert(conditions, "😰 Anxiety: " .. (flags.anxiety_treatment and "In Treatment" or "Untreated")) end
			if flags.chronic_illness then table.insert(conditions, "⚕️ Chronic Condition: Active") end
			if flags.hiv_positive then table.insert(conditions, "🩸 HIV: " .. (flags.on_art_treatment and "Controlled w/ ART" or "Uncontrolled")) end
			
			local healthStatus = "Unknown"
			if health >= 80 then healthStatus = "✅ EXCELLENT"
			elseif health >= 60 then healthStatus = "👍 GOOD"
			elseif health >= 40 then healthStatus = "⚠️ FAIR - Needs Attention"
			elseif health >= 20 then healthStatus = "⚠️ POOR - Treatment Needed"
			else healthStatus = "🚨 CRITICAL - Immediate Care Needed"
			end
			
			local reportText = "📋 COMPREHENSIVE HEALTH REPORT\n\n"
			reportText = reportText .. "Overall Health: " .. healthStatus .. "\n"
			reportText = reportText .. "Health Score: " .. tostring(health) .. "/100\n\n"
			
			if #conditions > 0 then
				reportText = reportText .. "Current Conditions:\n"
				for _, condition in ipairs(conditions) do
					reportText = reportText .. "• " .. condition .. "\n"
				end
			else
				reportText = reportText .. "✅ No chronic conditions detected!\n"
			end
			
			reportText = reportText .. "\nWhat would you like to do?"
			
			eventDef.question = reportText
			return true
		end,
		
		choices = {
			{
				text = "Review results with doctor",
				effects = { Money = -50, Happiness = 3, Smarts = 2 },
				feedText = "📋 Discussed results. Now have a clear health plan.",
			},
			{
				text = "Schedule follow-up tests",
				effects = { Money = -100, Health = 2 },
				feedText = "📋 Booked additional tests for thorough assessment.",
			},
			{
				text = "File it away (ignore)",
				effects = { Happiness = 1 },
				feedText = "📋 Put it in a drawer. Out of sight, out of mind.",
			},
		},
	},
}

-- CRITICAL FIX #251: Export events in standard format for LifeEvents loader
HealthEvents.LifeEvents = HealthEvents.events

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #498-500: DISEASE TRACKING AND PROGRESSION SYSTEM
-- Tracks active diseases and their effects over time
-- ═══════════════════════════════════════════════════════════════════════════════

HealthEvents.DiseaseTypes = {
	cold_flu = { 
		name = "Cold/Flu", 
		severity = "mild", 
		duration = 1, 
		healthImpact = -2,
		canSpread = true,
	},
	diabetes = {
		name = "Diabetes",
		severity = "chronic",
		duration = -1, -- Lifelong
		healthImpact = -3, -- Per year if untreated
		manageable = true,
		managedHealthImpact = -1,
	},
	heart_disease = {
		name = "Heart Disease",
		severity = "serious",
		duration = -1,
		healthImpact = -5,
		manageable = true,
		managedHealthImpact = -2,
		fatalityRisk = 0.05,
	},
	cancer = {
		name = "Cancer",
		severity = "critical",
		duration = -1,
		healthImpact = -10,
		treatmentRequired = true,
		fatalityRisk = 0.15,
		treatedFatalityRisk = 0.03,
	},
	depression = {
		name = "Clinical Depression",
		severity = "moderate",
		duration = -1,
		healthImpact = -1,
		happinessImpact = -5,
		manageable = true,
		managedHappinessImpact = -1,
	},
	anxiety = {
		name = "Anxiety Disorder",
		severity = "moderate",
		duration = -1,
		healthImpact = -1,
		happinessImpact = -3,
		manageable = true,
	},
	hiv = {
		name = "HIV",
		severity = "serious",
		duration = -1,
		healthImpact = -5,
		manageable = true,
		managedHealthImpact = -1,
		fatalityRisk = 0.02,
	},
	broken_bone = {
		name = "Broken Bone",
		severity = "moderate",
		duration = 1,
		healthImpact = -5,
	},
}

function HealthEvents.initDiseaseTracking(state)
	state.ActiveDiseases = state.ActiveDiseases or {}
	state.MedicalHistory = state.MedicalHistory or {}
end

function HealthEvents.addDisease(state, diseaseType, options)
	HealthEvents.initDiseaseTracking(state)
	options = options or {}
	
	local diseaseInfo = HealthEvents.DiseaseTypes[diseaseType]
	if not diseaseInfo then
		return false, "Unknown disease type"
	end
	
	-- Check if already has this disease
	if state.ActiveDiseases[diseaseType] then
		return false, "Already has this disease"
	end
	
	state.ActiveDiseases[diseaseType] = {
		type = diseaseType,
		name = diseaseInfo.name,
		severity = diseaseInfo.severity,
		diagnosedAge = state.Age,
		diagnosedYear = state.Year,
		inTreatment = options.inTreatment or false,
		managed = options.managed or false,
		yearsWithCondition = 0,
	}
	
	-- Set flag
	state.Flags = state.Flags or {}
	state.Flags[diseaseType] = true
	state.Flags.has_illness = true
	
	if diseaseInfo.severity == "chronic" or diseaseInfo.severity == "serious" or diseaseInfo.severity == "critical" then
		state.Flags.chronic_illness = true
	end
	
	-- Record in medical history
	table.insert(state.MedicalHistory, {
		type = "diagnosis",
		disease = diseaseType,
		name = diseaseInfo.name,
		age = state.Age,
		year = state.Year,
	})
	
	return true, diseaseInfo
end

function HealthEvents.removeDisease(state, diseaseType)
	HealthEvents.initDiseaseTracking(state)
	
	if not state.ActiveDiseases[diseaseType] then
		return false, "Does not have this disease"
	end
	
	local disease = state.ActiveDiseases[diseaseType]
	state.ActiveDiseases[diseaseType] = nil
	
	-- Clear flag
	if state.Flags then
		state.Flags[diseaseType] = nil
	end
	
	-- Check if any diseases remain
	local hasAnyDisease = false
	for _ in pairs(state.ActiveDiseases) do
		hasAnyDisease = true
		break
	end
	if not hasAnyDisease and state.Flags then
		state.Flags.has_illness = nil
	end
	
	-- Record in medical history
	table.insert(state.MedicalHistory, {
		type = "recovery",
		disease = diseaseType,
		name = disease.name,
		age = state.Age,
		year = state.Year,
		yearsAfflicted = disease.yearsWithCondition,
	})
	
	return true
end

function HealthEvents.tickDiseases(state)
	HealthEvents.initDiseaseTracking(state)
	
	local effects = {
		healthChange = 0,
		happinessChange = 0,
		died = false,
		deathCause = nil,
		messages = {},
	}
	
	for diseaseType, disease in pairs(state.ActiveDiseases) do
		local info = HealthEvents.DiseaseTypes[diseaseType]
		if not info then continue end
		
		disease.yearsWithCondition = (disease.yearsWithCondition or 0) + 1
		
		-- Check for natural recovery (temporary illnesses)
		if info.duration > 0 and disease.yearsWithCondition >= info.duration then
			HealthEvents.removeDisease(state, diseaseType)
			table.insert(effects.messages, "Recovered from " .. info.name)
			continue
		end
		
		-- Apply health impact
		local healthImpact = info.healthImpact or 0
		if disease.managed and info.managedHealthImpact then
			healthImpact = info.managedHealthImpact
		end
		effects.healthChange = effects.healthChange + healthImpact
		
		-- Apply happiness impact (mental health conditions)
		if info.happinessImpact then
			local happinessImpact = info.happinessImpact
			if disease.managed and info.managedHappinessImpact then
				happinessImpact = info.managedHappinessImpact
			end
			effects.happinessChange = effects.happinessChange + happinessImpact
		end
		
		-- Check fatality risk
		local fatalityRisk = info.fatalityRisk or 0
		if disease.inTreatment and info.treatedFatalityRisk then
			fatalityRisk = info.treatedFatalityRisk
		end
		
		if fatalityRisk > 0 then
			local roll = math.random()
			if roll < fatalityRisk then
				effects.died = true
				effects.deathCause = info.name
				break
			end
		end
	end
	
	return effects
end

function HealthEvents.getActiveDiseaseCount(state)
	HealthEvents.initDiseaseTracking(state)
	local count = 0
	for _ in pairs(state.ActiveDiseases) do
		count = count + 1
	end
	return count
end

function HealthEvents.hasChronicCondition(state)
	HealthEvents.initDiseaseTracking(state)
	for diseaseType, _ in pairs(state.ActiveDiseases) do
		local info = HealthEvents.DiseaseTypes[diseaseType]
		if info and (info.severity == "chronic" or info.severity == "serious") then
			return true
		end
	end
	return false
end

function HealthEvents.setTreatment(state, diseaseType, inTreatment)
	HealthEvents.initDiseaseTracking(state)
	if state.ActiveDiseases[diseaseType] then
		state.ActiveDiseases[diseaseType].inTreatment = inTreatment
		state.ActiveDiseases[diseaseType].managed = inTreatment
		return true
	end
	return false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #501-503: HEALTH SUMMARY AND REPORTING
-- Generates comprehensive health reports for the player
-- ═══════════════════════════════════════════════════════════════════════════════

function HealthEvents.getHealthSummary(state)
	HealthEvents.initDiseaseTracking(state)
	
	local summary = {
		overallHealth = (state.Stats and state.Stats.Health) or state.Health or 50,
		activeDiseases = {},
		chronicConditions = 0,
		inTreatment = 0,
		healthRisks = {},
	}
	
	-- List active diseases
	for diseaseType, disease in pairs(state.ActiveDiseases) do
		local info = HealthEvents.DiseaseTypes[diseaseType]
		table.insert(summary.activeDiseases, {
			name = info and info.name or diseaseType,
			severity = info and info.severity or "unknown",
			yearsAfflicted = disease.yearsWithCondition,
			inTreatment = disease.inTreatment,
			managed = disease.managed,
		})
		
		if info and (info.severity == "chronic" or info.severity == "serious") then
			summary.chronicConditions = summary.chronicConditions + 1
		end
		
		if disease.inTreatment then
			summary.inTreatment = summary.inTreatment + 1
		end
	end
	
	-- Check health risks based on flags
	local flags = state.Flags or {}
	if flags.smoker then
		table.insert(summary.healthRisks, "Smoking increases cancer and heart disease risk")
	end
	if flags.heavy_drinker then
		table.insert(summary.healthRisks, "Heavy drinking damages liver and heart")
	end
	if flags.obese then
		table.insert(summary.healthRisks, "Obesity increases diabetes and heart disease risk")
	end
	if flags.sedentary then
		table.insert(summary.healthRisks, "Sedentary lifestyle reduces overall health")
	end
	
	-- Calculate overall status
	if summary.overallHealth >= 80 and #summary.activeDiseases == 0 then
		summary.status = "EXCELLENT"
	elseif summary.overallHealth >= 60 then
		summary.status = "GOOD"
	elseif summary.overallHealth >= 40 then
		summary.status = "FAIR"
	elseif summary.overallHealth >= 20 then
		summary.status = "POOR"
	else
		summary.status = "CRITICAL"
	end
	
	return summary
end

return HealthEvents
