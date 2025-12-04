-- CareerData.lua - Main Career Data Module
-- Combines all career parts into one comprehensive system
-- 100+ Careers with Specific Events for BitLife-style gameplay

local CareerData = {}

-- Import all career parts
local Part1 = require(script.Parent.CareerData_Part1)
local Part2 = require(script.Parent.CareerData_Part2)
local Part3 = require(script.Parent.CareerData_Part3)
local Part4 = require(script.Parent.CareerData_Part4)
local Part5 = require(script.Parent.CareerData_Part5)

--============================================================================
-- COMBINE ALL JOBS
--============================================================================
CareerData.Jobs = {}

-- Merge all job tables
for id, job in pairs(Part1.Jobs or {}) do
    CareerData.Jobs[id] = job
end
for id, job in pairs(Part2.Jobs or {}) do
    CareerData.Jobs[id] = job
end
for id, job in pairs(Part3.Jobs or {}) do
    CareerData.Jobs[id] = job
end
for id, job in pairs(Part4.Jobs or {}) do
    CareerData.Jobs[id] = job
end
for id, job in pairs(Part5.Jobs or {}) do
    CareerData.Jobs[id] = job
end

--============================================================================
-- CATEGORIES
--============================================================================
CareerData.Categories = Part1.Categories or {
    "Entry Level",
    "Service", 
    "Food Industry",
    "Retail",
    "Trades",
    "Office",
    "Technology",
    "Medical",
    "Legal",
    "Finance",
    "Creative",
    "Government",
    "Education",
    "Science",
    "Sports",
    "Entertainment",
    "Military",
    "Criminal",
    "Transportation",
    "Real Estate",
    "Agriculture",
    "Maritime",
    "Aviation",
    "Emergency Services",
    "Religious",
    "Hospitality",
    "Beauty",
    "Fitness",
    "Journalism",
    "Executive"
}

--============================================================================
-- SKILLS
--============================================================================
CareerData.Skills = Part1.Skills or {
    Technical = { name = "Technical", description = "Ability to work with tools, machines, and technology" },
    Creative = { name = "Creative", description = "Artistic ability and imagination" },
    Social = { name = "Social", description = "People skills and communication" },
    Physical = { name = "Physical", description = "Strength, endurance, and athleticism" },
    Analytical = { name = "Analytical", description = "Problem-solving and critical thinking" },
    Leadership = { name = "Leadership", description = "Ability to manage and inspire others" },
    Medical = { name = "Medical", description = "Healthcare knowledge and patient care" },
    Legal = { name = "Legal", description = "Law knowledge and argumentation" },
    Financial = { name = "Financial", description = "Money management and investing" },
    Culinary = { name = "Culinary", description = "Cooking and food preparation" },
    Athletic = { name = "Athletic", description = "Sports performance and training" },
    Artistic = { name = "Artistic", description = "Visual arts and design" },
    Musical = { name = "Musical", description = "Music performance and composition" },
    Writing = { name = "Writing", description = "Written communication and storytelling" },
    Teaching = { name = "Teaching", description = "Educating and mentoring others" },
    Mechanical = { name = "Mechanical", description = "Working with engines and machines" },
    Scientific = { name = "Scientific", description = "Research and experimentation" },
    Criminal = { name = "Criminal", description = "Illegal activities and street smarts" },
    Charisma = { name = "Charisma", description = "Charm and persuasion" },
    Stealth = { name = "Stealth", description = "Sneaking and avoiding detection" }
}

--============================================================================
-- CAREER PROGRESSION PATHS
--============================================================================
CareerData.ProgressionPaths = {
    -- Entry Level to Corporate
    {
        name = "Corporate Ladder",
        steps = {"Fast Food Worker", "Cashier", "Receptionist", "Data Entry Clerk", "Office Manager", "Executive"}
    },
    -- Tech Career
    {
        name = "Tech Career",
        steps = {"IT Support", "Junior Developer", "Software Developer", "Senior Developer", "Tech Lead", "CTO"}
    },
    -- Medical Career
    {
        name = "Medical Career",
        steps = {"Nurse", "Charge Nurse", "Nurse Practitioner", "Doctor", "Surgeon", "Chief of Surgery"}
    },
    -- Legal Career
    {
        name = "Legal Career",
        steps = {"Paralegal", "Lawyer", "Senior Associate", "Partner", "Judge"}
    },
    -- Criminal Empire
    {
        name = "Criminal Empire",
        steps = {"Drug Dealer", "Drug Kingpin", "Crime Boss"}
    },
    -- Creative Path
    {
        name = "Creative Path",
        steps = {"Graphic Designer", "Senior Designer", "Art Director", "Creative Director"}
    },
    -- Entertainment
    {
        name = "Entertainment",
        steps = {"Actor", "Working Actor", "Star", "A-List"}
    },
    -- Military
    {
        name = "Military",
        steps = {"Enlisted Soldier", "Sergeant", "Officer", "General"}
    },
    -- Education
    {
        name = "Education",
        steps = {"Teacher", "Department Head", "Principal", "Superintendent"}
    },
    -- Trades
    {
        name = "Trades",
        steps = {"Electrician Apprentice", "Journeyman Electrician", "Master Electrician", "Contractor"}
    }
}

--============================================================================
-- HELPER FUNCTIONS
--============================================================================

-- Get all jobs in a category
function CareerData.GetJobsByCategory(category)
    local jobs = {}
    for _, job in pairs(CareerData.Jobs) do
        if job.category == category then
            table.insert(jobs, job)
        end
    end
    return jobs
end

-- Get jobs player qualifies for
function CareerData.GetAvailableJobs(playerState)
    local available = {}
    for _, job in pairs(CareerData.Jobs) do
        if CareerData.PlayerQualifies(playerState, job) then
            table.insert(available, job)
        end
    end
    return available
end

-- Check if player qualifies for a job
function CareerData.PlayerQualifies(playerState, job)
    -- Age check
    if playerState.age < (job.minAge or 0) then
        return false
    end
    if job.maxAge and playerState.age > job.maxAge then
        return false
    end
    
    -- Education check
    if job.requirement then
        local educationLevel = CareerData.GetEducationLevel(playerState.education)
        local requiredLevel = CareerData.GetEducationLevel(job.requirement)
        if educationLevel < requiredLevel then
            -- Check alternate requirement
            if not job.alternateRequirement then
                return false
            end
        end
    end
    
    -- Skills check
    if job.requiredSkills then
        for skill, required in pairs(job.requiredSkills) do
            local playerSkill = playerState.skills and playerState.skills[skill] or 0
            if playerSkill < required then
                return false
            end
        end
    end
    
    -- Criminal record check (for legal jobs)
    if not job.illegal and playerState.criminalRecord and playerState.criminalRecord > 0 then
        if job.category == "Government" or job.category == "Legal" or job.category == "Medical" then
            -- Background check jobs may reject
            return false
        end
    end
    
    return true
end

-- Get education level as number for comparison
function CareerData.GetEducationLevel(education)
    local levels = {
        ["None"] = 0,
        ["High School"] = 1,
        ["GED"] = 1,
        ["Community College"] = 2,
        ["Associate's"] = 2,
        ["Bachelor's Degree"] = 3,
        ["Bachelor's"] = 3,
        ["Master's Degree"] = 4,
        ["Master's"] = 4,
        ["Law Degree"] = 5,
        ["Medical Degree"] = 5,
        ["PhD"] = 5,
        ["Doctorate"] = 5
    }
    return levels[education] or 0
end

-- Get random career event for a job (weighted by probability and conditions)
function CareerData.GetCareerEvent(job, playerState, yearsInJob)
    if not job.careerEvents then return nil end
    
    local eligibleEvents = {}
    
    for _, event in ipairs(job.careerEvents) do
        local eligible = true
        
        -- Check minimum years in job
        if event.minYearsInJob and yearsInJob < event.minYearsInJob then
            eligible = false
        end
        
        -- Check performance requirement
        if event.requiresPerformance and playerState.jobPerformance then
            if playerState.jobPerformance < event.requiresPerformance then
                eligible = false
            end
        end
        
        -- Random probability check
        if eligible then
            if math.random() < event.probability then
                table.insert(eligibleEvents, event)
            end
        end
    end
    
    -- Return random eligible event or nil
    if #eligibleEvents > 0 then
        return eligibleEvents[math.random(#eligibleEvents)]
    end
    
    return nil
end

-- Get random work day flavor text
function CareerData.GetWorkDayEvent(job)
    if not job.workDayEvents or #job.workDayEvents == 0 then
        return "Another day at work."
    end
    return job.workDayEvents[math.random(#job.workDayEvents)]
end

-- Calculate salary with modifiers
function CareerData.CalculateSalary(job, playerState, yearsInJob)
    local baseSalary = job.baseSalary or 30000
    
    -- Experience bonus (1% per year, capped at 30%)
    local experienceBonus = math.min(yearsInJob * 0.01, 0.30)
    
    -- Performance bonus
    local performanceBonus = 0
    if playerState.jobPerformance then
        performanceBonus = (playerState.jobPerformance - 50) * 0.005 -- -25% to +25%
    end
    
    -- Skill bonus
    local skillBonus = 0
    if job.skillGains and playerState.skills then
        for skill, _ in pairs(job.skillGains) do
            local playerSkill = playerState.skills[skill] or 0
            skillBonus = skillBonus + (playerSkill * 0.001) -- 0.1% per skill point
        end
    end
    
    local totalMultiplier = 1 + experienceBonus + performanceBonus + skillBonus
    
    return math.floor(baseSalary * totalMultiplier)
end

-- Process event choice outcome
function CareerData.ProcessEventOutcome(event, choiceIndex, playerState)
    local choice = event.choices[choiceIndex]
    if not choice then return nil end
    
    -- Roll for outcome based on probabilities
    local roll = math.random()
    local cumulative = 0
    
    for _, outcome in ipairs(choice.outcomes) do
        cumulative = cumulative + outcome.probability
        if roll <= cumulative then
            return outcome
        end
    end
    
    -- Fallback to last outcome
    return choice.outcomes[#choice.outcomes]
end

-- Get promotion job
function CareerData.GetPromotionJob(currentJob)
    local promotionTitle = currentJob.promotionPath
    if not promotionTitle then return nil end
    
    -- Look for job with matching title
    for _, job in pairs(CareerData.Jobs) do
        if job.title == promotionTitle then
            return job
        end
    end
    
    return nil
end

-- Count total jobs
function CareerData.GetJobCount()
    local count = 0
    for _ in pairs(CareerData.Jobs) do
        count = count + 1
    end
    return count
end

-- Get all illegal jobs
function CareerData.GetIllegalJobs()
    local illegal = {}
    for _, job in pairs(CareerData.Jobs) do
        if job.illegal then
            table.insert(illegal, job)
        end
    end
    return illegal
end

-- Get entry level jobs (no requirements)
function CareerData.GetEntryLevelJobs()
    local entry = {}
    for _, job in pairs(CareerData.Jobs) do
        if not job.requirement and (job.minAge or 0) <= 18 then
            table.insert(entry, job)
        end
    end
    return entry
end

return CareerData
