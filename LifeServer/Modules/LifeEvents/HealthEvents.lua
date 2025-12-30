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
		-- CRITICAL FIX: Text variations for more variety
		textVariants = {
			"You woke up feeling terrible. Head pounding, body aching...",
			"Something's definitely wrong. You feel awful.",
			"You've been fighting off something for days. Now it's hit hard.",
			"Fever, chills, the works. You're sick.",
			"Your body is telling you to slow down. You feel miserable.",
			"That tickle in your throat turned into full-blown sickness.",
		},
		question = "What's wrong?",
		minAge = 3, maxAge = 100,
		baseChance = 0.555,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "illness", "sick", "recovery" },
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Illness MORE LIKELY when health is low!
		-- User bug: "health events aren't linked to health stat"
		-- Low health = higher chance of getting sick, high health = lower chance
		-- ═══════════════════════════════════════════════════════════════════════════════
		getWeight = function(state)
			local health = (state.Stats and state.Stats.Health) or 50
			-- Base weight: 100
			-- Low health (< 30): +50 weight (150 total = much more likely)
			-- Medium health (30-60): +25 weight (125 total)
			-- Good health (60-80): 0 bonus (100 total)
			-- Excellent health (> 80): -30 weight (70 total = less likely)
			if health < 30 then
				return 150
			elseif health < 60 then
				return 125
			elseif health > 80 then
				return 70
			end
			return 100
		end,
		
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
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then
							state:ModifyStat("Health", 2)
							state:ModifyStat("Happiness", 3)
						end
						if state.AddFeed then state:AddFeed("🤒 Quick recovery! Back on your feet!") end
					elseif roll < 0.85 then
						if state.ModifyStat then
							state:ModifyStat("Health", -2)
							state:ModifyStat("Happiness", -3)
						end
						if state.AddFeed then state:AddFeed("🤒 Rough few days but getting better.") end
					else
						if state.ModifyStat then
							state:ModifyStat("Health", -5)
							state:ModifyStat("Happiness", -5)
						end
						state.Flags = state.Flags or {}
						state.Flags.prolonged_illness = true
						if state.AddFeed then state:AddFeed("🤒 This is lasting longer than expected. Worry setting in.") end
					end
				end,
			},
		{ text = "Push through it", effects = { Health = -3, Happiness = -2, Smarts = 1 }, feedText = "🤒 Working sick. Spreading germs. Delayed recovery." },
		{ text = "Go to doctor ($50)", effects = { Money = -50, Health = 3 }, feedText = "🤒 Got proper treatment. Meds helping.", eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 for doctor" end },
		},
	},
	{
		id = "health_injury_accident",
		title = "Accident/Injury",
		emoji = "🩹",
		text = "You've been injured!",
		-- CRITICAL FIX: Text variations for more variety
		textVariants = {
			"Ouch! You've hurt yourself in an accident.",
			"Something went wrong and now you're injured.",
			"A sudden mishap left you nursing an injury.",
			"You had an accident. Time to assess the damage.",
			"An unexpected fall/collision left you injured.",
			"You got hurt! It happened so fast...",
		},
		question = "How bad is it?",
		minAge = 5, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "injury", "accident", "recovery" },
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Injuries MORE LIKELY when health is low!
		-- User bug: "health events aren't linked to health stat"
		-- Low health = more prone to accidents, high health = less likely
		-- ═══════════════════════════════════════════════════════════════════════════════
		getWeight = function(state)
			local health = (state.Stats and state.Stats.Health) or 50
			local age = state.Age or 30
			-- Base weight: 100
			-- Low health (< 30): +60 weight (160 = much more likely)
			-- Old age (> 70): +40 weight (accidents more likely with age)
			-- Excellent health (> 80): -40 weight (60 = less likely)
			local weight = 100
			if health < 30 then
				weight = weight + 60
			elseif health < 50 then
				weight = weight + 30
			elseif health > 80 then
				weight = weight - 40
			end
			-- Older people more prone to falls/injuries
			if age > 70 then
				weight = weight + 40
			elseif age > 50 then
				weight = weight + 20
			end
			return weight
		end,
		
		-- CRITICAL: Random injury severity
		choices = {
			{
				text = "Assess the damage",
				effects = {},
				feedText = "Checking the injury...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then
							state:ModifyStat("Health", -2)
							state:ModifyStat("Happiness", -2)
						end
						if state.AddFeed then state:AddFeed("🩹 Minor injury. Bruises and scrapes. Ice and rest.") end
					elseif roll < 0.70 then
						if state.ModifyStat then
							state:ModifyStat("Health", -5)
							state:ModifyStat("Happiness", -4)
						end
						-- CRITICAL FIX #532: Prevent money going negative
						state.Money = math.max(0, (state.Money or 0) - 100)
						if state.AddFeed then state:AddFeed("🩹 Moderate injury. Sprain or strain. Weeks to heal.") end
					elseif roll < 0.90 then
						if state.ModifyStat then
							state:ModifyStat("Health", -10)
							state:ModifyStat("Happiness", -8)
						end
						-- CRITICAL FIX #533: Prevent money going negative
						state.Money = math.max(0, (state.Money or 0) - 500)
						state.Flags = state.Flags or {}
						state.Flags.serious_injury = true
						if state.AddFeed then state:AddFeed("🩹 Serious injury. Broken bone. Surgery needed. Months of recovery.") end
					else
						if state.ModifyStat then
							state:ModifyStat("Health", -15)
							state:ModifyStat("Happiness", -12)
						end
						-- CRITICAL FIX #534: Prevent money going negative, add medical debt flag
						local medCost = 2000
						if (state.Money or 0) < medCost then
							state.Flags = state.Flags or {}
							state.Flags.medical_debt = true
						end
						state.Money = math.max(0, (state.Money or 0) - medCost)
						state.Flags = state.Flags or {}
						state.Flags.major_injury = true
						if state.AddFeed then state:AddFeed("🩹 Major trauma. Emergency room. Long rehabilitation ahead.") end
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
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "checkup", "doctor", "preventive" },
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Doctor checkups more likely when health is medium or player is older
		-- This helps players manage their health better
		-- ═══════════════════════════════════════════════════════════════════════════════
		getWeight = function(state)
			local health = (state.Stats and state.Stats.Health) or 50
			local age = state.Age or 30
			local weight = 100
			-- Low-medium health: need checkups more
			if health < 50 then
				weight = weight + 40
			elseif health < 70 then
				weight = weight + 20
			end
			-- Older people more likely to visit doctor
			if age > 50 then
				weight = weight + 30
			elseif age > 35 then
				weight = weight + 15
			end
			return weight
		end,
		
		-- CRITICAL: Random checkup results
		choices = {
			{
				text = "Get your results",
				effects = {},
				feedText = "Waiting for test results...",
				-- ═══════════════════════════════════════════════════════════════════════════════
				-- CRITICAL FIX #529: Set went_to_doctor flag so diagnosis events work correctly!
				-- User complaint: "DIAGNOSIS SHOWING UP BUT I DIDNT GO TO DOCTOR"
				-- ═══════════════════════════════════════════════════════════════════════════════
				setFlags = { went_to_doctor = true, doctor_checkup = true, recent_checkup = true },
				onResolve = function(state)
					-- CRITICAL FIX #529: ALSO set flags here for onResolve path
					state.Flags = state.Flags or {}
					state.Flags.went_to_doctor = true
					state.Flags.doctor_checkup = true
					state.Flags.recent_checkup = true
					
					local health = (state.Stats and state.Stats.Health) or 50
					local age = state.Age or 30
					local roll = math.random()
					local goodResultChance = 0.45 + (health / 200) - (age / 250)
					
				-- CRITICAL FIX: Use actual disease/condition names instead of vague "serious diagnosis"
				-- User complained: "IT SAID HEALTH SCARE I BEEN DIAGNOSED WITH SOMETHING BUT IT DIDNT SAY ANYTHING"
				local minorConditions = {
					"slightly elevated blood pressure", "mild vitamin D deficiency", 
					"borderline cholesterol", "minor iron deficiency", "slightly low B12"
				}
				local moderateConditions = {
					"prediabetes", "high cholesterol", "hypertension stage 1",
					"thyroid dysfunction", "sleep apnea", "anemia"
				}
				local seriousConditions = {
					"Type 2 Diabetes", "Hypertension Stage 2", "Heart Arrhythmia",
					"Early Kidney Disease", "Liver Function Issues", "Autoimmune Disorder"
				}
				
				if roll < goodResultChance then
					-- AAA FIX: Nil check for all state methods
					if state.ModifyStat then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Health", 3)
					end
					if state.AddFeed then state:AddFeed("🏥 All clear! Clean bill of health! Relief!") end
				elseif roll < 0.70 then
					local condition = minorConditions[math.random(1, #minorConditions)]
					if state.ModifyStat then state:ModifyStat("Happiness", 2) end
					state:AddFeed(string.format("🏥 Doctor found %s. Watch diet and exercise. Manageable.", condition))
				elseif roll < 0.90 then
					local condition = moderateConditions[math.random(1, #moderateConditions)]
					state:ModifyStat("Happiness", -5)
					state:ModifyStat("Health", -3)
					state.Flags = state.Flags or {}
					state.Flags.health_concerns = true
					state.Flags.current_condition = condition
					state:AddFeed(string.format("🏥 Diagnosed with %s. Need follow-up treatment and lifestyle changes.", condition))
				else
					local condition = seriousConditions[math.random(1, #seriousConditions)]
					state:ModifyStat("Happiness", -10)
					state:ModifyStat("Health", -8)
					state.Flags = state.Flags or {}
					state.Flags.serious_diagnosis = true
					state.Flags.current_condition = condition
					state:AddFeed(string.format("🏥 Diagnosed with %s. Treatment required immediately. Life-changing news.", condition))
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
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "dental", "teeth", "checkup" },
		
	-- CRITICAL: Random dental outcome - checkups are free/covered by insurance!
	choices = {
		{
			text = "Open wide",
			effects = {},  -- FREE - dental checkups covered by insurance/parents
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
		baseChance = 0.55,
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
			text = "Hire personal trainer ($200)",
			effects = { Money = -200 },
			feedText = "Training with pro...",
			eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for trainer" end,
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
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "allergies", "seasonal", "health" },
		
		choices = {
		{
			text = "Take some allergy medicine",
			effects = {},
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
		{ text = "Allergy shots ($100)", effects = { Money = -100, Happiness = 2, Health = 3 }, setFlags = { allergy_treatment = true }, feedText = "🤧 Long-term solution! Building immunity!", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for shots" end },
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
		baseChance = 0.455,
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
		{ text = "Seek professional help ($80)", effects = { Money = -80, Happiness = 6, Health = 3 }, setFlags = { therapy = true }, feedText = "😰 Therapist appointment made. Healing begins.", eligibility = function(state) return (state.Money or 0) >= 80, "💸 Need $80 for therapy" end },
		},
	},
	{
		id = "health_depression_bout",
		title = "Feeling Low",
		emoji = "😔",
		text = "Depression is hitting hard.",
		question = "What do you do?",
		minAge = 12, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
			{ text = "Start therapy/medication ($100)", effects = { Money = -100, Happiness = 4, Health = 4 }, setFlags = { depression_treatment = true }, feedText = "😔 Getting help. It's okay to not be okay.",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Can't afford treatment ($100 needed)" end,
			},
		},
	},
	{
		id = "health_stress_overload",
		title = "Stress Overload",
		emoji = "🤯",
		text = "Stress is piling up beyond manageable levels!",
		question = "How do you handle burnout?",
		minAge = 16, maxAge = 80,
		baseChance = 0.55,
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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "mental_health",
		tags = { "therapy", "healing", "growth" },
		requiresFlags = { therapy = true },
		
		-- CRITICAL: Random therapy progress
		choices = {
			{
				text = "Have a breakthrough session ($80)",
				effects = { Money = -80 },
				feedText = "Processing in therapy...",
				eligibility = function(state) return (state.Money or 0) >= 80, "💸 Can't afford this session ($80 needed)" end,
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
			{ text = "Skip this week - can't afford it", effects = { Happiness = -2 }, feedText = "🛋️ Missed a session. Financial stress affecting mental health." },
			{ text = "Try self-help techniques instead", effects = { Happiness = 3, Smarts = 1 }, feedText = "🛋️ Journaling, deep breathing, applying what you've learned." },
		},
	},
	{
		id = "health_meditation_practice",
		title = "Meditation Practice",
		emoji = "🧘",
		text = "Trying to build a meditation habit.",
		question = "How is your practice going?",
		minAge = 10, maxAge = 100,
		baseChance = 0.455,
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
			{ text = "Use a free meditation app", effects = { Happiness = 4, Health = 3 }, feedText = "🧘 App helps! Structure and guidance working! Free apps are great!" },
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
		baseChance = 0.55,
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
		{ text = "Try some sleep aids", effects = { Health = -1 }, feedText = "😴 Meds knock you out but groggy mornings.",
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
		{ text = "See sleep specialist ($150)", effects = { Money = -150, Health = 5, Happiness = 4 }, feedText = "😴 Sleep study revealed issues. Treatment helping!", eligibility = function(state) return (state.Money or 0) >= 150, "💸 Need $150 for specialist" end },
		},
	},
	{
		id = "health_vivid_dreams",
		title = "Vivid Dreams",
		emoji = "💭",
		text = "Your dreams have been intense lately!",
		question = "What kind of dreams?",
		minAge = 8, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "wellness",
		tags = { "nutrition", "diet", "health" },
		
		choices = {
		{
			text = "Clean up your diet",
			effects = {},
			feedText = "Eating healthier...",
			onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.healthy_eater = true
						state:AddFeed("🥗 Feeling so much better! Energy up! Eating cleaner!")
					else
						state:ModifyStat("Health", 2)
						state:ModifyStat("Happiness", 1)
						state:AddFeed("🥗 Some improvement. Cravings are tough but trying!")
					end
				end,
			},
			{ text = "Go vegetarian/vegan", effects = { Health = 3, Happiness = 4 }, setFlags = { vegetarian = true }, feedText = "🥗 Plant-based life! Feel lighter and cleaner!" },
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
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "wellness",
		tags = { "water", "hydration", "health" },
		
		choices = {
		{ text = "Start drinking more water", effects = { Health = 3, Happiness = 2 }, setFlags = { hydrated = true }, feedText = "💧 8 glasses a day! Skin better! More energy!" },
		{ text = "Living on coffee/soda", effects = { Health = -2, Happiness = 1 }, feedText = "💧 Caffeine is technically water, right? Wrong." },
		{ text = "Commit to staying hydrated", effects = { Health = 3, Happiness = 3 }, setFlags = { hydrated = true }, feedText = "💧 Got a reusable bottle and tracking intake! Hydration hero!" },
		},
	},
	{
		id = "health_screen_time",
		title = "Screen Time Awareness",
		emoji = "📱",
		text = "Your screen time has been excessive!",
		question = "What do you do about it?",
		minAge = 8, maxAge = 70,
		baseChance = 0.55,
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
		id = "health_lifestyle_choice",
		title = "Lifestyle Choices",
		emoji = "🍵",
		text = "Thinking about your lifestyle and health habits.",
		question = "What's your approach to healthy living?",
		minAge = 18, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "wellness",
		tags = { "health", "lifestyle", "choices" },
		
		choices = {
		{ text = "Balanced approach", effects = { Happiness = 3, Health = 2 }, feedText = "🍵 Taking a balanced approach to life. Everything in moderation!" },
		{ text = "Focus on healthy living", effects = { Happiness = 4, Health = 6, Money = 50 }, setFlags = { health_conscious = true }, feedText = "🥗 Making healthier choices. Feeling great!" },
		{ text = "Commit to regular exercise", effects = { Happiness = 6, Health = 8 }, setFlags = { fitness_focused = true }, feedText = "💪 All in on fitness! Running, pushups, staying active! Best shape ever!" },
		{ text = "Ignore health for now", effects = { Happiness = 2, Health = -5 }, setFlags = { unhealthy_habits = true }, feedText = "🍔 Not prioritizing health. May regret this later." },
		},
	},
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #231-250: DISEASE DIAGNOSIS CARDS
	-- These events show exactly what illness the player has when diagnosed
	-- ══════════════════════════════════════════════════════════════════════════════
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Diagnosis cards now require feeling sick first!
	-- User complaint: "RANDOM DIAGNOSIS POPPING UP BUT I DIDNT GO TO DOCTOR"
	-- Changed text to make it clear you GOT sick (not that doctor diagnosed you)
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "health_diagnosis_cold_flu",
		-- CRITICAL FIX: Changed title to not look like a "diagnosis" - it's just getting sick
		title = "🤒 Under the Weather",
		emoji = "🤒",
		text = "You've come down with a cold or flu! You woke up feeling terrible - stuffy nose, sore throat, and body aches.",
		question = "Looks like a cold or flu virus. What do you want to do?",
		minAge = 3, maxAge = 100,
		baseChance = 0.25, -- CRITICAL FIX: Reduced from 0.35 to reduce spam
		cooldown = 5, -- CRITICAL FIX: Increased from 4 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "illness", "cold", "flu", "sick" },
		-- CRITICAL FIX: Removed isDiagnosisCard - this is just a common illness, not a diagnosis
		-- isDiagnosisCard = true,
		-- diagnosisType = "cold_flu",
		
		choices = {
		{ text = "Rest at home", effects = { Health = 3, Happiness = -2 }, setFlags = { has_cold = true }, feedText = "🤒 Resting at home. Should recover in a week." },
		{ text = "Take some medicine", effects = { Health = 5, Happiness = 1 }, feedText = "🤒 Got some medicine and resting up. Should feel better soon!" },
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
		baseChance = 0.25,
		cooldown = 40, -- Only diagnose once
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "diabetes", "chronic" },
		isDiagnosisCard = true,
		diagnosisType = "diabetes",
		oneTime = true,
		maxOccurrences = 1,
		-- CRITICAL FIX: Only show if player visited doctor or has symptoms
		eligibility = function(state)
			local health = (state.Stats and state.Stats.Health) or 50
			local flags = state.Flags or {}
			-- Already have diabetes? Don't show again
			if flags.diabetes then return false end
			-- CRITICAL FIX: Must have visited doctor OR have symptoms
			local visitedDoctor = flags.went_to_doctor or flags.doctor_checkup or flags.recent_checkup
			local hasSymptoms = flags.feeling_sick or flags.frequent_urination or flags.excessive_thirst
				or flags.unexplained_weight_loss or flags.fatigue or health < 40
			-- Only show if visited doctor with low health OR has specific symptoms
			if not visitedDoctor and not hasSymptoms then
				return false
			end
			return health < 60
		end,
		
		choices = {
			{
				text = "Accept treatment plan",
				effects = { Happiness = -5, Health = -10 },
				setFlags = { diabetes = true, chronic_illness = true, on_medication = true },
				feedText = "💉 Diabetes diagnosis. Started insulin and lifestyle changes.",
			},
			{
				text = "Get second opinion ($200)",
				effects = { Money = -200, Happiness = -3 },
				feedText = "💉 Second doctor confirmed. You have diabetes.",
				eligibility = function(state) return (state.Money or 0) >= 200, "💸 Can't afford second opinion ($200 needed)" end,
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
		baseChance = 0.22,
		cooldown = 40,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "heart", "serious" },
		isDiagnosisCard = true,
		diagnosisType = "heart_disease",
		oneTime = true,
		maxOccurrences = 1,
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #530: Heart disease diagnosis REQUIRES doctor visit!
		-- User complaint: "DIAGNOSIS SHOWING UP BUT I DIDNT GO TO DOCTOR"
		-- Must have: went_to_doctor OR doctor_checkup OR recent_checkup flag
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local health = (state.Stats and state.Stats.Health) or 50
			local age = state.Age or 30
			local flags = state.Flags or {}
			-- Already have heart disease? Don't show again
			if flags.heart_disease then return false end
			-- CRITICAL FIX: Must have visited doctor OR have severe symptoms
			local visitedDoctor = flags.went_to_doctor or flags.doctor_checkup or flags.recent_checkup
			local hasSymptoms = flags.chest_pain or flags.shortness_of_breath or flags.heart_palpitations 
				or flags.feeling_faint or flags.hospitalized or health < 30
			if not visitedDoctor and not hasSymptoms then
				return false
			end
			return (age > 45 and health < 55)
		end,
		
		choices = {
			{
				text = "Start treatment immediately ($500)",
				effects = { Happiness = -10, Money = -500, Health = -15 },
				setFlags = { heart_disease = true, chronic_illness = true, on_heart_medication = true },
				feedText = "❤️‍🩹 Heart disease diagnosed. On medication and strict diet now.",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Can't afford treatment ($500 needed)" end,
			},
			{
				text = "Get bypass surgery if needed ($5,000)",
				effects = { Happiness = -15, Money = -5000, Health = 5 },
				setFlags = { heart_disease = true, had_heart_surgery = true },
				feedText = "❤️‍🩹 Underwent heart surgery. Long recovery ahead.",
				eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Can't afford surgery ($5,000 needed)" end,
			},
			{ text = "Try lifestyle changes only (free but risky)", effects = { Happiness = -5, Health = -20 }, setFlags = { heart_disease = true, untreated_heart_condition = true }, feedText = "❤️‍🩹 No treatment. Trying diet and exercise only. Very risky choice." },
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Cure heart disease",
				effects = { Happiness = 25, Health = 30 },
				setFlags = { heart_disease_cured = true },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ GOD MODE ACTIVATED! Your heart is now perfectly healthy! Miracle!",
			},
		},
	},
	{
		id = "health_diagnosis_cancer",
		title = "🎗️ Diagnosis: Cancer",
		emoji = "🎗️",
		text = "The biopsy results have come back. The news is serious.",
		question = "Your diagnosis: CANCER DETECTED\n\n🔬 Finding: Malignant cells detected\n⚠️ Severity: CRITICAL\n🏥 Treatment: Chemotherapy/Radiation/Surgery\n⏰ Early detection increases survival rate\n\nThis is a life-changing diagnosis.",
		minAge = 30, maxAge = 100, -- CRITICAL FIX: Cancer rare under 30
		baseChance = 0.10, -- CRITICAL FIX: Reduced from 0.18 - cancer is rare
		cooldown = 50, -- CRITICAL FIX: Increased - cancer shouldn't pop up often
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "cancer", "critical" },
		isDiagnosisCard = true,
		diagnosisType = "cancer",
		oneTime = true,
		maxOccurrences = 1,
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #531: Cancer diagnosis REQUIRES doctor visit or screening!
		-- User complaint: "DIAGNOSIS SHOWING UP BUT I DIDNT GO TO DOCTOR"
		-- This is a MAJOR diagnosis - should NEVER pop up randomly!
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Already have cancer or survived? Don't show again
			if flags.has_cancer or flags.cancer_survivor then return false end
			-- CRITICAL FIX: Must have visited doctor OR had screening
			local visitedDoctor = flags.went_to_doctor or flags.doctor_checkup or flags.recent_checkup
			local hadScreening = flags.cancer_screening or flags.biopsy or flags.mammogram 
				or flags.colonoscopy or flags.blood_work
			local hasSevereSymptoms = flags.unexplained_weight_loss or flags.persistent_cough 
				or flags.found_lump or flags.unusual_bleeding or flags.severe_fatigue
			if not visitedDoctor and not hadScreening and not hasSevereSymptoms then
				return false
			end
			return true
		end,
		
		choices = {
			{
				text = "Fight it - start treatment ($10,000)",
				effects = { Happiness = -20, Money = -10000, Health = -25 },
				setFlags = { has_cancer = true, cancer = true, in_treatment = true, fighting_cancer = true },
				feedText = "🎗️ Cancer diagnosis. Starting chemotherapy. Fight of your life.",
				eligibility = function(state) return (state.Money or 0) >= 10000, "💸 Can't afford cancer treatment ($10,000 needed). Try alternative options or seek financial help." end,
				onResolve = function(state)
					-- CRITICAL FIX: Treatment doesn't immediately resolve - it takes time
					-- First treatment has 40% chance to show improvement
					-- Patient can try again at doctor later
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.40 then
						-- Treatment showing early promise
						state.Flags.treatment_responding = true
						state.Flags.cancer_treatment_rounds = 1
						state:AddFeed("🎗️ First round of chemo complete. Early signs are promising!")
					elseif roll < 0.70 then
						-- Treatment uncertain - need more rounds
						state.Flags.treatment_uncertain = true
						state.Flags.cancer_treatment_rounds = 1
						state:AddFeed("🎗️ First round complete. Results inconclusive. More treatment needed.")
					else
						-- Treatment not working well
						state.Flags.treatment_struggling = true
						state.Flags.cancer_treatment_rounds = 1
						state:AddFeed("🎗️ Treatment is hard on your body. Doctors are concerned. Don't give up!")
					end
				end,
			},
			{
				text = "Get second opinion first ($500)",
				effects = { Happiness = -5, Money = -500 },
				feedText = "🎗️ Seeking another doctor's perspective...",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Can't afford second opinion ($500 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.has_cancer = true
					state.Flags.cancer = true
					if roll < 0.15 then
						-- Misdiagnosis (rare)
						state.Flags.cancer_misdiagnosis = true
						state:ModifyStat("Happiness", 20)
						state:AddFeed("🎗️ INCREDIBLE NEWS! Second opinion says it's NOT cancer! Just a benign growth!")
					elseif roll < 0.50 then
						-- Earlier stage than thought
						state.Flags.early_stage_cancer = true
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎗️ Second doctor says it was caught earlier than thought. Better prognosis!")
					else
						-- Diagnosis confirmed
						state.Flags.confirmed_cancer = true
						state:AddFeed("🎗️ Second doctor confirmed the diagnosis. Time to start treatment.")
					end
				end,
			},
			{
				text = "Refuse treatment (accept fate)",
				effects = { Happiness = -30, Health = -40 },
				setFlags = { has_cancer = true, terminal_illness = true, refusing_treatment = true },
				feedText = "🎗️ Choosing to live remaining time without treatment.",
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Cure it instantly",
				effects = { Happiness = 30, Health = 20 },
				setFlags = { cancer_survivor = true, miraculous_recovery = true },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ GOD MODE ACTIVATED! The cancer has completely vanished! Miraculous recovery!",
			},
		},
	},
	-- CRITICAL FIX: Cancer follow-up treatment events - allow retry at doctor
	{
		id = "health_cancer_treatment_followup",
		title = "🎗️ Cancer Treatment Update",
		emoji = "🎗️",
		text = "Time for your cancer treatment check-up. The doctors have the latest results.",
		question = "How is your treatment going?",
		minAge = 20, maxAge = 100,
		baseChance = 0.70,
		cooldown = 1,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "cancer", "treatment", "followup" },
		-- Only show for people actively fighting cancer
		eligibility = function(state)
			local flags = state.Flags or {}
			return flags.has_cancer and flags.in_treatment and not flags.cancer_survivor and not flags.terminal_illness
		end,
		
		choices = {
			{
				text = "Continue aggressive treatment ($5,000)",
				effects = { Money = -5000, Health = -10, Happiness = -5 },
				feedText = "🎗️ Pushing through more treatment...",
				-- BUG FIX #3: Add eligibility check for treatment cost
				eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Can't afford treatment ($5,000 needed)" end,
				onResolve = function(state)
					state.Flags = state.Flags or {}
					local rounds = (state.Flags.cancer_treatment_rounds or 1) + 1
					state.Flags.cancer_treatment_rounds = rounds
					
					-- Each round has a chance to beat it, improved by previous rounds
					local baseChance = 0.25 + (rounds * 0.10) -- More rounds = better odds
					local roll = math.random()
					
					if roll < baseChance then
						-- REMISSION!
						state.Flags.cancer_survivor = true
						state.Flags.in_remission = true
						state.Flags.in_treatment = nil
						state.Flags.treatment_responding = nil
						state.Flags.treatment_uncertain = nil
						state.Flags.treatment_struggling = nil
						state:ModifyStat("Happiness", 30)
						state:ModifyStat("Health", 10)
						state:AddFeed("🎗️ REMISSION! After " .. rounds .. " rounds of treatment, you beat cancer! 🎉")
					elseif roll < baseChance + 0.30 then
						-- Improving
						state.Flags.treatment_responding = true
						state.Flags.treatment_uncertain = nil
						state.Flags.treatment_struggling = nil
						state:AddFeed("🎗️ Good news! Treatment round " .. rounds .. " is working. Keep fighting!")
					elseif roll < baseChance + 0.55 then
						-- Stable
						state.Flags.treatment_uncertain = true
						state:AddFeed("🎗️ Holding steady after round " .. rounds .. ". Not worse, not better yet.")
					else
						-- Getting worse
						state.Flags.treatment_struggling = true
						state:ModifyStat("Health", -5)
						if rounds >= 5 and math.random() < 0.30 then
							-- After many rounds, might become terminal
							state.Flags.terminal_illness = true
							state.Flags.in_treatment = nil
							state:AddFeed("🎗️ After " .. rounds .. " rounds... doctors say treatment isn't working. 💔")
						else
							state:AddFeed("🎗️ Round " .. rounds .. " was tough. Cancer is stubborn. Don't give up!")
						end
					end
				end,
			},
			{
				text = "Try alternative treatments ($3,000)",
				effects = { Money = -3000, Happiness = 2 },
				feedText = "🎗️ Exploring other options...",
				-- BUG FIX #4: Add eligibility check for treatment cost
				eligibility = function(state) return (state.Money or 0) >= 3000, "💸 Can't afford alternative treatment ($3,000 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					
					if roll < 0.20 then
						-- Alternative worked! (rare)
						state.Flags.cancer_survivor = true
						state.Flags.in_remission = true
						state.Flags.in_treatment = nil
						state:ModifyStat("Happiness", 25)
						state:AddFeed("🎗️ The alternative approach worked! You're in remission! 🌟")
					elseif roll < 0.50 then
						-- Helped a bit
						state.Flags.treatment_responding = true
						state:AddFeed("🎗️ Alternative therapies giving you strength. Combining with regular treatment.")
					else
						-- Didn't help
						state:AddFeed("🎗️ Alternative treatment didn't show results. Back to traditional methods.")
					end
				end,
			},
			{
				text = "Take a break from treatment",
				effects = { Happiness = 5, Health = -5 },
				feedText = "🎗️ Your body needs rest...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.treatment_paused = true
					state:AddFeed("🎗️ Taking a break to recover strength. Will resume treatment later.")
				end,
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
		baseChance = 0.32,
		cooldown = 40,
		stage = STAGE,
		ageBand = "any",
		category = "mental_health",
		tags = { "diagnosis", "depression", "mental_health" },
		isDiagnosisCard = true,
		diagnosisType = "depression",
		oneTime = true,
		maxOccurrences = 1,
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #532: Depression diagnosis requires VERY low happiness or doctor visit
		-- Changed the text to say "After evaluation" so it makes sense narratively
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local happiness = (state.Stats and state.Stats.Happiness) or 50
			local flags = state.Flags or {}
			-- Already have depression? Don't show again
			if flags.depression then return false end
			-- Need either: doctor visit OR VERY severe symptoms (happiness below 25)
			local visitedDoctor = flags.went_to_doctor or flags.doctor_checkup or flags.recent_checkup
			local visitedTherapist = flags.therapy_session or flags.saw_therapist or flags.mental_health_eval
			local severeSymptoms = happiness < 25 or flags.suicidal_thoughts or flags.cant_get_out_of_bed
			if not visitedDoctor and not visitedTherapist and not severeSymptoms then
				return false
			end
			return happiness < 35
		end,
		
		choices = {
			{
				-- CRITICAL FIX: Show price and add eligibility!
				text = "Start therapy and medication ($100)",
				effects = { Money = -100, Happiness = 5, Health = 3 },
				setFlags = { depression = true, mental_illness = true, depression_treatment = true, therapy = true },
				feedText = "😔 Depression diagnosed. Starting treatment. It gets better.",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for treatment" end,
			},
			{
				-- CRITICAL FIX: Show price and add eligibility!
				text = "Try therapy only ($80)",
				effects = { Money = -80, Happiness = 3 },
				setFlags = { depression = true, mental_illness = true, therapy = true },
				feedText = "😔 Starting therapy for depression. Taking the first step.",
				eligibility = function(state) return (state.Money or 0) >= 80, "💸 Need $80 for therapy" end,
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
		baseChance = 0.3,
		cooldown = 40,
		stage = STAGE,
		ageBand = "any",
		category = "mental_health",
		tags = { "diagnosis", "anxiety", "mental_health" },
		isDiagnosisCard = true,
		diagnosisType = "anxiety",
		oneTime = true,
		maxOccurrences = 1,
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #533: Anxiety diagnosis requires doctor/therapist or severe symptoms
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Already have anxiety? Don't show again
			if flags.anxiety then return false end
			-- Need either: doctor/therapist visit OR explicit panic attacks
			local visitedDoctor = flags.went_to_doctor or flags.doctor_checkup or flags.recent_checkup
			local visitedTherapist = flags.therapy_session or flags.saw_therapist or flags.mental_health_eval
			local hasSymptoms = flags.panic_attacks or flags.severe_anxiety or flags.anxiety_attack
			if not visitedDoctor and not visitedTherapist and not hasSymptoms then
				return false
			end
			return flags.stressed or flags.panic_attacks or flags.nervous
		end,
		
		choices = {
			{
				text = "Start treatment ($100)",
				effects = { Money = -100, Happiness = 5 },
				setFlags = { anxiety = true, mental_illness = true, anxiety_treatment = true },
				feedText = "😰 Anxiety diagnosed. Starting therapy and learning coping strategies.",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Can't afford treatment ($100 needed)" end,
			},
			{
				text = "Try medication ($50)",
				effects = { Money = -50, Happiness = 3, Health = 1 },
				setFlags = { anxiety = true, on_anxiety_meds = true },
				feedText = "😰 Anti-anxiety medication prescribed. Taking the edge off.",
				eligibility = function(state) return (state.Money or 0) >= 50, "💸 Can't afford medication ($50 needed)" end,
			},
			{ text = "Try to manage it without treatment", effects = { Happiness = -5 }, setFlags = { anxiety = true, untreated_anxiety = true }, feedText = "😰 Trying to cope on your own. Breathing exercises, research, self-help." },
		},
	},
	-- REMOVED: STI and HIV events (inappropriate for Roblox)
	-- Replaced with more appropriate health conditions
	{
		id = "health_diagnosis_infection",
		title = "🦠 Diagnosis: Bacterial Infection",
		emoji = "🦠",
		text = "Your test results show you have a bacterial infection.",
		question = "Your diagnosis: BACTERIAL INFECTION\n\n🔬 Status: Positive\n⚠️ Type: Bacterial infection detected\n💊 Treatment: Antibiotics available\n🩺 Follow-up: Required\n\nRest and take your medicine!",
		minAge = 5, maxAge = 90,
		baseChance = 0.30,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "infection" },
		isDiagnosisCard = true,
		diagnosisType = "infection",
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #534: Infection diagnosis requires being sick or doctor visit
		-- User complaint: "DIAGNOSIS SHOWING UP BUT I DIDNT GO TO DOCTOR"
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local flags = state.Flags or {}
			local health = (state.Stats and state.Stats.Health) or 50
			-- Currently recovering? Don't show again
			if flags.recovering_from_infection then return false end
			-- Must have: visited doctor, OR been sick, OR have low health
			local visitedDoctor = flags.went_to_doctor or flags.doctor_checkup or flags.recent_checkup
			local beenSick = flags.feeling_sick or flags.has_cold or flags.prolonged_illness or flags.fever
			local lowHealth = health < 40
			return visitedDoctor or beenSick or lowHealth
		end,
		
		choices = {
			{
				text = "Take antibiotics as prescribed ($100)",
				effects = { Money = -100, Happiness = -5, Health = 10 },
				setFlags = { recovering_from_infection = true },
				feedText = "🦠 Infection treated with antibiotics. Feeling better!",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Can't afford antibiotics ($100 needed)" end,
			},
			{
				text = "Try to tough it out (free but risky)",
				effects = { Health = -10, Happiness = -8 },
				setFlags = { untreated_infection = true },
				feedText = "🦠 The infection lingered. Should have taken the medicine.",
			},
		},
	},
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Chronic fatigue requires low health + stress
	-- User complaint: "CHRONIC FATIGUE KEEPS POPPING UP AT AGE 32"
	-- Added eligibility to only trigger when player has low health/high stress
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "health_diagnosis_chronic_fatigue",
		title = "😴 Chronic Fatigue",
		emoji = "😴",
		text = "You've been feeling exhausted for months. No matter how much you sleep, you wake up tired. After seeing a doctor, they've diagnosed you with chronic fatigue syndrome.",
		question = "Chronic Fatigue Syndrome\n\nYou've been running on empty for too long. This is your body telling you to slow down. What will you do?",
		minAge = 22, maxAge = 65,
		baseChance = 0.12, -- Reduced chance
		cooldown = 40, -- Very long cooldown
		stage = STAGE,
		ageBand = "adult",
		category = "health",
		tags = { "chronic", "fatigue", "exhaustion" },
		isDiagnosisCard = true,
		diagnosisType = "chronic_fatigue",
		oneTime = true,
		maxOccurrences = 1,
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #535: Chronic fatigue requires doctor visit + symptoms
		-- User complaint: "CHRONIC FATIGUE KEEPS POPPING UP AT AGE 32 WITHOUT DOCTOR"
		-- The text says "After seeing a doctor" so must have actually seen a doctor!
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local health = (state.Stats and state.Stats.Health) or 50
			local happiness = (state.Stats and state.Stats.Happiness) or 50
			local flags = state.Flags or {}
			-- Already has it? Don't trigger again
			if flags.chronic_fatigue then return false end
			-- CRITICAL FIX: Must have visited doctor (the text says "After seeing a doctor")
			local visitedDoctor = flags.went_to_doctor or flags.doctor_checkup or flags.recent_checkup
			if not visitedDoctor then return false end
			-- AND must have low health OR low happiness (stress indicator)
			return health < 45 or happiness < 35
		end,
		
		choices = {
			{
				text = "Follow treatment plan",
				effects = { Happiness = -10, Health = -5 },
				setFlags = { chronic_fatigue = true, managing_condition = true },
				feedText = "😴 Learning to manage chronic fatigue. Taking it one day at a time.",
			},
			{
				text = "Join a support group",
				effects = { Happiness = -5, Health = -3 },
				setFlags = { chronic_fatigue = true, has_support = true },
				feedText = "😴 Finding others who understand. It helps to not be alone.",
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
		baseChance = 0.32,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "diagnosis", "injury", "bone" },
		isDiagnosisCard = true,
		diagnosisType = "broken_bone",
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Broken bone should ONLY appear if player had an accident/injury!
		-- User complaint: "DIAGNOSIS BROKEN BONE POPPED UP RANDOMLY BRO I DIDNT GET IN A FIGHT"
		-- Must require: car accident, fight, fall, sports injury, or similar event
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Check if player had any event that could cause a broken bone
			local hadInjuryEvent = flags.car_accident or flags.car_crash or flags.was_in_accident
				or flags.got_in_fight or flags.fight or flags.lost_fight or flags.attacked
				or flags.fell or flags.slipped or flags.tripped or flags.fell_down
				or flags.sports_injury or flags.injured_playing or flags.workout_injury
				or flags.serious_injury or flags.injured or flags.hurt
				or flags.bike_accident or flags.skateboard_accident
				or flags.hospitalized or flags.emergency_room
				or flags.physical_altercation or flags.assault_victim
			-- Also check if went to doctor after feeling pain
			local wentToDoctor = flags.went_to_doctor or flags.doctor_checkup
			local hasPain = flags.severe_pain or flags.limping or flags.cant_walk
			
			if not hadInjuryEvent and not (wentToDoctor and hasPain) then
				return false
			end
			return true
		end,
		
		choices = {
			{
				text = "Get it set and wear the cast ($500)",
				effects = { Money = -500, Health = -5, Happiness = -5 },
				setFlags = { broken_bone = true, in_cast = true },
				feedText = "🦴 Bone set, cast on. 6 weeks of limited mobility.",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Can't afford hospital visit ($500 needed)" end,
			},
			{
				text = "Surgery if needed ($3,000)",
				effects = { Money = -3000, Health = 5, Happiness = -8 },
				setFlags = { had_bone_surgery = true },
				feedText = "🦴 Needed surgery to fix properly. Pins and plates inserted.",
				eligibility = function(state) return (state.Money or 0) >= 3000, "💸 Can't afford surgery ($3,000 needed)" end,
			},
			{ text = "Try to heal it yourself (risky - free)", effects = { Health = -15, Happiness = -10 }, setFlags = { broken_bone = true, untreated_injury = true }, feedText = "🦴 No doctor. Hoping it heals right. Risky move." },
		},
	},
	{
		id = "health_checkup_results_detailed",
		title = "📋 Detailed Health Report",
		emoji = "📋",
		text = "Your comprehensive health checkup results are ready!",
		question = "Your Health Report Card:",
		minAge = 18, maxAge = 100,
		baseChance = 0.4,
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
				effects = { Happiness = 3, Smarts = 2 },
				feedText = "📋 Discussed results. Now have a clear health plan.",
			},
			{
				text = "Schedule follow-up tests ($100)",
				effects = { Money = -100, Health = 2 },
				feedText = "📋 Booked additional tests for thorough assessment.",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for additional tests" end,
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- CHRONIC CONDITION TREATMENT EVENTS
-- CRITICAL FIX: User requested "ENSURE IT LINKS TO BACKEND AND CAN HEAL IT OR NOT"
-- "CAN GO TO DOCTOR AND TRY GET IT TAKEN AWAY LIKE BITLIFE DOES"
-- These events allow players to attempt treatment for diagnosed conditions
-- ═══════════════════════════════════════════════════════════════════════════════

HealthEvents.events[#HealthEvents.events + 1] = {
	id = "health_treatment_checkup",
	title = "Treatment Follow-Up",
	emoji = "🏥",
	text = "Time for your regular checkup to monitor your condition.",
	question = "The doctor reviews your treatment progress...",
	minAge = 18, maxAge = 100,
	baseChance = 0.55,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
	stage = STAGE,
	ageBand = "any",
	category = "health",
	tags = { "treatment", "doctor", "chronic" },
	
	-- Only trigger for people with chronic conditions
	eligibility = function(state)
		local flags = state.Flags or {}
		return flags.chronic_illness or flags.diabetes or flags.heart_disease 
			or flags.chronic_condition or flags.hypertension or flags.high_cholesterol
	end,
	
	choices = {
		{
			text = "Regular checkup",
			effects = { Happiness = 2 },
			feedText = "Checking in with the doctor...",
			onResolve = function(state)
				local roll = math.random(1, 100)
				local health = (state.Stats and state.Stats.Health) or 50
				
				if roll <= 25 then
					-- CONDITION IMPROVED!
					state.Stats = state.Stats or {}
					state.Stats.Health = math.min(100, health + 5)
					state.Flags = state.Flags or {}
					state.Flags.condition_improving = true
					if state.AddFeed then
						state:AddFeed("🏥 Good news! Your condition seems stable. Keep taking care of yourself!")
					end
				elseif roll <= 70 then
					-- Stable
					if state.AddFeed then
						state:AddFeed("🏥 Condition stable. Doctor says to keep doing what you're doing.")
					end
				else
					-- Need to adjust
					if state.AddFeed then
						state:AddFeed("🏥 Doctor recommends some lifestyle changes to help manage your condition.")
					end
				end
			end,
		},
		{
			text = "Follow treatment plan strictly ($200)",
			effects = { Money = -200, Happiness = 3 },
			feedText = "Following doctor's orders...",
			eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for prescriptions" end,
			onResolve = function(state)
				local roll = math.random(1, 100)
				local health = (state.Stats and state.Stats.Health) or 50
				
				if roll <= 30 then
					-- CONDITION IMPROVED!
					state.Stats = state.Stats or {}
					state.Stats.Health = math.min(100, health + 10)
					state.Flags = state.Flags or {}
					state.Flags.condition_improving = true
					if state.AddFeed then
						state:AddFeed("🏥 Great news! Your condition is improving! Keep up the good work!")
					end
				elseif roll <= 70 then
					-- Stable
					state.Stats = state.Stats or {}
					state.Stats.Health = math.min(100, health + 3)
					if state.AddFeed then
						state:AddFeed("🏥 Condition stable. Treatment is working as expected.")
					end
				else
					-- Not improving
					if state.AddFeed then
						state:AddFeed("🏥 No improvement yet. Doctor adjusting treatment plan.")
					end
				end
			end,
		},
		{
			text = "See a specialist for new options ($200)",
			effects = { Money = -200, Smarts = 3 },
			feedText = "Exploring options...",
			eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for specialist visit" end,
			onResolve = function(state)
				local roll = math.random(1, 100)
				
				if roll <= 25 then
					-- NEW TREATMENT WORKS - CONDITION REMISSION!
					state.Stats = state.Stats or {}
					state.Stats.Health = math.min(100, (state.Stats.Health or 50) + 20)
					state.Flags = state.Flags or {}
					state.Flags.condition_in_remission = true
					-- Chance to clear the chronic flag
					if math.random() < 0.3 then
						state.Flags.chronic_illness = nil
						state.Flags.chronic_condition = nil
						if state.AddFeed then
							state:AddFeed("🎉 AMAZING NEWS! New treatment put your condition into remission! You're essentially cured!")
						end
					else
						if state.AddFeed then
							state:AddFeed("🏥 New treatment is working much better! Condition well-managed now.")
						end
					end
				elseif roll <= 60 then
					-- Some improvement
					state.Stats = state.Stats or {}
					state.Stats.Health = math.min(100, (state.Stats.Health or 50) + 5)
					if state.AddFeed then
						state:AddFeed("🏥 New medication helping a bit. Slow progress but hopeful.")
					end
				else
					-- Expensive but didn't help
					if state.AddFeed then
						state:AddFeed("🏥 Expensive consultations, no new options. Stick with current treatment.")
					end
				end
			end,
		},
		{
			text = "Try alternative medicine ($300)",
			effects = { Money = -300, Happiness = 2 },
			feedText = "Exploring alternatives...",
			eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 for alternative treatments" end,
			onResolve = function(state)
				local roll = math.random(1, 100)
				if roll <= 15 then
					-- Actually worked (rare)
					state.Stats = state.Stats or {}
					state.Stats.Health = math.min(100, (state.Stats.Health or 50) + 8)
					if state.AddFeed then
						state:AddFeed("🌿 Surprisingly, the alternative approach helped! You feel better!")
					end
				elseif roll <= 50 then
					-- Placebo effect
					state.Stats = state.Stats or {}
					state.Stats.Happiness = math.min(100, (state.Stats.Happiness or 50) + 5)
					if state.AddFeed then
						state:AddFeed("🌿 Hard to say if it worked, but you feel more positive.")
					end
				else
					-- Wasted money
					if state.AddFeed then
						state:AddFeed("🌿 No effect. Doctor says stick with proven medicine.")
					end
				end
			end,
		},
		{
			text = "Skip this checkup",
			effects = { Happiness = 3, Health = -5 },
			feedText = "Avoiding the doctor...",
			onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.skipped_treatment = true
				if state.AddFeed then
					state:AddFeed("🏥 Skipping checkups is risky. Condition could worsen unnoticed.")
				end
			end,
		},
	},
}

HealthEvents.events[#HealthEvents.events + 1] = {
	id = "health_diabetes_management",
	title = "Diabetes Check",
	emoji = "💉",
	text = "Your blood sugar levels need monitoring. Time for a diabetes checkup.",
	question = "How are you managing your diabetes?",
	minAge = 18, maxAge = 100,
	baseChance = 0.50,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
	stage = STAGE,
	ageBand = "any",
	category = "health",
	tags = { "diabetes", "chronic", "treatment" },
	
	eligibility = function(state)
		local flags = state.Flags or {}
		return flags.diabetes == true
	end,
	
	choices = {
		{
			-- CRITICAL FIX: Show price and add eligibility!
			text = "Strict diet + insulin treatment ($100)",
			effects = { Money = -100, Health = 5, Happiness = -2 },
			feedText = "Managing carefully...",
			eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for insulin" end,
			onResolve = function(state)
				local roll = math.random(1, 100)
				if roll <= 40 then
					-- Really good control
					state.Flags = state.Flags or {}
					state.Flags.diabetes_controlled = true
					if state.AddFeed then
						state:AddFeed("💉 A1C levels are excellent! Diabetes well-controlled.")
					end
				else
					if state.AddFeed then
						state:AddFeed("💉 Blood sugar levels acceptable. Keep up the routine.")
					end
				end
			end,
		},
		{
			-- CRITICAL FIX: Show price and add eligibility!
			text = "Try new medication ($300)",
			effects = { Money = -300 },
			feedText = "Trying new approach...",
			eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 for new medication" end,
			onResolve = function(state)
				local roll = math.random(1, 100)
				if roll <= 20 then
					-- REMISSION possible with Type 2
					state.Stats = state.Stats or {}
					state.Stats.Health = math.min(100, (state.Stats.Health or 50) + 15)
					state.Flags = state.Flags or {}
					state.Flags.diabetes_remission = true
					if state.AddFeed then
						state:AddFeed("💉 NEW MEDS WORKING! Blood sugar nearly normal. Could be remission!")
					end
				elseif roll <= 60 then
					state.Stats = state.Stats or {}
					state.Stats.Health = math.min(100, (state.Stats.Health or 50) + 5)
					if state.AddFeed then
						state:AddFeed("💉 New medication helping. Fewer spikes in blood sugar.")
					end
				else
					if state.AddFeed then
						state:AddFeed("💉 Side effects from new meds. Going back to old prescription.")
					end
				end
			end,
		},
		{
			text = "Exercise and lifestyle changes",
			effects = { Health = 8, Happiness = 3 },
			feedText = "Changing habits...",
			onResolve = function(state)
				local roll = math.random(1, 100)
				if roll <= 30 then
					state.Flags = state.Flags or {}
					state.Flags.diabetes_lifestyle_controlled = true
					if state.AddFeed then
						state:AddFeed("💉 Lifestyle changes making a real difference! Less medication needed!")
					end
				else
					if state.AddFeed then
						state:AddFeed("💉 Exercise helping but still need medication. Every bit counts.")
					end
				end
			end,
		},
		{
			text = "Ignore it and hope for the best",
			effects = { Happiness = 5, Health = -15 },
			feedText = "Living dangerously...",
			onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.untreated_diabetes = true
				if state.AddFeed then
					state:AddFeed("⚠️ DANGEROUS! Uncontrolled diabetes causes serious complications!")
				end
			end,
		},
	},
}

return HealthEvents
