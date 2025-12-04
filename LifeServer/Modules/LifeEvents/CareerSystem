local CareerSystem = {}

CareerSystem.Catalog = {
	gig = {
		{
			id = "barista",
			name = "Coffee Barista",
			category = "service",
			requiredEducation = "none",
			baseSalary = 24000,
			performanceGain = { Happiness = 1, Smarts = 1 },
		},
		{
			id = "retail",
			name = "Retail Associate",
			category = "retail",
			requiredEducation = "none",
			baseSalary = 26000,
		},
	},
	professional = {
		{
			id = "software_engineer",
			name = "Junior Software Engineer",
			category = "tech",
			requiredEducation = "bachelors",
			baseSalary = 72000,
			performanceGain = { Smarts = 2 },
		},
		{
			id = "nurse",
			name = "Registered Nurse",
			category = "medical",
			requiredEducation = "bachelors",
			baseSalary = 68000,
		},
	},
	creative = {
		{
			id = "graphic_designer",
			name = "Graphic Designer",
			category = "creative",
			requiredEducation = "associate",
			baseSalary = 52000,
		},
		{
			id = "musician",
			name = "Touring Musician",
			category = "entertainment",
			requiredEducation = "none",
			baseSalary = 38000,
			variance = 30000,
		},
	},
}

local function meetsEducation(requirement, level)
	if not requirement or requirement == "none" then
		return true
	end

	local hierarchy = {
		none = 0,
		highschool = 1,
		associate = 2,
		bachelors = 3,
		masters = 4,
		doctorate = 5,
	}
	return (hierarchy[level or "none"] or 0) >= (hierarchy[requirement] or 0)
end

function CareerSystem.getJobsForState(state)
	local available = {}
	for _, track in pairs(CareerSystem.Catalog) do
		for _, job in ipairs(track) do
			if meetsEducation(job.requiredEducation, state.Education and state.Education.level) then
				table.insert(available, job)
			end
		end
	end
	return available
end

function CareerSystem.getJob(jobId)
	for _, track in pairs(CareerSystem.Catalog) do
		for _, job in ipairs(track) do
			if job.id == jobId then
				return job
			end
		end
	end
end

function CareerSystem.simulateWork(state)
	if not state.Career or not state.Career.jobId then
		return
	end

	state.Career.performance = math.clamp((state.Career.performance or 60) + Random.new():NextInteger(-2, 5), 0, 100)
	state.Career.promotionProgress = math.clamp((state.Career.promotionProgress or 0) + Random.new():NextInteger(3, 10), 0, 100)

	if state.Career.performance >= 90 and state.Career.promotionProgress >= 100 then
		state.Career.salary = math.floor(state.Career.salary * 1.15)
		state.Career.promotionProgress = 20
		state.Career.raiseCount = (state.Career.raiseCount or 0) + 1
		state:AddFeed(("You were promoted! Salary is now $%s."):format(state.Career.salary))
	end

	local salary = state.Career.salary or 0
	state:AddMoney(math.floor(salary / 12), "Monthly salary")
end

return CareerSystem
