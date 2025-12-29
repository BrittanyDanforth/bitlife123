--[[
    Travel & Vacation Events
    Adventures and trips around the world
    All events use randomized outcomes - NO god mode
]]

local TravelEvents = {}

local STAGE = "random"

TravelEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- VACATIONS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "travel_beach_vacation",
		title = "Beach Getaway",
		emoji = "🏖️",
		text = "Opportunity for a beach vacation!",
		question = "Do you take the trip?",
		minAge = 15, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "travel",
		tags = { "vacation", "beach", "relaxation" },
		
		eligibility = function(state)
			local money = state.Money or 0
			-- CRITICAL FIX: Check for choice cost ($800), not $300
			if money < 800 then
				return false, "Can't afford a beach vacation"
			end
			-- CRITICAL FIX: Can't travel from prison!
			if state.Flags and (state.Flags.in_prison or state.Flags.incarcerated) then
				return false, "Can't travel from prison"
			end
			return true
		end,
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL: Random vacation outcome
		choices = {
			{
				-- MINOR FIX: Show price in choice text
				text = "Book the trip! ($800)",
				effects = { Money = -800 },
				feedText = "Heading to the beach...",
				-- MINOR FIX: Add eligibility check
				eligibility = function(state)
					if (state.Money or 0) < 800 then
						return false, "Can't afford $800 vacation"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then
							state:ModifyStat("Happiness", 15)
							state:ModifyStat("Health", 5)
						end
						state.Flags = state.Flags or {}
						state.Flags.beach_lover = true
						if state.AddFeed then state:AddFeed("🏖️ PARADISE! Perfect weather, perfect beach! Refreshed!") end
					elseif roll < 0.85 then
						if state.ModifyStat then
							state:ModifyStat("Happiness", 10)
							state:ModifyStat("Health", 3)
						end
						if state.AddFeed then state:AddFeed("🏖️ Great trip! Some rain but still wonderful!") end
					else
						if state.ModifyStat then
							state:ModifyStat("Happiness", 4)
							state:ModifyStat("Health", -2)
						end
						if state.AddFeed then state:AddFeed("🏖️ Got sunburned and sick. Still needed the break.") end
					end
				end,
			},
			-- MINOR FIX: Show price in choice text
		{ text = "Budget staycation ($100)", effects = { Money = -100, Happiness = 5, Health = 2 }, feedText = "🏖️ Relaxing at home. Not as exciting but restful.",
			eligibility = function(state)
				if (state.Money or 0) < 100 then
					return false, "Can't afford $100 staycation"
				end
				return true
			end,
		},
			{ text = "Skip it - save money", effects = { Happiness = -2 }, feedText = "🏖️ Money over memories. Maybe next time." },
		},
	},
	{
		id = "travel_mountain_trip",
		title = "Mountain Adventure",
		emoji = "🏔️",
		text = "Time for a mountain getaway!",
		question = "What's your mountain adventure?",
		minAge = 15, maxAge = 80,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "travel",
		tags = { "vacation", "mountains", "adventure" },
		
		eligibility = function(state)
			local money = state.Money or 0
			-- CRITICAL FIX: Check for MOST EXPENSIVE choice ($600 skiing), not $400
			if money < 600 then
				return false, "Can't afford mountain trip"
			end
			-- CRITICAL FIX: Can't travel from prison!
			if state.Flags and (state.Flags.in_prison or state.Flags.incarcerated) then
				return false, "Can't travel from prison"
			end
			return true
		end,
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		choices = {
			{
				-- MINOR FIX: Show price in choice text
				text = "Hiking adventure ($400)",
				effects = { Money = -400, Health = 5 },
				feedText = "Hitting the trails...",
				eligibility = function(state)
					if (state.Money or 0) < 400 then
						return false, "Can't afford $400 trip"
					end
					return true
				end,
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					
					if roll < 0.55 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 12) end
						state.Flags = state.Flags or {}
						state.Flags.hiker = true
						if state.AddFeed then state:AddFeed("🏔️ Reached the summit! Views were breathtaking!") end
					elseif roll < 0.85 then
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						if state.AddFeed then state:AddFeed("🏔️ Great hike! Legs are sore but worth it!") end
					else
						if state.ModifyStat then
							state:ModifyStat("Happiness", 2)
							state:ModifyStat("Health", -3)
						end
						if state.AddFeed then state:AddFeed("🏔️ Got lost briefly. Scary but made it back.") end
					end
				end,
			},
			{
				-- MINOR FIX: Show price in choice text
				text = "Skiing/snowboarding ($600)",
				effects = { Money = -600 },
				feedText = "Hitting the slopes...",
				eligibility = function(state)
					if (state.Money or 0) < 600 then
						return false, "Can't afford $600 ski trip"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then
							state:ModifyStat("Happiness", 15)
							state:ModifyStat("Health", 3)
						end
						state.Flags = state.Flags or {}
						state.Flags.skier = true
						if state.AddFeed then state:AddFeed("🏔️ Powder day! Best runs of your life!") end
					elseif roll < 0.80 then
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						if state.AddFeed then state:AddFeed("🏔️ Great time on the mountain! Want to go again!") end
					else
						if state.ModifyStat then
							state:ModifyStat("Happiness", -2)
							state:ModifyStat("Health", -5)
						end
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 200)
						if state.AddFeed then state:AddFeed("🏔️ Wiped out hard. Injury on the slopes. Ouch.") end
					end
				end,
			},
			-- MINOR FIX: Show price in choice text
		{ text = "Cozy cabin retreat ($350)", effects = { Money = -350, Happiness = 10, Health = 3 }, feedText = "🏔️ Fire crackling, mountains visible, pure peace.",
			eligibility = function(state)
				if (state.Money or 0) < 350 then
					return false, "Can't afford $350 retreat"
				end
				return true
			end,
		},
		},
	},
	{
		id = "travel_international_trip",
		title = "International Adventure",
		emoji = "✈️",
		text = "Opportunity for international travel!",
		question = "Where do you go?",
		minAge = 18, maxAge = 80,
		baseChance = 0.12,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "travel",
		tags = { "international", "adventure", "culture" },
		
		eligibility = function(state)
			local money = state.Money or 0
			-- CRITICAL FIX: Check for MOST EXPENSIVE choice ($3000), not $1500
			if money < 3000 then
				return false, "Can't afford international travel"
			end
			-- CRITICAL FIX: Can't travel from prison!
			if state.Flags and (state.Flags.in_prison or state.Flags.incarcerated) then
				return false, "Can't travel from prison"
			end
			return true
		end,
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL: Random international trip outcome
		choices = {
			{
				-- MINOR FIX: Show price in choice text
				text = "Europe tour ($3,000)",
				effects = { Money = -3000 },
				feedText = "Exploring Europe...",
				eligibility = function(state)
					if (state.Money or 0) < 3000 then
						return false, "Can't afford $3,000 Europe trip"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Happiness", 18)
						state:ModifyStat("Smarts", 5)
						state.Flags = state.Flags or {}
						state.Flags.world_traveler = true
						state:AddFeed("✈️ INCREDIBLE! Paris, Rome, Barcelona! Life-changing!")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("✈️ Amazing trip! Some travel mishaps but memories for life!")
					else
						state:ModifyStat("Happiness", 4)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 500)
						state:AddFeed("✈️ Got robbed/scammed. Ruined parts of trip. Stressful.")
					end
				end,
			},
			{
				-- MINOR FIX: Show price in choice text
				text = "Asian adventure ($2,500)",
				effects = { Money = -2500 },
				feedText = "Exploring Asia...",
				eligibility = function(state)
					if (state.Money or 0) < 2500 then
						return false, "Can't afford $2,500 Asia trip"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 18)
						state:ModifyStat("Smarts", 5)
						state.Flags = state.Flags or {}
						state.Flags.world_traveler = true
						state:AddFeed("✈️ Japan, Thailand, temples and food! Mind-expanding!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("✈️ Culture shock but amazing experiences!")
					else
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Health", -4)
						state:AddFeed("✈️ Got food poisoning. Still worth it but rough.")
					end
				end,
			},
			{
				text = "Tropical paradise ($2,000)",
				effects = { Money = -2000 },
				feedText = "Island hopping...",
				-- BUG FIX #8: Add eligibility check for trip cost
				eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Can't afford trip ($2,000 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 16)
						state:ModifyStat("Health", 4)
						state:AddFeed("✈️ Caribbean/Pacific islands! Crystal water! Perfection!")
					else
						state:ModifyStat("Happiness", 10)
						state:AddFeed("✈️ Beautiful but travel days were exhausting.")
					end
				end,
			},
		},
	},
	{
		id = "travel_road_trip",
		title = "Road Trip!",
		emoji = "🚗",
		text = "Perfect weather for a road trip!",
		question = "Hit the open road?",
		minAge = 16, maxAge = 80,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "travel",
		tags = { "road_trip", "adventure", "driving" },
		
		eligibility = function(state)
			-- Need a car OR money to rent
			local hasCar = state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0
			local money = state.Money or 0
			if not hasCar and money < 200 then
				return false, "Need a car or money to rent one"
			end
			return true
		end,
		
		-- CRITICAL: Random road trip outcome
		choices = {
		{
			text = "Go on the adventure ($200)",
			effects = { Money = -200 },
			feedText = "Driving into the sunset...",
			eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for road trip" end,
			onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.road_tripper = true
						state:AddFeed("🚗 Best road trip ever! Amazing stops, great memories!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 7)
						state:AddFeed("🚗 Good trip! Some long stretches but worth it!")
					elseif roll < 0.95 then
						state:ModifyStat("Happiness", 2)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 150)
						state:AddFeed("🚗 Car trouble. Breakdown delayed everything.")
					else
						state:ModifyStat("Happiness", -4)
						state:ModifyStat("Health", -3)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 300)
						state:AddFeed("🚗 Minor accident. Everyone okay but car damaged.")
					end
				end,
			},
			{ text = "Day trip instead ($50)", effects = { Money = -50, Happiness = 6 }, feedText = "🚗 Quick adventure! Back home for dinner!", eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 for day trip" end },
		{ text = "Explore locally for free", effects = { Happiness = 4 }, feedText = "🚗 Found some cool spots nearby without spending a dime!" },
			{ text = "Not in the mood", effects = { Happiness = 1 }, feedText = "🚗 Road trips sound exhausting right now." },
		},
	},
	{
		id = "travel_cruise",
		title = "Cruise Ship Opportunity",
		emoji = "🚢",
		text = "There's a deal on a cruise!",
		question = "Set sail?",
		minAge = 18, maxAge = 90,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "travel",
		tags = { "cruise", "vacation", "ocean" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 1000 then
				return false, "Can't afford a cruise"
			end
			return true
		end,
		
		-- CRITICAL: Random cruise outcome
		choices = {
			{
				text = "Book the cruise ($1,500)",
				effects = { Money = -1500 },
				feedText = "All aboard...",
				-- BUG FIX #9: Add eligibility check for cruise cost
				eligibility = function(state) return (state.Money or 0) >= 1500, "💸 Can't afford cruise ($1,500 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Health", 3)
						state.Flags = state.Flags or {}
						state.Flags.cruiser = true
						state:AddFeed("🚢 Incredible cruise! Great food, great ports, great vibes!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🚢 Lovely trip! Ship was nice, ports were interesting!")
					elseif roll < 0.95 then
						state:ModifyStat("Happiness", 3)
						state:ModifyStat("Health", -3)
						state:AddFeed("🚢 Seasickness ruined half the trip. Not for everyone.")
					else
						state:ModifyStat("Happiness", -2)
						state:ModifyStat("Health", -5)
						state.Flags = state.Flags or {}
						state.Flags.cruise_disaster = true
						state:AddFeed("🚢 Norovirus outbreak! Quarantined in cabin! Nightmare!")
					end
				end,
			},
			{ text = "Too confined - skip", effects = { Happiness = 1 }, feedText = "🚢 Stuck on a boat? No thanks. Need land." },
		},
	},
	{
		id = "travel_camping",
		title = "Camping Trip",
		emoji = "⛺",
		text = "Time to connect with nature!",
		question = "Go camping?",
		minAge = 8, maxAge = 75,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "travel",
		tags = { "camping", "nature", "outdoors" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 50 then
				return false, "Need some money for camping supplies"
			end
			return true
		end,
		
		-- CRITICAL: Random camping outcome
		choices = {
		{
			text = "Rough it in the wilderness ($100)",
			effects = { Money = -100 },
			feedText = "Setting up camp...",
			eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for camping gear" end,
			onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					
					if roll < 0.50 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Health", 4)
						state.Flags = state.Flags or {}
						state.Flags.camper = true
						state:AddFeed("⛺ Stars, campfire, nature! Exactly what you needed!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 7)
						state:ModifyStat("Health", 2)
						state:AddFeed("⛺ Fun trip! Some bugs but overall great!")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 2)
						state:ModifyStat("Health", -2)
						state:AddFeed("⛺ Rain all weekend. Soggy and cold. Character building?")
					else
						state:ModifyStat("Happiness", -4)
						state:ModifyStat("Health", -4)
						state:AddFeed("⛺ Bear got into food! Wildlife encounter was terrifying!")
					end
				end,
			},
		{ text = "Glamping (fancy camping) ($300)", effects = { Money = -300, Happiness = 10, Health = 2 }, feedText = "⛺ Nature with amenities! Best of both worlds!", eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 for glamping" end },
		{ text = "Not outdoorsy", effects = { Happiness = 1 }, feedText = "⛺ Hotels exist for a reason. Pass." },
		{ text = "Backyard camping", effects = { Happiness = 4, Health = 1 }, feedText = "⛺ Set up a tent in the backyard. Stars and fresh air!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- TRAVEL MISHAPS & ADVENTURES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "travel_flight_issues",
		title = "Flight Problems",
		emoji = "✈️",
		text = "Something went wrong with your flight!",
		question = "What happened?",
		minAge = 15, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "travel",
		tags = { "flight", "delay", "problems" },
		
		choices = {
			{
				text = "Deal with the delay",
				effects = {},
				feedText = "Stuck at the airport...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("✈️ 2-hour delay. Annoying but manageable.")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -6)
						state:AddFeed("✈️ Major delay. Lost half a day. Frustrating!")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", -8)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 100)
						state:AddFeed("✈️ Cancelled flight! Scrambling for alternatives!")
					else
						state:ModifyStat("Happiness", 3)
						state.Money = (state.Money or 0) + 200
						state:AddFeed("✈️ Overbooked! Volunteered to bump. Got voucher!")
					end
				end,
			},
			{ text = "Lost luggage situation", effects = { Happiness = -6, Money = -150 }, setFlags = { lost_luggage = true }, feedText = "✈️ Bags didn't make it. Living in airport clothes." },
		},
	},
	{
		id = "travel_local_experience",
		title = "Local Adventure",
		emoji = "🗺️",
		text = "Discover something new in your own area!",
		question = "What local adventure do you try?",
		minAge = 10, maxAge = 90,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "travel",
		tags = { "local", "explore", "adventure" },
		
		choices = {
		{ text = "Try a new restaurant ($40)", effects = { Money = -40, Happiness = 6 }, feedText = "🗺️ Hidden gem! Best meal in months!", eligibility = function(state) return (state.Money or 0) >= 40, "💸 Need $40" end },
		{ text = "Explore a park you've never visited", effects = { Health = 3, Happiness = 5 }, feedText = "🗺️ Can't believe you never came here! Beautiful!" },
		{ text = "Check out a local attraction ($20)", effects = { Money = -20, Smarts = 2, Happiness = 4 }, feedText = "🗺️ Tourist in your own town! Actually really cool!", eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20" end },
			{ text = "Take a different route home", effects = { Happiness = 3, Smarts = 1 }, feedText = "🗺️ Found a great shortcut/view/shop you never knew!" },
		},
	},
	{
		id = "travel_adventure_activity",
		title = "Adventure Activity",
		emoji = "🎢",
		text = "Adrenaline-pumping activity opportunity!",
		question = "Try something thrilling?",
		minAge = 16, maxAge = 70,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "adventure",
		tags = { "adventure", "thrilling", "extreme" },
		
		eligibility = function(state)
			local health = (state.Stats and state.Stats.Health) or 50
			local money = state.Money or 0
			if health < 30 or money < 100 then
				return false, "Need decent health and money for adventure activities"
			end
			return true
		end,
		
		-- CRITICAL: Random adventure outcome
		choices = {
		{
			text = "Skydiving ($250)",
			effects = { Money = -250 },
			feedText = "Jumping out of a plane...",
			eligibility = function(state) return (state.Money or 0) >= 250, "💸 Need $250 for skydiving" end,
			onResolve = function(state)
					local roll = math.random()
					if roll < 0.80 then
						state:ModifyStat("Happiness", 18)
						state.Flags = state.Flags or {}
						state.Flags.thrill_seeker = true
						state:AddFeed("🎢 INCREDIBLE! Jumped and floated! Life-changing rush!")
					elseif roll < 0.95 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🎢 Scary but did it! Proud of yourself!")
					else
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Health", -5)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 500)
						state:AddFeed("🎢 Hard landing. Minor injury. Still wild experience.")
					end
				end,
			},
			{
				text = "Bungee jumping",
				effects = { Money = -150 },
				feedText = "Taking the leap...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.75 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.thrill_seeker = true
						state:AddFeed("🎢 BOUNCED BACK UP! Rush like no other!")
					elseif roll < 0.95 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🎢 Terrifying but exhilarating!")
					else
						state:ModifyStat("Happiness", -2)
						state:ModifyStat("Health", -2)
						state:AddFeed("🎢 Whiplash. Safe but ouch.")
					end
				end,
			},
			{
				text = "Zip-lining",
				effects = { Money = -80, Health = 2, Happiness = 10 },
				feedText = "🎢 Soaring through the treetops! Amazing views! Fun!",
			},
			{ text = "Not into extreme stuff", effects = { Happiness = 2 }, feedText = "🎢 Living isn't dying. Ground is good." },
		},
	},
	{
		id = "travel_solo_trip",
		title = "Solo Travel",
		emoji = "🎒",
		text = "Consider traveling alone!",
		question = "Go on a solo adventure?",
		minAge = 18, maxAge = 75,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "travel",
		tags = { "solo", "independence", "adventure" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 500 then
				return false, "Need money for solo trip"
			end
			return true
		end,
		
		-- CRITICAL: Random solo travel outcome
		choices = {
			{
				text = "Take the solo journey",
				effects = { Money = -800 },
				feedText = "Traveling alone...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Smarts", 5)
						state.Flags = state.Flags or {}
						state.Flags.solo_traveler = true
						state:AddFeed("🎒 Life-changing! Found yourself! Made friends along the way!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("🎒 Great trip! Some lonely moments but mostly amazing!")
					elseif roll < 0.95 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🎒 More isolating than expected. Still good experience.")
					else
						state:ModifyStat("Happiness", -4)
						state:ModifyStat("Health", -3)
						state.Flags = state.Flags or {}
						state.Flags.travel_mishap = true
						state:AddFeed("🎒 Something went wrong. Scary situation alone. Made it okay.")
					end
				end,
			},
			{ text = "Need a travel buddy", effects = { Happiness = 2 }, feedText = "🎒 Solo sounds lonely. Will wait for company." },
		},
	},
	{
		id = "travel_work_trip",
		title = "Business Travel",
		emoji = "💼",
		text = "Work requires you to travel!",
		question = "How does the business trip go?",
		minAge = 20, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "career",
		tags = { "business", "work", "travel" },
		requiresJob = true,
		
		-- CRITICAL: Random business trip outcome
		choices = {
			{
				text = "Make the most of it",
				effects = {},
				feedText = "Work trip underway...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 3)
						state.Money = (state.Money or 0) + 100
						state:AddFeed("💼 Productive trip! Networked well! Some sightseeing too!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("💼 Got the job done. Airports and hotels. Meh.")
					else
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Health", -2)
						state:AddFeed("💼 Exhausting trip. Red-eyes and meetings. Burnt out.")
					end
				end,
			},
			{ text = "Try to get out of it", effects = { Happiness = 2 }, feedText = "💼 Convinced someone else to go. Homebody wins." },
		},
	},
	{
		id = "travel_cultural_immersion",
		title = "Cultural Immersion",
		emoji = "🌍",
		text = "Opportunity for deep cultural experience!",
		question = "Immerse yourself in another culture?",
		minAge = 16, maxAge = 80,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "travel",
		tags = { "culture", "learning", "experience" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 1000 then
				return false, "Need money for cultural travel"
			end
			return true
		end,
		
		choices = {
			{
				text = "Homestay with local family",
				effects = { Money = -500 },
				feedText = "Living with locals...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Smarts", 6)
						state.Flags = state.Flags or {}
						state.Flags.cultural_explorer = true
						state:AddFeed("🌍 Life-changing! New perspective! Second family abroad!")
					else
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("🌍 Interesting experience! Language barrier but meaningful!")
					end
				end,
			},
			{ text = "Language immersion program", effects = { Money = -800, Smarts = 8, Happiness = 10 }, setFlags = { language_learner = true }, feedText = "🌍 Fluent now! Mind expanded! New world opened!" },
			{ text = "Volunteer abroad", effects = { Money = -600, Happiness = 12, Smarts = 4 }, setFlags = { volunteer_abroad = true }, feedText = "🌍 Made a difference AND learned so much! Win-win!" },
		},
	},
	{
		id = "travel_bucket_list_destination",
		title = "Bucket List Destination",
		emoji = "⭐",
		text = "Chance to visit a bucket list destination!",
		question = "Make the dream trip happen?",
		minAge = 20, maxAge = 90,
		baseChance = 0.08,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "travel",
		tags = { "bucket_list", "dream", "destination" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 4000 then
				return false, "Need significant savings for bucket list trip ($4,000)"
			end
			return true
		end,
		
		choices = {
			{
				text = "Make it happen ($4,000)",
				effects = { Money = -4000 },
				feedText = "Dream trip becoming reality...",
				-- BUG FIX #10: Add eligibility check for trip cost
				eligibility = function(state) return (state.Money or 0) >= 4000, "💸 Can't afford trip ($4,000 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 20)
						state:ModifyStat("Smarts", 5)
						state.Flags = state.Flags or {}
						state.Flags.bucket_list_complete = true
						state:AddFeed("⭐ DREAM CAME TRUE! Even better than imagined! Peak life moment!")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 14)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("⭐ Amazing trip! Few disappointments but mostly magical!")
					else
						state:ModifyStat("Happiness", 8)
						state:AddFeed("⭐ Reality vs expectations. Still glad you went though.")
					end
				end,
			},
			{ text = "Not yet - save more first", effects = { Happiness = -1 }, setFlags = { bucket_list_waiting = true }, feedText = "⭐ Someday. Dream delayed, not denied." },
		},
	},
}

return TravelEvents
