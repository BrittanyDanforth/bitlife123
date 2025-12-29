--[[
	CareerActivityEvents.lua
	========================
	Comprehensive event templates for career and job-related activities.
	These events give players immersive BitLife-style event cards for all
	work-related interactions and experiences.
	
	Categories:
	- JobInterview: Interview experiences
	- FirstDay: Starting a new job
	- Promotion: Career advancement
	- RaiseNegotiation: Salary discussions
	- WorkProject: Work assignments
	- OfficePolitics: Workplace dynamics
	- WorkTravel: Business trips
	- TrainingEvent: Professional development
	- PerformanceReview: Employee evaluations
	- Resignation: Quitting jobs
	- Firing: Getting terminated
	- Retirement: Career conclusion
--]]

local CareerEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS (CRITICAL FIX: Nil-safe operations)
-- ═══════════════════════════════════════════════════════════════════════════════
local function safeModifyStat(state, stat, amount)
	if state and state.ModifyStat then
		state:ModifyStat(stat, amount)
	elseif state and state.Stats then
		state.Stats[stat] = math.clamp((state.Stats[stat] or 50) + amount, 0, 100)
	elseif state then
		state[stat] = math.clamp((state[stat] or 50) + amount, 0, 100)
	end
end

local function safeAddFeed(state, message)
	if state and state.AddFeed then
		state:AddFeed(message)
	end
end

-- CRITICAL FIX: Check if player is currently employed
local function isEmployed(state)
	if not state then return false end
	
	-- Check CurrentJob
	if state.CurrentJob and state.CurrentJob.id then
		return true
	end
	
	-- Check flags
	local flags = state.Flags or {}
	return flags.employed or flags.has_job or false
end

-- CRITICAL FIX: Check if player can do work activities (must be employed, not in prison)
local function canDoWorkActivities(state)
	if not state then return false end
	
	local flags = state.Flags or {}
	-- Can't work from prison!
	if flags.in_prison or flags.incarcerated or flags.in_jail then
		return false
	end
	
	return isEmployed(state)
end

-- CRITICAL FIX: Check if player is looking for work (for interview events)
local function isJobSeeking(state)
	if not state then return false end
	
	-- Job seekers can be unemployed or looking for new job
	local flags = state.Flags or {}
	if flags.in_prison or flags.incarcerated then
		return false
	end
	
	-- Employed people can also interview for new jobs
	return true
end

-- CRITICAL FIX: Get player's work experience level
local function getExperienceLevel(state)
	if not state then return "entry" end
	
	local careerInfo = state.CareerInfo or {}
	local yearsWorked = careerInfo.yearsInWorkforce or 0
	local promotions = careerInfo.promotions or 0
	
	if promotions >= 3 or yearsWorked >= 10 then
		return "senior"
	elseif promotions >= 1 or yearsWorked >= 3 then
		return "mid"
	end
	
	return "entry"
end

-- CRITICAL FIX: Check if player is old enough to work
local function isWorkingAge(state, minAge)
	local age = state.Age or 0
	return age >= (minAge or 16)
end

-- CRITICAL FIX: Check retirement eligibility
local function canRetire(state)
	if not state then return false end
	local age = state.Age or 0
	return age >= 55 and isEmployed(state)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- JOB INTERVIEW EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CareerEvents.JobInterview = {
	-- CRITICAL FIX: Category-wide eligibility
	eligibility = function(state) return isJobSeeking(state) and isWorkingAge(state, 16) end,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Standard interview
	{
		id = "interview_standard",
		title = "👔 Job Interview",
		texts = {
			"You walk into the interview room. This is your chance!",
			"The interviewer looks up from your resume.",
			"Time to make a great first impression!",
			"Your dream job could be one interview away!",
		},
		effects = { Happiness = {-5, 15}, Smarts = {2, 5} },
		choices = {
			{
				text = "Be confident and prepared",
				feedback = {
					"You answer every question with poise!",
					"Your preparation shows through!",
					"The interviewer seems impressed!",
				},
				effects = { Happiness = 18, Smarts = 5 },
			},
			{
				text = "Show enthusiasm",
				feedback = {
					"Your passion for the role is evident!",
					"Enthusiasm is contagious!",
					"They can see you really want this job!",
				},
				effects = { Happiness = 15 },
			},
			{
				text = "Ask thoughtful questions",
				feedback = {
					"Your questions show you've done research!",
					"Interviewers love curious candidates!",
					"You stand out from other applicants!",
				},
				effects = { Happiness = 12, Smarts = 5 },
			},
			{
				text = "Freeze up nervously",
				feedback = {
					"Your mind goes blank mid-sentence...",
					"The silence is deafening.",
					"Not your best performance.",
				},
				effects = { Happiness = -8 },
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Ace it perfectly!",
				feedback = {
					"⚡ You perform FLAWLESSLY!",
					"⚡ Every answer is PERFECT!",
					"⚡ They're ready to hire you on the spot!",
				},
				effects = { Happiness = 30, Smarts = 10 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				setFlags = { interview_aced = true, job_offer_pending = true },
			},
		},
	},
	-- Event 2: Tough question
	{
		id = "interview_tough_question",
		title = "❓ Tough Interview Question",
		texts = {
			"'Tell me about your greatest weakness...'",
			"'Where do you see yourself in 5 years?'",
			"'Why should we hire you over other candidates?'",
		},
		effects = { Happiness = {-5, 12}, Smarts = {2, 8} },
		choices = {
			{
				text = "Give an honest, thoughtful answer",
				feedback = {
					"Your authenticity resonates!",
					"Being genuine builds trust.",
					"They appreciate your honesty!",
				},
				effects = { Happiness = 12, Smarts = 5 },
			},
			{
				text = "Use a rehearsed response",
				feedback = {
					"Your prepared answer is smooth.",
					"It works, but feels a bit generic.",
					"Safe but not memorable.",
				},
				effects = { Happiness = 5 },
			},
			{
				text = "Turn it into a strength",
				feedback = {
					"You spin the question masterfully!",
					"Impressive interview skills!",
					"That was clever!",
				},
				effects = { Happiness = 15, Smarts = 8 },
			},
		},
	},
	-- Event 3: Panel interview
	{
		id = "interview_panel",
		title = "👥 Panel Interview",
		texts = {
			"You face a panel of five interviewers!",
			"Multiple people will be evaluating you today.",
			"The pressure is on with all eyes on you!",
		},
		effects = { Happiness = {-8, 15}, Smarts = {3, 8} },
		choices = {
			{
				text = "Make eye contact with everyone",
				feedback = {
					"You engage each panel member!",
					"Your presence fills the room!",
					"Confident body language noted!",
				},
				effects = { Happiness = 15, Smarts = 5 },
			},
			{
				text = "Focus on the decision maker",
				feedback = {
					"You identify and impress the key person!",
					"Strategic but noticed by others.",
					"Partially effective.",
				},
				effects = { Happiness = 8, Smarts = 8 },
			},
			{
				text = "Get overwhelmed",
				feedback = {
					"So many faces, so many questions!",
					"You struggle to keep up.",
					"A challenging experience.",
				},
				effects = { Happiness = -8 },
			},
		},
	},
	-- Event 4: Interview success
	{
		id = "interview_success",
		title = "🎉 Job Offer!",
		texts = {
			"'We'd like to offer you the position!'",
			"Your phone rings with great news!",
			"The email says: 'Congratulations!'",
		},
		effects = { Happiness = {25, 40} },
		choices = {
			{
				text = "Accept immediately",
				feedback = {
					"You're hired! Congratulations!",
					"New chapter of your career begins!",
					"You did it!",
				},
				effects = { Happiness = 40 },
			},
			{
				text = "Negotiate salary",
				feedback = {
					"You counter their offer professionally.",
					"They come back with a better number!",
					"Smart negotiation!",
				},
				effects = { Happiness = 38, Smarts = 8 },
			},
			{
				text = "Ask for time to consider",
				feedback = {
					"Taking time to think is wise.",
					"They give you a few days.",
					"Consider your options carefully.",
				},
				effects = { Happiness = 25 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIRST DAY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CareerEvents.FirstDay = {
	-- CRITICAL FIX: Category-wide eligibility - must have just started a job
	eligibility = function(state) 
		return canDoWorkActivities(state) and isWorkingAge(state, 16)
	end,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Starting the job
	{
		id = "firstday_start",
		title = "🌟 First Day at Work!",
		texts = {
			"It's your first day at the new job!",
			"Fresh start, new opportunities!",
			"Time to make a good impression!",
		},
		effects = { Happiness = {10, 25} },
		choices = {
			{
				text = "Arrive early and prepared",
				feedback = {
					"First to arrive, great first impression!",
					"Your new colleagues notice your dedication!",
					"Starting off on the right foot!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Introduce yourself to everyone",
				feedback = {
					"You meet your whole team!",
					"Building relationships from day one!",
					"Friendly and approachable!",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Focus on learning",
				feedback = {
					"You absorb information like a sponge!",
					"So much to learn, but you're ready!",
					"Taking notes and asking questions!",
				},
				effects = { Happiness = 20, Smarts = 5 },
			},
		},
	},
	-- Event 2: Meeting the boss
	{
		id = "firstday_boss",
		title = "👔 Meeting Your Boss",
		texts = {
			"Your new supervisor wants to meet you.",
			"The boss calls you into their office.",
			"Time for a first one-on-one with management!",
		},
		effects = { Happiness = {5, 18} },
		choices = {
			{
				text = "Express gratitude for the opportunity",
				feedback = {
					"Your appreciation is noted!",
					"The boss seems pleased with your attitude.",
					"Positive first interaction!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Share your career goals",
				feedback = {
					"Your ambition is evident!",
					"The boss sees potential in you.",
					"Goal-oriented employee identified!",
				},
				effects = { Happiness = 15, Smarts = 3 },
			},
			{
				text = "Ask how you can contribute immediately",
				feedback = {
					"Eager to get started!",
					"The boss appreciates your proactive attitude.",
					"Ready to work!",
				},
				effects = { Happiness = 16 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROMOTION EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CareerEvents.Promotion = {
	-- CRITICAL FIX: Category-wide eligibility - must be employed
	eligibility = canDoWorkActivities,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Getting promoted
	{
		id = "promotion_receive",
		title = "📈 Promotion!",
		texts = {
			"You're being promoted!",
			"Your hard work has paid off!",
			"Moving up the corporate ladder!",
		},
		effects = { Happiness = {25, 40} },
		choices = {
			{
				text = "Accept graciously",
				feedback = {
					"Congratulations on your new role!",
					"You've earned this advancement!",
					"New title, new responsibilities!",
				},
				effects = { Happiness = 40 },
			},
			{
				text = "Negotiate the package",
				feedback = {
					"Promotion plus better compensation!",
					"Know your worth!",
					"Smart negotiation!",
				},
				effects = { Happiness = 38, Smarts = 5 },
			},
			{
				text = "Ask about growth path",
				feedback = {
					"Where can this lead?",
					"Planning for continued advancement.",
					"Always thinking ahead!",
				},
				effects = { Happiness = 35, Smarts = 8 },
			},
		},
	},
	-- Event 2: Passed over
	{
		id = "promotion_passed",
		title = "😔 Passed Over",
		texts = {
			"Someone else got the promotion you wanted...",
			"Your name wasn't called for advancement.",
			"Disappointment in the meeting room.",
		},
		effects = { Happiness = {-20, -5} },
		choices = {
			{
				text = "Ask for feedback",
				feedback = {
					"Understanding why helps you improve.",
					"The feedback is constructive.",
					"Knowledge for next time.",
				},
				effects = { Happiness = -8, Smarts = 5 },
			},
			{
				text = "Work harder",
				feedback = {
					"Use this as motivation!",
					"Determined to earn it next time.",
					"Turning disappointment into drive!",
				},
				effects = { Happiness = -5 },
			},
			{
				text = "Consider other options",
				feedback = {
					"Maybe this company isn't for you.",
					"Time to update that resume?",
					"Evaluating your career path.",
				},
				effects = { Happiness = -10 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- RAISE NEGOTIATION EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CareerEvents.RaiseNegotiation = {
	-- CRITICAL FIX: Category-wide eligibility - must be employed
	eligibility = canDoWorkActivities,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Asking for a raise
	{
		id = "raise_ask",
		title = "💰 Asking for a Raise",
		texts = {
			"You've scheduled a meeting to discuss compensation.",
			"It's time to talk about your salary.",
			"You deserve more than you're making!",
		},
		effects = { Happiness = {-5, 20} },
		choices = {
			{
				text = "Present your accomplishments",
				feedback = {
					"Your track record speaks for itself!",
					"Data-driven negotiation!",
					"They can't argue with results!",
				},
				effects = { Happiness = 20 },
			},
			{
				text = "Compare to market rates",
				feedback = {
					"You've done your research!",
					"Industry standards support your request.",
					"Informed negotiation!",
				},
				effects = { Happiness = 18, Smarts = 5 },
			},
			{
				text = "Appeal emotionally",
				feedback = {
					"Personal circumstances considered.",
					"They sympathize but business is business.",
					"Partial success at best.",
				},
				effects = { Happiness = 5 },
			},
		},
	},
	-- Event 2: Raise approved
	{
		id = "raise_approved",
		title = "✅ Raise Approved!",
		texts = {
			"Your salary increase has been approved!",
			"The company values your contributions!",
			"More money in your pocket!",
		},
		effects = { Happiness = {20, 35} },
		choices = {
			{
				text = "Thank your manager",
				feedback = {
					"Gratitude goes a long way!",
					"Maintaining good relationships.",
					"Professional and appreciated!",
				},
				effects = { Happiness = 32 },
			},
			{
				text = "Celebrate privately",
				feedback = {
					"Quiet satisfaction!",
					"Your efforts paid off!",
					"Financial goals getting closer!",
				},
				effects = { Happiness = 35 },
			},
			{
				text = "Immediately plan next raise",
				feedback = {
					"Always striving for more!",
					"Ambitious financial planning.",
					"Never settling!",
				},
				effects = { Happiness = 25, Smarts = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- WORK PROJECT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CareerEvents.WorkProject = {
	-- CRITICAL FIX: Category-wide eligibility - must be employed
	eligibility = canDoWorkActivities,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Big project assignment
	{
		id = "project_assigned",
		title = "📋 Big Project Assigned",
		texts = {
			"You've been assigned to lead an important project!",
			"A major initiative needs your skills.",
			"This is your chance to shine!",
		},
		effects = { Happiness = {8, 22}, Smarts = {5, 12} },
		choices = {
			{
				text = "Dive in enthusiastically",
				feedback = {
					"Your energy is contagious!",
					"The team rallies behind your leadership!",
					"Full steam ahead!",
				},
				effects = { Happiness = 22, Smarts = 8 },
			},
			{
				text = "Plan meticulously",
				feedback = {
					"Your detailed planning pays off!",
					"Nothing is overlooked!",
					"Organization is key to success!",
				},
				effects = { Happiness = 18, Smarts = 12 },
			},
			{
				text = "Delegate effectively",
				feedback = {
					"Good leaders know how to delegate!",
					"The right people on the right tasks.",
					"Management skills showcased!",
				},
				effects = { Happiness = 20, Smarts = 10 },
			},
		},
	},
	-- Event 2: Project success
	{
		id = "project_success",
		title = "🏆 Project Success!",
		texts = {
			"Your project was a huge success!",
			"Leadership notices your achievement!",
			"The results exceeded expectations!",
		},
		effects = { Happiness = {22, 38}, Smarts = {5, 10} },
		choices = {
			{
				text = "Share credit with team",
				feedback = {
					"Your generosity is noted!",
					"Team players are valued!",
					"Building loyalty and respect!",
				},
				effects = { Happiness = 35 },
			},
			{
				text = "Document your achievement",
				feedback = {
					"Added to your performance review!",
					"Evidence for future advancement!",
					"Career highlights growing!",
				},
				effects = { Happiness = 30, Smarts = 10 },
			},
			{
				text = "Ask for more responsibility",
				feedback = {
					"Strike while the iron is hot!",
					"Ambitious and ready for more!",
					"Career acceleration!",
				},
				effects = { Happiness = 32, Smarts = 5 },
			},
		},
	},
	-- Event 3: Project struggles
	{
		id = "project_struggle",
		title = "😰 Project Struggles",
		texts = {
			"Your project is facing major challenges...",
			"Things aren't going as planned.",
			"The deadline is approaching and progress is slow.",
		},
		effects = { Happiness = {-15, 5}, Smarts = {3, 8} },
		choices = {
			{
				text = "Work overtime to fix it",
				feedback = {
					"Late nights and hard work!",
					"Determination to succeed!",
					"Pushing through the difficulty!",
				},
				effects = { Happiness = 5, Health = -5, Smarts = 5 },
			},
			{
				text = "Ask for help",
				feedback = {
					"No shame in needing support!",
					"Fresh perspectives help!",
					"Collaborative problem-solving!",
				},
				effects = { Happiness = -5, Smarts = 8 },
			},
			{
				text = "Reset expectations",
				feedback = {
					"Being realistic about outcomes.",
					"Communication is key.",
					"Managing expectations properly.",
				},
				effects = { Happiness = -10, Smarts = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- OFFICE POLITICS EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CareerEvents.OfficePolitics = {
	-- CRITICAL FIX: Category-wide eligibility - must be employed
	eligibility = canDoWorkActivities,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Office gossip
	{
		id = "politics_gossip",
		title = "🗣️ Office Gossip",
		texts = {
			"Colleagues are gossiping near the water cooler.",
			"You hear whispers about changes at the company.",
			"Office politics are heating up.",
		},
		effects = { Happiness = {-5, 5}, Smarts = {2, 5} },
		choices = {
			{
				text = "Stay out of it",
				feedback = {
					"You focus on your work.",
					"Not getting involved is smart.",
					"Drama-free zone!",
				},
				effects = { Happiness = 5 },
			},
			{
				text = "Listen carefully",
				feedback = {
					"Information is power.",
					"You learn interesting things.",
					"Staying informed without participating.",
				},
				effects = { Happiness = 2, Smarts = 5 },
			},
			{
				text = "Join the conversation",
				feedback = {
					"You're now part of the inner circle.",
					"But be careful what you say...",
					"Office politics can be dangerous.",
				},
				effects = { Happiness = -5, Smarts = 3 },
			},
		},
	},
	-- Event 2: Taking credit
	{
		id = "politics_credit",
		title = "😠 Someone Took Credit",
		texts = {
			"A coworker took credit for your idea!",
			"Your work is being attributed to someone else.",
			"Injustice in the workplace!",
		},
		effects = { Happiness = {-18, 0} },
		choices = {
			{
				text = "Address it directly",
				feedback = {
					"You confront the situation professionally.",
					"Truth comes out eventually.",
					"Standing up for yourself!",
				},
				effects = { Happiness = 0 },
			},
			{
				text = "Let it go this time",
				feedback = {
					"Pick your battles.",
					"You'll make sure it doesn't happen again.",
					"Learning experience.",
				},
				effects = { Happiness = -12 },
			},
			{
				text = "Document everything going forward",
				feedback = {
					"Creating a paper trail.",
					"Protecting yourself in the future.",
					"Fool me once...",
				},
				effects = { Happiness = -8, Smarts = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PERFORMANCE REVIEW EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CareerEvents.PerformanceReview = {
	-- CRITICAL FIX: Category-wide eligibility - must be employed
	eligibility = canDoWorkActivities,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Annual review
	{
		id = "review_annual",
		title = "📊 Annual Performance Review",
		texts = {
			"It's time for your annual performance review.",
			"Your manager is ready to discuss your year.",
			"Let's see how you measured up.",
		},
		effects = { Happiness = {-5, 20}, Smarts = {3, 8} },
		choices = {
			{
				text = "Highlight accomplishments",
				feedback = {
					"You remind them of your wins!",
					"Self-advocacy is important!",
					"Your achievements are recognized!",
				},
				effects = { Happiness = 18, Smarts = 5 },
			},
			{
				text = "Accept feedback gracefully",
				feedback = {
					"Constructive criticism helps you grow.",
					"Professional and mature attitude.",
					"Room for improvement is okay!",
				},
				effects = { Happiness = 12, Smarts = 8 },
			},
			{
				text = "Set new goals together",
				feedback = {
					"Collaborative goal-setting!",
					"Aligned with your manager.",
					"Clear path forward!",
				},
				effects = { Happiness = 15, Smarts = 5 },
			},
		},
	},
	-- Event 2: Excellent review
	{
		id = "review_excellent",
		title = "⭐ Excellent Review!",
		texts = {
			"Your performance review was outstanding!",
			"'Exceeds expectations' across the board!",
			"Your hard work is recognized!",
		},
		effects = { Happiness = {22, 35} },
		choices = {
			{
				text = "Feel proud",
				feedback = {
					"You've earned this recognition!",
					"All that effort paid off!",
					"Celebrating your success!",
				},
				effects = { Happiness = 35 },
			},
			{
				text = "Ask about advancement",
				feedback = {
					"Perfect time to discuss career growth!",
					"The door is open!",
					"Strategic career planning!",
				},
				effects = { Happiness = 28, Smarts = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- WORK TRAVEL EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CareerEvents.WorkTravel = {
	-- CRITICAL FIX: Category-wide eligibility - must be employed
	eligibility = canDoWorkActivities,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Business trip
	{
		id = "travel_business",
		title = "✈️ Business Trip",
		texts = {
			"You're traveling for work!",
			"Company business in another city.",
			"Professional travel opportunities!",
		},
		effects = { Happiness = {8, 22}, Smarts = {3, 8} },
		choices = {
			{
				text = "Focus on business",
				feedback = {
					"All work, no play - but productive!",
					"Meetings go well!",
					"Professional goals achieved!",
				},
				effects = { Happiness = 15, Smarts = 8 },
			},
			{
				text = "Network at events",
				feedback = {
					"Making valuable connections!",
					"Industry contacts acquired!",
					"Expanding your professional network!",
				},
				effects = { Happiness = 18, Smarts = 5 },
			},
			{
				text = "Explore after hours",
				feedback = {
					"Work-life balance on the road!",
					"You experience the new city!",
					"Memories and meetings!",
				},
				effects = { Happiness = 22 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- RESIGNATION EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CareerEvents.Resignation = {
	-- CRITICAL FIX: Category-wide eligibility - must be employed to resign
	eligibility = canDoWorkActivities,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Quitting
	{
		id = "resign_quit",
		title = "👋 Resigning",
		texts = {
			"You've decided to leave your job.",
			"Time to hand in your resignation.",
			"Moving on to new opportunities.",
		},
		effects = { Happiness = {-5, 15} },
		choices = {
			{
				text = "Two weeks notice",
				feedback = {
					"Professional and courteous!",
					"Leaving on good terms.",
					"Bridge not burned!",
				},
				effects = { Happiness = 12 },
			},
			{
				text = "Negotiate exit",
				feedback = {
					"Maybe a better offer to stay?",
					"Seeing what they'll do to keep you.",
					"Playing your cards.",
				},
				effects = { Happiness = 15, Smarts = 5 },
			},
			{
				text = "Quit dramatically",
				feedback = {
					"You've always wanted to do this!",
					"Satisfying but potentially risky.",
					"Mic drop moment!",
				},
				effects = { Happiness = 10 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- RETIREMENT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CareerEvents.Retirement = {
	-- CRITICAL FIX: Category-wide eligibility - must be old enough and employed
	eligibility = canRetire,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true, retired = true },
	-- Event 1: Retiring
	{
		id = "retire_end",
		title = "🏖️ Retirement!",
		texts = {
			"Your career has come to an end!",
			"Time to enjoy your golden years!",
			"Decades of work behind you!",
		},
		effects = { Happiness = {25, 45} },
		choices = {
			{
				text = "Celebrate the milestone",
				feedback = {
					"Retirement party!",
					"Colleagues honor your contributions!",
					"A career well-lived!",
				},
				effects = { Happiness = 45 },
			},
			{
				text = "Look forward to freedom",
				feedback = {
					"No more alarm clocks!",
					"Your time is finally your own!",
					"Freedom awaits!",
				},
				effects = { Happiness = 40 },
			},
			{
				text = "Plan your retirement activities",
				feedback = {
					"Travel, hobbies, relaxation!",
					"So much to do with your time!",
					"Best years ahead!",
				},
				effects = { Happiness = 42 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAPPING TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
CareerEvents.ActivityMapping = {
	["interview"] = "JobInterview",
	["job_interview"] = "JobInterview",
	["apply"] = "JobInterview",
	["first_day"] = "FirstDay",
	["new_job"] = "FirstDay",
	["start_job"] = "FirstDay",
	["promotion"] = "Promotion",
	["promote"] = "Promotion",
	["raise"] = "RaiseNegotiation",
	["salary"] = "RaiseNegotiation",
	["negotiate"] = "RaiseNegotiation",
	["project"] = "WorkProject",
	["work_project"] = "WorkProject",
	["assignment"] = "WorkProject",
	["politics"] = "OfficePolitics",
	["office"] = "OfficePolitics",
	["gossip"] = "OfficePolitics",
	["review"] = "PerformanceReview",
	["evaluation"] = "PerformanceReview",
	["business_trip"] = "WorkTravel",
	["work_travel"] = "WorkTravel",
	["resign"] = "Resignation",
	["quit"] = "Resignation",
	["retire"] = "Retirement",
	["retirement"] = "Retirement",
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ADDITIONAL HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

-- CRITICAL FIX: Enhanced event retrieval with state-aware eligibility
function CareerEvents.getEventForActivity(activityId, state)
	local categoryName = CareerEvents.ActivityMapping[activityId]
	if not categoryName then
		-- Try partial matching
		for key, cat in pairs(CareerEvents.ActivityMapping) do
			if string.find(activityId:lower(), key) or string.find(key, activityId:lower()) then
				categoryName = cat
				break
			end
		end
	end
	
	if not categoryName then
		return nil
	end
	
	local eventList = CareerEvents[categoryName]
	if not eventList or #eventList == 0 then
		return nil
	end
	
	-- CRITICAL FIX: Check category-wide eligibility if state provided
	if state and eventList.eligibility and not eventList.eligibility(state) then
		return nil
	end
	
	-- CRITICAL FIX: Check category-wide blocked flags
	if state and eventList.blockedByFlags and state.Flags then
		for flag, _ in pairs(eventList.blockedByFlags) do
			if state.Flags[flag] then
				return nil -- Blocked by flag
			end
		end
	end
	
	-- Filter to valid events only
	local validEvents = {}
	for i, event in ipairs(eventList) do
		if type(event) == "table" and event.id then
			local valid = true
			
			-- Check event-level conditions
			if event.condition and state and not event.condition(state) then
				valid = false
			end
			
			-- Check event-level blocked flags
			if valid and event.blockedByFlags and state and state.Flags then
				for flag, _ in pairs(event.blockedByFlags) do
					if state.Flags[flag] then
						valid = false
						break
					end
				end
			end
			
			if valid then
				table.insert(validEvents, event)
			end
		end
	end
	
	if #validEvents == 0 then
		return nil
	end
	
	-- Return random event from valid events
	local selectedEvent = validEvents[math.random(1, #validEvents)]
	
	-- CRITICAL FIX: Process texts array if present
	if selectedEvent.texts and #selectedEvent.texts > 0 then
		local eventCopy = {}
		for k, v in pairs(selectedEvent) do
			eventCopy[k] = v
		end
		eventCopy.text = eventCopy.texts[math.random(#eventCopy.texts)]
		return eventCopy
	end
	
	return selectedEvent
end

-- CRITICAL FIX: Apply effects safely
function CareerEvents.applyEffects(state, effects)
	if not effects or not state then return state end
	
	for stat, value in pairs(effects) do
		local change = 0
		if type(value) == "table" then
			change = math.random(value[1], value[2])
		else
			change = value
		end
		
		if stat == "Money" then
			state.Money = math.max(0, (state.Money or 0) + change)
		elseif state.Stats then
			state.Stats[stat] = math.clamp((state.Stats[stat] or 50) + change, 0, 100)
		else
			state[stat] = math.clamp((state[stat] or 50) + change, 0, 100)
		end
	end
	
	return state
end

function CareerEvents.getAllCategories()
	return {"JobInterview", "FirstDay", "Promotion", "RaiseNegotiation", "WorkProject", "OfficePolitics", "PerformanceReview", "WorkTravel", "Resignation", "Retirement"}
end

return CareerEvents
