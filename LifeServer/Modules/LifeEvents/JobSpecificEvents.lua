--[[
    Job-Specific Events
    Events tailored to specific job categories from OccupationScreen
    All events use randomized outcomes - NO god mode
    
    Categories covered:
    - entry (teen jobs)
    - service (hospitality, food service)
    - trades (construction, electrician, plumber, etc)
    - office (admin, HR, management)
    - tech (IT, developers, data science)
    - medical (healthcare professionals)
    - law (legal profession)
    - finance (banking, accounting, investing)
    - creative (art, media, entertainment)
    - government (public sector)
    - education (teachers, professors)
    - science (researchers, labs)
    - sports (athletes, coaching)
    - military (armed forces)
]]

local JobSpecificEvents = {}

local STAGE = "adult"

-- Helper to check job category
local function isInJobCategory(state, categories)
	if not state.CurrentJob then return false end
	local jobCat = (state.CurrentJob.category or ""):lower()
	for _, cat in ipairs(categories) do
		if jobCat == cat:lower() then
			return true
		end
	end
	return false
end

JobSpecificEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- ENTRY LEVEL / SERVICE JOBS (Teen/Entry workers)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "entry_rude_customer",
		title = "Rude Customer",
		emoji = "😤",
		text = "A customer is being incredibly rude and demanding to see the manager.",
		question = "How do you handle this angry customer?",
		minAge = 14, maxAge = 30,
		baseChance = 0.5,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"entry", "service", "retail"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_service",
		tags = { "customer_service", "conflict", "work" },
		
		choices = {
			{
				text = "Stay calm and de-escalate",
				effects = {},
				feedText = "You take a deep breath...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 3)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("😤 Handled it professionally! Manager impressed.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("😤 Customer still complained. Not your fault.")
					end
				end,
			},
			{
				text = "Get a manager immediately",
				effects = { Happiness = 1 },
				feedText = "Not your problem anymore. That's what managers are for.",
			},
			{
				text = "Snap back at them",
				effects = {},
				feedText = "You've had enough...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("😤 Felt great to stand up! Customer backed down.")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("😤 Got written up. Worth it? Maybe.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.fired_entry = true
						state:AddFeed("😤 FIRED. Shouldn't have said that.")
					end
				end,
			},
		},
	},
	{
		id = "entry_shift_cover",
		title = "Cover a Shift",
		emoji = "📞",
		text = "A coworker is begging you to cover their shift.",
		question = "Do you cover for them?",
		minAge = 14, maxAge = 30,
		baseChance = 0.5,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"entry", "service", "retail"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_service",
		tags = { "work", "schedule", "favor" },
		
		choices = {
			{
				text = "Cover the shift",
				effects = { Money = 80, Happiness = -1, Health = -1 },
				setFlags = { reliable_worker = true },
				feedText = "Extra hours, extra money. You're exhausted though.",
			},
			{
				text = "Say no - you have plans",
				effects = { Happiness = 2 },
				feedText = "Your time matters too. No guilt.",
			},
			{
				text = "Only if they owe you one",
				effects = { Money = 80, Smarts = 1 },
				setFlags = { favor_owed = true },
				feedText = "Business transaction. They'll cover for you later.",
			},
		},
	},
	{
		id = "entry_tip_windfall",
		title = "Big Tip!",
		emoji = "💵",
		text = "A customer left you an unusually large tip!",
		question = "How big was it?",
		minAge = 16, maxAge = 35,
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "service", "entry" },
		eligibility = function(state)
			return isInJobCategory(state, {"service", "entry"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_service",
		tags = { "money", "tips", "luck" },
		
		-- CRITICAL: Random tip amount
		choices = {
			{
				text = "Accept the generous tip",
				effects = {},
				feedText = "You check the tip amount...",
				onResolve = function(state)
					local roll = math.random()
					local tip
					if roll < 0.50 then
						tip = math.random(20, 50)
						state:AddFeed(string.format("💵 Nice! $%d tip! Made your day!", tip))
					elseif roll < 0.80 then
						tip = math.random(50, 100)
						state:AddFeed(string.format("💵 WOW! $%d tip! Amazing customer!", tip))
					else
						tip = math.random(100, 300)
						state.Flags = state.Flags or {}
						state.Flags.lucky_tip = true
						state:AddFeed(string.format("💵 INCREDIBLE! $%d tip! Life-changing generosity!", tip))
					end
					state.Money = (state.Money or 0) + tip
					state:ModifyStat("Happiness", 5)
				end,
			},
		},
	},
	{
		id = "service_busy_rush",
		title = "Rush Hour Chaos",
		emoji = "🌪️",
		text = "The lunch/dinner rush is INSANE today!",
		question = "How do you handle the pressure?",
		minAge = 16, maxAge = 40,
		baseChance = 0.5,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"service", "entry"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_service",
		tags = { "stress", "busy", "work" },
		
		choices = {
			{
				text = "Thrive under pressure",
				effects = {},
				feedText = "Orders flying, you're in the zone...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state.Money = (state.Money or 0) + 50
						state:AddFeed("🌪️ Crushed it! Manager noticed your efficiency!")
					else
						state:ModifyStat("Happiness", 1)
						state:ModifyStat("Health", -1)
						state:AddFeed("🌪️ Survived. Barely. Need a break.")
					end
				end,
			},
			{
				text = "Get overwhelmed",
				effects = { Happiness = -5, Health = -2 },
				feedText = "Too much at once. Mistakes happen. Stressful.",
			},
			{
				text = "Ask coworkers for help",
				effects = { Happiness = 2 },
				setFlags = { team_player = true },
				feedText = "Teamwork! Got through it together.",
			},
		},
	},
	{
		id = "service_late_night_shift",
		title = "Late Night Shift",
		emoji = "🌙",
		text = "Working the late night/graveyard shift.",
		question = "How's the night shift treating you?",
		minAge = 18, maxAge = 40,
		baseChance = 0.55,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"service", "entry"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_service",
		tags = { "night", "shift", "work" },
		
		choices = {
			{ text = "Quiet night - easy money", effects = { Money = 60, Happiness = 2 }, feedText = "Slow night. Got paid to basically chill." },
			{ text = "Weird customers at 3am", effects = { Happiness = -2, Smarts = 1 }, feedText = "The things you see at night... interesting characters." },
			{ text = "Tired and making mistakes", effects = { Happiness = -3, Health = -2 }, feedText = "Sleep schedule is destroyed. Hard to function." },
			{ text = "Creepy incident", effects = { Happiness = -5 }, setFlags = { night_shift_scare = true }, feedText = "Something unsettling happened. Considering day shifts only." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- TRADES JOBS (Construction, Electrician, Plumber, etc)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "trades_workplace_injury",
		title = "Workplace Injury Risk",
		emoji = "⚠️",
		text = "The work site has some safety concerns today.",
		question = "How do you handle the safety situation?",
		minAge = 18, maxAge = 60,
		baseChance = 0.555,
		cooldown = 3,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "trades", "construction" },
		eligibility = function(state)
			return isInJobCategory(state, {"trades", "construction"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_trades",
		tags = { "safety", "injury", "work" },
		
		-- CRITICAL: Random injury outcome
		choices = {
			{
				text = "Follow all safety protocols",
				effects = {},
				feedText = "Being careful on the job...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.80 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("⚠️ Another safe day. Protocol works.")
					else
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("⚠️ Minor injury despite precautions. Occupational hazard.")
					end
				end,
			},
			{
				text = "Cut corners to finish faster",
				effects = {},
				feedText = "Rushing to meet deadline...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state.Money = (state.Money or 0) + 100
						state:ModifyStat("Happiness", 2)
						state:AddFeed("⚠️ Got done early. Bonus for speed!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", -2)
						state:AddFeed("⚠️ Close call but nothing happened. Lucky.")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.work_injury = true
						state:AddFeed("⚠️ INJURED! Hospital visit. Weeks off work.")
					end
				end,
			},
			{
				text = "Report safety violations",
				effects = { Smarts = 2 },
				setFlags = { safety_reporter = true },
				feedText = "Did the right thing. Some coworkers annoyed but safety first.",
			},
		},
	},
	{
		id = "trades_big_project",
		title = "Big Project",
		emoji = "🏗️",
		text = "There's a major project that could be a big opportunity.",
		question = "How do you approach the big project?",
		minAge = 20, maxAge = 55,
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "trades", "construction" },
		eligibility = function(state)
			return isInJobCategory(state, {"trades", "construction"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_trades",
		tags = { "project", "opportunity", "work" },
		
		-- CRITICAL: Random project outcome
		choices = {
			{
				text = "Go above and beyond",
				effects = {},
				feedText = "Putting in extra effort...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					local successChance = 0.40 + (smarts / 200) + (health / 400)
					if roll < successChance then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.recognized_tradesperson = true
						state:AddFeed("🏗️ Project success! Big bonus! Reputation boosted!")
					else
						state:ModifyStat("Happiness", 2)
						state:ModifyStat("Health", -2)
						state:AddFeed("🏗️ Good work but exhausted. Adequate recognition.")
					end
				end,
			},
			{
				text = "Do standard quality work",
				effects = { Money = 100, Happiness = 2 },
				feedText = "Solid work. Job done. Moving on.",
			},
			{
				text = "Find a better opportunity",
				effects = {},
				feedText = "Looking for something else...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state.Money = (state.Money or 0) + 300
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🏗️ Found better paying gig! Smart move!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🏗️ Nothing better available. Stuck with current work.")
					end
				end,
			},
		},
	},
	{
		id = "trades_apprentice_moment",
		title = "Teaching Moment",
		emoji = "👷",
		text = "A new apprentice is shadowing you and making mistakes.",
		question = "How do you handle the apprentice?",
		minAge = 25, maxAge = 60,
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "trades", "construction" },
		eligibility = function(state)
			return isInJobCategory(state, {"trades", "construction"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_trades",
		tags = { "teaching", "apprentice", "work" },
		
		choices = {
			{ text = "Patiently teach them", effects = { Happiness = 3, Smarts = 2 }, setFlags = { good_mentor = true }, feedText = "Passing on knowledge. They're improving!" },
			{ text = "Let them learn from mistakes", effects = { Happiness = 1, Smarts = 1 }, feedText = "Best teacher is experience. They'll figure it out." },
			{ text = "Get frustrated with them", effects = { Happiness = -3 }, feedText = "Why can't they get this?! Patience wearing thin." },
			{ text = "Request they work with someone else", effects = { Happiness = 2 }, feedText = "Not everyone's cut out for teaching." },
		},
	},
	{
		id = "trades_weather_challenge",
		title = "Weather Problems",
		emoji = "🌧️",
		text = "Bad weather is affecting work conditions.",
		question = "How does weather impact your work?",
		minAge = 18, maxAge = 60,
		baseChance = 0.4,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"trades", "construction"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_trades",
		tags = { "weather", "outdoor", "work" },
		
		choices = {
			{ text = "Work through it - need the hours", effects = { Money = 100, Health = -3, Happiness = -2 }, feedText = "Miserable but money is money. Power through." },
			{ text = "Call it a day - safety first", effects = { Money = -50, Health = 1, Happiness = 1 }, feedText = "Lost wages but better than injury or illness." },
			{ text = "Find indoor tasks instead", effects = { Money = 50, Smarts = 1 }, feedText = "Productive regardless. Found other work to do." },
		},
	},
	{
		id = "trades_certification_opportunity",
		title = "Certification Opportunity",
		emoji = "📜",
		text = "There's a chance to get an advanced certification.",
		question = "Do you pursue the certification?",
		minAge = 20, maxAge = 50,
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"trades", "construction"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_trades",
		tags = { "certification", "career", "advancement" },
		
		-- CRITICAL: Random certification outcome
		choices = {
			{
				text = "Study and take the exam",
				effects = { Money = -200 },
				feedText = "Hitting the books and taking the test...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.40 + (smarts / 150)
					if roll < successChance then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 8)
						state.Money = (state.Money or 0) + 400
						state.Flags = state.Flags or {}
						state.Flags.certified_tradesperson = true
						state:AddFeed("📜 PASSED! New certification! Higher pay unlocked!")
					else
						state:ModifyStat("Happiness", -4)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("📜 Failed the exam. Can try again later.")
					end
				end,
			},
			{
				text = "Not worth the time and money",
				effects = { Happiness = 1 },
				feedText = "Maybe later. Content with current skills.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- TECH JOBS (IT, Developers, Data Science)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "tech_production_bug",
		title = "Production Bug!",
		emoji = "🐛",
		text = "There's a critical bug in production and everyone's panicking!",
		question = "How do you handle the production crisis?",
		minAge = 20, maxAge = 55,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "tech", "technology" },
		eligibility = function(state)
			return isInJobCategory(state, {"tech", "technology"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_tech",
		tags = { "bug", "crisis", "tech" },
		
		-- CRITICAL: Random bug fix outcome
		choices = {
			{
				text = "Stay calm and debug",
				effects = {},
				feedText = "Diving into the code...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.35 + (smarts / 150)
					if roll < successChance then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 3)
						state.Money = (state.Money or 0) + 200
						state.Flags = state.Flags or {}
						state.Flags.bug_hero = true
						state:AddFeed("🐛 FOUND IT! Fixed the bug! You're a hero!")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Happiness", 2)
						state:ModifyStat("Smarts", 1)
						state:AddFeed("🐛 Team effort fixed it. You helped.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🐛 Couldn't find it. Someone else did. Frustrating.")
					end
				end,
			},
			{
				text = "It was YOUR code that broke",
				effects = {},
				feedText = "Oh no... this is your bug...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🐛 Fixed your own mess. Embarrassing but handled.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.caused_outage = true
						state:AddFeed("🐛 Major outage traced back to you. Career setback.")
					end
				end,
			},
			{
				text = "Escalate immediately",
				effects = { Happiness = 1 },
				feedText = "Not your job to fix. Seniors are on it.",
			},
		},
	},
	{
		id = "tech_imposter_syndrome",
		title = "Imposter Syndrome",
		emoji = "🎭",
		text = "You feel like you don't belong. Everyone seems smarter.",
		question = "How do you deal with imposter syndrome?",
		minAge = 20, maxAge = 45,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "tech", "technology" },
		eligibility = function(state)
			return isInJobCategory(state, {"tech", "technology"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_tech",
		tags = { "imposter", "mental_health", "tech" },
		
		choices = {
			{ text = "Push through - prove yourself", effects = { Happiness = -2, Smarts = 3 }, setFlags = { overcoming_imposter = true }, feedText = "Everyone feels this way. Keep learning, keep growing." },
			{ text = "Talk to others - they feel the same", effects = { Happiness = 4, Smarts = 1 }, feedText = "Not alone. Mentors admit they still learn too." },
			{ text = "Let it hold you back", effects = { Happiness = -5, Smarts = -1 }, setFlags = { imposter_paralysis = true }, feedText = "Afraid to speak up, afraid to try. Stuck." },
			{ text = "Use it as motivation", effects = { Happiness = 2, Smarts = 4 }, setFlags = { imposter_motivation = true }, feedText = "Study harder, learn more. Turn fear into fuel." },
		},
	},
	{
		-- CRITICAL FIX: Renamed from "tech_side_project_success" to avoid duplicate ID conflict
		-- Career.lua has a more detailed version
		id = "tech_side_project_takeoff",
		title = "Side Project",
		emoji = "💻",
		text = "Your side project is getting attention!",
		question = "What happens with your side project?",
		minAge = 20, maxAge = 50,
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"tech", "technology"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_tech",
		tags = { "project", "startup", "tech" },
		
		-- CRITICAL: Random side project outcome
		choices = {
			{
				text = "Try to monetize it",
				effects = {},
				feedText = "Launching publicly...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.15 then
						state.Money = (state.Money or 0) + 5000
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.side_project_success = true
						state:AddFeed("💻 VIRAL! Making real money! Startup dreams!")
					elseif roll < 0.40 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 6)
						state:AddFeed("💻 Some traction! Making a little side income!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("💻 Flopped. No interest. Back to the drawing board.")
					end
				end,
			},
			{
				text = "Add it to your portfolio",
				effects = { Smarts = 3, Happiness = 4 },
				setFlags = { impressive_portfolio = true },
				feedText = "Great resume material even if it doesn't make money.",
			},
			{
				text = "Abandon it - lost interest",
				effects = { Happiness = -1 },
				feedText = "Yet another unfinished project. Developer tradition.",
			},
		},
	},
	{
		id = "tech_job_market_hot",
		title = "Hot Job Market",
		emoji = "📧",
		text = "Recruiters are sliding into your DMs constantly.",
		question = "How do you respond to recruiters?",
		minAge = 22, maxAge = 50,
		baseChance = 0.555,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"tech", "technology"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_tech",
		tags = { "recruiters", "job_market", "tech" },
		
		-- CRITICAL: Random recruiter outcome
		choices = {
			{
				text = "Explore opportunities",
				effects = {},
				feedText = "You respond to some messages...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.30 then
						state.Money = (state.Money or 0) + 1000
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.job_hopped = true
						state:AddFeed("📧 Got a better offer! New job with 30% raise!")
					elseif roll < 0.60 then
						state:ModifyStat("Happiness", 3)
						state.Flags = state.Flags or {}
						state.Flags.counter_offer = true
						state:AddFeed("📧 Leveraged offers for a counter. Got a raise to stay!")
					else
						state:ModifyStat("Happiness", 1)
						state:AddFeed("📧 Nothing better than what you have. Good to know your worth though.")
					end
				end,
			},
			{
				text = "Ignore them all",
				effects = { Happiness = 1 },
				feedText = "Happy where you are. Inbox stays unread.",
			},
			{
				text = "Mark as spam",
				effects = { Happiness = 2 },
				feedText = "So. Many. Messages. Peace restored.",
			},
		},
	},
	{
		id = "tech_new_framework",
		title = "New Technology",
		emoji = "📚",
		text = "A hot new technology/framework everyone's talking about.",
		question = "Do you learn the new tech?",
		minAge = 20, maxAge = 50,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "tech", "technology" },
		eligibility = function(state)
			return isInJobCategory(state, {"tech", "technology"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_tech",
		tags = { "learning", "technology", "skills" },
		
		choices = {
			{
				text = "Learn it thoroughly",
				effects = {},
				feedText = "Diving deep into the new tech...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.early_adopter = true
						state:AddFeed("📚 Mastered it! Now you're the expert!")
					else
						state:ModifyStat("Smarts", 2)
						state:AddFeed("📚 Basic understanding. Good enough for now.")
					end
				end,
			},
			{
				text = "Wait to see if it sticks",
				effects = { Happiness = 1, Smarts = 1 },
				feedText = "So many technologies come and go. Wait and see.",
			},
			{
				text = "It's just a fad - ignore it",
				effects = { Happiness = 2 },
				feedText = "Remember when everyone said that about JavaScript?",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MEDICAL JOBS (Healthcare Professionals)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		-- CRITICAL FIX: Renamed from "medical_code_blue" to avoid duplicate ID conflict
		-- Career.lua has another version
		id = "medical_code_blue_emergency",
		title = "Code Blue!",
		emoji = "🚨",
		text = "Emergency! A patient is crashing!",
		question = "How do you respond to the code?",
		minAge = 22, maxAge = 65,
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "medical", "healthcare" },
		eligibility = function(state)
			return isInJobCategory(state, {"medical", "healthcare"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_medical",
		tags = { "emergency", "life_death", "medical" },
		
		-- CRITICAL: Random emergency outcome
		choices = {
			{
				text = "Respond immediately and professionally",
				effects = {},
				feedText = "Racing to the patient...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.40 + (smarts / 200)
					if roll < successChance then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.saved_life = true
						state:AddFeed("🚨 Patient stabilized! You helped save a life!")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🚨 Team effort. Patient made it. Relief.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.lost_patient = true
						state:AddFeed("🚨 Lost them. Nothing more could be done. Heavy.")
					end
				end,
			},
			{
				text = "Freeze up in the moment",
				effects = { Happiness = -6, Smarts = 1 },
				setFlags = { froze_emergency = true },
				feedText = "Others took over. Training kicked in for them. Shake it off.",
			},
		},
	},
	{
		id = "medical_long_shift",
		title = "Extended Shift",
		emoji = "⏰",
		text = "Asked to work another double shift.",
		question = "Do you take the extra shift?",
		minAge = 20, maxAge = 60,
		baseChance = 0.5,
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "medical", "healthcare" },
		eligibility = function(state)
			return isInJobCategory(state, {"medical", "healthcare"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_medical",
		tags = { "overtime", "tired", "medical" },
		
		choices = {
			{ text = "Stay - patients need you", effects = { Money = 300, Health = -5, Happiness = -3 }, setFlags = { dedicated_healthcare = true }, feedText = "36 hours. Exhausted. But patients were cared for." },
			{ text = "Go home - need rest to be effective", effects = { Health = 2, Happiness = 2 }, feedText = "Can't help anyone if you're burned out." },
			{ text = "Compromise - stay a few more hours", effects = { Money = 100, Health = -2, Happiness = 1 }, feedText = "Middle ground. Help until replacement arrives." },
		},
	},
	{
		id = "medical_difficult_patient",
		title = "Difficult Patient",
		emoji = "😤",
		text = "A patient is being extremely difficult and combative.",
		question = "How do you handle the difficult patient?",
		minAge = 20, maxAge = 65,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"medical", "healthcare"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_medical",
		tags = { "patient", "difficult", "medical" },
		
		choices = {
			{ text = "Maintain professional compassion", effects = { Happiness = 3, Smarts = 2 }, setFlags = { compassionate_caregiver = true }, feedText = "They're scared and in pain. Patience prevails." },
			{ text = "Get frustrated - you're human", effects = { Happiness = -4 }, feedText = "Snapped a little. Apologized later. It happens." },
			{ text = "Tag out - someone else takes over", effects = { Happiness = 1 }, feedText = "Not every patient clicks with every caregiver." },
			{ text = "Report the behavior", effects = { Smarts = 1 }, feedText = "Documentation is important. Especially for safety." },
		},
	},
	{
		id = "medical_mistake_worry",
		title = "Medical Mistake Concern",
		emoji = "😰",
		text = "You're worried you might have made a mistake.",
		question = "What do you do about the potential error?",
		minAge = 22, maxAge = 65,
		baseChance = 0.455,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"medical", "healthcare"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_medical",
		tags = { "mistake", "anxiety", "medical" },
		
		-- CRITICAL: Random mistake outcome
		choices = {
			{
				text = "Double-check and report if needed",
				effects = {},
				feedText = "You verify your concern...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("😰 False alarm! Everything was fine. Relief floods in.")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", -2)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("😰 Small error caught early. No harm done. Good catch.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.medical_error = true
						state:AddFeed("😰 It was a mistake. Patient okay but incident reported.")
					end
				end,
			},
			{
				text = "Stay quiet and hope it's nothing",
				effects = {},
				feedText = "You decide not to say anything...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("😰 Nothing happened. The anxiety was worse than reality.")
					else
						state:ModifyStat("Happiness", -12)
						state.Flags = state.Flags or {}
						state.Flags.hidden_mistake = true
						state:AddFeed("😰 Something did happen. Now it's worse because you didn't report.")
					end
				end,
			},
		},
	},
	{
		id = "medical_breakthrough_case",
		title = "Breakthrough Case",
		emoji = "⭐",
		text = "A patient you've been treating is making a remarkable recovery!",
		question = "How does the breakthrough affect you?",
		minAge = 24, maxAge = 65,
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"medical", "healthcare"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_medical",
		tags = { "success", "recovery", "medical" },
		
		choices = {
			{ text = "Tears of joy - this is why you do it", effects = { Happiness = 12, Health = 2 }, setFlags = { purpose_reminder = true }, feedText = "This moment makes all the hard days worth it." },
			{ text = "Professional pride", effects = { Happiness = 6, Smarts = 2 }, feedText = "Good outcome. Evidence-based care works." },
			{ text = "Share the success with the team", effects = { Happiness = 8 }, feedText = "Team celebration. Everyone contributed to this win." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FINANCE JOBS (Banking, Accounting, Investing)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "finance_big_deal",
		title = "Big Deal",
		emoji = "💼",
		text = "A major deal/account is on the line.",
		question = "How do you handle the high-pressure deal?",
		minAge = 24, maxAge = 55,
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"finance", "banking"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_finance",
		tags = { "deal", "pressure", "finance" },
		
		-- CRITICAL: Random deal outcome
		choices = {
			{
				text = "Give your best pitch/work",
				effects = {},
				feedText = "Putting it all on the line...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.30 + (smarts / 150)
					if roll < successChance then
						state.Money = (state.Money or 0) + 2000
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.big_deal_winner = true
						state:AddFeed("💼 CLOSED THE DEAL! Huge bonus! Career milestone!")
					elseif roll < successChance + 0.35 then
						state.Money = (state.Money or 0) + 300
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💼 Deal done but smaller than hoped. Still a win.")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("💼 Lost the deal. Competition won. Crushing.")
					end
				end,
			},
			{
				text = "Play it safe - don't oversell",
				effects = { Money = 200, Happiness = 2 },
				feedText = "Conservative approach. Solid but not spectacular.",
			},
		},
	},
	{
		id = "finance_audit_stress",
		title = "Audit Season",
		emoji = "📊",
		text = "It's audit season. The pressure is immense.",
		question = "How do you survive audit season?",
		minAge = 22, maxAge = 55,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"finance", "banking"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_finance",
		tags = { "audit", "stress", "accounting" },
		
		choices = {
			{ text = "Long hours - get it done", effects = { Money = 300, Health = -5, Happiness = -4 }, setFlags = { audit_survivor = true }, feedText = "80-hour weeks. No life. But you survived." },
			{ text = "Delegate effectively", effects = { Money = 200, Smarts = 2, Happiness = 1 }, feedText = "Leadership shining through. Team handles it together." },
			{ text = "Make mistakes from exhaustion", effects = { Happiness = -6, Money = -200 }, setFlags = { audit_mistakes = true }, feedText = "Errors found. Rework required. Nightmare." },
			{ text = "Questioning life choices", effects = { Happiness = -5 }, setFlags = { reconsidering_finance = true }, feedText = "Is this worth it? Every year same misery." },
		},
	},
	{
		id = "finance_ethics_dilemma",
		title = "Ethical Gray Area",
		emoji = "⚖️",
		text = "You've discovered something potentially unethical at work.",
		question = "What do you do about the ethical concern?",
		minAge = 24, maxAge = 55,
		baseChance = 0.4,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"finance", "banking"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_finance",
		tags = { "ethics", "whistleblower", "finance" },
		
		-- CRITICAL: Random ethics outcome
		choices = {
			{
				text = "Report it through proper channels",
				effects = {},
				feedText = "You file the report...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.ethical_hero = true
						state:AddFeed("⚖️ Investigation happened. You did the right thing. Protected.")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -4)
						state:AddFeed("⚖️ Report buried. Nothing happened. Frustrating.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.retaliation = true
						state:AddFeed("⚖️ Retaliation. Suddenly your position is 'eliminated.'")
					end
				end,
			},
			{
				text = "Look the other way",
				effects = { Happiness = -5 },
				setFlags = { ignored_ethics = true },
				feedText = "Not your problem. But the guilt lingers.",
			},
			{
				text = "Anonymous tip to regulators",
				effects = {},
				feedText = "Anonymously reporting...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("⚖️ Investigation launched. You stayed anonymous.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("⚖️ Not enough evidence. Nothing happened.")
					end
				end,
			},
		},
	},
	{
		id = "finance_market_crash",
		title = "Market Volatility",
		emoji = "📉",
		text = "Markets are in turmoil. Clients are panicking.",
		question = "How do you handle the market chaos?",
		minAge = 24, maxAge = 55,
		baseChance = 0.455,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"finance", "banking"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_finance",
		tags = { "market", "crisis", "finance" },
		
		choices = {
			{ text = "Stay calm - advise patience", effects = { Happiness = 2, Smarts = 3 }, setFlags = { calm_advisor = true }, feedText = "Markets recover. Panic selling is the worst move." },
			{ text = "Make bold moves", effects = {}, feedText = "Taking calculated risks...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state.Money = (state.Money or 0) + 1000
						state:ModifyStat("Happiness", 8)
						state:AddFeed("📉 Bought the dip! Made money when others panicked!")
					else
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 500)
						state:ModifyStat("Happiness", -6)
						state:AddFeed("📉 Wrong call. Lost money trying to time the market.")
					end
				end,
			},
			{ text = "Panic like everyone else", effects = { Happiness = -5, Money = -200 }, feedText = "Sold at the bottom. Classic retail investor move." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CREATIVE JOBS (Art, Media, Entertainment)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		-- CRITICAL FIX: Renamed from "creative_big_break" to avoid duplicate ID conflict
		-- Career.lua has another version
		id = "creative_big_break_opportunity",
		title = "Big Break Opportunity",
		emoji = "⭐",
		text = "An opportunity could be your big break!",
		question = "How do you approach this opportunity?",
		minAge = 18, maxAge = 50,
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"creative", "entertainment", "media"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_creative",
		tags = { "opportunity", "fame", "creative" },
		
		-- CRITICAL: Random big break outcome
		choices = {
			{
				text = "Go all in - this is it",
				effects = {},
				feedText = "Putting everything on the line...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.15 + (looks / 200) + (smarts / 300)
					if roll < successChance then
						state.Money = (state.Money or 0) + 5000
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Looks", 3)
						state.Flags = state.Flags or {}
						state.Flags.big_break_success = true
						state:AddFeed("⭐ IT HAPPENED! Your big break! Career transformed!")
					elseif roll < successChance + 0.30 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 5)
						state:AddFeed("⭐ Good showing! Not viral but doors opened.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("⭐ Didn't work out. Back to the grind. Keep trying.")
					end
				end,
			},
			{
				text = "Play it safe",
				effects = { Happiness = -2 },
				setFlags = { played_safe = true },
				feedText = "What if? You'll always wonder. Regret creeps in.",
			},
		},
	},
	{
		-- CRITICAL FIX: Renamed from "creative_creative_block" to avoid duplicate ID conflict
		-- Career.lua has another version
		id = "creative_block_frustration",
		title = "Creative Block",
		emoji = "🧱",
		text = "You're completely blocked. No ideas. Nothing.",
		question = "How do you overcome the creative block?",
		minAge = 18, maxAge = 55,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"creative", "entertainment", "media"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_creative",
		tags = { "block", "creativity", "struggle" },
		
		choices = {
			{
				text = "Push through - force it",
				effects = {},
				feedText = "Creating anyway...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🧱 Breakthrough! Sometimes you just have to push.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🧱 Forced work feels forced. Not your best.")
					end
				end,
			},
			{
				text = "Take a break - refresh",
				effects = { Health = 2, Happiness = 3 },
				feedText = "Stepping away. Coming back with fresh eyes.",
			},
			{
				text = "Seek inspiration elsewhere",
				effects = { Smarts = 2 },
				feedText = "Museums, nature, conversations. Filling the creative well.",
			},
			{
				text = "Deadline panic - scramble",
				effects = { Happiness = -5, Smarts = 1 },
				setFlags = { deadline_panic = true },
				feedText = "Procrastination + pressure = something. Not great, but something.",
			},
		},
	},
	{
		id = "creative_criticism_response",
		title = "Harsh Criticism",
		emoji = "💔",
		text = "Your work received harsh criticism.",
		question = "How do you handle the negative feedback?",
		minAge = 18, maxAge = 55,
		baseChance = 0.555,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"creative", "entertainment", "media"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_creative",
		tags = { "criticism", "feedback", "creative" },
		
		choices = {
			{ text = "Learn from it - grow", effects = { Smarts = 4, Happiness = 2 }, setFlags = { handles_criticism = true }, feedText = "Painful but you found the valid points. Improving." },
			{ text = "Devastated - question everything", effects = { Happiness = -8 }, setFlags = { crushed_by_criticism = true }, feedText = "Maybe you're not cut out for this..." },
			{ text = "Dismiss it - they don't understand", effects = { Happiness = 2 }, feedText = "Haters gonna hate. Their opinion doesn't matter." },
			{ text = "Use it as fuel", effects = { Happiness = 4, Smarts = 2 }, setFlags = { motivated_by_hate = true }, feedText = "You'll show them. Prove them wrong." },
		},
	},
	{
		id = "creative_viral_content",
		title = "Content Going Viral",
		emoji = "🔥",
		text = "Something you created is going viral!",
		question = "What happens with your viral content?",
		minAge = 18, maxAge = 50,
		baseChance = 0.4,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"creative", "entertainment", "media"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_creative",
		tags = { "viral", "fame", "success" },
		
		-- CRITICAL: Random viral outcome
		choices = {
			{
				text = "Ride the wave",
				effects = {},
				feedText = "Numbers climbing, followers pouring in...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state.Money = (state.Money or 0) + 3000
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Looks", 2)
						state.Flags = state.Flags or {}
						state.Flags.viral_success = true
						state:AddFeed("🔥 MASSIVE SUCCESS! Brand deals! New opportunities!")
					elseif roll < 0.70 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🔥 Good buzz! More followers. Momentum building.")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🔥 Viral moment passed quickly. Flash in the pan.")
					end
				end,
			},
			{
				text = "Get overwhelmed by attention",
				effects = { Happiness = -3 },
				setFlags = { overwhelmed_fame = true },
				feedText = "Too much too fast. Anxiety about maintaining it.",
			},
		},
	},
	{
		id = "creative_collaboration",
		title = "Collaboration Offer",
		emoji = "🤝",
		text = "Someone wants to collaborate with you on a project!",
		question = "Do you accept the collaboration?",
		minAge = 18, maxAge = 55,
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"creative", "entertainment", "media"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_creative",
		tags = { "collaboration", "teamwork", "creative" },
		
		-- CRITICAL: Random collaboration outcome
		choices = {
			{
				text = "Collaborate and see what happens",
				effects = {},
				feedText = "Working together on something new...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state.Money = (state.Money or 0) + 400
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.good_collab = true
						state:AddFeed("🤝 Perfect partnership! Created something amazing!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🤝 Decent collaboration. Different styles but managed.")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.bad_collab = true
						state:AddFeed("🤝 Disaster. Creative differences. Never again.")
					end
				end,
			},
			{
				text = "Work alone - trust your vision",
				effects = { Happiness = 2 },
				setFlags = { solo_artist = true },
				feedText = "Your vision, your way. No compromises.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EDUCATION JOBS (Teachers, Professors)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "education_difficult_student",
		title = "Difficult Student",
		emoji = "😤",
		text = "A student is being particularly challenging.",
		question = "How do you handle the difficult student?",
		minAge = 24, maxAge = 65,
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"education", "teaching"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_education",
		tags = { "student", "teaching", "challenge" },
		
		choices = {
			{
				text = "Find what motivates them",
				effects = {},
				feedText = "Trying to connect...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.reached_student = true
						state:AddFeed("😤 Breakthrough! Found their spark. Teaching win!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("😤 Some progress. Still challenging but trying.")
					end
				end,
			},
			{
				text = "Strict discipline approach",
				effects = {},
				feedText = "Setting firm boundaries...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("😤 Structure worked. They responded to clear rules.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("😤 Backfired. Rebellion intensified.")
					end
				end,
			},
			{
				text = "Involve parents/administration",
				effects = { Happiness = 1 },
				feedText = "Not just your problem to solve. Getting support.",
			},
			{
				text = "Feel defeated",
				effects = { Happiness = -5 },
				setFlags = { teacher_burnout = true },
				feedText = "Can't reach everyone. Sometimes it's not enough.",
			},
		},
	},
	{
		id = "education_student_success",
		title = "Student Success Story",
		emoji = "🎓",
		text = "A former student reached out to thank you for changing their life!",
		question = "How does this affect you?",
		minAge = 28, maxAge = 70,
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"education", "teaching"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_education",
		tags = { "success", "impact", "teaching" },
		
		choices = {
			{ text = "This is why you teach", effects = { Happiness = 15, Health = 2 }, setFlags = { teaching_purpose = true }, feedText = "All the hard days were worth it. This. THIS." },
			{ text = "Humble - they did the work", effects = { Happiness = 8, Smarts = 1 }, feedText = "You guided, they succeeded. Credit to them." },
			{ text = "Proud and share the story", effects = { Happiness = 10 }, feedText = "Told everyone! This is what teaching is about!" },
		},
	},
	{
		id = "education_grading_nightmare",
		title = "Grading Mountain",
		emoji = "📝",
		text = "The stack of papers to grade is overwhelming.",
		question = "How do you tackle the grading?",
		minAge = 24, maxAge = 65,
		baseChance = 0.5,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"education", "teaching"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_education",
		tags = { "grading", "work", "teaching" },
		
		choices = {
			{ text = "Marathon session - get it done", effects = { Happiness = -3, Health = -2, Smarts = 1 }, feedText = "Hours of grading. Eyes crossing. But done." },
			{ text = "Spread it out over days", effects = { Happiness = 1 }, feedText = "Sustainable pace. Quality feedback." },
			{ text = "Curse the profession you chose", effects = { Happiness = -2 }, feedText = "Why. Why did they all write 5 pages." },
			{ text = "Speed grade with rubric", effects = { Happiness = 2, Smarts = 1 }, feedText = "Efficient system. Not compromising quality too much." },
		},
	},
	{
		id = "education_curriculum_change",
		title = "Curriculum Update",
		emoji = "📚",
		text = "Major curriculum changes are being implemented.",
		question = "How do you adapt to the changes?",
		minAge = 26, maxAge = 65,
		baseChance = 0.455,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"education", "teaching"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_education",
		tags = { "curriculum", "change", "education" },
		
		choices = {
			{ text = "Embrace and innovate", effects = { Smarts = 4, Happiness = 4 }, setFlags = { adaptive_teacher = true }, feedText = "Change is growth! New materials, new methods!" },
			{ text = "Reluctantly comply", effects = { Happiness = -2, Smarts = 1 }, feedText = "Following directives even if you disagree." },
			{ text = "Pushback and advocate", effects = { Smarts = 2, Happiness = -1 }, setFlags = { education_advocate = true }, feedText = "Fighting for what you believe is best for students." },
			{ text = "Ignore it - teach your way", effects = { Happiness = 2 }, setFlags = { rebel_teacher = true }, feedText = "Close that door and do what works. Risk though..." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MILITARY/GOVERNMENT JOBS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		-- CRITICAL FIX: Renamed from "military_deployment" to avoid duplicate ID conflict
		-- CareerEvents has another version
		id = "military_deployment_orders",
		title = "Deployment Orders",
		emoji = "🎖️",
		text = "You've received deployment orders.",
		question = "How do you handle deployment?",
		minAge = 18, maxAge = 50,
		oneTime = false,
		baseChance = 0.455,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"military"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_military",
		tags = { "military", "deployment", "service" },
		
		-- CRITICAL: Random deployment outcome
		choices = {
			{
				text = "Serve with honor",
				effects = {},
				feedText = "Months away from home...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					if roll < 0.60 then
						state.Money = (state.Money or 0) + 1000
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.served_deployed = true
						state:AddFeed("🎖️ Deployment complete. Served honorably. Changed forever.")
					elseif roll < 0.85 then
						state.Money = (state.Money or 0) + 1000
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Health", -3)
						state:AddFeed("🎖️ Deployment took a toll. Home now. Processing it all.")
					else
						state:ModifyStat("Happiness", -10)
						state:ModifyStat("Health", -10)
						state.Flags = state.Flags or {}
						state.Flags.combat_injury = true
						state:AddFeed("🎖️ Injured in service. Purple Heart. Recovery ahead.")
					end
				end,
			},
		},
	},
	{
		id = "government_bureaucracy",
		title = "Bureaucratic Nightmare",
		emoji = "📄",
		text = "The bureaucracy is frustrating beyond belief.",
		question = "How do you navigate the red tape?",
		minAge = 22, maxAge = 65,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"government", "military"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_government",
		tags = { "bureaucracy", "paperwork", "government" },
		
		choices = {
			{ text = "Learn to work the system", effects = { Smarts = 4, Happiness = 2 }, setFlags = { system_savvy = true }, feedText = "Found the shortcuts. Who to email. How to expedite." },
			{ text = "Get endlessly frustrated", effects = { Happiness = -5 }, feedText = "Form 27B-Stroke-6 denied because of Form 27A. WHAT." },
			{ text = "Accept it as part of the job", effects = { Happiness = 1, Smarts = 1 }, feedText = "This is government work. It is what it is." },
			{ text = "Advocate for better processes", effects = { Smarts = 2, Happiness = -2 }, setFlags = { reform_advocate = true }, feedText = "Trying to change things. Brick wall usually wins." },
		},
	},
	{
		id = "government_job_security",
		title = "Job Security",
		emoji = "🏛️",
		text = "Budget cuts are threatening positions.",
		question = "How secure is your government job?",
		minAge = 25, maxAge = 65,
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"government"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_government",
		tags = { "security", "budget", "government" },
		
		-- CRITICAL: Random job security outcome
		choices = {
			{
				text = "Ride out the uncertainty",
				effects = {},
				feedText = "Waiting for the budget decision...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🏛️ Safe! Funding secured. Job continues.")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🏛️ Position changed but still employed. Adapted.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.lost_gov_job = true
						state:AddFeed("🏛️ Position eliminated. Government shutdown claimed another.")
					end
				end,
			},
			{
				text = "Start looking elsewhere just in case",
				effects = { Smarts = 2 },
				setFlags = { hedging_bets = true },
				feedText = "Smart to have a backup plan. Applications sent.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SPORTS/ATHLETICS JOBS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "sports_big_game",
		title = "Big Game",
		emoji = "🏆",
		text = "The most important game/competition of the season!",
		question = "How do you perform under pressure?",
		minAge = 18, maxAge = 45,
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"sports", "athletics"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_sports",
		tags = { "competition", "pressure", "sports" },
		
		-- CRITICAL: Random game outcome
		choices = {
			{
				text = "Give your best performance",
				effects = {},
				feedText = "The crowd roars, you step up...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					local successChance = 0.30 + (health / 150)
					if roll < successChance then
						state.Money = (state.Money or 0) + 2000
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Health", 2)
						state.Flags = state.Flags or {}
						state.Flags.champion = true
						state:AddFeed("🏆 VICTORY! Career-defining performance! Champion!")
					elseif roll < successChance + 0.30 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🏆 Good showing! Didn't win but played well.")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🏆 Choked under pressure. Devastating loss.")
					end
				end,
			},
			{
				text = "Get injured during the game",
				effects = { Health = -10, Happiness = -8 },
				setFlags = { sports_injury = true },
				feedText = "Injury at the worst time. Season might be over.",
			},
		},
	},
	{
		id = "sports_career_ending_injury",
		title = "Injury Concern",
		emoji = "🤕",
		text = "A recurring injury is getting worse.",
		question = "How do you handle the injury situation?",
		minAge = 20, maxAge = 45,
		baseChance = 0.455,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"sports", "athletics"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_sports",
		tags = { "injury", "career", "sports" },
		
		-- CRITICAL: Random injury outcome
		choices = {
			{
				text = "Push through the pain",
				effects = {},
				feedText = "Playing hurt...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Health", -3)
						state:AddFeed("🤕 Managed the pain. Still performing. For now.")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -4)
						state:ModifyStat("Health", -8)
						state:AddFeed("🤕 Made it worse. Now need serious recovery time.")
					else
						state:ModifyStat("Happiness", -12)
						state:ModifyStat("Health", -15)
						state.Flags = state.Flags or {}
						state.Flags.career_ending_injury = true
						state:AddFeed("🤕 Career-ending injury. Playing days are over.")
					end
				end,
			},
			{
				text = "Take time to properly heal",
				effects = { Health = 5, Happiness = -3, Money = -500 },
				setFlags = { taking_recovery = true },
				feedText = "Missing games but long-term health matters more.",
			},
			{
				text = "Consult specialists",
				effects = { Money = -300 },
				feedText = "Getting the best medical advice...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Health", 8)
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🤕 Treatment plan working! Full recovery expected!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🤕 Need surgery. Long recovery but possible.")
					end
				end,
			},
		},
	},
	{
		id = "sports_retirement_age",
		title = "Career Twilight",
		emoji = "🌅",
		text = "You're getting older for this sport. Body doesn't recover like it used to.",
		question = "How do you face the end of your playing career?",
		minAge = 32, maxAge = 45,
		oneTime = true,
		baseChance = 0.55,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"sports", "athletics"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_sports",
		tags = { "retirement", "aging", "sports" },
		
		choices = {
			{ text = "One more season - not ready to quit", effects = { Health = -3, Happiness = 4 }, setFlags = { one_more_season = true }, feedText = "Not done yet. Proving doubters wrong." },
			{ text = "Transition to coaching", effects = { Happiness = 5, Smarts = 3 }, setFlags = { becoming_coach = true }, feedText = "Passing on knowledge. New chapter begins." },
			{ text = "Accept retirement gracefully", effects = { Happiness = 3, Health = 5 }, setFlags = { retired_athlete = true }, feedText = "Good career. Time for the next chapter." },
			{ text = "Struggle with identity loss", effects = { Happiness = -8 }, setFlags = { athlete_identity_crisis = true }, feedText = "If not an athlete, who are you? Hard transition." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- LAW / LEGAL PROFESSION (lawyers, judges, paralegals)
	-- CRITICAL FIX: User feedback - "only 20% of jobs have events"
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "law_big_case",
		title = "Major Case Assignment",
		emoji = "⚖️",
		text = "You've been assigned a high-profile case that could make or break your career.",
		question = "How do you approach this opportunity?",
		minAge = 25, maxAge = 65,
		baseChance = 0.5,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"law", "legal"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_law",
		tags = { "law", "case", "career" },
		
		choices = {
			{
				text = "Prepare meticulously - leave nothing to chance",
				effects = { Health = -3 },
				feedText = "Working around the clock on this case...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state.Money = (state.Money or 0) + math.random(5000, 15000)
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.won_big_case = true
						state:AddFeed("⚖️ WON THE CASE! Your reputation soars!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("⚖️ Lost the case despite preparation. Lessons learned.")
					end
				end,
			},
			{
				text = "Trust your instincts in the courtroom",
				effects = {},
				feedText = "Going in confident...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state.Money = (state.Money or 0) + math.random(3000, 8000)
						state:ModifyStat("Happiness", 8)
						state:AddFeed("⚖️ Your charisma won the jury over! Case won!")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("⚖️ Overconfidence backfired. Lost the case.")
					end
				end,
			},
			{
				text = "Seek a settlement before trial",
				effects = { Happiness = 3, Money = 2000 },
				feedText = "Negotiated a favorable settlement. Safe play.",
			},
		},
	},
	{
		id = "law_ethical_dilemma",
		title = "Legal Ethics Dilemma",
		emoji = "🤔",
		text = "A client wants you to do something legally questionable. It would help them win, but...",
		question = "What do you do?",
		minAge = 25, maxAge = 65,
		baseChance = 0.45,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"law", "legal"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_law",
		tags = { "law", "ethics", "career" },
		
		choices = {
			{
				text = "Refuse - your integrity isn't for sale",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { ethical_lawyer = true },
				feedText = "You might lose the client, but you keep your license.",
			},
			{
				text = "Push ethical boundaries (risky)",
				effects = {},
				feedText = "Walking a thin line...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state.Money = (state.Money or 0) + math.random(5000, 15000)
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🤔 Got away with it. Client happy. This time.")
					else
						state:ModifyStat("Happiness", -15)
						state.Flags = state.Flags or {}
						state.Flags.bar_investigation = true
						state:AddFeed("🤔 Bar Association is investigating you. Career at risk!")
					end
				end,
			},
			{
				text = "Find a legal loophole instead",
				effects = { Smarts = 3 },
				feedText = "Thinking creatively within the law...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state.Money = (state.Money or 0) + math.random(2000, 8000)
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🤔 Found a brilliant legal solution! Client impressed!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🤔 No loophole found. Had to decline client's request.")
					end
				end,
			},
		},
	},
	{
		id = "law_partner_offer",
		title = "Partnership Opportunity",
		emoji = "🏛️",
		text = "You're being considered for partner at your law firm!",
		question = "How do you feel about this milestone?",
		minAge = 30, maxAge = 55,
		baseChance = 0.4,
		oneTime = true,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"law", "legal"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_law",
		tags = { "law", "promotion", "career" },
		
		choices = {
			{
				text = "Accept partnership eagerly",
				effects = { Happiness = 15 },
				setFlags = { law_partner = true },
				feedText = "Evaluating your candidacy...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state.Money = (state.Money or 0) + math.random(20000, 50000)
						state:AddFeed("🏛️ YOU MADE PARTNER! Your name is on the door!")
					else
						state:ModifyStat("Happiness", -10)
						state:AddFeed("🏛️ Passed over for partnership. Maybe next year.")
					end
				end,
			},
			{
				text = "Negotiate better terms first",
				effects = { Smarts = 2 },
				feedText = "You know your worth...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state.Money = (state.Money or 0) + math.random(30000, 70000)
						state.Flags = state.Flags or {}
						state.Flags.law_partner = true
						state:ModifyStat("Happiness", 12)
						state:AddFeed("🏛️ Partner with excellent terms! Well negotiated!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🏛️ They found your demands excessive. Offer rescinded.")
					end
				end,
			},
		},
	},
	{
		id = "law_difficult_client",
		title = "Difficult Client",
		emoji = "😤",
		text = "Your client is being incredibly demanding and unreasonable about their case.",
		question = "How do you handle this situation?",
		minAge = 25, maxAge = 65,
		baseChance = 0.5,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"law", "legal"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_law",
		tags = { "law", "client", "conflict" },
		
		choices = {
			{
				text = "Set firm professional boundaries",
				effects = { Happiness = 3, Smarts = 2 },
				feedText = "Clear communication about expectations.",
			},
			{
				text = "Drop the client entirely",
				effects = { Money = -500, Happiness = 8 },
				feedText = "Some clients aren't worth the stress.",
			},
			{
				text = "Tolerate them - they pay well",
				effects = { Happiness = -5, Money = 1000 },
				feedText = "Money is money. Even if it costs your sanity.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- OFFICE / CORPORATE JOBS (admin, HR, management)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "office_meeting_marathon",
		title = "Meeting Marathon",
		emoji = "📅",
		text = "Your calendar is completely packed with back-to-back meetings today.",
		question = "How do you survive this meeting marathon?",
		minAge = 20, maxAge = 65,
		baseChance = 0.5,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"office", "admin", "corporate"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_office",
		tags = { "office", "meetings", "work" },
		
		choices = {
			{
				text = "Power through with coffee",
				effects = { Health = -2, Happiness = -3 },
				feedText = "So. Many. Meetings.",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Smarts", 2)
						state:AddFeed("📅 Managed to contribute something valuable in one meeting!")
					else
						state:AddFeed("📅 Survived, but you can't remember what any meeting was about.")
					end
				end,
			},
			{
				text = "Strategically decline some meetings",
				effects = { Happiness = 5 },
				feedText = "Work smarter, not harder...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:AddFeed("📅 Nobody even noticed you skipped those meetings!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📅 Boss noticed your absence. Got a talking-to.")
					end
				end,
			},
			{
				text = "Multitask during boring meetings",
				effects = { Smarts = 1 },
				feedText = "Laptop open, looking productive...",
			},
		},
	},
	{
		id = "office_watercooler_gossip",
		title = "Office Gossip",
		emoji = "🗣️",
		text = "You overhear some juicy gossip about a coworker's personal life.",
		question = "What do you do with this information?",
		minAge = 18, maxAge = 65,
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"office", "admin", "corporate", "entry", "service"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_office",
		tags = { "office", "gossip", "social" },
		
		choices = {
			{
				text = "Keep it to yourself - not your business",
				effects = { Happiness = 2, Smarts = 2 },
				setFlags = { trustworthy_coworker = true },
				feedText = "Discretion is the better part of valor.",
			},
			{
				text = "Share with one close work friend",
				effects = { Happiness = 3 },
				feedText = "You'll just tell ONE person...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:AddFeed("🗣️ The secret stayed between you two. Bonding moment!")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.office_gossip_backfire = true
						state:AddFeed("🗣️ It got back to the person. Awkward!")
					end
				end,
			},
			{
				text = "Use the information strategically",
				effects = {},
				feedText = "Knowledge is power...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state.Money = (state.Money or 0) + math.random(500, 2000)
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🗣️ Positioned yourself well in office politics.")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("🗣️ Your manipulation was noticed. Trust eroded.")
					end
				end,
			},
		},
	},
	{
		id = "office_project_credit",
		title = "Credit for Your Work",
		emoji = "😠",
		text = "A colleague is taking credit for work YOU did on a project!",
		question = "How do you respond?",
		minAge = 20, maxAge = 60,
		baseChance = 0.2, -- CRITICAL FIX: Reduced from 0.45 - was spamming with workplace_conflict!
		cooldown = 8, -- CRITICAL FIX: Increased from 3 - prevent credit-stealing spam
		maxOccurrences = 2, -- CRITICAL FIX: Max 2 times - this is a rare but impactful event
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"office", "admin", "corporate", "tech"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_office",
		tags = { "office", "conflict", "work" },
		
		choices = {
			{
				text = "Confront them privately",
				effects = {},
				feedText = "Time for a difficult conversation...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("😠 They apologized and gave you proper credit!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("😠 They denied everything. At least you spoke up.")
					end
				end,
			},
			{
				text = "Document everything and tell HR",
				effects = { Smarts = 2 },
				feedText = "Creating a paper trail...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.stood_up_for_self = true
						state:AddFeed("😠 HR sided with you. Proper credit given!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("😠 HR couldn't determine the truth. Frustrating.")
					end
				end,
			},
			{
				text = "Let it go - not worth the drama",
				effects = { Happiness = -4 },
				feedText = "Sometimes you just have to move on...",
			},
		},
	},
	{
		id = "office_work_from_home",
		title = "Remote Work Request",
		emoji = "🏠",
		text = "You want to work from home more often. Time to ask the boss.",
		question = "How do you approach this request?",
		minAge = 22, maxAge = 60,
		baseChance = 0.45,
		cooldown = 4,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"office", "admin", "corporate", "tech"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_office",
		tags = { "office", "wfh", "work" },
		
		choices = {
			{
				text = "Present a formal proposal with productivity data",
				effects = { Smarts = 3 },
				feedText = "Showing you've thought this through...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.remote_approved = true
						state:AddFeed("🏠 WFH approved! Hello, sweatpants productivity!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🏠 Request denied. Company culture, they said.")
					end
				end,
			},
			{
				text = "Just casually mention it",
				effects = {},
				feedText = "Testing the waters...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🏠 Boss was surprisingly cool with it!")
					else
						state:AddFeed("🏠 'We'll see' - the classic non-answer.")
					end
				end,
			},
			{
				text = "Don't ask - just start doing it occasionally",
				effects = {},
				feedText = "Better to ask forgiveness than permission...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🏠 Nobody seems to notice or care!")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("🏠 Got called out for not being in the office. Awkward.")
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SCIENCE / RESEARCH (scientists, researchers, lab workers)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "science_research_breakthrough",
		title = "Research Breakthrough",
		emoji = "🔬",
		text = "Your experiments are showing promising results! This could be huge!",
		question = "How do you proceed with this discovery?",
		minAge = 24, maxAge = 70,
		baseChance = 0.45,
		cooldown = 3,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "science", "research", "medical" },
		eligibility = function(state)
			return isInJobCategory(state, {"science", "research", "medical"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_science",
		tags = { "science", "research", "discovery" },
		
		choices = {
			{
				text = "Publish immediately - stake your claim",
				effects = {},
				feedText = "Racing to publish...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state.Money = (state.Money or 0) + math.random(3000, 10000)
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Smarts", 5)
						state.Flags = state.Flags or {}
						state.Flags.published_researcher = true
						state:AddFeed("🔬 Published in a major journal! Your name in lights!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🔬 Results didn't replicate. Back to the drawing board.")
					else
						state:ModifyStat("Happiness", -12)
						state:AddFeed("🔬 Someone else published the same thing first!")
					end
				end,
			},
			{
				text = "Verify results thoroughly first",
				effects = { Smarts = 3 },
				feedText = "Good science takes time...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state.Money = (state.Money or 0) + math.random(5000, 15000)
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 4)
						state:AddFeed("🔬 Results verified and published! Solid science!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🔬 Found a flaw. Good thing you checked!")
					end
				end,
			},
			{
				text = "Collaborate with another lab",
				effects = { Happiness = 3 },
				feedText = "Science is a team effort...",
				onResolve = function(state)
					state.Money = (state.Money or 0) + math.random(2000, 6000)
					state:ModifyStat("Smarts", 2)
					state:AddFeed("🔬 Joint publication - shared credit but stronger results!")
				end,
			},
		},
	},
	{
		id = "science_grant_application",
		title = "Grant Application",
		emoji = "📝",
		text = "A major research grant is available. The application deadline is approaching!",
		question = "How do you approach the grant application?",
		minAge = 26, maxAge = 70,
		baseChance = 0.5,
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "science", "research", "education" },
		eligibility = function(state)
			return isInJobCategory(state, {"science", "research", "education"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_science",
		tags = { "science", "grant", "funding" },
		
		choices = {
			{
				text = "Submit a bold, innovative proposal",
				effects = { Smarts = 2 },
				feedText = "Thinking big...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state.Money = (state.Money or 0) + math.random(20000, 100000)
						state:ModifyStat("Happiness", 20)
						state.Flags = state.Flags or {}
						state.Flags.major_grant = true
						state:AddFeed("📝 GRANT APPROVED! Funding secured for years!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📝 'Too risky' - reviewers didn't share your vision.")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("📝 Harsh feedback. Back to smaller grants.")
					end
				end,
			},
			{
				text = "Play it safe with proven methods",
				effects = {},
				feedText = "Tried and true...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state.Money = (state.Money or 0) + math.random(10000, 40000)
						state:ModifyStat("Happiness", 10)
						state:AddFeed("📝 Grant approved! Solid funding for the lab!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📝 'Not innovative enough' - can't win!")
					end
				end,
			},
			{
				text = "Skip this round - too much work",
				effects = { Happiness = 3, Health = 2 },
				feedText = "Sometimes self-care matters more.",
			},
		},
	},
	{
		id = "science_lab_accident",
		title = "Lab Incident",
		emoji = "⚗️",
		text = "There's been an accident in the lab! Equipment damaged, samples potentially contaminated.",
		question = "How do you handle this crisis?",
		minAge = 22, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		-- User bug: "IT SAYS LAB ACCIDENT EVEN THO IM A WAITER???"
		requiresJobCategory = { "science", "research", "medical" },
		eligibility = function(state)
			return isInJobCategory(state, {"science", "research", "medical"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_science",
		tags = { "science", "accident", "crisis" },
		
		choices = {
			{
				text = "Take full responsibility",
				effects = { Happiness = -5 },
				feedText = "Being accountable...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
					state:ModifyStat("Smarts", 2)
					state:AddFeed("⚗️ Administration appreciated your honesty. Small fine.")
				else
					-- CRITICAL FIX: Prevent negative money
					state.Money = math.max(0, (state.Money or 0) - math.random(500, 2000))
					state:AddFeed("⚗️ Serious consequences. Equipment costs deducted from budget.")
					end
				end,
			},
			{
				text = "Investigate what went wrong first",
				effects = { Smarts = 3 },
				feedText = "Finding the root cause...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("⚗️ Equipment malfunction! Not your fault after all!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("⚗️ Turns out protocols weren't followed. Need better training.")
					end
				end,
			},
			{
				text = "Quietly fix it - no one needs to know",
				effects = {},
				feedText = "What they don't know...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("⚗️ Crisis averted. Nobody noticed.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.lab_coverup_discovered = true
						state:AddFeed("⚗️ Cover-up discovered. Trust severely damaged.")
					end
				end,
			},
		},
	},
	{
		id = "science_peer_review",
		title = "Peer Review Drama",
		emoji = "📑",
		text = "A peer reviewer gave your paper a harsh, possibly unfair rejection.",
		question = "How do you respond?",
		minAge = 26, maxAge = 70,
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Added requiresJobCategory as PRIMARY check
		requiresJobCategory = { "science", "research", "education" },
		eligibility = function(state)
			return isInJobCategory(state, {"science", "research", "education"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_science",
		tags = { "science", "publishing", "conflict" },
		
		choices = {
			{
				text = "Appeal the decision professionally",
				effects = { Smarts = 2 },
				feedText = "Making your case...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("📑 Appeal successful! Paper accepted!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📑 Appeal denied. Try another journal.")
					end
				end,
			},
			{
				text = "Revise based on their feedback",
				effects = { Happiness = -2, Smarts = 3 },
				feedText = "Taking criticism constructively...",
				onResolve = function(state)
					state:ModifyStat("Happiness", 5)
					state:AddFeed("📑 Paper stronger now. Resubmitting!")
				end,
			},
			{
				text = "Vent about it publicly on social media",
				effects = {},
				feedText = "Academic Twitter, here we go...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("📑 Your rant went viral! Others had similar experiences!")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("📑 Came off as unprofessional. Bad look.")
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MORE MILITARY EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "military_promotion_board",
		title = "Promotion Board",
		emoji = "🎖️",
		text = "You're up for promotion! Time to appear before the board.",
		question = "How do you approach the promotion board?",
		minAge = 20, maxAge = 55,
		baseChance = 0.45,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"military", "defense"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_military",
		tags = { "military", "promotion", "career" },
		
		choices = {
			{
				text = "Demonstrate exceptional leadership",
				effects = {},
				feedText = "Presenting your service record...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state.Money = (state.Money or 0) + math.random(3000, 8000)
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.military_promoted = true
						state:AddFeed("🎖️ PROMOTED! New rank comes with new responsibilities!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🎖️ Not selected this time. Keep serving.")
					end
				end,
			},
			{
				text = "Highlight technical expertise",
				effects = { Smarts = 2 },
				feedText = "Showing your skills...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state.Money = (state.Money or 0) + math.random(2000, 6000)
						state:ModifyStat("Happiness", 12)
						state:AddFeed("🎖️ Promoted for technical excellence!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🎖️'Need more leadership experience' they said.")
					end
				end,
			},
		},
	},
	{
		id = "military_family_sacrifice",
		title = "Family vs. Duty",
		emoji = "👨‍👩‍👧",
		text = "Your service is taking a toll on family relationships. Missing important events, deployments...",
		question = "How do you balance duty and family?",
		minAge = 22, maxAge = 55,
		baseChance = 0.45,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"military", "defense"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_military",
		tags = { "military", "family", "balance" },
		
		choices = {
			{
				text = "Request a stateside assignment",
				effects = {},
				feedText = "Prioritizing family...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.stateside_assignment = true
						state:AddFeed("👨‍👩‍👧 Request approved! More time with family!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("👨‍👩‍👧 Needs of the service come first. Request denied.")
					end
				end,
			},
			{
				text = "Double down on service - family understands",
				effects = { Happiness = -5 },
				setFlags = { service_committed = true },
				feedText = "Duty calls. They'll understand... hopefully.",
			},
			{
				text = "Consider leaving the service",
				effects = { Happiness = 5 },
				setFlags = { considering_discharge = true },
				feedText = "Maybe civilian life is calling...",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MORE GOVERNMENT EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "government_whistleblower",
		title = "Witness Misconduct",
		emoji = "🔔",
		text = "You've discovered your department is wasting taxpayer money or breaking rules.",
		question = "Do you blow the whistle?",
		minAge = 22, maxAge = 65,
		baseChance = 0.4,
		cooldown = 4,
		oneTime = true,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"government", "public"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_government",
		tags = { "government", "ethics", "whistleblower" },
		
		choices = {
			{
				text = "Report through official channels",
				effects = {},
				feedText = "Following proper procedures...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.whistleblower_hero = true
						state:AddFeed("🔔 Investigation launched! You're protected by whistleblower laws!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.whistleblower_retaliation = true
						state:AddFeed("🔔 Report 'lost in the system'. Subtle retaliation begins.")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🔔 Problem quietly fixed. No credit given. At least it's fixed.")
					end
				end,
			},
			{
				text = "Go to the media anonymously",
				effects = {},
				feedText = "Leaking the truth...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.anonymous_hero = true
						state:AddFeed("🔔 Story breaks! Reform happens! You stay anonymous!")
					else
						state:ModifyStat("Happiness", -15)
						state.Flags = state.Flags or {}
						state.Flags.leak_traced = true
						state:AddFeed("🔔 Leak traced back to you. Career in jeopardy.")
					end
				end,
			},
			{
				text = "Keep quiet - not your problem",
				effects = { Happiness = -3 },
				feedText = "Self-preservation wins. This time.",
			},
		},
	},
	{
		id = "government_promotion_politics",
		title = "Political Promotion",
		emoji = "🏛️",
		text = "A promotion is available, but it seems to be going to the director's friend who's less qualified.",
		question = "How do you react to this situation?",
		minAge = 25, maxAge = 60,
		baseChance = 0.45,
		cooldown = 3,
		requiresJob = true,
		eligibility = function(state)
			return isInJobCategory(state, {"government", "public"})
		end,
		stage = STAGE,
		ageBand = "working_age",
		category = "career_government",
		tags = { "government", "promotion", "politics" },
		
		choices = {
			{
				text = "Apply anyway - merit should matter",
				effects = { Smarts = 2 },
				feedText = "Fighting the good fight...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state.Money = (state.Money or 0) + math.random(5000, 12000)
						state:ModifyStat("Happiness", 15)
						state:AddFeed("🏛️ Against all odds, YOU got it! Merit won!")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("🏛️ Exactly as predicted. The friend got it. At least you tried.")
					end
				end,
			},
			{
				text = "File a formal complaint",
				effects = {},
				feedText = "This isn't right...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state:ModifyStat("Happiness", 12)
						state:AddFeed("🏛️ Investigation found impropriety! Process restarted!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🏛️ Complaint noted but nothing changed. Made some enemies.")
					end
				end,
			},
			{
				text = "Accept it - that's how government works",
				effects = { Happiness = -5 },
				feedText = "Pick your battles...",
			},
		},
	},
}

return JobSpecificEvents
