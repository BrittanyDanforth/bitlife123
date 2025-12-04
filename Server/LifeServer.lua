-- LifeServer.lua - Main BitLife Backend Server
-- Central hub for all game logic, connecting to frontend remotes

local LifeServer = {}

--============================================================================
-- SERVICES AND DEPENDENCIES
--============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Data Modules
local DataFolder = script.Parent.Data
local CareerData = require(DataFolder.CareerData)
local TraitData = require(DataFolder.TraitData)
local EventData = require(DataFolder.EventData)

-- System Modules
local SystemsFolder = script.Parent.Systems
local PlayerStateManager = require(SystemsFolder.PlayerStateManager)
local EventEngine = require(SystemsFolder.EventEngine)

-- DataStore
local PlayerDataStore = DataStoreService:GetDataStore("PlayerLifeData_v1")

--============================================================================
-- REMOTE SETUP
--============================================================================
local function SetupRemotes()
    local remotesFolder = ReplicatedStorage:FindFirstChild("LifeRemotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "LifeRemotes"
        remotesFolder.Parent = ReplicatedStorage
    end
    
    -- Create RemoteFunctions
    local functions = {
        "RequestAgeUp",
        "ApplyForJob",
        "QuitJob",
        "DoWork",
        "RequestPromotion",
        "RequestRaise",
        "GetCareerInfo",
        "EnrollEducation",
        "GetEducationInfo",
        "DoActivity",
        "CommitCrime",
        "DoPrisonAction",
        "BuyProperty",
        "BuyVehicle",
        "BuyItem",
        "SellAsset",
        "Gamble",
        "DoInteraction",
        "StartPath",
        "DoPathAction",
        "SubmitChoice",
        "GetAvailableJobs",
        "GetPlayerState",
        "StartNewLife"
    }
    
    -- Create RemoteEvents
    local events = {
        "SyncState",
        "PresentEvent",
        "SetLifeInfo",
        "MinigameStart",
        "MinigameResult"
    }
    
    for _, name in ipairs(functions) do
        if not remotesFolder:FindFirstChild(name) then
            local remote = Instance.new("RemoteFunction")
            remote.Name = name
            remote.Parent = remotesFolder
        end
    end
    
    for _, name in ipairs(events) do
        if not remotesFolder:FindFirstChild(name) then
            local remote = Instance.new("RemoteEvent")
            remote.Name = name
            remote.Parent = remotesFolder
        end
    end
    
    return remotesFolder
end

local Remotes = nil

--============================================================================
-- PLAYER DATA MANAGEMENT
--============================================================================
local PlayerStates = {} -- In-memory cache

-- Load player data
function LifeServer.LoadPlayerData(player)
    local success, data = pcall(function()
        return PlayerDataStore:GetAsync("Player_" .. player.UserId)
    end)
    
    if success and data then
        PlayerStates[player.UserId] = PlayerStateManager.Deserialize(data)
        return PlayerStates[player.UserId]
    end
    
    return nil
end

-- Save player data
function LifeServer.SavePlayerData(player)
    local state = PlayerStates[player.UserId]
    if not state then return false end
    
    local success, err = pcall(function()
        PlayerDataStore:SetAsync("Player_" .. player.UserId, PlayerStateManager.Serialize(state))
    end)
    
    if not success then
        warn("Failed to save player data: " .. tostring(err))
    end
    
    return success
end

-- Auto-save periodically
local function StartAutoSave()
    spawn(function()
        while true do
            wait(60) -- Save every minute
            for userId, state in pairs(PlayerStates) do
                local player = Players:GetPlayerByUserId(userId)
                if player then
                    LifeServer.SavePlayerData(player)
                end
            end
        end
    end)
end

--============================================================================
-- CORE GAME FUNCTIONS
--============================================================================

-- Start a new life
function LifeServer.StartNewLife(player, options)
    options = options or {}
    options.name = options.name or "Baby"
    options.gender = options.gender or (math.random() > 0.5 and "male" or "female")
    
    local state = PlayerStateManager.CreateNewLife(player.UserId, options)
    PlayerStates[player.UserId] = state
    
    -- Sync to client
    LifeServer.SyncState(player)
    
    return state
end

-- Age up the player
function LifeServer.AgeUp(player)
    local state = PlayerStates[player.UserId]
    if not state then return nil end
    
    -- Can't age up if dead
    if state.health <= 0 then
        return nil, "You have died."
    end
    
    -- Process aging
    PlayerStateManager.AgeUp(state)
    
    -- Apply annual income/expenses
    LifeServer.ProcessAnnualFinances(state)
    
    -- Get event for this year
    local event = EventEngine.GetEvent(state)
    
    -- Save and sync
    LifeServer.SavePlayerData(player)
    LifeServer.SyncState(player)
    
    -- Return event if there is one
    if event then
        return {
            event = event,
            state = PlayerStateManager.GetStateSummary(state)
        }
    end
    
    -- No event, return flavor text
    local flavorText = EventEngine.GetWorkDayFlavor(state)
    return {
        flavorText = flavorText,
        state = PlayerStateManager.GetStateSummary(state)
    }
end

-- Process annual finances
function LifeServer.ProcessAnnualFinances(state)
    local income = 0
    local expenses = 0
    
    -- Salary income
    if state.career.currentJob and not state.legal.inPrison then
        income = income + (state.career.salary or 0)
    end
    
    -- Living expenses
    if state.living.type == "own" then
        expenses = expenses + 12000 -- $1000/month rent estimate
    elseif state.living.type == "roommates" then
        expenses = expenses + 6000
    end
    
    -- Property costs
    for _, property in ipairs(state.properties or {}) do
        expenses = expenses + (property.annualCost or 0)
    end
    
    -- Vehicle costs
    for _, vehicle in ipairs(state.vehicles or {}) do
        expenses = expenses + (vehicle.annualCost or 0)
    end
    
    -- Student loan payments
    if state.education.debt > 0 then
        local payment = math.min(state.education.debt * 0.1, 5000) -- 10% or $5000
        expenses = expenses + payment
        state.education.debt = state.education.debt - payment
        if state.education.debt < 0 then state.education.debt = 0 end
    end
    
    -- Apply net income
    local netIncome = income - expenses
    PlayerStateManager.ModifyMoney(state, netIncome)
end

--============================================================================
-- CAREER FUNCTIONS
--============================================================================

-- Get available jobs
function LifeServer.GetAvailableJobs(player)
    local state = PlayerStates[player.UserId]
    if not state then return {} end
    
    return CareerData.GetAvailableJobs(state)
end

-- Apply for job
function LifeServer.ApplyForJob(player, jobId)
    local state = PlayerStates[player.UserId]
    if not state then return false, "No state" end
    
    if state.legal.inPrison then
        return false, "You're in prison"
    end
    
    local job = CareerData.Jobs[jobId]
    if not job then return false, "Job not found" end
    
    if not CareerData.PlayerQualifies(state, job) then
        return false, "You don't qualify for this job"
    end
    
    -- Interview success based on skills and traits
    local interviewScore = 50
    interviewScore = interviewScore + (state.smarts / 5)
    interviewScore = interviewScore + (state.skills.Social or 0) / 3
    
    -- Trait bonuses
    local traitModifiers = TraitData.ApplyTraitEffects(state, state.traits)
    interviewScore = interviewScore + (traitModifiers.interviewBonus or 0) * 100
    
    -- Random factor
    local roll = math.random(1, 100)
    
    if roll <= interviewScore then
        -- Got the job!
        if state.career.currentJob then
            -- Add to history
            table.insert(state.career.history, {
                job = state.career.currentJob,
                years = state.career.yearsInJob,
                endReason = "quit"
            })
        end
        
        state.career.currentJob = job.title
        state.career.yearsInJob = 0
        state.career.performance = 50
        state.career.salary = CareerData.CalculateSalary(job, state, 0)
        state.career.promotionProgress = 0
        state.career.isUnemployed = false
        state.stats.jobsHeld = (state.stats.jobsHeld or 0) + 1
        
        LifeServer.SyncState(player)
        return true, "Congratulations! You got the job as " .. job.title .. "!"
    else
        return false, "Sorry, they went with another candidate."
    end
end

-- Quit job
function LifeServer.QuitJob(player)
    local state = PlayerStates[player.UserId]
    if not state then return false end
    
    if not state.career.currentJob then
        return false, "You don't have a job"
    end
    
    table.insert(state.career.history, {
        job = state.career.currentJob,
        years = state.career.yearsInJob,
        endReason = "quit"
    })
    
    state.career.currentJob = nil
    state.career.yearsInJob = 0
    state.career.salary = 0
    state.career.isUnemployed = true
    
    LifeServer.SyncState(player)
    return true, "You quit your job."
end

-- Do work (improve performance)
function LifeServer.DoWork(player, effort)
    local state = PlayerStates[player.UserId]
    if not state then return false end
    
    if not state.career.currentJob then
        return false, "You need a job first"
    end
    
    effort = effort or "normal" -- "slack", "normal", "hard"
    
    local performanceChange = 0
    local stressChange = 0
    local happinessChange = 0
    
    if effort == "slack" then
        performanceChange = -5
        stressChange = -5
        happinessChange = 5
    elseif effort == "normal" then
        performanceChange = 2
        stressChange = 2
    elseif effort == "hard" then
        performanceChange = 10
        stressChange = 10
        happinessChange = -3
    end
    
    state.career.performance = math.max(0, math.min(100, state.career.performance + performanceChange))
    PlayerStateManager.ModifyStat(state, "stress", stressChange)
    PlayerStateManager.ModifyStat(state, "happiness", happinessChange)
    
    -- Skill gains
    local job = CareerData.Jobs[state.career.currentJob]
    if job and job.skillGains then
        for skill, amount in pairs(job.skillGains) do
            PlayerStateManager.ModifySkill(state, skill, amount * 0.5)
        end
    end
    
    LifeServer.SyncState(player)
    return true, "You worked " .. effort .. "."
end

-- Request promotion
function LifeServer.RequestPromotion(player)
    local state = PlayerStates[player.UserId]
    if not state then return false end
    
    if not state.career.currentJob then
        return false, "You need a job first"
    end
    
    local job = CareerData.Jobs[state.career.currentJob]
    local promotionJob = CareerData.GetPromotionJob(job)
    
    if not promotionJob then
        return false, "There's no promotion available from this position"
    end
    
    -- Check requirements
    local score = state.career.performance + state.career.promotionProgress
    score = score + state.career.yearsInJob * 5
    
    if math.random(1, 100) <= score then
        -- Promoted!
        table.insert(state.career.history, {
            job = state.career.currentJob,
            years = state.career.yearsInJob,
            endReason = "promoted"
        })
        
        state.career.currentJob = promotionJob.title
        state.career.yearsInJob = 0
        state.career.salary = CareerData.CalculateSalary(promotionJob, state, 0)
        state.career.promotionProgress = 0
        
        LifeServer.SyncState(player)
        return true, "Congratulations! You've been promoted to " .. promotionJob.title .. "!"
    else
        return false, "Your promotion request was denied. Keep working hard!"
    end
end

-- Request raise
function LifeServer.RequestRaise(player)
    local state = PlayerStates[player.UserId]
    if not state then return false end
    
    if not state.career.currentJob then
        return false, "You need a job first"
    end
    
    local score = state.career.performance
    score = score + state.career.yearsInJob * 10
    
    -- Can't ask too often
    if state.career.lastRaise and (state.age - state.career.lastRaise) < 1 then
        return false, "You just got a raise recently."
    end
    
    if math.random(1, 100) <= score then
        local raisePercent = 5 + math.random(0, 10)
        local raiseAmount = math.floor(state.career.salary * raisePercent / 100)
        state.career.salary = state.career.salary + raiseAmount
        state.career.lastRaise = state.age
        
        LifeServer.SyncState(player)
        return true, "You got a " .. raisePercent .. "% raise! (+" .. raiseAmount .. "/year)"
    else
        return false, "Your raise request was denied."
    end
end

--============================================================================
-- EDUCATION FUNCTIONS
--============================================================================

function LifeServer.EnrollEducation(player, programId)
    local state = PlayerStates[player.UserId]
    if not state then return false end
    
    local programs = {
        ["community_college"] = {name = "Community College", duration = 2, cost = 10000, minAge = 18, yields = "Associate's"},
        ["bachelors"] = {name = "Bachelor's Degree", duration = 4, cost = 80000, minAge = 18, yields = "Bachelor's Degree", requires = "High School"},
        ["masters"] = {name = "Master's Degree", duration = 2, cost = 60000, minAge = 22, yields = "Master's Degree", requires = "Bachelor's Degree"},
        ["law"] = {name = "Law School", duration = 3, cost = 150000, minAge = 22, yields = "Law Degree", requires = "Bachelor's Degree"},
        ["medical"] = {name = "Medical School", duration = 4, cost = 250000, minAge = 22, yields = "Medical Degree", requires = "Bachelor's Degree"},
        ["phd"] = {name = "PhD", duration = 5, cost = 100000, minAge = 24, yields = "PhD", requires = "Master's Degree"}
    }
    
    local program = programs[programId]
    if not program then return false, "Invalid program" end
    
    if state.age < program.minAge then
        return false, "You must be at least " .. program.minAge .. " to enroll"
    end
    
    if program.requires and state.education.level ~= program.requires then
        return false, "You need a " .. program.requires .. " first"
    end
    
    -- Can afford or take loans?
    if state.money < program.cost then
        -- Student loans
        state.education.debt = state.education.debt + program.cost
    else
        state.money = state.money - program.cost
    end
    
    state.education.currentEnrollment = programId
    state.education.progress = 0
    state.education.gpa = 3.0
    
    LifeServer.SyncState(player)
    return true, "You enrolled in " .. program.name .. "!"
end

--============================================================================
-- ACTIVITY FUNCTIONS
--============================================================================

function LifeServer.DoActivity(player, activityId)
    local state = PlayerStates[player.UserId]
    if not state then return false end
    
    local activities = {
        gym = {stat = "Physical", change = 2, happiness = 3, cost = 0},
        library = {stat = "smarts", change = 2, happiness = 1, cost = 0},
        movies = {stat = "happiness", change = 10, cost = 15},
        meditation = {stat = "stress", change = -10, happiness = 5, cost = 0},
        party = {stat = "happiness", change = 15, social = 3, cost = 50},
        volunteer = {stat = "karma", change = 10, happiness = 5, cost = 0},
        therapy = {stat = "happiness", change = 8, stress = -15, cost = 100}
    }
    
    local activity = activities[activityId]
    if not activity then return false, "Unknown activity" end
    
    if state.money < (activity.cost or 0) then
        return false, "You can't afford this"
    end
    
    state.money = state.money - (activity.cost or 0)
    
    if activity.stat and activity.change then
        if state.skills[activity.stat] then
            PlayerStateManager.ModifySkill(state, activity.stat, activity.change)
        else
            PlayerStateManager.ModifyStat(state, activity.stat, activity.change)
        end
    end
    
    if activity.happiness then
        PlayerStateManager.ModifyStat(state, "happiness", activity.happiness)
    end
    
    if activity.social then
        PlayerStateManager.ModifySkill(state, "Social", activity.social)
    end
    
    LifeServer.SyncState(player)
    return true, "Activity completed!"
end

--============================================================================
-- CRIME FUNCTIONS
--============================================================================

function LifeServer.CommitCrime(player, crimeId)
    local state = PlayerStates[player.UserId]
    if not state then return false end
    
    local crimes = {
        shoplift = {reward = 50, catchChance = 0.3, sentence = 0, fine = 100},
        pickpocket = {reward = 100, catchChance = 0.35, sentence = 0, fine = 500},
        burglary = {reward = 2000, catchChance = 0.4, sentence = 2, fine = 2000},
        grand_theft = {reward = 5000, catchChance = 0.45, sentence = 3, fine = 5000},
        robbery = {reward = 10000, catchChance = 0.5, sentence = 5, fine = 10000},
        assault = {reward = 0, catchChance = 0.6, sentence = 3, fine = 1000},
        murder = {reward = 0, catchChance = 0.7, sentence = 25, fine = 0}
    }
    
    local crime = crimes[crimeId]
    if not crime then return false, "Unknown crime" end
    
    -- Apply skill modifiers
    local catchChance = crime.catchChance
    catchChance = catchChance - (state.skills.Criminal or 0) / 200
    catchChance = catchChance - (state.skills.Stealth or 0) / 300
    
    -- Trait modifiers
    local traitMods = TraitData.ApplyTraitEffects(state, state.traits)
    catchChance = catchChance - (traitMods.crimeSuccess or 0)
    
    catchChance = math.max(0.1, math.min(0.9, catchChance))
    
    if math.random() < catchChance then
        -- Caught!
        if crime.sentence > 0 then
            PlayerStateManager.SendToPrison(state, crime.sentence, crimeId)
            LifeServer.SyncState(player)
            return false, "You were caught! Sentenced to " .. crime.sentence .. " years in prison!"
        else
            state.money = state.money - crime.fine
            state.stats.crimesCommitted = (state.stats.crimesCommitted or 0) + 1
            LifeServer.SyncState(player)
            return false, "You were caught! Fined $" .. crime.fine .. "!"
        end
    else
        -- Success!
        state.money = state.money + crime.reward
        state.stats.crimesCommitted = (state.stats.crimesCommitted or 0) + 1
        PlayerStateManager.ModifySkill(state, "Criminal", 2)
        PlayerStateManager.ModifyStat(state, "karma", -10)
        
        LifeServer.SyncState(player)
        return true, "Crime successful! You got away with $" .. crime.reward .. "!"
    end
end

--============================================================================
-- RELATIONSHIP FUNCTIONS
--============================================================================

function LifeServer.DoInteraction(player, personId, action)
    local state = PlayerStates[player.UserId]
    if not state then return false end
    
    -- Find the person
    local person = nil
    local category = nil
    
    for cat, people in pairs(state.relationships) do
        if type(people) == "table" then
            for _, p in ipairs(people) do
                if p.id == personId then
                    person = p
                    category = cat
                    break
                end
            end
        end
    end
    
    if not person then return false, "Person not found" end
    if not person.alive then return false, "They have passed away" end
    
    local interactions = {
        talk = {change = 5, fail = -2, successRate = 0.8},
        compliment = {change = 8, fail = -3, successRate = 0.7},
        gift = {change = 15, fail = 0, successRate = 0.9, cost = 50},
        argue = {change = -10, fail = -15, successRate = 0.4},
        hug = {change = 10, fail = -5, successRate = 0.75},
        insult = {change = -20, fail = -10, successRate = 0.6},
        fight = {change = -30, fail = -20, successRate = 0.5}
    }
    
    local interaction = interactions[action]
    if not interaction then return false, "Unknown action" end
    
    if interaction.cost and state.money < interaction.cost then
        return false, "You can't afford this"
    end
    
    if interaction.cost then
        state.money = state.money - interaction.cost
    end
    
    local success = math.random() < interaction.successRate
    local change = success and interaction.change or interaction.fail
    
    person.relationshipQuality = math.max(0, math.min(100, (person.relationshipQuality or 50) + change))
    
    LifeServer.SyncState(player)
    
    if success then
        return true, "The interaction went well!"
    else
        return false, "That didn't go as planned..."
    end
end

--============================================================================
-- EVENT HANDLING
--============================================================================

function LifeServer.SubmitChoice(player, eventId, choiceIndex)
    local state = PlayerStates[player.UserId]
    if not state then return nil end
    
    -- Get the current event (should be stored temporarily)
    -- For now, we'll just process the choice and return outcome
    local outcome = EventEngine.ProcessChoice({id = eventId, choices = {{}, {}, {}, {}}}, choiceIndex)
    
    if outcome and outcome.effects then
        -- Apply effects
        for effect, value in pairs(outcome.effects) do
            if effect == "money" then
                PlayerStateManager.ModifyMoney(state, value)
            elseif effect == "health" then
                PlayerStateManager.ModifyHealth(state, value)
            elseif effect == "happiness" then
                PlayerStateManager.ModifyStat(state, "happiness", value)
            elseif effect == "stress" then
                PlayerStateManager.ModifyStat(state, "stress", value)
            elseif effect == "karma" then
                PlayerStateManager.ModifyStat(state, "karma", value)
            elseif effect == "reputation" then
                -- Handle reputation
            elseif effect == "fired" then
                LifeServer.QuitJob(player)
            elseif effect == "arrested" then
                PlayerStateManager.SendToPrison(state, 1, "crime")
            end
        end
        
        -- Record event in history
        state.eventHistory[eventId] = state.age
    end
    
    LifeServer.SyncState(player)
    return outcome
end

--============================================================================
-- SYNC AND UTILITIES
--============================================================================

function LifeServer.SyncState(player)
    local state = PlayerStates[player.UserId]
    if not state then return end
    
    if Remotes then
        local syncRemote = Remotes:FindFirstChild("SyncState")
        if syncRemote then
            syncRemote:FireClient(player, state)
        end
    end
end

function LifeServer.GetPlayerState(player)
    return PlayerStates[player.UserId]
end

--============================================================================
-- INITIALIZATION
--============================================================================

function LifeServer.Init()
    print("LifeServer initializing...")
    
    -- Setup remotes
    Remotes = SetupRemotes()
    
    -- Connect remote handlers
    local functions = Remotes:GetChildren()
    for _, remote in ipairs(functions) do
        if remote:IsA("RemoteFunction") then
            if LifeServer[remote.Name] then
                remote.OnServerInvoke = function(player, ...)
                    return LifeServer[remote.Name](player, ...)
                end
            end
        end
    end
    
    -- Player join/leave handlers
    Players.PlayerAdded:Connect(function(player)
        local data = LifeServer.LoadPlayerData(player)
        if not data then
            -- No existing save, wait for them to create a life
            PlayerStates[player.UserId] = nil
        else
            LifeServer.SyncState(player)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        LifeServer.SavePlayerData(player)
        PlayerStates[player.UserId] = nil
    end)
    
    -- Start auto-save
    StartAutoSave()
    
    print("LifeServer initialized with " .. CareerData.GetJobCount() .. " careers!")
end

-- Run initialization
if RunService:IsServer() then
    LifeServer.Init()
end

return LifeServer
