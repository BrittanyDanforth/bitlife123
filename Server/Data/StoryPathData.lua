-- StoryPathData.lua - Long-term Story Paths
-- Multi-stage storylines the player can pursue

local StoryPathData = {}

--============================================================================
-- STORY PATHS
--============================================================================
StoryPathData.Paths = {
    --========================================
    -- POLITICAL CAREER
    --========================================
    political_career = {
        id = "political_career",
        name = "Political Career",
        description = "Rise through the ranks of politics to become President",
        icon = "🏛️",
        minAge = 25,
        requirements = {
            education = "Bachelor's Degree",
            criminalRecord = false,
            karma = 30
        },
        stages = {
            {
                id = "local_politics",
                name = "Local Politics",
                description = "Start your political journey at the local level",
                duration = 2, -- Years
                actions = {
                    campaign = {
                        name = "Campaign",
                        description = "Campaign for local office",
                        outcomes = {
                            {weight = 0.5, text = "Your message resonates!", effects = {progress = 20, fame = 2}},
                            {weight = 0.3, text = "Decent turnout at events.", effects = {progress = 10}},
                            {weight = 0.2, text = "Nobody showed up...", effects = {progress = -5, happiness = -5}}
                        }
                    },
                    fundraise = {
                        name = "Fundraise",
                        description = "Raise money for your campaign",
                        outcomes = {
                            {weight = 0.4, text = "Big donors interested!", effects = {money = 10000, progress = 10}},
                            {weight = 0.4, text = "Modest donations.", effects = {money = 2000, progress = 5}},
                            {weight = 0.2, text = "Fundraising fell flat.", effects = {money = 500}}
                        }
                    },
                    volunteer = {
                        name = "Community Work",
                        description = "Build grassroots support",
                        outcomes = {
                            {weight = 0.6, text = "Community loves you!", effects = {progress = 15, karma = 5}},
                            {weight = 0.4, text = "Good impression made.", effects = {progress = 8, karma = 2}}
                        }
                    }
                },
                completion = {
                    title = "City Council Member",
                    effects = {fame = 5, salary = 50000}
                }
            },
            {
                id = "state_politics",
                name = "State Politics",
                description = "Move up to state-level office",
                duration = 4,
                actions = {
                    legislate = {
                        name = "Propose Legislation",
                        description = "Introduce a bill",
                        outcomes = {
                            {weight = 0.3, text = "Bill passed! Historic!", effects = {progress = 25, fame = 5}},
                            {weight = 0.4, text = "Bill in committee.", effects = {progress = 10}},
                            {weight = 0.3, text = "Bill shot down.", effects = {progress = -5, happiness = -5}}
                        }
                    },
                    debate = {
                        name = "Public Debate",
                        description = "Face opponents in debate",
                        outcomes = {
                            {weight = 0.4, text = "Dominated the debate!", effects = {progress = 20, fame = 3}},
                            {weight = 0.4, text = "Held your own.", effects = {progress = 10}},
                            {weight = 0.2, text = "That went poorly...", effects = {progress = -10, fame = -2}}
                        }
                    },
                    scandal = {
                        name = "Handle Scandal",
                        description = "Address a political scandal",
                        hidden = true,
                        outcomes = {
                            {weight = 0.5, text = "Weathered the storm.", effects = {progress = 0}},
                            {weight = 0.3, text = "Came out stronger!", effects = {progress = 10, fame = 2}},
                            {weight = 0.2, text = "Career in jeopardy!", effects = {progress = -30, fame = -10}}
                        }
                    }
                },
                completion = {
                    title = "State Senator",
                    effects = {fame = 15, salary = 80000}
                }
            },
            {
                id = "national_politics",
                name = "National Politics",
                description = "Enter the national stage",
                duration = 6,
                actions = {
                    national_campaign = {
                        name = "National Campaign",
                        description = "Campaign across the country",
                        outcomes = {
                            {weight = 0.4, text = "Momentum building!", effects = {progress = 20, fame = 10}},
                            {weight = 0.4, text = "Mixed results.", effects = {progress = 10, fame = 5}},
                            {weight = 0.2, text = "Campaign struggling.", effects = {progress = -10}}
                        }
                    },
                    media = {
                        name = "Media Appearance",
                        description = "National TV interview",
                        outcomes = {
                            {weight = 0.4, text = "Viral moment! Clip everywhere!", effects = {progress = 25, fame = 15}},
                            {weight = 0.4, text = "Good interview.", effects = {progress = 10, fame = 5}},
                            {weight = 0.2, text = "Gaffe! Bad press!", effects = {progress = -15, fame = 5}}
                        }
                    }
                },
                completion = {
                    title = "Senator/Governor",
                    effects = {fame = 30, salary = 150000}
                }
            },
            {
                id = "presidential",
                name = "Presidential Campaign",
                description = "Run for the highest office",
                duration = 2,
                actions = {
                    primary = {
                        name = "Primary Campaign",
                        description = "Win your party's nomination",
                        outcomes = {
                            {weight = 0.3, text = "Secured nomination!", effects = {progress = 40, fame = 20}},
                            {weight = 0.4, text = "Delegate lead!", effects = {progress = 20, fame = 10}},
                            {weight = 0.3, text = "Losing ground.", effects = {progress = -10}}
                        }
                    },
                    general = {
                        name = "General Election",
                        description = "Face off against opponent",
                        outcomes = {
                            {weight = 0.4, text = "Polls looking good!", effects = {progress = 25}},
                            {weight = 0.4, text = "Tight race.", effects = {progress = 10}},
                            {weight = 0.2, text = "Falling behind.", effects = {progress = -15}}
                        }
                    }
                },
                completion = {
                    title = "President",
                    effects = {fame = 100, salary = 400000},
                    achievement = "Became President"
                }
            }
        }
    },
    
    --========================================
    -- CRIME EMPIRE
    --========================================
    crime_empire = {
        id = "crime_empire",
        name = "Crime Empire",
        description = "Build a criminal organization from nothing",
        icon = "🔫",
        minAge = 18,
        requirements = {
            karma = -20 -- Must be morally flexible
        },
        stages = {
            {
                id = "street_level",
                name = "Street Level",
                description = "Start as a small-time criminal",
                duration = 2,
                actions = {
                    hustle = {
                        name = "Hustle",
                        description = "Make money on the streets",
                        outcomes = {
                            {weight = 0.5, text = "Good haul tonight.", effects = {money = 1000, progress = 10, criminal = 1}},
                            {weight = 0.3, text = "Close call with cops.", effects = {money = 500, progress = 5}},
                            {weight = 0.2, text = "Got robbed yourself.", effects = {money = -500, health = -10}}
                        }
                    },
                    recruit = {
                        name = "Recruit",
                        description = "Build your crew",
                        outcomes = {
                            {weight = 0.5, text = "Found reliable people.", effects = {progress = 15}},
                            {weight = 0.3, text = "Crew is shaping up.", effects = {progress = 8}},
                            {weight = 0.2, text = "Can't trust anyone.", effects = {progress = -5}}
                        }
                    }
                },
                completion = {
                    title = "Street Boss",
                    effects = {criminal = 5, money = 10000}
                }
            },
            {
                id = "organized",
                name = "Organized Crime",
                description = "Run a proper operation",
                duration = 3,
                actions = {
                    territory = {
                        name = "Expand Territory",
                        description = "Take over new areas",
                        outcomes = {
                            {weight = 0.4, text = "New turf secured!", effects = {progress = 20, money = 5000}},
                            {weight = 0.3, text = "Rival gang pushback.", effects = {progress = 5, health = -10}},
                            {weight = 0.3, text = "Bloody war.", effects = {progress = -10, health = -20}}
                        }
                    },
                    launder = {
                        name = "Launder Money",
                        description = "Clean your dirty money",
                        outcomes = {
                            {weight = 0.6, text = "Money cleaned successfully.", effects = {progress = 10, money = 20000}},
                            {weight = 0.3, text = "IRS sniffing around.", effects = {progress = 5, stress = 20}},
                            {weight = 0.1, text = "Audit! Lost funds!", effects = {money = -10000}}
                        }
                    },
                    bribe = {
                        name = "Bribe Officials",
                        description = "Get cops and politicians on payroll",
                        outcomes = {
                            {weight = 0.5, text = "Protection secured.", effects = {progress = 15, money = -5000}},
                            {weight = 0.3, text = "They want more money.", effects = {money = -10000}},
                            {weight = 0.2, text = "Setup! It was a sting!", effects = {arrested = true}}
                        }
                    }
                },
                completion = {
                    title = "Crime Boss",
                    effects = {criminal = 10, money = 100000, fame = 5}
                }
            },
            {
                id = "kingpin",
                name = "Kingpin",
                description = "Rule the criminal underworld",
                duration = 5,
                actions = {
                    empire = {
                        name = "Expand Empire",
                        description = "Go nationwide",
                        outcomes = {
                            {weight = 0.3, text = "Empire spans the coast!", effects = {progress = 25, money = 500000}},
                            {weight = 0.4, text = "Growth continues.", effects = {progress = 15, money = 100000}},
                            {weight = 0.3, text = "Feds are watching.", effects = {progress = -10, stress = 30}}
                        }
                    },
                    eliminate = {
                        name = "Eliminate Competition",
                        description = "Deal with rivals permanently",
                        outcomes = {
                            {weight = 0.4, text = "Rivals eliminated.", effects = {progress = 20, karma = -20}},
                            {weight = 0.3, text = "War is costly.", effects = {progress = 10, money = -50000}},
                            {weight = 0.3, text = "You're a target now.", effects = {health = -30}}
                        }
                    },
                    go_legit = {
                        name = "Go Legitimate",
                        description = "Start cleaning up your business",
                        outcomes = {
                            {weight = 0.4, text = "Transitioning to legal.", effects = {karma = 10, progress = 10}},
                            {weight = 0.3, text = "Hard to leave the life.", effects = {}},
                            {weight = 0.3, text = "They won't let you leave.", effects = {health = -20}}
                        }
                    }
                },
                completion = {
                    title = "Crime Lord",
                    effects = {criminal = 20, money = 10000000, fame = 20},
                    achievement = "Built a Crime Empire"
                }
            }
        }
    },
    
    --========================================
    -- FAME & FORTUNE
    --========================================
    fame_fortune = {
        id = "fame_fortune",
        name = "Fame & Fortune",
        description = "Become a famous celebrity",
        icon = "⭐",
        minAge = 16,
        requirements = {
            looks = 50
        },
        stages = {
            {
                id = "aspiring",
                name = "Aspiring Star",
                description = "Break into the industry",
                duration = 2,
                actions = {
                    audition = {
                        name = "Audition",
                        description = "Try out for roles",
                        outcomes = {
                            {weight = 0.3, text = "Callback! They liked you!", effects = {progress = 20, fame = 2}},
                            {weight = 0.4, text = "Almost... not quite.", effects = {progress = 5}},
                            {weight = 0.3, text = "Rejected. Keep trying.", effects = {progress = -5, happiness = -10}}
                        }
                    },
                    social_media = {
                        name = "Build Social Media",
                        description = "Grow your following",
                        outcomes = {
                            {weight = 0.4, text = "Post went viral!", effects = {progress = 25, fame = 10}},
                            {weight = 0.4, text = "Steady growth.", effects = {progress = 10, fame = 3}},
                            {weight = 0.2, text = "Algorithm hates you.", effects = {progress = 0}}
                        }
                    },
                    network = {
                        name = "Network",
                        description = "Meet industry people",
                        outcomes = {
                            {weight = 0.4, text = "Made valuable connections!", effects = {progress = 15, Social = 2}},
                            {weight = 0.4, text = "Few good contacts.", effects = {progress = 8}},
                            {weight = 0.2, text = "Industry is brutal.", effects = {happiness = -10}}
                        }
                    }
                },
                completion = {
                    title = "Rising Star",
                    effects = {fame = 15}
                }
            },
            {
                id = "breakthrough",
                name = "Breakthrough",
                description = "Get your big break",
                duration = 3,
                actions = {
                    major_role = {
                        name = "Land Major Role",
                        description = "Audition for a big project",
                        outcomes = {
                            {weight = 0.3, text = "YOU GOT IT! Star role!", effects = {progress = 35, fame = 25, money = 100000}},
                            {weight = 0.4, text = "Supporting role offered.", effects = {progress = 15, fame = 10, money = 30000}},
                            {weight = 0.3, text = "Not this time.", effects = {progress = -5}}
                        }
                    },
                    publicity = {
                        name = "Publicity Stunt",
                        description = "Get attention",
                        outcomes = {
                            {weight = 0.4, text = "Headlines everywhere!", effects = {progress = 20, fame = 15}},
                            {weight = 0.3, text = "Some buzz generated.", effects = {progress = 10, fame = 5}},
                            {weight = 0.3, text = "Backfired! Bad press!", effects = {fame = 5, karma = -5}}
                        }
                    }
                },
                completion = {
                    title = "Celebrity",
                    effects = {fame = 40, money = 500000}
                }
            },
            {
                id = "a_list",
                name = "A-List",
                description = "Reach the top",
                duration = 4,
                actions = {
                    blockbuster = {
                        name = "Star in Blockbuster",
                        description = "Lead a major production",
                        outcomes = {
                            {weight = 0.4, text = "Box office smash!", effects = {progress = 30, fame = 30, money = 5000000}},
                            {weight = 0.4, text = "Solid performance.", effects = {progress = 15, fame = 10, money = 1000000}},
                            {weight = 0.2, text = "Flop. Critics harsh.", effects = {progress = -10, fame = -5}}
                        }
                    },
                    awards = {
                        name = "Awards Campaign",
                        description = "Campaign for recognition",
                        outcomes = {
                            {weight = 0.3, text = "AND THE WINNER IS... YOU!", effects = {progress = 40, fame = 50}},
                            {weight = 0.4, text = "Nominated!", effects = {progress = 20, fame = 20}},
                            {weight = 0.3, text = "Snubbed.", effects = {happiness = -10}}
                        }
                    },
                    brand = {
                        name = "Build Brand",
                        description = "Launch business ventures",
                        outcomes = {
                            {weight = 0.4, text = "Brand is thriving!", effects = {progress = 15, money = 2000000}},
                            {weight = 0.4, text = "Modest success.", effects = {progress = 8, money = 500000}},
                            {weight = 0.2, text = "Business failed.", effects = {money = -500000}}
                        }
                    }
                },
                completion = {
                    title = "A-List Celebrity",
                    effects = {fame = 80, money = 50000000},
                    achievement = "Became A-List Celebrity"
                }
            }
        }
    },
    
    --========================================
    -- BUSINESS TYCOON
    --========================================
    business_tycoon = {
        id = "business_tycoon",
        name = "Business Tycoon",
        description = "Build a business empire",
        icon = "💼",
        minAge = 21,
        requirements = {
            education = "Bachelor's Degree",
            smarts = 60
        },
        stages = {
            {
                id = "startup",
                name = "Startup",
                description = "Launch your first company",
                duration = 3,
                actions = {
                    develop = {
                        name = "Develop Product",
                        description = "Build your offering",
                        outcomes = {
                            {weight = 0.4, text = "Product-market fit!", effects = {progress = 25}},
                            {weight = 0.4, text = "Iterating...", effects = {progress = 10}},
                            {weight = 0.2, text = "Back to the drawing board.", effects = {progress = -10}}
                        }
                    },
                    pitch = {
                        name = "Pitch to Investors",
                        description = "Seek funding",
                        outcomes = {
                            {weight = 0.3, text = "Funded! $1M raised!", effects = {progress = 30, money = 1000000}},
                            {weight = 0.4, text = "Interested but not committed.", effects = {progress = 10}},
                            {weight = 0.3, text = "Rejected.", effects = {progress = -5, happiness = -10}}
                        }
                    },
                    hire = {
                        name = "Build Team",
                        description = "Hire key people",
                        outcomes = {
                            {weight = 0.5, text = "A-team assembled!", effects = {progress = 20, Leadership = 2}},
                            {weight = 0.3, text = "Decent hires.", effects = {progress = 10}},
                            {weight = 0.2, text = "Bad hire. Had to fire.", effects = {progress = -5, money = -10000}}
                        }
                    }
                },
                completion = {
                    title = "Startup Founder",
                    effects = {Financial = 5, Leadership = 5}
                }
            },
            {
                id = "growth",
                name = "Growth Phase",
                description = "Scale the business",
                duration = 4,
                actions = {
                    expand = {
                        name = "Expand Operations",
                        description = "Grow to new markets",
                        outcomes = {
                            {weight = 0.4, text = "Expansion successful!", effects = {progress = 25, money = 500000}},
                            {weight = 0.4, text = "Steady growth.", effects = {progress = 15, money = 200000}},
                            {weight = 0.2, text = "Expansion costs more than expected.", effects = {progress = 5, money = -100000}}
                        }
                    },
                    acquire = {
                        name = "Acquire Company",
                        description = "Buy a competitor",
                        outcomes = {
                            {weight = 0.4, text = "Strategic acquisition!", effects = {progress = 30, money = -500000}},
                            {weight = 0.3, text = "Integration challenges.", effects = {progress = 10, money = -300000}},
                            {weight = 0.3, text = "Deal fell through.", effects = {progress = -5}}
                        }
                    }
                },
                completion = {
                    title = "CEO",
                    effects = {money = 5000000, fame = 10}
                }
            },
            {
                id = "empire",
                name = "Business Empire",
                description = "Become a mogul",
                duration = 5,
                actions = {
                    ipo = {
                        name = "Take Company Public",
                        description = "IPO on stock market",
                        outcomes = {
                            {weight = 0.4, text = "IPO soars! You're a billionaire!", effects = {progress = 40, money = 100000000, fame = 30}},
                            {weight = 0.4, text = "Solid IPO.", effects = {progress = 20, money = 50000000, fame = 15}},
                            {weight = 0.2, text = "IPO flops.", effects = {progress = -10, money = 10000000}}
                        }
                    },
                    diversify = {
                        name = "Diversify Holdings",
                        description = "Build conglomerate",
                        outcomes = {
                            {weight = 0.5, text = "Portfolio thriving!", effects = {progress = 25, money = 20000000}},
                            {weight = 0.3, text = "Mixed results.", effects = {progress = 10}},
                            {weight = 0.2, text = "Some ventures failed.", effects = {money = -5000000}}
                        }
                    },
                    philanthropy = {
                        name = "Philanthropy",
                        description = "Give back",
                        outcomes = {
                            {weight = 0.6, text = "Your foundation helps millions!", effects = {progress = 15, karma = 30, fame = 10}},
                            {weight = 0.4, text = "Doing good work.", effects = {progress = 8, karma = 15}}
                        }
                    }
                },
                completion = {
                    title = "Business Tycoon",
                    effects = {money = 1000000000, fame = 50},
                    achievement = "Became a Billionaire"
                }
            }
        }
    }
}

--============================================================================
-- HELPER FUNCTIONS
--============================================================================

-- Get path by ID
function StoryPathData.GetPath(pathId)
    return StoryPathData.Paths[pathId]
end

-- Check if player meets requirements
function StoryPathData.MeetsRequirements(playerState, pathId)
    local path = StoryPathData.Paths[pathId]
    if not path then return false, "Path not found" end
    
    if playerState.age < path.minAge then
        return false, "Must be at least " .. path.minAge .. " years old"
    end
    
    if path.requirements then
        if path.requirements.education then
            -- Check education level
            local eduLevels = {
                ["None"] = 0,
                ["High School"] = 1,
                ["Associate's"] = 2,
                ["Bachelor's Degree"] = 3,
                ["Master's Degree"] = 4,
                ["PhD"] = 5
            }
            local playerLevel = eduLevels[playerState.education.level] or 0
            local reqLevel = eduLevels[path.requirements.education] or 0
            if playerLevel < reqLevel then
                return false, "Requires " .. path.requirements.education
            end
        end
        
        if path.requirements.criminalRecord == false then
            if playerState.legal.criminalRecord and #playerState.legal.criminalRecord > 0 then
                return false, "Cannot have a criminal record"
            end
        end
        
        if path.requirements.karma then
            if (playerState.karma or 50) < path.requirements.karma then
                return false, "Karma too low"
            end
        end
        
        if path.requirements.smarts then
            if (playerState.smarts or 50) < path.requirements.smarts then
                return false, "Not smart enough"
            end
        end
        
        if path.requirements.looks then
            if (playerState.looks or 50) < path.requirements.looks then
                return false, "Looks requirement not met"
            end
        end
    end
    
    return true
end

-- Get current stage for player
function StoryPathData.GetCurrentStage(playerState, pathId)
    local progress = playerState.storyPaths.progress[pathId]
    if not progress then return nil end
    
    local path = StoryPathData.Paths[pathId]
    if not path then return nil end
    
    return path.stages[progress.stageIndex]
end

-- Process action outcome
function StoryPathData.ProcessAction(action)
    if not action.outcomes then return nil end
    
    local roll = math.random()
    local cumulative = 0
    
    for _, outcome in ipairs(action.outcomes) do
        cumulative = cumulative + outcome.weight
        if roll <= cumulative then
            return outcome
        end
    end
    
    return action.outcomes[#action.outcomes]
end

-- Get all available paths
function StoryPathData.GetAllPaths()
    local paths = {}
    for id, path in pairs(StoryPathData.Paths) do
        table.insert(paths, {
            id = id,
            name = path.name,
            description = path.description,
            icon = path.icon
        })
    end
    return paths
end

return StoryPathData
