local LifeBackend = {}
LifeBackend.__index = LifeBackend

local GamepassSystem

function LifeBackend:checkGamepassOwnership(player, gamepassKey)
	if not player then
		return false
	end

	local success, owns = pcall(function()
		return GamepassSystem:checkOwnership(player, gamepassKey)
	end)

	if not success then
		warn(string.format("[LifeBackend] Failed to check %s ownership: %s", tostring(gamepassKey), tostring(owns)))
		return false
	end

	return owns
end

function LifeBackend:promptGamepassPurchase(player, gamepassKey)
	if not player then
		return
	end

	local success, err = pcall(function()
		GamepassSystem:promptGamepass(player, gamepassKey)
	end)

	if not success then
		warn(string.format("[LifeBackend] Failed to prompt %s purchase: %s", tostring(gamepassKey), tostring(err)))
	end
end

--[[
	LifeBackend.lua

	This module implements a stateful BitLife-style backend that powers all of the premium
	client screens in this repository. It owns the authoritative player state, surfaces
	consistent remotes under ReplicatedStorage/LifeRemotes, and generates contextual events
	for 100+ careers, activities, assets, and story paths.

	The goals of this backend are:
	1. Deterministic, career-aware events (no random unrelated popups).
	2. Scalable data-driven catalogs for jobs, activities, crimes, assets, and story paths.
	3. Minute-by-minute stat simulation so every screen can trust the values it displays.
	4. Seamless integration with the existing UI expectations (remote names, payload shapes).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local ModulesFolder = script:FindFirstChild("Modules") or script.Parent:FindFirstChild("Modules")
assert(ModulesFolder, "[LifeBackend] Missing Modules folder. Expected LifeServer/Modules.")

local LifeState = require(ModulesFolder:WaitForChild("LifeState"))
local LifeStageSystem = require(ModulesFolder:WaitForChild("LifeStageSystem"))
GamepassSystem = require(ModulesFolder:WaitForChild("GamepassSystem"))
local MobSystem = require(ModulesFolder:WaitForChild("MobSystem"))
local LifeEventsFolder = ModulesFolder:WaitForChild("LifeEvents")
local LifeEvents = require(LifeEventsFolder:WaitForChild("init"))
local EventEngine = LifeEvents.EventEngine

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #1: Load premium feature modules
-- These were defined but NEVER required, so their yearly processing never ran!
-- ════════════════════════════════════════════════════════════════════════════
local GodModeSystem = require(ModulesFolder:WaitForChild("GodModeSystem"))
local RoyaltyEvents = nil
local CelebrityEvents = nil

-- Safe require for premium event modules (they might not exist in all setups)
pcall(function()
	RoyaltyEvents = require(LifeEventsFolder:WaitForChild("RoyaltyEvents"))
end)
pcall(function()
	CelebrityEvents = require(LifeEventsFolder:WaitForChild("CelebrityEvents"))
end)

local RANDOM = Random.new()
local C = nil -- client palette not available on server

local function debugPrint(...)
	print("[LifeBackend]", ...)
end

local function clamp(value, minValue, maxValue)
	return math.clamp(value, minValue or 0, maxValue or 100)
end

local function shallowCopy(source)
	if type(source) ~= "table" then
		return source
	end
	local target = {}
	for key, value in pairs(source) do
		target[key] = value
	end
	return target
end

local function deepCopy(source, seen)
	if type(source) ~= "table" then
		return source
	end
	if seen and seen[source] then
		return seen[source]
	end
	local target = {}
	seen = seen or {}
	seen[source] = target
	for key, value in pairs(source) do
		target[deepCopy(key, seen)] = deepCopy(value, seen)
	end
	return target
end

local function chooseRandom(list)
	if #list == 0 then
		return nil
	end
	return list[RANDOM:NextInteger(1, #list)]
end

local function formatMoney(amount)
	if amount >= 1_000_000 then
		return string.format("$%.1fM", amount / 1_000_000)
	elseif amount >= 1_000 then
		return string.format("$%.1fK", amount / 1_000)
	else
		return "$" .. tostring(math.floor(amount + 0.5))
	end
end

local function countEntries(tbl)
	if type(tbl) ~= "table" then
		return 0
	end
	local count = 0
	for _ in pairs(tbl) do
		count += 1
	end
	return count
end

local function sumAssetList(list)
	if type(list) ~= "table" then
		return 0
	end
	local total = 0
	for _, asset in pairs(list) do
		if type(asset) == "table" then
			local value = asset.value or asset.price or asset.cost or asset.worth or asset.Worth
			if typeof(value) == "number" then
				total += value
			end
		elseif typeof(asset) == "number" then
			total += asset
		end
	end
	return total
end

local function computeNetWorth(state)
	local total = state.Money or 0
	local assets = state.Assets or {}
	total += sumAssetList(assets.Properties)
	total += sumAssetList(assets.Vehicles)
	total += sumAssetList(assets.Items)
	total += sumAssetList(assets.Crypto)
	total += sumAssetList(assets.Businesses)
	total += sumAssetList(assets.Investments)
	return math.max(0, total)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EDUCATION LEVEL FORMATTER - Convert internal IDs to display names
-- ═══════════════════════════════════════════════════════════════════════════════
local EducationDisplayNames = {
	none = "No Formal Education",
	elementary = "Elementary School",
	middle_school = "Middle School",
	high_school = "High School Diploma",
	highschool = "High School Diploma",
	community = "Associate's Degree",
	associate = "Associate's Degree",
	bachelor = "Bachelor's Degree",
	bachelors = "Bachelor's Degree",
	trade = "Trade School Certification",
	bootcamp = "Coding Bootcamp",
	master = "Master's Degree",
	masters = "Master's Degree",
	business = "MBA",
	law = "Law Degree (J.D.)",
	medical = "Medical Degree (M.D.)",
	doctorate = "Doctorate (Ph.D.)",
	phd = "Doctorate (Ph.D.)",
}

local function formatEducation(educationLevel)
	if not educationLevel or educationLevel == "" then
		return "No Formal Education"
	end
	return EducationDisplayNames[educationLevel:lower()] or educationLevel:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest) return first:upper()..rest:lower() end)
end

local function appendFeed(state, message)
	if not state or not message or message == "" then
		return
	end
	if state.PendingFeed and state.PendingFeed ~= "" then
		state.PendingFeed = state.PendingFeed .. " " .. message
	else
		state.PendingFeed = message
	end
end

local function safeLower(value)
	if type(value) ~= "string" then
		return ""
	end
	return string.lower(value)
end

local familyKeywords = { "mother", "father", "mom", "dad", "sister", "brother", "sibling", "grand", "son", "daughter", "child", "parent", "aunt", "uncle", "cousin" }
local romanceKeywords = { "husband", "wife", "spouse", "partner", "boyfriend", "girlfriend", "fiancé", "fiance", "lover" }

local function isFamilyRelationship(rel, relId)
	if type(rel) ~= "table" then
		return false
	end
	if rel.isFamily or rel.is_family then
		return true
	end
	local relType = safeLower(rel.type)
	if relType == "family" then
		return true
	end
	local role = safeLower(rel.role or "")
	for _, keyword in ipairs(familyKeywords) do
		if role:find(keyword, 1, true) then
			return true
		end
	end
	if relId then
		local idLower = safeLower(tostring(relId))
		for _, keyword in ipairs(familyKeywords) do
			if idLower:find(keyword, 1, true) then
				return true
			end
		end
	end
	return false
end

local function isRomanticRelationship(rel)
	if type(rel) ~= "table" then
		return false
	end
	local relType = safeLower(rel.type)
	if relType == "romance" or relType == "partner" or relType == "spouse" then
		return true
	end
	local role = safeLower(rel.role or "")
	for _, keyword in ipairs(romanceKeywords) do
		if role:find(keyword, 1, true) then
			return true
		end
	end
	return false
end

local function pruneRelationshipsForAge(state, targetAge)
	if not state or not state.Relationships then
		return
	end

	local toRemove = {}
	local shouldClearPartner = false

	for relId, rel in pairs(state.Relationships) do
		if type(rel) == "table" then
			local familyRel = isFamilyRelationship(rel, relId)
			local romanticRel = isRomanticRelationship(rel)

			if targetAge < 13 and romanticRel then
				table.insert(toRemove, relId)
				if state.Relationships.partner and state.Relationships.partner.id == rel.id then
					shouldClearPartner = true
				end
			elseif targetAge < 10 and not familyRel then
				table.insert(toRemove, relId)
			end
		end
	end

	for _, relId in ipairs(toRemove) do
		state.Relationships[relId] = nil
	end

	if shouldClearPartner or (state.Relationships.partner and state.Relationships.partner.id and not state.Relationships[state.Relationships.partner.id]) then
		state.Relationships.partner = nil
		state.Flags = state.Flags or {}
		state.Flags.has_partner = nil
		state.Flags.dating = nil
		state.Flags.married = nil
	end
end

local function resetMobStateForAge(state, targetAge)
	if not state or targetAge >= 18 then
		return
	end

	local mobState = MobSystem and MobSystem:getMobState(state) or (state.MobState or {})
	mobState.inMob = false
	mobState.familyId = nil
	mobState.familyName = nil
	mobState.familyEmoji = nil
	mobState.rankIndex = 1
	mobState.rankLevel = 1
	mobState.rankName = nil
	mobState.rankEmoji = nil
	mobState.respect = 0
	mobState.heat = 0
	mobState.loyalty = 100
	mobState.operationsCompleted = 0
	mobState.operationsFailed = 0
	mobState.earnings = 0

	state.MobState = mobState
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PERSONALITY DESCRIPTION GENERATOR - BitLife AAA Quality
-- Generates personality adjectives based on stats
-- ═══════════════════════════════════════════════════════════════════════════════
local function getPersonalityDescription(stats, flags)
	local traits = {}
	stats = stats or {}
	flags = flags or {}
	
	-- Happiness-based traits
	local happiness = stats.Happiness or 50
	if happiness >= 85 then
		table.insert(traits, "radiantly happy")
	elseif happiness >= 70 then
		table.insert(traits, "cheerful")
	elseif happiness >= 50 then
		table.insert(traits, "content")
	elseif happiness >= 30 then
		table.insert(traits, "melancholic")
	else
		table.insert(traits, "deeply unhappy")
	end
	
	-- Smarts-based traits
	local smarts = stats.Smarts or 50
	if smarts >= 90 then
		table.insert(traits, "brilliant")
	elseif smarts >= 75 then
		table.insert(traits, "intelligent")
	elseif smarts >= 50 then
		table.insert(traits, "reasonably clever")
	elseif smarts >= 30 then
		table.insert(traits, "simple-minded")
	else
		table.insert(traits, "not academically inclined")
	end
	
	-- Health-based traits
	local health = stats.Health or 50
	if health >= 85 then
		table.insert(traits, "remarkably fit")
	elseif health >= 70 then
		table.insert(traits, "healthy")
	elseif health >= 40 then
		table.insert(traits, "of average health")
	elseif health >= 20 then
		table.insert(traits, "in poor health")
	else
		table.insert(traits, "gravely ill")
	end
	
	-- Looks-based traits
	local looks = stats.Looks or 50
	if looks >= 90 then
		table.insert(traits, "stunningly attractive")
	elseif looks >= 75 then
		table.insert(traits, "good-looking")
	elseif looks >= 50 then
		table.insert(traits, "average-looking")
	elseif looks >= 30 then
		table.insert(traits, "plain")
	else
		table.insert(traits, "homely")
	end
	
	-- Flag-based personality additions
	if flags.criminal_record then table.insert(traits, "with a troubled past") end
	if flags.philanthropist then table.insert(traits, "generous") end
	if flags.famous or flags.celebrity then table.insert(traits, "famous") end
	if flags.world_champion or flags.racing_legend then table.insert(traits, "legendary") end
	if flags.retired then table.insert(traits, "retired") end
	
	return traits
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LIFESTYLE SUMMARY GENERATOR - BitLife AAA Quality
-- ═══════════════════════════════════════════════════════════════════════════════
local function getLifestyleSummary(flags)
	local lifestyles = {}
	flags = flags or {}
	
	if flags.heavy_drinker then table.insert(lifestyles, "enjoyed drinking heavily") end
	if flags.substance_issue then table.insert(lifestyles, "struggled with substance abuse") end
	if flags.fitness_enthusiast then table.insert(lifestyles, "was dedicated to fitness") end
	if flags.vegan or flags.vegetarian then table.insert(lifestyles, "followed a plant-based diet") end
	if flags.smoker then table.insert(lifestyles, "was a smoker") end
	if flags.workaholic then table.insert(lifestyles, "was a workaholic") end
	if flags.adventurous then table.insert(lifestyles, "loved adventure") end
	if flags.homebody then table.insert(lifestyles, "preferred staying home") end
	if flags.religious then table.insert(lifestyles, "was deeply religious") end
	if flags.criminal_path then table.insert(lifestyles, "walked the path of crime") end
	if flags.entrepreneur then table.insert(lifestyles, "had an entrepreneurial spirit") end
	if flags.philanthropist then table.insert(lifestyles, "was known for charitable giving") end
	
	return lifestyles
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DEATH OBITUARY GENERATOR - BitLife AAA Quality
-- Generates a full obituary-style death message
-- ═══════════════════════════════════════════════════════════════════════════════
local function generateObituary(state, deathInfo)
	local name = state.Name or "This person"
	local age = state.Age or 0
	local gender = state.Gender or "male"
	local pronoun = gender == "female" and "She" or "He"
	local possessive = gender == "female" and "her" or "his"
	
	local stats = state.Stats or {}
	local flags = state.Flags or {}
	
	local lines = {}
	
	-- Opening line with personality
	local traits = getPersonalityDescription(stats, flags)
	local traitText = ""
	if #traits >= 2 then
		traitText = traits[1] .. " and " .. traits[2]
	elseif #traits == 1 then
		traitText = traits[1]
	else
		traitText = "ordinary"
	end
	
	table.insert(lines, string.format("%s was a %s individual who passed away at age %d.", name, traitText, age))
	
	-- Cause of death
	local cause = deathInfo and deathInfo.cause or "natural causes"
	if cause == "Health failure" then
		cause = "failing health after a long struggle"
	elseif cause == "Natural causes" then
		cause = "peaceful natural causes"
	elseif cause == "Extraordinarily long life" then
		cause = "an extraordinarily long and full life"
	end
	table.insert(lines, string.format("%s died from %s.", pronoun, cause))
	
	-- Education
	local education = formatEducation(state.Education)
	if education ~= "No Formal Education" then
		table.insert(lines, string.format("%s held a %s.", pronoun, education))
	end
	
	-- Career
	if state.CurrentJob and state.CurrentJob.name then
		table.insert(lines, string.format("At the time of death, %s was working as a %s at %s.", 
			pronoun:lower(), state.CurrentJob.name, state.CurrentJob.company or "a local company"))
	elseif flags.retired then
		table.insert(lines, string.format("%s was enjoying %s retirement.", pronoun, possessive))
	elseif flags.unemployed or flags.between_jobs then
		table.insert(lines, string.format("%s was between jobs at the time.", pronoun))
	end
	
	-- Relationships
	local relationshipCount = countEntries(state.Relationships or {})
	if state.Relationships and state.Relationships.partner then
		local partner = state.Relationships.partner
		local partnerRole = partner.role or "partner"
		if flags.married then
			table.insert(lines, string.format("%s was married to %s.", pronoun, partner.name or "their spouse"))
		elseif flags.engaged then
			table.insert(lines, string.format("%s was engaged to %s.", pronoun, partner.name or "their fiancé"))
		else
			table.insert(lines, string.format("%s was in a relationship with %s.", pronoun, partner.name or "someone special"))
		end
	else
		table.insert(lines, string.format("%s was single.", pronoun))
	end
	
	-- Family count
	local familyCount = 0
	local childCount = 0
	for id, rel in pairs(state.Relationships or {}) do
		if type(rel) == "table" then
			if rel.type == "family" or rel.isFamily then
				familyCount = familyCount + 1
			end
			if rel.role and (rel.role:find("Son") or rel.role:find("Daughter") or rel.role:find("Child")) then
				childCount = childCount + 1
			end
		end
	end
	if childCount > 0 then
		table.insert(lines, string.format("%s had %d %s.", pronoun, childCount, childCount == 1 and "child" or "children"))
	end
	
	-- Lifestyle
	local lifestyles = getLifestyleSummary(flags)
	if #lifestyles > 0 then
		local lifestyleText = table.concat(lifestyles, ", ")
		table.insert(lines, string.format("Throughout life, %s %s.", pronoun:lower(), lifestyleText))
	end
	
	-- Net worth
	local netWorth = computeNetWorth(state)
	if netWorth >= 1000000000 then
		table.insert(lines, string.format("%s died a billionaire with a net worth of $%.2fB.", pronoun, netWorth / 1000000000))
	elseif netWorth >= 1000000 then
		table.insert(lines, string.format("%s died a millionaire with a net worth of $%.2fM.", pronoun, netWorth / 1000000))
	elseif netWorth >= 100000 then
		table.insert(lines, string.format("%s left behind a net worth of $%s.", pronoun, formatMoney(netWorth)))
	elseif netWorth > 0 then
		table.insert(lines, string.format("%s had modest savings of $%s.", pronoun, formatMoney(netWorth)))
	else
		table.insert(lines, string.format("%s died penniless.", pronoun))
	end
	
	-- Final stat summary
	table.insert(lines, string.format("\n📊 Final Stats: 😊 %d | ❤️ %d | 🧠 %d | 💎 %d", 
		stats.Happiness or 0, stats.Health or 0, stats.Smarts or 0, stats.Looks or 0))
	
	return table.concat(lines, "\n")
end

local function buildDeathMeta(state, deathInfo)
	local stageData = LifeStageSystem.getStage(state.Age or 0)
	local stats = state.Stats or {}
	local flags = state.Flags or {}
	
	return {
		age = state.Age,
		year = state.Year,
		cause = deathInfo and deathInfo.cause or "Unknown causes",
		causeId = deathInfo and deathInfo.id,
		stage = stageData and stageData.id or "unknown",
		stageName = stageData and stageData.name or "Unknown",
		netWorth = computeNetWorth(state),
		money = state.Money or 0,
		-- Career info
		career = state.CurrentJob and state.CurrentJob.name or (state.Career and state.Career.jobTitle),
		employer = state.CurrentJob and state.CurrentJob.company or (state.Career and state.Career.employer),
		-- Education - FIXED: Use formatted display name
		education = formatEducation(state.Education),
		educationRaw = state.Education,
		-- Stats
		happiness = stats.Happiness or 0,
		health = stats.Health or 0,
		smarts = stats.Smarts or 0,
		looks = stats.Looks or 0,
		-- Personality and lifestyle
		personality = getPersonalityDescription(stats, flags),
		lifestyle = getLifestyleSummary(flags),
		-- Family and relationships
		fame = state.Fame or 0,
		relationshipCount = countEntries(state.Relationships),
		wasMarried = flags.married or false,
		hadChildren = flags.has_children or false,
		-- Legacy flags
		wasRich = computeNetWorth(state) >= 1000000,
		wasFamous = (state.Fame or 0) >= 50,
		wasCriminal = flags.criminal_record or flags.criminal_path or false,
		-- Full obituary text
		obituary = generateObituary(state, deathInfo),
		-- Raw flags for client
		flags = shallowCopy(flags),
	}
end

-- ============================================================================
-- Job Catalog (mirrors OccupationScreen order and IDs)
-- ============================================================================

local JobCatalogList = {
	-- ENTRY LEVEL / PART-TIME (Easy to get - difficulty 1)
	{ id = "fastfood", name = "Fast Food Worker", company = "Burger Palace", emoji = "🍔", salary = 22000, minAge = 14, requirement = nil, category = "entry",
		difficulty = 1, description = "Anyone can flip burgers!" },
	{ id = "retail", name = "Retail Associate", company = "MegaMart", emoji = "🛒", salary = 26000, minAge = 16, requirement = nil, category = "entry",
		difficulty = 1, description = "Helping customers find what they need" },
	{ id = "cashier", name = "Cashier", company = "QuickMart", emoji = "💵", salary = 24000, minAge = 15, requirement = nil, category = "entry",
		difficulty = 1, description = "Ring up customers all day" },
	{ id = "bagger", name = "Grocery Bagger", company = "Fresh Foods", emoji = "🛍️", salary = 18000, minAge = 14, requirement = nil, category = "entry",
		difficulty = 1, description = "Perfect first job for teens" },
	{ id = "movie_usher", name = "Movie Usher", company = "CineMax", emoji = "🎬", salary = 20000, minAge = 14, requirement = nil, category = "entry",
		difficulty = 1, description = "Watch movies and help guests" },
	{ id = "lifeguard", name = "Lifeguard", company = "City Pool", emoji = "🏊", salary = 28000, minAge = 16, requirement = nil, category = "entry",
		difficulty = 2, minStats = { Health = 50 }, description = "Must be able to swim well" },
	{ id = "camp_counselor", name = "Camp Counselor", company = "Summer Camp", emoji = "🏕️", salary = 22000, minAge = 16, requirement = nil, category = "entry",
		difficulty = 1, description = "Fun summer job with kids" },
	{ id = "newspaper_delivery", name = "Newspaper Delivery", company = "Daily News", emoji = "📰", salary = 15000, minAge = 12, requirement = nil, category = "entry",
		difficulty = 1, description = "Early morning route delivery" },

	-- SERVICE
	{ id = "waiter", name = "Waiter/Waitress", company = "The Grand Restaurant", emoji = "🍽️", salary = 32000, minAge = 16, requirement = nil, category = "service" },
	{ id = "bartender", name = "Bartender", company = "The Tipsy Owl", emoji = "🍸", salary = 38000, minAge = 21, requirement = nil, category = "service" },
	{ id = "barista", name = "Barista", company = "Bean Scene", emoji = "☕", salary = 28000, minAge = 16, requirement = nil, category = "service" },
	{ id = "hotel_front_desk", name = "Hotel Receptionist", company = "Grand Hotel", emoji = "🏨", salary = 32000, minAge = 18, requirement = "high_school", category = "service" },
	{ id = "flight_attendant", name = "Flight Attendant", company = "SkyWays Airlines", emoji = "✈️", salary = 55000, minAge = 21, requirement = "high_school", category = "service" },
	{ id = "tour_guide", name = "Tour Guide", company = "City Tours", emoji = "🗺️", salary = 35000, minAge = 18, requirement = "high_school", category = "service" },
	{ id = "casino_dealer", name = "Casino Dealer", company = "Lucky Star Casino", emoji = "🎰", salary = 45000, minAge = 21, requirement = "high_school", category = "service" },
	{ id = "cruise_staff", name = "Cruise Ship Staff", company = "Ocean Voyages", emoji = "🚢", salary = 42000, minAge = 18, requirement = "high_school", category = "service" },
	{ id = "personal_trainer", name = "Personal Trainer", company = "FitLife Gym", emoji = "💪", salary = 48000, minAge = 18, requirement = "high_school", category = "service" },

	-- TRADES - CRITICAL FIX: Physical labor jobs now require health
	{ id = "janitor", name = "Janitor", company = "CleanCo Services", emoji = "🧹", salary = 28000, minAge = 18, requirement = nil, category = "trades",
		difficulty = 1, description = "Entry level maintenance work" },
	{ id = "construction", name = "Construction Worker", company = "BuildRight Co", emoji = "👷", salary = 42000, minAge = 18, requirement = nil, category = "trades",
		minStats = { Health = 45 }, difficulty = 2, description = "Physically demanding work" },
	{ id = "electrician_apprentice", name = "Electrician Apprentice", company = "Spark Electric", emoji = "⚡", salary = 35000, minAge = 18, requirement = "high_school", category = "trades" },
	{ id = "electrician", name = "Electrician", company = "PowerPro Electric", emoji = "⚡", salary = 62000, minAge = 22, requirement = "high_school", category = "trades" },
	{ id = "plumber_apprentice", name = "Plumber Apprentice", company = "DrainMaster", emoji = "🔧", salary = 32000, minAge = 18, requirement = "high_school", category = "trades" },
	{ id = "plumber", name = "Licensed Plumber", company = "FlowRight Plumbing", emoji = "🔧", salary = 58000, minAge = 22, requirement = "high_school", category = "trades" },
	{ id = "mechanic", name = "Auto Mechanic", company = "QuickFix Auto", emoji = "🔩", salary = 45000, minAge = 18, requirement = "high_school", category = "trades" },
	{ id = "hvac_tech", name = "HVAC Technician", company = "CoolAir Systems", emoji = "❄️", salary = 52000, minAge = 20, requirement = "high_school", category = "trades" },
	{ id = "welder", name = "Welder", company = "Steel Works Inc", emoji = "🔥", salary = 48000, minAge = 18, requirement = "high_school", category = "trades" },
	{ id = "carpenter", name = "Carpenter", company = "WoodCraft Co", emoji = "🪚", salary = 46000, minAge = 18, requirement = "high_school", category = "trades" },
	{ id = "truck_driver", name = "Truck Driver", company = "FastFreight Logistics", emoji = "🚛", salary = 55000, minAge = 21, requirement = "high_school", category = "trades" },
	{ id = "foreman", name = "Construction Foreman", company = "BuildRight Co", emoji = "🏗️", salary = 72000, minAge = 28, requirement = "high_school", category = "trades" },

	-- OFFICE
	{ id = "receptionist", name = "Receptionist", company = "Corporate Office", emoji = "📞", salary = 32000, minAge = 18, requirement = "high_school", category = "office" },
	{ id = "office_assistant", name = "Office Assistant", company = "Business Solutions", emoji = "📋", salary = 35000, minAge = 18, requirement = "high_school", category = "office" },
	{ id = "data_entry", name = "Data Entry Clerk", company = "DataCorp", emoji = "⌨️", salary = 34000, minAge = 18, requirement = "high_school", category = "office" },
	{ id = "administrative_assistant", name = "Administrative Assistant", company = "Executive Office", emoji = "📁", salary = 42000, minAge = 20, requirement = "high_school", category = "office" },
	{ id = "hr_coordinator", name = "HR Coordinator", company = "PeopleFirst HR", emoji = "👥", salary = 48000, minAge = 22, requirement = "bachelor", category = "office" },
	{ id = "hr_manager", name = "HR Manager", company = "PeopleFirst HR", emoji = "👥", salary = 78000, minAge = 28, requirement = "bachelor", category = "office" },
	{ id = "recruiter", name = "Corporate Recruiter", company = "TalentFind Inc", emoji = "🔍", salary = 58000, minAge = 24, requirement = "bachelor", category = "office" },
	{ id = "office_manager", name = "Office Manager", company = "CorpWorld Inc", emoji = "🏢", salary = 62000, minAge = 26, requirement = "bachelor", category = "office" },
	{ id = "executive_assistant", name = "Executive Assistant", company = "CEO Office", emoji = "👔", salary = 72000, minAge = 26, requirement = "bachelor", category = "office" },
	{ id = "project_manager", name = "Project Manager", company = "ManageAll Corp", emoji = "📊", salary = 85000, minAge = 28, requirement = "bachelor", category = "office" },
	{ id = "operations_director", name = "Operations Director", company = "Global Corp", emoji = "🎯", salary = 145000, minAge = 35, requirement = "master", category = "office",
		difficulty = 7, minStats = { Smarts = 65 }, description = "Executive leadership position" },
	{ id = "coo", name = "Chief Operating Officer", company = "Fortune 500", emoji = "🏆", salary = 350000, minAge = 42, requirement = "master", category = "office",
		difficulty = 9, minStats = { Smarts = 75 }, description = "C-suite requires exceptional talent" },

	-- TECHNOLOGY
	{ id = "it_support", name = "IT Support Technician", company = "TechHelp Inc", emoji = "🖥️", salary = 45000, minAge = 18, requirement = "high_school", category = "tech" },
	{ id = "junior_developer", name = "Junior Developer", company = "CodeStart Inc", emoji = "💻", salary = 65000, minAge = 21, requirement = "bachelor", category = "tech" },
	{ id = "developer", name = "Software Developer", company = "TechStart Inc", emoji = "💻", salary = 95000, minAge = 23, requirement = "bachelor", category = "tech" },
	{ id = "senior_developer", name = "Senior Developer", company = "BigTech Corp", emoji = "💻", salary = 145000, minAge = 27, requirement = "bachelor", category = "tech" },
	{ id = "tech_lead", name = "Tech Lead", company = "BigTech Corp", emoji = "👨‍💻", salary = 175000, minAge = 30, requirement = "bachelor", category = "tech" },
	{ id = "software_architect", name = "Software Architect", company = "MegaTech Inc", emoji = "🏗️", salary = 195000, minAge = 32, requirement = "master", category = "tech" },
	{ id = "web_developer", name = "Web Developer", company = "WebWorks Studio", emoji = "🌐", salary = 78000, minAge = 22, requirement = "bachelor", category = "tech" },
	{ id = "mobile_developer", name = "Mobile App Developer", company = "AppFactory", emoji = "📱", salary = 92000, minAge = 23, requirement = "bachelor", category = "tech" },
	{ id = "data_analyst", name = "Data Analyst", company = "DataDriven Co", emoji = "📈", salary = 72000, minAge = 22, requirement = "bachelor", category = "tech" },
	{ id = "data_scientist", name = "Data Scientist", company = "AI Innovations", emoji = "🧠", salary = 135000, minAge = 26, requirement = "master", category = "tech" },
	{ id = "ml_engineer", name = "Machine Learning Engineer", company = "AI Labs", emoji = "🤖", salary = 165000, minAge = 28, requirement = "master", category = "tech" },
	{ id = "cybersecurity_analyst", name = "Cybersecurity Analyst", company = "SecureNet", emoji = "🔐", salary = 95000, minAge = 24, requirement = "bachelor", category = "tech" },
	{ id = "security_engineer", name = "Security Engineer", company = "CyberShield", emoji = "🛡️", salary = 140000, minAge = 28, requirement = "bachelor", category = "tech" },
	{ id = "devops_engineer", name = "DevOps Engineer", company = "CloudOps Inc", emoji = "☁️", salary = 125000, minAge = 26, requirement = "bachelor", category = "tech" },
	{ id = "cto", name = "Chief Technology Officer", company = "Tech Giant", emoji = "🚀", salary = 380000, minAge = 38, requirement = "master", category = "tech",
		difficulty = 9, minStats = { Smarts = 80 }, description = "Lead technology strategy for entire company" },

	-- MEDICAL
	{ id = "hospital_orderly", name = "Hospital Orderly", company = "City Hospital", emoji = "🏥", salary = 28000, minAge = 18, requirement = nil, category = "medical" },
	{ id = "medical_assistant", name = "Medical Assistant", company = "Family Clinic", emoji = "💉", salary = 36000, minAge = 18, requirement = "high_school", category = "medical" },
	{ id = "emt", name = "EMT / Paramedic", company = "City Ambulance", emoji = "🚑", salary = 42000, minAge = 18, requirement = "high_school", category = "medical" },
	{ id = "nurse_lpn", name = "Licensed Practical Nurse", company = "Regional Hospital", emoji = "👩‍⚕️", salary = 52000, minAge = 20, requirement = "community", category = "medical" },
	{ id = "nurse_rn", name = "Registered Nurse", company = "City Hospital", emoji = "👩‍⚕️", salary = 78000, minAge = 22, requirement = "bachelor", category = "medical" },
	{ id = "nurse_practitioner", name = "Nurse Practitioner", company = "Medical Center", emoji = "👩‍⚕️", salary = 118000, minAge = 28, requirement = "master", category = "medical" },
	{ id = "physical_therapist", name = "Physical Therapist", company = "RehabCare Center", emoji = "🦿", salary = 92000, minAge = 26, requirement = "master", category = "medical" },
	{ id = "pharmacist", name = "Pharmacist", company = "MediPharm", emoji = "💊", salary = 128000, minAge = 28, requirement = "phd", category = "medical" },
	{ id = "dentist", name = "Dentist", company = "Bright Smiles Dental", emoji = "🦷", salary = 175000, minAge = 28, requirement = "medical", category = "medical" },
	{ id = "doctor_resident", name = "Medical Resident", company = "Teaching Hospital", emoji = "🩺", salary = 65000, minAge = 26, requirement = "medical", category = "medical" },
	{ id = "doctor", name = "Doctor", company = "City Hospital", emoji = "🩺", salary = 250000, minAge = 30, requirement = "medical", category = "medical" },
	{ id = "surgeon", name = "Surgeon", company = "Medical Center", emoji = "🔪", salary = 420000, minAge = 34, requirement = "medical", category = "medical" },
	{ id = "chief_of_medicine", name = "Chief of Medicine", company = "University Hospital", emoji = "👨‍⚕️", salary = 550000, minAge = 45, requirement = "medical", category = "medical" },
	{ id = "psychiatrist", name = "Psychiatrist", company = "Mental Health Center", emoji = "🧠", salary = 280000, minAge = 32, requirement = "medical", category = "medical" },
	{ id = "veterinarian", name = "Veterinarian", company = "Pet Care Clinic", emoji = "🐾", salary = 105000, minAge = 28, requirement = "medical", category = "medical" },

	-- LAW
	{ id = "paralegal", name = "Paralegal", company = "Legal Associates", emoji = "📜", salary = 52000, minAge = 22, requirement = "bachelor", category = "law" },
	{ id = "legal_assistant", name = "Legal Assistant", company = "Smith & Partners", emoji = "📝", salary = 42000, minAge = 18, requirement = "high_school", category = "law" },
	{ id = "associate_lawyer", name = "Associate Attorney", company = "Law Firm LLP", emoji = "⚖️", salary = 95000, minAge = 26, requirement = "law", category = "law" },
	{ id = "lawyer", name = "Attorney", company = "Smith & Associates", emoji = "⚖️", salary = 145000, minAge = 28, requirement = "law", category = "law" },
	{ id = "senior_partner", name = "Senior Partner", company = "Elite Law Firm", emoji = "⚖️", salary = 350000, minAge = 38, requirement = "law", category = "law" },
	{ id = "prosecutor", name = "Prosecutor", company = "District Attorney", emoji = "🏛️", salary = 95000, minAge = 28, requirement = "law", category = "law" },
	{ id = "public_defender", name = "Public Defender", company = "Public Defender's Office", emoji = "🏛️", salary = 72000, minAge = 26, requirement = "law", category = "law" },
	{ id = "judge", name = "Judge", company = "Superior Court", emoji = "👨‍⚖️", salary = 195000, minAge = 45, requirement = "law", category = "law" },

	-- FINANCE
	{ id = "bank_teller", name = "Bank Teller", company = "First National Bank", emoji = "🏦", salary = 34000, minAge = 18, requirement = "high_school", category = "finance" },
	{ id = "loan_officer", name = "Loan Officer", company = "City Bank", emoji = "💰", salary = 58000, minAge = 22, requirement = "bachelor", category = "finance" },
	{ id = "accountant_jr", name = "Junior Accountant", company = "Financial Services", emoji = "📊", salary = 52000, minAge = 22, requirement = "bachelor", category = "finance" },
	{ id = "accountant", name = "Senior Accountant", company = "Big4 Accounting", emoji = "📊", salary = 78000, minAge = 25, requirement = "bachelor", category = "finance" },
	{ id = "cpa", name = "Certified Public Accountant", company = "CPA Partners", emoji = "📊", salary = 95000, minAge = 28, requirement = "bachelor", category = "finance" },
	{ id = "financial_analyst", name = "Financial Analyst", company = "Investment Group", emoji = "📈", salary = 85000, minAge = 23, requirement = "bachelor", category = "finance" },
	{ id = "investment_banker_jr", name = "Investment Banking Analyst", company = "Goldman & Partners", emoji = "💹", salary = 120000, minAge = 22, requirement = "bachelor", category = "finance" },
	{ id = "investment_banker", name = "Investment Banker", company = "Wall Street Bank", emoji = "💹", salary = 225000, minAge = 28, requirement = "master", category = "finance" },
	{ id = "hedge_fund_manager", name = "Hedge Fund Manager", company = "Elite Capital", emoji = "🏦", salary = 750000, minAge = 35, requirement = "master", category = "finance" },
	{ id = "actuary", name = "Actuary", company = "Insurance Corp", emoji = "🧮", salary = 125000, minAge = 26, requirement = "bachelor", category = "finance" },
	{ id = "cfo", name = "Chief Financial Officer", company = "Fortune 500", emoji = "💼", salary = 450000, minAge = 42, requirement = "master", category = "finance",
		difficulty = 9, minStats = { Smarts = 80 }, description = "Top financial leadership position" },

	-- CREATIVE
	{ id = "graphic_designer_jr", name = "Junior Graphic Designer", company = "Design Studio", emoji = "🎨", salary = 42000, minAge = 21, requirement = "bachelor", category = "creative" },
	{ id = "graphic_designer", name = "Graphic Designer", company = "Creative Agency", emoji = "🎨", salary = 62000, minAge = 24, requirement = "bachelor", category = "creative" },
	{ id = "art_director", name = "Art Director", company = "Top Agency", emoji = "🎨", salary = 115000, minAge = 30, requirement = "bachelor", category = "creative" },
	{ id = "photographer", name = "Photographer", company = "Photo Studio", emoji = "📷", salary = 48000, minAge = 18, requirement = nil, category = "creative" },
	{ id = "videographer", name = "Videographer", company = "Video Productions", emoji = "🎥", salary = 55000, minAge = 21, requirement = "bachelor", category = "creative" },
	{ id = "journalist_jr", name = "Junior Journalist", company = "City News", emoji = "📰", salary = 38000, minAge = 22, requirement = "bachelor", category = "creative" },
	{ id = "journalist", name = "Journalist", company = "National Times", emoji = "📰", salary = 62000, minAge = 26, requirement = "bachelor", category = "creative" },
	{ id = "editor", name = "Editor", company = "Publishing House", emoji = "✍️", salary = 72000, minAge = 28, requirement = "bachelor", category = "creative" },
	{ id = "social_media_manager", name = "Social Media Manager", company = "Digital Agency", emoji = "📱", salary = 55000, minAge = 22, requirement = "bachelor", category = "creative" },
	{ id = "marketing_associate", name = "Marketing Associate", company = "AdVenture Agency", emoji = "📈", salary = 52000, minAge = 22, requirement = "bachelor", category = "creative" },
	{ id = "marketing_manager", name = "Marketing Manager", company = "Brand Corp", emoji = "📈", salary = 95000, minAge = 28, requirement = "bachelor", category = "creative" },
	{ id = "cmo", name = "Chief Marketing Officer", company = "Fortune 500", emoji = "📢", salary = 320000, minAge = 40, requirement = "master", category = "creative",
		difficulty = 8, minStats = { Smarts = 70 }, description = "Lead marketing for major corporation" },
	-- CRITICAL FIX: Creative careers need difficulty to prevent everyone becoming a star instantly
	{ id = "actor_extra", name = "Background Actor", company = "Hollywood Studios", emoji = "🎭", salary = 25000, minAge = 18, requirement = nil, category = "creative",
		difficulty = 2, minStats = { Looks = 35 }, description = "Entry point to acting career" },
	{ id = "actor", name = "Actor", company = "Talent Agency", emoji = "🎭", salary = 85000, minAge = 21, requirement = nil, category = "creative",
		difficulty = 7, minStats = { Looks = 55 }, description = "Professional acting requires talent and luck" },
	{ id = "movie_star", name = "Movie Star", company = "Major Studios", emoji = "⭐", salary = 2500000, minAge = 25, requirement = nil, category = "creative",
		difficulty = 10, minStats = { Looks = 80 }, description = "Only the most talented become stars" },
	{ id = "musician_local", name = "Local Musician", company = "Self-Employed", emoji = "🎸", salary = 28000, minAge = 16, requirement = nil, category = "creative",
		difficulty = 3, description = "Local gigs and small venues" },
	{ id = "musician_signed", name = "Signed Musician", company = "Record Label", emoji = "🎸", salary = 95000, minAge = 20, requirement = nil, category = "creative",
		difficulty = 7, description = "Record labels only sign the talented" },
	{ id = "pop_star", name = "Pop Star", company = "Global Records", emoji = "🎤", salary = 5000000, minAge = 22, requirement = nil, category = "creative",
		difficulty = 10, minStats = { Looks = 70 }, description = "World-famous musical artist" },

	-- GOVERNMENT
	{ id = "postal_worker", name = "Postal Worker", company = "US Postal Service", emoji = "📮", salary = 45000, minAge = 18, requirement = "high_school", category = "government" },
	{ id = "dmv_clerk", name = "DMV Clerk", company = "Dept of Motor Vehicles", emoji = "🚗", salary = 38000, minAge = 18, requirement = "high_school", category = "government" },
	{ id = "social_worker", name = "Social Worker", company = "Family Services", emoji = "🤝", salary = 52000, minAge = 22, requirement = "bachelor", category = "government" },
	{ id = "probation_officer", name = "Probation Officer", company = "Corrections Dept", emoji = "🔒", salary = 55000, minAge = 22, requirement = "bachelor", category = "government" },
	{ id = "police_officer", name = "Police Officer", company = "City Police Dept", emoji = "👮", salary = 62000, minAge = 21, requirement = "high_school", category = "government",
		minStats = { Health = 50 }, difficulty = 3, description = "Must pass police academy fitness test" },
	{ id = "detective", name = "Detective", company = "City Police Dept", emoji = "🔍", salary = 85000, minAge = 28, requirement = "bachelor", category = "government",
		minStats = { Smarts = 55 }, difficulty = 5, description = "Investigative skills required" },
	{ id = "police_chief", name = "Police Chief", company = "City Police Dept", emoji = "👮‍♂️", salary = 145000, minAge = 40, requirement = "bachelor", category = "government",
		minStats = { Smarts = 60 }, difficulty = 7, description = "Top law enforcement position" },
	{ id = "firefighter", name = "Firefighter", company = "Fire Department", emoji = "🚒", salary = 58000, minAge = 18, requirement = "high_school", category = "government",
		minStats = { Health = 60 }, difficulty = 3, description = "Requires physical fitness test" },
	{ id = "fire_captain", name = "Fire Captain", company = "Fire Department", emoji = "🚒", salary = 95000, minAge = 32, requirement = "high_school", category = "government",
		minStats = { Health = 55 }, difficulty = 4, description = "Leadership role requiring experience" },
	{ id = "city_council", name = "City Council Member", company = "City Government", emoji = "🏛️", salary = 72000, minAge = 25, requirement = "bachelor", category = "government" },
	{ id = "mayor", name = "Mayor", company = "City Hall", emoji = "🏛️", salary = 185000, minAge = 35, requirement = "bachelor", category = "government" },
	{ id = "fbi_agent", name = "FBI Agent", company = "Federal Bureau of Investigation", emoji = "🕵️", salary = 95000, minAge = 25, requirement = "bachelor", category = "government" },
	{ id = "cia_agent", name = "CIA Agent", company = "Central Intelligence Agency", emoji = "🕵️‍♂️", salary = 105000, minAge = 26, requirement = "bachelor", category = "government" },
	{ id = "diplomat", name = "Diplomat", company = "State Department", emoji = "🌍", salary = 125000, minAge = 30, requirement = "master", category = "government" },
	{ id = "senator", name = "Senator", company = "US Senate", emoji = "🏛️", salary = 174000, minAge = 35, requirement = "bachelor", category = "government",
		difficulty = 9, minStats = { Smarts = 60 }, description = "Elected to national legislature" },
	{ id = "president", name = "President", company = "United States", emoji = "🇺🇸", salary = 400000, minAge = 35, requirement = "bachelor", category = "government",
		difficulty = 10, minStats = { Smarts = 70 }, description = "Leader of the free world" },

	-- EDUCATION
	{ id = "teaching_assistant", name = "Teaching Assistant", company = "Local School", emoji = "📚", salary = 28000, minAge = 18, requirement = "high_school", category = "education" },
	{ id = "substitute_teacher", name = "Substitute Teacher", company = "School District", emoji = "📚", salary = 32000, minAge = 21, requirement = "bachelor", category = "education" },
	{ id = "teacher", name = "Teacher", company = "Public School", emoji = "👨‍🏫", salary = 52000, minAge = 22, requirement = "bachelor", category = "education" },
	{ id = "department_head", name = "Department Head", company = "High School", emoji = "👨‍🏫", salary = 72000, minAge = 32, requirement = "master", category = "education" },
	{ id = "principal", name = "School Principal", company = "Local School District", emoji = "🏫", salary = 105000, minAge = 38, requirement = "master", category = "education" },
	{ id = "superintendent", name = "School Superintendent", company = "School District", emoji = "🏫", salary = 185000, minAge = 45, requirement = "phd", category = "education" },
	{ id = "professor_assistant", name = "Assistant Professor", company = "State University", emoji = "🎓", salary = 72000, minAge = 28, requirement = "phd", category = "education" },
	{ id = "professor", name = "Professor", company = "University", emoji = "🎓", salary = 115000, minAge = 35, requirement = "phd", category = "education" },
	{ id = "dean", name = "Dean", company = "University", emoji = "🎓", salary = 225000, minAge = 45, requirement = "phd", category = "education" },

	-- SCIENCE
	{ id = "lab_technician", name = "Lab Technician", company = "Research Lab", emoji = "🔬", salary = 42000, minAge = 22, requirement = "bachelor", category = "science" },
	{ id = "research_assistant", name = "Research Assistant", company = "University Lab", emoji = "🔬", salary = 48000, minAge = 22, requirement = "bachelor", category = "science" },
	{ id = "scientist", name = "Scientist", company = "Research Institute", emoji = "🧪", salary = 85000, minAge = 26, requirement = "master", category = "science" },
	{ id = "senior_scientist", name = "Senior Scientist", company = "BioTech Corp", emoji = "🧪", salary = 125000, minAge = 32, requirement = "phd", category = "science" },
	{ id = "research_director", name = "Research Director", company = "Innovation Labs", emoji = "🔬", salary = 195000, minAge = 40, requirement = "phd", category = "science" },

	-- SPORTS - CRITICAL FIX: Sports careers now require actual fitness!
	{ id = "gym_instructor", name = "Gym Instructor", company = "Fitness Center", emoji = "🏋️", salary = 35000, minAge = 18, requirement = nil, category = "sports",
		minStats = { Health = 60 }, difficulty = 2, description = "Must be in excellent physical shape" },
	{ id = "minor_league", name = "Minor League Player", company = "Farm Team", emoji = "⚾", salary = 45000, minAge = 18, requirement = nil, category = "sports",
		minStats = { Health = 70 }, difficulty = 6, description = "Exceptional athletic ability required" },
	{ id = "professional_athlete", name = "Professional Athlete", company = "Sports Team", emoji = "🏆", salary = 850000, minAge = 21, requirement = nil, category = "sports",
		minStats = { Health = 80 }, difficulty = 9, description = "Elite-level athletic performance" },
	{ id = "star_athlete", name = "Star Athlete", company = "Champion Team", emoji = "⭐", salary = 15000000, minAge = 24, requirement = nil, category = "sports",
		minStats = { Health = 90 }, difficulty = 10, description = "World-class athletic ability" },
	{ id = "sports_coach", name = "Sports Coach", company = "High School", emoji = "📋", salary = 55000, minAge = 25, requirement = "bachelor", category = "sports",
		minStats = { Smarts = 45 }, difficulty = 4, description = "Teaching and athletic knowledge" },
	{ id = "head_coach", name = "Head Coach", company = "Pro Team", emoji = "📋", salary = 2500000, minAge = 40, requirement = "bachelor", category = "sports",
		minStats = { Smarts = 65 }, difficulty = 8, description = "Elite coaching position" },

	-- MILITARY - CRITICAL FIX: All military jobs now require fitness!
	{ id = "enlisted", name = "Enlisted Soldier", company = "US Army", emoji = "🪖", salary = 35000, minAge = 18, requirement = "high_school", category = "military",
		minStats = { Health = 55 }, difficulty = 3, description = "Must pass physical fitness test" },
	{ id = "sergeant", name = "Sergeant", company = "US Army", emoji = "🪖", salary = 55000, minAge = 24, requirement = "high_school", category = "military",
		minStats = { Health = 50 }, difficulty = 4, description = "Leadership and combat experience required" },
	{ id = "officer", name = "Military Officer", company = "US Armed Forces", emoji = "🎖️", salary = 75000, minAge = 22, requirement = "bachelor", category = "military",
		minStats = { Health = 50, Smarts = 50 }, difficulty = 5, description = "Requires degree and fitness" },
	{ id = "captain", name = "Captain", company = "US Armed Forces", emoji = "🎖️", salary = 95000, minAge = 28, requirement = "bachelor", category = "military",
		minStats = { Health = 45, Smarts = 55 }, difficulty = 6, description = "Advanced military leadership" },
	{ id = "colonel", name = "Colonel", company = "US Armed Forces", emoji = "🎖️", salary = 135000, minAge = 38, requirement = "master", category = "military",
		minStats = { Smarts = 60 }, difficulty = 7, description = "High command position" },
	{ id = "general", name = "General", company = "Pentagon", emoji = "⭐", salary = 220000, minAge = 50, requirement = "master", category = "military",
		minStats = { Smarts = 70 }, difficulty = 9, description = "Top military leadership" },

	-- CRIMINAL CAREERS
	{ id = "illegal_dealer_street", name = "Street Hustler", company = "The Streets", emoji = "💰", salary = 45000, minAge = 16, requirement = nil, category = "criminal", illegal = true },
	{ id = "illegal_dealer", name = "Illegal Dealer", company = "The Organization", emoji = "💰", salary = 120000, minAge = 20, requirement = nil, category = "criminal", illegal = true },
	{ id = "enforcer", name = "Enforcer", company = "Unknown", emoji = "💪", salary = 200000, minAge = 25, requirement = nil, category = "criminal", illegal = true },
	{ id = "crew_member", name = "Crew Member", company = "The Crew", emoji = "🤝", salary = 55000, minAge = 16, requirement = nil, category = "criminal", illegal = true },
	{ id = "crew_leader", name = "Crew Leader", company = "The Crew", emoji = "🔥", salary = 150000, minAge = 22, requirement = nil, category = "criminal", illegal = true },
	{ id = "crime_boss", name = "Crime Boss", company = "The Syndicate", emoji = "🎩", salary = 500000, minAge = 30, requirement = nil, category = "criminal", illegal = true },
	{ id = "smuggler", name = "Smuggler", company = "Import/Export", emoji = "📦", salary = 95000, minAge = 21, requirement = nil, category = "criminal", illegal = true },
	{ id = "fence", name = "Fence", company = "Underground Market", emoji = "💎", salary = 85000, minAge = 20, requirement = nil, category = "criminal", illegal = true },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- RACING CAREER PATH
	-- A full progression from go-karts to becoming a racing legend
	-- Requires: High Health (reflexes), starts young, danger element
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "go_kart_racer", name = "Go-Kart Racer", company = "Local Karting League", emoji = "🏎️", salary = 15000, minAge = 12, requirement = nil, category = "racing", 
		minStats = { Health = 50 }, description = "Start your racing career on the track" },
	{ id = "amateur_racer", name = "Amateur Racer", company = "Regional Racing Circuit", emoji = "🏎️", salary = 35000, minAge = 16, requirement = nil, category = "racing",
		minStats = { Health = 60 }, description = "Compete in regional amateur racing series" },
	{ id = "professional_racer", name = "Professional Racer", company = "National Racing Series", emoji = "🏁", salary = 150000, minAge = 18, requirement = nil, category = "racing",
		minStats = { Health = 70 }, description = "Race professionally on the national circuit" },
	{ id = "f1_driver", name = "Formula 1 Driver", company = "F1 Racing Team", emoji = "🏆", salary = 2500000, minAge = 21, requirement = nil, category = "racing",
		minStats = { Health = 80 }, description = "The pinnacle of motorsport" },
	{ id = "racing_legend", name = "Racing Legend", company = "Racing Hall of Fame", emoji = "👑", salary = 15000000, minAge = 28, requirement = nil, category = "racing",
		minStats = { Health = 75 }, description = "Multi-champion, legend status achieved" },
	{ id = "racing_team_owner", name = "Racing Team Owner", company = "Your Racing Team", emoji = "🏢", salary = 5000000, minAge = 35, requirement = nil, category = "racing",
		description = "Own and manage a professional racing team" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- HACKER/CYBERSECURITY CAREER PATH
	-- Two branches: White Hat (legit) or Black Hat (criminal)
	-- Requires: High Smarts, tech skills
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- Entry points (shared) - These give experience flags for higher-tier jobs
	{ id = "script_kiddie", name = "Script Kiddie", company = "The Internet", emoji = "👶💻", salary = 0, minAge = 14, requirement = nil, category = "hacker",
		minStats = { Smarts = 55 }, grantsFlags = { "coder", "tech_experience" }, description = "Learning to hack with pre-made tools" },
	{ id = "freelance_hacker", name = "Freelance Hacker", company = "Dark Web", emoji = "🖥️", salary = 60000, minAge = 18, requirement = nil, category = "hacker",
		minStats = { Smarts = 65 }, requiresFlags = { "coder", "tech_experience" }, grantsFlags = { "hacker_experience" }, description = "Taking small hacking jobs online" },
	
	-- White Hat Path (Legit Cybersecurity)
	{ id = "pen_tester", name = "Penetration Tester", company = "SecureIT Solutions", emoji = "🔓", salary = 95000, minAge = 20, requirement = "high_school", category = "tech",
		minStats = { Smarts = 70 }, description = "Legally hack companies to find vulnerabilities" },
	{ id = "security_consultant", name = "Security Consultant", company = "CyberGuard Inc", emoji = "🛡️", salary = 165000, minAge = 25, requirement = "bachelor", category = "tech",
		minStats = { Smarts = 75 }, description = "Advise companies on cybersecurity" },
	{ id = "ciso", name = "Chief Information Security Officer", company = "Fortune 500", emoji = "🔐", salary = 420000, minAge = 32, requirement = "bachelor", category = "tech",
		minStats = { Smarts = 80 }, description = "Lead security for a major corporation" },
	
	-- Black Hat Path (Criminal Hacker)
	-- CRITICAL FIX: Hacker jobs now require prior coding/tech experience!
	{ id = "black_hat_hacker", name = "Black Hat Hacker", company = "Underground", emoji = "🎭", salary = 200000, minAge = 22, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 75 }, requiresFlags = { "coder", "tech_experience" }, description = "Requires coding experience to hack" },
	{ id = "elite_hacker", name = "Elite Hacker", company = "Anonymous Collective", emoji = "👤", salary = 500000, minAge = 26, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 85 }, requiresFlags = { "hacker_experience" }, grantsFlags = { "elite_hacker_rep", "elite_hacker" }, description = "Must have proven hacking skills" },
	{ id = "cyber_crime_boss", name = "Cyber Crime Boss", company = "The Syndicate", emoji = "💀", salary = 2000000, minAge = 32, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 90 }, requiresFlags = { "elite_hacker_rep" }, grantsFlags = { "cyber_crime_history" }, description = "Must be a known elite hacker" },
	{ id = "ransomware_kingpin", name = "Ransomware Kingpin", company = "Shadow Network", emoji = "☠️", salary = 10000000, minAge = 30, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 95 }, requiresFlags = { "cyber_crime_history" }, description = "Must have cyber crime background" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- ESPORTS CAREER PATH
	-- Modern gaming career for young players
	-- ═══════════════════════════════════════════════════════════════════════════════
	{ id = "casual_gamer", name = "Casual Streamer", company = "Twitch", emoji = "🎮", salary = 5000, minAge = 13, requirement = nil, category = "esports",
		minStats = { Smarts = 40 }, description = "Stream games with a small following" },
	{ id = "content_creator", name = "Gaming Content Creator", company = "YouTube Gaming", emoji = "📹", salary = 45000, minAge = 16, requirement = nil, category = "esports",
		minStats = { Smarts = 50 }, description = "Create gaming content with growing audience" },
	{ id = "pro_gamer", name = "Pro Gamer", company = "Esports Organization", emoji = "🕹️", salary = 150000, minAge = 16, requirement = nil, category = "esports",
		minStats = { Smarts = 60 }, description = "Compete professionally in esports" },
	{ id = "esports_champion", name = "Esports Champion", company = "World Champions", emoji = "🏆", salary = 1500000, minAge = 18, requirement = nil, category = "esports",
		minStats = { Smarts = 70 }, description = "World champion esports player" },
	{ id = "gaming_legend", name = "Gaming Legend", company = "Hall of Fame", emoji = "👑", salary = 5000000, minAge = 22, requirement = nil, category = "esports",
		description = "Legendary status in gaming history" },
}

local JobCatalog = {}
for _, job in ipairs(JobCatalogList) do
	JobCatalog[job.id] = job
end

function LifeBackend:findJobByInput(query)
	if not query or query == "" then
		return nil
	end
	query = tostring(query):lower()
	if JobCatalog[query] then
		return JobCatalog[query]
	end
	for _, job in pairs(JobCatalog) do
		if job.id and job.id:lower() == query then
			return job
		end
	end
	for _, job in pairs(JobCatalog) do
		if job.name and job.name:lower():find(query, 1, true) then
			return job
		end
	end
	return nil
end

-- ════════════════════════════════════════════════════════════════════════════════════════════════
-- CAREER TRACKS - Define full career paths from entry-level to top positions
-- Each track is an ordered list where promotions move you up the list
-- ════════════════════════════════════════════════════════════════════════════════════════════════
local CareerTracks = {
	-- Office/Business path
	office = { "receptionist", "office_assistant", "data_entry", "administrative_assistant", "office_manager", "project_manager", "operations_director", "coo" },
	hr = { "hr_coordinator", "recruiter", "hr_manager" },
	
	-- Technology path
	tech_dev = { "it_support", "junior_developer", "developer", "senior_developer", "tech_lead", "software_architect", "cto" },
	tech_web = { "web_developer", "developer", "senior_developer", "tech_lead" },
	tech_mobile = { "mobile_developer", "senior_developer", "tech_lead" },
	tech_data = { "data_analyst", "data_scientist", "ml_engineer" },
	tech_security = { "cybersecurity_analyst", "security_engineer", "ciso" },
	tech_devops = { "devops_engineer", "tech_lead", "cto" },
	
	-- Medical path
	medical_nursing = { "hospital_orderly", "medical_assistant", "nurse_lpn", "nurse_rn", "nurse_practitioner" },
	medical_doctor = { "doctor_resident", "doctor", "surgeon", "chief_of_medicine" },
	medical_other = { "emt", "physical_therapist", "pharmacist", "dentist", "veterinarian", "psychiatrist" },
	
	-- Legal path
	legal = { "legal_assistant", "paralegal", "associate_lawyer", "lawyer", "senior_partner" },
	legal_gov = { "public_defender", "prosecutor", "judge" },
	
	-- Finance path
	finance_banking = { "bank_teller", "loan_officer", "accountant_jr", "accountant", "cpa", "cfo" },
	finance_invest = { "financial_analyst", "investment_banker_jr", "investment_banker", "hedge_fund_manager" },
	
	-- Creative path
	creative_design = { "graphic_designer_jr", "graphic_designer", "art_director" },
	creative_media = { "journalist_jr", "journalist", "editor" },
	creative_marketing = { "social_media_manager", "marketing_associate", "marketing_manager", "cmo" },
	creative_acting = { "actor_extra", "actor", "movie_star" },
	creative_music = { "musician_local", "musician_signed", "pop_star" },
	
	-- Government path
	gov_police = { "police_officer", "detective", "police_chief" },
	gov_fire = { "firefighter", "fire_captain" },
	gov_politics = { "city_council", "mayor", "senator", "president" },
	gov_federal = { "fbi_agent", "cia_agent", "diplomat" },
	
	-- Education path
	education_school = { "teaching_assistant", "substitute_teacher", "teacher", "department_head", "principal", "superintendent" },
	education_university = { "professor_assistant", "professor", "dean" },
	
	-- Science path
	science = { "lab_technician", "research_assistant", "scientist", "senior_scientist", "research_director" },
	
	-- Sports path
	sports_player = { "minor_league", "professional_athlete", "star_athlete" },
	sports_coach = { "gym_instructor", "sports_coach", "head_coach" },
	
	-- Military path
	military_enlisted = { "enlisted", "sergeant" },
	military_officer = { "officer", "captain", "colonel", "general" },
	
	-- Criminal path
	criminal_street = { "illegal_dealer_street", "illegal_dealer", "enforcer", "crew_leader", "crime_boss" },
	criminal_crew = { "crew_member", "crew_leader", "crime_boss" },
	
	-- Hacker paths
	hacker_whitehat = { "script_kiddie", "freelance_hacker", "pen_tester", "security_consultant", "ciso" },
	hacker_blackhat = { "script_kiddie", "freelance_hacker", "black_hat_hacker", "elite_hacker", "cyber_crime_boss", "ransomware_kingpin" },
	
	-- Racing path
	racing = { "go_kart_racer", "amateur_racer", "professional_racer", "f1_driver", "racing_legend" },
	
	-- Esports path
	esports = { "casual_gamer", "content_creator", "pro_gamer", "esports_champion", "gaming_legend" },
	
	-- Trades path
	trades_electric = { "electrician_apprentice", "electrician" },
	trades_plumb = { "plumber_apprentice", "plumber" },
	trades_construct = { "construction", "foreman" },
}

-- Direct promotion mapping for quick lookups (job -> next job)
local PromotionMap = {}
for trackName, trackJobs in pairs(CareerTracks) do
	for i = 1, #trackJobs - 1 do
		PromotionMap[trackJobs[i]] = trackJobs[i + 1]
	end
end

-- Helper function to get the next promotion for any job
local function getNextPromotionJob(jobId)
	return PromotionMap[jobId]
end

-- ============================================================================
-- Activities, Crimes, Prison Actions, and Assets
-- ============================================================================

local ActivityCatalog = {
	read = { stats = { Smarts = 5, Happiness = 2 }, feed = "read a novel", cost = 0 },
	study = { stats = { Smarts = 6 }, feed = "studied hard", cost = 0 },
	meditate = { stats = { Happiness = 5, Health = 2 }, feed = "meditated", cost = 0 },
	gym = { stats = { Health = 6, Looks = 2 }, feed = "hit the gym", cost = 0, unlockFlag = "gym_rat" },
	run = { stats = { Health = 4, Happiness = 1 }, feed = "went on a run", cost = 0 },
	yoga = { stats = { Health = 3, Happiness = 3 }, feed = "did yoga", cost = 0 },
	spa = { stats = { Happiness = 6, Looks = 3 }, feed = "enjoyed a spa day", cost = 200 },
	salon = { stats = { Looks = 4, Happiness = 2 }, feed = "visited the salon", cost = 80 },
	-- CRITICAL FIX: Driver's license activity - sets all license flags
	drivers_license = { 
		stats = { Happiness = 5, Smarts = 2 }, 
		feed = "got your driver's license!", 
		cost = 50,
		setFlags = { has_license = true, drivers_license = true, driver_license = true },
		oneTime = true, -- Can only do this once
		requiresAge = 16,
		blockedByFlag = "has_license", -- Can't get a license if you already have one
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- EDUCATION ACTIVITIES (Like BitLife!) - Go back to school, get GED, etc.
	-- ═══════════════════════════════════════════════════════════════════════════
	get_ged = {
		stats = { Smarts = 10, Happiness = 8 },
		feed = "got your GED! High school equivalent achieved!",
		cost = 150,
		requiresAge = 16,
		requiresFlag = "dropped_out_high_school",
		blockedByFlag = "has_ged",
		setFlags = { has_ged = true, has_ged_or_diploma = true },
		oneTime = true,
	},
	return_high_school = {
		stats = { Smarts = 5, Happiness = 3 },
		feed = "returned to high school to finish your education!",
		cost = 0,
		requiresAge = 14,
		maxAge = 21,
		requiresFlag = "dropped_out_high_school",
		blockedByFlag = "has_diploma",
		setFlags = { returning_student = true, in_school = true, dropped_out_high_school = nil },
		oneTime = true,
	},
	community_college = {
		stats = { Smarts = 8, Happiness = 5 },
		feed = "enrolled in community college!",
		cost = 2000,
		requiresAge = 18,
		requiresFlag = "has_ged_or_diploma",
		blockedByFlag = "in_college",
		setFlags = { in_college = true, community_college = true },
		educationProgram = "community",
		skipCompletionTracking = true,
		oneTime = true,
	},
	university = {
		stats = { Smarts = 10, Happiness = 6 },
		feed = "enrolled in university! 4-year degree program!",
		cost = 5000,
		requiresAge = 18,
		requiresFlag = "has_ged_or_diploma",
		blockedByFlag = "in_university",
		setFlags = { in_university = true, in_college = true },
		educationProgram = "bachelor",
		skipCompletionTracking = true,
		oneTime = true,
	},
	trade_school = {
		stats = { Smarts = 6, Happiness = 5 },
		feed = "enrolled in trade school! Learning practical skills!",
		cost = 3000,
		requiresAge = 18,
		setFlags = { in_trade_school = true, learning_trade = true },
		educationProgram = "trade",
		skipCompletionTracking = true,
		oneTime = true,
	},
	coding_bootcamp = {
		stats = { Smarts = 12, Happiness = 4 },
		feed = "enrolled in a coding bootcamp! Tech skills incoming!",
		cost = 8000,
		requiresAge = 18,
		setFlags = { coding_bootcamp = true, tech_skills = true },
		educationProgram = "bootcamp",
		skipCompletionTracking = true,
		oneTime = true,
	},
	medical_school = {
		stats = { Smarts = 15, Happiness = 3, Health = -5 },
		feed = "enrolled in medical school! Becoming a doctor!",
		cost = 50000,
		requiresAge = 22,
		requiresFlag = "has_degree",
		blockedByFlag = "in_med_school",
		setFlags = { in_med_school = true },
		educationProgram = "medical",
		skipCompletionTracking = true,
		oneTime = true,
	},
	law_school = {
		stats = { Smarts = 14, Happiness = 2 },
		feed = "enrolled in law school! Becoming a lawyer!",
		cost = 40000,
		requiresAge = 22,
		requiresFlag = "has_degree",
		blockedByFlag = "in_law_school",
		setFlags = { in_law_school = true },
		educationProgram = "law",
		skipCompletionTracking = true,
		oneTime = true,
	},
	business_school = {
		stats = { Smarts = 12, Happiness = 4, Money = -500 },
		feed = "enrolled in business school! Getting your MBA!",
		cost = 35000,
		requiresAge = 22,
		requiresFlag = "has_degree",
		blockedByFlag = "in_business_school",
		setFlags = { in_business_school = true },
		educationProgram = "business",
		skipCompletionTracking = true,
		oneTime = true,
	},
	
	party = { stats = { Happiness = 5 }, feed = "partied with friends", cost = 0 },
	hangout = { stats = { Happiness = 3 }, feed = "hung out with friends", cost = 0 },
	nightclub = { stats = { Happiness = 6, Health = -2 }, feed = "went clubbing", cost = 50 },
	host_party = { stats = { Happiness = 8 }, feed = "hosted a party", cost = 300 },
	tv = { stats = { Happiness = 2 }, feed = "binged a show", cost = 0 },
	games = { stats = { Happiness = 3, Smarts = 1 }, feed = "played video games", cost = 0 },
	movies = { stats = { Happiness = 3 }, feed = "watched a movie", cost = 20 },
	concert = { stats = { Happiness = 5 }, feed = "went to a concert", cost = 150 },
	vacation = { stats = { Happiness = 10, Health = 4 }, feed = "took a vacation", cost = 2000 },
	-- CRITICAL FIX: Missing activities from client (caused "Unknown activity" error)
	martial_arts = { stats = { Health = 5, Looks = 2 }, feed = "practiced martial arts", cost = 100 },
	karaoke = { stats = { Happiness = 4 }, feed = "sang karaoke", cost = 20 },
	arcade = { stats = { Happiness = 4, Smarts = 1 }, feed = "played games at the arcade", cost = 30 },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- BABY/TODDLER PLAY ACTIVITIES (Ages 0-5)
	-- ═══════════════════════════════════════════════════════════════════════════
	play_toys = { stats = { Happiness = 4 }, feed = "played with toys", cost = 0 },
	watch_cartoons = { stats = { Happiness = 3 }, feed = "watched cartoons", cost = 0 },
	play_peekaboo = { stats = { Happiness = 5 }, feed = "played peekaboo", cost = 0 },
	play_blocks = { stats = { Happiness = 3, Smarts = 2 }, feed = "played with blocks", cost = 0 },
	playground = { stats = { Happiness = 5, Health = 2 }, feed = "went to the playground", cost = 0 },
	coloring = { stats = { Happiness = 3 }, feed = "colored a picture", cost = 0 },
	play_dolls = { stats = { Happiness = 3 }, feed = "played with dolls", cost = 0 },
	bubbles = { stats = { Happiness = 4 }, feed = "blew bubbles", cost = 0 },
	nap_time = { stats = { Health = 4, Happiness = 2 }, feed = "took a nap", cost = 0 },
	play_outside = { stats = { Happiness = 4, Health = 3 }, feed = "played outside", cost = 0 },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- BABY MISCHIEF (Ages 0-4) - CRITICAL FIX: Added to server catalog
	-- ═══════════════════════════════════════════════════════════════════════════
	cry_loudly = { stats = { Happiness = 2 }, feed = "cried really loud for attention", cost = 0 },
	throw_food = { stats = { Happiness = 3 }, feed = "threw food everywhere", cost = 0 },
	break_toy = { stats = { Happiness = -1 }, feed = "broke a toy", cost = 0 },
	draw_walls = { stats = { Happiness = 4 }, feed = "drew on the walls", cost = 0 },
	refuse_nap = { stats = { Happiness = 3, Health = -1 }, feed = "refused to take a nap", cost = 0 },
	tantrum = { stats = { Happiness = -2 }, feed = "threw a tantrum", cost = 0 },
	bite_sibling = { stats = { Happiness = 1 }, feed = "bit someone", cost = 0 },
	hide_mom_keys = { stats = { Happiness = 4 }, feed = "hid mom's keys", cost = 0 },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- CHILD MISCHIEF (Ages 5-12) - CRITICAL FIX: Added to server catalog
	-- ═══════════════════════════════════════════════════════════════════════════
	skip_chores = { stats = { Happiness = 4, Smarts = -1 }, feed = "skipped chores", cost = 0 },
	prank_sibling = { stats = { Happiness = 5 }, feed = "pranked a sibling", cost = 0 },
	sneak_candy = { stats = { Happiness = 4, Health = -1 }, feed = "sneaked candy", cost = 0 },
	stay_up_late = { stats = { Happiness = 3, Health = -2 }, feed = "stayed up past bedtime", cost = 0 },
	cheat_test = { stats = { Happiness = -2 }, feed = "cheated on a test", cost = 0, setFlag = "cheater" },
	talk_back = { stats = { Happiness = 1 }, feed = "talked back to parents", cost = 0 },
	blame_sibling = { stats = { Happiness = 2 }, feed = "blamed a sibling", cost = 0 },
	fake_sick = { stats = { Happiness = 4 }, feed = "faked being sick", cost = 0 },
	toilet_paper_house = { stats = { Happiness = 5 }, feed = "toilet papered a house", cost = 0 },
	ring_doorbell_run = { stats = { Happiness = 4, Health = 1 }, feed = "played ding dong ditch", cost = 0 },
	
	-- ═══════════════════════════════════════════════════════════════════════════
	-- TEEN MISCHIEF (Ages 13-17) - CRITICAL FIX: Added to server catalog
	-- Activities have risk of getting caught with consequences
	-- ═══════════════════════════════════════════════════════════════════════════
	sneak_out = { stats = { Happiness = 6 }, feed = "snuck out at night", cost = 0, setFlag = "rebellious", 
		risk = 25, riskConsequence = "your parents caught you coming back! Grounded!", riskFlag = "grounded" },
	skip_class = { stats = { Happiness = 4, Smarts = -2 }, feed = "skipped class", cost = 0,
		risk = 30, riskConsequence = "the school called your parents!", riskFlag = "truant" },
	party_crash = { stats = { Happiness = 5 }, feed = "crashed a party", cost = 0,
		risk = 20, riskConsequence = "you got kicked out!" },
	fake_id = { stats = { Happiness = 2 }, feed = "got a fake ID", cost = 0, setFlag = "has_fake_id",
		risk = 15, riskConsequence = "the bouncer confiscated it!" },
	vandalize = { stats = { Happiness = 2 }, feed = "vandalized something", cost = 0, setFlag = "vandal",
		risk = 35, riskConsequence = "someone saw you and called the cops!", riskFlag = "criminal_record" },
	bully = { stats = { Happiness = -3 }, feed = "bullied someone", cost = 0, setFlag = "bully",
		risk = 40, riskConsequence = "a teacher witnessed it! You're in big trouble." },
	steal_parents_car = { stats = { Happiness = 6, Health = -2 }, feed = "took parents' car for a joyride", cost = 0,
		risk = 30, riskConsequence = "you crashed it! Your parents are furious.", riskFlag = "in_trouble" },
	break_curfew = { stats = { Happiness = 4 }, feed = "broke curfew", cost = 0,
		risk = 20, riskConsequence = "your parents were waiting up for you!" },
	drink_underage = { stats = { Happiness = 3, Health = -3 }, feed = "drank alcohol underage", cost = 0,
		risk = 25, riskConsequence = "you got sick and your parents found out!" },
	smoke = { stats = { Happiness = 1, Health = -4 }, feed = "tried smoking", cost = 0, setFlag = "smoker",
		risk = 20, riskConsequence = "your parents smelled it on your clothes!" },
}

local CrimeCatalog = {
	-- PETTY CRIMES (low risk)
	porch_pirate = { risk = 20, reward = { 30, 200 }, jail = { min = 0.2, max = 1 } },
	shoplift = { risk = 25, reward = { 20, 150 }, jail = { min = 0.5, max = 2 } },
	pickpocket = { risk = 35, reward = { 30, 300 }, jail = { min = 0.5, max = 2 } },
	-- PROPERTY CRIMES (medium risk)
	burglary = { risk = 50, reward = { 500, 5000 }, jail = { min = 2, max = 5 } },
	gta = { risk = 60, reward = { 2000, 20000 }, jail = { min = 3, max = 7 } },
	-- MAJOR CRIMES (high risk)
	bank_robbery = { risk = 80, reward = { 10000, 500000 }, jail = { min = 5, max = 12 } },
	-- EXPANDED CRIMES (CRITICAL FIX: Added more variety)
	tax_fraud = { risk = 35, reward = { 5000, 50000 }, jail = { min = 1, max = 5 } },
	identity_theft = { risk = 40, reward = { 1000, 20000 }, jail = { min = 2, max = 6 } },
	smuggling = { risk = 55, reward = { 500, 10000 }, jail = { min = 3, max = 10 } },
	car_theft = { risk = 50, reward = { 3000, 15000 }, jail = { min = 2, max = 5 } },
	arson = { risk = 70, reward = { 0, 1000 }, jail = { min = 5, max = 15 } },
	intimidation = { risk = 60, reward = { 2000, 30000 }, jail = { min = 3, max = 8 } },
	ransom = { risk = 85, reward = { 10000, 200000 }, jail = { min = 10, max = 25 } },
	assault = { risk = 90, reward = { 0, 5000 }, jail = { min = 20, max = 100 } },
}

local PrisonActions = {
	prison_escape = { description = "Attempt a daring escape", successStat = "Freedom" },
	-- CRITICAL FIX: Added prison_escape_failed handler (called by ActivitiesScreen minigame failure)
	prison_escape_failed = { 
		stats = { Health = -5, Happiness = -10 }, 
		feed = "got caught trying to escape", 
		jailIncrease = 2, -- Add 2 years to sentence for failed escape attempt
	},
	prison_workout = { stats = { Health = 4, Looks = 1 }, feed = "worked out in the yard" },
	prison_study = { stats = { Smarts = 4 }, feed = "studied for a GED" },
	prison_crew = { stats = { Happiness = 2, Health = -3 }, feed = "aligned with a crew", flag = "crew_member" },
	prison_riot = { stats = { Health = -10 }, feed = "started a riot", risk = 70 },
	prison_snitch = { stats = { Health = -5 }, feed = "snitched on someone", risk = 50 },
	prison_appeal = { moneyCost = 5000, feed = "filed an appeal", jailReduction = 1 },
	prison_goodbehavior = { jailReduction = 0.5, feed = "kept a low profile" },
}

local Properties = {
	{ id = "studio", name = "Studio Apartment", price = 85000, income = 500 },
	{ id = "1br_condo", name = "1BR Condo", price = 175000, income = 1000 },
	{ id = "family_house", name = "Family House", price = 350000, income = 2000 },
	{ id = "beach_house", name = "Beach House", price = 1200000, income = 5000 },
	{ id = "penthouse", name = "Luxury Penthouse", price = 2500000, income = 10000 },
	{ id = "mansion", name = "Mansion", price = 8500000, income = 25000 },
}

local Vehicles = {
	{ id = "used_civic", name = "Used Honda Civic", price = 8000 },
	{ id = "camry", name = "Toyota Camry", price = 28000 },
	{ id = "bmw", name = "BMW 3 Series", price = 55000 },
	{ id = "tesla", name = "Tesla Model S", price = 95000 },
	{ id = "porsche", name = "Porsche 911", price = 180000 },
	{ id = "lambo", name = "Lamborghini", price = 300000 },
	{ id = "ferrari", name = "Ferrari F8", price = 350000 },
	{ id = "yacht", name = "Yacht", price = 2000000 },
	{ id = "jet", name = "Private Jet", price = 15000000 },
}

local ShopItems = {
	{ id = "sneakers", name = "Sneakers", price = 350 },
	{ id = "iphone", name = "iPhone", price = 1200 },
	{ id = "bag", name = "Designer Bag", price = 2500 },
	{ id = "gaming_pc", name = "Gaming PC", price = 3000 },
	{ id = "necklace", name = "Gold Necklace", price = 3500 },
	{ id = "watch", name = "Designer Watch", price = 5000 },
	{ id = "ring", name = "Diamond Ring", price = 15000 },
	{ id = "piano", name = "Grand Piano", price = 50000 },
}

local EducationCatalog = {
	-- CRITICAL FIX: Added minAge to prevent underage enrollment
	community = { name = "Community College", cost = 15000, duration = 2, requirement = "high_school", minAge = 18 },
	bachelor = { name = "Bachelor's Degree", cost = 80000, duration = 4, requirement = "high_school", minAge = 18 },
	trade = { name = "Trade School", cost = 30000, duration = 2, requirement = "high_school", minAge = 18 },
	bootcamp = { name = "Coding Bootcamp", cost = 12000, duration = 1, requirement = "high_school", minAge = 18 },
	master = { name = "Master's Degree", cost = 60000, duration = 2, requirement = "bachelor", minAge = 22 },
	business = { name = "MBA Program", cost = 90000, duration = 2, requirement = "bachelor", minAge = 22 },
	law = { name = "Law School", cost = 150000, duration = 3, requirement = "bachelor", minAge = 22 },
	medical = { name = "Medical School", cost = 200000, duration = 4, requirement = "bachelor", minAge = 22 },
	phd = { name = "PhD Program", cost = 100000, duration = 5, requirement = "master", minAge = 24 },
}

local EducationRanks = {
	none = 0,
	high_school = 1,
	community = 2,
	trade = 2,
	bootcamp = 2,
	bachelor = 3,
	master = 4,
	business = 4,
	law = 5,
	medical = 5,
	phd = 6,
}

-- ============================================================================
-- Story Paths & Actions
-- ============================================================================

local StoryPaths = {
	political = {
		id = "political",
		name = "Political Career",
		description = "Rise from local office to the presidency.",
		color = C and C.Blue or Color3.fromRGB(59, 130, 246),
		minAge = 25,
		-- FIXED: Synced smarts requirement with StoryPathsScreen (was 65, now 70)
		requirements = { education = "bachelor", smarts = 70 },
		stages = { "local_office", "mayor", "governor", "senator", "president" },
	},
	criminal = {
		id = "criminal",
		name = "Crime Empire",
		description = "Climb the syndicate ranks.",
		color = C and C.Red or Color3.fromRGB(239, 68, 68),
		minAge = 16,
		requirements = {},
		stages = { "hustler", "operator", "lieutenant", "underboss", "boss" },
	},
	celebrity = {
		id = "celebrity",
		name = "Fame & Fortune",
		description = "Become a world-famous icon.",
		color = C and C.Amber or Color3.fromRGB(245, 158, 11),
		minAge = 14,
		requirements = { looks = 50 },
		stages = { "aspiring", "influencer", "rising_star", "celebrity", "icon" },
	},
	royal = {
		id = "royal",
		name = "Royal Dynasty",
		description = "Charm your way into royalty.",
		color = C and C.Purple or Color3.fromRGB(147, 51, 234),
		minAge = 18,
		-- FIXED: Synced looks requirement with StoryPathsScreen (was 75, now 80)
		requirements = { looks = 80, happiness = 60 },
		stages = { "commoner", "courted", "engaged", "married", "monarch" },
	},
}

local StoryPathActions = {
	political = {
		campaign = { cost = 5000, stats = { Happiness = -2 }, progress = 0.05 },
		debate = { stats = { Smarts = 2 }, progress = 0.04 },
		rally = { cost = 10000, stats = { Happiness = 4 }, progress = 0.06 },
		ad = { cost = 50000, progress = 0.1 },
		scandal = { risk = 40, stats = { Happiness = -6 }, progress = -0.08 },
	},
	criminal = {
		recruit = { stats = { Happiness = 2 }, progress = 0.05 },
		territory = { risk = 45, progress = 0.08 },
		heist = { risk = 60, reward = { 5000, 100000 }, progress = 0.1 },
		bribe = { cost = 25000, progress = 0.05 },
		war = { risk = 80, stats = { Health = -10 }, progress = 0.12 },
	},
	celebrity = {
		post = { stats = { Happiness = 2 }, progress = 0.04 },
		collab = { stats = { Happiness = 3 }, progress = 0.05 },
		interview = { stats = { Happiness = 4 }, progress = 0.06 },
		scandal = { risk = 30, progress = 0.07 },
		charity = { cost = 10000, stats = { Happiness = 5 }, progress = 0.08 },
	},
	royal = {
		charm = { stats = { Happiness = 3 }, progress = 0.04 },
		etiquette = { stats = { Smarts = 2 }, progress = 0.05 },
		intrigue = { risk = 50, progress = 0.08 },
		heir = { stats = { Happiness = 6 }, progress = 0.1 },
		decree = { stats = { Happiness = -2 }, progress = 0.06 },
	},
}

-- ════════════════════════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: MOVE CAREER EVENT TABLES BEFORE THE FUNCTION THAT USES THEM
-- In Lua, local variables must be defined BEFORE they are referenced!
-- ════════════════════════════════════════════════════════════════════════════════════════════════

local PoliceCareerEvents = {
	{
		id = "police_patrol",
		title = "Suspicious Van",
		emoji = "🚓",
		text = "During a late-night patrol you spot a dark van idling behind a closed electronics store.",
		question = "How do you handle it?",
		choices = {
			{ text = "Call for backup and box them in", deltas = { Happiness = -1 }, setFlags = { police_cautious = true }, feedText = "You waited for backup and safely arrested the crew." },
			{ text = "Approach alone with confidence", deltas = { Health = -5, Happiness = 3 }, setFlags = { police_hero = true }, feedText = "You confronted the suspects solo and earned respect." },
			{ text = "Let it slide", deltas = { Happiness = -3 }, setFlags = { police_corrupt = true }, feedText = "You pretended not to notice the van." },
		},
	},
	{
		id = "police_bribe",
		title = "Traffic Stop Temptation",
		emoji = "🚔",
		text = "You pull over a wealthy executive who quietly offers an envelope to forget about the speeding.",
		question = "Take the envelope?",
		choices = {
			{ text = "Refuse and write the ticket", deltas = { Happiness = 2 }, setFlags = { police_reputable = true }, feedText = "You refused the bribe and wrote the ticket." },
			{ text = "Accept the cash", deltas = { Money = 2500, Happiness = 1 }, setFlags = { police_corrupt = true }, feedText = "You pocketed the envelope. Internal Affairs is now curious." },
		},
	},
	{
		id = "police_riot",
		title = "Crowd Control",
		emoji = "🛡️",
		text = "A protest turns heated. Barricades are shaking and the crowd is chanting your name.",
		question = "What tactic do you try?",
		choices = {
			{ text = "Defuse with calm orders", deltas = { Happiness = 3 }, setFlags = { police_mediator = true }, feedText = "You kept things calm and prevented violence." },
			{ text = "Charge the line", deltas = { Health = -10, Happiness = -2 }, setFlags = { police_hero = true }, feedText = "You pushed the line back but took some hits." },
			{ text = "Wait for SWAT", deltas = { Happiness = -1 }, setFlags = { police_cautious = true }, feedText = "You held position until SWAT arrived." },
		},
	},
}

local TechCareerEvents = {
	{
		id = "tech_deadline",
		title = "Crunch Time",
		emoji = "💻",
		text = "Your team's deadline is tomorrow and the code is still buggy. Your manager wants you to push anyway.",
		question = "What do you do?",
		choices = {
			{ text = "Push the buggy code", deltas = { Happiness = -2 }, setFlags = { tech_rushed = true }, feedText = "You shipped buggy code. Users are complaining." },
			{ text = "Stay late and fix it", deltas = { Health = -3, Happiness = 2, Smarts = 2 }, setFlags = { tech_dedicated = true }, feedText = "You pulled an all-nighter and shipped clean code." },
			{ text = "Request extension", deltas = { Happiness = 1 }, setFlags = { tech_realistic = true }, feedText = "You negotiated a 3-day extension." },
		},
	},
	{
		id = "tech_interview",
		title = "Job Offer",
		emoji = "🚀",
		text = "A competitor reaches out with a job offer paying 40% more than your current salary.",
		question = "How do you respond?",
		choices = {
			{ text = "Accept the offer", deltas = { Money = 15000, Happiness = 3 }, setFlags = { tech_job_hopper = true }, feedText = "You jumped ship for more money." },
			{ text = "Use it to negotiate a raise", deltas = { Money = 5000, Happiness = 2 }, feedText = "You leveraged the offer into a counter-offer." },
			{ text = "Decline and stay loyal", deltas = { Happiness = 1 }, setFlags = { tech_loyal = true }, feedText = "You stayed put for now." },
		},
	},
	{
		id = "tech_security",
		title = "Security Breach",
		emoji = "🔐",
		text = "You discover a critical security vulnerability in production code. Fixing it will delay the release.",
		question = "What's your move?",
		choices = {
			{ text = "Report it immediately", deltas = { Happiness = 2, Smarts = 3 }, setFlags = { tech_ethical = true }, feedText = "You reported the vulnerability and prevented a breach." },
			{ text = "Fix it quietly", deltas = { Smarts = 2 }, feedText = "You patched it without telling anyone." },
			{ text = "Ignore it for now", deltas = { Happiness = -5 }, setFlags = { tech_negligent = true }, feedText = "The vulnerability was exploited weeks later." },
		},
	},
}

local MedicalCareerEvents = {
	{
		id = "medical_emergency",
		title = "Code Blue",
		emoji = "🚑",
		text = "A patient flatlines during your shift. You're the closest medical staff.",
		question = "What do you do?",
		choices = {
			{ text = "Start CPR immediately", deltas = { Health = -2, Happiness = 4 }, setFlags = { medical_hero = true }, feedText = "You saved a life with quick action." },
			{ text = "Call for the crash team", deltas = { Happiness = 1 }, feedText = "You followed protocol and got help." },
			{ text = "Freeze up", deltas = { Happiness = -5, Health = -3 }, setFlags = { medical_anxious = true }, feedText = "You froze and the patient died." },
		},
	},
	{
		id = "medical_ethics",
		title = "Ethical Dilemma",
		emoji = "⚕️",
		text = "A wealthy patient offers you $50,000 to skip them ahead in the transplant list.",
		question = "What do you say?",
		choices = {
			{ text = "Refuse firmly", deltas = { Happiness = 3 }, setFlags = { medical_ethical = true }, feedText = "You refused the bribe and reported the incident." },
			{ text = "Accept the money", deltas = { Money = 50000, Happiness = -2 }, setFlags = { medical_corrupt = true }, feedText = "You took the bribe. Your conscience weighs heavy." },
		},
	},
	{
		id = "medical_mistake",
		title = "Medical Error",
		emoji = "💊",
		text = "You realize you prescribed the wrong dosage to a patient yesterday. They haven't taken it yet.",
		question = "How do you handle it?",
		choices = {
			{ text = "Call them immediately", deltas = { Happiness = 2, Smarts = 2 }, setFlags = { medical_responsible = true }, feedText = "You caught the error in time and fixed it." },
			{ text = "Quietly fix it in the system", deltas = { Happiness = -1 }, feedText = "You corrected the record without telling anyone." },
			{ text = "Hope they don't notice", deltas = { Happiness = -10 }, setFlags = { medical_negligent = true }, feedText = "The patient had a reaction and sued the hospital." },
		},
	},
}

local OfficeCareerEvents = {
	{
		id = "office_credit",
		title = "Stolen Credit",
		emoji = "📊",
		text = "Your manager presents YOUR project to executives as their own idea.",
		question = "What do you do?",
		choices = {
			{ text = "Confront them privately", deltas = { Happiness = 2 }, setFlags = { office_assertive = true }, feedText = "You addressed the issue directly." },
			{ text = "Email the executives with proof", deltas = { Happiness = 3 }, setFlags = { office_bold = true }, feedText = "You exposed the credit theft." },
			{ text = "Let it slide", deltas = { Happiness = -3 }, setFlags = { office_pushover = true }, feedText = "You let your work be stolen." },
		},
	},
	{
		id = "office_gossip",
		title = "Office Gossip",
		emoji = "💬",
		text = "Coworkers are spreading rumors about a colleague's personal life. They want you to join in.",
		question = "What do you do?",
		choices = {
			{ text = "Refuse to participate", deltas = { Happiness = 2 }, setFlags = { office_professional = true }, feedText = "You stayed above the gossip." },
			{ text = "Join the conversation", deltas = { Happiness = 1 }, setFlags = { office_gossiper = true }, feedText = "You participated in the gossip." },
			{ text = "Defend the colleague", deltas = { Happiness = 3 }, setFlags = { office_defender = true }, feedText = "You stood up for your colleague." },
		},
	},
	{
		id = "office_overwork",
		title = "Weekend Work",
		emoji = "🏢",
		text = "Your boss asks you to work this weekend. Again. You have family plans.",
		question = "What do you say?",
		choices = {
			{ text = "Work the weekend", deltas = { Happiness = -4, Money = 200 }, setFlags = { office_workaholic = true }, feedText = "You cancelled plans to work." },
			{ text = "Politely decline", deltas = { Happiness = 3 }, setFlags = { office_boundaries = true }, feedText = "You set healthy boundaries." },
			{ text = "Negotiate half day", deltas = { Happiness = 1, Money = 100 }, feedText = "You compromised on a half day." },
		},
	},
}

local FinanceCareerEvents = {
	{
		id = "finance_insider",
		title = "Insider Trading Tip",
		emoji = "💹",
		text = "A client accidentally shares material non-public information about an upcoming merger.",
		question = "What do you do?",
		choices = {
			{ text = "Report to compliance", deltas = { Happiness = 3 }, setFlags = { finance_ethical = true }, feedText = "You reported the potential violation." },
			{ text = "Trade on the info", deltas = { Money = 50000, Happiness = -2 }, setFlags = { finance_insider_trader = true }, feedText = "You made an illegal trade." },
			{ text = "Pretend you didn't hear", deltas = { Happiness = -1 }, feedText = "You ignored the information." },
		},
	},
	{
		id = "finance_market_crash",
		title = "Market Chaos",
		emoji = "📉",
		text = "The market is crashing. Your clients are panicking and calling non-stop.",
		question = "How do you handle it?",
		choices = {
			{ text = "Calm them down, advise holding", deltas = { Happiness = 2, Smarts = 2 }, setFlags = { finance_steady = true }, feedText = "You kept clients calm during the chaos." },
			{ text = "Sell everything", deltas = { Happiness = -3 }, setFlags = { finance_panic = true }, feedText = "You panic-sold at the bottom." },
			{ text = "Go dark and hide", deltas = { Happiness = -5 }, setFlags = { finance_coward = true }, feedText = "You avoided all calls and lost clients." },
		},
	},
	{
		id = "finance_bonus",
		title = "Bonus Season",
		emoji = "💰",
		text = "Bonuses are announced. Yours is lower than expected, while a less qualified colleague got more.",
		question = "What do you do?",
		choices = {
			{ text = "Negotiate with your boss", deltas = { Money = 5000, Happiness = 2 }, feedText = "You negotiated a bonus adjustment." },
			{ text = "Accept it quietly", deltas = { Happiness = -2 }, feedText = "You accepted the lower bonus." },
			{ text = "Start job hunting", deltas = { Happiness = 1 }, setFlags = { finance_looking = true }, feedText = "You started looking for new opportunities." },
		},
	},
}

function LifeBackend:buildCareerEvent(state)
	local job = state and state.CurrentJob
	if not job or not job.id then
		return nil
	end
	local jobId = string.lower(job.id)
	local jobCategory = (job.category and string.lower(job.category)) or ""
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #8: Career events for different job categories
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	local eventPool = nil
	local eventSource = nil
	
	-- Police/Detective events
	if jobId:find("police") or jobId:find("detective") or jobId:find("fbi") or jobId:find("cia") then
		eventPool = PoliceCareerEvents
		eventSource = "career_police"
	-- Tech events
	elseif jobCategory == "tech" or jobId:find("developer") or jobId:find("engineer") or jobId:find("cto") then
		eventPool = TechCareerEvents
		eventSource = "career_tech"
	-- Medical events
	elseif jobCategory == "medical" or jobId:find("doctor") or jobId:find("nurse") or jobId:find("surgeon") then
		eventPool = MedicalCareerEvents
		eventSource = "career_medical"
	-- Office events
	elseif jobCategory == "office" or jobId:find("manager") or jobId:find("coo") or jobId:find("director") then
		eventPool = OfficeCareerEvents
		eventSource = "career_office"
	-- Finance events
	elseif jobCategory == "finance" or jobId:find("banker") or jobId:find("accountant") or jobId:find("cfo") then
		eventPool = FinanceCareerEvents
		eventSource = "career_finance"
	end
	
	if not eventPool or #eventPool == 0 then
		return nil
	end
	
	local template = chooseRandom(eventPool)
	if not template then
		return nil
	end
	
	local eventDef = deepCopy(template)
	eventDef.id = template.id .. "_" .. tostring(RANDOM:NextInteger(1000, 999999))
	eventDef.source = eventSource
	return eventDef
end

-- ============================================================================
-- Event Catalog (contextual story events, per category)
-- ============================================================================

local EventCatalog = {
	childhood = {
		{
			id = "child_schoolyard",
			title = "Schoolyard Antics",
			emoji = "🎒",
			text = "A bully keeps bothering you during recess.",
			question = "How do you respond?",
			choices = {
				{ text = "Tell a teacher", deltas = { Happiness = -2, Smarts = 2 }, flags = { brave = true }, feed = "stood up for yourself at school." },
				{ text = "Stand up to them", deltas = { Health = -1, Happiness = 3 }, feed = "confronted a bully and earned respect." },
				{ text = "Ignore it", deltas = { Happiness = -3 }, feed = "kept your head down at recess." },
			},
		},
		{
			id = "child_sickday",
			title = "Sick Day",
			emoji = "🤒",
			text = "You wake up feeling awful before an exam.",
			question = "What will you do?",
			choices = {
				{ text = "Stay home", deltas = { Health = 4, Smarts = -2 }, feed = "rested at home instead of taking a test." },
				{ text = "Push through", deltas = { Health = -3, Smarts = 2 }, feed = "toughed out an exam while sick." },
			},
		},
	},
	teen = {
		{
			id = "teen_exam",
			title = "Entrance Exam",
			emoji = "📚",
			text = "A prestigious school invites you to take a difficult entrance exam.",
			question = "Do you cram or wing it?",
			choices = {
				{ text = "Study all night", deltas = { Smarts = 4, Health = -2 }, feed = "studied past midnight for an exam." },
				{ text = "Trust your instincts", deltas = { Smarts = 1, Happiness = 2 }, feed = "trusted your instincts on a big exam." },
			},
		},
		{
			id = "teen_party",
			title = "House Party Invite",
			emoji = "🥳",
			text = "Friends invite you to a rowdy party the night before SAT prep.",
			question = "What's the move?",
			choices = {
				{ text = "Stay in and study", deltas = { Smarts = 3, Happiness = -2 }, feed = "skipped a party to study." },
				{ text = "Go anyway", deltas = { Happiness = 4, Smarts = -2 }, feed = "went to a party and memories were made." },
			},
		},
	},
	career_medical = {
		{
			id = "med_shift",
			title = "Chaotic ER Shift",
			emoji = "🏥",
			text = "Three critical patients arrive simultaneously during your ER shift.",
			question = "How do you triage?",
			choices = {
				{ text = "Lead decisively", deltas = { Happiness = -4 }, career = { performance = 8, progress = 6 }, feed = "took charge during a chaotic ER shift." },
				{ text = "Call for help", deltas = { Happiness = -1 }, career = { performance = 4 }, feed = "coordinated with colleagues on a hectic shift." },
			},
		},
		{
			id = "med_mistake",
			title = "Charting Mistake",
			emoji = "🩺",
			text = "You realize a colleague charted the wrong dosage on a patient record.",
			question = "Do you speak up?",
			choices = {
				{ text = "Correct it quietly", deltas = { Smarts = 2 }, career = { performance = 4 }, feed = "caught a dosage error before it was too late." },
				{ text = "Report it formally", deltas = { Happiness = -2 }, career = { performance = 6 }, feed = "reported a medication error to supervisors." },
			},
		},
	},
	career_tech = {
		{
			id = "tech_outage",
			title = "Production Outage",
			emoji = "💻",
			text = "A massive outage hits your product minutes before launch.",
			question = "How do you respond?",
			choices = {
				{ text = "Lead the war room", deltas = { Happiness = -3 }, career = { performance = 7, progress = 5 }, feed = "led the response to a critical outage." },
				{ text = "Patch quietly", deltas = { Smarts = 2 }, career = { performance = 4 }, feed = "froze feature rollout to stabilize prod." },
			},
		},
		{
			id = "tech_opportunity",
			title = "Side Project Buzz",
			emoji = "🚀",
			text = "Your side project gains traction online.",
			question = "Focus on the day job or chase the hype?",
			choices = {
				{ text = "Stay loyal", deltas = { Happiness = -1 }, career = { performance = 3 }, feed = "stayed focused on your employer despite side buzz." },
				{ text = "Pitch it internally", deltas = { Happiness = 2 }, career = { progress = 4 }, feed = "pitched your side project to leadership." },
			},
		},
	},
	career_creative = {
		{
			id = "creative_brief",
			title = "Impossible Brief",
			emoji = "🎨",
			text = "A client wants a full rebrand in two days.",
			question = "What do you propose?",
			choices = {
				{ text = "Push back", deltas = { Happiness = -1 }, career = { performance = 3 }, feed = "stood firm on creative timelines." },
				{ text = "Pull an all-nighter", deltas = { Health = -4, Happiness = 3 }, career = { performance = 5 }, feed = "burned the midnight oil for a demanding client." },
			},
		},
	},
	romance = {
		{
			id = "romance_conflict",
			title = "Heart-to-Heart",
			emoji = "💞",
			text = "Your partner feels neglected during your grind.",
			question = "How do you address it?",
			choices = {
				{ text = "Plan a surprise date", deltas = { Happiness = 4 }, relationships = { delta = 8 }, cost = 200, feed = "put career aside for a surprise date night." },
				{ text = "Explain the hustle", deltas = { Happiness = -1 }, relationships = { delta = 3 }, feed = "had a difficult talk about priorities." },
			},
		},
	},
	crime = {
		{
			id = "crime_dilemma",
			title = "Risky Opportunity",
			emoji = "🕶️",
			text = "An underboss offers you a high-stakes job.",
			question = "Take the gig?",
			choices = {
				{ text = "Take the job", deltas = { Happiness = 3 }, crime = { reward = { 20000, 80000 }, riskBonus = 15 }, feed = "accepted a lucrative, dangerous contract." },
				{ text = "Lay low", deltas = { Happiness = -2 }, feed = "kept a low profile despite pressure." },
			},
		},
	},
	general = {
		{
			id = "general_raise",
			title = "Unexpected Raise",
			emoji = "💰",
			text = "Your manager offers a modest raise if you take on extra responsibilities.",
			question = "Accept?",
			choices = {
				{ text = "Accept", deltas = { Happiness = 2 }, career = { salaryBonus = 0.05 }, feed = "took on extra responsibilities for a raise." },
				{ text = "Decline politely", deltas = { Happiness = -1 }, feed = "protected your work-life balance." },
			},
		},
		{
			id = "general_volunteer",
			title = "Volunteer Day",
			emoji = "🤝",
			text = "Your company sponsors a volunteer event at a local shelter.",
			question = "Do you sign up?",
			choices = {
				{ text = "Absolutely", deltas = { Happiness = 4 }, feed = "volunteered at a community shelter." },
				{ text = "Skip it", deltas = { Happiness = -1 }, feed = "skipped volunteer day to rest." },
			},
		},
	},
}

local function flattenEventPools(triggers)
	local pool = {}
	for _, trigger in ipairs(triggers) do
		local bucket = EventCatalog[trigger]
		if bucket then
			for _, item in ipairs(bucket) do
				table.insert(pool, item)
			end
		end
	end
	if #pool == 0 then
		for _, item in ipairs(EventCatalog.general) do
			table.insert(pool, item)
		end
	end
	return pool
end

-- ============================================================================
-- LifeBackend object construction
-- ============================================================================

function LifeBackend.new()
	local self = setmetatable({}, LifeBackend)
	self.playerStates = {}
	self.pendingEvents = {}
	self.remoteFolder = nil
	self.remotes = {}
	return self
end

-- Remote creation helpers ----------------------------------------------------

function LifeBackend:createRemote(name, className)
	local remote = self.remoteFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = self.remoteFolder
	end
	return remote
end

function LifeBackend:setupRemotes()
	self.remoteFolder = ReplicatedStorage:FindFirstChild("LifeRemotes")
	if not self.remoteFolder then
		self.remoteFolder = Instance.new("Folder")
		self.remoteFolder.Name = "LifeRemotes"
		self.remoteFolder.Parent = ReplicatedStorage
	end

	self.remotes.RequestAgeUp = self:createRemote("RequestAgeUp", "RemoteEvent")
	self.remotes.SyncState = self:createRemote("SyncState", "RemoteEvent")
	self.remotes.PresentEvent = self:createRemote("PresentEvent", "RemoteEvent")
	self.remotes.SubmitChoice = self:createRemote("SubmitChoice", "RemoteEvent")
	self.remotes.SetLifeInfo = self:createRemote("SetLifeInfo", "RemoteEvent")
	self.remotes.MinigameResult = self:createRemote("MinigameResult", "RemoteEvent")
	self.remotes.MinigameStart = self:createRemote("MinigameStart", "RemoteEvent")

	self.remotes.DoActivity = self:createRemote("DoActivity", "RemoteFunction")
	self.remotes.CommitCrime = self:createRemote("CommitCrime", "RemoteFunction")
	self.remotes.DoPrisonAction = self:createRemote("DoPrisonAction", "RemoteFunction")

	self.remotes.ApplyForJob = self:createRemote("ApplyForJob", "RemoteFunction")
	self.remotes.QuitJob = self:createRemote("QuitJob", "RemoteFunction")
	self.remotes.DoWork = self:createRemote("DoWork", "RemoteFunction")
	self.remotes.RequestPromotion = self:createRemote("RequestPromotion", "RemoteFunction")
	self.remotes.RequestRaise = self:createRemote("RequestRaise", "RemoteFunction")
	self.remotes.GetCareerInfo = self:createRemote("GetCareerInfo", "RemoteFunction")
	self.remotes.GetEducationInfo = self:createRemote("GetEducationInfo", "RemoteFunction")
	self.remotes.EnrollEducation = self:createRemote("EnrollEducation", "RemoteFunction")

	self.remotes.BuyProperty = self:createRemote("BuyProperty", "RemoteFunction")
	self.remotes.BuyVehicle = self:createRemote("BuyVehicle", "RemoteFunction")
	self.remotes.BuyItem = self:createRemote("BuyItem", "RemoteFunction")
	self.remotes.SellAsset = self:createRemote("SellAsset", "RemoteFunction")
	self.remotes.Gamble = self:createRemote("Gamble", "RemoteFunction")

	self.remotes.DoInteraction = self:createRemote("DoInteraction", "RemoteFunction")

	self.remotes.StartPath = self:createRemote("StartPath", "RemoteFunction")
	self.remotes.DoPathAction = self:createRemote("DoPathAction", "RemoteFunction")
	self.remotes.ResetLife = self:createRemote("ResetLife", "RemoteEvent")
	
	-- PREMIUM FEATURES: Organized Crime remotes
	self.remotes.JoinMob = self:createRemote("JoinMob", "RemoteFunction")
	self.remotes.LeaveMob = self:createRemote("LeaveMob", "RemoteFunction")
	self.remotes.DoMobOperation = self:createRemote("DoMobOperation", "RemoteFunction")
	self.remotes.CheckGamepass = self:createRemote("CheckGamepass", "RemoteFunction")
	self.remotes.PromptGamepass = self:createRemote("PromptGamepass", "RemoteEvent")
	self.remotes.UseTimeMachine = self:createRemote("UseTimeMachine", "RemoteFunction")
	self.remotes.GodModeEdit = self:createRemote("GodModeEdit", "RemoteFunction")
	
	-- CRITICAL FIX #13: PREMIUM FEATURES: Royalty remotes
	self.remotes.DoRoyalDuty = self:createRemote("DoRoyalDuty", "RemoteFunction")
	self.remotes.Abdicate = self:createRemote("Abdicate", "RemoteFunction")
	self.remotes.GetRoyalInfo = self:createRemote("GetRoyalInfo", "RemoteFunction")

	-- Event connections
	self.remotes.RequestAgeUp.OnServerEvent:Connect(function(player)
		self:handleAgeUp(player)
	end)

	self.remotes.SetLifeInfo.OnServerEvent:Connect(function(player, name, gender)
		self:setLifeInfo(player, name, gender)
	end)

	self.remotes.SubmitChoice.OnServerEvent:Connect(function(player, eventId, choiceIndex)
		self:resolvePendingEvent(player, eventId, choiceIndex)
	end)

	self.remotes.MinigameResult.OnServerEvent:Connect(function(player, won, payload)
		self:handleMinigameResult(player, won, payload)
	end)

	self.remotes.DoActivity.OnServerInvoke = function(player, activityId, bonus)
		return self:handleActivity(player, activityId, bonus)
	end
	self.remotes.CommitCrime.OnServerInvoke = function(player, crimeId, minigameBonus)
		return self:handleCrime(player, crimeId, minigameBonus)
	end
	self.remotes.DoPrisonAction.OnServerInvoke = function(player, actionId)
		return self:handlePrisonAction(player, actionId)
	end

	self.remotes.ApplyForJob.OnServerInvoke = function(player, jobId)
		return self:handleJobApplication(player, jobId)
	end
	self.remotes.QuitJob.OnServerInvoke = function(player, quitStyle)
		return self:handleQuitJob(player, quitStyle)
	end
	self.remotes.DoWork.OnServerInvoke = function(player)
		return self:handleWork(player)
	end
	self.remotes.RequestPromotion.OnServerInvoke = function(player)
		return self:handlePromotion(player)
	end
	self.remotes.RequestRaise.OnServerInvoke = function(player)
		return self:handleRaise(player)
	end
	self.remotes.GetCareerInfo.OnServerInvoke = function(player)
		return self:getCareerInfo(player)
	end

	self.remotes.GetEducationInfo.OnServerInvoke = function(player)
		return self:getEducationInfo(player)
	end
	self.remotes.EnrollEducation.OnServerInvoke = function(player, programId)
		return self:enrollEducation(player, programId)
	end

	self.remotes.BuyProperty.OnServerInvoke = function(player, assetId)
		return self:handleAssetPurchase(player, "Properties", Properties, assetId)
	end
	self.remotes.BuyVehicle.OnServerInvoke = function(player, assetId)
		return self:handleAssetPurchase(player, "Vehicles", Vehicles, assetId)
	end
	self.remotes.BuyItem.OnServerInvoke = function(player, assetId)
		return self:handleAssetPurchase(player, "Items", ShopItems, assetId)
	end
	self.remotes.SellAsset.OnServerInvoke = function(player, assetId, assetType)
		return self:handleAssetSale(player, assetId, assetType)
	end
	self.remotes.Gamble.OnServerInvoke = function(player, betAmount, finalSymbols)
		return self:handleGamble(player, betAmount, finalSymbols)
	end

	self.remotes.DoInteraction.OnServerInvoke = function(player, payload)
		return self:handleInteraction(player, payload)
	end

	self.remotes.StartPath.OnServerInvoke = function(player, pathId)
		return self:startStoryPath(player, pathId)
	end
	self.remotes.DoPathAction.OnServerInvoke = function(player, pathId, actionId)
		return self:performPathAction(player, pathId, actionId)
	end

	self.remotes.ResetLife.OnServerEvent:Connect(function(player)
		self:resetLife(player)
	end)
	
	-- PREMIUM FEATURES: Organized Crime handlers
	self.remotes.JoinMob.OnServerInvoke = function(player, familyId)
		return self:handleJoinMob(player, familyId)
	end
	
	self.remotes.LeaveMob.OnServerInvoke = function(player)
		return self:handleLeaveMob(player)
	end
	
	self.remotes.DoMobOperation.OnServerInvoke = function(player, operationId)
		return self:handleMobOperation(player, operationId)
	end
	
	self.remotes.CheckGamepass.OnServerInvoke = function(player, gamepassKey)
		return self:checkGamepassOwnership(player, gamepassKey)
	end
	
	self.remotes.PromptGamepass.OnServerEvent:Connect(function(player, gamepassKey)
		self:promptGamepassPurchase(player, gamepassKey)
	end)
	
	self.remotes.UseTimeMachine.OnServerInvoke = function(player, yearsBack)
		return self:handleTimeMachine(player, yearsBack)
	end

	self.remotes.GodModeEdit.OnServerInvoke = function(player, payload)
		return self:handleGodModeEdit(player, payload)
	end
	
	-- CRITICAL FIX #13: PREMIUM FEATURES: Royalty handlers
	self.remotes.DoRoyalDuty.OnServerInvoke = function(player, dutyId)
		return self:handleRoyalDuty(player, dutyId)
	end
	
	self.remotes.Abdicate.OnServerInvoke = function(player)
		return self:handleAbdication(player)
	end
	
	self.remotes.GetRoyalInfo.OnServerInvoke = function(player)
		return self:getRoyalInfo(player)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #13: ROYALTY SYSTEM HANDLERS
-- ════════════════════════════════════════════════════════════════════════════

function LifeBackend:handleRoyalDuty(player, dutyId)
	if not self:checkGamepassOwnership(player, "ROYALTY") then
		self:promptGamepassPurchase(player, "ROYALTY")
		return { success = false, message = "👑 Royal duties require the Royalty gamepass.", needsGamepass = true }
	end
	
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end
	
	if not state.RoyalState or not state.RoyalState.isRoyal then
		return { success = false, message = "You're not royalty!" }
	end
	
	-- Find the duty
	local duties = {
		state_visit = { name = "State Visit", emoji = "🤝", popularity = { 2, 8 }, cost = 50000, minAge = 18 },
		ribbon_cutting = { name = "Ribbon Cutting Ceremony", emoji = "✂️", popularity = { 1, 5 }, cost = 5000, minAge = 10 },
		charity_gala = { name = "Host Charity Gala", emoji = "🎭", popularity = { 3, 10 }, cost = 100000, minAge = 18 },
		military_parade = { name = "Attend Military Parade", emoji = "🎖️", popularity = { 2, 6 }, cost = 10000, minAge = 16 },
		parliament_opening = { name = "State Opening of Parliament", emoji = "🏛️", popularity = { 1, 5 }, cost = 25000, minAge = 21, requiresMonarch = true },
		hospital_visit = { name = "Hospital Visit", emoji = "🏥", popularity = { 3, 8 }, cost = 2000, minAge = 8 },
		school_visit = { name = "School Visit", emoji = "🏫", popularity = { 2, 6 }, cost = 3000, minAge = 12 },
		knighting_ceremony = { name = "Knighting Ceremony", emoji = "⚔️", popularity = { 2, 5 }, cost = 15000, minAge = 21, requiresMonarch = true },
		environmental_campaign = { name = "Environmental Campaign", emoji = "🌍", popularity = { 2, 7 }, cost = 200000, minAge = 18 },
		sports_event = { name = "Sports Event Appearance", emoji = "🏆", popularity = { 2, 5 }, cost = 10000, minAge = 12 },
		arts_patronage = { name = "Arts Patronage Event", emoji = "🎨", popularity = { 1, 4 }, cost = 25000, minAge = 16 },
		disaster_relief = { name = "Disaster Relief Visit", emoji = "🆘", popularity = { 5, 15 }, cost = 10000, minAge = 16 },
	}
	
	local duty = duties[dutyId]
	if not duty then
		return { success = false, message = "Unknown duty." }
	end
	
	-- Check age requirement
	if state.Age < duty.minAge then
		return { success = false, message = "You must be at least " .. duty.minAge .. " to perform this duty." }
	end
	
	-- Check monarch requirement
	if duty.requiresMonarch and not state.RoyalState.isMonarch then
		return { success = false, message = "Only the monarch can perform this duty." }
	end
	
	-- Check funds
	if state.Money < duty.cost then
		return { success = false, message = "Not enough funds for this duty. Required: $" .. formatMoney(duty.cost) }
	end
	
	-- Deduct cost
	state.Money = state.Money - duty.cost
	
	-- Apply popularity gain
	local popGain = RANDOM:NextInteger(duty.popularity[1], duty.popularity[2])
	state.RoyalState.popularity = math.min(100, state.RoyalState.popularity + popGain)
	state.RoyalState.dutiesCompleted = (state.RoyalState.dutiesCompleted or 0) + 1
	state.RoyalState.dutyStreak = (state.RoyalState.dutyStreak or 0) + 1
	
	-- Streak bonus
	if state.RoyalState.dutyStreak >= 5 then
		state.RoyalState.popularity = math.min(100, state.RoyalState.popularity + 5)
		popGain = popGain + 5
	end
	
	local message = string.format("%s Completed: %s (+%d popularity)", duty.emoji, duty.name, popGain)
	appendFeed(state, message)
	self:pushState(player, message)
	
	return { 
		success = true, 
		message = message,
		popularityGain = popGain,
		currentPopularity = state.RoyalState.popularity,
	}
end

function LifeBackend:handleAbdication(player)
	if not self:checkGamepassOwnership(player, "ROYALTY") then
		return { success = false, message = "👑 Abdication requires the Royalty gamepass.", needsGamepass = true }
	end
	
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end
	
	if not state.RoyalState or not state.RoyalState.isRoyal then
		return { success = false, message = "You're not royalty!" }
	end
	
	if not state.RoyalState.isMonarch then
		return { success = false, message = "Only the monarch can abdicate. You're still " .. (state.RoyalState.title or "an heir") .. "." }
	end
	
	-- Abdicate
	state.RoyalState.isMonarch = false
	state.RoyalState.popularity = math.max(0, state.RoyalState.popularity - 30)
	
	state.Flags.abdicated = true
	state.Flags.is_monarch = nil
	state.Flags.former_monarch = true
	
	local message = "👑 You have abdicated the throne! The nation is shocked."
	appendFeed(state, message)
	self:pushState(player, message)
	
	return { success = true, message = message }
end

function LifeBackend:getRoyalInfo(player)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end
	
	local hasRoyalty = self:checkGamepassOwnership(player, "ROYALTY")
	
	if not state.RoyalState or not state.RoyalState.isRoyal then
		return {
			success = true,
			isRoyal = false,
			hasGamepass = hasRoyalty,
		}
	end
	
	return {
		success = true,
		isRoyal = true,
		hasGamepass = hasRoyalty,
		royalState = state.RoyalState,
	}
end

function LifeBackend:createInitialState(player)
	local state = LifeState.new(player)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #11: BITIZENSHIP BENEFITS
	-- Players with Bitizenship get bonus starting money and special flags
	-- ═══════════════════════════════════════════════════════════════════════════════
	local hasBitizenship = self:checkGamepassOwnership(player, "BITIZENSHIP")
	if hasBitizenship then
		state.Money = (state.Money or 0) + 10000 -- Start with $10k bonus
		state.Flags = state.Flags or {}
		state.Flags.bitizen = true
		state.Flags.premium_player = true
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #4: Set ALL gamepass ownership flags on character creation
	-- Without this, premium events check flags that are NEVER set!
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.Flags = state.Flags or {}
	state.GamepassOwnership = state.GamepassOwnership or {}
	
	-- Check and set ALL premium gamepass flags
	local hasRoyalty = self:checkGamepassOwnership(player, "ROYALTY")
	if hasRoyalty then
		state.Flags.royalty_gamepass = true
		state.GamepassOwnership.royalty = true
	end
	
	local hasMafia = self:checkGamepassOwnership(player, "MAFIA")
	if hasMafia then
		state.Flags.mafia_gamepass = true  -- CRITICAL FIX #9: This flag was NEVER set!
		state.GamepassOwnership.mafia = true
	end
	
	local hasCelebrity = self:checkGamepassOwnership(player, "CELEBRITY")
	if hasCelebrity then
		state.Flags.celebrity_gamepass = true
		state.GamepassOwnership.celebrity = true
	end
	
	local hasGodMode = self:checkGamepassOwnership(player, "GOD_MODE")
	if hasGodMode then
		state.Flags.god_mode_gamepass = true
		state.GamepassOwnership.godMode = true
		-- CRITICAL FIX #6: God Mode enables stat editing UI, not events
		state.GodModeState = state.GodModeState or {}
		state.GodModeState.enabled = true
	end
	
	local hasTimeMachine = self:checkGamepassOwnership(player, "TIME_MACHINE")
	if hasTimeMachine then
		state.Flags.time_machine_gamepass = true
		state.GamepassOwnership.timeMachine = true
	end
	
	local hasBossMode = self:checkGamepassOwnership(player, "BOSS_MODE")
	if hasBossMode then
		state.Flags.boss_mode_gamepass = true
		state.GamepassOwnership.bossMode = true
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- SERVER-SIDE FAMILY CREATION
	-- Create proper family members so they're part of authoritative state
	-- This prevents the "disappearing family" bug where client-generated defaults
	-- would conflict with server state after interactions.
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	state.Relationships = state.Relationships or {}
	
	-- Generate random names for family members (EXPANDED - 80+ names each for variety)
	local maleNames = {
		-- Classic names
		"James", "Michael", "David", "John", "Robert", "William", "Richard", "Thomas", "Charles", "Daniel",
		"Christopher", "Matthew", "Anthony", "Mark", "Steven", "Andrew", "Joshua", "Kevin", "Brian", "Ryan",
		-- Modern names
		"Liam", "Noah", "Oliver", "Ethan", "Aiden", "Lucas", "Mason", "Logan", "Alexander", "Sebastian",
		"Benjamin", "Henry", "Owen", "Jack", "Carter", "Jayden", "Dylan", "Wyatt", "Luke", "Caleb",
		-- Diverse cultural names
		"Diego", "Carlos", "Miguel", "Rafael", "Alejandro", "Juan", "Marco", "Antonio", "Luis", "Eduardo",
		"Jamal", "Darius", "Malik", "Terrence", "Andre", "DeShawn", "Marcus", "Dante", "Isaiah", "Brandon",
		"Hiroshi", "Takeshi", "Kenji", "Yuki", "Ryu", "Akira", "Kazuki", "Ren", "Sora", "Haruki",
		"Raj", "Arjun", "Vikram", "Rahul", "Amir", "Omar", "Hassan", "Khalid", "Zaid", "Tariq"
	}
	local femaleNames = {
		-- Classic names
		"Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Susan", "Jessica", "Sarah", "Karen",
		"Nancy", "Lisa", "Betty", "Margaret", "Dorothy", "Sandra", "Ashley", "Kimberly", "Donna", "Emily",
		-- Modern names
		"Emma", "Olivia", "Ava", "Isabella", "Sophia", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn",
		"Abigail", "Luna", "Ella", "Scarlett", "Grace", "Chloe", "Victoria", "Aria", "Lily", "Zoey",
		-- Diverse cultural names
		"Maria", "Carmen", "Valentina", "Lucia", "Ana", "Rosa", "Elena", "Gabriela", "Natalia", "Sofia",
		"Aaliyah", "Destiny", "Diamond", "Jasmine", "Imani", "Tiana", "Sierra", "Layla", "Aisha", "Zoe",
		"Sakura", "Yuki", "Mei", "Hana", "Aiko", "Rin", "Mika", "Kaori", "Nanami", "Koharu",
		"Priya", "Ananya", "Isha", "Fatima", "Zahra", "Leila", "Nadia", "Sara", "Amira", "Yasmin"
	}
	
	local function randomName(gender)
		local names = (gender == "male") and maleNames or femaleNames
		return names[RANDOM:NextInteger(1, #names)]
	end
	
	-- Mother (always created)
	local motherAge = 22 + RANDOM:NextInteger(0, 8) -- Mom is 22-30 years older
	state.Relationships["mother"] = {
		id = "mother",
		name = randomName("female"),
		type = "family",
		role = "Mother",
		relationship = 75 + RANDOM:NextInteger(-10, 15),
		age = motherAge,
		gender = "female",
		alive = true,
		isFamily = true,
	}
	
	-- Father (always created)
	local fatherAge = 24 + RANDOM:NextInteger(0, 10) -- Dad is 24-34 years older
	state.Relationships["father"] = {
		id = "father",
		name = randomName("male"),
		type = "family",
		role = "Father",
		relationship = 70 + RANDOM:NextInteger(-10, 15),
		age = fatherAge,
		gender = "male",
		alive = true,
		isFamily = true,
	}
	
	-- Grandparents (50% chance each)
	if RANDOM:NextNumber() > 0.5 then
		local grandmaAge = motherAge + 22 + RANDOM:NextInteger(0, 8)
		state.Relationships["grandmother_maternal"] = {
			id = "grandmother_maternal",
			name = randomName("female"),
			type = "family",
			role = "Grandmother",
			relationship = 65 + RANDOM:NextInteger(-5, 10),
			age = grandmaAge,
			gender = "female",
			alive = grandmaAge < 85,
			isFamily = true,
		}
	end
	
	if RANDOM:NextNumber() > 0.5 then
		local grandpaAge = fatherAge + 24 + RANDOM:NextInteger(0, 10)
		state.Relationships["grandfather_paternal"] = {
			id = "grandfather_paternal",
			name = randomName("male"),
			type = "family",
			role = "Grandfather",
			relationship = 60 + RANDOM:NextInteger(-5, 10),
			age = grandpaAge,
			gender = "male",
			alive = grandpaAge < 82,
			isFamily = true,
		}
	end
	
	-- Siblings (random chance)
	local numSiblings = RANDOM:NextInteger(0, 3)
	for i = 1, numSiblings do
		local isBrother = RANDOM:NextNumber() > 0.5
		local siblingAge = RANDOM:NextInteger(-5, 8) -- Can be older or younger
		local siblingId = (isBrother and "brother_" or "sister_") .. tostring(i)
		local siblingRole = siblingAge > 0 and (isBrother and "Older Brother" or "Older Sister") 
			or (isBrother and "Younger Brother" or "Younger Sister")
		
		state.Relationships[siblingId] = {
			id = siblingId,
			name = randomName(isBrother and "male" or "female"),
			type = "family",
			role = siblingRole,
			relationship = 55 + RANDOM:NextInteger(-10, 20),
			age = math.max(1, siblingAge), -- Sibling age relative to player (stored as absolute later)
			gender = isBrother and "male" or "female",
			alive = true,
			isFamily = true,
			ageOffset = siblingAge, -- Store the offset for updating later
		}
	end
	
	-- CRITICAL FIX: Ensure Assets table is properly initialized
	-- This prevents the "state.Assets is NIL" error on client
	state.Assets = state.Assets or {}
	state.Assets.Properties = state.Assets.Properties or {}
	state.Assets.Vehicles = state.Assets.Vehicles or {}
	state.Assets.Items = state.Assets.Items or {}
	state.Assets.Crypto = state.Assets.Crypto or {}
	state.Assets.Investments = state.Assets.Investments or {}
	state.Assets.Businesses = state.Assets.Businesses or {}
	
	debugPrint(string.format("Created initial state for %s with %d family members", 
		player.Name, countEntries(state.Relationships)))
	debugPrint("  Assets initialized:", state.Assets ~= nil)
	
	return state
end

function LifeBackend:getState(player)
	return self.playerStates[player]
end

function LifeBackend:serializeState(state)
	local serialized
	
	if state and state.Serialize then
		serialized = state:Serialize()
		serialized.PendingFeed = nil
		serialized.lastFeed = nil
	else
		serialized = deepCopy(state)
		if serialized then
			serialized.PendingFeed = nil
			serialized.lastFeed = nil
		end
	end
	
	-- CRITICAL FIX: Always ensure Assets is properly structured in serialized output
	-- This fixes the "state.Assets is NIL" error on client
	if serialized then
		serialized.Assets = serialized.Assets or {}
		serialized.Assets.Properties = serialized.Assets.Properties or {}
		serialized.Assets.Vehicles = serialized.Assets.Vehicles or {}
		serialized.Assets.Items = serialized.Assets.Items or {}
		serialized.Assets.Crypto = serialized.Assets.Crypto or {}
		serialized.Assets.Investments = serialized.Assets.Investments or {}
		serialized.Assets.Businesses = serialized.Assets.Businesses or {}
		
		-- Debug: Trace what's being serialized
		debugPrint("[serializeState] Assets in serialized state:")
		debugPrint("  Properties:", #serialized.Assets.Properties)
		debugPrint("  Vehicles:", #serialized.Assets.Vehicles)
		debugPrint("  Items:", #serialized.Assets.Items)

		-- ═══════════════════════════════════════════════════════════════════════════════
		-- PREMIUM FEATURE SERIALIZATION - CRITICAL FIX #21
		-- Ensure all premium states are properly serialized for client
		-- ═══════════════════════════════════════════════════════════════════════════════
		
		-- MAFIA STATE
		serialized.MobState = MobSystem:serialize(state)
		
		-- ROYALTY STATE
		if state.RoyalState and state.RoyalState.isRoyal then
			serialized.RoyalState = state.RoyalState
		else
			serialized.RoyalState = { isRoyal = false }
		end
		
		-- CELEBRITY/FAME STATE
		if state.FameState and state.FameState.careerPath then
			serialized.FameState = state.FameState
		else
			serialized.FameState = { isFamous = false, fame = state.Fame or 0 }
		end
		
		-- GOD MODE STATE
		if state.GodModeState then
			serialized.GodModeState = state.GodModeState
		else
			serialized.GodModeState = { enabled = false }
		end
		
		-- GAMEPASS OWNERSHIP
		serialized.GamepassOwnership = state.GamepassOwnership or {}
	end
	
	return serialized
end

function LifeBackend:pushState(player, feedText, resultData)
	local state = self.playerStates[player]
	if not state then
		return
	end
	state.lastFeed = feedText or state.lastFeed
	self.remotes.SyncState:FireClient(player, self:serializeState(state), feedText, resultData)
end

function LifeBackend:applyStatChanges(state, deltas)
	if not deltas then
		return
	end
	state.Stats = state.Stats or {}
	for stat, delta in pairs(deltas) do
		if stat == "Money" or stat == "money" then
			state.Money = math.max(0, (state.Money or 0) + delta)
		elseif stat == "Health" or stat == "H" then
			state.Stats.Health = clamp((state.Stats.Health or 0) + delta)
			state.Health = state.Stats.Health
		elseif stat == "Happiness" or stat == "Happy" then
			state.Stats.Happiness = clamp((state.Stats.Happiness or 0) + delta)
			state.Happiness = state.Stats.Happiness
		elseif stat == "Smarts" then
			state.Stats.Smarts = clamp((state.Stats.Smarts or 0) + delta)
			state.Smarts = state.Stats.Smarts
		elseif stat == "Looks" then
			state.Stats.Looks = clamp((state.Stats.Looks or 0) + delta)
			state.Looks = state.Stats.Looks
		end
	end
end

function LifeBackend:addMoney(state, amount)
	state.Money = math.max(0, (state.Money or 0) + amount)
end

-- ============================================================================
-- Player lifecycle
-- ============================================================================

function LifeBackend:onPlayerAdded(player)
	local state = self:createInitialState(player)
	self.playerStates[player] = state
	self:pushState(player, "A new life begins...")
end

function LifeBackend:onPlayerRemoving(player)
	self.playerStates[player] = nil
	self.pendingEvents[player.UserId] = nil
end

-- CRITICAL FIX: Filter text using Roblox's TextService for custom names
local TextService = game:GetService("TextService")

local function filterText(text, player)
	if not text or text == "" then return text end
	local success, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	if success then
		return result
	else
		-- If filtering fails, return a sanitized version
		return text:gsub("[^%w%s'-]", ""):sub(1, 30)
	end
end

function LifeBackend:setLifeInfo(player, name, gender)
	local state = self:getState(player)
	if not state then
		return
	end
	if name and name ~= "" then
		-- CRITICAL FIX: Apply Roblox text filtering to custom names
		local filteredName = filterText(name, player)
		state.Name = filteredName
	end
	if gender then
		state.Gender = gender
	end
	self:pushState(player, string.format("%s takes their first breath.", state.Name or "Your character"))
end

-- ============================================================================
-- Age Up & Events
-- ============================================================================

function LifeBackend:advanceRelationships(state)
	if not state.Relationships then
		return
	end
	
	-- CRITICAL FIX: Relationships degrade much faster while in jail!
	-- Prison isolates you from loved ones, causing relationships to suffer
	local isInJail = state.InJail
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Improved family death mechanics
	-- Realistic death chances based on age, not just >95
	-- Proper happiness impact and death notifications
	-- ═══════════════════════════════════════════════════════════════════════════════
	local familyDeaths = {}
	
	for relId, rel in pairs(state.Relationships) do
		if type(rel) == "table" and rel.alive ~= false then
			-- Normal fluctuation: -2 to +3
			-- Jail fluctuation: -8 to -2 (always negative, relationships decay)
			local change
			if isInJail then
				change = RANDOM:NextInteger(-8, -2)
			else
				change = RANDOM:NextInteger(-2, 3)
			end
			rel.relationship = clamp((rel.relationship or 60) + change, 0, 100)
			
			-- Partner might leave if relationship drops too low during jail
			if isInJail and rel.type == "romance" and rel.relationship < 20 then
				if RANDOM:NextNumber() < 0.4 then -- 40% chance partner leaves
					rel.alive = false -- Mark as "gone" (breakup)
					state.Flags.recently_single = true
					state.Flags.has_partner = nil
					if state.Relationships.partner and state.Relationships.partner.id == rel.id then
						state.Relationships.partner = nil
					end
					state.PendingFeed = (rel.name or "Your partner") .. " couldn't handle the separation and left you."
				end
			end
			
			-- Age up the family member
			rel.age = (rel.age or (state.Age + 20)) + 1
			
			-- CRITICAL FIX: Realistic death chances based on age for family members
			-- More graduated death chances instead of just >95 = 20%
			if rel.type == "family" or rel.isFamily then
				local deathChance = 0
				local relAge = rel.age or 0
				
				if relAge >= 100 then
					deathChance = 0.50 -- 50% chance at 100+
				elseif relAge >= 95 then
					deathChance = 0.25 -- 25% chance at 95-99
				elseif relAge >= 90 then
					deathChance = 0.12 -- 12% chance at 90-94
				elseif relAge >= 85 then
					deathChance = 0.06 -- 6% chance at 85-89
				elseif relAge >= 80 then
					deathChance = 0.03 -- 3% chance at 80-84
				elseif relAge >= 75 then
					deathChance = 0.015 -- 1.5% chance at 75-79
				elseif relAge >= 70 then
					deathChance = 0.008 -- 0.8% chance at 70-74
				elseif relAge >= 60 then
					deathChance = 0.003 -- 0.3% chance at 60-69 (accidents, illness)
				end
				
				if deathChance > 0 and RANDOM:NextNumber() < deathChance then
					rel.alive = false
					rel.deceased = true
					rel.deathAge = relAge
					table.insert(familyDeaths, {
						name = rel.name or "A loved one",
						role = rel.role or "family member",
						age = relAge,
						id = relId,
					})
				end
			elseif rel.age > 95 and RANDOM:NextNumber() < 0.2 then
				-- Non-family (old friends etc) still use simple check
				rel.alive = false
				rel.deceased = true
				state.PendingFeed = (rel.name or "A loved one") .. " passed away."
			end
		end
	end
	
	-- CRITICAL FIX: Handle family death notifications with proper emotional impact
	if #familyDeaths > 0 then
		local death = familyDeaths[1] -- Process one death at a time
		local roleName = death.role or "family member"
		local isCloseFamily = (death.id == "mother" or death.id == "father" or 
			death.id:find("brother") or death.id:find("sister"))
		
		-- Happiness impact based on closeness
		if state.ModifyStat then
			if isCloseFamily then
				state:ModifyStat("Happiness", -25)
			else
				state:ModifyStat("Happiness", -10)
			end
		else
			state.Stats = state.Stats or {}
			local impact = isCloseFamily and -25 or -10
			state.Stats.Happiness = clamp((state.Stats.Happiness or 50) + impact, 0, 100)
		end
		
		local messages = {
			"💔 %s (%s, age %d) has passed away. Rest in peace.",
			"😢 Sadly, %s (%s) died at age %d.",
			"🕯️ Your %s, %s, passed away at %d years old.",
		}
		local msgTemplate = messages[RANDOM:NextInteger(1, #messages)]
		local formattedMsg = string.format(msgTemplate, death.name, roleName, death.age)
		
		state.PendingFeed = formattedMsg
		state.Flags = state.Flags or {}
		state.Flags.recently_bereaved = true
		state.Flags["lost_" .. death.id] = true
	end
end

function LifeBackend:updateEducationProgress(state)
	-- CRITICAL FIX: Can't attend school/college while incarcerated!
	-- Education progress is paused during jail time
	if state.InJail then
		return
	end
	
	local eduData = state.EducationData
	if eduData and eduData.Status == "enrolled" then
		-- CRITICAL FIX: Ensure duration is never 0 or nil to prevent instant graduation bug
		-- Duration of 0 would cause 100/0 = infinity, triggering instant "graduation"
		local duration = eduData.Duration
		if not duration or duration <= 0 then
			duration = 4 -- Default to 4 years if not set properly
		end
		local progressPerYear = 100 / duration
		eduData.Progress = clamp((eduData.Progress or 0) + progressPerYear, 0, 100)
		if eduData.Progress >= 100 then
			-- CRITICAL FIX: Only show graduation message for High School and higher
			-- Elementary and Middle School are silent auto-progressions (BitLife-style)
			local level = eduData.Level or ""
			local isPreHighSchool = (level == "elementary" or level == "middle_school" or level == "")
			
			if isPreHighSchool then
				-- Silent progression - just reset progress for next phase
				-- The actual institution transition is handled in LifeState:AdvanceAge()
				eduData.Progress = 0
				-- Don't set status to "completed" - we're still in school
			else
				-- High School and above get proper graduation messages
				eduData.Status = "completed"
				state.Education = eduData.Level
				state.PendingFeed = string.format("🎓 You graduated from %s!", eduData.Institution or "school")
				
				-- Set appropriate flags
				state.Flags = state.Flags or {}
				if level == "high_school" then
					state.Flags.graduated_high_school = true
					state.Flags.high_school_graduate = true
				elseif level == "trade" then
					state.Flags.trade_certified = true
				elseif level == "bootcamp" then
					state.Flags.bootcamp_graduate = true
				elseif level == "bachelor" or level == "community" or level == "associate" then
					state.Flags.college_graduate = true
					if level == "bachelor" then
						state.Flags.has_degree = true
					end
				elseif level == "business" then
					state.Flags.masters_degree = true
					state.Flags.has_degree = true
				elseif level == "master" then
					state.Flags.masters_degree = true
					state.Flags.has_degree = true
				elseif level == "law" then
					state.Flags.law_degree = true
					state.Flags.has_degree = true
				elseif level == "medical" then
					state.Flags.medical_degree = true
					state.Flags.has_degree = true
				elseif level == "phd" or level == "doctorate" then
					state.Flags.doctorate = true
					state.Flags.has_degree = true
				end
			end
		end
	end
end

function LifeBackend:tickCareer(state)
	-- CRITICAL: Don't tick career for retired players
	if state.Flags and state.Flags.retired then
		return
	end
	
	-- CRITICAL FIX: Don't tick career while in jail - player loses their job progression
	-- and cannot work while incarcerated
	if state.InJail then
		return
	end
	
	-- Must have a current job to tick career
	if not state.CurrentJob then
		return
	end
	
	state.CareerInfo = state.CareerInfo or {}
	local info = state.CareerInfo
	
	-- Try to get job from catalog, but fallback to CurrentJob data if not found
	-- This handles jobs created by events that aren't in the main JobCatalog
	local catalogJob = JobCatalog[state.CurrentJob.id or state.CurrentJob]
	
	-- For semi-retired, only tick at half rate (less aggressive career progression)
	if state.Flags and state.Flags.semi_retired then
		if RANDOM:NextNumber() < 0.5 then
			return -- Skip half the time
		end
	end
	
	info.yearsAtJob = (info.yearsAtJob or 0) + 1
	-- CRITICAL FIX: Performance can fluctuate more - not always improving
	info.performance = clamp((info.performance or 60) + RANDOM:NextInteger(-5, 5), 0, 100)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #25: Calculate promotion progress based on years and performance
	-- This provides visual feedback to the player without auto-promoting
	-- ═══════════════════════════════════════════════════════════════════════════════
	local yearsProgress = math.min((info.yearsAtJob or 0) * 10, 30) -- Up to 30% from years (3 years min)
	local perfProgress = (info.performance or 50) * 0.5 -- Up to 50% from performance
	info.promotionProgress = clamp(yearsProgress + perfProgress, 0, 100)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Track career skills based on job category
	-- Skills grow slowly while working in related fields
	-- ═══════════════════════════════════════════════════════════════════════════════
	info.skills = info.skills or {}
	local category = state.CurrentJob.category or "general"
	
	-- Map job categories to skills
	local categorySkills = {
		tech = { Technical = 3, Analytical = 2 },
		office = { Social = 2, Analytical = 1 },
		science = { Analytical = 3, Technical = 2 },
		law = { Social = 2, Analytical = 2 },
		finance = { Analytical = 3, Leadership = 1 },
		medical = { Technical = 2, Analytical = 2, Social = 1 },
		military = { Physical = 3, Leadership = 2 },
		sports = { Physical = 4, Leadership = 1 },
		trades = { Technical = 2, Physical = 2 },
		creative = { Creative = 4, Social = 1 },
		entertainment = { Creative = 3, Social = 2 },
		service = { Social = 3 },
		retail = { Social = 2 },
		food = { Social = 1, Physical = 1 },
		executive = { Leadership = 4, Analytical = 2, Social = 2 },
		management = { Leadership = 3, Social = 2 },
		government = { Leadership = 2, Social = 2, Analytical = 1 },
	}
	
	local skillGrowth = categorySkills[category] or { Social = 1 }
	for skill, maxGain in pairs(skillGrowth) do
		local currentLevel = info.skills[skill] or 0
		-- Diminishing returns at higher levels
		local gain = math.max(1, math.floor(maxGain * (1 - currentLevel / 100)))
		info.skills[skill] = math.min(100, currentLevel + RANDOM:NextInteger(0, gain))
	end
	
	-- CRITICAL FIX: Actually PAY the salary during age up!
	-- Use catalog job salary if available, otherwise use CurrentJob.salary directly
	-- This ensures event-created jobs (not in catalog) still pay salary
	local salary = 0
	if catalogJob and catalogJob.salary then
		salary = catalogJob.salary
	elseif state.CurrentJob.salary then
		salary = state.CurrentJob.salary
	end
	
	if salary > 0 then
		self:addMoney(state, salary)
		debugPrint("Salary paid:", salary, "to player. New balance:", state.Money)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROPERTY INCOME - Collect passive income from owned real estate
-- CRITICAL FIX: This was completely missing! Properties have income fields but
-- the rental income was never being collected during age up.
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:collectPropertyIncome(state)
	-- Properties still generate income even if player is in jail (tenants pay rent)
	-- But player can't BUY or SELL while incarcerated (handled elsewhere)
	
	state.Assets = state.Assets or {}
	local properties = state.Assets.Properties or {}
	
	if #properties == 0 then
		return
	end
	
	local totalIncome = 0
	for _, prop in ipairs(properties) do
		local income = prop.income or 0
		if income > 0 then
			totalIncome = totalIncome + income
		end
	end
	
	if totalIncome > 0 then
		self:addMoney(state, totalIncome)
		-- CRITICAL FIX: Only show rental income message occasionally to avoid spam
		-- Only show if:
		-- 1. Income is very significant ($10K+ per year), OR
		-- 2. Player has multiple properties (actual landlord)
		-- AND only show message sometimes (roughly every 3 years) to avoid repetitive feed
		local numProperties = #properties
		local shouldShowMessage = (totalIncome >= 10000 or numProperties >= 2) and RANDOM:NextNumber() < 0.33
		
		if shouldShowMessage then
			local currentFeed = state.PendingFeed or ""
			local incomeText = string.format("💰 Your properties generated $%s in rental income this year.", formatMoney(totalIncome))
			if currentFeed ~= "" then
				state.PendingFeed = currentFeed .. " " .. incomeText
			else
				state.PendingFeed = incomeText
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #10: Vehicle Depreciation System
-- Vehicles lose value over time (10-15% per year) based on condition
-- Without this, cars never lose value and can be sold for purchase price forever
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:tickVehicleDepreciation(state)
	state.Assets = state.Assets or {}
	local vehicles = state.Assets.Vehicles or {}
	
	if #vehicles == 0 then
		return
	end
	
	for _, vehicle in ipairs(vehicles) do
		if vehicle.value and vehicle.value > 0 then
			-- Depreciation rate: 10-15% per year, modified by condition
			local baseDepreciation = 0.12 -- 12% base
			local conditionMod = vehicle.condition and (1 - vehicle.condition / 200) or 1 -- Poor condition = faster depreciation
			local depreciationRate = baseDepreciation * conditionMod
			
			-- Calculate depreciation
			local depreciationAmount = math.floor(vehicle.value * depreciationRate)
			vehicle.value = math.max(500, vehicle.value - depreciationAmount) -- Minimum $500 scrap value
			
			-- Condition also degrades slightly each year (1-5%)
			if vehicle.condition then
				vehicle.condition = math.max(0, vehicle.condition - RANDOM:NextInteger(1, 5))
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #11: Investment Value Fluctuation
-- Investments should gain or lose value each year based on market conditions
-- Without this, investments are just static numbers
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:tickInvestments(state)
	state.Assets = state.Assets or {}
	local investments = state.Assets.Investments or {}
	local crypto = state.Assets.Crypto or {}
	
	-- Stock/bond investments: -10% to +15% annually
	for _, inv in ipairs(investments) do
		if inv.value and inv.value > 0 then
			local changePercent = RANDOM:NextNumber() * 0.25 - 0.10 -- -10% to +15%
			local changeAmount = math.floor(inv.value * changePercent)
			inv.value = math.max(0, inv.value + changeAmount)
		end
	end
	
	-- Crypto: more volatile, -30% to +50% annually
	for _, coin in ipairs(crypto) do
		if coin.value and coin.value > 0 then
			local changePercent = RANDOM:NextNumber() * 0.80 - 0.30 -- -30% to +50%
			local changeAmount = math.floor(coin.value * changePercent)
			coin.value = math.max(0, coin.value + changeAmount)
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #12: Annual Cost of Living Expenses
-- Players should have annual expenses that scale with lifestyle
-- Without this, money only goes up, never down from basic living costs
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyLivingExpenses(state)
	-- Don't apply expenses if player is under 18 (parents support them)
	if (state.Age or 0) < 18 then
		return
	end
	
	-- Don't apply expenses in prison (state provides housing/food)
	if state.InJail then
		return
	end
	
	local baseCost = 8000 -- $8,000/year minimum for basic living
	local totalExpenses = baseCost
	
	-- Add housing costs if no owned property
	local hasProperty = state.Assets and state.Assets.Properties and #state.Assets.Properties > 0
	if not hasProperty then
		totalExpenses = totalExpenses + 12000 -- Rent: $1,000/month
	end
	
	-- Add vehicle maintenance if owns vehicles
	local numVehicles = state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles or 0
	if numVehicles > 0 then
		totalExpenses = totalExpenses + (numVehicles * 2000) -- $2,000/year per vehicle
	end
	
	-- Family costs
	local childCount = state.ChildCount or 0
	if childCount > 0 then
		totalExpenses = totalExpenses + (childCount * 5000) -- $5,000/year per child
	end
	
	-- Healthcare costs increase with age
	if (state.Age or 0) > 50 then
		local ageFactor = ((state.Age or 50) - 50) / 10
		totalExpenses = totalExpenses + math.floor(2000 * ageFactor)
	end
	
	-- Apply expenses (but don't go below 0)
	local currentMoney = state.Money or 0
	if currentMoney >= totalExpenses then
		state.Money = currentMoney - totalExpenses
	else
		-- Can't afford full expenses - go broke but not negative
		state.Money = 0
		state.Flags = state.Flags or {}
		state.Flags.struggling_financially = true
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #13: Health Decay from Unhealthy Habits
-- Smoking, drinking, and other bad habits should actually affect health
-- Without this, flags like "smoker" are just cosmetic
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyHabitEffects(state)
	state.Stats = state.Stats or {}
	state.Flags = state.Flags or {}
	
	local healthChange = 0
	local happinessChange = 0
	
	-- Smoking: -1 to -3 health per year, cumulative damage
	if state.Flags.smoker then
		healthChange = healthChange - RANDOM:NextInteger(1, 3)
		-- 5% chance per year of serious illness from smoking
		if RANDOM:NextNumber() < 0.05 then
			state.Flags.smoking_related_illness = true
			healthChange = healthChange - 10
		end
	end
	
	-- Heavy drinking: -1 to -2 health, -2 to +1 happiness (addiction)
	if state.Flags.heavy_drinker then
		healthChange = healthChange - RANDOM:NextInteger(1, 2)
		happinessChange = happinessChange + RANDOM:NextInteger(-2, 1)
		-- 3% chance of liver problems
		if RANDOM:NextNumber() < 0.03 then
			state.Flags.liver_problems = true
			healthChange = healthChange - 8
		end
	end
	
	-- Substance abuse: serious health impact
	if state.Flags.substance_issue or state.Flags.substance_addict then
		healthChange = healthChange - RANDOM:NextInteger(2, 5)
		happinessChange = happinessChange - RANDOM:NextInteger(1, 3)
	end
	
	-- Fitness enthusiast: positive health
	if state.Flags.fitness_enthusiast then
		healthChange = healthChange + RANDOM:NextInteger(1, 2)
	end
	
	-- Apply changes
	if healthChange ~= 0 then
		state.Stats.Health = clamp((state.Stats.Health or 50) + healthChange, 0, 100)
		state.Health = state.Stats.Health
	end
	
	if happinessChange ~= 0 then
		state.Stats.Happiness = clamp((state.Stats.Happiness or 50) + happinessChange, 0, 100)
		state.Happiness = state.Stats.Happiness
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #14: Fame Decay System
-- Fame should gradually decrease without maintenance
-- Without this, once famous always famous
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:tickFame(state)
	local fame = state.Fame or 0
	if fame <= 0 then
		return
	end
	
	-- Fame naturally decays 5-10% per year without maintenance
	local decayRate = RANDOM:NextNumber() * 0.05 + 0.05 -- 5-10%
	local decayAmount = math.floor(fame * decayRate)
	
	-- Active careers that maintain fame slow decay
	if state.CurrentJob then
		local jobId = state.CurrentJob.id or ""
		local fameMaintainingJobs = {
			"actor", "singer", "athlete", "influencer", "model", 
			"tv_host", "youtuber", "politician", "celebrity"
		}
		for _, job in ipairs(fameMaintainingJobs) do
			if jobId:find(job) then
				decayAmount = math.floor(decayAmount * 0.3) -- 70% slower decay
				break
			end
		end
	end
	
	state.Fame = math.max(0, fame - decayAmount)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #15: Education Debt Interest
-- Student loans should accrue interest annually
-- Without this, college debt never grows
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyDebtInterest(state)
	if not state.EducationData or not state.EducationData.Debt then
		return
	end
	
	local debt = state.EducationData.Debt
	if debt <= 0 then
		return
	end
	
	-- 5% annual interest on student loans
	local interest = math.floor(debt * 0.05)
	state.EducationData.Debt = debt + interest
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #36: Annual Education Costs
-- Students need to pay for room, board, books, etc. while enrolled
-- Without this, college is just a one-time tuition payment
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyEducationCosts(state)
	local eduData = state.EducationData
	if not eduData or eduData.Status ~= "enrolled" then
		return
	end
	
	-- CRITICAL FIX: Only apply education costs to POST-HIGH-SCHOOL education!
	-- Elementary, middle school, and high school are FREE (public school)
	-- This was incorrectly charging 5-year-olds for "education expenses"
	local level = eduData.Level or ""
	
	-- These are the ONLY levels that have costs (college and beyond)
	local annualCosts = {
		community = 3000, -- Living expenses while at community college
		bachelor = 8000, -- Room, board, books at university
		master = 6000, -- Graduate students have some funding
		law = 5000, -- Law school has less room/board (often living at home)
		medical = 10000, -- Med students need equipment, books
		phd = 3000, -- PhD students get stipends
	}
	
	-- CRITICAL: If the level is not in our costs table, it's FREE education (K-12)
	-- Do NOT charge for elementary, middle_school, high_school, or unknown levels
	local cost = annualCosts[level]
	if not cost then
		-- This is K-12 education or unknown - no cost!
		return
	end
	
	-- Also verify age - college shouldn't start before 18
	local age = state.Age or 0
	if age < 18 then
		return
	end
	
	local money = state.Money or 0
	
	if money >= cost then
		state.Money = money - cost
	else
		-- Can't afford - add to debt
		local shortfall = cost - money
		state.Money = 0
		eduData.Debt = (eduData.Debt or 0) + shortfall
		state.Flags = state.Flags or {}
		state.Flags.has_student_loans = true
		self:logYearEvent(state, "education",
			string.format("📚 Took out $%d in loans for education expenses.", shortfall), "📝")
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #16: Pet Lifecycle System
-- Pets age and eventually pass away (dogs ~12-15 years, cats ~15-20 years)
-- Without this, pets live forever once acquired
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:tickPetLifecycle(state)
	state.Flags = state.Flags or {}
	state.PetData = state.PetData or {}
	
	-- Initialize pet ages if not set
	if state.Flags.has_dog and not state.PetData.dogAge then
		state.PetData.dogAge = 1 -- Assume recently adopted
		state.PetData.dogName = state.PetData.dogName or "Buddy"
	end
	if state.Flags.has_cat and not state.PetData.catAge then
		state.PetData.catAge = 1
		state.PetData.catName = state.PetData.catName or "Whiskers"
	end
	
	-- Age dogs and check for death (lifespan 10-15 years)
	if state.Flags.has_dog and state.PetData.dogAge then
		state.PetData.dogAge = state.PetData.dogAge + 1
		local dogAge = state.PetData.dogAge
		if dogAge >= 10 then
			local deathChance = (dogAge - 10) / 10 -- Increases each year after 10
			if RANDOM:NextNumber() < deathChance then
				state.Flags.has_dog = nil
				state.Flags.lost_dog = true
				state.PetData.dogAge = nil
				local dogName = state.PetData.dogName or "your dog"
				self:logYearEvent(state, "pet_death", 
					string.format("💔 %s passed away after %d wonderful years together.", dogName, dogAge), "🐕")
				state.Stats = state.Stats or {}
				state.Stats.Happiness = clamp((state.Stats.Happiness or 50) - 15, 0, 100)
			end
		end
	end
	
	-- Age cats and check for death (lifespan 12-20 years)
	if state.Flags.has_cat and state.PetData.catAge then
		state.PetData.catAge = state.PetData.catAge + 1
		local catAge = state.PetData.catAge
		if catAge >= 12 then
			local deathChance = (catAge - 12) / 15 -- Cats live longer
			if RANDOM:NextNumber() < deathChance then
				state.Flags.has_cat = nil
				state.Flags.lost_cat = true
				state.PetData.catAge = nil
				local catName = state.PetData.catName or "your cat"
				self:logYearEvent(state, "pet_death", 
					string.format("💔 %s passed away at age %d. A faithful companion.", catName, catAge), "🐱")
				state.Stats = state.Stats or {}
				state.Stats.Happiness = clamp((state.Stats.Happiness or 50) - 12, 0, 100)
			end
		end
	end
	
	-- Small pets have shorter lifespans (2-5 years)
	if state.Flags.has_small_pet and state.PetData.smallPetAge then
		state.PetData.smallPetAge = state.PetData.smallPetAge + 1
		if state.PetData.smallPetAge >= 3 then
			local deathChance = (state.PetData.smallPetAge - 2) / 5
			if RANDOM:NextNumber() < deathChance then
				state.Flags.has_small_pet = nil
				state.PetData.smallPetAge = nil
				self:logYearEvent(state, "pet_death", "💔 Your small pet passed away.", "🐹")
				state.Stats.Happiness = clamp((state.Stats.Happiness or 50) - 5, 0, 100)
			end
		end
	elseif state.Flags.has_small_pet and not state.PetData.smallPetAge then
		state.PetData.smallPetAge = 1
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #17: Career Skills Tracking
-- Skills gained from jobs should persist and affect future job applications
-- Without this, experience in a field doesn't help career progression
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:updateCareerSkills(state)
	if not state.CurrentJob then
		return
	end
	
	state.CareerInfo = state.CareerInfo or {}
	state.CareerInfo.skills = state.CareerInfo.skills or {}
	
	local job = state.CurrentJob
	local category = job.category or "general"
	
	-- Gain 1-3 skill points in current category each year
	local skillGain = RANDOM:NextInteger(1, 3)
	state.CareerInfo.skills[category] = (state.CareerInfo.skills[category] or 0) + skillGain
	
	-- Cap skills at 100
	state.CareerInfo.skills[category] = math.min(100, state.CareerInfo.skills[category])
	
	-- Also gain general "work experience" stat
	state.CareerInfo.skills.general = (state.CareerInfo.skills.general or 0) + 1
	state.CareerInfo.skills.general = math.min(100, state.CareerInfo.skills.general)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #18: Relationship Decay Without Interaction
-- Relationships that aren't maintained should slowly decrease
-- Without this, relationships stay at 100 forever once maxed
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyRelationshipDecay(state)
	if not state.Relationships then
		return
	end
	
	for relId, rel in pairs(state.Relationships) do
		if type(rel) == "table" and rel.alive ~= false then
			-- Relationships naturally decay 1-3 points per year without interaction
			local decay = RANDOM:NextInteger(1, 3)
			
			-- Close family decays slower
			if rel.isFamily or rel.type == "family" then
				decay = math.floor(decay * 0.5)
			end
			
			-- Partners decay faster if not married (less commitment)
			if rel.type == "romantic" and not state.Flags.married then
				decay = decay + 1
			end
			
			rel.relationship = math.max(0, (rel.relationship or 50) - decay)
			
			-- Very low relationships may end naturally
			if rel.relationship <= 10 and rel.type == "friend" then
				if RANDOM:NextNumber() < 0.2 then -- 20% chance friendship fades
					rel.alive = false
					rel.ended = true
					rel.endReason = "drifted_apart"
				end
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #19: Property Appreciation/Depreciation
-- Property values should change based on market conditions
-- Without this, properties are just static values
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:tickPropertyValues(state)
	state.Assets = state.Assets or {}
	local properties = state.Assets.Properties or {}
	
	if #properties == 0 then
		return
	end
	
	for _, prop in ipairs(properties) do
		if prop.value and prop.value > 0 then
			-- Properties generally appreciate 2-5% per year, sometimes decline 1-2%
			local changePercent = RANDOM:NextNumber() * 0.06 - 0.01 -- -1% to +5%
			local changeAmount = math.floor(prop.value * changePercent)
			prop.value = math.max(1000, prop.value + changeAmount) -- Minimum $1,000 value
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #20: Bankruptcy Protection System
-- Players with massive debt should face consequences
-- Without this, players can accumulate infinite negative consequences
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:checkBankruptcy(state)
	local totalDebt = 0
	
	-- Calculate total debt
	if state.EducationData and state.EducationData.Debt then
		totalDebt = totalDebt + state.EducationData.Debt
	end
	
	-- CRITICAL FIX #21: Include credit card debt and mortgage in total debt calculation
	state.Flags = state.Flags or {}
	if state.Flags.credit_card_debt then
		totalDebt = totalDebt + (state.Flags.credit_card_debt or 0)
	end
	if state.Flags.mortgage_debt then
		totalDebt = totalDebt + (state.Flags.mortgage_debt or 0)
	end
	
	-- Check if player is in severe financial distress
	local money = state.Money or 0
	local netWorth = computeNetWorth(state)
	
	-- If net worth is severely negative and player has no income
	if netWorth < -100000 and not state.CurrentJob and money <= 0 then
		if not state.Flags.declared_bankruptcy then
			-- First time - opportunity to declare bankruptcy
			state.Flags.financial_crisis = true
			self:logYearEvent(state, "financial", 
				"⚠️ You're in severe financial distress. Consider your options carefully.", "💸")
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #21: Credit Card Debt Interest
-- Credit card debt should accrue 15-25% annual interest (much higher than student loans)
-- Without this, players can rack up credit card debt without consequences
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyCreditCardInterest(state)
	state.Flags = state.Flags or {}
	
	local ccDebt = state.Flags.credit_card_debt or 0
	if ccDebt <= 0 then
		return
	end
	
	-- Credit card interest is brutal: 18-25% APR
	local interestRate = 0.18 + (RANDOM:NextNumber() * 0.07) -- 18-25%
	local interest = math.floor(ccDebt * interestRate)
	state.Flags.credit_card_debt = ccDebt + interest
	
	-- Minimum payment required ($25 or 2% of balance, whichever is higher)
	local minPayment = math.max(25, math.floor(ccDebt * 0.02))
	local money = state.Money or 0
	
	if money >= minPayment then
		state.Money = money - minPayment
		state.Flags.credit_card_debt = math.max(0, state.Flags.credit_card_debt - minPayment)
	else
		-- Missed payment - extra penalties
		state.Flags.credit_card_debt = state.Flags.credit_card_debt + 35 -- Late fee
		state.Flags.bad_credit = true
		self:logYearEvent(state, "financial", 
			"💳 Missed credit card payment! Late fees and credit damage.", "💸")
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #22: Business Income Collection
-- Owned businesses should generate (or lose) income annually
-- Without this, businesses are static investments
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:collectBusinessIncome(state)
	state.Assets = state.Assets or {}
	local businesses = state.Assets.Businesses or {}
	
	if #businesses == 0 then
		return
	end
	
	local totalIncome = 0
	
	for _, biz in ipairs(businesses) do
		if biz.value and biz.value > 0 then
			-- Business income is volatile: -20% to +40% of value annually
			local performanceMultiplier = RANDOM:NextNumber() * 0.60 - 0.20 -- -20% to +40%
			local annualIncome = math.floor(biz.value * performanceMultiplier * 0.15) -- 15% base return
			
			-- Track business performance
			biz.lastYearProfit = annualIncome
			
			if annualIncome > 0 then
				totalIncome = totalIncome + annualIncome
				-- Good year - business grows
				biz.value = math.floor(biz.value * (1 + RANDOM:NextNumber() * 0.05)) -- Up to 5% growth
			elseif annualIncome < 0 then
				-- Bad year - might need to inject cash or business shrinks
				biz.value = math.max(100, math.floor(biz.value * (1 - RANDOM:NextNumber() * 0.1))) -- Up to 10% decline
			end
		end
	end
	
	if totalIncome > 0 then
		state.Money = (state.Money or 0) + totalIncome
		self:logYearEvent(state, "business", 
			string.format("📊 Your businesses generated $%s in profit!", formatMoney(totalIncome)), "💼")
	elseif totalIncome < 0 then
		-- Business losses
		local loss = math.abs(totalIncome)
		if (state.Money or 0) >= loss then
			state.Money = state.Money - loss
			self:logYearEvent(state, "business", 
				string.format("📊 Your businesses lost $%s this year.", formatMoney(loss)), "📉")
		else
			self:logYearEvent(state, "business", 
				"📊 Your businesses are struggling. Consider your options.", "📉")
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #23: Mortgage Payment Tracking
-- Home mortgages should require monthly payments
-- Without this, owning a home has no ongoing cost
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyMortgagePayments(state)
	state.Flags = state.Flags or {}
	
	local mortgageDebt = state.Flags.mortgage_debt or 0
	if mortgageDebt <= 0 then
		return
	end
	
	-- Mortgage interest is typically 3-7% APR
	local interestRate = 0.05 -- 5% average
	local monthlyInterest = math.floor(mortgageDebt * interestRate / 12)
	local monthlyPrincipal = math.floor(mortgageDebt / 360) -- 30-year mortgage
	local annualPayment = (monthlyInterest + monthlyPrincipal) * 12
	
	local money = state.Money or 0
	
	if money >= annualPayment then
		state.Money = money - annualPayment
		state.Flags.mortgage_debt = math.max(0, mortgageDebt - (monthlyPrincipal * 12))
		
		if state.Flags.mortgage_debt <= 0 then
			state.Flags.mortgage_debt = nil
			state.Flags.mortgage_paid_off = true
			self:logYearEvent(state, "housing", 
				"🏠 Congratulations! You paid off your mortgage!", "🎉")
		end
	else
		-- Can't afford mortgage
		state.Flags.mortgage_trouble = true
		self:logYearEvent(state, "housing", 
			"🏠 Warning: Struggling to make mortgage payments!", "⚠️")
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #24: Update Child Roles As They Grow
-- Children should transition from "Son/Daughter" to "Teenage" to "Adult"
-- 
-- NOTE: Aging and death checks are ONLY done in advanceRelationships() now!
-- Previously this function duplicated that work, causing:
--   1. Family members aging 2x per year
--   2. Family members getting 2x death rolls per year
-- This was why parents died when the player was only 21-23 years old!
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:ageRelationships(state)
	if not state.Relationships then
		return
	end
	
	for relId, rel in pairs(state.Relationships) do
		if type(rel) == "table" and rel.alive ~= false then
			-- REMOVED: Duplicate aging - advanceRelationships() already ages everyone
			-- REMOVED: Duplicate death checks - advanceRelationships() already handles this
			
			-- Children grow up and their role description changes
			if rel.isChild and rel.age then
				-- Update child role based on age
				if rel.age >= 18 then
					rel.role = rel.gender == "male" and "Adult Son" or "Adult Daughter"
					rel.isChild = nil
					rel.isAdult = true
				elseif rel.age >= 13 then
					rel.role = rel.gender == "male" and "Teenage Son" or "Teenage Daughter"
				end
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #25: Health Insurance Costs
-- Adults without employer health insurance should pay for it
-- Without this, healthcare has no ongoing cost except emergencies
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyHealthInsuranceCosts(state)
	-- Only applies to adults
	if (state.Age or 0) < 18 then
		return
	end
	
	-- Skip if in prison (state provides healthcare)
	if state.InJail then
		return
	end
	
	state.Flags = state.Flags or {}
	
	-- Check if employed (employer provides insurance)
	if state.CurrentJob then
		-- Employed - partial insurance cost
		local employeeShare = 2400 -- $200/month employee contribution
		if (state.Money or 0) >= employeeShare then
			state.Money = state.Money - employeeShare
		end
		state.Flags.has_health_insurance = true
		return
	end
	
	-- Unemployed - need to buy own insurance or go without
	if state.Flags.has_health_insurance then
		-- Self-paid insurance: ~$6000/year for individual
		local insuranceCost = 6000
		if state.Age >= 50 then
			insuranceCost = 9000 -- Higher premiums for older adults
		end
		
		if (state.Money or 0) >= insuranceCost then
			state.Money = state.Money - insuranceCost
		else
			-- Can't afford insurance
			state.Flags.has_health_insurance = nil
			state.Flags.uninsured = true
		end
	else
		-- Uninsured - risk of catastrophic costs
		state.Flags.uninsured = true
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #31: Car Loan Payment System
-- Vehicle purchases can be financed with loans that need monthly payments
-- Without this, car loans are just flags with no financial impact
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:applyCarLoanPayments(state)
	state.Flags = state.Flags or {}
	
	local carLoanBalance = state.Flags.car_loan_balance or 0
	if carLoanBalance <= 0 then
		return
	end
	
	-- Car loan interest is typically 4-10% APR
	local interestRate = state.Flags.bad_credit and 0.12 or 0.06 -- Higher rate if bad credit
	local monthlyPayment = state.Flags.car_loan_payment or math.floor(carLoanBalance / 48) -- 4-year loan default
	local annualInterest = math.floor(carLoanBalance * interestRate)
	local annualPayment = monthlyPayment * 12
	
	local money = state.Money or 0
	
	if money >= annualPayment then
		state.Money = money - annualPayment
		-- Principal reduction (payment minus interest portion)
		local principalPaid = math.max(0, annualPayment - annualInterest)
		state.Flags.car_loan_balance = math.max(0, carLoanBalance - principalPaid)
		
		if state.Flags.car_loan_balance <= 0 then
			state.Flags.car_loan_balance = nil
			state.Flags.car_loan_payment = nil
			state.Flags.has_car_loan = nil
			self:logYearEvent(state, "financial",
				"🚗 Car loan paid off! The vehicle is fully yours!", "🎉")
		end
	else
		-- Can't afford car payment
		state.Flags.car_payment_trouble = true
		-- Repo risk
		local repoChance = 0.20
		if RANDOM:NextNumber() < repoChance then
			-- Car repossessed
			if state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0 then
				-- Remove the financed vehicle
				for i, v in ipairs(state.Assets.Vehicles) do
					if v.financed then
						table.remove(state.Assets.Vehicles, i)
						break
					end
				end
			end
			state.Flags.car_loan_balance = nil
			state.Flags.car_loan_payment = nil
			state.Flags.has_car_loan = nil
			state.Flags.car_repossessed = true
			state.Flags.bad_credit = true
			self:logYearEvent(state, "financial",
				"🚗 Car repossessed! Couldn't make the payments.", "😔")
		else
			self:logYearEvent(state, "financial",
				"🚗 Warning: Struggling to make car payments!", "⚠️")
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #32: Addiction System with Consequences
-- Addictions should have escalating consequences over time
-- Without this, addictions are just flags with no gameplay impact
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:processAddictions(state)
	state.Flags = state.Flags or {}
	state.Stats = state.Stats or {}
	
	local addictions = {
		smoking = {
			healthCost = 2,
			moneyCost = 1500, -- Pack-a-day habit
			quitDifficulty = 0.15,
		},
		heavy_drinking = {
			healthCost = 3,
			happinessCost = 2,
			moneyCost = 2500,
			quitDifficulty = 0.12,
		},
		alcoholic = {
			healthCost = 5,
			happinessCost = 4,
			moneyCost = 4000,
			quitDifficulty = 0.08,
			canLoseJob = true,
		},
		gambling_addiction = {
			happinessCost = 5,
			moneyCost = function(state) return math.floor((state.Money or 0) * 0.20) end, -- 20% of wealth
			quitDifficulty = 0.10,
		},
		substance_user = {
			healthCost = 4,
			happinessCost = 3,
			moneyCost = 3000,
			quitDifficulty = 0.10,
			canGetArrested = true,
		},
		substance_addict = {
			healthCost = 8,
			happinessCost = 6,
			smartsCost = 2,
			moneyCost = 8000,
			quitDifficulty = 0.05,
			canGetArrested = true,
			canOverdose = true,
		},
	}
	
	for addictionName, addiction in pairs(addictions) do
		if state.Flags[addictionName] then
			-- Apply health cost
			if addiction.healthCost then
				state.Stats.Health = clamp((state.Stats.Health or 50) - addiction.healthCost, 0, 100)
			end
			
			-- Apply happiness cost
			if addiction.happinessCost then
				state.Stats.Happiness = clamp((state.Stats.Happiness or 50) - addiction.happinessCost, 0, 100)
			end
			
			-- Apply smarts cost (brain damage from substance abuse)
			if addiction.smartsCost then
				state.Stats.Smarts = clamp((state.Stats.Smarts or 50) - addiction.smartsCost, 0, 100)
			end
			
			-- Apply money cost
			local moneyCost = addiction.moneyCost
			if type(moneyCost) == "function" then
				moneyCost = moneyCost(state)
			end
			state.Money = math.max(0, (state.Money or 0) - moneyCost)
			
			-- Chance to lose job
			if addiction.canLoseJob and state.CurrentJob and RANDOM:NextNumber() < 0.15 then
				state.CurrentJob = nil
				state.Flags.employed = nil
				state.Flags.has_job = nil
				state.Flags.fired_for_addiction = true
				self:logYearEvent(state, "career",
					"💼 Lost job due to addiction problems.", "😔")
			end
			
			-- Chance to get arrested (illegal substances)
			if addiction.canGetArrested and RANDOM:NextNumber() < 0.08 then
				state.Flags.arrested = true
				state.Flags.criminal_record = true
				self:logYearEvent(state, "legal",
					"🚔 Arrested for illegal activity!", "⚠️")
			end
			
			-- Chance to overdose (severe addiction)
			if addiction.canOverdose and RANDOM:NextNumber() < 0.03 then
				state.Stats.Health = clamp((state.Stats.Health or 50) - 30, 0, 100)
				if state.Stats.Health <= 0 then
					state.Flags.dead = true
					state.DeathReason = "Substance overdose"
				else
					state.Flags.overdose_survivor = true
					self:logYearEvent(state, "health",
						"💊 Overdosed but survived. Wake-up call.", "🏥")
				end
			end
			
			-- Random chance to try to quit
			if RANDOM:NextNumber() < addiction.quitDifficulty then
				state.Flags[addictionName] = nil
				state.Flags[addictionName .. "_recovered"] = true
				self:logYearEvent(state, "health",
					string.format("🎉 Overcame %s! A new chapter begins.", addictionName:gsub("_", " ")), "💪")
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #35: Natural Death System
-- Players should be able to die from old age or very low health
-- Without this, players are effectively immortal
-- ═══════════════════════════════════════════════════════════════════════════════
function LifeBackend:checkNaturalDeath(state)
	-- Already dead
	if state.Flags and state.Flags.dead then
		return
	end
	
	state.Stats = state.Stats or {}
	state.Flags = state.Flags or {}
	local age = state.Age or 0
	local health = state.Stats.Health or 50
	
	-- Health-based death (very low health)
	if health <= 0 then
		state.Flags.dead = true
		state.DeathReason = state.DeathReason or "Health complications"
		state.DeathAge = age
		state.DeathYear = state.Year
		return
	end
	
	-- Critical health warning
	if health <= 10 then
		self:logYearEvent(state, "health",
			"⚠️ Health is critical! Seek medical attention immediately.", "🏥")
	end
	
	-- Age-based death chance (increases with age)
	if age >= 65 then
		local baseMortality = 0 -- No random death before 65
		
		-- Life expectancy calculations
		-- 65-70: Very low chance
		-- 70-80: Low chance
		-- 80-90: Moderate chance
		-- 90-100: High chance
		-- 100+: Very high chance
		
		if age >= 65 and age < 70 then
			baseMortality = 0.005 -- 0.5% per year
		elseif age >= 70 and age < 80 then
			baseMortality = 0.02 -- 2% per year
		elseif age >= 80 and age < 90 then
			baseMortality = 0.06 -- 6% per year
		elseif age >= 90 and age < 100 then
			baseMortality = 0.15 -- 15% per year
		elseif age >= 100 then
			baseMortality = 0.30 -- 30% per year
		end
		
		-- Health modifies mortality
		-- Good health (>70) reduces mortality by 50%
		-- Poor health (<30) increases mortality by 100%
		local healthModifier = 1.0
		if health > 70 then
			healthModifier = 0.5
		elseif health < 30 then
			healthModifier = 2.0
		end
		
		-- Lifestyle factors
		local lifestyleModifier = 1.0
		if state.Flags.fitness_enthusiast or state.Flags.healthy_lifestyle then
			lifestyleModifier = lifestyleModifier * 0.7 -- 30% reduction
		end
		if state.Flags.smoking or state.Flags.heavy_drinking then
			lifestyleModifier = lifestyleModifier * 1.5 -- 50% increase
		end
		if state.Flags.substance_addict or state.Flags.alcoholic then
			lifestyleModifier = lifestyleModifier * 2.0 -- 100% increase
		end
		
		local finalMortality = baseMortality * healthModifier * lifestyleModifier
		
		if RANDOM:NextNumber() < finalMortality then
			state.Flags.dead = true
			state.DeathAge = age
			state.DeathYear = state.Year
			
			-- Generate death reason based on age/health
			local deathReasons
			if age >= 90 then
				deathReasons = {
					"Natural causes",
					"Passed peacefully in sleep",
					"Old age",
					"Heart gave out",
				}
			elseif health < 30 then
				deathReasons = {
					"Health complications",
					"Organ failure",
					"Medical emergency",
					"Chronic illness",
				}
			else
				deathReasons = {
					"Natural causes",
					"Heart attack",
					"Stroke",
					"Unexpected illness",
				}
			end
			
			state.DeathReason = deathReasons[RANDOM:NextInteger(1, #deathReasons)]
		end
	end
end

function LifeBackend:generateEvent(player, state)
	local triggers = {}
	if state.Age < 13 then
		table.insert(triggers, "childhood")
	elseif state.Age < 18 then
		table.insert(triggers, "teen")
	end

	if state.CurrentJob then
		local job = JobCatalog[state.CurrentJob.id or state.CurrentJob]
		if job and job.category then
			table.insert(triggers, "career_" .. job.category)
		end
	end

	-- Criminal and Black Hat Hacker careers trigger crime events
	if state.CurrentJob then
		local job = JobCatalog[state.CurrentJob.id or state.CurrentJob]
		if job and (job.category == "criminal" or (job.category == "hacker" and job.illegal)) then
			table.insert(triggers, "crime")
		end
	end
	
	-- Criminal story path also triggers crime events
	if state.ActivePath == "criminal" then
		table.insert(triggers, "crime")
	end

	if state.Relationships and state.Relationships.partner then
		table.insert(triggers, "romance")
	end

	local pool = flattenEventPools(triggers)
	return chooseRandom(pool)
end

-- ============================================================================
-- CRITICAL FIX: Text variable replacement for dynamic content in events
-- Replaces placeholders like {{PARTNER_NAME}}, {{PLAYER_NAME}}, {{AGE}}, etc.
-- ============================================================================
function LifeBackend:replaceTextVariables(text, state)
	if not text or type(text) ~= "string" then
		return text
	end
	
	local result = text
	
	-- Partner name replacement
	if state.Relationships and state.Relationships.partner then
		local partnerName = state.Relationships.partner.name or "your partner"
		result = result:gsub("{{PARTNER_NAME}}", partnerName)
		result = result:gsub("{{PARTNER}}", partnerName)
		result = result:gsub("your partner", partnerName) -- Also replace generic "your partner" with actual name
		result = result:gsub("Your partner", partnerName)
	else
		result = result:gsub("{{PARTNER_NAME}}", "your partner")
		result = result:gsub("{{PARTNER}}", "someone special")
	end
	
	-- Player name replacement  
	local playerName = state.Name or "You"
	local honorific = (state.Gender == "female") and "Ms." or "Mr."
	
	-- CRITICAL FIX: Replace combined patterns FIRST before individual replacements
	result = result:gsub("Mr%./Ms%. %[YOUR NAME%]", honorific .. " " .. playerName)
	result = result:gsub("Mr%./Ms%. {{NAME}}", honorific .. " " .. playerName)
	result = result:gsub("Mr%./Ms%. {{PLAYER_NAME}}", honorific .. " " .. playerName)
	
	-- Then replace standalone patterns
	result = result:gsub("{{PLAYER_NAME}}", playerName)
	result = result:gsub("{{NAME}}", playerName)
	result = result:gsub("%[YOUR NAME%]", playerName)
	result = result:gsub("%[your name%]", playerName)
	result = result:gsub("Mr%./Ms%.", honorific)
	
	-- Age replacement
	local age = state.Age or 0
	result = result:gsub("{{AGE}}", tostring(age))
	
	-- Job/company replacement
	if state.CurrentJob then
		result = result:gsub("{{JOB_NAME}}", state.CurrentJob.name or "your job")
		result = result:gsub("{{COMPANY}}", state.CurrentJob.company or "your employer")
	end
	
	-- Mother/Father name replacement
	-- CRITICAL FIX: Ultra-robust relationship name handling with multiple fallbacks
	local motherName = "Mom"
	local fatherName = "Dad"
	
	-- Try to get parent names from relationships
	local success, extractedNames = pcall(function()
		if state.Relationships then
			-- Try multiple ways to access relationships (in case of different storage formats)
			local mother = state.Relationships.mother or state.Relationships["mother"]
			local father = state.Relationships.father or state.Relationships["father"]
			
			local extractedMom = "Mom"
			local extractedDad = "Dad"
			
			if mother and type(mother) == "table" then
				extractedMom = mother.name or mother.Name or "Mom"
			end
			if father and type(father) == "table" then
				extractedDad = father.name or father.Name or "Dad"
			end
			
			return { mom = extractedMom, dad = extractedDad }
		end
		return { mom = "Mom", dad = "Dad" }
	end)
	
	if success and extractedNames then
		motherName = extractedNames.mom or "Mom"
		fatherName = extractedNames.dad or "Dad"
	end
	
	-- CRITICAL FIX: Friend name lookup with pcall protection
	if state.Relationships then
		pcall(function()
			for relId, rel in pairs(state.Relationships) do
				if type(rel) == "table" and rel.type == "friend" then
					result = result:gsub("{{FRIEND_NAME}}", rel.name or "your friend")
					break
				end
			end
		end)
	end
	
	-- CRITICAL FIX: Always replace placeholders with multiple pattern variations
	-- This prevents {{FATHER_NAME}} from appearing literally in game text
	-- Try both escaped and unescaped patterns for maximum compatibility
	result = result:gsub("{{MOTHER_NAME}}", motherName)
	result = result:gsub("{{FATHER_NAME}}", fatherName)
	-- Escaped pattern versions (Lua pattern special chars)
	result = result:gsub("%%{%%{MOTHER_NAME%%}%%}", motherName)
	result = result:gsub("%%{%%{FATHER_NAME%%}%%}", fatherName)
	-- Generic parent terms
	result = result:gsub("Your mother", motherName)
	result = result:gsub("Your father", fatherName)
	result = result:gsub("your mother", motherName:lower())
	result = result:gsub("your father", fatherName:lower())
	result = result:gsub("Your dad", fatherName)
	result = result:gsub("your dad", fatherName:lower())
	result = result:gsub("Your mom", motherName)
	result = result:gsub("your mom", motherName:lower())
	
	-- Fallback for friend name if no friend found
	result = result:gsub("{{FRIEND_NAME}}", "your friend")
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Add more dynamic placeholders for realistic events
	-- These prevent hardcoded text like "You're 38 with 2 kids"
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Money/salary replacement
	local money = state.Money or 0
	result = result:gsub("{{MONEY}}", formatMoney(money))
	result = result:gsub("{{SAVINGS}}", formatMoney(money))
	if state.CurrentJob then
		result = result:gsub("{{SALARY}}", formatMoney(state.CurrentJob.salary or 0))
		result = result:gsub("{{COMPANY}}", state.CurrentJob.company or "your employer")
	else
		-- CRITICAL FIX: Fallback for SALARY and COMPANY when unemployed
		result = result:gsub("{{SALARY}}", "$0")
		result = result:gsub("{{COMPANY}}", "your last employer")
	end
	
	-- Family status replacement
	local familyParts = {}
	if state.Flags and (state.Flags.has_child or state.Flags.parent) then
		local childCount = state.ChildCount or 0
		if childCount > 0 then
			table.insert(familyParts, childCount == 1 and "a child" or (childCount .. " kids"))
		else
			table.insert(familyParts, "children")
		end
	end
	if state.Flags and (state.Flags.married or state.Flags.has_partner) then
		table.insert(familyParts, "a spouse")
	end
	if state.Assets and state.Assets.Properties and #state.Assets.Properties > 0 then
		table.insert(familyParts, "a mortgage")
	end
	
	local familyStatus = ""
	if #familyParts > 0 then
		familyStatus = "You're " .. tostring(age) .. " with " .. table.concat(familyParts, " and ") .. "."
	else
		familyStatus = "You're " .. tostring(age) .. " years old."
	end
	result = result:gsub("{{FAMILY_STATUS}}", familyStatus)
	
	-- Life stage
	local stage = "adult"
	if age < 5 then stage = "toddler"
	elseif age < 13 then stage = "child"
	elseif age < 18 then stage = "teenager"
	elseif age < 30 then stage = "young adult"
	elseif age < 50 then stage = "adult"
	elseif age < 65 then stage = "middle-aged"
	else stage = "senior"
	end
	result = result:gsub("{{LIFE_STAGE}}", stage)
	
	-- Years at job
	if state.CareerInfo and state.CareerInfo.yearsAtJob then
		result = result:gsub("{{YEARS_AT_JOB}}", tostring(state.CareerInfo.yearsAtJob))
	else
		result = result:gsub("{{YEARS_AT_JOB}}", "several")
	end
	
	return result
end

function LifeBackend:presentEvent(player, eventDef, feedText)
	if not eventDef then
		self:pushState(player, feedText)
		return
	end
	
	local state = self:getState(player)

	local eventId = (eventDef.id or "event") .. "_" .. HttpService:GenerateGUID(false)
	
	-- CRITICAL FIX: Process getDynamicText for events with dynamic content
	local eventText = eventDef.text
	if eventDef.getDynamicText and type(eventDef.getDynamicText) == "function" then
		local success, dynamicData = pcall(eventDef.getDynamicText, state)
		if success and dynamicData then
			if dynamicData.text then
				eventText = dynamicData.text
			end
			-- Store dynamic data for use in choice resolution
			eventDef._dynamicData = dynamicData
		end
	end
	
	-- CRITICAL FIX: Replace text variables with actual names
	local processedText = self:replaceTextVariables(eventText, state)
	local processedTitle = self:replaceTextVariables(eventDef.title, state)
	local processedQuestion = self:replaceTextVariables(eventDef.question or "What will you do?", state)
	
	local eventPayload = {
		id = eventId,
		title = processedTitle,
		emoji = eventDef.emoji,
		text = processedText,
		question = processedQuestion,
		category = eventDef.category or "life",
		choices = {},
	}

	for index, choice in ipairs(eventDef.choices or {}) do
		eventPayload.choices[index] = {
			index = index,
			text = self:replaceTextVariables(choice.text or ("Choice " .. index), state),
			minigame = choice.minigame,
		}
	end

	local pending = self.pendingEvents[player.UserId] or {}
	pending.activeEventId = eventId
	pending.definition = eventDef
	pending.choices = eventDef.choices
	pending.timestamp = os.clock()
	pending.feedText = feedText or pending.feedText
	self.pendingEvents[player.UserId] = pending

	self.remotes.PresentEvent:FireClient(player, eventPayload, feedText)
end

-- ============================================================================
-- CRITICAL FIX: Log significant events that occur during the year
-- These get used in the year summary instead of random generic messages
-- ============================================================================
function LifeBackend:logYearEvent(state, eventType, description, emoji)
	state.YearLog = state.YearLog or {}
	table.insert(state.YearLog, {
		type = eventType,
		text = description,
		emoji = emoji or "📌",
		age = state.Age,
	})
end

-- ============================================================================
-- CRITICAL FIX: BitLife-style year summaries using ACTUAL event history
-- Uses logged events from the year instead of random generic messages
-- ============================================================================
function LifeBackend:generateYearSummary(state)
	local age = state.Age or 0
	local summaryParts = {}
	local emoji = "📅"
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: First check for actual logged events from this year
	-- This replaces random generic messages with real event descriptions
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.YearLog and #state.YearLog > 0 then
		-- Use actual events that happened
		for _, logEntry in ipairs(state.YearLog) do
			if logEntry.text and logEntry.text ~= "" then
				table.insert(summaryParts, logEntry.text)
				if logEntry.emoji then
					emoji = logEntry.emoji
				end
			end
		end
		-- Clear the year log after using it
		state.YearLog = {}
		
		-- If we have actual events, use them and skip random filler
		if #summaryParts > 0 then
			local maxParts = math.min(#summaryParts, 3)
			local finalParts = {}
			for i = 1, maxParts do
				table.insert(finalParts, summaryParts[i])
			end
			return string.format("%s Age %d: %s", emoji, age, table.concat(finalParts, " "))
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- Fallback: No specific events logged, use context-aware generic summary
	-- These should only appear when genuinely nothing notable happened
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Check for specific life situations first (these ARE real, not random)
	if state.Flags then
		-- Divorce just happened
		if state.Flags.parents_divorced and not state.Flags.divorce_acknowledged then
			table.insert(summaryParts, "Your parents have separated. Your family dynamic has changed.")
			emoji = "💔"
			state.Flags.divorce_acknowledged = true
		end
		
		-- Just got married
		if state.Flags.just_married then
			local partnerName = state.Relationships and state.Relationships.partner and state.Relationships.partner.name or "your partner"
			table.insert(summaryParts, string.format("You married %s!", partnerName))
			emoji = "💒"
			state.Flags.just_married = nil
		end
		
		-- Just had a baby
		if state.Flags.just_had_baby then
			table.insert(summaryParts, "You became a parent!")
			emoji = "👶"
			state.Flags.just_had_baby = nil
		end
		
		-- Just got promoted
		if state.Flags.just_promoted then
			table.insert(summaryParts, "You earned a promotion at work!")
			emoji = "📈"
			state.Flags.just_promoted = nil
		end
	end
	
	-- If we found real situation-based summaries, return them
	if #summaryParts > 0 then
		return string.format("%s Age %d: %s", emoji, age, table.concat(summaryParts, " "))
	end
	
	-- Age-based generic context (only if nothing specific happened)
	local ageContext = ""
	if age <= 4 then
		local toddlerLines = {
			"Another year of growing up.",
			"Learning new things every day.",
			"Time flies when you're little.",
		}
		ageContext = toddlerLines[RANDOM:NextInteger(1, #toddlerLines)]
		emoji = "👶"
	elseif age <= 12 then
		local childLines = {
			"School keeps you busy.",
			"Another year of growing up.",
			"Childhood continues.",
		}
		ageContext = childLines[RANDOM:NextInteger(1, #childLines)]
		emoji = "🧒"
	elseif age <= 17 then
		local teenLines = {
			"Another year of high school.",
			"Teen life continues.",
			"Growing up fast.",
		}
		ageContext = teenLines[RANDOM:NextInteger(1, #teenLines)]
		emoji = "🎒"
	elseif age <= 25 then
		local youngAdultLines = {
			"Building your future.",
			"Young adulthood continues.",
			"Finding your path.",
		}
		ageContext = youngAdultLines[RANDOM:NextInteger(1, #youngAdultLines)]
		emoji = "🌟"
	elseif age <= 40 then
		local adultLines = {
			"Life continues.",
			"Staying busy.",
			"Making progress.",
		}
		ageContext = adultLines[RANDOM:NextInteger(1, #adultLines)]
		emoji = "💼"
	elseif age <= 60 then
		local middleAgeLines = {
			"Wisdom comes with age.",
			"You've learned what matters most.",
			"Life experience is your greatest asset.",
			"The years fly by faster now.",
			"You're in the prime of your life.",
		}
		ageContext = middleAgeLines[RANDOM:NextInteger(1, #middleAgeLines)]
		emoji = "🍷"
	else
		local seniorLines = {
			"You've lived a full life.",
			"Every day is a blessing.",
			"You have stories to tell.",
			"Reflecting on a life well lived.",
			"Cherishing the golden years.",
		}
		ageContext = seniorLines[RANDOM:NextInteger(1, #seniorLines)]
		emoji = "👴"
	end
	
	table.insert(summaryParts, ageContext)
	
	-- Relationship status
	if state.Relationships and state.Relationships.partner then
		local partner = state.Relationships.partner
		local partnerName = partner.name or "your partner"
		local role = partner.role or "Partner"
		
		if state.Flags and state.Flags.married then
			local marriedLines = {
				string.format("Life with %s is good.", partnerName),
				string.format("You and %s are building a life together.", partnerName),
				string.format("Marriage keeps things interesting.", partnerName),
			}
			table.insert(summaryParts, marriedLines[RANDOM:NextInteger(1, #marriedLines)])
		elseif state.Flags and state.Flags.engaged then
			table.insert(summaryParts, string.format("You can't wait to marry %s.", partnerName))
		elseif state.Flags and state.Flags.dating then
			local datingLines = {
				string.format("Dating %s is going well.", partnerName),
				string.format("You enjoy spending time with %s.", partnerName),
			}
			table.insert(summaryParts, datingLines[RANDOM:NextInteger(1, #datingLines)])
		end
	end
	
	-- Job status (only for working-age adults)
	if age >= 18 then
		if state.CurrentJob then
			local job = state.CurrentJob
			if state.CareerInfo and (state.CareerInfo.yearsAtJob or 0) > 0 then
				local years = state.CareerInfo.yearsAtJob
				if years >= 10 then
					table.insert(summaryParts, string.format("You've been at %s for %d years now.", job.company, years))
				elseif years >= 5 then
					table.insert(summaryParts, string.format("You're well established at %s.", job.company))
				end
			else
				-- Just mention they have a job occasionally
				if RANDOM:NextNumber() < 0.3 then
					table.insert(summaryParts, string.format("Work at %s keeps you busy.", job.company))
				end
			end
		elseif age < 65 and not (state.Flags and (state.Flags.retired or state.Flags.in_school)) then
			if RANDOM:NextNumber() < 0.5 then
				table.insert(summaryParts, "You're currently between jobs.")
			end
		end
	end
	
	-- Money situation
	local money = state.Money or 0
	if money < 100 and age >= 18 then
		if RANDOM:NextNumber() < 0.4 then
			table.insert(summaryParts, "Money is tight right now.")
		end
	elseif money > 1000000 then
		if RANDOM:NextNumber() < 0.3 then
			table.insert(summaryParts, "Financial success feels good.")
		end
	end
	
	-- Health comments
	local health = state.Stats and state.Stats.Health or 50
	if health < 30 then
		table.insert(summaryParts, "Your health concerns you.")
	elseif health > 85 and RANDOM:NextNumber() < 0.2 then
		table.insert(summaryParts, "You're feeling great!")
	end
	
	-- Happiness comments
	local happiness = state.Stats and state.Stats.Happiness or 50
	if happiness < 25 then
		if RANDOM:NextNumber() < 0.5 then
			local sadLines = {
				"Things feel harder lately.",
				"You're going through a rough patch.",
				"Life feels heavy sometimes.",
			}
			table.insert(summaryParts, sadLines[RANDOM:NextInteger(1, #sadLines)])
		end
	elseif happiness > 80 and RANDOM:NextNumber() < 0.3 then
		local happyLines = {
			"Life is treating you well.",
			"You're in a good place.",
			"Happiness comes easy these days.",
		}
		table.insert(summaryParts, happyLines[RANDOM:NextInteger(1, #happyLines)])
	end
	
	-- Prison
	if state.InJail then
		emoji = "🔒"
		-- MINOR FIX: Use %.1f for consistent decimal formatting
		summaryParts = { string.format("Behind bars. %.1f years remaining.", state.JailYearsLeft or 0) }
	end
	
	-- Combine parts (max 2-3 sentences to avoid clutter)
	local maxParts = math.min(#summaryParts, 3)
	local finalParts = {}
	for i = 1, maxParts do
		table.insert(finalParts, summaryParts[i])
	end
	
	local summary = table.concat(finalParts, " ")
	if summary == "" then
		summary = "Another year passes."
	end
	
	return string.format("%s Age %d: %s", emoji, age, summary)
end

function LifeBackend:handleAgeUp(player)
	local state = self:getState(player)
	if not state or state.awaitingDecision or (state.Flags and state.Flags.dead) then
		if state and state.Flags and state.Flags.dead then
			debugPrint("Age up ignored for dead player", player.Name)
		end
		return
	end

	debugPrint(string.format("Age up requested by %s (Age %d, Year %d)", player.Name, state.Age or -1, state.Year or 0))

	local oldAge = state.Age
	if state.AdvanceAge then
		state:AdvanceAge()
	else
		state.Age = (state.Age or 0) + 1
		state.Year = (state.Year or 2025) + 1
	end

	self:advanceRelationships(state)
	self:updateEducationProgress(state)
	self:tickCareer(state)
	self:collectPropertyIncome(state) -- CRITICAL FIX: Collect passive income from owned properties
	self:tickVehicleDepreciation(state) -- CRITICAL FIX #10: Vehicles lose value over time
	self:tickInvestments(state) -- CRITICAL FIX #11: Investments fluctuate in value
	self:applyLivingExpenses(state) -- CRITICAL FIX #12: Annual cost of living
	self:applyHabitEffects(state) -- CRITICAL FIX #13: Health effects from habits
	self:tickFame(state) -- CRITICAL FIX #14: Fame decays without maintenance
	self:applyDebtInterest(state) -- CRITICAL FIX #15: Student loan interest
	self:applyEducationCosts(state) -- CRITICAL FIX #36: Annual education costs
	self:tickPetLifecycle(state) -- CRITICAL FIX #16: Pets age and can pass away
	self:updateCareerSkills(state) -- CRITICAL FIX #17: Track career skills
	self:applyRelationshipDecay(state) -- CRITICAL FIX #18: Relationships decay without maintenance
	self:tickPropertyValues(state) -- CRITICAL FIX #19: Property values change
	self:checkBankruptcy(state) -- CRITICAL FIX #20: Check for financial distress
	self:applyCreditCardInterest(state) -- CRITICAL FIX #21: Credit card debt grows with interest
	self:collectBusinessIncome(state) -- CRITICAL FIX #22: Business income/losses
	self:applyMortgagePayments(state) -- CRITICAL FIX #23: Mortgage payments
	self:ageRelationships(state) -- CRITICAL FIX #24: Partners and family age with player
	self:applyHealthInsuranceCosts(state) -- CRITICAL FIX #25: Health insurance costs
	self:applyCarLoanPayments(state) -- CRITICAL FIX #31: Car loan payments
	self:processAddictions(state) -- CRITICAL FIX #32: Addiction consequences
	local mobEvents = MobSystem:onYearPass(state)
	if mobEvents and #mobEvents > 0 then
		for _, event in ipairs(mobEvents) do
			if event.message then
				appendFeed(state, event.message)
			end
		end
	end
	
	-- ════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #2: Process yearly ROYALTY updates (popularity, succession, duties)
	-- Without this, royal players never advanced to King, never got jubilees, etc.!
	-- ════════════════════════════════════════════════════════════════════════════
	if RoyaltyEvents and state.RoyalState and state.RoyalState.isRoyal then
		local royalEvents = RoyaltyEvents.processYearlyRoyalUpdates(state)
		if royalEvents and #royalEvents > 0 then
			for _, event in ipairs(royalEvents) do
				if event.message then
					appendFeed(state, event.message)
				end
			end
		end
		
		-- CRITICAL FIX #10: Check for throne succession (become monarch if next in line)
		if state.RoyalState.lineOfSuccession == 1 and not state.RoyalState.isMonarch then
			-- 3% chance per year the monarch passes and you inherit
			if state.Age >= 25 and RANDOM:NextNumber() < 0.03 then
				local success, msg = RoyaltyEvents.becomeMonarch(state)
				if success then
					appendFeed(state, msg)
					state.Flags.throne_ready = nil
					state.Flags.became_monarch = true
				end
			end
		end
		
		-- CRITICAL FIX #19: Royal wealth management - allowance/expenses
		if state.RoyalState.isRoyal then
			local royalIncome = 0
			if state.RoyalState.isMonarch then
				royalIncome = math.random(5000000, 20000000) -- Monarchs get massive income
			else
				royalIncome = math.random(500000, 2000000) -- Princes/Princesses get allowance
			end
			state.Money = (state.Money or 0) + royalIncome
			state.RoyalState.wealth = state.Money
		end
	end
	
	-- ════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #3: Process yearly CELEBRITY/FAME updates (promotions, events)
	-- Without this, famous players never advanced in their careers!
	-- ════════════════════════════════════════════════════════════════════════════
	if CelebrityEvents and state.FameState and state.FameState.careerPath then
		local fameEvents = CelebrityEvents.processYearlyFameUpdates(state)
		if fameEvents and #fameEvents > 0 then
			for _, event in ipairs(fameEvents) do
				if event.message then
					appendFeed(state, event.message)
				end
				-- Handle career promotions
				if event.type == "promotion" then
					state.Flags.got_promotion = true
				end
			end
		end
		
		-- CRITICAL FIX #16: Random endorsement deals for famous players
		if state.Fame and state.Fame >= 40 and RANDOM:NextNumber() < 0.15 then
			local endorsementValue = math.floor(state.Fame * RANDOM:NextInteger(5000, 20000))
			state.Money = (state.Money or 0) + endorsementValue
			if state.FameState.endorsements then
				table.insert(state.FameState.endorsements, {
					year = state.Year,
					value = endorsementValue,
				})
			end
			appendFeed(state, string.format("💰 You received a $%s endorsement deal!", formatMoney(endorsementValue)))
		end
	end
	self:checkNaturalDeath(state) -- CRITICAL FIX #35: Check for natural death
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: IMMEDIATELY handle death if checkNaturalDeath marked player as dead
	-- Without this, player dies but never sees the death screen!
	-- The bug was: checkNaturalDeath sets Flags.dead=true but Health could still be >0
	-- So the health check at the end of handleAgeUp would pass, continuing normal flow
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.Flags and state.Flags.dead then
		state.Health = 0
		state.Stats = state.Stats or {}
		state.Stats.Health = 0
		local deathFeed = string.format("💀 Age %d: %s", state.Age, state.DeathReason or "You passed away.")
		state.awaitingDecision = false
		self:completeAgeCycle(player, state, deathFeed)
		return
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #4: Pay pension to retired players
	-- Retirees should receive annual pension income based on their career history
	-- Without this, retired players had NO income and would slowly go broke!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.Flags and state.Flags.retired then
		local pensionAmount = 0
		
		-- Get pension from stored amount (set during retirement event)
		if state.Flags.pension_amount and type(state.Flags.pension_amount) == "number" then
			pensionAmount = state.Flags.pension_amount
		else
			-- Fallback: Calculate based on career info
			if state.CareerInfo and state.CareerInfo.lastJob then
				local lastSalary = state.CareerInfo.lastJob.salary or 30000
				pensionAmount = math.floor(lastSalary * 0.4) -- 40% of last salary
			else
				pensionAmount = 15000 -- Minimum pension
			end
			-- Store for future years
			state.Flags.pension_amount = pensionAmount
		end
		
		-- Pay the pension
		if pensionAmount > 0 then
			self:addMoney(state, pensionAmount)
			debugPrint("Pension paid:", pensionAmount, "to retired player. New balance:", state.Money)
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Removed duplicate family aging and death logic!
	-- Family members are ALREADY aged and checked for death in advanceRelationships()
	-- Having it here too caused:
	--   1. Family members aging 2 years per player year (double speed!)
	--   2. Family members getting TWO death rolls per year (stacking mortality!)
	-- This was why the user's parents died when player was only 21-23 years old!
	-- The detailed death logic in advanceRelationships (lines 1767-1807) is preserved
	-- which has proper graduated death chances based on age.
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Decrement jail sentence each year and auto-release when complete
	-- Without this, prisoners would be stuck forever!
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.InJail and state.JailYearsLeft then
		state.JailYearsLeft = state.JailYearsLeft - 1
		
		if state.JailYearsLeft <= 0 then
			-- Sentence complete! Release the prisoner
			state.InJail = false
			state.JailYearsLeft = 0
			state.Flags.in_prison = nil
			state.Flags.incarcerated = nil
			state.Flags.ex_convict = true -- MINOR FIX: Mark as ex-convict for future events
			
			-- ═══════════════════════════════════════════════════════════════════════
			-- CRITICAL FIX #7: Resume education that was suspended during incarceration
			-- If player was in college before going to jail, they can now re-enroll
			-- ═══════════════════════════════════════════════════════════════════════
			if state.EducationData and state.EducationData.StatusBeforeJail == "enrolled" then
				state.EducationData.Status = "enrolled"
				state.EducationData.StatusBeforeJail = nil
				state.PendingFeed = "🎉 You've been released from prison! Time served. Your education has been reinstated."
			else
				state.PendingFeed = "🎉 You've been released from prison! Time served."
			end
			
			debugPrint("Player released from prison after completing sentence:", player.Name)
		else
			state.PendingFeed = string.format("📅 Prison: %.1f years remaining.", state.JailYearsLeft)
		end
	end

	state.Stats = state.Stats or {}
	state.Stats.Health = clamp((state.Stats.Health or 0) - RANDOM:NextInteger(0, 2))
	state.Stats.Happiness = clamp((state.Stats.Happiness or 0) + RANDOM:NextInteger(-1, 2))
	state.Stats.Smarts = clamp((state.Stats.Smarts or 0) + RANDOM:NextInteger(-1, 2))
	state.Health = state.Stats.Health
	state.Happiness = state.Stats.Happiness
	state.Smarts = state.Stats.Smarts

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Generate interesting BitLife-style year summaries instead of boring 
	-- "Another year passes" - Include relationship status, job, notable things happening
	-- ═══════════════════════════════════════════════════════════════════════════════
	local feedText
	if state.PendingFeed then
		feedText = string.format("Age %d: %s", state.Age, state.PendingFeed)
	else
		feedText = self:generateYearSummary(state)
	end
	state.PendingFeed = nil

	if state.Health <= 0 then
		state.awaitingDecision = false
		self:completeAgeCycle(player, state, feedText)
		return
	end

	-- BitLife style: ONE event per age up, not multiple stacked events
	local queue = {}

	-- Stage transition -> fold into feed text, not a separate choice event
	local transitionEvent = LifeStageSystem.getTransitionEvent(oldAge, state.Age)
	if transitionEvent then
		local stageName = transitionEvent.title or "a new stage"
		feedText = string.format("🎂 %s\n%s", transitionEvent.text or ("You entered " .. stageName), feedText)
	end

	-- Get just ONE event from the year queue (BitLife style)
	local yearlyEvents = LifeEvents.buildYearQueue(state, { maxEvents = 1 }) or {}
	if #yearlyEvents > 0 then
		local eventDef = yearlyEvents[1]
		eventDef.source = "lifeevents"
		table.insert(queue, eventDef)
	end

	local careerEvent = self:buildCareerEvent(state)
	if careerEvent then
		if #queue == 0 then
			table.insert(queue, careerEvent)
		elseif RANDOM:NextNumber() < 0.4 then
			queue[1] = careerEvent
		end
	end

	if #queue == 0 then
		state.awaitingDecision = false
		self:completeAgeCycle(player, state, feedText)
		return
	end

	if #queue > 0 then
		debugPrint(string.format("Event for %s: %s", player.Name, queue[1].id or "unknown"))
	end

	self.pendingEvents[player.UserId] = {
		queue = queue,
		cursor = 1,
		feedText = feedText,
	}
	state.awaitingDecision = true
	self:presentEvent(player, queue[1], feedText)
end

function LifeBackend:resetLife(player)
	debugPrint("Resetting life for", player.Name)
	-- CRITICAL FIX #15: Use createInitialState instead of raw LifeState.new
	-- This ensures the player gets proper family members, Bitizenship bonuses, etc.
	local newState = self:createInitialState(player)
	self.playerStates[player] = newState
	self.pendingEvents[player.UserId] = nil
	self:pushState(player, "A new life begins...")
end

function LifeBackend:completeAgeCycle(player, state, feedText, resultData)
	local deathInfo
	-- CRITICAL FIX: Check Flags.dead FIRST (set by checkNaturalDeath)
	-- This ensures natural deaths from old age are properly handled
	if state.Flags and state.Flags.dead then
		deathInfo = { died = true, cause = state.DeathReason or state.CauseOfDeath or "Natural causes" }
	elseif state.Health and state.Health <= 0 then
		deathInfo = { died = true, cause = "Health Failure" }
	else
		deathInfo = LifeStageSystem.checkDeath(state)
	end

	if deathInfo and deathInfo.died then
		state.Flags = state.Flags or {}
		if state.SetFlag then
			state:SetFlag("dead", true)
		else
			state.Flags.dead = true
		end
		state.CauseOfDeath = deathInfo.cause
		
		-- Build AAA-quality death summary
		local deathMeta = buildDeathMeta(state, deathInfo)
		
		-- Use the full obituary for the death popup
		feedText = deathMeta.obituary or string.format("You passed away from %s.", deathInfo.cause or "unknown causes")
		
		debugPrint(string.format("Player died: %s (Age %d) cause=%s", state.Name or player.Name, state.Age or -1, deathInfo.cause or "unknown"))
		resultData = {
			showPopup = true,
			emoji = "☠️",
			title = string.format("💀 %s (Age %d)", state.Name or "You", state.Age or 0),
			body = feedText,
			wasSuccess = false,
			fatal = true,
			cause = deathInfo.cause,
			deathMeta = deathMeta,
		}
	end

	self:pushState(player, feedText, resultData)
end

function LifeBackend:resolvePendingEvent(player, eventId, choiceIndex)
	local pending = self.pendingEvents[player.UserId]
	if not pending then
		return
	end
	if pending.activeEventId and pending.activeEventId ~= eventId then
		return
	end

	local eventDef
	if pending.queue then
		eventDef = pending.definition or pending.queue[pending.cursor]
	else
		eventDef = pending.definition
	end
	if not eventDef then
		return
	end

	local choices = eventDef.choices or {}
	local choice = choices[choiceIndex]
	if not choice then
		return
	end

	debugPrint(string.format("Resolving event %s for %s with choice #%d", eventDef.id or "unknown", player.Name, choiceIndex))

	local state = self:getState(player)
	if not state then
		return
	end

	-- CRITICAL FIX: Use feedText (what events use), then feed, then text
	local feedText = choice.feedText or choice.feed or choice.text or "Life continues..."
	local resultData
	local effectsSummary = choice.deltas or {}

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Minigame Integration for Career Events (Racing, Hacking, etc.)
	-- If choice triggers a minigame, store pending event and wait for minigame result
	-- ═══════════════════════════════════════════════════════════════════════════════
	if choice.triggerMinigame then
		-- Initialize pending minigame storage
		self.pendingMinigameEvents = self.pendingMinigameEvents or {}
		
		-- Store the event context for when minigame completes
		self.pendingMinigameEvents[player.UserId] = {
			eventDef = eventDef,
			choice = choice,
			choiceIndex = choiceIndex,
			feedText = feedText,
		}
		
		-- Tell client to start the minigame
		local minigamePayload = {
			type = choice.triggerMinigame,
			options = choice.minigameOptions or {},
			eventId = eventDef.id,
		}
		
		-- Clear the pending event queue but keep awaiting decision
		self.pendingEvents[player.UserId] = nil
		-- state.awaitingDecision stays true until minigame completes
		
		-- Fire the minigame start event to client
		if self.remotes.MinigameStart then
			self.remotes.MinigameStart:FireClient(player, minigamePayload)
		else
			-- Fallback: create the remote if it doesn't exist
			local minigameRemote = self:createRemote("MinigameStart", "RemoteEvent")
			minigameRemote:FireClient(player, minigamePayload)
		end
		
		debugPrint(string.format("Minigame triggered for %s: %s", player.Name, choice.triggerMinigame))
		return -- Wait for minigame result
	end

	-- CRITICAL: Track jail state BEFORE event processing to detect incarceration
	local wasInJailBefore = state.InJail or false

	if choice.effects or eventDef.source == "lifeevents" or eventDef.source == "stage" then
		local preStats = table.clone(state.Stats)
		local preMoney = state.Money
		local success, err = pcall(function()
			EventEngine.completeEvent(eventDef, choiceIndex, state)
		end)
		if not success then
			warn("[LifeBackend] Event resolution error:", err)
		end
		effectsSummary = {
			Happiness = (state.Stats.Happiness - preStats.Happiness),
			Health = (state.Stats.Health - preStats.Health),
			Smarts = (state.Stats.Smarts - preStats.Smarts),
			Looks = (state.Stats.Looks - preStats.Looks),
			Money = (state.Money - preMoney),
		}
	else
		self:applyStatChanges(state, choice.deltas)

		if choice.cost and choice.cost > 0 then
			self:addMoney(state, -choice.cost)
			effectsSummary = effectsSummary or {}
			effectsSummary.Money = (effectsSummary.Money or 0) - choice.cost
		end

		if choice.career then
			state.CareerInfo = state.CareerInfo or {}
			local info = state.CareerInfo
			info.performance = clamp((info.performance or 60) + (choice.career.performance or 0))
			info.promotionProgress = clamp((info.promotionProgress or 0) + (choice.career.progress or 0))
			if choice.career.salaryBonus and state.CurrentJob then
				local job = state.CurrentJob
				job.salary = math.floor((job.salary or 0) * (1 + choice.career.salaryBonus))
			end
		end

		if choice.relationships and choice.relationships.delta then
			for _, rel in pairs(state.Relationships or {}) do
				if type(rel) == "table" then
					rel.relationship = clamp((rel.relationship or 50) + choice.relationships.delta, 0, 100)
				end
			end
		end

		if choice.crime then
			local reward = RANDOM:NextInteger(choice.crime.reward[1], choice.crime.reward[2])
			self:addMoney(state, reward)
			effectsSummary = effectsSummary or {}
			effectsSummary.Money = (effectsSummary.Money or 0) + reward
		end
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Handle setFlags and clearFlags in the else branch too!
		-- Without this, dynamically created events (like prison escape) won't have
		-- their flags processed, causing players to stay stuck in prison, etc.
		-- ═══════════════════════════════════════════════════════════════════════════════
		state.Flags = state.Flags or {}
		
		-- Apply setFlags
		if choice.setFlags then
			for flagName, flagValue in pairs(choice.setFlags) do
				state.Flags[flagName] = flagValue
			end
		end
		
		-- Apply clearFlags (remove flags)
		if choice.clearFlags then
			for flagName, _ in pairs(choice.clearFlags) do
				state.Flags[flagName] = nil
			end
		end
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: Call eventDef.onComplete for dynamically created events
		-- This ensures custom logic (like freeing from prison) actually runs
		-- ═══════════════════════════════════════════════════════════════════════════════
		if eventDef.onComplete and type(eventDef.onComplete) == "function" then
			local success, err = pcall(function()
				eventDef.onComplete(state, choice, eventDef, {})
			end)
			if not success then
				warn("[LifeBackend] onComplete handler error:", err)
			end
		end
		
		-- Also support choice-level onResolve in else branch
		if choice.onResolve and type(choice.onResolve) == "function" then
			local success, err = pcall(function()
				choice.onResolve(state, choice, eventDef, {})
			end)
			if not success then
				warn("[LifeBackend] choice.onResolve handler error:", err)
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Log this event to the year log for accurate year summaries
	-- This ensures the year summary says what ACTUALLY happened, not random text
	-- ═══════════════════════════════════════════════════════════════════════════════
	if eventDef.id and eventDef.title then
		local logText = choice.feedText or choice.feed or choice.text or eventDef.title
		if logText and logText ~= "" then
			self:logYearEvent(state, eventDef.id, logText, eventDef.emoji)
		end
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Detect if player was JUST incarcerated by this event
	-- Override popup with jail-specific content so user sees "Busted!" not generic text
	-- ═══════════════════════════════════════════════════════════════════════════════
	local justGotIncarcerated = (not wasInJailBefore) and state.InJail
	local jailPopupBody = nil
	local jailPopupTitle = nil
	local jailPopupEmoji = nil

	if justGotIncarcerated then
		-- Player was caught during this event!
		-- Try to get the jail message from PendingFeed set by onResolve
		if state.PendingFeed and type(state.PendingFeed) == "string" and state.PendingFeed ~= "" then
			-- Check if the feed text is jail-related (contains relevant keywords)
			local feedLower = state.PendingFeed:lower()
			if feedLower:find("sentenced") or feedLower:find("jail") or feedLower:find("prison") 
				or feedLower:find("arrested") or feedLower:find("caught") or feedLower:find("years") then
				jailPopupBody = state.PendingFeed
			end
		end

		-- Fallback: construct a generic jail message if we couldn't find one
		if not jailPopupBody then
			local yearsText = state.JailYearsLeft and string.format("%.1f years", state.JailYearsLeft) or "some time"
			jailPopupBody = string.format("You were caught and sentenced to %s in prison!", yearsText)
		end

		jailPopupTitle = "Busted!"
		jailPopupEmoji = "🚔"
		feedText = jailPopupBody -- Also update the feed text for the feed display

		debugPrint(string.format("Player %s was incarcerated by event! Jail years: %.1f", player.Name, state.JailYearsLeft or 0))
	end

	-- CRITICAL FIX: Use PendingFeed (detailed outcome from onResolve) for popup body
	-- Fall back to feedText (short choice text) only if no detailed outcome was set
	local popupBody = jailPopupBody or state.PendingFeed or feedText
	if popupBody == nil or popupBody == "" then
		popupBody = "Something happened..."
	end
	
	resultData = {
		showPopup = true,
		emoji = jailPopupEmoji or eventDef.emoji,
		title = jailPopupTitle or eventDef.title,
		body = popupBody,
		happiness = effectsSummary.Happiness,
		health = effectsSummary.Health,
		smarts = effectsSummary.Smarts,
		looks = effectsSummary.Looks,
		money = effectsSummary.Money,
		wasSuccess = not justGotIncarcerated, -- Mark as failure if caught
	}

	if pending.queue then
		pending.cursor = pending.cursor + 1
		if pending.cursor <= #pending.queue then
			pending.definition = pending.queue[pending.cursor]
			self.pendingEvents[player.UserId] = pending
			debugPrint(string.format("Advancing to next event in queue (%d/%d) for %s", pending.cursor, #pending.queue, player.Name))
			self:presentEvent(player, pending.definition, pending.feedText)
			return
		else
			self.pendingEvents[player.UserId] = nil
			state.awaitingDecision = false
			debugPrint(string.format("Event queue complete for %s", player.Name))
			self:completeAgeCycle(player, state, pending.feedText or feedText, resultData)
			return
		end
	end

	self.pendingEvents[player.UserId] = nil
	state.awaitingDecision = false
	self:pushState(player, feedText, resultData)
end

-- ============================================================================
-- Activities / Crimes / Prison
-- ============================================================================

function LifeBackend:handleActivity(player, activityId, bonus)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "No life data loaded." }
	end
	if state.InJail then
		return { success = false, message = "You can't do that behind bars." }
	end
	local activity = ActivityCatalog[activityId]
	if not activity then
		return { success = false, message = "Unknown activity." }
	end

	local isEducationActivity = activity.educationProgram ~= nil

	-- CRITICAL FIX: Check age requirement for activities (like driver's license)
	if activity.requiresAge and (state.Age or 0) < activity.requiresAge then
		return { success = false, message = string.format("You must be at least %d years old.", activity.requiresAge) }
	end
	
	-- CRITICAL FIX: Check maximum age for activities (like returning to high school)
	if activity.maxAge and (state.Age or 0) > activity.maxAge then
		return { success = false, message = string.format("You're too old for this! (Max age: %d)", activity.maxAge) }
	end
	
	-- CRITICAL FIX: Check if blocked by existing flag (e.g., can't get license if already have one)
	state.Flags = state.Flags or {}
	if activity.blockedByFlag and state.Flags[activity.blockedByFlag] then
		return { success = false, message = "You've already done this!" }
	end
	
	-- CRITICAL FIX: Check if activity requires a specific flag (like dropout for GED)
	if activity.requiresFlag then
		if not state.Flags[activity.requiresFlag] then
			-- Provide helpful messages based on which flag is missing
			local helpfulMessage = "You don't meet the requirements for this."
			if activity.requiresFlag == "dropped_out_high_school" then
				helpfulMessage = "This is only for people who dropped out of high school."
			elseif activity.requiresFlag == "has_ged_or_diploma" then
				helpfulMessage = "You need a high school diploma or GED first."
			elseif activity.requiresFlag == "has_degree" then
				helpfulMessage = "You need a college degree first."
			end
			return { success = false, message = helpfulMessage }
		end
	end
	
	-- CRITICAL FIX: Check if this is a one-time activity that was already completed
	state.CompletedActivities = state.CompletedActivities or {}
	if activity.oneTime and not activity.skipCompletionTracking and state.CompletedActivities[activityId] then
		return { success = false, message = "You can only do this once!" }
	end

	local shouldChargeCost = (not isEducationActivity) and activity.cost and activity.cost > 0
	if shouldChargeCost and (state.Money or 0) < activity.cost then
		return { success = false, message = "You can't afford that right now." }
	end

	if shouldChargeCost then
		self:addMoney(state, -activity.cost)
	end

	local deltas = shallowCopy(activity.stats or {})
	if bonus then
		for stat, delta in pairs(deltas) do
			deltas[stat] = delta + math.ceil(delta * 0.5)
		end
	end

	self:applyStatChanges(state, deltas)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Handle setFlag for activities (especially mischief activities)
	-- Without this, flags like "cheater", "rebellious", "bully" won't be set
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.Flags = state.Flags or {}
	if activity.setFlag then
		state.Flags[activity.setFlag] = true
	end
	
	-- Handle multiple flags if needed
	if activity.setFlags then
		for flagName, flagValue in pairs(activity.setFlags) do
			state.Flags[flagName] = flagValue
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Some mischief activities have risk of getting caught
	-- E.g., vandalism, bullying, underage drinking may have consequences
	-- ═══════════════════════════════════════════════════════════════════════════════
	local resultMessage = ""
	local gotCaught = false
	
	if isEducationActivity then
		local enrollResult = self:enrollEducation(player, activity.educationProgram, { skipPush = true })
		if not enrollResult or not enrollResult.success then
			return enrollResult or { success = false, message = "Unable to enroll right now." }
		end
		resultMessage = enrollResult.message or "You enrolled in a new program."
	else
		if activity.risk and RANDOM:NextInteger(1, 100) <= activity.risk then
			gotCaught = true
			-- Risk-based consequence (usually for teen mischief)
			if activity.riskConsequence then
				resultMessage = string.format("You %s... but %s", activity.feed or "did it", activity.riskConsequence)
			else
				resultMessage = string.format("You %s... and got caught!", activity.feed or "did it")
			end
			-- Apply negative effects for getting caught
			self:applyStatChanges(state, { Happiness = -5 })
			if activity.riskFlag then
				state.Flags[activity.riskFlag] = true
			end
		else
			resultMessage = string.format("You %s.", activity.feed or "enjoyed the day")
		end
	end
	
	-- CRITICAL FIX: Track one-time activities so they can't be repeated
	if activity.oneTime and not activity.skipCompletionTracking and not isEducationActivity then
		state.CompletedActivities = state.CompletedActivities or {}
		state.CompletedActivities[activityId] = true
	end

	-- CRITICAL FIX: Don't use showPopup here - client shows its own result popup
	-- This was causing double popup issues in ActivitiesScreen
	self:pushState(player, resultMessage)
	return { success = true, message = resultMessage, gotCaught = gotCaught }
end

function LifeBackend:handleCrime(player, crimeId, minigameBonus)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "No life data loaded." }
	end
	if state.InJail then
		-- MINOR FIX: More helpful error message
		return { success = false, message = "You can't commit crimes while in prison. Serve your sentence first." }
	end

	local crime = CrimeCatalog[crimeId]
	if not crime then
		return { success = false, message = "Unknown crime." }
	end

	state.Flags = state.Flags or {}

	local riskModifier = 0
	if state.Flags.criminal_tendencies then
		riskModifier = riskModifier - 10
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Minigame bonus reduces risk of getting caught!
	-- Completing the heist minigame (like cracking a safe) gives you an advantage
	-- ═══════════════════════════════════════════════════════════════════════════════
	if minigameBonus == true then
		riskModifier = riskModifier - 20  -- 20% less likely to get caught
	elseif minigameBonus == false and crime.hasMinigame then
		-- Failed minigame for a crime that has one = higher risk
		riskModifier = riskModifier + 15  -- 15% more likely to get caught
	end

	local roll = RANDOM:NextInteger(0, 100)
	local caught = roll < (crime.risk + riskModifier)

	if caught then
		-- CRITICAL FIX: Use NextInteger, not NextNumber!
		-- NextNumber() returns a 0-1 float, NextInteger(min, max) returns proper integer range
		local years = RANDOM:NextInteger(crime.jail.min, crime.jail.max)
		state.InJail = true
		state.JailYearsLeft = years
		state.Flags.in_prison = true
		state.Flags.incarcerated = true
		
		-- CRITICAL FIX: Lose job when going to prison!
		-- In BitLife, you get fired when incarcerated. Save last job for potential re-employment.
		if state.CurrentJob then
			state.CareerInfo = state.CareerInfo or {}
			state.CareerInfo.lastJobBeforeJail = {
				id = state.CurrentJob.id,
				name = state.CurrentJob.name,
				company = state.CurrentJob.company,
				salary = state.CurrentJob.salary,
			}
			-- Clear current job
			state.CurrentJob = nil
			state.Flags.employed = nil
			state.Flags.has_job = nil
		end
		
		-- Also pause any education enrollment
		if state.EducationData and state.EducationData.Status == "enrolled" then
			state.EducationData.StatusBeforeJail = "enrolled"
			state.EducationData.Status = "suspended"
		end
		
		self:applyStatChanges(state, { Happiness = -10, Health = -5 })
		-- CRITICAL FIX: Only mention losing job if they actually had one
		local message
		if state.CareerInfo and state.CareerInfo.lastJobBeforeJail then
			message = string.format("You were caught! Sentenced to %.1f years. You lost your job.", years)
		else
			message = string.format("You were caught! Sentenced to %.1f years.", years)
		end
		-- CRITICAL FIX: Don't use showPopup - client shows its own result
		self:pushState(player, message)
		return { success = false, caught = true, message = message }
	else
		local payout = RANDOM:NextInteger(crime.reward[1], crime.reward[2])
		self:addMoney(state, payout)
		self:applyStatChanges(state, { Happiness = 4 })
		local message = string.format("Crime succeeded! You gained %s.", formatMoney(payout))
		-- CRITICAL FIX: Don't use showPopup - client shows its own result
		self:pushState(player, message)
		return { success = true, caught = false, message = message, money = payout }
	end
end

function LifeBackend:handlePrisonAction(player, actionId)
	local state = self:getState(player)
	if not state or not state.InJail then
		return { success = false, message = "You're not currently incarcerated." }
	end

	local action = PrisonActions[actionId]
	if not action then
		return { success = false, message = "Unknown prison action." }
	end

	state.Flags = state.Flags or {}

	if action.moneyCost and (state.Money or 0) < action.moneyCost then
		return { success = false, message = "You can't afford that legal help." }
	end

	if action.moneyCost then
		self:addMoney(state, -action.moneyCost)
	end

	if action.stats then
		self:applyStatChanges(state, action.stats)
	end

	if action.jailReduction then
		state.JailYearsLeft = math.max(0, (state.JailYearsLeft or 0) - action.jailReduction)
	end

	-- CRITICAL FIX: Support for jailIncrease (for failed escape attempts)
	-- NOTE: Client handles showing the popup, so we DON'T send showPopup here
	-- to avoid DOUBLE POPUP bug
	if action.jailIncrease then
		state.JailYearsLeft = (state.JailYearsLeft or 0) + action.jailIncrease
		-- MINOR FIX: Use %.1f for consistent decimal formatting
		local message = string.format("Your escape failed. %.1f years added to your sentence.", action.jailIncrease)
		self:pushState(player, message)
		return { success = false, message = message }
	end

	if action.risk and RANDOM:NextInteger(1, 100) <= action.risk then
		local message = "Guards caught you. Your sentence increased."
		state.JailYearsLeft = (state.JailYearsLeft or 0) + 1
		self:applyStatChanges(state, { Happiness = -5 })
		self:pushState(player, message)
		return { success = false, message = message }
	end

	if actionId == "prison_escape" then
		-- CRITICAL FIX: Prison escape is now determined by the client-side minigame!
		-- The client calls "prison_escape" only after winning the minigame.
		-- So if we get here, the player WON the minigame and should escape!
		
		state.awaitingDecision = true
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX: FREE THE PLAYER IMMEDIATELY when they win the minigame!
		-- Don't wait for the choice - they already escaped by winning the minigame.
		-- The event card is just asking what they do AFTER escaping.
		-- ═══════════════════════════════════════════════════════════════════════════════
		state.InJail = false
		state.JailYearsLeft = 0
		state.Flags.in_prison = nil
		state.Flags.incarcerated = nil
		state.Flags.escaped_prisoner = true
		state.Flags.fugitive = true
		state.PendingFeed = nil
		state.YearLog = {}
		
		-- Player won the minigame - they escape successfully!
		local eventDef = {
			id = "prison_escape_success",
			title = "🎉 Escape Successful!",
			emoji = "🏃",
			text = "Against all odds, you made it over the wall and into freedom! You're now a fugitive - but you're FREE!",
			question = "What's your plan now?",
			-- CRITICAL FIX: Use "success" category so card shows GREEN border!
			category = "success",
			source = "lifeevents",
			choices = {
				{ 
					text = "Lay low and start fresh", 
					effects = { Happiness = 20 },
					setFlags = { escaped_prisoner = true, fugitive = true, criminal_record = true },
					feedText = "🏃 You escaped prison! Now living as a fugitive.",
				},
				{ 
					text = "Leave the country", 
					effects = { Happiness = 15, Money = -5000 },
					setFlags = { escaped_prisoner = true, fugitive = true, fled_country = true },
					feedText = "🏃 You escaped and fled to another country!",
				},
			},
			-- Backup onComplete just to make absolutely sure
			onComplete = function(state, choice, eventDef, outcome)
				-- Ensure flags are set (they should already be, but just in case)
				state.InJail = false
				state.JailYearsLeft = 0
				state.Flags.in_prison = nil
				state.Flags.incarcerated = nil
			end,
		}
		
		-- CRITICAL FIX: Changed feedText to show success
		self:presentEvent(player, eventDef, "🏃 You're FREE! You escaped!")
		return { success = true, message = "Escape successful!" }
	end

	if (state.JailYearsLeft or 0) <= 0 then
		state.InJail = false
		state.Flags.in_prison = nil
		state.Flags.incarcerated = nil
		self:pushState(player, "You're now free!")
		return { success = true, message = "Sentence complete! You're free." }
	end

	local message = action.feed or "You passed some time."
	self:pushState(player, message)
	return { success = true, message = message }
end

-- ============================================================================
-- Career / Education
-- ============================================================================

function LifeBackend:meetsEducationRequirement(state, requirement)
	if not requirement then
		return true
	end
	local playerRank = EducationRanks[state.Education or "none"] or 0
	local jobRank = EducationRanks[requirement] or 0
	return playerRank >= jobRank
end

-- ============================================================================
-- CRITICAL FIX: Job Rejection Messages for variety and realism
-- ============================================================================
-- MINOR FIX: Expanded rejection messages for more variety
local JobRejectionMessages = {
	generic = {
		"After careful consideration, we've decided to go with another candidate.",
		"Unfortunately, your application was not successful this time.",
		"We appreciate your interest, but we're looking for someone with more experience.",
		"Thank you for applying, but we've filled the position.",
		"Your qualifications don't quite match what we're looking for right now.",
		"We're moving forward with other candidates at this time.",
		"While your application was strong, we found a better fit.",
	},
	lowStats = {
		"You didn't pass the physical fitness requirements.",
		"The aptitude test results weren't quite what we were hoping for.",
		"We need someone with stronger qualifications for this role.",
		"Your skills assessment didn't meet our requirements.",
	},
	competitive = {
		"This position attracted many highly qualified candidates.",
		"Competition for this role was extremely fierce.",
		"We received over 500 applications for this position.",
		"The hiring committee narrowed it down and chose someone else.",
	},
	entry = {
		"Even entry-level positions can be competitive these days!",
		"We're looking for someone with a bit more availability.",
		"Your interview went well, but another candidate edged you out.",
		"Keep applying! The right opportunity will come.",
	},
	-- CRITICAL FIX: Messages for when criminal record affects job chances
	criminalRecord = {
		"The background check revealed some concerns.",
		"We need to go with a candidate without legal issues.",
		"Our policy requires a clean record for this position.",
		"Your qualifications were good, but the background check was problematic.",
	},
}

-- CRITICAL FIX: Server-side list of jobs that can only be obtained through promotion
local PromotionOnlyJobs = {
	["racing_legend"] = true, ["racing_team_owner"] = true,
	["star_athlete"] = true, ["sports_legend"] = true, ["team_owner"] = true,
	["movie_star"] = true, ["director"] = true, ["producer"] = true,
	["gaming_legend"] = true, ["esports_team_owner"] = true,
	["music_icon"] = true, ["record_label_owner"] = true,
	["cto"] = true, ["ceo"] = true, ["cfo"] = true, ["cmo"] = true, ["coo"] = true,
	["partner"] = true, ["senior_partner"] = true,
	["chief_of_surgery"] = true, ["hospital_director"] = true,
	["chief_pilot"] = true, ["airline_executive"] = true,
	["cia_director"] = true, ["fbi_director"] = true,
	["senator"] = true, ["governor"] = true, ["president"] = true,
}

function LifeBackend:handleJobApplication(player, jobId)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data not loaded." }
	end

	local job = JobCatalog[jobId]
	if not job then
		return { success = false, message = "Unknown job." }
	end
	
	-- CRITICAL FIX: Block direct application to promotion-only positions
	if PromotionOnlyJobs[jobId] then
		return { 
			success = false, 
			message = "This position requires years of experience and internal promotion. You can't apply directly." 
		}
	end

	if state.InJail then
		return { success = false, message = "You can't apply while incarcerated." }
	end

	if (state.Age or 0) < job.minAge then
		return { success = false, message = string.format("You must be at least %d years old to apply.", job.minAge) }
	end

	if not self:meetsEducationRequirement(state, job.requirement) then
		local eduNames = { high_school = "a High School Diploma", bachelor = "a Bachelor's Degree", master = "a Master's Degree", 
			phd = "a PhD", medical = "a Medical Degree", law = "a Law Degree", community = "a Community College certificate" }
		local needed = eduNames[job.requirement] or "more education"
		return { success = false, message = string.format("This position requires %s.", needed) }
	end

	-- CRITICAL FIX: Check minStats requirements (for physical/demanding jobs)
	if job.minStats then
		state.Stats = state.Stats or {}
		for statName, minValue in pairs(job.minStats) do
			local playerStat = state.Stats[statName] or state[statName] or 50
			if playerStat < minValue then
				local statDisplayName = statName:gsub("^%l", string.upper)
				local gap = minValue - playerStat
				local severity = gap > 20 and "far below" or (gap > 10 and "below" or "slightly below")
				return { 
					success = false, 
					message = string.format("You're %s the %s requirement (%d needed, you have %d). Work on improving yourself!", severity, statDisplayName, minValue, playerStat) 
				}
			end
		end
	end
	
	-- CRITICAL FIX: Check requiresFlags (for specialized jobs like hacking that need prior experience)
	if job.requiresFlags then
		state.Flags = state.Flags or {}
		local hasRequiredExperience = false
		local requiredFlagNames = {}
		
		for _, flagName in ipairs(job.requiresFlags) do
			table.insert(requiredFlagNames, flagName)
			if state.Flags[flagName] then
				hasRequiredExperience = true
				break -- Only need ONE of the flags
			end
		end
		
		if not hasRequiredExperience then
			-- Provide helpful message about what experience is needed
			local experienceMessages = {
				coder = "coding skills (try computer camp or study programming)",
				tech_experience = "tech industry experience (work in IT first)",
				hacker_experience = "hacking experience (start as a script kiddie first)",
				elite_hacker_rep = "elite hacker reputation (prove yourself as a black hat first)",
				cyber_crime_history = "cyber crime background (work your way up the criminal ladder)",
			}
			
			local helpText = experienceMessages[requiredFlagNames[1]] or "specialized experience"
			return { 
				success = false, 
				message = string.format("This job requires %s. You don't have the necessary background.", helpText)
			}
		end
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Job Application Rejection System
	-- Not every application should succeed! Add realistic interview/hiring mechanics.
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	state.JobApplications = state.JobApplications or {}
	local appHistory = state.JobApplications[jobId] or { attempts = 0, lastAttempt = 0, rejectedThisYear = false }
	
	-- Cooldown: Can't spam applications to the same job within the same year
	if appHistory.lastAttempt == (state.Age or 0) and appHistory.rejectedThisYear then
		return { 
			success = false, 
			message = string.format("You already applied to %s this year. Wait until next year to try again.", job.company)
		}
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Realistic job application system
	-- Job acceptance should NOT be automatic - difficulty matters!
	-- ═══════════════════════════════════════════════════════════════════════════════
	local difficulty = job.difficulty or 1
	
	-- Base chance calculation - MUCH more realistic now
	-- Scale: 1-10 difficulty where 10 is nearly impossible
	local baseChance
	if difficulty >= 10 then
		baseChance = 0.03 -- 3% - Near impossible (Movie Star, President, Pro Athlete)
	elseif difficulty >= 9 then
		baseChance = 0.08 -- 8% - Elite (CTO, Senator, Music Icon)
	elseif difficulty >= 8 then
		baseChance = 0.12 -- 12% - Very competitive (CEO, Hollywood Actor)
	elseif difficulty >= 7 then
		baseChance = 0.20 -- 20% - Highly competitive (CMO, Recording Artist)
	elseif difficulty >= 6 then
		baseChance = 0.30 -- 30% - Competitive (Detective, Pro Musician)
	elseif difficulty >= 5 then
		baseChance = 0.40 -- 40% - Above average difficulty
	elseif difficulty >= 4 then
		baseChance = 0.50 -- 50% - Moderate difficulty
	elseif difficulty >= 3 then
		baseChance = 0.60 -- 60% - Some competition
	elseif difficulty >= 2 then
		baseChance = 0.70 -- 70% - Entry-level with competition
	else
		baseChance = 0.80 -- 80% - Basic entry jobs anyone can get
	end
	
	-- Experience bonus - REDUCED from original to prevent god-mode
	state.CareerInfo = state.CareerInfo or {}
	local yearsExperience = state.CareerInfo.totalYearsWorked or 0
	local experienceBonus = math.min(0.10, yearsExperience * 0.01) -- Up to +10% for 10+ years experience (was +20%)
	
	-- Industry experience bonus - REDUCED
	if state.Career and state.Career.track == job.category then
		experienceBonus = experienceBonus + 0.08 -- Industry experience helps (was +15%)
	end
	
	-- Stat bonus - REDUCED to prevent stats from overriding difficulty
	state.Stats = state.Stats or {}
	local statBonus = 0
	if job.category == "tech" or job.category == "office" or job.category == "science" or job.category == "law" or job.category == "finance" then
		local smarts = state.Stats.Smarts or state.Smarts or 50
		statBonus = math.clamp((smarts - 50) / 400, -0.10, 0.10) -- +/-10% based on Smarts (was +/-25%)
	elseif job.category == "military" or job.category == "sports" or job.category == "trades" then
		local health = state.Stats.Health or state.Health or 50
		statBonus = math.clamp((health - 50) / 400, -0.10, 0.10) -- +/-10% based on Health (was +/-25%)
	end
	
	-- Previous rejection penalty (companies remember bad interviews)
	local rejectionPenalty = math.min(0.20, (appHistory.attempts or 0) * 0.08) -- -8% per previous rejection, max -20%
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Criminal record affects job applications!
	-- Employers run background checks - having a record makes it much harder to get hired
	-- Some jobs (law enforcement, government, finance) outright reject ex-convicts
	-- ═══════════════════════════════════════════════════════════════════════════════
	local criminalPenalty = 0
	if state.Flags and state.Flags.criminal_record then
		-- Jobs that do strict background checks and won't hire ex-convicts
		local strictBackgroundCheckJobs = {
			"law", "government", "finance", "education", "healthcare", "military", "security"
		}
		
		local isStrictJob = false
		for _, category in ipairs(strictBackgroundCheckJobs) do
			if job.category == category or (job.id and string.find(job.id:lower(), category)) then
				isStrictJob = true
				break
			end
		end
		
		if isStrictJob then
			-- Strict background check jobs won't hire people with records
			return {
				success = false,
				message = "Your background check revealed a criminal record. This position requires a clean record."
			}
		end
		
		-- Other jobs have a penalty but not automatic rejection
		criminalPenalty = 0.30 -- 30% penalty for having a record
		
		-- Fugitives face even harsher penalties
		if state.Flags.fugitive or state.Flags.escaped_prisoner then
			criminalPenalty = 0.50 -- 50% penalty for being a fugitive
		end
	end
	
	-- CRITICAL FIX: Cap maximum chance based on difficulty
	-- Even with perfect stats, difficult jobs should remain difficult
	local maxChance = 1.0 - (difficulty * 0.05) -- difficulty 10 caps at 50%, difficulty 1 caps at 95%
	maxChance = math.clamp(maxChance, 0.30, 0.95)
	
	local finalChance = math.clamp(baseChance + experienceBonus + statBonus - rejectionPenalty - criminalPenalty, 0.02, maxChance)
	
	-- Entry-level jobs (no requirements, low salary) - still have some chance of rejection
	if not job.requirement and (job.salary or 0) < 35000 then
		finalChance = math.max(finalChance, 0.65) -- At least 65% chance for basic jobs (was 80%!)
	end
	
	-- Roll for success
	local roll = RANDOM:NextNumber()
	local accepted = roll < finalChance
	
	-- Track application
	state.JobApplications[jobId] = {
		attempts = (appHistory.attempts or 0) + 1,
		lastAttempt = state.Age or 0,
		rejectedThisYear = not accepted,
	}
	
	if not accepted then
		-- Pick a rejection message based on situation
		local messages
		-- CRITICAL FIX: Show criminal record message if that's why they were rejected
		if criminalPenalty > 0 and state.Flags and state.Flags.criminal_record then
			messages = JobRejectionMessages.criminalRecord
		elseif difficulty >= 6 then
			messages = JobRejectionMessages.competitive
		elseif job.minStats then
			messages = JobRejectionMessages.lowStats
		elseif not job.requirement then
			messages = JobRejectionMessages.entry
		else
			messages = JobRejectionMessages.generic
		end
		local msg = messages[RANDOM:NextInteger(1, #messages)]
		
		-- Add encouragement for first rejection
		if appHistory.attempts == 0 then
			msg = msg .. " Don't give up - try again next year or look for other opportunities!"
		elseif appHistory.attempts >= 2 then
			msg = msg .. " Consider gaining more experience or improving your skills before reapplying."
		end
		
		return { success = false, message = msg }
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- SUCCESS! Hired for the job
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Check if illegal job and warn/block based on criminal status
	if job.illegal and not (state.Flags and state.Flags.criminal_path) then
		state.Flags = state.Flags or {}
		state.Flags.criminal_path = true
		state.Flags.criminal = true
	end
	
	state.CareerInfo = state.CareerInfo or {}
	state.Career = state.Career or {}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Save OLD job to career history before replacing
	-- This populates the Career Info screen's career history section
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.CurrentJob then
		state.CareerInfo.careerHistory = state.CareerInfo.careerHistory or {}
		local historyEntry = {
			title = state.CurrentJob.name,
			company = state.CurrentJob.company,
			salary = state.CurrentJob.salary,
			category = state.CurrentJob.category,
			yearsWorked = state.CareerInfo.yearsAtJob or 0,
			performance = state.CareerInfo.performance or 60,
			raises = state.CareerInfo.raises or 0,
			promotions = state.CareerInfo.promotions or 0,
			reason = "quit", -- They left for a new job
			endAge = state.Age or 0,
			endYear = state.Year or 2025,
		}
		table.insert(state.CareerInfo.careerHistory, historyEntry)
		
		-- Track total years worked for experience bonuses
		state.CareerInfo.totalYearsWorked = (state.CareerInfo.totalYearsWorked or 0) + (state.CareerInfo.yearsAtJob or 0)
	end

	state.CurrentJob = {
		id = job.id,
		name = job.name,
		company = job.company,
		salary = job.salary,
		category = job.category,
		difficulty = job.difficulty or 1, -- CRITICAL FIX: Pass difficulty to client
		minStats = job.minStats, -- CRITICAL FIX: Pass stat requirements
	}

	state.CareerInfo.performance = 60
	state.CareerInfo.promotionProgress = 0
	state.CareerInfo.yearsAtJob = 0
	state.CareerInfo.raises = 0
	state.CareerInfo.promotions = 0

	state.Career.track = job.category
	
	-- CRITICAL FIX: Set employment flags and clear retirement-related flags
	state.Flags = state.Flags or {}
	state.Flags.employed = true
	state.Flags.has_job = true
	state.Flags.between_jobs = nil
	state.Flags.unemployed = nil
	
	-- CRITICAL FIX: Set has_teen_job for jobs obtained before age 18
	if (state.Age or 0) < 18 then
		state.Flags.has_teen_job = true
	end
	
	if state.Flags.retired then
		state.Flags.retired = nil
		state.Flags.semi_retired = nil
		state.Flags.pension_amount = nil
	end
	
	-- CRITICAL FIX: Grant experience flags from job (for career progression)
	-- Some jobs grant flags that unlock higher-tier jobs
	if job.grantsFlags then
		for _, flagName in ipairs(job.grantsFlags) do
			state.Flags[flagName] = true
		end
	end
	
	-- Clear application history for this job (fresh start)
	state.JobApplications[jobId] = nil

	local feed = string.format("🎉 Congratulations! You were hired as a %s at %s!", job.name, job.company)
	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:handleQuitJob(player, quitStyle)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data not loaded." }
	end
	if not state.CurrentJob then
		return { success = false, message = "You're not currently employed." }
	end

	state.CareerInfo = state.CareerInfo or {}
	state.Career = state.Career or {}
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Save job to career history before clearing
	-- This populates the Career Info screen's career history section
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.CareerInfo.careerHistory = state.CareerInfo.careerHistory or {}
	
	-- Determine quit reason based on style
	local quitReason = "quit"
	if quitStyle == "dramatic" then
		quitReason = "quit_dramatic"
	elseif quitStyle == "ghost" then
		quitReason = "quit_ghost"
	end
	
	local historyEntry = {
		title = state.CurrentJob.name,
		company = state.CurrentJob.company,
		salary = state.CurrentJob.salary,
		category = state.CurrentJob.category,
		yearsWorked = state.CareerInfo.yearsAtJob or 0,
		performance = state.CareerInfo.performance or 60,
		raises = state.CareerInfo.raises or 0,
		promotions = state.CareerInfo.promotions or 0,
		reason = quitReason,
		endAge = state.Age or 0,
		endYear = state.Year or 2025,
	}
	table.insert(state.CareerInfo.careerHistory, historyEntry)
	
	-- Track total years worked for experience bonuses
	state.CareerInfo.totalYearsWorked = (state.CareerInfo.totalYearsWorked or 0) + (state.CareerInfo.yearsAtJob or 0)

	local jobName = state.CurrentJob.name
	local companyName = state.CurrentJob.company or "your employer"
	state.CurrentJob = nil
	state.CareerInfo.performance = 0
	state.CareerInfo.promotionProgress = 0
	state.CareerInfo.yearsAtJob = 0
	state.Career.track = nil
	
	-- CRITICAL FIX: Clear employment flags properly
	state.Flags = state.Flags or {}
	state.Flags.employed = nil
	state.Flags.has_job = nil
	state.Flags.between_jobs = true
	
	-- BITLIFE-STYLE: Different messages and effects based on quit style
	local feed
	local happinessBonus = 0
	
	if quitStyle == "dramatic" then
		-- Dramatic quit - burned bridges but felt GOOD
		feed = string.format("🔥 You told %s EXACTLY what you think of them. Flipped your desk. Said goodbye to nobody. Walked out like a BOSS. Your ex-coworkers are STILL talking about it. #Legend", companyName)
		happinessBonus = 15
		state.Flags.burned_bridges = true
		state.Flags.epic_quitter = true
	elseif quitStyle == "ghost" then
		-- Ghost - just stopped showing up
		feed = string.format("👻 You just... stopped going to %s. No call. No text. Nothing. They probably filed a missing person report. Your desk stuff is still there. You're officially a ghost.", companyName)
		happinessBonus = 5
		state.Flags.unreliable = true
		state.Flags.ghosted_employer = true
	else
		-- Professional - two week notice
		feed = string.format("✅ You submitted your two-week notice at %s. Your boss looked disappointed but thanked you for your professionalism. Wrote you a great recommendation letter.", companyName)
		happinessBonus = 5
		state.Flags.professional_quitter = true
	end
	
	-- Apply happiness bonus
	state.Stats = state.Stats or {}
	state.Stats.Happiness = math.min(100, (state.Stats.Happiness or 50) + happinessBonus)

	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:handleWork(player)
	local state = self:getState(player)
	if not state or not state.CurrentJob then
		return { success = false, message = "You need a job first." }
	end
	if state.InJail then
		return { success = false, message = "Get out of prison first." }
	end

	state.CareerInfo = state.CareerInfo or {}

	local salary = state.CurrentJob.salary or 0
	local bonus = math.floor(((state.CareerInfo.performance or 50) / 100) * 0.2 * salary)
	local payday = math.floor(salary / 12 + bonus)
	self:addMoney(state, payday)
	self:applyStatChanges(state, { Happiness = RANDOM:NextInteger(-2, 2) })

	-- CRITICAL FIX: Working hard improves performance, but not guaranteed
	-- Performance is the key metric for promotions now (see handlePromotion)
	state.CareerInfo.performance = clamp((state.CareerInfo.performance or 60) + RANDOM:NextInteger(1, 5), 0, 100)

	local message = string.format("Payday! You earned %s.", formatMoney(payday))
	-- CRITICAL FIX: Don't use showPopup here - client already shows result from return value
	-- This was causing DOUBLE popup issue!
	self:pushState(player, message)
	return { success = true, message = message, money = payday }
end

function LifeBackend:handlePromotion(player)
	local state = self:getState(player)
	if not state or not state.CurrentJob then
		return { success = false, message = "You need a job first." }
	end

	state.CareerInfo = state.CareerInfo or {}
	local info = state.CareerInfo
	state.Flags = state.Flags or {}

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Promotions were happening every 1-2 years (way too fast!)
	-- Now require: minimum years at job, good performance, AND random approval chance
	-- This matches BitLife where promotions are rare and based on performance
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Minimum 3 years at current position before eligible for promotion
	local yearsAtJob = info.yearsAtJob or 0
	if yearsAtJob < 3 then
		return { success = false, message = string.format("You need more time in your current role. (%.0f/3 years)", yearsAtJob) }
	end
	
	-- Need good performance (70+)
	local performance = info.performance or 50
	if performance < 70 then
		return { success = false, message = string.format("Your performance needs improvement. (%d%% / 70%% required)", performance) }
	end
	
	-- Cooldown: Can only request promotion once per year
	local lastPromotionRequest = info.lastPromotionRequestAge or 0
	if (state.Age or 0) <= lastPromotionRequest then
		return { success = false, message = "You already asked this year. Try again next year." }
	end
	info.lastPromotionRequestAge = state.Age or 0
	
	-- Random chance based on performance - promotions aren't guaranteed!
	-- 70% performance = 40% chance, 100% performance = 70% chance
	local promotionChance = 0.1 + (performance / 100) * 0.6
	local roll = RANDOM:NextNumber()
	
	if roll > promotionChance then
		-- Denied!
		local denialMessages = {
			"Your manager said 'not this time.' Keep working hard.",
			"The budget for promotions has been frozen. Try again next year.",
			"They're looking for someone with more experience in leadership.",
			"You're doing great, but there's no open positions above you right now.",
		}
		local msg = denialMessages[RANDOM:NextInteger(1, #denialMessages)]
		return { success = false, message = msg }
	end

	-- Promotion granted!
	info.promotionProgress = 0
	info.promotions = (info.promotions or 0) + 1
	state.Flags.just_promoted = true
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #5: Actually change job title on promotion, not just salary!
	-- Use CareerTracks to find the next job in the career path
	-- ═══════════════════════════════════════════════════════════════════════════════
	local currentJobId = state.CurrentJob.id
	local promotedToNewTitle = false
	local oldJobName = state.CurrentJob.name or "your old position"
	local newJobName = nil
	
	-- Find current job's career track and next position
	for trackName, trackJobs in pairs(CareerTracks) do
		for i, jobId in ipairs(trackJobs) do
			if jobId == currentJobId then
				-- Found current job, check if there's a next position
				local nextJobId = trackJobs[i + 1]
				if nextJobId then
					local nextJob = JobCatalog[nextJobId]
					if nextJob then
						-- Check if player meets requirements for next job
						local meetsReqs = true
						if nextJob.minAge and (state.Age or 0) < nextJob.minAge then
							meetsReqs = false
						end
						-- For now, skip education check on internal promotions
						
						if meetsReqs then
							-- PROMOTE to next job!
							state.CurrentJob = {
								id = nextJob.id,
								name = nextJob.name,
								title = nextJob.name,
								company = state.CurrentJob.company or nextJob.company, -- Keep same company
								salary = math.floor((state.CurrentJob.salary or nextJob.salary) * 1.25), -- 25% raise on title change
								emoji = nextJob.emoji,
								category = nextJob.category,
								hiredAt = state.Age,
							}
							promotedToNewTitle = true
							newJobName = nextJob.name
							info.yearsAtJob = 0 -- Reset years at job for new position
							info.raises = 0 -- Reset raises for new position
						end
					end
				end
				break
			end
		end
		if promotedToNewTitle then break end
	end
	
	local feed
	if promotedToNewTitle and newJobName then
		feed = string.format("🎉 MAJOR PROMOTION! You've been promoted from %s to %s! New salary: %s", 
			oldJobName, newJobName, formatMoney(state.CurrentJob.salary))
		-- Add a flag for major promotion
		state.Flags.major_promotion = true
	else
		-- No title change available (top of career track) - just salary bump
		state.CurrentJob.salary = math.floor((state.CurrentJob.salary or 0) * 1.15)
		feed = string.format("🎉 Salary promotion! You now earn %s.", formatMoney(state.CurrentJob.salary))
	end
	
	info.performance = clamp((info.performance or 60) + 5, 0, 100)
	self:pushState(player, feed)
	return { success = true, message = feed, newJob = promotedToNewTitle and state.CurrentJob or nil }
end

function LifeBackend:handleRaise(player)
	local state = self:getState(player)
	if not state or not state.CurrentJob then
		return { success = false, message = "No employer to ask." }
	end

	state.CareerInfo = state.CareerInfo or {}
	local info = state.CareerInfo

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Add cooldown to prevent raise spam
	-- Can only ask for a raise once per year, similar to promotions
	-- ═══════════════════════════════════════════════════════════════════════════════
	local lastRaiseRequest = info.lastRaiseRequestAge or 0
	if (state.Age or 0) <= lastRaiseRequest then
		return { success = false, message = "You already asked for a raise this year. Try again next year." }
	end
	info.lastRaiseRequestAge = state.Age or 0

	if (info.performance or 0) < 60 then
		return { success = false, message = "Improve your performance before asking. (Need 60%+)" }
	end
	if (info.raises or 0) >= 5 then
		return { success = false, message = "You've maxed out raises for this role. Need a promotion for more." }
	end

	-- CRITICAL FIX: Raise chance based on performance, not just 70% flat
	local performance = info.performance or 60
	local raiseChance = 0.3 + (performance / 100) * 0.4 -- 30-70% based on performance
	local granted = RANDOM:NextNumber() < raiseChance
	
	if not granted then
		info.performance = clamp((info.performance or 60) - 5, 0, 100)
		return { success = false, message = "Raise denied. 'Budget constraints' they said. Maybe next year." }
	end

	state.CurrentJob.salary = math.floor((state.CurrentJob.salary or 0) * 1.08) -- 8% raise instead of 10%
	info.raises = (info.raises or 0) + 1
	info.performance = clamp((info.performance or 60) + 3, 0, 100)

	local feed = string.format("💰 Raise approved! Salary is now %s.", formatMoney(state.CurrentJob.salary))
	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:getCareerInfo(player)
	local state = self:getState(player)
	if not state then
		return { success = false }
	end
	state.CareerInfo = state.CareerInfo or {}
	state.Career = state.Career or {}

	-- CRITICAL FIX #6: Get next promotion job info for client display
	local nextJobId = nil
	local nextJobName = nil
	local nextJobSalary = nil
	if state.CurrentJob and state.CurrentJob.id then
		nextJobId = getNextPromotionJob(state.CurrentJob.id)
		if nextJobId and JobCatalog[nextJobId] then
			local nextJob = JobCatalog[nextJobId]
			nextJobName = nextJob.name
			nextJobSalary = nextJob.salary
		end
	end

	return {
		success = true,
		performance = state.CareerInfo.performance or 0,
		promotionProgress = state.CareerInfo.promotionProgress or 0,
		yearsAtJob = state.CareerInfo.yearsAtJob or 0,
		raises = state.CareerInfo.raises or 0,
		promotions = state.CareerInfo.promotions or 0,
		careerHistory = state.CareerInfo.careerHistory or {},
		skills = state.CareerInfo.skills or {},
		track = state.Career.track,
		totalExperience = state.CareerInfo.totalYearsWorked or 0,
		totalYearsWorked = state.CareerInfo.totalYearsWorked or 0,
		-- CRITICAL FIX #7: Include next promotion info
		promotesTo = nextJobId,
		promotesToName = nextJobName,
		promotesToSalary = nextJobSalary,
		hasPromotion = nextJobId ~= nil,
	}
end

function LifeBackend:getEducationInfo(player)
	local state = self:getState(player)
	if not state then
		return { success = false }
	end
	local edu = state.EducationData or { Status = "none" }
	state.Stats = state.Stats or {}

	local rawGPA
	if edu.GPA ~= nil then
		rawGPA = edu.GPA
	else
		local smarts = state.Stats.Smarts or 0
		rawGPA = math.floor((smarts / 25) * 100) / 100
	end

	return {
		success = true,
		level = state.Education,
		-- CRITICAL FIX: Add human-readable education level display
		levelDisplay = formatEducation(state.Education),
		institution = edu.Institution or "Local School",
		gpa = rawGPA,
		progress = edu.Progress or 0,
		status = edu.Status or "none",
		creditsEarned = edu.CreditsEarned,
		creditsRequired = edu.CreditsRequired,
		year = edu.Year,
		totalYears = edu.TotalYears,
		debt = edu.Debt or 0,
	}
end

function LifeBackend:enrollEducation(player, programId, options)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	options = options or {}
	local skipPush = options.skipPush == true

	local program = EducationCatalog[programId]
	if not program then
		return { success = false, message = "Unknown education program." }
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Prevent multiple education enrollments!
	-- You can't be enrolled in two programs at once - just like real life
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.EducationData and state.EducationData.Status == "enrolled" then
		local currentProgram = state.EducationData.Institution or "a program"
		return { 
			success = false, 
			message = string.format("You're already enrolled in %s! Complete it first or drop out.", currentProgram)
		}
	end

	-- CRITICAL FIX: Check minimum age for enrollment
	local playerAge = state.Age or 0
	local minAge = program.minAge or 18
	if playerAge < minAge then
		return { success = false, message = string.format("You must be at least %d years old to enroll in %s.", minAge, program.name) }
	end

	if not self:meetsEducationRequirement(state, program.requirement) then
		-- MINOR FIX: More helpful error message with specific requirement
		local requiredText = program.requirement or "a prerequisite degree"
		return { success = false, message = string.format("You need %s to enroll in %s.", requiredText, program.name) }
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Allow student loans! Don't block enrollment for not having cash.
	-- Just like real life - students take out loans for education
	-- ═══════════════════════════════════════════════════════════════════════════════
	local prevDebt = (state.EducationData and state.EducationData.Debt) or 0
	local currentMoney = state.Money or 0
	local tuitionCost = program.cost or 0
	local loanNeeded = 0
	
	if currentMoney >= tuitionCost then
		-- Player can pay in full
		self:addMoney(state, -tuitionCost)
	else
		-- Player takes out student loans for the remainder
		loanNeeded = tuitionCost - currentMoney
		if currentMoney > 0 then
			self:addMoney(state, -currentMoney) -- Pay what they can
		end
		-- Loan is added to debt (paid back later)
	end
	-- CRITICAL FIX: Track loan separately from total cost for proper messaging
	local totalDebt = prevDebt + loanNeeded -- Only add the loan portion to debt, not what was paid
	
	state.EducationData = {
		Status = "enrolled",
		Level = programId,
		Progress = 0,
		Duration = program.duration,
		Institution = program.name,
		Debt = totalDebt,
		LoanAmount = loanNeeded, -- Track how much was borrowed this enrollment
	}
	state.Career = state.Career or {}
	state.Career.education = programId
	
	-- Set student loan flag if they took a loan
	if loanNeeded > 0 then
		state.Flags = state.Flags or {}
		state.Flags.has_student_loans = true
		state.Flags.student_loan_amount = (state.Flags.student_loan_amount or 0) + loanNeeded
	end

	local feed
	if loanNeeded > 0 then
		feed = string.format("You enrolled in %s! Took out %s in student loans.", program.name, formatMoney(loanNeeded))
	else
		feed = string.format("You enrolled in %s! Paid tuition in full.", program.name)
	end
	if not skipPush then
		self:pushState(player, feed)
	end
	return { success = true, message = feed }
end

-- ============================================================================
-- Assets & Gambling
-- ============================================================================

function LifeBackend:findAssetById(list, assetId)
	for _, asset in ipairs(list) do
		if asset.id == assetId then
			return asset
		end
	end
end

--[[
	handleAssetPurchase - Server-side validation for asset purchases
	
	Validates:
	- Age requirements (must be 18+ for most purchases)
	- Money availability
	- Driver's license for vehicles
	- Prevents godmode by enforcing real checks
]]
function LifeBackend:handleAssetPurchase(player, assetType, catalog, assetId)
	debugPrint("=== ASSET PURCHASE ===")
	debugPrint("  Player:", player.Name, "Type:", assetType, "AssetId:", assetId)
	
	local state = self:getState(player)
	if not state then
		debugPrint("  FAILED: No state")
		return { success = false, message = "Life data missing." }
	end

	local asset = self:findAssetById(catalog, assetId)
	if not asset then
		debugPrint("  FAILED: Unknown asset")
		return { success = false, message = "Unknown asset." }
	end
	
	debugPrint("  Found asset:", asset.name, "Price:", asset.price)

	state.Assets = state.Assets or {}
	state.Flags = state.Flags or {}

	-- Age check for major purchases (properties and vehicles)
	local minAge = asset.minAge or 18
	if assetType == "Properties" then
		minAge = asset.minAge or 21 -- Must be 21+ to buy property
	elseif assetType == "Vehicles" then
		minAge = asset.minAge or 16 -- Must be 16+ for vehicles

		-- Vehicle-specific: require driver's license
		-- CRITICAL FIX: Check ALL possible license flag names for consistency
		local hasLicense = state.Flags and (state.Flags.has_license or state.Flags.drivers_license or state.Flags.driver_license)
		if not hasLicense then
			debugPrint("  FAILED: No driver's license")
			return { success = false, message = "You need a driver's license first!" }
		end
	elseif assetType == "Items" then
		minAge = asset.minAge or 14 -- Shop items can be bought younger
	end

	if (state.Age or 0) < minAge then
		return { success = false, message = string.format("You must be at least %d years old to buy this.", minAge) }
	end

	-- Prison check - can't buy stuff while incarcerated
	if state.InJail then
		return { success = false, message = "You can't make purchases while incarcerated." }
	end

	-- Money check
	if (state.Money or 0) < asset.price then
		return { success = false, message = "You can't afford that." }
	end

	state.Assets[assetType] = state.Assets[assetType] or {}
	table.insert(state.Assets[assetType], {
		id = asset.id,
		name = asset.name,
		emoji = asset.emoji,
		value = asset.price,
		price = asset.price,
		income = asset.income,
		acquiredAge = state.Age,
		acquiredYear = state.Year,
	})
	
	debugPrint("  SUCCESS: Added to state.Assets." .. assetType)
	debugPrint("    Total items in " .. assetType .. ":", #state.Assets[assetType])
	for i, a in ipairs(state.Assets[assetType]) do
		debugPrint("      [" .. i .. "]", a.id, a.name)
	end

	if assetType == "Vehicles" then
		state.Flags.has_vehicle = true
		state.Flags.has_car = true
	elseif assetType == "Properties" then
		state.Flags.has_property = true
		state.Flags.homeowner = true
	end

	self:addMoney(state, -asset.price)
	local feed = string.format("You purchased %s for %s.", asset.name, formatMoney(asset.price))
	
	-- Debug: Check assets before push
	debugPrint("  Before pushState:")
	debugPrint("    state.Assets.Properties:", state.Assets.Properties and #state.Assets.Properties or 0)
	debugPrint("    state.Assets.Vehicles:", state.Assets.Vehicles and #state.Assets.Vehicles or 0)
	debugPrint("    state.Assets.Items:", state.Assets.Items and #state.Assets.Items or 0)
	
	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:handleAssetSale(player, assetId, assetType)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	if state.InJail then
		return { success = false, message = "You can't sell assets while incarcerated." }
	end

	state.Assets = state.Assets or {}
	state.Flags = state.Flags or {}

	local bucket = state.Assets[assetType]
	if not bucket then
		return { success = false, message = "You don't own anything like that." }
	end

	for index, asset in ipairs(bucket) do
		if asset.id == assetId then
			local payout = math.floor((asset.value or 0) * 0.7)
			table.remove(bucket, index)
			self:addMoney(state, payout)

			if assetType == "Vehicles" and #bucket == 0 then
				state.Flags.has_vehicle = nil
				state.Flags.has_car = nil
			elseif assetType == "Properties" and #bucket == 0 then
				state.Flags.has_property = nil
				state.Flags.homeowner = nil
			end

			local feed = string.format("You sold %s for %s.", asset.name or "an asset", formatMoney(payout))
			self:pushState(player, feed)
			return { success = true, message = feed }
		end
	end

	return { success = false, message = "Asset not found." }
end

function LifeBackend:handleGamble(player, betAmount, finalSymbols)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	if betAmount <= 0 then
		return { success = false, message = "Bet a positive amount." }
	end

	if (state.Money or 0) < betAmount then
		return { success = false, message = "Not enough money to bet." }
	end

	self:addMoney(state, -betAmount)

	-- For now, trust client symbols; you can swap this to a pure server roll later.
	local won = finalSymbols[1] == finalSymbols[2] and finalSymbols[2] == finalSymbols[3]
	local payout = 0
	local message
	if won then
		payout = betAmount * 5
		self:addMoney(state, payout)
		message = string.format("JACKPOT! You won %s!", formatMoney(payout))
	else
		message = "Better luck next time."
	end

	self:pushState(player, message)
	return { success = won, winnings = payout, message = message }
end

-- ============================================================================
-- Relationships & Interactions
-- ============================================================================

local function inferNameFromId(identifier)
	if type(identifier) ~= "string" or identifier == "" then
		return nil
	end
	local cleaned = identifier:gsub("_", " ")
	return cleaned:sub(1, 1):upper() .. cleaned:sub(2)
end

function LifeBackend:createRelationship(state, relType, options)
	state.Relationships = state.Relationships or {}
	state.Flags = state.Flags or {}
	options = options or {}

	-- Prefer EventEngine for dynamic friend/romance generation
	if EventEngine and EventEngine.createRelationship and not options.id and (relType == "friend" or relType == "romance" or relType == "partner" or relType == "enemy") then
		local success, relationship = pcall(EventEngine.createRelationship, state, relType, options)
		if success and relationship then
			return relationship
		end
		if not success then
			warn("[LifeBackend] EventEngine relationship creation failed:", relationship)
		end
	end

	local newId = options.id or string.format("%s_%s", relType, HttpService:GenerateGUID(false))
	local defaultName = inferNameFromId(options.id) or inferNameFromId(relType) or "Person"
	local relationship = {
		id = newId,
		name = options.name or defaultName,
		type = relType,
		role = options.role or defaultName,
		relationship = options.startLevel or 60,
		age = options.age or state.Age,
		gender = options.gender,
		alive = options.alive ~= false,
	}

	state.Relationships[newId] = relationship

	if relType == "romance" or relType == "partner" then
		state.Relationships.partner = relationship
		state.Flags.has_partner = true
		state.Flags.dating = true
	end

	return relationship
end

local InteractionEffects = {
	family = {
		hug = { delta = 6, cost = 0, message = "You hugged them tightly." },
		talk = { delta = 4, message = "You caught up on life." },
		gift = { delta = 5, cost = 100, message = "You bought them a thoughtful gift." },
		argue = { delta = -8, message = "You argued and tensions rose." },
		money = { delta = -2, message = "You asked them for money.", grant = function(state) state.Money = (state.Money or 0) + RANDOM:NextInteger(100, 500) end },
		vacation = { delta = 10, cost = 2000, message = "You took them on a vacation." },
		apologize = { delta = 7, message = "You apologized for past mistakes." },
	},
	romance = {
		date = { delta = 8, cost = 100, message = "You went on a romantic date." },
		gift = { delta = 9, cost = 200, message = "You surprised them with a gift." },
		kiss = { delta = 5, message = "You shared a kiss." },
		propose = { delta = 15, cost = 5000, message = "You proposed!", flags = { engaged = true, committed_relationship = true } },
		breakup = { delta = -999, message = "You ended the relationship.", remove = true, clearFlags = { "has_partner", "dating", "committed_relationship", "married", "engaged" } },
		flirt = { delta = 4, message = "You flirted playfully." },
		compliment = { delta = 3, message = "You complimented them." },
		meet_someone = {
			forceNewRelationship = true,
			requiresSingle = true,
			delta = 10,
			message = function(_, relationship)
				local name = (relationship and relationship.name) or "someone new"
				return string.format("You hit it off with %s!", name)
			end,
		},
	},
	friend = {
		hangout = { delta = 6, message = "You hung out together." },
		gift = { delta = 4, cost = 50, message = "You gave them a small gift." },
		support = { delta = 5, message = "You supported them through a tough time." },
		party = { delta = 7, message = "You partied together." },
		betray = { delta = -15, message = "You betrayed their trust." },
		ghost = { delta = -999, message = "You ghosted them.", remove = true },
		make_friend = {
			forceNewRelationship = true,
			delta = 12,
			message = function(_, relationship)
				local name = (relationship and relationship.name) or "a new friend"
				return string.format("You became friends with %s.", name)
			end,
		},
	},
	enemy = {
		insult = { delta = -6, message = "You insulted them." },
		fight = { delta = -10, message = "You got into a fight.", stats = { Health = -5 } },
		forgive = { delta = 10, message = "You forgave them.", convert = "friend" },
		prank = { delta = -4, message = "You pulled a prank on them." },
		ignore = { delta = 0, message = "You ignored them." },
	},
}

function LifeBackend:ensureRelationship(state, relType, targetId, options)
	options = options or {}
	state.Relationships = state.Relationships or {}

	-- If we have a specific targetId and it exists, return it
	if targetId and state.Relationships[targetId] then
		return state.Relationships[targetId]
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- FAMILY MEMBER HANDLING
	-- For family types (mother, father, sibling, etc.), do NOT create generic entries.
	-- Family members are created server-side in createInitialState(). If a family
	-- member doesn't exist in state.Relationships, return nil so the client knows
	-- this person doesn't exist (preventing the "deleted family" bug).
	-- ═══════════════════════════════════════════════════════════════════════════════
	if relType == "family" then
		-- If targetId is specified but doesn't exist, the family member doesn't exist
		if targetId then
			local familyIds = {"mother", "father", "grandmother", "grandfather", "brother", "sister", "son", "daughter"}
			for _, familyType in ipairs(familyIds) do
				if targetId:lower():find(familyType) then
					-- This is a family ID but it doesn't exist in state - return nil
					debugPrint(string.format("Family member '%s' not found in state - returning nil", targetId))
					return nil
				end
			end
		end
		
		-- For generic family requests without targetId, also return nil (don't create randoms)
		return nil
	end

	-- Force create a new relationship if requested
	if options.forceNewRelationship then
		return self:createRelationship(state, relType, options.relationshipOptions)
	end

	-- Friend: create new friend if no specific target
	if relType == "friend" and not targetId then
		return self:createRelationship(state, "friend", options.relationshipOptions)
	end

	-- Romance: find existing partner or create new one
	if relType == "romance" then
		if targetId and state.Relationships[targetId] then
			return state.Relationships[targetId]
		end

		local partner = state.Relationships.partner
		if partner and partner.alive ~= false then
			return partner
		end

		return self:createRelationship(state, "romance", options.relationshipOptions)
	end

	-- Enemy: create new enemy if no specific target
	if relType == "enemy" and not targetId then
		return self:createRelationship(state, "enemy", options.relationshipOptions)
	end

	-- For other relationship types with targetId that doesn't exist, create it
	if targetId and not state.Relationships[targetId] then
		local relOptions = shallowCopy(options.relationshipOptions or {})
		relOptions.id = targetId
		return self:createRelationship(state, relType, relOptions)
	end

	return targetId and state.Relationships[targetId] or nil
end

function LifeBackend:handleInteraction(player, payload)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	if type(payload) ~= "table" then
		return { success = false, message = "Invalid interaction payload." }
	end

	local relType = payload.relationshipType or "family"
	local actionId = payload.actionId
	local targetId = payload.targetId
	local targetStrength = tonumber(payload.relationshipStrength)

	local actionSet = InteractionEffects[relType]
	if not actionSet then
		return { success = false, message = "Unknown relationship type." }
	end

	local action = actionSet[actionId]
	if not action then
		return { success = false, message = "Unknown interaction." }
	end

	state.Flags = state.Flags or {}
	state.Relationships = state.Relationships or {}

	-- Single-only actions (meet_someone etc.)
	if action.requiresSingle then
		local partner = state.Relationships.partner
		if partner and partner.alive ~= false then
			return { success = false, message = "You're already in a relationship." }
		end
	end

	-- Money / cost checks
	if action.cost and (state.Money or 0) < action.cost then
		return { success = false, message = "You can't afford that gesture." }
	end

	if action.cost then
		self:addMoney(state, -action.cost)
	end

	local ensureOptions = {
		forceNewRelationship = action.forceNewRelationship,
		relationshipOptions = {
			id = targetId,
			name = payload.targetName,
			role = payload.targetRole,
			startLevel = targetStrength,
		},
	}

	local relationship = self:ensureRelationship(state, relType, targetId, ensureOptions)
	if not relationship then
		return { success = false, message = "No one to interact with." }
	end

	-- Apply relationship strength change
	if action.delta then
		relationship.relationship = clamp((relationship.relationship or 50) + action.delta, -100, 100)
	end

	-- Stat changes
	if action.stats then
		self:applyStatChanges(state, action.stats)
	end

	-- Optional reward / grant
	local grantMessage
	if action.grant then
		local ok, result = pcall(action.grant, state, relationship, payload)
		if not ok then
			warn("[LifeBackend] Interaction grant failed:", result)
		elseif type(result) == "string" then
			grantMessage = result
		elseif type(result) == "table" and result.message then
			grantMessage = result.message
		end
	end

	-- Removal (breakup / ghost, etc.) – ONLY this relationship
	if action.remove then
		if relationship.id and state.Relationships[relationship.id] then
			state.Relationships[relationship.id] = nil
		end

		if relType == "romance" and state.Relationships.partner == relationship then
			state.Relationships.partner = nil
			state.Flags.has_partner = nil
			state.Flags.dating = nil
			state.Flags.committed_relationship = nil
			state.Flags.married = nil
			state.Flags.engaged = nil
		end
	end

	-- Convert enemy -> friend, etc.
	if action.convert == "friend" then
		relationship.type = "friend"
		relationship.role = "Friend"
	end

	-- Flags
	if action.flag then
		state.Flags[action.flag] = true
	end

	if action.flags then
		for flagName, value in pairs(action.flags) do
			state.Flags[flagName] = value
		end
	end

	if action.clearFlags then
		for _, flagName in ipairs(action.clearFlags) do
			state.Flags[flagName] = nil
		end
	end

	-- Feed message
	local feed
	if type(action.message) == "function" then
		local ok, message = pcall(action.message, state, relationship, action, payload)
		if ok then
			feed = message
		else
			warn("[LifeBackend] Interaction message handler failed:", message)
		end
	end

	feed = feed or grantMessage or action.message or "You interacted."
	self:pushState(player, feed)

	-- IMPORTANT: do NOT return full state here – the UI should rely on SyncState,
	-- or only use this small payload for local row updates.
	return {
		success = true,
		message = feed,
		targetId = relationship.id,
		relationshipValue = relationship.relationship,
	}
end

-- ============================================================================
-- Story Paths
-- ============================================================================

function LifeBackend:startStoryPath(player, pathId)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	local path = StoryPaths[pathId]
	if not path then
		return { success = false, message = "Unknown path." }
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #1: Premium path gamepass checks
	-- Celebrity and Royal paths require gamepasses
	-- ═══════════════════════════════════════════════════════════════════════════════
	local premiumPaths = {
		celebrity = { key = "CELEBRITY", displayName = "Fame Package" },
		royal = { key = "ROYALTY", displayName = "Royalty Pass" },
	}
	
	local premiumInfo = premiumPaths[pathId]
	if premiumInfo then
		if not self:checkGamepassOwnership(player, premiumInfo.key) then
			self:promptGamepassPurchase(player, premiumInfo.key)
			return { 
				success = false, 
				-- MINOR FIX #3: Cleaner gamepass name in error message
				message = "👑 The " .. path.name .. " path requires the " .. premiumInfo.displayName .. " gamepass.",
				needsGamepass = true,
				gamepassKey = premiumInfo.key
			}
		end
	end

	local req = path.requirements or {}

	if (state.Age or 0) < (path.minAge or 0) then
		return { success = false, message = "You're too young for this path." }
	end

	if req.education and not self:meetsEducationRequirement(state, req.education) then
		return { success = false, message = "You need more education first." }
	end

	if req.smarts and (state.Stats and state.Stats.Smarts or 0) < req.smarts then
		return { success = false, message = "You need to be smarter to walk this path." }
	end

	if req.looks and (state.Stats and state.Stats.Looks or 0) < req.looks then
		return { success = false, message = "You need higher looks for this path." }
	end

	if req.happiness and (state.Stats and state.Stats.Happiness or 0) < req.happiness then
		return { success = false, message = "You need to be happier for this path." }
	end

	state.Paths = state.Paths or {}
	state.Paths[pathId] = 0
	state.Paths.active = pathId
	state.ActivePath = pathId

	local feed = string.format("You began the %s path.", path.name)
	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:performPathAction(player, pathId, actionId)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	state.Paths = state.Paths or {}

	if state.Paths.active ~= pathId then
		return { success = false, message = "You're not on that path." }
	end

	local actionSet = StoryPathActions[pathId]
	if not actionSet then
		return { success = false, message = "No actions available." }
	end

	local action = actionSet[actionId]
	if not action then
		return { success = false, message = "Unknown path action." }
	end

	if action.cost and (state.Money or 0) < action.cost then
		return { success = false, message = "Insufficient funds for that move." }
	end

	if action.cost then
		self:addMoney(state, -action.cost)
	end

	if action.stats then
		self:applyStatChanges(state, action.stats)
	end

	local progress = state.Paths[pathId] or 0
	local path = StoryPaths[pathId]
	local stages = path.stages

	if action.reward then
		local payout = RANDOM:NextInteger(action.reward[1], action.reward[2])
		self:addMoney(state, payout)
	end

	if action.risk and RANDOM:NextInteger(1, 100) <= action.risk then
		progress = math.max(0, progress - RANDOM:NextNumber())
		state.Paths[pathId] = progress
		self:pushState(player, "A risky move set you back on your path.", {
			showPopup = true,
			emoji = "⚠️",
			title = "Setback",
			body = "Your risky move caused a setback.",
			wasSuccess = false,
		})
		return { success = false, message = "The move backfired." }
	end

	progress = progress + (action.progress or 0.05)
	if progress >= #stages then
		state.Paths[pathId] = #stages
		state.Paths.active = nil
		state.ActivePath = nil
		local feed = string.format("You completed the %s path!", path.name)
		self:pushState(player, feed, {
			showPopup = true,
			emoji = "🌟",
			title = "Path Complete",
			body = feed,
			wasSuccess = true,
		})
		return { success = true, message = feed }
	end

	state.Paths[pathId] = progress
	self:pushState(player, "You progressed along your path.")
	return { success = true, message = "Progress made." }
end

-- ============================================================================
-- Minigames
-- ============================================================================

function LifeBackend:handleMinigameResult(player, won, payload)
	local state = self:getState(player)
	if not state then
		return
	end
	
	-- CRITICAL FIX: Check if there's a pending event minigame to resolve
	local pending = self.pendingMinigameEvents and self.pendingMinigameEvents[player.UserId]
	if pending and pending.eventDef and pending.choice then
		local choice = pending.choice
		local eventDef = pending.eventDef
		
		-- Create minigame result object
		local minigameResult = {
			success = won,
			won = won,
			payload = payload or {},
		}
		
		-- Execute the onResolve handler with minigame result
		if choice.onResolve and type(choice.onResolve) == "function" then
			local success, err = pcall(function()
				choice.onResolve(state, minigameResult)
			end)
			if not success then
				warn("[LifeBackend] Event minigame onResolve error:", err)
			end
		end
		
		-- Apply base effects from the choice
		if choice.effects then
			self:applyStatChanges(state, choice.effects)
		end
		
		-- Apply setFlags
		if choice.setFlags then
			state.Flags = state.Flags or {}
			for flag, value in pairs(choice.setFlags) do
				state.Flags[flag] = value
			end
		end
		
		-- Clear the pending minigame
		self.pendingMinigameEvents[player.UserId] = nil
		
		-- Complete the age cycle
		state.awaitingDecision = false
		local feedText = choice.feedText or (won and "You succeeded!" or "You failed.")
		self:completeAgeCycle(player, state, feedText)
		
		return
	end
	
	-- Fallback for standalone minigames (not event-related)
	if won then
		self:applyStatChanges(state, { Happiness = 3 })
	else
		self:applyStatChanges(state, { Happiness = -2 })
	end
	self:pushState(player, won and "You crushed the minigame!" or "You failed the minigame.")
end

-- ============================================================================
-- PREMIUM FEATURES: Organized Crime / Mob System
-- ============================================================================

-- Crime family definitions
-- Mob operations
function LifeBackend:handleJoinMob(player, familyId)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end

	local canJoin, reason = MobSystem:canJoinMob(state)
	if not canJoin then
		return { success = false, message = reason or "You can't join the mob right now." }
	end

	if not self:checkGamepassOwnership(player, "MAFIA") then
		self:promptGamepassPurchase(player, "MAFIA")
		return {
			success = false,
			message = "Organized crime requires the Mafia gamepass.",
			needsGamepass = true,
		}
	end

	local success, message = MobSystem:joinFamily(state, familyId)
	if not success then
		return { success = false, message = message or "The family rejected you." }
	end

	local msg = message or "You've joined the crime family."
	self:pushState(player, msg)
	
	return { success = true, message = msg, mobState = MobSystem:serialize(state) }
end

function LifeBackend:handleLeaveMob(player)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end

	local success, message, consequences = MobSystem:leaveFamily(state)
	if not success then
		return { success = false, message = message or "You can't leave right now." }
	end

	if type(consequences) == "table" and #consequences > 0 then
		appendFeed(state, table.concat(consequences, " "))
	end

	local msg = message or "You left the family. Watch your back..."
	self:pushState(player, msg)
	
	return { success = true, message = msg }
end

function LifeBackend:handleMobOperation(player, operationId)
	-- CRITICAL FIX #12: Check MAFIA gamepass before operations
	if not self:checkGamepassOwnership(player, "MAFIA") then
		self:promptGamepassPurchase(player, "MAFIA")
		return {
			success = false,
			message = "🔫 Organized Crime operations require the Mafia gamepass.",
			needsGamepass = true,
			gamepassKey = "MAFIA"
		}
	end
	
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end
	local success, message, opResult = MobSystem:doOperation(state, operationId)
	if success then
		local resp = {
			success = true,
			message = message or "Operation complete!",
			money = opResult and opResult.money,
			respect = opResult and opResult.respect,
			promoted = opResult and opResult.promoted,
		}
		self:pushState(player, resp.message)
		return resp
	end

	local resultPayload = {
		success = false,
		message = message or "The operation failed.",
		arrested = opResult and opResult.arrested,
	}

	if opResult and opResult.arrested then
		self:pushState(player, resultPayload.message)
	end

	return resultPayload
end

function LifeBackend:handleGodModeEdit(player, payload)
	payload = payload or {}
	if not self:checkGamepassOwnership(player, "GOD_MODE") then
		self:promptGamepassPurchase(player, "GOD_MODE")
		return {
			success = false,
			message = "⚡ God Mode requires the God Mode gamepass.",
			needsGamepass = true,
		}
	end

	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	local summaries = {}
	local statsPayload = payload.stats or {}

	local function applyStat(key, value)
		if value == nil then
			return
		end
		local num = tonumber(value)
		if not num then
			return
		end
		num = clamp(math.floor(num + 0.5), 0, 100)
		state.Stats = state.Stats or {}
		state.Stats[key] = num
		state[key] = num
		table.insert(summaries, string.format("%s set to %d%%", key, num))
	end

	applyStat("Happiness", statsPayload.Happiness or payload.Happiness)
	applyStat("Health", statsPayload.Health or payload.Health)
	applyStat("Smarts", statsPayload.Smarts or payload.Smarts)
	applyStat("Looks", statsPayload.Looks or payload.Looks)

	if payload.name and type(payload.name) == "string" then
		local trimmed = payload.name:gsub("^%s+", ""):gsub("%s+$", "")
		if trimmed ~= "" then
			state.Name = trimmed:sub(1, 40)
			table.insert(summaries, "Name updated")
		end
	end

	-- CRITICAL FIX: Store gender with proper capitalization for client compatibility
	if payload.gender and type(payload.gender) == "string" then
		local genderLower = payload.gender:lower()
		if genderLower == "male" then
			state.Gender = "Male"
			table.insert(summaries, "Gender updated")
		elseif genderLower == "female" then
			state.Gender = "Female"
			table.insert(summaries, "Gender updated")
		elseif genderLower == "nonbinary" then
			state.Gender = "Nonbinary"
			table.insert(summaries, "Gender updated")
		end
	end

	if payload.money ~= nil then
		local money = tonumber(payload.money)
		if money then
			state.Money = math.max(0, math.floor(money))
			table.insert(summaries, "Money set to " .. formatMoney(state.Money))
		end
	end

	if payload.clearCareer then
		if state.CurrentJob then
			state:ClearCareer()
			table.insert(summaries, "Career cleared")
		end
	elseif payload.careerId and type(payload.careerId) == "string" and payload.careerId ~= "" then
		local jobData = self:findJobByInput(payload.careerId)
		if jobData then
			state:SetCareer(jobData)
			table.insert(summaries, "Career set to " .. jobData.name)
		else
			return { success = false, message = "Couldn't find a career matching '" .. payload.careerId .. "'." }
		end
	end

	-- GOD MODE CHARACTER CREATION FEATURES
	-- Handle family wealth setting (only during creation - godModeCreate flag)
	if payload.godModeCreate and payload.familyWealth then
		local wealthSettings = {
			["Poor"] = { min = 0, max = 500, flag = "poor_family" },
			["Lower Middle"] = { min = 1000, max = 5000, flag = nil },
			["Middle Class"] = { min = 5000, max = 20000, flag = nil },
			["Upper Middle"] = { min = 50000, max = 100000, flag = "wealthy_parents" },
			["Rich"] = { min = 500000, max = 2000000, flag = "rich_family" },
			["Famous"] = { min = 5000000, max = 10000000, flag = "famous_family" },
		}
		
		local wealth = wealthSettings[payload.familyWealth]
		if wealth then
			local moneyAmount = RANDOM:NextInteger(wealth.min, wealth.max)
			state.Money = moneyAmount
			if wealth.flag then
				state.Flags = state.Flags or {}
				state.Flags[wealth.flag] = true
			end
			-- CRITICAL FIX: Use specific message based on wealth level
			local wealthMessage = "Family wealth set to " .. payload.familyWealth
			if payload.familyWealth == "Famous" then
				wealthMessage = "👑 Born into a famous royal family with $" .. formatMoney(moneyAmount) .. " inheritance!"
			elseif payload.familyWealth == "Rich" then
				wealthMessage = "🏰 Born into a wealthy family with $" .. formatMoney(moneyAmount) .. " trust fund!"
			elseif payload.familyWealth == "Upper Middle" then
				wealthMessage = "🏢 Born into an upper middle class family with $" .. formatMoney(moneyAmount) .. "."
			elseif payload.familyWealth == "Poor" then
				wealthMessage = "🏚️ Born into a poor family. Starting with just $" .. formatMoney(moneyAmount) .. "."
			end
			table.insert(summaries, wealthMessage)
		end
	end
	
	-- CRITICAL FIX: Handle starting stats from God Mode creation
	if payload.godModeCreate and payload.stats then
		if type(payload.stats) == "table" then
			-- Apply custom starting stats
			if payload.stats.Happiness then
				state.Happiness = math.clamp(tonumber(payload.stats.Happiness) or 50, 0, 100)
			end
			if payload.stats.Health then
				state.Health = math.clamp(tonumber(payload.stats.Health) or 100, 0, 100)
			end
			if payload.stats.Smarts then
				state.Smarts = math.clamp(tonumber(payload.stats.Smarts) or 50, 0, 100)
			end
			if payload.stats.Looks then
				state.Looks = math.clamp(tonumber(payload.stats.Looks) or 50, 0, 100)
			end
			table.insert(summaries, "Starting stats customized")
		end
	end
	
	-- Handle ethnicity setting
	if payload.ethnicity and payload.ethnicity ~= "Random" then
		state.Flags = state.Flags or {}
		state.Flags.ethnicity = payload.ethnicity
		table.insert(summaries, "Ethnicity set to " .. payload.ethnicity)
	end
	
	-- Handle country setting
	if payload.country then
		state.Flags = state.Flags or {}
		state.Flags.country = payload.country
		table.insert(summaries, "Country set to " .. payload.country)
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #7: ROYAL BIRTH INITIALIZATION
	-- Handle "Born Royal" family wealth option - requires Royalty gamepass
	-- ═══════════════════════════════════════════════════════════════════════════════
	if payload.familyWealth == "Royal" or payload.familyWealth == "Royalty" or payload.bornRoyal then
		if self:checkGamepassOwnership(player, "ROYALTY") then
			-- Initialize royal state
			local royalCountryId = payload.royalCountry or "uk" -- Default to UK
			local royalCountries = {
				uk = { id = "uk", name = "United Kingdom", emoji = "🇬🇧", palace = "Buckingham Palace", startingWealth = { min = 50000000, max = 500000000 } },
				spain = { id = "spain", name = "Spain", emoji = "🇪🇸", palace = "Royal Palace of Madrid", startingWealth = { min = 30000000, max = 200000000 } },
				japan = { id = "japan", name = "Japan", emoji = "🇯🇵", palace = "Imperial Palace", startingWealth = { min = 100000000, max = 800000000 } },
				monaco = { id = "monaco", name = "Monaco", emoji = "🇲🇨", palace = "Prince's Palace", startingWealth = { min = 200000000, max = 1000000000 } },
				saudi = { id = "saudi", name = "Saudi Arabia", emoji = "🇸🇦", palace = "Al-Yamamah Palace", startingWealth = { min = 500000000, max = 5000000000 } },
				sweden = { id = "sweden", name = "Sweden", emoji = "🇸🇪", palace = "Stockholm Palace", startingWealth = { min = 20000000, max = 150000000 } },
				netherlands = { id = "netherlands", name = "Netherlands", emoji = "🇳🇱", palace = "Royal Palace Amsterdam", startingWealth = { min = 30000000, max = 200000000 } },
				belgium = { id = "belgium", name = "Belgium", emoji = "🇧🇪", palace = "Royal Palace of Brussels", startingWealth = { min = 25000000, max = 180000000 } },
				denmark = { id = "denmark", name = "Denmark", emoji = "🇩🇰", palace = "Amalienborg Palace", startingWealth = { min = 25000000, max = 150000000 } },
				norway = { id = "norway", name = "Norway", emoji = "🇳🇴", palace = "Royal Palace Oslo", startingWealth = { min = 25000000, max = 150000000 } },
				morocco = { id = "morocco", name = "Morocco", emoji = "🇲🇦", palace = "Royal Palace of Rabat", startingWealth = { min = 80000000, max = 400000000 } },
				jordan = { id = "jordan", name = "Jordan", emoji = "🇯🇴", palace = "Al-Husseiniya Palace", startingWealth = { min = 50000000, max = 300000000 } },
				thailand = { id = "thailand", name = "Thailand", emoji = "🇹🇭", palace = "Grand Palace", startingWealth = { min = 100000000, max = 600000000 } },
			}
			
			local country = royalCountries[royalCountryId] or royalCountries.uk
			local wealthRange = country.startingWealth
			local royalWealth = RANDOM:NextInteger(wealthRange.min, wealthRange.max)
			
			-- Determine title based on gender
			local gender = state.Gender or "Male"
			local title = (gender == "Female") and "Princess" or "Prince"
			
			-- Initialize royal state
			state.RoyalState = {
				isRoyal = true,
				isMonarch = false,
				country = country.id,
				countryName = country.name,
				countryEmoji = country.emoji,
				palace = country.palace,
				title = title,
				lineOfSuccession = RANDOM:NextInteger(1, 5),
				popularity = 75 + RANDOM:NextInteger(-10, 10),
				scandals = 0,
				dutiesCompleted = 0,
				dutyStreak = 0,
				reignYears = 0,
				wealth = royalWealth,
				awards = {},
				charitiesPatronized = {},
				stateVisits = {},
			}
			
			state.Money = royalWealth
			
			-- Set royal flags
			state.Flags.is_royalty = true
			state.Flags.royal_birth = true
			state.Flags.royal_country = country.id
			state.Flags.wealthy_family = true
			state.Flags.upper_class = true
			state.Flags.famous_family = true
			state.Flags.royalty_gamepass = true
			
			table.insert(summaries, string.format("👑 Born as %s of %s %s with $%s inheritance!", title, country.emoji, country.name, formatMoney(royalWealth)))
		else
			-- No gamepass, prompt purchase
			self:promptGamepassPurchase(player, "ROYALTY")
			table.insert(summaries, "👑 Royal birth requires the Royalty gamepass!")
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #8: CELEBRITY CAREER INITIALIZATION
	-- Handle starting a fame career from character creation - requires Celebrity gamepass
	-- ═══════════════════════════════════════════════════════════════════════════════
	if payload.famePath and payload.famePath ~= "" then
		if self:checkGamepassOwnership(player, "CELEBRITY") then
			local careerPaths = {
				actor = { name = "Acting", emoji = "🎬", firstStage = "Extra", salary = { min = 500, max = 2000 } },
				musician = { name = "Music", emoji = "🎵", firstStage = "Street Performer", salary = { min = 50, max = 500 } },
				influencer = { name = "Social Media", emoji = "📱", firstStage = "New Creator", salary = { min = 0, max = 100 } },
				athlete = { name = "Professional Sports", emoji = "🏆", firstStage = "Amateur", salary = { min = 0, max = 500 } },
				model = { name = "Modeling", emoji = "📸", firstStage = "Amateur Model", salary = { min = 100, max = 1000 } },
			}
			
			local path = careerPaths[payload.famePath]
			if path then
				state.FameState = {
					isFamous = false,
					careerPath = payload.famePath,
					careerName = path.name,
					currentStage = 1,
					stageName = path.firstStage,
					subType = payload.fameSubType,
					yearsInCareer = 0,
					lastPromotionYear = 0,
					followers = 0,
					endorsements = {},
					awards = {},
					scandals = 0,
					fameLevel = "Unknown",
				}
				
				state.CurrentJob = {
					id = payload.famePath .. "_starter",
					name = path.firstStage,
					company = path.name .. " Industry",
					salary = RANDOM:NextInteger(path.salary.min, path.salary.max),
					category = "entertainment",
					isFameCareer = true,
				}
				
				state.Flags.fame_career = true
				state.Flags.entertainment_industry = true
				state.Flags["career_" .. payload.famePath] = true
				state.Flags.employed = true
				state.Flags.has_job = true
				state.Flags.celebrity_gamepass = true
				
				table.insert(summaries, string.format("%s Started %s career as %s!", path.emoji, path.name, path.firstStage))
			end
		else
			self:promptGamepassPurchase(player, "CELEBRITY")
			table.insert(summaries, "⭐ Fame careers require the Celebrity gamepass!")
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #20: GOD MODE PRESETS - Quick preset application
	-- ═══════════════════════════════════════════════════════════════════════════════
	if payload.preset then
		if GodModeSystem then
			local success, msg = GodModeSystem:applyPreset(state, payload.preset)
			if success then
				table.insert(summaries, msg)
			end
		end
	end
	
	-- Handle clearing flags (criminal record, diseases, addictions, debt)
	if payload.clearCriminalRecord then
		if GodModeSystem then
			GodModeSystem:clearCriminalRecord(state)
			table.insert(summaries, "📋 Criminal record cleared!")
		end
	end
	
	if payload.cureDiseases then
		if GodModeSystem then
			GodModeSystem:cureDiseases(state)
			table.insert(summaries, "💊 All diseases cured!")
		end
	end
	
	if payload.removeAddictions then
		if GodModeSystem then
			GodModeSystem:removeAddictions(state)
			table.insert(summaries, "🚭 All addictions removed!")
		end
	end
	
	if payload.clearDebt then
		if GodModeSystem then
			GodModeSystem:clearDebt(state)
			table.insert(summaries, "💳 All debt cleared!")
		end
	end

	if #summaries == 0 then
		return { success = false, message = "No God Mode changes were provided." }
	end

	state.Flags = state.Flags or {}
	state.Flags.god_mode_last_used = os.time()
	
	-- Mark as God Mode created character
	if payload.godModeCreate then
		state.Flags.god_mode_created = true
	end

	local feedText = payload.godModeCreate 
		and "⚡ A custom life begins..." 
		or ("⚡ God Mode update: " .. table.concat(summaries, " • "))
	appendFeed(state, feedText)
	self:pushState(player, feedText)

	return { success = true, message = feedText, changes = summaries }
end

function LifeBackend:handleTimeMachine(player, yearsBack)
	-- CRITICAL FIX: Check gamepass ownership first
	if not self:checkGamepassOwnership(player, "TIME_MACHINE") then
		-- Prompt purchase and return error
		self:promptGamepassPurchase(player, "TIME_MACHINE")
		return { 
			success = false, 
			message = "👑 Time Machine requires the Time Machine pass.", 
			needsGamepass = true,
			gamepassKey = "TIME_MACHINE"
		}
	end
	
	local state = self:getState(player)
	if not state then
		return { success = false, message = "State not found." }
	end
	
	local currentAge = state.Age
	local targetAge = yearsBack == -1 and 0 or (currentAge - yearsBack)
	
	if targetAge < 0 then
		targetAge = 0
	end
	
	local yearsRewound = currentAge - targetAge
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #1: Reset death state - player is no longer dead!
	-- Without this, player would still be "dead" after using Time Machine
	-- ═══════════════════════════════════════════════════════════════════════════════
	state.Flags = state.Flags or {}
	state.Flags.dead = nil
	state.DeathReason = nil
	state.DeathAge = nil
	state.DeathYear = nil
	state.CauseOfDeath = nil
	
	-- Reset to target age
	state.Age = targetAge
	state.Year = state.Year - yearsRewound
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #2: Rewind family members' ages too!
	-- If mom was 80 when you died at 55, going back to baby should make her 25 again
	-- ═══════════════════════════════════════════════════════════════════════════════
	if state.Relationships then
		for relId, rel in pairs(state.Relationships) do
			if type(rel) == "table" then
				-- Rewind their age by the same amount
				if rel.age and type(rel.age) == "number" then
					rel.age = rel.age - yearsRewound
					-- Make sure they're at least a reasonable age
					if relId == "mother" or relId == "father" then
						rel.age = math.max(rel.age, 20) -- Parents at least 20
					elseif relId:find("grand") then
						rel.age = math.max(rel.age, 50) -- Grandparents at least 50
					else
						rel.age = math.max(rel.age, 0) -- Others at least 0
					end
				end
				
				-- CRITICAL FIX #3: Resurrect family members who died after this point
				-- If we're going back 30 years, family who died in the last 30 years should be alive
				if rel.deceased and rel.deathAge then
					local theirAgeNow = (rel.age or 0)
					local theirAgeAtDeath = rel.deathAge
					-- If their "current" rewound age is before they died, bring them back
					if theirAgeNow < theirAgeAtDeath then
						rel.alive = true
						rel.deceased = nil
						rel.deathAge = nil
						rel.deathYear = nil
					end
				end
			end
		end
	end

	pruneRelationshipsForAge(state, targetAge)
	resetMobStateForAge(state, targetAge)
	
	-- Reset some stats based on age
	if targetAge == 0 then
		-- Baby reset - full reset
		state.Stats = state.Stats or {}
		state.Stats.Happiness = 90
		state.Stats.Health = 100
		state.Health = 100 -- CRITICAL: Sync both health fields!
		state.Happiness = 90
		state.Money = 0
		state.Education = "none"
		state.CurrentJob = nil
		state.Career = nil
		state.InJail = false
		state.JailYearsLeft = 0
		-- Reset education data
		if state.EducationData then
			state.EducationData = {
				Status = "enrolled",
				Level = "elementary",
				Progress = 0,
				Duration = 5,
			}
		end
		if state.MobState then
			state.MobState.inMob = false
			state.MobState.family = nil
			state.MobState.rank = nil
		end
		-- Clear most flags but keep some identity ones
		local keepFlags = { gender = state.Flags.gender }
		state.Flags = keepFlags
	else
		-- Partial reset - restore health somewhat
		state.Stats = state.Stats or {}
		state.Stats.Health = math.min(100, (state.Stats.Health or 50) + 30)
		state.Health = state.Stats.Health -- CRITICAL: Sync both health fields!
		state.InJail = false
		state.JailYearsLeft = 0
		state.Flags.in_prison = nil
		state.Flags.incarcerated = nil
	end
	
	local msg = string.format("⏰ Time traveled back to age %d!", targetAge)
	self:pushState(player, msg)
	
	return { success = true, message = msg, newAge = targetAge }
end

-- ============================================================================
-- Initialization Entry Point
-- ============================================================================

function LifeBackend:start()
	self:setupRemotes()
	for _, player in ipairs(Players:GetPlayers()) do
		self:onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(function(player)
		self:onPlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerRemoving(player)
	end)
end

local backendSingleton

return {
	init = function()
		if backendSingleton then
			return backendSingleton
		end
		backendSingleton = LifeBackend.new()
		backendSingleton:start()
		return backendSingleton
	end,
}
