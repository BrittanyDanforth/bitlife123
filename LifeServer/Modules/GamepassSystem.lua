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
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local GamepassSystem = {}
GamepassSystem.__index = GamepassSystem

-- ════════════════════════════════════════════════════════════════════════════
-- GAMEPASS DEFINITIONS
-- Replace these IDs with your actual Roblox gamepass IDs
-- ════════════════════════════════════════════════════════════════════════════

GamepassSystem.Gamepasses = {
	-- Core Premium Passes
	BITIZENSHIP = {
		id = 0, -- Replace with actual gamepass ID
		name = "Bitizenship",
		emoji = "👑",
		description = "Unlock premium features! Ad-free, special careers, and more.",
		price = 299, -- Robux
		features = {
			"Ad-free experience",
			"Access to Royalty careers",
			"Special character customization",
			"Exclusive random events",
			"Start with bonus money",
		},
	},
	
	GOD_MODE = {
		id = 0, -- Replace with actual gamepass ID
		name = "God Mode",
		emoji = "⚡",
		description = "Edit your stats anytime! Become the perfect person.",
		price = 499, -- Robux
		features = {
			"Edit Happiness, Health, Smarts, Looks anytime",
			"Set any stat from 0-100",
			"Change your character's appearance",
			"Modify relationship levels",
			"Instant skill boosts",
		},
	},
	
	TIME_MACHINE = {
		id = 0, -- Replace with actual gamepass ID
		name = "Time Machine",
		emoji = "⏰",
		description = "Go back in time when you die! Fix your mistakes.",
		price = 399, -- Robux
		features = {
			"Go back 5 years",
			"Go back 10 years",
			"Go back 20 years",
			"Go back 30 years",
			"Restart as baby (same character)",
		},
	},
	
	BOSS_MODE = {
		id = 0, -- Replace with actual gamepass ID
		name = "Boss Mode",
		emoji = "💼",
		description = "Start your own business empire! Become a tycoon.",
		price = 399, -- Robux
		features = {
			"Start any type of business",
			"Hire and fire employees",
			"Expand to multiple locations",
			"Go public with IPO",
			"Franchise your business",
		},
	},
	
	MAFIA = {
		id = 0, -- Replace with actual gamepass ID
		name = "Organized Crime",
		emoji = "🔫",
		description = "Join the criminal underworld. Rise through the ranks of the Mafia.",
		price = 499, -- Robux
		features = {
			"Join crime families (Italian, Russian, Yakuza, Cartel, Triad)",
			"Rise from Associate to Boss",
			"Run criminal operations",
			"Territory wars",
			"Special mafia events",
		},
	},
	
	ROYALTY = {
		id = 0, -- Replace with actual gamepass ID
		name = "Royalty",
		emoji = "👸",
		description = "Be born into royalty! Live as a prince or princess.",
		price = 299, -- Robux
		features = {
			"Born as royalty (random country)",
			"Inherit the throne",
			"Royal duties and events",
			"Massive wealth",
			"Royal scandals",
		},
	},
	
	CELEBRITY = {
		id = 0, -- Replace with actual gamepass ID
		name = "Fame Package",
		emoji = "⭐",
		description = "Become a celebrity faster! Special fame careers.",
		price = 249, -- Robux
		features = {
			"Actor career path",
			"Music career path",
			"Social media influencer",
			"Professional athlete",
			"Fame events and paparazzi",
		},
	},
	
	DARK_MODE = {
		id = 0, -- Replace with actual gamepass ID
		name = "Dark Mode",
		emoji = "🌙",
		description = "Easy on the eyes! Switch to dark theme.",
		price = 49, -- Robux
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
	-- Time Machine uses (for non-gamepass owners)
	TIME_5_YEARS = {
		id = 0, -- Replace with actual product ID
		name = "Go Back 5 Years",
		emoji = "⏰",
		description = "Go back 5 years in your life",
		price = 25, -- Robux
		type = "consumable",
	},
	TIME_10_YEARS = {
		id = 0, -- Replace with actual product ID
		name = "Go Back 10 Years",
		emoji = "⏰",
		description = "Go back 10 years in your life",
		price = 45, -- Robux
		type = "consumable",
	},
	TIME_20_YEARS = {
		id = 0, -- Replace with actual product ID
		name = "Go Back 20 Years",
		emoji = "⏰",
		description = "Go back 20 years in your life",
		price = 75, -- Robux
		type = "consumable",
	},
	TIME_30_YEARS = {
		id = 0, -- Replace with actual product ID
		name = "Go Back 30 Years",
		emoji = "⏰",
		description = "Go back 30 years in your life",
		price = 99, -- Robux
		type = "consumable",
	},
	TIME_BABY = {
		id = 0, -- Replace with actual product ID
		name = "Restart as Baby",
		emoji = "👶",
		description = "Restart your life from age 0 (same character)",
		price = 125, -- Robux
		type = "consumable",
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
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- OWNERSHIP CHECKING
-- ════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════
-- DEVELOPMENT/TESTING MODE
-- Set this to true in Studio to test premium features without real gamepasses
-- CRITICAL: Set to false before publishing to production!
-- ════════════════════════════════════════════════════════════════════════════
GamepassSystem.DEV_MODE = false -- Change to true for testing in Studio

function GamepassSystem:checkOwnership(player, gamepassKey)
	local gamepass = self.Gamepasses[gamepassKey]
	if not gamepass then
		warn("[GamepassSystem] Unknown gamepass:", gamepassKey)
		return false
	end
	
	-- If ID is 0, use dev mode setting
	if gamepass.id == 0 then
		-- In dev mode, return true to allow testing premium features
		if self.DEV_MODE then
			return true
		end
		-- In production with ID 0, features are disabled
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

-- ════════════════════════════════════════════════════════════════════════════
-- PREMIUM FEATURE CHECKS
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
	-- If they own the gamepass, unlimited uses
	if self:hasTimeMachine(player) then
		return true, "gamepass"
	end
	
	-- Otherwise, they need to purchase individual uses
	return false, "purchase_required"
end

function GamepassSystem:getTimeMachineOptions()
	return {
		{ years = 5, label = "5 Years", emoji = "⏰", productKey = "TIME_5_YEARS" },
		{ years = 10, label = "10 Years", emoji = "⏰", productKey = "TIME_10_YEARS" },
		{ years = 20, label = "20 Years", emoji = "⏰", productKey = "TIME_20_YEARS" },
		{ years = 30, label = "30 Years", emoji = "⏰", productKey = "TIME_30_YEARS" },
		{ years = -1, label = "Baby", emoji = "👶", productKey = "TIME_BABY" }, -- -1 = restart
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- GOD MODE LOGIC
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:canEditStats(player)
	return self:hasGodMode(player)
end

function GamepassSystem:getEditableStats()
	return {
		{ key = "Happiness", emoji = "😊", min = 0, max = 100 },
		{ key = "Health", emoji = "❤️", min = 0, max = 100 },
		{ key = "Smarts", emoji = "🧠", min = 0, max = 100 },
		{ key = "Looks", emoji = "✨", min = 0, max = 100 },
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- MAFIA/MOB ACCESS
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:canJoinMafia(player)
	return self:hasMafia(player)
end

function GamepassSystem:getMafiaFamilies()
	return {
		{
			id = "italian",
			name = "Italian Mafia",
			emoji = "🇮🇹",
			description = "La Cosa Nostra - The traditional organized crime family",
			ranks = {"Associate", "Soldier", "Capo", "Underboss", "Boss"},
			color = Color3.fromRGB(239, 68, 68), -- Red
		},
		{
			id = "russian",
			name = "Russian Bratva",
			emoji = "🇷🇺",
			description = "The Brotherhood - Ruthless eastern European syndicate",
			ranks = {"Shestyorka", "Bratok", "Brigadier", "Avtoritet", "Pakhan"},
			color = Color3.fromRGB(59, 130, 246), -- Blue
		},
		{
			id = "yakuza",
			name = "Japanese Yakuza",
			emoji = "🇯🇵",
			description = "Honor and tradition - The way of the samurai",
			ranks = {"Shatei", "Wakashu", "Shateigashira", "Wakagashira", "Oyabun"},
			color = Color3.fromRGB(139, 92, 246), -- Purple
		},
		{
			id = "cartel",
			name = "Mexican Cartel",
			emoji = "🇲🇽",
			description = "El Cartel - Control the smuggling empire",
			ranks = {"Halcon", "Sicario", "Lugarteniente", "Capo", "Jefe"},
			color = Color3.fromRGB(34, 197, 94), -- Green
		},
		{
			id = "triad",
			name = "Chinese Triad",
			emoji = "🇨🇳",
			description = "The Heaven and Earth Society - Ancient criminal organization",
			ranks = {"Blue Lantern", "49er", "Red Pole", "Deputy", "Dragon Head"},
			color = Color3.fromRGB(249, 115, 22), -- Orange
		},
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- SERIALIZATION (for client display)
-- ════════════════════════════════════════════════════════════════════════════

function GamepassSystem:getGamepassInfo(gamepassKey)
	local gamepass = self.Gamepasses[gamepassKey]
	if not gamepass then return nil end
	
	return {
		key = gamepassKey,
		name = gamepass.name,
		emoji = gamepass.emoji,
		description = gamepass.description,
		price = gamepass.price,
		features = gamepass.features,
	}
end

function GamepassSystem:getAllGamepasses()
	local list = {}
	for key, data in pairs(self.Gamepasses) do
		table.insert(list, {
			key = key,
			name = data.name,
			emoji = data.emoji,
			description = data.description,
			price = data.price,
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

-- MINOR FIX #1: Add function to refresh gamepass cache after purchase
function GamepassSystem:refreshPlayerCache(player)
	local playerId = player.UserId
	for key, _ in pairs(self.Gamepasses) do
		local cacheKey = playerId .. "_" .. key
		self.playerOwnership[cacheKey] = nil -- Clear cache to force re-check
	end
end

-- MINOR FIX #2: Add function to clear cache when player leaves
function GamepassSystem:onPlayerRemoving(player)
	local playerId = player.UserId
	for key, _ in pairs(self.Gamepasses) do
		local cacheKey = playerId .. "_" .. key
		self.playerOwnership[cacheKey] = nil
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SINGLETON INSTANCE
-- ════════════════════════════════════════════════════════════════════════════

local instance = GamepassSystem.new()

return instance
