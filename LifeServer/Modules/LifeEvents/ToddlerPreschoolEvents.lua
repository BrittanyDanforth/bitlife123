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
	baseChance = 0.6,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
	baseChance = 0.8,
	oneTime = true,
	category = "childhood",

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
	id = "show_and_tell",
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
	baseChance = 0.6,
	cooldown = 3,
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
	baseChance = 0.7,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
	baseChance = 0.7,
	cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
	id = "imaginary_friend",
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
	baseChance = 0.6,
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
	baseChance = 0.6,
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
	baseChance = 0.6,
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
	baseChance = 0.7,
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
	baseChance = 0.6,
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
	baseChance = 0.7,
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
	id = "birthday_party",
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
	baseChance = 0.55, -- CRITICAL FIX: Reduced from 0.9 to prevent spam
	cooldown = 12, -- CRITICAL FIX: Increased - birthday parties aren't every year
	category = "childhood",

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

return events
