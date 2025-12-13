--[[
	MafiaSystem.lua
	
	Organized crime/Mafia system for BitLife-style game.
	Allows players to join crime families and rise through the ranks.
	
	REQUIRES: Mafia gamepass (ID: 1626238769)
	
	CRITICAL FIX #101: This is the CANONICAL mafia module
	CRITICAL FIX #241: Removed duplicate MobSystem.lua (was identical copy)
	
	NOTE: The old MobSystem.lua was an exact duplicate of this file.
	All mafia/mob functionality should use this MafiaSystem module.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MafiaSystem = {}
MafiaSystem.__index = MafiaSystem

-- ════════════════════════════════════════════════════════════════════════════
-- CRIME FAMILY DEFINITIONS
-- ════════════════════════════════════════════════════════════════════════════

MafiaSystem.Families = {
	italian = {
		id = "italian",
		name = "Italian Mafia",
		fullName = "La Cosa Nostra",
		emoji = "🇮🇹",
		description = "The traditional organized crime family. Honor, loyalty, and family above all.",
		color = Color3.fromRGB(239, 68, 68),
		colorDark = Color3.fromRGB(185, 28, 28),
		ranks = {
			{ id = "associate", name = "Associate", level = 1, respect = 0, emoji = "👤" },
			{ id = "soldier", name = "Soldier", level = 2, respect = 100, emoji = "🔫" },
			{ id = "capo", name = "Caporegime", level = 3, respect = 500, emoji = "💰" },
			{ id = "underboss", name = "Underboss", level = 4, respect = 2000, emoji = "🎩" },
			{ id = "boss", name = "Boss", level = 5, respect = 10000, emoji = "👑" },
		},
		operations = {
			{ id = "protection", name = "Protection Racket", emoji = "🛡️", risk = 20, reward = { min = 500, max = 2000 }, respect = 5, description = "Collect envelopes from local businesses.", rankRequired = 1, category = "income" },
			{ id = "numbers", name = "Numbers Game", emoji = "🎲", risk = 25, reward = { min = 1200, max = 4000 }, respect = 8, description = "Rig a neighborhood lottery.", rankRequired = 1, category = "income" },
			{ id = "gambling", name = "Run Gambling Ring", emoji = "🎰", risk = 30, reward = { min = 1000, max = 5000 }, respect = 10, description = "Operate an underground casino night.", rankRequired = 2, category = "income" },
			{ id = "loan_shark", name = "Shylock Loans", emoji = "💵", risk = 35, reward = { min = 3000, max = 12000 }, respect = 18, description = "Collect interest from desperate borrowers.", rankRequired = 2, category = "finance" },
			{ id = "smuggling", name = "Smuggle Goods", emoji = "📦", risk = 40, reward = { min = 2000, max = 10000 }, respect = 20, description = "Sneak contraband through the docks.", rankRequired = 3, category = "logistics" },
			{ id = "heist", name = "Plan a Heist", emoji = "🏦", risk = 60, reward = { min = 10000, max = 100000 }, respect = 50, description = "Coordinate a high-stakes robbery.", rankRequired = 4, category = "score" },
			{ id = "silencer", name = "Silence a Witness", emoji = "🎯", risk = 80, reward = { min = 5000, max = 25000 }, respect = 100, description = "Make sure someone can't testify.", rankRequired = 5, category = "enforcement" },
		},
		initiation = "You must prove your loyalty by completing a task for the family.",
	},
	
	russian = {
		id = "russian",
		name = "Russian Bratva",
		fullName = "Bratva (The Brotherhood)",
		emoji = "🇷🇺",
		description = "The ruthless eastern European syndicate. Strength and fear are your weapons.",
		color = Color3.fromRGB(59, 130, 246),
		colorDark = Color3.fromRGB(29, 78, 216),
		ranks = {
			{ id = "shestyorka", name = "Shestyorka", level = 1, respect = 0, emoji = "👤" },
			{ id = "bratok", name = "Bratok", level = 2, respect = 100, emoji = "🔫" },
			{ id = "brigadier", name = "Brigadier", level = 3, respect = 500, emoji = "💰" },
			{ id = "avtoritet", name = "Avtoritet", level = 4, respect = 2000, emoji = "🎩" },
			{ id = "pakhan", name = "Pakhan", level = 5, respect = 10000, emoji = "👑" },
		},
		operations = {
			{ id = "intimidation", name = "Street Intimidation", emoji = "🤐", risk = 25, reward = { min = 800, max = 3000 }, respect = 8, description = "Shake down kiosks for protection cash.", rankRequired = 1, category = "income" },
			{ id = "black_market", name = "Black Market Deal", emoji = "🛰️", risk = 35, reward = { min = 2000, max = 9000 }, respect = 15, description = "Move counterfeit goods through the ports.", rankRequired = 1, category = "logistics" },
			{ id = "cyber", name = "Cyber Crime", emoji = "💻", risk = 30, reward = { min = 2000, max = 20000 }, respect = 15, description = "Deploy a ransomware payload.", rankRequired = 2, category = "tech" },
			{ id = "weapons", name = "Arms Dealing", emoji = "🔫", risk = 45, reward = { min = 3000, max = 15000 }, respect = 25, description = "Broker a weapons shipment.", rankRequired = 3, category = "logistics" },
			{ id = "ransom", name = "High-Value Ransom", emoji = "💼", risk = 70, reward = { min = 15000, max = 75000 }, respect = 60, description = "Grab a VIP and negotiate ransom.", rankRequired = 4, category = "score" },
			{ id = "enforcer_hit", name = "Enforcer Job", emoji = "🕶️", risk = 85, reward = { min = 10000, max = 50000 }, respect = 120, description = "Handle a problem for the boss.", rankRequired = 5, category = "enforcement" },
		},
		initiation = "To join the Bratva, you must show no fear. Complete an act of violence.",
	},
	
	yakuza = {
		id = "yakuza",
		name = "Japanese Yakuza",
		fullName = "The Yamaguchi-gumi",
		emoji = "🇯🇵",
		description = "Honor and tradition guide the way. The path of the samurai lives on.",
		color = Color3.fromRGB(139, 92, 246),
		colorDark = Color3.fromRGB(109, 40, 217),
		ranks = {
			{ id = "shatei", name = "Shatei", level = 1, respect = 0, emoji = "👤" },
			{ id = "wakashu", name = "Wakashu", level = 2, respect = 100, emoji = "🔫" },
			{ id = "shateigashira", name = "Shateigashira", level = 3, respect = 500, emoji = "💰" },
			{ id = "wakagashira", name = "Wakagashira", level = 4, respect = 2000, emoji = "🎩" },
			{ id = "oyabun", name = "Oyabun", level = 5, respect = 10000, emoji = "👑" },
		},
		operations = {
			{ id = "pachinko", name = "Pachinko Parlors", emoji = "🎰", risk = 15, reward = { min = 1000, max = 5000 }, respect = 8, description = "Siphon coins from arcades.", rankRequired = 1, category = "income" },
			{ id = "night_market", name = "Night Market Fees", emoji = "🀄", risk = 20, reward = { min = 1500, max = 6000 }, respect = 10, description = "Tax the street vendors.", rankRequired = 1, category = "income" },
			{ id = "blackmail", name = "Corporate Blackmail", emoji = "📂", risk = 35, reward = { min = 5000, max = 25000 }, respect = 20, description = "Leak photos unless they pay.", rankRequired = 2, category = "finance" },
			{ id = "construction", name = "Construction Bid Rigging", emoji = "🏗️", risk = 25, reward = { min = 3000, max = 15000 }, respect = 15, description = "Control major contracts.", rankRequired = 3, category = "logistics" },
			{ id = "art_smuggling", name = "Art Smuggling", emoji = "🖼️", risk = 45, reward = { min = 7000, max = 30000 }, respect = 35, description = "Move stolen art overseas.", rankRequired = 4, category = "logistics" },
			{ id = "international_smuggling", name = "International Smuggling", emoji = "🚢", risk = 75, reward = { min = 20000, max = 100000 }, respect = 80, description = "Massive contraband operation overseas.", rankRequired = 5, category = "score" },
			{ id = "yubitsume", name = "Enforce Loyalty", emoji = "🩸", risk = 50, reward = { min = 0, max = 0 }, respect = 150, description = "Make an example with yubitsume.", rankRequired = 5, category = "discipline" },
		},
		initiation = "You must get the traditional irezumi tattoo and swear the oath of loyalty.",
	},
	
	cartel = {
		id = "cartel",
		name = "Mexican Cartel",
		fullName = "El Cartel de Sinaloa",
		emoji = "🇲🇽",
		description = "Control the smuggling empire. Money flows like water, but so does blood.",
		color = Color3.fromRGB(34, 197, 94),
		colorDark = Color3.fromRGB(22, 163, 74),
		ranks = {
			{ id = "halcon", name = "Halcon", level = 1, respect = 0, emoji = "👤" },
			{ id = "sicario", name = "Sicario", level = 2, respect = 100, emoji = "🔫" },
			{ id = "lugarteniente", name = "Lugarteniente", level = 3, respect = 500, emoji = "💰" },
			{ id = "capo", name = "Capo", level = 4, respect = 2000, emoji = "🎩" },
			{ id = "jefe", name = "El Jefe", level = 5, respect = 10000, emoji = "👑" },
		},
		operations = {
			{ id = "lookout", name = "Lookout Duty", emoji = "👀", risk = 10, reward = { min = 200, max = 800 }, respect = 3, description = "Watch the border crossings.", rankRequired = 1, category = "support" },
			{ id = "mule_run", name = "Courier Run", emoji = "🧳", risk = 25, reward = { min = 2000, max = 7000 }, respect = 10, description = "Move product across town.", rankRequired = 1, category = "logistics" },
			{ id = "transport", name = "Cargo Transport", emoji = "🚛", risk = 40, reward = { min = 5000, max = 20000 }, respect = 20, description = "Escort a major shipment.", rankRequired = 2, category = "logistics" },
			{ id = "production", name = "Run Operations", emoji = "⚗️", risk = 50, reward = { min = 10000, max = 50000 }, respect = 35, description = "Oversee the production facility.", rankRequired = 3, category = "finance" },
			{ id = "distribution", name = "Distribution Network", emoji = "📦", risk = 35, reward = { min = 8000, max = 30000 }, respect = 25, description = "Expand the regional network.", rankRequired = 4, category = "logistics" },
			{ id = "facility_expansion", name = "Facility Expansion", emoji = "🏭", risk = 55, reward = { min = 12000, max = 60000 }, respect = 40, description = "Build a new hidden facility.", rankRequired = 4, category = "finance" },
			{ id = "territorial", name = "Territory Takeover", emoji = "🌎", risk = 90, reward = { min = 25000, max = 150000 }, respect = 100, description = "Seize a rival's territory.", rankRequired = 5, category = "enforcement" },
		},
		initiation = "Prove yourself by making a successful run across the border.",
	},
	
	triad = {
		id = "triad",
		name = "Chinese Triad",
		fullName = "The 14K Triad",
		emoji = "🇨🇳",
		description = "The Heaven and Earth Society. Ancient traditions meet modern crime.",
		color = Color3.fromRGB(249, 115, 22),
		colorDark = Color3.fromRGB(194, 65, 12),
		ranks = {
			{ id = "lantern", name = "Blue Lantern", level = 1, respect = 0, emoji = "👤" },
			{ id = "fortyNiner", name = "49er", level = 2, respect = 100, emoji = "🔫" },
			{ id = "redPole", name = "Red Pole", level = 3, respect = 500, emoji = "💰" },
			{ id = "deputy", name = "Deputy", level = 4, respect = 2000, emoji = "🎩" },
			{ id = "dragonHead", name = "Dragon Head", level = 5, respect = 10000, emoji = "👑" },
		},
		operations = {
			{ id = "counterfeiting", name = "Counterfeit Bills", emoji = "💷", risk = 25, reward = { min = 1500, max = 6000 }, respect = 10, description = "Print stacks of fake cash.", rankRequired = 1, category = "income" },
			{ id = "piracy", name = "Software Piracy", emoji = "💾", risk = 20, reward = { min = 2000, max = 10000 }, respect = 8, description = "Duplicate movies and games.", rankRequired = 1, category = "tech" },
			{ id = "loan_sharking", name = "Loan Sharking", emoji = "📉", risk = 30, reward = { min = 3000, max = 12000 }, respect = 15, description = "Collect brutal interest payments.", rankRequired = 2, category = "finance" },
			{ id = "nightclub_take", name = "Nightclub Takeover", emoji = "🎤", risk = 35, reward = { min = 5000, max = 22000 }, respect = 22, description = "Seize control of a nightclub.", rankRequired = 3, category = "violence" },
			{ id = "smuggling", name = "Smuggling Ring", emoji = "🚢", risk = 55, reward = { min = 15000, max = 60000 }, respect = 40, description = "Move contraband along the coast.", rankRequired = 4, category = "logistics" },
			{ id = "ritual", name = "Blood Oath Ceremony", emoji = "🩸", risk = 40, reward = { min = 0, max = 0 }, respect = 200, description = "Enforce loyalty through ritual.", rankRequired = 5, category = "discipline" },
		},
		initiation = "You must undergo the traditional 36 oaths ceremony and blood oath.",
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #319: OPERATION SCENARIOS - Choice-based events for immersive gameplay
-- Each operation can have multiple scenario steps with branching choices
-- ════════════════════════════════════════════════════════════════════════════

MafiaSystem.OperationScenarios = {
	-- STREET INTIMIDATION (Bratva)
	intimidation = {
		{
			id = "intimidation_approach",
			title = "🤐 STREET INTIMIDATION",
			text = "The Bratva needs you to collect 'protection money' from local businesses. You approach a small electronics kiosk run by an older man.",
			choices = {
				{
					text = "Walk up calmly and explain the 'arrangement'",
					successMod = 1.1,
					riskMod = 0.8,
					next = "intimidation_negotiate",
				},
				{
					text = "Bring a baseball bat and look menacing",
					successMod = 1.0,
					riskMod = 1.2,
					rewardMod = 1.2,
					next = "intimidation_force",
				},
				{
					text = "Wait until closing time to approach",
					successMod = 1.2,
					riskMod = 0.6,
					next = "intimidation_private",
				},
			},
		},
		{
			id = "intimidation_negotiate",
			title = "💬 THE NEGOTIATION",
			text = "The shop owner looks nervous. He says he can't afford protection money - business has been slow.",
			choices = {
				{
					text = "Lower the amount, keep him as a regular payer",
					successMod = 1.1,
					riskMod = 0.7,
					rewardMod = 0.6,
					final = true,
				},
				{
					text = "Insist on the full amount or there'll be problems",
					successMod = 0.9,
					riskMod = 1.1,
					final = true,
				},
				{
					text = "Offer 'protection' services - you'll watch out for his shop",
					successMod = 1.3,
					riskMod = 0.5,
					rewardMod = 0.8,
					final = true,
				},
			},
		},
		{
			id = "intimidation_force",
			title = "👊 SHOW OF FORCE",
			text = "You smash a display case to make your point. The owner's hands are shaking as he reaches for his cash register.",
			choices = {
				{
					text = "Take what he gives and leave quickly",
					successMod = 1.0,
					riskMod = 1.0,
					rewardMod = 0.9,
					final = true,
				},
				{
					text = "Demand everything in the register",
					successMod = 0.7,
					riskMod = 1.5,
					rewardMod = 1.4,
					final = true,
				},
				{
					text = "Stop - apologize and set up a reasonable payment plan",
					successMod = 1.2,
					riskMod = 0.6,
					rewardMod = 0.5,
					respectBonus = 5, -- Shows restraint
					final = true,
				},
			},
		},
		{
			id = "intimidation_private",
			title = "🌙 AFTER HOURS",
			text = "The shop is closed. The owner is alone, counting the day's earnings. He looks up, startled.",
			choices = {
				{
					text = "Introduce yourself professionally as 'local security'",
					successMod = 1.2,
					riskMod = 0.5,
					final = true,
				},
				{
					text = "Block the door and make your demands clear",
					successMod = 1.0,
					riskMod = 1.0,
					rewardMod = 1.1,
					final = true,
				},
			},
		},
	},
	
	-- BLACK MARKET DEAL
	black_market = {
		{
			id = "black_market_contact",
			title = "🛰️ BLACK MARKET DEAL",
			text = "A contact has a shipment of counterfeit electronics that need to move through the port. You need to handle the logistics.",
			choices = {
				{
					text = "Bribe the dock workers to look the other way",
					successMod = 1.2,
					riskMod = 0.7,
					costMod = 0.15, -- 15% of potential reward as bribe
					next = "black_market_delivery",
				},
				{
					text = "Use a front company's shipping containers",
					successMod = 1.1,
					riskMod = 0.8,
					next = "black_market_delivery",
				},
				{
					text = "Move the goods at night through the back entrance",
					successMod = 0.9,
					riskMod = 1.2,
					next = "black_market_risky",
				},
			},
		},
		{
			id = "black_market_delivery",
			title = "📦 THE DELIVERY",
			text = "The goods are ready to move. Your buyer is waiting at a warehouse across town. How do you transport them?",
			choices = {
				{
					text = "Rent a legitimate delivery truck with fake paperwork",
					successMod = 1.1,
					riskMod = 0.8,
					final = true,
				},
				{
					text = "Split into smaller packages across multiple cars",
					successMod = 1.2,
					riskMod = 0.6,
					rewardMod = 0.9, -- Extra logistics cost
					final = true,
				},
				{
					text = "One fast run with armed escort",
					successMod = 0.9,
					riskMod = 1.3,
					rewardMod = 1.0,
					final = true,
				},
			},
		},
		{
			id = "black_market_risky",
			title = "⚠️ COMPLICATIONS",
			text = "Security spotted movement near the port! They're doing a sweep.",
			choices = {
				{
					text = "Hide the goods and abort for tonight",
					successMod = 0.7,
					riskMod = 0.4,
					rewardMod = 0.0, -- No reward this time
					final = true,
				},
				{
					text = "Create a distraction and rush the goods through",
					successMod = 0.6,
					riskMod = 1.5,
					rewardMod = 1.0,
					final = true,
				},
				{
					text = "Bribe the security guard on the spot",
					successMod = 0.8,
					riskMod = 0.9,
					costMod = 0.25,
					final = true,
				},
			},
		},
	},
	
	-- CYBER CRIME
	cyber = {
		{
			id = "cyber_target",
			title = "💻 CYBER OPERATION",
			text = "The tech team has identified a vulnerable target - a regional hospital network. Ransomware could be devastating.",
			choices = {
				{
					text = "Target the hospital - maximum pressure for ransom",
					successMod = 1.0,
					riskMod = 1.5, -- High heat
					rewardMod = 1.5,
					next = "cyber_execution",
				},
				{
					text = "Switch to a less sensitive target - a logistics company",
					successMod = 1.2,
					riskMod = 0.7,
					rewardMod = 0.8,
					next = "cyber_execution",
				},
				{
					text = "Cryptocurrency exchange hack instead - higher skill needed",
					successMod = 0.7,
					riskMod = 1.0,
					rewardMod = 2.0, -- High reward if successful
					next = "cyber_execution",
				},
			},
		},
		{
			id = "cyber_execution",
			title = "🖥️ DEPLOYING PAYLOAD",
			text = "The malware is ready. Your hacker is waiting for the go-ahead.",
			choices = {
				{
					text = "Execute now during business hours",
					successMod = 1.0,
					riskMod = 1.1,
					final = true,
				},
				{
					text = "Wait until Friday night - IT staff will be minimal",
					successMod = 1.3,
					riskMod = 0.8,
					final = true,
				},
				{
					text = "Deploy and immediately demand ransom",
					successMod = 0.9,
					riskMod = 1.2,
					rewardMod = 1.1,
					final = true,
				},
			},
		},
	},
	
	-- ARMS DEALING
	weapons = {
		{
			id = "weapons_source",
			title = "🔫 ARMS DEAL",
			text = "A shipment of military-grade weapons needs to move from the supplier to your buyer. The Bratva is counting on you.",
			choices = {
				{
					text = "Meet the supplier alone to inspect the merchandise",
					successMod = 1.0,
					riskMod = 1.1,
					next = "weapons_transfer",
				},
				{
					text = "Send trusted soldiers to verify and transport",
					successMod = 1.1,
					riskMod = 0.9,
					next = "weapons_transfer",
				},
				{
					text = "Arrange simultaneous exchange at neutral location",
					successMod = 1.2,
					riskMod = 0.7,
					costMod = 0.1, -- Extra logistics
					next = "weapons_transfer",
				},
			},
		},
		{
			id = "weapons_transfer",
			title = "📦 THE HANDOFF",
			text = "The weapons are ready. Your buyer's men are approaching the meeting point.",
			choices = {
				{
					text = "Show the merchandise, get the cash, professional handoff",
					successMod = 1.1,
					riskMod = 0.8,
					final = true,
				},
				{
					text = "Demand payment first before revealing location",
					successMod = 1.0,
					riskMod = 1.0,
					rewardMod = 1.1,
					final = true,
				},
				{
					text = "Keep some weapons as 'insurance' for future business",
					successMod = 0.9,
					riskMod = 1.2,
					rewardMod = 0.8,
					respectBonus = 10, -- Power move
					final = true,
				},
			},
		},
	},
	
	-- HIGH VALUE RANSOM
	ransom = {
		{
			id = "ransom_target",
			title = "💼 HIGH VALUE TARGET",
			text = "Intelligence has identified a wealthy businessman's son. The family is worth millions. This is your big score.",
			choices = {
				{
					text = "Grab him at the nightclub tonight",
					successMod = 1.0,
					riskMod = 1.2,
					next = "ransom_capture",
				},
				{
					text = "Pose as a taxi driver and pick him up",
					successMod = 1.2,
					riskMod = 0.8,
					next = "ransom_capture",
				},
				{
					text = "Infiltrate his security team first",
					successMod = 1.3,
					riskMod = 0.6,
					costMod = 0.15,
					next = "ransom_capture",
				},
			},
		},
		{
			id = "ransom_capture",
			title = "🚐 THE GRAB",
			text = "The target is in your van. He's scared but cooperating. Time to make the ransom demand.",
			choices = {
				{
					text = "Demand $500,000 in 48 hours",
					successMod = 1.1,
					riskMod = 0.9,
					next = "ransom_negotiate",
				},
				{
					text = "Demand $1 million - they can afford it",
					successMod = 0.8,
					riskMod = 1.2,
					rewardMod = 1.5,
					next = "ransom_negotiate",
				},
				{
					text = "Send a message with proof of life, negotiate from there",
					successMod = 1.2,
					riskMod = 0.7,
					next = "ransom_negotiate",
				},
			},
		},
		{
			id = "ransom_negotiate",
			title = "📞 THE NEGOTIATION",
			text = "The family wants to negotiate. They claim they can't pay the full amount immediately.",
			choices = {
				{
					text = "Accept their counter-offer - half now, half on release",
					successMod = 1.3,
					riskMod = 0.6,
					rewardMod = 0.7,
					final = true,
				},
				{
					text = "Hold firm - full amount or consequences",
					successMod = 0.8,
					riskMod = 1.4,
					final = true,
				},
				{
					text = "Demand crypto payment - harder to trace",
					successMod = 1.1,
					riskMod = 0.8,
					final = true,
				},
			},
		},
	},
	
	-- ENFORCER HIT
	enforcer_hit = {
		{
			id = "enforcer_briefing",
			title = "🕶️ ENFORCER JOB",
			text = "The boss has a problem that needs to disappear. A rival who's been causing trouble. This is a test of your loyalty.",
			choices = {
				{
					text = "Accept the job without question",
					successMod = 1.0,
					riskMod = 1.0,
					respectBonus = 20,
					next = "enforcer_method",
				},
				{
					text = "Ask for details about the target first",
					successMod = 1.1,
					riskMod = 0.9,
					next = "enforcer_method",
				},
				{
					text = "Request additional payment for the risk",
					successMod = 0.9,
					riskMod = 1.1,
					rewardMod = 1.3,
					next = "enforcer_method",
				},
			},
		},
		{
			id = "enforcer_method",
			title = "🎯 THE APPROACH",
			text = "You've tracked the target to his usual haunts. How do you want to handle this?",
			choices = {
				{
					text = "Quick and clean - professional hit",
					successMod = 1.0,
					riskMod = 1.0,
					final = true,
				},
				{
					text = "Make it look like an accident",
					successMod = 0.8,
					riskMod = 0.5,
					final = true,
				},
				{
					text = "Send a message to others - make it public",
					successMod = 1.0,
					riskMod = 1.8,
					respectBonus = 30,
					final = true,
				},
			},
		},
	},
	
	-- PROTECTION RACKET (Italian)
	protection = {
		{
			id = "protection_rounds",
			title = "🛡️ COLLECTION DAY",
			text = "It's time to make the rounds. Three businesses owe protection money this week. Where do you start?",
			choices = {
				{
					text = "Start with the restaurant - they always pay",
					successMod = 1.2,
					riskMod = 0.6,
					rewardMod = 0.8,
					final = true,
				},
				{
					text = "Go to the struggling deli - they're behind on payments",
					successMod = 0.9,
					riskMod = 0.9,
					rewardMod = 0.7,
					final = true,
				},
				{
					text = "Hit the new jewelry store - time to expand",
					successMod = 0.8,
					riskMod = 1.2,
					rewardMod = 1.3,
					final = true,
				},
			},
		},
	},
	
	-- GAMBLING RING (Italian)
	gambling = {
		{
			id = "gambling_setup",
			title = "🎰 CASINO NIGHT",
			text = "You're running tonight's underground poker game. High rollers are expected. How do you want to play it?",
			choices = {
				{
					text = "Run it straight - house edge is enough",
					successMod = 1.2,
					riskMod = 0.6,
					rewardMod = 0.8,
					final = true,
				},
				{
					text = "Rig a few games for big winners who complain",
					successMod = 1.0,
					riskMod = 1.0,
					rewardMod = 1.1,
					final = true,
				},
				{
					text = "Let a VIP win big - he'll bring more whales next time",
					successMod = 1.1,
					riskMod = 0.7,
					rewardMod = 0.5,
					respectBonus = 15, -- Long-term thinking
					final = true,
				},
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- MOB STATE (per player)
-- ════════════════════════════════════════════════════════════════════════════

MafiaSystem.DefaultMobState = {
	inMob = false,
	familyId = nil,
	rankIndex = 1,
	respect = 0,
	notoriety = 0, -- Police awareness
	kills = 0,
	earnings = 0,
	yearsInMob = 0,
	operationsCompleted = 0,
	operationsFailed = 0,
	betrayals = 0,
	loyalty = 100,
	territories = {},
	crew = {}, -- NPCs under your command
	heat = 0, -- Current wanted level
	lastEvent = nil,
}

-- ════════════════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem.new()
	local self = setmetatable({}, MafiaSystem)
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- MOB STATE MANAGEMENT
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:initMobState(lifeState)
	if not lifeState.MobState then
		lifeState.MobState = {}
		for k, v in pairs(self.DefaultMobState) do
			if type(v) == "table" then
				lifeState.MobState[k] = {}
			else
				lifeState.MobState[k] = v
			end
		end
	end
	return lifeState.MobState
end

function MafiaSystem:getMobState(lifeState)
	return self:initMobState(lifeState)
end

-- ════════════════════════════════════════════════════════════════════════════
-- JOIN/LEAVE MOB
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:canJoinMob(lifeState)
	local mobState = self:getMobState(lifeState)
	
	-- Already in a mob
	if mobState.inMob then
		return false, "You're already in a crime family!"
	end
	
	-- Age requirement
	if lifeState.Age < 18 then
		return false, "You must be at least 18 to join the mob."
	end
	
	-- Not in jail
	if lifeState.InJail then
		return false, "You can't join from jail!"
	end
	
	return true, nil
end

function MafiaSystem:joinFamily(lifeState, familyId)
	local canJoin, reason = self:canJoinMob(lifeState)
	if not canJoin then
		return false, reason
	end
	
	local family = self.Families[familyId]
	if not family then
		return false, "Unknown crime family."
	end
	
	local mobState = self:getMobState(lifeState)
	-- CRITICAL FIX #7: Set all state fields that client expects
	mobState.inMob = true
	mobState.familyId = familyId
	mobState.familyName = family.name
	mobState.familyEmoji = family.emoji
	mobState.rankIndex = 1
	mobState.rankLevel = 1
	mobState.rankName = family.ranks[1].name
	mobState.rankEmoji = family.ranks[1].emoji
	mobState.respect = 0
	mobState.loyalty = 100
	mobState.heat = 0
	mobState.yearsInMob = 0
	mobState.operationsCompleted = 0
	mobState.operationsFailed = 0
	mobState.earnings = 0
	mobState.kills = 0
	
	return true, "You've joined " .. family.name .. " as a " .. family.ranks[1].name .. "!"
end

function MafiaSystem:leaveFamily(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return false, "You're not in a crime family."
	end
	
	local family = self.Families[mobState.familyId]
	
	-- Leaving has consequences!
	local consequences = {}
	
	-- High rank = harder to leave
	if mobState.rankIndex >= 3 then
		-- Risk of being killed
		local deathRisk = mobState.rankIndex * 15
		if math.random(100) <= deathRisk then
			return false, "The family doesn't let high-ranking members leave alive... You've been eliminated!", { death = true }
		end
		table.insert(consequences, "A hit has been put out on you!")
	end
	
	-- Reset mob state
	mobState.inMob = false
	mobState.familyId = nil
	mobState.rankIndex = 1
	mobState.respect = 0
	mobState.loyalty = 0
	
	return true, "You've left " .. family.name .. ". Watch your back...", consequences
end

-- ════════════════════════════════════════════════════════════════════════════
-- OPERATIONS (Criminal Activities)
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:getAvailableOperations(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return {}
	end
	
	local family = self.Families[mobState.familyId]
	local available = {}
	
	-- Higher ranks unlock more operations
	local rankGate = mobState.rankIndex + 1
	for i, op in ipairs(family.operations) do
		local required = op.rankRequired or i
		if required <= rankGate then
			table.insert(available, op)
		end
	end
	
	return available
end

function MafiaSystem:doOperation(lifeState, operationId)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return false, "You're not in a crime family!", nil
	end
	
	if lifeState.InJail then
		return false, "You can't do operations from jail!", nil
	end
	
	local family = self.Families[mobState.familyId]
	local operation = nil
	
	for _, op in ipairs(family.operations) do
		if op.id == operationId then
			operation = op
			break
		end
	end
	
	if not operation then
		return false, "Unknown operation.", nil
	end
	
	-- Calculate success
	local baseChance = 100 - operation.risk
	local rankBonus = mobState.rankIndex * 5
	local successChance = math.min(95, baseChance + rankBonus)
	
	local roll = math.random(100)
	local success = roll <= successChance
	
	local result = {
		operation = operation.name,
		success = success,
		money = 0,
		respect = 0,
		heat = 0,
		message = "",
	}
	
	if success then
		-- Calculate rewards
		result.money = math.random(operation.reward.min, operation.reward.max)
		result.respect = operation.respect + math.random(0, 10)
		result.heat = math.floor(operation.risk / 10)
		
		-- Apply rewards
		lifeState.Money = (lifeState.Money or 0) + result.money
		mobState.respect = mobState.respect + result.respect
		mobState.heat = math.min(100, mobState.heat + result.heat)
		mobState.earnings = mobState.earnings + result.money
		mobState.operationsCompleted = mobState.operationsCompleted + 1
		
		result.message = string.format(
			"Operation successful! You earned $%s and gained %d respect.",
			self:formatMoney(result.money),
			result.respect
		)
		
		-- Check for rank up
		local rankUpMsg = self:checkRankUp(lifeState)
		if rankUpMsg then
			result.message = result.message .. "\n\n" .. rankUpMsg
			result.promoted = true
		end
	else
		-- Failed operation
		result.heat = math.floor(operation.risk / 5)
		mobState.heat = math.min(100, mobState.heat + result.heat)
		mobState.operationsFailed = mobState.operationsFailed + 1
		
		-- Risk of arrest
		local arrestChance = operation.risk / 2
		if math.random(100) <= arrestChance then
			local jailYears = math.ceil(operation.risk / 20)
			lifeState.InJail = true
			lifeState.JailYearsLeft = jailYears
			result.message = string.format(
				"Operation failed! You got caught and sentenced to %d years in prison!",
				jailYears
			)
			result.arrested = true
		else
			result.message = "Operation failed! You barely escaped, but the heat is on."
		end
	end
	
	return true, result.message, result
end

-- ════════════════════════════════════════════════════════════════════════════
-- RANK SYSTEM
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:getCurrentRank(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState or not mobState.inMob then
		return nil
	end
	
	-- CRITICAL FIX #121: Nil safety for family lookup
	local family = mobState.familyId and self.Families[mobState.familyId]
	if not family then
		return nil
	end
	
	-- CRITICAL FIX #122: Nil safety for rank index lookup
	local rankIndex = mobState.rankIndex or 1
	if not family.ranks or not family.ranks[rankIndex] then
		return nil
	end
	
	return family.ranks[rankIndex]
end

function MafiaSystem:getNextRank(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState or not mobState.inMob then
		return nil
	end
	
	-- CRITICAL FIX #123: Nil safety for family and ranks lookup
	local family = mobState.familyId and self.Families[mobState.familyId]
	if not family or not family.ranks then
		return nil
	end
	
	local rankIndex = mobState.rankIndex or 1
	if rankIndex >= #family.ranks then
		return nil -- Already at top
	end
	
	return family.ranks[rankIndex + 1]
end

function MafiaSystem:checkRankUp(lifeState)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return nil
	end
	
	local family = self.Families[mobState.familyId]
	local nextRank = self:getNextRank(lifeState)
	
	if not nextRank then
		return nil -- Already at top
	end
	
	if mobState.respect >= nextRank.respect then
		-- CRITICAL FIX #9: Update all rank fields for client consistency
		mobState.rankIndex = mobState.rankIndex + 1
		mobState.rankLevel = mobState.rankIndex
		mobState.rankName = nextRank.name
		mobState.rankEmoji = nextRank.emoji
		return string.format(
			"🎉 You've been promoted to %s %s!",
			nextRank.emoji,
			nextRank.name
		)
	end
	
	return nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- YEARLY UPDATE
-- ════════════════════════════════════════════════════════════════════════════

-- CRITICAL FIX #311-320: MAFIA HEAT AND RESPECT CALCULATION FIXES
function MafiaSystem:calculateHeat(lifeState, baseHeat, riskMod)
	local mobState = self:getMobState(lifeState)
	if not mobState then return baseHeat end
	
	-- Higher ranks attract more heat
	local rankMod = 1 + ((mobState.rankIndex or 1) * 0.1)
	-- More operations = more attention
	local opsMod = 1 + ((mobState.operationsCompleted or 0) * 0.01)
	-- Risk modifier from operation
	riskMod = riskMod or 1.0
	
	local finalHeat = math.floor(baseHeat * rankMod * opsMod * riskMod)
	return math.max(0, math.min(100, finalHeat))
end

function MafiaSystem:calculateRespect(baseRespect, mobState, successMod)
	if not mobState then return baseRespect end
	
	-- Loyalty bonus
	local loyaltyMod = 1 + ((mobState.loyalty or 100) / 500)
	-- Success modifier from operation
	successMod = successMod or 1.0
	-- Years in mob bonus
	local experienceMod = 1 + ((mobState.yearsInMob or 0) * 0.02)
	
	local finalRespect = math.floor(baseRespect * loyaltyMod * successMod * experienceMod)
	return math.max(0, finalRespect)
end

function MafiaSystem:addHeat(lifeState, amount)
	local mobState = self:getMobState(lifeState)
	if not mobState then return end
	
	mobState.heat = math.min(100, math.max(0, (mobState.heat or 0) + amount))
	
	-- High heat consequences
	if mobState.heat >= 80 then
		lifeState.Flags = lifeState.Flags or {}
		lifeState.Flags.high_heat = true
		lifeState.Flags.feds_watching = true
	elseif mobState.heat < 50 then
		if lifeState.Flags then
			lifeState.Flags.high_heat = nil
			lifeState.Flags.feds_watching = nil
		end
	end
end

function MafiaSystem:addRespect(lifeState, amount)
	local mobState = self:getMobState(lifeState)
	if not mobState then return end
	
	mobState.respect = math.max(0, (mobState.respect or 0) + amount)
	
	-- Check for rank up
	local rankUpMsg = self:checkRankUp(lifeState)
	return rankUpMsg
end

function MafiaSystem:onYearPass(lifeState)
	local mobState = self:getMobState(lifeState)
	local events = {}
	
	if not mobState.inMob then
		return events
	end
	
	mobState.yearsInMob = mobState.yearsInMob + 1
	
	-- CRITICAL FIX #321: Heat decays based on rank (bosses have more scrutiny)
	local baseDecay = 15 - (mobState.rankIndex or 1) * 2 -- Higher rank = slower decay
	mobState.heat = math.max(0, mobState.heat - math.max(5, baseDecay))
	
	-- Random mob events
	local roll = math.random(100)
	
	if roll <= 5 then
		-- Family war
		table.insert(events, {
			type = "war",
			message = "⚔️ Your family is at war with a rival organization!",
		})
	elseif roll <= 10 then
		-- Police crackdown
		if mobState.heat > 50 then
			table.insert(events, {
				type = "crackdown",
				message = "🚔 Police are cracking down on organized crime. Lay low!",
			})
			mobState.heat = math.min(100, mobState.heat + 20)
		end
	elseif roll <= 15 then
		-- Loyalty test
		table.insert(events, {
			type = "loyalty",
			message = "🤫 The family is testing your loyalty...",
		})
	elseif roll <= 20 then
		-- Tribute payment
		local tribute = math.floor(mobState.respect * 10)
		if lifeState.Money >= tribute then
			lifeState.Money = lifeState.Money - tribute
			mobState.loyalty = math.min(100, mobState.loyalty + 5)
			table.insert(events, {
				type = "tribute",
				message = string.format("💰 You paid $%s in tribute to the boss.", self:formatMoney(tribute)),
			})
		else
			mobState.loyalty = math.max(0, mobState.loyalty - 20)
			table.insert(events, {
				type = "tribute_failed",
				message = "😰 You couldn't pay tribute. The family is not pleased...",
			})
		end
	end
	
	-- Low loyalty consequences
	if mobState.loyalty < 30 then
		local betrayalChance = 100 - mobState.loyalty
		if math.random(100) <= betrayalChance / 2 then
			table.insert(events, {
				type = "betrayal",
				message = "⚠️ The family suspects you might be disloyal...",
			})
		end
	end
	
	if #events > 0 then
		mobState.lastEvent = events[#events].message
	end
	
	return events
end

-- ════════════════════════════════════════════════════════════════════════════
-- SERIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

-- CRITICAL FIX #322-330: ENHANCED SERIALIZATION WITH PROPER COLOR HANDLING
function MafiaSystem:serialize(lifeState)
	local mobState = self:getMobState(lifeState)
	
	-- CRITICAL FIX #14: Handle nil or empty mobState
	if not mobState or not mobState.inMob then
		return { 
			inMob = false,
			familyId = nil,
			familyName = nil,
			familyEmoji = nil,
			familyColor = nil,
			familyColorHex = nil,
			rankLevel = 1,
			rankName = nil,
			rankEmoji = nil,
			respect = 0,
			loyalty = 100,
			heat = 0,
			yearsInMob = 0,
			operationsCompleted = 0,
			operationsFailed = 0,
			earnings = 0,
			kills = 0,
			operations = {},
		}
	end
	
	local family = self.Families[mobState.familyId]
	if not family then
		return { inMob = false, operations = {} }
	end
	
	local currentRank = family.ranks[mobState.rankIndex or 1]
	local nextRank = self:getNextRank(lifeState)
	local operationsSummary = {}
	local rankGate = (mobState.rankIndex or 1) + 1
	for idx, op in ipairs(family.operations) do
		local required = op.rankRequired or idx
		if required <= rankGate then
			table.insert(operationsSummary, {
				id = op.id,
				name = op.name,
				emoji = op.emoji,
				description = op.description,
				category = op.category,
				risk = op.risk,
				respect = op.respect,
				minReward = op.reward.min,
				maxReward = op.reward.max,
				rankRequired = required,
				-- CRITICAL FIX #323: Add scenario flag for operations with scenarios
				hasScenarios = self:hasScenarios(op.id),
			})
		end
	end
	
	-- CRITICAL FIX #324: Properly serialize color for client
	local familyColorArray = nil
	local familyColorHex = nil
	local familyColorDark = nil
	
	if family.color then
		-- Serialize as array [R, G, B] values 0-1
		familyColorArray = { family.color.R, family.color.G, family.color.B }
		-- Also provide hex string for easier CSS usage
		familyColorHex = string.format("#%02X%02X%02X", 
			math.floor(family.color.R * 255),
			math.floor(family.color.G * 255),
			math.floor(family.color.B * 255))
	end
	if family.colorDark then
		familyColorDark = { family.colorDark.R, family.colorDark.G, family.colorDark.B }
	end
	
	-- CRITICAL FIX #325: Calculate progress to next rank
	local progressToNextRank = 0
	if nextRank then
		local currentRespect = mobState.respect or 0
		local currentRankRespect = currentRank.respect or 0
		local nextRankRespect = nextRank.respect or 100
		local needed = nextRankRespect - currentRankRespect
		local progress = currentRespect - currentRankRespect
		if needed > 0 then
			progressToNextRank = math.min(100, math.floor((progress / needed) * 100))
		end
	else
		progressToNextRank = 100 -- At max rank
	end
	
	return {
		inMob = true,
		familyId = mobState.familyId,
		familyName = family.name,
		familyFullName = family.fullName,
		familyEmoji = family.emoji,
		familyDescription = family.description,
		familyColor = familyColorArray,
		familyColorHex = familyColorHex,
		familyColorDark = familyColorDark,
		rankName = currentRank.name,
		rankEmoji = currentRank.emoji,
		rankLevel = mobState.rankIndex,
		maxRank = #family.ranks,
		respect = mobState.respect,
		respectDisplay = self:formatMoney(mobState.respect), -- CRITICAL FIX: Formatted display
		nextRankRespect = nextRank and nextRank.respect or nil,
		nextRankName = nextRank and nextRank.name or nil,
		progressToNextRank = progressToNextRank,
		notoriety = mobState.notoriety,
		heat = mobState.heat,
		heatLevel = mobState.heat >= 80 and "EXTREME" or (mobState.heat >= 60 and "HIGH" or (mobState.heat >= 40 and "MODERATE" or (mobState.heat >= 20 and "LOW" or "NONE"))),
		loyalty = mobState.loyalty,
		kills = mobState.kills,
		earnings = mobState.earnings,
		earningsDisplay = self:formatMoney(mobState.earnings),
		yearsInMob = mobState.yearsInMob,
		operationsCompleted = mobState.operationsCompleted,
		operationsFailed = mobState.operationsFailed or 0,
		lastEvent = mobState.lastEvent,
		operations = operationsSummary,
		-- CRITICAL FIX #326: Add flags for client to know player's status
		isBoss = mobState.rankIndex >= 5,
		isUnderboss = mobState.rankIndex >= 4,
		isCaptain = mobState.rankIndex >= 3,
		isMade = mobState.rankIndex >= 2,
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- UTILITIES
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:formatMoney(amount)
	if amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	else
		return tostring(amount)
	end
end

function MafiaSystem:getFamilyList()
	local list = {}
	for id, family in pairs(self.Families) do
		table.insert(list, {
			id = id,
			name = family.name,
			fullName = family.fullName,
			emoji = family.emoji,
			description = family.description,
			color = { family.color.R, family.color.G, family.color.B },
			colorDark = { family.colorDark.R, family.colorDark.G, family.colorDark.B },
		})
	end
	return list
end

-- CRITICAL FIX #13: Removed duplicate serialize function
-- The comprehensive serialize function is defined above (lines 558-610)

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #319: SCENARIO-BASED OPERATION SYSTEM
-- Returns scenario steps for immersive, choice-based operations
-- ════════════════════════════════════════════════════════════════════════════

function MafiaSystem:getOperationScenarios(operationId)
	return self.OperationScenarios[operationId]
end

function MafiaSystem:hasScenarios(operationId)
	return self.OperationScenarios[operationId] ~= nil
end

function MafiaSystem:getScenarioStep(operationId, stepId)
	local scenarios = self.OperationScenarios[operationId]
	if not scenarios then return nil end
	
	for _, step in ipairs(scenarios) do
		if step.id == stepId then
			return step
		end
	end
	
	-- Return first step if no ID matches
	return scenarios[1]
end

-- Process a scenario-based operation with accumulated modifiers
function MafiaSystem:doScenarioOperation(lifeState, operationId, accumulatedMods)
	local mobState = self:getMobState(lifeState)
	
	if not mobState.inMob then
		return false, "You're not in a crime family!", nil
	end
	
	if lifeState.InJail then
		return false, "You can't do operations from jail!", nil
	end
	
	local family = self.Families[mobState.familyId]
	local operation = nil
	
	for _, op in ipairs(family.operations) do
		if op.id == operationId then
			operation = op
			break
		end
	end
	
	if not operation then
		return false, "Unknown operation.", nil
	end
	
	-- Apply accumulated modifiers from scenario choices
	local mods = accumulatedMods or {}
	local successMod = mods.successMod or 1.0
	local riskMod = mods.riskMod or 1.0
	local rewardMod = mods.rewardMod or 1.0
	local costMod = mods.costMod or 0
	local respectBonus = mods.respectBonus or 0
	
	-- Calculate success with modifiers
	local baseChance = 100 - (operation.risk * riskMod)
	local rankBonus = mobState.rankIndex * 5
	local successChance = math.min(95, (baseChance + rankBonus) * successMod)
	
	local roll = math.random(100)
	local success = roll <= successChance
	
	local result = {
		operation = operation.name,
		operationEmoji = operation.emoji,
		success = success,
		money = 0,
		respect = 0,
		heat = 0,
		message = "",
		scenarioEvent = true, -- Flag for client to know this came from scenarios
	}
	
	if success then
		-- Calculate rewards with modifiers
		local baseReward = math.random(operation.reward.min, operation.reward.max)
		result.money = math.floor(baseReward * rewardMod * (1 - costMod))
		result.respect = math.floor((operation.respect + math.random(0, 10) + respectBonus) * successMod)
		result.heat = math.floor((operation.risk / 10) * riskMod)
		
		-- Apply rewards
		lifeState.Money = (lifeState.Money or 0) + result.money
		mobState.respect = mobState.respect + result.respect
		mobState.heat = math.min(100, mobState.heat + result.heat)
		mobState.earnings = mobState.earnings + result.money
		mobState.operationsCompleted = mobState.operationsCompleted + 1
		
		result.message = string.format(
			"%s Operation successful! You earned $%s and gained %d respect.",
			operation.emoji,
			self:formatMoney(result.money),
			result.respect
		)
		
		-- Check for rank up
		local rankUpMsg = self:checkRankUp(lifeState)
		if rankUpMsg then
			result.message = result.message .. "\n\n" .. rankUpMsg
			result.promoted = true
		end
	else
		-- Failed operation
		result.heat = math.floor((operation.risk / 5) * riskMod)
		mobState.heat = math.min(100, mobState.heat + result.heat)
		mobState.operationsFailed = mobState.operationsFailed + 1
		
		-- Risk of arrest based on modified risk
		local arrestChance = (operation.risk * riskMod) / 2
		if math.random(100) <= arrestChance then
			local jailYears = math.ceil((operation.risk * riskMod) / 20)
			lifeState.InJail = true
			lifeState.JailYearsLeft = jailYears
			result.message = string.format(
				"%s Operation failed! You got caught and sentenced to %d years!",
				operation.emoji,
				jailYears
			)
			result.arrested = true
		else
			result.message = string.format("%s Operation failed! You barely escaped, but the heat is on.", operation.emoji)
		end
	end
	
	return true, result.message, result
end

-- Generate an event card for mafia operations (for LifeClient to display)
function MafiaSystem:generateOperationEvent(lifeState, operationId)
	local mobState = self:getMobState(lifeState)
	if not mobState or not mobState.inMob then
		return nil
	end
	
	local scenarios = self:getOperationScenarios(operationId)
	if not scenarios or #scenarios == 0 then
		return nil
	end
	
	local firstStep = scenarios[1]
	local family = self.Families[mobState.familyId]
	
	-- Convert to event card format
	return {
		id = "mafia_op_" .. operationId,
		title = firstStep.title,
		emoji = (family and family.emoji) or "🔫",
		text = firstStep.text,
		isMafiaOperation = true,
		operationId = operationId,
		scenarioStepId = firstStep.id,
		choices = firstStep.choices,
		familyName = family and family.name,
		familyColor = family and { family.color.R, family.color.G, family.color.B },
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- SINGLETON INSTANCE
-- ════════════════════════════════════════════════════════════════════════════

local instance = MafiaSystem.new()

return instance
