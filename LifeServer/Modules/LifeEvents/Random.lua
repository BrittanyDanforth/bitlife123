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
			end,
		},
		{
			text = "An old house",
			effects = { Happiness = 8 },
			setFlags = { inherited_property = true, homeowner = true, has_property = true },
			feedText = "You inherited a property!",
			onResolve = function(state)
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
		text = "You had a minor accident.",
		question = "What happened?",
		minAge = 5, maxAge = 80,
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{ text = "Tripped and fell", effects = { Health = -5, Happiness = -3 }, feedText = "You took a tumble. Bruises heal." },
			{ text = "Cut yourself cooking", effects = { Health = -3, Smarts = 2 }, feedText = "Kitchen accidents happen." },
			{ text = "Sports injury", effects = { Health = -8, Happiness = -2 }, setFlags = { sports_injury = true }, feedText = "You got hurt playing sports." },
			{ text = "Stubbed toe badly", effects = { Health = -2, Happiness = -5 }, feedText = "The pain! It never gets easier!" },
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

	-- ══════════════════════════════════════════════════════════════════════════════
	-- INJURY SYSTEM - BITLIFE STYLE "WHERE DID YOU GET HURT?"
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "injury_fall",
		title = "Bad Fall!",
		emoji = "🤕",
		text = "You took a nasty fall!",
		question = "Where did you get hurt?",
		minAge = 3, maxAge = 85,
		baseChance = 0.25,
		cooldown = 2,
		category = "injury",

		choices = {
			{ text = "My head - hit it hard", effects = { Health = -15, Smarts = -2, Happiness = -10 }, setFlags = { head_injury = true }, feedText = "You hit your head badly. Doctors are concerned." },
			{ text = "My arm - might be broken", effects = { Health = -12, Happiness = -8 }, setFlags = { broken_arm = true }, feedText = "You broke your arm! Months in a cast." },
			{ text = "My leg - can't walk right", effects = { Health = -12, Happiness = -8 }, setFlags = { broken_leg = true }, feedText = "You broke your leg. Crutches for months." },
			{ text = "My back - really hurts", effects = { Health = -18, Happiness = -12 }, setFlags = { back_injury = true }, feedText = "Back injury. This might be a long recovery." },
			{ text = "Just some scrapes and bruises", effects = { Health = -5, Happiness = -3 }, feedText = "You got off lucky with minor injuries." },
		},
	},
	{
		id = "injury_sports",
		title = "Sports Injury!",
		emoji = "⚽",
		text = "You got injured playing sports!",
		question = "What happened?",
		minAge = 6, maxAge = 60,
		baseChance = 0.3,
		cooldown = 2,
		category = "injury",

		choices = {
			{ text = "Twisted my ankle badly", effects = { Health = -10, Happiness = -6 }, setFlags = { sprained_ankle = true }, feedText = "Nasty ankle sprain. You'll be off your feet for a while." },
			{ text = "Knee injury - heard a pop", effects = { Health = -20, Happiness = -15, Money = -2000 }, setFlags = { acl_injury = true, needs_surgery = true }, feedText = "Torn ACL. Surgery is required." },
			{ text = "Dislocated my shoulder", effects = { Health = -12, Happiness = -8, Money = -500 }, setFlags = { shoulder_injury = true }, feedText = "Shoulder popped out! Emergency room visit." },
			{ text = "Got hit in the face", effects = { Health = -8, Looks = -3, Happiness = -7 }, setFlags = { facial_injury = true }, feedText = "Your face took the hit. Bruised and swollen." },
			{ text = "Concussion from collision", effects = { Health = -15, Smarts = -3, Happiness = -10 }, setFlags = { concussion = true }, feedText = "Concussion. You need to take it easy." },
			{ text = "Minor strain - tough it out", effects = { Health = -3, Happiness = -2 }, feedText = "You pushed through a minor strain." },
		},
	},
	{
		id = "injury_car_accident",
		title = "Car Accident!",
		emoji = "🚗💥",
		text = "You were in a car accident!",
		question = "How bad was it?",
		minAge = 16, maxAge = 90,
		baseChance = 0.1,
		cooldown = 5,
		category = "injury",

		choices = {
			{ text = "Whiplash - neck hurts", effects = { Health = -10, Happiness = -8, Money = -300 }, setFlags = { whiplash = true }, feedText = "Whiplash from the accident. Painful but you'll recover." },
			{ text = "Broken ribs", effects = { Health = -20, Happiness = -15, Money = -1000 }, setFlags = { broken_ribs = true }, feedText = "Broken ribs. Every breath hurts." },
			{ text = "Serious head trauma", effects = { Health = -35, Smarts = -5, Happiness = -20, Money = -10000 }, setFlags = { traumatic_injury = true, hospitalized = true }, feedText = "Severe head trauma. Long hospital stay ahead." },
			{ text = "Broken bones multiple places", effects = { Health = -30, Happiness = -20, Money = -5000 }, setFlags = { multiple_fractures = true, hospitalized = true }, feedText = "Multiple broken bones. Extensive recovery." },
			{ text = "Just shaken up - walked away", effects = { Health = -3, Happiness = -5 }, feedText = "Miraculously, you walked away with just a scare." },
			{ text = "The car is totaled but I'm fine", effects = { Money = -3000, Happiness = -8 }, setFlags = { lost_car = true }, feedText = "Your car is destroyed but you're alive.", onResolve = function(state)
				-- Remove vehicle
				local vehicles = state.Assets and state.Assets.Vehicles
				if vehicles and #vehicles > 0 then
					table.remove(vehicles, 1)
				end
				if state.Flags then
					state.Flags.has_car = nil
				end
			end },
		},
	},
	{
		id = "injury_work_accident",
		title = "Workplace Accident!",
		emoji = "🏭",
		text = "You got injured at work!",
		question = "What happened?",
		minAge = 16, maxAge = 70,
		baseChance = 0.15,
		cooldown = 4,
		category = "injury",

		choices = {
			{ text = "Fell off a ladder", effects = { Health = -18, Happiness = -10, Money = 1000 }, setFlags = { workplace_injury = true }, feedText = "Ladder fall at work. Workers' comp is kicking in." },
			{ text = "Repetitive strain injury", effects = { Health = -8, Happiness = -5 }, setFlags = { rsi = true }, feedText = "Carpal tunnel from work. Need to take breaks." },
			{ text = "Heavy object fell on me", effects = { Health = -25, Happiness = -15, Money = 2000 }, setFlags = { workplace_injury = true, hospitalized = true }, feedText = "Crushed by equipment. Serious but compensated." },
			{ text = "Chemical burn", effects = { Health = -15, Looks = -5, Happiness = -12 }, setFlags = { chemical_injury = true }, feedText = "Chemical burn. Scarring is likely." },
			{ text = "Minor cut - first aid was enough", effects = { Health = -3, Happiness = -2 }, feedText = "Just a cut. Band-aid and back to work." },
		},
	},
	{
		id = "injury_home_accident",
		title = "Accident at Home!",
		emoji = "🏠",
		text = "You had an accident at home!",
		question = "What happened?",
		minAge = 3, maxAge = 90,
		baseChance = 0.2,
		cooldown = 2,
		category = "injury",

		choices = {
			{ text = "Slipped in the bathroom", effects = { Health = -12, Happiness = -8 }, setFlags = { bathroom_fall = true }, feedText = "Slipped and fell in the bathroom. Ouch!" },
			{ text = "Burned myself cooking", effects = { Health = -8, Looks = -2, Happiness = -5 }, feedText = "Kitchen burn. Not too bad, but painful." },
			{ text = "Cut myself with a knife", effects = { Health = -10, Happiness = -6, Money = -200 }, feedText = "Deep cut. Needed stitches." },
			{ text = "Fell down the stairs", effects = { Health = -20, Happiness = -12 }, setFlags = { stair_fall = true }, feedText = "Tumbled down the stairs. Major bruising." },
			{ text = "Furniture fell on me", effects = { Health = -15, Happiness = -8 }, feedText = "Furniture accident. That bookshelf was heavy!" },
			{ text = "Stubbed toe - broken", effects = { Health = -5, Happiness = -8 }, setFlags = { broken_toe = true }, feedText = "Broken toe! Such a small thing, so much pain!" },
		},
	},
	{
		id = "injury_attack",
		title = "Attacked!",
		emoji = "👊",
		text = "Someone attacked you!",
		question = "How badly were you hurt?",
		minAge = 12, maxAge = 80,
		baseChance = 0.08,
		cooldown = 6,
		category = "injury",

		choices = {
			{ text = "Black eye and bruises", effects = { Health = -10, Looks = -5, Happiness = -12 }, setFlags = { assault_victim = true }, feedText = "You were beaten up. Face is bruised badly." },
			{ text = "Stabbed - rushed to hospital", effects = { Health = -40, Happiness = -25, Money = -5000 }, setFlags = { stabbing_victim = true, hospitalized = true }, feedText = "You were stabbed. Critical condition." },
			{ text = "Knocked unconscious", effects = { Health = -20, Smarts = -2, Happiness = -15 }, setFlags = { assault_victim = true, concussion = true }, feedText = "Knocked out cold. Woke up in hospital." },
			{ text = "Fought them off - minor injuries", effects = { Health = -8, Happiness = -5 }, setFlags = { self_defense = true }, feedText = "You defended yourself and escaped!" },
			{ text = "Robbed and injured", effects = { Health = -12, Happiness = -15, Money = -500 }, setFlags = { robbery_victim = true }, feedText = "They took your stuff and hurt you." },
		},
	},
	{
		id = "injury_animal",
		title = "Animal Attack!",
		emoji = "🐕",
		text = "You were attacked by an animal!",
		question = "What kind of animal?",
		minAge = 3, maxAge = 85,
		baseChance = 0.1,
		cooldown = 5,
		category = "injury",

		choices = {
			{ text = "Dog bite on arm", effects = { Health = -12, Happiness = -8, Money = -200 }, setFlags = { dog_bite = true }, feedText = "A dog bit your arm badly. Needed treatment." },
			{ text = "Dog bite on leg", effects = { Health = -10, Happiness = -7 }, setFlags = { dog_bite = true }, feedText = "Dog bit your leg. Painful but healing." },
			{ text = "Cat scratch got infected", effects = { Health = -8, Happiness = -5, Money = -150 }, feedText = "Cat scratch turned into an infection. Antibiotics needed." },
			{ text = "Bee/wasp sting - allergic reaction", effects = { Health = -20, Happiness = -12, Money = -500 }, setFlags = { allergic_reaction = true }, feedText = "Severe allergic reaction! Emergency treatment." },
			{ text = "Snake bite", effects = { Health = -25, Happiness = -15, Money = -1000 }, setFlags = { snake_bite = true, hospitalized = true }, feedText = "Snake bite! Hospital stay for antivenin." },
			{ text = "Minor scratch - cleaned it up", effects = { Health = -3, Happiness = -2 }, feedText = "Just a scratch. Cleaned and bandaged." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ILLNESS SYSTEM - BITLIFE STYLE SICKNESS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "illness_flu",
		title = "Flu Season Hit!",
		emoji = "🤒",
		text = "You caught the flu!",
		question = "How bad is it?",
		minAge = 3, maxAge = 90,
		baseChance = 0.35,
		cooldown = 2,
		category = "illness",

		choices = {
			{ text = "Miserable for a week", effects = { Health = -10, Happiness = -8 }, feedText = "A week in bed with the flu. Awful." },
			{ text = "Mild case - over quickly", effects = { Health = -5, Happiness = -3 }, feedText = "Mild flu. You bounced back fast." },
			{ text = "Turned into pneumonia", effects = { Health = -25, Happiness = -15, Money = -1000 }, setFlags = { pneumonia = true, hospitalized = true }, feedText = "Flu turned into pneumonia. Hospital stay." },
			{ text = "Just a 24-hour bug", effects = { Health = -3, Happiness = -2 }, feedText = "Quick stomach bug. One bad day." },
		},
	},
	{
		id = "illness_food_poisoning",
		title = "Food Poisoning!",
		emoji = "🤢",
		text = "You got food poisoning!",
		question = "How did you handle it?",
		minAge = 5, maxAge = 90,
		baseChance = 0.2,
		cooldown = 2,
		category = "illness",

		choices = {
			{ text = "Worst 24 hours of my life", effects = { Health = -10, Happiness = -12 }, feedText = "Brutal food poisoning. Never eating there again." },
			{ text = "Mild but unpleasant", effects = { Health = -5, Happiness = -5 }, feedText = "Stomach issues for a day. Manageable." },
			{ text = "Needed IV fluids at hospital", effects = { Health = -15, Happiness = -10, Money = -500 }, setFlags = { dehydrated = true }, feedText = "So dehydrated you needed the ER." },
			{ text = "Passed quickly", effects = { Health = -3, Happiness = -3 }, feedText = "Over in a few hours. Lucky." },
		},
	},
	{
		id = "illness_mental_health",
		title = "Mental Health Struggle",
		emoji = "😔",
		text = "You're struggling with your mental health.",
		question = "What are you experiencing?",
		minAge = 12, maxAge = 90,
		baseChance = 0.2,
		cooldown = 3,
		category = "mental_health",

		choices = {
			{ text = "Depression - everything feels heavy", effects = { Happiness = -20, Health = -5 }, setFlags = { depression = true }, feedText = "Depression hit hard. Seeking help is important." },
			{ text = "Anxiety - constant worry", effects = { Happiness = -15, Health = -3, Smarts = -2 }, setFlags = { anxiety = true }, feedText = "Anxiety is overwhelming. Hard to focus." },
			{ text = "Burnout - completely exhausted", effects = { Happiness = -15, Health = -10 }, setFlags = { burnout = true }, feedText = "Burnout. You need a real break." },
			{ text = "Started therapy - feeling better", effects = { Happiness = 5, Money = -500 }, setFlags = { in_therapy = true }, feedText = "Therapy is helping. Progress takes time." },
			{ text = "Medication is helping", effects = { Happiness = 8, Health = 3, Money = -200 }, setFlags = { on_medication = true }, feedText = "Medication made a real difference." },
		},
	},
	{
		id = "illness_chronic",
		title = "Chronic Condition",
		emoji = "🏥",
		text = "You've been diagnosed with a chronic condition.",
		question = "What's the diagnosis?",
		minAge = 25, maxAge = 85,
		baseChance = 0.1,
		cooldown = 10,
		category = "illness",

		choices = {
			{ text = "Diabetes - manageable with lifestyle", effects = { Health = -10, Happiness = -8, Money = -300 }, setFlags = { diabetic = true }, feedText = "Diabetes diagnosis. Diet and exercise are key." },
			{ text = "High blood pressure", effects = { Health = -8, Happiness = -5, Money = -100 }, setFlags = { hypertension = true }, feedText = "High blood pressure. Medication and monitoring." },
			{ text = "Autoimmune condition", effects = { Health = -15, Happiness = -12, Money = -500 }, setFlags = { autoimmune = true }, feedText = "Autoimmune disorder. Managing flare-ups." },
			{ text = "Arthritis - joint pain", effects = { Health = -10, Happiness = -8 }, setFlags = { arthritis = true }, feedText = "Arthritis. Movement is harder now." },
			{ text = "Asthma - breathing issues", effects = { Health = -8, Happiness = -5, Money = -150 }, setFlags = { asthma = true }, feedText = "Asthma diagnosis. Inhaler is your new friend." },
		},
	},
	{
		id = "illness_cancer_scare",
		title = "The Scary Diagnosis",
		emoji = "🎗️",
		text = "You've found a concerning lump or had abnormal test results.",
		question = "What's the outcome?",
		minAge = 25, maxAge = 90,
		baseChance = 0.05,
		cooldown = 10,
		category = "illness",

		choices = {
			{ text = "False alarm - benign", effects = { Happiness = 15, Health = 3 }, feedText = "Thank goodness, it was benign. What a relief!" },
			{ text = "Early stage - treatable", effects = { Health = -20, Happiness = -15, Money = -10000 }, setFlags = { cancer_survivor = true }, feedText = "Cancer caught early. Treatment is working." },
			{ text = "Serious but fighting", effects = { Health = -40, Happiness = -25, Money = -25000 }, setFlags = { battling_cancer = true }, feedText = "Serious diagnosis. The fight of your life." },
			{ text = "Need more tests - waiting", effects = { Happiness = -15, Health = -5 }, setFlags = { health_scare = true }, feedText = "The waiting for results is agonizing." },
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
		baseChance = 0.3,
		cooldown = 2,
		requiresFlags = { hospitalized = true },
		category = "recovery",

		choices = {
			{ text = "Making great progress!", effects = { Health = 15, Happiness = 10 }, feedText = "Recovery is going well! Almost back to normal." },
			{ text = "Slower than expected", effects = { Health = 5, Happiness = -5 }, feedText = "Recovery is taking longer than hoped." },
			{ text = "Complications arose", effects = { Health = -10, Happiness = -10, Money = -1000 }, feedText = "Setback in recovery. More treatment needed." },
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
		text = "You need surgery for your condition.",
		question = "How does the surgery go?",
		minAge = 5, maxAge = 90,
		baseChance = 0.5,
		cooldown = 3,
		requiresFlags = { needs_surgery = true },
		category = "recovery",

		choices = {
			{ text = "Successful - smooth recovery ahead", effects = { Health = 10, Happiness = 8, Money = -5000 }, feedText = "Surgery was a success! Now to recover." },
			{ text = "Minor complications but okay", effects = { Health = 5, Happiness = 2, Money = -7000 }, feedText = "Some complications but you pulled through." },
			{ text = "Long surgery but successful", effects = { Health = 8, Happiness = 5, Money = -8000 }, feedText = "Marathon surgery but it worked!" },
			{ text = "Need follow-up procedures", effects = { Health = 3, Happiness = -5, Money = -3000 }, setFlags = { needs_more_surgery = true }, feedText = "More procedures needed. Not done yet." },
		},
		onComplete = function(state)
			state.Flags = state.Flags or {}
			state.Flags.needs_surgery = nil
		end,
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ADDITIONAL RANDOM LIFE EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "pet_adoption",
		title = "Furry Friend",
		emoji = "🐕",
		text = "You're thinking about getting a pet!",
		question = "What kind of pet?",
		minAge = 10, maxAge = 80,
		baseChance = 0.2,
		cooldown = 5,

		choices = {
			{ text = "Adopt a dog", effects = { Happiness = 15, Money = -500, Health = 3 }, setFlags = { has_pet = true, has_dog = true }, feedText = "You adopted a dog! Best friend for life." },
			{ text = "Adopt a cat", effects = { Happiness = 12, Money = -300 }, setFlags = { has_pet = true, has_cat = true }, feedText = "You got a cat! Independent but loving." },
			{ text = "Get a small pet (hamster, fish, etc.)", effects = { Happiness = 8, Money = -100 }, setFlags = { has_pet = true }, feedText = "You got a small pet! Easy to care for." },
			{ text = "Not ready for a pet yet", effects = { Happiness = -2 }, feedText = "Maybe someday. Pets are a big responsibility." },
		},
	},
	{
		id = "pet_loss",
		title = "Goodbye, Friend",
		emoji = "🌈",
		text = "Your beloved pet has passed away.",
		question = "How do you cope?",
		minAge = 10, maxAge = 90,
		baseChance = 0.15,
		cooldown = 10,
		requiresFlags = { has_pet = true },

		choices = {
			{ text = "Devastated - they were family", effects = { Happiness = -20, Health = -5 }, feedText = "Losing your pet is heartbreaking." },
			{ text = "Grateful for the time together", effects = { Happiness = -10 }, feedText = "You cherish the memories you shared." },
			{ text = "Adopt another pet soon", effects = { Happiness = -8, Money = -300 }, setFlags = { has_pet = true }, feedText = "You opened your heart to another pet." },
			{ text = "Not getting another pet", effects = { Happiness = -12 }, feedText = "Too painful. You can't go through this again.", onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.has_pet = nil
				state.Flags.has_dog = nil
				state.Flags.has_cat = nil
			end },
		},
	},
	{
		id = "home_invasion",
		title = "Break-In!",
		emoji = "🚨",
		text = "Someone broke into your home!",
		question = "What happened?",
		minAge = 18, maxAge = 90,
		baseChance = 0.05,
		cooldown = 10,
		category = "crime",

		choices = {
			{ text = "Caught them in the act - fight!", effects = { Health = -15, Happiness = -10 }, setFlags = { home_invasion = true, self_defense = true }, feedText = "You confronted the intruder. Got hurt but they fled." },
			{ text = "They stole valuables while you slept", effects = { Money = -5000, Happiness = -15 }, setFlags = { burglarized = true }, feedText = "They took everything valuable. You feel violated." },
			{ text = "Alarm scared them off", effects = { Happiness = -8 }, feedText = "The alarm worked. Nothing taken but you're shaken." },
			{ text = "Hid and called police", effects = { Happiness = -12 }, setFlags = { home_invasion = true }, feedText = "Police caught them. You're safe but traumatized." },
		},
	},
	{
		id = "lawsuit",
		title = "Legal Trouble",
		emoji = "⚖️",
		text = "You're involved in a lawsuit!",
		question = "What's the situation?",
		minAge = 18, maxAge = 80,
		baseChance = 0.1,
		cooldown = 8,

		choices = {
			{ text = "You're suing someone - and won!", effects = { Money = 15000, Happiness = 10, Smarts = 2 }, feedText = "You won your lawsuit! Justice served." },
			{ text = "You're suing - but lost", effects = { Money = -5000, Happiness = -10 }, feedText = "Lost the case. Expensive and disappointing." },
			{ text = "Being sued - you won", effects = { Money = -2000, Happiness = 5 }, feedText = "You defended yourself successfully!" },
			{ text = "Being sued - you lost", effects = { Money = -20000, Happiness = -20 }, setFlags = { lawsuit_lost = true }, feedText = "You lost the lawsuit. Devastating." },
			{ text = "Settled out of court", effects = { Money = -5000, Happiness = -3 }, feedText = "Settled to avoid trial. Could be worse." },
		},
	},
	{
		id = "natural_disaster",
		title = "Natural Disaster!",
		emoji = "🌪️",
		text = "A natural disaster struck your area!",
		question = "How bad was the damage?",
		minAge = 5, maxAge = 95,
		baseChance = 0.05,
		cooldown = 15,
		category = "disaster",

		choices = {
			{ text = "Home destroyed - lost everything", effects = { Money = -30000, Happiness = -25, Health = -5 }, setFlags = { disaster_survivor = true, homeless = true }, feedText = "Everything is gone. Starting over." },
			{ text = "Significant damage but insured", effects = { Money = -5000, Happiness = -15 }, setFlags = { disaster_survivor = true }, feedText = "Major damage but insurance is covering most of it." },
			{ text = "Minor damage - lucky", effects = { Money = -1000, Happiness = -5 }, feedText = "You got off relatively easy." },
			{ text = "Completely untouched", effects = { Happiness = 5 }, feedText = "Your home was spared. Others weren't as lucky." },
			{ text = "Helped rescue others - hero", effects = { Health = -5, Happiness = 15 }, setFlags = { local_hero = true }, feedText = "You helped save lives. True heroism." },
		},
	},
	{
		id = "scam_victim",
		title = "Scammed!",
		emoji = "🎭",
		text = "You fell for a scam!",
		question = "What kind of scam was it?",
		minAge = 16, maxAge = 90,
		baseChance = 0.1,
		cooldown = 5,

		choices = {
			{ text = "Online shopping scam", effects = { Money = -500, Happiness = -8 }, feedText = "That website was fake. Money gone." },
			{ text = "Investment fraud", effects = { Money = -10000, Happiness = -20, Smarts = -2 }, setFlags = { scam_victim = true }, feedText = "Lost thousands to a Ponzi scheme." },
			{ text = "Romance scam", effects = { Money = -5000, Happiness = -25 }, setFlags = { heartbroken = true }, feedText = "They never loved you. Just wanted your money." },
			{ text = "Identity theft", effects = { Money = -3000, Happiness = -15 }, setFlags = { identity_stolen = true }, feedText = "Your identity was stolen. Nightmare to fix." },
			{ text = "Caught it in time", effects = { Money = -100, Happiness = -5, Smarts = 3 }, feedText = "You caught on before losing much. Lesson learned." },
		},
	},
	{
		id = "talent_discovered",
		title = "Hidden Talent!",
		emoji = "✨",
		text = "You discovered you have a hidden talent!",
		question = "What is it?",
		minAge = 8, maxAge = 70,
		baseChance = 0.15,
		cooldown = 5,

		choices = {
			{ text = "Musical ability", effects = { Happiness = 12, Smarts = 3 }, setFlags = { musical_talent = true }, hintCareer = "entertainment", feedText = "You can really sing/play! Natural talent!" },
			{ text = "Artistic skill", effects = { Happiness = 10, Smarts = 2 }, setFlags = { artistic_talent = true }, hintCareer = "creative", feedText = "You're a natural artist!" },
			{ text = "Athletic ability", effects = { Happiness = 10, Health = 5 }, setFlags = { athletic_talent = true }, hintCareer = "sports", feedText = "You've got serious athletic potential!" },
			{ text = "Writing ability", effects = { Happiness = 8, Smarts = 4 }, setFlags = { writing_talent = true }, hintCareer = "writing", feedText = "You have a gift with words!" },
			{ text = "Leadership qualities", effects = { Happiness = 8, Smarts = 3 }, setFlags = { natural_leader = true }, hintCareer = "business", feedText = "People naturally follow your lead!" },
		},
	},
	{
		id = "unexpected_visitor",
		title = "Surprise Visit!",
		emoji = "🚪",
		text = "Someone showed up unexpectedly at your door!",
		question = "Who is it?",
		minAge = 15, maxAge = 85,
		baseChance = 0.2,
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
		cooldown = 5,

		choices = {
			{ text = "Found a valuable item", effects = { Money = 2000, Happiness = 10 }, feedText = "You found something valuable! What luck!" },
			{ text = "Random act of generosity", effects = { Happiness = 15 }, feedText = "Someone did something incredibly kind for you!" },
			{ text = "Perfect timing saved you", effects = { Happiness = 10, Health = 5 }, feedText = "Right place, right time. Avoided disaster." },
			{ text = "Connection led to opportunity", effects = { Happiness = 10, Smarts = 3 }, setFlags = { lucky_network = true }, feedText = "A chance meeting opened new doors!" },
		},
	},
	{
		id = "public_embarrassment",
		title = "Public Humiliation",
		emoji = "😳",
		text = "Something incredibly embarrassing happened to you in public!",
		question = "What happened?",
		minAge = 10, maxAge = 80,
		baseChance = 0.15,
		cooldown = 3,

		choices = {
			{ text = "Wardrobe malfunction", effects = { Happiness = -10, Looks = -3 }, feedText = "Everyone saw... everything. Mortifying." },
			{ text = "Said something embarrassing", effects = { Happiness = -8, Smarts = -2 }, feedText = "You can't believe you said that. Cringe." },
			{ text = "Tripped and fell spectacularly", effects = { Happiness = -7, Health = -3 }, feedText = "Epic fall. Someone definitely recorded it." },
			{ text = "Got caught in a lie publicly", effects = { Happiness = -12 }, setFlags = { reputation_damaged = true }, feedText = "Your lie was exposed. Reputation hit." },
			{ text = "Laughed it off - no big deal", effects = { Happiness = 5 }, setFlags = { thick_skinned = true }, feedText = "You didn't let it bother you. Strong move." },
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
		baseChance = 0.8, -- High chance if triggered
		cooldown = 5,
		-- Only triggers for people with bum_life flag or very low money
		requiresFlags = { bum_life = true },
		blockedByFlags = { homeless = true },

		choices = {
			{ 
				text = "Beg family for help", 
				effects = { Happiness = -8 }, 
				feedText = "You swallowed your pride and asked family for help.",
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
		baseChance = 0.9,
		cooldown = 1,
		requiresFlags = { homeless = true },

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
						state.InJail = true
						state.JailYearsLeft = math.random(1, 3)
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
		baseChance = 0.2,
		cooldown = 10,
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
}

return Random
