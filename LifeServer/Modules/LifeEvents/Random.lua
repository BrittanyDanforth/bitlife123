-- LifeEvents/Random.lua
-- Random life events that can happen at various ages
-- These provide variety when no specific stage events trigger

local RandomEvents = {}

RandomEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════
	-- EVERYDAY LIFE
	-- ══════════════════════════════════════════════════════════════════════
	
	{
		id = "random_found_money",
		title = "Lucky Find",
		emoji = "💵",
		category = "luck",
		text = "You found some money on the ground!",
		question = "What do you do with it?",
		minAge = 5, maxAge = 80,
		baseChance = 0.3,
		cooldown = 5,
		choices = {
			{
				text = "Keep it",
				effects = { Money = { 20, 100 }, Happiness = 5 },
				feed = "You pocketed some found money. Finders keepers!",
			},
			{
				text = "Turn it in to lost & found",
				effects = { Happiness = 3 },
				setFlags = { honest = true },
				feed = "You turned in the money. Good karma!",
			},
			{
				text = "Donate it",
				effects = { Happiness = 8 },
				setFlags = { charitable = true },
				feed = "You donated the found money to charity.",
			},
		},
	},
	
	{
		id = "random_weather_event",
		title = "Caught in the Storm",
		emoji = "⛈️",
		category = "random",
		text = "You got caught in a sudden downpour without an umbrella.",
		question = "What do you do?",
		minAge = 8, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		choices = {
			{
				text = "Run for cover",
				effects = { Health = -2, Happiness = -1 },
				feed = "You got drenched running for shelter.",
			},
			{
				text = "Dance in the rain",
				effects = { Happiness = 8, Health = -3 },
				setFlags = { free_spirit = true },
				feed = "You danced in the rain like nobody was watching!",
			},
			{
				text = "Wait it out patiently",
				effects = { Happiness = -2 },
				feed = "You waited until the storm passed.",
			},
		},
	},
	
	{
		id = "random_lottery",
		title = "Lottery Ticket",
		emoji = "🎫",
		category = "luck",
		text = "Someone gave you a lottery ticket as a gift.",
		question = "Did you win?",
		minAge = 18, maxAge = 80,
		baseChance = 0.3,
		cooldown = 5,
		choices = {
			{
				text = "Check the numbers... WINNER!",
				effects = { Money = { 500, 5000 }, Happiness = 15 },
				feed = "You won money on a lottery ticket!",
			},
			{
				text = "Check the numbers... nothing",
				effects = { Happiness = -2 },
				feed = "The lottery ticket was a bust.",
			},
			{
				text = "Give it to someone else",
				effects = { Happiness = 3 },
				feed = "You passed on the lottery ticket.",
			},
		},
	},
	
	{
		id = "random_flat_tire",
		title = "Car Trouble",
		emoji = "🚗",
		category = "random",
		text = "Your car got a flat tire on the way somewhere important.",
		question = "How do you handle it?",
		minAge = 16, maxAge = 75,
		baseChance = 0.4,
		cooldown = 4,
		requiresFlags = { has_car = true },
		choices = {
			{
				text = "Change it yourself",
				effects = { Happiness = 3, Health = -1 },
				setFlags = { handy = true },
				feed = "You changed the tire yourself. Impressive!",
			},
			{
				text = "Call for roadside assistance",
				effects = { Money = -100, Happiness = -2 },
				feed = "You called for help with the flat tire.",
			},
			{
				text = "Ask a stranger for help",
				effects = { Happiness = { -3, 5 } },
				feed = "A kind stranger helped with your tire.",
			},
		},
	},
	
	{
		id = "random_jury_duty",
		title = "Jury Duty",
		emoji = "⚖️",
		category = "civic",
		text = "You've been summoned for jury duty.",
		question = "How do you approach it?",
		minAge = 18, maxAge = 70,
		baseChance = 0.3,
		cooldown = 10,
		choices = {
			{
				text = "Serve proudly",
				effects = { Smarts = 3, Happiness = -2 },
				setFlags = { civic_minded = true },
				feed = "You served on a jury. Civic duty fulfilled!",
			},
			{
				text = "Try to get excused",
				effects = { Happiness = 2 },
				feed = "You managed to get excused from jury duty.",
			},
			{
				text = "Get selected as foreperson",
				effects = { Smarts = 5, Happiness = 3 },
				setFlags = { leader = true },
				feed = "You led the jury deliberations.",
			},
		},
	},
	
	{
		id = "random_wrong_number",
		title = "Wrong Number",
		emoji = "📞",
		category = "random",
		text = "Someone called you by mistake, but they seem really interesting.",
		question = "Do you keep talking?",
		minAge = 16, maxAge = 60,
		baseChance = 0.2,
		cooldown = 5,
		choices = {
			{
				text = "Chat for a while",
				effects = { Happiness = 5 },
				feed = "You had an unexpectedly nice conversation with a stranger.",
			},
			{
				text = "Politely end the call",
				effects = { },
				feed = "You wished them well and hung up.",
			},
			{
				text = "They become a friend",
				effects = { Happiness = 8 },
				setFlags = { has_random_friend = true },
				feed = "An unexpected phone call led to a new friendship!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════
	-- HEALTH & ACCIDENTS
	-- ══════════════════════════════════════════════════════════════════════
	
	{
		id = "random_minor_illness",
		title = "Under the Weather",
		emoji = "🤒",
		category = "health",
		text = "You've come down with a cold.",
		question = "How do you handle it?",
		minAge = 5, maxAge = 80,
		baseChance = 0.5,
		cooldown = 2,
		choices = {
			{
				text = "Rest and recover",
				effects = { Health = 3, Happiness = -2 },
				feed = "You took time to rest and recovered fully.",
			},
			{
				text = "Push through it",
				effects = { Health = -5, Happiness = -3 },
				feed = "You tried to ignore it and felt worse.",
			},
			{
				text = "Home remedies",
				effects = { Health = 2, Happiness = 1 },
				feed = "Grandma's chicken soup worked wonders.",
			},
		},
	},
	
	{
		id = "random_minor_accident",
		title = "Oops!",
		emoji = "🤕",
		category = "health",
		text = "You had a minor accident and hurt yourself.",
		question = "What happened?",
		minAge = 5, maxAge = 75,
		baseChance = 0.3,
		cooldown = 3,
		choices = {
			{
				text = "Stubbed your toe badly",
				effects = { Health = -3, Happiness = -2 },
				feed = "You stubbed your toe. The pain was real.",
			},
			{
				text = "Tripped and fell",
				effects = { Health = -5, Happiness = -3 },
				feed = "You took a tumble and got some bruises.",
			},
			{
				text = "Cut yourself cooking",
				effects = { Health = -4 },
				feed = "A kitchen mishap left you with a cut.",
			},
		},
	},
	
	{
		id = "random_food_poisoning",
		title = "Bad Meal",
		emoji = "🤢",
		category = "health",
		text = "Something you ate didn't agree with you.",
		question = "How bad is it?",
		minAge = 10, maxAge = 80,
		baseChance = 0.3,
		cooldown = 4,
		choices = {
			{
				text = "Just some discomfort",
				effects = { Health = -3, Happiness = -2 },
				feed = "You had an upset stomach but recovered quickly.",
			},
			{
				text = "Really sick for a day",
				effects = { Health = -8, Happiness = -5 },
				feed = "Food poisoning knocked you out for a day.",
			},
			{
				text = "It was the restaurant's fault",
				effects = { Health = -5, Money = 500 },
				feed = "You got a refund after complaining about the bad food.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════
	-- SOCIAL ENCOUNTERS
	-- ══════════════════════════════════════════════════════════════════════
	
	{
		id = "random_old_friend",
		title = "Blast from the Past",
		emoji = "👋",
		category = "social",
		text = "You ran into someone you haven't seen in years.",
		question = "How does it go?",
		minAge = 18, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		choices = {
			{
				text = "Great reunion!",
				effects = { Happiness = 8 },
				feed = "You reconnected with an old friend!",
			},
			{
				text = "Awkward small talk",
				effects = { Happiness = -2 },
				feed = "The reunion was pretty awkward.",
			},
			{
				text = "They've changed completely",
				effects = { Happiness = { -3, 5 } },
				feed = "They're a completely different person now.",
			},
		},
	},
	
	{
		id = "random_celebrity_sighting",
		title = "Celebrity Encounter",
		emoji = "⭐",
		category = "social",
		text = "You spotted a celebrity in public!",
		question = "What do you do?",
		minAge = 10, maxAge = 70,
		baseChance = 0.2,
		cooldown = 5,
		choices = {
			{
				text = "Ask for a photo",
				effects = { Happiness = { -5, 10 } },
				feed = "You approached the celebrity for a photo.",
			},
			{
				text = "Play it cool",
				effects = { Happiness = 3 },
				feed = "You stayed cool and gave them a respectful nod.",
			},
			{
				text = "Pretend you didn't notice",
				effects = { Happiness = 2 },
				feed = "You pretended not to see them. Privacy matters.",
			},
		},
	},
	
	{
		id = "random_stranger_kindness",
		title = "Random Kindness",
		emoji = "💝",
		category = "social",
		text = "A stranger did something unexpectedly kind for you.",
		question = "What happened?",
		minAge = 8, maxAge = 80,
		baseChance = 0.3,
		cooldown = 3,
		choices = {
			{
				text = "They paid for your coffee",
				effects = { Happiness = 8 },
				feed = "A stranger paid for your order. Faith in humanity restored!",
			},
			{
				text = "They helped with your bags",
				effects = { Happiness = 5 },
				feed = "Someone helped you carry heavy bags.",
			},
			{
				text = "They gave you a genuine compliment",
				effects = { Happiness = 7, Looks = 1 },
				feed = "A stranger's kind words made your day.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════
	-- TECH & MODERN LIFE
	-- ══════════════════════════════════════════════════════════════════════
	
	{
		id = "random_phone_broke",
		title = "Phone Disaster",
		emoji = "📱",
		category = "tech",
		text = "Your phone screen cracked!",
		question = "What do you do?",
		minAge = 13, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		choices = {
			{
				text = "Get it repaired",
				effects = { Money = -200, Happiness = -2 },
				feed = "You got your phone screen fixed.",
			},
			{
				text = "Buy a new phone",
				effects = { Money = -800, Happiness = 3 },
				feed = "You upgraded to a new phone.",
			},
			{
				text = "Live with the cracks",
				effects = { Happiness = -3 },
				feed = "You're using a cracked phone now.",
			},
		},
	},
	
	{
		id = "random_viral_post",
		title = "Internet Fame",
		emoji = "📲",
		category = "social",
		text = "Something you posted online is getting lots of attention!",
		question = "How does it affect you?",
		minAge = 13, maxAge = 50,
		baseChance = 0.2,
		cooldown = 5,
		choices = {
			{
				text = "Positive attention!",
				effects = { Happiness = 10, Looks = 2 },
				setFlags = { internet_famous = true },
				feed = "Your post went viral in a good way!",
			},
			{
				text = "Mixed reactions",
				effects = { Happiness = { -5, 5 } },
				feed = "Your post got attention, but opinions are divided.",
			},
			{
				text = "Delete it before it spreads",
				effects = { Happiness = -2 },
				feed = "You deleted the post before it got out of hand.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════
	-- HOBBIES & INTERESTS
	-- ══════════════════════════════════════════════════════════════════════
	
	{
		id = "random_new_hobby",
		title = "New Interest",
		emoji = "🎯",
		category = "hobby",
		text = "You discovered a new hobby that really interests you.",
		question = "What is it?",
		minAge = 10, maxAge = 70,
		baseChance = 0.4,
		cooldown = 5,
		choices = {
			{
				text = "A creative pursuit",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { creative_hobby = true },
				feed = "You picked up a creative new hobby!",
			},
			{
				text = "A physical activity",
				effects = { Happiness = 5, Health = 5 },
				setFlags = { active_hobby = true },
				feed = "You started a new active hobby!",
			},
			{
				text = "A mental challenge",
				effects = { Smarts = 7, Happiness = 3 },
				setFlags = { intellectual_hobby = true },
				feed = "You found a hobby that challenges your mind!",
			},
			{
				text = "A social activity",
				effects = { Happiness = 8 },
				setFlags = { social_hobby = true },
				feed = "Your new hobby helps you meet people!",
			},
		},
	},
	
	{
		id = "random_pet_encounter",
		title = "Animal Encounter",
		emoji = "🐕",
		category = "random",
		text = "A friendly stray animal approached you.",
		question = "What do you do?",
		minAge = 5, maxAge = 70,
		baseChance = 0.3,
		cooldown = 4,
		choices = {
			{
				text = "Take it home!",
				effects = { Happiness = 15, Money = -200 },
				setFlags = { has_pet = true, animal_lover = true },
				feed = "You adopted a stray pet!",
			},
			{
				text = "Pet it and move on",
				effects = { Happiness = 5 },
				feed = "You made a furry friend for a moment.",
			},
			{
				text = "Call animal control",
				effects = { Happiness = 2 },
				feed = "You made sure the animal would be taken care of.",
			},
			{
				text = "I'm not an animal person",
				effects = { },
				feed = "You kept your distance from the animal.",
			},
		},
	},
	
	{
		id = "random_book_discovery",
		title = "Life-Changing Book",
		emoji = "📖",
		category = "hobby",
		text = "You read a book that really resonated with you.",
		question = "What kind of book was it?",
		minAge = 12, maxAge = 80,
		baseChance = 0.3,
		cooldown = 3,
		choices = {
			{
				text = "Self-improvement",
				effects = { Smarts = 5, Happiness = 3 },
				setFlags = { self_improver = true },
				feed = "A self-help book gave you new perspective.",
			},
			{
				text = "A gripping novel",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { avid_reader = true },
				feed = "You couldn't put the book down!",
			},
			{
				text = "A career-relevant book",
				effects = { Smarts = 7 },
				feed = "You learned something valuable for your career.",
			},
			{
				text = "A philosophy book",
				effects = { Smarts = 5, Happiness = { -3, 5 } },
				setFlags = { philosophical = true },
				feed = "The book made you question everything.",
			},
		},
	},
}

return RandomEvents
