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

local ModulesFolder = script:FindFirstChild("Modules") or script.Parent:FindFirstChild("Modules")
assert(ModulesFolder, "[LifeBackend] Missing Modules folder. Expected LifeServer/Modules.")

local LifeState = require(ModulesFolder:WaitForChild("LifeState"))
local LifeStageSystem = require(ModulesFolder:WaitForChild("LifeStageSystem"))
local LifeEventsFolder = ModulesFolder:WaitForChild("LifeEvents")
local LifeEvents = require(LifeEventsFolder:WaitForChild("init"))
local EventEngine = LifeEvents.EventEngine

local LifeBackend = {}
LifeBackend.__index = LifeBackend

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
	master = "Master's Degree",
	masters = "Master's Degree",
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
	{ id = "drug_dealer_street", name = "Street Dealer", company = "The Streets", emoji = "💊", salary = 45000, minAge = 16, requirement = nil, category = "criminal", illegal = true },
	{ id = "drug_dealer", name = "Drug Dealer", company = "The Organization", emoji = "💊", salary = 120000, minAge = 20, requirement = nil, category = "criminal", illegal = true },
	{ id = "hitman", name = "Hitman", company = "Unknown", emoji = "🔫", salary = 200000, minAge = 25, requirement = nil, category = "criminal", illegal = true },
	{ id = "gang_member", name = "Gang Member", company = "The Gang", emoji = "🔪", salary = 55000, minAge = 16, requirement = nil, category = "criminal", illegal = true },
	{ id = "gang_lieutenant", name = "Gang Lieutenant", company = "The Gang", emoji = "🔪", salary = 150000, minAge = 22, requirement = nil, category = "criminal", illegal = true },
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
	-- Entry points (shared)
	{ id = "script_kiddie", name = "Script Kiddie", company = "The Internet", emoji = "👶💻", salary = 0, minAge = 14, requirement = nil, category = "hacker",
		minStats = { Smarts = 55 }, description = "Learning to hack with pre-made tools" },
	{ id = "freelance_hacker", name = "Freelance Hacker", company = "Dark Web", emoji = "🖥️", salary = 60000, minAge = 18, requirement = nil, category = "hacker",
		minStats = { Smarts = 65 }, description = "Taking small hacking jobs online" },
	
	-- White Hat Path (Legit Cybersecurity)
	{ id = "pen_tester", name = "Penetration Tester", company = "SecureIT Solutions", emoji = "🔓", salary = 95000, minAge = 20, requirement = "high_school", category = "tech",
		minStats = { Smarts = 70 }, description = "Legally hack companies to find vulnerabilities" },
	{ id = "security_consultant", name = "Security Consultant", company = "CyberGuard Inc", emoji = "🛡️", salary = 165000, minAge = 25, requirement = "bachelor", category = "tech",
		minStats = { Smarts = 75 }, description = "Advise companies on cybersecurity" },
	{ id = "ciso", name = "Chief Information Security Officer", company = "Fortune 500", emoji = "🔐", salary = 420000, minAge = 32, requirement = "bachelor", category = "tech",
		minStats = { Smarts = 80 }, description = "Lead security for a major corporation" },
	
	-- Black Hat Path (Criminal Hacker)
	{ id = "black_hat_hacker", name = "Black Hat Hacker", company = "Underground", emoji = "🎭", salary = 200000, minAge = 20, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 70 }, description = "Hack for profit illegally" },
	{ id = "elite_hacker", name = "Elite Hacker", company = "Anonymous Collective", emoji = "👤", salary = 500000, minAge = 25, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 80 }, description = "One of the best hackers in the world" },
	{ id = "cyber_crime_boss", name = "Cyber Crime Boss", company = "The Syndicate", emoji = "💀", salary = 2000000, minAge = 30, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 85 }, description = "Run a cyber criminal empire" },
	{ id = "ransomware_kingpin", name = "Ransomware Kingpin", company = "Shadow Network", emoji = "☠️", salary = 10000000, minAge = 28, requirement = nil, category = "hacker", illegal = true,
		minStats = { Smarts = 90 }, description = "Control the most feared ransomware operations" },

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

local CareerTracks = {
	office = { "receptionist", "office_assistant", "data_entry", "administrative_assistant", "project_manager", "operations_director", "coo" },
	tech = { "it_support", "junior_developer", "developer", "senior_developer", "tech_lead", "software_architect", "cto" },
	medical = { "hospital_orderly", "medical_assistant", "nurse_lpn", "nurse_rn", "doctor_resident", "doctor", "chief_of_medicine" },
	legal = { "legal_assistant", "paralegal", "associate_lawyer", "lawyer", "senior_partner", "judge" },
	creative = { "graphic_designer_jr", "graphic_designer", "art_director", "actor", "movie_star" },
	finance = { "bank_teller", "accountant_jr", "financial_analyst", "investment_banker", "hedge_fund_manager", "cfo" },
	government = { "postal_worker", "city_council", "mayor", "governor", "senator", "president" },
	criminal = { "drug_dealer_street", "drug_dealer", "gang_lieutenant", "crime_boss" },
	sports = { "gym_instructor", "minor_league", "professional_athlete", "star_athlete", "head_coach" },
	-- NEW: Racing career track - from go-karts to legend
	racing = { "go_kart_racer", "amateur_racer", "professional_racer", "f1_driver", "racing_legend", "racing_team_owner" },
	-- NEW: Hacker career - white hat path (legit)
	hacker_whitehat = { "script_kiddie", "freelance_hacker", "pen_tester", "security_consultant", "ciso" },
	-- NEW: Hacker career - black hat path (criminal)
	hacker_blackhat = { "script_kiddie", "freelance_hacker", "black_hat_hacker", "elite_hacker", "cyber_crime_boss", "ransomware_kingpin" },
	-- NEW: Esports career track
	esports = { "casual_gamer", "content_creator", "pro_gamer", "esports_champion", "gaming_legend" },
}

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
	party = { stats = { Happiness = 5 }, feed = "partied with friends", cost = 0 },
	hangout = { stats = { Happiness = 3 }, feed = "hung out with friends", cost = 0 },
	nightclub = { stats = { Happiness = 6, Health = -2 }, feed = "went clubbing", cost = 50 },
	host_party = { stats = { Happiness = 8 }, feed = "hosted a party", cost = 300 },
	tv = { stats = { Happiness = 2 }, feed = "binged a show", cost = 0 },
	games = { stats = { Happiness = 3, Smarts = 1 }, feed = "played video games", cost = 0 },
	movies = { stats = { Happiness = 3 }, feed = "watched a movie", cost = 20 },
	concert = { stats = { Happiness = 5 }, feed = "went to a concert", cost = 150 },
	vacation = { stats = { Happiness = 10, Health = 4 }, feed = "took a vacation", cost = 2000 },
}

local CrimeCatalog = {
	porch_pirate = { risk = 20, reward = { 30, 200 }, jail = { min = 0.2, max = 1 } },
	shoplift = { risk = 25, reward = { 20, 150 }, jail = { min = 0.5, max = 2 } },
	pickpocket = { risk = 35, reward = { 30, 300 }, jail = { min = 0.5, max = 2 } },
	burglary = { risk = 50, reward = { 500, 5000 }, jail = { min = 2, max = 5 } },
	gta = { risk = 60, reward = { 2000, 20000 }, jail = { min = 3, max = 7 } },
	bank_robbery = { risk = 80, reward = { 10000, 500000 }, jail = { min = 5, max = 12 } },
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
	prison_gang = { stats = { Happiness = 2, Health = -3 }, feed = "aligned with a gang", flag = "gang_member" },
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
	community = { name = "Community College", cost = 15000, duration = 2, requirement = "high_school" },
	bachelor = { name = "Bachelor's Degree", cost = 80000, duration = 4, requirement = "high_school" },
	master = { name = "Master's Degree", cost = 60000, duration = 2, requirement = "bachelor" },
	law = { name = "Law School", cost = 150000, duration = 3, requirement = "bachelor" },
	medical = { name = "Medical School", cost = 200000, duration = 4, requirement = "bachelor" },
	phd = { name = "PhD Program", cost = 100000, duration = 5, requirement = "master" },
}

local EducationRanks = {
	none = 0,
	high_school = 1,
	community = 2,
	bachelor = 3,
	master = 4,
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
		stages = { "hustler", "dealer", "lieutenant", "underboss", "boss" },
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
	self.remotes.CommitCrime.OnServerInvoke = function(player, crimeId)
		return self:handleCrime(player, crimeId)
	end
	self.remotes.DoPrisonAction.OnServerInvoke = function(player, actionId)
		return self:handlePrisonAction(player, actionId)
	end

	self.remotes.ApplyForJob.OnServerInvoke = function(player, jobId)
		return self:handleJobApplication(player, jobId)
	end
	self.remotes.QuitJob.OnServerInvoke = function(player)
		return self:handleQuitJob(player)
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
end

function LifeBackend:createInitialState(player)
	local state = LifeState.new(player)
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- SERVER-SIDE FAMILY CREATION
	-- Create proper family members so they're part of authoritative state
	-- This prevents the "disappearing family" bug where client-generated defaults
	-- would conflict with server state after interactions.
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	state.Relationships = state.Relationships or {}
	
	-- Generate random names for family members
	local maleNames = {"James", "Michael", "David", "John", "Robert", "William", "Richard", "Thomas", "Charles", "Daniel"}
	local femaleNames = {"Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Susan", "Jessica", "Sarah", "Karen"}
	
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

function LifeBackend:setLifeInfo(player, name, gender)
	local state = self:getState(player)
	if not state then
		return
	end
	if name and name ~= "" then
		state.Name = name
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
	
	for _, rel in pairs(state.Relationships) do
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
			
			rel.age = (rel.age or (state.Age + 20)) + 1
			if rel.age > 95 and RANDOM:NextNumber() < 0.2 then
				rel.alive = false
				state.PendingFeed = (rel.name or "A loved one") .. " passed away."
			end
		end
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
		local duration = eduData.Duration or 4
		local progressPerYear = 100 / duration
		eduData.Progress = clamp((eduData.Progress or 0) + progressPerYear, 0, 100)
		if eduData.Progress >= 100 then
			eduData.Status = "completed"
			state.Education = eduData.Level
			state.PendingFeed = string.format("You graduated from %s!", eduData.Institution or "school")
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
	info.performance = clamp((info.performance or 60) + RANDOM:NextInteger(-3, 4), 0, 100)
	info.promotionProgress = clamp((info.promotionProgress or 0) + RANDOM:NextInteger(2, 6), 0, 100)
	
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
		-- Add to feed if significant income
		if totalIncome >= 1000 then
			local currentFeed = state.PendingFeed or ""
			if currentFeed ~= "" then
				state.PendingFeed = currentFeed .. string.format(" You collected $%s in rental income.", formatMoney(totalIncome))
			else
				state.PendingFeed = string.format("You collected $%s in rental income.", formatMoney(totalIncome))
			end
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
	result = result:gsub("{{PLAYER_NAME}}", playerName)
	result = result:gsub("{{NAME}}", playerName)
	
	-- Age replacement
	local age = state.Age or 0
	result = result:gsub("{{AGE}}", tostring(age))
	
	-- Job/company replacement
	if state.CurrentJob then
		result = result:gsub("{{JOB_NAME}}", state.CurrentJob.name or "your job")
		result = result:gsub("{{COMPANY}}", state.CurrentJob.company or "your employer")
	end
	
	-- Mother/Father name replacement
	if state.Relationships then
		if state.Relationships.mother then
			result = result:gsub("{{MOTHER_NAME}}", state.Relationships.mother.name or "Mom")
			result = result:gsub("Your mother", state.Relationships.mother.name or "Your mother")
		end
		if state.Relationships.father then
			result = result:gsub("{{FATHER_NAME}}", state.Relationships.father.name or "Dad")
			result = result:gsub("Your father", state.Relationships.father.name or "Your father")
		end
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
	
	-- CRITICAL FIX: Replace text variables with actual names
	local processedText = self:replaceTextVariables(eventDef.text, state)
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
		summaryParts = { string.format("Behind bars. %d years remaining.", state.JailYearsLeft or 0) }
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
			state.PendingFeed = "🎉 You've been released from prison! Time served."
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
	local newState = LifeState.new(player)
	self.playerStates[player] = newState
	self.pendingEvents[player.UserId] = nil
	self:pushState(player, "A new life begins...")
end

function LifeBackend:completeAgeCycle(player, state, feedText, resultData)
	local deathInfo
	if state.Health and state.Health <= 0 then
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

	local feedText = choice.feed or choice.text or "Life continues."
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

	resultData = {
		showPopup = true,
		emoji = jailPopupEmoji or eventDef.emoji,
		title = jailPopupTitle or eventDef.title,
		body = jailPopupBody or feedText,
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

	if activity.cost and activity.cost > 0 and (state.Money or 0) < activity.cost then
		return { success = false, message = "You can't afford that right now." }
	end

	if activity.cost and activity.cost > 0 then
		self:addMoney(state, -activity.cost)
	end

	local deltas = shallowCopy(activity.stats or {})
	if bonus then
		for stat, delta in pairs(deltas) do
			deltas[stat] = delta + math.ceil(delta * 0.5)
		end
	end

	self:applyStatChanges(state, deltas)

	local resultMessage = string.format("You %s.", activity.feed or "enjoyed the day")
	local resultData = {
		showPopup = true,
		emoji = "✨",
		title = "Activity Complete",
		body = resultMessage,
		happiness = deltas.Happiness,
		health = deltas.Health,
		smarts = deltas.Smarts,
		looks = deltas.Looks,
		money = activity.cost and -activity.cost or 0,
		wasSuccess = true,
	}

	self:pushState(player, resultMessage, resultData)
	return { success = true, message = resultMessage }
end

function LifeBackend:handleCrime(player, crimeId)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "No life data loaded." }
	end
	if state.InJail then
		return { success = false, message = "Serve your sentence first." }
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

	local roll = RANDOM:NextInteger(0, 100)
	local caught = roll < (crime.risk + riskModifier)

	if caught then
		local years = RANDOM:NextNumber(crime.jail.min, crime.jail.max)
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
		local message = string.format("You were caught! Sentenced to %.1f years. You lost your job.", years)
		self:pushState(player, message, {
			showPopup = true,
			emoji = "🚔",
			title = "Busted!",
			body = message,
			wasSuccess = false,
			happiness = -10,
			health = -5,
		})
		return { success = false, caught = true, message = message }
	else
		local payout = RANDOM:NextInteger(crime.reward[1], crime.reward[2])
		self:addMoney(state, payout)
		self:applyStatChanges(state, { Happiness = 4 })
		local message = string.format("Crime succeeded! You gained %s.", formatMoney(payout))
		self:pushState(player, message, {
			showPopup = true,
			emoji = "💰",
			title = "Clean Getaway",
			body = message,
			money = payout,
			happiness = 4,
			wasSuccess = true,
		})
		return { success = true, caught = false, message = message }
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
	if action.jailIncrease then
		state.JailYearsLeft = (state.JailYearsLeft or 0) + action.jailIncrease
		local message = string.format("Your escape failed. %d years added to your sentence.", action.jailIncrease)
		self:pushState(player, message, {
			showPopup = true,
			emoji = "🚔",
			title = "Caught!",
			body = message,
			wasSuccess = false,
		})
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
		state.awaitingDecision = true
		-- CRITICAL FIX: Prison escape now has real outcomes that properly clear jail flags
		local escapeChance = 0.25 + (state.Stats and state.Stats.Smarts or 0) / 200 -- 25-75% based on smarts
		local escaped = RANDOM:NextNumber() < escapeChance
		
		local eventDef
		if escaped then
			eventDef = {
				id = "prison_escape_success",
				title = "Escape Successful!",
				emoji = "🏃",
				text = "Against all odds, you made it over the wall and into freedom! You're now a fugitive.",
				question = "What now?",
				choices = {
					{ 
						text = "Lay low and start fresh", 
						deltas = { Happiness = 20 },
						setFlags = { escaped_prisoner = true, fugitive = true, criminal_record = true },
						clearFlags = { in_prison = true, incarcerated = true },
						feedText = "You escaped prison! Now living as a fugitive.",
					},
					{ 
						text = "Leave the country", 
						deltas = { Happiness = 15, Money = -5000 },
						setFlags = { escaped_prisoner = true, fugitive = true, fled_country = true },
						clearFlags = { in_prison = true, incarcerated = true },
						feedText = "You escaped and fled to another country!",
					},
				},
				-- CRITICAL: Actually free the player when event resolves
				onResolve = function(state)
					state.InJail = false
					state.JailYearsLeft = 0
					state.Flags.in_prison = nil
					state.Flags.incarcerated = nil
					state.Flags.escaped_prisoner = true
					state.Flags.fugitive = true
				end,
			}
		else
			-- Escape failed - add years to sentence
			local addedYears = RANDOM:NextInteger(2, 5)
			state.JailYearsLeft = (state.JailYearsLeft or 0) + addedYears
			eventDef = {
				id = "prison_escape_failed",
				title = "Escape Failed",
				emoji = "🚨",
				text = string.format("You were caught trying to escape! They added %d years to your sentence.", addedYears),
				choices = {
					{ 
						text = "Accept your fate", 
						deltas = { Happiness = -15, Health = -5 },
						setFlags = { escape_attempt_failed = true },
						feedText = "Your escape attempt failed. More time behind bars.",
					},
				},
			}
		end
		
		self:presentEvent(player, eventDef, escaped and "You attempted an escape..." or "You tried to escape...")
		return { success = true, message = escaped and "Escape attempt underway..." or "Planning your escape..." }
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
local JobRejectionMessages = {
	generic = {
		"After careful consideration, we've decided to go with another candidate.",
		"Unfortunately, your application was not successful this time.",
		"We appreciate your interest, but we're looking for someone with more experience.",
		"Thank you for applying, but we've filled the position.",
		"Your qualifications don't quite match what we're looking for right now.",
	},
	lowStats = {
		"You didn't pass the physical fitness requirements.",
		"The aptitude test results weren't quite what we were hoping for.",
		"We need someone with stronger qualifications for this role.",
	},
	competitive = {
		"This position attracted many highly qualified candidates.",
		"Competition for this role was extremely fierce.",
		"We received over 500 applications for this position.",
	},
	entry = {
		"Even entry-level positions can be competitive these days!",
		"We're looking for someone with a bit more availability.",
		"Your interview went well, but another candidate edged you out.",
	},
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
	
	-- Calculate acceptance chance based on multiple factors
	local baseChance = 0.90 -- 90% base for entry level jobs with no requirements
	local difficulty = job.difficulty or 1
	
	-- Reduce chance based on job difficulty (1-10 scale)
	-- difficulty 1 = easy entry job, difficulty 10 = near impossible (star athlete, CEO)
	if difficulty >= 8 then
		baseChance = 0.15 -- Elite jobs are very hard to get
	elseif difficulty >= 6 then
		baseChance = 0.35 -- Competitive positions
	elseif difficulty >= 4 then
		baseChance = 0.55 -- Moderate difficulty
	elseif difficulty >= 2 then
		baseChance = 0.75 -- Entry-level but some competition
	end
	
	-- Boost chance based on relevant experience
	state.CareerInfo = state.CareerInfo or {}
	local yearsExperience = state.CareerInfo.totalYearsWorked or 0
	local experienceBonus = math.min(0.20, yearsExperience * 0.02) -- Up to +20% for 10+ years experience
	
	-- Boost if applying to same category as previous job
	if state.Career and state.Career.track == job.category then
		experienceBonus = experienceBonus + 0.15 -- Industry experience helps!
	end
	
	-- Boost based on Smarts for office/tech jobs, Health for physical jobs
	state.Stats = state.Stats or {}
	local statBonus = 0
	if job.category == "tech" or job.category == "office" or job.category == "science" or job.category == "law" or job.category == "finance" then
		local smarts = state.Stats.Smarts or state.Smarts or 50
		statBonus = (smarts - 50) / 200 -- +/-25% based on Smarts
	elseif job.category == "military" or job.category == "sports" or job.category == "trades" then
		local health = state.Stats.Health or state.Health or 50
		statBonus = (health - 50) / 200 -- +/-25% based on Health
	end
	
	-- Previous rejection penalty (companies remember bad interviews)
	local rejectionPenalty = math.min(0.30, (appHistory.attempts or 0) * 0.10) -- -10% per previous rejection, max -30%
	
	local finalChance = math.clamp(baseChance + experienceBonus + statBonus - rejectionPenalty, 0.05, 0.98)
	
	-- Entry-level jobs (no requirements, low salary) should be easier
	if not job.requirement and (job.salary or 0) < 35000 then
		finalChance = math.max(finalChance, 0.80) -- At least 80% chance for basic jobs
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
		if difficulty >= 6 then
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
	if state.Flags.retired then
		state.Flags.retired = nil
		state.Flags.semi_retired = nil
		state.Flags.pension_amount = nil
	end
	
	-- Clear application history for this job (fresh start)
	state.JobApplications[jobId] = nil

	local feed = string.format("🎉 Congratulations! You were hired as a %s at %s!", job.name, job.company)
	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:handleQuitJob(player)
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
	local historyEntry = {
		title = state.CurrentJob.name,
		company = state.CurrentJob.company,
		salary = state.CurrentJob.salary,
		category = state.CurrentJob.category,
		yearsWorked = state.CareerInfo.yearsAtJob or 0,
		performance = state.CareerInfo.performance or 60,
		raises = state.CareerInfo.raises or 0,
		promotions = state.CareerInfo.promotions or 0,
		reason = "quit",
		endAge = state.Age or 0,
		endYear = state.Year or 2025,
	}
	table.insert(state.CareerInfo.careerHistory, historyEntry)
	
	-- Track total years worked for experience bonuses
	state.CareerInfo.totalYearsWorked = (state.CareerInfo.totalYearsWorked or 0) + (state.CareerInfo.yearsAtJob or 0)

	local jobName = state.CurrentJob.name
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

	local feed = string.format("You resigned from your job as %s.", jobName)
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

	state.CareerInfo.performance = clamp((state.CareerInfo.performance or 60) + RANDOM:NextInteger(1, 4), 0, 100)
	state.CareerInfo.promotionProgress = clamp((state.CareerInfo.promotionProgress or 0) + RANDOM:NextInteger(3, 6), 0, 100)

	local message = string.format("Payday! You earned %s.", formatMoney(payday))
	self:pushState(player, message, {
		showPopup = true,
		emoji = "💼",
		title = "Work Complete",
		body = message,
		money = payday,
	})
	return { success = true, message = message }
end

function LifeBackend:handlePromotion(player)
	local state = self:getState(player)
	if not state or not state.CurrentJob then
		return { success = false, message = "You need a job first." }
	end

	state.CareerInfo = state.CareerInfo or {}
	local info = state.CareerInfo

	if (info.promotionProgress or 0) < 80 then
		return { success = false, message = "You need more experience before a promotion." }
	end

	info.promotionProgress = 0
	state.CurrentJob.salary = math.floor((state.CurrentJob.salary or 0) * 1.2)
	info.performance = clamp((info.performance or 60) + 10, 0, 100)

	local feed = string.format("You were promoted! Salary is now %s.", formatMoney(state.CurrentJob.salary))
	self:pushState(player, feed)
	return { success = true, message = feed }
end

function LifeBackend:handleRaise(player)
	local state = self:getState(player)
	if not state or not state.CurrentJob then
		return { success = false, message = "No employer to ask." }
	end

	state.CareerInfo = state.CareerInfo or {}
	local info = state.CareerInfo

	if (info.performance or 0) < 60 then
		return { success = false, message = "Improve your performance before asking." }
	end
	if (info.raises or 0) >= 5 then
		return { success = false, message = "You've maxed out raises for this role." }
	end

	local granted = RANDOM:NextNumber() > 0.3
	if not granted then
		info.performance = clamp((info.performance or 60) - 5, 0, 100)
		return { success = false, message = "Raise denied. Maybe next quarter." }
	end

	state.CurrentJob.salary = math.floor((state.CurrentJob.salary or 0) * 1.1)
	info.raises = (info.raises or 0) + 1
	info.performance = clamp((info.performance or 60) + 5, 0, 100)

	local feed = string.format("You negotiated a raise! Salary is %s.", formatMoney(state.CurrentJob.salary))
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

	return {
		success = true,
		performance = state.CareerInfo.performance or 0,
		promotionProgress = state.CareerInfo.promotionProgress or 0,
		yearsAtJob = state.CareerInfo.yearsAtJob or 0,
		raises = state.CareerInfo.raises or 0,
		promotions = state.CareerInfo.promotions or 0, -- CRITICAL FIX: Track promotions
		careerHistory = state.CareerInfo.careerHistory or {},
		skills = state.CareerInfo.skills or {},
		track = state.Career.track,
		-- CRITICAL FIX: Add totalExperience for Career Info modal display
		totalExperience = state.CareerInfo.totalYearsWorked or 0,
		totalYearsWorked = state.CareerInfo.totalYearsWorked or 0,
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

function LifeBackend:enrollEducation(player, programId)
	local state = self:getState(player)
	if not state then
		return { success = false, message = "Life data missing." }
	end

	local program = EducationCatalog[programId]
	if not program then
		return { success = false, message = "Unknown education program." }
	end

	if not self:meetsEducationRequirement(state, program.requirement) then
		return { success = false, message = "You need to complete the prerequisite first." }
	end

	if (state.Money or 0) < program.cost then
		return { success = false, message = "You can't afford tuition." }
	end

	local prevDebt = (state.EducationData and state.EducationData.Debt) or 0

	self:addMoney(state, -program.cost)
	state.EducationData = {
		Status = "enrolled",
		Level = programId,
		Progress = 0,
		Duration = program.duration,
		Institution = program.name,
		Debt = prevDebt + program.cost,
	}
	state.Career = state.Career or {}
	state.Career.education = programId

	local feed = string.format("You enrolled in %s.", program.name)
	self:pushState(player, feed)
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
		local hasLicense = state.Flags and (state.Flags.has_license or state.Flags.drivers_license)
		if not hasLicense then
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
