-- CareerData Part 4: Creative, Entertainment, Government, and Education Careers
-- Unique career paths with specific life events

local CareerData_Part4 = {}
CareerData_Part4.Jobs = {}

--============================================================================
-- CREATIVE CAREERS
--============================================================================

-- GRAPHIC DESIGNER
CareerData_Part4.Jobs["Graphic Designer"] = {
    id = "graphic_designer",
    title = "Graphic Designer",
    category = "Creative",
    baseSalary = 48000,
    salaryRange = {38000, 70000},
    minAge = 18,
    maxAge = nil,
    requirement = "Bachelor's Degree",
    alternateRequirement = "Strong Portfolio",
    requiredSkills = {Creative = 30, Artistic = 30},
    skillGains = {Creative = 3, Artistic = 3, Technical = 1},
    description = "Make things look pretty. Explain why Comic Sans is wrong.",
    workEnvironment = "office",
    stressLevel = "medium",
    promotionPath = "Senior Designer",
    
    careerEvents = {
        {
            id = "gd_client_hell",
            name = "Client From Hell",
            description = "'Can you make the logo bigger? And also smaller? And more colorful but also minimalist?'",
            probability = 0.15,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Patiently work through their feedback",
                    outcomes = {
                        {probability = 0.5, result = "happy", description = "After 47 revisions, they love it!", effects = {stress = 20, reputation = 5}},
                        {probability = 0.5, result = "frustrated", description = "They still don't like it. Your soul hurts.", effects = {stress = 25, happiness = -10}}
                    }
                },
                {
                    text = "Educate them on design principles",
                    outcomes = {
                        {probability = 0.4, result = "understand", description = "They actually learn! Better feedback now.", effects = {reputation = 10, social = 1}},
                        {probability = 0.6, result = "offended", description = "They think you're being condescending.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Just give them what they want",
                    outcomes = {
                        {probability = 0.7, result = "ugly", description = "It's ugly but they're happy. That's... something.", effects = {stress = 15}},
                        {probability = 0.3, result = "portfolio", description = "This isn't going in your portfolio.", effects = {happiness = -5}}
                    }
                }
            }
        },
        {
            id = "gd_spec_work",
            name = "Spec Work Request",
            description = "A potential client wants you to design their whole brand 'to see if you're a good fit'. For free.",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Do the spec work",
                    outcomes = {
                        {probability = 0.3, result = "hired", description = "They love it! You got a major client!", effects = {money = 5000, reputation = 15}},
                        {probability = 0.7, result = "ghosted", description = "They used your designs and never contacted you again.", effects = {happiness = -20, karma = -5}}
                    }
                },
                {
                    text = "Decline and explain why spec work is bad",
                    outcomes = {
                        {probability = 0.5, result = "respected", description = "They understand. You're hired at full rate!", effects = {reputation = 10, money = 3000}},
                        {probability = 0.5, result = "lost", description = "They go elsewhere. At least you have integrity.", effects = {karma = 5}}
                    }
                },
                {
                    text = "Offer a paid design test instead",
                    outcomes = {
                        {probability = 0.6, result = "compromise", description = "They agree to pay for a sample. Win-win!", effects = {money = 500}},
                        {probability = 0.4, result = "refused", description = "They refuse. Bullet dodged.", effects = {}}
                    }
                }
            }
        },
        {
            id = "gd_award",
            name = "Design Award",
            description = "Your work was nominated for a major design award!",
            probability = 0.04,
            minYearsInJob = 1,
            requiresPerformance = 70,
            choices = {
                {
                    text = "Attend the ceremony",
                    outcomes = {
                        {probability = 0.4, result = "win", description = "YOU WON! Industry recognition!", effects = {fame = 10, reputation = 30, happiness = 25}},
                        {probability = 0.6, result = "nominated", description = "Didn't win but the nomination looks great on your portfolio.", effects = {reputation = 15, happiness = 5}}
                    }
                },
                {
                    text = "Watch from home",
                    outcomes = {
                        {probability = 0.4, result = "won_absent", description = "You won and weren't there! Regret!", effects = {fame = 8, reputation = 25, happiness = 10}},
                        {probability = 0.6, result = "no_win", description = "Didn't win. At least you didn't get dressed up.", effects = {reputation = 10}}
                    }
                }
            }
        },
        {
            id = "gd_rebrand",
            name = "Major Rebrand Project",
            description = "A Fortune 500 company wants you to lead their entire rebrand!",
            probability = 0.03,
            minYearsInJob = 2,
            requiresPerformance = 75,
            choices = {
                {
                    text = "Accept this career-defining opportunity",
                    outcomes = {
                        {probability = 0.6, result = "success", description = "The rebrand is a hit! You're in every design blog!", effects = {fame = 20, reputation = 40, money = 30000}},
                        {probability = 0.3, result = "controversy", description = "People hate the new logo. Internet is brutal.", effects = {fame = 10, reputation = -10, stress = 30}},
                        {probability = 0.1, result = "scrapped", description = "They scrap the whole thing after internal drama.", effects = {money = 15000, stress = 20}}
                    }
                },
                {
                    text = "Decline - too much pressure",
                    outcomes = {
                        {probability = 0.5, result = "regret", description = "Another designer does it well. Could have been you.", effects = {happiness = -10}},
                        {probability = 0.5, result = "peace", description = "You avoided potential disaster. Smart.", effects = {}}
                    }
                }
            }
        },
        {
            id = "gd_ai_threat",
            name = "AI Design Tools",
            description = "Your company is considering replacing designers with AI tools...",
            probability = 0.06,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Embrace AI as a tool",
                    outcomes = {
                        {probability = 0.7, result = "adapted", description = "You learn to use AI to be more efficient. Indispensable!", effects = {technical = 3, reputation = 15}},
                        {probability = 0.3, result = "replaced", description = "They still cut the design team. Including you.", effects = {fired = true}}
                    }
                },
                {
                    text = "Focus on what AI can't do",
                    outcomes = {
                        {probability = 0.6, result = "valuable", description = "Your creativity and client relationships keep you essential.", effects = {reputation = 10}},
                        {probability = 0.4, result = "obsolete", description = "AI gets better faster than expected.", effects = {stress = 20}}
                    }
                },
                {
                    text = "Start looking for a new career",
                    outcomes = {
                        {probability = 0.5, result = "pivot", description = "Maybe it's time for a change anyway.", effects = {}},
                        {probability = 0.5, result = "overreaction", description = "Turns out the AI hype was overblown.", effects = {happiness = -5}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Client asked for 'something like Apple but more unique'. Sure.",
        "Finally found the perfect font pairing!",
        "Spent 3 hours adjusting kerning. Worth it.",
        "Someone called your work 'neat'. Not sure if compliment.",
        "The printer colors NEVER match the screen.",
        "Made a logo that you're actually proud of!",
        "Stock photo hunting is its own skill.",
        "Client used the wrong file AGAIN.",
        "Your Dribbble post got featured!",
        "Creative block hit hard today.",
        "A non-designer said 'anyone can do this'. Fuming.",
        "Found inspiration in the weirdest place.",
        "Imposter syndrome is real today.",
        "Your typography skills are *chef's kiss*."
    }
}

-- WRITER/AUTHOR
CareerData_Part4.Jobs["Writer"] = {
    id = "writer",
    title = "Writer",
    category = "Creative",
    baseSalary = 45000,
    salaryRange = {25000, 80000},
    minAge = 18,
    maxAge = nil,
    requirement = nil,
    alternateRequirement = "Strong Writing Sample",
    requiredSkills = {Writing = 30},
    skillGains = {Writing = 3, Creative = 2},
    description = "Turn words into worlds. Cry about rejection letters.",
    workEnvironment = "home",
    stressLevel = "varies",
    promotionPath = "Published Author",
    freelance = true,
    
    careerEvents = {
        {
            id = "wr_rejection",
            name = "Rejection Letter",
            description = "Another rejection from a publisher. That's 47 now.",
            probability = 0.12,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Keep submitting",
                    outcomes = {
                        {probability = 0.3, result = "accepted", description = "Publisher #48 LOVES it! Book deal!", effects = {money = 15000, reputation = 30, happiness = 40}},
                        {probability = 0.7, result = "persist", description = "More rejections. But you keep going.", effects = {writing = 1}}
                    }
                },
                {
                    text = "Revise based on feedback",
                    outcomes = {
                        {probability = 0.6, result = "better", description = "The revisions make it significantly better!", effects = {writing = 2}},
                        {probability = 0.4, result = "lost_voice", description = "You revised so much it lost its soul.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Self-publish",
                    outcomes = {
                        {probability = 0.4, result = "success", description = "Self-publishing was the right call! Sales are good!", effects = {money = 8000, reputation = 15}},
                        {probability = 0.6, result = "silence", description = "It's out there. No one noticed.", effects = {money = -500, happiness = -10}}
                    }
                }
            }
        },
        {
            id = "wr_writers_block",
            name = "Writer's Block",
            description = "You've stared at a blank page for three weeks. Nothing comes.",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Power through anyway",
                    outcomes = {
                        {probability = 0.4, result = "breakthrough", description = "The words start flowing! Better than ever!", effects = {writing = 2, happiness = 15}},
                        {probability = 0.6, result = "garbage", description = "You wrote 10,000 words of garbage.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Take a break and live life",
                    outcomes = {
                        {probability = 0.7, result = "inspired", description = "Experiences give you new material! Inspiration returns!", effects = {creative = 2, happiness = 10}},
                        {probability = 0.3, result = "deadline", description = "The deadline doesn't wait for inspiration.", effects = {stress = 20}}
                    }
                },
                {
                    text = "Try writing something completely different",
                    outcomes = {
                        {probability = 0.5, result = "new_genre", description = "This new direction works! Maybe pivot genres?", effects = {writing = 1, creative = 1}},
                        {probability = 0.5, result = "scattered", description = "Now you have two unfinished projects.", effects = {stress = 10}}
                    }
                }
            }
        },
        {
            id = "wr_bestseller",
            name = "Bestseller List",
            description = "Your book hit the bestseller list!",
            probability = 0.02,
            minYearsInJob = 2,
            requiresPerformance = 80,
            choices = {
                {
                    text = "Celebrate and do press tours",
                    outcomes = {
                        {probability = 0.8, result = "famous", description = "Interviews, book signings, movie interest! You made it!", effects = {fame = 30, money = 100000, happiness = 40}},
                        {probability = 0.2, result = "overwhelmed", description = "The attention is overwhelming. Be careful what you wish for.", effects = {fame = 25, money = 80000, stress = 25}}
                    }
                },
                {
                    text = "Stay humble and start the next book",
                    outcomes = {
                        {probability = 0.7, result = "sophomore", description = "Second book is even better!", effects = {fame = 20, money = 50000, reputation = 20}},
                        {probability = 0.3, result = "slump", description = "Second book syndrome. Hard to follow up.", effects = {fame = 15, stress = 20}}
                    }
                }
            }
        },
        {
            id = "wr_plagiarism",
            name = "Plagiarism Accusation",
            description = "Someone is accusing you of plagiarizing their work!",
            probability = 0.03,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Fight it - your work is original",
                    outcomes = {
                        {probability = 0.8, result = "vindicated", description = "Investigation proves you wrote it independently. Your name is cleared!", effects = {reputation = 10, money = -5000}},
                        {probability = 0.2, result = "settled", description = "You settle to avoid legal costs. People wonder.", effects = {reputation = -20, money = -20000}}
                    }
                },
                {
                    text = "Reach out privately to resolve",
                    outcomes = {
                        {probability = 0.6, result = "misunderstanding", description = "It was a misunderstanding! Similar ideas happen.", effects = {}},
                        {probability = 0.4, result = "demands", description = "They want money. This is extortion.", effects = {stress = 25}}
                    }
                }
            }
        },
        {
            id = "wr_movie_deal",
            name = "Movie Rights Offer",
            description = "A studio wants to buy the movie rights to your book!",
            probability = 0.03,
            minYearsInJob = 1,
            requiresPerformance = 70,
            choices = {
                {
                    text = "Accept their offer",
                    outcomes = {
                        {probability = 0.6, result = "made", description = "They actually make the movie! It's... different.", effects = {money = 200000, fame = 25}},
                        {probability = 0.4, result = "shelved", description = "Development hell. Movie never gets made. Still got paid.", effects = {money = 200000}}
                    }
                },
                {
                    text = "Negotiate for creative control",
                    outcomes = {
                        {probability = 0.3, result = "control", description = "You got creative control AND more money!", effects = {money = 350000, fame = 30, happiness = 20}},
                        {probability = 0.7, result = "lost_deal", description = "They go with another book instead.", effects = {happiness = -15}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Wrote 5,000 words today! On fire!",
        "Stared at a blank document for 4 hours.",
        "A reader sent fan mail. Made your week!",
        "Killed off a character. Cried writing it.",
        "Research rabbit hole led somewhere interesting.",
        "Your coffee is cold. Again. Always.",
        "The first draft is done! (Now rewrite everything)",
        "Someone quoted your book online!",
        "Deadline is tomorrow. You're on page 30.",
        "Your cat walked on your keyboard. Surprisingly helpful.",
        "Rejected from a magazine. Keep going.",
        "Found the perfect word after 20 minutes of thesaurus diving.",
        "Your workspace is a beautiful disaster.",
        "Someone asked 'when are you getting a real job'."
    }
}

-- MUSICIAN
CareerData_Part4.Jobs["Musician"] = {
    id = "musician",
    title = "Musician",
    category = "Entertainment",
    baseSalary = 35000,
    salaryRange = {15000, 500000},
    minAge = 16,
    maxAge = nil,
    requirement = nil,
    requiredSkills = {Musical = 30},
    skillGains = {Musical = 3, Creative = 2, Social = 1},
    description = "Play music. Dream of making it big. Work a side gig.",
    workEnvironment = "various",
    stressLevel = "varies",
    promotionPath = "Famous Musician",
    freelance = true,
    
    careerEvents = {
        {
            id = "mus_record_deal",
            name = "Record Deal Offer",
            description = "A record label wants to sign you! But the contract terms are questionable...",
            probability = 0.04,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Sign immediately",
                    outcomes = {
                        {probability = 0.4, result = "star", description = "The label pushes you! Album goes gold!", effects = {money = 50000, fame = 40, reputation = 30}},
                        {probability = 0.6, result = "owned", description = "You made them millions. You got thousands.", effects = {money = 10000, fame = 20, karma = -5}}
                    }
                },
                {
                    text = "Negotiate better terms",
                    outcomes = {
                        {probability = 0.5, result = "better_deal", description = "They improved the offer. Your lawyer was worth it!", effects = {money = 30000, fame = 35}},
                        {probability = 0.5, result = "pulled", description = "They pulled the offer. Another artist signed instead.", effects = {happiness = -20}}
                    }
                },
                {
                    text = "Stay independent",
                    outcomes = {
                        {probability = 0.4, result = "indie_success", description = "Independence lets you keep creative control. Cult following develops!", effects = {money = 20000, fame = 15, happiness = 20}},
                        {probability = 0.6, result = "struggle", description = "Independence is hard. Bills don't pay themselves.", effects = {money = 5000, stress = 15}}
                    }
                }
            }
        },
        {
            id = "mus_viral",
            name = "Viral Moment",
            description = "Your song is going viral on TikTok!",
            probability = 0.03,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Ride the wave - post constantly",
                    outcomes = {
                        {probability = 0.6, result = "famous", description = "You're everywhere! Labels calling! Shows booked!", effects = {fame = 35, money = 30000, happiness = 30}},
                        {probability = 0.4, result = "one_hit", description = "People only want that one song. Limiting.", effects = {fame = 20, money = 15000, stress = 15}}
                    }
                },
                {
                    text = "Stay authentic to your art",
                    outcomes = {
                        {probability = 0.5, result = "respect", description = "Real fans found you. Loyal audience built.", effects = {fame = 15, reputation = 20}},
                        {probability = 0.5, result = "faded", description = "Moment passed. Back to obscurity.", effects = {happiness = -10}}
                    }
                }
            }
        },
        {
            id = "mus_sold_out",
            name = "Sold Out Show",
            description = "You sold out your first major venue!",
            probability = 0.05,
            minYearsInJob = 1,
            requiresPerformance = 65,
            choices = {
                {
                    text = "Give the show of your life",
                    outcomes = {
                        {probability = 0.7, result = "legendary", description = "Best night of your life! Crowd went INSANE!", effects = {happiness = 40, fame = 15, reputation = 20}},
                        {probability = 0.3, result = "nerves", description = "Nerves got to you. Not your best performance.", effects = {happiness = 10, stress = 15}}
                    }
                }
            }
        },
        {
            id = "mus_band_drama",
            name = "Band Drama",
            description = "Your bandmate wants to go solo. The band might break up.",
            probability = 0.06,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Try to keep the band together",
                    outcomes = {
                        {probability = 0.4, result = "reunited", description = "Heart-to-heart worked! Band stays together!", effects = {happiness = 15}},
                        {probability = 0.6, result = "tension", description = "They stay but resentment lingers.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Go solo yourself",
                    outcomes = {
                        {probability = 0.5, result = "freedom", description = "Solo career takes off! You don't need them!", effects = {fame = 10, happiness = 15}},
                        {probability = 0.5, result = "struggle", description = "Harder alone than you thought.", effects = {money = -5000, stress = 20}}
                    }
                },
                {
                    text = "Support their decision",
                    outcomes = {
                        {probability = 0.6, result = "amicable", description = "Amicable split. Reunion tour in 10 years?", effects = {karma = 5}},
                        {probability = 0.4, result = "bitter", description = "They badmouth you. Ex-bandmate drama.", effects = {reputation = -10}}
                    }
                }
            }
        },
        {
            id = "mus_guitar_smash",
            name = "Stage Moment",
            description = "The crowd is electric. You feel the urge to do something memorable...",
            probability = 0.05,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Smash your guitar",
                    outcomes = {
                        {probability = 0.6, result = "iconic", description = "ICONIC! Photos everywhere! Worth the $2000 guitar!", effects = {fame = 15, money = -2000, happiness = 20}},
                        {probability = 0.4, result = "cringe", description = "It just seemed try-hard. Awkward.", effects = {reputation = -5, money = -2000}}
                    }
                },
                {
                    text = "Stage dive into the crowd",
                    outcomes = {
                        {probability = 0.5, result = "caught", description = "They caught you! Best feeling ever!", effects = {happiness = 25}},
                        {probability = 0.5, result = "dropped", description = "They dropped you. Your back hurts.", effects = {health = -15, happiness = 5}}
                    }
                },
                {
                    text = "Just play your heart out",
                    outcomes = {
                        {probability = 0.8, result = "perfect", description = "Sometimes the music speaks for itself.", effects = {reputation = 10}},
                        {probability = 0.2, result = "forgettable", description = "Good show but nothing memorable happened.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Practiced for 6 hours. Fingers hurt. Worth it.",
        "Wrote a song that made you cry.",
        "Gig only paid $50 but the crowd was amazing.",
        "Your gear broke. There goes this month's savings.",
        "Someone recognized you from a show!",
        "Music video shoot was exhausting but fun.",
        "Royalty check arrived. Enough for coffee!",
        "Collaborated with another artist. Magic happened.",
        "The venue had terrible sound. Not your best show.",
        "A fan got your lyrics tattooed. Surreal.",
        "Your parents finally said they're proud.",
        "Streaming numbers are up! By 12 listeners!",
        "Opened for a bigger band. Nerve-wracking.",
        "Your song played on the radio!"
    }
}

-- ACTOR
CareerData_Part4.Jobs["Actor"] = {
    id = "actor",
    title = "Actor",
    category = "Entertainment",
    baseSalary = 40000,
    salaryRange = {20000, 10000000},
    minAge = 18,
    maxAge = nil,
    requirement = nil,
    alternateRequirement = "Acting Training",
    requiredSkills = {Social = 30, Creative = 20},
    skillGains = {Social = 2, Creative = 2, Charisma = 3},
    description = "Pretend to be other people for money. Wait tables in between.",
    workEnvironment = "various",
    stressLevel = "varies",
    promotionPath = "A-List Actor",
    freelance = true,
    
    careerEvents = {
        {
            id = "act_callback",
            name = "Big Audition",
            description = "You got a callback for a major film role!",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Give everything in the audition",
                    outcomes = {
                        {probability = 0.3, result = "cast", description = "YOU GOT THE PART! This is it!", effects = {money = 50000, fame = 25, happiness = 40}},
                        {probability = 0.5, result = "close", description = "Down to you and one other. They went with the other.", effects = {happiness = -10}},
                        {probability = 0.2, result = "memorable", description = "Didn't get this role but casting remembers you!", effects = {reputation = 15}}
                    }
                },
                {
                    text = "Play it safe",
                    outcomes = {
                        {probability = 0.2, result = "cast", description = "Your steady performance won them over!", effects = {money = 50000, fame = 20}},
                        {probability = 0.8, result = "forgettable", description = "They said you were 'fine'. Forgettable.", effects = {}}
                    }
                }
            }
        },
        {
            id = "act_method",
            name = "Method Acting",
            description = "Your director wants you to stay in character for the entire 3-month shoot.",
            probability = 0.05,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Commit fully - go method",
                    outcomes = {
                        {probability = 0.5, result = "acclaimed", description = "Your performance is being called Oscar-worthy!", effects = {fame = 30, reputation = 25, health = -10}},
                        {probability = 0.3, result = "lost", description = "You lost yourself in the role. Recovery takes time.", effects = {fame = 20, health = -25, happiness = -15}},
                        {probability = 0.2, result = "annoying", description = "Everyone on set found you insufferable.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Balance method with sanity",
                    outcomes = {
                        {probability = 0.7, result = "good", description = "Strong performance without losing yourself.", effects = {fame = 15, reputation = 15}},
                        {probability = 0.3, result = "director_upset", description = "Director thinks you're not committed enough.", effects = {reputation = -5}}
                    }
                }
            }
        },
        {
            id = "act_scandal",
            name = "Tabloid Story",
            description = "A tabloid is about to publish a false scandalous story about you!",
            probability = 0.04,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Sue them",
                    outcomes = {
                        {probability = 0.6, result = "retraction", description = "They retract the story and apologize!", effects = {reputation = 10, money = -20000}},
                        {probability = 0.4, result = "streisand", description = "Lawsuit draws more attention to the story.", effects = {fame = 10, reputation = -15}}
                    }
                },
                {
                    text = "Ignore it",
                    outcomes = {
                        {probability = 0.5, result = "forgotten", description = "Story fades away in a week.", effects = {}},
                        {probability = 0.5, result = "believed", description = "Some people believe it. Frustrating.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Address it publicly",
                    outcomes = {
                        {probability = 0.6, result = "believed", description = "Your statement is believed. Fans support you!", effects = {reputation = 5, happiness = 10}},
                        {probability = 0.4, result = "suspicious", description = "Some think you're protesting too much.", effects = {}}
                    }
                }
            }
        },
        {
            id = "act_oscar_nom",
            name = "Award Season",
            description = "You're nominated for a major acting award!",
            probability = 0.02,
            minYearsInJob = 3,
            requiresPerformance = 85,
            choices = {
                {
                    text = "Campaign hard",
                    outcomes = {
                        {probability = 0.4, result = "win", description = "YOU WON! Tears, speech, career-defining moment!", effects = {fame = 50, money = 200000, happiness = 50}},
                        {probability = 0.6, result = "lost", description = "You lost. Smiled through the pain on camera.", effects = {fame = 25, happiness = -10}}
                    }
                },
                {
                    text = "Stay humble",
                    outcomes = {
                        {probability = 0.3, result = "win", description = "The humility paid off! You won!", effects = {fame = 45, money = 200000, happiness = 50}},
                        {probability = 0.7, result = "honored", description = "Didn't win but honored to be nominated.", effects = {fame = 20, happiness = 5}}
                    }
                }
            }
        },
        {
            id = "act_typecast",
            name = "Typecast Trap",
            description = "You're being offered the same type of role again. Good money but...",
            probability = 0.08,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Take the money",
                    outcomes = {
                        {probability = 0.7, result = "paid", description = "Money is good. Security is nice.", effects = {money = 30000}},
                        {probability = 0.3, result = "stuck", description = "You're now officially typecast.", effects = {money = 30000, happiness = -10}}
                    }
                },
                {
                    text = "Hold out for different roles",
                    outcomes = {
                        {probability = 0.4, result = "range", description = "Casting sees your range! Better roles coming!", effects = {reputation = 20}},
                        {probability = 0.6, result = "broke", description = "Bills pile up. Maybe should have taken it.", effects = {money = -5000, stress = 20}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Auditioned for 3 roles today. Rejected from 3.",
        "Your scene partner was amazing. Chemistry!",
        "The director screamed at everyone. Hollywood, baby.",
        "Memorized 10 pages of dialogue overnight.",
        "Someone recognized you from that commercial!",
        "Craft services had your favorite snacks.",
        "Waited 8 hours to shoot a 30-second scene.",
        "Your agent called with good news for once!",
        "Table read went perfectly.",
        "Had to cry on command. Nailed it.",
        "The lighting made you look fantastic.",
        "Background actor stepped on your line. Again.",
        "Your character got killed off. Bittersweet.",
        "A kid asked for your autograph. First time!"
    }
}

--============================================================================
-- GOVERNMENT CAREERS
--============================================================================

-- POLICE OFFICER
CareerData_Part4.Jobs["Police Officer"] = {
    id = "police_officer",
    title = "Police Officer",
    category = "Government",
    baseSalary = 55000,
    salaryRange = {45000, 75000},
    minAge = 21,
    maxAge = 35,
    requirement = "High School",
    additionalRequirements = {"Police Academy", "Background Check"},
    requiredSkills = {Physical = 20},
    skillGains = {Physical = 2, Social = 2, Leadership = 1},
    description = "Protect and serve. Navigate the complex reality of modern policing.",
    workEnvironment = "patrol",
    stressLevel = "very_high",
    promotionPath = "Sergeant",
    
    careerEvents = {
        {
            id = "cop_shooting",
            name = "Shots Fired",
            description = "Active shooter situation! Lives are at stake!",
            probability = 0.04,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Rush in to help",
                    outcomes = {
                        {probability = 0.5, result = "hero", description = "You stopped the threat! Lives saved!", effects = {reputation = 40, fame = 10, health = -10, stress = 30}},
                        {probability = 0.3, result = "wounded", description = "You're hit but you saved people.", effects = {reputation = 35, health = -40, stress = 35}},
                        {probability = 0.2, result = "trauma", description = "You had to use lethal force. It haunts you.", effects = {reputation = 20, happiness = -30, stress = 40}}
                    }
                },
                {
                    text = "Follow protocol - wait for backup",
                    outcomes = {
                        {probability = 0.6, result = "safe", description = "Backup arrives. Situation resolved safely.", effects = {reputation = 10}},
                        {probability = 0.4, result = "criticized", description = "People died while you waited. The guilt...", effects = {reputation = -20, happiness = -25}}
                    }
                }
            }
        },
        {
            id = "cop_corruption",
            name = "Corruption Offer",
            description = "A senior officer offers you a cut if you look the other way on some things...",
            probability = 0.05,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Report them to internal affairs",
                    outcomes = {
                        {probability = 0.5, result = "justice", description = "They're arrested! You're a hero! Also hated by some colleagues.", effects = {karma = 25, reputation = 20}},
                        {probability = 0.3, result = "retaliation", description = "IA investigates but others retaliate against you.", effects = {karma = 20, stress = 30}},
                        {probability = 0.2, result = "buried", description = "Case gets buried. Nothing happens. Disillusionment.", effects = {happiness = -20, karma = 10}}
                    }
                },
                {
                    text = "Take the money",
                    outcomes = {
                        {probability = 0.5, result = "dirty", description = "Easy money flows in. You're in deep now.", effects = {money = 10000, karma = -40}},
                        {probability = 0.5, result = "caught", description = "FBI sting. You're arrested.", effects = {arrested = true, fired = true}}
                    }
                },
                {
                    text = "Decline quietly",
                    outcomes = {
                        {probability = 0.6, result = "quiet", description = "You're not in, but you're not a snitch either.", effects = {karma = 5}},
                        {probability = 0.4, result = "targeted", description = "They see you as a threat anyway.", effects = {stress = 20}}
                    }
                }
            }
        },
        {
            id = "cop_traffic_stop",
            name = "Tense Traffic Stop",
            description = "Something feels off about this stop. The driver is nervous...",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Stay calm and proceed carefully",
                    outcomes = {
                        {probability = 0.7, result = "clean", description = "Just nerves. Warning issued. Everyone goes home safe.", effects = {}},
                        {probability = 0.2, result = "arrest", description = "They had warrants. Clean arrest made!", effects = {reputation = 10}},
                        {probability = 0.1, result = "danger", description = "They pulled a weapon! You had to react!", effects = {health = -20, stress = 30}}
                    }
                },
                {
                    text = "Call for backup before approaching",
                    outcomes = {
                        {probability = 0.6, result = "justified", description = "Good instinct. Backup helps secure arrest.", effects = {reputation = 5}},
                        {probability = 0.4, result = "overreaction", description = "Turns out it was nothing. Backup annoyed.", effects = {reputation = -5}}
                    }
                }
            }
        },
        {
            id = "cop_community",
            name = "Community Relations",
            description = "The neighborhood has tension with police. A community event is planned.",
            probability = 0.06,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Engage genuinely with residents",
                    outcomes = {
                        {probability = 0.7, result = "trust", description = "People open up. You build real relationships.", effects = {reputation = 15, social = 2, karma = 10}},
                        {probability = 0.3, result = "skeptical", description = "Some remain skeptical. Change takes time.", effects = {karma = 5}}
                    }
                },
                {
                    text = "Keep it professional and brief",
                    outcomes = {
                        {probability = 0.5, result = "fine", description = "Cordial but distant. No progress made.", effects = {}},
                        {probability = 0.5, result = "seen_through", description = "People see you're not genuine.", effects = {reputation = -5}}
                    }
                }
            }
        },
        {
            id = "cop_promotion",
            name = "Sergeant Exam",
            description = "The sergeant exam is coming up. Time to move up?",
            probability = 0.05,
            minYearsInJob = 3,
            requiresPerformance = 65,
            choices = {
                {
                    text = "Take the exam",
                    outcomes = {
                        {probability = 0.5, result = "promoted", description = "You passed! Sergeant stripes!", effects = {promoted = "Sergeant", salaryIncrease = 15000}},
                        {probability = 0.5, result = "failed", description = "Didn't pass. Next time.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Stay on patrol",
                    outcomes = {
                        {probability = 0.7, result = "happy", description = "Patrol is where the action is.", effects = {}},
                        {probability = 0.3, result = "regret", description = "Watch others advance past you.", effects = {happiness = -5}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Domestic disturbance call. Nobody hurt.",
        "A kid asked to see your badge. Wholesome moment.",
        "Paperwork never ends.",
        "Traffic duty in the rain. Joy.",
        "Made a clean arrest. Good police work.",
        "An old lady made you cookies.",
        "Court appearance took all day.",
        "Your partner told a terrible joke. You laughed anyway.",
        "Responded to a false alarm. Third time today.",
        "Helped someone change a tire. Community service.",
        "Night shift is quiet. Too quiet.",
        "Caught a shoplifter. Kid stuff.",
        "Someone thanked you for your service.",
        "The vest is hot. So hot."
    }
}

-- FIREFIGHTER
CareerData_Part4.Jobs["Firefighter"] = {
    id = "firefighter",
    title = "Firefighter",
    category = "Emergency Services",
    baseSalary = 52000,
    salaryRange = {42000, 70000},
    minAge = 18,
    maxAge = nil,
    requirement = "High School",
    additionalRequirements = {"Fire Academy", "EMT Certification"},
    requiredSkills = {Physical = 30},
    skillGains = {Physical = 3, Medical = 1, Leadership = 1},
    description = "Run into burning buildings. It's literally the job.",
    workEnvironment = "fire_station",
    stressLevel = "high",
    promotionPath = "Lieutenant",
    
    careerEvents = {
        {
            id = "fire_save",
            name = "Trapped Victim",
            description = "Someone's trapped in a burning building! Fire is spreading fast!",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Go in now",
                    outcomes = {
                        {probability = 0.6, result = "hero", description = "You found them! Carried them out! HERO!", effects = {reputation = 40, fame = 10, health = -10}},
                        {probability = 0.3, result = "close", description = "Got them out just as the ceiling collapsed!", effects = {reputation = 35, health = -15}},
                        {probability = 0.1, result = "injured", description = "You saved them but you're badly hurt.", effects = {reputation = 30, health = -40}}
                    }
                },
                {
                    text = "Wait for safer conditions",
                    outcomes = {
                        {probability = 0.4, result = "window", description = "The opportunity came. Rescue successful!", effects = {reputation = 25}},
                        {probability = 0.6, result = "too_late", description = "The building collapsed. They didn't make it.", effects = {happiness = -30, stress = 35}}
                    }
                }
            }
        },
        {
            id = "fire_arson",
            name = "Arson Suspected",
            description = "This fire was clearly set intentionally. You notice evidence...",
            probability = 0.05,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Document everything for investigators",
                    outcomes = {
                        {probability = 0.7, result = "arrest", description = "Your observations led to an arrest!", effects = {reputation = 20}},
                        {probability = 0.3, result = "helpful", description = "Evidence helped the investigation.", effects = {reputation = 10}}
                    }
                },
                {
                    text = "Focus on the fire, let others investigate",
                    outcomes = {
                        {probability = 0.6, result = "professional", description = "Stay in your lane. That's fair.", effects = {}},
                        {probability = 0.4, result = "missed", description = "Evidence was lost in the suppression.", effects = {}}
                    }
                }
            }
        },
        {
            id = "fire_calendar",
            name = "Calendar Photoshoot",
            description = "They want you for the firefighter charity calendar!",
            probability = 0.04,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Do the photoshoot",
                    outcomes = {
                        {probability = 0.8, result = "famous", description = "You're Mr/Ms February! Calendar sells out!", effects = {fame = 5, happiness = 15}},
                        {probability = 0.2, result = "teased", description = "The station teases you relentlessly.", effects = {fame = 3, happiness = 5}}
                    }
                },
                {
                    text = "Decline - too embarrassing",
                    outcomes = {
                        {probability = 1.0, result = "private", description = "Your dignity remains intact.", effects = {}}
                    }
                }
            }
        },
        {
            id = "fire_station_life",
            name = "Station Prank War",
            description = "Someone put your gear in jello. It's war.",
            probability = 0.07,
            minYearsInJob = 0.2,
            choices = {
                {
                    text = "Epic revenge prank",
                    outcomes = {
                        {probability = 0.7, result = "legendary", description = "Your response is legendary! Laughs all around!", effects = {happiness = 20}},
                        {probability = 0.3, result = "too_far", description = "Went too far. Captain is NOT happy.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Let it go",
                    outcomes = {
                        {probability = 0.5, result = "mature", description = "The mature choice. Respected... and boring.", effects = {}},
                        {probability = 0.5, result = "target", description = "Now you're an easy target.", effects = {happiness = -5}}
                    }
                }
            }
        },
        {
            id = "fire_cancer",
            name = "Health Concern",
            description = "You learn that firefighters have elevated cancer risks from smoke exposure...",
            probability = 0.03,
            minYearsInJob = 2,
            choices = {
                {
                    text = "Get screened regularly",
                    outcomes = {
                        {probability = 0.9, result = "clean", description = "Clean bill of health! Peace of mind.", effects = {happiness = 10}},
                        {probability = 0.1, result = "early", description = "They found something early. Treatable.", effects = {health = -20}}
                    }
                },
                {
                    text = "Don't worry about it",
                    outcomes = {
                        {probability = 0.8, result = "fine", description = "Probably fine. Most firefighters are.", effects = {}},
                        {probability = 0.2, result = "late", description = "Should have gotten checked...", effects = {health = -40}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Made chili for the station. Everyone loved it.",
        "3 AM call. House fire. Minimal damage.",
        "A kid visited the station. Got to spray the hose!",
        "Training day. Climbed 20 flights in full gear.",
        "Cat stuck in a tree. Yes, that really happens.",
        "Your gear smells. It always smells.",
        "False alarm. Burned popcorn in an office.",
        "Car accident. Used the jaws of life.",
        "Night shift poker game. Won $20.",
        "The dalmatian at the station loves you.",
        "Did CPR. Person survived. Best feeling.",
        "Equipment check took all morning.",
        "A family brought thank-you donuts.",
        "Grease fire at a restaurant. Quick response."
    }
}

--============================================================================
-- EDUCATION CAREERS
--============================================================================

-- TEACHER
CareerData_Part4.Jobs["Teacher"] = {
    id = "teacher",
    title = "Teacher",
    category = "Education",
    baseSalary = 45000,
    salaryRange = {38000, 65000},
    minAge = 23,
    maxAge = nil,
    requirement = "Bachelor's Degree",
    license = "Teaching Certificate",
    requiredSkills = {Teaching = 20, Social = 20},
    skillGains = {Teaching = 3, Social = 2, Leadership = 1},
    description = "Shape young minds. Deal with parents. Work way more than people think.",
    workEnvironment = "school",
    stressLevel = "high",
    promotionPath = "Department Head",
    
    careerEvents = {
        {
            id = "teach_troubled",
            name = "Troubled Student",
            description = "A student is acting out. You sense something deeper is wrong at home.",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Talk to them privately",
                    outcomes = {
                        {probability = 0.6, result = "breakthrough", description = "They open up. You help them get support.", effects = {karma = 15, teaching = 1, happiness = 15}},
                        {probability = 0.4, result = "walls", description = "They won't talk. But they know you care.", effects = {karma = 5}}
                    }
                },
                {
                    text = "Report to counselor",
                    outcomes = {
                        {probability = 0.7, result = "help", description = "Counselor gets them help. System works!", effects = {karma = 10}},
                        {probability = 0.3, result = "falls_through", description = "Counselor is overwhelmed. Kid falls through cracks.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Discipline the behavior",
                    outcomes = {
                        {probability = 0.3, result = "stops", description = "Behavior stops. Problem solved?", effects = {}},
                        {probability = 0.7, result = "worse", description = "Acting out gets worse. This isn't working.", effects = {stress = 15}}
                    }
                }
            }
        },
        {
            id = "teach_parent_complaint",
            name = "Angry Parent",
            description = "A parent is furious their child got a C. 'My kid is an A student!'",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Show them the work and rubric",
                    outcomes = {
                        {probability = 0.5, result = "accepted", description = "Evidence is clear. They accept it.", effects = {reputation = 5}},
                        {probability = 0.5, result = "still_angry", description = "They don't care about evidence.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Stand firm on the grade",
                    outcomes = {
                        {probability = 0.4, result = "respected", description = "Principal backs you up. Grade stands.", effects = {reputation = 10}},
                        {probability = 0.6, result = "complaint", description = "They escalate to administration.", effects = {stress = 20}}
                    }
                },
                {
                    text = "Offer extra credit opportunity",
                    outcomes = {
                        {probability = 0.7, result = "satisfied", description = "They're satisfied. Kid actually does better.", effects = {}},
                        {probability = 0.3, result = "precedent", description = "Now every parent expects this.", effects = {stress = 10}}
                    }
                }
            }
        },
        {
            id = "teach_success",
            name = "Student Success Story",
            description = "A former student sends you a message. You changed their life.",
            probability = 0.05,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Read it and respond",
                    outcomes = {
                        {probability = 1.0, result = "fulfilled", description = "This is why you teach. Worth every hard day.", effects = {happiness = 30, karma = 10}}
                    }
                }
            }
        },
        {
            id = "teach_budget",
            name = "Supplies Crisis",
            description = "The school cut supply budgets. Your classroom needs basic materials.",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Buy supplies yourself",
                    outcomes = {
                        {probability = 0.8, result = "sacrifice", description = "You do it because the kids need it.", effects = {money = -500, karma = 10}},
                        {probability = 0.2, result = "noticed", description = "A donor notices and reimburses you!", effects = {karma = 10, happiness = 15}}
                    }
                },
                {
                    text = "Create a donors choose page",
                    outcomes = {
                        {probability = 0.6, result = "funded", description = "Complete strangers fund your classroom!", effects = {happiness = 15}},
                        {probability = 0.4, result = "unfunded", description = "Only partial funding. Still short.", effects = {money = -200}}
                    }
                },
                {
                    text = "Make do with what you have",
                    outcomes = {
                        {probability = 0.5, result = "creative", description = "Creativity thrives within constraints!", effects = {creative = 1}},
                        {probability = 0.5, result = "limited", description = "The kids deserve better.", effects = {happiness = -10}}
                    }
                }
            }
        },
        {
            id = "teach_award",
            name = "Teacher of the Year",
            description = "You're nominated for Teacher of the Year!",
            probability = 0.03,
            minYearsInJob = 2,
            requiresPerformance = 75,
            choices = {
                {
                    text = "Accept the nomination graciously",
                    outcomes = {
                        {probability = 0.4, result = "win", description = "YOU WON! Recognition for all your hard work!", effects = {fame = 5, reputation = 30, happiness = 30}},
                        {probability = 0.6, result = "honored", description = "Didn't win but the recognition meant everything.", effects = {reputation = 15, happiness = 15}}
                    }
                },
                {
                    text = "Deflect credit to your colleagues",
                    outcomes = {
                        {probability = 0.7, result = "respected", description = "Everyone appreciates your humility.", effects = {reputation = 10}},
                        {probability = 0.3, result = "overlooked", description = "Your modesty cost you recognition.", effects = {}}
                    }
                }
            }
        },
        {
            id = "teach_summer",
            name = "Summer Job Decision",
            description = "Summer break! But your salary isn't great...",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Get a summer job",
                    outcomes = {
                        {probability = 0.8, result = "money", description = "Extra income helps! Exhausting though.", effects = {money = 5000, health = -5}},
                        {probability = 0.2, result = "burnout", description = "No rest. You're burned out come fall.", effects = {money = 5000, stress = 20}}
                    }
                },
                {
                    text = "Rest and recharge",
                    outcomes = {
                        {probability = 0.7, result = "refreshed", description = "Ready to tackle fall semester!", effects = {happiness = 15, health = 10}},
                        {probability = 0.3, result = "tight", description = "Money is tight but you needed the break.", effects = {happiness = 10, money = -1000}}
                    }
                },
                {
                    text = "Summer school teaching",
                    outcomes = {
                        {probability = 0.8, result = "teaching_money", description = "Extra money doing what you love!", effects = {money = 3000, teaching = 1}},
                        {probability = 0.2, result = "tired", description = "Teaching year-round is exhausting.", effects = {money = 3000, stress = 15}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "A student finally understood the concept! Light bulb moment!",
        "Spent $50 on supplies. Again.",
        "Parent-teacher conferences were exhausting.",
        "Your lesson plan went perfectly!",
        "Staff meeting could have been an email.",
        "A student drew a picture of you. It's on the fridge.",
        "Grading took until midnight.",
        "Fire drill interrupted the best lesson.",
        "A student remembered something you taught last year!",
        "Lunch was 15 minutes because of a crisis.",
        "The copier jammed. Classic.",
        "Your most challenging student made progress!",
        "Another standardized test to prepare for.",
        "A colleague shared an amazing resource!",
        "End of year. So many hugs."
    }
}

-- PROFESSOR
CareerData_Part4.Jobs["Professor"] = {
    id = "professor",
    title = "Assistant Professor",
    category = "Education",
    baseSalary = 75000,
    salaryRange = {60000, 120000},
    minAge = 28,
    maxAge = nil,
    requirement = "PhD",
    requiredSkills = {Teaching = 30, Scientific = 40, Analytical = 40},
    skillGains = {Teaching = 2, Scientific = 3, Analytical = 2, Writing = 2},
    description = "Teach, research, and fight for tenure. Publish or perish.",
    workEnvironment = "university",
    stressLevel = "high",
    promotionPath = "Associate Professor",
    
    careerEvents = {
        {
            id = "prof_tenure",
            name = "Tenure Decision",
            description = "The tenure committee is meeting. Six years of work on the line.",
            probability = 0.05,
            minYearsInJob = 5,
            requiresPerformance = 70,
            choices = {
                {
                    text = "Present your strongest case",
                    outcomes = {
                        {probability = 0.5, result = "tenured", description = "TENURE! Job security for life!", effects = {promoted = "Associate Professor", salaryIncrease = 20000, happiness = 40}},
                        {probability = 0.5, result = "denied", description = "Denied. Your academic career may be over.", effects = {happiness = -40, stress = 35}}
                    }
                },
                {
                    text = "Hope your work speaks for itself",
                    outcomes = {
                        {probability = 0.4, result = "tenured", description = "Your publication record won them over!", effects = {promoted = "Associate Professor", salaryIncrease = 20000, happiness = 40}},
                        {probability = 0.6, result = "denied", description = "Needed more advocacy. Denied.", effects = {happiness = -35}}
                    }
                }
            }
        },
        {
            id = "prof_paper_rejected",
            name = "Paper Rejected",
            description = "Your paper was rejected. The reviews are harsh.",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Revise and resubmit elsewhere",
                    outcomes = {
                        {probability = 0.6, result = "accepted", description = "Another journal accepts it! Persistence pays off!", effects = {reputation = 15, writing = 1}},
                        {probability = 0.4, result = "rejected_again", description = "Rejected again. This is soul-crushing.", effects = {happiness = -15}}
                    }
                },
                {
                    text = "Take the feedback to heart",
                    outcomes = {
                        {probability = 0.7, result = "improved", description = "The revisions made it much stronger!", effects = {writing = 2, scientific = 1}},
                        {probability = 0.3, result = "lost_direction", description = "You've revised it so much it lost its core argument.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Abandon this project",
                    outcomes = {
                        {probability = 0.4, result = "fresh_start", description = "New project is more promising anyway.", effects = {}},
                        {probability = 0.6, result = "wasted", description = "Two years of work gone.", effects = {happiness = -10}}
                    }
                }
            }
        },
        {
            id = "prof_student_crush",
            name = "Student Attraction",
            description = "A student is clearly attracted to you. They're always around...",
            probability = 0.04,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Maintain strict professional boundaries",
                    outcomes = {
                        {probability = 0.9, result = "professional", description = "You handle it professionally. They move on.", effects = {reputation = 5}},
                        {probability = 0.1, result = "complaint", description = "They file a complaint for 'coldness'. Cleared quickly.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Report to the department",
                    outcomes = {
                        {probability = 0.8, result = "handled", description = "Department handles it appropriately.", effects = {}},
                        {probability = 0.2, result = "awkward", description = "Now it's super awkward in class.", effects = {stress = 10}}
                    }
                },
                {
                    text = "Respond to their interest",
                    outcomes = {
                        {probability = 0.1, result = "relationship", description = "Risky but you start something after they graduate.", effects = {happiness = 20, karma = -15}},
                        {probability = 0.9, result = "scandal", description = "MAJOR scandal. Career damaged.", effects = {reputation = -50, fired = true}}
                    }
                }
            }
        },
        {
            id = "prof_grant",
            name = "Grant Application",
            description = "A major grant could fund your research for 5 years!",
            probability = 0.06,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Submit an ambitious proposal",
                    outcomes = {
                        {probability = 0.3, result = "funded", description = "$500,000 grant! Your research is funded!", effects = {money = 50000, reputation = 30, happiness = 25}},
                        {probability = 0.7, result = "declined", description = "Not funded this cycle. Very competitive.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Submit a conservative proposal",
                    outcomes = {
                        {probability = 0.4, result = "partial", description = "Partially funded. Better than nothing!", effects = {money = 20000, reputation = 15}},
                        {probability = 0.6, result = "declined", description = "Too safe. They wanted innovation.", effects = {}}
                    }
                }
            }
        },
        {
            id = "prof_plagiarism",
            name = "Plagiarism Discovery",
            description = "You discover a student plagiarized their entire thesis...",
            probability = 0.05,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Report to academic integrity board",
                    outcomes = {
                        {probability = 0.8, result = "expelled", description = "Student expelled. Integrity maintained.", effects = {karma = 10}},
                        {probability = 0.2, result = "appealed", description = "They appeal. Long process. Eventually expelled.", effects = {stress = 20}}
                    }
                },
                {
                    text = "Give them a chance to redo it",
                    outcomes = {
                        {probability = 0.4, result = "learned", description = "They learned their lesson. New thesis is original.", effects = {karma = 5}},
                        {probability = 0.6, result = "again", description = "They did it again. Now you HAVE to report.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Let it slide",
                    outcomes = {
                        {probability = 0.5, result = "nothing", description = "No one ever finds out.", effects = {karma = -15}},
                        {probability = 0.5, result = "discovered", description = "It's discovered later. You're implicated.", effects = {reputation = -30}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Submitted a paper! Now the anxiety wait.",
        "Office hours were actually productive today.",
        "A student asked a question that made you think.",
        "Faculty meeting was 3 hours of politics.",
        "Your H-index went up by 1!",
        "Peer review request. Another one.",
        "Grad student made a breakthrough!",
        "The committee work never ends.",
        "Presenting at a conference next month!",
        "A colleague cited your work!",
        "Grading 200 papers. Why are they all bad?",
        "The research is finally coming together.",
        "Academic Twitter drama. Staying out of it.",
        "A former student got a tenure-track job!"
    }
}

return CareerData_Part4
