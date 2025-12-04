local HttpService = game:GetService("HttpService")

local LifeState = {}
LifeState.__index = LifeState

local RNG = Random.new()

local TRAIT_POOL = {
	{ id = "ambitious", label = "Ambitious", effects = { Smarts = 2, Happiness = 1 } },
	{ id = "charming", label = "Charming", effects = { Happiness = 3, Looks = 2 } },
	{ id = "reckless", label = "Reckless", effects = { Happiness = 2, Health = -2 } },
	{ id = "introvert", label = "Introvert", effects = { Happiness = -1, Smarts = 2 } },
	{ id = "empath", label = "Empath", effects = { Happiness = 2 } },
	{ id = "workhorse", label = "Workhorse", effects = { Smarts = 1, Health = -1 } },
	{ id = "lucky", label = "Lucky", effects = { Happiness = 2 } },
	{ id = "athletic", label = "Athletic", effects = { Health = 3 } },
	{ id = "artsy", label = "Artsy", effects = { Happiness = 2 } },
	{ id = "street_smart", label = "Street Smart", effects = { Smarts = 1, Looks = 1 } },
}

local function shallowCopy(tbl)
	if type(tbl) ~= "table" then
		return tbl
	end
	local copy = {}
	for key, value in pairs(tbl) do
		copy[key] = value
	end
	return copy
end

local function clampStat(value)
	return math.clamp(math.floor(value + 0.5), 0, 100)
end

local function rollTraits(count)
	count = count or 3
	local pulled = {}
	local pool = table.clone(TRAIT_POOL)
	for _ = 1, math.min(count, #pool) do
		local index = RNG:NextInteger(1, #pool)
		table.insert(pulled, pool[index])
		table.remove(pool, index)
	end
	return pulled
end

local function createStartingRelationships()
	return {
		mother = { id = "mother", name = "Mom", type = "family", role = "Mother", relationship = 85, age = RNG:NextInteger(35, 55), alive = true },
		father = { id = "father", name = "Dad", type = "family", role = "Father", relationship = 80, age = RNG:NextInteger(37, 58), alive = true },
	}
end

function LifeState.new(player)
	local self = setmetatable({}, LifeState)

	self.UserId = player.UserId
	self.DisplayName = player.DisplayName
	self.Name = nil
	self.Gender = nil

	self.Age = 0
	self.Year = 2025
	self.Money = 0
	self.Experience = 0

	self.Stats = {
		Happiness = RNG:NextInteger(55, 75),
		Health = RNG:NextInteger(60, 85),
		Smarts = RNG:NextInteger(40, 80),
		Looks = RNG:NextInteger(35, 80),
	}

	self.Personality = rollTraits()
	self.Flags = {}
	self.Relationships = createStartingRelationships()

	self.PendingFeed = "A new life begins..."
	self.lastFeed = self.PendingFeed
	self.awaitingDecision = false

	self.InJail = false
	self.JailYearsLeft = 0

	self.Career = {
		track = nil,
		jobId = nil,
		jobTitle = nil,
		employer = nil,
		salary = 0,
		performance = 60,
		promotionProgress = 0,
		yearsAtJob = 0,
		raiseCount = 0,
	}
	self.CurrentJob = nil
	self.CareerInfo = {
		performance = 60,
		promotionProgress = 0,
		yearsAtJob = 0,
		raises = 0,
		careerHistory = {},
		skills = {},
	}

	self.Education = "none"
	self.EducationData = {
		Status = "none",
		Level = "none",
		Progress = 0,
		Duration = 0,
		Institution = nil,
		GPA = math.floor(self.Stats.Smarts / 20 * 100) / 100,
		Debt = 0,
	}

	self.Assets = {
		Properties = {},
		Vehicles = {},
		Items = {},
		Crypto = {},
	}

	self.Story = {
		Paths = {},
		ActivePath = nil,
	}
	self.Paths = { active = nil }
	self.ActivePath = nil

	self.EventHistory = {
		seen = {},
		lastOccurrence = {},
		milestones = {},
		feed = {},
		choices = {},
	}

	for _, trait in ipairs(self.Personality) do
		if trait.effects then
			for stat, delta in pairs(trait.effects) do
				if self.Stats[stat] then
					self.Stats[stat] = clampStat(self.Stats[stat] + delta)
				end
			end
		end
	end

	self.Happiness = self.Stats.Happiness
	self.Health = self.Stats.Health
	self.Smarts = self.Stats.Smarts
	self.Looks = self.Stats.Looks

	return self
end

function LifeState.fromSerialized(player, data)
	local self = LifeState.new(player)
	for key, value in pairs(data) do
		if key ~= "Stats" and key ~= "EventHistory" and key ~= "Assets" then
			self[key] = value
		end
	end

	if data.Stats then
		self.Stats = table.clone(data.Stats)
	end

	if data.Assets then
		self.Assets = table.clone(data.Assets)
	end

	if data.EventHistory then
		self.EventHistory = table.clone(data.EventHistory)
	end

	self.Happiness = self.Stats.Happiness or self.Happiness
	self.Health = self.Stats.Health or self.Health
	self.Smarts = self.Stats.Smarts or self.Smarts
	self.Looks = self.Stats.Looks or self.Looks

	return self
end

function LifeState:Serialize()
	local serialized = {
		UserId = self.UserId,
		DisplayName = self.DisplayName,
		Name = self.Name,
		Gender = self.Gender,
		Age = self.Age,
		Year = self.Year,
		Money = self.Money,
		Stats = table.clone(self.Stats),
		Flags = table.clone(self.Flags),
		Relationships = table.clone(self.Relationships),
		Career = table.clone(self.Career),
		CurrentJob = self.CurrentJob and table.clone(self.CurrentJob) or nil,
		CareerInfo = table.clone(self.CareerInfo),
		Education = self.Education,
		EducationData = table.clone(self.EducationData),
		Assets = table.clone(self.Assets),
		Story = table.clone(self.Story),
		Paths = table.clone(self.Paths),
		EventHistory = {
			seen = table.clone(self.EventHistory.seen),
			lastOccurrence = table.clone(self.EventHistory.lastOccurrence),
			milestones = table.clone(self.EventHistory.milestones),
			feed = table.clone(self.EventHistory.feed),
		},
		Personality = table.clone(self.Personality),
		PendingFeed = self.PendingFeed,
		lastFeed = self.lastFeed,
		InJail = self.InJail,
		JailYearsLeft = self.JailYearsLeft,
		ActivePath = self.ActivePath,
		awaitingDecision = self.awaitingDecision,
	}

	serialized.Happiness = serialized.Stats.Happiness
	serialized.Health = serialized.Stats.Health
	serialized.Smarts = serialized.Stats.Smarts
	serialized.Looks = serialized.Stats.Looks

	return serialized
end

function LifeState:AdvanceAge()
	self.Age = self.Age + 1
	self.Year = self.Year + 1
	self.Career.promotionProgress = clampStat(self.Career.promotionProgress + RNG:NextInteger(1, 3))
	self.Career.yearsAtJob = (self.Career.yearsAtJob or 0) + 1
	self:RecordFlag("age_" .. tostring(self.Age))
	self:AddFeed(string.format("Turned %d", self.Age))
end

function LifeState:AddFeed(text)
	table.insert(self.EventHistory.feed, 1, { year = self.Year, age = self.Age, text = text })
	if #self.EventHistory.feed > 50 then
		table.remove(self.EventHistory.feed)
	end
	self.PendingFeed = text
	self.lastFeed = text
end

function LifeState:AddMoney(amount, reason)
	self.Money = math.floor(self.Money + amount)
	if reason then
		self:AddFeed(string.format("%s (%s)", amount >= 0 and ("Gained $" .. tostring(amount)) or ("Lost $" .. tostring(math.abs(amount))), reason))
	end
end

function LifeState:HasMoney(amount)
	return self.Money >= amount
end

function LifeState:ModifyStat(stat, delta)
	if self.Stats[stat] then
		self.Stats[stat] = clampStat(self.Stats[stat] + delta)
		self[stat] = self.Stats[stat]
	end
end

function LifeState:ApplyEffects(effects)
	for key, delta in pairs(effects) do
		if key == "Money" or key == "Cash" then
			self:AddMoney(delta)
		else
			self:ModifyStat(key, delta)
		end
	end
end

function LifeState:SetFlag(flag, value)
	self.Flags[flag] = value ~= false
end

function LifeState:ClearFlag(flag)
	self.Flags[flag] = nil
end

function LifeState:HasFlag(flag)
	return self.Flags[flag] == true
end

function LifeState:RecordFlag(flag)
	self.EventHistory.milestones[flag] = true
	self:SetFlag(flag, true)
end

function LifeState:AddRelationship(data)
	local relId = data.id or HttpService:GenerateGUID(false)
	self.Relationships[relId] = {
		id = relId,
		name = data.name or "Person",
		type = data.type or "friend",
		role = data.role or "Friend",
		relationship = data.relationship or 50,
		age = data.age or self.Age,
		status = data.status or "active",
	}
	return self.Relationships[relId]
end

function LifeState:GetRelationship(id)
	return self.Relationships[id]
end

function LifeState:ModifyRelationship(id, delta)
	local rel = self.Relationships[id]
	if rel then
		rel.relationship = math.clamp((rel.relationship or 50) + delta, -100, 100)
	end
end

function LifeState:RemoveRelationship(id)
	self.Relationships[id] = nil
end

function LifeState:GetRelationshipsByType(relType)
	local list = {}
	for _, rel in pairs(self.Relationships) do
		if rel.type == relType then
			table.insert(list, rel)
		end
	end
	return list
end

function LifeState:SetCareer(jobData)
	if not jobData then
		self.Career = {
			track = nil,
			jobId = nil,
			jobTitle = nil,
			employer = nil,
			salary = 0,
			performance = 60,
			promotionProgress = 0,
			yearsAtJob = 0,
			raiseCount = 0,
		}
		self.CurrentJob = nil
		self:ClearFlag("employed")
		return
	end

	self.Career.jobId = jobData.id
	self.Career.jobTitle = jobData.name
	self.Career.employer = jobData.company
	self.Career.salary = jobData.salary or 0
	self.Career.track = jobData.category
	self.Career.performance = 60
	self.Career.promotionProgress = 0
	self.Career.yearsAtJob = 0
	self.Career.raiseCount = 0
	self.CurrentJob = {
		id = jobData.id,
		name = jobData.name,
		company = jobData.company,
		salary = jobData.salary or 0,
		category = jobData.category,
	}
	self:SetFlag("employed", true)
	self:AddFeed(("Started working as %s at %s"):format(jobData.name, jobData.company))
end

function LifeState:RecordEvent(eventId, data)
	self.EventHistory.seen[eventId] = true
	self.EventHistory.lastOccurrence[eventId] = self.Year
	if data then
		self.EventHistory.choices[eventId] = data
	end
end

function LifeState:HasSeenEvent(eventId)
	return self.EventHistory.seen[eventId] == true
end

function LifeState:CanAfford(amount)
	return self.Money >= amount
end

function LifeState:EnrollEducation(program)
	self.EducationData = self.EducationData or {}
	self.EducationData.Status = "enrolled"
	self.EducationData.Level = program.id or program.level or program.name or "program"
	self.EducationData.Duration = program.duration or program.Duration or 4
	self.EducationData.Progress = 0
	self.EducationData.Institution = program.name or "Program"
	self.EducationData.Debt = (self.EducationData.Debt or 0) + (program.cost or 0)
	self.EducationData.GPA = math.max(self.EducationData.GPA or 2.5, 3.0)
	self:SetFlag("student", true)
end

function LifeState:Graduate(level, title)
	self.Education = level
	self.EducationData = self.EducationData or {}
	self.EducationData.Status = "completed"
	self.EducationData.Progress = 100
	self.EducationData.Level = level
	self.EducationData.Institution = title or self.EducationData.Institution
	self:SetFlag(level .. "_graduate", true)
	self:RecordFlag(level .. "_graduate")
	self:ClearFlag("student")
	self:AddFeed(("Graduated with %s"):format(title or level))
end

function LifeState:GetNetWorth()
	local total = self.Money
	for _, list in pairs(self.Assets) do
		for _, asset in pairs(list) do
			total += asset.value or 0
		end
	end
	return total
end

return LifeState
