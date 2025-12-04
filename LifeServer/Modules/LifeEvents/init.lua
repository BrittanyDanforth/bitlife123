--[[
	LifeEvents/init.lua
	
	CONSOLIDATED Event system for BitLife-style game.
	All events are defined inline to avoid child module issues.
	
	Usage:
		local LifeEvents = require(LifeEventsFolder:WaitForChild("init"))
		local events = LifeEvents.buildYearQueue(playerState, { maxEvents = 2 })
		LifeEvents.EventEngine.completeEvent(eventDef, choiceIndex, state)
]]

local LifeEvents = {}

local RANDOM = Random.new()

-- Master event registry
local AllEvents = {}
local EventsByCategory = {}

-- ════════════════════════════════════════════════════════════════════════════
-- LIFE STAGES
-- ════════════════════════════════════════════════════════════════════════════

local LifeStages = {
	{ id = "baby",       minAge = 0,  maxAge = 2 },
	{ id = "toddler",    minAge = 3,  maxAge = 4 },
	{ id = "child",      minAge = 5,  maxAge = 12 },
	{ id = "teen",       minAge = 13, maxAge = 17 },
	{ id = "young_adult", minAge = 18, maxAge = 29 },
	{ id = "adult",      minAge = 30, maxAge = 49 },
	{ id = "middle_age", minAge = 50, maxAge = 64 },
	{ id = "senior",     minAge = 65, maxAge = 999 },
}

local function getLifeStage(age)
	for _, stage in ipairs(LifeStages) do
		if age >= stage.minAge and age <= stage.maxAge then
			return stage.id
		end
	end
	return "adult"
end

-- ════════════════════════════════════════════════════════════════════════════
-- ALL EVENTS DEFINED INLINE
-- ════════════════════════════════════════════════════════════════════════════

local EventPools = {
	-- ══════════════════════════════════════════════════════════════════════
	-- CHILDHOOD EVENTS (Ages 0-12)
	-- ══════════════════════════════════════════════════════════════════════
	childhood = {
		{
			id = "first_words",
			title = "First Words",
			emoji = "👶",
			text = "Your parents are excited - you just spoke your first word!",
			question = "What did you say?",
			minAge = 1, maxAge = 2,
			oneTime = true, priority = "high", isMilestone = true,
			choices = {
				{ text = '"Mama"', effects = { Happiness = 5 }, setFlags = { first_word = "mama" }, feed = "You said your first word: 'Mama'." },
				{ text = '"Dada"', effects = { Happiness = 5 }, setFlags = { first_word = "dada" }, feed = "You said your first word: 'Dada'." },
				{ text = '"No!"', effects = { Happiness = 3 }, setFlags = { rebellious_streak = true }, feed = "Your first word was 'No!' - independent spirit!" },
				{ text = "The dog's name", effects = { Happiness = 4 }, setFlags = { animal_lover = true }, feed = "You tried to say the pet's name." },
			},
		},
		{
			id = "first_steps",
			title = "First Steps",
			emoji = "🚶",
			text = "You're standing up and ready to take your first steps!",
			question = "How do you approach this?",
			minAge = 1, maxAge = 2,
			oneTime = true, priority = "high", isMilestone = true,
			choices = {
				{ text = "Carefully and cautiously", effects = { Smarts = 2 }, setFlags = { cautious = true }, feed = "You took careful first steps." },
				{ text = "Boldly charge forward", effects = { Health = -2, Happiness = 5 }, setFlags = { adventurous = true }, feed = "You ran before you could walk!" },
				{ text = "Wait for encouragement", effects = { Happiness = 3 }, feed = "With cheering, you walked into their arms." },
			},
		},
		{
			id = "preschool_start",
			title = "First Day of Preschool",
			emoji = "🎒",
			text = "It's your first day of preschool!",
			question = "How do you handle being away from home?",
			minAge = 3, maxAge = 4,
			oneTime = true, priority = "high",
			choices = {
				{ text = "Cry and cling to mom/dad", effects = { Happiness = -5 }, feed = "The first day was rough." },
				{ text = "March in confidently", effects = { Happiness = 5, Smarts = 2 }, setFlags = { confident = true }, feed = "You walked in like you owned the place!" },
				{ text = "Quietly observe", effects = { Smarts = 3 }, setFlags = { observant = true }, feed = "You watched everything carefully." },
				{ text = "Find the art supplies", effects = { Happiness = 5 }, setFlags = { artistic = true }, hintCareer = "creative", feed = "You made a beeline for the crayons!" },
			},
		},
		{
			id = "imaginary_friend",
			title = "Imaginary Friend",
			emoji = "👻",
			text = "You've been talking to your 'invisible friend.'",
			question = "Who is your imaginary friend?",
			minAge = 3, maxAge = 5,
			oneTime = true, baseChance = 0.6,
			choices = {
				{ text = "A brave superhero", effects = { Happiness = 5 }, setFlags = { hero_complex = true }, feed = "Your superhero friend makes you feel invincible." },
				{ text = "A wise wizard", effects = { Smarts = 3 }, setFlags = { loves_fantasy = true }, feed = "Your wizard friend teaches you 'magic'." },
				{ text = "A friendly animal", effects = { Happiness = 3 }, setFlags = { animal_lover = true }, feed = "Your animal friend understands you." },
				{ text = "I don't need imaginary friends", effects = { Smarts = 2 }, setFlags = { pragmatic = true }, feed = "You prefer real friends." },
			},
		},
		{
			id = "first_best_friend",
			title = "A New Best Friend",
			emoji = "🤝",
			text = "You've been hanging out with a kid from class a lot!",
			question = "What do you two do together?",
			minAge = 5, maxAge = 8,
			oneTime = true,
			choices = {
				{ text = "Play imaginative games", effects = { Happiness = 5, Smarts = 2 }, setFlags = { has_best_friend = true }, feed = "You create entire worlds together." },
				{ text = "Build with blocks/Legos", effects = { Smarts = 5, Happiness = 3 }, setFlags = { builder = true }, hintCareer = "tech", feed = "Engineering minds in the making!" },
				{ text = "Play sports outside", effects = { Health = 5, Happiness = 3 }, setFlags = { sporty = true }, hintCareer = "sports", feed = "Always running around outside." },
				{ text = "Read and explore", effects = { Smarts = 5 }, setFlags = { curious = true }, hintCareer = "science", feed = "Partners in curiosity!" },
			},
		},
		{
			id = "school_bully",
			title = "Trouble on the Playground",
			emoji = "😠",
			text = "An older kid has been picking on you.",
			question = "How do you handle this?",
			minAge = 6, maxAge = 10,
			baseChance = 0.5, cooldown = 4,
			choices = {
				{ text = "Stand up to them", effects = { Happiness = 5, Health = {-3, 3} }, setFlags = { brave = true }, feed = "You stood up to the bully!" },
				{ text = "Tell a teacher", effects = { Happiness = 2, Smarts = 2 }, feed = "You told an adult. The bully got in trouble." },
				{ text = "Avoid them", effects = { Happiness = -3 }, feed = "You learned which hallways to avoid." },
				{ text = "Try to befriend them", effects = { Happiness = {-2, 5} }, setFlags = { peacemaker = true }, feed = "Sometimes kindness works." },
			},
		},
		{
			id = "talent_show",
			title = "School Talent Show",
			emoji = "🎭",
			text = "The school is having a talent show!",
			question = "What will you do?",
			minAge = 6, maxAge = 11,
			baseChance = 0.6, cooldown = 3,
			choices = {
				{ text = "Sing a song", effects = { Happiness = {-3, 10}, Looks = 2 }, setFlags = { performer = true }, hintCareer = "entertainment", feed = "You sang your heart out!" },
				{ text = "Do a magic trick", effects = { Smarts = 3, Happiness = 5 }, feed = "Your magic trick amazed everyone!" },
				{ text = "Tell jokes", effects = { Happiness = 7 }, setFlags = { class_clown = true }, feed = "You had everyone laughing!" },
				{ text = "Watch from audience", effects = { }, feed = "You cheered on your classmates." },
			},
		},
		{
			id = "science_fair",
			title = "Science Fair Project",
			emoji = "🔬",
			text = "It's science fair season!",
			question = "Choose your project:",
			minAge = 7, maxAge = 11,
			baseChance = 0.6, cooldown = 3,
			choices = {
				{ text = "Volcano eruption", effects = { Smarts = 3, Happiness = 5 }, hintCareer = "science", feed = "Your volcano was the hit of the fair!" },
				{ text = "Growing plants", effects = { Smarts = 5 }, setFlags = { patient = true }, feed = "You documented how plants grow." },
				{ text = "Build a robot", effects = { Smarts = 7 }, setFlags = { tech_enthusiast = true }, hintCareer = "tech", feed = "Your robot impressed the judges!" },
				{ text = "Skip it", effects = { Smarts = -2 }, feed = "You didn't participate this year." },
			},
		},
		{
			id = "sports_tryout_kid",
			title = "Sports Team Tryouts",
			emoji = "⚽",
			text = "Tryouts for the youth sports league!",
			question = "Which sport will you try?",
			minAge = 6, maxAge = 11,
			baseChance = 0.6, cooldown = 3,
			choices = {
				{ text = "Soccer", effects = { Health = 5, Happiness = 3 }, setFlags = { plays_soccer = true }, hintCareer = "sports", feed = "You made the soccer team!" },
				{ text = "Basketball", effects = { Health = 5, Happiness = 3 }, setFlags = { plays_basketball = true }, feed = "You're on the basketball team!" },
				{ text = "Swimming", effects = { Health = 7 }, setFlags = { swimmer = true }, feed = "You joined the swim team!" },
				{ text = "I'm not sporty", effects = { }, feed = "Sports aren't really your thing." },
			},
		},
		{
			id = "music_lessons",
			title = "Music Lessons",
			emoji = "🎹",
			text = "Your parents offer to pay for music lessons.",
			question = "What instrument interests you?",
			minAge = 6, maxAge = 10,
			baseChance = 0.5, cooldown = 5,
			choices = {
				{ text = "Piano", effects = { Smarts = 3, Happiness = 3 }, setFlags = { plays_piano = true }, hintCareer = "creative", feed = "You started piano lessons!" },
				{ text = "Guitar", effects = { Happiness = 5, Looks = 2 }, setFlags = { plays_guitar = true }, hintCareer = "entertainment", feed = "You're learning guitar!" },
				{ text = "Drums", effects = { Happiness = 5, Health = 2 }, setFlags = { plays_drums = true }, feed = "You took up drums!" },
				{ text = "No thanks", effects = { }, feed = "You passed on music lessons." },
			},
		},
		{
			id = "first_crush_kid",
			title = "Butterfly Feelings",
			emoji = "💕",
			text = "Someone in class makes you feel... different.",
			question = "What do you do about these feelings?",
			minAge = 9, maxAge = 12,
			oneTime = true, baseChance = 0.6,
			choices = {
				{ text = "Write them a secret note", effects = { Happiness = {-5, 10} }, setFlags = { romantic = true }, feed = "You slipped a note to your crush." },
				{ text = "Tell your best friend", effects = { Happiness = 3 }, feed = "You confided in your best friend." },
				{ text = "Keep it secret", effects = { }, setFlags = { private_person = true }, feed = "Some things are just for you." },
				{ text = "Ew, no thanks", effects = { Happiness = 2 }, feed = "Romance? You've got better things to think about." },
			},
		},
		{
			id = "video_games",
			title = "Gaming Discovery",
			emoji = "🎮",
			text = "You've discovered video games!",
			question = "What kind of games captivate you?",
			minAge = 7, maxAge = 11,
			baseChance = 0.7, cooldown = 5,
			choices = {
				{ text = "Building/creative games", effects = { Smarts = 3, Happiness = 5 }, setFlags = { creative_gamer = true }, hintCareer = "tech", feed = "You love building in games!" },
				{ text = "Adventure/story games", effects = { Smarts = 2, Happiness = 5 }, setFlags = { story_lover = true }, feed = "You get lost in epic stories." },
				{ text = "Competitive multiplayer", effects = { Happiness = 5 }, setFlags = { competitive = true }, feed = "You love the thrill of competition!" },
				{ text = "Games aren't my thing", effects = { }, feed = "You prefer other hobbies." },
			},
		},
		{
			id = "summer_camp",
			title = "Summer Camp",
			emoji = "🏕️",
			text = "Your parents are sending you to summer camp!",
			question = "What kind of camp?",
			minAge = 8, maxAge = 12,
			baseChance = 0.4, cooldown = 3,
			choices = {
				{ text = "Outdoor adventure", effects = { Health = 5, Happiness = 5 }, setFlags = { nature_lover = true }, feed = "You learned to hike and camp!" },
				{ text = "Science camp", effects = { Smarts = 7 }, hintCareer = "science", feed = "Cool experiments all summer!" },
				{ text = "Arts camp", effects = { Happiness = 5, Looks = 3 }, hintCareer = "creative", feed = "You explored painting and sculpture!" },
				{ text = "Computer/coding camp", effects = { Smarts = 7 }, setFlags = { coder = true }, hintCareer = "tech", feed = "You learned to code!" },
			},
		},
		{
			id = "allowance",
			title = "First Allowance",
			emoji = "💰",
			text = "Your parents started giving you a weekly allowance.",
			question = "How do you handle your money?",
			minAge = 8, maxAge = 11,
			oneTime = true,
			choices = {
				{ text = "Save it all", effects = { Smarts = 3, Money = 50 }, setFlags = { saver = true }, hintCareer = "finance", feed = "You save every penny!" },
				{ text = "Spend on candy and toys", effects = { Happiness = 5, Money = -20 }, setFlags = { spender = true }, feed = "You enjoy your money!" },
				{ text = "Save some, spend some", effects = { Smarts = 2, Happiness = 3, Money = 25 }, feed = "You're learning balance." },
				{ text = "Try to invest somehow", effects = { Smarts = 5, Money = {-10, 30} }, setFlags = { entrepreneur = true }, feed = "Already thinking about growing money!" },
			},
		},
		{
			id = "reading_habit",
			title = "Lost in Books",
			emoji = "📚",
			text = "You've discovered the joy of reading!",
			question = "What do you love to read?",
			minAge = 7, maxAge = 12,
			baseChance = 0.5, cooldown = 4,
			choices = {
				{ text = "Fantasy adventures", effects = { Smarts = 5, Happiness = 3 }, setFlags = { fantasy_reader = true }, hintCareer = "creative", feed = "Magical worlds await!" },
				{ text = "Science and nature", effects = { Smarts = 7 }, setFlags = { nonfiction_reader = true }, hintCareer = "science", feed = "You love learning facts!" },
				{ text = "Mystery stories", effects = { Smarts = 5 }, setFlags = { mystery_lover = true }, hintCareer = "law", feed = "You love solving mysteries!" },
				{ text = "I don't really like reading", effects = { }, feed = "Books aren't your thing right now." },
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════
	-- TEEN EVENTS (Ages 13-17)
	-- ══════════════════════════════════════════════════════════════════════
	teen = {
		{
			id = "class_selection",
			title = "Choosing Your Classes",
			emoji = "📋",
			text = "Time to select your elective classes.",
			question = "What interests you most?",
			minAge = 14, maxAge = 16,
			cooldown = 2,
			choices = {
				{ text = "Advanced Math & Science", effects = { Smarts = 5 }, setFlags = { stem_track = true }, hintCareer = "tech", feed = "Challenging STEM classes!" },
				{ text = "Creative Writing & Literature", effects = { Smarts = 3, Happiness = 3 }, hintCareer = "creative", feed = "Exploring the power of words." },
				{ text = "Business & Economics", effects = { Smarts = 3, Money = 10 }, setFlags = { business_track = true }, hintCareer = "finance", feed = "Learning how business works." },
				{ text = "Art & Music", effects = { Happiness = 5, Looks = 2 }, hintCareer = "creative", feed = "Developing artistic talents." },
			},
		},
		{
			id = "group_project",
			title = "Group Project Drama",
			emoji = "📝",
			text = "Group project, but one member isn't helping.",
			question = "How do you handle it?",
			minAge = 13, maxAge = 17,
			baseChance = 0.6, cooldown = 2,
			choices = {
				{ text = "Do their share yourself", effects = { Smarts = 3, Happiness = -3, Health = -2 }, feed = "You did all the work." },
				{ text = "Talk to them directly", effects = { Smarts = 2, Happiness = {-2, 5} }, setFlags = { direct = true }, feed = "You addressed it head-on." },
				{ text = "Tell the teacher", effects = { Smarts = 2 }, feed = "Teacher adjusted the grades." },
				{ text = "Accept a lower grade", effects = { Happiness = -2, Smarts = -1 }, feed = "The project suffered." },
			},
		},
		{
			id = "academic_pressure",
			title = "Under Pressure",
			emoji = "😰",
			text = "A big exam is coming up. Pressure is on.",
			question = "How do you cope?",
			minAge = 14, maxAge = 17,
			baseChance = 0.5, cooldown = 2,
			choices = {
				{ text = "Study intensively", effects = { Smarts = 5, Health = -3, Happiness = -2 }, feed = "Exhausted but prepared." },
				{ text = "Form a study group", effects = { Smarts = 4, Happiness = 2 }, feed = "Studying with friends helped." },
				{ text = "Take breaks to de-stress", effects = { Smarts = 2, Happiness = 3, Health = 2 }, feed = "Healthy studying!" },
				{ text = "Procrastinate", effects = { Smarts = {-2, 3}, Happiness = -3 }, setFlags = { procrastinator = true }, feed = "Crammed the night before!" },
			},
		},
		{
			id = "high_school_romance",
			title = "Feelings Developing",
			emoji = "💘",
			text = "Someone you like seems interested in you too.",
			question = "What do you do?",
			minAge = 14, maxAge = 17,
			baseChance = 0.6, cooldown = 2,
			choices = {
				{ text = "Ask them out", effects = { Happiness = {-5, 10} }, setFlags = { dating = true }, feed = "You made a move!" },
				{ text = "Drop hints and wait", effects = { Happiness = 2 }, feed = "Playing it cool." },
				{ text = "Focus on being friends first", effects = { Happiness = 3 }, feed = "Building a foundation." },
				{ text = "I'm not ready for dating", effects = { Happiness = 2 }, feed = "Focused on other things." },
			},
		},
		{
			id = "party_invitation",
			title = "The Big Party",
			emoji = "🎉",
			text = "Invited to a party. Parents might not approve.",
			question = "What do you do?",
			minAge = 15, maxAge = 17,
			baseChance = 0.6, cooldown = 2,
			choices = {
				{ text = "Sneak out and go", effects = { Happiness = 5, Health = {-3, 0} }, setFlags = { rebellious = true }, feed = "You snuck out! Wild party." },
				{ text = "Ask parents for permission", effects = { Happiness = 3 }, setFlags = { respectful = true }, feed = "They said yes (with rules)." },
				{ text = "Say you're at a friend's", effects = { Happiness = 4 }, setFlags = { bends_truth = true }, feed = "A white lie got you there." },
				{ text = "Skip it", effects = { Happiness = -2 }, feed = "You stayed home. FOMO is real." },
			},
		},
		{
			id = "clique_pressure",
			title = "Finding Your Group",
			emoji = "👥",
			text = "Social groups are forming. Where do you fit?",
			question = "Which group do you gravitate toward?",
			minAge = 13, maxAge = 16,
			oneTime = true,
			choices = {
				{ text = "The studious overachievers", effects = { Smarts = 5 }, setFlags = { nerd_group = true }, feed = "Found your tribe among academics." },
				{ text = "The athletes and jocks", effects = { Health = 5, Happiness = 3 }, setFlags = { jock_group = true }, hintCareer = "sports", feed = "Fit in with the athletic crowd." },
				{ text = "The creative/artsy types", effects = { Happiness = 5, Looks = 2 }, setFlags = { artsy_group = true }, hintCareer = "creative", feed = "Found kindred creative spirits." },
				{ text = "A mix of everyone", effects = { Happiness = 3, Smarts = 2 }, setFlags = { social_butterfly = true }, feed = "You move between groups easily." },
			},
		},
		{
			id = "first_job_teen",
			title = "Your First Job",
			emoji = "💼",
			text = "A local business is hiring teenagers.",
			question = "Will you apply?",
			minAge = 15, maxAge = 17,
			baseChance = 0.6, cooldown = 3,
			choices = {
				{ text = "Work at fast food", effects = { Money = 200, Health = -2, Happiness = -1 }, setFlags = { has_job = true }, feed = "You got a job flipping burgers!" },
				{ text = "Work at retail store", effects = { Money = 180, Happiness = 1 }, setFlags = { has_job = true }, feed = "You're working retail." },
				{ text = "Tutor younger kids", effects = { Money = 150, Smarts = 3 }, setFlags = { has_job = true }, hintCareer = "education", feed = "You're tutoring others!" },
				{ text = "No job yet", effects = { Happiness = 2 }, feed = "Focusing on school and fun." },
			},
		},
		{
			id = "peer_pressure",
			title = "Peer Pressure",
			emoji = "🚬",
			text = "Some kids offer you something you know isn't good.",
			question = "What do you do?",
			minAge = 15, maxAge = 17,
			baseChance = 0.4, cooldown = 3,
			choices = {
				{ text = "Firmly say no", effects = { Happiness = 3, Health = 2 }, setFlags = { resists_pressure = true }, feed = "You said no. Friends respected that." },
				{ text = "Make an excuse to leave", effects = { Happiness = 1 }, feed = "You got out smoothly." },
				{ text = "Try it once", effects = { Health = -5, Happiness = {-3, 3} }, setFlags = { experimented = true }, feed = "Not your proudest moment." },
				{ text = "Become a regular user", effects = { Health = -10, Happiness = -5, Smarts = -3 }, setFlags = { substance_issue = true }, feed = "This became a problem..." },
			},
		},
		{
			id = "college_prep",
			title = "Planning Your Future",
			emoji = "🎯",
			text = "College applications are looming.",
			question = "What path are you considering?",
			minAge = 16, maxAge = 17,
			oneTime = true,
			choices = {
				{ text = "Aim for a top university", effects = { Smarts = 3, Happiness = -2 }, setFlags = { college_bound = true, ambitious = true }, feed = "Working hard for a prestigious school." },
				{ text = "State school is fine", effects = { Smarts = 2, Happiness = 2 }, setFlags = { college_bound = true }, feed = "Taking a practical approach." },
				{ text = "Trade school / vocational", effects = { Smarts = 2 }, setFlags = { trade_school_bound = true }, hintCareer = "trades", feed = "Planning to learn a skilled trade." },
				{ text = "Skip college, start working", effects = { Money = 100 }, setFlags = { no_college = true }, feed = "Ready to enter the workforce." },
			},
		},
		{
			id = "sports_varsity",
			title = "Varsity Tryouts",
			emoji = "🏅",
			text = "Varsity sports tryouts are coming up.",
			question = "Will you try out?",
			minAge = 14, maxAge = 17,
			baseChance = 0.4, cooldown = 2,
			requiresStats = { Health = { min = 50 } },
			choices = {
				{ text = "Football", effects = { Health = 5, Happiness = {-3, 8} }, setFlags = { varsity_athlete = true }, hintCareer = "sports", feed = "You tried out for football!" },
				{ text = "Basketball", effects = { Health = 5, Happiness = {-3, 8} }, setFlags = { varsity_athlete = true }, feed = "You tried out for basketball!" },
				{ text = "Track & Field", effects = { Health = 7, Happiness = 5 }, setFlags = { varsity_athlete = true }, feed = "You joined the track team!" },
				{ text = "Not really into sports", effects = { }, feed = "Organized sports aren't your thing." },
			},
		},
		{
			id = "school_play",
			title = "Drama Production",
			emoji = "🎭",
			text = "The school is putting on a big play.",
			question = "Will you participate?",
			minAge = 13, maxAge = 17,
			baseChance = 0.4, cooldown = 2,
			choices = {
				{ text = "Audition for lead role", effects = { Happiness = {-5, 10}, Looks = 3 }, setFlags = { theater_kid = true }, hintCareer = "entertainment", feed = "You went for the lead!" },
				{ text = "Join the ensemble", effects = { Happiness = 5, Looks = 2 }, setFlags = { theater_kid = true }, feed = "You're part of the cast!" },
				{ text = "Work on tech/backstage", effects = { Smarts = 3, Happiness = 3 }, setFlags = { tech_crew = true }, feed = "You're part of the crew!" },
				{ text = "Just watch the show", effects = { Happiness = 2 }, feed = "You'll support from the audience." },
			},
		},
		{
			id = "volunteer",
			title = "Giving Back",
			emoji = "🤝",
			text = "Opportunity to volunteer in your community.",
			question = "What cause calls to you?",
			minAge = 13, maxAge = 17,
			baseChance = 0.4, cooldown = 2,
			choices = {
				{ text = "Animal shelter", effects = { Happiness = 5 }, setFlags = { volunteer = true, animal_lover = true }, hintCareer = "veterinary", feed = "Helping animals at the shelter!" },
				{ text = "Food bank", effects = { Happiness = 5, Health = 2 }, setFlags = { volunteer = true }, feed = "Helping feed those in need." },
				{ text = "Tutoring younger kids", effects = { Happiness = 3, Smarts = 3 }, setFlags = { volunteer = true }, hintCareer = "education", feed = "Helping younger kids learn!" },
				{ text = "I'm too busy", effects = { }, feed = "Volunteering will have to wait." },
			},
		},
		{
			id = "social_media_teen",
			title = "Going Viral",
			emoji = "📱",
			text = "Something you posted is getting attention!",
			question = "What happened?",
			minAge = 13, maxAge = 17,
			baseChance = 0.3, cooldown = 3,
			choices = {
				{ text = "A funny video went viral", effects = { Happiness = 10, Looks = 3 }, setFlags = { internet_famous = true }, hintCareer = "entertainment", feed = "You're internet famous!" },
				{ text = "Your art got shared everywhere", effects = { Happiness = 8, Looks = 5 }, setFlags = { recognized_artist = true }, hintCareer = "creative", feed = "Your creative work is noticed!" },
				{ text = "Something embarrassing spread", effects = { Happiness = -10, Looks = -5 }, feed = "Something embarrassing went viral..." },
				{ text = "Your opinion sparked debate", effects = { Happiness = {-5, 5} }, setFlags = { controversial = true }, feed = "Your hot take divided the internet." },
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════
	-- ADULT EVENTS (Ages 18+)
	-- ══════════════════════════════════════════════════════════════════════
	adult = {
		{
			id = "moving_out",
			title = "Time to Leave the Nest",
			emoji = "🏠",
			text = "Considering moving out of your parents' house.",
			question = "What's your plan?",
			minAge = 18, maxAge = 24,
			oneTime = true,
			choices = {
				{ text = "Get my own apartment", effects = { Happiness = 10, Money = -500 }, setFlags = { lives_alone = true }, feed = "You got your own place! Freedom!" },
				{ text = "Find roommates", effects = { Happiness = 5, Money = -200 }, setFlags = { has_roommates = true }, feed = "Moved in with roommates." },
				{ text = "Stay home to save money", effects = { Money = 300, Happiness = -3 }, setFlags = { lives_with_parents = true }, feed = "Staying home. Smart financially." },
			},
		},
		{
			id = "college_experience",
			title = "College Life",
			emoji = "📚",
			text = "College is a whole new world.",
			question = "What's your focus?",
			minAge = 18, maxAge = 22,
			requiresFlags = { college_bound = true },
			cooldown = 2,
			choices = {
				{ text = "Study hard, great grades", effects = { Smarts = 7, Happiness = -2, Health = -2 }, setFlags = { honors_student = true }, feed = "Crushing it academically!" },
				{ text = "Balance academics and social", effects = { Smarts = 4, Happiness = 5 }, feed = "Getting the full college experience." },
				{ text = "Party now, study later", effects = { Happiness = 8, Smarts = -2, Health = -3 }, setFlags = { party_animal = true }, feed = "College is about the experience, right?" },
				{ text = "Focus on networking", effects = { Smarts = 3, Money = 100 }, setFlags = { networker = true }, feed = "Building your professional network." },
			},
		},
		{
			id = "first_real_job",
			title = "Career Beginning",
			emoji = "💼",
			text = "You've landed your first real job! Time to start your career.",
			question = "How do you approach your new role?",
			minAge = 18, maxAge = 28,
			oneTime = true, priority = "high", isMilestone = true,
			requiresJob = true, -- Only triggers when you actually have a job
			choices = {
				{ text = "Work extra hard to impress", effects = { Smarts = 3, Health = -3, Money = 100 }, setFlags = { hard_worker = true, had_first_job = true }, feed = "Giving 110% to prove yourself." },
				{ text = "Good work, maintain balance", effects = { Happiness = 5, Money = 50 }, setFlags = { work_life_balance = true, had_first_job = true }, feed = "Doing well while maintaining life." },
				{ text = "Network and build relationships", effects = { Happiness = 3 }, setFlags = { networker = true, had_first_job = true }, feed = "Focused on making connections." },
				{ text = "Minimal effort, maximum coasting", effects = { Happiness = 3, Smarts = -2 }, setFlags = { slacker = true, had_first_job = true }, feed = "Doing just enough to get by." },
			},
		},
		{
			id = "serious_relationship",
			title = "Getting More Serious",
			emoji = "💑",
			text = "Your relationship has been going really well lately.",
			question = "How do you want to take it to the next level?",
			minAge = 18, maxAge = 40,
			baseChance = 0.5, cooldown = 5,
			requiresFlags = { has_partner = true }, -- Must already be dating
			choices = {
				{ text = "Commit fully to this", effects = { Happiness = 10 }, setFlags = { committed_relationship = true }, feed = "You're fully committed now!" },
				{ text = "Keep things as they are", effects = { Happiness = 3 }, feed = "No need to rush things." },
				{ text = "Take a step back", effects = { Happiness = -5 }, feed = "You need some space to think." },
				{ text = "End the relationship", effects = { Happiness = -8 }, setFlags = { recently_single = true }, feed = "You ended the relationship." },
			},
		},
		{
			id = "marriage_proposal",
			title = "The Big Question",
			emoji = "💍",
			text = "Your relationship has reached a point where marriage feels right.",
			question = "What happens?",
			minAge = 24, maxAge = 45,
			oneTime = true,
			requiresFlags = { committed_relationship = true, has_partner = true },
			requiresPartner = true,
			choices = {
				{ text = "Pop the question (they say yes!)", effects = { Happiness = 15 }, setFlags = { engaged = true }, feed = "They said YES!" },
				{ text = "Pop the question (they say no)", effects = { Happiness = -15 }, setFlags = { proposal_rejected = true }, feed = "They said no. Devastating." },
				{ text = "Get proposed to (say yes!)", effects = { Happiness = 15 }, setFlags = { engaged = true }, feed = "You said YES!" },
				{ text = "Not ready yet", effects = { Happiness = -2 }, feed = "Marriage can wait." },
			},
		},
		{
			id = "buying_home",
			title = "Buying a Home",
			emoji = "🏡",
			text = "Considering buying your first home.",
			question = "What's your approach?",
			minAge = 25, maxAge = 50,
			oneTime = true,
			requiresStats = { Money = { min = 1000 } },
			choices = {
				{ text = "Buy a starter home", effects = { Happiness = 10, Money = -5000 }, setFlags = { homeowner = true }, feed = "You bought your first home!" },
				{ text = "Stretch for dream home", effects = { Happiness = 15, Money = -15000, Health = -3 }, setFlags = { homeowner = true }, feed = "Got your dream home! But mortgage is steep." },
				{ text = "Keep renting for now", effects = { Money = 500 }, feed = "Renting a bit longer. More flexibility." },
				{ text = "Move to cheaper area", effects = { Happiness = 5, Money = -3000 }, setFlags = { homeowner = true, relocated = true }, feed = "Moved somewhere more affordable!" },
			},
		},
		{
			id = "having_children",
			title = "Starting a Family",
			emoji = "👶",
			text = "You and your spouse are talking about having children.",
			question = "What's the decision?",
			minAge = 25, maxAge = 45,
			oneTime = true,
			requiresFlags = { married = true, has_partner = true },
			requiresPartner = true,
			choices = {
				{ text = "Yes, we want children!", effects = { Happiness = 10, Money = -2000, Health = -2 }, setFlags = { has_children = true, parent = true }, feed = "You're going to be a parent!" },
				{ text = "Maybe someday", effects = { Happiness = 2 }, feed = "Kids are on the horizon, but not yet." },
				{ text = "Prefer to stay child-free", effects = { Happiness = 5, Money = 1000 }, setFlags = { childfree = true }, feed = "Decided not to have children. More freedom!" },
				{ text = "Adopt a child", effects = { Happiness = 12, Money = -3000 }, setFlags = { has_children = true, parent = true, adopted = true }, feed = "You adopted a child!" },
			},
		},
		{
			id = "career_crossroads",
			title = "Career Crossroads",
			emoji = "🛤️",
			text = "You're at a turning point in your career.",
			question = "What path do you take?",
			minAge = 28, maxAge = 45,
			baseChance = 0.4, cooldown = 5,
			requiresJob = true, -- Must have a job
			choices = {
				{ text = "Push for a promotion", effects = { Smarts = 2, Money = {-100, 500}, Happiness = {-3, 10} }, feed = "You went for the promotion!" },
				{ text = "Change companies for better pay", effects = { Money = 1000, Happiness = 3 }, setFlags = { job_hopper = true }, feed = "Switched jobs for a raise!" },
				{ text = "Pivot to a new career", effects = { Smarts = 5, Money = -1000, Happiness = 5 }, setFlags = { career_changer = true }, feed = "Starting over in a new field!" },
				{ text = "Stay the course", effects = { Happiness = 2 }, feed = "You're content where you are." },
			},
		},
		{
			id = "midlife_health",
			title = "Health Wake-Up Call",
			emoji = "🏥",
			text = "A routine checkup reveals you need to pay attention to health.",
			question = "How do you respond?",
			minAge = 35, maxAge = 50,
			baseChance = 0.3, cooldown = 5,
			choices = {
				{ text = "Complete lifestyle overhaul", effects = { Health = 15, Happiness = 5, Money = -500 }, setFlags = { health_conscious = true }, feed = "Transformed your lifestyle!" },
				{ text = "Make gradual improvements", effects = { Health = 8, Happiness = 3 }, feed = "Making steady health improvements." },
				{ text = "Ignore it", effects = { Health = -10, Happiness = -5 }, feed = "You ignored the warning signs..." },
				{ text = "Become obsessive about health", effects = { Health = 10, Happiness = -5, Money = -1000 }, feed = "Health became your entire focus." },
			},
		},
		{
			id = "empty_nest",
			title = "Empty Nest",
			emoji = "🪹",
			text = "Your children have grown up and moved out.",
			question = "How do you feel?",
			minAge = 45, maxAge = 60,
			oneTime = true,
			requiresFlags = { has_children = true },
			choices = {
				{ text = "Sad but proud", effects = { Happiness = -3 }, setFlags = { empty_nester = true }, feed = "You miss them, but raised them well." },
				{ text = "Excited for new freedom", effects = { Happiness = 10, Money = 500 }, setFlags = { empty_nester = true }, feed = "A new chapter of freedom!" },
				{ text = "Focus on your relationship", effects = { Happiness = 8 }, setFlags = { empty_nester = true }, feed = "You and your partner reconnect." },
				{ text = "Fill the void with hobbies", effects = { Happiness = 5, Smarts = 2 }, setFlags = { empty_nester = true }, feed = "You discovered new passions." },
			},
		},
		{
			id = "retirement_planning",
			title = "Thinking About Retirement",
			emoji = "📊",
			text = "Retirement is on the horizon. Are you prepared?",
			question = "What's your retirement outlook?",
			minAge = 50, maxAge = 62,
			oneTime = true,
			choices = {
				{ text = "Well prepared - saved consistently", effects = { Happiness = 10, Money = 5000 }, setFlags = { retirement_ready = true }, feed = "Years of saving paid off!" },
				{ text = "Moderately prepared", effects = { Happiness = 5, Money = 1000 }, setFlags = { retirement_possible = true }, feed = "You'll be okay, but not lavish." },
				{ text = "Not at all - need to work longer", effects = { Happiness = -5 }, setFlags = { must_keep_working = true }, feed = "Retirement will have to wait." },
				{ text = "Planning early retirement", effects = { Happiness = 8, Money = -2000 }, setFlags = { early_retirement = true }, feed = "You're cutting out early!" },
			},
		},
		{
			id = "grandchildren",
			title = "Becoming a Grandparent",
			emoji = "👴",
			text = "Your child is having a baby. You're a grandparent!",
			question = "How do you feel?",
			minAge = 45, maxAge = 75,
			oneTime = true,
			requiresFlags = { has_children = true },
			choices = {
				{ text = "Overjoyed!", effects = { Happiness = 15 }, setFlags = { grandparent = true }, feed = "You're a grandparent! Circle of life continues." },
				{ text = "Happy but feeling old", effects = { Happiness = 8 }, setFlags = { grandparent = true }, feed = "A grandparent... when did that happen?" },
				{ text = "Ready to spoil them", effects = { Happiness = 10, Money = -500 }, setFlags = { grandparent = true }, feed = "Grandparent privileges: spoil and return!" },
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════
	-- CAREER EVENTS
	-- ══════════════════════════════════════════════════════════════════════
	career = {
		{
			id = "workplace_conflict",
			title = "Office Drama",
			emoji = "😤",
			text = "A coworker has been taking credit for your work.",
			question = "How do you handle this?",
			minAge = 18, maxAge = 65,
			baseChance = 0.4, cooldown = 3,
			requiresJob = true,
			choices = {
				{ text = "Confront them directly", effects = { Happiness = {-5, 5} }, setFlags = { confrontational = true }, feed = "You called them out." },
				{ text = "Document everything, report to HR", effects = { Smarts = 2 }, feed = "You took the professional route." },
				{ text = "Let it go this time", effects = { Happiness = -3 }, feed = "You let it slide. But watching now." },
				{ text = "Beat them at their own game", effects = { Smarts = 3, Happiness = {-3, 5} }, feed = "Two can play at office politics." },
			},
		},
		{
			id = "promotion_opportunity",
			title = "Opportunity Knocks",
			emoji = "📈",
			text = "A promotion opportunity has opened up at work.",
			question = "Do you go for it?",
			minAge = 20, maxAge = 60,
			baseChance = 0.4, cooldown = 3,
			requiresJob = true,
			choices = {
				{ text = "Apply and compete hard", effects = { Smarts = 2, Money = {0, 1000}, Health = -2 }, feed = "You threw your hat in the ring!" },
				{ text = "Apply casually", effects = { Money = {0, 500} }, feed = "Applied but kept expectations low." },
				{ text = "Not interested", effects = { Happiness = 2 }, feed = "You're happy where you are." },
			},
		},
		{
			id = "layoff_threat",
			title = "Company Restructuring",
			emoji = "📉",
			text = "Your company is laying people off. Your position is at risk.",
			question = "What do you do?",
			minAge = 22, maxAge = 60,
			baseChance = 0.25, cooldown = 5,
			requiresJob = true,
			choices = {
				{ text = "Work extra hard to prove value", effects = { Health = -5, Smarts = 2, Money = {-200, 500} }, feed = "Worked overtime to secure position." },
				{ text = "Start job hunting quietly", effects = { Smarts = 2 }, setFlags = { job_hunting = true }, feed = "Exploring other options." },
				{ text = "Accept severance if offered", effects = { Money = 2000, Happiness = -5 }, setFlags = { unemployed = true }, feed = "Took the package. Time for something new." },
				{ text = "Trust it will work out", effects = { Happiness = {-10, 5} }, feed = "You hoped for the best..." },
			},
		},
		{
			id = "boss_from_hell",
			title = "Difficult Manager",
			emoji = "👹",
			text = "Your new manager is making work miserable.",
			question = "How do you cope?",
			minAge = 18, maxAge = 60,
			baseChance = 0.35, cooldown = 4,
			requiresJob = true,
			choices = {
				{ text = "Keep your head down", effects = { Happiness = -5, Health = -3 }, feed = "You endured in silence." },
				{ text = "Address it with HR", effects = { Happiness = {-5, 5} }, feed = "You reported the issues." },
				{ text = "Find a new job", effects = { Happiness = 5 }, setFlags = { job_hunting = true }, feed = "Life's too short for bad bosses." },
				{ text = "Adapt and learn to work with them", effects = { Smarts = 3, Happiness = 2 }, feed = "You figured out the relationship." },
			},
		},
		{
			id = "work_achievement",
			title = "Major Achievement",
			emoji = "🏆",
			text = "You accomplished something significant at work!",
			question = "What was it?",
			minAge = 20, maxAge = 65,
			baseChance = 0.3, cooldown = 3,
			requiresJob = true,
			requiresStats = { Smarts = { min = 50 } },
			choices = {
				{ text = "Landed a big client/deal", effects = { Happiness = 10, Money = 1000, Smarts = 2 }, setFlags = { big_achiever = true }, feed = "You closed a major deal!" },
				{ text = "Solved a critical problem", effects = { Happiness = 8, Smarts = 5 }, setFlags = { problem_solver = true }, feed = "You saved the day!" },
				{ text = "Got recognized by leadership", effects = { Happiness = 10, Money = 500 }, feed = "The executives noticed your work!" },
				{ text = "Mentored someone successfully", effects = { Happiness = 8, Smarts = 2 }, setFlags = { mentor = true }, feed = "You helped someone grow!" },
			},
		},
		{
			id = "business_trip",
			title = "Business Travel",
			emoji = "✈️",
			text = "Your company selected you for an important business trip.",
			question = "How do you approach it?",
			minAge = 22, maxAge = 60,
			baseChance = 0.35, cooldown = 2,
			requiresJob = true,
			choices = {
				{ text = "All business, impress clients", effects = { Smarts = 3, Money = 300, Health = -2 }, feed = "You crushed it professionally!" },
				{ text = "Balance work and exploration", effects = { Happiness = 5, Smarts = 2 }, feed = "You saw some sights while working!" },
				{ text = "Network at every opportunity", effects = { Smarts = 2 }, setFlags = { strong_network = true }, feed = "You made valuable connections!" },
				{ text = "Party too much", effects = { Happiness = 5, Health = -5, Money = -200 }, feed = "The expense report might be awkward..." },
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════
	-- RELATIONSHIP EVENTS
	-- ══════════════════════════════════════════════════════════════════════
	relationships = {
		{
			id = "sibling_rivalry",
			title = "Sibling Conflict",
			emoji = "👊",
			text = "You and your sibling are fighting.",
			question = "How do you handle it?",
			minAge = 5, maxAge = 25,
			baseChance = 0.4, cooldown = 3,
			requiresFlags = { big_family = true }, -- Only if you have siblings
			choices = {
				{ text = "Work it out together", effects = { Happiness = 5, Smarts = 2 }, setFlags = { good_sibling = true }, feed = "You and your sibling made up." },
				{ text = "Give them the silent treatment", effects = { Happiness = -3 }, feed = "The cold war continues..." },
				{ text = "Involve your parents", effects = { Happiness = {-5, 3} }, feed = "Parents got involved. Mixed results." },
				{ text = "Apologize", effects = { Happiness = 3 }, setFlags = { peacemaker = true }, feed = "You chose peace over being right." },
			},
		},
		{
			id = "friend_in_need",
			title = "A Friend Needs Help",
			emoji = "🆘",
			text = "A close friend is going through a tough time.",
			question = "How do you respond?",
			minAge = 12, maxAge = 80,
			baseChance = 0.4, cooldown = 2,
			choices = {
				{ text = "Drop everything to help", effects = { Happiness = 5, Health = -2 }, setFlags = { loyal_friend = true }, feed = "You were there when they needed you." },
				{ text = "Help within your limits", effects = { Happiness = 3 }, feed = "You supported them the best you could." },
				{ text = "Help them find professional support", effects = { Happiness = 3, Smarts = 2 }, feed = "You connected them with resources." },
				{ text = "I have my own problems", effects = { Happiness = -3 }, setFlags = { selfish_friend = true }, feed = "You couldn't be there for them." },
			},
		},
		{
			id = "friendship_drift",
			title = "Growing Apart",
			emoji = "😔",
			text = "You and a longtime friend have been drifting apart.",
			question = "What do you do?",
			minAge = 16, maxAge = 60,
			baseChance = 0.3, cooldown = 4,
			choices = {
				{ text = "Make an effort to reconnect", effects = { Happiness = 5 }, setFlags = { values_friendship = true }, feed = "You rekindled the friendship." },
				{ text = "Accept that people change", effects = { Happiness = -2, Smarts = 2 }, feed = "Some friendships run their course." },
				{ text = "Have an honest conversation", effects = { Happiness = {-3, 5} }, feed = "You talked about what's been happening." },
				{ text = "Let it fade naturally", effects = { Happiness = -3 }, feed = "The friendship quietly ended." },
			},
		},
		{
			id = "new_friendship",
			title = "Making New Friends",
			emoji = "🤗",
			text = "You've met someone who could become a good friend.",
			question = "How do you nurture this connection?",
			minAge = 8, maxAge = 70,
			baseChance = 0.4, cooldown = 2,
			choices = {
				{ text = "Invite them to hang out", effects = { Happiness = 5 }, setFlags = { socially_active = true }, feed = "You took initiative and made a new friend!" },
				{ text = "Keep it casual for now", effects = { Happiness = 3 }, feed = "You're taking things slow." },
				{ text = "They seem great, but I'm too busy", effects = { Happiness = -2 }, feed = "The opportunity passed." },
				{ text = "Share something personal", effects = { Happiness = 7 }, setFlags = { deep_connector = true }, feed = "You bonded quickly over shared experiences." },
			},
		},
		{
			id = "family_reunion",
			title = "Family Reunion",
			emoji = "👨‍👩‍👧‍👦",
			text = "There's a big family reunion coming up.",
			question = "How do you approach it?",
			minAge = 10, maxAge = 80,
			baseChance = 0.3, cooldown = 5,
			choices = {
				{ text = "Embrace the chaos", effects = { Happiness = 7 }, setFlags = { family_oriented = true }, feed = "You enjoyed reconnecting with family!" },
				{ text = "Catch up with specific relatives", effects = { Happiness = 5, Smarts = 2 }, feed = "You had meaningful conversations." },
				{ text = "Avoid the drama", effects = { Happiness = 2 }, feed = "You stayed out of family politics." },
				{ text = "Skip it", effects = { Happiness = {-3, 3} }, feed = "You missed the reunion." },
			},
		},
		{
			id = "dating_app",
			title = "Modern Dating",
			emoji = "📱",
			text = "You've been single for a while and decide to try dating apps.",
			question = "How's it going?",
			minAge = 18, maxAge = 50,
			baseChance = 0.35, cooldown = 3,
			requiresFlags = { has_partner = false }, -- Only if single
			choices = {
				{ text = "Met someone special", effects = { Happiness = 8 }, setFlags = { dating_someone = true }, feed = "You found someone promising!" },
				{ text = "Lots of bad dates, but learning", effects = { Happiness = -2, Smarts = 2 }, feed = "The dating world is rough." },
				{ text = "Delete the apps, try meeting people IRL", effects = { Happiness = 3 }, feed = "Going old school." },
				{ text = "I'm okay being single", effects = { Happiness = 5 }, setFlags = { content_single = true }, feed = "Single life has its perks!" },
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════
	-- MILESTONES
	-- ══════════════════════════════════════════════════════════════════════
	milestones = {
		{
			id = "birth_story",
			title = "Your Birth Story",
			emoji = "🍼",
			text = "Your parents tell the story of when you were born.",
			question = "What was memorable about your arrival?",
			minAge = 3, maxAge = 6,
			oneTime = true, priority = "high", isMilestone = true,
			choices = {
				{ text = "I was born early but healthy", effects = { Health = 5 }, setFlags = { fighter = true }, feed = "You came early but showed strength." },
				{ text = "A perfectly normal delivery", effects = { Happiness = 3 }, feed = "You arrived right on schedule." },
				{ text = "There were complications, but I made it", effects = { Health = -3 }, setFlags = { survivor = true }, feed = "Your birth was difficult, but you're a fighter." },
				{ text = "I was a very big baby", effects = { Health = 3 }, feed = "You were a healthy, robust baby!" },
			},
		},
		{
			id = "family_background",
			title = "Your Family",
			emoji = "👨‍👩‍👧",
			text = "As you grow, you understand your family situation.",
			question = "What kind of family do you have?",
			minAge = 4, maxAge = 7,
			oneTime = true, priority = "high", isMilestone = true,
			choices = {
				{ text = "Two loving parents", effects = { Happiness = 10 }, setFlags = { stable_home = true }, feed = "You have a supportive, loving family." },
				{ text = "Single parent working hard", effects = { Happiness = 3, Smarts = 2 }, setFlags = { single_parent = true }, feed = "Your parent works hard for you." },
				{ text = "Living with grandparents", effects = { Happiness = 5, Smarts = 3 }, setFlags = { raised_by_grandparents = true }, feed = "Grandparents raised you with wisdom." },
				{ text = "Large extended family", effects = { Happiness = 8 }, setFlags = { big_family = true }, feed = "You're surrounded by relatives!" },
			},
		},
		{
			id = "losing_tooth",
			title = "First Lost Tooth",
			emoji = "🦷",
			text = "Your first baby tooth fell out!",
			question = "What do you do with it?",
			minAge = 5, maxAge = 7,
			oneTime = true, isMilestone = true,
			choices = {
				{ text = "Put it under pillow for tooth fairy", effects = { Happiness = 5, Money = 5 }, feed = "The tooth fairy left you money!" },
				{ text = "Keep it in a special box", effects = { Happiness = 3 }, setFlags = { sentimental = true }, feed = "You're saving your teeth." },
				{ text = "Show it off to everyone", effects = { Happiness = 5, Looks = 1 }, feed = "You proudly showed off your gap-toothed smile!" },
				{ text = "Accidentally swallow it", effects = { Happiness = -2 }, feed = "Oops! Well, that's one way to lose a tooth." },
			},
		},
		{
			id = "learned_bike",
			title = "Learning to Ride a Bike",
			emoji = "🚲",
			text = "You're learning to ride a bike!",
			question = "How does it go?",
			minAge = 5, maxAge = 8,
			oneTime = true, isMilestone = true,
			choices = {
				{ text = "Got it on the first try!", effects = { Happiness = 8, Health = 3 }, setFlags = { natural_athlete = true }, feed = "You're a natural! Freedom on two wheels!" },
				{ text = "Fell a lot, but kept trying", effects = { Happiness = 5, Health = -2 }, setFlags = { persistent = true }, feed = "You got some scrapes, but never gave up!" },
				{ text = "Needed training wheels a while", effects = { Happiness = 3 }, setFlags = { cautious_learner = true }, feed = "You took your time, but got there." },
				{ text = "Too scared, gave up", effects = { Happiness = -3 }, setFlags = { bike_phobia = true }, feed = "Bikes aren't for everyone... yet." },
			},
		},
		{
			id = "discovered_passion",
			title = "Finding Your Passion",
			emoji = "⭐",
			text = "Something really captured your imagination!",
			question = "What got you excited?",
			minAge = 6, maxAge = 12,
			oneTime = true, isMilestone = true,
			choices = {
				{ text = "Sports and athletics", effects = { Health = 5, Happiness = 5 }, setFlags = { passionate_athlete = true }, hintCareer = "sports", feed = "You fell in love with sports!" },
				{ text = "Art and creativity", effects = { Happiness = 7, Looks = 3 }, setFlags = { passionate_artist = true }, hintCareer = "creative", feed = "Your creative soul awakened!" },
				{ text = "Science and discovery", effects = { Smarts = 7 }, setFlags = { passionate_scientist = true }, hintCareer = "science", feed = "The mysteries of the universe call to you!" },
				{ text = "Building and creating things", effects = { Smarts = 5, Happiness = 3 }, setFlags = { passionate_builder = true }, hintCareer = "tech", feed = "You love making things!" },
				{ text = "Helping others", effects = { Happiness = 5 }, setFlags = { passionate_helper = true }, hintCareer = "medical", feed = "You have a natural desire to help!" },
			},
		},
		{
			id = "graduation_high_school",
			title = "High School Graduation",
			emoji = "🎓",
			text = "You're graduating from high school!",
			question = "How do you feel about your experience?",
			minAge = 17, maxAge = 19,
			oneTime = true, priority = "high", isMilestone = true,
			choices = {
				{ text = "Best years of my life", effects = { Happiness = 10 }, setFlags = { loved_high_school = true }, feed = "You graduated with amazing memories!" },
				{ text = "Glad it's over", effects = { Happiness = 5 }, feed = "High school wasn't your favorite, but you made it!" },
				{ text = "Nervous about what's next", effects = { Happiness = 2, Smarts = 2 }, feed = "The future is uncertain but exciting." },
				{ text = "I learned a lot about myself", effects = { Happiness = 5, Smarts = 5 }, setFlags = { self_aware = true }, feed = "High school was a journey of self-discovery." },
			},
		},
		{
			id = "wedding_day",
			title = "Wedding Day",
			emoji = "💒",
			text = "It's your wedding day!",
			question = "What kind of wedding did you have?",
			minAge = 20, maxAge = 70,
			oneTime = true, priority = "high", isMilestone = true,
			requiresFlags = { engaged = true },
			choices = {
				{ text = "Dream wedding, no expense spared", effects = { Happiness = 15, Money = -10000 }, setFlags = { married = true }, feed = "Your fairy tale wedding was unforgettable!" },
				{ text = "Small, intimate ceremony", effects = { Happiness = 12, Money = -2000 }, setFlags = { married = true }, feed = "A beautiful, intimate celebration." },
				{ text = "Courthouse wedding", effects = { Happiness = 8, Money = -100 }, setFlags = { married = true }, feed = "Quick and simple - you're married!" },
				{ text = "Destination wedding adventure", effects = { Happiness = 15, Money = -8000 }, setFlags = { married = true }, feed = "Married in a beautiful location!" },
			},
		},
		{
			id = "first_child_birth",
			title = "Becoming a Parent",
			emoji = "👶",
			text = "Your first child is born!",
			question = "How do you feel?",
			minAge = 20, maxAge = 50,
			oneTime = true, priority = "high", isMilestone = true,
			requiresFlags = { has_children = true },
			choices = {
				{ text = "Overwhelmed with love", effects = { Happiness = 20, Health = -3 }, setFlags = { devoted_parent = true }, feed = "Your heart expanded the moment you held them." },
				{ text = "Terrified but excited", effects = { Happiness = 10 }, feed = "Parenthood is scary but amazing!" },
				{ text = "Already planning their future", effects = { Happiness = 8, Smarts = 2 }, setFlags = { tiger_parent = true }, feed = "You have big dreams for your child!" },
				{ text = "I hope I can do this", effects = { Happiness = 5 }, feed = "You're nervous but determined to be a good parent." },
			},
		},
		{
			id = "retirement_day",
			title = "Retirement Day",
			emoji = "🌴",
			text = "After decades of work, you're retiring!",
			question = "How do you celebrate?",
			minAge = 55, maxAge = 75,
			oneTime = true, priority = "high", isMilestone = true,
			choices = {
				{ text = "Big retirement party", effects = { Happiness = 15, Money = -500 }, setFlags = { retired = true }, feed = "You celebrated with colleagues and friends!" },
				{ text = "Immediately start traveling", effects = { Happiness = 15, Money = -3000, Health = 3 }, setFlags = { retired = true }, feed = "You're seeing the world!" },
				{ text = "Quietly transition", effects = { Happiness = 10 }, setFlags = { retired = true }, feed = "You slipped into retirement peacefully." },
				{ text = "Planning my next chapter", effects = { Happiness = 12, Smarts = 3 }, setFlags = { retired = true }, feed = "Retirement is just the beginning!" },
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════
	-- RANDOM / EVERYDAY EVENTS
	-- ══════════════════════════════════════════════════════════════════════
	random = {
		{
			id = "found_money",
			title = "Lucky Find",
			emoji = "💵",
			text = "You found some money on the ground!",
			question = "What do you do with it?",
			minAge = 5, maxAge = 80,
			baseChance = 0.25, cooldown = 5,
			choices = {
				{ text = "Keep it", effects = { Money = { 20, 100 }, Happiness = 5 }, feed = "Finders keepers!" },
				{ text = "Turn it in to lost & found", effects = { Happiness = 3 }, setFlags = { honest = true }, feed = "Good karma!" },
				{ text = "Donate it", effects = { Happiness = 8 }, setFlags = { charitable = true }, feed = "You donated the found money." },
			},
		},
		{
			id = "weather_event",
			title = "Caught in the Storm",
			emoji = "⛈️",
			text = "You got caught in a sudden downpour!",
			question = "What do you do?",
			minAge = 8, maxAge = 70,
			baseChance = 0.3, cooldown = 3,
			choices = {
				{ text = "Run for cover", effects = { Health = -2, Happiness = -1 }, feed = "You got drenched running for shelter." },
				{ text = "Dance in the rain", effects = { Happiness = 8, Health = -3 }, setFlags = { free_spirit = true }, feed = "You danced like nobody was watching!" },
				{ text = "Wait it out", effects = { Happiness = -2 }, feed = "You waited until the storm passed." },
			},
		},
		{
			id = "lottery",
			title = "Lottery Ticket",
			emoji = "🎫",
			text = "Someone gave you a lottery ticket as a gift.",
			question = "Did you win?",
			minAge = 18, maxAge = 80,
			baseChance = 0.2, cooldown = 5,
			choices = {
				{ text = "Check the numbers... WINNER!", effects = { Money = { 500, 5000 }, Happiness = 15 }, feed = "You won money on a lottery ticket!" },
				{ text = "Check the numbers... nothing", effects = { Happiness = -2 }, feed = "The lottery ticket was a bust." },
				{ text = "Give it to someone else", effects = { Happiness = 3 }, feed = "You passed on the lottery ticket." },
			},
		},
		{
			id = "minor_illness",
			title = "Under the Weather",
			emoji = "🤒",
			text = "You've come down with a cold.",
			question = "How do you handle it?",
			minAge = 5, maxAge = 80,
			baseChance = 0.4, cooldown = 2,
			choices = {
				{ text = "Rest and recover", effects = { Health = 3, Happiness = -2 }, feed = "You took time to rest and recovered." },
				{ text = "Push through it", effects = { Health = -5, Happiness = -3 }, feed = "You tried to ignore it and felt worse." },
				{ text = "Home remedies", effects = { Health = 2, Happiness = 1 }, feed = "Grandma's chicken soup worked wonders." },
			},
		},
		{
			id = "minor_accident",
			title = "Oops!",
			emoji = "🤕",
			text = "You had a minor accident.",
			question = "What happened?",
			minAge = 5, maxAge = 75,
			baseChance = 0.25, cooldown = 3,
			choices = {
				{ text = "Stubbed your toe badly", effects = { Health = -3, Happiness = -2 }, feed = "The pain was real." },
				{ text = "Tripped and fell", effects = { Health = -5, Happiness = -3 }, feed = "You took a tumble and got bruises." },
				{ text = "Cut yourself cooking", effects = { Health = -4 }, feed = "A kitchen mishap left you with a cut." },
			},
		},
		{
			id = "old_friend",
			title = "Blast from the Past",
			emoji = "👋",
			text = "You ran into someone from your past that you haven't seen in years.",
			question = "How does it go?",
			minAge = 25, maxAge = 70,
			baseChance = 0.3, cooldown = 5,
			requiresFlags = { socially_active = true }, -- Must have been social
			choices = {
				{ text = "Great reunion!", effects = { Happiness = 8 }, feed = "You reconnected with an old friend!" },
				{ text = "Awkward small talk", effects = { Happiness = -2 }, feed = "The reunion was pretty awkward." },
				{ text = "They've changed completely", effects = { Happiness = { -3, 5 } }, feed = "They're a completely different person now." },
			},
		},
		{
			id = "stranger_kindness",
			title = "Random Kindness",
			emoji = "💝",
			text = "A stranger did something unexpectedly kind for you.",
			question = "What happened?",
			minAge = 8, maxAge = 80,
			baseChance = 0.25, cooldown = 3,
			choices = {
				{ text = "They paid for your coffee", effects = { Happiness = 8 }, feed = "A stranger paid for your order!" },
				{ text = "They helped with your bags", effects = { Happiness = 5 }, feed = "Someone helped you carry heavy bags." },
				{ text = "They gave you a genuine compliment", effects = { Happiness = 7, Looks = 1 }, feed = "A stranger's kind words made your day." },
			},
		},
		{
			id = "new_hobby",
			title = "New Interest",
			emoji = "🎯",
			text = "You discovered a new hobby that interests you.",
			question = "What is it?",
			minAge = 10, maxAge = 70,
			baseChance = 0.35, cooldown = 5,
			choices = {
				{ text = "A creative pursuit", effects = { Happiness = 8, Smarts = 2 }, setFlags = { creative_hobby = true }, feed = "You picked up a creative new hobby!" },
				{ text = "A physical activity", effects = { Happiness = 5, Health = 5 }, setFlags = { active_hobby = true }, feed = "You started a new active hobby!" },
				{ text = "A mental challenge", effects = { Smarts = 7, Happiness = 3 }, setFlags = { intellectual_hobby = true }, feed = "A hobby that challenges your mind!" },
				{ text = "A social activity", effects = { Happiness = 8 }, setFlags = { social_hobby = true }, feed = "Your new hobby helps you meet people!" },
			},
		},
		{
			id = "pet_encounter",
			title = "Animal Encounter",
			emoji = "🐕",
			text = "A friendly stray animal approached you.",
			question = "What do you do?",
			minAge = 5, maxAge = 70,
			baseChance = 0.25, cooldown = 4,
			choices = {
				{ text = "Take it home!", effects = { Happiness = 15, Money = -200 }, setFlags = { has_pet = true, animal_lover = true }, feed = "You adopted a stray pet!" },
				{ text = "Pet it and move on", effects = { Happiness = 5 }, feed = "You made a furry friend for a moment." },
				{ text = "Call animal control", effects = { Happiness = 2 }, feed = "You made sure the animal would be cared for." },
				{ text = "I'm not an animal person", effects = { }, feed = "You kept your distance." },
			},
		},
		{
			id = "phone_broke",
			title = "Phone Disaster",
			emoji = "📱",
			text = "Your phone screen cracked!",
			question = "What do you do?",
			minAge = 13, maxAge = 70,
			baseChance = 0.3, cooldown = 3,
			choices = {
				{ text = "Get it repaired", effects = { Money = -200, Happiness = -2 }, feed = "You got your phone screen fixed." },
				{ text = "Buy a new phone", effects = { Money = -800, Happiness = 3 }, feed = "You upgraded to a new phone." },
				{ text = "Live with the cracks", effects = { Happiness = -3 }, feed = "You're using a cracked phone now." },
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

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
	for categoryName, events in pairs(EventPools) do
		total += registerEvents(events, categoryName)
	end
	
	print(string.format("[LifeEvents] Loaded %d events across %d categories.", total, 0))
	return total
end

-- Auto-init
LifeEvents.init()

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT HISTORY TRACKING
-- ════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════
-- ELIGIBILITY CHECKS
-- ════════════════════════════════════════════════════════════════════════════

local function canEventTrigger(event, state)
	local age = state.Age or 0
	local history = getEventHistory(state)
	
	if event.minAge and age < event.minAge then return false end
	if event.maxAge and age > event.maxAge then return false end
	
	if event.oneTime and history.completed[event.id] then
		return false
	end
	
	local cooldown = event.cooldown or 3
	local lastAge = history.lastOccurrence[event.id]
	if lastAge and (age - lastAge) < cooldown then
		return false
	end
	
	local maxOccur = event.maxOccurrences or 5
	local count = history.occurrences[event.id] or 0
	if count >= maxOccur then
		return false
	end
	
	if event.requiresFlags then
		local flags = state.Flags or {}
		for flag, required in pairs(event.requiresFlags) do
			if required == true and not flags[flag] then return false end
			if required == false and flags[flag] then return false end
		end
	end
	
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
	
	-- Check if event requires having a job
	if event.requiresJob then
		local hasJob = state.CurrentJob ~= nil
		if not hasJob then return false end
	end
	
	-- Check if event requires NOT having a job
	if event.requiresNoJob then
		local hasJob = state.CurrentJob ~= nil
		if hasJob then return false end
	end
	
	-- Check if event requires having a partner
	if event.requiresPartner then
		local hasPartner = state.Relationships and state.Relationships.partner
		if not hasPartner then return false end
	end
	
	-- Check if event requires education level
	if event.requiresEducation then
		local edu = state.Education or "none"
		local eduLevels = { none = 0, elementary = 1, middle_school = 2, high_school = 3, community = 4, bachelor = 5, master = 6, law = 7, medical = 7, phd = 8 }
		local playerLevel = eduLevels[edu] or 0
		local requiredLevel = eduLevels[event.requiresEducation] or 0
		if playerLevel < requiredLevel then return false end
	end
	
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

-- ════════════════════════════════════════════════════════════════════════════
-- CATEGORY SELECTION
-- ════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════
-- BUILD YEAR QUEUE - Main entry point
-- ════════════════════════════════════════════════════════════════════════════

function LifeEvents.buildYearQueue(state, options)
	options = options or {}
	local maxEvents = options.maxEvents or 1 -- BitLife style: 1 event max per year
	
	if not state then return {} end
	
	local selectedEvents = {}
	local candidateEvents = {}
	
	local categories = getRelevantCategories(state)
	
	-- Collect all eligible events
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
	
	-- Separate priority (milestone) events from regular events
	local priorityEvents = {}
	local regularEvents = {}
	
	for _, candidate in ipairs(candidateEvents) do
		if candidate.priority then
			table.insert(priorityEvents, candidate)
		else
			table.insert(regularEvents, candidate)
		end
	end
	
	-- Priority events (milestones) always trigger if available
	if #priorityEvents > 0 then
		-- Pick the highest weighted priority event
		table.sort(priorityEvents, function(a, b) return a.weight > b.weight end)
		local chosen = priorityEvents[1]
		table.insert(selectedEvents, chosen.event)
		recordEventShown(state, chosen.event)
		return selectedEvents -- Just return the milestone, don't stack more events
	end
	
	-- For regular events: chance of a "quiet year" with no events
	-- Young kids (0-4): 30% chance of quiet year
	-- Children (5-12): 40% chance of quiet year
	-- Teens (13-17): 35% chance of quiet year
	-- Adults (18+): 50% chance of quiet year
	local age = state.Age or 0
	local quietChance = 0.4
	if age <= 4 then
		quietChance = 0.3 -- More things happen in early childhood
	elseif age <= 12 then
		quietChance = 0.4
	elseif age <= 17 then
		quietChance = 0.35
	else
		quietChance = 0.5 -- Adult years are often routine
	end
	
	if RANDOM:NextNumber() < quietChance then
		return {} -- Quiet year, no event
	end
	
	-- Select ONE regular event using weighted random selection
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

-- ════════════════════════════════════════════════════════════════════════════
-- EVENT ENGINE
-- ════════════════════════════════════════════════════════════════════════════

local EventEngine = {}

-- Name pools for generating relationship names
local MaleNames = {"James", "Michael", "David", "John", "Robert", "Chris", "Daniel", "Matthew", "Anthony", "Mark", "Steven", "Andrew", "Joshua", "Kevin", "Brian", "Ryan", "Justin", "Brandon", "Eric", "Tyler", "Alex", "Jake", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Oliver", "Aiden", "Carter"}
local FemaleNames = {"Emma", "Olivia", "Sophia", "Isabella", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn", "Abigail", "Emily", "Elizabeth", "Sofia", "Avery", "Ella", "Scarlett", "Grace", "Chloe", "Victoria", "Riley", "Aria", "Lily", "Zoey", "Hannah", "Layla", "Nora", "Zoe", "Leah", "Hazel", "Luna"}

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
	
	-- For romance, use opposite gender
	if relType == "romance" or relType == "partner" then
		gender = getOppositeGender(state.Gender or "male")
		name = name or generateName(gender)
		-- Romance partners are around the same age
		age = math.max(18, age + RANDOM:NextInteger(-5, 5))
	elseif relType == "friend" then
		-- Friends can be any gender
		gender = RANDOM:NextNumber() > 0.5 and "male" or "female"
		name = name or generateName(gender)
		age = math.max(5, age + RANDOM:NextInteger(-3, 3))
	end
	
	local relationship = {
		id = id,
		name = name,
		type = relType,
		role = relType == "romance" and "Partner" or (relType == "friend" and "Friend" or relType),
		relationship = RANDOM:NextInteger(50, 75), -- Starting relationship level
		age = age,
		gender = gender,
		alive = true,
		metAge = state.Age,
	}
	
	state.Relationships[id] = relationship
	
	-- For romance, also set as "partner" for easy access
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
	
	-- ═══════════════════════════════════════════════════════════════════
	-- RELATIONSHIP CREATION BASED ON EVENT
	-- ═══════════════════════════════════════════════════════════════════
	
	local eventId = eventDef.id or ""
	state.Relationships = state.Relationships or {}
	
	-- Friend-making events (childhood best friend)
	if eventId == "first_best_friend" then
		if choiceIndex >= 1 and choiceIndex <= 4 then -- All positive choices make a friend
			local friend = createRelationship(state, "friend")
			outcome.feedText = outcome.feedText .. " " .. friend.name .. " became your best friend!"
			outcome.newRelationship = friend
		end
	end
	
	-- New friendship (adult)
	if eventId == "new_friendship" then
		if choiceIndex == 1 or choiceIndex == 4 then -- "Invite to hang out" or "Share something personal"
			local friend = createRelationship(state, "friend")
			outcome.feedText = outcome.feedText .. " You became friends with " .. friend.name .. "!"
			outcome.newRelationship = friend
		end
	end
	
	-- Dating app - creates a new partner
	if eventId == "dating_app" then
		if choiceIndex == 1 then -- "Met someone special"
			if not state.Relationships.partner then
				local partner = createRelationship(state, "romance")
				outcome.feedText = "You matched with " .. partner.name .. " and hit it off!"
				outcome.newRelationship = partner
				state.Flags.dating = true
				state.Flags.has_partner = true
			end
		end
	end
	
	-- High school romance
	if eventId == "high_school_romance" then
		if choiceIndex == 1 then -- "Ask them out"
			if not state.Relationships.partner then
				local partner = createRelationship(state, "romance")
				outcome.feedText = "You asked " .. partner.name .. " out and they said yes!"
				outcome.newRelationship = partner
				state.Flags.dating = true
				state.Flags.has_partner = true
			end
		end
	end
	
	-- Serious relationship - deepens existing relationship
	if eventId == "serious_relationship" then
		local partner = state.Relationships.partner
		if partner then
			if choiceIndex == 1 then -- "Commit fully"
				partner.relationship = math.min(100, (partner.relationship or 50) + 20)
				state.Flags.committed_relationship = true
				outcome.feedText = "Your relationship with " .. partner.name .. " is now rock solid!"
			elseif choiceIndex == 4 then -- "End the relationship"
				state.Relationships.partner = nil
				state.Relationships[partner.id] = nil
				state.Flags.has_partner = nil
				state.Flags.dating = nil
				state.Flags.recently_single = true
				outcome.feedText = "You broke up with " .. partner.name .. "."
			else
				partner.relationship = math.min(100, (partner.relationship or 50) + 5)
			end
		end
	end
	
	-- First crush (childhood) - just a flag, no real relationship
	if eventId == "first_crush_kid" then
		if choiceIndex == 1 or choiceIndex == 2 then
			state.Flags.had_first_crush = true
		end
	end
	
	-- Marriage proposal - requires existing partner
	if eventId == "marriage_proposal" then
		local partner = state.Relationships.partner
		if partner then
			if choiceIndex == 1 or choiceIndex == 3 then -- They said yes
				state.Flags.engaged = true
				partner.role = "Fiancé"
				outcome.feedText = partner.name .. " said YES! You're engaged!"
			elseif choiceIndex == 2 then -- They said no
				state.Relationships.partner = nil
				state.Relationships[partner.id] = nil
				state.Flags.proposal_rejected = true
				outcome.feedText = partner.name .. " said no. The relationship ended."
			end
		end
	end
	
	-- Wedding creates marriage
	if eventId == "wedding_day" then
		local partner = state.Relationships.partner
		if partner then
			state.Flags.married = true
			state.Flags.engaged = nil
			partner.role = "Spouse"
			outcome.feedText = "You married " .. partner.name .. "!"
		end
	end
	
	return outcome
end

LifeEvents.EventEngine = EventEngine

return LifeEvents
