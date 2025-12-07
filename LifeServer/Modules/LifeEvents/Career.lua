--[[
    Career Events
    All events here REQUIRE the player to have a job (requiresJob = true)
]]

local Career = {}

local STAGE = "adult" -- working-life events

Career.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- GENERAL WORKPLACE EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "workplace_conflict",
		title = "Office Drama",
		emoji = "😤",
		text = "A coworker has been taking credit for your work.",
		question = "How do you handle this?",
		minAge = 18, maxAge = 65,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		-- CRITICAL FIX: Can't have workplace conflicts while in prison!
		blockedByFlags = { in_prison = true },

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_workplace",
		tags = { "job", "conflict", "coworker", "office_politics" },

		choices = {
			{ text = "Confront them directly", effects = { Happiness = 3 }, setFlags = { workplace_confrontation = true }, feedText = "You called them out. The tension is thick." },
			{ text = "Document everything, report to HR", effects = { Smarts = 2 }, feedText = "You took the professional route." },
			{ text = "Let it go this time", effects = { Happiness = -3 }, feedText = "You let it slide. But you're watching now." },
			{ text = "Beat them at their own game", effects = { Smarts = 3 }, feedText = "Two can play at office politics." },
		},
	},
	{
		id = "promotion_opportunity",
		title = "Opportunity Knocks",
		emoji = "📈",
		text = "A promotion opportunity has opened up at work.",
		question = "Do you go for it?",
		minAge = 20, maxAge = 60,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		blockedByFlags = { in_prison = true },

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_growth",
		tags = { "job", "promotion", "money", "advancement" },
		careerTags = { "management" },

		choices = {
			{ text = "Apply and compete hard", effects = { Smarts = 2, Money = 500, Health = -2 }, setFlags = { sought_promotion = true }, feedText = "You threw your hat in the ring!" },
			{ text = "Apply casually", effects = { Money = 250 }, feedText = "You applied but kept expectations low." },
			{ text = "Not interested", effects = { Happiness = 2 }, feedText = "You're happy where you are." },
		},
	},
	{
		id = "layoff_threat",
		title = "Company Restructuring",
		emoji = "📉",
		text = "Your company is laying people off. Your position might be at risk.",
		question = "What do you do?",
		minAge = 22, maxAge = 60,
		baseChance = 0.3,
		cooldown = 5,
		requiresJob = true,
		-- CRITICAL FIX #9: Can't have layoff threats while in prison!
		blockedByFlags = { in_prison = true },

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_risk",
		tags = { "job", "layoffs", "risk", "stress" },

		choices = {
			{ text = "Work extra hard to prove value", effects = { Health = -5, Smarts = 2, Money = 200 }, feedText = "You worked overtime to secure your position." },
			{ text = "Start job hunting quietly", effects = { Smarts = 2 }, setFlags = { job_hunting = true }, feedText = "You're exploring other options." },
			{ text = "Accept severance if offered", effects = { Money = 2000, Happiness = -5 }, setFlags = { between_jobs = true }, feedText = "You took the package. Time for something new." },
			{ text = "Trust it will work out", effects = { Happiness = 2 }, feedText = "You hoped for the best..." },
		},
	},
	{
		id = "difficult_boss",
		title = "Difficult Manager",
		emoji = "👹",
		text = "Your new manager is making work miserable.",
		question = "How do you cope?",
		minAge = 18, maxAge = 60,
		baseChance = 0.4,
		cooldown = 4,
		requiresJob = true,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_workplace",
		tags = { "job", "manager", "stress", "conflict" },

		choices = {
			{ text = "Keep your head down", effects = { Happiness = -5, Health = -3 }, feedText = "You endured in silence." },
			{ text = "Address it with HR", effects = { Happiness = 3 }, feedText = "You reported the issues." },
			{ text = "Find a new job", effects = { Happiness = 5 }, setFlags = { job_hunting = true }, feedText = "Life's too short for bad bosses." },
			{ text = "Adapt and learn to work with them", effects = { Smarts = 3, Happiness = 2 }, feedText = "You figured out how to manage the relationship." },
		},
	},
	{
		id = "work_achievement",
		title = "Major Achievement",
		emoji = "🏆",
		text = "Your manager says you have a chance to really shine today.",
		question = "How do you approach this opportunity?",
		minAge = 20, maxAge = 65,
		baseChance = 0.3,
		cooldown = 3,
		requiresJob = true,
		requiresStats = { Smarts = { min = 50 } },

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_success",
		tags = { "achievement", "recognition", "job" },
		careerTags = { "leadership" },
		-- CRITICAL FIX: Random achievement outcome based on approach
		choices = {
			{
				text = "Go all out - maximum effort!",
				effects = { Health = -2 },
				feedText = "You gave it everything...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.40 + (smarts / 150)
					if roll < successChance then
						state.Money = (state.Money or 0) + 1000
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.big_achiever = true
						state:AddFeed("🏆 You knocked it out of the park! Major achievement!")
					elseif roll < successChance + 0.30 then
						state.Money = (state.Money or 0) + 300
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🏆 Solid performance! Good job but not exceptional.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🏆 Despite your effort, it didn't go as planned. Disappointing.")
					end
				end,
			},
			{
				text = "Play it smart and strategic",
				effects = {},
				feedText = "You approached it methodically...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.30 + (smarts / 120)
					if roll < successChance then
						state.Money = (state.Money or 0) + 800
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 4)
						state.Flags = state.Flags or {}
						state.Flags.problem_solver = true
						state:AddFeed("🏆 Your strategic approach paid off beautifully!")
					elseif roll < successChance + 0.35 then
						state.Money = (state.Money or 0) + 200
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🏆 It went okay. Nothing special but nothing wrong either.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🏆 Your plan didn't work out. Back to the drawing board.")
					end
				end,
			},
			{
				text = "Let others take the lead",
				effects = { Happiness = 2 },
				feedText = "You supported from the sidelines.",
			},
		},
	},
	{
		id = "business_trip",
		title = "Business Travel",
		emoji = "✈️",
		text = "You've been selected for an important business trip.",
		question = "How do you approach it?",
		minAge = 22, maxAge = 60,
		baseChance = 0.4,
		cooldown = 2,
		requiresJob = true,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_travel",
		tags = { "job", "travel", "clients" },

		choices = {
			{ text = "All business, impress the clients", effects = { Smarts = 3, Money = 300, Health = -2 }, feedText = "You crushed it professionally!" },
			{ text = "Balance work and exploration", effects = { Happiness = 5, Smarts = 2 }, feedText = "You saw some sights while getting work done!" },
			{ text = "Network at every opportunity", effects = { Smarts = 2 }, setFlags = { strong_network = true }, feedText = "You made valuable connections!" },
		},
	},
	{
		id = "career_crossroads",
		title = "Career Crossroads",
		emoji = "🛤️",
		text = "You're at a turning point in your career.",
		question = "What path do you take?",
		minAge = 28, maxAge = 45,
		baseChance = 0.5,
		cooldown = 5,
		requiresJob = true,

		-- META
		stage = STAGE,
		ageBand = "adult_midlife",
		category = "career_decision",
		tags = { "job", "decision", "pivot" },
		careerTags = { "career_general" },

		choices = {
			{ text = "Push for a promotion", effects = { Smarts = 2, Money = 500, Happiness = 5 }, feedText = "You went for the promotion!" },
			{ text = "Change companies for better pay", effects = { Money = 1000, Happiness = 3 }, setFlags = { job_hopper = true }, feedText = "You switched jobs for a raise!" },
			{ text = "Pivot to a new career entirely", effects = { Smarts = 5, Money = -1000, Happiness = 5 }, setFlags = { career_changer = true }, feedText = "You're starting over in a new field!" },
			{ text = "Stay the course", effects = { Happiness = 2 }, feedText = "You're content where you are." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- CAREER-SPECIFIC EVENTS (Require specific job categories)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "tech_innovation",
		title = "Tech Breakthrough",
		emoji = "💡",
		text = "You have an idea for a revolutionary new feature/product.",
		question = "What do you do with it?",
		minAge = 20, maxAge = 50,
		baseChance = 0.3,
		cooldown = 5,
		requiresJob = true,
		requiresJobCategory = "tech",

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_tech",
		tags = { "tech", "innovation", "product", "startup" },
		careerTags = { "tech", "startup" },

		choices = {
			{ text = "Pitch it to your company", effects = { Happiness = 8, Money = 1000, Smarts = 3 }, feedText = "You pitched your big idea!" },
			{ text = "Start your own company with it", effects = { Happiness = 10, Money = -3000 }, setFlags = { entrepreneur = true, startup_founder = true }, feedText = "You're going out on your own!" },
			{ text = "Keep developing it as a side project", effects = { Smarts = 5, Health = -2 }, setFlags = { side_hustler = true }, feedText = "You're building something on the side." },
			{ text = "Forget it, too risky", effects = { Happiness = -3 }, feedText = "The idea faded away..." },
		},
	},
	{
		id = "medical_save",
		title = "Critical Moment",
		emoji = "🏥",
		text = "A patient's life depends on your quick decision.",
		question = "What do you do?",
		minAge = 28, maxAge = 65,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		requiresJobCategory = "medical",

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_medical",
		tags = { "medical", "emergency", "patients" },
		careerTags = { "medical" },

		choices = {
			{ text = "Trust your training and act", effects = { Happiness = 10, Smarts = 5 }, feedText = "You made a split-second decision that saved them!" },
			{ text = "Consult with colleagues first", effects = { Smarts = 3, Happiness = 5 }, feedText = "Team medicine saved the day." },
			{ text = "Follow strict protocol", effects = { Smarts = 2 }, feedText = "By the book... it worked." },
		},
	},
	{
		id = "legal_case",
		title = "The Big Case",
		emoji = "⚖️",
		text = "You've been assigned a high-profile case.",
		question = "How do you approach it?",
		minAge = 27, maxAge = 65,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		requiresJobCategory = "law",

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_law",
		tags = { "law", "case", "high_profile" },
		careerTags = { "law" },

		choices = {
			{ text = "Work around the clock", effects = { Smarts = 5, Money = 2000, Health = -5 }, setFlags = { legal_star = true }, feedText = "You gave it everything!" },
			{ text = "Delegate and manage", effects = { Smarts = 3, Money = 1000 }, feedText = "Leadership got the job done." },
			{ text = "Find an unexpected angle", effects = { Smarts = 7, Happiness = 5, Money = 1500 }, feedText = "Your creative approach paid off!" },
		},
	},
	{
		id = "creative_block",
		title = "Creative Block",
		emoji = "🎨",
		text = "You're stuck. The inspiration just won't come.",
		question = "How do you push through?",
		minAge = 20, maxAge = 60,
		baseChance = 0.5,
		cooldown = 2,
		requiresJob = true,
		requiresJobCategory = "creative",

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_creative",
		tags = { "creative", "block", "art", "work" },
		careerTags = { "creative" },

		choices = {
			{ text = "Take a break and recharge", effects = { Happiness = 5, Health = 3, Smarts = 2 }, feedText = "Rest brought the creativity back." },
			{ text = "Push through with discipline", effects = { Smarts = 3, Happiness = -3, Health = -2 }, feedText = "Discipline overcame the block." },
			{ text = "Seek inspiration from others", effects = { Smarts = 4, Happiness = 3 }, feedText = "Collaboration sparked new ideas." },
			{ text = "Try something completely different", effects = { Happiness = 5, Smarts = 5 }, setFlags = { versatile_creative = true }, feedText = "A new direction opened new doors!" },
		},
	},
	{
		id = "athlete_injury",
		title = "Sports Injury",
		emoji = "🤕",
		text = "You've sustained an injury that could affect your career.",
		question = "How do you handle it?",
		minAge = 18, maxAge = 40,
		baseChance = 0.5,
		cooldown = 3,
		requiresJob = true,
		requiresJobCategory = "sports",

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_sports",
		tags = { "sports", "injury", "health" },
		careerTags = { "sports" },

		choices = {
			{ text = "Proper rehab, take time to heal", effects = { Health = 5, Money = -500, Happiness = -3 }, setFlags = { recovered_athlete = true }, feedText = "You took recovery seriously." },
			{ text = "Rush back too soon", effects = { Health = -10, Happiness = -5 }, setFlags = { chronic_injury = true }, feedText = "Coming back too fast made it worse..." },
			{ text = "Use it as motivation", effects = { Health = 3, Smarts = 2, Happiness = 5 }, setFlags = { comeback_story = true }, feedText = "You turned the setback into fuel!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ENTREPRENEURSHIP
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "business_opportunity",
		title = "Business Opportunity",
		emoji = "💰",
		text = "Someone approaches you with an exciting business opportunity. They promise big returns!",
		question = "What do you do?",
		minAge = 22, maxAge = 60,
		baseChance = 0.3,
		cooldown = 4,
		-- CRITICAL FIX #10: Can't invest if broke, can't be approached from prison
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true },
		-- Need at least $3000 to invest (first choice costs $3000)
		eligibility = function(state)
			local money = state.Money or 0
			if money < 500 then
				return false, "Too broke to be approached by investors"
			end
			return true
		end,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "entrepreneurship",
		tags = { "business", "investment", "scam_risk", "money" },
		careerTags = { "business" },
		-- CRITICAL FIX: Random investment outcome - can't choose if scam/legit
		choices = {
			{
				text = "Invest a significant amount",
				effects = { Money = -3000 },
				feedText = "You put your money on the line...",
				onResolve = function(state)
					local roll = math.random()
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					-- Smarter people slightly less likely to fall for scams
					local scamChance = 0.35 - (smarts / 400)
					if roll < scamChance then
						state:ModifyStat("Happiness", -15)
						state:AddFeed("💰 It was a scam! You lost everything you invested!")
					elseif roll < scamChance + 0.35 then
						state.Money = (state.Money or 0) + 3500
						state:ModifyStat("Happiness", 5)
						state:AddFeed("💰 Made a modest return on the investment.")
					else
						state.Money = (state.Money or 0) + 8000
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.investor = true
						state:AddFeed("💰 Great investment! You made serious money!")
					end
				end,
			},
			{
				text = "Research it thoroughly first",
				effects = { Smarts = 2 },
				feedText = "You investigated before committing...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("💰 Your research revealed it was a scam! Good call.")
					elseif roll < 0.60 then
						state.Money = (state.Money or 0) + 2000
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.investor = true
						state:AddFeed("💰 Legitimate opportunity! You invested and profited.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("💰 Took too long researching - the opportunity passed.")
					end
				end,
			},
			{
				text = "Decline - too risky",
				effects = { Happiness = 2 },
				feedText = "You played it safe...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Smarts", 2)
						state:AddFeed("💰 Smart move - later heard others lost money on it.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("💰 Others made good money on it. Maybe you were too cautious?")
					end
				end,
			},
		},
	},
	{
		id = "side_business",
		title = "Side Business Idea",
		emoji = "💡",
		text = "You've been working on a side business that's gaining traction.",
		question = "What's next?",
		minAge = 25, maxAge = 55,
		baseChance = 0.3,
		cooldown = 4,
		requiresFlags = { entrepreneur = true },

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "entrepreneurship",
		tags = { "business", "side_hustle", "growth" },
		careerTags = { "business" },

		choices = {
			{ 
				text = "Go full-time on it", 
				effects = { Happiness = 10, Money = 2000 }, 
				setFlags = { full_time_entrepreneur = true, between_jobs = true }, 
				feedText = "You quit your job to focus on your business!",
				onResolve = function(state)
					if state.ClearCareer then
						state:ClearCareer()
					else
						state.CurrentJob = nil
						state.Flags = state.Flags or {}
						state.Flags.has_job = nil
						state.Flags.employed = nil
					end
				end,
			},
			{ text = "Keep it as a side income", effects = { Money = 500, Happiness = 5, Health = -2 }, feedText = "Extra income is nice!" },
			{ text = "Sell it", effects = { Money = 5000, Happiness = 5 }, feedText = "You sold your side business for a nice profit!" },
			{ text = "Find investors", effects = { Money = 3000, Smarts = 2 }, setFlags = { has_investors = true }, feedText = "You brought on investors to grow!" },
		},
	},
	{
		id = "career_recognition",
		title = "Industry Recognition",
		emoji = "🏅",
		text = "You've been nominated for an industry award!",
		question = "How do you feel?",
		minAge = 30, maxAge = 65,
		baseChance = 0.2,
		cooldown = 5,
		requiresJob = true,
		requiresStats = { Smarts = { min = 70 } },

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_success",
		tags = { "award", "industry", "recognition" },
		careerTags = { "career_general" },

		choices = {
			{ text = "Honored and humbled", effects = { Happiness = 10, Smarts = 2 }, setFlags = { award_winner = true }, feedText = "You were recognized for your contributions!" },
			{ text = "It's about time!", effects = { Happiness = 8 }, setFlags = { award_winner = true }, feedText = "Finally, the recognition you deserved!" },
			{ text = "Use it to help others", effects = { Happiness = 12, Smarts = 3 }, setFlags = { award_winner = true, gives_back = true }, feedText = "You used your platform to lift others." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ADDITIONAL CAREER EVENTS - AAA QUALITY EXPANSION
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "work_from_home",
		title = "Remote Work Opportunity",
		emoji = "🏠",
		text = "Your company is offering a permanent work-from-home option.",
		question = "What do you choose?",
		minAge = 22, maxAge = 60,
		baseChance = 0.4,
		cooldown = 5,
		requiresJob = true,

		choices = {
			{ text = "Go fully remote", effects = { Happiness = 8, Health = 3, Money = 200 }, setFlags = { works_from_home = true }, feedText = "No more commute! Working in your pajamas!" },
			{ text = "Stay in the office", effects = { Happiness = 2, Smarts = 2 }, feedText = "You prefer the structure of the office." },
			{ text = "Hybrid schedule", effects = { Happiness = 6, Health = 2 }, setFlags = { hybrid_worker = true }, feedText = "Best of both worlds!" },
			{ text = "Use it to move somewhere cheaper", effects = { Happiness = 10, Money = 500 }, setFlags = { works_from_home = true, relocated = true }, feedText = "You moved to a lower cost of living area!" },
		},
	},
	{
		id = "toxic_workplace",
		title = "Toxic Workplace",
		emoji = "☢️",
		text = "Your workplace has become extremely toxic.",
		question = "How do you cope?",
		minAge = 20, maxAge = 60,
		baseChance = 0.3,
		cooldown = 4,
		requiresJob = true,

		choices = {
			{ 
				text = "Quit immediately - mental health first", 
				effects = { Happiness = 8, Health = 5, Money = -1000 }, 
				setFlags = { between_jobs = true }, 
				feedText = "You walked out. Best decision for your health.",
				onResolve = function(state)
					if state.ClearCareer then
						state:ClearCareer()
					else
						state.CurrentJob = nil
						state.Flags = state.Flags or {}
						state.Flags.has_job = nil
						state.Flags.employed = nil
					end
				end,
			},
			{ text = "Start job hunting while staying", effects = { Happiness = -5, Health = -3 }, setFlags = { job_hunting = true }, feedText = "You're enduring while looking for exits." },
			{ text = "Try to change the culture from within", effects = { Happiness = -3, Smarts = 3 }, feedText = "You're trying to make things better." },
			{ text = "Document everything for a lawsuit", effects = { Smarts = 2 }, setFlags = { building_case = true }, feedText = "You're keeping records of everything." },
		},
	},
	{
		id = "salary_negotiation",
		title = "Salary Negotiation",
		emoji = "💵",
		text = "It's annual review time. You're thinking about asking for a raise.",
		question = "How do you approach this negotiation?",
		minAge = 22, maxAge = 60,
		baseChance = 0.5,
		cooldown = 2,
		requiresJob = true,

		-- CRITICAL FIX: Changed from "pick your outcome" to "pick your approach"
		-- Actual raise amount is random based on stats + approach
		choices = {
			{ 
				text = "Come prepared with market data and achievements", 
				effects = { Smarts = 1 },
				onResolve = function(state, choice)
					local smarts = (state.Stats and state.Stats.Smarts) or state.Smarts or 50
					local performance = (state.CareerInfo and state.CareerInfo.performance) or 60
					-- Preparation + smart + good performance = better odds
					local successChance = 0.3 + (smarts / 200) + (performance / 200)
					local roll = math.random()
					if roll < successChance then
						choice.effects = { Money = 800, Smarts = 2, Happiness = 5 }
						choice.feedText = "Your research paid off! You got a solid raise!"
					elseif roll < successChance + 0.3 then
						choice.effects = { Money = 300, Happiness = 2 }
						choice.feedText = "You got a small raise. Better than nothing."
					else
						choice.effects = { Happiness = -5 }
						choice.feedText = "Denied. Budget constraints, they said."
					end
				end,
			},
			{ 
				text = "Ask confidently but wing it", 
				effects = {},
				onResolve = function(state, choice)
					local roll = math.random()
					if roll < 0.25 then
						choice.effects = { Money = 500, Happiness = 5 }
						choice.feedText = "They respected your confidence! Raise granted."
					elseif roll < 0.55 then
						choice.effects = { Money = 150, Happiness = 1 }
						choice.feedText = "You got a token increase."
					else
						choice.effects = { Happiness = -4 }
						choice.feedText = "Denied. Should have prepared better."
					end
				end,
			},
			{ 
				text = "Accept the standard cost-of-living increase", 
				effects = { Money = 200, Happiness = -1 }, 
				feedText = "You took the standard 2% increase." 
			},
			{ 
				text = "Threaten to leave if no raise", 
				effects = {},
				onResolve = function(state, choice)
					local roll = math.random()
					if roll < 0.35 then
						choice.effects = { Money = 1200, Happiness = 3 }
						choice.setFlags = { hardball_negotiator = true }
						choice.feedText = "They called your bluff and matched your demands!"
					elseif roll < 0.6 then
						choice.effects = { Money = 400 }
						choice.feedText = "They offered a compromise. Tension remains."
					else
						choice.effects = { Happiness = -10 }
						choice.setFlags = { burned_bridges = true }
						choice.feedText = "They said 'go ahead and leave.' Backfired badly."
					end
				end,
			},
			{ 
				text = "Ask for more vacation instead of money", 
				effects = { Happiness = 5, Health = 2 }, 
				setFlags = { values_time_off = true }, 
				feedText = "More days off granted! Time is priceless." 
			},
		},
	},
	{
		-- CRITICAL FIX: This was god-mode - player picked WHY they were fired!
		-- Now the reason is random and player just responds to being fired
		id = "fired",
		title = "❌ You're Fired!",
		emoji = "📦",
		text = "Your boss called you into the office... and fired you.",
		question = "How do you react?",
		minAge = 20, maxAge = 60,
		baseChance = 0.15,
		cooldown = 8,
		-- CRITICAL FIX #8: Added "fired" category for red event card
		category = "fired",
		requiresJob = true,

		choices = {
			{ 
				text = "Accept it and leave gracefully", 
				effects = { },
				feedText = "You were called into the office...",
				onResolve = function(state)
					-- CRITICAL FIX: Random reason for firing
					local performance = (state.CareerInfo and state.CareerInfo.performance) or 50
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					
					if performance < 40 or roll <= 30 then
						-- Performance issues
						state.Flags.fired = true
						state.Flags.between_jobs = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", -15)
						end
						state.Money = (state.Money or 0) - 500
						if state.AddFeed then
							state:AddFeed("📦 Fired for performance issues. You saw it coming.")
						end
					elseif roll <= 55 then
						-- Company downsizing (severance)
						state.Flags.laid_off = true
						state.Flags.between_jobs = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", -10)
						end
						state.Money = (state.Money or 0) + 2000
						if state.AddFeed then
							state:AddFeed("📦 Laid off due to downsizing. At least you got severance.")
						end
					else
						-- Politics / backstabbing
						state.Flags.fired = true
						state.Flags.betrayed = true
						state.Flags.between_jobs = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", -20)
						end
						if state.AddFeed then
							state:AddFeed("📦 Someone threw you under the bus. Devastating.")
						end
					end
				end,
			},
			{ 
				text = "Argue and make a scene", 
				effects = { Happiness = -25 }, 
				setFlags = { burned_bridges = true, between_jobs = true },
				feedText = "You lost it. Burned bridges. No reference letter for you.",
			},
		},
		onComplete = function(state)
			-- CRITICAL FIX: Clear both Career and CurrentJob
			if state.ClearCareer then
				state:ClearCareer()
			else
				state.CurrentJob = nil
				state.Career = nil
				state.Flags = state.Flags or {}
				state.Flags.has_job = nil
				state.Flags.employed = nil
			end
		end,
	},
	{
		id = "dream_job_offer",
		title = "Dream Job Offer?",
		emoji = "✨",
		text = "You received an incredible job offer! But should you trust it?",
		question = "How do you respond?",
		minAge = 25, maxAge = 55,
		baseChance = 0.2,
		cooldown = 6,
		requiresJob = true,
		-- CRITICAL FIX: Random job offer legitimacy - can't choose if it's a scam
		choices = {
			{
				text = "Accept immediately - this is my chance!",
				effects = {},
				feedText = "You jumped at the opportunity...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then -- 60% legitimate great job
						state.Money = (state.Money or 0) + 1000
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.dream_job = true
						state:AddFeed("✨ It's real! You got your dream job! Incredible!")
					elseif roll < 0.80 then -- 20% good but tradeoffs
						state.Money = (state.Money or 0) + 300
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.dream_job = true
						state:AddFeed("✨ Great job but required sacrifices. Worth it though!")
					else -- 20% scam
						state:ModifyStat("Happiness", -12)
						state:AddFeed("✨ It was a scam! They just wanted personal information. Crushed.")
					end
				end,
			},
			{
				text = "Research the company thoroughly first",
				effects = { Smarts = 1 },
				feedText = "You did your due diligence...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.10 then -- Small chance it was a scam you avoided
						state:ModifyStat("Happiness", 3)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("✨ Good thing you researched - it was a scam! Crisis averted.")
					elseif roll < 0.70 then -- Usually it's legit and you get it
						state.Money = (state.Money or 0) + 1000
						state:ModifyStat("Happiness", 14)
						state.Flags = state.Flags or {}
						state.Flags.dream_job = true
						state:AddFeed("✨ Verified and accepted! Your dream job awaits!")
					else -- Sometimes you're too slow
						state:ModifyStat("Happiness", -8)
						state:AddFeed("✨ Took too long researching - they gave the job to someone else!")
					end
				end,
			},
			{
				text = "Decline - seems too good to be true",
				effects = { Happiness = -3 },
				feedText = "You passed on the opportunity...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state:ModifyStat("Smarts", 2)
						state:AddFeed("✨ Smart move - later heard it was a scam company!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("✨ It was actually legitimate... you missed a real opportunity.")
					end
				end,
			},
		},
	},
	{
		id = "workplace_romance",
		title = "Office Romance",
		emoji = "💕",
		text = "You've developed feelings for a coworker.",
		question = "What do you do?",
		minAge = 20, maxAge = 55,
		baseChance = 0.3,
		cooldown = 5,
		requiresJob = true,
		blockedByFlags = { married = true },

		choices = {
			{ text = "Pursue it - love conquers all", effects = { Happiness = 10 }, setFlags = { office_romance = true, has_partner = true }, feedText = "You took a chance on love at work!" },
			{ text = "Keep it strictly professional", effects = { Happiness = -3, Smarts = 2 }, feedText = "You kept boundaries. Smart but hard." },
			{ text = "Transfer departments first", effects = { Happiness = 8 }, setFlags = { has_partner = true }, feedText = "You avoided conflicts of interest, then dated." },
			{ text = "Flirt but don't commit", effects = { Happiness = 5 }, setFlags = { office_flirt = true }, feedText = "The tension is fun but risky." },
		},
	},
	{
		id = "burnout_crisis",
		title = "Burnout",
		emoji = "🔥",
		text = "You're completely burnt out. Can't function anymore.",
		question = "What do you do?",
		minAge = 25, maxAge = 55,
		baseChance = 0.3,
		cooldown = 4,
		requiresJob = true,
		requiresStats = { Health = { max = 40 } },

		choices = {
			{ text = "Take a medical leave", effects = { Health = 15, Happiness = 10, Money = -1000 }, setFlags = { took_leave = true }, feedText = "You needed the break desperately." },
			{ text = "Push through - can't afford to stop", effects = { Health = -15, Happiness = -10 }, setFlags = { severe_burnout = true }, feedText = "You're destroying yourself..." },
			{ 
				text = "Quit without a plan", 
				effects = { Happiness = 8, Health = 10, Money = -2000 }, 
				setFlags = { between_jobs = true, sabbatical = true }, 
				feedText = "You snapped and walked out. Freedom!",
				onResolve = function(state)
					if state.ClearCareer then
						state:ClearCareer()
					else
						state.CurrentJob = nil
						state.Flags = state.Flags or {}
						state.Flags.has_job = nil
						state.Flags.employed = nil
					end
				end,
			},
			{ text = "Negotiate reduced hours", effects = { Health = 8, Happiness = 5, Money = -300 }, setFlags = { part_time = true }, feedText = "Your employer worked with you on balance." },
		},
	},
	{
		-- CRITICAL FIX: This was a god-mode event where player picked outcome!
		-- Now you meet a coworker and whether friendship works out is random
		id = "office_friendship",
		title = "New Coworker Connection",
		emoji = "🤝",
		text = "You've started chatting more with a coworker during lunch breaks. You two seem to click.",
		question = "Do you want to pursue this friendship?",
		minAge = 20, maxAge = 60,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,

		choices = {
			{ 
				text = "Yes, invite them to hang out", 
				effects = { },
				feedText = "You asked if they wanted to grab lunch...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					if roll <= 50 then
						state.Flags = state.Flags or {}
						state.Flags.has_work_friend = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", 8)
						end
						if state.AddFeed then
							state:AddFeed("🤝 Work BFF achieved! Lunch dates every day now.")
						end
					elseif roll <= 75 then
						if state.ModifyStat then
							state:ModifyStat("Happiness", 3)
						end
						if state.AddFeed then
							state:AddFeed("🤝 They're friendly but keep things professional.")
						end
					else
						if state.ModifyStat then
							state:ModifyStat("Happiness", -2)
						end
						if state.AddFeed then
							state:AddFeed("😕 Awkward - they didn't seem interested. Oh well.")
						end
					end
				end,
			},
			{ text = "Keep it professional", effects = { Happiness = 1 }, feedText = "You prefer to keep work and personal life separate." },
		},
	},
	{
		id = "major_presentation",
		title = "Big Presentation",
		emoji = "📊",
		text = "You have to present to the executive team!",
		question = "How do you prepare?",
		minAge = 25, maxAge = 60,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		-- CRITICAL FIX: Random presentation outcome based on preparation
		choices = {
			{
				text = "Practice extensively beforehand",
				effects = { Health = -1 },
				feedText = "You rehearsed for hours...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.45 + (smarts / 150)
					if roll < successChance then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.great_presenter = true
						state:AddFeed("📊 Nailed it! Standing ovation from the executives!")
					elseif roll < successChance + 0.35 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("📊 Solid presentation. Good feedback all around.")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("📊 You stumbled a bit. Not great, but you recovered.")
					end
				end,
			},
			{
				text = "Wing it - I know this stuff",
				effects = {},
				feedText = "You walked in confident...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.25 + (smarts / 200)
					if roll < successChance then
						state.Money = (state.Money or 0) + 600
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.natural_presenter = true
						state:AddFeed("📊 Crushed it! Natural born presenter!")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📊 It went okay. Got through it.")
					else
						state:ModifyStat("Happiness", -10)
						state:ModifyStat("Smarts", -2)
						state.Flags = state.Flags or {}
						state.Flags.presentation_trauma = true
						state:AddFeed("📊 Froze up completely. Total disaster. Embarrassing.")
					end
				end,
			},
			{
				text = "Ask a colleague to co-present",
				effects = { Happiness = 2 },
				feedText = "You presented together...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Smarts", 1)
						state:AddFeed("📊 Good teamwork! The presentation went smoothly.")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📊 It was okay. Some confusion about who was saying what.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📊 Your colleague dropped the ball. Awkward...")
					end
				end,
			},
		},
	},
	{
		id = "mentorship",
		title = "Mentorship Opportunity",
		emoji = "👨‍🏫",
		text = "A senior leader offers to mentor you.",
		question = "How do you respond?",
		minAge = 22, maxAge = 40,
		baseChance = 0.3,
		cooldown = 5,
		requiresJob = true,

		choices = {
			{ text = "Embrace it fully", effects = { Smarts = 5, Happiness = 8, Money = 500 }, setFlags = { has_mentor = true }, feedText = "Having a mentor accelerated your career!" },
			{ text = "Too busy right now", effects = { Happiness = -3 }, feedText = "You passed on a great opportunity." },
			{ text = "They taught you everything", effects = { Smarts = 7, Happiness = 10 }, setFlags = { mentored = true, rising_star = true }, feedText = "Your mentor's guidance changed your trajectory!" },
		},
	},
	{
		id = "overtime_culture",
		title = "Overtime Culture",
		emoji = "⏰",
		text = "Your workplace expects constant overtime.",
		question = "How do you handle it?",
		minAge = 22, maxAge = 55,
		baseChance = 0.4,
		cooldown = 2,
		requiresJob = true,

		choices = {
			{ text = "Work the overtime for money", effects = { Money = 600, Health = -8, Happiness = -5 }, feedText = "The money is good but you're exhausted." },
			{ text = "Set boundaries", effects = { Happiness = 5, Health = 3 }, setFlags = { sets_boundaries = true }, feedText = "You stood your ground on work-life balance." },
			{ text = "Look for another job", effects = { Happiness = 2 }, setFlags = { job_hunting = true }, feedText = "This culture isn't for you." },
			{ text = "Become the office hero", effects = { Money = 1000, Health = -12, Happiness = 5 }, setFlags = { workaholic = true }, feedText = "You're the go-to person but burning out." },
		},
	},
	{
		id = "startup_opportunity",
		title = "Startup Opportunity",
		emoji = "🚀",
		text = "A promising startup wants to recruit you.",
		question = "What do you do?",
		minAge = 22, maxAge = 45,
		baseChance = 0.25,
		cooldown = 5,
		requiresJob = true,

		choices = {
			{ text = "Jump in! High risk, high reward", effects = { Happiness = 10, Money = -500 }, setFlags = { startup_employee = true }, feedText = "You joined the startup! Equity could be huge!" },
			{ text = "Too risky - stay corporate", effects = { Happiness = -2, Money = 200 }, feedText = "You played it safe." },
			{ text = "Negotiate hard for equity", effects = { Happiness = 8, Smarts = 2 }, setFlags = { startup_employee = true, has_equity = true }, feedText = "You got a great equity package!" },
			{ text = "The startup failed before you could join", effects = { Happiness = 3 }, feedText = "Dodged a bullet! They went under." },
		},
	},
	{
		id = "caught_slacking",
		title = "Caught Slacking",
		emoji = "😬",
		text = "Your boss caught you slacking off at work!",
		question = "What happened?",
		minAge = 18, maxAge = 60,
		baseChance = 0.3,
		cooldown = 3,
		requiresJob = true,

		choices = {
			{ text = "Online shopping during work", effects = { Happiness = -5 }, feedText = "Caught with Amazon open. Embarrassing warning." },
			{ text = "Social media all day", effects = { Happiness = -5, Smarts = -2 }, feedText = "Your screen time was tracked. Busted." },
			{ text = "Taking a nap at your desk", effects = { Health = 2, Happiness = -8 }, feedText = "They woke you up. Major write-up." },
			{ text = "Actually it looked bad but you were on task", effects = { Happiness = -3, Smarts = 2 }, feedText = "You explained yourself. Close call." },
		},
	},
	{
		id = "coworker_leaving",
		title = "Coworker Departure",
		emoji = "👋",
		text = "Your favorite coworker is leaving the company.",
		question = "How do you feel?",
		minAge = 22, maxAge = 60,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,

		choices = {
			{ text = "Devastated - they made work fun", effects = { Happiness = -8 }, feedText = "Work will be so different without them." },
			{ text = "Inspired - maybe I should leave too", effects = { Happiness = 2 }, setFlags = { considering_leaving = true }, feedText = "They gave you something to think about." },
			{ text = "Happy for them - great opportunity", effects = { Happiness = 3 }, feedText = "You celebrated their new chapter." },
			{ text = "They got poached - now I want a raise", effects = { Happiness = 2, Smarts = 2 }, feedText = "If they're worth that much, so are you!" },
		},
	},
	{
		id = "workplace_harassment",
		title = "Workplace Harassment",
		emoji = "⚠️",
		text = "You're experiencing harassment at work.",
		question = "What do you do?",
		minAge = 18, maxAge = 60,
		baseChance = 0.15,
		cooldown = 8,
		requiresJob = true,

		choices = {
			{ text = "Report it to HR", effects = { Happiness = -5, Smarts = 2 }, setFlags = { reported_harassment = true }, feedText = "You made an official report." },
			{ text = "Confront the harasser directly", effects = { Happiness = -3 }, setFlags = { confronted_harasser = true }, feedText = "You stood up for yourself." },
			{ text = "Document and get legal advice", effects = { Smarts = 3, Money = -500 }, setFlags = { building_case = true }, feedText = "You're building a case." },
			{ text = "Leave the job entirely", effects = { Happiness = 3, Health = 5, Money = -1000 }, setFlags = { between_jobs = true }, feedText = "Your wellbeing mattered more than the job." },
		},
	},
	{
		id = "industry_conference",
		title = "Industry Conference",
		emoji = "🎤",
		text = "You attended a major industry conference!",
		question = "What was the highlight?",
		minAge = 25, maxAge = 60,
		baseChance = 0.4,
		cooldown = 2,
		requiresJob = true,

		choices = {
			{ text = "Met incredible people", effects = { Happiness = 8, Smarts = 3 }, setFlags = { strong_network = true }, feedText = "The connections you made were invaluable!" },
			{ text = "Got inspired by speakers", effects = { Happiness = 6, Smarts = 4 }, feedText = "You left full of new ideas." },
			{ text = "Landed a job lead", effects = { Happiness = 10, Money = 500 }, setFlags = { job_opportunity = true }, feedText = "A conversation led to an amazing opportunity!" },
			{ text = "Honestly it was boring", effects = { Happiness = -2, Money = -300 }, feedText = "Waste of time and money." },
		},
	},
	{
		id = "performance_review",
		title = "Performance Review",
		emoji = "📋",
		text = "It's annual performance review time. Your manager wants to discuss your progress.",
		question = "How do you approach this review?",
		minAge = 20, maxAge = 60,
		baseChance = 0.6,
		cooldown = 2,
		requiresJob = true,

		-- CRITICAL FIX: Changed from "pick your outcome" to "pick your approach" 
		-- Actual outcome is determined by stats + random chance via onResolve
		choices = {
			{ 
				text = "Walk in confident with achievements prepared", 
				effects = { Smarts = 1 },
				onResolve = function(state, choice)
					local smarts = (state.Stats and state.Stats.Smarts) or state.Smarts or 50
					local happiness = (state.Stats and state.Stats.Happiness) or state.Happiness or 50
					-- Prepared + smart employees get better reviews
					local successChance = 0.3 + (smarts / 200) + (happiness / 300)
					local roll = math.random()
					if roll < successChance then
						choice.effects = { Happiness = 10, Money = 800, Smarts = 2 }
						choice.setFlags = { top_performer = true }
						choice.feedText = "Exceeds expectations! Your preparation paid off!"
					elseif roll < successChance + 0.35 then
						choice.effects = { Happiness = 3, Money = 200 }
						choice.feedText = "Meets expectations. Solid performance."
					else
						choice.effects = { Happiness = -5 }
						choice.feedText = "Needs improvement. Time to step it up."
					end
				end,
			},
			{ 
				text = "Go in casually and wing it", 
				effects = {},
				onResolve = function(state, choice)
					local smarts = (state.Stats and state.Stats.Smarts) or state.Smarts or 50
					-- Winging it has lower success chance
					local successChance = 0.15 + (smarts / 300)
					local roll = math.random()
					if roll < successChance then
						choice.effects = { Happiness = 8, Money = 500 }
						choice.feedText = "Somehow you aced it! Lucky break."
					elseif roll < successChance + 0.4 then
						choice.effects = { Happiness = 1, Money = 100 }
						choice.feedText = "Meets expectations. Could have been better."
					else
						choice.effects = { Happiness = -8 }
						choice.setFlags = { on_pip = true }
						choice.feedText = "Needs improvement. You're on a performance plan now."
					end
				end,
			},
		{ 
			text = "Ask to reschedule - not feeling ready", 
			effects = { Happiness = -3 },
			feedText = "You postponed the review. The anxiety continues." 
		},
	},
},

-- ══════════════════════════════════════════════════════════════════════════════
-- NEW EVENTS - EXPANDED CAREER CONTENT
-- ══════════════════════════════════════════════════════════════════════════════
{
	id = "company_acquisition",
	title = "Your Company Got Acquired!",
	emoji = "🏢",
	text = "Big news: a larger corporation just acquired your company. There's talk of 'synergies' and 'restructuring.' Translation: layoffs might be coming. But there could also be new opportunities.",
	question = "How do you handle this uncertain time?",
	minAge = 22, maxAge = 55,
	baseChance = 0.25,
	cooldown = 6,
	requiresJob = true,
	
	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_risk",
	tags = { "job", "acquisition", "corporate", "change" },
	
	choices = {
		{ text = "Network aggressively - make yourself visible", effects = { Happiness = -2, Smarts = 3, Money = 200 }, setFlags = { networker = true }, feedText = "You introduced yourself to the new executives. Smart move." },
		{ text = "Keep your head down and hope for the best", effects = { Happiness = -5 }, feedText = "You're playing it safe. Nervously checking your email." },
		{ text = "Start looking for a new job immediately", effects = { Happiness = 3, Smarts = 2 }, setFlags = { proactive_job_hunt = true }, feedText = "You're not waiting to find out. Applications are out." },
		{ text = "Volunteer for the integration team", effects = { Happiness = 5, Money = 500, Smarts = 4 }, setFlags = { integration_leader = true }, feedText = "You positioned yourself as a key player in the transition!" },
	},
},
{
	id = "remote_work_decision",
	title = "Remote Work Opportunity",
	emoji = "🏠",
	text = "Your company is offering permanent remote work options. You could work from home forever, come to the office, or go hybrid.",
	question = "What's your work style?",
	minAge = 20, maxAge = 60,
	baseChance = 0.35,
	cooldown = 5,
	requiresJob = true,
	
	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_lifestyle",
	tags = { "job", "remote", "flexibility", "lifestyle" },
	
	choices = {
		{ text = "Go fully remote - freedom!", effects = { Happiness = 10, Health = 3 }, setFlags = { remote_worker = true }, feedText = "No more commute! You're working in pajamas now." },
		{ text = "Stay in the office - I need the structure", effects = { Happiness = 3, Smarts = 2 }, setFlags = { office_worker = true }, feedText = "You thrive on in-person collaboration." },
		{ text = "Hybrid - best of both worlds", effects = { Happiness = 7, Health = 2 }, setFlags = { hybrid_worker = true }, feedText = "Some days home, some days office. Perfect balance." },
		{ text = "Ask to relocate to a cheaper city", effects = { Happiness = 8, Money = 800 }, setFlags = { relocated_worker = true }, feedText = "You moved somewhere with lower cost of living while keeping your salary!" },
	},
},
{
	-- CRITICAL FIX: Renamed from "side_hustle_opportunity" to avoid ID conflict with FastFoodEvents
	id = "side_hustle_idea",
	title = "Side Hustle Opportunity",
	emoji = "💡",
	text = "You've got an idea for a side business. It could bring in extra money, but it'll take time away from your main job and personal life.",
	question = "Do you pursue the side hustle?",
	minAge = 22, maxAge = 50,
	baseChance = 0.35,
	cooldown = 4,
	requiresJob = true,
	
	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_entrepreneurship",
	tags = { "job", "side_hustle", "entrepreneurship", "money" },
	
	choices = {
		{ text = "Go all in - build it nights and weekends", effects = { Happiness = 5, Money = 1500, Health = -5 }, setFlags = { side_hustler = true, entrepreneur = true }, feedText = "You're burning the midnight oil. The hustle is real!" },
		{ text = "Start small - test the waters", effects = { Happiness = 3, Money = 500 }, setFlags = { small_business = true }, feedText = "You launched with minimal risk. Smart approach." },
		{ text = "Focus on my current career", effects = { Happiness = 2, Smarts = 2 }, feedText = "You decided to excel at your main job instead." },
		{ text = "Partner with a friend on it", effects = { Happiness = 5, Money = 800 }, setFlags = { business_partner = true }, feedText = "You and a friend are building something together!" },
	},
},
{
	id = "toxic_workplace_culture",
	title = "Toxic Work Environment",
	emoji = "☣️",
	text = "Your workplace has become toxic. Gossip, backstabbing, unclear expectations, and constant stress. Your mental health is suffering.",
	question = "How do you cope?",
	minAge = 20, maxAge = 55,
	baseChance = 0.3,
	cooldown = 4,
	requiresJob = true,
	requiresStats = { Happiness = { max = 60 } },
	
	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_challenge",
	tags = { "job", "toxic", "stress", "mental_health" },
	
	choices = {
		{ text = "Set firm boundaries", effects = { Happiness = 5, Health = 3, Smarts = 2 }, setFlags = { boundary_setter = true }, feedText = "You stopped answering emails after 6pm. Revolutionary." },
		{ text = "Confront the issues head-on", effects = { Happiness = -3, Smarts = 4 }, setFlags = { confrontational = true }, feedText = "You called out the toxicity in a meeting. Brave but risky." },
		{ text = "Document everything and report to HR", effects = { Happiness = -2, Smarts = 3 }, setFlags = { documented_issues = true }, feedText = "You're building a paper trail. Just in case." },
		{ text = "Start therapy to cope", effects = { Happiness = 8, Health = 5, Money = -500 }, setFlags = { in_therapy = true }, feedText = "Professional help is making a real difference." },
	},
},
{
	id = "mentorship_opportunity",
	title = "Mentorship Moment",
	emoji = "🎓",
	text = "A senior leader at your company has taken notice of your work and offered to be your mentor.",
	question = "How do you respond?",
	minAge = 22, maxAge = 40,
	baseChance = 0.25,
	cooldown = 5,
	requiresJob = true,
	
	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_growth",
	tags = { "job", "mentor", "leadership", "growth" },
	
	choices = {
		{ text = "Eagerly accept - learn everything!", effects = { Happiness = 8, Smarts = 6, Money = 300 }, setFlags = { has_mentor = true, eager_learner = true }, feedText = "You're soaking up wisdom like a sponge. Career accelerating!" },
		{ text = "Accept but set boundaries", effects = { Happiness = 5, Smarts = 4 }, setFlags = { has_mentor = true }, feedText = "You're learning but maintaining your independence." },
		{ text = "Politely decline - don't want the pressure", effects = { Happiness = 2 }, feedText = "You prefer to find your own way. Valid choice." },
		{ text = "Accept and eventually become a mentor yourself", effects = { Happiness = 10, Smarts = 5 }, setFlags = { has_mentor = true, future_mentor = true }, feedText = "The cycle of mentorship continues through you!" },
	},
},
{
	id = "career_pivot_consideration",
	title = "Career Pivot?",
	emoji = "🔄",
	text = "You've been thinking about a complete career change. Different industry, different role. A fresh start.",
	question = "Do you take the leap?",
	minAge = 28, maxAge = 50,
	baseChance = 0.25,
	cooldown = 6,
	requiresJob = true,
	
	-- META
	stage = STAGE,
	ageBand = "adult_midlife",
	category = "career_change",
	tags = { "job", "pivot", "change", "risk" },
	
	choices = {
		{ 
			text = "Yes - start over in a new field", 
			effects = { Happiness = 10, Money = -2000, Smarts = 5 }, 
			setFlags = { career_pivoter = true },
			feedText = "You quit and started over. Scary but exciting!",
			onResolve = function(state)
				if state.ClearCareer then
					state:ClearCareer()
				else
					state.CurrentJob = nil
					state.Flags = state.Flags or {}
					state.Flags.has_job = nil
					state.Flags.employed = nil
					state.Flags.between_jobs = true
				end
			end,
		},
		{ text = "Take night classes while keeping your job", effects = { Happiness = 5, Smarts = 4, Health = -2 }, setFlags = { learning_new_field = true }, feedText = "You're building new skills on the side." },
		{ text = "Stay where you are - too risky", effects = { Happiness = -3 }, feedText = "You chose security over passion. For now." },
		{ text = "Transition gradually within your company", effects = { Happiness = 6, Smarts = 3 }, setFlags = { internal_pivot = true }, feedText = "You're moving to a different department. New challenges, same paycheck!" },
	},
},
{
	-- CRITICAL FIX: This was a god-mode event where player chose if they won!
	-- Now uses random outcome based on performance like BitLife
	id = "workplace_recognition",
	title = "Award Ceremony",
	emoji = "🏆",
	text = "Your work has been noticed! You're nominated for an employee recognition award. The ceremony is tonight.",
	question = "Will you attend?",
	minAge = 22, maxAge = 55,
	baseChance = 0.3,
	cooldown = 3,
	requiresJob = true,
	
	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_success",
	tags = { "job", "recognition", "achievement", "success" },
	
	choices = {
		{ 
			text = "Attend the ceremony", 
			effects = { },
			feedText = "You attended the ceremony...",
			onResolve = function(state)
				-- CRITICAL FIX: Random outcome, not player choice!
				local performance = (state.CareerInfo and state.CareerInfo.performance) or 50
				local roll = math.random(1, 100)
				if roll <= performance * 0.5 then
					state.Flags = state.Flags or {}
					state.Flags.award_winner = true
					state.Flags.recognized = true
					state.Money = (state.Money or 0) + 500
					if state.ModifyStat then
						state:ModifyStat("Happiness", 15)
					end
					if state.AddFeed then
						state:AddFeed("🏆 You WON! Standing ovation!")
					end
				elseif roll <= performance * 0.8 then
					state.Flags = state.Flags or {}
					state.Flags.recognized = true
					state.Money = (state.Money or 0) + 200
					if state.ModifyStat then
						state:ModifyStat("Happiness", 7)
					end
					if state.AddFeed then
						state:AddFeed("🥈 Runner-up. Still an honor!")
					end
				else
					if state.ModifyStat then
						state:ModifyStat("Happiness", -3)
					end
					if state.AddFeed then
						state:AddFeed("😕 Someone else won. Maybe next year.")
					end
				end
			end,
		},
		{ text = "Skip it - too nervous", effects = { Happiness = -2 }, feedText = "You skipped the ceremony. Wonder if you would have won..." },
	},
},

-- ══════════════════════════════════════════════════════════════════════════════
-- SPORTS JOB SPECIFIC EVENTS  
-- ══════════════════════════════════════════════════════════════════════════════
{
	-- CRITICAL FIX: Player can't choose injury severity - random outcome
	id = "sports_injury_scare",
	title = "Career-Threatening Injury",
	emoji = "🏥",
	text = "During practice, you go down. Pain shoots through your leg. Trainers rush over. You're carried off. MRI scheduled. This could be BAD.",
	question = "What do you do?",
	minAge = 18, maxAge = 45,
	baseChance = 0.25,
	cooldown = 5,
	requiresJob = true,
	requiresJobCategory = "sports",
	blockedByFlags = { in_prison = true },

	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_sports",
	tags = { "injury", "sports", "career" },

	choices = {
		{
			text = "Wait anxiously for the MRI results",
			effects = { Happiness = -5 },
			feedText = "The waiting is the worst part...",
			onResolve = function(state)
				-- Random injury severity - player doesn't choose!
				local roll = math.random()
				if roll < 0.50 then
					-- Minor injury
					if state.ModifyStat then
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", 10)
					end
					if state.AddFeed then
						state:AddFeed("🎉 Great news! Just a minor strain. 2 weeks of rest and you'll be back on the field.")
					end
				elseif roll < 0.85 then
					-- Serious injury
					if state.ModifyStat then
						state:ModifyStat("Health", -25)
						state:ModifyStat("Happiness", -15)
					end
					state.Flags = state.Flags or {}
					state.Flags.injured_athlete = true
					if state.AddFeed then
						state:AddFeed("😔 Bad news. Torn ligament. Surgery needed. Season's over. Months of grueling rehab ahead.")
					end
				else
					-- Career-ending
					if state.ModifyStat then
						state:ModifyStat("Health", -35)
						state:ModifyStat("Happiness", -30)
					end
					state.Money = (state.Money or 0) + 50000
					if state.CurrentJob and state.CurrentJob.category == "sports" then
						state.CurrentJob = nil
					end
					state.Flags = state.Flags or {}
					state.Flags.retired_athlete = true
					if state.AddFeed then
						state:AddFeed("💔 The worst news. Career-ending injury. Your playing days are over. $50K insurance settlement. Time for chapter 2 of your life.")
					end
				end
			end,
		},
		{
			text = "Stay positive and pray for good news",
			effects = { Happiness = 2 },
			feedText = "You try to keep a positive mindset...",
			onResolve = function(state)
				-- Same random outcome but slight happiness boost for positivity
				local roll = math.random()
				if roll < 0.55 then -- Slightly better odds for being positive
					if state.ModifyStat then
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", 12)
					end
					if state.AddFeed then
						state:AddFeed("🙏 Your positive attitude paid off! Just a minor sprain. Back in action soon!")
					end
				else
					if state.ModifyStat then
						state:ModifyStat("Health", -20)
						state:ModifyStat("Happiness", -10)
					end
					state.Flags = state.Flags or {}
					state.Flags.injured_athlete = true
					if state.AddFeed then
						state:AddFeed("😢 Serious injury confirmed. Months of rehab ahead. Stay strong.")
					end
				end
			end,
		},
	},
},
{
	id = "championship_game",
	title = "Championship Opportunity",
	emoji = "🏆",
	text = "Your team made it to the championship! All your hard work led to this moment. The whole world is watching. Nerves are electric.",
	question = "How do you perform?",
	minAge = 18, maxAge = 40,
	baseChance = 0.15,
	cooldown = 8,
	requiresJob = true,
	requiresJobCategory = "sports",
	blockedByFlags = { in_prison = true },

	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_sports",
	tags = { "championship", "sports", "success" },

	choices = {
		{
			text = "MVP performance - CHAMPIONS!",
			effects = { Happiness = 25, Health = -5 },
			setFlags = { championship_winner = true, sports_legend = true },
			feedText = "YOU DID IT! MVP! CHAMPIONS! Parade through the city!",
			onResolve = function(state)
				local bonus = math.random(100000, 500000)
				state.Money = (state.Money or 0) + bonus
				if state.AddFeed then
					state:AddFeed(string.format("🏆 Championship bonus: $%d! You're a LEGEND!", bonus))
				end
			end,
		},
		{
			text = "Solid contribution - team wins",
			effects = { Happiness = 18, Health = -3 },
			setFlags = { championship_winner = true },
			feedText = "Your team won! You contributed. Champion!",
			onResolve = function(state)
				local bonus = math.random(50000, 150000)
				state.Money = (state.Money or 0) + bonus
			end,
		},
		{
			text = "Heartbreaking loss in finals",
			effects = { Happiness = -15, Health = -5 },
			feedText = "So close. Runner-up. The 'what ifs' will haunt you.",
		},
	},
},

-- ══════════════════════════════════════════════════════════════════════════════
-- CREATIVE JOB SPECIFIC EVENTS
-- ══════════════════════════════════════════════════════════════════════════════
{
	-- CRITICAL FIX: Renamed to avoid duplicate ID with earlier creative_block event
	id = "creative_deadline_crisis",
	title = "Deadline Creative Block",
	emoji = "🎨",
	text = "You're staring at a blank canvas/screen/page. Nothing. The deadline is TOMORROW. Your creative well has run completely dry.",
	question = "How do you overcome it?",
	minAge = 20, maxAge = 60,
	baseChance = 0.35,
	cooldown = 3,
	requiresJob = true,
	requiresJobCategory = "creative",
	blockedByFlags = { in_prison = true },

	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_creative",
	tags = { "creativity", "stress", "deadline" },

	choices = {
		{
			text = "Power through - all-nighter",
			effects = { Health = -8, Happiness = -5 },
			feedText = "You pulled an all-nighter...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.6 then
					if state.ModifyStat then
						state:ModifyStat("Smarts", 3)
					end
					if state.AddFeed then
						state:AddFeed("💡 Breakthrough at 3AM! Creativity struck! It's GOOD!")
					end
				else
					if state.AddFeed then
						state:AddFeed("😩 Exhausted garbage. You'll have to redo it.")
					end
				end
			end,
		},
		{
			text = "Step away and find inspiration",
			effects = { Happiness = 3, Health = 2 },
			feedText = "You went for a walk...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.7 then
					if state.AddFeed then
						state:AddFeed("🌅 Fresh air did the trick. Idea struck while walking!")
					end
				else
					if state.AddFeed then
						state:AddFeed("🤷 Nice walk. Still no ideas. Deadline missed.")
					end
				end
			end,
		},
		{
			text = "Be honest with the client",
			effects = { Happiness = -3, Smarts = 2 },
			feedText = "You asked for an extension. Honest but risky.",
		},
	},
},
{
	id = "creative_viral_moment",
	title = "Viral Success!",
	emoji = "📱",
	text = "Your latest work EXPLODED online! Millions of views. People sharing. News outlets reaching out. You're suddenly FAMOUS.",
	question = "How do you handle sudden fame?",
	minAge = 18, maxAge = 55,
	baseChance = 0.1,
	cooldown = 10,
	requiresJob = true,
	requiresJobCategory = "creative",
	blockedByFlags = { in_prison = true },

	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_creative",
	tags = { "viral", "fame", "success" },

	choices = {
		{
			text = "Capitalize immediately - brand deals!",
			effects = { Happiness = 12 },
			setFlags = { viral_star = true },
			feedText = "You struck while the iron was hot!",
			onResolve = function(state)
				local earnings = math.random(20000, 100000)
				state.Money = (state.Money or 0) + earnings
				if state.AddFeed then
					state:AddFeed(string.format("💰 Brand deals and sponsorships: $%d!", earnings))
				end
			end,
		},
		{
			text = "Stay humble - focus on the craft",
			effects = { Happiness = 8, Smarts = 5 },
			setFlags = { respected_artist = true },
			feedText = "You didn't let it go to your head. Respect increased.",
		},
		{
			text = "Panic - not ready for this",
			effects = { Happiness = -8, Health = -5 },
			setFlags = { anxiety_issues = true },
			feedText = "Fame is overwhelming. You're not handling it well.",
		},
	},
},

-- ══════════════════════════════════════════════════════════════════════════════
-- GOVERNMENT JOB SPECIFIC EVENTS
-- ══════════════════════════════════════════════════════════════════════════════
{
	id = "government_whistleblower",
	title = "Witness Something Wrong",
	emoji = "🏛️",
	text = "You discovered your agency is doing something... questionable. Maybe not illegal, but definitely unethical. Higher-ups are involved.",
	question = "What do you do?",
	minAge = 25, maxAge = 65,
	baseChance = 0.15,
	cooldown = 8,
	requiresJob = true,
	requiresJobCategory = "government",
	blockedByFlags = { in_prison = true },

	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_government",
	tags = { "ethics", "whistleblower", "government" },

	choices = {
		{
			text = "Report through proper channels",
			effects = { Smarts = 3 },
			feedText = "You filed an internal report...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.4 then
					state.Flags = state.Flags or {}
					state.Flags.reform_hero = true
					if state.AddFeed then
						state:AddFeed("✅ Your report led to reforms. You're a quiet hero.")
					end
				else
					if state.AddFeed then
						state:AddFeed("📝 Report filed. Nothing happened. Bureaucracy.")
					end
				end
			end,
		},
		{
			text = "Go to the press",
			effects = {},
			setFlags = { whistleblower = true },
			feedText = "You became a whistleblower...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.3 then
					if state.ModifyStat then
						state:ModifyStat("Happiness", 15)
					end
					if state.AddFeed then
						state:AddFeed("📰 You're a national hero! The truth came out!")
					end
				else
					state.CurrentJob = nil
					if state.AddFeed then
						state:AddFeed("🔥 Fired. Blacklisted. Nobody will hire you now.")
					end
				end
			end,
		},
		{
			text = "Look the other way",
			effects = { Happiness = -8 },
			feedText = "You said nothing. The guilt eats at you.",
		},
	},
},
{
	id = "government_promotion_politics",
	title = "Political Promotion",
	emoji = "🏛️",
	text = "A senior position opened up. You're qualified. But so is someone connected to the mayor's office. Politics vs. merit.",
	question = "How do you handle it?",
	minAge = 30, maxAge = 60,
	baseChance = 0.25,
	cooldown = 4,
	requiresJob = true,
	requiresJobCategory = "government",
	blockedByFlags = { in_prison = true },

	-- META
	stage = STAGE,
	ageBand = "working_age",
	category = "career_government",
	tags = { "promotion", "politics", "government" },

	choices = {
		{
			text = "Apply based on merit alone",
			effects = { Smarts = 3 },
			feedText = "You let your work speak for itself...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.4 then
					local raise = math.random(5000, 15000)
					state.Money = (state.Money or 0) + raise
					if state.CurrentJob then
						state.CurrentJob.salary = (state.CurrentJob.salary or 50000) + raise
					end
					if state.AddFeed then
						state:AddFeed("🎉 You got the promotion! Merit won!")
					end
				else
					if state.AddFeed then
						state:AddFeed("😤 The connected person got it. Politics wins again.")
					end
				end
			end,
		},
		{
			text = "Network and play the game",
			effects = { Smarts = 2, Happiness = -3 },
			feedText = "You did some schmoozing...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.6 then
					local raise = math.random(5000, 15000)
					state.Money = (state.Money or 0) + raise
					if state.CurrentJob then
						state.CurrentJob.salary = (state.CurrentJob.salary or 50000) + raise
					end
					state.Flags = state.Flags or {}
					state.Flags.political_player = true
					if state.AddFeed then
						state:AddFeed("🎭 You played the game. And WON. Promoted!")
					end
				else
					if state.AddFeed then
						state:AddFeed("🤷 The networking didn't help. Still passed over.")
					end
				end
			end,
		},
	},
},
}

return Career
