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
	minAge = 18, maxAge = 75,
	-- CRITICAL FIX #HOMELESS-7: Increased baseChance from 0.7 to 0.95 for guaranteed trigger
	baseChance = 0.95,
	cooldown = 3,
	oneTime = true,
	-- CRITICAL FIX #HOMELESS-8: Made eligibility MUCH less strict!
	-- OLD: Required BOTH money < 200 AND no job (too strict - never triggered)
	-- NEW: Triggers if broke (< 500) OR unemployed for a while OR tracked as broke for 2+ years
	-- This ensures eviction actually happens when player is in financial trouble!
	eligibility = function(state)
		local money = state.Money or 0
		local hasJob = state.CurrentJob ~= nil
		local yearsBroke = (state.FinancialState and state.FinancialState.yearsBroke) or 0

		-- Trigger if any of these conditions:
		-- 1. Very broke (< 200) regardless of job
		-- 2. Moderately broke (< 500) AND no job
		-- 3. Been broke for 2+ years (tracked by FinancialState)
		-- 4. No money at all
		return money <= 0
			or (money < 200)
			or (money < 500 and not hasJob)
			or yearsBroke >= 2
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
			eligibility = function(state)
				return state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0
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
	baseChance = 0.85,
	cooldown = 1,
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
	baseChance = 0.85,
	cooldown = 1,
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
					state.Money = state.Money + bonus
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
	baseChance = 0.8,
	cooldown = 1,
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
	cooldown = 2,
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
	cooldown = 2,
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
	cooldown = 2,
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
	cooldown = 2,
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
	cooldown = 2,
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

return events
