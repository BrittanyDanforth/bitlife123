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
		text = "It's time to get your driver's license!",
		question = "How does the test go?",
		minAge = 16, maxAge = 20,
		oneTime = true,
		isMilestone = true,

		-- META
		stage = "teen",
		ageBand = "teen_mid",
		category = "transport",
		milestoneKey = "DRIVING_LICENSE",
		tags = { "independence", "transport", "test" },

		choices = {
			{ text = "Passed first try!", effects = { Happiness = 10, Smarts = 2 }, setFlags = { has_license = true, good_driver = true }, feedText = "You nailed the driving test!" },
			{ text = "Passed after a few attempts", effects = { Happiness = 5 }, setFlags = { has_license = true }, feedText = "Third time's the charm! You got your license." },
			{ text = "Still working on it", effects = { Happiness = -2 }, feedText = "You'll get it eventually." },
			{ text = "Don't need a license", effects = { }, feedText = "You'll use public transport." },
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

		-- META
		stage = "teen",
		ageBand = "late_teen",
		category = "transport",
		milestoneKey = "FIRST_CAR",
		tags = { "transport", "money", "independence" },

		choices = {
			{
				text = "A beat-up used car",
				effects = { Happiness = 7, Money = -500 },
				setFlags = { has_car = true, has_vehicle = true },
				feedText = "It's not pretty, but it's yours!",
				onResolve = function(state)
					local EventEngine = require(script.Parent).EventEngine
					EventEngine.addAsset(state, "vehicle", {
						id = "beater_car_" .. tostring(state.Age),
						name = "Beat-up Used Car",
						emoji = "🚙",
						price = 500,
						value = 400,
						condition = 35,
						isEventAcquired = true,
					})
				end,
			},
			{
				text = "A decent reliable car",
				effects = { Happiness = 8, Money = -3000 },
				setFlags = { has_car = true, has_vehicle = true },
				feedText = "A solid first car!",
				onResolve = function(state)
					local EventEngine = require(script.Parent).EventEngine
					EventEngine.addAsset(state, "vehicle", {
						id = "reliable_car_" .. tostring(state.Age),
						name = "Reliable Used Car",
						emoji = "🚗",
						price = 3000,
						value = 2500,
						condition = 65,
						isEventAcquired = true,
					})
				end,
			},
			{
				text = "A gift from family",
				effects = { Happiness = 10 },
				setFlags = { has_car = true, has_vehicle = true },
				feedText = "Your family helped you get a car!",
				onResolve = function(state)
					local EventEngine = require(script.Parent).EventEngine
					EventEngine.addAsset(state, "vehicle", {
						id = "gift_car_" .. tostring(state.Age),
						name = "Family Gift Car",
						emoji = "🚗",
						price = 0,
						value = 5000,
						condition = 70,
						isEventAcquired = true,
					})
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
		title = "College Graduation",
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
		category = "education",
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
		title = "Starting Your Career",
		emoji = "💼",
		text = "You got your first real, full-time job!",
		question = "How do you feel about starting?",
		minAge = 18, maxAge = 28,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		-- META
		stage = "adult",
		ageBand = "young_adult",
		category = "career",
		milestoneKey = "FIRST_REAL_JOB",
		tags = { "job", "career_start", "money" },
		careerTags = { "career_general" },

		choices = {
			{ text = "Excited and motivated", effects = { Happiness = 10, Money = 500 }, setFlags = { employed = true }, feedText = "Your career begins!" },
			{ text = "Nervous but ready", effects = { Happiness = 5, Smarts = 2, Money = 500 }, setFlags = { employed = true }, feedText = "First day jitters, but you've got this." },
			{ text = "It's just a paycheck", effects = { Money = 500 }, setFlags = { employed = true }, feedText = "Work to live, not live to work." },
		},
	},
	{
		id = "major_promotion",
		title = "Big Promotion",
		emoji = "📈",
		text = "After years of dedication, hard work, and consistently exceeding expectations, you've been promoted to a senior position! This is a major career milestone.",
		question = "How do you handle the new responsibility?",
		minAge = 28, maxAge = 55,
		baseChance = 0.3,
		cooldown = 5,
		requiresJob = true,
		priority = "high",
		isMilestone = true,
		-- Only trigger if player has earned it through hard work
		customValidation = function(state)
			if not state.CareerInfo then return false end
			local promotionProgress = state.CareerInfo.promotionProgress or 0
			local performance = state.CareerInfo.performance or 0
			local yearsAtJob = state.CareerInfo.yearsAtJob or 0
			-- Must have worked very hard: max promotion progress AND excellent performance AND significant time at job
			return promotionProgress >= 90 and performance >= 75 and yearsAtJob >= 2
		end,

		-- META
		stage = "adult",
		ageBand = "adult_midlife",
		category = "career",
		milestoneKey = "MAJOR_PROMOTION",
		tags = { "job", "promotion", "senior_role" },
		careerTags = { "management" },

		choices = {
			{ 
				text = "Step up and lead", 
				effects = { Happiness = 12, Money = 2000, Smarts = 3 }, 
				setFlags = { senior_role = true }, 
				feedText = "You rose to the challenge! Your years of preparation made you ready for this.",
				onResolve = function(state)
					if state.CurrentJob then
						local oldSalary = state.CurrentJob.salary or 30000
						state.CurrentJob.salary = math.floor(oldSalary * 1.4)
						state.CurrentJob.name = "Senior " .. (state.CurrentJob.name or "Manager")
					end
					if state.CareerInfo then
						state.CareerInfo.promotionProgress = 0
						state.CareerInfo.performance = math.min(100, (state.CareerInfo.performance or 60) + 15)
					end
				end,
			},
			{ 
				text = "Grow into it gradually", 
				effects = { Happiness = 8, Money = 1500, Smarts = 2 }, 
				setFlags = { senior_role = true }, 
				feedText = "You're adjusting to the new role. It's a learning curve, but you're getting there.",
				onResolve = function(state)
					if state.CurrentJob then
						local oldSalary = state.CurrentJob.salary or 30000
						state.CurrentJob.salary = math.floor(oldSalary * 1.3)
						state.CurrentJob.name = "Senior " .. (state.CurrentJob.name or "Manager")
					end
					if state.CareerInfo then
						state.CareerInfo.promotionProgress = 0
						state.CareerInfo.performance = math.min(100, (state.CareerInfo.performance or 60) + 10)
					end
				end,
			},
			{ 
				text = "Struggle with impostor syndrome", 
				effects = { Happiness = 5, Money = 1500, Smarts = 3 }, 
				setFlags = { senior_role = true }, 
				feedText = "You question if you deserve it. But you do - your hard work earned this.",
				onResolve = function(state)
					if state.CurrentJob then
						local oldSalary = state.CurrentJob.salary or 30000
						state.CurrentJob.salary = math.floor(oldSalary * 1.3)
						state.CurrentJob.name = "Senior " .. (state.CurrentJob.name or "Manager")
					end
					if state.CareerInfo then
						state.CareerInfo.promotionProgress = 0
						state.CareerInfo.performance = math.min(100, (state.CareerInfo.performance or 60) + 8)
					end
				end,
			},
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

		choices = {
			{ text = "Grateful for the journey", effects = { Happiness = 15 }, setFlags = { retired = true }, feedText = "A career well spent. Time to relax!" },
			{ text = "Ready for the next adventure", effects = { Happiness = 12 }, setFlags = { retired = true, active_retiree = true }, feedText = "Retirement is just a new beginning!" },
			{ text = "A bit sad to leave", effects = { Happiness = 8 }, setFlags = { retired = true }, feedText = "You'll miss the workplace, but it's time." },
			{ text = "Relieved!", effects = { Happiness = 10, Health = 5 }, setFlags = { retired = true }, feedText = "Finally free!" },
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
			{ text = "Buy a sports car", effects = { Happiness = 8, Money = -5000 }, setFlags = { midlife_crisis = true }, feedText = "Midlife crisis? Or just having fun?" },
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

return Milestones
