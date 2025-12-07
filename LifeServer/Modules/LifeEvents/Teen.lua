--[[
	Teen Events (Ages 13-17)
	High school, identity, relationships, early choices
]]

local Teen = {}

Teen.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- STAGE TRANSITION
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "stage_transition_teen",
		title = "Welcome to High School",
		emoji = "🎓",
		text = "You're starting high school! Everything feels bigger and more intense.",
		question = "What's your approach to high school?",
		minAge = 13, maxAge = 14,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		-- Set education status when entering high school
		onComplete = function(state)
			state.EducationData = state.EducationData or {}
			state.EducationData.Status = "enrolled"
			state.EducationData.Institution = "High School"
			state.EducationData.Level = "high_school"
			state.EducationData.Duration = 4 -- CRITICAL: High school takes 4 years (ages 14-18)
			state.EducationData.Progress = 0 -- Start at 0% progress
			state.Flags = state.Flags or {}
			state.Flags.in_high_school = true
			state.Flags.is_teenager = true
		end,
		choices = {
			{
				text = "Focus on academics",
				effects = { Smarts = 5 },
				setFlags = { academic_path = true, in_high_school = true },
				feedText = "You're determined to excel academically.",
			},
			{
				text = "Join lots of activities",
				effects = { Happiness = 5, Health = 2 },
				setFlags = { extracurricular_focus = true, in_high_school = true },
				feedText = "You want the full high school experience!",
			},
			{
				text = "Focus on making friends",
				effects = { Happiness = 5 },
				setFlags = { social_path = true, in_high_school = true },
				feedText = "Your social life is your priority.",
			},
			{
				text = "Keep a low profile",
				effects = { Smarts = 2 },
				setFlags = { introvert_path = true, in_high_school = true },
				feedText = "You prefer to observe and stay under the radar.",
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ACADEMICS & SCHOOL
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "class_selection",
		title = "Choosing Your Classes",
		emoji = "📋",
		text = "It's time to select your elective classes for next year.",
		question = "What interests you most?",
		minAge = 14, maxAge = 16,
		cooldown = 2,
		choices = {
			{ text = "Advanced Math & Science", effects = { Smarts = 5 }, setFlags = { stem_track = true }, hintCareer = "tech", feedText = "You're challenging yourself with advanced STEM classes." },
			{ text = "Creative Writing & Literature", effects = { Smarts = 3, Happiness = 3 }, setFlags = { humanities_track = true }, hintCareer = "creative", feedText = "You're exploring the power of words." },
			{ text = "Business & Economics", effects = { Smarts = 3, Money = 10 }, setFlags = { business_track = true }, hintCareer = "finance", feedText = "You're learning how the business world works." },
			{ text = "Art & Music", effects = { Happiness = 5, Looks = 2 }, setFlags = { arts_track = true }, hintCareer = "creative", feedText = "You're developing your artistic talents." },
			{ text = "Vocational/Technical", effects = { Smarts = 3, Health = 2 }, setFlags = { vocational_track = true }, hintCareer = "trades", feedText = "You're learning practical, hands-on skills." },
		},
	},
	{
		id = "group_project",
		title = "Group Project Drama",
		emoji = "📝",
		text = "You're assigned a group project, but one member isn't pulling their weight.",
		question = "How do you handle it?",
		minAge = 13, maxAge = 17,
		baseChance = 0.7,
		cooldown = 2,
		choices = {
			{ text = "Do their share yourself", effects = { Smarts = 3, Happiness = -3, Health = -2 }, setFlags = { takes_on_too_much = true }, feedText = "You did all the work. Good grade, but you're exhausted." },
			{ text = "Talk to them directly", effects = { Smarts = 2, Happiness = 3 }, setFlags = { direct_communicator = true }, feedText = "You addressed the issue head-on." },
			{ text = "Tell the teacher", effects = { Smarts = 2 }, setFlags = { follows_rules = true }, feedText = "The teacher adjusted the grades accordingly." },
			{ text = "Accept a lower grade", effects = { Happiness = -2, Smarts = -1 }, feedText = "The project suffered, but you avoided conflict." },
		},
	},
	{
		id = "academic_pressure",
		title = "Under Pressure",
		emoji = "😰",
		text = "A big exam is coming up. You're feeling the pressure.",
		question = "How do you cope?",
		minAge = 14, maxAge = 17,
		baseChance = 0.6,
		cooldown = 2,
		choices = {
			{ text = "Study intensively", effects = { Smarts = 5, Health = -3, Happiness = -2 }, feedText = "You crammed hard. Exhausted but prepared." },
			{ text = "Form a study group", effects = { Smarts = 4, Happiness = 2 }, setFlags = { collaborative = true }, feedText = "Studying with friends made it bearable." },
			{ text = "Take breaks to de-stress", effects = { Smarts = 2, Happiness = 3, Health = 2 }, setFlags = { balanced_approach = true }, feedText = "You maintained balance. Healthy studying!" },
			{ text = "Procrastinate until the last minute", effects = { Smarts = 1, Happiness = -3 }, setFlags = { procrastinator = true }, feedText = "You crammed the night before. Stressful!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- SOCIAL LIFE & RELATIONSHIPS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "high_school_romance",
		title = "Feelings Developing",
		emoji = "💘",
		text = "Someone you like seems to be interested in you too.",
		question = "What do you do?",
		minAge = 14, maxAge = 17,
		baseChance = 0.7,
		cooldown = 2,
		choices = {
			{ text = "Ask them out", effects = { Happiness = 8 }, setFlags = { romantically_active = true, has_partner = true, dating = true }, feedText = "You made a move! Heart pounding." },
			{ text = "Drop hints and wait", effects = { Happiness = 2 }, feedText = "You're playing it cool, waiting for them to act." },
			{ text = "Focus on being friends first", effects = { Happiness = 3 }, setFlags = { takes_it_slow = true }, feedText = "You're building a foundation of friendship." },
			{ text = "I'm not ready for dating", effects = { Happiness = 2 }, feedText = "You're focused on other things right now." },
		},
	},
	{
		id = "party_invitation",
		title = "The Big Party",
		emoji = "🎉",
		text = "You're invited to a party at a popular kid's house. Your parents might not approve.",
		question = "What do you do?",
		minAge = 15, maxAge = 17,
		baseChance = 0.7,
		cooldown = 2,
		choices = {
			{ text = "Sneak out and go", effects = { Happiness = 5, Health = -2 }, setFlags = { rebellious = true, sneaks_out = true }, feedText = "You snuck out! The party was wild." },
			{ text = "Ask parents for permission", effects = { Happiness = 3 }, setFlags = { respectful = true }, feedText = "You asked, and they said yes (with rules)." },
			{ text = "Say you're staying at a friend's", effects = { Happiness = 4 }, setFlags = { bends_truth = true }, feedText = "A white lie got you to the party." },
			{ text = "Skip it", effects = { Happiness = -2 }, feedText = "You stayed home. FOMO is real." },
		},
	},
	{
		id = "clique_pressure",
		title = "Finding Your Group",
		emoji = "👥",
		text = "Different social groups are forming. Where do you fit in?",
		question = "Which group do you gravitate toward?",
		minAge = 13, maxAge = 16,
		oneTime = true,
		choices = {
			{ text = "The studious overachievers", effects = { Smarts = 5 }, setFlags = { nerd_group = true }, feedText = "You found your tribe among the academic crowd." },
			{ text = "The athletes and jocks", effects = { Health = 5, Happiness = 3 }, setFlags = { jock_group = true }, hintCareer = "sports", feedText = "You fit in with the athletic crowd." },
			{ text = "The creative/artsy types", effects = { Happiness = 5, Looks = 2 }, setFlags = { artsy_group = true }, hintCareer = "creative", feedText = "You found kindred creative spirits." },
			{ text = "The rebels and misfits", effects = { Happiness = 3 }, setFlags = { rebel_group = true }, feedText = "You don't follow the mainstream." },
			{ text = "A mix of everyone", effects = { Happiness = 3, Smarts = 2 }, setFlags = { social_butterfly = true }, feedText = "You move between groups easily." },
		},
	},
	{
		id = "friendship_drama",
		title = "Best Friend Betrayal",
		emoji = "💔",
		text = "You found out your best friend has been talking behind your back.",
		question = "How do you react?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 3,
		requiresFlags = { has_best_friend = true },
		choices = {
			{ text = "Confront them", effects = { Happiness = 3 }, setFlags = { confrontational = true }, feedText = "You had it out. The truth came to light." },
			{ text = "End the friendship", effects = { Happiness = -5 }, setFlags = { holds_grudges = true, has_best_friend = false }, feedText = "You cut them off. It hurts." },
			{ text = "Try to understand why", effects = { Smarts = 2, Happiness = 2 }, setFlags = { empathetic = true }, feedText = "You tried to see their perspective." },
			{ text = "Forgive and move on", effects = { Happiness = 3 }, setFlags = { forgiving = true }, feedText = "You chose to forgive. Friendships are complicated." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- IDENTITY & PERSONAL GROWTH
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "identity_question",
		title = "Who Am I?",
		emoji = "🪞",
		text = "You've been thinking a lot about who you really are.",
		question = "What aspect of yourself are you exploring?",
		minAge = 14, maxAge = 17,
		oneTime = true,
		choices = {
			{ text = "My values and beliefs", effects = { Smarts = 3, Happiness = 3 }, setFlags = { philosophical = true }, feedText = "You're questioning what you believe in." },
			{ text = "My future career", effects = { Smarts = 3 }, setFlags = { career_focused = true }, feedText = "You're thinking seriously about your future." },
			{ text = "My style and appearance", effects = { Looks = 5, Happiness = 3 }, setFlags = { style_conscious = true }, feedText = "You're developing your personal style." },
			{ text = "My relationships with others", effects = { Happiness = 3 }, setFlags = { socially_aware = true }, feedText = "You're learning about how you relate to people." },
		},
	},
	{
		id = "mental_health_awareness",
		title = "Tough Times",
		emoji = "🌧️",
		text = "You've been feeling down lately. More than usual.",
		question = "How do you cope?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		choices = {
			{ text = "Talk to a trusted adult", effects = { Happiness = 5, Health = 3 }, setFlags = { seeks_help = true }, feedText = "Opening up helped. You're not alone." },
			{ text = "Confide in a friend", effects = { Happiness = 3 }, feedText = "Your friend listened and supported you." },
			{ text = "Try to push through alone", effects = { Happiness = -3, Health = -2 }, setFlags = { struggles_alone = true }, feedText = "You tried to handle it alone. It's hard." },
			{ text = "Express through creative outlet", effects = { Happiness = 4, Smarts = 2 }, setFlags = { creative_coping = true }, feedText = "Art, music, or writing helped you process feelings." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- EARLY WORK & MONEY
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "first_job_offer",
		title = "Your First Job",
		emoji = "💼",
		text = "A local business is hiring teenagers for part-time work.",
		question = "Will you apply?",
		minAge = 15, maxAge = 17,
		baseChance = 0.7,
		cooldown = 3,
		-- CRITICAL FIX: Only block by ACTUAL employment flags, not experience flags
		blockedByFlags = { employed = true, has_job = true, has_teen_job = true },
		requiresNoJob = true,
		choices = {
			{ text = "Work at a fast food place", effects = { Money = 200, Health = -2, Happiness = -1 }, setFlags = { has_teen_job = true, fast_food_experience = true }, feedText = "You got a job flipping burgers. Money incoming!" },
			{ text = "Work at a retail store", effects = { Money = 180, Happiness = 1 }, setFlags = { has_teen_job = true, retail_experience = true }, feedText = "You're working retail. Learning about customers." },
			{ text = "Tutor younger kids", effects = { Money = 150, Smarts = 3 }, setFlags = { has_teen_job = true, tutoring_experience = true }, hintCareer = "education", feedText = "You're tutoring others. Teaching is rewarding!" },
			{ text = "I don't want a job yet", effects = { Happiness = 2 }, feedText = "You're focusing on school and fun for now." },
		},
	},
	{
		id = "entrepreneurship",
		title = "Side Hustle",
		emoji = "💡",
		text = "You have an idea for making money on your own.",
		question = "What's your business?",
		minAge = 14, maxAge = 17,
		baseChance = 0.5,
		cooldown = 3,
		choices = {
			{ text = "Lawn care / yard work", effects = { Money = 150, Health = 3 }, setFlags = { entrepreneur = true }, hintCareer = "business", feedText = "You started a lawn care service!" },
			{ text = "Selling crafts online", effects = { Money = 100, Happiness = 3 }, setFlags = { entrepreneur = true, creative_business = true }, hintCareer = "creative", feedText = "You're selling your creations online!" },
			{ text = "Tech support for neighbors", effects = { Money = 120, Smarts = 3 }, setFlags = { entrepreneur = true, tech_savvy = true }, hintCareer = "tech", feedText = "You're the neighborhood tech expert!" },
			{ text = "Social media management", effects = { Money = 130, Smarts = 2 }, setFlags = { entrepreneur = true, social_media_savvy = true }, hintCareer = "marketing", feedText = "You're managing social media for local businesses!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- FUTURE PLANNING
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "college_prep",
		title = "Planning Your Future",
		emoji = "🎯",
		text = "College applications are looming. What's your plan?",
		question = "What path are you considering?",
		minAge = 16, maxAge = 17,
		oneTime = true,
		-- CRITICAL FIX: Use blockedByFlags instead of requiresFlags with false value
		-- Only show if haven't graduated yet (planning stage)
		blockedByFlags = { graduated_high_school = true, high_school_graduate = true },
		choices = {
			{
				text = "Aim for a top university",
				effects = { Smarts = 3, Happiness = -2 },
				setFlags = { college_bound = true, ambitious = true, plans_for_college = true },
				feedText = "You're working hard for a prestigious school.",
			},
			{
				text = "State school is fine",
				effects = { Smarts = 2, Happiness = 2 },
				setFlags = { college_bound = true, practical = true, plans_for_college = true },
				feedText = "You're taking a practical approach to higher ed.",
			},
			{
				text = "Community college first",
				effects = { Smarts = 1, Money = 50 },
				setFlags = { college_bound = true, economical = true, plans_for_community_college = true },
				feedText = "You're saving money with community college.",
			},
			{
				text = "Trade school / vocational",
				effects = { Smarts = 2 },
				setFlags = { trade_school_bound = true },
				hintCareer = "trades",
				feedText = "You're planning to learn a skilled trade.",
			},
			{
				text = "Skip college, start working",
				effects = { Money = 100 },
				setFlags = { no_college = true, workforce_bound = true },
				feedText = "You're ready to enter the workforce directly.",
			},
		},
	},
	{
		id = "graduation_high_school",
		title = "High School Graduation",
		emoji = "🎓",
		text = "You're graduating from high school!",
		question = "How do you feel about your high school experience?",
		-- CRITICAL FIX: Changed minAge to 17 only (player is still in "teen" stage at 17)
		-- At age 18, player is in "young_adult" stage which doesn't pull "teen" events
		-- The event should trigger during the age 17 → 18 transition
		minAge = 17, maxAge = 17,
		-- CRITICAL FIX: Added category = "milestones" to ensure this event triggers
		-- from the milestones pool which is included in ALL life stages
		category = "milestones",
		oneTime = true,
		priority = "high",
		isMilestone = true,
		-- onComplete runs after ANY choice - this ensures Education is always updated
		onComplete = function(state, choice, eventDef, outcome)
			-- Set education level
			state.Education = "high_school"
			-- Set graduated flag
			state.Flags = state.Flags or {}
			state.Flags.graduated_high_school = true
			state.Flags.high_school_graduate = true
			-- Update education data
			if state.EducationData then
				state.EducationData.Status = "completed"
				state.EducationData.Level = "high_school"
				state.EducationData.Institution = "High School"
			end
		end,
		choices = {
			{
				text = "Best years of my life so far",
				effects = { Happiness = 10 },
				setFlags = { loved_high_school = true, graduated_high_school = true, high_school_graduate = true },
				feedText = "You graduated with amazing memories!",
			},
			{
				text = "Glad it's over",
				effects = { Happiness = 5 },
				setFlags = { graduated_high_school = true, high_school_graduate = true },
				feedText = "High school wasn't your favorite, but you made it!",
			},
			{
				text = "Nervous about what's next",
				effects = { Happiness = 2, Smarts = 2 },
				setFlags = { graduated_high_school = true, high_school_graduate = true },
				feedText = "The future is uncertain but exciting.",
			},
			{
				text = "I learned a lot about myself",
				effects = { Happiness = 5, Smarts = 5 },
				setFlags = { self_aware = true, graduated_high_school = true, high_school_graduate = true },
				feedText = "High school was a journey of self-discovery.",
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- EXTRACURRICULAR
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "sports_varsity",
		title = "Varsity Tryouts",
		emoji = "🏅",
		text = "Varsity sports tryouts are coming up. You've been practicing hard.",
		question = "Which sport?",
		minAge = 14, maxAge = 17,
		baseChance = 0.5,
		cooldown = 2,
		requiresStats = { Health = { min = 50 } },
		choices = {
			{ text = "Football", effects = { Health = 5, Happiness = 5 }, setFlags = { varsity_athlete = true, plays_football = true }, hintCareer = "sports", feedText = "You made the football team!" },
			{ text = "Basketball", effects = { Health = 5, Happiness = 5 }, setFlags = { varsity_athlete = true, plays_basketball = true }, hintCareer = "sports", feedText = "You made the basketball team!" },
			{ text = "Soccer", effects = { Health = 5, Happiness = 5 }, setFlags = { varsity_athlete = true, plays_soccer = true }, hintCareer = "sports", feedText = "You made the soccer team!" },
			{ text = "Track & Field", effects = { Health = 7, Happiness = 5 }, setFlags = { varsity_athlete = true, runs_track = true }, hintCareer = "sports", feedText = "You joined the track team!" },
			{ text = "Not really into sports", effects = { }, feedText = "Organized sports aren't your thing." },
		},
	},
	{
		id = "school_play",
		title = "Drama Production",
		emoji = "🎭",
		text = "The school is putting on a big play. Auditions are open.",
		question = "Will you participate?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 2,
		choices = {
			{ text = "Audition for lead role", effects = { Happiness = 8, Looks = 3 }, setFlags = { theater_kid = true, lead_actor = true }, hintCareer = "entertainment", feedText = "You went for the lead! Bold move!" },
			{ text = "Join the ensemble", effects = { Happiness = 5, Looks = 2 }, setFlags = { theater_kid = true }, hintCareer = "entertainment", feedText = "You're part of the cast!" },
			{ text = "Work on tech/backstage", effects = { Smarts = 3, Happiness = 3 }, setFlags = { tech_crew = true }, feedText = "You're part of the crew. Essential work!" },
			{ text = "Just watch the show", effects = { Happiness = 2 }, feedText = "You'll support from the audience." },
		},
	},
	{
		id = "volunteer_opportunity",
		title = "Giving Back",
		emoji = "🤝",
		text = "There's an opportunity to volunteer in your community.",
		question = "What cause calls to you?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 2,
		choices = {
			{ text = "Animal shelter", effects = { Happiness = 5 }, setFlags = { volunteer = true, animal_lover = true }, hintCareer = "veterinary", feedText = "You're helping animals at the shelter!" },
			{ text = "Food bank", effects = { Happiness = 5, Health = 2 }, setFlags = { volunteer = true, community_minded = true }, feedText = "You're helping feed those in need." },
			{ text = "Tutoring younger kids", effects = { Happiness = 3, Smarts = 3 }, setFlags = { volunteer = true, teacher_at_heart = true }, hintCareer = "education", feedText = "You're helping younger kids learn!" },
			{ text = "Environmental cleanup", effects = { Happiness = 4, Health = 2 }, setFlags = { volunteer = true, environmentalist = true }, feedText = "You're helping clean up the planet!" },
			{ text = "I'm too busy right now", effects = { }, feedText = "Volunteering will have to wait." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ADDITIONAL TEEN EVENTS - AAA QUALITY EXPANSION
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Renamed from "caught_cheating" to avoid ID conflict with Relationships.lua
	-- That event is about cheating on partners, this is about cheating on tests
	{
		id = "caught_cheating_test",
		title = "Caught Cheating",
		emoji = "📝",
		text = "A teacher suspects you of cheating on a test.",
		question = "What really happened?",
		minAge = 13, maxAge = 17,
		baseChance = 0.3,
		cooldown = 4,

		choices = {
			{ text = "I actually cheated - own up", effects = { Happiness = -5, Smarts = -3 }, setFlags = { academic_probation = true, honest = true }, feedText = "You admitted it. There are consequences, but at least you were honest." },
			{ text = "I cheated but deny it", effects = { Happiness = -2, Smarts = -5 }, setFlags = { academic_probation = true, liar = true }, feedText = "You denied it, but they have evidence. Double trouble." },
			{ text = "I didn't cheat - defend myself", effects = { Happiness = 5, Smarts = 3 }, setFlags = { falsely_accused = true }, feedText = "You proved your innocence! That was stressful." },
			{ text = "Someone copied off me without my knowledge", effects = { Happiness = -2 }, feedText = "You got caught in someone else's cheating scandal." },
		},
	},
	{
		id = "prom_invitation",
		title = "Prom Season",
		emoji = "💃",
		text = "Prom is coming up! The biggest dance of the year.",
		question = "What's your prom plan?",
		minAge = 16, maxAge = 18,
		oneTime = true,
		-- CRITICAL FIX: Random promposal outcomes
		choices = {
			{
				text = "Ask my crush with a big promposal",
				effects = { Money = -100 },
				feedText = "You planned an elaborate promposal...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local happiness = (state.Stats and state.Stats.Happiness) or 50
					local roll = math.random()
					local successChance = 0.50 + (looks / 200) + (happiness / 300)
					if state.Flags and (state.Flags.romantically_active or state.Flags.has_partner) then
						successChance = successChance + 0.20
					end
					if roll < successChance then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.prom_date = true
						state.Flags.romantic_gesture = true
						state:AddFeed("💃 They said YES! Your promposal was epic!")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("💃 They said no... Rejection stings, but you're brave for trying.")
					end
				end,
			},
			{
				text = "Go with friends as a group",
				effects = { Happiness = 6 },
				setFlags = { prom_group = true },
				feedText = "Prom with friends was so much fun!",
			},
			{
				text = "Wait and hope someone asks me",
				effects = {},
				feedText = "You waited hopefully...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local askedChance = 0.30 + (looks / 150)
					if state.Flags and (state.Flags.social_butterfly or state.Flags.popular) then
						askedChance = askedChance + 0.20
					end
					if roll < askedChance then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Looks", 2)
						state.Flags = state.Flags or {}
						state.Flags.prom_date = true
						state:AddFeed("💃 Someone asked you to prom! What a moment!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("💃 Nobody asked... You ended up going with friends instead.")
					end
				end,
			},
			{
				text = "Skip prom entirely",
				effects = { Happiness = -2, Money = 200 },
				setFlags = { skipped_prom = true },
				feedText = "You decided prom wasn't worth the hype.",
			},
			{
				text = "Go alone and own it",
				effects = { Happiness = 5 },
				setFlags = { independent = true },
				feedText = "You proved you don't need a date to have a great time!",
			},
		},
	},
	{
		id = "car_accident_passenger",
		title = "Scary Ride",
		emoji = "🚗",
		text = "You're in a car with a friend who's driving recklessly.",
		question = "What do you do?",
		minAge = 15, maxAge = 17,
		baseChance = 0.3,
		cooldown = 5,

		choices = {
			{ text = "Tell them to slow down", effects = { Happiness = 3, Health = 2 }, setFlags = { assertive = true }, feedText = "You spoke up and they listened. Smart move." },
			{ text = "Say nothing - don't want to seem uncool", effects = { Health = -3, Happiness = -2 }, setFlags = { peer_pressure_weak = true }, feedText = "You stayed quiet. Nothing bad happened, but it was scary." },
			{ text = "Demand they pull over, you're getting out", effects = { Happiness = 4, Health = 5 }, setFlags = { values_safety = true }, feedText = "You prioritized your safety. Good decision." },
			{ text = "There's an accident", effects = { Health = -15, Happiness = -10 }, setFlags = { car_accident_survivor = true }, feedText = "The car crashed. You survived but it was traumatic." },
		},
	},
	{
		id = "social_media_fame",
		title = "Going Viral",
		emoji = "📱",
		text = "A video or post you made is going viral!",
		question = "What kind of viral moment is it?",
		minAge = 13, maxAge = 17,
		baseChance = 0.2,
		cooldown = 5,
		requiresFlags = { social_online = true },

		choices = {
			{ text = "A funny video everyone loves", effects = { Happiness = 10, Looks = 2 }, setFlags = { social_media_famous = true }, hintCareer = "entertainment", feedText = "You're internet famous! Everyone at school has seen it!" },
			{ text = "An embarrassing moment", effects = { Happiness = -8, Looks = -3 }, setFlags = { embarrassed_online = true }, feedText = "This is mortifying. The whole school saw it." },
			{ text = "A talent showcase", effects = { Happiness = 8, Smarts = 2 }, setFlags = { recognized_talent = true }, hintCareer = "creative", feedText = "Your talent got discovered! People are impressed." },
			{ text = "A controversial opinion", effects = { Happiness = -3 }, setFlags = { controversial_online = true }, feedText = "People have strong opinions about your post..." },
		},
	},
	{
		id = "first_heartbreak",
		title = "Heartbreak",
		emoji = "💔",
		text = "Your first real relationship just ended.",
		question = "How do you cope with the breakup?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		requiresFlags = { romantically_active = true },

		choices = {
			{ text = "Cry it out and lean on friends", effects = { Happiness = -5 }, setFlags = { emotional_processor = true }, feedText = "It hurts, but your friends are there for you." },
			{ text = "Try to win them back", effects = { Happiness = -8, Looks = -2 }, setFlags = { clingy = true }, feedText = "The pleading didn't work. It made things worse." },
			{ text = "Pretend you're fine", effects = { Happiness = -6, Health = -2 }, setFlags = { suppresses_emotions = true }, feedText = "You're bottling up your feelings. Not healthy." },
			{ text = "Channel it into productivity", effects = { Happiness = -2, Smarts = 5 }, setFlags = { motivated_by_pain = true }, feedText = "You used the energy to focus on yourself." },
			{ text = "Move on quickly to someone new", effects = { Happiness = 3 }, setFlags = { rebounds_fast = true }, feedText = "The best way to get over someone is to get under... homework. Lots of homework." },
		},
	},
	{
		-- CRITICAL FIX: Was god-mode - player picked why they got detention!
		-- Now reason is random, player chooses how to handle it
		id = "detention",
		title = "Detention",
		emoji = "📚",
		text = "The teacher handed you a detention slip. After school today.",
		question = "How do you handle this?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 2,

		choices = {
			{ 
				text = "Accept it and show up", 
				effects = { },
				feedText = "You showed up to detention...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 25 then
						-- Talked back
						state.Flags.defiant = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", -2)
						end
						if state.AddFeed then
							state:AddFeed("📚 Detention for talking back to a teacher. Worth it? Maybe.")
						end
					elseif roll <= 50 then
						-- Late
						state.Flags.chronically_late = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", -3)
						end
						if state.AddFeed then
							state:AddFeed("📚 Detention for being late too many times. Set more alarms!")
						end
					elseif roll <= 75 then
						-- Phone
						if state.ModifyStat then
							state:ModifyStat("Happiness", -2)
						end
						if state.AddFeed then
							state:AddFeed("📚 Detention for using your phone in class. Busted!")
						end
					else
						-- Made a friend in detention
						state.Flags.detention_buddy = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", 2)
						end
						if state.AddFeed then
							state:AddFeed("📚 Detention wasn't so bad - you made a friend there!")
						end
					end
				end,
			},
			{ text = "Skip detention", effects = { Happiness = 3 }, setFlags = { skipped_detention = true }, feedText = "You skipped detention. Might come back to bite you..." },
			{ text = "Get your parents to get you out", effects = { Happiness = 1 }, feedText = "Your parents called the school. They got you out... this time." },
		},
	},
	{
		-- CRITICAL FIX: Was god-mode - player picked summer romance outcome!
		-- Now outcome is random based on player choice
		id = "summer_love",
		title = "Summer Romance",
		emoji = "☀️",
		text = "You met someone special over summer vacation. They live in another town.",
		question = "Do you want to try making it work?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 2,

		choices = {
			{ 
				text = "Yes! Try long distance", 
				effects = { },
				feedText = "You wanted to make it work...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 30 then
						-- It works out!
						state.Flags.has_partner = true
						state.Flags.summer_love = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", 10)
						end
						if state.AddFeed then
							state:AddFeed("☀️ Your summer romance turned into something real!")
						end
					elseif roll <= 70 then
						-- Fizzles out
						state.Flags.long_distance_failed = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", -5)
						end
						if state.AddFeed then
							state:AddFeed("☀️ Long distance was too hard. It fizzled out.")
						end
					else
						-- They ghost you
						if state.ModifyStat then
							state:ModifyStat("Happiness", -8)
						end
						if state.AddFeed then
							state:AddFeed("☀️ They stopped responding to your texts...")
						end
					end
				end,
			},
			{ text = "No, let it be a summer memory", effects = { Happiness = 4 }, setFlags = { nostalgic = true }, feedText = "Some things are meant to be a beautiful memory." },
		},
	},
	{
		id = "peer_pressure_substances",
		title = "Sketchy Offer",
		emoji = "⚠️",
		text = "Someone at a party offers you something sketchy. They say it'll make you 'feel different.'",
		question = "What do you do?",
		minAge = 14, maxAge = 17,
		baseChance = 0.3,
		cooldown = 4,

		choices = {
			{ text = "Firmly say no and leave", effects = { Happiness = 5, Health = 3 }, setFlags = { resists_peer_pressure = true }, feedText = "You made a smart choice. You left the party." },
			{ text = "Make an excuse and walk away", effects = { Happiness = 3, Health = 2 }, feedText = "You avoided the situation without making a scene." },
			{ text = "Try it once", effects = { Health = -10, Happiness = 3 }, setFlags = { made_bad_choice = true }, feedText = "You tried it. You felt weird afterward. This could lead down a bad path." },
			{ text = "Call parents to pick you up", effects = { Happiness = 2, Health = 3 }, setFlags = { trusts_parents = true }, feedText = "Your parents came to get you. They're proud you called." },
		},
	},
	{
		id = "college_tour",
		title = "College Visit",
		emoji = "🎓",
		text = "Your family takes you on a college tour.",
		question = "What kind of school appeals to you?",
		minAge = 15, maxAge = 17,
		baseChance = 0.6,
		cooldown = 2,

		choices = {
			{ text = "Big university with lots of options", effects = { Happiness = 4, Smarts = 2 }, setFlags = { wants_big_school = true }, feedText = "You loved the energy of a big campus!" },
			{ text = "Small college with tight community", effects = { Happiness = 5, Smarts = 2 }, setFlags = { wants_small_school = true }, feedText = "You prefer a more personal learning environment." },
			{ text = "Prestigious Ivy League type", effects = { Smarts = 4, Happiness = -2 }, setFlags = { ivy_aspirations = true }, feedText = "You're aiming high! The pressure is real." },
			{ text = "Local community college", effects = { Happiness = 3, Money = 100 }, setFlags = { practical_choice = true }, feedText = "Staying close to home and saving money makes sense." },
			{ text = "Not interested in college", effects = { Happiness = 2 }, setFlags = { no_college = true }, feedText = "College isn't for everyone. You have other plans." },
		},
	},
	{
		id = "driving_test",
		title = "The Driving Test",
		emoji = "🚙",
		text = "It's time for your driver's license road test! The examiner is watching your every move.",
		question = "How do you approach the test?",
		minAge = 16, maxAge = 17,
		oneTime = true,

		-- CRITICAL FIX: Random outcome based on choice + stats, not player-picked result!
		choices = {
			{ 
				text = "Stay calm and focused", 
				effects = {}, 
				feedText = "You took a deep breath and focused...",
				onResolve = function(state)
					-- Better chance with smarts and good_driver flag
					local baseChance = 0.65
					local smarts = state.Stats and state.Stats.Smarts or 50
					local bonus = (smarts - 50) / 100 -- +/- 0.5 based on smarts
					if state.Flags and state.Flags.good_driver then bonus = bonus + 0.15 end
					if state.Flags and state.Flags.nervous_driver then bonus = bonus - 0.1 end
					
					if math.random() < (baseChance + bonus) then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.has_license = true
						state.Flags.drivers_license = true
						state:AddFeed("🚗 You passed the driving test! You're licensed!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🚗 You failed the driving test. Hit a cone. Try again next time.")
					end
				end,
			},
			{ 
				text = "Rush through it nervously", 
				effects = {},
				feedText = "Your nerves got the better of you...",
				onResolve = function(state)
					-- Lower chance when rushing
					local baseChance = 0.35
					local smarts = state.Stats and state.Stats.Smarts or 50
					local bonus = (smarts - 50) / 150
					
					if math.random() < (baseChance + bonus) then
						state:ModifyStat("Happiness", 7)
						state.Flags = state.Flags or {}
						state.Flags.has_license = true
						state.Flags.drivers_license = true
						state:AddFeed("🚗 Somehow you passed despite being nervous! Licensed driver!")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.nervous_driver = true
						state:AddFeed("🚗 You were too nervous and failed. The examiner was not impressed.")
					end
				end,
			},
			{ 
				text = "Study the rules beforehand", 
				effects = { Smarts = 2 },
				feedText = "You prepared thoroughly...",
				onResolve = function(state)
					-- Best chance - well prepared
					local baseChance = 0.80
					local smarts = state.Stats and state.Stats.Smarts or 50
					local bonus = (smarts - 50) / 100
					if state.Flags and state.Flags.good_driver then bonus = bonus + 0.1 end
					
					if math.random() < (baseChance + bonus) then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.has_license = true
						state.Flags.drivers_license = true
						state.Flags.good_driver = true
						state:AddFeed("🚗 Perfect score! Your preparation paid off. Licensed to drive!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🚗 Despite preparing, you made a mistake. Failed, but you'll get it next time.")
					end
				end,
			},
			{ 
				text = "Reschedule - not ready yet", 
				effects = { Happiness = -2 },
				feedText = "You decided you're not ready yet. That's okay.",
			},
		},
	},
	{
		id = "scholarship_opportunity",
		title = "Scholarship Application",
		emoji = "📜",
		text = "You have a chance to apply for a major scholarship. Deadline is this week!",
		question = "How do you approach the application?",
		minAge = 16, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		-- CRITICAL FIX: Random scholarship outcome based on effort + stats
		choices = {
			{
				text = "Go all out - essays, recommendations, the works",
				effects = { Smarts = 2, Happiness = -3 },
				feedText = "You poured your heart into the application...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.35 + (smarts / 150)
					if state.Flags and state.Flags.academic_path then successChance = successChance + 0.15 end
					if roll < successChance then
						state.Money = (state.Money or 0) + 5000
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.scholarship_winner = true
						state:AddFeed("📜 You won the scholarship! $5,000 for college!")
					elseif roll < successChance + 0.25 then
						state.Money = (state.Money or 0) + 1500
						state:ModifyStat("Happiness", 6)
						state:AddFeed("📜 Honorable mention - partial scholarship awarded!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📜 Despite your effort, you didn't win. Competition was tough.")
					end
				end,
			},
			{
				text = "Put in a solid effort",
				effects = { Smarts = 1 },
				feedText = "You did your best within reason...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.20 + (smarts / 200)
					if roll < successChance then
						state.Money = (state.Money or 0) + 3000
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.scholarship_winner = true
						state:AddFeed("📜 You won a scholarship! Nice!")
					elseif roll < successChance + 0.25 then
						state.Money = (state.Money or 0) + 800
						state:ModifyStat("Happiness", 4)
						state:AddFeed("📜 Small scholarship awarded! Better than nothing.")
					else
						state:AddFeed("📜 Didn't win this time. Keep trying!")
					end
				end,
			},
			{
				text = "Barely try on the application",
				effects = {},
				feedText = "You rushed through it last minute...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.05 then -- 5% lucky win
						state.Money = (state.Money or 0) + 2000
						state:ModifyStat("Happiness", 8)
						state:AddFeed("📜 Somehow you won! Pure luck!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📜 Predictably rejected. Half-hearted effort shows.")
					end
				end,
			},
			{ text = "Don't bother applying", effects = { }, feedText = "You missed the opportunity entirely." },
		},
	},
	{
		id = "caught_with_something",
		title = "Caught Red-Handed",
		emoji = "😰",
		text = "Your parents catch you with something you shouldn't have!",
		question = "How do you handle the confrontation?",
		minAge = 14, maxAge = 17,
		baseChance = 0.2,
		cooldown = 5,

		choices = {
			{ text = "Lie about it", effects = { Happiness = -3 }, setFlags = { lies_to_parents = true }, feedText = "They didn't believe you. Now you're grounded AND they don't trust you." },
			{ text = "Own up to it honestly", effects = { Happiness = -5 }, setFlags = { honest_with_parents = true }, feedText = "You faced the consequences. Grounded, but at least you were honest." },
			{ text = "Blame it on friends", effects = { Happiness = -2 }, setFlags = { blames_others = true }, feedText = "Throwing friends under the bus? Not cool." },
			{ text = "It was a misunderstanding", effects = { Happiness = 5 }, feedText = "Plot twist: it was actually nothing bad. False alarm!" },
		},
	},
	{
		id = "online_gaming_addiction",
		title = "Gaming All Night",
		emoji = "🎮",
		text = "You've been staying up way too late playing online games.",
		question = "How is it affecting you?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 2,
		requiresFlags = { gamer = true },

		choices = {
			{ text = "Made amazing online friends", effects = { Happiness = 6 }, setFlags = { online_friends = true }, feedText = "You met some great people from around the world!" },
			{ text = "Grades are slipping badly", effects = { Smarts = -5, Happiness = 3 }, setFlags = { gaming_addiction = true }, feedText = "School is suffering because of gaming..." },
			{ text = "Found a healthy balance", effects = { Happiness = 4, Smarts = 2 }, setFlags = { balanced_gamer = true }, feedText = "You learned to manage your time between games and life." },
			{ text = "Parents took away the games", effects = { Happiness = -6, Health = 3 }, feedText = "No more games. Your sleep schedule is better though." },
		},
	},
	{
		id = "school_rivalry",
		title = "Rivalry Week",
		emoji = "🏆",
		text = "The big game against your school's rival is this week!",
		question = "How do you show your school spirit?",
		minAge = 13, maxAge = 17,
		baseChance = 0.6,
		cooldown = 2,

		choices = {
			{ text = "Go all out with face paint and cheering", effects = { Happiness = 7 }, setFlags = { school_spirit = true }, feedText = "You were the loudest fan in the stands!" },
			{ text = "Play in the big game", effects = { Health = 3, Happiness = 8 }, setFlags = { varsity_athlete = true }, hintCareer = "sports", feedText = "You played your heart out! What a game!" },
			{ text = "Don't really care about sports", effects = { Happiness = 1 }, feedText = "School spirit isn't really your thing." },
			{ text = "Prank the rival school", effects = { Happiness = 6, Smarts = -2 }, setFlags = { prankster = true }, feedText = "The prank was legendary! But also kinda risky." },
		},
	},
	{
		id = "body_image_struggle",
		title = "Mirror Struggles",
		emoji = "🪞",
		text = "You're having a hard time with how you look.",
		question = "How do you cope with body image issues?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,

		choices = {
			{ text = "Start working out healthily", effects = { Health = 8, Happiness = 4, Looks = 3 }, setFlags = { fitness_focused = true }, feedText = "You started a healthy exercise routine!" },
			{ text = "Talk to someone about it", effects = { Happiness = 5, Health = 2 }, setFlags = { seeks_help = true }, feedText = "Opening up helped you feel better about yourself." },
			{ text = "Obsess over appearance", effects = { Happiness = -5, Health = -3, Looks = 2 }, setFlags = { body_dysmorphia = true }, feedText = "The obsession is becoming unhealthy..." },
			{ text = "Learn to accept yourself", effects = { Happiness = 8 }, setFlags = { self_accepting = true }, feedText = "You learned that you're perfect as you are." },
		},
	},
	{
		id = "senioritis",
		title = "Senioritis Hits",
		emoji = "😴",
		text = "It's your senior year and motivation is... lacking.",
		question = "How do you handle senioritis?",
		minAge = 17, maxAge = 18,
		baseChance = 0.7,
		cooldown = 3,

		choices = {
			{ text = "Coast through - already got into college", effects = { Smarts = -3, Happiness = 5 }, setFlags = { senioritis = true }, feedText = "You're doing the bare minimum. Living the dream!" },
			{ text = "Stay focused until the end", effects = { Smarts = 4, Happiness = -2 }, setFlags = { disciplined = true }, feedText = "You pushed through. Strong finish!" },
			{ text = "Skip class more often", effects = { Smarts = -5, Happiness = 4 }, setFlags = { skips_class = true }, feedText = "You've been MIA a lot. The attendance office is calling." },
			{ text = "Focus on fun senior activities", effects = { Happiness = 8 }, setFlags = { senior_memories = true }, feedText = "You made the most of your last year!" },
		},
	},
	{
		id = "caught_sneaking_out",
		title = "The Great Escape... Failed",
		emoji = "🌙",
		text = "You tried to sneak out at night but got caught!",
		question = "What were you trying to do?",
		minAge = 14, maxAge = 17,
		baseChance = 0.3,
		cooldown = 4,

		choices = {
			{ text = "Meet up with friends", effects = { Happiness = -4 }, setFlags = { grounded = true }, feedText = "Caught by mom on the way out. Grounded for a month." },
			{ text = "Go to a party", effects = { Happiness = -6 }, setFlags = { grounded = true, party_animal = true }, feedText = "You're in big trouble. Worth it? Debatable." },
			{ text = "See a romantic interest", effects = { Happiness = -5 }, setFlags = { grounded = true, romantic = true }, feedText = "Caught climbing out the window. So embarrassing." },
			{ text = "Just wanted some alone time", effects = { Happiness = -3 }, setFlags = { grounded = true }, feedText = "You just wanted to stargaze. They didn't believe you." },
		},
	},
	{
		id = "ap_exam_stress",
		title = "AP Exam Season",
		emoji = "📖",
		text = "Advanced Placement exams are coming up. The pressure is intense.",
		question = "How do you prepare?",
		minAge = 15, maxAge = 17,
		baseChance = 0.5,
		cooldown = 2,
		requiresFlags = { academic_path = true },

		choices = {
			{ text = "Study obsessively", effects = { Smarts = 7, Health = -4, Happiness = -3 }, setFlags = { ap_scholar = true }, feedText = "You aced the exams! But at what cost to your health?" },
			{ text = "Form a study group", effects = { Smarts = 5, Happiness = 3 }, feedText = "Studying with friends made it bearable and effective!" },
			{ text = "Cram the night before", effects = { Smarts = 3, Health = -3 }, setFlags = { procrastinator = true }, feedText = "Last-minute cramming. You scraped by." },
			{ text = "Accept that it's just one test", effects = { Happiness = 4, Smarts = 2 }, setFlags = { keeps_perspective = true }, feedText = "You kept perspective. Did well enough." },
		},
	},
	{
		id = "friend_moving_away",
		title = "Best Friend Moving Away",
		emoji = "😢",
		text = "Your best friend just told you they're moving to another state.",
		question = "How do you handle this news?",
		minAge = 13, maxAge = 17,
		baseChance = 0.2,
		cooldown = 5,
		requiresFlags = { has_best_friend = true },

		choices = {
			{ text = "Promise to stay in touch forever", effects = { Happiness = -4 }, setFlags = { long_distance_friendship = true }, feedText = "Distance doesn't end real friendships." },
			{ text = "Throw them a going-away party", effects = { Happiness = 3, Money = -50 }, feedText = "You gave them an amazing send-off!" },
			{ text = "Pretend you don't care", effects = { Happiness = -6 }, setFlags = { hides_feelings = true }, feedText = "You're heartbroken but hiding it." },
			{ text = "Make plans to visit each other", effects = { Happiness = 2 }, feedText = "You're already planning summer visits!" },
		},
	},
	{
		id = "youtube_channel",
		title = "Starting a Channel",
		emoji = "📹",
		text = "You're thinking about starting a YouTube channel or streaming.",
		question = "What kind of content do you make?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,

		choices = {
			{ text = "Gaming content", effects = { Happiness = 5, Smarts = 2 }, setFlags = { content_creator = true, gaming_content = true }, hintCareer = "entertainment", feedText = "You started streaming your gameplay!" },
			{ text = "Vlogs and lifestyle", effects = { Happiness = 6, Looks = 2 }, setFlags = { content_creator = true, vlogger = true }, hintCareer = "entertainment", feedText = "People love following your life!" },
			{ text = "Educational/tutorial content", effects = { Smarts = 5, Happiness = 4 }, setFlags = { content_creator = true, educator = true }, hintCareer = "education", feedText = "You're teaching people online!" },
			{ text = "Comedy and entertainment", effects = { Happiness = 7 }, setFlags = { content_creator = true, comedian = true }, hintCareer = "entertainment", feedText = "Making people laugh is your thing!" },
			{ text = "Too much effort", effects = { Happiness = 1 }, feedText = "You decided not to pursue content creation." },
		},
	},
	{
		id = "stood_up",
		title = "Stood Up",
		emoji = "💔",
		text = "You got all dressed up for a date, but they never showed.",
		question = "How do you react?",
		minAge = 14, maxAge = 17,
		baseChance = 0.2,
		cooldown = 4,

		choices = {
			{ text = "Feel humiliated and cry", effects = { Happiness = -8, Looks = -2 }, feedText = "That really hurt. You deserved better." },
			{ text = "Confront them later", effects = { Happiness = -3 }, setFlags = { confrontational = true }, feedText = "You demanded an explanation. It was awkward." },
			{ text = "Go enjoy yourself anyway", effects = { Happiness = 3 }, setFlags = { independent = true }, feedText = "Their loss! You had fun by yourself." },
			{ text = "Vent to friends about it", effects = { Happiness = 2 }, feedText = "Your friends made you feel better about the whole thing." },
		},
	},
	{
		id = "car_first_drive",
		title = "First Time Behind the Wheel",
		emoji = "🚗",
		text = "Your parent is teaching you to drive for the first time! They look nervous.",
		question = "How do you approach your first lesson?",
		minAge = 15, maxAge = 16,
		oneTime = true,

		-- CRITICAL FIX: Random outcome based on stats, not player choice!
		choices = {
			{ 
				text = "Listen carefully to instructions", 
				effects = {},
				feedText = "You paid close attention...",
				onResolve = function(state)
					local baseChance = 0.70
					local smarts = state.Stats and state.Stats.Smarts or 50
					local bonus = (smarts - 50) / 100
					
					if math.random() < (baseChance + bonus) then
						state:ModifyStat("Happiness", 7)
						state:ModifyStat("Smarts", 2)
						state.Flags = state.Flags or {}
						state.Flags.good_driver = true
						state:AddFeed("🚗 You're a natural! Driving came easily to you.")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🚗 It was shaky, but you didn't crash. More practice needed!")
					end
				end,
			},
			{ 
				text = "Get overconfident behind the wheel", 
				effects = {},
				feedText = "You felt like you already knew what you were doing...",
				onResolve = function(state)
					local baseChance = 0.30 -- risky approach
					
					if math.random() < baseChance then
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.confident_driver = true
						state:AddFeed("🚗 Your confidence paid off! Smooth first drive.")
					else
						state:ModifyStat("Happiness", -5)
						state:ModifyStat("Health", -2)
						state.Flags = state.Flags or {}
						state.Flags.nervous_driver = true
						state:AddFeed("🚗 You almost hit a mailbox! Your parent is stressed. That was scary!")
					end
				end,
			},
			{ 
				text = "Feel too nervous to try", 
				effects = {},
				feedText = "You were hesitant to take the wheel...",
				onResolve = function(state)
					local baseChance = 0.50
					
					if math.random() < baseChance then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🚗 Your parent encouraged you. You did okay despite the nerves!")
					else
						state:ModifyStat("Happiness", -3)
						state.Flags = state.Flags or {}
						state.Flags.nervous_driver = true
						state:AddFeed("🚗 You were too anxious. Maybe driving school would help.")
					end
				end,
			},
			{ 
				text = "Ask to go to driving school instead", 
				effects = { Money = -200 },
				setFlags = { driving_school = true },
				feedText = "You signed up for professional driving lessons.",
			},
		},
	},
}

return Teen
