--[[
    Special Moments Events
    Memorable and unique life moments
    All events use randomized outcomes - NO god mode
]]

local SpecialMoments = {}

local STAGE = "random"

SpecialMoments.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MILESTONE MOMENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "moment_first_car",
		title = "First Car",
		emoji = "🚗",
		text = "You're getting your first car!",
		question = "What kind of car do you get?",
		minAge = 16, maxAge = 30,
		baseChance = 0.2,
		cooldown = 10,
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "milestone",
		tags = { "car", "first", "milestone" },
		
		eligibility = function(state)
			local money = state.Money or 0
			local hasNoCar = not (state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0)
			-- CRITICAL FIX: Check for CHEAPEST choice cost ($500 parent help), not $500 arbitrary
			-- Also need to check flags for existing car ownership
			if state.Flags and (state.Flags.has_car or state.Flags.has_first_car or state.Flags.owns_car) then
				return false, "Already have a car"
			end
			if money < 500 or not hasNoCar then
				return false, "Already have a car or not enough money"
			end
			return true
		end,
		
		-- CRITICAL: Random first car outcome
		choices = {
			{
				text = "Buy a used beater",
				effects = { Money = -1500 },
				feedText = "Getting your first wheels...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.has_first_car = true
						state:AddFeed("🚗 FREEDOM! She's not pretty but she runs! First car love!")
					else
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.has_first_car = true
						state:AddFeed("🚗 It's a car! Needs work but yours! Independence!")
					end
				end,
			},
			{ text = "Reasonable reliable car", effects = { Money = -5000, Happiness = 10 }, setFlags = { has_first_car = true }, feedText = "🚗 Decent car! Should last years! Smart choice!" },
			{ text = "Parents help with car", effects = { Money = -500, Happiness = 10 }, setFlags = { has_first_car = true }, feedText = "🚗 Parents helped! Lucky! Grateful for the assist!" },
		},
	},
	{
		id = "moment_first_apartment",
		title = "First Apartment",
		emoji = "🏠",
		text = "Moving into your first place!",
		question = "What's the first apartment like?",
		minAge = 18, maxAge = 30,
		baseChance = 0.2,
		cooldown = 10,
		oneTime = true,
		stage = STAGE,
		ageBand = "young_adult",
		category = "milestone",
		tags = { "apartment", "moving", "independence" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 1000 then
				return false, "Need money for first/last month rent"
			end
			return true
		end,
		
		-- CRITICAL: Random first apartment outcome
		choices = {
			{
				text = "Sign the lease!",
				effects = { Money = -1500 },
				feedText = "Moving in...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.first_apartment = true
						state:AddFeed("🏠 YOUR OWN PLACE! Freedom! Adulting! Walking around naked!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.first_apartment = true
						state:AddFeed("🏠 It's small and has quirks but it's YOURS!")
					else
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.first_apartment = true
						state:AddFeed("🏠 Surprise roaches/issues but still proud! Independence!")
					end
				end,
			},
		},
	},
	{
		id = "moment_dream_achievement",
		title = "Dream Achievement",
		emoji = "⭐",
		text = "You achieved something you've always dreamed of!",
		question = "What dream did you achieve?",
		minAge = 15, maxAge = 100,
		baseChance = 0.08,
		cooldown = 10,
		stage = STAGE,
		ageBand = "any",
		category = "milestone",
		tags = { "dream", "achievement", "goal" },
		
		choices = {
			{ text = "Career dream realized", effects = { Happiness = 20, Smarts = 5, Money = 500 }, setFlags = { career_dream = true }, feedText = "⭐ DREAM JOB/ACHIEVEMENT! Years of work paid off! On top of the world!" },
			{ text = "Personal goal accomplished", effects = { Happiness = 18, Health = 5 }, setFlags = { personal_dream = true }, feedText = "⭐ Did what you set out to do! Proves anything is possible!" },
			{ text = "Creative dream fulfilled", effects = { Happiness = 18, Smarts = 3 }, setFlags = { creative_dream = true }, feedText = "⭐ Your art/creation is out there! Dream become reality!" },
			{ text = "Financial milestone hit", effects = { Happiness = 15, Money = 1000 }, setFlags = { financial_dream = true }, feedText = "⭐ Reached your money goal! Financial security feels amazing!" },
		},
	},
	{
		id = "moment_reconnection",
		title = "Long-Lost Reconnection",
		emoji = "🔗",
		text = "You reconnected with someone from your past!",
		question = "How does the reconnection go?",
		minAge = 20, maxAge = 100,
		baseChance = 0.1,
		cooldown = 6,
		stage = STAGE,
		ageBand = "any",
		category = "relationships",
		tags = { "reconnection", "past", "friends" },
		
		-- CRITICAL: Random reconnection outcome
		choices = {
			{
				text = "Catch up with them",
				effects = {},
				feedText = "Reconnecting with the past...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.reconnected_friend = true
						state:AddFeed("🔗 Like no time passed! Instant connection! So glad you found each other!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🔗 Nice to catch up! You've both changed. Still good to reconnect.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🔗 Awkward. You've grown in different directions. Bittersweet.")
					end
				end,
			},
		},
	},
	{
		id = "moment_surprise_party",
		title = "Surprise Party",
		emoji = "🎊",
		text = "SURPRISE! A party was thrown for you!",
		question = "How do you react?",
		minAge = 10, maxAge = 100,
		baseChance = 0.08,
		cooldown = 8,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "surprise", "party", "celebration" },
		
		choices = {
			{ text = "Genuinely surprised and happy", effects = { Happiness = 18 }, setFlags = { loved_surprise_party = true }, feedText = "🎊 ACTUALLY SURPRISED! Heart full! Feel so loved!" },
			{ text = "Overwhelmed but touched", effects = { Happiness = 10 }, feedText = "🎊 So many people! A lot to process! Grateful!" },
			{ text = "Knew it was coming", effects = { Happiness = 8 }, feedText = "🎊 Saw it coming but still appreciated! Bad poker face friends!" },
		},
	},
	{
		id = "moment_personal_best",
		title = "Personal Record",
		emoji = "🏆",
		text = "You achieved a personal best!",
		question = "What was your personal record?",
		minAge = 10, maxAge = 90,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "achievement",
		tags = { "personal_best", "achievement", "progress" },
		
		choices = {
			{ text = "Physical achievement", effects = { Happiness = 12, Health = 5 }, setFlags = { pb_physical = true }, feedText = "🏆 Fastest/longest/strongest ever! Body exceeded expectations!" },
			{ text = "Mental/learning achievement", effects = { Happiness = 10, Smarts = 5 }, setFlags = { pb_mental = true }, feedText = "🏆 Brain powered through! Learned/solved/mastered something!" },
			{ text = "Financial achievement", effects = { Happiness = 10, Money = 200 }, setFlags = { pb_financial = true }, feedText = "🏆 Money milestone! Saved/earned more than ever!" },
			{ text = "Social achievement", effects = { Happiness = 10, Looks = 2 }, setFlags = { pb_social = true }, feedText = "🏆 Social victory! Did something you never thought possible!" },
		},
	},
	{
		id = "moment_random_kindness",
		title = "Act of Kindness Received",
		emoji = "💝",
		text = "A stranger did something incredibly kind for you!",
		question = "What was the kind act?",
		minAge = 5, maxAge = 100,
		baseChance = 0.1,
		cooldown = 6,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "kindness", "strangers", "humanity" },
		
		choices = {
			{ text = "Paid for your meal/coffee", effects = { Happiness = 10, Money = 15 }, setFlags = { received_kindness = true }, feedText = "💝 Complete stranger! Restored faith in humanity!" },
			{ text = "Helped in time of need", effects = { Happiness = 12, Health = 2 }, feedText = "💝 Right person, right time! Angel in disguise!" },
			{ text = "Genuine words of encouragement", effects = { Happiness = 8, Smarts = 2 }, feedText = "💝 Exactly what you needed to hear! Universe sending messages!" },
			{ text = "Went out of their way", effects = { Happiness = 10 }, feedText = "💝 Such effort for a stranger! People CAN be amazing!" },
		},
	},
	{
		id = "moment_perfect_day",
		title = "One of Those Days",
		emoji = "✨",
		text = "Everything is going right today!",
		question = "What made today perfect?",
		minAge = 5, maxAge = 100,
		baseChance = 0.1,
		cooldown = 6,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "perfect_day", "luck", "joy" },
		
		choices = {
			{ text = "Everything aligned perfectly", effects = { Happiness = 15, Health = 3, Smarts = 2 }, setFlags = { had_perfect_day = true }, feedText = "✨ Magic day! When does this happen?! Savoring every moment!" },
			{ text = "Won at everything", effects = { Happiness = 14, Money = 100 }, feedText = "✨ Can't lose today! Everything going your way!" },
			{ text = "Perfectly peaceful", effects = { Happiness = 12, Health = 4 }, feedText = "✨ Nothing special but nothing wrong. Perfect contentment!" },
		},
	},
	{
		id = "moment_mentor_wisdom",
		title = "Mentor's Wisdom",
		emoji = "🧙",
		text = "Someone wise shared life-changing advice!",
		question = "What wisdom did they share?",
		minAge = 15, maxAge = 100,
		baseChance = 0.12,
		cooldown = 6,
		stage = STAGE,
		ageBand = "any",
		category = "growth",
		tags = { "wisdom", "mentor", "advice" },
		
		choices = {
			{ text = "Career guidance", effects = { Happiness = 8, Smarts = 5, Money = 100 }, setFlags = { career_mentored = true }, feedText = "🧙 Career path cleared! Mentor wisdom! Years of experience condensed!" },
			{ text = "Life perspective", effects = { Happiness = 10, Smarts = 4 }, setFlags = { life_wisdom = true }, feedText = "🧙 Changed how you see everything! Paradigm shift! Enlightened!" },
			{ text = "Relationship advice", effects = { Happiness = 8, Smarts = 3 }, feedText = "🧙 Understanding people better now! Social wisdom unlocked!" },
			{ text = "Personal challenge guidance", effects = { Happiness = 10, Health = 2 }, feedText = "🧙 Exactly what you needed to hear! They understood!" },
		},
	},
	{
		id = "moment_standing_ovation",
		title = "Standing Ovation",
		emoji = "👏",
		text = "You got a standing ovation!",
		question = "What did you do to earn it?",
		minAge = 10, maxAge = 100,
		baseChance = 0.05,
		cooldown = 10,
		stage = STAGE,
		ageBand = "any",
		category = "achievement",
		tags = { "ovation", "recognition", "performance" },
		
		choices = {
			{ text = "Performance/presentation", effects = { Happiness = 20, Looks = 3, Smarts = 2 }, setFlags = { standing_ovation = true }, feedText = "👏 STANDING OVATION! Nailed it! Crowd on their feet! Peak moment!" },
			{ text = "Speech/speaking", effects = { Happiness = 18, Smarts = 4 }, feedText = "👏 Your words moved people! Connected deeply! Impact!" },
			{ text = "Achievement recognition", effects = { Happiness = 18, Money = 200 }, feedText = "👏 Recognized for your work! Applause well earned!" },
		},
	},
	{
		id = "moment_last_goodbye",
		title = "Meaningful Goodbye",
		emoji = "👋",
		text = "You had to say an important goodbye.",
		question = "How do you handle the farewell?",
		minAge = 10, maxAge = 100,
		baseChance = 0.1,
		cooldown = 6,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "goodbye", "farewell", "closure" },
		
		-- CRITICAL: Random goodbye outcome
		choices = {
			{
				text = "Express everything you feel",
				effects = {},
				feedText = "Saying your goodbye...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.had_closure = true
						state:AddFeed("👋 Said everything. Nothing left unsaid. Closure.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("👋 Emotional. Hard to find the words. Hope they understood.")
					end
				end,
			},
			{ text = "Promise to keep in touch", effects = { Happiness = 4 }, feedText = "👋 This isn't goodbye forever. See you again someday." },
			{ text = "Struggle to let go", effects = { Happiness = -6 }, feedText = "👋 Didn't want to say goodbye. Harder than expected." },
		},
	},
	{
		id = "moment_unexpected_inheritance",
		title = "Unexpected Inheritance",
		emoji = "💰",
		text = "You received an unexpected inheritance!",
		question = "What did you inherit?",
		minAge = 18, maxAge = 100,
		baseChance = 0.05,
		cooldown = 10,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "inheritance", "money", "surprise" },
		
		-- CRITICAL: Random inheritance amount
		choices = {
			{
				text = "Open the letter/call",
				effects = {},
				feedText = "Learning about the inheritance...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.15 then
						state.Money = (state.Money or 0) + 50000
						state:ModifyStat("Happiness", 20)
						state.Flags = state.Flags or {}
						state.Flags.major_inheritance = true
						state:AddFeed("💰 LIFE-CHANGING! Major inheritance! $50,000! Shocked!")
					elseif roll < 0.40 then
						state.Money = (state.Money or 0) + 10000
						state:ModifyStat("Happiness", 15)
						state:AddFeed("💰 Substantial inheritance! $10,000! Grateful!")
					elseif roll < 0.70 then
						state.Money = (state.Money or 0) + 2000
						state:ModifyStat("Happiness", 10)
						state:AddFeed("💰 Nice inheritance! $2,000! Unexpected windfall!")
					else
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💰 Inherited sentimental items. Not money but meaningful.")
					end
				end,
			},
		},
	},
	{
		id = "moment_life_flashing",
		title = "Near-Miss Experience",
		emoji = "😱",
		text = "You had a close call that made you think about everything!",
		question = "How do you process the near-miss?",
		minAge = 16, maxAge = 100,
		baseChance = 0.08,
		cooldown = 8,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "near_miss", "perspective", "life" },
		
		choices = {
			{ text = "Grateful to be alive", effects = { Happiness = 8, Health = 2, Smarts = 3 }, setFlags = { near_death_perspective = true }, feedText = "😱 Life is precious! Taking nothing for granted! Changed!" },
			{ text = "Anxiety about mortality", effects = { Happiness = -5, Smarts = 2 }, setFlags = { mortality_anxiety = true }, feedText = "😱 Can't stop thinking about it. Existential crisis mode." },
			{ text = "Make immediate life changes", effects = { Happiness = 6, Smarts = 4 }, feedText = "😱 Wake-up call! Reprioritizing everything! No more wasting time!" },
			{ text = "Shake it off", effects = { Happiness = 3 }, feedText = "😱 That was scary. Moving on. Life goes on." },
		},
	},
	{
		id = "moment_found_passion",
		title = "Discovered Your Passion",
		emoji = "❤️‍🔥",
		text = "You discovered something you're truly passionate about!",
		question = "What's your new passion?",
		minAge = 10, maxAge = 90,
		baseChance = 0.1,
		cooldown = 8,
		stage = STAGE,
		ageBand = "any",
		category = "growth",
		tags = { "passion", "discovery", "purpose" },
		
		choices = {
			{ text = "Creative pursuit", effects = { Happiness = 15, Smarts = 3 }, setFlags = { found_creative_passion = true }, feedText = "❤️‍🔥 Art/music/writing! Something clicks! This is it!" },
			{ text = "Cause/advocacy", effects = { Happiness = 12, Smarts = 4 }, setFlags = { found_cause = true }, feedText = "❤️‍🔥 Found something worth fighting for! Purpose!" },
			{ text = "Hobby/activity", effects = { Happiness = 12, Health = 3 }, setFlags = { found_hobby_passion = true }, feedText = "❤️‍🔥 This is what I want to do! Joy found!" },
			{ text = "Career calling", effects = { Happiness = 14, Smarts = 5, Money = 100 }, setFlags = { found_calling = true }, feedText = "❤️‍🔥 This is what I'm meant to do! Career clarity!" },
		},
	},
	{
		id = "moment_forgiveness_given",
		title = "Giving Forgiveness",
		emoji = "🕊️",
		text = "You found it in your heart to forgive someone.",
		question = "How do you feel after forgiving?",
		minAge = 12, maxAge = 100,
		baseChance = 0.1,
		cooldown = 6,
		stage = STAGE,
		ageBand = "any",
		category = "growth",
		tags = { "forgiveness", "healing", "peace" },
		
		choices = {
			{ text = "Weight lifted", effects = { Happiness = 12, Health = 3, Smarts = 3 }, setFlags = { forgave_someone = true }, feedText = "🕊️ Let it go. Forgiveness for YOU not them. Free now!" },
			{ text = "Still processing", effects = { Happiness = 5, Smarts = 2 }, feedText = "🕊️ Forgave but won't forget. Boundaries remain." },
			{ text = "Rekindled relationship", effects = { Happiness = 10 }, feedText = "🕊️ Forgiveness led to reconciliation. Healing together." },
		},
	},
	{
		id = "moment_forgiveness_received",
		title = "Receiving Forgiveness",
		emoji = "🙏",
		text = "Someone you wronged has forgiven you.",
		question = "How do you feel about being forgiven?",
		minAge = 12, maxAge = 100,
		baseChance = 0.08,
		cooldown = 6,
		stage = STAGE,
		ageBand = "any",
		category = "growth",
		tags = { "forgiveness", "redemption", "relief" },
		
		choices = {
			{ text = "Profound relief", effects = { Happiness = 15, Health = 3 }, setFlags = { was_forgiven = true }, feedText = "🙏 FORGIVEN! Guilt lifted! Can move forward! Grateful!" },
			{ text = "Commit to being better", effects = { Happiness = 10, Smarts = 4 }, feedText = "🙏 Second chance. Won't waste it. Growth from mistakes." },
			{ text = "Don't deserve it", effects = { Happiness = 5 }, feedText = "🙏 Their grace exceeds my worth. Humbled. Learning." },
		},
	},
}

return SpecialMoments
