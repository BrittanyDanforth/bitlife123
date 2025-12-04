-- CareerData Part 3: Medical, Legal, and Finance Careers
-- High-stakes professional careers with specific events

local CareerData_Part3 = {}
CareerData_Part3.Jobs = {}

--============================================================================
-- MEDICAL CAREERS
--============================================================================

-- NURSE
CareerData_Part3.Jobs["Registered Nurse"] = {
    id = "registered_nurse",
    title = "Registered Nurse",
    category = "Medical",
    baseSalary = 65000,
    salaryRange = {55000, 85000},
    minAge = 22,
    maxAge = nil,
    requirement = "Nursing Degree",
    license = "RN License",
    requiredSkills = {Medical = 20},
    skillGains = {Medical = 3, Social = 2, Physical = 1},
    description = "Save lives, comfort patients, survive 12-hour shifts.",
    workEnvironment = "hospital",
    stressLevel = "high",
    promotionPath = "Charge Nurse",
    
    careerEvents = {
        {
            id = "nurse_code_blue",
            name = "Code Blue!",
            description = "A patient is coding! You're the first responder!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Begin CPR immediately",
                    outcomes = {
                        {probability = 0.6, result = "saved", description = "You kept them alive until the code team arrived! Patient stabilized!", effects = {reputation = 25, medical = 2, happiness = 15}},
                        {probability = 0.4, result = "lost", description = "Despite your best efforts, they didn't make it. It's never easy.", effects = {happiness = -20, stress = 20}}
                    }
                },
                {
                    text = "Call the code team first",
                    outcomes = {
                        {probability = 0.5, result = "team_saves", description = "Team arrives fast and saves them!", effects = {reputation = 5}},
                        {probability = 0.5, result = "too_late", description = "Those seconds mattered. Should have started CPR.", effects = {reputation = -15, happiness = -15}}
                    }
                }
            }
        },
        {
            id = "nurse_medication_error",
            name = "Medication Error",
            description = "You almost gave a patient the wrong medication! You caught it just in time.",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Report the near-miss",
                    outcomes = {
                        {probability = 0.8, result = "praised", description = "Reporting near-misses prevents real errors. Good call!", effects = {reputation = 10}},
                        {probability = 0.2, result = "scrutiny", description = "Now you're being watched more closely.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Keep it to yourself - no harm done",
                    outcomes = {
                        {probability = 0.7, result = "fine", description = "No one ever knows.", effects = {}},
                        {probability = 0.3, result = "happens_again", description = "Same issue happens with another nurse. Investigation reveals the pattern.", effects = {reputation = -20}}
                    }
                }
            }
        },
        {
            id = "nurse_difficult_patient",
            name = "Combative Patient",
            description = "A patient becomes violent and tries to hit you!",
            probability = 0.10,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Use de-escalation techniques",
                    outcomes = {
                        {probability = 0.5, result = "calmed", description = "You talked them down. Crisis averted.", effects = {reputation = 10, social = 1}},
                        {probability = 0.5, result = "still_violent", description = "They're too agitated. Need security.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Call for security immediately",
                    outcomes = {
                        {probability = 0.8, result = "handled", description = "Security handles it professionally.", effects = {}},
                        {probability = 0.2, result = "injury", description = "Before security arrives, you get hit.", effects = {health = -15}}
                    }
                },
                {
                    text = "Restrain them yourself",
                    outcomes = {
                        {probability = 0.3, result = "controlled", description = "You safely restrain them until help arrives.", effects = {physical = 1}},
                        {probability = 0.7, result = "injured", description = "Bad idea. You're hurt.", effects = {health = -25, stress = 20}}
                    }
                }
            }
        },
        {
            id = "nurse_death",
            name = "Patient Death",
            description = "Your patient passed away. You were with them at the end.",
            probability = 0.07,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Stay professional and comfort the family",
                    outcomes = {
                        {probability = 0.8, result = "grateful", description = "The family thanks you for being there. Bittersweet.", effects = {social = 2, happiness = -10}},
                        {probability = 0.2, result = "blame", description = "Family lashes out in grief. Not your fault.", effects = {happiness = -20, stress = 15}}
                    }
                },
                {
                    text = "Take a moment alone",
                    outcomes = {
                        {probability = 0.7, result = "process", description = "You process the loss. It's part of the job, but never easy.", effects = {happiness = -5}},
                        {probability = 0.3, result = "breakdown", description = "The emotions hit hard. You need a break.", effects = {happiness = -15, stress = 20}}
                    }
                },
                {
                    text = "Push through - other patients need you",
                    outcomes = {
                        {probability = 0.5, result = "strong", description = "You compartmentalize and carry on.", effects = {}},
                        {probability = 0.5, result = "burnout", description = "Bottling it up isn't healthy.", effects = {stress = 25, happiness = -10}}
                    }
                }
            }
        },
        {
            id = "nurse_family_thanks",
            name = "Family Gratitude",
            description = "A patient's family brings you homemade cookies and a heartfelt thank you card.",
            probability = 0.05,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Accept graciously",
                    outcomes = {
                        {probability = 1.0, result = "touched", description = "This is why you do this job. Worth every hard day.", effects = {happiness = 25}}
                    }
                },
                {
                    text = "Share with the whole team",
                    outcomes = {
                        {probability = 1.0, result = "team_spirit", description = "You share the cookies. Team morale boosted!", effects = {happiness = 20, reputation = 5}}
                    }
                }
            }
        },
        {
            id = "nurse_overtime",
            name = "Mandatory Overtime",
            description = "The next shift is short-staffed. They're asking you to stay another 4 hours.",
            probability = 0.12,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Stay - the patients need you",
                    outcomes = {
                        {probability = 0.7, result = "survive", description = "Exhausting but you made it. Time-and-a-half pay!", effects = {money = 150, health = -5, stress = 15}},
                        {probability = 0.3, result = "error", description = "Fatigue leads to a minor mistake. Wake-up call.", effects = {money = 150, health = -10, stress = 20}}
                    }
                },
                {
                    text = "Refuse - you need rest",
                    outcomes = {
                        {probability = 0.6, result = "respected", description = "Setting boundaries. Self-care is important.", effects = {}},
                        {probability = 0.4, result = "guilt", description = "You feel guilty but you needed the rest.", effects = {happiness = -5}}
                    }
                }
            }
        },
        {
            id = "nurse_promotion",
            name = "Charge Nurse Position",
            description = "There's an opening for Charge Nurse. More responsibility, more pay.",
            probability = 0.05,
            minYearsInJob = 2,
            requiresPerformance = 65,
            choices = {
                {
                    text = "Apply for the position",
                    outcomes = {
                        {probability = 0.6, result = "promoted", description = "You're the new Charge Nurse! More leadership, more money!", effects = {promoted = "Charge Nurse", salaryIncrease = 12000}},
                        {probability = 0.4, result = "passed", description = "They went with someone more experienced.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Stay at the bedside",
                    outcomes = {
                        {probability = 1.0, result = "content", description = "Direct patient care is your calling.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "A patient's vitals are finally stable. Relief.",
        "The night shift left you a mess. Thanks.",
        "A patient remembered your name and thanked you.",
        "Your feet are screaming after mile 6 on the floor.",
        "A doctor actually listened to your assessment!",
        "IV on the first try! Still got it.",
        "The break room had pizza. Small victories.",
        "A patient's family member was incredibly rude.",
        "You made a scared child laugh during their shot.",
        "The charting system crashed. Of course it did.",
        "Another nurse called off. Here we go.",
        "A patient coded but made it. What a day.",
        "Finally got to sit down for 5 minutes.",
        "A patient gave you a drawing. It's going on the fridge."
    }
}

-- DOCTOR (General Practitioner)
CareerData_Part3.Jobs["Doctor"] = {
    id = "doctor",
    title = "General Practitioner",
    category = "Medical",
    baseSalary = 180000,
    salaryRange = {150000, 220000},
    minAge = 30,
    maxAge = nil,
    requirement = "Medical Degree",
    license = "Medical License",
    residency = true,
    requiredSkills = {Medical = 50, Analytical = 40},
    skillGains = {Medical = 3, Analytical = 2, Social = 1, Leadership = 1},
    description = "Diagnose illnesses, prescribe treatments, save lives.",
    workEnvironment = "hospital",
    stressLevel = "very_high",
    promotionPath = "Department Head",
    
    careerEvents = {
        {
            id = "doc_malpractice",
            name = "Malpractice Suit",
            description = "A former patient is suing you for malpractice!",
            probability = 0.04,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Fight it - you did nothing wrong",
                    outcomes = {
                        {probability = 0.6, result = "dismissed", description = "Case dismissed! Your reputation is intact.", effects = {money = -5000, stress = 20}},
                        {probability = 0.3, result = "settle", description = "Insurance settles out of court. Not ideal but over.", effects = {money = -10000, reputation = -10}},
                        {probability = 0.1, result = "lose", description = "Jury sides with patient. Massive settlement.", effects = {money = -50000, reputation = -30}}
                    }
                },
                {
                    text = "Settle quickly",
                    outcomes = {
                        {probability = 0.8, result = "settled", description = "Settled fast. More expensive but less stressful.", effects = {money = -30000, stress = 10}},
                        {probability = 0.2, result = "admitted", description = "Settlement looks like admission of guilt.", effects = {money = -30000, reputation = -15}}
                    }
                }
            }
        },
        {
            id = "doc_diagnosis",
            name = "Mystery Diagnosis",
            description = "A patient has baffling symptoms. Every test is inconclusive.",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Order more specialized tests",
                    outcomes = {
                        {probability = 0.6, result = "found", description = "The tests reveal a rare condition. Treatment begins!", effects = {reputation = 20, medical = 2}},
                        {probability = 0.4, result = "expensive", description = "Tests come back normal. Patient is frustrated at the bill.", effects = {}}
                    }
                },
                {
                    text = "Consult with specialists",
                    outcomes = {
                        {probability = 0.7, result = "collaboration", description = "Specialist spots something you missed. Team effort!", effects = {reputation = 10, medical = 1}},
                        {probability = 0.3, result = "no_help", description = "They're stumped too. Back to square one.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Trust your gut - treat empirically",
                    outcomes = {
                        {probability = 0.4, result = "right", description = "Your instinct was correct! They improve!", effects = {reputation = 25, medical = 3}},
                        {probability = 0.6, result = "wrong", description = "Wrong call. Patient gets worse before you correct course.", effects = {reputation = -10, stress = 20}}
                    }
                }
            }
        },
        {
            id = "doc_pharma_rep",
            name = "Pharma Rep Visit",
            description = "A pharmaceutical rep offers expensive dinners and gifts to prescribe their drug.",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Accept the gifts",
                    outcomes = {
                        {probability = 0.5, result = "fancy_dinner", description = "Great steak! And the drug is actually good.", effects = {money = 500, karma = -5}},
                        {probability = 0.5, result = "conflict", description = "You start prescribing more of their drug. Ethical gray area.", effects = {money = 500, karma = -15}}
                    }
                },
                {
                    text = "Decline - maintain independence",
                    outcomes = {
                        {probability = 1.0, result = "ethical", description = "Your prescribing stays evidence-based. Right call.", effects = {karma = 5}}
                    }
                },
                {
                    text = "Report them to compliance",
                    outcomes = {
                        {probability = 0.7, result = "clean", description = "They were being too aggressive. Good catch.", effects = {reputation = 10}},
                        {probability = 0.3, result = "overreaction", description = "Compliance says it was within guidelines.", effects = {}}
                    }
                }
            }
        },
        {
            id = "doc_anti_vaxxer",
            name = "Anti-Vax Patient",
            description = "A parent refuses to vaccinate their child despite your recommendations.",
            probability = 0.07,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Spend extra time educating them",
                    outcomes = {
                        {probability = 0.4, result = "convinced", description = "They come around! Science wins!", effects = {happiness = 15, social = 1}},
                        {probability = 0.6, result = "refused", description = "They're not budging. Frustrating.", effects = {stress = 10}}
                    }
                },
                {
                    text = "Accept their decision",
                    outcomes = {
                        {probability = 0.8, result = "document", description = "You document the refusal. Legally covered.", effects = {}},
                        {probability = 0.2, result = "consequence", description = "Child gets sick later. You wonder if you could have done more.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Dismiss them as a patient",
                    outcomes = {
                        {probability = 0.5, result = "justified", description = "Your practice, your rules. They find another doctor.", effects = {}},
                        {probability = 0.5, result = "backlash", description = "They blast you online. Other anti-vaxxers pile on.", effects = {reputation = -10}}
                    }
                }
            }
        },
        {
            id = "doc_save_life",
            name = "Emergency Save",
            description = "Someone collapses at a restaurant. You're the only doctor present!",
            probability = 0.03,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Rush in and help",
                    outcomes = {
                        {probability = 0.7, result = "hero", description = "You stabilize them until paramedics arrive! Local hero!", effects = {reputation = 30, fame = 5, happiness = 25}},
                        {probability = 0.3, result = "lost", description = "Despite your efforts, they don't make it. You did everything right.", effects = {happiness = -20}}
                    }
                },
                {
                    text = "Direct others while calling 911",
                    outcomes = {
                        {probability = 0.8, result = "coordinated", description = "Your direction kept people calm. Good outcome!", effects = {reputation = 15, leadership = 1}},
                        {probability = 0.2, result = "chaos", description = "Not enough. You should have jumped in.", effects = {happiness = -10}}
                    }
                }
            }
        },
        {
            id = "doc_burnout",
            name = "Burnout Crisis",
            description = "You're exhausted, disconnected, and questioning everything about your career.",
            probability = 0.06,
            minYearsInJob = 2,
            choices = {
                {
                    text = "Take a leave of absence",
                    outcomes = {
                        {probability = 0.8, result = "recovered", description = "Time off was needed. You come back refreshed.", effects = {health = 20, happiness = 20, stress = -30}},
                        {probability = 0.2, result = "guilt", description = "Hard to relax knowing patients need you.", effects = {health = 10, stress = -10}}
                    }
                },
                {
                    text = "Push through",
                    outcomes = {
                        {probability = 0.3, result = "fine", description = "You find a second wind. Maybe it was just a bad week.", effects = {}},
                        {probability = 0.7, result = "worse", description = "It gets worse. You start making mistakes.", effects = {health = -15, stress = 30, reputation = -10}}
                    }
                },
                {
                    text = "Seek professional help",
                    outcomes = {
                        {probability = 0.9, result = "therapy", description = "Therapy helps. Doctors need doctors too.", effects = {happiness = 15, stress = -20}},
                        {probability = 0.1, result = "stigma", description = "You worry about colleagues finding out.", effects = {stress = -10, happiness = 5}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Diagnosed something textbook for once. Refreshing.",
        "A patient brought you coffee. You really needed it.",
        "The charting is never-ending.",
        "An elderly patient's stories made you smile.",
        "Insurance denied a medication your patient needs. Time to fight.",
        "Successfully delivered hard news with compassion.",
        "A colleague asked for your opinion on a case.",
        "You remembered why you went into medicine today.",
        "The student shadowing you asked great questions.",
        "On-call night was surprisingly quiet. Suspicious.",
        "A patient finally quit smoking! Your nagging worked!",
        "Hospital admin wants you in another meeting. Joy.",
        "Your handwriting is still illegible. It's a doctor thing.",
        "Caught a diagnosis everyone else missed."
    }
}

-- SURGEON
CareerData_Part3.Jobs["Surgeon"] = {
    id = "surgeon",
    title = "Surgeon",
    category = "Medical",
    baseSalary = 350000,
    salaryRange = {280000, 500000},
    minAge = 33,
    maxAge = nil,
    requirement = "Medical Degree",
    specialization = "Surgery Residency",
    license = "Medical License",
    requiredSkills = {Medical = 70, Technical = 50},
    skillGains = {Medical = 3, Technical = 2, Leadership = 1},
    description = "Cut people open to fix them. No pressure.",
    workEnvironment = "hospital",
    stressLevel = "extreme",
    promotionPath = "Chief of Surgery",
    
    careerEvents = {
        {
            id = "surg_complication",
            name = "Surgical Complication",
            description = "During surgery, you encounter unexpected complications!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Adapt and overcome",
                    outcomes = {
                        {probability = 0.7, result = "save", description = "Years of training kick in. You adapt and save them!", effects = {reputation = 20, medical = 2}},
                        {probability = 0.3, result = "close", description = "Touch and go, but patient survives. Close call.", effects = {stress = 25}}
                    }
                },
                {
                    text = "Call for backup surgeon",
                    outcomes = {
                        {probability = 0.8, result = "help", description = "Second pair of hands helps. Good teamwork!", effects = {reputation = 5}},
                        {probability = 0.2, result = "no_time", description = "No time to wait. You handle it yourself.", effects = {stress = 30}}
                    }
                },
                {
                    text = "Abort the surgery",
                    outcomes = {
                        {probability = 0.5, result = "safe", description = "Safer to close and try again. Patient stabilizes.", effects = {}},
                        {probability = 0.5, result = "questioned", description = "Colleagues question if abort was necessary.", effects = {reputation = -10}}
                    }
                }
            }
        },
        {
            id = "surg_patient_death",
            name = "Lost on the Table",
            description = "A patient dies during surgery. It wasn't your fault, but...",
            probability = 0.04,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Talk to the family yourself",
                    outcomes = {
                        {probability = 0.6, result = "understanding", description = "They appreciate your honesty. Painful but right.", effects = {happiness = -15, reputation = 10}},
                        {probability = 0.4, result = "blame", description = "They blame you despite the facts.", effects = {happiness = -25, stress = 30}}
                    }
                },
                {
                    text = "Let the hospital handle notification",
                    outcomes = {
                        {probability = 0.5, result = "protocol", description = "Standard protocol. Proper but impersonal.", effects = {happiness = -10}},
                        {probability = 0.5, result = "cold", description = "Family feels you were cold for not coming yourself.", effects = {reputation = -5}}
                    }
                }
            }
        },
        {
            id = "surg_shaky_hands",
            name = "The Shakes",
            description = "Your hands are trembling before a delicate surgery. Too much coffee? Nerves?",
            probability = 0.05,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Push through - you've got this",
                    outcomes = {
                        {probability = 0.6, result = "steady", description = "Once you start, you're rock solid. Years of practice.", effects = {}},
                        {probability = 0.4, result = "shaky", description = "Your incisions aren't as clean as usual. Patient is fine but not your best work.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Have another surgeon take over",
                    outcomes = {
                        {probability = 0.7, result = "responsible", description = "Knowing your limits is professional. Patient is in good hands.", effects = {reputation = 5}},
                        {probability = 0.3, result = "questioned", description = "People wonder if you're losing your edge.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Take beta blockers to steady yourself",
                    outcomes = {
                        {probability = 0.8, result = "steady", description = "Common among surgeons. Works perfectly.", effects = {}},
                        {probability = 0.2, result = "dependency", description = "You start needing them every time...", effects = {}}
                    }
                }
            }
        },
        {
            id = "surg_innovative",
            name = "New Technique",
            description = "You've developed a new surgical technique that could revolutionize the field!",
            probability = 0.02,
            minYearsInJob = 3,
            requiresPerformance = 80,
            choices = {
                {
                    text = "Publish your research",
                    outcomes = {
                        {probability = 0.6, result = "published", description = "Your paper is a hit! Invitations to speak at conferences!", effects = {fame = 15, reputation = 40, money = 10000}},
                        {probability = 0.4, result = "disputed", description = "Other surgeons dispute your findings. Academic battle.", effects = {reputation = 15, stress = 20}}
                    }
                },
                {
                    text = "Patent it first",
                    outcomes = {
                        {probability = 0.5, result = "profitable", description = "Medical device companies are very interested...", effects = {money = 100000, reputation = 20}},
                        {probability = 0.5, result = "ethical_questions", description = "Patenting a lifesaving technique? Ethics committees aren't happy.", effects = {money = 50000, reputation = -15}}
                    }
                }
            }
        },
        {
            id = "surg_celebrity_patient",
            name = "VIP Patient",
            description = "A famous celebrity needs surgery and specifically requested you!",
            probability = 0.03,
            minYearsInJob = 2,
            choices = {
                {
                    text = "Treat them like any patient",
                    outcomes = {
                        {probability = 0.8, result = "professional", description = "Surgery goes well. They appreciate the normalcy.", effects = {reputation = 15, fame = 5}},
                        {probability = 0.2, result = "demanding", description = "Their entourage makes everything difficult.", effects = {stress = 20, fame = 3}}
                    }
                },
                {
                    text = "Pull out all stops for VIP treatment",
                    outcomes = {
                        {probability = 0.6, result = "impressed", description = "They're impressed! Recommend you to all their famous friends!", effects = {fame = 15, reputation = 20}},
                        {probability = 0.4, result = "entitled", description = "They become impossibly demanding.", effects = {stress = 25, fame = 10}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Perfect surgery. In and out in record time.",
        "The OR playlist was on point today.",
        "Scrub nurse anticipated your every move. Great team.",
        "The anesthesiologist was late. Delay of 30 minutes.",
        "Your hands were steady as stone today.",
        "Post-op patient is recovering beautifully.",
        "Medical student observed surgery. Teaching moment.",
        "Reviewed scans for tomorrow's surgery. Tricky one.",
        "Your back hurts from 6 hours standing.",
        "Another surgeon asked for your consult. Respect.",
        "OR scheduling conflicts. Politics everywhere.",
        "Innovative approach worked perfectly!",
        "The vending machine gave you two candy bars.",
        "Family thanked you in tears. That's why you do this."
    }
}

--============================================================================
-- LEGAL CAREERS
--============================================================================

-- PARALEGAL
CareerData_Part3.Jobs["Paralegal"] = {
    id = "paralegal",
    title = "Paralegal",
    category = "Legal",
    baseSalary = 50000,
    salaryRange = {40000, 65000},
    minAge = 20,
    maxAge = nil,
    requirement = "Paralegal Certificate",
    requiredSkills = {Analytical = 20},
    skillGains = {Legal = 3, Analytical = 2, Writing = 1},
    description = "Do the lawyer's work for a fraction of the pay.",
    workEnvironment = "office",
    stressLevel = "high",
    promotionPath = "Senior Paralegal",
    
    careerEvents = {
        {
            id = "para_deadline",
            name = "Filing Deadline",
            description = "The filing deadline is in 2 hours and you just found a major error!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Fix it yourself and file on time",
                    outcomes = {
                        {probability = 0.6, result = "hero", description = "Fixed and filed with 5 minutes to spare! You saved the case!", effects = {reputation = 20, stress = 15}},
                        {probability = 0.4, result = "more_errors", description = "Rush job created new errors. Filed but problematic.", effects = {reputation = -10, stress = 25}}
                    }
                },
                {
                    text = "Alert the attorney immediately",
                    outcomes = {
                        {probability = 0.7, result = "team_fix", description = "Attorney takes over. All hands on deck. Made it!", effects = {reputation = 5}},
                        {probability = 0.3, result = "blame", description = "Attorney asks why you didn't catch it sooner.", effects = {reputation = -5, stress = 20}}
                    }
                },
                {
                    text = "File it with the error",
                    outcomes = {
                        {probability = 0.2, result = "unnoticed", description = "No one catches it. Lucky.", effects = {}},
                        {probability = 0.8, result = "caught", description = "Opposing counsel catches it. Motion to dismiss.", effects = {reputation = -30, fired = true}}
                    }
                }
            }
        },
        {
            id = "para_law_school",
            name = "Law School Decision",
            description = "You've been accepted to law school! But it means quitting this job...",
            probability = 0.04,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Go to law school",
                    outcomes = {
                        {probability = 1.0, result = "school", description = "Time to become an actual lawyer!", effects = {newCareerPath = "Law Student"}}
                    }
                },
                {
                    text = "Stay - you like being a paralegal",
                    outcomes = {
                        {probability = 0.7, result = "content", description = "Good pay, less stress than attorneys. Valid choice.", effects = {happiness = 5}},
                        {probability = 0.3, result = "regret", description = "Sometimes you wonder what if...", effects = {}}
                    }
                }
            }
        },
        {
            id = "para_evidence",
            name = "Smoking Gun",
            description = "During discovery, you find evidence that could destroy your client's case!",
            probability = 0.03,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Immediately report to the attorney",
                    outcomes = {
                        {probability = 0.8, result = "ethical", description = "Attorney handles it properly. Ethics maintained.", effects = {reputation = 10, karma = 10}},
                        {probability = 0.2, result = "killed", description = "Case settles immediately. Client is furious but law is law.", effects = {reputation = 5}}
                    }
                },
                {
                    text = "Bury it",
                    outcomes = {
                        {probability = 0.3, result = "hidden", description = "It never comes up. Case won.", effects = {karma = -25}},
                        {probability = 0.7, result = "discovered", description = "It's discovered. Sanctions, disbarment talks, YOU'RE fired.", effects = {fired = true, reputation = -50}}
                    }
                },
                {
                    text = "Anonymously leak it",
                    outcomes = {
                        {probability = 0.4, result = "justice", description = "Justice is served. No one knows it was you.", effects = {karma = 15}},
                        {probability = 0.6, result = "traced", description = "They trace the leak. You're in big trouble.", effects = {fired = true, reputation = -30}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Reviewed 500 documents today. Eyes are bleeding.",
        "Found a crucial piece of evidence! Attorney didn't say thanks.",
        "The coffee machine is your best friend.",
        "Billable hours are soul-crushing.",
        "Witness interview went better than expected.",
        "The printer jammed during an important filing.",
        "Organized 10,000 pages of discovery.",
        "An attorney actually thanked you today!",
        "Worked until midnight on a brief.",
        "Your legal research was cited in court!",
        "Someone brought donuts. Day saved.",
        "The client is calling every hour for updates.",
        "Learned a new area of law today.",
        "Your desk is drowning in papers."
    }
}

-- LAWYER
CareerData_Part3.Jobs["Lawyer"] = {
    id = "lawyer",
    title = "Attorney",
    category = "Legal",
    baseSalary = 120000,
    salaryRange = {80000, 200000},
    minAge = 27,
    maxAge = nil,
    requirement = "Law Degree",
    license = "Bar Admission",
    requiredSkills = {Legal = 40, Analytical = 40, Social = 30},
    skillGains = {Legal = 3, Social = 2, Analytical = 2, Leadership = 1},
    description = "Argue cases, bill hours, and drown in paperwork.",
    workEnvironment = "office",
    stressLevel = "very_high",
    promotionPath = "Partner",
    
    careerEvents = {
        {
            id = "law_big_case",
            name = "Career-Making Case",
            description = "You've been assigned a high-profile case that could make your career!",
            probability = 0.05,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Pour everything into it",
                    outcomes = {
                        {probability = 0.5, result = "win", description = "YOU WON! Your name is in the papers! Partnership track!", effects = {reputation = 40, fame = 10, money = 50000, promotionProgress = 30}},
                        {probability = 0.3, result = "settle", description = "Favorable settlement. Not a win but not a loss.", effects = {reputation = 15, money = 20000}},
                        {probability = 0.2, result = "lose", description = "You lost. Very publicly. Career setback.", effects = {reputation = -20, happiness = -20}}
                    }
                },
                {
                    text = "Suggest settlement to client",
                    outcomes = {
                        {probability = 0.6, result = "settled", description = "Quick settlement. Good for client, less glory for you.", effects = {reputation = 10, money = 15000}},
                        {probability = 0.4, result = "refused", description = "Client wants their day in court.", effects = {stress = 15}}
                    }
                }
            }
        },
        {
            id = "law_ethics",
            name = "Ethical Dilemma",
            description = "Your client confesses to you that they're guilty. But you're winning the case...",
            probability = 0.04,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Continue the defense - it's your duty",
                    outcomes = {
                        {probability = 0.6, result = "acquittal", description = "Client acquitted. The system works as designed.", effects = {reputation = 10, karma = -10}},
                        {probability = 0.4, result = "convicted", description = "Convicted anyway. Justice served.", effects = {}}
                    }
                },
                {
                    text = "Withdraw from the case",
                    outcomes = {
                        {probability = 0.5, result = "respected", description = "Colleagues respect your integrity.", effects = {karma = 15, reputation = 5}},
                        {probability = 0.5, result = "questioned", description = "People wonder why you withdrew.", effects = {reputation = -5}}
                    }
                },
                {
                    text = "Encourage client to plead guilty",
                    outcomes = {
                        {probability = 0.4, result = "plea", description = "They take a plea deal. Lighter sentence.", effects = {karma = 10}},
                        {probability = 0.6, result = "refused", description = "They refuse. Now what?", effects = {stress = 20}}
                    }
                }
            }
        },
        {
            id = "law_courtroom_drama",
            name = "Courtroom Showdown",
            description = "Opposing counsel just made a devastating point. The jury is swayed!",
            probability = 0.08,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Object and attack the argument",
                    outcomes = {
                        {probability = 0.5, result = "recovered", description = "Your objection is sustained! Momentum shifted back!", effects = {reputation = 15, legal = 1}},
                        {probability = 0.5, result = "overruled", description = "Overruled. That point stands.", effects = {stress = 20}}
                    }
                },
                {
                    text = "Save your rebuttal for closing",
                    outcomes = {
                        {probability = 0.6, result = "closing_win", description = "Your closing argument destroys their point!", effects = {reputation = 20, social = 1}},
                        {probability = 0.4, result = "too_late", description = "Jury already made up their mind.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Request a recess to regroup",
                    outcomes = {
                        {probability = 0.5, result = "recovered", description = "Time to think. You come back strong.", effects = {}},
                        {probability = 0.5, result = "weak", description = "Looks like you're scrambling.", effects = {reputation = -5}}
                    }
                }
            }
        },
        {
            id = "law_partner_track",
            name = "Partnership Decision",
            description = "The partners are voting on whether to make you a partner!",
            probability = 0.04,
            minYearsInJob = 5,
            requiresPerformance = 75,
            choices = {
                {
                    text = "Campaign hard for it",
                    outcomes = {
                        {probability = 0.5, result = "partner", description = "YOU MADE PARTNER! Years of sacrifice paid off!", effects = {promoted = "Partner", salaryIncrease = 100000, happiness = 30}},
                        {probability = 0.5, result = "passed", description = "Passed over. Maybe next year.", effects = {happiness = -25}}
                    }
                },
                {
                    text = "Let your work speak",
                    outcomes = {
                        {probability = 0.4, result = "partner", description = "Your reputation precedes you. Welcome, Partner.", effects = {promoted = "Partner", salaryIncrease = 100000, happiness = 30}},
                        {probability = 0.6, result = "overlooked", description = "Politics won over merit.", effects = {happiness = -20}}
                    }
                },
                {
                    text = "Consider leaving for another firm",
                    outcomes = {
                        {probability = 0.6, result = "counter", description = "They counter-offer with partnership to keep you!", effects = {promoted = "Partner", salaryIncrease = 80000}},
                        {probability = 0.4, result = "leave", description = "Another firm offers you partnership!", effects = {promoted = "Partner (New Firm)", salaryIncrease = 90000}}
                    }
                }
            }
        },
        {
            id = "law_pro_bono",
            name = "Pro Bono Case",
            description = "A clearly innocent person needs help but can't pay. You're already overworked.",
            probability = 0.06,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Take the case pro bono",
                    outcomes = {
                        {probability = 0.7, result = "justice", description = "You win! An innocent person goes free. This is why you became a lawyer.", effects = {happiness = 25, karma = 20, stress = 15}},
                        {probability = 0.3, result = "lost", description = "Despite your efforts, they're convicted. Devastating.", effects = {happiness = -15, karma = 10}}
                    }
                },
                {
                    text = "Refer to legal aid",
                    outcomes = {
                        {probability = 0.6, result = "helped", description = "Legal aid takes it. They're in good hands.", effects = {karma = 5}},
                        {probability = 0.4, result = "declined", description = "Legal aid is swamped. No one helps them.", effects = {karma = -5, happiness = -5}}
                    }
                },
                {
                    text = "Decline - too busy",
                    outcomes = {
                        {probability = 0.5, result = "fine", description = "Someone else helps. Probably.", effects = {}},
                        {probability = 0.5, result = "guilt", description = "They're convicted. You could have helped.", effects = {karma = -10, happiness = -10}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Billed 14 hours today. Is this what success feels like?",
        "Won a motion! The little victories matter.",
        "Opposing counsel tried to bluff. Didn't work.",
        "Client calls at midnight. Again.",
        "Your closing argument was flawless.",
        "Paralegal saved you with their research.",
        "Judge ruled in your favor!",
        "Pulled an all-nighter on a brief.",
        "Settled a case without going to trial. Efficient.",
        "A witness lied on the stand. You knew it.",
        "Made it home for dinner! First time this week.",
        "Your suit is now your personality.",
        "Client verdict: Not Guilty. The relief.",
        "Associate you mentored won their first case!",
        "The coffee here costs $8. You don't care anymore."
    }
}

--============================================================================
-- FINANCE CAREERS
--============================================================================

-- BANK TELLER
CareerData_Part3.Jobs["Bank Teller"] = {
    id = "bank_teller",
    title = "Bank Teller",
    category = "Finance",
    baseSalary = 32000,
    salaryRange = {28000, 40000},
    minAge = 18,
    maxAge = nil,
    requirement = "High School",
    requiredSkills = {},
    skillGains = {Financial = 2, Social = 2, Analytical = 1},
    description = "Count money, help customers, and don't get robbed.",
    workEnvironment = "bank",
    stressLevel = "medium",
    promotionPath = "Head Teller",
    
    careerEvents = {
        {
            id = "teller_robbery",
            name = "Bank Robbery!",
            description = "Someone passes you a note: 'Give me all the money. I have a gun.'",
            probability = 0.03,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Follow protocol - give them the money",
                    outcomes = {
                        {probability = 0.9, result = "safe", description = "You hand over the money. They leave. You're safe. The dye pack explodes in their car.", effects = {stress = 30, happiness = -10}},
                        {probability = 0.1, result = "hostage", description = "They don't leave. Hostage situation.", effects = {stress = 50, health = -10}}
                    }
                },
                {
                    text = "Trigger the silent alarm",
                    outcomes = {
                        {probability = 0.7, result = "police", description = "Police arrive. Robber flees. You're a hero!", effects = {reputation = 25, stress = 25}},
                        {probability = 0.3, result = "noticed", description = "They notice you moving. Things escalate.", effects = {health = -15, stress = 40}}
                    }
                },
                {
                    text = "Try to stall them",
                    outcomes = {
                        {probability = 0.4, result = "caught", description = "Police arrive while you stall! Arrest made!", effects = {reputation = 30, stress = 30}},
                        {probability = 0.6, result = "impatient", description = "They get impatient and aggressive.", effects = {health = -10, stress = 35}}
                    }
                }
            }
        },
        {
            id = "teller_shortage",
            name = "Drawer Shortage",
            description = "Your drawer is $100 short at end of day!",
            probability = 0.07,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Report it honestly",
                    outcomes = {
                        {probability = 0.6, result = "found", description = "Security footage shows a transaction error. Not your fault!", effects = {}},
                        {probability = 0.4, result = "warning", description = "It's on your record. Watch your counts.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Cover it from your own pocket",
                    outcomes = {
                        {probability = 0.7, result = "covered", description = "Drawer balances. Crisis averted.", effects = {money = -100}},
                        {probability = 0.3, result = "discovered", description = "They review the video anyway. Suspicious.", effects = {money = -100, reputation = -15}}
                    }
                },
                {
                    text = "Recount everything",
                    outcomes = {
                        {probability = 0.5, result = "found", description = "Found a stuck bill! Drawer balances!", effects = {happiness = 10}},
                        {probability = 0.5, result = "still_short", description = "Still short after recount.", effects = {stress = 15}}
                    }
                }
            }
        },
        {
            id = "teller_elderly_scam",
            name = "Elder Scam Suspected",
            description = "An elderly customer wants to wire $10,000 to 'their grandson in trouble'. Something seems off.",
            probability = 0.06,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Process the wire as requested",
                    outcomes = {
                        {probability = 0.2, result = "legitimate", description = "It was really their grandson. You were wrong.", effects = {}},
                        {probability = 0.8, result = "scam", description = "It was a scam. Their life savings gone. You feel awful.", effects = {happiness = -20, karma = -15}}
                    }
                },
                {
                    text = "Ask questions and delay the transaction",
                    outcomes = {
                        {probability = 0.7, result = "stopped", description = "You helped them realize it's a scam! You saved their savings!", effects = {reputation = 25, happiness = 15, karma = 15}},
                        {probability = 0.3, result = "upset", description = "They're upset you're interfering. Manager gets involved.", effects = {stress = 15}}
                    }
                },
                {
                    text = "Alert your manager",
                    outcomes = {
                        {probability = 0.8, result = "intervention", description = "Manager helps investigate. Scam confirmed!", effects = {reputation = 15, karma = 10}},
                        {probability = 0.2, result = "overreaction", description = "It was legitimate. Customer files complaint.", effects = {reputation = -5}}
                    }
                }
            }
        },
        {
            id = "teller_promotion",
            name = "Personal Banker Opening",
            description = "A position opened for Personal Banker. Better pay and your own desk!",
            probability = 0.06,
            minYearsInJob = 1,
            requiresPerformance = 60,
            choices = {
                {
                    text = "Apply for it",
                    outcomes = {
                        {probability = 0.6, result = "promoted", description = "You got it! No more standing all day!", effects = {promoted = "Personal Banker", salaryIncrease = 8000}},
                        {probability = 0.4, result = "denied", description = "Went to someone with more sales numbers.", effects = {happiness = -10}}
                    }
                },
                {
                    text = "Stay at teller line",
                    outcomes = {
                        {probability = 1.0, result = "content", description = "Less sales pressure at the teller line.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Counted $50,000 without a single error!",
        "A customer gave you a holiday card. Sweet.",
        "Someone tried to cash a clearly fake check.",
        "Your line was out the door all day.",
        "Helped a first-time home buyer with their mortgage payment.",
        "The coin counter broke. Manual counting time.",
        "A customer yelled at you about fees you didn't create.",
        "Security guard told you good jokes all day.",
        "Made a child smile with a lollipop.",
        "Your feet hurt from standing all day.",
        "Break room had cake for someone's birthday!",
        "Explained how interest works. Again.",
        "A customer brought their dog. Best part of the day.",
        "The AC is broken. Everyone is miserable."
    }
}

-- FINANCIAL ANALYST
CareerData_Part3.Jobs["Financial Analyst"] = {
    id = "financial_analyst",
    title = "Financial Analyst",
    category = "Finance",
    baseSalary = 75000,
    salaryRange = {60000, 100000},
    minAge = 22,
    maxAge = nil,
    requirement = "Bachelor's Degree",
    preferredMajor = "Finance",
    requiredSkills = {Financial = 30, Analytical = 40},
    skillGains = {Financial = 3, Analytical = 3, Technical = 1},
    description = "Crunch numbers, build models, and predict the future (sort of).",
    workEnvironment = "office",
    stressLevel = "high",
    promotionPath = "Senior Financial Analyst",
    
    careerEvents = {
        {
            id = "fin_bad_call",
            name = "Bad Investment Call",
            description = "Your investment recommendation just lost the company $500,000!",
            probability = 0.05,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Own the mistake and explain what went wrong",
                    outcomes = {
                        {probability = 0.6, result = "forgiven", description = "Everyone makes bad calls. Your honesty is respected.", effects = {reputation = -10}},
                        {probability = 0.4, result = "consequences", description = "You're off the big accounts for now.", effects = {reputation = -20, stress = 20}}
                    }
                },
                {
                    text = "Blame market volatility",
                    outcomes = {
                        {probability = 0.5, result = "accepted", description = "True enough. Unpredictable markets.", effects = {reputation = -5}},
                        {probability = 0.5, result = "seen_through", description = "Boss knows you're making excuses.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Try to recoup losses with a risky play",
                    outcomes = {
                        {probability = 0.3, result = "recovered", description = "Against all odds, you recovered the losses!", effects = {reputation = 15}},
                        {probability = 0.7, result = "worse", description = "You made it worse. Much worse.", effects = {reputation = -30, fired = true}}
                    }
                }
            }
        },
        {
            id = "fin_insider_tip",
            name = "Suspicious Tip",
            description = "A friend who works at another company hints at upcoming merger news...",
            probability = 0.04,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Trade on the information",
                    outcomes = {
                        {probability = 0.4, result = "rich", description = "The merger happens! You made $50,000!", effects = {money = 50000, karma = -30}},
                        {probability = 0.6, result = "sec", description = "SEC investigates. Your trades are flagged.", effects = {arrested = true, fired = true}}
                    }
                },
                {
                    text = "Ignore it completely",
                    outcomes = {
                        {probability = 0.9, result = "clean", description = "Smart move. Your conscience is clear.", effects = {karma = 5}},
                        {probability = 0.1, result = "regret", description = "Merger was huge. You missed out legally.", effects = {happiness = -5}}
                    }
                },
                {
                    text = "Report to compliance",
                    outcomes = {
                        {probability = 0.8, result = "protected", description = "Compliance investigates. You're in the clear.", effects = {reputation = 10, karma = 10}},
                        {probability = 0.2, result = "drama", description = "Your friend gets in trouble. Friendship over.", effects = {karma = 10, happiness = -10}}
                    }
                }
            }
        },
        {
            id = "fin_model_works",
            name = "Model Vindication",
            description = "Your financial model predicted a market movement PERFECTLY!",
            probability = 0.06,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Present findings to leadership",
                    outcomes = {
                        {probability = 0.7, result = "recognition", description = "Leadership is impressed! You're getting noticed!", effects = {reputation = 25, promotionProgress = 15}},
                        {probability = 0.3, result = "jealousy", description = "Colleagues are jealous. Office politics incoming.", effects = {reputation = 15, stress = 10}}
                    }
                },
                {
                    text = "Quietly document for future use",
                    outcomes = {
                        {probability = 0.6, result = "portfolio", description = "Building a track record. Smart.", effects = {reputation = 5}},
                        {probability = 0.4, result = "missed", description = "Could have gotten more credit.", effects = {}}
                    }
                }
            }
        },
        {
            id = "fin_burnout",
            name = "80 Hour Weeks",
            description = "You've worked 80 hours a week for 3 months. Earnings season is brutal.",
            probability = 0.08,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Push through",
                    outcomes = {
                        {probability = 0.5, result = "bonus", description = "Huge bonus at year end! Worth it?", effects = {money = 15000, health = -15, stress = 25}},
                        {probability = 0.5, result = "burnout", description = "You burn out completely.", effects = {health = -25, happiness = -20}}
                    }
                },
                {
                    text = "Set boundaries",
                    outcomes = {
                        {probability = 0.4, result = "respected", description = "Manager respects your limits.", effects = {happiness = 10}},
                        {probability = 0.6, result = "slacker", description = "You're seen as 'not committed'.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Look for a new job",
                    outcomes = {
                        {probability = 0.6, result = "offer", description = "Better work-life balance elsewhere! Job offer!", effects = {jobOffer = "Financial Analyst (Better Hours)", offerSalary = 80000}},
                        {probability = 0.4, result = "stuck", description = "Market is tough. Stuck for now.", effects = {happiness = -10}}
                    }
                }
            }
        },
        {
            id = "fin_cfa",
            name = "CFA Exam",
            description = "Time to take the CFA Level 1 exam!",
            probability = 0.05,
            minYearsInJob = 1,
            choices = {
                {
                    text = "Study hard and take it",
                    outcomes = {
                        {probability = 0.5, result = "pass", description = "You PASSED! On to Level 2!", effects = {reputation = 20, financial = 3}},
                        {probability = 0.5, result = "fail", description = "Failed. Join the 60% who fail the first time.", effects = {happiness = -15, money = -1000}}
                    }
                },
                {
                    text = "Postpone - not ready",
                    outcomes = {
                        {probability = 0.7, result = "delay", description = "More time to study. Registration expires though.", effects = {money = -500}},
                        {probability = 0.3, result = "never", description = "You keep postponing. The dream fades.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Your Excel crashed and took 2 hours of work with it. Autosave failed.",
        "Built a model that actually made sense on the first try.",
        "Earnings call revealed something your model predicted!",
        "Stared at spreadsheets for 12 hours straight.",
        "The coffee in the finance department is top tier.",
        "Presented to the CFO. Didn't choke!",
        "Pivot tables are your best friend.",
        "Another all-nighter for earnings season.",
        "Your financial projection was spot on!",
        "Argued with an MD about assumptions. You were right.",
        "The market did something completely irrational today.",
        "Bloomberg terminal is your happy place.",
        "Free dinner for staying late. Again.",
        "Your model broke at 2 AM. The panic was real."
    }
}

-- INVESTMENT BANKER
CareerData_Part3.Jobs["Investment Banker"] = {
    id = "investment_banker",
    title = "Investment Banking Analyst",
    category = "Finance",
    baseSalary = 110000,
    salaryRange = {95000, 150000},
    bonusRange = {50000, 150000},
    minAge = 22,
    maxAge = nil,
    requirement = "Bachelor's Degree",
    preferredMajor = "Finance",
    targetSchools = true,
    requiredSkills = {Financial = 40, Analytical = 50},
    skillGains = {Financial = 4, Analytical = 3, Leadership = 1},
    description = "Work 100 hours a week for money you won't have time to spend.",
    workEnvironment = "office",
    stressLevel = "extreme",
    promotionPath = "Associate",
    
    careerEvents = {
        {
            id = "ib_live_deal",
            name = "Live Deal",
            description = "You're staffed on a billion dollar M&A deal. This is what you signed up for!",
            probability = 0.08,
            minYearsInJob = 0.3,
            choices = {
                {
                    text = "Be the first in, last out",
                    outcomes = {
                        {probability = 0.6, result = "noticed", description = "MD notices your hustle. You're his new favorite.", effects = {reputation = 30, stress = 35, promotionProgress = 20}},
                        {probability = 0.4, result = "burnout", description = "You did great but you're completely fried.", effects = {reputation = 20, health = -20, stress = 40}}
                    }
                },
                {
                    text = "Do excellent work but maintain sanity",
                    outcomes = {
                        {probability = 0.5, result = "balanced", description = "Great work with reasonable hours. Is that possible?", effects = {reputation = 15}},
                        {probability = 0.5, result = "compared", description = "You're compared unfavorably to the gunner on the team.", effects = {reputation = 5}}
                    }
                },
                {
                    text = "Try to get off the deal",
                    outcomes = {
                        {probability = 0.3, result = "moved", description = "Moved to another deal. Less prestigious but manageable.", effects = {}},
                        {probability = 0.7, result = "labeled", description = "You're labeled as 'not a team player'.", effects = {reputation = -25}}
                    }
                }
            }
        },
        {
            id = "ib_mistake_deck",
            name = "Mistake in the Deck",
            description = "There's a typo in the pitch deck going to the CEO in 10 minutes!",
            probability = 0.09,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Race to fix and reprint",
                    outcomes = {
                        {probability = 0.6, result = "fixed", description = "Fixed with 2 minutes to spare! Crisis averted!", effects = {stress = 20}},
                        {probability = 0.4, result = "too_late", description = "Didn't make it. MD is furious.", effects = {reputation = -15, stress = 30}}
                    }
                },
                {
                    text = "Hope no one notices",
                    outcomes = {
                        {probability = 0.3, result = "unnoticed", description = "Somehow, no one saw it.", effects = {}},
                        {probability = 0.7, result = "caught", description = "CEO pointed it out. In the meeting. Everyone knows.", effects = {reputation = -20, happiness = -15}}
                    }
                },
                {
                    text = "Alert the team immediately",
                    outcomes = {
                        {probability = 0.7, result = "team_fix", description = "Someone stalls, someone prints. Team effort!", effects = {stress = 15}},
                        {probability = 0.3, result = "blame", description = "Who made this deck? Oh, you.", effects = {reputation = -10}}
                    }
                }
            }
        },
        {
            id = "ib_prestige",
            name = "Headhunter Call",
            description = "A headhunter is offering a VP role at a prestigious private equity firm!",
            probability = 0.04,
            minYearsInJob = 2,
            requiresPerformance = 70,
            choices = {
                {
                    text = "Take the interview",
                    outcomes = {
                        {probability = 0.5, result = "offer", description = "They want you! $300K all-in with carried interest!", effects = {jobOffer = "VP Private Equity", offerSalary = 300000}},
                        {probability = 0.3, result = "reject", description = "Didn't make the cut. The PE interviews are brutal.", effects = {happiness = -10}},
                        {probability = 0.2, result = "found_out", description = "Your MD found out you interviewed. Awkward.", effects = {reputation = -15}}
                    }
                },
                {
                    text = "Stay on partner track",
                    outcomes = {
                        {probability = 0.6, result = "loyal", description = "Loyalty noted. You're being groomed for MD.", effects = {promotionProgress = 15}},
                        {probability = 0.4, result = "wonder", description = "Sometimes you wonder what could have been...", effects = {}}
                    }
                }
            }
        },
        {
            id = "ib_weekend",
            name = "Weekend Surprise",
            description = "It's Friday 6 PM and you thought you were free. MD just staffed you on a Sunday pitch.",
            probability = 0.12,
            minYearsInJob = 0,
            choices = {
                {
                    text = "Cancel your plans",
                    outcomes = {
                        {probability = 0.8, result = "normal", description = "Just another weekend at the office. You're used to this.", effects = {happiness = -10, stress = 15}},
                        {probability = 0.2, result = "rewarded", description = "Deal closes. Nice bonus bump.", effects = {happiness = -5, money = 5000}}
                    }
                },
                {
                    text = "Push back - you have commitments",
                    outcomes = {
                        {probability = 0.2, result = "respected", description = "MD respects your boundaries. Rare.", effects = {}},
                        {probability = 0.8, result = "noted", description = "It's noted. Not favorably.", effects = {reputation = -10}}
                    }
                },
                {
                    text = "Pull an all-nighter Friday to finish early",
                    outcomes = {
                        {probability = 0.5, result = "done", description = "You finished before Saturday! Weekend saved!", effects = {stress = 20}},
                        {probability = 0.5, result = "more_work", description = "They find more work. Of course they do.", effects = {stress = 25, happiness = -15}}
                    }
                }
            }
        },
        {
            id = "ib_cocaine",
            name = "The Bathroom Bump",
            description = "A senior banker offers you cocaine at a client event. 'It's how we keep going.'",
            probability = 0.03,
            minYearsInJob = 0.5,
            choices = {
                {
                    text = "Decline politely",
                    outcomes = {
                        {probability = 0.8, result = "respected", description = "They shrug and move on. No pressure.", effects = {}},
                        {probability = 0.2, result = "outsider", description = "You're never quite in the 'inner circle'.", effects = {reputation = -5}}
                    }
                },
                {
                    text = "Accept",
                    outcomes = {
                        {probability = 0.5, result = "energy", description = "You've never felt more awake. Is this what they're all doing?", effects = {health = -10, stress = -15}},
                        {probability = 0.5, result = "spiral", description = "This becomes a pattern. A dangerous one.", effects = {health = -30, addiction = true}}
                    }
                },
                {
                    text = "Report to compliance",
                    outcomes = {
                        {probability = 0.4, result = "investigation", description = "Investigation launched. You're protected as whistleblower.", effects = {karma = 15}},
                        {probability = 0.6, result = "nothing", description = "Compliance 'looks into it'. Nothing happens. The guy still works there.", effects = {}}
                    }
                }
            }
        }
    },
    
    workDayEvents = {
        "Only worked 70 hours this week! It's like vacation!",
        "Your Seamless order history is embarrassing.",
        "MD complimented your model. Made your month.",
        "Printer jammed at 3 AM. Classic.",
        "Slept under your desk. The cleaners saw you.",
        "Closing dinner was at a 3-star Michelin restaurant.",
        "Your Uber driver at 4 AM recognized you. Concerning.",
        "Deal closed! Time to do it all again.",
        "Associates are hazing the new analyst. You were there once.",
        "Bonus day. All forgiven. Until Monday.",
        "Client threw their coffee at the wall. Normal Tuesday.",
        "Your Bloomberg terminal is your only friend.",
        "Pitched to a Fortune 500 CEO. Didn't faint!",
        "Free dinner every night! Because you can never leave!",
        "Considered crying in the bathroom. Decided against it."
    }
}

return CareerData_Part3
