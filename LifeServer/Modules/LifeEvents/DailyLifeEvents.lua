--[[
    Daily Life Events
    Everyday mundane events that happen regularly
    All events use randomized outcomes - NO god mode
]]

local DailyLifeEvents = {}

local STAGE = "random"

DailyLifeEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MORNING EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "daily_alarm_morning",
		title = "Morning Alarm",
		emoji = "⏰",
		text = "The alarm is going off!",
		-- CRITICAL FIX: Added text variations for morning routine!
		textVariants = {
			"BEEP BEEP BEEP! The alarm is screaming at you. Time to face the day.",
			"Your phone alarm starts playing that song. You know the one.",
			"6:30 AM. The alarm clock is your enemy. But also your friend. Kinda.",
			"That irritating buzzing sound. Morning has arrived whether you like it or not.",
			"Another day, another alarm. The eternal struggle begins.",
			"Your alarm goes off. The battle between sleep and responsibility commences.",
		},
		question = "How do you start your day?",
		minAge = 12, maxAge = 80,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "morning", "routine", "wake" },
		-- AAA FIX: Can't have normal morning routine in prison!
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL: Random morning outcome
		choices = {
			{
				text = "Jump up ready to go",
				effects = {},
				feedText = "Starting the day strong...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then
							state:ModifyStat("Happiness", 5)
							state:ModifyStat("Health", 2)
						end
						state.Flags = state.Flags or {}
						state.Flags.morning_person = true
						if state.AddFeed then state:AddFeed("⏰ Great start! Feeling energized! Productive day ahead!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 2) end
						if state.AddFeed then state:AddFeed("⏰ Up and at 'em. Coffee will help. Normal morning.") end
					end
				end,
			},
			{ text = "Hit snooze multiple times", effects = { Happiness = -2, Health = -1 }, feedText = "⏰ Just five more... ten more... now you're late!" },
			{ text = "Oversleep completely", effects = { Happiness = -5, Smarts = -1 }, feedText = "⏰ SLEPT THROUGH IT! Scrambling! Day ruined already!" },
		},
	},
	{
		id = "daily_breakfast_decision",
		title = "Breakfast Decision",
		emoji = "🍳",
		text = "Time for breakfast!",
		-- CRITICAL FIX: Added text variations for breakfast!
		textVariants = {
			"Your stomach is growling. What's for breakfast?",
			"The most important meal of the day... or is it?",
			"You stumble into the kitchen. Breakfast options await.",
			"Your body needs fuel. The fridge awaits your decision.",
			"Morning hunger hits. What's on the breakfast menu today?",
			"Time to eat something before starting the day.",
		},
		question = "What do you eat?",
		minAge = 8, maxAge = 100,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "breakfast", "food", "morning" },
		-- AAA FIX: Can't choose breakfast in prison!
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		choices = {
			{ text = "Healthy breakfast ($5)", effects = { Health = 3, Happiness = 3, Money = -5 }, feedText = "🍳 Eggs, fruit, good stuff! Fueled for the day!", eligibility = function(state) return (state.Money or 0) >= 5, "💸 Need $5" end },
			{ text = "Quick cereal/toast ($2)", effects = { Happiness = 2, Money = -2 }, feedText = "🍳 Basic breakfast. Does the job.", eligibility = function(state) return (state.Money or 0) >= 2, "💸 Need $2" end },
			{ text = "Skip breakfast", effects = { Health = -2, Happiness = -1 }, feedText = "🍳 No time! Running on empty. Coffee will do." },
			{ text = "Fancy brunch ($25)", effects = { Happiness = 8, Money = -25, Health = 1 }, feedText = "🍳 Treating yourself! Avocado toast energy!", eligibility = function(state) return (state.Money or 0) >= 25, "💸 Need $25" end },
		},
	},
	{
		id = "daily_getting_dressed",
		title = "Getting Dressed",
		emoji = "👕",
		text = "Time to pick an outfit!",
		question = "How does getting dressed go?",
		minAge = 10, maxAge = 90,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "clothes", "fashion", "routine" },
		-- AAA FIX: Can't choose outfits in prison (prison uniform!)
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL: Random outfit outcome
		choices = {
			{
				text = "Put together a great outfit",
				effects = {},
				feedText = "Checking the mirror...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					
					if roll < 0.50 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then
							state:ModifyStat("Happiness", 6)
							state:ModifyStat("Looks", 2)
						end
						if state.AddFeed then state:AddFeed("👕 Looking GOOD! Confidence boost! Outfit on point!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 3) end
						if state.AddFeed then state:AddFeed("👕 Decent outfit. Presentable. Good enough!") end
					end
				end,
			},
			{ text = "Wear whatever's clean", effects = { Happiness = 1 }, feedText = "👕 Function over fashion. It's clean, it works." },
			{ text = "Nothing fits right today", effects = { Happiness = -4, Looks = -1 }, feedText = "👕 Bloated? Wrong size? Nothing works. Frustrated." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- COMMUTE EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "daily_commute_car",
		title = "Daily Commute",
		emoji = "🚗",
		text = "Time for your daily commute!",
		question = "How does the commute go?",
		minAge = 18, maxAge = 75,
		baseChance = 0.25,  -- CRITICAL FIX: Reduced from 0.55 to prevent car event spam
		cooldown = 5, -- CRITICAL FIX: Increased to space out commute events
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "commute", "traffic", "work" },
		requiresJob = true,
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true },  -- CRITICAL FIX: Can't commute from prison!
		
		-- CRITICAL FIX #4: Daily car commute requires owning a car!
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Check car-related flags
			if flags.has_car or flags.owns_car or flags.has_vehicle or flags.has_first_car then
				return true
			end
			-- Check Assets.Vehicles
			if state.Assets and state.Assets.Vehicles then
				if type(state.Assets.Vehicles) == "table" and #state.Assets.Vehicles > 0 then
					return true
				end
			end
			return false, "Need a car to drive to work"
		end,
		
		-- CRITICAL FIX #1013: Added more choice options!
		choices = {
			{
				text = "Hit the road",
				effects = {},
				feedText = "On your way...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						if state.ModifyStat then state:ModifyStat("Happiness", 3) end
						if state.AddFeed then state:AddFeed("🚗 Smooth commute! Made great time! Good tunes!") end
					elseif roll < 0.70 then
						if state.ModifyStat then state:ModifyStat("Happiness", 1) end
						if state.AddFeed then state:AddFeed("🚗 Normal commute. Not bad, not great.") end
					elseif roll < 0.90 then
						if state.ModifyStat then state:ModifyStat("Happiness", -4) end
						if state.AddFeed then state:AddFeed("🚗 Traffic nightmare! Late to work! Stressed!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -6) end
						state.Money = math.max(0, (state.Money or 0) - 50)
						if state.AddFeed then state:AddFeed("🚗 Fender bender! Minor accident. Insurance claim incoming.") end
					end
				end,
			},
			{
				text = "Leave extra early",
				effects = { Happiness = 2 },
				feedText = "🚗 Beat the traffic! Arrived early and relaxed!",
			},
			{
				text = "Call in - work from home today",
				effects = { Happiness = 3 },
				feedText = "🚗 Stayed home instead. No commute stress!",
			},
		},
	},
	{
		id = "daily_public_transit",
		title = "Public Transit Commute",
		emoji = "🚌",
		text = "Taking public transit today!",
		question = "How is the transit experience?",
		minAge = 16, maxAge = 90,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "transit", "commute", "public" },
		blockedByFlags = { in_prison = true, incarcerated = true },  -- CRITICAL FIX: Can't take transit from prison!
		
		-- CRITICAL FIX #1014: Added more choice options!
		choices = {
			{
				text = "Ride the bus/train",
				effects = {},
				feedText = "On public transit...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 1)
						state:AddFeed("🚌 Got a seat! Read a book! Productive commute!")
					elseif roll < 0.65 then
						state:ModifyStat("Happiness", 1)
						state:AddFeed("🚌 Standing room only. Made it. Normal transit day.")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🚌 Delayed! Crowded! Someone smells bad! Misery.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🚌 Missed the bus/train! Had to wait forever! Late!")
					end
				end,
			},
			{
				text = "Take an Uber instead ($15)",
				effects = { Money = -15, Happiness = 3 },
				feedText = "🚌 Skipped the bus. Comfortable ride in an Uber!",
				eligibility = function(state) return (state.Money or 0) >= 15, "Can't afford Uber" end,
			},
			{
				text = "Walk/bike instead",
				effects = { Health = 3, Happiness = 2 },
				feedText = "🚌 Fresh air and exercise! Good for you!",
			},
		},
	},
	{
		id = "daily_working_from_home",
		title = "Working From Home",
		emoji = "💻",
		text = "Remote work day!",
		question = "How productive is your WFH day?",
		minAge = 20, maxAge = 75,
		baseChance = 0.35, -- CRITICAL FIX: Lowered from 0.55 to reduce spam
		cooldown = 6, -- CRITICAL FIX: Increased from 4 to reduce spam
		oneTime = false, -- Can happen multiple times
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "remote", "wfh", "work" },
		requiresJob = true,
		-- CRITICAL FIX: Only trigger if player actually works remotely!
		-- This was spamming for everyone with a job even if they're not remote workers
		-- Check for ANY remote work flag (different events set different flags)
		eligibility = function(state)
			local flags = state.Flags or {}
			if flags.works_from_home or flags.remote_worker or flags.hybrid_worker or flags.remote_approved then
				return true
			end
			return false, "You don't work remotely"
		end,
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true },
		
		-- CRITICAL: Random WFH productivity
		choices = {
			{
				text = "Focus and work hard",
				effects = {},
				feedText = "Working from the couch/desk...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.45 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.productive_remote_worker = true
						state:AddFeed("💻 Super productive WFH day! Got so much done!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("💻 Decent productivity. Some distractions but okay.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("💻 Distracted all day. Netflix won. Feel guilty.")
					end
				end,
			},
			{ text = "Work in pajamas", effects = { Happiness = 5, Health = 1 }, feedText = "💻 Cozy and productive! WFH life is best life!" },
			{ text = "Struggle with distractions", effects = { Happiness = -3, Smarts = -1 }, feedText = "💻 Home has too many temptations. Got nothing done." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- LUNCH & BREAKS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "daily_lunch_decision",
		title = "Lunch Break",
		emoji = "🥪",
		text = "Lunch time!",
		question = "What do you do for lunch?",
		minAge = 15, maxAge = 80,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "lunch", "break", "food" },
		
		choices = {
			{ text = "Packed lunch (saves money)", effects = { Health = 2, Happiness = 3, Money = 5 }, feedText = "🥪 Healthy and economical! Adult achievement!" },
			{ text = "Buy lunch ($15)", effects = { Happiness = 4, Money = -15, Health = -1 }, feedText = "🥪 Treating yourself! Restaurant/takeout life!", eligibility = function(state) return (state.Money or 0) >= 15, "💸 Need $15" end },
			{ text = "Skip lunch (busy)", effects = { Health = -3, Happiness = -2, Smarts = 1 }, feedText = "🥪 No time! Working through. Hangry later." },
			{ 
			-- CRITICAL FIX: Show price!
			text = "Social lunch with coworkers ($15)", 
			effects = { Happiness = 6, Money = -15 }, 
			feedText = "🥪 Great conversation! Work friendships building!",
			-- CRITICAL FIX #4: Check both job AND money!
			eligibility = function(state)
				if not state.CurrentJob then
					return false, "You don't have coworkers - you don't have a job!"
				end
				if (state.Money or 0) < 15 then
					return false, "💸 Need $15 for lunch"
				end
				return true
			end,
		},
		},
	},
	{
		id = "daily_afternoon_slump",
		title = "Afternoon Slump",
		emoji = "😴",
		text = "The 3pm slump is hitting hard!",
		question = "How do you power through?",
		minAge = 18, maxAge = 75,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "afternoon", "tired", "energy" },
		
		choices = {
			{ text = "Coffee/energy drink", effects = { Happiness = 3, Health = -1 }, feedText = "😴 Caffeine boost! Powered through! Crash later." },
			{ text = "Quick walk outside", effects = { Happiness = 4, Health = 3 }, feedText = "😴 Fresh air! Second wind! Natural energy!" },
			{ text = "Power through exhausted", effects = { Happiness = -3, Health = -2 }, feedText = "😴 Zombie mode. Clock watching. When is 5pm?" },
			{ text = "Give in and zone out", effects = { Happiness = 1 }, feedText = "😴 Staring at screen but brain is elsewhere. Survival." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EVENING EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "daily_after_work",
		title = "After Work",
		emoji = "🏠",
		text = "Workday is done! What now?",
		question = "How do you spend your evening?",
		minAge = 18, maxAge = 80,
		baseChance = 0.555,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "evening", "leisure", "home" },
		blockedByFlags = { in_prison = true, incarcerated = true, retired = true },  -- CRITICAL FIX: No "after work" in prison or retired!
		-- CRITICAL FIX: Requires having a job to have "after work" time
		eligibility = function(state)
			if not state.CurrentJob and not (state.Flags and state.Flags.employed) then
				return false, "You don't have work to be 'after'!"
			end
			return true
		end,
		
		choices = {
			{ text = "Exercise/gym ($5)", effects = { Health = 5, Happiness = 4, Money = -5 }, setFlags = { regular_exerciser = true }, feedText = "🏠 Post-work workout! Stress relief! Endorphins!", eligibility = function(state) return (state.Money or 0) >= 5, "💸 Need $5" end },
			{ text = "TV/streaming binge", effects = { Happiness = 5, Health = -1 }, feedText = "🏠 Decompressing with shows! Couch comfort!" },
			{ text = "Social plans ($30)", effects = { Happiness = 7, Money = -30, Health = -1 }, feedText = "🏠 Seeing friends! Good times! Social battery charging!", eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30" end },
			{ text = "Productive hobbies", effects = { Happiness = 6, Smarts = 2 }, feedText = "🏠 Working on projects! Creative outlet! Fulfilling!" },
			{ text = "Chores and responsibilities", effects = { Happiness = 2, Smarts = 1 }, feedText = "🏠 Adulting. Laundry, dishes, bills. Boring but necessary." },
		},
	},
	{
		id = "daily_dinner_prep",
		title = "Dinner Time",
		emoji = "🍽️",
		text = "What's for dinner?",
		question = "How do you handle dinner?",
		minAge = 15, maxAge = 100,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "dinner", "cooking", "food" },
		
		-- CRITICAL: Random dinner outcome
		choices = {
			{
				text = "Cook a nice meal ($15 groceries)",
				effects = { Money = -15 },
				feedText = "In the kitchen...",
				eligibility = function(state) return (state.Money or 0) >= 15, "Need $15 for ingredients" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Health", 3)
						state:AddFeed("🍽️ Delicious! Homemade goodness! Chef skills!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Health", 2)
						state:AddFeed("🍽️ Edible! Not gourmet but not bad!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🍽️ Burned it. Kitchen disaster. Ordering pizza.")
					end
				end,
			},
			{ text = "Order takeout/delivery ($25)", effects = { Happiness = 6, Money = -25, Health = -2 }, feedText = "🍽️ Easy and delicious! No dishes! Worth it!" },
			{ text = "Leftovers", effects = { Happiness = 3, Money = 0, Health = 1 }, feedText = "🍽️ Using what you have! Economical! Less waste!" },
			{ text = "Snacking instead of real meal", effects = { Happiness = 2, Health = -3 }, feedText = "🍽️ Chips and random stuff. Not a meal. Whatever." },
		},
	},
	{
		id = "daily_evening_relaxation",
		title = "Evening Wind Down",
		emoji = "🌙",
		text = "Time to relax for the evening!",
		question = "How do you wind down?",
		minAge = 12, maxAge = 100,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "evening", "relax", "unwind" },
		
		choices = {
			{ text = "Read a book", effects = { Happiness = 5, Smarts = 3, Health = 1 }, feedText = "🌙 Lost in a good book! Perfect evening!" },
			{ text = "Watch TV/movies", effects = { Happiness = 5, Health = -1 }, feedText = "🌙 Screen time relaxation! Mindless entertainment!" },
			{ 
			text = "Quality time with family/partner", 
			effects = { Happiness = 7 }, 
			feedText = "🌙 Connection time! Relationships matter!",
			-- CRITICAL FIX #2: Only show if player has family/partner
			eligibility = function(state)
				local flags = state.Flags or {}
				-- Check for partner/spouse
				if flags.married or flags.has_partner or flags.dating then
					return true
				end
				-- Check for children
				if flags.has_child or flags.parent then
					return true
				end
				-- Check Relationships table
				if state.Relationships then
					if state.Relationships.partner then return true end
					-- Check for any family relationships
					for _, rel in pairs(state.Relationships) do
						if type(rel) == "table" and (rel.type == "family" or rel.isFamily) then
							return true
						end
					end
				end
				return false, "Need family or partner for quality time"
			end,
		},
			{ text = "Scroll phone until sleep", effects = { Happiness = 2, Health = -2 }, setFlags = { phone_before_bed = true }, feedText = "🌙 Doomscrolling until eyes close. Not ideal but common." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SLEEP EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "daily_bedtime_routine",
		title = "Bedtime Routine",
		emoji = "😴",
		text = "Time for bed!",
		question = "How do you prepare for sleep?",
		minAge = 10, maxAge = 100,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "sleep", "bedtime", "routine" },
		
		-- CRITICAL: Random sleep quality
		choices = {
			{
				text = "Good sleep hygiene",
				effects = {},
				feedText = "Getting ready for quality sleep...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Health", 4)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.good_sleeper = true
						state:AddFeed("😴 Great sleep! Woke up refreshed! Sleep routine works!")
					else
						state:ModifyStat("Health", 2)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("😴 Decent sleep. Could be better but not bad.")
					end
				end,
			},
			{ text = "Late night screen time", effects = { Health = -2, Happiness = 1 }, feedText = "😴 Phone until late. Melatonin disrupted. Tired tomorrow." },
			{ text = "Anxiety keeping you up", effects = { Health = -3, Happiness = -4 }, setFlags = { sleep_anxiety = true }, feedText = "😴 Can't stop thinking. Racing mind. Exhausted but wired." },
			{ text = "Perfect 8 hours", effects = { Health = 5, Happiness = 5 }, feedText = "😴 PERFECT SLEEP! Full 8 hours! Rare achievement!" },
		},
	},
	{
		id = "daily_cant_sleep",
		title = "Can't Sleep",
		emoji = "🌙",
		text = "Lying awake at 2am...",
		question = "What do you do when you can't sleep?",
		minAge = 12, maxAge = 100,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "insomnia", "sleep", "night" },
		
		-- CRITICAL: Random insomnia night
		choices = {
			{
				text = "Try relaxation techniques",
				effects = {},
				feedText = "Breathing, counting sheep...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Health", 1)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🌙 Finally fell asleep! Techniques worked!")
					else
						state:ModifyStat("Health", -3)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🌙 Didn't work. Watched the ceiling until dawn.")
					end
				end,
			},
			{ text = "Get up and do something", effects = { Smarts = 2, Health = -2 }, feedText = "🌙 Read, cleaned, worked. Tired but productive." },
			{ text = "Lie there frustrated", effects = { Happiness = -5, Health = -4 }, feedText = "🌙 Tossed and turned. Angry at own brain. Exhausted." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- HOUSEHOLD EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "daily_household_chores",
		title = "Household Chores",
		emoji = "🧹",
		text = "Chores need doing!",
		question = "How do you handle chores?",
		minAge = 12, maxAge = 90,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "chores", "cleaning", "home" },
		
		choices = {
			{ text = "Get them all done", effects = { Happiness = 5, Health = 1, Smarts = 1 }, feedText = "🧹 Productive! Clean house! Adult accomplishment!" },
			{ text = "Do the bare minimum", effects = { Happiness = 2 }, feedText = "🧹 Did enough. Not spotless but livable." },
			{ text = "Procrastinate", effects = { Happiness = 3 }, setFlags = { messy_home = true }, feedText = "🧹 Future you problem. Present you is relaxing." },
			{ text = "Make it fun with music/podcast", effects = { Happiness = 6, Smarts = 2 }, feedText = "🧹 Cleaning dance party! Made it enjoyable!" },
		},
	},
	{
		id = "daily_laundry_day",
		title = "Laundry Day",
		emoji = "🧺",
		text = "Mountain of laundry to deal with!",
		question = "How do you tackle laundry?",
		minAge = 15, maxAge = 90,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "laundry", "chores", "home" },
		
		-- CRITICAL: Random laundry outcome
		choices = {
			{
				text = "Wash, dry, fold, put away",
				effects = {},
				feedText = "Full laundry cycle...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.has_clean_laundry = true
						state:AddFeed("🧺 All done! Clothes put away! Rare achievement!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🧺 Washed and dried. Folding? That's future you's problem.")
					else
						state:ModifyStat("Happiness", -3)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 30)
						state:AddFeed("🧺 Ruined a favorite piece! Shrank it! Laundry fail!")
					end
				end,
			},
			{ text = "Live out of the dryer", effects = { Happiness = 2 }, feedText = "🧺 Wrinkled but clean. Good enough system." },
			{ text = "Out of clean clothes crisis", effects = { Happiness = -4, Looks = -1 }, feedText = "🧺 Nothing clean! Emergency! Wearing questionable clothes!" },
		},
	},
	{
		id = "daily_grocery_shopping",
		title = "Grocery Shopping",
		emoji = "🛒",
		text = "Need groceries!",
		question = "How does grocery shopping go?",
		minAge = 16, maxAge = 90,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "groceries", "shopping", "food" },
		blockedByFlags = { in_prison = true, incarcerated = true },  -- CRITICAL FIX: Can't shop in prison!
		
		-- CRITICAL: Random grocery outcome
		choices = {
			{
				text = "Stick to the list ($50)",
				effects = { Money = -50 },
				feedText = "Shopping strategically...",
				eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need at least $50 for groceries" end,
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🛒 Mission accomplished! Budget kept! Well stocked!")
					else
						state:ModifyStat("Happiness", 3)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 20)
						state:AddFeed("🛒 Mostly stuck to list. Few impulse buys. Not bad.")
					end
				end,
			},
			{ text = "Impulse buy everything ($100)", effects = { Happiness = 5, Money = -100, Health = -1 }, feedText = "🛒 Bought ALL THE THINGS! Budget destroyed! No regrets?",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Can't afford impulse shopping ($100 needed)" end,
			},
			{ text = "Shop hungry ($80)", effects = { Happiness = 2, Money = -80 }, feedText = "🛒 Mistake. Bought so much junk. Why did you shop hungry?",
				eligibility = function(state) return (state.Money or 0) >= 80, "💸 Not enough for hungry shopping ($80 needed)" end,
			},
			{ text = "Skip it - eat what's at home", effects = { Happiness = -2, Health = -1 }, feedText = "🛒 Making do with what's in the pantry. Creative meals ahead." },
		},
	},
	{
		id = "daily_package_delivery",
		title = "Package Arrived!",
		emoji = "📦",
		text = "Your package has arrived!",
		question = "What's in the box?",
		minAge = 12, maxAge = 100,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "package", "delivery", "shopping" },
		
		-- CRITICAL: Random package outcome
		choices = {
			{
				text = "Open it excitedly",
				effects = {},
				feedText = "Tearing open the box...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("📦 LOVE IT! Exactly what you wanted! Happy purchase!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("📦 It's fine. Met expectations. Nothing special.")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📦 Not as expected. Disappointment. Returns?")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📦 WRONG ITEM! Or damaged! Contacting customer service!")
					end
				end,
			},
		},
	},
	{
		id = "daily_neighbors_noise",
		title = "Neighbor Noise",
		emoji = "🔊",
		text = "Neighbors are being noisy!",
		question = "How do you handle the noise?",
		minAge = 18, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "daily",
		tags = { "noise", "neighbors", "conflict" },
		-- CRITICAL FIX #9: Need a home to have neighbors!
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true, living_in_car = true, couch_surfing = true },
		
		-- CRITICAL FIX #9: Require housing for neighbor events
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Check for housing
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
			return false, "Need a home to have neighbors"
		end,
		
		-- CRITICAL: Random noise resolution
		choices = {
			{
				text = "Ask them nicely to quiet down",
				effects = {},
				feedText = "Knocking on their door...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🔊 They apologized! Noise stopped! Crisis averted!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 1)
						state:AddFeed("🔊 Awkward exchange but they quieted down somewhat.")
					else
						state:ModifyStat("Happiness", -4)
						state.Flags = state.Flags or {}
						state.Flags.neighbor_conflict = true
						state:AddFeed("🔊 They were rude about it! Neighborhood tension!")
					end
				end,
			},
			{ text = "Passive-aggressive notes", effects = { Happiness = 1 }, feedText = "🔊 Left a note. Feel petty but righteous." },
			{ text = "Endure it", effects = { Happiness = -4, Health = -1 }, feedText = "🔊 Suffering in silence. Annoying but non-confrontational." },
			{ text = "Call noise complaint", effects = { Happiness = -2 }, setFlags = { called_on_neighbors = true }, feedText = "🔊 Escalated. Relations with neighbors damaged." },
		},
	},
}

return DailyLifeEvents
