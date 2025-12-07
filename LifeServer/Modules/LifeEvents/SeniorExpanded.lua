--[[
    Senior Expanded Events (Ages 60+)
    Additional senior events with deep, realistic scenarios
    All events use randomized outcomes - NO god mode
]]

local SeniorExpanded = {}

local STAGE = "senior"

SeniorExpanded.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- RETIREMENT LIFE (Ages 60-80)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "senior_travel_dreams",
		title = "Travel Dreams",
		emoji = "✈️",
		text = "Finally have time to travel! The world awaits!",
		question = "Where do you go?",
		minAge = 60, maxAge = 85,
		baseChance = 0.35,
		cooldown = 3,
		stage = STAGE,
		ageBand = "senior",
		category = "leisure",
		tags = { "travel", "retirement", "adventure" },
		
		eligibility = function(state)
			local money = state.Money or 0
			local health = (state.Stats and state.Stats.Health) or 50
			-- CRITICAL FIX: Check for MOST EXPENSIVE choice ($3000), not $1000
			if money < 3000 then
				return false, "Can't afford to travel"
			end
			if health < 30 then
				return false, "Health doesn't permit travel"
			end
			-- CRITICAL FIX: Can't travel from prison!
			if state.Flags and (state.Flags.in_prison or state.Flags.incarcerated) then
				return false, "Can't travel from prison"
			end
			return true
		end,
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL: Random travel outcome
		choices = {
			{
				text = "Dream vacation abroad",
				effects = { Money = -3000 },
				feedText = "Off to see the world...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Health", 2)
						state.Flags = state.Flags or {}
						state.Flags.world_traveler = true
						state:AddFeed("✈️ Incredible trip! Memories of a lifetime!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("✈️ Great trip with minor hiccups. Still wonderful.")
					else
						state:ModifyStat("Happiness", 2)
						state:ModifyStat("Health", -3)
						state:AddFeed("✈️ Got sick during trip. Still glad you went.")
					end
				end,
			},
			{
				text = "Road trip adventure",
				effects = { Money = -800, Happiness = 10, Health = 1 },
				feedText = "Open road, no schedule, pure freedom!",
			},
			{
				text = "Cruise ship vacation",
				effects = { Money = -2000 },
				feedText = "Setting sail...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 12)
						state:AddFeed("✈️ Perfect cruise! Great food, great ports, relaxing!")
					else
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", -2)
						state:AddFeed("✈️ Got seasick. Still fun but rough moments.")
					end
				end,
			},
			{
				text = "Save money - stay local",
				effects = { Happiness = 3, Money = 100 },
				feedText = "Plenty to see close to home. Being responsible.",
			},
		},
	},
	{
		id = "senior_volunteer_work",
		title = "Volunteer Calling",
		emoji = "🤝",
		text = "With more free time, you're drawn to volunteering.",
		question = "What kind of volunteering interests you?",
		minAge = 60, maxAge = 90,
		baseChance = 0.3,
		cooldown = 4,
		stage = STAGE,
		ageBand = "senior",
		category = "purpose",
		tags = { "volunteer", "community", "purpose" },
		
		choices = {
			{ text = "Mentoring young people", effects = { Happiness = 10, Smarts = 2 }, setFlags = { mentor_senior = true }, feedText = "Passing on life lessons. They actually listen!" },
			{ text = "Animal shelter work", effects = { Happiness = 8, Health = 2 }, setFlags = { animal_volunteer = true }, feedText = "Helping homeless pets find homes. Rewarding!" },
			{ text = "Food bank/homeless services", effects = { Happiness = 9, Smarts = 1 }, setFlags = { helping_needy = true }, feedText = "Making a real difference for those in need." },
			{ text = "Hospital/hospice volunteer", effects = { Happiness = 6, Smarts = 2 }, setFlags = { hospital_volunteer = true }, feedText = "Being there for others in difficult times. Profound." },
			{ text = "Too busy enjoying retirement", effects = { Happiness = 3 }, feedText = "Maybe later. Right now, relaxation is the priority." },
		},
	},
	{
		id = "senior_grandchildren_relationship",
		title = "Grandchildren Bond",
		emoji = "👴",
		text = "Your grandchildren want to spend more time with you!",
		question = "How do you bond with your grandchildren?",
		minAge = 55, maxAge = 95,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "senior",
		category = "family",
		tags = { "grandchildren", "family", "legacy" },
		
		choices = {
			{ text = "Spoil them rotten", effects = { Happiness = 10, Money = -200 }, setFlags = { spoiling_grandkids = true }, feedText = "Candy, presents, NO rules. That's grandparent privilege!" },
			{ text = "Teach them your skills/hobbies", effects = { Happiness = 8, Smarts = 2 }, setFlags = { teaching_grandkids = true }, feedText = "Fishing, cooking, gardening - passing down traditions." },
			{ text = "Share family stories", effects = { Happiness = 8, Smarts = 1 }, setFlags = { family_historian = true }, feedText = "They love hearing about 'the old days'." },
			{ text = "Be the babysitter", effects = { Happiness = 6, Health = -2, Money = -50 }, feedText = "Helping out with childcare. Tiring but worth it." },
			{ text = "Stay connected digitally", effects = { Happiness = 5, Smarts = 2 }, feedText = "Video calls, texting - technology bridges the distance." },
		},
	},
	{
		id = "senior_hobby_mastery",
		title = "Hobby Mastery",
		emoji = "🎨",
		text = "With time to dedicate, you're becoming an expert at your hobby!",
		question = "What hobby are you mastering?",
		minAge = 60, maxAge = 90,
		baseChance = 0.35,
		cooldown = 3,
		stage = STAGE,
		ageBand = "senior",
		category = "hobbies",
		tags = { "hobby", "mastery", "passion" },
		
		choices = {
			{ text = "Gardening - beautiful results", effects = { Happiness = 8, Health = 3 }, setFlags = { master_gardener = true }, feedText = "Your garden is the envy of the neighborhood!" },
			{ text = "Woodworking/crafts", effects = { Happiness = 7, Smarts = 2 }, setFlags = { craftsperson = true }, feedText = "Creating beautiful handmade pieces." },
			{ text = "Painting/art", effects = { Happiness = 9, Smarts = 2 }, setFlags = { senior_artist = true }, feedText = "Your art is getting good enough to sell!" },
			{ text = "Golf - finally breaking par", effects = { Happiness = 8, Health = 2, Money = -100 }, setFlags = { golf_master = true }, feedText = "Finally playing at the level you always wanted!" },
			{ text = "Writing memoirs", effects = { Happiness = 7, Smarts = 4 }, setFlags = { memoir_writer = true }, feedText = "Recording your life story. What a journey it's been!" },
		},
	},
	{
		id = "senior_financial_concerns",
		title = "Financial Concerns",
		emoji = "💰",
		text = "Retirement finances need attention.",
		question = "What's your financial situation?",
		minAge = 62, maxAge = 90,
		baseChance = 0.35,
		cooldown = 3,
		stage = STAGE,
		ageBand = "senior",
		category = "finance",
		tags = { "money", "retirement", "planning" },
		
		-- CRITICAL: Random financial situation
		choices = {
			{
				text = "Review your finances",
				effects = {},
				feedText = "Looking at the numbers...",
				onResolve = function(state)
					local money = state.Money or 0
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 6)
						state.Money = money + 500
						state:AddFeed("💰 Finances looking good! Even found extra savings!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("💰 On track. Not wealthy but comfortable.")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.financial_stress_senior = true
						state:AddFeed("💰 Money is tight. Need to cut expenses.")
					end
				end,
			},
		},
	},
	{
		id = "senior_community_involvement",
		title = "Community Involvement",
		emoji = "🏘️",
		text = "Your community needs active members.",
		question = "How involved are you in your community?",
		minAge = 60, maxAge = 90,
		baseChance = 0.3,
		cooldown = 4,
		stage = STAGE,
		ageBand = "senior",
		category = "social",
		tags = { "community", "social", "involvement" },
		
		choices = {
			{ text = "Join/lead community organizations", effects = { Happiness = 7, Smarts = 2 }, setFlags = { community_leader = true }, feedText = "HOA, rotary, church committee - making a difference locally." },
			{ text = "Neighborhood watch participant", effects = { Happiness = 4, Smarts = 1 }, setFlags = { watchful_neighbor = true }, feedText = "Keeping an eye out for everyone's safety." },
			{ text = "Run for local office", effects = {}, feedText = "Putting your name on the ballot...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.local_official = true
						state:AddFeed("🏘️ ELECTED! Councilperson! Time to make changes!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🏘️ Lost the election. Still proud you tried.")
					end
				end,
			},
			{ text = "Keep to yourself", effects = { Happiness = 2 }, setFlags = { private_senior = true }, feedText = "Prefer peace and quiet. Mind your own business." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- HEALTH CHALLENGES (Ages 60-100)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "senior_new_diagnosis",
		title = "New Diagnosis",
		emoji = "🏥",
		text = "The doctor has news about your health.",
		question = "What's the diagnosis?",
		minAge = 60, maxAge = 100,
		baseChance = 0.3,
		cooldown = 4,
		stage = STAGE,
		ageBand = "senior",
		category = "health",
		tags = { "health", "diagnosis", "medical" },
		
		-- CRITICAL: Random diagnosis - player doesn't choose what health issue
		choices = {
			{
				text = "Get the results",
				effects = {},
				feedText = "The doctor reviews your tests...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local age = state.Age or 70
					local roll = math.random()
					local goodChance = 0.30 + (health / 200) - (age / 300)
					if roll < goodChance then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Health", 2)
						state:AddFeed("🏥 All clear! Healthy for your age! Relief!")
					elseif roll < goodChance + 0.30 then
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Health", -3)
						state:AddFeed("🏥 Minor issue found. Manageable with medication.")
					elseif roll < goodChance + 0.50 then
						state:ModifyStat("Happiness", -6)
						state:ModifyStat("Health", -8)
						state.Flags = state.Flags or {}
						state.Flags.chronic_condition = true
						state:AddFeed("🏥 Chronic condition diagnosed. Lifestyle changes needed.")
					else
						state:ModifyStat("Happiness", -12)
						state:ModifyStat("Health", -15)
						state.Flags = state.Flags or {}
						state.Flags.serious_illness = true
						state:AddFeed("🏥 Serious diagnosis. Treatment options being discussed.")
					end
				end,
			},
		},
	},
	{
		id = "senior_fall_risk",
		title = "Fall Incident",
		emoji = "⚠️",
		text = "You had a fall. It's a wake-up call about mobility.",
		question = "How serious was the fall?",
		minAge = 65, maxAge = 100,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "senior",
		category = "health",
		tags = { "fall", "injury", "mobility" },
		
		-- CRITICAL: Random fall outcome
		choices = {
			{
				text = "Assess the damage",
				effects = {},
				feedText = "Checking for injuries...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", -2)
						state:ModifyStat("Health", -2)
						state:AddFeed("⚠️ Just bruises. Scared but okay. Being more careful now.")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -5)
						state:ModifyStat("Health", -8)
						state.Flags = state.Flags or {}
						state.Flags.mobility_concern = true
						state:AddFeed("⚠️ Sprained something. Need a cane for a while.")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", -8)
						state:ModifyStat("Health", -15)
						state.Money = (state.Money or 0) - 1000
						state.Flags = state.Flags or {}
						state.Flags.broken_bone_senior = true
						state:AddFeed("⚠️ Broken bone. Hospital and rehab. Serious setback.")
					else
						state:ModifyStat("Happiness", -12)
						state:ModifyStat("Health", -25)
						state.Flags = state.Flags or {}
						state.Flags.major_fall = true
						state:AddFeed("⚠️ Severe injury. Hip replacement needed. Long recovery.")
					end
				end,
			},
		},
	},
	{
		id = "senior_medication_management",
		title = "Medication Juggling",
		emoji = "💊",
		text = "Managing multiple medications is getting complicated.",
		question = "How do you handle all the medications?",
		minAge = 65, maxAge = 100,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "senior",
		category = "health",
		tags = { "medication", "health", "management" },
		
		choices = {
			{ text = "Use pill organizers and alarms", effects = { Health = 3, Smarts = 2 }, setFlags = { organized_meds = true }, feedText = "System in place. Never miss a dose." },
			{ text = "Sometimes forget doses", effects = { Health = -3, Happiness = -2 }, feedText = "Missed a few. Doctor says it's important to be consistent." },
			{ text = "Ask doctor to simplify regimen", effects = { Health = 2, Happiness = 3 }, feedText = "Fewer pills, same benefits. Much easier!" },
			{ text = "Rely on family to help", effects = { Health = 2, Happiness = 1 }, feedText = "Kids/spouse help keep track. Teamwork." },
		},
	},
	{
		id = "senior_exercise_routine",
		title = "Staying Active",
		emoji = "🚶",
		text = "Exercise is important at this age.",
		question = "What's your fitness routine?",
		minAge = 60, maxAge = 95,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "senior",
		category = "health",
		tags = { "exercise", "fitness", "health" },
		
		choices = {
			{
				text = "Daily walks",
				effects = {},
				feedText = "Walking every day...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.active_senior = true
						state:AddFeed("🚶 Consistent walks paying off! Feeling great!")
					else
						state:ModifyStat("Health", 2)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🚶 Some walks. Better than nothing!")
					end
				end,
			},
			{ text = "Swimming - easy on joints", effects = { Health = 6, Happiness = 5 }, setFlags = { swimmer = true }, feedText = "Perfect exercise! Low impact, full body." },
			{ text = "Senior fitness classes", effects = { Health = 5, Happiness = 6 }, setFlags = { group_fitness = true }, feedText = "Fun with others your age! Great motivation!" },
			{ text = "Too tired/hurt to exercise", effects = { Health = -3, Happiness = -2 }, setFlags = { sedentary_senior = true }, feedText = "Body doesn't cooperate. Frustrating." },
		},
	},
	{
		id = "senior_cognitive_challenge",
		title = "Memory Challenge",
		emoji = "🧠",
		text = "You've been forgetting things more often lately.",
		question = "How do you address memory concerns?",
		minAge = 65, maxAge = 100,
		baseChance = 0.3,
		cooldown = 4,
		stage = STAGE,
		ageBand = "senior",
		category = "health",
		tags = { "memory", "cognitive", "health" },
		
		-- CRITICAL: Random cognitive outcome
		choices = {
			{
				text = "See a doctor about it",
				effects = {},
				feedText = "Getting evaluated...",
				onResolve = function(state)
					local age = state.Age or 75
					local roll = math.random()
					local normalChance = 0.50 - (age / 250)
					if roll < normalChance then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🧠 Normal age-related forgetfulness. Nothing serious!")
					elseif roll < normalChance + 0.30 then
						state:ModifyStat("Happiness", 2)
						state:ModifyStat("Smarts", -2)
						state:AddFeed("🧠 Mild cognitive impairment. Brain exercises recommended.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.cognitive_decline = true
						state:AddFeed("🧠 More serious diagnosis. Early intervention starting.")
					end
				end,
			},
			{
				text = "Do brain exercises and puzzles",
				effects = { Smarts = 3, Happiness = 3 },
				setFlags = { brain_training = true },
				feedText = "Crosswords, sudoku, learning new things. Keeping sharp!",
			},
			{
				text = "Ignore it - just getting old",
				effects = { Happiness = -2 },
				feedText = "Everyone forgets things. Not worried. (Should be though.)",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FAMILY & RELATIONSHIPS (Ages 60-100)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "senior_adult_children_relationship",
		title = "Adult Children Dynamics",
		emoji = "👨‍👩‍👧‍👦",
		text = "Your relationship with your adult children is evolving.",
		question = "How are things with your adult children?",
		minAge = 60, maxAge = 100,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "senior",
		category = "family",
		tags = { "children", "family", "relationships" },
		
		choices = {
			{ text = "Closer than ever", effects = { Happiness = 10 }, setFlags = { close_family = true }, feedText = "Regular calls, visits. Mutual respect and love." },
			{ text = "Role reversal - they parent you now", effects = { Happiness = -3, Health = 1 }, setFlags = { role_reversal = true }, feedText = "They worry about YOU now. Strange but touching." },
			{ text = "Conflict over your independence", effects = { Happiness = -6 }, setFlags = { independence_conflict = true }, feedText = "They want to help. You want to do it yourself. Friction." },
			{ text = "Estranged - don't talk much", effects = { Happiness = -8 }, setFlags = { estranged_children = true }, feedText = "Painful distance. Regrets about what went wrong." },
			{ text = "Providing financial help to them", effects = { Happiness = 2, Money = -500 }, setFlags = { supporting_adult_kids = true }, feedText = "Kids need help. Generations supporting each other." },
		},
	},
	{
		id = "senior_widow_widower",
		title = "Losing Partner",
		emoji = "💔",
		text = "Your life partner has passed away.",
		question = "How do you cope with the loss?",
		minAge = 60, maxAge = 100,
		oneTime = true,
		baseChance = 0.15,
		requiresPartner = true,
		stage = STAGE,
		ageBand = "senior",
		category = "loss",
		tags = { "death", "spouse", "grief" },
		
		choices = {
			{ text = "Devastating grief", effects = { Happiness = -20, Health = -10 }, setFlags = { widowed = true }, feedText = "The other half of you is gone. Nothing feels right." },
			{ text = "Lean on family for support", effects = { Happiness = -15, Health = -5 }, setFlags = { family_support_grief = true }, feedText = "Children and grandchildren help you through. Together." },
			{ text = "Join grief support group", effects = { Happiness = -12, Smarts = 2 }, setFlags = { grief_support = true }, feedText = "Others understand. You're not alone in this pain." },
			{ text = "Honor their memory by living fully", effects = { Happiness = -10, Health = -3 }, setFlags = { honoring_memory = true }, feedText = "They'd want you to keep going. Living for both of you." },
		},
	},
	{
		id = "senior_late_romance",
		title = "Late-Life Romance",
		emoji = "❤️",
		text = "Romance can happen at any age!",
		question = "What's happening in your love life?",
		minAge = 60, maxAge = 90,
		baseChance = 0.15,
		cooldown = 5,
		requiresSingle = true,
		stage = STAGE,
		ageBand = "senior",
		category = "romance",
		tags = { "love", "dating", "senior" },
		
		-- CRITICAL: Random romance outcome
		choices = {
			{
				text = "Start dating again",
				effects = {},
				feedText = "Putting yourself out there...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Health", 3)
						state.Flags = state.Flags or {}
						state.Flags.senior_romance = true
						state:AddFeed("❤️ Found someone special! Never too late for love!")
						state:AddRelationship("Partner", "romantic", 0.75)
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("❤️ Some nice dates. Still looking for the right one.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("❤️ Dating scene is different. Not easy at this age.")
					end
				end,
			},
			{
				text = "Content being single",
				effects = { Happiness = 5 },
				setFlags = { happy_single_senior = true },
				feedText = "Don't need a partner to be happy. Complete on your own.",
			},
			{
				text = "Family disapproves of dating",
				effects = { Happiness = -4 },
				setFlags = { family_disapproves_dating = true },
				feedText = "Kids think it's 'too soon' or 'inappropriate'. Frustrating.",
			},
		},
	},
	{
		id = "senior_family_reunion",
		title = "Family Reunion",
		emoji = "👨‍👩‍👧‍👦",
		text = "The whole extended family is gathering!",
		question = "How does the family reunion go?",
		minAge = 60, maxAge = 100,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "senior",
		category = "family",
		tags = { "family", "reunion", "gathering" },
		
		-- CRITICAL: Random reunion outcome
		choices = {
			{
				text = "Host the gathering",
				effects = { Money = -300 },
				feedText = "Everyone coming to your place...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.family_matriarch = true
						state:AddFeed("👨‍👩‍👧‍👦 Wonderful gathering! You're the heart of this family!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Health", -2)
						state:AddFeed("👨‍👩‍👧‍👦 Great time but exhausting to host!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("👨‍👩‍👧‍👦 Family drama surfaced. Some arguments. Stressful.")
					end
				end,
			},
			{
				text = "Attend as guest of honor",
				effects = { Happiness = 10 },
				feedText = "Celebrated as the elder! Stories and memories shared.",
			},
			{
				text = "Too tired - skip this one",
				effects = { Happiness = -3 },
				feedText = "Body said no. Wish you could've gone.",
			},
		},
	},
	{
		id = "senior_inheritance_planning",
		title = "Inheritance Planning",
		emoji = "📜",
		text = "Time to think about your estate and inheritance.",
		question = "How do you approach estate planning?",
		minAge = 65, maxAge = 100,
		oneTime = true,
		stage = STAGE,
		ageBand = "senior",
		category = "finance",
		tags = { "inheritance", "estate", "planning" },
		
		choices = {
			{ text = "Fair split between all children", effects = { Happiness = 5, Smarts = 2 }, setFlags = { fair_inheritance = true }, feedText = "Equal distribution. No favoritism. They can sort it out." },
			{ text = "Based on need/circumstances", effects = { Happiness = 3, Smarts = 2 }, setFlags = { need_based_inheritance = true }, feedText = "The one struggling gets more. Makes sense." },
			{ text = "Donate most to charity", effects = { Happiness = 8, Smarts = 3 }, setFlags = { charitable_estate = true }, feedText = "Leave a legacy bigger than family. Help the world." },
			{ text = "Complicated family dynamics", effects = { Happiness = -5 }, setFlags = { inheritance_drama = true }, feedText = "This is going to cause fights. No good solution." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- REFLECTION & LEGACY (Ages 70-100)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "senior_life_reflection",
		title = "Life Reflection",
		emoji = "🪞",
		text = "Looking back on your life and all you've experienced.",
		question = "How do you feel about your life?",
		minAge = 70, maxAge = 100,
		baseChance = 0.3,
		cooldown = 4,
		stage = STAGE,
		ageBand = "senior",
		category = "reflection",
		tags = { "reflection", "life", "meaning" },
		
		choices = {
			{ text = "Satisfied and at peace", effects = { Happiness = 15, Health = 3 }, setFlags = { life_satisfaction = true }, feedText = "It was a good life. Mistakes and all. No regrets." },
			{ text = "Some regrets but accepting", effects = { Happiness = 5, Smarts = 2 }, feedText = "Things you'd do differently. But you did your best." },
			{ text = "Wishing you'd done more", effects = { Happiness = -5 }, setFlags = { regretful = true }, feedText = "So many things left undone. Dreams unfulfilled." },
			{ text = "Proud of what you've built", effects = { Happiness = 12 }, setFlags = { proud_legacy = true }, feedText = "Family, career, impact. You've left your mark." },
		},
	},
	{
		id = "senior_wisdom_sharing",
		title = "Sharing Wisdom",
		emoji = "📖",
		text = "Young people are asking for your life advice.",
		question = "What wisdom do you share?",
		minAge = 70, maxAge = 100,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "senior",
		category = "legacy",
		tags = { "wisdom", "advice", "legacy" },
		
		choices = {
			{ text = "Relationships matter most", effects = { Happiness = 8 }, feedText = "'At the end, it's the people you loved that matter.'" },
			{ text = "Don't wait to do what you want", effects = { Happiness = 7, Smarts = 1 }, feedText = "'Time goes faster than you think. Do it now.'" },
			{ text = "Hard work pays off", effects = { Happiness = 6, Smarts = 1 }, feedText = "'Nothing comes easy. But effort is always rewarded.'" },
			{ text = "Let go of grudges", effects = { Happiness = 9 }, feedText = "'Forgiveness isn't for them, it's for you.'" },
			{ text = "Health is everything", effects = { Happiness = 6, Health = 2 }, feedText = "'Take care of your body. You only get one.'" },
		},
	},
	{
		id = "senior_bucket_list_complete",
		title = "Bucket List",
		emoji = "✅",
		text = "Working through things you always wanted to do!",
		question = "What's on your bucket list?",
		minAge = 65, maxAge = 95,
		baseChance = 0.3,
		cooldown = 4,
		stage = STAGE,
		ageBand = "senior",
		category = "experiences",
		tags = { "bucket_list", "goals", "experiences" },
		
		eligibility = function(state)
			local money = state.Money or 0
			local health = (state.Stats and state.Stats.Health) or 50
			if money < 500 and health < 40 then
				return false, "Need money or health to tackle bucket list"
			end
			return true
		end,
		
		-- CRITICAL: Random bucket list outcome
		choices = {
			{
				text = "Try something adventurous",
				effects = { Money = -500 },
				feedText = "Going for an adventure...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.bucket_list_adventure = true
						state:AddFeed("✅ DID IT! Skydiving/traveling/whatever - INCREDIBLE!")
					else
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", -3)
						state:AddFeed("✅ Tried but body had limits. Still proud you attempted!")
					end
				end,
			},
			{
				text = "Reconnect with someone from the past",
				effects = {},
				feedText = "Reaching out after all these years...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("✅ Reconnected! Wonderful reunion. Closure or new friendship.")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("✅ They've changed. You've changed. Bittersweet.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("✅ They passed away. Too late. Lesson learned.")
					end
				end,
			},
			{
				text = "Learn something you never did",
				effects = { Smarts = 5, Happiness = 8, Money = -200 },
				setFlags = { lifelong_learner = true },
				feedText = "New language, instrument, skill. Never too old to learn!",
			},
			{
				text = "Write letters to loved ones",
				effects = { Happiness = 8 },
				setFlags = { wrote_letters = true },
				feedText = "Words they'll treasure forever. Your love on paper.",
			},
		},
	},
	{
		id = "senior_technology_challenge",
		title = "Technology Frustration",
		emoji = "📱",
		text = "Technology keeps changing and it's hard to keep up!",
		question = "How do you handle modern technology?",
		minAge = 65, maxAge = 100,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "senior",
		category = "challenges",
		tags = { "technology", "learning", "frustration" },
		
		choices = {
			{
				text = "Ask grandkids for help",
				effects = {},
				feedText = "Learning from the experts...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("📱 They taught you! Video calling, texting - you got this!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📱 They went too fast. Still confused. Try again later.")
					end
				end,
			},
			{
				text = "Take a senior tech class",
				effects = { Money = -50, Smarts = 4, Happiness = 4 },
				setFlags = { tech_savvy_senior = true },
				feedText = "Class at your pace. Actually understanding it now!",
			},
			{
				text = "Give up - prefer the old ways",
				effects = { Happiness = 2 },
				setFlags = { tech_resistant = true },
				feedText = "Phone calls and letters worked fine for decades.",
			},
			{
				text = "Embrace it and figure it out",
				effects = { Smarts = 5, Happiness = 3 },
				setFlags = { embraced_tech = true },
				feedText = "YouTube tutorials! Learning on your own. Proud!",
			},
		},
	},
	{
		id = "senior_daily_routine",
		title = "Daily Routine",
		emoji = "☀️",
		text = "Your daily routine defines your retirement life.",
		question = "What does a typical day look like?",
		minAge = 62, maxAge = 100,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "senior",
		category = "lifestyle",
		tags = { "routine", "retirement", "daily" },
		
		choices = {
			{ text = "Active and full", effects = { Happiness = 6, Health = 4 }, setFlags = { active_routine = true }, feedText = "Morning walk, hobbies, social visits. Never bored!" },
			{ text = "Peaceful and slow", effects = { Happiness = 5, Health = 2 }, setFlags = { peaceful_routine = true }, feedText = "Coffee, reading, gardening. Quiet contentment." },
			{ text = "Lonely and repetitive", effects = { Happiness = -5, Health = -2 }, setFlags = { lonely_routine = true }, feedText = "TV, same meals, no visitors. Isolated." },
			{ text = "Helping family full-time", effects = { Happiness = 4, Health = -1 }, setFlags = { family_helper = true }, feedText = "Babysitting, errands, always busy helping kids." },
		},
	},
	{
		id = "senior_scam_attempt",
		title = "Scam Attempt",
		emoji = "🚨",
		text = "Someone is trying to scam you!",
		question = "How do you handle the scam attempt?",
		minAge = 60, maxAge = 100,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "senior",
		category = "challenges",
		tags = { "scam", "fraud", "safety" },
		
		-- CRITICAL: Random scam outcome
		choices = {
			{
				text = "Recognize it and hang up/ignore",
				effects = { Smarts = 3, Happiness = 3 },
				setFlags = { scam_savvy = true },
				feedText = "🚨 Nice try, scammer. You're not falling for that!",
			},
			{
				text = "Not sure - almost fell for it",
				effects = {},
				feedText = "Something felt off...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local safeChance = 0.40 + (smarts / 150)
					if roll < safeChance then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🚨 Almost got you! Caught it just in time. Close call.")
					else
						state.Money = (state.Money or 0) - 500
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.scam_victim = true
						state:AddFeed("🚨 They got you. Lost money. Feeling foolish and angry.")
					end
				end,
			},
			{
				text = "Report it to authorities",
				effects = { Smarts = 2, Happiness = 2 },
				feedText = "Reported to protect others too. Good citizen.",
			},
		},
	},
	{
		id = "senior_end_of_life_planning",
		title = "End of Life Planning",
		emoji = "📝",
		text = "Having important conversations about end of life wishes.",
		question = "How do you approach these conversations?",
		minAge = 70, maxAge = 100,
		oneTime = true,
		stage = STAGE,
		ageBand = "senior",
		category = "planning",
		tags = { "end_of_life", "planning", "wishes" },
		
		choices = {
			{ text = "Document everything clearly", effects = { Happiness = 5, Smarts = 3 }, setFlags = { end_of_life_planned = true }, feedText = "Living will, DNR, burial wishes. All documented. Peace of mind." },
			{ text = "Discuss with family", effects = { Happiness = 3, Smarts = 2 }, setFlags = { family_discussions = true }, feedText = "Hard conversations but necessary. They know your wishes." },
			{ text = "Avoid the topic", effects = { Happiness = -3 }, setFlags = { avoiding_reality = true }, feedText = "Too morbid to think about. But leaving confusion behind." },
			{ text = "Already at peace with mortality", effects = { Happiness = 8 }, setFlags = { accepted_mortality = true }, feedText = "Death is natural. You've lived a full life. Ready when it comes." },
		},
	},
	{
		id = "senior_milestone_birthday",
		title = "Milestone Birthday",
		emoji = "🎂",
		text = "It's a big birthday! Another decade celebration!",
		question = "How do you celebrate?",
		minAge = 70, maxAge = 100,
		oneTime = false,
		baseChance = 0.4,
		cooldown = 10,
		stage = STAGE,
		ageBand = "senior",
		category = "celebration",
		tags = { "birthday", "milestone", "celebration" },
		
		choices = {
			{ text = "Big party with everyone", effects = { Happiness = 15, Money = -500 }, setFlags = { milestone_celebration = true }, feedText = "What a celebration! Everyone you love in one place!" },
			{ text = "Quiet dinner with close family", effects = { Happiness = 10 }, feedText = "Intimate and meaningful. Perfect." },
			{ text = "Reflection on how far you've come", effects = { Happiness = 8, Smarts = 2 }, feedText = "Made it this far. Still here. Grateful." },
			{ text = "Feel old - not celebrating", effects = { Happiness = -4 }, feedText = "Another year older. Nothing to celebrate." },
		},
	},
	{
		id = "senior_final_goodbye",
		title = "The Final Chapter",
		emoji = "🕊️",
		text = "Your health is declining. The end is near.",
		question = "How do you spend your final days?",
		minAge = 80, maxAge = 120,
		oneTime = true,
		baseChance = 0.15,
		stage = STAGE,
		ageBand = "senior",
		category = "end_of_life",
		tags = { "death", "final", "goodbye" },
		
		eligibility = function(state)
			local health = (state.Stats and state.Stats.Health) or 50
			if health > 30 then
				return false, "Health is still good"
			end
			return true
		end,
		
		choices = {
			{ text = "Surrounded by loved ones", effects = { Happiness = 15 }, setFlags = { peaceful_end = true }, feedText = "🕊️ Family gathered. Love spoken. Peaceful end." },
			{ text = "Make peace with old conflicts", effects = { Happiness = 10 }, setFlags = { made_peace = true }, feedText = "🕊️ Apologies and forgiveness. No grudges left behind." },
			{ text = "Share final words of wisdom", effects = { Happiness = 10, Smarts = 5 }, setFlags = { final_wisdom = true }, feedText = "🕊️ Your legacy in words. They'll remember forever." },
			{ text = "At peace with a life well lived", effects = { Happiness = 20 }, setFlags = { life_complete = true }, feedText = "🕊️ No regrets. Full life. Ready for what comes next." },
		},
	},
}

return SeniorExpanded
