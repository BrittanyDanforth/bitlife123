-- EventEngine.lua - Context-Aware Event System
-- Handles intelligent event selection based on player state, career, and traits

local EventEngine = {}

-- Data imports (will be required when integrated)
local CareerData = nil -- require(script.Parent.Parent.Data.CareerData)
local EventData = nil -- require(script.Parent.Parent.Data.EventData)
local TraitData = nil -- require(script.Parent.Parent.Data.TraitData)

--============================================================================
-- EVENT PRIORITY SYSTEM
--============================================================================
EventEngine.Priority = {
    CRITICAL = 1,   -- Must happen (death, major life events)
    HIGH = 2,       -- Very likely to happen
    NORMAL = 3,     -- Standard probability
    LOW = 4,        -- Rare events
    AMBIENT = 5     -- Flavor text, very low priority
}

--============================================================================
-- CONTEXT CATEGORIES
--============================================================================
EventEngine.Contexts = {
    "career",
    "education", 
    "relationship",
    "family",
    "health",
    "financial",
    "legal",
    "social",
    "random"
}

--============================================================================
-- MAIN EVENT SELECTION
--============================================================================

-- Get the most appropriate event for the current situation
function EventEngine.GetEvent(playerState, contextHint)
    -- Collect all possible events with their weighted scores
    local candidateEvents = {}
    
    -- 1. Check for critical/forced events first
    local criticalEvent = EventEngine.CheckCriticalEvents(playerState)
    if criticalEvent then
        return criticalEvent
    end
    
    -- 2. Get career-specific events if employed
    if playerState.career and playerState.career.currentJob then
        local careerEvents = EventEngine.GetCareerEvents(playerState)
        for _, event in ipairs(careerEvents) do
            table.insert(candidateEvents, {
                event = event,
                score = EventEngine.ScoreEvent(event, playerState, "career"),
                source = "career"
            })
        end
    end
    
    -- 3. Get education events if enrolled
    if playerState.education and playerState.education.currentEnrollment then
        local eduEvents = EventEngine.GetEducationEvents(playerState)
        for _, event in ipairs(eduEvents) do
            table.insert(candidateEvents, {
                event = event,
                score = EventEngine.ScoreEvent(event, playerState, "education"),
                source = "education"
            })
        end
    end
    
    -- 4. Get relationship events if applicable
    local relationEvents = EventEngine.GetRelationshipEvents(playerState)
    for _, event in ipairs(relationEvents) do
        table.insert(candidateEvents, {
            event = event,
            score = EventEngine.ScoreEvent(event, playerState, "relationship"),
            source = "relationship"
        })
    end
    
    -- 5. Get age-appropriate life events
    local lifeEvents = EventEngine.GetLifeEvents(playerState)
    for _, event in ipairs(lifeEvents) do
        table.insert(candidateEvents, {
            event = event,
            score = EventEngine.ScoreEvent(event, playerState, "life"),
            source = "life"
        })
    end
    
    -- 6. Get random events
    local randomEvents = EventEngine.GetRandomEvents(playerState)
    for _, event in ipairs(randomEvents) do
        table.insert(candidateEvents, {
            event = event,
            score = EventEngine.ScoreEvent(event, playerState, "random"),
            source = "random"
        })
    end
    
    -- Select event based on weighted random selection
    return EventEngine.SelectWeightedEvent(candidateEvents, contextHint)
end

--============================================================================
-- CRITICAL EVENT CHECKING
--============================================================================

-- Check for events that MUST happen
function EventEngine.CheckCriticalEvents(playerState)
    -- Death check
    if playerState.health and playerState.health <= 0 then
        return {
            id = "player_death",
            name = "The End",
            description = "Your health has failed...",
            priority = EventEngine.Priority.CRITICAL,
            choices = {{text = "Accept fate", outcomes = {{probability = 1, result = "death", description = "Your life has ended.", effects = {death = true}}}}}
        }
    end
    
    -- Prison release check
    if playerState.legal and playerState.legal.inPrison then
        if playerState.legal.prisonYearsServed >= playerState.legal.prisonSentence then
            return {
                id = "prison_release",
                name = "Freedom!",
                description = "You've served your sentence. You're being released!",
                priority = EventEngine.Priority.CRITICAL,
                choices = {{text = "Walk out a free person", outcomes = {{probability = 1, result = "released", description = "You're finally free!", effects = {release = true}}}}}
            }
        end
    end
    
    -- Mandatory education events
    if playerState.age == 5 then
        return {
            id = "start_school",
            name = "First Day of School",
            description = "Today is your first day of school!",
            priority = EventEngine.Priority.CRITICAL,
            choices = {{text = "Go to school", outcomes = {{probability = 1, result = "enrolled", description = "You start elementary school!", effects = {education = "Elementary"}}}}}
        }
    end
    
    if playerState.age == 18 and playerState.education.level == "High School" then
        return {
            id = "graduation_hs",
            name = "High School Graduation",
            description = "Congratulations! You're graduating from high school!",
            priority = EventEngine.Priority.CRITICAL,
            choices = {{text = "Accept your diploma", outcomes = {{probability = 1, result = "graduated", description = "You graduated high school!", effects = {graduation = "High School"}}}}}
        }
    end
    
    return nil
end

--============================================================================
-- CAREER EVENT SYSTEM
--============================================================================

-- Get career-specific events
function EventEngine.GetCareerEvents(playerState)
    local events = {}
    
    if not playerState.career or not playerState.career.currentJob then
        return events
    end
    
    local jobTitle = playerState.career.currentJob
    local yearsInJob = playerState.career.yearsInJob or 0
    local performance = playerState.career.performance or 50
    
    -- Get job data from CareerData
    if CareerData and CareerData.Jobs then
        local jobData = CareerData.Jobs[jobTitle]
        if jobData and jobData.careerEvents then
            for _, event in ipairs(jobData.careerEvents) do
                -- Check eligibility
                if EventEngine.IsCareerEventEligible(event, playerState, yearsInJob, performance) then
                    -- Apply career-specific context
                    local contextualizedEvent = EventEngine.ContextualizeCareerEvent(event, jobData, playerState)
                    table.insert(events, contextualizedEvent)
                end
            end
        end
        
        -- Add generic work events
        local genericEvents = EventEngine.GetGenericWorkEvents(playerState, jobData)
        for _, event in ipairs(genericEvents) do
            table.insert(events, event)
        end
    end
    
    return events
end

-- Check if career event is eligible
function EventEngine.IsCareerEventEligible(event, playerState, yearsInJob, performance)
    -- Minimum years check
    if event.minYearsInJob and yearsInJob < event.minYearsInJob then
        return false
    end
    
    -- Performance requirement
    if event.requiresPerformance and performance < event.requiresPerformance then
        return false
    end
    
    -- Probability check (but don't eliminate, just for scoring)
    return true
end

-- Add context to career event
function EventEngine.ContextualizeCareerEvent(event, jobData, playerState)
    -- Clone event to avoid modifying original
    local contextEvent = EventEngine.CloneEvent(event)
    
    -- Add job-specific details to description
    contextEvent.jobTitle = jobData.title
    contextEvent.category = jobData.category
    contextEvent.source = "career"
    
    return contextEvent
end

-- Generic work events applicable to any job
function EventEngine.GetGenericWorkEvents(playerState, jobData)
    local events = {}
    
    -- Raise request (if employed > 1 year)
    if playerState.career.yearsInJob >= 1 then
        table.insert(events, {
            id = "work_raise_request",
            name = "Time for a Raise?",
            description = "You've been working hard. Maybe it's time to ask for a raise.",
            probability = 0.08,
            source = "career",
            choices = {
                {
                    text = "Ask for a raise",
                    outcomes = {
                        {probability = 0.4, result = "approved", description = "Your boss agrees! 5% raise!", effects = {salaryIncrease = 0.05}},
                        {probability = 0.4, result = "denied", description = "Not in the budget right now.", effects = {happiness = -5}},
                        {probability = 0.2, result = "later", description = "They'll consider it at review time.", effects = {}}
                    }
                },
                {
                    text = "Not right now",
                    outcomes = {
                        {probability = 1, result = "wait", description = "Maybe next time.", effects = {}}
                    }
                }
            }
        })
    end
    
    -- Consider quitting
    if playerState.career.yearsInJob >= 0.5 then
        table.insert(events, {
            id = "work_consider_quit",
            name = "Career Crossroads",
            description = "You find yourself wondering if this job is right for you.",
            probability = 0.05,
            source = "career",
            choices = {
                {
                    text = "Quit and look for something new",
                    outcomes = {
                        {probability = 0.5, result = "quit", description = "You quit! Time for something new.", effects = {quit = true}},
                        {probability = 0.5, result = "quit_hard", description = "You quit. Job hunting is tough though.", effects = {quit = true, stress = 10}}
                    }
                },
                {
                    text = "Stay - the grass isn't always greener",
                    outcomes = {
                        {probability = 0.7, result = "stay", description = "You decide to stick with it.", effects = {}},
                        {probability = 0.3, result = "stay_content", description = "Good choice. You're happy here.", effects = {happiness = 5}}
                    }
                }
            }
        })
    end
    
    return events
end

--============================================================================
-- RELATIONSHIP EVENTS
--============================================================================

-- Get relationship events based on current status
function EventEngine.GetRelationshipEvents(playerState)
    local events = {}
    local age = playerState.age or 0
    
    -- Single events
    if not playerState.relationships.partner then
        if age >= 16 then
            table.insert(events, {
                id = "meet_someone",
                name = "Someone Catches Your Eye",
                description = "You notice someone attractive in your daily life.",
                probability = 0.12,
                source = "relationship",
                choices = {
                    {
                        text = "Approach them",
                        outcomes = {
                            {probability = 0.4, result = "date", description = "They're interested! You exchange numbers!", effects = {newRelationship = true, happiness = 20}},
                            {probability = 0.4, result = "rejected", description = "They're not interested.", effects = {happiness = -5}},
                            {probability = 0.2, result = "awkward", description = "It's awkward. They have a partner.", effects = {}}
                        }
                    },
                    {
                        text = "Admire from afar",
                        outcomes = {
                            {probability = 0.8, result = "nothing", description = "The moment passes.", effects = {}},
                            {probability = 0.2, result = "approach_you", description = "They approach YOU instead!", effects = {newRelationship = true, happiness = 25}}
                        }
                    }
                }
            })
        end
    else
        -- Partner events
        local partner = playerState.relationships.partner
        local relationshipQuality = partner.relationshipQuality or 50
        
        -- Good relationship events
        if relationshipQuality >= 70 then
            table.insert(events, {
                id = "relationship_milestone",
                name = "Special Moment",
                description = "You and " .. (partner.name or "your partner") .. " share a beautiful moment together.",
                probability = 0.10,
                source = "relationship",
                choices = {
                    {
                        text = "Cherish it",
                        outcomes = {
                            {probability = 1, result = "happy", description = "Moments like these make life worth living.", effects = {happiness = 15, relationshipBonus = 5}}
                        }
                    }
                }
            })
        end
        
        -- Rocky relationship events
        if relationshipQuality < 40 then
            table.insert(events, {
                id = "relationship_trouble",
                name = "Relationship Problems",
                description = "Things with " .. (partner.name or "your partner") .. " have been rocky lately.",
                probability = 0.15,
                source = "relationship",
                choices = {
                    {
                        text = "Talk it out",
                        outcomes = {
                            {probability = 0.5, result = "improved", description = "Communication helps! Things improve.", effects = {relationshipBonus = 10}},
                            {probability = 0.5, result = "fight", description = "The talk turns into a fight.", effects = {relationshipBonus = -10, happiness = -10}}
                        }
                    },
                    {
                        text = "Give space",
                        outcomes = {
                            {probability = 0.4, result = "helped", description = "Space was needed. Things settle.", effects = {}},
                            {probability = 0.6, result = "distance", description = "The distance grows...", effects = {relationshipBonus = -5}}
                        }
                    },
                    {
                        text = "End the relationship",
                        outcomes = {
                            {probability = 0.6, result = "breakup", description = "It's over. Time to move on.", effects = {breakup = true, happiness = -20}},
                            {probability = 0.4, result = "reconsider", description = "On second thought, maybe there's still hope.", effects = {}}
                        }
                    }
                }
            })
        end
    end
    
    return events
end

--============================================================================
-- EDUCATION EVENTS
--============================================================================

function EventEngine.GetEducationEvents(playerState)
    local events = {}
    
    if not playerState.education or not playerState.education.currentEnrollment then
        return events
    end
    
    local enrollment = playerState.education.currentEnrollment
    local gpa = playerState.education.gpa or 3.0
    
    -- Study events
    table.insert(events, {
        id = "study_session",
        name = "Study Time",
        description = "You have a big exam coming up!",
        probability = 0.15,
        source = "education",
        choices = {
            {
                text = "Study hard",
                outcomes = {
                    {probability = 0.7, result = "good_grade", description = "Your studying paid off! Good grade!", effects = {gpaBonus = 0.1, smarts = 1}},
                    {probability = 0.3, result = "average", description = "Average score. Could be better.", effects = {}}
                }
            },
            {
                text = "Cram the night before",
                outcomes = {
                    {probability = 0.4, result = "pass", description = "Somehow you passed!", effects = {}},
                    {probability = 0.6, result = "fail", description = "Cramming didn't work. Failed.", effects = {gpaBonus = -0.2, happiness = -10}}
                }
            },
            {
                text = "Wing it",
                outcomes = {
                    {probability = 0.2, result = "lucky", description = "Guessed right on most questions!", effects = {}},
                    {probability = 0.8, result = "disaster", description = "Complete disaster. F.", effects = {gpaBonus = -0.3, happiness = -15}}
                }
            }
        }
    })
    
    -- Social education events
    table.insert(events, {
        id = "school_social",
        name = "Campus Life",
        description = "There's a campus event tonight!",
        probability = 0.10,
        source = "education",
        choices = {
            {
                text = "Go and have fun",
                outcomes = {
                    {probability = 0.6, result = "fun", description = "Great time! Made some friends!", effects = {happiness = 15, social = 1}},
                    {probability = 0.3, result = "ok", description = "It was alright.", effects = {happiness = 5}},
                    {probability = 0.1, result = "wild", description = "Things got WILD.", effects = {happiness = 20, karma = -5}}
                }
            },
            {
                text = "Stay in and study",
                outcomes = {
                    {probability = 0.7, result = "productive", description = "Productive night!", effects = {smarts = 1, gpaBonus = 0.05}},
                    {probability = 0.3, result = "fomo", description = "You can hear them having fun. FOMO.", effects = {happiness = -5}}
                }
            }
        }
    })
    
    return events
end

--============================================================================
-- LIFE EVENTS
--============================================================================

function EventEngine.GetLifeEvents(playerState)
    local events = {}
    local age = playerState.age or 0
    
    if EventData and EventData.Events then
        for _, event in pairs(EventData.Events) do
            if EventEngine.IsLifeEventEligible(event, playerState) then
                table.insert(events, event)
            end
        end
    end
    
    return events
end

function EventEngine.IsLifeEventEligible(event, playerState)
    local age = playerState.age or 0
    
    -- Age range check
    if event.ageRange then
        if age < event.ageRange[1] or age > event.ageRange[2] then
            return false
        end
    end
    
    -- Check other requirements
    if event.requiresPartner and not playerState.relationships.partner then
        return false
    end
    
    if event.requiresJob and not playerState.career.currentJob then
        return false
    end
    
    if event.minMoney and (playerState.money or 0) < event.minMoney then
        return false
    end
    
    return true
end

--============================================================================
-- RANDOM EVENTS
--============================================================================

function EventEngine.GetRandomEvents(playerState)
    local events = {}
    
    -- These are always possible regardless of context
    
    -- Finding money
    table.insert(events, {
        id = "found_money",
        name = "Lucky Find",
        description = "You found some money on the ground!",
        probability = 0.03,
        source = "random",
        choices = {
            {
                text = "Keep it",
                outcomes = {
                    {probability = 0.7, result = "small", description = "It's $20. Nice!", effects = {money = 20}},
                    {probability = 0.25, result = "medium", description = "It's $100! Lucky day!", effects = {money = 100, happiness = 5}},
                    {probability = 0.05, result = "large", description = "It's $500! Amazing!", effects = {money = 500, happiness = 15}}
                }
            },
            {
                text = "Turn it in to lost and found",
                outcomes = {
                    {probability = 0.3, result = "returned", description = "The owner thanks you!", effects = {karma = 10}},
                    {probability = 0.7, result = "unclaimed", description = "No one claims it. Good karma though!", effects = {karma = 5}}
                }
            }
        }
    })
    
    -- Random illness
    if playerState.age >= 5 then
        table.insert(events, {
            id = "random_sick",
            name = "Feeling Ill",
            description = "You're not feeling well today...",
            probability = 0.08,
            source = "random",
            choices = {
                {
                    text = "Rest and take medicine",
                    outcomes = {
                        {probability = 0.8, result = "recovered", description = "A few days rest and you're better!", effects = {health = -5}},
                        {probability = 0.2, result = "worse", description = "It's worse than you thought. Doctor time.", effects = {health = -15, money = -100}}
                    }
                },
                {
                    text = "Push through it",
                    outcomes = {
                        {probability = 0.4, result = "fine", description = "Mind over matter. You're fine.", effects = {health = -3}},
                        {probability = 0.6, result = "collapsed", description = "Bad idea. You collapsed.", effects = {health = -20}}
                    }
                }
            }
        })
    end
    
    return events
end

--============================================================================
-- EVENT SCORING AND SELECTION
--============================================================================

-- Score an event based on relevance and probability
function EventEngine.ScoreEvent(event, playerState, context)
    local score = 100 -- Base score
    
    -- Apply probability
    local probability = event.probability or 0.10
    score = score * probability
    
    -- Context bonus (career events more likely when working, etc.)
    if context == "career" and playerState.career.currentJob then
        score = score * 1.5
    end
    
    if context == "education" and playerState.education.currentEnrollment then
        score = score * 1.5
    end
    
    -- Trait modifiers
    if event.traitModifiers and playerState.traits then
        for _, traitId in ipairs(playerState.traits) do
            if event.traitModifiers[traitId] then
                score = score * event.traitModifiers[traitId]
            end
        end
    end
    
    -- Recency penalty (don't repeat events too often)
    if playerState.eventHistory and playerState.eventHistory[event.id] then
        local lastOccurrence = playerState.eventHistory[event.id]
        local yearsSince = playerState.age - lastOccurrence
        if yearsSince < 2 then
            score = score * 0.2 -- Heavy penalty for recent events
        elseif yearsSince < 5 then
            score = score * 0.5
        end
    end
    
    -- Priority modifier
    local priority = event.priority or EventEngine.Priority.NORMAL
    if priority == EventEngine.Priority.CRITICAL then
        score = score * 10
    elseif priority == EventEngine.Priority.HIGH then
        score = score * 3
    elseif priority == EventEngine.Priority.LOW then
        score = score * 0.5
    elseif priority == EventEngine.Priority.AMBIENT then
        score = score * 0.2
    end
    
    return score
end

-- Select event using weighted random selection
function EventEngine.SelectWeightedEvent(candidates, contextHint)
    if #candidates == 0 then return nil end
    
    -- Apply context hint bonus
    if contextHint then
        for _, candidate in ipairs(candidates) do
            if candidate.source == contextHint then
                candidate.score = candidate.score * 1.5
            end
        end
    end
    
    -- Calculate total score
    local totalScore = 0
    for _, candidate in ipairs(candidates) do
        totalScore = totalScore + candidate.score
    end
    
    -- Random selection
    local roll = math.random() * totalScore
    local cumulative = 0
    
    for _, candidate in ipairs(candidates) do
        cumulative = cumulative + candidate.score
        if roll <= cumulative then
            return candidate.event
        end
    end
    
    -- Fallback
    return candidates[#candidates].event
end

--============================================================================
-- UTILITY FUNCTIONS
--============================================================================

-- Clone an event table
function EventEngine.CloneEvent(event)
    local clone = {}
    for k, v in pairs(event) do
        if type(v) == "table" then
            clone[k] = EventEngine.CloneEvent(v)
        else
            clone[k] = v
        end
    end
    return clone
end

-- Process event choice and get outcome
function EventEngine.ProcessChoice(event, choiceIndex)
    local choice = event.choices[choiceIndex]
    if not choice then return nil end
    
    local roll = math.random()
    local cumulative = 0
    
    for _, outcome in ipairs(choice.outcomes) do
        cumulative = cumulative + outcome.probability
        if roll <= cumulative then
            return outcome
        end
    end
    
    return choice.outcomes[#choice.outcomes]
end

-- Get flavor text for work day (no event)
function EventEngine.GetWorkDayFlavor(playerState)
    if not playerState.career or not playerState.career.currentJob then
        return "Another day passes."
    end
    
    if CareerData and CareerData.Jobs then
        local jobData = CareerData.Jobs[playerState.career.currentJob]
        if jobData and jobData.workDayEvents then
            return jobData.workDayEvents[math.random(#jobData.workDayEvents)]
        end
    end
    
    return "You worked today."
end

return EventEngine
