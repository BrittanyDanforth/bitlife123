-- TraitData.lua - Personality Traits System
-- Traits affect events, relationships, career success, and life outcomes

local TraitData = {}

--============================================================================
-- TRAIT CATEGORIES
--============================================================================
TraitData.Categories = {
    "Personality",
    "Intelligence",
    "Physical",
    "Social",
    "Mental",
    "Moral",
    "Special"
}

--============================================================================
-- ALL TRAITS
--============================================================================
TraitData.Traits = {
    --========================================
    -- PERSONALITY TRAITS
    --========================================
    Ambitious = {
        id = "ambitious",
        name = "Ambitious",
        category = "Personality",
        description = "Driven to succeed at all costs",
        rarity = "common",
        effects = {
            promotionChance = 0.15,
            salaryBonus = 0.10,
            stress = 0.10,
            workPerformance = 0.15
        },
        eventModifiers = {
            career_promotion = 1.5,
            career_opportunity = 1.3
        },
        conflictsWith = {"Lazy", "Content"},
        inheritChance = 0.20
    },
    
    Lazy = {
        id = "lazy",
        name = "Lazy",
        category = "Personality",
        description = "Prefers the path of least resistance",
        rarity = "common",
        effects = {
            promotionChance = -0.20,
            workPerformance = -0.20,
            stress = -0.15,
            happiness = 0.05
        },
        eventModifiers = {
            career_fired = 1.5,
            career_warning = 1.4
        },
        conflictsWith = {"Ambitious", "Workaholic"},
        inheritChance = 0.15
    },
    
    Charismatic = {
        id = "charismatic",
        name = "Charismatic",
        category = "Social",
        description = "Natural charm that draws people in",
        rarity = "uncommon",
        effects = {
            socialSuccess = 0.25,
            relationshipBonus = 0.20,
            negotiationBonus = 0.15,
            fameGain = 0.10
        },
        eventModifiers = {
            romance_success = 1.4,
            interview_success = 1.3,
            social_event = 1.2
        },
        conflictsWith = {"Awkward", "Shy"},
        inheritChance = 0.15
    },
    
    Shy = {
        id = "shy",
        name = "Shy",
        category = "Social",
        description = "Uncomfortable in social situations",
        rarity = "common",
        effects = {
            socialSuccess = -0.15,
            stress = 0.05,
            focusBonus = 0.10
        },
        eventModifiers = {
            romance_failure = 1.3,
            public_speaking = 0.6
        },
        conflictsWith = {"Charismatic", "Outgoing"},
        inheritChance = 0.20
    },
    
    Intelligent = {
        id = "intelligent",
        name = "Intelligent",
        category = "Intelligence",
        description = "Quick learner with high cognitive abilities",
        rarity = "uncommon",
        effects = {
            studyEfficiency = 0.30,
            skillGainBonus = 0.20,
            problemSolvingBonus = 0.25,
            examBonus = 0.20
        },
        eventModifiers = {
            education_success = 1.4,
            puzzle_solving = 1.5,
            research_breakthrough = 1.3
        },
        conflictsWith = {},
        inheritChance = 0.25
    },
    
    Stupid = {
        id = "stupid",
        name = "Slow Learner",
        category = "Intelligence",
        description = "Struggles with complex concepts",
        rarity = "uncommon",
        effects = {
            studyEfficiency = -0.30,
            skillGainBonus = -0.20,
            examBonus = -0.25
        },
        eventModifiers = {
            education_failure = 1.5,
            scam_victim = 1.4
        },
        conflictsWith = {"Intelligent", "Genius"},
        inheritChance = 0.15
    },
    
    Athletic = {
        id = "athletic",
        name = "Athletic",
        category = "Physical",
        description = "Natural physical abilities",
        rarity = "uncommon",
        effects = {
            healthBonus = 0.15,
            physicalSkillGain = 0.25,
            sportsSuccess = 0.30,
            attractiveness = 0.10
        },
        eventModifiers = {
            sports_tryout = 1.5,
            physical_challenge = 1.4,
            fight_success = 1.3
        },
        conflictsWith = {"Weak", "Obese"},
        inheritChance = 0.20
    },
    
    Weak = {
        id = "weak",
        name = "Weak",
        category = "Physical",
        description = "Below average physical strength",
        rarity = "common",
        effects = {
            healthBonus = -0.10,
            physicalSkillGain = -0.20,
            sportsSuccess = -0.30
        },
        eventModifiers = {
            fight_failure = 1.5,
            physical_challenge = 0.6
        },
        conflictsWith = {"Athletic", "Strong"},
        inheritChance = 0.15
    },
    
    Attractive = {
        id = "attractive",
        name = "Attractive",
        category = "Physical",
        description = "Blessed with good looks",
        rarity = "uncommon",
        effects = {
            socialSuccess = 0.15,
            romanceSuccess = 0.30,
            fameGain = 0.15,
            modelingSuccess = 0.50
        },
        eventModifiers = {
            romance_opportunity = 1.5,
            modeling_career = 2.0,
            first_impression = 1.3
        },
        conflictsWith = {"Ugly"},
        inheritChance = 0.30
    },
    
    Ugly = {
        id = "ugly",
        name = "Ugly",
        category = "Physical",
        description = "Below average appearance",
        rarity = "uncommon",
        effects = {
            socialSuccess = -0.10,
            romanceSuccess = -0.20,
            modelingSuccess = -0.80
        },
        eventModifiers = {
            romance_rejection = 1.3,
            bullying = 1.4
        },
        conflictsWith = {"Attractive"},
        inheritChance = 0.25
    },
    
    Kind = {
        id = "kind",
        name = "Kind",
        category = "Moral",
        description = "Genuinely cares about others",
        rarity = "common",
        effects = {
            karmaGain = 0.20,
            relationshipBonus = 0.15,
            crimeSuccess = -0.20
        },
        eventModifiers = {
            charity_event = 1.5,
            helping_stranger = 1.4,
            friendship_success = 1.3
        },
        conflictsWith = {"Cruel", "Psychopath"},
        inheritChance = 0.25
    },
    
    Cruel = {
        id = "cruel",
        name = "Cruel",
        category = "Moral",
        description = "Takes pleasure in others' suffering",
        rarity = "rare",
        effects = {
            karmaGain = -0.30,
            intimidationBonus = 0.25,
            crimeSuccess = 0.15,
            relationshipBonus = -0.20
        },
        eventModifiers = {
            crime_opportunity = 1.4,
            bullying_others = 1.5,
            breakup_cause = 1.4
        },
        conflictsWith = {"Kind", "Empathetic"},
        inheritChance = 0.10
    },
    
    Honest = {
        id = "honest",
        name = "Honest",
        category = "Moral",
        description = "Tells the truth even when difficult",
        rarity = "common",
        effects = {
            trustBonus = 0.25,
            karmaGain = 0.15,
            crimeSuccess = -0.30,
            negotiationBonus = 0.10
        },
        eventModifiers = {
            caught_lying = 0.5,
            trust_earned = 1.5
        },
        conflictsWith = {"Liar", "Manipulative"},
        inheritChance = 0.20
    },
    
    Liar = {
        id = "liar",
        name = "Compulsive Liar",
        category = "Moral",
        description = "Lies even when unnecessary",
        rarity = "uncommon",
        effects = {
            trustBonus = -0.30,
            manipulationBonus = 0.20,
            crimeSuccess = 0.15,
            karmaGain = -0.15
        },
        eventModifiers = {
            caught_lying = 1.5,
            deception_success = 1.3
        },
        conflictsWith = {"Honest"},
        inheritChance = 0.15
    },
    
    Brave = {
        id = "brave",
        name = "Brave",
        category = "Personality",
        description = "Faces danger without fear",
        rarity = "uncommon",
        effects = {
            fightSuccess = 0.20,
            heroicAction = 0.30,
            militaryBonus = 0.25,
            stress = -0.10
        },
        eventModifiers = {
            emergency_response = 1.5,
            confrontation_success = 1.4,
            heroic_opportunity = 1.5
        },
        conflictsWith = {"Coward"},
        inheritChance = 0.15
    },
    
    Coward = {
        id = "coward",
        name = "Cowardly",
        category = "Personality",
        description = "Avoids confrontation at all costs",
        rarity = "common",
        effects = {
            fightSuccess = -0.30,
            fleeSuccess = 0.30,
            stress = 0.15
        },
        eventModifiers = {
            confrontation_flee = 1.5,
            standing_up = 0.5
        },
        conflictsWith = {"Brave", "Fearless"},
        inheritChance = 0.15
    },
    
    Lucky = {
        id = "lucky",
        name = "Lucky",
        category = "Special",
        description = "Fortune seems to favor you",
        rarity = "rare",
        effects = {
            gamblingBonus = 0.20,
            randomEventBonus = 0.15,
            accidentChance = -0.20,
            lotteryChance = 0.50
        },
        eventModifiers = {
            random_windfall = 2.0,
            accident_avoidance = 1.5,
            lucky_break = 2.0
        },
        conflictsWith = {"Unlucky"},
        inheritChance = 0.05
    },
    
    Unlucky = {
        id = "unlucky",
        name = "Unlucky",
        category = "Special",
        description = "Bad things seem to follow you",
        rarity = "uncommon",
        effects = {
            gamblingBonus = -0.20,
            accidentChance = 0.25,
            randomEventPenalty = 0.15
        },
        eventModifiers = {
            random_misfortune = 1.5,
            accident = 1.4,
            illness = 1.2
        },
        conflictsWith = {"Lucky"},
        inheritChance = 0.10
    },
    
    --========================================
    -- MENTAL TRAITS
    --========================================
    Anxious = {
        id = "anxious",
        name = "Anxious",
        category = "Mental",
        description = "Constant worry and unease",
        rarity = "common",
        effects = {
            stress = 0.25,
            happiness = -0.10,
            focusBonus = -0.15,
            socialSuccess = -0.10
        },
        eventModifiers = {
            panic_attack = 1.5,
            social_anxiety = 1.4,
            overthinking = 1.3
        },
        conflictsWith = {"Calm", "Confident"},
        canDevelop = true,
        developmentTriggers = {"trauma", "stress", "failure"},
        inheritChance = 0.25
    },
    
    Calm = {
        id = "calm",
        name = "Calm",
        category = "Mental",
        description = "Maintains composure under pressure",
        rarity = "uncommon",
        effects = {
            stress = -0.20,
            crisisPerformance = 0.25,
            negotiationBonus = 0.15
        },
        eventModifiers = {
            emergency_response = 1.3,
            keeping_cool = 1.5,
            meditation_success = 1.4
        },
        conflictsWith = {"Anxious", "HotHeaded"},
        inheritChance = 0.15
    },
    
    Depressed = {
        id = "depressed",
        name = "Depressed",
        category = "Mental",
        description = "Persistent feelings of sadness",
        rarity = "uncommon",
        effects = {
            happiness = -0.30,
            motivation = -0.25,
            healthBonus = -0.10,
            socialSuccess = -0.15
        },
        eventModifiers = {
            breakdown = 1.5,
            isolation = 1.4,
            recovery = 0.7
        },
        conflictsWith = {},
        canDevelop = true,
        canHeal = true,
        developmentTriggers = {"loss", "trauma", "loneliness", "failure"},
        inheritChance = 0.20
    },
    
    Confident = {
        id = "confident",
        name = "Confident",
        category = "Mental",
        description = "Strong belief in oneself",
        rarity = "uncommon",
        effects = {
            interviewBonus = 0.25,
            socialSuccess = 0.15,
            negotiationBonus = 0.20,
            publicSpeaking = 0.30
        },
        eventModifiers = {
            presentation_success = 1.4,
            standing_up = 1.3,
            first_impression = 1.3
        },
        conflictsWith = {"Insecure", "Anxious"},
        inheritChance = 0.15
    },
    
    Insecure = {
        id = "insecure",
        name = "Insecure",
        category = "Mental",
        description = "Doubts own worth and abilities",
        rarity = "common",
        effects = {
            interviewBonus = -0.15,
            socialSuccess = -0.10,
            jealousyChance = 0.25,
            relationshipStability = -0.15
        },
        eventModifiers = {
            jealousy_event = 1.5,
            self_sabotage = 1.4,
            seeking_validation = 1.3
        },
        conflictsWith = {"Confident"},
        canDevelop = true,
        developmentTriggers = {"rejection", "failure", "bullying"},
        inheritChance = 0.20
    },
    
    --========================================
    -- SPECIAL/RARE TRAITS
    --========================================
    Genius = {
        id = "genius",
        name = "Genius",
        category = "Intelligence",
        description = "Exceptional intellectual abilities",
        rarity = "legendary",
        effects = {
            studyEfficiency = 0.50,
            skillGainBonus = 0.40,
            problemSolvingBonus = 0.50,
            researchBonus = 0.40,
            examBonus = 0.40
        },
        eventModifiers = {
            breakthrough = 2.0,
            scholarship = 2.0,
            invention = 2.0
        },
        conflictsWith = {"Stupid"},
        inheritChance = 0.05
    },
    
    Psychopath = {
        id = "psychopath",
        name = "Psychopath",
        category = "Mental",
        description = "Lacks empathy and remorse",
        rarity = "rare",
        effects = {
            empathy = -1.0,
            manipulationBonus = 0.40,
            crimeSuccess = 0.30,
            karmaGain = -0.50,
            stress = -0.20
        },
        eventModifiers = {
            crime_opportunity = 1.5,
            manipulation_success = 1.5,
            guilt = 0.1
        },
        conflictsWith = {"Kind", "Empathetic"},
        inheritChance = 0.03
    },
    
    Empathetic = {
        id = "empathetic",
        name = "Empathetic",
        category = "Social",
        description = "Deeply feels others' emotions",
        rarity = "uncommon",
        effects = {
            empathy = 0.50,
            relationshipBonus = 0.25,
            counselingBonus = 0.30,
            karmaGain = 0.15
        },
        eventModifiers = {
            helping_others = 1.5,
            emotional_support = 1.4,
            understanding_motives = 1.3
        },
        conflictsWith = {"Psychopath", "Cruel"},
        inheritChance = 0.15
    },
    
    Workaholic = {
        id = "workaholic",
        name = "Workaholic",
        category = "Personality",
        description = "Obsessed with work above all else",
        rarity = "uncommon",
        effects = {
            workPerformance = 0.30,
            promotionChance = 0.25,
            salaryBonus = 0.15,
            stress = 0.25,
            relationshipBonus = -0.20,
            healthBonus = -0.10
        },
        eventModifiers = {
            overtime_opportunity = 1.5,
            burnout = 1.5,
            career_success = 1.4
        },
        conflictsWith = {"Lazy"},
        canDevelop = true,
        inheritChance = 0.10
    },
    
    Addictive = {
        id = "addictive",
        name = "Addictive Personality",
        category = "Mental",
        description = "Prone to developing addictions",
        rarity = "uncommon",
        effects = {
            addictionChance = 0.40,
            gamblingRisk = 0.30,
            drinkingRisk = 0.30,
            drugRisk = 0.40
        },
        eventModifiers = {
            addiction_event = 1.5,
            relapse = 1.4,
            substance_temptation = 1.5
        },
        conflictsWith = {},
        inheritChance = 0.25
    },
    
    Fertile = {
        id = "fertile",
        name = "Fertile",
        category = "Physical",
        description = "High reproductive capability",
        rarity = "uncommon",
        effects = {
            pregnancyChance = 0.40,
            twinChance = 0.15
        },
        eventModifiers = {
            pregnancy = 1.5,
            accidental_pregnancy = 1.4
        },
        conflictsWith = {"Infertile"},
        inheritChance = 0.20
    },
    
    Infertile = {
        id = "infertile",
        name = "Infertile",
        category = "Physical",
        description = "Unable to have biological children",
        rarity = "rare",
        effects = {
            pregnancyChance = -0.90
        },
        eventModifiers = {
            pregnancy = 0.1,
            fertility_treatment = 1.5
        },
        conflictsWith = {"Fertile"},
        inheritChance = 0.05
    },
    
    Rebellious = {
        id = "rebellious",
        name = "Rebellious",
        category = "Personality",
        description = "Questions authority and rules",
        rarity = "common",
        effects = {
            disciplineProblem = 0.25,
            creativityBonus = 0.15,
            crimeSuccess = 0.10,
            authorityConflict = 0.30
        },
        eventModifiers = {
            rule_breaking = 1.5,
            standing_up_authority = 1.4,
            school_trouble = 1.4
        },
        conflictsWith = {"Obedient"},
        inheritChance = 0.15
    },
    
    Obedient = {
        id = "obedient",
        name = "Obedient",
        category = "Personality",
        description = "Follows rules and respects authority",
        rarity = "common",
        effects = {
            disciplineProblem = -0.30,
            schoolSuccess = 0.15,
            militaryBonus = 0.20,
            creativityBonus = -0.10
        },
        eventModifiers = {
            following_orders = 1.4,
            getting_along = 1.3
        },
        conflictsWith = {"Rebellious"},
        inheritChance = 0.20
    },
    
    --========================================
    -- ROYAL/SPECIAL STATUS TRAITS
    --========================================
    RoyalBlood = {
        id = "royal_blood",
        name = "Royal Blood",
        category = "Special",
        description = "Born into royalty",
        rarity = "legendary",
        effects = {
            socialStatus = 1.0,
            wealthBonus = 0.50,
            fameBonus = 0.40,
            pressureBonus = 0.30
        },
        eventModifiers = {
            royal_event = 2.0,
            media_attention = 1.5,
            assassination_attempt = 1.2
        },
        conflictsWith = {},
        inheritChance = 0.90,
        specialCondition = "born_royal"
    },
    
    Famous = {
        id = "famous",
        name = "Famous",
        category = "Special",
        description = "Well-known public figure",
        rarity = "rare",
        effects = {
            fameBonus = 0.30,
            incomeBonus = 0.25,
            privacyPenalty = 0.40,
            stalkerRisk = 0.20
        },
        eventModifiers = {
            paparazzi = 1.5,
            endorsement = 1.4,
            scandal = 1.3
        },
        canDevelop = true,
        developmentTriggers = {"viral", "success", "achievement"},
        inheritChance = 0.10
    }
}

--============================================================================
-- TRAIT RARITY WEIGHTS
--============================================================================
TraitData.RarityWeights = {
    common = 0.50,
    uncommon = 0.30,
    rare = 0.15,
    legendary = 0.05
}

--============================================================================
-- HELPER FUNCTIONS
--============================================================================

-- Get random trait based on rarity
function TraitData.GetRandomTrait(excludeList)
    excludeList = excludeList or {}
    
    -- Build weighted list
    local weightedList = {}
    local totalWeight = 0
    
    for id, trait in pairs(TraitData.Traits) do
        local excluded = false
        for _, excludeId in ipairs(excludeList) do
            if id == excludeId then
                excluded = true
                break
            end
        end
        
        if not excluded then
            local weight = TraitData.RarityWeights[trait.rarity] or 0.25
            totalWeight = totalWeight + weight
            table.insert(weightedList, {trait = trait, weight = weight})
        end
    end
    
    -- Roll
    local roll = math.random() * totalWeight
    local cumulative = 0
    
    for _, entry in ipairs(weightedList) do
        cumulative = cumulative + entry.weight
        if roll <= cumulative then
            return entry.trait
        end
    end
    
    return weightedList[#weightedList].trait
end

-- Get traits by category
function TraitData.GetTraitsByCategory(category)
    local traits = {}
    for _, trait in pairs(TraitData.Traits) do
        if trait.category == category then
            table.insert(traits, trait)
        end
    end
    return traits
end

-- Check if two traits conflict
function TraitData.TraitsConflict(trait1Id, trait2Id)
    local trait1 = TraitData.Traits[trait1Id]
    if not trait1 then return false end
    
    if trait1.conflictsWith then
        for _, conflictId in ipairs(trait1.conflictsWith) do
            if conflictId == trait2Id then
                return true
            end
        end
    end
    
    return false
end

-- Calculate trait inheritance from parents
function TraitData.GetInheritedTraits(parent1Traits, parent2Traits)
    local inherited = {}
    local allParentTraits = {}
    
    -- Combine parent traits
    for _, traitId in ipairs(parent1Traits or {}) do
        allParentTraits[traitId] = (allParentTraits[traitId] or 0) + 1
    end
    for _, traitId in ipairs(parent2Traits or {}) do
        allParentTraits[traitId] = (allParentTraits[traitId] or 0) + 1
    end
    
    -- Check each parent trait for inheritance
    for traitId, count in pairs(allParentTraits) do
        local trait = TraitData.Traits[traitId]
        if trait then
            local inheritChance = trait.inheritChance or 0.10
            -- Double chance if both parents have it
            if count >= 2 then
                inheritChance = inheritChance * 2
            end
            
            if math.random() < inheritChance then
                table.insert(inherited, traitId)
            end
        end
    end
    
    return inherited
end

-- Get starting traits for new character
function TraitData.GetStartingTraits(numTraits)
    numTraits = numTraits or 2
    local traits = {}
    local attempts = 0
    local maxAttempts = 50
    
    while #traits < numTraits and attempts < maxAttempts do
        local trait = TraitData.GetRandomTrait()
        local canAdd = true
        
        -- Check conflicts with existing traits
        for _, existingId in ipairs(traits) do
            if TraitData.TraitsConflict(trait.id, existingId) then
                canAdd = false
                break
            end
        end
        
        -- Check if already have this trait
        for _, existingId in ipairs(traits) do
            if existingId == trait.id then
                canAdd = false
                break
            end
        end
        
        if canAdd then
            table.insert(traits, trait.id)
        end
        
        attempts = attempts + 1
    end
    
    return traits
end

-- Apply trait effects to player state
function TraitData.ApplyTraitEffects(playerState, traitIds)
    local modifiers = {
        health = 0,
        happiness = 0,
        stress = 0,
        money = 0,
        karma = 0,
        fame = 0,
        -- Skill modifiers
        skillGainBonus = 0,
        -- Social modifiers
        socialSuccess = 0,
        romanceSuccess = 0,
        relationshipBonus = 0,
        -- Work modifiers
        workPerformance = 0,
        promotionChance = 0,
        salaryBonus = 0,
        -- Other
        crimeSuccess = 0,
        gamblingBonus = 0
    }
    
    for _, traitId in ipairs(traitIds or {}) do
        local trait = TraitData.Traits[traitId]
        if trait and trait.effects then
            for effect, value in pairs(trait.effects) do
                modifiers[effect] = (modifiers[effect] or 0) + value
            end
        end
    end
    
    return modifiers
end

-- Get event modifier for a trait
function TraitData.GetEventModifier(traitIds, eventType)
    local modifier = 1.0
    
    for _, traitId in ipairs(traitIds or {}) do
        local trait = TraitData.Traits[traitId]
        if trait and trait.eventModifiers and trait.eventModifiers[eventType] then
            modifier = modifier * trait.eventModifiers[eventType]
        end
    end
    
    return modifier
end

-- Check if trait can develop from trigger
function TraitData.CanDevelopTrait(traitId, trigger, playerState)
    local trait = TraitData.Traits[traitId]
    if not trait then return false end
    if not trait.canDevelop then return false end
    if not trait.developmentTriggers then return false end
    
    -- Check if already has trait
    for _, existingId in ipairs(playerState.traits or {}) do
        if existingId == traitId then
            return false
        end
    end
    
    -- Check if trigger matches
    for _, validTrigger in ipairs(trait.developmentTriggers) do
        if validTrigger == trigger then
            return true
        end
    end
    
    return false
end

return TraitData
