--[[
    Seasonal & Holiday Events
    Events related to seasons, holidays, and annual celebrations
    All events use randomized outcomes - NO god mode
]]

local SeasonalEvents = {}

local STAGE = "random"

SeasonalEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- WINTER EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "seasonal_winter_holiday",
		title = "Winter Holiday Season",
		emoji = "🎄",
		text = "The winter holiday season is here!",
		question = "How do you celebrate?",
		minAge = 5, maxAge = 100,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "holiday", "winter", "celebration" },
		
		-- CRITICAL: Random holiday outcome
		choices = {
			{
				text = "Big family celebration",
				effects = { Money = -200 },
				feedText = "Gathering with loved ones...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.holiday_memories = true
						state:AddFeed("🎄 MAGICAL! Best holiday ever! Love and joy everywhere!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🎄 Good times with family! Some stress but worth it!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🎄 Family drama ruined the mood. Holiday tensions.")
					end
				end,
			},
			{ text = "Quiet cozy celebration", effects = { Money = -50, Happiness = 10, Health = 2 }, feedText = "🎄 Peaceful holiday. No drama. Just warmth and comfort." },
			{ text = "Volunteer/give back", effects = { Happiness = 12, Money = -30 }, setFlags = { holiday_volunteer = true }, feedText = "🎄 Helping others made it meaningful! True spirit!" },
			{ text = "Working through the holidays", effects = { Happiness = -4, Money = 100 }, feedText = "🎄 Missed celebrations. Holiday pay but empty feeling." },
		},
	},
	{
		id = "seasonal_new_year",
		title = "New Year's Eve",
		emoji = "🎆",
		text = "New Year's Eve is here!",
		question = "How do you ring in the new year?",
		minAge = 10, maxAge = 100,
		baseChance = 0.5,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "new_year", "celebration", "resolutions" },
		
		-- CRITICAL: Random New Year's outcome
		choices = {
			{
				text = "Big party",
				effects = { Money = -50 },
				feedText = "Celebrating with the crowd...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.epic_new_year = true
						state:AddFeed("🎆 AMAZING NIGHT! Countdown was perfect! Great start to the year!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🎆 Fun party! Maybe too much champagne but good times!")
					else
						state:ModifyStat("Happiness", -2)
						state:ModifyStat("Health", -3)
						state:AddFeed("🎆 Rough morning. Maybe went too hard. Regrets.")
					end
				end,
			},
			{ text = "Intimate gathering", effects = { Happiness = 8, Money = -20 }, feedText = "🎆 Small circle, big laughs. Perfect way to end the year." },
			{ text = "Reflect and set intentions", effects = { Happiness = 6, Smarts = 3 }, setFlags = { has_resolutions = true }, feedText = "🎆 Mindful new year. Goals set. Feeling hopeful!" },
			{ text = "Asleep before midnight", effects = { Happiness = 4, Health = 3 }, feedText = "🎆 Slept through it. New year started with good rest!" },
		},
	},
	{
		id = "seasonal_winter_storm",
		title = "Winter Storm",
		emoji = "❄️",
		text = "A major winter storm is hitting!",
		question = "How do you handle being snowed in?",
		minAge = 5, maxAge = 100,
		baseChance = 0.45,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "weather",
		tags = { "winter", "storm", "weather" },
		
		-- CRITICAL: Random storm outcome
		choices = {
			{
				text = "Embrace the snow day",
				effects = {},
				feedText = "Stuck inside...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("❄️ SNOW DAY! Cozy inside! Hot chocolate and relaxation!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("❄️ Stuck inside. Cabin fever setting in. When will it stop?")
					end
				end,
			},
			{ text = "Shovel and brave it", effects = { Health = 3, Happiness = 4 }, feedText = "❄️ Got outside! Fresh air! Exercise! Winter warrior!" },
			{ text = "Power outage crisis", effects = { Happiness = -6, Health = -3, Money = -100 }, setFlags = { survived_storm = true }, feedText = "❄️ Lost power. Freezing and dark. Survival mode." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SPRING EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "seasonal_spring_cleaning",
		title = "Spring Cleaning",
		emoji = "🧹",
		text = "It's time for spring cleaning!",
		question = "How do you approach the deep clean?",
		minAge = 15, maxAge = 90,
		baseChance = 0.55,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "spring", "cleaning", "organization" },
		
		-- CRITICAL: Random cleaning outcome
		choices = {
			{
				text = "Full Marie Kondo mode",
				effects = {},
				feedText = "Decluttering everything...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 10)
						state.Money = (state.Money or 0) + 100
						state.Flags = state.Flags or {}
						state.Flags.organized_home = true
						state:AddFeed("🧹 SPARKS JOY! Donated/sold so much! House is perfect!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🧹 Made progress! Rooms look better! Feels good!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🧹 Made a bigger mess. Overwhelmed. Gave up halfway.")
					end
				end,
			},
			{ text = "Just the essentials", effects = { Happiness = 4 }, feedText = "🧹 Quick clean. Good enough. Not everything needs perfection." },
			{ text = "Hire cleaning help", effects = { Money = -100, Happiness = 8 }, feedText = "🧹 Professionals handled it! Worth every penny!" },
		},
	},
	{
		id = "seasonal_easter",
		title = "Easter/Spring Festival",
		emoji = "🐰",
		text = "Easter/Spring celebration time!",
		question = "How do you celebrate spring?",
		minAge = 3, maxAge = 100,
		baseChance = 0.555,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "easter", "spring", "celebration" },
		
		choices = {
			{ text = "Egg hunt fun", effects = { Happiness = 10 }, feedText = "🐰 Found the golden egg! Or watched kids find it! Joy!" },
			{ text = "Family brunch", effects = { Happiness = 8, Money = -40 }, feedText = "🐰 Beautiful spring brunch! Good food, good company!" },
			{ text = "Religious observance", effects = { Happiness = 6, Smarts = 1 }, feedText = "🐰 Meaningful spiritual celebration. Renewal." },
			{ text = "Just another Sunday", effects = { Happiness = 2 }, feedText = "🐰 Didn't celebrate. Quiet day off." },
		},
	},
	{
		id = "seasonal_allergies",
		title = "Allergy Season",
		emoji = "🤧",
		text = "Spring allergies are brutal this year!",
		question = "How do you survive allergy season?",
		minAge = 8, maxAge = 90,
		baseChance = 0.555,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "allergies", "spring", "health" },
		
		-- CRITICAL: Random allergy severity
		choices = {
			{
				text = "Antihistamines and push through",
				effects = { Money = -20 },
				feedText = "Medicating...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🤧 Meds working! Manageable allergies!")
					else
						state:ModifyStat("Happiness", -4)
						state:ModifyStat("Health", -2)
						state:AddFeed("🤧 Meds barely help. Miserable. When will pollen stop?")
					end
				end,
			},
			{ text = "Stay indoors", effects = { Happiness = 1, Health = 1 }, feedText = "🤧 Missing the nice weather but at least not sneezing." },
			{ text = "Natural remedies", effects = { Happiness = 4, Health = 2, Money = -30 }, feedText = "🤧 Local honey, neti pot, supplements. Actually helping!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SUMMER EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "seasonal_summer_vacation",
		title = "Summer Vacation",
		emoji = "☀️",
		text = "Summer vacation time!",
		question = "What's your summer adventure?",
		minAge = 5, maxAge = 90,
		baseChance = 0.55,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "summer", "vacation", "fun" },
		
		-- CRITICAL: Random summer outcome
		choices = {
			{
				-- CRITICAL FIX: Show price and add eligibility check
				text = "Beach vacation ($500)",
				effects = { Money = -500 },
				feedText = "Heading to the shore...",
				eligibility = function(state)
					if (state.Money or 0) < 500 then
						return false, "Can't afford $500 beach vacation"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Health", 3)
						state.Flags = state.Flags or {}
						state.Flags.beach_memories = true
						state:AddFeed("☀️ PERFECT BEACH TRIP! Sun, sand, relaxation!")
					else
						state:ModifyStat("Happiness", 8)
						state:AddFeed("☀️ Good trip! Sunburned but happy!")
					end
				end,
			},
			{ text = "Staycation ($50)", effects = { Happiness = 8, Money = -50, Health = 2 }, feedText = "☀️ Local exploration! Saved money, still relaxed!" },
			{ 
				-- CRITICAL FIX: Show price and add eligibility check
				text = "Summer camp/program ($300)", 
				effects = { Money = -300, Happiness = 10, Smarts = 3 }, 
				feedText = "☀️ Amazing summer experience! Made memories!",
				eligibility = function(state)
					if (state.Money or 0) < 300 then
						return false, "Can't afford $300 summer camp"
					end
					return true
				end,
			},
			{ text = "Working all summer", effects = { Happiness = -2, Money = 500 }, feedText = "☀️ No vacation. But bank account looking good." },
		},
	},
	{
		id = "seasonal_fourth_july",
		title = "Independence Day",
		emoji = "🎆",
		text = "Fourth of July celebrations!",
		question = "How do you celebrate?",
		minAge = 5, maxAge = 100,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "july_4th", "patriotic", "celebration" },
		
		choices = {
			{
				text = "Big BBQ party",
				effects = { Money = -50 },
				feedText = "Grilling and celebrating...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🎆 Great cookout! Fireworks were amazing!")
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎆 Fun party! A little too hot but good times!")
					end
				end,
			},
			{ text = "Watch fireworks", effects = { Happiness = 8 }, feedText = "🎆 Spectacular show! Colors lighting up the sky!" },
			{ text = "Quiet celebration", effects = { Happiness = 5, Health = 1 }, feedText = "🎆 Relaxing holiday. Avoided the crowds." },
		},
	},
	{
		id = "seasonal_heat_wave",
		title = "Heat Wave",
		emoji = "🥵",
		text = "Extreme heat wave hitting!",
		question = "How do you survive the heat?",
		minAge = 5, maxAge = 100,
		baseChance = 0.455,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "weather",
		tags = { "summer", "heat", "weather" },
		
		-- CRITICAL: Random heat wave outcome
		choices = {
			{
				text = "Stay inside with AC",
				effects = { Money = -50 },
				feedText = "Cranking the AC...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🥵 Survived! AC working overtime! Cool and comfortable!")
					else
						state:ModifyStat("Happiness", -4)
						state.Money = (state.Money or 0) - 100
						state:AddFeed("🥵 AC broke! Emergency repair! Suffering in the heat!")
					end
				end,
			},
			{ text = "Hit the pool/water", effects = { Happiness = 8, Health = 2, Money = -10 }, feedText = "🥵 Best idea ever! Cooling off in the water!" },
			{ text = "Suffer through it", effects = { Happiness = -6, Health = -4 }, feedText = "🥵 Miserable. So hot. When will it end?" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FALL EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "seasonal_halloween",
		title = "Halloween",
		emoji = "🎃",
		text = "Halloween is here!",
		question = "How do you celebrate spooky season?",
		minAge = 3, maxAge = 90,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "halloween", "spooky", "celebration" },
		
		-- CRITICAL: Random Halloween outcome
		choices = {
			{
				text = "Epic costume party",
				effects = { Money = -50 },
				feedText = "Showing off your costume...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					
					if roll < 0.55 then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.costume_winner = true
						state:AddFeed("🎃 BEST COSTUME! Everyone loved it! Party was amazing!")
					else
						state:ModifyStat("Happiness", 7)
						state:AddFeed("🎃 Fun party! Good costume vibes! Spooky good time!")
					end
				end,
			},
			{ text = "Hand out candy", effects = { Money = -30, Happiness = 6 }, feedText = "🎃 Cute trick-or-treaters! Spreading joy!" },
			{ text = "Haunted house/scary movies", effects = { Happiness = 8 }, feedText = "🎃 Terrified and loving it! Adrenaline rush!" },
			{ text = "Skip Halloween", effects = { Happiness = 2 }, feedText = "🎃 Not into it this year. Quiet night in." },
		},
	},
	{
		id = "seasonal_thanksgiving",
		title = "Thanksgiving",
		emoji = "🦃",
		text = "Thanksgiving is here!",
		question = "How do you celebrate Thanksgiving?",
		minAge = 5, maxAge = 100,
		baseChance = 0.45,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "thanksgiving", "family", "gratitude" },
		
		-- CRITICAL: Random Thanksgiving outcome
		choices = {
			{
				text = "Host the gathering",
				effects = { Money = -150 },
				feedText = "Cooking and hosting...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 12)
						state:AddFeed("🦃 FEAST SUCCESS! Turkey perfect! Everyone happy!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🦃 Good dinner! Some dishes were a miss but overall great!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🦃 Kitchen disasters. Stress. Family still had fun though.")
					end
				end,
			},
			{ text = "Be a guest", effects = { Happiness = 8, Money = -20 }, feedText = "🦃 Just showed up with pie! No cooking stress! Smart!" },
			{ text = "Friendsgiving", effects = { Happiness = 10, Money = -40 }, setFlags = { friendsgiving = true }, feedText = "🦃 Chosen family! No drama! Best Thanksgiving!" },
			{ text = "Volunteering", effects = { Happiness = 10 }, setFlags = { thanksgiving_volunteer = true }, feedText = "🦃 Serving others! True gratitude in action!" },
		},
	},
	{
		id = "seasonal_fall_activities",
		title = "Fall Activities",
		emoji = "🍂",
		text = "Perfect fall weather for activities!",
		question = "What fall activity do you do?",
		minAge = 5, maxAge = 90,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "fall", "autumn", "activities" },
		
		choices = {
			{ text = "Apple/pumpkin picking", effects = { Happiness = 8, Health = 2, Money = -25 }, feedText = "🍂 Fall harvest fun! Great photos! Seasonal joy!" },
			{ text = "Leaf peeping road trip", effects = { Happiness = 10, Money = -50 }, feedText = "🍂 Beautiful foliage! Nature's colors! Perfect drive!" },
			{ text = "Football game", effects = { Happiness = 8, Money = -30 }, feedText = "🍂 Game day! Team spirit! Fall vibes!" },
			{ text = "Cozy inside with PSL", effects = { Happiness = 6, Money = -5 }, feedText = "🍂 Basic but happy. Sweater weather perfection." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- BIRTHDAY EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "seasonal_birthday",
		title = "Your Birthday!",
		emoji = "🎂",
		text = "It's your birthday!",
		question = "How do you celebrate?",
		minAge = 5, maxAge = 100,
		baseChance = 0.5,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "milestone",
		tags = { "birthday", "celebration", "annual" },
		
		-- CRITICAL: Random birthday outcome
		choices = {
			{
				text = "Big party",
				effects = { Money = -100 },
				feedText = "Celebrating with friends and family...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.great_birthday = true
						state:AddFeed("🎂 BEST BIRTHDAY EVER! Felt so loved! Amazing celebration!")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🎂 Great party! Wonderful gifts! Good times!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🎂 Party was okay. Fewer people came than expected.")
					end
				end,
			},
			{ text = "Treat yourself day", effects = { Money = -75, Happiness = 10, Health = 2 }, feedText = "🎂 Self-care birthday! Spoiled yourself! Perfect day!" },
			{ text = "Quiet celebration", effects = { Happiness = 6, Money = -20 }, feedText = "🎂 Low key but nice. Cake and close ones." },
			{ text = "Work through it", effects = { Happiness = -4, Money = 50 }, feedText = "🎂 Forgot own birthday. Just another day. Sad." },
		},
	},
	{
		id = "seasonal_milestone_birthday",
		title = "Milestone Birthday",
		emoji = "🎉",
		text = "It's a big milestone birthday!",
		question = "How do you mark this milestone?",
		minAge = 18, maxAge = 100,
		baseChance = 0.55,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "milestone",
		tags = { "birthday", "milestone", "age" },
		
		choices = {
			{
				-- CRITICAL FIX: Show price and add eligibility check
				text = "Throw a huge party ($300)",
				effects = { Money = -300 },
				feedText = "Major celebration...",
				eligibility = function(state)
					if (state.Money or 0) < 300 then
						return false, "Can't afford $300 party"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 18)
						state.Flags = state.Flags or {}
						state.Flags.legendary_party = true
						state:AddFeed("🎉 EPIC MILESTONE PARTY! Everyone came! Memories for life!")
					else
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🎉 Great party! Some no-shows but still wonderful!")
					end
				end,
			},
			{ 
				-- CRITICAL FIX: Show price and add eligibility check
				text = "Big trip to celebrate ($500)", 
				effects = { Money = -500, Happiness = 15, Smarts = 2 }, 
				setFlags = { birthday_trip = true }, 
				feedText = "🎉 Dream destination for milestone! Treated yourself big!",
				eligibility = function(state)
					if (state.Money or 0) < 500 then
						return false, "Can't afford $500 birthday trip"
					end
					return true
				end,
			},
			{ text = "Crisis about getting older", effects = { Happiness = -6, Smarts = 3 }, feedText = "🎉 Existential dread. Where did the time go? Reflecting." },
			{ text = "Just another number", effects = { Happiness = 4 }, feedText = "🎉 Age is just a number. Not making a big deal." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- ANNIVERSARY EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "seasonal_anniversary",
		title = "Relationship Anniversary",
		emoji = "💕",
		text = "It's your anniversary!",
		question = "How do you celebrate your relationship?",
		minAge = 18, maxAge = 100,
		baseChance = 0.555,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "relationships",
		tags = { "anniversary", "romance", "celebration" },
		requiresPartner = true,
		-- CRITICAL FIX: Can't celebrate anniversary while in prison (unless it's a prison event variant)
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL: Random anniversary outcome
		choices = {
			{
				text = "Romantic dinner",
				effects = { Money = -100 },
				feedText = "Special dinner together...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.romantic_anniversary = true
						state:AddFeed("💕 PERFECT EVENING! So in love! Best anniversary!")
					else
						state:ModifyStat("Happiness", 7)
						state:AddFeed("💕 Nice dinner! Restaurant was packed but still romantic!")
					end
				end,
			},
			{ 
				-- CRITICAL FIX: Show price and add eligibility check
				text = "Weekend getaway ($300)", 
				effects = { Money = -300, Happiness = 15, Health = 2 }, 
				feedText = "💕 Couple's trip! Quality time! Relationship goals!",
				eligibility = function(state)
					if (state.Money or 0) < 300 then
						return false, "Can't afford $300 weekend getaway"
					end
					return true
				end,
			},
			{ text = "Forgot the anniversary", effects = { Happiness = -8 }, setFlags = { forgot_anniversary = true }, feedText = "💕 OH NO! Completely forgot! In the doghouse now!" },
			{ text = "Simple but meaningful", effects = { Happiness = 8, Money = -30 }, feedText = "💕 Thoughtful gift and quality time. Love isn't expensive." },
		},
	},
	{
		id = "seasonal_valentines",
		title = "Valentine's Day",
		emoji = "💝",
		text = "Valentine's Day is here!",
		question = "How do you handle Valentine's?",
		minAge = 13, maxAge = 100,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "valentines", "romance", "love" },
		
		-- CRITICAL: Random Valentine's outcome based on relationship status
		choices = {
			{
				text = "Romantic plans with partner",
				effects = { Money = -75 },
				feedText = "Valentine's date...",
				onResolve = function(state)
					local hasPartner = state.Flags and (state.Flags.married or state.Flags.engaged or state.Flags.dating_app_match)
					if not hasPartner then
						state:ModifyStat("Happiness", -4)
						state:AddFeed("💝 Single on Valentine's. Surrounded by couples. Lonely.")
						return
					end
					
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 12)
						state:AddFeed("💝 Best Valentine's ever! Romance is alive!")
					else
						state:ModifyStat("Happiness", 6)
						state:AddFeed("💝 Nice Valentine's! Commercial but sweet!")
					end
				end,
			},
			{ text = "Galentine's/Palentine's", effects = { Money = -20, Happiness = 8 }, feedText = "💝 Celebrated with friends! Who needs romance? Fun!" },
			{ text = "Self-love day", effects = { Money = -30, Happiness = 6, Health = 2 }, feedText = "💝 Treated yourself! Self-care is important!" },
			{ text = "Ignore it completely", effects = { Happiness = 2 }, feedText = "💝 Hallmark holiday. Didn't participate. Saved money." },
		},
	},
}

return SeasonalEvents
