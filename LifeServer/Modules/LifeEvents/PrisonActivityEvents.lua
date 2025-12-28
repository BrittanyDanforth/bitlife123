--[[
	PrisonActivityEvents.lua
	========================
	Comprehensive event templates for prison activities.
	These events give players immersive BitLife-style event cards
	for all prison-related actions.
	
	Categories:
	- prison_workout: Exercise in the yard
	- prison_study: Education and self-improvement  
	- prison_job: Prison work assignments
	- prison_crew: Gang/crew interactions with combat
	- prison_riot: Prison riots with combat
	- prison_snitch: Informing on other inmates
	- prison_appeal: Legal appeals
	- prison_escape: Escape attempts
	- prison_fight: Random yard fights
	- prison_contraband: Smuggling items
	- prison_therapy: Mental health support
	
	CRITICAL FIX: Added global cooldown system to prevent spam!
	User complaint: "THE PRISON SPAMS STUFF"
--]]

local PrisonEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: GLOBAL COOLDOWN SYSTEM TO PREVENT SPAM
-- Tracks last time each category was shown to prevent rapid repetition
-- User complaint: "THE PRISON SPAMS STUFF"
-- ═══════════════════════════════════════════════════════════════════════════════
PrisonEvents.COOLDOWNS = {
	Workout = 1,    -- Can show workout events every year
	Study = 1,      -- Can show study events every year
	Job = 1,        -- Can show job events every year
	Crew = 2,       -- Gang events every 2 years minimum
	Riot = 5,       -- Riots are rare - 5 year minimum between
	Snitch = 3,     -- Snitch events every 3 years
	Appeal = 2,     -- Appeal events every 2 years
	Fight = 2,      -- Fights every 2 years
}

-- Track when last event of each type was shown
PrisonEvents.LastShown = {}

function PrisonEvents.canShowCategory(state, category)
	if not state then return true end
	local cooldown = PrisonEvents.COOLDOWNS[category] or 1
	
	-- Get last shown age for this category
	state._prisonEventHistory = state._prisonEventHistory or {}
	local lastAge = state._prisonEventHistory[category]
	
	if not lastAge then return true end
	
	local currentAge = state.Age or 0
	return (currentAge - lastAge) >= cooldown
end

function PrisonEvents.markCategoryShown(state, category)
	if not state then return end
	state._prisonEventHistory = state._prisonEventHistory or {}
	state._prisonEventHistory[category] = state.Age or 0
end

-- CRITICAL FIX: Limit total prison events per year to prevent spam
PrisonEvents.MAX_EVENTS_PER_YEAR = 2
function PrisonEvents.canShowMoreThisYear(state)
	if not state then return true end
	state._prisonEventsThisYear = state._prisonEventsThisYear or 0
	return state._prisonEventsThisYear < PrisonEvents.MAX_EVENTS_PER_YEAR
end

function PrisonEvents.incrementYearlyCount(state)
	if not state then return end
	state._prisonEventsThisYear = (state._prisonEventsThisYear or 0) + 1
end

function PrisonEvents.resetYearlyCount(state)
	if not state then return end
	state._prisonEventsThisYear = 0
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRISON WORKOUT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
PrisonEvents.Workout = {
	-- Event 1: Basic yard workout
	{
		id = "prison_workout_basic",
		title = "💪 Yard Time",
		texts = {
			"You head out to the yard for your daily exercise time.",
			"The prison yard is your gym now. Time to get in shape.",
			"Other inmates are already working out when you arrive at the yard.",
			"The sun beats down on the yard as you start your workout routine.",
		},
		effects = { Health = {5, 10}, Happiness = {2, 5} },
		choices = {
			{
				text = "Hit the weights hard",
				feedback = {
					"You push yourself to the limit on the bench press. 💪",
					"Your muscles burn as you lift more than yesterday.",
					"Other inmates nod in respect as you work the iron.",
				},
				effects = { Health = 10 },
			},
			{
				text = "Do cardio laps",
				feedback = {
					"You run laps around the yard until your lungs burn.",
					"The repetitive running helps clear your mind.",
					"You complete 20 laps before the guards call time.",
				},
				effects = { Health = 8, Happiness = 3 },
			},
			{
				text = "Join a group workout",
				feedback = {
					"You join a group of inmates doing calisthenics.",
					"Working out with others keeps you motivated.",
					"The group accepts you as one of their own.",
				},
				effects = { Health = 7, Happiness = 5 },
			},
		},
	},
	-- Event 2: Challenged by another inmate
	{
		id = "prison_workout_challenge",
		title = "🏋️ Workout Challenge",
		texts = {
			"A muscular inmate approaches you. 'Bet you can't outlift me.'",
			"'Hey new fish, let's see what you got,' says a scarred inmate.",
			"Someone wants to prove they're stronger than you in the yard.",
		},
		effects = { Health = {3, 8} },
		choices = {
			{
				text = "Accept the challenge",
				feedback = {
					"You go rep for rep. In the end, you earn respect either way.",
					"The competition pushes you harder than ever before.",
					"Win or lose, you showed you're not afraid.",
				},
				effects = { Health = 12, Happiness = 5 },
				triggersCombat = true,
			},
			{
				text = "Decline politely",
				feedback = {
					"You're not here to prove anything. Smart choice.",
					"'No thanks, I'm just here to do my time,' you say.",
					"The inmate shrugs and finds another challenger.",
				},
				effects = { Health = 5 },
			},
			{
				text = "Mock him instead",
				feedback = {
					"Your words provoke him. He swings at you!",
					"Bad move. Now you're fighting for real.",
					"Guards are watching. This could go badly.",
				},
				effects = { Health = -5 },
				triggersCombat = true,
			},
		},
	},
	-- Event 3: Guard harassment
	{
		id = "prison_workout_guard",
		title = "🚔 Guard Interruption",
		texts = {
			"A guard stops you mid-rep. 'Think you're tough, convict?'",
			"Officer Martinez doesn't like you exercising. 'Back to your cell!'",
			"The guards seem to be targeting you today during yard time.",
		},
		effects = { Happiness = {-5, -2} },
		choices = {
			{
				text = "Comply immediately",
				feedback = {
					"You put the weights down and walk away quietly.",
					"'Smart choice, convict,' the guard sneers.",
					"No use arguing with authority in here.",
				},
				effects = { Happiness = -3 },
			},
			{
				text = "Ask what the problem is",
				feedback = {
					"'Just keeping an eye on troublemakers,' he says.",
					"You ask respectfully and he eventually moves on.",
					"The guard seems satisfied you're not a threat.",
				},
				effects = {},
			},
			{
				text = "Ignore and keep lifting",
				feedback = {
					"The guard blows his whistle. You're heading to solitary.",
					"Guards don't appreciate being ignored. Bad call.",
					"You're dragged away from the yard. A week in the hole.",
				},
				effects = { Happiness = -10, Health = -5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRISON STUDY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
PrisonEvents.Study = {
	-- Event 1: Library time
	{
		id = "prison_study_library",
		title = "📚 Prison Library",
		texts = {
			"The prison library is quiet today. Perfect for studying.",
			"You find a corner in the library to work on your education.",
			"Books are your escape from the prison routine.",
			"The librarian nods as you settle in with some textbooks.",
		},
		effects = { Smarts = {3, 8} },
		choices = {
			{
				text = "Study law books",
				feedback = {
					"You read about appeals and legal procedures.",
					"The more you learn, the better your appeal might go.",
					"Knowledge is power, especially behind bars.",
				},
				effects = { Smarts = 8 },
			},
			{
				text = "Read literature",
				feedback = {
					"You lose yourself in a classic novel.",
					"Books transport you far from these walls.",
					"Reading expands your mind and soothes your soul.",
				},
				effects = { Smarts = 5, Happiness = 5 },
			},
			{
				text = "Study for GED",
				feedback = {
					"You work through practice tests and exercises.",
					"Getting your GED could help when you get out.",
					"Education is your ticket to a better future.",
				},
				effects = { Smarts = 10 },
			},
		},
	},
	-- Event 2: Teaching opportunity
	{
		id = "prison_study_teach",
		title = "📖 Teaching Others",
		texts = {
			"A younger inmate asks if you can help him learn to read.",
			"'Hey, you seem smart. Can you help me with this?' an inmate asks.",
			"Someone notices your studying and wants to learn from you.",
		},
		effects = { Smarts = {2, 5}, Happiness = {3, 7} },
		choices = {
			{
				text = "Help them learn",
				feedback = {
					"You spend an hour teaching basic reading skills.",
					"The gratitude in their eyes makes it worthwhile.",
					"Teaching someone else actually helps you learn too.",
				},
				effects = { Smarts = 3, Happiness = 8 },
			},
			{
				text = "Too busy studying",
				feedback = {
					"'Sorry, I need to focus on my own work,' you say.",
					"They look disappointed but understand.",
					"You have to look out for yourself in here.",
				},
				effects = { Smarts = 5 },
			},
			{
				text = "Charge them for tutoring",
				feedback = {
					"'Commissary items, and I'll help,' you say.",
					"They agree. You now have a side hustle.",
					"Everything has a price behind bars.",
				},
				effects = { Smarts = 3 },
			},
		},
	},
	-- Event 3: Computer lab
	{
		id = "prison_study_computer",
		title = "💻 Computer Class",
		texts = {
			"The prison offers a basic computer skills class.",
			"You sign up for the computer lab to learn useful skills.",
			"Technology skills could help you find work after release.",
		},
		effects = { Smarts = {5, 10} },
		choices = {
			{
				text = "Learn typing and office skills",
				feedback = {
					"You practice typing and basic spreadsheet work.",
					"Your typing speed improves significantly.",
					"Practical skills that employers want.",
				},
				effects = { Smarts = 8 },
			},
			{
				text = "Study programming basics",
				feedback = {
					"The instructor teaches you basic coding concepts.",
					"It's challenging but fascinating.",
					"Maybe you could have a tech career after release.",
				},
				effects = { Smarts = 12 },
			},
			{
				text = "Just browse (limited internet)",
				feedback = {
					"You don't learn much but it passes the time.",
					"The heavily filtered internet is better than nothing.",
					"A small connection to the outside world.",
				},
				effects = { Happiness = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRISON CREW EVENTS (WITH COMBAT)
-- ═══════════════════════════════════════════════════════════════════════════════
PrisonEvents.Crew = {
	-- Event 1: Initiation
	{
		id = "prison_crew_initiation",
		title = "⛓️ Gang Initiation",
		texts = {
			"The Southside crew is willing to let you join... if you prove yourself.",
			"'You want protection? You gotta earn it,' the shot-caller says.",
			"Joining a crew means safety, but also obligations.",
		},
		effects = { Happiness = {-5, 5} },
		triggersCombat = true,
		combatContext = "prison",
		combatDifficulty = "trained",
		choices = {
			{
				text = "Accept the initiation",
				feedback = {
					"You step into the circle. Time to prove yourself.",
					"They don't go easy on you, but you hold your ground.",
					"Blood is spilled, but respect is earned.",
				},
				effects = { Health = -15, Happiness = 10 },
				triggersCombat = true,
			},
			{
				text = "Try to negotiate",
				feedback = {
					"'I can be useful in other ways,' you say.",
					"The shot-caller considers your offer.",
					"Maybe you can earn your place without violence.",
				},
				effects = { Smarts = 3 },
			},
			{
				text = "Walk away",
				feedback = {
					"'Not interested,' you say and turn your back.",
					"They let you go... for now. But you're on your own.",
					"Independence has its costs in prison.",
				},
				effects = { Happiness = -5 },
			},
		},
	},
	-- Event 2: Crew business
	{
		id = "prison_crew_business",
		title = "🤝 Crew Business",
		texts = {
			"Your crew needs you to handle something in the yard.",
			"The shot-caller has a job for you. Can't say no.",
			"Being in a crew means doing what you're told.",
		},
		effects = {},
		choices = {
			{
				text = "Do what they ask",
				feedback = {
					"You handle the business. Loyalty is everything.",
					"The crew appreciates your dependability.",
					"You've proven yourself once again.",
				},
				effects = { Happiness = 3 },
			},
			{
				text = "Question the order",
				feedback = {
					"'Why me?' you ask. The shot-caller doesn't like questions.",
					"You do it anyway, but there's tension now.",
					"Watch your back. Trust is everything in here.",
				},
				effects = { Happiness = -3 },
			},
			{
				text = "Refuse",
				feedback = {
					"Refusing a direct order? That's dangerous.",
					"The crew might see you as unreliable now.",
					"You might need to watch your back.",
				},
				effects = { Happiness = -10 },
				triggersCombat = true,
			},
		},
	},
	-- Event 3: Rival crew
	{
		id = "prison_crew_rivals",
		title = "⚔️ Rival Crew",
		texts = {
			"Northside boys are moving into your crew's territory.",
			"A rival gang member is talking trash about your crew.",
			"Tension is high between your crew and the rivals.",
		},
		effects = {},
		triggersCombat = true,
		combatContext = "prison",
		combatDifficulty = "strong",
		choices = {
			{
				text = "Confront them",
				feedback = {
					"You step up. 'You got a problem?' Violence erupts.",
					"Words turn to fists fast in the yard.",
					"Your crew has your back, but this gets ugly.",
				},
				effects = { Health = -10, Happiness = 5 },
				triggersCombat = true,
			},
			{
				text = "Report to shot-caller",
				feedback = {
					"You let leadership handle it. Smart politics.",
					"The shot-caller appreciates the intel.",
					"Sometimes the best move is not making one.",
				},
				effects = { Happiness = 2 },
			},
			{
				text = "Stay out of it",
				feedback = {
					"You keep your head down and avoid the drama.",
					"Your crew might see this as weakness.",
					"In prison, neutrality is sometimes seen as betrayal.",
				},
				effects = { Happiness = -5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRISON RIOT EVENTS (WITH COMBAT)
-- ═══════════════════════════════════════════════════════════════════════════════
PrisonEvents.Riot = {
	-- Event 1: Riot starts
	{
		id = "prison_riot_start",
		title = "🔥 Prison Riot!",
		texts = {
			"The prison erupts in chaos. A riot has started!",
			"Inmates are fighting guards. Fires are burning. Total chaos.",
			"You hear the alarms blaring. This is a full-scale riot!",
		},
		effects = { Health = {-20, -5}, Happiness = {-10, 10} },
		triggersCombat = true,
		combatContext = "prison",
		combatDifficulty = "average",
		choices = {
			{
				text = "Join the riot",
				feedback = {
					"You throw yourself into the chaos!",
					"This is your chance to settle scores!",
					"The adrenaline is pumping. Freedom or death!",
				},
				effects = { Health = -15, Happiness = 10 },
				triggersCombat = true,
			},
			{
				text = "Hide in your cell",
				feedback = {
					"You barricade yourself and wait it out.",
					"The sounds of violence echo through the halls.",
					"Hours pass before order is restored.",
				},
				effects = { Happiness = -5 },
			},
			{
				text = "Help guards restore order",
				feedback = {
					"You side with authority. Risky but potentially rewarding.",
					"Other inmates see you helping guards.",
					"This might help your case... or make you a target.",
				},
				effects = { Happiness = -3 },
			},
		},
	},
	-- Event 2: Riot opportunity
	{
		id = "prison_riot_opportunity",
		title = "🚨 Riot Chaos",
		texts = {
			"In the riot confusion, you have options...",
			"The guards are distracted. What do you do?",
			"Chaos creates opportunity. Choose wisely.",
		},
		effects = {},
		choices = {
			{
				text = "Try to escape",
				feedback = {
					"You make a run for it in the chaos!",
					"Heart pounding, you look for an exit.",
					"This could be your only chance at freedom!",
				},
				effects = { Happiness = 20 },
				triggersEscape = true,
			},
			{
				text = "Settle a score",
				feedback = {
					"You find that inmate who's been making your life miserable.",
					"Time for payback with no witnesses.",
					"This is personal.",
				},
				effects = {},
				triggersCombat = true,
			},
			{
				text = "Protect yourself",
				feedback = {
					"You grab a makeshift weapon and defend your cell.",
					"You'll survive this riot no matter what.",
					"Stay alive. That's all that matters.",
				},
				effects = { Health = -5 },
			},
		},
	},
	-- Event 3: Riot aftermath
	{
		id = "prison_riot_aftermath",
		title = "🏥 Riot Aftermath",
		texts = {
			"The riot is over. Guards are assessing the damage.",
			"Bodies are being carried out. The warden is furious.",
			"A tense calm settles over the prison.",
		},
		effects = { Health = {-10, 0}, Happiness = {-10, -2} },
		choices = {
			{
				text = "Keep quiet about what you saw",
				feedback = {
					"You saw things. Bad things. But you say nothing.",
					"Silence is survival in prison.",
					"What happens in the riot stays in the riot.",
				},
				effects = {},
			},
			{
				text = "Cooperate with investigation",
				feedback = {
					"You tell the warden what you know.",
					"Some inmates will never forgive you for this.",
					"But maybe it helps your case for early release.",
				},
				effects = { Happiness = -10 },
			},
			{
				text = "Seek medical attention",
				feedback = {
					"You got hurt in the chaos and need the infirmary.",
					"The doctor patches you up as best she can.",
					"You'll heal, but the scars will stay.",
				},
				effects = { Health = 10 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRISON SNITCH EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
PrisonEvents.Snitch = {
	-- Event 1: Guard approaches
	{
		id = "prison_snitch_guard",
		title = "🤫 Guard's Offer",
		texts = {
			"A guard pulls you aside. 'I know you see things. Tell me.'",
			"'We can make your life easier if you cooperate,' a guard says.",
			"The warden wants informants. You could be useful.",
		},
		effects = { Happiness = {-5, 5} },
		choices = {
			{
				text = "Agree to inform",
				feedback = {
					"You nod. 'What do you want to know?'",
					"Being a snitch is dangerous but has benefits.",
					"You're now an informant. Watch your back.",
				},
				effects = { Happiness = -5 },
			},
			{
				text = "Give false information",
				feedback = {
					"You tell them something useless but believable.",
					"They seem satisfied. You've bought time.",
					"Playing both sides is a dangerous game.",
				},
				effects = { Smarts = 3 },
			},
			{
				text = "Refuse completely",
				feedback = {
					"'I don't see anything,' you say firmly.",
					"The guard looks disappointed. 'Suit yourself.'",
					"You keep your integrity but lose potential advantages.",
				},
				effects = { Happiness = 3 },
			},
		},
	},
	-- Event 2: Information to share
	{
		id = "prison_snitch_info",
		title = "👀 You Know Something",
		texts = {
			"You witnessed contraband being smuggled. What do you do?",
			"You know who's planning an attack. Speak up?",
			"You have information that guards would pay for.",
		},
		effects = {},
		choices = {
			{
				text = "Report to guards",
				feedback = {
					"You pass the information to your contact.",
					"If anyone finds out, you're dead.",
					"The guards seem pleased. Your privileges improve.",
				},
				effects = { Happiness = 5 },
			},
			{
				text = "Keep it to yourself",
				feedback = {
					"Some things are better left unsaid.",
					"You stay silent and stay alive.",
					"Loyalty to fellow inmates, even if they don't know it.",
				},
				effects = {},
			},
			{
				text = "Sell it to the highest bidder",
				feedback = {
					"Information is currency in prison.",
					"You find someone willing to pay for what you know.",
					"Dangerous, but profitable.",
				},
				effects = { Happiness = 3 },
			},
		},
	},
	-- Event 3: Almost caught
	{
		id = "prison_snitch_caught",
		title = "😱 Snitch Exposed?",
		texts = {
			"Rumors are spreading. Someone thinks you're a snitch.",
			"An inmate corners you. 'You been talking to guards?'",
			"Your informant activities might have been noticed.",
		},
		effects = { Happiness = {-15, -5} },
		triggersCombat = true,
		choices = {
			{
				text = "Deny everything",
				feedback = {
					"'I don't know what you're talking about,' you say calmly.",
					"Your poker face saves you... for now.",
					"They're suspicious but have no proof.",
				},
				effects = { Happiness = -5 },
			},
			{
				text = "Deflect blame",
				feedback = {
					"You point the finger at someone else.",
					"Now that other guy has problems.",
					"Survival means making hard choices.",
				},
				effects = { Happiness = -3 },
			},
			{
				text = "Prepare to fight",
				feedback = {
					"If they want a problem, they'll get one.",
					"You're not going down without a fight.",
					"Time to defend yourself!",
				},
				effects = {},
				triggersCombat = true,
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRISON JOB EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
PrisonEvents.Job = {
	-- Event 1: Kitchen duty
	{
		id = "prison_job_kitchen",
		title = "🍳 Kitchen Duty",
		texts = {
			"You've been assigned to work in the prison kitchen.",
			"Another day cooking slop for hundreds of inmates.",
			"The kitchen is hot, but it's better than sitting in a cell.",
		},
		effects = { Happiness = {2, 5} },
		choices = {
			{
				text = "Work hard",
				feedback = {
					"You cook and clean without complaint.",
					"The guards notice your good work ethic.",
					"Honest work helps pass the time.",
				},
				effects = { Happiness = 5 },
			},
			{
				text = "Steal extra food",
				feedback = {
					"You pocket some extra portions for later.",
					"Contraband food is valuable currency.",
					"Just don't get caught.",
				},
				effects = { Happiness = 3 },
			},
			{
				text = "Slack off",
				feedback = {
					"You do the bare minimum and take frequent breaks.",
					"The supervisor gives you a warning.",
					"You might lose this cushy job.",
				},
				effects = { Happiness = -2 },
			},
		},
	},
	-- Event 2: Laundry
	{
		id = "prison_job_laundry",
		title = "👕 Laundry Room",
		texts = {
			"You spend your work hours in the prison laundry.",
			"The machines drone on as you sort endless clothes.",
			"It's mindless work, but it keeps you busy.",
		},
		effects = { Happiness = {1, 4} },
		choices = {
			{
				text = "Hide contraband in clothes",
				feedback = {
					"You help move items for other inmates.",
					"They'll owe you favors for this.",
					"Risky, but it builds alliances.",
				},
				effects = { Happiness = 5 },
			},
			{
				text = "Just do the job",
				feedback = {
					"You fold clothes and keep your head down.",
					"Nothing exciting, but nothing dangerous either.",
					"Safe and boring. Prison life.",
				},
				effects = { Happiness = 2 },
			},
			{
				text = "Chat with coworkers",
				feedback = {
					"You get to know your fellow workers.",
					"Connections are valuable in here.",
					"You learn some useful information.",
				},
				effects = { Happiness = 3, Smarts = 2 },
			},
		},
	},
	-- Event 3: Yard maintenance
	{
		id = "prison_job_yard",
		title = "🌿 Yard Work",
		texts = {
			"You're assigned to maintain the prison grounds.",
			"Fresh air and sunshine while you work outdoors.",
			"Gardening isn't so bad when you're locked up.",
		},
		effects = { Health = {3, 7}, Happiness = {3, 7} },
		choices = {
			{
				text = "Work enthusiastically",
				feedback = {
					"You take pride in making the yard look nice.",
					"The physical work keeps you fit.",
					"Guards appreciate inmates who work hard.",
				},
				effects = { Health = 7, Happiness = 5 },
			},
			{
				text = "Look for escape routes",
				feedback = {
					"You survey the fences and guard patterns.",
					"Useful information for later perhaps...",
					"Don't be too obvious about it.",
				},
				effects = { Smarts = 5 },
			},
			{
				text = "Find places to hide things",
				feedback = {
					"The yard has good hiding spots for contraband.",
					"You note locations for future use.",
					"A useful discovery.",
				},
				effects = { Smarts = 3 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRISON APPEAL EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
PrisonEvents.Appeal = {
	-- Event 1: Filing appeal
	{
		id = "prison_appeal_file",
		title = "⚖️ Legal Appeal",
		texts = {
			"You're working on your appeal paperwork.",
			"With the help of the law library, you file an appeal.",
			"Your case might have grounds for reconsideration.",
		},
		effects = { Happiness = {5, 15} },
		choices = {
			{
				text = "Hire a real lawyer",
				feedback = {
					"If you have the money, a lawyer improves your chances.",
					"Professional representation makes a difference.",
					"Now you wait for the court's decision.",
				},
				effects = { Happiness = 10 },
				cost = 5000,
			},
			{
				text = "File pro se (yourself)",
				feedback = {
					"You represent yourself with what you've learned.",
					"It's a long shot, but worth trying.",
					"The courts might listen... or might not.",
				},
				effects = { Happiness = 5, Smarts = 5 },
			},
			{
				text = "Ask a jailhouse lawyer",
				feedback = {
					"A fellow inmate who knows the system helps you.",
					"They've helped others. Maybe they can help you.",
					"Your appeal is filed. Hope for the best.",
				},
				effects = { Happiness = 7 },
			},
		},
	},
	-- Event 2: Appeal hearing
	{
		id = "prison_appeal_hearing",
		title = "🏛️ Appeal Hearing",
		texts = {
			"Your appeal is being heard today.",
			"You sit before the parole board with hope in your heart.",
			"This is your chance to argue for freedom.",
		},
		effects = { Happiness = {-10, 20} },
		choices = {
			{
				text = "Express genuine remorse",
				feedback = {
					"You speak from the heart about your crimes.",
					"The board seems moved by your sincerity.",
					"You've done what you can. Now you wait.",
				},
				effects = { Happiness = 15 },
			},
			{
				text = "Focus on rehabilitation",
				feedback = {
					"You highlight your education and good behavior.",
					"Evidence of change is what they want to see.",
					"Your record speaks for itself.",
				},
				effects = { Happiness = 12 },
			},
			{
				text = "Challenge the evidence",
				feedback = {
					"You argue that your conviction was flawed.",
					"The board listens but seems skeptical.",
					"A risky strategy that could backfire.",
				},
				effects = { Happiness = 5, Smarts = 3 },
			},
		},
	},
	-- Event 3: Appeal result
	{
		id = "prison_appeal_result",
		title = "📜 Appeal Decision",
		texts = {
			"The court has made a decision on your appeal.",
			"A letter arrives with news about your case.",
			"Your heart pounds as you read the official document.",
		},
		effects = { Happiness = {-20, 30} },
		choices = {
			{
				text = "Read the decision",
				feedback = {
					"You open the envelope with trembling hands...",
					"Whatever it says, at least you tried.",
					"This moment will change everything.",
				},
				effects = {},
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRISON FIGHT EVENTS (RANDOM YARD ENCOUNTERS)
-- ═══════════════════════════════════════════════════════════════════════════════
PrisonEvents.Fight = {
	-- Event 1: Challenged
	{
		id = "prison_fight_challenge",
		title = "👊 You're Challenged",
		texts = {
			"An inmate steps to you in the yard. 'What you looking at?'",
			"Someone's been spreading rumors about you. Now they want to fight.",
			"A new arrival wants to establish dominance. You're the target.",
		},
		effects = { Health = {-20, 0}, Happiness = {-10, 5} },
		triggersCombat = true,
		combatContext = "prison",
		combatDifficulty = "strong",
		choices = {
			{
				text = "Fight!",
				feedback = {
					"You square up and prepare to throw hands.",
					"In prison, backing down is worse than losing.",
					"Time to show what you're made of!",
				},
				effects = {},
				triggersCombat = true,
			},
			{
				text = "Talk your way out",
				feedback = {
					"'I don't want problems,' you say calmly.",
					"Sometimes words can defuse tension.",
					"He seems to accept your submission... for now.",
				},
				effects = { Happiness = -5 },
			},
			{
				text = "Get guards involved",
				feedback = {
					"You signal for the guards to intervene.",
					"They break it up, but now you look like a snitch.",
					"You're safe today, but tomorrow?",
				},
				effects = { Happiness = -10 },
			},
		},
	},
	-- Event 2: Jumped
	{
		id = "prison_fight_jumped",
		title = "😵 Ambushed!",
		texts = {
			"You turn a corner and several inmates are waiting.",
			"Someone set you up. You walked right into a trap.",
			"'This is for what you did,' they say as they close in.",
		},
		effects = { Health = {-30, -10} },
		triggersCombat = true,
		combatContext = "prison",
		combatDifficulty = "outnumbered",
		choices = {
			{
				text = "Fight them all",
				feedback = {
					"You're outnumbered but you're not going down easy!",
					"Fists fly in every direction.",
					"Even if you lose, you earned respect for fighting back.",
				},
				effects = { Health = -20 },
				triggersCombat = true,
			},
			{
				text = "Try to run",
				feedback = {
					"You bolt for the nearest exit!",
					"Running might save you from worse injuries.",
					"They catch you anyway. It's bad.",
				},
				effects = { Health = -25 },
			},
			{
				text = "Call for help",
				feedback = {
					"You scream for guards to save you.",
					"They arrive just in time to prevent worse damage.",
					"You're in the infirmary now, but you survived.",
				},
				effects = { Health = -15, Happiness = -10 },
			},
		},
	},
	-- Event 3: Protect someone
	{
		id = "prison_fight_protect",
		title = "🛡️ Someone Needs Help",
		texts = {
			"A young inmate is being beaten by a bigger guy.",
			"You witness an unfair fight. Do you intervene?",
			"Someone weaker is getting attacked. What do you do?",
		},
		effects = {},
		triggersCombat = true,
		combatContext = "prison",
		combatDifficulty = "average",
		choices = {
			{
				text = "Step in and help",
				feedback = {
					"'Hey! Pick on someone your own size!'",
					"You jump into the fight to even the odds.",
					"You might make an ally... or an enemy.",
				},
				effects = { Happiness = 5 },
				triggersCombat = true,
			},
			{
				text = "Mind your own business",
				feedback = {
					"It's not your problem. You look away.",
					"The beating continues until guards arrive.",
					"You feel guilty, but you stayed safe.",
				},
				effects = { Happiness = -5 },
			},
			{
				text = "Alert the guards",
				feedback = {
					"You catch a guard's attention and point.",
					"They intervene and stop the assault.",
					"You helped without getting involved directly.",
				},
				effects = { Happiness = 2 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAPPING TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
PrisonEvents.ActivityMapping = {
	["prison_workout"] = "Workout",
	["prison_exercise"] = "Workout",
	["prison_study"] = "Study",
	["prison_library"] = "Study",
	["prison_education"] = "Study",
	["prison_crew"] = "Crew",
	["prison_gang"] = "Crew",
	["prison_riot"] = "Riot",
	["prison_snitch"] = "Snitch",
	["prison_inform"] = "Snitch",
	["prison_job"] = "Job",
	["prison_work"] = "Job",
	["prison_appeal"] = "Appeal",
	["prison_lawyer"] = "Appeal",
	["prison_fight"] = "Fight",
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS - CRITICAL FIX: Now with anti-spam cooldown integration!
-- ═══════════════════════════════════════════════════════════════════════════════
function PrisonEvents.getEventForActivity(activityId, state)
	-- CRITICAL FIX: Check if we can show more events this year
	if state and not PrisonEvents.canShowMoreThisYear(state) then
		return nil, "Maximum prison events reached for this year"
	end
	
	local categoryName = PrisonEvents.ActivityMapping[activityId]
	if not categoryName then
		-- Try partial matching
		for key, cat in pairs(PrisonEvents.ActivityMapping) do
			if string.find(activityId, key) or string.find(key, activityId) then
				categoryName = cat
				break
			end
		end
	end
	
	if not categoryName then
		return nil, "Unknown activity type"
	end
	
	-- CRITICAL FIX: Check cooldown for this category
	if state and not PrisonEvents.canShowCategory(state, categoryName) then
		return nil, "This activity is on cooldown"
	end
	
	local eventList = PrisonEvents[categoryName]
	if not eventList or #eventList == 0 then
		return nil, "No events for this category"
	end
	
	-- CRITICAL FIX: Mark category as shown and increment yearly count
	if state then
		PrisonEvents.markCategoryShown(state, categoryName)
		PrisonEvents.incrementYearlyCount(state)
	end
	
	-- Return random event from category
	return eventList[math.random(1, #eventList)]
end

-- CRITICAL FIX: New function to get event with state validation
function PrisonEvents.getEventWithValidation(activityId, state)
	if not state then
		return PrisonEvents.getEventForActivity(activityId, nil)
	end
	
	-- Reset yearly count if this is a new year
	local currentAge = state.Age or 0
	state._lastPrisonEventAge = state._lastPrisonEventAge or 0
	if currentAge > state._lastPrisonEventAge then
		PrisonEvents.resetYearlyCount(state)
		state._lastPrisonEventAge = currentAge
	end
	
	return PrisonEvents.getEventForActivity(activityId, state)
end

function PrisonEvents.getAllCategories()
	return {"Workout", "Study", "Crew", "Riot", "Snitch", "Job", "Appeal", "Fight"}
end

-- CRITICAL FIX: Reset function for when player leaves prison
function PrisonEvents.resetAllCooldowns(state)
	if state then
		state._prisonEventHistory = {}
		state._prisonEventsThisYear = 0
	end
end

return PrisonEvents
