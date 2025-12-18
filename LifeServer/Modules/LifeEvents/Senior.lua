--[[
    Senior Events (Ages 60+)
    Golden years, retirement, legacy, health challenges, and end-of-life events
    
    Comprehensive events for senior citizens covering:
    - Retirement and post-work life
    - Health and aging challenges
    - Family relationships (grandchildren, adult children)
    - Legacy and life reflection
    - Hobbies and activities for seniors
    - Financial planning for retirement
    - Loss and grief
    - End-of-life planning
]]

local Senior = {}

local STAGE = "senior"

-- Helper function for random names
local function getRandomName(isMale)
    local maleNames = {"James", "William", "Robert", "Michael", "David", "Richard", "Joseph", "Thomas", "Charles", "Daniel"}
    local femaleNames = {"Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Susan", "Jessica", "Sarah", "Karen"}
    local names = isMale and maleNames or femaleNames
    return names[math.random(1, #names)]
end

Senior.events = {
    -- ══════════════════════════════════════════════════════════════════════════════
    -- EARLY RETIREMENT (60-70)
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "retirement_party",
        title = "Retirement Party",
        emoji = "🎉",
        text = "Your colleagues are throwing you a retirement party! Everyone is gathered to celebrate your career.",
        question = "How do you feel about retiring?",
        minAge = 60, maxAge = 70,
        oneTime = true,
        requiresFlags = { employed = true },
        blockedByFlags = { retired = true, in_prison = true },
        
        stage = STAGE,
        ageBand = "senior_early",
        category = "career",
        tags = { "retirement", "celebration", "career_end" },
        
        choices = {
            {
                text = "Excited - finally free!",
                effects = { Happiness = 15 },
                setFlags = { retired = true, retirement_happy = true },
                feedText = "Freedom! No more alarm clocks!",
                onResolve = function(state)
                    -- Calculate pension based on final salary
                    local pension = 0
                    if state.CurrentJob and state.CurrentJob.salary then
                        pension = math.floor(state.CurrentJob.salary * 0.45)
                        state.Flags = state.Flags or {}
                        state.Flags.pension_amount = pension
                    end
                    -- Store job info for legacy
                    state.CareerInfo = state.CareerInfo or {}
                    state.CareerInfo.lastJob = state.CurrentJob
                    state.CareerInfo.retirementAge = state.Age
                    state.CareerInfo.totalYearsWorked = (state.Age or 65) - 18
                    -- Clear job
                    state.CurrentJob = nil
                    state.Flags.employed = nil
                    state.Flags.has_job = nil
                    if state.AddFeed then
                        state:AddFeed(string.format("🎉 Retired with a pension of $%d/year! Party time!", pension))
                    end
                end,
            },
            {
                text = "Bittersweet - I'll miss work",
                effects = { Happiness = 5 },
                setFlags = { retired = true, misses_work = true },
                feedText = "Mixed feelings about leaving...",
                onResolve = function(state)
                    local pension = 0
                    if state.CurrentJob and state.CurrentJob.salary then
                        pension = math.floor(state.CurrentJob.salary * 0.45)
                        state.Flags = state.Flags or {}
                        state.Flags.pension_amount = pension
                    end
                    state.CareerInfo = state.CareerInfo or {}
                    state.CareerInfo.lastJob = state.CurrentJob
                    state.CareerInfo.retirementAge = state.Age
                    state.CurrentJob = nil
                    state.Flags.employed = nil
                    state.Flags.has_job = nil
                    if state.AddFeed then
                        state:AddFeed("🎉 Retired but already missing your colleagues...")
                    end
                end,
            },
            {
                text = "Nervous about what comes next",
                effects = { Happiness = -2 },
                setFlags = { retired = true, retirement_anxiety = true },
                feedText = "What will you do with all this free time?",
                onResolve = function(state)
                    local pension = 0
                    if state.CurrentJob and state.CurrentJob.salary then
                        pension = math.floor(state.CurrentJob.salary * 0.40)
                        state.Flags = state.Flags or {}
                        state.Flags.pension_amount = pension
                    end
                    state.CareerInfo = state.CareerInfo or {}
                    state.CareerInfo.lastJob = state.CurrentJob
                    state.CurrentJob = nil
                    state.Flags.employed = nil
                    state.Flags.has_job = nil
                    if state.AddFeed then
                        state:AddFeed("🎉 Retired, but worried about the future...")
                    end
                end,
            },
            {
                text = "Actually, I'm not ready to retire",
                effects = { Happiness = 5, Money = 500 },
                feedText = "You decided to keep working a bit longer.",
            },
        },
    },
    
    {
        id = "retirement_adjustment",
        title = "Adjusting to Retirement",
        emoji = "🏠",
        text = "It's been a few months since you retired. The adjustment is... interesting.",
        question = "How's retirement treating you?",
        minAge = 60, maxAge = 72,
        oneTime = true,
        requiresFlags = { retired = true },
        blockedByFlags = { in_prison = true },
        
        stage = STAGE,
        ageBand = "senior_early",
        category = "lifestyle",
        tags = { "retirement", "adjustment", "routine" },
        
        choices = {
            { 
                text = "Loving it! Found new hobbies", 
                effects = { Happiness = 10 }, 
                setFlags = { retirement_thriving = true }, 
                feedText = "You're busier than ever with hobbies and activities!" 
            },
            { 
                text = "Driving my spouse crazy at home", 
                effects = { Happiness = -5 }, 
                setFlags = { retirement_friction = true }, 
                feedText = "Too much togetherness can be challenging..." 
            },
            { 
                text = "Bored - miss the structure", 
                effects = { Happiness = -8 }, 
                setFlags = { retirement_bored = true }, 
                feedText = "Days blur together without work routines." 
            },
            { 
                text = "Volunteering to stay active", 
                effects = { Happiness = 8 }, 
                setFlags = { volunteer_retiree = true }, 
                feedText = "Giving back feels wonderful!" 
            },
            { 
                text = "Took a part-time job", 
                effects = { Happiness = 5, Money = 500 }, 
                setFlags = { semi_retired = true }, 
                feedText = "A little extra income and purpose!" 
            },
        },
    },
    
    {
        id = "senior_health_checkup",
        title = "Annual Health Screening",
        emoji = "🩺",
        text = "Time for your annual senior health screening. The doctor runs all the tests.",
        question = "What did the results show?",
        minAge = 60, maxAge = 95,
        baseChance = 0.7,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior",
        category = "health",
        tags = { "medical", "screening", "health" },
        
        -- CRITICAL FIX: Random health outcome based on current health, not player choice
        choices = {
            {
                text = "Get the full screening done",
                effects = { Money = -300 },
                feedText = "The doctor reviews your results...",
                onResolve = function(state)
                    local health = (state.Stats and state.Stats.Health) or 50
                    local age = state.Age or 70
                    local roll = math.random()
                    -- Older and less healthy = more likely to have issues
                    local problemChance = 0.20 + ((age - 60) / 100) - (health / 200)
                    
                    if roll < problemChance * 0.3 then
                        -- Serious issue found
                        state:ModifyStat("Health", -10)
                        state:ModifyStat("Happiness", -10)
                        state.Flags = state.Flags or {}
                        state.Flags.serious_health_issue = true
                        state:AddFeed("🩺 Concerning results. The doctor wants more tests. This is serious.")
                    elseif roll < problemChance then
                        -- Minor issue found
                        state:ModifyStat("Health", -3)
                        state:ModifyStat("Happiness", -3)
                        state:AddFeed("🩺 Some issues to watch. New medications prescribed.")
                    elseif roll < problemChance + 0.35 then
                        -- Okay but need to watch things
                        state:ModifyStat("Happiness", 2)
                        state:AddFeed("🩺 Mostly good! Just need to watch cholesterol/blood pressure.")
                    else
                        -- Clean bill of health
                        state:ModifyStat("Health", 5)
                        state:ModifyStat("Happiness", 8)
                        state:AddFeed("🩺 Excellent health for your age! Keep up the good work!")
                    end
                end,
            },
            {
                text = "Skip it - I feel fine",
                effects = {},
                feedText = "You decided to skip the checkup...",
                onResolve = function(state)
                    local roll = math.random()
                    if roll < 0.20 then
                        state:ModifyStat("Health", -8)
                        state.Flags = state.Flags or {}
                        state.Flags.undiagnosed_condition = true
                        state:AddFeed("🩺 You felt fine, but something might be developing undetected...")
                    else
                        state:AddFeed("🩺 Skipped the checkup. Probably fine... right?")
                    end
                end,
            },
        },
    },
    
    {
        id = "grandchild_visit",
        title = "Grandchildren Visit",
        emoji = "👶",
        text = "Your grandchildren are visiting! The house is alive with their energy.",
        question = "How do you spend time with them?",
        minAge = 55, maxAge = 95,
        baseChance = 0.6,
        cooldown = 2,
        requiresFlags = { grandparent = true },
        
        stage = STAGE,
        ageBand = "senior",
        category = "family",
        tags = { "grandchildren", "family", "joy" },
        
        choices = {
            { 
                text = "Spoil them with treats and gifts", 
                effects = { Happiness = 12, Money = -100 }, 
                setFlags = { spoiling_grandparent = true }, 
                feedText = "What are grandparents for if not spoiling?!" 
            },
            { 
                text = "Share stories from your life", 
                effects = { Happiness = 10, Smarts = 2 }, 
                setFlags = { storyteller_grandparent = true }, 
                feedText = "They love hearing about 'the old days!'" 
            },
            { 
                text = "Teach them something special", 
                effects = { Happiness = 8, Smarts = 3 }, 
                feedText = "Passing down skills and knowledge!" 
            },
            { 
                text = "Play games together", 
                effects = { Happiness = 10, Health = 2 }, 
                feedText = "Board games, video games - fun for everyone!" 
            },
            { 
                text = "Let the parents deal with them", 
                effects = { Happiness = 3 }, 
                feedText = "You're tired. You did your parenting years ago." 
            },
        },
    },
    
    {
        id = "senior_hobby_discovery",
        title = "New Hobby in Retirement",
        emoji = "🎨",
        text = "With all this free time in retirement, you're looking for a new hobby.",
        question = "What catches your interest?",
        minAge = 60, maxAge = 85,
        oneTime = true,
        requiresFlags = { retired = true },
        
        stage = STAGE,
        ageBand = "senior_early",
        category = "hobbies",
        tags = { "hobby", "retirement", "activities" },
        
        choices = {
            { 
                text = "Gardening", 
                effects = { Happiness = 8, Health = 5 }, 
                setFlags = { gardener = true }, 
                feedText = "Your garden is thriving! So peaceful." 
            },
            { 
                text = "Painting or art", 
                effects = { Happiness = 10, Smarts = 3 }, 
                setFlags = { artist_senior = true }, 
                feedText = "You discovered a hidden artistic talent!" 
            },
            { 
                text = "Woodworking", 
                effects = { Happiness = 7, Smarts = 2 }, 
                setFlags = { woodworker = true }, 
                feedText = "Building things with your hands is satisfying." 
            },
            { 
                text = "Golf", 
                effects = { Happiness = 6, Health = 3, Money = -200 }, 
                setFlags = { golfer = true }, 
                feedText = "Out on the course several times a week!" 
            },
            { 
                text = "Writing memoirs", 
                effects = { Happiness = 8, Smarts = 5 }, 
                setFlags = { memoirist = true }, 
                feedText = "Your life story deserves to be told." 
            },
            { 
                text = "Learning technology", 
                effects = { Smarts = 8, Happiness = 5 }, 
                setFlags = { tech_savvy_senior = true }, 
                feedText = "You're mastering smartphones and tablets!" 
            },
        },
    },
    
    {
        id = "senior_travel_opportunity",
        title = "Retirement Travel",
        emoji = "✈️",
        text = "You finally have time to travel! Where do you go?",
        question = "Choose your adventure:",
        minAge = 60, maxAge = 80,
        baseChance = 0.5,
        cooldown = 3,
        requiresFlags = { retired = true },
        blockedByFlags = { in_prison = true, serious_health_issue = true },
        eligibility = function(state)
            local money = state.Money or 0
            if money < 500 then
                return false, "Can't afford to travel"
            end
            return true
        end,
        
        stage = STAGE,
        ageBand = "senior",
        category = "travel",
        tags = { "travel", "adventure", "bucket_list" },
        
        choices = {
            {
                text = "Cruise vacation",
                effects = {},
                feedText = "You booked a cruise...",
                onResolve = function(state)
                    local money = state.Money or 0
                    if money >= 5000 then
                        state.Money = money - 5000
                        state:ModifyStat("Happiness", 15)
                        state:ModifyStat("Health", 3)
                        state:AddFeed("🚢 Luxury cruise! Fine dining, ports of call, paradise!")
                    elseif money >= 2000 then
                        state.Money = money - 2000
                        state:ModifyStat("Happiness", 10)
                        state:AddFeed("🚢 Nice cruise! Saw beautiful places from the ship!")
                    else
                        state.Money = money - 500
                        state:ModifyStat("Happiness", 6)
                        state:AddFeed("🚢 Budget cruise but still amazing to travel!")
                    end
                end,
            },
            {
                text = "National Parks road trip",
                effects = {},
                feedText = "You hit the open road...",
                onResolve = function(state)
                    local money = state.Money or 0
                    if money >= 3000 then
                        state.Money = money - 3000
                        state:ModifyStat("Happiness", 12)
                        state:ModifyStat("Health", 5)
                        state.Flags = state.Flags or {}
                        state.Flags.nature_lover = true
                        state:AddFeed("🏞️ Incredible trip! Saw the Grand Canyon, Yellowstone, and more!")
                    elseif money >= 1000 then
                        state.Money = money - 1000
                        state:ModifyStat("Happiness", 8)
                        state:ModifyStat("Health", 3)
                        state:AddFeed("🏞️ Great trip to nearby parks! America is beautiful.")
                    else
                        state.Money = money - 300
                        state:ModifyStat("Happiness", 5)
                        state:AddFeed("🏞️ Day trips to local parks. Still wonderful!")
                    end
                end,
            },
            {
                text = "International adventure",
                effects = {},
                feedText = "You booked an international trip...",
                onResolve = function(state)
                    local money = state.Money or 0
                    if money >= 8000 then
                        state.Money = money - 8000
                        state:ModifyStat("Happiness", 18)
                        state:ModifyStat("Smarts", 3)
                        state.Flags = state.Flags or {}
                        state.Flags.world_traveler = true
                        state:AddFeed("🌍 Dream trip of a lifetime! Europe/Asia/wherever you dreamed!")
                    elseif money >= 4000 then
                        state.Money = money - 4000
                        state:ModifyStat("Happiness", 12)
                        state:ModifyStat("Smarts", 2)
                        state:AddFeed("🌍 Great international trip! Crossed places off your bucket list!")
                    else
                        state:ModifyStat("Happiness", -2)
                        state:AddFeed("🌍 Can't quite afford international travel right now...")
                    end
                end,
            },
            {
                text = "Visit family across the country",
                effects = {},
                feedText = "You visited family...",
                onResolve = function(state)
                    local money = state.Money or 0
                    state.Money = math.max(0, money - math.min(1500, money * 0.3))
                    state:ModifyStat("Happiness", 10)
                    state:AddFeed("👨‍👩‍👧‍👦 Wonderful time reconnecting with family!")
                end,
            },
            {
                text = "Stay home - travel is exhausting",
                effects = { Happiness = 2, Health = 2 },
                feedText = "You enjoyed staying home. Nothing wrong with that!",
            },
        },
    },
    
    {
        id = "senior_center_activities",
        title = "Senior Center",
        emoji = "🏛️",
        text = "The local senior center has lots of activities. You decide to check it out.",
        question = "What program interests you?",
        minAge = 62, maxAge = 90,
        baseChance = 0.5,
        cooldown = 3,
        
        stage = STAGE,
        ageBand = "senior",
        category = "social",
        tags = { "community", "activities", "social" },
        
        choices = {
            { 
                text = "Exercise classes", 
                effects = { Health = 8, Happiness = 5 }, 
                setFlags = { exercises_regularly = true }, 
                feedText = "Low-impact aerobics keep you moving!" 
            },
            { 
                text = "Card games and bingo", 
                effects = { Happiness = 7, Smarts = 2 }, 
                setFlags = { card_player = true }, 
                feedText = "You made friends over poker and bingo!" 
            },
            { 
                text = "Computer classes", 
                effects = { Smarts = 8, Happiness = 5 }, 
                setFlags = { learning_tech = true }, 
                feedText = "Now you can email and video chat with family!" 
            },
            { 
                text = "Book club", 
                effects = { Smarts = 5, Happiness = 6 }, 
                setFlags = { bookworm_senior = true }, 
                feedText = "Great discussions about books and life!" 
            },
            { 
                text = "Not interested - prefer being home", 
                effects = { Happiness = -2 }, 
                setFlags = { homebound_preference = true }, 
                feedText = "Social activities aren't for everyone." 
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- MID-SENIOR YEARS (70-80)
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "mobility_challenges",
        title = "Getting Around",
        emoji = "🦯",
        text = "Moving around isn't as easy as it used to be. Stairs and long walks are getting harder.",
        question = "How do you adapt?",
        minAge = 70, maxAge = 90,
        baseChance = 0.5,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior_mid",
        category = "health",
        tags = { "mobility", "aging", "adaptation" },
        
        choices = {
            { 
                text = "Get a cane or walker", 
                effects = { Health = 3, Happiness = -2 }, 
                setFlags = { uses_mobility_aid = true }, 
                feedText = "Pride aside, the cane really helps." 
            },
            { 
                text = "Physical therapy", 
                effects = { Health = 8, Money = -500, Happiness = 3 }, 
                setFlags = { physical_therapy = true }, 
                feedText = "The exercises are helping! Slowly improving." 
            },
            { 
                text = "Modify the house", 
                effects = { Happiness = 5, Money = -2000 }, 
                setFlags = { accessible_home = true }, 
                feedText = "Grab bars, no-step entry... home is safer now." 
            },
            { 
                text = "Push through the pain", 
                effects = { Health = -5, Happiness = -3 }, 
                setFlags = { stubborn_about_health = true }, 
                feedText = "Too stubborn for help. It's getting harder." 
            },
        },
    },
    
    {
        id = "memory_concerns",
        title = "Memory Worries",
        emoji = "🧠",
        text = "You've been forgetting things more often. Keys, names, appointments...",
        question = "How do you handle these concerns?",
        minAge = 68, maxAge = 95,
        baseChance = 0.4,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior_mid",
        category = "health",
        tags = { "memory", "aging", "cognitive" },
        
        -- CRITICAL FIX: Random outcome - memory issues aren't always serious
        choices = {
            {
                text = "See a doctor about it",
                effects = { Money = -300 },
                feedText = "The doctor ran some cognitive tests...",
                onResolve = function(state)
                    local age = state.Age or 75
                    local smarts = (state.Stats and state.Stats.Smarts) or 50
                    local roll = math.random()
                    -- Older and lower smarts = higher risk
                    local seriousRisk = 0.15 + ((age - 65) / 200) - (smarts / 300)
                    
                    if roll < seriousRisk then
                        state:ModifyStat("Happiness", -15)
                        state.Flags = state.Flags or {}
                        state.Flags.cognitive_decline = true
                        state:AddFeed("🧠 The diagnosis isn't good. Early stages of dementia detected.")
                    elseif roll < seriousRisk + 0.25 then
                        state:ModifyStat("Happiness", -5)
                        state.Flags = state.Flags or {}
                        state.Flags.mild_memory_issues = true
                        state:AddFeed("🧠 Mild cognitive impairment. Manageable with exercises.")
                    else
                        state:ModifyStat("Happiness", 8)
                        state:AddFeed("🧠 Normal age-related forgetfulness. Nothing to worry about!")
                    end
                end,
            },
            {
                text = "Do brain exercises and puzzles",
                effects = { Smarts = 5, Happiness = 3 },
                setFlags = { does_brain_exercises = true },
                feedText = "Crosswords, sudoku, learning new things... staying sharp!",
            },
            {
                text = "Ignore it - everyone forgets things",
                effects = {},
                feedText = "You brushed off the concerns...",
                onResolve = function(state)
                    local roll = math.random()
                    if roll < 0.15 then
                        state.Flags = state.Flags or {}
                        state.Flags.undiagnosed_memory_issue = true
                        state:AddFeed("🧠 Maybe should have checked... the forgetfulness is getting worse.")
                    else
                        state:AddFeed("🧠 Probably nothing serious. Just normal aging.")
                    end
                end,
            },
            {
                text = "Start writing everything down",
                effects = { Smarts = 2, Happiness = 2 },
                setFlags = { uses_memory_aids = true },
                feedText = "Lists and notes everywhere! It helps a lot.",
            },
        },
    },
    
    {
        id = "old_friend_reunion",
        title = "Blast from the Past",
        emoji = "👋",
        text = "You reconnected with an old friend from decades ago!",
        question = "How does the reunion go?",
        minAge = 60, maxAge = 90,
        baseChance = 0.4,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior",
        category = "relationships",
        tags = { "friends", "reunion", "nostalgia" },
        
        choices = {
            { 
                text = "Like no time has passed!", 
                effects = { Happiness = 12 }, 
                setFlags = { reconnected_friends = true }, 
                feedText = "You picked up right where you left off!" 
            },
            { 
                text = "Realize how much you've both changed", 
                effects = { Happiness = 3, Smarts = 3 }, 
                feedText = "Different people now, but good to reconnect." 
            },
            { 
                text = "Sad - they aren't doing well", 
                effects = { Happiness = -5 }, 
                feedText = "It's hard seeing old friends struggle..." 
            },
            { 
                text = "They've passed away", 
                effects = { Happiness = -10, Health = -2 }, 
                setFlags = { friend_passed = true }, 
                feedText = "You learned they passed. Another one gone..." 
            },
        },
    },
    
    {
        id = "financial_review_senior",
        title = "Retirement Financial Review",
        emoji = "💰",
        text = "Time to review your retirement finances. Are you on track?",
        question = "What does the assessment show?",
        minAge = 65, maxAge = 85,
        baseChance = 0.4,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior",
        category = "money",
        tags = { "finances", "retirement", "planning" },
        
        -- CRITICAL FIX: Financial outcome based on actual money, not choice
        choices = {
            {
                text = "Review the numbers",
                effects = {},
                feedText = "Looking at the finances...",
                onResolve = function(state)
                    local money = state.Money or 0
                    local pension = (state.Flags and state.Flags.pension_amount) or 0
                    local hasSavings = state.Flags and (state.Flags.saver or state.Flags.investor or state.Flags.retirement_saver)
                    
                    local financialScore = 0
                    if money > 100000 then financialScore = financialScore + 4 end
                    if money > 50000 then financialScore = financialScore + 3 end
                    if money > 20000 then financialScore = financialScore + 2 end
                    if money > 5000 then financialScore = financialScore + 1 end
                    if pension > 20000 then financialScore = financialScore + 2 end
                    if hasSavings then financialScore = financialScore + 2 end
                    
                    if financialScore >= 8 then
                        state:ModifyStat("Happiness", 10)
                        state:AddFeed("💰 Financially secure! Retirement is comfortable.")
                    elseif financialScore >= 5 then
                        state:ModifyStat("Happiness", 5)
                        state:AddFeed("💰 Doing okay. Not luxurious but stable.")
                    elseif financialScore >= 2 then
                        state:ModifyStat("Happiness", -3)
                        state:AddFeed("💰 Tight budget. Need to be careful with spending.")
                    else
                        state:ModifyStat("Happiness", -8)
                        state.Flags = state.Flags or {}
                        state.Flags.financially_struggling = true
                        state:AddFeed("💰 Struggling financially. May need to rely on family or assistance.")
                    end
                end,
            },
            {
                text = "Don't want to know",
                effects = { Happiness = -2 },
                feedText = "Ignorance is bliss... for now.",
            },
        },
    },
    
    {
        id = "driving_concerns",
        title = "Behind the Wheel",
        emoji = "🚗",
        text = "Your family is worried about your driving. Reflexes aren't what they used to be.",
        question = "How do you respond?",
        minAge = 72, maxAge = 92,
        baseChance = 0.4,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior_mid",
        category = "independence",
        tags = { "driving", "safety", "independence" },
        
        choices = {
            { 
                text = "Take a senior driving course", 
                effects = { Smarts = 3, Money = -100 }, 
                setFlags = { senior_driver_trained = true }, 
                feedText = "The refresher course helped! Insurance discount too!" 
            },
            { 
                text = "Give up the keys voluntarily", 
                effects = { Happiness = -10 }, 
                setFlags = { stopped_driving = true }, 
                feedText = "Losing independence hurts, but you know it's safer." 
            },
            { 
                text = "Refuse to stop driving", 
                effects = { Happiness = 3 },
                feedText = "You insist you're fine...",
                onResolve = function(state)
                    local roll = math.random()
                    if roll < 0.20 then
                        state:ModifyStat("Health", -10)
                        state:ModifyStat("Happiness", -15)
                        state.Money = math.max(0, (state.Money or 0) - 3000)
                        state.Flags = state.Flags or {}
                        state.Flags.car_accident_senior = true
                        state:AddFeed("🚗 Had a fender bender. Family was right to worry...")
                    elseif roll < 0.40 then
                        state:AddFeed("🚗 No incidents yet, but a few close calls...")
                    else
                        state:AddFeed("🚗 Driving fine! Still got it!")
                    end
                end,
            },
            { 
                text = "Only drive during the day", 
                effects = { Happiness = -3 }, 
                setFlags = { daytime_driver_only = true }, 
                feedText = "Compromise - no night driving. Safer this way." 
            },
        },
    },
    
    {
        id = "adult_child_conflict",
        title = "Family Tensions",
        emoji = "😤",
        text = "You're having some conflict with your adult children. They think they know what's best for you.",
        question = "How do you handle this?",
        minAge = 65, maxAge = 90,
        baseChance = 0.4,
        cooldown = 2,
        requiresFlags = { has_child = true },
        
        stage = STAGE,
        ageBand = "senior",
        category = "family",
        tags = { "family", "conflict", "independence" },
        
        choices = {
            { 
                text = "Have a heart-to-heart talk", 
                effects = { Happiness = 5 }, 
                setFlags = { good_family_communication = true }, 
                feedText = "You worked things out. They just care about you." 
            },
            { 
                text = "Assert your independence", 
                effects = { Happiness = 3 }, 
                setFlags = { fiercely_independent = true }, 
                feedText = "You reminded them you're capable of making your own decisions!" 
            },
            { 
                text = "Give in to their demands", 
                effects = { Happiness = -5 }, 
                setFlags = { feels_controlled = true }, 
                feedText = "You went along with it, but you're not happy." 
            },
            { 
                text = "Create some distance", 
                effects = { Happiness = -8 }, 
                setFlags = { family_estranged = true }, 
                feedText = "Less contact for now. Need space." 
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- LATE SENIOR YEARS (80+)
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "assisted_living_decision",
        title = "Living Arrangements",
        emoji = "🏥",
        text = "Living independently is getting harder. Your family thinks you need more help.",
        question = "What do you decide?",
        minAge = 78, maxAge = 95,
        baseChance = 0.4,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior_late",
        category = "housing",
        tags = { "assisted_living", "care", "independence" },
        
        choices = {
            { 
                text = "Move to assisted living", 
                effects = { Health = 5, Happiness = -5, Money = -5000 }, 
                setFlags = { assisted_living = true }, 
                feedText = "It's different, but the care is good." 
            },
            { 
                text = "In-home caregiver", 
                effects = { Health = 3, Happiness = 3, Money = -3000 }, 
                setFlags = { has_caregiver = true }, 
                feedText = "Help comes to you. Staying home is important." 
            },
            { 
                text = "Move in with adult child", 
                effects = { Happiness = 5 }, 
                setFlags = { lives_with_family = true }, 
                feedText = "Multi-generational living. Family is close." 
            },
            { 
                text = "Stubbornly stay independent", 
                effects = { Happiness = 3, Health = -5 }, 
                setFlags = { refuses_help = true }, 
                feedText = "You're managing... mostly. Scary close calls sometimes." 
            },
        },
    },
    
    {
        id = "health_scare_serious",
        title = "Health Emergency",
        emoji = "🚑",
        text = "A sudden health emergency sends you to the hospital!",
        question = "What happened?",
        minAge = 70, maxAge = 95,
        baseChance = 0.455,
        cooldown = 3,
        
        stage = STAGE,
        ageBand = "senior_late",
        category = "health",
        tags = { "emergency", "hospital", "health_crisis" },
        
        -- CRITICAL FIX: Random emergency type, not player choice
        choices = {
            {
                text = "Get emergency care",
                effects = { Money = -2000 },
                feedText = "In the ambulance...",
                onResolve = function(state)
                    local health = (state.Stats and state.Stats.Health) or 50
                    local age = state.Age or 80
                    local roll = math.random()
                    
                    -- Determine type of emergency
                    local emergencyRoll = math.random(1, 10)
                    local emergencyType = ""
                    local severity = 0
                    
                    if emergencyRoll <= 3 then
                        emergencyType = "heart"
                        severity = 3
                    elseif emergencyRoll <= 5 then
                        emergencyType = "fall"
                        severity = 2
                    elseif emergencyRoll <= 7 then
                        emergencyType = "stroke"
                        severity = 3
                    else
                        emergencyType = "other"
                        severity = 1
                    end
                    
                    -- Recovery chance based on health
                    local recoveryChance = 0.60 + (health / 200) - ((age - 60) / 100)
                    
                    if roll < recoveryChance then
                        -- Good recovery
                        state:ModifyStat("Health", -5 * severity)
                        state:ModifyStat("Happiness", -5)
                        if emergencyType == "heart" then
                            state.Flags = state.Flags or {}
                            state.Flags.heart_condition = true
                            state:AddFeed("🚑 Heart scare! Surgery went well. On new medications now.")
                        elseif emergencyType == "fall" then
                            state.Flags = state.Flags or {}
                            state.Flags.had_bad_fall = true
                            state:AddFeed("🚑 Bad fall! Broke a bone but recovering well.")
                        elseif emergencyType == "stroke" then
                            state.Flags = state.Flags or {}
                            state.Flags.stroke_survivor = true
                            state:AddFeed("🚑 Stroke! Got treatment fast. Recovery is good.")
                        else
                            state:AddFeed("🚑 Hospital stay but you pulled through!")
                        end
                    elseif roll < recoveryChance + 0.25 then
                        -- Partial recovery
                        state:ModifyStat("Health", -15)
                        state:ModifyStat("Happiness", -10)
                        state.Flags = state.Flags or {}
                        state.Flags.chronic_health_issue = true
                        state:AddFeed("🚑 Survived, but with lasting effects. Life is different now.")
                    else
                        -- Serious but stabilized
                        state:ModifyStat("Health", -20)
                        state:ModifyStat("Happiness", -15)
                        state.Flags = state.Flags or {}
                        state.Flags.serious_health_issue = true
                        state:AddFeed("🚑 Touch and go, but you made it. Health has declined significantly.")
                    end
                end,
            },
        },
    },
    
    {
        id = "funeral_planning",
        title = "Making Arrangements",
        emoji = "📋",
        text = "It's practical to plan ahead. You're thinking about funeral arrangements.",
        question = "How do you approach this?",
        minAge = 70, maxAge = 95,
        oneTime = true,
        
        stage = STAGE,
        ageBand = "senior_late",
        category = "end_of_life",
        tags = { "planning", "funeral", "practical" },
        
        choices = {
            { 
                text = "Pre-plan and pre-pay everything", 
                effects = { Happiness = 5, Smarts = 3, Money = -5000 }, 
                setFlags = { funeral_planned = true, prepaid_funeral = true }, 
                feedText = "One less thing for family to worry about." 
            },
            { 
                text = "Write down my wishes", 
                effects = { Happiness = 3, Smarts = 2 }, 
                setFlags = { funeral_planned = true }, 
                feedText = "Family knows what you want. That's enough." 
            },
            { 
                text = "Don't want to think about it", 
                effects = { Happiness = -2 }, 
                feedText = "Too morbid. Skip it." 
            },
            { 
                text = "Want a big celebration of life", 
                effects = { Happiness = 5 }, 
                setFlags = { wants_celebration = true }, 
                feedText = "You want people to party, not mourn!" 
            },
        },
    },
    
    {
        id = "losing_spouse",
        title = "Loss of a Partner",
        emoji = "💔",
        text = "Your beloved partner of many years has passed away.",
        question = "How do you cope with this loss?",
        minAge = 60, maxAge = 95,
        oneTime = true,
        requiresFlags = { married = true },
        blockedByFlags = { widowed = true },
        
        stage = STAGE,
        ageBand = "senior",
        category = "loss",
        tags = { "death", "spouse", "grief" },
        
        choices = {
            { 
                text = "Lean on family and friends", 
                effects = { Happiness = -20, Health = -8 }, 
                setFlags = { widowed = true, grieving = true, has_support = true }, 
                feedText = "The hardest loss of your life. But you're not alone." 
            },
            { 
                text = "Grieve in solitude", 
                effects = { Happiness = -25, Health = -12 }, 
                setFlags = { widowed = true, grieving = true, isolated_grief = true }, 
                feedText = "You withdrew from everyone. The pain is overwhelming." 
            },
            { 
                text = "Focus on keeping their memory alive", 
                effects = { Happiness = -15, Health = -5 }, 
                setFlags = { widowed = true, grieving = true, honoring_memory = true }, 
                feedText = "They live on in memories and the things they loved." 
            },
            { 
                text = "Try to stay strong for the family", 
                effects = { Happiness = -18, Health = -6 }, 
                setFlags = { widowed = true, grieving = true, strong_facade = true }, 
                feedText = "You held it together for everyone else. But the grief is deep." 
            },
        },
        onComplete = function(state)
            state.Flags = state.Flags or {}
            state.Flags.married = nil
            state.Flags.has_partner = nil
            if state.Relationships and state.Relationships.partner then
                state.Relationships.partner.alive = false
                state.Relationships.late_spouse = state.Relationships.partner
                state.Relationships.partner = nil
            end
        end,
    },
    
    {
        id = "losing_friends",
        title = "Outliving Friends",
        emoji = "😢",
        text = "Another friend from your generation has passed away. You're attending too many funerals lately.",
        question = "How does this affect you?",
        minAge = 72, maxAge = 95,
        baseChance = 0.555,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior_late",
        category = "loss",
        tags = { "death", "friends", "mortality" },
        
        choices = {
            { 
                text = "Cherish those still here", 
                effects = { Happiness = -5 }, 
                setFlags = { appreciates_life = true }, 
                feedText = "You call old friends more often now." 
            },
            { 
                text = "Feel increasingly alone", 
                effects = { Happiness = -12, Health = -3 }, 
                setFlags = { lonely_senior = true }, 
                feedText = "Your generation is disappearing..." 
            },
            { 
                text = "Accept it as natural", 
                effects = { Happiness = -3, Smarts = 2 }, 
                setFlags = { accepts_mortality = true }, 
                feedText = "It's the circle of life. Sad but true." 
            },
            { 
                text = "Make new, younger friends", 
                effects = { Happiness = 5 }, 
                setFlags = { intergenerational_friendships = true }, 
                feedText = "You've made friends across generations!" 
            },
        },
    },
    
    {
        id = "great_grandchild",
        title = "Great-Grandchild Born!",
        emoji = "👶",
        text = "You're a great-grandparent now! Four generations of your family exist!",
        question = "How do you feel?",
        minAge = 75, maxAge = 100,
        oneTime = true,
        requiresFlags = { grandparent = true },
        
        stage = STAGE,
        ageBand = "senior_late",
        category = "family",
        tags = { "birth", "legacy", "family" },
        
        choices = {
            { 
                text = "Overwhelmed with joy", 
                effects = { Happiness = 20 }, 
                setFlags = { great_grandparent = true }, 
                feedText = "Four generations! You've seen your legacy grow!" 
            },
            { 
                text = "Feeling blessed to witness this", 
                effects = { Happiness = 15, Health = 3 }, 
                setFlags = { great_grandparent = true }, 
                feedText = "Not everyone gets to meet their great-grandchildren." 
            },
            { 
                text = "A bit too old and tired", 
                effects = { Happiness = 5 }, 
                setFlags = { great_grandparent = true }, 
                feedText = "Happy news, but babies are exhausting at this age." 
            },
        },
    },
    
    {
        id = "birthday_milestone_80",
        title = "🎂 80th Birthday!",
        emoji = "🎉",
        text = "You've reached 80 years old! A major milestone!",
        question = "How do you celebrate?",
        minAge = 80, maxAge = 80,
        oneTime = true,
        priority = "high",
        isMilestone = true,
        
        stage = STAGE,
        ageBand = "senior_late",
        category = "milestone",
        milestoneKey = "SENIOR_80TH_BIRTHDAY",
        tags = { "birthday", "milestone", "celebration" },
        
        choices = {
            { 
                text = "Big family celebration", 
                effects = { Happiness = 15, Money = -500 }, 
                setFlags = { celebrated_80 = true }, 
                feedText = "Everyone came together to honor you!" 
            },
            { 
                text = "Quiet reflection", 
                effects = { Happiness = 8, Smarts = 3 }, 
                setFlags = { celebrated_80 = true }, 
                feedText = "80 years of memories... quite a journey." 
            },
            { 
                text = "Do something wild off the bucket list", 
                effects = { Happiness = 20, Health = -3, Money = -1000 }, 
                setFlags = { celebrated_80 = true, did_something_wild = true }, 
                feedText = "80 and still adventurous! Incredible!" 
            },
        },
    },
    
    {
        id = "birthday_milestone_90",
        title = "🎂 90th Birthday!",
        emoji = "🎊",
        text = "You've reached 90 years old! Very few people make it this far!",
        question = "How are you feeling at 90?",
        minAge = 90, maxAge = 90,
        oneTime = true,
        priority = "high",
        isMilestone = true,
        
        stage = STAGE,
        ageBand = "senior_very_late",
        category = "milestone",
        milestoneKey = "SENIOR_90TH_BIRTHDAY",
        tags = { "birthday", "milestone", "longevity" },
        
        choices = {
            { 
                text = "Grateful for every day", 
                effects = { Happiness = 15 }, 
                setFlags = { celebrated_90 = true, grateful_senior = true }, 
                feedText = "Every day is a blessing at this point." 
            },
            { 
                text = "Still got plenty of life in me!", 
                effects = { Happiness = 20, Health = 5 }, 
                setFlags = { celebrated_90 = true, spirited_senior = true }, 
                feedText = "Age is just a number! 90 never looked so good!" 
            },
            { 
                text = "Ready to see what comes next", 
                effects = { Happiness = 10 }, 
                setFlags = { celebrated_90 = true, at_peace = true }, 
                feedText = "At peace with whatever the future holds." 
            },
        },
    },
    
    {
        id = "centenarian",
        title = "🎂 100 YEARS OLD!",
        emoji = "💯",
        text = "You've reached 100 years old! You're a CENTENARIAN! This is incredibly rare!",
        question = "What's your secret to longevity?",
        minAge = 100, maxAge = 100,
        oneTime = true,
        priority = "high",
        isMilestone = true,
        
        stage = STAGE,
        ageBand = "centenarian",
        category = "milestone",
        milestoneKey = "SENIOR_CENTENARIAN",
        tags = { "birthday", "milestone", "longevity", "rare" },
        
        choices = {
            { 
                text = "Good genes and luck", 
                effects = { Happiness = 25 }, 
                setFlags = { centenarian = true }, 
                feedText = "Sometimes it's just luck!" 
            },
            { 
                text = "Healthy living all my life", 
                effects = { Happiness = 25, Health = 5 }, 
                setFlags = { centenarian = true, healthy_lifer = true }, 
                feedText = "Diet, exercise, no smoking... it paid off!" 
            },
            { 
                text = "A positive attitude", 
                effects = { Happiness = 30 }, 
                setFlags = { centenarian = true, positive_attitude = true }, 
                feedText = "Laughter and love are the best medicine!" 
            },
            { 
                text = "Honestly, no idea!", 
                effects = { Happiness = 20 }, 
                setFlags = { centenarian = true }, 
                feedText = "Still here and still confused about it!" 
            },
        },
    },
    
    -- ══════════════════════════════════════════════════════════════════════════════
    -- ADDITIONAL SENIOR EVENTS
    -- ══════════════════════════════════════════════════════════════════════════════
    {
        id = "scam_call",
        title = "Suspicious Phone Call",
        emoji = "📞",
        text = "You received a call claiming to be from the IRS demanding immediate payment in gift cards.",
        question = "What do you do?",
        minAge = 60, maxAge = 95,
        baseChance = 0.4,
        cooldown = 3,
        
        stage = STAGE,
        ageBand = "senior",
        category = "scam",
        tags = { "scam", "phone", "safety" },
        
        choices = {
            { 
                text = "Hang up immediately", 
                effects = { Happiness = 3, Smarts = 2 }, 
                setFlags = { scam_aware = true }, 
                feedText = "Good instincts! That was definitely a scam." 
            },
            { 
                text = "Ask family member for advice", 
                effects = { Happiness = 3 }, 
                feedText = "Your family confirmed it was a scam. Stay vigilant!" 
            },
            { 
                text = "Almost fell for it", 
                effects = { Happiness = -3, Smarts = 1 }, 
                setFlags = { vulnerable_to_scams = true }, 
                feedText = "You caught it just in time! Be more careful." 
            },
            { 
                text = "Fell for it and sent money",
                effects = {},
                feedText = "You went to buy gift cards...",
                onResolve = function(state)
                    local money = state.Money or 0
                    local lossAmount = math.min(2000, math.floor(money * 0.3))
                    state.Money = math.max(0, money - lossAmount)
                    state:ModifyStat("Happiness", -15)
                    state.Flags = state.Flags or {}
                    state.Flags.scam_victim = true
                    state:AddFeed(string.format("📞 Scammed out of $%d! Devastating and embarrassing.", lossAmount))
                end,
            },
        },
    },
    
    {
        id = "pet_companion_senior",
        title = "Furry Companion",
        emoji = "🐕",
        text = "You're thinking about getting a pet for companionship.",
        question = "What do you decide?",
        minAge = 60, maxAge = 85,
        oneTime = true,
        blockedByFlags = { assisted_living = true },
        
        stage = STAGE,
        ageBand = "senior",
        category = "pets",
        tags = { "pet", "companion", "loneliness" },
        
        choices = {
            { 
                text = "Get a cat - low maintenance", 
                effects = { Happiness = 10, Money = -200 }, 
                setFlags = { has_cat = true, has_pet_senior = true }, 
                feedText = "Your new cat is wonderful company!" 
            },
            { 
                text = "Get a small dog", 
                effects = { Happiness = 12, Health = 5, Money = -300 }, 
                setFlags = { has_dog = true, has_pet_senior = true }, 
                feedText = "Daily walks with your pup keep you active!" 
            },
            { 
                text = "Get a bird", 
                effects = { Happiness = 8, Money = -100 }, 
                setFlags = { has_bird = true, has_pet_senior = true }, 
                feedText = "Your bird's singing brightens every day!" 
            },
            { 
                text = "Too much responsibility", 
                effects = { Happiness = -2 }, 
                feedText = "Pets require too much care at this stage." 
            },
        },
    },
    
    {
        id = "volunteer_legacy",
        title = "Giving Back",
        emoji = "🤝",
        text = "You want to give back to the community in your retirement years.",
        question = "How do you volunteer?",
        minAge = 60, maxAge = 85,
        baseChance = 0.5,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior",
        category = "volunteering",
        tags = { "volunteer", "community", "purpose" },
        
        choices = {
            { 
                text = "Mentor young people", 
                effects = { Happiness = 10, Smarts = 3 }, 
                setFlags = { mentor = true }, 
                feedText = "Sharing your wisdom with the next generation!" 
            },
            { 
                text = "Meals on Wheels", 
                effects = { Happiness = 8, Health = 2 }, 
                setFlags = { meals_on_wheels_volunteer = true }, 
                feedText = "Delivering food and companionship to homebound seniors." 
            },
            { 
                text = "Hospital volunteer", 
                effects = { Happiness = 7 }, 
                setFlags = { hospital_volunteer = true }, 
                feedText = "Comforting patients makes a real difference." 
            },
            { 
                text = "Political/advocacy work", 
                effects = { Happiness = 6, Smarts = 4 }, 
                setFlags = { activist_senior = true }, 
                feedText = "Fighting for causes you believe in!" 
            },
            { 
                text = "Don't have the energy", 
                effects = { Happiness = -2 }, 
                feedText = "Volunteering requires more energy than you have." 
            },
        },
    },
    
    {
        id = "downsizing_home",
        title = "Downsizing",
        emoji = "🏠",
        text = "Your big house has too many memories and too many empty rooms. Time to downsize?",
        question = "What do you do?",
        minAge = 65, maxAge = 85,
        oneTime = true,
        requiresFlags = { homeowner = true },
        
        stage = STAGE,
        ageBand = "senior",
        category = "housing",
        tags = { "home", "downsizing", "moving" },
        
        choices = {
            { 
                text = "Sell and move to a smaller place", 
                effects = { Happiness = 3, Money = 50000 }, 
                setFlags = { downsized = true }, 
                feedText = "Less to maintain. Plus money from the sale!" 
            },
            { 
                text = "Move to a retirement community", 
                effects = { Happiness = 8, Money = 40000 }, 
                setFlags = { retirement_community = true }, 
                feedText = "Activities, amenities, and neighbors your age!" 
            },
            { 
                text = "Stay - too many memories here", 
                effects = { Happiness = 5, Money = -1000 }, 
                feedText = "This is home. You're not leaving." 
            },
            { 
                text = "Have family move in with you", 
                effects = { Happiness = 7 }, 
                setFlags = { multigenerational_home = true }, 
                feedText = "The house is full of life again!" 
            },
        },
    },
    
    {
        id = "medical_decisions",
        title = "Medical Decisions",
        emoji = "📋",
        text = "Your doctor wants to discuss advanced care directives and medical wishes.",
        question = "What are your wishes?",
        minAge = 65, maxAge = 95,
        oneTime = true,
        
        stage = STAGE,
        ageBand = "senior",
        category = "end_of_life",
        tags = { "medical", "directives", "planning" },
        
        choices = {
            { 
                text = "Full treatment - fight to the end", 
                effects = { Happiness = 2 }, 
                setFlags = { full_treatment = true, advance_directive = true }, 
                feedText = "You want every possible intervention." 
            },
            { 
                text = "DNR - comfort care only", 
                effects = { Happiness = 5 }, 
                setFlags = { dnr = true, comfort_care = true, advance_directive = true }, 
                feedText = "Quality over quantity. No heroic measures." 
            },
            { 
                text = "Let family decide when the time comes", 
                effects = { Happiness = 0 }, 
                feedText = "You trust your family to make the right call." 
            },
            { 
                text = "Too hard to think about", 
                effects = { Happiness = -3 }, 
                feedText = "You couldn't bring yourself to decide." 
            },
        },
    },
    
    {
        id = "hearing_loss",
        title = "What Did You Say?",
        emoji = "👂",
        text = "You're having trouble hearing conversations clearly. People keep telling you the TV is too loud.",
        question = "What do you do?",
        minAge = 65, maxAge = 95,
        baseChance = 0.5,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior",
        category = "health",
        tags = { "hearing", "aging", "disability" },
        
        choices = {
            { 
                text = "Get hearing aids", 
                effects = { Happiness = 8, Money = -3000 }, 
                setFlags = { wears_hearing_aids = true }, 
                feedText = "Wow! You can hear again! Should have done this sooner!" 
            },
            { 
                text = "Keep asking people to repeat", 
                effects = { Happiness = -5 }, 
                setFlags = { hearing_impaired = true }, 
                feedText = "WHAT? Could you say that again?" 
            },
            { 
                text = "Withdraw from social situations", 
                effects = { Happiness = -10 }, 
                setFlags = { hearing_impaired = true, socially_withdrawn = true }, 
                feedText = "It's easier to stay home than struggle to hear." 
            },
            { 
                text = "Learn to lip read", 
                effects = { Smarts = 5, Happiness = 3 }, 
                setFlags = { hearing_impaired = true, lip_reader = true }, 
                feedText = "You're adapting by watching lips and expressions!" 
            },
        },
    },
    
    {
        id = "vision_changes",
        title = "Vision Troubles",
        emoji = "👁️",
        text = "Your eyesight isn't what it used to be. Reading and driving are getting harder.",
        question = "How do you adapt?",
        minAge = 65, maxAge = 95,
        baseChance = 0.5,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior",
        category = "health",
        tags = { "vision", "aging", "disability" },
        
        choices = {
            { 
                text = "New glasses and regular checkups", 
                effects = { Happiness = 5, Money = -500 }, 
                setFlags = { vision_corrected = true }, 
                feedText = "Stronger prescription helps a lot!" 
            },
            { 
                text = "Large print books and audiobooks", 
                effects = { Happiness = 4 }, 
                setFlags = { low_vision = true, uses_audiobooks = true }, 
                feedText = "Adapting to read in new ways!" 
            },
            { 
                text = "Cataract surgery", 
                effects = { Happiness = 10, Health = 5, Money = -2000 }, 
                setFlags = { had_cataract_surgery = true }, 
                feedText = "The surgery was a miracle! Crystal clear vision!" 
            },
            { 
                text = "Just squint harder", 
                effects = { Happiness = -5, Health = -2 }, 
                setFlags = { vision_deteriorating = true }, 
                feedText = "The headaches are getting worse..." 
            },
        },
    },
    
    {
        id = "sleep_problems_senior",
        title = "Sleep Troubles",
        emoji = "😴",
        text = "You're having trouble sleeping through the night. Wide awake at 3 AM again.",
        question = "How do you handle the insomnia?",
        minAge = 60, maxAge = 95,
        baseChance = 0.5,
        cooldown = 3,
        
        stage = STAGE,
        ageBand = "senior",
        category = "health",
        tags = { "sleep", "health", "aging" },
        
        choices = {
            { 
                text = "Talk to doctor about sleep aids", 
                effects = { Health = 3, Happiness = 3, Money = -100 }, 
                setFlags = { takes_sleep_medication = true }, 
                feedText = "Medication helps you sleep through the night." 
            },
            { 
                text = "Accept the new sleep schedule", 
                effects = { Happiness = 2 }, 
                setFlags = { early_riser_senior = true }, 
                feedText = "Early to bed, earlier to rise. It's fine." 
            },
            { 
                text = "Spend sleepless hours worrying", 
                effects = { Health = -5, Happiness = -5 }, 
                setFlags = { anxiety_senior = true }, 
                feedText = "3 AM anxiety is no joke..." 
            },
            { 
                text = "Read or listen to podcasts", 
                effects = { Smarts = 3, Happiness = 2 }, 
                feedText = "Making productive use of sleepless hours!" 
            },
        },
    },
    
    {
        id = "estate_planning",
        title = "Getting Affairs in Order",
        emoji = "📜",
        text = "It's time to make sure your estate is properly planned.",
        question = "What arrangements do you make?",
        minAge = 65, maxAge = 95,
        oneTime = true,
        
        stage = STAGE,
        ageBand = "senior",
        category = "legal",
        tags = { "estate", "will", "planning" },
        
        choices = {
            { 
                text = "Hire an attorney for proper estate plan", 
                effects = { Happiness = 8, Money = -2000, Smarts = 2 }, 
                setFlags = { estate_planned = true, has_will = true }, 
                feedText = "Will, trust, power of attorney - all set up properly!" 
            },
            { 
                text = "DIY will from an online service", 
                effects = { Happiness = 3, Money = -100 }, 
                setFlags = { has_will = true }, 
                feedText = "Basic will in place. Better than nothing!" 
            },
            { 
                text = "Give away assets while still alive", 
                effects = { Happiness = 10, Money = -5000 }, 
                setFlags = { giving_inheritance_early = true }, 
                feedText = "Why wait? You get to see them enjoy it!" 
            },
            { 
                text = "Let the family figure it out", 
                effects = { Happiness = -3 }, 
                feedText = "Hopefully they won't fight over it..." 
            },
        },
    },
    
    {
        id = "technology_frustration",
        title = "Modern Technology",
        emoji = "📱",
        text = "Your phone updated and now nothing works the way it used to!",
        question = "How do you handle the tech frustration?",
        minAge = 60, maxAge = 95,
        baseChance = 0.5,
        cooldown = 2,
        
        stage = STAGE,
        ageBand = "senior",
        category = "technology",
        tags = { "technology", "frustration", "adaptation" },
        
        choices = {
            { 
                text = "Ask grandkids for help", 
                effects = { Happiness = 5 }, 
                feedText = "They fixed it in 30 seconds. Amazing." 
            },
            { 
                text = "Take a class at the library", 
                effects = { Smarts = 5, Happiness = 4 }, 
                setFlags = { learning_tech = true }, 
                feedText = "You're getting the hang of this!" 
            },
            { 
                text = "Give up and use an older device", 
                effects = { Happiness = -3 }, 
                setFlags = { tech_resistant = true }, 
                feedText = "The old phone worked fine!" 
            },
            { 
                text = "Throw the phone across the room", 
                effects = { Happiness = -2, Money = -200 }, 
                feedText = "That didn't help... and now you need a new phone." 
            },
        },
    },
    
    {
        id = "bucket_list_senior",
        title = "Bucket List Item",
        emoji = "📝",
        text = "You're checking something off your bucket list!",
        question = "What adventure are you having?",
        minAge = 60, maxAge = 90,
        baseChance = 0.4,
        cooldown = 3,
        blockedByFlags = { serious_health_issue = true, assisted_living = true },
        eligibility = function(state)
            return (state.Money or 0) >= 500
        end,
        
        stage = STAGE,
        ageBand = "senior",
        category = "adventure",
        tags = { "bucket_list", "adventure", "life_goals" },
        
        choices = {
            { 
                text = "See the Northern Lights", 
                effects = { Happiness = 15, Money = -3000 }, 
                setFlags = { saw_aurora = true, bucket_list_done = true }, 
                feedText = "Breathtaking! A sight you'll never forget!" 
            },
            { 
                text = "Learn to paint", 
                effects = { Happiness = 10, Smarts = 3, Money = -200 }, 
                setFlags = { learned_painting = true, bucket_list_done = true }, 
                feedText = "You created your first painting! Not bad!" 
            },
            { 
                text = "Reconnect with lost family", 
                effects = { Happiness = 12, Money = -500 }, 
                setFlags = { family_reconnected = true, bucket_list_done = true }, 
                feedText = "The reunion was emotional and wonderful." 
            },
            { 
                text = "Write your life story", 
                effects = { Happiness = 10, Smarts = 5 }, 
                setFlags = { wrote_memoir = true, bucket_list_done = true }, 
                feedText = "Your story is now preserved for generations!" 
            },
            { 
                text = "Skydiving!", 
                effects = {},
                setFlags = { bucket_list_done = true },
                feedText = "You're actually doing this...",
                onResolve = function(state)
                    local health = (state.Stats and state.Stats.Health) or 50
                    local roll = math.random()
                    if roll < 0.85 or health > 40 then
                        state:ModifyStat("Happiness", 20)
                        state.Money = (state.Money or 0) - 500
                        state.Flags = state.Flags or {}
                        state.Flags.went_skydiving = true
                        state:AddFeed("🪂 INCREDIBLE! You jumped out of a plane! What a rush!")
                    else
                        state:ModifyStat("Health", -5)
                        state:ModifyStat("Happiness", 5)
                        state.Money = (state.Money or 0) - 500
                        state:AddFeed("🪂 The landing was rough. But you did it!")
                    end
                end,
            },
        },
    },
    
    {
        id = "reflecting_on_life",
        title = "Life in Retrospect",
        emoji = "🪞",
        text = "You find yourself reflecting on your entire life journey.",
        question = "Overall, how do you feel about your life?",
        minAge = 70, maxAge = 100,
        oneTime = true,
        
        stage = STAGE,
        ageBand = "senior",
        category = "reflection",
        tags = { "legacy", "reflection", "meaning" },
        
        choices = {
            { 
                text = "Lived a full life with no regrets", 
                effects = { Happiness = 15 }, 
                setFlags = { life_fulfilled = true, no_regrets = true }, 
                feedText = "You did it all. Loved, lost, and lived fully." 
            },
            { 
                text = "Proud of family and relationships", 
                effects = { Happiness = 12 }, 
                setFlags = { life_fulfilled = true, relationship_focused = true }, 
                feedText = "The people you loved were the real treasure." 
            },
            { 
                text = "Regret some choices", 
                effects = { Happiness = -5, Smarts = 3 }, 
                setFlags = { has_regrets = true }, 
                feedText = "Some roads not taken haunt you still..." 
            },
            { 
                text = "Just grateful to still be here", 
                effects = { Happiness = 10 }, 
                setFlags = { grateful_for_life = true }, 
                feedText = "Every day above ground is a good day." 
            },
            { 
                text = "Wish I had done more", 
                effects = { Happiness = -8 }, 
                setFlags = { has_regrets = true, unfulfilled = true }, 
                feedText = "So many dreams left unrealized..." 
            },
        },
    },
}

return Senior
