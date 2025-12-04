-- EventData.lua - Life Events System
-- Random life events that happen based on age, context, and traits

local EventData = {}

--============================================================================
-- EVENT CATEGORIES
--============================================================================
EventData.Categories = {
    "Random",
    "Health",
    "Relationship",
    "Financial",
    "Social",
    "Family",
    "Legal",
    "Education",
    "Death",
    "Opportunity",
    "Accident",
    "Achievement"
}

--============================================================================
-- LIFE EVENTS BY AGE GROUP
--============================================================================
EventData.Events = {
    --========================================
    -- CHILDHOOD (0-12)
    --========================================
    childhood_bully = {
        id = "childhood_bully",
        name = "School Bully",
        description = "A bigger kid is bullying you at school!",
        category = "Social",
        ageRange = {6, 12},
        probability = 0.15,
        choices = {
            {
                text = "Tell a teacher",
                outcomes = {
                    {probability = 0.5, result = "stopped", description = "The teacher intervenes. Bullying stops.", effects = {}},
                    {probability = 0.3, result = "worse", description = "The bully retaliates for 'snitching'.", effects = {happiness = -10}},
                    {probability = 0.2, result = "ignored", description = "Teacher doesn't take it seriously.", effects = {happiness = -5}}
                }
            },
            {
                text = "Tell your parents",
                outcomes = {
                    {probability = 0.6, result = "handled", description = "Your parents talk to the school. Things improve.", effects = {happiness = 5}},
                    {probability = 0.4, result = "embarrassing", description = "Now you're 'the kid whose parents complain'.", effects = {happiness = -5}}
                }
            },
            {
                text = "Stand up to them",
                outcomes = {
                    {probability = 0.3, result = "respect", description = "They back down! You earned respect!", effects = {happiness = 15, bravery = 5}},
                    {probability = 0.4, result = "fight", description = "You get in a fight! Both get in trouble.", effects = {happiness = -5}},
                    {probability = 0.3, result = "beaten", description = "They beat you up.", effects = {health = -10, happiness = -15}}
                }
            },
            {
                text = "Ignore them",
                outcomes = {
                    {probability = 0.4, result = "bored", description = "They eventually get bored and stop.", effects = {}},
                    {probability = 0.6, result = "continues", description = "The bullying continues for years.", effects = {happiness = -10, stress = 10}}
                }
            }
        }
    },
    
    childhood_pet = {
        id = "childhood_pet",
        name = "Pet Request",
        description = "You really want a pet! Will you ask your parents?",
        category = "Family",
        ageRange = {5, 12},
        probability = 0.10,
        choices = {
            {
                text = "Ask for a dog",
                outcomes = {
                    {probability = 0.4, result = "yes_dog", description = "Your parents say yes! You get a puppy!", effects = {happiness = 25, pet = "dog"}},
                    {probability = 0.6, result = "no_dog", description = "Sorry, no dogs. Maybe something smaller?", effects = {happiness = -5}}
                }
            },
            {
                text = "Ask for a cat",
                outcomes = {
                    {probability = 0.5, result = "yes_cat", description = "You get a kitten! So fluffy!", effects = {happiness = 20, pet = "cat"}},
                    {probability = 0.5, result = "no_cat", description = "Mom is allergic. No cats.", effects = {happiness = -5}}
                }
            },
            {
                text = "Ask for a hamster",
                outcomes = {
                    {probability = 0.7, result = "yes_hamster", description = "Hamsters are manageable. You get one!", effects = {happiness = 15, pet = "hamster"}},
                    {probability = 0.3, result = "no", description = "They still say no.", effects = {happiness = -5}}
                }
            },
            {
                text = "Don't ask",
                outcomes = {
                    {probability = 1.0, result = "nothing", description = "You don't ask. Maybe next year.", effects = {}}
                }
            }
        }
    },
    
    childhood_talent = {
        id = "childhood_talent",
        name = "Hidden Talent",
        description = "Your teacher noticed you have a natural talent!",
        category = "Achievement",
        ageRange = {6, 12},
        probability = 0.05,
        traitModifiers = {Intelligent = 1.5, Athletic = 1.5, Creative = 1.5},
        choices = {
            {
                text = "Develop this talent",
                outcomes = {
                    {probability = 0.8, result = "developed", description = "You start lessons and get even better!", effects = {skillBonus = true}},
                    {probability = 0.2, result = "lost_interest", description = "You tried but lost interest.", effects = {}}
                }
            },
            {
                text = "Not interested",
                outcomes = {
                    {probability = 1.0, result = "ignored", description = "Some talents are never developed.", effects = {}}
                }
            }
        }
    },
    
    --========================================
    -- TEENAGE YEARS (13-17)
    --========================================
    teen_first_kiss = {
        id = "teen_first_kiss",
        name = "First Kiss",
        description = "Someone at school wants to kiss you!",
        category = "Relationship",
        ageRange = {13, 17},
        probability = 0.12,
        traitModifiers = {Attractive = 1.5, Charismatic = 1.3, Shy = 0.7},
        choices = {
            {
                text = "Go for it!",
                outcomes = {
                    {probability = 0.6, result = "magical", description = "Your first kiss! It was magical!", effects = {happiness = 20}},
                    {probability = 0.3, result = "awkward", description = "It was... awkward. But you did it!", effects = {happiness = 5}},
                    {probability = 0.1, result = "disaster", description = "You bumped teeth. Ouch.", effects = {happiness = -5}}
                }
            },
            {
                text = "Not ready yet",
                outcomes = {
                    {probability = 0.7, result = "wait", description = "You decide to wait. No rush.", effects = {}},
                    {probability = 0.3, result = "regret", description = "They lose interest. Missed opportunity.", effects = {happiness = -5}}
                }
            }
        }
    },
    
    teen_party = {
        id = "teen_party",
        name = "House Party",
        description = "You're invited to a house party! Your parents said no...",
        category = "Social",
        ageRange = {14, 17},
        probability = 0.15,
        choices = {
            {
                text = "Sneak out and go",
                outcomes = {
                    {probability = 0.4, result = "fun", description = "Best party ever! No one found out!", effects = {happiness = 20}},
                    {probability = 0.3, result = "caught", description = "Your parents caught you sneaking back in. Grounded.", effects = {happiness = -10}},
                    {probability = 0.2, result = "trouble", description = "Party got busted by cops. You ran.", effects = {happiness = 5, stress = 15}},
                    {probability = 0.1, result = "drinking", description = "You tried alcohol for the first time.", effects = {happiness = 10}}
                }
            },
            {
                text = "Obey your parents",
                outcomes = {
                    {probability = 0.5, result = "fomo", description = "Everyone's talking about it Monday. FOMO.", effects = {happiness = -10}},
                    {probability = 0.5, result = "dodged", description = "Party got busted. Glad you weren't there!", effects = {happiness = 5}}
                }
            },
            {
                text = "Ask permission again",
                outcomes = {
                    {probability = 0.3, result = "yes", description = "They said yes with conditions!", effects = {happiness = 15}},
                    {probability = 0.7, result = "still_no", description = "Still no.", effects = {happiness = -5}}
                }
            }
        }
    },
    
    teen_driver_license = {
        id = "teen_driver_license",
        name = "Driver's License",
        description = "Time to take your driving test!",
        category = "Achievement",
        ageRange = {16, 17},
        probability = 0.30,
        oneTimePerAge = true,
        choices = {
            {
                text = "Take the test",
                outcomes = {
                    {probability = 0.7, result = "passed", description = "YOU PASSED! Freedom on four wheels!", effects = {happiness = 25, license = "driver"}},
                    {probability = 0.3, result = "failed", description = "Failed parallel parking. Try again later.", effects = {happiness = -15}}
                }
            },
            {
                text = "Wait until you're more ready",
                outcomes = {
                    {probability = 1.0, result = "delayed", description = "Better to be safe. You'll try later.", effects = {}}
                }
            }
        }
    },
    
    teen_college_decision = {
        id = "teen_college_decision",
        name = "College Applications",
        description = "Senior year! Time to think about your future.",
        category = "Education",
        ageRange = {17, 18},
        probability = 0.50,
        oneTimePerAge = true,
        choices = {
            {
                text = "Apply to top universities",
                outcomes = {
                    {probability = 0.4, result = "accepted", description = "You got into your dream school!", effects = {happiness = 30}},
                    {probability = 0.4, result = "waitlist", description = "Waitlisted at dream school, but accepted elsewhere.", effects = {happiness = 10}},
                    {probability = 0.2, result = "rejected", description = "Rejected. Your backup school it is.", effects = {happiness = -10}}
                }
            },
            {
                text = "Apply to state schools",
                outcomes = {
                    {probability = 0.8, result = "accepted", description = "Accepted! Affordable education!", effects = {happiness = 15}},
                    {probability = 0.2, result = "rejected", description = "Community college might be the path.", effects = {happiness = -5}}
                }
            },
            {
                text = "Skip college - work instead",
                outcomes = {
                    {probability = 0.5, result = "good_choice", description = "Not everyone needs college. You'll do your own thing.", effects = {}},
                    {probability = 0.5, result = "pressure", description = "Everyone questions your choice.", effects = {stress = 10}}
                }
            }
        }
    },
    
    --========================================
    -- YOUNG ADULT (18-30)
    --========================================
    adult_move_out = {
        id = "adult_move_out",
        name = "Moving Out",
        description = "Time to leave the nest? Your parents ask about your plans.",
        category = "Family",
        ageRange = {18, 25},
        probability = 0.20,
        requiresLivingWithParents = true,
        choices = {
            {
                text = "Get your own place",
                outcomes = {
                    {probability = 0.6, result = "independent", description = "Freedom! Your own space! (Also bills...)", effects = {happiness = 20, money = -500}},
                    {probability = 0.4, result = "struggle", description = "Rent is EXPENSIVE. But you're doing it.", effects = {happiness = 10, money = -800}}
                }
            },
            {
                text = "Get roommates",
                outcomes = {
                    {probability = 0.5, result = "fun", description = "Roommates are great! Instant social life!", effects = {happiness = 15, money = -300}},
                    {probability = 0.5, result = "nightmare", description = "Roommate from hell. At least rent is cheap.", effects = {happiness = -5, money = -300}}
                }
            },
            {
                text = "Stay home a bit longer",
                outcomes = {
                    {probability = 0.6, result = "comfortable", description = "Smart financial choice. Save that money.", effects = {money = 200}},
                    {probability = 0.4, result = "pressure", description = "Parents are getting annoyed...", effects = {stress = 10}}
                }
            }
        }
    },
    
    adult_career_change = {
        id = "adult_career_change",
        name = "Quarter-Life Crisis",
        description = "Is this really what you want to do with your life?",
        category = "Random",
        ageRange = {25, 35},
        probability = 0.10,
        requiresJob = true,
        choices = {
            {
                text = "Make a major change",
                outcomes = {
                    {probability = 0.5, result = "success", description = "The change was scary but right!", effects = {happiness = 25}},
                    {probability = 0.5, result = "struggle", description = "Starting over is hard.", effects = {happiness = -10, money = -5000}}
                }
            },
            {
                text = "Stay the course",
                outcomes = {
                    {probability = 0.6, result = "content", description = "You find meaning in what you do.", effects = {happiness = 5}},
                    {probability = 0.4, result = "regret", description = "The 'what if' never quite goes away.", effects = {happiness = -5}}
                }
            },
            {
                text = "Seek therapy to figure it out",
                outcomes = {
                    {probability = 0.8, result = "clarity", description = "Therapy helps you find clarity.", effects = {happiness = 15, money = -500}},
                    {probability = 0.2, result = "confused", description = "Still confused, but working on it.", effects = {money = -500}}
                }
            }
        }
    },
    
    --========================================
    -- HEALTH EVENTS
    --========================================
    health_cold = {
        id = "health_cold",
        name = "Common Cold",
        description = "You've caught a cold!",
        category = "Health",
        ageRange = {0, 100},
        probability = 0.15,
        choices = {
            {
                text = "Rest and recover",
                outcomes = {
                    {probability = 0.9, result = "recovered", description = "A few days of rest and you're better.", effects = {health = -5}},
                    {probability = 0.1, result = "worse", description = "It turned into a sinus infection.", effects = {health = -15, money = -100}}
                }
            },
            {
                text = "Push through it",
                outcomes = {
                    {probability = 0.4, result = "fine", description = "Mind over matter. You powered through.", effects = {health = -5}},
                    {probability = 0.6, result = "spreads", description = "You got everyone else sick too.", effects = {health = -10, karma = -5}}
                }
            }
        }
    },
    
    health_accident = {
        id = "health_accident",
        name = "Car Accident",
        description = "You've been in a car accident!",
        category = "Accident",
        ageRange = {16, 100},
        probability = 0.03,
        requiresLicense = true,
        choices = {
            {
                text = "Assess the damage",
                outcomes = {
                    {probability = 0.5, result = "minor", description = "Minor fender bender. Everyone's okay.", effects = {money = -500}},
                    {probability = 0.3, result = "moderate", description = "You're bruised up. Car is totaled.", effects = {health = -20, money = -5000}},
                    {probability = 0.2, result = "serious", description = "Hospital stay required.", effects = {health = -40, money = -10000}}
                }
            }
        }
    },
    
    health_serious = {
        id = "health_serious",
        name = "Serious Diagnosis",
        description = "The doctor has some concerning news...",
        category = "Health",
        ageRange = {40, 100},
        probability = 0.05,
        traitModifiers = {Unlucky = 1.5},
        choices = {
            {
                text = "Get treatment immediately",
                outcomes = {
                    {probability = 0.7, result = "recovery", description = "Caught early. Treatment is working.", effects = {health = -20, money = -10000, happiness = -15}},
                    {probability = 0.3, result = "ongoing", description = "It's going to be a long fight.", effects = {health = -30, money = -20000}}
                }
            },
            {
                text = "Get a second opinion",
                outcomes = {
                    {probability = 0.3, result = "misdiagnosis", description = "Second opinion says it's not as serious!", effects = {happiness = 20}},
                    {probability = 0.7, result = "confirmed", description = "Diagnosis confirmed. Time to fight.", effects = {health = -25, money = -15000}}
                }
            }
        }
    },
    
    --========================================
    -- FINANCIAL EVENTS
    --========================================
    financial_windfall = {
        id = "financial_windfall",
        name = "Unexpected Windfall",
        description = "You received an unexpected sum of money!",
        category = "Financial",
        ageRange = {18, 100},
        probability = 0.03,
        traitModifiers = {Lucky = 2.0},
        choices = {
            {
                text = "Invest it wisely",
                outcomes = {
                    {probability = 0.6, result = "grew", description = "Smart investing! Your money grew!", effects = {money = 15000}},
                    {probability = 0.4, result = "lost", description = "Market crashed. Lost most of it.", effects = {money = 3000}}
                }
            },
            {
                text = "Spend it on something nice",
                outcomes = {
                    {probability = 0.8, result = "enjoyed", description = "YOLO! You treated yourself!", effects = {money = 5000, happiness = 20}},
                    {probability = 0.2, result = "regret", description = "Probably should have saved that.", effects = {money = 2000, happiness = 5}}
                }
            },
            {
                text = "Save it all",
                outcomes = {
                    {probability = 1.0, result = "saved", description = "Into savings it goes.", effects = {money = 10000}}
                }
            }
        }
    },
    
    financial_scam = {
        id = "financial_scam",
        name = "Scam Attempt",
        description = "Someone is trying to scam you out of money!",
        category = "Financial",
        ageRange = {18, 100},
        probability = 0.08,
        traitModifiers = {Intelligent = 0.5, Stupid = 2.0},
        choices = {
            {
                text = "Recognize and ignore it",
                outcomes = {
                    {probability = 1.0, result = "avoided", description = "Nice try, scammer! You're too smart for that.", effects = {}}
                }
            },
            {
                text = "Fall for it",
                hidden = true,
                outcomes = {
                    {probability = 1.0, result = "scammed", description = "You got scammed! Money gone!", effects = {money = -5000, happiness = -20}}
                }
            },
            {
                text = "Report it to authorities",
                outcomes = {
                    {probability = 0.3, result = "caught", description = "Your report helped catch the scammer!", effects = {karma = 10}},
                    {probability = 0.7, result = "nothing", description = "They couldn't do anything. At least you reported it.", effects = {karma = 5}}
                }
            }
        }
    },
    
    --========================================
    -- RELATIONSHIP EVENTS
    --========================================
    relationship_proposal = {
        id = "relationship_proposal",
        name = "Marriage Proposal",
        description = "Your partner is proposing!",
        category = "Relationship",
        ageRange = {18, 80},
        probability = 0.08,
        requiresPartner = true,
        minRelationshipLength = 1,
        choices = {
            {
                text = "Say yes!",
                outcomes = {
                    {probability = 0.9, result = "engaged", description = "You're engaged! Wedding planning begins!", effects = {happiness = 40, engaged = true}},
                    {probability = 0.1, result = "doubts", description = "You said yes but you have doubts...", effects = {happiness = 10, engaged = true}}
                }
            },
            {
                text = "Say no",
                outcomes = {
                    {probability = 0.5, result = "breakup", description = "They're devastated. Relationship ends.", effects = {happiness = -20, singleAgain = true}},
                    {probability = 0.5, result = "stay_together", description = "They're hurt but you stay together.", effects = {happiness = -10}}
                }
            },
            {
                text = "Ask for more time",
                outcomes = {
                    {probability = 0.6, result = "understanding", description = "They understand. No rush.", effects = {}},
                    {probability = 0.4, result = "upset", description = "They're upset but give you time.", effects = {happiness = -5}}
                }
            }
        }
    },
    
    relationship_cheating = {
        id = "relationship_cheating",
        name = "Temptation",
        description = "Someone is very interested in you... but you're in a relationship.",
        category = "Relationship",
        ageRange = {18, 80},
        probability = 0.06,
        requiresPartner = true,
        traitModifiers = {Attractive = 1.5, Charismatic = 1.3},
        choices = {
            {
                text = "Stay faithful",
                outcomes = {
                    {probability = 0.9, result = "loyal", description = "You stay loyal. Right choice.", effects = {karma = 10}},
                    {probability = 0.1, result = "what_if", description = "You wonder 'what if' but stay loyal.", effects = {karma = 5}}
                }
            },
            {
                text = "Cheat",
                outcomes = {
                    {probability = 0.4, result = "secret", description = "It happened. No one knows... for now.", effects = {karma = -20}},
                    {probability = 0.6, result = "caught", description = "Your partner found out! Relationship destroyed!", effects = {karma = -25, happiness = -20, singleAgain = true}}
                }
            },
            {
                text = "Talk to your partner about your feelings",
                outcomes = {
                    {probability = 0.5, result = "strengthen", description = "Honesty strengthens your relationship.", effects = {karma = 5, happiness = 5}},
                    {probability = 0.5, result = "issues", description = "Opens up underlying relationship issues.", effects = {happiness = -10}}
                }
            }
        }
    },
    
    --========================================
    -- RANDOM LIFE EVENTS
    --========================================
    random_lottery = {
        id = "random_lottery",
        name = "Lottery Ticket",
        description = "You found a $5 lottery ticket on the ground!",
        category = "Financial",
        ageRange = {18, 100},
        probability = 0.02,
        traitModifiers = {Lucky = 3.0},
        choices = {
            {
                text = "Scratch it",
                outcomes = {
                    {probability = 0.5, result = "nothing", description = "Not a winner. Oh well.", effects = {}},
                    {probability = 0.3, result = "small", description = "Won $20! Free money!", effects = {money = 20, happiness = 5}},
                    {probability = 0.15, result = "medium", description = "Won $500! Nice!", effects = {money = 500, happiness = 15}},
                    {probability = 0.04, result = "big", description = "Won $10,000! Lucky day!", effects = {money = 10000, happiness = 30}},
                    {probability = 0.01, result = "jackpot", description = "JACKPOT! $1,000,000! Life-changing!", effects = {money = 1000000, happiness = 50, fame = 5}}
                }
            },
            {
                text = "Throw it away",
                outcomes = {
                    {probability = 0.9, result = "nothing", description = "Probably wasn't a winner anyway.", effects = {}},
                    {probability = 0.1, result = "regret", description = "You hear someone won a jackpot with a ticket just like that...", effects = {happiness = -5}}
                }
            }
        }
    },
    
    random_celebrity = {
        id = "random_celebrity",
        name = "Celebrity Encounter",
        description = "You spot a famous celebrity in public!",
        category = "Social",
        ageRange = {10, 100},
        probability = 0.02,
        choices = {
            {
                text = "Ask for a photo",
                outcomes = {
                    {probability = 0.6, result = "photo", description = "They said yes! You have a selfie with a celeb!", effects = {happiness = 20}},
                    {probability = 0.3, result = "no", description = "They politely decline. Understandable.", effects = {}},
                    {probability = 0.1, result = "rude", description = "They were rude about it. Less of a fan now.", effects = {happiness = -5}}
                }
            },
            {
                text = "Respect their privacy",
                outcomes = {
                    {probability = 0.8, result = "respect", description = "You nod and let them be. Classy.", effects = {karma = 5}},
                    {probability = 0.2, result = "noticed", description = "They noticed your respect and smiled at you!", effects = {happiness = 10}}
                }
            },
            {
                text = "Freak out",
                outcomes = {
                    {probability = 0.5, result = "embarrass", description = "You made a scene. So embarrassing.", effects = {happiness = -10}},
                    {probability = 0.5, result = "laugh", description = "Your reaction made them laugh! Cute moment.", effects = {happiness = 15}}
                }
            }
        }
    },
    
    random_crime_witness = {
        id = "random_crime_witness",
        name = "Witness to Crime",
        description = "You witness a crime happening!",
        category = "Legal",
        ageRange = {16, 100},
        probability = 0.04,
        choices = {
            {
                text = "Call 911",
                outcomes = {
                    {probability = 0.7, result = "helped", description = "Police respond. Your call may have saved someone.", effects = {karma = 15}},
                    {probability = 0.3, result = "too_late", description = "Police arrived but criminals escaped.", effects = {karma = 10}}
                }
            },
            {
                text = "Intervene directly",
                outcomes = {
                    {probability = 0.3, result = "hero", description = "You stopped the crime! Local hero!", effects = {karma = 25, fame = 5, reputation = 20}},
                    {probability = 0.4, result = "helped", description = "Your intervention helped. Criminals fled.", effects = {karma = 20}},
                    {probability = 0.3, result = "hurt", description = "You got hurt trying to help.", effects = {karma = 15, health = -25}}
                }
            },
            {
                text = "Walk away",
                outcomes = {
                    {probability = 0.6, result = "safe", description = "Not your problem. You stay safe.", effects = {karma = -10}},
                    {probability = 0.4, result = "guilt", description = "You wonder if you could have helped.", effects = {karma = -15, happiness = -10}}
                }
            }
        }
    },
    
    --========================================
    -- DEATH EVENTS
    --========================================
    death_family = {
        id = "death_family",
        name = "Family Loss",
        description = "A family member has passed away...",
        category = "Death",
        ageRange = {10, 100},
        probability = 0.05,
        requiresFamily = true,
        choices = {
            {
                text = "Grieve and process",
                outcomes = {
                    {probability = 0.7, result = "heal", description = "It takes time, but you start to heal.", effects = {happiness = -30, familyMemberDeath = true}},
                    {probability = 0.3, result = "struggle", description = "The grief is overwhelming.", effects = {happiness = -40, stress = 20, familyMemberDeath = true}}
                }
            },
            {
                text = "Seek support from loved ones",
                outcomes = {
                    {probability = 0.8, result = "supported", description = "Family and friends rally around you.", effects = {happiness = -25, familyMemberDeath = true}},
                    {probability = 0.2, result = "alone", description = "Everyone is dealing with their own grief.", effects = {happiness = -35, familyMemberDeath = true}}
                }
            }
        }
    },
    
    --========================================
    -- OPPORTUNITY EVENTS
    --========================================
    opportunity_investment = {
        id = "opportunity_investment",
        name = "Investment Opportunity",
        description = "A friend offers you a chance to invest in their startup!",
        category = "Opportunity",
        ageRange = {25, 70},
        probability = 0.04,
        minMoney = 10000,
        choices = {
            {
                text = "Invest $10,000",
                outcomes = {
                    {probability = 0.2, result = "rich", description = "The startup explodes! Your investment 10x!", effects = {money = 100000, happiness = 40}},
                    {probability = 0.3, result = "profit", description = "Startup does well! You doubled your money!", effects = {money = 20000, happiness = 20}},
                    {probability = 0.5, result = "lost", description = "Startup failed. Lost your investment.", effects = {money = -10000, happiness = -15}}
                }
            },
            {
                text = "Decline politely",
                outcomes = {
                    {probability = 0.5, result = "dodged", description = "Company fails. Glad you didn't invest.", effects = {}},
                    {probability = 0.5, result = "missed", description = "Company succeeds. FOMO is real.", effects = {happiness = -10}}
                }
            },
            {
                text = "Invest less ($1,000)",
                outcomes = {
                    {probability = 0.3, result = "profit", description = "Safe bet paid off! Made $5,000!", effects = {money = 5000, happiness = 10}},
                    {probability = 0.7, result = "lost", description = "Lost $1,000 but not devastating.", effects = {money = -1000}}
                }
            }
        }
    }
}

--============================================================================
-- HELPER FUNCTIONS
--============================================================================

-- Get eligible events for current player state
function EventData.GetEligibleEvents(playerState)
    local eligible = {}
    
    for _, event in pairs(EventData.Events) do
        if EventData.PlayerEligible(playerState, event) then
            table.insert(eligible, event)
        end
    end
    
    return eligible
end

-- Check if player is eligible for an event
function EventData.PlayerEligible(playerState, event)
    local age = playerState.age or 0
    
    -- Age check
    if event.ageRange then
        if age < event.ageRange[1] or age > event.ageRange[2] then
            return false
        end
    end
    
    -- Money requirement
    if event.minMoney and (playerState.money or 0) < event.minMoney then
        return false
    end
    
    -- License requirement
    if event.requiresLicense and not playerState.driversLicense then
        return false
    end
    
    -- Job requirement
    if event.requiresJob and not playerState.job then
        return false
    end
    
    -- Partner requirement
    if event.requiresPartner and not playerState.partner then
        return false
    end
    
    -- Family requirement
    if event.requiresFamily and not playerState.family then
        return false
    end
    
    -- One-time per age check
    if event.oneTimePerAge then
        local eventHistory = playerState.eventHistory or {}
        if eventHistory[event.id .. "_" .. age] then
            return false
        end
    end
    
    return true
end

-- Roll for a random event
function EventData.RollForEvent(playerState, traitModifiers)
    local eligible = EventData.GetEligibleEvents(playerState)
    if #eligible == 0 then return nil end
    
    -- Apply trait modifiers to probabilities
    traitModifiers = traitModifiers or {}
    
    for _, event in ipairs(eligible) do
        local probability = event.probability or 0.05
        
        -- Apply trait modifiers
        if event.traitModifiers then
            for trait, modifier in pairs(event.traitModifiers) do
                if traitModifiers[trait] then
                    probability = probability * modifier
                end
            end
        end
        
        if math.random() < probability then
            return event
        end
    end
    
    return nil
end

-- Process event outcome
function EventData.ProcessOutcome(event, choiceIndex)
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

return EventData
