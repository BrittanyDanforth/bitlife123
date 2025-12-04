-- CareerData Part 5: Sports, Military, Criminal, and Unique Careers
-- High-stakes and specialized career paths

local CareerData_Part5 = {}
CareerData_Part5.Jobs = {}

--============================================================================
-- SPORTS CAREERS
--============================================================================

-- PROFESSIONAL ATHLETE
CareerData_Part5.Jobs["Professional Athlete"] = {
    id = "professional_athlete",
    title = "Professional Athlete",
    category = "Sports",
    baseSalary = 500000,
    salaryRange = {50000, 50000000},
    minAge = 18,
    maxAge = 40,
    requirement = nil,
    specialRequirement = "Elite Athletic Ability",
    requiredSkills = {Athletic = 70, Physical = 70},
    skillGains = {Athletic = 2, Physical = 2, Fame = 3},
    description = "Compete at the highest level. Your body is your career.",
    workEnvironment = "stadium",
    stressLevel = "very_high",
    promotionPath = "All-Star/Hall of Fame",
    careerLength = "short",
    
    careerEvents = {
        {
            id = "ath_injury",
            name = "Major Injury",
            description = "You tore your ACL during the game. Career-threatening injury.",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Get surgery and rehab fully",
                    outcomes = {
                        {probability = 0.6, result = "comeback", description = "After 9 months, you're back! Maybe even stronger!", effects = {health = -20, athletic = 2}},
                        {probability = 0.3, result = "never_same", description = "You return but you're not the same athlete.", effects = {health = -30, athletic = -20}},
                        {probability = 0.1, result = "retired", description = "The injury ends your career early.", effects = {fired = true}}
                    }
                },
                {
                    text = "Rush back too soon",
                    outcomes = {
                        {probability = 0.3, result = "fine", description = "Somehow you're okay. Lucky.", effects = {health = -15}},
                        {probability = 0.7, result = "reinjury", description = "Reinjured. Now it's really bad.", effects = {health = -50, athletic = -30}}
                    }
                }
            }
        },
        {
            id = "ath_contract",
            name = "Contract Negotiations",
            description = "Your contract is up! Time to negotiate for what you're worth.",
            probability = 0.06,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Demand top dollar",
                    outcomes = {
                        {probability = 0.4, result = "max_deal", description = "You got the MAX CONTRACT! Generational wealth!", effects = {money = 10000000, happiness = 40}},
                        {probability = 0.4, result = "negotiated", description = "Got a good deal after some back and forth.", effects = {money = 5000000, happiness = 20}},
                        {probability = 0.2, result = "holdout", description = "Standoff. You might miss games.", effects = {stress = 30}}
                    }
                },
                {
                    text = "Take a team-friendly deal",
                    outcomes = {
                        {probability = 0.7, result = "team_player", description = "Less money but team can build around you.", effects = {money = 3000000, reputation = 20}},
                        {probability = 0.3, result = "regret", description = "Teammates got paid more. You feel foolish.", effects = {money = 3000000, happiness = -15}}
                    }
                },
                {
                    text = "Test free agency",
                    outcomes = {
                        {probability = 0.5, result = "bidding_war", description = "Multiple teams bid! Leverage!", effects = {money = 8000000, fame = 10}},
                        {probability = 0.3, result = "new_team", description = "Got paid but had to move cities.", effects = {money = 6000000, happiness = -10}},
                        {probability = 0.2, result = "no_offers", description = "Market dried up. Scrambling.", effects = {money = 1000000, stress = 25}}
                    }
                }
            }
        },
        {
            id = "ath_championship",
            name = "Championship Game",
            description = "This is it. The championship. Everything you've worked for.",
            probability = 0.04,
            minYearsInJob = 1,
            requiresPerformance = 70,
            choices = {
                {
                    text = "Play the game of your life",
                    outcomes = {
                        {probability = 0.5, result = "champion", description = "YOU WON! CHAMPIONSHIP! Confetti, tears, glory!", effects = {fame = 50, happiness = 50, money = 1000000}},
                        {probability = 0.3, result = "lost", description = "You played great but lost. Silver medal.", effects = {fame = 20, happiness = -20}},
                        {probability = 0.2, result = "choked", description = "You choked in the big moment. Haunting.", effects = {fame = 10, happiness = -30, reputation = -20}}
                    }
                }
            }
        },
        {
            id = "ath_scandal",
            name = "PED Scandal",
            description = "You're accused of using performance-enhancing drugs!",
            probability = 0.03,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Deny everything",
                    outcomes = {
                        {probability = 0.3, result = "cleared", description = "Tests come back clean! Your name is cleared!", effects = {reputation = 10}},
                        {probability = 0.7, result = "suspended", description = "Evidence proves otherwise. Suspended.", effects = {reputation = -40, fame = -20, money = -1000000}}
                    }
                },
                {
                    text = "Come clean if guilty",
                    outcomes = {
                        {probability = 0.5, result = "redemption", description = "Your honesty starts a redemption arc.", effects = {reputation = -20, karma = 10}},
                        {probability = 0.5, result = "pariah", description = "You're a cheater. Legacy tarnished.", effects = {reputation = -50, fame = -30}}
                    }
                }
            }
        },
        {
            id = "ath_retirement",
            name = "Retirement Decision",
            description = "Your body is breaking down. Is it time to retire?",
            probability = 0.05,
            minYearsInJob = 5,
            choices = {
                {
                    text = "Retire on top",
                    outcomes = {
                        {probability = 0.8, result = "legend", description = "You go out a legend. Hall of Fame awaits.", effects = {retired = true, fame = 30}},
                        {probability = 0.2, result = "regret", description = "Did you leave too early? You'll never know.", effects = {retired = true, happiness = -10}}
                    }
                },
                {
                    text = "Play one more year",
                    outcomes = {
                        {probability = 0.4, result = "glory", description = "One more great season! Perfect ending!", effects = {fame = 20, money = 2000000}},
                        {probability = 0.6, result = "embarrassing", description = "Your body gave out. Sad ending.", effects = {health = -30, fame = -10}}
                    }
                }
            }
        },
        {
            id = "ath_endorsement",
            name = "Endorsement Deal",
            description = "A major brand wants you as their spokesperson!",
            probability = 0.07,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Take the deal",
                    outcomes = {
                        {probability = 0.7, result = "paid", description = "Easy money! Your face is everywhere!", effects = {money = 2000000, fame = 20}},
                        {probability = 0.3, result = "controversy", description = "The brand gets in trouble. You're associated.", effects = {money = 2000000, reputation = -15}}
                    }
                },
                {
                    text = "Negotiate for equity instead",
                    outcomes = {
                        {probability = 0.4, result = "rich", description = "Company explodes! Your equity is worth millions!", effects = {money = 10000000}},
                        {probability = 0.6, result = "nothing", description = "Company fails. Your equity is worthless.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Practice was brutal. Everything hurts.",
        "Game day! Adrenaline is pumping!",
        "A kid asked for your autograph. Still surreal.",
        "Media obligations all morning.",
        "Physical therapy again.",
        "Film session revealed what you did wrong.",
        "Nutrition plan is boring but necessary.",
        "Coach praised your effort today!",
        "Your jersey is the top seller!",
        "Rival talked trash. Can't wait to face them.",
        "Rest day. Your body thanks you.",
        "Social media is blowing up after that play!",
        "Contract bonus for making the playoffs!",
        "Your stats are looking good this season."
    }
}

-- PERSONAL TRAINER
CareerData_Part5.Jobs["Personal Trainer"] = {
    id = "personal_trainer",
    title = "Personal Trainer",
    category = "Fitness",
    baseSalary = 40000,
    salaryRange = {25000, 100000},
    minAge = 18,
    maxAge = nil,
    requirement = nil,
    certifications = {"Personal Training Certification"},
    requiredSkills = {Physical = 30, Social = 20},
    skillGains = {Physical = 2, Social = 2, Teaching = 1},
    description = "Help people get fit. Count reps. Motivate the unmotivated.",
    workEnvironment = "gym",
    stressLevel = "low",
    promotionPath = "Gym Manager",
    freelance = true,
    
    careerEvents = {
        {
            id = "pt_celebrity_client",
            name = "Celebrity Client",
            description = "A famous celebrity wants you as their personal trainer!",
            probability = 0.04,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Take them on",
                    outcomes = {
                        {probability = 0.6, result = "famous", description = "Word spreads! Celebrity clients start calling!", effects = {fame = 10, money = 50000, reputation = 25}},
                        {probability = 0.3, result = "demanding", description = "They're incredibly demanding. Worth the money?", effects = {money = 40000, stress = 25}},
                        {probability = 0.1, result = "fired", description = "They fire you publicly. Bad press.", effects = {reputation = -20}}
                    }
                },
                {
                    text = "Decline - NDA complications",
                    outcomes = {
                        {probability = 0.5, result = "respectful", description = "They respect your boundaries.", effects = {}},
                        {probability = 0.5, result = "missed", description = "That could have changed your career...", effects = {happiness = -5}}
                    }
                }
            }
        },
        {
            id = "pt_transformation",
            name = "Incredible Transformation",
            description = "Your client's transformation is going viral! Before/after photos everywhere!",
            probability = 0.05,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Ride the wave - promote yourself",
                    outcomes = {
                        {probability = 0.7, result = "famous", description = "Business explodes! Waitlist of clients!", effects = {fame = 15, money = 20000, reputation = 20}},
                        {probability = 0.3, result = "backlash", description = "Some say the transformation was photoshopped.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Keep the spotlight on the client",
                    outcomes = {
                        {probability = 0.8, result = "classy", description = "People appreciate your humility. Referrals increase.", effects = {reputation = 15, karma = 5}},
                        {probability = 0.2, result = "unnoticed", description = "You don't get the credit you deserve.", effects = {}}
                    }
                }
            }
        },
        {
            id = "pt_injury",
            name = "Client Injury",
            description = "A client got injured during your session!",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Document everything properly",
                    outcomes = {
                        {probability = 0.8, result = "covered", description = "Your documentation protects you. Minor injury.", effects = {stress = 15}},
                        {probability = 0.2, result = "lawsuit", description = "They sue anyway. Your insurance covers it.", effects = {stress = 25, money = -2000}}
                    }
                },
                {
                    text = "Help them and apologize",
                    outcomes = {
                        {probability = 0.7, result = "forgiven", description = "They understand. Accidents happen.", effects = {karma = 5}},
                        {probability = 0.3, result = "angry", description = "They blame you completely.", effects = {reputation = -15}}
                    }
                }
            }
        },
        {
            id = "pt_gym_offer",
            name = "Gym Partnership",
            description = "A gym offers you a partnership to open your own training studio!",
            probability = 0.04,
            minYearsInJob = 2,
            requiresPerformance = 65,
            choices = {
                {
                    text = "Accept the partnership",
                    outcomes = {
                        {probability = 0.6, result = "success", description = "Your studio is thriving! Business owner!", effects = {promoted = "Studio Owner", money = 30000, stress = 20}},
                        {probability = 0.4, result = "struggle", description = "Business is hard. Barely breaking even.", effects = {promoted = "Studio Owner", stress = 30}}
                    }
                },
                {
                    text = "Stay independent",
                    outcomes = {
                        {probability = 1.0, result = "freedom", description = "Freedom over growth. Valid choice.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Client hit a new PR! Your coaching worked!",
        "Someone asked for 'just abs'. Explained it doesn't work that way.",
        "5 AM client. Coffee is everything.",
        "A client no-showed. Frustrating.",
        "Your workout was fire today.",
        "Demonstrated perfect squat form. Legs hurt now.",
        "New client is incredibly motivated!",
        "Someone hogged the squat rack for an hour.",
        "Meal prepped with a client. Teaching moment.",
        "A client finally stuck to their diet!",
        "The gym is packed. New Year's resolution crowd.",
        "Helped someone with their form. They appreciated it.",
        "Certification renewal is due. Time to study.",
        "A client brought you a protein bar. Sweet!"
    }
}

--============================================================================
-- MILITARY CAREERS
--============================================================================

-- ENLISTED SOLDIER
CareerData_Part5.Jobs["Enlisted Soldier"] = {
    id = "enlisted_soldier",
    title = "Enlisted Soldier",
    category = "Military",
    baseSalary = 35000,
    salaryRange = {30000, 55000},
    minAge = 18,
    maxAge = 35,
    requirement = "High School",
    additionalRequirements = {"Pass ASVAB", "Basic Training"},
    requiredSkills = {Physical = 25},
    skillGains = {Physical = 3, Leadership = 2, Technical = 1},
    description = "Serve your country. From push-ups to combat.",
    workEnvironment = "military_base",
    stressLevel = "high",
    promotionPath = "Non-Commissioned Officer",
    benefits = {"Housing", "Healthcare", "GI Bill"},
    
    careerEvents = {
        {
            id = "mil_deployment",
            name = "Deployment Orders",
            description = "You're being deployed to an active combat zone.",
            probability = 0.08,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Accept your duty",
                    outcomes = {
                        {probability = 0.6, result = "served", description = "Tour complete. You saw things, did things. Changed.", effects = {leadership = 3, physical = 2, happiness = -10, karma = 15}},
                        {probability = 0.3, result = "decorated", description = "Your valor earned you a medal!", effects = {reputation = 30, fame = 5, leadership = 5}},
                        {probability = 0.1, result = "wounded", description = "You were wounded in action. Purple Heart.", effects = {health = -40, reputation = 20, fame = 5}}
                    }
                }
            }
        },
        {
            id = "mil_combat",
            name = "Under Fire",
            description = "Your unit is taking enemy fire! What do you do?",
            probability = 0.05,
            minYearsInJob = 0,
            deploymentRequired = true,
            choices = {
                {
                    text = "Lead the counterattack",
                    outcomes = {
                        {probability = 0.5, result = "hero", description = "Your leadership saved lives! Medal recommendation!", effects = {reputation = 40, leadership = 5}},
                        {probability = 0.3, result = "survived", description = "Fierce fighting. Everyone made it.", effects = {leadership = 2}},
                        {probability = 0.2, result = "wounded", description = "You're hit! Medic!", effects = {health = -30}}
                    }
                },
                {
                    text = "Provide cover fire",
                    outcomes = {
                        {probability = 0.7, result = "covered", description = "Your fire allowed teammates to advance.", effects = {reputation = 15}},
                        {probability = 0.3, result = "pinned", description = "Pinned down for hours. Terrifying.", effects = {stress = 30}}
                    }
                },
                {
                    text = "Call for support",
                    outcomes = {
                        {probability = 0.6, result = "support", description = "Air support arrives! Enemy neutralized!", effects = {reputation = 10}},
                        {probability = 0.4, result = "delayed", description = "Support delayed. You had to improvise.", effects = {leadership = 2}}
                    }
                }
            }
        },
        {
            id = "mil_ptsd",
            name = "The Memories",
            description = "You're struggling with what you experienced. Nightmares. Flashbacks.",
            probability = 0.06,
            minYearsInJob = 1,
            combatRequired = true,
            choices = {
                {
                    text = "Seek help from VA",
                    outcomes = {
                        {probability = 0.7, result = "healing", description = "Therapy helps. Slow progress, but progress.", effects = {happiness = 10, health = 10}},
                        {probability = 0.3, result = "waiting", description = "Months-long waitlist. The system is broken.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Talk to fellow veterans",
                    outcomes = {
                        {probability = 0.8, result = "understood", description = "They get it. You're not alone.", effects = {happiness = 15}},
                        {probability = 0.2, result = "isolated", description = "Hard to open up. Still struggling.", effects = {happiness = -5}}
                    }
                },
                {
                    text = "Try to push through alone",
                    outcomes = {
                        {probability = 0.3, result = "strong", description = "Time helps. You find peace.", effects = {}},
                        {probability = 0.7, result = "struggle", description = "It gets worse. Please get help.", effects = {health = -20, happiness = -25}}
                    }
                }
            }
        },
        {
            id = "mil_reenlist",
            name = "Reenlistment Decision",
            description = "Your contract is up. Reenlist or return to civilian life?",
            probability = 0.05,
            minYearsInJob = 3,
            choices = {
                {
                    text = "Reenlist",
                    outcomes = {
                        {probability = 0.7, result = "career", description = "Military is your life. Promotion opportunities ahead.", effects = {promotionProgress = 20, money = 10000}},
                        {probability = 0.3, result = "stuck", description = "Same old same old. Wondering about civilian life.", effects = {}}
                    }
                },
                {
                    text = "Return to civilian life",
                    outcomes = {
                        {probability = 0.5, result = "transition", description = "Adjustment is hard but you make it work. GI Bill helps.", effects = {newCareerPath = "Civilian", money = 20000}},
                        {probability = 0.5, result = "struggle", description = "Civilian life is harder than expected.", effects = {stress = 25, happiness = -10}}
                    }
                }
            }
        },
        {
            id = "mil_promotion",
            name = "Promotion Board",
            description = "You're up for E-5 Sergeant!",
            probability = 0.06,
            minYearsInJob = 3,
            requiresPerformance = 60,
            choices = {
                {
                    text = "Go before the board",
                    outcomes = {
                        {probability = 0.6, result = "promoted", description = "Congratulations, Sergeant! More stripes, more responsibility!", effects = {promoted = "Sergeant", salaryIncrease = 8000, leadership = 2}},
                        {probability = 0.4, result = "passed", description = "Not this time. Keep trying.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Wait for more experience",
                    outcomes = {
                        {probability = 0.7, result = "later", description = "More time to prepare.", effects = {}},
                        {probability = 0.3, result = "missed", description = "Someone else got your slot.", effects = {happiness = -5}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "PT at 0500. Your whole body aches.",
        "Drill sergeant made you do 50 extra push-ups.",
        "Care package from home! Best day!",
        "Cleaned the barracks for inspection.",
        "Weapons training was on point today.",
        "Your battle buddy had your back.",
        "MREs again. At least it's food.",
        "Got yelled at for a messy bunk.",
        "Letters from family keep you going.",
        "Night watch. Stars are beautiful out here.",
        "Your unit won the PT competition!",
        "Waiting. So much waiting.",
        "Made some lifelong friends today.",
        "Missing home. But you're proud of your service."
    }
}

--============================================================================
-- CRIMINAL CAREERS
--============================================================================

-- DRUG DEALER
CareerData_Part5.Jobs["Drug Dealer"] = {
    id = "drug_dealer",
    title = "Drug Dealer",
    category = "Criminal",
    baseSalary = 50000,
    salaryRange = {20000, 500000},
    minAge = 16,
    maxAge = nil,
    requirement = nil,
    illegal = true,
    requiredSkills = {Criminal = 20},
    skillGains = {Criminal = 3, Social = 1, Charisma = 1},
    description = "Sell drugs. Make money. Try not to die or go to prison.",
    workEnvironment = "streets",
    stressLevel = "extreme",
    promotionPath = "Drug Lord",
    
    careerEvents = {
        {
            id = "drug_bust",
            name = "Police Raid",
            description = "POLICE! They're raiding your spot!",
            probability = 0.12,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Run!",
                    outcomes = {
                        {probability = 0.4, result = "escaped", description = "You got away! Lost product but not your freedom.", effects = {money = -5000}},
                        {probability = 0.4, result = "caught", description = "They caught you. You're going to jail.", effects = {arrested = true}},
                        {probability = 0.2, result = "shot", description = "They shot at you! You're hit!", effects = {health = -40, arrested = true}}
                    }
                },
                {
                    text = "Flush everything",
                    outcomes = {
                        {probability = 0.5, result = "clean", description = "No evidence! They have to let you go.", effects = {money = -10000}},
                        {probability = 0.5, result = "found", description = "They found some. Possession charges.", effects = {arrested = true}}
                    }
                },
                {
                    text = "Comply peacefully",
                    outcomes = {
                        {probability = 0.8, result = "arrested", description = "You're arrested. No additional charges for resisting.", effects = {arrested = true}},
                        {probability = 0.2, result = "beaten", description = "They were rough anyway.", effects = {arrested = true, health = -20}}
                    }
                }
            }
        },
        {
            id = "drug_rival",
            name = "Territory Dispute",
            description = "A rival crew is moving in on your territory!",
            probability = 0.10,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Fight for your turf",
                    outcomes = {
                        {probability = 0.4, result = "won", description = "They backed off. Your reputation grows.", effects = {reputation = 20, criminal = 2}},
                        {probability = 0.3, result = "war", description = "Street war begins. Dangerous.", effects = {reputation = 10, stress = 30}},
                        {probability = 0.3, result = "shot", description = "You got shot in the beef.", effects = {health = -35}}
                    }
                },
                {
                    text = "Try to negotiate",
                    outcomes = {
                        {probability = 0.4, result = "peace", description = "You split territory. Business continues.", effects = {money = -10000}},
                        {probability = 0.6, result = "weak", description = "They see you as weak. Things get worse.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Move your operation",
                    outcomes = {
                        {probability = 0.6, result = "new_turf", description = "New territory, fresh start.", effects = {}},
                        {probability = 0.4, result = "followed", description = "They follow you. No escape.", effects = {stress = 25}}
                    }
                }
            }
        },
        {
            id = "drug_snitch",
            name = "Snitch in the Crew",
            description = "You think someone in your crew is talking to the police...",
            probability = 0.06,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Find out who it is",
                    outcomes = {
                        {probability = 0.5, result = "found", description = "You found the rat. Now what?", effects = {}},
                        {probability = 0.3, result = "wrong_person", description = "You accused the wrong person.", effects = {reputation = -10, karma = -10}},
                        {probability = 0.2, result = "paranoia", description = "Maybe there is no snitch. You're paranoid.", effects = {happiness = -15}}
                    }
                },
                {
                    text = "Lay low for a while",
                    outcomes = {
                        {probability = 0.6, result = "safe", description = "Good call. Heat dies down.", effects = {money = -5000}},
                        {probability = 0.4, result = "busted", description = "They busted you anyway.", effects = {arrested = true}}
                    }
                },
                {
                    text = "Feed false information",
                    outcomes = {
                        {probability = 0.7, result = "smart", description = "Snitch is exposed when cops act on bad info!", effects = {criminal = 2}},
                        {probability = 0.3, result = "backfire", description = "Your plan backfired.", effects = {stress = 20}}
                    }
                }
            }
        },
        {
            id = "drug_connect",
            name = "New Connection",
            description = "A major supplier wants to work with you. Much bigger product, much bigger risk.",
            probability = 0.05,
            minYearsInJob = 1,
            requiresPerformance = 50,
            choices = {
                {
                    text = "Move up to wholesale",
                    outcomes = {
                        {probability = 0.5, result = "kingpin", description = "You're a major player now. Serious money!", effects = {promoted = "Drug Kingpin", money = 100000, criminal = 5}},
                        {probability = 0.3, result = "feds", description = "The feds are watching big players. Heat increases.", effects = {money = 50000, stress = 30}},
                        {probability = 0.2, result = "setup", description = "It was a setup. You're arrested.", effects = {arrested = true}}
                    }
                },
                {
                    text = "Stay at your level",
                    outcomes = {
                        {probability = 0.7, result = "safe", description = "Less money but less risk.", effects = {}},
                        {probability = 0.3, result = "disrespect", description = "They see you as small time.", effects = {reputation = -10}}
                    }
                }
            }
        },
        {
            id = "drug_out",
            name = "Getting Out",
            description = "You're thinking about going straight. But the game doesn't let you go easily...",
            probability = 0.04,
            minYearsInJob = 2,
            choices = {
                {
                    text = "Walk away clean",
                    outcomes = {
                        {probability = 0.4, result = "out", description = "You got out! Starting fresh!", effects = {newCareerPath = "Legitimate", karma = 15}},
                        {probability = 0.4, result = "pulled_back", description = "They won't let you leave. You know too much.", effects = {stress = 30}},
                        {probability = 0.2, result = "killed", description = "They made an example of you.", effects = {health = -50}}
                    }
                },
                {
                    text = "Make one last big score",
                    outcomes = {
                        {probability = 0.3, result = "rich", description = "One last hit! Set for life!", effects = {money = 200000, karma = -10}},
                        {probability = 0.7, result = "caught", description = "One more job... that's always how it goes.", effects = {arrested = true}}
                    }
                },
                {
                    text = "Turn informant",
                    outcomes = {
                        {probability = 0.5, result = "protection", description = "Witness protection. New identity, new life.", effects = {karma = 10, money = 0}},
                        {probability = 0.5, result = "discovered", description = "Word got out. You're marked.", effects = {health = -30}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Made good money today. Clean transactions.",
        "Had to lay low. Cops were around.",
        "A junkie tried to short you. Handled it.",
        "Re-upped from your connect.",
        "Paranoid every time a car slows down.",
        "Made a new customer. Word of mouth.",
        "Someone OD'd on your product. The guilt...",
        "Rival crew mean-mugged you. Tension rising.",
        "Counting cash alone at 3 AM.",
        "Your mom thinks you're a 'entrepreneur'. If she knew...",
        "Product was stepped on. Customer complained.",
        "Good day. No drama. Those are rare.",
        "Almost got robbed. Watched your back.",
        "The life is getting to you."
    }
}

-- HITMAN
CareerData_Part5.Jobs["Hitman"] = {
    id = "hitman",
    title = "Hitman",
    category = "Criminal",
    baseSalary = 150000,
    salaryRange = {50000, 1000000},
    minAge = 25,
    maxAge = nil,
    requirement = nil,
    illegal = true,
    requiredSkills = {Criminal = 50, Stealth = 40, Physical = 30},
    skillGains = {Criminal = 3, Stealth = 3},
    description = "Kill people for money. The ultimate moral compromise.",
    workEnvironment = "various",
    stressLevel = "extreme",
    promotionPath = "Legendary Assassin",
    
    careerEvents = {
        {
            id = "hit_target",
            name = "New Contract",
            description = "A high-profile target. $500,000. Do you accept?",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Accept the contract",
                    outcomes = {
                        {probability = 0.5, result = "clean", description = "Clean job. In and out. Payment received.", effects = {money = 500000, criminal = 3, karma = -50}},
                        {probability = 0.3, result = "messy", description = "Complications. You got it done but left evidence.", effects = {money = 500000, stress = 25, karma = -50}},
                        {probability = 0.2, result = "caught", description = "Caught on camera. You're a wanted person.", effects = {money = 200000, karma = -50}}
                    }
                },
                {
                    text = "Decline - too risky",
                    outcomes = {
                        {probability = 0.7, result = "passed", description = "Someone else takes the job.", effects = {}},
                        {probability = 0.3, result = "displeased", description = "Your employer is displeased. Might affect future work.", effects = {reputation = -15}}
                    }
                }
            }
        },
        {
            id = "hit_innocent",
            name = "Wrong Target",
            description = "The intel was bad. The target... wasn't guilty of anything.",
            probability = 0.03,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "It's done. Move on.",
                    outcomes = {
                        {probability = 0.5, result = "cold", description = "You're becoming colder. The job does this.", effects = {karma = -30, happiness = -15}},
                        {probability = 0.5, result = "haunted", description = "Their face haunts you.", effects = {karma = -30, happiness = -25, stress = 30}}
                    }
                },
                {
                    text = "Seek revenge on who gave you bad intel",
                    outcomes = {
                        {probability = 0.4, result = "justice", description = "They set you up. You handled them.", effects = {karma = -20}},
                        {probability = 0.6, result = "war", description = "You've started a war.", effects = {stress = 40}}
                    }
                }
            }
        },
        {
            id = "hit_retire",
            name = "Getting Out",
            description = "You want out. But people like you don't just retire...",
            probability = 0.04,
            minYearsInJob = 3,
            choices = {
                {
                    text = "Disappear completely",
                    outcomes = {
                        {probability = 0.4, result = "free", description = "New identity. New life. You're out.", effects = {newCareerPath = "Retired", karma = 5}},
                        {probability = 0.6, result = "found", description = "They found you. There's no getting out.", effects = {health = -30}}
                    }
                },
                {
                    text = "Fake your own death",
                    outcomes = {
                        {probability = 0.5, result = "dead", description = "As far as everyone knows, you're dead.", effects = {newCareerPath = "Assumed Dead", fame = -100}},
                        {probability = 0.5, result = "discovered", description = "Your 'death' is discovered as a fake.", effects = {stress = 40}}
                    }
                },
                {
                    text = "Keep working until they kill you",
                    outcomes = {
                        {probability = 1.0, result = "fate", description = "You accept your fate. This is who you are.", effects = {happiness = -10}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Surveillance on a target. Hours of watching.",
        "Payment came through. Untraceable as always.",
        "Acquiring new equipment. The usual.",
        "A clean job. Professional.",
        "Can't sleep. The faces...",
        "New identity papers arrived.",
        "Training at the range. Stay sharp.",
        "A client tried to double-cross you. Mistake.",
        "Laying low between jobs.",
        "The isolation gets to you sometimes.",
        "Another day, another life taken.",
        "Met with a new contact. Business as usual.",
        "What would your family think?",
        "Money can't buy peace of mind."
    }
}

--============================================================================
-- UNIQUE CAREERS
--============================================================================

-- REAL ESTATE AGENT
CareerData_Part5.Jobs["Real Estate Agent"] = {
    id = "real_estate_agent",
    title = "Real Estate Agent",
    category = "Real Estate",
    baseSalary = 45000,
    salaryRange = {20000, 500000},
    minAge = 18,
    maxAge = nil,
    requirement = "Real Estate License",
    requiredSkills = {Social = 30},
    skillGains = {Social = 3, Financial = 2, Charisma = 2},
    description = "Help people buy and sell homes. Commission-based hustle.",
    workEnvironment = "office",
    stressLevel = "medium",
    promotionPath = "Broker",
    commission = true,
    
    careerEvents = {
        {
            id = "re_big_sale",
            name = "Million Dollar Listing",
            description = "You landed a $2 million listing! If you sell it, huge commission!",
            probability = 0.06,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Go all out on marketing",
                    outcomes = {
                        {probability = 0.5, result = "sold", description = "SOLD! $60,000 commission!", effects = {money = 60000, reputation = 25}},
                        {probability = 0.3, result = "reduced", description = "Sold but for less. Still good commission.", effects = {money = 45000, reputation = 15}},
                        {probability = 0.2, result = "expired", description = "Listing expired. Lost the client.", effects = {happiness = -20}}
                    }
                },
                {
                    text = "Price it aggressively",
                    outcomes = {
                        {probability = 0.4, result = "fast_sale", description = "Sold in a week! Quick commission!", effects = {money = 55000, reputation = 20}},
                        {probability = 0.6, result = "underpriced", description = "Seller thinks you left money on the table.", effects = {money = 55000, reputation = -10}}
                    }
                }
            }
        },
        {
            id = "re_nightmare_client",
            name = "Client From Hell",
            description = "This buyer has rejected 47 homes and counting...",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Keep showing houses",
                    outcomes = {
                        {probability = 0.4, result = "finally", description = "House #48 is the one! They LOVE it!", effects = {money = 15000, stress = 20}},
                        {probability = 0.6, result = "endless", description = "They rejected that one too. Your soul hurts.", effects = {stress = 30}}
                    }
                },
                {
                    text = "Have a heart-to-heart",
                    outcomes = {
                        {probability = 0.5, result = "realistic", description = "They adjust expectations. Progress!", effects = {}},
                        {probability = 0.5, result = "offended", description = "They're offended. Find a new agent.", effects = {happiness = 10}}
                    }
                },
                {
                    text = "Fire them as a client",
                    outcomes = {
                        {probability = 0.7, result = "relief", description = "Your time is worth more. Good riddance.", effects = {happiness = 15}},
                        {probability = 0.3, result = "bad_review", description = "They leave a bad review online.", effects = {reputation = -15}}
                    }
                }
            }
        },
        {
            id = "re_broker",
            name = "Become a Broker",
            description = "You have enough experience to get your broker license!",
            probability = 0.04,
            minYearsInJob = 3,
            requiresPerformance = 65,
            choices = {
                {
                    text = "Get your broker license",
                    outcomes = {
                        {probability = 0.7, result = "broker", description = "You're now a broker! Open your own office!", effects = {promoted = "Real Estate Broker", salaryIncrease = 30000}},
                        {probability = 0.3, result = "failed", description = "Failed the broker exam. Try again.", effects = {happiness = -10, money = -2000}}
                    }
                },
                {
                    text = "Stay as an agent",
                    outcomes = {
                        {probability = 1.0, result = "agent", description = "Less responsibility. That's okay.", effects = {}}
                    }
                }
            }
        },
        {
            id = "re_market_crash",
            name = "Market Downturn",
            description = "The housing market is crashing. Sales are down 50%.",
            probability = 0.04,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Pivot to rentals and distressed properties",
                    outcomes = {
                        {probability = 0.6, result = "adapted", description = "Smart pivot! Still making money!", effects = {money = 20000, reputation = 15}},
                        {probability = 0.4, result = "struggling", description = "Even those markets are tough.", effects = {money = 5000, stress = 20}}
                    }
                },
                {
                    text = "Wait out the downturn",
                    outcomes = {
                        {probability = 0.5, result = "survived", description = "Market recovers. You made it through.", effects = {}},
                        {probability = 0.5, result = "broke", description = "Savings depleted. Tough times.", effects = {money = -10000}}
                    }
                },
                {
                    text = "Find a different career",
                    outcomes = {
                        {probability = 0.5, result = "pivot", description = "Maybe real estate wasn't for you.", effects = {newCareerPath = "Career Change"}},
                        {probability = 0.5, result = "regret", description = "Market bounces back. You left too early.", effects = {happiness = -15}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Showed 5 houses today! Exhausting but productive.",
        "Offer accepted! Time for champagne!",
        "Buyer got cold feet. Deal fell through.",
        "Your marketing brought in 3 new leads!",
        "Negotiated $20k off for your buyer!",
        "Open house was packed! Great turnout.",
        "Client called at 11 PM with questions. Boundaries...",
        "Listing photos came out amazing!",
        "Lost a listing to another agent. Painful.",
        "Commission check cleared! Treating yourself.",
        "Home inspection found major issues. Stressful.",
        "First-time buyers are the most rewarding.",
        "Closing day! Everyone's smiling!",
        "Door-knocked 50 houses. 2 leads. Worth it?"
    }
}

-- PILOT
CareerData_Part5.Jobs["Airline Pilot"] = {
    id = "airline_pilot",
    title = "Airline Pilot",
    category = "Aviation",
    baseSalary = 130000,
    salaryRange = {80000, 350000},
    minAge = 23,
    maxAge = 65,
    requirement = "Bachelor's Degree",
    additionalRequirements = {"ATP License", "Flight Hours", "Medical Certificate"},
    requiredSkills = {Technical = 40, Analytical = 40},
    skillGains = {Technical = 2, Leadership = 2, Analytical = 2},
    description = "Fly commercial aircraft. See the world from 35,000 feet.",
    workEnvironment = "airplane",
    stressLevel = "varies",
    promotionPath = "Captain",
    
    careerEvents = {
        {
            id = "pilot_emergency",
            name = "In-Flight Emergency",
            description = "Engine failure at 30,000 feet! 200 passengers on board!",
            probability = 0.03,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Follow emergency procedures exactly",
                    outcomes = {
                        {probability = 0.8, result = "landed", description = "Emergency landing successful! Everyone survived! You're a hero!", effects = {fame = 30, reputation = 40, happiness = 25}},
                        {probability = 0.2, result = "rough", description = "Rough landing. Some injuries but everyone survived.", effects = {fame = 20, reputation = 30}}
                    }
                },
                {
                    text = "Trust your instincts",
                    outcomes = {
                        {probability = 0.5, result = "perfect", description = "Your instincts were right! Perfect emergency landing!", effects = {fame = 35, reputation = 45}},
                        {probability = 0.5, result = "close", description = "Too close. You got lucky.", effects = {fame = 15, stress = 30}}
                    }
                }
            }
        },
        {
            id = "pilot_captain",
            name = "Captain Upgrade",
            description = "You've been offered an upgrade to Captain!",
            probability = 0.05,
            minYearsInJob = 5,
            requiresPerformance = 70,
            choices = {
                {
                    text = "Accept the upgrade",
                    outcomes = {
                        {probability = 0.9, result = "captain", description = "Four stripes! You're now Captain!", effects = {promoted = "Captain", salaryIncrease = 80000}},
                        {probability = 0.1, result = "training", description = "More training required. Soon though.", effects = {technical = 3}}
                    }
                },
                {
                    text = "Stay as First Officer",
                    outcomes = {
                        {probability = 1.0, result = "comfortable", description = "Less responsibility. Still flying.", effects = {}}
                    }
                }
            }
        },
        {
            id = "pilot_medical",
            name = "Medical Issue",
            description = "Your medical certificate is at risk due to a health issue...",
            probability = 0.04,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Get treatment immediately",
                    outcomes = {
                        {probability = 0.7, result = "cleared", description = "Treatment works! Medical renewed!", effects = {health = 10}},
                        {probability = 0.3, result = "grounded", description = "Temporarily grounded. Could return.", effects = {money = -20000}}
                    }
                },
                {
                    text = "Hide it and hope it goes away",
                    outcomes = {
                        {probability = 0.2, result = "fine", description = "It cleared up on its own.", effects = {}},
                        {probability = 0.8, result = "discovered", description = "FAA finds out. Your career may be over.", effects = {fired = true}}
                    }
                }
            }
        },
        {
            id = "pilot_layover",
            name = "Layover Romance",
            description = "You keep seeing the same flight attendant on layovers...",
            probability = 0.05,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Ask them out",
                    outcomes = {
                        {probability = 0.6, result = "dating", description = "You're dating a fellow crew member! Love at 35,000 feet!", effects = {happiness = 25, relationship = true}},
                        {probability = 0.4, result = "awkward", description = "They're not interested. Awkward flights ahead.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Keep it professional",
                    outcomes = {
                        {probability = 0.8, result = "professional", description = "Boundaries are important.", effects = {}},
                        {probability = 0.2, result = "missed", description = "Turns out they liked you. Opportunity missed.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Smooth landing! Passengers applauded!",
        "Turbulence was rough today.",
        "Layover in Paris. Living the dream.",
        "Red-eye flight. Coffee is essential.",
        "The sunrise at altitude never gets old.",
        "Delayed 3 hours. Passengers are cranky.",
        "Flew over your hometown!",
        "Co-pilot and you make a great team.",
        "Weather diverted you to a different city.",
        "Simulator training. Stay sharp.",
        "First class gave you champagne. Perks!",
        "Jet lag is brutal this week.",
        "A kid came to see the cockpit. Their face!",
        "100,000 flight hours! Milestone!"
    }
}

-- YOUTUBE/CONTENT CREATOR
CareerData_Part5.Jobs["Content Creator"] = {
    id = "content_creator",
    title = "Content Creator",
    category = "Entertainment",
    baseSalary = 30000,
    salaryRange = {0, 10000000},
    minAge = 13,
    maxAge = nil,
    requirement = nil,
    requiredSkills = {Creative = 20},
    skillGains = {Creative = 3, Technical = 2, Social = 2, Charisma = 2},
    description = "Make videos, build an audience, hustle for views.",
    workEnvironment = "home",
    stressLevel = "varies",
    promotionPath = "Famous Creator",
    freelance = true,
    
    careerEvents = {
        {
            id = "yt_viral",
            name = "Video Goes Viral",
            description = "Your video is going VIRAL! Millions of views pouring in!",
            probability = 0.04,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Strike while it's hot - upload daily",
                    outcomes = {
                        {probability = 0.6, result = "momentum", description = "You kept the momentum! 1 million subscribers!", effects = {fame = 40, money = 100000, happiness = 40}},
                        {probability = 0.4, result = "burnout", description = "You burned out. Quality dropped. Views faded.", effects = {fame = 20, money = 30000, health = -15}}
                    }
                },
                {
                    text = "Stay true to your upload schedule",
                    outcomes = {
                        {probability = 0.5, result = "loyal", description = "Built a loyal audience. Sustainable growth!", effects = {fame = 25, money = 50000}},
                        {probability = 0.5, result = "missed", description = "Algorithm moved on. Missed your window.", effects = {fame = 15, money = 20000}}
                    }
                }
            }
        },
        {
            id = "yt_cancel",
            name = "Cancellation",
            description = "Something you said years ago resurfaced. Twitter is out for blood.",
            probability = 0.05,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Apologize sincerely",
                    outcomes = {
                        {probability = 0.5, result = "forgiven", description = "People accept your apology. Growth moment.", effects = {reputation = -10, karma = 5}},
                        {probability = 0.5, result = "not_enough", description = "Apology wasn't enough. Lost sponsors.", effects = {reputation = -30, money = -20000}}
                    }
                },
                {
                    text = "Defend yourself",
                    outcomes = {
                        {probability = 0.3, result = "vindicated", description = "Context matters! You're cleared!", effects = {reputation = 5}},
                        {probability = 0.7, result = "worse", description = "Doubling down made it worse.", effects = {reputation = -40, fame = -20}}
                    }
                },
                {
                    text = "Stay silent and wait it out",
                    outcomes = {
                        {probability = 0.6, result = "forgotten", description = "Internet moves on. You survived.", effects = {reputation = -5}},
                        {probability = 0.4, result = "assumed", description = "Silence seen as admission of guilt.", effects = {reputation = -20}}
                    }
                }
            }
        },
        {
            id = "yt_sponsor",
            name = "Sponsorship Deal",
            description = "A major brand offers $50,000 for one sponsored video!",
            probability = 0.07,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Take the deal",
                    outcomes = {
                        {probability = 0.6, result = "success", description = "Good integration. Fans didn't mind. Easy money!", effects = {money = 50000}},
                        {probability = 0.3, result = "backlash", description = "Fans accuse you of selling out.", effects = {money = 50000, reputation = -15}},
                        {probability = 0.1, result = "scam", description = "Brand doesn't pay. Lesson learned.", effects = {happiness = -15}}
                    }
                },
                {
                    text = "Negotiate for more",
                    outcomes = {
                        {probability = 0.4, result = "more", description = "They went to $75,000!", effects = {money = 75000}},
                        {probability = 0.6, result = "lost", description = "They went with someone else.", effects = {}}
                    }
                },
                {
                    text = "Decline - doesn't fit your brand",
                    outcomes = {
                        {probability = 0.7, result = "integrity", description = "Fans respect your integrity!", effects = {reputation = 10}},
                        {probability = 0.3, result = "regret", description = "That money would have been nice...", effects = {}}
                    }
                }
            }
        },
        {
            id = "yt_burnout",
            name = "Creator Burnout",
            description = "You haven't had a day off in months. The grind is killing you.",
            probability = 0.08,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Take a break",
                    outcomes = {
                        {probability = 0.6, result = "recharged", description = "Break was needed! Came back better than ever!", effects = {health = 15, happiness = 20}},
                        {probability = 0.4, result = "lost_subs", description = "Algorithm punished your absence. Lost subscribers.", effects = {health = 15, fame = -10}}
                    }
                },
                {
                    text = "Push through",
                    outcomes = {
                        {probability = 0.3, result = "survived", description = "You made it through the slump.", effects = {}},
                        {probability = 0.7, result = "collapse", description = "You broke down. Extended hiatus needed.", effects = {health = -25, happiness = -20}}
                    }
                },
                {
                    text = "Hire help",
                    outcomes = {
                        {probability = 0.7, result = "sustainable", description = "Editor and manager make it sustainable!", effects = {money = -30000, happiness = 15}},
                        {probability = 0.3, result = "expensive", description = "Good help is expensive. Margins shrink.", effects = {money = -50000}}
                    }
                }
            }
        },
        {
            id = "yt_meetup",
            name = "Fan Event",
            description = "You're hosting your first fan meetup! 500 people signed up!",
            probability = 0.05,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Meet everyone personally",
                    outcomes = {
                        {probability = 0.8, result = "amazing", description = "Fans are crying tears of joy! Best day ever!", effects = {happiness = 30, reputation = 20}},
                        {probability = 0.2, result = "overwhelmed", description = "Overwhelming. Social battery drained.", effects = {happiness = 10, stress = 20}}
                    }
                },
                {
                    text = "Keep it short and structured",
                    outcomes = {
                        {probability = 0.6, result = "smooth", description = "Professional event. Everyone had fun!", effects = {reputation = 15}},
                        {probability = 0.4, result = "impersonal", description = "Some fans wanted more personal time.", effects = {reputation = 5}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Uploaded a video! Checking analytics obsessively.",
        "10,000 subscribers! Milestone!",
        "Negative comment hit different today.",
        "Editing took 12 hours. That transition though...",
        "Collab video with a bigger creator!",
        "Brand reached out for partnership!",
        "Algorithm screwed you. Views are down.",
        "Fan art in the comments. So wholesome!",
        "Bought a better camera. Investment!",
        "Trending page! You made it!",
        "Comment section is wholesome today.",
        "Thumbnail A/B testing worked!",
        "Your favorite creator watched your video!",
        "Demonetized for unknown reasons. Appealing..."
    }
}

return CareerData_Part5
