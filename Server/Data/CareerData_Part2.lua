-- CareerData Part 2: Trades, Office, and Technology Careers
-- Each career has SPECIFIC events that only happen in THAT career

local CareerData_Part2 = {}

--============================================================================
-- TRADES CAREERS
--============================================================================

-- ELECTRICIAN
CareerData_Part2.Jobs = {}

CareerData_Part2.Jobs["Electrician Apprentice"] = {
    id = "electrician_apprentice",
    title = "Electrician Apprentice",
    category = "Trades",
    baseSalary = 32000,
    salaryRange = {28000, 38000},
    minAge = 18,
    maxAge = nil,
    requirement = "High School",
    requiredSkills = {},
    skillGains = {Technical = 2, Mechanical = 1, Physical = 1},
    description = "Learn the trade while carrying tools and pulling wire.",
    workEnvironment = "construction",
    stressLevel = "medium",
    promotionPath = "Journeyman Electrician",
    
    careerEvents = {
        {
            id = "elec_shock",
            name = "Electrical Shock",
            description = "You touched a live wire! Electricity courses through you!",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Let go and step back",
                    outcomes = {
                        {probability = 0.7, result = "minor", description = "A scary shock but you're okay.", effects = {health = -10, stress = 15}},
                        {probability = 0.3, result = "burn", description = "Entry and exit burns on your hands.", effects = {health = -25}}
                    }
                },
                {
                    text = "Call for help immediately",
                    outcomes = {
                        {probability = 0.9, result = "helped", description = "Coworker cuts the power. You're safe.", effects = {health = -5}},
                        {probability = 0.1, result = "serious", description = "Had to go to the hospital for monitoring.", effects = {health = -20}}
                    }
                }
            }
        },
        {
            id = "elec_mentor",
            name = "Journeyman's Wisdom",
            description = "Your journeyman mentor offers to teach you a special technique after hours.",
            probability = 0.08,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Stay late and learn",
                    outcomes = {
                        {probability = 0.9, result = "learn", description = "You learned valuable techniques! Skill improved.", effects = {technical = 3, mechanical = 2}},
                        {probability = 0.1, result = "tired", description = "Learned a lot but you're exhausted.", effects = {technical = 2, health = -5}}
                    }
                },
                {
                    text = "Decline - you have plans",
                    outcomes = {
                        {probability = 0.5, result = "fine", description = "They understand.", effects = {}},
                        {probability = 0.5, result = "missed", description = "You missed out on valuable knowledge.", effects = {}}
                    }
                }
            }
        },
        {
            id = "elec_inspection",
            name = "Surprise Inspection",
            description = "City inspector just showed up! Is your work up to code?",
            probability = 0.07,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Confidently show your work",
                    outcomes = {
                        {probability = 0.6, result = "pass", description = "Everything's up to code! Inspector impressed.", effects = {reputation = 15}},
                        {probability = 0.4, result = "minor_issues", description = "A few minor issues to fix. Not bad for an apprentice.", effects = {technical = 1}}
                    }
                },
                {
                    text = "Get your journeyman to handle it",
                    outcomes = {
                        {probability = 0.8, result = "handled", description = "Journeyman takes over. Pass!", effects = {}},
                        {probability = 0.2, result = "blamed", description = "Some of your work fails. You get blamed.", effects = {reputation = -10}}
                    }
                }
            }
        },
        {
            id = "elec_dangerous_order",
            name = "Unsafe Order",
            description = "Contractor wants you to skip safety protocols to save time.",
            probability = 0.05,
            minYearsInJob = 0.2,
            choices = {
                {
                    text = "Refuse - safety first",
                    outcomes = {
                        {probability = 0.6, result = "respected", description = "Your journeyman backs you up. Good call.", effects = {reputation = 10}},
                        {probability = 0.4, result = "tension", description = "Contractor is pissed but can't fire you for safety.", effects = {stress = 10}}
                    }
                },
                {
                    text = "Follow the order",
                    outcomes = {
                        {probability = 0.5, result = "fine", description = "Nothing bad happens this time...", effects = {}},
                        {probability = 0.3, result = "injury", description = "You get hurt. Should've said no.", effects = {health = -30}},
                        {probability = 0.2, result = "caught", description = "Inspector finds the violation. Huge fine.", effects = {reputation = -25}}
                    }
                }
            }
        },
        {
            id = "elec_licensing_exam",
            name = "Licensing Opportunity",
            description = "You have enough hours to take your journeyman exam!",
            probability = 0.04,
            minYearsInJob = 2,
            requiresPerformance = 50,
            choices = {
                {
                    text = "Take the exam",
                    outcomes = {
                        {probability = 0.6, result = "pass", description = "You passed! You're a licensed Journeyman Electrician!", effects = {promoted = "Journeyman Electrician", salaryIncrease = 15000}},
                        {probability = 0.4, result = "fail", description = "Failed by 2 points. You can retake in 30 days.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Study more first",
                    outcomes = {
                        {probability = 1.0, result = "study", description = "You decide to study more before the exam.", effects = {technical = 2}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Pulled wire through conduit for 8 hours. Arms are noodles.",
        "Your journeyman taught you a new wiring technique.",
        "The foreman yelled at everyone. Fun times.",
        "You dropped your wire strippers from 20 feet up.",
        "Free lunch on the job site today!",
        "The blueprints were wrong. Had to redo everything.",
        "Someone didn't tag out the breaker. Close call.",
        "Your tool pouch is getting heavy.",
        "Finally mastered the bend radius calculation!",
        "The other apprentice keeps asking you for help.",
        "Got sawdust in places sawdust should never be.",
        "Your boots are falling apart already.",
        "The new building is starting to look like something!"
    }
}

CareerData_Part2.Jobs["Journeyman Electrician"] = {
    id = "journeyman_electrician",
    title = "Journeyman Electrician",
    category = "Trades",
    baseSalary = 55000,
    salaryRange = {45000, 70000},
    minAge = 22,
    maxAge = nil,
    requirement = "Electrician License",
    requiredSkills = {Technical = 30, Mechanical = 20},
    skillGains = {Technical = 2, Mechanical = 2, Leadership = 1},
    description = "Licensed electrician handling complex installations.",
    workEnvironment = "construction",
    stressLevel = "medium",
    promotionPath = "Master Electrician",
    
    careerEvents = {
        {
            id = "jour_apprentice_injury",
            name = "Apprentice Injury",
            description = "Your apprentice just got shocked because they didn't follow your instructions!",
            probability = 0.05,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Take full responsibility",
                    outcomes = {
                        {probability = 0.6, result = "respected", description = "Apprentice is okay. Your responsibility earns respect.", effects = {reputation = 10, leadership = 2}},
                        {probability = 0.4, result = "write_up", description = "You get written up but kept your integrity.", effects = {reputation = -5, leadership = 1}}
                    }
                },
                {
                    text = "Document that they ignored instructions",
                    outcomes = {
                        {probability = 0.7, result = "protected", description = "Paperwork shows you followed protocol.", effects = {}},
                        {probability = 0.3, result = "blamed", description = "Company still blames the journeyman.", effects = {reputation = -10}}
                    }
                }
            }
        },
        {
            id = "jour_side_job",
            name = "Side Job Offer",
            description = "A homeowner offers you $2000 cash to do some work on the side!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Take the side job",
                    outcomes = {
                        {probability = 0.7, result = "paid", description = "Easy money! Weekend well spent.", effects = {money = 2000}},
                        {probability = 0.2, result = "liability", description = "Something goes wrong. No insurance for side work...", effects = {money = -1000}},
                        {probability = 0.1, result = "caught", description = "Your company finds out. You're in trouble.", effects = {reputation = -20}}
                    }
                },
                {
                    text = "Decline - too risky",
                    outcomes = {
                        {probability = 1.0, result = "safe", description = "Better safe than sorry. Your license is worth more.", effects = {}}
                    }
                },
                {
                    text = "Refer them to your company",
                    outcomes = {
                        {probability = 0.8, result = "referral", description = "You get a referral bonus!", effects = {money = 200, reputation = 5}},
                        {probability = 0.2, result = "no_sale", description = "They decide not to hire anyone.", effects = {}}
                    }
                }
            }
        },
        {
            id = "jour_union_strike",
            name = "Strike Vote",
            description = "The union is voting on whether to strike for better wages!",
            probability = 0.03,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Vote yes for the strike",
                    outcomes = {
                        {probability = 0.5, result = "win", description = "Strike succeeds! 10% raise for everyone!", effects = {salaryIncrease = 5500}},
                        {probability = 0.5, result = "lose", description = "Strike fails. Back to work with nothing.", effects = {happiness = -10, money = -2000}}
                    }
                },
                {
                    text = "Vote no",
                    outcomes = {
                        {probability = 0.6, result = "work", description = "Strike doesn't pass. Business as usual.", effects = {}},
                        {probability = 0.4, result = "labeled", description = "Word gets out you voted no. Union brothers are cold.", effects = {reputation = -15}}
                    }
                }
            }
        },
        {
            id = "jour_commercial_job",
            name = "Huge Commercial Job",
            description = "You've been assigned lead electrician on a $2 million commercial project!",
            probability = 0.06,
            minYearsInJob = 1,
            requiresPerformance = 60,
            choices = {
                {
                    text = "Accept with confidence",
                    outcomes = {
                        {probability = 0.7, result = "success", description = "Project completed on time and under budget! Huge bonus!", effects = {money = 5000, reputation = 25, promotionProgress = 20}},
                        {probability = 0.3, result = "issues", description = "Hit some snags but pulled through.", effects = {reputation = 10, stress = 20}}
                    }
                },
                {
                    text = "Request more support",
                    outcomes = {
                        {probability = 0.6, result = "granted", description = "They give you extra apprentices. Smart ask.", effects = {reputation = 5}},
                        {probability = 0.4, result = "denied", description = "Budget's tight. Figure it out.", effects = {stress = 15}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Your apprentice actually did something right today!",
        "The general contractor changed the plans again.",
        "Troubleshot a weird flickering issue. Nailed it.",
        "Your knees are starting to complain about all the kneeling.",
        "Successfully pulled 500 feet of wire through conduit.",
        "The inspector passed everything first try!",
        "Someone used the wrong gauge wire. Had to redo it all.",
        "Your tool belt is worth more than some people's cars.",
        "Night shift emergency call. Double pay though!",
        "Another electrician asked for YOUR advice. Feels good."
    }
}

-- PLUMBER
CareerData_Part2.Jobs["Plumber"] = {
    id = "plumber",
    title = "Plumber",
    category = "Trades",
    baseSalary = 52000,
    salaryRange = {40000, 75000},
    minAge = 18,
    maxAge = nil,
    requirement = "High School",
    requiredSkills = {},
    skillGains = {Technical = 2, Mechanical = 2, Physical = 1},
    description = "Fix pipes, unclog drains, and see things you can't unsee.",
    workEnvironment = "various",
    stressLevel = "medium",
    promotionPath = "Master Plumber",
    
    careerEvents = {
        {
            id = "plumb_sewage",
            name = "Sewage Nightmare",
            description = "A sewage line burst. It's EVERYWHERE. The smell is ungodly.",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Suit up and get to work",
                    outcomes = {
                        {probability = 0.8, result = "done", description = "Worst job ever but you fixed it. Extra hazard pay!", effects = {money = 200, happiness = -10, physical = 1}},
                        {probability = 0.2, result = "sick", description = "You got sick from exposure.", effects = {money = 200, health = -15}}
                    }
                },
                {
                    text = "Insist on proper hazmat equipment",
                    outcomes = {
                        {probability = 0.7, result = "equipped", description = "Company provides gear. Safer job.", effects = {money = 200}},
                        {probability = 0.3, result = "delay", description = "Delayed getting equipment. Customer complains.", effects = {reputation = -5, money = 200}}
                    }
                },
                {
                    text = "Say it's above your pay grade",
                    outcomes = {
                        {probability = 0.3, result = "specialist", description = "They call a specialist. Not your problem.", effects = {}},
                        {probability = 0.7, result = "ordered", description = "Boss says you're doing it. No choice.", effects = {stress = 15}}
                    }
                }
            }
        },
        {
            id = "plumb_found_treasure",
            name = "Found in the Pipes",
            description = "While snaking a drain, you pull up a diamond ring!",
            probability = 0.03,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Return it to the homeowner",
                    outcomes = {
                        {probability = 0.8, result = "reward", description = "They're SO grateful! Big tip and glowing review!", effects = {money = 300, reputation = 20, happiness = 15}},
                        {probability = 0.2, result = "thanks", description = "They thank you. That's it.", effects = {happiness = 5, karma = 10}}
                    }
                },
                {
                    text = "Pocket it - finders keepers",
                    outcomes = {
                        {probability = 0.5, result = "kept", description = "Worth $5000! They'll never know.", effects = {money = 5000, karma = -25}},
                        {probability = 0.5, result = "caught", description = "They saw it on the camera! Police called.", effects = {arrested = true, fired = true}}
                    }
                }
            }
        },
        {
            id = "plumb_emergency_call",
            name = "Midnight Emergency",
            description = "It's 2 AM. A burst pipe is flooding someone's basement!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Rush over immediately",
                    outcomes = {
                        {probability = 0.8, result = "hero", description = "You saved their house! Emergency rate plus huge tip!", effects = {money = 500, reputation = 15}},
                        {probability = 0.2, result = "worse", description = "It was worse than expected. Long night.", effects = {money = 500, health = -10, stress = 15}}
                    }
                },
                {
                    text = "Tell them to shut off water main and come in the morning",
                    outcomes = {
                        {probability = 0.5, result = "fine", description = "They manage until morning. Job done in daylight.", effects = {money = 200}},
                        {probability = 0.5, result = "damage", description = "More damage by morning. They're upset.", effects = {money = 200, reputation = -10}}
                    }
                }
            }
        },
        {
            id = "plumb_toilet_horror",
            name = "Toilet Horror",
            description = "You've seen some things. But what's clogging this toilet is... different.",
            probability = 0.07,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Just get it done. Don't think about it.",
                    outcomes = {
                        {probability = 0.9, result = "done", description = "It's out. You need therapy.", effects = {happiness = -5}},
                        {probability = 0.1, result = "weird", description = "Was that a... never mind. Some questions are better unasked.", effects = {}}
                    }
                },
                {
                    text = "Ask the customer what the hell happened",
                    outcomes = {
                        {probability = 0.3, result = "explanation", description = "They explain. You wish they hadn't.", effects = {happiness = -10}},
                        {probability = 0.7, result = "embarrassed", description = "They're too embarrassed to answer.", effects = {}}
                    }
                }
            }
        },
        {
            id = "plumb_contractor_license",
            name = "Start Your Own Business?",
            description = "You have enough experience to get your contractor license and start your own business!",
            probability = 0.04,
            minYearsInJob = 3,
            requiresPerformance = 70,
            choices = {
                {
                    text = "Go for it - start your own plumbing company",
                    outcomes = {
                        {probability = 0.6, result = "success", description = "Your own business! It's scary but exciting!", effects = {promoted = "Plumbing Contractor (Owner)", salaryIncrease = 30000, stress = 20}},
                        {probability = 0.4, result = "struggle", description = "Starting is tough. You're working twice as hard.", effects = {promoted = "Plumbing Contractor (Owner)", stress = 30}}
                    }
                },
                {
                    text = "Stay employed - less risk",
                    outcomes = {
                        {probability = 1.0, result = "safe", description = "Steady paycheck. Nothing wrong with that.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Unclogged a drain with your bare hands. Had gloves though.",
        "The customer tried to explain how to do your job.",
        "Found a toy dinosaur blocking a toilet. Kids.",
        "Your van smells like PVC glue now. Forever.",
        "Got a 5-star review! Worth the sewage.",
        "The water heater practically exploded when you touched it.",
        "Someone flushed an entire roll of paper towels.",
        "Crawled under a house. So many spiders.",
        "Perfect solder joint on the first try!",
        "The customer made you coffee. The little things.",
        "Your back is killing you from bending all day.",
        "Found $20 in a drain. Kept it.",
        "The homeowner asked if you did 'electrical too'. No."
    }
}

-- CARPENTER
CareerData_Part2.Jobs["Carpenter"] = {
    id = "carpenter",
    title = "Carpenter",
    category = "Trades",
    baseSalary = 45000,
    salaryRange = {35000, 65000},
    minAge = 18,
    maxAge = nil,
    requirement = nil,
    requiredSkills = {},
    skillGains = {Technical = 2, Physical = 2, Creative = 1},
    description = "Build things with wood. From houses to furniture.",
    workEnvironment = "construction",
    stressLevel = "medium",
    promotionPath = "Master Carpenter",
    
    careerEvents = {
        {
            id = "carp_nail_gun",
            name = "Nail Gun Incident",
            description = "The nail gun misfires!",
            probability = 0.05,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Assess the damage",
                    outcomes = {
                        {probability = 0.6, result = "miss", description = "Missed you completely. That was close!", effects = {stress = 15}},
                        {probability = 0.3, result = "graze", description = "Grazed your arm. Minor wound.", effects = {health = -10}},
                        {probability = 0.1, result = "hit", description = "Nail went into your leg. Hospital trip.", effects = {health = -30}}
                    }
                }
            }
        },
        {
            id = "carp_custom_furniture",
            name = "Custom Furniture Commission",
            description = "A wealthy client wants you to build a custom dining table for $3000!",
            probability = 0.06,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Accept the commission",
                    outcomes = {
                        {probability = 0.7, result = "masterpiece", description = "The table is beautiful! They're thrilled and refer friends!", effects = {money = 3000, reputation = 20, creative = 2}},
                        {probability = 0.3, result = "acceptable", description = "It's good but not your best work.", effects = {money = 3000}}
                    }
                },
                {
                    text = "Negotiate for more",
                    outcomes = {
                        {probability = 0.4, result = "more_money", description = "They agree to $4000!", effects = {money = 4000, reputation = 15}},
                        {probability = 0.6, result = "lost", description = "They find someone cheaper.", effects = {}}
                    }
                }
            }
        },
        {
            id = "carp_splinter",
            name = "The Mother of All Splinters",
            description = "A MASSIVE splinter lodges deep in your hand!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Dig it out yourself",
                    outcomes = {
                        {probability = 0.6, result = "got_it", description = "Got it! Manly as hell.", effects = {health = -5}},
                        {probability = 0.4, result = "worse", description = "Broke it off inside. Now it's infected.", effects = {health = -15}}
                    }
                },
                {
                    text = "Go to urgent care",
                    outcomes = {
                        {probability = 0.9, result = "removed", description = "Professional removal. Good as new.", effects = {money = -100}},
                        {probability = 0.1, result = "deep", description = "Deeper than expected. Minor surgery needed.", effects = {money = -500, health = -10}}
                    }
                },
                {
                    text = "Ignore it and keep working",
                    outcomes = {
                        {probability = 0.3, result = "fine", description = "It works itself out eventually.", effects = {}},
                        {probability = 0.7, result = "infection", description = "Major infection. Hand swells up.", effects = {health = -25, money = -300}}
                    }
                }
            }
        },
        {
            id = "carp_measurement",
            name = "Measure Twice, Cut Once... Or Not",
            description = "You cut expensive hardwood too short! It's ruined!",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Admit the mistake to your boss",
                    outcomes = {
                        {probability = 0.6, result = "understanding", description = "Happens to everyone. Just don't do it again.", effects = {reputation = -5}},
                        {probability = 0.4, result = "pay", description = "Boss makes you pay for the wood.", effects = {money = -200, reputation = -10}}
                    }
                },
                {
                    text = "Try to make it work somehow",
                    outcomes = {
                        {probability = 0.3, result = "creative", description = "You made it work! Problem-solving!", effects = {creative = 2}},
                        {probability = 0.7, result = "obvious", description = "Everyone can tell. Looks bad.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Blame the wrong measurement on the plans",
                    outcomes = {
                        {probability = 0.4, result = "believed", description = "They check. Plans were wrong! Not your fault!", effects = {}},
                        {probability = 0.6, result = "caught", description = "Plans were right. You're a liar.", effects = {reputation = -20}}
                    }
                }
            }
        },
        {
            id = "carp_hgtv",
            name = "TV Show Opportunity",
            description = "A home renovation show wants to feature your carpentry work!",
            probability = 0.02,
            minYearsInJob = 2,
            requiresPerformance = 70,
            choices = {
                {
                    text = "Appear on the show",
                    outcomes = {
                        {probability = 0.7, result = "famous", description = "Episode airs! Business triples!", effects = {fame = 10, reputation = 30, money = 5000}},
                        {probability = 0.3, result = "edited_bad", description = "They edited you to look incompetent.", effects = {reputation = -10, happiness = -15}}
                    }
                },
                {
                    text = "Decline - too much pressure",
                    outcomes = {
                        {probability = 1.0, result = "pass", description = "Fame isn't for everyone.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Perfect dovetail joint on the first try!",
        "Sawdust is in every crevice of your body.",
        "The client changed their mind three times today.",
        "Your table saw is your best friend.",
        "Got a splinter. Another one. Always splinters.",
        "Built something you're genuinely proud of!",
        "The wood grain on this piece is gorgeous.",
        "Spent an hour sanding. Arms are jello.",
        "The apprentice kept the tape measure. Again.",
        "Client asked if you could 'just make it bigger'. Not how wood works.",
        "Finished the deck! It's beautiful!",
        "Power went out. Hand tools it is.",
        "Your workshop smells amazing. Fresh cut pine."
    }
}

--============================================================================
-- OFFICE CAREERS
--============================================================================

-- RECEPTIONIST
CareerData_Part2.Jobs["Receptionist"] = {
    id = "receptionist",
    title = "Receptionist",
    category = "Office",
    baseSalary = 30000,
    salaryRange = {26000, 38000},
    minAge = 18,
    maxAge = nil,
    requirement = "High School",
    requiredSkills = {},
    skillGains = {Social = 2, Analytical = 1},
    description = "The face of the company. First impression matters.",
    workEnvironment = "office",
    stressLevel = "medium",
    promotionPath = "Office Manager",
    
    careerEvents = {
        {
            id = "recep_vip_arrival",
            name = "VIP Arrival",
            description = "A MAJOR client just walked in and you have no idea who they are!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Treat them like any visitor",
                    outcomes = {
                        {probability = 0.4, result = "fine", description = "They didn't mind being treated normally.", effects = {}},
                        {probability = 0.6, result = "offended", description = "They're offended. Your boss is NOT happy.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Quickly check the visitor schedule",
                    outcomes = {
                        {probability = 0.7, result = "found", description = "Found them! Roll out the red carpet treatment!", effects = {reputation = 10}},
                        {probability = 0.3, result = "unscheduled", description = "They're not on the schedule! Wing it!", effects = {stress = 10}}
                    }
                },
                {
                    text = "Stall while texting your boss",
                    outcomes = {
                        {probability = 0.5, result = "saved", description = "Boss gives you the heads up just in time!", effects = {reputation = 5}},
                        {probability = 0.5, result = "obvious", description = "Your stalling is obvious and awkward.", effects = {reputation = -5}}
                    }
                }
            }
        },
        {
            id = "recep_angry_visitor",
            name = "Irate Visitor",
            description = "Someone is FURIOUS about their appointment being cancelled!",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "De-escalate with empathy",
                    outcomes = {
                        {probability = 0.7, result = "calmed", description = "You calm them down. Crisis averted.", effects = {reputation = 10, social = 1}},
                        {probability = 0.3, result = "still_angry", description = "Nothing works. They leave a bad review.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Call security",
                    outcomes = {
                        {probability = 0.6, result = "removed", description = "Security escorts them out.", effects = {}},
                        {probability = 0.4, result = "scene", description = "They make a huge scene before leaving.", effects = {stress = 20}}
                    }
                },
                {
                    text = "Blame it on someone else",
                    outcomes = {
                        {probability = 0.5, result = "deflected", description = "They redirect anger elsewhere.", effects = {}},
                        {probability = 0.5, result = "backfire", description = "That person finds out you threw them under the bus.", effects = {reputation = -15}}
                    }
                }
            }
        },
        {
            id = "recep_office_gossip",
            name = "Juicy Gossip",
            description = "You overheard that two executives are having an affair!",
            probability = 0.04,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Keep it to yourself",
                    outcomes = {
                        {probability = 0.8, result = "professional", description = "Professional discretion. The right call.", effects = {karma = 5}},
                        {probability = 0.2, result = "explodes", description = "It comes out anyway. At least you weren't the leak.", effects = {}}
                    }
                },
                {
                    text = "Tell your work bestie",
                    outcomes = {
                        {probability = 0.4, result = "secret", description = "They keep the secret. Fun shared gossip.", effects = {happiness = 5}},
                        {probability = 0.6, result = "spread", description = "It spreads. Someone traces it back to you.", effects = {reputation = -20}}
                    }
                },
                {
                    text = "Anonymously tip HR",
                    outcomes = {
                        {probability = 0.5, result = "investigated", description = "HR investigates quietly.", effects = {}},
                        {probability = 0.5, result = "nothing", description = "HR does nothing. Office politics.", effects = {}}
                    }
                }
            }
        },
        {
            id = "recep_flowers_delivery",
            name = "Mysterious Flowers",
            description = "Beautiful flowers arrive for you at work! No card says who they're from.",
            probability = 0.03,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Ask around to find out who sent them",
                    outcomes = {
                        {probability = 0.5, result = "admirer", description = "Turns out someone in the office has a crush!", effects = {happiness = 15}},
                        {probability = 0.3, result = "partner", description = "It was your partner being romantic!", effects = {happiness = 20}},
                        {probability = 0.2, result = "wrong_person", description = "They were for someone else. Wrong address.", effects = {happiness = -5}}
                    }
                },
                {
                    text = "Enjoy the mystery",
                    outcomes = {
                        {probability = 1.0, result = "enjoy", description = "Some mysteries make life interesting.", effects = {happiness = 10}}
                    }
                }
            }
        },
        {
            id = "recep_promotion",
            name = "Office Manager Opening",
            description = "The office manager is leaving! You're being considered for the role.",
            probability = 0.05,
            minYearsInJob = 1,
            requiresPerformance = 60,
            choices = {
                {
                    text = "Actively campaign for it",
                    outcomes = {
                        {probability = 0.6, result = "promoted", description = "You got the promotion! Office Manager!", effects = {promoted = "Office Manager", salaryIncrease = 12000}},
                        {probability = 0.4, result = "passed", description = "They went with someone else.", effects = {happiness = -15}}
                    }
                },
                {
                    text = "Let your work speak for itself",
                    outcomes = {
                        {probability = 0.4, result = "promoted", description = "Your track record earned it!", effects = {promoted = "Office Manager", salaryIncrease = 12000}},
                        {probability = 0.6, result = "overlooked", description = "The squeaky wheel got the grease.", effects = {happiness = -10}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "The phone has been ringing non-stop.",
        "Someone left candy on your desk!",
        "Had to explain how to use the printer. Again.",
        "The CEO remembered your name!",
        "A delivery person was really cute.",
        "Office supplies are mysteriously disappearing.",
        "You know everyone's birthday by heart now.",
        "Someone's loud phone call is driving you crazy.",
        "Free lunch brought in for a meeting!",
        "The plant on your desk died. Rest in peace.",
        "You've become the unofficial IT support.",
        "Caught someone trying to sneak past without signing in.",
        "The office dog came to visit!",
        "Your desk is impeccably organized. Marie Kondo approved."
    }
}

-- DATA ENTRY CLERK
CareerData_Part2.Jobs["Data Entry Clerk"] = {
    id = "data_entry_clerk",
    title = "Data Entry Clerk",
    category = "Office",
    baseSalary = 32000,
    salaryRange = {28000, 40000},
    minAge = 18,
    maxAge = nil,
    requirement = "High School",
    requiredSkills = {},
    skillGains = {Analytical = 2, Technical = 1},
    description = "Type data into spreadsheets. All day. Every day.",
    workEnvironment = "office",
    stressLevel = "low",
    promotionPath = "Data Analyst",
    
    careerEvents = {
        {
            id = "data_massive_error",
            name = "The Spreadsheet Disaster",
            description = "You just realized you've been entering data in the wrong column for 3 DAYS!",
            probability = 0.07,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Come clean immediately",
                    outcomes = {
                        {probability = 0.5, result = "forgiven", description = "Mistakes happen. They appreciate your honesty.", effects = {reputation = -5}},
                        {probability = 0.5, result = "trouble", description = "Three days of work wasted. Not good.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Fix it yourself overnight",
                    outcomes = {
                        {probability = 0.6, result = "fixed", description = "You stayed until 2 AM but fixed it all!", effects = {stress = 20}},
                        {probability = 0.4, result = "more_errors", description = "Tired mistakes lead to MORE errors.", effects = {reputation = -20}}
                    }
                },
                {
                    text = "Hope no one notices",
                    outcomes = {
                        {probability = 0.2, result = "unnoticed", description = "Somehow no one caught it...", effects = {}},
                        {probability = 0.8, result = "caught", description = "Audit catches it. Everyone knows.", effects = {reputation = -25}}
                    }
                }
            }
        },
        {
            id = "data_automation",
            name = "Automation Opportunity",
            description = "You realize you could automate 80% of your job with a simple script...",
            probability = 0.05,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Propose the automation to your boss",
                    outcomes = {
                        {probability = 0.5, result = "promoted", description = "They're impressed! You get to lead the automation project!", effects = {reputation = 25, promotionProgress = 20}},
                        {probability = 0.3, result = "implemented", description = "Good idea but someone else implements it.", effects = {reputation = 10}},
                        {probability = 0.2, result = "fired", description = "They automate the job. And then lay you off.", effects = {fired = true}}
                    }
                },
                {
                    text = "Automate secretly and enjoy free time",
                    outcomes = {
                        {probability = 0.6, result = "easy_life", description = "You do 1 hour of work and get paid for 8. Living the dream.", effects = {happiness = 20, stress = -20}},
                        {probability = 0.4, result = "discovered", description = "IT finds your scripts. Awkward conversation.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Keep things the way they are",
                    outcomes = {
                        {probability = 1.0, result = "status_quo", description = "Job security in doing things the old way.", effects = {}}
                    }
                }
            }
        },
        {
            id = "data_carpal_tunnel",
            name = "Wrist Pain",
            description = "Your wrists are really hurting from all the typing...",
            probability = 0.08,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Request ergonomic equipment",
                    outcomes = {
                        {probability = 0.7, result = "approved", description = "New ergonomic keyboard and mouse! Much better.", effects = {health = 5}},
                        {probability = 0.3, result = "denied", description = "Budget doesn't cover it.", effects = {}}
                    }
                },
                {
                    text = "See a doctor",
                    outcomes = {
                        {probability = 0.8, result = "diagnosed", description = "Early carpal tunnel. Physical therapy helps.", effects = {health = -5, money = -200}},
                        {probability = 0.2, result = "serious", description = "You need surgery if you don't change habits.", effects = {health = -15, money = -500}}
                    }
                },
                {
                    text = "Push through the pain",
                    outcomes = {
                        {probability = 0.3, result = "fine", description = "It goes away on its own.", effects = {}},
                        {probability = 0.7, result = "worse", description = "It gets much worse. Now you need medical leave.", effects = {health = -25}}
                    }
                }
            }
        },
        {
            id = "data_speed_record",
            name = "Typing Speed Challenge",
            description = "Your office is having a typing speed competition!",
            probability = 0.04,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Go all out to win",
                    outcomes = {
                        {probability = 0.4, result = "win", description = "120 WPM! You win! $50 gift card!", effects = {money = 50, reputation = 10, happiness = 15}},
                        {probability = 0.4, result = "place", description = "Top 3! Not bad!", effects = {happiness = 5}},
                        {probability = 0.2, result = "choke", description = "You choke under pressure.", effects = {happiness = -5}}
                    }
                },
                {
                    text = "Don't participate",
                    outcomes = {
                        {probability = 1.0, result = "skip", description = "You sit this one out.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Entered 500 records today. New personal best!",
        "Your eyes are strained from staring at spreadsheets.",
        "The keyboard is disgusting. When was it last cleaned?",
        "You can type without looking now. Muscle memory.",
        "Spotify playlist made the day go faster.",
        "Found a duplicate entry from 2019.",
        "Your coworker's keyboard is SO LOUD.",
        "Free coffee in the break room!",
        "The data today made no sense. Garbage in, garbage out.",
        "You zoned out and typed the same thing twice.",
        "Excel crashed. Lost an hour of work.",
        "Discovered a shortcut that saves 2 seconds per entry.",
        "The AC is freezing. Your fingers are numb.",
        "Someone complimented your accuracy rate!"
    }
}

--============================================================================
-- TECHNOLOGY CAREERS
--============================================================================

-- JUNIOR SOFTWARE DEVELOPER
CareerData_Part2.Jobs["Junior Developer"] = {
    id = "junior_developer",
    title = "Junior Software Developer",
    category = "Technology",
    baseSalary = 65000,
    salaryRange = {55000, 80000},
    minAge = 18,
    maxAge = nil,
    requirement = "Bachelor's Degree",
    alternateRequirement = "Coding Bootcamp",
    requiredSkills = {Technical = 20},
    skillGains = {Technical = 3, Analytical = 2},
    description = "Write code, break things, fix things, repeat.",
    workEnvironment = "office",
    stressLevel = "medium",
    promotionPath = "Software Developer",
    
    careerEvents = {
        {
            id = "dev_production_down",
            name = "Production is DOWN!",
            description = "Your code change just crashed production! Millions of users affected!",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Immediately try to fix it",
                    outcomes = {
                        {probability = 0.4, result = "hero", description = "You found and fixed the bug! Crisis averted!", effects = {reputation = 15, technical = 2}},
                        {probability = 0.4, result = "made_worse", description = "You made it worse. Senior dev has to step in.", effects = {reputation = -10, stress = 25}},
                        {probability = 0.2, result = "panic", description = "You froze up. Others fixed it.", effects = {reputation = -5, stress = 20}}
                    }
                },
                {
                    text = "Roll back your changes",
                    outcomes = {
                        {probability = 0.8, result = "rollback", description = "Rollback successful! Site is back up!", effects = {stress = 15}},
                        {probability = 0.2, result = "cant_rollback", description = "Database migrations make rollback impossible.", effects = {stress = 30}}
                    }
                },
                {
                    text = "Alert the team and ask for help",
                    outcomes = {
                        {probability = 0.9, result = "team_fix", description = "Team rallies together and fixes it!", effects = {reputation = 5, stress = 15}},
                        {probability = 0.1, result = "blame", description = "Everyone knows it was your code.", effects = {reputation = -15}}
                    }
                }
            }
        },
        {
            id = "dev_code_review",
            name = "Brutal Code Review",
            description = "A senior developer left 47 comments on your pull request. All critical.",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Accept feedback gracefully and learn",
                    outcomes = {
                        {probability = 0.8, result = "learn", description = "You learned a ton! Your code improved significantly.", effects = {technical = 3, reputation = 10}},
                        {probability = 0.2, result = "overwhelmed", description = "So much to learn. A bit overwhelming.", effects = {technical = 1, stress = 10}}
                    }
                },
                {
                    text = "Defend your code choices",
                    outcomes = {
                        {probability = 0.3, result = "valid_points", description = "Some of your points were valid! Good debate.", effects = {reputation = 5}},
                        {probability = 0.7, result = "shot_down", description = "They shot down every argument. Embarrassing.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Quietly make all the changes",
                    outcomes = {
                        {probability = 1.0, result = "fixed", description = "You fix everything without complaint.", effects = {technical = 2}}
                    }
                }
            }
        },
        {
            id = "dev_imposter_syndrome",
            name = "Imposter Syndrome",
            description = "Everyone seems so smart. You feel like you don't belong here...",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Talk to a mentor about it",
                    outcomes = {
                        {probability = 0.9, result = "reassured", description = "They felt the same way when they started. You're doing fine!", effects = {happiness = 15, stress = -10}},
                        {probability = 0.1, result = "dismissive", description = "They brush it off. Not helpful.", effects = {}}
                    }
                },
                {
                    text = "Push through and prove yourself",
                    outcomes = {
                        {probability = 0.6, result = "confidence", description = "You shipped a feature solo! Confidence boosted!", effects = {happiness = 10, technical = 1}},
                        {probability = 0.4, result = "spiral", description = "The pressure makes it worse.", effects = {happiness = -10, stress = 15}}
                    }
                },
                {
                    text = "Consider if this career is right for you",
                    outcomes = {
                        {probability = 0.7, result = "stay", description = "After reflection, you decide to stick with it.", effects = {}},
                        {probability = 0.3, result = "doubt", description = "Doubt lingers...", effects = {happiness = -5}}
                    }
                }
            }
        },
        {
            id = "dev_side_project",
            name = "Side Project Goes Viral",
            description = "A tool you built in your free time is getting attention on GitHub!",
            probability = 0.03,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Promote it and build a community",
                    outcomes = {
                        {probability = 0.5, result = "success", description = "1000 stars! Tech blogs cover it! Recruiters are calling!", effects = {fame = 5, reputation = 25}},
                        {probability = 0.5, result = "moderate", description = "Decent traction but not huge.", effects = {reputation = 10}}
                    }
                },
                {
                    text = "Quietly maintain it",
                    outcomes = {
                        {probability = 0.7, result = "steady", description = "Slow but steady growth. Nice portfolio piece.", effects = {reputation = 5}},
                        {probability = 0.3, result = "abandoned", description = "Life gets busy. Project stagnates.", effects = {}}
                    }
                },
                {
                    text = "Try to monetize it",
                    outcomes = {
                        {probability = 0.3, result = "profitable", description = "People pay for premium features! Side income!", effects = {money = 5000}},
                        {probability = 0.7, result = "backlash", description = "Community backlash for monetizing.", effects = {reputation = -10}}
                    }
                }
            }
        },
        {
            id = "dev_hackathon",
            name = "Company Hackathon",
            description = "24-hour hackathon! Build something cool!",
            probability = 0.05,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Go all in with an ambitious idea",
                    outcomes = {
                        {probability = 0.3, result = "win", description = "Your team WON! Project gets funded for real development!", effects = {money = 1000, reputation = 25, happiness = 20}},
                        {probability = 0.4, result = "place", description = "You placed! Cool swag and recognition.", effects = {reputation = 10, happiness = 10}},
                        {probability = 0.3, result = "crash", description = "Too ambitious. Didn't finish.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Build something simple but polished",
                    outcomes = {
                        {probability = 0.5, result = "solid", description = "Judges loved how polished it was!", effects = {reputation = 15, happiness = 10}},
                        {probability = 0.5, result = "boring", description = "Too simple. Didn't stand out.", effects = {}}
                    }
                },
                {
                    text = "Skip it - you need sleep",
                    outcomes = {
                        {probability = 0.7, result = "rested", description = "You're rested while everyone's exhausted.", effects = {}},
                        {probability = 0.3, result = "fomo", description = "Everyone's talking about it. Major FOMO.", effects = {happiness = -5}}
                    }
                }
            }
        },
        {
            id = "dev_recruiter",
            name = "LinkedIn Recruiter",
            description = "A FAANG recruiter reached out about a position paying double your salary!",
            probability = 0.04,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Take the interview",
                    outcomes = {
                        {probability = 0.3, result = "offer", description = "You got an offer! 2x salary!", effects = {jobOffer = "Senior Developer (FAANG)", offerSalary = 150000}},
                        {probability = 0.5, result = "rejected", description = "Good experience but didn't make it.", effects = {technical = 1}},
                        {probability = 0.2, result = "ghosted", description = "They ghosted you. Classic.", effects = {happiness = -5}}
                    }
                },
                {
                    text = "Decline - happy where you are",
                    outcomes = {
                        {probability = 0.7, result = "content", description = "Loyalty and work-life balance matter.", effects = {}},
                        {probability = 0.3, result = "regret", description = "Sometimes you wonder what if...", effects = {happiness = -5}}
                    }
                },
                {
                    text = "Use it to negotiate a raise",
                    outcomes = {
                        {probability = 0.5, result = "raise", description = "Boss matches with a 30% raise to keep you!", effects = {salaryIncrease = 19500}},
                        {probability = 0.5, result = "bluff_called", description = "Boss calls your bluff. Awkward.", effects = {reputation = -10}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Fixed a bug that's been open for 6 months!",
        "Stack Overflow saved your life again.",
        "Spent 3 hours on a bug that was a missing semicolon.",
        "The build is broken. Wasn't you this time!",
        "Successfully deployed to production!",
        "Code review took longer than writing the code.",
        "The senior dev praised your solution!",
        "You finally understand recursion.",
        "Meeting could have been an email.",
        "Free lunch for hitting the sprint goal!",
        "Your PR got merged!",
        "Rubber duck debugging actually worked.",
        "The coffee machine is your best friend.",
        "Finally understood what the legacy code does.",
        "Git merge conflict hell. Send help."
    }
}

-- IT SUPPORT SPECIALIST
CareerData_Part2.Jobs["IT Support"] = {
    id = "it_support",
    title = "IT Support Specialist",
    category = "Technology",
    baseSalary = 45000,
    salaryRange = {38000, 55000},
    minAge = 18,
    maxAge = nil,
    requirement = "High School",
    certifications = {"CompTIA A+"},
    requiredSkills = {},
    skillGains = {Technical = 2, Social = 1, Analytical = 1},
    description = "Have you tried turning it off and on again?",
    workEnvironment = "office",
    stressLevel = "medium",
    promotionPath = "IT Manager",
    
    careerEvents = {
        {
            id = "it_ceo_computer",
            name = "CEO's Computer",
            description = "The CEO's computer is broken and they have a board presentation in 30 minutes!",
            probability = 0.05,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Drop everything and fix it",
                    outcomes = {
                        {probability = 0.7, result = "hero", description = "Fixed it with 5 minutes to spare! CEO remembers you!", effects = {reputation = 25, promotionProgress = 15}},
                        {probability = 0.3, result = "escalate", description = "Issue is bigger than expected. Had to get a loaner.", effects = {stress = 20}}
                    }
                },
                {
                    text = "Set up a backup laptop",
                    outcomes = {
                        {probability = 0.9, result = "quick_fix", description = "Backup laptop saves the day!", effects = {reputation = 15}},
                        {probability = 0.1, result = "not_ready", description = "Backup wasn't configured properly. Scramble!", effects = {reputation = -10, stress = 25}}
                    }
                }
            }
        },
        {
            id = "it_phishing",
            name = "Phishing Attack",
            description = "An employee clicked a phishing link and ransomware is spreading!",
            probability = 0.04,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Isolate affected systems immediately",
                    outcomes = {
                        {probability = 0.7, result = "contained", description = "Quick thinking! You contained the damage!", effects = {reputation = 30, technical = 2}},
                        {probability = 0.3, result = "spread", description = "It spread before you could act.", effects = {stress = 30}}
                    }
                },
                {
                    text = "Shut down the entire network",
                    outcomes = {
                        {probability = 0.5, result = "safe", description = "Nuclear option but effective. No data lost.", effects = {reputation = 15}},
                        {probability = 0.5, result = "overreaction", description = "It wasn't that bad. You caused more damage.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Try to identify and kill the process",
                    outcomes = {
                        {probability = 0.4, result = "stopped", description = "You stopped it! Minimal damage!", effects = {reputation = 25, technical = 3}},
                        {probability = 0.6, result = "too_late", description = "It encrypted 3 servers before you found it.", effects = {stress = 25}}
                    }
                }
            }
        },
        {
            id = "it_stupid_question",
            name = "Stupid Question",
            description = "A user asks you to help them find the 'any' key.",
            probability = 0.12,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Politely explain it means any key",
                    outcomes = {
                        {probability = 0.9, result = "understood", description = "They laugh at themselves. Crisis resolved.", effects = {}},
                        {probability = 0.1, result = "confused", description = "They're still confused. This will take a while.", effects = {stress = 10}}
                    }
                },
                {
                    text = "Walk over and press a key for them",
                    outcomes = {
                        {probability = 0.8, result = "done", description = "Just did it. Moving on.", effects = {}},
                        {probability = 0.2, result = "dependent", description = "Now they call you for everything.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Send them a screenshot",
                    outcomes = {
                        {probability = 0.7, result = "helpful", description = "Visual learning! They get it now.", effects = {}},
                        {probability = 0.3, result = "more_questions", description = "Now they have more questions.", effects = {stress = 5}}
                    }
                }
            }
        },
        {
            id = "it_server_room",
            name = "Server Room Emergency",
            description = "The server room AC failed! Temperatures rising fast!",
            probability = 0.03,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Emergency shutdown of non-critical servers",
                    outcomes = {
                        {probability = 0.8, result = "saved", description = "Core systems saved! Good call on priorities.", effects = {reputation = 20}},
                        {probability = 0.2, result = "wrong_servers", description = "You shut down critical servers by mistake!", effects = {reputation = -20}}
                    }
                },
                {
                    text = "Bring in portable AC units",
                    outcomes = {
                        {probability = 0.6, result = "temporary_fix", description = "Buys time until repair crew arrives!", effects = {reputation = 10}},
                        {probability = 0.4, result = "not_enough", description = "Not enough cooling. Some servers overheat.", effects = {stress = 20}}
                    }
                },
                {
                    text = "Open the door and use fans",
                    outcomes = {
                        {probability = 0.3, result = "works", description = "Ghetto but effective!", effects = {}},
                        {probability = 0.7, result = "fails", description = "Security risk and didn't cool enough.", effects = {reputation = -10}}
                    }
                }
            }
        },
        {
            id = "it_password_reset",
            name = "Password Reset Dilemma",
            description = "Someone claiming to be an executive needs an urgent password reset but isn't following protocol.",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Follow protocol strictly",
                    outcomes = {
                        {probability = 0.6, result = "correct", description = "Good call - it was a social engineering attempt!", effects = {reputation = 20}},
                        {probability = 0.4, result = "real_exec", description = "It really was the exec. They're annoyed.", effects = {reputation = -5}}
                    }
                },
                {
                    text = "Reset it - they sound legit",
                    outcomes = {
                        {probability = 0.3, result = "fine", description = "It was really them. No harm done.", effects = {}},
                        {probability = 0.7, result = "hacked", description = "It was a hacker! Account compromised! You're in trouble.", effects = {reputation = -30}}
                    }
                },
                {
                    text = "Call their office line to verify",
                    outcomes = {
                        {probability = 0.9, result = "verified", description = "Smart move! Always verify through known channels.", effects = {reputation = 5}},
                        {probability = 0.1, result = "no_answer", description = "No answer. Now what?", effects = {stress = 10}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Ticket #1247: 'Computer doesn't work'. That's it. That's the ticket.",
        "Someone called because their wireless mouse was plugged in.",
        "The printer jammed. It's ALWAYS the printer.",
        "A user had 47 browser toolbars installed.",
        "Someone's monitor 'wasn't working'. It was turned off.",
        "Had to explain what a right-click is. Three times.",
        "Found a user's password on a sticky note on their monitor.",
        "The ticket queue finally hit zero! Just kidding.",
        "Someone blamed IT for their own typo.",
        "Fixed an issue remotely in 30 seconds. They thought it was magic.",
        "The coffee machine in the server room is the best kept secret.",
        "A computer had so many viruses it crashed scanning for viruses.",
        "Someone asked if you could 'hack' their ex's social media.",
        "You were called a wizard. That was nice."
    }
}

-- SYSTEM ADMINISTRATOR
CareerData_Part2.Jobs["System Administrator"] = {
    id = "sysadmin",
    title = "System Administrator",
    category = "Technology",
    baseSalary = 75000,
    salaryRange = {60000, 95000},
    minAge = 21,
    maxAge = nil,
    requirement = "Bachelor's Degree",
    certifications = {"CompTIA Server+", "Linux+"},
    requiredSkills = {Technical = 30},
    skillGains = {Technical = 3, Analytical = 2, Leadership = 1},
    description = "Keep servers running. Fear the pager.",
    workEnvironment = "office",
    stressLevel = "high",
    promotionPath = "Senior System Administrator",
    
    careerEvents = {
        {
            id = "sys_3am_alert",
            name = "3 AM Alert",
            description = "Your phone blows up at 3 AM. Primary database server is down!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Log in and troubleshoot remotely",
                    outcomes = {
                        {probability = 0.6, result = "fixed", description = "Fixed it from bed. Back to sleep.", effects = {stress = 10}},
                        {probability = 0.4, result = "onsite", description = "Need to go onsite. This is bad.", effects = {stress = 25, health = -5}}
                    }
                },
                {
                    text = "Failover to backup and investigate in morning",
                    outcomes = {
                        {probability = 0.7, result = "failover", description = "Failover works! Deal with it at a human hour.", effects = {stress = 5}},
                        {probability = 0.3, result = "no_backup", description = "Backup had issues too. Murphy's Law.", effects = {stress = 30}}
                    }
                },
                {
                    text = "Ignore it - someone else will handle it",
                    outcomes = {
                        {probability = 0.1, result = "handled", description = "Someone else got it. Lucky.", effects = {}},
                        {probability = 0.9, result = "fired", description = "Extended outage. Major incident. You're fired.", effects = {fired = true}}
                    }
                }
            }
        },
        {
            id = "sys_security_audit",
            name = "Security Audit",
            description = "External auditors are reviewing your systems. Are you ready?",
            probability = 0.04,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "You're confident - systems are secure",
                    outcomes = {
                        {probability = 0.5, result = "pass", description = "Clean audit! Great job!", effects = {reputation = 25, bonus = 2000}},
                        {probability = 0.5, result = "findings", description = "A few findings but nothing critical.", effects = {reputation = 5}}
                    }
                },
                {
                    text = "Do a quick patch of known issues",
                    outcomes = {
                        {probability = 0.6, result = "caught_up", description = "Good call! Those would have been flagged.", effects = {reputation = 15}},
                        {probability = 0.4, result = "broke_something", description = "Last minute changes broke something.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Pray",
                    outcomes = {
                        {probability = 0.3, result = "lucky", description = "They missed the worst stuff. Lucky.", effects = {}},
                        {probability = 0.7, result = "disaster", description = "They found everything. SO many findings.", effects = {reputation = -20, stress = 30}}
                    }
                }
            }
        },
        {
            id = "sys_rm_rf",
            name = "The Forbidden Command",
            description = "You accidentally ran 'rm -rf /' on a production server.",
            probability = 0.02,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Immediately kill the process",
                    outcomes = {
                        {probability = 0.5, result = "saved", description = "Caught it early! Most data saved!", effects = {stress = 30}},
                        {probability = 0.5, result = "too_late", description = "Too late. It's gone. All of it.", effects = {stress = 50, health = -10}}
                    }
                },
                {
                    text = "Restore from backup",
                    outcomes = {
                        {probability = 0.7, result = "restored", description = "Backup from last night. Some data lost but recoverable.", effects = {reputation = -15, stress = 25}},
                        {probability = 0.3, result = "no_backup", description = "When was the last backup? ...Last backup?", effects = {reputation = -40, fired = true}}
                    }
                }
            }
        },
        {
            id = "sys_cloud_migration",
            name = "Cloud Migration Project",
            description = "Company wants to migrate to the cloud. You're leading the project.",
            probability = 0.05,
            minYearsInJob = 1,
            requiresPerformance = 60,
            choices = {
                {
                    text = "Embrace it - learn new skills",
                    outcomes = {
                        {probability = 0.7, result = "success", description = "Successful migration! You're now a cloud expert!", effects = {technical = 5, reputation = 30, promotionProgress = 25}},
                        {probability = 0.3, result = "struggles", description = "Learning curve was steep. Got there eventually.", effects = {technical = 3, stress = 20}}
                    }
                },
                {
                    text = "Resist - on-prem is better",
                    outcomes = {
                        {probability = 0.3, result = "valid", description = "Your concerns were valid. Hybrid approach adopted.", effects = {reputation = 10}},
                        {probability = 0.7, result = "dinosaur", description = "You're seen as resistant to change.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Delegate to a junior admin",
                    outcomes = {
                        {probability = 0.4, result = "success", description = "They crushed it! Good mentoring!", effects = {leadership = 2}},
                        {probability = 0.6, result = "disaster", description = "They weren't ready. It's a mess.", effects = {reputation = -20}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Servers are humming. Life is good.",
        "Someone requested sudo access. Denied.",
        "Updated 47 servers. Zero issues. That's suspicious.",
        "The monitoring dashboard is all green!",
        "A junior admin asked what 'chmod 777' does. Oh no.",
        "Wrote a script that saved 10 hours of manual work.",
        "Your coffee is cold. You forgot about it hours ago.",
        "Successfully talked management out of a bad idea.",
        "The backup job failed. For the third time this week.",
        "Someone emailed their password. In plain text.",
        "Your uptime record is 847 days. Don't jinx it.",
        "Had to explain why we can't 'just restart production'.",
        "Memory leak found. The hunt was on.",
        "Documentation? What documentation?"
    }
}

return CareerData_Part2
