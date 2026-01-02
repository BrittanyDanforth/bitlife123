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
		baseChance = 0.45,
		cooldown = 4,
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
		-- CRITICAL FIX: Actually add cars to Assets so they show in AssetScreen!
		choices = {
			{
				text = "Buy a used beater ($1,500)",
				effects = { Money = -1500 },
				feedText = "Getting your first wheels...",
				-- BUG FIX #12: Add eligibility check for car purchase
				eligibility = function(state) return (state.Money or 0) >= 1500, "💸 Can't afford car ($1,500 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					-- CRITICAL FIX: Add car to Assets!
					state.Assets = state.Assets or {}
					state.Assets.Vehicles = state.Assets.Vehicles or {}
					table.insert(state.Assets.Vehicles, {
						id = "first_car_beater_" .. tostring(os.time()),
						name = "Used Beater",
						emoji = "🚗",
						price = 1500,
						value = 1500,
						condition = roll < 0.55 and 65 or 45,
						happiness = 3,
						maintenance = 500,
						acquiredAge = state.Age,
						type = "sedan",
					})
					state.Flags = state.Flags or {}
					state.Flags.has_first_car = true
					state.Flags.has_car = true
					state.Flags.has_vehicle = true
					if roll < 0.55 then
						state:ModifyStat("Happiness", 12)
						state:AddFeed("🚗 FREEDOM! She's not pretty but she runs! First car love!")
					else
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🚗 It's a car! Needs work but yours! Independence!")
					end
				end,
			},
			{ 
				text = "Reasonable reliable car ($5,000)", 
				effects = { Money = -5000, Happiness = 10 }, 
				setFlags = { has_first_car = true, has_car = true, has_vehicle = true }, 
				feedText = "🚗 Decent car! Should last years! Smart choice!",
				-- BUG FIX #13: Add eligibility check for car purchase
				eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Can't afford car ($5,000 needed)" end,
				-- CRITICAL FIX: Add car to Assets!
				onResolve = function(state)
					state.Assets = state.Assets or {}
					state.Assets.Vehicles = state.Assets.Vehicles or {}
					table.insert(state.Assets.Vehicles, {
						id = "first_car_reliable_" .. tostring(os.time()),
						name = "Reliable Sedan",
						emoji = "🚗",
						price = 5000,
						value = 5000,
						condition = 80,
						happiness = 4,
						maintenance = 300,
						acquiredAge = state.Age,
						type = "sedan",
					})
				end,
			},
			{ 
				text = "Parents help with car ($500)", 
				effects = { Money = -500, Happiness = 10 }, 
				setFlags = { has_first_car = true, has_car = true, has_vehicle = true }, 
				feedText = "🚗 Parents helped! Lucky! Grateful for the assist!",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Can't afford ($500 needed)" end,
				-- CRITICAL FIX: Add car to Assets!
				onResolve = function(state)
					state.Assets = state.Assets or {}
					state.Assets.Vehicles = state.Assets.Vehicles or {}
					table.insert(state.Assets.Vehicles, {
						id = "first_car_gift_" .. tostring(os.time()),
						name = "Hand-Me-Down Car",
						emoji = "🚗",
						price = 500,
						value = 2500, -- Worth more than you paid
						condition = 60,
						happiness = 4,
						maintenance = 400,
						acquiredAge = state.Age,
						type = "sedan",
						wasGift = true,
					})
				end,
			},
			{
				text = "Not ready for a car yet",
				effects = { Happiness = -2 },
				feedText = "🚗 Maybe someday. Public transit works for now.",
			},
		},
	},
	{
		id = "moment_first_apartment",
		title = "First Apartment",
		emoji = "🏠",
		text = "Moving into your first place!",
		question = "What's the first apartment like?",
		minAge = 18, maxAge = 30,
		baseChance = 0.45,
		cooldown = 4,
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
				text = "Sign the lease ($1,500 deposit)",
				effects = { Money = -1500 },
				feedText = "Moving in...",
				-- BUG FIX #14: Add eligibility check for apartment deposit
				eligibility = function(state) return (state.Money or 0) >= 1500, "💸 Can't afford deposit ($1,500 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.first_apartment = true
						state:AddFeed("🏠 YOUR OWN PLACE! Freedom! Adulting! Your own rules!")
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
			{
				text = "Stay with family for now",
				effects = { Happiness = -3 },
				feedText = "🏠 Not ready yet. Saving up makes more sense.",
				-- CRITICAL FIX: Can't stay with family if parents are dead!
				eligibility = function(state)
					local flags = state.Flags or {}
					if flags.orphan or flags.lost_both_parents then
						return false, "Your parents have passed away"
					end
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
			},
			{
				-- CRITICAL FIX: Add cheaper roommate option to prevent hard lock!
				text = "Find a cheap room with roommates ($500)",
				effects = { Money = -500, Happiness = 5 },
				feedText = "🏠 Split rent with others. Not ideal but affordable!",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for first month" end,
				setFlags = { first_apartment = true, has_roommates = true },
			},
			{
				-- CRITICAL FIX: Always-available free option to prevent hard lock!
				text = "Keep looking for cheaper options",
				effects = { Happiness = -2 },
				feedText = "🏠 Housing market is rough. Still searching...",
			},
		},
	},
	{
		id = "moment_dream_achievement",
		title = "Dream Achievement",
		emoji = "⭐",
		text = "You achieved something you've always dreamed of!",
		-- CRITICAL FIX: NO question - this should auto-determine based on career/life!
		minAge = 30, maxAge = 100,
		baseChance = 0.12, -- Reduced - dreams are RARE
		cooldown = 15, -- Can't achieve multiple dreams quickly
		stage = STAGE,
		ageBand = "adult",
		category = "milestone",
		tags = { "dream", "achievement", "goal" },
		oneTime = true,
		maxOccurrences = 1,
		
		-- CRITICAL FIX: Must have ACTUAL accomplishments!
		eligibility = function(state)
			local flags = state.Flags or {}
			local money = state.Money or 0
			local hasJob = state.CurrentJob ~= nil
			local age = state.Age or 0
			
			if age < 30 then return false end
			
			-- Need significant accomplishments
			local hasAccomplishment = (hasJob and money >= 100000)
				or flags.promoted 
				or flags.got_degree 
				or flags.started_business
				or flags.famous
				or flags.wealthy
				or flags.successful_career
				or flags.published_author
				or flags.award_winner
				or flags.nfl_drafted or flags.nba_drafted
				or flags.championship_winner
				or flags.military_decorated
			
			return hasAccomplishment
		end,
		
		-- CRITICAL FIX: Single choice - auto-determines dream based on career!
		choices = {
			{
				text = "Celebrate this achievement!",
				effects = { Happiness = 25 },
				feedText = "Dreams DO come true!",
				onResolve = function(state)
					local flags = state.Flags or {}
					local job = state.CurrentJob
					local dreamText = ""
					local bonus = 0
					
					-- Auto-determine dream based on actual career/life!
					if flags.nfl_drafted or flags.nba_drafted or flags.pro_athlete then
						dreamText = "⭐ DREAM REALIZED: You made it to the big leagues! All those years of training paid off!"
						bonus = 10000
						flags.athlete_dream_achieved = true
					elseif flags.military_decorated or (job and job.category == "military") then
						dreamText = "⭐ DREAM REALIZED: You served your country with distinction! A true patriot!"
						bonus = 5000
						flags.military_dream_achieved = true
					elseif flags.famous or flags.celebrity then
						dreamText = "⭐ DREAM REALIZED: You became famous! People know your name!"
						bonus = 15000
						flags.fame_dream_achieved = true
					elseif flags.started_business or flags.entrepreneur then
						dreamText = "⭐ DREAM REALIZED: Your business succeeded! You're your own boss!"
						bonus = 20000
						flags.business_dream_achieved = true
					elseif flags.got_degree or flags.phd then
						dreamText = "⭐ DREAM REALIZED: Your education goals achieved! Knowledge is power!"
						bonus = 3000
						flags.education_dream_achieved = true
					elseif (state.Money or 0) >= 500000 then
						dreamText = "⭐ DREAM REALIZED: Financial freedom achieved! You made it!"
						bonus = 0
						flags.wealth_dream_achieved = true
					elseif job then
						dreamText = "⭐ DREAM REALIZED: You built a successful career as a " .. (job.name or "professional") .. "!"
						bonus = 5000
						flags.career_dream_achieved = true
					else
						dreamText = "⭐ DREAM REALIZED: You accomplished something meaningful in life!"
						bonus = 2500
						flags.personal_dream_achieved = true
					end
					
					state.Money = (state.Money or 0) + bonus
					state:ModifyStat("Happiness", 25)
					state.Flags = flags
					
					if bonus > 0 then
						state:AddFeed(dreamText .. " (+$" .. bonus .. " recognition bonus!)")
					else
						state:AddFeed(dreamText)
					end
				end,
			},
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.32,
		cooldown = 3,
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
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.38,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.25,
		cooldown = 4,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.25,
		cooldown = 4,
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
		baseChance = 0.32,
		cooldown = 3,
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
		-- CRITICAL FIX: Added text variations for more variety!
		textVariants = {
			"Something just CLICKED. You can't stop thinking about this!",
			"You found it! The thing that makes you feel ALIVE!",
			"Hours fly by when you do this. You've found your calling!",
			"Everyone notices how happy you are when doing this!",
			"This isn't just a hobby - it's who you ARE!",
		},
		question = "What's your new passion?",
		minAge = 10, maxAge = 90,
		baseChance = 0.1,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "growth",
		tags = { "passion", "discovery", "purpose" },
		
		-- MAX 5 CHOICES as requested
		choices = {
			{ text = "💻 Coding and technology!", effects = { Happiness = 15, Smarts = 5 }, setFlags = { found_tech_passion = true, loves_coding = true }, feedText = "❤️‍🔥 CODE IS POETRY! You see solutions everywhere!" },
			{ text = "🎮 Gaming and streaming!", effects = { Happiness = 14, Smarts = 2 }, setFlags = { found_gaming_passion = true, loves_gaming = true }, feedText = "❤️‍🔥 Gaming is more than fun - it's your IDENTITY!" },
			{ text = "💪 Fitness and health!", effects = { Happiness = 12, Health = 8 }, setFlags = { found_fitness_passion = true, fitness_focused = true }, feedText = "❤️‍🔥 Your body is a temple! Fitness is freedom!" },
			{ text = "🎵 Music and performing!", effects = { Happiness = 15, Looks = 3 }, setFlags = { found_music_passion = true, loves_music = true }, feedText = "❤️‍🔥 Music is your LANGUAGE! The stage awaits!" },
			{ text = "🌍 Helping my community!", effects = { Happiness = 12, Smarts = 4 }, setFlags = { found_cause = true, community_focused = true }, feedText = "❤️‍🔥 Making a DIFFERENCE is your purpose!" },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.32,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
