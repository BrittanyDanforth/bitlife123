--[[
	LifeEvents/init.lua
	
	COMPREHENSIVE Event system for BitLife-style game.
	All events are defined inline with full contextual requirements.
	
	CONTEXTUAL REQUIREMENTS:
	- requiresJob: Event only triggers if player has a job
	- requiresNoJob: Event only triggers if player is unemployed
	- requiresJobCategory: Event requires specific job type (tech, medical, law, etc.)
	- requiresPartner: Event only triggers if player has a romantic partner
	- requiresSingle: Event only triggers if player is single
	- requiresFlags: Table of flags that must be true/false
	- requiresStats: Table of stat requirements (e.g., { Smarts = { min = 60 } })
	- requiresEducation: Minimum education level required
]]

local LifeEvents = {}
local RANDOM = Random.new()

-- Master event registry
local AllEvents = {}
local EventsByCategory = {}

-- ════════════════════════════════════════════════════════════════════════════════════
-- COMPLETE EVENT POOLS - ALL EVENTS WITH CONTEXTUAL REQUIREMENTS
-- ════════════════════════════════════════════════════════════════════════════════════

local EventPools = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CHILDHOOD (Ages 0-12)
	-- ══════════════════════════════════════════════════════════════════════════════
	childhood = {
		{
			id = "first_words",
			title = "First Words",
			emoji = "👶",
			category = "milestone",
			text = "Your parents are excited - you just spoke your first word!",
			question = "What did you say?",
			minAge = 1, maxAge = 2,
			oneTime = true,
			priority = "high",
			isMilestone = true,
			choices = {
				{ text = '"Mama"', effects = { Happiness = 5 }, setFlags = { first_word = "mama" }, feedText = "You said your first word: 'Mama'. Your mother was overjoyed." },
				{ text = '"Dada"', effects = { Happiness = 5 }, setFlags = { first_word = "dada" }, feedText = "You said your first word: 'Dada'. Your father beamed with pride." },
				{ text = '"No!"', effects = { Happiness = 3 }, setFlags = { first_word = "no", rebellious_streak = true }, feedText = "Your first word was 'No!' - already showing your independent spirit." },
				{ text = "An attempt at the dog's name", effects = { Happiness = 4 }, setFlags = { first_word = "pet", animal_lover = true }, hintCareer = "veterinary", feedText = "You tried to say the dog's name. Pets already have your heart." },
			},
		},
		{
			id = "first_steps",
			title = "First Steps",
			emoji = "🚶",
			category = "milestone",
			text = "You're standing up and ready to take your first steps!",
			question = "How do you approach this challenge?",
			minAge = 1, maxAge = 2,
			oneTime = true,
			priority = "high",
			isMilestone = true,
			choices = {
				{ text = "Carefully and cautiously", effects = { Smarts = 2 }, setFlags = { cautious_personality = true }, feedText = "You took careful, measured first steps. Safety first!" },
				{ text = "Boldly charge forward", effects = { Health = -2, Happiness = 5 }, setFlags = { adventurous_spirit = true }, feedText = "You ran before you could walk - and took a tumble. But you got right back up!" },
				{ text = "Wait for encouragement", effects = { Happiness = 3 }, setFlags = { seeks_approval = true }, feedText = "With your parents cheering, you walked right into their arms." },
			},
		},
		{
			id = "preschool_start",
			title = "First Day of Preschool",
			emoji = "🎒",
			category = "education",
			text = "It's your first day of preschool! Your parents drop you off at the colorful building.",
			question = "How do you handle being away from home?",
			minAge = 3, maxAge = 4,
			oneTime = true,
			priority = "high",
			choices = {
				{ text = "Cry and cling to mom/dad", effects = { Happiness = -5 }, feedText = "The first day was rough. Lots of tears, but you survived." },
				{ text = "March in confidently", effects = { Happiness = 5, Smarts = 2 }, setFlags = { socially_confident = true }, feedText = "You walked in like you owned the place. New friends incoming!" },
				{ text = "Quietly observe the other kids", effects = { Smarts = 3 }, setFlags = { observant = true }, hintCareer = "science", feedText = "You watched everything carefully. An analytical mind is forming." },
				{ text = "Immediately find the art supplies", effects = { Happiness = 5, Looks = 1 }, setFlags = { artistic_interest = true }, hintCareer = "creative", feedText = "You made a beeline for the crayons. A creative soul!" },
			},
		},
		{
			id = "birth_story",
			title = "Your Birth Story",
			emoji = "🍼",
			category = "milestone",
			text = "Your parents sometimes tell the story of when you were born.",
			question = "What was memorable about your arrival?",
			minAge = 3, maxAge = 6,
			oneTime = true,
			isMilestone = true,
			choices = {
				{ text = "I was born early but healthy", effects = { Health = 5 }, setFlags = { premature_birth = true, fighter = true }, feedText = "You came early but showed your strength from day one." },
				{ text = "A perfectly normal delivery", effects = { Happiness = 3 }, feedText = "You arrived right on schedule." },
				{ text = "There were complications, but I made it", effects = { Health = -3 }, setFlags = { difficult_birth = true, survivor = true }, feedText = "Your birth was difficult, but you're a fighter." },
				{ text = "I was a very big baby", effects = { Health = 3 }, setFlags = { big_baby = true }, feedText = "You were a healthy, robust baby!" },
			},
		},
		{
			id = "family_background",
			title = "Your Family",
			emoji = "👨‍👩‍👧",
			category = "milestone",
			text = "As you grow, you start to understand your family situation.",
			question = "What kind of family do you have?",
			minAge = 4, maxAge = 7,
			oneTime = true,
			priority = "high",
			isMilestone = true,
			choices = {
				{ text = "Two loving parents", effects = { Happiness = 10 }, setFlags = { two_parent_home = true, stable_home = true }, feedText = "You have a supportive, loving family." },
				{ text = "Single parent working hard", effects = { Happiness = 3, Smarts = 2 }, setFlags = { single_parent = true, independent_early = true }, feedText = "Your parent works hard to provide for you." },
				{ text = "Living with grandparents", effects = { Happiness = 5, Smarts = 3 }, setFlags = { raised_by_grandparents = true }, feedText = "Your grandparents raised you with wisdom and love." },
				{ text = "Large extended family", effects = { Happiness = 8 }, setFlags = { big_family = true }, feedText = "You're surrounded by relatives!" },
			},
		},
		{
			id = "imaginary_friend",
			title = "Imaginary Friend",
			emoji = "👻",
			category = "social",
			text = "You've been spending a lot of time talking to your 'invisible friend.'",
			question = "Who is your imaginary friend?",
			minAge = 3, maxAge = 5,
			oneTime = true,
			baseChance = 0.6,
			choices = {
				{ text = "A brave superhero", effects = { Happiness = 5 }, setFlags = { hero_complex = true }, feedText = "Your imaginary superhero friend makes you feel invincible." },
				{ text = "A wise wizard", effects = { Smarts = 3 }, setFlags = { loves_fantasy = true }, hintCareer = "creative", feedText = "Your wizard friend teaches you 'magic' - really just creative problem solving." },
				{ text = "A friendly animal", effects = { Happiness = 3 }, setFlags = { animal_lover = true }, hintCareer = "veterinary", feedText = "Your animal friend understands you like no human does." },
				{ text = "I don't need imaginary friends", effects = { Smarts = 2 }, setFlags = { pragmatic = true }, feedText = "You prefer real friends. Very practical for your age." },
			},
		},
		{
			id = "losing_tooth",
			title = "First Lost Tooth",
			emoji = "🦷",
			category = "milestone",
			text = "Your first baby tooth fell out!",
			question = "What do you do with it?",
			minAge = 5, maxAge = 7,
			oneTime = true,
			isMilestone = true,
			choices = {
				{ text = "Put it under my pillow for the tooth fairy", effects = { Happiness = 5, Money = 5 }, feedText = "The tooth fairy left you some money!" },
				{ text = "Keep it in a special box", effects = { Happiness = 3 }, setFlags = { sentimental = true }, feedText = "You're saving your teeth for some reason." },
				{ text = "Show it off to everyone", effects = { Happiness = 5, Looks = 1 }, feedText = "You proudly showed off your gap-toothed smile!" },
			},
		},
		{
			id = "learned_bike",
			title = "Learning to Ride a Bike",
			emoji = "🚲",
			category = "milestone",
			text = "You're learning to ride a bike!",
			question = "How does it go?",
			minAge = 5, maxAge = 8,
			oneTime = true,
			isMilestone = true,
			choices = {
				{ text = "Got it on the first try!", effects = { Happiness = 8, Health = 3 }, setFlags = { natural_athlete = true }, feedText = "You're a natural! Freedom on two wheels!" },
				{ text = "Fell a lot, but kept trying", effects = { Happiness = 5, Health = -2 }, setFlags = { persistent = true }, feedText = "You got some scrapes, but you never gave up!" },
				{ text = "Needed training wheels for a while", effects = { Happiness = 3 }, setFlags = { cautious_learner = true }, feedText = "You took your time, but you got there." },
				{ text = "Too scared, gave up", effects = { Happiness = -3 }, setFlags = { bike_phobia = true }, feedText = "Bikes aren't for everyone... yet." },
			},
		},
		{
			id = "discovered_passion",
			title = "Finding Your Passion",
			emoji = "⭐",
			category = "milestone",
			text = "Something really captured your interest and imagination!",
			question = "What got you excited?",
			minAge = 6, maxAge = 12,
			oneTime = true,
			isMilestone = true,
			choices = {
				{ text = "Sports and athletics", effects = { Health = 5, Happiness = 5 }, setFlags = { passionate_athlete = true }, hintCareer = "sports", feedText = "You fell in love with sports!" },
				{ text = "Art and creativity", effects = { Happiness = 7, Looks = 3 }, setFlags = { passionate_artist = true }, hintCareer = "creative", feedText = "Your creative soul awakened!" },
				{ text = "Science and discovery", effects = { Smarts = 7 }, setFlags = { passionate_scientist = true }, hintCareer = "science", feedText = "The mysteries of the universe call to you!" },
				{ text = "Building and creating things", effects = { Smarts = 5, Happiness = 3 }, setFlags = { passionate_builder = true }, hintCareer = "tech", feedText = "You love making things with your hands and mind!" },
				{ text = "Helping and caring for others", effects = { Happiness = 5 }, setFlags = { passionate_helper = true }, hintCareer = "medical", feedText = "You have a natural desire to help others!" },
			},
		},
		{
			id = "first_best_friend",
			title = "A New Best Friend",
			emoji = "🤝",
			category = "social",
			text = "You've been hanging out with a kid from class a lot. They might become your best friend!",
			question = "What do you two do together?",
			minAge = 5, maxAge = 8,
			oneTime = true,
			choices = {
				{ text = "Play imaginative games", effects = { Happiness = 5, Smarts = 2 }, setFlags = { creative_play = true, has_best_friend = true }, feedText = "You and your new best friend create entire worlds together." },
				{ text = "Build things with blocks/Legos", effects = { Smarts = 5, Happiness = 3 }, setFlags = { builder = true, has_best_friend = true }, hintCareer = "tech", feedText = "You're a building team! Engineering minds in the making." },
				{ text = "Play sports outside", effects = { Health = 5, Happiness = 3 }, setFlags = { sporty = true, has_best_friend = true }, hintCareer = "sports", feedText = "You and your friend are always running around outside." },
				{ text = "Read and explore together", effects = { Smarts = 5 }, setFlags = { curious = true, has_best_friend = true }, hintCareer = "science", feedText = "You're partners in curiosity, always discovering new things." },
			},
		},
		{
			id = "school_bully",
			title = "Trouble on the Playground",
			emoji = "😠",
			category = "conflict",
			text = "An older kid at school has been picking on you and other kids.",
			question = "How do you handle this?",
			minAge = 6, maxAge = 10,
			baseChance = 0.6,
			cooldown = 3,
			choices = {
				{ text = "Stand up to them", effects = { Happiness = 5 }, setFlags = { brave = true }, feedText = "You stood up to the bully. It was scary, but you earned respect." },
				{ text = "Tell a teacher", effects = { Happiness = 2, Smarts = 2 }, setFlags = { trusts_authority = true }, feedText = "You told an adult. The bully got in trouble." },
				{ text = "Avoid them completely", effects = { Happiness = -3 }, setFlags = { conflict_avoidant = true }, feedText = "You learned which hallways to avoid. Safety first." },
				{ text = "Try to befriend them", effects = { Smarts = 3 }, setFlags = { peacemaker = true }, hintCareer = "social_work", feedText = "You tried to understand why they're mean. Sometimes kindness works." },
			},
		},
		{
			id = "pet_encounter",
			title = "A Pet of Your Own",
			emoji = "🐕",
			category = "responsibility",
			text = "Your parents agree to let you have a pet - but you must take care of it yourself.",
			question = "What pet do you choose?",
			minAge = 8, maxAge = 12,
			oneTime = true,
			baseChance = 0.5,
			choices = {
				{ text = "A dog", effects = { Happiness = 10, Health = 3 }, setFlags = { has_dog = true, animal_lover = true }, hintCareer = "veterinary", feedText = "You got a dog! A loyal companion for years to come." },
				{ text = "A cat", effects = { Happiness = 8 }, setFlags = { has_cat = true, animal_lover = true }, feedText = "You got a cat! Independent, but loving." },
				{ text = "A fish tank", effects = { Happiness = 3, Smarts = 2 }, setFlags = { has_fish = true }, feedText = "You set up a beautiful fish tank!" },
				{ text = "A hamster or guinea pig", effects = { Happiness = 5 }, setFlags = { has_small_pet = true, animal_lover = true }, feedText = "Your little furry friend is adorable!" },
			},
		},
		{
			id = "summer_camp",
			title = "Summer Camp",
			emoji = "🏕️",
			category = "experience",
			text = "Your parents are sending you to summer camp!",
			question = "What kind of camp appeals to you?",
			minAge = 8, maxAge = 12,
			baseChance = 0.5,
			cooldown = 2,
			choices = {
				{ text = "Outdoor adventure camp", effects = { Health = 5, Happiness = 5 }, setFlags = { nature_lover = true }, feedText = "You learned to hike, camp, and survive in nature!" },
				{ text = "Science camp", effects = { Smarts = 7 }, setFlags = { science_enthusiast = true }, hintCareer = "science", feedText = "You spent the summer doing cool experiments!" },
				{ text = "Arts camp", effects = { Happiness = 5, Looks = 3 }, setFlags = { artistic = true }, hintCareer = "creative", feedText = "You explored painting, sculpture, and more!" },
				{ text = "Sports camp", effects = { Health = 7, Happiness = 3 }, setFlags = { athlete = true }, hintCareer = "sports", feedText = "You trained hard and improved your athletic skills!" },
				{ text = "Computer/coding camp", effects = { Smarts = 7 }, setFlags = { coder = true }, hintCareer = "tech", feedText = "You learned to code! The digital world opens up." },
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- TEEN (Ages 13-17)
	-- ══════════════════════════════════════════════════════════════════════════════
	teen = {
		{
			id = "stage_transition_teen",
			title = "Welcome to High School",
			emoji = "🎓",
			category = "milestone",
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
		{
			id = "high_school_romance",
			title = "Feelings Developing",
			emoji = "💘",
			category = "romance",
			text = "Someone you like seems to be interested in you too.",
			question = "What do you do?",
			minAge = 14, maxAge = 17,
			baseChance = 0.7,
			cooldown = 2,
			choices = {
				{ text = "Ask them out", effects = { Happiness = 5 }, setFlags = { romantically_active = true, has_partner = true, dating = true }, feedText = "You made a move! Heart pounding." },
				{ text = "Drop hints and wait", effects = { Happiness = 2 }, feedText = "You're playing it cool, waiting for them to act." },
				{ text = "Focus on being friends first", effects = { Happiness = 3 }, setFlags = { takes_it_slow = true }, feedText = "You're building a foundation of friendship." },
				{ text = "I'm not ready for dating", effects = { Happiness = 2 }, feedText = "You're focused on other things right now." },
			},
		},
		{
			id = "clique_pressure",
			title = "Finding Your Group",
			emoji = "👥",
			category = "social",
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
			id = "new_hobby",
			title = "New Interest",
			emoji = "🎯",
			category = "hobby",
			text = "You discovered something that really interests you.",
			question = "What is it?",
			minAge = 13, maxAge = 17,
			baseChance = 0.5,
			cooldown = 3,
			choices = {
				{ text = "Gaming", effects = { Happiness = 5 }, setFlags = { gamer = true }, feedText = "Video games have captured your attention!" },
				{ text = "Music", effects = { Happiness = 5, Looks = 2 }, setFlags = { musician = true }, hintCareer = "entertainment", feedText = "You're learning to play music!" },
				{ text = "Writing/Reading", effects = { Smarts = 5 }, setFlags = { writer = true }, hintCareer = "creative", feedText = "You've discovered the power of words!" },
				{ text = "Sports/Fitness", effects = { Health = 5, Happiness = 3 }, setFlags = { fitness_focused = true }, hintCareer = "sports", feedText = "You're getting into shape!" },
			},
		},
		{
			id = "new_friendship",
			title = "Making New Friends",
			emoji = "🤗",
			category = "friendship",
			text = "You've met someone who could become a good friend.",
			question = "How do you nurture this connection?",
			minAge = 13, maxAge = 17,
			baseChance = 0.5,
			cooldown = 2,
			choices = {
				{ text = "Invite them to hang out", effects = { Happiness = 5 }, setFlags = { socially_active = true, has_best_friend = true }, feedText = "You took initiative and made a new friend!" },
				{ text = "Keep it casual for now", effects = { Happiness = 3 }, feedText = "You're taking things slow." },
				{ text = "They seem great, but I'm too busy", effects = { Happiness = -2 }, feedText = "The opportunity passed." },
				{ text = "Share something personal", effects = { Happiness = 7 }, setFlags = { deep_connector = true, has_best_friend = true }, feedText = "You bonded quickly over shared experiences." },
			},
		},
		{
			id = "first_job_offer",
			title = "Your First Job",
			emoji = "💼",
			category = "career",
			text = "A local business is hiring teenagers for part-time work.",
			question = "Will you apply?",
			minAge = 15, maxAge = 17,
			baseChance = 0.7,
			cooldown = 3,
			choices = {
				{ text = "Work at a fast food place", effects = { Money = 200, Health = -2, Happiness = -1 }, setFlags = { has_job = true, fast_food_experience = true }, feedText = "You got a job flipping burgers. Money incoming!" },
				{ text = "Work at a retail store", effects = { Money = 180, Happiness = 1 }, setFlags = { has_job = true, retail_experience = true }, feedText = "You're working retail. Learning about customers." },
				{ text = "Tutor younger kids", effects = { Money = 150, Smarts = 3 }, setFlags = { has_job = true, tutoring_experience = true }, hintCareer = "education", feedText = "You're tutoring others. Teaching is rewarding!" },
				{ text = "I don't want a job yet", effects = { Happiness = 2 }, feedText = "You're focusing on school and fun for now." },
			},
		},
		{
			id = "college_prep",
			title = "Planning Your Future",
			emoji = "🎯",
			category = "education",
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
			category = "milestone",
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
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ADULT (Ages 18+)
	-- ══════════════════════════════════════════════════════════════════════════════
	adult = {
		{
			id = "moving_out",
			title = "Time to Leave the Nest",
			emoji = "🏠",
			category = "milestone",
			text = "You're considering moving out of your parents' house.",
			question = "What's your plan?",
			minAge = 18, maxAge = 24,
			oneTime = true,
			choices = {
				{ text = "Get my own apartment", effects = { Happiness = 10, Money = -500 }, setFlags = { lives_alone = true, independent = true }, feedText = "You got your own place! Freedom!" },
				{ text = "Find roommates", effects = { Happiness = 5, Money = -200 }, setFlags = { has_roommates = true }, feedText = "You moved in with roommates. Cheaper but... interesting." },
				{ text = "Stay home to save money", effects = { Money = 300, Happiness = -3 }, setFlags = { lives_with_parents = true }, feedText = "You're staying home. Smart financially." },
			},
		},
		{
			id = "college_experience",
			title = "College Life",
			emoji = "📚",
			category = "education",
			text = "College is a whole new world of experiences.",
			question = "What's your focus?",
			minAge = 18, maxAge = 22,
			requiresFlags = { college_bound = true },
			cooldown = 2,
			choices = {
				{ text = "Study hard, get great grades", effects = { Smarts = 7, Happiness = -2, Health = -2 }, setFlags = { honors_student = true }, feedText = "You're crushing it academically!" },
				{ text = "Balance academics and social life", effects = { Smarts = 4, Happiness = 5 }, feedText = "You're getting the full college experience." },
				{ text = "Party now, study later", effects = { Happiness = 8, Smarts = -2, Health = -3 }, setFlags = { party_animal = true }, feedText = "College is about the experience, right?" },
				{ text = "Focus on networking and internships", effects = { Smarts = 3, Money = 100 }, setFlags = { career_focused = true }, hintCareer = "business", feedText = "You're building your professional network early." },
			},
		},
		{
			id = "graduation_college",
			title = "College Graduation",
			emoji = "🎓",
			category = "milestone",
			text = "You're graduating from college!",
			question = "What are you most proud of?",
			minAge = 21, maxAge = 30,
			oneTime = true,
			priority = "high",
			isMilestone = true,
			requiresFlags = { college_bound = true },
			choices = {
				{ text = "My academic achievements", effects = { Smarts = 10, Happiness = 5 }, setFlags = { college_graduate = true, academic_excellence = true }, feedText = "You graduated with honors!" },
				{ text = "The friendships I made", effects = { Happiness = 10 }, setFlags = { college_graduate = true, college_friends = true }, feedText = "You made lifelong friends!" },
				{ text = "Just getting through it", effects = { Happiness = 5 }, setFlags = { college_graduate = true }, feedText = "You survived college!" },
				{ text = "The experiences and growth", effects = { Happiness = 7, Smarts = 5 }, setFlags = { college_graduate = true, grew_in_college = true }, feedText = "College transformed you." },
			},
		},
		{
			id = "dating_app",
			title = "Modern Dating",
			emoji = "📱",
			category = "romance",
			text = "You've been single for a while and decide to try dating apps.",
			question = "How's it going?",
			minAge = 18, maxAge = 50,
			baseChance = 0.4,
			cooldown = 3,
			requiresSingle = true,
			choices = {
				{ text = "It's exhausting but I met someone special", effects = { Happiness = 8 }, setFlags = { dating = true, has_partner = true }, feedText = "You found someone promising!" },
				{ text = "Lots of bad dates, but learning", effects = { Happiness = -2, Smarts = 2 }, feedText = "The dating world is rough out there." },
				{ text = "Delete the apps, try meeting people IRL", effects = { Happiness = 3 }, feedText = "You're going old school." },
				{ text = "I'm actually okay being single", effects = { Happiness = 5 }, setFlags = { content_single = true }, feedText = "Single life has its perks!" },
			},
		},
		{
			id = "serious_relationship",
			title = "Getting Serious",
			emoji = "💑",
			category = "romance",
			text = "Your relationship is getting more serious. Your partner wants to talk about the future.",
			question = "How do you feel?",
			minAge = 20, maxAge = 35,
			baseChance = 0.6,
			cooldown = 3,
			requiresPartner = true,
			choices = {
				{ text = "I'm ready to commit", effects = { Happiness = 10 }, setFlags = { committed_relationship = true }, feedText = "You're ready for a serious commitment!" },
				{ text = "Let's take it slow", effects = { Happiness = 3 }, feedText = "You want to take things one step at a time." },
				{ text = "I'm not sure about this", effects = { Happiness = -5 }, feedText = "You have doubts about the relationship." },
				{ text = "I need to end this", effects = { Happiness = -8 }, setFlags = { recently_single = true }, feedText = "You ended the relationship. It's hard but necessary." },
			},
		},
		{
			id = "marriage_proposal",
			title = "The Big Question",
			emoji = "💍",
			category = "romance",
			text = "Your relationship has reached a point where marriage feels right.",
			question = "What happens?",
			minAge = 24, maxAge = 45,
			oneTime = true,
			requiresPartner = true,
			requiresFlags = { committed_relationship = true },
			choices = {
				{ text = "Pop the question (they say yes!)", effects = { Happiness = 15 }, setFlags = { engaged = true }, feedText = "They said YES! Wedding planning begins!" },
				{ text = "Pop the question (they say no)", effects = { Happiness = -15 }, setFlags = { proposal_rejected = true }, feedText = "They said no. Devastating." },
				{ text = "Get proposed to (say yes!)", effects = { Happiness = 15 }, setFlags = { engaged = true }, feedText = "You said YES! Wedding planning begins!" },
				{ text = "Not ready yet", effects = { Happiness = -2 }, feedText = "Marriage can wait." },
			},
		},
		{
			id = "wedding_day",
			title = "Wedding Day",
			emoji = "💒",
			category = "milestone",
			text = "It's your wedding day!",
			question = "What kind of wedding did you have?",
			minAge = 20, maxAge = 70,
			oneTime = true,
			priority = "high",
			isMilestone = true,
			requiresPartner = true,
			requiresFlags = { engaged = true },
			choices = {
				{ text = "Dream wedding, spared no expense", effects = { Happiness = 15, Money = -10000 }, setFlags = { married = true }, feedText = "Your fairy tale wedding was unforgettable!" },
				{ text = "Small, intimate ceremony", effects = { Happiness = 12, Money = -2000 }, setFlags = { married = true }, feedText = "A beautiful, intimate celebration of love." },
				{ text = "Courthouse wedding", effects = { Happiness = 8, Money = -100 }, setFlags = { married = true }, feedText = "Quick and simple - you're married!" },
				{ text = "Destination wedding adventure", effects = { Happiness = 15, Money = -8000 }, setFlags = { married = true }, feedText = "You got married in a beautiful location!" },
			},
		},
		{
			id = "having_children",
			title = "Starting a Family",
			emoji = "👶",
			category = "family",
			text = "You and your spouse are talking about having children.",
			question = "What's the decision?",
			minAge = 25, maxAge = 45,
			oneTime = true,
			requiresPartner = true,
			requiresFlags = { married = true },
			choices = {
				{ text = "Yes, we want children!", effects = { Happiness = 10, Money = -2000, Health = -2 }, setFlags = { has_children = true, parent = true }, feedText = "You're going to be a parent! Life changes forever." },
				{ text = "Maybe someday", effects = { Happiness = 2 }, feedText = "Kids are on the horizon, but not yet." },
				{ text = "We prefer to stay child-free", effects = { Happiness = 5, Money = 1000 }, setFlags = { childfree = true }, feedText = "You've decided not to have children. More freedom!" },
				{ text = "Adopt a child", effects = { Happiness = 12, Money = -3000 }, setFlags = { has_children = true, parent = true, adopted = true }, feedText = "You adopted a child! Welcome to the family!" },
			},
		},
		{
			id = "buying_home",
			title = "Buying a Home",
			emoji = "🏡",
			category = "finance",
			text = "You're considering buying your first home.",
			question = "What's your approach?",
			minAge = 25, maxAge = 50,
			oneTime = true,
			choices = {
				{ text = "Buy a starter home", effects = { Happiness = 10, Money = -5000 }, setFlags = { homeowner = true, has_car = true }, feedText = "You bought your first home! A big milestone!" },
				{ text = "Stretch for your dream home", effects = { Happiness = 15, Money = -15000, Health = -3 }, setFlags = { homeowner = true, has_car = true }, feedText = "You got your dream home! But the mortgage is steep." },
				{ text = "Keep renting for now", effects = { Money = 500 }, feedText = "You'll rent a bit longer. More flexibility." },
				{ text = "Move to a cheaper area", effects = { Happiness = 5, Money = -3000 }, setFlags = { homeowner = true, relocated = true, has_car = true }, feedText = "You moved somewhere more affordable!" },
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- CAREER (Requires Job)
	-- ══════════════════════════════════════════════════════════════════════════════
	career = {
		{
			id = "workplace_conflict",
			title = "Office Drama",
			emoji = "😤",
			category = "career",
			text = "A coworker has been taking credit for your work.",
			question = "How do you handle this?",
			minAge = 18, maxAge = 65,
			baseChance = 0.4,
			cooldown = 3,
			requiresJob = true,
			choices = {
				{ text = "Confront them directly", effects = { Happiness = 3 }, setFlags = { workplace_confrontation = true }, feedText = "You called them out. The tension is thick." },
				{ text = "Document everything, report to HR", effects = { Smarts = 2 }, feedText = "You took the professional route." },
				{ text = "Let it go this time", effects = { Happiness = -3 }, feedText = "You let it slide. But you're watching now." },
				{ text = "Beat them at their own game", effects = { Smarts = 3 }, feedText = "Two can play at office politics." },
			},
		},
		{
			id = "promotion_opportunity",
			title = "Opportunity Knocks",
			emoji = "📈",
			category = "career",
			text = "A promotion opportunity has opened up at work.",
			question = "Do you go for it?",
			minAge = 20, maxAge = 60,
			baseChance = 0.4,
			cooldown = 3,
			requiresJob = true,
			choices = {
				{ text = "Apply and compete hard", effects = { Smarts = 2, Money = 500, Health = -2 }, setFlags = { sought_promotion = true }, feedText = "You threw your hat in the ring!" },
				{ text = "Apply casually", effects = { Money = 250 }, feedText = "You applied but kept expectations low." },
				{ text = "Not interested", effects = { Happiness = 2 }, feedText = "You're happy where you are." },
			},
		},
		{
			id = "work_achievement",
			title = "Major Achievement",
			emoji = "🏆",
			category = "career",
			text = "You accomplished something significant at work!",
			question = "What was it?",
			minAge = 20, maxAge = 65,
			baseChance = 0.3,
			cooldown = 3,
			requiresJob = true,
			choices = {
				{ text = "Landed a big client/deal", effects = { Happiness = 10, Money = 1000, Smarts = 2 }, setFlags = { big_achiever = true }, feedText = "You closed a major deal!" },
				{ text = "Solved a critical problem", effects = { Happiness = 8, Smarts = 5 }, setFlags = { problem_solver = true }, feedText = "You saved the day with your solution!" },
				{ text = "Got recognized by leadership", effects = { Happiness = 10, Money = 500 }, feedText = "The executives noticed your work!" },
				{ text = "Mentored someone successfully", effects = { Happiness = 8, Smarts = 2 }, setFlags = { mentor = true }, feedText = "You helped someone grow in their career!" },
			},
		},
		{
			id = "career_crossroads",
			title = "Career Crossroads",
			emoji = "🛤️",
			category = "career",
			text = "You're at a turning point in your career.",
			question = "What path do you take?",
			minAge = 28, maxAge = 45,
			baseChance = 0.5,
			cooldown = 5,
			requiresJob = true,
			choices = {
				{ text = "Push for a promotion", effects = { Smarts = 2, Money = 500, Happiness = 5 }, feedText = "You went for the promotion!" },
				{ text = "Change companies for better pay", effects = { Money = 1000, Happiness = 3 }, setFlags = { job_hopper = true }, feedText = "You switched jobs for a raise!" },
				{ text = "Pivot to a new career entirely", effects = { Smarts = 5, Money = -1000, Happiness = 5 }, setFlags = { career_changer = true }, feedText = "You're starting over in a new field!" },
				{ text = "Stay the course", effects = { Happiness = 2 }, feedText = "You're content where you are." },
			},
		},
		{
			id = "business_trip",
			title = "Business Travel",
			emoji = "✈️",
			category = "career",
			text = "You've been selected for an important business trip.",
			question = "How do you approach it?",
			minAge = 22, maxAge = 60,
			baseChance = 0.4,
			cooldown = 2,
			requiresJob = true,
			choices = {
				{ text = "All business, impress the clients", effects = { Smarts = 3, Money = 300, Health = -2 }, feedText = "You crushed it professionally!" },
				{ text = "Balance work and exploration", effects = { Happiness = 5, Smarts = 2 }, feedText = "You saw some sights while getting work done!" },
				{ text = "Network at every opportunity", effects = { Smarts = 2 }, setFlags = { strong_network = true }, feedText = "You made valuable connections!" },
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- MILESTONES (Major life events)
	-- ══════════════════════════════════════════════════════════════════════════════
	milestones = {
		{
			id = "stage_transition_adult",
			title = "The Big 3-0",
			emoji = "🎂",
			category = "milestone",
			text = "You're turning 30! A new chapter of adulthood begins.",
			question = "How do you feel about this milestone?",
			minAge = 30, maxAge = 30,
			oneTime = true,
			priority = "high",
			isMilestone = true,
			choices = {
				{ text = "Excited for what's ahead", effects = { Happiness = 5 }, feedText = "30 is the new 20! You're just getting started." },
				{ text = "Reflective and content", effects = { Happiness = 3, Smarts = 2 }, feedText = "You're proud of how far you've come." },
				{ text = "A bit anxious", effects = { Happiness = -3 }, feedText = "Where did the time go? Mild existential crisis." },
				{ text = "Time to make changes", effects = { Happiness = 3 }, setFlags = { making_changes = true }, feedText = "This birthday inspired some life changes." },
			},
		},
		{
			id = "empty_nest",
			title = "Empty Nest",
			emoji = "🪹",
			category = "family",
			text = "Your children have all grown up and moved out.",
			question = "How do you feel?",
			minAge = 45, maxAge = 60,
			oneTime = true,
			requiresFlags = { has_children = true },
			choices = {
				{ text = "Sad but proud", effects = { Happiness = -3 }, setFlags = { empty_nester = true }, feedText = "You miss them, but you raised them well." },
				{ text = "Excited for new freedom", effects = { Happiness = 10, Money = 500 }, setFlags = { empty_nester = true }, feedText = "A new chapter of freedom begins!" },
				{ text = "Focus on your relationship", effects = { Happiness = 8 }, setFlags = { empty_nester = true }, feedText = "You and your partner reconnect." },
				{ text = "Fill the void with new hobbies", effects = { Happiness = 5, Smarts = 2 }, setFlags = { empty_nester = true }, feedText = "You discovered new passions." },
			},
		},
		{
			id = "grandchildren",
			title = "Becoming a Grandparent",
			emoji = "👴",
			category = "family",
			text = "Your child is having a baby. You're going to be a grandparent!",
			question = "How do you feel?",
			minAge = 45, maxAge = 75,
			oneTime = true,
			requiresFlags = { has_children = true },
			choices = {
				{ text = "Overjoyed!", effects = { Happiness = 15 }, setFlags = { grandparent = true }, feedText = "You're a grandparent! The circle of life continues." },
				{ text = "Happy but feeling old", effects = { Happiness = 8 }, setFlags = { grandparent = true }, feedText = "A grandparent... when did that happen?" },
				{ text = "Ready to spoil them", effects = { Happiness = 10, Money = -500 }, setFlags = { grandparent = true }, feedText = "Grandparent privileges: spoil and return!" },
			},
		},
		{
			id = "retirement_day",
			title = "Retirement Day",
			emoji = "🌴",
			category = "milestone",
			text = "After decades of work, you're retiring!",
			question = "How do you celebrate?",
			minAge = 55, maxAge = 75,
			oneTime = true,
			priority = "high",
			isMilestone = true,
			choices = {
				{ text = "Big retirement party", effects = { Happiness = 15, Money = -500 }, setFlags = { retired = true }, feedText = "You celebrated with colleagues and friends!" },
				{ text = "Immediately start traveling", effects = { Happiness = 15, Money = -3000, Health = 3 }, setFlags = { retired = true }, feedText = "You're seeing the world!" },
				{ text = "Quietly transition to retirement", effects = { Happiness = 10 }, setFlags = { retired = true }, feedText = "You slipped into retirement peacefully." },
				{ text = "Already planning my next chapter", effects = { Happiness = 12, Smarts = 3 }, setFlags = { retired = true }, feedText = "Retirement is just the beginning!" },
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- RANDOM (General life events)
	-- ══════════════════════════════════════════════════════════════════════════════
	random = {
		{
			id = "random_found_money",
			title = "Lucky Find",
			emoji = "💵",
			category = "luck",
			text = "You found some money on the ground!",
			question = "What do you do with it?",
			minAge = 5, maxAge = 80,
			baseChance = 0.3,
			cooldown = 5,
			choices = {
				{ text = "Keep it", effects = { Money = 50, Happiness = 5 }, feedText = "You pocketed some found money. Finders keepers!" },
				{ text = "Turn it in to lost & found", effects = { Happiness = 3 }, setFlags = { honest = true }, feedText = "You turned in the money. Good karma!" },
				{ text = "Donate it", effects = { Happiness = 8 }, setFlags = { charitable = true }, feedText = "You donated the found money to charity." },
			},
		},
		{
			id = "weather_event",
			title = "Caught in the Storm",
			emoji = "⛈️",
			category = "random",
			text = "You got caught in a sudden downpour without an umbrella.",
			question = "What do you do?",
			minAge = 8, maxAge = 70,
			baseChance = 0.4,
			cooldown = 3,
			choices = {
				{ text = "Run for cover", effects = { Health = -2, Happiness = -1 }, feedText = "You got drenched running for shelter." },
				{ text = "Dance in the rain", effects = { Happiness = 8, Health = -3 }, setFlags = { free_spirit = true }, feedText = "You danced in the rain like nobody was watching!" },
				{ text = "Wait it out patiently", effects = { Happiness = -2 }, feedText = "You waited until the storm passed." },
			},
		},
		{
			id = "minor_accident",
			title = "Oops!",
			emoji = "🤕",
			category = "health",
			text = "You had a minor accident and hurt yourself.",
			question = "What happened?",
			minAge = 5, maxAge = 75,
			baseChance = 0.3,
			cooldown = 3,
			choices = {
				{ text = "Stubbed your toe badly", effects = { Health = -3, Happiness = -2 }, feedText = "You stubbed your toe. The pain was real." },
				{ text = "Tripped and fell", effects = { Health = -5, Happiness = -3 }, feedText = "You took a tumble and got some bruises." },
				{ text = "Cut yourself cooking", effects = { Health = -4 }, feedText = "A kitchen mishap left you with a cut." },
			},
		},
		{
			id = "old_friend",
			title = "Blast from the Past",
			emoji = "👋",
			category = "social",
			text = "You ran into someone you haven't seen in years.",
			question = "How does it go?",
			minAge = 18, maxAge = 70,
			baseChance = 0.4,
			cooldown = 3,
			choices = {
				{ text = "Great reunion!", effects = { Happiness = 8 }, feedText = "You reconnected with an old friend!" },
				{ text = "Awkward small talk", effects = { Happiness = -2 }, feedText = "The reunion was pretty awkward." },
				{ text = "They've changed completely", effects = { Happiness = 2 }, feedText = "They're a completely different person now." },
			},
		},
		{
			id = "phone_broke",
			title = "Phone Disaster",
			emoji = "📱",
			category = "tech",
			text = "Your phone screen cracked!",
			question = "What do you do?",
			minAge = 13, maxAge = 70,
			baseChance = 0.4,
			cooldown = 3,
			choices = {
				{ text = "Get it repaired", effects = { Money = -200, Happiness = -2 }, feedText = "You got your phone screen fixed." },
				{ text = "Buy a new phone", effects = { Money = -800, Happiness = 3 }, feedText = "You upgraded to a new phone." },
				{ text = "Live with the cracks", effects = { Happiness = -3 }, feedText = "You're using a cracked phone now." },
			},
		},
		{
			id = "pet_encounter",
			title = "Animal Encounter",
			emoji = "🐕",
			category = "random",
			text = "A friendly stray animal approached you.",
			question = "What do you do?",
			minAge = 5, maxAge = 70,
			baseChance = 0.3,
			cooldown = 4,
			choices = {
				{ text = "Take it home!", effects = { Happiness = 15, Money = -200 }, setFlags = { has_pet = true, animal_lover = true }, feedText = "You adopted a stray pet!" },
				{ text = "Pet it and move on", effects = { Happiness = 5 }, feedText = "You made a furry friend for a moment." },
				{ text = "Call animal control", effects = { Happiness = 2 }, feedText = "You made sure the animal would be taken care of." },
				{ text = "I'm not an animal person", effects = { }, feedText = "You kept your distance from the animal." },
			},
		},
		{
			id = "family_reunion",
			title = "Family Reunion",
			emoji = "👨‍👩‍👧‍👦",
			category = "family",
			text = "There's a big family reunion coming up.",
			question = "How do you approach it?",
			minAge = 10, maxAge = 80,
			baseChance = 0.4,
			cooldown = 5,
			choices = {
				{ text = "Embrace the chaos", effects = { Happiness = 7 }, setFlags = { family_oriented = true }, feedText = "You enjoyed reconnecting with family!" },
				{ text = "Catch up with specific relatives", effects = { Happiness = 5, Smarts = 2 }, feedText = "You had meaningful conversations." },
				{ text = "Avoid the drama", effects = { Happiness = 2 }, feedText = "You stayed out of the family politics." },
				{ text = "Skip it", effects = { Happiness = -2 }, feedText = "You missed the reunion." },
			},
		},
		{
			id = "flat_tire",
			title = "Car Trouble",
			emoji = "🚗",
			category = "random",
			text = "Your car got a flat tire on the way somewhere important.",
			question = "How do you handle it?",
			minAge = 16, maxAge = 75,
			baseChance = 0.4,
			cooldown = 4,
			requiresFlags = { has_car = true },
			choices = {
				{ text = "Change it yourself", effects = { Happiness = 3, Health = -1 }, setFlags = { handy = true }, feedText = "You changed the tire yourself. Impressive!" },
				{ text = "Call for roadside assistance", effects = { Money = -100, Happiness = -2 }, feedText = "You called for help with the flat tire." },
				{ text = "Ask a stranger for help", effects = { Happiness = 3 }, feedText = "A kind stranger helped with your tire." },
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- RELATIONSHIPS (Partner/Romance events)
	-- ══════════════════════════════════════════════════════════════════════════════
	relationships = {
		{
			id = "sibling_rivalry",
			title = "Sibling Conflict",
			emoji = "👊",
			category = "family",
			text = "You and your sibling are fighting about something.",
			question = "How do you handle it?",
			minAge = 5, maxAge = 25,
			baseChance = 0.5,
			cooldown = 3,
			requiresFlags = { big_family = true },
			choices = {
				{ text = "Work it out together", effects = { Happiness = 5, Smarts = 2 }, setFlags = { good_sibling_bond = true }, feedText = "You and your sibling made up." },
				{ text = "Give them the silent treatment", effects = { Happiness = -3 }, feedText = "The cold war continues..." },
				{ text = "Involve your parents", effects = { Happiness = -2 }, feedText = "Parents got involved. Mixed results." },
				{ text = "Apologize (even if not fully your fault)", effects = { Happiness = 3 }, setFlags = { peacemaker = true }, feedText = "You chose peace over being right." },
			},
		},
		{
			id = "friend_in_need",
			title = "A Friend Needs Help",
			emoji = "🆘",
			category = "friendship",
			text = "A close friend is going through a really tough time and reaches out.",
			question = "How do you respond?",
			minAge = 12, maxAge = 80,
			baseChance = 0.5,
			cooldown = 2,
			choices = {
				{ text = "Drop everything to help", effects = { Happiness = 5, Health = -2 }, setFlags = { loyal_friend = true }, feedText = "You were there when they needed you most." },
				{ text = "Help within your limits", effects = { Happiness = 3 }, feedText = "You supported them the best you could." },
				{ text = "Help them find professional support", effects = { Happiness = 3, Smarts = 2 }, feedText = "You connected them with the right resources." },
				{ text = "I have my own problems", effects = { Happiness = -3 }, setFlags = { selfish_friend = true }, feedText = "You couldn't be there for them." },
			},
		},
		{
			id = "relationship_conflict",
			title = "Relationship Trouble",
			emoji = "💔",
			category = "romance",
			text = "You and your partner are having serious disagreements.",
			question = "How do you handle it?",
			minAge = 18, maxAge = 70,
			baseChance = 0.4,
			cooldown = 2,
			requiresPartner = true,
			choices = {
				{ text = "Seek couples counseling", effects = { Happiness = 5, Smarts = 2, Money = -200 }, feedText = "Professional help is improving things." },
				{ text = "Have a heart-to-heart talk", effects = { Happiness = 5 }, feedText = "You talked through the issues." },
				{ text = "Give each other space", effects = { Happiness = 2 }, feedText = "Some distance helped." },
				{ text = "Let it fester", effects = { Happiness = -5, Health = -2 }, feedText = "The problems are getting worse." },
			},
		},
		{
			id = "partner_support",
			title = "Supporting Your Partner",
			emoji = "🤝",
			category = "romance",
			text = "Your partner is going through a difficult time.",
			question = "How do you support them?",
			minAge = 18, maxAge = 80,
			baseChance = 0.4,
			cooldown = 2,
			requiresPartner = true,
			choices = {
				{ text = "Be there emotionally", effects = { Happiness = 5 }, setFlags = { supportive_partner = true }, feedText = "You were their rock." },
				{ text = "Help solve the problem", effects = { Happiness = 5, Smarts = 2 }, feedText = "You helped them find solutions." },
				{ text = "Give them space to process", effects = { Happiness = 3 }, feedText = "You respected their need for space." },
				{ text = "Struggle to know what to do", effects = { Happiness = -3 }, feedText = "You felt helpless." },
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════════════

local function registerEvents(events, categoryName)
	EventsByCategory[categoryName] = EventsByCategory[categoryName] or {}
	local count = 0
	
	for _, event in ipairs(events) do
		event._category = categoryName
		AllEvents[event.id] = event
		table.insert(EventsByCategory[categoryName], event)
		count += 1
	end
	
	return count
end

function LifeEvents.init()
	AllEvents = {}
	EventsByCategory = {}
	
	local total = 0
	local categoryCount = 0
	
	for categoryName, events in pairs(EventPools) do
		local count = registerEvents(events, categoryName)
		total += count
		categoryCount += 1
	end
	
	print(string.format("[LifeEvents] Loaded %d events across %d categories.", total, categoryCount))
	return total
end

-- Auto-init
LifeEvents.init()

-- ════════════════════════════════════════════════════════════════════════════════════
-- EVENT HISTORY TRACKING
-- ════════════════════════════════════════════════════════════════════════════════════

local function getEventHistory(state)
	state.EventHistory = state.EventHistory or {
		occurrences = {},
		lastOccurrence = {},
		completed = {},
		recentCategories = {},
	}
	return state.EventHistory
end

local function recordEventShown(state, event)
	local history = getEventHistory(state)
	local eventId = event.id
	
	history.occurrences[eventId] = (history.occurrences[eventId] or 0) + 1
	history.lastOccurrence[eventId] = state.Age
	
	if event.oneTime then
		history.completed[eventId] = true
	end
	
	table.insert(history.recentCategories, event._category or "general")
	if #history.recentCategories > 5 then
		table.remove(history.recentCategories, 1)
	end
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- ELIGIBILITY CHECKS - CORE CONTEXTUAL LOGIC
-- ════════════════════════════════════════════════════════════════════════════════════

local function canEventTrigger(event, state)
	local age = state.Age or 0
	local history = getEventHistory(state)
	
	-- Age check
	if event.minAge and age < event.minAge then return false end
	if event.maxAge and age > event.maxAge then return false end
	
	-- One-time event check
	if event.oneTime and history.completed[event.id] then
		return false
	end
	
	-- Cooldown check
	local cooldown = event.cooldown or 3
	local lastAge = history.lastOccurrence[event.id]
	if lastAge and (age - lastAge) < cooldown then
		return false
	end
	
	-- Max occurrences check
	local maxOccur = event.maxOccurrences or 5
	local count = history.occurrences[event.id] or 0
	if count >= maxOccur then
		return false
	end
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CONTEXTUAL REQUIREMENTS - MUST ALIGN WITH PLAYER'S LIFE SITUATION
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- Check required flags
	if event.requiresFlags then
		local flags = state.Flags or {}
		for flag, required in pairs(event.requiresFlags) do
			if required == true and not flags[flag] then 
				return false
			end
			if required == false and flags[flag] then 
				return false
			end
		end
	end
	
	-- Check required stats
	if event.requiresStats then
		local stats = state.Stats or state
		for stat, req in pairs(event.requiresStats) do
			local value = stats[stat] or state[stat] or 50
			if type(req) == "number" and value < req then return false end
			if type(req) == "table" then
				if req.min and value < req.min then return false end
				if req.max and value > req.max then return false end
			end
		end
	end
	
	-- JOB REQUIREMENTS - No career events without a job!
	if event.requiresJob then
		local hasJob = state.CurrentJob ~= nil
		if not hasJob then 
			return false
		end
	end
	
	if event.requiresNoJob then
		local hasJob = state.CurrentJob ~= nil
		if hasJob then 
			return false
		end
	end
	
	if event.requiresJobCategory then
		local hasJob = state.CurrentJob ~= nil
		if not hasJob then return false end
		local jobCategory = state.CurrentJob.category or ""
		if jobCategory ~= event.requiresJobCategory then
			return false
		end
	end
	
	-- RELATIONSHIP REQUIREMENTS - No marriage without partner!
	if event.requiresPartner then
		local hasPartner = state.Relationships and state.Relationships.partner
		if not hasPartner then 
			return false
		end
	end
	
	if event.requiresSingle then
		local hasPartner = state.Relationships and state.Relationships.partner
		if hasPartner then
			return false
		end
	end
	
	-- EDUCATION REQUIREMENTS
	if event.requiresEducation then
		local edu = state.Education or "none"
		local eduLevels = { 
			none = 0, elementary = 1, middle_school = 2, high_school = 3, 
			community = 4, bachelor = 5, master = 6, law = 7, medical = 7, phd = 8 
		}
		local playerLevel = eduLevels[edu] or 0
		local requiredLevel = eduLevels[event.requiresEducation] or 0
		if playerLevel < requiredLevel then 
			return false
		end
	end
	
	-- Random chance (last check)
	if event.baseChance then
		if RANDOM:NextNumber() > (event.baseChance or 1) then
			return false
		end
	end
	
	return true
end

local function getEventWeight(event, state)
	local history = getEventHistory(state)
	local weight = event.weight or 10
	
	local occurCount = history.occurrences[event.id] or 0
	if occurCount == 0 then
		weight = weight * 2.5
	end
	
	if event.priority == "high" or event.isMilestone then
		weight = weight * 3
	end
	
	local recentCats = history.recentCategories or {}
	for _, cat in ipairs(recentCats) do
		if cat == event._category then
			weight = weight * 0.5
			break
		end
	end
	
	local lastAge = history.lastOccurrence[event.id]
	if lastAge then
		local yearsSince = (state.Age or 0) - lastAge
		if yearsSince < 5 then
			weight = weight * (0.3 + (yearsSince / 10))
		end
	end
	
	return math.max(weight, 1)
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- CATEGORY SELECTION
-- ════════════════════════════════════════════════════════════════════════════════════

local function getRelevantCategories(state)
	local age = state.Age or 0
	local categories = {}
	
	if age <= 4 then
		table.insert(categories, "childhood")
		table.insert(categories, "milestones")
	elseif age <= 12 then
		table.insert(categories, "childhood")
		table.insert(categories, "milestones")
		table.insert(categories, "random")
	elseif age <= 17 then
		table.insert(categories, "teen")
		table.insert(categories, "milestones")
		table.insert(categories, "relationships")
		table.insert(categories, "random")
	else
		table.insert(categories, "adult")
		table.insert(categories, "milestones")
		table.insert(categories, "relationships")
		table.insert(categories, "random")
		
		if state.CurrentJob then
			table.insert(categories, "career")
		end
	end
	
	return categories
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- BUILD YEAR QUEUE
-- ════════════════════════════════════════════════════════════════════════════════════

function LifeEvents.buildYearQueue(state, options)
	options = options or {}
	local maxEvents = options.maxEvents or 1
	
	if not state then return {} end
	
	local selectedEvents = {}
	local candidateEvents = {}
	
	local categories = getRelevantCategories(state)
	
	for _, catName in ipairs(categories) do
		local catEvents = EventsByCategory[catName] or {}
		for _, event in ipairs(catEvents) do
			if canEventTrigger(event, state) then
				local weight = getEventWeight(event, state)
				table.insert(candidateEvents, {
					event = event,
					weight = weight,
					priority = event.priority == "high" or event.isMilestone,
				})
			end
		end
	end
	
	if #candidateEvents == 0 then
		return {}
	end
	
	local priorityEvents = {}
	local regularEvents = {}
	
	for _, candidate in ipairs(candidateEvents) do
		if candidate.priority then
			table.insert(priorityEvents, candidate)
		else
			table.insert(regularEvents, candidate)
		end
	end
	
	if #priorityEvents > 0 then
		table.sort(priorityEvents, function(a, b) return a.weight > b.weight end)
		local chosen = priorityEvents[1]
		table.insert(selectedEvents, chosen.event)
		recordEventShown(state, chosen.event)
		return selectedEvents
	end
	
	local age = state.Age or 0
	local quietChance = 0.4
	if age <= 4 then quietChance = 0.3
	elseif age <= 12 then quietChance = 0.4
	elseif age <= 17 then quietChance = 0.35
	else quietChance = 0.5 end
	
	if RANDOM:NextNumber() < quietChance then
		return {}
	end
	
	if #regularEvents > 0 then
		local totalWeight = 0
		for _, candidate in ipairs(regularEvents) do
			totalWeight = totalWeight + candidate.weight
		end
		
		local roll = RANDOM:NextNumber() * totalWeight
		local cumulative = 0
		
		for _, candidate in ipairs(regularEvents) do
			cumulative = cumulative + candidate.weight
			if roll <= cumulative then
				table.insert(selectedEvents, candidate.event)
				recordEventShown(state, candidate.event)
				break
			end
		end
	end
	
	return selectedEvents
end

function LifeEvents.getEvent(eventId)
	return AllEvents[eventId]
end

function LifeEvents.getAllEvents()
	return AllEvents
end

function LifeEvents.getEventsByCategory(categoryName)
	return EventsByCategory[categoryName] or {}
end

-- ════════════════════════════════════════════════════════════════════════════════════
-- EVENT ENGINE
-- ════════════════════════════════════════════════════════════════════════════════════

local EventEngine = {}

local MaleNames = {"James", "Michael", "David", "John", "Robert", "Chris", "Daniel", "Matthew", "Anthony", "Mark", "Steven", "Andrew", "Joshua", "Kevin", "Brian", "Ryan", "Justin", "Brandon", "Eric", "Tyler", "Alex", "Jake", "Ethan", "Noah", "Liam"}
local FemaleNames = {"Emma", "Olivia", "Sophia", "Isabella", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn", "Abigail", "Emily", "Elizabeth", "Sofia", "Avery", "Ella", "Scarlett", "Grace", "Chloe", "Victoria", "Riley", "Aria", "Lily", "Zoey", "Hannah", "Layla"}

local function generateName(gender)
	if gender == "female" then
		return FemaleNames[RANDOM:NextInteger(1, #FemaleNames)]
	else
		return MaleNames[RANDOM:NextInteger(1, #MaleNames)]
	end
end

local function getOppositeGender(playerGender)
	if playerGender == "male" or playerGender == "Male" then
		return "female"
	else
		return "male"
	end
end

local function createRelationship(state, relType, customName)
	state.Relationships = state.Relationships or {}
	
	local id = relType .. "_" .. tostring(RANDOM:NextInteger(1000, 9999))
	local age = state.Age or 20
	local gender = "male"
	local name = customName
	
	if relType == "romance" or relType == "partner" then
		gender = getOppositeGender(state.Gender or "male")
		name = name or generateName(gender)
		age = math.max(18, age + RANDOM:NextInteger(-5, 5))
	elseif relType == "friend" then
		gender = RANDOM:NextNumber() > 0.5 and "male" or "female"
		name = name or generateName(gender)
		age = math.max(5, age + RANDOM:NextInteger(-3, 3))
	end
	
	local relationship = {
		id = id,
		name = name,
		type = relType,
		role = relType == "romance" and "Partner" or (relType == "friend" and "Friend" or relType),
		relationship = RANDOM:NextInteger(50, 75),
		age = age,
		gender = gender,
		alive = true,
		metAge = state.Age,
	}
	
	state.Relationships[id] = relationship
	
	if relType == "romance" then
		state.Relationships.partner = relationship
	end
	
	return relationship
end

function EventEngine.completeEvent(eventDef, choiceIndex, state)
	if not eventDef or not eventDef.choices then
		return nil
	end
	
	local choice = eventDef.choices[choiceIndex]
	if not choice then
		return nil
	end
	
	local outcome = {
		eventId = eventDef.id,
		choiceIndex = choiceIndex,
		feedText = choice.feed or choice.feedText or choice.text,
		statChanges = {},
		flagChanges = {},
	}
	
	local effects = choice.effects or choice.deltas or {}
	for stat, change in pairs(effects) do
		local delta = change
		if type(change) == "table" then
			local min = change.min or change[1] or 0
			local max = change.max or change[2] or 0
			delta = RANDOM:NextInteger(min, max)
		end
		
		outcome.statChanges[stat] = delta
		
		if stat == "Money" or stat == "money" then
			state.Money = math.max(0, (state.Money or 0) + delta)
		elseif stat == "Happiness" or stat == "Health" or stat == "Smarts" or stat == "Looks" then
			local stats = state.Stats or state
			local current = stats[stat] or 50
			stats[stat] = math.clamp(current + delta, 0, 100)
			state[stat] = stats[stat]
		end
	end
	
	local flagChanges = choice.setFlags or choice.flags or {}
	for flag, value in pairs(flagChanges) do
		state.Flags = state.Flags or {}
		state.Flags[flag] = value
		outcome.flagChanges[flag] = value
	end
	
	if choice.hintCareer then
		state.CareerHints = state.CareerHints or {}
		state.CareerHints[choice.hintCareer] = true
	end
	
	-- Handle relationship creation from specific events
	local eventId = eventDef.id or ""
	state.Relationships = state.Relationships or {}
	
	if eventId == "first_best_friend" or eventId == "new_friendship" then
		if choiceIndex == 1 or choiceIndex == 4 then
			local friend = createRelationship(state, "friend")
			outcome.feedText = outcome.feedText .. " " .. friend.name .. " became your friend!"
			outcome.newRelationship = friend
		end
	end
	
	if eventId == "dating_app" or eventId == "high_school_romance" then
		if choiceIndex == 1 then
			if not state.Relationships.partner then
				local partner = createRelationship(state, "romance")
				outcome.feedText = "You started dating " .. partner.name .. "!"
				outcome.newRelationship = partner
				state.Flags = state.Flags or {}
				state.Flags.dating = true
				state.Flags.has_partner = true
			end
		end
	end
	
	if eventId == "wedding_day" then
		local partner = state.Relationships.partner
		if partner then
			partner.role = "Spouse"
			state.Flags = state.Flags or {}
			state.Flags.married = true
			state.Flags.engaged = nil
			outcome.feedText = "You married " .. partner.name .. "!"
		end
	end
	
	return outcome
end

LifeEvents.EventEngine = EventEngine

return LifeEvents
