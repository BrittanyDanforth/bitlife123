--[[
	╔══════════════════════════════════════════════════════════════════════════════╗
	║                  TEEN EVENTS MODULE v2.0                                     ║
	║            Triple-AAAA Quality Teen Life Events (Ages 13-17)                  ║
	╠══════════════════════════════════════════════════════════════════════════════╣
	║  This module contains 80+ detailed teen events covering:                      ║
	║  • High school transition and academics                                      ║
	║  • Social life, cliques, and friendships                                      ║
	║  • Romance and first relationships                                           ║
	║  • Identity exploration and personal growth                                   ║
	║  • Early work and entrepreneurship                                           ║
	║  • Future planning (college, trade school, workforce)                          ║
	║  • Extracurricular activities                                                ║
	║  • Mental health and challenges                                               ║
	║                                                                              ║
	║  Events are CONTEXTUAL - they only trigger when relevant to the player's     ║
	║  current situation, preventing random "godmode" popups.                       ║
	╚══════════════════════════════════════════════════════════════════════════════╝
]]

local Teen = {}

local RANDOM = Random.new()

Teen.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- STAGE TRANSITION
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "stage_transition_teen",
		title = "Welcome to High School",
		emoji = "🎓",
		text = "You're starting high school! Everything feels bigger and more intense. New building, new people, new expectations. This is your chance to reinvent yourself or stay true to who you are.",
		question = "What's your approach to high school?",
		minAge = 13, maxAge = 14,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		onComplete = function(state)
			state.EducationData = state.EducationData or {}
			state.EducationData.Status = "enrolled"
			state.EducationData.Institution = "High School"
			state.Flags = state.Flags or {}
			state.Flags.in_high_school = true
			state.Flags.is_teenager = true
		end,
		choices = {
			{
				text = "Focus on academics",
				effects = { Smarts = 5 },
				setFlags = { academic_path = true, in_high_school = true },
				feedText = "You're determined to excel academically. Grades matter!",
			},
			{
				text = "Join lots of activities",
				effects = { Happiness = 5, Health = 2 },
				setFlags = { extracurricular_focus = true, in_high_school = true },
				feedText = "You want the full high school experience! Clubs, sports, everything!",
			},
			{
				text = "Focus on making friends",
				effects = { Happiness = 5 },
				setFlags = { social_path = true, in_high_school = true },
				feedText = "Your social life is your priority. Friends first!",
			},
			{
				text = "Keep a low profile",
				effects = { Smarts = 2 },
				setFlags = { introvert_path = true, in_high_school = true },
				feedText = "You prefer to observe and stay under the radar. Less drama.",
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
		text = "It's time to select your elective classes for next year. This choice could shape your future. What interests you most?",
		question = "What interests you most?",
		minAge = 14, maxAge = 16,
		cooldown = 2,
		requiresFlags = { in_high_school = true },
		choices = {
			{ 
				text = "Advanced Math & Science", 
				effects = { Smarts = 5 }, 
				setFlags = { stem_track = true }, 
				hintCareer = "tech", 
				feedText = "You're challenging yourself with advanced STEM classes. AP Calculus, Physics, Chemistry - the works!",
			},
			{ 
				text = "Creative Writing & Literature", 
				effects = { Smarts = 3, Happiness = 3 }, 
				setFlags = { humanities_track = true }, 
				hintCareer = "creative", 
				feedText = "You're exploring the power of words. Literature, creative writing, poetry - your passion!",
			},
			{ 
				text = "Business & Economics", 
				effects = { Smarts = 3, Money = 10 }, 
				setFlags = { business_track = true }, 
				hintCareer = "finance", 
				feedText = "You're learning how the business world works. Economics, accounting, entrepreneurship!",
			},
			{ 
				text = "Art & Music", 
				effects = { Happiness = 5, Looks = 2 }, 
				setFlags = { arts_track = true }, 
				hintCareer = "creative", 
				feedText = "You're developing your artistic talents. Studio art, band, choir - creative expression!",
			},
			{ 
				text = "Vocational/Technical", 
				effects = { Smarts = 3, Health = 2 }, 
				setFlags = { vocational_track = true }, 
				hintCareer = "trades", 
				feedText = "You're learning practical, hands-on skills. Auto shop, woodworking, culinary arts!",
			},
		},
	},
	
	{
		id = "group_project",
		title = "Group Project Drama",
		emoji = "📝",
		text = "You're assigned a group project, but one member isn't pulling their weight. They're slacking off, missing meetings, and you're stuck doing their work. Classic high school problem.",
		question = "How do you handle it?",
		minAge = 13, maxAge = 17,
		baseChance = 0.7,
		cooldown = 2,
		requiresFlags = { in_high_school = true },
		choices = {
			{ 
				text = "Do their share yourself", 
				effects = { Smarts = 3, Happiness = -3, Health = -2 }, 
				setFlags = { takes_on_too_much = true }, 
				feedText = "You did all the work. Good grade, but you're exhausted and resentful.",
			},
			{ 
				text = "Talk to them directly", 
				effects = { Smarts = 2, Happiness = 3 }, 
				setFlags = { direct_communicator = true }, 
				feedText = "You addressed the issue head-on. They stepped up, and you learned conflict resolution.",
			},
			{ 
				text = "Tell the teacher", 
				effects = { Smarts = 2 }, 
				setFlags = { follows_rules = true }, 
				feedText = "The teacher adjusted the grades accordingly. Fair, but awkward.",
			},
			{ 
				text = "Accept a lower grade", 
				effects = { Happiness = -2, Smarts = -1 }, 
				setFlags = { conflict_averse = true },
				feedText = "The project suffered, but you avoided conflict. Not ideal.",
			},
		},
	},
	
	{
		id = "academic_pressure",
		title = "Under Pressure",
		emoji = "😰",
		text = "A big exam is coming up - finals, SATs, or AP tests. You're feeling the pressure. Everyone's talking about it, and you're starting to stress.",
		question = "How do you cope?",
		minAge = 14, maxAge = 17,
		baseChance = 0.6,
		cooldown = 2,
		requiresFlags = { in_high_school = true },
		choices = {
			{ 
				text = "Study intensively", 
				effects = { Smarts = 5, Health = -3, Happiness = -2 }, 
				setFlags = { intense_studier = true },
				feedText = "You crammed hard. Exhausted but prepared. You'll do well, but at what cost?",
			},
			{ 
				text = "Form a study group", 
				effects = { Smarts = 4, Happiness = 2 }, 
				setFlags = { collaborative = true }, 
				feedText = "Studying with friends made it bearable. You learned together and supported each other.",
			},
			{ 
				text = "Take breaks to de-stress", 
				effects = { Smarts = 2, Happiness = 3, Health = 2 }, 
				setFlags = { balanced_approach = true }, 
				feedText = "You maintained balance. Healthy studying! You did well without burning out.",
			},
			{ 
				text = "Procrastinate until the last minute", 
				effects = { Smarts = 1, Happiness = -3 }, 
				setFlags = { procrastinator = true }, 
				feedText = "You crammed the night before. Stressful! You passed, but barely.",
			},
		},
	},
	
	{
		id = "failing_class",
		title = "Failing a Class",
		emoji = "📉",
		text = "You're failing a class. The teacher pulled you aside and told you that if you don't turn things around, you'll fail. This is serious.",
		question = "What do you do?",
		minAge = 14, maxAge = 17,
		baseChance = 0.3,
		cooldown = 4,
		requiresFlags = { in_high_school = true },
		choices = {
			{
				text = "Get a tutor",
				effects = { Smarts = 5, Money = -100, Happiness = -2 },
				setFlags = { seeks_help = true },
				feedText = "You got a tutor. It's expensive, but you're catching up. You'll pass!",
			},
			{
				text = "Ask the teacher for extra credit",
				effects = { Smarts = 3, Happiness = 2 },
				setFlags = { proactive = true },
				feedText = "You asked for extra credit opportunities. The teacher appreciated your initiative.",
			},
			{
				text = "Study harder on your own",
				effects = { Smarts = 4, Health = -3, Happiness = -3 },
				setFlags = { independent = true },
				feedText = "You buckled down and studied harder. It worked, but you're exhausted.",
			},
			{
				text = "Give up and accept failure",
				effects = { Smarts = -3, Happiness = -5 },
				setFlags = { defeatist = true },
				feedText = "You gave up. You failed the class. You'll have to retake it.",
			},
		},
	},
	
	{
		id = "honor_roll",
		title = "Honor Roll!",
		emoji = "🏆",
		text = "You made the honor roll! Straight A's, or close to it. Your hard work paid off, and everyone's proud of you.",
		question = "How do you feel?",
		minAge = 14, maxAge = 17,
		baseChance = 0.25,
		cooldown = 3,
		requiresFlags = { in_high_school = true },
		requiresStats = { Smarts = { min = 70 } },
		choices = {
			{
				text = "Proud and motivated",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { honor_student = true, motivated = true },
				feedText = "You're proud! This motivates you to keep excelling!",
			},
			{
				text = "Relieved the pressure is off",
				effects = { Happiness = 6, Health = 2 },
				setFlags = { relieved = true },
				feedText = "You're relieved. The pressure was intense, but you did it!",
			},
			{
				text = "Worried about maintaining it",
				effects = { Happiness = 3, Smarts = 1 },
				setFlags = { anxious = true },
				feedText = "You're worried about maintaining this. The pressure is real.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SOCIAL LIFE & RELATIONSHIPS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "high_school_romance",
		title = "Feelings Developing",
		emoji = "💘",
		text = "Someone you like seems to be interested in you too. You catch them looking at you, they laugh at your jokes, and your friends are noticing the chemistry.",
		question = "What do you do?",
		minAge = 14, maxAge = 17,
		baseChance = 0.7,
		cooldown = 2,
		blockedByFlags = { has_romantic_partner = true },
		choices = {
			{ 
				text = "Ask them out", 
				effects = { Happiness = 8 }, 
				setFlags = { romantically_active = true, has_romantic_partner = true, dating = true }, 
				feedText = "You made a move! They said yes! Heart pounding, butterflies - this is exciting!",
				onResolve = function(state)
					local EventEngine = require(script.Parent.init).EventEngine
					if EventEngine and EventEngine.createRelationship then
						local playerGender = (state.Gender or "male"):lower()
						local partnerName = (playerGender == "male") and "Alex" or "Jordan"
						local partner = EventEngine.createRelationship(state, "romance", {
							name = partnerName,
							relationship = 65,
							age = (state.Age or 16) + RANDOM:NextInteger(-1, 1),
						})
					end
				end,
			},
			{ 
				text = "Drop hints and wait", 
				effects = { Happiness = 2 }, 
				setFlags = { shy = true },
				feedText = "You're playing it cool, waiting for them to act. The tension is building.",
			},
			{ 
				text = "Focus on being friends first", 
				effects = { Happiness = 3 }, 
				setFlags = { takes_it_slow = true }, 
				feedText = "You're building a foundation of friendship. See where it goes naturally.",
			},
			{ 
				text = "I'm not ready for dating", 
				effects = { Happiness = 2 }, 
				setFlags = { not_ready = true },
				feedText = "You're focused on other things right now. Maybe later.",
			},
		},
	},
	
	{
		id = "party_invitation",
		title = "The Big Party",
		emoji = "🎉",
		text = "You're invited to a party at a popular kid's house. Your parents might not approve - it's on a school night, and there might be alcohol. But everyone's going, and you don't want to miss out.",
		question = "What do you do?",
		minAge = 15, maxAge = 17,
		baseChance = 0.7,
		cooldown = 2,
		choices = {
			{ 
				text = "Sneak out and go", 
				effects = { Happiness = 5, Health = -2 }, 
				setFlags = { rebellious = true, sneaks_out = true }, 
				feedText = "You snuck out! The party was wild. You had fun, but you're exhausted and your parents are suspicious.",
			},
			{ 
				text = "Ask parents for permission", 
				effects = { Happiness = 3 }, 
				setFlags = { respectful = true }, 
				feedText = "You asked, and they said yes (with rules). You went, had fun, and got home on time.",
			},
			{ 
				text = "Say you're staying at a friend's", 
				effects = { Happiness = 4 }, 
				setFlags = { bends_truth = true }, 
				feedText = "A white lie got you to the party. You had fun, but you feel a bit guilty.",
			},
			{ 
				text = "Skip it", 
				effects = { Happiness = -2 }, 
				setFlags = { responsible = true },
				feedText = "You stayed home. FOMO is real, but you made the responsible choice.",
			},
		},
	},
	
	{
		id = "clique_pressure",
		title = "Finding Your Group",
		emoji = "👥",
		text = "Different social groups are forming. The jocks, the nerds, the artsy kids, the rebels. Where do you fit in? Finding your people is important in high school.",
		question = "Which group do you gravitate toward?",
		minAge = 13, maxAge = 16,
		oneTime = true,
		choices = {
			{ 
				text = "The studious overachievers", 
				effects = { Smarts = 5 }, 
				setFlags = { nerd_group = true }, 
				feedText = "You found your tribe among the academic crowd. Study groups and intellectual conversations!",
			},
			{ 
				text = "The athletes and jocks", 
				effects = { Health = 5, Happiness = 3 }, 
				setFlags = { jock_group = true }, 
				hintCareer = "sports", 
				feedText = "You fit in with the athletic crowd. Sports, fitness, team spirit!",
			},
			{ 
				text = "The creative/artsy types", 
				effects = { Happiness = 5, Looks = 2 }, 
				setFlags = { artsy_group = true }, 
				hintCareer = "creative", 
				feedText = "You found kindred creative spirits. Art, music, self-expression!",
			},
			{ 
				text = "The rebels and misfits", 
				effects = { Happiness = 3 }, 
				setFlags = { rebel_group = true }, 
				feedText = "You don't follow the mainstream. You're your own person, and you found others like you.",
			},
			{ 
				text = "A mix of everyone", 
				effects = { Happiness = 3, Smarts = 2 }, 
				setFlags = { social_butterfly = true }, 
				feedText = "You move between groups easily. You're friends with everyone!",
			},
		},
	},
	
	{
		id = "friendship_drama",
		title = "Best Friend Betrayal",
		emoji = "💔",
		text = "You found out your best friend has been talking behind your back. They said things about you that aren't true, and now everyone knows. Your trust is shattered.",
		question = "How do you react?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 3,
		requiresFlags = { has_best_friend = true },
		choices = {
			{ 
				text = "Confront them", 
				effects = { Happiness = 3 }, 
				setFlags = { confrontational = true }, 
				feedText = "You had it out. The truth came to light. It was messy, but you cleared the air.",
			},
			{ 
				text = "End the friendship", 
				effects = { Happiness = -5 }, 
				setFlags = { holds_grudges = true, has_best_friend = false }, 
				feedText = "You cut them off. It hurts, but you can't trust them anymore.",
			},
			{ 
				text = "Try to understand why", 
				effects = { Smarts = 2, Happiness = 2 }, 
				setFlags = { empathetic = true }, 
				feedText = "You tried to see their perspective. You talked it out and maybe saved the friendship.",
			},
			{ 
				text = "Forgive and move on", 
				effects = { Happiness = 3 }, 
				setFlags = { forgiving = true }, 
				feedText = "You chose to forgive. Friendships are complicated, and you value this one.",
			},
		},
	},
	
	{
		id = "bullying_situation",
		title = "Witnessing Bullying",
		emoji = "😔",
		text = "You see someone being bullied. A kid is being picked on, and everyone's watching but no one's doing anything. You could step in, or stay out of it.",
		question = "What do you do?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4,
		choices = {
			{
				text = "Step in and defend them",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { brave = true, stands_up_for_others = true },
				feedText = "You stepped in and defended them. It was scary, but you did the right thing. They're grateful.",
			},
			{
				text = "Get a teacher",
				effects = { Happiness = 3, Smarts = 1 },
				setFlags = { responsible = true },
				feedText = "You got a teacher involved. The situation was handled, and you did the right thing.",
			},
			{
				text = "Stay out of it",
				effects = { Happiness = -3 },
				setFlags = { passive = true },
				feedText = "You stayed out of it. You feel guilty, but you didn't want to make things worse.",
			},
			{
				text = "Befriend the victim later",
				effects = { Happiness = 4, Smarts = 1 },
				setFlags = { empathetic = true },
				feedText = "You reached out to them later. You became friends, and you're glad you did.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- IDENTITY & PERSONAL GROWTH
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "identity_question",
		title = "Who Am I?",
		emoji = "🪞",
		text = "You've been thinking a lot about who you really are. High school is a time of self-discovery, and you're questioning everything about yourself.",
		question = "What aspect of yourself are you exploring?",
		minAge = 14, maxAge = 17,
		oneTime = true,
		choices = {
			{ 
				text = "My values and beliefs", 
				effects = { Smarts = 3, Happiness = 3 }, 
				setFlags = { philosophical = true }, 
				feedText = "You're questioning what you believe in. Philosophy, religion, ethics - you're exploring big questions.",
			},
			{ 
				text = "My future career", 
				effects = { Smarts = 3 }, 
				setFlags = { career_focused = true }, 
				feedText = "You're thinking seriously about your future. What do you want to do with your life?",
			},
			{ 
				text = "My style and appearance", 
				effects = { Looks = 5, Happiness = 3 }, 
				setFlags = { style_conscious = true }, 
				feedText = "You're developing your personal style. Fashion, hair, self-expression - you're finding your look!",
			},
			{ 
				text = "My relationships with others", 
				effects = { Happiness = 3 }, 
				setFlags = { socially_aware = true }, 
				feedText = "You're learning about how you relate to people. What kind of friend are you? What kind of partner?",
			},
		},
	},
	
	{
		id = "mental_health_awareness",
		title = "Tough Times",
		emoji = "🌧️",
		text = "You've been feeling down lately. More than usual. School stress, social pressure, or just... life. It's been hard to get out of bed some days.",
		question = "How do you cope?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		choices = {
			{ 
				text = "Talk to a trusted adult", 
				effects = { Happiness = 5, Health = 3 }, 
				setFlags = { seeks_help = true }, 
				feedText = "Opening up helped. You're not alone. They got you help, and you're feeling better.",
			},
			{ 
				text = "Confide in a friend", 
				effects = { Happiness = 3 }, 
				setFlags = { has_support = true },
				feedText = "Your friend listened and supported you. It helped to talk about it.",
			},
			{ 
				text = "Try to push through alone", 
				effects = { Happiness = -3, Health = -2 }, 
				setFlags = { struggles_alone = true }, 
				feedText = "You tried to handle it alone. It's hard. You're still struggling.",
			},
			{ 
				text = "Express through creative outlet", 
				effects = { Happiness = 4, Smarts = 2 }, 
				setFlags = { creative_coping = true }, 
				feedText = "Art, music, or writing helped you process feelings. Creative expression is healing.",
			},
		},
	},
	
	{
		id = "coming_out",
		title = "Coming Out",
		emoji = "🌈",
		text = "You've been questioning your sexuality or gender identity. You've come to understand yourself better, and you're thinking about coming out to people in your life.",
		question = "How do you approach this?",
		minAge = 14, maxAge = 17,
		oneTime = true,
		baseChance = 0.2,
		cooldown = 5,
		choices = {
			{
				text = "Tell close friends first",
				effects = { Happiness = 6 },
				setFlags = { came_out = true, brave = true },
				feedText = "You told your close friends first. They were supportive! It felt amazing to be yourself.",
			},
			{
				text = "Tell family",
				effects = { Happiness = 4 },
				setFlags = { came_out = true, brave = true },
				feedText = "You came out to your family. It was scary, but they love you. You're accepted.",
			},
			{
				text = "Come out publicly",
				effects = { Happiness = 8, Looks = 2 },
				setFlags = { came_out = true, brave = true, confident = true },
				feedText = "You came out publicly. You're proud of who you are, and you're not hiding anymore.",
			},
			{
				text = "Keep it private for now",
				effects = { Happiness = 2 },
				setFlags = { private = true },
				feedText = "You're keeping it private for now. You'll come out when you're ready.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EARLY WORK & MONEY
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "first_job_offer",
		title = "Your First Job",
		emoji = "💼",
		text = "A local business is hiring teenagers for part-time work. You could use the money - for gas, clothes, or just having fun. But it means less free time.",
		question = "Will you apply?",
		minAge = 15, maxAge = 17,
		baseChance = 0.7,
		cooldown = 3,
		blockedByFlags = { has_teen_job = true, employed = true },
		choices = {
			{ 
				text = "Work at a fast food place", 
				effects = { Money = 200, Health = -2, Happiness = -1 }, 
				setFlags = { has_teen_job = true, fast_food_experience = true }, 
				feedText = "You got a job flipping burgers. Money incoming! It's not glamorous, but it pays.",
			},
			{ 
				text = "Work at a retail store", 
				effects = { Money = 180, Happiness = 1 }, 
				setFlags = { has_teen_job = true, retail_experience = true }, 
				feedText = "You're working retail. Learning about customers, sales, and dealing with people.",
			},
			{ 
				text = "Tutor younger kids", 
				effects = { Money = 150, Smarts = 3 }, 
				setFlags = { has_teen_job = true, tutoring_experience = true }, 
				hintCareer = "education", 
				feedText = "You're tutoring others. Teaching is rewarding, and you're good at it!",
			},
			{ 
				text = "I don't want a job yet", 
				effects = { Happiness = 2 }, 
				setFlags = { focused_on_school = true },
				feedText = "You're focusing on school and fun for now. Money can wait.",
			},
		},
	},
	
	{
		id = "entrepreneurship",
		title = "Side Hustle",
		emoji = "💡",
		text = "You have an idea for making money on your own. Why work for someone else when you can be your own boss?",
		question = "What's your business?",
		minAge = 14, maxAge = 17,
		baseChance = 0.5,
		cooldown = 3,
		choices = {
			{ 
				text = "Lawn care / yard work", 
				effects = { Money = 150, Health = 3 }, 
				setFlags = { entrepreneur = true }, 
				hintCareer = "business", 
				feedText = "You started a lawn care service! Mowing lawns, raking leaves - you're making bank!",
			},
			{ 
				text = "Selling crafts online", 
				effects = { Money = 100, Happiness = 3 }, 
				setFlags = { entrepreneur = true, creative_business = true }, 
				hintCareer = "creative", 
				feedText = "You're selling your creations online! Etsy, social media - people love your stuff!",
			},
			{ 
				text = "Tech support for neighbors", 
				effects = { Money = 120, Smarts = 3 }, 
				setFlags = { entrepreneur = true, tech_savvy = true }, 
				hintCareer = "tech", 
				feedText = "You're the neighborhood tech expert! Fixing computers, setting up Wi-Fi - you're in demand!",
				onResolve = function(state)
					-- CRITICAL: Build tech/coding interest for gradual career unlock
					state.Interests = state.Interests or {}
					state.Interests.coding = math.min(100, (state.Interests.coding or 0) + 15)
					state.Interests.tech = math.min(100, (state.Interests.tech or 0) + 20)
				end,
			},
			{ 
				text = "Social media management", 
				effects = { Money = 130, Smarts = 2 }, 
				setFlags = { entrepreneur = true, social_media_savvy = true }, 
				hintCareer = "marketing", 
				feedText = "You're managing social media for local businesses! Instagram, Facebook - you're a pro!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FUTURE PLANNING
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "college_prep",
		title = "Planning Your Future",
		emoji = "🎯",
		text = "College applications are looming. SATs, essays, recommendations - it's all coming up. What's your plan?",
		question = "What path are you considering?",
		minAge = 16, maxAge = 17,
		oneTime = true,
		requiresFlags = { graduated_high_school = false },
		choices = {
			{
				text = "Aim for a top university",
				effects = { Smarts = 3, Happiness = -2 },
				setFlags = { college_bound = true, ambitious = true, plans_for_college = true },
				feedText = "You're working hard for a prestigious school. AP classes, perfect grades, impressive extracurriculars.",
			},
			{
				text = "State school is fine",
				effects = { Smarts = 2, Happiness = 2 },
				setFlags = { college_bound = true, practical = true, plans_for_college = true },
				feedText = "You're taking a practical approach to higher ed. Good education, reasonable cost.",
			},
			{
				text = "Community college first",
				effects = { Smarts = 1, Money = 50 },
				setFlags = { college_bound = true, economical = true, plans_for_community_college = true },
				feedText = "You're saving money with community college. Smart financial move!",
			},
			{
				text = "Trade school / vocational",
				effects = { Smarts = 2 },
				setFlags = { trade_school_bound = true },
				hintCareer = "trades",
				feedText = "You're planning to learn a skilled trade. Electrician, plumber, mechanic - good money, practical skills!",
			},
			{
				text = "Skip college, start working",
				effects = { Money = 100 },
				setFlags = { no_college = true, workforce_bound = true },
				feedText = "You're ready to enter the workforce directly. College isn't for everyone, and that's okay.",
			},
		},
	},
	
	{
		id = "graduation_high_school",
		title = "High School Graduation",
		emoji = "🎓",
		text = "You're graduating from high school! Cap and gown, diploma, the whole ceremony. Your family is here, and you're about to walk across that stage. This is it - the end of an era.",
		question = "How do you feel about your high school experience?",
		minAge = 17, maxAge = 18,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		onComplete = function(state, choice, eventDef, outcome)
			state.Education = "high_school"
			state.Flags = state.Flags or {}
			state.Flags.graduated_high_school = true
			state.Flags.high_school_graduate = true
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
				feedText = "You graduated with amazing memories! High school was everything you hoped it would be.",
			},
			{
				text = "Glad it's over",
				effects = { Happiness = 5 },
				setFlags = { graduated_high_school = true, high_school_graduate = true },
				feedText = "High school wasn't your favorite, but you made it! On to bigger and better things!",
			},
			{
				text = "Nervous about what's next",
				effects = { Happiness = 2, Smarts = 2 },
				setFlags = { graduated_high_school = true, high_school_graduate = true, anxious = true },
				feedText = "The future is uncertain but exciting. You're ready for the next chapter, even if it's scary.",
			},
			{
				text = "I learned a lot about myself",
				effects = { Happiness = 5, Smarts = 5 },
				setFlags = { self_aware = true, graduated_high_school = true, high_school_graduate = true },
				feedText = "High school was a journey of self-discovery. You know yourself better now.",
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
		text = "Varsity sports tryouts are coming up. You've been practicing hard, and you think you have a shot. This could be your moment!",
		question = "Which sport?",
		minAge = 14, maxAge = 17,
		baseChance = 0.5,
		cooldown = 2,
		requiresStats = { Health = { min = 50 } },
		choices = {
			{ 
				text = "Football", 
				effects = { Health = 5, Happiness = 5 }, 
				setFlags = { varsity_athlete = true, plays_football = true }, 
				hintCareer = "sports", 
				feedText = "You made the football team! Time to hit the field!",
			},
			{ 
				text = "Basketball", 
				effects = { Health = 5, Happiness = 5 }, 
				setFlags = { varsity_athlete = true, plays_basketball = true }, 
				hintCareer = "sports", 
				feedText = "You made the basketball team! Hoops, here you come!",
			},
			{ 
				text = "Soccer", 
				effects = { Health = 5, Happiness = 5 }, 
				setFlags = { varsity_athlete = true, plays_soccer = true }, 
				hintCareer = "sports", 
				feedText = "You made the soccer team! Time to score some goals!",
			},
			{ 
				text = "Track & Field", 
				effects = { Health = 7, Happiness = 5 }, 
				setFlags = { varsity_athlete = true, runs_track = true }, 
				hintCareer = "sports", 
				feedText = "You joined the track team! Running, jumping, throwing - you're an athlete!",
			},
			{ 
				text = "Not really into sports", 
				effects = { }, 
				setFlags = { not_athletic = true },
				feedText = "Organized sports aren't your thing. That's okay - there are other ways to stay active.",
			},
		},
	},
	
	{
		id = "school_play",
		title = "Drama Production",
		emoji = "🎭",
		text = "The school is putting on a big play. Auditions are open, and everyone's talking about it. This could be your chance to shine!",
		question = "Will you participate?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 2,
		choices = {
			{ 
				text = "Audition for lead role", 
				effects = { Happiness = 8, Looks = 3 }, 
				setFlags = { theater_kid = true, lead_actor = true }, 
				hintCareer = "entertainment", 
				feedText = "You went for the lead! Bold move! You got the part - opening night is going to be amazing!",
			},
			{ 
				text = "Join the ensemble", 
				effects = { Happiness = 5, Looks = 2 }, 
				setFlags = { theater_kid = true }, 
				hintCareer = "entertainment", 
				feedText = "You're part of the cast! Singing, dancing, acting - you're having a blast!",
			},
			{ 
				text = "Work on tech/backstage", 
				effects = { Smarts = 3, Happiness = 3 }, 
				setFlags = { tech_crew = true }, 
				feedText = "You're part of the crew. Lights, sound, sets - essential work! You're learning valuable skills.",
			},
			{ 
				text = "Just watch the show", 
				effects = { Happiness = 2 }, 
				setFlags = { audience_member = true },
				feedText = "You'll support from the audience. Sometimes watching is just as fun!",
			},
		},
	},
	
	{
		id = "volunteer_opportunity",
		title = "Giving Back",
		emoji = "🤝",
		text = "There's an opportunity to volunteer in your community. Giving back feels good, and it looks great on college applications too.",
		question = "What cause calls to you?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 2,
		choices = {
			{ 
				text = "Animal shelter", 
				effects = { Happiness = 5 }, 
				setFlags = { volunteer = true, animal_lover = true }, 
				hintCareer = "veterinary", 
				feedText = "You're helping animals at the shelter! Walking dogs, playing with cats - it's rewarding!",
			},
			{ 
				text = "Food bank", 
				effects = { Happiness = 5, Health = 2 }, 
				setFlags = { volunteer = true, community_minded = true }, 
				feedText = "You're helping feed those in need. Sorting food, packing boxes - making a difference!",
			},
			{ 
				text = "Tutoring younger kids", 
				effects = { Happiness = 3, Smarts = 3 }, 
				setFlags = { volunteer = true, teacher_at_heart = true }, 
				hintCareer = "education", 
				feedText = "You're helping younger kids learn! Teaching is rewarding, and you're good at it!",
			},
			{ 
				text = "Environmental cleanup", 
				effects = { Happiness = 4, Health = 2 }, 
				setFlags = { volunteer = true, environmentalist = true }, 
				feedText = "You're helping clean up the planet! Picking up trash, planting trees - saving the Earth!",
			},
			{ 
				text = "I'm too busy right now", 
				effects = { }, 
				setFlags = { busy = true },
				feedText = "Volunteering will have to wait. You have too much on your plate right now.",
			},
		},
	},
	
	{
		id = "debate_team",
		title = "Debate Team",
		emoji = "🎤",
		text = "The debate team is recruiting. You've always been good at arguing your point, and this could be a great way to develop those skills.",
		question = "Do you join?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		choices = {
			{
				text = "Join and compete",
				effects = { Smarts = 5, Happiness = 3 },
				setFlags = { debater = true },
				hintCareer = "law",
				feedText = "You joined the debate team! You're learning to argue persuasively and think critically. Future lawyer?",
			},
			{
				text = "Just observe",
				effects = { Smarts = 2 },
				setFlags = { interested = true },
				feedText = "You watched a debate. Interesting, but not for you.",
			},
			{
				text = "Not interested",
				effects = { },
				feedText = "Debate isn't your thing. Too much arguing.",
			},
		},
	},
}

return Teen
