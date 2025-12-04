-- PlayerStateManager.lua - Central State Management System
-- Handles all player state, saving, loading, and synchronization

local PlayerStateManager = {}

-- Dependencies (will be required when integrated)
local TraitData = nil -- require(script.Parent.Parent.Data.TraitData)

--============================================================================
-- DEFAULT STATE TEMPLATE
--============================================================================
PlayerStateManager.DefaultState = {
    -- Basic Info
    playerId = nil,
    name = "",
    gender = "male",
    age = 0,
    birthday = {month = 1, day = 1},
    country = "USA",
    city = "",
    
    -- Core Stats (0-100 scale)
    health = 100,
    happiness = 50,
    smarts = 50,
    looks = 50,
    
    -- Secondary Stats
    karma = 50,
    fame = 0,
    stress = 0,
    willpower = 50,
    
    -- Money & Assets
    money = 0,
    bankBalance = 0,
    debt = 0,
    properties = {},
    vehicles = {},
    items = {},
    
    -- Skills (0-100 scale)
    skills = {
        Technical = 0,
        Creative = 0,
        Social = 0,
        Physical = 0,
        Analytical = 0,
        Leadership = 0,
        Medical = 0,
        Legal = 0,
        Financial = 0,
        Culinary = 0,
        Athletic = 0,
        Artistic = 0,
        Musical = 0,
        Writing = 0,
        Teaching = 0,
        Mechanical = 0,
        Scientific = 0,
        Criminal = 0,
        Charisma = 0,
        Stealth = 0
    },
    
    -- Traits
    traits = {},
    
    -- Education
    education = {
        level = "None",
        currentEnrollment = nil,
        progress = 0,
        gpa = 0,
        debt = 0,
        history = {},
        graduationYear = nil
    },
    
    -- Career
    career = {
        currentJob = nil,
        yearsInJob = 0,
        performance = 50,
        salary = 0,
        promotionProgress = 0,
        history = {},
        totalYearsWorked = 0,
        lastRaise = nil,
        isUnemployed = true
    },
    
    -- Relationships
    relationships = {
        parents = {},
        siblings = {},
        partner = nil,
        exes = {},
        children = {},
        friends = {},
        enemies = {},
        coworkers = {}
    },
    
    -- Living Situation
    living = {
        type = "parents", -- "parents", "own", "roommates", "homeless", "prison"
        address = nil,
        roommates = {}
    },
    
    -- Legal Status
    legal = {
        criminalRecord = {},
        currentCases = {},
        inPrison = false,
        prisonSentence = 0,
        prisonYearsServed = 0,
        onProbation = false,
        probationYears = 0
    },
    
    -- Health Conditions
    healthConditions = {},
    addictions = {},
    
    -- Life Events History
    eventHistory = {},
    achievements = {},
    
    -- Story Paths
    storyPaths = {
        active = nil,
        completed = {},
        progress = {}
    },
    
    -- Stats Tracking
    stats = {
        totalMoneyEarned = 0,
        totalMoneySpent = 0,
        crimesCommitted = 0,
        peopleKilled = 0,
        timeInPrison = 0,
        relationshipsHad = 0,
        childrenBorn = 0,
        jobsHeld = 0,
        degreesEarned = 0
    },
    
    -- Game Meta
    meta = {
        createdAt = 0,
        lastPlayed = 0,
        totalPlayTime = 0,
        generation = 1,
        previousLives = {}
    }
}

--============================================================================
-- STATE MANAGEMENT FUNCTIONS
--============================================================================

-- Create new player state
function PlayerStateManager.CreateNewLife(playerId, options)
    options = options or {}
    
    local state = PlayerStateManager.DeepCopy(PlayerStateManager.DefaultState)
    state.playerId = playerId
    state.meta.createdAt = os.time()
    state.meta.lastPlayed = os.time()
    
    -- Set initial values from options
    state.name = options.name or "Baby"
    state.gender = options.gender or (math.random() > 0.5 and "male" or "female")
    state.country = options.country or "USA"
    state.city = options.city or "New York"
    
    -- Random birthday
    state.birthday = {
        month = math.random(1, 12),
        day = math.random(1, 28)
    }
    
    -- Randomize starting stats slightly
    state.smarts = 40 + math.random(0, 20)
    state.looks = 40 + math.random(0, 20)
    state.health = 90 + math.random(0, 10)
    state.happiness = 70 + math.random(0, 30)
    
    -- Generate starting traits (2-3 traits)
    if TraitData then
        local numTraits = math.random(2, 3)
        state.traits = TraitData.GetStartingTraits(numTraits)
    end
    
    -- Generate family
    state.relationships.parents = PlayerStateManager.GenerateParents(state)
    
    -- 50% chance of siblings
    if math.random() > 0.5 then
        state.relationships.siblings = PlayerStateManager.GenerateSiblings(state, math.random(1, 3))
    end
    
    return state
end

-- Generate parents
function PlayerStateManager.GenerateParents(childState)
    local parents = {}
    
    -- Father
    local father = {
        id = "father_" .. tostring(os.time()),
        relationship = "Father",
        name = PlayerStateManager.GenerateName("male"),
        gender = "male",
        age = 25 + math.random(0, 15),
        alive = true,
        relationshipQuality = 70 + math.random(-20, 20),
        occupation = PlayerStateManager.GetRandomOccupation(),
        health = 70 + math.random(0, 30),
        traits = {}
    }
    
    -- Mother
    local mother = {
        id = "mother_" .. tostring(os.time()),
        relationship = "Mother",
        name = PlayerStateManager.GenerateName("female"),
        gender = "female",
        age = 22 + math.random(0, 12),
        alive = true,
        relationshipQuality = 75 + math.random(-15, 25),
        occupation = PlayerStateManager.GetRandomOccupation(),
        health = 75 + math.random(0, 25),
        traits = {}
    }
    
    table.insert(parents, father)
    table.insert(parents, mother)
    
    return parents
end

-- Generate siblings
function PlayerStateManager.GenerateSiblings(playerState, count)
    local siblings = {}
    
    for i = 1, count do
        local sibling = {
            id = "sibling_" .. i .. "_" .. tostring(os.time()),
            relationship = "Sibling",
            name = PlayerStateManager.GenerateName(math.random() > 0.5 and "male" or "female"),
            gender = math.random() > 0.5 and "male" or "female",
            age = math.max(0, playerState.age + math.random(-5, 5)),
            alive = true,
            relationshipQuality = 60 + math.random(-20, 30),
            traits = {}
        }
        table.insert(siblings, sibling)
    end
    
    return siblings
end

-- Generate a random name
function PlayerStateManager.GenerateName(gender)
    local maleNames = {
        "James", "John", "Robert", "Michael", "David", "William", "Richard", "Joseph",
        "Thomas", "Christopher", "Daniel", "Matthew", "Anthony", "Mark", "Steven",
        "Andrew", "Joshua", "Kevin", "Brian", "Ryan", "Jason", "Justin", "Brandon",
        "Tyler", "Jacob", "Noah", "Ethan", "Liam", "Mason", "Lucas", "Alexander"
    }
    
    local femaleNames = {
        "Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Susan",
        "Jessica", "Sarah", "Karen", "Lisa", "Nancy", "Betty", "Margaret", "Sandra",
        "Ashley", "Emily", "Megan", "Nicole", "Michelle", "Amanda", "Stephanie",
        "Olivia", "Emma", "Sophia", "Ava", "Isabella", "Mia", "Charlotte", "Amelia"
    }
    
    if gender == "male" then
        return maleNames[math.random(#maleNames)]
    else
        return femaleNames[math.random(#femaleNames)]
    end
end

-- Generate a random occupation for NPCs
function PlayerStateManager.GetRandomOccupation()
    local occupations = {
        "Teacher", "Engineer", "Nurse", "Doctor", "Lawyer", "Accountant",
        "Manager", "Sales Rep", "Driver", "Chef", "Police Officer", "Firefighter",
        "Writer", "Artist", "Musician", "Construction Worker", "Electrician",
        "Mechanic", "Store Clerk", "Bank Teller", "Programmer", "Architect",
        "Dentist", "Pharmacist", "Real Estate Agent", "Insurance Agent",
        "Homemaker", "Unemployed", "Retired"
    }
    return occupations[math.random(#occupations)]
end

--============================================================================
-- STATE MODIFICATION FUNCTIONS
--============================================================================

-- Modify a stat with bounds checking
function PlayerStateManager.ModifyStat(state, stat, amount, min, max)
    min = min or 0
    max = max or 100
    
    local current = state[stat] or 0
    local newValue = math.max(min, math.min(max, current + amount))
    state[stat] = newValue
    
    return newValue - current -- Return actual change
end

-- Modify health
function PlayerStateManager.ModifyHealth(state, amount)
    local change = PlayerStateManager.ModifyStat(state, "health", amount)
    
    -- Check for death
    if state.health <= 0 then
        state.alive = false
        state.causeOfDeath = "health"
    end
    
    return change
end

-- Modify money
function PlayerStateManager.ModifyMoney(state, amount)
    state.money = (state.money or 0) + amount
    
    if amount > 0 then
        state.stats.totalMoneyEarned = (state.stats.totalMoneyEarned or 0) + amount
    else
        state.stats.totalMoneySpent = (state.stats.totalMoneySpent or 0) + math.abs(amount)
    end
    
    -- Can go negative (debt)
    return amount
end

-- Modify skill
function PlayerStateManager.ModifySkill(state, skillName, amount)
    if not state.skills then state.skills = {} end
    
    local current = state.skills[skillName] or 0
    local newValue = math.max(0, math.min(100, current + amount))
    state.skills[skillName] = newValue
    
    return newValue - current
end

-- Add relationship
function PlayerStateManager.AddRelationship(state, category, person)
    if not state.relationships[category] then
        state.relationships[category] = {}
    end
    
    table.insert(state.relationships[category], person)
    state.stats.relationshipsHad = (state.stats.relationshipsHad or 0) + 1
end

-- Modify relationship quality
function PlayerStateManager.ModifyRelationship(state, personId, amount)
    for category, people in pairs(state.relationships) do
        for _, person in ipairs(people) do
            if person.id == personId then
                person.relationshipQuality = math.max(0, math.min(100, 
                    (person.relationshipQuality or 50) + amount))
                return true
            end
        end
    end
    return false
end

-- Add trait
function PlayerStateManager.AddTrait(state, traitId)
    if not state.traits then state.traits = {} end
    
    -- Check if already has trait
    for _, existing in ipairs(state.traits) do
        if existing == traitId then
            return false
        end
    end
    
    -- Check for conflicts with TraitData
    if TraitData then
        for _, existing in ipairs(state.traits) do
            if TraitData.TraitsConflict(traitId, existing) then
                return false
            end
        end
    end
    
    table.insert(state.traits, traitId)
    return true
end

-- Remove trait
function PlayerStateManager.RemoveTrait(state, traitId)
    if not state.traits then return false end
    
    for i, trait in ipairs(state.traits) do
        if trait == traitId then
            table.remove(state.traits, i)
            return true
        end
    end
    return false
end

--============================================================================
-- AGE UP SYSTEM
--============================================================================

-- Process aging
function PlayerStateManager.AgeUp(state)
    state.age = state.age + 1
    
    -- Age family members too
    for category, people in pairs(state.relationships) do
        for _, person in ipairs(people) do
            if person.alive then
                person.age = (person.age or 0) + 1
                
                -- Check for NPC death based on age
                local deathChance = PlayerStateManager.CalculateNPCDeathChance(person)
                if math.random() < deathChance then
                    person.alive = false
                    person.causeOfDeath = "natural"
                end
            end
        end
    end
    
    -- Decay relationships slightly
    PlayerStateManager.DecayRelationships(state)
    
    -- Update career years
    if state.career.currentJob then
        state.career.yearsInJob = state.career.yearsInJob + 1
        state.career.totalYearsWorked = state.career.totalYearsWorked + 1
    end
    
    -- Education progress
    if state.education.currentEnrollment then
        state.education.progress = state.education.progress + 1
    end
    
    -- Prison time
    if state.legal.inPrison then
        state.legal.prisonYearsServed = state.legal.prisonYearsServed + 1
        if state.legal.prisonYearsServed >= state.legal.prisonSentence then
            PlayerStateManager.ReleaseFromPrison(state)
        end
    end
    
    -- Natural stat changes with age
    PlayerStateManager.ApplyAgingEffects(state)
    
    -- Record age in history
    state.eventHistory["aged_" .. state.age] = true
    
    return state
end

-- Calculate NPC death chance based on age
function PlayerStateManager.CalculateNPCDeathChance(npc)
    local age = npc.age or 0
    local health = npc.health or 70
    
    -- Base death rate increases exponentially with age
    local baseRate = 0
    if age < 50 then
        baseRate = 0.001
    elseif age < 60 then
        baseRate = 0.005
    elseif age < 70 then
        baseRate = 0.015
    elseif age < 80 then
        baseRate = 0.04
    elseif age < 90 then
        baseRate = 0.10
    else
        baseRate = 0.25
    end
    
    -- Health modifier
    local healthModifier = (100 - health) / 100
    
    return baseRate * (1 + healthModifier)
end

-- Apply aging effects to stats
function PlayerStateManager.ApplyAgingEffects(state)
    local age = state.age
    
    -- Health decline with age
    if age > 50 then
        local decline = math.floor((age - 50) / 10)
        if math.random() < 0.3 then
            PlayerStateManager.ModifyHealth(state, -decline)
        end
    end
    
    -- Looks decline with age
    if age > 40 then
        local decline = math.floor((age - 40) / 15)
        if math.random() < 0.2 then
            PlayerStateManager.ModifyStat(state, "looks", -decline)
        end
    end
    
    -- Smarts increase in youth, stable in adulthood
    if age < 25 and math.random() < 0.1 then
        PlayerStateManager.ModifyStat(state, "smarts", 1)
    end
end

-- Decay relationships over time
function PlayerStateManager.DecayRelationships(state)
    for category, people in pairs(state.relationships) do
        for _, person in ipairs(people) do
            if person.alive and category ~= "parents" then
                -- Small random decay
                if math.random() < 0.1 then
                    person.relationshipQuality = math.max(0, 
                        (person.relationshipQuality or 50) - math.random(1, 3))
                end
            end
        end
    end
end

--============================================================================
-- PRISON SYSTEM
--============================================================================

-- Send to prison
function PlayerStateManager.SendToPrison(state, years, crime)
    state.legal.inPrison = true
    state.legal.prisonSentence = years
    state.legal.prisonYearsServed = 0
    state.living.type = "prison"
    
    -- Record crime
    table.insert(state.legal.criminalRecord, {
        crime = crime,
        year = state.age,
        sentence = years
    })
    
    -- Lose job if employed
    if state.career.currentJob then
        state.career.history = state.career.history or {}
        table.insert(state.career.history, {
            job = state.career.currentJob,
            endReason = "incarcerated"
        })
        state.career.currentJob = nil
        state.career.isUnemployed = true
    end
    
    state.stats.crimesCommitted = (state.stats.crimesCommitted or 0) + 1
end

-- Release from prison
function PlayerStateManager.ReleaseFromPrison(state)
    state.legal.inPrison = false
    state.legal.prisonSentence = 0
    state.legal.prisonYearsServed = 0
    state.living.type = "homeless" -- Need to find housing
    
    state.stats.timeInPrison = (state.stats.timeInPrison or 0) + state.legal.prisonYearsServed
end

--============================================================================
-- UTILITY FUNCTIONS
--============================================================================

-- Deep copy a table
function PlayerStateManager.DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for key, value in next, original, nil do
            copy[PlayerStateManager.DeepCopy(key)] = PlayerStateManager.DeepCopy(value)
        end
        setmetatable(copy, PlayerStateManager.DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- Validate state integrity
function PlayerStateManager.ValidateState(state)
    -- Ensure all required fields exist
    if not state.playerId then return false, "Missing playerId" end
    if not state.name then return false, "Missing name" end
    if type(state.age) ~= "number" then return false, "Invalid age" end
    if type(state.health) ~= "number" then return false, "Invalid health" end
    
    -- Ensure stats are in valid range
    local stats = {"health", "happiness", "smarts", "looks", "karma", "stress"}
    for _, stat in ipairs(stats) do
        if state[stat] then
            state[stat] = math.max(0, math.min(100, state[stat]))
        end
    end
    
    return true
end

-- Serialize state for saving
function PlayerStateManager.Serialize(state)
    -- Convert to JSON-safe format
    return state -- In Roblox, tables can be directly stored in DataStore
end

-- Deserialize state from storage
function PlayerStateManager.Deserialize(data)
    -- Validate and return
    local valid, err = PlayerStateManager.ValidateState(data)
    if not valid then
        warn("Invalid state data: " .. tostring(err))
        return nil
    end
    return data
end

-- Get state summary for display
function PlayerStateManager.GetStateSummary(state)
    return {
        name = state.name,
        age = state.age,
        gender = state.gender,
        money = state.money,
        health = state.health,
        happiness = state.happiness,
        smarts = state.smarts,
        looks = state.looks,
        job = state.career.currentJob,
        education = state.education.level,
        isInPrison = state.legal.inPrison
    }
end

-- Calculate net worth
function PlayerStateManager.CalculateNetWorth(state)
    local worth = state.money or 0
    worth = worth + (state.bankBalance or 0)
    
    -- Add property values
    for _, prop in ipairs(state.properties or {}) do
        worth = worth + (prop.value or 0)
    end
    
    -- Add vehicle values
    for _, vehicle in ipairs(state.vehicles or {}) do
        worth = worth + (vehicle.value or 0)
    end
    
    -- Subtract debt
    worth = worth - (state.debt or 0)
    worth = worth - (state.education.debt or 0)
    
    return worth
end

return PlayerStateManager
