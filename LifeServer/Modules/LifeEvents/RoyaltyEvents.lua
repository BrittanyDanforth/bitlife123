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

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #8: Helper functions for royalty eligibility
-- ═══════════════════════════════════════════════════════════════════════════════
local function hasRoyaltyGamepass(state)
	return state.Flags and state.Flags.royalty_gamepass == true
end

local function isRoyal(state)
	return state.Flags and (state.Flags.is_royal == true or state.Flags.born_royal == true)
end

local function isMonarch(state)
	if not state.Flags then return false end
	return state.Flags.is_monarch == true or state.Flags.became_monarch == true
		or state.Flags.crowned == true
end

local function isHeirToThrone(state)
	if not state.Flags then return false end
	return state.Flags.heir_to_throne == true or state.Flags.crown_prince == true
		or state.Flags.crown_princess == true
end

local function getRoyalPopularity(state)
	if not state.Flags then return 50 end
	return state.Flags.royal_popularity or 50
end

-- CRITICAL FIX #9: Prevent royal events for non-royals
local function canHaveRoyalEvents(state)
	if not hasRoyaltyGamepass(state) then return false end
	if not isRoyal(state) then return false end
	return true
end

-- CRITICAL FIX #10: Check if player is exiled or abdicated
local function isActiveRoyal(state)
	if not isRoyal(state) then return false end
	if state.Flags and state.Flags.abdicated then return false end
	if state.Flags and state.Flags.exiled then return false end
	return true
end

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
		id = "secret_vacation",
		name = "Secret Vacation Exposed",
		emoji = "🏖️",
		severity = "medium",
		popularityLoss = { min = 10, max = 25 },
		description = "Tabloids reveal you took a secret vacation while citizens struggle",
		canDeny = true,
		denySuccessChance = 40,
	},
	{
		id = "leaked_photos",
		name = "Unflattering Photos",
		emoji = "📸",
		severity = "high",
		popularityLoss = { min = 15, max = 35 },
		description = "Unflattering photos leaked to the press",
		canSue = true,
		sueSuccessChance = 60,
		suePayout = { min = 500000, max = 5000000 },
	},
	{
		id = "tax_evasion",
		name = "Tax Controversy",
		emoji = "💰",
		severity = "severe",
		popularityLoss = { min = 20, max = 40 },
		description = "Questions raised about royal finances",
		canInvestigate = true,
		investigationCost = 1000000,
	},
	{
		id = "embarrassing_incident",
		name = "Embarrassing Public Moment",
		emoji = "😳",
		severity = "medium",
		popularityLoss = { min = 8, max = 20 },
		description = "Had an embarrassing moment at a public event",
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
	-- CRITICAL FIX #288: Added oneTime to birth announcement
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
		oneTime = true,
		maxOccurrences = 1,
		priority = "critical",
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
	-- CRITICAL FIX #286: Added oneTime to christening event
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
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { christened = true } },
		choices = {
			{
				text = "Sleep through the whole thing",
				effects = { Happiness = 5 },
				setFlags = { peaceful_baby = true, christened = true },
				feed = "You slept peacefully through your christening.",
			},
			{
				text = "Cry during the ceremony",
				effects = { Happiness = -2 },
				setFlags = { fussy_baby = true, christened = true },
				feed = "Your cries echoed through the chapel!",
			},
		},
	},
	-- CRITICAL FIX #289: Added oneTime to first public appearance
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
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { first_appearance_done = true } },
		choices = {
			{
				text = "Wave enthusiastically to the crowd",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 5 },
				setFlags = { natural_public_speaker = true, first_appearance_done = true },
				feed = "The crowd loved your enthusiastic wave!",
			},
			{
				text = "Hide behind your parent shyly",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = 2 },
				setFlags = { shy_royal = true, first_appearance_done = true },
				feed = "You were adorably shy at your first appearance.",
			},
			{
				text = "Make a funny face at the cameras",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 3, scandals = 0 },
				setFlags = { first_appearance_done = true },
				setFlags = { playful_royal = true },
				feed = "Your funny face became a viral meme!",
			},
		},
	},
	-- CRITICAL FIX #287: Added oneTime to royal education choice
	{
		id = "royal_education_choice",
		title = "🎓 Royal Education",
		emoji = "🎓",
		text = "It's time to decide your education. Will you attend the prestigious royal academies or break tradition?",
		minAge = 6,
		maxAge = 8,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { elite_education = true, palace_tutors = true, normal_school = true } },
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
		-- CRITICAL FIX #40: Eligibility check for royal events
		eligibility = function(state) return canHaveRoyalEvents(state) and isActiveRoyal(state) end,
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
		-- CRITICAL FIX #41: Eligibility check for royal horse riding
		eligibility = function(state) return canHaveRoyalEvents(state) end,
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
		-- CRITICAL FIX: Added text variations to prevent spam feeling
		textVariants = {
			"Christmas is a magical time at the palace! The nation watches as your family celebrates.",
			"The palace is decorated beautifully for the holidays. Lights twinkle everywhere and carol singers perform in the halls.",
			"It's Christmas morning! Presents, family time, and royal traditions await.",
			"The annual Christmas celebration at the palace is in full swing. Dignitaries, family, and festive cheer!",
			"Snow blankets the palace grounds as Christmas arrives. The whole kingdom feels the holiday spirit.",
		},
		text = "Christmas is a magical time at the palace! The nation watches as your family celebrates.",
		minAge = 6,
		maxAge = 14,
		isRoyalOnly = true,
		cooldown = 5, -- CRITICAL FIX: Increased from 2 to 5 to prevent spam
		-- CRITICAL FIX #42: Eligibility for Christmas events
		eligibility = function(state) return isActiveRoyal(state) end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		-- CRITICAL FIX #43: Eligibility for tutor events
		eligibility = function(state) return isActiveRoyal(state) end,
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
		-- CRITICAL FIX #44: Eligibility for summer vacation events
		eligibility = function(state) return isActiveRoyal(state) end,
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
		id = "royal_school_life",
		title = "🏫 Royal School Life",
		emoji = "🏫",
		text = "Life at your exclusive boarding school is full of privilege... and pressure.",
		minAge = 13,
		maxAge = 17,
		isRoyalOnly = true,
		requiresFlags = { in_boarding_school = true },
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		-- CRITICAL FIX #45: Eligibility for school events
		eligibility = function(state) return isActiveRoyal(state) end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		-- CRITICAL FIX #46: Eligibility for teen scandal events
		eligibility = function(state) return isActiveRoyal(state) end,
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
		-- CRITICAL FIX #47: Eligibility for charity patron events
		eligibility = function(state) return isActiveRoyal(state) end,
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
		-- CRITICAL FIX #48: Eligibility for interview events
		eligibility = function(state) return isActiveRoyal(state) end,
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
	-- CRITICAL FIX #292: Added oneTime to coming of age (only happens once at 18)
	{
		id = "coming_of_age",
		title = "🎂 Royal Coming of Age",
		emoji = "🎂",
		text = "You've reached the age of majority! A grand celebration is held in your honor. You now have official royal duties.",
		minAge = 18,
		maxAge = 18,
		isRoyalOnly = true,
		isMilestone = true,
		oneTime = true,
		maxOccurrences = 1,
		priority = "critical",
		conditions = { blockedFlags = { came_of_age = true } },
		choices = {
			{
				text = "Embrace your new responsibilities",
				effects = { Happiness = 5, Smarts = 5 },
				royaltyEffect = { popularity = 10 },
				setFlags = { dutiful_royal = true, came_of_age = true },
				feed = "You embraced your royal duties with grace.",
			},
			{
				text = "Party like there's no tomorrow",
				effects = { Happiness = 15, Health = -5 },
				royaltyEffect = { popularity = -5 },
				setFlags = { party_royal = true, came_of_age = true },
				feed = "Your coming-of-age party was legendary!",
			},
			{
				text = "Give a speech about your vision for the future",
				effects = { Happiness = 5, Smarts = 8 },
				royaltyEffect = { popularity = 15 },
				setFlags = { visionary_royal = true, public_speaker = true, came_of_age = true },
				feed = "Your speech inspired the nation!",
			},
		},
	},
	-- CRITICAL FIX #293: Added oneTime to military service
	{
		id = "military_service",
		title = "🎖️ Royal Military Service",
		emoji = "🎖️",
		text = "Following royal tradition, you're expected to serve in the military. This will be your first taste of discipline and duty.",
		minAge = 18,
		maxAge = 25,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { military_service = true, declined_service = true } },
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
	-- CRITICAL FIX #294: Added oneTime to first solo engagement
	{
		id = "first_solo_engagement",
		title = "✨ First Solo Engagement",
		emoji = "✨",
		text = "Today marks your first solo royal engagement! You'll represent the crown without your parents' guidance.",
		minAge = 18,
		maxAge = 22,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { solo_success = true, learned_from_mistake = true, public_disaster = true } },
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
		oneTime = true, -- CRITICAL FIX #308: Only trigger once to prevent duplicate romance events
		cooldown = 4, -- CRITICAL FIX: 10 year cooldown as extra safety
		maxOccurrences = 1,
		conditions = {
			-- CRITICAL FIX: Removed "married = nil" (doesn't work in Lua tables)
			-- blockedFlags handles the "not married" requirement
			blockedByFlags = { royal_courtship_done = true, engaged = true, married = true }
		},
		choices = {
			{
				text = "Date someone from nobility",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 5 },
				-- CRITICAL FIX: Dating is NOT engaged! Removed engaged = true
				setFlags = { dating_noble = true, traditional_romance = true, royal_courtship_done = true, dating = true, has_partner = true },
				feed = "You began courting someone from a noble family.",
				-- CRITICAL FIX: Create partner relationship
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					-- CRITICAL FIX: Partner should be OPPOSITE gender by default!
					-- BUG FIX: Normalize gender to lowercase for case-insensitive comparison
					local playerGender = (state.Gender or "male"):lower()
					local partnerIsMale = (playerGender == "female")  -- If player is female, partner is male
					local nobleNames = partnerIsMale 
						and {"Lord Sebastian", "Duke Edward", "Earl William", "Viscount James", "Baron Frederick"}
						or {"Lady Victoria", "Duchess Amelia", "Countess Elizabeth", "Baroness Catherine", "Lady Margaret"}
					local partnerName = nobleNames[math.random(1, #nobleNames)]
					state.Relationships.partner = {
						id = "partner_noble",
						name = partnerName,
						type = "romantic",
						role = partnerIsMale and "Boyfriend" or "Girlfriend",
						relationship = 70,
						age = (state.Age or 25) + math.random(-3, 3),
						gender = partnerIsMale and "male" or "female",
						alive = true,
					}
				end,
			},
			{
				text = "Date a commoner (break tradition!)",
				effects = { Happiness = 12 },
				royaltyEffect = { popularity = 15 },
				-- CRITICAL FIX: Dating is NOT engaged! Removed engaged = true
				setFlags = { dating_commoner = true, modern_royal = true, royal_courtship_done = true, dating = true, has_partner = true },
				feed = "The public loves your down-to-earth romance!",
				-- CRITICAL FIX: Create partner relationship
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					-- CRITICAL FIX: Partner should be OPPOSITE gender by default!
					-- BUG FIX: Normalize gender to lowercase for case-insensitive comparison
					local playerGender = (state.Gender or "male"):lower()
					local partnerIsMale = (playerGender == "female")  -- If player is female, partner is male
					local commonerNames = partnerIsMale 
						and {"Marcus", "Oliver", "Thomas", "Benjamin", "Christopher"}
						or {"Emma", "Sophie", "Kate", "Jessica", "Rachel"}
					local partnerName = commonerNames[math.random(1, #commonerNames)]
					state.Relationships.partner = {
						id = "partner_commoner",
						name = partnerName,
						type = "romantic",
						role = partnerIsMale and "Boyfriend" or "Girlfriend",
						relationship = 80,
						age = (state.Age or 25) + math.random(-5, 5),
						gender = partnerIsMale and "male" or "female",
						alive = true,
					}
				end,
			},
			{
				text = "Date a foreign royal (alliance)",
				effects = { Happiness = 6 },
				royaltyEffect = { popularity = 3 },
				-- CRITICAL FIX: Dating is NOT engaged! Removed engaged = true
				setFlags = { dating_foreign_royal = true, diplomatic_romance = true, royal_courtship_done = true, dating = true, has_partner = true },
				feed = "Your relationship could unite two kingdoms!",
				-- CRITICAL FIX: Create partner relationship
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					-- CRITICAL FIX: Partner should be OPPOSITE gender by default!
					-- BUG FIX: Normalize gender to lowercase for case-insensitive comparison
					local playerGender = (state.Gender or "male"):lower()
					local partnerIsMale = (playerGender == "female")  -- If player is female, partner is male
					local royalNames = partnerIsMale 
						and {"Prince Albert", "Prince Henrik", "Prince Guillaume", "Prince Frederik", "Prince Carl"}
						or {"Princess Madeleine", "Princess Elisabeth", "Princess Mary", "Princess Maxima", "Princess Victoria"}
					local partnerName = royalNames[math.random(1, #royalNames)]
					state.Relationships.partner = {
						id = "partner_royal",
						name = partnerName,
						type = "romantic",
						role = partnerIsMale and "Prince Consort" or "Princess Consort",
						relationship = 65,
						age = (state.Age or 25) + math.random(-3, 3),
						gender = partnerIsMale and "male" or "female",
						alive = true,
					}
				end,
			},
			{
				text = "Keep your relationship secret",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 0 },
				setFlags = { secret_romance = true, royal_courtship_done = true, dating = true, has_partner = true },
				feed = "You're keeping your love life private... for now.",
				-- CRITICAL FIX: Create secret partner relationship
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					-- CRITICAL FIX: Partner should be OPPOSITE gender by default!
					-- BUG FIX: Normalize gender to lowercase for case-insensitive comparison
					local playerGender = (state.Gender or "male"):lower()
					local partnerIsMale = (playerGender == "female")  -- If player is female, partner is male
					local secretNames = partnerIsMale 
						and {"Alex", "Jordan", "Morgan", "Taylor", "Casey"}
						or {"Sam", "Jordan", "Morgan", "Taylor", "Casey"}  -- Different names for female partners
					local partnerName = secretNames[math.random(1, #secretNames)]
					state.Relationships.partner = {
						id = "partner_secret",
						name = partnerName,
						type = "romantic",
						role = "Secret Lover",
						relationship = 75,
						age = (state.Age or 25) + math.random(-5, 5),
						gender = partnerIsMale and "male" or "female",
						alive = true,
					}
				end,
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
		oneTime = true, -- CRITICAL FIX #306: Only one wedding planning event
		conditions = { requiresFlags = { engaged = true } },
		choices = {
			{
				text = "Traditional grand ceremony ($50 million)",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = 20 },
				setFlags = { grand_wedding = true, married = true },
				feed = "Your fairy-tale wedding captivated the world!",
				-- CRITICAL FIX #540: Royal treasury covers wedding costs with overflow protection
				onResolve = function(state)
					local cost = 50000000
					-- Royal treasury can go into debt for state events, but cap deduction
					state.Money = math.max(0, (state.Money or 0) - cost)
					if state.AddFeed then
						state:AddFeed("💒 Your grand royal wedding cost $50 million!")
					end
				end,
			},
			{
				text = "Modern intimate wedding ($10 million)",
				effects = { Happiness = 18 },
				royaltyEffect = { popularity = 25 },
				setFlags = { intimate_wedding = true, relatable_royal = true, married = true },
				feed = "Your intimate wedding touched hearts everywhere!",
				-- CRITICAL FIX #541: Prevent negative money
				onResolve = function(state)
					state.Money = math.max(0, (state.Money or 0) - 10000000)
					if state.AddFeed then
						state:AddFeed("💒 Your intimate royal wedding cost $10 million.")
					end
				end,
			},
			{
				text = "Lavish destination wedding ($100 million)",
				effects = { Happiness = 12 },
				royaltyEffect = { popularity = -10 },
				setFlags = { extravagant_wedding = true, married = true },
				feed = "Your extravagant wedding drew criticism for its cost.",
				-- CRITICAL FIX #542: Prevent negative money
				onResolve = function(state)
					state.Money = math.max(0, (state.Money or 0) - 100000000)
					if state.AddFeed then
						state:AddFeed("💒 Your lavish royal wedding cost $100 million!")
					end
				end,
			},
			{
				text = "Elope secretly",
				effects = { Happiness = 20 },
				royaltyEffect = { popularity = 10, scandals = 1 },
				setFlags = { eloped = true, rebellious_royal = true, married = true },
				feed = "You shocked the world by eloping!",
				-- CRITICAL FIX #543: Prevent negative money
				onResolve = function(state)
					state.Money = math.max(0, (state.Money or 0) - 100000)
					if state.AddFeed then
						state:AddFeed("💒 You eloped and saved millions!")
					end
				end,
			},
		},
	},
	-- CRITICAL FIX #295: Added cooldown to heir birth event
	{
		id = "royal_heir_birth",
		title = "👶 An Heir is Born",
		emoji = "👶",
		text = "Congratulations! You've welcomed a new member to the royal family. The nation celebrates the birth of an heir!",
		minAge = 22,
		maxAge = 45,
		isRoyalOnly = true,
		cooldown = 3,
		maxOccurrences = 4,
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #191: Fixed throne succession spam
	-- Made oneTime and added proper blocking flags
	-- CRITICAL FIX #500: This event should NOT set throne_ready = true!
	-- User complaint: "BECOMING RULER triggered but my parent hasn't died!"
	-- The throne_succession event represents the monarch's FAILING health, not death
	-- Only the monarch's actual death (in advanceYearly) should set throne_ready!
	-- THRONE AND SUCCESSION
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "throne_succession",
		title = "👑 Succession Approaches",
		emoji = "👑",
		textVariants = {
			"The current monarch's health is failing. As next in line, you must prepare for the weight of the crown. The doctors say it could be weeks, months, or even years - but the time is coming.",
			"Your parent the monarch has been unwell lately. The palace is buzzing with whispered concerns about succession. You feel the weight of expectations growing heavier each day.",
			"News of the monarch's declining health has spread. Foreign dignitaries are already speculating about the transition. Are you ready to lead when the time comes?",
			"The monarch has had another health scare. The prime minister has requested a private meeting with you about 'continuity of government'. The reality is setting in.",
			"Advisors have begun briefing you more intensely on state matters. It's unspoken, but everyone knows why - the monarch's condition is worsening.",
		},
		text = "The current monarch's health is failing. As next in line, you must prepare for the weight of the crown.",
		minAge = 25,
		maxAge = 80,
		isRoyalOnly = true,
		oneTime = true, -- CRITICAL FIX: Only happens once
		maxOccurrences = 1,
		cooldown = 40,
		conditions = { 
			requiresFlags = { is_royalty = true },
			blockedFlags = { is_monarch = true, throne_ready = true, succession_approached = true, parent_monarch_deceased = true },
		},
		-- CRITICAL: Add eligibility to ensure player is actually in line of succession
		eligibility = function(state)
			if not state.RoyalState then return false end
			local rs = state.RoyalState
			-- Must be in line of succession (not just any royal)
			if (rs.lineOfSuccession or 99) > 3 then
				return false, "Too far from throne to receive this event"
			end
			-- Parent monarch must still be alive!
			if rs.parentMonarchDeceased then
				return false, "Parent monarch already deceased"
			end
			return true
		end,
		choices = {
			{
				text = "Accept your destiny with grace",
				effects = { Happiness = 5, Smarts = 5 },
				royaltyEffect = { popularity = 10 },
				-- CRITICAL FIX: Do NOT set throne_ready! Only set mental preparedness flags
				setFlags = { prepared_for_succession = true, ready_for_throne = true, succession_approached = true },
				feed = "You prepared yourself for the responsibilities ahead. But only when the monarch passes will the crown truly await you.",
			},
			{
				text = "Feel overwhelmed by the responsibility",
				effects = { Happiness = -10 },
				royaltyEffect = { popularity = 0 },
				-- CRITICAL FIX: Do NOT set throne_ready!
				setFlags = { prepared_for_succession = true, reluctant_heir = true, succession_approached = true },
				feed = "The weight of the crown weighs heavily on you. But for now, you wait.",
			},
			{
				text = "Consider abdicating before coronation",
				effects = { Happiness = 0 },
				royaltyEffect = { popularity = -20 },
				setFlags = { considering_abdication = true, succession_approached = true },
				feed = "Rumors spread that you may refuse the throne when the time comes.",
			},
		},
	},
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #187: Fixed coronation event spam
	-- CRITICAL FIX: Added parent death requirement!
	-- User complaint: "IT SAYS YOU'RE BECOMING A RULER BUT MY PARENT HASNT DIED!"
	-- Coronation should ONLY happen when parent monarch has actually passed away!
	-- CRITICAL FIX #501: Strengthened eligibility - REQUIRES parent_monarch_deceased flag
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "coronation",
		title = "👑 You're Becoming Ruler!",
		emoji = "👑",
		-- CRITICAL FIX #307: Simplified text for younger audience
		textVariants = {
			"It's finally happening! After the passing of the monarch, you are about to become the new King or Queen! The whole kingdom watches as you prepare to wear the crown and lead your people!",
			"The day has come. Following the monarch's death, the crown passes to you. Billions will watch as you take your place on the throne. Are you ready for this responsibility?",
			"A nation mourns, but a new era begins. With the passing of your parent, you are to be crowned. The weight of history rests on your shoulders now.",
			"The throne awaits. After your parent's passing, it's time for your coronation. Crowds gather, cameras roll, and history is about to be made.",
			"From heir to monarch. The crown that once sat on your parent's head will soon be yours. The coronation preparations are complete - your reign begins today.",
		},
		text = "It's finally happening! You are about to become the new King or Queen! Everyone is watching as you get ready to wear the crown and rule the kingdom!",
		minAge = 21, -- Can be crowned as young as 21 in some kingdoms
		maxAge = 90,
		isRoyalOnly = true,
		isMilestone = true,
		oneTime = true,
		maxOccurrences = 1,
		cooldown = 40,
		priority = "critical",
		conditions = { 
			-- CRITICAL FIX: throne_ready is set ONLY when parent monarch dies (in advanceYearly)
			requiresFlags = { throne_ready = true },
			blockedFlags = { is_monarch = true, crowned = true, coronation_completed = true },
		},
		-- CRITICAL FIX #501: STRICT eligibility - parent monarch MUST be dead!
		eligibility = function(state)
			local flags = state.Flags or {}
			
			-- CRITICAL: throne_ready flag MUST be set (set only when parent dies)
			if not flags.throne_ready then 
				return false, "Not ready for throne (throne_ready flag not set)"
			end
			
			-- CRITICAL: parent_monarch_deceased flag MUST be set!
			-- This flag is set ONLY in advanceYearly when parent actually dies
			if not flags.parent_monarch_deceased then
				return false, "Parent monarch has not died yet!"
			end
			
			-- Double-check RoyalState for monarch parent status
			if state.RoyalState then
				local rs = state.RoyalState
				
				-- Must be first in line of succession
				if (rs.lineOfSuccession or 99) ~= 1 then
					return false, "Not first in line for succession"
				end
				
				-- parentMonarchDeceased flag in RoyalState must also be true
				if not rs.parentMonarchDeceased then
					return false, "Parent monarch status doesn't confirm death"
				end
			else
				return false, "No RoyalState - not royalty"
			end
			
			return true
		end,
		choices = {
			{
				text = "Accept the crown proudly! 👑",
				effects = { Happiness = 20, Smarts = 5 },
				royaltyEffect = { popularity = 25, becomeMonarch = true },
				setFlags = { is_monarch = true, crowned = true, coronation_completed = true },
				feed = "Long live the King/Queen! You are now the ruler!",
			},
			{
				text = "Make it a fun, modern ceremony! 🎉",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = 30, becomeMonarch = true },
				setFlags = { is_monarch = true, crowned = true, modern_monarch = true, coronation_completed = true },
				feed = "Your fun ceremony started a new era!",
			},
			{
				text = "Say no - I don't want to rule",
				effects = { Happiness = -20 },
				royaltyEffect = { popularity = -50, abdicated = true },
				setFlags = { abdicated = true, coronation_declined = true, coronation_completed = true },
				feed = "You shocked everyone by refusing the crown!",
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
		-- CRITICAL FIX: Split into requiresFlags and blockedByFlags (nil doesn't work in Lua tables)
		conditions = {
			requiresFlags = { is_monarch = true },
			blockedByFlags = { gave_first_speech = true }
		},
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
		-- CRITICAL FIX #440: Add cooldown and maxOccurrences to prevent spam
		cooldown = 4,  -- At least 10 years between major scandals
		maxOccurrences = 3,  -- Max 3 major scandals per lifetime
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
		-- CRITICAL FIX #439: Add cooldown and maxOccurrences to prevent spam
		cooldown = 3,  -- At least 8 years between paparazzi incidents
		maxOccurrences = 4,  -- Max 4 times per lifetime
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
		title = "👨‍👩‍👧‍👦 Family Disagreement",
		emoji = "👨‍👩‍👧‍👦",
		-- CRITICAL FIX #315: Simplified text and added cooldown to prevent spam
		text = "There's some tension in the royal family. A relative is upset and might cause problems if this gets out to the public.",
		minAge = 18,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 3, -- CRITICAL FIX #315: 8 year cooldown to prevent spam
		maxOccurrences = 3, -- CRITICAL FIX: Limit to 3 family feuds per lifetime
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
	-- CRITICAL FIX #284: Added oneTime and blockedFlags to legacy event
	{
		id = "royal_legacy",
		title = "📜 Your Royal Legacy",
		emoji = "📜",
		text = "As you enter your later years, historians are already writing about your reign. What will you be remembered for?",
		minAge = 65,
		maxAge = 90,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { is_monarch = true },
			blockedFlags = { legacy_charity = true, legacy_reform = true, reign_to_death = true, considers_abolition = true },
		},
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
	-- CRITICAL FIX #276: Added cooldown and oneTime to fashion event
	{
		id = "royal_fashion_icon",
		title = "👗 Fashion Trendsetter",
		emoji = "👗",
		text = "Your fashion choices are making headlines! Designers are desperate to dress you and the public copies your every outfit.",
		minAge = 16,
		maxAge = 60,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { fashion_icon = true, traditional_dresser = true } },
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
	-- CRITICAL FIX #277: Added cooldown and oneTime to documentary event
	{
		id = "royal_documentary",
		title = "🎥 Royal Documentary",
		emoji = "🎥",
		text = "A major streaming service wants to produce a documentary about your life. This could humanize the monarchy... or expose too much.",
		minAge = 25,
		maxAge = 90,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { documentary_open = true, documentary_controlled = true, declined_documentary = true } },
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
	-- CRITICAL FIX #285: Added oneTime to social media event
	{
		id = "royal_social_media",
		title = "📱 Royal Social Media",
		emoji = "📱",
		text = "Should you join social media? It could modernize the monarchy's image, but also opens you to direct criticism.",
		minAge = 18,
		maxAge = 50,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { has_social_media = true, no_social_media = true } },
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
	-- CRITICAL FIX #278: Added cooldown to humanitarian mission
	{
		id = "royal_humanitarian_mission",
		title = "🌍 Humanitarian Mission",
		emoji = "🌍",
		text = "A devastating disaster has struck a foreign nation. You have the opportunity to lead a royal humanitarian mission.",
		minAge = 21,
		maxAge = 70,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 3,
		choices = {
			{
				text = "Lead the mission personally",
				effects = { Happiness = 15, Health = -5 },
				royaltyEffect = { popularity = 25 },
				setFlags = { humanitarian_leader = true },
				feed = "Your hands-on approach inspired the world!",
			},
		{
			text = "Donate significantly and send representatives ($5M)",
			effects = { Happiness = 8, Money = -5000000 },
			royaltyEffect = { popularity = 15 },
			setFlags = { generous_royal = true },
			feed = "Your generous donation made a real difference.",
			eligibility = function(state) return (state.Money or 0) >= 5000000, "💸 Need $5M for significant donation" end,
		},
			{
				text = "Make a public statement of support",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = 5 },
				feed = "Your words were appreciated, though some hoped for more.",
			},
		},
	},
	-- CRITICAL FIX #279: Added cooldown and oneTime to modernization debate
	{
		id = "royal_modernization_debate",
		title = "⚖️ Monarchy Modernization",
		emoji = "⚖️",
		text = "There's growing debate about modernizing the monarchy. Some want more transparency, others want to preserve tradition.",
		minAge = 30,
		maxAge = 90,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { is_monarch = true },
			blockedFlags = { modernizer = true, careful_reformer = true, traditionalist = true },
		},
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
	-- CRITICAL FIX #280: Added cooldown to sibling rivalry
	{
		id = "royal_sibling_rivalry",
		title = "👨‍👩‍👧‍👦 Sibling Dynamics",
		emoji = "👨‍👩‍👧‍👦",
		text = "Your royal sibling is making waves. Are they supportive or competitive? The media loves a good sibling story.",
		minAge = 18,
		maxAge = 70,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 3,
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
	-- CRITICAL FIX #281: Added cooldown to security threat event
	-- CRITICAL FIX: Added text variations and context - User complaint: "doesn't explain the threat"
	{
		id = "royal_security_threat",
		title = "🚨 Security Threat",
		emoji = "🚨",
		textVariants = {
			"Intelligence has intercepted communications about a plot targeting you. The threat comes from an extremist group opposed to the monarchy. Your security team is on high alert.",
			"A disgruntled former palace employee has made credible threats online. They claim to know your schedules and routines. The police are investigating but haven't made an arrest yet.",
			"Anonymous letters containing explicit threats have been received at several royal residences. The handwriting analysis suggests someone educated, possibly with insider knowledge.",
			"A car was spotted multiple times outside your residence with occupants photographing your movements. When approached, they fled. The license plate traces to a known radical organization.",
			"During a routine security sweep, your team discovered surveillance equipment had been planted near your private quarters. Someone has been watching you. Who, and for how long?",
			"Social media chatter has spiked about you in concerning ways. Specific plans are being discussed in encrypted channels. Your cyber security team is working to identify the source.",
			"A member of your household staff was caught selling information about your whereabouts. The buyer's identity is unknown. How deep does this breach go?",
			"International intelligence agencies have shared warnings about a potential attack during your upcoming public appearance. The threat is considered serious and credible.",
		},
		text = "Your security team has uncovered a credible threat against you. How do you handle this frightening situation?",
		minAge = 18,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 3,
		maxOccurrences = 3,
		choices = {
			{
				text = "Increase security dramatically",
				effects = { Happiness = -10, Health = 5 },
				royaltyEffect = { popularity = 0 },
				setFlags = { high_security = true },
				feed = "Your security is now fortress-level. Armed guards, armored vehicles, and 24/7 surveillance. You're safe but it feels like living in a prison.",
			},
			{
				text = "Continue normal duties to show strength",
				effects = { Happiness = 5, Health = -5 },
				royaltyEffect = { popularity = 15 },
				setFlags = { brave_royal = true },
				feed = "Your courage in the face of threats impressed everyone! Headlines praise your bravery. But the risk was real - your security team was terrified.",
			},
			{
				text = "Take a temporary break from public life",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = -5 },
				setFlags = { took_break = true },
				feed = "Safety first. You retreated to a secure location until the threat was neutralized. Some called it wise, others called it cowardly.",
			},
			{
				text = "Address it publicly - transparency wins",
				effects = { Happiness = 0, Health = -2 },
				royaltyEffect = { popularity = 10 },
				setFlags = { transparent_royal = true },
				feed = "You held a press conference acknowledging the threat and reassuring the public. Your honesty was refreshing, though some worried it showed vulnerability.",
			},
		},
	},
	-- CRITICAL FIX #282: Added oneTime and blockedFlags to book deal
	{
		id = "royal_book_deal",
		title = "📚 Royal Memoirs",
		emoji = "📚",
		text = "A publisher is offering a massive advance for your memoirs. What will you reveal?",
		minAge = 35,
		maxAge = 90,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { wrote_tellall = true, wrote_memoirs = true, declined_memoirs = true } },
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
	-- CRITICAL FIX #283: Added cooldown to commonwealth tour
	{
		id = "royal_commonwealth_tour",
		title = "🌐 Commonwealth Tour",
		emoji = "🌐",
		text = "It's time for a major tour of Commonwealth nations. These tours are exhausting but vital for diplomatic relations.",
		minAge = 21,
		maxAge = 75,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 5,
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #226-240: MASSIVE ROYALTY EVENT EXPANSION
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "milestone_royal_birthday",
		title = "🎂 Milestone Birthday",
		emoji = "🎂",
		text = "You're celebrating a milestone birthday! The nation wants to celebrate with you.",
		minAge = 18,
		maxAge = 100,
		isRoyalOnly = true,
		cooldown = 4,
		choices = {
		{ text = "Grand public celebration ($500K)", effects = { Happiness = 15, Money = -500000 }, royaltyEffect = { popularity = 15 }, feed = "The nation celebrated!", eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K for celebration" end },
		{ text = "Intimate family gathering", effects = { Happiness = 20 }, royaltyEffect = { popularity = 5 }, feed = "A private celebration." },
		{ text = "Charitable donation instead ($1M)", effects = { Happiness = 15, Money = -1000000 }, royaltyEffect = { popularity = 20 }, feed = "You asked for charity donations!", eligibility = function(state) return (state.Money or 0) >= 1000000, "💸 Need $1M for charitable donation" end },
		},
	},
	{
		id = "royal_patronage_request",
		title = "🎗️ Patronage Request",
		emoji = "🎗️",
		text = "A charity has asked you to become their patron.",
		minAge = 21,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 3,
		choices = {
			{ text = "Accept and champion", effects = { Happiness = 10 }, royaltyEffect = { popularity = 12 }, feed = "You became a passionate advocate!" },
			{ text = "Accept ceremonially", effects = { Happiness = 5 }, royaltyEffect = { popularity = 5 }, feed = "You lent your name." },
			{ text = "Decline", effects = { Happiness = 0 }, royaltyEffect = { popularity = -3 }, feed = "Too many commitments." },
		},
	},
	{
		id = "royal_scandal_erupts",
		title = "📰 Scandal Erupts!",
		emoji = "📰",
		text = "The tabloids are running an embarrassing story about you!",
		minAge = 18,
		maxAge = 80,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
		{ text = "Issue dignified denial", effects = { Happiness = -10 }, royaltyEffect = { popularity = -5, scandals = 1 }, feed = "Your denial was measured." },
		{ text = "Sue for defamation ($500K)", effects = { Happiness = -15, Money = -500000 }, royaltyEffect = { popularity = -3, scandals = 1 }, feed = "You took legal action.", eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K for legal fees" end },
			{ text = "Ignore it", effects = { Happiness = -5 }, royaltyEffect = { popularity = -10, scandals = 1 }, feed = "Your silence spoke volumes." },
			{ text = "Address with humor", effects = { Happiness = 5 }, royaltyEffect = { popularity = 10 }, feed = "Your wit won the day!" },
		},
	},
	{
		id = "christmas_speech",
		title = "📺 Annual Address",
		emoji = "📺",
		-- CRITICAL FIX: Added text variations for variety
		textVariants = {
			"Time for your annual address to the nation.",
			"The cameras are ready. Millions await your words of hope and reflection.",
			"Christmas Day. The nation gathers around their screens to hear your annual message.",
			"Your speech writers have prepared remarks, but the delivery is all you.",
			"It's broadcast time. Your Christmas message will be heard by millions worldwide.",
		},
		text = "Time for your annual address to the nation.",
		minAge = 25,
		maxAge = 100,
		isRoyalOnly = true,
		cooldown = 5, -- CRITICAL FIX: Increased from 2 to 5 to prevent spam
		conditions = { requiresFlags = { is_monarch = true } },
		choices = {
			{ text = "Uplifting and hopeful", effects = { Happiness = 10 }, royaltyEffect = { popularity = 12 }, feed = "Your message resonated." },
			{ text = "Serious and reflective", effects = { Happiness = 5 }, royaltyEffect = { popularity = 8 }, feed = "Your address was thoughtful." },
			{ text = "Personal and vulnerable", effects = { Happiness = 15 }, royaltyEffect = { popularity = 20 }, feed = "Your sharing touched millions!" },
		},
	},
	{
		id = "your_royal_wedding",
		title = "💒 Your Royal Wedding!",
		emoji = "💒",
		text = "Your wedding day has arrived! The world is watching!",
		minAge = 21,
		maxAge = 60,
		isRoyalOnly = true,
		oneTime = true,
		conditions = { blockedFlags = { married = true } },
		choices = {
			{ text = "Traditional grand ceremony ($5M)", effects = { Happiness = 25, Money = -5000000 }, royaltyEffect = { popularity = 30 }, setFlags = { married = true }, feed = "A fairy tale wedding!", eligibility = function(state) return (state.Money or 0) >= 5000000, "💸 Need $5M for grand ceremony" end },
			{ text = "Modern celebration ($2M)", effects = { Happiness = 22, Money = -2000000 }, royaltyEffect = { popularity = 20 }, setFlags = { married = true }, feed = "A modern royal wedding!", eligibility = function(state) return (state.Money or 0) >= 2000000, "💸 Need $2M for modern wedding" end },
			{ text = "Private ceremony ($500K)", effects = { Happiness = 20, Money = -500000 }, royaltyEffect = { popularity = 10 }, setFlags = { married = true }, feed = "Beautifully intimate.", eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K for private ceremony" end },
			-- CRITICAL FIX: FREE option to prevent hard lock!
			{ text = "Simple state-funded ceremony", effects = { Happiness = 18 }, royaltyEffect = { popularity = 5 }, setFlags = { married = true }, feed = "💒 A modest royal wedding. Some call it refreshingly modern, others disappointed." },
		},
	},
	{
		id = "royal_heir_born",
		title = "👶 Royal Heir Born!",
		emoji = "👶",
		text = "A new heir has been born! The nation celebrates!",
		minAge = 22,
		maxAge = 50,
		isRoyalOnly = true,
		oneTime = true,
		conditions = { requiresFlags = { married = true }, blockedFlags = { has_heir = true } },
		choices = {
			{ text = "Grand announcement", effects = { Happiness = 30 }, royaltyEffect = { popularity = 25 }, setFlags = { has_heir = true }, feed = "The nation celebrates!" },
			{ text = "Private time first", effects = { Happiness = 35 }, royaltyEffect = { popularity = 15 }, setFlags = { has_heir = true }, feed = "Precious private moments." },
		},
	},
	{
		id = "constitutional_crisis",
		title = "⚠️ Constitutional Crisis",
		emoji = "⚠️",
		text = "A political crisis threatens the nation. As monarch, you have a role.",
		minAge = 30,
		maxAge = 90,
		isRoyalOnly = true,
		oneTime = true,
		conditions = { requiresFlags = { is_monarch = true } },
		choices = {
			{ text = "Stay neutral", effects = { Happiness = -10 }, royaltyEffect = { popularity = 5 }, feed = "You maintained constitutional neutrality." },
			{ text = "Mediate privately", effects = { Happiness = 5, Smarts = 10 }, royaltyEffect = { popularity = 20 }, feed = "Your quiet diplomacy helped!" },
			{ text = "Call for unity", effects = { Happiness = 10 }, royaltyEffect = { popularity = 15 }, feed = "Your call resonated." },
		},
	},
	{
		id = "royal_philanthropy_initiative",
		title = "❤️ Philanthropy Initiative",
		emoji = "❤️",
		text = "You can make a real difference. What cause will you champion?",
		minAge = 25,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{ text = "Mental health ($2M)", effects = { Happiness = 15, Money = -2000000 }, royaltyEffect = { popularity = 20 }, feed = "Your campaign saved lives!", eligibility = function(state) return (state.Money or 0) >= 2000000, "💸 Need $2M for mental health initiative" end },
			{ text = "Environment ($3M)", effects = { Happiness = 12, Money = -3000000 }, royaltyEffect = { popularity = 18 }, feed = "You're protecting the planet!", eligibility = function(state) return (state.Money or 0) >= 3000000, "💸 Need $3M for environment initiative" end },
			{ text = "Youth empowerment ($1.5M)", effects = { Happiness = 15, Money = -1500000 }, royaltyEffect = { popularity = 22 }, feed = "Inspiring young leaders!", eligibility = function(state) return (state.Money or 0) >= 1500000, "💸 Need $1.5M for youth initiative" end },
			-- CRITICAL FIX: FREE options to prevent hard lock!
			{ text = "Raise awareness through speeches", effects = { Happiness = 10, Smarts = 5 }, royaltyEffect = { popularity = 12 }, feed = "❤️ Your passionate advocacy is inspiring change! Words matter!" },
			{ text = "Volunteer your time personally", effects = { Happiness = 12, Health = -2 }, royaltyEffect = { popularity = 15 }, feed = "❤️ Rolling up your sleeves! The public loves seeing you in the trenches!" },
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #321: EXPANDED ROYAL PROGRESSION EVENTS
	-- More immersive royal life events for better gameplay
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "royal_council_meeting",
		title = "👑 Royal Council Meeting",
		emoji = "👑",
		text = "The royal council has convened to discuss important matters of state. Your input is requested on several key issues.",
		minAge = 21,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 3,
		conditions = { requiresFlags = { is_monarch = true } },
		choices = {
			{ text = "Focus on economic reforms", effects = { Smarts = 5 }, royaltyEffect = { popularity = 8 }, feed = "Your economic vision impressed the council." },
			{ text = "Prioritize social welfare programs", effects = { Happiness = 8 }, royaltyEffect = { popularity = 15 }, feed = "The people appreciate your compassion." },
			{ text = "Strengthen military and defense", effects = { Smarts = 3, Health = 2 }, royaltyEffect = { popularity = 5 }, feed = "The kingdom is secure under your leadership." },
			{ text = "Delegate to your advisors", effects = { Happiness = 5 }, royaltyEffect = { popularity = -3 }, feed = "You trust your council to handle affairs." },
		},
	},
	{
		id = "royal_scandal_tabloids",
		title = "📰 Tabloid Attack!",
		emoji = "📰",
		text = "A tabloid newspaper has published embarrassing photos and rumors about you. The palace is in damage control mode!",
		minAge = 18,
		maxAge = 80,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		baseChance = 0.55,
		choices = {
			{ text = "Sue the tabloid for defamation ($500K)", effects = { Happiness = -5, Money = -500000 }, royaltyEffect = { popularity = 5 }, feed = "You fought back legally!", eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K for legal fees" end },
			{ text = "Issue a dignified statement", effects = { Happiness = -3 }, royaltyEffect = { popularity = 8 }, feed = "Your grace under pressure impressed many." },
			{ text = "Ignore it completely", effects = { Happiness = -8 }, royaltyEffect = { popularity = -10 }, feed = "Your silence let rumors spread." },
			{ text = "Turn it into a joke on social media", effects = { Happiness = 10 }, royaltyEffect = { popularity = 15 }, feed = "Your sense of humor won the day!" },
		},
	},
	{
		id = "royal_investment_opportunity",
		title = "💎 Royal Investment",
		emoji = "💎",
		text = "Your financial advisors present several investment opportunities to grow the royal fortune.",
		minAge = 25,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{
				text = "Invest in sustainable energy",
				effects = { Smarts = 3 },
				royaltyEffect = { popularity = 10 },
				feed = "A forward-thinking investment!",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.6 then
						state.Money = (state.Money or 0) + 5000000
						state:AddFeed("💰 Your green investment paid off! +$5M")
					else
						-- CRITICAL FIX #544: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 2000000)
						state:AddFeed("📉 The investment underperformed. -$2M")
					end
				end,
			},
			{
				text = "Acquire a luxury resort",
				effects = { Happiness = 8 },
				feed = "A new vacation spot for the family!",
				onResolve = function(state)
					-- CRITICAL FIX #545: Prevent negative money on large purchase
					state.Money = math.max(0, (state.Money or 0) - 20000000)
					local roll = math.random()
					if roll < 0.5 then
						state.Money = (state.Money or 0) + 8000000
						state:AddFeed("🏖️ The resort is profitable! Annual income increased.")
					end
				end,
			},
		{
			text = "Start a charitable foundation ($10M)",
			effects = { Happiness = 15, Money = -10000000 },
			royaltyEffect = { popularity = 25 },
			setFlags = { royal_foundation = true },
			feed = "Your foundation will help millions!",
			eligibility = function(state) return (state.Money or 0) >= 10000000, "💸 Need $10M to start a foundation" end,
		},
			{
				text = "Keep the money in stable bonds",
				effects = { Happiness = 3 },
				feed = "Safe and steady wealth management.",
			},
		},
	},
	{
		id = "royal_pet_drama",
		title = "🐕 Royal Pet Situation",
		emoji = "🐕",
		text = "Your beloved royal pet is causing quite a stir! The palace staff have concerns.",
		minAge = 10,
		maxAge = 80,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
		{ text = "The pet stays - hire more staff ($50K)", effects = { Happiness = 10, Money = -50000 }, feed = "Your loyalty to your pet is admirable!", eligibility = function(state) return (state.Money or 0) >= 50000, "💸 Need $50K for staff" end },
		{ text = "Get professional training ($20K)", effects = { Happiness = 5, Money = -20000 }, feed = "Your pet is now palace-worthy.", eligibility = function(state) return (state.Money or 0) >= 20000, "💸 Need $20K for training" end },
		{ text = "Find a loving new home", effects = { Happiness = -15 }, royaltyEffect = { popularity = -5 }, feed = "A hard decision but necessary." },
		{ text = "Add MORE pets! ($100K)", effects = { Happiness = 15, Money = -100000 }, royaltyEffect = { popularity = 8 }, feed = "The palace is now a zoo! The public loves it.", eligibility = function(state) return (state.Money or 0) >= 100000, "💸 Need $100K for more pets" end },
		},
	},
	{
		id = "royal_university_degree",
		title = "🎓 Royal Education Decision",
		emoji = "🎓",
		text = "You have the opportunity to pursue higher education at one of the world's most prestigious universities.",
		minAge = 18,
		maxAge = 25,
		isRoyalOnly = true,
		oneTime = true,
		conditions = { blockedFlags = { royal_degree = true } },
		choices = {
			{ text = "Oxford - History and Politics", effects = { Smarts = 15, Happiness = 5 }, royaltyEffect = { popularity = 10 }, setFlags = { royal_degree = true, oxford_grad = true }, feed = "You graduated from Oxford with honors!" },
			{ text = "Cambridge - Economics", effects = { Smarts = 12, Happiness = 3 }, royaltyEffect = { popularity = 10 }, setFlags = { royal_degree = true, cambridge_grad = true }, feed = "A Cambridge economist on the throne!" },
			{ text = "Harvard - International Relations", effects = { Smarts = 10, Happiness = 8 }, royaltyEffect = { popularity = 8 }, setFlags = { royal_degree = true, harvard_grad = true }, feed = "You expanded your global perspective." },
			{ text = "Skip university - learn through royal duties", effects = { Happiness = 5 }, royaltyEffect = { popularity = -5 }, setFlags = { no_university = true }, feed = "Some lessons can't be taught in classrooms." },
		},
	},
	{
		id = "royal_love_triangle",
		title = "💔 Royal Love Complications",
		emoji = "💔",
		text = "Rumors are swirling about a love triangle involving you and two eligible nobles. The tabloids are having a field day!",
		minAge = 20,
		maxAge = 40,
		isRoyalOnly = true,
		oneTime = true,
		conditions = { blockedFlags = { married = true, love_triangle_resolved = true } },
		choices = {
			{ text = "Choose the one your heart desires", effects = { Happiness = 20 }, royaltyEffect = { popularity = 5 }, setFlags = { love_triangle_resolved = true, passionate_royal = true }, feed = "Love wins! The public adores your romance." },
			{ text = "Choose the politically advantageous match", effects = { Happiness = -5, Smarts = 5 }, royaltyEffect = { popularity = 10 }, setFlags = { love_triangle_resolved = true, strategic_royal = true }, feed = "A wise choice for the kingdom." },
			{ text = "Reject both and focus on yourself", effects = { Happiness = 5 }, royaltyEffect = { popularity = -3 }, setFlags = { love_triangle_resolved = true, independent_royal = true }, feed = "You're not ready to settle down." },
			{ text = "Try to keep seeing both secretly", effects = { Happiness = 10 }, royaltyEffect = { popularity = -15, scandals = 1 }, setFlags = { love_triangle_resolved = true, scandalous_royal = true }, feed = "This can only end badly..." },
		},
	},
	{
		id = "royal_balcony_appearance",
		title = "👋 Balcony Appearance",
		emoji = "👋",
		text = "Thousands have gathered outside the palace for a royal occasion. Time for the famous balcony wave!",
		minAge = 12, -- CRITICAL FIX #323: Was 5, now 12 - babies shouldn't wave to crowds independently
		maxAge = 100,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{ text = "Wave enthusiastically and blow kisses", effects = { Happiness = 12 }, royaltyEffect = { popularity = 10 }, feed = "The crowd went wild!" },
			{ text = "Maintain dignified composure", effects = { Happiness = 5 }, royaltyEffect = { popularity = 5 }, feed = "Regal and refined as always." },
			{ text = "Make funny faces at the kids below", effects = { Happiness = 15 }, royaltyEffect = { popularity = 15 }, feed = "You're the people's favorite!" },
			{ text = "Quickly retreat inside", effects = { Happiness = -5 }, royaltyEffect = { popularity = -8 }, feed = "The crowd was disappointed." },
		},
	},
	{
		id = "royal_state_dinner",
		title = "🍽️ State Dinner",
		emoji = "🍽️",
		text = "A foreign leader is visiting for an important state dinner. Every word and action will be scrutinized.",
		minAge = 18,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 3,
		choices = {
			{ text = "Be warm and personally engaging", effects = { Happiness = 8 }, royaltyEffect = { popularity = 12 }, feed = "You charmed the diplomatic delegation!" },
			{ text = "Stick strictly to protocol", effects = { Smarts = 3 }, royaltyEffect = { popularity = 5 }, feed = "A flawless diplomatic performance." },
			{ text = "Make a bold political statement", effects = { Happiness = 5, Smarts = 5 }, royaltyEffect = { popularity = -5 }, feed = "Controversial but memorable." },
			{ text = "Focus on learning about their culture", effects = { Smarts = 8, Happiness = 5 }, royaltyEffect = { popularity = 10 }, feed = "Your cultural curiosity impressed everyone." },
		},
	},
	{
		id = "royal_hunting_trip",
		title = "🦌 Royal Hunt",
		emoji = "🦌",
		text = "The royal hunting party is being organized. Traditional sport or modern controversy?",
		minAge = 16,
		maxAge = 75,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{ text = "Lead the traditional hunt", effects = { Health = 5, Happiness = 8 }, royaltyEffect = { popularity = -10 }, feed = "Traditionalists approved, activists didn't." },
			{ text = "Convert it to a photography safari", effects = { Happiness = 10, Smarts = 3 }, royaltyEffect = { popularity = 15 }, feed = "Modern and environmentally conscious!" },
			{ text = "Cancel the hunt entirely", effects = { Happiness = -3 }, royaltyEffect = { popularity = 12 }, feed = "Animal rights groups praised your decision." },
			{ text = "Make it a conservation education event", effects = { Happiness = 8, Smarts = 5 }, royaltyEffect = { popularity = 20 }, setFlags = { conservation_royal = true }, feed = "You turned tradition into progress!" },
		},
	},
	{
		id = "royal_secret_revealed",
		title = "🤫 Royal Secret Exposed",
		emoji = "🤫",
		text = "A palace insider has leaked information about a royal secret to the press. How do you handle this crisis?",
		minAge = 20,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 3,
		baseChance = 0.45,
		choices = {
			{ text = "Get ahead of the story - own it publicly", effects = { Happiness = -10 }, royaltyEffect = { popularity = 10 }, feed = "Your honesty was respected." },
			{ text = "Deny everything through official channels", effects = { Happiness = -5 }, royaltyEffect = { popularity = -15 }, feed = "The cover-up made it worse." },
			{ text = "Fire the leaker and tighten security", effects = { Happiness = -8 }, royaltyEffect = { popularity = -5 }, feed = "Trust in the palace is broken." },
			{ text = "Address it with humor on social media", effects = { Happiness = 8 }, royaltyEffect = { popularity = 20 }, feed = "Your relatability won the day!" },
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #451: MASSIVE ROYALTY EVENT EXPANSION
	-- 25+ new events for deeper royal gameplay
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- ROYAL WEDDING DRAMA
	{
		id = "wedding_planning_crisis",
		title = "💍 Wedding Drama",
		emoji = "💍",
		text = "Your wedding planning has hit a major snag. The tabloids are calling it the 'Royal Wedding Disaster'.",
		minAge = 18,
		maxAge = 45,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { engaged = true },
			blockedFlags = { married = true },
		},
		choices = {
			{ text = "Scale it back to intimate ceremony", effects = { Happiness = 10 }, royaltyEffect = { popularity = 15 }, setFlags = { intimate_wedding = true }, feed = "The simple elegance won hearts worldwide." },
			{ text = "Double down and go bigger", effects = { Happiness = 5 }, royaltyEffect = { popularity = -5, wealthCost = 10000000 }, setFlags = { extravagant_wedding = true }, feed = "The most expensive royal wedding in history!" },
			{ text = "Postpone until things calm down", effects = { Happiness = -10 }, royaltyEffect = { popularity = 5 }, setFlags = { postponed_wedding = true }, feed = "A wise decision to wait." },
			{ text = "Elope secretly", effects = { Happiness = 25 }, royaltyEffect = { popularity = -20, scandals = 1 }, setFlags = { eloped = true }, feed = "You shocked the world with a secret wedding!" },
		},
	},
	
	-- ROYAL BABY ANNOUNCEMENT
	{
		id = "royal_baby_announcement",
		title = "👶 Heir Announcement",
		emoji = "👶",
		text = "You're expecting a royal baby! The world awaits the announcement of the future heir.",
		minAge = 20,
		maxAge = 45,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 4,
		conditions = { 
			requiresFlags = { married = true },
		},
		choices = {
			{ text = "Grand palace balcony announcement", effects = { Happiness = 20 }, royaltyEffect = { popularity = 25 }, setFlags = { traditional_announcement = true }, feed = "The nation celebrates the royal baby!" },
			{ text = "Simple social media post", effects = { Happiness = 15 }, royaltyEffect = { popularity = 15 }, setFlags = { modern_parents = true }, feed = "The tweet broke the internet!" },
			{ text = "Keep it private as long as possible", effects = { Happiness = 10 }, royaltyEffect = { popularity = -5 }, setFlags = { private_parents = true }, feed = "You protected your privacy." },
			{ text = "Exclusive magazine deal", effects = { Happiness = 8 }, royaltyEffect = { popularity = -10, wealthGain = 5000000 }, setFlags = { sold_story = true }, feed = "Selling royal news? The public is divided." },
		},
	},
	
	-- VISITING DISASTER ZONES
	{
		id = "disaster_relief_visit",
		title = "🌊 Disaster Response",
		emoji = "🌊",
		text = "A terrible natural disaster has struck. The palace wants you to visit affected areas and show support.",
		minAge = 16,
		maxAge = 85,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 5,
		choices = {
			{ text = "Roll up sleeves and help personally", effects = { Happiness = 15, Health = -5 }, royaltyEffect = { popularity = 30 }, setFlags = { hands_on_royal = true }, feed = "Photos of you helping went viral!" },
			{ text = "Make a large personal donation", effects = { Happiness = 8 }, royaltyEffect = { popularity = 20, wealthCost = 1000000 }, setFlags = { generous_royal = true }, feed = "Your generosity was praised." },
			{ text = "Brief photo-op visit only", effects = { Happiness = 3 }, royaltyEffect = { popularity = 5 }, feed = "Critics called it performative." },
			{ text = "Stay away - too dangerous", effects = { Happiness = -10 }, royaltyEffect = { popularity = -25 }, setFlags = { absent_royal = true }, feed = "The public was disappointed by your absence." },
		},
	},
	
	-- ROYAL INVESTMENT SCANDAL
	{
		id = "investment_scandal",
		title = "💸 Investment Controversy",
		emoji = "💸",
		text = "Journalists discovered your investments in controversial industries. This could be a PR nightmare.",
		minAge = 25,
		maxAge = 80,
		isRoyalOnly = true,
		cooldown = 3,
		maxOccurrences = 2,
		choices = {
			{ text = "Divest immediately and apologize", effects = { Happiness = -5 }, royaltyEffect = { popularity = 10 }, setFlags = { ethical_investor = true }, feed = "Your swift action was praised." },
			{ text = "Defend the investments as legal", effects = { Happiness = 0 }, royaltyEffect = { popularity = -15 }, feed = "Technically legal, but the optics were bad." },
			{ text = "Create an ethical investment fund", effects = { Happiness = 10, Smarts = 5 }, royaltyEffect = { popularity = 25 }, setFlags = { created_ethical_fund = true }, feed = "You turned controversy into opportunity!" },
			{ text = "Blame your financial advisors", effects = { Happiness = -5 }, royaltyEffect = { popularity = -10 }, setFlags = { blamed_staff = true }, feed = "Passing the buck didn't go over well." },
		},
	},
	
	-- ROYAL SPORT EVENT
	{
		id = "major_sporting_event",
		title = "🏆 Royal Box Appearance",
		emoji = "🏆",
		text = "The national team is in the finals! Your presence in the royal box would mean everything to the players.",
		minAge = 12,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 3,
		maxOccurrences = 8,
		choices = {
			{ text = "Attend and cheer enthusiastically", effects = { Happiness = 15 }, royaltyEffect = { popularity = 15 }, feed = "Your passion matched the crowd's!" },
			{ text = "Attend with diplomatic neutrality", effects = { Happiness = 5 }, royaltyEffect = { popularity = 5 }, feed = "Professional as always." },
			{ text = "Meet the team in the locker room", effects = { Happiness = 10 }, royaltyEffect = { popularity = 12 }, setFlags = { team_supporter = true }, feed = "The players were thrilled to meet you!" },
			{ text = "Skip it for a scheduled duty", effects = { Happiness = -8 }, royaltyEffect = { popularity = -5 }, feed = "Duty before fun." },
		},
	},
	
	-- ROYAL RIVALRY WITH SIBLING
	{
		id = "sibling_rivalry_public",
		title = "👥 Sibling Rivalry",
		emoji = "👥",
		text = "The tabloids have noticed tension between you and your royal sibling. They're turning it into a public feud.",
		minAge = 16,
		maxAge = 60,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 3,
		conditions = { blockedFlags = { only_child = true } },
		choices = {
			{ text = "Public joint appearance to show unity", effects = { Happiness = 8 }, royaltyEffect = { popularity = 15 }, setFlags = { united_siblings = true }, feed = "You silenced the rumors together." },
			{ text = "Ignore the press entirely", effects = { Happiness = -5 }, royaltyEffect = { popularity = -5 }, feed = "The speculation continued." },
			{ text = "Leak your side of the story", effects = { Happiness = 5 }, royaltyEffect = { popularity = -10, scandals = 1 }, setFlags = { tabloid_source = true }, feed = "Playing the media game has consequences." },
			{ text = "Address it honestly in interview", effects = { Happiness = 10 }, royaltyEffect = { popularity = 20 }, setFlags = { honest_royal = true }, feed = "Your openness resonated with the public." },
		},
	},
	
	-- ROYAL DIPLOMATIC CRISIS
	{
		id = "diplomatic_incident",
		title = "🌍 Diplomatic Crisis",
		emoji = "🌍",
		text = "Your comments during an official visit were misinterpreted. It's now an international incident!",
		minAge = 21,
		maxAge = 80,
		isRoyalOnly = true,
		cooldown = 3,
		maxOccurrences = 2,
		choices = {
			{ text = "Issue a formal apology", effects = { Happiness = -10 }, royaltyEffect = { popularity = 10 }, setFlags = { apologized_diplomatically = true }, feed = "Crisis averted through diplomacy." },
			{ text = "Stand by your words", effects = { Happiness = 5 }, royaltyEffect = { popularity = -15 }, setFlags = { stubborn_royal = true }, feed = "Some admired your spine, others didn't." },
			{ text = "Blame the translation", effects = { Happiness = 0 }, royaltyEffect = { popularity = 0 }, feed = "A convenient excuse, but did anyone believe it?" },
			{ text = "Make a personal call to the leader", effects = { Happiness = 5, Smarts = 8 }, royaltyEffect = { popularity = 20 }, setFlags = { personal_diplomacy = true }, feed = "Your personal touch resolved everything!" },
		},
	},
	
	-- ROYAL HEALTH SCARE
	{
		id = "royal_health_scare",
		title = "🏥 Health Crisis",
		emoji = "🏥",
		text = "Rumors are spreading about your health. The palace must decide how to handle public concerns.",
		minAge = 30,
		maxAge = 95,
		isRoyalOnly = true,
		cooldown = 4,
		maxOccurrences = 2,
		choices = {
			{ text = "Full transparency about your condition", effects = { Happiness = 10, Health = 10 }, royaltyEffect = { popularity = 25 }, setFlags = { health_transparent = true }, feed = "The public sent overwhelming support." },
			{ text = "Brief statement, no details", effects = { Happiness = 0 }, royaltyEffect = { popularity = 5 }, feed = "Privacy maintained." },
			{ text = "Deny any health issues", effects = { Happiness = -10 }, royaltyEffect = { popularity = -10 }, feed = "The cover-up raised more questions." },
			{ text = "Advocate for the condition publicly", effects = { Happiness = 15, Health = 5 }, royaltyEffect = { popularity = 35 }, setFlags = { health_advocate = true }, feed = "You became a champion for awareness!" },
		},
	},
	
	-- ROYAL ARTS PATRONAGE
	{
		id = "arts_patronage_choice",
		title = "🎨 Arts Patronage",
		emoji = "🎨",
		text = "You've been asked to become patron of a major arts institution. This will shape your cultural legacy.",
		minAge = 21,
		maxAge = 80,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { arts_patron = true, music_patron = true, theater_patron = true, literature_patron = true } },
		choices = {
			{ text = "Patron of the National Gallery", effects = { Happiness = 10, Smarts = 5 }, royaltyEffect = { popularity = 12 }, setFlags = { arts_patron = true }, feed = "Your love of visual arts is now official." },
			{ text = "Patron of the Royal Opera", effects = { Happiness = 8, Smarts = 3 }, royaltyEffect = { popularity = 10 }, setFlags = { music_patron = true }, feed = "High culture becomes your domain." },
			{ text = "Patron of the National Theatre", effects = { Happiness = 12 }, royaltyEffect = { popularity = 15 }, setFlags = { theater_patron = true }, feed = "The stage is now your world!" },
			{ text = "Champion emerging artists instead", effects = { Happiness = 15 }, royaltyEffect = { popularity = 20 }, setFlags = { modern_patron = true }, feed = "You're bringing fresh talent to the spotlight!" },
		},
	},
	
	-- ROYAL SECURITY THREAT
	{
		id = "security_threat",
		title = "🚨 Security Breach",
		emoji = "🚨",
		text = "Security has uncovered a credible threat against you. This requires immediate action.",
		minAge = 18,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 3,
		maxOccurrences = 2,
		choices = {
			{ text = "Increase security and continue duties", effects = { Happiness = -5, Health = -5 }, royaltyEffect = { popularity = 15 }, setFlags = { brave_royal = true }, feed = "Your courage under pressure impressed the nation." },
			{ text = "Temporary retreat to safe location", effects = { Happiness = -15 }, royaltyEffect = { popularity = -5 }, feed = "Safety first. The public understood." },
			{ text = "Address the threat publicly", effects = { Happiness = 5 }, royaltyEffect = { popularity = 20 }, setFlags = { defiant_royal = true }, feed = "You refused to be intimidated!" },
			{ text = "Make no changes - refuse to show fear", effects = { Happiness = 10, Health = -10 }, royaltyEffect = { popularity = 10 }, setFlags = { fearless_royal = true }, feed = "Brave? Or reckless? Time will tell." },
		},
	},
	
	-- ROYAL ENVIRONMENTAL CAUSE
	{
		id = "environmental_champion",
		title = "🌍 Environmental Cause",
		emoji = "🌍",
		text = "The climate crisis needs powerful voices. You could become a major advocate for the environment.",
		minAge = 16,
		maxAge = 70,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { climate_champion = true, stays_neutral = true } },
		choices = {
			{ text = "Become a global climate ambassador", effects = { Happiness = 15, Smarts = 8 }, royaltyEffect = { popularity = 25 }, setFlags = { climate_champion = true }, feed = "You're now a face of the climate movement!" },
			{ text = "Start with your own estates going green", effects = { Happiness = 10 }, royaltyEffect = { popularity = 15 }, setFlags = { eco_estates = true }, feed = "Leading by example with green palaces." },
			{ text = "Focus on ocean conservation", effects = { Happiness = 12, Smarts = 5 }, royaltyEffect = { popularity = 18 }, setFlags = { ocean_advocate = true }, feed = "The seas have a royal protector now!" },
			{ text = "Stay politically neutral on this", effects = { Happiness = -5 }, royaltyEffect = { popularity = -10 }, setFlags = { stays_neutral = true }, feed = "Critics called you out of touch." },
		},
	},
	
	-- ROYAL MEMOIR OFFER
	{
		id = "memoir_offer",
		title = "📚 Memoir Deal",
		emoji = "📚",
		text = "A major publisher offers millions for your memoir. But what secrets might you reveal?",
		minAge = 35,
		maxAge = 80,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { wrote_memoir = true } },
		choices = {
			{ text = "Tell everything - no holds barred", effects = { Happiness = 20 }, royaltyEffect = { popularity = -30, wealthGain = 20000000, scandals = 2 }, setFlags = { wrote_memoir = true, tell_all = true }, feed = "Your explosive memoir rocked the monarchy!" },
			{ text = "Write a carefully curated story", effects = { Happiness = 10 }, royaltyEffect = { popularity = 10, wealthGain = 8000000 }, setFlags = { wrote_memoir = true, careful_memoir = true }, feed = "A bestseller that revealed nothing too damaging." },
			{ text = "Donate proceeds to charity", effects = { Happiness = 15 }, royaltyEffect = { popularity = 25, wealthGain = 0 }, setFlags = { wrote_memoir = true, charitable_memoir = true }, feed = "Your selfless gesture won hearts." },
			{ text = "Decline - some things should stay private", effects = { Happiness = 5 }, royaltyEffect = { popularity = 5 }, setFlags = { no_memoir = true }, feed = "You value privacy over profit." },
		},
	},
	
	-- ROYAL CORONATION
	{
		id = "coronation_ceremony",
		title = "👑 Coronation Day",
		emoji = "👑",
		text = "The day has finally come. Your coronation will be watched by billions around the world.",
		minAge = 18,
		maxAge = 90,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { is_monarch = true },
			blockedFlags = { coronation_complete = true },
		},
		choices = {
			{ text = "Full traditional ceremony", effects = { Happiness = 25 }, royaltyEffect = { popularity = 20, wealthCost = 50000000 }, setFlags = { coronation_complete = true, traditional_coronation = true }, feed = "A coronation for the ages!" },
			{ text = "Modernized slimmed-down ceremony", effects = { Happiness = 20 }, royaltyEffect = { popularity = 25, wealthCost = 10000000 }, setFlags = { coronation_complete = true, modern_coronation = true }, feed = "A new kind of monarch for a new era." },
			{ text = "Include multicultural elements", effects = { Happiness = 22, Smarts = 5 }, royaltyEffect = { popularity = 30, wealthCost = 30000000 }, setFlags = { coronation_complete = true, inclusive_coronation = true }, feed = "Your inclusive ceremony united the nation!" },
			{ text = "Private ceremony - reject the spectacle", effects = { Happiness = 10 }, royaltyEffect = { popularity = -15, wealthCost = 1000000 }, setFlags = { coronation_complete = true, private_coronation = true }, feed = "A monarch without fanfare. Unusual but respected by some." },
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #464: ADDITIONAL ROYALTY EVENTS FOR DEEPER GAMEPLAY
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- ROYAL MILITARY SERVICE
	{
		id = "royal_military_service",
		title = "⚔️ Military Service",
		emoji = "⚔️",
		text = "The nation expects royals to serve in the military. It's time to decide your path.",
		minAge = 18,
		maxAge = 25,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { military_service = true, avoided_military = true } },
		choices = {
			{ text = "Join the Army", effects = { Happiness = 10, Health = 15 }, royaltyEffect = { popularity = 20 }, setFlags = { military_service = true, army_royal = true }, feed = "You trained with the Army. Respected." },
			{ text = "Join the Navy", effects = { Happiness = 12, Health = 12 }, royaltyEffect = { popularity = 18 }, setFlags = { military_service = true, navy_royal = true }, feed = "A seafaring royal. Traditional and noble." },
			{ text = "Join the Air Force", effects = { Happiness = 15, Smarts = 5 }, royaltyEffect = { popularity = 22 }, setFlags = { military_service = true, pilot_royal = true }, feed = "A royal pilot! The photos are incredible." },
			{ text = "Skip military service", effects = { Happiness = 5 }, royaltyEffect = { popularity = -15 }, setFlags = { avoided_military = true }, feed = "Critics questioned your patriotism." },
		},
	},
	
	-- ROYAL TOUR
	{
		id = "royal_world_tour",
		title = "🌍 World Tour",
		emoji = "🌍",
		text = "You're embarking on an official world tour to represent the monarchy abroad.",
		minAge = 21,
		maxAge = 70,
		isRoyalOnly = true,
		cooldown = 3,
		maxOccurrences = 4,
		choices = {
			{ text = "Focus on charity and humanitarian causes", effects = { Happiness = 15 }, royaltyEffect = { popularity = 25 }, setFlags = { humanitarian_tour = true }, feed = "Your compassion touched millions worldwide." },
			{ text = "Emphasize trade and diplomacy", effects = { Happiness = 8, Smarts = 8 }, royaltyEffect = { popularity = 15 }, setFlags = { diplomatic_tour = true }, feed = "You strengthened international ties." },
			{ text = "Connect with the diaspora", effects = { Happiness = 12 }, royaltyEffect = { popularity = 20 }, setFlags = { diaspora_champion = true }, feed = "Expats felt connected to home through you." },
			{ text = "Make it a low-key private tour", effects = { Happiness = 10 }, royaltyEffect = { popularity = 5 }, feed = "Less fanfare, more genuine connections." },
		},
	},
	
	-- ARRANGED MARRIAGE PROPOSAL
	{
		id = "arranged_marriage_proposal",
		title = "💍 Arranged Match",
		emoji = "💍",
		text = "A strategic match has been proposed. This person could strengthen the monarchy's alliances.",
		minAge = 21,
		maxAge = 40,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { married = true } },
		choices = {
			{ text = "Accept for duty to the crown", effects = { Happiness = -5 }, royaltyEffect = { popularity = 15 }, setFlags = { arranged_marriage = true }, feed = "A match made for politics, not passion." },
			{ text = "Decline and marry for love", effects = { Happiness = 20 }, royaltyEffect = { popularity = 10 }, setFlags = { married_for_love = true }, feed = "You chose your heart over politics." },
			{ text = "Request time to get to know them", effects = { Happiness = 5 }, royaltyEffect = { popularity = 8 }, setFlags = { considering_match = true }, feed = "A modern approach to an old tradition." },
			{ text = "Cause a scandal by dating someone else", effects = { Happiness = 15 }, royaltyEffect = { popularity = -20, scandals = 1 }, setFlags = { rebellious_royal = true }, feed = "The tabloids are having a field day!" },
		},
	},
	
	-- ROYAL ILLNESS PUBLIC ANNOUNCEMENT
	{
		id = "royal_illness_announcement",
		title = "🏥 Health Announcement",
		emoji = "🏥",
		text = "You're facing a health challenge. The palace must decide whether to inform the public.",
		minAge = 35,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 5,
		maxOccurrences = 1,
		choices = {
			{ text = "Full transparency about your condition", effects = { Happiness = 10, Health = 10 }, royaltyEffect = { popularity = 30 }, setFlags = { health_advocate = true }, feed = "Your courage inspired millions." },
			{ text = "Brief statement, minimal details", effects = { Happiness = 0 }, royaltyEffect = { popularity = 10 }, feed = "Privacy maintained, concern addressed." },
			{ text = "Complete media blackout", effects = { Happiness = -10 }, royaltyEffect = { popularity = -15 }, feed = "Rumors spread. The silence was worse." },
		},
	},
	
	-- ROYAL SCANDAL RESPONSE
	{
		id = "major_royal_scandal",
		title = "📰 Major Scandal",
		emoji = "📰",
		text = "A significant scandal involving you has erupted. How do you respond?",
		minAge = 18,
		maxAge = 80,
		isRoyalOnly = true,
		cooldown = 4,
		maxOccurrences = 2,
		choices = {
			{ text = "Address it head-on in a public interview", effects = { Happiness = 5 }, royaltyEffect = { popularity = 15 }, setFlags = { faced_scandal = true }, feed = "Your honesty helped contain the damage." },
			{ text = "Let lawyers handle everything", effects = { Happiness = -5 }, royaltyEffect = { popularity = -10, wealthCost = 5000000 }, feed = "Legal but cold. People wanted humanity." },
			{ text = "Retreat and wait for it to blow over", effects = { Happiness = -15 }, royaltyEffect = { popularity = -20 }, feed = "It didn't blow over. The story grew." },
			{ text = "Apologize and commit to change", effects = { Happiness = 10 }, royaltyEffect = { popularity = 25 }, setFlags = { apologized_royal = true }, feed = "Your humility won back public support." },
		},
	},
	
	-- ROYAL PET
	{
		id = "royal_pet_moment",
		title = "🐕 Royal Pet",
		emoji = "🐕",
		text = "Your beloved royal pet has become famous! The public loves seeing your furry companion.",
		minAge = 10,
		maxAge = 90,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 3,
		choices = {
		{ text = "Feature them in official photos", effects = { Happiness = 15 }, royaltyEffect = { popularity = 12 }, setFlags = { pet_parent = true }, feed = "The nation has a new favorite royal pet!" },
		{ text = "Start a pet charity in their name ($50K)", effects = { Happiness = 12, Money = -50000 }, royaltyEffect = { popularity = 20 }, setFlags = { animal_advocate = true }, feed = "Your charity helps animals nationwide.", eligibility = function(state) return (state.Money or 0) >= 50000, "💸 Need $50K for charity" end },
			{ text = "Keep your pet life private", effects = { Happiness = 8 }, royaltyEffect = { popularity = 3 }, feed = "Some things are just for you." },
		},
	},
	
	-- PALACE RENOVATION
	{
		id = "palace_renovation",
		title = "🏰 Palace Renovation",
		emoji = "🏰",
		text = "The palace needs major renovations. The cost will be debated publicly.",
		minAge = 25,
		maxAge = 85,
		isRoyalOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { requiresFlags = { is_monarch = true } },
		choices = {
			{ text = "Use public funds - it's national heritage", effects = { Happiness = 5 }, royaltyEffect = { popularity = -15, wealthCost = 0 }, setFlags = { used_public_funds = true }, feed = "Taxpayers weren't happy about the cost." },
			{ text = "Pay from personal fortune", effects = { Happiness = 10 }, royaltyEffect = { popularity = 25, wealthCost = 100000000 }, setFlags = { paid_personally = true }, feed = "Your generosity impressed the nation." },
			{ text = "Open the palace to tourists to fund it", effects = { Happiness = 8, Smarts = 5 }, royaltyEffect = { popularity = 20, wealthCost = 20000000 }, setFlags = { tourist_palace = true }, feed = "Crowds can now see the royal home!" },
			{ text = "Delay indefinitely", effects = { Happiness = -5 }, royaltyEffect = { popularity = 5 }, feed = "The palace crumbles a bit more." },
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #CRASH-1: Initialize ALL numeric fields with defaults!
	-- User complaint: "attempt to compare number < nil" crashes every year after becoming royalty
	-- Problem: When becoming royalty via marriage, many fields are never set, causing nil compares
	-- Solution: Ensure EVERY numeric field has a default value BEFORE any comparisons
	-- ═══════════════════════════════════════════════════════════════════════════════
	royalState.popularity = tonumber(royalState.popularity) or 50
	royalState.lineOfSuccession = tonumber(royalState.lineOfSuccession) or 99  -- Far from throne by default (consort)
	royalState.reignYears = tonumber(royalState.reignYears) or 0
	royalState.dutiesCompleted = tonumber(royalState.dutiesCompleted) or 0
	royalState.dutyStreak = tonumber(royalState.dutyStreak) or 0
	royalState.scandals = tonumber(royalState.scandals) or 0
	royalState.wealth = tonumber(royalState.wealth) or 0
	royalState.parentAgeGap = tonumber(royalState.parentAgeGap) or 28
	royalState.isMonarch = royalState.isMonarch or false
	royalState.isRoyal = true  -- Ensure this is set
	
	-- Boolean field defaults
	royalState.cameOfAge = royalState.cameOfAge or false
	royalState.fullyAdult = royalState.fullyAdult or false
	
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
	-- CRITICAL FIX #304: Only show this message occasionally (25% chance) to prevent spam
	-- Also only apply decay if popularity is above 30 (prevents kicking players when already low)
	-- CRITICAL FIX #324: Only show advisor message for age 12+ (babies don't get advisor suggestions!)
	if royalState.dutiesCompleted == 0 and royalState.popularity > 30 and age >= 12 then
		royalState.popularity = math.max(0, royalState.popularity - 2)
		-- Only show the message 25% of the time to prevent annoying spam
		if math.random(100) <= 25 then
			table.insert(events, {
				type = "popularity_decay",
				message = "💭 A royal advisor suggests making more public appearances to maintain popularity.",
			})
		end
	elseif age < 12 and royalState.popularity > 30 then
		-- CRITICAL FIX #324: For young royals, popularity naturally stays stable (they're cute!)
		-- No decay for children under 12 - they don't need to do public duties
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Coronation requires ACTUAL parent monarch death!
	-- User complaint: "IT SAYS BECOMING RULER BUT MY PARENT HASNT DIED"
	-- Changed: Only set throne_ready when parent monarch actually dies
	-- Monarch death now requires age-based probability with actual death event
	-- ═══════════════════════════════════════════════════════════════════════════════
	if not royalState.isMonarch and royalState.lineOfSuccession == 1 and age >= 21 then
		-- Get parent monarch's estimated age (player age + ~25-30 years)
		local parentMonarchAge = age + (royalState.parentAgeGap or 28)
		
		-- Check if monarch parent could pass away based on realistic age
		-- Parents typically shouldn't die before age 60, increases after
		local deathChance = 0
		if parentMonarchAge >= 90 then
			deathChance = 40 -- High chance at 90+
		elseif parentMonarchAge >= 80 then
			deathChance = 20 -- Moderate chance at 80+
		elseif parentMonarchAge >= 70 then
			deathChance = 8  -- Lower chance at 70+
		elseif parentMonarchAge >= 60 then
			deathChance = 3  -- Small chance at 60+
		end
		-- Note: No chance below 60 - parents should live reasonably long
		
		if deathChance > 0 and math.random(100) <= deathChance then
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.throne_ready = true
			lifeState.Flags.is_heir = true
			lifeState.Flags.parent_monarch_deceased = true -- Mark parent as deceased!
			royalState.parentMonarchDeceased = true -- Track in royal state
			table.insert(events, {
				type = "monarch_death",
				message = "👑 The monarch has passed away. You are now heir to the throne and coronation awaits!",
			})
		elseif parentMonarchAge >= 75 and not lifeState.Flags.monarch_health_warned and math.random(100) <= 15 then
			-- Warning about declining health (no coronation yet)
			lifeState.Flags = lifeState.Flags or {}
			lifeState.Flags.monarch_health_warned = true
			table.insert(events, {
				type = "succession_warning",
				message = "👑 The current monarch's health is declining. You may need to prepare for the throne.",
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
-- CRITICAL FIX #441-445: ROYAL WEALTH MANAGEMENT SYSTEM
-- Track royal finances, allowances, estates, and expenses
-- ════════════════════════════════════════════════════════════════════════════

RoyaltyEvents.WealthSources = {
	crown_estate = {
		name = "Crown Estate Income",
		description = "Revenue from royal lands and properties",
		baseIncome = 5000000,
		monarchMultiplier = 3.0,
		heirMultiplier = 1.0,
		otherMultiplier = 0.3,
	},
	government_stipend = {
		name = "Sovereign Grant",
		description = "Government funding for official duties",
		baseIncome = 2000000,
		monarchMultiplier = 5.0,
		heirMultiplier = 1.5,
		otherMultiplier = 0.5,
	},
	private_investments = {
		name = "Private Investments",
		description = "Personal investment portfolio returns",
		baseIncome = 1000000,
		percentageOfWealth = 0.04, -- 4% annual return
	},
	royal_properties = {
		name = "Royal Property Income",
		description = "Rental income from royal properties",
		baseIncome = 500000,
		monarchMultiplier = 2.0,
		heirMultiplier = 0.5,
		otherMultiplier = 0.2,
	},
}

RoyaltyEvents.WealthExpenses = {
	palace_maintenance = {
		name = "Palace Maintenance",
		baseExpense = 2000000,
		monarchMultiplier = 2.0,
		heirMultiplier = 0.5,
		otherMultiplier = 0.2,
	},
	staff_salaries = {
		name = "Royal Staff",
		baseExpense = 1500000,
		monarchMultiplier = 3.0,
		heirMultiplier = 1.0,
		otherMultiplier = 0.3,
	},
	security = {
		name = "Security Detail",
		baseExpense = 3000000,
		monarchMultiplier = 2.0,
		heirMultiplier = 1.0,
		otherMultiplier = 0.5,
	},
	official_functions = {
		name = "Official Functions",
		baseExpense = 1000000,
		monarchMultiplier = 3.0,
		heirMultiplier = 1.0,
		otherMultiplier = 0.3,
	},
	charitable_giving = {
		name = "Royal Charities",
		baseExpense = 500000,
		monarchMultiplier = 2.0,
		heirMultiplier = 1.0,
		otherMultiplier = 0.5,
	},
}

function RoyaltyEvents.calculateYearlyIncome(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.isRoyal then
		return 0
	end
	
	local isMonarch = royalState.isMonarch
	local isHeir = (royalState.lineOfSuccession or 99) == 1
	local totalIncome = 0
	
	for sourceId, source in pairs(RoyaltyEvents.WealthSources) do
		local multiplier = source.otherMultiplier or 1.0
		if isMonarch then
			multiplier = source.monarchMultiplier or 1.0
		elseif isHeir then
			multiplier = source.heirMultiplier or 1.0
		end
		
		local income = source.baseIncome * multiplier
		
		-- Add percentage-based income
		if source.percentageOfWealth then
			income = income + ((royalState.wealth or 0) * source.percentageOfWealth)
		end
		
		totalIncome = totalIncome + income
	end
	
	-- Popularity affects income
	local popularity = royalState.popularity or 50
	local popularityMultiplier = 0.5 + (popularity / 100) -- 0.5 to 1.5
	totalIncome = math.floor(totalIncome * popularityMultiplier)
	
	return totalIncome
end

function RoyaltyEvents.calculateYearlyExpenses(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.isRoyal then
		return 0
	end
	
	local isMonarch = royalState.isMonarch
	local isHeir = (royalState.lineOfSuccession or 99) == 1
	local totalExpenses = 0
	
	for expenseId, expense in pairs(RoyaltyEvents.WealthExpenses) do
		local multiplier = expense.otherMultiplier or 1.0
		if isMonarch then
			multiplier = expense.monarchMultiplier or 1.0
		elseif isHeir then
			multiplier = expense.heirMultiplier or 1.0
		end
		
		totalExpenses = totalExpenses + (expense.baseExpense * multiplier)
	end
	
	return math.floor(totalExpenses)
end

function RoyaltyEvents.processYearlyRoyalFinances(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.isRoyal then
		return nil
	end
	
	local income = RoyaltyEvents.calculateYearlyIncome(lifeState)
	local expenses = RoyaltyEvents.calculateYearlyExpenses(lifeState)
	local netIncome = income - expenses
	
	-- Update money
	lifeState.Money = (lifeState.Money or 0) + netIncome
	
	-- Update royal wealth tracking
	royalState.wealth = (royalState.wealth or lifeState.Money)
	royalState.yearlyIncome = income
	royalState.yearlyExpenses = expenses
	
	-- Track reign finances for monarchs
	if royalState.isMonarch then
		royalState.reignYears = (royalState.reignYears or 0) + 1
		royalState.totalReignIncome = (royalState.totalReignIncome or 0) + income
		royalState.totalReignExpenses = (royalState.totalReignExpenses or 0) + expenses
	end
	
	return {
		income = income,
		expenses = expenses,
		netIncome = netIncome,
		newBalance = lifeState.Money,
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #446-448: ROYAL ESTATE MANAGEMENT
-- Buy, sell, and manage royal properties
-- ════════════════════════════════════════════════════════════════════════════

RoyaltyEvents.RoyalEstates = {
	{ id = "countryside_estate", name = "Countryside Estate", price = 15000000, income = 200000, prestige = 10, emoji = "🏰" },
	{ id = "beach_villa", name = "Royal Beach Villa", price = 25000000, income = 300000, prestige = 15, emoji = "🏖️" },
	{ id = "hunting_lodge", name = "Royal Hunting Lodge", price = 8000000, income = 50000, prestige = 8, emoji = "🦌" },
	{ id = "ski_chalet", name = "Alpine Ski Chalet", price = 20000000, income = 250000, prestige = 12, emoji = "⛷️" },
	{ id = "yacht", name = "Royal Yacht", price = 100000000, income = 0, prestige = 25, emoji = "🛥️" },
	{ id = "private_island", name = "Private Island", price = 200000000, income = 500000, prestige = 40, emoji = "🏝️" },
	{ id = "vineyard", name = "Royal Vineyard", price = 30000000, income = 800000, prestige = 15, emoji = "🍷" },
	{ id = "castle", name = "Historic Castle", price = 50000000, income = 400000, prestige = 30, emoji = "🏯" },
}

function RoyaltyEvents.purchaseEstate(lifeState, estateId)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.isRoyal then
		return false, "Not royalty"
	end
	
	-- Find estate
	local estate = nil
	for _, e in ipairs(RoyaltyEvents.RoyalEstates) do
		if e.id == estateId then
			estate = e
			break
		end
	end
	
	if not estate then
		return false, "Unknown estate"
	end
	
	-- Check if already own
	royalState.estates = royalState.estates or {}
	for _, owned in ipairs(royalState.estates) do
		if owned.id == estateId then
			return false, "Already own this estate"
		end
	end
	
	-- Check funds
	if (lifeState.Money or 0) < estate.price then
		return false, "Insufficient funds"
	end
	
	-- Purchase
	lifeState.Money = lifeState.Money - estate.price
	
	table.insert(royalState.estates, {
		id = estate.id,
		name = estate.name,
		emoji = estate.emoji,
		purchasePrice = estate.price,
		purchaseYear = lifeState.Year,
		income = estate.income,
		prestige = estate.prestige,
	})
	
	-- Fame boost from prestige
	local fameBoost = math.floor(estate.prestige / 5)
	lifeState.Fame = math.min(100, (lifeState.Fame or 0) + fameBoost)
	
	return true, string.format("%s Acquired %s! (+%d prestige)", estate.emoji, estate.name, estate.prestige)
end

function RoyaltyEvents.getEstateIncome(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.estates then
		return 0
	end
	
	local total = 0
	for _, estate in ipairs(royalState.estates) do
		total = total + (estate.income or 0)
	end
	
	return total
end

function RoyaltyEvents.getTotalPrestige(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState then
		return 0
	end
	
	local prestige = 0
	
	-- Base prestige from title
	if royalState.isMonarch then
		prestige = prestige + 100
	elseif (royalState.lineOfSuccession or 99) == 1 then
		prestige = prestige + 50
	else
		prestige = prestige + 20
	end
	
	-- Estate prestige
	if royalState.estates then
		for _, estate in ipairs(royalState.estates) do
			prestige = prestige + (estate.prestige or 0)
		end
	end
	
	-- Duties completed prestige
	prestige = prestige + ((royalState.dutiesCompleted or 0) * 2)
	
	-- Scandal penalty
	prestige = prestige - ((royalState.scandals or 0) * 10)
	
	return math.max(0, prestige)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #449-451: ROYAL CHARITY AND PUBLIC IMAGE
-- Manage charitable works and public perception
-- ════════════════════════════════════════════════════════════════════════════

RoyaltyEvents.RoyalCharities = {
	{ id = "childrens_hospital", name = "Children's Hospital", focus = "health", minDonation = 100000, popularityGain = 5, emoji = "🏥" },
	{ id = "wildlife_conservation", name = "Wildlife Conservation", focus = "environment", minDonation = 50000, popularityGain = 4, emoji = "🦁" },
	{ id = "arts_foundation", name = "Arts Foundation", focus = "culture", minDonation = 75000, popularityGain = 3, emoji = "🎨" },
	{ id = "veterans_fund", name = "Veterans Support", focus = "military", minDonation = 100000, popularityGain = 6, emoji = "🎖️" },
	{ id = "disaster_relief", name = "Disaster Relief", focus = "humanitarian", minDonation = 200000, popularityGain = 8, emoji = "🆘" },
	{ id = "education_fund", name = "Education Fund", focus = "education", minDonation = 80000, popularityGain = 5, emoji = "📚" },
	{ id = "mental_health", name = "Mental Health Awareness", focus = "health", minDonation = 60000, popularityGain = 7, emoji = "🧠" },
	{ id = "climate_action", name = "Climate Action Fund", focus = "environment", minDonation = 150000, popularityGain = 6, emoji = "🌍" },
}

function RoyaltyEvents.donateToCharity(lifeState, charityId, amount)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.isRoyal then
		return false, "Not royalty"
	end
	
	-- Find charity
	local charity = nil
	for _, c in ipairs(RoyaltyEvents.RoyalCharities) do
		if c.id == charityId then
			charity = c
			break
		end
	end
	
	if not charity then
		return false, "Unknown charity"
	end
	
	-- Check minimum
	if amount < charity.minDonation then
		return false, string.format("Minimum donation is $%d", charity.minDonation)
	end
	
	-- Check funds
	if (lifeState.Money or 0) < amount then
		return false, "Insufficient funds"
	end
	
	-- Make donation
	lifeState.Money = lifeState.Money - amount
	
	-- Track donations
	royalState.charitiesPatronized = royalState.charitiesPatronized or {}
	local found = false
	for _, patronized in ipairs(royalState.charitiesPatronized) do
		if patronized.id == charityId then
			patronized.totalDonated = (patronized.totalDonated or 0) + amount
			patronized.donations = (patronized.donations or 0) + 1
			found = true
			break
		end
	end
	
	if not found then
		table.insert(royalState.charitiesPatronized, {
			id = charity.id,
			name = charity.name,
			emoji = charity.emoji,
			focus = charity.focus,
			totalDonated = amount,
			donations = 1,
			firstDonationYear = lifeState.Year,
		})
	end
	
	-- Popularity gain (scaled by donation size)
	local baseGain = charity.popularityGain
	local sizeMultiplier = math.min(3, amount / charity.minDonation)
	local popGain = math.floor(baseGain * sizeMultiplier)
	
	royalState.popularity = math.min(100, (royalState.popularity or 50) + popGain)
	
	-- Set flags
	lifeState.Flags = lifeState.Flags or {}
	lifeState.Flags.charitable_royal = true
	lifeState.Flags["supports_" .. charity.focus] = true
	
	return true, string.format("%s Donated $%s to %s! (+%d popularity)", 
		charity.emoji, 
		RoyaltyEvents.formatMoney(amount), 
		charity.name, 
		popGain)
end

function RoyaltyEvents.getTotalCharitableDonations(lifeState)
	local royalState = lifeState.RoyalState
	if not royalState or not royalState.charitiesPatronized then
		return 0
	end
	
	local total = 0
	for _, charity in ipairs(royalState.charitiesPatronized) do
		total = total + (charity.totalDonated or 0)
	end
	
	return total
end

function RoyaltyEvents.formatMoney(amount)
	if amount >= 1000000000 then
		return string.format("%.1fB", amount / 1000000000)
	elseif amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	else
		return tostring(amount)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #546-560: ROYAL EDUCATION SYSTEM
-- Royals do NOT attend normal public schools!
-- They have private tutors, elite boarding schools, and prestigious academies
-- ════════════════════════════════════════════════════════════════════════════

RoyaltyEvents.RoyalEducation = {
	-- Childhood Education (Ages 5-13)
	childhood = {
		{
			id = "royal_tutors_childhood",
			name = "Palace Tutors",
			emoji = "👨‍🏫",
			description = "Private tutors at the palace",
			smartsGain = { min = 3, max = 6 },
			cost = 50000,
			prestige = 60,
			socialSkills = 30,
		},
		{
			id = "elite_prep_school",
			name = "Elite Preparatory School",
			emoji = "🏫",
			description = "Exclusive private day school for nobility",
			smartsGain = { min = 4, max = 7 },
			cost = 75000,
			prestige = 70,
			socialSkills = 60,
			famousPrepSchools = { "Hill House", "Wetherby", "Thomas's Battersea" },
		},
		{
			id = "junior_boarding_school",
			name = "Junior Boarding School",
			emoji = "🏰",
			description = "Elite boarding school for young royals",
			smartsGain = { min = 5, max = 8 },
			cost = 100000,
			prestige = 80,
			socialSkills = 70,
			independence = 50,
			famousSchools = { "Ludgrove", "Papplewick", "Summer Fields" },
		},
	},
	
	-- Teen Education (Ages 13-18)
	secondary = {
		{
			id = "elite_boarding_school",
			name = "Elite Boarding School",
			emoji = "🎓",
			description = "World-renowned boarding school",
			smartsGain = { min = 6, max = 10 },
			cost = 150000,
			prestige = 90,
			socialSkills = 80,
			connections = 90,
			famousSchools = { "Eton College", "Harrow", "Westminster", "Gordonstoun", "Le Rosey", "Andover", "Exeter" },
		},
		{
			id = "royal_military_academy",
			name = "Royal Military Academy",
			emoji = "🎖️",
			description = "Military training for future monarchs",
			smartsGain = { min = 5, max = 8 },
			healthGain = { min = 5, max = 10 },
			cost = 100000,
			prestige = 85,
			discipline = 95,
			leadership = 80,
			famousAcademies = { "Sandhurst", "West Point", "Saint-Cyr" },
		},
		{
			id = "swiss_finishing_school",
			name = "Swiss Finishing School",
			emoji = "🇨🇭",
			description = "Elite Swiss school focused on etiquette and refinement",
			smartsGain = { min = 4, max = 7 },
			looksGain = { min = 3, max = 6 },
			cost = 200000,
			prestige = 95,
			etiquette = 100,
			languages = 80,
			famousSchools = { "Institut Le Rosey", "Institut auf dem Rosenberg", "Aiglon College" },
		},
		{
			id = "palace_private_tutoring",
			name = "Palace Private Tutoring",
			emoji = "👑",
			description = "World-class tutors at the palace",
			smartsGain = { min = 6, max = 9 },
			cost = 125000,
			prestige = 75,
			privacy = 100,
			flexibility = 95,
		},
	},
	
	-- University Education (Ages 18+)
	university = {
		{
			id = "oxbridge",
			name = "Oxford/Cambridge",
			emoji = "🎓",
			description = "Britain's most prestigious universities",
			smartsGain = { min = 10, max = 15 },
			cost = 50000,
			prestige = 100,
			connections = 95,
			careerBoost = 90,
			duration = 3,
			famousCampuses = { "Oxford", "Cambridge" },
		},
		{
			id = "ivy_league",
			name = "Ivy League University",
			emoji = "🏛️",
			description = "America's elite universities",
			smartsGain = { min = 10, max = 15 },
			cost = 75000,
			prestige = 95,
			connections = 90,
			careerBoost = 85,
			duration = 4,
			famousCampuses = { "Harvard", "Yale", "Princeton", "Columbia" },
		},
		{
			id = "european_elite",
			name = "Elite European University",
			emoji = "🇪🇺",
			description = "Prestigious continental universities",
			smartsGain = { min = 9, max = 13 },
			cost = 40000,
			prestige = 85,
			connections = 80,
			careerBoost = 75,
			duration = 3,
			famousCampuses = { "Sciences Po", "ETH Zurich", "Leiden" },
		},
		{
			id = "military_officer_training",
			name = "Military Officer Training",
			emoji = "⚔️",
			description = "Commissioned officer training",
			smartsGain = { min = 6, max = 10 },
			healthGain = { min = 8, max = 15 },
			cost = 0,
			prestige = 80,
			discipline = 100,
			leadership = 95,
			duration = 2,
		},
	},
}

-- CRITICAL FIX #561: Royal Education Events
RoyaltyEvents.RoyalEducationEvents = {
	-- CHILDHOOD ROYAL EDUCATION (replaces normal elementary/middle school)
	{
		id = "royal_childhood_education_start",
		title = "👑 Royal Education Begins",
		emoji = "👑",
		text = "As a young royal, you won't attend ordinary school like other children. Your education will be befitting of your status. The palace advisors present options for your early education.",
		minAge = 5,
		maxAge = 6,
		oneTime = true,
		isRoyalOnly = true,
		priority = "high",
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true, royalty_gamepass = true } },
		blockedByFlags = { royal_education_started = true },
		choices = {
			{
				text = "Palace tutors - Learn at home with the best educators",
				effects = { Smarts = 5, Happiness = 8 },
				royaltyEffect = { popularity = 3 },
				setFlags = { royal_education_started = true, palace_educated = true, has_royal_tutors = true },
				feed = "You begin your education with world-class private tutors at the palace.",
				onResolve = function(state)
					state.EducationData = state.EducationData or {}
					state.EducationData.Institution = "Royal Palace Tutors"
					state.EducationData.Level = "royal_private"
					state.EducationData.Status = "enrolled"
					state.EducationData.isRoyalEducation = true
					state.Flags = state.Flags or {}
					state.Flags.in_school = true
					state.Flags.private_education = true
					if state.AddFeed then
						state:AddFeed("👨‍🏫 Your private tutors arrive at the palace! Only the finest education for royalty.")
					end
				end,
			},
			{
				text = "Elite preparatory school - Mix with other noble children",
				effects = { Smarts = 4, Happiness = 6, Looks = 2 },
				royaltyEffect = { popularity = 5 },
				setFlags = { royal_education_started = true, prep_school_student = true },
				feed = "You'll attend an exclusive preparatory school for children of nobility.",
				onResolve = function(state)
					local schools = { "Hill House", "Wetherby School", "Thomas's Battersea" }
					local school = schools[math.random(1, #schools)]
					state.EducationData = state.EducationData or {}
					state.EducationData.Institution = school
					state.EducationData.Level = "royal_prep"
					state.EducationData.Status = "enrolled"
					state.EducationData.isRoyalEducation = true
					state.Flags = state.Flags or {}
					state.Flags.in_school = true
					state.Flags.private_education = true
					if state.AddFeed then
						state:AddFeed(string.format("🏫 You begin at %s, one of the most exclusive schools in the world!", school))
					end
				end,
			},
		},
	},
	
	-- BOARDING SCHOOL TRANSITION
	{
		id = "royal_boarding_school",
		title = "🏰 Elite Boarding School",
		emoji = "🏰",
		text = "At 13, it's tradition for young royals to attend an elite boarding school. This will prepare you for your future duties and build connections with other influential families.",
		minAge = 13,
		maxAge = 14,
		oneTime = true,
		isRoyalOnly = true,
		priority = "high",
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true, royalty_gamepass = true } },
		blockedByFlags = { in_boarding_school = true, declined_boarding_school = true },
		choices = {
			{
				text = "Eton College - Britain's most famous school",
				effects = { Smarts = 8, Happiness = 5 },
				royaltyEffect = { popularity = 8 },
				setFlags = { in_boarding_school = true, eton_student = true, elite_connections = true },
				feed = "You'll join the ranks of kings, prime ministers, and leaders at Eton!",
				onResolve = function(state)
					state.EducationData = state.EducationData or {}
					state.EducationData.Institution = "Eton College"
					state.EducationData.Level = "royal_boarding"
					state.EducationData.Status = "enrolled"
					state.EducationData.Duration = 5
					state.EducationData.isRoyalEducation = true
					state.EducationData.isBoarding = true
					state.Flags = state.Flags or {}
					state.Flags.in_high_school = true -- For compatibility
					state.Flags.private_education = true
					state.Flags.boarding_student = true
					state.Money = math.max(0, (state.Money or 0) - 150000)
					if state.AddFeed then
						state:AddFeed("🎓 You arrive at Eton College! Centuries of tradition await.")
					end
				end,
			},
			{
				text = "Le Rosey (Switzerland) - The 'School of Kings'",
				effects = { Smarts = 7, Happiness = 8, Looks = 3 },
				royaltyEffect = { popularity = 10 },
				setFlags = { in_boarding_school = true, le_rosey_student = true, international_connections = true },
				feed = "The most expensive and exclusive school in the world awaits!",
				onResolve = function(state)
					state.EducationData = state.EducationData or {}
					state.EducationData.Institution = "Institut Le Rosey"
					state.EducationData.Level = "royal_boarding"
					state.EducationData.Status = "enrolled"
					state.EducationData.Duration = 5
					state.EducationData.isRoyalEducation = true
					state.EducationData.isBoarding = true
					state.Flags = state.Flags or {}
					state.Flags.in_high_school = true
					state.Flags.private_education = true
					state.Flags.boarding_student = true
					state.Flags.speaks_french = true
					state.Money = math.max(0, (state.Money or 0) - 200000)
					if state.AddFeed then
						state:AddFeed("🇨🇭 You jet off to Switzerland to attend the legendary Le Rosey!")
					end
				end,
			},
			{
				text = "Gordonstoun - Where Prince Charles and Prince Philip went",
				effects = { Smarts = 6, Health = 5, Happiness = 3 },
				royaltyEffect = { popularity = 6 },
				setFlags = { in_boarding_school = true, gordonstoun_student = true, outdoor_trained = true },
				feed = "A rigorous outdoor education in the Scottish Highlands!",
				onResolve = function(state)
					state.EducationData = state.EducationData or {}
					state.EducationData.Institution = "Gordonstoun"
					state.EducationData.Level = "royal_boarding"
					state.EducationData.Status = "enrolled"
					state.EducationData.Duration = 5
					state.EducationData.isRoyalEducation = true
					state.EducationData.isBoarding = true
					state.Flags = state.Flags or {}
					state.Flags.in_high_school = true
					state.Flags.private_education = true
					state.Flags.boarding_student = true
					state.Flags.outdoor_survival = true
					state.Money = math.max(0, (state.Money or 0) - 120000)
					if state.AddFeed then
						state:AddFeed("🏴󠁧󠁢󠁳󠁣󠁴󠁿 You arrive at Gordonstoun! Cold showers and character building await!")
					end
				end,
			},
			{
				text = "Continue with palace tutors - Stay close to family",
				effects = { Smarts = 5, Happiness = 10 },
				royaltyEffect = { popularity = -2 },
				setFlags = { declined_boarding_school = true, palace_educated = true },
				feed = "You'll continue your private education at the palace.",
				onResolve = function(state)
					state.EducationData = state.EducationData or {}
					state.EducationData.Institution = "Royal Palace Academy"
					state.EducationData.Level = "royal_private_secondary"
					state.EducationData.Status = "enrolled"
					state.EducationData.isRoyalEducation = true
					state.Flags = state.Flags or {}
					state.Flags.in_high_school = true
					state.Flags.private_education = true
					if state.AddFeed then
						state:AddFeed("👨‍🏫 Your private tutors will continue your secondary education at the palace.")
					end
				end,
			},
		},
	},
	
	-- ROYAL UNIVERSITY
	{
		id = "royal_university_choice",
		title = "🎓 Royal University Decision",
		emoji = "🎓",
		text = "As you complete your elite secondary education, it's time to choose your university path. Where will the next chapter of your royal education take place?",
		minAge = 18,
		maxAge = 19,
		oneTime = true,
		isRoyalOnly = true,
		priority = "high",
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true, royalty_gamepass = true } },
		blockedByFlags = { royal_university_chosen = true },
		choices = {
			{
				text = "Oxford University - History and tradition",
				effects = { Smarts = 12, Happiness = 7 },
				royaltyEffect = { popularity = 8 },
				setFlags = { royal_university_chosen = true, oxford_student = true, in_university = true },
				feed = "Oxford University welcomes you!",
				onResolve = function(state)
					state.EducationData = state.EducationData or {}
					state.EducationData.Institution = "University of Oxford"
					state.EducationData.Level = "royal_university"
					state.EducationData.Status = "enrolled"
					state.EducationData.Duration = 3
					state.EducationData.isRoyalEducation = true
					state.Flags = state.Flags or {}
					state.Flags.college_bound = true
					state.Flags.in_college = true
					if state.AddFeed then
						state:AddFeed("🎓 You walk through the ancient halls of Oxford! Generations of royals have studied here.")
					end
				end,
			},
			{
				text = "University of St Andrews - Meet your future spouse?",
				effects = { Smarts = 10, Happiness = 10, Looks = 2 },
				royaltyEffect = { popularity = 10 },
				setFlags = { royal_university_chosen = true, st_andrews_student = true, in_university = true },
				feed = "St Andrews - where Prince William met Kate!",
				onResolve = function(state)
					state.EducationData = state.EducationData or {}
					state.EducationData.Institution = "University of St Andrews"
					state.EducationData.Level = "royal_university"
					state.EducationData.Status = "enrolled"
					state.EducationData.Duration = 4
					state.EducationData.isRoyalEducation = true
					state.Flags = state.Flags or {}
					state.Flags.college_bound = true
					state.Flags.in_college = true
					state.Flags.might_find_love = true
					if state.AddFeed then
						state:AddFeed("🏴󠁧󠁢󠁳󠁣󠁴󠁿 You arrive at St Andrews! This is where royal love stories begin...")
					end
				end,
			},
			{
				text = "Royal Military Academy Sandhurst - Serve your country",
				effects = { Smarts = 6, Health = 12, Happiness = 5 },
				royaltyEffect = { popularity = 12 },
				setFlags = { royal_university_chosen = true, sandhurst_cadet = true, military_training = true },
				feed = "You'll train as a military officer!",
				onResolve = function(state)
					state.EducationData = state.EducationData or {}
					state.EducationData.Institution = "Royal Military Academy Sandhurst"
					state.EducationData.Level = "royal_military"
					state.EducationData.Status = "enrolled"
					state.EducationData.Duration = 1
					state.EducationData.isRoyalEducation = true
					state.Flags = state.Flags or {}
					state.Flags.military_training = true
					state.Flags.officer_candidate = true
					if state.AddFeed then
						state:AddFeed("🎖️ You begin officer training at Sandhurst! Many royals have served before you.")
					end
				end,
			},
			{
				text = "Gap year - Royal duties and travel first",
				effects = { Happiness = 12, Looks = 3 },
				royaltyEffect = { popularity = 5, dutiesCompleted = 3 },
				setFlags = { royal_university_chosen = true, gap_year = true },
				feed = "A royal gap year awaits!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.traveled_world = true
					state.Flags.royal_gap_year = true
					if state.AddFeed then
						state:AddFeed("🌍 You'll spend a year on royal tours and charitable work before university!")
					end
				end,
			},
		},
	},
	
	-- BOARDING SCHOOL EXPERIENCES
	{
		id = "boarding_school_experience",
		title = "🏫 Boarding School Life",
		emoji = "🏫",
		text = "Life at boarding school is unique for a royal. Everyone knows who you are, but you're expected to fit in.",
		minAge = 14,
		maxAge = 17,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		conditions = { requiresFlags = { in_boarding_school = true } },
		choices = {
			{
				text = "Become a prefect - Show leadership",
				effects = { Smarts = 3, Happiness = 5 },
				royaltyEffect = { popularity = 5 },
				setFlags = { school_prefect = true, natural_leader = true },
				feed = "You're appointed as a school prefect!",
			},
			{
				text = "Join the sports team - Excel athletically",
				effects = { Health = 5, Happiness = 6, Looks = 2 },
				royaltyEffect = { popularity = 4 },
				setFlags = { school_athlete = true },
				feed = "You become a star athlete at school!",
			},
			{
				text = "Focus on academics - Top of the class",
				effects = { Smarts = 7, Happiness = 3 },
				setFlags = { top_student = true, academic_excellence = true },
				feed = "Your grades are exceptional!",
			},
			{
				text = "Sneak out for adventures - Break the rules",
				effects = { Happiness = 8, Smarts = -2 },
				royaltyEffect = { popularity = -3, scandals = 1 },
				setFlags = { rebellious_teen = true, broke_school_rules = true },
				feed = "You got caught sneaking out! The tabloids are having a field day.",
			},
		},
	},
	
	-- ROYAL GRADUATION
	{
		id = "royal_graduation",
		title = "🎓 Royal Graduation Day",
		emoji = "🎓",
		text = "Graduation day! The press and cameras are everywhere as you complete your education. This is a major royal milestone.",
		minAge = 18,
		maxAge = 22,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { in_boarding_school = true } },
		blockedByFlags = { royal_graduated = true },
		choices = {
			{
				text = "Graduate with honors - Make the family proud",
				effects = { Smarts = 5, Happiness = 12 },
				royaltyEffect = { popularity = 10 },
				setFlags = { royal_graduated = true, graduated_with_honors = true },
				feed = "You graduate with distinction! The nation celebrates!",
				onResolve = function(state)
					state.EducationData = state.EducationData or {}
					state.EducationData.Status = "graduated"
					state.Education = "royal_boarding_school"
					state.Flags = state.Flags or {}
					state.Flags.high_school_graduate = true
					state.Flags.private_education = true
					state.Flags.in_boarding_school = nil
					if state.AddFeed then
						state:AddFeed("🎓 You've graduated from one of the world's most elite institutions!")
					end
				end,
			},
			{
				text = "Graduate quietly - Avoid the spotlight",
				effects = { Smarts = 3, Happiness = 8 },
				royaltyEffect = { popularity = 3 },
				setFlags = { royal_graduated = true, quiet_graduation = true },
				feed = "A private graduation ceremony, away from the press.",
				onResolve = function(state)
					state.EducationData = state.EducationData or {}
					state.EducationData.Status = "graduated"
					state.Education = "royal_boarding_school"
					state.Flags = state.Flags or {}
					state.Flags.high_school_graduate = true
					state.Flags.in_boarding_school = nil
				end,
			},
		},
	},
}

-- Add royal education events to the main events list
for _, event in ipairs(RoyaltyEvents.RoyalEducationEvents) do
	table.insert(RoyaltyEvents.LifeEvents, event)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #562-575: MORE ROYAL LIFE EVENTS
-- Expanded royal experiences, duties, and drama
-- ════════════════════════════════════════════════════════════════════════════

RoyaltyEvents.ExpandedRoyalEvents = {
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: ROYAL CHILDHOOD EXPERIENCES
	-- User complaint: "THE ROYALTY BARELY CHANGES STUFF BRUH"
	-- Royals need events for EVERY age from birth onwards!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- AGE 7: Royal siblings and etiquette
	{
		id = "royal_siblings_lessons",
		title = "👨‍👩‍👧‍👦 Royal Siblings",
		emoji = "👨‍👩‍👧‍👦",
		text = "As a young royal, you're expected to take lessons with your siblings or cousins from other noble families.",
		minAge = 6,
		maxAge = 10,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Be the responsible older sibling",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { responsible_royal = true },
				feed = "You showed maturity beyond your years!",
			},
			{
				text = "Be competitive and try to outshine them",
				effects = { Happiness = 3, Smarts = 5 },
				setFlags = { competitive_royal = true },
				feed = "Your competitive spirit impressed the tutors!",
			},
			{
				text = "Play pranks and make mischief",
				effects = { Happiness = 8, Smarts = -2 },
				setFlags = { mischievous_royal = true },
				feed = "The palace staff has their hands full with you!",
			},
		},
	},
	
	{
		id = "royal_etiquette_lessons",
		title = "🎩 Royal Etiquette",
		emoji = "🎩",
		text = "A strict etiquette instructor arrives at the palace. Time to learn proper royal behavior!",
		minAge = 5,
		maxAge = 12,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Pay attention and learn proper manners",
				effects = { Happiness = 2, Smarts = 5 },
				setFlags = { proper_manners = true, etiquette_trained = true },
				feed = "You mastered the art of royal etiquette!",
			},
			{
				text = "Pretend to pay attention while daydreaming",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { daydreamer = true },
				feed = "The instructor didn't notice your wandering mind.",
			},
			{
				text = "Deliberately misbehave",
				effects = { Happiness = 6, Smarts = -3 },
				royaltyEffect = { popularity = -5 },
				setFlags = { rebellious_royal = true },
				feed = "The palace is abuzz with gossip about your behavior!",
			},
		},
	},
	
	-- AGE 8: Pony/Horse lessons
	{
		id = "royal_pony_lessons",
		title = "🐴 Royal Riding Lessons",
		emoji = "🐴",
		text = "Every royal must learn to ride! Your first pony, a beautiful creature, awaits in the royal stables.",
		minAge = 6,
		maxAge = 10,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Embrace it - You're a natural rider!",
				effects = { Happiness = 10, Health = 5 },
				setFlags = { equestrian = true, loves_horses = true },
				feed = "You and your pony form an instant bond!",
			},
			{
				text = "Try cautiously - A bit nervous but determined",
				effects = { Happiness = 5, Health = 3 },
				setFlags = { cautious_rider = true },
				feed = "With practice, you're becoming a competent rider!",
			},
			{
				text = "Refuse at first - Horses are scary!",
				effects = { Happiness = -2, Health = 2 },
				setFlags = { afraid_of_horses = true },
				feed = "It took some time, but eventually you gave it a try.",
			},
		},
	},
	
	-- AGE 9: Royal charity visit
	{
		id = "royal_charity_visit",
		title = "💝 First Charity Visit",
		emoji = "💝",
		text = "It's time for your first official charity visit! Your parents are taking you to a children's hospital.",
		minAge = 7,
		maxAge = 12,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Connect with the children genuinely",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = 20 },
				setFlags = { charitable_heart = true, loves_charity = true },
				feed = "The children adored you and so did the media! You're a natural philanthropist.",
			},
			{
				text = "Be polite but formal",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = 10 },
				setFlags = { formal_royal = true },
				feed = "You performed your duties with proper decorum.",
			},
			{
				text = "Feel overwhelmed by the experience",
				effects = { Happiness = -5 },
				royaltyEffect = { popularity = 5 },
				setFlags = { sensitive_soul = true },
				feed = "The experience left a deep impression on you.",
			},
		},
	},
	
	-- AGE 10: Royal friends
	{
		id = "royal_friends",
		title = "👑 Noble Companions",
		emoji = "👑",
		text = "As a young royal, your friendships are carefully curated. Children from noble families are invited to the palace.",
		minAge = 8,
		maxAge = 12,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Become best friends with a duke's child",
				effects = { Happiness = 10 },
				setFlags = { noble_friend = true, social_royal = true },
				feed = "You and your noble friend are inseparable!",
			},
			{
				text = "Prefer the company of palace staff's children",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 5 },
				setFlags = { down_to_earth = true },
				feed = "Your choice of friends shows your humble character.",
			},
			{
				text = "Prefer to be alone - Books are your friends",
				effects = { Happiness = 3, Smarts = 8 },
				setFlags = { solitary_royal = true, bookworm = true },
				feed = "You find more comfort in the palace library than in playmates.",
			},
		},
	},
	
	-- AGE 12: Coming of age prep
	{
		id = "royal_coming_of_age_prep",
		title = "🌟 Preparing for Adulthood",
		emoji = "🌟",
		text = "As you approach your teenage years, the palace begins preparing you for your future royal responsibilities.",
		minAge = 11,
		maxAge = 13,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Embrace your destiny as future royalty",
				effects = { Happiness = 8, Smarts = 5 },
				setFlags = { embraced_duty = true, mature_royal = true },
				feed = "You accept your royal destiny with grace and determination!",
			},
			{
				text = "Feel the weight of expectations",
				effects = { Happiness = -5, Smarts = 3 },
				setFlags = { burdened_royal = true },
				feed = "The crown feels heavy even before you wear it...",
			},
			{
				text = "Dream of a normal life",
				effects = { Happiness = 3 },
				setFlags = { dreams_of_normalcy = true },
				feed = "Sometimes you wonder what life would be like as a regular kid...",
			},
		},
	},
	
	-- AGE 13: First solo engagement
	{
		id = "royal_first_solo_engagement",
		title = "🎤 First Solo Appearance",
		emoji = "🎤",
		text = "For the first time, you'll attend an official event WITHOUT your parents! A school opening ceremony awaits.",
		minAge = 12,
		maxAge = 15,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Nail it - Give a small speech confidently",
				effects = { Happiness = 12, Smarts = 3 },
				royaltyEffect = { popularity = 15 },
				setFlags = { confident_speaker = true, solo_debut_success = true },
				feed = "Your first solo engagement was a massive success! The press loves you!",
			},
			{
				text = "Manage adequately - A bit nervous but okay",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = 8 },
				setFlags = { nervous_performer = true },
				feed = "You got through it! Experience will build confidence.",
			},
			{
				text = "Struggle - Stage fright hits hard",
				effects = { Happiness = -8 },
				royaltyEffect = { popularity = -5 },
				setFlags = { stage_fright = true },
				feed = "The experience was overwhelming... but you survived.",
			},
		},
	},
	
	-- AGE 14: Royal boarding school option
	{
		id = "royal_boarding_school",
		title = "🏫 Elite Education",
		emoji = "🏫",
		text = "Your parents discuss your education future. Will you attend an elite boarding school or continue private palace tutoring?",
		minAge = 13,
		maxAge = 16,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Elite boarding school - Meet other nobles",
				effects = { Happiness = 8, Smarts = 10 },
				setFlags = { boarding_school = true, elite_education = true },
				feed = "You're off to one of the world's most exclusive schools!",
			},
			{
				text = "Continue palace tutoring - Stay home",
				effects = { Happiness = 5, Smarts = 8 },
				setFlags = { palace_educated = true },
				feed = "Your tutors continue to provide world-class education at home.",
			},
			{
				text = "Military academy - Build discipline",
				effects = { Happiness = 2, Health = 10, Smarts = 5 },
				setFlags = { military_education = true, disciplined = true },
				feed = "The military academy will shape you into a leader!",
			},
		},
	},
	
	-- AGE 15: Driving training
	{
		id = "royal_drivers_training",
		title = "🚗 Royal Driving Lessons",
		emoji = "🚗",
		text = "Even royals must learn to drive! Though you'll usually have a chauffeur, driving is an important skill.",
		minAge = 15,
		maxAge = 17,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Learn in a luxury vehicle",
				effects = { Happiness = 10 },
				setFlags = { can_drive = true, learned_in_luxury = true },
				feed = "Learning to drive in a Bentley? Very royal of you!",
			},
			{
				text = "Learn defensive driving like security",
				effects = { Happiness = 5, Health = 5 },
				setFlags = { can_drive = true, defensive_driver = true },
				feed = "You learned advanced driving techniques!",
			},
			{
				text = "Let the chauffeur handle it",
				effects = { Happiness = 3 },
				setFlags = { prefers_chauffeur = true },
				feed = "Why drive when you have staff for that?",
			},
		},
	},
	
	-- AGE 16: Sweet sixteen royal style
	{
		id = "royal_sixteenth_birthday",
		title = "🎂 Royal Sweet Sixteen",
		emoji = "🎂",
		text = "Your sixteenth birthday is a major celebration! The palace is planning an extravagant event.",
		minAge = 16,
		maxAge = 16,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Grand ball with nobility from around the world",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = 20 },
				setFlags = { sweet_sixteen_ball = true },
				feed = "A magnificent celebration worthy of a future monarch!",
			},
			{
				text = "Intimate celebration with close friends",
				effects = { Happiness = 12 },
				royaltyEffect = { popularity = 10 },
				setFlags = { private_celebration = true },
				feed = "A wonderful birthday surrounded by those who truly know you.",
			},
			{
				text = "Charity gala in your honor",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 25 },
				setFlags = { charitable_birthday = true, loves_charity = true },
				feed = "Your birthday raised millions for charity! What a noble gesture!",
			},
		},
	},
	
	-- AGE 17: Gap year decision
	{
		id = "royal_gap_year_decision",
		title = "🌍 Gap Year Adventure?",
		emoji = "🌍",
		text = "Before university, many royals take a gap year. What will you do with this time?",
		minAge = 17,
		maxAge = 18,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "World tour with charitable work",
				effects = { Happiness = 15, Smarts = 5 },
				royaltyEffect = { popularity = 20 },
				setFlags = { gap_year_charity = true, world_traveler = true },
				feed = "Your gap year combined adventure with meaningful service!",
			},
			{
				text = "Military service to serve the nation",
				effects = { Happiness = 5, Health = 15 },
				setFlags = { gap_year_military = true, military_service = true },
				feed = "Following royal tradition, you serve in the armed forces!",
			},
			{
				text = "Skip it - Straight to university",
				effects = { Happiness = 3, Smarts = 8 },
				setFlags = { no_gap_year = true },
				feed = "You're eager to begin your higher education!",
			},
		},
	},
	
	{
		id = "royal_first_public_appearance",
		title = "👶 First Public Appearance",
		emoji = "👶",
		text = "The palace announces your first official public appearance! The world wants to see the young royal.",
		minAge = 1,
		maxAge = 3,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Wave to the crowd adorably",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = 15 },
				setFlags = { first_appearance = true, adorable_royal = true },
				feed = "The world falls in love with the adorable young royal!",
			},
			{
				text = "Cry and hide - Too overwhelming",
				effects = { Happiness = -3 },
				royaltyEffect = { popularity = 5 },
				setFlags = { first_appearance = true, shy_child = true },
				feed = "You cried, but the public found it endearing anyway!",
			},
		},
	},
	
	{
		id = "royal_christmas_broadcast",
		title = "🎄 Royal Christmas",
		emoji = "🎄",
		-- CRITICAL FIX: Added text variations and blocked by royal_christmas_speech to prevent double christmas
		textVariants = {
			"It's Christmas at the palace! The royal family gathers for celebrations and traditions.",
			"Christmas morning arrives with all the pomp and circumstance of royal tradition!",
			"The palace Christmas tree is magnificent! Family traditions and festive cheer fill every room.",
			"Another magical Christmas surrounded by family, tradition, and the warmth of the palace.",
			"Royal Christmas is here! The nation celebrates alongside your family.",
		},
		text = "It's Christmas at the palace! The royal family gathers for celebrations and traditions.",
		minAge = 3,
		maxAge = 100,
		isRoyalOnly = true,
		cooldown = 5, -- CRITICAL FIX: Increased from 3 to 5 to prevent spam
		blockedByFlags = { had_royal_christmas_this_year = true }, -- CRITICAL FIX: Prevent double christmas events
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Join in all the royal traditions",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 3 },
				setFlags = { loves_traditions = true },
				feed = "A magical royal Christmas with the whole family!",
			},
			{
				text = "Appear in the Christmas photo",
				effects = { Happiness = 6, Looks = 1 },
				royaltyEffect = { popularity = 5 },
				feed = "The official Christmas photo is shared worldwide!",
			},
			{
				text = "Skip some events - Need private time",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = -2 },
				setFlags = { values_privacy = true },
				feed = "You took some time for yourself amid the festivities.",
			},
		},
	},
	
	-- ROYAL TEEN EXPERIENCES
	{
		id = "royal_first_solo_engagement",
		title = "👑 First Solo Engagement",
		emoji = "👑",
		text = "At last! Your first official royal engagement without your parents. A hospital visit to meet young patients.",
		minAge = 16,
		maxAge = 18,
		oneTime = true,
		isRoyalOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Charm everyone with natural warmth",
				effects = { Happiness = 8, Smarts = 2 },
				royaltyEffect = { popularity = 12 },
				setFlags = { natural_charmer = true, good_with_public = true },
				feed = "Your natural warmth wins hearts! A future star of the royal family!",
			},
			{
				text = "Follow protocol perfectly",
				effects = { Happiness = 5, Smarts = 3 },
				royaltyEffect = { popularity = 8 },
				setFlags = { follows_protocol = true },
				feed = "You handled everything with perfect royal composure.",
			},
			{
				text = "Nervous but get through it",
				effects = { Happiness = 3 },
				royaltyEffect = { popularity = 5 },
				setFlags = { nervous_in_public = true },
				feed = "It was nerve-wracking, but you did it!",
			},
		},
	},
	
	{
		id = "royal_media_training",
		title = "📺 Royal Media Training",
		emoji = "📺",
		text = "The palace has arranged media training for you. You'll learn how to handle interviews, speeches, and the ever-present cameras.",
		minAge = 14,
		maxAge = 20,
		oneTime = true,
		isRoyalOnly = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Take it seriously - Master the skills",
				effects = { Smarts = 5, Happiness = 3 },
				royaltyEffect = { popularity = 5 },
				setFlags = { media_trained = true, polished_speaker = true },
				feed = "You've become an expert at handling the media!",
			},
			{
				text = "Learn the basics, nothing more",
				effects = { Smarts = 2 },
				setFlags = { basic_media_skills = true },
				feed = "You learned enough to get by.",
			},
			{
				text = "Reject all the PR coaching",
				effects = { Happiness = 5, Smarts = -1 },
				royaltyEffect = { popularity = -5 },
				setFlags = { unpolished = true, authentic = true },
				feed = "You want to be yourself, not a PR creation.",
			},
		},
	},
	
	-- ROYAL ADULT EXPERIENCES
	{
		id = "royal_charity_patron",
		title = "🎗️ Become Charity Patron",
		emoji = "🎗️",
		text = "You've been asked to become the official patron of a major charity. This will be your signature cause.",
		minAge = 21,
		maxAge = 50,
		isRoyalOnly = true,
		oneTime = true,
		conditions = { requiresFlags = { is_royalty = true, royal_adult = true } },
		choices = {
			{
				text = "Children's charity - Help the young",
				effects = { Happiness = 10 },
				royaltyEffect = { popularity = 15 },
				setFlags = { charity_patron = true, childrens_advocate = true },
				feed = "You become patron of a major children's charity!",
			},
			{
				text = "Mental health charity - Break stigma",
				effects = { Happiness = 8, Smarts = 2 },
				royaltyEffect = { popularity = 12 },
				setFlags = { charity_patron = true, mental_health_advocate = true },
				feed = "You champion mental health awareness!",
			},
			{
				text = "Environmental charity - Save the planet",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 10 },
				setFlags = { charity_patron = true, environmental_advocate = true },
				feed = "You dedicate yourself to environmental causes!",
			},
			{
				text = "Military charity - Support veterans",
				effects = { Happiness = 8 },
				royaltyEffect = { popularity = 12 },
				setFlags = { charity_patron = true, military_supporter = true },
				feed = "You honor those who served!",
			},
		},
	},
	
	{
		id = "royal_world_tour",
		title = "🌍 Royal World Tour",
		emoji = "🌍",
		text = "You're embarking on an official royal tour! Multiple countries, weeks of engagements, and global media attention.",
		minAge = 21,
		maxAge = 70,
		isRoyalOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		conditions = { requiresFlags = { is_royalty = true, royal_adult = true } },
		choices = {
			{
				text = "Commonwealth tour - Strengthen ties",
				effects = { Happiness = 8, Health = -5 },
				royaltyEffect = { popularity = 15 },
				setFlags = { completed_royal_tour = true, commonwealth_ambassador = true },
				feed = "A successful tour through Commonwealth nations!",
				onResolve = function(state)
					state.RoyalState = state.RoyalState or {}
					state.RoyalState.stateVisits = state.RoyalState.stateVisits or {}
					table.insert(state.RoyalState.stateVisits, {
						type = "commonwealth",
						year = state.Year,
						success = true,
					})
				end,
			},
			{
				text = "Diplomatic tour - Important meetings",
				effects = { Smarts = 5, Happiness = 5, Health = -3 },
				royaltyEffect = { popularity = 10 },
				setFlags = { completed_royal_tour = true, diplomatic_experience = true },
				feed = "You met world leaders and discussed important matters!",
			},
			{
				text = "Charity-focused tour - Help those in need",
				effects = { Happiness = 12, Health = -4 },
				royaltyEffect = { popularity = 18 },
				setFlags = { completed_royal_tour = true, humanitarian_royal = true },
				feed = "You brought attention to important causes around the world!",
			},
		},
	},
	
	-- ROYAL SENIOR EVENTS
	{
		id = "royal_memoir",
		title = "📚 Royal Memoir",
		emoji = "📚",
		text = "A publisher has offered a massive advance for your memoirs. But what will you reveal?",
		minAge = 50,
		maxAge = 90,
		isRoyalOnly = true,
		oneTime = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
			{
				text = "Write a dignified, careful memoir",
				effects = { Happiness = 8, Money = 5000000 },
				royaltyEffect = { popularity = 5 },
				setFlags = { wrote_memoir = true, dignified_author = true },
				feed = "Your tasteful memoir becomes a bestseller!",
			},
			{
				text = "Tell ALL the secrets - Explosive revelations!",
				effects = { Happiness = 10, Money = 20000000 },
				royaltyEffect = { popularity = -20, scandals = 3 },
				setFlags = { wrote_memoir = true, tell_all_author = true, family_outcast = true },
				feed = "Your explosive memoir rocks the royal family! Millions sold!",
			},
			{
				text = "Decline - Some things are private",
				effects = { Happiness = 5 },
				royaltyEffect = { popularity = 8 },
				setFlags = { refused_memoir = true, maintains_dignity = true },
				feed = "You choose to keep royal secrets private.",
			},
		},
	},
	
	{
		id = "royal_legacy_foundation",
		title = "🏛️ Royal Legacy",
		emoji = "🏛️",
		text = "As a senior royal, you want to establish your lasting legacy. What will you be remembered for?",
		minAge = 60,
		maxAge = 100,
		isRoyalOnly = true,
		oneTime = true,
		conditions = { requiresFlags = { is_royalty = true } },
		choices = {
		{
			text = "Establish a major foundation ($10M)",
			effects = { Happiness = 12, Money = -10000000 },
			royaltyEffect = { popularity = 20 },
			setFlags = { established_foundation = true, philanthropist = true },
			feed = "Your foundation will help millions for generations!",
			eligibility = function(state) return (state.Money or 0) >= 10000000, "💸 Need $10M for foundation" end,
		},
		{
			text = "Commission a lasting monument ($5M)",
			effects = { Happiness = 8, Money = -5000000 },
			royaltyEffect = { popularity = 10 },
			setFlags = { commissioned_monument = true },
			feed = "A beautiful monument will bear your name forever!",
			eligibility = function(state) return (state.Money or 0) >= 5000000, "💸 Need $5M for monument" end,
		},
			{
				text = "Focus on family - Your children are your legacy",
				effects = { Happiness = 15 },
				royaltyEffect = { popularity = 5 },
				setFlags = { family_focused_legacy = true },
				feed = "Your greatest legacy is the family you've raised.",
			},
		},
	},
}

-- Add expanded events to main list
for _, event in ipairs(RoyaltyEvents.ExpandedRoyalEvents) do
	table.insert(RoyaltyEvents.LifeEvents, event)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #576: Helper function to check if education is royal
-- Prevents royals from getting normal school events
-- ════════════════════════════════════════════════════════════════════════════
function RoyaltyEvents.isRoyalEducation(state)
	if not state then return false end
	
	-- Check if player is royalty
	if state.Flags and state.Flags.is_royalty then
		return true
	end
	
	if state.RoyalState and state.RoyalState.isRoyal then
		return true
	end
	
	-- Check education data
	if state.EducationData and state.EducationData.isRoyalEducation then
		return true
	end
	
	return false
end

-- CRITICAL FIX #577: Block normal school for royals
function RoyaltyEvents.shouldBlockNormalSchool(state)
	return RoyaltyEvents.isRoyalEducation(state)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #43: Export events in standard format for LifeEvents loader
-- The init.lua module loader expects .events, .Events, or .LifeEvents array
-- ════════════════════════════════════════════════════════════════════════════
RoyaltyEvents.events = RoyaltyEvents.LifeEvents

return RoyaltyEvents
