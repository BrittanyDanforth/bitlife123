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
		id = "boss_from_hell",
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
		text = "You accomplished something significant at work!",
		question = "What was it?",
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

		choices = {
			{ text = "Landed a big client/deal", effects = { Happiness = 10, Money = 1000, Smarts = 2 }, setFlags = { big_achiever = true }, feedText = "You closed a major deal!" },
			{ text = "Solved a critical problem", effects = { Happiness = 8, Smarts = 5 }, setFlags = { problem_solver = true }, feedText = "You saved the day with your solution!" },
			{ text = "Got recognized by leadership", effects = { Happiness = 10, Money = 500 }, feedText = "The executives noticed your work!" },
			{ text = "Mentored someone successfully", effects = { Happiness = 8, Smarts = 2 }, setFlags = { mentor = true }, feedText = "You helped someone grow in their career!" },
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
		text = "Someone approaches you with a business opportunity.",
		question = "Is it legit?",
		minAge = 22, maxAge = 60,
		baseChance = 0.3,
		cooldown = 4,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "entrepreneurship",
		tags = { "business", "investment", "scam_risk", "money" },
		careerTags = { "business" },

		choices = {
			{ text = "It's a great opportunity! Invest!", effects = { Money = 3000, Happiness = 8 }, setFlags = { investor = true }, feedText = "You took a chance on the opportunity!" },
			{ text = "Do thorough due diligence first", effects = { Smarts = 3, Money = 1000 }, feedText = "You researched carefully before deciding." },
			{ text = "If it sounds too good to be true...", effects = { Happiness = 2, Smarts = 2 }, feedText = "You wisely passed on the 'opportunity.'" },
			{ text = "It's a scam! Report it!", effects = { Smarts = 3 }, feedText = "You recognized and reported the scam." },
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
		text = "It's annual review time. You want a raise.",
		question = "How do you approach the negotiation?",
		minAge = 22, maxAge = 60,
		baseChance = 0.5,
		cooldown = 2,
		requiresJob = true,

		choices = {
			{ text = "Come prepared with market data", effects = { Money = 800, Smarts = 3 }, feedText = "Your research paid off. Nice raise!" },
			{ text = "Ask confidently but wing it", effects = { Money = 400, Happiness = 3 }, feedText = "You got something, not as much as you hoped." },
			{ text = "Accept what they offer", effects = { Money = 200, Happiness = -2 }, feedText = "You took the standard increase." },
			{ text = "Threaten to leave", effects = { Money = 1000, Happiness = -3 }, setFlags = { hardball_negotiator = true }, feedText = "They matched your demands. Tense though." },
			{ text = "Ask for more vacation instead", effects = { Happiness = 6, Health = 3 }, setFlags = { values_time_off = true }, feedText = "More days off is worth more than money!" },
		},
	},
	{
		id = "fired",
		title = "You're Fired!",
		emoji = "📦",
		text = "Your boss called you into the office... and fired you.",
		question = "What happened?",
		minAge = 20, maxAge = 60,
		baseChance = 0.15,
		cooldown = 8,
		requiresJob = true,

		choices = {
			{ text = "Performance issues - saw it coming", effects = { Happiness = -15, Money = -500 }, setFlags = { fired = true, between_jobs = true }, feedText = "You knew it was coming. Still hurts." },
			{ text = "Politics - someone threw you under the bus", effects = { Happiness = -20 }, setFlags = { fired = true, betrayed = true, between_jobs = true }, feedText = "Backstabbed at work. Devastating." },
			{ text = "Company downsizing - not your fault", effects = { Happiness = -10, Money = 2000 }, setFlags = { laid_off = true, between_jobs = true }, feedText = "Severance helps, but still a blow." },
			{ text = "You quit before they could fire you", effects = { Happiness = -5, Money = -200 }, setFlags = { between_jobs = true, quit_before_fired = true }, feedText = "You saw the writing on the wall and quit first." },
		},
		onComplete = function(state)
			-- CRITICAL FIX: Clear both Career and CurrentJob
			-- The system uses CurrentJob for job checks, Career is legacy
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
		title = "Dream Job Offer",
		emoji = "✨",
		text = "You got an offer for your dream job!",
		question = "What's the catch?",
		minAge = 25, maxAge = 55,
		baseChance = 0.2,
		cooldown = 6,
		requiresJob = true,

		choices = {
			{ text = "It's perfect! Take it!", effects = { Happiness = 15, Money = 1000 }, setFlags = { dream_job = true }, feedText = "You got your dream job! Incredible!" },
			{ text = "Great job but requires relocating", effects = { Happiness = 8, Money = 800, Health = -3 }, setFlags = { dream_job = true, relocated = true }, feedText = "Worth the move for this opportunity!" },
			{ text = "Amazing role but less pay", effects = { Happiness = 10, Money = -500 }, setFlags = { dream_job = true }, feedText = "Passion over pay. You're happier." },
			{ text = "Too good to be true - scam", effects = { Happiness = -10 }, feedText = "It was fake. Crushing disappointment." },
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
		id = "office_friendship",
		title = "Work Best Friend",
		emoji = "🤝",
		text = "You've become really close with a coworker.",
		question = "How does this friendship develop?",
		minAge = 20, maxAge = 60,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,

		choices = {
			{ text = "Work BFF - lunch every day", effects = { Happiness = 8 }, setFlags = { has_work_friend = true }, feedText = "Work is so much better with a friend!" },
			{ text = "They become a real life friend too", effects = { Happiness = 10 }, setFlags = { has_best_friend = true }, feedText = "A true friendship beyond work." },
			{ text = "They got promoted - things changed", effects = { Happiness = -5 }, feedText = "The power dynamic ruined the friendship." },
			{ text = "They left the company", effects = { Happiness = -3 }, feedText = "Work feels lonelier now." },
		},
	},
	{
		id = "major_presentation",
		title = "Big Presentation",
		emoji = "📊",
		text = "You have to present to the executive team!",
		question = "How does it go?",
		minAge = 25, maxAge = 60,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,

		choices = {
			{ text = "Nailed it! Standing ovation", effects = { Happiness = 12, Money = 500, Smarts = 3 }, setFlags = { great_presenter = true }, feedText = "You killed that presentation!" },
			{ text = "Solid performance, good feedback", effects = { Happiness = 5, Smarts = 2 }, feedText = "You did well. Not perfect but strong." },
			{ text = "Froze up - disaster", effects = { Happiness = -10, Smarts = -2 }, setFlags = { presentation_trauma = true }, feedText = "Total failure. Embarrassing." },
			{ text = "Technical difficulties saved you", effects = { Happiness = 3 }, feedText = "The projector broke - presentation rescheduled!" },
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
		text = "It's annual performance review time.",
		question = "What did your review say?",
		minAge = 20, maxAge = 60,
		baseChance = 0.6,
		cooldown = 2,
		requiresJob = true,

		choices = {
			{ text = "Exceeds expectations!", effects = { Happiness = 10, Money = 800, Smarts = 2 }, setFlags = { top_performer = true }, feedText = "Amazing review! Raise incoming!" },
			{ text = "Meets expectations", effects = { Happiness = 3, Money = 200 }, feedText = "Solid but not standout." },
			{ text = "Needs improvement", effects = { Happiness = -8 }, setFlags = { on_pip = true }, feedText = "You're on a performance improvement plan now." },
			{ text = "Blindsided by negative feedback", effects = { Happiness = -12, Smarts = -2 }, feedText = "The criticism came out of nowhere. Devastating." },
		},
	},
}

return Career
