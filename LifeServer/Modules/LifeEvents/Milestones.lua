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
		text = "You're 18! Legally an adult now.",
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
			{ text = "Ready to take on the world", effects = { Happiness = 10 }, setFlags = { confident_adult = true }, feedText = "Adulthood, here you come!" },
			{ text = "Nervous but excited", effects = { Happiness = 5, Smarts = 2 }, feedText = "It's a lot of responsibility." },
			{ text = "Nothing really changed", effects = { Happiness = 3 }, feedText = "Just another birthday." },
			{ text = "Register to vote!", effects = { Smarts = 3, Happiness = 5 }, setFlags = { civic_minded = true }, feedText = "You exercised your new civic rights!" },
		},
	},
	{
		id = "driving_license",
		title = "Getting Your License",
		emoji = "🚗",
		text = "You're at the DMV for your driver's license test. The instructor looks strict.",
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
					local baseChance = 0.30 -- bad approach
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
		baseChance = 0.3,
		cooldown = 5,
		requiresJob = true,
		priority = "high",
		isMilestone = true,
		-- CRITICAL: Block this event for retired players
		blockedByFlags = { retired = true, semi_retired = true },

		-- META
		stage = "adult",
		ageBand = "adult_midlife",
		category = "career",
		milestoneKey = "MAJOR_PROMOTION",
		tags = { "job", "promotion", "senior_role" },
		careerTags = { "management" },

		-- CRITICAL FIX: Actually update the job when promoted!
		onComplete = function(state, choice, eventDef, outcome)
			if state.CurrentJob and state.CurrentJob.salary then
				local oldSalary = state.CurrentJob.salary
				local oldTitle = state.CurrentJob.name or "Employee"
				
				-- Give a 20-35% raise on promotion
				-- CRITICAL FIX: Use consistent Random API
				local RANDOM_PROMO = Random.new()
				local raisePercent = RANDOM_PROMO:NextInteger(20, 35) / 100
				local newSalary = math.floor(oldSalary * (1 + raisePercent))
				
				-- Generate a promoted title
				local promotedTitle = "Senior " .. oldTitle
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
				
				-- Update the job
				state.CurrentJob.name = promotedTitle
				state.CurrentJob.salary = newSalary
				
				-- Update CareerInfo
				state.CareerInfo = state.CareerInfo or {}
				state.CareerInfo.promotions = (state.CareerInfo.promotions or 0) + 1
				state.CareerInfo.lastPromotion = state.Age
				state.CareerInfo.promotionHistory = state.CareerInfo.promotionHistory or {}
				table.insert(state.CareerInfo.promotionHistory, {
					fromTitle = oldTitle,
					toTitle = promotedTitle,
					age = state.Age,
					year = state.Year,
					salaryIncrease = newSalary - oldSalary,
				})
				
				-- Update feed with actual promotion details
				if state.AddFeed then
					state:AddFeed("📈 Promoted to " .. promotedTitle .. "! Salary: $" .. tostring(newSalary) .. "/year (+$" .. tostring(newSalary - oldSalary) .. ")")
				end
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
			-- Calculate pension based on career history
			local pensionBase = 0
			if state.CurrentJob and state.CurrentJob.salary then
				pensionBase = math.floor(state.CurrentJob.salary * 0.4) -- 40% of last salary
			end
			
			-- Store pension info before clearing career
			state.Flags = state.Flags or {}
			state.Flags.retired = true
			state.Flags.pension_amount = pensionBase
			
			-- Store last job for history
			if state.CurrentJob then
				state.CareerInfo = state.CareerInfo or {}
				state.CareerInfo.lastJob = state.CurrentJob
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

		choices = {
			{ text = "Best years ahead", effects = { Happiness = 10 }, feedText = "Your 30s are going to be amazing!" },
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

		choices = {
			{ text = "Life begins at 40", effects = { Happiness = 10 }, feedText = "The best is yet to come!" },
			{ text = "Time for a midlife check-in", effects = { Smarts = 3, Happiness = 5 }, feedText = "You're reflecting on where you are." },
			-- CRITICAL FIX: Show price in choice text and add eligibility check!
			{ 
				text = "Buy a sports car ($5,000)", 
				effects = { Happiness = 8, Money = -5000 }, 
				setFlags = { midlife_crisis = true }, 
				feedText = "Midlife crisis? Or just having fun?",
				eligibility = function(state)
					if (state.Money or 0) < 5000 then
						return false, "Can't afford a $5,000 sports car"
					end
					return true
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
}

-- CRITICAL FIX #135: Export events in standard format for LifeEvents loader
-- The init.lua module loader expects .events, .Events, or .LifeEvents array
Milestones.LifeEvents = Milestones.events

return Milestones
