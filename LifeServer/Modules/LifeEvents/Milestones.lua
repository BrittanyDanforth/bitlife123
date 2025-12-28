--[[
    Milestone Events
    Important life events that mark major transitions
    These are priority events that should trigger when conditions are met
]]

local Milestones = {}

Milestones.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EARLY LIFE MILESTONES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "stage_transition_toddler",
		title = "Growing Up Fast",
		emoji = "👧",
		text = "You're becoming a toddler! The world is getting bigger.",
		question = "What's your personality like?",
		minAge = 2, maxAge = 3,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		-- META
		stage = "childhood",
		ageBand = "baby_toddler",
		category = "life_stage",
		milestoneKey = "STAGE_TODDLER",
		tags = { "core", "transition", "personality" },

		choices = {
			{ text = "Curious about everything", effects = { Smarts = 3, Happiness = 5 }, setFlags = { curious = true }, hintCareer = "science", feedText = "You want to explore everything!" },
			{ text = "Always making friends", effects = { Happiness = 7 }, setFlags = { social = true }, feedText = "You love being around people!" },
			{ text = "Quiet and observant", effects = { Smarts = 5 }, setFlags = { observant = true }, feedText = "You watch and learn." },
			{ text = "Little troublemaker", effects = { Happiness = 5 }, setFlags = { mischievous = true }, feedText = "You keep your parents on their toes!" },
		},
	},
	{
		id = "birth_story",
		title = "Your Origin Story",
		emoji = "📖",
		text = "Your parents told you about the day you were born.",
		question = "What was special about your birth?",
		minAge = 3, maxAge = 5,
		oneTime = true,
		isMilestone = true,

		-- META
		stage = "childhood",
		ageBand = "early_childhood",
		category = "family",
		milestoneKey = "BIRTH_STORY",
		tags = { "family", "background", "identity" },

		choices = {
			{ text = "Born during a big storm", effects = { Happiness = 3 }, setFlags = { dramatic_birth = true }, feedText = "You came into the world with thunder and lightning!" },
			{ text = "Very easy delivery", effects = { Health = 3 }, setFlags = { easy_birth = true }, feedText = "You arrived smoothly into the world." },
			{ text = "Born on a holiday", effects = { Happiness = 5 }, setFlags = { holiday_birthday = true }, feedText = "Your birthday is always a double celebration!" },
			{ text = "Nearly didn't make it", effects = { Health = 3, Smarts = 2 }, setFlags = { fighter_from_birth = true }, feedText = "You've been a fighter since day one." },
		},
	},
	{
		id = "family_background",
		title = "Understanding Your Family",
		emoji = "👨‍👩‍👧‍👦",
		text = "You're starting to understand your family's situation.",
		question = "What's your family like?",
		minAge = 4, maxAge = 6,
		oneTime = true,
		isMilestone = true,

		-- META
		stage = "childhood",
		ageBand = "early_childhood",
		category = "family",
		milestoneKey = "FAMILY_BACKGROUND",
		tags = { "family", "class", "upbringing" },

		choices = {
			{ text = "Wealthy and privileged", effects = { Money = 1000, Happiness = 3 }, setFlags = { wealthy_family = true }, feedText = "You grew up with advantages." },
			{ text = "Comfortable middle class", effects = { Money = 300, Happiness = 5 }, setFlags = { middle_class = true }, feedText = "A comfortable, stable upbringing." },
			{ text = "Working class, tight budget", effects = { Happiness = 3, Smarts = 2 }, setFlags = { working_class = true }, feedText = "You learned to value what you have." },
			{ text = "Single parent household", effects = { Smarts = 3 }, setFlags = { single_parent = true }, feedText = "Your parent worked extra hard for you." },
			{ text = "Big family with lots of siblings", effects = { Happiness = 5 }, setFlags = { has_siblings = true, big_family = true }, feedText = "Always someone to play with!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- COMING OF AGE MILESTONES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "turning_18",
		title = "Official Adulthood",
		emoji = "🎂",
		-- CRITICAL FIX #FUN-5: Added text variations for the big 18!
		textVariants = {
			"You're 18! LEGALLY AN ADULT! You can vote! Sign contracts! Get tattoos without permission! The world is your oyster... and also your responsibility now. No pressure!",
			"HAPPY 18TH BIRTHDAY! Your parents look at you with a mix of pride and terror. 'You're an adult now,' Mom says, tearing up. Dad hands you some official-looking papers. Taxes are coming. Adulthood is real.",
			"You blow out 18 candles and suddenly everything feels different. You can buy lottery tickets! Open a bank account! Move out! The possibilities are endless. The responsibilities are also endless. Hmm.",
			"18 YEARS OLD! You wake up expecting to feel different. You don't. But legally? EVERYTHING has changed. You're responsible for yourself now. The training wheels are officially off.",
			"The big 1-8! Your friends throw you a party with a cake that says 'Congrats, you survived childhood!' Dark humor aside, you actually made it. Now what?",
			"You're finally 18! Your inbox is already flooding with selective service registration reminders, voter registration forms, and credit card offers. This is what adulthood looks like, apparently.",
			"EIGHTEEN! Your little sibling asks if you feel any different. You say no. But secretly? You're terrified and excited in equal measure. This is it. The rest of your life starts now.",
			"Happy 18th! Your grandparents gave you a card with cash and a note: 'Welcome to paying bills!' Thanks, Grandma. Really feeling the love and the existential dread.",
		},
		text = "You're 18! Legally an adult now.",
		questionVariants = {
			"How do you feel about adulthood?",
			"What's your first move as an adult?",
			"Ready for this new chapter?",
		},
		question = "How do you feel about adulthood?",
		minAge = 18, maxAge = 18,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		-- META
		stage = "adult", -- transition into adult stage
		ageBand = "young_adult",
		category = "life_stage",
		milestoneKey = "TURNING_18",
		tags = { "core", "adulthood", "birthday" },

		choices = {
			{ text = "Ready to CONQUER the world! 💪", effects = { Happiness = 12 }, setFlags = { confident_adult = true, ambitious_start = true }, feedText = "Watch out world, here comes a BOSS! You're going to make this decade COUNT!" },
			{ text = "Nervous but cautiously optimistic", effects = { Happiness = 6, Smarts = 3 }, setFlags = { careful_adult = true }, feedText = "One step at a time. No need to rush. You'll figure it out." },
			{ text = "Register to vote - democracy time!", effects = { Smarts = 4, Happiness = 6 }, setFlags = { civic_minded = true, voter = true }, feedText = "First thing you did? Exercise your civic duty! Your vote counts!" },
			{ text = "Immediately make questionable adult decisions", effects = { Happiness = 8, Health = -2 }, setFlags = { wild_start = true }, feedText = "You celebrated by doing ALL the things you couldn't do before. Some you'll regret. Worth it?" },
			{ text = "Feel exactly the same, honestly", effects = { Happiness = 4, Smarts = 2 }, feedText = "Everyone hyped up 18 so much. But you're still just... you. That's okay." },
		},
	},
	{
		id = "driving_license",
		title = "Getting Your License",
		emoji = "🚗",
		-- CRITICAL FIX #FUN-6: Added text variations for DMV experience!
		textVariants = {
			"You're at the DMV for your driver's license test. The instructor looks like they've seen things. Terrible things. Specifically, they've seen teenagers drive.",
			"DMV DAY! The line was 2 hours long. You filled out forms wrong twice. But NOW you're in the car with a very tired-looking examiner. Deep breaths.",
			"The driving test examiner gets into the car and immediately checks their seatbelt. Three times. They grip the clipboard like a shield. 'Whenever you're ready,' they say unconvincingly.",
			"You've been dreaming of this moment! The DMV smell (paper and despair) fills your nostrils. The examiner approaches. They look at you. They sigh. 'Another one,' they mutter. Great start!",
			"Your DMV test is TODAY! You practiced parallel parking 100 times. Three-point turns until you saw them in your sleep. The examiner has a poker face. Impossible to read. Here we go.",
			"The DMV is PACKED. You watched three other teens fail before your turn. One cried. One hit a cone. One forgot how to start the car. YOU'VE GOT THIS. Probably. Maybe.",
			"The driving examiner introduces themselves with zero enthusiasm. They've been doing this for 20 years. 'Just drive normally,' they say. Nothing about this feels normal.",
			"You're finally taking your driving test! Your palms are sweating. The examiner smells like coffee and broken dreams. 'Put it in drive,' they say. Your whole future flashes before your eyes.",
		},
		text = "You're at the DMV for your driver's license test. The instructor looks strict.",
		questionVariants = {
			"What's your approach?",
			"How do you handle the test?",
			"Strategy for passing?",
		},
		question = "What's your approach?",
		minAge = 16, maxAge = 20,
		oneTime = true,
		isMilestone = true,
		-- CRITICAL FIX: Block if player already has a license from learning_to_drive event!
		blockedByFlags = { driver_license = true, has_license = true },

		-- META
		stage = "teen",
		ageBand = "teen_mid",
		category = "transport",
		milestoneKey = "DRIVING_LICENSE",
		tags = { "independence", "transport", "test" },

		-- CRITICAL FIX: Random outcomes based on stats, not player choice!
		choices = {
			{ 
				text = "Drive carefully and by the book", 
				effects = {},
				feedText = "You drove carefully...",
				onResolve = function(state)
					local baseChance = 0.70
					local smarts = state.Stats and state.Stats.Smarts or 50
					local health = state.Stats and state.Stats.Health or 50
					local bonus = ((smarts - 50) + (health - 50)) / 200
					if state.Flags and state.Flags.good_driver then bonus = bonus + 0.15 end
					
					if math.random() < (baseChance + bonus) then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.has_license = true
						state.Flags.good_driver = true
						state:AddFeed("🚗 You passed your driving test! Licensed driver!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🚗 You failed the test. Parallel parking was your downfall.")
					end
				end,
			},
			{ 
				text = "Try to impress with your skills", 
				effects = {},
				feedText = "You tried to show off...",
				onResolve = function(state)
					local baseChance = 0.45 -- riskier approach
					local smarts = state.Stats and state.Stats.Smarts or 50
					local bonus = (smarts - 50) / 150
					
					if math.random() < (baseChance + bonus) then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.has_license = true
						state.Flags.confident_driver = true
						state:AddFeed("🚗 The instructor was impressed! Perfect score, licensed!")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🚗 Showing off backfired. Failed! The instructor was not amused.")
					end
				end,
			},
			{ 
				text = "Hope for the best, wing it", 
				effects = {},
				feedText = "You went in unprepared...",
				onResolve = function(state)
					local baseChance = 0.550 -- bad approach
					if state.Flags and state.Flags.good_driver then baseChance = 0.50 end
					
					if math.random() < baseChance then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.has_license = true
						state:AddFeed("🚗 Somehow you passed winging it! Lucky day!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🚗 You weren't prepared enough. Failed the test.")
					end
				end,
			},
			{ 
				text = "Skip it - public transport works fine", 
				effects = { },
				feedText = "You decided not to get a license. Public transport it is!",
			},
		},
	},
	{
		id = "first_car",
		title = "First Set of Wheels",
		emoji = "🚙",
		text = "You're getting your first car!",
		question = "What kind of car?",
		minAge = 16, maxAge = 25,
		oneTime = true,
		requiresFlags = { has_license = true },
		blockedByFlags = { has_car = true, has_vehicle = true, car_owner = true, in_prison = true },
		-- CRITICAL FIX: Need at least some money or a generous family!
		eligibility = function(state)
			-- Either has enough for cheapest car OR might get a family gift
			local money = state.Money or 0
			-- $200 minimum or family might help
			return money >= 200 or true -- Family gift option always available
		end,

		-- META
		stage = "teen",
		ageBand = "late_teen",
		category = "transport",
		milestoneKey = "FIRST_CAR",
		tags = { "transport", "money", "independence" },

		choices = {
			{
				text = "A beat-up used car",
				effects = { Happiness = 7 },
				setFlags = { has_car = true, has_vehicle = true },
				feedText = "Looking for a beater...",
				-- CRITICAL FIX: Money validation for $500 beater
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 500 then
						state.Money = money - 500
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "beater_car_" .. tostring(state.Age or 0),
								name = "Beat-up Used Car",
								emoji = "🚙",
								price = 500,
								value = 400,
								condition = 35,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then
							state:AddFeed("🚙 It's not pretty, but it's yours!")
						end
					elseif money >= 200 then
						state.Money = money - 200
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "junker_car_" .. tostring(state.Age or 0),
								name = "Barely Running Junker",
								emoji = "🚙",
								price = 200,
								value = 100,
								condition = 15,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then
							state:AddFeed("🚙 It barely runs, but wheels are wheels!")
						end
					else
						-- Can't afford, parents help with loan
						if state.ModifyStat then state:ModifyStat("Happiness", -3) end
						state.Flags = state.Flags or {}
						state.Flags.owes_parents = true
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "loaner_car_" .. tostring(state.Age or 0),
								name = "Parents' Loaner Car",
								emoji = "🚙",
								price = 0,
								value = 800,
								condition = 40,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then
							state:AddFeed("🚙 Parents loaned you the old family car. You owe them!")
						end
					end
				end,
			},
			{
				text = "A decent reliable car",
				effects = { Happiness = 8 },
				setFlags = { has_car = true, has_vehicle = true },
				feedText = "Looking for something reliable...",
				-- CRITICAL FIX: Money validation for $3000 car
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 3000 then
						state.Money = money - 3000
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "reliable_car_" .. tostring(state.Age or 0),
								name = "Reliable Used Car",
								emoji = "🚗",
								price = 3000,
								value = 2500,
								condition = 65,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then
							state:AddFeed("🚗 A solid first car!")
						end
					elseif money >= 1500 then
						state.Money = money - 1500
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "older_car_" .. tostring(state.Age or 0),
								name = "Older Used Car",
								emoji = "🚗",
								price = 1500,
								value = 1200,
								condition = 50,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then
							state:AddFeed("🚗 Older than hoped but still decent!")
						end
					elseif money >= 500 then
						state.Money = money - 500
						if state.ModifyStat then state:ModifyStat("Happiness", -4) end
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "beater_compromise_" .. tostring(state.Age or 0),
								name = "Beat-up Used Car",
								emoji = "🚙",
								price = 500,
								value = 400,
								condition = 35,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then
							state:AddFeed("🚙 Can't afford reliable - settling for a beater.")
						end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -6) end
						if state.AddFeed then
							state:AddFeed("💸 Can't afford a car right now...")
						end
						state.Flags = state.Flags or {}
						state.Flags.has_car = nil
						state.Flags.has_vehicle = nil
					end
				end,
			},
			{
				text = "A gift from family",
				effects = { Happiness = 10 },
				setFlags = { has_car = true, has_vehicle = true },
				feedText = "Your family helped you get a car!",
				onResolve = function(state)
					if state.AddAsset then
						state:AddAsset("Vehicles", {
							id = "gift_car_" .. tostring(state.Age or 0),
							name = "Family Gift Car",
							emoji = "🚗",
							price = 0,
							value = 5000,
							condition = 70,
							isEventAcquired = true,
						})
					end
				end,
			},
			{
				text = "Saving up for something better",
				effects = { Money = 200 },
				feedText = "You're waiting for the right one.",
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- EDUCATION MILESTONES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "college_graduation",
		title = "🎓 College Graduation!",
		emoji = "🎓",
		text = "You did it! Four years of hard work paid off.",
		question = "How do you feel about graduating?",
		minAge = 21, maxAge = 26,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		requiresFlags = { college_bound = true },

		-- META
		stage = "adult",
		ageBand = "young_adult",
		-- CRITICAL FIX #10: Added "graduation" category for gold event card
		category = "graduation",
		milestoneKey = "COLLEGE_GRADUATION",
		tags = { "college", "degree", "career_setup" },
		careerTags = { "career_general" },

		-- onComplete ensures Education is always set after any choice
		onComplete = function(state, choice, eventDef, outcome)
			state.Education = "bachelor"
			state.Flags = state.Flags or {}
			state.Flags.college_grad = true
			state.Flags.bachelor_degree = true
			state.Flags.college_graduate = true
			-- CRITICAL FIX: Set flags needed for education activities
			state.Flags.has_degree = true
			state.Flags.has_ged_or_diploma = true
			
			-- CRITICAL FIX: User reported "IM A COLLEGE STUDENT LIVING IN DORM ROOM STILL EVEN THO IM LIKE 40"
			-- MUST clear all college enrollment flags when graduating!
			state.Flags.in_college = nil
			state.Flags.college_student = nil
			state.Flags.enrolled_college = nil
			state.Flags.college_bound = nil
			
			if state.EducationData then
				state.EducationData.Status = "completed"
				state.EducationData.Level = "bachelor"
			end
		end,
		choices = {
			{
				text = "Proud and ready for the future",
				effects = { Happiness = 15, Smarts = 5 },
				setFlags = { college_grad = true, bachelor_degree = true },
				feedText = "You graduated college! Bachelor's degree earned!",
			},
			{
				text = "Relieved it's over",
				effects = { Happiness = 10, Smarts = 3 },
				setFlags = { college_grad = true, bachelor_degree = true },
				feedText = "Finally done with school!",
			},
			{
				text = "Already missing it",
				effects = { Happiness = 8, Smarts = 5 },
				setFlags = { college_grad = true, bachelor_degree = true },
				feedText = "The college years were special.",
			},
			{
				text = "Time for grad school",
				effects = { Smarts = 7, Money = -5000 },
				setFlags = { college_grad = true, bachelor_degree = true, grad_school = true, pursuing_graduate = true },
				feedText = "You're continuing your education!",
			},
		},
	},
	{
		id = "grad_school_complete",
		title = "Advanced Degree",
		emoji = "📜",
		text = "You've completed your advanced degree!",
		question = "What did you earn?",
		minAge = 24, maxAge = 35,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		requiresFlags = { grad_school = true },

		-- META
		stage = "adult",
		ageBand = "young_adult",
		category = "education",
		milestoneKey = "GRAD_SCHOOL_COMPLETE",
		tags = { "graduate_school", "degree", "career_setup" },
		careerTags = { "science", "law", "medical", "education" },

		choices = {
			{
				text = "Master's Degree",
				effects = { Smarts = 8, Happiness = 10, Money = 1000 },
				setFlags = { masters_degree = true, advanced_degree = true },
				feedText = "You earned your Master's!",
				onResolve = function(state)
					state.Education = "master"
					state.Flags.masters_degree = true
					if state.EducationData then
						state.EducationData.Status = "completed"
						state.EducationData.Level = "master"
					end
				end,
			},
			{
				text = "PhD/Doctorate",
				effects = { Smarts = 12, Happiness = 12 },
				setFlags = { doctorate = true, phd = true, advanced_degree = true },
				hintCareer = "science",
				feedText = "Dr. You! You earned your PhD!",
				onResolve = function(state)
					state.Education = "phd"
					state.Flags.doctorate = true
					state.Flags.phd = true
					if state.EducationData then
						state.EducationData.Status = "completed"
						state.EducationData.Level = "phd"
					end
				end,
			},
			{
				text = "Law Degree (JD)",
				effects = { Smarts = 10, Happiness = 10 },
				setFlags = { law_degree = true, advanced_degree = true },
				hintCareer = "law",
				feedText = "You passed the bar! You're a lawyer!",
				onResolve = function(state)
					state.Education = "law"
					state.Flags.law_degree = true
					state.Flags.passed_bar = true
					if state.EducationData then
						state.EducationData.Status = "completed"
						state.EducationData.Level = "law"
					end
				end,
			},
			{
				text = "Medical Degree (MD)",
				effects = { Smarts = 12, Happiness = 10 },
				setFlags = { medical_degree = true, advanced_degree = true },
				hintCareer = "medical",
				feedText = "Dr. You! You're a physician!",
				onResolve = function(state)
					state.Education = "medical"
					state.Flags.medical_degree = true
					state.Flags.is_doctor = true
					if state.EducationData then
						state.EducationData.Status = "completed"
						state.EducationData.Level = "medical"
					end
				end,
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- CAREER MILESTONES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "first_real_job",
		title = "Time to Start Working?",
		emoji = "💼",
		-- CRITICAL FIX: Changed from "you got a job" to asking if player WANTS a job
		text = "You're an adult now. It might be time to enter the workforce.",
		question = "What's your plan?",
		minAge = 18, maxAge = 28,
		oneTime = true,
		priority = "medium", -- Lowered priority - not forced
		isMilestone = true,
		baseChance = 0.6, -- Only 60% chance to trigger, not guaranteed
		-- CRITICAL FIX #305: Block for royalty - they don't need jobs! Also block if already has job
		blockedByFlags = { employed = true, has_job = true, has_teen_job = true, coder = true, tech_experience = true, is_royalty = true, royal_birth = true },
		requiresNoJob = true, -- Extra safety check

		-- META
		stage = "adult",
		ageBand = "young_adult",
		category = "career",
		milestoneKey = "FIRST_REAL_JOB",
		tags = { "job", "career_start", "money" },
		careerTags = { "career_general" },

		choices = {
			-- CRITICAL FIX: Added choice to NOT get a job - player agency is key!
			{ 
				text = "Start job hunting", 
				effects = { Happiness = 5 }, 
				setFlags = { job_hunting = true }, 
				feedText = "You're looking for work. Check the Jobs tab to apply!",
				-- No automatic job assignment - player chooses in OccupationScreen
			},
			{ 
				text = "Focus on education first", 
				effects = { Smarts = 3 }, 
				setFlags = { prioritizing_education = true }, 
				feedText = "You decided to focus on your studies before working." 
			},
			{ 
				text = "Take some time to figure things out", 
				effects = { Happiness = 2 }, 
				feedText = "No rush - you're exploring your options." 
			},
			{ 
				text = "Already have plans", 
				effects = { Happiness = 3 }, 
				feedText = "You've got your own path in mind." 
			},
			-- CRITICAL FIX: Added lazy/bum option for player agency - can lead to homelessness!
			{ 
				text = "Nah, I'll just chill (be lazy)", 
				effects = { Happiness = 3, Smarts = -2 }, 
				setFlags = { lazy = true, unemployed_by_choice = true, bum_life = true }, 
				feedText = "Work? That sounds like a lot of effort. You're gonna take it easy.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.lazy = true
					state.Flags.bum_life = true
					state.Flags.at_risk_homeless = true
					if state.AddFeed then
						state:AddFeed("⚠️ Without income, bills will pile up...")
					end
				end,
			},
		},
		
		-- CRITICAL FIX: REMOVED auto job assignment! Player should choose their own job!
		-- The old onComplete was forcing a random job on players without consent
		-- Now players can go to OccupationScreen and pick their own job
		onComplete = function(state, choice, eventDef, outcome)
			-- Only hint that jobs are available, don't force one
			if state.AddFeed and choice and choice.text == "Start job hunting" then
				state:AddFeed("💼 Tip: Open the Jobs tab to browse available positions!")
			end
		end,
		
		-- Keep backward compatibility but don't auto-assign
		_deprecated_onComplete = function(state, choice, eventDef, outcome)
			-- OLD CODE - REMOVED: Was forcing random jobs on players
			-- Generate a random entry-level job for the player
			local entryJobs = {
				{ id = "retail", name = "Retail Associate", company = "MegaMart", salary = 26000, category = "entry" },
				{ id = "cashier", name = "Cashier", company = "QuickMart", salary = 24000, category = "entry" },
				{ id = "fastfood", name = "Fast Food Worker", company = "Burger Palace", salary = 22000, category = "entry" },
				{ id = "office_assistant", name = "Office Assistant", company = "Business Solutions", salary = 35000, category = "office" },
				{ id = "receptionist", name = "Receptionist", company = "Corporate Office", salary = 32000, category = "office" },
				{ id = "waiter", name = "Waiter/Waitress", company = "The Grand Restaurant", salary = 32000, category = "service" },
				{ id = "barista", name = "Barista", company = "Bean Scene", salary = 28000, category = "service" },
				{ id = "data_entry", name = "Data Entry Clerk", company = "DataCorp", salary = 34000, category = "office" },
			}
			
			-- CRITICAL FIX: Use consistent Random API
			local RANDOM = Random.new()
			local job = entryJobs[RANDOM:NextInteger(1, #entryJobs)]
			
			if state.SetCareer then
				state:SetCareer({
					id = job.id,
					name = job.name,
					company = job.company,
					salary = job.salary,
					category = job.category,
				})
			else
				-- Fallback if SetCareer doesn't exist
				state.CurrentJob = {
					id = job.id,
					name = job.name,
					company = job.company,
					salary = job.salary,
					category = job.category,
				}
				state.Flags = state.Flags or {}
				state.Flags.employed = true
				state.Flags.has_job = true
			end
			
			-- Update feed text to include the job name
			if state.AddFeed then
				state:AddFeed("💼 You started working as a " .. job.name .. " at " .. job.company .. "!")
			end
		end,
	},
	{
		id = "major_promotion",
		title = "Big Promotion",
		emoji = "📈",
		text = "You've been promoted to a senior position!",
		question = "How do you handle the new responsibility?",
		minAge = 28, maxAge = 55,
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.55 - was triggering too often!
		cooldown = 6, -- CRITICAL FIX: Increased from 2 - promotions every 2 years is unrealistic!
		maxOccurrences = 3, -- Maximum 3 major promotions per career
		requiresJob = true,
		priority = "medium", -- CRITICAL FIX: Reduced from "high" to prevent spam
		isMilestone = true,
		-- CRITICAL: Block this event for retired players
		blockedByFlags = { retired = true, semi_retired = true },
		
		-- CRITICAL FIX #506: Block for entertainment careers - they have their own progression!
		-- Rappers, musicians, actors, influencers progress through Fame, not corporate promotions
		eligibility = function(state)
			if not state.CurrentJob then return false end
			local jobCat = (state.CurrentJob.category or ""):lower()
			local jobId = (state.CurrentJob.id or ""):lower()
			
			-- Block for entertainment careers
			if jobCat == "entertainment" or jobCat == "creative" or jobCat == "music" then
				return false, "Entertainment careers have their own progression"
			end
			-- Block for specific entertainment job IDs
			if jobId:find("rapper") or jobId:find("musician") or jobId:find("actor") or
			   jobId:find("singer") or jobId:find("streamer") or jobId:find("influencer") or
			   jobId:find("creator") or jobId:find("celebrity") or jobId:find("athlete") then
				return false, "Entertainment careers have their own progression"
			end
			-- Block if they have isFameCareer flag on their job
			if state.CurrentJob.isFameCareer then
				return false, "Fame careers have their own progression"
			end
			return true
		end,

		-- META
		stage = "adult",
		ageBand = "adult_midlife",
		category = "career",
		milestoneKey = "MAJOR_PROMOTION",
		tags = { "job", "promotion", "senior_role" },
		careerTags = { "management" },

		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #11: major_promotion MUST use CareerTracks to sync with OccupationScreen!
		-- The old code just prefixed "Senior " to job titles, breaking the career track system.
		-- Now we look up the actual next job in the career track and promote to THAT job.
		-- This fixes the disconnect between major_promotion events and career progression display.
		-- ═══════════════════════════════════════════════════════════════════════════════
		onComplete = function(state, choice, eventDef, outcome)
			if not state.CurrentJob or not state.CurrentJob.salary then
				return
			end
			
			local oldSalary = state.CurrentJob.salary
			local oldTitle = state.CurrentJob.name or "Employee"
			local oldJobId = state.CurrentJob.id
			
			-- Try to find next job in career track
			local promotedToTrackJob = false
			local newJobData = nil
			
			-- CRITICAL FIX: Use the global CareerTracks and JobCatalog from LifeBackend
			-- These are accessed through the event resolution context or require
			local careerTracksRef = nil
			local jobCatalogRef = nil
			
			-- Try to get CareerTracks from parent module context
			local ModulesFolder = script.Parent and script.Parent.Parent
			if ModulesFolder then
				local success, backendRef = pcall(function()
					-- CareerTracks are exported through the init module
					return nil -- We'll build them inline for this event
				end)
			end
			
			-- ═══════════════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX #52: Define career tracks inline for promotion lookup
			-- This mirrors the CareerTracks in LifeBackend.lua
			-- INCLUDES entry-level track so generic first jobs can progress!
			-- ═══════════════════════════════════════════════════════════════════════════════
			local CareerTracks = {
				-- CRITICAL FIX #53: Entry-level tracks for players who got generic first jobs
				entry = { "entry_career", "office_assistant", "administrative_assistant", "office_manager", "project_manager" },
				entry_service = { "retail_worker", "cashier", "shift_supervisor", "store_manager", "district_manager" },
				entry_food = { "fast_food_worker", "server", "shift_lead", "restaurant_manager" },
				-- Office tracks
				office = { "receptionist", "office_assistant", "data_entry", "administrative_assistant", "office_manager", "project_manager", "operations_director", "coo" },
				-- Tech tracks (require coder/tech flags)
				tech_dev = { "it_support", "junior_developer", "developer", "senior_developer", "tech_lead", "software_architect", "cto" },
				tech_web = { "web_developer", "developer", "senior_developer", "tech_lead" },
				-- Medical tracks
				medical_nursing = { "hospital_orderly", "medical_assistant", "nurse_lpn", "nurse_rn", "nurse_practitioner" },
				medical_doctor = { "doctor_resident", "doctor", "surgeon", "chief_of_medicine" },
				-- Legal tracks
				legal = { "legal_assistant", "paralegal", "associate_lawyer", "lawyer", "senior_partner" },
				-- Finance tracks
				finance_banking = { "bank_teller", "loan_officer", "accountant_jr", "accountant", "cpa", "cfo" },
				finance_invest = { "financial_analyst", "investment_banker_jr", "investment_banker", "hedge_fund_manager" },
				-- Creative tracks
				creative_design = { "graphic_designer_jr", "graphic_designer", "art_director" },
				creative_media = { "journalist_jr", "journalist", "editor" },
				creative_marketing = { "social_media_manager", "marketing_associate", "marketing_manager", "cmo" },
				creative_acting = { "actor_extra", "actor", "movie_star" },
				creative_music = { "musician_local", "musician_signed", "pop_star" },
				-- Government tracks
				gov_police = { "police_officer", "detective", "police_chief" },
				-- Education tracks
				education_school = { "teaching_assistant", "substitute_teacher", "teacher", "department_head", "principal", "superintendent" },
				education_university = { "professor_assistant", "professor", "dean" },
				-- Science tracks
				science = { "lab_technician", "research_assistant", "scientist", "senior_scientist", "research_director" },
				-- Sports tracks
				sports_player = { "minor_league", "professional_athlete", "star_athlete" },
				sports_coach = { "gym_instructor", "sports_coach", "head_coach" },
				-- Military tracks
				military_enlisted = { "enlisted", "sergeant" },
				military_officer = { "officer", "captain", "colonel", "general" },
				-- Esports tracks (require gamer flag)
				esports = { "casual_gamer", "content_creator", "pro_gamer", "esports_champion", "gaming_legend" },
				-- Racing tracks
				racing = { "go_kart_racer", "amateur_racer", "professional_racer", "f1_driver", "racing_legend" },
				-- Hacker tracks (require coder flag)
				hacker_whitehat = { "script_kiddie", "freelance_hacker", "pen_tester", "security_consultant", "ciso" },
			}
			
			-- ═══════════════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX #54: Map job categories to their allowed tracks
			-- This prevents players from being promoted into incompatible career tracks
			-- (e.g., entry worker shouldn't suddenly become a tech lead)
			-- ═══════════════════════════════════════════════════════════════════════════════
			local categoryToTracks = {
				entry = { "entry", "entry_service", "entry_food", "office" },
				service = { "entry_service", "entry_food" },
				office = { "office" },
				tech = { "tech_dev", "tech_web" },
				medical = { "medical_nursing", "medical_doctor" },
				legal = { "legal" },
				finance = { "finance_banking", "finance_invest" },
				creative = { "creative_design", "creative_media", "creative_marketing", "creative_acting", "creative_music" },
				government = { "gov_police" },
				education = { "education_school", "education_university" },
				science = { "science" },
				sports = { "sports_player", "sports_coach" },
				military = { "military_enlisted", "military_officer" },
				esports = { "esports" },
				racing = { "racing" },
				hacker = { "hacker_whitehat" },
			}
			
			-- Get current job category
			local currentCategory = (state.CurrentJob.category and state.CurrentJob.category:lower()) or "entry"
			local allowedTracks = categoryToTracks[currentCategory] or { "entry", "office" }
			
			-- Look up the next job in the career track - ONLY in allowed tracks!
			if oldJobId then
				for _, trackName in ipairs(allowedTracks) do
					local trackJobs = CareerTracks[trackName]
					if trackJobs then
						for i, jobId in ipairs(trackJobs) do
							if jobId == oldJobId then
								-- Found current job - get next position
								local nextJobId = trackJobs[i + 1]
								if nextJobId then
									promotedToTrackJob = true
									newJobData = {
										id = nextJobId,
										name = nextJobId:gsub("_", " "):gsub("(%a)([%w_']*)", function(f,r) return f:upper()..r:lower() end),
									}
									
									-- Update the actual job ID so career track is in sync!
									state.CurrentJob.id = nextJobId
									-- CRITICAL FIX #55: Preserve job category during promotion
									-- Don't change category - player stays in their career path
								end
								break
							end
						end
					end
					if promotedToTrackJob then break end
				end
			end
			
			-- Calculate new salary (25% raise for track promotion, 15-25% for generic)
			-- CRITICAL FIX #56: Cap salary increases to prevent unrealistic jumps
			local RANDOM_PROMO = Random.new()
			local newSalary
			local promotedTitle
			local maxSalaryIncrease = oldSalary * 0.40 -- Max 40% increase to prevent huge jumps
			
			if promotedToTrackJob and newJobData then
				-- CRITICAL: Use the track job name instead of fake "Senior X" titles!
				newSalary = math.floor(oldSalary * 1.25)
				promotedTitle = newJobData.name
				state.CurrentJob.name = promotedTitle
				state.CurrentJob.title = promotedTitle
			else
				-- Fallback: No next track job (top of career) - just salary bump with title tweak
				local raisePercent = RANDOM_PROMO:NextInteger(15, 25) / 100
				newSalary = math.floor(oldSalary * (1 + raisePercent))
				
				-- Generate a promoted title only as fallback
				promotedTitle = "Senior " .. oldTitle
				if oldTitle:find("Junior") then
					promotedTitle = oldTitle:gsub("Junior ", "")
				elseif oldTitle:find("Associate") then
					promotedTitle = oldTitle:gsub("Associate", "Senior")
				elseif oldTitle:find("Senior") then
					promotedTitle = "Lead " .. oldTitle:gsub("Senior ", "")
				elseif oldTitle:find("Lead") then
					promotedTitle = "Principal " .. oldTitle:gsub("Lead ", "")
				elseif oldTitle:find("Manager") then
					promotedTitle = "Director of " .. (state.CurrentJob.company or "Operations")
				end
				
				state.CurrentJob.name = promotedTitle
				state.CurrentJob.title = promotedTitle
			end
			
			state.CurrentJob.salary = newSalary
			
			-- Update CareerInfo - CRITICAL: Reset promotion progress!
			state.CareerInfo = state.CareerInfo or {}
			state.CareerInfo.promotions = (state.CareerInfo.promotions or 0) + 1
			state.CareerInfo.lastPromotion = state.Age
			state.CareerInfo.promotionProgress = 0 -- CRITICAL FIX #10: Reset progress after promotion!
			state.CareerInfo.yearsAtJob = 0 -- Reset years at new position
			state.CareerInfo.raises = 0 -- Reset raises for new role
			state.CareerInfo.promotionHistory = state.CareerInfo.promotionHistory or {}
			table.insert(state.CareerInfo.promotionHistory, {
				fromTitle = oldTitle,
				toTitle = promotedTitle,
				fromJobId = oldJobId,
				toJobId = state.CurrentJob.id,
				age = state.Age,
				year = state.Year,
				salaryIncrease = newSalary - oldSalary,
				wasTrackPromotion = promotedToTrackJob,
			})
			
			-- Update feed with actual promotion details
			if state.AddFeed then
				local feedMsg = "📈 Promoted to " .. promotedTitle .. "! Salary: $" .. tostring(newSalary) .. "/year (+$" .. tostring(newSalary - oldSalary) .. ")"
				if promotedToTrackJob then
					feedMsg = "🎉 CAREER ADVANCEMENT: " .. feedMsg
				end
				state:AddFeed(feedMsg)
			end
		end,

		choices = {
			{ text = "Step up and lead", effects = { Happiness = 12, Money = 2000, Smarts = 3 }, setFlags = { senior_role = true, promoted = true }, feedText = "You rose to the challenge!" },
			{ text = "Grow into it gradually", effects = { Happiness = 8, Money = 1500, Smarts = 2 }, setFlags = { senior_role = true, promoted = true }, feedText = "You're adjusting to the new role." },
			{ text = "Struggle with impostor syndrome", effects = { Happiness = 5, Money = 1500, Smarts = 3 }, setFlags = { senior_role = true, promoted = true }, feedText = "You question if you deserve it." },
		},
	},
	{
		id = "retirement_day",
		title = "Retirement Day",
		emoji = "🎉",
		text = "Today is your last day of work. You're retiring!",
		question = "How do you feel?",
		minAge = 60, maxAge = 70,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		requiresJob = true,

		-- META
		stage = "senior",
		ageBand = "senior_early",
		category = "career",
		milestoneKey = "RETIREMENT_DAY",
		tags = { "retirement", "job_end", "transition" },

		-- CRITICAL: Clear job when retiring to prevent career events from firing
		onComplete = function(state, choice, eventDef, outcome)
			-- CRITICAL FIX: Calculate pension from multiple sources since state.CurrentJob.salary
			-- may not reflect actual earnings (e.g., fame careers where catalog salary differs)
			local pensionBase = 0
			local actualSalary = 0
			
			-- Try multiple sources to get the actual salary
			-- 1. Check if there's stored salary info from last year's payment
			if state.CareerInfo and state.CareerInfo.lastPaidSalary and state.CareerInfo.lastPaidSalary > 0 then
				actualSalary = state.CareerInfo.lastPaidSalary
			end
			
			-- 2. Check state.CurrentJob.salary (may be outdated for fame careers)
			if actualSalary == 0 and state.CurrentJob and state.CurrentJob.salary then
				actualSalary = state.CurrentJob.salary
			end
			
			-- 3. Estimate from net worth growth if salary seems too low (fame career fix)
			-- If salary is suspiciously low but player has high net worth, estimate from that
			if actualSalary < 1000 and state.Money and state.Money > 1000000 then
				-- Estimate salary as roughly 10-20% of net worth for famous people
				actualSalary = math.floor(state.Money * 0.15)
			end
			
			-- Calculate pension as 40% of actual salary
			if actualSalary > 0 then
				pensionBase = math.floor(actualSalary * 0.4)
			end
			
			-- Ensure minimum pension of $15,000
			pensionBase = math.max(15000, pensionBase)
			
			-- Store pension info before clearing career
			state.Flags = state.Flags or {}
			state.Flags.retired = true
			state.Flags.pension_amount = pensionBase
			
			-- Store last job for history
			if state.CurrentJob then
				state.CareerInfo = state.CareerInfo or {}
				state.CareerInfo.lastJob = state.CurrentJob
				state.CareerInfo.lastJobSalary = actualSalary -- Store actual salary for records
				state.CareerInfo.retirementAge = state.Age
			end
			
			-- Clear the job using ClearCareer if available
			if state.ClearCareer then
				state:ClearCareer()
			else
				state.CurrentJob = nil
				state.Flags.employed = nil
				state.Flags.has_job = nil
			end
		end,

		choices = {
			{ text = "Grateful for the journey", effects = { Happiness = 15 }, setFlags = { retired = true }, feedText = "A career well spent. Time to relax! You'll receive pension income." },
			{ text = "Ready for the next adventure", effects = { Happiness = 12 }, setFlags = { retired = true, active_retiree = true }, feedText = "Retirement is just a new beginning! Pension secured." },
			{ text = "A bit sad to leave", effects = { Happiness = 8 }, setFlags = { retired = true }, feedText = "You'll miss the workplace, but it's time. Pension awaits." },
			{ text = "Relieved!", effects = { Happiness = 10, Health = 5 }, setFlags = { retired = true }, feedText = "Finally free! Enjoy your pension!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- DECADE BIRTHDAYS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "turning_30",
		title = "The Big 3-0",
		emoji = "3️⃣0️⃣",
		-- CRITICAL FIX #807: Dynamic text based on actual life status!
		-- User complaint: "It doesn't check if I'm famous"
		text = "You're turning 30! Welcome to a new decade.",
		question = "How do you approach your 30s?",
		minAge = 30, maxAge = 30,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		-- META
		stage = "adult",
		ageBand = "adult_30s",
		category = "decade_birthday",
		milestoneKey = "TURNING_30",
		tags = { "birthday", "decade", "reflection" },
		
		-- CRITICAL FIX: Dynamic text based on player's life
		getDynamicText = function(state)
			local money = state.Money or 0
			local fame = state.Fame or 0
			local hasJob = state.CurrentJob ~= nil
			local jobName = hasJob and state.CurrentJob.name or "unemployed"
			local happiness = (state.Stats and state.Stats.Happiness) or state.Happiness or 50
			
			local text = "You're turning 30! "
			
			-- Fame-based
			if fame >= 70 then
				text = "🌟 You're turning 30 as a FAMOUS celebrity! The world knows your name! "
			elseif fame >= 40 then
				text = "⭐ You're turning 30 with some fame under your belt. People recognize you! "
			end
			
			-- Money-based
			if money >= 1000000 then
				text = text .. string.format("With $%.1fM in the bank, you're set for life! ", money/1000000)
			elseif money >= 100000 then
				text = text .. string.format("With $%.0fK saved, you're doing great! ", money/1000)
			elseif money < 5000 then
				text = text .. "Money is tight, but there's still time to build wealth. "
			end
			
			-- Career-based
			if hasJob and jobName then
				text = text .. string.format("Your career as a %s defines this chapter.", jobName)
			else
				text = text .. "Career-wise, you're still figuring things out."
			end
			
			return { 
				text = text, 
				money = money, 
				fame = fame, 
				isFamous = fame >= 40,
				isRich = money >= 100000,
			}
		end,

		choices = {
			{ 
				text = "Best years ahead", 
				effects = { Happiness = 10 }, 
				feedText = "Your 30s are going to be amazing!",
				onResolve = function(state)
					if state.Fame and state.Fame >= 50 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎉 You're famous AND turning 30! Life is incredible!")
					end
				end,
			},
			{ text = "Time to get serious", effects = { Smarts = 5, Happiness = 5 }, feedText = "Time to build your life." },
			{ text = "Feeling old already", effects = { Happiness = -3 }, feedText = "Where did the time go?" },
			{ text = "Just getting started", effects = { Happiness = 8, Health = 3 }, feedText = "Age is just a number!" },
		},
	},
	{
		id = "turning_40",
		title = "The Big 4-0",
		emoji = "4️⃣0️⃣",
		text = "You're 40! Midlife is here.",
		question = "How do you feel about turning 40?",
		minAge = 40, maxAge = 40,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		-- META
		stage = "adult",
		ageBand = "adult_40s",
		category = "decade_birthday",
		milestoneKey = "TURNING_40",
		tags = { "birthday", "midlife", "reflection" },
		
		-- CRITICAL FIX #900: Dynamic text based on player's life at 40!
		getDynamicText = function(state)
			local money = state.Money or 0
			local fame = state.Fame or 0
			local health = (state.Stats and state.Stats.Health) or 50
			local happiness = (state.Stats and state.Stats.Happiness) or 50
			local hasJob = state.CurrentJob ~= nil
			local flags = state.Flags or {}
			
			local baseText = "You're 40! "
			
			-- Life status assessment
			if fame >= 70 then
				baseText = baseText .. "The cameras flash as you celebrate - you're FAMOUS at 40! "
			elseif money >= 1000000 then
				baseText = baseText .. "Champagne toast on your yacht - you're a MILLIONAIRE at 40! "
			elseif money >= 100000 then
				baseText = baseText .. "You've built real wealth by 40. The hard work paid off! "
			elseif flags.homeless then
				baseText = baseText .. "No home, no party. This birthday hits different when you're on the streets. "
			elseif flags.in_prison then
				baseText = baseText .. "Spending your 40th behind bars. Plenty of time to reflect. "
			elseif hasJob and state.CurrentJob.salary and state.CurrentJob.salary > 100000 then
				baseText = baseText .. "Your corner office has a great view for this milestone! "
			end
			
			-- Health status
			if health >= 80 then
				baseText = baseText .. "You're in peak shape - 40 looks GOOD on you!"
			elseif health < 40 then
				baseText = baseText .. "Your body's starting to remind you it's not 20 anymore..."
			else
				baseText = baseText .. "Midlife is officially here."
			end
			
			return baseText
		end,

		choices = {
			{ text = "Life begins at 40", effects = { Happiness = 10 }, feedText = "The best is yet to come!" },
			{ text = "Time for a midlife check-in", effects = { Smarts = 3, Happiness = 5 }, feedText = "You're reflecting on where you are." },
			-- CRITICAL FIX: Sports car actually adds a vehicle to your Assets!
			{ 
				text = "Buy a used sports car ($8,000)", 
				effects = { Happiness = 12, Money = -8000 }, 
				setFlags = { midlife_crisis = true, has_car = true, has_sports_car = true }, 
				feedText = "🚗 Midlife crisis? Maybe. But you look GOOD!",
				eligibility = function(state)
					if (state.Money or 0) < 8000 then
						return false, "Can't afford a sports car"
					end
					return true
				end,
				onResolve = function(state)
					-- CRITICAL FIX: Actually add the car to Assets!
					state.Assets = state.Assets or {}
					state.Assets.Vehicles = state.Assets.Vehicles or {}
					table.insert(state.Assets.Vehicles, {
						id = "midlife_sports_car_" .. tostring(os.time()),
						name = "Used Sports Car",
						emoji = "🏎️",
						price = 8000,
						value = 8000,
						happiness = 5,
						maintenance = 1500,
						acquiredAge = state.Age,
						acquiredYear = state.Year,
						resaleModifier = 0.65,
						type = "sports_car",
					})
					state.Flags = state.Flags or {}
					state.Flags.has_vehicle = true
					state.Flags.has_car = true
					state.Flags.has_sports_car = true
					state:AddFeed("🏎️ You bought a used sports car! Feel that engine roar!")
				end,
			},
			{ text = "Content with where I am", effects = { Happiness = 8 }, feedText = "You're at peace with your life." },
		},
	},
	{
		id = "turning_50",
		title = "Half Century",
		emoji = "5️⃣0️⃣",
		text = "50 years! Half a century of experiences.",
		question = "What's your outlook?",
		minAge = 50, maxAge = 50,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		-- META
		stage = "adult",
		ageBand = "adult_50s",
		category = "decade_birthday",
		milestoneKey = "TURNING_50",
		tags = { "birthday", "aging", "reflection" },
		
		-- CRITICAL FIX #901: Dynamic text based on player's life at 50!
		getDynamicText = function(state)
			local money = state.Money or 0
			local fame = state.Fame or 0
			local health = (state.Stats and state.Stats.Health) or 50
			local flags = state.Flags or {}
			local jobHistory = state.JobHistory or {}
			
			local baseText = "HALF A CENTURY! "
			
			-- Legacy assessment
			if fame >= 80 then
				baseText = baseText .. "You're a LEGEND! 50 years and still on top! "
			elseif money >= 5000000 then
				baseText = baseText .. "50 and worth MILLIONS! Your empire stands tall! "
			elseif money >= 500000 then
				baseText = baseText .. "Retirement fund looking GOOD at 50! "
			elseif flags.retired then
				baseText = baseText .. "Already retired - living the dream early! "
			elseif flags.homeless then
				baseText = baseText .. "50 years... and nowhere to call home. Time for change. "
			elseif #jobHistory >= 5 then
				baseText = baseText .. "5 decades, " .. #jobHistory .. " careers! What a journey! "
			end
			
			-- Family assessment
			if flags.has_grandchildren or flags.grandparent then
				baseText = baseText .. "The grandkids make this birthday extra special!"
			elseif flags.married or flags.has_spouse then
				baseText = baseText .. "Celebrating with your partner of many years!"
			elseif health >= 75 then
				baseText = baseText .. "Still feeling young and vibrant!"
			else
				baseText = baseText .. "Half a century of experiences behind you."
			end
			
			return baseText
		end,

		choices = {
			{ text = "Wiser and happier", effects = { Happiness = 10, Smarts = 3 }, feedText = "Age brings wisdom and contentment." },
			{ text = "Young at heart", effects = { Happiness = 8, Health = 3 }, feedText = "You feel as young as ever!" },
			{ text = "Worried about health", effects = { Happiness = -2, Health = 5 }, setFlags = { health_conscious = true }, feedText = "You're taking health more seriously." },
			{ text = "Best version of myself", effects = { Happiness = 12 }, feedText = "This is your era!" },
		},
	},
	{
		id = "becoming_grandparent",
		title = "Grandparent!",
		emoji = "👴",
		text = "Congratulations! You've become a grandparent!",
		question = "How do you approach this new role?",
		minAge = 45, maxAge = 80,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		requiresFlags = { parent = true },

		-- META
		stage = "senior",
		ageBand = "senior",
		category = "family",
		milestoneKey = "BECOMING_GRANDPARENT",
		tags = { "family", "grandparent", "next_generation" },

		choices = {
			{ text = "Overjoyed and involved", effects = { Happiness = 15 }, setFlags = { grandparent = true, active_grandparent = true }, feedText = "You're going to be the best grandparent!" },
			{ text = "Happy but keeping boundaries", effects = { Happiness = 10 }, setFlags = { grandparent = true }, feedText = "You'll be there when needed." },
			{ text = "Feeling old suddenly", effects = { Happiness = 5 }, setFlags = { grandparent = true }, feedText = "A grandparent already?" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: MORE ENGAGING MILESTONES FOR KEY AGES
	-- Making important ages feel SPECIAL and memorable!
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "first_best_friend",
		title = "Best Friends Forever!",
		emoji = "🤝",
		text = "You've made a BEST FRIEND! Someone you tell all your secrets to!",
		question = "How did you two become best friends?",
		minAge = 5, maxAge = 8,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		stage = "childhood",
		ageBand = "early_childhood",
		category = "social",
		milestoneKey = "FIRST_BEST_FRIEND",
		tags = { "core", "friendship", "social" },

		choices = {
			{ text = "Met on the playground!", effects = { Happiness = 12 }, setFlags = { has_best_friend = true, social_butterfly = true }, feedText = "You two became instant besties!" },
			{ text = "Sat next to each other in class!", effects = { Happiness = 10, Smarts = 2 }, setFlags = { has_best_friend = true }, feedText = "Study buddies who became best friends!" },
			{ text = "Neighbors who became inseparable!", effects = { Happiness = 11 }, setFlags = { has_best_friend = true, neighborhood_kid = true }, feedText = "Always at each other's houses!" },
			{ text = "Connected over video games!", effects = { Happiness = 10, Smarts = 1 }, setFlags = { has_best_friend = true, gamer_kid = true }, feedText = "Gaming buddies for life!" },
		},
	},
	{
		id = "first_pocket_money",
		title = "First Pocket Money!",
		emoji = "💰",
		text = "Your parents started giving you a weekly allowance! Your first real money!",
		question = "What do you do with your allowance?",
		minAge = 6, maxAge = 10,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		stage = "childhood",
		ageBand = "early_childhood",
		category = "finance",
		milestoneKey = "FIRST_POCKET_MONEY",
		tags = { "money", "responsibility", "learning" },

		choices = {
			{ 
				text = "SAVE IT ALL! 🏦", 
				effects = { Happiness = 5, Smarts = 3, Money = 50 }, 
				setFlags = { saver = true, financially_smart = true }, 
				feedText = "You're starting a savings habit early!" 
			},
			{ 
				text = "Spend it on candy! 🍬", 
				effects = { Happiness = 12 }, 
				setFlags = { spender = true }, 
				feedText = "So much candy! Your teeth might regret this!" 
			},
			{ 
				text = "Buy a toy I've been wanting! 🎮", 
				effects = { Happiness = 10, Money = -20 }, 
				setFlags = { goal_saver = true }, 
				feedText = "You saved up and bought something special!" 
			},
			{ 
				text = "Share with my friends! 💝", 
				effects = { Happiness = 8 }, 
				setFlags = { generous = true }, 
				feedText = "You're a generous kid!" 
			},
		},
	},
	{
		id = "turning_double_digits",
		title = "Double Digits!",
		emoji = "🔟",
		text = "You're turning 10! DOUBLE DIGITS! This feels like a BIG deal!",
		question = "How do you celebrate?",
		minAge = 10, maxAge = 10,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		stage = "childhood",
		ageBand = "late_childhood",
		category = "life_stage",
		milestoneKey = "DOUBLE_DIGITS",
		tags = { "birthday", "milestone", "growing_up" },

		choices = {
			{ text = "HUGE birthday party! ($100)", effects = { Happiness = 15, Money = -100 }, setFlags = { party_person = true }, feedText = "The party of the decade! Everyone came!", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Family needs $100 for the party" end },
			{ text = "Special trip with family! (free)", effects = { Happiness = 12, Health = 2 }, setFlags = { family_oriented = true }, feedText = "Made amazing memories with the family!" },
			{ text = "Get a pet as a gift! (free)", effects = { Happiness = 18 }, setFlags = { has_pet = true, animal_lover = true }, feedText = "THE BEST BIRTHDAY GIFT EVER!" },
			{ text = "New gaming console! (free)", effects = { Happiness = 14, Smarts = 1 }, setFlags = { gamer = true }, feedText = "Hours of gaming ahead! Best gift!" },
		},
	},
	{
		id = "first_heartbreak",
		title = "First Heartbreak",
		emoji = "💔",
		text = "Your first crush doesn't like you back... or worse, likes someone else. It HURTS.",
		question = "How do you handle your first heartbreak?",
		minAge = 12, maxAge = 16,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		stage = "teen",
		ageBand = "teen",
		category = "relationships",
		milestoneKey = "FIRST_HEARTBREAK",
		tags = { "romance", "emotional", "growing_up" },

		choices = {
			{ 
				text = "Cry it out with friends", 
				effects = { Happiness = -3 }, 
				setFlags = { emotionally_open = true, first_heartbreak = true }, 
				feedText = "Your friends were there for you. It gets better." 
			},
			{ 
				text = "Listen to sad music alone", 
				effects = { Happiness = -5, Smarts = 1 }, 
				setFlags = { introspective = true, first_heartbreak = true }, 
				feedText = "You wrote some deep thoughts in your journal." 
			},
			{ 
				text = "Pretend you don't care", 
				effects = { Happiness = -2 }, 
				setFlags = { guarded_heart = true, first_heartbreak = true }, 
				feedText = "Playing it cool on the outside." 
			},
			{ 
				text = "Channel it into sports/hobbies", 
				effects = { Happiness = 2, Health = 3 }, 
				setFlags = { channels_emotions = true, first_heartbreak = true }, 
				feedText = "You're going to come out stronger from this!" 
			},
		},
	},
	{
		id = "first_paycheck",
		title = "First Paycheck!",
		emoji = "💵",
		text = "You got your FIRST EVER paycheck! All that hard work, and now real money!",
		question = "What do you do with your first paycheck?",
		minAge = 14, maxAge = 18,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		requiresJob = true,

		stage = "teen",
		ageBand = "teen",
		category = "finance",
		milestoneKey = "FIRST_PAYCHECK",
		tags = { "money", "work", "achievement" },

		choices = {
			{ 
				text = "Open a savings account!", 
				effects = { Happiness = 8, Smarts = 3, Money = 200 }, 
				setFlags = { saver = true, financially_responsible = true }, 
				feedText = "Smart move! Your future self will thank you!" 
			},
			{ 
				text = "Buy something awesome!", 
				effects = { Happiness = 15 }, 
				setFlags = { treat_yourself = true }, 
				feedText = "You earned it! Enjoy that purchase!" 
			},
			{ 
				text = "Help the family with bills!", 
				effects = { Happiness = 6, Smarts = 2 }, 
				setFlags = { family_helper = true, mature_for_age = true }, 
				feedText = "Your family appreciates your contribution!" 
			},
			{ 
				text = "Blow it all on a weekend!", 
				effects = { Happiness = 12, Money = -150 }, 
				setFlags = { yolo_spender = true }, 
				feedText = "That was FUN! ...now you're broke again." 
			},
		},
	},
	{
		id = "milestone_moving_out",  -- CRITICAL FIX: Renamed to avoid duplicate ID
		title = "Moving Out!",
		emoji = "🏠",
		text = "It's time to leave the nest! You're getting your own place! Rent will be about $900/month.",
		question = "How do you feel about this huge step?",
		minAge = 18, maxAge = 25,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		
		-- CRITICAL FIX: Can't move out if already moved out or broke!
		blockedByFlags = {
			moved_out = true,
			has_own_place = true,
			has_apartment = true,
			in_prison = true,
			homeless = true,
		},
		
		-- CRITICAL FIX: Must be able to AFFORD to move out!
		eligibility = function(state)
			local money = state.Money or 0
			-- Need at least $1000 to move out
			if money < 1000 then
				return false, "💸 You need at least $1,000 to move out! Save up first."
			end
			-- If no job, need more savings
			if not state.CurrentJob and money < 5000 then
				return false, "💸 Without a job, you need $5,000+ saved to move out safely!"
			end
			return true
		end,

		stage = "adult",
		ageBand = "young_adult",
		category = "life_stage",
		milestoneKey = "MOVING_OUT",
		tags = { "independence", "adult", "home" },

		choices = {
			{ 
				text = "FREEDOM! So excited!", 
				effects = { Happiness = 15, Money = -500 }, 
				-- CRITICAL FIX: Set ALL housing flags for consistency
				setFlags = { 
					moved_out = true, 
					independent = true,
					has_own_place = true,
					has_apartment = true,
					renting = true,
				}, 
				feedText = "Your own place! No more rules! Rent is $900/month.",
				onResolve = function(state)
					state.HousingState = state.HousingState or {}
					state.HousingState.status = "renter"
					state.HousingState.type = "apartment"
					state.HousingState.rent = 900
					state.HousingState.yearsWithoutPayingRent = 0
					state.HousingState.missedRentYears = 0
					state.HousingState.moveInYear = state.Year or 2025
					state.Flags.living_with_parents = nil
				end,
			},
			{ 
				text = "Nervous but ready", 
				effects = { Happiness = 8, Smarts = 2, Money = -500 }, 
				setFlags = { 
					moved_out = true, 
					cautious_adult = true,
					has_own_place = true,
					has_apartment = true,
					renting = true,
				}, 
				feedText = "A big step, but you've got this. Budget carefully!",
				onResolve = function(state)
					state.HousingState = state.HousingState or {}
					state.HousingState.status = "renter"
					state.HousingState.type = "apartment"
					state.HousingState.rent = 900
					state.HousingState.yearsWithoutPayingRent = 0
					state.HousingState.missedRentYears = 0
					state.HousingState.moveInYear = state.Year or 2025
					state.Flags.living_with_parents = nil
				end,
			},
			{ 
				text = "Will miss home", 
				effects = { Happiness = 5, Money = -500 }, 
				setFlags = { 
					moved_out = true, 
					homebody = true,
					has_own_place = true,
					has_apartment = true,
					renting = true,
				}, 
				feedText = "It's bittersweet leaving home. But your own space awaits!",
				onResolve = function(state)
					state.HousingState = state.HousingState or {}
					state.HousingState.status = "renter"
					state.HousingState.type = "apartment"
					state.HousingState.rent = 900
					state.HousingState.yearsWithoutPayingRent = 0
					state.HousingState.missedRentYears = 0
					state.HousingState.moveInYear = state.Year or 2025
					state.Flags.living_with_parents = nil
				end,
			},
			{ 
				text = "Get roommates to save money", 
				effects = { Happiness = 10, Money = -250 }, 
				setFlags = { 
					moved_out = true, 
					has_roommates = true,
					has_own_place = true,
					has_apartment = true,
					renting = true,
				}, 
				feedText = "Living with friends! Your share is $500/month.",
				onResolve = function(state)
					state.HousingState = state.HousingState or {}
					state.HousingState.status = "renter"
					state.HousingState.type = "shared_apartment"
					state.HousingState.rent = 500
					state.HousingState.yearsWithoutPayingRent = 0
					state.HousingState.missedRentYears = 0
					state.HousingState.moveInYear = state.Year or 2025
					state.Flags.living_with_parents = nil
				end,
			},
		},
	},
}

-- CRITICAL FIX #135: Export events in standard format for LifeEvents loader
-- The init.lua module loader expects .events, .Events, or .LifeEvents array
Milestones.LifeEvents = Milestones.events

return Milestones
