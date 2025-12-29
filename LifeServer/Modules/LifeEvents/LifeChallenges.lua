--[[
    Life Challenges & Obstacles
    Major life challenges and how to overcome them
    All events use randomized outcomes - NO god mode
]]

local LifeChallenges = {}

local STAGE = "random"

LifeChallenges.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- PERSONAL CHALLENGES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "challenge_addiction_struggle",
		title = "Addiction Battle",
		emoji = "⚔️",
		text = "You're struggling with an addiction.",
		question = "How do you fight this battle?",
		minAge = 16, maxAge = 80,
		baseChance = 0.32,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "addiction", "recovery", "struggle" },
		
		requiresFlags = { unhealthy_coping = true },
		
		-- CRITICAL: Random addiction recovery outcome
		choices = {
			{
				-- CRITICAL FIX: Show price and add per-choice eligibility check
				text = "Seek professional help ($500)",
				effects = { Money = -500 },
				feedText = "Getting into treatment...",
				eligibility = function(state)
					if (state.Money or 0) < 500 then
						return false, "Can't afford $500 for professional help"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Health", 8)
						state.Flags = state.Flags or {}
						state.Flags.in_recovery = true
						state.Flags.unhealthy_coping = nil
						state:AddFeed("⚔️ RECOVERY BEGINS! One day at a time. Getting better!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Health", 4)
						state:AddFeed("⚔️ Making progress. Not easy but trying. Slip-ups happen.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("⚔️ Relapsed. Treatment didn't stick yet. Try again.")
					end
				end,
			},
			{ text = "Join support group", effects = { Happiness = 4, Health = 3 }, setFlags = { in_recovery = true }, feedText = "⚔️ Found community. Not alone in this fight." },
			{ text = "Try to quit cold turkey", effects = {}, feedText = "Going it alone...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Health", 10)
						state.Flags = state.Flags or {}
						state.Flags.in_recovery = true
						state.Flags.unhealthy_coping = nil
						state:AddFeed("⚔️ Did it! Willpower won! Clean and proud!")
					else
						state:ModifyStat("Happiness", -6)
						state:ModifyStat("Health", -4)
						state:AddFeed("⚔️ Couldn't do it alone. Need support to beat this.")
					end
				end,
			},
		},
	},
	{
		id = "challenge_major_setback",
		title = "Major Life Setback",
		emoji = "🔙",
		text = "Life has dealt you a major setback.",
		question = "How do you handle this blow?",
		minAge = 18, maxAge = 80,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "challenge",
		tags = { "setback", "resilience", "challenge" },
		
		-- CRITICAL: Random setback type and recovery
		choices = {
			{
				text = "Career setback",
				effects = {},  -- No forced money loss - handled in onResolve
				feedText = "Dealing with professional blow...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", -6)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("🔙 Major career hit but finding new path. Growth opportunity.")
					else
						state:ModifyStat("Happiness", -10)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 500)
						state.Flags = state.Flags or {}
						state.Flags.career_crisis = true
						state:AddFeed("🔙 Career in shambles. Starting over. Devastating but not impossible.")
					end
				end,
			},
			{
				text = "Relationship setback",
				effects = {},
				feedText = "Processing relationship loss...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", -8)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🔙 Heart broken but learning. Will love again. Healing.")
					else
						state:ModifyStat("Happiness", -12)
						state:ModifyStat("Health", -3)
						state.Flags = state.Flags or {}
						state.Flags.heartbroken = true
						state:AddFeed("🔙 Devastating loss. Can't imagine life without them. Dark times.")
					end
				end,
			},
		{
			text = "Financial setback",
			effects = {},  -- Don't force money loss - it's in onResolve based on what you have
			feedText = "Dealing with financial blow...",
			onResolve = function(state)
				-- Take proportional money loss (50% of what you have, max $1000)
				local currentMoney = state.Money or 0
				local lossAmount = math.min(1000, math.floor(currentMoney * 0.5))
				state.Money = math.max(0, currentMoney - lossAmount)
				
				local roll = math.random()
				if roll < 0.45 then
					state:ModifyStat("Happiness", -5)
					state:ModifyStat("Smarts", 4)
					if lossAmount > 0 then
						state:AddFeed(string.format("🔙 Lost $%d but learned lesson. Rebuilding smarter.", lossAmount))
					else
						state:AddFeed("🔙 Financial setback but already had nothing. Rock bottom.")
					end
				else
					state:ModifyStat("Happiness", -10)
					state.Flags = state.Flags or {}
					state.Flags.financial_crisis = true
					if lossAmount > 0 then
						state:AddFeed(string.format("🔙 Financial devastation. Lost $%d. Starting over.", lossAmount))
					else
						state:AddFeed("🔙 Financial crisis. Already broke. Things got worse somehow.")
					end
				end
			end,
			},
		},
	},
	{
		id = "challenge_impostor_syndrome",
		title = "Impostor Syndrome",
		emoji = "😰",
		text = "Feeling like a fraud despite your accomplishments.",
		question = "How do you deal with impostor syndrome?",
		minAge = 18, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "mental_health",
		tags = { "impostor", "confidence", "psychology" },
		
		-- CRITICAL: Random impostor syndrome outcome
		choices = {
			{
				text = "Challenge the thoughts",
				effects = {},
				feedText = "Fighting self-doubt...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.50 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.confident = true
						state:AddFeed("😰 Realized you DO belong! Earned your place! Confidence boost!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 3)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("😰 Still struggle but managing. Fake it til you make it.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("😰 Self-doubt won today. Tomorrow is another fight.")
					end
				end,
			},
			{ text = "Talk to mentor/therapist", effects = { Happiness = 6, Smarts = 3 }, feedText = "😰 External perspective helps! You're not a fraud!" },
			{ text = "Document your wins", effects = { Happiness = 5, Smarts = 2 }, setFlags = { keeps_success_journal = true }, feedText = "😰 Evidence of accomplishments. Can't argue with facts!" },
		},
	},
	{
		id = "challenge_chronic_illness",
		title = "Chronic Illness Diagnosis",
		emoji = "🏥",
		text = "The doctor has some difficult news. After running tests, you've been diagnosed with a chronic condition that will require ongoing management.",
		question = "How do you adapt to this new reality?",
		minAge = 25, maxAge = 100,
		baseChance = 0.20, -- Reduced from 0.32 to make it less common
		cooldown = 10, -- Higher cooldown - life-changing diagnosis shouldn't spam
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "chronic", "illness", "health" },
		
		choices = {
			{
				text = "Follow treatment plan ($200)",
				effects = { Money = -200 },
				feedText = "Managing the condition...",
				eligibility = function(state) return (state.Money or 0) >= 200, "Can't afford treatment" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Health", -5)
						state.Flags = state.Flags or {}
						state.Flags.chronic_illness = true
						state:AddFeed("🏥 Managing well! New normal established. Adapting!")
					else
						state:ModifyStat("Happiness", -4)
						state:ModifyStat("Health", -10)
						state.Flags = state.Flags or {}
						state.Flags.chronic_illness = true
						state:AddFeed("🏥 Good days and bad days. Condition challenging but fighting.")
					end
				end,
			},
		{ text = "Join support community", effects = { Happiness = 5, Health = -5 }, setFlags = { chronic_illness = true, illness_support_group = true }, feedText = "🏥 Others understand. Not alone in this. Community helps." },
		{ text = "Research everything online", effects = { Happiness = -2, Smarts = 3, Health = -5 }, setFlags = { chronic_illness = true, illness_researcher = true }, feedText = "🏥 Became an expert on your condition. Knowledge is power." },
		{ text = "Struggle to accept", effects = { Happiness = -8, Health = -8 }, setFlags = { chronic_illness = true, illness_denial = true }, feedText = "🏥 Can't accept this is your life now. Grieving health." },
	},
},
	{
		id = "challenge_burnout_recovery",
		title = "Recovering from Burnout",
		emoji = "🔥",
		text = "You've hit complete burnout. Time to recover.",
		question = "How do you recover from burnout?",
		minAge = 20, maxAge = 70,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "wellness",
		tags = { "burnout", "recovery", "stress" },
		
		requiresFlags = { burned_out = true },
		
		-- CRITICAL: Random burnout recovery
		choices = {
			{
				-- CRITICAL FIX: Show price and add per-choice eligibility check
				text = "Take extended leave ($500)",
				effects = { Money = -500 },
				feedText = "Stepping back completely...",
				eligibility = function(state)
					if (state.Money or 0) < 500 then
						return false, "Can't afford $500 for extended leave"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Health", 8)
						state.Flags = state.Flags or {}
						state.Flags.burned_out = nil
						state.Flags.recovered_from_burnout = true
						state:AddFeed("🔥 REST! Actually rested! Feel human again! Reset complete!")
					else
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", 4)
						state:AddFeed("🔥 Better but not fully recovered. Need more time.")
					end
				end,
			},
			{ text = "Make lifestyle changes", effects = { Happiness = 6, Health = 4 }, feedText = "🔥 Boundaries, self-care, priorities. Sustainable pace now." },
			{ text = "Push through it", effects = { Happiness = -6, Health = -6 }, feedText = "🔥 Can't stop. Things getting worse. Crisis mode continues." },
		},
	},
	{
		id = "challenge_identity_crisis",
		title = "Identity Crisis",
		emoji = "🤔",
		text = "You don't know who you are anymore.",
		question = "How do you find yourself?",
		minAge = 16, maxAge = 70,
		baseChance = 0.38,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "psychology",
		tags = { "identity", "crisis", "self" },
		
		-- CRITICAL: Random identity discovery
		choices = {
			{
				text = "Deep self-reflection",
				effects = {},
				feedText = "Looking inward...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.45 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 5)
						state.Flags = state.Flags or {}
						state.Flags.self_aware = true
						state:AddFeed("🤔 FOUND YOURSELF! Know who you are now. Clarity!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("🤔 Getting clearer. Still work to do. Progress.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤔 More confused than before. Identity is complex.")
					end
				end,
			},
			{ text = "Try new things", effects = { Happiness = 6, Smarts = 3 }, feedText = "🤔 Experimenting with life. Discovering what resonates." },
			{ text = "Seek therapy ($150)", effects = { Money = -150, Happiness = 5, Smarts = 4 }, setFlags = { in_therapy = true }, feedText = "🤔 Professional guidance. Peeling back layers. Growth.", eligibility = function(state) return (state.Money or 0) >= 150, "💸 Need $150 for therapy" end },
		},
	},
	{
		id = "challenge_fear_of_failure",
		title = "Paralyzed by Fear of Failure",
		emoji = "😨",
		text = "Fear of failure is stopping you from trying.",
		question = "How do you overcome the fear?",
		minAge = 15, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "psychology",
		tags = { "fear", "failure", "psychology" },
		
		-- CRITICAL: Random fear outcome
		choices = {
			{
				text = "Take the leap anyway",
				effects = {},
				feedText = "Doing it scared...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 4)
						state.Flags = state.Flags or {}
						state.Flags.courageous = true
						state:AddFeed("😨 IT WORKED! Feared failure but succeeded! Growth!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("😨 Failed but survived! Failure isn't the end! Learned!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("😨 Failed and it hurt. But still here. Try again?")
					end
				end,
			},
			{ text = "Start small", effects = { Happiness = 5, Smarts = 2 }, feedText = "😨 Baby steps. Building confidence gradually. Smart approach." },
			{ text = "Stay safe", effects = { Happiness = -3 }, setFlags = { plays_it_safe = true }, feedText = "😨 Didn't try. Safe but stagnant. Regret building." },
		},
	},
	{
		id = "challenge_loneliness_epidemic",
		title = "Deep Loneliness",
		emoji = "😔",
		text = "You're experiencing profound loneliness.",
		question = "How do you fight loneliness?",
		minAge = 15, maxAge = 100,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "mental_health",
		tags = { "loneliness", "isolation", "connection" },
		
		-- CRITICAL: Random loneliness outcome
		choices = {
			{
				text = "Reach out to others",
				effects = {},
				feedText = "Making an effort to connect...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Health", 3)
						state.Flags = state.Flags or {}
						state.Flags.connected = true
						state:AddFeed("😔 Found connection! People responded! Not alone anymore!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("😔 Some progress. One good conversation helped.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("😔 Reached out. Got rejected. Hurts more than isolation.")
					end
				end,
			},
			{ text = "Join community groups", effects = { Happiness = 6 }, feedText = "😔 Structured social opportunities. Finding your people." },
			{ text = "Get a pet ($200)", effects = { Money = -200, Happiness = 8 }, setFlags = { has_dog = true }, feedText = "😔 Unconditional love. Companion. Not alone anymore.", eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for pet" end },
			{ text = "Accept being alone", effects = { Happiness = 2, Smarts = 3 }, setFlags = { comfortable_alone = true }, feedText = "😔 Learning to enjoy your own company. Self-sufficient." },
		},
	},
	{
		id = "challenge_regret",
		title = "Living with Regret",
		emoji = "😢",
		text = "You're haunted by a major regret.",
		question = "How do you deal with regret?",
		minAge = 25, maxAge = 100,
		baseChance = 0.38,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "psychology",
		tags = { "regret", "past", "moving_on" },
		
		-- CRITICAL: Random regret processing
		choices = {
			{
				text = "Process and forgive yourself",
				effects = {},
				feedText = "Working through regret...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 4)
						state.Flags = state.Flags or {}
						state.Flags.self_forgiveness = true
						state:AddFeed("😢 Let it go. Past can't change. Present can. Peace found.")
					else
						state:ModifyStat("Happiness", 3)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("😢 Still hurts but accepting. Time helps heal.")
					end
				end,
			},
			{ text = "Try to make amends", effects = {}, feedText = "Reaching out to right wrongs...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("😢 Apology accepted. Closure. Burden lifted.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("😢 Not forgiven by others but tried. Did what you could.")
					end
				end,
			},
			{ text = "Use it as motivation", effects = { Happiness = 5, Smarts = 3 }, feedText = "😢 Channel regret into change. Be better now." },
		},
	},
	{
		id = "challenge_comparison_trap",
		title = "Comparison Trap",
		emoji = "📱",
		text = "You keep comparing yourself to others.",
		question = "How do you escape the comparison trap?",
		minAge = 13, maxAge = 70,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "psychology",
		tags = { "comparison", "social_media", "self_worth" },
		
		-- CRITICAL: Random comparison outcome
		choices = {
			{
				text = "Social media detox",
				effects = {},
				feedText = "Stepping away from screens...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Health", 2)
						state.Flags = state.Flags or {}
						state.Flags.social_media_healthy = true
						state:AddFeed("📱 Feel so much better! Comparison stopped! Present moment!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📱 Helped a bit. Old habits die hard. Keep trying.")
					end
				end,
			},
			{ text = "Focus on gratitude", effects = { Happiness = 6, Smarts = 2 }, feedText = "📱 What you HAVE, not what you lack. Perspective shift." },
			{ text = "Set personal goals", effects = { Happiness = 5, Smarts = 3 }, feedText = "📱 Only competition is past you. Personal growth focus." },
		},
	},
	{
		id = "challenge_perfectionism",
		title = "Perfectionism Paralysis",
		emoji = "🎯",
		text = "Perfectionism is preventing progress.",
		question = "How do you overcome perfectionism?",
		minAge = 15, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "psychology",
		tags = { "perfectionism", "progress", "mindset" },
		
		-- CRITICAL: Random perfectionism outcome
		choices = {
			{
				text = "Done is better than perfect",
				effects = {},
				feedText = "Shipping imperfect work...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.recovered_perfectionist = true
						state:AddFeed("🎯 IT'S GOOD ENOUGH! Released it! Nobody noticed flaws!")
					else
						state:ModifyStat("Happiness", 3)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🎯 Finished but anxiety about imperfections. Progress though!")
					end
				end,
			},
			{ text = "Small imperfections on purpose", effects = { Happiness = 5, Smarts = 2 }, feedText = "🎯 Embracing wabi-sabi. Beauty in imperfection." },
			{ text = "Stay stuck perfectionist", effects = { Happiness = -4 }, setFlags = { perfectionist = true }, feedText = "🎯 Can't release anything. Everything unfinished. Stuck." },
		},
	},
	{
		id = "challenge_procrastination",
		title = "Procrastination Battle",
		emoji = "⏰",
		text = "Procrastination is out of control.",
		question = "How do you beat procrastination?",
		minAge = 14, maxAge = 70,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "productivity",
		tags = { "procrastination", "productivity", "habits" },
		
		-- CRITICAL: Random procrastination outcome
		choices = {
			{
				text = "Use productivity techniques",
				effects = {},
				feedText = "Trying new systems...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.45 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 4)
						state.Flags = state.Flags or {}
						state.Flags.productive = true
						state:AddFeed("⏰ SYSTEM WORKS! Getting things done! Procrastination beaten!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("⏰ Some improvement. Technique helps sometimes.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("⏰ Procrastinated learning productivity systems. Ironic.")
					end
				end,
			},
			{ text = "Just start (2 minute rule)", effects = { Happiness = 5, Smarts = 2 }, feedText = "⏰ Starting was the hard part! Momentum built!" },
			{ text = "Accountability partner", effects = { Happiness = 5 }, feedText = "⏰ External accountability helps! Someone watching!" },
		},
	},
	{
		id = "challenge_people_pleasing",
		title = "People Pleasing Problem",
		emoji = "😊",
		text = "You can't stop saying yes to everyone.",
		question = "How do you set boundaries?",
		minAge = 15, maxAge = 80,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "psychology",
		tags = { "boundaries", "people_pleasing", "assertiveness" },
		
		-- CRITICAL: Random boundary setting outcome
		choices = {
			{
				text = "Practice saying no",
				effects = {},
				feedText = "Setting a boundary...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.has_boundaries = true
						state:AddFeed("😊 Said NO! World didn't end! They respected it! Freedom!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("😊 Said no but felt guilty. Boundary held though. Progress!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("😊 They got upset when you said no. Hard but necessary.")
					end
				end,
			},
			{ text = "Realize you can't please everyone", effects = { Happiness = 5, Smarts = 4 }, feedText = "😊 Lightbulb moment! Their happiness isn't your job!" },
			{ text = "Keep people pleasing", effects = { Happiness = -4, Health = -2 }, setFlags = { people_pleaser = true }, feedText = "😊 Said yes again. Overcommitted. Burned out." },
		},
	},
	{
		id = "challenge_trust_issues",
		title = "Trust Issues",
		emoji = "🔒",
		text = "You have trouble trusting people.",
		question = "How do you work on trust?",
		minAge = 16, maxAge = 80,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "psychology",
		tags = { "trust", "relationships", "healing" },
		
		-- CRITICAL: Random trust work outcome
		choices = {
			{
				text = "Take a small trust risk",
				effects = {},
				feedText = "Opening up a little...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.learning_to_trust = true
						state:AddFeed("🔒 They didn't betray you! Trust rewarded! Healing!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🔒 Small trust given. Nothing bad happened. Baby steps.")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.trust_issues = true
						state:AddFeed("🔒 They let you down. Trust issues confirmed. Walls up.")
					end
				end,
			},
			{ text = "Therapy for trust trauma ($100)", effects = { Money = -100, Happiness = 5, Smarts = 3 }, feedText = "🔒 Processing why trust is hard. Healing old wounds.", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for therapy" end },
			{ text = "Stay guarded", effects = { Happiness = -2 }, setFlags = { trust_issues = true }, feedText = "🔒 Walls stay up. Safe but lonely." },
		},
	},
	{
		id = "challenge_second_chance",
		title = "Second Chance",
		emoji = "🌅",
		text = "Life is offering you a second chance.",
		question = "Do you take the second chance?",
		minAge = 18, maxAge = 90,
		baseChance = 0.1,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "opportunity",
		tags = { "second_chance", "redemption", "opportunity" },
		
		-- CRITICAL: Random second chance outcome
		choices = {
			{
				text = "Take the opportunity",
				effects = {},
				feedText = "Seizing the second chance...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Smarts", 5)
						state.Flags = state.Flags or {}
						state.Flags.redeemed = true
						state:AddFeed("🌅 REDEMPTION! Made the most of second chance! New beginning!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("🌅 Making progress with second chance. Grateful for opportunity.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🌅 Second chance is harder than expected. Not giving up.")
					end
				end,
			},
			{ text = "Too scared to try again", effects = { Happiness = -4 }, feedText = "🌅 Passed on second chance. Fear won. Regret likely." },
		},
	},
	{
		id = "challenge_toxic_relationship_escape",
		title = "Escaping Toxic Relationship",
		emoji = "🚪",
		text = "You need to leave a toxic situation.",
		question = "How do you escape?",
		minAge = 16, maxAge = 80,
		baseChance = 0.1,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "relationships",
		tags = { "toxic", "escape", "freedom" },
		
		-- CRITICAL: Random escape outcome
		choices = {
			{
				text = "Make an exit plan",
				effects = { Money = -200 },
				feedText = "Carefully planning escape...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Health", 5)
						state.Flags = state.Flags or {}
						state.Flags.escaped_toxic = true
						state:AddFeed("🚪 FREE! Got out safely! New chapter begins! Relief!")
					else
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Health", 2)
						state:AddFeed("🚪 Getting out was messy but out! Healing can start.")
					end
				end,
			},
			{ text = "Get support to leave", effects = { Happiness = 8, Health = 3 }, setFlags = { escaped_toxic = true }, feedText = "🚪 Friends/family helped. Not alone. Support system saved you." },
			{ text = "Stay (it's complicated)", effects = { Happiness = -6, Health = -4 }, feedText = "🚪 Can't leave yet. Complicated. Survival mode continues." },
		},
	},
}

return LifeChallenges
