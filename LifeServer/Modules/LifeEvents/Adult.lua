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
				setFlags = { lives_alone = true, independent = true, renting = true, homeowner = false },
				feedText = "You got your own place! You're renting an apartment. Freedom!"
			},
			{
				text = "Find roommates",
				effects = { Happiness = 5, Money = -200 },
				setFlags = { has_roommates = true, renting = true, homeowner = false },
				feedText = "You moved in with roommates. You're renting. Cheaper but... interesting."
			},
			{
				text = "Stay home to save money",
				effects = { Money = 300, Happiness = -3 },
				setFlags = { lives_with_parents = true, renting = false, homeowner = false },
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
		requiresFlags = { college_bound = true },
		cooldown = 2,

		-- META
		stage = STAGE,
		ageBand = "young_adult",
		category = "education",
		milestoneKey = "ADULT_COLLEGE_EXPERIENCE",
		tags = { "college", "lifestyle" },
		careerTags = { "business" },

		-- Ensure player is enrolled in college when this fires
		onComplete = function(state)
			state.EducationData = state.EducationData or {}
			state.EducationData.Status = "enrolled"
			state.EducationData.Institution = "University"
			state.EducationData.Level = "pursuing_bachelor"

			state.Flags = state.Flags or {}
			state.Flags.in_college = true
		end,

		choices = {
			{
				text = "Study hard, get great grades",
				effects = { Smarts = 7, Happiness = -2, Health = -2 },
				setFlags = { honors_student = true, in_college = true },
				feedText = "You're crushing it academically!",
			},
			{
				text = "Balance academics and social life",
				effects = { Smarts = 4, Happiness = 5 },
				setFlags = { in_college = true },
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
		oneTime = true,
		requiresFlags = { college_bound = true },

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
		text = "After saving up and building your credit, you're finally ready to consider buying your first home. You've been looking at listings and talking to lenders.",
		question = "What's your approach?",
		minAge = 25, maxAge = 50,
		oneTime = true,
		-- Only trigger if player has enough money saved
		customValidation = function(state)
			local money = state.Money or 0
			local hasJob = state.CurrentJob ~= nil
			-- Need at least some savings and a job for mortgage approval
			return money >= 10000 and hasJob
		end,

		-- META
		stage = STAGE,
		ageBand = "adult_midlife",
		category = "housing",
		milestoneKey = "ADULT_BUYING_HOME",
		tags = { "property", "money_big", "stability" },

		choices = {
			{
				text = "Buy a starter home",
				effects = { Happiness = 10 },
				setFlags = { homeowner = true, has_property = true, renting = false },
				feedText = "You bought your first home! A big milestone!",
				onResolve = function(state)
					local EventEngine = require(script.Parent.init).EventEngine
					local homePrice = 85000
					local downPayment = math.floor(homePrice * 0.2) -- 20% down
					local money = state.Money or 0
					
					if money >= downPayment then
						state.Money = math.max(0, money - downPayment)
						if EventEngine and EventEngine.addAsset then
							EventEngine.addAsset(state, "property", {
								id = "starter_home_" .. tostring(state.Age or 0),
								name = "Starter Home",
								emoji = "🏠",
								price = homePrice,
								value = homePrice,
								income = 0,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then
							state:AddFeed("You put down $" .. downPayment .. " and got a mortgage for your starter home!")
						end
					else
						if state.AddFeed then
							state:AddFeed("You couldn't afford the down payment. You'll need to save more.")
						end
					end
				end,
			},
			{
				text = "Stretch for your dream home",
				effects = { Happiness = 15, Health = -3 },
				setFlags = { homeowner = true, has_property = true, high_mortgage = true, renting = false },
				feedText = "You got your dream home! But the mortgage is steep.",
				onResolve = function(state)
					local EventEngine = require(script.Parent.init).EventEngine
					local homePrice = 350000
					local downPayment = math.floor(homePrice * 0.15) -- 15% down (stretching)
					local money = state.Money or 0
					
					if money >= downPayment then
						state.Money = math.max(0, money - downPayment)
						if EventEngine and EventEngine.addAsset then
							EventEngine.addAsset(state, "property", {
								id = "dream_home_" .. tostring(state.Age or 0),
								name = "Dream Home",
								emoji = "🏡",
								price = homePrice,
								value = homePrice,
								income = 0,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then
							state:AddFeed("You stretched your budget and put down $" .. downPayment .. " on your dream home. The monthly payments will be tight!")
						end
					else
						if state.AddFeed then
							state:AddFeed("You couldn't afford the down payment. Dreams will have to wait.")
						end
					end
				end,
			},
			{
				text = "Keep renting for now",
				effects = { Money = 500 },
				setFlags = { renting = true, homeowner = false },
				feedText = "You'll rent a bit longer. More flexibility and less financial stress.",
			},
			{
				text = "Move to a cheaper area",
				effects = { Happiness = 5 },
				setFlags = { homeowner = true, has_property = true, relocated = true, renting = false },
				feedText = "You moved somewhere more affordable!",
				onResolve = function(state)
					local EventEngine = require(script.Parent.init).EventEngine
					local homePrice = 65000
					local downPayment = math.floor(homePrice * 0.2)
					local money = state.Money or 0
					
					if money >= downPayment then
						state.Money = math.max(0, money - downPayment)
						if EventEngine and EventEngine.addAsset then
							EventEngine.addAsset(state, "property", {
								id = "affordable_home_" .. tostring(state.Age or 0),
								name = "Affordable Home",
								emoji = "🏠",
								price = homePrice,
								value = homePrice,
								income = 0,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then
							state:AddFeed("You found an affordable home in a cheaper area! Down payment: $" .. downPayment)
						end
					else
						if state.AddFeed then
							state:AddFeed("Even the cheaper area was out of reach. Keep saving!")
						end
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
		text = "Retirement is on the horizon. Are you prepared?",
		question = "What's your retirement outlook?",
		minAge = 50, maxAge = 62,
		oneTime = true,

		-- META
		stage = STAGE,
		ageBand = "pre_senior",
		category = "money",
		milestoneKey = "ADULT_RETIREMENT_PLANNING",
		tags = { "retirement", "money_long_term" },

		choices = {
			{
				text = "Well prepared - saved consistently",
				effects = { Happiness = 10, Money = 5000 },
				setFlags = { retirement_ready = true },
				feedText = "Your years of saving paid off!"
			},
			{
				text = "Moderately prepared",
				effects = { Happiness = 5, Money = 1000 },
				setFlags = { retirement_possible = true },
				feedText = "You'll be okay, but not lavish."
			},
			{
				text = "Not at all - need to work longer",
				effects = { Happiness = -5 },
				setFlags = { must_keep_working = true },
				feedText = "Retirement will have to wait."
			},
			{
				text = "Planning early retirement",
				effects = { Happiness = 8, Money = -2000 },
				setFlags = { early_retirement = true },
				feedText = "You're cutting out early!"
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
				feedText = "Retirement is here! Time to relax."
			},
			{
				text = "Keep working part-time",
				effects = { Happiness = 5, Money = 500 },
				setFlags = { semi_retired = true },
				feedText = "You're staying active in the workforce."
			},
			{
				text = "Focus on hobbies and travel",
				effects = { Happiness = 12, Money = -1000 },
				feedText = "Time to enjoy life to the fullest!"
			},
			{
				text = "Dedicate time to family",
				effects = { Happiness = 8 },
				feedText = "Family becomes your focus."
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
}

return Adult
