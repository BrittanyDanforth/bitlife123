--[[
    Hobby & Interest Events
    Events related to hobbies, interests, and leisure activities
    All events use randomized outcomes - NO god mode
    
    CRITICAL FIX #1000+: Hobbies now require DISCOVERY events first!
    User complaint: "I never did a musical option or hobby and it says Musical Journey"
    Players must now discover/start hobbies before progress events trigger!
]]

local HobbyEvents = {}

local STAGE = "random"

HobbyEvents.events = {
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- HOBBY DISCOVERY EVENTS - These introduce hobbies to the player!
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "hobby_general_discovery",
		title = "Looking for a Hobby",
		emoji = "🎯",
		text = "You've got some free time and want to pick up a new hobby. What interests you?",
		question = "What hobby catches your attention?",
		minAge = 10, maxAge = 70,
		baseChance = 0.35,
		cooldown = 10,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "hobby", "discovery", "lifestyle" },
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL FIX: Dynamically adjust choices based on age!
		-- Kids shouldn't need to pay $150 for video games - use common sense!
		preProcess = function(state, eventDef)
			local age = state.Age or 18
			local isKid = age < 18
			
			-- Update choice texts based on age
			if isKid then
				-- Kids get hobbies for free (parents buy stuff, use family resources)
				eventDef.choices[1].text = "🎮 Video games!"
				eventDef.choices[1].effects = { Happiness = 5 }
				eventDef.choices[1].eligibility = nil -- No money needed
				eventDef.choices[1].feedText = "🎮 You got into gaming! So many games to play!"
				
				eventDef.choices[3].text = "👨‍🍳 Cooking/baking with family"
				eventDef.choices[3].effects = { Happiness = 4, Smarts = 1 }
				eventDef.choices[3].eligibility = nil -- No money needed
				eventDef.choices[3].feedText = "👨‍🍳 You're learning to cook with your family! Fun and delicious!"
			end
			return true
		end,
		
		choices = {
			{
				-- CRITICAL FIX: Adults pay $150, kids get it free via preProcess
				text = "🎮 Video games! ($150)",
				effects = { Happiness = 5, Money = -150 },
				setFlags = { gamer = true, plays_video_games = true, owns_console = true },
				feedText = "🎮 You bought a gaming console! Time to play!",
				eligibility = function(state)
					local age = state.Age or 18
					if age < 18 then return true end -- Kids don't pay
					return (state.Money or 0) >= 150, "💸 Can't afford gaming setup ($150)"
				end,
			},
			{
				text = "📚 Reading more",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { bookworm = true, reading_hobby = true },
				feedText = "📚 You joined the library and got a library card! So many books!",
			},
			{
				-- CRITICAL FIX: Adults pay $30, kids cook with family for free
				text = "👨‍🍳 Cooking/baking ($30)",
				effects = { Happiness = 4, Money = -30 },
				setFlags = { pursuing_cooking = true, interested_in_cooking = true },
				feedText = "👨‍🍳 You bought a cookbook and some kitchen supplies! Let's cook!",
				eligibility = function(state)
					local age = state.Age or 18
					if age < 18 then return true end -- Kids cook with family for free
					return (state.Money or 0) >= 30, "Need $30 for cooking supplies"
				end,
			},
			{
				text = "💪 Fitness/exercise",
				effects = { Health = 3, Happiness = 3 },
				setFlags = { fitness_focused = true, athletic = true, sports_lover = true },
				feedText = "💪 You're committed to getting fit! Time to exercise!",
			},
			{
				text = "Nothing right now",
				effects = {},
				feedText = "🤷 Not the right time for a new hobby. Maybe later.",
			},
		},
	},
	{
		id = "hobby_discover_writing",
		title = "The Writing Itch",
		emoji = "✍️",
		text = "You've always had stories in your head. Maybe it's time to write them down?",
		question = "Do you want to try writing?",
		minAge = 12, maxAge = 80,
		baseChance = 0.2,
		cooldown = 10,
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "writing", "discovery", "creative" },
		blockedByFlags = { pursuing_writing = true, writer = true, blogger = true },
		
		choices = {
			{
				text = "Start writing a novel",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { pursuing_writing = true, aspiring_novelist = true },
				feedText = "✍️ You opened a blank document. 'Chapter 1...'",
			},
			{
				text = "Start a blog/journal",
				effects = { Happiness = 4 },
				setFlags = { pursuing_writing = true, journaling = true },
				feedText = "✍️ You started writing regularly. Therapeutic!",
			},
			{
				text = "Writing's not for me",
				effects = {},
				feedText = "✍️ Not everyone's a writer. That's okay!",
			},
		},
	},
	{
		id = "hobby_discover_photography",
		title = "Capturing Moments",
		emoji = "📷",
		text = "You've been taking great photos with your phone. Maybe invest in a real camera?",
		question = "Do you want to pursue photography?",
		minAge = 14, maxAge = 70,
		baseChance = 0.2,
		cooldown = 10,
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "photography", "discovery", "creative" },
		blockedByFlags = { pursuing_photography = true, photographer = true, has_camera = true },
		
		choices = {
			{
				text = "Buy a camera! ($300)",
				effects = { Happiness = 6, Money = -300 },
				setFlags = { pursuing_photography = true, has_camera = true },
				feedText = "📷 New camera! Time to learn about aperture and shutter speed!",
				eligibility = function(state) return (state.Money or 0) >= 300, "Can't afford a camera" end,
			},
			{
				text = "Just keep using my phone",
				effects = { Happiness = 3 },
				setFlags = { phone_photographer = true },
				feedText = "📷 Phone cameras are good enough. You keep snapping!",
			},
			{
				text = "Not interested",
				effects = {},
				feedText = "📷 Photography's not your thing.",
			},
		},
	},
	{
		id = "hobby_discover_yoga",
		title = "Mind-Body Connection",
		emoji = "🧘",
		text = "A friend invited you to try yoga. It could be relaxing...",
		question = "Do you want to try yoga?",
		minAge = 15, maxAge = 85,
		baseChance = 0.2,
		cooldown = 10,
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "yoga", "wellness", "discovery" },
		blockedByFlags = { pursuing_yoga = true, yoga_practitioner = true, in_prison = true },
		
		choices = {
		{
			text = "Yes! Sign me up! ($50)",
			effects = { Happiness = 5, Health = 2, Money = -50 },
			eligibility = function(state) return (state.Money or 0) >= 50, "💸 Can't afford yoga class ($50 needed)" end,
			setFlags = { pursuing_yoga = true, wellness_focused = true },
			feedText = "🧘 First class was challenging but peaceful!",
		},
			{
				text = "I'll try it at home with videos",
				effects = { Happiness = 3, Health = 1 },
				setFlags = { pursuing_yoga = true },
				feedText = "🧘 Downloaded a yoga app. Namaste at home!",
			},
			{
				text = "Not my thing",
				effects = {},
				feedText = "🧘 Yoga's not for everyone.",
			},
		},
	},
	{
		id = "hobby_discover_collecting",
		title = "Collector's Spark",
		emoji = "🏆",
		text = "You found an interesting item and wondered if it's valuable. Maybe start a collection?",
		question = "Do you want to start collecting?",
		minAge = 10, maxAge = 90,
		baseChance = 0.2,
		cooldown = 10,
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "collecting", "discovery", "hobby" },
		blockedByFlags = { collector = true, has_collection = true },
		
		choices = {
			{
				text = "Start collecting! ($50)",
				effects = { Happiness = 5, Money = -50 },
				setFlags = { collector = true, has_collection = true, likes_collecting = true },
				feedText = "🏆 Your first piece! The start of a collection!",
				-- CRITICAL FIX: Prevent softlock by checking affordability upfront
				eligibility = function(state)
					return (state.Money or 0) >= 50, "💸 You need $50 to start collecting! (You have $" .. tostring(state.Money or 0) .. ")"
				end,
			},
			{
				text = "Maybe just this one item",
				effects = { Happiness = 2 },
				feedText = "🏆 Nice find, but collecting's not your thing.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CREATIVE HOBBIES
	-- ══════════════════════════════════════════════════════════════════════════════
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #1000: HOBBY DISCOVERY EVENT (Must happen BEFORE pursuing hobbies!)
	-- User complaint: "I never did a musical option or hobby and it says Musical Journey"
	-- This event INTRODUCES hobbies to the player first!
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "hobby_discover_music",
		title = "Musical Curiosity",
		emoji = "🎵",
		text = "You've been hearing music that really moves you. Maybe you should try learning an instrument?",
		question = "Do you want to pursue music as a hobby?",
		minAge = 8, maxAge = 50,
		baseChance = 0.25,
		cooldown = 8,
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "music", "discovery", "hobby" },
		blockedByFlags = { in_prison = true, incarcerated = true, pursuing_music = true, musician = true },
		
		choices = {
			{
				text = "Yes! I want to learn an instrument!",
				effects = { Happiness = 5 },
				setFlags = { pursuing_music = true, started_music_hobby = true },
				feedText = "🎵 You found a cheap used instrument online! Time to learn!",
			},
			{
				text = "Try singing",
				effects = { Happiness = 5 },
				setFlags = { pursuing_music = true, pursuing_singing = true },
				feedText = "🎵 YouTube tutorials and practice! La la la!",
			},
			{
				text = "Just enjoy listening for now",
				effects = { Happiness = 3 },
				setFlags = { music_appreciator = true },
				feedText = "🎵 Not for you right now, but you love listening to music!",
			},
			{
				text = "Not interested in music",
				effects = {},
				feedText = "🎵 Music's not your thing. That's okay!",
			},
		},
	},
	{
		id = "hobby_music_pursuit",
		title = "Musical Journey",
		emoji = "🎵",
		text = "Time to practice your music!",
		question = "How is your musical hobby going?",
		minAge = 8, maxAge = 90,
		baseChance = 0.45,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "music", "instrument", "creative" },
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL FIX #1001: REQUIRE player to have started music hobby first!
		requiresFlags = { pursuing_music = true },
		eligibility = function(state)
			local flags = state.Flags or {}
			if not (flags.pursuing_music or flags.musician or flags.started_music_hobby or flags.in_a_band) then
				return false, "Not pursuing music as a hobby"
			end
			return true
		end,
		
		choices = {
			{
				text = "Practice an instrument ($50)",
				effects = { Money = -50 },
				feedText = "Practicing...",
				eligibility = function(state) return (state.Money or 0) >= 50, "💸 Can't afford instrument supplies ($50 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						if state.ModifyStat then
							state:ModifyStat("Happiness", 10)
							state:ModifyStat("Smarts", 3)
						end
						state.Flags = state.Flags or {}
						state.Flags.musician = true
						if state.AddFeed then state:AddFeed("🎵 Getting good! Can play a whole song! Progress!") end
					elseif roll < 0.80 then
						if state.ModifyStat then
							state:ModifyStat("Happiness", 5)
							state:ModifyStat("Smarts", 2)
						end
						if state.AddFeed then state:AddFeed("🎵 Slow progress but improving bit by bit.") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("🎵 Frustrating plateau. Maybe not musical after all?") end
					end
				end,
			},
			{ text = "Join a band/ensemble", effects = { Happiness = 8, Smarts = 2 }, setFlags = { in_a_band = true }, feedText = "🎵 Making music with others! Collaborative magic!" },
			{ text = "Take lessons ($100)", effects = { Money = -100, Happiness = 6, Smarts = 4 }, feedText = "🎵 Professional instruction accelerating learning!",
				eligibility = function(state) return (state.Money or 0) >= 100, "Can't afford $100 lessons" end,
			},
			{ 
				text = "Give up music",
				effects = { Happiness = -3 },
				setFlags = { pursuing_music = false, quit_music = true },
				feedText = "🎵 Music just isn't for you. Time to move on.",
			},
		},
	},
	-- CRITICAL FIX #1002: Art discovery event
	{
		id = "hobby_discover_art",
		title = "Artistic Curiosity",
		emoji = "🎨",
		text = "You've been admiring art and wondering if you could create something yourself...",
		question = "Do you want to try art as a hobby?",
		minAge = 5, maxAge = 60,
		baseChance = 0.25,
		cooldown = 8,
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "art", "discovery", "hobby" },
		blockedByFlags = { in_prison = true, incarcerated = true, pursuing_art = true, artist = true },
		
		choices = {
			{
				text = "Yes! Get me some art supplies! ($50)",
				effects = { Happiness = 5, Money = -50 },
				setFlags = { pursuing_art = true, started_art_hobby = true },
				feedText = "🎨 You bought paints, brushes, canvas! Let's create!",
				eligibility = function(state) return (state.Money or 0) >= 50, "💸 Can't afford art supplies ($50)" end,
			},
			{
				text = "Maybe just some drawing ($20)",
				effects = { Happiness = 4, Money = -20 },
				setFlags = { pursuing_art = true, pursuing_drawing = true },
				feedText = "🎨 You got a sketchbook and pencils! Simple but fun!",
				eligibility = function(state) return (state.Money or 0) >= 20, "💸 Can't afford supplies ($20)" end,
			},
			{
				text = "I prefer to appreciate art, not create it",
				effects = { Happiness = 2 },
				setFlags = { art_appreciator = true },
				feedText = "🎨 You love visiting galleries but making art isn't for you.",
			},
			{
				text = "Art's not my thing",
				effects = {},
				feedText = "🎨 Not everyone's an artist. That's perfectly fine!",
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
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "art", "painting", "creative" },
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL FIX #1003: REQUIRE player to have started art hobby first!
		requiresFlags = { pursuing_art = true },
		eligibility = function(state)
			local flags = state.Flags or {}
			if not (flags.pursuing_art or flags.artist or flags.started_art_hobby or flags.pursuing_drawing) then
				return false, "Not pursuing art as a hobby"
			end
			return true
		end,
		
		-- CRITICAL: Random art creation outcome
		choices = {
			{
				text = "Create a new piece ($30 supplies)",
				effects = { Money = -30 },
				feedText = "Creating art...",
				eligibility = function(state) return (state.Money or 0) >= 30, "Need $30 for art supplies" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then
							state:ModifyStat("Happiness", 12)
							state:ModifyStat("Smarts", 2)
						end
						state.Flags = state.Flags or {}
						state.Flags.artist = true
						if state.AddFeed then state:AddFeed("🎨 MASTERPIECE! Best work yet! True creative expression!") end
					elseif roll < 0.75 then
						if state.ModifyStat then state:ModifyStat("Happiness", 6) end
						if state.AddFeed then state:AddFeed("🎨 Decent piece. Learning and growing as an artist.") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("🎨 Not happy with it. Scrapped and starting over.") end
					end
				end,
			},
			{ text = "Take an art class ($80)", effects = { Money = -80, Happiness = 6, Smarts = 4 }, feedText = "🎨 Learning new techniques! Skill level up!", eligibility = function(state) return (state.Money or 0) >= 80, "Need $80 for art class" end },
			{ text = "Share your art online", effects = {}, feedText = "Posting your work...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 12) end
						state.Money = (state.Money or 0) + 50
						if state.AddFeed then state:AddFeed("🎨 VIRAL! People love your art! Commission requests!") end
					elseif roll < 0.70 then
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddFeed then state:AddFeed("🎨 Some likes and comments! Encouragement helps!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -3) end
						if state.AddFeed then state:AddFeed("🎨 Crickets. Or worse, criticism. Ouch.") end
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
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		
		-- CRITICAL FIX #1004: Require player to have started writing hobby first!
		requiresFlags = { pursuing_writing = true },
		eligibility = function(state)
			local flags = state.Flags or {}
			if not (flags.pursuing_writing or flags.writer or flags.blogger or flags.journaling) then
				return false, "Not pursuing writing as a hobby"
			end
			return true
		end,
		tags = { "writing", "creative", "author" },
		-- AAA FIX: Can't pursue writing hobbies in prison (different events for prison writing)
		blockedByFlags = { in_prison = true, incarcerated = true },
		
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
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		
		-- CRITICAL FIX #1005: Require player to have started photography hobby first!
		requiresFlags = { pursuing_photography = true },
		eligibility = function(state)
			local flags = state.Flags or {}
			if not (flags.pursuing_photography or flags.photographer or flags.has_camera) then
				return false, "Not pursuing photography as a hobby"
			end
			return true
		end,
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
			{ text = "Enter a photo contest ($20)", effects = { Money = -20 }, feedText = "Submitting to contest...",
				eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20 entry fee" end,
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
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		
		-- CRITICAL FIX #1006: Require player to have a garden first!
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Must have a place to garden (homeowner or has access to land)
			if not (flags.gardener or flags.has_garden or flags.homeowner or flags.has_backyard) then
				return false, "No garden to tend"
			end
			return true
		end,
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
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		
		-- CRITICAL FIX #1007: Require player to have started cooking hobby!
		eligibility = function(state)
			local flags = state.Flags or {}
			if not (flags.pursuing_cooking or flags.home_chef or flags.interested_in_cooking) then
				return false, "Not pursuing cooking as a hobby"
			end
			return true
		end,
		tags = { "cooking", "food", "kitchen" },
		
		-- CRITICAL: Random cooking outcome
		choices = {
			{
				text = "Try a challenging recipe ($30)",
				effects = { Money = -30 },
				feedText = "In the kitchen...",
				eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30 for ingredients" end,
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
			{ text = "Take a cooking class ($75)", effects = { Money = -75, Happiness = 7, Smarts = 4 }, feedText = "👨‍🍳 Learning from pros! Knife skills improved!", eligibility = function(state) return (state.Money or 0) >= 75, "💸 Need $75 for class" end },
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
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		
		-- CRITICAL FIX #1008: Require player to be interested in sports!
		eligibility = function(state)
			local flags = state.Flags or {}
			local health = (state.Stats and state.Stats.Health) or 50
			-- Must have interest in sports OR be healthy enough
			if flags.in_prison or flags.incarcerated then return false, "Can't play sports in prison" end
			if not (flags.sports_lover or flags.athletic or flags.plays_sports or health >= 40) then
				return false, "Not interested in sports"
			end
			return true
		end,
		tags = { "sports", "recreation", "fitness" },
		
		-- CRITICAL: Random sports outcome
		choices = {
			{
				text = "Play in a rec league ($30)",
				effects = { Money = -30 },
				feedText = "Game day...",
				eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30 for league fee" end,
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
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		
		-- CRITICAL FIX #1009: Require player to be pursuing yoga!
		eligibility = function(state)
			local flags = state.Flags or {}
			if flags.in_prison or flags.incarcerated then return false, "Can't do yoga in prison" end
			if not (flags.pursuing_yoga or flags.yoga_practitioner or flags.wellness_focused) then
				return false, "Not pursuing yoga/wellness"
			end
			return true
		end,
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
			{ text = "Try hot yoga ($20)", effects = { Health = 4, Happiness = 6, Money = -20 }, feedText = "🧘 Sweating out toxins! Intense but cleansing!", eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20 for hot yoga" end },
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
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		
		-- CRITICAL FIX #1010: Require player to be a gamer!
		eligibility = function(state)
			local flags = state.Flags or {}
			if flags.in_prison or flags.incarcerated then return false, "Can't game in prison" end
			-- Gaming is pretty accessible - just need to have played before
			if not (flags.gamer or flags.plays_video_games or flags.owns_console or flags.pc_gamer) then
				return false, "Not a gamer"
			end
			return true
		end,
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
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		
		-- CRITICAL FIX #1011: Require player to be a collector!
		eligibility = function(state)
			local flags = state.Flags or {}
			if not (flags.collector or flags.has_collection or flags.likes_collecting) then
				return false, "Not a collector"
			end
			return true
		end,
		tags = { "collecting", "hobby", "treasure" },
		
		-- CRITICAL: Random collecting outcome
		choices = {
			{
				text = "Hunt for new items ($50)",
				effects = { Money = -50 },
				feedText = "Searching for treasures...",
				eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 for hunting" end,
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
				text = "Host game night ($30)",
				effects = { Money = -30 },
				feedText = "Rolling dice, playing cards...",
				eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30 for snacks/drinks" end,
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
			{ text = "Visit board game cafe ($20)", effects = { Money = -20, Happiness = 7 }, feedText = "🎲 So many games! Great atmosphere! Found new favorites!", eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20 for cafe" end },
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "hobbies",
		tags = { "diy", "crafts", "projects" },
		
		-- CRITICAL: Random DIY outcome
		choices = {
			{
				text = "Take on the project ($75)",
				effects = { Money = -75 },
				feedText = "Building/crafting...",
				eligibility = function(state) return (state.Money or 0) >= 75, "💸 Need $75 for materials" end,
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
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 50)
						state:AddFeed("🔨 Disaster. Had to call a professional. Money wasted.")
					end
				end,
			},
			{ text = "Small craft project ($20)", effects = { Money = -20, Happiness = 6, Smarts = 2 }, feedText = "🔨 Handmade creation! Cute and personal!", eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20 for supplies" end },
			{ text = "Furniture restoration ($40)", effects = { Money = -40, Happiness = 8 }, feedText = "🔨 Old made new! Upcycling success! Sustainable!", eligibility = function(state) return (state.Money or 0) >= 40, "💸 Need $40 for supplies" end },
			{ text = "Watch DIY tutorials", effects = { Smarts = 3, Happiness = 2 }, feedText = "🔨 Learning skills online! Free education!" },
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
