--[[
    Career Events
    All events here REQUIRE the player to have a job (requiresJob = true)
]]

local Career = {}

local RANDOM = Random.new()

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
		text = "A promotion opportunity has opened up at work. You've been putting in the hours and your performance reviews have been strong. This could be your chance!",
		question = "Do you go for it?",
		minAge = 20, maxAge = 60,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		-- Only trigger if player has worked hard
		customValidation = function(state)
			if not state.CareerInfo then return false end
			local promotionProgress = state.CareerInfo.promotionProgress or 0
			local performance = state.CareerInfo.performance or 0
			return promotionProgress >= 70 and performance >= 65
		end,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_growth",
		tags = { "job", "promotion", "money", "advancement" },
		careerTags = { "management" },

		choices = {
			{ 
				text = "Apply and compete hard", 
				effects = { Smarts = 2, Health = -2 }, 
				setFlags = { sought_promotion = true }, 
				feedText = "You threw your hat in the ring! You'll need to prove yourself in interviews and assessments.",
				onResolve = function(state)
					-- Increase promotion progress based on how hard you've worked
					if state.CareerInfo then
						local currentProgress = state.CareerInfo.promotionProgress or 0
						if currentProgress >= 80 then
							-- High chance of success if you've worked hard enough
							if state.CareerInfo.performance and state.CareerInfo.performance >= 75 then
								state.CareerInfo.promotionProgress = 100 -- Guaranteed promotion
								if state.AddFeed then
									state:AddFeed("Your hard work paid off! You got the promotion!")
								end
							else
								state.CareerInfo.promotionProgress = math.min(100, currentProgress + 15)
							end
						else
							state.CareerInfo.promotionProgress = math.min(100, currentProgress + 10)
						end
					end
				end,
			},
			{ 
				text = "Apply casually", 
				effects = { }, 
				feedText = "You applied but kept expectations low. Without strong preparation, your chances are slim.",
				onResolve = function(state)
					if state.CareerInfo then
						state.CareerInfo.promotionProgress = math.min(100, (state.CareerInfo.promotionProgress or 0) + 5)
					end
				end,
			},
			{ 
				text = "Not interested", 
				effects = { Happiness = 2 }, 
				feedText = "You're happy where you are. Stability over advancement.",
			},
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
		text = "After months of hard work and dedication, you accomplished something significant at work! Your efforts didn't go unnoticed.",
		question = "What was it?",
		minAge = 20, maxAge = 65,
		baseChance = 0.3,
		cooldown = 3,
		requiresJob = true,
		requiresStats = { Smarts = { min = 50 } },
		-- Only trigger if player has been performing well
		customValidation = function(state)
			if not state.CareerInfo then return false end
			local performance = state.CareerInfo.performance or 0
			local yearsAtJob = state.CareerInfo.yearsAtJob or 0
			return performance >= 60 and yearsAtJob >= 0.5 -- At least 6 months at job
		end,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_success",
		tags = { "achievement", "recognition", "job" },
		careerTags = { "leadership" },

		choices = {
			{ 
				text = "Landed a big client/deal", 
				effects = { Happiness = 10, Money = 1000, Smarts = 2 }, 
				setFlags = { big_achiever = true }, 
				feedText = "You closed a major deal! Your networking and persistence paid off.",
				onResolve = function(state)
					if state.CareerInfo then
						state.CareerInfo.performance = math.min(100, (state.CareerInfo.performance or 60) + 15)
						state.CareerInfo.promotionProgress = math.min(100, (state.CareerInfo.promotionProgress or 0) + 20)
					end
				end,
			},
			{ 
				text = "Solved a critical problem", 
				effects = { Happiness = 8, Smarts = 5 }, 
				setFlags = { problem_solver = true }, 
				feedText = "You saved the day with your solution! Your analytical skills impressed everyone.",
				onResolve = function(state)
					if state.CareerInfo then
						state.CareerInfo.performance = math.min(100, (state.CareerInfo.performance or 60) + 12)
						state.CareerInfo.promotionProgress = math.min(100, (state.CareerInfo.promotionProgress or 0) + 15)
					end
				end,
			},
			{ 
				text = "Got recognized by leadership", 
				effects = { Happiness = 10, Money = 500 }, 
				feedText = "The executives noticed your work! Your consistent performance earned recognition.",
				onResolve = function(state)
					if state.CareerInfo then
						state.CareerInfo.performance = math.min(100, (state.CareerInfo.performance or 60) + 10)
						state.CareerInfo.promotionProgress = math.min(100, (state.CareerInfo.promotionProgress or 0) + 12)
					end
				end,
			},
			{ 
				text = "Mentored someone successfully", 
				effects = { Happiness = 8, Smarts = 2 }, 
				setFlags = { mentor = true }, 
				feedText = "You helped someone grow in their career! Leadership potential recognized.",
				onResolve = function(state)
					if state.CareerInfo then
						state.CareerInfo.performance = math.min(100, (state.CareerInfo.performance or 60) + 8)
						state.CareerInfo.promotionProgress = math.min(100, (state.CareerInfo.promotionProgress or 0) + 10)
					end
				end,
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
		text = "Someone approaches you with a business opportunity. They claim it's a 'sure thing' and want you to invest. Something feels off, but they're very persuasive.",
		question = "What do you do?",
		minAge = 22, maxAge = 60,
		baseChance = 0.3,
		cooldown = 4,
		-- Only trigger if player has some money to invest
		customValidation = function(state)
			local money = state.Money or 0
			return money >= 2000 -- Need at least $2000 to be a target
		end,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "entrepreneurship",
		tags = { "business", "investment", "scam_risk", "money" },
		careerTags = { "business" },

		choices = {
			{ 
				text = "Invest without checking", 
				effects = { Happiness = -5 }, 
				setFlags = { gullible = true },
				feedText = "You invested without checking...",
				onResolve = function(state)
					local investment = math.min(3000, math.floor((state.Money or 0) * 0.3)) -- 30% of money or max 3000
					local roll = RANDOM:NextNumber()
					
					if roll < 0.15 then -- 15% chance it's legit
						local returnAmount = math.floor(investment * 1.5)
						state.Money = (state.Money or 0) - investment + returnAmount
						if state.AddFeed then
							state:AddFeed("Lucky! The investment paid off! You got back $" .. returnAmount .. "!")
						end
						state.Flags = state.Flags or {}
						state.Flags.investor = true
					else -- 85% chance it's a scam
						state.Money = math.max(0, (state.Money or 0) - investment)
						if state.AddFeed then
							state:AddFeed("It was a scam! You lost $" .. investment .. ". Always do your research!")
						end
					end
				end,
			},
			{ 
				text = "Do thorough due diligence first", 
				effects = { Smarts = 3 }, 
				setFlags = { careful_investor = true },
				feedText = "You researched carefully...",
				onResolve = function(state)
					local roll = RANDOM:NextNumber()
					if roll < 0.3 then -- 30% chance it's legit after research
						local investment = math.min(2000, math.floor((state.Money or 0) * 0.2))
						local returnAmount = math.floor(investment * 1.3)
						state.Money = (state.Money or 0) - investment + returnAmount
						if state.AddFeed then
							state:AddFeed("Good call! After research, you invested wisely and made $" .. (returnAmount - investment) .. " profit!")
						end
						state.Flags = state.Flags or {}
						state.Flags.investor = true
					else
						if state.AddFeed then
							state:AddFeed("Your research revealed it was a scam. You avoided losing money!")
						end
					end
				end,
			},
			{ 
				text = "If it sounds too good to be true...", 
				effects = { Happiness = 2, Smarts = 2 }, 
				setFlags = { wise = true },
				feedText = "You wisely passed on the 'opportunity.' Your gut was right - it was too good to be true.",
			},
			{ 
				text = "It's a scam! Report it!", 
				effects = { Smarts = 3, Happiness = 3 }, 
				setFlags = { vigilant = true },
				feedText = "You recognized and reported the scam. Authorities thanked you for helping prevent others from being victimized.",
			},
		},
	},
	{
		id = "side_business",
		title = "Side Business Idea",
		emoji = "💡",
		text = "You've been working on a side business in your spare time. It's been growing slowly but steadily. You're starting to see real potential.",
		question = "What's next?",
		minAge = 25, maxAge = 55,
		baseChance = 0.3,
		cooldown = 4,
		requiresFlags = { entrepreneur = true },
		-- Only trigger if player has been working on it (has entrepreneur flag for a while)
		customValidation = function(state)
			-- Check if they have enough money/savings to make business decisions
			local money = state.Money or 0
			return money >= 1000
		end,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "entrepreneurship",
		tags = { "business", "side_hustle", "growth" },
		careerTags = { "business" },

		choices = {
			{ 
				text = "Go full-time on it", 
				effects = { Happiness = 10 }, 
				setFlags = { full_time_entrepreneur = true }, 
				feedText = "You quit your job to focus on your business! Risky but exciting!",
				onResolve = function(state)
					-- Realistic outcome - might succeed or fail
					local roll = RANDOM:NextNumber()
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local successChance = math.min(0.7, 0.4 + (smarts / 200)) -- Smarter = better chance
					
					if roll < successChance then
						-- Success - business grows
						local income = math.floor((state.Money or 0) * 0.1) + 2000
						state.Money = (state.Money or 0) + income
						if state.AddFeed then
							state:AddFeed("Your business took off! You're making $" .. income .. " per month!")
						end
					else
						-- Struggling - need to work harder
						if state.AddFeed then
							state:AddFeed("Going full-time is harder than expected. You're struggling but determined to make it work.")
						end
					end
				end,
			},
			{ 
				text = "Keep it as a side income", 
				effects = { Happiness = 5, Health = -2 }, 
				setFlags = { side_hustler = true },
				feedText = "Extra income is nice! You're balancing work and your side business.",
				onResolve = function(state)
					-- Steady side income
					local sideIncome = math.floor((state.Money or 0) * 0.05) + 500
					state.Money = (state.Money or 0) + sideIncome
					if state.AddFeed then
						state:AddFeed("Your side business brings in $" .. sideIncome .. " this month. Steady progress!")
					end
				end,
			},
			{ 
				text = "Sell it", 
				effects = { Happiness = 5 }, 
				setFlags = { sold_business = true },
				feedText = "You're considering selling...",
				onResolve = function(state)
					-- Value depends on how successful it was
					local baseValue = 3000
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local salePrice = baseValue + math.floor(smarts * 20) -- Smarter = better business = higher sale
					state.Money = (state.Money or 0) + salePrice
					if state.AddFeed then
						state:AddFeed("You sold your side business for $" .. salePrice .. "! A nice profit for your efforts.")
					end
				end,
			},
			{ 
				text = "Find investors", 
				effects = { Smarts = 2 }, 
				setFlags = { has_investors = true },
				feedText = "You're pitching to investors...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = RANDOM:NextNumber()
					local pitchSuccess = 0.3 + (smarts / 200) -- Better pitch if smarter
					
					if roll < pitchSuccess then
						local investment = 5000 + math.floor(smarts * 30)
						state.Money = (state.Money or 0) + investment
						if state.AddFeed then
							state:AddFeed("Investors loved your pitch! You secured $" .. investment .. " in funding!")
						end
					else
						if state.AddFeed then
							state:AddFeed("Investors weren't convinced. You'll need to refine your pitch and try again.")
						end
					end
				end,
			},
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
}

return Career
