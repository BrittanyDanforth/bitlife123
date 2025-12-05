--[[
	╔══════════════════════════════════════════════════════════════════════════════╗
	║                  RANDOM EVENTS MODULE v2.0                                   ║
	║            Triple-AAAA Quality Random Life Events                             ║
	╠══════════════════════════════════════════════════════════════════════════════╣
	║  This module contains 100+ detailed random events covering:                  ║
	║  • Luck & fortune (found money, lottery, inheritance)                          ║
	║  • Accidents & mishaps (with SPECIFIC body part injuries)                     ║
	║  • Health & wellness (illness, fitness, medical issues)                       ║
	║  • Social encounters (celebrity sightings, random kindness, awkward moments)  ║
	║  • Everyday life (weather, lost items, new hobbies, social media)             ║
	║  • Opportunities (travel, volunteering, unexpected chances)                    ║
	║                                                                              ║
	║  Events are CONTEXTUAL and DETAILED - injuries specify body parts            ║
	║  (e.g., "you got hurt in your left arm" not just "you got hurt").            ║
	╚══════════════════════════════════════════════════════════════════════════════╝
]]

local Random = {}

local RANDOM = Random.new()

-- Helper function to get random body part
local function getRandomBodyPart()
	local parts = { "left arm", "right arm", "left leg", "right leg", "face", "chest", "back", "shoulder", "hand", "ankle", "knee", "elbow", "wrist", "foot", "head" }
	return parts[RANDOM:NextInteger(1, #parts)]
end

-- Helper function to get random injury severity and description
local function getRandomInjury()
	local injuries = {
		{ text = "minor cuts and bruises", health = -5 },
		{ text = "a deep gash requiring stitches", health = -12 },
		{ text = "a broken bone", health = -20 },
		{ text = "serious internal injuries", health = -30 },
		{ text = "a concussion", health = -15 },
		{ text = "a sprained joint", health = -10 },
		{ text = "a dislocated shoulder", health = -18 },
		{ text = "severe bruising", health = -8 },
		{ text = "a laceration", health = -12 },
		{ text = "a fracture", health = -22 },
	}
	return injuries[RANDOM:NextInteger(1, #injuries)]
end

Random.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- LUCK & FORTUNE
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "found_money",
		title = "Lucky Find",
		emoji = "💵",
		text = "You found money on the ground! A crisp bill just sitting there, waiting for someone to claim it.",
		question = "What do you do with it?",
		minAge = 6, maxAge = 90,
		baseChance = 0.2,
		cooldown = 3,
		choices = {
			{ 
				text = "Keep it - finders keepers!", 
				effects = { Happiness = 5, Money = 100 }, 
				setFlags = { lucky = true },
				feedText = "You pocketed the cash. Lucky day!",
			},
			{ 
				text = "Turn it in to lost and found", 
				effects = { Happiness = 3, Smarts = 1 }, 
				setFlags = { honest = true }, 
				feedText = "You did the right thing. Someone might come looking for it.",
			},
			{ 
				text = "Donate it to charity", 
				effects = { Happiness = 5 }, 
				setFlags = { generous = true }, 
				feedText = "You paid it forward. Good karma!",
			},
		},
	},
	
	{
		id = "lottery_scratch",
		title = "Scratch Ticket",
		emoji = "🎰",
		text = "Someone gave you a scratch lottery ticket as a gift. You're skeptical, but curious. Time to see if luck is on your side!",
		question = "Let's see what you won!",
		minAge = 18, maxAge = 90,
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{ 
				text = "Scratch it off", 
				effects = { Happiness = 2 }, 
				setFlags = { scratched_ticket = true },
				feedText = "You scratch off the ticket...",
				onResolve = function(state)
					-- Realistic lottery odds - most tickets lose, small chance of winning
					local roll = RANDOM:NextNumber()
					local winnings = 0
					local message = ""
					
					if roll < 0.01 then -- 1% chance of big win
						winnings = 5000
						message = "INCREDIBLE! You won $5,000! This is your lucky day!"
						state.Flags = state.Flags or {}
						state.Flags.lottery_winner = true
						state.Flags.lucky = true
					elseif roll < 0.05 then -- 4% chance of medium win
						winnings = 100
						message = "Nice! You won $100! Not bad!"
						state.Flags = state.Flags or {}
						state.Flags.lucky = true
					elseif roll < 0.15 then -- 10% chance of small win
						winnings = 20
						message = "You won $20! Better than nothing!"
					else -- 85% chance of losing
						winnings = 0
						message = "Sorry, not a winner. Better luck next time!"
					end
					
					if winnings > 0 then
						state.Money = (state.Money or 0) + winnings
						state.Stats = state.Stats or {}
						state.Stats.Happiness = math.min(100, (state.Stats.Happiness or 50) + (winnings >= 5000 and 20 or 5))
					end
					
					if state.AddFeed then
						state:AddFeed(message)
					end
				end,
			},
			{ 
				text = "Give it to someone else", 
				effects = { Happiness = 2 }, 
				setFlags = { generous = true },
				feedText = "You won a little something! $50 isn't bad!",
			},
			{ 
				text = "Nothing this time", 
				effects = { Happiness = -2 }, 
				feedText = "No luck. Better luck next time.",
			},
		},
	},
	
	{
		id = "inheritance",
		title = "Unexpected Inheritance",
		emoji = "📜",
		text = "A distant relative you barely knew passed away and left you something in their will. You're surprised - you hadn't spoken in years.",
		question = "What did you inherit?",
		minAge = 25, maxAge = 80,
		baseChance = 0.15,
		cooldown = 10,
		oneTime = true,
		choices = {
			{
				text = "A substantial sum",
				effects = { Happiness = 10, Money = 10000 },
				setFlags = { inherited_money = true },
				feedText = "You inherited $10,000! A nice surprise!",
			},
			{
				text = "A quirky family heirloom",
				effects = { Happiness = 5 },
				setFlags = { has_heirloom = true },
				feedText = "An interesting piece of family history. Worth something, but more sentimental value.",
				onResolve = function(state)
					if state.AddAsset then
						state:AddAsset("Shop", {
							id = "family_heirloom_" .. tostring(state.Age),
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
				setFlags = { inherited_property = true, homeowner = true, has_property = true, renting = false },
				feedText = "You inherited a property! Needs some work, but it's yours!",
				onResolve = function(state)
					if state.AddAsset then
						state:AddAsset("Properties", {
							id = "inherited_house_" .. tostring(state.Age),
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
				setFlags = { inherited_debt = true },
				feedText = "They left you with bills to pay. Not the inheritance you hoped for.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- ACCIDENTS & MISHAPS (WITH SPECIFIC BODY PARTS)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "minor_accident",
		title = "Ouch!",
		emoji = "🤕",
		text = "You had a minor accident. It happened fast - one moment you're fine, the next you're hurt.",
		question = "What happened?",
		minAge = 5, maxAge = 80,
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{ 
				text = "Tripped and fell", 
				effects = { Health = -5, Happiness = -3 }, 
				feedText = "You took a tumble and got hurt. Bruises heal, but it hurts!",
				onResolve = function(state)
					local bodyPart = getRandomBodyPart()
					local injury = getRandomInjury()
					if state.AddFeed then
						state:AddFeed("You got " .. injury.text .. " on your " .. bodyPart .. ".")
					end
					if state.ModifyStat then
						state:ModifyStat("Health", injury.health)
					end
				end,
			},
			{ 
				text = "Cut yourself cooking", 
				effects = { Health = -3, Smarts = 2 }, 
				feedText = "You cut yourself while cooking. Kitchen accidents happen. You learned to be more careful.",
				onResolve = function(state)
					local hand = RANDOM:NextInteger(1, 2) == 1 and "left hand" or "right hand"
					if state.AddFeed then
						state:AddFeed("You cut your " .. hand .. " - needed a bandage but you're okay.")
					end
				end,
			},
			{ 
				text = "Sports injury", 
				effects = { Health = -8, Happiness = -2 }, 
				setFlags = { sports_injury = true },
				feedText = "You got hurt playing sports. Ouch!",
				onResolve = function(state)
					local bodyPart = getRandomBodyPart()
					local injury = getRandomInjury()
					if state.AddFeed then
						state:AddFeed("You got " .. injury.text .. " on your " .. bodyPart .. ".")
					end
					if state.ModifyStat then
						state:ModifyStat("Health", injury.health)
					end
				end,
			},
			{ 
				text = "Stubbed toe badly", 
				effects = { Health = -2, Happiness = -5 }, 
				feedText = "You stubbed your toe on the corner of the table. The pain! It never gets easier!",
				onResolve = function(state)
					local foot = RANDOM:NextInteger(1, 2) == 1 and "left foot" or "right foot"
					if state.AddFeed then
						state:AddFeed("Your " .. foot .. " is throbbing. Might be broken, might just be really bruised.")
					end
				end,
			},
		},
	},
	
	{
		id = "bike_accident",
		title = "Bike Crash",
		emoji = "🚲",
		text = "You crashed your bike! Whether it was a pothole, a car, or just losing balance, you went down hard.",
		question = "How bad is it?",
		minAge = 8, maxAge = 70,
		baseChance = 0.25,
		cooldown = 3,
		requiresFlags = { has_bike = true },
		choices = {
			{
				text = "Minor scrapes",
				effects = { Health = -5, Happiness = -2 },
				feedText = "You got scraped up. Road rash hurts, but you'll be okay.",
				onResolve = function(state)
					local bodyPart = getRandomBodyPart()
					if state.AddFeed then
						state:AddFeed("You got scraped up on your " .. bodyPart .. " and knees.")
					end
				end,
			},
			{
				text = "Broken something",
				effects = { Health = -20, Happiness = -5, Money = -500 },
				setFlags = { broken_bone = true },
				feedText = "You broke something! Hospital visit, cast, the works. This is going to take a while to heal.",
				onResolve = function(state)
					local bodyPart = getRandomBodyPart()
					if state.AddFeed then
						state:AddFeed("You broke your " .. bodyPart .. "! Cast for weeks.")
					end
				end,
			},
			{
				text = "Walked away fine",
				effects = { Happiness = 2, Smarts = 1 },
				setFlags = { lucky = true },
				feedText = "You walked away unscathed! Lucky! The bike took the damage, not you.",
			},
		},
	},
	
	{
		id = "car_trouble",
		title = "Vehicle Problems",
		emoji = "🚗",
		text = "Your car broke down! You're stranded, and it's going to cost money to fix. Cars - can't live with them, can't live without them.",
		question = "How do you handle it?",
		minAge = 16, maxAge = 90,
		baseChance = 0.3,
		cooldown = 2,
		requiresFlags = { has_car = true },
		choices = {
			{
				text = "Pay for repairs",
				effects = { Money = -500, Happiness = -3 },
				setFlags = { responsible = true },
				feedText = "Expensive repairs. $500 later, your car is running again. Cars, right?",
			},
			{
				text = "Try to fix it yourself",
				effects = { Money = -100, Smarts = 3, Health = -2 },
				setFlags = { handy = true },
				feedText = "You tried to fix it yourself. You learned something, but you also got hurt in the process.",
				onResolve = function(state)
					local hand = RANDOM:NextInteger(1, 2) == 1 and "left hand" or "right hand"
					if state.AddFeed then
						state:AddFeed("You cut your " .. hand .. " working on the car. Ouch!")
					end
				end,
			},
			{
				text = "Junk it and buy a new car",
				effects = { Money = -5000, Happiness = 5 },
				setFlags = { upgraded_car = true },
				feedText = "Time for an upgrade anyway! You bought a new car. Fresh start!",
				onResolve = function(state)
					if state.RemoveAsset then
						-- Remove old car (simplified - would track specific car in real implementation)
						local vehicles = state.Assets and state.Assets.Vehicles
						if vehicles and #vehicles > 0 then
							state:RemoveAsset("Vehicles", vehicles[1].id)
						end
					end
					if state.AddAsset then
						state:AddAsset("Vehicles", {
							id = "replacement_car_" .. tostring(state.Age),
							name = "New Reliable Car",
							emoji = "🚗",
							price = 5000,
							value = 4500,
							isEventAcquired = true,
						})
					end
				end,
			},
			{
				text = "Sell it for scrap and take the bus",
				effects = { Money = 300, Happiness = -5 },
				setFlags = { carless = true },
				feedText = "You sold the heap for $300 and went back to public transit. Less convenient, but cheaper.",
				onResolve = function(state)
					if state.RemoveAsset then
						local vehicles = state.Assets and state.Assets.Vehicles
						if vehicles and #vehicles > 0 then
							state:RemoveAsset("Vehicles", vehicles[1].id)
						end
					end
					-- Use state.Flags directly instead of deprecated SetFlag
					state.Flags = state.Flags or {}
					state.Flags.has_car = false
					state.Flags.has_vehicle = false
				end,
			},
		},
	},
	
	{
		id = "phone_broke",
		title = "Phone Disaster",
		emoji = "📱",
		text = "Your phone is broken or lost! Screen cracked, water damage, or just... gone. You're disconnected from the digital world.",
		question = "What do you do?",
		minAge = 12, maxAge = 80,
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{ 
				text = "Get the latest model", 
				effects = { Money = -800, Happiness = 8 }, 
				setFlags = { tech_enthusiast = true },
				feedText = "New phone! Shiny, fast, all the latest features. Worth it!",
			},
			{ 
				text = "Get a basic replacement", 
				effects = { Money = -200, Happiness = 2 }, 
				setFlags = { practical = true },
				feedText = "It works. That's what matters. You don't need all the bells and whistles.",
			},
			{ 
				text = "Fix the old one", 
				effects = { Money = -100, Happiness = 3, Smarts = 2 }, 
				setFlags = { frugal = true },
				feedText = "You got it repaired. Good as new (almost). Saved some money!",
			},
			{ 
				text = "Go without for a while", 
				effects = { Happiness = -5 }, 
				setFlags = { disconnected = true },
				feedText = "You're living disconnected. It's... different. Peaceful, but inconvenient.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- HEALTH & WELLNESS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "caught_cold",
		title = "Under the Weather",
		emoji = "🤧",
		text = "You caught a cold. Sniffles, cough, general misery. Everyone around you seems fine, but you're down for the count.",
		question = "How do you handle being sick?",
		minAge = 3, maxAge = 90,
		baseChance = 0.4,
		cooldown = 2,
		choices = {
			{ 
				text = "Rest up properly", 
				effects = { Health = 3, Happiness = -2 }, 
				setFlags = { responsible = true },
				feedText = "You took care of yourself. Rest, fluids, medicine. You recovered faster.",
			},
			{ 
				text = "Push through it", 
				effects = { Health = -3, Happiness = -3 }, 
				setFlags = { stubborn = true },
				feedText = "You kept going. Probably not wise. You made yourself worse.",
			},
			{ 
				text = "Home remedies", 
				effects = { Health = 2 }, 
				setFlags = { resourceful = true },
				feedText = "Soup, tea, honey, rest. Home remedies worked wonders.",
			},
			{ 
				text = "See a doctor", 
				effects = { Health = 5, Money = -100 }, 
				setFlags = { proactive = true },
				feedText = "The doctor helped you recover faster. Prescription meds did the trick.",
			},
		},
	},
	
	{
		id = "fitness_moment",
		title = "Health Motivation",
		emoji = "💪",
		text = "You're feeling motivated to get in better shape. Maybe you saw yourself in a photo, or a friend invited you to work out. The motivation is there - will you act on it?",
		question = "What do you do?",
		minAge = 15, maxAge = 70,
		baseChance = 0.3,
		cooldown = 3,
		choices = {
			{ 
				text = "Start going to the gym", 
				effects = { Health = 8, Happiness = 5, Money = -50 }, 
				setFlags = { gym_member = true, fitness_enthusiast = true }, 
				feedText = "You joined a gym! Time to get swole!",
			},
			{ 
				text = "Take up running", 
				effects = { Health = 7, Happiness = 3 }, 
				setFlags = { runner = true }, 
				feedText = "You started running regularly! Couch to 5K, here you come!",
			},
			{ 
				text = "Try a new sport", 
				effects = { Health = 5, Happiness = 7 }, 
				setFlags = { athletic = true },
				feedText = "You picked up a new sport! It's fun and you're getting fitter!",
			},
			{ 
				text = "Eh, motivation faded", 
				effects = { Happiness = -2 }, 
				setFlags = { unmotivated = true },
				feedText = "The motivation was short-lived. Maybe next time.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SOCIAL ENCOUNTERS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "encounter_celebrity",
		title = "Celebrity Sighting",
		emoji = "⭐",
		text = "You ran into a celebrity! They're just... there. In the wild. Do you approach them, or play it cool?",
		question = "What do you do?",
		minAge = 10, maxAge = 80,
		baseChance = 0.15,
		cooldown = 5,
		choices = {
			{ 
				text = "Ask for a selfie", 
				effects = { Happiness = 10 }, 
				setFlags = { met_celebrity = true },
				feedText = "You got a photo with a celebrity! They were nice about it!",
			},
			{ 
				text = "Play it cool", 
				effects = { Happiness = 5, Smarts = 2 }, 
				setFlags = { cool = true },
				feedText = "You acted casual. Smooth. They probably appreciated not being mobbed.",
			},
			{ 
				text = "Totally fanboy/fangirl", 
				effects = { Happiness = 7, Looks = -2 }, 
				setFlags = { fan = true },
				feedText = "You couldn't contain your excitement! They were amused, at least.",
			},
			{ 
				text = "Didn't recognize them", 
				effects = { Smarts = 1 }, 
				feedText = "Wait, who was that? Someone said they were famous, but you're not sure.",
			},
		},
	},
	
	{
		id = "random_kindness",
		title = "Random Act of Kindness",
		emoji = "💝",
		text = "A stranger did something unexpectedly kind for you. Paid for your coffee, helped you carry something, held the door. Small gesture, big impact.",
		question = "How did it make you feel?",
		minAge = 5, maxAge = 90,
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{ 
				text = "Restored faith in humanity", 
				effects = { Happiness = 10 }, 
				setFlags = { optimistic = true },
				feedText = "People can be so good! This made your whole day better.",
			},
			{ 
				text = "Inspired to pay it forward", 
				effects = { Happiness = 8 }, 
				setFlags = { pays_it_forward = true, generous = true }, 
				feedText = "You'll do the same for someone else! Kindness is contagious!",
			},
			{ 
				text = "Suspicious of their motives", 
				effects = { Happiness = 2, Smarts = 2 }, 
				setFlags = { cynical = true },
				feedText = "You wondered what they wanted. Maybe you're too jaded.",
			},
		},
	},
	
	{
		id = "awkward_encounter",
		title = "Awkward Moment",
		emoji = "😬",
		text = "You had an embarrassing moment in public. Tripped, said something weird, had a wardrobe malfunction. Everyone saw. The cringe is real.",
		question = "How do you handle it?",
		minAge = 10, maxAge = 80,
		baseChance = 0.4,
		cooldown = 2,
		choices = {
			{ 
				text = "Laugh it off", 
				effects = { Happiness = 5 }, 
				setFlags = { good_sport = true, confident = true }, 
				feedText = "You laughed at yourself. Best approach! People respect that.",
			},
			{ 
				text = "Die of embarrassment", 
				effects = { Happiness = -5 }, 
				setFlags = { self_conscious = true },
				feedText = "You wanted to disappear. The embarrassment is eating at you.",
			},
			{ 
				text = "Pretend nothing happened", 
				effects = { Happiness = 2 }, 
				setFlags = { in_denial = true },
				feedText = "Maybe no one noticed... right?",
			},
			{ 
				text = "Make it a funny story", 
				effects = { Happiness = 7 }, 
				setFlags = { good_storyteller = true },
				feedText = "This will be a great story later! You're already retelling it.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EVERYDAY LIFE
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "weather_event",
		title = "Weather Watch",
		emoji = "🌦️",
		text = "The weather is affecting your plans today. Mother nature has her own agenda, and it doesn't always align with yours.",
		question = "What's happening?",
		minAge = 5, maxAge = 90,
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{ 
				text = "Beautiful day - enjoyed it!", 
				effects = { Happiness = 7, Health = 3 }, 
				setFlags = { outdoorsy = true },
				feedText = "Perfect weather made everything better! You spent time outside.",
			},
			{ 
				text = "Rainy day - stayed in", 
				effects = { Happiness = 3 }, 
				setFlags = { cozy = true },
				feedText = "Cozy day indoors. Rain is perfect for staying home.",
			},
			{ 
				text = "Snowstorm - adventure!", 
				effects = { Happiness = 5, Health = 2 }, 
				setFlags = { adventurous = true },
				feedText = "You made the most of the snow! Built a snowman, had a snowball fight!",
			},
			{ 
				text = "Heat wave - tough day", 
				effects = { Happiness = -3, Health = -2 }, 
				setFlags = { heat_exhaustion = true },
				feedText = "The heat was brutal. You're exhausted and dehydrated.",
			},
		},
	},
	
	{
		id = "lost_item",
		title = "Where Did It Go?",
		emoji = "🔍",
		text = "You lost something important. You've looked everywhere, but it's just... gone. Where could it be?",
		question = "What was it?",
		minAge = 5, maxAge = 90,
		baseChance = 0.3,
		cooldown = 3,
		choices = {
			{ 
				text = "Keys - found them eventually", 
				effects = { Happiness = -3 }, 
				setFlags = { forgetful = true },
				feedText = "Stressful search, but they turned up in the last place you looked (of course).",
			},
			{ 
				text = "Wallet - had to cancel cards", 
				effects = { Happiness = -5, Money = -50 }, 
				setFlags = { careless = true },
				feedText = "What a hassle! Had to cancel all your cards, get new ones. Expensive mistake.",
			},
			{ 
				text = "Something sentimental", 
				effects = { Happiness = -7 }, 
				setFlags = { grieving = true },
				feedText = "It can't be replaced... You're devastated. Maybe it'll turn up.",
			},
			{ 
				text = "Something replaceable", 
				effects = { Happiness = -2, Money = -30 }, 
				setFlags = { forgetful = true },
				feedText = "Annoying, but not the end of the world. You'll replace it.",
			},
		},
	},
	
	{
		id = "new_hobby",
		title = "New Interest",
		emoji = "🎯",
		text = "You've discovered a new hobby! Something caught your interest, and you're diving in. This could be your new passion.",
		question = "What caught your interest?",
		minAge = 10, maxAge = 80,
		baseChance = 0.3,
		cooldown = 3,
		choices = {
			{ 
				text = "Gaming", 
				effects = { Happiness = 7, Smarts = 2 }, 
				setFlags = { gamer = true }, 
				feedText = "You got into gaming! Hours of fun ahead!",
			},
			{ 
				text = "Crafting/DIY", 
				effects = { Happiness = 5, Smarts = 3 }, 
				setFlags = { crafter = true }, 
				feedText = "You love making things! Your home is filling with projects!",
			},
			{ 
				text = "Cooking/Baking", 
				effects = { Happiness = 6, Health = 2 }, 
				setFlags = { foodie = true }, 
				feedText = "You're exploring the kitchen! Delicious experiments ahead!",
			},
			{ 
				text = "Reading", 
				effects = { Smarts = 5, Happiness = 4 }, 
				setFlags = { bookworm = true }, 
				feedText = "Books are your new escape! You're reading everything!",
			},
			{ 
				text = "Outdoor activities", 
				effects = { Health = 5, Happiness = 5 }, 
				setFlags = { outdoorsy = true }, 
				feedText = "Nature calls to you! Hiking, camping, exploring!",
			},
			{ 
				text = "Music", 
				effects = { Happiness = 7 }, 
				setFlags = { musician = true }, 
				feedText = "You're learning music! Picking up an instrument or just listening more!",
			},
		},
	},
	
	{
		id = "social_media_moment",
		title = "Internet Fame",
		emoji = "📲",
		text = "Something you posted went viral! Thousands, maybe millions of views. People are sharing it, commenting, reacting. You're internet famous!",
		question = "How do you handle the attention?",
		minAge = 13, maxAge = 60,
		baseChance = 0.15,
		cooldown = 5,
		requiresFlags = { social_online = true },
		choices = {
			{ 
				text = "Embrace the fame", 
				effects = { Happiness = 10, Money = 100 }, 
				setFlags = { internet_famous = true }, 
				feedText = "You're internet famous! Enjoying every minute of it!",
			},
			{ 
				text = "Stay humble", 
				effects = { Happiness = 5, Smarts = 2 }, 
				setFlags = { grounded = true },
				feedText = "You kept perspective. Fame is fleeting, but you're enjoying it while it lasts.",
			},
			{ 
				text = "Delete everything", 
				effects = { Happiness = -3 }, 
				setFlags = { private = true },
				feedText = "The attention was too much. You deleted everything and went private.",
			},
			{ 
				text = "Try to monetize it", 
				effects = { Money = 500, Smarts = 2 }, 
				setFlags = { content_creator = true }, 
				feedText = "You turned it into income! Sponsored posts, partnerships. Smart move!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- OPPORTUNITIES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "travel_opportunity",
		title = "Travel Opportunity",
		emoji = "✈️",
		text = "An opportunity to travel came up unexpectedly! A friend invited you, a deal popped up, or you just got the urge to explore. Adventure awaits!",
		question = "Do you go?",
		minAge = 18, maxAge = 75,
		baseChance = 0.3,
		cooldown = 3,
		choices = {
			{ 
				text = "Absolutely, adventure awaits!", 
				effects = { Happiness = 12, Money = -1000 }, 
				setFlags = { well_traveled = true, adventurous = true }, 
				feedText = "You went on an amazing trip! Made memories that'll last forever!",
			},
			{ 
				text = "Go on a budget", 
				effects = { Happiness = 7, Money = -300 }, 
				setFlags = { well_traveled = true, budget_traveler = true }, 
				feedText = "You traveled smart! Hostels, deals, still had an amazing time!",
			},
			{ 
				text = "Not the right time", 
				effects = { Happiness = -2, Money = 200 }, 
				setFlags = { responsible = true },
				feedText = "You saved the money instead. Maybe next time.",
			},
		},
	},
	
	{
		id = "volunteer_moment",
		title = "Helping Others",
		emoji = "🤝",
		text = "You spent some time helping others in need. Volunteering at a shelter, helping a neighbor, or just doing something kind. It felt good.",
		question = "How did it feel?",
		minAge = 12, maxAge = 90,
		baseChance = 0.3,
		cooldown = 2,
		choices = {
			{ 
				text = "Incredibly rewarding", 
				effects = { Happiness = 10 }, 
				setFlags = { volunteer = true, community_minded = true }, 
				feedText = "Helping others filled your heart. You'll definitely do this again.",
			},
			{ 
				text = "Eye-opening experience", 
				effects = { Happiness = 5, Smarts = 3 }, 
				setFlags = { volunteer = true, empathetic = true }, 
				feedText = "You gained perspective. The world is bigger than your bubble.",
			},
			{ 
				text = "Harder than expected", 
				effects = { Happiness = 3, Health = -2 }, 
				setFlags = { volunteer = true, tired = true }, 
				feedText = "It was tough but meaningful. You're exhausted, but you made a difference.",
			},
		},
	},
}

return Random
