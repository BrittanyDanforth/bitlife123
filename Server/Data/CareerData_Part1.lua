-- CareerData Part 1: Entry Level, Service, and Food Industry Careers
-- Each career has SPECIFIC events that only happen in THAT career

local CareerData_Part1 = {}

--============================================================================
-- CAREER CATEGORIES
--============================================================================
CareerData_Part1.Categories = {
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
-- SKILL DEFINITIONS
--============================================================================
CareerData_Part1.Skills = {
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
-- ENTRY LEVEL CAREERS (Jobs anyone can get)
--============================================================================
CareerData_Part1.Jobs = {}

-- FAST FOOD WORKER
CareerData_Part1.Jobs["Fast Food Worker"] = {
    id = "fast_food_worker",
    title = "Fast Food Worker",
    category = "Entry Level",
    baseSalary = 18000,
    salaryRange = {16000, 22000},
    minAge = 16,
    maxAge = nil,
    requirement = nil,
    requiredSkills = {},
    skillGains = {Social = 1, Physical = 1},
    description = "Flip burgers, take orders, and deal with hangry customers.",
    workEnvironment = "fast_food_restaurant",
    stressLevel = "medium",
    promotionPath = "Shift Manager",
    
    -- SPECIFIC EVENTS ONLY FOR THIS JOB
    careerEvents = {
        {
            id = "ff_grease_fire",
            name = "Grease Fire",
            description = "The fryer catches fire! What do you do?",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Grab the fire extinguisher",
                    outcomes = {
                        {probability = 0.7, result = "hero", description = "You put out the fire and save the day! Your manager is impressed.", effects = {reputation = 15, promotionProgress = 10}},
                        {probability = 0.3, result = "fail", description = "You fumble with the extinguisher and make it worse. Fire department called.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Yell for help and evacuate",
                    outcomes = {
                        {probability = 0.9, result = "safe", description = "Everyone evacuates safely. Standard procedure.", effects = {}},
                        {probability = 0.1, result = "hero", description = "Your quick thinking prevented injuries!", effects = {reputation = 5}}
                    }
                },
                {
                    text = "Try to smother it with a towel",
                    outcomes = {
                        {probability = 0.3, result = "success", description = "Risky but it worked!", effects = {reputation = 5}},
                        {probability = 0.7, result = "injured", description = "You burned your hand badly!", effects = {health = -20, happiness = -10}}
                    }
                }
            }
        },
        {
            id = "ff_karen_customer",
            name = "The Karen",
            description = "A customer is SCREAMING that their burger has pickles when they said NO PICKLES!",
            probability = 0.15,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Apologize profusely and remake it",
                    outcomes = {
                        {probability = 0.6, result = "resolved", description = "They calm down after getting a fresh burger.", effects = {stress = 5}},
                        {probability = 0.4, result = "escalate", description = "They demand to speak to your manager anyway.", effects = {stress = 10, reputation = -5}}
                    }
                },
                {
                    text = "Stay calm and offer a refund",
                    outcomes = {
                        {probability = 0.8, result = "resolved", description = "Money talks. They take the refund and leave.", effects = {}},
                        {probability = 0.2, result = "escalate", description = "They want BOTH a refund AND a free meal!", effects = {stress = 10}}
                    }
                },
                {
                    text = "Snap back at them",
                    outcomes = {
                        {probability = 0.1, result = "respect", description = "Surprisingly, they back down.", effects = {happiness = 5}},
                        {probability = 0.9, result = "fired", description = "Your manager fires you on the spot.", effects = {fired = true}}
                    }
                }
            }
        },
        {
            id = "ff_secret_shopper",
            name = "Secret Shopper",
            description = "A corporate secret shopper is evaluating your store today!",
            probability = 0.05,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Go above and beyond with service",
                    outcomes = {
                        {probability = 0.7, result = "excellent", description = "The secret shopper gives a glowing review mentioning YOU by name!", effects = {reputation = 20, promotionProgress = 15, bonus = 200}},
                        {probability = 0.3, result = "good", description = "Good review overall.", effects = {reputation = 5}}
                    }
                },
                {
                    text = "Just do your normal routine",
                    outcomes = {
                        {probability = 0.5, result = "average", description = "Average scores. Nothing special.", effects = {}},
                        {probability = 0.5, result = "below", description = "They noted some issues.", effects = {reputation = -5}}
                    }
                }
            }
        },
        {
            id = "ff_robbery",
            name = "Armed Robbery",
            description = "Someone pulls a gun and demands all the cash from the register!",
            probability = 0.03,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Comply and give them the money",
                    outcomes = {
                        {probability = 0.95, result = "safe", description = "They take the money and run. You're shaken but safe.", effects = {happiness = -15, stress = 20}},
                        {probability = 0.05, result = "hurt", description = "They pistol-whip you anyway before fleeing.", effects = {health = -25, happiness = -20}}
                    }
                },
                {
                    text = "Try to be a hero",
                    outcomes = {
                        {probability = 0.1, result = "hero", description = "You somehow disarm them! You're a local hero!", effects = {reputation = 50, happiness = 20, fame = 5}},
                        {probability = 0.6, result = "shot", description = "You get shot!", effects = {health = -60, happiness = -30}},
                        {probability = 0.3, result = "beaten", description = "They beat you badly.", effects = {health = -40, happiness = -25}}
                    }
                },
                {
                    text = "Hit the silent alarm",
                    outcomes = {
                        {probability = 0.7, result = "caught", description = "Police arrive and arrest them! You helped catch a criminal.", effects = {reputation = 15, happiness = 10}},
                        {probability = 0.3, result = "noticed", description = "They notice and threaten you, but flee.", effects = {happiness = -10, stress = 15}}
                    }
                }
            }
        },
        {
            id = "ff_health_inspector",
            name = "Health Inspection",
            description = "The health inspector just walked in! Your station is a mess.",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Quickly clean everything",
                    outcomes = {
                        {probability = 0.5, result = "caught", description = "They saw you scrambling. Suspicious.", effects = {reputation = -10}},
                        {probability = 0.5, result = "clean", description = "You got it clean in time!", effects = {}}
                    }
                },
                {
                    text = "Distract them while coworker cleans",
                    outcomes = {
                        {probability = 0.6, result = "success", description = "Your coworker got it clean. Teamwork!", effects = {reputation = 5}},
                        {probability = 0.4, result = "fail", description = "They see right through you.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Just act natural",
                    outcomes = {
                        {probability = 0.3, result = "fine", description = "They focus on other areas.", effects = {}},
                        {probability = 0.7, result = "violation", description = "They write up violations at your station.", effects = {reputation = -20, stress = 10}}
                    }
                }
            }
        },
        {
            id = "ff_coworker_stealing",
            name = "Stealing Coworker",
            description = "You catch your coworker stealing from the register!",
            probability = 0.04,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Report them to the manager",
                    outcomes = {
                        {probability = 0.8, result = "reward", description = "They get fired. Manager thanks you for your honesty.", effects = {reputation = 15, promotionProgress = 10}},
                        {probability = 0.2, result = "revenge", description = "They find out you snitched. They key your car.", effects = {reputation = 10, happiness = -10}}
                    }
                },
                {
                    text = "Confront them privately",
                    outcomes = {
                        {probability = 0.5, result = "stop", description = "They're embarrassed and stop stealing.", effects = {}},
                        {probability = 0.3, result = "cut_in", description = "They offer to split the money with you...", effects = {moralChoice = true}},
                        {probability = 0.2, result = "threaten", description = "They threaten you to keep quiet.", effects = {stress = 15, happiness = -5}}
                    }
                },
                {
                    text = "Mind your own business",
                    outcomes = {
                        {probability = 0.6, result = "nothing", description = "You pretend you saw nothing.", effects = {}},
                        {probability = 0.4, result = "blamed", description = "When money goes missing, YOU get blamed!", effects = {reputation = -25, fired = true}}
                    }
                }
            }
        },
        {
            id = "ff_promotion_offer",
            name = "Shift Manager Opening",
            description = "The shift manager quit! Your manager asks if you want the position.",
            probability = 0.07,
            minYearsInJob = 0.5,
            requiresPerformance = 60,
            choices = {
                {
                    text = "Accept the promotion",
                    outcomes = {
                        {probability = 1.0, result = "promoted", description = "You're now a Shift Manager!", effects = {promoted = "Shift Manager", salaryIncrease = 3000}}
                    }
                },
                {
                    text = "Decline - too much responsibility",
                    outcomes = {
                        {probability = 0.7, result = "respect", description = "Your manager respects your honesty.", effects = {}},
                        {probability = 0.3, result = "disappointed", description = "Your manager seems disappointed in you.", effects = {reputation = -5}}
                    }
                }
            }
        },
        {
            id = "ff_celebrity_visit",
            name = "Celebrity Customer",
            description = "A famous celebrity just walked in and you're taking their order!",
            probability = 0.02,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Stay professional",
                    outcomes = {
                        {probability = 0.8, result = "tip", description = "They appreciate your professionalism and leave a huge tip!", effects = {money = 100, happiness = 15}},
                        {probability = 0.2, result = "normal", description = "Just a normal transaction.", effects = {happiness = 5}}
                    }
                },
                {
                    text = "Ask for a selfie",
                    outcomes = {
                        {probability = 0.4, result = "selfie", description = "They're cool with it! You got a pic with a celeb!", effects = {happiness = 20, fame = 1}},
                        {probability = 0.4, result = "refused", description = "They politely decline.", effects = {}},
                        {probability = 0.2, result = "rude", description = "They're annoyed. Your manager scolds you.", effects = {reputation = -10, happiness = -5}}
                    }
                },
                {
                    text = "Freak out and fanboy/fangirl",
                    outcomes = {
                        {probability = 0.3, result = "funny", description = "They think it's adorable!", effects = {happiness = 15}},
                        {probability = 0.7, result = "embarrass", description = "So embarrassing. They leave quickly.", effects = {happiness = -10, reputation = -5}}
                    }
                }
            }
        }
    },
    
    -- Random flavor text that can appear during work
    workDayEvents = {
        "You dropped a tray of fries. Five second rule?",
        "The ice cream machine is broken. Again.",
        "A kid threw up in the play area.",
        "Someone paid entirely in coins.",
        "The drive-thru headset keeps cutting out.",
        "You burned yourself on the fryer.",
        "A customer complimented your smile.",
        "You found $5 in the parking lot.",
        "The lunch rush was INSANE today.",
        "Your coworker called in sick. Double shift!",
        "Someone ordered 50 nuggets. For themselves.",
        "The bathroom needs cleaning. Your turn.",
        "A customer tried to pay with expired coupons.",
        "You memorized the entire menu finally!",
        "The new trainee keeps messing up orders."
    }
}

-- CASHIER
CareerData_Part1.Jobs["Cashier"] = {
    id = "cashier",
    title = "Cashier",
    category = "Retail",
    baseSalary = 20000,
    salaryRange = {18000, 25000},
    minAge = 16,
    maxAge = nil,
    requirement = nil,
    requiredSkills = {},
    skillGains = {Social = 2, Analytical = 1},
    description = "Scan items, handle money, and smile through the pain.",
    workEnvironment = "retail_store",
    stressLevel = "medium",
    promotionPath = "Head Cashier",
    
    careerEvents = {
        {
            id = "cash_counterfeit",
            name = "Counterfeit Bill",
            description = "The bill checker pen says this $100 is FAKE!",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Refuse the bill politely",
                    outcomes = {
                        {probability = 0.6, result = "accept", description = "Customer is embarrassed but produces a real bill.", effects = {}},
                        {probability = 0.3, result = "argue", description = "They argue but eventually leave.", effects = {stress = 10}},
                        {probability = 0.1, result = "threaten", description = "They threaten you before leaving.", effects = {stress = 20, happiness = -10}}
                    }
                },
                {
                    text = "Call security",
                    outcomes = {
                        {probability = 0.5, result = "arrest", description = "Turns out they're a known counterfeiter! Security arrests them.", effects = {reputation = 15}},
                        {probability = 0.5, result = "innocent", description = "They didn't know it was fake. Awkward.", effects = {}}
                    }
                },
                {
                    text = "Accept it anyway",
                    outcomes = {
                        {probability = 0.3, result = "unnoticed", description = "No one notices...", effects = {}},
                        {probability = 0.7, result = "caught", description = "Your drawer is short. You're in trouble.", effects = {reputation = -20, money = -100}}
                    }
                }
            }
        },
        {
            id = "cash_register_error",
            name = "Register Malfunction",
            description = "Your register crashes during a huge line of customers!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Try to fix it yourself",
                    outcomes = {
                        {probability = 0.4, result = "fixed", description = "A quick reboot fixed it! The line didn't grow too long.", effects = {reputation = 5}},
                        {probability = 0.6, result = "worse", description = "You made it worse. IT has to come.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Call for backup immediately",
                    outcomes = {
                        {probability = 0.8, result = "smooth", description = "Another register opens. Crisis averted.", effects = {}},
                        {probability = 0.2, result = "wait", description = "No backup available. Customers are furious.", effects = {stress = 20, reputation = -5}}
                    }
                },
                {
                    text = "Do the math manually",
                    outcomes = {
                        {probability = 0.3, result = "impressive", description = "You handle it like a pro! Manager is impressed.", effects = {reputation = 10, promotionProgress = 5}},
                        {probability = 0.7, result = "slow", description = "It takes forever. The line wraps around the store.", effects = {stress = 25}}
                    }
                }
            }
        },
        {
            id = "cash_shoplifter",
            name = "Shoplifter Spotted",
            description = "You see someone stuffing merchandise in their bag!",
            probability = 0.07,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Alert security discreetly",
                    outcomes = {
                        {probability = 0.8, result = "caught", description = "Security catches them at the door. Good eye!", effects = {reputation = 15, bonus = 50}},
                        {probability = 0.2, result = "escaped", description = "They got away before security arrived.", effects = {}}
                    }
                },
                {
                    text = "Confront them directly",
                    outcomes = {
                        {probability = 0.3, result = "drop", description = "They drop everything and run.", effects = {reputation = 10}},
                        {probability = 0.4, result = "deny", description = "They deny it and cause a scene.", effects = {stress = 15}},
                        {probability = 0.3, result = "aggressive", description = "They get aggressive with you!", effects = {health = -10, stress = 20}}
                    }
                },
                {
                    text = "Pretend you didn't see",
                    outcomes = {
                        {probability = 0.5, result = "nothing", description = "They walk out. Not your problem.", effects = {}},
                        {probability = 0.5, result = "camera", description = "Loss prevention saw the whole thing on camera. You're questioned.", effects = {reputation = -15}}
                    }
                }
            }
        },
        {
            id = "cash_price_dispute",
            name = "Price Dispute",
            description = "A customer insists the item is on sale for 50% off, but it's not in the system.",
            probability = 0.12,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Honor the price they say",
                    outcomes = {
                        {probability = 0.5, result = "happy", description = "Customer leaves happy. Your drawer will be off though.", effects = {stress = 5}},
                        {probability = 0.5, result = "manager", description = "Manager asks why you gave an unauthorized discount.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Call a manager",
                    outcomes = {
                        {probability = 0.7, result = "resolved", description = "Manager handles it. They were wrong.", effects = {}},
                        {probability = 0.3, result = "side_customer", description = "Manager sides with the customer anyway.", effects = {stress = 10}}
                    }
                },
                {
                    text = "Stand firm on the price",
                    outcomes = {
                        {probability = 0.4, result = "pay", description = "They grumble but pay full price.", effects = {}},
                        {probability = 0.4, result = "leave", description = "They leave the items and storm out.", effects = {}},
                        {probability = 0.2, result = "complaint", description = "They file a complaint to corporate about you.", effects = {reputation = -10, stress = 15}}
                    }
                }
            }
        },
        {
            id = "cash_employee_discount",
            name = "Discount Dilemma",
            description = "Your friend wants you to use your employee discount for their huge purchase.",
            probability = 0.05,
            minYearsInJob = 0.2,
            choices = {
                {
                    text = "Use your discount for them",
                    outcomes = {
                        {probability = 0.6, result = "unnoticed", description = "No one notices. Your friend saves big.", effects = {happiness = 5}},
                        {probability = 0.4, result = "caught", description = "Loss prevention flags the transaction. You're in trouble.", effects = {reputation = -30, fired = true}}
                    }
                },
                {
                    text = "Politely decline",
                    outcomes = {
                        {probability = 0.6, result = "understand", description = "They understand. It's against policy.", effects = {}},
                        {probability = 0.4, result = "upset", description = "They're upset with you. Friendship strained.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Buy it yourself and sell to them",
                    outcomes = {
                        {probability = 0.7, result = "works", description = "A legal loophole! Everyone wins.", effects = {happiness = 5}},
                        {probability = 0.3, result = "suspected", description = "Manager suspects something. You're being watched.", effects = {stress = 10}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "The card reader is acting up again.",
        "Someone paid with a bag of quarters.",
        "A customer tried to return a clearly used item.",
        "The line stretched all the way to the back.",
        "Someone's coupon expired 3 years ago.",
        "A kid kept scanning random items.",
        "You finally memorized all the produce codes!",
        "Someone abandoned a full cart at checkout.",
        "The security tag wouldn't come off.",
        "A customer complimented your patience.",
        "You stood for 8 hours straight. Your feet hurt.",
        "Someone tried to use a competitor's gift card.",
        "The AC broke. It's so hot in here.",
        "Black Friday flashbacks hit you hard today."
    }
}

-- JANITOR
CareerData_Part1.Jobs["Janitor"] = {
    id = "janitor",
    title = "Janitor",
    category = "Service",
    baseSalary = 24000,
    salaryRange = {20000, 32000},
    minAge = 18,
    maxAge = nil,
    requirement = nil,
    requiredSkills = {},
    skillGains = {Physical = 2},
    description = "Keep buildings clean and running. The unsung hero.",
    workEnvironment = "various",
    stressLevel = "low",
    promotionPath = "Head Custodian",
    
    careerEvents = {
        {
            id = "jan_biohazard",
            name = "Biohazard Situation",
            description = "Someone made a HORRIBLE mess in the bathroom. It's everywhere.",
            probability = 0.12,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Put on extra gear and handle it",
                    outcomes = {
                        {probability = 0.8, result = "clean", description = "It was awful, but you got it done. Professional.", effects = {reputation = 10, happiness = -5}},
                        {probability = 0.2, result = "sick", description = "You got sick from the exposure.", effects = {health = -15, happiness = -10}}
                    }
                },
                {
                    text = "Claim it requires specialized cleanup",
                    outcomes = {
                        {probability = 0.5, result = "approved", description = "They call a hazmat team. Not your problem.", effects = {}},
                        {probability = 0.5, result = "denied", description = "Boss says to just clean it.", effects = {stress = 10}}
                    }
                },
                {
                    text = "Put up an 'Out of Order' sign and leave",
                    outcomes = {
                        {probability = 0.3, result = "forgotten", description = "No one notices for days.", effects = {}},
                        {probability = 0.7, result = "busted", description = "Boss finds out and is furious.", effects = {reputation = -20}}
                    }
                }
            }
        },
        {
            id = "jan_found_money",
            name = "Found Cash",
            description = "You find a wallet with $500 cash while cleaning!",
            probability = 0.04,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Turn it in to lost and found",
                    outcomes = {
                        {probability = 0.5, result = "reward", description = "The owner returns and gives you a $100 reward!", effects = {money = 100, reputation = 10, happiness = 10}},
                        {probability = 0.5, result = "nothing", description = "No one claims it. At least you did the right thing.", effects = {reputation = 5}}
                    }
                },
                {
                    text = "Keep the cash, turn in the wallet",
                    outcomes = {
                        {probability = 0.6, result = "kept", description = "No one's the wiser.", effects = {money = 500, karma = -10}},
                        {probability = 0.4, result = "caught", description = "The owner knew exactly how much was in there. You're fired.", effects = {fired = true, reputation = -30}}
                    }
                },
                {
                    text = "Keep everything",
                    outcomes = {
                        {probability = 0.4, result = "kept", description = "Free money!", effects = {money = 500, karma = -20}},
                        {probability = 0.6, result = "camera", description = "Security camera caught you. You're fired and arrested.", effects = {fired = true, arrested = true}}
                    }
                }
            }
        },
        {
            id = "jan_locked_room",
            name = "Mysterious Room",
            description = "You have keys to a room that's always locked. Tonight you're curious...",
            probability = 0.03,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Open it and look inside",
                    outcomes = {
                        {probability = 0.5, result = "boring", description = "Just old storage. Anticlimactic.", effects = {}},
                        {probability = 0.3, result = "secret", description = "You find some interesting documents...", effects = {intelligence = 5}},
                        {probability = 0.2, result = "caught", description = "Security catches you snooping.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Mind your own business",
                    outcomes = {
                        {probability = 1.0, result = "safe", description = "Some mysteries are better left unsolved.", effects = {}}
                    }
                }
            }
        },
        {
            id = "jan_overtime",
            name = "Overtime Opportunity",
            description = "There's a big event tomorrow and they need the building SPOTLESS. Overtime available.",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Take all the overtime you can",
                    outcomes = {
                        {probability = 0.8, result = "paid", description = "Exhausting but worth it. Great paycheck!", effects = {money = 400, happiness = -5, physical = 1}},
                        {probability = 0.2, result = "injury", description = "You worked too hard and threw out your back.", effects = {money = 400, health = -20}}
                    }
                },
                {
                    text = "Do a normal shift",
                    outcomes = {
                        {probability = 0.7, result = "fine", description = "Work-life balance is important.", effects = {}},
                        {probability = 0.3, result = "pressure", description = "Boss is disappointed you didn't help more.", effects = {reputation = -5}}
                    }
                }
            }
        },
        {
            id = "jan_injury",
            name = "Slip and Fall",
            description = "You slip on a wet floor you just mopped!",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Report the injury",
                    outcomes = {
                        {probability = 0.7, result = "comp", description = "Worker's comp covers your medical bills.", effects = {health = -10}},
                        {probability = 0.3, result = "denied", description = "They claim you didn't follow protocol.", effects = {health = -10, money = -200}}
                    }
                },
                {
                    text = "Walk it off",
                    outcomes = {
                        {probability = 0.6, result = "fine", description = "Just a bruise. You're tough.", effects = {health = -5}},
                        {probability = 0.4, result = "worse", description = "It was worse than you thought. Should've reported it.", effects = {health = -25}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Someone clogged the toilet. Again.",
        "The floor buffer is making a weird noise.",
        "You found someone's lost keys.",
        "A kid spilled an entire slushie.",
        "The supply closet was out of trash bags.",
        "Someone actually thanked you today!",
        "There's gum under EVERY desk.",
        "The elevators need deep cleaning.",
        "You discovered a hidden room behind a shelf.",
        "Night shift is peaceful. Just you and your thoughts.",
        "Someone left food in a trash can. The smell...",
        "You've never seen this much glitter in your life.",
        "The wax on the floors looks PERFECT."
    }
}

-- WAITER/WAITRESS
CareerData_Part1.Jobs["Waiter"] = {
    id = "waiter",
    title = "Waiter/Waitress",
    category = "Food Industry",
    baseSalary = 22000, -- Plus tips
    salaryRange = {18000, 35000},
    minAge = 16,
    maxAge = nil,
    requirement = nil,
    requiredSkills = {},
    skillGains = {Social = 3, Physical = 1},
    description = "Serve food, manage tables, and hustle for tips.",
    workEnvironment = "restaurant",
    stressLevel = "high",
    promotionPath = "Head Waiter",
    tipsEnabled = true,
    
    careerEvents = {
        {
            id = "wait_big_tipper",
            name = "High Roller Table",
            description = "A wealthy-looking party of 8 just sat in your section!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Give them VIP treatment",
                    outcomes = {
                        {probability = 0.7, result = "huge_tip", description = "They loved the service! $200 tip!", effects = {money = 200, happiness = 20}},
                        {probability = 0.2, result = "normal_tip", description = "Good service, standard tip.", effects = {money = 50}},
                        {probability = 0.1, result = "stiffed", description = "Rich people, no tip. Unbelievable.", effects = {happiness = -15}}
                    }
                },
                {
                    text = "Treat them like any other table",
                    outcomes = {
                        {probability = 0.5, result = "normal", description = "Average tip. Missed opportunity?", effects = {money = 30}},
                        {probability = 0.5, result = "appreciated", description = "They appreciated not being fawned over. Decent tip.", effects = {money = 80}}
                    }
                }
            }
        },
        {
            id = "wait_spill",
            name = "Major Spill",
            description = "You trip and spill drinks ALL over a customer!",
            probability = 0.07,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Apologize profusely and offer to pay for dry cleaning",
                    outcomes = {
                        {probability = 0.6, result = "forgiven", description = "They're understanding. Accidents happen.", effects = {money = -50, stress = 10}},
                        {probability = 0.4, result = "angry", description = "They're furious. Manager comps their meal.", effects = {reputation = -10, stress = 15}}
                    }
                },
                {
                    text = "Blame the busboy for leaving something in the way",
                    outcomes = {
                        {probability = 0.3, result = "believed", description = "They buy it. Busboy takes the heat.", effects = {karma = -5}},
                        {probability = 0.7, result = "seen", description = "Someone saw what really happened. You look worse.", effects = {reputation = -20}}
                    }
                },
                {
                    text = "Make a self-deprecating joke",
                    outcomes = {
                        {probability = 0.5, result = "laugh", description = "They laugh! Crisis averted with humor.", effects = {}},
                        {probability = 0.5, result = "not_amused", description = "They are NOT amused.", effects = {reputation = -5, stress = 10}}
                    }
                }
            }
        },
        {
            id = "wait_allergy",
            name = "Allergy Emergency",
            description = "A customer is having an allergic reaction! Did the kitchen mess up?",
            probability = 0.04,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Call 911 immediately",
                    outcomes = {
                        {probability = 0.9, result = "saved", description = "Paramedics arrive quickly. They'll be okay.", effects = {reputation = 10}},
                        {probability = 0.1, result = "serious", description = "It was severe. They're hospitalized.", effects = {stress = 20}}
                    }
                },
                {
                    text = "Ask if they have an EpiPen",
                    outcomes = {
                        {probability = 0.6, result = "has_one", description = "They use their EpiPen. Crisis managed.", effects = {}},
                        {probability = 0.4, result = "doesnt", description = "They don't! Now you really need 911.", effects = {stress = 25}}
                    }
                },
                {
                    text = "Check what they ordered first",
                    outcomes = {
                        {probability = 0.3, result = "kitchen_fault", description = "Kitchen messed up. Restaurant is liable.", effects = {}},
                        {probability = 0.7, result = "wasted_time", description = "You wasted precious time. Manager is upset.", effects = {reputation = -15}}
                    }
                }
            }
        },
        {
            id = "wait_date_gone_wrong",
            name = "Breakup at Your Table",
            description = "The couple at your table is having a LOUD breakup!",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Give them space and privacy",
                    outcomes = {
                        {probability = 0.7, result = "tip", description = "They appreciate your discretion. Good tip from the guilty party.", effects = {money = 40}},
                        {probability = 0.3, result = "leave", description = "One storms out. No tip on an unpaid bill.", effects = {stress = 10}}
                    }
                },
                {
                    text = "Subtly offer the bill",
                    outcomes = {
                        {probability = 0.5, result = "take_hint", description = "They pay and leave. Table freed up.", effects = {money = 20}},
                        {probability = 0.5, result = "offended", description = "They think you're being rude during their crisis.", effects = {reputation = -5}}
                    }
                },
                {
                    text = "Bring free dessert to calm things down",
                    outcomes = {
                        {probability = 0.4, result = "works", description = "Nothing heals like chocolate. They calm down.", effects = {reputation = 5}},
                        {probability = 0.6, result = "backfire", description = "Manager asks why you gave away free food.", effects = {reputation = -5}}
                    }
                }
            }
        },
        {
            id = "wait_celebrity",
            name = "Celebrity Diner",
            description = "A famous celebrity is seated at your table!",
            probability = 0.02,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Be professional and give excellent service",
                    outcomes = {
                        {probability = 0.7, result = "huge_tip", description = "They're impressed by your professionalism. Massive tip!", effects = {money = 300, happiness = 25}},
                        {probability = 0.3, result = "normal", description = "Great service, average tip. At least you met them!", effects = {money = 50, happiness = 10}}
                    }
                },
                {
                    text = "Mention you're a big fan",
                    outcomes = {
                        {probability = 0.5, result = "kind", description = "They're gracious about it. Even take a photo!", effects = {happiness = 20, fame = 1}},
                        {probability = 0.5, result = "annoyed", description = "They just want to eat in peace.", effects = {}}
                    }
                },
                {
                    text = "Take a sneaky photo for social media",
                    outcomes = {
                        {probability = 0.3, result = "viral", description = "Your post goes viral! Followers gained!", effects = {fame = 5, happiness = 15}},
                        {probability = 0.4, result = "caught", description = "They catch you. Super awkward.", effects = {reputation = -10, happiness = -10}},
                        {probability = 0.3, result = "fired", description = "Manager fires you for violating guest privacy.", effects = {fired = true}}
                    }
                }
            }
        },
        {
            id = "wait_karen_table",
            name = "Table From Hell",
            description = "These customers are complaining about EVERYTHING. Nothing is right.",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Kill them with kindness",
                    outcomes = {
                        {probability = 0.4, result = "won_over", description = "They eventually soften. Small tip but you survived.", effects = {money = 10, stress = 15}},
                        {probability = 0.6, result = "still_awful", description = "Nothing works. They complain to the manager anyway.", effects = {stress = 20, reputation = -5}}
                    }
                },
                {
                    text = "Get the manager involved early",
                    outcomes = {
                        {probability = 0.7, result = "manager_handles", description = "Manager takes over. Not your problem anymore.", effects = {stress = 5}},
                        {probability = 0.3, result = "blamed", description = "Manager blames you for not handling it.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Subtly get revenge (bad service)",
                    outcomes = {
                        {probability = 0.3, result = "satisfying", description = "Petty? Yes. Satisfying? Also yes.", effects = {happiness = 5, karma = -5}},
                        {probability = 0.7, result = "caught", description = "They complain. Manager writes you up.", effects = {reputation = -20}}
                    }
                }
            }
        },
        {
            id = "wait_steal_tip",
            name = "Stolen Tip",
            description = "You saw another server take the cash tip left at your table!",
            probability = 0.05,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Confront them directly",
                    outcomes = {
                        {probability = 0.5, result = "return", description = "They sheepishly give it back.", effects = {money = 30}},
                        {probability = 0.3, result = "deny", description = "They deny it. Your word against theirs.", effects = {stress = 15}},
                        {probability = 0.2, result = "fight", description = "Things escalate. Management has to separate you.", effects = {reputation = -10, stress = 20}}
                    }
                },
                {
                    text = "Report them to the manager",
                    outcomes = {
                        {probability = 0.6, result = "fired", description = "They're fired for stealing. Justice served.", effects = {reputation = 5}},
                        {probability = 0.4, result = "no_proof", description = "No proof. Manager can't do anything.", effects = {stress = 10}}
                    }
                },
                {
                    text = "Let it slide this time",
                    outcomes = {
                        {probability = 0.5, result = "regret", description = "They keep doing it to others. Should've said something.", effects = {karma = -5}},
                        {probability = 0.5, result = "move_on", description = "Not worth the drama.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Someone snapped their fingers to get your attention.",
        "A table split the check 12 ways. All separate cards.",
        "You got a phone number instead of a tip.",
        "The kitchen is running behind. Customers are angry.",
        "Someone complained their steak was too 'steaky'.",
        "A kid dumped an entire plate on the floor.",
        "Your feet are killing you after that double.",
        "A customer left a 50% tip! Made your night!",
        "Someone tried to order off a 10-year-old menu.",
        "The POS system crashed during rush.",
        "A table stayed 2 hours after closing.",
        "You dropped a tray. Everyone clapped. Kill me.",
        "A regular customer remembered your name!",
        "Someone asked if the ice cubes were gluten-free."
    }
}

-- BARISTA
CareerData_Part1.Jobs["Barista"] = {
    id = "barista",
    title = "Barista",
    category = "Food Industry",
    baseSalary = 23000,
    salaryRange = {20000, 30000},
    minAge = 16,
    maxAge = nil,
    requirement = nil,
    requiredSkills = {},
    skillGains = {Social = 2, Culinary = 1},
    description = "Craft coffee drinks and deal with caffeine-deprived customers.",
    workEnvironment = "coffee_shop",
    stressLevel = "medium",
    promotionPath = "Shift Supervisor",
    tipsEnabled = true,
    
    careerEvents = {
        {
            id = "bar_latte_art",
            name = "Latte Art Competition",
            description = "Your shop is hosting a latte art competition!",
            probability = 0.05,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Enter and give it your all",
                    outcomes = {
                        {probability = 0.3, result = "win", description = "Your rosetta wins! $500 prize!", effects = {money = 500, reputation = 20, happiness = 25}},
                        {probability = 0.5, result = "place", description = "You placed top 3! Not bad at all.", effects = {money = 100, reputation = 10, happiness = 10}},
                        {probability = 0.2, result = "lose", description = "Your design looked like a blob. Better luck next time.", effects = {happiness = -5}}
                    }
                },
                {
                    text = "Just watch",
                    outcomes = {
                        {probability = 1.0, result = "learn", description = "You learn some new techniques from watching.", effects = {culinary = 1}}
                    }
                }
            }
        },
        {
            id = "bar_wrong_order",
            name = "The Complicated Order",
            description = "A customer ordered a 'venti half-caff triple shot sugar-free vanilla soy no-foam extra-hot latte with exactly 2.5 pumps of hazelnut' and you can't remember it all!",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Ask them to repeat it",
                    outcomes = {
                        {probability = 0.6, result = "fine", description = "They repeat it. You got it this time.", effects = {}},
                        {probability = 0.4, result = "annoyed", description = "They're visibly annoyed but repeat it.", effects = {stress = 5}}
                    }
                },
                {
                    text = "Wing it and hope for the best",
                    outcomes = {
                        {probability = 0.3, result = "nailed", description = "Somehow you nailed it!", effects = {reputation = 5}},
                        {probability = 0.7, result = "wrong", description = "It's wrong. They make you remake it. Twice.", effects = {stress = 15, reputation = -5}}
                    }
                },
                {
                    text = "Write it down next time",
                    outcomes = {
                        {probability = 1.0, result = "learn", description = "Lesson learned. Always write it down.", effects = {}}
                    }
                }
            }
        },
        {
            id = "bar_morning_rush",
            name = "Insane Morning Rush",
            description = "There's a LINE OUT THE DOOR and you're the only one on bar!",
            probability = 0.12,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Power through at top speed",
                    outcomes = {
                        {probability = 0.6, result = "hero", description = "You served 50 drinks in an hour! New record!", effects = {reputation = 15, happiness = 10, stress = 15}},
                        {probability = 0.4, result = "mistakes", description = "You made several mistakes in the rush.", effects = {reputation = -5, stress = 20}}
                    }
                },
                {
                    text = "Call for backup",
                    outcomes = {
                        {probability = 0.7, result = "help_arrives", description = "Someone comes to help. Teamwork!", effects = {stress = 10}},
                        {probability = 0.3, result = "no_help", description = "No one's available. You're on your own.", effects = {stress = 25}}
                    }
                },
                {
                    text = "Prioritize quality over speed",
                    outcomes = {
                        {probability = 0.5, result = "respected", description = "Customers appreciate the quality despite the wait.", effects = {reputation = 5, stress = 15}},
                        {probability = 0.5, result = "complaints", description = "People complain about wait times.", effects = {reputation = -10, stress = 20}}
                    }
                }
            }
        },
        {
            id = "bar_regular_crush",
            name = "Cute Regular",
            description = "That cute regular is here again. They seem to be flirting with you...",
            probability = 0.06,
            minYearsInJob = 0.2,
            choices = {
                {
                    text = "Write your number on their cup",
                    outcomes = {
                        {probability = 0.5, result = "date", description = "They text you! Date incoming!", effects = {happiness = 25, relationship = true}},
                        {probability = 0.3, result = "no_response", description = "They never text. Awkward next visit.", effects = {happiness = -10}},
                        {probability = 0.2, result = "taken", description = "Turns out they have a partner. Oops.", effects = {happiness = -5}}
                    }
                },
                {
                    text = "Keep it professional",
                    outcomes = {
                        {probability = 0.7, result = "professional", description = "You stay professional. Maybe some other time.", effects = {}},
                        {probability = 0.3, result = "ask_out", description = "THEY give YOU their number!", effects = {happiness = 20, relationship = true}}
                    }
                },
                {
                    text = "Flirt back but don't commit",
                    outcomes = {
                        {probability = 0.6, result = "fun", description = "The flirting is fun. Good tips!", effects = {money = 20, happiness = 10}},
                        {probability = 0.4, result = "mixed_signals", description = "Now it's awkward. Mixed signals everywhere.", effects = {stress = 10}}
                    }
                }
            }
        },
        {
            id = "bar_espresso_machine",
            name = "Machine Breakdown",
            description = "The espresso machine just died! There's a line of people waiting!",
            probability = 0.07,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Try to fix it yourself",
                    outcomes = {
                        {probability = 0.4, result = "fixed", description = "It just needed a reset! You're a genius!", effects = {reputation = 10}},
                        {probability = 0.6, result = "worse", description = "You made it worse. Repair guy has to come.", effects = {reputation = -5}}
                    }
                },
                {
                    text = "Offer alternative drinks",
                    outcomes = {
                        {probability = 0.7, result = "accepted", description = "Most people are happy with cold brew or tea.", effects = {}},
                        {probability = 0.3, result = "leave", description = "Half the line leaves. Sales down.", effects = {stress = 10}}
                    }
                },
                {
                    text = "Call the repair service",
                    outcomes = {
                        {probability = 0.6, result = "quick", description = "Repair comes fast. Back in business!", effects = {}},
                        {probability = 0.4, result = "hours", description = "Repair takes hours. Long day ahead.", effects = {stress = 20}}
                    }
                }
            }
        },
        {
            id = "bar_milk_allergy",
            name = "Allergy Close Call",
            description = "You almost gave a drink with dairy to someone with a severe milk allergy!",
            probability = 0.05,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Catch it and remake with oat milk",
                    outcomes = {
                        {probability = 1.0, result = "save", description = "Crisis averted. They never knew.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Double-check all allergy orders from now on",
                    outcomes = {
                        {probability = 1.0, result = "learn", description = "Scary wake-up call. You'll be more careful.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Someone ordered a 'regular coffee'. What size? What roast? DETAILS.",
        "The tip jar is looking healthy today!",
        "A customer asked if you had 'normal milk'. Sigh.",
        "Your latte art was ON POINT today.",
        "Someone took 5 minutes to order while staring at the menu.",
        "A customer pronounced it 'expresso'. Again.",
        "The blender broke during frappuccino happy hour.",
        "Someone asked for their coffee 'not too hot but not cold either'.",
        "You spilled syrup all over yourself.",
        "A dog in the drive-thru got a puppuccino!",
        "Someone came in RIGHT before close.",
        "You finally perfected the tulip latte art!",
        "A customer wrote a nice review mentioning you by name!",
        "The oat milk is out. Customers are panicking."
    }
}

-- DELIVERY DRIVER
CareerData_Part1.Jobs["Delivery Driver"] = {
    id = "delivery_driver",
    title = "Delivery Driver",
    category = "Service",
    baseSalary = 28000,
    salaryRange = {22000, 40000},
    minAge = 18,
    maxAge = nil,
    requirement = "Driver's License",
    requiredSkills = {},
    skillGains = {Physical = 1},
    description = "Deliver packages, food, or whatever needs to get somewhere fast.",
    workEnvironment = "vehicle",
    stressLevel = "medium",
    promotionPath = "Route Supervisor",
    tipsEnabled = true,
    
    careerEvents = {
        {
            id = "del_flat_tire",
            name = "Flat Tire",
            description = "You've got a flat tire in the middle of your deliveries!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Change it yourself",
                    outcomes = {
                        {probability = 0.7, result = "fixed", description = "20 minutes later, you're back on the road.", effects = {physical = 1, stress = 10}},
                        {probability = 0.3, result = "struggle", description = "The lug nuts are stuck. It takes forever.", effects = {stress = 20}}
                    }
                },
                {
                    text = "Call roadside assistance",
                    outcomes = {
                        {probability = 0.6, result = "wait", description = "Help arrives in 45 minutes. Deliveries late.", effects = {reputation = -5}},
                        {probability = 0.4, result = "long_wait", description = "2 hour wait. Multiple deliveries missed.", effects = {reputation = -15, money = -50}}
                    }
                },
                {
                    text = "Ask a nearby stranger for help",
                    outcomes = {
                        {probability = 0.5, result = "help", description = "A kind stranger helps you out!", effects = {happiness = 5}},
                        {probability = 0.5, result = "ignore", description = "Everyone ignores you. Guess you're on your own.", effects = {happiness = -5}}
                    }
                }
            }
        },
        {
            id = "del_dog_attack",
            name = "Aggressive Dog",
            description = "A big angry dog is blocking the path to the door!",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Leave package at the sidewalk",
                    outcomes = {
                        {probability = 0.7, result = "safe", description = "Safe choice. Customer can get it later.", effects = {}},
                        {probability = 0.3, result = "complaint", description = "Customer complains it was too far.", effects = {reputation = -5}}
                    }
                },
                {
                    text = "Try to befriend the dog",
                    outcomes = {
                        {probability = 0.4, result = "friend", description = "They just wanted pets! New friend!", effects = {happiness = 10}},
                        {probability = 0.6, result = "bitten", description = "CHOMP. You got bit.", effects = {health = -20, happiness = -15}}
                    }
                },
                {
                    text = "Use treats from your bag",
                    outcomes = {
                        {probability = 0.8, result = "distracted", description = "Dog is distracted. Delivery complete!", effects = {}},
                        {probability = 0.2, result = "not_food_motivated", description = "This dog isn't food motivated. Still angry.", effects = {}}
                    }
                }
            }
        },
        {
            id = "del_wrong_address",
            name = "Wrong Address",
            description = "The GPS led you to the wrong place. This isn't the right house!",
            probability = 0.09,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Call the customer",
                    outcomes = {
                        {probability = 0.8, result = "directions", description = "They give you correct directions. Problem solved!", effects = {}},
                        {probability = 0.2, result = "no_answer", description = "No answer. What now?", effects = {stress = 10}}
                    }
                },
                {
                    text = "Ask neighbors",
                    outcomes = {
                        {probability = 0.6, result = "helpful", description = "A neighbor points you to the right house.", effects = {}},
                        {probability = 0.4, result = "no_help", description = "No one knows who ordered this.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Leave it here anyway",
                    outcomes = {
                        {probability = 0.1, result = "right_place", description = "Turns out it WAS the right place! Weird GPS.", effects = {}},
                        {probability = 0.9, result = "wrong", description = "Customer never got their package. Complaint filed.", effects = {reputation = -20}}
                    }
                }
            }
        },
        {
            id = "del_huge_tip",
            name = "Generous Tipper",
            description = "The customer hands you a $100 bill as a tip!",
            probability = 0.03,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Accept it gratefully",
                    outcomes = {
                        {probability = 0.9, result = "keep", description = "A hundred bucks! What a day!", effects = {money = 100, happiness = 20}},
                        {probability = 0.1, result = "accident", description = "They meant to give a $10. They ask for change.", effects = {happiness = 5, money = 10}}
                    }
                },
                {
                    text = "Ask if they're sure",
                    outcomes = {
                        {probability = 0.7, result = "sure", description = "'Keep it, you earned it!' Wow!", effects = {money = 100, happiness = 20}},
                        {probability = 0.3, result = "mistake", description = "Oh whoops, they meant $10.", effects = {money = 10, happiness = 5}}
                    }
                }
            }
        },
        {
            id = "del_fender_bender",
            name = "Minor Accident",
            description = "You backed into a mailbox! There's a small dent in the bumper.",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Report it to your supervisor",
                    outcomes = {
                        {probability = 0.6, result = "forgiven", description = "Accidents happen. Minor penalty.", effects = {reputation = -5}},
                        {probability = 0.4, result = "trouble", description = "You get written up.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Fix the mailbox and don't mention it",
                    outcomes = {
                        {probability = 0.6, result = "fine", description = "No one ever finds out.", effects = {money = -30}},
                        {probability = 0.4, result = "caught", description = "Security camera. Now you're in double trouble.", effects = {reputation = -25}}
                    }
                },
                {
                    text = "Drive away quickly",
                    outcomes = {
                        {probability = 0.4, result = "escape", description = "What mailbox? You saw nothing.", effects = {karma = -10}},
                        {probability = 0.6, result = "witness", description = "Someone saw and got your plate number.", effects = {reputation = -20, money = -200}}
                    }
                }
            }
        },
        {
            id = "del_no_contact",
            name = "No Contact Delivery",
            description = "Instructions say 'leave at door' but there's no safe place to leave it.",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Wait and try to contact customer",
                    outcomes = {
                        {probability = 0.6, result = "answer", description = "They answer and come get it.", effects = {}},
                        {probability = 0.4, result = "no_answer", description = "No response after 10 minutes.", effects = {stress = 10}}
                    }
                },
                {
                    text = "Hide it the best you can",
                    outcomes = {
                        {probability = 0.7, result = "found", description = "Customer finds it. All good!", effects = {}},
                        {probability = 0.3, result = "stolen", description = "Package thief got to it first.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Return to depot",
                    outcomes = {
                        {probability = 1.0, result = "safe", description = "Customer will have to pick it up. Safe choice.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Traffic was BRUTAL today.",
        "A customer gave you a cold water bottle. So nice!",
        "You delivered to a mansion. Some people...",
        "Found a great shortcut that saves 10 minutes!",
        "Your car smells like pizza now. Not mad about it.",
        "Someone's package was 80 pounds. Your back...",
        "GPS sent you to a dead end. Again.",
        "A customer's doorbell played a whole song.",
        "You pet so many dogs today!",
        "Rain made every package delivery an adventure.",
        "Hit 100 deliveries in one day! New record!",
        "A customer's house had 47 stairs. No tip.",
        "Delivered to your old teacher. Awkward!",
        "Found a $20 bill on the ground between stops!"
    }
}

-- CALL CENTER AGENT
CareerData_Part1.Jobs["Call Center Agent"] = {
    id = "call_center_agent",
    title = "Call Center Agent",
    category = "Service",
    baseSalary = 26000,
    salaryRange = {22000, 35000},
    minAge = 18,
    maxAge = nil,
    requirement = nil,
    requiredSkills = {},
    skillGains = {Social = 2, Analytical = 1},
    description = "Answer phones, solve problems, and maintain your sanity.",
    workEnvironment = "office",
    stressLevel = "high",
    promotionPath = "Team Lead",
    
    careerEvents = {
        {
            id = "cc_screaming_customer",
            name = "Screaming Customer",
            description = "This customer has been SCREAMING at you for 20 minutes straight!",
            probability = 0.15,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Stay calm and professional",
                    outcomes = {
                        {probability = 0.5, result = "calm_down", description = "They eventually tire out and calm down.", effects = {stress = 15, reputation = 5}},
                        {probability = 0.5, result = "still_angry", description = "They stay angry but you handled it well.", effects = {stress = 20}}
                    }
                },
                {
                    text = "Transfer to supervisor",
                    outcomes = {
                        {probability = 0.7, result = "handled", description = "Supervisor takes over. Not your problem now.", effects = {stress = 5}},
                        {probability = 0.3, result = "supervisor_busy", description = "Supervisor is busy. You're stuck with them.", effects = {stress = 25}}
                    }
                },
                {
                    text = "'Accidentally' disconnect the call",
                    outcomes = {
                        {probability = 0.5, result = "peace", description = "Sweet silence. They don't call back.", effects = {stress = -10, happiness = 5}},
                        {probability = 0.5, result = "callback", description = "They call back angrier. And you get it again.", effects = {stress = 30}}
                    }
                },
                {
                    text = "Match their energy",
                    outcomes = {
                        {probability = 0.1, result = "respect", description = "Shockingly, they respect you standing up.", effects = {happiness = 10}},
                        {probability = 0.9, result = "fired", description = "Call was recorded. You're fired.", effects = {fired = true}}
                    }
                }
            }
        },
        {
            id = "cc_metrics_review",
            name = "Performance Review",
            description = "Your call metrics are being reviewed this week!",
            probability = 0.06,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Focus on quick calls to boost numbers",
                    outcomes = {
                        {probability = 0.6, result = "good_numbers", description = "Your numbers look great on paper!", effects = {reputation = 10, promotionProgress = 10}},
                        {probability = 0.4, result = "quality_drop", description = "Numbers up but quality scores down.", effects = {reputation = -5}}
                    }
                },
                {
                    text = "Focus on quality customer service",
                    outcomes = {
                        {probability = 0.6, result = "good_quality", description = "Great customer satisfaction scores!", effects = {reputation = 15, promotionProgress = 5}},
                        {probability = 0.4, result = "slow", description = "Quality is great but you're too slow.", effects = {reputation = -5}}
                    }
                },
                {
                    text = "Just do your normal routine",
                    outcomes = {
                        {probability = 0.5, result = "average", description = "Average across the board.", effects = {}},
                        {probability = 0.5, result = "below", description = "Below targets this quarter.", effects = {reputation = -10}}
                    }
                }
            }
        },
        {
            id = "cc_flirty_caller",
            name = "Flirty Caller",
            description = "This caller is definitely flirting with you over the phone...",
            probability = 0.05,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Keep it strictly professional",
                    outcomes = {
                        {probability = 1.0, result = "professional", description = "You steer the conversation back to business.", effects = {}}
                    }
                },
                {
                    text = "Flirt back a little",
                    outcomes = {
                        {probability = 0.6, result = "harmless", description = "Made the call more fun. No harm done.", effects = {happiness = 5}},
                        {probability = 0.4, result = "recorded", description = "Quality assurance was listening. You're talked to.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Report it as harassment",
                    outcomes = {
                        {probability = 0.7, result = "noted", description = "Management notes the incident.", effects = {}},
                        {probability = 0.3, result = "dismissed", description = "They dismiss it as harmless.", effects = {}}
                    }
                }
            }
        },
        {
            id = "cc_tech_issue",
            name = "System Crash",
            description = "The entire phone system crashes! All agents are down!",
            probability = 0.04,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Take an extended break",
                    outcomes = {
                        {probability = 0.7, result = "break", description = "Free time! Systems are down for 2 hours.", effects = {happiness = 15, stress = -10}},
                        {probability = 0.3, result = "caught", description = "Manager catches you slacking.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Help IT troubleshoot",
                    outcomes = {
                        {probability = 0.4, result = "hero", description = "You actually find the issue! IT is impressed.", effects = {reputation = 15, promotionProgress = 10}},
                        {probability = 0.6, result = "useless", description = "You tried but you're not IT.", effects = {}}
                    }
                },
                {
                    text = "Catch up on paperwork",
                    outcomes = {
                        {probability = 1.0, result = "productive", description = "Productive use of downtime.", effects = {reputation = 5}}
                    }
                }
            }
        },
        {
            id = "cc_suicide_call",
            name = "Crisis Call",
            description = "A caller reveals they're in a serious crisis and having dark thoughts...",
            probability = 0.02,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Follow crisis protocol - get supervisor",
                    outcomes = {
                        {probability = 0.9, result = "protocol", description = "Supervisor takes over with crisis training.", effects = {stress = 20}},
                        {probability = 0.1, result = "helped", description = "They get the help they need. You did the right thing.", effects = {stress = 15, happiness = 10}}
                    }
                },
                {
                    text = "Try to help them yourself",
                    outcomes = {
                        {probability = 0.4, result = "calmed", description = "Your kindness helped them through. You made a difference.", effects = {happiness = 20, stress = 25}},
                        {probability = 0.6, result = "over_head", description = "It's too much. You need to transfer.", effects = {stress = 30}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "You've said 'How can I help you?' 200 times today.",
        "A customer actually said thank you. Shocking!",
        "Your headset is giving you a headache.",
        "Someone asked you to do something completely impossible.",
        "You got a perfect quality score on a call!",
        "The hold music is stuck in your head forever now.",
        "A call lasted 2 hours. TWO. HOURS.",
        "You learned 5 new curse words from customers today.",
        "The office AC is broken. You're melting.",
        "Free pizza in the break room!",
        "Your throat hurts from talking all day.",
        "A coworker got a promotion. Could be you next time.",
        "Someone called about their printer. You don't do printers.",
        "You got a 5-star survey! Made your day!"
    }
}

return CareerData_Part1
