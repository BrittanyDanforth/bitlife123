--[[
	Teen Events (Ages 13-17)
	High school, identity, relationships, early choices
]]

-- CRITICAL FIX #TEEN-1: Add RANDOM definition for consistent random number generation
local RANDOM = Random.new()

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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "teen", -- CRITICAL FIX: Proper category
		tags = { "school", "education", "choices" },
		requiresFlags = { in_high_school = true }, -- CRITICAL FIX: Must be in school
		blockedByFlags = { dropped_out_high_school = true, in_prison = true },
		choices = {
			-- CRITICAL FIX #1003: Added math_science_talent for consequence events linkage!
			{ text = "Advanced Math & Science", effects = { Smarts = 5 }, setFlags = { stem_track = true, math_science_talent = true }, hintCareer = "tech", feedText = "You're challenging yourself with advanced STEM classes." },
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
		baseChance = 0.4, -- CRITICAL FIX: Reduced from 0.7
		cooldown = 5, -- CRITICAL FIX: Increased to prevent spam
		category = "teen", -- CRITICAL FIX: Proper category
		tags = { "school", "conflict", "teamwork" },
		requiresFlags = { in_high_school = true }, -- CRITICAL FIX: Must be in school
		blockedByFlags = { dropped_out_high_school = true, in_prison = true },
		choices = {
			{ text = "Do their share yourself", effects = { Smarts = 3, Happiness = -3, Health = -2 }, setFlags = { takes_on_too_much = true }, feedText = "You did all the work. Good grade, but you're exhausted." },
			{ text = "Talk to them directly", effects = { Smarts = 2, Happiness = 3 }, setFlags = { direct_communicator = true }, feedText = "You addressed the issue head-on." },
			{ text = "Tell the teacher", effects = { Smarts = 2 }, setFlags = { follows_rules = true }, feedText = "The teacher adjusted the grades accordingly." },
			{ text = "Accept a lower grade", effects = { Happiness = -2, Smarts = -1 }, feedText = "The project suffered, but you avoided conflict." },
		},
	},
	-- ═══════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: High School Dropout Event (like BitLife)
	-- This allows the GED and Return to School activities to work
	-- ═══════════════════════════════════════════════════════════════════════════
	{
		id = "considering_dropping_out",
		title = "Thinking About Dropping Out",
		emoji = "🚪",
		text = "School has been really hard lately. You're struggling with classes, maybe with teachers, maybe with other students. Some days you wonder if you should just quit.",
		question = "What do you do?",
		minAge = 15, maxAge = 17,
		baseChance = 0.45, -- Rare but possible
		cooldown = 3,
		requiresFlags = { in_high_school = true },
		blockedByFlags = { honor_student = true, academic_path = true },
		choices = {
			{
				text = "Drop out of high school",
				effects = { Happiness = 5, Smarts = -10 },
				setFlags = { dropped_out_high_school = true, in_high_school = nil, dropout = true },
				feedText = "You dropped out of high school. You can always get your GED later...",
				onResolve = function(state)
					state.Education = "none"
					state.EducationData = state.EducationData or {}
					state.EducationData.Status = "dropped_out"
					state.EducationData.Level = "none"
					state.Flags = state.Flags or {}
					state.Flags.dropped_out_high_school = true
					state.Flags.in_high_school = nil
					if state.AddFeed then
						state:AddFeed("📕 You dropped out of high school. You can get your GED or return later through Activities!")
					end
				end,
			},
			{
				text = "Get help from a counselor",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { sought_help = true },
				feedText = "You talked to someone about your struggles. It helped a lot.",
			},
			{
				text = "Push through - just one more year",
				effects = { Smarts = 5, Health = -2, Happiness = -3 },
				setFlags = { persistent = true },
				feedText = "You decided to stick it out. It's hard, but you'll make it.",
			},
			{
				text = "Try an alternative program",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { alternative_education = true },
				feedText = "You switched to an alternative learning program that fits you better.",
			},
		},
	},
	{
		id = "academic_pressure",
		title = "Under Pressure",
		emoji = "😰",
		text = "A big exam is coming up. You're feeling the pressure.",
		question = "How do you cope?",
		minAge = 14, maxAge = 17,
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.6
		cooldown = 5, -- CRITICAL FIX: Increased to prevent spam
		category = "teen", -- CRITICAL FIX: Proper category
		tags = { "school", "stress", "exam" },
		requiresFlags = { in_high_school = true }, -- CRITICAL FIX: Must be in school
		blockedByFlags = { dropped_out_high_school = true, in_prison = true },
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
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.7
		cooldown = 5, -- CRITICAL FIX: Increased to prevent spam
		category = "teen", -- CRITICAL FIX: Proper category
		tags = { "romance", "relationships", "teen" },
		requiresSingle = true,
		blockedByFlags = { in_prison = true, has_partner = true, dating = true },
		choices = {
			{ 
				text = "Ask them out", 
				effects = { Happiness = 8 }, 
				setFlags = { romantically_active = true, has_partner = true, dating = true }, 
				feedText = "You made a move! Heart pounding...",
				-- CRITICAL FIX: Actually create the partner object!
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					-- CRITICAL FIX: Partner should be OPPOSITE gender by default!
					-- BUG FIX: Normalize gender to lowercase for comparison
					local playerGender = (state.Gender or "male"):lower()
					local partnerIsMale = (playerGender == "female") -- If player is female, partner is male
					local names = partnerIsMale 
						and {"Jake", "Tyler", "Brandon", "Kyle", "Zach", "Dylan", "Josh", "Austin", "Connor", "Trevor"}
						or {"Emma", "Olivia", "Hannah", "Madison", "Chloe", "Alexis", "Taylor", "Savannah", "Kayla", "Hailey"}
					local partnerName = names[math.random(1, #names)] or "Someone"
					state.Relationships.partner = {
						id = "partner",
						name = partnerName,
						type = "romantic",
						role = partnerIsMale and "Boyfriend" or "Girlfriend",
						relationship = 70,
						age = state.Age or 15,
						gender = partnerIsMale and "male" or "female",
						alive = true,
						metThrough = "high_school",
						isClassmate = true,
					}
					if state.AddFeed then
						state:AddFeed(string.format("💘 You're dating %s! High school sweethearts!", partnerName))
					end
				end,
			},
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
		-- CRITICAL FIX: Added text variations for different party scenarios!
		textVariants = {
			"The most popular kid at school is throwing a huge party. You're somehow on the list!",
			"Word is there's going to be an EPIC party this weekend. You got invited!",
			"Your crush is going to be at a party this weekend. You just got the address.",
			"End of semester party! Everyone's going, but your parents are strict about curfew.",
			"There's a secret party happening. Parents will be gone. You got the invite.",
			"The football team is celebrating their win with a party. You're invited as a +1.",
		},
		question = "What do you do?",
		minAge = 15, maxAge = 17,
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.7
		cooldown = 5, -- CRITICAL FIX: Increased to prevent spam
		category = "teen", -- CRITICAL FIX: Proper category
		tags = { "social", "party", "teen" },
		blockedByFlags = { in_prison = true, grounded = true },
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
		textVariants = {
			"Different social groups are forming. Where do you fit in?",
			"High school has tribes. Which one is yours?",
			"Cafeteria seating says a lot. Where do you sit?",
			"Every group has its vibe. What's yours?",
			"Social circles are forming. Time to pick a lane... or not.",
			"The jocks, the nerds, the artsy kids... where do YOU belong?",
		},
		text = "Different social groups are forming. Where do you fit in?",
		question = "Which group do you gravitate toward?",
		minAge = 13, maxAge = 16,
		oneTime = true,
		category = "teen",
		tags = { "social", "identity", "teen" },
		requiresFlags = { in_high_school = true },
		blockedByFlags = { dropped_out_high_school = true, in_prison = true, found_clique = true },
		choices = {
			{ text = "The studious overachievers", effects = { Smarts = 5 }, setFlags = { nerd_group = true, found_clique = true, academic_focus = true }, hintCareer = "tech", feedText = "You found your tribe among the academic crowd." },
			{ text = "The athletes and jocks", effects = { Health = 5, Happiness = 3 }, setFlags = { jock_group = true, found_clique = true, athletic = true }, hintCareer = "sports", feedText = "You fit in with the athletic crowd." },
			{ text = "The creative/artsy types", effects = { Happiness = 5, Looks = 2 }, setFlags = { artsy_group = true, found_clique = true, creative = true }, hintCareer = "creative", feedText = "You found kindred creative spirits." },
			{ text = "The rebels and misfits", effects = { Happiness = 3 }, setFlags = { rebel_group = true, found_clique = true, independent_thinker = true }, feedText = "You don't follow the mainstream." },
			{ text = "A mix of everyone", effects = { Happiness = 3, Smarts = 2 }, setFlags = { social_butterfly = true, found_clique = true, adaptable = true }, feedText = "You move between groups easily." },
		},
	},
	{
		id = "friendship_drama",
		title = "Best Friend Betrayal",
		emoji = "💔",
		textVariants = {
			"You found out your best friend has been talking behind your back.",
			"Screenshots don't lie. Your BFF has been saying THINGS about you.",
			"A mutual friend showed you texts. Your best friend... isn't so friendly.",
			"The rumors going around? They started with your 'best friend.'",
			"Trust shattered. Someone you trusted has been fake.",
			"That person you told everything to? They've been sharing it all.",
		},
		text = "You found out your best friend has been talking behind your back.",
		question = "How do you react?",
		minAge = 13, maxAge = 17,
		baseChance = 0.3,
		cooldown = 6,
		category = "teen",
		tags = { "friendship", "conflict", "teen" },
		requiresFlags = { has_best_friend = true },
		blockedByFlags = { in_prison = true },
		choices = {
			{ text = "Confront them", effects = { Happiness = 3 }, setFlags = { confrontational = true, direct_communicator = true }, feedText = "You had it out. The truth came to light." },
			{ text = "End the friendship", effects = { Happiness = -5 }, setFlags = { holds_grudges = true, has_best_friend = false, been_betrayed = true }, feedText = "You cut them off. It hurts." },
			{ text = "Try to understand why", effects = { Smarts = 2, Happiness = 2 }, setFlags = { empathetic = true, emotionally_mature = true }, feedText = "You tried to see their perspective." },
			{ text = "Forgive and move on", effects = { Happiness = 3 }, setFlags = { forgiving = true, resilient = true }, feedText = "You chose to forgive. Friendships are complicated." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- IDENTITY & PERSONAL GROWTH
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "identity_question",
		title = "Who Am I?",
		emoji = "🪞",
		textVariants = {
			"You've been thinking a lot about who you really are.",
			"Late night thoughts hitting different. Who ARE you?",
			"Looking in the mirror and wondering who's looking back.",
			"Everyone seems to know who they are. Do you?",
			"Identity crisis? More like identity exploration.",
			"The person you were last year isn't who you are now.",
			"Trying to figure yourself out before life figures you out.",
		},
		text = "You've been thinking a lot about who you really are.",
		question = "What aspect of yourself are you exploring?",
		minAge = 14, maxAge = 17,
		oneTime = true,
		category = "teen",
		tags = { "identity", "growth", "teen" },
		blockedByFlags = { in_prison = true, identity_explored = true },
		choices = {
			{ text = "My values and beliefs", effects = { Smarts = 3, Happiness = 3 }, setFlags = { philosophical = true, identity_explored = true, deep_thinker = true }, feedText = "You're questioning what you believe in." },
			{ text = "My future career", effects = { Smarts = 3 }, setFlags = { career_focused = true, identity_explored = true, ambitious = true }, feedText = "You're thinking seriously about your future." },
			{ text = "My style and appearance", effects = { Looks = 5, Happiness = 3 }, setFlags = { style_conscious = true, identity_explored = true, fashion_aware = true }, feedText = "You're developing your personal style." },
			{ text = "My relationships with others", effects = { Happiness = 3 }, setFlags = { socially_aware = true, identity_explored = true, emotionally_intelligent = true }, feedText = "You're learning about how you relate to people." },
		},
	},
	{
		id = "mental_health_awareness",
		title = "Tough Times",
		emoji = "🌧️",
		text = "You've been feeling down lately. More than usual.",
		question = "How do you cope?",
		minAge = 13, maxAge = 17,
		baseChance = 0.35, -- CRITICAL FIX: Reduced
		cooldown = 5, -- CRITICAL FIX: Increased
		category = "teen", -- CRITICAL FIX: Proper category
		tags = { "mental_health", "coping", "teen" },
		blockedByFlags = { in_prison = true },
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
		-- CRITICAL FIX #16: Text variations for first job experience!
		textVariants = {
			"A local business is hiring teenagers for part-time work.",
			"The mall is hiring! Your chance to earn some cash.",
			"A 'Now Hiring' sign catches your eye. Time for your first job?",
			"Your parents suggest you get a part-time job to learn responsibility.",
			"Friends are bragging about their jobs. Maybe you should get one too?",
			"Summer is coming and so are job opportunities for teens!",
		},
		text = "A local business is hiring teenagers for part-time work.",
		question = "Will you apply?",
		minAge = 15, maxAge = 17,
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.7
		cooldown = 5, -- CRITICAL FIX: Increased
		category = "teen", -- CRITICAL FIX: Proper category
		tags = { "job", "money", "teen" },
		-- CRITICAL FIX: Only block by ACTUAL employment flags, not experience flags
		blockedByFlags = { employed = true, has_job = true, has_teen_job = true, in_prison = true },
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
		-- CRITICAL FIX: Added text variations!
		textVariants = {
			"You've been watching entrepreneurs online. Maybe YOU could start something!",
			"Your friends are all broke but you have IDEAS. Time to make money!",
			"Why work for someone else when you could be your own boss?",
			"You spotted a gap in the market. Time to fill it!",
			"Everyone keeps asking you to do this for them. Why not charge?",
		},
		question = "What's your business?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 5,
		category = "teen",
		tags = { "business", "money", "teen" },
		blockedByFlags = { in_prison = true, entrepreneur = true },
		choices = {
			{ text = "🌿 Lawn care / yard work", effects = { Money = 150, Health = 3 }, setFlags = { entrepreneur = true }, hintCareer = "business", feedText = "You started a lawn care service! Neighbors love you!" },
			{ text = "🎨 Selling crafts online", effects = { Money = 100, Happiness = 3 }, setFlags = { entrepreneur = true, creative_business = true }, hintCareer = "creative", feedText = "Your Etsy shop is up! Creativity pays!" },
			{ text = "💻 Tech support for neighbors", effects = { Money = 120, Smarts = 3 }, setFlags = { entrepreneur = true, tech_savvy = true }, hintCareer = "tech", feedText = "You're the neighborhood IT person! 'Have you tried turning it off?'" },
			{ text = "📱 Social media management", effects = { Money = 130, Smarts = 2 }, setFlags = { entrepreneur = true, social_media_savvy = true }, hintCareer = "marketing", feedText = "Local businesses hire you for their social media!" },
			{ text = "🎮 Streaming/content creation", effects = { Money = 80, Happiness = 5 }, setFlags = { entrepreneur = true, content_creator = true, future_streamer = true }, hintCareer = "entertainment", feedText = "You started streaming! First followers coming in!" },
			{ text = "🐕 Pet sitting / dog walking", effects = { Money = 110, Health = 2, Happiness = 3 }, setFlags = { entrepreneur = true, animal_lover = true }, feedText = "You're the neighborhood pet sitter! Puppy cuddles AND money!" },
			{ text = "📚 Tutoring classmates", effects = { Money = 140, Smarts = 4 }, setFlags = { entrepreneur = true, tutoring_business = true }, hintCareer = "education", feedText = "Kids pay you to help them pass! Easy money!" },
			{ text = "🚗 Car washing", effects = { Money = 160, Health = 2 }, setFlags = { entrepreneur = true }, feedText = "You wash cars on weekends! $20 per car adds up!" },
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
		blockedByFlags = { graduated_high_school = true, high_school_graduate = true, future_planned = true },
		choices = {
			{
				text = "Aim for a top university",
				effects = { Smarts = 3, Happiness = -2 },
				setFlags = { college_bound = true, ambitious = true, plans_for_college = true, future_planned = true },
				feedText = "You're working hard for a prestigious school.",
				-- CRITICAL FIX #805: Actually set up education path!
				-- User complaint: "Planning Your Future does nothing"
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.ivy_league_aspirations = true
					state.Flags.college_track = true
					-- Set education intention
					state.EducationPlan = state.EducationPlan or {}
					state.EducationPlan.goal = "top_university"
					state.EducationPlan.type = "university"
					if state.AddFeed then
						state:AddFeed("🎯 You're on the Ivy League track! Study hard!")
					end
				end,
			},
			{
				text = "State school is fine",
				effects = { Smarts = 2, Happiness = 2 },
				setFlags = { college_bound = true, practical = true, plans_for_college = true, future_planned = true },
				feedText = "You're taking a practical approach to higher ed.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.state_college_track = true
					state.EducationPlan = state.EducationPlan or {}
					state.EducationPlan.goal = "state_university"
					state.EducationPlan.type = "university"
					if state.AddFeed then
						state:AddFeed("🎯 State school it is! Practical and affordable!")
					end
				end,
			},
			{
				text = "Community college first",
				effects = { Smarts = 1, Money = 50 },
				setFlags = { college_bound = true, economical = true, plans_for_community_college = true, future_planned = true },
				feedText = "You're saving money with community college.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.community_college_track = true
					state.EducationPlan = state.EducationPlan or {}
					state.EducationPlan.goal = "community_college"
					state.EducationPlan.type = "community_college"
					state.Money = (state.Money or 0) + 500 -- Scholarship for being smart
					if state.AddFeed then
						state:AddFeed("🎯 Community college first - smart financial move!")
					end
				end,
			},
			{
				text = "Trade school / vocational",
				effects = { Smarts = 2 },
				setFlags = { trade_school_bound = true, future_planned = true },
				hintCareer = "trades",
				feedText = "You're planning to learn a skilled trade.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.trade_school_track = true
					state.Flags.practical_skills = true
					state.EducationPlan = state.EducationPlan or {}
					state.EducationPlan.goal = "trade_school"
					state.EducationPlan.type = "vocational"
					-- Trade skills start building
					state.CareerSkills = state.CareerSkills or {}
					state.CareerSkills.trades = (state.CareerSkills.trades or 0) + 10
					if state.AddFeed then
						state:AddFeed("🎯 Trade school path! You'll learn valuable hands-on skills!")
					end
				end,
			},
			{
				text = "Skip college, start working",
				effects = { Money = 100 },
				setFlags = { no_college = true, workforce_bound = true, future_planned = true },
				feedText = "You're ready to enter the workforce directly.",
				-- CRITICAL FIX: Actually prepare them for work!
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.eager_to_work = true
					state.Flags.job_ready = true
					state.Money = (state.Money or 0) + 200 -- Already saving from odd jobs
					-- Set up for job hunting at 18
					state.EducationPlan = state.EducationPlan or {}
					state.EducationPlan.goal = "work"
					state.EducationPlan.type = "none"
					if state.AddFeed then
						state:AddFeed("🎯 No college for you - you're going straight to work!")
					end
				end,
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
			-- CRITICAL FIX: Set has_ged_or_diploma for education activities
			state.Flags.has_diploma = true
			state.Flags.has_ged_or_diploma = true
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
		-- CRITICAL FIX: Renamed to teen_sports_varsity for unique ID
		id = "teen_sports_varsity",
		title = "Varsity Tryouts",
		emoji = "🏅",
		text = "Varsity sports tryouts are coming up. You've been practicing hard.",
		question = "Which sport?",
		minAge = 14, maxAge = 17,
		baseChance = 0.25, -- REDUCED from 0.35 - need prior sports interest
		cooldown = 5, -- INCREASED from 4
		requiresStats = { Health = { min = 50 } },
		-- CRITICAL FIX #TEEN-1: Block if player chose incompatible paths
		blockedByFlags = { 
			hates_sports = true, academic_focus = true, nerd_group = true,
			gamer_kid = true, tech_interest = true, coding_prodigy = true,
		},
		-- CRITICAL FIX: Require SOME prior sports interest
		eligibility = function(state)
			if state.Flags and state.Flags.hates_sports then return false end
			-- Must have SOME athletic interest
			if state.Flags then
				local hasInterest = state.Flags.likes_sports or state.Flags.athletic_focus 
					or state.Flags.plays_football or state.Flags.plays_basketball
					or state.Flags.sporty or state.Flags.natural_athlete
					or state.Flags.adventurous_spirit
				return hasInterest
			end
			return false -- No interest = no varsity tryouts
		end,
		choices = {
			{ text = "Football", effects = { Health = 5, Happiness = 5 }, setFlags = { varsity_athlete = true, varsity_football = true, plays_football = true }, hintCareer = "sports", feedText = "You made the football team!" },
			{ text = "Basketball", effects = { Health = 5, Happiness = 5 }, setFlags = { varsity_athlete = true, varsity_basketball = true, plays_basketball = true }, hintCareer = "sports", feedText = "You made the basketball team!" },
			{ text = "Soccer", effects = { Health = 5, Happiness = 5 }, setFlags = { varsity_athlete = true, plays_soccer = true }, hintCareer = "sports", feedText = "You made the soccer team!" },
			{ text = "Track & Field", effects = { Health = 7, Happiness = 5 }, setFlags = { varsity_athlete = true, runs_track = true }, hintCareer = "sports", feedText = "You joined the track team!" },
			{ 
				text = "Not really into sports", 
				effects = { }, 
				feedText = "Organized sports aren't your thing.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.sports_declines = (state.Flags.sports_declines or 0) + 1
					if state.Flags.sports_declines >= 2 then
						state.Flags.hates_sports = true
					end
					state:AddFeed("🏅 Varsity sports aren't for you. Other interests await!")
				end,
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: EXPANDED TEEN SPORTS EVENTS
	-- User feedback: "have events that let u be like nah or taking sports more seriously"
	-- These connect to childhood sports progression for athlete career path
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "teen_sports_college_scout",
		title = "College Scout at Your Game!",
		emoji = "🎓",
		text = "There's a college scout in the stands watching YOUR game! Your coach told you to play your best. This could be a scholarship opportunity!",
		question = "How do you handle the pressure?",
		minAge = 15, maxAge = 17,
		baseChance = 0.35,
		cooldown = 8,
		oneTime = true,
		requiresFlags = { varsity_athlete = true },
		blockedByFlags = { quit_sports = true },
		requiresStats = { Health = 60 },
		
		choices = {
			{
				text = "Play my heart out - this is my moment!",
				effects = { Health = 3 },
				feedText = "Time to shine!",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 35 then
						state:ModifyStat("Happiness", 20)
						state.Flags.college_sports_interest = true
						state.Flags.scholarship_likely = true
						state:AddFeed("🎓 INCREDIBLE performance! The scout took notes the WHOLE game! They want to meet with you!")
					elseif roll <= 70 then
						state:ModifyStat("Happiness", 10)
						state.Flags.college_sports_interest = true
						state:AddFeed("🎓 Solid game! The scout seemed impressed. You might hear from them!")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags.choked_scout_game = true
						state:AddFeed("🎓 Nerves got to you. Not your best game. The scout left early...")
					end
				end,
			},
			{
				text = "Just play my normal game - don't overthink it",
				effects = { Happiness = 5 },
				feedText = "Staying calm...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 50 then
						state:ModifyStat("Happiness", 12)
						state.Flags.college_sports_interest = true
						state:AddFeed("🎓 Your consistent play impressed the scout! They appreciate players who don't crack under pressure!")
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎓 Average game. The scout made some notes but didn't seem blown away.")
					end
				end,
			},
			{
				text = "I don't think college sports is for me",
				effects = { Happiness = 2 },
				feedText = "Sports for fun, not for a career.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.casual_athlete = true
					state.Flags.varsity_athlete = nil
					state:AddFeed("🎓 You decided sports will stay a hobby, not a career. There are other paths!")
				end,
			},
		},
	},
	
	{
		id = "teen_sports_state_championship",
		title = "State Championship Game!",
		emoji = "🏆",
		text = "Your team made it to the STATE CHAMPIONSHIP! This is the biggest game of your life. The whole school is going. Local news will be there. Scouts are watching.",
		question = "How do you prepare for the biggest game ever?",
		minAge = 15, maxAge = 18,
		baseChance = 0.3,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { varsity_athlete = true },
		blockedByFlags = { quit_sports = true },
		
		choices = {
			{
				text = "Train harder than ever - I WILL be ready",
				effects = { Health = 5 },
				feedText = "Extra practice, extra film study...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					state.Flags.state_championship_played = true
					if roll <= 45 then
						state:ModifyStat("Happiness", 25)
						state.Flags.state_champion = true
						state.Flags.sports_legend = true
						state.Fame = math.min(100, (state.Fame or 0) + 15)
						state:AddFeed("🏆 STATE CHAMPIONS!!! You played the game of your LIFE! MVP! Legend status!")
					elseif roll <= 75 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🏆 Lost in a close game. Heartbreaking but you left it all on the field. Proud moment.")
					else
						state:ModifyStat("Happiness", -10)
						state:AddFeed("🏆 Got blown out. Tough loss. But making it to state is still an achievement.")
					end
				end,
			},
			{
				text = "Stay loose - don't put too much pressure on myself",
				effects = { Happiness = 3 },
				feedText = "Keeping things in perspective...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					state.Flags.state_championship_played = true
					if roll <= 35 then
						state:ModifyStat("Happiness", 20)
						state.Flags.state_champion = true
						state:AddFeed("🏆 Your relaxed approach worked! STATE CHAMPIONS! What a game!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🏆 Didn't win, but you enjoyed the experience. No regrets!")
					end
				end,
			},
		},
	},
	
	{
		id = "teen_sports_injury_setback",
		title = "Sports Injury Setback",
		emoji = "🤕",
		text = "You got injured during practice. The doctor says you need several weeks to recover. You might miss the rest of the season.",
		question = "How do you deal with this setback?",
		minAge = 14, maxAge = 17,
		baseChance = 0.3,
		cooldown = 8,
		requiresFlags = { varsity_athlete = true },
		blockedByFlags = { quit_sports = true },
		
		choices = {
			{
				text = "Focus on recovery - I'll come back stronger",
				effects = { Health = 5, Smarts = 3 },
				feedText = "Patience and determination...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.overcame_injury = true
					state.Flags.resilient = true
					state:ModifyStat("Happiness", 5)
					state:AddFeed("🤕 The recovery was hard but you came back stronger than ever! Coaches noticed your dedication.")
				end,
			},
			{
				text = "Try to play through it - the team needs me",
				effects = { Health = -10 },
				feedText = "Risking it all...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 30 then
						state:ModifyStat("Happiness", 10)
						state.Flags.played_through_pain = true
						state:AddFeed("🤕 You gutted it out! Team MVP for your dedication!")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -15)
						state.Flags.chronic_injury = true
						state:AddFeed("🤕 Made the injury WORSE. Now you're out even longer. Should have rested.")
					end
				end,
			},
			{
				text = "Maybe this is a sign to quit sports",
				effects = { Happiness = -5 },
				feedText = "Reconsidering everything...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.quit_sports = true
					state.Flags.varsity_athlete = nil
					state:AddFeed("🤕 You decided sports aren't worth the physical toll. Time for new pursuits.")
				end,
			},
		},
	},
	{
		id = "school_play",
		title = "Drama Production",
		emoji = "🎭",
		text = "The school is putting on a big play. Auditions are open.",
		question = "Will you participate?",
		minAge = 13, maxAge = 17,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

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
		-- CRITICAL FIX #17: Text variations for prom experience!
		textVariants = {
			"Prom is coming up! The biggest dance of the year.",
			"Everyone's talking about prom. It's THE event of senior year!",
			"Prom tickets are on sale. Your social life hangs in the balance!",
			"The prom theme was just announced. Time to make plans!",
			"You can feel the prom excitement in the air. What's your move?",
			"Posters for prom are everywhere. You can't escape prom fever!",
		},
		text = "Prom is coming up! The biggest dance of the year.",
		question = "What's your prom plan?",
		minAge = 16, maxAge = 18,
		oneTime = true,
		-- CRITICAL FIX: Random promposal outcomes
		choices = {
		{
			-- CRITICAL FIX: Big promposal is optional - there's a free simple ask too!
			text = "Big elaborate promposal ($100)",
			effects = { Money = -100 },
			feedText = "You planned an elaborate promposal...",
			eligibility = function(state) return (state.Money or 0) >= 100, "💸 Try asking simply instead!" end,
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local happiness = (state.Stats and state.Stats.Happiness) or 50
					local roll = math.random()
					local successChance = 0.50 + (looks / 200) + (happiness / 300)
					if state.Flags and (state.Flags.romantically_active or state.Flags.has_partner) then
						successChance = successChance + 0.20
					end
					if roll < successChance then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 10) end
						state.Flags = state.Flags or {}
						state.Flags.prom_date = true
						state.Flags.romantic_gesture = true
						if state.AddFeed then state:AddFeed("💃 They said YES! Your promposal was epic!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -8) end
						if state.AddFeed then state:AddFeed("💃 They said no... Rejection stings, but you're brave for trying.") end
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
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then
							state:ModifyStat("Happiness", 12)
							state:ModifyStat("Looks", 2)
						end
						state.Flags = state.Flags or {}
						state.Flags.prom_date = true
						if state.AddFeed then state:AddFeed("💃 Someone asked you to prom! What a moment!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -5) end
						if state.AddFeed then state:AddFeed("💃 Nobody asked... You ended up going with friends instead.") end
					end
				end,
			},
		{
			-- CRITICAL FIX: Free option to ask your crush simply
			text = "Simply ask your crush",
			effects = {},
			feedText = "You asked them sincerely...",
			onResolve = function(state)
				local looks = (state.Stats and state.Stats.Looks) or 50
				local roll = math.random()
				local successChance = 0.40 + (looks / 200)
				if roll < successChance then
					if state.ModifyStat then state:ModifyStat("Happiness", 8) end
					state.Flags = state.Flags or {}
					state.Flags.prom_date = true
					if state.AddFeed then state:AddFeed("💃 They said YES! Sometimes simple is best!") end
				else
					if state.ModifyStat then state:ModifyStat("Happiness", -5) end
					if state.AddFeed then state:AddFeed("💃 They said no... but at least you asked!") end
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
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresSingle = true,

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
						state.Flags.dating = true
						-- CRITICAL FIX: Actually create the partner object!
						state.Relationships = state.Relationships or {}
						-- CRITICAL FIX: Partner should be OPPOSITE gender by default!
						-- BUG FIX: Normalize gender to lowercase for comparison
						local playerGender = (state.Gender or "male"):lower()
						local partnerIsMale = (playerGender == "female") -- If player is female, partner is male
						local names = partnerIsMale 
							and {"Ryan", "Tyler", "Brandon", "Kyle", "Zach", "Dylan", "Josh", "Austin", "Connor", "Trevor"}
							or {"Lily", "Sophie", "Grace", "Chloe", "Zoe", "Bella", "Mia", "Emma", "Ava", "Harper"}
						local partnerName = names[math.random(1, #names)] or "Someone"
						state.Relationships.partner = {
							id = "partner",
							name = partnerName,
							type = "romantic",
							role = partnerIsMale and "Boyfriend" or "Girlfriend",
							relationship = 65,
							age = state.Age or 15,
							gender = partnerIsMale and "male" or "female",
							alive = true,
							metThrough = "summer_vacation",
							longDistance = true,
						}
						if state.ModifyStat then
							state:ModifyStat("Happiness", 10)
						end
						if state.AddFeed then
							state:AddFeed(string.format("☀️ Your summer romance with %s turned into something real!", partnerName))
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
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

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
		baseChance = 0.35, -- CRITICAL FIX: Reduced
		cooldown = 5,
		maxOccurrences = 2, -- Can tour twice max
		oneTime = true, -- CRITICAL FIX: Only one college tour decision needed

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
		-- CRITICAL FIX #18: Text variations for driving test milestone!
		textVariants = {
			"It's time for your driver's license road test! The examiner is watching your every move.",
			"The big day is here - your driving test! Your palms are sweaty.",
			"You're behind the wheel for your license test. The examiner looks stern.",
			"DMV road test day! Your future of automotive freedom depends on the next 15 minutes.",
			"The driving instructor clicks their seatbelt. It's go time.",
			"License test! Your parents wave nervously as you pull away with the examiner.",
		},
		text = "It's time for your driver's license road test! The examiner is watching your every move.",
		question = "How do you approach the test?",
		minAge = 16, maxAge = 17,
		oneTime = true,
		maxOccurrences = 1,
		-- CRITICAL FIX: Block if already have license OR already did another driving event
		blockedByFlags = { has_license = true, drivers_license = true, driver_license = true, has_drivers_license = true, driving_done = true, in_prison = true },

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
						-- CRITICAL FIX: Set ALL license flag variations for compatibility!
						state.Flags.has_license = true
						state.Flags.drivers_license = true
						state.Flags.driver_license = true
						state.Flags.has_drivers_license = true
						state.Flags.learned_driving = true
						state:AddFeed("🚗 You passed the driving test! You're licensed!")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.learned_driving = true -- Mark as attempted
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
					local baseChance = 0.555
					local smarts = state.Stats and state.Stats.Smarts or 50
					local bonus = (smarts - 50) / 150
					
					if math.random() < (baseChance + bonus) then
						state:ModifyStat("Happiness", 7)
						state.Flags = state.Flags or {}
						-- CRITICAL FIX: Set ALL license flag variations for compatibility!
						state.Flags.has_license = true
						state.Flags.drivers_license = true
						state.Flags.driver_license = true
						state.Flags.has_drivers_license = true
						state.Flags.learned_driving = true
						state:AddFeed("🚗 Somehow you passed despite being nervous! Licensed driver!")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.nervous_driver = true
						state.Flags.learned_driving = true -- Mark as attempted
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
						-- CRITICAL FIX: Set ALL license flag variations for compatibility!
						state.Flags.has_license = true
						state.Flags.drivers_license = true
						state.Flags.driver_license = true
						state.Flags.has_drivers_license = true
						state.Flags.learned_driving = true
						state.Flags.good_driver = true
						state:AddFeed("🚗 Perfect score! Your preparation paid off. Licensed to drive!")
					else
						state:ModifyStat("Happiness", -3)
						state.Flags = state.Flags or {}
						state.Flags.learned_driving = true -- Mark as attempted
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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

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
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

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
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.7 to prevent spam
		cooldown = 5, -- CRITICAL FIX: Increased from 3
		oneTime = true, -- CRITICAL FIX: Only happens once per life
		blockedByFlags = { in_prison = true, dropped_out_high_school = true, senioritis_event_done = true },

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
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

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
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresFlags = { has_best_friend = true },

		choices = {
			{ text = "Promise to stay in touch forever", effects = { Happiness = -4 }, setFlags = { long_distance_friendship = true }, feedText = "Distance doesn't end real friendships." },
			{ text = "Throw them a going-away party ($50)", effects = { Happiness = 3, Money = -50 }, feedText = "You gave them an amazing send-off!", eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 for party supplies" end },
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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam

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
					local baseChance = 0.550 -- risky approach
					
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
				text = "Driving school ($200)", 
				effects = { Money = -200 },
				setFlags = { driving_school = true },
				eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for driving school" end,
				feedText = "🚗 Signed up for professional driving lessons!",
			},
			{ 
				text = "Ask parents to pay for driving school", 
				effects = { Smarts = 3 },
				setFlags = { driving_school = true },
				feedText = "🚗 Your parents paid for driving school! Lucky!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EXPANDED TEEN EVENTS - MORE VARIETY AND DEPTH
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_part_time_struggle",
		title = "Work-Life Balance",
		emoji = "⏰",
		text = "Your part-time job is interfering with school and social life.",
		question = "How do you handle this?",
		minAge = 15, maxAge = 17,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresFlags = { has_teen_job = true },
		
		choices = {
			{ text = "Quit the job - school comes first", effects = { Smarts = 3, Happiness = 4 }, setFlags = { has_teen_job = false }, feedText = "You quit to focus on what matters. Good choice." },
			{ text = "Cut back hours", effects = { Happiness = 3 }, feedText = "Finding balance with fewer work hours." },
			{ text = "Power through - need the money", effects = { Health = -3, Money = 100 }, setFlags = { workaholic = true }, feedText = "You're exhausted but the paycheck is worth it... maybe." },
			{ text = "Switch to a flexible job", effects = { Happiness = 3, Money = 50 }, feedText = "Found something with better hours!" },
		},
	},
	{
		id = "teen_crush_confession",
		title = "Confession Time",
		emoji = "💌",
		text = "You've been holding in your feelings for someone special. It's eating you up inside.",
		question = "Do you finally confess?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		requiresSingle = true,
		
		-- CRITICAL FIX: Random confession outcome
		choices = {
			{
				text = "Go for it - tell them everything",
				effects = {},
				feedText = "You gathered your courage and confessed...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local happiness = (state.Stats and state.Stats.Happiness) or 50
					local roll = math.random()
					local successChance = 0.35 + (looks / 200) + (happiness / 300)
					if state.Flags and (state.Flags.popular or state.Flags.attractive) then
						successChance = successChance + 0.15
					end
					if roll < successChance then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						state.Flags.romantically_active = true
						state.Flags.dating = true
						-- Create partner
						state.Relationships = state.Relationships or {}
						-- CRITICAL FIX: Partner should be OPPOSITE gender by default!
						-- BUG FIX: Normalize gender to lowercase for comparison
						local playerGender = (state.Gender or "male"):lower()
						local partnerIsMale = (playerGender == "female") -- If player is female, partner is male
						local names = partnerIsMale 
							and {"Mason", "Ethan", "Noah", "Liam", "Lucas", "Oliver", "Aiden", "Elijah"}
							or {"Ava", "Isabella", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn", "Luna"}
						local partnerName = names[math.random(1, #names)] or "Someone"
						state.Relationships.partner = {
							id = "partner",
							name = partnerName,
							type = "romantic",
							role = partnerIsMale and "Boyfriend" or "Girlfriend",
							relationship = 75,
							age = state.Age or 15,
							gender = partnerIsMale and "male" or "female",
							alive = true,
							metThrough = "school",
						}
						state:AddFeed(string.format("💌 They said they like you too! You're now dating %s!", partnerName))
					elseif roll < successChance + 0.25 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("💌 They were flattered but want to stay friends. Ouch, but not terrible.")
					else
						state:ModifyStat("Happiness", -10)
						state:AddFeed("💌 Rejected... hard. They weren't kind about it. That really hurt.")
					end
				end,
			},
		{
			text = "Write them a letter instead",
			effects = {},
			feedText = "You wrote a heartfelt letter...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.40 then
					state:ModifyStat("Happiness", 10)
					state:ModifyStat("Smarts", 1)
					-- CRITICAL FIX: Create partner relationship when letter works!
					state.Flags = state.Flags or {}
					state.Flags.has_partner = true
					state.Flags.dating = true
					state.Relationships = state.Relationships or {}
					-- CRITICAL FIX: Partner should be OPPOSITE gender by default!
					-- BUG FIX: Normalize gender to lowercase for comparison
					local playerGender = (state.Gender or "male"):lower()
					local partnerIsMale = (playerGender == "female") -- If player is female, partner is male
					local names = partnerIsMale 
						and {"Mason", "Ethan", "Noah", "Liam", "Lucas", "Oliver", "Aiden", "Elijah"}
						or {"Ava", "Isabella", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn", "Luna"}
					local partnerName = names[math.random(1, #names)] or "Someone"
					state.Relationships.partner = {
						id = "partner",
						name = partnerName,
						type = "romantic",
						role = partnerIsMale and "Boyfriend" or "Girlfriend",
						relationship = 70,
						age = state.Age or 15,
						gender = partnerIsMale and "male" or "female",
						alive = true,
						metThrough = "school",
					}
					state:AddFeed(string.format("💌 The letter worked! You're now dating %s!", partnerName))
				elseif roll < 0.70 then
					state:ModifyStat("Happiness", -2)
					state:AddFeed("💌 They appreciated the letter but aren't interested that way.")
				else
					state:ModifyStat("Happiness", -7)
					state:AddFeed("💌 They showed the letter to their friends... Mortifying.")
				end
			end,
		},
			{ text = "Keep it inside - too risky", effects = { Happiness = -4 }, setFlags = { fear_of_rejection = true }, feedText = "You'll always wonder what could have been..." },
			{ text = "Drop hints and see if they notice", effects = { Happiness = 2 }, feedText = "You're being subtle. Maybe too subtle?" },
		},
	},
	{
		id = "teen_essay_contest",
		title = "Essay Contest",
		emoji = "✍️",
		text = "Your English teacher nominated you for a prestigious essay contest!",
		question = "What topic do you write about?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresStats = { Smarts = { min = 55 } },
		
		-- CRITICAL FIX: Random essay contest outcome
		choices = {
			{
				text = "A personal story about overcoming challenges",
				effects = { Smarts = 3 },
				feedText = "You poured your heart into a personal essay...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local winChance = 0.30 + (smarts / 200)
					if state.Flags and (state.Flags.bookworm or state.Flags.creative) then
						winChance = winChance + 0.15
					end
					if roll < winChance then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 5)
						state.Flags = state.Flags or {}
						state.Flags.essay_winner = true
						state:AddFeed("✍️ You won first place! $500 prize and recognition!")
					elseif roll < winChance + 0.30 then
						state.Money = (state.Money or 0) + 100
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("✍️ Honorable mention! Nice recognition.")
					else
						state:ModifyStat("Smarts", 2)
						state:AddFeed("✍️ Didn't win, but the writing practice was valuable.")
					end
				end,
			},
			{
				text = "An opinion piece on a social issue",
				effects = { Smarts = 3 },
				feedText = "You wrote a passionate opinion piece...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.activist_writer = true
						state:AddFeed("✍️ Your essay sparked conversation and won!")
					elseif roll < 0.50 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("✍️ Well-received but not a winner.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("✍️ Judges found it too controversial.")
					end
				end,
			},
			{ text = "A creative fiction piece", effects = { Smarts = 2, Happiness = 4 }, setFlags = { fiction_writer = true }, hintCareer = "creative", feedText = "You enjoyed writing a creative story!" },
			{ text = "Skip the contest - too much pressure", effects = { Happiness = -2 }, feedText = "You passed on the opportunity." },
		},
	},
	{
		id = "teen_car_purchase_dream",
		title = "Dream Car",
		emoji = "🚗",
		text = "You've been saving up and finally have enough to buy a cheap car!",
		question = "What kind of car do you look for?",
		minAge = 16, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresFlags = { has_license = true },
		-- CRITICAL FIX: Check money requirement!
		eligibility = function(state)
			local money = state.Money or 0
			if money < 1500 then
				return false, "Not enough money for a car"
			end
			return true
		end,
		
		choices = {
			{
				text = "Cheap beater ($1,500)",
				effects = { Money = -1500, Happiness = 7 },
				setFlags = { has_car = true, owns_car = true },
				eligibility = function(state) return (state.Money or 0) >= 1500, "💸 Need $1,500 for a car" end,
				feedText = "🚗 You bought your first car for $1,500! Freedom!",
				onResolve = function(state)
					state:AddAsset("Vehicles", {
						id = "beater_car_" .. tostring(os.time()),
						type = "sedan",
						name = "Beater Car",
						emoji = "🚗",
						price = 1500,
						value = 1200,
						condition = 50,
						happiness = 3,
						maintenance = 400,
						acquiredAge = state.Age,
						description = "Your first car! It runs... mostly.",
					})
				end,
			},
			{
				text = "Something reliable ($3,000)",
				effects = { Money = -3000, Happiness = 8 },
				setFlags = { has_car = true, owns_car = true },
				eligibility = function(state) return (state.Money or 0) >= 3000, "💸 Need $3,000 for reliable car" end,
				feedText = "🚗 You bought a reliable car for $3,000! Smart choice.",
				onResolve = function(state)
					state:AddAsset("Vehicles", {
						id = "reliable_car_" .. tostring(os.time()),
						type = "sedan",
						name = "Reliable Car",
						emoji = "🚗",
						price = 3000,
						value = 2800,
						condition = 80,
						happiness = 4,
						maintenance = 250,
						acquiredAge = state.Age,
						description = "Not flashy, but it works!",
					})
				end,
			},
			{ text = "Keep saving for something better", effects = { Happiness = -2, Money = 200 }, feedText = "Patience. You want something nice." },
			{ text = "Parents offer to help pay", effects = { Happiness = 6 }, setFlags = { parents_helped_with_car = true }, feedText = "Your parents chipped in! Family car incoming." },
		},
	},
	{
		id = "teen_band_start",
		title = "Starting a Band",
		emoji = "🎸",
		text = "You and your friends want to start a band together!",
		question = "What role do you play?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		choices = {
			{ text = "Lead vocals", effects = { Happiness = 8, Looks = 3 }, setFlags = { band_vocalist = true, in_band = true }, hintCareer = "entertainment", feedText = "You're the face of the band! Time to practice your stage presence." },
			{ text = "Guitar", effects = { Happiness = 7, Smarts = 2 }, setFlags = { band_guitarist = true, in_band = true }, hintCareer = "entertainment", feedText = "You're shredding! Learning new riffs every day." },
			{ text = "Drums", effects = { Happiness = 6, Health = 2 }, setFlags = { band_drummer = true, in_band = true }, hintCareer = "entertainment", feedText = "You're the heartbeat of the band!" },
			{ text = "Bass", effects = { Happiness = 5, Smarts = 2 }, setFlags = { band_bassist = true, in_band = true }, hintCareer = "entertainment", feedText = "The underrated hero. Holding down the groove!" },
			{ text = "Manager/organizer instead", effects = { Smarts = 4, Money = 20 }, setFlags = { band_manager = true }, hintCareer = "business", feedText = "You're handling the business side. Smart move!" },
		},
	},
	{
		id = "teen_band_gig",
		title = "First Gig",
		emoji = "🎤",
		text = "Your band got offered your first real gig at a local venue!",
		question = "How does the performance go?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		requiresFlags = { in_band = true },
		
		-- CRITICAL FIX: Random gig outcome
		choices = {
			{
				text = "Give it everything you've got",
				effects = {},
				feedText = "You took the stage and played your hearts out...",
				onResolve = function(state)
					local happiness = (state.Stats and state.Stats.Happiness) or 50
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local successChance = 0.40 + (happiness / 200) + (looks / 300)
					if roll < successChance then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Looks", 3)
						state.Money = (state.Money or 0) + 150
						state.Flags = state.Flags or {}
						state.Flags.successful_musician = true
						state:AddFeed("🎤 AMAZING show! The crowd loved you! You got paid $150!")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Happiness", 5)
						state.Money = (state.Money or 0) + 50
						state:AddFeed("🎤 Decent set. Some people enjoyed it!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🎤 Rough gig. Technical difficulties and missed notes. The crowd was lukewarm.")
					end
				end,
			},
			{
				text = "Play it safe with familiar songs",
				effects = {},
				feedText = "You stuck to what you know...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 6)
						state.Money = (state.Money or 0) + 75
						state:AddFeed("🎤 Solid performance! Safe but good.")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🎤 Nothing special, but you got through it.")
					end
				end,
			},
			{ text = "Get stage fright and bail", effects = { Happiness = -10 }, setFlags = { stage_fright = true, in_band = false }, feedText = "You couldn't do it. The band might not forgive you." },
		},
	},
	{
		id = "teen_social_media_drama",
		title = "Online Drama",
		emoji = "💬",
		text = "There's major drama happening in your social circle online!",
		question = "What's your role in all this?",
		minAge = 13, maxAge = 17,
		baseChance = 0.35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		choices = {
			{ text = "Stay out of it completely", effects = { Happiness = 3 }, setFlags = { avoids_drama = true }, feedText = "Not your circus, not your monkeys. Smart." },
			{ text = "Try to mediate and help", effects = { Happiness = 2, Smarts = 2 }, setFlags = { peacemaker = true }, feedText = "You tried to calm things down. Some appreciated it." },
			{ text = "Take sides and defend a friend", effects = { Happiness = -2 }, setFlags = { loyal_friend = true }, feedText = "You backed up your friend. Made some enemies though." },
			{ text = "Fuel the fire for entertainment", effects = { Happiness = 4 }, setFlags = { drama_starter = true }, feedText = "You made it worse... but it was entertaining." },
		},
	},
	{
		id = "teen_parent_conflict",
		title = "Parent Problems",
		emoji = "😤",
		text = "You and your parents are fighting about something big.",
		question = "What's the conflict about?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		choices = {
			{ text = "Curfew and freedoms", effects = { Happiness = -4 }, setFlags = { curfew_fighter = true }, feedText = "You want more independence. They want to keep you safe." },
			{ text = "Grades and school performance", effects = { Happiness = -3, Smarts = 2 }, feedText = "The lecture about grades was not fun." },
			{ text = "Choice of friends", effects = { Happiness = -5 }, setFlags = { rebel = true }, feedText = "They don't approve of your friends. You don't care." },
			{ text = "Screen time and phone usage", effects = { Happiness = -3 }, feedText = "Put down the phone, they said. For hours." },
			{ text = "We actually resolved it like adults", effects = { Happiness = 3, Smarts = 2 }, setFlags = { mature_communicator = true }, feedText = "You talked it out. Growth!" },
		},
	},
	{
		id = "teen_anxiety_attack",
		title = "Anxiety Strikes",
		emoji = "😰",
		text = "You're having an anxiety attack. Heart racing, can't breathe...",
		question = "How do you cope?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		
		choices = {
			{ text = "Practice breathing techniques", effects = { Happiness = 3, Health = 2 }, setFlags = { manages_anxiety = true }, feedText = "Deep breaths helped calm you down." },
			{ text = "Call someone you trust", effects = { Happiness = 4 }, setFlags = { reaches_out = true }, feedText = "Talking to someone helped you feel less alone." },
			{ text = "Hide it and push through", effects = { Happiness = -5, Health = -3 }, setFlags = { hides_struggles = true }, feedText = "You suffered in silence. Not healthy." },
			{ text = "Leave the situation causing it", effects = { Happiness = 2 }, feedText = "Removing yourself from the trigger helped." },
			{ text = "Talk to a professional", effects = { Happiness = 5, Health = 4 }, setFlags = { gets_help = true }, feedText = "Getting professional help was the right call." },
		},
	},
	{
		id = "teen_acne_struggle",
		title = "Skin Problems",
		emoji = "😣",
		text = "Stress and bad luck have caused skin breakouts. It's ruining your confidence.",
		question = "How do you deal with it?",
		minAge = 13, maxAge = 17,
		baseChance = 0.35,
		cooldown = 3,
		
		choices = {
			{
				text = "See a dermatologist ($80)",
				effects = { Money = -80 },
				feedText = "You got professional treatment...",
				eligibility = function(state) return (state.Money or 0) >= 80, "💸 Can't afford dermatologist ($80 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Looks", 5)
						state:ModifyStat("Happiness", 6)
						state:AddFeed("😊 The treatment worked! Your skin is clearing up!")
					else
						state:ModifyStat("Looks", 2)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("😊 Slow progress, but it's getting better.")
					end
				end,
			},
			{ text = "Try over-the-counter products ($20)", effects = { Money = -20, Looks = 2 }, feedText = "Some improvement with drugstore products.",
				eligibility = function(state) return (state.Money or 0) >= 20, "💸 Can't afford skincare products ($20 needed)" end,
			},
			{ text = "Accept it as part of being a teen", effects = { Happiness = 3 }, setFlags = { self_accepting = true }, feedText = "It's temporary. You're still you." },
			{ text = "Cover it with makeup ($30)", effects = { Looks = 3, Money = -30 }, feedText = "Learned some concealing techniques!",
				eligibility = function(state) return (state.Money or 0) >= 30, "💸 Can't afford makeup ($30 needed)" end,
			},
		},
	},
	{
		id = "teen_first_kiss",
		title = "First Kiss",
		emoji = "💋",
		text = "There might be a chance for your first kiss...",
		question = "How does it go?",
		minAge = 13, maxAge = 17,
		oneTime = true,
		baseChance = 0.4,
		
		-- CRITICAL FIX: Random kiss outcome
		choices = {
			{
				text = "Go for it!",
				effects = {},
				feedText = "You leaned in...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.had_first_kiss = true
						state.Flags.romantic = true
						state:AddFeed("💋 Your first kiss! Butterflies everywhere! It was perfect.")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.had_first_kiss = true
						state:AddFeed("💋 First kiss done! A little awkward but still memorable.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("💋 They turned away. Rejected. Ouch.")
					end
				end,
			},
			{ text = "Wait for them to make the move", effects = { }, feedText = "You waited nervously...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.had_first_kiss = true
						state:AddFeed("💋 They kissed you! Your first kiss!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("💋 They didn't make a move. The moment passed.")
					end
				end,
			},
			{ text = "Chicken out", effects = { Happiness = -4 }, setFlags = { missed_opportunity = true }, feedText = "You couldn't do it. The moment was lost." },
		},
	},
	{
		id = "teen_hobby_discovery",
		title = "New Interest",
		emoji = "✨",
		text = "You've discovered a new hobby that really excites you!",
		question = "What hobby captured your interest?",
		minAge = 13, maxAge = 17,
		baseChance = 0.35,
		cooldown = 3,
		
		choices = {
			{ text = "Photography", effects = { Happiness = 5, Smarts = 2 }, setFlags = { photographer = true }, hintCareer = "creative", feedText = "You're seeing the world through a new lens!" },
			{ text = "Coding/Programming", effects = { Smarts = 6, Happiness = 4 }, setFlags = { codes = true }, hintCareer = "tech", feedText = "Building apps and websites is addictive!" },
			{ text = "Fitness/Working out", effects = { Health = 6, Happiness = 4, Looks = 2 }, setFlags = { fitness_enthusiast = true }, feedText = "Getting stronger every day!" },
			{ text = "Art/Drawing", effects = { Happiness = 5, Looks = 2 }, setFlags = { artist = true }, hintCareer = "creative", feedText = "You're creating amazing art!" },
			{ text = "Writing stories", effects = { Smarts = 4, Happiness = 4 }, setFlags = { writer = true }, hintCareer = "creative", feedText = "Worlds are being born in your imagination!" },
			{ text = "Playing an instrument", effects = { Smarts = 3, Happiness = 5 }, setFlags = { musician = true }, hintCareer = "entertainment", feedText = "Making music is your new passion!" },
		},
	},
	{
		id = "teen_bullying_witness",
		title = "Witnessing Bullying",
		emoji = "👊",
		text = "You see someone getting bullied at school.",
		question = "What do you do?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		
		choices = {
			{ 
				text = "👊 Stand up and FIGHT!", 
				effects = {},
				setFlags = { stands_up_to_bullies = true },
				feedText = "You physically intervened...",
				-- CRITICAL FIX: Fight minigame for standing up to bullies!
				triggerMinigame = "fight",
				minigameOptions = { difficulty = "easy" },
				onResolve = function(state, minigameResult)
					local won = minigameResult and (minigameResult.success or minigameResult.won)
					if won then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Health", -5)
						state.Flags = state.Flags or {}
						state.Flags.hero = true
						state.Flags.fighter = true
						state:AddFeed("👊 You beat the bully! Everyone cheered. You're a hero!")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.brave = true
						state:AddFeed("👊 You got beat up, but you stood your ground. Respect earned.")
					end
				end,
			},
			{ text = "Verbally confront the bully", effects = { Happiness = 5 }, setFlags = { stands_up_to_bullies = true }, feedText = "You defended them with words. It took courage." },
			{ text = "Report it to a teacher", effects = { Smarts = 2 }, setFlags = { reports_wrongdoing = true }, feedText = "You told an adult. They handled it." },
			{ text = "Stay out of it", effects = { Happiness = -4 }, setFlags = { bystander = true }, feedText = "You did nothing. That guilt stays." },
			{ text = "Befriend the victim later", effects = { Happiness = 3 }, setFlags = { kind = true }, feedText = "You checked on them afterward. They appreciated it." },
		},
	},
	{
		id = "teen_college_rejection",
		title = "College Decision",
		emoji = "📬",
		text = "You got a response from a college you applied to!",
		question = "What does the letter say?",
		minAge = 17, maxAge = 18,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresFlags = { college_bound = true },
		
		-- CRITICAL FIX: Random college decision outcome based on stats!
		choices = {
			{
				text = "Open the letter from your dream school",
				effects = {},
				feedText = "You nervously opened the envelope...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local acceptChance = 0.25 + (smarts / 150)
					if state.Flags and state.Flags.academic_path then acceptChance = acceptChance + 0.15 end
					if state.Flags and state.Flags.scholarship_winner then acceptChance = acceptChance + 0.10 end
					if state.Flags and state.Flags.ivy_aspirations then acceptChance = acceptChance - 0.10 end
					
					if roll < acceptChance then
						state:ModifyStat("Happiness", 20)
						state.Flags = state.Flags or {}
						state.Flags.accepted_dream_school = true
						state:AddFeed("📬 ACCEPTED to your dream school!! This is incredible!")
					elseif roll < acceptChance + 0.25 then
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.waitlisted = true
						state:AddFeed("📬 Waitlisted. There's still hope!")
					else
						state:ModifyStat("Happiness", -10)
						state:AddFeed("📬 Rejected. It stings. But there are other options.")
					end
				end,
			},
			{
				text = "Open the safety school letter",
				effects = {},
				feedText = "The backup plan...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.85 then
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.accepted_safety_school = true
						state:AddFeed("📬 Accepted to your safety school! Good backup.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📬 Even the safety school rejected you. Time to reconsider plans.")
					end
				end,
			},
			{ text = "Too scared to open it yet", effects = { Happiness = -3 }, feedText = "The unopened letter is haunting you." },
		},
	},
	{
		id = "teen_volunteer_impact",
		title = "Making a Difference",
		emoji = "🌟",
		text = "Your volunteer work is really making an impact in the community!",
		question = "How do you feel about your contribution?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		requiresFlags = { volunteer = true },
		
		choices = {
			{ text = "Inspired to do even more", effects = { Happiness = 8 }, setFlags = { dedicated_volunteer = true }, feedText = "You're making a real difference!" },
			{ text = "Proud but it's a lot of work", effects = { Happiness = 4, Health = -2 }, feedText = "Rewarding but exhausting." },
			{ text = "Considering a career helping others", effects = { Happiness = 6, Smarts = 2 }, setFlags = { wants_to_help = true }, hintCareer = "medical", feedText = "Maybe this is your calling?" },
			{ text = "Need a break from volunteering", effects = { Happiness = 2, Health = 2 }, setFlags = { volunteer = false }, feedText = "Stepping back for self-care." },
		},
	},
	{
		id = "teen_sports_injury",
		title = "Sports Injury",
		emoji = "🤕",
		text = "You got injured during practice or a game!",
		question = "How serious is it?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresFlags = { varsity_athlete = true },
		
		-- CRITICAL FIX: Random injury severity
		choices = {
			{
				text = "Wait for the doctor's diagnosis",
				effects = {},
				feedText = "The medical staff examines you...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Health", -3)
						state:AddFeed("🤕 Minor sprain. Rest for a week and you'll be fine.")
					elseif roll < 0.75 then
						state:ModifyStat("Health", -8)
						state:ModifyStat("Happiness", -4)
						state.Flags = state.Flags or {}
						state.Flags.injured = true
						state:AddFeed("🤕 Moderate injury. Out for the rest of the season.")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.seriously_injured = true
						state.Flags.varsity_athlete = nil
						state:AddFeed("🤕 Serious injury. Your athletic career might be affected.")
					end
				end,
			},
			{ text = "Try to play through the pain", effects = { Health = -10, Happiness = -3 }, setFlags = { plays_through_pain = true }, feedText = "You made it worse. Should have stopped." },
			{ text = "Rest immediately and recover", effects = { Health = -5, Smarts = 2 }, feedText = "Smart decision. Rest will help." },
		},
	},
	{
		id = "teen_music_taste",
		title = "Musical Identity",
		emoji = "🎵",
		text = "You've really developed your musical taste!",
		question = "What kind of music defines you?",
		minAge = 13, maxAge = 17,
		oneTime = true,
		baseChance = 0.45,
		
		choices = {
			{ text = "Hip-hop and rap", effects = { Happiness = 4 }, setFlags = { likes_hiphop = true }, feedText = "The beats and lyrics speak to you." },
			{ text = "Rock and alternative", effects = { Happiness = 4 }, setFlags = { likes_rock = true }, feedText = "Guitar riffs are your thing." },
			{ text = "Pop music", effects = { Happiness = 4 }, setFlags = { likes_pop = true }, feedText = "Catchy hooks and big productions!" },
			{ text = "Electronic and EDM", effects = { Happiness = 4 }, setFlags = { likes_edm = true }, feedText = "The bass drops hit different." },
			{ text = "Everything - can't pick just one", effects = { Happiness = 5, Smarts = 1 }, setFlags = { eclectic_taste = true }, feedText = "Music is music. You appreciate it all." },
		},
	},
	{
		id = "teen_internet_argument",
		title = "Internet Debate",
		emoji = "💻",
		text = "You're in a heated argument with someone online.",
		question = "How do you handle it?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		choices = {
			{ 
				text = "🎤 DESTROY them with FACTS!", 
				effects = {},
				feedText = "You engaged in debate...",
				-- CRITICAL FIX: Debate minigame for internet arguments!
				triggerMinigame = "debate",
				minigameOptions = { difficulty = "easy", context = "internet", title = "💻 ONLINE ARGUMENT" },
				onResolve = function(state, minigameResult)
					local won = minigameResult and (minigameResult.success or minigameResult.won)
					if won then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.debate_champion = true
						state:AddFeed("🎤 You absolutely DESTROYED them! Screenshot saved. Victory!")
					else
						state:ModifyStat("Happiness", -6)
						state:ModifyStat("Health", -2)
						state.Flags = state.Flags or {}
						state.Flags.internet_warrior = true
						state:AddFeed("💻 You lost the argument. They screenshotted your L. Embarrassing.")
					end
				end,
			},
			{ text = "Block and move on", effects = { Happiness = 3 }, setFlags = { knows_when_to_stop = true }, feedText = "Not worth your energy. Smart." },
			{ text = "Actually have a productive conversation", effects = { Happiness = 4, Smarts = 3 }, setFlags = { good_communicator = true }, feedText = "Rare achievement: civil internet discourse!" },
			{ text = "Let friends handle it", effects = { Happiness = 2 }, feedText = "Your friends jumped in. Chaotic but entertaining." },
		},
	},
	{
		id = "teen_fashion_evolution",
		title = "Style Evolution",
		emoji = "👕",
		text = "You're experimenting with your personal style!",
		question = "What style are you going for?",
		minAge = 13, maxAge = 17,
		oneTime = true,
		baseChance = 0.35,
		
		choices = {
			{ text = "Trendy and fashion-forward ($100)", effects = { Looks = 5, Money = -100 }, setFlags = { fashionista = true }, feedText = "Always on top of the latest trends!",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Trendy clothes cost $100!" end,
			},
			{ text = "Athletic and casual", effects = { Looks = 2, Health = 2 }, setFlags = { sporty_style = true }, feedText = "Comfort and function first." },
			{ text = "Alternative and unique", effects = { Looks = 3, Happiness = 4 }, setFlags = { alternative_style = true }, feedText = "You march to your own beat." },
			{ text = "Classic and understated", effects = { Looks = 3, Smarts = 2 }, setFlags = { classic_style = true }, feedText = "Timeless and sophisticated." },
			{ text = "Whatever's clean", effects = { Happiness = 2 }, feedText = "Fashion? More like comfortable." },
		},
	},
	{
		id = "teen_sibling_dynamic",
		title = "Sibling Situation",
		emoji = "👫",
		text = "Your relationship with your sibling is evolving as you both get older.",
		question = "How is it going?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		requiresFlags = { has_younger_sibling = true },
		
		choices = {
			{ text = "We're actually getting closer", effects = { Happiness = 6 }, setFlags = { close_with_sibling = true }, feedText = "The sibling bond is strengthening!" },
			{ text = "Constant fighting", effects = { Happiness = -4 }, setFlags = { sibling_rivalry = true }, feedText = "Can't be in the same room without drama." },
			{ text = "Teaching them things", effects = { Happiness = 4, Smarts = 2 }, setFlags = { mentors_sibling = true }, feedText = "You're passing down your wisdom!" },
			{ text = "We just ignore each other", effects = { Happiness = 1 }, feedText = "Coexisting peacefully through avoidance." },
		},
	},
	{
		id = "teen_late_night_studying",
		title = "All-Nighter",
		emoji = "🌙",
		text = "You have a huge test tomorrow and you're not prepared.",
		question = "How do you approach tonight?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		-- CRITICAL FIX: Random test outcome based on study approach
		choices = {
			{
				text = "Pull an all-nighter studying",
				effects = { Health = -5 },
				feedText = "You stayed up all night cramming...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🌙 The all-nighter paid off! You aced the test!")
					elseif roll < 0.70 then
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🌙 Passed, but barely. So tired.")
					else
						state:ModifyStat("Smarts", -2)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🌙 Fell asleep during the test. The all-nighter backfired.")
					end
				end,
			},
			{
				text = "Study until midnight then sleep",
				effects = { Health = -2 },
				feedText = "Balanced approach...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local passChance = 0.50 + (smarts / 150)
					if roll < passChance then
						state:ModifyStat("Smarts", 4)
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🌙 Rested brain worked better! Good grade!")
					else
						state:ModifyStat("Smarts", 1)
						state:AddFeed("🌙 Could have studied more, but you passed.")
					end
				end,
			},
			{
				text = "Wing it - how bad could it be?",
				effects = {},
				feedText = "You showed up hoping for the best...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if smarts > 70 and roll < 0.40 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🌙 Your natural smarts carried you! Somehow did well!")
					elseif roll < 0.25 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🌙 Got lucky with easy questions!")
					else
						state:ModifyStat("Smarts", -3)
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🌙 Bombed the test. Should have studied.")
					end
				end,
			},
			{ text = "Accept the L", effects = { Smarts = -2, Happiness = -3 }, feedText = "You didn't even try. That zero hurts." },
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #87: TALENT DISCOVERY EVENTS
	-- These events help players discover talents that can lead to Celebrity careers
	-- Requires Celebrity gamepass for full career options
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "talent_discovery",
		title = "Hidden Talent!",
		emoji = "⭐",
		text = "During a school event, you discover you might have a hidden talent! People are taking notice.",
		question = "What talent did you discover?",
		minAge = 13, maxAge = 16,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		
		choices = {
			{
				text = "Acting - you're a natural performer",
				effects = { Happiness = 10, Looks = 3 },
				setFlags = { talent_acting = true, drama_kid = true, natural_performer = true },
				feedText = "You have a gift for acting! The drama teacher wants you for the lead role.",
				fameEffect = { fame = 2 },
			},
			{
				text = "Singing - your voice is amazing",
				effects = { Happiness = 10 },
				setFlags = { talent_singing = true, choir_member = true, gifted_voice = true },
				feedText = "Your voice gave everyone chills. You could be a star!",
				fameEffect = { fame = 2 },
			},
			{
				text = "Dancing - moves like nobody else",
				effects = { Happiness = 10, Health = 3 },
				setFlags = { talent_dancing = true, dance_team = true, natural_dancer = true },
				feedText = "Your dancing left everyone speechless!",
				fameEffect = { fame = 2 },
			},
			{
				text = "Sports - athletic prodigy",
				effects = { Happiness = 10, Health = 5 },
				setFlags = { talent_sports = true, athletic_prodigy = true, varsity_potential = true },
				feedText = "Scouts are already keeping an eye on you!",
				fameEffect = { fame = 2 },
			},
		{
			text = "Content creation - you love making videos",
			effects = { Happiness = 8, Smarts = 3 },
			setFlags = { talent_social = true, content_creator = true },
			feedText = "You discovered a love for creating content!",
			-- CRITICAL FIX: Player can't DECIDE to go viral - that's random!
			-- They can only discover they like content creation. Going viral happens later randomly.
			onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.talent_social = true
				state.Flags.content_creator = true
				-- Small chance they actually go viral (not guaranteed!)
				local roll = math.random(1, 100)
				if roll <= 15 then
					state.Fame = math.min(100, (state.Fame or 0) + 5)
					state.Flags.viral_content = true
					state:AddFeed("⭐ Your content actually went viral! This could be big!")
				else
					state:AddFeed("⭐ You love making content! Who knows where this could lead...")
				end
			end,
		},
		},
	},
	{
		id = "fame_audition",
		title = "Big Audition Opportunity!",
		emoji = "🎬",
		text = "A talent scout noticed you! They want you to audition for a real opportunity.",
		question = "This could change everything. Do you go for it?",
		minAge = 14, maxAge = 18,
		oneTime = true,
		requiresAnyFlags = { talent_acting = true, talent_singing = true, talent_dancing = true, natural_performer = true },
		
		choices = {
			{
				text = "Go all in! This is your dream!",
				effects = { Happiness = 5 },
				successChance = 50,
				successEffects = { Happiness = 20 },
				successFeed = "🌟 YOU GOT THE PART! This is the beginning of something huge!",
				successFame = 10,
				failEffects = { Happiness = -10 },
				failFeed = "😔 They went with someone else. Keep trying though!",
				failFame = 1,
				setFlags = { auditioned_professionally = true },
			},
			{
				text = "Prepare carefully first",
				effects = { Smarts = 3, Happiness = 3 },
				successChance = 65,
				successEffects = { Happiness = 15 },
				successFeed = "🌟 Your preparation paid off! You got a callback!",
				successFame = 8,
				failEffects = { Happiness = -5 },
				failFeed = "📝 Not this time, but they loved your professionalism.",
				failFame = 2,
				setFlags = { auditioned_professionally = true, prepared_audition = true },
			},
			{
				text = "Too nervous - maybe next time",
				effects = { Happiness = -5 },
				setFlags = { missed_opportunity = true },
				feedText = "You passed on the opportunity. There'll be other chances... right?",
			},
			{
				text = "Focus on school instead",
				effects = { Smarts = 5, Happiness = -3 },
				setFlags = { chose_education = true },
				feedText = "Fame can wait. Education comes first.",
			},
		},
	},
	{
		id = "school_talent_show",
		title = "School Talent Show",
		emoji = "🎤",
		text = "The annual talent show is coming up. Everyone's talking about who's going to perform.",
		question = "Do you sign up?",
		minAge = 13, maxAge = 17,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		choices = {
			{
				text = "Sign up and perform your heart out!",
				effects = { Happiness = 8 },
				successChance = 60,
				successEffects = { Happiness = 15, Looks = 2 },
				successFeed = "🌟 STANDING OVATION! You won the talent show!",
				successFame = { fame = 3 },
				failEffects = { Happiness = -8, Looks = -1 },
				failFeed = "😅 You forgot your lines/lyrics/steps. Everyone saw. Mortifying.",
				setFlags = { performed_publicly = true },
			},
			{
				text = "Help backstage instead",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { stage_crew = true },
				feedText = "You helped make the show happen. The performers thanked you!",
			},
			{
				text = "Just watch from the audience",
				effects = { Happiness = 2 },
				feedText = "Some great performances! Maybe next year you'll try.",
			},
			{
				text = "Skip it entirely",
				effects = { Happiness = 1 },
				feedText = "Talent shows aren't your thing.",
			},
		},
	},
	{
		-- CRITICAL FIX: Renamed from "viral_moment" to avoid duplicate ID with Adult.lua/CelebrityEvents.lua
		id = "teen_filmed_viral",
		title = "Your Video Went VIRAL!",
		emoji = "📱",
		text = "Someone filmed you doing something and posted it online. It's blowing up!",
		question = "What kind of viral moment was it?",
		minAge = 13, maxAge = 17,
		baseChance = 0.455,
		oneTime = true,
		
		choices = {
			{
				text = "An amazing talent display",
				effects = { Happiness = 15 },
				setFlags = { viral_talent = true, internet_famous = true },
				feedText = "🔥 10 million views! Brands are reaching out!",
				fameEffect = { fame = 8, followers = 50000 },
			},
			{
				text = "A hilarious fail",
				effects = { Happiness = -5, Looks = -3 },
				setFlags = { viral_fail = true, meme_material = true },
				feedText = "😅 You're famous... for all the wrong reasons.",
				fameEffect = { fame = 5, followers = 20000 },
			},
			{
				text = "A heartwarming moment",
				effects = { Happiness = 12 },
				setFlags = { viral_wholesome = true },
				feedText = "🥰 People love you! You're trending for being a good person.",
				fameEffect = { fame = 6, followers = 30000 },
			},
			{
				text = "Delete the video immediately",
				effects = { Happiness = 3 },
				feedText = "You asked them to take it down. Privacy preserved.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #455: EXPANDED TEEN EVENTS
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- DATING DRAMA
	{
		id = "teen_dating_drama",
		title = "Dating Drama",
		emoji = "💔",
		text = "Your crush started dating someone else. Your friends are expecting a reaction.",
		question = "How do you handle this?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 3,
		choices = {
			{
				text = "Act like you don't care",
				effects = { Happiness = -5 },
				setFlags = { plays_it_cool = true },
				feedText = "You played it cool, but inside it hurts.",
			},
			{
				text = "Express your feelings honestly",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { emotionally_mature = true },
				feedText = "That took courage. You feel better for being honest.",
			},
			{
				text = "Try to break them up",
				effects = { Happiness = 5 },
				setFlags = { drama_starter = true },
				feedText = "This is going to get messy...",
			},
			{
				text = "Focus on self-improvement",
				effects = { Happiness = 10, Health = 5 },
				setFlags = { self_focused = true },
				feedText = "You hit the gym and focused on yourself. Good choice!",
			},
		},
	},
	
	-- PART-TIME JOB OFFER
	{
		id = "teen_first_job_offer",
		title = "First Job Offer!",
		emoji = "💼",
		text = "A local business is looking for part-time help. They want to hire you!",
		question = "What do you do?",
		minAge = 15, maxAge = 17,
		baseChance = 0.555,
		oneTime = true,
		maxOccurrences = 1,
		blockedByFlags = { has_part_time_job = true },
		choices = {
			{
				text = "Take the job eagerly",
				effects = { Happiness = 10, Money = 200 },
				setFlags = { has_part_time_job = true, hardworker = true },
				feedText = "Your first paycheck! It's not much, but it's honest work.",
			},
			{
				text = "Negotiate for better hours",
				effects = { Happiness = 8, Money = 200, Smarts = 3 },
				setFlags = { has_part_time_job = true, negotiator = true },
				feedText = "They agreed to flexible hours! Smart move.",
			},
			{
				text = "Decline - too busy with school",
				effects = { Happiness = -3, Smarts = 5 },
				feedText = "School comes first. Your grades thank you.",
			},
			{
				text = "Decline - too busy with friends",
				effects = { Happiness = 5 },
				feedText = "Work can wait. You're enjoying your youth.",
			},
		},
	},
	
	-- HOUSE PARTY
	{
		id = "teen_house_party",
		title = "House Party!",
		emoji = "🎉",
		text = "Someone's parents are out of town. There's a huge party happening tonight!",
		question = "Are you going?",
		minAge = 15, maxAge = 17,
		baseChance = 0.35,
		cooldown = 3,
		maxOccurrences = 5,
		choices = {
			{
				text = "Go and have a blast",
				effects = { Happiness = 15, Health = -5 },
				setFlags = { party_animal = true },
				feedText = "Best night ever! You made memories (and maybe some mistakes).",
			},
			{
				text = "Go but stay responsible",
				effects = { Happiness = 8 },
				setFlags = { responsible_fun = true },
				feedText = "You had fun but stayed smart. Good balance!",
			},
			{
				text = "Stay home - not worth the risk",
				effects = { Happiness = -5 },
				feedText = "FOMO is real, but so are consequences.",
			},
			{
				text = "Tell parents and get it shut down",
				effects = { Happiness = -10 },
				setFlags = { snitch = true },
				feedText = "You did the 'right' thing. No one's talking to you now.",
			},
		},
	},
	
	-- GETTING CAUGHT
	{
		id = "teen_caught_sneaking",
		title = "Caught!",
		emoji = "😱",
		text = "Your parents caught you sneaking back into the house at 3 AM!",
		question = "What's your excuse?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 3,
		choices = {
			{
				text = "Tell the truth",
				effects = { Happiness = -5, Smarts = 5 },
				setFlags = { honest_teen = true },
				feedText = "Grounded for a week, but they respect your honesty.",
			},
			{
				text = "Make up an elaborate lie",
				effects = { Happiness = 5 },
				setFlags = { good_liar = true },
				feedText = "They... actually believed it? You're good at this.",
			},
			{
				text = "Blame it on a friend",
				effects = { Happiness = 3 },
				setFlags = { throws_friends = true },
				feedText = "Your friend is taking the heat for you. Yikes.",
			},
			{
				text = "Say nothing and accept the punishment",
				effects = { Happiness = -10 },
				feedText = "Silence. Two weeks grounded. Worth it.",
			},
		},
	},
	
	-- ACADEMIC CHALLENGE
	{
		id = "teen_ap_classes",
		title = "Advanced Classes",
		emoji = "📚",
		text = "You've been offered a spot in Advanced Placement classes. They're harder but look great for college.",
		question = "Do you take the challenge?",
		minAge = 15, maxAge = 17,
		baseChance = 0.4,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { minSmarts = 60 },
		choices = {
			{
				text = "Accept all available AP classes",
				effects = { Happiness = -5, Smarts = 15 },
				setFlags = { ap_student = true, overachiever = true },
				feedText = "It's brutal, but you're learning so much!",
			},
			{
				text = "Take just one or two",
				effects = { Smarts = 8 },
				setFlags = { ap_student = true },
				feedText = "A balanced approach. Challenging but manageable.",
			},
			{
				text = "Decline - stay in regular classes",
				effects = { Happiness = 5 },
				feedText = "Less stress, more time for yourself.",
			},
		},
	},
	
	-- DRIVER'S LICENSE
	{
		id = "teen_drivers_license",
		title = "Driver's License!",
		emoji = "🚗",
		text = "You finally turned 16 and can get your driver's license! Time for the test.",
		question = "How does the test go?",
		minAge = 16, maxAge = 17,
		baseChance = 0.45, -- CRITICAL FIX: Reduced from 0.9 - other driving events exist
		oneTime = true,
		maxOccurrences = 1,
		category = "milestone",
		tags = { "driving", "license", "milestone" },
		-- CRITICAL FIX: Block if already have license from ANY driving event
		blockedByFlags = { has_license = true, drivers_license = true, driver_license = true, has_drivers_license = true, learned_driving = true, driving_done = true },
		choices = {
			{
				text = "Nail it perfectly!",
				effects = { Happiness = 20 },
				-- CRITICAL FIX: Set ALL license flags via onResolve for compatibility
				setFlags = { has_license = true, good_driver = true, drivers_license = true, driver_license = true, has_drivers_license = true, learned_driving = true },
				feedText = "🚗 You passed! Freedom awaits!",
			},
			{
				text = "Pass, but barely",
				effects = { Happiness = 12 },
				-- CRITICAL FIX: Set ALL license flags via onResolve for compatibility
				setFlags = { has_license = true, drivers_license = true, driver_license = true, has_drivers_license = true, learned_driving = true },
				feedText = "🚗 A pass is a pass! You got your license!",
			},
			{
				text = "Fail miserably",
				effects = { Happiness = -15 },
				setFlags = { failed_driving_test = true, learned_driving = true },
				feedText = "😬 You ran over three cones and a sign. Maybe next time.",
			},
			{
				text = "Too nervous - reschedule",
				effects = { Happiness = -5 },
				feedText = "Anxiety got the best of you. There's always next month.",
			},
		},
	},
	
	-- SOCIAL MEDIA DRAMA - MESSAGES LEAKED
	{
		id = "teen_messages_leaked", -- CRITICAL FIX: Renamed from duplicate teen_social_media_drama
		title = "Messages Leaked!",
		emoji = "📱",
		text = "Someone screenshot your private messages and shared them publicly. People are talking.",
		question = "How do you handle this?",
		minAge = 13, maxAge = 17,
		baseChance = 0.45, -- CRITICAL FIX: Reduced from 0.555 to prevent spam
		cooldown = 5, -- CRITICAL FIX: Increased from 4 to reduce spam
		maxOccurrences = 1, -- CRITICAL FIX: Only happens once
		blockedByFlags = { in_prison = true, dropped_out_high_school = true, messages_leaked_done = true },
		choices = {
			{
				text = "Address it publicly and own it",
				effects = { Happiness = 5 },
				setFlags = { owns_mistakes = true },
				feedText = "You faced it head-on. People respect that.",
			},
			{
				text = "Go completely offline for a while",
				effects = { Happiness = -10, Health = 5 },
				setFlags = { digital_detox = true },
				feedText = "The break was needed. You feel more centered.",
			},
			{
				text = "Clap back and start a war",
				effects = { Happiness = -5 },
				setFlags = { clap_back_king = true },
				feedText = "This is getting ugly. But you're winning.",
			},
		{
			text = "Have your parents intervene",
			effects = { Happiness = -15 },
			setFlags = { parents_involved = true },
			feedText = "It stopped, but now you're 'that kid.'",
		},
	},
},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: MORE SUPER ENGAGING TEEN EVENTS
	-- Making teen years more exciting and memorable!
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_viral_moment",
		title = "You're Going VIRAL!",
		emoji = "🔥",
		text = "A video of you just went VIRAL! Thousands of views and climbing!",
		question = "What happened?!",
		minAge = 13, maxAge = 18,
		baseChance = 0.35,
		cooldown = 4,
		oneTime = true,
		priority = "high",
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #605: Viral events REQUIRE player to have actually posted content!
		-- User complaint: "Video went viral but I never posted any videos"
		-- A video of you can only go viral if you've been posting/creating content
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Player MUST have some form of content creation or social media activity!
			local hasCreatedContent = flags.content_creator or flags.streamer or flags.influencer
				or flags.first_video_posted or flags.first_video_uploaded or flags.youtube_started
				or flags.social_media_active or flags.pursuing_streaming or flags.youtube_channel
				or flags.gaming_content or flags.vlogger or flags.social_media_star or flags.talent_social
			if not hasCreatedContent then
				return false, "Player hasn't created any content yet"
			end
			return true
		end,
		
		choices = {
			{
				text = "An awesome talent video!",
				effects = {},
				feedText = "Your talent caught the internet's attention...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 65 then
						state.Flags.went_viral = true
						state.Flags.internet_famous = true
						state:ModifyStat("Happiness", 20)
						state:ModifyStat("Looks", 3)
						state:AddFeed("🔥 Your video hit 1 MILLION views! You're internet famous! Agents are calling!")
					else
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🔥 It got 50K views! Not mega-viral but still cool!")
					end
				end,
			},
			{
				text = "A hilarious fail video!",
				effects = {},
				feedText = "Your embarrassing moment is everywhere...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 50 then
						state.Flags.went_viral = true
						state.Flags.meme_kid = true
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🔥 You became a MEME! Everyone at school knows you now!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🔥 It was embarrassing but people forgot pretty quickly.")
					end
				end,
			},
			{
				text = "Standing up for something important!",
				effects = {},
				feedText = "Your message resonated with people...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.went_viral = true
					state.Flags.activist = true
					state:ModifyStat("Happiness", 15)
					state:ModifyStat("Smarts", 3)
					state:AddFeed("🔥 Your video inspired thousands! You're making a difference!")
				end,
			},
		},
	},
	{
		id = "teen_secret_party",
		title = "SECRET PARTY INVITE!",
		emoji = "🎉",
		text = "You got invited to THE party of the year! But your parents said NO going out tonight...",
		question = "What do you do?",
		minAge = 14, maxAge = 17,
		baseChance = 0.5,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		
		choices = {
			{
				text = "SNEAK OUT! You only live once!",
				effects = {},
				feedText = "You climb out your window at midnight...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 40 then
						state.Flags.party_legend = true
						state:ModifyStat("Happiness", 18)
						state:AddFeed("🎉 LEGENDARY NIGHT! Made out with your crush! Home safe before sunrise!")
					elseif roll <= 70 then
						state:ModifyStat("Happiness", 12)
						state:AddFeed("🎉 Amazing party! And you got away with it!")
					else
						state.Flags.grounded = true
						state:ModifyStat("Happiness", -10)
						state:AddFeed("🎉 You got CAUGHT sneaking back in. GROUNDED for a month!")
					end
				end,
			},
			{
				text = "Stay home - not worth the risk",
				effects = { Happiness = -5 },
				setFlags = { rule_follower = true },
				feedText = "FOMO is real but you stayed put. Your parents appreciated it.",
			},
			{
				text = "Convince your parents to let you go!",
				effects = {},
				feedText = "You make your best case...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					if roll <= 45 then
						state:ModifyStat("Happiness", 15)
						state:AddFeed("🎉 They said YES! Best party ever, and no guilt!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🎉 They said no, but at least you tried the honest way.")
					end
				end,
			},
		},
	},
	{
		id = "teen_talent_discovered",
		title = "HIDDEN TALENT!",
		emoji = "✨",
		text = "You just discovered you have an AMAZING talent you never knew about!",
		question = "What is your hidden talent?",
		minAge = 12, maxAge = 17,
		baseChance = 0.45,
		cooldown = 99,
		oneTime = true,
		priority = "high",
		
		choices = {
			{
				text = "Amazing singer/musician!",
				effects = { Happiness = 12 },
				setFlags = { musical_talent = true, talented_singer = true },
				feedText = "🎤 Your voice is INCREDIBLE! People are amazed!",
			},
			{
				text = "Athletic superstar potential!",
				effects = { Happiness = 10, Health = 5 },
				setFlags = { athletic_talent = true, sports_potential = true },
				feedText = "🏆 You have natural athletic ability! Coaches want you on their team!",
			},
			{
				text = "Artistic genius!",
				effects = { Happiness = 11, Smarts = 2 },
				setFlags = { artistic_talent = true, creative_genius = true },
				feedText = "🎨 Your art is STUNNING! People want to buy your work!",
			},
			{
				text = "Tech/coding prodigy!",
				effects = { Happiness = 10, Smarts = 5 },
				setFlags = { tech_talent = true, coding_prodigy = true },
				feedText = "💻 You built an app in a weekend! Tech companies are interested!",
			},
		},
	},
	{
		id = "teen_first_real_relationship",
		title = "OFFICIAL Relationship!",
		emoji = "❤️",
		text = "Someone asked you to be their boyfriend/girlfriend! This is REAL!",
		question = "How do you feel about this?",
		minAge = 14, maxAge = 18,
		baseChance = 0.45,
		cooldown = 3,
		
		choices = {
			{
				text = "SO EXCITED! Say yes!",
				effects = {},
				feedText = "You're in a relationship now...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					state.Flags.in_relationship = true
					if roll <= 60 then
						state:ModifyStat("Happiness", 18)
						state:AddFeed("❤️ Best relationship EVER! You're so happy together!")
					else
						state:ModifyStat("Happiness", 10)
						state:AddFeed("❤️ It's nice to have someone. Still figuring things out!")
					end
				end,
			},
			{
				text = "Say yes, but keep it chill",
				effects = { Happiness = 8 },
				setFlags = { in_relationship = true, casual_dater = true },
				feedText = "Low-key relationship vibes. Works for you!",
			},
			{
				text = "Actually... I'm not ready",
				effects = { Happiness = 2, Smarts = 2 },
				setFlags = { knows_themselves = true },
				feedText = "You know what you want. Respectable.",
			},
		},
	},
	{
		id = "teen_school_competition_win",
		title = "You WON!",
		emoji = "🏆",
		text = "You entered a school competition... and you WON!",
		question = "What did you win?",
		minAge = 13, maxAge = 18,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		category = "school",
		tags = { "competition", "achievement", "school" },
		blockedByFlags = { in_prison = true, dropped_out_high_school = true },
		
		choices = {
			{
				text = "Science Fair - First Place!",
				effects = { Smarts = 8, Happiness = 12 },
				setFlags = { science_fair_winner = true, academic_achiever = true },
				feedText = "🏆 Your project impressed the judges! Scholarship offers are coming!",
			},
			{
				text = "Sports Championship!",
				effects = { Health = 6, Happiness = 15, Looks = 2 },
				setFlags = { sports_champion = true },
				feedText = "🏆 MVP! The crowd went WILD! Colleges are scouting you!",
			},
			{
				text = "Art/Music Competition!",
				effects = { Happiness = 14, Looks = 3 },
				setFlags = { art_competition_winner = true },
				feedText = "🏆 Your creativity shined! Local newspaper did a story on you!",
			},
			{
				text = "Debate/Speech Competition!",
				effects = { Smarts = 6, Happiness = 11 },
				setFlags = { debate_champion = true, public_speaker = true },
				feedText = "🏆 You destroyed the competition! Natural leader material!",
			},
		},
	},

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: NEW ENGAGING TEEN EVENTS FOR VARIETY
	-- These events keep teens hooked and create memorable stories
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_secret_revealed",
		title = "🤫 The Secret",
		emoji = "🤫",
		text = "Someone at school just found out a secret about you! It's spreading fast...",
		question = "What's the secret?",
		minAge = 13, maxAge = 18,
		baseChance = 0.2,
		cooldown = 10,
		oneTime = true,
		category = "social",
		tags = { "drama", "social", "secret" },
		blockedByFlags = { in_prison = true, dropped_out_high_school = true },
		
		choices = {
			{
				text = "An embarrassing crush",
				effects = { Happiness = -10 },
				feedText = "Oh no. Everyone knows now...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.3 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.crush_likes_back = true
						state:AddFeed("😊 Plot twist! Your crush heard and... THEY LIKE YOU BACK!")
					elseif roll < 0.6 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("😅 It's awkward for a week, then everyone moves on. High school!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("😢 People are teasing you. It'll blow over eventually...")
					end
				end,
			},
			{
				text = "Something you lied about",
				effects = { Happiness = -12 },
				feedText = "The truth comes out...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.4 then
						state:ModifyStat("Smarts", 3)
						state:AddFeed("🤔 You learned your lesson. Honesty is easier in the long run.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.reputation_damaged = true
						state:AddFeed("😔 Trust takes time to rebuild. People are watching you now.")
					end
				end,
			},
			{
				text = "A hidden talent",
				effects = { Happiness = 5 },
				feedText = "People found out you're actually really good at something!",
				onResolve = function(state)
					state:ModifyStat("Happiness", 10)
					state.Flags = state.Flags or {}
					state.Flags.talent_discovered = true
					state:AddFeed("✨ Your secret talent is out! Now everyone wants you to perform!")
				end,
			},
		},
	},
	{
		id = "teen_viral_video",
		title = "📱 You Went Viral!",
		emoji = "📱",
		text = "A video of you is spreading like wildfire on social media!",
		question = "What kind of video is it?",
		minAge = 13, maxAge = 18,
		baseChance = 0.15,
		cooldown = 15,
		oneTime = true,
		category = "social",
		tags = { "viral", "social_media", "fame" },
		blockedByFlags = { in_prison = true, went_teen_viral = true },
		
		choices = {
			{
				text = "Something impressive you did",
				effects = { Happiness = 20, Looks = 3 },
				setFlags = { went_teen_viral = true, internet_famous = true },
				feedText = "The whole school knows!",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.4 then
						state.Money = (state.Money or 0) + 500
						state:AddFeed("📱 MILLIONS of views! Brand deals are rolling in! +$500!")
					else
						state:AddFeed("📱 Everyone thinks you're COOL now! Popularity skyrocketed!")
					end
				end,
			},
			{
				text = "An embarrassing moment",
				effects = { Happiness = -15 },
				setFlags = { went_teen_viral = true, viral_embarrassment = true },
				feedText = "No. No no no...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.3 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("📱 You owned it! Made a comeback video. People respect the confidence!")
					else
						state:AddFeed("📱 This will be your villain origin story. Never living this down.")
					end
				end,
			},
			{
				text = "A random funny thing",
				effects = { Happiness = 15 },
				setFlags = { went_teen_viral = true, meme_famous = true },
				feedText = "Wait what? This blew up?!",
				onResolve = function(state)
					state:AddFeed("📱 You're a MEME! People quote you in the halls! Weird but cool!")
				end,
			},
		},
	},
	{
		id = "teen_unexpected_friendship",
		title = "🤝 Unlikely Friends",
		emoji = "🤝",
		text = "You ended up becoming friends with someone completely unexpected...",
		question = "Who became your new friend?",
		minAge = 13, maxAge = 18,
		baseChance = 0.25,
		cooldown = 8,
		oneTime = true,
		category = "social",
		tags = { "friendship", "social", "growth" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "The popular kid",
				effects = { Happiness = 12, Looks = 2 },
				setFlags = { popular_friend = true },
				feedText = "Social upgrade unlocked!",
				onResolve = function(state)
					state:AddFeed("🤝 They're actually really down to earth! Your social life just leveled up!")
				end,
			},
			{
				text = "The 'weird' kid everyone avoids",
				effects = { Happiness = 10, Smarts = 3 },
				setFlags = { kind_soul = true, unconventional_friend = true },
				feedText = "You looked past the surface...",
				onResolve = function(state)
					state:AddFeed("🤝 They're FASCINATING! Most interesting person you've met. Best decision ever.")
				end,
			},
			{
				text = "Someone from a different grade",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { diverse_friendships = true },
				feedText = "Age is just a number!",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.5 then
						state:AddFeed("🤝 They give the BEST advice about surviving the grades above!")
					else
						state:AddFeed("🤝 Different perspective on life. Your worldview expanded!")
					end
				end,
			},
			{
				text = "A teacher's kid",
				effects = { Happiness = 6, Smarts = 4 },
				setFlags = { teacher_connection = true },
				feedText = "Inside access to teacher secrets!",
				onResolve = function(state)
					state:AddFeed("🤝 You now know which teachers are actually cool. Strategic friendship!")
				end,
			},
		},
	},
	{
		id = "teen_defining_moment",
		title = "⭐ Defining Moment",
		emoji = "⭐",
		text = "Something happened today that you know you'll remember forever...",
		question = "What was the moment?",
		minAge = 14, maxAge = 18,
		baseChance = 0.2,
		cooldown = 12,
		oneTime = true,
		category = "milestone",
		tags = { "growth", "memory", "milestone" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "Standing up to a bully",
				effects = { Happiness = 15, Health = 2 },
				setFlags = { stood_up_to_bully = true, brave = true },
				feedText = "Today you found your courage.",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.6 then
						state:AddFeed("⭐ They backed down. You're not afraid anymore. Others look up to you now.")
					else
						state:ModifyStat("Health", -5)
						state:AddFeed("⭐ It didn't go perfectly, but you did the right thing. That matters.")
					end
				end,
			},
			{
				text = "Helping someone in need",
				effects = { Happiness = 18, Smarts = 2 },
				setFlags = { helper = true, kind_soul = true },
				feedText = "You made a real difference.",
				onResolve = function(state)
					state:AddFeed("⭐ They thanked you with tears in their eyes. You'll never forget this feeling.")
				end,
			},
			{
				text = "Achieving something you thought impossible",
				effects = { Happiness = 20, Smarts = 3 },
				setFlags = { overcame_odds = true, achiever = true },
				feedText = "You proved yourself wrong.",
				onResolve = function(state)
					state:AddFeed("⭐ If you can do THIS, what else are you capable of? Everything feels possible now!")
				end,
			},
			{
				text = "A deep conversation that changed your perspective",
				effects = { Smarts = 6, Happiness = 10 },
				setFlags = { philosophical = true, deep_thinker = true },
				feedText = "Your world expanded.",
				onResolve = function(state)
					state:AddFeed("⭐ You see things differently now. Childhood innocence fading, but wisdom growing.")
				end,
			},
		},
	},
	{
		id = "teen_mentor_figure",
		title = "🌟 A Mentor Appears",
		emoji = "🌟",
		text = "An adult in your life has taken a special interest in helping you succeed...",
		question = "Who becomes your mentor?",
		minAge = 14, maxAge = 18,
		baseChance = 0.2,
		cooldown = 15,
		oneTime = true,
		category = "growth",
		tags = { "mentor", "guidance", "growth" },
		blockedByFlags = { in_prison = true, has_mentor = true },
		
		choices = {
			{
				text = "A teacher who sees your potential",
				effects = { Smarts = 8, Happiness = 10 },
				setFlags = { has_mentor = true, teacher_mentor = true },
				feedText = "Finally, an adult who gets you.",
				onResolve = function(state)
					state:AddFeed("🌟 They push you to be better. Your grades AND confidence improve!")
				end,
			},
			{
				text = "A family friend in your dream career",
				effects = { Smarts = 5, Happiness = 12 },
				setFlags = { has_mentor = true, career_mentor = true },
				feedText = "An inside look at your future!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.career_clarity = true
					state:AddFeed("🌟 They're showing you exactly what it takes. You have a roadmap now!")
				end,
			},
			{
				text = "A coach who believes in you",
				effects = { Health = 6, Happiness = 10, Looks = 2 },
				setFlags = { has_mentor = true, coach_mentor = true },
				feedText = "They're tough, but fair.",
				onResolve = function(state)
					state:AddFeed("🌟 'I see champions. You just need to believe it too.' You'll never forget those words.")
				end,
			},
			{
				text = "A successful relative",
				effects = { Smarts = 4, Happiness = 8, Money = 100 },
				setFlags = { has_mentor = true, family_mentor = true },
				feedText = "Family looking out for you.",
				onResolve = function(state)
					state:AddFeed("🌟 They're investing in your future. Both with advice AND some cash for your goals!")
				end,
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- NEW ENGAGING TEEN EVENTS - Makes ages 13-18 less repetitive!
	-- User feedback: "AGE LIKE 5 TO 18 IS BASICLY ALLWAYS THE EXACT SAME"
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "teen_cheating_request",
		title = "The Cheat Request",
		emoji = "📋",
		text = "During a big test, the kid next to you slides a note: 'Please let me see your answers! I'll fail if you don't help. I'll do anything!'",
		question = "What do you do?",
		minAge = 13, maxAge = 18,
		baseChance = 0.4,
		cooldown = 4,
		category = "school",
		tags = { "cheating", "test", "ethics", "school" },
		blockedByFlags = { in_prison = true, dropped_out_high_school = true },
		
		choices = {
			{
				text = "Let them copy - they're desperate",
				effects = {},
				feedText = "You angled your paper...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 25 then
						state:ModifyStat("Happiness", -12)
						state:ModifyStat("Smarts", -5)
						state.Flags.caught_enabling_cheating = true
						state:AddFeed("📋 CAUGHT! Teacher saw. BOTH of you got zeros. Academic probation!")
					elseif roll <= 60 then
						state:ModifyStat("Happiness", 3)
						state.Flags.helped_cheater = true
						state:AddFeed("📋 They got away with it. They owe you BIG time.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📋 They copied wrong answers. Still failed. All that risk for nothing.")
					end
				end,
			},
			{
				text = "Ignore them and focus on your test",
				effects = { Smarts = 2 },
				setFlags = { academic_integrity = true },
				feedText = "📋 You stayed focused. Their problem isn't your problem.",
			},
			{
				text = "Whisper 'No way, I could get expelled'",
				effects = { Happiness = 2 },
				feedText = "📋 You declined quietly. They looked disappointed but understood.",
			},
			{
				text = "Give them wrong answers on purpose",
				effects = {},
				feedText = "You fed them false info...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 50 then
						state:ModifyStat("Happiness", 5)
						state.Flags.sabotaged_cheater = true
						state:AddFeed("📋 They got an F. Shouldn't have tried to cheat. Karma!")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("📋 They figured out you tricked them. Now they're your enemy.")
					end
				end,
			},
		},
	},
	{
		id = "teen_locker_room_confrontation",
		title = "Locker Room Showdown",
		emoji = "🏋️",
		text = "After gym class, some kids corner you in the locker room. 'You think you're tough? Prove it.' Everyone's watching to see what happens.",
		question = "How do you handle this?",
		minAge = 13, maxAge = 18,
		baseChance = 0.45,
		cooldown = 5,
		category = "conflict",
		tags = { "confrontation", "bullying", "gym", "school" },
		blockedByFlags = { in_prison = true, dropped_out_high_school = true },
		
		choices = {
			{
				text = "Stand your ground and don't back down",
				effects = {},
				feedText = "You faced them directly...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random(100) + (health / 4)
					state.Flags = state.Flags or {}
					if roll >= 60 then
						state:ModifyStat("Happiness", 8)
						state.Flags.earned_respect = true
						state.Flags.stood_up_for_self = true
						state:AddFeed("🏋️ Your confidence surprised them. They backed off. Respect earned!")
					else
						state:ModifyStat("Happiness", -5)
						state:ModifyStat("Health", -5)
						state.Flags.lost_confrontation = true
						state:AddFeed("🏋️ It got physical. You took some hits but didn't back down.")
					end
				end,
			},
			{
				text = "Try to talk your way out",
				effects = {},
				feedText = "You tried diplomacy...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random(100) + (smarts / 4)
					if roll >= 55 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🏋️ You defused the situation with words. Crisis averted!")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🏋️ They laughed at your 'talking'. Humiliating.")
					end
				end,
			},
			{
				text = "Walk away - not worth it",
				effects = { Happiness = -4 },
				feedText = "🏋️ You walked past them. Smart or weak? People will debate.",
			},
			{
				text = "Throw the first punch",
				effects = {},
				feedText = "You struck first...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random(100) + (health / 3)
					state.Flags = state.Flags or {}
					if roll >= 70 then
						state:ModifyStat("Happiness", 6)
						state.Flags.aggressive_reputation = true
						state:AddFeed("🏋️ Your surprise attack worked! They scattered. Don't mess with you!")
					else
						state:ModifyStat("Health", -12)
						state:ModifyStat("Happiness", -10)
						state.Flags.got_beat_up = true
						state:AddFeed("🏋️ Bad move. There were more of them. Hospital visit needed.")
					end
				end,
			},
		},
	},
	{
		id = "teen_party_invitation",
		title = "The Party Invite",
		emoji = "🎉",
		text = "The popular kids are throwing a party while their parents are away. You actually got invited! But there's gonna be drama and things might get crazy...",
		question = "Do you go?",
		minAge = 14, maxAge = 18,
		baseChance = 0.4,
		cooldown = 4,
		category = "social",
		tags = { "party", "social", "decisions", "teen" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "Go and have fun!",
				effects = {},
				feedText = "You went to the party...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 30 then
						state:ModifyStat("Happiness", 12)
						state.Flags.party_legend = true
						state:AddFeed("🎉 BEST. NIGHT. EVER. You're now part of the in-crowd!")
					elseif roll <= 60 then
						state:ModifyStat("Happiness", 6)
						state.Flags.went_to_party = true
						state:AddFeed("🎉 Fun night! Made some memories. Nothing too crazy.")
					elseif roll <= 85 then
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Health", -2)
						state:AddFeed("🎉 The night got messy. Headache tomorrow. Was it worth it?")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags.party_disaster = true
						state:AddFeed("🎉 Cops showed up. Parents were called. You're GROUNDED.")
					end
				end,
			},
			{
				text = "Go but stay sober",
				effects = { Happiness = 4 },
				setFlags = { responsible = true, party_attended = true },
				feedText = "🎉 You had fun without getting wasted. Respect.",
			},
			{
				text = "Skip it - not worth the risk",
				effects = { Happiness = -2 },
				feedText = "🎉 You stayed home. FOMO is real but so is being responsible.",
			},
			{
				text = "Tell an adult (snitch)",
				effects = {},
				feedText = "You told a parent...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 40 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🎉 Party got shut down. Some kids got in trouble. You saved lives maybe?")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags.social_outcast = true
						state:AddFeed("🎉 Everyone found out you snitched. Social suicide.")
					end
				end,
			},
		},
	},
	{
		-- CRITICAL FIX: Renamed from "teen_social_media_drama" to avoid duplicate ID
		id = "teen_social_media_explosion",
		title = "Social Media Explosion!",
		emoji = "📱",
		text = "Someone posted something about you online. It's going VIRAL in your school. Your phone is blowing up with notifications.",
		question = "What did they post?",
		minAge = 13, maxAge = 18,
		baseChance = 0.35,
		cooldown = 4,
		category = "social",
		tags = { "social_media", "drama", "viral", "teen" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "An embarrassing photo of you",
				effects = {},
				feedText = "The photo spread everywhere...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 30 then
						state:ModifyStat("Happiness", 5)
						state.Flags.viral_fame = true
						state:AddFeed("📱 Plot twist - people thought it was FUNNY in a good way. You're a meme legend!")
					else
						state:ModifyStat("Happiness", -10)
						state:ModifyStat("Looks", -3)
						state.Flags.viral_embarrassment = true
						state:AddFeed("📱 Everyone saw it. The comments are brutal. You want to transfer schools.")
					end
				end,
			},
			{
				text = "A lie/rumor about you",
				effects = {},
				feedText = "The rumor spread like wildfire...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 40 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📱 The truth came out. The poster got in trouble for spreading lies.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags.online_victim = true
						state:AddFeed("📱 People believe the lie. Your reputation is damaged.")
					end
				end,
			},
			{
				text = "Actually something COOL about you",
				effects = { Happiness = 8, Looks = 3 },
				setFlags = { positive_viral = true },
				feedText = "📱 You went viral for something AWESOME! Everyone wants to know you now!",
			},
			{
				text = "A private conversation that leaked",
				effects = {},
				feedText = "Your private words went public...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 60 then
						state:ModifyStat("Happiness", -12)
						state.Flags.privacy_violated = true
						state:AddFeed("📱 Your private messages are everywhere. Trust is SHATTERED.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📱 People saw it but moved on. Internet attention is short.")
					end
				end,
			},
		},
	},
	{
		id = "teen_teacher_conflict",
		title = "Teacher Trouble",
		emoji = "👨‍🏫",
		text = "A teacher has it out for you. They keep calling on you when you don't know the answer, grading you harshly, and making snide comments. Today they went TOO far.",
		question = "What do you do?",
		minAge = 13, maxAge = 18,
		baseChance = 0.35,
		cooldown = 4,
		category = "school",
		tags = { "teacher", "conflict", "school", "authority" },
		blockedByFlags = { in_prison = true, dropped_out_high_school = true },
		
		choices = {
			{
				text = "Stand up for yourself in class",
				effects = {},
				feedText = "You spoke up...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random(100) + (smarts / 5)
					state.Flags = state.Flags or {}
					if roll >= 60 then
						state:ModifyStat("Happiness", 8)
						state.Flags.stood_up_to_teacher = true
						state:AddFeed("👨‍🏫 Your classmates supported you! The teacher backed down.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags.teacher_enemy = true
						state:AddFeed("👨‍🏫 You made it worse. Now they REALLY have it out for you.")
					end
				end,
			},
			{
				text = "Report them to the principal",
				effects = {},
				feedText = "You went to administration...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 50 then
						state:ModifyStat("Happiness", 6)
						state.Flags.reported_teacher = true
						state:AddFeed("👨‍🏫 The principal took your complaint seriously! Things are changing.")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("👨‍🏫 Nothing happened. Teacher tenure is strong. You feel powerless.")
					end
				end,
			},
			{
				text = "Get your parents involved",
				effects = {},
				feedText = "Your parents contacted the school...",
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 60 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("👨‍🏫 Parents to the rescue! The teacher is being more careful now.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("👨‍🏫 Parents tried but it made things awkward. Teacher knows you snitched.")
					end
				end,
			},
			{
				text = "Keep your head down and survive",
				effects = { Happiness = -4, Smarts = 2 },
				feedText = "👨‍🏫 You focused on just passing the class. One more year of this...",
			},
		},
	},
	{
		id = "teen_caught_skipping",
		title = "Skipping School",
		emoji = "🏃",
		text = "Your friends want to skip school and go to the mall/movies/beach. 'Come on, live a little!' They're peer pressuring you hard.",
		question = "What do you do?",
		minAge = 14, maxAge = 18,
		baseChance = 0.35,
		cooldown = 4,
		category = "social",
		tags = { "skipping", "peer_pressure", "school", "decisions" },
		blockedByFlags = { in_prison = true, dropped_out_high_school = true },
		
		choices = {
			{
				text = "Skip with them - YOLO!",
				effects = {},
				feedText = "You ditched school...",
				onResolve = function(state)
					local roll = math.random(100)
					state.Flags = state.Flags or {}
					if roll <= 30 then
						state:ModifyStat("Happiness", 10)
						state.Flags.skipped_successfully = true
						state:AddFeed("🏃 Best day ever! No one found out. Memories made!")
					elseif roll <= 60 then
						state:ModifyStat("Happiness", 4)
						state.Flags.skipped_school = true
						state:AddFeed("🏃 Fun day out. School called home but you made up an excuse.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags.caught_skipping = true
						state:AddFeed("🏃 CAUGHT! Truancy officer spotted you. Now you're in deep trouble.")
					end
				end,
			},
			{
				text = "Make an excuse and stay",
				effects = { Smarts = 2 },
				feedText = "🏃 You made up an excuse. They went without you. FOMO but responsible.",
			},
			{
				text = "Skip just one class, not the whole day",
				effects = {},
				feedText = "You skipped one period...",
				onResolve = function(state)
					local roll = math.random(100)
					if roll <= 70 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🏃 Quick adventure, back before anyone noticed. Perfect crime!")
					else
						state:ModifyStat("Happiness", -4)
						state.Flags = state.Flags or {}
						state.Flags.caught_skipping = true
						state:AddFeed("🏃 The ONE class you skipped had a pop quiz. And they called roll.")
					end
				end,
			},
			{
				text = "Tell them skipping is dumb",
				effects = { Happiness = -3 },
				setFlags = { goody_two_shoes = true },
				feedText = "🏃 You lectured them. They rolled their eyes and left you behind.",
			},
		},
	},
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- NEW VARIETY EVENTS - Making ages 13-17 less repetitive
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_internet_rabbit_hole",
		title = "🕳️ Internet Rabbit Hole",
		emoji = "🕳️",
		text = "You started watching one video and now it's 3 AM. You've gone deep down an internet rabbit hole.",
		question = "What weird thing did you discover?",
		minAge = 13, maxAge = 18,
		baseChance = 0.4,
		cooldown = 4,
		category = "entertainment",
		tags = { "internet", "discovery", "hobby", "late_night" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "A new hobby that actually interests you",
				effects = { Smarts = 4, Happiness = 6 },
				setFlags = { found_internet_hobby = true },
				feedText = "🕳️ You discovered something amazing - woodworking/coding/music production! New passion unlocked!",
			},
			{
				text = "Conspiracy theories that blow your mind",
				effects = { Smarts = -2, Happiness = 3 },
				setFlags = { conspiracy_phase = true },
				feedText = "🕳️ The moon landing... was it real? You're questioning EVERYTHING now.",
			},
			{
				text = "A content creator you now follow obsessively",
				effects = { Happiness = 4 },
				setFlags = { has_favorite_creator = true },
				feedText = "🕳️ You found your new favorite creator! Watched 50 videos in one night.",
			},
			{
				text = "Cringy old content of yourself",
				effects = { Happiness = -5 },
				feedText = "🕳️ Why does 12-year-old you exist on the internet?! Delete! DELETE!",
			},
		},
	},
	{
		id = "teen_random_act_kindness",
		title = "💝 Random Kindness",
		emoji = "💝",
		text = "A stranger did something unexpectedly kind for you today.",
		question = "What happened?",
		minAge = 13, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		category = "social",
		tags = { "kindness", "positive", "stranger", "good_day" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "Someone paid for my coffee/food",
				effects = { Happiness = 8, Money = 10 },
				setFlags = { experienced_kindness = true },
				feedText = "💝 A stranger ahead of you paid for your order. Faith in humanity restored!",
			},
			{
				text = "Someone complimented me genuinely",
				effects = { Happiness = 6, Looks = 2 },
				feedText = "💝 A random person said 'You look really nice today!' Made your whole week!",
			},
			{
				text = "Someone helped me when I was lost/struggling",
				effects = { Happiness = 5, Smarts = 2 },
				feedText = "💝 When you were visibly struggling, someone stopped to help. Angels exist!",
			},
			{
				text = "Someone defended me from mean people",
				effects = { Happiness = 8 },
				setFlags = { had_defender = true },
				feedText = "💝 A stranger stood up for you when others were being jerks. Hero!",
			},
		},
	},
	{
		id = "teen_awkward_silence",
		title = "😬 Awkward Moment",
		emoji = "😬",
		text = "Something super awkward just happened. Time slowed down. You could feel everyone cringing.",
		question = "What happened?",
		minAge = 13, maxAge = 18,
		baseChance = 0.4,
		cooldown = 4,
		category = "social",
		tags = { "awkward", "social", "embarrassment", "relatable" },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "Waved at someone who wasn't waving at me",
				effects = { Happiness = -3 },
				feedText = "😬 They were waving at someone behind you. You pretended to fix your hair.",
			},
			{
				text = "Said 'you too' when it didn't make sense",
				effects = { Happiness = -2 },
				feedText = "😬 'Enjoy your meal!' 'You too!' You're replaying it in your head for days.",
			},
			{
				text = "Your stomach growled LOUD in a quiet room",
				effects = { Happiness = -4 },
				feedText = "😬 Dead silence. Then YOUR STOMACH. Everyone looked. Mortifying.",
			},
			{
				text = "Laughed way too hard at something unfunny",
				effects = { Happiness = -3 },
				feedText = "😬 No one else laughed. You laughed alone. For too long. In the silence.",
			},
		},
	},
	{
		id = "teen_existential_crisis",
		title = "🌌 Late Night Thoughts",
		emoji = "🌌",
		text = "It's 2 AM and you're staring at the ceiling having deep thoughts about life, the universe, and everything.",
		question = "What are you thinking about?",
		minAge = 14, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		oneTime = true,
		category = "philosophy",
		tags = { "existential", "deep_thoughts", "growing_up", "identity" },
		blockedByFlags = { in_prison = true, had_existential_crisis = true },
		
		choices = {
			{
				text = "What do I even want to do with my life?",
				effects = { Happiness = -2, Smarts = 3 },
				setFlags = { career_questioning = true, had_existential_crisis = true },
				feedText = "🌌 The pressure of 'what do you want to be?' is overwhelming. No answers yet.",
			},
			{
				text = "Does anyone actually understand me?",
				effects = { Happiness = -4 },
				setFlags = { feeling_misunderstood = true, had_existential_crisis = true },
				feedText = "🌌 You feel like you're playing a character. Who is the REAL you?",
			},
			{
				text = "Will I ever actually matter?",
				effects = { Happiness = -3, Smarts = 4 },
				setFlags = { legacy_aware = true, had_existential_crisis = true },
				feedText = "🌌 7 billion people on Earth. What makes you special? Heavy thoughts.",
			},
			{
				text = "Life is actually pretty amazing when you think about it",
				effects = { Happiness = 6, Smarts = 3 },
				setFlags = { grateful_perspective = true, had_existential_crisis = true },
				feedText = "🌌 You're alive! On a rock! Flying through space! That's incredible!",
			},
		},
	},
	{
		id = "teen_unexpected_talent",
		title = "✨ Hidden Talent!",
		emoji = "✨",
		text = "You tried something new today and discovered you're actually... really good at it?!",
		question = "What's your hidden talent?",
		minAge = 13, maxAge = 18,
		baseChance = 0.35,
		cooldown = 6,
		oneTime = true,
		category = "discovery",
		tags = { "talent", "discovery", "skill", "surprise" },
		blockedByFlags = { in_prison = true, found_hidden_talent = true },
		
		choices = {
			{
				text = "Cooking - made something actually delicious!",
				effects = { Happiness = 8, Smarts = 3 },
				-- CRITICAL FIX: Set more comprehensive flags for career wiring!
				setFlags = { 
					cooking_talent = true, 
					found_hidden_talent = true,
					chef_potential = true,
					culinary_interest = true,
					food_service_interest = true,
				},
				hintCareer = "chef",
				feedText = "✨ Your family was shocked. 'YOU made this?!' Future chef potential!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.cooking_talent = true
					state.Flags.chef_potential = true
					state:AddFeed("✨ Hidden talent: COOKING! This could be a career path!")
				end,
			},
			{
				text = "Athletics - outperformed everyone!",
				effects = { Happiness = 8, Health = 5 },
				-- CRITICAL FIX: Wire to sports career path
				setFlags = { 
					athletic_talent = true, 
					found_hidden_talent = true,
					natural_athlete = true,
					sports_interest = true,
					varsity_potential = true,
					passionate_athlete = true, -- Same flag as discovered_passion!
				},
				hintCareer = "sports",
				feedText = "✨ Turns out you're naturally athletic! Coach is already interested!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.athletic_talent = true
					state.Flags.natural_athlete = true
					state.Flags.passionate_athlete = true
					state:AddFeed("✨ Hidden talent: ATHLETICS! Sports careers may open up!")
				end,
			},
			{
				text = "Public speaking - held everyone's attention!",
				effects = { Happiness = 7, Smarts = 4 },
				-- CRITICAL FIX: Wire to law/politics/business careers
				setFlags = { 
					public_speaking_talent = true, 
					found_hidden_talent = true,
					natural_leader = true,
					law_interest = true,
					politics_interest = true,
					charismatic = true,
				},
				hintCareer = "law",
				feedText = "✨ You got up to present and... everyone was captivated. Natural orator!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.public_speaking_talent = true
					state.Flags.natural_leader = true
					state:AddFeed("✨ Hidden talent: PUBLIC SPEAKING! Law, politics, or leadership await!")
				end,
			},
			{
				text = "Art - created something beautiful!",
				effects = { Happiness = 8, Looks = 2 },
				-- CRITICAL FIX: Wire to creative careers
				setFlags = { 
					art_talent = true, 
					found_hidden_talent = true,
					creative_talent = true,
					artistic = true,
					passionate_artist = true, -- Same flag as discovered_passion!
					design_interest = true,
				},
				hintCareer = "creative",
				feedText = "✨ You drew/painted something and people actually wanted to BUY it!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.art_talent = true
					state.Flags.creative_talent = true
					state.Flags.passionate_artist = true
					state:AddFeed("✨ Hidden talent: ART! Creative careers may open up!")
				end,
			},
			{
				text = "Tech/Coding - figured out complex stuff fast!",
				effects = { Happiness = 7, Smarts = 5 },
				-- CRITICAL FIX: Wire to tech careers
				setFlags = { 
					tech_talent = true, 
					found_hidden_talent = true,
					coding_prodigy = true,
					tech_savvy = true,
					passionate_scientist = true, -- Same flag as discovered_passion!
					hacker_interest = true,
				},
				hintCareer = "tech",
				feedText = "✨ You built something amazing with code! Silicon Valley calling?",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.tech_talent = true
					state.Flags.coding_prodigy = true
					state.Flags.passionate_scientist = true
					state:AddFeed("✨ Hidden talent: TECH! Programming and engineering await!")
				end,
			},
		},
	},

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- NEW TEEN VARIETY EVENTS (Ages 10-18) - More unique experiences!
	-- User complaint: "LIFE FROM LIKE AGE 10 TO 18 IS LEGIT THE EXACT SAME EVERYTIME"
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "teen_school_project_partner",
		title = "📚 Group Project Partner",
		emoji = "📚",
		text = "You've been assigned a group project! Your partner is someone you don't know well.",
		question = "How does the project go?",
		minAge = 12, maxAge = 17,
		baseChance = 0.35,
		cooldown = 4,
		category = "school",
		tags = { "school", "teamwork", "social" },
		
		choices = {
			{
				text = "We work great together!",
				effects = { Happiness = 8, Smarts = 4 },
				setFlags = { good_teamwork = true },
				feedText = "📚 Amazing chemistry! You made a new friend AND aced the project!",
			},
			{
				text = "They don't do any work",
				effects = { Happiness = -5, Smarts = 2 },
				feedText = "📚 You did everything yourself. Frustrating but you learned a lot.",
			},
			{
				text = "We argue the whole time",
				effects = { Happiness = -6 },
				setFlags = { conflict_at_school = true },
				feedText = "📚 Creative differences turned ugly. Barely finished in time.",
			},
			{
				text = "They become your best friend!",
				effects = { Happiness = 12 },
				setFlags = { made_best_friend = true, has_best_friend = true },
				feedText = "📚 Who knew a school project could change your social life forever!",
			},
		},
	},
	
	{
		id = "teen_embarrassing_moment",
		title = "😳 Embarrassing Moment!",
		emoji = "😳",
		text = "Something incredibly embarrassing just happened at school!",
		question = "What happened?",
		minAge = 11, maxAge = 18,
		baseChance = 0.45,
		cooldown = 3,
		category = "social",
		tags = { "embarrassing", "school", "social" },
		
		choices = {
			{
				text = "Tripped in front of everyone",
				effects = { Happiness = -8, Looks = -2 },
				feedText = "😳 The whole cafeteria saw. You'll never forget the laughter.",
			},
			{
				text = "Called the teacher 'mom' or 'dad'",
				effects = { Happiness = -5 },
				feedText = "😳 The class erupted. It'll become a school legend.",
			},
			{
				text = "Your phone went off in class",
				effects = { Happiness = -4, Smarts = -1 },
				feedText = "😳 Worst ringtone to go off at the worst time.",
			},
			{
				text = "Laughed it off like a boss",
				effects = { Happiness = 5 },
				setFlags = { confident = true },
				feedText = "😳 You turned the embarrassment into a funny moment. Respect earned!",
			},
		},
	},
	
	{
		id = "teen_crush_drama",
		title = "💕 Crush Drama",
		emoji = "💕",
		text = "Your crush found out you like them!",
		question = "What happens next?",
		minAge = 13, maxAge = 18,
		baseChance = 0.4,
		cooldown = 3,
		category = "romance",
		tags = { "crush", "romance", "teen" },
		
		choices = {
			{
				text = "They like you back!",
				effects = { Happiness = 20 },
				setFlags = { first_relationship = true, dating = true },
				feedText = "💕 THEY LIKE YOU BACK! Your heart is literally exploding!",
			},
			{
				text = "They just want to be friends",
				effects = { Happiness = -10 },
				setFlags = { friend_zoned = true },
				feedText = "💕 Ouch. At least they were nice about it.",
			},
			{
				text = "They told everyone and now it's awkward",
				effects = { Happiness = -15 },
				feedText = "💕 Your secret is out. School just got a lot more uncomfortable.",
			},
			{
				text = "You never find out their reaction",
				effects = { Happiness = -3 },
				feedText = "💕 The suspense is killing you. Maybe it's better not to know?",
			},
		},
	},
	
	{
		id = "teen_new_hobby_discovery",
		title = "🎯 New Hobby!",
		emoji = "🎯",
		text = "You've discovered something you really enjoy doing!",
		question = "What's your new hobby?",
		minAge = 10, maxAge = 17,
		baseChance = 0.35,
		cooldown = 4,
		category = "hobby",
		tags = { "hobby", "interests", "growth" },
		
		choices = {
			{
				text = "Video games/Gaming",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { gamer = true, gaming_hobby = true },
				feedText = "🎮 You've entered the world of gaming! Hours disappear like magic.",
			},
			{
				text = "Reading/Writing",
				effects = { Happiness = 5, Smarts = 6 },
				setFlags = { bookworm = true, likes_reading = true },
				feedText = "📖 Lost in worlds of imagination. Your vocabulary is expanding!",
			},
			{
				text = "Sports/Outdoor activities",
				effects = { Happiness = 7, Health = 5 },
				setFlags = { athletic = true, sports_hobby = true },
				feedText = "⚽ Fresh air and exercise! Your body thanks you.",
			},
			{
				text = "Art/Creative stuff",
				effects = { Happiness = 8, Looks = 2 },
				setFlags = { creative = true, artistic_hobby = true },
				feedText = "🎨 Expressing yourself through art. It's therapeutic!",
			},
			{
				text = "Music/Instrument",
				effects = { Happiness = 7, Smarts = 3 },
				setFlags = { musical = true, plays_instrument = true },
				feedText = "🎸 Making music fills your soul. Keep practicing!",
			},
		},
	},
	
	{
		id = "teen_school_dance",
		title = "💃 School Dance",
		emoji = "💃",
		text = "The big school dance is coming up!",
		question = "What's your plan?",
		minAge = 13, maxAge = 18,
		baseChance = 0.45,
		cooldown = 3,
		category = "social",
		tags = { "dance", "social", "school" },
		
		choices = {
			{
				text = "Go with a date!",
				effects = { Happiness = 12, Looks = 2 },
				feedText = "💃 You looked amazing and had the best night ever!",
				eligibility = function(state)
					return state.Flags and (state.Flags.dating or state.Flags.popular or state.Flags.confident)
				end,
			},
			{
				text = "Go with friends",
				effects = { Happiness = 10 },
				feedText = "💃 Dancing with friends is the best! No drama, just fun!",
			},
			{
				text = "Skip it - not your thing",
				effects = { Happiness = 2, Smarts = 3 },
				setFlags = { introverted = true },
				feedText = "💃 You stayed home and actually had a great night by yourself.",
			},
			{
				text = "Go alone and make the best of it",
				effects = { Happiness = 5 },
				setFlags = { independent = true },
				feedText = "💃 Surprisingly, you ended up having fun anyway!",
			},
		},
	},
	
	{
		id = "teen_sibling_rivalry",
		title = "😤 Sibling Drama",
		emoji = "😤",
		text = "You and your sibling are fighting... again.",
		question = "What's the argument about?",
		minAge = 10, maxAge = 18,
		baseChance = 0.4,
		cooldown = 4,
		category = "family",
		tags = { "family", "sibling", "conflict" },
		-- Only show if player has siblings
		eligibility = function(state)
			if state.Relationships then
				for id, rel in pairs(state.Relationships) do
					if type(rel) == "table" and (rel.role == "Brother" or rel.role == "Sister" or 
						id:find("brother") or id:find("sister")) and rel.alive ~= false then
						return true
					end
				end
			end
			return false, "No siblings"
		end,
		
		choices = {
			{
				text = "They borrowed your stuff without asking",
				effects = { Happiness = -5 },
				feedText = "😤 BOUNDARIES! Is that so hard to understand?!",
			},
			{
				text = "Parents are comparing you to them",
				effects = { Happiness = -8, Smarts = -1 },
				setFlags = { sibling_rivalry = true },
				feedText = "😤 'Why can't you be more like your sibling?' Ugh.",
			},
			{
				text = "They snitched on you",
				effects = { Happiness = -6 },
				feedText = "😤 Betrayal! You won't forget this.",
			},
			{
				text = "Actually made up and bonded",
				effects = { Happiness = 8 },
				setFlags = { close_with_siblings = true },
				feedText = "😤 The fight ended with you both laughing. Siblings are weird.",
			},
		},
	},
	
	{
		id = "teen_identity_exploration",
		title = "🤔 Who Am I?",
		emoji = "🤔",
		text = "You're starting to figure out who you really are.",
		question = "What's on your mind?",
		minAge = 14, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		oneTime = true,
		category = "personal",
		tags = { "identity", "growth", "teen" },
		
		choices = {
			{
				text = "Exploring my personal style",
				effects = { Happiness = 6, Looks = 3 },
				setFlags = { fashion_conscious = true },
				feedText = "🤔 Your style is YOUR style. Express yourself!",
			},
			{
				text = "Figuring out what I believe in",
				effects = { Happiness = 4, Smarts = 4 },
				setFlags = { thoughtful = true, philosophical = true },
				feedText = "🤔 Deep thoughts about life, morality, and meaning.",
			},
			{
				text = "Deciding what kind of person I want to be",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { self_aware = true },
				feedText = "🤔 You're becoming the person you want to be. Growth!",
			},
			{
				text = "Just going with the flow",
				effects = { Happiness = 3 },
				feedText = "🤔 No pressure. You'll figure it out eventually.",
			},
		},
	},
	
	{
		id = "teen_summer_job",
		title = "💼 Summer Job Opportunity",
		emoji = "💼",
		text = "You could get a summer job to earn some money!",
		question = "What do you do?",
		minAge = 15, maxAge = 18,
		baseChance = 0.35,
		cooldown = 3,
		category = "work",
		tags = { "job", "money", "summer" },
		
		choices = {
			{
				text = "Get the job and work hard",
				effects = { Happiness = 4, Smarts = 3, Money = 800 },
				setFlags = { first_job = true, hardworking = true },
				feedText = "💼 Your first paycheck! Financial independence feels amazing!",
			},
			{
				text = "Get the job but slack off",
				effects = { Happiness = 2, Money = 400 },
				setFlags = { first_job = true },
				feedText = "💼 Easy money, minimal effort. Don't expect a reference though.",
			},
			{
				text = "Skip it - summer is for fun!",
				effects = { Happiness = 8, Health = 2 },
				feedText = "💼 You only get so many carefree summers. Enjoy them!",
			},
			{
				text = "Start your own small business",
				effects = { Happiness = 6, Smarts = 5, Money = 300 },
				setFlags = { entrepreneur = true, business_minded = true },
				feedText = "💼 Lawn mowing, tutoring, or selling crafts - you're a young entrepreneur!",
			},
		},
	},
	
	{
		id = "teen_academic_pressure",
		title = "📝 Academic Pressure",
		emoji = "📝",
		text = "School is getting more demanding. The pressure is real.",
		question = "How do you handle it?",
		minAge = 14, maxAge = 18,
		baseChance = 0.45,
		cooldown = 3,
		category = "school",
		tags = { "school", "stress", "academics" },
		
		choices = {
			{
				text = "Rise to the challenge",
				effects = { Happiness = 5, Smarts = 6 },
				setFlags = { academically_driven = true },
				feedText = "📝 Hard work pays off! Your grades are improving.",
			},
			{
				text = "Get overwhelmed and stressed",
				effects = { Happiness = -10, Health = -3, Smarts = 2 },
				setFlags = { stressed_student = true },
				feedText = "📝 The pressure is crushing. You need a break.",
			},
			{
				text = "Find a balance between work and fun",
				effects = { Happiness = 8, Smarts = 3, Health = 2 },
				setFlags = { balanced_student = true },
				feedText = "📝 Work hard, play hard. You've got this figured out!",
			},
			{
				text = "Decide grades aren't everything",
				effects = { Happiness = 4, Smarts = -2 },
				feedText = "📝 School isn't the only path to success. Or is it?",
			},
		},
	},

-- ══════════════════════════════════════════════════════════════════════════════
-- MASSIVE TEEN EXPANSION - 30+ NEW EVENTS
-- More drama, more choices, more replayability!
-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "teen_social_media_fame",
		title = "📱 Going Viral!",
		emoji = "📱",
		textVariants = {
			"One of your posts is blowing up!",
			"Your video is getting thousands of views!",
			"You're suddenly internet famous!",
		},
		text = "One of your posts is blowing up!",
		question = "What do you do with your 15 minutes of fame?",
		minAge = 13, maxAge = 18,
		baseChance = 0.25,
		cooldown = 6,
		category = "social",
		tags = { "social_media", "fame", "viral" },
		
		choices = {
			{
				text = "📈 Try to build on it - make more content!",
				effects = { Happiness = 10 },
				feedText = "Going for fame...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.3 then
						state.Flags.social_media_famous = true
						state.Flags.content_creator = true
						state:ModifyStat("Happiness", 15)
						state:AddFeed("📱 You actually did it! You're building a real following!")
					elseif roll < 0.7 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("📱 Some new followers, but the virality faded...")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📱 The internet moved on fast. Fame is fleeting!")
					end
				end,
			},
			{
				text = "😎 Enjoy it but stay humble",
				effects = { Happiness = 8 },
				setFlags = { had_viral_moment = true, stays_humble = true },
				feedText = "📱 Cool moment! But you know it's temporary. Back to normal life!",
			},
			{
				text = "😰 Freak out - too much attention!",
				effects = { Happiness = -5 },
				setFlags = { avoids_spotlight = true },
				feedText = "📱 Delete delete delete! Too many strangers looking at you!",
			},
		},
	},

	{
		id = "teen_identity_crisis",
		title = "🪞 Who Am I?",
		emoji = "🪞",
		textVariants = {
			"You're questioning everything about yourself...",
			"Who are you REALLY? The question haunts you.",
			"You feel lost about your identity...",
		},
		text = "You're questioning everything about yourself...",
		question = "How do you explore your identity?",
		minAge = 14, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		oneTime = true,
		category = "personal",
		tags = { "identity", "growing_up", "self_discovery" },
		blockedByFlags = { identity_explored = true },
		
		choices = {
			{
				text = "🎨 Express yourself through art/music",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { identity_explored = true, artistic_soul = true, expressive = true },
				feedText = "🪞 Art helps you understand yourself. Each creation reveals something new.",
			},
			{
				text = "📚 Read and learn about different perspectives",
				effects = { Happiness = 5, Smarts = 6 },
				setFlags = { identity_explored = true, philosophical = true, well_read = true },
				feedText = "🪞 Books open your mind. So many ways to be in this world...",
			},
			{
				text = "👥 Talk to trusted friends/family",
				effects = { Happiness = 7 },
				setFlags = { identity_explored = true, open_communicator = true },
				feedText = "🪞 Opening up helps. Others have been through this too.",
			},
			{
				text = "🧘 Just let it be - you'll figure it out",
				effects = { Happiness = 4 },
				setFlags = { identity_explored = true, patient_with_self = true },
				feedText = "🪞 Some questions don't need immediate answers. You're growing.",
			},
		},
	},

	{
		id = "teen_peer_pressure_party",
		title = "🎉 Party Invite",
		emoji = "🎉",
		textVariants = {
			"There's a party this weekend. Parents won't be home...",
			"Everyone's talking about this party. Will you go?",
			"The 'cool kids' invited you to their party...",
		},
		text = "There's a party this weekend. Parents won't be home...",
		question = "What do you do?",
		minAge = 14, maxAge = 18,
		baseChance = 0.4,
		cooldown = 4,
		category = "social",
		tags = { "party", "peer_pressure", "choices" },
		
		choices = {
			{
				text = "🎉 Go and have fun responsibly",
				effects = { Happiness = 8 },
				feedText = "Party time...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.6 then
						state.Flags.party_goer = true
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎉 Great party! You had fun and stayed out of trouble!")
					elseif roll < 0.85 then
						state:AddFeed("🎉 Party was okay. A little boring honestly.")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags.got_in_trouble = true
						state:AddFeed("🎉 Things got out of hand. Someone called the cops!")
					end
				end,
			},
			{
				text = "🚫 Skip it - not your scene",
				effects = { Happiness = 2 },
				setFlags = { knows_own_limits = true },
				feedText = "🎉 You stayed home. FOMO hit, but you're okay with your choice.",
			},
			{
				text = "🤔 Go but leave early",
				effects = { Happiness = 5 },
				setFlags = { cautious_partier = true },
				feedText = "🎉 You showed face, then dipped. Best of both worlds!",
			},
		},
	},

	{
		id = "teen_first_heartbreak",
		title = "💔 Heartbreak",
		emoji = "💔",
		textVariants = {
			"Someone you cared about really hurt you...",
			"Your first real heartbreak has arrived...",
			"Love didn't work out the way you hoped...",
		},
		text = "Someone you cared about really hurt you...",
		question = "How do you cope?",
		minAge = 13, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		oneTime = true,
		category = "relationships",
		tags = { "heartbreak", "love", "growing_up" },
		requiresFlags = { has_had_crush = true },
		blockedByFlags = { first_heartbreak_done = true },
		
		choices = {
			{
				text = "😭 Let yourself feel it all",
				effects = { Happiness = -10 },
				feedText = "Feeling the pain...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.first_heartbreak_done = true
					state.Flags.emotionally_aware = true
					task.delay(0, function()
						state:ModifyStat("Happiness", 8)
					end)
					state:AddFeed("💔 It hurts now. But feeling it is how you heal. You'll be okay.")
				end,
			},
			{
				text = "🏃 Distract yourself with activities",
				effects = { Happiness = -3, Health = 5 },
				setFlags = { first_heartbreak_done = true, copes_with_activity = true },
				feedText = "💔 You threw yourself into sports/hobbies. Busy = less time to think.",
			},
			{
				text = "🗣️ Talk to friends about it",
				effects = { Happiness = -2 },
				setFlags = { first_heartbreak_done = true, relies_on_friends = true },
				feedText = "💔 Your friends rallied around you. They've got your back.",
			},
			{
				text = "😤 Pretend you don't care",
				effects = { Happiness = -8 },
				setFlags = { first_heartbreak_done = true, bottles_emotions = true },
				feedText = "💔 'I'm fine.' (You're not fine, but that's okay too.)",
			},
		},
	},

	{
		id = "teen_talent_discovery",
		title = "⭐ Hidden Talent!",
		emoji = "⭐",
		textVariants = {
			"You discover you're actually GOOD at something!",
			"A hidden talent emerges!",
			"You surprise yourself with a new skill!",
		},
		text = "You discover you're actually GOOD at something!",
		question = "What's your hidden talent?",
		minAge = 12, maxAge = 17,
		baseChance = 0.35,
		cooldown = 8,
		oneTime = true,
		category = "personal",
		tags = { "talent", "discovery", "skills" },
		blockedByFlags = { hidden_talent_found = true },
		
		choices = {
			{
				text = "🎵 Musical ability",
				effects = { Happiness = 10, Looks = 2 },
				setFlags = { hidden_talent_found = true, musical_talent = true, natural_musician = true },
				feedText = "⭐ You picked up an instrument and... WOW! Natural talent!",
			},
			{
				text = "🎨 Artistic skill",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { hidden_talent_found = true, artistic_talent = true, creative_mind = true },
				feedText = "⭐ Your art is actually... really good?! Where did this come from?",
			},
			{
				text = "🏆 Athletic prowess",
				effects = { Happiness = 8, Health = 5 },
				setFlags = { hidden_talent_found = true, athletic_talent = true, natural_athlete = true },
				feedText = "⭐ You tried a sport and dominated! Natural-born athlete!",
			},
			{
				text = "🧮 Academic brilliance",
				effects = { Happiness = 6, Smarts = 8 },
				setFlags = { hidden_talent_found = true, academic_talent = true, naturally_smart = true },
				feedText = "⭐ School suddenly clicks. You understand things others struggle with!",
			},
			{
				text = "🎭 Performance ability",
				effects = { Happiness = 10 },
				setFlags = { hidden_talent_found = true, performance_talent = true, natural_performer = true },
				feedText = "⭐ You got on stage and... wow! Natural born performer!",
			},
		},
	},

	{
		id = "teen_guidance_opportunity",
		title = "🌟 A Mentor Appears",
		emoji = "🌟",
		textVariants = {
			"An adult notices your potential and offers guidance...",
			"Someone wants to mentor you!",
			"A teacher/coach sees something special in you...",
		},
		text = "An adult notices your potential and offers guidance...",
		question = "Do you accept their mentorship?",
		minAge = 13, maxAge = 17,
		baseChance = 0.3,
		cooldown = 6,
		oneTime = true,
		category = "personal",
		tags = { "mentor", "guidance", "growth" },
		blockedByFlags = { has_mentor = true },
		
		choices = {
			{
				text = "🙏 Gratefully accept!",
				effects = { Happiness = 10, Smarts = 5 },
				setFlags = { has_mentor = true, mentored = true, accepts_guidance = true },
				feedText = "🌟 Having someone believe in you changes everything! They guide your growth.",
			},
			{
				text = "🤷 Accept but don't commit",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { has_mentor = true, casual_mentee = true },
				feedText = "🌟 You take their advice sometimes. It helps... when you listen.",
			},
			{
				text = "🙄 Turn them down - you've got this",
				effects = { Happiness = 2 },
				setFlags = { rejected_mentor = true, independent_minded = true },
				feedText = "🌟 You prefer to figure things out alone. Their offer meant well though.",
			},
		},
	},

	{
		id = "teen_creative_project",
		title = "💡 Big Project Idea",
		emoji = "💡",
		textVariants = {
			"You have an idea for something amazing!",
			"Inspiration strikes! You want to create something!",
			"A creative vision consumes your thoughts...",
		},
		text = "You have an idea for something amazing!",
		question = "What do you want to create?",
		minAge = 13, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		category = "personal",
		tags = { "creativity", "projects", "ambition" },
		
		choices = {
			{
				text = "🎬 A video/film project",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { filmmaker_interest = true, creative_creator = true },
				feedText = "🎬 Lights, camera... you're making a movie! Even if it's on your phone.",
			},
			{
				text = "📖 Write a story/novel",
				effects = { Happiness = 6, Smarts = 5 },
				setFlags = { writer_interest = true, creative_creator = true },
				feedText = "📖 Chapter 1... You start writing. Will you finish? Time will tell!",
			},
			{
				text = "🎮 Design a game",
				effects = { Happiness = 7, Smarts = 4 },
				setFlags = { game_designer_interest = true, creative_creator = true },
				feedText = "🎮 Your game idea is brilliant! Even if coding is harder than expected...",
			},
			{
				text = "🎵 Compose music",
				effects = { Happiness = 8 },
				setFlags = { composer_interest = true, creative_creator = true },
				feedText = "🎵 Your first original song! It's rough but it's YOURS!",
			},
		},
	},

	{
		id = "teen_friendship_drama",
		title = "😱 Friend Drama!",
		emoji = "😱",
		textVariants = {
			"Your friend group is having SERIOUS drama!",
			"Two of your friends are fighting!",
			"There's tension in your social circle...",
		},
		text = "Your friend group is having SERIOUS drama!",
		question = "What role do you play?",
		minAge = 12, maxAge = 18,
		baseChance = 0.45,
		cooldown = 4,
		category = "social",
		tags = { "friends", "drama", "conflict" },
		
		choices = {
			{
				text = "🕊️ Try to be the peacemaker",
				effects = { Happiness = -2, Smarts = 2 },
				feedText = "Mediating...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.5 then
						state.Flags.good_mediator = true
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🕊️ You helped them work it out! Crisis averted!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🕊️ You tried, but now BOTH are mad at you! Ugh!")
					end
				end,
			},
			{
				text = "🍿 Stay out of it - not your business",
				effects = { Happiness = 3 },
				setFlags = { avoids_drama = true },
				feedText = "😱 You watched from the sidelines. Smart move... maybe.",
			},
			{
				text = "🗣️ Pick a side",
				effects = {},
				feedText = "Taking sides...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.5 then
						state.Flags.loyal_friend = true
						state:ModifyStat("Happiness", 5)
						state:AddFeed("😱 Your friend appreciated your loyalty! The other... not so much.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags.lost_friend = true
						state:AddFeed("😱 You picked wrong! Now you've lost a friend!")
					end
				end,
			},
		},
	},

	{
		id = "teen_future_dreams",
		title = "🔮 Future Dreams",
		emoji = "🔮",
		textVariants = {
			"Everyone asks 'What do you want to be when you grow up?'",
			"You start thinking seriously about your future...",
			"Dreams for the future fill your mind...",
		},
		text = "Everyone asks 'What do you want to be when you grow up?'",
		question = "What's your dream?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 6,
		oneTime = true,
		category = "personal",
		tags = { "future", "dreams", "career" },
		blockedByFlags = { future_dream_set = true },
		
		choices = {
			{
				text = "💼 Something successful and stable",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { future_dream_set = true, dreams_of_success = true, practical_dreamer = true },
				feedText = "🔮 Doctor? Lawyer? Business? Something that pays well and is respected!",
			},
			{
				text = "🎨 Something creative and artistic",
				effects = { Happiness = 8 },
				setFlags = { future_dream_set = true, dreams_of_art = true, artistic_dreams = true },
				feedText = "🔮 Artist? Musician? Actor? You want to CREATE for a living!",
			},
			{
				text = "🌍 Something that helps others",
				effects = { Happiness = 7 },
				setFlags = { future_dream_set = true, dreams_of_helping = true, altruistic_dreams = true },
				feedText = "🔮 Teacher? Doctor? Non-profit? You want to make a difference!",
			},
			{
				text = "🤷 No idea yet - and that's okay",
				effects = { Happiness = 4 },
				setFlags = { future_dream_set = true, exploring_options = true },
				feedText = "🔮 The future is a mystery. You'll figure it out... eventually!",
			},
			{
				text = "🚀 Something extraordinary",
				effects = { Happiness = 10 },
				setFlags = { future_dream_set = true, big_dreams = true, ambitious = true },
				feedText = "🔮 Astronaut? CEO? Famous? Why dream small?! Sky's the limit!",
			},
		},
	},

	{
		id = "teen_volunteering",
		title = "🤝 Volunteer Opportunity",
		emoji = "🤝",
		textVariants = {
			"There's a chance to volunteer in your community!",
			"A local organization needs help...",
			"You could make a difference by volunteering!",
		},
		text = "There's a chance to volunteer in your community!",
		question = "Do you help out?",
		minAge = 13, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		category = "social",
		tags = { "volunteering", "community", "helping" },
		
		choices = {
			{
				text = "🐾 Animal shelter",
				effects = { Happiness = 10, Health = 2 },
				setFlags = { volunteer = true, animal_volunteer = true, animal_lover = true },
				feedText = "🤝 Puppies and kittens! Best volunteer gig EVER! So many cuddles!",
			},
			{
				text = "🍲 Food bank",
				effects = { Happiness = 8 },
				setFlags = { volunteer = true, food_bank_volunteer = true, community_minded = true },
				feedText = "🤝 Helping feed families in need. It's hard work but meaningful.",
			},
			{
				text = "👴 Senior center",
				effects = { Happiness = 7, Smarts = 2 },
				setFlags = { volunteer = true, senior_volunteer = true, patient = true },
				feedText = "🤝 Old folks have the BEST stories! You learn so much.",
			},
			{
				text = "📚 Tutoring younger kids",
				effects = { Happiness = 6, Smarts = 4 },
				setFlags = { volunteer = true, tutor_volunteer = true, likes_teaching = true },
				feedText = "🤝 Teaching others teaches you! Plus the kids look up to you.",
			},
			{
				text = "⏳ Too busy right now",
				effects = { Happiness = -2 },
				feedText = "🤝 Life's busy. Maybe next time.",
			},
		},
	},

	{
		id = "teen_mortifying_moment",
		title = "😳 Mortifying Moment!",
		emoji = "😳",
		textVariants = {
			"Something INCREDIBLY embarrassing just happened!",
			"You want to crawl into a hole and disappear!",
			"Peak embarrassment achieved!",
		},
		text = "Something INCREDIBLY embarrassing just happened!",
		question = "How do you react?",
		minAge = 12, maxAge = 18,
		baseChance = 0.4,
		cooldown = 4,
		category = "social",
		tags = { "embarrassing", "social", "growing_up" },
		
		choices = {
			{
				text = "😂 Laugh it off",
				effects = { Happiness = 5 },
				setFlags = { good_sport = true, handles_embarrassment_well = true },
				feedText = "😳 If you laugh first, no one can laugh AT you! Power move!",
			},
			{
				text = "😭 Die inside",
				effects = { Happiness = -8 },
				feedText = "😳 You will remember this at 3 AM for the rest of your life.",
			},
			{
				text = "🏃 Run away immediately",
				effects = { Happiness = -5, Health = 2 },
				feedText = "😳 You SET A RECORD getting out of there! Never speak of this again!",
			},
			{
				text = "🤷 Pretend it didn't happen",
				effects = { Happiness = -2 },
				setFlags = { denial_mode = true },
				feedText = "😳 Nothing happened. NOTHING. Move along. You're FINE.",
			},
		},
	},

	{
		id = "teen_college_pressure",
		title = "🎓 College Pressure",
		emoji = "🎓",
		textVariants = {
			"Everyone's talking about college applications...",
			"The college countdown has begun!",
			"SATs, essays, applications - it's all so much!",
		},
		text = "Everyone's talking about college applications...",
		question = "How do you feel about your future?",
		minAge = 16, maxAge = 18,
		baseChance = 0.35,
		cooldown = 4,
		category = "school",
		tags = { "college", "future", "pressure" },
		
		choices = {
			{
				text = "📝 Dive in - let's do this!",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { college_focused = true, organized_student = true },
				feedText = "🎓 Applications, essays, scholarships - you're on it!",
			},
			{
				text = "😰 So stressed I can't function",
				effects = { Happiness = -10, Health = -3 },
				setFlags = { college_anxiety = true, overwhelmed = true },
				feedText = "🎓 The pressure is crushing. Everyone seems to have it figured out except you.",
			},
			{
				text = "🤔 College isn't the only path",
				effects = { Happiness = 3 },
				setFlags = { alternative_path = true, independent_thinker = true },
				feedText = "🎓 Trade school? Gap year? Starting a business? Many roads to success!",
			},
			{
				text = "🙄 I'll deal with it later",
				effects = { Happiness = 2 },
				setFlags = { procrastinator = true },
				feedText = "🎓 Future you's problem! (Future you will NOT be happy about this.)",
			},
		},
	},

	{
		id = "teen_online_gaming",
		title = "🎮 Gaming Life",
		emoji = "🎮",
		textVariants = {
			"You've been spending a LOT of time gaming...",
			"Your gaming skills are improving dramatically!",
			"Games have become your main hobby...",
		},
		text = "You've been spending a LOT of time gaming...",
		question = "How does gaming fit into your life?",
		minAge = 12, maxAge = 18,
		baseChance = 0.4,
		cooldown = 5,
		category = "hobbies",
		tags = { "gaming", "hobby", "technology" },
		
		choices = {
			{
				text = "🏆 Getting seriously competitive",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { competitive_gamer = true, gamer = true },
				feedText = "🎮 Ranked matches, tournaments - you're taking this seriously!",
			},
			{
				text = "👥 It's how I connect with friends",
				effects = { Happiness = 6 },
				setFlags = { social_gamer = true, gamer = true },
				feedText = "🎮 Gaming with friends is the best! Your squad is unbeatable!",
			},
			{
				text = "😴 Maybe playing too much...",
				effects = { Happiness = 3, Health = -3 },
				setFlags = { gaming_addiction = true },
				feedText = "🎮 'Just one more game' at 3 AM... again. This might be a problem.",
			},
			{
				text = "📝 Balancing it with other stuff",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { balanced_gamer = true, gamer = true },
				feedText = "🎮 Gaming is fun but you've got other things going on too! Balance!",
			},
		},
	},

	{
		id = "teen_family_argument",
		title = "😤 Parent Drama",
		emoji = "😤",
		textVariants = {
			"You and your parents are NOT seeing eye to eye...",
			"Another argument with the parents...",
			"Why don't they understand you?!",
		},
		text = "You and your parents are NOT seeing eye to eye...",
		question = "How do you handle the conflict?",
		minAge = 13, maxAge = 18,
		baseChance = 0.45,
		cooldown = 4,
		category = "family",
		tags = { "family", "conflict", "parents" },
		
		choices = {
			{
				text = "🗣️ Try to communicate calmly",
				effects = { Happiness = 3, Smarts = 2 },
				feedText = "Talking it out...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.6 then
						state.Flags = state.Flags or {}
						state.Flags.good_communicator = true
						state:ModifyStat("Happiness", 8)
						state:AddFeed("😤 You talked it out! They actually listened! Progress!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("😤 You tried... but they didn't get it. At least you tried.")
					end
				end,
			},
			{
				text = "😡 Blow up and storm off",
				effects = { Happiness = -8 },
				setFlags = { explosive_temper = true },
				feedText = "😤 DOOR SLAM! You're furious! They just don't GET it!",
			},
			{
				text = "😶 Give them the silent treatment",
				effects = { Happiness = -5 },
				setFlags = { passive_aggressive = true },
				feedText = "😤 Fine. Whatever. You're not talking to them.",
			},
			{
				text = "📝 Write them a letter explaining your feelings",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { written_communicator = true },
				feedText = "😤 Sometimes it's easier to write it down. Maybe they'll understand.",
			},
		},
	},

	{
		id = "teen_summer_plans",
		title = "☀️ Summer Plans",
		emoji = "☀️",
		textVariants = {
			"School's out! What are you doing this summer?",
			"Summer break is here! The possibilities are endless!",
			"Three months of freedom! How will you spend it?",
		},
		text = "School's out! What are you doing this summer?",
		question = "What's your summer plan?",
		minAge = 12, maxAge = 17,
		baseChance = 0.35,
		cooldown = 6,
		category = "lifestyle",
		tags = { "summer", "vacation", "plans" },
		
		choices = {
			{
				text = "💼 Get a summer job",
				effects = { Happiness = 3, Money = 500 },
				setFlags = { summer_job = true, work_experience = true },
				feedText = "☀️ Work all summer! Your wallet is happy, your tan is not.",
			},
			{
				text = "🏕️ Summer camp adventure",
				effects = { Happiness = 10, Health = 3 },
				setFlags = { camp_kid = true, outdoorsy = true },
				feedText = "☀️ Best. Summer. EVER! Camp friends, activities, memories!",
			},
			{
				text = "🏠 Stay home and chill",
				effects = { Happiness = 6 },
				setFlags = { lazy_summer = true },
				feedText = "☀️ Sleep in, video games, Netflix... peak summer vibes!",
			},
			{
				text = "✈️ Family vacation",
				effects = { Happiness = 8 },
				setFlags = { family_trip = true },
				feedText = "☀️ Road trip or flight - family vacation time! Memories (and fights) made!",
			},
			{
				text = "📚 Summer school/enrichment",
				effects = { Happiness = 2, Smarts = 8 },
				setFlags = { summer_school = true, dedicated_student = true },
				feedText = "☀️ Getting ahead! While friends play, you learn. Future you says thanks.",
			},
		},
	},

-- ════════════════════════════════════════════════════════════════════════════
-- MASSIVE EXPANSION: NEW TEEN EVENTS (Ages 13-18)
-- Rich teenage experiences that shape identity and future
-- ════════════════════════════════════════════════════════════════════════════

	{
		id = "teen_first_job_interview",
		title = "First Job Interview!",
		emoji = "💼",
		textVariants = {
			"Your first ever job interview! So nervous!",
			"Time to prove yourself for a part-time job!",
			"You applied for a job and they called back!",
			"Interview day! Look professional!",
		},
		text = "Your first ever job interview! So nervous!",
		question = "How does it go?",
		minAge = 15, maxAge = 18,
		baseChance = 0.45,
		cooldown = 4,
		oneTime = true,
		category = "teen",
		tags = { "teen", "job", "milestone" },
		careerTags = { "business", "service", "retail" },
		blockedByFlags = { first_interview_done = true },
		
		choices = {
			{
				text = "😎 Nailed it! Got hired!",
				effects = { Happiness = 8, Money = 100 },
				setFlags = { first_interview_done = true, has_first_job = true, good_interviewer = true, work_experience = true, professional_start = true },
				hintCareer = "business",
				feedText = "💼 You got the job! First paycheck incoming!",
			},
			{
				text = "😰 So nervous, stumbled words",
				effects = { Happiness = -2 },
				setFlags = { first_interview_done = true, interview_anxiety = true, learned_from_failure = true },
				feedText = "💼 Not your best performance... they said 'we'll call you'",
			},
			{
				text = "🤷 Did okay, waiting to hear",
				effects = { Happiness = 3 },
				setFlags = { first_interview_done = true, interview_experience = true },
				feedText = "💼 Could've been worse! The waiting is the hardest part.",
			},
		},
	},

	{
		id = "teen_online_drama_explosion",
		title = "Social Media Drama!",
		emoji = "📱",
		textVariants = {
			"Someone said something about you online!",
			"A post about you is going around!",
			"Drama in the group chat!",
			"Screenshots are being shared... involving YOU!",
		},
		text = "Someone said something about you online!",
		question = "How do you handle social media drama?",
		minAge = 13, maxAge = 18,
		baseChance = 0.45,
		cooldown = 4,
		category = "teen",
		tags = { "teen", "social", "drama" },
		
		choices = {
			{
				text = "🔥 Clap back publicly",
				effects = { Happiness = 3 },
				setFlags = { social_media_fighter = true, confrontational = true },
				feedText = "📱 You responded! Now everyone's watching the drama unfold!",
			},
			{
				text = "🤝 Handle it privately",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { mature_approach = true, conflict_resolver = true },
				feedText = "📱 You DMed them directly. Mature move. Respect.",
			},
			{
				text = "🤷 Ignore it completely",
				effects = { Happiness = 2 },
				setFlags = { above_drama = true },
				feedText = "📱 Not worth your energy. Let them talk.",
			},
			{
				text = "📴 Delete social media",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { social_media_break = true, values_peace = true },
				feedText = "📱 FREEDOM! No more drama! At least for now...",
			},
		},
	},

	{
		id = "teen_college_application_stress",
		title = "College Pressure!",
		emoji = "🎓",
		textVariants = {
			"Everyone's talking about college applications!",
			"SATs, ACTs, applications... the pressure is REAL!",
			"Your parents keep asking about your college plans!",
			"College tours, essay writing, it's overwhelming!",
		},
		text = "Everyone's talking about college applications!",
		question = "How are you handling the pressure?",
		minAge = 16, maxAge = 18,
		baseChance = 0.45,
		cooldown = 4,
		category = "teen",
		tags = { "teen", "college", "stress" },
		careerTags = { "education", "tech", "medical", "law", "finance" },
		
		choices = {
			{
				text = "📚 Grinding hard! Dream school bound!",
				effects = { Happiness = 3, Smarts = 5, Health = -2 },
				setFlags = { college_focused = true, ambitious_student = true, honors_student = true, academic_achiever = true },
				hintCareer = "education",
				feedText = "🎓 Study study study! You WILL get into your dream school!",
			},
			{
				text = "🤷 Going with the flow",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { relaxed_about_college = true },
				feedText = "🎓 Whatever happens, happens. You'll figure it out.",
			},
			{
				text = "💰 Considering alternatives",
				effects = { Happiness = 3, Smarts = 3 },
				setFlags = { considering_trade_school = true, practical_minded = true, vocational_track = true, hands_on_type = true },
				hintCareer = "trades",
				feedText = "🎓 Trade school? Gap year? Straight to work? Options!",
			},
			{
				text = "😰 Completely overwhelmed",
				effects = { Happiness = -4, Health = -2 },
				setFlags = { college_anxiety = true, needs_support = true },
				feedText = "🎓 It's all too much. You need a break and some guidance.",
			},
		},
	},

	{
		id = "teen_social_circle_shift",
		title = "Friend Group Shift!",
		emoji = "👥",
		textVariants = {
			"Your friend group is changing...",
			"Old friends drifting, new people entering your life!",
			"High school is reshuffling social circles!",
			"Are these still YOUR people?",
		},
		text = "Your friend group is changing...",
		question = "How do you navigate this?",
		minAge = 14, maxAge = 18,
		baseChance = 0.4,
		cooldown = 5,
		category = "teen",
		tags = { "teen", "friends", "social" },
		
		choices = {
			{
				text = "🆕 Embrace new friendships",
				effects = { Happiness = 6 },
				setFlags = { adaptable_socially = true, open_to_change = true },
				feedText = "👥 New friends, new experiences! Growth!",
			},
			{
				text = "💔 Miss the old group",
				effects = { Happiness = -3 },
				setFlags = { nostalgic = true, values_old_friends = true },
				feedText = "👥 Things aren't the same. You miss how it used to be.",
			},
			{
				text = "🤝 Keep both old and new",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { social_butterfly = true, diplomatic = true },
				feedText = "👥 You balance both groups! More friends = more fun!",
			},
			{
				text = "😌 Prefer being alone anyway",
				effects = { Happiness = 3 },
				setFlags = { comfortable_alone = true, introverted = true },
				feedText = "👥 Less drama this way. You enjoy your own company.",
			},
		},
	},

	{
		id = "teen_athletic_injury",
		title = "Sports Injury!",
		emoji = "🩹",
		textVariants = {
			"You got hurt playing sports!",
			"A bad fall during practice!",
			"Sports injury - how bad is it?",
			"Something popped/twisted during the game!",
		},
		text = "You got hurt playing sports!",
		question = "How serious is it?",
		minAge = 13, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		category = "teen",
		tags = { "teen", "sports", "injury" },
		requiresFlags = { on_sports_team = true },
		
		choices = {
			{
				text = "🩹 Minor - walk it off",
				effects = { Health = -5, Happiness = 2 },
				setFlags = { tough_player = true, minor_sports_injury = true },
				feedText = "🩹 Just a bruise! Back in the game!",
			},
			{
				text = "🏥 Needs medical attention",
				effects = { Health = -15, Happiness = -5, Money = -200 },
				setFlags = { had_sports_injury = true },
				feedText = "🩹 Doctor visit. Rest and recovery needed.",
			},
			{
				text = "😱 Season-ending injury",
				effects = { Health = -25, Happiness = -10, Money = -500 },
				setFlags = { serious_sports_injury = true, season_ended = true },
				feedText = "🩹 Devastating news. Your season is over.",
			},
		},
	},

	{
		id = "teen_internet_famous",
		title = "Going Viral!",
		emoji = "📈",
		textVariants = {
			"Something you posted is BLOWING UP!",
			"Your video is going viral!",
			"Thousands of likes... wait, MILLIONS?!",
			"You're internet famous overnight!",
		},
		text = "Something you posted is BLOWING UP!",
		question = "How do you handle sudden fame?",
		minAge = 13, maxAge = 18,
		baseChance = 0.25,
		cooldown = 6,
		category = "teen",
		tags = { "teen", "viral", "social" },
		careerTags = { "entertainment", "marketing", "esports" },
		
		choices = {
			{
				text = "🎉 Ride the wave! Post more!",
				effects = { Happiness = 10, Money = 50 },
				setFlags = { went_viral = true, content_creator_start = true, influencer_potential = true, content_creator = true, streamer = true, social_media_savvy = true },
				hintCareer = "entertainment",
				feedText = "📈 You're capitalizing on the moment! Followers flooding in!",
			},
			{
				text = "😳 This is overwhelming",
				effects = { Happiness = 3 },
				setFlags = { went_viral = true, viral_anxiety = true },
				feedText = "📈 So many notifications... is this good? Bad? WHAT?!",
			},
			{
				text = "🔒 Go private, too much attention",
				effects = { Happiness = -2 },
				setFlags = { went_viral = true, privacy_focused = true },
				feedText = "📈 Locking everything down. This is TOO much.",
			},
			{
				text = "💰 Try to monetize it",
				effects = { Happiness = 6, Money = 200, Smarts = 2 },
				setFlags = { went_viral = true, business_minded_teen = true, entrepreneur = true, marketing_savvy = true },
				hintCareer = "business",
				feedText = "📈 Brand deals? Merch? You see the opportunity!",
			},
		},
	},

	{
		id = "teen_self_discovery_journey",
		title = "Who Am I?",
		emoji = "🤔",
		textVariants = {
			"You're questioning everything about yourself...",
			"Who are you really? Deep thoughts time.",
			"Identity crisis hitting hard!",
			"Trying to figure out who you want to be...",
		},
		text = "You're questioning everything about yourself...",
		question = "How do you explore your identity?",
		minAge = 14, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		oneTime = true,
		category = "teen",
		tags = { "teen", "identity", "growth" },
		blockedByFlags = { identity_explored = true },
		
		choices = {
			{
				text = "🎨 Try new styles/expressions",
				effects = { Happiness = 5, Looks = 2 },
				setFlags = { identity_explored = true, experimental_phase = true },
				feedText = "🤔 New clothes, new hair, new you? Experimenting!",
			},
			{
				text = "📚 Deep dive into interests",
				effects = { Happiness = 4, Smarts = 3 },
				setFlags = { identity_explored = true, finding_passions = true },
				feedText = "🤔 What do YOU actually like? Time to find out!",
			},
			{
				text = "👥 Try different friend groups",
				effects = { Happiness = 4 },
				setFlags = { identity_explored = true, social_explorer = true },
				feedText = "🤔 Different people, different vibes, finding your tribe!",
			},
			{
				text = "😌 I know who I am",
				effects = { Happiness = 6 },
				setFlags = { identity_explored = true, strong_identity = true },
				feedText = "🤔 Some people just KNOW. You're confident in yourself!",
			},
		},
	},

	{
		id = "teen_mental_health",
		title = "Mental Health Check",
		emoji = "🧠",
		textVariants = {
			"You've been feeling... off lately.",
			"Stress is piling up...",
			"Some days are harder than others.",
			"Time to check in with yourself.",
		},
		text = "You've been feeling... off lately.",
		question = "How do you handle your mental health?",
		minAge = 13, maxAge = 18,
		baseChance = 0.4,
		cooldown = 5,
		category = "teen",
		tags = { "teen", "mental_health", "wellness" },
		
		choices = {
			{
				text = "💬 Talk to someone trusted",
				effects = { Happiness = 6, Health = 3 },
				setFlags = { seeks_support = true, emotionally_aware = true },
				feedText = "🧠 Opening up helps. You're not alone in this.",
			},
			{
				text = "📓 Journal your feelings",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { uses_journaling = true, self_reflective = true },
				feedText = "🧠 Writing it out helps process emotions.",
			},
			{
				text = "🏃 Exercise to cope",
				effects = { Happiness = 5, Health = 4 },
				setFlags = { exercise_coper = true, active_coping = true },
				feedText = "🧠 Moving your body helps move your mood!",
			},
			{
				text = "😔 Struggle silently",
				effects = { Happiness = -4, Health = -2 },
				setFlags = { struggles_alone = true, needs_help = true },
				feedText = "🧠 It's hard to ask for help. But please try.",
			},
		},
	},

	{
		id = "teen_car_dreams",
		title = "Car Dreaming!",
		emoji = "🚗",
		textVariants = {
			"You're dreaming about your first car!",
			"Everyone's getting their license... now what?",
			"What kind of car person will you be?",
			"Freedom on four wheels!",
		},
		text = "You're dreaming about your first car!",
		question = "What's your car situation?",
		minAge = 16, maxAge = 18,
		baseChance = 0.4,
		cooldown = 4,
		category = "teen",
		tags = { "teen", "car", "independence" },
		careerTags = { "trades", "racing" },
		
		choices = {
			{
				text = "💰 Saving for MY own car",
				effects = { Happiness = 4, Money = -100 },
				setFlags = { saving_for_car = true, financially_motivated = true, money_smart = true },
				hintCareer = "finance",
				feedText = "🚗 Every dollar goes to the car fund! Getting there!",
			},
			{
				text = "🎁 Parents might help/give me one",
				effects = { Happiness = 6 },
				setFlags = { expects_parent_car = true },
				feedText = "🚗 Fingers crossed! Birthday gift? Graduation present?",
			},
			{
				text = "🚌 Don't really need a car",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { okay_without_car = true, practical = true, environmentally_conscious = true },
				feedText = "🚗 Public transit, friends with cars... you're good!",
			},
			{
				text = "🛠️ Fix up an old one!",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { wants_project_car = true, hands_on_type = true, mechanic_interest = true, racing_interest = true },
				hintCareer = "trades",
				feedText = "🚗 A fixer-upper! You'll learn so much!",
			},
		},
	},

	{
		id = "teen_rebellion_phase",
		title = "Rebellion!",
		emoji = "😤",
		textVariants = {
			"Rules feel SO unfair!",
			"You're pushing back against authority!",
			"Why do adults think they know everything?!",
			"Time to make your own rules!",
		},
		text = "Rules feel SO unfair!",
		question = "How rebellious are you feeling?",
		minAge = 13, maxAge = 17,
		baseChance = 0.35,
		cooldown = 5,
		category = "teen",
		tags = { "teen", "rebellion", "growth" },
		
		choices = {
			{
				text = "🔥 Full rebel mode!",
				effects = { Happiness = 4 },
				setFlags = { rebellious_teen = true, questions_authority = true },
				feedText = "😤 Rules are meant to be broken! (Within reason...)",
			},
			{
				text = "🎨 Express it through art/music",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { creative_outlet = true, healthy_rebellion = true },
				feedText = "😤 Channeling feelings into creative expression!",
			},
			{
				text = "💬 Try to negotiate with parents",
				effects = { Happiness = 3, Smarts = 3 },
				setFlags = { diplomatic_teen = true, mature_communication = true },
				feedText = "😤 Having actual conversations about rules. Respect!",
			},
			{
				text = "😌 Not really my thing",
				effects = { Happiness = 2 },
				setFlags = { follows_rules = true, non_rebellious = true },
				feedText = "😤 Rules exist for reasons. You get it.",
			},
		},
	},

	{
		id = "teen_future_career_thoughts",
		title = "Future Dreams!",
		emoji = "💭",
		textVariants = {
			"What do you want to be when you grow up?",
			"Career day got you thinking...",
			"The future is coming - what's your path?",
			"Dreams, goals, aspirations!",
		},
		text = "What do you want to be when you grow up?",
		question = "What's your dream career?",
		minAge = 14, maxAge = 18,
		baseChance = 0.4,
		cooldown = 4,
		category = "teen",
		tags = { "teen", "career", "dreams" },
		
		choices = {
			{
				text = "💰 Something that pays well",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { money_motivated_career = true, practical_goals = true },
				feedText = "💭 Financial security is the goal. Respect the hustle!",
			},
			{
				text = "❤️ Follow my passion",
				effects = { Happiness = 6 },
				setFlags = { passion_driven = true, follows_heart = true },
				feedText = "💭 Do what you love and you'll never work a day!",
			},
			{
				text = "🌍 Help make the world better",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { wants_to_help_others = true, idealistic = true },
				feedText = "💭 Making a difference matters more than money!",
			},
			{
				text = "🤷 No idea yet",
				effects = { Happiness = 2 },
				setFlags = { undecided_career = true, exploring_options = true },
				feedText = "💭 Still figuring it out. That's totally okay!",
			},
		},
	},

	{
		id = "teen_romantic_devastation",
		title = "Heartbreak 💔",
		emoji = "💔",
		textVariants = {
			"Your first real heartbreak...",
			"A relationship ended and it HURTS.",
			"They broke up with you... or you broke up with them.",
			"Love hurts sometimes.",
		},
		text = "Your first real heartbreak...",
		question = "How do you cope?",
		minAge = 14, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		category = "teen",
		tags = { "teen", "heartbreak", "romance" },
		
		choices = {
			{
				text = "😭 Full sad mode",
				effects = { Happiness = -6 },
				setFlags = { experienced_heartbreak = true, feels_deeply = true },
				feedText = "💔 Ice cream. Sad music. Crying. This is PAIN.",
			},
			{
				text = "💪 Keep busy, stay strong",
				effects = { Happiness = -2, Smarts = 2 },
				setFlags = { experienced_heartbreak = true, resilient = true },
				feedText = "💔 Channeling energy into other things. Coping!",
			},
			{
				text = "👫 Lean on friends",
				effects = { Happiness = 2 },
				setFlags = { experienced_heartbreak = true, values_friendship = true },
				feedText = "💔 Friends are there for you. Group hug!",
			},
			{
				text = "🔜 Already over it",
				effects = { Happiness = 4 },
				setFlags = { experienced_heartbreak = true, moves_on_quick = true },
				feedText = "💔 That was quick! Plenty of fish in the sea!",
			},
		},
	},

	{
		id = "teen_school_stress_overload",
		title = "Academic Pressure!",
		emoji = "📚",
		textVariants = {
			"Tests, homework, expectations... SO much pressure!",
			"Your grades determine your future?! STRESS!",
			"AP classes, honors, extracurriculars... when do you SLEEP?",
			"The academic grind is REAL.",
		},
		text = "Tests, homework, expectations... SO much pressure!",
		question = "How are you handling it?",
		minAge = 14, maxAge = 18,
		baseChance = 0.45,
		cooldown = 4,
		category = "teen",
		tags = { "teen", "school", "stress" },
		
		choices = {
			{
				text = "💪 Thriving under pressure",
				effects = { Happiness = 4, Smarts = 4 },
				setFlags = { handles_pressure_well = true, academic_achiever = true },
				feedText = "📚 Pressure makes diamonds! You're CRUSHING it!",
			},
			{
				text = "😰 Barely keeping up",
				effects = { Happiness = -3, Health = -2 },
				setFlags = { academic_stress = true },
				feedText = "📚 It's a lot. You're surviving, barely.",
			},
			{
				text = "⚖️ Finding balance",
				effects = { Happiness = 3, Smarts = 2, Health = 2 },
				setFlags = { balanced_student = true },
				feedText = "📚 School matters but so does mental health!",
			},
			{
				text = "🤷 Grades aren't everything",
				effects = { Happiness = 5 },
				setFlags = { relaxed_about_grades = true },
				feedText = "📚 C's get degrees! (Or so you tell yourself)",
			},
		},
	},

	{
		id = "teen_online_friends",
		title = "Online Friendships!",
		emoji = "🌐",
		textVariants = {
			"You've made friends online who GET you!",
			"Internet friends are real friends!",
			"Your online community means a lot to you!",
			"Discord, gaming, forums - your people!",
		},
		text = "You've made friends online who GET you!",
		question = "How important are online friendships?",
		minAge = 13, maxAge = 18,
		baseChance = 0.4,
		cooldown = 4,
		category = "teen",
		tags = { "teen", "online", "friends" },
		
		choices = {
			{
				text = "💕 They're my best friends!",
				effects = { Happiness = 6 },
				setFlags = { values_online_friends = true, internet_social = true },
				feedText = "🌐 Real connection doesn't need physical presence!",
			},
			{
				text = "🎮 Gaming buddies are the best",
				effects = { Happiness = 5 },
				setFlags = { gaming_friends = true, gamer_social = true },
				feedText = "🌐 Victory royales and voice chats! Squad goals!",
			},
			{
				text = "⚖️ Online AND offline friends",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { balanced_friendships = true },
				feedText = "🌐 Best of both worlds! Double the friendships!",
			},
			{
				text = "🤷 Prefer in-person friends",
				effects = { Happiness = 3 },
				setFlags = { prefers_irl_friends = true },
				feedText = "🌐 Nothing beats hanging out face to face!",
			},
		},
	},

	{
		id = "teen_body_image",
		title = "Body Image",
		emoji = "🪞",
		textVariants = {
			"Society has a lot to say about bodies...",
			"How do you feel about your appearance?",
			"Social media vs. real life bodies...",
			"Mirror, mirror on the wall...",
		},
		text = "Society has a lot to say about bodies...",
		question = "How's your body image?",
		minAge = 13, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		category = "teen",
		tags = { "teen", "body_image", "wellness" },
		
		choices = {
			{
				text = "💪 Confident and comfortable!",
				effects = { Happiness = 6, Looks = 2 },
				setFlags = { body_confident = true, healthy_self_image = true },
				feedText = "🪞 You rock what you got! Confidence is ATTRACTIVE!",
			},
			{
				text = "🏋️ Working on self-improvement",
				effects = { Happiness = 4, Health = 3 },
				setFlags = { self_improvement_focused = true },
				feedText = "🪞 Healthy goals, healthy mindset! Progress!",
			},
			{
				text = "😔 Struggling with it",
				effects = { Happiness = -4 },
				setFlags = { body_image_issues = true },
				feedText = "🪞 It's hard. Remember - social media isn't real.",
			},
			{
				text = "🤷 Don't think about it much",
				effects = { Happiness = 3 },
				setFlags = { neutral_body_image = true },
				feedText = "🪞 It's just a body! More important things to think about.",
			},
		},
	},

	{
		id = "teen_senioritis",
		title = "Senioritis!",
		emoji = "😴",
		textVariants = {
			"Senior year and... you can't be bothered!",
			"Senioritis has officially set in!",
			"Almost done with high school... motivation: GONE!",
			"Why try when graduation is SO close?",
		},
		text = "Senior year and... you can't be bothered!",
		question = "How bad is the senioritis?",
		minAge = 17, maxAge = 18,
		baseChance = 0.35,
		cooldown = 4,
		category = "teen",
		tags = { "teen", "senior", "school" },
		
		choices = {
			{
				text = "😴 Terminal senioritis",
				effects = { Happiness = 4, Smarts = -2 },
				setFlags = { severe_senioritis = true },
				feedText = "😴 Showing up is optional at this point. Right?",
			},
			{
				text = "💪 Finishing strong!",
				effects = { Happiness = 3, Smarts = 4 },
				setFlags = { finishes_strong = true, disciplined = true },
				feedText = "😴 No senioritis here! Strong finish to high school!",
			},
			{
				text = "⚖️ Bare minimum mode",
				effects = { Happiness = 5 },
				setFlags = { minimum_effort = true },
				feedText = "😴 Just enough to pass. Strategic senioritis!",
			},
			{
				text = "🎉 Already celebrating!",
				effects = { Happiness = 7 },
				setFlags = { early_celebration = true },
				feedText = "😴 You're basically graduated already in your mind!",
			},
		},
	},

	{
		id = "teen_first_date",
		title = "First Date!",
		emoji = "💕",
		textVariants = {
			"You asked someone out... and they said YES!",
			"Your first real date is happening!",
			"Butterflies everywhere! First date nerves!",
			"Where should you go? What should you wear?!",
		},
		text = "You asked someone out... and they said YES!",
		question = "How does the date go?",
		minAge = 14, maxAge = 18,
		baseChance = 0.35,
		cooldown = 5,
		oneTime = true,
		category = "teen",
		tags = { "teen", "romance", "date" },
		blockedByFlags = { first_date_done = true },
		
		choices = {
			{
				text = "🌟 Amazing! Sparks flew!",
				effects = { Happiness = 10, Looks = 2 },
				setFlags = { first_date_done = true, great_first_date = true, romantic_success = true },
				feedText = "💕 Best night ever! Already planning date #2!",
			},
			{
				text = "😊 Nice! A little awkward but cute",
				effects = { Happiness = 6 },
				setFlags = { first_date_done = true, okay_first_date = true },
				feedText = "💕 Some awkward moments but overall sweet!",
			},
			{
				text = "😬 Disaster... SO awkward",
				effects = { Happiness = -3 },
				setFlags = { first_date_done = true, awkward_date = true },
				feedText = "💕 Cringe moments you'll remember forever. Learning experience!",
			},
			{
				text = "🤝 Friend-zoned but okay",
				effects = { Happiness = 2 },
				setFlags = { first_date_done = true, friend_zone_experience = true },
				feedText = "💕 'Let's just be friends.' Ouch but okay!",
			},
		},
	},
}

return Teen
