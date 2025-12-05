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
		Duration = 0,
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
		careerHistory = {},
		skills = {},
	}
	self.Career = {
		track = nil, -- current career track
		education = nil,
	}
	
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
	if self.Age == 5 and self.Education == "none" then
		self.EducationData.Status = "enrolled"
		self.EducationData.Institution = "Elementary School"
		self.Flags.in_school = true
	end
	
	-- Age 11: Middle school transition (just update institution)
	if self.Age == 11 and self.Education == "none" then
		self.EducationData.Institution = "Middle School"
	end
	
	-- Age 14: Start high school (still no diploma yet!)
	if self.Age == 14 and self.Education == "none" then
		self.EducationData.Institution = "High School"
		self.Flags.in_high_school = true
	end
	
	-- Age 18: Auto-graduate high school if player hasn't already via event
	-- This ensures EVERYONE gets high school education by 18
	if self.Age == 18 then
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
	end
	
	-- Jail time reduction
	if self.InJail and self.JailYearsLeft > 0 then
		self.JailYearsLeft = math.max(0, self.JailYearsLeft - 1)
		if self.JailYearsLeft <= 0 then
			self.InJail = false
			self.Flags.in_prison = nil
			self.Flags.incarcerated = nil
			
			-- CRITICAL FIX: Resume suspended education if player was enrolled before jail
			if self.EducationData and self.EducationData.Status == "suspended" then
				if self.EducationData.StatusBeforeJail == "enrolled" then
					self.EducationData.Status = "enrolled"
					self.EducationData.StatusBeforeJail = nil
					self.PendingFeed = "You've been released from prison! You can resume your education."
				else
					self.PendingFeed = "You've been released from prison!"
				end
			else
				self.PendingFeed = "You've been released from prison!"
			end
		end
	end
	
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
	-- Semi-retirees still earn from their part-time job
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	if self.Flags and self.Flags.semi_retired and self.CurrentJob and self.CurrentJob.salary then
		local partTimeSalary = self.CurrentJob.salary
		self.Money = (self.Money or 0) + partTimeSalary
		if not self.PendingFeed then
			self.PendingFeed = string.format("You earned $%s from your part-time work.", partTimeSalary)
		end
	end
	
	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- STAT MANIPULATION
-- ════════════════════════════════════════════════════════════════════════════

function LifeState:ModifyStat(statName, delta)
	if self.Stats[statName] ~= nil then
		self.Stats[statName] = math.clamp(self.Stats[statName] + delta, 0, 100)
		self[statName] = self.Stats[statName]
	end
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

function LifeState:AddRelationship(id, data)
	self.Relationships[id] = data
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
		
		-- Event History (needed for client to show recent events)
		EventHistory = {
			feed = self.EventHistory.feed or {},
		},
		
		-- Death
		CauseOfDeath = self.CauseOfDeath,
	}
end

return LifeState
