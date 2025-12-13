--[[
	LifeState.lua
	
	Manages player state for the BitLife-style game.
	Provides a clean interface for state manipulation and serialization.
]]

local LifeState = {}
LifeState.__index = LifeState

local RANDOM = Random.new()

-- ════════════════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════════════════

function LifeState.new(player)
	local self = setmetatable({}, LifeState)
	
	-- Identity
	self.Player = player
	self.Name = nil
	self.Gender = nil
	
	-- Age & Time
	self.Age = 0
	self.Year = 2025
	
	-- Core Stats (0-100)
	self.Stats = {
		Happiness = 75 + RANDOM:NextInteger(-10, 10),
		Health = 100,
		Smarts = 50 + RANDOM:NextInteger(-15, 15),
		Looks = 50 + RANDOM:NextInteger(-15, 15),
	}
	
	-- Shorthand access
	self.Happiness = self.Stats.Happiness
	self.Health = self.Stats.Health
	self.Smarts = self.Stats.Smarts
	self.Looks = self.Stats.Looks
	
	-- Money
	self.Money = 0
	
	-- Education
	self.Education = "none" -- none, high_school, community, bachelor, master, law, medical, phd
	self.EducationData = {
		Status = "none", -- none, enrolled, completed
		Level = nil,
		Progress = 0,
		Duration = nil, -- CRITICAL FIX: nil instead of 0 to prevent divide-by-zero in progress calc
		Institution = nil,
		GPA = nil,
		Debt = 0,
		CreditsEarned = 0,
		CreditsRequired = 0,
		Year = 0,
		TotalYears = 0,
	}
	
	-- Career
	self.CurrentJob = nil -- { id, name, company, salary, category }
	self.CareerInfo = {
		performance = 0,
		promotionProgress = 0,
		yearsAtJob = 0,
		raises = 0,
		promotions = 0, -- CRITICAL FIX: Track promotions separately from raises
		careerHistory = {},
		skills = {},
	}
	self.Career = {
		track = nil, -- current career track
		education = nil,
	}
	
	-- CRITICAL FIX: YearLog tracks events that happen during the year
	-- Used by generateYearSummary for event-based summaries instead of random messages
	self.YearLog = {}
	
	-- Prison
	self.InJail = false
	self.JailYearsLeft = 0
	
	-- Relationships
	self.Relationships = {}
	
	-- Assets
	self.Assets = {
		Properties = {},
		Vehicles = {},
		Items = {},
		Investments = {},
		Crypto = {},
		Businesses = {},
	}
	
	-- Flags (story/behavior tracking)
	self.Flags = {}
	
	-- CRITICAL FIX: Pet data for pet lifecycle tracking
	self.PetData = {}
	
	-- CRITICAL FIX: Child count for family tracking
	self.ChildCount = 0
	
	-- Career hints from childhood choices
	self.CareerHints = {}
	
	-- Story arcs the player is pursuing
	self.StoryArcs = {}
	
	-- Story Paths progress
	self.Paths = {
		active = nil,
	}
	self.ActivePath = nil
	
	-- Fame (0-100)
	self.Fame = 0
	
	-- ════════════════════════════════════════════════════════════════════════════
	-- PREMIUM FEATURE: Organized Crime/Mob State
	-- CRITICAL FIX #12: Full mob state initialization
	-- ════════════════════════════════════════════════════════════════════════════
	self.MobState = {
		inMob = false,
		familyId = nil,
		familyName = nil,
		familyEmoji = nil,
		familyColor = nil,
		rankIndex = 1,
		rankLevel = 1,
		rankName = "Associate",
		rankEmoji = "👤",
		respect = 0,
		notoriety = 0,
		heat = 0,
		loyalty = 100,
		kills = 0,
		earnings = 0,
		yearsInMob = 0,
		operationsCompleted = 0,
		operationsFailed = 0,
		operations = {}, -- Available operations
		territories = {},
		lastEvent = nil,
	}
	
	-- ════════════════════════════════════════════════════════════════════════════
	-- PREMIUM FEATURE: Royalty State
	-- CRITICAL FIX #13: Full royalty state initialization
	-- ════════════════════════════════════════════════════════════════════════════
	self.RoyalState = {
		isRoyal = false,
		isMonarch = false,
		country = nil,
		countryName = nil,
		countryEmoji = nil,
		palace = nil,
		title = nil,
		lineOfSuccession = 0,
		popularity = 0,
		scandals = 0,
		dutiesCompleted = 0,
		dutyStreak = 0,
		reignYears = 0,
		wealth = 0,
		awards = {},
		charitiesPatronized = {},
		stateVisits = {},
	}
	
	-- ════════════════════════════════════════════════════════════════════════════
	-- PREMIUM FEATURE: Celebrity/Fame State
	-- CRITICAL FIX #14: Full celebrity state initialization
	-- ════════════════════════════════════════════════════════════════════════════
	self.FameState = {
		isFamous = false,
		careerPath = nil, -- actor, musician, influencer, athlete, model
		careerName = nil,
		currentStage = 0,
		stageName = nil,
		subType = nil, -- genre, sport, platform, etc.
		yearsInCareer = 0,
		lastPromotionYear = 0,
		followers = 0,
		endorsements = {},
		awards = {},
		scandals = 0,
		fameLevel = "Unknown",
	}
	
	-- ════════════════════════════════════════════════════════════════════════════
	-- PREMIUM FEATURE: God Mode State
	-- CRITICAL FIX #15: God mode tracking
	-- ════════════════════════════════════════════════════════════════════════════
	self.GodModeState = {
		enabled = false,
		editsThisLife = 0,
		lastEditAge = 0,
	}
	
	-- Premium gamepass ownership flags
	self.GamepassOwnership = {
		royalty = false,
		mafia = false,
		celebrity = false,
		godMode = false,
		bitizenship = false,
		timeMachine = false,
		bossMode = false,
	}
	
	-- Event History (for preventing repeats)
	self.EventHistory = {
		occurrences = {},
		lastOccurrence = {},
		completed = {},
		recentCategories = {},
		recentEvents = {},
	}
	
	-- Death info
	self.CauseOfDeath = nil
	
	-- State flags
	self.awaitingDecision = false
	self.PendingFeed = nil
	self.lastFeed = nil
	
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- AGE ADVANCEMENT
-- ════════════════════════════════════════════════════════════════════════════

function LifeState:AdvanceAge()
	self.Age = self.Age + 1
	self.Year = self.Year + 1
	
	-- Sync stat shortcuts
	self.Happiness = self.Stats.Happiness
	self.Health = self.Stats.Health
	self.Smarts = self.Stats.Smarts
	self.Looks = self.Stats.Looks
	
	-- Age-based stat decay
	if self.Age > 50 then
		local decay = math.floor((self.Age - 50) / 15)
		self.Stats.Health = math.max(0, self.Stats.Health - decay)
		self.Stats.Looks = math.max(0, self.Stats.Looks - math.floor(decay / 2))
		self.Health = self.Stats.Health
		self.Looks = self.Stats.Looks
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- EDUCATION AUTO-PROGRESSION (BitLife-style automatic school progression)
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Age 5: Start elementary school
	-- CRITICAL FIX: Elementary/Middle school are silent progressions - NO graduation events
	-- Only High School and higher get graduation events
	if self.Age == 5 and self.Education == "none" then
		self.EducationData.Status = "enrolled"
		self.EducationData.Institution = "Elementary School"
		self.EducationData.Level = "elementary" -- Mark as pre-high-school level
		self.EducationData.Duration = 6 -- Elementary is 6 years (ages 5-10)
		self.EducationData.Progress = 0
		self.Flags.in_school = true
	end
	
	-- Age 11: Middle school transition (automatic, no graduation message)
	if self.Age == 11 and self.Education == "none" then
		self.EducationData.Institution = "Middle School"
		self.EducationData.Level = "middle_school" -- Still pre-high-school
		self.EducationData.Duration = 3 -- Middle school is 3 years (ages 11-13)
		self.EducationData.Progress = 0 -- Reset progress for new phase
		-- No graduation message - this is silent progression
	end
	
	-- Age 14: Start high school (still no diploma yet!)
	-- CRITICAL FIX: Only set up high school if not already enrolled (event may have handled this)
	if self.Age == 14 and self.Education == "none" then
		-- Only initialize if not already set up by the Teen event
		if not self.EducationData.Institution or self.EducationData.Institution == "Middle School" then
			self.EducationData.Institution = "High School"
			self.EducationData.Level = "high_school"
			self.EducationData.Status = "enrolled"
			self.EducationData.Duration = 4 -- High school takes 4 years (ages 14-18)
			self.EducationData.Progress = self.EducationData.Progress or 0 -- Don't reset if already has progress
			self.Flags.in_high_school = true
		end
	end
	
	-- Age 18: Auto-graduate high school if player hasn't already via event
	-- This ensures EVERYONE gets high school education by 18
	-- CRITICAL FIX: Don't auto-graduate if player is in jail - they need to finish later
	if self.Age == 18 then
		if not self.InJail then
			if self.Education == "none" or self.EducationData.Status == "enrolled" then
				self.Education = "high_school"
				self.EducationData.Status = "completed"
				self.EducationData.Level = "high_school"
				self.Flags.graduated_high_school = true
				self.Flags.high_school_graduate = true
				self.Flags.in_high_school = nil
				if not self.PendingFeed then
					self.PendingFeed = "You automatically graduated from high school!"
				end
			end
		else
			-- Player is in jail at 18 - mark that they missed graduation
			self.Flags.missed_graduation = true
			self.EducationData.Status = "suspended"
			if not self.PendingFeed then
				self.PendingFeed = "You couldn't attend graduation because you're in prison."
			end
		end
	end
	
	-- CRITICAL FIX: Allow late high school graduation when released from jail
	-- If player missed graduation due to jail and is now out, let them complete it
	if self.Age >= 18 and self.Age <= 25 then
		if not self.InJail and self.Flags.missed_graduation then
			if self.Education == "none" then
				-- Option to get GED in prison should set this flag
				if self.EducationData and self.EducationData.Status ~= "suspended" then
					self.Education = "high_school"
					self.EducationData.Status = "completed"
					self.EducationData.Level = "high_school"
					self.Flags.graduated_high_school = true
					self.Flags.high_school_graduate = true
					self.Flags.got_ged = true
					self.Flags.missed_graduation = nil
					if not self.PendingFeed then
						self.PendingFeed = "You earned your GED!"
					end
				end
			end
		end
	end
	
	-- NOTE: Jail time is now decremented in LifeBackend.lua to prevent DOUBLE decrementation bug
	-- The duplicate code here was causing jail sentences to decrease by 2 years per age instead of 1
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- PENSION/RETIREMENT INCOME SYSTEM
	-- Retirees receive monthly pension based on their career history
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if self.Flags and self.Flags.retired then
		local pensionAmount = self.Flags.pension_amount or 0
		
		-- If no pension was set, calculate a basic social security amount
		if pensionAmount == 0 then
			-- Base social security: $12,000/year minimum, scaled by smarts (work history proxy)
			local baseSSI = 12000
			local smartsBonus = (self.Stats.Smarts or 50) * 100 -- Up to $5,000 extra
			pensionAmount = baseSSI + smartsBonus
			self.Flags.pension_amount = pensionAmount
		end
		
		-- Add annual pension (paid monthly but processed yearly)
		if pensionAmount > 0 then
			self.Money = (self.Money or 0) + pensionAmount
			-- Don't set PendingFeed if there's already one (avoid overwriting important messages)
			if not self.PendingFeed then
				self.PendingFeed = string.format("You received $%s in pension income.", pensionAmount)
			end
		end
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- SEMI-RETIRED INCOME (Part-time work)
	-- CRITICAL FIX: REMOVED duplicate salary payment!
	-- Semi-retired workers already get paid through LifeBackend:tickCareer()
	-- Having it here too was causing double-payment bug.
	-- 
	-- Note: The salary for semi-retired is halved when they become semi-retired
	-- (see Adult.lua and LifeStageSystem.lua onResolve handlers)
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- (Salary payment handled by LifeBackend:tickCareer, not here)
	
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- STAT MANIPULATION
-- ════════════════════════════════════════════════════════════════════════════

function LifeState:ModifyStat(statName, delta)
	-- CRITICAL FIX: Initialize stat if missing (prevents silent failures)
	if self.Stats[statName] == nil then
		-- Initialize common stats to default values
		local defaults = { Happiness = 50, Health = 50, Smarts = 50, Looks = 50 }
		if defaults[statName] then
			self.Stats[statName] = defaults[statName]
		else
			return self -- Unknown stat, skip silently
		end
	end
	self.Stats[statName] = math.clamp(self.Stats[statName] + delta, 0, 100)
	self[statName] = self.Stats[statName]
	return self
end

function LifeState:SetStat(statName, value)
	if self.Stats[statName] ~= nil then
		self.Stats[statName] = math.clamp(value, 0, 100)
		self[statName] = self.Stats[statName]
	end
	return self
end

function LifeState:AddMoney(amount)
	self.Money = math.max(0, self.Money + amount)
	return self
end

function LifeState:SubtractMoney(amount)
	self.Money = math.max(0, self.Money - amount)
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- FLAGS
-- ════════════════════════════════════════════════════════════════════════════

function LifeState:SetFlag(flagName, value)
	self.Flags[flagName] = value
	return self
end

function LifeState:GetFlag(flagName)
	return self.Flags[flagName]
end

function LifeState:HasFlag(flagName)
	return self.Flags[flagName] == true
end

-- ════════════════════════════════════════════════════════════════════════════
-- RELATIONSHIPS
-- ════════════════════════════════════════════════════════════════════════════

-- CRITICAL FIX #480: Support both 2-arg (id, data) and 3-arg (id, type, strength) signatures
-- Event handlers in RelationshipsExpanded.lua use: state:AddRelationship("Partner", "romantic", 0.65)
-- But the original signature was: state:AddRelationship(id, data)
function LifeState:AddRelationship(id, typeOrData, strength)
	if type(typeOrData) == "table" then
		-- Original signature: (id, data)
		self.Relationships[id] = typeOrData
	else
		-- Event handler signature: (id, type, strength)
		-- Create a proper relationship object
		local RANDOM = Random.new()
		local maleNames = {"James", "Michael", "David", "John", "Robert", "William", "Thomas", "Daniel", "Matthew", "Anthony", "Liam", "Noah", "Oliver", "Ethan", "Lucas"}
		local femaleNames = {"Emma", "Olivia", "Ava", "Isabella", "Sophia", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn", "Sarah", "Jessica", "Emily", "Ashley", "Rachel"}
		
		local relationshipType = typeOrData or "romance"
		local relationshipStrength = strength or 0.5
		
		-- Determine gender based on player's gender and relationship type
		local partnerGender = "female"
		if self.Gender == "Female" then
			partnerGender = "male"
		end
		-- Allow same-gender relationships randomly (~15% of the time for variety)
		if RANDOM:NextNumber() < 0.15 then
			partnerGender = self.Gender == "Male" and "male" or "female"
		end
		
		local nameList = partnerGender == "male" and maleNames or femaleNames
		local partnerName = nameList[RANDOM:NextInteger(1, #nameList)]
		
		local relationship = {
			id = id:lower(),
			name = partnerName,
			type = relationshipType,
			role = id, -- "Partner", "Date", etc.
			relationship = math.floor(relationshipStrength * 100), -- Convert 0-1 to 0-100
			gender = partnerGender,
			age = math.max(18, (self.Age or 18) + RANDOM:NextInteger(-5, 5)),
			alive = true,
			metAge = self.Age or 18,
		}
		
		-- Store in appropriate place based on type
		if relationshipType == "romantic" or relationshipType == "romance" then
			self.Relationships.partner = relationship
			self.Relationships[id:lower()] = relationship
		else
			self.Relationships[id:lower()] = relationship
		end
	end
	return self
end

function LifeState:GetRelationship(id)
	return self.Relationships[id]
end

function LifeState:ModifyRelationship(id, delta)
	local rel = self.Relationships[id]
	if rel then
		rel.relationship = math.clamp((rel.relationship or 50) + delta, 0, 100)
	end
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- ASSETS
-- ════════════════════════════════════════════════════════════════════════════

function LifeState:AddAsset(category, asset)
	-- CRITICAL FIX: Validate inputs to prevent crashes
	if type(category) ~= "string" or category == "" then
		warn("[LifeState:AddAsset] Invalid category:", category)
		return self
	end
	if type(asset) ~= "table" then
		warn("[LifeState:AddAsset] Invalid asset (expected table):", type(asset))
		return self
	end
	
	-- CRITICAL FIX: Ensure asset has required fields
	asset.id = asset.id or (category .. "_" .. tostring(tick()))
	asset.name = asset.name or "Unknown Asset"
	asset.value = asset.value or asset.price or 0
	
	print("[LifeState:AddAsset] Adding to category:", category)
	print("  Asset id:", asset.id, "name:", asset.name)
	
	self.Assets[category] = self.Assets[category] or {}
	table.insert(self.Assets[category], asset)
	
	print("  Total in", category .. ":", #self.Assets[category])
	return self
end

function LifeState:RemoveAsset(category, assetId)
	local bucket = self.Assets[category]
	if not bucket then return nil end
	
	for i, asset in ipairs(bucket) do
		if asset.id == assetId then
			return table.remove(bucket, i)
		end
	end
	return nil
end

function LifeState:GetNetWorth()
	local total = self.Money
	
	for _, category in pairs(self.Assets) do
		for _, asset in pairs(category) do
			if type(asset) == "table" then
				total = total + (asset.value or asset.price or 0)
			elseif type(asset) == "number" then
				total = total + asset
			end
		end
	end
	
	return math.max(0, total)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CAREER (for event handlers)
-- ════════════════════════════════════════════════════════════════════════════

function LifeState:SetCareer(jobData)
	if type(jobData) ~= "table" then return self end
	
	self.CurrentJob = {
		id = jobData.id or "unknown",
		name = jobData.name or jobData.jobTitle or "Job",
		company = jobData.company or jobData.employer or "Company",
		salary = jobData.salary or 30000,
		category = jobData.category or "general",
	}
	
	self.CareerInfo.performance = 60
	self.CareerInfo.promotionProgress = 0
	self.CareerInfo.yearsAtJob = 0
	self.Career.track = jobData.category
	
	self.Flags.employed = true
	self.Flags.has_job = true
	
	return self
end

function LifeState:ClearCareer()
	self.CurrentJob = nil
	self.CareerInfo.performance = 0
	self.CareerInfo.promotionProgress = 0
	self.CareerInfo.yearsAtJob = 0
	self.Career.track = nil
	self.Flags.employed = nil
	self.Flags.has_job = nil
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- EDUCATION (for event handlers)
-- ════════════════════════════════════════════════════════════════════════════

function LifeState:EnrollEducation(eduData)
	if type(eduData) ~= "table" then return self end
	
	self.EducationData = {
		Status = "enrolled",
		Level = eduData.type or eduData.level or "college",
		Progress = 0,
		Duration = eduData.duration or 4,
		Institution = eduData.name or eduData.institution or "University",
		GPA = nil,
		Debt = (self.EducationData.Debt or 0) + (eduData.cost or 0),
		CreditsEarned = 0,
		CreditsRequired = 120,
		Year = 1,
		TotalYears = eduData.duration or 4,
	}
	
	self.Flags.in_college = true
	self.Flags.college_student = true
	
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- FEED (for event handlers - stores pending feed text)
-- ════════════════════════════════════════════════════════════════════════════

function LifeState:AddFeed(text)
	if text and text ~= "" then
		self.PendingFeed = text
	end
	return self
end

function LifeState:ClearFlag(flagName)
	self.Flags[flagName] = nil
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: RecordEvent function for event tracking
-- Called by EventEngine to track which events have occurred
-- ════════════════════════════════════════════════════════════════════════════

function LifeState:RecordEvent(eventId, data)
	if not eventId then return self end
	
	self.EventHistory = self.EventHistory or {}
	self.EventHistory.completed = self.EventHistory.completed or {}
	self.EventHistory.occurrences = self.EventHistory.occurrences or {}
	
	self.EventHistory.completed[eventId] = true
	self.EventHistory.occurrences[eventId] = (self.EventHistory.occurrences[eventId] or 0) + 1
	
	if data then
		self.EventHistory.lastChoice = self.EventHistory.lastChoice or {}
		self.EventHistory.lastChoice[eventId] = data.choice
	end
	
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- EDUCATION DISPLAY NAME FORMATTER
-- Converts internal IDs (high_school) to display names (High School Diploma)
-- ════════════════════════════════════════════════════════════════════════════

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

function LifeState:FormatEducation(educationLevel)
	local level = educationLevel or self.Education or "none"
	if not level or level == "" then
		return "No Formal Education"
	end
	return EducationDisplayNames[level:lower()] or level:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest) return first:upper()..rest:lower() end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- SERIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

function LifeState:Serialize()
	-- Debug: Log asset counts before serialization
	print("[LifeState:Serialize] Self.Assets status:")
	if self.Assets then
		print("  Properties:", self.Assets.Properties and #self.Assets.Properties or 0)
		print("  Vehicles:", self.Assets.Vehicles and #self.Assets.Vehicles or 0)
		print("  Items:", self.Assets.Items and #self.Assets.Items or 0)
	else
		print("  WARNING: self.Assets is nil!")
	end
	
	return {
		-- Identity
		Name = self.Name,
		Gender = self.Gender,
		
		-- Age & Time
		Age = self.Age,
		Year = self.Year,
		
		-- Stats
		Stats = {
			Happiness = self.Stats.Happiness,
			Health = self.Stats.Health,
			Smarts = self.Stats.Smarts,
			Looks = self.Stats.Looks,
		},
		Happiness = self.Stats.Happiness,
		Health = self.Stats.Health,
		Smarts = self.Stats.Smarts,
		Looks = self.Stats.Looks,
		
		-- Money
		Money = self.Money,
		
		-- Education
		Education = self.Education,
		EducationDisplay = self:FormatEducation(), -- CRITICAL FIX: Human-readable education level
		EducationData = self.EducationData,
		
		-- Career
		CurrentJob = self.CurrentJob,
		CareerInfo = self.CareerInfo,
		Career = self.Career,
		
		-- Prison
		InJail = self.InJail,
		JailYearsLeft = self.JailYearsLeft,
		
		-- Relationships
		Relationships = self.Relationships,
		
		-- Assets (deep copy to ensure proper serialization)
		Assets = self.Assets,
		
		-- Flags
		Flags = self.Flags,
		
		-- Career hints
		CareerHints = self.CareerHints,
		
		-- Story
		StoryArcs = self.StoryArcs,
		Paths = self.Paths,
		ActivePath = self.ActivePath,
		
		-- Fame
		Fame = self.Fame,
		
		-- CRITICAL FIX: Pet data for pet lifecycle (needed for pet age display)
		PetData = self.PetData,
		
		-- CRITICAL FIX: Child count for family display
		ChildCount = self.ChildCount,
		
		-- ════════════════════════════════════════════════════════════════════════════
		-- PREMIUM FEATURES - Full serialization
		-- ════════════════════════════════════════════════════════════════════════════
		
		-- PREMIUM FEATURE: Mob State for organized crime
		MobState = self.MobState,
		
		-- PREMIUM FEATURE: Royalty State
		RoyalState = self.RoyalState,
		
		-- PREMIUM FEATURE: Celebrity/Fame State
		FameState = self.FameState,
		
		-- PREMIUM FEATURE: God Mode State
		GodModeState = self.GodModeState,
		
		-- Gamepass ownership for client UI
		GamepassOwnership = self.GamepassOwnership,
		
		-- Event History (needed for client to show recent events)
		EventHistory = {
			feed = self.EventHistory.feed or {},
		},
		
		-- Death
		CauseOfDeath = self.CauseOfDeath,
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- PREMIUM FEATURE HELPERS
-- ════════════════════════════════════════════════════════════════════════════

-- CRITICAL FIX #16: Initialize royalty for new character
function LifeState:InitializeRoyalty(countryData, title)
	self.RoyalState.isRoyal = true
	self.RoyalState.country = countryData.id
	self.RoyalState.countryName = countryData.name
	self.RoyalState.countryEmoji = countryData.emoji
	self.RoyalState.palace = countryData.palace
	self.RoyalState.title = title
	self.RoyalState.lineOfSuccession = math.random(1, 5)
	self.RoyalState.popularity = 75 + math.random(-10, 10)
	
	-- Calculate starting wealth
	local wealthRange = countryData.startingWealth or { min = 10000000, max = 100000000 }
	self.RoyalState.wealth = math.random(wealthRange.min, wealthRange.max)
	self.Money = self.RoyalState.wealth
	
	-- Set flags
	self.Flags.is_royalty = true
	self.Flags.royal_birth = true
	self.Flags.royal_country = countryData.id
	self.Flags.wealthy_family = true
	self.Flags.upper_class = true
	self.Flags.famous_family = true
	
	return self
end

-- CRITICAL FIX #17: Initialize mafia membership
function LifeState:InitializeMafia(familyData)
	self.MobState.inMob = true
	self.MobState.familyId = familyData.id
	self.MobState.familyName = familyData.name
	self.MobState.familyEmoji = familyData.emoji
	if familyData.color then
		self.MobState.familyColor = { familyData.color.R, familyData.color.G, familyData.color.B }
	end
	self.MobState.rankIndex = 1
	self.MobState.rankLevel = 1
	self.MobState.rankName = familyData.ranks[1].name
	self.MobState.rankEmoji = familyData.ranks[1].emoji
	self.MobState.respect = 0
	self.MobState.loyalty = 100
	self.MobState.heat = 0
	self.MobState.yearsInMob = 0
	self.MobState.operationsCompleted = 0
	self.MobState.earnings = 0
	self.MobState.kills = 0
	
	-- Set flags
	self.Flags.in_mob = true
	self.Flags.mafia_member = true
	self.Flags.criminal_lifestyle = true
	
	return self
end

-- CRITICAL FIX #18: Initialize fame career
function LifeState:InitializeFameCareer(careerPath, careerData, firstStage)
	self.FameState.careerPath = careerPath
	self.FameState.careerName = careerData.name
	self.FameState.currentStage = 1
	self.FameState.stageName = firstStage.name
	self.FameState.yearsInCareer = 0
	self.FameState.lastPromotionYear = 0
	self.FameState.followers = firstStage.followers or 0
	
	-- Set job
	self.CurrentJob = {
		id = careerPath .. "_" .. firstStage.id,
		name = firstStage.name,
		company = careerData.name .. " Industry",
		salary = math.random(firstStage.salary.min, firstStage.salary.max),
		category = "entertainment",
		isFameCareer = true,
	}
	
	-- Set flags
	self.Flags.fame_career = true
	self.Flags.entertainment_industry = true
	self.Flags["career_" .. careerPath] = true
	self.Flags.employed = true
	self.Flags.has_job = true
	
	return self
end

-- CRITICAL FIX #19: Enable god mode
function LifeState:EnableGodMode()
	self.GodModeState.enabled = true
	self.Flags.god_mode_active = true
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #95: Set gamepass flags from ownership data
-- This ensures all gamepass-related flags are properly set in state
-- ════════════════════════════════════════════════════════════════════════════
function LifeState:SetGamepassFlags(gamepassOwnership)
	if not gamepassOwnership then return self end
	
	self.GamepassOwnership = self.GamepassOwnership or {}
	self.Flags = self.Flags or {}
	
	-- Royalty gamepass
	if gamepassOwnership.Royalty or gamepassOwnership.royalty then
		self.GamepassOwnership.royalty = true
		self.GamepassOwnership.Royalty = true
		self.Flags.royalty_gamepass = true
	end
	
	-- Mafia gamepass
	if gamepassOwnership.Mafia or gamepassOwnership.mafia then
		self.GamepassOwnership.mafia = true
		self.GamepassOwnership.Mafia = true
		self.Flags.mafia_gamepass = true
	end
	
	-- Celebrity/Fame gamepass
	if gamepassOwnership.Celebrity or gamepassOwnership.celebrity then
		self.GamepassOwnership.celebrity = true
		self.GamepassOwnership.Celebrity = true
		self.Flags.celebrity_gamepass = true
	end
	
	-- God Mode gamepass
	if gamepassOwnership.GodMode or gamepassOwnership.godMode then
		self.GamepassOwnership.godMode = true
		self.GamepassOwnership.GodMode = true
		self.Flags.god_mode_gamepass = true
	end
	
	-- Bitizenship gamepass
	if gamepassOwnership.Bitizenship or gamepassOwnership.bitizenship then
		self.GamepassOwnership.bitizenship = true
		self.GamepassOwnership.Bitizenship = true
		self.Flags.bitizenship = true
	end
	
	-- Time Machine gamepass
	if gamepassOwnership.TimeMachine or gamepassOwnership.timeMachine then
		self.GamepassOwnership.timeMachine = true
		self.GamepassOwnership.TimeMachine = true
		self.Flags.time_machine_gamepass = true
	end
	
	-- Boss Mode gamepass
	if gamepassOwnership.BossMode or gamepassOwnership.bossMode then
		self.GamepassOwnership.bossMode = true
		self.GamepassOwnership.BossMode = true
		self.Flags.boss_mode_gamepass = true
	end
	
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #73/#74: Check if player should start as royalty
-- Called during character creation when player selects "Royal" family wealth
-- ════════════════════════════════════════════════════════════════════════════
function LifeState:CheckAndInitializeRoyalty()
	-- Only initialize if player has royalty gamepass AND selected royalty
	if self.Flags.royalty_gamepass and (self.Flags.selected_royalty or self.Flags.royal_family) then
		-- Pick a random royal country
		local RoyalCountries = {
			{ id = "uk", name = "United Kingdom", emoji = "🇬🇧", palace = "Buckingham Palace", startingWealth = { min = 50000000, max = 500000000 } },
			{ id = "japan", name = "Japan", emoji = "🇯🇵", palace = "Imperial Palace", startingWealth = { min = 100000000, max = 800000000 } },
			{ id = "monaco", name = "Monaco", emoji = "🇲🇨", palace = "Prince's Palace", startingWealth = { min = 200000000, max = 1000000000 } },
			{ id = "saudi", name = "Saudi Arabia", emoji = "🇸🇦", palace = "Al-Yamamah Palace", startingWealth = { min = 500000000, max = 5000000000 } },
		}
		
		local country = RoyalCountries[math.random(#RoyalCountries)]
		local title = self.Gender == "male" and "Prince" or "Princess"
		
		return self:InitializeRoyalty(country, title)
	end
	
	return self
end

-- CRITICAL FIX #20: Apply god mode stat edit
function LifeState:ApplyGodModeEdit(statKey, newValue)
	if not self.GodModeState.enabled then
		return false, "God Mode not enabled"
	end
	
	local validStats = { Happiness = true, Health = true, Smarts = true, Looks = true }
	if not validStats[statKey] then
		return false, "Invalid stat"
	end
	
	newValue = math.clamp(newValue, 0, 100)
	
	if self.Stats[statKey] ~= nil then
		self.Stats[statKey] = newValue
	end
	if self[statKey] ~= nil then
		self[statKey] = newValue
	end
	
	self.GodModeState.editsThisLife = self.GodModeState.editsThisLife + 1
	self.GodModeState.lastEditAge = self.Age
	
	return true, string.format("%s set to %d", statKey, newValue)
end

return LifeState
