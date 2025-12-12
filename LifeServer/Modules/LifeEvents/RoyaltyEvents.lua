--[[
	RoyaltyEvents.lua
	
	Comprehensive royalty system for BitLife-style game.
	Handles all aspects of royal life including:
	- Being born as prince/princess
	- Royal duties and responsibilities
	- Throne inheritance and succession
	- Royal scandals and drama
	- Abdication and exile
	- Royal marriages and alliances
	- State affairs and diplomacy
	
	REQUIRES: Royalty gamepass (ID: 1626378001)
	
	This is a PREMIUM feature - full 1000+ line implementation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoyaltyEvents = {}

-- ════════════════════════════════════════════════════════════════════════════
-- ROYAL COUNTRIES AND TITLES
-- ════════════════════════════════════════════════════════════════════════════

RoyaltyEvents.RoyalCountries = {
	{
		id = "uk",
		name = "United Kingdom",
		emoji = "🇬🇧",
		palace = "Buckingham Palace",
		currency = "GBP",
		titles = {
			male = { heir = "Prince", monarch = "King" },
			female = { heir = "Princess", monarch = "Queen" },
		},
		traditions = { "Trooping the Colour", "State Opening of Parliament", "Royal Ascot", "Garden Parties" },
		startingWealth = { min = 50000000, max = 500000000 },
	},
	{
		id = "spain",
		name = "Spain",
		emoji = "🇪🇸",
		palace = "Royal Palace of Madrid",
		currency = "EUR",
		titles = {
			male = { heir = "Príncipe", monarch = "Rey" },
			female = { heir = "Princesa", monarch = "Reina" },
		},
		traditions = { "La Pascua Militar", "Día de la Hispanidad", "Easter Celebrations" },
		startingWealth = { min = 30000000, max = 200000000 },
	},
	{
		id = "sweden",
		name = "Sweden",
		emoji = "🇸🇪",
		palace = "Stockholm Palace",
		currency = "SEK",
		titles = {
			male = { heir = "Prins", monarch = "Kung" },
			female = { heir = "Prinsessa", monarch = "Drottning" },
		},
		traditions = { "Nobel Prize Ceremony", "National Day", "Lucia Day" },
		startingWealth = { min = 20000000, max = 150000000 },
	},
	{
		id = "japan",
		name = "Japan",
		emoji = "🇯🇵",
		palace = "Imperial Palace",
		currency = "JPY",
		titles = {
			male = { heir = "Prince", monarch = "Emperor" },
			female = { heir = "Princess", monarch = "Empress" },
		},
		traditions = { "New Year Greeting", "Emperor's Birthday", "Cherry Blossom Viewing" },
		startingWealth = { min = 100000000, max = 800000000 },
	},
	{
		id = "monaco",
		name = "Monaco",
		emoji = "🇲🇨",
		palace = "Prince's Palace",
		currency = "EUR",
		titles = {
			male = { heir = "Prince", monarch = "Sovereign Prince" },
			female = { heir = "Princess", monarch = "Sovereign Princess" },
		},
		traditions = { "Monaco Grand Prix", "Rose Ball", "National Day" },
		startingWealth = { min = 200000000, max = 1000000000 },
	},
	{
		id = "saudi",
		name = "Saudi Arabia",
		emoji = "🇸🇦",
		palace = "Al-Yamamah Palace",
		currency = "SAR",
		titles = {
			male = { heir = "Prince", monarch = "King" },
			female = { heir = "Princess", monarch = "Queen" },
		},
		traditions = { "Eid Celebrations", "Camel Racing", "Falconry" },
		startingWealth = { min = 500000000, max = 5000000000 },
	},
	{
		id = "thailand",
		name = "Thailand",
		emoji = "🇹🇭",
		palace = "Grand Palace",
		currency = "THB",
		titles = {
			male = { heir = "Prince", monarch = "King" },
			female = { heir = "Princess", monarch = "Queen" },
		},
		traditions = { "Royal Ploughing Ceremony", "King's Birthday", "Coronation Day" },
		startingWealth = { min = 100000000, max = 600000000 },
	},
	{
		id = "morocco",
		name = "Morocco",
		emoji = "🇲🇦",
		palace = "Royal Palace of Rabat",
		currency = "MAD",
		titles = {
			male = { heir = "Prince", monarch = "King" },
			female = { heir = "Princess", monarch = "Queen" },
		},
		traditions = { "Throne Day", "Green March", "Youth Day" },
		startingWealth = { min = 80000000, max = 400000000 },
	},
	{
		id = "jordan",
		name = "Jordan",
		emoji = "🇯🇴",
		palace = "Al-Husseiniya Palace",
		currency = "JOD",
		titles = {
			male = { heir = "Prince", monarch = "King" },
			female = { heir = "Princess", monarch = "Queen" },
		},
		traditions = { "Independence Day", "King's Birthday", "Arab Revolt Day" },
		startingWealth = { min = 50000000, max = 300000000 },
	},
	{
		id = "belgium",
		name = "Belgium",
		emoji = "🇧🇪",
		palace = "Royal Palace of Brussels",
		currency = "EUR",
		titles = {
			male = { heir = "Prince", monarch = "King" },
			female = { heir = "Princess", monarch = "Queen" },
		},
		traditions = { "National Day", "King's Feast", "Te Deum" },
		startingWealth = { min = 25000000, max = 180000000 },
	},
	{
		id = "netherlands",
		name = "Netherlands",
		emoji = "🇳🇱",
		palace = "Royal Palace Amsterdam",
		currency = "EUR",
		titles = {
			male = { heir = "Prins", monarch = "Koning" },
			female = { heir = "Prinses", monarch = "Koningin" },
		},
		traditions = { "King's Day", "Prinsjesdag", "Liberation Day" },
		startingWealth = { min = 30000000, max = 200000000 },
	},
	{
		id = "norway",
		name = "Norway",
		emoji = "🇳🇴",
		palace = "Royal Palace Oslo",
		currency = "NOK",
		titles = {
			male = { heir = "Prins", monarch = "Kong" },
			female = { heir = "Prinsesse", monarch = "Dronning" },
		},
		traditions = { "Constitution Day", "Nobel Peace Prize", "Christmas Speech" },
		startingWealth = { min = 25000000, max = 150000000 },
	},
	{
		id = "denmark",
		name = "Denmark",
		emoji = "🇩🇰",
		palace = "Amalienborg Palace",
		currency = "DKK",
		titles = {
			male = { heir = "Prins", monarch = "Konge" },
			female = { heir = "Prinsesse", monarch = "Dronning" },
		},
		traditions = { "Queen's Birthday", "Constitution Day", "New Year's Address" },
		startingWealth = { min = 25000000, max = 150000000 },
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- ROYAL DUTIES - Things royals must do
-- ════════════════════════════════════════════════════════════════════════════

RoyaltyEvents.RoyalDuties = {
	-- CEREMONIAL DUTIES
	{
		id = "state_visit",
		name = "State Visit",
		emoji = "🤝",
		category = "diplomatic",
		description = "Welcome a foreign head of state",
		popularityEffect = { min = 2, max = 8 },
		wealthCost = 50000,
		minAge = 18,
		frequency = "yearly",
	},
	{
		id = "ribbon_cutting",
		name = "Ribbon Cutting Ceremony",
		emoji = "✂️",
		category = "ceremonial",
		description = "Open a new hospital, school, or building",
		popularityEffect = { min = 1, max = 5 },
		wealthCost = 5000,
		minAge = 10,
		frequency = "monthly",
	},
	{
		id = "charity_gala",
		name = "Host Charity Gala",
		emoji = "🎭",
		category = "charity",
		description = "Raise money for a good cause",
		popularityEffect = { min = 3, max = 10 },
		wealthCost = 100000,
		charityCost = 500000,
		minAge = 18,
		frequency = "quarterly",
	},
	{
		id = "military_parade",
		name = "Attend Military Parade",
		emoji = "🎖️",
		category = "military",
		description = "Review the troops and show national pride",
		popularityEffect = { min = 2, max = 6 },
		wealthCost = 10000,
		minAge = 16,
		frequency = "yearly",
	},
	{
		id = "parliament_opening",
		name = "State Opening of Parliament",
		emoji = "🏛️",
		category = "political",
		description = "Deliver the Speech from the Throne",
		popularityEffect = { min = 1, max = 5 },
		wealthCost = 25000,
		minAge = 21,
		requiresMonarch = true,
		frequency = "yearly",
	},
	{
		id = "diplomatic_reception",
		name = "Diplomatic Reception",
		emoji = "🍾",
		category = "diplomatic",
		description = "Host foreign ambassadors at the palace",
		popularityEffect = { min = 1, max = 4 },
		wealthCost = 75000,
		minAge = 21,
		frequency = "quarterly",
	},
	{
		id = "hospital_visit",
		name = "Hospital Visit",
		emoji = "🏥",
		category = "charity",
		description = "Visit sick children and wounded veterans",
		popularityEffect = { min = 3, max = 8 },
		wealthCost = 2000,
		minAge = 8,
		frequency = "monthly",
	},
	{
		id = "school_visit",
		name = "School Visit",
		emoji = "🏫",
		category = "education",
		description = "Inspire young students and promote education",
		popularityEffect = { min = 2, max = 6 },
		wealthCost = 3000,
		minAge = 12,
		frequency = "monthly",
	},
	{
		id = "knighting_ceremony",
		name = "Knighting Ceremony",
		emoji = "⚔️",
		category = "ceremonial",
		description = "Award knighthoods to deserving citizens",
		popularityEffect = { min = 2, max = 5 },
		wealthCost = 15000,
		minAge = 21,
		requiresMonarch = true,
		frequency = "quarterly",
	},
	{
		id = "royal_wedding_guest",
		name = "Attend Royal Wedding",
		emoji = "💒",
		category = "social",
		description = "Attend a royal wedding in another country",
		popularityEffect = { min = 1, max = 4 },
		wealthCost = 50000,
		minAge = 16,
		frequency = "rare",
	},
	{
		id = "environmental_campaign",
		name = "Environmental Campaign",
		emoji = "🌍",
		category = "charity",
		description = "Champion environmental causes",
		popularityEffect = { min = 2, max = 7 },
		wealthCost = 200000,
		minAge = 18,
		frequency = "yearly",
	},
	{
		id = "sports_event",
		name = "Sports Event Appearance",
		emoji = "🏆",
		category = "sports",
		description = "Present trophies at major sporting events",
		popularityEffect = { min = 2, max = 5 },
		wealthCost = 10000,
		minAge = 12,
		frequency = "quarterly",
	},
	{
		id = "arts_patronage",
		name = "Arts Patronage Event",
		emoji = "🎨",
		category = "culture",
		description = "Support the arts and attend exhibitions",
		popularityEffect = { min = 1, max = 4 },
		wealthCost = 25000,
		minAge = 16,
		frequency = "monthly",
	},
	{
		id = "religious_ceremony",
		name = "Religious Ceremony",
		emoji = "⛪",
		category = "religious",
		description = "Attend important religious services",
		popularityEffect = { min = 1, max = 3 },
		wealthCost = 5000,
		minAge = 10,
		frequency = "quarterly",
	},
	{
		id = "disaster_relief",
		name = "Disaster Relief Visit",
		emoji = "🆘",
		category = "emergency",
		description = "Visit areas affected by natural disasters",
		popularityEffect = { min = 5, max = 15 },
		wealthCost = 10000,
		donationAmount = 1000000,
		minAge = 16,
		frequency = "rare",
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- ROYAL SCANDALS - Bad things that can happen
-- ════════════════════════════════════════════════════════════════════════════

RoyaltyEvents.RoyalScandals = {
	{
		id = "affair_rumor",
		name = "Affair Rumors",
		emoji = "💔",
		severity = "medium",
		popularityLoss = { min = 10, max = 25 },
		description = "Tabloids publish rumors of a royal affair",
		canDeny = true,
		denySuccessChance = 40,
	},
	{
		id = "leaked_photos",
		name = "Leaked Private Photos",
		emoji = "📸",
		severity = "high",
		popularityLoss = { min = 15, max = 35 },
		description = "Private photos leaked to the press",
		canSue = true,
		sueSuccessChance = 60,
		suePayout = { min = 500000, max = 5000000 },
	},
	{
		id = "tax_evasion",
		name = "Tax Evasion Allegations",
		emoji = "💰",
		severity = "severe",
		popularityLoss = { min = 20, max = 40 },
		description = "Accused of hiding money in offshore accounts",
		canInvestigate = true,
		investigationCost = 1000000,
	},
	{
		id = "drunk_incident",
		name = "Drunken Public Incident",
		emoji = "🍺",
		severity = "medium",
		popularityLoss = { min = 8, max = 20 },
		description = "Caught intoxicated at a public event",
		canApologize = true,
		apologyRecovery = { min = 5, max = 15 },
	},
	{
		id = "political_comment",
		name = "Political Controversy",
		emoji = "🗣️",
		severity = "medium",
		popularityLoss = { min = 10, max = 25 },
		description = "Made controversial political statements",
		canRetract = true,
		retractRecovery = { min = 3, max = 10 },
	},
	{
		id = "servant_abuse",
		name = "Staff Mistreatment Claims",
		emoji = "😠",
		severity = "high",
		popularityLoss = { min = 15, max = 35 },
		description = "Former staff claim mistreatment",
		canSettle = true,
		settlementCost = { min = 500000, max = 2000000 },
	},
	{
		id = "racist_remark",
		name = "Racist Remark Scandal",
		emoji = "🤬",
		severity = "severe",
		popularityLoss = { min = 25, max = 50 },
		description = "Accused of making racist comments",
		canApologize = true,
		apologyRecovery = { min = 5, max = 15 },
		requiresRehab = true,
	},
	{
		id = "nazi_costume",
		name = "Offensive Costume",
		emoji = "👔",
		severity = "severe",
		popularityLoss = { min = 20, max = 45 },
		description = "Photographed wearing offensive costume",
		canApologize = true,
		apologyRecovery = { min = 3, max = 10 },
	},
	{
		id = "wedding_crash",
		name = "Wedding Drama",
		emoji = "💒",
		severity = "low",
		popularityLoss = { min = 3, max = 10 },
		description = "Minor incident at a royal wedding",
		autoRecover = true,
		recoveryTime = 2,
	},
	{
		id = "family_feud",
		name = "Family Feud Goes Public",
		emoji = "👨‍👩‍👧‍👦",
		severity = "high",
		popularityLoss = { min = 10, max = 30 },
		description = "Internal family disputes leaked to media",
		canReconcile = true,
		reconcileChance = 50,
	},
	{
		id = "hunting_controversy",
		name = "Hunting Controversy",
		emoji = "🦌",
		severity = "medium",
		popularityLoss = { min = 8, max = 20 },
		description = "Criticized for hunting endangered animals",
		canDonate = true,
		donationAmount = 500000,
		donationRecovery = { min = 5, max = 12 },
	},
	{
		id = "extravagant_spending",
		name = "Extravagant Spending",
		emoji = "💎",
		severity = "medium",
		popularityLoss = { min = 5, max = 15 },
		description = "Criticized for lavish spending during economic hardship",
		canDonate = true,
		donationAmount = 1000000,
		donationRecovery = { min = 3, max = 8 },
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- ROYAL LIFE EVENTS - Major life milestones for royals
-- ════════════════════════════════════════════════════════════════════════════

RoyaltyEvents.LifeEvents = {
	-- BIRTH AND CHILDHOOD
	{
		id = "royal_birth_announcement",
		title = "👶 Royal Birth Announcement",
		emoji = "👶",
		text = "The kingdom celebrates your birth! Crowds gather outside the palace, bells ring across the land, and congratulations pour in from around the world.",
		question = "How do you feel about your royal destiny?",
		minAge = 0,
		maxAge = 0,
		isRoyalOnly = true,
		isBirthEvent = true,
		choices = {
			{
				text = "Born to rule! (Embrace destiny)",
				effects = { Happiness = 10 },
				setFlags = { embraced_royalty = true, confident_royal = true },
				feed = "You were born to wear the crown!",
			},
			{
				text = "It's just a title... (Humble)",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { humble_royal = true },
				feed = "You were born with a humble spirit.",
			},
		},
	},
	{
		id = "royal_christening",
		title = "⛪ Royal Christening",
		emoji = "⛪",
		text = "Your christening ceremony is held at the Royal Chapel. World leaders and foreign royalty attend this grand occasion.",
		question = "The ceremony proceeds smoothly...",
		minAge = 0,
		maxAge = 1,
		isRoyalOnly = true,
		isMilestone = true,
		choices = {
			{
				text = "Sleep through the whole thing",
				effects = { Happiness = 5 },
				setFlags = { peaceful_baby = true },
				feed = "You slept peacefully through your christening.",
			},
			{
				text = "Cry during the ceremony",
				effects = { Happiness = -2 },
				setFlags = { fussy_baby = true },
				feed = "Your cries echoed through the chapel!",
			},
		},
	},
	{
		id = "first_public_appearance",
		title = "📸 First Public Appearance",
		emoji = "📸",
		-- CRITICAL FIX #102/#109: Use {{AGE}} placeholder instead of %d for dynamic text
		text = "At {{AGE}} years old, you make your first official public appearance. The world's media captures every moment as you wave to the crowds.",
		minAge = 3,
		maxAge = 5,
		isRoyalOnly = true,
		isMilestone = true,
		choices = {
			{
				text = "Wave enthusiastically to the crowd",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 5 },
				setFlags = { natural_public_speaker = true },
				feed = "The crowd loved your enthusiastic wave!",
			},
			{
				text = "Hide behind your parent shyly",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = 2 },
				setFlags = { shy_royal = true },
				feed = "You were adorably shy at your first appearance.",
			},
			{
				text = "Make a funny face at the cameras",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 3, scandals = 0 },
				setFlags = { playful_royal = true },
				feed = "Your funny face became a viral meme!",
			},
		},
	},
	{
		id = "royal_education_choice",
		title = "🎓 Royal Education",
		emoji = "🎓",
		text = "It's time to decide your education. Will you attend the prestigious royal academies or break tradition?",
		minAge = 6,
		maxAge = 8,
		isRoyalOnly = true,
		choices = {
			{
				text = "Attend Eton/exclusive boarding school",
				effects = { Smarts = 10, Happiness = -5 },
				setFlags = { elite_education = true, boarding_school = true },
				feed = "You enrolled at the most prestigious boarding school.",
			},
			{
				text = "Private tutors at the palace",
				effects = { Smarts = 8, Happiness = 5 },
				setFlags = { palace_educated = true, home_schooled = true },
				feed = "World-class tutors came to teach you at the palace.",
			},
			{
				text = "Public school (break tradition)",
				effects = { Smarts = 5, Happiness = 8 },
				royaltyEffect = { popularity = 10 },
				setFlags = { public_school_royal = true, common_touch = true },
				feed = "You made history by attending public school!",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #106/#118: ROYAL CHILDHOOD EVENTS (Ages 8-12)
	-- These events fill the gap between royal education and coming of age
	-- Without these, royal players had NO royal events from age 8 to 18!
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "royal_playmate",
		title = "👑 Royal Playmates",
		emoji = "👑",
		text = "As a young royal, you're surrounded by children from noble families. Who do you want to be friends with?",
		minAge = 8,
		maxAge = 12,
		isRoyalOnly = true,
		cooldown = 3,
		choices = {
			{
				text = "Play with the Duke's children",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 3 },
				setFlags = { noble_friends = true },
				feed = "You made friends with other noble children.",
			},
			{
				text = "Sneak out to play with commoner kids",
				effects = { Happiness = 12 },
				royaltyEffect = { popularity = 5 },
				setFlags = { commoner_friends = true, adventurous_royal = true },
				feed = "You had the best day playing with regular kids!",
			},
			{
				text = "Focus on your royal studies instead",
				effects = { Smarts = 8, Happiness = -3 },
				setFlags = { studious_royal = true },
				feed = "You chose education over play. Very princely.",
			},
		},
	},
	{
		id = "royal_pony_lesson",
		title = "🐴 Royal Horse Riding",
		emoji = "🐴",
		text = "Every royal must learn to ride! Your riding instructor says you're ready for the stables.",
		minAge = 8,
		maxAge = 12,
		isRoyalOnly = true,
		oneTime = true,
		choices = {
			{
				text = "Mount up and ride like the wind!",
				effects = { Happiness = 10, Health = 5 },
				royaltyEffect = { popularity = 5 },
				setFlags = { horse_rider = true, equestrian = true },
				feed = "You're a natural in the saddle!",
			},
			{
				text = "Approach the horse cautiously",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { horse_rider = true, cautious = true },
				feed = "You learned to ride slowly but safely.",
			},
			{
				text = "Fall off but get back on",
				effects = { Happiness = 3, Health = -5 },
				setFlags = { horse_rider = true, resilient = true },
				feed = "You fell but showed true royal determination!",
			},
		},
	},
	{
		id = "royal_christmas_speech",
		title = "🎄 Christmas at the Palace",
		emoji = "🎄",
		text = "Christmas is a magical time at the palace! The nation watches as your family celebrates.",
		minAge = 6,
		maxAge = 14,
		isRoyalOnly = true,
		cooldown = 2,
		choices = {
			{
				text = "Wave to the crowds from the balcony",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 5 },
				feed = "The crowds loved seeing you!",
			},
			{
				text = "Help give out gifts to charity children",
				effects = { Happiness = 12 },
				royaltyEffect = { popularity = 8 },
				setFlags = { charitable_spirit = true },
				feed = "Your kindness touched many hearts.",
			},
			{
				text = "Stay inside with family",
				effects = { Happiness = 8 },
				feed = "A quiet family Christmas. Perfect.",
			},
		},
	},
	{
		id = "royal_tutor_problem",
		title = "📖 Trouble with Tutors",
		emoji = "📖",
		text = "Your private tutor is being particularly strict today. Latin verbs, French etiquette, mathematics...",
		minAge = 8,
		maxAge = 14,
		isRoyalOnly = true,
		cooldown = 2,
		choices = {
			{
				text = "Study hard and impress them",
				effects = { Smarts = 8, Happiness = -2 },
				royaltyEffect = { popularity = 2 },
				setFlags = { excellent_student = true },
				feed = "Your tutor praised your dedication!",
			},
			{
				text = "Pull a prank on the tutor",
				effects = { Happiness = 8, Smarts = -2 },
				royaltyEffect = { popularity = -3 },
				setFlags = { prankster = true },
				feed = "The tutor was NOT amused... but the staff laughed!",
			},
			{
				text = "Pretend to be sick to skip lessons",
				effects = { Happiness = 5 },
				setFlags = { plays_sick = true },
				feed = "You escaped lessons for the day!",
			},
		},
	},
	{
		id = "royal_summer_vacation",
		title = "🏰 Royal Summer Holiday",
		emoji = "🏰",
		text = "Summer vacation! Where will the royal family spend the holidays?",
		minAge = 6,
		maxAge = 16,
		isRoyalOnly = true,
		cooldown = 3,
		choices = {
			{
				text = "The countryside estate",
				effects = { Happiness = 8, Health = 5 },
				feed = "A peaceful summer in the countryside.",
			},
			{
				text = "The royal yacht",
				effects = { Happiness = 10 },
				feed = "Sailing the Mediterranean in style!",
			},
			{
				text = "Visit other royals abroad",
				effects = { Happiness = 6, Smarts = 5 },
				royaltyEffect = { popularity = 5 },
				setFlags = { well_traveled_royal = true },
				feed = "You made connections with foreign royals.",
			},
			{
				text = "Stay at the palace (boring!)",
				effects = { Happiness = -3, Smarts = 3 },
				feed = "A long, quiet summer at the palace...",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #119: ROYAL TEEN EVENTS (Ages 13-17)
	-- These events keep the royal experience alive during teenage years
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "royal_boarding_school",
		title = "🏫 Royal School Life",
		emoji = "🏫",
		text = "Life at your exclusive boarding school is full of privilege... and pressure.",
		minAge = 13,
		maxAge = 17,
		isRoyalOnly = true,
		cooldown = 2,
		choices = {
			{
				text = "Excel at academics",
				effects = { Smarts = 8, Happiness = 3 },
				royaltyEffect = { popularity = 3 },
				setFlags = { top_student = true },
				feed = "Your grades are the talk of the school!",
			},
			{
				text = "Become captain of a sports team",
				effects = { Health = 8, Happiness = 8 },
				royaltyEffect = { popularity = 5 },
				setFlags = { sports_captain = true },
				feed = "You led your team with royal spirit!",
			},
			{
				text = "Focus on making influential friends",
				effects = { Happiness = 6 },
				royaltyEffect = { popularity = 3 },
				setFlags = { social_climber = true },
				feed = "You built connections that will last a lifetime.",
			},
			{
				text = "Stay low-key and avoid attention",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { modest_royal = true },
				feed = "You tried to be just another student.",
			},
		},
	},
	{
		id = "royal_teen_scandal",
		title = "📱 Caught on Camera!",
		emoji = "📱",
		text = "Someone snapped a photo of you at a party. The tabloids are going crazy!",
		minAge = 15,
		maxAge = 19,
		isRoyalOnly = true,
		baseChance = 0.4,
		cooldown = 2,
		choices = {
			{
				text = "Apologize publicly",
				effects = { Happiness = -5 },
				royaltyEffect = { popularity = -5, scandals = 1 },
				setFlags = { apologized_scandal = true },
				feed = "You apologized. The scandal will blow over.",
			},
			{
				text = "Deny everything",
				effects = { Happiness = -3 },
				royaltyEffect = { popularity = -10, scandals = 1 },
				setFlags = { denied_scandal = true },
				feed = "Your denial only made things worse...",
			},
			{
				text = "Own it with confidence",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 5, scandals = 1 },
				setFlags = { owned_scandal = true, rebel_royal = true },
				feed = "You turned the scandal into a personality win!",
			},
		},
	},
	{
		id = "royal_charity_work",
		title = "❤️ First Charity Patron",
		emoji = "❤️",
		text = "You're old enough to become patron of a charity. Which cause speaks to you?",
		minAge = 14,
		maxAge = 18,
		isRoyalOnly = true,
		oneTime = true,
		choices = {
			{
				text = "Children's hospital",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 10 },
				setFlags = { charity_patron = true, helps_children = true },
				feed = "You became patron of a children's hospital.",
			},
			{
				text = "Environmental conservation",
				effects = { Happiness = 8, Smarts = 3 },
				royaltyEffect = { popularity = 8 },
				setFlags = { charity_patron = true, environmentalist = true },
				feed = "You're fighting for the planet!",
			},
			{
				text = "Mental health awareness",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 12 },
				setFlags = { charity_patron = true, mental_health_advocate = true },
				feed = "Your openness about mental health inspired many.",
			},
			{
				text = "Arts and culture",
				effects = { Happiness = 6, Smarts = 5 },
				royaltyEffect = { popularity = 6 },
				setFlags = { charity_patron = true, arts_supporter = true },
				feed = "You became a patron of the arts.",
			},
		},
	},
	{
		id = "royal_first_interview",
		title = "🎤 Your First Interview",
		emoji = "🎤",
		text = "A major news outlet wants your first-ever solo interview. The world wants to know: who is the young royal?",
		minAge = 16,
		maxAge = 20,
		isRoyalOnly = true,
		oneTime = true,
		isMilestone = true,
		choices = {
			{
				text = "Be polished and professional",
				effects = { Smarts = 5, Happiness = 5 },
				royaltyEffect = { popularity = 8 },
				setFlags = { first_interview = true, professional_image = true },
				feed = "You came across as mature beyond your years.",
			},
			{
				text = "Be yourself - relatable and honest",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 15 },
				setFlags = { first_interview = true, peoples_royal = true },
				feed = "The public fell in love with your authenticity!",
			},
			{
				text = "Refuse the interview",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = -5 },
				setFlags = { avoids_media = true },
				feed = "You value your privacy. Fair enough.",
			},
		},
	},
	{
		id = "royal_gap_year_decision",
		title = "✈️ Gap Year Plans",
		emoji = "✈️",
		text = "Many royals take a gap year before university. What are your plans?",
		minAge = 17,
		maxAge = 19,
		isRoyalOnly = true,
		oneTime = true,
		choices = {
			{
				text = "Charity work in Africa",
				effects = { Happiness = 10, Health = 3 },
				royaltyEffect = { popularity = 15 },
				setFlags = { gap_year = true, charity_gap_year = true },
				feed = "Your humanitarian gap year made headlines!",
			},
			{
				text = "Travel the world incognito",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = 5 },
				setFlags = { gap_year = true, world_traveler = true },
				feed = "You experienced the world like a normal person!",
			},
			{
				text = "Military training",
				effects = { Health = 10, Happiness = 3 },
				royaltyEffect = { popularity = 8 },
				setFlags = { gap_year = true, military_training = true },
				feed = "You started your military training early.",
			},
			{
				text = "Go straight to university",
				effects = { Smarts = 8 },
				setFlags = { no_gap_year = true },
				feed = "No time to waste - education first!",
			},
		},
	},
	{
		id = "coming_of_age",
		title = "🎂 Royal Coming of Age",
		emoji = "🎂",
		text = "You've reached the age of majority! A grand celebration is held in your honor. You now have official royal duties.",
		minAge = 18,
		maxAge = 18,
		isRoyalOnly = true,
		isMilestone = true,
		choices = {
			{
				text = "Embrace your new responsibilities",
				effects = { Happiness = 5, Smarts = 5 },
				royaltyEffect = { popularity = 10 },
				setFlags = { dutiful_royal = true },
				feed = "You embraced your royal duties with grace.",
			},
			{
				text = "Party like there's no tomorrow",
				effects = { Happiness = 15, Health = -5 },
				royaltyEffect = { popularity = -5 },
				setFlags = { party_royal = true },
				feed = "Your coming-of-age party was legendary!",
			},
			{
				text = "Give a speech about your vision for the future",
				effects = { Happiness = 5, Smarts = 8 },
				royaltyEffect = { popularity = 15 },
				setFlags = { visionary_royal = true, public_speaker = true },
				feed = "Your speech inspired the nation!",
			},
		},
	},
	{
		id = "military_service",
		title = "🎖️ Royal Military Service",
		emoji = "🎖️",
		text = "Following royal tradition, you're expected to serve in the military. This will be your first taste of discipline and duty.",
		minAge = 18,
		maxAge = 25,
		isRoyalOnly = true,
		conditions = { requiresFlags = { not_served_military = nil } },
		choices = {
			{
				text = "Join the Army",
				effects = { Health = 10, Happiness = 5 },
				royaltyEffect = { popularity = 8 },
				setFlags = { military_service = true, army_veteran = true },
				feed = "You proudly served in the Royal Army.",
			},
			{
				text = "Join the Navy",
				effects = { Health = 8, Smarts = 5 },
				royaltyEffect = { popularity = 8 },
				setFlags = { military_service = true, navy_veteran = true },
				feed = "You served honorably in the Royal Navy.",
			},
			{
				text = "Join the Air Force (become a pilot)",
				effects = { Health = 5, Smarts = 8, Happiness = 10 },
				royaltyEffect = { popularity = 10 },
				setFlags = { military_service = true, pilot = true, air_force_veteran = true },
				feed = "You earned your wings as a Royal Air Force pilot!",
			},
			{
				text = "Decline military service",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = -15 },
				setFlags = { declined_service = true },
				feed = "You broke tradition by declining military service.",
			},
		},
	},
	{
		id = "first_solo_engagement",
		title = "✨ First Solo Engagement",
		emoji = "✨",
		text = "Today marks your first solo royal engagement! You'll represent the crown without your parents' guidance.",
		minAge = 18,
		maxAge = 22,
		isRoyalOnly = true,
		choices = {
			{
				text = "Nail it with charm and grace",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 12 },
				setFlags = { solo_success = true },
				feed = "Your first solo engagement was a resounding success!",
			},
			{
				text = "Make a small mistake but recover",
				effects = { Happiness = 3, Smarts = 3 },
				royaltyEffect = { popularity = 5 },
				setFlags = { learned_from_mistake = true },
				feed = "A minor gaffe, but you handled it with grace.",
			},
			{
				text = "Totally mess it up",
				effects = { Happiness = -10 },
				royaltyEffect = { popularity = -10 },
				setFlags = { engagement_disaster = true },
				feed = "Your first solo engagement was... memorable for the wrong reasons.",
			},
		},
	},
	
	-- ROMANCE AND MARRIAGE
	{
		id = "royal_courtship",
		title = "💕 Royal Romance",
		emoji = "💕",
		text = "You've fallen in love! But royal relationships come with scrutiny. The whole world is watching.",
		minAge = 18,
		maxAge = 40,
		isRoyalOnly = true,
		conditions = { requiresFlags = { married = nil } },
		choices = {
			{
				text = "Date someone from nobility",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 5 },
				setFlags = { dating_noble = true, traditional_romance = true },
				feed = "You began courting someone from a noble family.",
			},
			{
				text = "Date a commoner (break tradition!)",
				effects = { Happiness = 12 },
				royaltyEffect = { popularity = 15 },
				setFlags = { dating_commoner = true, modern_royal = true },
				feed = "The public loves your down-to-earth romance!",
			},
			{
				text = "Date a foreign royal (alliance)",
				effects = { Happiness = 6 },
				royaltyEffect = { popularity = 3 },
				setFlags = { dating_foreign_royal = true, diplomatic_romance = true },
				feed = "Your relationship could unite two kingdoms!",
			},
			{
				text = "Keep your relationship secret",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 0 },
				setFlags = { secret_romance = true },
				feed = "You're keeping your love life private... for now.",
			},
		},
	},
	{
		id = "royal_wedding_planning",
		title = "💒 Royal Wedding Preparations",
		emoji = "💒",
		text = "Wedding bells are ringing! Your royal wedding will be watched by millions around the world. How extravagant will it be?",
		minAge = 21,
		maxAge = 50,
		isRoyalOnly = true,
		conditions = { requiresFlags = { engaged = true } },
		choices = {
			{
				text = "Traditional grand ceremony ($50 million)",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = 20, wealthCost = 50000000 },
				setFlags = { grand_wedding = true },
				feed = "Your fairy-tale wedding captivated the world!",
			},
			{
				text = "Modern intimate wedding ($10 million)",
				effects = { Happiness = 18 },
				royaltyEffect = { popularity = 25, wealthCost = 10000000 },
				setFlags = { intimate_wedding = true, relatable_royal = true },
				feed = "Your intimate wedding touched hearts everywhere!",
			},
			{
				text = "Lavish destination wedding ($100 million)",
				effects = { Happiness = 12 },
				royaltyEffect = { popularity = -10, wealthCost = 100000000 },
				setFlags = { extravagant_wedding = true },
				feed = "Your extravagant wedding drew criticism for its cost.",
			},
			{
				text = "Elope secretly",
				effects = { Happiness = 20 },
				royaltyEffect = { popularity = 10, scandals = 1, wealthCost = 100000 },
				setFlags = { eloped = true, rebellious_royal = true },
				feed = "You shocked the world by eloping!",
			},
		},
	},
	{
		id = "royal_heir_birth",
		title = "👶 An Heir is Born",
		emoji = "👶",
		text = "Congratulations! You've welcomed a new member to the royal family. The nation celebrates the birth of an heir!",
		minAge = 22,
		maxAge = 45,
		isRoyalOnly = true,
		conditions = { requiresFlags = { married = true } },
		choices = {
			{
				text = "Traditional royal announcement",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = 20 },
				setFlags = { royal_parent = true },
				feed = "The birth was announced in traditional royal fashion!",
			},
			{
				text = "Share on social media first",
				effects = { Happiness = 12 },
				royaltyEffect = { popularity = 25 },
				setFlags = { royal_parent = true, modern_royal = true },
				feed = "Your personal touch on the announcement went viral!",
			},
			{
				text = "Keep it private initially",
				effects = { Happiness = 18 },
				royaltyEffect = { popularity = 10 },
				setFlags = { royal_parent = true, private_royal = true },
				feed = "You enjoyed private moments before the public announcement.",
			},
		},
	},
	
	-- THRONE AND SUCCESSION
	{
		id = "throne_succession",
		title = "👑 Succession Approaches",
		emoji = "👑",
		text = "The current monarch's health is failing. As next in line, you must prepare for the weight of the crown.",
		minAge = 25,
		maxAge = 80,
		isRoyalOnly = true,
		conditions = { 
			requiresFlags = { is_heir = true },
			blockedFlags = { is_monarch = true },
		},
		choices = {
			{
				text = "Accept your destiny with grace",
				effects = { Happiness = 5, Smarts = 5 },
				royaltyEffect = { popularity = 10 },
				setFlags = { ready_for_throne = true },
				feed = "You prepared yourself for the responsibilities ahead.",
			},
			{
				text = "Feel overwhelmed by the responsibility",
				effects = { Happiness = -10 },
				royaltyEffect = { popularity = 0 },
				setFlags = { reluctant_heir = true },
				feed = "The weight of the crown weighs heavily on you.",
			},
			{
				text = "Consider abdicating before coronation",
				effects = { Happiness = 0 },
				royaltyEffect = { popularity = -20 },
				setFlags = { considering_abdication = true },
				feed = "Rumors spread that you may refuse the throne.",
			},
		},
	},
	{
		id = "coronation",
		title = "👑 CORONATION DAY",
		emoji = "👑",
		text = "The day has come. You are being crowned as the new monarch! Millions watch as the crown is placed upon your head.",
		minAge = 25,
		maxAge = 90,
		isRoyalOnly = true,
		isMilestone = true,
		priority = "critical",
		conditions = { 
			requiresFlags = { throne_ready = true },
			blockedFlags = { is_monarch = true },
		},
		choices = {
			{
				text = "Swear the sacred oath with conviction",
				effects = { Happiness = 20, Smarts = 5 },
				royaltyEffect = { popularity = 25, becomesMonarch = true },
				setFlags = { is_monarch = true, crowned = true },
				feed = "Long live the King/Queen! You are now the monarch!",
			},
			{
				text = "Break tradition with a modern coronation",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = 30, becomesMonarch = true },
				setFlags = { is_monarch = true, crowned = true, modern_monarch = true },
				feed = "Your modern coronation marked a new era!",
			},
			{
				text = "Abdicate at the last moment",
				effects = { Happiness = -20 },
				royaltyEffect = { popularity = -50, abdicated = true },
				setFlags = { abdicated = true },
				feed = "In a shocking turn, you abdicated the throne!",
			},
		},
	},
	{
		id = "first_speech_as_monarch",
		title = "🎤 Address to the Nation",
		emoji = "🎤",
		text = "As the new monarch, you must address your nation for the first time. What message will you send?",
		minAge = 25,
		maxAge = 90,
		isRoyalOnly = true,
		conditions = { requiresFlags = { is_monarch = true, gave_first_speech = nil } },
		choices = {
			{
				text = "Promise to serve the people",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 15 },
				setFlags = { gave_first_speech = true, servant_monarch = true },
				feed = "Your humble promise resonated with the people.",
			},
			{
				text = "Outline ambitious reforms",
				effects = { Happiness = 5, Smarts = 5 },
				royaltyEffect = { popularity = 10 },
				setFlags = { gave_first_speech = true, reformer_monarch = true },
				feed = "Your vision for change excited the nation!",
			},
			{
				text = "Honor tradition and continuity",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 12 },
				setFlags = { gave_first_speech = true, traditional_monarch = true },
				feed = "Your respect for tradition earned praise.",
			},
			{
				text = "Make it personal and emotional",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = 20 },
				setFlags = { gave_first_speech = true, emotional_monarch = true },
				feed = "Tears flowed as you shared your personal story.",
			},
		},
	},
	
	-- SCANDALS AND CRISES
	{
		id = "scandal_response",
		title = "📰 Royal Scandal!",
		emoji = "📰",
		text = "A scandal has rocked the palace! The tabloids are running explosive stories about you. How do you respond?",
		minAge = 16,
		maxAge = 90,
		isRoyalOnly = true,
		choices = {
			{
				text = "Issue a formal denial",
				effects = { Happiness = -5 },
				royaltyEffect = { popularity = -5 },
				setFlags = { denied_scandal = true },
				feed = "You denied the allegations through official channels.",
			},
			{
				text = "Ignore it and let it blow over",
				effects = { Happiness = -8 },
				royaltyEffect = { popularity = -10 },
				setFlags = { ignored_scandal = true },
				feed = "Your silence spoke volumes to some.",
			},
			{
				text = "Confess and apologize publicly",
				effects = { Happiness = -15 },
				royaltyEffect = { popularity = 5 },
				setFlags = { confessed_scandal = true, honest_royal = true },
				feed = "Your honesty was appreciated by many.",
			},
			{
				text = "Sue the tabloids",
				effects = { Happiness = -5 },
				royaltyEffect = { popularity = 0, legalAction = true },
				setFlags = { sued_press = true },
				feed = "You took legal action against the press.",
			},
		},
	},
	{
		id = "paparazzi_incident",
		title = "📸 Paparazzi Incident",
		emoji = "📸",
		text = "Paparazzi have been following you relentlessly. One of them just got too close for comfort.",
		minAge = 14,
		maxAge = 90,
		isRoyalOnly = true,
		choices = {
			{
				text = "Smile and wave professionally",
				effects = { Happiness = -3 },
				royaltyEffect = { popularity = 5 },
				setFlags = { graceful_under_pressure = true },
				feed = "You handled the paparazzi with grace.",
			},
			{
				text = "Confront them angrily",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = -15 },
				setFlags = { lost_temper = true },
				feed = "Your angry outburst was caught on camera!",
			},
			{
				text = "Have security handle it",
				effects = { Happiness = 0 },
				royaltyEffect = { popularity = 0 },
				feed = "Security cleared the paparazzi.",
			},
			{
				text = "Flee through a back exit",
				effects = { Happiness = -5 },
				royaltyEffect = { popularity = -5 },
				feed = "You escaped the paparazzi through a back door.",
			},
		},
	},
	{
		id = "royal_feud",
		title = "👨‍👩‍👧‍👦 Family Feud",
		emoji = "👨‍👩‍👧‍👦",
		text = "There's tension within the royal family. A sibling or relative is causing drama that threatens to go public.",
		minAge = 18,
		maxAge = 90,
		isRoyalOnly = true,
		choices = {
			{
				text = "Try to resolve it privately",
				effects = { Happiness = -5, Smarts = 3 },
				royaltyEffect = { popularity = 5 },
				setFlags = { family_mediator = true },
				feed = "You attempted to heal the family rift in private.",
			},
			{
				text = "Take your side to the media",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = -20, scandals = 1 },
				setFlags = { went_public_feud = true },
				feed = "The family feud exploded into the public eye!",
			},
			{
				text = "Distance yourself completely",
				effects = { Happiness = 0 },
				royaltyEffect = { popularity = 0 },
				setFlags = { family_distant = true },
				feed = "You stepped back from the family drama.",
			},
			{
				text = "Support the troublemaker",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = -10 },
				setFlags = { supported_rebel = true },
				feed = "You stood by your troubled relative.",
			},
		},
	},
	
	-- ABDICATION AND EXILE
	{
		id = "abdication_consideration",
		title = "⚠️ Consider Abdication",
		emoji = "⚠️",
		text = "The pressures of royal life have become overwhelming. You're seriously considering stepping back from your duties.",
		minAge = 25,
		maxAge = 90,
		isRoyalOnly = true,
		conditions = { requiresFlags = { is_monarch = true } },
		choices = {
			{
				text = "Abdicate and live privately",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = -30, abdicated = true },
				setFlags = { abdicated = true, private_life = true },
				feed = "You shocked the world by abdicating the throne!",
			},
			{
				text = "Abdicate but remain a senior royal",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = -15, stepDown = true },
				setFlags = { stepped_down = true },
				feed = "You stepped down but remain part of the royal family.",
			},
			{
				text = "Stay and push through",
				effects = { Happiness = -5, Health = -5 },
				royaltyEffect = { popularity = 5 },
				setFlags = { persevered = true },
				feed = "You chose duty over personal happiness.",
			},
			{
				text = "Take extended leave for mental health",
				effects = { Happiness = 10, Health = 10 },
				royaltyEffect = { popularity = 10 },
				setFlags = { royal_leave = true, mental_health_advocate = true },
				feed = "Your honesty about mental health won praise.",
			},
		},
	},
	{
		id = "exile_option",
		title = "✈️ Leave the Country",
		emoji = "✈️",
		text = "After recent events, you're considering leaving the country and starting fresh somewhere else.",
		minAge = 21,
		maxAge = 90,
		isRoyalOnly = true,
		conditions = { requiresFlags = { wants_to_leave = true } },
		choices = {
			{
				text = "Move to America and start anew",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = -40, exiled = true },
				setFlags = { exiled = true, lives_in_usa = true },
				feed = "You left the royal life behind for America!",
			},
			{
				text = "Move to a private island",
				effects = { Happiness = 12 },
				royaltyEffect = { popularity = -30, exiled = true, wealthCost = 50000000 },
				setFlags = { exiled = true, island_life = true },
				feed = "You retreated to your own private island!",
			},
			{
				text = "Stay and fight for your place",
				effects = { Happiness = -5 },
				royaltyEffect = { popularity = 10 },
				setFlags = { stood_ground = true },
				feed = "You refused to be driven from your homeland.",
			},
		},
	},
	
	-- LATE LIFE AND LEGACY
	{
		id = "royal_legacy",
		title = "📜 Your Royal Legacy",
		emoji = "📜",
		text = "As you enter your later years, historians are already writing about your reign. What will you be remembered for?",
		minAge = 65,
		maxAge = 90,
		isRoyalOnly = true,
		conditions = { requiresFlags = { is_monarch = true } },
		choices = {
			{
				text = "Charity work and compassion",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = 20 },
				setFlags = { legacy_charity = true },
				feed = "You will be remembered as a compassionate monarch.",
			},
			{
				text = "Modernizing the monarchy",
				effects = { Happiness = 10, Smarts = 5 },
				royaltyEffect = { popularity = 15 },
				setFlags = { legacy_modernizer = true },
				feed = "You brought the monarchy into the modern age.",
			},
			{
				text = "Preserving tradition",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 10 },
				setFlags = { legacy_traditionalist = true },
				feed = "You upheld centuries of royal tradition.",
			},
			{
				text = "The scandals and drama",
				effects = { Happiness = -10 },
				royaltyEffect = { popularity = -10 },
				setFlags = { legacy_controversial = true },
				feed = "Your reign will be remembered as... eventful.",
			},
		},
	},
	{
		id = "succession_planning",
		title = "👑 Succession Planning",
		emoji = "👑",
		text = "It's time to think about who will succeed you. The future of the monarchy depends on this decision.",
		minAge = 60,
		maxAge = 95,
		isRoyalOnly = true,
		conditions = { requiresFlags = { is_monarch = true } },
		choices = {
			{
				text = "Prepare your eldest for the throne",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = 10 },
				setFlags = { traditional_succession = true },
				feed = "You're grooming your heir for the crown.",
			},
			{
				text = "Choose the most capable heir (skip line)",
				effects = { Happiness = 3, Smarts = 5 },
				royaltyEffect = { popularity = -5, scandals = 1 },
				setFlags = { merit_succession = true },
				feed = "You broke tradition by choosing capability over birth order!",
			},
			{
				text = "Plan to reign until death",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = 5 },
				setFlags = { reign_to_death = true },
				feed = "You'll wear the crown until your last breath.",
			},
			{
				text = "Consider abolishing the monarchy",
				effects = { Happiness = 0 },
				royaltyEffect = { popularity = -25 },
				setFlags = { considers_abolition = true },
				feed = "Whispers of abolition shocked the nation!",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #110: EXPANDED ROYAL EVENTS
	-- Additional royal events for more comprehensive gameplay
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "royal_fashion_icon",
		title = "👗 Fashion Trendsetter",
		emoji = "👗",
		text = "Your fashion choices are making headlines! Designers are desperate to dress you and the public copies your every outfit.",
		minAge = 16,
		maxAge = 60,
		isRoyalOnly = true,
		choices = {
			{
				text = "Embrace high fashion and bold choices",
				effects = { Happiness = 10, Looks = 5 },
				royaltyEffect = { popularity = 10 },
				setFlags = { fashion_icon = true },
				feed = "You've become a global fashion icon!",
			},
			{
				text = "Stick to traditional royal attire",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = 5 },
				setFlags = { traditional_dresser = true },
				feed = "Your classic style is timeless elegance.",
			},
			{
				text = "Support local designers exclusively",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 12 },
				setFlags = { supports_local = true },
				feed = "Your patriotic fashion choices boosted the local industry!",
			},
		},
	},
	{
		id = "royal_documentary",
		title = "🎥 Royal Documentary",
		emoji = "🎥",
		text = "A major streaming service wants to produce a documentary about your life. This could humanize the monarchy... or expose too much.",
		minAge = 25,
		maxAge = 90,
		isRoyalOnly = true,
		choices = {
			{
				text = "Allow full access - nothing to hide",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = 20 },
				setFlags = { documentary_open = true },
				feed = "The documentary was a huge success! People loved seeing the real you.",
			},
			{
				text = "Strictly controlled access only",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = 8 },
				setFlags = { documentary_controlled = true },
				feed = "The documentary showed a polished version of royal life.",
			},
			{
				text = "Decline - maintain the mystique",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = -5 },
				setFlags = { declined_documentary = true },
				feed = "You value your privacy over publicity.",
			},
		},
	},
	{
		id = "royal_social_media",
		title = "📱 Royal Social Media",
		emoji = "📱",
		text = "Should you join social media? It could modernize the monarchy's image, but also opens you to direct criticism.",
		minAge = 18,
		maxAge = 50,
		isRoyalOnly = true,
		conditions = { blockedFlags = { has_social_media = true } },
		choices = {
			{
				text = "Launch official accounts on all platforms",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 15 },
				setFlags = { has_social_media = true, social_media_savvy = true },
				feed = "Your social media presence took off! Millions of followers.",
			},
			{
				text = "Start with just one platform (Instagram)",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = 10 },
				setFlags = { has_social_media = true },
				feed = "Your Instagram is carefully curated and very popular.",
			},
			{
				text = "Stay off social media entirely",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = -3 },
				setFlags = { no_social_media = true },
				feed = "You prefer to remain mysterious.",
			},
		},
	},
	{
		id = "royal_humanitarian_mission",
		title = "🌍 Humanitarian Mission",
		emoji = "🌍",
		text = "A devastating disaster has struck a foreign nation. You have the opportunity to lead a royal humanitarian mission.",
		minAge = 21,
		maxAge = 70,
		isRoyalOnly = true,
		choices = {
			{
				text = "Lead the mission personally",
				effects = { Happiness = 15, Health = -5 },
				royaltyEffect = { popularity = 25 },
				setFlags = { humanitarian_leader = true },
				feed = "Your hands-on approach inspired the world!",
			},
			{
				text = "Donate significantly and send representatives",
				effects = { Happiness = 8, Money = -5000000 },
				royaltyEffect = { popularity = 15 },
				setFlags = { generous_royal = true },
				feed = "Your generous donation made a real difference.",
			},
			{
				text = "Make a public statement of support",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = 5 },
				feed = "Your words were appreciated, though some hoped for more.",
			},
		},
	},
	{
		id = "royal_modernization_debate",
		title = "⚖️ Monarchy Modernization",
		emoji = "⚖️",
		text = "There's growing debate about modernizing the monarchy. Some want more transparency, others want to preserve tradition.",
		minAge = 30,
		maxAge = 90,
		isRoyalOnly = true,
		conditions = { requiresFlags = { is_monarch = true } },
		choices = {
			{
				text = "Push for significant modernization",
				effects = { Happiness = 10, Smarts = 5 },
				royaltyEffect = { popularity = 15 },
				setFlags = { modernizer = true },
				feed = "Your reforms are ushering in a new era for the monarchy!",
			},
			{
				text = "Make small, careful changes",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = 8 },
				setFlags = { careful_reformer = true },
				feed = "Gradual change keeps everyone happy.",
			},
			{
				text = "Defend tradition staunchly",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = -5 },
				setFlags = { traditionalist = true },
				feed = "Your dedication to tradition is unwavering.",
			},
		},
	},
	{
		id = "royal_sibling_rivalry",
		title = "👨‍👩‍👧‍👦 Sibling Dynamics",
		emoji = "👨‍👩‍👧‍👦",
		text = "Your royal sibling is making waves. Are they supportive or competitive? The media loves a good sibling story.",
		minAge = 18,
		maxAge = 70,
		isRoyalOnly = true,
		choices = {
			{
				text = "Present a united front publicly",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 10 },
				setFlags = { united_family = true },
				feed = "The world admires your family unity.",
			},
			{
				text = "Compete for the spotlight",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = -5, scandals = 1 },
				setFlags = { sibling_rivalry = true },
				feed = "The rivalry makes headlines but hurts the family image.",
			},
			{
				text = "Support their independent path",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 8 },
				setFlags = { supportive_sibling = true },
				feed = "Your support shows true royal grace.",
			},
		},
	},
	{
		id = "royal_security_threat",
		title = "🚨 Security Threat",
		emoji = "🚨",
		text = "Your security team has uncovered a credible threat against you. How do you handle this frightening situation?",
		minAge = 18,
		maxAge = 90,
		isRoyalOnly = true,
		choices = {
			{
				text = "Increase security dramatically",
				effects = { Happiness = -10, Health = 5 },
				royaltyEffect = { popularity = 0 },
				setFlags = { high_security = true },
				feed = "Your security is now fortress-level.",
			},
			{
				text = "Continue normal duties to show strength",
				effects = { Happiness = 5, Health = -5 },
				royaltyEffect = { popularity = 15 },
				setFlags = { brave_royal = true },
				feed = "Your courage in the face of threats impressed everyone!",
			},
			{
				text = "Take a temporary break from public life",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = -5 },
				setFlags = { took_break = true },
				feed = "Safety first. You'll return when it's safe.",
			},
		},
	},
	{
		id = "royal_book_deal",
		title = "📚 Royal Memoirs",
		emoji = "📚",
		text = "A publisher is offering a massive advance for your memoirs. What will you reveal?",
		minAge = 35,
		maxAge = 90,
		isRoyalOnly = true,
		choices = {
			{
				text = "Write a tell-all explosive memoir",
				effects = { Happiness = 10, Money = 20000000 },
				royaltyEffect = { popularity = -20, scandals = 2 },
				setFlags = { wrote_tellall = true },
				feed = "Your tell-all shocked the world and topped bestseller lists!",
			},
			{
				text = "Write a dignified, measured account",
				effects = { Happiness = 8, Money = 10000000 },
				royaltyEffect = { popularity = 10 },
				setFlags = { wrote_memoirs = true },
				feed = "Your graceful memoirs were well-received.",
			},
			{
				text = "Decline - some things should stay private",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = 3 },
				setFlags = { declined_memoirs = true },
				feed = "You chose discretion over disclosure.",
			},
		},
	},
	{
		id = "royal_commonwealth_tour",
		title = "🌐 Commonwealth Tour",
		emoji = "🌐",
		text = "It's time for a major tour of Commonwealth nations. These tours are exhausting but vital for diplomatic relations.",
		minAge = 21,
		maxAge = 75,
		isRoyalOnly = true,
		choices = {
			{
				text = "Embrace every engagement enthusiastically",
				effects = { Happiness = 5, Health = -10 },
				royaltyEffect = { popularity = 20 },
				setFlags = { touring_royal = true },
				feed = "Your energy and warmth won hearts across nations!",
			},
			{
				text = "Focus on key diplomatic moments",
				effects = { Happiness = 3, Health = -5 },
				royaltyEffect = { popularity = 12 },
				feed = "Strategic engagement was efficient and effective.",
			},
			{
				text = "Cut the tour short due to health",
				effects = { Happiness = -5, Health = 5 },
				royaltyEffect = { popularity = -8 },
				setFlags = { cut_tour_short = true },
				feed = "Some were disappointed, but health comes first.",
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

function RoyaltyEvents.getCountryById(countryId)
	for _, country in ipairs(RoyaltyEvents.RoyalCountries) do
		if country.id == countryId then
			return country
		end
	end
	return RoyaltyEvents.RoyalCountries[1] -- Default to UK
end

function RoyaltyEvents.getRandomCountry()
	return RoyaltyEvents.RoyalCountries[math.random(1, #RoyaltyEvents.RoyalCountries)]
end

function RoyaltyEvents.getRoyalTitle(countryId, gender, isMonarch)
	local country = RoyaltyEvents.getCountryById(countryId)
	local genderKey = (gender or "Male"):lower()
	if genderKey ~= "male" and genderKey ~= "female" then
		genderKey = "male"
	end
	
	if isMonarch then
		return country.titles[genderKey].monarch
	else
		return country.titles[genderKey].heir
	end
end

function RoyaltyEvents.getRandomDuty(age, isMonarch)
	local availableDuties = {}
	for _, duty in ipairs(RoyaltyEvents.RoyalDuties) do
		if age >= (duty.minAge or 0) then
			if duty.requiresMonarch then
				if isMonarch then
					table.insert(availableDuties, duty)
				end
			else
				table.insert(availableDuties, duty)
			end
		end
	end
	
	if #availableDuties == 0 then
		return nil
	end
	
	return availableDuties[math.random(1, #availableDuties)]
end

function RoyaltyEvents.getRandomScandal()
	return RoyaltyEvents.RoyalScandals[math.random(1, #RoyaltyEvents.RoyalScandals)]
end

function RoyaltyEvents.getEventsForAge(age, flags)
	local availableEvents = {}
	
	for _, event in ipairs(RoyaltyEvents.LifeEvents) do
		local meetsAge = age >= (event.minAge or 0) and age <= (event.maxAge or 999)
		local meetsConditions = true
		
		if event.conditions then
			if event.conditions.requiresFlags then
				for flag, value in pairs(event.conditions.requiresFlags) do
					if value == nil then
						-- Flag must not exist
						if flags[flag] then
							meetsConditions = false
							break
						end
					elseif flags[flag] ~= value then
						meetsConditions = false
						break
					end
				end
			end
			if event.conditions.blockedFlags then
				for flag, value in pairs(event.conditions.blockedFlags) do
					if flags[flag] == value then
						meetsConditions = false
						break
					end
				end
			end
		end
		
		if meetsAge and meetsConditions then
			table.insert(availableEvents, event)
		end
	end
	
	return availableEvents
end

function RoyaltyEvents.initializeRoyalState(lifeState, countryId, gender)
	local country = RoyaltyEvents.getCountryById(countryId)
	local title = RoyaltyEvents.getRoyalTitle(countryId, gender, false)
	
	-- Calculate starting wealth
	local wealthRange = country.startingWealth or { min = 10000000, max = 100000000 }
	local startingWealth = math.random(wealthRange.min, wealthRange.max)
	
	lifeState.RoyalState = {
		isRoyal = true,
		isMonarch = false,
		country = country.id,
		countryName = country.name,
		countryEmoji = country.emoji,
		palace = country.palace,
		title = title,
		lineOfSuccession = math.random(1, 5),
		popularity = 75 + math.random(-10, 10),
		scandals = 0,
		dutiesCompleted = 0,
		dutyStreak = 0,
		reignYears = 0,
		wealth = startingWealth,
		awards = {},
		charitiesPatronized = {},
		stateVisits = {},
	}
	
	-- Set player money
	lifeState.Money = startingWealth
	
	-- Set flags
	lifeState.Flags = lifeState.Flags or {}
	lifeState.Flags.is_royalty = true
	lifeState.Flags.royal_birth = true
	lifeState.Flags.royal_country = country.id
	lifeState.Flags.wealthy_family = true
	lifeState.Flags.upper_class = true
	lifeState.Flags.famous_family = true
	
	return true, string.format("Born as %s of %s!", title, country.name)
end

function RoyaltyEvents.processYearlyRoyalUpdates(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.isRoyal then
		return {}
	end
	
	local events = {}
	local age = lifeState.Age or 0
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #29: Age-based title progression
	-- Update royal title based on age (e.g., Prince → Crown Prince at age 18)
	-- ═══════════════════════════════════════════════════════════════════════════════
	local oldTitle = royalState.title
	RoyaltyEvents.updateRoyalTitle(lifeState)
	if royalState.title ~= oldTitle and royalState.title then
		table.insert(events, {
			type = "title_change",
			message = string.format("👑 Your title has changed! You are now %s!", royalState.title),
		})
	end
	
	-- CRITICAL FIX #29: Coming of age milestones
	if age == 18 and not royalState.cameOfAge then
		royalState.cameOfAge = true
		royalState.popularity = math.min(100, royalState.popularity + 5)
		table.insert(events, {
			type = "coming_of_age",
			message = "🎂 You have come of age! You can now perform adult royal duties.",
		})
		lifeState.Flags = lifeState.Flags or {}
		lifeState.Flags.royal_adult = true
	elseif age == 21 and not royalState.fullyAdult then
		royalState.fullyAdult = true
		royalState.popularity = math.min(100, royalState.popularity + 3)
		table.insert(events, {
			type = "full_adulthood",
			message = "🎉 At 21, you are now a full adult member of the royal family!",
		})
	end
	
	-- Passive popularity decay
	if royalState.dutiesCompleted == 0 then
		royalState.popularity = math.max(0, royalState.popularity - 2)
		table.insert(events, {
			type = "popularity_decay",
			message = "Your popularity dropped slightly due to lack of public appearances.",
		})
	end
	
	-- Reset yearly counters
	royalState.dutiesCompleted = 0
	
	-- Reign years for monarchs
	if royalState.isMonarch then
		royalState.reignYears = royalState.reignYears + 1
		
		-- Long reign bonuses
		if royalState.reignYears == 25 then
			royalState.popularity = math.min(100, royalState.popularity + 10)
			table.insert(events, {
				type = "jubilee",
				message = "🎉 Silver Jubilee! 25 years on the throne!",
			})
		elseif royalState.reignYears == 50 then
			royalState.popularity = math.min(100, royalState.popularity + 15)
			table.insert(events, {
				type = "jubilee",
				message = "🎉 Golden Jubilee! 50 years on the throne!",
			})
		elseif royalState.reignYears == 70 then
			royalState.popularity = math.min(100, royalState.popularity + 20)
			table.insert(events, {
				type = "jubilee",
				message = "🎉 Platinum Jubilee! 70 years on the throne!",
			})
		end
	end
	
	-- Succession advancement
	if not royalState.isMonarch and royalState.lineOfSuccession > 1 then
		-- Small chance of moving up in line
		if math.random(100) <= 5 then
			local oldLine = royalState.lineOfSuccession
			royalState.lineOfSuccession = royalState.lineOfSuccession - 1
			-- CRITICAL FIX #29: Update title after succession change
			RoyaltyEvents.updateRoyalTitle(lifeState)
			table.insert(events, {
				type = "succession",
				message = string.format("You moved up to #%d in line for the throne! You are now %s.", royalState.lineOfSuccession, royalState.title),
			})
		end
	end
	
	-- Check if ready for coronation
	if not royalState.isMonarch and royalState.lineOfSuccession == 1 and age >= 21 then
		if math.random(100) <= 10 then -- 10% chance per year when next in line and adult
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.throne_ready = true
			lifeState.Flags.is_heir = true
			table.insert(events, {
				type = "succession_imminent",
				message = "👑 The current monarch's health is declining. You may soon inherit the throne!",
			})
		end
	end
	
	-- Random scandal chance
	if math.random(100) <= 3 then
		local scandal = RoyaltyEvents.getRandomScandal()
		if scandal then
			royalState.scandals = royalState.scandals + 1
			local popLoss = math.random(scandal.popularityLoss.min, scandal.popularityLoss.max)
			royalState.popularity = math.max(0, royalState.popularity - popLoss)
			table.insert(events, {
				type = "scandal",
				message = "📰 SCANDAL: " .. scandal.name .. " - " .. scandal.description,
				scandalId = scandal.id,
			})
		end
	end
	
	return events
end

function RoyaltyEvents.completeDuty(lifeState, dutyId)
	local royalState = lifeState.RoyalState
	if not royalState then
		return false, "Not royalty"
	end
	
	local duty = nil
	for _, d in ipairs(RoyaltyEvents.RoyalDuties) do
		if d.id == dutyId then
			duty = d
			break
		end
	end
	
	if not duty then
		return false, "Unknown duty"
	end
	
	-- Check age requirement
	if lifeState.Age < (duty.minAge or 0) then
		return false, "Too young for this duty"
	end
	
	-- Check monarch requirement
	if duty.requiresMonarch and not royalState.isMonarch then
		return false, "Only the monarch can perform this duty"
	end
	
	-- Apply costs
	if duty.wealthCost then
		if lifeState.Money < duty.wealthCost then
			return false, "Not enough money"
		end
		lifeState.Money = lifeState.Money - duty.wealthCost
	end
	
	if duty.charityCost then
		lifeState.Money = lifeState.Money - duty.charityCost
	end
	
	if duty.donationAmount then
		lifeState.Money = lifeState.Money - duty.donationAmount
	end
	
	-- Apply popularity effect
	local popGain = math.random(duty.popularityEffect.min, duty.popularityEffect.max)
	royalState.popularity = math.min(100, royalState.popularity + popGain)
	royalState.dutiesCompleted = royalState.dutiesCompleted + 1
	royalState.dutyStreak = royalState.dutyStreak + 1
	
	-- Streak bonus
	if royalState.dutyStreak >= 5 then
		royalState.popularity = math.min(100, royalState.popularity + 5)
	end
	
	return true, string.format("✅ Completed: %s (+%d popularity)", duty.name, popGain)
end

function RoyaltyEvents.becomeMonarch(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState then
		return false, "Not royalty"
	end
	
	if royalState.isMonarch then
		return false, "Already a monarch"
	end
	
	local country = RoyaltyEvents.getCountryById(royalState.country)
	local gender = lifeState.Gender or "Male"
	local monarchTitle = RoyaltyEvents.getRoyalTitle(royalState.country, gender, true)
	
	royalState.isMonarch = true
	royalState.title = monarchTitle
	royalState.lineOfSuccession = 0
	royalState.reignYears = 0
	royalState.popularity = math.min(100, royalState.popularity + 20)
	
	-- Set flags
	lifeState.Flags.is_monarch = true
	lifeState.Flags.crowned = true
	
	return true, string.format("👑 Long live %s %s of %s!", monarchTitle, lifeState.Name or "Your Majesty", country.name)
end

function RoyaltyEvents.abdicate(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState then
		return false, "Not royalty"
	end
	
	royalState.isMonarch = false
	royalState.popularity = math.max(0, royalState.popularity - 30)
	
	lifeState.Flags.abdicated = true
	lifeState.Flags.is_monarch = nil
	lifeState.Flags.former_monarch = true
	
	return true, "You have abdicated the throne."
end

-- ════════════════════════════════════════════════════════════════════════════
-- SERIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

function RoyaltyEvents.serializeRoyalState(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState then
		return {
			isRoyal = false,
		}
	end
	
	return {
		isRoyal = royalState.isRoyal,
		isMonarch = royalState.isMonarch,
		country = royalState.country,
		countryName = royalState.countryName,
		countryEmoji = royalState.countryEmoji,
		palace = royalState.palace,
		title = royalState.title,
		lineOfSuccession = royalState.lineOfSuccession,
		popularity = royalState.popularity,
		scandals = royalState.scandals,
		dutiesCompleted = royalState.dutiesCompleted,
		reignYears = royalState.reignYears,
		wealth = royalState.wealth,
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #15: ROYAL RANK/TITLE PROGRESSION SYSTEM
-- Handles progression from Prince/Princess → Crown Prince/Princess → King/Queen
-- ════════════════════════════════════════════════════════════════════════════

RoyaltyEvents.TitleProgression = {
	male = {
		{ title = "Prince", lineOfSuccession = 6, ageMin = 0 },
		{ title = "Prince", lineOfSuccession = 5, ageMin = 0 },
		{ title = "Prince", lineOfSuccession = 4, ageMin = 0 },
		{ title = "Prince", lineOfSuccession = 3, ageMin = 0 },
		{ title = "Crown Prince", lineOfSuccession = 2, ageMin = 16 },
		{ title = "Crown Prince", lineOfSuccession = 1, ageMin = 18 },
		{ title = "King", lineOfSuccession = 0, ageMin = 21, isMonarch = true },
	},
	female = {
		{ title = "Princess", lineOfSuccession = 6, ageMin = 0 },
		{ title = "Princess", lineOfSuccession = 5, ageMin = 0 },
		{ title = "Princess", lineOfSuccession = 4, ageMin = 0 },
		{ title = "Princess", lineOfSuccession = 3, ageMin = 0 },
		{ title = "Crown Princess", lineOfSuccession = 2, ageMin = 16 },
		{ title = "Crown Princess", lineOfSuccession = 1, ageMin = 18 },
		{ title = "Queen", lineOfSuccession = 0, ageMin = 21, isMonarch = true },
	},
}

function RoyaltyEvents.updateRoyalTitle(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.isRoyal then
		return nil
	end
	
	local gender = (lifeState.Gender or "Male"):lower()
	local progression = RoyaltyEvents.TitleProgression[gender] or RoyaltyEvents.TitleProgression.male
	local age = lifeState.Age or 0
	local line = royalState.lineOfSuccession or 99
	
	-- Find appropriate title
	for _, rank in ipairs(progression) do
		if line <= rank.lineOfSuccession and age >= rank.ageMin then
			royalState.title = rank.title
			if rank.isMonarch and not royalState.isMonarch and line == 0 then
				-- They should be monarch but aren't yet - coronation pending
				lifeState.Flags = lifeState.Flags or {}
				lifeState.Flags.throne_ready = true
			end
			return rank.title
		end
	end
	
	return royalState.title
end

function RoyaltyEvents.advanceSuccession(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.isRoyal then
		return false, nil
	end
	
	-- Already monarch
	if royalState.isMonarch then
		return false, nil
	end
	
	local oldLine = royalState.lineOfSuccession
	
	-- Move up in succession
	if oldLine > 1 then
		royalState.lineOfSuccession = oldLine - 1
		RoyaltyEvents.updateRoyalTitle(lifeState)
		
		return true, string.format("You moved up to #%d in the line of succession! You are now %s.", royalState.lineOfSuccession, royalState.title)
	elseif oldLine == 1 then
		-- Ready for coronation
		lifeState.Flags = lifeState.Flags or {}
		lifeState.Flags.throne_ready = true
		lifeState.Flags.is_heir = true
		
		return true, "The monarch has passed. The crown will soon be yours..."
	end
	
	return false, nil
end

function RoyaltyEvents.triggerCoronation(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.isRoyal then
		return false, "Not royalty"
	end
	
	if royalState.isMonarch then
		return false, "Already a monarch"
	end
	
	local gender = (lifeState.Gender or "Male"):lower()
	local monarchTitle = gender == "female" and "Queen" or "King"
	
	royalState.isMonarch = true
	royalState.title = monarchTitle
	royalState.lineOfSuccession = 0
	royalState.reignYears = 0
	royalState.popularity = math.min(100, royalState.popularity + 20)
	
	lifeState.Flags = lifeState.Flags or {}
	lifeState.Flags.is_monarch = true
	lifeState.Flags.crowned = true
	lifeState.Flags.throne_ready = nil
	
	return true, string.format("👑 Long live %s %s! You have been crowned!", monarchTitle, lifeState.Name or "Your Majesty")
end

-- ════════════════════════════════════════════════════════════════════════════
-- ROYAL DUTY COMPLETION SYSTEM
-- ════════════════════════════════════════════════════════════════════════════

function RoyaltyEvents.getAvailableDuties(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.isRoyal then
		return {}
	end
	
	local age = lifeState.Age or 0
	local isMonarch = royalState.isMonarch
	local available = {}
	
	for _, duty in ipairs(RoyaltyEvents.RoyalDuties) do
		local meetsReqs = true
		
		if age < (duty.minAge or 0) then
			meetsReqs = false
		end
		
		if duty.requiresMonarch and not isMonarch then
			meetsReqs = false
		end
		
		if meetsReqs then
			table.insert(available, duty)
		end
	end
	
	return available
end

function RoyaltyEvents.performDuty(lifeState, dutyId)
	local royalState = lifeState.RoyalState
	if not royalState then
		return false, "Not royalty", nil
	end
	
	local duty = nil
	for _, d in ipairs(RoyaltyEvents.RoyalDuties) do
		if d.id == dutyId then
			duty = d
			break
		end
	end
	
	if not duty then
		return false, "Unknown duty", nil
	end
	
	-- Check requirements
	if lifeState.Age < (duty.minAge or 0) then
		return false, "Too young for this duty", nil
	end
	
	if duty.requiresMonarch and not royalState.isMonarch then
		return false, "Only the monarch can perform this duty", nil
	end
	
	local totalCost = (duty.wealthCost or 0) + (duty.charityCost or 0) + (duty.donationAmount or 0)
	if lifeState.Money < totalCost then
		return false, "Not enough funds", nil
	end
	
	-- Apply costs
	lifeState.Money = lifeState.Money - totalCost
	
	-- Apply popularity gain
	local popGain = math.random(duty.popularityEffect.min, duty.popularityEffect.max)
	royalState.popularity = math.min(100, royalState.popularity + popGain)
	royalState.dutiesCompleted = (royalState.dutiesCompleted or 0) + 1
	royalState.dutyStreak = (royalState.dutyStreak or 0) + 1
	
	-- Streak bonus
	if royalState.dutyStreak >= 5 then
		popGain = popGain + 5
		royalState.popularity = math.min(100, royalState.popularity + 5)
	end
	
	local result = {
		dutyId = duty.id,
		dutyName = duty.name,
		dutyEmoji = duty.emoji,
		popularityGain = popGain,
		cost = totalCost,
		newPopularity = royalState.popularity,
	}
	
	return true, string.format("%s Completed: %s (+%d popularity)", duty.emoji, duty.name, popGain), result
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #43: Export events in standard format for LifeEvents loader
-- The init.lua module loader expects .events, .Events, or .LifeEvents array
-- ════════════════════════════════════════════════════════════════════════════
RoyaltyEvents.events = RoyaltyEvents.LifeEvents

return RoyaltyEvents
