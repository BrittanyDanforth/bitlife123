-- ActivityData.lua - Activities, Crimes, and Prison Actions
-- Comprehensive activity system with effects and outcomes

local ActivityData = {}

--============================================================================
-- ACTIVITY CATEGORIES
--============================================================================
ActivityData.Categories = {
    MindBody = "Mind & Body",
    Social = "Social",
    Entertainment = "Entertainment",
    Crime = "Crime",
    Prison = "Prison"
}

--============================================================================
-- MIND & BODY ACTIVITIES
--============================================================================
ActivityData.MindBody = {
    gym = {
        id = "gym",
        name = "Go to the Gym",
        description = "Work out and improve your fitness",
        icon = "💪",
        minAge = 12,
        cost = 0,
        effects = {
            health = {5, 10},
            happiness = {2, 5},
            looks = {1, 3},
            stress = {-3, -1}
        },
        skillGains = {Physical = 2, Athletic = 1},
        duration = 1, -- hours
        outcomes = {
            {weight = 0.6, text = "Great workout! You feel stronger.", bonusEffects = {}},
            {weight = 0.2, text = "You pushed yourself hard. Personal best!", bonusEffects = {Physical = 2}},
            {weight = 0.1, text = "You pulled a muscle. Ouch!", bonusEffects = {health = -10}},
            {weight = 0.1, text = "Made a new gym buddy!", bonusEffects = {Social = 1, happiness = 5}}
        }
    },
    
    meditation = {
        id = "meditation",
        name = "Meditate",
        description = "Clear your mind and find inner peace",
        icon = "🧘",
        minAge = 10,
        cost = 0,
        effects = {
            stress = {-10, -5},
            happiness = {3, 8},
            health = {1, 3}
        },
        skillGains = {},
        duration = 0.5,
        outcomes = {
            {weight = 0.7, text = "You feel centered and calm.", bonusEffects = {}},
            {weight = 0.2, text = "Deep meditation! You feel enlightened.", bonusEffects = {smarts = 1}},
            {weight = 0.1, text = "You fell asleep. Well-rested at least!", bonusEffects = {health = 5}}
        }
    },
    
    library = {
        id = "library",
        name = "Study at the Library",
        description = "Expand your knowledge through reading",
        icon = "📚",
        minAge = 6,
        cost = 0,
        effects = {
            smarts = {2, 5},
            happiness = {0, 3}
        },
        skillGains = {Analytical = 1, Writing = 1},
        duration = 2,
        outcomes = {
            {weight = 0.6, text = "You learned something new today.", bonusEffects = {}},
            {weight = 0.2, text = "That book changed your perspective!", bonusEffects = {smarts = 3}},
            {weight = 0.1, text = "Fell asleep reading. The librarian wasn't pleased.", bonusEffects = {}},
            {weight = 0.1, text = "Met an interesting person in the stacks.", bonusEffects = {Social = 1}}
        }
    },
    
    martialArts = {
        id = "martialArts",
        name = "Take Martial Arts Class",
        description = "Learn self-defense and discipline",
        icon = "🥋",
        minAge = 8,
        cost = 50,
        effects = {
            health = {3, 6},
            happiness = {3, 6}
        },
        skillGains = {Physical = 2, Athletic = 1},
        statBonus = {fighting = 3},
        duration = 1.5,
        outcomes = {
            {weight = 0.5, text = "Your technique is improving.", bonusEffects = {}},
            {weight = 0.3, text = "You earned a new belt!", bonusEffects = {happiness = 10}},
            {weight = 0.1, text = "Got knocked down in sparring.", bonusEffects = {health = -5}},
            {weight = 0.1, text = "The sensei praised your dedication!", bonusEffects = {Leadership = 1}}
        }
    },
    
    yoga = {
        id = "yoga",
        name = "Do Yoga",
        description = "Improve flexibility and mental clarity",
        icon = "🧘‍♀️",
        minAge = 12,
        cost = 20,
        effects = {
            health = {3, 6},
            stress = {-8, -4},
            happiness = {3, 6}
        },
        skillGains = {Physical = 1},
        duration = 1,
        outcomes = {
            {weight = 0.7, text = "Namaste! You feel balanced.", bonusEffects = {}},
            {weight = 0.2, text = "You finally nailed that difficult pose!", bonusEffects = {looks = 1}},
            {weight = 0.1, text = "Pulled something. Not very zen.", bonusEffects = {health = -3}}
        }
    },
    
    therapy = {
        id = "therapy",
        name = "See a Therapist",
        description = "Work through your mental health with a professional",
        icon = "🛋️",
        minAge = 16,
        cost = 150,
        effects = {
            happiness = {5, 15},
            stress = {-15, -8}
        },
        skillGains = {},
        duration = 1,
        canRemoveTrait = {"Depressed", "Anxious", "Insecure"},
        outcomes = {
            {weight = 0.6, text = "That session was helpful.", bonusEffects = {}},
            {weight = 0.3, text = "A real breakthrough today!", bonusEffects = {happiness = 10}},
            {weight = 0.1, text = "Hard session. Brought up painful memories.", bonusEffects = {stress = 5}}
        }
    },
    
    doctor = {
        id = "doctor",
        name = "Visit the Doctor",
        description = "Get a checkup or treat health issues",
        icon = "🏥",
        minAge = 0,
        cost = 100,
        effects = {
            health = {5, 15}
        },
        skillGains = {},
        duration = 1,
        outcomes = {
            {weight = 0.6, text = "Clean bill of health!", bonusEffects = {}},
            {weight = 0.2, text = "Doctor caught something early. Good you came!", bonusEffects = {health = 10}},
            {weight = 0.15, text = "Nothing serious. Take some vitamins.", bonusEffects = {}},
            {weight = 0.05, text = "They found something concerning...", bonusEffects = {health = -20, stress = 20}}
        }
    },
    
    dentist = {
        id = "dentist",
        name = "Visit the Dentist",
        description = "Keep those teeth healthy",
        icon = "🦷",
        minAge = 3,
        cost = 75,
        effects = {
            health = {2, 5},
            looks = {1, 2}
        },
        skillGains = {},
        duration = 1,
        outcomes = {
            {weight = 0.5, text = "No cavities! Keep flossing.", bonusEffects = {}},
            {weight = 0.3, text = "One small cavity. Fixed now.", bonusEffects = {}},
            {weight = 0.15, text = "Your smile is picture perfect!", bonusEffects = {looks = 2}},
            {weight = 0.05, text = "Root canal needed. Ouch and expensive.", bonusEffects = {money = -500, health = -5}}
        }
    }
}

--============================================================================
-- SOCIAL ACTIVITIES
--============================================================================
ActivityData.Social = {
    party = {
        id = "party",
        name = "Go to a Party",
        description = "Let loose and socialize",
        icon = "🎉",
        minAge = 14,
        cost = 30,
        effects = {
            happiness = {10, 20},
            stress = {-5, -2}
        },
        skillGains = {Social = 2, Charisma = 1},
        duration = 4,
        outcomes = {
            {weight = 0.4, text = "Great party! Had a blast!", bonusEffects = {}},
            {weight = 0.2, text = "Made some new friends!", bonusEffects = {Social = 2}},
            {weight = 0.2, text = "Things got wild. What a night!", bonusEffects = {happiness = 10, karma = -2}},
            {weight = 0.1, text = "Someone there was interested in you...", bonusEffects = {happiness = 15}},
            {weight = 0.1, text = "Party was kind of lame.", bonusEffects = {happiness = -5}}
        }
    },
    
    bar = {
        id = "bar",
        name = "Hit the Bar",
        description = "Drinks and socializing at a bar",
        icon = "🍺",
        minAge = 21,
        cost = 50,
        effects = {
            happiness = {5, 15},
            stress = {-5, -2}
        },
        skillGains = {Social = 1},
        duration = 3,
        risks = {addiction = 0.02},
        outcomes = {
            {weight = 0.4, text = "Good drinks, good conversation.", bonusEffects = {}},
            {weight = 0.2, text = "You had a great time!", bonusEffects = {happiness = 5}},
            {weight = 0.2, text = "Drank too much. Rough morning ahead.", bonusEffects = {health = -5}},
            {weight = 0.1, text = "Got into a bar fight!", bonusEffects = {health = -10}},
            {weight = 0.1, text = "Met someone special...", bonusEffects = {happiness = 20}}
        }
    },
    
    club = {
        id = "club",
        name = "Go Clubbing",
        description = "Dance the night away",
        icon = "🪩",
        minAge = 18,
        cost = 75,
        effects = {
            happiness = {10, 20},
            stress = {-8, -3}
        },
        skillGains = {Social = 2},
        duration = 5,
        outcomes = {
            {weight = 0.5, text = "Danced all night! Amazing!", bonusEffects = {}},
            {weight = 0.2, text = "Your dance moves impressed everyone!", bonusEffects = {Charisma = 1}},
            {weight = 0.15, text = "Met some interesting people.", bonusEffects = {Social = 2}},
            {weight = 0.1, text = "VIP treatment! Someone recognized you.", bonusEffects = {fame = 1}},
            {weight = 0.05, text = "Lost your wallet. Great.", bonusEffects = {money = -200}}
        }
    },
    
    volunteer = {
        id = "volunteer",
        name = "Volunteer Work",
        description = "Give back to the community",
        icon = "🤝",
        minAge = 12,
        cost = 0,
        effects = {
            happiness = {5, 10},
            karma = {5, 15}
        },
        skillGains = {Social = 1, Leadership = 1},
        duration = 3,
        outcomes = {
            {weight = 0.6, text = "You made a difference today.", bonusEffects = {}},
            {weight = 0.2, text = "The people you helped were so grateful!", bonusEffects = {happiness = 10}},
            {weight = 0.1, text = "Got recognized for your service!", bonusEffects = {reputation = 5}},
            {weight = 0.1, text = "Made connections with other volunteers.", bonusEffects = {Social = 2}}
        }
    },
    
    dating = {
        id = "dating",
        name = "Go on a Date",
        description = "Spend time with a romantic interest",
        icon = "💕",
        minAge = 16,
        cost = 100,
        requiresPartner = true,
        effects = {
            happiness = {10, 20}
        },
        skillGains = {Social = 1, Charisma = 1},
        duration = 3,
        outcomes = {
            {weight = 0.5, text = "Wonderful date! You're so happy together.", bonusEffects = {relationshipBonus = 10}},
            {weight = 0.2, text = "Best date ever! Sparks flying!", bonusEffects = {relationshipBonus = 15, happiness = 10}},
            {weight = 0.2, text = "Nice time. Comfortable together.", bonusEffects = {relationshipBonus = 5}},
            {weight = 0.1, text = "Awkward. Ran out of things to talk about.", bonusEffects = {relationshipBonus = -5}}
        }
    },
    
    concert = {
        id = "concert",
        name = "Attend a Concert",
        description = "See live music",
        icon = "🎸",
        minAge = 10,
        cost = 100,
        effects = {
            happiness = {15, 25},
            stress = {-5, -2}
        },
        skillGains = {Musical = 1},
        duration = 3,
        outcomes = {
            {weight = 0.6, text = "Amazing show! What an experience!", bonusEffects = {}},
            {weight = 0.2, text = "You caught a guitar pick! Souvenir!", bonusEffects = {happiness = 5}},
            {weight = 0.1, text = "Met the band backstage!", bonusEffects = {happiness = 20, fame = 1}},
            {weight = 0.1, text = "Too crowded and loud. Headache.", bonusEffects = {happiness = -5}}
        }
    },
    
    sports_game = {
        id = "sports_game",
        name = "Watch a Sports Game",
        description = "Cheer on your favorite team",
        icon = "🏟️",
        minAge = 5,
        cost = 50,
        effects = {
            happiness = {10, 20},
            stress = {-3, 3}
        },
        skillGains = {},
        duration = 3,
        outcomes = {
            {weight = 0.4, text = "Your team won! Great game!", bonusEffects = {happiness = 10}},
            {weight = 0.3, text = "Your team lost. Sports are heartbreak.", bonusEffects = {happiness = -5}},
            {weight = 0.2, text = "Close game! Edge of your seat!", bonusEffects = {}},
            {weight = 0.1, text = "Caught a foul ball!", bonusEffects = {happiness = 15}}
        }
    }
}

--============================================================================
-- ENTERTAINMENT ACTIVITIES
--============================================================================
ActivityData.Entertainment = {
    movies = {
        id = "movies",
        name = "Watch a Movie",
        description = "Catch a film at the theater",
        icon = "🎬",
        minAge = 5,
        cost = 15,
        effects = {
            happiness = {5, 12}
        },
        skillGains = {},
        duration = 2,
        outcomes = {
            {weight = 0.5, text = "Great movie! Really enjoyed it.", bonusEffects = {}},
            {weight = 0.2, text = "Meh. That was disappointing.", bonusEffects = {happiness = -3}},
            {weight = 0.2, text = "That was incredible! New favorite film!", bonusEffects = {happiness = 5}},
            {weight = 0.1, text = "Fell asleep. Well-rested though!", bonusEffects = {}}
        }
    },
    
    videogames = {
        id = "videogames",
        name = "Play Video Games",
        description = "Game for a while",
        icon = "🎮",
        minAge = 6,
        cost = 0,
        effects = {
            happiness = {5, 10},
            stress = {-5, -2}
        },
        skillGains = {Technical = 1},
        duration = 2,
        outcomes = {
            {weight = 0.5, text = "Good gaming session.", bonusEffects = {}},
            {weight = 0.2, text = "You won! Sweet victory!", bonusEffects = {happiness = 5}},
            {weight = 0.2, text = "Lost track of time. 5 hours later...", bonusEffects = {health = -2}},
            {weight = 0.1, text = "Rage quit. Controller survived though.", bonusEffects = {stress = 5}}
        }
    },
    
    reading = {
        id = "reading",
        name = "Read a Book",
        description = "Get lost in a good book",
        icon = "📖",
        minAge = 6,
        cost = 0,
        effects = {
            happiness = {3, 8},
            smarts = {1, 3}
        },
        skillGains = {Writing = 1},
        duration = 2,
        outcomes = {
            {weight = 0.6, text = "Good read. Expanded your mind.", bonusEffects = {}},
            {weight = 0.3, text = "Couldn't put it down! Finished the whole thing!", bonusEffects = {smarts = 2}},
            {weight = 0.1, text = "Boring book. DNF.", bonusEffects = {happiness = -2}}
        }
    },
    
    gambling = {
        id = "gambling",
        name = "Go Gambling",
        description = "Test your luck at the casino",
        icon = "🎰",
        minAge = 21,
        cost = 100,
        effects = {},
        skillGains = {},
        duration = 3,
        risks = {addiction = 0.05},
        outcomes = {
            {weight = 0.4, text = "Lost your money. House always wins.", bonusEffects = {money = -100, happiness = -10}},
            {weight = 0.3, text = "Broke even. Could be worse.", bonusEffects = {}},
            {weight = 0.2, text = "Won some money!", bonusEffects = {money = 200, happiness = 15}},
            {weight = 0.08, text = "Big winner!", bonusEffects = {money = 1000, happiness = 25}},
            {weight = 0.02, text = "JACKPOT!", bonusEffects = {money = 10000, happiness = 50}}
        }
    },
    
    shopping = {
        id = "shopping",
        name = "Go Shopping",
        description = "Retail therapy",
        icon = "🛍️",
        minAge = 10,
        cost = 100,
        effects = {
            happiness = {5, 15},
            looks = {1, 3}
        },
        skillGains = {},
        duration = 2,
        outcomes = {
            {weight = 0.6, text = "Found some great stuff!", bonusEffects = {}},
            {weight = 0.2, text = "Spent way more than planned.", bonusEffects = {money = -150}},
            {weight = 0.1, text = "Amazing sale! Saved so much!", bonusEffects = {money = 50}},
            {weight = 0.1, text = "Nothing good. Waste of time.", bonusEffects = {happiness = -5}}
        }
    },
    
    vacation = {
        id = "vacation",
        name = "Take a Vacation",
        description = "Get away from it all",
        icon = "✈️",
        minAge = 18,
        cost = 2000,
        effects = {
            happiness = {20, 40},
            stress = {-30, -20},
            health = {5, 10}
        },
        skillGains = {Social = 1},
        duration = 168, -- One week
        outcomes = {
            {weight = 0.6, text = "Amazing trip! Memories for a lifetime.", bonusEffects = {}},
            {weight = 0.2, text = "Best vacation ever! Life-changing!", bonusEffects = {happiness = 20}},
            {weight = 0.1, text = "Relaxing trip. Just what you needed.", bonusEffects = {}},
            {weight = 0.08, text = "Vacation romance!", bonusEffects = {happiness = 25}},
            {weight = 0.02, text = "Disaster vacation. Lost luggage, bad hotel.", bonusEffects = {happiness = -20}}
        }
    }
}

--============================================================================
-- CRIMES
--============================================================================
ActivityData.Crimes = {
    shoplift = {
        id = "shoplift",
        name = "Shoplift",
        description = "Steal from a store",
        icon = "🛒",
        severity = "petty",
        minAge = 10,
        baseCatchChance = 0.35,
        rewards = {min = 20, max = 100},
        sentence = 0, -- Months
        fine = {min = 100, max = 500},
        karmaLoss = 5,
        skillGains = {Criminal = 1, Stealth = 1}
    },
    
    pickpocket = {
        id = "pickpocket",
        name = "Pickpocket",
        description = "Steal from someone's pocket",
        icon = "👛",
        severity = "petty",
        minAge = 12,
        baseCatchChance = 0.40,
        rewards = {min = 50, max = 300},
        sentence = 0,
        fine = {min = 500, max = 1000},
        karmaLoss = 8,
        skillGains = {Criminal = 2, Stealth = 2}
    },
    
    carTheft = {
        id = "carTheft",
        name = "Steal a Car",
        description = "Grand theft auto",
        icon = "🚗",
        severity = "felony",
        minAge = 16,
        baseCatchChance = 0.45,
        rewards = {min = 2000, max = 10000},
        sentence = 12, -- 1 year
        fine = 0,
        karmaLoss = 15,
        skillGains = {Criminal = 3, Technical = 1}
    },
    
    burglary = {
        id = "burglary",
        name = "Burglary",
        description = "Break into a home",
        icon = "🏠",
        severity = "felony",
        minAge = 16,
        baseCatchChance = 0.40,
        rewards = {min = 1000, max = 15000},
        sentence = 24,
        fine = 0,
        karmaLoss = 20,
        skillGains = {Criminal = 3, Stealth = 2}
    },
    
    robbery = {
        id = "robbery",
        name = "Armed Robbery",
        description = "Rob someone with a weapon",
        icon = "🔫",
        severity = "violent_felony",
        minAge = 18,
        baseCatchChance = 0.50,
        rewards = {min = 5000, max = 50000},
        sentence = 60, -- 5 years
        fine = 0,
        karmaLoss = 35,
        skillGains = {Criminal = 5}
    },
    
    bankHeist = {
        id = "bankHeist",
        name = "Bank Heist",
        description = "Rob a bank (high risk)",
        icon = "🏦",
        severity = "major_felony",
        minAge = 21,
        baseCatchChance = 0.65,
        rewards = {min = 50000, max = 500000},
        sentence = 120, -- 10 years
        fine = 0,
        karmaLoss = 50,
        skillGains = {Criminal = 10, Leadership = 2},
        requiresSkill = {Criminal = 30}
    },
    
    assault = {
        id = "assault",
        name = "Assault",
        description = "Attack someone",
        icon = "👊",
        severity = "violent",
        minAge = 14,
        baseCatchChance = 0.60,
        rewards = {min = 0, max = 0},
        sentence = 12,
        fine = {min = 1000, max = 5000},
        karmaLoss = 25,
        skillGains = {Criminal = 2}
    },
    
    murder = {
        id = "murder",
        name = "Murder",
        description = "Kill someone (extreme)",
        icon = "☠️",
        severity = "capital",
        minAge = 18,
        baseCatchChance = 0.70,
        rewards = {min = 0, max = 0},
        sentence = 300, -- 25 years to life
        fine = 0,
        karmaLoss = 100,
        skillGains = {Criminal = 5},
        deathPenaltyRisk = 0.1
    },
    
    drugDealing = {
        id = "drugDealing",
        name = "Sell Drugs",
        description = "Deal illegal substances",
        icon = "💊",
        severity = "felony",
        minAge = 16,
        baseCatchChance = 0.35,
        rewards = {min = 500, max = 5000},
        sentence = 36,
        fine = 0,
        karmaLoss = 20,
        skillGains = {Criminal = 3, Social = 1}
    },
    
    extortion = {
        id = "extortion",
        name = "Extortion",
        description = "Blackmail someone",
        icon = "📩",
        severity = "felony",
        minAge = 18,
        baseCatchChance = 0.30,
        rewards = {min = 1000, max = 20000},
        sentence = 24,
        fine = 0,
        karmaLoss = 30,
        skillGains = {Criminal = 3, Charisma = 1}
    },
    
    fraud = {
        id = "fraud",
        name = "Commit Fraud",
        description = "Financial deception",
        icon = "💳",
        severity = "whiteCollar",
        minAge = 18,
        baseCatchChance = 0.25,
        rewards = {min = 5000, max = 100000},
        sentence = 36,
        fine = {min = 10000, max = 50000},
        karmaLoss = 25,
        skillGains = {Criminal = 3, Financial = 1},
        requiresSkill = {Financial = 20}
    }
}

--============================================================================
-- PRISON ACTIVITIES
--============================================================================
ActivityData.Prison = {
    exercise = {
        id = "exercise",
        name = "Exercise in the Yard",
        description = "Work out and stay fit",
        icon = "🏋️",
        effects = {
            health = {3, 8},
            happiness = {2, 5}
        },
        skillGains = {Physical = 2},
        outcomes = {
            {weight = 0.7, text = "Good workout. Maintaining your strength.", bonusEffects = {}},
            {weight = 0.2, text = "Made some friends in the yard.", bonusEffects = {Social = 1}},
            {weight = 0.1, text = "Got in a scuffle. Guard broke it up.", bonusEffects = {health = -5}}
        }
    },
    
    library = {
        id = "library",
        name = "Visit Prison Library",
        description = "Read and learn",
        icon = "📚",
        effects = {
            smarts = {2, 5},
            happiness = {1, 3}
        },
        skillGains = {Analytical = 1, Writing = 1},
        outcomes = {
            {weight = 0.8, text = "Quiet time with books. Mind stayed sharp.", bonusEffects = {}},
            {weight = 0.2, text = "Found a fascinating book!", bonusEffects = {smarts = 2}}
        }
    },
    
    work = {
        id = "work",
        name = "Work Prison Job",
        description = "Earn a little money inside",
        icon = "🔨",
        effects = {
            money = {5, 20}
        },
        skillGains = {Technical = 1},
        reduceSentence = 0.01, -- 1% off
        outcomes = {
            {weight = 0.7, text = "Another day of work. Time passes.", bonusEffects = {}},
            {weight = 0.2, text = "Good work today. Warden noticed.", bonusEffects = {reputation = 2}},
            {weight = 0.1, text = "Injured at work.", bonusEffects = {health = -10}}
        }
    },
    
    riot = {
        id = "riot",
        name = "Start a Riot",
        description = "Dangerous but might escape",
        icon = "🔥",
        effects = {},
        addSentence = 24, -- Add 2 years if caught
        escapeChance = 0.05,
        outcomes = {
            {weight = 0.6, text = "Riot suppressed. Extra time added.", bonusEffects = {sentence = 24, health = -20}},
            {weight = 0.3, text = "Chaos! But you're caught and beaten.", bonusEffects = {sentence = 36, health = -40}},
            {weight = 0.1, text = "In the chaos... you ESCAPED!", bonusEffects = {escaped = true}}
        }
    },
    
    escape = {
        id = "escape",
        name = "Attempt Escape",
        description = "Try to break out",
        icon = "🏃",
        effects = {},
        escapeChance = 0.10,
        addSentence = 36,
        outcomes = {
            {weight = 0.7, text = "Caught! Solitary confinement and more time.", bonusEffects = {sentence = 36, health = -10}},
            {weight = 0.2, text = "Almost made it! So close...", bonusEffects = {sentence = 24}},
            {weight = 0.1, text = "You're FREE! Life as a fugitive begins.", bonusEffects = {escaped = true}}
        }
    },
    
    goodBehavior = {
        id = "goodBehavior",
        name = "Show Good Behavior",
        description = "Follow the rules and reduce sentence",
        icon = "😇",
        effects = {
            karma = {2, 5}
        },
        reduceSentence = 0.05, -- 5% off
        outcomes = {
            {weight = 0.8, text = "Being on your best behavior.", bonusEffects = {}},
            {weight = 0.2, text = "Warden approved early release consideration!", bonusEffects = {reduceSentence = 0.1}}
        }
    },
    
    gang = {
        id = "gang",
        name = "Join Prison Gang",
        description = "Protection but dangerous",
        icon = "👥",
        effects = {},
        skillGains = {Criminal = 2},
        outcomes = {
            {weight = 0.5, text = "You're in. Protection comes at a cost.", bonusEffects = {karma = -10}},
            {weight = 0.3, text = "Gang helped you out. Owing favors though.", bonusEffects = {}},
            {weight = 0.2, text = "Gang war. You got hurt.", bonusEffects = {health = -25}}
        }
    }
}

--============================================================================
-- HELPER FUNCTIONS
--============================================================================

-- Get activity by ID from any category
function ActivityData.GetActivity(activityId)
    for category, activities in pairs({
        ActivityData.MindBody,
        ActivityData.Social,
        ActivityData.Entertainment
    }) do
        if activities[activityId] then
            return activities[activityId]
        end
    end
    return nil
end

-- Get crime by ID
function ActivityData.GetCrime(crimeId)
    return ActivityData.Crimes[crimeId]
end

-- Get prison activity by ID
function ActivityData.GetPrisonActivity(activityId)
    return ActivityData.Prison[activityId]
end

-- Roll outcome for activity
function ActivityData.RollOutcome(activity)
    if not activity.outcomes then return nil end
    
    local roll = math.random()
    local cumulative = 0
    
    for _, outcome in ipairs(activity.outcomes) do
        cumulative = cumulative + outcome.weight
        if roll <= cumulative then
            return outcome
        end
    end
    
    return activity.outcomes[#activity.outcomes]
end

-- Calculate crime success chance
function ActivityData.CalculateCrimeSuccess(crime, playerState)
    local catchChance = crime.baseCatchChance
    
    -- Reduce by criminal skill
    local criminalSkill = playerState.skills and playerState.skills.Criminal or 0
    catchChance = catchChance - (criminalSkill / 200)
    
    -- Reduce by stealth skill
    local stealthSkill = playerState.skills and playerState.skills.Stealth or 0
    catchChance = catchChance - (stealthSkill / 300)
    
    -- Trait modifiers
    -- (Would apply trait modifiers here)
    
    return math.max(0.10, math.min(0.95, catchChance))
end

return ActivityData
