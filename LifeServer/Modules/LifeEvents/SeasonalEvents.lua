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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "holiday", "winter", "celebration" },
		
		-- CRITICAL: Random holiday outcome
		choices = {
		{
			text = "Big family celebration ($200)",
			effects = { Money = -200 },
			feedText = "Gathering with loved ones...",
			eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for celebration" end,
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
		{ text = "Quiet cozy celebration ($50)", effects = { Money = -50, Happiness = 10, Health = 2 }, feedText = "🎄 Peaceful holiday. No drama. Just warmth and comfort.", eligibility = function(state) return (state.Money or 0) >= 50, "Can't afford this" end },
		{ text = "Volunteer/give back ($30)", effects = { Happiness = 12, Money = -30 }, setFlags = { holiday_volunteer = true }, feedText = "🎄 Helping others made it meaningful! True spirit!", eligibility = function(state) return (state.Money or 0) >= 30, "Can't afford donation" end },
			{ text = "Working through the holidays", effects = { Happiness = -4, Money = 100 }, feedText = "🎄 Missed celebrations. Holiday pay but empty feeling.", eligibility = function(state) return state.CurrentJob ~= nil, "You don't have a job" end },
			{ text = "Simple celebration at home", effects = { Happiness = 6 }, feedText = "🎄 Low-key but nice. Watched movies and relaxed." },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "new_year", "celebration", "resolutions" },
		
		-- CRITICAL: Random New Year's outcome
		choices = {
		{
			text = "Big party ($50)",
			effects = { Money = -50 },
			feedText = "Celebrating with the crowd...",
			eligibility = function(state) return (state.Money or 0) >= 50, "Can't afford party" end,
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
			{ text = "Intimate gathering ($20)", effects = { Happiness = 8, Money = -20 }, feedText = "🎆 Small circle, big laughs. Perfect way to end the year.", eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20" end },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
			{ text = "Power outage crisis", effects = { Happiness = -6, Health = -3 }, setFlags = { survived_storm = true }, feedText = "❄️ Lost power. Freezing and dark. Survival mode." },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		{ text = "Hire cleaning help ($100)", effects = { Money = -100, Happiness = 8 }, feedText = "🧹 Professionals handled it! Worth every penny!", eligibility = function(state) return (state.Money or 0) >= 100, "Can't afford cleaners" end },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "easter", "spring", "celebration" },
		
	choices = {
		{ text = "Egg hunt fun", effects = { Happiness = 10 }, feedText = "🐰 Found the golden egg! Or watched kids find it! Joy!" },
		{ text = "Family brunch ($40)", effects = { Happiness = 8, Money = -40 }, feedText = "🐰 Beautiful spring brunch! Good food, good company!", eligibility = function(state) return (state.Money or 0) >= 40, "Can't afford brunch" end },
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
		-- CRITICAL FIX: Changed "Antihistamines" to "allergy medicine" - kid-friendly language!
		choices = {
			{
				text = "Take allergy medicine ($20)",
				effects = { Money = -20 },
				feedText = "Taking medicine...",
				eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20 for medicine" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🤧 Medicine working! Feeling much better!")
					else
						state:ModifyStat("Happiness", -4)
						state:ModifyStat("Health", -2)
						state:AddFeed("🤧 Medicine barely helps. Still sneezing. Ugh!")
					end
				end,
			},
			{ text = "Stay indoors", effects = { Happiness = 1, Health = 1 }, feedText = "🤧 Missing the nice weather but at least not sneezing." },
			{ text = "Try home remedies ($30)", effects = { Happiness = 4, Health = 2, Money = -30 }, feedText = "🤧 Honey, tea, and rest. Actually helping!", eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30" end },
			{ text = "Just deal with it", effects = { Happiness = -2, Health = -1 }, feedText = "🤧 Sneezing and miserable but saving money." },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
			{ text = "Staycation ($50)", effects = { Happiness = 8, Money = -50, Health = 2 }, feedText = "☀️ Local exploration! Saved money, still relaxed!", eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50" end },
		{ text = "Enjoy local parks", effects = { Happiness = 6, Health = 2 }, feedText = "☀️ Free fun in the sun! Parks and picnics!" },
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
			{ text = "Working all summer", effects = { Happiness = -2, Money = 500 }, feedText = "☀️ No vacation. But bank account looking good.", eligibility = function(state) return state.CurrentJob ~= nil, "You need a job first" end },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "july_4th", "patriotic", "celebration" },
		
	choices = {
		{
			text = "Big BBQ party ($50)",
			effects = { Money = -50 },
			feedText = "Grilling and celebrating...",
			eligibility = function(state) return (state.Money or 0) >= 50, "Can't afford BBQ" end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "weather",
		tags = { "summer", "heat", "weather" },
		
		-- CRITICAL: Random heat wave outcome
		choices = {
			{
				text = "Stay inside with AC ($50)",
				effects = { Money = -50 },
				feedText = "Cranking the AC...",
				eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 for AC" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						if state.ModifyStat then state:ModifyStat("Happiness", 4) end
						if state.AddFeed then state:AddFeed("🥵 Survived! AC working overtime! Cool and comfortable!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -4) end
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 100)
						if state.AddFeed then state:AddFeed("🥵 AC broke! Emergency repair! Suffering in the heat!") end
					end
				end,
			},
			{ text = "Hit the pool/water ($10)", effects = { Happiness = 8, Health = 2, Money = -10 }, feedText = "🥵 Best idea ever! Cooling off in the water!", eligibility = function(state) return (state.Money or 0) >= 10, "💸 Need $10" end },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "halloween", "spooky", "celebration" },
		
		-- CRITICAL FIX: Age-appropriate Halloween choices!
		-- Kids go trick-or-treating, adults hand out candy
		getDynamicChoices = function(state)
			local age = state.Age or 10
			local money = state.Money or 0
			local choices = {}
			
			if age <= 17 then
				-- KIDS: Trick-or-treating is FREE and the main activity!
				table.insert(choices, {
					text = "Go trick-or-treating! 🍬",
					effects = { Happiness = 10 },
					feedText = "🎃 CANDY HAUL! Best Halloween ever! So much candy!",
				})
				table.insert(choices, {
					text = "Epic costume party with friends",
					effects = { Happiness = 8 },
					feedText = "🎃 Awesome party! Everyone loved our costumes!",
				})
				table.insert(choices, {
					text = "Scary movie marathon",
					effects = { Happiness = 6 },
					feedText = "🎃 Spooky movie night! Screamed so much!",
				})
			else
				-- ADULTS: Different activities
				if money >= 50 then
					table.insert(choices, {
						text = "Throw a Halloween party ($50)",
						effects = { Money = -50, Happiness = 12 },
						feedText = "🎃 EPIC PARTY! Best costumes! Everyone had a blast!",
					})
				end
				if money >= 30 then
					table.insert(choices, {
						text = "Hand out candy to kids ($30)",
						effects = { Money = -30, Happiness = 8 },
						feedText = "🎃 Adorable trick-or-treaters! Spreading Halloween joy!",
					})
				end
				table.insert(choices, {
					text = "Haunted house adventure",
					effects = { Happiness = 7 },
					feedText = "🎃 Terrified and loved it! Heart still racing!",
				})
				table.insert(choices, {
					text = "Horror movie marathon",
					effects = { Happiness = 5 },
					feedText = "🎃 Scary movies all night! Perfect spooky vibes!",
				})
			end
			
			-- Everyone can skip
			table.insert(choices, {
				text = "Skip Halloween",
				effects = { Happiness = 2 },
				feedText = "🎃 Not feeling it this year. Quiet night in.",
			})
			
			return choices
		end,
		
		choices = {
			-- Fallback choices if getDynamicChoices fails
			{ text = "Go trick-or-treating! 🍬", effects = { Happiness = 10 }, feedText = "🎃 CANDY HAUL! Best Halloween ever!" },
			{ text = "Scary movie marathon", effects = { Happiness = 6 }, feedText = "🎃 Spooky movies all night!" },
			{ text = "Skip Halloween", effects = { Happiness = 2 }, feedText = "🎃 Not into it this year." },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "thanksgiving", "family", "gratitude" },
		
		-- CRITICAL: Random Thanksgiving outcome
		choices = {
			{
				text = "Host the gathering ($150)",
				effects = { Money = -150 },
				feedText = "Cooking and hosting...",
				eligibility = function(state) return (state.Money or 0) >= 150, "💸 Need $150 to host" end,
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
			{ text = "Be a guest ($20)", effects = { Happiness = 8, Money = -20 }, feedText = "🦃 Just showed up with pie! No cooking stress! Smart!", eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20 for pie" end },
			{ text = "Friendsgiving ($40)", effects = { Happiness = 10, Money = -40 }, setFlags = { friendsgiving = true }, feedText = "🦃 Chosen family! No drama! Best Thanksgiving!", eligibility = function(state) return (state.Money or 0) >= 40, "💸 Need $40" end },
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
		{ text = "Apple/pumpkin picking ($25)", effects = { Happiness = 8, Health = 2, Money = -25 }, feedText = "🍂 Fall harvest fun! Great photos! Seasonal joy!", eligibility = function(state) return (state.Money or 0) >= 25, "💸 Need $25 for picking trip" end },
		{ text = "Scenic nature walk", effects = { Happiness = 8, Health = 3 }, feedText = "🍂 Beautiful foliage! Nature's colors! Perfect walk!" },
		{ text = "Football game ($30)", effects = { Happiness = 8, Money = -30 }, feedText = "🍂 Game day! Team spirit! Fall vibes!", eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30 for tickets" end },
		{ text = "Cozy inside with hot cocoa", effects = { Happiness = 6 }, feedText = "🍂 Warm and happy. Sweater weather perfection." },
		{ text = "Enjoy the crisp fall air", effects = { Happiness = 5, Health = 1 }, feedText = "🍂 Crisp air and changing leaves. Simple fall vibes." },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "milestone",
		tags = { "birthday", "celebration", "annual" },
		
		-- CRITICAL: Random birthday outcome
		choices = {
			{
				text = "Big party ($100)",
				effects = { Money = -100 },
				feedText = "Celebrating with friends and family...",
				eligibility = function(state) return (state.Money or 0) >= 100, "Can't afford party" end,
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
			{ text = "Treat yourself day ($75)", effects = { Money = -75, Happiness = 10, Health = 2 }, feedText = "🎂 Self-care birthday! Spoiled yourself! Perfect day!", eligibility = function(state) return (state.Money or 0) >= 75, "💸 Need $75" end },
			{ text = "Quiet celebration ($20)", effects = { Happiness = 6, Money = -20 }, feedText = "🎂 Low key but nice. Cake and close ones.", eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20" end },
			{ text = "Just enjoy your day", effects = { Happiness = 4 }, feedText = "🎂 Simple but nice. Birthday vibes." },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
				text = "Romantic dinner ($100)",
				effects = { Money = -100 },
				feedText = "Special dinner together...",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for dinner" end,
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
			{ text = "Simple but meaningful ($30)", effects = { Happiness = 8, Money = -30 }, feedText = "💕 Thoughtful gift and quality time. Love isn't expensive.", eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30" end },
			{ text = "Homemade celebration", effects = { Happiness = 6 }, feedText = "💕 Cooked dinner together! Quality time over expense!" },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "seasonal",
		tags = { "valentines", "romance", "love" },
		
		-- CRITICAL: Random Valentine's outcome based on relationship status
		choices = {
			{
				text = "Romantic plans with partner ($75)",
				effects = { Money = -75 },
				feedText = "Valentine's date...",
				eligibility = function(state) return (state.Money or 0) >= 75, "💸 Need $75 for date" end,
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
			{ text = "Galentine's/Palentine's ($20)", effects = { Money = -20, Happiness = 8 }, feedText = "💝 Celebrated with friends! Who needs romance? Fun!", eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20" end },
			{ text = "Self-love day ($30)", effects = { Money = -30, Happiness = 6, Health = 2 }, feedText = "💝 Treated yourself! Self-care is important!", eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30" end },
			{ text = "Ignore it completely", effects = { Happiness = 2 }, feedText = "💝 Hallmark holiday. Didn't participate. Saved money." },
		},
	},
}

return SeasonalEvents
