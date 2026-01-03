--[[
	ToddlerPreschoolEvents.lua

	MASSIVE expansion for ages 3-6 with tons of variety
	Playground drama, preschool chaos, childhood memories
	Each event has multiple text variations for replayability
]]

local events = {}

-- ════════════════════════════════════════════════════════════════════════════
-- PLAYGROUND LEGENDS (Ages 3-6)
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "playground_champion",
	title = "Playground Champion",
	emoji = "👑",
	textVariants = {
		"You dominated the playground today! No one could catch you in tag!",
		"Every kid wanted to be on YOUR team at recess!",
		"You were UNSTOPPABLE on the monkey bars today!",
		"The whole playground watched as you conquered the tallest slide!",
		"You became the undisputed king/queen of four square!",
	},
	text = "You dominated the playground today!",
	question = "How did the other kids react?",
	minAge = 3, maxAge = 6,
	baseChance = 0.45, -- CRITICAL FIX: Reduced from 0.6 to prevent spam
	cooldown = 5, -- CRITICAL FIX: Increased from 4 to reduce spam
	maxOccurrences = 2, -- CRITICAL FIX: Limit to 2 times
	category = "childhood",

	choices = {
		{
			text = "They all wanted to be my friend",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				state.Flags = state.Flags or {}
				if roll <= 60 then
					state:ModifyStat("Happiness", 8)
					state.Flags.popular_kid = true
					state:AddFeed("👑 You're the cool kid! Everyone wants to play with you!")
				elseif roll <= 85 then
					state:ModifyStat("Happiness", 5)
					state:AddFeed("👑 You made some new friends today! Playground fame!")
				else
					state:ModifyStat("Happiness", 2)
					state.Flags.show_off = true
					state:AddFeed("👑 Some kids think you're a show-off now...")
				end
			end,
		},
		{
			text = "I showed off even more",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 40 then
					state:ModifyStat("Happiness", 6)
					state:ModifyStat("Health", 2)
					state:AddFeed("👑 You pulled off even cooler moves! LEGENDARY!")
				elseif roll <= 70 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("👑 You got a bit tired but everyone was impressed!")
				else
					state:ModifyStat("Happiness", -3)
					state:ModifyStat("Health", -5)
					state:AddFeed("👑 You tried too hard and fell! Scraped your knee bad...")
				end
			end,
		},
		{
			text = "I helped other kids play too",
			effects = {},
			onResolve = function(state)
				state.Flags = state.Flags or {}
				state:ModifyStat("Happiness", 6)
				state.Flags.kind_kid = true
				state:AddFeed("👑 You helped the younger kids! Teacher called you a good helper!")
			end,
		},
	},
}

events[#events + 1] = {
	id = "playground_bully_encounter",
	title = "Playground Trouble",
	emoji = "😠",
	textVariants = {
		"A bigger kid pushed you off the swings!",
		"Someone stole your spot on the slide!",
		"A mean kid knocked down your sandcastle!",
		"Someone called you a baby in front of everyone!",
		"A bigger kid took your snack at recess!",
	},
	text = "A bigger kid pushed you off the swings!",
	question = "What do you do?",
	minAge = 3, maxAge = 6,
	baseChance = 0.5,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
	category = "childhood",

	choices = {
		{
			text = "Cry and run to teacher",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 50 then
					state:ModifyStat("Happiness", -2)
					state:AddFeed("😢 Teacher made them apologize. Justice!")
				elseif roll <= 80 then
					state:ModifyStat("Happiness", -4)
					state:AddFeed("😢 Teacher said 'work it out yourselves.' Unhelpful...")
				else
					state:ModifyStat("Happiness", -6)
					state.Flags = state.Flags or {}
					state.Flags.tattletale_rep = true
					state:AddFeed("😢 Now everyone calls you a tattletale...")
				end
			end,
		},
		{
			text = "Push them back!",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				state.Flags = state.Flags or {}
				if roll <= 30 then
					state:ModifyStat("Happiness", 5)
					state.Flags.stands_up_for_self = true
					state:AddFeed("😤 They backed off! You stood up for yourself!")
				elseif roll <= 60 then
					state:ModifyStat("Happiness", -3)
					state:ModifyStat("Health", -3)
					state:AddFeed("😤 You both got in trouble and sat in time-out!")
				else
					state:ModifyStat("Health", -8)
					state:ModifyStat("Happiness", -8)
					state:AddFeed("😤 They were bigger. You got beat up...")
				end
			end,
		},
		{
			text = "Walk away and find other friends",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 70 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🚶 You found nicer kids to play with! Way better!")
				else
					state:ModifyStat("Happiness", -3)
					state:AddFeed("🚶 You felt sad the rest of recess...")
				end
			end,
		},
		{
			text = "Tell them you'll tell your dad",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 40 then
					state:ModifyStat("Happiness", 2)
					state:AddFeed("👨 They got scared and left you alone!")
				else
					state:ModifyStat("Happiness", -4)
					state:AddFeed("👨 They laughed at you... 'My dad could beat up YOUR dad!'")
				end
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- PRESCHOOL/KINDERGARTEN DRAMA (Ages 3-6)
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "first_day_crying",
	title = "First Day Tears",
	emoji = "😭",
	textVariants = {
		"It's your first day and you cried when mom/dad left!",
		"You woke up and realized: school. EVERY. DAY. Tears happened.",
		"Seeing all the strangers at school made you burst into tears!",
		"Mom/Dad tried to leave and you grabbed their leg screaming!",
		"The classroom door closed and the waterworks started!",
	},
	text = "It's your first day and you cried when mom/dad left!",
	question = "How did the day go after that?",
	minAge = 3, maxAge = 5,
	baseChance = 0.45, -- CRITICAL FIX: Reduced from 0.8 to prevent too high frequency
	oneTime = true,
	maxOccurrences = 1,
	category = "childhood",
	-- CRITICAL FIX: Block if already experienced first day
	blockedByFlags = { first_day_done = true, in_prison = true },

	choices = {
		{
			text = "Cried the whole day",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", -8)
				state.Flags = state.Flags or {}
				state.Flags.separation_anxiety = true
				state:AddFeed("😭 You cried until pickup. Teacher called you 'a handful.'")
			end,
		},
		{
			text = "Made a friend and felt better",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 70 then
					state:ModifyStat("Happiness", 5)
					state.Flags = state.Flags or {}
					state.Flags.makes_friends_easily = true
					state:AddFeed("😊 Another kid shared their crayons! You stopped crying!")
				else
					state:ModifyStat("Happiness", -2)
					state:AddFeed("😊 You tried but still felt scared all day...")
				end
			end,
		},
		{
			text = "Teacher distracted me with toys",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 3)
				state:AddFeed("🧸 Ooh, TOYS! What parents? This place is GREAT!")
			end,
		},
	},
}

events[#events + 1] = {
	id = "ran_to_class_late",
	title = "Late to Class!",
	emoji = "🏃",
	textVariants = {
		"You overslept and had to RUN to class!",
		"Mom was running late! You rushed into class after everyone else!",
		"You were playing and forgot the bell rang! Sprint time!",
		"The bus was late! You burst through the door out of breath!",
		"You got distracted by a bug and suddenly class started without you!",
	},
	text = "You overslept and had to RUN to class!",
	question = "What happened when you got there?",
	minAge = 4, maxAge = 6,
	baseChance = 0.5,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
	category = "childhood",

	choices = {
		{
			text = "Everyone stared at me",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 40 then
					state:ModifyStat("Happiness", -2)
					state:AddFeed("🏃 Embarrassing! Everyone looked! You turned red!")
				elseif roll <= 70 then
					state:ModifyStat("Happiness", -4)
					state:AddFeed("🏃 Teacher made you stand at the door until she was ready...")
				else
					state:ModifyStat("Happiness", 2)
					state:AddFeed("🏃 Your friend saved you a seat! No one cared!")
				end
			end,
		},
		{
			text = "Teacher was mad",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 50 then
					state:ModifyStat("Happiness", -5)
					state:AddFeed("😠 Teacher gave you 'the look.' Terrifying.")
				else
					state:ModifyStat("Happiness", -3)
					state:AddFeed("😠 Teacher just sighed. 'Again?' she muttered.")
				end
			end,
		},
		{
			text = "I snuck in and no one noticed",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 60 then
					state:ModifyStat("Happiness", 4)
					state:ModifyStat("Smarts", 2)
					state.Flags = state.Flags or {}
					state.Flags.sneaky_kid = true
					state:AddFeed("🤫 Ninja mode activated! No one saw a thing!")
				else
					state:ModifyStat("Happiness", -4)
					state:AddFeed("🤫 Teacher saw you. 'Nice try,' she said. Busted.")
				end
			end,
		},
	},
}

events[#events + 1] = {
	-- CRITICAL FIX: Renamed from "show_and_tell" to avoid duplicate ID with Childhood.lua
	id = "preschool_show_and_tell",
	title = "Show and Tell",
	emoji = "🎤",
	textVariants = {
		"It's show and tell day! What did you bring?",
		"Your turn to present to the class! Everyone's watching!",
		"Time to show your favorite thing to the whole class!",
		"Show and tell! You've been waiting for this ALL WEEK!",
		"The teacher calls your name. It's YOUR turn to present!",
	},
	text = "It's show and tell day! What did you bring?",
	question = "What happens?",
	minAge = 4, maxAge = 6,
	baseChance = 0.45, -- CRITICAL FIX: Reduced from 0.6 to prevent spam
	cooldown = 5, -- CRITICAL FIX: Increased from 3 to reduce spam
	maxOccurrences = 2, -- CRITICAL FIX: Limit to 2 times
	category = "childhood",

	choices = {
		{
			text = "My favorite toy",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 50 then
					state:ModifyStat("Happiness", 6)
					state:AddFeed("🧸 Everyone loved it! They all wanted to play with it!")
				elseif roll <= 80 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🧸 Some kids thought it was cool. Some were jealous.")
				else
					state:ModifyStat("Happiness", -5)
					state:AddFeed("🧸 A kid said your toy was 'for babies.' You cried.")
				end
			end,
		},
		{
			text = "A cool bug I found",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 40 then
					state:ModifyStat("Happiness", 8)
					state.Flags = state.Flags or {}
					state.Flags.nature_kid = true
					state:AddFeed("🐛 The boys thought you were SO COOL! Bug expert!")
				elseif roll <= 70 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🐛 Some kids screamed. Others were fascinated!")
				else
					state:ModifyStat("Happiness", -6)
					state:AddFeed("🐛 It escaped! Teacher screamed! Chaos erupted!")
				end
			end,
		},
		{
			text = "I forgot to bring something",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 30 then
					state:ModifyStat("Happiness", -6)
					state:ModifyStat("Smarts", -2)
					state:AddFeed("😰 You stood there silent. Everyone stared. Mortifying.")
				elseif roll <= 60 then
					state:ModifyStat("Happiness", -3)
					state:AddFeed("😰 You made something up. Not sure anyone believed you...")
				else
					state:ModifyStat("Happiness", 2)
					state:ModifyStat("Smarts", 3)
					state:AddFeed("😰 You told a story instead! Teacher was impressed!")
				end
			end,
		},
		{
			text = "A drawing I made",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 60 then
					state:ModifyStat("Happiness", 5)
					state.Flags = state.Flags or {}
					state.Flags.artistic_kid = true
					state:AddFeed("🎨 Teacher put it on the wall! You're an artist!")
				else
					state:ModifyStat("Happiness", 2)
					state:AddFeed("🎨 A kid said it didn't look like what you said it was...")
				end
			end,
		},
	},
}

events[#events + 1] = {
	id = "naptime_rebellion",
	title = "Naptime Trouble",
	emoji = "😴",
	textVariants = {
		"It's naptime but you're NOT tired!",
		"Teacher says lie down. Your body says RUN AROUND!",
		"Everyone's sleeping but you're wide awake!",
		"Naptime is SO boring! You want to PLAY!",
		"You're supposed to sleep but there's SO much to do!",
	},
	text = "It's naptime but you're NOT tired!",
	question = "What do you do?",
	minAge = 3, maxAge = 5,
	baseChance = 0.5, -- CRITICAL FIX: Reduced from 0.7 to prevent spam
	cooldown = 6, -- CRITICAL FIX: Increased from 4 to reduce spam
	maxOccurrences = 2, -- CRITICAL FIX: Only happens twice per childhood
	category = "childhood",

	choices = {
		{
			text = "Pretend to sleep",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 60 then
					state:ModifyStat("Happiness", 2)
					state:AddFeed("😴 You stared at the ceiling for an hour. Boring but safe.")
				else
					state:ModifyStat("Happiness", 3)
					state:ModifyStat("Health", 3)
					state:AddFeed("😴 You actually fell asleep! Woke up feeling great!")
				end
			end,
		},
		{
			text = "Whisper with friends",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 40 then
					state:ModifyStat("Happiness", 5)
					state:AddFeed("🤫 You and your friend giggled quietly the whole time!")
				elseif roll <= 70 then
					state:ModifyStat("Happiness", -2)
					state:AddFeed("🤫 Teacher caught you! 'SHHHH!' Scary.")
				else
					state:ModifyStat("Happiness", -5)
					state:AddFeed("🤫 You both got moved to opposite corners!")
				end
			end,
		},
		{
			text = "Sneak to the toys",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 30 then
					state:ModifyStat("Happiness", 8)
					state.Flags = state.Flags or {}
					state.Flags.sneaky_kid = true
					state:AddFeed("🎮 You played for 20 minutes before anyone noticed!")
				elseif roll <= 60 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🎮 Got a few minutes of play before being caught!")
				else
					state:ModifyStat("Happiness", -6)
					state:AddFeed("🎮 Teacher caught you immediately! Extra long naptime tomorrow!")
				end
			end,
		},
		{
			text = "Cause chaos",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 4)
				state:ModifyStat("Health", -2)
				state.Flags = state.Flags or {}
				state.Flags.troublemaker = true
				state:AddFeed("😈 You woke everyone up! Teacher called your parents. Worth it.")
			end,
		},
	},
}

events[#events + 1] = {
	id = "potty_accident",
	title = "Oops!",
	emoji = "💦",
	textVariants = {
		"You had an accident at school...",
		"You waited too long to go to the bathroom...",
		"You were playing and forgot you had to go...",
		"The bathroom was too far away...",
		"You raised your hand but teacher didn't see you in time...",
	},
	text = "You had an accident at school...",
	question = "What happened next?",
	minAge = 3, maxAge = 5,
	baseChance = 0.4,
	cooldown = 3,
	category = "childhood",

	choices = {
		{
			text = "Everyone saw",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 30 then
					state:ModifyStat("Happiness", -10)
					state.Flags = state.Flags or {}
					state.Flags.embarrassing_memory = true
					state:AddFeed("💦 Kids laughed. You'll remember this FOREVER.")
				elseif roll <= 70 then
					state:ModifyStat("Happiness", -6)
					state:AddFeed("💦 It was embarrassing but everyone forgot by tomorrow.")
				else
					state:ModifyStat("Happiness", -3)
					state:AddFeed("💦 A nice kid said 'it's okay, it happens to everyone.'")
				end
			end,
		},
		{
			text = "Teacher handled it quietly",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", -3)
				state:AddFeed("💦 Teacher was nice about it. Got new clothes. Not too bad.")
			end,
		},
		{
			text = "I blamed someone else",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 20 then
					state:ModifyStat("Happiness", 2)
					state.Flags = state.Flags or {}
					state.Flags.good_liar = true
					state:AddFeed("🤥 They believed you! Someone else got blamed!")
				else
					state:ModifyStat("Happiness", -8)
					state:AddFeed("🤥 No one believed you. Made it worse.")
				end
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- FRIENDSHIP DRAMA (Ages 3-6)
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "best_friend_fight",
	title = "Best Friend Fight",
	emoji = "💔",
	textVariants = {
		"Your best friend said they don't want to be your friend anymore!",
		"Your best friend played with someone else today!",
		"You and your best friend fought over a toy!",
		"Your best friend said they have a NEW best friend!",
		"Your best friend didn't save you a seat at lunch!",
	},
	text = "Your best friend said they don't want to be your friend anymore!",
	question = "What do you do?",
	minAge = 4, maxAge = 6,
	baseChance = 0.5,
	cooldown = 3,
	category = "childhood",

	choices = {
		{
			text = "Cry about it",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 50 then
					state:ModifyStat("Happiness", -6)
					state:AddFeed("💔 You cried all day. They apologized at pickup time.")
				else
					state:ModifyStat("Happiness", -8)
					state:AddFeed("💔 You cried. They didn't care. Ouch.")
				end
			end,
		},
		{
			text = "Find a new best friend",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 60 then
					state:ModifyStat("Happiness", 4)
					state:AddFeed("👫 You made a NEW friend! Better than the old one!")
				else
					state:ModifyStat("Happiness", -3)
					state:AddFeed("👫 It's hard to make new friends... you miss them.")
				end
			end,
		},
		{
			text = "Tell teacher",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 40 then
					state:ModifyStat("Happiness", 2)
					state:AddFeed("👩‍🏫 Teacher made them play with you. Forced friendship!")
				else
					state:ModifyStat("Happiness", -4)
					state:AddFeed("👩‍🏫 Teacher said 'you can't force friendship.' Unhelpful.")
				end
			end,
		},
		{
			text = "Say 'I didn't want to be YOUR friend anyway!'",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 30 then
					state:ModifyStat("Happiness", 3)
					state.Flags = state.Flags or {}
					state.Flags.tough_kid = true
					state:AddFeed("😤 Power move! They looked hurt. You walked away cool.")
				else
					state:ModifyStat("Happiness", -5)
					state:AddFeed("😤 They said 'fine!' and you both cried later.")
				end
			end,
		},
	},
}

events[#events + 1] = {
	id = "sharing_is_hard",
	title = "Sharing Struggle",
	emoji = "🤲",
	textVariants = {
		"Another kid wants to play with YOUR toy!",
		"Teacher says you HAVE to share. But you don't WANT to!",
		"Someone's turn with the bike is over but they won't give it up!",
		"Everyone wants the red crayon. There's only ONE.",
		"The new kid wants to play YOUR favorite thing!",
	},
	text = "Another kid wants to play with YOUR toy!",
	question = "Do you share?",
	minAge = 3, maxAge = 5,
	baseChance = 0.5, -- CRITICAL FIX: Reduced from 0.7 to prevent spam
	cooldown = 5, -- CRITICAL FIX: Increased from 4 to reduce spam
	category = "childhood",

	choices = {
		{
			text = "Share nicely",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 70 then
					state:ModifyStat("Happiness", 5)
					state.Flags = state.Flags or {}
					state.Flags.good_sharer = true
					state:AddFeed("🤝 You shared! They were so happy! Teacher gave you a star!")
				else
					state:ModifyStat("Happiness", 1)
					state:AddFeed("🤝 You shared but they broke it... great.")
				end
			end,
		},
		{
			text = "NO! IT'S MINE!",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 30 then
					state:ModifyStat("Happiness", 4)
					state:AddFeed("😤 You kept it! No one messes with YOUR stuff!")
				elseif roll <= 60 then
					state:ModifyStat("Happiness", -3)
					state:AddFeed("😤 Teacher took it away from BOTH of you. Fair? NO.")
				else
					state:ModifyStat("Happiness", -6)
					state.Flags = state.Flags or {}
					state.Flags.selfish_kid = true
					state:AddFeed("😤 You got in trouble. Parents were 'disappointed.'")
				end
			end,
		},
		{
			text = "Hide the toy",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 50 then
					state:ModifyStat("Happiness", 3)
					state.Flags = state.Flags or {}
					state.Flags.sneaky_kid = true
					state:AddFeed("🙈 You hid it! They can't share what they can't find!")
				else
					state:ModifyStat("Happiness", -4)
					state:AddFeed("🙈 They saw you hide it! Tattled to teacher!")
				end
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- IMAGINATION & PRETEND PLAY (Ages 3-6)
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	-- CRITICAL FIX: Renamed from "imaginary_friend" to avoid duplicate ID with Childhood.lua
	id = "toddler_imaginary_friend",
	title = "Imaginary Friend",
	emoji = "👻",
	textVariants = {
		"You made up an imaginary friend!",
		"You started talking to someone only you can see!",
		"Your new best friend is... invisible!",
		"You've been having conversations with 'Mr. Whispers'!",
		"Mom asks who you're talking to. 'My friend!' you say.",
	},
	text = "You made up an imaginary friend!",
	question = "What's your imaginary friend like?",
	minAge = 3, maxAge = 6,
	baseChance = 0.4,
	oneTime = true,
	category = "childhood",

	choices = {
		{
			text = "A friendly helper",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 5)
				state:ModifyStat("Smarts", 3)
				state.Flags = state.Flags or {}
				state.Flags.had_imaginary_friend = true
				state:AddFeed("👻 Your imaginary friend helps you be brave! Great imagination!")
			end,
		},
		{
			text = "A mischievous troublemaker",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				state.Flags = state.Flags or {}
				state.Flags.had_imaginary_friend = true
				if roll <= 50 then
					state:ModifyStat("Happiness", 6)
					state:AddFeed("👻 Your imaginary friend gets blamed for everything! Genius!")
				else
					state:ModifyStat("Happiness", 2)
					state:AddFeed("👻 Parents don't believe 'they did it.' Darn.")
				end
			end,
		},
		{
			text = "A scary shadow creature",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				state.Flags = state.Flags or {}
				state.Flags.had_imaginary_friend = true
				if roll <= 30 then
					state:ModifyStat("Happiness", -4)
					state.Flags.childhood_fears = true
					state:AddFeed("👻 Actually kind of scared yourself. Mom's worried...")
				else
					state:ModifyStat("Happiness", 2)
					state:AddFeed("👻 You made them scary so THEY protect YOU! Smart!")
				end
			end,
		},
	},
}

events[#events + 1] = {
	id = "superhero_phase",
	title = "Superhero Dreams",
	emoji = "🦸",
	textVariants = {
		"You've decided you ARE a superhero!",
		"Cape on, you're ready to save the world!",
		"You've been running around with your arms out flying!",
		"Everyone must call you by your superhero name now!",
		"You tried to use your powers on your sibling!",
	},
	text = "You've decided you ARE a superhero!",
	question = "What heroic thing do you do?",
	minAge = 3, maxAge = 6,
	baseChance = 0.45,
	cooldown = 3,
	category = "childhood",

	choices = {
		{
			text = "Try to fly off the couch",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 50 then
					state:ModifyStat("Happiness", 5)
					state:AddFeed("🦸 SUPER LANDING! Pillows everywhere but you're FINE!")
				elseif roll <= 80 then
					state:ModifyStat("Health", -3)
					state:ModifyStat("Happiness", 2)
					state:AddFeed("🦸 Bit of a rough landing... but heroes don't cry!")
				else
					state:ModifyStat("Health", -8)
					state:ModifyStat("Happiness", -5)
					state:AddFeed("🦸 OW! Okay, heroes CAN cry sometimes! Bandages needed!")
				end
			end,
		},
		{
			text = "Save the cat",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 40 then
					state:ModifyStat("Happiness", 6)
					state:AddFeed("🐱 The cat didn't need saving but appreciated the attention!")
				else
					state:ModifyStat("Health", -2)
					state:AddFeed("🐱 The cat scratched you. Ungrateful villain!")
				end
			end,
		},
		{
			text = "Fight the bad guys (stuffed animals)",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 8)
				state:ModifyStat("Health", 2)
				state:AddFeed("🧸 VICTORY! The stuffed animal army has been defeated! The world is safe!")
			end,
		},
		{
			text = "Wear the cape to school",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 60 then
					state:ModifyStat("Happiness", 7)
					state.Flags = state.Flags or {}
					state.Flags.confident_kid = true
					state:AddFeed("🦸 Other kids thought it was SO COOL! You're a legend!")
				else
					state:ModifyStat("Happiness", -3)
					state:AddFeed("🦸 Some kids laughed... but you know the truth!")
				end
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- FOOD DRAMA (Ages 3-6)
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "lunchbox_disaster",
	title = "Lunch Disaster",
	emoji = "🍱",
	textVariants = {
		"You opened your lunchbox and... YUCK!",
		"Mom packed something GROSS for lunch!",
		"Your sandwich got all smooshed!",
		"Someone else's lunch looks WAY better than yours!",
		"You forgot your lunchbox at home!",
	},
	text = "You opened your lunchbox and... YUCK!",
	question = "What do you do about lunch?",
	minAge = 4, maxAge = 6,
	baseChance = 0.5,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
	category = "childhood",

	choices = {
		{
			text = "Eat it anyway",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 60 then
					state:ModifyStat("Happiness", 1)
					state:ModifyStat("Health", 2)
					state:AddFeed("🍱 It wasn't THAT bad... you survived.")
				else
					state:ModifyStat("Happiness", -3)
					state:AddFeed("🍱 You gagged the whole time. Traumatic.")
				end
			end,
		},
		{
			text = "Trade with another kid",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 50 then
					state:ModifyStat("Happiness", 6)
					state:AddFeed("🔄 SCORE! Got fruit snacks for your weird sandwich!")
				elseif roll <= 80 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🔄 Fair trade. Both happy.")
				else
					state:ModifyStat("Happiness", -2)
					state:AddFeed("🔄 No one wanted to trade... you ate alone.")
				end
			end,
		},
		{
			text = "Throw it away secretly",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 60 then
					state:ModifyStat("Happiness", 2)
					state:ModifyStat("Health", -2)
					state:AddFeed("🗑️ Gone! Mom will never know. But hungry later...")
				else
					state:ModifyStat("Happiness", -5)
					state:AddFeed("🗑️ Teacher SAW. Called your mom. Big trouble.")
				end
			end,
		},
		{
			text = "Cry until teacher helps",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 50 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("😢 Teacher gave you crackers from the emergency stash!")
				else
					state:ModifyStat("Happiness", -3)
					state:AddFeed("😢 Teacher said 'that's what you have.' Cold.")
				end
			end,
		},
	},
}

events[#events + 1] = {
	id = "snack_time_drama",
	title = "Snack Time",
	emoji = "🍪",
	textVariants = {
		"Someone brought the BEST snack to share!",
		"It's your turn to bring snack for the class!",
		"Another kid's snack looks SO much better!",
		"You got TWO snacks somehow!",
		"There's one cookie left and two kids want it!",
	},
	text = "Someone brought the BEST snack to share!",
	question = "What happens?",
	minAge = 3, maxAge = 6,
	baseChance = 0.45,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
	category = "childhood",

	choices = {
		{
			text = "I got the biggest piece!",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 6)
				state:AddFeed("🍪 BEST DAY EVER! You got the corner brownie!")
			end,
		},
		{
			text = "I got the smallest piece",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", -4)
				state:AddFeed("🍪 Unfair! Life is unfair! You complained but it didn't help.")
			end,
		},
		{
			text = "I shared mine with a friend",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 4)
				state.Flags = state.Flags or {}
				state.Flags.generous_kid = true
				state:AddFeed("🍪 You split your snack! Best friends FOREVER now!")
			end,
		},
		{
			text = "I ate it too fast and felt sick",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", -2)
				state:ModifyStat("Health", -3)
				state:AddFeed("🤢 Ate too fast! Tummy ache! But worth it!")
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- TANTRUMS & MELTDOWNS (Ages 3-5)
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "public_tantrum",
	title = "Meltdown!",
	emoji = "😤",
	textVariants = {
		"You wanted something at the store and mom said NO!",
		"You had to leave the playground and you were NOT ready!",
		"Your sibling got something and you DIDN'T!",
		"Bedtime was announced. UNACCEPTABLE.",
		"The TV was turned off in the middle of your show!",
	},
	text = "You wanted something at the store and mom said NO!",
	question = "How bad was the tantrum?",
	minAge = 3, maxAge = 5,
	baseChance = 0.45,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
	category = "childhood",

	choices = {
		{
			text = "FULL MELTDOWN",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 30 then
					state:ModifyStat("Happiness", 5)
					state.Flags = state.Flags or {}
					state.Flags.tantrum_wins = true
					state:AddFeed("😤 You screamed SO loud they gave in! It works!")
				elseif roll <= 70 then
					state:ModifyStat("Happiness", -6)
					state:AddFeed("😤 Screamed for 20 minutes. Still didn't get it. Exhausted.")
				else
					state:ModifyStat("Happiness", -10)
					state:AddFeed("😤 Got carried out of the store. Everyone stared. Lost privileges.")
				end
			end,
		},
		{
			text = "Cried quietly",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 50 then
					state:ModifyStat("Happiness", -3)
					state:AddFeed("😢 Sad but dignified. Maybe next time...")
				else
					state:ModifyStat("Happiness", 2)
					state:AddFeed("😢 Parents felt bad. Got ice cream later!")
				end
			end,
		},
		{
			text = "Accepted it like a champ",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 4)
				state.Flags = state.Flags or {}
				state.Flags.mature_for_age = true
				state:AddFeed("😊 You said 'okay.' Parents were SHOCKED. Got extra praise!")
			end,
		},
		{
			text = "Held breath until face turned blue",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 40 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("😤 Parents freaked out! You got what you wanted!")
				else
					state:ModifyStat("Happiness", -4)
					state:ModifyStat("Health", -2)
					state:AddFeed("😤 You passed out briefly. Doctor visit. Scary for everyone.")
				end
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- LEARNING & DISCOVERY (Ages 3-6)
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "learning_abcs",
	title = "Learning Letters",
	emoji = "📚",
	textVariants = {
		"Teacher is teaching the ABCs!",
		"You're learning to write your name!",
		"Time to learn letters and sounds!",
		"The alphabet song is stuck in your head!",
		"You recognized a letter on a sign!",
	},
	text = "Teacher is teaching the ABCs!",
	question = "How's learning going?",
	minAge = 3, maxAge = 5,
	baseChance = 0.45,
	oneTime = true,
	category = "childhood",

	choices = {
		{
			text = "I got it immediately!",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Smarts", 5)
				state:ModifyStat("Happiness", 5)
				state.Flags = state.Flags or {}
				state.Flags.quick_learner = true
				state:AddFeed("📚 A-B-C-D-E-F-G! You're a genius! First to memorize it!")
			end,
		},
		{
			text = "It's confusing but I'm trying",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 70 then
					state:ModifyStat("Smarts", 3)
					state:ModifyStat("Happiness", 3)
					state:AddFeed("📚 LMNOP is hard but you're getting there!")
				else
					state:ModifyStat("Smarts", 1)
					state:AddFeed("📚 Why are there SO MANY letters?!")
				end
			end,
		},
		{
			text = "I'd rather play",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Smarts", -2)
				state:ModifyStat("Happiness", 4)
				state.Flags = state.Flags or {}
				state.Flags.easily_distracted = true
				state:AddFeed("📚 Letters are BORING. The toy corner is RIGHT THERE.")
			end,
		},
	},
}

events[#events + 1] = {
	id = "counting_fingers",
	title = "Learning Numbers",
	emoji = "🔢",
	textVariants = {
		"You're learning to count to 10!",
		"Teacher asks: how many fingers do you have?",
		"1, 2, 3... what comes next?",
		"You're learning that numbers are EVERYWHERE!",
		"Time to count the snacks!",
	},
	text = "You're learning to count to 10!",
	question = "How high can you count?",
	minAge = 3, maxAge = 5,
	baseChance = 0.45,
	oneTime = true,
	category = "childhood",

	choices = {
		{
			text = "All the way to 100!",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Smarts", 6)
				state:ModifyStat("Happiness", 5)
				state.Flags = state.Flags or {}
				state.Flags.math_whiz = true
				state:AddFeed("🔢 ONE HUNDRED! Teacher was impressed! Parents bragged!")
			end,
		},
		{
			text = "1, 2, 3... um... 7?",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Smarts", 2)
				state:AddFeed("🔢 Numbers are hard! 4, 5, 6 keep escaping your brain!")
			end,
		},
		{
			text = "I can count my snacks accurately",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Smarts", 4)
				state:ModifyStat("Happiness", 3)
				state:AddFeed("🔢 Practical math! 1 cookie, 2 cookies, 3 cookies... MINE!")
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- ARTS & CRAFTS (Ages 3-6)
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "art_project",
	title = "Art Time!",
	emoji = "🎨",
	textVariants = {
		"Time to make art! The possibilities are endless!",
		"You've got crayons, glitter, and GLUE!",
		"Art project day! What will you create?",
		"Teacher hands out paper and says 'be creative!'",
		"You're making a masterpiece!",
	},
	text = "Time to make art! The possibilities are endless!",
	question = "What do you create?",
	minAge = 3, maxAge = 6,
	baseChance = 0.45,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
	category = "childhood",

	choices = {
		{
			text = "A beautiful drawing of my family",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 60 then
					state:ModifyStat("Happiness", 6)
					state.Flags = state.Flags or {}
					state.Flags.artistic_kid = true
					state:AddFeed("🎨 Mom put it on the fridge! FAMOUS ARTIST!")
				else
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🎨 Mom asked 'which one is me?' ...you weren't sure either.")
				end
			end,
		},
		{
			text = "Glitter EVERYWHERE",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 8)
				state:AddFeed("✨ SPARKLES! You, the table, the floor, other kids... GLITTER FOR ALL!")
			end,
		},
		{
			text = "Ate the glue",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 70 then
					state:ModifyStat("Happiness", 2)
					state:AddFeed("🧴 It tasted weird but you survived. Classic choice.")
				else
					state:ModifyStat("Health", -3)
					state:AddFeed("🧴 Tummy ache. Worth it? Maybe.")
				end
			end,
		},
		{
			text = "Finger painting chaos",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 7)
				state.Flags = state.Flags or {}
				state.Flags.messy_artist = true
				state:AddFeed("🖐️ PAINT EVERYWHERE! Your hands are still slightly blue days later!")
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- BIRTHDAY & SPECIAL DAYS (Ages 3-6)
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	-- CRITICAL FIX: Renamed to avoid ID collision with Childhood.lua birthday_party
	id = "toddler_birthday_party",
	title = "Birthday Party!",
	emoji = "🎂",
	textVariants = {
		"It's YOUR birthday! Party time!",
		"Everyone sang happy birthday TO YOU!",
		"You got to wear the birthday crown at school!",
		"Birthday cupcakes for the whole class!",
		"PRESENTS! CAKE! YOUR DAY!",
	},
	text = "It's YOUR birthday! Party time!",
	question = "How was your special day?",
	minAge = 3, maxAge = 6,
	baseChance = 0.45, -- CRITICAL FIX: Reduced to prevent spam
	cooldown = 12, -- CRITICAL FIX: Increased - birthday parties aren't every year
	category = "childhood",
	tags = { "birthday", "party", "toddler" },

	choices = {
		{
			text = "Best day EVER!",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 10)
				state:AddFeed("🎂 BEST DAY EVER! Cake, presents, everyone sang! You're OLDER now!")
			end,
		},
		{
			text = "I cried when the cake came out",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 50 then
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🎂 Happy tears! So much attention! Overwhelmed but loved!")
				else
					state:ModifyStat("Happiness", -2)
					state:AddFeed("🎂 Too much attention! You hid under the table briefly.")
				end
			end,
		},
		{
			text = "Didn't get the present I wanted",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 40 then
					state:ModifyStat("Happiness", 2)
					state:AddFeed("🎁 Wrong toy BUT... the other stuff was still pretty good.")
				else
					state:ModifyStat("Happiness", -5)
					state:AddFeed("🎁 SPECIFICALLY asked for it! They got the WRONG ONE!")
				end
			end,
		},
		{
			text = "Got sick from too much cake",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 4)
				state:ModifyStat("Health", -4)
				state:AddFeed("🤢 SO MUCH CAKE! Tummy hurts but NO REGRETS!")
			end,
		},
	},
}

events[#events + 1] = {
	id = "classmate_birthday",
	title = "Someone's Birthday",
	emoji = "🎈",
	textVariants = {
		"It's another kid's birthday today!",
		"Someone brought cupcakes for their birthday!",
		"Birthday party invitation - are you invited?",
		"The class is singing happy birthday... but not to you.",
		"Another kid is wearing the birthday crown today!",
	},
	text = "It's another kid's birthday today!",
	question = "How do you feel?",
	minAge = 3, maxAge = 6,
	baseChance = 0.5,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
	category = "childhood",

	choices = {
		{
			text = "Happy for them!",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", 4)
				state:AddFeed("🎈 Free cupcake! You sang the loudest! Good friend!")
			end,
		},
		{
			text = "Jealous it's not MY birthday",
			effects = {},
			onResolve = function(state)
				state:ModifyStat("Happiness", -3)
				state:AddFeed("🎈 Why is it THEIR day? When is it MY turn?!")
			end,
		},
		{
			text = "I wasn't invited to their party",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 30 then
					state:ModifyStat("Happiness", -8)
					state:AddFeed("💔 Everyone got an invitation except you... it hurts.")
				else
					state:ModifyStat("Happiness", -4)
					state:AddFeed("💔 Not invited. Maybe they could only have a few kids?")
				end
			end,
		},
		{
			text = "Stole extra cupcake when no one was looking",
			effects = {},
			onResolve = function(state)
				local roll = math.random(100)
				if roll <= 50 then
					state:ModifyStat("Happiness", 5)
					state:AddFeed("🧁 Snuck a second one! Delicious crime!")
				else
					state:ModifyStat("Happiness", -4)
					state:AddFeed("🧁 Got caught! Had to apologize to the birthday kid!")
				end
			end,
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: NEW EARLY CHILDHOOD EVENTS FOR VARIETY
-- User complaint: "first age 1-10 most stuff is always the same"
-- Adding more unique personality-forming events
-- ════════════════════════════════════════════════════════════════════════════

events[#events + 1] = {
	id = "toddler_first_drawing",
	title = "Your First Masterpiece!",
	emoji = "🎨",
	textVariants = {
		"You drew your first real picture today!",
		"You made art that your parents actually recognized!",
		"Your crayon creation is going on the fridge!",
	},
	text = "You drew your first real picture today!",
	question = "What did you draw?",
	minAge = 3, maxAge = 5,
	baseChance = 0.35,
	cooldown = 6,
	oneTime = true,
	category = "childhood",

	choices = {
		{
			text = "My family",
			effects = { Happiness = 8 },
			setFlags = { family_oriented = true, draws_family = true },
			feedText = "🎨 Mom and Dad loved it! It's going on the fridge!",
		},
		{
			text = "A dinosaur/monster",
			effects = { Happiness = 6, Smarts = 2 },
			setFlags = { creative_imagination = true },
			feedText = "🎨 Your imagination is WILD! What a creative kid!",
		},
		{
			text = "A superhero (me!)",
			effects = { Happiness = 7 },
			setFlags = { confident_kid = true, hero_complex = true },
			feedText = "🎨 You're the HERO of your own story!",
		},
		{
			text = "Just scribbles (abstract art)",
			effects = { Happiness = 4, Smarts = 3 },
			setFlags = { abstract_thinker = true },
			feedText = "🎨 'It's ABSTRACT!' you insist. Future artist?",
		},
	},
}

events[#events + 1] = {
	id = "toddler_favorite_food",
	title = "Food Discovery!",
	emoji = "🍕",
	textVariants = {
		"You discovered a new favorite food!",
		"You found the BEST food EVER (in your opinion)!",
		"This is now the only thing you want to eat!",
	},
	text = "You discovered a new favorite food!",
	question = "What became your favorite?",
	minAge = 2, maxAge = 5,
	baseChance = 0.4,
	cooldown = 5,
	oneTime = true,
	category = "childhood",

	choices = {
		{
			text = "Pizza - the perfect food!",
			effects = { Happiness = 6 },
			setFlags = { pizza_lover = true },
			feedText = "🍕 Pizza is now requested at EVERY meal!",
		},
		{
			text = "Chicken nuggets ONLY",
			effects = { Happiness = 5 },
			setFlags = { nugget_kid = true, picky_eater = true },
			feedText = "🍗 If it's not shaped like a nugget, you won't eat it!",
		},
		{
			text = "Healthy veggies (surprising everyone!)",
			effects = { Happiness = 4, Health = 3 },
			setFlags = { veggie_kid = true, healthy_eater = true },
			feedText = "🥦 You actually LIKE vegetables! Parents are thrilled!",
		},
		{
			text = "Sweet treats and desserts",
			effects = { Happiness = 7 },
			setFlags = { sweet_tooth = true },
			feedText = "🍭 Anything sweet is your jam! Sugar rush incoming!",
		},
	},
}

events[#events + 1] = {
	id = "toddler_animal_encounter",
	title = "Meeting an Animal!",
	emoji = "🐕",
	textVariants = {
		"You met a friendly dog at the park!",
		"A cat wandered up to you!",
		"You saw a cool animal up close!",
	},
	text = "You met a friendly animal today!",
	question = "How did you react?",
	minAge = 2, maxAge = 5,
	baseChance = 0.45,
	cooldown = 4,
	category = "childhood",

	choices = {
		{
			text = "I LOVED it! New best friend!",
			effects = { Happiness = 10 },
			setFlags = { animal_lover = true, wants_pet = true },
			feedText = "🐕 You begged your parents for a pet the whole way home!",
		},
		{
			text = "Curious but careful",
			effects = { Happiness = 5, Smarts = 2 },
			setFlags = { cautious_kid = true },
			feedText = "🐕 You watched from a safe distance. Smart kid!",
		},
		{
			text = "SCARED! Too big/fast/loud!",
			effects = { Happiness = -3 },
			setFlags = { afraid_of_animals = true },
			feedText = "😨 You hid behind your parent's legs. Maybe next time!",
		},
	},
}

events[#events + 1] = {
	id = "toddler_first_music",
	title = "Musical Discovery!",
	emoji = "🎵",
	text = "You discovered you really like music!",
	question = "What kind of music moves you?",
	minAge = 3, maxAge = 6,
	baseChance = 0.35,
	cooldown = 8,
	oneTime = true,
	category = "childhood",

	choices = {
		{
			text = "Dancing music - can't sit still!",
			effects = { Happiness = 8, Health = 2 },
			-- CRITICAL FIX: This sets flags for future entertainment career!
			setFlags = { loves_dancing = true, musical_kid = true, natural_dancer = true },
			feedText = "🎵 You dance whenever music plays! Future star?",
		},
		{
			text = "Singing along - learning all the words!",
			effects = { Happiness = 7 },
			setFlags = { loves_singing = true, musical_kid = true, gifted_voice = true },
			feedText = "🎵 You memorize every song! Your voice is getting noticed!",
		},
		{
			text = "Making noise on pots and pans - DRUMS!",
			effects = { Happiness = 6 },
			setFlags = { loves_drums = true, musical_kid = true, loud_kid = true },
			feedText = "🥁 BANG BANG BANG! Future drummer (parents' eardrums: RIP)!",
		},
		{
			text = "Quiet music - it helps me think",
			effects = { Happiness = 4, Smarts = 3 },
			setFlags = { calm_listener = true, thoughtful_kid = true },
			feedText = "🎵 You like peaceful music. An old soul in a young body!",
		},
	},
}

events[#events + 1] = {
	id = "child_building_blocks",
	title = "Master Builder!",
	emoji = "🧱",
	text = "You love building things with blocks, LEGO, or anything stackable!",
	question = "What do you build?",
	minAge = 3, maxAge = 7,
	baseChance = 0.4,
	cooldown = 6,
	category = "childhood",

	choices = {
		{
			text = "The BIGGEST tower ever!",
			effects = { Happiness = 7 },
			setFlags = { competitive_builder = true },
			feedText = "🧱 You built it SO tall! Then... CRASH! Build again!",
		},
		{
			text = "A house for my toys",
			effects = { Happiness = 6, Smarts = 2 },
			-- CRITICAL FIX: Wire to future architecture/construction interest!
			setFlags = { architect_interest = true, creative_builder = true, likes_building = true },
			feedText = "🧱 Your toys have the nicest house! Future architect?",
		},
		{
			text = "A spaceship to fly away!",
			effects = { Happiness = 7, Smarts = 3 },
			setFlags = { space_dreamer = true, science_interest = true },
			feedText = "🚀 Ready for liftoff! Your imagination is out of this world!",
		},
		{
			text = "Following the instructions perfectly",
			effects = { Smarts = 5 },
			setFlags = { detail_oriented = true, follows_rules = true },
			feedText = "🧱 You followed EVERY step! Precision is your thing!",
		},
	},
}

events[#events + 1] = {
	id = "child_role_playing",
	title = "Playing Pretend!",
	emoji = "🎭",
	text = "You love playing pretend and acting out stories!",
	question = "What do you pretend to be?",
	minAge = 3, maxAge = 7,
	baseChance = 0.45,
	cooldown = 5,
	category = "childhood",

	choices = {
		{
			text = "A doctor helping sick patients",
			effects = { Happiness = 6, Smarts = 2 },
			-- CRITICAL FIX: Wire to future medical career interest!
			setFlags = { plays_doctor = true, medical_interest = true, empathetic = true, caring_nature = true },
			feedText = "🩺 'The doctor will see you now!' You bandaged all your stuffed animals!",
		},
		{
			text = "A superhero saving the day!",
			effects = { Happiness = 8, Health = 2 },
			setFlags = { hero_complex = true, brave = true, active_imagination = true },
			feedText = "🦸 Cape on! Bad guys beware! You saved the world (living room)!",
		},
		{
			text = "A teacher with stuffed animal students",
			effects = { Happiness = 5, Smarts = 4 },
			setFlags = { plays_teacher = true, leadership_interest = true, likes_learning = true },
			feedText = "📚 Class is in session! Your teddy bears are learning so much!",
		},
		{
			text = "A chef cooking delicious food",
			effects = { Happiness = 6 },
			setFlags = { plays_chef = true, cooking_interest = true },
			feedText = "👨‍🍳 'Order up!' Your mud pies and leaf salads are 5-star!",
		},
	},
},

-- ══════════════════════════════════════════════════════════════════════════════
-- MASSIVE EXPANSION: 50+ NEW TODDLER/PRESCHOOL EVENTS
-- Added for variety and replayability
-- ══════════════════════════════════════════════════════════════════════════════

{
	id = "toddler_first_friend",
	title = "First Friend!",
	emoji = "🤝",
	textVariants = {
		"At the playground, another toddler approaches you!",
		"You meet a kid your age at daycare!",
		"A neighbor brings their child over for a playdate!",
		"At the park, you notice a friendly face!",
	},
	text = "At the playground, another toddler approaches you!",
	question = "How do you react?",
	minAge = 2, maxAge = 4,
	baseChance = 0.45,
	cooldown = 4,
	oneTime = true,
	category = "social",
	tags = { "toddler", "friends", "social" },
	blockedByFlags = { has_first_friend = true },
	
	choices = {
		{
			text = "🤗 Share your toys!",
			effects = { Happiness = 8 },
			setFlags = { has_first_friend = true, generous = true, social_butterfly = true },
			feedText = "🤝 You made your first friend by sharing! The start of a beautiful friendship!",
		},
		{
			text = "👀 Watch them shyly",
			effects = { Happiness = 4 },
			setFlags = { has_first_friend = true, shy_kid = true },
			feedText = "🤝 After some shy glances, you warmed up and made a new friend!",
		},
		{
			text = "🏃 Run and play chase!",
			effects = { Happiness = 6, Health = 2 },
			setFlags = { has_first_friend = true, active_kid = true },
			feedText = "🤝 You bonded through energetic play! Tag, you're friends now!",
		},
	},
},

{
	id = "toddler_tantrum",
	title = "Big Feelings!",
	emoji = "😤",
	textVariants = {
		"Something doesn't go your way and BIG feelings bubble up!",
		"You're overwhelmed and don't know how to handle it!",
		"The emotions are too much to contain!",
		"You feel frustrated and it's all too much!",
	},
	text = "Something doesn't go your way and BIG feelings bubble up!",
	question = "How do you express yourself?",
	minAge = 2, maxAge = 4,
	baseChance = 0.5,
	cooldown = 5,
	category = "childhood",
	tags = { "toddler", "emotions", "tantrum" },
	
	choices = {
		{
			text = "😭 Full meltdown - crying and screaming",
			effects = { Happiness = -5 },
			feedText = "Meltdown mode...",
			onResolve = function(state)
				local roll = math.random()
				state.Flags = state.Flags or {}
				if roll < 0.3 then
					state.Flags.learns_from_tantrums = true
					state:AddFeed("😭 Big cry! But after, you got hugs and felt better. Emotions are hard!")
				elseif roll < 0.7 then
					state:AddFeed("😭 The tantrum exhausted you. You fell asleep and woke up reset.")
				else
					state.Flags.difficult_toddler = true
					state:AddFeed("😭 Epic meltdown. Parents looked tired. Being a toddler is TOUGH.")
				end
			end,
		},
		{
			text = "🧸 Hug your comfort toy",
			effects = { Happiness = 2 },
			setFlags = { self_soothes = true },
			feedText = "🧸 You hugged your favorite toy and the feelings got smaller. Good coping!",
		},
		{
			text = "🗣️ Use your words (try to)",
			effects = { Happiness = 3, Smarts = 2 },
			setFlags = { good_communicator = true },
			feedText = "🗣️ 'I... feel... SAD!' You tried words! Adults were proud!",
		},
	},
},

{
	id = "toddler_potty_milestone",
	title = "Potty Progress!",
	emoji = "🚽",
	textVariants = {
		"The big potty doesn't seem so scary anymore!",
		"You've been practicing and it's starting to click!",
		"Diaper days might be numbered!",
	},
	text = "The big potty doesn't seem so scary anymore!",
	question = "Time to try the potty!",
	minAge = 2, maxAge = 3,
	baseChance = 0.45,
	cooldown = 3,
	oneTime = true,
	category = "childhood",
	tags = { "toddler", "milestone", "potty" },
	blockedByFlags = { potty_trained = true },
	
	choices = {
		{
			text = "✨ Success! You did it!",
			effects = { Happiness = 10 },
			setFlags = { potty_trained = true, confident_learner = true },
			feedText = "🚽 YOU DID IT! The celebration was MASSIVE! High fives all around!",
		},
		{
			text = "😬 Oops, almost...",
			effects = { Happiness = 2 },
			feedText = "🚽 Not quite... but you're getting there! Progress not perfection!",
		},
		{
			text = "😰 Too scared, maybe later",
			effects = { Happiness = -2 },
			setFlags = { potty_shy = true },
			feedText = "🚽 That's okay. The potty will be there when you're ready!",
		},
	},
},

{
	id = "toddler_sibling_reaction",
	title = "New Baby in the House!",
	emoji = "👶",
	textVariants = {
		"Mom and Dad brought home a tiny human!",
		"There's a new baby and everyone's paying attention to them!",
		"A baby sibling has arrived!",
	},
	text = "Mom and Dad brought home a tiny human!",
	question = "How do you feel about this new baby?",
	minAge = 2, maxAge = 5,
	baseChance = 0.3,
	cooldown = 10,
	oneTime = true,
	category = "family",
	tags = { "toddler", "sibling", "family" },
	requiresFlags = { has_sibling_born = true },
	blockedByFlags = { sibling_reaction_done = true },
	
	choices = {
		{
			text = "❤️ Love them! Want to help!",
			effects = { Happiness = 8 },
			setFlags = { sibling_reaction_done = true, loving_sibling = true, helpful = true },
			feedText = "❤️ You LOVE your new sibling! You want to help with everything!",
		},
		{
			text = "😤 Not happy about sharing attention",
			effects = { Happiness = -5 },
			setFlags = { sibling_reaction_done = true, sibling_jealousy = true },
			feedText = "😤 The baby gets ALL the attention! It's not fair! (Normal feeling)",
		},
		{
			text = "🤔 Curious but cautious",
			effects = { Happiness = 2 },
			setFlags = { sibling_reaction_done = true, cautious_sibling = true },
			feedText = "🤔 The baby is interesting... but also kind of weird and loud.",
		},
	},
},

{
	id = "toddler_food_adventure",
	title = "New Food Challenge!",
	emoji = "🥦",
	textVariants = {
		"There's something NEW on your plate!",
		"Mom wants you to try a new vegetable!",
		"A strange food appears at dinner time!",
	},
	text = "There's something NEW on your plate!",
	question = "Will you try it?",
	minAge = 2, maxAge = 5,
	baseChance = 0.4,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "food", "picky" },
	
	choices = {
		{
			text = "🤢 No way! It looks yucky!",
			effects = { Happiness = -2 },
			setFlags = { picky_eater = true },
			feedText = "🤢 You pushed the plate away. The green stuff looked SUSPICIOUS.",
		},
		{
			text = "🤔 One tiny bite...",
			effects = { Happiness = 3 },
			feedText = "Trying it...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.5 then
					state.Flags.adventurous_eater = true
					state:ModifyStat("Happiness", 5)
					state:AddFeed("😋 You liked it! Maybe new foods aren't so bad!")
				else
					state:ModifyStat("Happiness", -2)
					state:AddFeed("🤢 You tried it... BLEH! Never again.")
				end
			end,
		},
		{
			text = "😋 Yum! More please!",
			effects = { Happiness = 6, Health = 3 },
			setFlags = { loves_food = true, good_eater = true },
			feedText = "😋 Delicious! You ate it all and wanted more! Adventurous eater!",
		},
	},
},

{
	id = "toddler_night_terror",
	title = "Scary Dream!",
	emoji = "😱",
	textVariants = {
		"You wake up in the middle of the night, scared!",
		"A nightmare jolts you awake!",
		"Something in your dream was really scary!",
	},
	text = "You wake up in the middle of the night, scared!",
	question = "What do you do?",
	minAge = 2, maxAge = 6,
	baseChance = 0.35,
	cooldown = 5,
	category = "childhood",
	tags = { "toddler", "nightmare", "sleep" },
	
	choices = {
		{
			text = "😭 Cry for mom/dad!",
			effects = { Happiness = 3 },
			feedText = "😭 You cried out and someone came! Cuddles made it all better.",
		},
		{
			text = "🧸 Hug your stuffed animal tight",
			effects = { Happiness = 4 },
			setFlags = { self_soothes = true, brave = true },
			feedText = "🧸 You hugged your friend tight and felt safe. So brave!",
		},
		{
			text = "😰 Hide under the blanket",
			effects = { Happiness = 1 },
			feedText = "😰 The blanket became your fortress. Nothing could get you there!",
		},
	},
},

{
	id = "preschool_show_and_tell_day",
	title = "Show and Tell!",
	emoji = "⭐",
	textVariants = {
		"It's show and tell day at preschool!",
		"Time to show the class something special!",
		"Your turn to present to everyone!",
	},
	text = "It's show and tell day at preschool!",
	question = "What do you share?",
	minAge = 3, maxAge = 5,
	baseChance = 0.5,
	cooldown = 4,
	category = "school",
	tags = { "preschool", "social", "confidence" },
	requiresFlags = { in_preschool = true },
	
	choices = {
		{
			text = "🧸 Your favorite toy",
			effects = { Happiness = 6 },
			setFlags = { confident_speaker = true },
			feedText = "⭐ You showed your best friend (the toy) to everyone! They loved it!",
		},
		{
			text = "🎨 A picture you drew",
			effects = { Happiness = 5, Smarts = 2 },
			setFlags = { artistic_confidence = true },
			feedText = "⭐ Your artwork impressed everyone! Future artist in the making!",
		},
		{
			text = "😰 Too shy to share",
			effects = { Happiness = -3 },
			setFlags = { stage_fright = true },
			feedText = "😰 You couldn't do it... but that's okay. Public speaking is hard!",
		},
		{
			text = "🐛 A cool bug you found",
			effects = { Happiness = 7 },
			setFlags = { nature_lover = true, unique_kid = true },
			feedText = "⭐ A BUG?! Some kids screamed, some thought it was AWESOME!",
		},
	},
},

{
	id = "toddler_art_creation",
	title = "Masterpiece Time!",
	emoji = "🎨",
	textVariants = {
		"You have crayons and paper! Time to create!",
		"Art supplies are out! What will you make?",
		"Time to express yourself through art!",
	},
	text = "You have crayons and paper! Time to create!",
	question = "What do you draw?",
	minAge = 2, maxAge = 5,
	baseChance = 0.45,
	cooldown = 3,
	category = "childhood",
	tags = { "toddler", "art", "creativity" },
	
	choices = {
		{
			text = "👨‍👩‍👧 Your family",
			effects = { Happiness = 6 },
			setFlags = { family_oriented = true, artistic = true },
			feedText = "🎨 Your family portrait goes on the fridge! Everyone loved it!",
		},
		{
			text = "🌈 Something abstract and colorful",
			effects = { Happiness = 5, Smarts = 2 },
			setFlags = { creative_mind = true, artistic = true },
			feedText = "🎨 'It's a rainbow explosion!' they say. You know it's so much more.",
		},
		{
			text = "🏠 A house with a sun",
			effects = { Happiness = 4 },
			setFlags = { traditional_kid = true },
			feedText = "🎨 Classic! A house, sun, maybe some flowers. Timeless.",
		},
		{
			text = "👹 A monster!",
			effects = { Happiness = 7 },
			setFlags = { vivid_imagination = true, unique_kid = true },
			feedText = "🎨 RAWR! It's scary and awesome! You're quite the artist!",
		},
	},
},

{
	id = "toddler_playground_adventure",
	title = "Playground Challenge!",
	emoji = "🛝",
	textVariants = {
		"You're at the playground and there's a BIG slide!",
		"The climbing structure looks challenging!",
		"All the other kids are playing on the big equipment!",
	},
	text = "You're at the playground and there's a BIG slide!",
	question = "Do you try it?",
	minAge = 2, maxAge = 5,
	baseChance = 0.5,
	cooldown = 3,
	category = "childhood",
	tags = { "toddler", "playground", "brave" },
	
	choices = {
		{
			text = "🎢 Go for it! Down the big slide!",
			effects = { Happiness = 8, Health = 2 },
			setFlags = { brave = true, thrill_seeker = true },
			feedText = "🛝 WHEEEEE! That was AMAZING! You want to do it again!",
		},
		{
			text = "🧗 Try the climbing part first",
			effects = { Happiness = 5, Health = 3 },
			setFlags = { careful_kid = true, good_motor_skills = true },
			feedText = "🛝 You climbed all the way up! Look at you go!",
		},
		{
			text = "👀 Watch others first",
			effects = { Happiness = 2 },
			setFlags = { observant = true, cautious = true },
			feedText = "🛝 You watched and learned. Maybe next time you'll try!",
		},
	},
},

{
	id = "toddler_pet_encounter",
	title = "Furry Friend!",
	emoji = "🐕",
	textVariants = {
		"A friendly dog approaches you at the park!",
		"You see a cat lounging in the sun!",
		"There's a cute pet nearby!",
	},
	text = "A friendly dog approaches you at the park!",
	question = "What do you do?",
	minAge = 2, maxAge = 5,
	baseChance = 0.4,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "pets", "animals" },
	
	choices = {
		{
			text = "🤗 Pet the doggy gently!",
			effects = { Happiness = 8 },
			setFlags = { animal_lover = true, gentle = true },
			feedText = "🐕 Soft fur! The dog liked you! You made a furry friend!",
		},
		{
			text = "😱 Scared! It's so big!",
			effects = { Happiness = -3 },
			setFlags = { scared_of_dogs = true },
			feedText = "🐕 That was scary! Dogs are big and unpredictable!",
		},
		{
			text = "🏃 Chase it! Play!",
			effects = { Happiness = 7, Health = 3 },
			setFlags = { playful = true, energetic_kid = true },
			feedText = "🐕 You and the dog ran around! Best day ever!",
		},
	},
},

{
	id = "preschool_music_class",
	title = "Music Time!",
	emoji = "🎵",
	textVariants = {
		"It's music time at preschool!",
		"The teacher has instruments for everyone!",
		"Time to make some noise!",
	},
	text = "It's music time at preschool!",
	question = "Which instrument do you pick?",
	minAge = 3, maxAge = 5,
	baseChance = 0.45,
	cooldown = 4,
	category = "school",
	tags = { "preschool", "music", "creativity" },
	requiresFlags = { in_preschool = true },
	
	choices = {
		{
			text = "🥁 Drums! Bang bang bang!",
			effects = { Happiness = 8 },
			setFlags = { loves_drums = true, musical_interest = true, energetic_kid = true },
			feedText = "🥁 You made the LOUDEST sounds! Music (and noise) is your thing!",
		},
		{
			text = "🎹 The little keyboard",
			effects = { Happiness = 6, Smarts = 2 },
			setFlags = { piano_interest = true, musical_interest = true },
			feedText = "🎹 You pressed all the keys! Some sounds were pretty!",
		},
		{
			text = "🎤 Just sing along!",
			effects = { Happiness = 7 },
			setFlags = { loves_singing = true, outgoing = true },
			feedText = "🎤 La la la! Your voice is your instrument! Star performer!",
		},
		{
			text = "🪇 Shake the tambourine",
			effects = { Happiness = 5 },
			setFlags = { musical_interest = true, likes_rhythm = true },
			feedText = "🪇 Shake shake shake! You've got rhythm!",
		},
	},
},

{
	id = "toddler_helping_chores",
	title = "Little Helper!",
	emoji = "🧹",
	textVariants = {
		"Mom/Dad is doing chores and you want to help!",
		"The grown-ups are cleaning. You want to join!",
		"Time to be a big helper!",
	},
	text = "Mom/Dad is doing chores and you want to help!",
	question = "How do you help?",
	minAge = 2, maxAge = 5,
	baseChance = 0.4,
	cooldown = 4,
	category = "family",
	tags = { "toddler", "helping", "family" },
	
	choices = {
		{
			text = "🧹 Try sweeping (make a bigger mess)",
			effects = { Happiness = 5 },
			feedText = "Sweeping...",
			onResolve = function(state)
				local roll = math.random()
				state.Flags = state.Flags or {}
				if roll < 0.4 then
					state.Flags.helpful = true
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🧹 You actually helped! Sort of! Parents appreciated the effort!")
				else
					state:AddFeed("🧹 More mess than before... but the effort was adorable!")
				end
			end,
		},
		{
			text = "🧸 Put toys away",
			effects = { Happiness = 6 },
			setFlags = { responsible = true, helpful = true },
			feedText = "🧸 You put your toys away! So responsible! Gold star!",
		},
		{
			text = "🍽️ Help set the table",
			effects = { Happiness = 5, Smarts = 1 },
			setFlags = { helpful = true, learns_chores = true },
			feedText = "🍽️ You carried the napkins! Such a big help!",
		},
	},
},

{
	id = "toddler_water_play",
	title = "Splash Time!",
	emoji = "💦",
	textVariants = {
		"It's bath time! The water is warm and bubbly!",
		"Summer sprinklers are on in the yard!",
		"There's a puddle just BEGGING to be jumped in!",
	},
	text = "Water play opportunity!",
	question = "How do you play?",
	minAge = 1, maxAge = 4,
	baseChance = 0.45,
	cooldown = 3,
	category = "childhood",
	tags = { "toddler", "play", "water" },
	
	choices = {
		{
			text = "💦 SPLASH! Maximum water everywhere!",
			effects = { Happiness = 8 },
			setFlags = { loves_water = true, messy_player = true },
			feedText = "💦 SPLASH ATTACK! Water EVERYWHERE! You're soaked and HAPPY!",
		},
		{
			text = "🛁 Play with bath toys calmly",
			effects = { Happiness = 5 },
			setFlags = { calm_player = true },
			feedText = "🛁 Duck goes quack! Boat goes vroom! Nice calm play time!",
		},
		{
			text = "🫧 Make bubbles!",
			effects = { Happiness = 7 },
			setFlags = { loves_bubbles = true },
			feedText = "🫧 Bubbles! So many bubbles! Pop pop pop! Magic!",
		},
	},
},

{
	id = "toddler_language_explosion",
	title = "Words Words Words!",
	emoji = "🗣️",
	textVariants = {
		"Your vocabulary is EXPLODING!",
		"New words are coming out every day!",
		"You're learning to talk more and more!",
	},
	text = "Your vocabulary is EXPLODING!",
	question = "What's your favorite new word?",
	minAge = 2, maxAge = 3,
	baseChance = 0.5,
	cooldown = 5,
	oneTime = true,
	category = "childhood",
	tags = { "toddler", "language", "milestone" },
	blockedByFlags = { language_explosion_done = true },
	
	choices = {
		{
			text = "🚫 'NO!' (Classic toddler)",
			effects = { Happiness = 3 },
			setFlags = { language_explosion_done = true, strong_willed = true },
			feedText = "🗣️ 'NO!' Your favorite word. You use it A LOT.",
		},
		{
			text = "❓ 'Why?' (The curious one)",
			effects = { Happiness = 4, Smarts = 3 },
			setFlags = { language_explosion_done = true, naturally_curious = true, asks_why = true },
			feedText = "🗣️ 'Why?' Over and over. You want to understand EVERYTHING!",
		},
		{
			text = "❤️ 'I love you!'",
			effects = { Happiness = 8 },
			setFlags = { language_explosion_done = true, affectionate = true },
			feedText = "🗣️ 'I wuv you!' Hearts melt everywhere! So sweet!",
		},
		{
			text = "🎉 A silly made-up word",
			effects = { Happiness = 6 },
			setFlags = { language_explosion_done = true, creative_mind = true },
			feedText = "🗣️ 'Boppity-woop!' What does it mean? Only YOU know!",
		},
	},
},

{
	id = "preschool_first_day",
	title = "First Day of Preschool!",
	emoji = "🏫",
	textVariants = {
		"Today's the big day! First day of preschool!",
		"You're starting preschool! A whole new world!",
		"Time to join the other kids at school!",
	},
	text = "Today's the big day! First day of preschool!",
	question = "How do you feel?",
	minAge = 3, maxAge = 4,
	baseChance = 0.5,
	cooldown = 10,
	oneTime = true,
	category = "school",
	tags = { "preschool", "milestone", "school" },
	blockedByFlags = { in_preschool = true },
	
	choices = {
		{
			text = "😊 Excited! New friends!",
			effects = { Happiness = 10, Smarts = 2 },
			setFlags = { in_preschool = true, loves_school = true, social_butterfly = true },
			feedText = "🏫 First day was AMAZING! You can't wait to go back!",
		},
		{
			text = "😭 Don't want to leave mom/dad!",
			effects = { Happiness = -5 },
			setFlags = { in_preschool = true, separation_anxiety = true },
			feedText = "🏫 Lots of tears at drop-off... but you survived the day!",
		},
		{
			text = "😐 Nervous but okay",
			effects = { Happiness = 3 },
			setFlags = { in_preschool = true, adjusts_gradually = true },
			feedText = "🏫 First day was... fine. Takes time to adjust.",
		},
	},
},

{
	id = "toddler_independence",
	title = "I Can Do It Myself!",
	emoji = "💪",
	textVariants = {
		"You want to do something by yourself!",
		"Time to prove you're a big kid!",
		"You refuse help - you've got this!",
	},
	text = "You want to do something by yourself!",
	question = "What are you determined to do alone?",
	minAge = 2, maxAge = 4,
	baseChance = 0.5,
	cooldown = 3,
	category = "childhood",
	tags = { "toddler", "independence", "growing" },
	
	choices = {
		{
			text = "👕 Get dressed (backwards probably)",
			effects = { Happiness = 5 },
			feedText = "Getting dressed...",
			onResolve = function(state)
				local roll = math.random()
				state.Flags = state.Flags or {}
				if roll < 0.3 then
					state.Flags.independent = true
					state:ModifyStat("Happiness", 5)
					state:AddFeed("👕 You did it! Shirt might be inside-out but WHO CARES!")
				elseif roll < 0.7 then
					state:ModifyStat("Happiness", 2)
					state:AddFeed("👕 Two legs in one pant hole... close enough!")
				else
					state:ModifyStat("Happiness", -2)
					state:AddFeed("👕 Stuck in your shirt! Help needed after all.")
				end
			end,
		},
		{
			text = "🥄 Feed yourself",
			effects = { Happiness = 4 },
			setFlags = { independent_eater = true },
			feedText = "🥄 More food on your face than in your mouth but INDEPENDENCE!",
		},
		{
			text = "👟 Put on your own shoes",
			effects = { Happiness = 6 },
			setFlags = { independent = true },
			feedText = "👟 Shoes on! Wrong feet, but they're ON! Victory!",
		},
	},
},

{
	id = "toddler_imaginary_friend",
	title = "Special Friend!",
	emoji = "👻",
	textVariants = {
		"You have a new friend... that no one else can see!",
		"An imaginary companion has appeared!",
		"You've been talking to someone invisible!",
	},
	text = "You have a new friend... that no one else can see!",
	question = "Who is your imaginary friend?",
	minAge = 2, maxAge = 5,
	baseChance = 0.35,
	cooldown = 8,
	oneTime = true,
	category = "childhood",
	tags = { "toddler", "imagination", "friends" },
	blockedByFlags = { had_imaginary_friend = true },
	
	choices = {
		{
			text = "🐻 An animal friend",
			effects = { Happiness = 6, Smarts = 2 },
			setFlags = { had_imaginary_friend = true, vivid_imagination = true, animal_lover = true },
			feedText = "👻 Mr. Bear goes everywhere with you! Only you can see him!",
		},
		{
			text = "👸 A princess/prince",
			effects = { Happiness = 7 },
			setFlags = { had_imaginary_friend = true, vivid_imagination = true, royalty_dreams = true },
			feedText = "👻 Your royal friend helps you rule your kingdom (bedroom)!",
		},
		{
			text = "🦸 A superhero",
			effects = { Happiness = 8 },
			setFlags = { had_imaginary_friend = true, vivid_imagination = true, hero_complex = true },
			feedText = "👻 Captain Invisible helps you fight bad guys! Pow pow!",
		},
		{
			text = "👽 Something... unusual",
			effects = { Happiness = 5, Smarts = 3 },
			setFlags = { had_imaginary_friend = true, vivid_imagination = true, unique_kid = true },
			feedText = "👻 Bloop the blob is your best friend. No one else understands!",
		},
	},
},

{
	id = "toddler_counting_milestone",
	title = "Numbers Time!",
	emoji = "🔢",
	textVariants = {
		"Time to count! One, two, three...",
		"Numbers are becoming your friend!",
		"You're learning to count!",
	},
	text = "Time to count! One, two, three...",
	question = "How far can you count?",
	minAge = 2, maxAge = 4,
	baseChance = 0.45,
	cooldown = 5,
	oneTime = true,
	category = "childhood",
	tags = { "toddler", "learning", "numbers" },
	blockedByFlags = { learned_counting = true },
	
	choices = {
		{
			text = "1️⃣ One, two, THREE!",
			effects = { Happiness = 4, Smarts = 2 },
			setFlags = { learned_counting = true },
			feedText = "🔢 One, two, THREE! You're counting! Well... close enough!",
		},
		{
			text = "🔟 All the way to TEN!",
			effects = { Happiness = 6, Smarts = 5 },
			setFlags = { learned_counting = true, quick_learner = true, number_smart = true },
			feedText = "🔢 WOW! You counted to TEN! Math genius in the making!",
		},
		{
			text = "🤷 Just say random numbers",
			effects = { Happiness = 3 },
			setFlags = { learned_counting = true },
			feedText = "🔢 'One, seven, three, eleventy!' Close... ish!",
		},
	},
},

{
	id = "toddler_color_learning",
	title = "Colors Everywhere!",
	emoji = "🌈",
	textVariants = {
		"The world is full of colors!",
		"What's your favorite color?",
		"Colors are magical!",
	},
	text = "The world is full of colors!",
	question = "What's your favorite color?",
	minAge = 2, maxAge = 4,
	baseChance = 0.5,
	cooldown = 5,
	oneTime = true,
	category = "childhood",
	tags = { "toddler", "learning", "colors" },
	blockedByFlags = { favorite_color_picked = true },
	
	choices = {
		{
			text = "🔴 RED! Like fire trucks!",
			effects = { Happiness = 5 },
			setFlags = { favorite_color_picked = true, favorite_color_red = true, energetic_kid = true },
			feedText = "🔴 RED is the best! Fire trucks, strawberries, and ketchup!",
		},
		{
			text = "🔵 BLUE! Like the sky!",
			effects = { Happiness = 5 },
			setFlags = { favorite_color_picked = true, favorite_color_blue = true, calm_temperament = true },
			feedText = "🔵 BLUE! Like the sky, ocean, and... blueberries!",
		},
		{
			text = "💜 PURPLE! It's pretty!",
			effects = { Happiness = 5, Looks = 1 },
			setFlags = { favorite_color_picked = true, favorite_color_purple = true, artistic = true },
			feedText = "💜 PURPLE! The color of royalty and grape juice!",
		},
		{
			text = "🌈 ALL OF THEM!",
			effects = { Happiness = 7 },
			setFlags = { favorite_color_picked = true, loves_all_colors = true, positive_attitude = true },
			feedText = "🌈 Why pick one?! ALL colors are amazing! Rainbow lover!",
		},
	},
},

{
	id = "toddler_bedtime_routine",
	title = "Bedtime Story!",
	emoji = "📖",
	textVariants = {
		"It's bedtime! Time for a story!",
		"Snuggle up for bedtime routine!",
		"Story time before sleep!",
	},
	text = "It's bedtime! Time for a story!",
	question = "What kind of story do you want?",
	minAge = 1, maxAge = 5,
	baseChance = 0.45,
	cooldown = 3,
	category = "family",
	tags = { "toddler", "bedtime", "family" },
	
	choices = {
		{
			text = "🐻 Animal adventures",
			effects = { Happiness = 5 },
			setFlags = { loves_animal_stories = true, animal_lover = true },
			feedText = "📖 The bear went on an adventure... and you drifted to sleep!",
		},
		{
			text = "🏰 Fairy tales",
			effects = { Happiness = 6 },
			setFlags = { loves_fairy_tales = true, vivid_imagination = true },
			feedText = "📖 Once upon a time... you fell asleep dreaming of castles!",
		},
		{
			text = "🚀 Space adventures",
			effects = { Happiness = 5, Smarts = 2 },
			setFlags = { loves_space = true, curious_about_space = true },
			feedText = "📖 Rockets and stars filled your dreams! Future astronaut!",
		},
		{
			text = "🎵 Just sing songs",
			effects = { Happiness = 6 },
			setFlags = { loves_lullabies = true, musical_interest = true },
			feedText = "📖 Soft songs lulled you to sleep. Sweet dreams!",
		},
	},
},

-- ════════════════════════════════════════════════════════════════════════════
-- MASSIVE EXPANSION: NEW TODDLER/PRESCHOOL EVENTS (50+ new events)
-- These create variety and personalization for early life gameplay
-- ════════════════════════════════════════════════════════════════════════════

{
	id = "toddler_picky_eater",
	title = "Picky Eater Phase",
	emoji = "🥦",
	textVariants = {
		"Vegetables? GROSS! You refuse to eat anything green!",
		"You've decided you ONLY want chicken nuggets. Nothing else!",
		"Every meal is a battle. You want mac and cheese ONLY!",
		"You push away your plate. 'I don't LIKE it!'",
		"The broccoli looks like tiny trees. Scary tiny trees!",
	},
	text = "Vegetables? GROSS! You refuse to eat anything green!",
	question = "What do you do at dinner time?",
	minAge = 2, maxAge = 5,
	baseChance = 0.45,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "food", "behavior" },
	
	choices = {
		{
			text = "🙅 Refuse to eat ANYTHING",
			effects = { Health = -3, Happiness = 2 },
			setFlags = { picky_eater = true, stubborn = true },
			feedText = "🥦 You went to bed hungry. Victory? Defeat? Who knows!",
		},
		{
			text = "🤢 Pretend to eat, hide food",
			effects = { Smarts = 2 },
			setFlags = { sneaky_kid = true, problem_solver = true },
			feedText = "🥦 Vegetables under the table... until the dog ate them!",
		},
		{
			text = "😋 Actually try the food",
			effects = { Health = 4, Happiness = 3 },
			setFlags = { adventurous_eater = true, open_minded = true },
			feedText = "🥦 Wait... broccoli is actually kinda good?!",
		},
		{
			text = "😭 Cry until you get dessert",
			effects = { Happiness = 4, Health = -2 },
			setFlags = { knows_manipulation = true },
			feedText = "🥦 Tears work! Ice cream for dinner! (Just this once...)",
		},
	},
},

{
	id = "toddler_afraid_of_dark",
	title = "Afraid of the Dark",
	emoji = "🌙",
	textVariants = {
		"The lights go off and you're TERRIFIED!",
		"Something moved in the shadows! Or... did it?",
		"Bedtime is scary. The dark is full of monsters!",
		"Every shadow looks like a monster waiting to get you!",
		"You hear strange noises when it's dark...",
	},
	text = "The lights go off and you're TERRIFIED!",
	question = "How do you handle bedtime?",
	minAge = 2, maxAge = 6,
	baseChance = 0.5,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "fear", "bedtime" },
	
	choices = {
		{
			text = "😱 Scream for parents",
			effects = { Happiness = -2 },
			setFlags = { scared_of_dark = true, needs_comfort = true },
			feedText = "🌙 Mom/Dad came running. You slept in their bed!",
			relationshipEffect = { type = "family", change = 5 },
		},
		{
			text = "🔦 Use a nightlight",
			effects = { Happiness = 2 },
			setFlags = { uses_nightlight = true, problem_solver = true, creative_problem_solver = true, tech_savvy = true },
			hintCareer = "tech",
			feedText = "🌙 The nightlight keeps the monsters away! Much better!",
		},
		{
			text = "🦸 Pretend to be brave",
			effects = { Happiness = 3, Smarts = 2 },
			setFlags = { brave_kid = true, overcomes_fears = true, confident = true, leader_traits = true },
			feedText = "🌙 You're a superhero! Superheroes aren't afraid of dark!",
		},
		{
			text = "🧸 Hug stuffed animal tighter",
			effects = { Happiness = 3 },
			setFlags = { comfort_object = true, emotionally_attached = true, empathetic = true },
			feedText = "🌙 Mr. Bear will protect you! Together you're invincible!",
		},
	},
},

{
	id = "toddler_learning_abc",
	title = "ABC Time!",
	emoji = "🔤",
	textVariants = {
		"A, B, C, D, E, F, G... you're learning the alphabet!",
		"Time to sing the ABC song!",
		"Letters are everywhere! Signs, books, everything!",
		"Your parents are teaching you letters today!",
	},
	text = "A, B, C, D, E, F, G... you're learning the alphabet!",
	question = "How's the learning going?",
	minAge = 2, maxAge = 5,
	baseChance = 0.45,
	cooldown = 5,
	oneTime = true,
	category = "childhood",
	tags = { "toddler", "learning", "letters" },
	careerTags = { "education", "creative" },
	blockedByFlags = { learned_alphabet = true },
	
	choices = {
		{
			text = "🎵 Sing the whole song!",
			effects = { Happiness = 5, Smarts = 4 },
			setFlags = { learned_alphabet = true, quick_learner = true, musical_memory = true, smart_kid = true, early_reader = true },
			hintCareer = "education",
			feedText = "🔤 A B C D E F G... all the way to Z! You nailed it!",
		},
		{
			text = "🤔 Get stuck at L-M-N-O-P",
			effects = { Happiness = 3, Smarts = 2 },
			setFlags = { learned_alphabet = true },
			feedText = "🔤 'Elemeno P!' It's all one letter, right? Close enough!",
		},
		{
			text = "😴 Fall asleep during lesson",
			effects = { Happiness = 2 },
			setFlags = { learned_alphabet = true, sleepy_learner = true },
			feedText = "🔤 Zzz... you'll learn it tomorrow. Or the next day...",
		},
	},
},

{
	id = "toddler_first_haircut",
	title = "First Haircut!",
	emoji = "✂️",
	textVariants = {
		"Time for your first haircut! The barber chair is HUGE!",
		"Snip snip! Your parents brought you for your first haircut!",
		"The scissors look scary... but your hair IS pretty long...",
		"You're getting a real grown-up haircut today!",
	},
	text = "Time for your first haircut! The barber chair is HUGE!",
	question = "How do you handle it?",
	minAge = 1, maxAge = 4,
	baseChance = 0.55,
	oneTime = true,
	category = "childhood",
	tags = { "toddler", "milestone", "haircut" },
	blockedByFlags = { first_haircut_done = true },
	
	choices = {
		{
			text = "😭 Cry the whole time",
			effects = { Happiness = -3, Looks = 3 },
			setFlags = { first_haircut_done = true, hates_haircuts = true },
			feedText = "✂️ TRAUMATIC! But at least you look cute now...",
		},
		{
			text = "😊 Sit still like a champ",
			effects = { Happiness = 4, Looks = 4 },
			setFlags = { first_haircut_done = true, patient_kid = true, brave_kid = true },
			feedText = "✂️ You were so good! Got a lollipop as reward!",
		},
		{
			text = "🏃 Try to run away",
			effects = { Happiness = 2, Looks = 2 },
			setFlags = { first_haircut_done = true, wild_spirit = true },
			feedText = "✂️ Chaos! But they caught you. Uneven haircut... character!",
		},
	},
},

{
	id = "toddler_lost_in_store",
	title = "Lost in the Store!",
	emoji = "🏪",
	textVariants = {
		"Where's mommy?! WHERE'S MOMMY?! You're LOST!",
		"One minute you were right there, the next... WHERE ARE THEY?!",
		"You looked at toys for ONE second and now you're alone!",
		"The store is HUGE and you can't find your parents!",
	},
	text = "Where's mommy?! WHERE'S MOMMY?! You're LOST!",
	question = "What do you do?",
	minAge = 2, maxAge = 6,
	baseChance = 0.4,
	cooldown = 5,
	category = "childhood",
	tags = { "toddler", "scary", "store" },
	
	choices = {
		{
			text = "😭 Cry really loud",
			effects = { Happiness = -5 },
			setFlags = { got_lost_once = true },
			feedText = "🏪 Your crying worked! A worker found your parents!",
		},
		{
			text = "🧑 Find a store employee",
			effects = { Smarts = 3, Happiness = -2 },
			setFlags = { got_lost_once = true, knows_stranger_safety = true, smart_kid = true },
			feedText = "🏪 Smart! You found help and they called your parents!",
		},
		{
			text = "🔍 Try to find them yourself",
			effects = { Happiness = -3 },
			setFlags = { got_lost_once = true, independent_kid = true },
			feedText = "🏪 After scary minutes, you found them in checkout!",
		},
		{
			text = "🪑 Stay where you are",
			effects = { Smarts = 4 },
			setFlags = { got_lost_once = true, follows_instructions = true },
			feedText = "🏪 Good strategy! They came back to where they lost you!",
		},
	},
},

{
	id = "toddler_making_friends",
	title = "Making Friends",
	emoji = "👫",
	careerTags = { "business", "service" },
	textVariants = {
		"There's another kid at the playground! They look nice!",
		"A new kid moved in next door. They're your age!",
		"At daycare, a kid shares their snack with you!",
		"Another kid has the SAME favorite toy as you!",
	},
	text = "There's another kid at the playground! They look nice!",
	question = "Do you want to be friends?",
	minAge = 2, maxAge = 5,
	baseChance = 0.5,
	cooldown = 3,
	category = "childhood",
	tags = { "toddler", "social", "friends" },
	
	choices = {
		{
			text = "👋 Walk up and say hi!",
			effects = { Happiness = 6 },
			setFlags = { outgoing_kid = true, friendly_personality = true },
			feedText = "👫 You made a new friend! You played all afternoon!",
		},
		{
			text = "🎁 Share your toy with them",
			effects = { Happiness = 5, Smarts = 2 },
			setFlags = { generous_kid = true, makes_friends_easily = true },
			feedText = "👫 Sharing is caring! Now you're best buddies!",
		},
		{
			text = "😶 Wait for them to approach",
			effects = { Happiness = 3 },
			setFlags = { shy_personality = true },
			feedText = "👫 They came over! Sometimes waiting works!",
		},
		{
			text = "🏃 Run away shyly",
			effects = { Happiness = -2 },
			setFlags = { very_shy = true, social_anxiety = true },
			feedText = "👫 Maybe next time. Friends are scary...",
		},
	},
},

{
	id = "toddler_pet_encounter",
	title = "Meeting a Pet!",
	emoji = "🐕",
	textVariants = {
		"Your family got a new puppy! It's so fluffy!",
		"Grandma's cat wants to play with you!",
		"There's a friendly dog at the park!",
		"The neighbor's pet bunny is visiting!",
	},
	text = "Your family got a new puppy! It's so fluffy!",
	question = "How do you react to the animal?",
	minAge = 1, maxAge = 5,
	baseChance = 0.45,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "pets", "animals" },
	
	choices = {
		{
			text = "🤗 Hug it immediately!",
			effects = { Happiness = 8 },
			setFlags = { animal_lover = true, loves_pets = true },
			feedText = "🐕 BEST. DAY. EVER! You and the pet are inseparable!",
		},
		{
			text = "😨 Back away scared",
			effects = { Happiness = -2 },
			setFlags = { scared_of_animals = true },
			feedText = "🐕 Animals are unpredictable! You kept your distance.",
		},
		{
			text = "🤔 Observe carefully first",
			effects = { Happiness = 4, Smarts = 2 },
			setFlags = { cautious_with_animals = true, observant_kid = true },
			feedText = "🐕 Smart approach! You slowly made friends with it!",
		},
		{
			text = "🍪 Try to feed it",
			effects = { Happiness = 6 },
			setFlags = { animal_lover = true, nurturing_personality = true },
			feedText = "🐕 You shared your snack! Animals love you!",
		},
	},
},

{
	id = "toddler_temper_tantrum",
	title = "MELTDOWN!",
	emoji = "😤",
	textVariants = {
		"You can't have ice cream for breakfast?! UNACCEPTABLE!",
		"TV time is OVER?! This is the WORST day EVER!",
		"Your sibling touched YOUR toy! RAGE MODE ACTIVATED!",
		"Bedtime already?! But you're NOT TIRED!",
	},
	text = "You can't have ice cream for breakfast?! UNACCEPTABLE!",
	question = "How bad does the tantrum get?",
	minAge = 2, maxAge = 5,
	baseChance = 0.45,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "behavior", "tantrum" },
	
	choices = {
		{
			text = "😤 Full nuclear meltdown",
			effects = { Happiness = -5, Health = -2 },
			setFlags = { throws_big_tantrums = true, emotional_kid = true },
			feedText = "😤 EPIC tantrum! Screaming, crying, the works! Then... nap time.",
		},
		{
			text = "😢 Cry but calm down",
			effects = { Happiness = -3 },
			setFlags = { normal_tantrums = true },
			feedText = "😤 You cried it out. Feeling better now.",
		},
		{
			text = "🤝 Try to negotiate",
			effects = { Smarts = 3, Happiness = -1 },
			setFlags = { tries_to_negotiate = true, smart_kid = true },
			feedText = "😤 'What about just ONE scoop?' Good try, little lawyer!",
		},
		{
			text = "😔 Accept it sadly",
			effects = { Happiness = -2, Smarts = 2 },
			setFlags = { mature_for_age = true, emotionally_regulated = true },
			feedText = "😤 You pouted but accepted it. Growing up already!",
		},
	},
},

{
	id = "toddler_drawing_masterpiece",
	title = "Art Time!",
	emoji = "🎨",
	textVariants = {
		"Crayons are out! Time to create your masterpiece!",
		"You found markers! The world is your canvas!",
		"Finger paints! This is going to be MESSY!",
		"Time to draw! What will you create?",
	},
	text = "Crayons are out! Time to create your masterpiece!",
	question = "What do you draw?",
	minAge = 2, maxAge = 5,
	baseChance = 0.5,
	cooldown = 3,
	category = "childhood",
	careerTags = { "creative", "entertainment" },
	tags = { "toddler", "creative", "art" },
	
	choices = {
		{
			text = "👨‍👩‍👦 Draw your family",
			effects = { Happiness = 5 },
			setFlags = { family_artist = true, loves_family = true, artistic = true, creative = true },
			hintCareer = "creative",
			feedText = "🎨 A masterpiece! It's going on the fridge!",
			relationshipEffect = { type = "family", change = 5 },
		},
		{
			text = "🌈 Scribble rainbows",
			effects = { Happiness = 6 },
			setFlags = { colorful_artist = true, happy_kid = true, artistic = true, creative = true },
			hintCareer = "creative",
			feedText = "🎨 SO MANY COLORS! It's beautiful chaos!",
		},
		{
			text = "🦖 Draw dinosaurs/monsters",
			effects = { Happiness = 5, Smarts = 2 },
			setFlags = { creative_imagination = true, loves_dinosaurs = true, artistic = true, science_interest = true },
			hintCareer = "science",
			feedText = "🎨 RAWR! Your T-Rex is terrifying! (In a cute way)",
		},
		{
			text = "🏠 Draw everything around you",
			effects = { Happiness = 4, Smarts = 3 },
			setFlags = { observant_artist = true, detail_oriented = true, artistic = true, observant = true },
			hintCareer = "creative",
			feedText = "🎨 You drew the house, the dog, everything! Future artist!",
		},
	},
},

{
	id = "toddler_bath_time_fun",
	title = "Bath Time!",
	emoji = "🛁",
	textVariants = {
		"Splash splash! Bath time!",
		"Bubble bath time! So many bubbles!",
		"Time to get clean! The bathtub is calling!",
		"Rubber ducky, you're the one!",
	},
	text = "Splash splash! Bath time!",
	question = "How do you approach bath time?",
	minAge = 1, maxAge = 5,
	baseChance = 0.45,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "routine", "bath" },
	
	choices = {
		{
			text = "🎉 LOVE IT! Splash city!",
			effects = { Happiness = 6, Health = 2 },
			setFlags = { loves_bath_time = true, water_lover = true, athletic = true },
			feedText = "🛁 SPLASH! The bathroom is flooded but you're happy!",
		},
		{
			text = "😭 HATE IT! No bath!",
			effects = { Happiness = -3, Health = -1 },
			setFlags = { hates_baths = true, stubborn = true },
			feedText = "🛁 You screamed like it was lava. Drama queen/king!",
		},
		{
			text = "🧸 Only with toys!",
			effects = { Happiness = 4 },
			setFlags = { needs_bath_toys = true, playful = true },
			feedText = "🛁 Rubber ducky and boats make everything better!",
		},
		{
			text = "🎵 Sing in the tub",
			effects = { Happiness = 5 },
			setFlags = { shower_singer = true, musical_interest = true, musical_talent = true, passionate_performer = true },
			hintCareer = "entertainment",
			feedText = "🛁 Your bathroom concerts are legendary!",
		},
	},
},

{
	id = "toddler_sibling_moment",
	title = "Sibling Situation",
	emoji = "👶",
	textVariants = {
		"Your parents bring home a NEW BABY! What?!",
		"You have to share your room with your sibling now!",
		"Your sibling took YOUR toy! This means war!",
		"Mom and dad are paying more attention to the baby!",
	},
	text = "Your parents bring home a NEW BABY! What?!",
	question = "How do you feel about this?",
	minAge = 2, maxAge = 6,
	baseChance = 0.4,
	cooldown = 5,
	category = "family",
	tags = { "toddler", "sibling", "family" },
	
	choices = {
		{
			text = "😊 Excited! A friend!",
			effects = { Happiness = 6 },
			setFlags = { loves_siblings = true, welcoming_sibling = true },
			feedText = "👶 You're the BEST big brother/sister! So excited!",
		},
		{
			text = "😤 Jealous! No fair!",
			effects = { Happiness = -4 },
			setFlags = { sibling_jealousy = true },
			feedText = "👶 Why do THEY get all the attention?! You were here first!",
		},
		{
			text = "🤔 Confused... what IS that?",
			effects = { Happiness = 2, Smarts = 2 },
			setFlags = { curious_about_baby = true },
			feedText = "👶 Why does it cry so much? Can it play yet?",
		},
		{
			text = "🛡️ Must protect the baby!",
			effects = { Happiness = 5 },
			setFlags = { protective_sibling = true, caring_personality = true },
			feedText = "👶 You're on guard duty! No one hurts YOUR baby!",
		},
	},
},

{
	id = "toddler_learning_shapes",
	title = "Shapes Discovery",
	emoji = "🔷",
	textVariants = {
		"Circles! Squares! Triangles! Shapes are everywhere!",
		"Everything has a shape! You're noticing them all!",
		"Shape puzzle time! Can you match them?",
		"Your teacher is showing you all the different shapes!",
	},
	text = "Circles! Squares! Triangles! Shapes are everywhere!",
	question = "Which shape is your favorite?",
	minAge = 2, maxAge = 5,
	baseChance = 0.45,
	cooldown = 5,
	oneTime = true,
	category = "childhood",
	tags = { "toddler", "learning", "shapes" },
	
	choices = {
		{
			text = "⭕ Circle! Like pizza!",
			effects = { Happiness = 4, Smarts = 2 },
			setFlags = { learned_shapes = true, likes_circles = true },
			feedText = "🔷 Circles are perfect! Like the sun and cookies!",
		},
		{
			text = "⬜ Square! Like a block!",
			effects = { Happiness = 4, Smarts = 2 },
			setFlags = { learned_shapes = true, likes_squares = true },
			feedText = "🔷 Squares are sturdy! Building blocks are squares!",
		},
		{
			text = "🔺 Triangle! Like a mountain!",
			effects = { Happiness = 4, Smarts = 3 },
			setFlags = { learned_shapes = true, likes_triangles = true },
			feedText = "🔷 Triangles are pointy! Like pizza slices!",
		},
		{
			text = "⭐ Star! Like in the sky!",
			effects = { Happiness = 5, Smarts = 2 },
			setFlags = { learned_shapes = true, likes_stars = true, dreams_big = true },
			feedText = "🔷 Stars are magical! You're a star yourself!",
		},
	},
},

{
	id = "toddler_playground_slide",
	title = "The Big Slide!",
	emoji = "🛝",
	textVariants = {
		"The BIG slide at the playground! It's so tall!",
		"All the big kids use that slide. Can you do it?",
		"That slide looks scary... but also fun?",
		"You've conquered the baby slide. Time for the BIG one!",
	},
	text = "The BIG slide at the playground! It's so tall!",
	question = "Do you try the big slide?",
	minAge = 3, maxAge = 6,
	baseChance = 0.5,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "playground", "challenge" },
	
	choices = {
		{
			text = "🚀 WHEEE! Down I go!",
			effects = { Happiness = 8, Health = 2 },
			setFlags = { brave_kid = true, conquered_big_slide = true, thrill_seeker = true },
			feedText = "🛝 AMAZING! You did it! Best feeling ever!",
		},
		{
			text = "😰 Climb up, chicken out",
			effects = { Happiness = -2 },
			setFlags = { has_fears = true },
			feedText = "🛝 You walked back down the stairs. Maybe next time!",
		},
		{
			text = "👨 Only with parent help",
			effects = { Happiness = 5 },
			setFlags = { cautious_kid = true },
			feedText = "🛝 With mom/dad at the bottom, you did it! Safe AND fun!",
		},
		{
			text = "🔁 Practice on small slide first",
			effects = { Happiness = 4, Smarts = 2 },
			setFlags = { methodical_learner = true, practices_first = true },
			feedText = "🛝 Smart! Build up to it. You'll conquer it soon!",
		},
	},
},

{
	id = "toddler_broken_toy",
	title = "Broken Toy!",
	emoji = "🧸",
	textVariants = {
		"Oh no! Your favorite toy broke!",
		"The head came off your stuffed animal!",
		"Your toy truck lost a wheel!",
		"Something terrible happened to your beloved toy!",
	},
	text = "Oh no! Your favorite toy broke!",
	question = "How do you handle this tragedy?",
	minAge = 2, maxAge = 6,
	baseChance = 0.45,
	cooldown = 5,
	category = "childhood",
	tags = { "toddler", "toys", "emotions" },
	
	choices = {
		{
			text = "😭 Cry forever",
			effects = { Happiness = -6 },
			setFlags = { attached_to_toys = true, emotional_kid = true },
			feedText = "🧸 The tears won't stop! This is the saddest day!",
		},
		{
			text = "🔧 Try to fix it",
			effects = { Happiness = 2, Smarts = 3 },
			setFlags = { tries_to_fix_things = true, problem_solver = true },
			feedText = "🧸 With tape and hope, you tried to save it!",
		},
		{
			text = "👨 Ask parent to fix it",
			effects = { Happiness = 4 },
			setFlags = { asks_for_help = true },
			feedText = "🧸 Parent magic! It's almost like new!",
		},
		{
			text = "🤷 Move on to next toy",
			effects = { Happiness = 1 },
			setFlags = { adaptable_kid = true, not_attached = true },
			feedText = "🧸 Easy come, easy go. Other toys await!",
		},
	},
},

{
	id = "toddler_first_joke",
	title = "Telling Jokes!",
	emoji = "😂",
	textVariants = {
		"Why did the chicken cross the road? You don't know but it's HILARIOUS!",
		"You learned a joke! Time to tell EVERYONE!",
		"Knock knock! You've discovered the power of humor!",
		"You made someone laugh! This is your new superpower!",
	},
	text = "Why did the chicken cross the road? You don't know but it's HILARIOUS!",
	question = "How's your comedy career starting?",
	minAge = 3, maxAge = 6,
	baseChance = 0.45,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "humor", "social" },
	
	choices = {
		{
			text = "😂 Tell the joke 100 times",
			effects = { Happiness = 5 },
			setFlags = { class_clown = true, loves_attention = true },
			feedText = "😂 You told it SO many times! Still funny to you!",
		},
		{
			text = "🤔 Try to make up your own jokes",
			effects = { Happiness = 4, Smarts = 3 },
			setFlags = { creative_kid = true, aspiring_comedian = true },
			feedText = "😂 'Why did the banana... uh... go!' Comedy gold!",
		},
		{
			text = "😊 Save it for special moments",
			effects = { Happiness = 3 },
			setFlags = { knows_timing = true },
			feedText = "😂 Strategic humor. Save the best jokes!",
		},
	},
},

{
	id = "toddler_dress_up",
	title = "Dress Up Time!",
	emoji = "👗",
	textVariants = {
		"Time to play dress up! Who will you be today?",
		"You found the costume box! So many options!",
		"Halloween or not, it's dress up time!",
		"You want to wear your costume EVERYWHERE!",
	},
	text = "Time to play dress up! Who will you be today?",
	question = "What do you dress up as?",
	minAge = 2, maxAge = 6,
	baseChance = 0.5,
	cooldown = 3,
	category = "childhood",
	tags = { "toddler", "play", "imagination" },
	
	choices = {
		{
			text = "🦸 Superhero! I have powers!",
			effects = { Happiness = 6 },
			setFlags = { loves_superheroes = true, hero_complex = true },
			feedText = "👗 You're SUPER! Fighting invisible bad guys all day!",
		},
		{
			text = "👸 Princess/Prince! Royal life!",
			effects = { Happiness = 6, Looks = 1 },
			setFlags = { loves_royalty = true, royalty_dreams = true },
			feedText = "👗 Your majesty! The kingdom (backyard) awaits!",
		},
		{
			text = "🦖 Dinosaur! RAWR!",
			effects = { Happiness = 5 },
			setFlags = { loves_dinosaurs = true, wild_imagination = true },
			feedText = "👗 RAWR! You're a terrifying T-Rex! Run, humans!",
		},
		{
			text = "👨‍🚀 Astronaut! Space explorer!",
			effects = { Happiness = 5, Smarts = 2 },
			setFlags = { loves_space = true, wants_to_explore = true },
			feedText = "👗 3... 2... 1... BLAST OFF! To infinity and beyond!",
		},
	},
},

{
	id = "toddler_sharing_lesson",
	title = "Sharing is Caring?",
	emoji = "🤝",
	textVariants = {
		"Another kid wants to play with YOUR toy!",
		"Time to share your snack with your friend!",
		"Your sibling wants your stuff! Again!",
		"Sharing is what nice kids do... but it's HARD!",
	},
	text = "Another kid wants to play with YOUR toy!",
	question = "Do you share?",
	minAge = 2, maxAge = 5,
	baseChance = 0.5,
	cooldown = 3,
	category = "childhood",
	tags = { "toddler", "social", "sharing" },
	
	choices = {
		{
			text = "😊 Sure! Here you go!",
			effects = { Happiness = 4, Smarts = 2 },
			setFlags = { good_sharer = true, generous_personality = true },
			feedText = "🤝 You shared! And guess what? They shared back!",
		},
		{
			text = "😤 NO! MINE!",
			effects = { Happiness = 2 },
			setFlags = { doesn_share = true, possessive = true },
			feedText = "🤝 You clutched it tight. Sharing is HARD!",
		},
		{
			text = "⏰ They can have a turn later",
			effects = { Happiness = 3, Smarts = 2 },
			setFlags = { fair_sharer = true, diplomatic_kid = true },
			feedText = "🤝 Taking turns! Fair solution for everyone!",
		},
		{
			text = "🔄 Trade for their toy",
			effects = { Happiness = 5, Smarts = 3 },
			setFlags = { good_negotiator = true, business_minded = true },
			feedText = "🤝 A deal was made! Both kids happy!",
		},
	},
},

{
	id = "toddler_messy_eating",
	title = "Messy Meal!",
	emoji = "🍝",
	textVariants = {
		"Spaghetti! It's everywhere! On you, the chair, the floor!",
		"Feeding yourself is HARD! Food goes everywhere!",
		"You're covered in food! But you're feeding yourself!",
		"Meal time = mess time at your age!",
	},
	text = "Spaghetti! It's everywhere! On you, the chair, the floor!",
	question = "How does the meal go?",
	minAge = 1, maxAge = 4,
	baseChance = 0.45,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "food", "milestone" },
	
	choices = {
		{
			text = "🎨 Food is art! Spread it everywhere!",
			effects = { Happiness = 6 },
			setFlags = { messy_eater = true, creative_mess = true },
			feedText = "🍝 The high chair is now a modern art installation!",
		},
		{
			text = "🥄 Try to be neat",
			effects = { Happiness = 3, Smarts = 2 },
			setFlags = { neat_eater = true, coordinated = true },
			feedText = "🍝 Some made it in your mouth! Progress!",
		},
		{
			text = "✋ Use hands! Utensils are for losers!",
			effects = { Happiness = 5 },
			setFlags = { hands_on_eater = true, independent = true },
			feedText = "🍝 Hands work just fine! Who needs forks?!",
		},
	},
},

{
	id = "toddler_question_phase",
	title = "But WHY?",
	emoji = "❓",
	textVariants = {
		"Why is the sky blue? Why? But WHY?",
		"You've discovered the power of asking WHY!",
		"Everything needs an explanation! WHY WHY WHY!",
		"Parents are getting tired of your questions!",
	},
	text = "Why is the sky blue? Why? But WHY?",
	question = "How curious are you?",
	minAge = 2, maxAge = 6,
	baseChance = 0.5,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "curious", "development" },
	
	choices = {
		{
			text = "❓ Ask WHY about EVERYTHING",
			effects = { Smarts = 4, Happiness = 3 },
			setFlags = { very_curious = true, question_asker = true, future_scientist = true },
			feedText = "❓ Your parents are exhausted but you're LEARNING!",
		},
		{
			text = "🤔 Ask about specific things",
			effects = { Smarts = 3, Happiness = 2 },
			setFlags = { thoughtfully_curious = true },
			feedText = "❓ Focused questions! Getting real answers!",
		},
		{
			text = "📚 Look at books for answers",
			effects = { Smarts = 4, Happiness = 2 },
			setFlags = { book_learner = true, independent_learner = true },
			feedText = "❓ Books have SO many answers! (And pictures!)",
		},
		{
			text = "🤷 Accept 'because I said so'",
			effects = { Happiness = 2 },
			setFlags = { accepts_authority = true },
			feedText = "❓ Sometimes you just gotta accept it!",
		},
	},
},

{
	id = "toddler_best_friend_forever",
	title = "Best Friend!",
	emoji = "💕",
	textVariants = {
		"You found your BEST FRIEND! You're inseparable!",
		"There's one kid you ALWAYS want to play with!",
		"You and another kid just CLICK! Best friends forever!",
		"You made a best friend at daycare/preschool!",
	},
	text = "You found your BEST FRIEND! You're inseparable!",
	question = "How did you become best friends?",
	minAge = 3, maxAge = 6,
	baseChance = 0.45,
	cooldown = 5,
	oneTime = true,
	category = "childhood",
	tags = { "toddler", "friends", "milestone" },
	blockedByFlags = { first_best_friend = true },
	
	choices = {
		{
			text = "🎮 Same favorite things!",
			effects = { Happiness = 7 },
			setFlags = { first_best_friend = true, has_childhood_friend = true, bonds_over_interests = true },
			feedText = "💕 You both love the SAME stuff! Perfect match!",
		},
		{
			text = "🛡️ They stood up for me",
			effects = { Happiness = 6 },
			setFlags = { first_best_friend = true, has_childhood_friend = true, values_loyalty = true },
			feedText = "💕 They had your back! A true friend!",
		},
		{
			text = "🏠 They're my neighbor!",
			effects = { Happiness = 6 },
			setFlags = { first_best_friend = true, has_childhood_friend = true, neighborhood_friend = true },
			feedText = "💕 Living close means playing together all the time!",
		},
		{
			text = "😄 We just laugh together!",
			effects = { Happiness = 8 },
			setFlags = { first_best_friend = true, has_childhood_friend = true, fun_loving = true },
			feedText = "💕 Everything is funnier together! BFFs!",
		},
	},
},

{
	id = "toddler_sleep_problems",
	title = "Can't Sleep!",
	emoji = "😴",
	textVariants = {
		"You don't want to go to bed! You're NOT TIRED!",
		"It's bedtime but your eyes won't close!",
		"You keep getting out of bed!",
		"Sleep is for boring people! You want to PLAY!",
	},
	text = "You don't want to go to bed! You're NOT TIRED!",
	question = "What's your bedtime strategy?",
	minAge = 2, maxAge = 6,
	baseChance = 0.45,
	cooldown = 4,
	category = "childhood",
	tags = { "toddler", "sleep", "behavior" },
	
	choices = {
		{
			text = "🏃 Keep getting out of bed",
			effects = { Happiness = 2, Health = -2 },
			setFlags = { fights_bedtime = true, energetic_kid = true },
			feedText = "😴 Round 1... Round 2... Round 10... Finally asleep!",
		},
		{
			text = "💧 'I need water!' 'One more story!'",
			effects = { Happiness = 3 },
			setFlags = { bedtime_delays = true, clever_kid = true },
			feedText = "😴 Water, bathroom, snack... you know all the tricks!",
		},
		{
			text = "😇 Go to sleep like a good kid",
			effects = { Health = 3, Happiness = 2 },
			setFlags = { good_sleeper = true, follows_rules = true },
			feedText = "😴 Out like a light! What a good kid!",
		},
		{
			text = "🎵 Need songs/stories to sleep",
			effects = { Happiness = 4 },
			setFlags = { needs_sleep_routine = true },
			feedText = "😴 The routine works! Songs and stories, then zzz...",
		},
	},
},

{
	id = "toddler_outdoor_discovery",
	title = "Outdoor Adventure!",
	emoji = "🌳",
	textVariants = {
		"The backyard is full of wonders! Bugs! Dirt! Sticks!",
		"You're exploring outside! Nature is AMAZING!",
		"Everything outside is new and exciting!",
		"The great outdoors awaits, little explorer!",
	},
	text = "The backyard is full of wonders! Bugs! Dirt! Sticks!",
	question = "What's the best part of being outside?",
	minAge = 2, maxAge = 6,
	baseChance = 0.45,
	cooldown = 3,
	category = "childhood",
	tags = { "toddler", "nature", "explore" },
	
	choices = {
		{
			text = "🐛 BUGS! They're fascinating!",
			effects = { Happiness = 5, Smarts = 2 },
			setFlags = { likes_bugs = true, nature_curious = true },
			feedText = "🌳 You collected SO many bugs! (Mom was not thrilled)",
		},
		{
			text = "🪨 Rocks and sticks collection!",
			effects = { Happiness = 5 },
			setFlags = { collector_kid = true, treasure_hunter = true },
			feedText = "🌳 Your pockets are FULL of 'treasures'!",
		},
		{
			text = "🌸 Flowers and plants!",
			effects = { Happiness = 5 },
			setFlags = { nature_lover = true, gentle_with_nature = true },
			feedText = "🌳 You picked flowers for everyone! (Well, the weeds too)",
		},
		{
			text = "💨 Running around everywhere!",
			effects = { Happiness = 6, Health = 3 },
			setFlags = { outdoor_kid = true, athletic_start = true },
			feedText = "🌳 You ran until you dropped! Happy exhaustion!",
		},
	},
},

{
	id = "toddler_potty_training",
	title = "Potty Training Time!",
	emoji = "🚽",
	textVariants = {
		"Time to learn to use the potty like a big kid!",
		"No more diapers? This is a big step!",
		"The potty is scary but exciting!",
		"Everyone's celebrating your potty progress!",
	},
	text = "Time to learn to use the potty like a big kid!",
	question = "How's potty training going?",
	minAge = 2, maxAge = 4,
	baseChance = 0.5,
	oneTime = true,
	category = "childhood",
	tags = { "toddler", "milestone", "development" },
	blockedByFlags = { potty_trained = true },
	
	choices = {
		{
			text = "🏆 I got this! Champion!",
			effects = { Happiness = 6, Smarts = 2 },
			setFlags = { potty_trained = true, quick_learner = true },
			feedText = "🚽 You're a potty PRODIGY! No more diapers!",
		},
		{
			text = "😅 Some accidents happen",
			effects = { Happiness = 3 },
			setFlags = { potty_trained = true },
			feedText = "🚽 Learning process! Getting better every day!",
		},
		{
			text = "😰 It's scary! I don't wanna!",
			effects = { Happiness = -2 },
			setFlags = { potty_trained = true, potty_fears = true },
			feedText = "🚽 Eventually got there! Just needed time!",
		},
	},
},

{
	id = "toddler_tantrum_public",
	title = "Public Meltdown!",
	emoji = "🛒",
	textVariants = {
		"You're melting down... in the GROCERY STORE!",
		"Full tantrum at the restaurant! Everyone's staring!",
		"You lost it at the mall! Maximum embarrassment!",
		"Public place + tired toddler = DISASTER!",
	},
	text = "You're melting down... in the GROCERY STORE!",
	question = "How bad does it get?",
	minAge = 2, maxAge = 5,
	baseChance = 0.4,
	cooldown = 5,
	category = "childhood",
	tags = { "toddler", "tantrum", "public" },
	
	choices = {
		{
			text = "🌊 Full theatrical performance",
			effects = { Happiness = -5 },
			setFlags = { public_tantrums = true, dramatic_kid = true },
			feedText = "🛒 Oscar-worthy tantrum! Everyone watched in horror!",
		},
		{
			text = "😢 Cry but get carried out",
			effects = { Happiness = -3 },
			setFlags = { sometimes_tantrums = true },
			feedText = "🛒 Emergency exit! Parents are mortified!",
		},
		{
			text = "🍬 Bribed with snacks",
			effects = { Happiness = 4 },
			setFlags = { snack_motivated = true },
			feedText = "🛒 A snack fixed everything! Crisis averted!",
		},
		{
			text = "😤 Pouty but manageable",
			effects = { Happiness = -1 },
			setFlags = { controlled_emotions = true },
			feedText = "🛒 Mad but held it together. Growing up!",
		},
	},
}

return events
