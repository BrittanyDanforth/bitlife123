--[[
    Hobby & Interest Events
    Events related to hobbies, interests, and leisure activities
    All events use randomized outcomes - NO god mode
]]

local HobbyEvents = {}

local STAGE = "random"

HobbyEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CREATIVE HOBBIES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "hobby_music_pursuit",
		title = "Musical Journey",
		emoji = "🎵",
		text = "You're pursuing music as a hobby!",
		question = "How is your musical hobby going?",
		minAge = 8, maxAge = 90,
		baseChance = 0.45,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "music", "instrument", "creative" },
		
		-- CRITICAL: Random music progress
		choices = {
			{
				text = "Practice an instrument",
				effects = { Money = -50 },
				feedText = "Practicing...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.musician = true
						state:AddFeed("🎵 Getting good! Can play a whole song! Progress!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🎵 Slow progress but improving bit by bit.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🎵 Frustrating plateau. Maybe not musical after all?")
					end
				end,
			},
			{ text = "Join a band/ensemble", effects = { Happiness = 8, Smarts = 2 }, setFlags = { in_a_band = true }, feedText = "🎵 Making music with others! Collaborative magic!" },
			-- MINOR FIX: Show price in choice text
		{ text = "Take lessons ($100)", effects = { Money = -100, Happiness = 6, Smarts = 4 }, feedText = "🎵 Professional instruction accelerating learning!",
			eligibility = function(state) return (state.Money or 0) >= 100, "Can't afford $100 lessons" end,
		},
		},
	},
	{
		id = "hobby_art_creation",
		title = "Art Creation",
		emoji = "🎨",
		text = "Working on your art!",
		question = "How is your art going?",
		minAge = 5, maxAge = 100,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "art", "painting", "creative" },
		
		-- CRITICAL: Random art creation outcome
		choices = {
			{
				text = "Create a new piece",
				effects = { Money = -30 },
				feedText = "Creating art...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.artist = true
						state:AddFeed("🎨 MASTERPIECE! Best work yet! True creative expression!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🎨 Decent piece. Learning and growing as an artist.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🎨 Not happy with it. Scrapped and starting over.")
					end
				end,
			},
			{ text = "Take an art class", effects = { Money = -80, Happiness = 6, Smarts = 4 }, feedText = "🎨 Learning new techniques! Skill level up!" },
			{ text = "Share your art online", effects = {}, feedText = "Posting your work...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 12)
						state.Money = (state.Money or 0) + 50
						state:AddFeed("🎨 VIRAL! People love your art! Commission requests!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎨 Some likes and comments! Encouragement helps!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🎨 Crickets. Or worse, criticism. Ouch.")
					end
				end,
			},
		},
	},
	{
		id = "hobby_writing",
		title = "Writing Endeavors",
		emoji = "✍️",
		text = "Working on your writing!",
		question = "How is your writing going?",
		minAge = 12, maxAge = 100,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "writing", "creative", "author" },
		
		-- CRITICAL: Random writing outcome
		choices = {
			{
				text = "Work on your story/novel",
				effects = {},
				feedText = "Writing...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.35 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 4)
						state.Flags = state.Flags or {}
						state.Flags.writer = true
						state:AddFeed("✍️ Writing flows! Chapter complete! In the zone!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("✍️ Words on page. Progress even if slow.")
					else
						state:ModifyStat("Happiness", -3)
						state.Flags = state.Flags or {}
						state.Flags.writers_block = true
						state:AddFeed("✍️ WRITER'S BLOCK! Staring at blank page. Frustrating!")
					end
				end,
			},
			{ text = "Submit to publication", effects = {}, feedText = "Sending your work...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.15 then
						state:ModifyStat("Happiness", 15)
						state.Money = (state.Money or 0) + 500
						state.Flags = state.Flags or {}
						state.Flags.published = true
						state:AddFeed("✍️ ACCEPTED! Getting published! Writer achievement unlocked!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("✍️ Rejection letter. Keep trying. Every author has a stack.")
					end
				end,
			},
			{ text = "Start a blog", effects = { Happiness = 5, Smarts = 2 }, setFlags = { blogger = true }, feedText = "✍️ Blog launched! Writing for an audience now!" },
		},
	},
	{
		id = "hobby_photography",
		title = "Photography",
		emoji = "📷",
		text = "Exploring photography!",
		question = "How is your photography hobby?",
		minAge = 12, maxAge = 90,
		baseChance = 0.45,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "photography", "camera", "creative" },
		
		choices = {
			{
				text = "Go on a photo walk",
				effects = { Health = 2 },
				feedText = "Capturing moments...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.photographer = true
						state:AddFeed("📷 AMAZING SHOTS! Perfect light! Portfolio worthy!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("📷 Some good shots! Getting better at composition!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📷 Mediocre photos. Need more practice.")
					end
				end,
			},
			-- MINOR FIX: Show price in choice text
		{ text = "Upgrade equipment ($500)", effects = { Money = -500, Happiness = 6, Smarts = 2 }, feedText = "📷 New camera! Better lenses! The gear helps!",
			eligibility = function(state) return (state.Money or 0) >= 500, "Can't afford $500 upgrade" end,
		},
			{ text = "Enter a photo contest", effects = { Money = -20 }, feedText = "Submitting to contest...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.10 then
						state:ModifyStat("Happiness", 15)
						state.Money = (state.Money or 0) + 500
						state:AddFeed("📷 WON! Photo contest winner! Recognition!")
					elseif roll < 0.35 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("📷 Honorable mention! Eyes on your work!")
					else
						state:ModifyStat("Happiness", -1)
						state:AddFeed("📷 Didn't place. Tough competition.")
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- PHYSICAL HOBBIES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "hobby_gardening",
		title = "Gardening",
		emoji = "🌱",
		text = "Tending to your garden!",
		question = "How is your garden growing?",
		minAge = 10, maxAge = 100,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "gardening", "plants", "nature" },
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true },  -- CRITICAL FIX: Can't garden in prison/homeless!
		
		-- CRITICAL: Random gardening outcome
		choices = {
			{
				text = "Spend time in the garden",
				effects = { Health = 2 },
				feedText = "Planting and weeding...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.gardener = true
						state:AddFeed("🌱 THRIVING! Plants are flourishing! Green thumb!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🌱 Mixed results. Some plants happy, others struggling.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🌱 Pests/drought/disease. Garden struggling. Sad.")
					end
				end,
			},
			{ text = "Grow vegetables", effects = { Health = 3, Happiness = 6, Money = 20 }, feedText = "🌱 Homegrown produce! Tastes better AND saves money!" },
			{ text = "Plant flowers", effects = { Happiness = 8, Looks = 1 }, feedText = "🌱 Beautiful blooms! Yard looks amazing!" },
		},
	},
	{
		id = "hobby_cooking",
		title = "Cooking Adventures",
		emoji = "👨‍🍳",
		text = "Exploring cooking as a hobby!",
		question = "What are you cooking?",
		minAge = 12, maxAge = 100,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "cooking", "food", "kitchen" },
		
		-- CRITICAL: Random cooking outcome
		choices = {
			{
				text = "Try a challenging recipe",
				effects = { Money = -30 },
				feedText = "In the kitchen...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.45 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.home_chef = true
						state:AddFeed("👨‍🍳 DELICIOUS! Restaurant quality! Impressed everyone!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("👨‍🍳 Turned out well! Edible and enjoyable!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("👨‍🍳 Kitchen disaster. Burned/underseasoned/wrong. Takeout it is.")
					end
				end,
			},
			{ text = "Take a cooking class", effects = { Money = -75, Happiness = 7, Smarts = 4 }, feedText = "👨‍🍳 Learning from pros! Knife skills improved!" },
			{ text = "Meal prep for the week", effects = { Health = 3, Happiness = 4, Money = 30 }, feedText = "👨‍🍳 Organized! Healthy meals ready! Productive!" },
		},
	},
	{
		id = "hobby_sports_recreation",
		title = "Recreational Sports",
		emoji = "⚽",
		text = "Playing recreational sports!",
		question = "How is your sports hobby going?",
		minAge = 10, maxAge = 75,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "sports", "recreation", "fitness" },
		
		-- CRITICAL: Random sports outcome
		choices = {
			{
				text = "Play in a rec league",
				effects = { Money = -30 },
				feedText = "Game day...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					
					if roll < 0.50 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Health", 4)
						state.Flags = state.Flags or {}
						state.Flags.rec_athlete = true
						state:AddFeed("⚽ Great game! Won! Exercise AND fun!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Health", 3)
						state:AddFeed("⚽ Good game! Lost but had fun! Workout!")
					else
						state:ModifyStat("Happiness", 2)
						state:ModifyStat("Health", -2)
						state:AddFeed("⚽ Tweaked something. Minor injury. Sore.")
					end
				end,
			},
			{ text = "Casual pickup game", effects = { Health = 3, Happiness = 6 }, feedText = "⚽ Spontaneous sports! Low pressure fun!" },
			{ text = "Watch instead of play", effects = { Happiness = 4 }, feedText = "⚽ Cheering from sidelines. Maybe next time." },
		},
	},
	{
		id = "hobby_yoga_wellness",
		title = "Yoga & Wellness",
		emoji = "🧘",
		text = "Practicing yoga and wellness!",
		question = "How is your practice?",
		minAge = 15, maxAge = 90,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "yoga", "wellness", "mindfulness" },
		
		choices = {
			{
				text = "Commit to regular practice",
				effects = {},
				feedText = "On the mat...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Health", 5)
						state.Flags = state.Flags or {}
						state.Flags.yogi = true
						state:AddFeed("🧘 Flexible, centered, calm! Yoga is life changing!")
					else
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Health", 3)
						state:AddFeed("🧘 Some sessions better than others. Still beneficial.")
					end
				end,
			},
			{ text = "Try hot yoga", effects = { Health = 4, Happiness = 6, Money = -20 }, feedText = "🧘 Sweating out toxins! Intense but cleansing!" },
			-- MINOR FIX: Show price in choice text
		{ text = "Yoga retreat ($300)", effects = { Money = -300, Happiness = 12, Health = 5 }, setFlags = { yoga_retreat = true }, feedText = "🧘 Weekend of peace and practice! Transformed!",
			eligibility = function(state) return (state.Money or 0) >= 300, "Can't afford $300 retreat" end,
		},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- COLLECTING & GAMING
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "hobby_gaming",
		title = "Video Gaming",
		emoji = "🎮",
		text = "Gaming is life!",
		question = "How is your gaming going?",
		minAge = 8, maxAge = 80,
		baseChance = 0.55,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "gaming", "video_games", "entertainment" },
		
		-- CRITICAL: Random gaming outcome
		choices = {
			{
				text = "Marathon gaming session",
				effects = {},
				feedText = "Controller in hand...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.gamer = true
						state:AddFeed("🎮 EPIC SESSION! Beat the boss! Achievement unlocked!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🎮 Fun session! Made progress! Good times!")
					else
						state:ModifyStat("Happiness", -2)
						state:ModifyStat("Health", -1)
						state:AddFeed("🎮 Too much gaming. Eyes hurt. Feeling guilty.")
					end
				end,
			},
			{ text = "Play online with friends", effects = { Happiness = 8, Smarts = 1 }, feedText = "🎮 Squad up! Laughs and competition! Social gaming!" },
			{ text = "Try competitive gaming", effects = {}, feedText = "Entering the ranked queue...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🎮 RANKED UP! Better than expected! Competitive gamer!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🎮 Toxic lobbies. Lost rank. Tilted. Taking a break.")
					end
				end,
			},
		},
	},
	{
		id = "hobby_collecting",
		title = "Collecting",
		emoji = "🏆",
		text = "Working on your collection!",
		question = "How is your collection growing?",
		minAge = 10, maxAge = 100,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "collecting", "hobby", "treasure" },
		
		-- CRITICAL: Random collecting outcome
		choices = {
			{
				text = "Hunt for new items",
				effects = { Money = -50 },
				feedText = "Searching for treasures...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.collector = true
						state:AddFeed("🏆 RARE FIND! White whale caught! Collection upgraded!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🏆 Found some decent items! Collection growing!")
					else
						state:ModifyStat("Happiness", 1)
						state:AddFeed("🏆 Nothing good today. The hunt continues.")
					end
				end,
			},
			{ text = "Sell duplicate items", effects = {}, feedText = "Listing duplicates...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state.Money = (state.Money or 0) + 200
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🏆 Sold well! Profit AND room for more!")
					else
						state.Money = (state.Money or 0) + 30
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🏆 Low offers. Sold for less than hoped.")
					end
				end,
			},
			{ text = "Display/organize collection", effects = { Happiness = 6, Smarts = 1 }, feedText = "🏆 Admiring your treasures! Pride of ownership!" },
		},
	},
	{
		id = "hobby_board_games",
		title = "Board Gaming",
		emoji = "🎲",
		text = "Board game night!",
		question = "How does game night go?",
		minAge = 8, maxAge = 100,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "board_games", "social", "games" },
		
		-- CRITICAL: Random board game night
		choices = {
			{
				text = "Host game night",
				effects = { Money = -30 },
				feedText = "Rolling dice, playing cards...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.game_night_host = true
						state:AddFeed("🎲 EPIC NIGHT! Great games, great people! Everyone won!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🎲 Fun night! Some games better than others!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🎲 Someone was a sore loser. Awkward end to the night.")
					end
				end,
			},
			{ text = "Learn a complex new game", effects = { Smarts = 4, Happiness = 4 }, feedText = "🎲 Brain workout! Strategy game mastered!" },
			{ text = "Visit board game cafe", effects = { Money = -20, Happiness = 7 }, feedText = "🎲 So many games! Great atmosphere! Found new favorites!" },
		},
	},
	{
		id = "hobby_reading",
		title = "Reading",
		emoji = "📚",
		text = "Lost in a good book!",
		question = "What are you reading?",
		minAge = 8, maxAge = 100,
		baseChance = 0.455,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "reading", "books", "learning" },
		
		choices = {
			{ text = "Fiction adventure", effects = { Happiness = 8, Smarts = 2 }, setFlags = { bookworm = true }, feedText = "📚 Couldn't put it down! Transported to another world!" },
			{ text = "Non-fiction learning", effects = { Smarts = 5, Happiness = 5 }, feedText = "📚 Mind expanded! New knowledge acquired!" },
			{ text = "Classic literature", effects = { Smarts = 4, Happiness = 4 }, feedText = "📚 Timeless wisdom! Understanding why it's a classic!" },
			{ text = "Start a book club", effects = { Happiness = 7, Smarts = 3 }, setFlags = { book_club_member = true }, feedText = "📚 Discussing books with others! Social AND intellectual!" },
		},
	},
	{
		id = "hobby_diy_projects",
		title = "DIY Projects",
		emoji = "🔨",
		text = "Working on a DIY project!",
		question = "How does the project go?",
		minAge = 15, maxAge = 85,
		baseChance = 0.45,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "diy", "crafts", "projects" },
		
		-- CRITICAL: Random DIY outcome
		choices = {
			{
				text = "Take on the project",
				effects = { Money = -75 },
				feedText = "Building/crafting...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.40 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.handy = true
						state:AddFeed("🔨 NAILED IT! Project complete! So satisfying!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🔨 Done! Not perfect but functional! Proud of it!")
					else
						state:ModifyStat("Happiness", -3)
						state.Money = (state.Money or 0) - 50
						state:AddFeed("🔨 Disaster. Had to call a professional. Money wasted.")
					end
				end,
			},
			{ text = "Small craft project", effects = { Money = -20, Happiness = 6, Smarts = 2 }, feedText = "🔨 Handmade creation! Cute and personal!" },
			{ text = "Furniture restoration", effects = { Money = -40, Happiness = 8 }, feedText = "🔨 Old made new! Upcycling success! Sustainable!" },
		},
	},
	{
		id = "hobby_outdoor_activities",
		title = "Outdoor Adventures",
		emoji = "🌲",
		text = "Getting outside!",
		question = "What outdoor activity?",
		minAge = 5, maxAge = 85,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "outdoors", "nature", "adventure" },
		blockedByFlags = { in_prison = true, incarcerated = true },  -- CRITICAL FIX: Can't go hiking in prison!
		
		choices = {
			{
				text = "Go hiking",
				effects = {},
				feedText = "On the trail...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					
					if roll < 0.60 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Health", 4)
						state.Flags = state.Flags or {}
						state.Flags.hiker = true
						state:AddFeed("🌲 AMAZING VIEWS! Great hike! Nature heals!")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Health", 3)
						state:AddFeed("🌲 Nice hike! Good exercise! Fresh air!")
					else
						state:ModifyStat("Happiness", 2)
						state:ModifyStat("Health", -1)
						state:AddFeed("🌲 Harder than expected. Made it but exhausted.")
					end
				end,
			},
			{ text = "Bird watching", effects = { Happiness = 6, Smarts = 3, Health = 2 }, setFlags = { birder = true }, feedText = "🌲 Spotted rare birds! Peaceful hobby! Nature connection!" },
			{ text = "Fishing", effects = { Happiness = 7, Health = 2 }, feedText = "🌲 Relaxing by the water. Caught dinner maybe!",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:AddFeed("🌲 Caught some fish! Dinner sorted!")
					else
						state:AddFeed("🌲 Nothing biting but peaceful anyway.")
					end
				end,
			},
			{ text = "Just enjoy a park", effects = { Happiness = 5, Health = 2 }, feedText = "🌲 Simple pleasures. Fresh air and grass. Perfect." },
		},
	},
}

return HobbyEvents
