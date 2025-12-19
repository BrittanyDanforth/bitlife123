--[[
    Career Events
    All events here REQUIRE the player to have a job (requiresJob = true)
]]

local Career = {}

local STAGE = "adult" -- working-life events

-- ════════════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: Helper function to check if player is in an entertainment/celebrity career
-- Entertainment careers (influencers, streamers, rappers, athletes, actors) have their OWN
-- dedicated event files and should NOT see generic workplace events like "office drama",
-- "promotion opportunity", "layoff threat", etc.
-- ════════════════════════════════════════════════════════════════════════════════════
local function isEntertainmentCareer(state)
	if not state.CurrentJob then return false end
	local jobId = (state.CurrentJob.id or ""):lower()
	local jobName = (state.CurrentJob.name or ""):lower()
	local jobCat = (state.CurrentJob.category or ""):lower()

	-- CRITICAL FIX: Check for isFameCareer flag on job FIRST (most reliable)
	if state.CurrentJob.isFameCareer then
		return true
	end

	-- Check job categories that are entertainment-based
	if jobCat == "entertainment" or jobCat == "celebrity" or jobCat == "fame" or 
	   jobCat == "sports" or jobCat == "music" or jobCat == "acting" or 
	   jobCat == "racing" or jobCat == "gaming" or jobCat == "hacker" then
		return true
	end

	-- Check specific entertainment job IDs/names
	local entertainmentKeywords = {
		"influencer", "streamer", "youtuber", "content_creator", "tiktoker",
		"actor", "actress", "movie_star", "celebrity", "model", "supermodel",
		"rapper", "musician", "singer", "dj", "producer_music", "artist",
		"athlete", "player", "football", "basketball", "baseball", "soccer", "mma", "boxer",
		"host", "anchor", "presenter", "comedian", "performer", "entertainer",
		"racer", "f1_driver", "racing", "gamer", "esports", "pro_gamer"
	}

	for _, keyword in ipairs(entertainmentKeywords) do
		if jobId:find(keyword) or jobName:find(keyword) then
			return true
		end
	end

	-- Check flags that indicate entertainment career
	if state.Flags then
		if state.Flags.isInfluencer or state.Flags.isStreamer or state.Flags.isRapper or
		   state.Flags.isAthlete or state.Flags.isActor or state.Flags.isCelebrity or
		   state.Flags.rapper or state.Flags.content_creator or state.Flags.streamer or
		   state.Flags.signed_athlete or state.Flags.signed_artist or state.Flags.pro_racer or
		   state.Flags.f1_driver or state.Flags.pro_gamer then
			return true
		end
	end

	-- Check FameState for career paths
	if state.FameState then
		local careerPath = (state.FameState.careerPath or ""):lower()
		if careerPath == "influencer" or careerPath == "streamer" or careerPath == "rapper" or
		   careerPath == "youtuber" or careerPath == "athlete" or careerPath == "actor" or
		   careerPath == "musician" then
			return true
		end
	end

	return false
end

-- CRITICAL FIX: Helper to check if player has a formal workplace job
-- Used for events like "office drama", "promotion opportunity", "layoff threat"
local function hasFormalWorkplaceJob(state)
	if not state.CurrentJob then return false end
	-- Block for entertainment careers - they have their own event files
	if isEntertainmentCareer(state) then return false end
	-- Block for informal/illegal careers
	if state.Flags then
		if state.Flags.street_hustler or state.Flags.dealer or state.Flags.criminal_career or
		   state.Flags.supplier or state.Flags.in_mob or state.Flags.mafia_member then
			return false
		end
	end
	return true
end

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
		-- CRITICAL FIX: Only for formal workplace jobs
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
			freelancer = true,
			self_employed = true,
		},
		-- CRITICAL FIX: Block entertainment careers - influencers/athletes don't have "coworkers taking credit"
		eligibility = hasFormalWorkplaceJob,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_workplace",
		tags = { "job", "conflict", "coworker", "office_politics", "formal_job" },

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
		-- CRITICAL FIX: Only for formal jobs with promotion structures
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
			self_employed = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they have their own promotion events
		eligibility = hasFormalWorkplaceJob,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_growth",
		tags = { "job", "promotion", "money", "advancement", "formal_job" },
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
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Only for formal company jobs
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
			self_employed = true,
			freelancer = true,
		},
		-- CRITICAL FIX: Block entertainment careers - influencers/athletes don't get "laid off"
		eligibility = hasFormalWorkplaceJob,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_risk",
		tags = { "job", "layoffs", "risk", "stress", "formal_job" },

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
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Only show for FORMAL jobs with actual managers/HR
		-- Street hustlers, criminals, freelancers don't have "managers"
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
			freelancer = true,
			self_employed = true,
			entrepreneur = true,
			full_time_entrepreneur = true,
		},
		-- Only triggers for formal workplace categories
		eligibility = function(state)
			if not state.CurrentJob then return false end
			local jobCat = state.CurrentJob.category or ""
			local formalCategories = {
				["office"] = true, ["tech"] = true, ["medical"] = true,
				["finance"] = true, ["education"] = true, ["government"] = true,
				["service"] = true, ["retail"] = true, ["trades"] = true,
				["corporate"] = true, ["management"] = true, ["legal"] = true,
			}
			-- Block for illegal/informal job categories
			local informalCategories = {
				["crime"] = true, ["illegal"] = true, ["street"] = true,
				["underground"] = true, ["hustler"] = true, ["criminal"] = true,
			}
			if informalCategories[jobCat:lower()] then
				return false, "Informal jobs don't have managers"
			end
			-- Allow if job has a formal category OR if no category specified (assume formal)
			return true
		end,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_workplace",
		tags = { "job", "manager", "stress", "conflict", "formal_job" },

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
		baseChance = 0.55,
		cooldown = 3,
		requiresJob = true,
		requiresStats = { Smarts = { min = 50 } },
		-- CRITICAL FIX: Block entertainment careers - they have their own achievement events
		eligibility = hasFormalWorkplaceJob,

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
		-- CRITICAL FIX: Only for formal corporate jobs
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they travel differently (tours, shoots)
		eligibility = hasFormalWorkplaceJob,

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_travel",
		tags = { "job", "travel", "clients", "formal_job" },

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
		cooldown = 2,
		requiresJob = true,
		blockedByFlags = { in_prison = true, incarcerated = true },
		-- CRITICAL FIX: Block entertainment careers - they have their own career progressions
		eligibility = hasFormalWorkplaceJob,

		-- META
		stage = STAGE,
		ageBand = "adult_midlife",
		category = "career_decision",
		tags = { "job", "decision", "pivot" },
		careerTags = { "career_general" },

		choices = {
			{ text = "Push for a promotion", effects = { Smarts = 2, Money = 500, Happiness = 5 }, feedText = "You went for the promotion!" },
			{ text = "Change companies for better pay", effects = { Money = 1000, Happiness = 3 }, setFlags = { job_hopper = true }, feedText = "You switched jobs for a raise!" },
			{ 
				text = "Pivot to a new career entirely", 
				effects = { Smarts = 5, Happiness = 5 }, 
				setFlags = { career_changer = true }, 
				feedText = "Pivoting to a new career...",
				-- CRITICAL FIX: Money validation for $1000 career change costs
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 1000 then
						state.Money = money - 1000
						if state.AddFeed then
							state:AddFeed("🛤️ You're starting over in a new field! Invested $1000 in training!")
						end
					elseif money >= 500 then
						state.Money = money - 500
						if state.ModifyStat then state:ModifyStat("Smarts", -1) end
						if state.AddFeed then
							state:AddFeed("🛤️ Budget career pivot! Self-teaching with online courses.")
						end
					else
						if state.ModifyStat then state:ModifyStat("Smarts", -2) end
						if state.AddFeed then
							state:AddFeed("🛤️ Can't afford training. Starting from scratch with just determination!")
						end
					end
				end,
			},
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
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		requiresJobCategory = "tech",
		blockedByFlags = { in_prison = true, incarcerated = true },

		-- META
		stage = STAGE,
		ageBand = "working_age",
		category = "career_tech",
		tags = { "tech", "innovation", "product", "startup" },
		careerTags = { "tech", "startup" },

		choices = {
			{ text = "Pitch it to your company", effects = { Happiness = 8, Money = 1000, Smarts = 3 }, feedText = "You pitched your big idea!" },
			{ 
				text = "Start your own company with it", 
				effects = { Happiness = 10 }, 
				setFlags = { entrepreneur = true, startup_founder = true }, 
				feedText = "Starting your own company...",
				-- CRITICAL FIX: Money validation for $3000 startup costs
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 3000 then
						state.Money = money - 3000
						if state.AddFeed then
							state:AddFeed("💡 You founded your own tech startup! $3000 invested to get started!")
						end
					elseif money >= 1000 then
						state.Money = money - 1000
						if state.ModifyStat then state:ModifyStat("Happiness", -3) end
						if state.AddFeed then
							state:AddFeed("💡 Bootstrapping a lean startup! Working from your garage with $1000.")
						end
					elseif money >= 200 then
						state.Money = money - 200
						if state.ModifyStat then state:ModifyStat("Happiness", -5) end
						if state.AddFeed then
							state:AddFeed("💡 Micro-startup! Just $200 for domain and hosting. Living the dream... barely.")
						end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then
							state:AddFeed("💡 Can't afford startup costs. Keeping it as a side project for now.")
						end
						state.Flags = state.Flags or {}
						state.Flags.startup_founder = nil
						state.Flags.side_hustler = true
					end
				end,
			},
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
		baseChance = 0.55,
		cooldown = 2,
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
		baseChance = 0.55,
		cooldown = 2,
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
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		requiresStats = { Smarts = { min = 70 } },
		-- CRITICAL FIX: Block entertainment careers - they have their own awards
		eligibility = hasFormalWorkplaceJob,

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
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Only for formal office jobs
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
		},
		-- CRITICAL FIX: Block entertainment careers - influencers don't get "remote work options"
		eligibility = hasFormalWorkplaceJob,

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
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Only for formal workplace jobs
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they don't have "toxic workplace" in this sense
		eligibility = hasFormalWorkplaceJob,

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
		-- CRITICAL FIX: Only for formal jobs with salaries and reviews
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
			self_employed = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they don't have "annual reviews"
		eligibility = hasFormalWorkplaceJob,

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
		baseChance = 0.4,
		cooldown = 3,
		-- CRITICAL FIX #8: Added "fired" category for red event card
		category = "fired",
		requiresJob = true,
		-- CRITICAL FIX: Only for formal jobs - street hustlers don't get "fired"
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
			self_employed = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they don't get "fired" in this way
		eligibility = hasFormalWorkplaceJob,

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
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Block entertainment careers - they don't get recruited this way
		eligibility = hasFormalWorkplaceJob,
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
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		requiresSingle = true,
		blockedByFlags = { married = true, in_prison = true, incarcerated = true },
		-- CRITICAL FIX: Block entertainment careers - they don't have "coworkers" in this way
		eligibility = hasFormalWorkplaceJob,

		choices = {
			{ 
				text = "Pursue it - love conquers all", 
				effects = { Happiness = 10 }, 
				setFlags = { office_romance = true, has_partner = true, dating = true }, 
				feedText = "You took a chance on love at work!",
				-- CRITICAL FIX: Actually create the partner object!
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local isMale = math.random() > 0.5
					local names = isMale 
						and {"Brian", "Kevin", "Scott", "Greg", "Craig", "Derek", "Todd", "Chad", "Brett", "Lance"}
						or {"Heather", "Dana", "Kristen", "Jen", "Monica", "Paula", "Stacy", "Allison", "Brittany", "Shannon"}
					local partnerName = names[math.random(1, #names)]
					state.Relationships.partner = {
						id = "partner",
						name = partnerName,
						type = "romantic",
						role = isMale and "Boyfriend" or "Girlfriend",
						relationship = 70,
						age = (state.Age or 30) + math.random(-5, 5),
						gender = isMale and "male" or "female",
						alive = true,
						metThrough = "work",
						isCoworker = true,
					}
					if state.AddFeed then
						state:AddFeed(string.format("💕 You started dating %s from work!", partnerName))
					end
				end,
			},
			{ text = "Keep it strictly professional", effects = { Happiness = -3, Smarts = 2 }, feedText = "You kept boundaries. Smart but hard." },
			{ 
				text = "Transfer departments first", 
				effects = { Happiness = 8 }, 
				setFlags = { has_partner = true, dating = true }, 
				feedText = "You transferred, then started dating!",
				-- CRITICAL FIX: Actually create the partner object!
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local isMale = math.random() > 0.5
					local names = isMale 
						and {"Brian", "Kevin", "Scott", "Greg", "Craig", "Derek", "Todd", "Chad", "Brett", "Lance"}
						or {"Heather", "Dana", "Kristen", "Jen", "Monica", "Paula", "Stacy", "Allison", "Brittany", "Shannon"}
					local partnerName = names[math.random(1, #names)]
					state.Relationships.partner = {
						id = "partner",
						name = partnerName,
						type = "romantic",
						role = isMale and "Boyfriend" or "Girlfriend",
						relationship = 65,
						age = (state.Age or 30) + math.random(-5, 5),
						gender = isMale and "male" or "female",
						alive = true,
						metThrough = "work",
					}
					if state.AddFeed then
						state:AddFeed(string.format("💕 After transferring, you started dating %s!", partnerName))
					end
				end,
			},
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
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		requiresStats = { Health = { max = 40 } },
		blockedByFlags = { in_prison = true, incarcerated = true },
		-- CRITICAL FIX: Block entertainment careers - they have different burnout scenarios
		eligibility = hasFormalWorkplaceJob,

		choices = {
			{ 
				text = "Take a medical leave", 
				effects = { Health = 15, Happiness = 10 }, 
				setFlags = { took_leave = true }, 
				feedText = "Taking medical leave...",
				-- CRITICAL FIX: Money validation for $1000 leave expenses
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 1000 then
						state.Money = money - 1000
						if state.AddFeed then
							state:AddFeed("🔥 You took paid leave. The break is desperately needed.")
						end
					elseif money >= 300 then
						state.Money = money - 300
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then
							state:AddFeed("🔥 Unpaid leave - tight budget but mental health is priceless.")
						end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -4) end
						if state.AddFeed then
							state:AddFeed("🔥 Can't afford time off. Taking sick days and resting at home.")
						end
					end
				end,
			},
			{ text = "Push through - can't afford to stop", effects = { Health = -15, Happiness = -10 }, setFlags = { severe_burnout = true }, feedText = "You're destroying yourself..." },
			{ 
				text = "Quit without a plan", 
				effects = { Happiness = 8, Health = 10 }, 
				setFlags = { between_jobs = true, sabbatical = true }, 
				feedText = "Walking out...",
				-- CRITICAL FIX: Money validation for $2000 quitting buffer
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 2000 then
						state.Money = money - 2000
						if state.AddFeed then
							state:AddFeed("🔥 You snapped and walked out! Freedom! Living on savings.")
						end
					elseif money >= 500 then
						state.Money = money - 500
						if state.ModifyStat then state:ModifyStat("Happiness", -3) end
						if state.AddFeed then
							state:AddFeed("🔥 You quit! Money's tight but your sanity is worth it.")
						end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -6) end
						if state.AddFeed then
							state:AddFeed("🔥 You quit with no savings. Scary but you couldn't take it anymore.")
						end
					end
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
			{ 
				text = "Negotiate reduced hours", 
				effects = { Health = 8, Happiness = 5 }, 
				setFlags = { part_time = true }, 
				feedText = "Negotiating reduced hours...",
				-- CRITICAL FIX: Money validation for $300 salary reduction
				onResolve = function(state)
					local money = state.Money or 0
					-- Reduced hours = reduced pay, represented as expense
					if money >= 300 then
						state.Money = money - 300
						if state.AddFeed then
							state:AddFeed("🔥 Your employer agreed to part-time! Balance restored.")
						end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then
							state:AddFeed("🔥 Reduced hours approved but money will be very tight.")
						end
					end
				end,
			},
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
		-- CRITICAL FIX: Only for formal jobs with coworkers
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
			self_employed = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they don't have "coworkers" in the same way
		eligibility = hasFormalWorkplaceJob,

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
		-- CRITICAL FIX: Only for formal corporate jobs
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they don't present to "executives"
		eligibility = hasFormalWorkplaceJob,
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
		baseChance = 0.55,
		cooldown = 2,
		requiresJob = true,
		-- CRITICAL FIX: Only for formal corporate jobs with senior leadership
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they have different mentorship
		eligibility = hasFormalWorkplaceJob,

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
		-- CRITICAL FIX: Only for formal jobs with overtime expectations
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
			self_employed = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they don't have "overtime" in this sense
		eligibility = hasFormalWorkplaceJob,

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
		baseChance = 0.455,
		cooldown = 2,
		requiresJob = true,
		blockedByFlags = { in_prison = true, incarcerated = true },
		-- CRITICAL FIX: Block entertainment careers - they don't get recruited by startups
		eligibility = hasFormalWorkplaceJob,

		choices = {
			{ 
				text = "Jump in! High risk, high reward", 
				effects = { Happiness = 10 }, 
				setFlags = { startup_employee = true }, 
				feedText = "Joining the startup...",
				-- CRITICAL FIX: Money validation for $500 transition costs
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 500 then
						state.Money = money - 500
						if state.AddFeed then
							state:AddFeed("🚀 You joined the startup! Took a pay cut but equity could be huge!")
						end
					elseif money >= 100 then
						state.Money = money - 100
						if state.AddFeed then
							state:AddFeed("🚀 Joined the startup! Barely affording the transition but YOLO!")
						end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -3) end
						if state.AddFeed then
							state:AddFeed("🚀 Joined the startup! No savings buffer. Risky move!")
						end
					end
				end,
			},
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
		baseChance = 0.55,
		cooldown = 3,
		requiresJob = true,
		-- CRITICAL FIX: Only for formal jobs with bosses watching
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
			self_employed = true,
		},
		-- CRITICAL FIX: Block entertainment careers - influencers don't have "bosses"
		eligibility = hasFormalWorkplaceJob,

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
		-- CRITICAL FIX: Only for formal jobs with coworkers
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
			self_employed = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they don't have "coworkers leaving"
		eligibility = hasFormalWorkplaceJob,

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
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		-- CRITICAL FIX: Only for formal jobs with HR options
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they have different harassment scenarios
		eligibility = hasFormalWorkplaceJob,

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
		-- CRITICAL FIX: Only for legitimate professional careers
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they go to different events
		eligibility = hasFormalWorkplaceJob,

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
		-- CRITICAL FIX: Only for formal jobs with performance reviews
		blockedByFlags = { 
			in_prison = true, 
			street_hustler = true, 
			dealer = true, 
			criminal_career = true,
			self_employed = true,
			freelancer = true,
		},
		-- CRITICAL FIX: Block entertainment careers - they don't have "performance reviews"
		eligibility = hasFormalWorkplaceJob,

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
	baseChance = 0.455,
	cooldown = 2,
	requiresJob = true,
	-- CRITICAL FIX: Block entertainment careers - they don't get "acquired"
	eligibility = hasFormalWorkplaceJob,
	
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
	baseChance = 0.555,
	cooldown = 2,
	requiresJob = true,
	-- CRITICAL FIX: Block entertainment careers - they don't have "remote work options"
	eligibility = hasFormalWorkplaceJob,
	
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
	baseChance = 0.555,
	cooldown = 2,
	requiresJob = true,
	-- CRITICAL FIX: Block entertainment careers - they ARE the side hustle for many
	eligibility = hasFormalWorkplaceJob,
	
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
	baseChance = 0.55,
	cooldown = 2,
	requiresJob = true,
	requiresStats = { Happiness = { max = 60 } },
	-- CRITICAL FIX: Block entertainment careers - they have different toxic scenarios
	eligibility = hasFormalWorkplaceJob,
	
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
	baseChance = 0.455,
	cooldown = 2,
	requiresJob = true,
	-- CRITICAL FIX: Block entertainment careers - they have different mentorship
	eligibility = hasFormalWorkplaceJob,
	
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
	baseChance = 0.455,
	cooldown = 2,
	requiresJob = true,
	-- CRITICAL FIX: Block entertainment careers - they have different career paths
	eligibility = hasFormalWorkplaceJob,
	
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
	baseChance = 0.55,
	cooldown = 3,
	requiresJob = true,
	-- CRITICAL FIX: Block entertainment careers - they have their own awards
	eligibility = hasFormalWorkplaceJob,
	
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
	baseChance = 0.455,
	cooldown = 2,
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
	baseChance = 0.4,
	cooldown = 3,
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
	baseChance = 0.555,
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
	cooldown = 4,
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
	baseChance = 0.4,
	cooldown = 3,
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
	baseChance = 0.455,
	cooldown = 2,
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

-- ══════════════════════════════════════════════════════════════════════════════
-- ADDITIONAL CAREER EVENTS - EXPANDED VARIETY
-- ══════════════════════════════════════════════════════════════════════════════

-- RETAIL & SERVICE INDUSTRY
{
	id = "retail_holiday_rush",
	title = "Holiday Rush",
	emoji = "🎄",
	text = "The holiday shopping season is here. Work is insane.",
	question = "How do you handle the chaos?",
	minAge = 18, maxAge = 55,
	baseChance = 0.5,
	cooldown = 2,
	requiresJob = true,
	requiresJobCategory = "retail",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_retail",
	tags = { "retail", "holiday", "stress" },
	
	choices = {
		{
			text = "Extra shifts = extra money",
			effects = {},
			feedText = "You worked every shift available...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.60 then
					state.Money = (state.Money or 0) + math.random(500, 1200)
					state:ModifyStat("Health", -5)
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🎄 Exhausted but your bank account is happy!")
				else
					state.Money = (state.Money or 0) + math.random(300, 600)
					state:ModifyStat("Health", -8)
					state:ModifyStat("Happiness", -4)
					state:AddFeed("🎄 Burned out. The money wasn't worth this.")
				end
			end,
		},
		{ text = "Stick to regular hours", effects = { Happiness = 3, Money = 200 }, feedText = "You maintained boundaries. Sanity preserved!" },
		{ text = "Call in sick during peak", effects = { Happiness = 5, Money = -100 }, setFlags = { unreliable_worker = true }, feedText = "You ditched during the rush. Manager is furious." },
	},
},
{
	id = "retail_difficult_customer",
	title = "Customer From Hell",
	emoji = "😤",
	text = "A customer is screaming at you over something that isn't your fault.",
	question = "How do you handle this Karen/Kevin?",
	minAge = 16, maxAge = 55,
	baseChance = 0.6,
	cooldown = 2,
	requiresJob = true,
	requiresJobCategory = "retail",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_retail",
	tags = { "retail", "customer", "conflict" },
	
	-- CRITICAL FIX: Random outcome based on approach
	choices = {
		{
			text = "Kill them with kindness",
			effects = {},
			feedText = "You smiled through the abuse...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.50 then
					state:ModifyStat("Smarts", 2)
					state:ModifyStat("Happiness", 2)
					state:AddFeed("😤 They calmed down eventually. Patience is a virtue.")
				elseif roll < 0.80 then
					state:ModifyStat("Happiness", -3)
					state:AddFeed("😤 They kept yelling. You survived. Barely.")
				else
					state:ModifyStat("Happiness", -6)
					state.Flags = state.Flags or {}
					state.Flags.retail_trauma = true
					state:AddFeed("😤 They demanded your manager. You got written up for THEIR attitude.")
				end
			end,
		},
		{
			text = "Get a manager involved",
			effects = {},
			feedText = "You called for backup...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.60 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("😤 Manager handled it. They were on your side!")
				else
					state:ModifyStat("Happiness", -2)
					state:AddFeed("😤 Manager sided with the customer. Ugh.")
				end
			end,
		},
		{ text = "Snap back at them", effects = { Happiness = 5 }, setFlags = { got_written_up = true }, feedText = "You told them off! Worth it. But you're in trouble now." },
		{ text = "Walk to the back and cry", effects = { Happiness = -5, Health = -2 }, feedText = "Retail breaks everyone eventually." },
	},
},

-- TECH INDUSTRY
{
	id = "tech_crunch_time",
	title = "Crunch Time",
	emoji = "💻",
	text = "Major deadline approaching. The team is working 80-hour weeks.",
	question = "How do you handle the crunch?",
	minAge = 20, maxAge = 50,
	baseChance = 0.5,
	cooldown = 3,
	requiresJob = true,
	requiresJobCategory = "tech",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_tech",
	tags = { "tech", "deadline", "crunch", "stress" },
	
	choices = {
		{
			text = "Push through - this is what we signed up for",
			effects = {},
			feedText = "You pushed through the crunch...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.55 then
					state.Money = (state.Money or 0) + math.random(2000, 5000)
					state:ModifyStat("Smarts", 3)
					state:ModifyStat("Health", -8)
					state:ModifyStat("Happiness", 5)
					state.Flags = state.Flags or {}
					state.Flags.shipped_product = true
					state:AddFeed("💻 Project shipped! Big bonus! But you need a vacation.")
				else
					state:ModifyStat("Health", -10)
					state:ModifyStat("Happiness", -5)
					state:AddFeed("💻 Project shipped but at what cost? You're burnt out.")
				end
			end,
		},
		{ text = "Set boundaries - work smarter not harder", effects = { Health = -3, Smarts = 3 }, setFlags = { work_life_balance = true }, feedText = "You maintained some sanity while contributing." },
		{ text = "This is unsustainable - speak up", effects = { Happiness = 3, Smarts = 2 }, setFlags = { advocate_for_team = true }, feedText = "You raised concerns about sustainable work practices." },
		{ text = "Time to update that resume", effects = { Happiness = 2 }, setFlags = { job_hunting = true }, feedText = "This culture isn't for you. Time to find a better environment." },
	},
},
{
	id = "tech_startup_equity",
	title = "Startup Equity Offer",
	emoji = "🚀",
	text = "A startup offers you equity instead of a higher salary. Could be worth millions... or nothing.",
	question = "Do you take the gamble?",
	minAge = 22, maxAge = 45,
	baseChance = 0.55,
	cooldown = 2,
	requiresJob = true,
	requiresJobCategory = "tech",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_tech",
	tags = { "tech", "startup", "equity", "gamble" },
	
	-- CRITICAL FIX: Random equity outcome - can't choose if startup succeeds!
	choices = {
		{
			text = "Take the equity - bet on the future",
			effects = { Money = -500 }, -- Lower immediate salary
			feedText = "You bet on the startup...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.15 then
					-- Jackpot!
					state.Money = (state.Money or 0) + math.random(50000, 200000)
					state:ModifyStat("Happiness", 20)
					state.Flags = state.Flags or {}
					state.Flags.startup_millionaire = true
					state:AddFeed("🚀 THE STARTUP GOT ACQUIRED! Your equity is worth a fortune!")
				elseif roll < 0.40 then
					-- Modest success
					state.Money = (state.Money or 0) + math.random(10000, 30000)
					state:ModifyStat("Happiness", 10)
					state:AddFeed("🚀 Startup did okay! Your equity has some value!")
				elseif roll < 0.70 then
					-- It's hanging on
					state:ModifyStat("Happiness", -2)
					state:AddFeed("🚀 Startup is struggling. Equity worth unknown. Still waiting.")
				else
					-- Failed
					state:ModifyStat("Happiness", -10)
					state.Flags = state.Flags or {}
					state.Flags.startup_failure = true
					state:AddFeed("🚀 Startup went bust. All that equity is worthless.")
				end
			end,
		},
		{ text = "Take more salary - need stability", effects = { Money = 500, Happiness = 3 }, feedText = "You chose the safer path. Cash is king." },
		{ text = "Negotiate for both", effects = { Smarts = 2 }, feedText = "You pushed for more salary AND some equity. Smart negotiating!" },
	},
},
{
	id = "tech_side_project_success",
	title = "Side Project Blows Up",
	emoji = "📱",
	text = "An app you built in your spare time is suddenly getting traction!",
	question = "What do you do?",
	minAge = 18, maxAge = 50,
	baseChance = 0.4,
	cooldown = 2,
	requiresJob = true,
	requiresJobCategory = "tech",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_tech",
	tags = { "tech", "side_project", "success" },
	
	-- CRITICAL FIX: Random outcome based on what player does with it
	choices = {
		{
			text = "Quit job and go all in",
			effects = {},
			feedText = "You bet everything on your project...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.30 then
					state.Money = (state.Money or 0) + math.random(30000, 100000)
					state:ModifyStat("Happiness", 15)
					state.Flags = state.Flags or {}
					state.Flags.successful_founder = true
					state.Flags.self_employed = true
					if state.ClearCareer then state:ClearCareer() end
					state:AddFeed("📱 You're your own boss! The app took off!")
				elseif roll < 0.55 then
					state:ModifyStat("Happiness", 2)
					state.Flags = state.Flags or {}
					state.Flags.indie_developer = true
					state.Flags.self_employed = true
					if state.ClearCareer then state:ClearCareer() end
					state:AddFeed("📱 Making enough to get by. Freedom has a price.")
				else
					state:ModifyStat("Happiness", -12)
					state:ModifyStat("Money", -5000)
					state.Flags = state.Flags or {}
					state.Flags.unemployed = true
					if state.ClearCareer then state:ClearCareer() end
					state:AddFeed("📱 The app flopped after you quit. Should have kept your job.")
				end
			end,
		},
		{
			text = "Keep day job, grow it slowly",
			effects = {},
			feedText = "You're playing it safe while building...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.50 then
					state.Money = (state.Money or 0) + math.random(5000, 20000)
					state:ModifyStat("Happiness", 8)
					state.Flags = state.Flags or {}
					state.Flags.side_income = true
					state:AddFeed("📱 Nice side income! Best of both worlds!")
				else
					state:ModifyStat("Happiness", 3)
					state:AddFeed("📱 Hard to balance both. App growing slowly.")
				end
			end,
		},
		{ text = "Sell the project now", effects = { Money = 10000, Happiness = 8 }, feedText = "Cashed out while it was hot! Nice exit!" },
	},
},

-- MEDICAL FIELD
{
	id = "medical_code_blue",
	title = "Code Blue",
	emoji = "🏥",
	text = "A patient is coding! Life or death moment.",
	question = "You're there. What do you do?",
	minAge = 24, maxAge = 65,
	baseChance = 0.4,
	cooldown = 3,
	requiresJob = true,
	requiresJobCategory = "medical",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_medical",
	tags = { "medical", "emergency", "life_death" },
	
	-- CRITICAL FIX: Random patient outcome - you don't choose if they live
	choices = {
		{
			text = "Jump in and help",
			effects = {},
			feedText = "You rushed to help...",
			onResolve = function(state)
				local smarts = (state.Stats and state.Stats.Smarts) or 50
				local roll = math.random()
				local successChance = 0.50 + (smarts / 200)
				if roll < successChance then
					state:ModifyStat("Happiness", 12)
					state:ModifyStat("Smarts", 3)
					state.Flags = state.Flags or {}
					state.Flags.saved_a_life = true
					state:AddFeed("🏥 Patient stabilized! You helped save a life!")
				elseif roll < successChance + 0.25 then
					state:ModifyStat("Happiness", -5)
					state:ModifyStat("Smarts", 2)
					state:AddFeed("🏥 Patient didn't make it. You did everything you could.")
				else
					state:ModifyStat("Happiness", -10)
					state:ModifyStat("Health", -3)
					state.Flags = state.Flags or {}
					state.Flags.patient_loss_trauma = true
					state:AddFeed("🏥 Lost the patient. This weighs heavy on you.")
				end
			end,
		},
		{
			text = "Call for backup - follow protocol",
			effects = {},
			feedText = "You followed protocol...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.60 then
					state:ModifyStat("Happiness", 6)
					state:ModifyStat("Smarts", 2)
					state:AddFeed("🏥 Team handled it. Patient made it. Protocol works.")
				else
					state:ModifyStat("Happiness", -4)
					state:AddFeed("🏥 Did what you could. Sometimes outcomes aren't good.")
				end
			end,
		},
		{
			text = "Freeze - this is overwhelming",
			effects = { Happiness = -8, Health = -3 },
			setFlags = { medical_anxiety = true },
			feedText = "You froze. Someone else stepped in. You feel terrible.",
		},
	},
},
{
	-- CRITICAL FIX: Renamed from "medical_malpractice_fear" to avoid duplicate ID conflict
	-- CareerEvents has another version
	id = "medical_malpractice_concern",
	title = "Malpractice Concern",
	emoji = "⚖️",
	text = "A patient's family is threatening to sue over a bad outcome that wasn't your fault.",
	question = "How do you handle this?",
	minAge = 26, maxAge = 65,
	baseChance = 0.45,
	cooldown = 2,
	requiresJob = true,
	requiresJobCategory = "medical",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_medical",
	tags = { "medical", "legal", "malpractice" },
	
	choices = {
		{
			text = "Document everything meticulously",
			effects = { Smarts = 3, Happiness = -3 },
			feedText = "You covered your bases with documentation...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.75 then
					state:ModifyStat("Happiness", 5)
					state:AddFeed("⚖️ Documentation saved you. Case dismissed!")
				else
					state.Money = math.max(0, (state.Money or 0) - 5000)
					state:ModifyStat("Happiness", -8)
					state:AddFeed("⚖️ Settled out of court. Insurance covered most but it stings.")
				end
			end,
		},
		{ text = "Let legal handle it", effects = { Happiness = -4 }, feedText = "Out of your hands. The anxiety is the worst part." },
		{ text = "Consider leaving medicine", effects = { Happiness = -10 }, setFlags = { career_doubt = true }, feedText = "Is this worth the stress anymore?" },
	},
},

-- TRADES & MANUAL LABOR
{
	id = "trades_worksite_injury",
	title = "Worksite Accident",
	emoji = "🔧",
	text = "Someone got hurt on the job site today.",
	question = "How do you respond?",
	minAge = 18, maxAge = 60,
	baseChance = 0.55,
	cooldown = 2,
	requiresJob = true,
	requiresJobCategory = "trades",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_trades",
	tags = { "trades", "safety", "injury" },
	
	-- CRITICAL FIX: Random injury severity - player doesn't pick who got hurt or how bad
	choices = {
		{
			text = "Help immediately and call medics",
			effects = {},
			feedText = "You rushed to help...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.25 then
					-- It was you who got hurt
					state:ModifyStat("Health", -15)
					state:ModifyStat("Happiness", -8)
					state.Money = math.max(0, (state.Money or 0) - 500)
					state:AddFeed("🔧 Turns out YOU were the one who got hurt. Out for a while.")
				elseif roll < 0.60 then
					-- Minor injury to coworker
					state:ModifyStat("Happiness", 2)
					state:AddFeed("🔧 Minor injury. Quick first aid. Back to work soon.")
				else
					-- Serious injury to coworker
					state:ModifyStat("Happiness", -5)
					state.Flags = state.Flags or {}
					state.Flags.witnessed_injury = true
					state:AddFeed("🔧 Serious injury. Ambulance came. Sobering day.")
				end
			end,
		},
		{
			text = "Call for safety meeting",
			effects = { Smarts = 2, Happiness = 2 },
			setFlags = { safety_advocate = true },
			feedText = "You pushed for better safety protocols.",
		},
		{
			text = "Document for workers comp",
			effects = { Smarts = 3 },
			feedText = "Making sure everyone's covered properly.",
		},
	},
},
{
	id = "trades_big_contract",
	title = "Big Contract Opportunity",
	emoji = "📋",
	text = "A major client wants to hire you for a big project. Could be very lucrative.",
	question = "Do you take it on?",
	minAge = 22, maxAge = 60,
	baseChance = 0.55,
	cooldown = 2,
	requiresJob = true,
	requiresJobCategory = "trades",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_trades",
	tags = { "trades", "contract", "opportunity" },
	
	-- CRITICAL FIX: Random contract outcome
	choices = {
		{
			text = "Take the contract!",
			effects = {},
			feedText = "You took on the big job...",
			onResolve = function(state)
				local smarts = (state.Stats and state.Stats.Smarts) or 50
				local health = (state.Stats and state.Stats.Health) or 50
				local roll = math.random()
				local successChance = 0.45 + (smarts / 200) + (health / 300)
				if roll < successChance then
					state.Money = (state.Money or 0) + math.random(5000, 15000)
					state:ModifyStat("Happiness", 12)
					state:ModifyStat("Health", -3)
					state.Flags = state.Flags or {}
					state.Flags.reputation_builder = true
					state:AddFeed("📋 Nailed it! Huge payout and more jobs coming in!")
				elseif roll < successChance + 0.25 then
					state.Money = (state.Money or 0) + math.random(2000, 5000)
					state:ModifyStat("Happiness", 3)
					state:ModifyStat("Health", -5)
					state:AddFeed("📋 Finished but some issues. Got paid, learned lessons.")
				else
					state.Money = math.max(0, (state.Money or 0) - 2000)
					state:ModifyStat("Happiness", -10)
					state:ModifyStat("Health", -5)
					state.Flags = state.Flags or {}
					state.Flags.contract_failure = true
					state:AddFeed("📋 Disaster. Project went wrong. Out of pocket to fix it.")
				end
			end,
		},
		{ text = "Pass - too risky", effects = { Happiness = 2 }, feedText = "Played it safe. Stability has value." },
		{ text = "Negotiate better terms first", effects = { Smarts = 2, Money = 1000 }, feedText = "Got better payment terms before starting. Smart!" },
	},
},

-- EDUCATION
{
	id = "education_problem_student",
	title = "Problem Student",
	emoji = "👨‍🏫",
	text = "A student is constantly disruptive and failing. But you sense there's something deeper going on.",
	question = "How do you handle this?",
	minAge = 24, maxAge = 65,
	baseChance = 0.4,
	cooldown = 3,
	requiresJob = true,
	requiresJobCategory = "education",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_education",
	tags = { "education", "student", "challenge" },
	
	-- CRITICAL FIX: Random outcome based on approach
	choices = {
		{
			text = "Take extra time to connect with them",
			effects = {},
			feedText = "You reached out to the struggling student...",
			onResolve = function(state)
				local smarts = (state.Stats and state.Stats.Smarts) or 50
				local roll = math.random()
				local successChance = 0.50 + (smarts / 200)
				if roll < successChance then
					state:ModifyStat("Happiness", 15)
					state:ModifyStat("Smarts", 2)
					state.Flags = state.Flags or {}
					state.Flags.made_a_difference = true
					state:AddFeed("👨‍🏫 Breakthrough! The student turned around. This is why you teach!")
				elseif roll < successChance + 0.30 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("👨‍🏫 Some progress. Small wins matter in education.")
				else
					state:ModifyStat("Happiness", -3)
					state:ModifyStat("Health", -2)
					state:AddFeed("👨‍🏫 Despite your efforts, the student dropped out. Heartbreaking.")
				end
			end,
		},
		{ text = "Follow standard discipline procedures", effects = { Smarts = 1 }, feedText = "By the book. Some situations are beyond your control." },
		{ text = "Refer to counseling services", effects = { Happiness = 2, Smarts = 2 }, feedText = "Got the right professionals involved. Smart approach." },
		{ text = "Focus energy on students who want to learn", effects = { Happiness = 2 }, feedText = "You can't save everyone. Harsh but realistic." },
	},
},
{
	id = "education_parent_confrontation",
	title = "Angry Parent",
	emoji = "😠",
	text = "A parent is furious about their child's grade. They're demanding you change it.",
	question = "How do you respond?",
	minAge = 24, maxAge = 65,
	baseChance = 0.4,
	cooldown = 2,
	requiresJob = true,
	requiresJobCategory = "education",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_education",
	tags = { "education", "parent", "conflict" },
	
	choices = {
		{
			text = "Hold firm - the grade is earned",
			effects = {},
			feedText = "You stood by your assessment...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.60 then
					state:ModifyStat("Happiness", 4)
					state:ModifyStat("Smarts", 2)
					state.Flags = state.Flags or {}
					state.Flags.principled_teacher = true
					state:AddFeed("😠 Parent backed down. Your principal supported you!")
				else
					state:ModifyStat("Happiness", -5)
					state:AddFeed("😠 Parent went to administration. Stressful but you stood your ground.")
				end
			end,
		},
		{ text = "Offer extra credit opportunity", effects = { Happiness = 3 }, feedText = "Diplomatic solution. Everyone saves face." },
		{ text = "Cave and change the grade", effects = { Happiness = -8, Smarts = -2 }, setFlags = { pushover = true }, feedText = "You compromised your integrity. Feels awful." },
		{ text = "Get administration involved", effects = { Happiness = 2 }, feedText = "Let the higher-ups handle it. That's what they're for." },
	},
},

-- FINANCE
{
	id = "finance_ethical_dilemma",
	title = "Ethical Gray Area",
	emoji = "💰",
	text = "Your firm wants you to sell a product that technically isn't illegal, but definitely isn't in clients' best interests.",
	question = "What do you do?",
	minAge = 24, maxAge = 60,
	baseChance = 0.55,
	cooldown = 2,
	requiresJob = true,
	requiresJobCategory = "finance",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_finance",
	tags = { "finance", "ethics", "sales" },
	
	choices = {
		{
			text = "Refuse and put clients first",
			effects = {},
			feedText = "You refused the unethical sales...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.40 then
					state:ModifyStat("Happiness", 10)
					state.Flags = state.Flags or {}
					state.Flags.ethical_finance = true
					state:AddFeed("💰 Management respected your stance. Integrity intact!")
				elseif roll < 0.70 then
					state:ModifyStat("Happiness", 2)
					state:AddFeed("💰 They weren't happy but let it go. For now.")
				else
					state.Money = math.max(0, (state.Money or 0) - 2000)
					state:ModifyStat("Happiness", -5)
					state.Flags = state.Flags or {}
					state.Flags.passed_over = true
					state:AddFeed("💰 Passed over for promotion. Integrity has a cost.")
				end
			end,
		},
		{ text = "Play the game - hit targets", effects = { Money = 3000, Happiness = -5 }, setFlags = { sold_out = true }, feedText = "You made the sales. The bonus was nice. Your soul? Less so." },
		{ text = "Document and report anonymously", effects = { Smarts = 2 }, setFlags = { whistleblower_potential = true }, feedText = "You're building a paper trail. Just in case." },
		{ text = "Find a new firm with better values", effects = { Happiness = 5 }, setFlags = { job_hunting = true }, feedText = "Time to find a place that matches your ethics." },
	},
},

-- CREATIVE/ENTERTAINMENT
{
	id = "creative_big_break",
	title = "Big Break Opportunity",
	emoji = "⭐",
	text = "Someone important noticed your work! This could be your big break.",
	question = "What do you do?",
	minAge = 18, maxAge = 55,
	baseChance = 0.45,
	cooldown = 2,
	requiresJob = true,
	requiresJobCategory = "creative",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_creative",
	tags = { "creative", "opportunity", "fame" },
	
	-- CRITICAL FIX: Random big break outcome
	choices = {
		{
			text = "Go all in - this is the moment!",
			effects = {},
			feedText = "You seized the opportunity...",
			onResolve = function(state)
				local looks = (state.Stats and state.Stats.Looks) or 50
				local smarts = (state.Stats and state.Stats.Smarts) or 50
				local roll = math.random()
				local successChance = 0.30 + (looks / 200) + (smarts / 300)
				if roll < successChance * 0.5 then
					-- Major success
					state.Money = (state.Money or 0) + math.random(20000, 50000)
					state:ModifyStat("Happiness", 20)
					state:ModifyStat("Looks", 3)
					state.Flags = state.Flags or {}
					state.Flags.famous = true
					state.Flags.breakthrough_artist = true
					state:AddFeed("⭐ BREAKTHROUGH! You're getting recognized everywhere!")
				elseif roll < successChance then
					-- Moderate success
					state.Money = (state.Money or 0) + math.random(5000, 15000)
					state:ModifyStat("Happiness", 12)
					state.Flags = state.Flags or {}
					state.Flags.rising_star = true
					state:AddFeed("⭐ The opportunity paid off! Career momentum!")
				elseif roll < 0.75 then
					-- Didn't pan out
					state:ModifyStat("Happiness", -5)
					state:AddFeed("⭐ The 'big break' fizzled. Back to grinding.")
				else
					-- Disaster
					state:ModifyStat("Happiness", -10)
					state.Flags = state.Flags or {}
					state.Flags.reputation_damaged = true
					state:AddFeed("⭐ Bombed hard. Your reputation took a hit.")
				end
			end,
		},
		{ text = "Play it cool - don't seem desperate", effects = { Happiness = 3, Smarts = 2 }, feedText = "You stayed composed. Playing the long game." },
		{ text = "Be authentic - take it or leave it", effects = { Happiness = 5 }, setFlags = { authentic = true }, feedText = "You were yourself. If it works, it works." },
	},
},
{
	id = "creative_creative_block",
	title = "Creative Block",
	emoji = "🎨",
	text = "You've hit a wall. The creativity just isn't flowing.",
	question = "How do you push through?",
	minAge = 18, maxAge = 65,
	baseChance = 0.5,
	cooldown = 2,
	requiresJob = true,
	requiresJobCategory = "creative",
	blockedByFlags = { in_prison = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_creative",
	tags = { "creative", "block", "struggle" },
	
	choices = {
		{
			text = "Force yourself to create anyway",
			effects = {},
			feedText = "You pushed through the block...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.40 then
					state:ModifyStat("Smarts", 3)
					state:ModifyStat("Happiness", 5)
					state:AddFeed("🎨 Breakthrough! Some of your best work came from the struggle!")
				else
					state:ModifyStat("Happiness", -4)
					state:ModifyStat("Health", -2)
					state:AddFeed("🎨 Mediocre output. The block won this round.")
				end
			end,
		},
		{ text = "Take a break and recharge", effects = { Happiness = 4, Health = 3 }, feedText = "Sometimes you need to step away to come back stronger." },
		{ text = "Seek inspiration from others", effects = { Smarts = 2, Happiness = 3 }, feedText = "Consumed art, music, nature. Fresh ideas emerging!" },
		{ text = "Change your environment", effects = { Happiness = 3, Money = -100 }, feedText = "New coffee shop, new ideas. Change of scenery helped!" },
	},
},

-- GENERAL CAREER EVENTS
{
	id = "career_networking_event",
	title = "Networking Event",
	emoji = "🤝",
	text = "There's a big industry networking event. Your boss expects you to attend.",
	question = "How do you approach it?",
	minAge = 22, maxAge = 60,
	baseChance = 0.4,
	cooldown = 3,
	requiresJob = true,
	blockedByFlags = { in_prison = true, street_hustler = true, criminal_career = true },
	-- CRITICAL FIX: Block entertainment careers - they have different networking
	eligibility = hasFormalWorkplaceJob,
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_networking",
	tags = { "networking", "social", "career" },
	
	-- CRITICAL FIX: Random networking outcome
	choices = {
		{
			text = "Work the room confidently",
			effects = {},
			feedText = "You networked like a pro...",
			onResolve = function(state)
				local looks = (state.Stats and state.Stats.Looks) or 50
				local smarts = (state.Stats and state.Stats.Smarts) or 50
				local roll = math.random()
				local successChance = 0.40 + (looks / 200) + (smarts / 300)
				if roll < successChance then
					state:ModifyStat("Happiness", 8)
					state:ModifyStat("Smarts", 2)
					state.Money = (state.Money or 0) + 500
					state.Flags = state.Flags or {}
					state.Flags.strong_network = true
					state:AddFeed("🤝 Made great connections! New opportunities incoming!")
				elseif roll < successChance + 0.30 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🤝 Met some people. Exchanged cards. We'll see.")
				else
					state:ModifyStat("Happiness", -2)
					state:AddFeed("🤝 Awkward conversations. Networking isn't your strength.")
				end
			end,
		},
		{ text = "Stick close to people you know", effects = { Happiness = 2 }, feedText = "Comfort zone intact. Some light networking." },
		{ text = "Leave early - hate these things", effects = { Happiness = 3, Smarts = -1 }, feedText = "You escaped! But missed opportunities." },
		{ text = "Get too drunk at the open bar", effects = { Happiness = 4, Health = -2 }, setFlags = { embarrassed_self = true }, feedText = "You... might have said some things. Monday will be awkward." },
	},
},
{
	id = "career_sabbatical_consideration",
	title = "Sabbatical Offer",
	emoji = "🏖️",
	text = "Your company offers a sabbatical program. You could take 3 months off, unpaid.",
	question = "Do you take it?",
	minAge = 30, maxAge = 55,
	baseChance = 0.45,
	cooldown = 2,
	requiresJob = true,
	blockedByFlags = { in_prison = true, street_hustler = true, criminal_career = true },
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_decision",
	tags = { "sabbatical", "break", "career" },
	
	-- CRITICAL FIX: Check if player can afford sabbatical AND block entertainment careers
	eligibility = function(state)
		if not hasFormalWorkplaceJob(state) then
			return false, "Entertainment careers don't have sabbatical programs"
		end
		local money = state.Money or 0
		if money < 3000 then
			return false, "Can't afford 3 months without income"
		end
		return true
	end,
	
	choices = {
		{
			text = "Take the sabbatical!",
			effects = {},
			feedText = "You took time off to recharge...",
			onResolve = function(state)
				local money = state.Money or 0
				local cost = math.min(5000, money * 0.5)
				state.Money = money - cost
				state:ModifyStat("Happiness", 15)
				state:ModifyStat("Health", 10)
				state.Flags = state.Flags or {}
				state.Flags.took_sabbatical = true
				state.Flags.recharged = true
				state:AddFeed(string.format("🏖️ Best 3 months of your life! Cost $%d but worth every penny.", math.floor(cost)))
			end,
		},
		{ text = "Can't afford to not work", effects = { Happiness = -3 }, feedText = "Financial reality wins. Maybe someday." },
		{ text = "Negotiate for paid sabbatical", effects = { Smarts = 2 }, feedText = "You pushed for paid time. They said they'd consider it." },
	},
},
{
	id = "career_raise_negotiation",
	title = "Raise Negotiation",
	emoji = "💵",
	text = "Review time. You deserve more money. Time to ask for it.",
	question = "How do you approach the negotiation?",
	minAge = 22, maxAge = 60,
	baseChance = 0.4,
	cooldown = 2,
	requiresJob = true,
	blockedByFlags = { in_prison = true, street_hustler = true, criminal_career = true },
	-- CRITICAL FIX: Block entertainment careers - they don't have "review time"
	eligibility = hasFormalWorkplaceJob,
	
	stage = STAGE,
	ageBand = "working_age",
	category = "career_money",
	tags = { "raise", "negotiation", "salary" },
	
	-- CRITICAL FIX: Random raise outcome based on approach
	choices = {
		{
			text = "Come prepared with accomplishments",
			effects = {},
			feedText = "You made your case with data...",
			onResolve = function(state)
				local smarts = (state.Stats and state.Stats.Smarts) or 50
				local roll = math.random()
				local successChance = 0.50 + (smarts / 200)
				if roll < successChance then
					local raise = math.random(2000, 8000)
					state.Money = (state.Money or 0) + raise
					if state.CurrentJob then
						state.CurrentJob.salary = (state.CurrentJob.salary or 40000) + raise
					end
					state:ModifyStat("Happiness", 10)
					state:AddFeed(string.format("💵 GOT THE RAISE! +$%d! Your prep paid off!", raise))
				elseif roll < successChance + 0.25 then
					local raise = math.random(500, 2000)
					state.Money = (state.Money or 0) + raise
					if state.CurrentJob then
						state.CurrentJob.salary = (state.CurrentJob.salary or 40000) + raise
					end
					state:ModifyStat("Happiness", 5)
					state:AddFeed(string.format("💵 Got a partial raise: +$%d. Something is better than nothing.", raise))
				else
					state:ModifyStat("Happiness", -5)
					state:AddFeed("💵 Denied. 'Budget constraints.' Frustrating.")
				end
			end,
		},
		{
			text = "Wing it and hope for the best",
			effects = {},
			feedText = "You asked without much preparation...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.25 then
					local raise = math.random(1000, 4000)
					state.Money = (state.Money or 0) + raise
					if state.CurrentJob then
						state.CurrentJob.salary = (state.CurrentJob.salary or 40000) + raise
					end
					state:ModifyStat("Happiness", 8)
					state:AddFeed(string.format("💵 Lucky! They said yes! +$%d!", raise))
				else
					state:ModifyStat("Happiness", -3)
					state:AddFeed("💵 They asked for justification. You didn't have it. No raise.")
				end
			end,
		},
		{ text = "Accept whatever they offer", effects = { Happiness = -2 }, feedText = "You took what was given. Probably left money on the table." },
		{ text = "Threaten to leave if no raise", effects = {}, feedText = "Risky move...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.30 then
					local raise = math.random(4000, 10000)
					state.Money = (state.Money or 0) + raise
					if state.CurrentJob then
						state.CurrentJob.salary = (state.CurrentJob.salary or 40000) + raise
					end
					state:ModifyStat("Happiness", 8)
					state:AddFeed(string.format("💵 They caved! BIG raise: +$%d!", raise))
				elseif roll < 0.60 then
					state:ModifyStat("Happiness", -5)
					state:AddFeed("💵 They called your bluff. No raise. Awkward now.")
				else
					state.Flags = state.Flags or {}
					state.Flags.on_thin_ice = true
					state:ModifyStat("Happiness", -8)
					state:AddFeed("💵 They told you to go ahead and leave then. Yikes.")
				end
			end,
		},
	},
},

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #322: EXPANDED CAREER PROGRESSION EVENTS
	-- More immersive career events for better gameplay
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "career_mentor_opportunity",
		title = "🎓 Mentorship Offer",
		emoji = "🎓",
		text = "A senior executive has noticed your potential and offers to mentor you. This could accelerate your career.",
		minAge = 22, maxAge = 45,
		baseChance = 0.455,
		cooldown = 2,
		requiresJob = true,
		blockedByFlags = { in_prison = true, street_hustler = true, criminal_career = true },
		-- CRITICAL FIX: Block entertainment careers - they have different mentorship
		eligibility = hasFormalWorkplaceJob,
		stage = STAGE,
		category = "career_growth",
		tags = { "mentor", "growth", "career" },
		choices = {
			{ text = "Accept enthusiastically", effects = { Smarts = 8, Happiness = 5 }, setFlags = { has_mentor = true }, feedText = "You gained a powerful ally in your career!" },
			{ text = "Accept but set boundaries", effects = { Smarts = 5, Happiness = 3 }, setFlags = { has_mentor = true }, feedText = "A balanced mentorship relationship begins." },
			{ text = "Politely decline - prefer independence", effects = { Happiness = 2 }, feedText = "You value forging your own path." },
		},
	},
	{
		id = "career_public_speaking",
		title = "🎤 Speaking Opportunity",
		emoji = "🎤",
		text = "You've been asked to present at the company-wide meeting. Hundreds will be watching!",
		minAge = 23, maxAge = 60,
		baseChance = 0.55,
		cooldown = 3,
		requiresJob = true,
		blockedByFlags = { in_prison = true },
		-- CRITICAL FIX: Block entertainment careers - they have different speaking events
		eligibility = hasFormalWorkplaceJob,
		stage = STAGE,
		category = "career_challenge",
		tags = { "presentation", "public_speaking", "career" },
		choices = {
			{
				text = "Prepare extensively and crush it",
				effects = { Health = -2 },
				feedText = "Showtime...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.40 + (smarts / 200) then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Smarts", 5)
						state.Money = (state.Money or 0) + 2000
						state.Flags = state.Flags or {}
						state.Flags.public_speaker = true
						state:AddFeed("🎤 STANDING OVATION! You're now known as a great presenter!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎤 Solid presentation. Professional and competent.")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("🎤 You froze up. Embarrassing silence. The slide clicker stopped working.")
					end
				end,
			},
			{ text = "Wing it with confidence", effects = { Happiness = 3 }, feedText = "You went with the flow...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.natural_speaker = true
						state:AddFeed("🎤 Natural talent! Everyone was impressed by your off-the-cuff style!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🎤 It showed that you didn't prepare. Awkward.")
					end
				end,
			},
			{ text = "Fake sick and skip it", effects = { Happiness = -3 }, setFlags = { avoids_spotlight = true }, feedText = "You dodged it but missed an opportunity." },
		},
	},
	{
		id = "career_startup_offer",
		title = "🚀 Startup Opportunity",
		emoji = "🚀",
		text = "A friend's startup is taking off and they want you to join as a founding member. It's risky but could be huge!",
		minAge = 22, maxAge = 45,
		baseChance = 0.4,
		cooldown = 3,
		oneTime = true,
		requiresJob = true,
		blockedByFlags = { in_prison = true },
		-- CRITICAL FIX: Block entertainment careers - they don't join startups
		eligibility = hasFormalWorkplaceJob,
		stage = STAGE,
		category = "career_decision",
		tags = { "startup", "risk", "opportunity", "career" },
		choices = {
			{
				text = "Leave everything and join!",
				effects = { Happiness = 10 },
				feedText = "Taking the leap...",
				setFlags = { startup_founder = true },
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.20 then
						state.Money = (state.Money or 0) + 500000
						state:ModifyStat("Happiness", 25)
						state.Flags = state.Flags or {}
						state.Flags.startup_success = true
						state:AddFeed("🚀 THE STARTUP EXPLODED! You're RICH! IPO was a massive success!")
					elseif roll < 0.50 then
						state.Money = (state.Money or 0) + 50000
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🚀 Startup did okay. Made some money and gained great experience.")
					else
						state.Money = (state.Money or 0) - 10000
						state:ModifyStat("Happiness", -15)
						state.Flags = state.Flags or {}
						state.Flags.startup_failed = true
						state:AddFeed("🚀 Startup crashed and burned. Lost money. Back to job hunting.")
					end
				end,
			},
			{ text = "Join as an advisor (keep current job)", effects = { Smarts = 3 }, feedText = "You helped from the sidelines." },
			{ text = "Decline - too risky", effects = { Happiness = 2 }, feedText = "You played it safe." },
		},
	},
	{
		id = "career_office_politics",
		title = "🎭 Office Power Play",
		emoji = "🎭",
		text = "Two executives are in a power struggle. Both are trying to recruit you to their side.",
		minAge = 25, maxAge = 55,
		baseChance = 0.455,
		cooldown = 2,
		requiresJob = true,
		blockedByFlags = { in_prison = true, self_employed = true },
		-- CRITICAL FIX: Block entertainment careers - they don't have executive power struggles
		eligibility = hasFormalWorkplaceJob,
		stage = STAGE,
		category = "career_workplace",
		tags = { "politics", "conflict", "strategy", "career" },
		choices = {
			{
				text = "Side with Executive A (the favorite)",
				effects = {},
				feedText = "You picked a side...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.6 then
						state.Money = (state.Money or 0) + 3000
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🎭 Your side won! Executive A promoted you as thanks!")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.backed_loser = true
						state:AddFeed("🎭 Executive A lost. Now their replacement doesn't trust you.")
					end
				end,
			},
			{
				text = "Side with Executive B (the underdog)",
				effects = {},
				feedText = "You picked the underdog...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state.Money = (state.Money or 0) + 8000
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.kingmaker = true
						state:AddFeed("🎭 Executive B won against the odds! They rewarded your loyalty BIG!")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("🎭 Executive B lost. You backed the wrong horse.")
					end
				end,
			},
			{ text = "Stay neutral - focus on work", effects = { Smarts = 3, Happiness = 3 }, feedText = "You avoided the drama and kept your head down." },
		},
	},
	{
		id = "career_viral_moment",
		title = "📱 Work Goes Viral",
		emoji = "📱",
		text = "Something you did at work got caught on camera and is going viral on social media!",
		minAge = 20, maxAge = 50,
		baseChance = 0.1,
		cooldown = 4,
		requiresJob = true,
		-- CRITICAL FIX: Block entertainment careers - they have their own viral events
		eligibility = hasFormalWorkplaceJob,
		stage = STAGE,
		category = "career_random",
		tags = { "viral", "social_media", "fame", "career" },
		choices = {
			{
				text = "Embrace the attention!",
				effects = { Happiness = 10 },
				feedText = "You leaned into your viral fame...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state.Money = (state.Money or 0) + 5000
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.internet_famous = true
						state:AddFeed("📱 You leveraged the fame! Sponsorship deals, speaking gigs, the works!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📱 The internet turned on you. Comments got mean. Fame is fleeting.")
					end
				end,
			},
			{ text = "Ask for it to be taken down", effects = { Happiness = -3 }, feedText = "You tried to contain it but the internet never forgets." },
			{ text = "Ignore it completely", effects = { Happiness = 2 }, feedText = "You didn't engage and it eventually blew over." },
		},
	},
	{
		id = "career_dream_job_offer",
		title = "✨ Dream Job Offer",
		emoji = "✨",
		text = "A recruiter called with THE job offer - your dream company wants YOU. But it requires relocating.",
		minAge = 25, maxAge = 50,
		baseChance = 0.4,
		cooldown = 3,
		requiresJob = true,
		blockedByFlags = { in_prison = true },
		-- CRITICAL FIX: Block entertainment careers - they don't get recruited this way
		eligibility = hasFormalWorkplaceJob,
		stage = STAGE,
		category = "career_opportunity",
		tags = { "dream_job", "relocation", "opportunity", "career" },
		choices = {
			{
				text = "Accept immediately!",
				effects = { Happiness = 20 },
				feedText = "You're living your dream!",
				setFlags = { dream_job = true },
				onResolve = function(state)
					state.Money = (state.Money or 0) + 15000 -- Signing bonus + relocation
					if state.CurrentJob then
						state.CurrentJob.salary = (state.CurrentJob.salary or 40000) * 1.5
					end
					state:AddFeed("✨ DREAM JOB SECURED! Big salary increase and doing what you love!")
				end,
			},
			{
				text = "Negotiate for remote work option",
				effects = {},
				feedText = "You tried to have it all...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state.Money = (state.Money or 0) + 10000
						state:ModifyStat("Happiness", 18)
						state.Flags = state.Flags or {}
						state.Flags.dream_job = true
						state.Flags.remote_worker = true
						state:AddFeed("✨ They said YES to remote! Dream job without moving!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("✨ They said no to remote. Offer withdrawn. Devastating.")
					end
				end,
			},
			{ text = "Decline - can't leave current life", effects = { Happiness = -10 }, feedText = "You couldn't take the leap. What if..." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- POLITICAL STORY PATH EVENTS
	-- User feedback: "Story paths don't do much" - These events fire for political path
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "political_path_local_politics",
		title = "🏛️ Local Political Opportunity",
		emoji = "🏛️",
		text = "Your interest in politics has caught attention. A local party official notices your potential and invites you to a community organizing event.",
		question = "This could be your first step into politics!",
		minAge = 18, maxAge = 50,
		baseChance = 0.6,
		oneTime = true,
		conditions = { requiresFlags = { pursuing_politics = true } },
		blockedByFlags = { entered_local_politics = true },
		category = "career",
		choices = {
			{ text = "Attend and network 🤝", effects = { Happiness = 10, Smarts = 5 }, setFlags = { entered_local_politics = true, political_connections = true }, feedText = "You made valuable connections in local politics! Your journey begins." },
			{ text = "Volunteer for the campaign 📋", effects = { Happiness = 8, Smarts = 3 }, setFlags = { entered_local_politics = true, campaign_experience = true }, feedText = "You spent months helping with the campaign. You learned a lot about how politics really works." },
			{ text = "Decline - not ready yet", effects = { Happiness = -5 }, feedText = "You passed on the opportunity. Maybe next time." },
		},
	},
	{
		id = "political_path_first_speech",
		title = "📢 Your First Political Speech",
		emoji = "📢",
		text = "You've been invited to speak at a local town hall meeting. This is your chance to share your vision!",
		question = "How do you approach your speech?",
		minAge = 20, maxAge = 55,
		baseChance = 0.55,
		cooldown = 2,
		conditions = { requiresFlags = { pursuing_politics = true, entered_local_politics = true } },
		category = "career",
		choices = {
			{ text = "Passionate and inspiring 🔥", effects = { Happiness = 15 }, setFlags = { political_reputation = true, charismatic_politician = true }, feedText = "The crowd loved it! You got a standing ovation!" },
			{ text = "Calm and policy-focused 📊", effects = { Smarts = 8, Happiness = 5 }, setFlags = { policy_expert = true }, feedText = "You impressed the policy wonks. Respect increased." },
			{ text = "Attack the opposition 👊", effects = { Happiness = 5 }, setFlags = { aggressive_politician = true }, feedText = "Controversial but it got people talking!" },
			{ text = "Wing it - no preparation", effects = { Happiness = -10 }, feedText = "That was rough. You stumbled through and forgot your points." },
		},
	},
	{
		id = "political_path_scandal_rumor",
		title = "📰 Political Scandal Brewing",
		emoji = "📰",
		text = "A rumor about you is spreading in political circles. Someone claims you said something controversial at a private event.",
		question = "How do you handle this potential scandal?",
		minAge = 21, maxAge = 60,
		baseChance = 0.45,
		cooldown = 3,
		conditions = { requiresFlags = { pursuing_politics = true } },
		category = "career",
		choices = {
			{ text = "Get ahead of it - make a statement 📺", effects = { Smarts = 5, Happiness = -3 }, setFlags = { survived_scandal = true }, feedText = "Your quick response controlled the narrative." },
			{ text = "Stay silent - let it blow over 🤐", effects = { Happiness = -5 }, feedText = "The rumors eventually faded but some damage was done." },
			{ text = "Attack the source 🔍", effects = { Happiness = 3 }, setFlags = { political_fighter = true }, feedText = "You went on the offensive. The source backed down." },
			{ text = "Admit and apologize 🙏", effects = { Happiness = 8, Smarts = -3 }, setFlags = { humble_politician = true }, feedText = "Your honesty was refreshing to voters." },
		},
	},
	{
		id = "political_path_campaign_donation",
		title = "💰 Campaign Donation Offer",
		emoji = "💰",
		text = "A wealthy donor offers to fund your political ambitions, but they hint at expecting 'favorable treatment' in return.",
		question = "This money could change everything...",
		minAge = 25, maxAge = 60,
		baseChance = 0.5,
		oneTime = true,
		conditions = { requiresFlags = { pursuing_politics = true, entered_local_politics = true } },
		category = "career",
		choices = {
			{ text = "Accept the donation 💵", effects = { Happiness = 10 }, setFlags = { dirty_politician = true, big_donor_backing = true }, feedText = "The money pours in. Your campaign coffers are full." },
			{ text = "Accept but stay independent 🤝", effects = { Happiness = 5, Smarts = 5 }, setFlags = { pragmatic_politician = true }, feedText = "You took the money but made no promises." },
			{ text = "Refuse - principles first ✊", effects = { Happiness = 15, Smarts = -5 }, setFlags = { ethical_politician = true, grassroots_funded = true }, feedText = "You stayed clean. Your integrity is intact!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRIMINAL STORY PATH EVENTS  
	-- User feedback: "Story paths don't do much" - These events fire for crime path
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "criminal_path_first_job",
		title = "🔫 Your First Criminal Job",
		emoji = "🔫",
		text = "A shady contact approaches you with an opportunity. They need someone to run a 'delivery' across town - no questions asked.",
		question = "This could be your entry into the underworld...",
		minAge = 16, maxAge = 40,
		baseChance = 0.6,
		oneTime = true,
		conditions = { requiresFlags = { pursuing_crime = true } },
		blockedByFlags = { first_criminal_job = true, in_prison = true },
		category = "crime",
		choices = {
			{ text = "Take the job 📦", effects = { Happiness = 5 }, setFlags = { first_criminal_job = true, street_runner = true, criminal_path = true }, feedText = "You completed the delivery. $500 cash, no trace. Easy money." },
			{ text = "Negotiate for more money 💰", effects = { Smarts = 3 }, setFlags = { first_criminal_job = true, negotiator = true }, feedText = "They respected your hustle. You got $800 instead." },
			{ text = "Ask what's in the package 🤔", effects = { Smarts = 5 }, setFlags = { cautious_criminal = true }, feedText = "They laughed and walked away. Wrong question to ask." },
			{ text = "Report it to police 👮", effects = { Happiness = -5 }, setFlags = { snitch = true }, feedText = "You told the cops. Sleep well knowing you did the 'right' thing." },
		},
	},
	{
		id = "criminal_path_crew_recruitment",
		title = "👥 Criminal Crew Offer",
		emoji = "👥",
		text = "A small-time crew is looking for new blood. They've been watching you and think you've got what it takes.",
		question = "Join the crew?",
		minAge = 17, maxAge = 35,
		baseChance = 0.55,
		cooldown = 3,
		conditions = { requiresFlags = { pursuing_crime = true, first_criminal_job = true } },
		blockedByFlags = { in_prison = true },
		category = "crime",
		choices = {
			{ text = "Join up - strength in numbers 🤝", effects = { Happiness = 10 }, setFlags = { crew_member = true, organized_crime = true }, feedText = "You're in! The crew has your back now." },
			{ text = "Test them first - prove they're legit 🧪", effects = { Smarts = 5 }, setFlags = { cautious_criminal = true }, feedText = "Smart move. You'll join when you're ready." },
			{ text = "Stay solo - trust no one 🐺", effects = { Happiness = 3 }, setFlags = { lone_wolf = true }, feedText = "You work alone. Keeps things simple." },
		},
	},
	{
		id = "criminal_path_close_call",
		title = "🚨 Close Call with Police",
		emoji = "🚨",
		text = "Cops pull up on you while you're handling business. They're asking questions...",
		question = "How do you handle this?",
		minAge = 16, maxAge = 50,
		baseChance = 0.5,
		cooldown = 2,
		conditions = { requiresFlags = { pursuing_crime = true } },
		blockedByFlags = { in_prison = true },
		category = "crime",
		choices = {
			{ text = "Play it cool - you're just walking 😎", effects = { Smarts = 5, Happiness = 5 }, setFlags = { cool_under_pressure = true }, feedText = "They bought it. You walked away clean." },
			{ text = "Run for it! 🏃", effects = { Health = -5 }, setFlags = { runner = true }, feedText = "You lost them in the alleys. That was close!" },
			{ text = "Cooperate fully 🙋", effects = { Happiness = -10 }, setFlags = { cooperative_with_police = true }, feedText = "They let you go but they're watching you now." },
			{ text = "Talk your way out 🗣️", effects = { Smarts = 8 }, setFlags = { smooth_talker = true }, feedText = "Your silver tongue saved you. They apologized for the inconvenience!" },
		},
	},
	{
		id = "criminal_path_turf_war",
		title = "⚔️ Turf War Starting",
		emoji = "⚔️",
		text = "Another crew is moving in on your territory. Tensions are high and violence seems inevitable.",
		question = "What's your move?",
		minAge = 18, maxAge = 45,
		baseChance = 0.45,
		cooldown = 4,
		conditions = { requiresFlags = { pursuing_crime = true, crew_member = true } },
		blockedByFlags = { in_prison = true },
		category = "crime",
		choices = {
			{ text = "Strike first - send a message 👊", effects = { Health = -10, Happiness = 8 }, setFlags = { violent_rep = true, turf_defender = true }, feedText = "Blood was spilled. They know not to mess with you now." },
			{ text = "Set up a sit-down to negotiate 🤝", effects = { Smarts = 10 }, setFlags = { diplomat = true }, feedText = "You brokered a deal. The streets stay peaceful... for now." },
			{ text = "Inform to the cops - let them handle it 📞", effects = { Happiness = -15 }, setFlags = { snitch = true }, feedText = "They got busted. But your own crew suspects you now." },
			{ text = "Lay low and wait it out 🙈", effects = { Happiness = -5 }, feedText = "Coward move but you stayed safe." },
		},
	},
}

return Career
