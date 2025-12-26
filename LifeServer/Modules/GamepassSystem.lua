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
	TIME_MACHINE = 1630681215, -- Time Machine gamepass (unlimited rewinds)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- ⚠️ CRITICAL WARNING: These gamepasses have ID=0 and CANNOT BE PURCHASED!
	-- You need to create these gamepasses on Roblox and add their IDs here!
	-- To create a gamepass: Go to Game Settings → Monetization → Passes → Create
	-- Then copy the ID from the URL and paste it below.
	-- ═══════════════════════════════════════════════════════════════════════════════
	BITIZENSHIP = 0,  -- ⚠️ NEEDS REAL ID - Ad-free + bonus features
	BOSS_MODE = 0,    -- ⚠️ NEEDS REAL ID - Start businesses
	DARK_MODE = 0,    -- ⚠️ NEEDS REAL ID - Dark theme UI
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #920: STAT_BOOST Developer Product
	-- Boosts all stats when player is struggling
	-- ═══════════════════════════════════════════════════════════════════════════════
	STAT_BOOST = {
		id = 3489760202,  -- REAL PRODUCT ID from user
		name = "Miracle Boost! 💪",
		emoji = "📈",
		description = "Instantly boost ALL stats by +25! Health, Happiness, Smarts, Looks!",
		price = 50,
		type = "consumable",
		boostAmount = 25,  -- How much to boost each stat
	},
	
	-- CRITICAL FIX #900: Get Out of Jail Developer Product
	GET_OUT_OF_JAIL = {
		id = 3489751054,  -- REAL PRODUCT ID
		name = "Get Out of Jail FREE!",
		emoji = "🔓",
		description = "Instantly released from prison! All charges dropped!",
		price = 49,
		type = "consumable",
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #921: EXTRA_LIFE Developer Product - AMAZING IMPLEMENTATION!
	-- When you die, you get a SECOND CHANCE at life!
	-- - Your character is "miraculously saved" and revived
	-- - Health fully restored to 100
	-- - You keep ALL your assets, money, relationships
	-- - Age is rolled back 5-10 years (you were in a coma/recovery)
	-- - You get a "Survivor" badge and unique life story
	-- - Special "Near Death Experience" events unlock
	-- - Your character gains wisdom (+10 Smarts)
	-- - Creates a dramatic narrative moment!
	-- ═══════════════════════════════════════════════════════════════════════════════
	EXTRA_LIFE = {
		id = 3489759791,  -- REAL PRODUCT ID from user
		name = "Second Chance at Life! 💖",
		emoji = "💖",
		description = "Miraculously survive death! Keep everything, revive younger & wiser!",
		price = 99,
		type = "consumable",
		-- How it works:
		-- 1. Death is prevented
		-- 2. Age rolled back 5-10 years (recovery/coma time)
		-- 3. Health restored to 100%
		-- 4. Keep all money, assets, relationships
		-- 5. Gain "survivor" flag for unique events
		-- 6. +10 Smarts (near-death wisdom)
		-- 7. Special narrative message about survival
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem.new()
	local self = setmetatable({}, GamepassSystem)
	self.playerOwnership = {} -- Cache of player ownership
	self.ownershipCallbacks = {} -- Callbacks for ownership changes
	-- CRITICAL FIX #10: Persistent ownership cache to survive across server restarts
	self.persistentOwnership = {}
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #10: Initialize all gamepass ownership for a player on join
-- This ensures ownership is checked once and cached immediately
-- ════════════════════════════════════════════════════════════════════════════
function GamepassSystem:initializePlayerOwnership(player)
	if not player then return end
	
	local playerId = player.UserId
	self.persistentOwnership[playerId] = self.persistentOwnership[playerId] or {}
	
	-- Check all gamepasses upfront
	local gamepassesToCheck = { "ROYALTY", "GOD_MODE", "MAFIA", "CELEBRITY", "TIME_MACHINE", "BOSS_MODE", "BITIZENSHIP" }
	
	for _, gamepassKey in ipairs(gamepassesToCheck) do
		local gamepass = self.Gamepasses[gamepassKey]
		if gamepass and gamepass.id and gamepass.id > 0 then
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(playerId, gamepass.id)
			end)
			
			if success and owns == true then
				local cacheKey = playerId .. "_" .. gamepassKey
				self.playerOwnership[cacheKey] = true
				self.persistentOwnership[playerId][gamepassKey] = true
			end
		end
	end
	
	return self.persistentOwnership[playerId]
end

-- CRITICAL FIX #10: Get all owned gamepasses for a player
function GamepassSystem:getOwnedGamepasses(player)
	if not player then return {} end
	
	local owned = {}
	local playerId = player.UserId
	
	if self.persistentOwnership[playerId] then
		for gamepassKey, ownsIt in pairs(self.persistentOwnership[playerId]) do
			if ownsIt then
				table.insert(owned, gamepassKey)
			end
		end
	end
	
	return owned
end

-- CRITICAL FIX #10: Restore ownership from saved state
function GamepassSystem:restoreOwnershipFromState(player, savedOwnership)
	if not player or not savedOwnership then return end
	
	local playerId = player.UserId
	self.persistentOwnership[playerId] = self.persistentOwnership[playerId] or {}
	
	for gamepassKey, ownsIt in pairs(savedOwnership) do
		if ownsIt == true then
			local cacheKey = playerId .. "_" .. gamepassKey
			self.playerOwnership[cacheKey] = true
			self.persistentOwnership[playerId][gamepassKey] = true
		end
	end
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
	
	-- CRITICAL FIX #427: If cache is TRUE, ALWAYS return true - never re-check!
	-- A purchased gamepass can never become unpurchased
	if self.playerOwnership[cacheKey] == true then
		return true
	end
	
	-- CRITICAL FIX #10: Check persistent cache from DataStore first
	-- This ensures ownership persists across server restarts and rejoins
	if self.persistentOwnership and self.persistentOwnership[playerId] then
		if self.persistentOwnership[playerId][gamepassKey] == true then
			self.playerOwnership[cacheKey] = true
			return true
		end
	end
	
	-- Only check server if we don't know or cache is false
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(playerId, gamepass.id)
	end)
	
	if success then
		-- CRITICAL FIX #428: ONLY upgrade to true, NEVER downgrade to false
		-- MarketplaceService might return stale data right after purchase
		if owns == true then
			self.playerOwnership[cacheKey] = true
		elseif self.playerOwnership[cacheKey] == nil then
			-- Only set to false if we've never checked before
			self.playerOwnership[cacheKey] = false
		end
		-- If cache was already true but API returned false, KEEP it true!
		return self.playerOwnership[cacheKey]
	else
		warn("[GamepassSystem] Failed to check ownership:", owns)
	end
	
	-- Return cached value if API failed, or false if no cache
	return self.playerOwnership[cacheKey] or false
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
-- CRITICAL FIX: Track when prompts are shown to avoid spamming
-- ════════════════════════════════════════════════════════════════════════════

-- Track when we last showed a prompt for each player/gamepass combo
GamepassSystem.promptHistory = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #500: REDUCED COOLDOWN FROM 30 MINUTES TO 3 SECONDS!
-- The old 30-minute cooldown was KILLING sales!
-- User complaint: "clicking gamepass button doesn't popup again after first try"
-- Problem: After clicking once, users had to wait 30 MINUTES to try again!
-- Now: 3-second cooldown just to prevent accidental double-clicks
-- ═══════════════════════════════════════════════════════════════════════════════
GamepassSystem.PROMPT_COOLDOWN = 3 -- 3 seconds (was 1800 = 30 minutes!)

-- CRITICAL FIX #501: Track if prompt was triggered by direct user click (bypasses cooldown)
GamepassSystem.COOLDOWN_BYPASS_FLAG = "_user_click"

function GamepassSystem:canShowPrompt(player, gamepassKey, requiresFatalCondition, playerState, forceBypassCooldown)
	local playerId = player.UserId
	local cacheKey = playerId .. "_prompt_" .. gamepassKey
	
	-- Check if player already owns the gamepass
	if self:checkOwnership(player, gamepassKey) then
		return false, "already_owns"
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #502: Allow bypass of cooldown for direct user clicks!
	-- When a user INTENTIONALLY clicks a purchase button, ALWAYS show the prompt!
	-- The cooldown should only prevent auto-prompts from spamming, not block purchases!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if forceBypassCooldown == true then
		-- User clicked button intentionally - ALWAYS show prompt!
		return true, nil
	end
	
	-- Check prompt cooldown (only for auto-prompts, not user clicks)
	local lastPrompt = self.promptHistory[cacheKey]
	if lastPrompt then
		local timeSince = os.time() - lastPrompt
		if timeSince < self.PROMPT_COOLDOWN then
			return false, "cooldown", self.PROMPT_COOLDOWN - timeSince
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #503: GOD_MODE fatal condition check ONLY for death-screen prompts
	-- NOT for intro screen or direct button clicks!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if gamepassKey == "GOD_MODE" and requiresFatalCondition == true then
		if not playerState then
			return false, "no_state"
		end
		
		local flags = playerState.Flags or {}
		local health = playerState.Health or playerState.Stats and playerState.Stats.Health or 50
		
		-- Must be dying or dead to get God Mode prompt
		local isDying = health <= 10
		local isDead = flags.dead or flags.is_dead
		local hasFatalCondition = flags.fatal_condition or flags.dying or flags.near_death
		
		if not isDying and not isDead and not hasFatalCondition then
			return false, "not_fatal_condition"
		end
	end
	
	return true, nil
end

function GamepassSystem:recordPromptShown(player, gamepassKey)
	local playerId = player.UserId
	local cacheKey = playerId .. "_prompt_" .. gamepassKey
	self.promptHistory[cacheKey] = os.time()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #504: Added forceBypassCooldown parameter!
-- When true, bypasses the cooldown check for direct user clicks
-- This ensures users can ALWAYS attempt to buy when they click a button
-- ═══════════════════════════════════════════════════════════════════════════════
function GamepassSystem:promptGamepass(player, gamepassKey, forceBypassCooldown)
	local gamepass = self.Gamepasses[gamepassKey]
	if not gamepass or gamepass.id == 0 then
		warn("[GamepassSystem] Cannot prompt purchase - invalid ID for:", gamepassKey)
		-- CRITICAL FIX #505: Return detailed error info so client can show feedback
		return false, "invalid_gamepass", gamepassKey
	end
	
	-- CRITICAL FIX #506: Pass forceBypassCooldown to canShowPrompt
	local canShow, reason, timeRemaining = self:canShowPrompt(player, gamepassKey, false, nil, forceBypassCooldown)
	if not canShow then
		if reason == "already_owns" then
			print("[GamepassSystem] Player already owns", gamepassKey, "- not showing prompt")
			return false, "already_owns", gamepassKey
		elseif reason == "cooldown" then
			print("[GamepassSystem] Prompt cooldown active for", gamepassKey, "- wait", timeRemaining, "seconds")
			return false, "cooldown", timeRemaining
		end
		return false, reason, gamepassKey
	end
	
	-- Record that we showed this prompt
	self:recordPromptShown(player, gamepassKey)
	
	local success, err = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, gamepass.id)
	end)
	
	if not success then
		warn("[GamepassSystem] Failed to prompt purchase:", err)
		return false, "roblox_error", tostring(err)
	end
	
	print("[GamepassSystem] ✅ Successfully prompted", gamepassKey, "purchase for", player.Name)
	return true, nil, nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #935: Enhanced product prompting with cooldowns and non-annoying behavior
-- Products now have cooldowns just like gamepasses to prevent spam
-- ═══════════════════════════════════════════════════════════════════════════════

-- Cooldowns for products (in seconds)
GamepassSystem.productCooldowns = {
	GET_OUT_OF_JAIL = 120,   -- 2 minutes (they're in jail, they'll see it)
	EXTRA_LIFE = 300,        -- 5 minutes (only prompt on death-adjacent events)
	STAT_BOOST = 180,        -- 3 minutes (prompt when stats are low)
	TIME_5_YEARS = 300,      -- 5 minutes
	TIME_10_YEARS = 300,
	TIME_20_YEARS = 300,
}

-- Track when products were last prompted
GamepassSystem.lastProductPrompt = {}

function GamepassSystem:canPromptProduct(player, productKey)
	local playerId = player.UserId
	local cacheKey = playerId .. "_product_" .. productKey
	
	local lastPrompt = self.lastProductPrompt[cacheKey]
	local cooldown = self.productCooldowns[productKey] or 180 -- Default 3 minute cooldown
	
	if lastPrompt and (os.time() - lastPrompt) < cooldown then
		local remaining = cooldown - (os.time() - lastPrompt)
		return false, "cooldown", remaining
	end
	
	return true, nil, nil
end

function GamepassSystem:recordProductPrompt(player, productKey)
	local playerId = player.UserId
	local cacheKey = playerId .. "_product_" .. productKey
	self.lastProductPrompt[cacheKey] = os.time()
end

function GamepassSystem:promptProduct(player, productKey, forceBypassCooldown)
	local product = self.Products[productKey]
	if not product or product.id == 0 then
		warn("[GamepassSystem] Cannot prompt purchase - invalid ID for:", productKey)
		return false, "invalid_product"
	end
	
	-- Check cooldown unless bypassing
	if not forceBypassCooldown then
		local canPrompt, reason, remaining = self:canPromptProduct(player, productKey)
		if not canPrompt then
			print("[GamepassSystem] Product prompt cooldown active for", productKey, "- wait", remaining, "seconds")
			return false, "cooldown"
		end
	end
	
	-- Record that we prompted this product
	self:recordProductPrompt(player, productKey)
	
	local success, err = pcall(function()
		MarketplaceService:PromptProductPurchase(player, product.id)
	end)
	
	if not success then
		warn("[GamepassSystem] Failed to prompt purchase:", err)
		return false, "roblox_error"
	end
	
	print("[GamepassSystem] ✅ Successfully prompted product", productKey, "for", player.Name)
	return true, nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #936: Get product info for CardPopup display
-- Returns info that can be shown in a nice UI card before prompting
-- ═══════════════════════════════════════════════════════════════════════════════
function GamepassSystem:getProductInfo(productKey)
	local product = self.Products[productKey]
	if not product then return nil end
	
	return {
		key = productKey,
		id = product.id,
		name = product.name,
		emoji = product.emoji,
		description = product.description,
		price = product.price,
		type = product.type,
	}
end

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
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- GOD MODE PROMPT - REQUIRES FATAL CONDITION
-- This is the ONLY way God Mode should be prompted
-- It validates that the player is actually dying/dead before showing the prompt
-- ════════════════════════════════════════════════════════════════════════════
function GamepassSystem:promptGodModeOnDeath(player, playerState)
	if not player or not playerState then
		warn("[GamepassSystem] Cannot prompt God Mode - missing player or state")
		return false
	end
	
	-- Already owns? No need to prompt
	if self:hasGodMode(player) then
		print("[GamepassSystem] Player already has God Mode - not prompting")
		return false
	end
	
	-- Validate fatal condition
	local flags = playerState.Flags or {}
	local health = playerState.Health or (playerState.Stats and playerState.Stats.Health) or 50
	
	local isDying = health <= 10
	local isDead = flags.dead or flags.is_dead
	local hasFatalCondition = flags.fatal_condition or flags.dying or flags.near_death
	
	if not isDying and not isDead and not hasFatalCondition then
		warn("[GamepassSystem] God Mode prompt blocked - no fatal condition detected")
		warn("[GamepassSystem] Health:", health, "Dead:", tostring(isDead), "Dying:", tostring(hasFatalCondition))
		return false
	end
	
	-- Check cooldown
	local canShow, reason, timeRemaining = self:canShowPrompt(player, "GOD_MODE", true, playerState)
	if not canShow then
		if reason == "already_owns" then
			print("[GamepassSystem] Player already owns GOD_MODE - not showing prompt")
		elseif reason == "cooldown" then
			print("[GamepassSystem] God Mode prompt on cooldown - wait", timeRemaining, "seconds")
		elseif reason == "not_fatal_condition" then
			print("[GamepassSystem] God Mode prompt blocked - no fatal condition")
		end
		return false
	end
	
	-- Record the prompt
	self:recordPromptShown(player, "GOD_MODE")
	
	-- Track offer count
	flags.god_mode_offer_count = (flags.god_mode_offer_count or 0) + 1
	flags.last_god_mode_offer_age = playerState.Age
	
	print("[GamepassSystem] Showing God Mode prompt due to fatal condition (Health:", health, ")")
	
	local success, err = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, self.Gamepasses.GOD_MODE.id)
	end)
	
	if not success then
		warn("[GamepassSystem] Failed to prompt God Mode purchase:", err)
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

-- CRITICAL FIX #904: Special product IDs that need custom handling
GamepassSystem.specialProductIds = {
	[3489751054] = "GET_OUT_OF_JAIL",  -- Instant jail release
	[3489759791] = "EXTRA_LIFE",       -- Miraculous survival on death
	[3489760202] = "STAT_BOOST",       -- Boost all stats +25
}

-- Pending actions (player -> true)
GamepassSystem.pendingJailRelease = {}
GamepassSystem.pendingExtraLife = {}  -- Player has an extra life ready to use
GamepassSystem.pendingStatBoost = {}

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
function GamepassSystem:processProductReceipt(receiptInfo, getPlayerState, executeTimeMachine, executeJailRelease, executeStatBoost, executeExtraLife)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left, but purchase succeeded - we should still grant it
		-- Store for later if they rejoin (not implemented here for simplicity)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	local productId = receiptInfo.ProductId
	local years = self.productIdToYears[productId]
	
	-- CRITICAL FIX #905: Check for special products (GET_OUT_OF_JAIL, EXTRA_LIFE, STAT_BOOST)
	local specialProduct = self.specialProductIds[productId]
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- GET OUT OF JAIL - Instant prison release
	-- ═══════════════════════════════════════════════════════════════════════════════
	if specialProduct == "GET_OUT_OF_JAIL" then
		print("[GamepassSystem] Processing GET OUT OF JAIL product for:", player.Name)
		
		if executeJailRelease then
			local success, result = pcall(function()
				return executeJailRelease(player)
			end)
			
			if success and result and result.success then
				print("[GamepassSystem] GET OUT OF JAIL successful for player:", player.Name)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			else
				warn("[GamepassSystem] GET OUT OF JAIL failed:", result and result.message or "Unknown error")
				self.pendingJailRelease[player.UserId] = true
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		else
			self.pendingJailRelease[player.UserId] = true
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- STAT_BOOST - Instantly boost all stats by +25!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if specialProduct == "STAT_BOOST" then
		print("[GamepassSystem] Processing STAT_BOOST product for:", player.Name)
		
		if executeStatBoost then
			local success, result = pcall(function()
				return executeStatBoost(player)
			end)
			
			if success and result and result.success then
				print("[GamepassSystem] STAT_BOOST successful for player:", player.Name)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			else
				warn("[GamepassSystem] STAT_BOOST failed:", result and result.message or "Unknown error")
				self.pendingStatBoost[player.UserId] = true
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		else
			self.pendingStatBoost[player.UserId] = true
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- EXTRA_LIFE - The AMAZING second chance at life!
	-- This is stored as a "pending" extra life that activates on death
	-- When player dies, instead of dying, they get revived!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if specialProduct == "EXTRA_LIFE" then
		print("[GamepassSystem] Processing EXTRA_LIFE product for:", player.Name)
		
		-- Extra life is stored and used when player would die
		-- Count how many extra lives they have (can stack!)
		local currentLives = self.pendingExtraLife[player.UserId] or 0
		self.pendingExtraLife[player.UserId] = currentLives + 1
		
		print("[GamepassSystem] Player now has", self.pendingExtraLife[player.UserId], "extra lives!")
		
		-- Notify the player they have an extra life ready
		if executeExtraLife then
			pcall(function()
				executeExtraLife(player, "purchased") -- Just notify, don't use yet
			end)
		end
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	if years then
		-- This is a time machine product
		print("[GamepassSystem] Processing Time Machine product:", productId, "years:", years)
		
		if executeTimeMachine then
			local success, result = pcall(function()
				return executeTimeMachine(player, years)
			end)
			
			if success and result and result.success then
				print("[GamepassSystem] Time Machine purchase successful for player:", player.Name)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			else
				warn("[GamepassSystem] Time Machine failed:", result and result.message or "Unknown error")
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		
		self.pendingTimeMachineActions[player.UserId] = years
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	-- Unknown product
	warn("[GamepassSystem] Unknown product ID:", productId)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- CRITICAL FIX #906: Check if player has a pending jail release
function GamepassSystem:hasPendingJailRelease(player)
	return self.pendingJailRelease[player.UserId] == true
end

function GamepassSystem:clearPendingJailRelease(player)
	self.pendingJailRelease[player.UserId] = nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EXTRA_LIFE SYSTEM - The amazing second chance!
-- ═══════════════════════════════════════════════════════════════════════════════

-- Check if player has an extra life to use
function GamepassSystem:hasExtraLife(player)
	return (self.pendingExtraLife[player.UserId] or 0) > 0
end

-- Get how many extra lives player has
function GamepassSystem:getExtraLives(player)
	return self.pendingExtraLife[player.UserId] or 0
end

-- Use one extra life (called when player would die)
function GamepassSystem:useExtraLife(player)
	local lives = self.pendingExtraLife[player.UserId] or 0
	if lives > 0 then
		self.pendingExtraLife[player.UserId] = lives - 1
		print("[GamepassSystem] Extra life used! Remaining:", lives - 1)
		return true
	end
	return false
end

-- Grant an extra life (from purchase)
function GamepassSystem:grantExtraLife(player)
	local lives = self.pendingExtraLife[player.UserId] or 0
	self.pendingExtraLife[player.UserId] = lives + 1
	return lives + 1
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- STAT_BOOST SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════════

function GamepassSystem:hasPendingStatBoost(player)
	return self.pendingStatBoost[player.UserId] == true
end

function GamepassSystem:clearPendingStatBoost(player)
	self.pendingStatBoost[player.UserId] = nil
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
	-- CRITICAL FIX #426: IMMEDIATELY set cache to TRUE after purchase notification
	-- We KNOW the purchase happened because PromptGamePassPurchaseFinished fired with wasPurchased = true
	-- DO NOT re-check MarketplaceService - it might return stale data!
	local playerId = player.UserId
	local cacheKey = playerId .. "_" .. gamepassKey
	
	-- FORCE the cache to TRUE - we know they own it because they just bought it!
	self.playerOwnership[cacheKey] = true
	print("[GamepassSystem] FORCED ownership cache to TRUE for", player.Name, gamepassKey)
	
	-- Call callback if set
	if self.onGamepassPurchased then
		self.onGamepassPurchased(player, gamepassKey)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #376-385: COMPREHENSIVE GAMEPASS VALIDATION
-- Enhanced validation for all gamepass features
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:validateFeatureAccess(player, featureId, lifeState)
	local requiredPass = self:getRequiredGamepassForFeature(featureId)
	
	if not requiredPass then
		return true, nil -- Feature doesn't require a gamepass
	end
	
	local hasPass = self:checkOwnership(player, requiredPass)
	
	if not hasPass then
		return false, {
			reason = "gamepass_required",
			gamepass = requiredPass,
			gamepassInfo = self:getGamepassInfo(requiredPass),
		}
	end
	
	-- Additional validation based on feature type
	if featureId == "royal_birth" and lifeState then
		if lifeState.Age > 0 then
			return false, { reason = "must_be_newborn", message = "Royalty must be selected at birth" }
		end
	end
	
	if featureId == "join_mafia" and lifeState then
		if lifeState.Age < 18 then
			return false, { reason = "too_young", message = "Must be 18+ to join the mafia" }
		end
		if lifeState.MobState and lifeState.MobState.inMob then
			return false, { reason = "already_in_mob", message = "Already in a crime family" }
		end
	end
	
	return true, nil
end

function GamepassSystem:getFeatureLockedInfo(featureId)
	local requiredPass = self:getRequiredGamepassForFeature(featureId)
	if not requiredPass then
		return nil -- Not locked
	end
	
	local passInfo = self:getGamepassInfo(requiredPass)
	return {
		isLocked = true,
		requiredGamepass = requiredPass,
		gamepassName = passInfo and passInfo.name or requiredPass,
		gamepassEmoji = passInfo and passInfo.emoji or "🔒",
		gamepassPrice = passInfo and passInfo.price or 0,
		gamepassId = passInfo and passInfo.id or 0,
	}
end

-- CRITICAL FIX #386: Check all gamepasses at once for batch operations
function GamepassSystem:checkAllOwnership(player)
	local ownership = {}
	for key, _ in pairs(self.Gamepasses) do
		ownership[key] = self:checkOwnership(player, key)
	end
	return ownership
end

-- CRITICAL FIX #387: Immediate callback after gamepass purchase
function GamepassSystem:setupPurchaseFinishedListener()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
		if wasPurchased then
			-- Find which gamepass was purchased
			for key, data in pairs(self.Gamepasses) do
				if data.id == gamepassId then
					print("[GamepassSystem] Player", player.Name, "purchased", key)
					self:notifyGamepassPurchased(player, key)
					break
				end
			end
		end
	end)
end

-- CRITICAL FIX #388: Celebrity career stage progression check
function GamepassSystem:canProgressFameCareer(lifeState)
	if not lifeState.FameState then
		return false, "No fame career"
	end
	
	local fameState = lifeState.FameState
	local careerPath = fameState.careerPath
	local currentStage = fameState.currentStage
	
	if not careerPath then
		return false, "No career path selected"
	end
	
	local paths = self:getCelebrityCareerPaths()
	local path = paths[careerPath]
	
	if not path then
		return false, "Invalid career path"
	end
	
	local nextStage = path.stages[currentStage + 1]
	if not nextStage then
		return false, "Already at max stage"
	end
	
	-- Check requirements
	local yearsInCareer = fameState.yearsInCareer or 0
	local currentFame = lifeState.Fame or 0
	
	if yearsInCareer < (nextStage.yearsRequired or 0) then
		return false, string.format("Need %d years (have %d)", nextStage.yearsRequired, yearsInCareer)
	end
	
	if currentFame < (nextStage.fame or 0) then
		return false, string.format("Need %d fame (have %d)", nextStage.fame, currentFame)
	end
	
	return true, nextStage
end

-- CRITICAL FIX #389: Progress fame career to next stage
function GamepassSystem:progressFameCareer(lifeState)
	local canProgress, nextStageOrReason = self:canProgressFameCareer(lifeState)
	
	if not canProgress then
		return false, nextStageOrReason
	end
	
	local nextStage = nextStageOrReason
	local fameState = lifeState.FameState
	local careerPath = fameState.careerPath
	local paths = self:getCelebrityCareerPaths()
	local path = paths[careerPath]
	
	-- Update fame state
	fameState.currentStage = fameState.currentStage + 1
	fameState.stageName = nextStage.name
	fameState.lastPromotionYear = lifeState.Year or 2025
	
	-- Update salary
	local newSalary = math.random(nextStage.salary[1], nextStage.salary[2])
	if lifeState.CurrentJob then
		lifeState.CurrentJob.name = nextStage.name
		lifeState.CurrentJob.salary = newSalary
	end
	
	-- Update fame
	lifeState.Fame = math.max(lifeState.Fame or 0, nextStage.fame or 0)
	
	-- Update followers if applicable
	if nextStage.followers then
		fameState.followers = math.max(fameState.followers or 0, nextStage.followers)
	end
	
	-- Check if now famous
	if (lifeState.Fame or 0) >= 30 then
		fameState.isFamous = true
	end
	
	return true, string.format("Promoted to %s! Salary: $%s", nextStage.name, newSalary)
end

-- CRITICAL FIX #390: Fame decay over time for celebrities
function GamepassSystem:tickFameDecay(lifeState)
	if not lifeState.FameState or not lifeState.FameState.isFamous then
		return
	end
	
	local fame = lifeState.Fame or 0
	local fameState = lifeState.FameState
	
	-- Fame decays if not active in career
	local yearsInCareer = fameState.yearsInCareer or 0
	local yearsSincePromotion = (lifeState.Year or 2025) - (fameState.lastPromotionYear or 2025)
	
	-- Decay faster if inactive
	local decayRate = 1
	if yearsSincePromotion > 3 then
		decayRate = 2
	end
	if yearsSincePromotion > 5 then
		decayRate = 3
	end
	
	-- Random fame decay (some years fame drops)
	if math.random() < 0.3 then
		lifeState.Fame = math.max(0, fame - decayRate)
	end
	
	-- Followers can also drop
	if fameState.followers and fameState.followers > 0 and math.random() < 0.2 then
		local followerLoss = math.floor(fameState.followers * 0.05) -- 5% loss
		fameState.followers = math.max(0, fameState.followers - followerLoss)
	end
end

-- CRITICAL FIX #391: Royalty succession handling
function GamepassSystem:checkRoyalSuccession(lifeState)
	if not lifeState.RoyalState or not lifeState.RoyalState.isRoyal then
		return false, "Not royalty"
	end
	
	local royalState = lifeState.RoyalState
	
	-- Already monarch
	if royalState.isMonarch then
		return false, "Already the monarch"
	end
	
	-- First in line? 10% chance per year of ascending
	if royalState.lineOfSuccession == 1 then
		if math.random() < 0.10 then
			return true, "The monarch has passed. You are now first in line to ascend!"
		end
	end
	
	-- Move up in succession line (5% chance per year)
	if math.random() < 0.05 and royalState.lineOfSuccession > 1 then
		royalState.lineOfSuccession = royalState.lineOfSuccession - 1
		return false, string.format("Moved up in succession. Now #%d in line.", royalState.lineOfSuccession)
	end
	
	return false, nil
end

-- CRITICAL FIX #392: Execute royal succession (become monarch)
function GamepassSystem:executeRoyalSuccession(lifeState)
	if not lifeState.RoyalState then
		return false, "Not royalty"
	end
	
	local royalState = lifeState.RoyalState
	royalState.isMonarch = true
	royalState.lineOfSuccession = 0
	royalState.reignYears = 0
	
	-- Update title
	local gender = (lifeState.Gender or "Male"):lower()
	if gender == "male" then
		royalState.title = "King"
	else
		royalState.title = "Queen"
	end
	
	-- Set flags
	lifeState.Flags = lifeState.Flags or {}
	lifeState.Flags.is_monarch = true
	lifeState.Flags.ascended_throne = true
	lifeState.Flags.coronation_year = lifeState.Year
	
	-- Fame boost
	lifeState.Fame = math.min(100, (lifeState.Fame or 0) + 40)
	
	-- Popularity boost
	royalState.popularity = math.min(100, (royalState.popularity or 50) + 20)
	
	return true, string.format("👑 Long live %s %s! You are now the ruling monarch!", royalState.title, lifeState.Name or "")
end

-- CRITICAL FIX #393: Mafia rank-based operation reward multipliers
function GamepassSystem:getMafiaRewardMultiplier(lifeState)
	if not lifeState.MobState or not lifeState.MobState.inMob then
		return 1.0
	end
	
	local rankIndex = lifeState.MobState.rankIndex or 1
	-- Higher ranks get better cuts
	local multipliers = { 1.0, 1.2, 1.5, 2.0, 3.0 }
	return multipliers[rankIndex] or 1.0
end

-- CRITICAL FIX #394: Mafia loyalty decay
function GamepassSystem:tickMafiaLoyalty(lifeState)
	if not lifeState.MobState or not lifeState.MobState.inMob then
		return
	end
	
	local mobState = lifeState.MobState
	
	-- Loyalty decays if not doing operations
	local opsCompleted = mobState.operationsCompleted or 0
	local yearsInMob = mobState.yearsInMob or 0
	
	local opsPerYear = 0
	if yearsInMob > 0 then
		opsPerYear = opsCompleted / yearsInMob
	end
	
	-- If less than 2 operations per year, loyalty slowly drops
	if opsPerYear < 2 then
		mobState.loyalty = math.max(0, (mobState.loyalty or 100) - 5)
	end
	
	-- Very low loyalty triggers events
	if (mobState.loyalty or 100) < 30 then
		lifeState.Flags = lifeState.Flags or {}
		lifeState.Flags.low_mob_loyalty = true
	end
end

-- CRITICAL FIX #395: Event cooldown validation
function GamepassSystem:validateEventCooldown(lifeState, eventId, cooldownYears)
	if not lifeState.EventHistory then
		return true -- No history, can trigger
	end
	
	local lastOccurrence = lifeState.EventHistory.lastOccurrence
	if not lastOccurrence or not lastOccurrence[eventId] then
		return true -- Never occurred
	end
	
	local lastAge = lastOccurrence[eventId]
	local currentAge = lifeState.Age or 0
	local yearsSince = currentAge - lastAge
	
	return yearsSince >= (cooldownYears or 1)
end

-- CRITICAL FIX #396: Record event occurrence for cooldown
function GamepassSystem:recordEventOccurrence(lifeState, eventId)
	lifeState.EventHistory = lifeState.EventHistory or {}
	lifeState.EventHistory.occurrences = lifeState.EventHistory.occurrences or {}
	lifeState.EventHistory.lastOccurrence = lifeState.EventHistory.lastOccurrence or {}
	
	lifeState.EventHistory.occurrences[eventId] = (lifeState.EventHistory.occurrences[eventId] or 0) + 1
	lifeState.EventHistory.lastOccurrence[eventId] = lifeState.Age or 0
end

-- CRITICAL FIX #397: Career skill requirements check
function GamepassSystem:checkCareerSkillRequirements(lifeState, jobRequirements)
	if not jobRequirements then
		return true, nil
	end
	
	local skills = (lifeState.CareerInfo and lifeState.CareerInfo.skills) or {}
	local missing = {}
	
	for skill, required in pairs(jobRequirements) do
		local playerSkill = skills[skill] or 0
		if playerSkill < required then
			table.insert(missing, {
				skill = skill,
				required = required,
				have = playerSkill,
			})
		end
	end
	
	if #missing > 0 then
		return false, missing
	end
	
	return true, nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- SINGLETON INSTANCE
-- ════════════════════════════════════════════════════════════════════════════

local instance = GamepassSystem.new()

-- CRITICAL FIX #398: Auto-setup purchase listener
instance:setupPurchaseFinishedListener()

return instance
