--[[
    Adult Events (Ages 18+)
    Career, family, major life decisions

    Integrated with:
    - core milestones via `isMilestone` + milestoneKey
    - career catalog via `hintCareer` + event-level careerTags
    - tagging via `stage`, `ageBand`, `category`, `tags`
]]

-- CRITICAL FIX #ADULT-1: Add RANDOM definition for consistent random number generation
local RANDOM = Random.new()

local Adult = {}

local STAGE = "adult"

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: Helper to generate unique child names
-- User review: "the system keeps giving me children with the same name over and over again"
-- This expands name pools AND checks for duplicates
-- ═══════════════════════════════════════════════════════════════════════════════
local EXPANDED_BOY_NAMES = {
	"James", "Oliver", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Benjamin", "Henry", "Alexander",
	"Sebastian", "Jack", "Owen", "Daniel", "Michael", "William", "Aiden", "Jackson", "Logan", "Carter",
	"Matthew", "Ryan", "Nathan", "Caleb", "Dylan", "Isaac", "Leo", "Gabriel", "Joshua", "Andrew",
	"Theodore", "Thomas", "Charles", "Christopher", "Jaxon", "Anthony", "David", "Joseph", "John", "Luke"
}
local EXPANDED_GIRL_NAMES = {
	"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia", "Amelia", "Charlotte", "Harper", "Evelyn",
	"Abigail", "Emily", "Elizabeth", "Sofia", "Ella", "Madison", "Scarlett", "Victoria", "Aria", "Grace",
	"Chloe", "Camila", "Penelope", "Riley", "Layla", "Lillian", "Nora", "Zoey", "Mila", "Aubrey",
	"Hannah", "Lily", "Addison", "Eleanor", "Natalie", "Luna", "Savannah", "Brooklyn", "Leah", "Zoe"
}

local function getUniqueChildName(state, isBoy)
	local namePool = isBoy and EXPANDED_BOY_NAMES or EXPANDED_GIRL_NAMES
	
	-- Get existing child names to avoid duplicates
	local existingNames = {}
	if state.Relationships then
		for _, rel in pairs(state.Relationships) do
			if type(rel) == "table" and (rel.role == "Son" or rel.role == "Daughter") then
				if rel.name then
					existingNames[rel.name:lower()] = true
				end
			end
		end
	end
	
	-- Try to find unique name
	for attempt = 1, 100 do
		local candidate = namePool[math.random(1, #namePool)]
		if not existingNames[candidate:lower()] then
			return candidate
		end
	end
	
	-- If all names used, add a number suffix
	local baseName = namePool[math.random(1, #namePool)]
	return baseName .. " Jr."
end

Adult.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- YOUNG ADULT (18-29)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "adult_moving_out",  -- CRITICAL FIX: Renamed to avoid duplicate ID with Milestones.lua
		title = "Time to Leave the Nest",
		emoji = "🏠",
		-- CRITICAL FIX: Better text explaining the financial implications
		text = "You're considering moving out of your parents' house. Getting your own place means rent, bills, and responsibility!",
		-- CRITICAL FIX: Added text variations for moving out scenarios!
		textVariants = {
			"Your parents have been hinting that maybe it's time to get your own place.",
			"You're an adult now. Living with mom and dad is getting awkward.",
			"All your friends have their own apartments. You're still in your childhood room.",
			"The tension at home is real. You need your own space.",
			"You got a job. You have savings. Time to spread your wings?",
			"Your parents found your... personal items. It's time to move out. NOW.",
		},
		question = "What's your plan?",
		minAge = 18, maxAge = 24,
		oneTime = true,
		-- CRITICAL FIX: Can't move out from prison or if already moved out!
		blockedByFlags = { 
			in_prison = true, 
			incarcerated = true,
			moved_out = true,        -- Already moved out
			has_own_place = true,    -- Already has own place
			has_apartment = true,    -- Already has apartment
			homeless = true,         -- Homeless people can't "move out"
		},
		
		-- CRITICAL FIX: Must be able to afford rent! No more broke people moving out!
		eligibility = function(state)
			local money = state.Money or 0
			-- Need at least $1000 to move out (first month rent + deposit)
			if money < 1000 then
				return false, "You need at least $1,000 saved to move out (first month + deposit)!"
			end
			-- Must have a job OR significant savings to afford rent
			local hasJob = state.CurrentJob ~= nil
			if not hasJob and money < 5000 then
				return false, "Without a job, you need at least $5,000 saved to move out!"
			end
			return true
		end,

		-- META
		stage = STAGE,
		ageBand = "young_adult",
		category = "housing",
		milestoneKey = "ADULT_MOVING_OUT",
		tags = { "independence", "family", "money" },

		choices = {
			{
				text = "Get my own apartment ($500 deposit)",
				effects = { Happiness = 10, Money = -500 },
				-- CRITICAL FIX #SOFTLOCK: Add eligibility check to prevent game-breaking bug!
				-- User bug: "IT SAYS MOVING OUT YOUR OWN PLACE! BUT DIDNT CHECK IF IM BROKE"
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 You need at least $500 for deposit! Save up first." end,
				-- CRITICAL FIX: Set ALL the housing flags that other systems check for!
				-- AssetsScreen checks: has_apartment, renting, moved_out, has_own_place
				-- Homeless events check: moved_out, has_own_place, renting, has_apartment
				setFlags = { 
					lives_alone = true, 
					independent = true,
					moved_out = true,        -- CRITICAL: Marks player as moved out
					has_own_place = true,    -- CRITICAL: Has their own housing
					has_apartment = true,    -- CRITICAL: Specifically an apartment
					renting = true,          -- CRITICAL: They're renting (affects expenses)
				},
				feedText = "You got your own place! Freedom! But remember - rent is due monthly...",
				-- CRITICAL FIX: Initialize HousingState properly
				onResolve = function(state)
					state.HousingState = state.HousingState or {}
					state.HousingState.status = "renter"
					state.HousingState.type = "apartment"
					state.HousingState.rent = 900 -- Basic apartment rent
					state.HousingState.yearsWithoutPayingRent = 0
					state.HousingState.missedRentYears = 0
					state.HousingState.moveInYear = state.Year or 2025
					-- Clear living with parents flag
					state.Flags.living_with_parents = nil
					state:AddFeed("🔑 Welcome to adulthood! Your rent is $900/month. Better get a job!")
				end,
			},
			{
				text = "Find roommates ($200 deposit)",
				effects = { Happiness = 5, Money = -200 },
				-- CRITICAL FIX #SOFTLOCK: Add eligibility check!
				eligibility = function(state) return (state.Money or 0) >= 200, "💸 You need at least $200 for your share of deposit!" end,
				-- CRITICAL FIX: Roommates still means moved out!
				setFlags = { 
					has_roommates = true,
					moved_out = true,
					has_own_place = true,
					has_apartment = true,
					renting = true,
				},
				feedText = "You moved in with roommates. Cheaper but... interesting.",
				onResolve = function(state)
					state.HousingState = state.HousingState or {}
					state.HousingState.status = "renter"
					state.HousingState.type = "shared_apartment"
					state.HousingState.rent = 500 -- Cheaper with roommates
					state.HousingState.yearsWithoutPayingRent = 0
					state.HousingState.missedRentYears = 0
					state.HousingState.moveInYear = state.Year or 2025
					state.Flags.living_with_parents = nil
					state:AddFeed("🏠 Your share of rent is $500/month. Roommates can be... unpredictable.")
				end,
			},
			{
				text = "Stay home to save money",
				effects = { Money = 300, Happiness = -3 },
				-- CRITICAL FIX: Explicitly mark as still with parents
				setFlags = { 
					living_with_parents = true,
					-- CRITICAL: Do NOT set moved_out, has_apartment, etc.
				},
				feedText = "You're staying home. Smart financially, but maybe a bit cramped.",
				-- ═══════════════════════════════════════════════════════════════════════════════
				-- CRITICAL FIX: Can't stay with parents if they're dead!
				-- User complaint: "IT SAYS LIVING WITH PARENTS BUT MY PARENTS ARE DEAD"
				-- ═══════════════════════════════════════════════════════════════════════════════
				eligibility = function(state)
					local flags = state.Flags or {}
					-- Check if both parents are dead
					if flags.orphan or flags.lost_both_parents then
						return false, "Your parents have passed away"
					end
					-- Check Relationships for living parents
					if state.Relationships then
						local hasLivingParent = false
						for id, rel in pairs(state.Relationships) do
							if rel and (rel.role == "Mother" or rel.role == "Father" or rel.type == "parent") then
								if rel.alive ~= false and rel.deceased ~= true then
									hasLivingParent = true
									break
								end
							end
						end
						if not hasLivingParent then
							return false, "Your parents have passed away"
						end
					end
					return true
				end,
				onResolve = function(state)
					state.HousingState = state.HousingState or {}
					state.HousingState.status = "with_parents"
					state.HousingState.rent = 0 -- No rent with parents
					state.HousingState.yearsWithoutPayingRent = 0
					-- Clear any moved out flags
					state.Flags.moved_out = nil
					state.Flags.has_own_place = nil
					state.Flags.has_apartment = nil
					state.Flags.renting = nil
				end,
			},
		},
	},

	{
		id = "college_experience",
		title = "College Life",
		emoji = "📚",
		-- CRITICAL FIX #FUN-7: Added text variations for college experience!
		textVariants = {
			"College is a WHOLE NEW WORLD! No parents, no curfew, instant ramen for every meal. Freedom tastes weird. You're responsible for yourself now. This is terrifying and amazing.",
			"Your dorm room is tiny, your roommate snores, and the dining hall closes at 8pm. But somehow? This is the best time of your life. College is WILD.",
			"First week of college: lost on campus 12 times, went to the wrong lecture hall twice, made 3 friends and 1 enemy. This is going to be interesting.",
			"The university campus is HUGE. You've gotten lost every day this week. The library has 8 floors. Your professor has a Nobel Prize. What are you even doing here?!",
			"College! Where sleep is optional, coffee is mandatory, and everyone pretends to have their life together. You're fitting right in by also pretending.",
			"Your classes started and you're already behind on the reading. But you've also joined 5 clubs, gone to 3 parties, and made friends from 4 different countries. Priorities!",
			"The transition to college hit you like a truck. Suddenly you're cooking (burning) your own food, doing your own laundry (everything is pink now), and managing your own time (poorly).",
			"COLLEGE! Your parents dropped you off with tears in their eyes. You walked into your dorm, looked around, and thought: 'I have absolutely no idea what I'm doing.' Perfect.",
		},
		text = "College is a whole new world of experiences.",
		questionVariants = {
			"What's your focus?",
			"How are you approaching college?",
			"What's your college strategy?",
		},
		question = "What's your focus?",
		minAge = 18, maxAge = 22,
		baseChance = 0.4, -- CRITICAL FIX: Reduced from 0.7 to prevent spam
		-- CRITICAL FIX #516: Accept MULTIPLE flags for college eligibility
		-- Was only checking college_bound but user could have in_college, enrolled_college, etc.
		eligibility = function(state)
			if not state.Flags then return false end
			return state.Flags.college_bound or state.Flags.in_college or 
			       state.Flags.enrolled_college or state.Flags.college_student or
			       (state.EducationData and state.EducationData.Status == "enrolled")
		end,
		cooldown = 5, -- CRITICAL FIX: Increased from 1 to prevent spam

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
				text = "Study hard - Dean's List or bust! 📖",
				effects = { Smarts = 7, Happiness = -2, Health = -2 },
				setFlags = { honors_student = true, in_college = true, college_student = true },
				feedText = "Library until 2am. Flashcards for breakfast. Your GPA is looking STELLAR!",
			},
			{
				text = "Balance academics and social life ⚖️",
				effects = { Smarts = 4, Happiness = 5 },
				setFlags = { in_college = true, college_student = true, balanced_college = true },
				feedText = "Study during the week, party on weekends. This is the way. You're living your best college life!",
			},
			{
				text = "Party now, worry about grades later 🎉",
				effects = { Happiness = 8, Smarts = -2, Health = -3 },
				setFlags = { party_animal = true, in_college = true },
				feedText = "You know every frat house, every party playlist, every 3am pizza spot. Academics? Those are future you's problem.",
			},
			{
				text = "Focus on networking and internships 💼",
				effects = { Smarts = 3, Money = 150 },
				setFlags = { career_focused = true, in_college = true },
				hintCareer = "business",
				feedText = "LinkedIn profile is POLISHED. Three internships lined up. You're thinking ahead!",
			},
			{
				text = "Join every club possible! 🎭",
				effects = { Happiness = 6, Smarts = 2, Health = -1 },
				setFlags = { extracurricular_king = true, in_college = true },
				feedText = "Debate club, gaming club, chess club, ultimate frisbee, a cappella... you're EVERYWHERE!",
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
		baseChance = 0.6, -- CRITICAL FIX: Reduced from 0.8 to prevent spam
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
				text = "Keep renting for now",
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
		cooldown = 8,
		oneTime = true, -- CRITICAL FIX: Only once!

		-- META
		stage = STAGE,
		ageBand = "adult_midlife",
		category = "health",
		tags = { "doctor", "lifestyle", "midlife" },
		
		-- CRITICAL FIX #806: Only show if health is actually concerning!
		-- User complaint: Health wake-up call showing when already healthy
		eligibility = function(state)
			local health = (state.Stats and state.Stats.Health) or state.Health or 50
			-- Only show if health is below 65 at midlife
			if health >= 75 then
				return false, "Player is healthy - no wake-up call needed"
			end
			return true
		end,
		blockedByFlags = { midlife_health_done = true },
		
		-- Dynamic text based on actual health
		getDynamicText = function(state)
			local health = (state.Stats and state.Stats.Health) or state.Health or 50
			local text
			if health < 40 then
				text = string.format("Your checkup results are concerning. At %d%% health, the doctor says major changes are needed.", math.floor(health))
			elseif health < 55 then
				text = string.format("A routine checkup reveals some issues. %d%% health at your age needs attention.", math.floor(health))
			else
				text = "A routine checkup reveals you could be doing better. Some preventive changes would help."
			end
			return { text = text, currentHealth = health }
		end,

		choices = {
		{
			text = "Complete lifestyle overhaul ($500)",
			effects = { Health = 15, Happiness = 5, Money = -500 },
			setFlags = { health_conscious = true, midlife_health_done = true },
			feedText = "You transformed your lifestyle. Feeling great!",
			eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for lifestyle changes" end,
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or state.Health or 50
					if health < 40 then
						state:ModifyStat("Health", 20) -- Extra boost for very unhealthy
						state:AddFeed("🏥 Major transformation! You feel like a new person!")
					end
				end,
			},
			{
				text = "Make gradual improvements",
				effects = { Health = 8, Happiness = 3 },
				setFlags = { midlife_health_done = true },
				feedText = "You're making steady health improvements."
			},
			{
				text = "Ignore it and hope for the best",
				effects = { Health = -10, Happiness = -5 },
				setFlags = { midlife_health_done = true, ignores_health = true },
				feedText = "You ignored the warning signs..."
			},
		{
			text = "Become obsessive about health ($1,000)",
			effects = { Health = 10, Happiness = -5, Money = -1000 },
			setFlags = { health_obsessed = true, midlife_health_done = true },
			feedText = "Health became your entire focus. Maybe too much.",
			eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Need $1,000 for health obsession" end,
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
			text = "Get a full retirement assessment ($200)",
			effects = { Money = -200 },
			feedText = "The advisor runs the numbers...",
			eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for assessment" end,
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
			text = "Focus on hobbies and travel ($1,000)",
			effects = { Happiness = 12, Money = -1000 },
			setFlags = { retired = true },
			feedText = "Time to enjoy life to the fullest! Your pension awaits.",
			eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Need $1,000 for travel" end,
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
				-- CRITICAL FIX #5: Only show this choice if player actually has family
				eligibility = function(state)
					local flags = state.Flags or {}
					-- Check for spouse/partner
					if flags.married or flags.has_partner then
						return true
					end
					-- Check for children
					if flags.has_child or flags.parent then
						return true
					end
					-- Check Relationships table
					if state.Relationships then
						if state.Relationships.partner then return true end
						for id, rel in pairs(state.Relationships) do
							if type(rel) == "table" and (rel.isChild or rel.type == "family") then
								return true
							end
						end
					end
					return false, "Need family to dedicate time to"
				end,
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
		baseChance = 0.35,
		cooldown = 5,

		-- META
		stage = STAGE,
		ageBand = "senior",
		category = "health",
		tags = { "aging", "doctor", "health_risk" },

	choices = {
		{
			text = "Follow doctor's orders carefully ($500)",
			effects = { Health = 5, Money = -500 },
			feedText = "You're taking good care of yourself.",
			eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for medical care" end,
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
		baseChance = 0.35,
		cooldown = 5, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresFlags = { lives_alone = true },

		choices = {
			{ text = "Noisy neighbors keep you up", effects = { Health = -3, Happiness = -4 }, feedText = "Sleep deprivation is real. These walls are paper thin." },
		{ text = "Pests - roaches or mice!", effects = { Happiness = -6, Health = -2 }, feedText = "Gross! Had to deal with an infestation." },
		{ text = "Landlord won't fix anything", effects = { Happiness = -4 }, setFlags = { bad_landlord = true }, feedText = "Frustrating! Nothing ever gets fixed." },
		{ text = "Minor annoyances", effects = { Happiness = -2 }, feedText = "Small complaints but nothing major." },
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
		cooldown = 5, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresFlags = { has_roommates = true },
		-- CRITICAL FIX: Can't have roommate drama from prison!
		blockedByFlags = { in_prison = true, incarcerated = true },

		choices = {
			{ text = "They never clean", effects = { Happiness = -4, Health = -2 }, feedText = "Living in filth because they won't do dishes." },
			{ text = "They eat my food", effects = { Happiness = -3 }, feedText = "Your groceries keep disappearing." },
			{ text = "They're too loud", effects = { Happiness = -3, Health = -2 }, setFlags = { poor_sleep = true }, feedText = "Parties every night. You're exhausted." },
			{ text = "We're actually great friends!", effects = { Happiness = 6 }, setFlags = { good_roommates = true }, feedText = "Living together strengthened your friendship!" },
			{ text = "Time to move out ($300)", effects = { Money = -300, Happiness = 3 }, setFlags = { lives_alone = true }, feedText = "You got your own place. Peace at last.", eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 deposit to move out" end },
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
		baseChance = 0.35,
		cooldown = 5,
		requiresFlags = { has_degree = true },

		choices = {
			{ text = "Paying minimum - will take forever", effects = { Happiness = -3 }, feedText = "You'll be paying this for decades." },
			{ text = "Aggressively paying them down", effects = { Happiness = -2, Smarts = 2 }, setFlags = { debt_focused = true }, feedText = "Living frugally to eliminate the debt faster." },
			{ text = "Looking into loan forgiveness", effects = { Smarts = 2 }, setFlags = { public_service = true }, feedText = "Maybe public service can help." },
			{ text = "Defaulted... oops", effects = { Happiness = -8 }, setFlags = { bad_credit = true }, feedText = "Your credit is destroyed. Big mistake." },
		},
	},
	{
		id = "dating_apps",
		title = "The Dating App Life",
		emoji = "📱",
		text = "You've entered the world of dating apps.",
		question = "How's your experience?",
		minAge = 20, maxAge = 40,
		baseChance = 0.35,
		cooldown = 5, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresSingle = true,
		blockedByFlags = { married = true, in_prison = true, incarcerated = true },

		choices = {
			{ text = "Tons of matches, no connections", effects = { Happiness = -3 }, feedText = "Quantity over quality. Modern dating is exhausting." },
			{ 
				text = "Found someone amazing!", 
				effects = { Happiness = 10 }, 
				setFlags = { has_partner = true, met_online = true, dating = true }, 
				feedText = "Swipe right turned into real love!",
				-- CRITICAL FIX #2008: Partner gender based on PLAYER gender!
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					-- BUG FIX: Normalize gender to lowercase for comparison
					local playerGender = (state.Gender or "male"):lower()
					local partnerIsMale = (playerGender == "female")
					local names = partnerIsMale 
						and {"Mike", "Chris", "Jason", "Brian", "Matt", "Steve", "Dave", "Tom", "Nick", "Ben"}
						or {"Jessica", "Ashley", "Sarah", "Emily", "Lauren", "Amanda", "Megan", "Nicole", "Brittany", "Rachel"}
					local partnerName = names[math.random(1, #names)] or "Someone"
					state.Relationships.partner = {
						id = "partner",
						name = partnerName,
						type = "romantic",
						role = partnerIsMale and "Boyfriend" or "Girlfriend",
						relationship = 70,
						age = (state.Age or 25) + math.random(-5, 5),
						gender = partnerIsMale and "male" or "female",
						alive = true,
						metThrough = "dating_app",
					}
					if state.AddFeed then
						state:AddFeed(string.format("📱 Swipe right on %s turned into real love!", tostring(partnerName)))
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
		-- CRITICAL FIX: Removed money check - event has "Super simple" free option
		eligibility = function(state)
			return true
		end,

		choices = {
			{ 
				text = "Big traditional wedding ($15,000)", 
				effects = { Money = -15000, Happiness = 12 },
				setFlags = { married = true, big_wedding = true }, 
				eligibility = function(state) return (state.Money or 0) >= 15000, "💸 Need $15,000 for big wedding" end,
				feedText = "💒 A beautiful wedding! Your wallet hurts but it was worth it!",
				onResolve = function(state)
					-- Update partner to spouse
					if state.Relationships and state.Relationships.partner then
						local partnerGender = state.Relationships.partner.gender or "female"
						state.Relationships.partner.role = (partnerGender == "female") and "Wife" or "Husband"
						state.Relationships.partner.isSpouse = true
						state.Relationships.partner.married = true
						state.Relationships.partner.type = "spouse"
					end
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
				end,
			},
			{ 
				text = "Small intimate ceremony ($3,000)", 
				effects = { Money = -3000, Happiness = 10 },
				setFlags = { married = true }, 
				eligibility = function(state) return (state.Money or 0) >= 3000, "💸 Need $3,000 for intimate ceremony" end,
				feedText = "💒 Just close friends and family. Perfect!",
				onResolve = function(state)
					if state.Relationships and state.Relationships.partner then
						local partnerGender = state.Relationships.partner.gender or "female"
						state.Relationships.partner.role = (partnerGender == "female") and "Wife" or "Husband"
						state.Relationships.partner.isSpouse = true
						state.Relationships.partner.married = true
						state.Relationships.partner.type = "spouse"
					end
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
				end,
			},
			{ 
				text = "Destination wedding ($10,000)", 
				effects = { Money = -10000, Happiness = 14, Health = 3 },
				setFlags = { married = true, destination_wedding = true }, 
				eligibility = function(state) return (state.Money or 0) >= 10000, "💸 Need $10,000 for destination wedding" end,
				feedText = "🏝️ Getting married on a beach was magical!",
				onResolve = function(state)
					if state.Relationships and state.Relationships.partner then
						local partnerGender = state.Relationships.partner.gender or "female"
						state.Relationships.partner.role = (partnerGender == "female") and "Wife" or "Husband"
						state.Relationships.partner.isSpouse = true
						state.Relationships.partner.married = true
						state.Relationships.partner.type = "spouse"
					end
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
				end,
			},
	{ 
		text = "Courthouse and save the money ($100)",
			effects = { Happiness = 5, Money = -100 }, 
			setFlags = { married = true, practical_wedding = true }, 
			feedText = "Quick and easy. More money for the honeymoon!",
			eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for courthouse fee" end,
		onResolve = function(state)
				if state.Relationships and state.Relationships.partner then
					local partnerGender = state.Relationships.partner.gender or "female"
					state.Relationships.partner.role = (partnerGender == "female") and "Wife" or "Husband"
					state.Relationships.partner.isSpouse = true
					state.Relationships.partner.married = true
					state.Relationships.partner.type = "spouse"
				end
				state.Flags = state.Flags or {}
				state.Flags.engaged = nil
			end,
		},
	{ 
		text = "Super simple - just sign the papers",
			effects = { Happiness = 3 }, 
			setFlags = { married = true, simple_wedding = true }, 
			feedText = "💍 Just the two of you. A signature, a kiss, and you're married! No frills needed.",
		onResolve = function(state)
				if state.Relationships and state.Relationships.partner then
					local partnerGender = state.Relationships.partner.gender or "female"
					state.Relationships.partner.role = (partnerGender == "female") and "Wife" or "Husband"
					state.Relationships.partner.isSpouse = true
					state.Relationships.partner.married = true
					state.Relationships.partner.type = "spouse"
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
		-- CRITICAL FIX: Must have partner AND be trying for baby - user reported baby without partner!
		requiresPartner = true,
		requiresFlags = { trying_for_baby = true },

		choices = {
			{ 
				text = "It's exhausting but amazing", 
				effects = { Happiness = 10, Health = -5 }, 
				setFlags = { has_child = true, parent = true }, 
				feedText = "Sleep is a distant memory but you're in love.",
				eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Need $1,000 for baby supplies" end,
				-- CRITICAL FIX: Create actual child in Relationships table
				-- CRITICAL FIX: Use helper function to avoid duplicate child names
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local childName = getUniqueChildName(state, isBoy)
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
				effects = { Happiness = 2, Health = -8 }, 
				setFlags = { has_child = true, parent = true, overwhelmed_parent = true }, 
				feedText = "This is harder than you imagined.",
				eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Need $1,000 for baby supplies" end,
				-- CRITICAL FIX: Use helper function to avoid duplicate child names
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local childName = getUniqueChildName(state, isBoy)
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
				effects = { Happiness = 15, Health = -3 }, 
				setFlags = { has_child = true, parent = true, natural_parent = true }, 
				feedText = "You were born for this!",
				eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Need $1,000 for baby supplies" end,
				-- CRITICAL FIX: Use helper function to avoid duplicate child names
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local childName = getUniqueChildName(state, isBoy)
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
				effects = { Happiness = 5 }, 
				setFlags = { has_child = true, parent = true }, 
				feedText = "You're not pulling your weight...",
				eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Need $1,000 for baby supplies" end,
				onResolve = function(state)
					state.Money = math.max(0, (state.Money or 0) - 1000)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local childName = getUniqueChildName(state, isBoy)
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
			-- CRITICAL FIX: FREE option for broke players!
			{ 
				text = "Family helped with everything!", 
				effects = { Happiness = 12, Health = -4 }, 
				setFlags = { has_child = true, parent = true, family_support = true }, 
				feedText = "👶 Baby shower gifts, hand-me-downs, and grandparents pitching in! Community stepped up BIG!",
				-- CRITICAL FIX: Use helper function to avoid duplicate child names
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local childName = getUniqueChildName(state, isBoy)
					local childId = "child_" .. tostring(childCount)
					state.Relationships[childId] = {
						id = childId,
						name = childName,
						type = "family",
						role = isBoy and "Son" or "Daughter",
						relationship = 95,
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
		cooldown = 5,
		requiresJob = true, -- CRITICAL FIX: Only show for employed players!

	choices = {
		{ text = "Chase the promotion", effects = { Money = 1000, Happiness = -3, Health = -3 }, setFlags = { workaholic = true }, hintCareer = "management", feedText = "You're climbing the ladder. At what cost?" },
		{ text = "Start my own business ($5,000)", effects = { Money = -5000, Happiness = 5 }, setFlags = { entrepreneur = true }, hintCareer = "business", feedText = "You took the entrepreneurial leap!", eligibility = function(state) return (state.Money or 0) >= 5000, "Need $5K for startup" end },
		{ text = "Change careers entirely ($1,000)", effects = { Happiness = 8, Money = -1000, Smarts = 5 }, setFlags = { career_changer = true }, feedText = "A fresh start in a new field!", eligibility = function(state) return (state.Money or 0) >= 1000, "Need $1K for retraining" end },
		{ text = "Stay the course - stability is fine", effects = { Happiness = 2 }, feedText = "Sometimes the best move is no move. You're content." },
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
		cooldown = 5, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresJob = true, -- CRITICAL FIX: Only show for employed players!

		choices = {
			{ text = "Try to work it out professionally", effects = { Smarts = 3, Happiness = 2 }, feedText = "You handled it maturely. Conflict resolved." },
			{ text = "Take it to HR", effects = { Happiness = -2 }, setFlags = { hr_involved = true }, feedText = "HR is now involved. Things got formal." },
			{ text = "Confront them directly", effects = { Happiness = -4 }, setFlags = { confrontational = true }, feedText = "The confrontation didn't go well." },
			{ text = "Just avoid them", effects = { Happiness = -2 }, feedText = "The tension remains but you're coexisting." },
			{ text = "Quit over it", effects = { Happiness = 3 }, feedText = "Life's too short. You left for a new opportunity." },
		},
	},
	{
		id = "big_promotion",
		title = "The Big Promotion",
		emoji = "📈",
		text = "You've been offered a major promotion at {{COMPANY}}!",
		question = "What's the catch?",
		minAge = 28, maxAge = 55,
		baseChance = 0.15, -- CRITICAL FIX: Further reduced - too many promotion events!
		cooldown = 10, -- CRITICAL FIX: Increased to prevent spam
		maxOccurrences = 2,
		requiresJob = true,
		-- CRITICAL FIX: Block if recently promoted from ANY event!
		blockedByFlags = { recently_promoted = true, just_got_raise = true },

		choices = {
			{ 
				text = "Step up and lead!", 
				effects = { Happiness = 5, Health = -3 }, 
				-- CRITICAL FIX: Add recently_promoted to prevent spam
				setFlags = { senior_position = true, promoted = true, recently_promoted = true }, 
				feedText = "You're moving up! The pressure is on.",
				onResolve = function(state)
					if state.CurrentJob and state.CurrentJob.salary then
						local raiseAmount = math.floor(state.CurrentJob.salary * 0.25) -- 25% raise
						state.CurrentJob.salary = state.CurrentJob.salary + raiseAmount
						state.Money = (state.Money or 0) + 3000 -- Signing bonus
						state.CareerInfo = state.CareerInfo or {}
						state.CareerInfo.promotions = (state.CareerInfo.promotions or 0) + 1
						state.CareerInfo.raises = (state.CareerInfo.raises or 0) + 1
						-- Set recently_promoted flag to block other promotion events
						state.Flags = state.Flags or {}
						state.Flags.recently_promoted = true
						if state.AddFeed then
							state:AddFeed(string.format("📈 PROMOTED! Salary now $%d (+25%%)!", state.CurrentJob.salary or 0))
						end
					end
				end,
			},
			{ 
				text = "Take it - requires relocating", 
				effects = { Happiness = -3 }, 
				setFlags = { relocated = true, promoted = true, recently_promoted = true }, 
				feedText = "You moved for the job. Big change.",
				onResolve = function(state)
					if state.CurrentJob and state.CurrentJob.salary then
						local raiseAmount = math.floor(state.CurrentJob.salary * 0.20) -- 20% raise
						state.CurrentJob.salary = state.CurrentJob.salary + raiseAmount
						state.Money = (state.Money or 0) + 2500 -- Relocation bonus
						state.CareerInfo = state.CareerInfo or {}
						state.CareerInfo.promotions = (state.CareerInfo.promotions or 0) + 1
						if state.AddFeed then
							state:AddFeed(string.format("📈 Relocated for the promotion! New salary: $%d", state.CurrentJob.salary or 0))
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
							state:AddFeed(string.format("📈 Manager now! Salary: $%d. Time to lead.", state.CurrentJob.salary or 0))
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
		cooldown = 5, -- CRITICAL FIX #705: Reduced from 5 for more variety
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
				text = "Buy a sports car ($10,000)", 
				effects = { Money = -10000, Happiness = 8 },
				setFlags = { midlife_crisis = true, has_car = true }, 
				eligibility = function(state) return (state.Money or 0) >= 10000, "💸 Need $10,000 for sports car" end,
				feedText = "🏎️ Bought a sports car! Feeling alive!",
				onResolve = function(state)
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
				end 
			},
			{ 
				text = "Treat yourself to something nice ($3,000)", 
				effects = { Money = -3000, Happiness = 5 },
				setFlags = { midlife_crisis = true }, 
				eligibility = function(state) return (state.Money or 0) >= 3000, "💸 Need $3,000" end,
				feedText = "🛍️ Bought something expensive. Retail therapy!",
			},
			{ text = "Have an affair", effects = { Happiness = 5 }, setFlags = { cheater = true, affair = true }, feedText = "You made a terrible decision..." },
			{ 
				text = "Make a dramatic career change", 
				effects = { Happiness = 10 },
				setFlags = { career_reinvented = true }, 
				feedText = "🔄 You quit to pursue your dream! Time for a fresh start!",
			},
			{ 
				text = "Go to therapy", 
				effects = { Happiness = 8, Smarts = 3 },
				setFlags = { in_therapy = true }, 
				feedText = "🧠 Therapy is helping you find clarity and peace!",
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
		{ text = "Amicable split ($5,000)", effects = { Happiness = -10, Money = -5000 }, setFlags = { divorced = true, recently_single = true }, feedText = "You parted ways peacefully. Still hurts.",
			eligibility = function(state) return (state.Money or 0) >= 5000, "Can't afford settlement" end,
		},
		{ text = "Bitter court battle ($20,000)", effects = { Happiness = -20, Money = -20000, Health = -5 }, setFlags = { divorced = true, messy_divorce = true, recently_single = true }, feedText = "The divorce was ugly and expensive.",
			eligibility = function(state) return (state.Money or 0) >= 20000, "Can't afford lawyers" end,
		},
		{ text = "Separate quietly - minimal costs", effects = { Happiness = -12, Health = -3 }, setFlags = { divorced = true, recently_single = true }, feedText = "No lawyers, just signed papers. Walked away with nothing." },
		{ text = "They cheated - take what you can", effects = { Happiness = -25, Money = 2000, Health = -5 }, setFlags = { divorced = true, cheated_on = true, recently_single = true }, feedText = "Betrayal. At least you got some compensation." },
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
			-- CRITICAL FIX: Partner choice needs eligibility check
			{ 
				text = "Freedom! Time for us again", 
				effects = { Happiness = 10 }, 
				setFlags = { empty_nester = true }, 
				feedText = "Rediscovering each other and enjoying the quiet!",
				eligibility = function(state)
					local flags = state.Flags or {}
					return flags.has_partner or flags.married
				end,
			},
			{ text = "Proud of the adult they became", effects = { Happiness = 8 }, setFlags = { empty_nester = true, proud_parent = true }, feedText = "You raised them well. They're thriving." },
			{ text = "Turning their room into something fun ($500)", effects = { Happiness = 6, Money = -500 }, setFlags = { empty_nester = true }, feedText = "Home gym? Art studio? The possibilities!", eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for renovation" end },
		},
	},
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Parent Death Event - Parents should realistically die!
	-- User complaint: "IM 69 YEARS OLD AND MY PARENTS ARE STILL ALIVE?!"
	-- This event triggers when parents would realistically pass away
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "parent_passes_away",
		title = "Losing a Parent",
		emoji = "💔",
		text = "You've received devastating news. One of your parents has passed away.",
		question = "You have to say goodbye...",
		minAge = 40, maxAge = 80,
		baseChance = 0.40,
		cooldown = 5,
		priority = "high",
		isMilestone = true,
		
		eligibility = function(state)
			local flags = state.Flags or {}
			local age = state.Age or 0
			
			-- If both parents already dead, don't trigger
			if flags.lost_both_parents or flags.orphan then
				return false
			end
			
			-- Estimate parent age (assuming parents are 25-35 years older)
			local parentAgeGap = 30
			local parentAge = age + parentAgeGap
			
			-- Parents realistically start dying around 70+
			-- Higher chance as parent age increases
			if parentAge < 65 then
				return false -- Parents too young to die of natural causes typically
			end
			
			-- Increase chance based on parent age
			local deathChance = 0
			if parentAge >= 90 then
				deathChance = 70 -- Very high chance at 90+
			elseif parentAge >= 85 then
				deathChance = 50
			elseif parentAge >= 80 then
				deathChance = 35
			elseif parentAge >= 75 then
				deathChance = 20
			elseif parentAge >= 70 then
				deathChance = 10
			elseif parentAge >= 65 then
				deathChance = 5
			end
			
			-- Roll to see if event should trigger
			return math.random(100) <= deathChance
		end,
		
		choices = {
			{
				text = "Be there for the funeral",
				effects = { Happiness = -25, Health = -5 },
				setFlags = { lost_parent = true, grieving = true },
				feedText = "💔 Your parent is gone. You'll never forget them.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					-- Check if this is second parent loss
					if state.Flags.lost_parent then
						state.Flags.lost_both_parents = true
						state.Flags.orphan = true
						state:AddFeed("💔 Both parents gone now. You feel truly alone in the world.")
					end
				end,
			},
			{
				text = "Celebrate their life",
				effects = { Happiness = -15, Health = -2, Smarts = 3 },
				setFlags = { lost_parent = true },
				feedText = "💔 Gone but never forgotten. Their memory lives on in you.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					if state.Flags.lost_parent then
						state.Flags.lost_both_parents = true
					end
				end,
			},
		},
	},
	{
		id = "parent_health_crisis",
		title = "Parent's Health Crisis",
		emoji = "🏥",
		text = "One of your parents is having serious health problems.",
		question = "How do you respond?",
		minAge = 35, maxAge = 70, -- Extended age range
		baseChance = 0.35,
		cooldown = 5,
		
		-- CRITICAL FIX #8: Parent health crisis requires living parents!
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Check if parents are deceased
			if flags.lost_both_parents or flags.orphan then
				return false
			end
			-- Check Relationships for living parents
			if state.Relationships then
				local hasLivingParent = false
				for id, rel in pairs(state.Relationships) do
					if type(rel) == "table" then
						local role = (rel.role or ""):lower()
						if (role == "mother" or role == "father" or role == "parent") and rel.alive ~= false then
							hasLivingParent = true
							break
						end
					end
				end
				if state.Relationships.mother or state.Relationships.father then
					return true -- Default assume parents exist
				end
				return hasLivingParent
			end
			-- Default to true if no flags indicate deceased parents
			return not flags.lost_parent
		end,

		choices = {
			{ text = "Become their primary caregiver ($2,000)", effects = { Happiness = -10, Health = -8, Money = -2000 }, setFlags = { family_caregiver = true }, feedText = "You've taken on a huge responsibility.", eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Need $2,000 for care expenses" end },
			{ text = "Help coordinate their care ($1,000)", effects = { Happiness = -5, Money = -1000 }, feedText = "You're organizing doctors, nurses, and family.", eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Need $1,000 to help with care" end },
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
		cooldown = 5,
		-- CRITICAL FIX: Can't do bucket list activities from prison or if homeless
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true },
		-- CRITICAL FIX: Removed money check - event has free options
		choices = {
			{ 
				text = "Dream vacation trip ($2,000)", 
				effects = { Happiness = 12, Health = 3, Money = -2000 },
				setFlags = { traveled_world = true }, 
				eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Need $2,000 for trip" end,
				feedText = "✈️ Dream vacation! Worth every penny!",
			},
			{ 
				text = "Local adventure ($500)", 
				effects = { Happiness = 8, Money = -500 },
				setFlags = { traveled_world = true }, 
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for trip" end,
				feedText = "✈️ Local adventure! Dreams don't have to be expensive!",
			},
			{ 
				text = "Learn a new skill ($200 class)", 
				effects = { Happiness = 8, Smarts = 5, Money = -200 },
				setFlags = { lifelong_learner = true }, 
				eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for class" end,
				feedText = "📚 You're never too old to learn something new!",
			},
			{ 
				text = "Learn online", 
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { lifelong_learner = true }, 
				feedText = "📚 Free online courses! Self-taught and proud!",
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
			{ text = "Donate to charity ($5,000)", effects = { Money = -5000, Happiness = 15 }, setFlags = { philanthropist = true }, feedText = "Giving back feels amazing.", eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Need $5,000 to donate" end },
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
			{ text = "Fight with everything you have ($10K)", effects = { Health = -10, Happiness = -10, Money = -10000 }, setFlags = { battling_illness = true, fighter = true }, feedText = "You're in the fight of your life.", eligibility = function(state) return (state.Money or 0) >= 10000, "💸 Need $10K for treatment" end },
			{ text = "Accept it and make peace", effects = { Health = -5, Happiness = -5 }, setFlags = { at_peace = true }, feedText = "You've found acceptance." },
			{ text = "Seek alternative treatments ($5K)", effects = { Health = -8, Happiness = -5, Money = -5000 }, setFlags = { alternative_medicine = true }, feedText = "You're trying every option.", eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Need $5K for alternative treatments" end },
			{ text = "It's treatable - caught it early ($3K)", effects = { Health = -5, Money = -3000, Happiness = 5 }, setFlags = { health_recovered = true }, feedText = "Caught early! Treatment is working.", eligibility = function(state) return (state.Money or 0) >= 3000, "💸 Need $3K for treatment" end },
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
			{ text = "Ready to spoil them rotten", effects = { Happiness = 15 }, setFlags = { grandparent = true, spoiling_grandparent = true }, feedText = "This kid is getting EVERYTHING!" },
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
			{ text = "Move to assisted living ($3,000)", effects = { Health = 5, Happiness = -5, Money = -3000 }, setFlags = { assisted_living = true }, feedText = "You moved to a facility. Safer, but different.", eligibility = function(state) return (state.Money or 0) >= 3000, "💸 Need $3,000 for assisted living" end },
			{ text = "Hire in-home care ($2,000)", effects = { Health = 5, Money = -2000 }, setFlags = { has_caregiver = true }, feedText = "Help comes to you. You stay home.", eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Need $2,000 for in-home care" end },
			{ 
			text = "Move in with family", 
			effects = { Happiness = 5 }, 
			setFlags = { lives_with_family = true }, 
			feedText = "Your family welcomed you into their home.",
			-- CRITICAL FIX: Can only move in with family if you have family
			eligibility = function(state)
				local flags = state.Flags or {}
				if flags.has_child or flags.has_children or flags.parent then
					return true
				end
				-- Could also move in with siblings
				if state.Relationships then
					for _, rel in pairs(state.Relationships) do
						if rel.type == "sibling" or rel.type == "family" then
							return true
						end
					end
				end
				return false, "You don't have any family to move in with"
			end,
		},
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
			state.Flags.has_spouse = nil
			state.Flags.dating = nil
			state.Flags.committed_relationship = nil
			state.Flags.lives_with_partner = nil
			
			-- CRITICAL FIX #WIDOW-1: Check BOTH spouse and partner!
			-- After marriage, partner is moved to spouse field
			if state.Relationships then
				-- Check spouse first (after proper marriage)
				if state.Relationships.spouse then
					state.Relationships.spouse.alive = false
					state.Relationships.spouse.deceased = true
					state.Relationships.late_spouse = state.Relationships.spouse
					state.Relationships.spouse = nil
				-- Fallback to partner (old code path)
				elseif state.Relationships.partner then
					state.Relationships.partner.alive = false
					state.Relationships.partner.deceased = true
					state.Relationships.late_spouse = state.Relationships.partner
					state.Relationships.partner = nil
				end
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

		-- CRITICAL FIX: Dynamic charity donation based on player's actual wealth!
		choices = {
			{ text = "Everything split equally among children", effects = { Happiness = 5 }, setFlags = { has_will = true }, feedText = "Fair and simple. Fewer arguments later." },
			{ text = "Leave more to those who need it", effects = { Happiness = 3 }, setFlags = { has_will = true }, feedText = "You considered each person's situation." },
			{ 
				text = "Donate most of it to charity", 
				effects = { Happiness = 10 }, 
				setFlags = { has_will = true, charitable_legacy = true }, 
				feedText = "Your wealth will help many causes.",
				eligibility = function(state) 
					local money = state.Money or 0
					if money < 1000 then
						return false, "💸 Need at least $1,000 to donate"
					end
					return true 
				end,
				onResolve = function(state)
					-- CRITICAL FIX: Donate 60% of player's money, not a hardcoded $5000!
					local money = state.Money or 0
					local donation = math.floor(money * 0.6)
					state.Money = money - donation
					state:AddFeed(string.format("📜 You donated $%s to charity. Your legacy will help many!", tostring(donation)))
				end,
			},
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
		baseChance = 0.35,
		cooldown = 5, -- CRITICAL FIX: Increased from 2 to reduce spam

		choices = {
			{ text = "Take a class to learn", effects = { Smarts = 5, Happiness = 5 }, setFlags = { tech_savvy_senior = true }, feedText = "You're learning! Video calls are great!" },
			{ text = "Ask grandkids for help", effects = { Happiness = 5 }, feedText = "The young ones are patient teachers." },
			{ text = "Give up - it's too confusing", effects = { Happiness = -3 }, setFlags = { technology_resistant = true }, feedText = "You'll stick with what you know." },
			{ text = "Hire someone to set things up ($200)", effects = { Money = -200, Happiness = 3 }, feedText = "Everything works now... mostly.", eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for tech setup" end },
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
		-- CRITICAL FIX: Only show this if player actually has a BIG house!
		-- Don't show "downsize your big house" to someone in a studio apartment!
		eligibility = function(state)
			-- Must have a big house (mansion, large house, etc.) - not a studio/apartment
			if state.Assets and state.Assets.Properties then
				for _, prop in ipairs(state.Assets.Properties) do
					local name = (prop.name or ""):lower()
					local propType = (prop.type or ""):lower()
					local price = prop.price or prop.value or 0
					-- Only trigger for actual big houses (mansion, large house, or expensive property)
					if name:find("mansion") or name:find("estate") or name:find("villa")
						or name:find("large") or name:find("luxury") or name:find("penthouse")
						or propType:find("mansion") or propType:find("estate")
						or price >= 500000 then
						return true
					end
				end
			end
			-- Also check HousingState
			if state.HousingState then
				local housing = state.HousingState
				local housingType = (housing.type or ""):lower()
				local housingValue = housing.value or 0
				if housingType:find("mansion") or housingType:find("estate") or housingType:find("large")
					or housingValue >= 500000 then
					return true
				end
			end
			return false -- Don't show this for small apartments/studios
		end,

		choices = {
			{ text = "Sell and move to a smaller place", effects = { Money = 20000, Happiness = 3 }, setFlags = { downsized = true }, feedText = "Less space, less maintenance. More freedom!" },
			{ text = "Stay - too many memories here", effects = { Happiness = 5 }, feedText = "This house is full of your life's history." },
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
			{ text = "World cruise ($15K)", effects = { Money = -15000, Happiness = 20, Health = 3 }, setFlags = { world_traveler = true }, feedText = "Seeing the world at sea. Magnificent!", eligibility = function(state) return (state.Money or 0) >= 15000, "💸 Need $15K for world cruise" end },
			{ text = "Visit every grandchild ($3K)", effects = { Money = -3000, Happiness = 15 }, feedText = "Quality time with each grandchild. Priceless.", eligibility = function(state) return (state.Money or 0) >= 3000, "💸 Need $3K for travel" end },
			{ text = "Return to your birthplace ($2K)", effects = { Money = -2000, Happiness = 12 }, setFlags = { returned_home = true }, feedText = "Revisiting where it all began. Emotional.", eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Need $2K for travel" end },
			{ text = "Learn to paint/play music ($500)", effects = { Money = -500, Happiness = 10, Smarts = 3 }, setFlags = { artist_senior = true }, feedText = "Never too late to be creative!", eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for supplies/lessons" end },
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
		baseChance = 0.18,  -- CRITICAL FIX: Reduced from 0.4 to prevent spam (VehicleEvents has similar)
		cooldown = 6,  -- CRITICAL FIX: Increased from 3 to space out car trouble events
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
				-- CRITICAL FIX: Show the cost!
				text = "Use public transit/rideshare ($100)",
				effects = { Money = -100, Happiness = -2 },
				feedText = "Getting by without the car for now...",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for transit/rideshare" end,
			},
			{
				-- CRITICAL FIX: Add a FREE option so players aren't hard-locked!
				text = "Walk or bike everywhere",
				effects = { Health = 3, Happiness = -3 },
				feedText = "Getting fit but transportation is tough!",
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
		cooldown = 5,
		blockedByFlags = { in_prison = true, homeless = true },
		
		choices = {
			{ text = "They're too loud", effects = { Happiness = -4, Health = -2 }, setFlags = { bad_neighbors = true }, feedText = "The noise is driving you crazy." },
			{ text = "Property line dispute", effects = { Happiness = -3 }, feedText = "Lawyers might get involved..." },
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
		cooldown = 5,
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
		cooldown = 5,
		blockedByFlags = { in_prison = true },
		
		choices = {
			{ text = "Gardening", effects = { Happiness = 6, Health = 3 }, setFlags = { gardener = true }, feedText = "Growing things is incredibly satisfying!" },
			{ text = "Cooking/Baking", effects = { Happiness = 5, Health = 2 }, setFlags = { home_chef = true }, feedText = "You're becoming quite the chef!" },
			{ text = "Photography ($300)", effects = { Happiness = 5, Smarts = 2, Money = -300 }, setFlags = { photographer = true }, feedText = "Capturing beautiful moments!", eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 for camera equipment" end },
			{ text = "Woodworking ($200)", effects = { Happiness = 5, Smarts = 3, Money = -200 }, setFlags = { woodworker = true }, feedText = "Making things with your hands is therapeutic.", eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for tools" end },
			{ text = "Playing an instrument ($400)", effects = { Happiness = 6, Smarts = 3, Money = -400 }, setFlags = { musician_hobby = true }, feedText = "Music brings you so much joy!", eligibility = function(state) return (state.Money or 0) >= 400, "💸 Need $400 for an instrument" end },
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
		cooldown = 5,
		
		choices = {
			{ text = "Make effort to reconnect", effects = { Happiness = 8 }, setFlags = { maintains_friendships = true }, feedText = "You organized a reunion. Worth every moment!" },
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
		cooldown = 5,
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
		cooldown = 5, -- CRITICAL FIX #713: Reduced from 6 for more variety
		
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
		cooldown = 5, -- CRITICAL FIX #715: Reduced from 5 
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
		cooldown = 5,
		blockedByFlags = { in_prison = true },
		
		choices = {
			{ text = "Started exercising regularly", effects = { Health = 8, Happiness = 5 }, setFlags = { exercises = true }, feedText = "Running, bodyweight exercises, free workouts! Feeling stronger!" },
			{ text = "Improved diet significantly ($100)", effects = { Health = 6, Happiness = 3, Money = -100 }, setFlags = { healthy_eater = true }, feedText = "Eating better. More energy!", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for healthy groceries" end },
			{ text = "Both diet and exercise ($300)", effects = { Health = 12, Happiness = 7, Money = -300 }, setFlags = { health_focused = true }, feedText = "Complete lifestyle change! Looking and feeling great!", eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 for gym + groceries" end },
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
			{ text = "Adopt a dog ($300)", effects = { Happiness = 10, Health = 3, Money = -300 }, setFlags = { has_pet = true, has_dog = true }, feedText = "You adopted a dog! Unconditional love awaits!", eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 for dog adoption + supplies" end },
			{ text = "Adopt a cat ($150)", effects = { Happiness = 8, Money = -150 }, setFlags = { has_pet = true, has_cat = true }, feedText = "You adopted a cat! Independent but loving!", eligibility = function(state) return (state.Money or 0) >= 150, "💸 Need $150 for cat adoption + supplies" end },
			{ text = "Get a fish tank ($100)", effects = { Happiness = 4, Smarts = 1, Money = -100 }, setFlags = { has_pet = true, has_fish = true }, feedText = "Fish tank set up! Very relaxing to watch.", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for fish tank setup" end },
			{ text = "Rescue an older pet ($200)", effects = { Happiness = 12, Money = -200 }, setFlags = { has_pet = true, pet_rescuer = true }, feedText = "Gave a senior pet a loving home! You're their hero!", eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for pet rescue + supplies" end },
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
		cooldown = 5,
		
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
		cooldown = 5,
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
		baseChance = 0.35,
		cooldown = 5,
		blockedByFlags = { in_prison = true, homeless = true },
		-- CRITICAL FIX: Block for military - they have different leave system!
		eligibility = function(state)
			-- Military personnel don't get "vacation planning" - they have military leave
			if state.CurrentJob and state.CurrentJob.category == "military" then
				return false
			end
			if state.Flags then
				if state.Flags.military or state.Flags.enlisted or state.Flags.soldier or
				   state.Flags.army or state.Flags.navy or state.Flags.air_force or state.Flags.marines then
					return false
				end
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
			text = "Staycation at home ($100)",
			effects = { Happiness = 6, Health = 3, Money = -100 },
			feedText = "Sometimes home is the best vacation. Relaxed and recharged!",
			eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for staycation" end,
		},
		{
			text = "Visit family ($300)",
			effects = { Happiness = 8, Money = -300 },
			feedText = "Quality time with family. Worth the trip!",
			eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 for travel" end,
		},
		-- CRITICAL FIX: FREE option to prevent hardlock
		{ text = "Just relax at home", effects = { Happiness = 4, Health = 2 }, feedText = "🏖️ No vacation this year, but you found time to recharge at home. Sometimes that's enough." },
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
		cooldown = 5,
		
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
			{ text = "Try sleep supplements", effects = { Health = 2 }, feedText = "Melatonin and herbal teas. Some improvement." },
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
		cooldown = 5,
		blockedByFlags = { in_prison = true },
		
	choices = {
		{ 
			text = "Go and have fun ($200 travel/gifts)", 
			effects = { Happiness = 10, Money = -200 }, 
			setFlags = { family_connected = true }, 
			feedText = "Catching up with relatives you haven't seen in years!",
			eligibility = function(state) return (state.Money or 0) >= 200, "Can't afford travel costs" end,
		},
		{ text = "Dreading the awkward questions", effects = { Happiness = -3 }, feedText = "So, when are you getting married? Having kids? Getting a real job?" },
		{ text = "Skip it - too much drama", effects = { Happiness = 2 }, setFlags = { avoids_family = true }, feedText = "You made an excuse. Some family is best in small doses." },
		{ 
			text = "Organize it yourself ($500)", 
			effects = { Happiness = 5, Money = -500, Smarts = 2 }, 
			setFlags = { family_planner = true }, 
			feedText = "You're bringing everyone together!",
			eligibility = function(state) return (state.Money or 0) >= 500, "Can't afford to host" end,
		},
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
		cooldown = 5,
		requiresJob = true,
		
		choices = {
			{ text = "Best work friend ever", effects = { Happiness = 8 }, setFlags = { has_work_friend = true }, feedText = "Work is so much better with a good friend there!" },
			{ text = "Hang out outside work too", effects = { Happiness = 6 }, setFlags = { work_friend_real_friend = true }, feedText = "The friendship extends beyond the office!" },
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
		cooldown = 5,
		
		choices = {
			{ text = "Paid for your coffee", effects = { Happiness = 6, Money = 5 }, feedText = "A stranger ahead of you in line paid for your order!" },
			{ text = "Helped you when you were stuck", effects = { Happiness = 8 }, feedText = "Someone stopped to help when you needed it most!" },
			{ text = "Gave you a sincere compliment", effects = { Happiness = 5, Looks = 1 }, feedText = "A stranger's kind words made your day!" },
			{ text = "Paid it forward", effects = { Happiness = 10 }, setFlags = { pays_it_forward = true }, feedText = "You were inspired to do something kind for someone else!" },
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
		cooldown = 5,
		
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
		-- CRITICAL FIX: Renamed to avoid ID collision with Career.lua
		id = "adult_career_crossroads",
		title = "Career Crossroads",
		emoji = "🔀",
		text = "You've been doing the same job for years. Is it time for a change?",
		question = "What do you decide?",
		minAge = 28, maxAge = 50,
		baseChance = 0.3,
		cooldown = 8,
		maxOccurrences = 2,
		category = "career",
		tags = { "career", "decision", "crossroads" },
		blockedByFlags = { in_prison = true },
		choices = {
			{ text = "Take a leap and change careers ($5,000)", effects = { Happiness = 15, Money = -5000 }, setFlags = { career_changer = true }, feedText = "Scary but exciting! New chapter begins.", eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Need $5,000 for career change" end },
			{ text = "Stay but ask for a promotion", effects = { Happiness = 5, Money = 5000 }, feedText = "You made your case. A raise is coming!" },
			{ text = "Start a side business ($2,000)", effects = { Happiness = 10, Money = -2000, Smarts = 5 }, setFlags = { entrepreneur = true }, feedText = "Nights and weekends building your dream!", eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Need $2,000 for business startup" end },
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
		blockedByFlags = { homeowner = true, has_property = true },
		-- CRITICAL FIX: Must have enough money for down payment!
		-- User complaint: "IT SAYS IM A HOMEOWNER BUT THE POPUP FOR BUYING HOME I HAD NO MONEY"
		eligibility = function(state)
			local money = state.Money or 0
			if money < 10000 then
				return false, "Not enough money for a down payment"
			end
			local flags = state.Flags or {}
			if flags.homeowner or flags.has_property then
				return false, "Already owns a home"
			end
			return true
		end,
		choices = {
			{ 
				text = "Offer asking price immediately ($50k down)", 
				effects = { Happiness = 15, Money = -50000 }, 
				setFlags = { homeowner = true, has_property = true }, 
				feedText = "🏠 Keys in hand! You're a homeowner!",
				eligibility = function(state)
					local money = state.Money or 0
					if money < 50000 then
						return false, "Can't afford $50,000 down payment"
					end
					return true
				end,
				onResolve = function(state)
					if state.AddAsset then
						state:AddAsset("Properties", {
							id = "home_" .. tostring(state.Age or 0),
							name = "House",
							emoji = "🏠",
							price = 250000,
							value = 250000,
							income = 0,
							isEventAcquired = true,
						})
					end
				end,
			},
			{ 
				text = "Negotiate aggressively ($40k down)", 
				effects = { Happiness = 12, Money = -40000, Smarts = 3 }, 
				setFlags = { homeowner = true, has_property = true }, 
				feedText = "🏠 Saved $10k with your negotiating skills!",
				eligibility = function(state)
					local money = state.Money or 0
					if money < 40000 then
						return false, "Can't afford $40,000 down payment"
					end
					return true
				end,
				onResolve = function(state)
					if state.AddAsset then
						state:AddAsset("Properties", {
							id = "home_negotiated_" .. tostring(state.Age or 0),
							name = "House",
							emoji = "🏠",
							price = 200000,
							value = 200000,
							income = 0,
							isEventAcquired = true,
						})
					end
				end,
			},
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
		-- CRITICAL FIX: Changed from in_relationship to has_partner (most dating events set has_partner not in_relationship)
		requiresFlags = { has_partner = true },
		choices = {
			{ text = "Grand romantic gesture ($5,000)", effects = { Happiness = 25, Money = -5000 }, setFlags = { engaged = true, romantic = true }, feedText = "💍 They said YES! What a magical moment!", eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Need $5,000 for grand gesture" end },
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
		baseChance = 0.35,
		oneTime = true,
		maxOccurrences = 1,
		choices = {
			{ text = "Proud of what I've built", effects = { Happiness = 15 }, setFlags = { content_with_life = true }, feedText = "Looking back with satisfaction. You've done well!" },
			{ text = "Time for a big change ($10,000)", effects = { Happiness = 10, Money = -10000 }, setFlags = { midlife_change = true }, feedText = "Bucket list time! New adventures await.", eligibility = function(state) return (state.Money or 0) >= 10000, "💸 Need $10,000 for big change" end },
			{ text = "Regret some choices", effects = { Happiness = -10 }, setFlags = { has_regrets = true }, feedText = "Some roads not taken still haunt you." },
			{ text = "Focus on what's ahead", effects = { Happiness = 8, Smarts = 5 }, setFlags = { forward_looking = true }, feedText = "The best is yet to come!" },
		},
	},
	
	-- REMOVED: OLD Inheritance event that let player CHOOSE what they inherit
	-- This was BAD design - inheritance should be a SURPRISE, not a choice!
	-- The fixed version is below at id "unexpected_inheritance_surprise"
	-- User complained: "FIX THE SURPRISE INHERITANCE TO BE AN ACTUAL SURPRISE NOT LET ME CHOOSE"
	-- Also: "A HOUSE THAT NEEDS WORKING ON AND I LOSE 5K?? THATS DUMB"
	
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
			{ text = "Caught early - very treatable", effects = { Happiness = -5, Health = -10 }, setFlags = { health_survivor = true }, feedText = "Early detection saved you. Treatment successful!" },
			{ text = "Lifestyle changes needed", effects = { Happiness = -8, Health = 15 }, setFlags = { health_conscious = true }, feedText = "Wake-up call. Time to get serious about health." },
			{ text = "Long road ahead", effects = { Happiness = -20, Health = -25 }, setFlags = { chronic_illness = true }, feedText = "This will be a journey. Stay strong." },
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
			{ text = "Help without hesitation ($1,000)", effects = { Happiness = 10, Money = -1000 }, setFlags = { loyal_friend = true }, feedText = "That's what friends are for. They'd do the same for you.", eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Need $1,000 to help" end },
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
		baseChance = 0.35,
		oneTime = true,
		maxOccurrences = 1,
		-- CRITICAL FIX: Changed from has_children to has_child (most events set has_child not has_children)
		requiresFlags = { has_child = true },
		choices = {
			{ text = "Rediscover yourself and hobbies", effects = { Happiness = 15 }, setFlags = { empty_nester = true, self_renewed = true }, feedText = "Freedom! Time to focus on YOU again." },
			{ text = "Struggle with the silence", effects = { Happiness = -15 }, setFlags = { empty_nester = true }, feedText = "It's harder than expected. You miss them." },
			{ text = "Renovate the house ($20,000)", effects = { Happiness = 10, Money = -20000 }, setFlags = { empty_nester = true }, feedText = "Finally turning that room into your dream space!", eligibility = function(state) return (state.Money or 0) >= 20000, "💸 Need $20,000 for renovation" end },
			{ text = "Plan more visits and trips to see them ($2,000)", effects = { Happiness = 8, Money = -2000 }, setFlags = { empty_nester = true }, feedText = "Distance doesn't mean disconnection.", eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Need $2,000 for travel" end },
		},
	},

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: NEW ENGAGING ADULT EVENTS FOR VARIETY
	-- These events make adult life more interesting and keep players hooked
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		-- CRITICAL FIX: Renamed from "viral_moment" to avoid duplicate ID
		id = "adult_viral_fame",
		title = "🌟 Viral Fame!",
		emoji = "📱",
		text = "Something you posted online has gone VIRAL! Your phone is blowing up with notifications. Millions of people are watching, sharing, commenting...",
		question = "How do you handle your 15 minutes of fame?",
		minAge = 18, maxAge = 55,
		baseChance = 0.15,
		cooldown = 20,
		oneTime = true,
		category = "social",
		tags = { "viral", "fame", "social_media", "opportunity" },
		blockedByFlags = { in_prison = true, went_viral_before = true },
		-- CRITICAL FIX: Only show if player uses social media!
		eligibility = function(state)
			local flags = state.Flags or {}
			local usesSocialMedia = flags.content_creator or flags.streamer or flags.social_media_active
				or flags.posts_online or flags.vlogger or flags.gaming_content
				or flags.has_social_media or flags.influencer_wannabe or flags.social_butterfly
				or flags.online_presence or flags.digital_native
			return usesSocialMedia, "Need social media presence"
		end,
		choices = {
			{
				text = "Monetize it - get sponsors!",
				effects = { Happiness = 15 },
				setFlags = { went_viral_before = true, influencer = true },
				feedText = "You capitalized on your viral moment!",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.4 then
						state.Money = (state.Money or 0) + 25000
						state.Flags.successful_influencer = true
						state:AddFeed("💰 JACKPOT! Brands are throwing money at you! +$25,000!")
					elseif roll < 0.7 then
						state.Money = (state.Money or 0) + 8000
						state:AddFeed("💰 A few sponsorships came through! +$8,000!")
					else
						state.Money = (state.Money or 0) + 2000
						state:AddFeed("💰 Made some cash, but fame faded fast. +$2,000")
					end
				end,
			},
			{
				text = "Use it to launch a business",
				effects = { Happiness = 10 },
				setFlags = { went_viral_before = true, business_starter = true },
				feedText = "Leveraging fame for business...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.35 then
						state.Money = (state.Money or 0) + 50000
						state.Flags.viral_entrepreneur = true
						state:AddFeed("🚀 Your business EXPLODED! People love your brand! +$50,000!")
					elseif roll < 0.6 then
						state.Money = (state.Money or 0) + 12000
						state:AddFeed("🚀 Business is doing okay! Steady growth. +$12,000")
					else
						state.Money = math.max(0, (state.Money or 0) - 5000)
						state:AddFeed("🚀 Business flopped. Lost your investment. -$5,000")
					end
				end,
			},
			{
				text = "Stay humble - enjoy the moment",
				effects = { Happiness = 20, Smarts = 2 },
				setFlags = { went_viral_before = true, humble = true },
				feedText = "You enjoyed the attention without letting it change you.",
			},
			{
				text = "Delete everything - too much attention",
				effects = { Happiness = -5, Health = 3 },
				setFlags = { went_viral_before = true, privacy_focused = true },
				feedText = "You weren't ready for all that attention. Back to normal life.",
			},
		},
	},
	{
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Made inheritance a TRUE SURPRISE - player doesn't choose!
		-- User complaint: "SUPRISE INHERITANCE ISNT A SUPRISE CUZ ITS LEGIT LETTING ME CHOOSE"
		-- Now the inheritance amount is determined randomly and shown directly in text!
		-- ═══════════════════════════════════════════════════════════════════════════════
		id = "unexpected_inheritance",
		title = "💌 Surprise Inheritance!",
		emoji = "📜",
		minAge = 25, maxAge = 70,
		baseChance = 0.12,
		cooldown = 25,
		oneTime = true,
		category = "money",
		tags = { "inheritance", "surprise", "family", "money" },
		blockedByFlags = { in_prison = true, got_inheritance = true },
		
		-- Dynamic text showing the actual inheritance amount!
		preProcess = function(state, eventDef)
			local roll = math.random()
			local amount = 0
			local itemDesc = ""
			local reaction = ""
			
			if roll < 0.15 then
				amount = 500000
				itemDesc = "their entire estate - $500,000!"
				reaction = "You're RICH! Life-changing money!"
			elseif roll < 0.35 then
				amount = 75000
				itemDesc = "a nice sum - $75,000!"
				reaction = "What a generous surprise!"
			elseif roll < 0.55 then
				amount = 15000
				itemDesc = "$15,000 in savings!"
				reaction = "Better than nothing!"
			elseif roll < 0.75 then
				amount = 5000
				itemDesc = "an old antique worth about $5,000!"
				reaction = "It might be worth something!"
			else
				amount = 500
				itemDesc = "a box of old photographs and $500 for 'safekeeping'."
				reaction = "Mostly sentimental value..."
			end
			
			-- Store the amount for onComplete
			state._inheritanceAmount = amount
			
			eventDef.text = string.format("A lawyer contacts you with unexpected news! A distant relative you barely knew has passed away, and they left you %s", itemDesc)
			eventDef.question = string.format("%s How do you feel?", reaction)
			return true
		end,
		
		choices = {
			{
				text = "Wow! Thank you, Great Uncle!",
				effects = { Happiness = 15 },
				setFlags = { got_inheritance = true },
				feedText = "What an unexpected blessing!",
				onResolve = function(state)
					local amount = state._inheritanceAmount or 15000
					state.Money = (state.Money or 0) + amount
					state._inheritanceAmount = nil
					state.Flags = state.Flags or {}
					state.Flags.got_inheritance = true
					if amount >= 100000 then
						state.Flags.wealthy_inheritance = true
					end
					state:AddFeed(string.format("💰 Inherited $%s from a distant relative!", tostring(amount)))
				end,
			},
			{
				text = "I wish I'd known them better...",
				effects = { Happiness = 5 },
				setFlags = { got_inheritance = true },
				feedText = "Bittersweet feelings about the loss.",
				onResolve = function(state)
					local amount = state._inheritanceAmount or 15000
					state.Money = (state.Money or 0) + amount
					state._inheritanceAmount = nil
					state.Flags = state.Flags or {}
					state.Flags.got_inheritance = true
					state:AddFeed(string.format("💰 Inherited $%s. You regret not knowing them better.", tostring(amount)))
				end,
			},
		},
	},
	{
		id = "life_changing_conversation",
		title = "💬 The Conversation",
		emoji = "🗣️",
		text = "You had a deep, meaningful conversation with a stranger that really made you think about your life choices...",
		question = "What was the conversation about?",
		minAge = 20, maxAge = 65,
		baseChance = 0.2,
		cooldown = 15,
		oneTime = true,
		category = "personal",
		tags = { "wisdom", "growth", "reflection", "milestone" },
		blockedByFlags = { in_prison = true },
		choices = {
			{
				text = "About chasing dreams vs. stability",
				effects = { Smarts = 5, Happiness = 5 },
				setFlags = { deep_thinker = true, life_reflected = true },
				feedText = "Their words stuck with you. 'What's the point of safety if you never feel alive?'",
			},
			{
				text = "About relationships and love",
				effects = { Happiness = 8 },
				setFlags = { romantic_soul = true, life_reflected = true },
				feedText = "They said: 'Love isn't about finding the perfect person. It's about seeing imperfect people perfectly.'",
			},
			{
				text = "About dealing with failure",
				effects = { Smarts = 4, Health = 3 },
				setFlags = { resilient = true, life_reflected = true },
				feedText = "'Every master was once a disaster.' Those words changed how you see setbacks.",
			},
			{
				text = "About family and legacy",
				effects = { Happiness = 6, Smarts = 2 },
				setFlags = { family_focused = true, life_reflected = true },
				feedText = "'In the end, it's not about what you gathered, but who gathered around you.'",
			},
		},
	},
	{
		id = "mystery_package",
		title = "📦 Mystery Package",
		emoji = "📦",
		text = "A mysterious package arrives at your door. No return address. Just your name scrawled on the front...",
		question = "What do you do?",
		minAge = 18, maxAge = 70,
		baseChance = 0.18,
		cooldown = 12,
		oneTime = true,
		category = "random",
		tags = { "mystery", "surprise", "random" },
		blockedByFlags = { in_prison = true },
		choices = {
			{
				text = "Open it immediately!",
				effects = {},
				feedText = "Your curiosity wins...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.25 then
						state.Money = (state.Money or 0) + 5000
						state:ModifyStat("Happiness", 20)
						state:AddFeed("📦 It's cash! $5,000! Who sent this?!")
					elseif roll < 0.45 then
						state:ModifyStat("Happiness", 15)
						state.Flags.got_mystery_gift = true
						state:AddFeed("📦 It's an expensive watch! Must have been from a secret admirer!")
					elseif roll < 0.65 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("📦 Old family photos from a relative you lost touch with. Touching!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📦 Just some books. Nice gesture though!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📦 It was a prank. Glitter EVERYWHERE. Not funny.")
					end
				end,
			},
			{
				text = "Call the police first",
				effects = { Smarts = 3 },
				feedText = "Better safe than sorry...",
				onResolve = function(state)
					state:AddFeed("👮 Police said it's safe. Just a care package from a charity. How boring.")
				end,
			},
			{
				text = "Return to sender (wherever that is)",
				effects = {},
				feedText = "You decided not to risk it.",
				onResolve = function(state)
					state:AddFeed("📦 You'll never know what was inside. Probably nothing. Right?")
				end,
			},
		},
	},
	{
		id = "random_act_of_kindness",
		title = "💝 Acts of Kindness",
		emoji = "💝",
		text = "You witnessed someone struggling today and had a chance to help...",
		question = "What do you do?",
		minAge = 12, maxAge = 90,
		baseChance = 0.3,
		cooldown = 8,
		category = "social",
		tags = { "kindness", "charity", "social", "moral" },
		blockedByFlags = { in_prison = true },
		choices = {
			{
				-- CRITICAL FIX: Show price in button text and add eligibility check!
				text = "Help them generously ($50)",
				effects = { Happiness = 10, Money = -50 },
				setFlags = { kind_soul = true },
				feedText = "You helped and it felt amazing.",
				eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 to help generously" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.3 then
						state.Money = (state.Money or 0) + 500
						state:AddFeed("💝 Plot twist! They paid you back 10x when they got back on their feet!")
					elseif roll < 0.5 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.new_friend = true
						state:AddFeed("💝 You made a new friend! They're awesome!")
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("💝 Karma will remember your kindness.")
					end
				end,
			},
			{
				text = "Help a little",
				effects = { Happiness = 4 },
				feedText = "You did what you could.",
			},
			{
				text = "Too busy, walk past",
				effects = { Happiness = -3 },
				feedText = "You had your own problems...",
			},
		},
	},
	{
		id = "second_chance_romance",
		title = "💕 The One That Got Away",
		emoji = "💘",
		text = "You randomly bump into an old flame from years ago. They look great. The chemistry is still there...",
		question = "What happens next?",
		minAge = 25, maxAge = 60,
		baseChance = 0.15,
		cooldown = 20,
		oneTime = true,
		category = "relationships",
		tags = { "romance", "past", "second_chance" },
		blockedByFlags = { in_prison = true, married = true, second_chance_tried = true },
		choices = {
			{
				text = "Get coffee, reconnect",
				effects = { Happiness = 10 },
				setFlags = { second_chance_tried = true },
				feedText = "Maybe things happen for a reason...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.4 then
						state:ModifyStat("Happiness", 20)
						state.Flags.rekindled_love = true
						state.Flags.dating = true
						state:AddFeed("💕 Sparks flew! You're giving it another shot!")
					elseif roll < 0.7 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("💕 Nice catching up. But that chapter is closed. You're both different people now.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("💕 Awkward. You remembered why it ended. Yikes.")
					end
				end,
			},
			{
				text = "Politely decline, keep walking",
				effects = { Smarts = 2 },
				setFlags = { second_chance_tried = true },
				feedText = "Some doors are better left closed.",
			},
			{
				text = "Pretend not to see them",
				effects = { Happiness = -5 },
				setFlags = { second_chance_tried = true },
				feedText = "You hid behind a plant. They definitely saw you. Awkward.",
			},
		},
	},
	{
		id = "adventure_opportunity",
		title = "🌍 Adventure Calls!",
		emoji = "🎒",
		text = "A once-in-a-lifetime adventure opportunity has presented itself!",
		question = "Do you take the leap?",
		minAge = 18, maxAge = 65,
		baseChance = 0.2,
		cooldown = 15,
		category = "adventure",
		tags = { "adventure", "travel", "opportunity", "life_changing" },
		blockedByFlags = { in_prison = true, adventure_taken = true },
		choices = {
			{
				text = "Climb a famous mountain!",
				effects = { Health = -10, Happiness = 25 },
				setFlags = { adventurer = true, mountain_climber = true },
				feedText = "The summit awaits!",
				onResolve = function(state)
					local roll = math.random()
					local health = (state.Stats and state.Stats.Health) or 50
					local successChance = 0.5 + (health / 200)
					if roll < successChance then
						state:ModifyStat("Health", 10)
						state:ModifyStat("Happiness", 20)
						state.Flags = state.Flags or {}
						state.Flags.conquered_mountain = true
						state:AddFeed("🏔️ YOU DID IT! Standing on the summit, looking at the world below... unforgettable!")
					else
						state:ModifyStat("Health", -15)
						state:AddFeed("🏔️ Had to turn back due to weather. Disappointed but alive. You'll try again someday.")
					end
				end,
			},
			{
				text = "Skydiving over the ocean!",
				effects = { Happiness = 30 },
				setFlags = { adventurer = true, skydiver = true },
				feedText = "FREE FALLING!",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.95 then
						state:AddFeed("🪂 INCREDIBLE! The rush of freefall, then floating over crystal blue waters. You feel SO alive!")
					else
						state:ModifyStat("Health", -20)
						state.Flags = state.Flags or {}
						state.Flags.rough_landing = true
						state:AddFeed("🪂 Rough landing! Sprained your ankle. But WHAT A STORY!")
					end
				end,
			},
			{
				-- CRITICAL FIX: Show price in text!
				text = "Safari in Africa ($3,000)!",
				effects = { Money = -3000, Happiness = 25 },
				setFlags = { adventurer = true, safari_done = true },
				feedText = "The wild calls! Lions and elephants!",
				eligibility = function(state)
					if (state.Money or 0) < 3000 then
						return false, "Can't afford the $3,000 safari trip"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.6 then
						state.Flags.saw_big_five = true
						state:AddFeed("🦁 SAW THE BIG FIVE! Lions, elephants, rhinos, leopards, and buffalo! Life-changing experience!")
					else
						state:AddFeed("🦁 Incredible trip! The sunsets, the animals, the people. You'll never forget it.")
					end
				end,
			},
			{
				text = "Too risky, stay safe",
				effects = { Happiness = -5 },
				feedText = "You'll always wonder 'what if?'...",
			},
		},
	},
	{
		id = "skill_discovery",
		title = "🎯 Hidden Talent!",
		emoji = "✨",
		text = "You tried something new and discovered you're actually REALLY good at it!",
		question = "What's your hidden talent?",
		minAge = 15, maxAge = 70,
		baseChance = 0.25,
		cooldown = 12,
		oneTime = true,
		category = "personal",
		tags = { "talent", "skill", "discovery", "self_improvement" },
		blockedByFlags = { in_prison = true, talent_discovered = true },
		choices = {
			{
				text = "Cooking - you could be a chef!",
				effects = { Happiness = 12, Smarts = 3 },
				setFlags = { talent_discovered = true, talented_cook = true },
				feedText = "Who knew you had such culinary skills?!",
				onResolve = function(state)
					state:AddFeed("👨‍🍳 Your dishes are AMAZING! Friends and family are begging for dinner invites!")
				end,
			},
			{
				text = "Art - you have a creative eye!",
				effects = { Happiness = 15, Smarts = 4 },
				setFlags = { talent_discovered = true, artistic = true },
				feedText = "An artist is born!",
				onResolve = function(state)
					state:AddFeed("🎨 Your art is beautiful! People actually want to BUY your work!")
				end,
			},
			{
				text = "Music - you have an ear for it!",
				effects = { Happiness = 14, Smarts = 3 },
				setFlags = { talent_discovered = true, musical_talent = true },
				feedText = "Musical genius awakened!",
				onResolve = function(state)
					state:AddFeed("🎵 You picked up an instrument and it just... clicked! You're a natural!")
				end,
			},
			{
				text = "Public speaking - you command a room!",
				effects = { Happiness = 10, Smarts = 5 },
				setFlags = { talent_discovered = true, charismatic_speaker = true },
				feedText = "Born to lead!",
				onResolve = function(state)
					state:AddFeed("🎤 When you speak, people LISTEN. This could open SO many doors!")
				end,
			},
		},
	},

-- ════════════════════════════════════════════════════════════════════════════
-- MASSIVE EXPANSION: NEW ADULT EVENTS (Ages 18-65)
-- Life experiences that shape careers, relationships, and personal growth
-- ════════════════════════════════════════════════════════════════════════════

	{
		id = "adult_quarter_life_crisis",
		title = "Quarter-Life Crisis!",
		emoji = "😰",
		textVariants = {
			"You're 25 and questioning EVERYTHING!",
			"Is this what adulthood is supposed to be?!",
			"Comparing yourself to everyone on social media...",
			"What am I doing with my life?!",
		},
		text = "You're 25 and questioning EVERYTHING!",
		question = "How do you handle this crisis?",
		minAge = 24, maxAge = 28,
		baseChance = 0.45,
		cooldown = 5,
		oneTime = true,
		category = "adult",
		tags = { "adult", "crisis", "growth" },
		blockedByFlags = { quarter_life_crisis_done = true },
		
		choices = {
			{
				text = "🔄 Make big life changes",
				effects = { Happiness = 5 },
				setFlags = { quarter_life_crisis_done = true, embraces_change = true },
				feedText = "😰 New career? New city? Time for a fresh start!",
			},
			{
				text = "📚 Invest in self-improvement",
				effects = { Happiness = 4, Smarts = 4 },
				setFlags = { quarter_life_crisis_done = true, self_improvement = true },
				feedText = "😰 Books, courses, therapy - becoming a better you!",
			},
			{
				text = "🎉 YOLO - enjoy the ride",
				effects = { Happiness = 6 },
				setFlags = { quarter_life_crisis_done = true, carpe_diem = true },
				feedText = "😰 Life's too short to stress! Have fun!",
			},
			{
				text = "😌 I'm actually doing okay",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { quarter_life_crisis_done = true, grounded = true },
				feedText = "😰 Comparison is the thief of joy. You're doing fine!",
			},
		},
	},

	{
		id = "adult_first_apartment",
		title = "First Apartment!",
		emoji = "🏠",
		textVariants = {
			"You signed your first lease! It's YOUR place!",
			"Keys to your own apartment! Independence!",
			"First place on your own - freedom AND responsibility!",
			"Welcome home... to YOUR home!",
		},
		text = "You signed your first lease! It's YOUR place!",
		question = "How's apartment life?",
		minAge = 18, maxAge = 30,
		baseChance = 0.4,
		cooldown = 5,
		oneTime = true,
		category = "adult",
		tags = { "adult", "milestone", "home" },
		blockedByFlags = { first_apartment = true },
		
		choices = {
			{
				text = "🎨 Decorating and making it mine!",
				effects = { Happiness = 8, Money = -500 },
				setFlags = { first_apartment = true, homemaker = true },
				feedText = "🏠 IKEA trips, Pinterest boards - it's coming together!",
			},
			{
				text = "💰 Worried about rent",
				effects = { Happiness = 2, Smarts = 2 },
				setFlags = { first_apartment = true, budget_conscious = true },
				feedText = "🏠 Rent is... a lot. But it's worth the independence!",
			},
			{
				text = "🎉 Party at my place!",
				effects = { Happiness = 7 },
				setFlags = { first_apartment = true, party_host = true },
				feedText = "🏠 Housewarming party! You're the host now!",
			},
			{
				text = "😢 Miss living at home",
				effects = { Happiness = -2 },
				setFlags = { first_apartment = true, homesick_adult = true },
				feedText = "🏠 Freedom is great but... who's doing laundry now?",
			},
		},
	},

	{
		id = "adult_career_fork_decision",
		title = "Career Crossroads!",
		emoji = "🛤️",
		textVariants = {
			"A major career decision is ahead of you!",
			"Stay safe or take a risk?",
			"Your career path is forking...",
			"Time to choose your professional future!",
		},
		text = "A major career decision is ahead of you!",
		question = "What path do you take?",
		minAge = 25, maxAge = 50,
		baseChance = 0.35,
		cooldown = 6,
		category = "adult",
		tags = { "adult", "career", "decision" },
		
		choices = {
			{
				text = "🚀 Take the risky opportunity",
				effects = { Happiness = 6 },
				setFlags = { career_risk_taker = true },
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 60 then
						state:ModifyStat("Money", 5000)
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🛤️ The risk paid off! Career is THRIVING!")
					else
						state:ModifyStat("Money", -1000)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🛤️ Risky move didn't work out... lesson learned!")
					end
				end,
			},
			{
				text = "🛡️ Stay secure and stable",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { career_conservative = true },
				feedText = "🛤️ Security matters. Steady progress wins the race!",
			},
			{
				text = "🔄 Pivot to something new",
				effects = { Happiness = 5 },
				setFlags = { career_pivoter = true },
				feedText = "🛤️ Complete career change! Starting fresh!",
			},
			{
				text = "📚 Invest in more education",
				effects = { Happiness = 3, Smarts = 5, Money = -2000 },
				setFlags = { lifelong_learner = true },
				feedText = "🛤️ Back to school! Knowledge is power!",
			},
		},
	},

	{
		id = "adult_health_checkup_result",
		title = "Health Scare!",
		emoji = "🏥",
		textVariants = {
			"Something felt wrong... doctor time!",
			"A symptom has you worried...",
			"Health scare - time to get checked!",
			"Your body is telling you something...",
		},
		text = "Something felt wrong... doctor time!",
		question = "What does the doctor say?",
		minAge = 25, maxAge = 70,
		baseChance = 0.35,
		cooldown = 5,
		category = "adult",
		tags = { "adult", "health", "medical" },
		
		choices = {
			{
				text = "😰 Could be serious - more tests",
				effects = { Happiness = -5, Health = -5, Money = -500 },
				setFlags = { health_scare = true, being_monitored = true },
				feedText = "🏥 Waiting for results is the WORST. Fingers crossed.",
			},
			{
				text = "😅 False alarm! All clear!",
				effects = { Happiness = 8, Health = 5 },
				setFlags = { health_scare_clear = true },
				feedText = "🏥 What a relief! Taking better care of yourself now!",
			},
			{
				text = "⚠️ Minor issue - lifestyle changes needed",
				effects = { Happiness = 2, Health = -10 },
				setFlags = { health_warning = true, needs_lifestyle_change = true },
				feedText = "🏥 Not terrible but a wake-up call. Time for changes!",
			},
		},
	},

	{
		id = "adult_networking_event",
		title = "Networking Event!",
		emoji = "🤝",
		textVariants = {
			"Industry networking event - who will you meet?",
			"Business cards ready! Networking time!",
			"Making connections could change everything!",
			"Professional mixer - put yourself out there!",
		},
		text = "Industry networking event - who will you meet?",
		question = "How do you approach networking?",
		minAge = 22, maxAge = 60,
		baseChance = 0.35,
		cooldown = 5,
		category = "adult",
		tags = { "adult", "career", "networking" },
		careerTags = { "business", "finance", "tech", "marketing" },
		
		choices = {
			{
				text = "😎 Work the room confidently",
				effects = { Happiness = 5, Smarts = 2, Money = 200 },
				setFlags = { good_networker = true, professional_connections = true, charismatic = true },
				hintCareer = "business",
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 40 then
						state.Flags.valuable_contact_made = true
						state.Flags.career_opportunity = true
						state:AddFeed("🤝 Made a GREAT connection! Could lead to opportunities!")
					else
						state:AddFeed("🤝 Handed out cards, made small talk. Solid networking!")
					end
				end,
			},
			{
				text = "😰 Awkwardly hover near food",
				effects = { Happiness = -2 },
				setFlags = { networking_anxiety = true, introvert = true },
				feedText = "🤝 At least the appetizers were good...",
			},
			{
				text = "🎯 Target specific people",
				effects = { Happiness = 4, Smarts = 3, Money = 300 },
				setFlags = { strategic_networker = true, professional_connections = true, ambitious = true },
				hintCareer = "finance",
				feedText = "🤝 Quality over quantity! Meaningful conversations!",
			},
			{
				text = "🚪 Leave early",
				effects = { Happiness = 2 },
				setFlags = { avoids_networking = true },
				feedText = "🤝 Not your scene. That's okay!",
			},
		},
	},

	{
		id = "adult_side_gig_opportunity",
		title = "Side Hustle!",
		emoji = "💼",
		textVariants = {
			"Time to start a side hustle?",
			"Extra income opportunities everywhere!",
			"Your main job isn't cutting it...",
			"Everyone has a side hustle these days!",
		},
		text = "Time to start a side hustle?",
		question = "What's your side hustle?",
		minAge = 20, maxAge = 55,
		baseChance = 0.35,
		cooldown = 5,
		category = "adult",
		tags = { "adult", "money", "hustle" },
		careerTags = { "business", "tech", "entertainment" },
		
		choices = {
			{
				text = "🚗 Gig economy (driving/delivery)",
				effects = { Happiness = 2, Money = 300, Health = -2 },
				setFlags = { gig_worker = true, hustle_mindset = true },
				feedText = "💼 Flexible hours, decent money. The grind continues!",
				-- CRITICAL FIX: User bug "SIDE GIG DRIVING LIKE BUT I DONT HAVE A CAR??"
				-- Only show driving option if player has a vehicle!
				eligibility = function(state)
					if not state then return false end
					-- Check if player has any vehicle
					if state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0 then
						return true
					end
					-- Also check flags for car ownership
					if state.Flags and (state.Flags.owns_car or state.Flags.has_vehicle or state.Flags.owns_vehicle) then
						return true
					end
					-- Check if they have driver's license at least (can rent/borrow)
					if state.Flags and state.Flags.has_drivers_license then
						return true
					end
					return false
				end,
			},
			{
				text = "🚴 Delivery by bike/walking",
				effects = { Happiness = 1, Money = 150, Health = 3 },
				setFlags = { gig_worker = true, hustle_mindset = true, physically_active = true },
				feedText = "💼 No car? No problem! Deliver on foot or bike. Great exercise!",
			},
			{
				text = "💻 Freelance your skills",
				effects = { Happiness = 4, Money = 500, Smarts = 2 },
				setFlags = { freelancer = true, entrepreneur = true, self_employed = true },
				hintCareer = "tech",
				feedText = "💼 Using your talents for extra cash! Smart!",
			},
			{
				text = "📦 Sell stuff online",
				effects = { Happiness = 3, Money = 200 },
				setFlags = { online_seller = true, entrepreneur = true, business_minded = true },
				hintCareer = "business",
				feedText = "💼 One person's trash... your profit!",
			},
			{
				text = "🙅 No time for that",
				effects = { Happiness = 3 },
				setFlags = { values_free_time = true, work_life_balance = true },
				feedText = "💼 Work-life balance matters. Money isn't everything!",
			},
		},
	},

	{
		id = "adult_friendship_fade",
		title = "Friendship Fading...",
		emoji = "👋",
		textVariants = {
			"An old friendship is drifting apart...",
			"You haven't talked to your friend in months...",
			"Life got busy and friendships suffered...",
			"Are you growing apart from people?",
		},
		text = "An old friendship is drifting apart...",
		question = "What do you do?",
		minAge = 25, maxAge = 60,
		baseChance = 0.35,
		cooldown = 5,
		category = "adult",
		tags = { "adult", "friends", "relationships" },
		
		choices = {
			{
				text = "📱 Reach out and reconnect",
				effects = { Happiness = 5 },
				setFlags = { maintains_friendships = true, good_friend = true, loyal = true },
				feedText = "👋 You reached out! Sometimes that's all it takes!",
				relationshipEffect = { type = "friend", change = 20 },
			},
			{
				text = "😔 Accept people grow apart",
				effects = { Happiness = -2, Smarts = 2 },
				setFlags = { accepts_change = true, realistic = true },
				feedText = "👋 Sad but natural. Not all friendships last forever.",
				relationshipEffect = { type = "friend", change = -15 },
			},
			{
				text = "🆕 Focus on making new friends",
				effects = { Happiness = 4 },
				setFlags = { makes_new_friends = true, social_butterfly = true },
				feedText = "👋 New chapter, new people! Moving forward!",
			},
			{
				text = "🤷 Was I ever that close to them?",
				effects = { Happiness = 2 },
				setFlags = { emotionally_distant = true },
				feedText = "👋 Maybe it was more casual than you thought.",
			},
		},
	},

	{
		id = "adult_social_comparison",
		title = "Comparison Trap!",
		emoji = "📱",
		textVariants = {
			"Everyone on social media seems more successful...",
			"Your ex just got engaged. You're eating cereal.",
			"High school friends are buying houses while you...",
			"Everyone's highlight reel vs. your behind-the-scenes...",
		},
		text = "Everyone on social media seems more successful...",
		question = "How do you handle comparison?",
		minAge = 22, maxAge = 45,
		baseChance = 0.4,
		cooldown = 5,
		category = "adult",
		tags = { "adult", "social", "mental_health" },
		
		choices = {
			{
				text = "📵 Social media detox",
				effects = { Happiness = 6, Health = 2 },
				setFlags = { did_social_detox = true, values_reality = true },
				feedText = "📱 Stepping away from the highlight reel. Peace!",
			},
			{
				text = "💪 Use it as motivation",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { competitive_motivation = true },
				feedText = "📱 If they can do it, so can I! Let's go!",
			},
			{
				text = "🙏 Practice gratitude",
				effects = { Happiness = 5 },
				setFlags = { grateful_mindset = true },
				feedText = "📱 Counting YOUR blessings. Life is good actually!",
			},
			{
				text = "😔 Spiral into self-doubt",
				effects = { Happiness = -5 },
				setFlags = { comparison_struggles = true },
				feedText = "📱 It's hard not to compare. Be kind to yourself.",
			},
		},
	},

	{
		id = "adult_passive_income",
		title = "Passive Income Dream!",
		emoji = "💰",
		textVariants = {
			"What if your money worked for you?",
			"Passive income is the dream!",
			"Making money while you sleep?",
			"Building wealth without trading time?",
		},
		text = "What if your money worked for you?",
		question = "How do you pursue passive income?",
		minAge = 25, maxAge = 55,
		baseChance = 0.3,
		cooldown = 6,
		category = "adult",
		tags = { "adult", "money", "investment" },
		requiresStats = { Money = 1000 },
		
		choices = {
			{
				text = "📈 Invest in stocks/index funds",
				effects = { Smarts = 3 },
				setFlags = { passive_investor = true },
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 70 then
						state:ModifyStat("Money", 500)
						state:AddFeed("💰 Your investments are growing! Slow and steady!")
					else
						state:ModifyStat("Money", -300)
						state:AddFeed("💰 Market dipped. Long-term game though!")
					end
				end,
			},
			{
				text = "🏠 Save for rental property",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { real_estate_interest = true },
				feedText = "💰 Landlord dreams! One day...",
			},
			{
				text = "💻 Create digital products",
				effects = { Happiness = 4, Smarts = 4 },
				setFlags = { digital_entrepreneur = true },
				feedText = "💰 E-books, courses, templates - sell while you sleep!",
			},
			{
				text = "🎰 Get rich quick schemes",
				effects = { Happiness = 2 },
				setFlags = { falls_for_schemes = true },
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 10 then
						state:ModifyStat("Money", 2000)
						state:AddFeed("💰 Wait... it actually worked?! Lucky!")
					else
						state:ModifyStat("Money", -500)
						state:AddFeed("💰 Shocker - the scheme was a scam.")
					end
				end,
			},
		},
	},

	{
		id = "adult_burnout",
		title = "Burnout!",
		emoji = "🔥",
		textVariants = {
			"You're running on empty...",
			"Work, life, everything - too much!",
			"The candle has burned at both ends...",
			"You can't keep this pace up...",
		},
		text = "You're running on empty...",
		question = "How do you handle burnout?",
		minAge = 25, maxAge = 60,
		baseChance = 0.35,
		cooldown = 5,
		category = "adult",
		tags = { "adult", "health", "work" },
		
		choices = {
			{
				text = "🏖️ Take time off",
				effects = { Happiness = 8, Health = 5, Money = -300 },
				setFlags = { took_mental_health_break = true },
				feedText = "🔥 Rest is productive. You needed this!",
			},
			{
				text = "💪 Push through",
				effects = { Happiness = -4, Health = -5, Money = 500 },
				setFlags = { pushed_through_burnout = true },
				feedText = "🔥 Made it work but at what cost?",
			},
			{
				text = "🔄 Make lifestyle changes",
				effects = { Happiness = 5, Health = 3 },
				setFlags = { lifestyle_change = true },
				feedText = "🔥 Setting boundaries. Saying no. Self-care!",
			},
			{
				text = "🚪 Quit the source of stress",
				effects = { Happiness = 6, Money = -1000 },
				setFlags = { quit_due_to_burnout = true },
				feedText = "🔥 Mental health > money. Starting fresh!",
			},
		},
	},

	{
		id = "adult_new_hobby",
		title = "New Hobby!",
		emoji = "🎨",
		textVariants = {
			"Time to pick up a new hobby!",
			"You need something just for FUN!",
			"All work and no play? Not anymore!",
			"What will your new passion be?",
		},
		text = "Time to pick up a new hobby!",
		question = "What hobby do you try?",
		minAge = 20, maxAge = 70,
		baseChance = 0.35,
		cooldown = 5,
		category = "adult",
		tags = { "adult", "hobby", "lifestyle" },
		
		choices = {
			{
				text = "🎮 Gaming/Esports",
				effects = { Happiness = 6, Smarts = 2 },
				setFlags = { adult_gamer = true },
				feedText = "🎨 Games are for everyone! Having a blast!",
			},
			{
				text = "🏃 Fitness/Running",
				effects = { Happiness = 5, Health = 5 },
				setFlags = { fitness_hobby = true },
				feedText = "🎨 Runner's high is REAL! Feeling great!",
			},
			{
				text = "📸 Photography",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { photography_hobby = true },
				feedText = "🎨 Capturing moments! Art through the lens!",
			},
			{
				text = "🎸 Music/Instrument",
				effects = { Happiness = 6, Smarts = 3 },
				setFlags = { music_hobby = true },
				feedText = "🎨 Learning an instrument! It's never too late!",
			},
			{
				text = "🪴 Gardening/Plants",
				effects = { Happiness = 5, Health = 2 },
				setFlags = { gardening_hobby = true },
				feedText = "🎨 Plant parent! They're alive! Mostly!",
			},
		},
	},

	{
		id = "adult_dating_apps",
		title = "Dating App Experience!",
		emoji = "💕",
		textVariants = {
			"Swiping right, swiping left...",
			"The modern dating scene is WILD!",
			"Looking for love in the digital age!",
			"Your dating profile is live!",
		},
		text = "Swiping right, swiping left...",
		question = "How's online dating going?",
		minAge = 18, maxAge = 55,
		baseChance = 0.35,
		cooldown = 5,
		category = "adult",
		tags = { "adult", "dating", "romance" },
		blockedByFlags = { has_partner = true, married = true },
		
		choices = {
			{
				text = "💕 Met someone amazing!",
				effects = { Happiness = 10 },
				setFlags = { app_dating_success = true },
				feedText = "💕 Swipe right SUCCESS! A real connection!",
			},
			{
				text = "😬 Mostly disasters",
				effects = { Happiness = -3 },
				setFlags = { app_dating_fails = true },
				feedText = "💕 Bad dates make great stories... right?",
			},
			{
				text = "😴 Lots of matching, no meeting",
				effects = { Happiness = -1 },
				setFlags = { dating_app_fatigue = true },
				feedText = "💕 Conversations that go nowhere. Exhausting!",
			},
			{
				text = "📴 Deleted the apps",
				effects = { Happiness = 4 },
				setFlags = { over_dating_apps = true },
				feedText = "💕 Back to meeting people organically!",
			},
		},
	},

	{
		id = "adult_imposter_syndrome",
		title = "Imposter Syndrome!",
		emoji = "🎭",
		textVariants = {
			"Do you really belong here?",
			"Everyone else seems to know what they're doing...",
			"Are they going to find out you're faking it?",
			"Feeling like a fraud at your job...",
		},
		text = "Do you really belong here?",
		question = "How do you deal with imposter syndrome?",
		minAge = 22, maxAge = 50,
		baseChance = 0.35,
		cooldown = 5,
		category = "adult",
		tags = { "adult", "work", "mental_health" },
		
		choices = {
			{
				text = "💪 Fake it till you make it",
				effects = { Happiness = 3 },
				setFlags = { fakes_confidence = true },
				feedText = "🎭 Act confident, become confident. It works!",
			},
			{
				text = "📝 Track your accomplishments",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { tracks_success = true },
				feedText = "🎭 Actually, you HAVE done a lot! Look at that list!",
			},
			{
				text = "💬 Talk to others about it",
				effects = { Happiness = 6 },
				setFlags = { shares_feelings = true },
				feedText = "🎭 Wait, EVERYONE feels this way sometimes?!",
			},
			{
				text = "😔 Let it hold you back",
				effects = { Happiness = -5 },
				setFlags = { imposter_syndrome_struggles = true },
				feedText = "🎭 The doubt is paralyzing. You deserve to be here!",
			},
		},
	},

	{
		id = "adult_mentor_opportunity",
		title = "Mentor Opportunity!",
		emoji = "🧑‍🏫",
		textVariants = {
			"Someone wants YOU to be their mentor!",
			"A chance to give back and teach!",
			"Could you guide someone else's journey?",
			"Mentorship opportunity knocks!",
		},
		text = "Someone wants YOU to be their mentor!",
		question = "Do you take on a mentee?",
		minAge = 30, maxAge = 65,
		baseChance = 0.3,
		cooldown = 6,
		category = "adult",
		tags = { "adult", "career", "teaching" },
		requiresStats = { Smarts = 60 },
		
		choices = {
			{
				text = "👍 Absolutely! Paying it forward!",
				effects = { Happiness = 7, Smarts = 2 },
				setFlags = { is_mentor = true, gives_back = true },
				feedText = "🧑‍🏫 Teaching others helps you grow too! Rewarding!",
			},
			{
				text = "😅 Not sure I'm qualified",
				effects = { Happiness = 2 },
				setFlags = { humble = true },
				feedText = "🧑‍🏫 You have more to offer than you think!",
			},
			{
				text = "⏰ Don't have the time",
				effects = { Happiness = 1 },
				setFlags = { too_busy = true },
				feedText = "🧑‍🏫 Life is full. Maybe another time.",
			},
		},
	},

	{
		id = "adult_existential_thoughts",
		title = "Deep Thoughts!",
		emoji = "🌌",
		textVariants = {
			"Late night existential crisis!",
			"What's the meaning of all this?",
			"Deep thoughts at 3 AM...",
			"Pondering life's big questions!",
		},
		text = "Late night existential crisis!",
		question = "What conclusion do you come to?",
		minAge = 25, maxAge = 70,
		baseChance = 0.3,
		cooldown = 6,
		category = "adult",
		tags = { "adult", "philosophy", "growth" },
		
		choices = {
			{
				text = "🎯 Find meaning in your work",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { meaning_in_work = true },
				feedText = "🌌 Purpose through contribution! Makes sense!",
			},
			{
				text = "❤️ It's about relationships",
				effects = { Happiness = 6 },
				setFlags = { meaning_in_love = true },
				feedText = "🌌 Love and connection. That's what matters!",
			},
			{
				text = "🎉 Just enjoy the ride",
				effects = { Happiness = 5 },
				setFlags = { meaning_in_joy = true },
				feedText = "🌌 Life is meant to be lived! Enjoy it!",
			},
			{
				text = "🤷 Still figuring it out",
				effects = { Happiness = 2, Smarts = 2 },
				setFlags = { meaning_seeking = true },
				feedText = "🌌 The search continues. That's okay too.",
			},
		},
	},

	{
		id = "adult_reunion",
		title = "Reunion Time!",
		emoji = "👥",
		textVariants = {
			"High school reunion! Will you go?",
			"Class reunion invite arrived!",
			"Time to see old classmates...",
			"The reunion is happening!",
		},
		text = "High school reunion! Will you go?",
		question = "Do you attend?",
		minAge = 28, maxAge = 60,
		baseChance = 0.3,
		cooldown = 8,
		category = "adult",
		tags = { "adult", "social", "nostalgia" },
		
		choices = {
			{
				text = "🎉 Go and have a blast!",
				effects = { Happiness = 7 },
				setFlags = { attended_reunion = true, social_person = true },
				feedText = "👥 Great seeing everyone! Some surprises! Good memories!",
			},
			{
				text = "😬 Go but it's awkward",
				effects = { Happiness = 2 },
				setFlags = { attended_reunion = true },
				feedText = "👥 Some things don't change. Some things REALLY do.",
			},
			{
				text = "📵 Hard pass",
				effects = { Happiness = 3 },
				setFlags = { skipped_reunion = true },
				feedText = "👥 High school is in the past for a reason!",
			},
			{
				text = "📱 Stalk from social media instead",
				effects = { Happiness = 4 },
				setFlags = { reunion_stalker = true },
				feedText = "👥 Why go when you can see everything online?",
			},
		},
	},

	{
		id = "adult_random_kindness",
		title = "Random Kindness!",
		emoji = "💝",
		textVariants = {
			"Opportunity to help a stranger!",
			"Someone needs help - do you step up?",
			"A chance to make someone's day!",
			"Kindness moment incoming!",
		},
		text = "Opportunity to help a stranger!",
		question = "What do you do?",
		minAge = 18, maxAge = 80,
		baseChance = 0.35,
		cooldown = 5,
		category = "adult",
		tags = { "adult", "kindness", "community" },
		
		choices = {
			{
				text = "💝 Help without hesitation",
				effects = { Happiness = 6, Health = 2 },
				setFlags = { kind_person = true },
				feedText = "💝 You helped! Feels good to do good!",
			},
			{
				text = "💰 Help AND pay it forward",
				effects = { Happiness = 8, Money = -50 },
				setFlags = { very_generous = true },
				feedText = "💝 Went above and beyond! Made their whole week!",
			},
			{
				text = "😟 Want to help but can't",
				effects = { Happiness = -2 },
				feedText = "💝 Sometimes we can't. Don't be too hard on yourself.",
			},
			{
				text = "🚶 Keep walking",
				effects = { Happiness = -1 },
				setFlags = { missed_kindness_chance = true },
				feedText = "💝 Life is busy. But maybe next time...",
			},
		},
	},

-- ════════════════════════════════════════════════════════════════════════════
-- MASSIVE VARIETY EXPANSION: Career-Personalized Events
-- Events that change based on your job/career flags for unique experiences!
-- ════════════════════════════════════════════════════════════════════════════

	{
		id = "adult_tech_burnout",
		title = "Tech Industry Burnout",
		emoji = "💻",
		textVariants = {
			"Staring at screens for 12 hours a day is taking its toll...",
			"Another urgent Slack message at 11pm. When does it end?",
			"Your GitHub contributions are strong but your soul is weak.",
			"Sprint planning, standup, retro, repeat. The cycle never ends.",
			"You've debugged 47 issues this week. You ARE the bug now.",
		},
		text = "The tech grind is wearing you down...",
		question = "How do you cope?",
		minAge = 22, maxAge = 55,
		baseChance = 0.25,
		cooldown = 6,
		category = "career",
		tags = { "career", "tech", "burnout" },
		requiresAnyFlags = { developer_experience = true, coder = true, tech_experience = true, software_engineer = true },
		
		choices = {
			{
				text = "📵 Digital detox weekend",
				effects = { Happiness = 8, Health = 5, Smarts = -2 },
				setFlags = { manages_burnout = true },
				feedText = "💻 No screens for 48 hours. You remembered what grass looks like!",
			},
			{
				text = "🏃 Start exercising between sprints",
				effects = { Happiness = 5, Health = 8 },
				setFlags = { healthy_dev = true },
				feedText = "💻 Pushups between pushes. Your body thanks you!",
			},
			{
				text = "🔄 Ask for different project",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { career_pivoted = true },
				feedText = "💻 New codebase, fresh challenges. Sometimes change helps!",
			},
			{
				text = "☕ Just more coffee",
				effects = { Happiness = -3, Health = -5 },
				setFlags = { coffee_dependent = true, ignoring_burnout = true },
				feedText = "💻 Your blood is 40% caffeine now. This isn't sustainable...",
			},
		},
	},

	{
		id = "adult_office_politics",
		title = "Office Politics Drama",
		emoji = "🏢",
		textVariants = {
			"There's drama brewing in the break room...",
			"Teams are forming. Whose side are you on?",
			"The office is divided. Upper management vs everyone else.",
			"Whispered conversations stop when you walk by. Awkward.",
			"Someone's getting thrown under the bus. Don't let it be you.",
		},
		text = "Office politics are heating up!",
		question = "How do you navigate this?",
		minAge = 22, maxAge = 65,
		baseChance = 0.3,
		cooldown = 5,
		category = "career",
		tags = { "career", "office", "drama" },
		requiresAnyFlags = { employed = true, has_job = true, career_started = true },
		blockedByFlags = { self_employed = true, freelancer = true },
		
		choices = {
			{
				text = "🤝 Stay neutral, be Switzerland",
				effects = { Happiness = 3, Smarts = 3 },
				setFlags = { office_diplomat = true },
				feedText = "🏢 You stayed out of it. Smart move. Trust maintained.",
			},
			{
				text = "🎯 Side with whoever's winning",
				effects = { Happiness = 4, Money = 200 },
				setFlags = { political_player = true },
				feedText = "🏢 You picked the right side. Bonus incoming!",
			},
			{
				text = "🦸 Defend the underdog",
				effects = { Happiness = 6, Smarts = -1 },
				setFlags = { office_hero = true, made_enemies = true },
				feedText = "🏢 You spoke up for what's right. Some appreciate it. Others don't.",
			},
			{
				text = "📱 Document everything",
				effects = { Happiness = 2, Smarts = 4 },
				setFlags = { cautious_employee = true },
				feedText = "🏢 Emails saved. Receipts collected. Always be prepared.",
			},
		},
	},

	{
		id = "adult_friend_drift",
		title = "Friendship Growing Apart",
		emoji = "👥",
		textVariants = {
			"You and your best friend haven't hung out in months...",
			"Life got busy. You've both changed. Is this friendship over?",
			"Your old friend's life went a completely different direction.",
			"You used to talk every day. Now? Read receipts and silence.",
			"Do friendships have an expiration date?",
		},
		text = "An important friendship feels like it's fading...",
		question = "What do you do?",
		minAge = 22, maxAge = 60,
		baseChance = 0.3,
		cooldown = 6,
		category = "social",
		tags = { "social", "friends", "growth" },
		
		choices = {
			{
				text = "📱 Reach out - plan something!",
				effects = { Happiness = 7 },
				setFlags = { maintains_friendships = true, loyal_friend = true },
				feedText = "👥 You made the effort! Lunch next week! Friendship saved!",
			},
			{
				text = "🤷 Accept it - people change",
				effects = { Happiness = -2, Smarts = 3 },
				setFlags = { accepting_of_change = true },
				feedText = "👥 Sad but mature. Not all friendships last forever.",
			},
			{
				text = "😤 Confront them about it",
				effects = { Happiness = 4 },
				setFlags = { direct_communicator = true },
				feedText = "👥 'Are we still friends?' Awkward but necessary conversation.",
			},
			{
				text = "🆕 Focus on new friendships",
				effects = { Happiness = 5 },
				setFlags = { social_butterfly = true },
				feedText = "👥 Making new friends doesn't mean forgetting old ones!",
			},
		},
	},

	{
		id = "adult_money_windfall",
		title = "Unexpected Money!",
		emoji = "💰",
		textVariants = {
			"You found $500 in an old coat pocket!",
			"Tax refund was way bigger than expected!",
			"Distant relative left you some money!",
			"Your side project actually made money!",
			"Won a small prize! Not lottery, but still nice!",
		},
		text = "Unexpected money came your way!",
		question = "What do you do with it?",
		minAge = 18, maxAge = 80,
		baseChance = 0.25,
		cooldown = 8,
		category = "finance",
		tags = { "money", "windfall", "choices" },
		
		choices = {
			{
				text = "💰 Straight to savings",
				effects = { Happiness = 3, Money = 500, Smarts = 2 },
				setFlags = { good_saver = true },
				feedText = "💰 Smart! Future you will thank present you!",
			},
			{
				text = "🛍️ Treat yourself!",
				effects = { Happiness = 8, Money = 200 },
				setFlags = { enjoys_rewards = true },
				feedText = "💰 You deserve nice things sometimes! Enjoy!",
			},
			{
				text = "🎁 Share with loved ones",
				effects = { Happiness = 6, Money = 250 },
				setFlags = { generous_person = true },
				feedText = "💰 Spreading the wealth! Making others happy makes YOU happy!",
			},
			{
				text = "📈 Invest it",
				effects = { Happiness = 4, Money = 400, Smarts = 3 },
				setFlags = { investor_mindset = true },
				feedText = "💰 Money making money! Compound interest baby!",
			},
		},
	},

	{
		id = "adult_creative_block",
		title = "Creative Block!",
		emoji = "🎨",
		textVariants = {
			"Your creative well has run dry...",
			"Staring at a blank canvas/page/screen for hours...",
			"Where did all your inspiration go?",
			"Everything you make feels... wrong.",
			"The muse has abandoned you.",
		},
		text = "You're experiencing a major creative block!",
		question = "How do you break through?",
		minAge = 18, maxAge = 70,
		baseChance = 0.25,
		cooldown = 6,
		category = "hobby",
		tags = { "creative", "art", "struggle" },
		requiresAnyFlags = { artistic = true, creative = true, musician = true, writer = true, passionate_performer = true },
		
		choices = {
			{
				text = "🚶 Take a long walk in nature",
				effects = { Happiness = 5, Health = 3 },
				setFlags = { finds_inspiration_outdoors = true },
				feedText = "🎨 Fresh air, new perspective. Ideas starting to flow again!",
			},
			{
				text = "🎭 Try a completely different medium",
				effects = { Happiness = 6, Smarts = 3 },
				setFlags = { versatile_creator = true },
				feedText = "🎨 Painter trying writing? Writer trying music? Fresh approach!",
			},
			{
				text = "📚 Consume other people's art",
				effects = { Happiness = 4, Smarts = 4 },
				setFlags = { studies_masters = true },
				feedText = "🎨 Museums, books, concerts - refilling the creative tank!",
			},
			{
				text = "😤 Force through it",
				effects = { Happiness = -3, Smarts = 2 },
				setFlags = { disciplined_artist = true },
				feedText = "🎨 The work is bad but you're WORKING. That's what matters.",
			},
		},
	},

	{
		id = "adult_health_wake_up",
		title = "Health Reality Check",
		emoji = "🏥",
		textVariants = {
			"Doctor's visit gave you a wake-up call...",
			"Those numbers on the scale aren't great...",
			"You get winded climbing one flight of stairs...",
			"Your body is sending warning signals.",
			"Time to take health more seriously.",
		},
		text = "Your health needs attention!",
		question = "What changes do you make?",
		minAge = 28, maxAge = 70,
		baseChance = 0.3,
		cooldown = 7,
		category = "health",
		tags = { "health", "wellness", "lifestyle" },
		
		choices = {
			{
				text = "🥗 Complete diet overhaul",
				effects = { Happiness = 4, Health = 10, Money = -100 },
				setFlags = { healthy_eater = true, diet_change = true },
				feedText = "🏥 More vegetables, less junk. Your body is thanking you!",
			},
			{
				text = "🏃 Start exercising regularly",
				effects = { Happiness = 6, Health = 12 },
				setFlags = { regular_exerciser = true },
				feedText = "🏥 Gym membership actually being used! Progress!",
			},
			{
				text = "😴 Focus on sleep first",
				effects = { Happiness = 5, Health = 8, Smarts = 2 },
				setFlags = { prioritizes_sleep = true },
				feedText = "🏥 8 hours a night. Amazing what rest can do!",
			},
			{
				text = "🙈 Ignore it for now",
				effects = { Happiness = 2, Health = -5 },
				setFlags = { health_procrastinator = true },
				feedText = "🏥 Future you is very disappointed in present you...",
			},
		},
	},

	{
		id = "adult_unexpected_bill",
		title = "Surprise Expense!",
		emoji = "💸",
		textVariants = {
			"Car repair bill: WAY more than expected!",
			"Medical bill arrived. That's... a lot of zeros.",
			"Home repair emergency - not cheap!",
			"Phone screen shattered. Again.",
			"Life is expensive and it just got more expensive.",
		},
		text = "An unexpected bill just hit your wallet!",
		question = "How do you handle it?",
		minAge = 18, maxAge = 80,
		baseChance = 0.35,
		cooldown = 5,
		category = "finance",
		tags = { "money", "stress", "bills" },
		
		choices = {
			{
				text = "💰 Emergency fund to the rescue!",
				effects = { Happiness = 2, Money = -300 },
				setFlags = { prepared_financially = true },
				eligibility = function(state) return (state.Money or 0) >= 500, "Need $500+ savings" end,
				feedText = "💸 This is exactly why you saved! Still stings though.",
			},
			{
				text = "💳 Put it on credit",
				effects = { Happiness = -2, Money = -50 },
				setFlags = { uses_credit = true, has_debt = true },
				feedText = "💸 Immediate problem solved. Future problem created.",
			},
			{
				text = "📱 Ask family for help",
				effects = { Happiness = -3, Money = 0 },
				setFlags = { asked_family_for_money = true },
				feedText = "💸 They helped. But there was a lecture too.",
			},
			{
				text = "🔧 Try to fix it yourself",
				effects = { Happiness = 4, Smarts = 2, Money = -100 },
				setFlags = { diy_person = true },
				feedText = "💸 YouTube tutorials for the win! Mostly worked!",
			},
		},
	},

	{
		id = "adult_new_passion_discovery",
		title = "New Hobby Discovered!",
		emoji = "✨",
		textVariants = {
			"You tried something new and... you LOVE it!",
			"A friend introduced you to their hobby. You're hooked!",
			"What started as curiosity became an obsession!",
			"Finally found something to be passionate about!",
			"This might be your new thing!",
		},
		text = "You discovered a new hobby that excites you!",
		question = "How do you pursue it?",
		minAge = 18, maxAge = 75,
		baseChance = 0.3,
		cooldown = 8,
		category = "hobby",
		tags = { "hobby", "discovery", "passion" },
		
		choices = {
			{
				text = "🚀 Go all in! Equipment, classes, everything!",
				effects = { Happiness = 10, Money = -500, Smarts = 3 },
				setFlags = { committed_hobbyist = true, passionate_about_hobby = true },
				feedText = "✨ This is YOUR thing now! Investment made!",
			},
			{
				text = "📚 Learn slowly and thoroughly",
				effects = { Happiness = 6, Smarts = 5 },
				setFlags = { patient_learner = true },
				feedText = "✨ Taking your time. Enjoying the learning process!",
			},
			{
				text = "👥 Join a community/group",
				effects = { Happiness = 8 },
				setFlags = { social_hobbyist = true },
				feedText = "✨ New hobby AND new friends! Double win!",
			},
			{
				text = "🤫 Keep it casual for now",
				effects = { Happiness = 5 },
				setFlags = { casual_hobbyist = true },
				feedText = "✨ No pressure. Just fun. That's what hobbies should be!",
			},
		},
	},

	{
		id = "adult_neighbor_drama",
		title = "Neighbor Situation!",
		emoji = "🏘️",
		textVariants = {
			"Your neighbor is playing music at 2am. AGAIN.",
			"Their dog won't stop barking. Ever.",
			"They keep parking in YOUR spot!",
			"Passive aggressive notes are being exchanged.",
			"The neighborhood group chat is getting HEATED.",
		},
		text = "Neighbor drama is affecting your peace!",
		question = "How do you handle it?",
		minAge = 20, maxAge = 80,
		baseChance = 0.3,
		cooldown = 6,
		category = "home",
		tags = { "home", "neighbors", "conflict" },
		
		choices = {
			{
				text = "🗣️ Have a calm, direct conversation",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { good_communicator = true },
				feedText = "🏘️ You talked it out! They actually didn't realize. Problem solved!",
			},
			{
				text = "📝 Leave a polite note",
				effects = { Happiness = 2 },
				setFlags = { passive_approach = true },
				feedText = "🏘️ Note delivered. Hoping they get the message...",
			},
			{
				text = "😤 Give them a taste of their own medicine",
				effects = { Happiness = 3, Health = -2 },
				setFlags = { petty_neighbor = true },
				feedText = "🏘️ If they can be loud at 2am, SO CAN YOU. War begun.",
			},
			{
				text = "🎧 Noise-canceling headphones",
				effects = { Happiness = 4, Money = -80 },
				setFlags = { avoids_conflict = true },
				feedText = "🏘️ Can't hear drama if you're vibing to your playlist!",
			},
		},
	},

	{
		id = "adult_social_event_invite",
		title = "Social Event Invitation!",
		emoji = "🎉",
		textVariants = {
			"You've been invited to a party! Do you know anyone there?",
			"Wedding invitation arrived! It's a long trip though...",
			"Coworker's birthday party - mandatory fun?",
			"Old friend's gathering - haven't seen them in years!",
			"Networking event - could be good for your career!",
		},
		text = "You've been invited to a social event!",
		question = "Do you go?",
		minAge = 18, maxAge = 75,
		baseChance = 0.35,
		cooldown = 5,
		category = "social",
		tags = { "social", "events", "choices" },
		
		choices = {
			{
				text = "🎉 Absolutely! Let's socialize!",
				effects = { Happiness = 7, Money = -50 },
				setFlags = { social_person = true },
				feedText = "🎉 Great time! New connections made! Worth it!",
			},
			{
				text = "😬 Go but leave early",
				effects = { Happiness = 3 },
				setFlags = { shows_face = true },
				feedText = "🎉 Made an appearance. Irish goodbye successful.",
			},
			{
				text = "🙅 Politely decline",
				effects = { Happiness = 4 },
				setFlags = { values_alone_time = true },
				feedText = "🎉 Couch time is valuable too. No regrets.",
			},
			{
				text = "🤔 Only if someone I know is going",
				effects = { Happiness = 5 },
				setFlags = { needs_social_buffer = true },
				feedText = "🎉 Found a buddy! Much better with company!",
			},
		},
	},

	{
		id = "adult_career_opportunity",
		title = "Career Opportunity!",
		emoji = "📈",
		textVariants = {
			"A recruiter reached out with an interesting offer...",
			"Your boss mentioned a promotion might be coming!",
			"A competitor wants to poach you!",
			"Leadership role just opened up in your department!",
			"Your skills are in demand right now!",
		},
		text = "A career opportunity has appeared!",
		question = "What do you do?",
		minAge = 22, maxAge = 60,
		baseChance = 0.3,
		cooldown = 6,
		category = "career",
		tags = { "career", "opportunity", "growth" },
		requiresAnyFlags = { employed = true, has_job = true, career_started = true },
		
		choices = {
			{
				text = "🚀 Pursue it aggressively!",
				effects = { Happiness = 5, Money = 500, Smarts = 2 },
				setFlags = { career_ambitious = true, promotion_earned = true },
				feedText = "📈 You went for it! New title, new responsibilities, new MONEY!",
			},
			{
				text = "🤝 Use it to negotiate current position",
				effects = { Happiness = 4, Money = 300 },
				setFlags = { good_negotiator = true },
				feedText = "📈 Counter-offer accepted! Staying put with a raise!",
			},
			{
				text = "🤔 Think about it carefully",
				effects = { Happiness = 3, Smarts = 3 },
				setFlags = { thoughtful_decision_maker = true },
				feedText = "📈 Pros and cons listed. Taking time to decide right.",
			},
			{
				text = "😌 Happy where I am",
				effects = { Happiness = 5 },
				setFlags = { content_with_career = true },
				feedText = "📈 Money isn't everything. You like your work-life balance!",
			},
		},
	},

	{
		id = "adult_life_milestone_reflection",
		title = "Life Milestone!",
		emoji = "🎂",
		textVariants = {
			"Another birthday. Another year older. Time for reflection...",
			"Looking through old photos. Where did the time go?",
			"Life milestone approaching. How do you feel about it?",
			"You're entering a new decade of life!",
			"Time to take stock of where you are in life.",
		},
		text = "Time for life reflection!",
		question = "How are you feeling about life?",
		minAge = 30, maxAge = 70,
		baseChance = 0.25,
		cooldown = 10,
		category = "life",
		tags = { "life", "reflection", "growth" },
		
		choices = {
			{
				text = "😊 Proud of how far I've come!",
				effects = { Happiness = 8, Health = 3 },
				setFlags = { self_proud = true, positive_reflection = true },
				feedText = "🎂 You've accomplished a lot! Celebrate yourself!",
			},
			{
				text = "🎯 Setting new goals for next chapter",
				effects = { Happiness = 6, Smarts = 3 },
				setFlags = { goal_oriented = true, forward_thinking = true },
				feedText = "🎂 The best is yet to come! New adventures await!",
			},
			{
				text = "😰 Feeling behind compared to others",
				effects = { Happiness = -4 },
				setFlags = { comparison_trap = true },
				feedText = "🎂 Everyone's journey is different. Don't compare!",
			},
			{
				text = "🙏 Grateful for what I have",
				effects = { Happiness = 7 },
				setFlags = { grateful_heart = true },
				feedText = "🎂 Gratitude is the attitude! Life is good!",
			},
		},
	},

	{
		id = "adult_pet_consideration",
		title = "Thinking About a Pet!",
		emoji = "🐾",
		textVariants = {
			"Your place feels empty... maybe a furry friend would help?",
			"You've been watching pet videos non-stop. Is this a sign?",
			"Friend's pet is SO cute. You want one!",
			"Adopting a pet could change your life!",
			"Ready for the responsibility of a pet?",
		},
		text = "You're thinking about getting a pet!",
		question = "Do you take the plunge?",
		minAge = 20, maxAge = 70,
		baseChance = 0.25,
		cooldown = 8,
		category = "life",
		tags = { "life", "pets", "decisions" },
		blockedByFlags = { has_pet = true },
		
		choices = {
			{
				text = "🐕 Adopt a dog!",
				effects = { Happiness = 10, Money = -200, Health = 3 },
				setFlags = { has_pet = true, dog_owner = true, pet_parent = true },
				feedText = "🐾 Welcome home, furry friend! Best decision ever!",
			},
			{
				text = "🐱 Get a cat!",
				effects = { Happiness = 9, Money = -150 },
				setFlags = { has_pet = true, cat_owner = true, pet_parent = true },
				feedText = "🐾 A fluffy overlord joins your home! You serve them now!",
			},
			{
				text = "🤔 Not the right time",
				effects = { Happiness = 2 },
				setFlags = { waiting_for_pet = true },
				feedText = "🐾 Responsible choice. Pets are a big commitment!",
			},
			{
				text = "🐠 Start small - fish or hamster",
				effects = { Happiness = 5, Money = -50 },
				setFlags = { has_pet = true, small_pet_owner = true },
				feedText = "🐾 Baby steps! Still a life to care for!",
			},
		},
	},

	{
		id = "adult_random_encounter",
		title = "Random Encounter!",
		emoji = "🎲",
		textVariants = {
			"You bumped into someone interesting at the coffee shop!",
			"The person next to you on the plane wants to chat!",
			"Random conversation at a bar turned fascinating!",
			"Met someone at a bookstore - same favorite author!",
			"Chance encounter that could lead somewhere!",
		},
		text = "A random encounter with a stranger!",
		question = "How do you engage?",
		minAge = 18, maxAge = 75,
		baseChance = 0.3,
		cooldown = 5,
		category = "social",
		tags = { "social", "random", "connection" },
		
		choices = {
			{
				text = "💬 Have a deep conversation",
				effects = { Happiness = 6, Smarts = 2 },
				setFlags = { open_to_strangers = true },
				feedText = "🎲 Fascinating talk! New perspective gained!",
			},
			{
				text = "📱 Exchange contact info",
				effects = { Happiness = 5 },
				setFlags = { makes_connections = true },
				feedText = "🎲 New contact added! Maybe a future friend?",
			},
			{
				text = "😊 Pleasant small talk, move on",
				effects = { Happiness = 3 },
				feedText = "🎲 Nice moment, but life moves on. That's okay!",
			},
			{
				text = "🎧 Headphones in - not today",
				effects = { Happiness = 2 },
				setFlags = { values_peace = true },
				feedText = "🎲 Sometimes you just want to be in your own world!",
			},
		},
	},
}

return Adult
