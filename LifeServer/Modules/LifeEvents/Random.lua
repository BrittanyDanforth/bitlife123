--[[
	Random Events
	Life's surprises - good and bad luck, unexpected situations
	These add variety but aren't tied to specific life stages
]]

local Random = {}

Random.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- LUCK & FORTUNE
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "found_money",
		title = "Lucky Find",
		emoji = "💵",
		text = "You found money on the ground!",
		-- CRITICAL FIX: Added text variations for more variety
		textVariants = {
			"You spotted a $20 bill blowing across the sidewalk!",
			"While walking, you noticed some cash someone dropped!",
			"A wallet lay abandoned on a bench - it had money inside!",
			"You kicked something and discovered it was cash!",
			"Some crumpled bills caught your eye near a trash can!",
			"A gust of wind blew money right toward you!",
		},
		question = "What do you do with it?",
		minAge = 6, maxAge = 90,
		baseChance = 0.45,
		cooldown = 3,
		choices = {
			{ text = "Keep it - finders keepers!", effects = { Happiness = 5, Money = 100 }, feedText = "You pocketed the cash. Lucky day!" },
			{ text = "Turn it in to lost and found", effects = { Happiness = 3 }, setFlags = { honest = true }, feedText = "You did the right thing." },
			{ text = "Donate it to charity", effects = { Happiness = 5 }, setFlags = { generous = true }, feedText = "You paid it forward." },
		},
	},
	{
		id = "lottery_scratch",
		title = "Scratch Ticket",
		emoji = "🎰",
		text = "Someone gave you a scratch lottery ticket.",
		question = "How do you scratch it?",
		minAge = 18, maxAge = 90,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		-- CRITICAL FIX: Can't gamble from prison!
		blockedByFlags = { in_prison = true, incarcerated = true },
		-- CRITICAL FIX: Random outcome instead of player picking result
		choices = {
			{ 
				text = "Scratch it excitedly!", 
				effects = {},
				feedText = "You scratch with anticipation...",
				onResolve = function(state)
					-- CRITICAL FIX: Added nil checks for all method calls
					local roll = math.random()
					if roll < 0.02 then -- 2% chance big winner
						state.Money = (state.Money or 0) + 5000
						if state.ModifyStat then state:ModifyStat("Happiness", 20) end
						if state.AddFeed then state:AddFeed("🎰 JACKPOT!!! You won $5,000! Incredible!") end
					elseif roll < 0.15 then -- 13% chance small prize
						state.Money = (state.Money or 0) + math.random(20, 100)
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddFeed then state:AddFeed("🎰 You won a small prize! Nice!") end
					else -- 85% nothing
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("🎰 Nothing. Better luck next time.") end
					end
				end,
			},
			{ 
				text = "Scratch it carefully and slowly", 
				effects = {},
				feedText = "You scratch methodically...",
				onResolve = function(state)
					-- CRITICAL FIX: Added nil checks for all method calls
					local roll = math.random()
					if roll < 0.02 then
						state.Money = (state.Money or 0) + 5000
						if state.ModifyStat then state:ModifyStat("Happiness", 20) end
						if state.AddFeed then state:AddFeed("🎰 JACKPOT!!! You won $5,000!") end
					elseif roll < 0.15 then
						state.Money = (state.Money or 0) + math.random(20, 100)
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddFeed then state:AddFeed("🎰 Small winner! A little cash.") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("🎰 Not a winner. Oh well.") end
					end
				end,
			},
			{ text = "Give it away - gambling isn't for me", effects = { Happiness = 2 }, feedText = "You gave the ticket to someone else." },
		},
	},
	{
		id = "inheritance",
		title = "Unexpected Inheritance",
		emoji = "📜",
		text = "A distant relative you barely knew passed away and left you something in their will.",
		-- CRITICAL FIX: Added text variations for more variety
		textVariants = {
			"Your great-uncle passed away, and you're named in his will!",
			"A distant cousin you've never met left you an inheritance!",
			"Your grandmother's estranged sister remembered you in her will!",
			"A family member from overseas passed and left you something!",
			"An old relative finally settled their estate - you're a beneficiary!",
		},
		question = "The lawyer calls you about the inheritance...",
		minAge = 25, maxAge = 80,
		baseChance = 0.4,
		cooldown = 4,
		oneTime = true,
		-- CRITICAL FIX #4: Added "inheritance" category for green/gold event card
		category = "inheritance",
		tags = { "inheritance", "money", "family" },
		-- CRITICAL FIX: Extra protection against repeats
		blockedByFlags = { in_prison = true, inheritance_received = true },
		-- CRITICAL FIX: Random inheritance instead of player picking what they get
		choices = {
			{
				text = "Attend the will reading",
				effects = {},
				feedText = "You attended the reading of the will...",
				onResolve = function(state)
					-- CRITICAL FIX: Added nil checks for all method calls
					state.Flags = state.Flags or {}
					state.Flags.inheritance_received = true -- CRITICAL FIX: Mark as done to prevent repeats
					local roll = math.random()
					if roll < 0.30 then -- 30% substantial money
						local amount = math.random(5000, 25000)
						state.Money = (state.Money or 0) + amount
						if state.ModifyStat then state:ModifyStat("Happiness", 12) end
						if state.AddFeed then state:AddFeed(string.format("📜 You inherited $%d! What a windfall!", amount)) end
					elseif roll < 0.50 then -- 20% house
						state.Flags.inherited_property = true
						state.Flags.homeowner = true
						state.Flags.has_property = true
						if state.ModifyStat then state:ModifyStat("Happiness", 10) end
						if state.AddAsset then
							state:AddAsset("Properties", {
								id = "inherited_house_" .. tostring(state.Age or 0),
								name = "Inherited House",
								emoji = "🏚️",
								price = 0,
								value = 120000,
								income = 800,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then state:AddFeed("📜 You inherited a house! It needs some work but it's yours.") end
					elseif roll < 0.70 then -- 20% heirloom
						state.Flags = state.Flags or {}
						state.Flags.has_heirloom = true
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddAsset then
							state:AddAsset("Items", {
								id = "family_heirloom_" .. tostring(state.Age or 0),
								name = "Family Heirloom",
								emoji = "🏺",
								price = 0,
								value = 2500,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then state:AddFeed("📜 You inherited a family heirloom. Interesting piece of history!") end
					elseif roll < 0.85 then -- 15% small amount
						local amount = math.random(500, 2000)
						state.Money = (state.Money or 0) + amount
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddFeed then state:AddFeed(string.format("📜 You inherited $%d. Every bit helps!", amount)) end
					else -- 15% debt
						local debt = math.random(1000, 5000)
						state.Money = math.max(0, (state.Money or 0) - debt)
						if state.ModifyStat then state:ModifyStat("Happiness", -8) end
						if state.AddFeed then state:AddFeed(string.format("📜 Bad news... you inherited $%d in debt!", debt)) end
					end
				end,
			},
			{
				text = "Decline the inheritance",
				effects = { Happiness = -2 },
				setFlags = { inheritance_received = true }, -- CRITICAL FIX: Mark as done to prevent repeats
				feedText = "You declined to accept the inheritance. You never know what strings were attached.",
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ACCIDENTS & MISHAPS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "minor_accident",
		title = "Ouch!",
		emoji = "🤕",
		text = "You had an accident!",
		question = "Do you seek medical attention?",
		minAge = 5, maxAge = 80,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "random", -- CRITICAL FIX: Added explicit category
		-- CRITICAL FIX: Can't have accidents in prison (different event set)
		blockedByFlags = { in_prison = true, incarcerated = true },
		-- CRITICAL FIX: Random injury type and severity
		choices = {
			{
				text = "Go to the doctor ($100)",
				effects = { Money = -100 },
				feedText = "You went to see a doctor...",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for doctor visit" end,
				onResolve = function(state)
					local roll = math.random()
					local injuries = {
						{ type = "Tripped and fell", health = -5, hap = -3 },
						{ type = "Cut yourself cooking", health = -3, hap = -2 },
						{ type = "Sports injury", health = -8, hap = -2, flag = "sports_injury" },
						{ type = "Stubbed toe badly", health = -2, hap = -5 },
						{ type = "Bumped your head", health = -6, hap = -4 },
						{ type = "Sprained your wrist", health = -7, hap = -3 },
					}
					local injury = injuries[math.random(#injuries)]
					-- AAA FIX: Nil check for ModifyStat
					if state.ModifyStat then
						state:ModifyStat("Health", injury.health)
						state:ModifyStat("Happiness", injury.hap)
					end
					if injury.flag then
						state.Flags = state.Flags or {}
						state.Flags[injury.flag] = true
					end
					-- Doctor visit helps a bit
					if state.ModifyStat then state:ModifyStat("Health", 3) end
					if state.AddFeed then state:AddFeed(string.format("🤕 %s. The doctor patched you up.", injury.type)) end
				end,
			},
			{
				text = "Tough it out",
				effects = {},
				feedText = "You decided to tough it out...",
				onResolve = function(state)
					local injuries = {
						{ type = "Tripped and fell", health = -5, hap = -3 },
						{ type = "Cut yourself cooking", health = -4, hap = -2 },
						{ type = "Sports injury", health = -10, hap = -4, flag = "sports_injury" },
						{ type = "Stubbed toe badly", health = -2, hap = -5 },
						{ type = "Bumped your head", health = -8, hap = -5 },
						{ type = "Sprained something", health = -9, hap = -4 },
					}
					local injury = injuries[math.random(#injuries)]
					-- AAA FIX: Nil check for ModifyStat
					if state.ModifyStat then
						state:ModifyStat("Health", injury.health)
						state:ModifyStat("Happiness", injury.hap)
					end
					if injury.flag then
						state.Flags = state.Flags or {}
						state.Flags[injury.flag] = true
					end
					if state.AddFeed then state:AddFeed(string.format("🤕 %s. You're healing slowly without medical help.", injury.type)) end
				end,
			},
		},
	},
	{
		id = "car_trouble",
		title = "Vehicle Problems",
		emoji = "🚗",
		text = "Your car broke down!",
		question = "How do you handle it?",
		minAge = 16, maxAge = 90,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresFlags = { has_car = true },
		-- CRITICAL FIX: Can't have car trouble in prison!
		blockedByFlags = { in_prison = true, incarcerated = true },
		choices = {
			{
				text = "Pay for repairs",
				-- CRITICAL FIX: Validate money before deducting
				effects = {}, -- Money handled in onResolve
				feedText = "Time to see what the damage is...",
				onResolve = function(state)
					local money = state.Money or 0
					local repairCost = 500
					if money >= repairCost then
						state.Money = money - repairCost
						if state.ModifyStat then state:ModifyStat("Happiness", -3) end
						if state.AddFeed then
							state:AddFeed("🔧 Paid $500 for repairs. Expensive, but car is fixed!")
						end
					elseif money >= 200 then
						-- Partial repair - cheaper option
						state.Money = money - 200
						if state.ModifyStat then state:ModifyStat("Happiness", -5) end
						if state.AddFeed then
							state:AddFeed("🔧 Could only afford $200 for basic repairs. Hopefully it holds...")
						end
					else
						-- Can't afford any repairs
						if state.ModifyStat then state:ModifyStat("Happiness", -8) end
						if state.AddFeed then
							state:AddFeed("💸 Can't afford repairs! Your car is broken down...")
						end
						-- Mark car as broken
						state.Flags = state.Flags or {}
						state.Flags.car_broken = true
					end
				end,
			},
			{
				text = "Try to fix it yourself",
				-- CRITICAL FIX: Validate money for DIY parts
				effects = {}, -- Money handled in onResolve
				feedText = "Time to get your hands dirty...",
				onResolve = function(state)
					local money = state.Money or 0
					local partsCost = 100
					if money >= partsCost then
						state.Money = money - partsCost
						if state.ModifyStat then 
							state:ModifyStat("Smarts", 3)
							state:ModifyStat("Health", -2)
						end
						if state.AddFeed then
							state:AddFeed("🔧 Bought $100 in parts and fixed it yourself! Learned something too.")
						end
					else
						-- Try without parts
						local roll = math.random()
						if roll < 0.3 then
							-- Lucky fix
							if state.ModifyStat then state:ModifyStat("Smarts", 2) end
							if state.AddFeed then
								state:AddFeed("🔧 Fixed it with what you had! Lucky!")
							end
						else
							-- Couldn't fix it
							if state.ModifyStat then 
								state:ModifyStat("Happiness", -5)
								state:ModifyStat("Health", -3)
							end
							if state.AddFeed then
								state:AddFeed("🔧 Couldn't fix it without proper parts...")
							end
							state.Flags = state.Flags or {}
							state.Flags.car_broken = true
						end
					end
				end,
			},
			{
				text = "Junk it and buy a new car",
				-- CRITICAL FIX: Validate money for new car purchase
				effects = {}, -- Money handled in onResolve
				feedText = "Considering a new vehicle...",
				onResolve = function(state)
					local money = state.Money or 0
					local newCarCost = 5000
					if money >= newCarCost then
						state.Money = money - newCarCost
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						-- Remove old car (first one found)
						local vehicles = state.Assets and state.Assets.Vehicles
						if vehicles and #vehicles > 0 then
							table.remove(vehicles, 1)
						end
						-- Add new car
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "replacement_car_" .. tostring(state.Age or 0),
								name = "New Reliable Car",
								emoji = "🚗",
								price = 5000,
								value = 4500,
								condition = 85,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then
							state:AddFeed("🚗 Bought a new car for $5000! Fresh start!")
						end
					elseif money >= 2000 then
						-- Can only afford used car
						state.Money = money - 2000
						if state.ModifyStat then state:ModifyStat("Happiness", 2) end
						local vehicles = state.Assets and state.Assets.Vehicles
						if vehicles and #vehicles > 0 then
							table.remove(vehicles, 1)
						end
						if state.AddAsset then
							state:AddAsset("Vehicles", {
								id = "used_car_" .. tostring(state.Age or 0),
								name = "Used Car",
								emoji = "🚗",
								price = 2000,
								value = 1500,
								condition = 60,
								isEventAcquired = true,
							})
						end
						if state.AddFeed then
							state:AddFeed("🚗 Could only afford a $2000 used car. Better than nothing!")
						end
					else
						-- Can't afford new car
						if state.ModifyStat then state:ModifyStat("Happiness", -10) end
						if state.AddFeed then
							state:AddFeed("💸 Can't afford a new car! Stuck without wheels...")
						end
						-- Remove broken car
						local vehicles = state.Assets and state.Assets.Vehicles
						if vehicles and #vehicles > 0 then
							table.remove(vehicles, 1)
						end
						state.Flags = state.Flags or {}
						state.Flags.has_car = nil
						state.Flags.has_vehicle = nil
					end
				end,
			},
			{
				text = "Sell it for scrap and take the bus",
				effects = { Money = 300, Happiness = -5 },
				feedText = "You sold the heap and went back to public transit.",
				onResolve = function(state)
					-- Remove first vehicle
					local vehicles = state.Assets and state.Assets.Vehicles
					if vehicles and #vehicles > 0 then
						table.remove(vehicles, 1)
					end
					-- Clear vehicle flags if no vehicles left
					if state.Flags and (not vehicles or #vehicles == 0) then
						state.Flags.has_car = nil
						state.Flags.has_vehicle = nil
					end
				end,
			},
		},
	},
	{
		id = "phone_broke",
		title = "Phone Disaster",
		emoji = "📱",
		text = "Your phone is broken/lost!",
		question = "What do you do?",
		minAge = 12, maxAge = 80,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		-- CRITICAL FIX #6: Can't lose phone in prison (no phones!)
		blockedByFlags = { in_prison = true, incarcerated = true },
		choices = {
			-- CRITICAL FIX: Add money validation to prevent buying with no money
			{ 
				text = "Get the latest model", 
				effects = {}, -- Money handled in onResolve to validate first
				feedText = "You want the latest model...",
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 800 then
						state.Money = money - 800
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						if state.AddFeed then state:AddFeed("📱 New phone! It's shiny and does everything. $800 well spent!") end
					elseif money >= 200 then
						-- Can only afford basic model
						state.Money = money - 200
						if state.ModifyStat then state:ModifyStat("Happiness", 2) end
						if state.AddFeed then state:AddFeed("📱 Couldn't afford the latest model, got a basic one instead.") end
					else
						-- Can't afford anything
						if state.ModifyStat then state:ModifyStat("Happiness", -5) end
						if state.AddFeed then state:AddFeed("📱 Can't afford a new phone. Going phoneless for now...") end
					end
				end,
			},
			{ 
				text = "Get a basic replacement", 
				effects = {}, -- Money handled in onResolve to validate first
				feedText = "You look for a basic replacement...",
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 200 then
						state.Money = money - 200
						if state.ModifyStat then state:ModifyStat("Happiness", 2) end
						if state.AddFeed then state:AddFeed("📱 Got a basic replacement phone. It works. That's what matters.") end
					else
						-- Can't afford even the basic model
						if state.ModifyStat then state:ModifyStat("Happiness", -5) end
						if state.AddFeed then state:AddFeed("📱 Can't even afford a basic phone. Living disconnected now...") end
					end
				end,
			},
			{ 
				text = "Fix the old one", 
				effects = {}, -- Money handled in onResolve to validate first
				feedText = "You try to get it repaired...",
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 100 then
						state.Money = money - 100
						if state.ModifyStat then
							state:ModifyStat("Happiness", 3)
							state:ModifyStat("Smarts", 2)
						end
						if state.AddFeed then state:AddFeed("📱 Repaired your old phone. Good as new (almost). Saved $700!") end
					else
						-- Try DIY fix
						if state.ModifyStat then
							state:ModifyStat("Smarts", 3) -- Learn something at least
							state:ModifyStat("Happiness", math.random() > 0.5 and 2 or -3)
						end
						if state.AddFeed then state:AddFeed("📱 No money for repairs. Tried fixing it yourself with YouTube tutorials...") end
					end
				end,
			},
			{ text = "Go without for a while", effects = { Happiness = -5 }, feedText = "Living disconnected. It's... different." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- HEALTH & WELLNESS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "caught_cold",
		title = "Under the Weather",
		emoji = "🤧",
		text = "You caught a cold.",
		question = "How do you handle being sick?",
		minAge = 3, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{ text = "Rest up properly", effects = { Health = 3, Happiness = -2 }, feedText = "You took care of yourself." },
			{ text = "Push through it", effects = { Health = -3, Happiness = -3 }, feedText = "You kept going. Probably not wise." },
			{ text = "Home remedies", effects = { Health = 2 }, feedText = "Soup and tea worked wonders." },
			{ text = "See a doctor ($100)", effects = { Health = 5, Money = -100 }, feedText = "The doctor helped you recover faster.", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for doctor visit" end },
		},
	},
	{
		id = "fitness_moment",
		title = "Health Motivation",
		emoji = "💪",
		text = "You're feeling motivated to get in better shape.",
		question = "What do you do?",
		minAge = 15, maxAge = 70,
		baseChance = 0.55,
		cooldown = 3,
		choices = {
			{ text = "Start going to the gym ($50)", effects = { Health = 8, Happiness = 5, Money = -50 }, setFlags = { gym_member = true }, feedText = "You signed up for a gym membership! Time to get fit and feel great.", eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 for gym membership" end },
			{ text = "Take up running", effects = { Health = 7, Happiness = 3 }, setFlags = { runner = true }, feedText = "You started running regularly!" },
			{ text = "Try a new sport", effects = { Health = 5, Happiness = 7 }, feedText = "You picked up a new sport!" },
			{ text = "Eh, motivation faded", effects = { Happiness = -2 }, feedText = "The motivation was short-lived." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- SOCIAL ENCOUNTERS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "encounter_celebrity",
		title = "Celebrity Sighting",
		emoji = "⭐",
		text = "You ran into a celebrity!",
		question = "What do you do?",
		minAge = 10, maxAge = 80,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{ text = "Ask for a selfie", effects = { Happiness = 10 }, feedText = "You got a photo with a celebrity!" },
			{ text = "Play it cool", effects = { Happiness = 5, Smarts = 2 }, feedText = "You acted casual. Smooth." },
			{ text = "Totally fanboy/fangirl", effects = { Happiness = 7, Looks = -2 }, feedText = "You couldn't contain your excitement!" },
			{ text = "Didn't recognize them", effects = { Happiness = -1 }, feedText = "Wait, who was that? You pretended to recognize them but had no idea. Awkward!" },
		},
	},
	{
		id = "random_kindness",
		title = "Random Act of Kindness",
		emoji = "💝",
		text = "A stranger did something unexpectedly kind for you.",
		question = "How did it make you feel?",
		minAge = 5, maxAge = 90,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{ text = "Restored faith in humanity", effects = { Happiness = 10 }, feedText = "People can be so good!" },
			{ text = "Inspired to pay it forward", effects = { Happiness = 8 }, setFlags = { pays_it_forward = true }, feedText = "You'll do the same for someone else!" },
			{ text = "Suspicious of their motives", effects = { Happiness = 2, Smarts = 2 }, feedText = "You wondered what they wanted." },
		},
	},
	{
		id = "awkward_encounter",
		title = "Awkward Moment",
		emoji = "😬",
		text = "You had an embarrassing moment in public.",
		question = "How do you handle it?",
		minAge = 10, maxAge = 80,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{ text = "Laugh it off", effects = { Happiness = 5 }, setFlags = { good_sport = true }, feedText = "You laughed at yourself. Best approach!" },
			{ text = "Die of embarrassment", effects = { Happiness = -5 }, feedText = "You wanted to disappear." },
			{ text = "Pretend nothing happened", effects = { Happiness = 2 }, feedText = "Maybe no one noticed..." },
			{ text = "Make it a funny story", effects = { Happiness = 7 }, feedText = "This will be a great story later!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- EVERYDAY LIFE
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		-- CRITICAL FIX: Was god-mode - player picked weather outcome!
		-- Now weather is random, player just chooses how to react
		id = "weather_event",
		title = "Weather Alert",
		emoji = "🌦️",
		text = "There's unusual weather today that might affect your plans.",
		question = "How do you handle it?",
		minAge = 5, maxAge = 90,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{ 
				text = "Make the most of it", 
				effects = { },
				feedText = "You checked the weather...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					if roll <= 40 then
						if state.ModifyStat then
							state:ModifyStat("Happiness", 7)
							state:ModifyStat("Health", 3)
						end
						if state.AddFeed then
							state:AddFeed("☀️ Beautiful day! You enjoyed every minute.")
						end
					elseif roll <= 60 then
						if state.ModifyStat then
							state:ModifyStat("Happiness", 3)
						end
						if state.AddFeed then
							state:AddFeed("🌧️ Rainy day. Cozy time indoors.")
						end
					elseif roll <= 80 then
						if state.ModifyStat then
							state:ModifyStat("Happiness", 5)
							state:ModifyStat("Health", 2)
						end
						if state.AddFeed then
							state:AddFeed("❄️ Snow day! You had fun in the snow.")
						end
					else
						if state.ModifyStat then
							state:ModifyStat("Happiness", -3)
							state:ModifyStat("Health", -2)
						end
						if state.AddFeed then
							state:AddFeed("🥵 Heat wave! Brutal day.")
						end
					end
				end,
			},
			{ text = "Stay inside regardless", effects = { Happiness = 1 }, feedText = "You played it safe and stayed in." },
		},
	},
	{
		-- CRITICAL FIX: Lost item is now RANDOM - you don't choose what you lost!
		id = "lost_item",
		title = "Where Did It Go?",
		emoji = "🔍",
		text = "You can't find something important. You've searched everywhere!",
		question = "How hard do you search?",
		minAge = 5, maxAge = 90,
		baseChance = 0.55,
		cooldown = 3,
		choices = {
			{
				text = "Tear the house apart looking",
				effects = { Health = -2 },
				feedText = "You searched everywhere...",
				onResolve = function(state)
					local items = {
						{ text = "🔑 Your keys! Found them in the couch cushions. Phew!", happy = 2, money = 0 },
						{ text = "💳 Your wallet was gone! Had to cancel cards and lost $50 cash.", happy = -8, money = -50 },
						{ text = "📱 Your phone! It was in the fridge. How did that happen?", happy = -2, money = 0 },
						{ text = "💍 Something sentimental... gone forever. Irreplaceable.", happy = -12, money = 0 },
						{ text = "🎧 Your headphones. Never found them. Had to buy new ones.", happy = -5, money = -80 },
					}
					local item = items[math.random(1, #items)]
					state:ModifyStat("Happiness", item.happy)
					state.Money = math.max(0, (state.Money or 0) + item.money)
					if state.AddFeed then state:AddFeed(item.text) end
				end,
			},
			{
				text = "Check the obvious spots and move on",
				effects = {},
				feedText = "Quick search...",
				onResolve = function(state)
					if math.random() < 0.4 then
						state:ModifyStat("Happiness", 3)
						if state.AddFeed then state:AddFeed("🔍 Found it quickly! Crisis averted.") end
					else
						state:ModifyStat("Happiness", -5)
						state.Money = math.max(0, (state.Money or 0) - math.random(20, 100))
						if state.AddFeed then state:AddFeed("🔍 Never found it. Had to replace it.") end
					end
				end,
			},
			{
				text = "Give up - it's probably gone",
				effects = { Happiness = -4, Money = -50 },
				feedText = "You gave up and accepted the loss.",
			},
		},
	},
	{
		id = "new_hobby",
		title = "New Interest",
		emoji = "🎯",
		text = "You've discovered a new hobby!",
		question = "What caught your interest?",
		minAge = 10, maxAge = 80,
		baseChance = 0.55,
		cooldown = 3,
		choices = {
			{ text = "Gaming", effects = { Happiness = 7, Smarts = 2 }, setFlags = { gamer = true }, feedText = "You discovered video games and became hooked! Your reaction time improved." },
			{ text = "Crafting/DIY", effects = { Happiness = 5, Smarts = 3 }, setFlags = { crafter = true }, feedText = "You love making things!" },
			{ text = "Cooking/Baking", effects = { Happiness = 6, Health = 2 }, setFlags = { foodie = true }, feedText = "You're exploring the kitchen!" },
			{ text = "Reading", effects = { Smarts = 5, Happiness = 4 }, setFlags = { bookworm = true }, feedText = "Books are your new escape!" },
			{ text = "Outdoor activities", effects = { Health = 5, Happiness = 5 }, setFlags = { outdoorsy = true }, feedText = "You discovered a love for the outdoors! Hiking, camping, and fresh air became your thing." },
			{ text = "Music", effects = { Happiness = 7 }, setFlags = { musician = true }, feedText = "You're learning music!" },
		},
	},
	{
		id = "social_media_moment",
		title = "Internet Fame",
		emoji = "📲",
		text = "Something you posted went viral!",
		question = "How do you handle the attention?",
		minAge = 13, maxAge = 60,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #604: Viral events REQUIRE player to have actually posted content!
		-- User complaint: "Video went viral but I never posted any videos"
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Player MUST have some form of online activity!
			local hasOnlinePresence = flags.content_creator or flags.streamer or flags.influencer
				or flags.first_video_posted or flags.first_video_uploaded or flags.youtube_started
				or flags.social_media_active or flags.pursuing_streaming or flags.youtube_channel
				or flags.internet_famous or flags.gaming_content or flags.vlogger
			if not hasOnlinePresence then
				return false, "Player hasn't posted content yet"
			end
			return true
		end,
		
		choices = {
			{ text = "Embrace the fame", effects = { Happiness = 10, Money = 100 }, setFlags = { internet_famous = true }, feedText = "You're internet famous!" },
			{ text = "Stay humble", effects = { Happiness = 5, Smarts = 2 }, feedText = "You kept perspective." },
			{ text = "Delete everything", effects = { Happiness = -3 }, feedText = "The attention was too much." },
			{ text = "Try to monetize it", effects = { Money = 500, Smarts = 2 }, setFlags = { content_creator = true }, feedText = "You turned it into income!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- OPPORTUNITIES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "travel_opportunity",
		title = "Travel Opportunity",
		emoji = "✈️",
		text = "An opportunity to travel came up unexpectedly!",
		question = "Do you go?",
		minAge = 18, maxAge = 75,
		baseChance = 0.55,
		cooldown = 3,
		-- CRITICAL FIX #4: Can't travel from prison!
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true },
		-- CRITICAL FIX: Need at least $1000 to consider traveling (the adventure option costs $1000)
		eligibility = function(state)
			local money = state.Money or 0
			if money < 300 then
				return false, "Can't afford to travel"
			end
			return true
		end,
		choices = {
			{ text = "Absolutely, adventure awaits! ($1000)", effects = { Happiness = 12, Money = -1000 }, setFlags = { well_traveled = true }, feedText = "You went on an amazing trip!",
				eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Can't afford the full trip ($1000 needed)" end,
			},
			{ text = "Go on a budget ($300)", effects = { Happiness = 7, Money = -300 }, setFlags = { well_traveled = true }, feedText = "You traveled smart!",
				eligibility = function(state) return (state.Money or 0) >= 300, "💸 Can't afford even a budget trip ($300 needed)" end,
			},
			{ text = "Not the right time (Save money)", effects = { Happiness = -2, Money = 200 }, feedText = "You saved the money instead." },
		},
	},
	{
		id = "volunteer_moment",
		title = "Helping Others",
		emoji = "🤝",
		text = "You spent some time helping others in need.",
		question = "How did it feel?",
		minAge = 12, maxAge = 90,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{ text = "Incredibly rewarding", effects = { Happiness = 10 }, setFlags = { volunteer = true, community_minded = true }, feedText = "Helping others filled your heart." },
			{ text = "Eye-opening experience", effects = { Happiness = 5, Smarts = 3 }, setFlags = { volunteer = true }, feedText = "You gained perspective." },
			{ text = "Harder than expected", effects = { Happiness = 3, Health = -2 }, setFlags = { volunteer = true }, feedText = "It was tough but meaningful." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- INJURY SYSTEM - BITLIFE STYLE "WHERE DID YOU GET HURT?"
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "injury_fall",
		title = "Bad Fall!",
		emoji = "🤕",
		text = "You took a nasty fall!",
		question = "Do you go to the hospital?",
		minAge = 3, maxAge = 85,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "injury",
		-- CRITICAL FIX: Random injury location/severity
		choices = {
			{
				text = "Go to the emergency room ($500)",
				effects = { Money = -500 },
				feedText = "You rushed to the ER...",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Can't afford ER visit ($500 needed) - try home treatment" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.10 then -- 10% head injury
						state:ModifyStat("Health", -12)
						state:ModifyStat("Smarts", -2)
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.head_injury = true
						state:AddFeed("🤕 You hit your head badly. Doctors are monitoring you closely.")
					elseif roll < 0.25 then -- 15% broken arm
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.broken_arm = true
						state:AddFeed("🤕 You broke your arm! Months in a cast.")
					elseif roll < 0.40 then -- 15% broken leg
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.broken_leg = true
						state:AddFeed("🤕 You broke your leg. Crutches for months.")
					elseif roll < 0.50 then -- 10% back injury
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -12)
						state.Flags = state.Flags or {}
						state.Flags.back_injury = true
						state:AddFeed("🤕 Back injury. This might be a long recovery.")
					else -- 50% minor
						state:ModifyStat("Health", -4)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤕 Just some scrapes and bruises. You got lucky!")
					end
				end,
			},
			{
				text = "Wait and see if it heals",
				effects = {},
				feedText = "You decided to wait it out...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.15 then -- Worse outcomes when not treated
						state:ModifyStat("Health", -18)
						state:ModifyStat("Smarts", -2)
						state:ModifyStat("Happiness", -12)
						state.Flags = state.Flags or {}
						state.Flags.head_injury = true
						state:AddFeed("🤕 Your head injury got worse. Should've gone to the hospital!")
					elseif roll < 0.35 then
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.broken_arm = true
						state:AddFeed("🤕 Your arm is definitely broken. Healing crooked now.")
					elseif roll < 0.55 then
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.broken_leg = true
						state:AddFeed("🤕 That leg is broken. Should've gotten it set properly.")
					elseif roll < 0.65 then
						state:ModifyStat("Health", -20)
						state:ModifyStat("Happiness", -15)
						state.Flags = state.Flags or {}
						state.Flags.back_injury = true
						state:AddFeed("🤕 Back is messed up. This is going to be chronic.")
					else
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤕 Just bruises. Healed up fine on your own.")
					end
				end,
			},
		},
	},
	{
		id = "injury_sports",
		title = "Sports Injury!",
		emoji = "⚽",
		text = "You got injured playing sports!",
		question = "How do you respond?",
		minAge = 6, maxAge = 60,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "injury",
		-- CRITICAL FIX: Random injury type and severity
		choices = {
			{
				text = "Get medical attention immediately",
				effects = { Money = -300 },
				feedText = "You got checked out right away...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.15 then -- Ankle
						state:ModifyStat("Health", -8)
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.sprained_ankle = true
						state:AddFeed("⚽ Sprained ankle. A few weeks off your feet.")
					elseif roll < 0.25 then -- ACL - serious
						state:ModifyStat("Health", -18)
						state:ModifyStat("Happiness", -12)
						state.Money = math.max(0, (state.Money or 0) - 2000)
						state.Flags = state.Flags or {}
						state.Flags.acl_injury = true
						state.Flags.needs_surgery = true
						state:AddFeed("⚽ Torn ACL! Surgery required. Season's over.")
					elseif roll < 0.35 then -- Shoulder
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -7)
						state.Flags = state.Flags or {}
						state.Flags.shoulder_injury = true
						state:AddFeed("⚽ Dislocated shoulder. Popped back in at the ER.")
					elseif roll < 0.45 then -- Face
						state:ModifyStat("Health", -6)
						state:ModifyStat("Looks", -2)
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.facial_injury = true
						state:AddFeed("⚽ Took one to the face. Bruised but healing.")
					elseif roll < 0.55 then -- Concussion
						state:ModifyStat("Health", -12)
						state:ModifyStat("Smarts", -2)
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.concussion = true
						state:AddFeed("⚽ Concussion. Doctor says take it easy.")
					else -- Minor
						state:ModifyStat("Health", -3)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("⚽ Just a minor strain. Nothing serious!")
					end
				end,
			},
			{
				text = "Walk it off - it's probably fine",
				effects = {},
				feedText = "You tried to play through it...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.20 then -- Ankle - worse without treatment
						state:ModifyStat("Health", -12)
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.sprained_ankle = true
						state:AddFeed("⚽ That ankle is really messed up now. Should've stopped playing.")
					elseif roll < 0.35 then -- ACL
						state:ModifyStat("Health", -22)
						state:ModifyStat("Happiness", -15)
						state.Flags = state.Flags or {}
						state.Flags.acl_injury = true
						state.Flags.needs_surgery = true
						state:AddFeed("⚽ Something snapped in your knee. This is serious.")
					elseif roll < 0.50 then -- Concussion undetected
						state:ModifyStat("Health", -18)
						state:ModifyStat("Smarts", -4)
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.concussion = true
						state:AddFeed("⚽ That was a concussion. Playing through it made it worse.")
					else -- Lucked out
						state:ModifyStat("Health", -4)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("⚽ Just a minor strain. Walked it off successfully.")
					end
				end,
			},
		},
	},
	{
		id = "injury_car_accident",
		title = "Car Accident!",
		emoji = "🚗💥",
		text = "You were in a car accident!",
		question = "The ambulance arrives. What do you do?",
		minAge = 16, maxAge = 90,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "injury",
		-- CRITICAL FIX #1: MUST have a car to get in a car accident!
		requiresFlags = { has_car = true },
		-- Also can be a passenger with a license
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Has a car OR has a license (could be in someone else's car)
			return flags.has_car or flags.has_vehicle or flags.car_owner or flags.has_license
		end,
		blockedByFlags = { in_prison = true },
		-- CRITICAL FIX: Random accident severity - player doesn't choose how hurt they are
		choices = {
			{
				text = "Accept emergency care",
				effects = { Money = -1000 },
				feedText = "Paramedics rushed you to the hospital...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.05 then -- 5% severe trauma
						state:ModifyStat("Health", -32)
						state:ModifyStat("Smarts", -4)
						state:ModifyStat("Happiness", -18)
						state.Money = math.max(0, (state.Money or 0) - 8000)
						state.Flags = state.Flags or {}
						state.Flags.traumatic_injury = true
						state.Flags.hospitalized = true
						state:AddFeed("🚗💥 Severe head trauma. You're in the ICU.")
					elseif roll < 0.15 then -- 10% multiple fractures
						state:ModifyStat("Health", -25)
						state:ModifyStat("Happiness", -15)
						state.Money = math.max(0, (state.Money or 0) - 4000)
						state.Flags = state.Flags or {}
						state.Flags.multiple_fractures = true
						state.Flags.hospitalized = true
						state:AddFeed("🚗💥 Multiple broken bones. Long recovery ahead.")
					elseif roll < 0.30 then -- 15% broken ribs
						state:ModifyStat("Health", -18)
						state:ModifyStat("Happiness", -12)
						state.Flags = state.Flags or {}
						state.Flags.broken_ribs = true
						state:AddFeed("🚗💥 Broken ribs. Every breath hurts.")
					elseif roll < 0.50 then -- 20% whiplash
						state:ModifyStat("Health", -8)
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.whiplash = true
						state:AddFeed("🚗💥 Whiplash. Neck is sore but you'll recover.")
					elseif roll < 0.70 then -- 20% car totaled but okay
						state:ModifyStat("Health", -3)
						state:ModifyStat("Happiness", -8)
						local vehicles = state.Assets and state.Assets.Vehicles
						if vehicles and #vehicles > 0 then
							table.remove(vehicles, 1)
						end
						if state.Flags then
							state.Flags.has_car = nil
						end
						state:AddFeed("🚗💥 Car is totaled but you walked away mostly fine!")
					else -- 30% walked away fine
						state:ModifyStat("Health", -2)
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🚗💥 Incredibly lucky! Just shaken up.")
					end
				end,
			},
			{
				text = "Refuse treatment - I'm fine",
				effects = {},
				feedText = "You refused to go to the hospital...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.10 then -- Untreated injuries are worse
						state:ModifyStat("Health", -40)
						state:ModifyStat("Smarts", -5)
						state:ModifyStat("Happiness", -20)
						state.Flags = state.Flags or {}
						state.Flags.traumatic_injury = true
						state.Flags.hospitalized = true
						state:AddFeed("🚗💥 You collapsed later. Internal bleeding! Emergency surgery.")
					elseif roll < 0.30 then
						state:ModifyStat("Health", -30)
						state:ModifyStat("Happiness", -15)
						state.Flags = state.Flags or {}
						state.Flags.multiple_fractures = true
						state:AddFeed("🚗💥 Turns out multiple bones were broken. Bad decision.")
					elseif roll < 0.50 then
						state:ModifyStat("Health", -20)
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.broken_ribs = true
						state:AddFeed("🚗💥 Those ribs were definitely broken. Ouch.")
					else
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🚗💥 You got lucky - nothing serious this time.")
					end
				end,
			},
		},
	},
	{
		-- CRITICAL FIX: Was god-mode - player picked how they got injured!
		-- Now injury type is random, player responds to situation
		id = "injury_work_accident",
		title = "Workplace Accident!",
		emoji = "🏭",
		text = "There's been an accident at work! You got hurt.",
		question = "How do you handle it?",
		minAge = 16, maxAge = 70,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "injury",
		requiresJob = true,

		choices = {
			{ 
				text = "File for workers' compensation", 
				effects = { },
				feedText = "You filed a claim...",
				onResolve = function(state)
					-- Random injury type
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 20 then
						-- Serious: ladder fall
						state.Flags.workplace_injury = true
						state.Money = (state.Money or 0) + 2000
						if state.ModifyStat then
							state:ModifyStat("Health", -18)
							state:ModifyStat("Happiness", -10)
						end
						if state.AddFeed then
							state:AddFeed("🏭 Fell off a ladder. Serious injury but workers' comp helped.")
						end
					elseif roll <= 40 then
						-- RSI
						state.Flags.rsi = true
						if state.ModifyStat then
							state:ModifyStat("Health", -8)
							state:ModifyStat("Happiness", -5)
						end
						if state.AddFeed then
							state:AddFeed("🏭 Repetitive strain injury diagnosed. Need to take breaks.")
						end
					elseif roll <= 55 then
						-- Heavy object
						state.Flags.workplace_injury = true
						state.Flags.hospitalized = true
						state.Money = (state.Money or 0) + 3000
						if state.ModifyStat then
							state:ModifyStat("Health", -25)
							state:ModifyStat("Happiness", -15)
						end
						if state.AddFeed then
							state:AddFeed("🏭 Heavy equipment fell on you. Hospitalized but compensated.")
						end
					else
						-- Minor cut
						if state.ModifyStat then
							state:ModifyStat("Health", -3)
							state:ModifyStat("Happiness", -2)
						end
						if state.AddFeed then
							state:AddFeed("🏭 Minor cut. First aid was enough.")
						end
					end
				end,
			},
			{ text = "Tough it out - don't report it", effects = { Health = -10, Happiness = -5 }, feedText = "You didn't report it. Hopefully it heals on its own." },
		},
	},
	{
		-- CRITICAL FIX: Was god-mode - player picked how they got injured!
		-- Now injury is random, player chooses how to respond
		id = "injury_home_accident",
		title = "Accident at Home!",
		emoji = "🏠",
		text = "You had an accident at home and got hurt!",
		question = "What do you do?",
		minAge = 3, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "injury",

		choices = {
			{ 
				text = "Get medical attention", 
				effects = { },
				feedText = "You assessed the damage...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 25 then
						-- Bathroom slip
						state.Flags.bathroom_fall = true
						if state.ModifyStat then
							state:ModifyStat("Health", -12)
							state:ModifyStat("Happiness", -8)
						end
						if state.AddFeed then
							state:AddFeed("🏠 Slipped in the bathroom. Bruised but okay.")
						end
					elseif roll <= 50 then
						-- Cooking burn
						if state.ModifyStat then
							state:ModifyStat("Health", -8)
							state:ModifyStat("Happiness", -5)
						end
						if state.AddFeed then
							state:AddFeed("🏠 Burned yourself cooking. Painful but will heal.")
						end
					elseif roll <= 75 then
						-- Cut
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 200)
						if state.ModifyStat then
							state:ModifyStat("Health", -10)
							state:ModifyStat("Happiness", -6)
						end
						if state.AddFeed then
							state:AddFeed("🏠 Deep cut. Needed stitches at urgent care.")
						end
					else
						-- Stairs
						state.Flags.stair_fall = true
						if state.ModifyStat then
							state:ModifyStat("Health", -20)
							state:ModifyStat("Happiness", -12)
						end
						if state.AddFeed then
							state:AddFeed("🏠 Fell down the stairs. Major bruising!")
						end
					end
				end,
			},
			{ text = "Walk it off", effects = { Health = -8, Happiness = -3 }, feedText = "You toughed it out. Hopefully nothing's broken." },
			{ text = "Furniture fell on me", effects = { Health = -15, Happiness = -8 }, feedText = "Furniture accident. That bookshelf was heavy!" },
			{ text = "Stubbed toe - broken", effects = { Health = -5, Happiness = -8 }, setFlags = { broken_toe = true }, feedText = "Broken toe! Such a small thing, so much pain!" },
		},
	},
	{
		-- CRITICAL FIX #10: Was god-mode - player chose injury! Now random with response choices.
		id = "injury_attack",
		title = "Attacked!",
		emoji = "👊",
		text = "Someone attacked you on the street!",
		question = "What do you do?",
		minAge = 12, maxAge = 80,
		baseChance = 0.32,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "injury",
		blockedByFlags = { in_prison = true },

		choices = {
			{ 
				text = "👊 FIGHT BACK!", 
				effects = {},
				feedText = "You stood your ground...",
				-- CRITICAL FIX: Trigger fight minigame for confrontational choice!
				triggerMinigame = "fight",
				minigameOptions = { difficulty = "medium" },
				onResolve = function(state, minigameResult)
					-- If minigame was played, use its result
					local won = minigameResult and (minigameResult.success or minigameResult.won)
					
					if won then
						-- Player won the fight!
						state:ModifyStat("Health", -8)
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.self_defense = true
						state.Flags.fighter = true
						state:AddFeed("👊 You won the fight! They won't mess with you again!")
					else
						-- Player lost the fight - severity based on their health
						local health = (state.Stats and state.Stats.Health) or 50
						local severity = math.random(1, 100)
						
						if severity < 60 then
							-- Minor loss
							state:ModifyStat("Health", -15)
							state:ModifyStat("Looks", -3)
							state:ModifyStat("Happiness", -12)
							state.Flags = state.Flags or {}
							state.Flags.assault_victim = true
							state:AddFeed("👊 You got beaten up badly. Black eye and bruises.")
						elseif severity < 85 then
							-- Moderate loss
							state:ModifyStat("Health", -25)
							state:ModifyStat("Smarts", -2)
							state:ModifyStat("Happiness", -18)
							state.Flags = state.Flags or {}
							state.Flags.assault_victim = true
							state.Flags.concussion = true
							state:AddFeed("👊 Knocked unconscious. Woke up in the hospital.")
						else
							-- Severe loss
							state:ModifyStat("Health", -40)
							state:ModifyStat("Happiness", -25)
							state.Money = math.max(0, (state.Money or 0) - 5000)
							state.Flags = state.Flags or {}
							state.Flags.stabbing_victim = true
							state.Flags.hospitalized = true
							state:AddFeed("👊 They had a knife. You were stabbed. Critical condition.")
						end
					end
				end,
			},
			{ 
				text = "Run away!", 
				effects = {},
				feedText = "You tried to escape...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					local escape_bonus = health > 60 and 0.20 or 0
					
					if roll < (0.50 + escape_bonus) then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("👊 You got away! Heart pounding, but safe.")
					elseif roll < 0.80 then
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -10)
						state.Money = math.max(0, (state.Money or 0) - math.random(100, 500))
						state.Flags = state.Flags or {}
						state.Flags.robbery_victim = true
						state:AddFeed("👊 They caught up. Robbed you and roughed you up.")
					else
						state:ModifyStat("Health", -18)
						state:ModifyStat("Happiness", -15)
						state.Flags = state.Flags or {}
						state.Flags.assault_victim = true
						state:AddFeed("👊 Tripped while running. They caught you and beat you up.")
					end
				end,
			},
			{ 
				text = "Give them what they want", 
				effects = {},
				feedText = "You cooperated...",
				onResolve = function(state)
					local roll = math.random()
					local money_lost = math.random(100, 800)
					state.Money = math.max(0, (state.Money or 0) - money_lost)
					
					if roll < 0.60 then
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.robbery_victim = true
						state:AddFeed(string.format("👊 They took $%d and left. Shaken but okay.", money_lost))
					else
						state:ModifyStat("Health", -12)
						state:ModifyStat("Happiness", -15)
						state.Flags = state.Flags or {}
						state.Flags.robbery_victim = true
						state.Flags.assault_victim = true
						state:AddFeed("👊 They took your stuff AND beat you up anyway.")
					end
				end,
			},
		},
	},
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- ROAD RAGE ENCOUNTER WITH COMBAT
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "road_rage",
		title = "Road Rage!",
		emoji = "🚗",
		text = "Someone just cut you off in traffic and is now getting out of their car! They look furious!",
		question = "The driver is approaching your car aggressively...",
		minAge = 16, maxAge = 80,
		baseChance = 0.25,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "confrontation",
		blockedByFlags = { in_prison = true },
		-- CRITICAL FIX: Eligibility check for vehicle ownership - can't have road rage without a car!
		eligibility = function(state)
			-- Check if player owns any vehicles
			if state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0 then
				return true
			end
			-- Also check flags for basic car ownership
			if state.Flags and (state.Flags.has_car or state.Flags.has_vehicle or state.Flags.has_license) then
				return true
			end
			return false, "You need a car to experience road rage"
		end,
		
		choices = {
			{
				text = "🚪 Get out and confront them!",
				effects = {},
				feedText = "You stepped out of your car...",
				-- CRITICAL: Trigger the combat minigame!
				triggerMinigame = "combat",
				minigameOptions = { 
					context = "street",
					difficulty = "average",
					opponentDescription = "Angry Driver"
				},
				onResolve = function(state, minigameResult)
					local won = minigameResult and (minigameResult.success or minigameResult.won)
					
					if won then
						-- Player won the road rage fight!
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.road_rage_winner = true
						state:AddFeed("🚗👊 You taught that driver a lesson! They won't road rage again.")
					else
						-- Player lost
						local severity = math.random(1, 100)
						if severity < 50 then
							state:ModifyStat("Health", -15)
							state:ModifyStat("Happiness", -12)
							state:AddFeed("🚗👊 You got beat up on the side of the road. Humiliating.")
						elseif severity < 80 then
							state:ModifyStat("Health", -25)
							state:ModifyStat("Happiness", -18)
							state.Money = math.max(0, (state.Money or 0) - 2000)
							state.Flags = state.Flags or {}
							state.Flags.hospitalized = true
							state:AddFeed("🚗👊 The fight went badly. You needed hospital treatment.")
						else
							-- Legal trouble
							state:ModifyStat("Health", -10)
							state:ModifyStat("Happiness", -25)
							state.Money = math.max(0, (state.Money or 0) - 5000)
							state.Flags = state.Flags or {}
							state.Flags.assault_charge = true
							state:AddFeed("🚗👊 Witnesses called police. You both got arrested for assault!")
						end
					end
				end,
			},
			{
				text = "🔒 Stay in car, lock doors",
				effects = {},
				feedText = "You locked your doors...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🚗 They banged on your window and yelled, but eventually drove off.")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", -8)
						state.Money = math.max(0, (state.Money or 0) - math.random(200, 800))
						state:AddFeed("🚗 They damaged your car! Key scratches and a broken mirror.")
					else
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -12)
						state.Money = math.max(0, (state.Money or 0) - 1500)
						state:AddFeed("🚗 They smashed your window and pulled you out! It got ugly.")
					end
				end,
			},
			{
				text = "📱 Call 911",
				effects = {},
				feedText = "You called for help...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🚗👮 Police arrived quickly. The other driver got a ticket!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🚗 They drove off before police arrived. At least you're safe.")
					else
						state:ModifyStat("Happiness", -5)
						state.Money = math.max(0, (state.Money or 0) - math.random(100, 300))
						state:AddFeed("🚗 They damaged your car before fleeing. Police took a report.")
					end
				end,
			},
			{
				text = "🚗 Drive away quickly",
				effects = {},
				feedText = "You floored it!",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🚗 You sped away before things could escalate. Smart move!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🚗 They chased you for a while but eventually gave up. Heart racing!")
					else
						-- Car chase goes wrong
						state:ModifyStat("Health", -20)
						state:ModifyStat("Happiness", -15)
						state.Money = math.max(0, (state.Money or 0) - 3000)
						state.Flags = state.Flags or {}
						state.Flags.car_accident = true
						state:AddFeed("🚗💥 You crashed while trying to escape! Needed medical attention.")
					end
				end,
			},
		},
	},
	
	{
		-- CRITICAL FIX: Animal attack is now RANDOM - no god mode choosing severity!
		id = "injury_animal",
		title = "Animal Encounter!",
		emoji = "🐕",
		text = "An animal is acting aggressively towards you!",
		question = "How do you react?",
		minAge = 3, maxAge = 85,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "injury",
		choices = {
			{
				text = "Try to back away slowly",
				effects = {},
				feedText = "You tried to escape...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.5 then
						-- Escaped!
						state:ModifyStat("Happiness", 5)
						if state.AddFeed then state:AddFeed("🐕 You escaped without injury! Heart racing though.") end
					else
						-- Got hurt anyway
						local attacks = {
							{ health = -12, money = -200, text = "🐕 A dog bit your arm badly! Needed stitches and shots." },
							{ health = -10, money = -150, text = "🐕 Dog bite on your leg! Painful but you'll recover." },
							{ health = -8, money = -100, text = "🐱 Cat scratched you and it got infected. Antibiotics needed." },
							{ health = -5, money = 0, text = "🐕 Minor bite, but your pride is hurt more than your body." },
						}
						local attack = attacks[math.random(1, #attacks)]
						state:ModifyStat("Health", attack.health)
						state:ModifyStat("Happiness", -8)
						state.Money = math.max(0, (state.Money or 0) + attack.money)
						state.Flags = state.Flags or {}
						state.Flags.animal_attack_survivor = true
						if state.AddFeed then state:AddFeed(attack.text) end
					end
				end,
			},
			{
				text = "Stand your ground and yell",
				effects = {},
				feedText = "You showed no fear...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.3 then
						-- It worked!
						state:ModifyStat("Happiness", 8)
						if state.AddFeed then state:AddFeed("🐕 It backed off! Dominance asserted!") end
					elseif roll < 0.7 then
						-- Minor injury
						state:ModifyStat("Health", -8)
						state:ModifyStat("Happiness", -5)
						state.Money = math.max(0, (state.Money or 0) - 100)
						if state.AddFeed then state:AddFeed("🐕 It bit you anyway! Minor wound but scary.") end
					else
						-- Severe attack
						local attacks = {
							{ health = -20, money = -500, text = "🐝 Bee sting! Severe allergic reaction! Emergency room!", flag = "allergic_reaction" },
							{ health = -25, money = -1000, text = "🐍 Snake bite! Rushed to hospital for antivenin!", flag = "snake_bite" },
							{ health = -15, money = -300, text = "🐕 Multiple bites! Had to get a rabies shot!", flag = "dog_attack_severe" },
						}
						local attack = attacks[math.random(1, #attacks)]
						state:ModifyStat("Health", attack.health)
						state:ModifyStat("Happiness", -15)
						state.Money = math.max(0, (state.Money or 0) + attack.money)
						state.Flags = state.Flags or {}
						state.Flags[attack.flag] = true
						if state.AddFeed then state:AddFeed(attack.text) end
					end
				end,
			},
			{
				text = "Run as fast as you can",
				effects = { Health = -2 },
				feedText = "You sprinted away!",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.6 then
						state:ModifyStat("Happiness", 3)
						if state.AddFeed then state:AddFeed("🏃 You outran it! Cardio pays off!") end
					else
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -7)
						if state.AddFeed then state:AddFeed("🐕 It chased you down and bit you! Should've stood your ground.") end
					end
				end,
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ILLNESS SYSTEM - BITLIFE STYLE SICKNESS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		-- CRITICAL FIX #7: Was god-mode - player chose severity! Now random.
		id = "illness_flu",
		title = "Flu Season Hit!",
		emoji = "🤒",
		text = "You caught the flu!",
		question = "How do you deal with it?",
		minAge = 3, maxAge = 90,
		baseChance = 0.555,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "illness",

		choices = {
			{ 
				text = "Rest at home and recover", 
				effects = {},
				feedText = "You stayed home to recover...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤒 Mild flu. A few days in bed and you bounced back.")
					elseif roll < 0.80 then
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -8)
						state:AddFeed("🤒 Miserable flu. A week in bed feeling awful.")
					elseif roll < 0.95 then
						state:ModifyStat("Health", -18)
						state:ModifyStat("Happiness", -12)
						state.Flags = state.Flags or {}
						state.Flags.severe_illness = true
						state:AddFeed("🤒 Severe flu knocked you out for two weeks.")
					else
						state:ModifyStat("Health", -25)
						state:ModifyStat("Happiness", -15)
						state.Money = math.max(0, (state.Money or 0) - 1000)
						state.Flags = state.Flags or {}
						state.Flags.pneumonia = true
						state.Flags.hospitalized = true
						state:AddFeed("🏥 Flu turned into pneumonia! Hospitalized.")
					end
				end,
			},
			{ 
				text = "See a doctor immediately", 
				effects = { Money = -100 },
				feedText = "You went to the doctor...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Health", -3)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🤒 Doctor helped! Quick recovery with medication.")
					else
						state:ModifyStat("Health", -8)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🤒 Doctor visit helped but you were still sick for a while.")
					end
				end,
			},
			{ 
				text = "Push through it", 
				effects = {},
				feedText = "You tried to power through...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Health", -6)
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🤒 You managed to shake it off.")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.overworked = true
						state:AddFeed("🤒 Bad idea. Made it much worse by not resting.")
					end
				end,
			},
		},
	},
	{
		-- CRITICAL FIX #8: Was god-mode - player chose severity! Now random.
		id = "illness_food_poisoning",
		title = "Food Poisoning!",
		emoji = "🤢",
		text = "You got food poisoning from something you ate!",
		question = "How do you handle it?",
		minAge = 5, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "illness",

		choices = {
			{ 
				text = "Wait it out at home", 
				effects = {},
				feedText = "You stayed near the bathroom...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Health", -3)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤢 Over in a few hours. Lucky!")
					elseif roll < 0.75 then
						state:ModifyStat("Health", -6)
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🤢 Mild but unpleasant. Stomach issues for a day.")
					elseif roll < 0.95 then
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -12)
						state:AddFeed("🤢 Worst 24 hours of your life. Never eating there again.")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -10)
						state.Money = math.max(0, (state.Money or 0) - 500)
						state.Flags = state.Flags or {}
						state.Flags.dehydrated = true
						state:AddFeed("🏥 So dehydrated you needed IV fluids at the ER!")
					end
				end,
			},
			{ 
				text = "Go to urgent care", 
				effects = { Money = -150 },
				feedText = "You went to get checked out...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.80 then
						state:ModifyStat("Health", -4)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤢 Doctor gave you anti-nausea meds. Felt better soon.")
					else
						state:ModifyStat("Health", -8)
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🤢 Needed fluids but you recovered faster with help.")
					end
				end,
			},
		},
	},
	{
		-- CRITICAL FIX #9: Was god-mode - player chose condition! Now random with response choices.
		id = "illness_mental_health",
		title = "Mental Health Struggle",
		emoji = "😔",
		text = "You've been struggling with your mental health lately.",
		question = "What do you do about it?",
		minAge = 12, maxAge = 90,
		baseChance = 0.45,
		cooldown = 3,
		category = "mental_health",

		choices = {
			{ 
				text = "Seek professional help", 
				effects = { Money = -300 },
				feedText = "You reached out for help...",
				onResolve = function(state)
					local roll = math.random()
					local conditions = {
						{ name = "depression", text = "Depression was the diagnosis. Therapy is helping.", hap = -10, flag = "depression" },
						{ name = "anxiety", text = "Anxiety disorder. Learning coping strategies.", hap = -8, flag = "anxiety" },
						{ name = "burnout", text = "Severe burnout. You needed this break.", hap = -5, flag = "burnout" },
					}
					local condition = conditions[math.random(1, #conditions)]
					state:ModifyStat("Happiness", condition.hap)
					state.Flags = state.Flags or {}
					state.Flags[condition.flag] = true
					state.Flags.in_therapy = true
					state:AddFeed("😔 " .. condition.text .. " Treatment is making a difference.")
				end,
			},
			{ 
				text = "Try to handle it yourself", 
				effects = {},
				feedText = "You tried to push through alone...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("😔 You managed to cope. Exercise and friends helped.")
					elseif roll < 0.60 then
						state:ModifyStat("Happiness", -15)
						state:ModifyStat("Health", -5)
						state.Flags = state.Flags or {}
						state.Flags.depression = true
						state:AddFeed("😔 It got worse. Depression is real. Consider getting help.")
					else
						state:ModifyStat("Happiness", -20)
						state:ModifyStat("Health", -8)
						state.Flags = state.Flags or {}
						state.Flags.severe_depression = true
						state:AddFeed("😔 Ignoring it made things much worse. Please seek help.")
					end
				end,
			},
			{ 
				text = "Talk to friends and family", 
				effects = {},
				feedText = "You opened up to loved ones...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("😔 Your support system helped you through a rough patch.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.anxiety = true
						state:AddFeed("😔 They tried to help but you might need professional support.")
					end
				end,
			},
		},
	},
	{
		-- CRITICAL FIX: Doctor gives diagnosis, not player choosing their disease!
		id = "illness_chronic",
		title = "Medical Results",
		emoji = "🏥",
		text = "After your checkup, the doctor has some news about your test results.",
		question = "How do you react?",
		minAge = 25, maxAge = 85,
		baseChance = 0.1,
		cooldown = 4,
		category = "illness",

		choices = {
			{
				text = "Accept the diagnosis and manage it",
				effects = { Smarts = 2 },
				feedText = "The doctor explained your condition...",
				onResolve = function(state)
					-- Random diagnosis - player doesn't choose their disease!
					local conditions = {
						{ name = "diabetes", flag = "diabetic", health = -10, happiness = -8, money = 300, text = "Diabetes diagnosis. Your blood sugar is high. Diet and exercise are key to managing this." },
						{ name = "hypertension", flag = "hypertension", health = -8, happiness = -5, money = 100, text = "High blood pressure. You'll need medication and regular monitoring." },
						{ name = "autoimmune", flag = "autoimmune", health = -15, happiness = -12, money = 500, text = "Autoimmune disorder diagnosed. Managing flare-ups will be part of your life now." },
						{ name = "arthritis", flag = "arthritis", health = -10, happiness = -8, money = 0, text = "Arthritis in your joints. Movement will be harder, but manageable with treatment." },
						{ name = "asthma", flag = "asthma", health = -8, happiness = -5, money = 150, text = "Asthma diagnosis. Your inhaler is your new best friend." },
					}
					local condition = conditions[math.random(1, #conditions)]
					state.Flags = state.Flags or {}
					state.Flags[condition.flag] = true
					if state.ModifyStat then
						state:ModifyStat("Health", condition.health)
						state:ModifyStat("Happiness", condition.happiness)
					end
					state.Money = math.max(0, (state.Money or 0) - condition.money)
					if state.AddFeed then
						state:AddFeed("🏥 " .. condition.text)
					end
				end,
			},
			{
				text = "Seek a second opinion",
				effects = { Smarts = 3, Money = -500 },
				feedText = "You went to another doctor...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.2 then
						-- False alarm!
						if state.ModifyStat then
							state:ModifyStat("Happiness", 15)
						end
						if state.AddFeed then
							state:AddFeed("😮‍💨 Second opinion: False alarm! You're healthy. What a relief!")
						end
					else
						-- Same diagnosis confirmed
						local conditions = { "diabetes", "hypertension", "arthritis" }
						local condition = conditions[math.random(1, #conditions)]
						state.Flags = state.Flags or {}
						state.Flags[condition] = true
						if state.ModifyStat then
							state:ModifyStat("Health", -10)
							state:ModifyStat("Happiness", -5)
						end
						if state.AddFeed then
							state:AddFeed("🏥 Second doctor confirmed: " .. condition .. ". At least you know for sure now.")
						end
					end
				end,
			},
		},
	},
	{
		id = "illness_cancer_scare",
		title = "The Scary Diagnosis",
		emoji = "🎗️",
		text = "You've found a concerning lump or had abnormal test results.",
		question = "The doctor wants to run more tests...",
		minAge = 30, maxAge = 90, -- CRITICAL FIX: Start at 30, not 25
		baseChance = 0.08, -- CRITICAL FIX: Reduced from 0.25 - cancer scares should be RARE
		cooldown = 15, -- CRITICAL FIX: Increased massively - shouldn't repeat often
		category = "health",
		tags = { "illness", "cancer", "health_scare" },
		oneTime = true, -- CRITICAL FIX: Only happens once per life!
		-- CRITICAL FIX: Block if already had cancer scare or has cancer
		blockedByFlags = { cancer_survivor = true, battling_cancer = true, has_cancer = true, cancer_scare_done = true, in_prison = true },
		-- CRITICAL FIX: Require some health-related activity first
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Already dealt with cancer? Don't show
			if flags.cancer_survivor or flags.battling_cancer or flags.has_cancer then return false end
			-- Must have visited doctor or had some medical interaction
			local hadMedical = flags.went_to_doctor or flags.doctor_checkup or flags.recent_checkup
				or flags.health_checkup or flags.physical_exam or flags.found_lump
			if not hadMedical then return false end
			return true
		end,
		-- CRITICAL FIX: Random cancer outcome - player can't choose diagnosis
		choices = {
			{
				text = "Get tested immediately",
				effects = { Money = -1000, Happiness = -10 },
				feedText = "The waiting for results is agonizing...",
				onResolve = function(state)
					local roll = math.random()
					local age = state.Age or 40
					state.Flags = state.Flags or {}
					state.Flags.cancer_scare_done = true -- CRITICAL FIX: Mark as done to prevent repeats
					-- Older = slightly higher cancer risk
					local cancerRisk = 0.15 + (age - 25) / 200
					if roll < 0.50 then -- 50% false alarm
						state:ModifyStat("Happiness", 25)
						state:ModifyStat("Health", 5)
						state:AddFeed("🎗️ It's benign! Thank goodness. What a relief!")
					elseif roll < 0.50 + (cancerRisk * 0.6) then -- Variable early stage
						state:ModifyStat("Health", -18)
						state:ModifyStat("Happiness", -10)
						state.Money = math.max(0, (state.Money or 0) - 8000)
						state.Flags.cancer_survivor = true
						state:AddFeed("🎗️ Cancer caught early. Treatment is working. You'll beat this.")
					elseif roll < 0.50 + cancerRisk then -- Variable serious
						state:ModifyStat("Health", -35)
						state:ModifyStat("Happiness", -20)
						state.Money = math.max(0, (state.Money or 0) - 20000)
						state.Flags.battling_cancer = true
						state:AddFeed("🎗️ Serious diagnosis. The fight of your life begins.")
					else -- Need more tests
						state:ModifyStat("Happiness", -5)
						state.Flags.health_scare = true
						state:AddFeed("🎗️ Results inconclusive. More tests needed...")
					end
				end,
			},
			{
				text = "Delay the tests - I'm scared",
				effects = { Happiness = -15 },
				feedText = "You put off facing the truth...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.cancer_scare_done = true -- CRITICAL FIX: Mark as done to prevent repeats
					state.Flags.delayed_diagnosis = true
					state.Flags.health_scare = true
					state:AddFeed("🎗️ The uncertainty weighs on you. Should get tested soon...")
				end,
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- RECOVERY EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "recovery_physical",
		title = "Recovery Progress",
		emoji = "🩹",
		text = "You've been recovering from an injury.",
		question = "How's the recovery going?",
		minAge = 5, maxAge = 90,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresFlags = { hospitalized = true },
		category = "recovery",

		choices = {
			{ text = "Making great progress!", effects = { Health = 15, Happiness = 10 }, feedText = "Recovery is going well! Almost back to normal." },
			{ text = "Slower than expected", effects = { Health = 5, Happiness = -5 }, feedText = "Recovery is taking longer than hoped." },
			{ text = "Complications arose", effects = { Health = -10, Happiness = -10 }, feedText = "Setback in recovery. More treatment needed." },
			{ text = "Fully recovered!", effects = { Health = 20, Happiness = 15 }, setFlags = { fully_recovered = true }, feedText = "You're back to full health! What a journey.", onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.hospitalized = nil
				state.Flags.needs_surgery = nil
			end },
		},
	},
	{
		id = "recovery_surgery",
		title = "Surgery Day",
		emoji = "🏥",
		text = "You need surgery for your condition. The day has come.",
		question = "Which hospital do you go to?",
		minAge = 5, maxAge = 90,
		baseChance = 0.5,
		cooldown = 3,
		requiresFlags = { needs_surgery = true },
		category = "recovery",
		-- CRITICAL FIX: Random surgery outcome - player doesn't choose success
		choices = {
			{
				text = "Top-rated hospital ($10K)",
				effects = { Money = -10000 },
				feedText = "You chose the best medical care available...",
				eligibility = function(state) return (state.Money or 0) >= 10000, "💸 Can't afford top-rated hospital ($10K needed)" end,
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.needs_surgery = nil
					if roll < 0.70 then
						state:ModifyStat("Health", 15)
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🏥 Surgery was a complete success! Excellent care.")
					elseif roll < 0.90 then
						state:ModifyStat("Health", 8)
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🏥 Minor complications but the skilled team handled it well.")
					else
						state:ModifyStat("Health", 3)
						state:ModifyStat("Happiness", -5)
						state.Flags.needs_more_surgery = true
						state:AddFeed("🏥 Follow-up procedures needed. Not done yet.")
					end
				end,
			},
			{
				text = "Regular hospital ($5K)",
				effects = { Money = -5000 },
				feedText = "You went to a standard hospital...",
				eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Can't afford regular hospital ($5K needed)" end,
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.needs_surgery = nil
					if roll < 0.55 then
						state:ModifyStat("Health", 12)
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🏥 Surgery was successful! Recovery ahead.")
					elseif roll < 0.80 then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🏥 Some complications but you pulled through.")
					else
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -8)
						state.Flags.needs_more_surgery = true
						state:AddFeed("🏥 Serious complications. More surgery required.")
					end
				end,
			},
			{
				text = "Cheapest option available ($2K)",
				effects = { Money = -2000 },
				feedText = "You went with budget surgery...",
				eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Can't afford budget surgery ($2K needed)" end,
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.needs_surgery = nil
					if roll < 0.40 then
						state:ModifyStat("Health", 10)
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🏥 Got lucky! Surgery went fine despite the cut-rate care.")
					elseif roll < 0.70 then
						state:ModifyStat("Health", 2)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🏥 Complications from the surgery. Cheap isn't always best.")
					else
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -12)
						state.Flags.needs_more_surgery = true
						state:AddFeed("🏥 Surgery went badly. You get what you pay for...")
					end
				end,
			},
			{
				text = "Emergency charity care (free - risky)",
				effects = {},
				feedText = "You had no choice but to use emergency charity care...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.needs_surgery = nil
					if roll < 0.25 then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🏥 The charity hospital did their best. You survived.")
					elseif roll < 0.55 then
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -8)
						state:AddFeed("🏥 Long wait, limited resources. Surgery barely helped.")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -15)
						state.Flags.needs_more_surgery = true
						state:AddFeed("🏥 Serious complications. Emergency care has its limits.")
					end
				end,
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ADDITIONAL RANDOM LIFE EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		-- CRITICAL FIX: Renamed from "pet_adoption" to avoid duplicate ID conflict
		-- Adult.lua has another version
		id = "pet_adoption_random",
		title = "Furry Friend",
		emoji = "🐕",
		text = "You're thinking about getting a pet!",
		question = "What kind of pet?",
		minAge = 10, maxAge = 80,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

		choices = {
			{ text = "Adopt a dog ($500)", effects = { Happiness = 15, Money = -500, Health = 3 }, setFlags = { has_pet = true, has_dog = true }, feedText = "You adopted a dog! Best friend for life.", eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for dog adoption" end },
			{ text = "Adopt a cat ($300)", effects = { Happiness = 12, Money = -300 }, setFlags = { has_pet = true, has_cat = true }, feedText = "You got a cat! Independent but loving.", eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 for cat adoption" end },
			{ text = "Get a small pet ($100)", effects = { Happiness = 8, Money = -100 }, setFlags = { has_pet = true }, feedText = "You got a small pet! Easy to care for.", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for small pet" end },
			{ text = "Not ready for a pet yet", effects = { Happiness = -2 }, feedText = "Maybe someday. Pets are a big responsibility." },
		},
	},
	{
		-- CRITICAL FIX: Renamed from "pet_loss" to avoid duplicate ID conflict
		-- PetEvents.lua has a more detailed version
		id = "pet_loss_simple",
		title = "Goodbye, Friend",
		emoji = "🌈",
		text = "Your beloved pet has passed away.",
		question = "How do you cope?",
		minAge = 10, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4,
		requiresFlags = { has_pet = true },

		choices = {
			{ text = "Devastated - they were family", effects = { Happiness = -20, Health = -5 }, feedText = "Losing your pet is heartbreaking." },
			{ text = "Grateful for the time together", effects = { Happiness = -10 }, feedText = "You cherish the memories you shared." },
			{ text = "Adopt another pet soon ($300)", effects = { Happiness = -8, Money = -300 }, setFlags = { has_pet = true }, feedText = "You opened your heart to another pet.", eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 for pet adoption" end },
			{ text = "Not getting another pet", effects = { Happiness = -12 }, feedText = "Too painful. You can't go through this again.", onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.has_pet = nil
				state.Flags.has_dog = nil
				state.Flags.has_cat = nil
			end },
		},
	},
	{
		-- CRITICAL FIX: Was god-mode - player picked break-in outcome!
		-- Now outcome is random, player chooses response
		id = "home_invasion",
		title = "Break-In!",
		emoji = "🚨",
		text = "You hear breaking glass in your home at night. Someone's breaking in!",
		question = "What do you do?",
		minAge = 18, maxAge = 90,
		baseChance = 0.25,
		cooldown = 4,
		category = "crime",
		-- CRITICAL FIX: Can't be robbed at home while you're in prison!
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true, living_in_car = true, couch_surfing = true },
		
		-- CRITICAL FIX #7: Require having a home for home invasion
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Check for various housing flags
			if flags.has_home or flags.has_apartment or flags.has_house or flags.homeowner or flags.renting or flags.has_own_place then
				return true
			end
			-- Check HousingState
			if state.HousingState then
				local status = state.HousingState.status
				if status == "owner" or status == "renter" or status == "housed" then
					return true
				end
			end
			-- Check Assets.Properties
			if state.Assets and state.Assets.Properties and #state.Assets.Properties > 0 then
				return true
			end
			return false, "Need a home to have a home invasion"
		end,

		choices = {
			{ 
				text = "Call 911 and hide", 
				effects = { },
				feedText = "You called the police...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 40 then
						-- Police arrive in time
						state.Flags.home_invasion = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", -10)
						end
						if state.AddFeed then
							state:AddFeed("🚨 Police caught them! You're safe but shaken.")
						end
					elseif roll <= 70 then
						-- Alarm/noise scared them off
						if state.ModifyStat then
							state:ModifyStat("Happiness", -8)
						end
						if state.AddFeed then
							state:AddFeed("🚨 They heard you call and fled. Nothing taken!")
						end
					else
						-- They got away with stuff
						-- CRITICAL FIX: Prevent negative money!
						state.Flags.burglarized = true
						local stolenAmount = math.random(2000, 5000)
						stolenAmount = math.min(stolenAmount, state.Money or 0) -- Can't steal more than you have
						state.Money = math.max(0, (state.Money or 0) - stolenAmount)
						if state.ModifyStat then
							state:ModifyStat("Happiness", -15)
						end
						if state.AddFeed then
							if stolenAmount > 0 then
								state:AddFeed(string.format("🚨 They got away with $%d before police arrived.", stolenAmount))
							else
								state:AddFeed("🚨 They ransacked the place but found nothing valuable to steal.")
							end
						end
					end
				end,
			},
			{ 
				text = "👊 CONFRONT the intruder!", 
				effects = { },
				feedText = "You confronted them...",
				-- CRITICAL FIX: Fight minigame for home invasion confrontation!
				triggerMinigame = "fight",
				minigameOptions = { difficulty = "hard" },
				onResolve = function(state, minigameResult)
					local won = minigameResult and (minigameResult.success or minigameResult.won)
					state.Flags = state.Flags or {}
					
					if won then
						-- You defeated the intruder!
						state.Flags.self_defense = true
						state.Flags.home_defender = true
						if state.ModifyStat then
							state:ModifyStat("Health", -5)
							state:ModifyStat("Happiness", 5)
						end
						if state.AddFeed then
							state:AddFeed("🚨👊 You BEAT the intruder! They fled bleeding. Hero!")
						end
					else
						-- The intruder was too much
						state.Flags.home_invasion = true
						state.Flags.assault_victim = true
						if state.ModifyStat then
							state:ModifyStat("Health", -25)
							state:ModifyStat("Happiness", -15)
						end
						state.Money = math.max(0, (state.Money or 0) - math.random(1000, 3000))
						if state.AddFeed then
							state:AddFeed("🚨👊 They overpowered you, took your stuff, and left you hurt.")
						end
					end
				end,
			},
		},
	},
	{
		id = "lawsuit",
		title = "Legal Trouble",
		emoji = "⚖️",
		text = "You're being sued!",
		question = "How do you handle this lawsuit?",
		minAge = 18, maxAge = 80,
		baseChance = 0.1,
		cooldown = 3,
		-- CRITICAL FIX: Random lawsuit outcome - player doesn't choose to win
		choices = {
			{
				text = "Hire an expensive lawyer",
				effects = { Money = -5000 },
				feedText = "You hired the best attorney you could afford...",
				onResolve = function(state)
					local roll = math.random()
					local smarts = state.Stats and state.Stats.Smarts or 50
					-- Better lawyers + smarts = better odds
					local winChance = 0.50 + (smarts / 200)
					if roll < winChance then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("⚖️ You won the case! Justice prevailed.")
					elseif roll < winChance + 0.20 then
						state.Money = math.max(0, (state.Money or 0) - 5000)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("⚖️ Settled out of court. Could've been worse.")
					else
						state.Money = math.max(0, (state.Money or 0) - 15000)
						state:ModifyStat("Happiness", -15)
						state.Flags = state.Flags or {}
						state.Flags.lawsuit_lost = true
						state:AddFeed("⚖️ You lost the lawsuit. Devastating financially.")
					end
				end,
			},
			{
				text = "Use a public defender",
				effects = { Money = -500 },
				feedText = "You went with an affordable option...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("⚖️ Against the odds, you won! Good public defender.")
					elseif roll < 0.50 then
						state.Money = math.max(0, (state.Money or 0) - 8000)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("⚖️ Settled for a reasonable amount.")
					else
						state.Money = math.max(0, (state.Money or 0) - 20000)
						state:ModifyStat("Happiness", -18)
						state.Flags = state.Flags or {}
						state.Flags.lawsuit_lost = true
						state:AddFeed("⚖️ You lost badly. Cheap lawyers cost more in the end.")
					end
				end,
			},
			{
				text = "Represent yourself",
				effects = {},
				feedText = "You decided to be your own lawyer...",
				onResolve = function(state)
					local roll = math.random()
					local smarts = state.Stats and state.Stats.Smarts or 50
					local winChance = smarts / 250 -- Max 40% if genius
					if roll < winChance then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("⚖️ Incredible! You represented yourself and WON!")
					elseif roll < 0.30 then
						state.Money = math.max(0, (state.Money or 0) - 10000)
						state:ModifyStat("Happiness", -8)
						state:AddFeed("⚖️ Forced to settle. Not great, not terrible.")
					else
						state.Money = math.max(0, (state.Money or 0) - 25000)
						state:ModifyStat("Happiness", -20)
						state.Flags = state.Flags or {}
						state.Flags.lawsuit_lost = true
						state:AddFeed("⚖️ As they say: a lawyer who represents themselves has a fool for a client.")
					end
				end,
			},
		},
	},
	{
		id = "natural_disaster",
		title = "Natural Disaster!",
		emoji = "🌪️",
		text = "A natural disaster is bearing down on your area!",
		question = "What do you do?",
		minAge = 5, maxAge = 95,
		baseChance = 0.25,
		cooldown = 15,
		category = "disaster",
		-- CRITICAL FIX: Random disaster damage - player doesn't choose outcome
		choices = {
			{
				text = "Evacuate immediately",
				effects = { Money = -500 },
				feedText = "You fled to safety...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.disaster_survivor = true
					if roll < 0.10 then
						state.Money = math.max(0, (state.Money or 0) - 25000)
						state:ModifyStat("Happiness", -22)
						state.Flags.homeless = true
						state:AddFeed("🌪️ Home destroyed. Everything is gone, but you're alive.")
					elseif roll < 0.30 then
						state.Money = math.max(0, (state.Money or 0) - 8000)
						state:ModifyStat("Happiness", -12)
						state:AddFeed("🌪️ Significant damage. Insurance will cover some of it.")
					elseif roll < 0.60 then
						state.Money = math.max(0, (state.Money or 0) - 1500)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🌪️ Minor damage. You got lucky!")
					else
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🌪️ Your home was completely untouched! Miraculous.")
					end
				end,
			},
			{
				text = "Shelter in place",
				effects = {},
				feedText = "You hunkered down to ride out the storm...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.disaster_survivor = true
					if roll < 0.15 then
						state.Money = math.max(0, (state.Money or 0) - 30000)
						state:ModifyStat("Happiness", -25)
						state:ModifyStat("Health", -15)
						state.Flags.homeless = true
						state:AddFeed("🌪️ Home destroyed with you in it! Injured and lost everything.")
					elseif roll < 0.35 then
						state.Money = math.max(0, (state.Money or 0) - 10000)
						state:ModifyStat("Happiness", -15)
						state:ModifyStat("Health", -5)
						state:AddFeed("🌪️ Major damage. Got hurt in the chaos.")
					elseif roll < 0.65 then
						state.Money = math.max(0, (state.Money or 0) - 2000)
						state:ModifyStat("Happiness", -8)
						state:AddFeed("🌪️ Some damage but you're okay.")
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🌪️ Rode it out safely. Home intact!")
					end
				end,
			},
			{
				text = "Help evacuate neighbors first",
				effects = { Health = -5 },
				feedText = "You helped others escape...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.disaster_survivor = true
					state.Flags.local_hero = true
					if roll < 0.20 then
						state.Money = math.max(0, (state.Money or 0) - 20000)
						state:ModifyStat("Happiness", -10)
						state:ModifyStat("Health", -10)
						state:AddFeed("🌪️ You saved lives but your home is destroyed. A true hero.")
					elseif roll < 0.50 then
						state.Money = math.max(0, (state.Money or 0) - 5000)
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🌪️ Saved your neighbors! Some damage to your place.")
					else
						state:ModifyStat("Happiness", 20)
						state:AddFeed("🌪️ You're a hero! Saved lives and your home was spared!")
					end
				end,
			},
		},
	},
	{
		-- CRITICAL FIX: Scam event is now RANDOM outcome - no god mode choice!
		-- Player learns what happened AFTER choosing how to react (like BitLife)
		id = "scam_victim",
		title = "Suspicious Message",
		emoji = "📧",
		text = "You received a message that seems too good to be true. Someone claims you've won a prize, inherited money, or has an 'amazing investment opportunity' for you.",
		question = "How do you respond?",
		minAge = 16, maxAge = 90,
		baseChance = 0.38,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{
				text = "Investigate it - could be legit!",
				effects = {},
				feedText = "You looked into it...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					-- Smarter people are less likely to fall for it
					local scamChance = 0.70 - (smarts / 200) -- 70% base chance, reduced by smarts
					
					if roll < scamChance then
						-- Fell for it - random scam type
						local scamTypes = {
							{ loss = -500, text = "🎭 It was an online shopping scam! That website was completely fake. Money gone." },
							{ loss = -2000, text = "🎭 Romance scam! They pretended to love you just to steal your money." },
							{ loss = -3000, text = "🎭 Identity theft! They stole your personal information. Nightmare to fix." },
							{ loss = -5000, text = "🎭 Investment fraud! It was a Ponzi scheme. Your money vanished." },
							{ loss = -8000, text = "🎭 Nigerian prince scam! Can't believe you fell for the oldest trick." },
						}
						local scam = scamTypes[math.random(1, #scamTypes)]
						state.Money = math.max(0, (state.Money or 0) + scam.loss)
						state:ModifyStat("Happiness", -15)
						state.Flags = state.Flags or {}
						state.Flags.scam_victim = true
						if state.AddFeed then state:AddFeed(scam.text) end
					else
						-- Caught it in time
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", 3)
						if state.AddFeed then state:AddFeed("🎭 You realized it was a scam just in time! Close call.") end
					end
				end,
			},
			{
				text = "Delete it - obvious scam",
				effects = { Smarts = 1, Happiness = 1 },
				feedText = "Smart move. You deleted it without engaging.",
				onResolve = function(state)
					if state.AddFeed then state:AddFeed("🗑️ Deleted the suspicious message. Trust your instincts!") end
				end,
			},
			{
				text = "Report it as spam",
				effects = { Smarts = 2 },
				feedText = "You reported it and helped protect others.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.good_citizen = true
					if state.AddFeed then state:AddFeed("🛡️ Reported the scam! You might have saved someone else from falling for it.") end
				end,
			},
		},
	},
	{
		-- CRITICAL FIX: Talent discovery is now RANDOM - no god mode choosing!
		id = "talent_discovered",
		title = "Hidden Talent!",
		emoji = "✨",
		text = "Someone noticed you have a natural ability for something!",
		question = "Do you want to explore this talent?",
		minAge = 8, maxAge = 70,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{
				text = "Absolutely! Show me what I've got!",
				effects = { Happiness = 10 },
				feedText = "You're excited to discover your gift!",
				onResolve = function(state)
					local talents = {
						{ flag = "musical_talent", text = "🎵 You have an amazing ear for music! You can really sing and play!", stat = "Smarts", bonus = 3 },
						{ flag = "artistic_talent", text = "🎨 You're a natural artist! Your drawings and paintings are impressive!", stat = "Smarts", bonus = 2 },
						{ flag = "athletic_talent", text = "🏃 You have incredible athletic potential! Fast, strong, coordinated!", stat = "Health", bonus = 5 },
						{ flag = "writing_talent", text = "✍️ You have a gift with words! Your writing moves people!", stat = "Smarts", bonus = 4 },
						{ flag = "natural_leader", text = "👔 People naturally follow your lead! You're a born leader!", stat = "Smarts", bonus = 3 },
						{ flag = "cooking_talent", text = "👨‍🍳 You're an incredible cook! Everything you make tastes amazing!", stat = "Happiness", bonus = 5 },
						{ flag = "tech_talent", text = "💻 You have a natural gift for technology! Computers make sense to you!", stat = "Smarts", bonus = 5 },
					}
					local talent = talents[math.random(1, #talents)]
					state.Flags = state.Flags or {}
					state.Flags[talent.flag] = true
					state:ModifyStat(talent.stat, talent.bonus)
					if state.AddFeed then state:AddFeed(talent.text) end
				end,
			},
			{
				text = "Not interested - I'm fine as I am",
				effects = { Happiness = -2 },
				feedText = "You shrugged it off. Not everyone wants to be special.",
			},
		},
	},
	{
		id = "unexpected_visitor",
		title = "Surprise Visit!",
		emoji = "🚪",
		text = "Someone showed up unexpectedly at your door!",
		question = "Who is it?",
		minAge = 15, maxAge = 85,
		baseChance = 0.45,
		cooldown = 3,

		choices = {
			{ text = "Old friend - great reunion!", effects = { Happiness = 12 }, feedText = "An old friend visited! So good to catch up." },
			{ text = "Estranged family member", effects = { Happiness = -5 }, setFlags = { family_drama = true }, feedText = "Awkward... someone you hadn't seen in years." },
			{ text = "Someone claiming you won a prize", effects = { Happiness = -3, Smarts = 2 }, feedText = "Obviously a scam. You didn't fall for it." },
			{ text = "Package delivery - something you forgot you ordered", effects = { Happiness = 5 }, feedText = "Present from past you! Nice surprise." },
			{ text = "Neighbor needing help", effects = { Happiness = 5 }, setFlags = { good_neighbor = true }, feedText = "You helped out your neighbor. Good karma." },
		},
	},
	{
		id = "lucky_break",
		title = "Lucky Break!",
		emoji = "🍀",
		text = "Something unexpectedly good happened!",
		question = "What was your lucky break?",
		minAge = 10, maxAge = 90,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

		choices = {
			{ text = "Found a valuable item", effects = { Money = 2000, Happiness = 10 }, feedText = "You found something valuable! What luck!" },
			{ text = "Random act of generosity", effects = { Happiness = 15 }, feedText = "Someone did something incredibly kind for you!" },
			{ text = "Perfect timing saved you", effects = { Happiness = 10, Health = 5 }, feedText = "Right place, right time. Avoided disaster." },
			{ text = "Connection led to opportunity", effects = { Happiness = 10, Smarts = 3 }, setFlags = { lucky_network = true }, feedText = "A chance meeting opened new doors!" },
		},
	},
	{
		-- CRITICAL FIX: Was god-mode - player picked what embarrassment happened!
		-- Now embarrassment is random, player chooses how to react
		id = "public_embarrassment",
		title = "Public Humiliation",
		emoji = "😳",
		text = "Something incredibly embarrassing just happened to you in public!",
		question = "How do you handle it?",
		minAge = 10, maxAge = 80,
		baseChance = 0.4,
		cooldown = 3,

		choices = {
			{ 
				text = "Try to play it cool", 
				effects = { },
				feedText = "You tried to recover...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 25 then
						-- Wardrobe malfunction
						if state.ModifyStat then
							state:ModifyStat("Happiness", -10)
						end
						if state.AddFeed then
							state:AddFeed("😳 Wardrobe malfunction. Everyone saw. Mortifying!")
						end
					elseif roll <= 50 then
						-- Tripped
						if state.ModifyStat then
							state:ModifyStat("Happiness", -7)
							state:ModifyStat("Health", -3)
						end
						if state.AddFeed then
							state:AddFeed("😳 Epic fall in front of everyone. Someone recorded it.")
						end
					elseif roll <= 75 then
						-- Said something dumb
						if state.ModifyStat then
							state:ModifyStat("Happiness", -8)
						end
						if state.AddFeed then
							state:AddFeed("😳 You said something SO dumb. Cringe for days.")
						end
					else
						-- Actually recovered well!
						state.Flags.thick_skinned = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", 3)
						end
						if state.AddFeed then
							state:AddFeed("😎 You played it off perfectly! Nobody noticed.")
						end
					end
				end,
			},
			{ text = "Run away immediately", effects = { Happiness = -5 }, feedText = "You fled the scene. Smart move." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- HOMELESS / FINANCIAL CRISIS EVENTS - For players who chose the bum life
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "eviction_notice",
		title = "Eviction Notice",
		emoji = "📋",
		text = "You can't pay rent. Your landlord has given you an eviction notice.",
		question = "What do you do?",
		minAge = 18, maxAge = 80,
		baseChance = 0.5, -- CRITICAL FIX: Reduced from 0.8
		cooldown = 6, -- CRITICAL FIX: Increased to prevent spam
		category = "homeless",
		tags = { "eviction", "housing", "financial" },
	-- CRITICAL FIX: Only triggers for people with bum_life flag AND low money
	-- This prevents rich players from getting eviction notices!
	requiresFlags = { bum_life = true },
	-- CRITICAL FIX: Can't be evicted if living with family!
	blockedByFlags = { homeless = true, evicted = true, lives_with_parents = true, living_with_family = true, boomerang_kid = true },
		-- CRITICAL FIX: Custom eligibility check to ensure player is actually broke
		eligibility = function(state)
			local money = state.Money or 0
			-- Only show eviction if player has less than $500
			if money >= 500 then
				return false, "Has enough money to pay rent"
			end
			return true
		end,

		choices = {
		{ 
			text = "Beg family for help", 
			effects = { Happiness = -8 }, 
			feedText = "You swallowed your pride and asked family for help.",
			-- CRITICAL FIX: Can't beg family if already living with them!
			eligibility = function(state)
				local flags = state.Flags or {}
				if flags.lives_with_parents or flags.living_with_family or flags.boomerang_kid then
					return false, "You already live with your family!"
				end
				return true
			end,
			onResolve = function(state)
				if math.random() < 0.6 then
					state.Money = (state.Money or 0) + 500
					state:AddFeed("💕 Your family helped you out this time...")
				else
					state.Flags.homeless = true
					state.Flags.at_risk_homeless = nil
					state:AddFeed("😢 They couldn't help. You're on the streets now.")
				end
			end,
		},
			{ 
				text = "Try to find any job fast", 
				effects = { Happiness = -5 },
				setFlags = { desperate_job_hunt = true },
				feedText = "You're frantically looking for any work you can get.",
			},
			{ 
				text = "Accept your fate", 
				effects = { Happiness = -15, Health = -5 },
				setFlags = { homeless = true },
				feedText = "You've become homeless. Life on the streets is brutal.",
				onResolve = function(state)
					state.Flags.homeless = true
					state.Flags.at_risk_homeless = nil
					state.Flags.bum_life = nil
				end,
			},
		},
	},
	{
		id = "homeless_life",
		title = "Life on the Streets",
		emoji = "🏚️",
		text = "Another day homeless. The streets are harsh and unforgiving.",
		question = "How do you survive today?",
		minAge = 18, maxAge = 80,
		baseChance = 0.5, -- CRITICAL FIX: Reduced from 0.6
		cooldown = 4, -- CRITICAL FIX: Increased from 3
		maxOccurrences = 8, -- CRITICAL FIX: Limit homeless events per life - can't be stuck forever
		category = "homeless",
		tags = { "homeless", "survival" },
		requiresFlags = { homeless = true },
		blockedByFlags = { in_prison = true, renting = true, has_apartment = true, has_home = true }, -- CRITICAL FIX: Block if has home!

		choices = {
			{ 
				text = "Panhandle for money", 
				effects = { Happiness = -5, Looks = -2 },
				feedText = "You asked strangers for spare change.",
				onResolve = function(state)
					local earned = math.random(5, 50)
					state.Money = (state.Money or 0) + earned
					state:AddFeed(string.format("💰 You collected $%d from panhandling.", earned))
				end,
			},
			{ 
				text = "Search for food in dumpsters", 
				effects = { Happiness = -8, Health = -3 },
				feedText = "Dumpster diving for scraps. This is survival.",
			},
			{ 
				text = "Go to a shelter", 
				effects = { Happiness = 2, Health = 2 },
				setFlags = { using_shelter = true },
				feedText = "You found a warm bed at a shelter for the night.",
			},
			{ 
				text = "Try to find work - ANY work", 
				effects = { Happiness = 3 },
				feedText = "You're determined to get off the streets.",
				onResolve = function(state)
					if math.random() < 0.3 then
						state.Flags.homeless = nil
						state.Flags.has_temp_housing = true
						state.Money = (state.Money or 0) + 200
						state:AddFeed("🎉 You found day labor work! Enough for a cheap room tonight.")
					else
						state:AddFeed("😔 No luck finding work today...")
					end
				end,
			},
			{ 
				text = "Turn to crime to survive", 
				effects = { Happiness = -2 },
				setFlags = { desperate_criminal = true },
				feedText = "Desperation is pushing you to dark choices...",
				onResolve = function(state)
				if math.random() < 0.4 then
					state.Money = (state.Money or 0) + math.random(50, 200)
					state:AddFeed("💵 You stole some money. Risky, but you needed it.")
				else
					-- CRITICAL FIX: Set BOTH InJail AND in_prison flag for consistency
					state.InJail = true
					state.JailYearsLeft = math.random(1, 3)
					state.Flags = state.Flags or {}
					state.Flags.in_prison = true
					state.Flags.incarcerated = true
					state.Flags.criminal_record = true
					-- CRITICAL FIX: Clear job when going to jail!
					state.CurrentJob = nil
					state.Flags.employed = nil
					state.Flags.has_job = nil
					state:AddFeed("🚔 You got caught! Arrested for theft.")
				end
				end,
			},
		},
	},
	{
		id = "homeless_recovery",
		title = "A Second Chance",
		emoji = "🌅",
		text = "Someone offers you a chance to get back on your feet.",
		question = "What kind of help is it?",
		minAge = 18, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4,
		requiresFlags = { homeless = true },

		choices = {
			{ 
				text = "Job training program", 
				effects = { Happiness = 15, Smarts = 5 },
				setFlags = { in_recovery_program = true },
				feedText = "You're enrolled in a program to learn new skills!",
				onResolve = function(state)
					state.Flags.homeless = nil
					state.Flags.recovering = true
					state.Money = (state.Money or 0) + 500
				end,
			},
			{ 
				text = "Temporary housing assistance", 
				effects = { Happiness = 20, Health = 10 },
				feedText = "You have a roof over your head again!",
				onResolve = function(state)
					state.Flags.homeless = nil
					state.Flags.has_temp_housing = true
				end,
			},
			{ 
				text = "A kind stranger helps you", 
				effects = { Happiness = 25, Health = 5 },
				feedText = "Faith in humanity restored! Someone truly helped you.",
				onResolve = function(state)
					state.Flags.homeless = nil
					state.Money = (state.Money or 0) + 1000
					state:AddFeed("💕 A kind stranger gave you money and connected you with resources.")
				end,
			},
			{ 
				text = "You're skeptical of the help", 
				effects = { Happiness = -5 },
				feedText = "You turned down the help. Trust is hard on the streets.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- JOB OPPORTUNITY EVENTS - Jobs come to YOU (BitLife-style)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "random_job_offer",
		emoji = "📧",
		title = "Job Opportunity!",
		text = "A recruiter reached out to you with a job offer! They found your profile online.",
		question = "What do you do?",
		category = "career",
		weight = 6,
		minAge = 18,
		maxAge = 55,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresNoJob = true, -- Only for unemployed
		blockedByFlags = { in_prison = true },
		
		-- CRITICAL FIX #30: Job offers should use career skills and education
		choices = {
			{
				index = 1,
				text = "Accept the interview!",
				effects = { Happiness = 5 },
				feedText = "You went to the interview...",
				onResolve = function(state)
					-- Get player skills and education for better job matching
					local skills = (state.CareerInfo and state.CareerInfo.skills) or {}
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local education = state.EducationData and state.EducationData.level
					
					-- CRITICAL FIX: Calculate total skill level
					local totalSkills = 0
					for _, level in pairs(skills) do
						totalSkills = totalSkills + (level or 0)
					end
					
					-- Success chance based on smarts + skills + education
					local baseChance = 0.50
					local smartsBonus = smarts / 300 -- Up to +0.33
					local skillsBonus = math.min(totalSkills / 30, 0.2) -- Up to +0.2
					local educationBonus = 0
					if education == "bachelor" or education == "bachelors" then
						educationBonus = 0.1
					elseif education == "master" or education == "masters" then
						educationBonus = 0.15
					elseif education == "doctorate" or education == "phd" then
						educationBonus = 0.2
					end
					
					local successChance = math.min(0.95, baseChance + smartsBonus + skillsBonus + educationBonus)
					
					-- Entry level jobs for anyone
					local entryJobs = {
						{ name = "Office Assistant", salary = 32000, category = "entry" },
						{ name = "Customer Service Rep", salary = 30000, category = "service" },
						{ name = "Retail Associate", salary = 28000, category = "entry" },
						{ name = "Data Entry Clerk", salary = 34000, category = "entry" },
						{ name = "Receptionist", salary = 31000, category = "service" },
					}
					
					-- Better jobs for skilled/educated players
					local skilledJobs = {
						{ name = "Administrative Coordinator", salary = 42000, category = "office" },
						{ name = "Sales Representative", salary = 40000, category = "sales" },
						{ name = "Junior Analyst", salary = 48000, category = "office" },
						{ name = "Project Assistant", salary = 44000, category = "office" },
					}
					
					-- Tech jobs for players with technical skills
					local techJobs = {
						{ name = "IT Support Specialist", salary = 52000, category = "tech" },
						{ name = "Junior Developer", salary = 58000, category = "tech" },
						{ name = "QA Tester", salary = 50000, category = "tech" },
					}
					
					local roll = math.random()
					if roll < successChance then
						local job
						local techSkill = skills.Technical or 0
						local analyticalSkill = skills.Analytical or 0
						
						-- Match job to skills
						if techSkill >= 5 and math.random() < 0.7 then
							job = techJobs[math.random(1, #techJobs)]
						elseif (totalSkills >= 8 or education) and math.random() < 0.6 then
							job = skilledJobs[math.random(1, #skilledJobs)]
						else
							job = entryJobs[math.random(1, #entryJobs)]
						end
						
						-- Salary bonus for skills
						local salaryBonus = 1 + (totalSkills / 100) + (smarts - 50) / 200
						
						state.CurrentJob = {
							id = "random_" .. math.random(1000, 9999),
							name = job.name,
							company = "Local Business",
							salary = math.floor(job.salary * salaryBonus),
							category = job.category,
						}
						state.Flags = state.Flags or {}
						state.Flags.employed = true
						state.Flags.has_job = true
						if state.AddFeed then
							state:AddFeed(string.format("🎉 You got the job! %s - $%d/year", job.name, state.CurrentJob.salary))
						end
					else
						if state.AddFeed then
							state:AddFeed("😔 The interview didn't go well. Keep trying!")
						end
					end
				end,
			},
			{
				index = 2,
				text = "Not interested right now",
				effects = { Happiness = 2 },
				feedText = "You passed on the opportunity.",
			},
		},
	},
	
	{
		id = "friend_job_referral",
		emoji = "🤝",
		title = "Friend Knows Someone Hiring",
		text = "A friend says their company is hiring and can put in a good word for you!",
		question = "Do you take the referral?",
		category = "career",
		weight = 5,
		minAge = 18,
		maxAge = 50,
		baseChance = 0.45,
		cooldown = 3,
		requiresNoJob = true,
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				index = 1,
				text = "Yes! I need a job!",
				effects = { Happiness = 8 },
				feedText = "Your friend vouched for you...",
				onResolve = function(state)
					-- Referrals have higher success rate
					if math.random() < 0.85 then
						local jobs = {
							{ name = "Junior Developer", salary = 55000, category = "tech" },
							{ name = "Marketing Coordinator", salary = 42000, category = "creative" },
							{ name = "Sales Rep", salary = 38000, category = "sales" },
							{ name = "Administrative Assistant", salary = 36000, category = "entry" },
							{ name = "Account Manager", salary = 48000, category = "business" },
						}
						local job = jobs[math.random(1, #jobs)]
						state.CurrentJob = {
							id = "referral_" .. math.random(1000, 9999),
							name = job.name,
							company = "Friend's Company",
							salary = job.salary,
							category = job.category,
						}
						state.Flags = state.Flags or {}
						state.Flags.employed = true
						state.Flags.has_job = true
						state.Flags.got_job_through_friend = true
						if state.AddFeed then
							state:AddFeed(string.format("🎉 Referral worked! You're now a %s earning $%d!", job.name, job.salary))
						end
					else
						if state.AddFeed then
							state:AddFeed("😔 The position was filled before your interview.")
						end
					end
				end,
			},
			{
				index = 2,
				text = "No thanks, I'll find my own way",
				effects = { Happiness = 2 },
				feedText = "You want to succeed on your own merits.",
			},
		},
	},
	
	{
		id = "headhunted_better_job",
		emoji = "🎯",
		title = "Headhunted!",
		text = "A recruiter says a competitor is interested in you. They're offering a better position with more pay!",
		question = "Do you take the meeting?",
		category = "career",
		weight = 5,
		minAge = 25,
		maxAge = 55,
		baseChance = 0.45,
		cooldown = 4,
		requiresJob = true, -- Need a job to be headhunted
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				index = 1,
				text = "Take the meeting - hear them out",
				effects = { Happiness = 5 },
				feedText = "You met with the recruiter...",
				onResolve = function(state)
					if state.CurrentJob then
						local currentSalary = state.CurrentJob.salary or 40000
						local raise = math.random(15, 35) -- 15-35% raise
						local newSalary = math.floor(currentSalary * (1 + raise/100))
						
						-- Random outcome
						local outcome = math.random()
						if outcome < 0.5 then
							-- Great offer
							state.CurrentJob.salary = newSalary
							state.CurrentJob.company = "New Company"
							state.CareerInfo = state.CareerInfo or {}
							state.CareerInfo.jobChanges = (state.CareerInfo.jobChanges or 0) + 1
							if state.AddFeed then
								state:AddFeed(string.format("💼 You switched companies! New salary: $%d (+%d%%)!", newSalary, raise))
							end
						elseif outcome < 0.75 then
							-- They match your expectations but you stay
							local matchRaise = math.floor(currentSalary * 0.1)
							state.CurrentJob.salary = currentSalary + matchRaise
							if state.AddFeed then
								state:AddFeed(string.format("💰 Your current employer counter-offered! +$%d raise to keep you!", matchRaise))
							end
						else
							-- Didn't work out
							if state.AddFeed then
								state:AddFeed("🤷 The offer wasn't as good as promised. You stayed put.")
							end
						end
					end
				end,
			},
			{
				index = 2,
				text = "I'm loyal to my current employer",
				effects = { Happiness = 3 },
				setFlags = { loyal_employee = true },
				feedText = "Loyalty matters to you. Your boss appreciates it.",
			},
		},
	},
	
	{
		-- CRITICAL FIX: Renamed from "side_hustle_opportunity" to avoid duplicate ID
		id = "freelance_side_gig",
		emoji = "💡",
		title = "Side Hustle Opportunity",
		text = "Someone offers you a chance to make extra money on the side. It's freelance work!",
		question = "Do you take on the side gig?",
		category = "career",
		weight = 6,
		minAge = 16,
		maxAge = 60,
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.455
		cooldown = 4, -- CRITICAL FIX: Increased cooldown
		blockedByFlags = { in_prison = true },
		-- CRITICAL FIX: Side gig should only appear for people who need/want extra money
		-- Not for wealthy people with high-paying jobs
		eligibility = function(state)
			local money = state.Money or 0
			local salary = state.CurrentJob and state.CurrentJob.salary or 0
			local flags = state.Flags or {}
			
			-- If wealthy (100k+ savings AND 80k+ salary), don't offer side gigs
			if money >= 100000 and salary >= 80000 then
				return false
			end
			
			-- If no job, definitely relevant
			if not state.CurrentJob then
				return true
			end
			
			-- Low/moderate income = relevant
			if salary < 60000 then
				return true
			end
			
			-- Has debt or financial stress flags
			if flags.in_debt or flags.financial_stress or flags.needs_money then
				return true
			end
			
			-- Moderate income with low savings
			if salary < 80000 and money < 20000 then
				return true
			end
			
			-- Otherwise skip - they don't need side hustles
			return false
		end,
		
		choices = {
			{
				index = 1,
				text = "Sure, I can use the extra cash!",
				effects = { Happiness = 3, Health = -2 },
				feedText = "You took on some side work...",
				onResolve = function(state)
					local earnings = math.random(200, 800)
					state.Money = (state.Money or 0) + earnings
					state.Flags = state.Flags or {}
					state.Flags.side_hustler = true
					if state.AddFeed then
						state:AddFeed(string.format("💵 Side hustle paid $%d! Extra income is nice.", earnings))
					end
				end,
			},
			{
				index = 2,
				text = "I'm too busy for extra work",
				effects = { Happiness = 2, Health = 2 },
				feedText = "Work-life balance is important too.",
			},
		},
	},
	
	{
		id = "dream_job_posting",
		emoji = "⭐",
		title = "Dream Job Posted!",
		text = "You see a job posting that looks PERFECT for you. It's at your dream company!",
		question = "Do you apply?",
		category = "career",
		weight = 4,
		minAge = 22,
		maxAge = 45,
		baseChance = 0.4,
		cooldown = 15,
		oneTime = true,
		blockedByFlags = { in_prison = true, got_dream_job = true },
		
		choices = {
			{
				index = 1,
				text = "Apply immediately!",
				effects = { Happiness = 5 },
				feedText = "You put your best foot forward...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local successChance = 0.3 + (smarts / 200) -- 30-80% based on smarts
					
					if math.random() < successChance then
						local dreamJobs = {
							{ name = "Game Developer", salary = 85000, company = "Dream Studios" },
							{ name = "Product Manager", salary = 95000, company = "Tech Giant Inc" },
							{ name = "Creative Director", salary = 110000, company = "Design Co" },
							{ name = "Software Engineer", salary = 105000, company = "Innovation Labs" },
							{ name = "UX Designer", salary = 82000, company = "Digital Agency" },
						}
						local job = dreamJobs[math.random(1, #dreamJobs)]
						state.CurrentJob = {
							id = "dream_" .. math.random(1000, 9999),
							name = job.name,
							company = job.company,
							salary = job.salary,
							category = "tech",
						}
						state.Flags = state.Flags or {}
						state.Flags.employed = true
						state.Flags.has_job = true
						state.Flags.got_dream_job = true
						if state.AddFeed then
							state:AddFeed(string.format("🌟 DREAM JOB! You're now a %s at %s making $%d!!", job.name, job.company, job.salary))
						end
					else
						state.Flags = state.Flags or {}
						state.Flags.dream_job_rejected = true
						if state.AddFeed then
							state:AddFeed("😢 They went with another candidate. Keep dreaming...")
						end
					end
				end,
			},
			{
				index = 2,
				text = "I'm not qualified enough yet",
				effects = { Happiness = -3 },
				feedText = "Maybe one day you'll feel ready...",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MORE RANDOM LIFE EVENTS - Variety and spontaneity
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "random_compliment",
		emoji = "😊",
		title = "Unexpected Compliment",
		text = "A stranger complimented you out of nowhere! They said you have great style.",
		question = "How do you react?",
		category = "random",
		weight = 6,
		minAge = 10,
		maxAge = 80,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		choices = {
			{
				index = 1,
				text = "Thank them warmly",
				effects = { Happiness = 8, Looks = 1 },
				feedText = "You smiled and thanked them. Made your day!",
			},
			{
				index = 2,
				text = "Get awkward about it",
				effects = { Happiness = 3 },
				feedText = "You mumbled thanks and walked away quickly.",
			},
		},
	},
	
	{
		id = "old_friend_reconnect",
		emoji = "📱",
		title = "Old Friend Reached Out",
		text = "An old friend from years ago messaged you on social media! They want to catch up.",
		question = "Do you reconnect?",
		category = "random",
		weight = 5,
		minAge = 16,
		maxAge = 70,
		baseChance = 0.45,
		cooldown = 4,
		
		choices = {
			{
				index = 1,
				text = "Meet up with them!",
				effects = { Happiness = 10 },
				feedText = "You reconnected! It was like no time had passed.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.reconnected_friend = true
				end,
			},
			{
				index = 2,
				text = "Just text, too busy to meet",
				effects = { Happiness = 5 },
				feedText = "You caught up via text. Nice but not the same.",
			},
			{
				index = 3,
				text = "Ignore the message",
				effects = { Happiness = -2 },
				feedText = "You left them on read. Some people belong in the past.",
			},
		},
	},
	
	{
		-- CRITICAL FIX: Random unexpected skill - completely random, no god-mode choosing
		id = "random_talent_discovery",
		emoji = "🎯",
		title = "Unexpected Skill!",
		text = "Someone challenged you to try something you've never done before. You surprised everyone, including yourself!",
		question = "How do you feel about this discovery?",
		category = "random",
		weight = 4,
		minAge = 10,
		maxAge = 60,
		baseChance = 0.4,
		cooldown = 15,
		oneTime = true,
		choices = {
			{
				index = 1,
				text = "This is amazing! I want to develop this!",
				effects = { Happiness = 12 },
				feedText = "You're excited about your new discovery!",
				onResolve = function(state)
					local talents = {
						{ flag = "singing_talent", text = "🎤 Turns out you can SING! Voice of an angel!" },
						{ flag = "artistic_talent", text = "🎨 You're a natural artist! Your doodles are masterpieces!" },
						{ flag = "cooking_talent", text = "👨‍🍳 Master chef potential! Your food is incredible!" },
						{ flag = "athletic_talent", text = "🏃 Natural athlete! Speed, agility, coordination - you've got it!" },
						{ flag = "dancing_talent", text = "💃 You can DANCE! Natural rhythm and grace!" },
						{ flag = "comedy_talent", text = "😂 You're hilarious! Natural comedian!" },
						{ flag = "mechanical_talent", text = "🔧 Mechanical genius! You can fix anything!" },
					}
					local talent = talents[math.random(1, #talents)]
					state.Flags = state.Flags or {}
					state.Flags[talent.flag] = true
					if state.AddFeed then state:AddFeed(talent.text) end
				end,
			},
			{
				index = 2,
				text = "Cool, but I'm happy with who I am",
				effects = { Happiness = 5 },
				feedText = "You noted it but didn't pursue it. That's okay!",
			},
		},
	},
	
	{
		id = "viral_moment",
		emoji = "📱",
		title = "You Went Viral!",
		text = "Something you posted online went completely viral! Thousands of views!",
		question = "What happened?",
		category = "random",
		weight = 3,
		minAge = 13,
		maxAge = 50,
		baseChance = 0.1,
		cooldown = 20,
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #603: Viral events REQUIRE player to have actually posted content!
		-- User complaint: "Video went viral but I never posted any videos"
		-- Can't go viral if you've never posted anything online!
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Player MUST have some form of online presence/content creation!
			local hasOnlinePresence = flags.content_creator or flags.streamer or flags.influencer
				or flags.first_video_posted or flags.first_video_uploaded or flags.youtube_started
				or flags.social_media_active or flags.pursuing_streaming or flags.youtube_channel
				or flags.internet_famous or flags.went_viral or flags.gaming_content or flags.vlogger
			if not hasOnlinePresence then
				return false, "Player hasn't posted content yet"
			end
			return true
		end,
		
		choices = {
			{
				index = 1,
				text = "Embrace the fame!",
				effects = { Happiness = 15, Looks = 3 },
				feedText = "You went viral! People recognize you now.",
				setFlags = { internet_famous = true },
				onResolve = function(state)
					if math.random() < 0.3 then
						local money = math.random(500, 2000)
						state.Money = (state.Money or 0) + money
						if state.AddFeed then
							state:AddFeed(string.format("💵 Brand deal from your viral post: $%d!", money))
						end
					end
				end,
			},
			{
				index = 2,
				text = "Delete it - too much attention",
				effects = { Happiness = 3 },
				feedText = "You deleted it. Privacy > fame.",
			},
		},
	},
	
	{
		id = "bad_day",
		emoji = "😔",
		title = "Just a Bad Day",
		text = "Everything went wrong today. Spilled coffee, missed the bus, phone died...",
		question = "How do you cope?",
		category = "random",
		weight = 6,
		minAge = 10,
		maxAge = 80,
		baseChance = 0.45,
		cooldown = 3,
		
		choices = {
			{
				index = 1,
				text = "Tomorrow will be better",
				effects = { Happiness = 2, Smarts = 2 },
				feedText = "You stayed positive. That's strength.",
			},
			{
				index = 2,
				text = "Comfort food and early bed",
				effects = { Happiness = 5, Health = -1 },
				feedText = "You treated yourself and called it a day.",
			},
			{
				index = 3,
				text = "Complain to everyone",
				effects = { Happiness = 3 },
				feedText = "Venting helped a little.",
			},
		},
	},
	
	{
		id = "amazing_day",
		emoji = "🌟",
		title = "Everything Went Right!",
		text = "Today was perfect! Everything fell into place. Life is good!",
		question = "How do you celebrate?",
		category = "random",
		weight = 5,
		minAge = 10,
		maxAge = 80,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		choices = {
			{
				index = 1,
				text = "Share the joy with others",
				effects = { Happiness = 15 },
				feedText = "Your good mood was contagious!",
			},
			{
				index = 2,
				text = "Treat yourself to something nice",
				effects = { Happiness = 12, Money = -100 },
				-- MINOR FIX: More descriptive feedText
				feedText = "You treated yourself to something special. You definitely deserve it!",
			},
			{
				index = 3,
				text = "Be grateful and humble",
				effects = { Happiness = 10, Smarts = 2 },
				feedText = "You appreciated the moment.",
			},
		},
	},
	
	{
		id = "neighbor_drama",
		emoji = "🏠",
		title = "Neighbor Issues",
		text = "Your neighbor is being really annoying. Loud music, messy yard, or just rude.",
		question = "How do you handle it?",
		category = "random",
		weight = 5,
		minAge = 18,
		maxAge = 80,
		baseChance = 0.45,
		cooldown = 3,
		blockedByFlags = { homeless = true },
		
		choices = {
			{
				index = 1,
				text = "Talk to them directly and politely",
				effects = { Happiness = 5, Smarts = 3 },
				feedText = "You had a reasonable conversation...",
				onResolve = function(state)
					if math.random() < 0.6 then
						if state.AddFeed then
							state:AddFeed("🤝 They apologized! Problem solved.")
						end
					else
						state.Flags = state.Flags or {}
						state.Flags.bad_neighbor = true
						if state.AddFeed then
							state:AddFeed("😤 They didn't care. Great...")
						end
					end
				end,
			},
			{
				index = 2,
				text = "File a complaint",
				effects = { Happiness = 2 },
				feedText = "You reported them officially.",
			},
			{
				index = 3,
				text = "Just deal with it",
				effects = { Happiness = -3 },
				feedText = "You're being the bigger person. Sort of.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════════════
	-- VEHICLE OWNERSHIP EVENTS
	-- These events ONLY trigger for players who own vehicles (cars, motorcycles, etc.)
	-- ═══════════════════════════════════════════════════════════════════════════════════════
	
	{
		id = "vehicle_breakdown",
		emoji = "🚗",
		title = "Car Trouble!",
		text = "Your car suddenly breaks down on the side of the road! Smoke billows from under the hood.",
		question = "What do you do?",
		category = "vehicle",
		weight = 8,
		minAge = 16,
		maxAge = 90,
		baseChance = 0.5,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		blockedByFlags = { in_prison = true },
		requiresFlags = { has_vehicle = true },
		
		choices = {
			{
				index = 1,
				text = "Call a tow truck ($150)",
				effects = { Happiness = -3 },
				feedText = "Help is on the way...",
				onResolve = function(state)
					local cost = 150
					if (state.Money or 0) >= cost then
						state.Money = state.Money - cost
						if state.AddFeed then
							state:AddFeed("🚗 Tow truck came. Car's at the shop now. -$" .. cost)
						end
					else
						state.Money = 0
						if state.AddFeed then
							state:AddFeed("🚗 Tow truck came but you barely had enough to pay!")
						end
					end
				end,
			},
			{
				index = 2,
				text = "Try to fix it yourself",
				effects = { Happiness = -2, Health = -3 },
				feedText = "You pop the hood and get your hands dirty...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local successChance = 0.2 + (smarts / 200) -- 20-70% based on smarts
					
					if math.random() < successChance then
						if state.ModifyStat then state:ModifyStat("Happiness", 10) end
						state.Flags = state.Flags or {}
						state.Flags.car_mechanic = true
						if state.AddFeed then
							state:AddFeed("🔧 You fixed it! Who needs a mechanic anyway?")
						end
					else
						local cost = math.random(200, 500)
						if (state.Money or 0) >= cost then
							state.Money = state.Money - cost
						else
							state.Money = 0
						end
						if state.AddFeed then
							state:AddFeed(string.format("💸 Made it worse! Had to call a mechanic anyway. -$%d", cost))
						end
					end
				end,
			},
			{
				index = 3,
				text = "Call a friend for a ride",
				effects = { Happiness = -5 },
				feedText = "You wait for help to arrive...",
				onResolve = function(state)
					if state.AddFeed then
						state:AddFeed("🚗 Friend picked you up. Car's still stuck though...")
					end
				end,
			},
		},
	},
	
	{
		id = "vehicle_accident_minor",
		emoji = "💥",
		title = "Fender Bender!",
		text = "Someone rear-ended your car at a red light! The damage looks minor but still...",
		question = "How do you handle this?",
		category = "vehicle",
		weight = 7,
		minAge = 16,
		maxAge = 90,
		baseChance = 0.45,
		cooldown = 3,
		blockedByFlags = { in_prison = true },
		requiresFlags = { has_vehicle = true },
		
		choices = {
			{
				index = 1,
				text = "Exchange insurance information",
				effects = { Happiness = -3 },
				feedText = "You handle it by the book...",
				onResolve = function(state)
					if math.random() < 0.7 then
						-- Insurance covers it
						if state.AddFeed then
							state:AddFeed("📋 Insurance covered the repairs. What a hassle though!")
						end
					else
						-- Insurance doesn't cover it all
						local cost = math.random(100, 300)
						if (state.Money or 0) >= cost then
							state.Money = state.Money - cost
						else
							state.Money = 0
						end
						if state.AddFeed then
							state:AddFeed(string.format("📋 Insurance only covered part of it. You paid $%d out of pocket.", cost))
						end
					end
				end,
			},
			{
				index = 2,
				text = "Demand they pay cash now!",
				effects = { Happiness = -5 },
				feedText = "You're pretty upset about this...",
				onResolve = function(state)
					if math.random() < 0.4 then
						local payout = math.random(200, 500)
						state.Money = (state.Money or 0) + payout
						if state.AddFeed then
							state:AddFeed(string.format("💰 They paid you $%d on the spot. Nice!", payout))
						end
					else
						if state.AddFeed then
							state:AddFeed("😤 They refused. Now you have to go through insurance anyway!")
						end
					end
				end,
			},
			{
				index = 3,
				text = "Let it go - it's just cosmetic",
				effects = { Happiness = -2 },
				feedText = "It's just a car...",
			},
		},
	},
	
	{
		id = "vehicle_car_show",
		emoji = "🏆",
		title = "Local Car Show",
		text = "There's a car show happening this weekend! People are bringing their best rides.",
		question = "Do you enter your car?",
		category = "vehicle",
		weight = 5,
		minAge = 18,
		maxAge = 80,
		baseChance = 0.4,
		cooldown = 4,
		blockedByFlags = { in_prison = true },
		requiresFlags = { has_vehicle = true },
		
		choices = {
			{
				index = 1,
				text = "Enter the competition ($50 entry fee)",
				effects = { Happiness = 5 },
				feedText = "Time to show off your ride...",
				onResolve = function(state)
					if (state.Money or 0) >= 50 then
						state.Money = state.Money - 50
					else
						state.Money = 0
					end
					
					local roll = math.random()
					if roll < 0.15 then
						-- Win first place!
						local prize = math.random(500, 1500)
						state.Money = (state.Money or 0) + prize
						state.Flags = state.Flags or {}
						state.Flags.car_show_winner = true
						if state.ModifyStat then state:ModifyStat("Happiness", 15) end
						if state.AddFeed then
							state:AddFeed(string.format("🏆 FIRST PLACE! You won $%d! Your ride is a showstopper!", prize))
						end
					elseif roll < 0.4 then
						-- Top 3
						local prize = math.random(100, 300)
						state.Money = (state.Money or 0) + prize
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						if state.AddFeed then
							state:AddFeed(string.format("🥈 Top 3 finish! Won $%d. Nice showing!", prize))
						end
					else
						-- Didn't place
						if state.AddFeed then
							state:AddFeed("🚗 Didn't place, but people complimented your car!")
						end
					end
				end,
			},
			{
				index = 2,
				text = "Just attend as a spectator",
				effects = { Happiness = 3 },
				feedText = "You admire the beautiful cars.",
			},
			{
				index = 3,
				text = "Skip it - not my scene",
				effects = {},
				feedText = "Maybe next time.",
			},
		},
	},
	
	{
		id = "vehicle_road_trip",
		emoji = "🛣️",
		title = "Road Trip Opportunity!",
		text = "Your friends are planning an epic road trip! They want you to drive since you have a car.",
		question = "Do you join?",
		category = "vehicle",
		weight = 6,
		minAge = 18,
		maxAge = 65,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		blockedByFlags = { in_prison = true },
		requiresFlags = { has_vehicle = true },
		
		choices = {
			{
				index = 1,
				text = "Let's hit the road! ($200 for gas/expenses)",
				effects = { Happiness = 15, Health = 5 },
				feedText = "Adventure awaits!",
				onResolve = function(state)
					if (state.Money or 0) >= 200 then
						state.Money = state.Money - 200
					else
						state.Money = 0
					end
					
					state.Flags = state.Flags or {}
					state.Flags.road_trip_veteran = true
					
					local destinations = {
						"the Grand Canyon",
						"the beach",
						"the mountains", 
						"Las Vegas",
						"California",
						"the desert",
						"a national park",
						"a music festival",
					}
					local dest = destinations[math.random(1, #destinations)]
					
					if state.AddFeed then
						state:AddFeed(string.format("🛣️ Amazing road trip to %s! Made unforgettable memories!", dest))
					end
				end,
			},
			{
				index = 2,
				text = "I'll pass - too expensive",
				effects = { Happiness = -3 },
				feedText = "FOMO hits hard.",
			},
			{
				index = 3,
				text = "Can't take time off work",
				effects = { Happiness = -5 },
				feedText = "Responsibilities...",
			},
		},
	},
	
	{
		id = "vehicle_theft_attempt",
		emoji = "🚨",
		title = "Car Theft Attempt!",
		text = "You come back to your car and catch someone trying to break in!",
		question = "What do you do?!",
		category = "vehicle",
		weight = 5,
		minAge = 16,
		maxAge = 90,
		baseChance = 0.35,
		cooldown = 4,
		blockedByFlags = { in_prison = true },
		requiresFlags = { has_vehicle = true },
		triggerMinigame = "combat",
		
		choices = {
			{
				index = 1,
				text = "🥊 Confront them!",
				effects = {},
				feedText = "Not my car, you don't!",
				triggerMinigame = "combat",
				onResolve = function(state)
					if state.AddFeed then
						state:AddFeed("💪 You scared them off! Your car is safe.")
					end
				end,
			},
			{
				index = 2,
				text = "Call the police",
				effects = { Happiness = -5 },
				feedText = "You dial 911...",
				onResolve = function(state)
					if math.random() < 0.6 then
						if state.AddFeed then
							state:AddFeed("🚔 Police arrived quickly. They caught the thief!")
						end
					else
						local damage = math.random(100, 400)
						if (state.Money or 0) >= damage then
							state.Money = state.Money - damage
						else
							state.Money = 0
						end
						if state.AddFeed then
							state:AddFeed(string.format("🚔 Thief got away but damaged your car. Repairs cost $%d", damage))
						end
					end
				end,
			},
			{
				index = 3,
				text = "Honk and yell from a distance",
				effects = { Happiness = -3 },
				feedText = "You make a scene...",
				onResolve = function(state)
					if state.AddFeed then
						state:AddFeed("📢 They ran off! Could've been worse.")
					end
				end,
			},
		},
	},
	
	{
		id = "vehicle_speeding_ticket",
		emoji = "🚓",
		title = "Pulled Over!",
		text = "Blue lights flash behind you. A cop pulls you over for speeding!",
		question = "How do you handle this?",
		category = "vehicle",
		weight = 8,
		minAge = 16,
		maxAge = 90,
		baseChance = 0.5,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		blockedByFlags = { in_prison = true },
		requiresFlags = { has_vehicle = true },
		
		choices = {
			{
				index = 1,
				text = "Be polite and apologetic",
				effects = { Happiness = -3 },
				feedText = "You're respectful with the officer...",
				onResolve = function(state)
					if math.random() < 0.3 then
						-- Warning
						if state.AddFeed then
							state:AddFeed("🚓 The officer let you off with a warning! Lucky!")
						end
					else
						-- Ticket
						local fine = math.random(150, 350)
						if (state.Money or 0) >= fine then
							state.Money = state.Money - fine
						else
							state.Money = 0
						end
						if state.AddFeed then
							state:AddFeed(string.format("🚓 Got a speeding ticket. $%d fine. Ugh.", fine))
						end
					end
				end,
			},
			{
				index = 2,
				text = "Try to talk your way out of it",
				effects = { Happiness = -2 },
				feedText = "You try to be charming...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local successChance = 0.1 + (looks / 300) -- 10-43% based on looks
					
					if math.random() < successChance then
						if state.AddFeed then
							state:AddFeed("😊 Your charm worked! Just a warning.")
						end
					else
						local fine = math.random(200, 400)
						if (state.Money or 0) >= fine then
							state.Money = state.Money - fine
						else
							state.Money = 0
						end
						if state.AddFeed then
							state:AddFeed(string.format("😬 That backfired. $%d ticket PLUS attitude.", fine))
						end
					end
				end,
			},
			{
				index = 3,
				text = "Accept your fate silently",
				effects = { Happiness = -5 },
				feedText = "You take the L...",
				onResolve = function(state)
					local fine = math.random(175, 325)
					if (state.Money or 0) >= fine then
						state.Money = state.Money - fine
					else
						state.Money = 0
					end
					if state.AddFeed then
						state:AddFeed(string.format("🚓 $%d speeding ticket. Slow down next time.", fine))
					end
				end,
			},
		},
	},
	
	{
		id = "vehicle_upgrade_offer",
		emoji = "🔧",
		title = "Upgrade Your Ride!",
		text = "A mechanic friend offers to do some upgrades on your car for cheap!",
		question = "What upgrades do you want?",
		category = "vehicle",
		weight = 5,
		minAge = 18,
		maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		blockedByFlags = { in_prison = true },
		requiresFlags = { has_vehicle = true },
		
		choices = {
			{
				index = 1,
				text = "Performance upgrades ($800)",
				effects = { Happiness = 8 },
				feedText = "Time to boost your ride...",
				onResolve = function(state)
					if (state.Money or 0) >= 800 then
						state.Money = state.Money - 800
						state.Flags = state.Flags or {}
						state.Flags.car_upgraded = true
						state.Flags.fast_car = true
						if state.AddFeed then
							state:AddFeed("🏎️ Your car is FAST now! That engine purrs!")
						end
					else
						if state.AddFeed then
							state:AddFeed("💸 Not enough cash for the full upgrade package...")
						end
					end
				end,
			},
			{
				index = 2,
				text = "Cosmetic upgrades ($500)",
				effects = { Happiness = 6 },
				feedText = "Making it look good...",
				onResolve = function(state)
					if (state.Money or 0) >= 500 then
						state.Money = state.Money - 500
						state.Flags = state.Flags or {}
						state.Flags.car_customized = true
						if state.ModifyStat then state:ModifyStat("Looks", 2) end
						if state.AddFeed then
							state:AddFeed("✨ Your car looks amazing! New paint and trim!")
						end
					else
						if state.AddFeed then
							state:AddFeed("💸 Couldn't afford the full cosmetic package...")
						end
					end
				end,
			},
			{
				index = 3,
				text = "Pass - my car is fine as is",
				effects = { Happiness = 2 },
				feedText = "If it ain't broke...",
			},
		},
	},
	
	{
		id = "vehicle_racing_challenge",
		emoji = "🏁",
		title = "Street Racing Challenge!",
		text = "Someone pulls up next to you at a red light and revs their engine, challenging you to race!",
		question = "What do you do?",
		category = "vehicle",
		weight = 6,
		minAge = 18,
		maxAge = 45,
		baseChance = 0.4,
		cooldown = 3,
		blockedByFlags = { in_prison = true },
		requiresFlags = { has_vehicle = true },
		triggerMinigame = "qte",
		
		choices = {
			{
				index = 1,
				text = "🏎️ Accept the challenge!",
				effects = {},
				feedText = "Green light... GO!",
				triggerMinigame = "qte",
				minigameOptions = { difficulty = "medium" },
				onResolve = function(state)
					-- Result depends on minigame outcome
					if state.Flags and state.Flags.last_minigame_won then
						local prize = math.random(200, 800)
						state.Money = (state.Money or 0) + prize
						state.Flags.street_racer = true
						if state.ModifyStat then state:ModifyStat("Happiness", 12) end
						if state.AddFeed then
							state:AddFeed(string.format("🏆 YOU WON! They paid up $%d. Speed demon!", prize))
						end
					else
						if state.AddFeed then
							state:AddFeed("😤 You lost! They left you in their dust.")
						end
						if state.ModifyStat then state:ModifyStat("Happiness", -8) end
					end
				end,
			},
			{
				index = 2,
				text = "Ignore them - not worth the risk",
				effects = { Happiness = -2 },
				feedText = "You play it smart.",
			},
			{
				index = 3,
				text = "Roll down window and laugh",
				effects = { Happiness = 3 },
				feedText = "You're above petty challenges.",
			},
		},
	},
	
	{
		id = "vehicle_parking_disaster",
		emoji = "🅿️",
		title = "Parking Nightmare!",
		text = "You return to your car and find someone has DOUBLE PARKED blocking you in!",
		question = "What do you do?",
		category = "vehicle",
		weight = 7,
		minAge = 16,
		maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		blockedByFlags = { in_prison = true },
		requiresFlags = { has_vehicle = true },
		
		choices = {
			{
				index = 1,
				text = "Wait for them to come back",
				effects = { Happiness = -5 },
				feedText = "You wait... and wait...",
				onResolve = function(state)
					if math.random() < 0.6 then
						if state.AddFeed then
							state:AddFeed("⏰ They finally came back after 30 minutes. Unbelievable!")
						end
					else
						if state.AddFeed then
							state:AddFeed("😤 An HOUR later... they didn't even apologize!")
						end
						if state.ModifyStat then state:ModifyStat("Happiness", -5) end
					end
				end,
			},
			{
				index = 2,
				text = "Call parking enforcement",
				effects = { Happiness = -3 },
				feedText = "Time to teach them a lesson...",
				onResolve = function(state)
					if state.AddFeed then
						state:AddFeed("🚔 They got a ticket AND towed! Justice served.")
					end
					if state.ModifyStat then state:ModifyStat("Happiness", 5) end
				end,
			},
			{
				index = 3,
				text = "Try to squeeze out anyway",
				effects = {},
				feedText = "It's gonna be tight...",
				onResolve = function(state)
					if math.random() < 0.4 then
						if state.AddFeed then
							state:AddFeed("🚗 You made it out! Tight squeeze but no scratches!")
						end
					else
						local damage = math.random(100, 300)
						if (state.Money or 0) >= damage then
							state.Money = state.Money - damage
						else
							state.Money = 0
						end
						if state.AddFeed then
							state:AddFeed(string.format("💥 Scraped your car getting out. $%d in damage...", damage))
						end
					end
				end,
			},
		},
	},
	
	{
		id = "vehicle_gas_prices",
		emoji = "⛽",
		title = "Gas Price Shock!",
		text = "You pull up to the gas station and see prices have SKYROCKETED!",
		question = "What do you do?",
		category = "vehicle",
		weight = 8,
		minAge = 16,
		maxAge = 90,
		baseChance = 0.35, -- FIXED: Lowered to reduce spam
		cooldown = 4, -- FIXED: Increased from 1 - gas prices don't spike every year
		blockedByFlags = { in_prison = true },
		requiresFlags = { has_vehicle = true },
		
		choices = {
			{
				index = 1,
				text = "Fill up anyway - you need gas",
				effects = { Happiness = -3 },
				feedText = "You pump reluctantly...",
				onResolve = function(state)
					local cost = math.random(60, 100)
					if (state.Money or 0) >= cost then
						state.Money = state.Money - cost
					else
						state.Money = 0
					end
					if state.AddFeed then
						state:AddFeed(string.format("⛽ $%d to fill up?! Highway robbery!", cost))
					end
				end,
			},
			{
				index = 2,
				text = "Just get $20 worth",
				effects = { Happiness = -1 },
				feedText = "A little is better than none.",
				onResolve = function(state)
					if (state.Money or 0) >= 20 then
						state.Money = state.Money - 20
					else
						state.Money = 0
					end
					if state.AddFeed then
						state:AddFeed("⛽ Got just enough to get by. These prices are crazy!")
					end
				end,
			},
			{
				index = 3,
				text = "Drive to a cheaper station",
				effects = { Happiness = 2 },
				feedText = "You hunt for a better deal...",
				onResolve = function(state)
					local cost = math.random(40, 70)
					if (state.Money or 0) >= cost then
						state.Money = state.Money - cost
					else
						state.Money = 0
					end
					if state.AddFeed then
						state:AddFeed(string.format("⛽ Found cheaper gas! Only $%d to fill up.", cost))
					end
				end,
			},
			{
				index = 4,
				text = "Skip it - take the bus today",
				effects = { Happiness = -1 },
				feedText = "⛽ Left the car parked. Public transit it is!",
			},
		},
	},
}

return Random
