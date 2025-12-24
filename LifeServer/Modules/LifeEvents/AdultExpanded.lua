--[[
    Adult Expanded Events (Ages 18-60)
    100+ additional adult events with deep, realistic scenarios
    All events use randomized outcomes - NO god mode
]]

local AdultExpanded = {}

local STAGE = "adult"

AdultExpanded.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- YOUNG ADULT TRANSITION (Ages 18-25)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "adult_leaving_home",
		title = "Leaving the Nest",
		emoji = "🏠",
		text = "Time to move out of your parents' house!",
		question = "How does moving out go?",
		minAge = 18, maxAge = 24,
		oneTime = true,
		stage = STAGE,
		ageBand = "young_adult",
		category = "life_transition",
		tags = { "independence", "moving", "adult" },
		
		-- CRITICAL: Random move out outcome
		choices = {
			{
				text = "Move out and thrive",
				effects = {},
				feedText = "On your own for the first time...",
				onResolve = function(state)
					local money = state.Money or 0
					if money < 500 then
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🏠 Moved out but struggling. Bills are real. Scary.")
					else
						local roll = math.random()
						if roll < 0.50 then
							state:ModifyStat("Happiness", 10)
							state.Flags = state.Flags or {}
							state.Flags.independent = true
							state:AddFeed("🏠 FREEDOM! Your own place! Adult life begins!")
						else
							state:ModifyStat("Happiness", 4)
							state:AddFeed("🏠 It's harder than expected but you're managing.")
						end
					end
				end,
			},
			{
				text = "Struggle and return home",
				effects = { Happiness = -8 },
				setFlags = { boomerang_kid = true },
				feedText = "Reality hit hard. Back to parents' house. Humbling.",
			},
			{
				text = "Get roommates to afford it",
				effects = {},
				feedText = "Living with strangers...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.good_roommates = true
						state:AddFeed("🏠 Roommates are great! Like having friends around!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🏠 Roommates are... tolerable. Could be worse.")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.bad_roommates = true
						state:AddFeed("🏠 NIGHTMARE roommates. Dishes everywhere. So loud.")
					end
				end,
			},
			{
				text = "Stay home and save money",
				effects = { Money = 500, Happiness = -2 },
				setFlags = { lives_with_parents = true },
				feedText = "Smart financially but feel like you're behind.",
			},
		},
	},
	{
		id = "adult_college_experience",
		title = "College Life",
		emoji = "🎓",
		text = "The college experience is shaping who you become.",
		question = "What's your college experience like?",
		minAge = 18, maxAge = 23,
		baseChance = 0.5,
		cooldown = 2,
		requiresFlags = { in_college = true },
		stage = STAGE,
		ageBand = "young_adult",
		category = "education",
		tags = { "college", "education", "growth" },
		
		choices = {
			{ text = "Focused on academics", effects = { Smarts = 5, Happiness = -1 }, setFlags = { bookworm = true }, feedText = "Library is your second home. GPA is priority." },
			{ text = "Full social experience", effects = { Happiness = 6, Smarts = 1, Health = -1 }, setFlags = { social_butterfly_college = true }, feedText = "Parties, events, friends. The 'college experience'." },
			{ text = "Balanced approach", effects = { Smarts = 3, Happiness = 4, Health = 1 }, setFlags = { balanced_college = true }, feedText = "Study hard, play hard. Best of both worlds." },
			{ text = "Struggling to fit in", effects = { Happiness = -5, Smarts = 2 }, setFlags = { lonely_college = true }, feedText = "Everyone else seems to have friends. You don't." },
			{ text = "Working while studying", effects = { Smarts = 2, Money = 300, Health = -2 }, setFlags = { working_student = true }, feedText = "Exhausting but necessary. No time for fun." },
		},
	},
	{
		id = "adult_quarter_life_crisis",
		title = "Quarter-Life Crisis",
		emoji = "🤯",
		text = "Am I doing this right? What am I doing with my life?!",
		question = "How do you handle the existential crisis?",
		minAge = 22, maxAge = 28,
		oneTime = true,
		stage = STAGE,
		ageBand = "young_adult",
		category = "psychology",
		tags = { "crisis", "identity", "adult" },
		
		choices = {
			{ text = "Panic and make impulsive changes", effects = { Happiness = 2, Money = -500 }, setFlags = { impulsive_change = true }, feedText = "Quit job, dyed hair, bought something stupid. Felt good briefly." },
			{ text = "Trust the process - keep going", effects = { Happiness = 3, Smarts = 2 }, setFlags = { patient_growth = true }, feedText = "Everyone goes through this. Stay the course." },
			{ text = "Completely change direction", effects = { Happiness = 5, Money = -300 }, setFlags = { major_life_change = true }, feedText = "Screw it. New career, new city, new you." },
			{ text = "Seek therapy and guidance", effects = { Happiness = 6, Smarts = 3, Money = -100 }, setFlags = { therapy_helps = true }, feedText = "Working through it with professional help." },
			{ text = "Distract yourself from thinking about it", effects = { Happiness = -2 }, feedText = "Video games, partying, anything but thinking." },
		},
	},
	{
		id = "adult_student_loans",
		title = "Student Loan Reality",
		emoji = "📄",
		text = "Those student loans are coming due.",
		question = "How are you handling the debt?",
		minAge = 22, maxAge = 35,
		baseChance = 0.4,
		cooldown = 3,
		requiresFlags = { college_grad = true },
		stage = STAGE,
		ageBand = "young_adult",
		category = "finance",
		tags = { "debt", "loans", "money" },
		
		choices = {
			{ text = "Aggressively paying them off", effects = { Happiness = -2, Money = -400, Smarts = 2 }, setFlags = { paying_loans = true }, feedText = "Every spare dollar to loans. Ramen life." },
			{ text = "Just making minimum payments", effects = { Money = -100 }, feedText = "Interest is killing you but it's all you can afford." },
			{ text = "Income-based repayment plan", effects = { Money = -75, Smarts = 1 }, feedText = "Lower payments but loans stretch on forever." },
			{ text = "Struggling to pay at all", effects = { Happiness = -6, Money = -50 }, setFlags = { defaulting = true }, feedText = "Credit score tanking. Calls from collectors. Stress." },
			{ text = "Got lucky - loans forgiven", effects = { Happiness = 10, Money = 200 }, setFlags = { loans_forgiven = true }, feedText = "Some program or luck - debt free! Life-changing!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- RELATIONSHIPS & DATING (Ages 18-50)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "adult_dating_scene",
		title = "Dating Scene",
		emoji = "💕",
		text = "Navigating adult dating life.",
		question = "How's your dating life going?",
		minAge = 18, maxAge = 45,
		baseChance = 0.4,
		cooldown = 2,
		requiresSingle = true,
		stage = STAGE,
		ageBand = "adult",
		category = "romance",
		tags = { "dating", "relationships", "love" },
		
		-- CRITICAL: Random dating outcome
		choices = {
			{
				text = "Try dating apps",
				effects = {},
				feedText = "Swiping left, swiping right...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local successChance = 0.25 + (looks / 150)
					if roll < successChance then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						state.Flags = state.Flags or {}
						state.Flags.found_partner_apps = true
						state.Flags.has_partner = true
						if state.AddFeed then state:AddFeed("💕 Found someone special! Dating apps worked!") end
						-- AAA FIX: Check if AddRelationship exists before calling
						if state.AddRelationship then
							state:AddRelationship("Partner", "romantic", 0.70)
						else
							-- Fallback: Create partner directly
							state.Relationships = state.Relationships or {}
							state.Relationships.partner = {
								id = "partner_" .. tostring(state.Age or 0),
								name = "Partner",
								type = "romantic",
								relationship = 70,
								alive = true,
							}
						end
					elseif roll < 0.65 then
						if state.ModifyStat then state:ModifyStat("Happiness", 2) end
						if state.AddFeed then state:AddFeed("💕 Some okay dates. Nothing special yet.") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -4) end
						if state.AddFeed then state:AddFeed("💕 Dating app burnout. Soul-crushing experience.") end
					end
				end,
			},
			{
				text = "Meet people organically",
				effects = {},
				feedText = "Through friends, hobbies, work...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 10) end
						state.Flags = state.Flags or {}
						state.Flags.found_partner_organic = true
						state.Flags.has_partner = true
						if state.AddFeed then state:AddFeed("💕 Met someone amazing naturally! Real connection!") end
						-- AAA FIX: Check if AddRelationship exists before calling
						if state.AddRelationship then
							state:AddRelationship("Partner", "romantic", 0.80)
						else
							-- Fallback: Create partner directly
							state.Relationships = state.Relationships or {}
							state.Relationships.partner = {
								id = "partner_" .. tostring(state.Age or 0),
								name = "Partner",
								type = "romantic",
								relationship = 80,
								alive = true,
							}
						end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 2) end
						if state.AddFeed then state:AddFeed("💕 Still looking but enjoying life.") end
					end
				end,
			},
			{
				text = "Focus on yourself instead",
				effects = { Happiness = 4, Smarts = 2, Health = 2 },
				setFlags = { self_focused = true },
				feedText = "Working on yourself first. That's healthy.",
			},
			{
				text = "Burnt out from dating",
				effects = { Happiness = -3 },
				setFlags = { dating_exhausted = true },
				feedText = "Taking a break. It's exhausting out there.",
			},
		},
	},
	{
		id = "adult_serious_relationship",
		title = "Getting Serious",
		emoji = "💍",
		text = "Your relationship is getting serious. Big conversations are happening.",
		question = "Where is this relationship going?",
		minAge = 22, maxAge = 45,
		baseChance = 0.3,
		cooldown = 2,
		requiresPartner = true,
		stage = STAGE,
		ageBand = "adult",
		category = "romance",
		tags = { "relationship", "commitment", "future" },
		
		choices = {
			{ text = "Ready to commit fully", effects = { Happiness = 8 }, setFlags = { committed_relationship = true }, feedText = "This is the one. You're all in." },
			{ text = "Not sure - need more time", effects = { Happiness = -2 }, feedText = "Love them but scared of commitment. Stalling." },
			{ text = "Having doubts about compatibility", effects = { Happiness = -5 }, setFlags = { relationship_doubts = true }, feedText = "Something doesn't feel right. Can't ignore it." },
			{ text = "Ready for marriage discussion", effects = { Happiness = 6 }, setFlags = { marriage_minded = true }, feedText = "Talking about forever. Exciting and terrifying." },
		},
	},
	{
		id = "adult_relationship_challenges",
		title = "Relationship Challenges",
		emoji = "💔",
		text = "Every relationship has rough patches.",
		question = "What challenge are you facing?",
		minAge = 20, maxAge = 55,
		baseChance = 0.35,
		cooldown = 3,
		requiresPartner = true,
		stage = STAGE,
		ageBand = "adult",
		category = "romance",
		tags = { "relationship", "conflict", "challenges" },
		
		choices = {
			{
				text = "Communication breaking down",
				effects = {},
				feedText = "You're talking but not hearing each other...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💔 Worked through it. Communication improved.")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.communication_issues = true
						state:AddFeed("💔 Still struggling to connect. Walls are up.")
					end
				end,
			},
			{
				text = "Trust issues emerging",
				effects = { Happiness = -6 },
				setFlags = { trust_issues = true },
				feedText = "Something feels off. Trust is wavering.",
			},
			{
				text = "Different life goals",
				effects = { Happiness = -5 },
				setFlags = { incompatible_goals = true },
				feedText = "Want different things. How do you compromise?",
			},
			{
				text = "Growing apart slowly",
				effects = { Happiness = -4 },
				setFlags = { drifting_apart = true },
				feedText = "Comfortable but distant. When did this happen?",
			},
			{
				text = "Working through it together",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { relationship_work = true },
				feedText = "Committed to fixing things. Together.",
			},
		},
	},
	{
		id = "adult_breakup",
		title = "The Breakup",
		emoji = "💔",
		text = "The relationship has ended.",
		question = "How do you handle the breakup?",
		minAge = 18, maxAge = 55,
		baseChance = 0.45,
		cooldown = 2,
		requiresPartner = true,
		stage = STAGE,
		ageBand = "adult",
		category = "romance",
		tags = { "breakup", "heartbreak", "change" },
		
		choices = {
			{ text = "Devastated - takes years to recover", effects = { Happiness = -15, Health = -5 }, setFlags = { heartbroken_adult = true }, feedText = "World shattered. Everything reminds you of them." },
			{ text = "Sad but know it's right", effects = { Happiness = -6, Smarts = 2 }, setFlags = { mature_breakup = true }, feedText = "Hurts but it was the right decision." },
			{ text = "Already moving on", effects = { Happiness = 2 }, setFlags = { quick_recovery = true }, feedText = "Checked out emotionally a while ago." },
			{ text = "Thrown yourself into work/hobbies", effects = { Happiness = -2, Smarts = 3, Money = 200 }, setFlags = { breakup_productivity = true }, feedText = "Channeling pain into productivity. Cope mechanism." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CAREER DEVELOPMENT (Ages 22-55)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "adult_career_choice",
		title = "Career Direction",
		emoji = "🧭",
		text = "Time to figure out what you want to do with your professional life.",
		question = "What career direction are you taking?",
		minAge = 20, maxAge = 30,
		oneTime = true,
		stage = STAGE,
		ageBand = "young_adult",
		category = "career",
		tags = { "career", "choices", "future" },
		
		choices = {
			{ text = "Follow your passion", effects = { Happiness = 6, Money = -100 }, setFlags = { follows_passion = true }, feedText = "Money isn't everything. Do what you love!" },
			{ text = "Chase the money", effects = { Happiness = -2, Money = 300 }, setFlags = { money_motivated = true }, feedText = "Passion doesn't pay bills. Money first." },
			{ text = "Practical middle ground", effects = { Happiness = 3, Money = 100, Smarts = 2 }, setFlags = { pragmatic_career = true }, feedText = "Something you like that also pays. Balance." },
			{ text = "Still figuring it out", effects = { Happiness = -3 }, setFlags = { career_lost = true }, feedText = "No idea what you want. Floating." },
		},
	},
	{
		id = "adult_job_interview",
		title = "Big Interview",
		emoji = "👔",
		text = "You have an interview for a job you really want!",
		question = "How does the interview go?",
		minAge = 18, maxAge = 55,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "career",
		tags = { "interview", "job", "opportunity" },
		
		-- CRITICAL: Random interview outcome based on Smarts
		choices = {
			{
				text = "Give it your all",
				effects = {},
				feedText = "You walk into the interview room...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local successChance = 0.25 + (smarts / 200) + (looks / 400)
					if roll < successChance then
						state:ModifyStat("Happiness", 12)
						state.Money = (state.Money or 0) + 500
						state.Flags = state.Flags or {}
						state.Flags.got_dream_job = true
						state:AddFeed("👔 YOU GOT THE JOB! Dream opportunity landed!")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("👔 Good interview but didn't get it. Close though.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("👔 Bombed it. Nervous wreck. No callback.")
					end
				end,
			},
			{
				text = "Too nervous - blow it",
				effects = { Happiness = -6 },
				setFlags = { interview_anxiety = true },
				feedText = "Anxiety took over. Couldn't think straight.",
			},
		},
	},
	{
		id = "adult_career_setback",
		title = "Career Setback",
		emoji = "📉",
		text = "Your career has hit a roadblock.",
		question = "What setback are you facing?",
		minAge = 25, maxAge = 55,
		baseChance = 0.455,
		cooldown = 2,
		requiresJob = true,
		stage = STAGE,
		ageBand = "adult",
		category = "career",
		tags = { "career", "setback", "challenge" },
		
		choices = {
			{ text = "Passed over for promotion", effects = { Happiness = -6, Money = -100 }, setFlags = { passed_over = true }, feedText = "Less qualified person got it. Politics." },
			{ text = "Project failed publicly", effects = { Happiness = -7, Smarts = 2 }, setFlags = { public_failure = true }, feedText = "Big failure everyone saw. Reputation hurt." },
			{ text = "Company restructuring - demoted", effects = { Happiness = -8, Money = -200 }, setFlags = { demoted = true }, feedText = "Through no fault of yours. Still humiliating." },
			{ text = "Burnout affecting performance", effects = { Happiness = -5, Health = -4 }, setFlags = { burnout = true }, feedText = "Can't perform at your best. Exhausted." },
			{ text = "Industry changing - skills outdated", effects = { Happiness = -4, Smarts = -2 }, setFlags = { outdated_skills = true }, feedText = "World moved on. Need to upskill or die." },
		},
	},
	{
		id = "adult_career_peak",
		title = "Career Peak",
		emoji = "🏆",
		text = "You've achieved something significant in your career!",
		question = "What's your achievement?",
		minAge = 28, maxAge = 55,
		baseChance = 0.45,
		cooldown = 2,
		requiresJob = true,
		stage = STAGE,
		ageBand = "adult",
		category = "career",
		tags = { "success", "achievement", "career" },
		
		choices = {
			{ text = "Major promotion", effects = { Happiness = 10, Money = 500, Smarts = 2 }, setFlags = { promoted = true }, feedText = "Corner office! Big title! You made it!" },
			{ text = "Industry recognition", effects = { Happiness = 8, Smarts = 3 }, setFlags = { industry_recognized = true }, feedText = "Award, article, something. You're known now." },
			{ text = "Led successful project", effects = { Happiness = 7, Money = 300, Smarts = 3 }, feedText = "Your project was a hit. Leadership skills proven." },
			{ text = "Became the expert", effects = { Happiness = 6, Smarts = 5 }, setFlags = { subject_expert = true }, feedText = "People come to YOU for answers. Respected." },
		},
	},
	{
		id = "adult_side_hustle",
		title = "Side Hustle",
		emoji = "💡",
		text = "Thinking about starting something on the side.",
		question = "What kind of side hustle?",
		minAge = 22, maxAge = 50,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "business",
		tags = { "business", "money", "hustle" },
		
		-- CRITICAL: Random hustle outcome
		choices = {
			{
				text = "Freelancing in your skills",
				effects = {},
				feedText = "Offering your services...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.45 then
						state.Money = (state.Money or 0) + 400
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.successful_freelancer = true
						state:AddFeed("💡 Clients are coming! Making good side income!")
					else
						state:ModifyStat("Happiness", -2)
						state:ModifyStat("Smarts", 1)
						state:AddFeed("💡 Harder than expected. Barely any clients.")
					end
				end,
			},
			{
				text = "Selling things online",
				effects = {},
				feedText = "Opening an online shop...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state.Money = (state.Money or 0) + 300
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.online_seller = true
						state:AddFeed("💡 Sales are coming in! Entrepreneur vibes!")
					elseif roll < 0.70 then
						state.Money = (state.Money or 0) + 50
						state:AddFeed("💡 Trickle of sales. Not quitting the day job.")
					else
						state.Money = (state.Money or 0) - 100
						state:AddFeed("💡 Inventory sitting unsold. Money lost.")
					end
				end,
			},
			{
				text = "Gig economy work",
				effects = { Health = -2, Money = 200 },
				setFlags = { gig_worker = true },
				feedText = "Driving, delivering, tasking. It adds up.",
			},
			{
				text = "Creating content online",
				effects = {},
				feedText = "Building an online presence...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.15 then
						state.Money = (state.Money or 0) + 1000
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.content_creator = true
						state:AddFeed("💡 BLEW UP! Going viral! Making real money!")
					elseif roll < 0.40 then
						state.Money = (state.Money or 0) + 100
						state:ModifyStat("Happiness", 3)
						state:AddFeed("💡 Small following. Slow growth but it's something.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("💡 Creating into the void. Nobody watching.")
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FINANCES & MONEY (Ages 22-60)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "adult_financial_emergency",
		title = "Financial Emergency",
		emoji = "🚨",
		text = "An unexpected expense has hit!",
		question = "How do you handle it?",
		minAge = 20, maxAge = 60,
		baseChance = 0.35,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "finance",
		tags = { "money", "emergency", "stress" },
		
		-- CRITICAL: Random emergency - player doesn't choose what happens
		choices = {
			{
				text = "Deal with the emergency",
				effects = {},
				feedText = "The bill arrives...",
				onResolve = function(state)
					local money = state.Money or 0
					local roll = math.random()
					local expense = math.random(200, 800)
					if money >= expense then
						state.Money = money - expense
						state:ModifyStat("Happiness", -4)
						state:AddFeed(string.format("🚨 Paid $%d for emergency. Painful but handled.", expense))
					else
						state.Money = math.max(0, money - expense)
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.in_debt = true
						state:AddFeed(string.format("🚨 Couldn't afford $%d emergency. In debt now.", expense))
					end
				end,
			},
		},
	},
	{
		id = "adult_investment_opportunity",
		title = "Investment Opportunity",
		emoji = "📈",
		text = "An investment opportunity presents itself.",
		question = "Do you invest?",
		minAge = 25, maxAge = 60,
		baseChance = 0.455,
		cooldown = 2,
		stage = STAGE,
		ageBand = "adult",
		category = "finance",
		tags = { "investing", "money", "risk" },
		careerTags = { "finance" },
		
		-- CRITICAL: Random investment outcome
		eligibility = function(state)
			local money = state.Money or 0
			if money < 500 then
				return false, "Can't afford to invest"
			end
			return true
		end,
		
		choices = {
			{
				text = "Invest a significant amount",
				effects = {},
				feedText = "You put money in...",
				onResolve = function(state)
					local investment = 500
					state.Money = (state.Money or 0) - investment
					local roll = math.random()
					if roll < 0.35 then
						state.Money = state.Money + 1200
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.good_investment = true
						state:AddFeed("📈 INVESTMENT DOUBLED! Great call! $1200 profit!")
					elseif roll < 0.60 then
						state.Money = state.Money + 650
						state:ModifyStat("Happiness", 4)
						state:AddFeed("📈 Modest return. $150 profit. Not bad.")
					elseif roll < 0.85 then
						state.Money = state.Money + 500
						state:AddFeed("📈 Broke even. At least didn't lose money.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.lost_investment = true
						state:AddFeed("📈 LOST IT ALL. $500 gone. Never investing again.")
					end
				end,
			},
			{
				text = "Invest conservatively",
				effects = { Money = -200 },
				feedText = "Playing it safe...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state.Money = (state.Money or 0) + 260
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📈 Small but steady return. $60 profit.")
					else
						state.Money = (state.Money or 0) + 180
						state:ModifyStat("Happiness", -1)
						state:AddFeed("📈 Lost a little. Could be worse.")
					end
				end,
			},
			{
				text = "Pass on it",
				effects = { Smarts = 1 },
				feedText = "Not worth the risk. Keeping cash safe.",
			},
		},
	},
	{
		id = "adult_tax_situation",
		title = "Tax Time",
		emoji = "📋",
		text = "Tax season has arrived.",
		question = "How does it go?",
		minAge = 18, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "finance",
		tags = { "taxes", "money", "adult" },
		
		-- CRITICAL: Random tax outcome
		choices = {
			{
				text = "File your taxes",
				effects = {},
				feedText = "Going through the forms...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						local refund = math.random(500, 1500)
						state.Money = (state.Money or 0) + refund
						state:ModifyStat("Happiness", 6)
						state:AddFeed(string.format("📋 REFUND! $%d back! Tax return surprise!", refund))
					elseif roll < 0.65 then
						local owed = math.random(100, 400)
						state.Money = (state.Money or 0) - owed
						state:ModifyStat("Happiness", -3)
						state:AddFeed(string.format("📋 Owed $%d. Ugh. At least it's done.", owed))
					else
						state:ModifyStat("Happiness", -1)
						state:AddFeed("📋 Broke even. No refund, no payment. Boring.")
					end
				end,
			},
		},
	},
	{
		id = "adult_salary_negotiation",
		title = "Salary Negotiation",
		emoji = "💰",
		text = "Time to negotiate your salary.",
		question = "How do you approach the negotiation?",
		minAge = 22, maxAge = 55,
		baseChance = 0.455,
		cooldown = 2,
		requiresJob = true,
		stage = STAGE,
		ageBand = "adult",
		category = "career",
		tags = { "salary", "negotiation", "money" },
		
		-- CRITICAL: Random negotiation outcome
		choices = {
			{
				text = "Ask for a significant raise",
				effects = {},
				feedText = "You state your case for more money...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.25 + (smarts / 200)
					if roll < successChance then
						local raise = math.random(200, 500)
						state.Money = (state.Money or 0) + raise
						state:ModifyStat("Happiness", 8)
						state:AddFeed(string.format("💰 GOT THE RAISE! $%d more annually!", raise * 12))
					elseif roll < successChance + 0.35 then
						local raise = math.random(50, 150)
						state.Money = (state.Money or 0) + raise
						state:ModifyStat("Happiness", 3)
						state:AddFeed(string.format("💰 Partial win - got $%d more. Something.", raise * 12))
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("💰 Denied. No raise. That hurt.")
					end
				end,
			},
			{
				text = "Don't ask - afraid of rejection",
				effects = { Happiness = -2 },
				setFlags = { afraid_negotiate = true },
				feedText = "You don't ask, you don't get. And you didn't ask.",
			},
			{
				text = "Threaten to leave if no raise",
				effects = {},
				feedText = "Hardball negotiation...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						local raise = math.random(300, 600)
						state.Money = (state.Money or 0) + raise
						state:ModifyStat("Happiness", 10)
						state:AddFeed("💰 They folded! BIG raise to keep you!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.marked = true
						state:AddFeed("💰 They called your bluff. Now you're on thin ice.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.lost_job = true
						state:AddFeed("💰 'Then leave.' You're unemployed now.")
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- HEALTH & WELLNESS (Ages 25-60)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "adult_health_checkup",
		title = "Health Check-up",
		emoji = "🏥",
		text = "Time for a routine health check-up.",
		question = "What do the results show?",
		minAge = 25, maxAge = 70,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "adult",
		category = "health",
		tags = { "health", "doctor", "checkup" },
		
		-- CRITICAL: Random health outcome
		choices = {
			{
				text = "Get the results",
				effects = {},
				feedText = "The doctor reviews your tests...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local age = state.Age or 30
					local roll = math.random()
					local healthyChance = 0.60 - (age / 200) + (health / 200)
					if roll < healthyChance then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", 2)
						state:AddFeed("🏥 Clean bill of health! Everything looks good!")
					elseif roll < healthyChance + 0.25 then
						state:ModifyStat("Happiness", 1)
						state:AddFeed("🏥 Minor concerns. Watch your diet and exercise more.")
					elseif roll < healthyChance + 0.38 then
						state:ModifyStat("Happiness", -4)
						state:ModifyStat("Health", -3)
						state.Flags = state.Flags or {}
						state.Flags.health_warning = true
						state:AddFeed("🏥 Warning signs. Lifestyle changes needed. Serious.")
					else
						state:ModifyStat("Happiness", -8)
						state:ModifyStat("Health", -8)
						state.Flags = state.Flags or {}
						state.Flags.health_condition = true
						state:AddFeed("🏥 Diagnosed with a condition. Treatment starting.")
					end
				end,
			},
		},
	},
	{
		id = "adult_fitness_goal",
		title = "Fitness Goals",
		emoji = "💪",
		text = "You've set some fitness goals for yourself.",
		question = "How dedicated are you?",
		minAge = 20, maxAge = 55,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "adult",
		category = "health",
		tags = { "fitness", "exercise", "health" },
		
		-- CRITICAL: Random fitness outcome
		choices = {
			{
				text = "Commit to a strict routine",
				effects = {},
				feedText = "Weeks of dedication...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Health", 8)
						state:ModifyStat("Looks", 4)
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.fit = true
						state:AddFeed("💪 TRANSFORMED! Best shape of your life!")
					else
						state:ModifyStat("Health", 3)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("💪 Some progress. Not dramatic but healthier.")
					end
				end,
			},
			{
				text = "Try but keep falling off",
				effects = { Health = 1, Happiness = -2 },
				setFlags = { inconsistent_fitness = true },
				feedText = "Start-stop cycle. Frustrating.",
			},
			{
				text = "Hire a personal trainer",
				effects = { Money = -300 },
				feedText = "Investing in help...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Health", 10)
						state:ModifyStat("Looks", 5)
						state:ModifyStat("Happiness", 7)
						state.Flags = state.Flags or {}
						state.Flags.trainer_success = true
						state:AddFeed("💪 WORTH EVERY PENNY! Incredible results!")
					else
						state:ModifyStat("Health", 4)
						state:AddFeed("💪 Better than alone but not amazing results.")
					end
				end,
			},
		},
	},
	{
		id = "adult_mental_health_adult",
		title = "Mental Health Check",
		emoji = "🧠",
		text = "How's your mental health these days?",
		question = "What's your mental state?",
		minAge = 22, maxAge = 60,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "mental_health",
		tags = { "mental_health", "wellness", "self_care" },
		
		choices = {
			{ text = "Thriving - good mindset", effects = { Happiness = 5, Health = 2 }, setFlags = { mentally_healthy = true }, feedText = "In a good place mentally. Grateful." },
			{ text = "Struggling with anxiety", effects = { Happiness = -5, Health = -2 }, setFlags = { adult_anxiety = true }, feedText = "Constant worry. Hard to enjoy anything." },
			{ text = "Dealing with depression", effects = { Happiness = -8, Health = -3 }, setFlags = { adult_depression = true }, feedText = "Dark clouds won't lift. Getting through each day." },
			{ text = "Overwhelmed by stress", effects = { Happiness = -4, Health = -2 }, setFlags = { chronic_stress = true }, feedText = "Too much on your plate. Cracking under pressure." },
			{ text = "Actively working on improvement", effects = { Happiness = 3, Smarts = 2, Money = -50 }, setFlags = { mental_health_work = true }, feedText = "Therapy, meditation, self-care. Investing in yourself." },
		},
	},
	{
		id = "adult_addiction_struggle",
		title = "Addiction Concern",
		emoji = "⚠️",
		text = "Something has become a problem in your life.",
		question = "What are you struggling with?",
		minAge = 20, maxAge = 60,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "adult",
		category = "health",
		tags = { "addiction", "struggle", "health" },
		
		choices = {
			{
				text = "Recognize and seek help",
				effects = {},
				feedText = "Taking the first step...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Health", 5)
						state.Flags = state.Flags or {}
						state.Flags.in_recovery = true
						state:AddFeed("⚠️ Recovery journey started. Hard but hopeful.")
					else
						state:ModifyStat("Happiness", 2)
						state:ModifyStat("Health", 2)
						state:AddFeed("⚠️ Relapsed but trying again. One day at a time.")
					end
				end,
			},
			{
				text = "Deny there's a problem",
				effects = { Happiness = -6, Health = -6 },
				setFlags = { denial = true },
				feedText = "It's not that bad. You can stop anytime. (You can't.)",
			},
			{
				text = "Hit rock bottom first",
				effects = { Happiness = -12, Health = -10, Money = -500 },
				setFlags = { rock_bottom = true },
				feedText = "Lost so much. Maybe now you'll change.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SOCIAL & FRIENDSHIPS (Ages 25-60)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "adult_friendship_evolution",
		title = "Changing Friendships",
		emoji = "👥",
		text = "Adult friendships are different than when you were younger.",
		question = "What's your social life like?",
		minAge = 25, maxAge = 55,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "social",
		tags = { "friends", "social", "adult" },
		
		choices = {
			{ text = "Maintaining strong friendships", effects = { Happiness = 6 }, setFlags = { strong_friendships = true }, feedText = "Quality over quantity. True friends." },
			{ text = "Drifting apart from old friends", effects = { Happiness = -4 }, setFlags = { losing_friends = true }, feedText = "Life gets busy. Everyone's doing their own thing." },
			{ text = "Making new friends through work", effects = { Happiness = 4 }, setFlags = { work_friends_adult = true }, feedText = "Colleagues became genuine friends." },
			{ text = "Lonely - hard to make friends as adult", effects = { Happiness = -6 }, setFlags = { adult_lonely = true }, feedText = "Where do adults even make friends? Struggling." },
			{ text = "Prefer solitude anyway", effects = { Happiness = 2, Smarts = 2 }, setFlags = { happy_alone = true }, feedText = "Introverted life. Peace and quiet." },
		},
	},
	{
		id = "adult_social_event",
		title = "Social Event",
		emoji = "🎉",
		text = "You've been invited to a social event.",
		question = "How does it go?",
		minAge = 20, maxAge = 60,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "adult",
		category = "social",
		tags = { "party", "social", "networking" },
		
		-- CRITICAL: Random social outcome
		choices = {
			{
				text = "Go and socialize",
				effects = {},
				feedText = "You walk into the event...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 7)
						state.Flags = state.Flags or {}
						state.Flags.great_socializer = true
						state:AddFeed("🎉 Amazing night! Made connections, had fun!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🎉 Pleasant enough. Some small talk. Average.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🎉 Awkward. Stood in the corner. Left early.")
					end
				end,
			},
			{
				text = "Skip it - social anxiety",
				effects = { Happiness = -3 },
				setFlags = { social_avoidance = true },
				feedText = "Couldn't bring yourself to go. FOMO hits later.",
			},
			{
				text = "Go but leave early",
				effects = { Happiness = 1 },
				feedText = "Showed face, then Irish exit. Perfect balance.",
			},
		},
	},
	{
		id = "adult_networking",
		title = "Professional Networking",
		emoji = "🤝",
		text = "Networking could open career doors.",
		question = "How do you approach networking?",
		minAge = 22, maxAge = 55,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "career",
		tags = { "networking", "career", "professional" },
		
		-- CRITICAL: Random networking outcome
		choices = {
			{
				text = "Actively network",
				effects = {},
				feedText = "Making professional connections...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.good_network = true
						state:AddFeed("🤝 Made valuable connections! Opportunities incoming!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🤝 Few business cards exchanged. We'll see.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🤝 Awkward interactions. Networking isn't your thing.")
					end
				end,
			},
			{
				text = "Hate networking - avoid it",
				effects = { Happiness = 1 },
				setFlags = { hates_networking = true },
				feedText = "Feels fake and forced. Not doing it.",
			},
			{
				text = "Network online instead",
				effects = { Smarts = 2 },
				feedText = "LinkedIn life. Professional but from the couch.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- LIFE EVENTS (Ages 25-55)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "adult_wedding_event",
		title = "Wedding Season",
		emoji = "💒",
		text = "Everyone's getting married! You're invited to another wedding.",
		question = "How do you feel about wedding season?",
		minAge = 24, maxAge = 40,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "adult",
		category = "social",
		tags = { "wedding", "social", "comparison" },
		
		choices = {
			{ text = "Celebrate love - so happy for them!", effects = { Happiness = 5, Money = -100 }, feedText = "Beautiful ceremony. Cried a little. Worth the gift." },
			{ text = "Jealous - when's my turn?", effects = { Happiness = -5, Money = -100 }, setFlags = { wedding_jealousy = true }, feedText = "Happy for them but bitter inside." },
			{ text = "Wedding fatigue - too many", effects = { Happiness = -2, Money = -100 }, feedText = "This is wedding #5 this year. Your wallet is crying." },
			{ text = "Skip it - can't afford another", effects = { Happiness = -2 }, feedText = "RSVP: No. Bank account thanks you." },
		},
	},
	{
		id = "adult_having_children",
		title = "Children Discussion",
		emoji = "👶",
		text = "The question of having children comes up with your partner.",
		question = "What are your thoughts on kids?",
		minAge = 25, maxAge = 45,
		baseChance = 0.3,
		cooldown = 2,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "children", "family", "future" },
		-- CRITICAL FIX: Must have a partner to discuss having children!
		requiresFlags = { has_partner = true },
		blockedByFlags = { single = true, recently_single = true, divorced = true },
		
		-- CRITICAL FIX: Double-check with eligibility
		eligibility = function(state)
			local flags = state.Flags or {}
			if not (flags.has_partner or flags.married or flags.engaged or flags.dating or flags.committed_relationship) then
				return false, "Need a partner to discuss children"
			end
			return true
		end,
		
		choices = {
			{ text = "Definitely want kids", effects = { Happiness = 3 }, setFlags = { wants_kids = true }, feedText = "Can't wait to be a parent. It's the dream." },
			{ text = "Definitely don't want kids", effects = { Happiness = 4 }, setFlags = { childfree = true }, feedText = "Kid-free life is the life for you. No regrets." },
			{ text = "On the fence about it", effects = { Happiness = -2 }, setFlags = { undecided_kids = true }, feedText = "Pros and cons. Huge decision. Not ready to decide." },
			{ text = "Want them but can't afford them", effects = { Happiness = -5 }, setFlags = { wants_kids_broke = true }, feedText = "Kids are expensive. Maybe someday..." },
			{ text = "Trying but struggling", effects = { Happiness = -6 }, setFlags = { fertility_struggle = true }, feedText = "The journey is harder than expected. Emotionally draining." },
		},
	},
	{
		id = "adult_home_ownership",
		title = "Homeownership Dream",
		emoji = "🏡",
		text = "Thinking about buying a home.",
		question = "What's your housing situation?",
		minAge = 25, maxAge = 50,
		baseChance = 0.455,
		cooldown = 2,
		stage = STAGE,
		ageBand = "adult",
		category = "finance",
		tags = { "home", "property", "money" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 2000 then
				return false, "Not enough for a down payment"
			end
			return true
		end,
		
		-- CRITICAL: Random housing outcome
		choices = {
			{
				text = "Try to buy a house",
				effects = {},
				feedText = "House hunting, mortgage applications...",
				onResolve = function(state)
					local money = state.Money or 0
					local roll = math.random()
					if roll < 0.50 then
						state.Money = money - 5000
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.homeowner = true
						state:AddFeed("🏡 YOU OWN A HOME! Mortgage approved! Keys in hand!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🏡 Outbid or rejected. Housing market is brutal.")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🏡 Mortgage denied. Credit or income issues. Crushed.")
					end
				end,
			},
			{
				text = "Keep renting - more flexibility",
				effects = { Happiness = 2 },
				setFlags = { happy_renter = true },
				feedText = "Ownership is overrated. Rent and freedom.",
			},
			{
				text = "Save more for bigger down payment",
				effects = { Smarts = 2, Money = 200 },
				setFlags = { saving_for_house = true },
				feedText = "Patience. Building up that down payment.",
			},
		},
	},
	{
		id = "adult_midlife_crisis",
		title = "Midlife Crisis",
		emoji = "🏎️",
		text = "You're questioning everything about your life so far.",
		question = "How do you handle the midlife crisis?",
		minAge = 38, maxAge = 52,
		oneTime = true,
		stage = STAGE,
		ageBand = "adult",
		category = "psychology",
		tags = { "crisis", "midlife", "identity" },
		
		choices = {
			{ text = "Buy something impulsive and expensive", effects = { Happiness = 4, Money = -2000 }, setFlags = { midlife_splurge = true }, feedText = "Sports car, motorcycle, something stupid. Worth it?" },
			{ text = "Make a dramatic life change", effects = { Happiness = 5, Money = -500 }, setFlags = { midlife_change = true }, feedText = "Quit job, moved cities, started over. Bold move." },
			{ text = "Have an affair", effects = { Happiness = 3 }, setFlags = { affair = true }, feedText = "Made a terrible choice. Exciting but destructive." },
			{ text = "Channel it productively", effects = { Happiness = 6, Health = 4, Smarts = 2 }, setFlags = { productive_midlife = true }, feedText = "New fitness routine, new hobby, better version of you." },
			{ text = "Accept and appreciate what you have", effects = { Happiness = 8, Smarts = 3 }, setFlags = { grateful_midlife = true }, feedText = "Gratitude over regret. Peace with the journey." },
		},
	},
	{
		id = "adult_parents_aging",
		title = "Aging Parents",
		emoji = "👵",
		text = "Your parents are getting older. Roles are shifting.",
		question = "How are you handling your parents aging?",
		minAge = 35, maxAge = 60,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "parents", "aging", "family" },
		
		choices = {
			{ text = "Taking on caregiver role", effects = { Happiness = -4, Money = -200, Smarts = 2 }, setFlags = { caregiver = true }, feedText = "Helping them more. It's exhausting but important." },
			{ text = "Worried about their health", effects = { Happiness = -5 }, setFlags = { worried_about_parents = true }, feedText = "Every phone call makes your heart drop." },
			{ text = "Having difficult conversations", effects = { Happiness = -3, Smarts = 2 }, feedText = "End of life planning, living situations. Hard talks." },
			{ text = "Distant - not involved", effects = { Happiness = -2 }, setFlags = { distant_from_parents = true }, feedText = "Guilty but not close enough to help." },
			{ text = "They're healthy and independent", effects = { Happiness = 5 }, setFlags = { healthy_parents = true }, feedText = "Lucky. They're doing great for their age." },
		},
	},
	{
		id = "adult_hobby_discovery",
		title = "New Hobby Discovery",
		emoji = "✨",
		text = "You've discovered a new hobby that brings you joy!",
		question = "What's your new passion?",
		minAge = 25, maxAge = 60,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "hobbies",
		tags = { "hobby", "passion", "growth" },
		
		choices = {
			{ text = "Outdoor activities", effects = { Happiness = 6, Health = 5 }, setFlags = { outdoor_hobby = true }, feedText = "Hiking, camping, nature. Fresh air and adventure!" },
			{ text = "Creative pursuits", effects = { Happiness = 6, Smarts = 3 }, setFlags = { creative_hobby = true }, feedText = "Art, music, writing. Expressing yourself." },
			{ text = "Learning new skills", effects = { Smarts = 6, Happiness = 4 }, setFlags = { skill_hobby = true }, feedText = "Languages, coding, instruments. Never stop learning." },
			{ text = "Collecting something", effects = { Happiness = 4, Money = -100 }, setFlags = { collector = true }, feedText = "The thrill of the hunt. Your collection grows." },
			{ text = "Gaming community", effects = { Happiness = 5, Smarts = 2 }, setFlags = { gamer_adult = true }, feedText = "Found your people. Gaming isn't just for kids." },
		},
	},
	{
		id = "adult_vacation_plans",
		title = "Vacation Planning",
		emoji = "✈️",
		text = "Time to plan a vacation!",
		question = "What kind of trip?",
		minAge = 22, maxAge = 65,
		baseChance = 0.35,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "leisure",
		tags = { "vacation", "travel", "experiences" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 500 then
				return false, "Can't afford a vacation"
			end
			return true
		end,
		
		-- CRITICAL: Random vacation outcome
		choices = {
			{
				text = "Dream destination trip",
				effects = { Money = -2000 },
				feedText = "The trip of a lifetime...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.great_vacation = true
						state:AddFeed("✈️ INCREDIBLE TRIP! Memories that'll last forever!")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("✈️ Great trip! Some hiccups but worth it.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("✈️ Disaster vacation. Lost luggage, bad weather. Ugh.")
					end
				end,
			},
			{
				text = "Budget staycation",
				effects = { Money = -200, Happiness = 5 },
				feedText = "Local exploration. Don't need to fly to have fun.",
			},
			{
				text = "Relaxing beach trip",
				effects = { Money = -1000, Happiness = 10, Health = 3 },
				feedText = "Sun, sand, and doing nothing. Perfect.",
			},
			{
				text = "Adventure trip",
				effects = { Money = -1500 },
				feedText = "Adrenaline-seeking adventure...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.80 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Health", 3)
						state:AddFeed("✈️ EPIC adventure! Skydiving, rafting, unforgettable!")
					else
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", -5)
						state:AddFeed("✈️ Adventure injury. Still fun but ouch.")
					end
				end,
			},
		},
	},
	{
		id = "adult_car_situation",
		title = "Car Situation",
		emoji = "🚗",
		text = "Something's happening with your vehicle.",
		question = "What's the car situation?",
		minAge = 18, maxAge = 70,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "adult",
		category = "expenses",
		tags = { "car", "expenses", "adulting" },
		
		-- CRITICAL FIX: Check if has car first - Assets is a dictionary not an array!
		eligibility = function(state)
			-- Check flags first
			if state.Flags and (state.Flags.has_car or state.Flags.owns_car or state.Flags.has_first_car) then
				return true
			end
			-- CRITICAL FIX: Assets is a dictionary, check Vehicles key properly
			if state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0 then
				return true
			end
			return false, "No car to have issues with"
		end,
		
		-- CRITICAL: Random car problem
		choices = {
			{
				text = "Deal with it",
				effects = {},
				feedText = "Car trouble...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						local cost = math.random(100, 300)
						state.Money = (state.Money or 0) - cost
						state:ModifyStat("Happiness", -2)
						state:AddFeed(string.format("🚗 Minor repair needed. $%d gone.", cost))
					elseif roll < 0.70 then
						local cost = math.random(500, 1200)
						state.Money = (state.Money or 0) - cost
						state:ModifyStat("Happiness", -5)
						state:AddFeed(string.format("🚗 Major repair! $%d! That hurts.", cost))
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🚗 False alarm. Nothing major. Relief.")
					else
						local cost = math.random(1500, 3000)
						state.Money = (state.Money or 0) - cost
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.car_totaled = true
						state:AddFeed(string.format("🚗 Car is totaled. Either pay $%d or need new car.", cost))
					end
				end,
			},
		},
	},
	{
		id = "adult_pet_decision",
		title = "Pet Decision",
		emoji = "🐕",
		text = "Thinking about getting a pet.",
		question = "Do you get a pet?",
		minAge = 20, maxAge = 60,
		baseChance = 0.455,
		cooldown = 2,
		stage = STAGE,
		ageBand = "adult",
		category = "lifestyle",
		tags = { "pet", "companionship", "responsibility" },
		
		choices = {
			{
				text = "Adopt a dog",
				effects = { Money = -300 },
				setFlags = { has_dog = true },
				feedText = "New best friend acquired...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.75 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Health", 2)
						state:AddFeed("🐕 Best decision ever! Unconditional love!")
					else
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🐕 More work than expected but worth it.")
					end
				end,
			},
			{
				text = "Get a cat",
				effects = { Money = -200, Happiness = 7 },
				setFlags = { has_cat = true },
				feedText = "Independent companion. Perfect for you.",
			},
			{
				text = "Not ready for that commitment",
				effects = { Happiness = 1 },
				feedText = "Pets are a lot of responsibility. Not now.",
			},
			{
				text = "Already have pets - get another!",
				effects = { Money = -200, Happiness = 6 },
				requiresFlags = { has_pet = true },
				feedText = "More the merrier! Growing your pet family.",
			},
		},
	},
	{
		id = "adult_neighborhood_issues",
		title = "Neighbor Problems",
		emoji = "🏘️",
		text = "There's an issue with your neighbor.",
		question = "How do you handle it?",
		minAge = 22, maxAge = 70,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "lifestyle",
		tags = { "neighbors", "conflict", "home" },
		
		choices = {
			{
				text = "Talk it out civilly",
				effects = {},
				feedText = "You knock on their door...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🏘️ Resolved! They were reasonable. Good neighbors now.")
					else
						state:ModifyStat("Happiness", -3)
						state.Flags = state.Flags or {}
						state.Flags.bad_neighbors = true
						state:AddFeed("🏘️ They weren't receptive. Tension remains.")
					end
				end,
			},
			{
				text = "Escalate - call authorities",
				effects = {},
				feedText = "Taking official action...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🏘️ Authorities handled it. Problem solved but awkward.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🏘️ Made things worse. Now they hate you. Neighborhood war.")
					end
				end,
			},
			{
				text = "Just deal with it",
				effects = { Happiness = -3 },
				feedText = "Not worth the confrontation. Suffering in silence.",
			},
		},
	},
	{
		id = "adult_work_life_balance",
		title = "Work-Life Balance",
		emoji = "⚖️",
		text = "Struggling to find balance between work and life.",
		question = "How's your work-life balance?",
		minAge = 25, maxAge = 55,
		baseChance = 0.4,
		cooldown = 2,
		requiresJob = true,
		stage = STAGE,
		ageBand = "adult",
		category = "lifestyle",
		tags = { "balance", "work", "life" },
		
		choices = {
			{ text = "Work is consuming everything", effects = { Happiness = -6, Money = 200, Health = -4 }, setFlags = { workaholic = true }, feedText = "All work, no life. Making money but at what cost?" },
			{ text = "Found a good balance", effects = { Happiness = 6, Health = 2 }, setFlags = { balanced_life = true }, feedText = "Work stays at work. Life stays rich." },
			{ text = "Prioritizing life over work", effects = { Happiness = 5, Money = -100 }, setFlags = { life_prioritizer = true }, feedText = "Career taking backseat but happier." },
			{ text = "Boundaries constantly violated", effects = { Happiness = -4, Health = -2 }, setFlags = { bad_boundaries = true }, feedText = "Work calls at night, emails on vacation. Toxic." },
		},
	},
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #33: Car Shopping with Loan Financing
	-- Adults should be able to buy cars with financing (loans)
	-- Without this, players can only buy cars if they have full cash price
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "adult_car_shopping",
		title = "Time for New Wheels",
		emoji = "🚗",
		text = "Your current car situation needs attention - maybe it's time for an upgrade?",
		question = "How do you handle transportation?",
		minAge = 21, maxAge = 60,
		baseChance = 0.455,
		cooldown = 2,
		stage = STAGE,
		ageBand = "adult",
		category = "transportation",
		tags = { "car", "finance", "vehicle", "loan" },
		blockedByFlags = { in_prison = true },
		
		eligibility = function(state)
			-- Must have some income for financing
			return state.CurrentJob or (state.Money or 0) >= 3000
		end,
		
		choices = {
			{
				text = "Buy a reliable used car ($8,000)",
				effects = {},
				feedText = "Shopping for a used car...",
				onResolve = function(state)
					local money = state.Money or 0
					local carPrice = 8000
					
					if money >= carPrice then
						-- Pay cash
						state.Money = money - carPrice
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "used_car_" .. tostring(state.Age or 0),
								name = "Reliable Used Car",
								emoji = "🚗",
								price = carPrice,
								value = 7000,
								condition = 70,
								isEventAcquired = true,
							})
						end
						state.Flags = state.Flags or {}
						state.Flags.has_car = true
						state.Flags.has_vehicle = true
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🚗 Paid cash for a reliable used car! No monthly payments!")
					elseif money >= 2000 then
						-- Finance the car
						local downPayment = math.min(money, 2000)
						local loanAmount = carPrice - downPayment
						state.Money = money - downPayment
						state.Flags = state.Flags or {}
						state.Flags.has_car_loan = true
						state.Flags.car_loan_balance = loanAmount
						state.Flags.car_loan_payment = math.floor(loanAmount / 48) -- 4 year loan
						
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "financed_car_" .. tostring(state.Age or 0),
								name = "Reliable Used Car",
								emoji = "🚗",
								price = carPrice,
								value = 7000,
								condition = 70,
								isEventAcquired = true,
								financed = true,
							})
						end
						state.Flags.has_car = true
						state.Flags.has_vehicle = true
						state:ModifyStat("Happiness", 6)
						state:AddFeed(string.format("🚗 Financed a used car! $%d down, $%d/month for 4 years.", downPayment, state.Flags.car_loan_payment))
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🚗 Can't afford a car right now. Need more savings or a better job.")
					end
				end,
			},
			{
				text = "Finance a new car ($25,000)",
				effects = {},
				feedText = "At the new car dealership...",
				onResolve = function(state)
					local money = state.Money or 0
					local carPrice = 25000
					local requiredDownPayment = 3000
					
					if money < requiredDownPayment then
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🚗 Denied! Need at least $3,000 down payment.")
						return
					end
					
					-- Check if has bad credit
					state.Flags = state.Flags or {}
					if state.Flags.bad_credit or state.Flags.declared_bankruptcy then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🚗 Loan denied! Bad credit history.")
						return
					end
					
					-- Approved for financing
					local downPayment = math.min(money, 5000)
					local loanAmount = carPrice - downPayment
					state.Money = money - downPayment
					state.Flags.has_car_loan = true
					state.Flags.car_loan_balance = loanAmount
					state.Flags.car_loan_payment = math.floor(loanAmount / 60) -- 5 year loan
					
					if state.AddAsset then
						state:AddAsset("Vehicles", {
							id = "new_car_" .. tostring(state.Age or 0),
							name = "New Car",
							emoji = "🚗",
							price = carPrice,
							value = 22000, -- Depreciates immediately
							condition = 100,
							isEventAcquired = true,
							financed = true,
						})
					end
					state.Flags.has_car = true
					state.Flags.has_vehicle = true
					state:ModifyStat("Happiness", 10)
					state:AddFeed(string.format("🚗 Got a new car! $%d down, $%d/month for 5 years.", downPayment, state.Flags.car_loan_payment))
				end,
			},
			{
				text = "Buy a luxury car ($50,000+)",
				effects = {},
				feedText = "Living large at the luxury dealership...",
				onResolve = function(state)
					local money = state.Money or 0
					local carPrice = 50000
					
					if money >= carPrice then
						-- Pay cash for luxury
						state.Money = money - carPrice
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "luxury_car_" .. tostring(state.Age or 0),
								name = "Luxury Vehicle",
								emoji = "🏎️",
								price = carPrice,
								value = 45000,
								condition = 100,
								isEventAcquired = true,
							})
						end
						state.Flags = state.Flags or {}
						state.Flags.has_car = true
						state.Flags.has_vehicle = true
						state.Flags.luxury_car_owner = true
						state:ModifyStat("Happiness", 15)
						state:AddFeed("🏎️ Bought a luxury car with CASH! Living the dream!")
					elseif money >= 10000 then
						-- Finance luxury car
						state.Flags = state.Flags or {}
						if state.Flags.bad_credit then
							state:ModifyStat("Happiness", -5)
							state:AddFeed("🏎️ Luxury financing denied. Bad credit.")
							return
						end
						
						local downPayment = math.min(money, 15000)
						local loanAmount = carPrice - downPayment
						state.Money = money - downPayment
						state.Flags.has_car_loan = true
						state.Flags.car_loan_balance = loanAmount
						state.Flags.car_loan_payment = math.floor(loanAmount / 72) -- 6 year loan
						
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "financed_luxury_" .. tostring(state.Age or 0),
								name = "Luxury Vehicle",
								emoji = "🏎️",
								price = carPrice,
								value = 45000,
								condition = 100,
								isEventAcquired = true,
								financed = true,
							})
						end
						state.Flags.has_car = true
						state.Flags.has_vehicle = true
						state.Flags.luxury_car_owner = true
						state:ModifyStat("Happiness", 12)
						state:AddFeed(string.format("🏎️ Financed a luxury car! $%d down, $%d/month. Worth it!", downPayment, state.Flags.car_loan_payment))
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🏎️ Can't swing a luxury car yet. Dreams for later.")
					end
				end,
			},
			{
				text = "Keep what I have",
				effects = { Happiness = 2 },
				feedText = "Your current situation works for now.",
			},
		},
	},
}

return AdultExpanded
