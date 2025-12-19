--[[
    Adult Events (Ages 18+)
    Career, family, major life decisions

    Integrated with:
    - core milestones via `isMilestone` + milestoneKey
    - career catalog via `hintCareer` + event-level careerTags
    - tagging via `stage`, `ageBand`, `category`, `tags`
]]

local Adult = {}

local STAGE = "adult"

Adult.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- YOUNG ADULT (18-29)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "moving_out",
		title = "Time to Leave the Nest",
		emoji = "🏠",
		text = "You're considering moving out of your parents' house.",
		question = "What's your plan?",
		minAge = 18, maxAge = 24,
		oneTime = true,
		-- CRITICAL FIX: Can't move out from prison!
		blockedByFlags = { in_prison = true, incarcerated = true },

		-- META
		stage = STAGE,
		ageBand = "young_adult",
		category = "housing",
		milestoneKey = "ADULT_MOVING_OUT",
		tags = { "independence", "family", "money" },

		choices = {
			{
				text = "Get my own apartment",
				effects = { Happiness = 10, Money = -500 },
				setFlags = { lives_alone = true, independent = true },
				feedText = "You got your own place! Freedom!"
			},
			{
				text = "Find roommates",
				effects = { Happiness = 5, Money = -200 },
				setFlags = { has_roommates = true },
				feedText = "You moved in with roommates. Cheaper but... interesting."
			},
			{
				text = "Stay home to save money",
				effects = { Money = 300, Happiness = -3 },
				setFlags = { lives_with_parents = true },
				feedText = "You're staying home. Smart financially."
			},
		},
	},

	{
		id = "college_experience",
		title = "College Life",
		emoji = "📚",
		text = "College is a whole new world of experiences.",
		question = "What's your focus?",
		minAge = 18, maxAge = 22,
		baseChance = 0.7, -- CRITICAL FIX #700: High chance for college events
		-- CRITICAL FIX #516: Accept MULTIPLE flags for college eligibility
		-- Was only checking college_bound but user could have in_college, enrolled_college, etc.
		eligibility = function(state)
			if not state.Flags then return false end
			return state.Flags.college_bound or state.Flags.in_college or 
			       state.Flags.enrolled_college or state.Flags.college_student or
			       (state.EducationData and state.EducationData.Status == "enrolled")
		end,
		cooldown = 1, -- CRITICAL FIX #701: Reduced cooldown for more variety

		-- META
		stage = STAGE,
		ageBand = "young_adult",
		category = "education",
		milestoneKey = "ADULT_COLLEGE_EXPERIENCE",
		tags = { "college", "lifestyle" },
		careerTags = { "business" },

		-- CRITICAL FIX #517: Ensure player is enrolled in college when this fires
		onComplete = function(state)
			state.EducationData = state.EducationData or {}
			state.EducationData.Status = "enrolled"
			state.EducationData.Institution = state.EducationData.Institution or "University"
			state.EducationData.Level = state.EducationData.Level or "bachelor"
			state.EducationData.Duration = state.EducationData.Duration or 4
			state.EducationData.Progress = state.EducationData.Progress or 0

			state.Flags = state.Flags or {}
			state.Flags.in_college = true
			state.Flags.college_student = true
			state.Flags.enrolled_college = true
		end,

		choices = {
			{
				text = "Study hard, get great grades",
				effects = { Smarts = 7, Happiness = -2, Health = -2 },
				setFlags = { honors_student = true, in_college = true, college_student = true },
				feedText = "You're crushing it academically!",
			},
			{
				text = "Balance academics and social life",
				effects = { Smarts = 4, Happiness = 5 },
				setFlags = { in_college = true, college_student = true },
				feedText = "You're getting the full college experience.",
			},
			{
				text = "Party now, study later",
				effects = { Happiness = 8, Smarts = -2, Health = -3 },
				setFlags = { party_animal = true, in_college = true },
				feedText = "College is about the experience, right?",
			},
			{
				text = "Focus on networking and internships",
				effects = { Smarts = 3, Money = 100 },
				setFlags = { career_focused = true, in_college = true },
				hintCareer = "business",
				feedText = "You're building your professional network early.",
			},
		},
	},

	{
		id = "major_choice",
		title = "Declaring Your Major",
		emoji = "📋",
		text = "It's time to officially declare your major.",
		question = "What will you study?",
		minAge = 19, maxAge = 21,
		baseChance = 0.8, -- CRITICAL FIX #702: High chance for milestone
		oneTime = true,
		-- CRITICAL FIX #703: Accept multiple college flags
		eligibility = function(state)
			local flags = state.Flags or {}
			return flags.college_bound or flags.in_college or flags.college_student
		end,

		-- META
		stage = STAGE,
		ageBand = "young_adult",
		category = "education",
		milestoneKey = "ADULT_MAJOR_CHOICE",
		tags = { "college", "career_setup" },
		careerTags = { "tech", "finance", "medical", "law", "creative", "education" },

		choices = {
			{
				text = "STEM (Science/Tech/Engineering/Math)",
				effects = { Smarts = 5 },
				setFlags = { stem_major = true },
				hintCareer = "tech",
				feedText = "You're majoring in STEM. Challenging but rewarding."
			},
			{
				text = "Business/Finance",
				effects = { Smarts = 3, Money = 50 },
				setFlags = { business_major = true },
				hintCareer = "finance",
				feedText = "You're studying business. Follow the money!"
			},
			{
				text = "Pre-Med/Health Sciences",
				effects = { Smarts = 7, Health = -2 },
				setFlags = { premed = true },
				hintCareer = "medical",
				feedText = "You're on the pre-med track. Intense!"
			},
			{
				text = "Pre-Law",
				effects = { Smarts = 5 },
				setFlags = { prelaw = true },
				hintCareer = "law",
				feedText = "You're preparing for law school."
			},
			{
				text = "Arts/Humanities",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { arts_major = true },
				hintCareer = "creative",
				feedText = "You're following your creative passions."
			},
			{
				text = "Education",
				effects = { Smarts = 3, Happiness = 3 },
				setFlags = { education_major = true },
				hintCareer = "education",
				feedText = "You want to shape young minds."
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ADULT LIFE (30+)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "buying_home",
		title = "Buying a Home",
		emoji = "🏡",
		text = "You're considering buying your first home.",
		question = "What's your approach?",
		minAge = 25, maxAge = 50,
		oneTime = true,
		-- CRITICAL FIX #2: Don't show home buying if you have no money OR already own a home!
		blockedByFlags = { homeowner = true, has_property = true, in_prison = true },
		eligibility = function(state)
			-- Need at least $5000 for cheapest option down payment
			local money = state.Money or 0
			if money < 5000 then
				return false, "Not enough money for a down payment"
			end
			-- Can't already own property
			local flags = state.Flags or {}
			if flags.homeowner or flags.has_property then
				return false, "Already owns a home"
			end
			return true
		end,

		-- META
		stage = STAGE,
		ageBand = "adult_midlife",
		category = "housing",
		milestoneKey = "ADULT_BUYING_HOME",
		tags = { "property", "money_big", "stability" },

		choices = {
			{
				-- CRITICAL FIX: Show price in choice text!
				text = "Buy a starter home ($85,000 - $5,000 down)",
				effects = { Happiness = 10, Money = -5000 },
				setFlags = { homeowner = true, has_property = true },
				feedText = "You bought your first home! A big milestone!",
				-- CRITICAL FIX: Check if player can afford down payment
				eligibility = function(state)
					local money = state.Money or 0
					if money < 5000 then
						return false, "Can't afford the $5,000 down payment"
					end
					return true
				end,
				onResolve = function(state)
					-- Use LifeState:AddAsset method directly (if available)
					if state.AddAsset then
						state:AddAsset("Properties", {
							id = "starter_home_" .. tostring(state.Age or 0),
							name = "Starter Home",
							emoji = "🏠",
							price = 85000,
							value = 85000,
							income = 0,
							isEventAcquired = true,
						})
					end
				end,
			},
			{
				-- CRITICAL FIX: Show price in choice text!
				text = "Stretch for your dream home ($350,000 - $15,000 down)",
				effects = { Happiness = 15, Money = -15000, Health = -3 },
				setFlags = { homeowner = true, has_property = true, high_mortgage = true },
				feedText = "You got your dream home! But the mortgage is steep.",
				-- CRITICAL FIX: Check if player can afford down payment
				eligibility = function(state)
					local money = state.Money or 0
					if money < 15000 then
						return false, "Can't afford the $15,000 down payment"
					end
					return true
				end,
				onResolve = function(state)
					if state.AddAsset then
						state:AddAsset("Properties", {
							id = "dream_home_" .. tostring(state.Age or 0),
							name = "Dream Home",
							emoji = "🏡",
							price = 350000,
							value = 350000,
							income = 0,
							isEventAcquired = true,
						})
					end
				end,
			},
			{
				text = "Keep renting for now (Free)",
				effects = { Money = 500 },
				feedText = "You'll rent a bit longer. More flexibility.",
			},
			{
				-- CRITICAL FIX: Show price in choice text!
				text = "Move to a cheaper area ($65,000 - $3,000 down)",
				effects = { Happiness = 5, Money = -3000 },
				setFlags = { homeowner = true, has_property = true, relocated = true },
				feedText = "You moved somewhere more affordable!",
				-- CRITICAL FIX: Check if player can afford down payment
				eligibility = function(state)
					local money = state.Money or 0
					if money < 3000 then
						return false, "Can't afford the $3,000 down payment"
					end
					return true
				end,
				onResolve = function(state)
					if state.AddAsset then
						state:AddAsset("Properties", {
							id = "affordable_home_" .. tostring(state.Age or 0),
							name = "Affordable Home",
							emoji = "🏠",
							price = 65000,
							value = 65000,
							income = 0,
							isEventAcquired = true,
						})
					end
				end,
			},
		},
	},

	{
		id = "midlife_health",
		title = "Health Wake-Up Call",
		emoji = "🏥",
		text = "A routine checkup reveals you need to pay more attention to your health.",
		question = "How do you respond?",
		minAge = 35, maxAge = 50,
		baseChance = 0.4,
		cooldown = 5,

		-- META
		stage = STAGE,
		ageBand = "adult_midlife",
		category = "health",
		tags = { "doctor", "lifestyle", "midlife" },

		choices = {
			{
				text = "Complete lifestyle overhaul",
				effects = { Health = 15, Happiness = 5, Money = -500 },
				setFlags = { health_conscious = true },
				feedText = "You transformed your lifestyle. Feeling great!"
			},
			{
				text = "Make gradual improvements",
				effects = { Health = 8, Happiness = 3 },
				feedText = "You're making steady health improvements."
			},
			{
				text = "Ignore it and hope for the best",
				effects = { Health = -10, Happiness = -5 },
				feedText = "You ignored the warning signs..."
			},
			{
				text = "Become obsessive about health",
				effects = { Health = 10, Happiness = -5, Money = -1000 },
				setFlags = { health_obsessed = true },
				feedText = "Health became your entire focus. Maybe too much."
			},
		},
	},

	{
		id = "retirement_planning",
		title = "Thinking About Retirement",
		emoji = "📊",
		text = "A financial advisor reviews your retirement readiness.",
		question = "How does the assessment go?",
		minAge = 50, maxAge = 62,
		oneTime = true,

		-- META
		stage = STAGE,
		ageBand = "pre_senior",
		category = "money",
		milestoneKey = "ADULT_RETIREMENT_PLANNING",
		tags = { "retirement", "money_long_term" },
		-- CRITICAL FIX: Retirement readiness based on life choices, not direct selection
		choices = {
			{
				text = "Get a full retirement assessment",
				effects = { Money = -200 },
				feedText = "The advisor runs the numbers...",
				onResolve = function(state)
					-- Base readiness on accumulated wealth and smart decisions
					local money = state.Money or 0
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local hasSaved = state.Flags and (state.Flags.saver or state.Flags.investor or state.Flags.retirement_saver)
					local hasDebt = state.Flags and state.Flags.bad_credit
					
					local score = 0
					if money > 50000 then score = score + 3 end
					if money > 20000 then score = score + 2 end
					if money > 5000 then score = score + 1 end
					if smarts > 60 then score = score + 1 end
					if hasSaved then score = score + 2 end
					if hasDebt then score = score - 2 end
					
					if score >= 6 then
						state:ModifyStat("Happiness", 10)
						state.Money = (state.Money or 0) + 5000
						state.Flags = state.Flags or {}
						state.Flags.retirement_ready = true
						state:AddFeed("📊 Great news! You're well prepared for retirement!")
					elseif score >= 3 then
						state:ModifyStat("Happiness", 5)
						state.Money = (state.Money or 0) + 1000
						state.Flags = state.Flags or {}
						state.Flags.retirement_possible = true
						state:AddFeed("📊 Moderately prepared. You'll be okay, but not lavish.")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.must_keep_working = true
						state:AddFeed("📊 Not looking good... you'll need to work longer.")
					end
				end,
			},
			{
				text = "I'll figure it out myself",
				effects = {},
				feedText = "You decide to wing it...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.retirement_possible = true
						state:AddFeed("📊 You think you'll be fine. Probably.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📊 The uncertainty about retirement weighs on you.")
					end
				end,
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- SENIOR YEARS (65+)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "stage_transition_senior",
		title = "Golden Years Begin",
		emoji = "🌅",
		text = "You've reached 65! The senior years begin.",
		question = "How do you approach this new phase?",
		minAge = 65, maxAge = 65,
		oneTime = true,
		priority = "high",
		isMilestone = true,

		-- META
		stage = STAGE,
		ageBand = "senior",
		category = "life_stage",
		milestoneKey = "SENIOR_STAGE_START",
		tags = { "core", "retirement", "aging" },

		choices = {
			{
				text = "Embrace retirement fully",
				effects = { Happiness = 10 },
				setFlags = { retired = true },
				feedText = "Retirement is here! Time to relax. Your pension awaits.",
				-- Clear job and set up pension when fully retiring
				onResolve = function(state)
					-- Calculate pension based on career history
					local pensionBase = 0
					if state.CurrentJob and state.CurrentJob.salary then
						pensionBase = math.floor(state.CurrentJob.salary * 0.4)
					end
					
					state.Flags = state.Flags or {}
					state.Flags.pension_amount = pensionBase
					
					-- Store last job before clearing
					if state.CurrentJob then
						state.CareerInfo = state.CareerInfo or {}
						state.CareerInfo.lastJob = state.CurrentJob
						state.CareerInfo.retirementAge = state.Age
					end
					
					-- Clear the job
					if state.ClearCareer then
						state:ClearCareer()
					else
						state.CurrentJob = nil
						state.Flags.employed = nil
						state.Flags.has_job = nil
					end
				end,
			},
			{
				text = "Keep working part-time",
				effects = { Happiness = 5, Money = 500 },
				setFlags = { semi_retired = true },
				feedText = "You're staying active in the workforce.",
				-- Semi-retired: reduce salary but keep job
				onResolve = function(state)
					if state.CurrentJob and state.CurrentJob.salary then
						state.CurrentJob.salary = math.floor(state.CurrentJob.salary * 0.5)
					end
				end,
			},
			{
				text = "Focus on hobbies and travel",
				effects = { Happiness = 12, Money = -1000 },
				setFlags = { retired = true },
				feedText = "Time to enjoy life to the fullest! Your pension awaits.",
				-- Retire and travel
				onResolve = function(state)
					local pensionBase = 0
					if state.CurrentJob and state.CurrentJob.salary then
						pensionBase = math.floor(state.CurrentJob.salary * 0.4)
					end
					
					state.Flags = state.Flags or {}
					state.Flags.pension_amount = pensionBase
					
					if state.CurrentJob then
						state.CareerInfo = state.CareerInfo or {}
						state.CareerInfo.lastJob = state.CurrentJob
						state.CareerInfo.retirementAge = state.Age
					end
					
					if state.ClearCareer then
						state:ClearCareer()
					else
						state.CurrentJob = nil
						state.Flags.employed = nil
						state.Flags.has_job = nil
					end
				end,
			},
			{
				text = "Dedicate time to family",
				effects = { Happiness = 8 },
				setFlags = { retired = true },
				feedText = "Family becomes your focus. Your pension awaits.",
				-- Retire for family
				onResolve = function(state)
					local pensionBase = 0
					if state.CurrentJob and state.CurrentJob.salary then
						pensionBase = math.floor(state.CurrentJob.salary * 0.4)
					end
					
					state.Flags = state.Flags or {}
					state.Flags.pension_amount = pensionBase
					
					if state.CurrentJob then
						state.CareerInfo = state.CareerInfo or {}
						state.CareerInfo.lastJob = state.CurrentJob
						state.CareerInfo.retirementAge = state.Age
					end
					
					if state.ClearCareer then
						state:ClearCareer()
					else
						state.CurrentJob = nil
						state.Flags.employed = nil
						state.Flags.has_job = nil
					end
				end,
			},
		},
	},

	{
		id = "legacy_reflection",
		title = "Reflecting on Legacy",
		emoji = "📖",
		text = "You're thinking about the legacy you'll leave behind.",
		question = "What matters most to you?",
		minAge = 60, maxAge = 80,
		oneTime = true,

		-- META
		stage = STAGE,
		ageBand = "senior",
		category = "identity",
		milestoneKey = "SENIOR_LEGACY_REFLECTION",
		tags = { "legacy", "meaning", "endgame" },

		choices = {
			{
				text = "Family and relationships",
				effects = { Happiness = 10 },
				setFlags = { family_legacy = true },
				feedText = "Your greatest legacy is the people you love."
			},
			{
				text = "Career achievements",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { professional_legacy = true },
				feedText = "You're proud of what you accomplished."
			},
			{
				text = "Helping others",
				effects = { Happiness = 12 },
				setFlags = { charitable_legacy = true },
				feedText = "Making a difference was your calling."
			},
			{
				text = "Still building my legacy",
				effects = { Happiness = 5 },
				feedText = "You're not done yet!"
			},
		},
	},

	{
		id = "health_challenge_senior",
		title = "Health Challenges",
		emoji = "🏥",
		text = "Age brings some health challenges that need attention.",
		question = "How do you handle them?",
		minAge = 65, maxAge = 90,
		baseChance = 0.5,
		cooldown = 3,

		-- META
		stage = STAGE,
		ageBand = "senior",
		category = "health",
		tags = { "aging", "doctor", "health_risk" },

		choices = {
			{
				text = "Follow doctor's orders carefully",
				effects = { Health = 5, Money = -500 },
				feedText = "You're taking good care of yourself."
			},
			{
				text = "Stay as active as possible",
				effects = { Health = 8, Happiness = 5 },
				feedText = "Movement is medicine!"
			},
			{
				text = "Accept limitations gracefully",
				effects = { Happiness = 3, Smarts = 2 },
				feedText = "You're adapting with wisdom."
			},
			{
				text = "Fight against aging stubbornly",
				effects = { Happiness = 2, Health = 3 },
				feedText = "You refuse to slow down!"
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ADDITIONAL ADULT EVENTS - AAA QUALITY EXPANSION
	-- ══════════════════════════════════════════════════════════════════════════════

	-- YOUNG ADULT EXPANSION (18-29)
	{
		id = "first_apartment_problems",
		title = "Apartment Problems",
		emoji = "🏚️",
		text = "Your first apartment has some... issues.",
		question = "What's the biggest problem?",
		minAge = 18, maxAge = 26,
		baseChance = 0.5,
		cooldown = 2,
		requiresFlags = { lives_alone = true },

		choices = {
			{ text = "Noisy neighbors keep you up", effects = { Health = -3, Happiness = -4 }, feedText = "Sleep deprivation is real. These walls are paper thin." },
			{ text = "Pests - roaches or mice!", effects = { Happiness = -6, Health = -2, Money = -100 }, feedText = "You spent money on pest control. Gross." },
			{ text = "Landlord won't fix anything", effects = { Happiness = -4, Money = -200 }, setFlags = { bad_landlord = true }, feedText = "You had to pay for repairs yourself." },
			{ text = "Actually, it's not so bad", effects = { Happiness = 3 }, feedText = "You lucked out with a decent place!" },
		},
	},
	{
		id = "roommate_drama",
		title = "Roommate Drama",
		emoji = "😤",
		text = "Living with roommates is causing friction.",
		question = "What's the issue?",
		minAge = 18, maxAge = 28,
		baseChance = 0.4,
		cooldown = 2,
		requiresFlags = { has_roommates = true },
		-- CRITICAL FIX: Can't have roommate drama from prison!
		blockedByFlags = { in_prison = true, incarcerated = true },

		choices = {
			{ text = "They never clean", effects = { Happiness = -4, Health = -2 }, feedText = "Living in filth because they won't do dishes." },
			{ text = "They eat my food", effects = { Happiness = -3, Money = -50 }, feedText = "Your groceries keep disappearing." },
			{ text = "They're too loud", effects = { Happiness = -3, Health = -2 }, setFlags = { poor_sleep = true }, feedText = "Parties every night. You're exhausted." },
			{ text = "We're actually great friends!", effects = { Happiness = 6 }, setFlags = { good_roommates = true }, feedText = "Living together strengthened your friendship!" },
			{ text = "Time to move out", effects = { Money = -300, Happiness = 3 }, setFlags = { lives_alone = true }, feedText = "You got your own place. Peace at last." },
		},
	},
	{
		id = "quarter_life_crisis",
		title = "Quarter-Life Crisis",
		emoji = "😰",
		text = "You're in your mid-20s and questioning everything.",
		question = "What's bothering you most?",
		minAge = 23, maxAge = 28,
		oneTime = true,
		-- CRITICAL FIX: Different crisis priorities in prison
		blockedByFlags = { in_prison = true, incarcerated = true },

		choices = {
			{ text = "I don't know what I want to do with my life", effects = { Happiness = -5, Smarts = 3 }, setFlags = { searching_purpose = true }, feedText = "You're soul-searching. It's uncomfortable but necessary." },
			{ text = "I'm falling behind my peers", effects = { Happiness = -6 }, setFlags = { comparison_anxiety = true }, feedText = "Social media makes everyone seem more successful." },
			{ text = "I'm not where I thought I'd be", effects = { Happiness = -4 }, feedText = "Life didn't follow the plan you imagined." },
			{ text = "Actually, I'm pretty content", effects = { Happiness = 8 }, setFlags = { self_assured = true }, feedText = "You're at peace with where you are!" },
		},
	},
	{
		-- CRITICAL FIX: Renamed from first_real_job to avoid ID conflict with Milestones.lua
		-- This event is about adjusting to work life, not getting your first job
		id = "work_life_adjustment",
		title = "Adjusting to Work Life",
		emoji = "💼",
		text = "You've been at your job for a while now. The 9-5 grind is real.",
		question = "How's the adjustment going?",
		minAge = 19, maxAge = 28,
		oneTime = true,
		-- CRITICAL: Requires player to actually HAVE a job
		requiresJob = true,
		requiresFlags = { employed = true },

		choices = {
			{ text = "Imposter syndrome is real", effects = { Happiness = -3, Smarts = 4 }, setFlags = { imposter_syndrome = true }, feedText = "You feel like a fraud, but you're learning fast." },
			{ text = "I love it - finally in my field", effects = { Happiness = 8, Money = 500 }, setFlags = { career_launch = true }, feedText = "This is what you worked so hard for!" },
			{ text = "It's nothing like I expected", effects = { Happiness = -2 }, feedText = "The reality of work life is setting in." },
			{ text = "Already want to quit", effects = { Happiness = -5 }, setFlags = { job_dissatisfied = true }, feedText = "Is this really going to be your life?" },
		},
	},
	{
		id = "student_loan_reality",
		title = "Student Loan Reality",
		emoji = "💸",
		text = "The student loan payments have started.",
		question = "How are you handling the debt?",
		minAge = 22, maxAge = 30,
		baseChance = 0.5,
		cooldown = 3,
		requiresFlags = { has_degree = true },

		choices = {
			{ text = "Paying minimum - will take forever", effects = { Money = -200, Happiness = -3 }, feedText = "You'll be paying this for decades." },
			{ text = "Aggressively paying them down", effects = { Money = -600, Happiness = -2, Smarts = 2 }, setFlags = { debt_focused = true }, feedText = "Living frugally to eliminate the debt faster." },
			{ text = "Looking into loan forgiveness", effects = { Smarts = 2 }, setFlags = { public_service = true }, feedText = "Maybe public service can help." },
			{ text = "Defaulted... oops", effects = { Money = -1000, Happiness = -8 }, setFlags = { bad_credit = true }, feedText = "Your credit is destroyed. Big mistake." },
		},
	},
	{
		id = "dating_apps",
		title = "The Dating App Life",
		emoji = "📱",
		text = "You've entered the world of dating apps.",
		question = "How's your experience?",
		minAge = 20, maxAge = 40,
		baseChance = 0.5,
		cooldown = 2,
		requiresSingle = true,
		blockedByFlags = { married = true, in_prison = true, incarcerated = true },

		choices = {
			{ text = "Tons of matches, no connections", effects = { Happiness = -3 }, feedText = "Quantity over quality. Modern dating is exhausting." },
			{ 
				text = "Found someone amazing!", 
				effects = { Happiness = 10 }, 
				setFlags = { has_partner = true, met_online = true, dating = true }, 
				feedText = "Swipe right turned into real love!",
				-- CRITICAL FIX: Actually create the partner object!
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local isMale = math.random() > 0.5
					local names = isMale 
						and {"Mike", "Chris", "Jason", "Brian", "Matt", "Steve", "Dave", "Tom", "Nick", "Ben"}
						or {"Jessica", "Ashley", "Sarah", "Emily", "Lauren", "Amanda", "Megan", "Nicole", "Brittany", "Rachel"}
					local partnerName = names[math.random(1, #names)]
					state.Relationships.partner = {
						id = "partner",
						name = partnerName,
						type = "romantic",
						role = isMale and "Boyfriend" or "Girlfriend",
						relationship = 70,
						age = (state.Age or 25) + math.random(-5, 5),
						gender = isMale and "male" or "female",
						alive = true,
						metThrough = "dating_app",
					}
					if state.AddFeed then
						state:AddFeed(string.format("📱 Swipe right on %s turned into real love!", partnerName))
					end
				end,
			},
			{ text = "Catfished and disappointed", effects = { Happiness = -6 }, setFlags = { burned_by_dating = true }, feedText = "That profile was definitely not them." },
			{ text = "Prefer meeting people in person", effects = { Happiness = 2 }, setFlags = { traditional_dating = true }, feedText = "You deleted the apps. Old school it is." },
		},
	},
	{
		id = "wedding_planning",
		title = "Wedding Planning",
		emoji = "💒",
		-- CRITICAL FIX #19: Text variations for wedding planning milestone!
		textVariants = {
			"You're engaged and planning a wedding!",
			"Wedding bells are ringing! Time to plan the big day!",
			"The engagement was magical. Now comes the real work - wedding planning!",
			"Pinterest boards are filling up. Wedding venues are being toured. It's happening!",
			"The date is set, the guest list is growing. Your wedding approaches!",
			"Everyone keeps asking about 'the wedding'. Time to actually plan it!",
		},
		text = "You're engaged and planning a wedding!",
		question = "What kind of wedding?",
		minAge = 22, maxAge = 45,
		oneTime = true,
		requiresFlags = { engaged = true },
		blockedByFlags = { in_prison = true, incarcerated = true },
		-- CRITICAL FIX: Need at least courthouse money
		eligibility = function(state)
			local money = state.Money or 0
			if money < 100 then
				return false, "Can't even afford a courthouse wedding"
			end
			return true
		end,

		choices = {
			{ 
				text = "Big traditional wedding", 
				-- CRITICAL FIX: Validate money before expensive wedding
				effects = {}, -- Money handled in onResolve
				setFlags = { married = true, big_wedding = true }, 
				feedText = "Planning the wedding of your dreams...",
				onResolve = function(state)
					local money = state.Money or 0
					local weddingCost = 15000
					if money >= weddingCost then
						state.Money = money - weddingCost
						if state.ModifyStat then state:ModifyStat("Happiness", 12) end
						-- Update partner role to spouse
						if state.Relationships and state.Relationships.partner then
							local partnerGender = state.Relationships.partner.gender or "female"
							state.Relationships.partner.role = (partnerGender == "female") and "Wife" or "Husband"
						end
						if state.AddFeed then
							state:AddFeed("💒 A beautiful $15,000 wedding! Your wallet hurts but it was worth it!")
						end
					elseif money >= 8000 then
						state.Money = money - 8000
						if state.ModifyStat then state:ModifyStat("Happiness", 10) end
						if state.Relationships and state.Relationships.partner then
							local partnerGender = state.Relationships.partner.gender or "female"
							state.Relationships.partner.role = (partnerGender == "female") and "Wife" or "Husband"
						end
						if state.AddFeed then
							state:AddFeed("💒 Nice wedding for $8,000! Cut some corners but still beautiful!")
						end
					else
						-- Default to small wedding
						state.Money = math.max(0, money - 3000)
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						if state.Relationships and state.Relationships.partner then
							local partnerGender = state.Relationships.partner.gender or "female"
							state.Relationships.partner.role = (partnerGender == "female") and "Wife" or "Husband"
						end
						if state.AddFeed then
							state:AddFeed("💒 Had a smaller wedding you could afford. Still special!")
						end
					end
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
				end,
			},
			{ 
				text = "Small intimate ceremony", 
				-- CRITICAL FIX: Validate money
				effects = {}, -- Money handled in onResolve
				setFlags = { married = true }, 
				feedText = "Planning an intimate ceremony...",
				onResolve = function(state)
					local money = state.Money or 0
					local weddingCost = 3000
					if money >= weddingCost then
						state.Money = money - weddingCost
						if state.ModifyStat then state:ModifyStat("Happiness", 10) end
					else
						state.Money = math.max(0, money - 500)
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
					end
					if state.Relationships and state.Relationships.partner then
						local partnerGender = state.Relationships.partner.gender or "female"
						state.Relationships.partner.role = (partnerGender == "female") and "Wife" or "Husband"
					end
					if state.AddFeed then
						state:AddFeed("💒 Just close friends and family. Perfect!")
					end
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
				end,
			},
			{ 
				text = "Destination wedding", 
				-- CRITICAL FIX: Validate money
				effects = {}, -- Money handled in onResolve
				setFlags = { married = true, destination_wedding = true }, 
				feedText = "Planning a destination wedding...",
				onResolve = function(state)
					local money = state.Money or 0
					local weddingCost = 10000
					if money >= weddingCost then
						state.Money = money - weddingCost
						if state.ModifyStat then 
							state:ModifyStat("Happiness", 14)
							state:ModifyStat("Health", 3)
						end
						if state.AddFeed then
							state:AddFeed("🏝️ Getting married on a beach was magical!")
						end
					elseif money >= 5000 then
						state.Money = money - 5000
						if state.ModifyStat then 
							state:ModifyStat("Happiness", 10)
							state:ModifyStat("Health", 2)
						end
						if state.AddFeed then
							state:AddFeed("🏝️ Budget destination wedding! Still beautiful!")
						end
					else
						-- Can't afford destination
						state.Money = math.max(0, money - 2000)
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						if state.AddFeed then
							state:AddFeed("💒 Destination too expensive. Had a local wedding instead.")
						end
					end
					if state.Relationships and state.Relationships.partner then
						local partnerGender = state.Relationships.partner.gender or "female"
						state.Relationships.partner.role = (partnerGender == "female") and "Wife" or "Husband"
					end
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
				end,
			},
			{ 
				text = "Courthouse and save the money", 
				effects = { Happiness = 5, Money = -100 }, 
				setFlags = { married = true, practical_wedding = true }, 
				feedText = "Quick and easy. More money for the honeymoon!",
				onResolve = function(state)
					if state.Relationships and state.Relationships.partner then
						local partnerGender = state.Relationships.partner.gender or "female"
						state.Relationships.partner.role = (partnerGender == "female") and "Wife" or "Husband"
					end
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
				end,
			},
			{ 
				text = "Called off the wedding", 
				-- CRITICAL FIX: Validate money for deposits lost
				effects = {}, -- Money handled in onResolve
				setFlags = { wedding_canceled = true }, 
				feedText = "Having second thoughts...",
				onResolve = function(state)
					local money = state.Money or 0
					-- Lost deposits based on what you could afford
					local depositLoss = math.min(2000, money * 0.3)
					state.Money = math.max(0, money - depositLoss)
					if state.ModifyStat then state:ModifyStat("Happiness", -15) end
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
					state.Flags.has_partner = nil
					state.Flags.dating = nil
					if state.Relationships then
						state.Relationships.partner = nil
					end
					if state.AddFeed then
						state:AddFeed("💔 Called off the wedding. Better now than after. Lost deposits...")
					end
				end,
			},
		},
	},
	{
		id = "having_kids_decision",
		title = "The Baby Question",
		emoji = "👶",
		text = "The topic of having children comes up.",
		question = "Where do you stand?",
		minAge = 25, maxAge = 40,
		oneTime = true,
		requiresFlags = { has_partner = true },

		choices = {
			{ text = "We want kids - trying now!", effects = { Happiness = 5 }, setFlags = { trying_for_baby = true }, feedText = "You're ready to start a family!" },
			{ text = "Maybe someday, not yet", effects = { Happiness = 3 }, setFlags = { kids_later = true }, feedText = "The timing isn't right yet." },
			{ text = "Definitely don't want kids", effects = { Happiness = 5 }, setFlags = { child_free = true }, feedText = "You're confident in your child-free choice." },
			{ text = "Partner and I disagree on this", effects = { Happiness = -10 }, setFlags = { relationship_strain = true }, feedText = "This fundamental disagreement is causing problems." },
		},
	},
	{
		id = "new_baby",
		title = "👶 Baby Arrives!",
		emoji = "🍼",
		text = "You have a new baby! Life will never be the same.",
		question = "How are you handling parenthood?",
		minAge = 20, maxAge = 45,
		oneTime = true,
		-- CRITICAL FIX #7: Added "birth" category for light blue event card
		category = "birth",
		requiresFlags = { trying_for_baby = true },

		choices = {
			{ 
				text = "It's exhausting but amazing", 
				effects = { Happiness = 10, Health = -5, Money = -1000 }, 
				setFlags = { has_child = true, parent = true }, 
				feedText = "Sleep is a distant memory but you're in love.",
				-- CRITICAL FIX: Create actual child in Relationships table
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local names = isBoy and {"James", "Oliver", "Ethan", "Noah", "Liam", "Mason", "Lucas"} 
						or {"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia", "Amelia"}
					local childName = names[math.random(1, #names)]
					local childId = "child_" .. tostring(childCount)
					state.Relationships[childId] = {
						id = childId,
						name = childName,
						type = "family",
						role = isBoy and "Son" or "Daughter",
						relationship = 100,
						age = 0,
						gender = isBoy and "male" or "female",
						alive = true,
						isFamily = true,
						isChild = true,
					}
				end,
			},
			{ 
				text = "Struggling with the transition", 
				effects = { Happiness = 2, Health = -8, Money = -1000 }, 
				setFlags = { has_child = true, parent = true, overwhelmed_parent = true }, 
				feedText = "This is harder than you imagined.",
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local names = isBoy and {"James", "Oliver", "Ethan", "Noah", "Liam", "Mason"} 
						or {"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia"}
					local childName = names[math.random(1, #names)]
					local childId = "child_" .. tostring(childCount)
					state.Relationships[childId] = {
						id = childId,
						name = childName,
						type = "family",
						role = isBoy and "Son" or "Daughter",
						relationship = 80,
						age = 0,
						gender = isBoy and "male" or "female",
						alive = true,
						isFamily = true,
						isChild = true,
					}
				end,
			},
			{ 
				text = "Natural parent - taking to it well", 
				effects = { Happiness = 15, Health = -3, Money = -1000 }, 
				setFlags = { has_child = true, parent = true, natural_parent = true }, 
				feedText = "You were born for this!",
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local names = isBoy and {"James", "Oliver", "Ethan", "Noah", "Liam", "Mason"} 
						or {"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia"}
					local childName = names[math.random(1, #names)]
					local childId = "child_" .. tostring(childCount)
					state.Relationships[childId] = {
						id = childId,
						name = childName,
						type = "family",
						role = isBoy and "Son" or "Daughter",
						relationship = 100,
						age = 0,
						gender = isBoy and "male" or "female",
						alive = true,
						isFamily = true,
						isChild = true,
					}
				end,
			},
			{ 
				text = "Partner is doing most of the work", 
				effects = { Happiness = 5, Money = -1000 }, 
				setFlags = { has_child = true, parent = true }, 
				feedText = "You're not pulling your weight...",
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local names = isBoy and {"James", "Oliver", "Ethan", "Noah", "Liam", "Mason"} 
						or {"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia"}
					local childName = names[math.random(1, #names)]
					local childId = "child_" .. tostring(childCount)
					state.Relationships[childId] = {
						id = childId,
						name = childName,
						type = "family",
						role = isBoy and "Son" or "Daughter",
						relationship = 90,
						age = 0,
						gender = isBoy and "male" or "female",
						alive = true,
						isFamily = true,
						isChild = true,
					}
				end,
			},
		},
	},

	-- CAREER ADVANCEMENT (25-50)
	-- CRITICAL FIX: Renamed from "career_crossroads" to avoid ID conflict with Career.lua
	{
		id = "career_crossroads_midlife",
		title = "Career Crossroads",
		emoji = "🔀",
		text = "You're at a crossroads in your career.",
		question = "What path do you take?",
		minAge = 28, maxAge = 45,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true, -- CRITICAL FIX: Only show for employed players!

		choices = {
			{ text = "Chase the promotion", effects = { Money = 1000, Happiness = -3, Health = -3 }, setFlags = { workaholic = true }, hintCareer = "management", feedText = "You're climbing the ladder. At what cost?" },
			{ text = "Start my own business", effects = { Money = -5000, Happiness = 5 }, setFlags = { entrepreneur = true }, hintCareer = "business", feedText = "You took the entrepreneurial leap!" },
			{ text = "Change careers entirely", effects = { Happiness = 8, Money = -1000, Smarts = 5 }, setFlags = { career_changer = true }, feedText = "A fresh start in a new field!" },
			{ text = "Focus on work-life balance", effects = { Happiness = 10, Health = 5, Money = -500 }, setFlags = { balanced_life = true }, feedText = "You prioritized quality of life." },
		},
	},
	-- CRITICAL FIX: Renamed from "workplace_conflict" to avoid ID conflict with Career.lua
	{
		id = "workplace_conflict_serious",
		title = "Workplace Conflict",
		emoji = "😠",
		text = "There's serious conflict with a coworker.",
		question = "How do you handle it?",
		minAge = 22, maxAge = 60,
		baseChance = 0.4,
		cooldown = 2,
		requiresJob = true, -- CRITICAL FIX: Only show for employed players!

		choices = {
			{ text = "Try to work it out professionally", effects = { Smarts = 3, Happiness = 2 }, feedText = "You handled it maturely. Conflict resolved." },
			{ text = "Take it to HR", effects = { Happiness = -2 }, setFlags = { hr_involved = true }, feedText = "HR is now involved. Things got formal." },
			{ text = "Confront them directly", effects = { Happiness = -4 }, setFlags = { confrontational = true }, feedText = "The confrontation didn't go well." },
			{ text = "Just avoid them", effects = { Happiness = -2 }, feedText = "The tension remains but you're coexisting." },
			{ text = "Quit over it", effects = { Money = -500, Happiness = 3 }, feedText = "Life's too short. You left for a new opportunity." },
		},
	},
	{
		id = "big_promotion",
		title = "The Big Promotion",
		emoji = "📈",
		text = "You've been offered a major promotion at {{COMPANY}}!",
		question = "What's the catch?",
		minAge = 28, maxAge = 55,
		baseChance = 0.3,
		cooldown = 4,
		requiresJob = true, -- CRITICAL FIX: Only show for employed players!

		choices = {
			{ 
				text = "Step up and lead!", 
				effects = { Happiness = 5, Health = -3 }, 
				setFlags = { senior_position = true, promoted = true }, 
				feedText = "You're moving up! The pressure is on.",
				-- CRITICAL FIX: Actually increase salary when promoted
				onResolve = function(state)
					if state.CurrentJob and state.CurrentJob.salary then
						local raiseAmount = math.floor(state.CurrentJob.salary * 0.25) -- 25% raise
						state.CurrentJob.salary = state.CurrentJob.salary + raiseAmount
						state.Money = (state.Money or 0) + 3000 -- Signing bonus
						state.CareerInfo = state.CareerInfo or {}
						state.CareerInfo.promotions = (state.CareerInfo.promotions or 0) + 1
						state.CareerInfo.raises = (state.CareerInfo.raises or 0) + 1
						if state.AddFeed then
							state:AddFeed(string.format("📈 PROMOTED! Salary now $%d (+25%%)!", state.CurrentJob.salary))
						end
					end
				end,
			},
			{ 
				text = "Take it - requires relocating", 
				effects = { Happiness = -3 }, 
				setFlags = { relocated = true, promoted = true }, 
				feedText = "You moved for the job. Big change.",
				onResolve = function(state)
					if state.CurrentJob and state.CurrentJob.salary then
						local raiseAmount = math.floor(state.CurrentJob.salary * 0.20) -- 20% raise
						state.CurrentJob.salary = state.CurrentJob.salary + raiseAmount
						state.Money = (state.Money or 0) + 2500 -- Relocation bonus
						state.CareerInfo = state.CareerInfo or {}
						state.CareerInfo.promotions = (state.CareerInfo.promotions or 0) + 1
						if state.AddFeed then
							state:AddFeed(string.format("📈 Relocated for the promotion! New salary: $%d", state.CurrentJob.salary))
						end
					end
				end,
			},
			{ 
				text = "Accept - managing former peers", 
				effects = { Happiness = -2, Smarts = 3 }, 
				feedText = "Awkward but you'll make it work.",
				setFlags = { manager = true, promoted = true },
				onResolve = function(state)
					if state.CurrentJob and state.CurrentJob.salary then
						local raiseAmount = math.floor(state.CurrentJob.salary * 0.15) -- 15% raise
						state.CurrentJob.salary = state.CurrentJob.salary + raiseAmount
						state.Money = (state.Money or 0) + 2000
						state.CareerInfo = state.CareerInfo or {}
						state.CareerInfo.promotions = (state.CareerInfo.promotions or 0) + 1
						if state.AddFeed then
							state:AddFeed(string.format("📈 Manager now! Salary: $%d. Time to lead.", state.CurrentJob.salary))
						end
					end
				end,
			},
			{ text = "Turn it down to keep sanity", effects = { Happiness = 5, Health = 3 }, feedText = "You know your limits. Smart choice." },
		},
	},
	{
		id = "layoff_notice",
		title = "Layoffs Coming",
		emoji = "📉",
		text = "Your company is doing layoffs. You might be affected.",
		question = "How do you respond to the news?",
		minAge = 25, maxAge = 60,
		baseChance = 0.45, -- CRITICAL FIX #704: Increased from 0.2 for more career drama
		cooldown = 3, -- CRITICAL FIX #705: Reduced from 5 for more variety
		requiresJob = true, -- Only trigger if you have a job
		-- CRITICAL FIX: Random layoff outcome - you don't choose if you get laid off
		choices = {
			{
				text = "Stay calm and keep working",
				effects = {},
				feedText = "You kept your head down during the chaos...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					-- Smarter/better performers more likely to survive
					local surviveChance = 0.55 + (smarts / 200)
					if roll < surviveChance then
						state:ModifyStat("Happiness", -3)
						state.Flags = state.Flags or {}
						state.Flags.survivor_guilt = true
						state:AddFeed("📉 You survived the cuts! But watched friends go. Guilt.")
					else
						state:ModifyStat("Happiness", -10)
						state:ModifyStat("Health", -3)
						state.Money = math.max(0, (state.Money or 0) - 500)
						state.Flags = state.Flags or {}
						state.Flags.unemployed = true
						state.Flags.laid_off = true
						state.Flags.between_jobs = true
						if state.ClearCareer then
							state:ClearCareer()
						else
							state.CurrentJob = nil
							state.Flags.has_job = nil
							state.Flags.employed = nil
						end
						state:AddFeed("📉 You got laid off. Devastating news.")
					end
				end,
			},
			{
				text = "Start job hunting immediately",
				effects = { Smarts = 1 },
				feedText = "You started looking for a new job right away...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local findJobChance = 0.40 + (smarts / 150)
					if roll < findJobChance then
						state:ModifyStat("Happiness", 5)
						state.Money = (state.Money or 0) + 500
						state.Flags = state.Flags or {}
						state.Flags.career_secure = true
						state:AddFeed("📉 You found a new job before the layoffs hit! Proactive move.")
					elseif roll < 0.75 then
						state.Money = (state.Money or 0) + 2000
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.unemployed = true
						state.Flags.between_jobs = true
						if state.ClearCareer then
							state:ClearCareer()
						else
							state.CurrentJob = nil
							state.Flags.has_job = nil
							state.Flags.employed = nil
						end
						state:AddFeed("📉 Laid off, but negotiated a good severance package.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.unemployed = true
						state.Flags.laid_off = true
						state.Flags.between_jobs = true
						if state.ClearCareer then
							state:ClearCareer()
						else
							state.CurrentJob = nil
							state.Flags.has_job = nil
							state.Flags.employed = nil
						end
						state:AddFeed("📉 Laid off before you could find something new.")
					end
				end,
			},
			{
				text = "Volunteer for the severance package",
				effects = {},
				feedText = "You raised your hand for the buyout...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.75 then
						state.Money = (state.Money or 0) + 3000
						state:ModifyStat("Happiness", -3)
						state.Flags = state.Flags or {}
						state.Flags.unemployed = true
						state.Flags.between_jobs = true
						if state.ClearCareer then
							state:ClearCareer()
						else
							state.CurrentJob = nil
							state.Flags.has_job = nil
							state.Flags.employed = nil
						end
						state:AddFeed("📉 Took the severance. Got paid to leave - silver lining.")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📉 They wanted you to stay! Guess you're more valuable than you thought.")
					end
				end,
			},
		},
	},
	{
		id = "starting_business",
		title = "Launching Your Business",
		emoji = "🚀",
		text = "Your business is finally launching! The big day is here.",
		question = "What's your launch strategy?",
		minAge = 25, maxAge = 55,
		oneTime = true,
		requiresFlags = { entrepreneur = true },
		-- CRITICAL FIX: Can't start business from prison
		blockedByFlags = { in_prison = true, incarcerated = true },
		-- CRITICAL FIX: Need some startup capital
		eligibility = function(state)
			local money = state.Money or 0
			if money < 500 then
				return false, "Need at least $500 to start a business"
			end
			return true
		end,

		-- CRITICAL FIX: Random outcomes based on strategy + stats
		choices = {
			{ 
				text = "Go all-in with aggressive marketing", 
				effects = {},
				feedText = "You went big on marketing...",
				onResolve = function(state)
					local money = state.Money or 0
					local smarts = state.Stats and state.Stats.Smarts or 50
					local baseChance = 0.40
					local bonus = (smarts - 50) / 100 -- smarts helps
					local roll = math.random()
					
					-- CRITICAL FIX: Can't go all-in without money
					local marketingBudget = math.min(5000, money * 0.5) -- Spend up to 50% of money
					if marketingBudget < 1000 then
						-- Too little for aggressive marketing
						state:ModifyStat("Happiness", -3)
						state:AddFeed("😰 Can't afford aggressive marketing. Starting small instead.")
						state.Money = math.max(0, money - 500)
						return
					end
					
					state.Money = math.max(0, money - marketingBudget)
					
					if roll < (baseChance + bonus) * 0.5 then
						-- Massive success (rare)
						state:ModifyStat("Happiness", 15)
						state.Money = (state.Money or 0) + 15000 + marketingBudget -- ROI
						state.Flags = state.Flags or {}
						state.Flags.successful_business = true
						state:AddFeed("🚀 MASSIVE SUCCESS! Your business took off! Big profits!")
					elseif roll < (baseChance + bonus) then
						-- Moderate success
						state:ModifyStat("Happiness", 8)
						state.Money = (state.Money or 0) + 5000
						state:AddFeed("🚀 Your marketing worked! The business is growing!")
					elseif roll < 0.85 then
						-- Struggle - already lost marketing budget
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.business_struggling = true
						state:AddFeed("😰 The marketing spend didn't pay off. Struggling...")
					else
						-- Failure - already lost marketing budget
						state:ModifyStat("Happiness", -12)
						state.Flags = state.Flags or {}
						state.Flags.business_failed = true
						state:AddFeed("💔 The business flopped. Lost your marketing investment.")
					end
				end,
			},
			{ 
				text = "Start small and grow organically", 
				effects = {},
				feedText = "You took the careful approach...",
				onResolve = function(state)
					local smarts = state.Stats and state.Stats.Smarts or 50
					local baseChance = 0.60 -- safer approach
					local bonus = (smarts - 50) / 150
					local roll = math.random()
					
					if roll < (baseChance + bonus) then
						-- Slow but steady
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Smarts", 3)
						state.Money = (state.Money or 0) + 3000
						state:AddFeed("📈 Slow but steady growth! Smart move.")
					else
						-- Stagnation
						state:ModifyStat("Happiness", -3)
						state.Money = (state.Money or 0) + 500
						state:AddFeed("😐 Growth is slower than expected, but you're staying afloat.")
					end
				end,
			},
			{ 
				text = "Try to attract investors first", 
				effects = {},
				feedText = "You pitched to investors...",
				onResolve = function(state)
					local smarts = state.Stats and state.Stats.Smarts or 50
					local looks = state.Stats and state.Stats.Looks or 50
					local baseChance = 0.35
					local bonus = ((smarts - 50) + (looks - 50)) / 200 -- charisma matters
					
					if math.random() < (baseChance + bonus) then
						state:ModifyStat("Happiness", 12)
						state.Money = (state.Money or 0) + 25000
						state.Flags = state.Flags or {}
						state.Flags.has_investors = true
						state:AddFeed("💰 Investors loved your pitch! You got funded!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("😞 Investors passed. You'll need to bootstrap.")
					end
				end,
			},
			{ 
				text = "Postpone - not ready yet", 
				effects = { Happiness = -2 },
				feedText = "You decided you're not ready. Maybe next year.",
			},
		},
	},

	-- MIDLIFE (35-55)
	{
		id = "midlife_crisis",
		title = "Midlife Crisis",
		emoji = "🏎️",
		text = "You're questioning everything about your life.",
		question = "How do you cope?",
		minAge = 38, maxAge = 52,
		oneTime = true,
		blockedByFlags = { in_prison = true, incarcerated = true },

		choices = {
			{ 
				text = "Buy something expensive and impractical", 
				-- CRITICAL FIX: Validate money before sports car purchase
				effects = {}, -- Money handled in onResolve
				setFlags = { midlife_crisis = true }, 
				feedText = "Looking at that sports car...", 
				onResolve = function(state)
					local money = state.Money or 0
					local carCost = 10000
					if money >= carCost then
						state.Money = money - carCost
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "midlife_car_" .. tostring(state.Age or 0),
								name = "Midlife Crisis Sports Car",
								emoji = "🏎️",
								price = 45000,
								value = 40000,
								condition = 95,
								isEventAcquired = true,
							})
						end
						state.Flags = state.Flags or {}
						state.Flags.has_car = true
						if state.AddFeed then
							state:AddFeed("🏎️ Bought a $10K sports car! Feeling alive!")
						end
					elseif money >= 3000 then
						-- Buy something smaller but still impractical
						state.Money = money - 3000
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddFeed then
							state:AddFeed("🛍️ Bought something expensive ($3K). Retail therapy!")
						end
					else
						-- Can't afford anything
						if state.ModifyStat then state:ModifyStat("Happiness", -5) end
						if state.AddFeed then
							state:AddFeed("💸 Can't even afford a midlife crisis car...")
						end
					end
				end 
			},
			{ text = "Have an affair", effects = { Happiness = 5 }, setFlags = { cheater = true, affair = true }, feedText = "You made a terrible decision..." },
			{ 
				text = "Make a dramatic career change", 
				-- CRITICAL FIX: Validate money before career change
				effects = {}, -- Money handled in onResolve
				setFlags = { career_reinvented = true }, 
				feedText = "Considering a career change...",
				onResolve = function(state)
					local money = state.Money or 0
					local changeCost = 2000
					if money >= changeCost then
						state.Money = money - changeCost
						if state.ModifyStat then state:ModifyStat("Happiness", 10) end
						if state.AddFeed then
							state:AddFeed("🔄 You quit to pursue your dream!")
						end
					else
						-- Can't afford transition
						if state.ModifyStat then state:ModifyStat("Happiness", 3) end
						if state.AddFeed then
							state:AddFeed("🔄 Started planning a career change. Saving up for the transition.")
						end
					end
				end,
			},
			{ 
				text = "Go to therapy", 
				-- CRITICAL FIX: Validate money before therapy
				effects = {}, -- Money handled in onResolve
				setFlags = { in_therapy = true }, 
				feedText = "Considering therapy...",
				onResolve = function(state)
					local money = state.Money or 0
					local therapyCost = 500
					if money >= therapyCost then
						state.Money = money - therapyCost
						if state.ModifyStat then 
							state:ModifyStat("Happiness", 8)
							state:ModifyStat("Smarts", 3)
						end
						if state.AddFeed then
							state:AddFeed("🧠 Therapy is helping you find clarity!")
						end
					else
						-- Free resources
						if state.ModifyStat then 
							state:ModifyStat("Happiness", 5)
							state:ModifyStat("Smarts", 1)
						end
						if state.AddFeed then
							state:AddFeed("🧠 Using free self-help resources. Some clarity found.")
						end
					end
				end,
			},
			{ text = "Embrace the change gracefully", effects = { Happiness = 10, Smarts = 2 }, setFlags = { wisdom = true }, feedText = "Growth is part of life. You accept it." },
		},
	},
	{
		id = "divorce_proceedings",
		title = "Divorce",
		emoji = "💔",
		text = "Your marriage is ending in divorce.",
		question = "How does it unfold?",
		minAge = 28, maxAge = 65,
		oneTime = true,
		requiresFlags = { married = true },

		choices = {
			{ text = "Amicable split", effects = { Happiness = -10, Money = -5000 }, setFlags = { divorced = true, recently_single = true }, feedText = "You parted ways peacefully. Still hurts." },
			{ text = "Bitter court battle", effects = { Happiness = -20, Money = -20000, Health = -5 }, setFlags = { divorced = true, messy_divorce = true, recently_single = true }, feedText = "The divorce was ugly and expensive." },
			{ text = "You cheated - you're the villain", effects = { Happiness = -15, Money = -10000 }, setFlags = { divorced = true, cheater = true, recently_single = true }, feedText = "You destroyed the marriage. Living with guilt." },
			{ text = "They cheated - you're devastated", effects = { Happiness = -25, Money = -5000, Health = -5 }, setFlags = { divorced = true, cheated_on = true, recently_single = true }, feedText = "Betrayal. The trust is shattered." },
		},
		-- CRITICAL FIX: Properly clear ALL relationship flags on divorce
		onComplete = function(state)
			state.Flags = state.Flags or {}
			state.Flags.married = nil
			state.Flags.engaged = nil
			state.Flags.has_partner = nil
			state.Flags.dating = nil
			state.Flags.committed_relationship = nil
			state.Flags.lives_with_partner = nil
			-- Clear the partner relationship
			if state.Relationships then
				state.Relationships.partner = nil
			end
		end,
	},
	{
		id = "empty_nest",
		title = "Empty Nest",
		emoji = "🏠",
		text = "Your last child has moved out of the house.",
		question = "How do you feel about it?",
		minAge = 45, maxAge = 60,
		oneTime = true,
		-- CRITICAL FIX: Require ANY child-related flag
		requiresFlags = { has_child = true },
		blockedByFlags = { no_children = true, childfree = true },
		
		-- CRITICAL FIX: Add eligibility function to double-check
		eligibility = function(state)
			local flags = state.Flags or {}
			if not (flags.has_child or flags.has_children or flags.parent) then
				return false, "Need children for this event"
			end
			return true
		end,

		choices = {
			{ text = "Lonely - miss them terribly", effects = { Happiness = -8 }, setFlags = { empty_nester = true, lonely = true }, feedText = "The house feels so empty now." },
			{ text = "Freedom! Time for us again", effects = { Happiness = 10 }, setFlags = { empty_nester = true }, feedText = "You and your partner are rediscovering each other!" },
			{ text = "Proud of the adult they became", effects = { Happiness = 8 }, setFlags = { empty_nester = true, proud_parent = true }, feedText = "You raised them well. They're thriving." },
			{ text = "Turning their room into something fun", effects = { Happiness = 6, Money = -500 }, setFlags = { empty_nester = true }, feedText = "Home gym? Art studio? The possibilities!" },
		},
	},
	{
		id = "parent_health_crisis",
		title = "Parent's Health Crisis",
		emoji = "🏥",
		text = "One of your parents is having serious health problems.",
		question = "How do you respond?",
		minAge = 35, maxAge = 60,
		baseChance = 0.3,
		cooldown = 5,

		choices = {
			{ text = "Become their primary caregiver", effects = { Happiness = -10, Health = -8, Money = -2000 }, setFlags = { family_caregiver = true }, feedText = "You've taken on a huge responsibility." },
			{ text = "Help coordinate their care", effects = { Happiness = -5, Money = -1000 }, feedText = "You're organizing doctors, nurses, and family." },
			{ text = "Struggle to be there - too far away", effects = { Happiness = -12 }, setFlags = { family_guilt = true }, feedText = "Distance makes this heartbreaking." },
			{ text = "They passed away", effects = { Happiness = -20, Health = -5 }, setFlags = { lost_parent = true }, feedText = "Your parent is gone. Grief is overwhelming." },
		},
	},
	{
		id = "bucket_list",
		title = "Bucket List Time",
		emoji = "✈️",
		text = "You're thinking about your bucket list.",
		question = "What's your next adventure?",
		minAge = 40, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		-- CRITICAL FIX: Can't do bucket list activities from prison or if homeless
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true },
		-- CRITICAL FIX: Need at least some money for activities
		eligibility = function(state)
			local money = state.Money or 0
			if money < 100 then
				return false, "Can't afford bucket list activities"
			end
			return true
		end,
		choices = {
			{ 
				text = "Dream vacation trip", 
				-- CRITICAL FIX: Validate money before $5000 trip
				effects = {}, -- Money handled in onResolve
				setFlags = { traveled_world = true }, 
				feedText = "Planning the trip of a lifetime...",
				onResolve = function(state)
					local money = state.Money or 0
					local tripCost = 5000
					if money >= tripCost then
						state.Money = money - tripCost
						if state.ModifyStat then 
							state:ModifyStat("Happiness", 15)
							state:ModifyStat("Health", 3)
						end
						if state.AddFeed then
							state:AddFeed("✈️ Dream vacation! Worth every penny!")
						end
					elseif money >= 2000 then
						state.Money = money - 2000
						if state.ModifyStat then 
							state:ModifyStat("Happiness", 10)
							state:ModifyStat("Health", 2)
						end
						if state.AddFeed then
							state:AddFeed("✈️ Budget dream trip! Still amazing!")
						end
					elseif money >= 500 then
						state.Money = money - 500
						if state.ModifyStat then state:ModifyStat("Happiness", 6) end
						if state.AddFeed then
							state:AddFeed("✈️ Took a local adventure. Dreams don't have to be expensive!")
						end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -3) end
						if state.AddFeed then
							state:AddFeed("💸 Can't afford the trip right now...")
						end
					end
				end,
			},
			{ 
				text = "Learn a new skill", 
				-- CRITICAL FIX: Validate money for classes
				effects = {}, -- Money handled in onResolve
				setFlags = { lifelong_learner = true }, 
				feedText = "Starting to learn something new...",
				onResolve = function(state)
					local money = state.Money or 0
					local classCost = 500
					if money >= classCost then
						state.Money = money - classCost
						if state.ModifyStat then 
							state:ModifyStat("Happiness", 8)
							state:ModifyStat("Smarts", 5)
						end
						if state.AddFeed then
							state:AddFeed("📚 You're never too old to learn something new!")
						end
					else
						-- Free online learning
						if state.ModifyStat then 
							state:ModifyStat("Happiness", 5)
							state:ModifyStat("Smarts", 3)
						end
						if state.AddFeed then
							state:AddFeed("📚 Learning through free online resources!")
						end
					end
				end,
			},
			{ text = "Reconnect with old friends", effects = { Happiness = 10 }, feedText = "Those reunions filled your heart." },
			{ text = "Write your memoirs", effects = { Happiness = 5, Smarts = 3 }, setFlags = { wrote_memoir = true }, feedText = "Your life story is now on paper." },
		},
	},
	{
		id = "inheritance_received",
		title = "Inheritance",
		emoji = "💰",
		text = "A relative left you an inheritance.",
		question = "What do you do with the money?",
		minAge = 30, maxAge = 70,
		baseChance = 0.35, -- CRITICAL FIX #706: Increased from 0.15 for more variety
		cooldown = 5, -- CRITICAL FIX #707: Reduced from 10

		choices = {
			{ text = "Invest it wisely", effects = { Money = 20000, Smarts = 2 }, setFlags = { investor = true }, feedText = "You're growing that inheritance!" },
			{ text = "Pay off debts", effects = { Money = 10000, Happiness = 8 }, setFlags = { debt_free = true }, feedText = "Finally debt-free! What a relief." },
			{ text = "Splurge on something fun", effects = { Money = 5000, Happiness = 12 }, feedText = "You treated yourself. YOLO!" },
			{ text = "Save it for retirement", effects = { Money = 15000, Happiness = 3 }, setFlags = { retirement_saver = true }, feedText = "Future you will thank present you." },
			{ text = "Donate to charity", effects = { Money = -5000, Happiness = 15 }, setFlags = { philanthropist = true }, feedText = "Giving back feels amazing." },
		},
	},
	{
		id = "serious_illness",
		title = "Serious Illness",
		emoji = "🏥",
		text = "You've been diagnosed with a serious illness.",
		question = "How do you handle it?",
		minAge = 40, maxAge = 80,
		baseChance = 0.25, -- CRITICAL FIX #708: Increased from 0.1 for more realism
		cooldown = 6, -- CRITICAL FIX #709: Reduced from 10

		choices = {
			{ text = "Fight with everything you have", effects = { Health = -10, Happiness = -10, Money = -10000 }, setFlags = { battling_illness = true, fighter = true }, feedText = "You're in the fight of your life." },
			{ text = "Accept it and make peace", effects = { Health = -5, Happiness = -5 }, setFlags = { at_peace = true }, feedText = "You've found acceptance." },
			{ text = "Seek alternative treatments", effects = { Health = -8, Happiness = -5, Money = -5000 }, setFlags = { alternative_medicine = true }, feedText = "You're trying every option." },
			{ text = "It's treatable - caught it early", effects = { Health = -5, Money = -3000, Happiness = 5 }, setFlags = { health_recovered = true }, feedText = "Caught early! Treatment is working." },
		},
	},
	{
		id = "winning_lottery",
		title = "🎉 Lottery Win!",
		emoji = "🎰",
		text = "You won a significant lottery prize!",
		question = "What do you do?",
		minAge = 21, maxAge = 85,
		baseChance = 0.08, -- CRITICAL FIX #710: Increased from 0.02 - rare but possible
		cooldown = 10, -- CRITICAL FIX #711: Reduced from 20
		-- CRITICAL FIX #5: Added "lottery" category for gold event card
		category = "lottery",

		choices = {
			{ text = "Quit job and live large", effects = { Money = 500000, Happiness = 20, Health = -5 }, setFlags = { lottery_winner = true }, feedText = "You're rich! But maybe you went too hard." },
			{ text = "Invest and stay humble", effects = { Money = 450000, Happiness = 10, Smarts = 3 }, setFlags = { lottery_winner = true, wise_winner = true }, feedText = "Smart moves. The money will last." },
			{ text = "Share with family", effects = { Money = 200000, Happiness = 15 }, setFlags = { lottery_winner = true, generous = true }, feedText = "Your generosity made everyone happy!" },
			{ text = "Blow it all in a year", effects = { Money = 50000, Happiness = 15, Health = -8 }, setFlags = { lottery_winner = true, broke_again = true }, feedText = "Easy come, easy go. Back to square one." },
		},
	},

	-- SENIOR EXPANSION (65+)
	{
		id = "grandchildren",
		title = "Becoming a Grandparent",
		emoji = "👶",
		text = "Your child just had a baby - you're a grandparent!",
		question = "How do you feel about it?",
		minAge = 50, maxAge = 80,
		oneTime = true,
		requiresFlags = { has_child = true },

		choices = {
			{ text = "Over the moon - best day ever", effects = { Happiness = 20 }, setFlags = { grandparent = true }, feedText = "A grandchild! Your heart is bursting with joy." },
			{ text = "Excited but feel old", effects = { Happiness = 10 }, setFlags = { grandparent = true }, feedText = "Amazing but... grandparent? Already?" },
			{ text = "Ready to spoil them rotten", effects = { Happiness = 15, Money = -500 }, setFlags = { grandparent = true, spoiling_grandparent = true }, feedText = "This kid is getting EVERYTHING!" },
			{ text = "Hope they visit often", effects = { Happiness = 12 }, setFlags = { grandparent = true }, feedText = "Can't wait to see them grow up!" },
		},
		onResolve = function(state)
			if state.AddRelationship then
				state:AddRelationship("grandchild", {
					id = "grandchild_" .. tostring(state.Age or 0),
					name = "Grandchild",
					type = "family",
					age = 0,
					relationship = 100,
					alive = true,
				})
			end
		end,
	},
	{
		id = "assisted_living",
		title = "Considering Assisted Living",
		emoji = "🏥",
		text = "Living independently is getting harder.",
		question = "What do you decide?",
		minAge = 75, maxAge = 95,
		baseChance = 0.3,
		cooldown = 5,

		choices = {
			{ text = "Move to assisted living", effects = { Health = 5, Happiness = -5, Money = -3000 }, setFlags = { assisted_living = true }, feedText = "You moved to a facility. Safer, but different." },
			{ text = "Hire in-home care", effects = { Health = 5, Money = -2000 }, setFlags = { has_caregiver = true }, feedText = "Help comes to you. You stay home." },
			{ text = "Move in with family", effects = { Happiness = 5 }, setFlags = { lives_with_family = true }, feedText = "Your kids welcomed you into their home." },
			{ text = "Stubbornly stay independent", effects = { Happiness = 3, Health = -5 }, setFlags = { fiercely_independent = true }, feedText = "You'll manage on your own, thank you very much!" },
		},
	},
	{
		-- CRITICAL FIX: Lifetime achievement is now CONTEXTUAL based on actual life!
		-- No more choosing your legacy - it's determined by what you did
		id = "lifetime_achievement",
		title = "Looking Back",
		emoji = "🪞",
		text = "As you've grown older, you find yourself reflecting on your life and what you've accomplished.",
		question = "How do you feel about your journey?",
		minAge = 60, maxAge = 90,
		oneTime = true,
		-- Dynamic eligibility check - only show if they actually DID something
		eligibility = function(state)
			local flags = state.Flags or {}
			local hasCareer = state.CurrentJob or flags.retired or flags.ceo or flags.executive
			local hasMoney = (state.Money or 0) >= 100000
			local hasFamily = flags.married or flags.has_children
			local hasLegacy = flags.famous or flags.philanthropist or flags.criminal_mastermind
			local hasCrime = flags.criminal_record or flags.ex_convict
			-- Only trigger if they have SOME kind of story to tell
			return hasCareer or hasMoney or hasFamily or hasLegacy or hasCrime
		end,
		choices = {
			{
				text = "Accept the recognition gracefully",
				effects = { Happiness = 10 },
				feedText = "You've earned this moment.",
				onResolve = function(state)
					local flags = state.Flags or {}
					local achievements = {}
					
					-- Build contextual achievements list
					if (state.Money or 0) >= 1000000 then
						table.insert(achievements, "You built real wealth - a millionaire's legacy.")
					elseif (state.Money or 0) >= 100000 then
						table.insert(achievements, "You achieved financial security.")
					elseif (state.Money or 0) < 1000 then
						table.insert(achievements, "Money was never your priority.")
					end
					
					if flags.ceo or flags.executive then
						table.insert(achievements, "You reached the top of your career.")
					elseif flags.retired then
						table.insert(achievements, "You had a long, steady career.")
					elseif state.CurrentJob then
						table.insert(achievements, "You worked hard all your life.")
					else
						table.insert(achievements, "You walked your own path, career-free.")
					end
					
					if flags.married and flags.has_children then
						table.insert(achievements, "You built a family and a home.")
					elseif flags.married then
						table.insert(achievements, "You found love in this lifetime.")
					elseif flags.has_children then
						table.insert(achievements, "You raised children.")
					end
					
					if flags.famous or flags.celebrity then
						table.insert(achievements, "You became famous!")
					end
					
					if flags.criminal_record then
						table.insert(achievements, "You lived life on your own terms... legally or not.")
					end
					
					if flags.philanthropist or flags.good_person then
						table.insert(achievements, "You helped others along the way.")
					end
					
					-- If no achievements, be honest
					if #achievements == 0 then
						table.insert(achievements, "Your journey was... quiet. But it was yours.")
					end
					
					state.Flags = state.Flags or {}
					state.Flags.honored = true
					
					local summary = table.concat(achievements, " ")
					if state.AddFeed then
						state:AddFeed("🏆 " .. summary)
					end
				end,
			},
			{
				text = "Feel content with the simple moments",
				effects = { Happiness = 8 },
				feedText = "Not every life needs to be extraordinary.",
				onResolve = function(state)
					if state.AddFeed then
						state:AddFeed("☮️ You found peace in the ordinary. Sometimes that's enough.")
					end
				end,
			},
			{
				text = "Regret the roads not taken",
				effects = { Happiness = -5, Smarts = 2 },
				feedText = "You wonder about what could have been...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.has_regrets = true
					if state.AddFeed then
						state:AddFeed("😔 Looking back, there are things you wish you'd done differently...")
					end
				end,
			},
		},
	},
	{
		id = "spouse_passes",
		title = "Losing Your Partner",
		emoji = "💔",
		text = "Your life partner has passed away.",
		question = "How do you cope with the loss?",
		minAge = 55, maxAge = 95,
		oneTime = true,
		requiresFlags = { married = true },

		choices = {
			{ text = "Lean on family for support", effects = { Happiness = -25, Health = -10 }, setFlags = { widowed = true }, feedText = "Devastating loss. Family keeps you going." },
			{ text = "Find solace in memories", effects = { Happiness = -20, Health = -8 }, setFlags = { widowed = true }, feedText = "The memories of your life together sustain you." },
			{ text = "Struggle alone with grief", effects = { Happiness = -30, Health = -15 }, setFlags = { widowed = true, depressed = true }, feedText = "The loneliness is crushing." },
			{ text = "Eventually find new companionship", effects = { Happiness = -15, Health = -5 }, setFlags = { widowed = true, found_love_again = true }, feedText = "After time, you found connection again." },
		},
		-- CRITICAL FIX: Properly clear ALL relationship flags when spouse dies
		onComplete = function(state)
			state.Flags = state.Flags or {}
			state.Flags.married = nil
			state.Flags.engaged = nil
			state.Flags.has_partner = nil
			state.Flags.dating = nil
			state.Flags.committed_relationship = nil
			state.Flags.lives_with_partner = nil
			-- Mark partner as deceased but keep reference for memories
			if state.Relationships and state.Relationships.partner then
				state.Relationships.partner.alive = false
				state.Relationships.partner.deceased = true
				-- Move to a different key so new relationship can form
				state.Relationships.late_spouse = state.Relationships.partner
				state.Relationships.partner = nil
			end
		end,
	},
	{
		id = "writing_will",
		title = "Writing Your Will",
		emoji = "📜",
		text = "It's time to formalize your last wishes.",
		question = "How do you want to divide your estate?",
		minAge = 60, maxAge = 95,
		oneTime = true,

		choices = {
			{ text = "Everything split equally among children", effects = { Happiness = 5 }, setFlags = { has_will = true }, feedText = "Fair and simple. Fewer arguments later." },
			{ text = "Leave more to those who need it", effects = { Happiness = 3 }, setFlags = { has_will = true }, feedText = "You considered each person's situation." },
			{ text = "Donate much of it to charity", effects = { Happiness = 10, Money = -5000 }, setFlags = { has_will = true, charitable_legacy = true }, feedText = "Your wealth will help many causes." },
			{ text = "Leave it all to one person", effects = { Happiness = -2 }, setFlags = { has_will = true, contentious_will = true }, feedText = "This might cause family drama later..." },
		},
	},
	{
		id = "technology_struggle",
		title = "Technology Troubles",
		emoji = "📱",
		text = "Technology keeps changing and it's hard to keep up.",
		question = "How do you handle it?",
		minAge = 60, maxAge = 95,
		baseChance = 0.5,
		cooldown = 2,

		choices = {
			{ text = "Take a class to learn", effects = { Smarts = 5, Happiness = 5 }, setFlags = { tech_savvy_senior = true }, feedText = "You're learning! Video calls are great!" },
			{ text = "Ask grandkids for help", effects = { Happiness = 5 }, feedText = "The young ones are patient teachers." },
			{ text = "Give up - it's too confusing", effects = { Happiness = -3 }, setFlags = { technology_resistant = true }, feedText = "You'll stick with what you know." },
			{ text = "Hire someone to set things up", effects = { Money = -200, Happiness = 3 }, feedText = "Everything works now... mostly." },
		},
	},
	{
		id = "downsizing",
		title = "Time to Downsize",
		emoji = "🏠",
		text = "Your big house feels too empty now.",
		question = "What do you do?",
		minAge = 60, maxAge = 85,
		oneTime = true,
		requiresFlags = { homeowner = true },

		choices = {
			{ text = "Sell and move to a smaller place", effects = { Money = 20000, Happiness = 3 }, setFlags = { downsized = true }, feedText = "Less space, less maintenance. More freedom!" },
			{ text = "Stay - too many memories here", effects = { Happiness = 5, Money = -1000 }, feedText = "This house is full of your life's history." },
			{ text = "Move to a retirement community", effects = { Money = 15000, Happiness = 5 }, setFlags = { retirement_community = true }, feedText = "New friends and activities await!" },
			{ text = "Have family move in with you", effects = { Happiness = 8 }, setFlags = { multigenerational_home = true }, feedText = "The house is full of life again!" },
		},
	},
	{
		id = "final_adventure",
		title = "One Last Adventure",
		emoji = "🌍",
		text = "You want one final big adventure.",
		question = "What will it be?",
		minAge = 70, maxAge = 95,
		oneTime = true,

		choices = {
			{ text = "World cruise", effects = { Money = -15000, Happiness = 20, Health = 3 }, setFlags = { world_traveler = true }, feedText = "Seeing the world at sea. Magnificent!" },
			{ text = "Visit every grandchild", effects = { Money = -3000, Happiness = 15 }, feedText = "Quality time with each grandchild. Priceless." },
			{ text = "Return to your birthplace", effects = { Money = -2000, Happiness = 12 }, setFlags = { returned_home = true }, feedText = "Revisiting where it all began. Emotional." },
			{ text = "Learn to paint/play music", effects = { Money = -500, Happiness = 10, Smarts = 3 }, setFlags = { artist_senior = true }, feedText = "Never too late to be creative!" },
			{ text = "Write your life story", effects = { Happiness = 8, Smarts = 3 }, setFlags = { memoir_complete = true }, feedText = "Your story is now preserved for generations." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MORE MID-LIFE EVENTS (30-60) - EXPANDED VARIETY
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "car_breakdown",
		title = "Car Troubles",
		emoji = "🚗",
		text = "Your car broke down unexpectedly!",
		question = "How do you handle this?",
		minAge = 18, maxAge = 65,
		baseChance = 0.4,
		cooldown = 3,
		requiresFlags = { has_car = true },
		blockedByFlags = { in_prison = true },
		
		-- CRITICAL FIX: Random repair cost - player doesn't choose how serious the breakdown is
		choices = {
			{
				text = "Take it to a mechanic",
				effects = {},
				feedText = "The mechanic takes a look...",
				onResolve = function(state)
					local money = state.Money or 0
					local roll = math.random()
					if roll < 0.30 then
						-- Minor fix
						local cost = math.min(200, money * 0.3)
						state.Money = math.max(0, money - cost)
						state:ModifyStat("Happiness", -2)
						state:AddFeed(string.format("🔧 Minor issue. $%d repair.", math.floor(cost)))
					elseif roll < 0.65 then
						-- Moderate repair
						local cost = math.min(800, money * 0.4)
						state.Money = math.max(0, money - cost)
						state:ModifyStat("Happiness", -4)
						state:AddFeed(string.format("🔧 Significant repair needed. $%d.", math.floor(cost)))
					elseif roll < 0.90 then
						-- Major repair
						local cost = math.min(2000, money * 0.5)
						state.Money = math.max(0, money - cost)
						state:ModifyStat("Happiness", -6)
						state:AddFeed(string.format("🔧 Major repair! $%d. Ouch.", math.floor(cost)))
					else
						-- Totaled
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.has_car = nil
						state.Flags.owns_car = nil
						state:AddFeed("🚗 The car is totaled. Beyond repair. You need a new one.")
					end
				end,
			},
			{
				text = "Try to fix it yourself",
				effects = {},
				feedText = "You rolled up your sleeves...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local fixChance = 0.30 + (smarts / 200)
					if state.Flags and state.Flags.mechanic then fixChance = fixChance + 0.30 end
					
					if roll < fixChance then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🔧 You fixed it yourself! Saved a lot of money!")
					elseif roll < fixChance + 0.30 then
						local cost = 100
						state.Money = math.max(0, (state.Money or 0) - cost)
						state:AddFeed("🔧 Partial fix. Still needed some parts.")
					else
						local cost = 500
						state.Money = math.max(0, (state.Money or 0) - cost)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🔧 Made it worse. Had to pay a mechanic to fix your fix.")
					end
				end,
			},
			{
				text = "Use public transit/rideshare instead",
				effects = { Money = -100, Happiness = -2 },
				feedText = "Getting by without the car for now...",
			},
		},
	},
	{
		id = "neighbor_conflict",
		title = "Neighbor Problems",
		emoji = "🏠",
		text = "There's an ongoing conflict with your neighbor.",
		question = "What's the issue?",
		minAge = 22, maxAge = 70,
		baseChance = 0.3,
		cooldown = 4,
		blockedByFlags = { in_prison = true, homeless = true },
		
		choices = {
			{ text = "They're too loud", effects = { Happiness = -4, Health = -2 }, setFlags = { bad_neighbors = true }, feedText = "The noise is driving you crazy." },
			{ text = "Property line dispute", effects = { Happiness = -3, Money = -500 }, feedText = "Lawyers might get involved..." },
			{ text = "Their pets are a nuisance", effects = { Happiness = -3 }, feedText = "Barking at all hours. Pets everywhere." },
			{ text = "Actually, we resolved it", effects = { Happiness = 4 }, setFlags = { good_neighbors = true }, feedText = "Talked it out like adults. Good neighbors now!" },
		},
	},
	{
		id = "investment_opportunity",
		title = "Investment Opportunity",
		emoji = "📈",
		text = "A friend tells you about an investment opportunity.",
		question = "Do you invest?",
		minAge = 25, maxAge = 65,
		baseChance = 0.3,
		cooldown = 4,
		blockedByFlags = { in_prison = true },
		-- CRITICAL FIX: Need money to invest
		eligibility = function(state)
			local money = state.Money or 0
			if money < 500 then
				return false, "No money to invest"
			end
			return true
		end,
		
		-- CRITICAL FIX: Random investment outcome - you don't choose if it succeeds!
		choices = {
			{
				text = "Go big - invest a lot",
				effects = {},
				feedText = "You made a significant investment...",
				onResolve = function(state)
					local money = state.Money or 0
					local investAmount = math.min(5000, money * 0.4)
					state.Money = money - investAmount
					
					local roll = math.random()
					if roll < 0.25 then
						-- Big win
						local returns = investAmount * 3
						state.Money = (state.Money or 0) + returns
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.investor = true
						state.Flags.good_investor = true
						state:AddFeed(string.format("📈 JACKPOT! Investment tripled! +$%d!", math.floor(returns - investAmount)))
					elseif roll < 0.55 then
						-- Modest gain
						local returns = investAmount * 1.3
						state.Money = (state.Money or 0) + returns
						state:ModifyStat("Happiness", 5)
						state:AddFeed(string.format("📈 Nice return! +$%d profit.", math.floor(returns - investAmount)))
					elseif roll < 0.80 then
						-- Break even or small loss
						local returns = investAmount * 0.8
						state.Money = (state.Money or 0) + returns
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📈 Didn't work out. Lost a bit.")
					else
						-- Lost it all
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.bad_investor = true
						state:AddFeed(string.format("📉 Scam! Lost $%d! Should have done research.", math.floor(investAmount)))
					end
				end,
			},
			{
				text = "Invest a small amount to test",
				effects = {},
				feedText = "You made a small test investment...",
				onResolve = function(state)
					local money = state.Money or 0
					local investAmount = math.min(500, money * 0.1)
					state.Money = money - investAmount
					
					local roll = math.random()
					if roll < 0.35 then
						local returns = investAmount * 2
						state.Money = (state.Money or 0) + returns
						state:ModifyStat("Happiness", 6)
						state:AddFeed(string.format("📈 Small investment doubled! +$%d", math.floor(returns - investAmount)))
					elseif roll < 0.65 then
						local returns = investAmount * 1.1
						state.Money = (state.Money or 0) + returns
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📈 Small gain. Nothing exciting.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed(string.format("📉 Lost the $%d. Smart to start small.", math.floor(investAmount)))
					end
				end,
			},
			{
				text = "Pass - too risky",
				effects = { Happiness = 2 },
				setFlags = { cautious_investor = true },
				feedText = "You trusted your gut and passed.",
			},
		},
	},
	{
		id = "home_renovation",
		title = "Home Renovation",
		emoji = "🔨",
		text = "Your home needs some updates.",
		question = "What do you do?",
		minAge = 28, maxAge = 70,
		baseChance = 0.3,
		cooldown = 5,
		requiresFlags = { homeowner = true },
		blockedByFlags = { in_prison = true },
		-- CRITICAL FIX: Need money for renovations
		eligibility = function(state)
			local money = state.Money or 0
			if money < 500 then
				return false, "No money for renovations"
			end
			return true
		end,
		
		choices = {
			{
				text = "DIY renovation project",
				effects = {},
				feedText = "You decided to do it yourself...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local money = state.Money or 0
					local materialCost = math.min(1000, money * 0.2)
					state.Money = money - materialCost
					
					local roll = math.random()
					local successChance = 0.40 + (smarts / 200)
					if roll < successChance then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("🔨 DIY success! Home looks great and you saved money!")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🔨 It's... okay. Not professional but functional.")
					else
						local fixCost = math.min(1500, (state.Money or 0) * 0.3)
						state.Money = math.max(0, (state.Money or 0) - fixCost)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🔨 Disaster. Had to hire someone to fix your mistakes.")
					end
				end,
			},
			{
				text = "Hire professionals",
				effects = {},
				feedText = "You hired contractors...",
				onResolve = function(state)
					local money = state.Money or 0
					local cost = math.min(5000, money * 0.4)
					state.Money = math.max(0, money - cost)
					
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed(string.format("🔨 Professional job! Home looks amazing! ($%d)", math.floor(cost)))
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🔨 Good job, some delays, but looks nice.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🔨 Contractor issues. Took forever and cost more than quoted.")
					end
				end,
			},
			{
				text = "Put it off for later",
				effects = { Happiness = -2 },
				feedText = "The home continues to age. You'll get to it eventually.",
			},
		},
	},
	{
		id = "hobby_discovered",
		title = "New Passion",
		emoji = "✨",
		text = "You've discovered a new hobby that brings you joy!",
		question = "What captured your interest?",
		minAge = 25, maxAge = 75,
		baseChance = 0.4,
		cooldown = 4,
		blockedByFlags = { in_prison = true },
		
		choices = {
			{ text = "Gardening", effects = { Happiness = 6, Health = 3 }, setFlags = { gardener = true }, feedText = "Growing things is incredibly satisfying!" },
			{ text = "Cooking/Baking", effects = { Happiness = 5, Health = 2 }, setFlags = { home_chef = true }, feedText = "You're becoming quite the chef!" },
			{ text = "Photography", effects = { Happiness = 5, Smarts = 2, Money = -300 }, setFlags = { photographer = true }, feedText = "Capturing beautiful moments!" },
			{ text = "Woodworking", effects = { Happiness = 5, Smarts = 3, Money = -200 }, setFlags = { woodworker = true }, feedText = "Making things with your hands is therapeutic." },
			{ text = "Playing an instrument", effects = { Happiness = 6, Smarts = 3, Money = -400 }, setFlags = { musician_hobby = true }, feedText = "Music brings you so much joy!" },
		},
	},
	{
		id = "friendship_drifting",
		title = "Friendships Fading",
		emoji = "👋",
		text = "You've noticed your friendships have been drifting apart.",
		question = "What do you do about it?",
		minAge = 30, maxAge = 65,
		baseChance = 0.4,
		cooldown = 4,
		
		choices = {
			{ text = "Make effort to reconnect", effects = { Happiness = 8, Money = -100 }, setFlags = { maintains_friendships = true }, feedText = "You organized a reunion. Worth every moment!" },
			{ text = "Accept it's natural", effects = { Happiness = -3 }, feedText = "People grow apart. It's sad but normal." },
			{ text = "Focus on making new friends", effects = { Happiness = 5 }, setFlags = { social_adult = true }, feedText = "New friendships are forming at this stage of life!" },
			{ text = "Become more of a loner", effects = { Happiness = -5 }, setFlags = { loner = true }, feedText = "You're okay being alone. Mostly." },
		},
	},
	{
		id = "charity_work",
		title = "Giving Back",
		emoji = "❤️",
		text = "You feel called to give back to the community.",
		question = "How do you contribute?",
		minAge = 30, maxAge = 80,
		baseChance = 0.3,
		cooldown = 4,
		blockedByFlags = { in_prison = true },
		
		choices = {
			{ text = "Volunteer time regularly", effects = { Happiness = 10, Health = 2 }, setFlags = { volunteer_adult = true }, feedText = "Volunteering fills your heart!" },
			{ 
				text = "Make a significant donation", 
				effects = {},
				feedText = "You decided to donate...",
				onResolve = function(state)
					local money = state.Money or 0
					local donation = math.min(5000, money * 0.2)
					if donation >= 500 then
						state.Money = money - donation
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.philanthropist = true
						state:AddFeed(string.format("❤️ Donated $%d! Making a real difference!", math.floor(donation)))
					elseif donation >= 100 then
						state.Money = money - donation
						state:ModifyStat("Happiness", 6)
						state:AddFeed(string.format("❤️ Donated $%d. Every bit helps!", math.floor(donation)))
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("❤️ Can't afford much right now, but the thought counts.")
					end
				end,
			},
			{ text = "Start a community initiative", effects = { Happiness = 8, Smarts = 3 }, setFlags = { community_leader = true }, feedText = "You started something meaningful in your neighborhood!" },
			{ text = "Mentor young people", effects = { Happiness = 7, Smarts = 2 }, setFlags = { mentor = true }, feedText = "Passing on your knowledge to the next generation!" },
		},
	},
	{
		id = "unexpected_windfall",
		title = "Unexpected Money",
		emoji = "💵",
		text = "You received some unexpected money!",
		question = "Where did it come from?",
		minAge = 20, maxAge = 75,
		baseChance = 0.4, -- CRITICAL FIX #712: Increased from 0.15 for more financial events
		cooldown = 3, -- CRITICAL FIX #713: Reduced from 6 for more variety
		
		-- CRITICAL FIX: Random windfall amount - player doesn't choose how much they get!
		choices = {
			{
				text = "Tax refund!",
				effects = {},
				feedText = "The tax refund hit your account...",
				onResolve = function(state)
					local roll = math.random()
					local amount = math.floor(roll * 2000 + 500) -- $500 to $2500
					state.Money = (state.Money or 0) + amount
					state:ModifyStat("Happiness", 6)
					state:AddFeed(string.format("💵 Tax refund: $%d! Nice surprise!", amount))
				end,
			},
			{
				text = "Old debt repaid",
				effects = {},
				feedText = "Someone finally paid you back...",
				onResolve = function(state)
					local roll = math.random()
					local amount = math.floor(roll * 1500 + 200) -- $200 to $1700
					state.Money = (state.Money or 0) + amount
					state:ModifyStat("Happiness", 8)
					state:AddFeed(string.format("💵 They finally paid back $%d! Didn't think you'd see that again!", amount))
				end,
			},
			{
				text = "Work bonus",
				effects = {},
				requiresJob = true,
				feedText = "Your boss called you in...",
				onResolve = function(state)
					local roll = math.random()
					local amount = math.floor(roll * 3000 + 1000) -- $1000 to $4000
					state.Money = (state.Money or 0) + amount
					state:ModifyStat("Happiness", 10)
					state:AddFeed(string.format("💵 Surprise bonus: $%d! Hard work paying off!", amount))
				end,
			},
			{
				text = "Found money on the street",
				effects = {},
				feedText = "You saw something on the ground...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						local amount = math.floor(math.random() * 50 + 10) -- $10 to $60
						state.Money = (state.Money or 0) + amount
						state:ModifyStat("Happiness", 3)
						state:AddFeed(string.format("💵 Found $%d! Your lucky day!", amount))
					else
						local amount = math.floor(math.random() * 400 + 100) -- $100 to $500
						state.Money = (state.Money or 0) + amount
						state:ModifyStat("Happiness", 8)
						state:AddFeed(string.format("💵 Found $%d in an envelope! Jackpot!", amount))
					end
				end,
			},
		},
	},
	{
		id = "jury_duty",
		title = "Jury Duty",
		emoji = "⚖️",
		text = "You've been summoned for jury duty.",
		question = "How do you respond?",
		minAge = 21, maxAge = 70,
		baseChance = 0.4, -- CRITICAL FIX #714: Increased from 0.2
		cooldown = 3, -- CRITICAL FIX #715: Reduced from 5 
		blockedByFlags = { in_prison = true, criminal_record = true },
		
		choices = {
			{
				text = "Serve on the jury",
				effects = {},
				feedText = "You reported for jury duty...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 2)
						state.Money = math.max(0, (state.Money or 0) - 100) -- Lost work time
						state:AddFeed("⚖️ Served on a jury. Interesting experience!")
					elseif roll < 0.70 then
						state:ModifyStat("Smarts", 2)
						state:AddFeed("⚖️ Selected for jury but case settled. Went home.")
					else
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", -2)
						state.Money = math.max(0, (state.Money or 0) - 300)
						state:AddFeed("⚖️ Served on a long trial. Heavy responsibility.")
					end
				end,
			},
			{ text = "Get excused legitimately", effects = { Happiness = 2 }, feedText = "Had a valid reason to be excused. Phew!" },
			{ text = "Actually find it interesting", effects = { Happiness = 5, Smarts = 4 }, setFlags = { civic_minded = true }, feedText = "Fascinating look at the justice system!" },
		},
	},
	{
		id = "health_routine_established",
		title = "Health Check",
		emoji = "🏃",
		text = "Time to think about your health habits.",
		question = "How are you taking care of yourself?",
		minAge = 30, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		blockedByFlags = { in_prison = true },
		
		choices = {
			{ text = "Started exercising regularly", effects = { Health = 8, Happiness = 5, Money = -200 }, setFlags = { exercises = true }, feedText = "Gym membership! Feeling stronger!" },
			{ text = "Improved diet significantly", effects = { Health = 6, Happiness = 3, Money = -100 }, setFlags = { healthy_eater = true }, feedText = "Eating better. More energy!" },
			{ text = "Both diet and exercise", effects = { Health = 12, Happiness = 7, Money = -300 }, setFlags = { health_focused = true }, feedText = "Complete lifestyle change! Looking and feeling great!" },
			{ text = "Still neglecting health", effects = { Health = -5, Happiness = -2 }, setFlags = { unhealthy_habits = true }, feedText = "You know you should do better..." },
		},
	},
	{
		id = "pet_adoption",
		title = "Pet Adoption",
		emoji = "🐕",
		text = "You're thinking about getting a pet!",
		question = "What pet do you adopt?",
		minAge = 22, maxAge = 75,
		baseChance = 0.3,
		cooldown = 5,
		blockedByFlags = { in_prison = true, has_pet = true },
		
		choices = {
			{ text = "Adopt a dog", effects = { Happiness = 10, Health = 3, Money = -300 }, setFlags = { has_pet = true, has_dog = true }, feedText = "You adopted a dog! Unconditional love awaits!" },
			{ text = "Adopt a cat", effects = { Happiness = 8, Money = -150 }, setFlags = { has_pet = true, has_cat = true }, feedText = "You adopted a cat! Independent but loving!" },
			{ text = "Get a fish tank", effects = { Happiness = 4, Smarts = 1, Money = -100 }, setFlags = { has_pet = true, has_fish = true }, feedText = "Fish tank set up! Very relaxing to watch." },
			{ text = "Rescue an older pet", effects = { Happiness = 12, Money = -200 }, setFlags = { has_pet = true, pet_rescuer = true }, feedText = "Gave a senior pet a loving home! You're their hero!" },
			{ text = "Not the right time", effects = { Happiness = -2 }, feedText = "Maybe when life is more stable." },
		},
	},
	{
		id = "social_media_dilemma",
		title = "Social Media Life",
		emoji = "📱",
		text = "Social media is taking up a lot of your time.",
		question = "What's your relationship with social media?",
		minAge = 25, maxAge = 60,
		baseChance = 0.4,
		cooldown = 3,
		
		choices = {
			{ text = "It's connecting me with people", effects = { Happiness = 4 }, setFlags = { social_online = true }, feedText = "Finding old friends and making new connections!" },
			{ text = "It's making me anxious", effects = { Happiness = -5, Health = -2 }, setFlags = { social_media_anxiety = true }, feedText = "Comparison culture is toxic." },
			{ text = "Taking a digital detox", effects = { Happiness = 8, Health = 3 }, setFlags = { digital_minimalist = true }, feedText = "Stepping away felt amazing!" },
			{ text = "Using it for business/career", effects = { Smarts = 3, Money = 200 }, setFlags = { social_media_pro = true }, feedText = "Leveraging it professionally!" },
		},
	},
	{
		id = "career_plateau",
		title = "Career Plateau",
		emoji = "📊",
		text = "Your career has hit a plateau. No promotions, no growth.",
		question = "What do you do about it?",
		minAge = 35, maxAge = 55,
		baseChance = 0.3,
		cooldown = 4,
		requiresJob = true,
		
		choices = {
			{
				text = "Go back to school for new skills",
				effects = {},
				feedText = "You decided to learn new skills...",
				onResolve = function(state)
					local money = state.Money or 0
					local tuitionCost = math.min(3000, money * 0.3)
					if money >= 1000 then
						state.Money = money - tuitionCost
						state:ModifyStat("Smarts", 6)
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.continuing_education = true
						state:AddFeed(string.format("📚 Going back to school! ($%d investment in yourself)", math.floor(tuitionCost)))
					else
						state:ModifyStat("Smarts", 3)
						state:AddFeed("📚 Taking free online courses instead. Every bit helps!")
					end
				end,
			},
			{ text = "Start networking aggressively", effects = { Happiness = -2, Smarts = 2 }, setFlags = { networking = true }, feedText = "LinkedIn, conferences, coffee meetings..." },
			{ text = "Accept it and focus on life outside work", effects = { Happiness = 5, Health = 2 }, setFlags = { work_life_balance = true }, feedText = "Work isn't everything. Finding joy elsewhere!" },
			{ text = "Job search while employed", effects = { Smarts = 2 }, setFlags = { job_hunting = true }, feedText = "Quietly looking for better opportunities." },
		},
	},
	{
		id = "vacation_planning",
		title = "Vacation Time",
		emoji = "🏖️",
		text = "You have vacation time saved up. Time to use it!",
		question = "Where do you go?",
		minAge = 22, maxAge = 70,
		baseChance = 0.5,
		cooldown = 2,
		blockedByFlags = { in_prison = true, homeless = true },
		-- CRITICAL FIX: Need at least some money for vacation
		eligibility = function(state)
			local money = state.Money or 0
			if money < 100 then
				return false, "Can't afford any vacation"
			end
			return true
		end,
		
		choices = {
			{
				text = "Dream destination abroad",
				effects = {},
				feedText = "Planning the big trip...",
				onResolve = function(state)
					local money = state.Money or 0
					local tripCost = math.min(5000, money * 0.4)
					if tripCost >= 2000 then
						state.Money = money - tripCost
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Health", 3)
						state.Flags = state.Flags or {}
						state.Flags.well_traveled = true
						state:AddFeed(string.format("🏖️ Amazing international trip! ($%d well spent!)", math.floor(tripCost)))
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🏖️ Dream trip is out of budget right now...")
					end
				end,
			},
			{
				text = "Road trip adventure",
				effects = {},
				feedText = "Loading up the car...",
				onResolve = function(state)
					local money = state.Money or 0
					local tripCost = math.min(1000, money * 0.2)
					if tripCost >= 300 then
						state.Money = money - tripCost
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Health", 2)
						state:AddFeed(string.format("🚗 Epic road trip! ($%d)", math.floor(tripCost)))
					else
						state.Money = math.max(0, money - 100)
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🚗 Short but sweet road trip!")
					end
				end,
			},
			{
				text = "Staycation at home",
				effects = { Happiness = 6, Health = 3, Money = -100 },
				feedText = "Sometimes home is the best vacation. Relaxed and recharged!",
			},
			{
				text = "Visit family",
				effects = { Happiness = 8, Money = -300 },
				feedText = "Quality time with family. Worth the trip!",
			},
		},
	},
	{
		id = "sleep_problems",
		title = "Sleep Struggles",
		emoji = "😴",
		text = "You've been having trouble sleeping.",
		question = "What do you do about it?",
		minAge = 28, maxAge = 70,
		baseChance = 0.3,
		cooldown = 4,
		
		choices = {
			{
				text = "See a sleep specialist",
				effects = {},
				feedText = "You saw a doctor about it...",
				onResolve = function(state)
					local money = state.Money or 0
					local cost = math.min(500, money * 0.2)
					if cost >= 200 then
						state.Money = money - cost
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 4)
						state:AddFeed("😴 Got a sleep study. Solutions found!")
					else
						state:ModifyStat("Health", 2)
						state:AddFeed("😴 Doctor gave some advice. Trying it out.")
					end
				end,
			},
			{ text = "Fix sleep hygiene habits", effects = { Health = 4, Happiness = 3 }, setFlags = { good_sleep_habits = true }, feedText = "No screens before bed. Regular schedule. It's helping!" },
			{ text = "Try sleep supplements", effects = { Health = 2, Money = -50 }, feedText = "Melatonin and herbal teas. Some improvement." },
			{ text = "Just deal with it", effects = { Health = -5, Happiness = -4 }, setFlags = { sleep_deprived = true }, feedText = "Running on fumes. This isn't sustainable." },
		},
	},
	{
		id = "family_reunion",
		title = "Family Reunion",
		emoji = "👨‍👩‍👧‍👦",
		text = "There's a big family reunion coming up!",
		question = "How do you feel about it?",
		minAge = 25, maxAge = 75,
		baseChance = 0.3,
		cooldown = 4,
		blockedByFlags = { in_prison = true },
		
		choices = {
			{ text = "Can't wait to see everyone!", effects = { Happiness = 10, Money = -200 }, setFlags = { family_connected = true }, feedText = "Catching up with relatives you haven't seen in years!" },
			{ text = "Dreading the awkward questions", effects = { Happiness = -3 }, feedText = "So, when are you getting married? Having kids? Getting a real job?" },
			{ text = "Skip it - too much drama", effects = { Happiness = 2 }, setFlags = { avoids_family = true }, feedText = "You made an excuse. Some family is best in small doses." },
			{ text = "Organizing it yourself", effects = { Happiness = 5, Money = -500, Smarts = 2 }, setFlags = { family_planner = true }, feedText = "You're bringing everyone together!" },
		},
	},
	{
		id = "coworker_friendship",
		title = "Work Friend",
		emoji = "👥",
		text = "You've become close friends with a coworker.",
		question = "How does this friendship develop?",
		minAge = 22, maxAge = 60,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		
		choices = {
			{ text = "Best work friend ever", effects = { Happiness = 8 }, setFlags = { has_work_friend = true }, feedText = "Work is so much better with a good friend there!" },
			{ text = "Hang out outside work too", effects = { Happiness = 6, Money = -50 }, setFlags = { work_friend_real_friend = true }, feedText = "The friendship extends beyond the office!" },
			{ text = "Keep it professional", effects = { Happiness = 3 }, feedText = "Friendly at work, separate lives outside." },
			{ text = "They left the company", effects = { Happiness = -4 }, feedText = "Lost your work buddy. The office isn't the same." },
		},
	},
	{
		id = "random_act_kindness",
		title = "Random Kindness",
		emoji = "💕",
		text = "A stranger did something unexpectedly kind for you!",
		question = "What happened?",
		minAge = 18, maxAge = 85,
		baseChance = 0.2,
		cooldown = 4,
		
		choices = {
			{ text = "Paid for your coffee", effects = { Happiness = 6, Money = 5 }, feedText = "A stranger ahead of you in line paid for your order!" },
			{ text = "Helped you when you were stuck", effects = { Happiness = 8 }, feedText = "Someone stopped to help when you needed it most!" },
			{ text = "Gave you a sincere compliment", effects = { Happiness = 5, Looks = 1 }, feedText = "A stranger's kind words made your day!" },
			{ text = "Paid it forward", effects = { Happiness = 10, Money = -20 }, setFlags = { pays_it_forward = true }, feedText = "You were inspired to do something kind for someone else!" },
		},
	},
	{
		id = "hobby_competition",
		title = "Competition Time",
		emoji = "🏆",
		text = "There's a competition related to one of your hobbies!",
		question = "Do you enter?",
		minAge = 20, maxAge = 70,
		baseChance = 0.3,
		cooldown = 4,
		
		-- CRITICAL FIX: Random competition outcome
		choices = {
			{
				text = "Go for the win!",
				effects = {},
				feedText = "You entered the competition...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local winChance = 0.25 + (smarts / 200)
					if roll < winChance * 0.5 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.competition_winner = true
						state:AddFeed("🏆 FIRST PLACE! You won! What an achievement!")
					elseif roll < winChance then
						state.Money = (state.Money or 0) + 100
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🏆 Top finisher! You placed well!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🏆 Didn't place, but it was fun to compete!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🏆 Got eliminated early. Humbling experience.")
					end
				end,
			},
			{ text = "Just participate for fun", effects = { Happiness = 5 }, feedText = "Not about winning - just enjoying the experience!" },
			{ text = "Watch from the sidelines", effects = { Happiness = 2 }, feedText = "Enjoyed watching others compete." },
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #456: EXPANDED ADULT EVENTS
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- CAREER CROSSROADS
	{
		id = "career_crossroads",
		title = "Career Crossroads",
		emoji = "🔀",
		text = "You've been doing the same job for years. Is it time for a change?",
		question = "What do you decide?",
		minAge = 28, maxAge = 50,
		baseChance = 0.3,
		cooldown = 8,
		maxOccurrences = 2,
		choices = {
			{ text = "Take a leap and change careers", effects = { Happiness = 15, Money = -5000 }, setFlags = { career_changer = true }, feedText = "Scary but exciting! New chapter begins." },
			{ text = "Stay but ask for a promotion", effects = { Happiness = 5, Money = 5000 }, feedText = "You made your case. A raise is coming!" },
			{ text = "Start a side business", effects = { Happiness = 10, Money = -2000, Smarts = 5 }, setFlags = { entrepreneur = true }, feedText = "Nights and weekends building your dream!" },
			{ text = "Accept that this is your path", effects = { Happiness = -5 }, feedText = "Comfort is nice. Adventure can wait." },
		},
	},
	
	-- HOME PURCHASE
	{
		id = "first_home_purchase",
		title = "Buying a Home!",
		emoji = "🏠",
		text = "You found the perfect house. It's time to make an offer!",
		question = "How do you approach this?",
		minAge = 25, maxAge = 50,
		baseChance = 0.3,
		oneTime = true,
		maxOccurrences = 1,
		blockedByFlags = { homeowner = true },
		choices = {
			{ text = "Offer asking price immediately", effects = { Happiness = 15, Money = -50000 }, setFlags = { homeowner = true }, feedText = "🏠 Keys in hand! You're a homeowner!" },
			{ text = "Negotiate aggressively", effects = { Happiness = 12, Money = -40000, Smarts = 3 }, setFlags = { homeowner = true }, feedText = "🏠 Saved $10k with your negotiating skills!" },
			{ text = "Keep renting for now", effects = { Happiness = -5 }, feedText = "Not ready for that commitment yet." },
		},
	},
	
	-- MARRIAGE PROPOSAL
	{
		id = "marriage_proposal_moment",
		title = "The Big Question",
		emoji = "💍",
		text = "After much thought, it feels like the right time to propose to your partner!",
		question = "How does it go?",
		minAge = 22, maxAge = 55,
		baseChance = 0.35,
		oneTime = true,
		maxOccurrences = 1,
		blockedByFlags = { married = true, engaged = true },
		requiresFlags = { in_relationship = true },
		choices = {
			{ text = "Grand romantic gesture", effects = { Happiness = 25, Money = -5000 }, setFlags = { engaged = true, romantic = true }, feedText = "💍 They said YES! What a magical moment!" },
			{ text = "Simple and heartfelt", effects = { Happiness = 22 }, setFlags = { engaged = true }, feedText = "💍 They said YES! Sometimes simple is perfect." },
			{ text = "They propose to you first!", effects = { Happiness = 25 }, setFlags = { engaged = true }, feedText = "💍 They beat you to it! How romantic!" },
			{ text = "Wait for a better time", effects = { Happiness = -5 }, feedText = "Not yet. The timing will be right someday." },
		},
	},
	
	-- MIDLIFE REFLECTION
	{
		id = "midlife_reflection",
		title = "Midlife Reflection",
		emoji = "🪞",
		text = "Halfway through life. Time to reflect on what you've accomplished and what's still ahead.",
		question = "How do you feel about your life so far?",
		minAge = 40, maxAge = 50,
		baseChance = 0.5,
		oneTime = true,
		maxOccurrences = 1,
		choices = {
			{ text = "Proud of what I've built", effects = { Happiness = 15 }, setFlags = { content_with_life = true }, feedText = "Looking back with satisfaction. You've done well!" },
			{ text = "Time for a big change", effects = { Happiness = 10, Money = -10000 }, setFlags = { midlife_change = true }, feedText = "Bucket list time! New adventures await." },
			{ text = "Regret some choices", effects = { Happiness = -10 }, setFlags = { has_regrets = true }, feedText = "Some roads not taken still haunt you." },
			{ text = "Focus on what's ahead", effects = { Happiness = 8, Smarts = 5 }, setFlags = { forward_looking = true }, feedText = "The best is yet to come!" },
		},
	},
	
	-- UNEXPECTED INHERITANCE
	{
		id = "unexpected_inheritance",
		title = "Surprise Inheritance",
		emoji = "💰",
		text = "A distant relative you barely knew passed away and left you in their will!",
		question = "What did you inherit?",
		minAge = 25, maxAge = 70,
		baseChance = 0.15,
		oneTime = true,
		maxOccurrences = 1,
		choices = {
			{ text = "A substantial sum of money", effects = { Happiness = 20, Money = 100000 }, feedText = "💰 $100,000! Life-changing money!" },
			{ text = "A modest amount", effects = { Happiness = 10, Money = 15000 }, feedText = "💵 $15,000 - enough for something nice." },
			{ text = "A property in need of work", effects = { Happiness = 8, Money = -5000 }, setFlags = { inherited_property = true }, feedText = "🏚️ A fixer-upper. Could be worth it!" },
			{ text = "Just sentimental items", effects = { Happiness = 5 }, setFlags = { inherited_heirlooms = true }, feedText = "📦 Not valuable, but meaningful." },
		},
	},
	
	-- HEALTH SCARE
	{
		id = "adult_health_scare",
		title = "Health Scare",
		emoji = "🏥",
		text = "The doctor found something concerning during your routine checkup.",
		question = "What's the diagnosis?",
		minAge = 35, maxAge = 75,
		baseChance = 0.25,
		cooldown = 10,
		maxOccurrences = 2,
		choices = {
			{ text = "False alarm - nothing serious", effects = { Happiness = 10, Health = 5 }, feedText = "😮‍💨 What a relief! All clear." },
			{ text = "Caught early - very treatable", effects = { Happiness = -5, Health = -10, Money = -10000 }, setFlags = { health_survivor = true }, feedText = "Early detection saved you. Treatment successful!" },
			{ text = "Lifestyle changes needed", effects = { Happiness = -8, Health = 15 }, setFlags = { health_conscious = true }, feedText = "Wake-up call. Time to get serious about health." },
			{ text = "Long road ahead", effects = { Happiness = -20, Health = -25, Money = -50000 }, setFlags = { chronic_illness = true }, feedText = "This will be a journey. Stay strong." },
		},
	},
	
	-- FRIENDSHIP TEST
	{
		id = "friendship_test",
		title = "Friendship Test",
		emoji = "🤝",
		text = "Your best friend asks you for a significant favor that would put you out.",
		question = "What do you do?",
		minAge = 20, maxAge = 60,
		baseChance = 0.35,
		cooldown = 5,
		maxOccurrences = 3,
		choices = {
			{ text = "Help without hesitation", effects = { Happiness = 10, Money = -1000 }, setFlags = { loyal_friend = true }, feedText = "That's what friends are for. They'd do the same for you." },
			{ text = "Help, but set boundaries", effects = { Happiness = 5, Smarts = 3 }, feedText = "You helped within your limits. Fair balance." },
			{ text = "Decline - can't afford to right now", effects = { Happiness = -5 }, feedText = "They understand, but there's tension now." },
			{ text = "Ghost them instead of saying no", effects = { Happiness = -10 }, setFlags = { conflict_avoider = true }, feedText = "Avoiding the conversation made it worse." },
		},
	},
	
	-- EMPTY NEST
	{
		id = "empty_nest_moment",
		title = "Empty Nest",
		emoji = "🐣",
		text = "Your last child just moved out. The house feels so quiet now.",
		question = "How do you handle this new phase?",
		minAge = 45, maxAge = 65,
		baseChance = 0.5,
		oneTime = true,
		maxOccurrences = 1,
		requiresFlags = { has_children = true },
		choices = {
			{ text = "Rediscover yourself and hobbies", effects = { Happiness = 15 }, setFlags = { empty_nester = true, self_renewed = true }, feedText = "Freedom! Time to focus on YOU again." },
			{ text = "Struggle with the silence", effects = { Happiness = -15 }, setFlags = { empty_nester = true }, feedText = "It's harder than expected. You miss them." },
			{ text = "Renovate the house", effects = { Happiness = 10, Money = -20000 }, setFlags = { empty_nester = true }, feedText = "Finally turning that room into your dream space!" },
			{ text = "Plan more visits and trips to see them", effects = { Happiness = 8, Money = -2000 }, setFlags = { empty_nester = true }, feedText = "Distance doesn't mean disconnection." },
		},
	},
}

return Adult
