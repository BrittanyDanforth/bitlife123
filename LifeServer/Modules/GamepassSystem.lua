--[[
	GamepassSystem.lua
	
	Premium gamepass and purchaseable content system for BitLife-style game.
	Handles all premium features including:
	- Time Machine (go back years on death)
	- Mafia/Mob access
	- God Mode (edit stats)
	- Bitizenship (premium features)
	- Special Careers
	- Boss Mode (business features)
	- Royalty (born as prince/princess)
	- Celebrity (fame career paths)
	
	CRITICAL FIX #1: Real gamepass IDs implemented
	CRITICAL FIX #2: Full feature definitions for each gamepass
	CRITICAL FIX #3: Proper ownership caching and validation
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local GamepassSystem = {}
GamepassSystem.__index = GamepassSystem

-- ════════════════════════════════════════════════════════════════════════════
-- REAL GAMEPASS IDS - CRITICAL FIX #1
-- These are the actual production gamepass IDs
-- ════════════════════════════════════════════════════════════════════════════

local GAMEPASS_IDS = {
	ROYALTY = 1626378001,      -- Royalty gamepass
	GOD_MODE = 1628050729,     -- God Mode gamepass
	MAFIA = 1626238769,        -- Join the Mafia gamepass
	CELEBRITY = 1626461980,    -- Celebrity/Fame gamepass
	-- Additional gamepasses (set to 0 until real IDs are provided)
	BITIZENSHIP = 0,
	-- CRITICAL FIX: Time Machine gamepass with correct ID
	TIME_MACHINE = 1630681215,  -- Time Machine gamepass (unlimited rewinds)
	BOSS_MODE = 0,
	DARK_MODE = 0,
}

-- ════════════════════════════════════════════════════════════════════════════
-- GAMEPASS DEFINITIONS - Expanded with full features
-- ════════════════════════════════════════════════════════════════════════════

GamepassSystem.Gamepasses = {
	-- ═══════════════════════════════════════════════════════════════════════
	-- ROYALTY GAMEPASS - Born into royalty, inherit throne, royal lifestyle
	-- ═══════════════════════════════════════════════════════════════════════
	ROYALTY = {
		id = GAMEPASS_IDS.ROYALTY,
		name = "Royalty",
		emoji = "👸",
		description = "Be born into royalty! Live as a prince or princess, inherit kingdoms, and experience the royal lifestyle.",
		price = 299,
		category = "lifestyle",
		features = {
			"Born as Prince/Princess in random kingdom",
			"Choose your royal country at birth",
			"Inherit the throne and rule",
			"Royal duties and responsibilities",
			"Massive inherited wealth ($10M-$500M)",
			"Royal palace residence",
			"Royal scandals and drama",
			"Abdicate or exile options",
			"Royal marriages and alliances",
			"Execution/imprisonment powers",
			"Royal guards and servants",
			"State visits and diplomacy",
			"Royal charity work",
			"Knighting ceremonies",
			"Royal fashion and jewels",
		},
		-- CRITICAL: Link to character customization
		characterCreationOption = "royal_family",
		startingWealth = { min = 10000000, max = 500000000 },
		specialBirthOptions = {
			{ id = "prince", title = "Prince", emoji = "🤴", gender = "Male" },
			{ id = "princess", title = "Princess", emoji = "👸", gender = "Female" },
		},
		royalCountries = {
			{ id = "uk", name = "United Kingdom", emoji = "🇬🇧", title = { male = "Prince", female = "Princess" }, currency = "GBP" },
			{ id = "spain", name = "Spain", emoji = "🇪🇸", title = { male = "Príncipe", female = "Princesa" }, currency = "EUR" },
			{ id = "sweden", name = "Sweden", emoji = "🇸🇪", title = { male = "Prins", female = "Prinsessa" }, currency = "SEK" },
			{ id = "japan", name = "Japan", emoji = "🇯🇵", title = { male = "Prince", female = "Princess" }, currency = "JPY" },
			{ id = "monaco", name = "Monaco", emoji = "🇲🇨", title = { male = "Prince", female = "Princess" }, currency = "EUR" },
			{ id = "saudi", name = "Saudi Arabia", emoji = "🇸🇦", title = { male = "Prince", female = "Princess" }, currency = "SAR" },
			{ id = "thailand", name = "Thailand", emoji = "🇹🇭", title = { male = "Prince", female = "Princess" }, currency = "THB" },
			{ id = "morocco", name = "Morocco", emoji = "🇲🇦", title = { male = "Prince", female = "Princess" }, currency = "MAD" },
			{ id = "jordan", name = "Jordan", emoji = "🇯🇴", title = { male = "Prince", female = "Princess" }, currency = "JOD" },
			{ id = "belgium", name = "Belgium", emoji = "🇧🇪", title = { male = "Prince", female = "Princess" }, currency = "EUR" },
			{ id = "netherlands", name = "Netherlands", emoji = "🇳🇱", title = { male = "Prins", female = "Prinses" }, currency = "EUR" },
			{ id = "norway", name = "Norway", emoji = "🇳🇴", title = { male = "Prins", female = "Prinsesse" }, currency = "NOK" },
			{ id = "denmark", name = "Denmark", emoji = "🇩🇰", title = { male = "Prins", female = "Prinsesse" }, currency = "DKK" },
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- GOD MODE GAMEPASS - Edit all stats anytime
	-- ═══════════════════════════════════════════════════════════════════════
	GOD_MODE = {
		id = GAMEPASS_IDS.GOD_MODE,
		name = "God Mode",
		emoji = "⚡",
		description = "Edit your stats anytime! Become the perfect person with complete control over your life.",
		price = 499,
		category = "utility",
		features = {
			"Edit Happiness 0-100 anytime",
			"Edit Health 0-100 anytime",
			"Edit Smarts 0-100 anytime",
			"Edit Looks 0-100 anytime",
			"Change character appearance",
			"Modify relationship levels",
			"Instant skill boosts",
			"Edit Fame level",
			"Edit Wealth (within limits)",
			"Reset criminal record",
			"Change gender presentation",
			"Modify age (limited)",
			"Edit fertility",
			"Cure diseases instantly",
			"Maximum workout gains",
		},
		editableStats = {
			{ key = "Happiness", emoji = "😊", min = 0, max = 100, description = "Your overall mood and satisfaction" },
			{ key = "Health", emoji = "❤️", min = 0, max = 100, description = "Physical health and vitality" },
			{ key = "Smarts", emoji = "🧠", min = 0, max = 100, description = "Intelligence and wisdom" },
			{ key = "Looks", emoji = "✨", min = 0, max = 100, description = "Physical attractiveness" },
			{ key = "Fame", emoji = "⭐", min = 0, max = 100, description = "Public recognition and celebrity" },
		},
		editableBooleans = {
			{ key = "criminal_record", emoji = "📋", description = "Clear your criminal history" },
			{ key = "diseases", emoji = "💊", description = "Cure all diseases" },
			{ key = "addictions", emoji = "🚭", description = "Remove all addictions" },
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- MAFIA GAMEPASS - Join organized crime families
	-- ═══════════════════════════════════════════════════════════════════════
	MAFIA = {
		id = GAMEPASS_IDS.MAFIA,
		name = "Organized Crime",
		emoji = "🔫",
		description = "Join the criminal underworld. Rise through the ranks of the Mafia and build your criminal empire.",
		price = 499,
		category = "lifestyle",
		features = {
			"Join 5 crime families (Italian, Russian, Yakuza, Cartel, Triad)",
			"Rise from Associate to Boss",
			"Run criminal operations",
			"Territory wars and turf control",
			"Special mafia-only events",
			"Heist planning and execution",
			"Protection rackets",
			"Smuggling operations",
			"Prison connections",
			"Hitman contracts",
			"Money laundering",
			"Loan sharking",
			"Witness elimination",
			"Family loyalty system",
			"Rank-based operations unlock",
		},
		crimeFamily = {
			{ id = "italian", name = "Italian Mafia", emoji = "🇮🇹", color = Color3.fromRGB(239, 68, 68) },
			{ id = "russian", name = "Russian Bratva", emoji = "🇷🇺", color = Color3.fromRGB(59, 130, 246) },
			{ id = "yakuza", name = "Japanese Yakuza", emoji = "🇯🇵", color = Color3.fromRGB(139, 92, 246) },
			{ id = "cartel", name = "Mexican Cartel", emoji = "🇲🇽", color = Color3.fromRGB(34, 197, 94) },
			{ id = "triad", name = "Chinese Triad", emoji = "🇨🇳", color = Color3.fromRGB(249, 115, 22) },
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- CELEBRITY GAMEPASS - Fame and entertainment careers
	-- ═══════════════════════════════════════════════════════════════════════
	CELEBRITY = {
		id = GAMEPASS_IDS.CELEBRITY,
		name = "Fame Package",
		emoji = "⭐",
		description = "Become a celebrity! Access exclusive fame career paths and experience the glamorous lifestyle.",
		price = 249,
		category = "career",
		features = {
			"Actor career path (TV → Movies → A-List)",
			"Music career path (Indie → Label → Superstar)",
			"Social media influencer path",
			"Professional athlete career",
			"Model career path",
			"Fame events and paparazzi",
			"Red carpet events",
			"Award shows",
			"Celebrity scandals",
			"Endorsement deals",
			"Fan interactions",
			"Stalker events",
			"Celebrity relationships",
			"Rehab events",
			"Comeback arcs",
		},
		careerPaths = {
			-- ACTING CAREER
			actor = {
				name = "Acting",
				emoji = "🎬",
				stages = {
					{ id = "extra", name = "Extra", salary = { 500, 2000 }, fame = 0, yearsRequired = 0 },
					{ id = "background", name = "Background Actor", salary = { 2000, 8000 }, fame = 1, yearsRequired = 1 },
					{ id = "bit_part", name = "Bit Part Actor", salary = { 8000, 20000 }, fame = 5, yearsRequired = 2 },
					{ id = "supporting", name = "Supporting Actor", salary = { 50000, 150000 }, fame = 15, yearsRequired = 3 },
					{ id = "lead", name = "Lead Actor", salary = { 200000, 1000000 }, fame = 35, yearsRequired = 4 },
					{ id = "movie_star", name = "Movie Star", salary = { 1000000, 10000000 }, fame = 60, yearsRequired = 6 },
					{ id = "a_list", name = "A-List Celebrity", salary = { 10000000, 50000000 }, fame = 85, yearsRequired = 8 },
					{ id = "legend", name = "Hollywood Legend", salary = { 25000000, 100000000 }, fame = 100, yearsRequired = 15 },
				},
			},
			-- MUSIC CAREER
			musician = {
				name = "Music",
				emoji = "🎵",
				stages = {
					{ id = "street", name = "Street Performer", salary = { 100, 1000 }, fame = 0, yearsRequired = 0 },
					{ id = "local", name = "Local Artist", salary = { 1000, 5000 }, fame = 2, yearsRequired = 1 },
					{ id = "indie", name = "Indie Artist", salary = { 5000, 25000 }, fame = 8, yearsRequired = 2 },
					{ id = "signed", name = "Signed Artist", salary = { 50000, 200000 }, fame = 20, yearsRequired = 3 },
					{ id = "touring", name = "Touring Artist", salary = { 200000, 800000 }, fame = 40, yearsRequired = 4 },
					{ id = "platinum", name = "Platinum Artist", salary = { 1000000, 5000000 }, fame = 65, yearsRequired = 5 },
					{ id = "superstar", name = "Superstar", salary = { 5000000, 30000000 }, fame = 85, yearsRequired = 7 },
					{ id = "icon", name = "Music Icon", salary = { 20000000, 100000000 }, fame = 100, yearsRequired = 12 },
				},
			},
			-- SOCIAL MEDIA INFLUENCER
			influencer = {
				name = "Social Media",
				emoji = "📱",
				stages = {
					{ id = "newbie", name = "New Creator", salary = { 0, 100 }, fame = 0, yearsRequired = 0, followers = 100 },
					{ id = "micro", name = "Micro Influencer", salary = { 500, 5000 }, fame = 3, yearsRequired = 1, followers = 10000 },
					{ id = "growing", name = "Growing Influencer", salary = { 5000, 25000 }, fame = 10, yearsRequired = 2, followers = 100000 },
					{ id = "established", name = "Established Creator", salary = { 50000, 150000 }, fame = 25, yearsRequired = 3, followers = 500000 },
					{ id = "famous", name = "Famous Influencer", salary = { 200000, 500000 }, fame = 45, yearsRequired = 4, followers = 2000000 },
					{ id = "mega", name = "Mega Influencer", salary = { 500000, 2000000 }, fame = 65, yearsRequired = 5, followers = 10000000 },
					{ id = "celebrity", name = "Internet Celebrity", salary = { 2000000, 10000000 }, fame = 85, yearsRequired = 6, followers = 50000000 },
					{ id = "icon", name = "Social Media Icon", salary = { 10000000, 50000000 }, fame = 100, yearsRequired = 8, followers = 100000000 },
				},
			},
			-- PROFESSIONAL ATHLETE
			athlete = {
				name = "Professional Sports",
				emoji = "🏆",
				sports = { "Football", "Basketball", "Soccer", "Baseball", "Tennis", "Golf", "MMA", "Boxing" },
				stages = {
					{ id = "amateur", name = "Amateur", salary = { 0, 500 }, fame = 0, yearsRequired = 0 },
					{ id = "college", name = "College Athlete", salary = { 0, 5000 }, fame = 2, yearsRequired = 2 },
					{ id = "minor", name = "Minor League", salary = { 25000, 75000 }, fame = 5, yearsRequired = 3 },
					{ id = "pro", name = "Professional", salary = { 100000, 500000 }, fame = 15, yearsRequired = 4 },
					{ id = "starter", name = "Starter", salary = { 500000, 3000000 }, fame = 30, yearsRequired = 5 },
					{ id = "allstar", name = "All-Star", salary = { 3000000, 15000000 }, fame = 55, yearsRequired = 6 },
					{ id = "mvp", name = "MVP Candidate", salary = { 10000000, 40000000 }, fame = 75, yearsRequired = 8 },
					{ id = "legend", name = "Sports Legend", salary = { 30000000, 100000000 }, fame = 100, yearsRequired = 12 },
				},
			},
			-- MODEL CAREER
			model = {
				name = "Modeling",
				emoji = "📸",
				stages = {
					{ id = "amateur", name = "Amateur Model", salary = { 100, 500 }, fame = 0, yearsRequired = 0 },
					{ id = "catalog", name = "Catalog Model", salary = { 5000, 20000 }, fame = 3, yearsRequired = 1 },
					{ id = "commercial", name = "Commercial Model", salary = { 20000, 60000 }, fame = 10, yearsRequired = 2 },
					{ id = "fashion", name = "Fashion Model", salary = { 75000, 200000 }, fame = 25, yearsRequired = 3 },
					{ id = "runway", name = "Runway Model", salary = { 200000, 500000 }, fame = 40, yearsRequired = 4 },
					{ id = "top", name = "Top Model", salary = { 500000, 2000000 }, fame = 60, yearsRequired = 5 },
					{ id = "super", name = "Supermodel", salary = { 2000000, 10000000 }, fame = 85, yearsRequired = 7 },
					{ id = "icon", name = "Fashion Icon", salary = { 10000000, 50000000 }, fame = 100, yearsRequired = 10 },
				},
			},
		},
		fameEvents = {
			"Paparazzi follows you everywhere",
			"Fan asks for autograph",
			"Tabloid writes story about you",
			"Invited to red carpet event",
			"Brand wants endorsement deal",
			"Scandal in the press",
			"Award nomination",
			"Celebrity feud begins",
			"Stalker incident",
			"Charity gala invitation",
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- BITIZENSHIP - Core premium membership
	-- ═══════════════════════════════════════════════════════════════════════
	BITIZENSHIP = {
		id = GAMEPASS_IDS.BITIZENSHIP,
		name = "Bitizenship",
		emoji = "👑",
		description = "Unlock premium features! Ad-free, special careers, and more.",
		price = 299,
		category = "membership",
		features = {
			"Ad-free experience",
			"Access to Royalty careers",
			"Special character customization",
			"Exclusive random events",
			"Start with bonus money ($50,000)",
			"Premium relationship options",
			"Special life paths",
			"Early access to new features",
			"Premium support",
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- TIME MACHINE - Go back in time on death
	-- ═══════════════════════════════════════════════════════════════════════
	TIME_MACHINE = {
		id = GAMEPASS_IDS.TIME_MACHINE,
		name = "Time Machine",
		emoji = "⏰",
		description = "Go back in time when you die! Fix your mistakes.",
		price = 399,
		category = "utility",
		features = {
			"Go back 5 years",
			"Go back 10 years",
			"Go back 20 years",
			"Go back 30 years",
			"Restart as baby (same character)",
			"Keep memories from future",
			"Change key decisions",
			"Avoid death permanently",
		},
		timeOptions = {
			{ years = 5, label = "5 Years", emoji = "⏰" },
			{ years = 10, label = "10 Years", emoji = "⏰" },
			{ years = 20, label = "20 Years", emoji = "⏰" },
			{ years = 30, label = "30 Years", emoji = "⏰" },
			{ years = -1, label = "Baby (Restart)", emoji = "👶" },
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- BOSS MODE - Business empire features
	-- ═══════════════════════════════════════════════════════════════════════
	BOSS_MODE = {
		id = GAMEPASS_IDS.BOSS_MODE,
		name = "Boss Mode",
		emoji = "💼",
		description = "Start your own business empire! Become a tycoon.",
		price = 399,
		category = "career",
		features = {
			"Start any type of business",
			"Hire and fire employees",
			"Expand to multiple locations",
			"Go public with IPO",
			"Franchise your business",
			"Corporate espionage",
			"Hostile takeovers",
			"Business empire building",
		},
		businessTypes = {
			{ id = "restaurant", name = "Restaurant", emoji = "🍽️", startCost = 50000 },
			{ id = "retail", name = "Retail Store", emoji = "🏪", startCost = 75000 },
			{ id = "tech", name = "Tech Startup", emoji = "💻", startCost = 100000 },
			{ id = "real_estate", name = "Real Estate", emoji = "🏠", startCost = 200000 },
			{ id = "nightclub", name = "Nightclub", emoji = "🎵", startCost = 150000 },
			{ id = "gym", name = "Fitness Center", emoji = "💪", startCost = 80000 },
			{ id = "salon", name = "Beauty Salon", emoji = "💇", startCost = 40000 },
			{ id = "auto", name = "Auto Dealership", emoji = "🚗", startCost = 500000 },
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- DARK MODE - UI theme
	-- ═══════════════════════════════════════════════════════════════════════
	DARK_MODE = {
		id = GAMEPASS_IDS.DARK_MODE,
		name = "Dark Mode",
		emoji = "🌙",
		description = "Easy on the eyes! Switch to dark theme.",
		price = 49,
		category = "cosmetic",
		features = {
			"Dark theme UI",
			"Multiple theme options",
			"Custom accent colors",
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- PRODUCT DEFINITIONS (One-time purchases, consumables)
-- ════════════════════════════════════════════════════════════════════════════

GamepassSystem.Products = {
	-- ════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #100: Real Developer Product IDs for Time Machine
	-- These are the actual production product IDs for life rewind features
	-- ════════════════════════════════════════════════════════════════════════════
	TIME_5_YEARS = {
		id = 3477466389,  -- REAL PRODUCT ID: Go back in time 5 years!
		name = "Go Back 5 Years",
		emoji = "⏰",
		description = "Go back 5 years in your life",
		price = 25,
		type = "consumable",
		years = 5,
	},
	TIME_10_YEARS = {
		id = 3477466522,  -- REAL PRODUCT ID: Go back in time 10 years!
		name = "Go Back 10 Years",
		emoji = "⏰",
		description = "Go back 10 years in your life",
		price = 45,
		type = "consumable",
		years = 10,
	},
	TIME_20_YEARS = {
		id = 3477466619,  -- REAL PRODUCT ID: Go back in time 20 years!
		name = "Go Back 20 Years",
		emoji = "⏰",
		description = "Go back 20 years in your life",
		price = 75,
		type = "consumable",
		years = 20,
	},
	TIME_30_YEARS = {
		id = 0,  -- Not provided - set to 0 until real ID is available
		name = "Go Back 30 Years",
		emoji = "⏰",
		description = "Go back 30 years in your life",
		price = 99,
		type = "consumable",
		years = 30,
	},
	TIME_BABY = {
		id = 3477466778,  -- REAL PRODUCT ID: Go back to being a baby!
		name = "Restart as Baby",
		emoji = "👶",
		description = "Restart your life from age 0 (same character)",
		price = 125,
		type = "consumable",
		years = -1,  -- Special: restart from birth
	},
	
	-- Money boosts
	MONEY_SMALL = {
		id = 0,
		name = "Small Inheritance",
		emoji = "💵",
		description = "Receive $10,000",
		price = 25,
		type = "consumable",
		reward = 10000,
	},
	MONEY_MEDIUM = {
		id = 0,
		name = "Medium Inheritance",
		emoji = "💰",
		description = "Receive $100,000",
		price = 75,
		type = "consumable",
		reward = 100000,
	},
	MONEY_LARGE = {
		id = 0,
		name = "Large Inheritance",
		emoji = "🤑",
		description = "Receive $1,000,000",
		price = 150,
		type = "consumable",
		reward = 1000000,
	},
	
	-- Stat boosts
	STAT_BOOST = {
		id = 0,
		name = "Stat Boost",
		emoji = "📈",
		description = "+20 to all stats",
		price = 50,
		type = "consumable",
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem.new()
	local self = setmetatable({}, GamepassSystem)
	self.playerOwnership = {} -- Cache of player ownership
	self.ownershipCallbacks = {} -- Callbacks for ownership changes
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- DEVELOPMENT/TESTING MODE
-- Set this to true in Studio to test premium features without real gamepasses
-- CRITICAL: Set to false before publishing to production!
-- ════════════════════════════════════════════════════════════════════════════
GamepassSystem.DEV_MODE = false

-- ════════════════════════════════════════════════════════════════════════════
-- OWNERSHIP CHECKING - CRITICAL FIX #3: Improved caching
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:checkOwnership(player, gamepassKey)
	local gamepass = self.Gamepasses[gamepassKey]
	if not gamepass then
		warn("[GamepassSystem] Unknown gamepass:", gamepassKey)
		return false
	end
	
	-- If ID is 0, use dev mode setting
	if gamepass.id == 0 then
		if self.DEV_MODE then
			return true
		end
		return false
	end
	
	-- Check cached ownership first
	local playerId = player.UserId
	local cacheKey = playerId .. "_" .. gamepassKey
	if self.playerOwnership[cacheKey] ~= nil then
		return self.playerOwnership[cacheKey]
	end
	
	-- Check actual ownership with pcall protection
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(playerId, gamepass.id)
	end)
	
	if success then
		self.playerOwnership[cacheKey] = owns
		return owns
	else
		warn("[GamepassSystem] Failed to check ownership:", owns)
	end
	
	return false
end

function GamepassSystem:ownsAny(player, gamepassKeys)
	for _, key in ipairs(gamepassKeys) do
		if self:checkOwnership(player, key) then
			return true
		end
	end
	return false
end

function GamepassSystem:ownsAll(player, gamepassKeys)
	for _, key in ipairs(gamepassKeys) do
		if not self:checkOwnership(player, key) then
			return false
		end
	end
	return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- PREMIUM FEATURE CHECKS - Convenience methods
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:hasBitizenship(player)
	return self:checkOwnership(player, "BITIZENSHIP")
end

function GamepassSystem:hasGodMode(player)
	return self:checkOwnership(player, "GOD_MODE")
end

function GamepassSystem:hasTimeMachine(player)
	return self:checkOwnership(player, "TIME_MACHINE")
end

function GamepassSystem:hasBossMode(player)
	return self:checkOwnership(player, "BOSS_MODE")
end

function GamepassSystem:hasMafia(player)
	return self:checkOwnership(player, "MAFIA")
end

function GamepassSystem:hasRoyalty(player)
	return self:checkOwnership(player, "ROYALTY")
end

function GamepassSystem:hasCelebrity(player)
	return self:checkOwnership(player, "CELEBRITY")
end

function GamepassSystem:hasDarkMode(player)
	return self:checkOwnership(player, "DARK_MODE")
end

-- ════════════════════════════════════════════════════════════════════════════
-- PURCHASE PROMPTING
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:promptGamepass(player, gamepassKey)
	local gamepass = self.Gamepasses[gamepassKey]
	if not gamepass or gamepass.id == 0 then
		warn("[GamepassSystem] Cannot prompt purchase - invalid ID for:", gamepassKey)
		return false
	end
	
	local success, err = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, gamepass.id)
	end)
	
	if not success then
		warn("[GamepassSystem] Failed to prompt purchase:", err)
	end
	
	return success
end

function GamepassSystem:promptProduct(player, productKey)
	local product = self.Products[productKey]
	if not product or product.id == 0 then
		warn("[GamepassSystem] Cannot prompt purchase - invalid ID for:", productKey)
		return false
	end
	
	local success, err = pcall(function()
		MarketplaceService:PromptProductPurchase(player, product.id)
	end)
	
	if not success then
		warn("[GamepassSystem] Failed to prompt purchase:", err)
	end
	
	return success
end

-- ════════════════════════════════════════════════════════════════════════════
-- TIME MACHINE LOGIC
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:canUseTimeMachine(player, yearsBack)
	if self:hasTimeMachine(player) then
		return true, "gamepass"
	end
	return false, "purchase_required"
end

function GamepassSystem:getTimeMachineOptions()
	return {
		{ years = 5, label = "5 Years", emoji = "⏰", productKey = "TIME_5_YEARS" },
		{ years = 10, label = "10 Years", emoji = "⏰", productKey = "TIME_10_YEARS" },
		{ years = 20, label = "20 Years", emoji = "⏰", productKey = "TIME_20_YEARS" },
		{ years = 30, label = "30 Years", emoji = "⏰", productKey = "TIME_30_YEARS" },
		{ years = -1, label = "Baby", emoji = "👶", productKey = "TIME_BABY" },
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- GOD MODE LOGIC - CRITICAL FIX #4: Full implementation
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:canEditStats(player)
	return self:hasGodMode(player)
end

function GamepassSystem:getEditableStats()
	local godMode = self.Gamepasses.GOD_MODE
	return godMode.editableStats or {
		{ key = "Happiness", emoji = "😊", min = 0, max = 100 },
		{ key = "Health", emoji = "❤️", min = 0, max = 100 },
		{ key = "Smarts", emoji = "🧠", min = 0, max = 100 },
		{ key = "Looks", emoji = "✨", min = 0, max = 100 },
	}
end

function GamepassSystem:applyGodModeEdit(player, lifeState, statKey, newValue)
	if not self:hasGodMode(player) then
		return false, "God Mode gamepass required"
	end
	
	-- Validate stat key
	local validStats = { "Happiness", "Health", "Smarts", "Looks", "Fame" }
	local isValid = false
	for _, stat in ipairs(validStats) do
		if stat == statKey then
			isValid = true
			break
		end
	end
	
	if not isValid then
		return false, "Invalid stat key"
	end
	
	-- Clamp value
	newValue = math.clamp(newValue, 0, 100)
	
	-- Apply to state
	if lifeState.Stats and lifeState.Stats[statKey] ~= nil then
		lifeState.Stats[statKey] = newValue
	end
	if lifeState[statKey] ~= nil then
		lifeState[statKey] = newValue
	end
	
	return true, string.format("%s set to %d", statKey, newValue)
end

-- ════════════════════════════════════════════════════════════════════════════
-- MAFIA/MOB ACCESS - CRITICAL FIX #5: Proper integration
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:canJoinMafia(player)
	return self:hasMafia(player)
end

function GamepassSystem:getMafiaFamilies()
	local mafia = self.Gamepasses.MAFIA
	return mafia.crimeFamily or {
		{ id = "italian", name = "Italian Mafia", emoji = "🇮🇹", color = Color3.fromRGB(239, 68, 68) },
		{ id = "russian", name = "Russian Bratva", emoji = "🇷🇺", color = Color3.fromRGB(59, 130, 246) },
		{ id = "yakuza", name = "Japanese Yakuza", emoji = "🇯🇵", color = Color3.fromRGB(139, 92, 246) },
		{ id = "cartel", name = "Mexican Cartel", emoji = "🇲🇽", color = Color3.fromRGB(34, 197, 94) },
		{ id = "triad", name = "Chinese Triad", emoji = "🇨🇳", color = Color3.fromRGB(249, 115, 22) },
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- ROYALTY ACCESS - CRITICAL FIX #6: Born as royalty
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:canBeRoyalty(player)
	return self:hasRoyalty(player)
end

function GamepassSystem:getRoyalCountries()
	local royalty = self.Gamepasses.ROYALTY
	return royalty.royalCountries or {}
end

function GamepassSystem:getRoyalStartingWealth()
	local royalty = self.Gamepasses.ROYALTY
	local wealth = royalty.startingWealth or { min = 10000000, max = 500000000 }
	return math.random(wealth.min, wealth.max)
end

function GamepassSystem:initializeRoyalBirth(lifeState, player, countryId, title)
	if not self:hasRoyalty(player) then
		return false, "Royalty gamepass required"
	end
	
	local countries = self:getRoyalCountries()
	local country = nil
	for _, c in ipairs(countries) do
		if c.id == countryId then
			country = c
			break
		end
	end
	
	if not country then
		-- Random country
		country = countries[math.random(1, #countries)]
	end
	
	-- Determine title based on gender
	local gender = lifeState.Gender or "Male"
	local royalTitle = country.title[gender:lower()] or (gender == "Male" and "Prince" or "Princess")
	
	-- Initialize royal state
	lifeState.RoyalState = {
		isRoyal = true,
		country = country.id,
		countryName = country.name,
		countryEmoji = country.emoji,
		title = royalTitle,
		lineOfSuccession = math.random(1, 5), -- Position in line
		isMonarch = false,
		reignYears = 0,
		popularity = 75 + math.random(-10, 10),
		scandals = 0,
		dutiesCompleted = 0,
		wealth = self:getRoyalStartingWealth(),
	}
	
	-- Set starting money to royal wealth
	lifeState.Money = lifeState.RoyalState.wealth
	
	-- Set flags
	lifeState.Flags = lifeState.Flags or {}
	lifeState.Flags.is_royalty = true
	lifeState.Flags.royal_birth = true
	lifeState.Flags.royal_country = country.id
	lifeState.Flags.wealthy_family = true
	lifeState.Flags.upper_class = true
	
	return true, string.format("Born as %s %s of %s!", royalTitle, lifeState.Name or "Unknown", country.name)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CELEBRITY ACCESS - CRITICAL FIX #7: Fame career paths
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:canBeCelebrity(player)
	return self:hasCelebrity(player)
end

function GamepassSystem:getCelebrityCareerPaths()
	local celebrity = self.Gamepasses.CELEBRITY
	return celebrity.careerPaths or {}
end

function GamepassSystem:getFameEvents()
	local celebrity = self.Gamepasses.CELEBRITY
	return celebrity.fameEvents or {}
end

function GamepassSystem:initializeFameCareer(lifeState, player, careerPath)
	if not self:hasCelebrity(player) then
		return false, "Celebrity gamepass required"
	end
	
	local paths = self:getCelebrityCareerPaths()
	local path = paths[careerPath]
	
	if not path then
		return false, "Invalid career path"
	end
	
	-- Initialize fame state
	lifeState.FameState = {
		isFamous = false,
		careerPath = careerPath,
		careerName = path.name,
		currentStage = 1,
		stageName = path.stages[1].name,
		fame = 0,
		followers = 0,
		endorsements = {},
		awards = {},
		scandals = 0,
		yearsInCareer = 0,
	}
	
	-- Set starting job
	local firstStage = path.stages[1]
	lifeState.CurrentJob = {
		id = careerPath .. "_" .. firstStage.id,
		name = firstStage.name,
		company = path.name .. " Industry",
		salary = math.random(firstStage.salary[1], firstStage.salary[2]),
		category = "entertainment",
		isFameCareer = true,
	}
	
	-- Set flags
	lifeState.Flags = lifeState.Flags or {}
	lifeState.Flags.fame_career = true
	lifeState.Flags.entertainment_industry = true
	lifeState.Flags["career_" .. careerPath] = true
	
	return true, string.format("Started career as %s!", firstStage.name)
end

-- ════════════════════════════════════════════════════════════════════════════
-- SERIALIZATION (for client display)
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:getGamepassInfo(gamepassKey)
	local gamepass = self.Gamepasses[gamepassKey]
	if not gamepass then return nil end
	
	return {
		key = gamepassKey,
		id = gamepass.id,
		name = gamepass.name,
		emoji = gamepass.emoji,
		description = gamepass.description,
		price = gamepass.price,
		category = gamepass.category,
		features = gamepass.features,
	}
end

function GamepassSystem:getAllGamepasses()
	local list = {}
	for key, data in pairs(self.Gamepasses) do
		table.insert(list, {
			key = key,
			id = data.id,
			name = data.name,
			emoji = data.emoji,
			description = data.description,
			price = data.price,
			category = data.category or "general",
			features = data.features,
		})
	end
	return list
end

function GamepassSystem:getPlayerPremiumStatus(player)
	return {
		bitizenship = self:hasBitizenship(player),
		godMode = self:hasGodMode(player),
		timeMachine = self:hasTimeMachine(player),
		bossMode = self:hasBossMode(player),
		mafia = self:hasMafia(player),
		royalty = self:hasRoyalty(player),
		celebrity = self:hasCelebrity(player),
		darkMode = self:hasDarkMode(player),
	}
end

-- CRITICAL FIX #8: Refresh gamepass cache after purchase
function GamepassSystem:refreshPlayerCache(player)
	local playerId = player.UserId
	for key, _ in pairs(self.Gamepasses) do
		local cacheKey = playerId .. "_" .. key
		self.playerOwnership[cacheKey] = nil
	end
end

-- CRITICAL FIX #9: Clear cache when player leaves
function GamepassSystem:onPlayerRemoving(player)
	local playerId = player.UserId
	for key, _ in pairs(self.Gamepasses) do
		local cacheKey = playerId .. "_" .. key
		self.playerOwnership[cacheKey] = nil
	end
end

-- CRITICAL FIX #10: Get gamepass ID by key
function GamepassSystem:getGamepassId(gamepassKey)
	local gamepass = self.Gamepasses[gamepassKey]
	if gamepass then
		return gamepass.id
	end
	return 0
end

-- CRITICAL FIX #11: Check if feature requires specific gamepass
function GamepassSystem:getRequiredGamepassForFeature(featureId)
	local featureMapping = {
		-- Royalty features
		royal_birth = "ROYALTY",
		royal_family = "ROYALTY",
		throne_inheritance = "ROYALTY",
		royal_duties = "ROYALTY",
		royal_marriage = "ROYALTY",
		-- Mafia features
		join_mafia = "MAFIA",
		mafia_operations = "MAFIA",
		crime_family = "MAFIA",
		mob_activities = "MAFIA",
		-- Celebrity features
		actor_career = "CELEBRITY",
		music_career = "CELEBRITY",
		influencer_career = "CELEBRITY",
		athlete_career = "CELEBRITY",
		model_career = "CELEBRITY",
		fame_events = "CELEBRITY",
		-- God Mode features
		edit_stats = "GOD_MODE",
		stat_editing = "GOD_MODE",
		-- Boss Mode features
		start_business = "BOSS_MODE",
		business_empire = "BOSS_MODE",
		-- Time Machine features
		time_travel = "TIME_MACHINE",
		go_back_years = "TIME_MACHINE",
	}
	
	return featureMapping[featureId]
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #18: SYNC GAMEPASS OWNERSHIP TO LIFE STATE
-- This ensures all gamepass flags are properly set on the player's state
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:syncToLifeState(player, lifeState)
	if not lifeState then return end
	
	lifeState.Flags = lifeState.Flags or {}
	lifeState.GamepassOwnership = lifeState.GamepassOwnership or {}
	
	-- Check each gamepass and set flags
	local gamepassChecks = {
		{ key = "ROYALTY", flag = "royalty_gamepass", ownership = "royalty" },
		{ key = "MAFIA", flag = "mafia_gamepass", ownership = "mafia" },
		{ key = "CELEBRITY", flag = "celebrity_gamepass", ownership = "celebrity" },
		{ key = "GOD_MODE", flag = "god_mode_gamepass", ownership = "godMode" },
		{ key = "TIME_MACHINE", flag = "time_machine_gamepass", ownership = "timeMachine" },
		{ key = "BOSS_MODE", flag = "boss_mode_gamepass", ownership = "bossMode" },
		{ key = "BITIZENSHIP", flag = "bitizen", ownership = "bitizenship" },
	}
	
	for _, check in ipairs(gamepassChecks) do
		local owns = self:checkOwnership(player, check.key)
		lifeState.Flags[check.flag] = owns or nil
		lifeState.GamepassOwnership[check.ownership] = owns
		
		-- Special handling for god mode
		if check.key == "GOD_MODE" and owns then
			lifeState.GodModeState = lifeState.GodModeState or {}
			lifeState.GodModeState.enabled = true
		end
	end
	
	return lifeState
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #15: ROYAL RANK PROGRESSION HELPER
-- Handles progression from Prince/Princess → King/Queen with proper titles
-- ════════════════════════════════════════════════════════════════════════════

GamepassSystem.RoyalRankProgression = {
	male = {
		{ title = "Prince", level = 1 },
		{ title = "Crown Prince", level = 2 },
		{ title = "King", level = 3, isMonarch = true },
	},
	female = {
		{ title = "Princess", level = 1 },
		{ title = "Crown Princess", level = 2 },
		{ title = "Queen", level = 3, isMonarch = true },
	},
}

function GamepassSystem:getRoyalRank(lifeState)
	if not lifeState.RoyalState or not lifeState.RoyalState.isRoyal then
		return nil
	end
	
	local gender = (lifeState.Gender or "Male"):lower()
	local ranks = self.RoyalRankProgression[gender] or self.RoyalRankProgression.male
	
	if lifeState.RoyalState.isMonarch then
		return ranks[3]
	elseif lifeState.RoyalState.lineOfSuccession == 1 then
		return ranks[2]
	else
		return ranks[1]
	end
end

function GamepassSystem:updateRoyalTitle(lifeState)
	local rank = self:getRoyalRank(lifeState)
	if rank then
		lifeState.RoyalState.title = rank.title
	end
	return rank
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #17: MAFIA EVENT TRIGGER HELPERS
-- Provides proper mafia event triggering support
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:canTriggerMafiaEvent(player, lifeState, eventType)
	if not self:hasMafia(player) then
		return false, "Mafia gamepass required"
	end
	
	if not lifeState.MobState or not lifeState.MobState.inMob then
		if eventType ~= "approach" and eventType ~= "recruitment" then
			return false, "Must be in a crime family"
		end
	end
	
	return true, nil
end

function GamepassSystem:getMafiaEventChance(lifeState, eventType)
	local mobState = lifeState.MobState
	if not mobState or not mobState.inMob then
		return 0.05 -- 5% chance to get approached if not in mob
	end
	
	-- Base chances by event type
	local baseChances = {
		operation = 0.30,
		loyalty_test = 0.10,
		promotion = 0.15,
		war = 0.05,
		betrayal = 0.08,
		arrest = 0.10 + (mobState.heat or 0) / 200,
	}
	
	return baseChances[eventType] or 0.10
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #356: Developer Product Purchase Handler
-- Handles one-time time machine purchases (5yr, 10yr, 20yr, baby)
-- ════════════════════════════════════════════════════════════════════════════

-- Pending time machine actions (player -> years to travel back)
GamepassSystem.pendingTimeMachineActions = {}

-- Product ID to years mapping for ProcessReceipt
GamepassSystem.productIdToYears = {
	[3477466389] = 5,   -- 5 years
	[3477466522] = 10,  -- 10 years
	[3477466619] = 20,  -- 20 years
	[3477466778] = -1,  -- Baby (restart)
}

function GamepassSystem:getProductKeyForYears(years)
	if years == 5 then return "TIME_5_YEARS"
	elseif years == 10 then return "TIME_10_YEARS"
	elseif years == 20 then return "TIME_20_YEARS"
	elseif years == 30 then return "TIME_30_YEARS"
	elseif years == -1 then return "TIME_BABY"
	end
	return nil
end

function GamepassSystem:getProductIdForYears(years)
	local key = self:getProductKeyForYears(years)
	if key and self.Products[key] then
		return self.Products[key].id
	end
	return 0
end

-- Called when a developer product is purchased
-- Returns: Enum.ProductPurchaseDecision
function GamepassSystem:processProductReceipt(receiptInfo, getPlayerState, executeTimeMachine)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left, but purchase succeeded - we should still grant it
		-- Store for later if they rejoin (not implemented here for simplicity)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	local productId = receiptInfo.ProductId
	local years = self.productIdToYears[productId]
	
	if years then
		-- This is a time machine product
		print("[GamepassSystem] Processing Time Machine product:", productId, "years:", years)
		
		-- Execute the time machine action
		if executeTimeMachine then
			local success, result = pcall(function()
				return executeTimeMachine(player, years)
			end)
			
			if success and result and result.success then
				print("[GamepassSystem] Time Machine purchase successful for player:", player.Name)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			else
				warn("[GamepassSystem] Time Machine failed:", result and result.message or "Unknown error")
				-- Still grant since payment was taken
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		
		-- Mark as pending for this player so handleTimeMachine can use it
		self.pendingTimeMachineActions[player.UserId] = years
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	-- Unknown product
	warn("[GamepassSystem] Unknown product ID:", productId)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Check if player has a pending time machine action from product purchase
function GamepassSystem:hasPendingTimeMachine(player)
	return self.pendingTimeMachineActions[player.UserId] ~= nil
end

function GamepassSystem:getPendingTimeMachineYears(player)
	return self.pendingTimeMachineActions[player.UserId]
end

function GamepassSystem:clearPendingTimeMachine(player)
	self.pendingTimeMachineActions[player.UserId] = nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #357: Gamepass Purchase Listener for UI Refresh
-- Fires an event when a gamepass is purchased so UI can refresh
-- ════════════════════════════════════════════════════════════════════════════

-- Store callback for when gamepass is purchased (set by LifeBackend)
GamepassSystem.onGamepassPurchased = nil

function GamepassSystem:setGamepassPurchasedCallback(callback)
	self.onGamepassPurchased = callback
end

function GamepassSystem:notifyGamepassPurchased(player, gamepassKey)
	-- CRITICAL FIX #400: Clear ownership cache properly using correct cache key format
	-- Cache uses format: playerId .. "_" .. gamepassKey
	local playerId = player.UserId
	local cacheKey = playerId .. "_" .. gamepassKey
	
	-- Clear this specific gamepass cache entry
	self.playerOwnership[cacheKey] = nil
	
	-- CRITICAL FIX #401: Immediately re-check and cache the new ownership status
	-- This ensures the next check returns the updated value
	local success, owns = pcall(function()
		local gamepass = self.Gamepasses[gamepassKey]
		if gamepass and gamepass.id and gamepass.id ~= 0 then
			return MarketplaceService:UserOwnsGamePassAsync(playerId, gamepass.id)
		end
		return false
	end)
	
	if success then
		self.playerOwnership[cacheKey] = owns
		print("[GamepassSystem] Updated ownership cache for", player.Name, gamepassKey, "=", owns)
	end
	
	-- Call callback if set
	if self.onGamepassPurchased then
		self.onGamepassPurchased(player, gamepassKey)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SINGLETON INSTANCE
-- ════════════════════════════════════════════════════════════════════════════

local instance = GamepassSystem.new()

return instance
