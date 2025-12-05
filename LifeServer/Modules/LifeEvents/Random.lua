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
		question = "What do you do with it?",
		minAge = 6, maxAge = 90,
		baseChance = 0.2,
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
		question = "Let's see what you won!",
		minAge = 18, maxAge = 90,
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{ text = "BIG WINNER!", effects = { Happiness = 20, Money = 5000 }, feedText = "Incredible! You won big!" },
			{ text = "Small prize", effects = { Happiness = 5, Money = 50 }, feedText = "You won a little something!" },
			{ text = "Nothing this time", effects = { Happiness = -2 }, feedText = "No luck. Better luck next time." },
		},
	},
	{
		id = "inheritance",
		title = "Unexpected Inheritance",
		emoji = "📜",
		text = "A distant relative you barely knew passed away and left you something.",
		question = "What did you inherit?",
		minAge = 25, maxAge = 80,
		baseChance = 0.15,
		cooldown = 10,
		oneTime = true,
		choices = {
			{
				text = "A substantial sum",
				effects = { Happiness = 10, Money = 10000 },
				feedText = "You inherited a nice sum of money!",
			},
			{
				text = "A quirky family heirloom",
				effects = { Happiness = 5 },
				setFlags = { has_heirloom = true },
				feedText = "An interesting piece of family history.",
				onResolve = function(state)
					local EventEngine = require(script.Parent).EventEngine
					EventEngine.addAsset(state, "item", {
						id = "family_heirloom_" .. tostring(state.Age),
						name = "Family Heirloom",
						emoji = "🏺",
						price = 0,
						value = 2500,
						isEventAcquired = true,
					})
				end,
			},
			{
				text = "An old house",
				effects = { Happiness = 8 },
				setFlags = { inherited_property = true, homeowner = true, has_property = true },
				feedText = "You inherited a property!",
				onResolve = function(state)
					local EventEngine = require(script.Parent).EventEngine
					EventEngine.addAsset(state, "property", {
						id = "inherited_house_" .. tostring(state.Age),
						name = "Inherited House",
						emoji = "🏚️",
						price = 0,
						value = 120000,
						income = 800, -- can rent it out
						isEventAcquired = true,
					})
				end,
			},
			{
				text = "Some debt, unfortunately",
				effects = { Happiness = -5, Money = -2000 },
				feedText = "They left you with bills to pay.",
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
		text = "You had a minor accident with a specific injury.",
		question = "What happened?",
		minAge = 5, maxAge = 80,
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{
				text = "Tripped and fell",
				effects = { Health = -5, Happiness = -3 },
				feedText = "You took a tumble. Bruises heal.",
				onResolve = function(state)
					if state.ApplyInjury then
						state:ApplyInjury({ locations = { "knee", "elbow", "face" }, severity = "minor", cause = "fall" })
					end
				end,
			},
			{
				text = "Cut yourself cooking",
				effects = { Health = -3, Smarts = 2 },
				feedText = "Kitchen accidents happen.",
				onResolve = function(state)
					if state.ApplyInjury then
						state:ApplyInjury({ locations = { "hand", "finger" }, severity = "minor", cause = "kitchen knife" })
					end
				end,
			},
			{
				text = "Sports injury",
				effects = { Health = -8, Happiness = -2 },
				setFlags = { sports_injury = true },
				feedText = "You got hurt playing sports.",
				onResolve = function(state)
					if state.ApplyInjury then
						state:ApplyInjury({ locations = { "ankle", "knee", "shoulder" }, severity = "moderate", cause = "sports" })
					end
				end,
			},
			{
				text = "Stubbed toe badly",
				effects = { Health = -2, Happiness = -5 },
				feedText = "The pain! It never gets easier!",
				onResolve = function(state)
					if state.ApplyInjury then
						state:ApplyInjury({ locations = { "toe", "foot" }, severity = "minor", cause = "impact" })
					end
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
		baseChance = 0.3,
		cooldown = 2,
		requiresFlags = { has_car = true },
		choices = {
			{
				text = "Pay for repairs",
				effects = { Money = -500, Happiness = -3 },
				feedText = "Expensive repairs. Cars, right?",
			},
			{
				text = "Try to fix it yourself",
				effects = { Money = -100, Smarts = 3, Health = -2 },
				feedText = "You learned something, at least.",
			},
			{
				text = "Junk it and buy a new car",
				effects = { Money = -5000, Happiness = 5 },
				feedText = "Time for an upgrade anyway!",
				onResolve = function(state)
					local EventEngine = require(script.Parent).EventEngine
					-- Remove old car (first one found)
					local vehicles = state.Assets and state.Assets.Vehicles
					if vehicles and #vehicles > 0 then
						local oldCar = table.remove(vehicles, 1)
						-- Add new car
						EventEngine.addAsset(state, "vehicle", {
							id = "replacement_car_" .. tostring(state.Age),
							name = "New Reliable Car",
							emoji = "🚗",
							price = 5000,
							value = 4500,
							condition = 85,
							isEventAcquired = true,
						})
					end
				end,
			},
			{
				text = "Sell it for scrap and take the bus",
				effects = { Money = 300, Happiness = -5 },
				feedText = "You sold the heap and went back to public transit.",
				onResolve = function(state)
					local EventEngine = require(script.Parent).EventEngine
					-- Remove all vehicles (simplification - in reality would track specific one)
					local vehicles = state.Assets and state.Assets.Vehicles
					if vehicles and #vehicles > 0 then
						table.remove(vehicles, 1) -- Remove first car
					end
					-- Clear vehicle flags if no vehicles left
					if not vehicles or #vehicles == 0 then
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
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{ text = "Get the latest model", effects = { Money = -800, Happiness = 8 }, feedText = "New phone! Shiny!" },
			{ text = "Get a basic replacement", effects = { Money = -200, Happiness = 2 }, feedText = "It works. That's what matters." },
			{ text = "Fix the old one", effects = { Money = -100, Happiness = 3, Smarts = 2 }, feedText = "Good as new (almost)." },
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
		cooldown = 2,
		choices = {
			{ text = "Rest up properly", effects = { Health = 3, Happiness = -2 }, feedText = "You took care of yourself." },
			{ text = "Push through it", effects = { Health = -3, Happiness = -3 }, feedText = "You kept going. Probably not wise." },
			{ text = "Home remedies", effects = { Health = 2 }, feedText = "Soup and tea worked wonders." },
			{ text = "See a doctor", effects = { Health = 5, Money = -100 }, feedText = "The doctor helped you recover faster." },
		},
	},
	{
		id = "fitness_moment",
		title = "Health Motivation",
		emoji = "💪",
		text = "You're feeling motivated to get in better shape.",
		question = "What do you do?",
		minAge = 15, maxAge = 70,
		baseChance = 0.3,
		cooldown = 3,
		choices = {
			{ text = "Start going to the gym", effects = { Health = 8, Happiness = 5, Money = -50 }, setFlags = { gym_member = true }, feedText = "You joined a gym!" },
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
		baseChance = 0.15,
		cooldown = 5,
		choices = {
			{ text = "Ask for a selfie", effects = { Happiness = 10 }, feedText = "You got a photo with a celebrity!" },
			{ text = "Play it cool", effects = { Happiness = 5, Smarts = 2 }, feedText = "You acted casual. Smooth." },
			{ text = "Totally fanboy/fangirl", effects = { Happiness = 7, Looks = -2 }, feedText = "You couldn't contain your excitement!" },
			{ text = "Didn't recognize them", effects = { }, feedText = "Wait, who was that?" },
		},
	},
	{
		id = "random_kindness",
		title = "Random Act of Kindness",
		emoji = "💝",
		text = "A stranger did something unexpectedly kind for you.",
		question = "How did it make you feel?",
		minAge = 5, maxAge = 90,
		baseChance = 0.3,
		cooldown = 2,
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
		cooldown = 2,
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
		id = "weather_event",
		title = "Weather Watch",
		emoji = "🌦️",
		text = "The weather is affecting your plans today.",
		question = "What's happening?",
		minAge = 5, maxAge = 90,
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{ text = "Beautiful day - enjoyed it!", effects = { Happiness = 7, Health = 3 }, feedText = "Perfect weather made everything better!" },
			{ text = "Rainy day - stayed in", effects = { Happiness = 3 }, feedText = "Cozy day indoors." },
			{ text = "Snowstorm - adventure!", effects = { Happiness = 5, Health = 2 }, feedText = "You made the most of the snow!" },
			{ text = "Heat wave - tough day", effects = { Happiness = -3, Health = -2 }, feedText = "The heat was brutal." },
		},
	},
	{
		id = "lost_item",
		title = "Where Did It Go?",
		emoji = "🔍",
		text = "You lost something important.",
		question = "What was it?",
		minAge = 5, maxAge = 90,
		baseChance = 0.3,
		cooldown = 3,
		choices = {
			{ text = "Keys - found them eventually", effects = { Happiness = -3 }, feedText = "Stressful search, but they turned up." },
			{ text = "Wallet - had to cancel cards", effects = { Happiness = -5, Money = -50 }, feedText = "What a hassle!" },
			{ text = "Something sentimental", effects = { Happiness = -7 }, feedText = "It can't be replaced..." },
			{ text = "Something replaceable", effects = { Happiness = -2, Money = -30 }, feedText = "Annoying, but not the end of the world." },
		},
	},
	{
		id = "new_hobby",
		title = "New Interest",
		emoji = "🎯",
		text = "You've discovered a new hobby!",
		question = "What caught your interest?",
		minAge = 10, maxAge = 80,
		baseChance = 0.3,
		cooldown = 3,
		choices = {
			{ text = "Gaming", effects = { Happiness = 7, Smarts = 2 }, setFlags = { gamer = true }, feedText = "You got into gaming!" },
			{ text = "Crafting/DIY", effects = { Happiness = 5, Smarts = 3 }, setFlags = { crafter = true }, feedText = "You love making things!" },
			{ text = "Cooking/Baking", effects = { Happiness = 6, Health = 2 }, setFlags = { foodie = true }, feedText = "You're exploring the kitchen!" },
			{ text = "Reading", effects = { Smarts = 5, Happiness = 4 }, setFlags = { bookworm = true }, feedText = "Books are your new escape!" },
			{ text = "Outdoor activities", effects = { Health = 5, Happiness = 5 }, setFlags = { outdoorsy = true }, feedText = "Nature calls to you!" },
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
		baseChance = 0.15,
		cooldown = 5,
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
		baseChance = 0.3,
		cooldown = 3,
		choices = {
			{ text = "Absolutely, adventure awaits!", effects = { Happiness = 12, Money = -1000 }, setFlags = { well_traveled = true }, feedText = "You went on an amazing trip!" },
			{ text = "Go on a budget", effects = { Happiness = 7, Money = -300 }, setFlags = { well_traveled = true }, feedText = "You traveled smart!" },
			{ text = "Not the right time", effects = { Happiness = -2, Money = 200 }, feedText = "You saved the money instead." },
		},
	},
	{
		id = "volunteer_moment",
		title = "Helping Others",
		emoji = "🤝",
		text = "You spent some time helping others in need.",
		question = "How did it feel?",
		minAge = 12, maxAge = 90,
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{ text = "Incredibly rewarding", effects = { Happiness = 10 }, setFlags = { volunteer = true, community_minded = true }, feedText = "Helping others filled your heart." },
			{ text = "Eye-opening experience", effects = { Happiness = 5, Smarts = 3 }, setFlags = { volunteer = true }, feedText = "You gained perspective." },
			{ text = "Harder than expected", effects = { Happiness = 3, Health = -2 }, setFlags = { volunteer = true }, feedText = "It was tough but meaningful." },
		},
	},
}

return Random
