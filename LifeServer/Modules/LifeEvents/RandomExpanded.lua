--[[
    Random Expanded Events
    Events that can happen at any age - random life occurrences
    All events use randomized outcomes - NO god mode
]]

local RandomExpanded = {}

local STAGE = "random"

RandomExpanded.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- RANDOM ENCOUNTERS & SITUATIONS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "random_found_money",
		title = "Found Money!",
		emoji = "💵",
		text = "You found some money on the ground!",
		-- CRITICAL FIX #940: Added text variations for variety
		textVariants = {
			"Walking down the street, you spot something green on the ground. Money!",
			"There's cash just lying there on the sidewalk! No one's around...",
			"You look down and see a crumpled bill. Finders keepers?",
			"Holy cow! Someone dropped cash and you just found it!",
			"Is that... money? Just sitting there? Your lucky day!",
		},
		question = "What do you do?",
		minAge = 8, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "money", "luck", "found" },
		
		-- CRITICAL: Random amount found
		choices = {
			{
				text = "Keep it",
				effects = {},
				feedText = "Pocketing the cash...",
				onResolve = function(state)
					local roll = math.random()
					local amount
					if roll < 0.50 then
						amount = math.random(5, 20)
						-- AAA FIX: Nil check for all state methods
						if state.AddFeed then state:AddFeed(string.format("💵 Found $%d! Nice little bonus!", amount)) end
					elseif roll < 0.80 then
						amount = math.random(20, 100)
						if state.AddFeed then state:AddFeed(string.format("💵 Found $%d! Lucky day!", amount)) end
					else
						amount = math.random(100, 500)
						state.Flags = state.Flags or {}
						state.Flags.very_lucky = true
						if state.AddFeed then state:AddFeed(string.format("💵 Found $%d! Incredible luck!", amount)) end
					end
					state.Money = (state.Money or 0) + amount
					if state.ModifyStat then state:ModifyStat("Happiness", 4) end
				end,
			},
			{
				text = "Try to find the owner",
				effects = { Smarts = 2, Happiness = 3 },
				setFlags = { honest_finder = true },
				feedText = "Did the right thing. Karma points!",
			},
			{
				text = "Turn it in to lost and found",
				effects = { Smarts = 1, Happiness = 2 },
				feedText = "Someone might be looking for it.",
			},
		},
	},
	{
		id = "random_lost_wallet",
		title = "Lost Wallet!",
		emoji = "😱",
		text = "You've lost your wallet/purse!",
		-- CRITICAL FIX #941: Added text variations for variety
		textVariants = {
			"Where is it?! You've searched everywhere - your wallet is GONE!",
			"That sinking feeling when you reach for your wallet and it's not there...",
			"Panic sets in. Your wallet has disappeared. IDs, cards, cash - all gone!",
			"You retrace your steps mentally. When did you last have it? WHERE IS IT?!",
			"Oh no. Oh no no no. Your wallet is definitely missing.",
		},
		question = "What happens?",
		minAge = 16, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "misfortune",
		tags = { "money", "lost", "bad_luck" },
		
		-- CRITICAL: Random wallet recovery outcome
		choices = {
			{
				text = "Search frantically",
				effects = {},
				feedText = "Retracing your steps...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddFeed then state:AddFeed("😱 FOUND IT! Still there! So relieved!") end
					elseif roll < 0.65 then
						if state.ModifyStat then state:ModifyStat("Happiness", 2) end
						if state.AddFeed then state:AddFeed("😱 Someone returned it! Faith in humanity restored!") end
					elseif roll < 0.85 then
						local loss = math.random(50, 150)
						state.Money = math.max(0, (state.Money or 0) - loss)
						if state.ModifyStat then state:ModifyStat("Happiness", -3) end
						if state.AddFeed then state:AddFeed(string.format("😱 Found it but $%d cash missing. Could be worse.", loss)) end
					else
						local loss = math.random(100, 300)
						state.Money = math.max(0, (state.Money or 0) - loss)
						if state.ModifyStat then state:ModifyStat("Happiness", -8) end
						if state.AddFeed then state:AddFeed(string.format("😱 Gone forever. Lost $%d plus cards. Nightmare.", loss)) end
					end
				end,
			},
		},
	},
	{
		id = "random_flat_tire",
		title = "Flat Tire!",
		emoji = "🚗",
		text = "You've got a flat tire!",
		question = "How do you handle it?",
		minAge = 16, maxAge = 85,
		baseChance = 0.15,  -- CRITICAL FIX: Reduced from 0.455 to prevent spam (VehicleEvents has similar)
		cooldown = 6, -- CRITICAL FIX: Increased to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "vehicle",
		tags = { "car", "problem", "inconvenience" },
		
		eligibility = function(state)
			-- CRITICAL FIX: Check flags OR check Assets.Vehicles table properly
			if state.Flags and (state.Flags.has_car or state.Flags.owns_car or state.Flags.has_first_car) then
				return true
			end
			-- CRITICAL FIX: Assets is a dictionary, not an array - check Vehicles key
			if state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0 then
				return true
			end
			return false, "Need a car to have a flat tire"
		end,
		
		choices = {
			{
				text = "Change it yourself",
				effects = {},
				feedText = "Getting the spare out...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🚗 Changed it yourself! Feeling capable!")
					else
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 80)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🚗 Couldn't figure it out. Had to call for help. $80 gone.")
					end
				end,
			},
		{
			text = "Call roadside assistance ($50)",
			effects = { Money = -50, Happiness = 1 },
			feedText = "That's what you pay for! Help arrives.",
			eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 for roadside service" end,
		},
			{
				text = "Call someone to help",
				effects = { Happiness = 2 },
				feedText = "Friend/family came to the rescue. Good support system!",
			},
		},
	},
	{
		id = "random_traffic_ticket",
		title = "Traffic Ticket!",
		emoji = "🚨",
		text = "Red and blue lights in your mirror...",
		question = "Why are you getting pulled over?",
		minAge = 16, maxAge = 85,
		baseChance = 0.15,  -- CRITICAL FIX: Reduced from 0.45 to prevent spam (VehicleEvents has similar)
		cooldown = 6, -- CRITICAL FIX: Increased to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "legal",
		tags = { "ticket", "police", "driving" },
		
		eligibility = function(state)
			if state.Flags and state.Flags.has_license then
				return true
			end
			return false, "Need a license to get a traffic ticket"
		end,
		
		-- CRITICAL: Random ticket outcome
		choices = {
			{
				text = "Accept your fate",
				effects = {},
				feedText = "Officer approaches...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.20 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🚨 Just a warning! Phew!")
					elseif roll < 0.60 then
						local fine = math.random(100, 200)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - fine)
						state:ModifyStat("Happiness", -4)
						state:AddFeed(string.format("🚨 Speeding ticket. $%d fine.", fine))
					elseif roll < 0.85 then
						local fine = math.random(200, 400)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - fine)
						state:ModifyStat("Happiness", -6)
						state:AddFeed(string.format("🚨 Multiple violations! $%d!", fine))
					else
						local fine = math.random(300, 600)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - fine)
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.license_points = true
						state:AddFeed(string.format("🚨 Serious citation. $%d and points on license.", fine))
					end
				end,
			},
			{
				text = "Try to talk your way out",
				effects = {},
				feedText = "Being charming...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local charmChance = 0.20 + (looks / 200)
					if roll < charmChance then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🚨 Talked your way out! Charming!")
					else
						local fine = math.random(150, 300)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - fine)
						state:ModifyStat("Happiness", -5)
						state:AddFeed(string.format("🚨 Made it worse. $%d fine.", fine))
					end
				end,
			},
		},
	},
	{
		id = "random_lottery_scratch",
		title = "Lottery Scratch-Off",
		emoji = "🎰",
		text = "You bought a scratch-off lottery ticket!",
		question = "Did you win?",
		minAge = 18, maxAge = 90,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "gambling",
		tags = { "lottery", "gambling", "luck" },
		
		-- CRITICAL: Random lottery outcome - mostly losing
		choices = {
			{
				text = "Scratch it off",
				effects = { Money = -5 },
				feedText = "Scratching...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", -1)
						state:AddFeed("🎰 Nothing. Loser ticket. That's $5 gone.")
					elseif roll < 0.75 then
						state.Money = (state.Money or 0) + 5
						state:AddFeed("🎰 Won $5! Got your money back!")
					elseif roll < 0.90 then
						local win = math.random(10, 50)
						state.Money = (state.Money or 0) + win
						state:ModifyStat("Happiness", 4)
						state:AddFeed(string.format("🎰 Won $%d! Nice!", win))
					elseif roll < 0.98 then
						local win = math.random(100, 500)
						state.Money = (state.Money or 0) + win
						state:ModifyStat("Happiness", 8)
						state:AddFeed(string.format("🎰 WON $%d! Lucky day!", win))
					else
						local win = math.random(1000, 5000)
						state.Money = (state.Money or 0) + win
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.lottery_winner = true
						state:AddFeed(string.format("🎰 JACKPOT! $%d! INCREDIBLE!", win))
					end
				end,
			},
		},
	},
	{
		id = "random_jury_duty",
		title = "Jury Duty Notice",
		emoji = "⚖️",
		text = "You've been summoned for jury duty!",
		question = "How do you handle jury duty?",
		minAge = 18, maxAge = 75,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "adult",
		category = "civic",
		tags = { "jury", "civic_duty", "legal" },
		
		choices = {
			{
				text = "Serve and do your civic duty",
				effects = {},
				feedText = "Showing up to court...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", -2)
						state.Money = (state.Money or 0) + 30
						state:AddFeed("⚖️ Dismissed quickly. $30 for your time.")
					elseif roll < 0.70 then
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", 2)
						state.Money = (state.Money or 0) + 100
						state:AddFeed("⚖️ Selected! Interesting case. Civic duty done.")
					else
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 3)
						state.Money = (state.Money or 0) + 250
						state.Flags = state.Flags or {}
						state.Flags.jury_foreman = true
						state:AddFeed("⚖️ Elected jury foreman! Leadership moment!")
					end
				end,
			},
			{
				text = "Try to get excused",
				effects = {},
				feedText = "Coming up with reasons...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("⚖️ Excused! Back to regular life.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("⚖️ Didn't work. Still have to serve.")
					end
				end,
			},
		},
	},
	{
		id = "random_appliance_breaks",
		title = "Appliance Breakdown",
		emoji = "🔧",
		text = "A major appliance in your home has broken down!",
		question = "What broke and how do you fix it?",
		minAge = 22, maxAge = 90,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "home",
		tags = { "home", "appliance", "expense" },
		-- CRITICAL FIX #6: Block for homeless/prison - need a home for appliances!
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true, living_in_car = true, couch_surfing = true },
		
		-- CRITICAL FIX #6: Require having a home for appliance issues
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Check for various housing flags
			if flags.has_home or flags.has_apartment or flags.has_house or flags.homeowner or flags.renting then
				return true
			end
			-- Check HousingState
			if state.HousingState then
				local status = state.HousingState.status
				if status == "owner" or status == "renter" or status == "housed" then
					return true
				end
			end
			-- Check if player has Properties
			if state.Assets and state.Assets.Properties and #state.Assets.Properties > 0 then
				return true
			end
			return false, "Need a home to have appliance issues"
		end,
		
		-- CRITICAL: Random appliance and cost
		choices = {
			{
				text = "Get it repaired/replaced",
				effects = {},
				feedText = "Assessing the damage...",
				onResolve = function(state)
					local roll = math.random()
					local appliances = {"washing machine", "refrigerator", "dishwasher", "HVAC unit", "water heater", "oven"}
					local appliance = appliances[math.random(#appliances)]
					local cost
					if roll < 0.40 then
						cost = math.random(100, 300)
						state:AddFeed(string.format("🔧 %s repair: $%d. Could be worse.", appliance, cost))
					elseif roll < 0.70 then
						cost = math.random(300, 800)
						state:ModifyStat("Happiness", -3)
						state:AddFeed(string.format("🔧 %s needs major repair: $%d. Ouch.", appliance, cost))
					else
						cost = math.random(800, 2000)
						state:ModifyStat("Happiness", -6)
						state:AddFeed(string.format("🔧 %s needs replacement: $%d! Brutal expense.", appliance, cost))
					end
					-- CRITICAL FIX: Prevent negative money
					state.Money = math.max(0, (state.Money or 0) - cost)
				end,
			},
			{
				text = "Try to fix it yourself",
				effects = {},
				feedText = "Watching YouTube tutorials...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 5)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 50)
						state:AddFeed("🔧 FIXED IT! Parts cost $50. Feeling handy!")
					elseif roll < 0.65 then
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 150)
						state:ModifyStat("Happiness", 1)
						state:AddFeed("🔧 Partially fixed. Kinda works. $150 in parts.")
					else
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 400)
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🔧 Made it worse. Now need professional. $400 total.")
					end
				end,
			},
		},
	},
	{
		id = "random_surprise_visit",
		title = "Surprise Visit",
		emoji = "🚪",
		text = "Someone's at your door unexpectedly!",
		question = "Who is it?",
		minAge = 18, maxAge = 90,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "social",
		tags = { "surprise", "visitor", "social" },
		
		-- CRITICAL: Random visitor
		choices = {
			{
				text = "Answer the door",
				effects = {},
				feedText = "Opening the door...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🚪 Old friend visiting! Wonderful surprise!")
					elseif roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🚪 Family member stopped by! Good to see them!")
					elseif roll < 0.65 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🚪 Neighbor needs help. Being a good person.")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🚪 Salesperson. Wasted time. Door closed.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🚪 Awkward acquaintance. Forced small talk. Exhausting.")
					end
				end,
			},
			{
				text = "Pretend you're not home",
				effects = { Happiness = 1 },
				feedText = "Hiding. Not in the mood.",
			},
		},
	},
	{
		id = "random_dream_vivid",
		title = "Vivid Dream",
		emoji = "💭",
		text = "You had an incredibly vivid dream last night.",
		question = "What was the dream about?",
		minAge = 10, maxAge = 100,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "psychology",
		tags = { "dream", "sleep", "subconscious" },
		
		choices = {
			{ text = "Flying - felt free", effects = { Happiness = 4 }, feedText = "Soaring through the sky. Woke up energized!" },
			{ text = "Nightmare - terrifying", effects = { Happiness = -4, Health = -1 }, feedText = "Woke up in a cold sweat. Shook you up." },
			{ text = "Someone who passed away", effects = { Happiness = 3 }, setFlags = { visitation_dream = true }, feedText = "Felt like they visited you. Comforting and sad." },
			{ text = "Prophetic - felt meaningful", effects = { Smarts = 2, Happiness = 2 }, feedText = "What did it mean? Thinking about it all day." },
			{ text = "Weird and random", effects = { Happiness = 2 }, feedText = "Made no sense. Brains are weird." },
		},
	},
	{
		id = "random_weather_event",
		title = "Extreme Weather",
		emoji = "🌪️",
		text = "Severe weather is affecting your area!",
		question = "How bad is it?",
		minAge = 5, maxAge = 100,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "disaster",
		tags = { "weather", "disaster", "emergency" },
		
		-- CRITICAL: Random weather severity
		choices = {
			{
				text = "Ride it out",
				effects = {},
				feedText = "Waiting for it to pass...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", -1)
						state:AddFeed("🌪️ Power flickered. Trees down. But you're fine.")
					elseif roll < 0.75 then
						local cost = math.random(100, 500)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - cost)
						state:ModifyStat("Happiness", -4)
						state:AddFeed(string.format("🌪️ Some property damage. $%d to fix. Could be worse.", cost))
					elseif roll < 0.92 then
						local cost = math.random(500, 2000)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - cost)
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.weather_damage = true
						state:AddFeed(string.format("🌪️ Significant damage. $%d in repairs. Stressful.", cost))
					else
						local cost = math.random(2000, 10000)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - cost)
						state:ModifyStat("Happiness", -12)
						state:ModifyStat("Health", -5)
						state.Flags = state.Flags or {}
						state.Flags.major_weather_damage = true
						state:AddFeed(string.format("🌪️ Devastating damage. $%d+. Rebuilding.", cost))
					end
				end,
			},
		},
	},
	{
		id = "random_celebrity_encounter",
		title = "Celebrity Sighting",
		emoji = "⭐",
		text = "You spotted someone famous in public!",
		question = "What do you do?",
		minAge = 10, maxAge = 90,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "encounter",
		tags = { "celebrity", "fame", "encounter" },
		
		choices = {
			{
				text = "Ask for a photo/autograph",
				effects = {},
				feedText = "Approaching them...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.met_celebrity = true
						state:AddFeed("⭐ They were SO NICE! Got the photo! Life moment!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("⭐ They ignored you/were rude. Fantasy shattered.")
					end
				end,
			},
			{
				text = "Play it cool - respect their privacy",
				effects = { Smarts = 2, Happiness = 3 },
				feedText = "A nod of acknowledgment. They appreciated it.",
			},
			{
				text = "Snap a stealth photo",
				effects = { Happiness = 2 },
				feedText = "Got the pic! No one believes you though.",
			},
		},
	},
	{
		id = "random_act_kindness_received",
		title = "Random Kindness",
		emoji = "💝",
		text = "A stranger did something unexpectedly kind for you!",
		question = "What did they do?",
		minAge = 10, maxAge = 100,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "kindness",
		tags = { "kindness", "stranger", "gratitude" },
		
		choices = {
			{ text = "Paid for your coffee/meal", effects = { Happiness = 7, Money = 15 }, feedText = "💝 Pay it forward! Faith in humanity restored!" },
			{ text = "Helped you when you were struggling", effects = { Happiness = 8 }, feedText = "💝 Right place, right time. Angel in disguise." },
			{ text = "Complimented you sincerely", effects = { Happiness = 5, Looks = 1 }, feedText = "💝 Made your whole day. Such a simple gesture." },
			{ text = "Returned something you dropped", effects = { Happiness = 6 }, feedText = "💝 Honest people exist! So grateful!" },
		},
	},
	{
		id = "random_illness_bug",
		title = "Caught a Bug",
		emoji = "🤧",
		text = "You're coming down with something!",
		question = "How sick are you?",
		minAge = 3, maxAge = 100,
		baseChance = 0.555,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "sick", "illness", "health" },
		
		-- CRITICAL: Random illness severity
		choices = {
			{
				text = "Rest and recover",
				effects = {},
				feedText = "Taking it easy...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local age = state.Age or 30
					local roll = math.random()
					local mildChance = 0.50 + (health / 200) - (age / 300)
					if roll < mildChance then
						state:ModifyStat("Health", -2)
						state:ModifyStat("Happiness", -1)
						state:AddFeed("🤧 Mild cold. Sniffles for a few days. Fine now.")
					elseif roll < mildChance + 0.30 then
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤧 Flu hit hard. A week in bed. Miserable.")
					elseif roll < mildChance + 0.42 then
						state:ModifyStat("Health", -8)
						state:ModifyStat("Happiness", -5)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 100)
						state:AddFeed("🤧 Needed doctor visit and medication. $100. Rough.")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -8)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 500)
						state.Flags = state.Flags or {}
						state.Flags.serious_illness_random = true
						state:AddFeed("🤧 Turned serious. Hospital visit. Scary experience.")
					end
				end,
			},
		},
	},
	{
		id = "random_food_poisoning",
		title = "Food Poisoning",
		emoji = "🤢",
		text = "Something you ate didn't agree with you!",
		question = "How bad is it?",
		minAge = 5, maxAge = 100,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "food", "sick", "health" },
		
		-- CRITICAL: Random food poisoning severity
		choices = {
			{
				text = "Endure it",
				effects = {},
				feedText = "This is not fun...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Health", -3)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤢 Rough night. Fine by morning. Never eating there again.")
					elseif roll < 0.80 then
						state:ModifyStat("Health", -6)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🤢 Two days of misery. Lost weight the wrong way.")
					else
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -7)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 200)
						state:AddFeed("🤢 Hospitalized. IV fluids. Seriously bad batch.")
					end
				end,
			},
		},
	},
	{
		id = "random_good_news",
		title = "Good News!",
		emoji = "📰",
		text = "You received some unexpectedly good news!",
		question = "What was the good news?",
		minAge = 10, maxAge = 100,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "good_news", "luck", "positive" },
		
		choices = {
			{ text = "Financial windfall", effects = { Happiness = 8, Money = math.random(200, 1000) }, feedText = "📰 Money you weren't expecting! What a surprise!" },
			{ text = "Health scare was nothing", effects = { Happiness = 12, Health = 5 }, feedText = "📰 Test results came back clean! HUGE relief!" },
			{ text = "Someone important reached out", effects = { Happiness = 8 }, feedText = "📰 Reconnection you didn't expect. So happy!" },
			{ text = "Opportunity of a lifetime", effects = { Happiness = 10, Smarts = 2 }, feedText = "📰 Door opened you never expected! Amazing!" },
		},
	},
	{
		id = "random_bad_news",
		title = "Bad News",
		emoji = "😢",
		text = "You received some upsetting news.",
		question = "What happened?",
		minAge = 12, maxAge = 100,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "hardship",
		tags = { "bad_news", "sadness", "hardship" },
		
		choices = {
			{ text = "Someone you know passed away", effects = { Happiness = -12 }, setFlags = { grieving = true }, feedText = "😢 Gone too soon. Processing the loss." },
			{ text = "Plans fell through", effects = { Happiness = -6 }, feedText = "😢 Something you were counting on didn't work out." },
			{ text = "Relationship ended unexpectedly", effects = { Happiness = -8 }, feedText = "😢 Blindsided by the news. Heart hurts." },
			{ text = "Health news for someone you love", effects = { Happiness = -10 }, setFlags = { worried_about_loved_one = true }, feedText = "😢 They're going through something scary. Helpless feeling." },
		},
	},
	{
		id = "random_reunion_coincidence",
		title = "Chance Encounter",
		emoji = "👋",
		text = "You ran into someone from your past!",
		question = "Who did you run into?",
		minAge = 18, maxAge = 100,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "social",
		tags = { "reunion", "past", "encounter" },
		
		-- CRITICAL: Random encounter outcome
		choices = {
			{
				text = "Chat and catch up",
				effects = {},
				feedText = "Reconnecting after all these years...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.old_friend_reunion = true
						state:AddFeed("👋 Great catching up! Exchanged numbers! Old friend restored!")
					elseif roll < 0.65 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("👋 Nice to see them. Brief pleasant chat.")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", -2)
						state:AddFeed("👋 Awkward. Ran out of things to say. Different people now.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("👋 Old grudges resurfaced. Remembered why you lost touch.")
					end
				end,
			},
			{
				text = "Pretend you didn't see them",
				effects = { Happiness = 1 },
				feedText = "Dodge! Not in the mood for that conversation.",
			},
		},
	},
	{
		id = "random_hobby_discovery",
		title = "New Hobby Discovery",
		emoji = "✨",
		text = "You stumbled upon something that really interests you!",
		question = "What did you discover?",
		minAge = 8, maxAge = 90,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "growth",
		tags = { "hobby", "interest", "growth" },
		
		choices = {
			{ text = "Creative activity", effects = { Happiness = 6, Smarts = 2 }, setFlags = { creative_discovery = true }, feedText = "✨ Art, music, crafts - found something you love creating!" },
			{ text = "Physical activity", effects = { Happiness = 5, Health = 4 }, setFlags = { active_discovery = true }, feedText = "✨ Sport, exercise, outdoors - body and mind love it!" },
			{ text = "Learning/intellectual pursuit", effects = { Happiness = 4, Smarts = 5 }, setFlags = { learning_discovery = true }, feedText = "✨ Reading, puzzles, studying - feeding your brain!" },
			{ text = "Social activity", effects = { Happiness = 6 }, setFlags = { social_discovery = true }, feedText = "✨ New group, club, community - found your people!" },
			{ text = "Collecting something", effects = { Happiness = 5, Money = -50 }, setFlags = { collecting_discovery = true }, feedText = "✨ New collection started! Obsession begins!" },
		},
	},
	{
		id = "random_identity_theft",
		title = "Identity Theft Scare",
		emoji = "🔐",
		text = "There's suspicious activity on your accounts!",
		question = "How serious is it?",
		minAge = 18, maxAge = 100,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "adult",
		category = "crime",
		tags = { "fraud", "identity", "crime" },
		-- CRITICAL FIX: Can't get identity theft while in prison (no bank accounts accessible)
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL: Random identity theft severity
		choices = {
			{
				text = "Investigate immediately",
				effects = {},
				feedText = "Checking all accounts...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						if state.ModifyStat then state:ModifyStat("Happiness", 3) end
						if state.AddFeed then state:AddFeed("🔐 False alarm! Just a weird charge. All good.") end
					elseif roll < 0.70 then
						if state.ModifyStat then state:ModifyStat("Happiness", -4) end
						-- CRITICAL FIX: Can't lose more money than you have
						local loss = math.min(100, state.Money or 0)
						state.Money = math.max(0, (state.Money or 0) - loss)
						if state.AddFeed then 
							if loss > 0 then
								state:AddFeed(string.format("🔐 Small fraud. Bank fixed it. Lost $%d and time.", loss))
							else
								state:AddFeed("🔐 Small fraud attempt. Bank caught it in time!")
							end
						end
					elseif roll < 0.90 then
						if state.ModifyStat then state:ModifyStat("Happiness", -8) end
						-- CRITICAL FIX: Can't lose more money than you have
						local loss = math.min(500, state.Money or 0)
						state.Money = math.max(0, (state.Money or 0) - loss)
						state.Flags = state.Flags or {}
						state.Flags.identity_theft = true
						if state.AddFeed then 
							if loss > 0 then
								state:AddFeed(string.format("🔐 Real identity theft. Months to fix. Lost $%d.", loss))
							else
								state:AddFeed("🔐 Identity theft attempt! Caught early but took months to clear your name.")
							end
						end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -12) end
						-- CRITICAL FIX: Can't lose more money than you have
						local loss = math.min(2000, state.Money or 0)
						state.Money = math.max(0, (state.Money or 0) - loss)
						state.Flags = state.Flags or {}
						state.Flags.major_identity_theft = true
						if state.AddFeed then 
							if loss > 0 then
								state:AddFeed(string.format("🔐 Major breach. Credit destroyed. Lost $%d. Years to recover.", loss))
							else
								state:AddFeed("🔐 Major breach! Your credit is destroyed. Years to recover.")
							end
						end
					end
				end,
			},
		},
	},
	{
		id = "random_package_surprise",
		title = "Unexpected Package",
		emoji = "📦",
		text = "A package arrived that you weren't expecting!",
		question = "What's inside?",
		minAge = 12, maxAge = 100,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "surprise",
		tags = { "package", "surprise", "gift" },
		
		choices = {
			{ text = "A gift from someone who cares", effects = { Happiness = 8 }, feedText = "📦 Someone thought of you! So thoughtful!" },
			{ text = "Something you ordered and forgot about", effects = { Happiness = 5 }, feedText = "📦 Past-you got present-you a gift! Nice surprise!" },
			{ text = "Wrong address - not yours", effects = { Happiness = -1, Smarts = 1 }, feedText = "📦 Neighbor's package. Being honest and returning it." },
		{ text = "Free sample/promotion", effects = { Happiness = 3 }, feedText = "📦 Free stuff! Who doesn't love free stuff?" },
	},
},

-- ══════════════════════════════════════════════════════════════════════════════
-- DYNAMIC LIFE EVENTS - React to player's life choices and circumstances
-- User requested: "life wise hugely expanded so its way less boring"
-- These use eligibility functions to dynamically respond to player state
-- ══════════════════════════════════════════════════════════════════════════════

{
	id = "rand_life_reflection",
	title = "Life Reflection Moment",
	emoji = "💭",
	text = "A quiet moment of reflection. How do you feel about your life right now?",
	question = "What comes to mind?",
	minAge = 20, maxAge = 90,
	baseChance = 0.4,
	cooldown = 5,
	stage = STAGE,
	ageBand = "any",
	category = "random",
	tags = { "reflection", "life", "thoughts", "dynamic" },
	
	choices = {
		{
			text = "Gratitude for what I have",
			effects = {},
			feedText = "Counting blessings...",
			onResolve = function(state)
				local happiness = (state.Stats and state.Stats.Happiness) or 50
				local money = state.Money or 0
				
				-- More grateful if doing well
				if happiness > 60 or money > 50000 then
					state:ModifyStat("Happiness", 12)
					state:AddFeed("💭 Life is good. Really good. You're lucky and you know it.")
				else
					state:ModifyStat("Happiness", 8)
					state:AddFeed("💭 Could be worse. Focusing on the positives helps.")
				end
				state.Flags = state.Flags or {}
				state.Flags.grateful = true
			end,
		},
		{
			text = "Regret for missed opportunities",
			effects = {},
			feedText = "What ifs...",
			onResolve = function(state)
				local age = state.Age or 30
				if age > 50 then
					state:ModifyStat("Happiness", -10)
					state:AddFeed("💭 So many roads not taken. Is it too late? The weight of regret is heavy.")
				else
					state:ModifyStat("Happiness", -5)
					state:AddFeed("💭 Regrets surface. But there's still time to make different choices.")
				end
			end,
		},
		{
			text = "Excitement for the future",
			effects = { Happiness = 8 },
			feedText = "💭 Best is yet to come! You can feel it. Optimism flowing!",
			setFlags = { optimistic = true },
		},
		{
			text = "Just surviving day by day",
			effects = {},
			feedText = "One day at a time...",
			onResolve = function(state)
				local health = (state.Stats and state.Stats.Health) or 50
				local happiness = (state.Stats and state.Stats.Happiness) or 50
				
				if health < 40 or happiness < 30 then
					state:ModifyStat("Happiness", -5)
					state:AddFeed("💭 Survival mode. Each day is a struggle. Need help.")
					state.Flags = state.Flags or {}
					state.Flags.struggling = true
				else
					state:ModifyStat("Happiness", 2)
					state:AddFeed("💭 Steady rhythm. Not exciting, not terrible. Just... life.")
				end
			end,
		},
	},
},

{
	id = "rand_random_opportunity",
	title = "Unexpected Opportunity",
	emoji = "🎯",
	text = "An unexpected opportunity lands in your lap!",
	question = "What kind of opportunity is it?",
	minAge = 18, maxAge = 70,
	baseChance = 0.35,
	cooldown = 5,
	stage = STAGE,
	ageBand = "adult",
	category = "random",
	tags = { "opportunity", "chance", "luck", "dynamic" },
	
	choices = {
		{
			text = "A job offer out of nowhere",
			effects = {},
			feedText = "Career twist...",
			onResolve = function(state)
				local employed = state.CurrentJob ~= nil
				local roll = math.random()
				
				if employed then
					if roll < 0.5 then
						state.Money = (state.Money or 0) + math.random(5000, 20000)
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🎯 Recruited for a better position! More money! Career boost!")
						state.Flags = state.Flags or {}
						state.Flags.headhunted = true
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎯 Interesting offer but decided to stay where you are. Flattering though!")
					end
				else
					state:ModifyStat("Happiness", 15)
					state:AddFeed("🎯 A job when you needed it most! Someone believed in you!")
					state.Flags = state.Flags or {}
					state.Flags.got_opportunity = true
				end
			end,
		},
		{
			text = "An investment opportunity",
			effects = {},
			feedText = "Risk vs reward...",
			onResolve = function(state)
				local money = state.Money or 0
				local roll = math.random()
				
				if money < 1000 then
					state:ModifyStat("Happiness", -3)
					state:AddFeed("🎯 Great opportunity but no money to invest. Frustrating!")
				elseif roll < 0.4 then
					local profit = math.random(2000, 10000)
					state.Money = (state.Money or 0) + profit
					state:ModifyStat("Happiness", 12)
					state:AddFeed("🎯 Invested and it paid off! +" .. profit .. "! Lucky break!")
				elseif roll < 0.7 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🎯 Investment is slow but steady. Time will tell if it's worth it.")
				else
					local loss = math.random(500, 2000)
					state.Money = math.max(0, (state.Money or 0) - loss)
					state:ModifyStat("Happiness", -8)
					state:AddFeed("🎯 Investment tanked! Lost $" .. loss .. ". Should have been more careful.")
				end
			end,
		},
		{
			text = "A creative project invitation",
			effects = { Happiness = 8, Smarts = 2 },
			feedText = "🎯 Someone wants to collaborate with you! Creative energy flowing!",
			setFlags = { creative_opportunity = true },
		},
		{
			text = "Pass - seems too good to be true",
			effects = { Happiness = -2 },
			feedText = "🎯 Let it go. Maybe it was legit. Maybe it wasn't. You'll never know.",
		},
	},
},

{
	id = "rand_stranger_interaction",
	title = "Stranger Interaction",
	emoji = "👤",
	text = "A random stranger approaches you in public.",
	question = "What do they want?",
	minAge = 16, maxAge = 80,
	baseChance = 0.45,
	cooldown = 3,
	stage = STAGE,
	ageBand = "any",
	category = "random",
	tags = { "stranger", "interaction", "public", "dynamic" },
	
	choices = {
		{
			text = "They need directions",
			effects = { Happiness = 3 },
			feedText = "👤 Helped them find their way. Small act of kindness. Feels good!",
			onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.kind_to_strangers = true
			end,
		},
		{
			text = "They compliment you",
			effects = {},
			feedText = "Unexpected compliment...",
			onResolve = function(state)
				local looks = (state.Stats and state.Stats.Looks) or 50
				if looks > 60 then
					state:ModifyStat("Happiness", 10)
					state:AddFeed("👤 They said you look amazing! Confidence boost!")
				else
					state:ModifyStat("Happiness", 8)
					state:AddFeed("👤 A genuine compliment from a stranger. Made your day!")
				end
			end,
		},
		{
			text = "They're hitting on you",
			effects = {},
			feedText = "Getting hit on...",
			onResolve = function(state)
				local flags = state.Flags or {}
				local roll = math.random()
				
				if flags.married or flags.has_partner then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("👤 Flattered but committed. Still nice to know you've got it!")
				elseif roll < 0.3 then
					state:ModifyStat("Happiness", 10)
					state:AddFeed("👤 They were actually attractive! Exchange numbers?")
					state.Flags = state.Flags or {}
					state.Flags.potential_date = true
				else
					state:ModifyStat("Happiness", 2)
					state:AddFeed("👤 Not your type. But the attention is flattering.")
				end
			end,
		},
		{
			text = "They want money",
			effects = {},
			feedText = "Being asked for money...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.3 then
					state.Money = (state.Money or 0) - 10
					state:ModifyStat("Happiness", 5)
					state:AddFeed("👤 Gave them some change. Hopefully it helps.")
					state.Flags = state.Flags or {}
					state.Flags.charitable = true
				elseif roll < 0.7 then
					state:ModifyStat("Happiness", -2)
					state:AddFeed("👤 Said you had no cash. Did you feel guilty?")
				else
					state:ModifyStat("Happiness", -5)
					state:AddFeed("👤 They got aggressive when you said no. Unpleasant encounter.")
				end
			end,
		},
	},
},

{
	id = "rand_overheard_conversation",
	title = "Overheard Something",
	emoji = "👂",
	text = "You accidentally overheard a conversation that wasn't meant for you.",
	question = "What did you hear?",
	minAge = 14, maxAge = 80,
	baseChance = 0.4,
	cooldown = 4,
	stage = STAGE,
	ageBand = "any",
	category = "random",
	tags = { "overhear", "secret", "information", "dynamic" },
	
	choices = {
		{
			text = "Gossip about someone you know",
			effects = {},
			feedText = "Hearing gossip...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.4 then
					state:ModifyStat("Happiness", -5)
					state:AddFeed("👂 They were talking about YOU! And not nicely. Hurts.")
				elseif roll < 0.7 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("👂 Juicy gossip about someone else. You didn't hear that...")
				else
					state:ModifyStat("Happiness", 8)
					state:AddFeed("👂 They were saying nice things about you! Behind your back praise!")
				end
			end,
		},
		{
			text = "A business secret",
			effects = { Smarts = 2 },
			feedText = "👂 Information that could be valuable... What do you do with it?",
			setFlags = { knows_secret = true },
		},
		{
			text = "Someone's personal struggle",
			effects = { Happiness = -2 },
			feedText = "👂 Heard someone's pain. Feel intrusive but also empathetic.",
		},
		{
			text = "Nothing interesting",
			effects = { Happiness = 1 },
			feedText = "👂 Just mundane chatter. Life goes on.",
		},
	},
},

{
	id = "rand_small_victory",
	title = "Small Victory",
	emoji = "🏆",
	text = "Something small but satisfying happened today!",
	question = "What was your small win?",
	minAge = 10, maxAge = 90,
	baseChance = 0.5,
	cooldown = 3,
	stage = STAGE,
	ageBand = "any",
	category = "random",
	tags = { "victory", "small_win", "satisfaction", "dynamic" },
	
	choices = {
		{
			text = "Found money on the ground",
			effects = {},
			feedText = "Lucky find...",
			onResolve = function(state)
				local amount = math.random(5, 100)
				state.Money = (state.Money or 0) + amount
				state:ModifyStat("Happiness", 5)
				state:AddFeed("🏆 Found $" .. amount .. "! Is it bad luck? Who cares!")
			end,
		},
		{
			text = "Got the last of something you wanted",
			effects = { Happiness = 6 },
			feedText = "🏆 Last one in stock! The universe wanted you to have it!",
		},
		{
			text = "Perfectly caught the bus/train",
			effects = { Happiness = 5 },
			feedText = "🏆 Perfect timing! No waiting! It's the little things!",
		},
		{
			text = "Someone let you go first",
			effects = { Happiness = 4 },
			feedText = "🏆 Random act of kindness from a stranger. Faith in humanity!",
		},
	},
},

{
	id = "rand_minor_setback",
	title = "Minor Setback",
	emoji = "😤",
	text = "Something small but annoying happened today.",
	question = "What went wrong?",
	minAge = 10, maxAge = 90,
	baseChance = 0.45,
	cooldown = 3,
	stage = STAGE,
	ageBand = "any",
	category = "random",
	tags = { "setback", "frustration", "minor", "dynamic" },
	
	choices = {
		{
			text = "Phone died at the worst time",
			effects = { Happiness = -4 },
			feedText = "😤 Dead phone when you needed it most. Technology betrayal!",
		},
		{
			text = "Got stuck in traffic/transit",
			effects = { Happiness = -3 },
			feedText = "😤 Wasted time going nowhere. The commute rage is real.",
		},
		{
			text = "Spilled something on yourself",
			effects = { Happiness = -3, Money = -20 },
			feedText = "😤 Coffee/food on your clothes. Embarrassing. Had to buy new shirt.",
		},
		{
			text = "Forgot something important at home",
			effects = { Happiness = -4 },
			feedText = "😤 That thing you needed? At home. On the counter. Mocking you.",
		},
	},
},

{
	id = "rand_life_lesson",
	title = "Life Lesson Learned",
	emoji = "📚",
	text = "Something happened that taught you an important lesson.",
	question = "What did you learn?",
	minAge = 16, maxAge = 80,
	baseChance = 0.35,
	cooldown = 5,
	stage = STAGE,
	ageBand = "any",
	category = "random",
	tags = { "lesson", "wisdom", "growth", "dynamic" },
	
	choices = {
		{
			text = "Not everyone has your best interest",
			effects = { Smarts = 3, Happiness = -3 },
			feedText = "📚 Hard lesson but important. Trust must be earned, not given.",
			setFlags = { street_smart = true, cautious = true },
		},
		{
			text = "Kindness is always worth it",
			effects = { Happiness = 8 },
			feedText = "📚 Being good came back around. What you give, you get.",
			setFlags = { believes_in_kindness = true },
		},
		{
			text = "Time heals most wounds",
			effects = { Happiness = 5 },
			feedText = "📚 Things that seemed unbearable before... you survived them all.",
			setFlags = { resilient = true },
		},
		{
			text = "Money isn't everything",
			effects = {},
			feedText = "True wealth...",
			onResolve = function(state)
				local money = state.Money or 0
				if money > 100000 then
					state:ModifyStat("Happiness", 10)
					state:AddFeed("📚 You have money and realized it doesn't guarantee happiness. Profound.")
				else
					state:ModifyStat("Happiness", 5)
					state:AddFeed("📚 Easy to say when you're broke? Maybe. But still feels true.")
				end
			end,
		},
	},
},
}

return RandomExpanded
