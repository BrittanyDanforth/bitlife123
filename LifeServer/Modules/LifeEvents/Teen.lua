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
		choices = {
			{ text = "Focus on academics", effects = { Smarts = 5 }, setFlags = { academic_path = true }, feedText = "You're determined to excel academically." },
			{ text = "Join lots of activities", effects = { Happiness = 5, Health = 2 }, setFlags = { extracurricular_focus = true }, feedText = "You want the full high school experience!" },
			{ text = "Focus on making friends", effects = { Happiness = 5 }, setFlags = { social_path = true }, feedText = "Your social life is your priority." },
			{ text = "Keep a low profile", effects = { Smarts = 2 }, setFlags = { introvert_path = true }, feedText = "You prefer to observe and stay under the radar." },
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
		choices = {
			{ text = "Aim for a top university", effects = { Smarts = 3, Happiness = -2 }, setFlags = { college_bound = true, ambitious = true }, feedText = "You're working hard for a prestigious school." },
			{ text = "State school is fine", effects = { Smarts = 2, Happiness = 2 }, setFlags = { college_bound = true, practical = true }, feedText = "You're taking a practical approach to higher ed." },
			{ text = "Community college first", effects = { Smarts = 1, Money = 50 }, setFlags = { college_bound = true, economical = true }, feedText = "You're saving money with community college." },
			{ text = "Trade school / vocational", effects = { Smarts = 2 }, setFlags = { trade_school_bound = true }, hintCareer = "trades", feedText = "You're planning to learn a skilled trade." },
			{ text = "Skip college, start working", effects = { Money = 100 }, setFlags = { no_college = true }, feedText = "You're ready to enter the workforce directly." },
		},
	},
	{
		id = "graduation_high_school",
		title = "High School Graduation",
		emoji = "🎓",
		text = "You're graduating from high school!",
		question = "How do you feel about your high school experience?",
		minAge = 17, maxAge = 18,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		choices = {
			{ text = "Best years of my life so far", effects = { Happiness = 10 }, setFlags = { loved_high_school = true }, feedText = "You graduated with amazing memories!" },
			{ text = "Glad it's over", effects = { Happiness = 5 }, feedText = "High school wasn't your favorite, but you made it!" },
			{ text = "Nervous about what's next", effects = { Happiness = 2, Smarts = 2 }, feedText = "The future is uncertain but exciting." },
			{ text = "I learned a lot about myself", effects = { Happiness = 5, Smarts = 5 }, setFlags = { self_aware = true }, feedText = "High school was a journey of self-discovery." },
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
}

return Teen
