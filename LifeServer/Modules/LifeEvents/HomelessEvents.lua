--[[
	HomelessEvents.lua
	
	Comprehensive homeless life events for BitLife-style gameplay.
	These events create a realistic and engaging homeless experience with:
	- Multiple paths to homelessness (eviction, addiction, bad luck, choice)
	- Survival challenges (food, shelter, safety)
	- Recovery opportunities (shelters, programs, kind strangers)
	- Street life experiences (panhandling, community, dangers)
	- Paths out of homelessness (jobs, programs, housing assistance)
	
	CRITICAL: Events check for homeless flag set by various circumstances
]]

local events = {}

-- ════════════════════════════════════════════════════════════════════════════
-- PATHS TO HOMELESSNESS
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "financial_crisis_eviction",
	title = "Financial Crisis",
	emoji = "💸",
	text = "You've fallen behind on rent for months. Today, the landlord arrived with an eviction notice and two police officers.",
	question = "You have 48 hours to leave. What do you do?",
	minAge = 21, maxAge = 75, -- CRITICAL FIX: Increased minAge to 21 - need time to establish housing
	-- CRITICAL FIX: Reduced baseChance - this was triggering way too often!
	baseChance = 0.5,
	cooldown = 5, -- CRITICAL FIX: Increased cooldown - eviction shouldn't happen every few years
	oneTime = true,
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: EVICTION REQUIRES PLAYER TO ACTUALLY HAVE THEIR OWN HOUSING!
	-- A player who just turned 18 and lives with parents should NOT get evicted!
	-- MUST meet ALL of these conditions:
	-- 1. Has moved out (has_own_place, moved_out, renting, has_apartment flags)
	-- 2. Been struggling financially for a while (yearsBroke >= 3 OR very low money + no job)
	-- 3. NOT still living with parents
	-- ═══════════════════════════════════════════════════════════════════════════════
	eligibility = function(state)
		local age = state.Age or 0
		local money = state.Money or 0
		local hasJob = state.CurrentJob ~= nil
		local flags = state.Flags or {}
		
		-- CRITICAL CHECK 1: Must be old enough to have established independent living
		if age < 21 then return false, "Too young to be evicted from own place" end
		
		-- CRITICAL CHECK 2: Must have THEIR OWN housing to be evicted from!
		-- If they haven't moved out or don't have their own place, they can't be evicted
		local hasOwnHousing = flags.moved_out 
			or flags.has_own_place 
			or flags.renting 
			or flags.has_apartment
			or flags.has_house
			or flags.homeowner
			or (state.HousingState and state.HousingState.status == "renter")
			or (state.HousingState and state.HousingState.status == "owner")
		
		-- If player has NO housing flags, they probably still live with parents
		-- In that case, they CANNOT be evicted!
		if not hasOwnHousing then
			return false, "Player doesn't have their own housing to be evicted from"
		end
		
		-- CRITICAL CHECK 3: Must be in financial distress for a LONG time
		local yearsBroke = (state.FinancialState and state.FinancialState.yearsBroke) or 0
		local missedRentYears = (state.HousingState and state.HousingState.missedRentYears) or 0
		
		-- Only evict if they've been struggling for 3+ years OR completely destitute
		local isDestitute = (money <= 0 and not hasJob)
		local longTermStruggle = yearsBroke >= 3 or missedRentYears >= 3
		local severeStruggle = (money < 500 and not hasJob and yearsBroke >= 2)
		
		return isDestitute or longTermStruggle or severeStruggle
	end,
	-- CRITICAL FIX #HOMELESS-9: Mark as high priority so it doesn't get lost in pool
	priority = "high",
	blockedByFlags = { homeless = true, in_prison = true, couch_surfing = true, living_in_car = true },
	
	choices = {
		{
			text = "Call family for help",
			effects = { Happiness = -10 },
			feedText = "Swallowing your pride, you reach out to family...",
			onResolve = function(state)
				if math.random() < 0.5 then
					state.Money = (state.Money or 0) + 800
					state:AddFeed("💕 Your family came through. They sent money for a deposit on a cheap place.")
				else
					state.Flags.homeless = true
					state.Flags.family_rejected_help = true
					state:ModifyStat("Happiness", -15)
					state:AddFeed("😢 No one could help. You're on the streets now.")
				end
			end,
		},
		{
			text = "Stay with a friend temporarily",
			effects = { Happiness = -5 },
			feedText = "You asked a friend if you could crash...",
			onResolve = function(state)
				if math.random() < 0.6 then
					state.Flags.couch_surfing = true
					state:AddFeed("🛋️ A friend let you stay on their couch. It's temporary, but it's something.")
				else
					state.Flags.homeless = true
					state:AddFeed("😔 No one had room. You spent your first night in a park.")
				end
			end,
		},
		{
			text = "Go to a homeless shelter",
			effects = { Happiness = -8, Health = 3 },
			setFlags = { homeless = true, using_shelter = true },
			feedText = "You found a local shelter with an open bed.",
		},
		{
			text = "Live in your car",
			effects = { Happiness = -12, Health = -5 },
			-- CRITICAL FIX: Return reason string when eligibility fails to prevent "unknown" reason
			eligibility = function(state)
				local hasVehicle = state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0
				if not hasVehicle then
					return false, "You don't have a car to live in"
				end
				return true
			end,
			setFlags = { living_in_car = true },
			feedText = "At least you have your car. You parked in a Walmart lot for the night.",
		},
		{
			text = "Accept it - hit the streets",
			effects = { Happiness = -20, Health = -10 },
			setFlags = { homeless = true },
			feedText = "You've become homeless. The streets are cold and unforgiving.",
		},
	},
}

events[#events + 1] = {
	id = "couch_surfing_ends",
	title = "Wearing Out Your Welcome",
	emoji = "🚪",
	text = "Your friend says you need to leave. You've been on their couch for weeks and they need their space back.",
	question = "Where do you go now?",
	minAge = 18, maxAge = 70,
	baseChance = 0.55, -- CRITICAL FIX: Reduced from 0.85 to prevent spam
	cooldown = 4, -- CRITICAL FIX: Increased from 1 to prevent spam
	category = "homeless", -- CRITICAL FIX: Proper category
	tags = { "homeless", "housing", "crisis" },
	requiresFlags = { couch_surfing = true },
	blockedByFlags = { homeless = true },
	
	choices = {
		{
			text = "Find another friend's couch",
			effects = { Happiness = -5 },
			feedText = "You called around looking for another place...",
			onResolve = function(state)
				if math.random() < 0.4 then
					state:AddFeed("🛋️ Another friend said yes, but this can't last forever.")
				else
					state.Flags.couch_surfing = nil
					state.Flags.homeless = true
					state:AddFeed("😔 Everyone's out of patience. You're truly homeless now.")
				end
			end,
		},
		{
			text = "Go to a shelter",
			effects = { Happiness = -10 },
			feedText = "You headed to a homeless shelter.",
			onResolve = function(state)
				state.Flags.couch_surfing = nil
				state.Flags.homeless = true
				state.Flags.using_shelter = true
			end,
		},
		{
			text = "Sleep rough - find a spot outside",
			effects = { Happiness = -15, Health = -10 },
			feedText = "You found an overpass that seemed safe enough...",
			onResolve = function(state)
				state.Flags.couch_surfing = nil
				state.Flags.homeless = true
				state.Flags.sleeping_rough = true
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- DAILY HOMELESS SURVIVAL EVENTS
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "homeless_morning",
	title = "Another Day",
	emoji = "🌅",
	text = "The sun rises on another day without a home. Your stomach growls and you need to figure out where your next meal is coming from.",
	question = "How do you start your day?",
	minAge = 18, maxAge = 80,
	baseChance = 0.5, -- CRITICAL FIX: Reduced from 0.85 to prevent spam
	cooldown = 3, -- CRITICAL FIX: Increased from 1 to prevent spam
	category = "homeless", -- CRITICAL FIX: Proper category
	tags = { "homeless", "survival", "daily" },
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Panhandle at an intersection",
			effects = { Happiness = -5, Looks = -2 },
			feedText = "You stood at a busy intersection with a sign...",
			onResolve = function(state)
				local earned = math.random(3, 45)
				state.Money = (state.Money or 0) + earned
				if math.random() < 0.1 then
					-- Someone was very generous
					local bonus = math.random(20, 100)
					state.Money = (state.Money or 0) + bonus  -- CRITICAL FIX: nil safety
					state:AddFeed(string.format("💰 Made $%d panhandling. Someone gave you an extra $%d!", earned, bonus))
				else
					state:AddFeed(string.format("💰 Made $%d panhandling today.", earned))
				end
			end,
		},
		{
			text = "Look for food in dumpsters",
			effects = { Happiness = -10, Health = -3, Looks = -3 },
			feedText = "Dumpster diving behind restaurants...",
			onResolve = function(state)
				if math.random() < 0.7 then
					state:AddFeed("🍕 Found some decent food. It's survival.")
				else
					state:ModifyStat("Health", -8)
					state:AddFeed("🤢 The food was bad. You got sick.")
				end
			end,
		},
		{
			text = "Go to a soup kitchen",
			effects = { Happiness = 2, Health = 5 },
			feedText = "You got a hot meal at the local soup kitchen.",
		},
		{
			text = "Try to find day labor work",
			effects = { Happiness = 3 },
			feedText = "You went to a spot where contractors pick up workers...",
			onResolve = function(state)
				if math.random() < 0.35 then
					local pay = math.random(50, 120)
					state.Money = (state.Money or 0) + pay
					state:ModifyStat("Happiness", 10)
					state:AddFeed(string.format("💪 Got day labor! Earned $%d cash.", pay))
				else
					state:AddFeed("😔 No work today. Too many people, not enough jobs.")
				end
			end,
		},
		{
			text = "Spend the day at the library",
			effects = { Happiness = 5, Smarts = 2 },
			feedText = "The library is warm, quiet, and has free internet.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_night",
	title = "Finding Shelter",
	emoji = "🌙",
	text = "Night is falling and you need somewhere to sleep. The temperature is dropping.",
	question = "Where do you sleep tonight?",
	minAge = 18, maxAge = 80,
	baseChance = 0.5, -- CRITICAL FIX: Reduced from 0.8 to prevent spam
	cooldown = 3, -- CRITICAL FIX: Increased from 1 to prevent spam
	category = "homeless", -- CRITICAL FIX: Proper category
	tags = { "homeless", "survival", "night" },
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true, using_shelter = true },
	
	choices = {
		{
			text = "Try to get a bed at a shelter",
			effects = { Happiness = 3, Health = 5 },
			feedText = "You headed to the homeless shelter...",
			onResolve = function(state)
				if math.random() < 0.7 then
					state.Flags.using_shelter = true
					state:AddFeed("🏠 Got a bed! A warm night's sleep.")
				else
					state:ModifyStat("Happiness", -10)
					state:AddFeed("😔 Shelter was full. Had to sleep outside.")
				end
			end,
		},
		{
			text = "Sleep under a bridge",
			effects = { Happiness = -8, Health = -5 },
			setFlags = { sleeping_rough = true },
			feedText = "You found a spot under a bridge with some cardboard.",
		},
		{
			text = "Find an abandoned building",
			effects = { Happiness = -5, Health = -3 },
			feedText = "You found an empty building to squat in...",
			onResolve = function(state)
				if math.random() < 0.2 then
					-- Cops found you
					state:AddFeed("🚔 Police kicked you out in the middle of the night.")
					state:ModifyStat("Happiness", -10)
				elseif math.random() < 0.15 then
					-- Dangerous encounter
					state:ModifyStat("Health", -15)
					state:AddFeed("😨 Someone else was there and things got violent.")
				else
					state:AddFeed("🏚️ Found a relatively safe corner to sleep in.")
				end
			end,
		},
		{
			text = "Stay awake all night (safer)",
			effects = { Happiness = -10, Health = -8 },
			feedText = "You walked around all night. Exhausted but safer.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_danger",
	title = "Street Danger",
	emoji = "⚠️",
	text = "Being homeless makes you vulnerable. Tonight, someone approaches you with bad intentions.",
	question = "How do you handle this?",
	minAge = 18, maxAge = 75,
	baseChance = 0.5,
	cooldown = 3, -- CRITICAL FIX: Increased from 2
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Run away",
			effects = { Happiness = -5 },
			feedText = "You ran as fast as you could...",
			onResolve = function(state)
				if math.random() < 0.8 then
					state:AddFeed("🏃 You got away safely.")
				else
					state:ModifyStat("Health", -20)
					state:AddFeed("😰 They caught up. You got hurt.")
				end
			end,
		},
		{
			text = "Stand your ground",
			effects = { Happiness = -3 },
			feedText = "You stood firm and faced them...",
			onResolve = function(state)
				if math.random() < 0.5 then
					state.Flags.street_tough = true
					state:AddFeed("💪 They backed off. You've earned some respect on the streets.")
				else
					state:ModifyStat("Health", -25)
					state:AddFeed("🤕 The confrontation went badly. You're hurt.")
				end
			end,
		},
		{
			text = "Call for help",
			effects = { Happiness = -2 },
			feedText = "You yelled for help...",
			onResolve = function(state)
				if math.random() < 0.6 then
					state:AddFeed("🗣️ Someone heard and the attacker fled.")
				else
					state:ModifyStat("Health", -15)
					state:AddFeed("😢 No one came. You got hurt before they left.")
				end
			end,
		},
		{
			text = "Give them what they want",
			effects = { Happiness = -15 },
			feedText = "You gave up your few possessions...",
			onResolve = function(state)
				local lost = math.min(state.Money or 0, math.random(10, 50))
				state.Money = math.max(0, (state.Money or 0) - lost)
				state:AddFeed(string.format("💸 You lost $%d, but you weren't hurt.", lost))
			end,
		},
	},
}

events[#events + 1] = {
	id = "homeless_weather",
	title = "Harsh Weather",
	emoji = "🌧️",
	text = "A severe weather event is hitting the city. It's dangerous to be outside.",
	question = "How do you stay safe?",
	minAge = 18, maxAge = 80,
	baseChance = 0.6,
	cooldown = 3, -- CRITICAL FIX: Increased from 2
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	textVariants = {
		"A major storm is rolling in. Rain, wind, possibly hail.",
		"Temperatures are dropping dangerously low tonight.",
		"A heat wave is making the city unbearable.",
		"Heavy snow is blanketing everything. It's freezing.",
	},
	
	choices = {
		{
			text = "Find emergency shelter",
			effects = { Happiness = 5, Health = 5 },
			feedText = "You found an emergency warming/cooling center.",
		},
		{
			text = "Tough it out",
			effects = { Happiness = -10, Health = -15 },
			feedText = "You survived, but barely...",
			onResolve = function(state)
				if math.random() < 0.15 then
					state:ModifyStat("Health", -30)
					state:AddFeed("🏥 You had to be taken to the hospital for exposure.")
				end
			end,
		},
		{
			text = "Sneak into a 24-hour store",
			effects = { Happiness = 2 },
			feedText = "You stayed in a Walmart until the weather passed.",
			onResolve = function(state)
				if math.random() < 0.3 then
					state:AddFeed("🚔 Security asked you to leave eventually.")
					state:ModifyStat("Happiness", -5)
				end
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- HOMELESS COMMUNITY AND SUPPORT
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "homeless_community",
	title = "Street Family",
	emoji = "🤝",
	text = "You've met other homeless people who look out for each other. They're inviting you to join their group.",
	question = "Do you join them?",
	minAge = 18, maxAge = 70,
	baseChance = 0.5,
	cooldown = 5,
	oneTime = true,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Join the group",
			effects = { Happiness = 10, Health = 5 },
			setFlags = { homeless_community = true, has_street_family = true },
			feedText = "You've found community on the streets. There's safety in numbers.",
		},
		{
			text = "Stay solo - trust no one",
			effects = { Happiness = -3 },
			setFlags = { lone_homeless = true },
			feedText = "You prefer to keep to yourself. Trust is hard.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_friendship",
	title = "A Friend on the Streets",
	emoji = "👥",
	text = "Another homeless person shares their food with you and tells you their story. You're not alone out here.",
	question = "How do you respond?",
	minAge = 18, maxAge = 80,
	baseChance = 0.6,
	cooldown = 3, -- CRITICAL FIX: Increased from 2
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Share your story too",
			effects = { Happiness = 8 },
			setFlags = { has_homeless_friend = true },
			feedText = "You made a real connection. A friend in hard times.",
		},
		{
			text = "Accept the food gratefully",
			effects = { Happiness = 5, Health = 3 },
			feedText = "You ate together in companionable silence.",
		},
		{
			text = "Keep your distance",
			effects = { Happiness = -3 },
			feedText = "You thanked them but stayed guarded.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_kindness",
	title = "Random Act of Kindness",
	emoji = "💕",
	text = "A stranger stops and really sees you. They want to help.",
	question = "They offer you...",
	minAge = 18, maxAge = 80,
	baseChance = 0.45,
	cooldown = 3,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "A hot meal and coffee",
			effects = { Happiness = 15, Health = 5 },
			feedText = "They bought you a real meal. It meant everything.",
		},
		{
			text = "Money and a kind word",
			effects = { Happiness = 12 },
			feedText = "They gave you cash and treated you like a human being.",
			onResolve = function(state)
				local amount = math.random(20, 100)
				state.Money = (state.Money or 0) + amount
				state:AddFeed(string.format("💵 They gave you $%d and said 'good luck'.", amount))
			end,
		},
		{
			text = "New clothes and toiletries",
			effects = { Happiness = 10, Looks = 8, Health = 3 },
			feedText = "Clean clothes and hygiene supplies. You feel human again.",
		},
		{
			text = "A job lead",
			effects = { Happiness = 20, Smarts = 3 },
			setFlags = { has_job_lead = true },
			feedText = "They told you about a place that's hiring and will give you a chance!",
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- RECOVERY AND GETTING OFF THE STREETS
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "homeless_social_worker",
	title = "Outreach Worker",
	emoji = "📋",
	text = "A social worker approaches you. They want to help you get off the streets.",
	question = "What services do they offer?",
	minAge = 18, maxAge = 70,
	baseChance = 0.4,
	cooldown = 4,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Transitional housing program",
			effects = { Happiness = 20, Health = 10 },
			feedText = "You're accepted into a housing program!",
			onResolve = function(state)
				if math.random() < 0.8 then
					state.Flags.homeless = nil
					state.Flags.in_transitional_housing = true
					state:AddFeed("🏠 You have a real roof over your head again!")
				else
					state:AddFeed("😔 The program waitlist is too long right now.")
				end
			end,
		},
		{
			text = "Job training and placement",
			effects = { Happiness = 15, Smarts = 5 },
			setFlags = { in_job_training = true },
			feedText = "You're enrolled in a job training program!",
		},
		{
			text = "Mental health and counseling",
			effects = { Happiness = 12, Health = 8 },
			setFlags = { getting_counseling = true },
			feedText = "You're getting help processing everything you've been through.",
		},
		{
			text = "Decline - not ready for help",
			effects = { Happiness = -5 },
			feedText = "You're not ready to trust the system yet.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_job_opportunity",
	title = "A Real Chance",
	emoji = "💼",
	text = "A local business owner sees you and offers you a job. They want to give you a chance to get back on your feet.",
	question = "Do you take it?",
	minAge = 18, maxAge = 60,
	baseChance = 0.3,
	cooldown = 5,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Accept gratefully",
			effects = { Happiness = 30, Health = 10 },
			feedText = "You have a job! This changes everything!",
			onResolve = function(state)
				-- Give them a basic job
				state.CurrentJob = {
					id = "entry_level_comeback",
					name = "General Worker",
					company = "Local Business",
					salary = 28000,
					yearsAtJob = 0,
				}
				state.Flags.employed = true
				state.Flags.has_job = true
				-- Give first paycheck advance
				state.Money = (state.Money or 0) + 500
				state:AddFeed("💼 They gave you a $500 advance. Time to rebuild!")
			end,
		},
		{
			text = "Accept but feel overwhelmed",
			effects = { Happiness = 15 },
			feedText = "You'll try, but it feels like a lot...",
			onResolve = function(state)
				state.CurrentJob = {
					id = "entry_level_comeback",
					name = "Part-time Worker",
					company = "Local Business",
					salary = 18000,
					yearsAtJob = 0,
				}
				state.Flags.employed = true
				state.Money = (state.Money or 0) + 200
			end,
		},
		{
			text = "Decline - too ashamed",
			effects = { Happiness = -10 },
			feedText = "You couldn't accept. The shame was too much.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_recovery_milestone",
	title = "Getting Back Up",
	emoji = "🌟",
	text = "You've been working hard to get off the streets. Things are looking up.",
	question = "What's your breakthrough?",
	minAge = 18, maxAge = 65,
	baseChance = 0.5,
	cooldown = 3,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	eligibility = function(state)
		-- Higher chance if they have any positive flags
		return state.Flags.in_job_training 
			or state.Flags.has_job_lead 
			or state.Flags.getting_counseling
			or state.Flags.using_shelter
	end,
	
	choices = {
		{
			text = "Found affordable housing",
			effects = { Happiness = 35, Health = 15 },
			feedText = "You found a place you can afford! A tiny apartment, but it's YOURS.",
			onResolve = function(state)
				state.Flags.homeless = nil
				state.Flags.has_apartment = true
				state.Flags.recovering_homeless = true
				state.Money = (state.Money or 0) - math.min(state.Money or 0, 400) -- First month deposit
				state:AddFeed("🏠 You're no longer homeless! The struggle continues, but you have a home.")
			end,
		},
		{
			text = "Got a steady job",
			effects = { Happiness = 30, Health = 10 },
			feedText = "You got hired! Regular income changes everything.",
			onResolve = function(state)
				state.CurrentJob = {
					id = "comeback_job",
					name = "Worker",
					company = "Fresh Start Inc.",
					salary = 30000,
					yearsAtJob = 0,
				}
				state.Flags.employed = true
				state.Flags.has_job = true
				state.Money = (state.Money or 0) + 300
			end,
		},
		{
			text = "Reconnected with family",
			effects = { Happiness = 25 },
			feedText = "Your family took you back in while you get on your feet.",
			onResolve = function(state)
				state.Flags.homeless = nil
				state.Flags.living_with_family = true
				state:AddFeed("💕 Family gave you another chance. Don't waste it.")
			end,
		},
	},
}

events[#events + 1] = {
	id = "homeless_windfall",
	title = "Unexpected Help",
	emoji = "🎁",
	text = "Something unexpected happens that could change your situation.",
	question = "What is it?",
	minAge = 18, maxAge = 75,
	baseChance = 0.25,
	cooldown = 5,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Found money on the street",
			effects = { Happiness = 15 },
			feedText = "You found cash that someone dropped!",
			onResolve = function(state)
				local amount = math.random(50, 300)
				state.Money = (state.Money or 0) + amount
				state:AddFeed(string.format("💵 Found $%d! This could be the start of getting back up.", amount))
			end,
		},
		{
			text = "A charity helped you",
			effects = { Happiness = 20, Health = 10 },
			feedText = "A local charity provided significant support.",
			onResolve = function(state)
				state.Money = (state.Money or 0) + 500
				state.Flags.charity_support = true
				state:AddFeed("🤝 They helped with first month's rent and essentials!")
			end,
		},
		{
			text = "Viral story - community support",
			effects = { Happiness = 30 },
			feedText = "Someone shared your story online and people wanted to help!",
			onResolve = function(state)
				local donations = math.random(500, 2000)
				state.Money = (state.Money or 0) + donations
				state.Flags.homeless = nil
				state.Flags.community_helped = true
				state:AddFeed(string.format("🌟 The community raised $%d for you! You're getting a fresh start!", donations))
			end,
		},
		{
			text = "Old friend recognized you",
			effects = { Happiness = 20 },
			feedText = "An old friend spotted you and insisted on helping.",
			onResolve = function(state)
				if math.random() < 0.7 then
					state.Flags.homeless = nil
					state.Flags.friend_helping = true
					state.Money = (state.Money or 0) + 400
					state:AddFeed("👥 They're letting you stay with them until you're stable.")
				else
					state.Money = (state.Money or 0) + 100
					state:AddFeed("👥 They gave you some money and their number. Progress!")
				end
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- LONG-TERM HOMELESS EXPERIENCES
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "homeless_health_crisis",
	title = "Health Emergency",
	emoji = "🏥",
	text = "Living on the streets has taken a toll on your health. You're not feeling well at all.",
	question = "What do you do?",
	minAge = 18, maxAge = 80,
	baseChance = 0.5,
	cooldown = 3, -- CRITICAL FIX: Increased from 2
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Go to the ER",
			effects = { Health = 20, Happiness = 5 },
			feedText = "The hospital can't turn you away. You got medical care.",
			onResolve = function(state)
				-- Medical debt
				state.Flags.has_medical_debt = true
				state:AddFeed("🏥 You're feeling better, but now you have medical bills...")
			end,
		},
		{
			text = "Find a free clinic",
			effects = { Health = 10, Happiness = 3 },
			feedText = "A free clinic helped you. Bless the volunteers.",
		},
		{
			text = "Try to tough it out",
			effects = { Health = -20, Happiness = -10 },
			feedText = "You tried to ignore it...",
			onResolve = function(state)
				if (state.Health or 50) < 30 then
					state:ModifyStat("Health", -15)
					state:AddFeed("⚠️ You collapsed. Someone called an ambulance.")
				end
			end,
		},
	},
}

events[#events + 1] = {
	id = "homeless_police_interaction",
	title = "Police Encounter",
	emoji = "🚔",
	text = "Police officers approach you. Being homeless isn't a crime, but they want you to move.",
	question = "How do you handle this?",
	minAge = 18, maxAge = 80,
	baseChance = 0.55,
	cooldown = 3, -- CRITICAL FIX: Increased from 2
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Comply and move along",
			effects = { Happiness = -5 },
			feedText = "You gathered your things and moved to another spot.",
		},
		{
			text = "Explain your situation politely",
			effects = { Happiness = -2 },
			feedText = "You were respectful and explained you had nowhere to go...",
			onResolve = function(state)
				if math.random() < 0.4 then
					state:AddFeed("👮 The officer was sympathetic and gave you info about local shelters.")
					state:ModifyStat("Happiness", 5)
				else
					state:AddFeed("👮 They still made you move, but didn't give you trouble.")
				end
			end,
		},
		{
			text = "Assert your rights",
			effects = { Happiness = -3 },
			feedText = "You stood your ground...",
			onResolve = function(state)
				if math.random() < 0.3 then
					-- Things escalated
					state.InJail = true
					state.JailYearsLeft = 0.1 -- Just overnight
					state.Flags.in_prison = true
					state.Flags.arrested_while_homeless = true
					state:AddFeed("🚔 They arrested you for 'disorderly conduct'. A night in jail.")
				else
					state:AddFeed("👮 They let it go, but told you not to be there tomorrow.")
				end
			end,
		},
	},
}

events[#events + 1] = {
	id = "homeless_pet",
	title = "Faithful Companion",
	emoji = "🐕",
	text = "A stray dog has been following you around. It seems to have adopted you.",
	question = "Do you keep it?",
	minAge = 18, maxAge = 75,
	baseChance = 0.35,
	cooldown = 10,
	oneTime = true,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true, has_street_dog = true },
	
	choices = {
		{
			text = "Keep the dog - you need a friend",
			effects = { Happiness = 20 },
			setFlags = { has_street_dog = true, has_pet = true },
			feedText = "You named them and now you're not alone. This dog is family.",
		},
		{
			text = "Find it a home - you can't care for it",
			effects = { Happiness = 5 },
			feedText = "You took it to a no-kill shelter. Responsible choice.",
		},
		{
			text = "Shoo it away",
			effects = { Happiness = -5 },
			feedText = "You don't have room for another mouth to feed.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_winter_survival",
	title = "Winter on the Streets",
	emoji = "❄️",
	text = "Winter is brutal when you're homeless. The cold is dangerous and shelters are overcrowded.",
	question = "How do you survive the season?",
	minAge = 18, maxAge = 80,
	baseChance = 0.7,
	cooldown = 3,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Camp out at warming centers",
			effects = { Happiness = 3, Health = 5 },
			feedText = "You spent the worst nights at emergency warming centers.",
		},
		{
			text = "Build a proper camp with insulation",
			effects = { Happiness = 5, Smarts = 3 },
			setFlags = { has_homeless_camp = true },
			feedText = "You learned survival skills and built a weatherproof spot.",
		},
		{
			text = "Ride public transit all night",
			effects = { Happiness = -5, Health = -3 },
			feedText = "You rode buses and trains in circles just to stay warm.",
		},
		{
			text = "Risk hypothermia outside",
			effects = { Health = -25, Happiness = -15 },
			feedText = "It was a brutal winter. You barely made it.",
			onResolve = function(state)
				if math.random() < 0.1 then
					state:ModifyStat("Health", -40)
					state:AddFeed("🏥 You nearly died. Paramedics found you and saved your life.")
				end
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #HOMELESS-10: ADDITIONAL HOMELESS EVENTS FOR VARIETY
-- User request: "fix HOMELESS EVENTS to work greatly"
-- Adding more diverse events for engagement
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "homeless_phone_theft",
	title = "Phone Stolen!",
	emoji = "📱",
	text = "Someone snatched your phone while you were sleeping! Without it, you can't look for jobs or stay connected.",
	question = "What do you do?",
	minAge = 18, maxAge = 70,
	baseChance = 0.4,
	cooldown = 4,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Use the library computers",
			effects = { Happiness = -5, Smarts = 3 },
			feedText = "The library becomes your lifeline. Free internet and a place to apply for jobs.",
		},
		{
			text = "Panhandle for a cheap phone",
			effects = { Happiness = -8 },
			feedText = "You're saving every penny for a cheap phone...",
			onResolve = function(state)
				if math.random() < 0.6 then
					state.Money = math.max(0, (state.Money or 0) - 30)
					state:AddFeed("📱 Got a cheap prepaid phone. Back in touch with the world!")
				else
					state:AddFeed("📱 Still saving. No phone yet.")
				end
			end,
		},
		{
			text = "Ask a charity for help",
			effects = { Happiness = 3 },
			feedText = "Some charities have phone programs...",
			onResolve = function(state)
				if math.random() < 0.5 then
					state.Flags.got_charity_phone = true
					state:AddFeed("📱 They had an Obama phone program! You got a free phone!")
				else
					state:AddFeed("📱 Waitlist too long. Keep trying.")
				end
			end,
		},
	},
}

events[#events + 1] = {
	id = "homeless_camp_cleared",
	title = "Camp Cleared Out",
	emoji = "🚧",
	text = "City workers are clearing out the area where you've been staying. Everything you owned is being thrown away.",
	question = "What do you do?",
	minAge = 18, maxAge = 80,
	baseChance = 0.5,
	cooldown = 3,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Try to save your belongings",
			effects = { Happiness = -10 },
			feedText = "You grabbed what you could...",
			onResolve = function(state)
				if math.random() < 0.6 then
					state:AddFeed("🎒 Saved your most important items. Lost the rest.")
				else
					state:AddFeed("🗑️ Lost everything. Starting over with nothing.")
					state:ModifyStat("Happiness", -15)
				end
			end,
		},
		{
			text = "Argue with the workers",
			effects = { Happiness = -8 },
			feedText = "You pleaded for more time...",
			onResolve = function(state)
				if math.random() < 0.3 then
					state:AddFeed("⏰ They gave you an extra hour. Managed to grab everything.")
				else
					if math.random() < 0.4 then
						state.Flags.arrested_homeless = true
						state:AddFeed("🚔 Police got involved. You were cited for obstruction.")
					else
						state:AddFeed("🗑️ They threw everything away anyway.")
					end
				end
			end,
		},
		{
			text = "Accept it and move on",
			effects = { Happiness = -15, Smarts = 2 },
			setFlags = { lost_everything = true },
			feedText = "You watched them throw away your few possessions. Time to start over.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_documentary",
	title = "Documentary Crew",
	emoji = "🎬",
	text = "A documentary crew is filming the homeless situation in your city. They want to interview you about your story.",
	question = "Do you participate?",
	minAge = 18, maxAge = 75,
	baseChance = 0.25,
	cooldown = 8,
	oneTime = true,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Tell your story",
			effects = { Happiness = 10 },
			feedText = "You shared your journey with the cameras...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.3 then
					-- Documentary gets attention
					local donations = math.random(1000, 5000)
					state.Money = (state.Money or 0) + donations
					state.Flags.documentary_famous = true
					state:AddFeed(string.format("🎬 Documentary aired! Viewers donated $%d to help you! You're getting a fresh start!", donations))
					state.Flags.homeless = nil
				elseif roll < 0.6 then
					state.Money = (state.Money or 0) + 200
					state:AddFeed("🎬 They paid you $200 for your time. Documentary airs next year.")
				else
					state:AddFeed("🎬 Powerful interview. It felt good to be heard.")
				end
			end,
		},
		{
			text = "Decline - privacy matters",
			effects = { Happiness = -3 },
			feedText = "You don't want your face out there. Too risky.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_stolen_from",
	title = "Robbed!",
	emoji = "💸",
	text = "Another homeless person stole the money you'd been saving. The little you had is gone.",
	question = "What do you do?",
	minAge = 18, maxAge = 75,
	baseChance = 0.45,
	cooldown = 3,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Confront them",
			effects = { Happiness = -5 },
			feedText = "You tracked them down...",
			onResolve = function(state)
				if math.random() < 0.3 then
					local recovered = math.random(10, 50)
					state.Money = (state.Money or 0) + recovered
					state:AddFeed(string.format("💪 Got $%d back! They won't mess with you again.", recovered))
				elseif math.random() < 0.5 then
					state:ModifyStat("Health", -15)
					state:AddFeed("🤕 Fight went badly. You're hurt.")
				else
					state:AddFeed("😤 They ran away. Money's gone.")
				end
			end,
		},
		{
			text = "Let it go - not worth it",
			effects = { Happiness = -10, Smarts = 3 },
			feedText = "Violence solves nothing. You'll earn it back.",
		},
		{
			text = "Report to street community",
			effects = { Happiness = -3 },
			feedText = "You told the others what happened...",
			onResolve = function(state)
				if state.Flags.homeless_community then
					state:AddFeed("🤝 Your street family handled it. The thief won't bother you again.")
					state:ModifyStat("Happiness", 5)
				else
					state:AddFeed("👤 Nobody seems to care. You're on your own.")
				end
			end,
		},
	},
}

events[#events + 1] = {
	id = "homeless_food_poisoning",
	title = "Bad Food",
	emoji = "🤢",
	text = "That food from the dumpster didn't agree with you. You're extremely sick.",
	question = "What do you do?",
	minAge = 18, maxAge = 80,
	baseChance = 0.4,
	cooldown = 3,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Rest and hydrate",
			effects = { Health = -10, Happiness = -8 },
			feedText = "You found water and rested...",
			onResolve = function(state)
				if math.random() < 0.7 then
					state:AddFeed("💧 Rough 24 hours but you pulled through.")
				else
					state:ModifyStat("Health", -15)
					state:AddFeed("🤢 Still feeling terrible. This is taking days to recover from.")
				end
			end,
		},
		{
			text = "Go to the ER",
			effects = { Health = 10, Happiness = -5 },
			feedText = "The hospital treated you.",
			onResolve = function(state)
				state.Flags.has_medical_debt = true
				state:AddFeed("🏥 IV fluids helped. More medical debt though.")
			end,
		},
		{
			text = "Ask the homeless community for help",
			effects = { Health = -5 },
			feedText = "Others on the street watched over you...",
			onResolve = function(state)
				if state.Flags.homeless_community then
					state:ModifyStat("Health", 10)
					state:AddFeed("🤝 Your street family took care of you. Brought water and stayed close.")
				else
					state:AddFeed("👤 No one to help. You suffered alone.")
					state:ModifyStat("Happiness", -10)
				end
			end,
		},
	},
}

events[#events + 1] = {
	id = "homeless_unexpected_inheritance",
	title = "Letter from the Past",
	emoji = "📨",
	text = "A lawyer tracked you down. A distant relative you barely knew passed away and left you something in their will!",
	question = "What did they leave you?",
	minAge = 25, maxAge = 75,
	baseChance = 0.1,
	cooldown = 20,
	oneTime = true,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "A small amount of money",
			effects = { Happiness = 30, Health = 10 },
			feedText = "It's not millions, but it's life-changing!",
			onResolve = function(state)
				local inheritance = math.random(2000, 8000)
				state.Money = (state.Money or 0) + inheritance
				state.Flags.homeless = nil
				state.Flags.got_inheritance = true
				state:AddFeed(string.format("💰 $%d inheritance! Enough for a fresh start! You're off the streets!", inheritance))
			end,
		},
	},
}

events[#events + 1] = {
	id = "homeless_mental_health_struggle",
	title = "Mental Health Crisis",
	emoji = "😰",
	text = "The stress of homelessness is overwhelming. You're struggling with depression and anxiety.",
	question = "How do you cope?",
	minAge = 18, maxAge = 80,
	baseChance = 0.55,
	cooldown = 3,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Seek free counseling",
			effects = { Happiness = 10, Health = 5 },
			setFlags = { getting_homeless_counseling = true },
			feedText = "You found a free mental health clinic. Talking helps.",
		},
		{
			text = "Find an AA/NA meeting",
			effects = { Happiness = 8 },
			feedText = "The fellowship provides support, regardless of your struggle.",
			onResolve = function(state)
				state.Flags.in_support_group = true
				state:AddFeed("🤝 The meetings give you structure and community. One day at a time.")
			end,
		},
		{
			text = "Self-medicate with substances",
			effects = { Happiness = 5, Health = -15 },
			feedText = "Temporary relief, long-term damage...",
			onResolve = function(state)
				if math.random() < 0.5 then
					state.Flags.substance_issues = true
					state:AddFeed("😔 You're developing a problem. This isn't solving anything.")
				end
			end,
		},
		{
			text = "Focus on survival - no time for feelings",
			effects = { Happiness = -10, Smarts = 2 },
			feedText = "You push it down and keep moving. Survival first.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_skills_teaching",
	title = "Sharing Knowledge",
	emoji = "📚",
	text = "A newly homeless person is struggling. They don't know how to survive on the streets.",
	question = "Do you help them?",
	minAge = 20, maxAge = 70,
	baseChance = 0.4,
	cooldown = 4,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Teach them survival skills",
			effects = { Happiness = 15, Smarts = 2 },
			feedText = "You showed them where to find food, shelter, and stay safe.",
			onResolve = function(state)
				state.Flags.street_mentor = true
				state:AddFeed("🤝 They were grateful. You found purpose in helping others.")
			end,
		},
		{
			text = "Point them to resources",
			effects = { Happiness = 8 },
			feedText = "You told them about shelters, soup kitchens, and programs.",
		},
		{
			text = "Everyone for themselves",
			effects = { Happiness = -5 },
			feedText = "You walked away. Can barely help yourself.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_shower_opportunity",
	title = "Chance to Get Clean",
	emoji = "🚿",
	text = "Staying clean when homeless is nearly impossible. But today you have an opportunity.",
	question = "How do you get clean?",
	minAge = 18, maxAge = 80,
	baseChance = 0.5,
	cooldown = 3, -- CRITICAL FIX: Increased from 2
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Shelter shower program",
			effects = { Happiness = 12, Looks = 8, Health = 5 },
			feedText = "The shelter has shower hours. You waited in line for an hour but it was worth it.",
		},
		{
			text = "Sneak into a gym",
			effects = { Happiness = 8, Looks = 5 },
			feedText = "You slipped into a gym...",
			onResolve = function(state)
				if math.random() < 0.8 then
					state:AddFeed("🚿 Hot shower! Feel human again.")
				else
					state:AddFeed("🚿 Got caught and kicked out, but you were already clean!")
				end
			end,
		},
		{
			text = "Use a public fountain",
			effects = { Happiness = 3, Looks = 3, Health = -3 },
			feedText = "It's cold and people stare, but you're somewhat cleaner.",
		},
		{
			text = "Skip it - not safe to be vulnerable",
			effects = { Happiness = -5, Looks = -5 },
			feedText = "You don't feel safe getting undressed anywhere. Another dirty day.",
		},
	},
}

events[#events + 1] = {
	id = "homeless_voucher_lottery",
	title = "Housing Voucher Lottery",
	emoji = "🏠",
	text = "The housing authority opened applications for Section 8 vouchers! Thousands apply for just a few spots.",
	question = "Do you apply?",
	minAge = 18, maxAge = 80,
	baseChance = 0.3,
	cooldown = 6,
	requiresFlags = { homeless = true },
	blockedByFlags = { in_prison = true },
	
	choices = {
		{
			text = "Apply immediately",
			effects = { Happiness = 5 },
			feedText = "You filled out the application and submitted it...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.15 then
					state.Flags.homeless = nil
					state.Flags.has_housing_voucher = true
					state.Flags.has_apartment = true
					state:AddFeed("🏠 YOU WON THE LOTTERY! Housing voucher approved! You're getting an apartment!")
					state:ModifyStat("Happiness", 40)
				elseif roll < 0.4 then
					state.Flags.on_housing_waitlist = true
					state:AddFeed("📋 On the waitlist! Could be months or years, but there's hope.")
				else
					state:AddFeed("😔 Application wasn't selected. Thousands of others in the same boat.")
				end
			end,
		},
		{
			text = "Don't bother - never win these",
			effects = { Happiness = -5 },
			feedText = "You missed the deadline. Maybe next time.",
		},
	},
}

return events
