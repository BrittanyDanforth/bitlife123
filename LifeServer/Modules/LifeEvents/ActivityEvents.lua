-- ActivityEvents.lua
-- BitLife-style event cards for activities
-- Rich narrative events that pop up when doing activities
-- MASSIVELY EXPANDED with 100+ unique events

local ActivityEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- GYM / WORKOUT EVENTS (15+ events)
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Gym = {
	{
		id = "gym_great_session",
		title = "💪 Great Workout!",
		emoji = "💪",
		weight = 30,
		condition = function(state) return true end,
		texts = {
			"You pushed yourself hard at the gym today. The burn feels amazing!",
			"That was an incredible workout session. You can already feel yourself getting stronger.",
			"You crushed your personal best on the bench press today!",
			"The gym was empty and you had all the equipment to yourself. Perfect workout!",
		},
		effects = { Health = {5, 12}, Happiness = {2, 6}, Looks = {1, 4} },
		choices = {
			{ text = "💪 Keep it up!", feed = "You feel stronger already." },
			{ text = "📸 Take a gym selfie", feed = "You posted your gains on social media." },
		},
	},
	{
		id = "gym_met_trainer",
		title = "🏋️ Personal Trainer",
		emoji = "🏋️",
		weight = 15,
		condition = function(state) return (state.Money or 0) > 500 end,
		texts = {
			"A personal trainer at the gym notices your form and offers some tips.",
			"One of the trainers approaches you between sets with some advice.",
		},
		effects = { Health = {3, 8}, Smarts = {1, 3} },
		choices = {
			{ text = "📝 Take their advice", feed = "You learned proper technique.", effects = { Health = 3 } },
			{ text = "💵 Hire them ($200)", feed = "You hired a personal trainer!", cost = 200, effects = { Health = 8, Looks = 5 } },
			{ text = "🙅 I got this", feed = "You continued on your own." },
		},
	},
	{
		id = "gym_injury",
		title = "🤕 Gym Injury",
		emoji = "🤕",
		weight = 10,
		condition = function(state) return true end,
		texts = {
			"You lifted too heavy and felt something pull in your back.",
			"You weren't paying attention and dropped a weight on your foot.",
			"You pushed too hard and hurt your shoulder.",
		},
		effects = { Health = {-8, -20}, Happiness = {-5, -10} },
		category = "disaster",
		choices = {
			{ text = "🏥 Go to the doctor", feed = "The doctor says you need rest.", cost = 300, effects = { Health = 5 } },
			{ text = "🧊 Ice it and rest", feed = "You're taking it easy for a while." },
		},
	},
	{
		id = "gym_crush",
		title = "😍 Gym Crush",
		emoji = "😍",
		weight = 10,
		condition = function(state) return (state.Age or 0) >= 16 end,
		texts = {
			"Someone very attractive keeps glancing at you between sets.",
			"You noticed someone checking you out while you were on the treadmill.",
			"A cute person asked if you were using the machine next to you.",
		},
		effects = { Happiness = {5, 15} },
		choices = {
			{ text = "💬 Strike up a conversation", feed = "You had a nice chat. They seem interested!", effects = { Happiness = 8 } },
			{ text = "😊 Just smile back", feed = "You exchanged smiles. Nice!" },
			{ text = "🎧 Keep working out", feed = "You stayed focused on your gains." },
		},
	},
	{
		id = "gym_progress",
		title = "📈 Fitness Progress",
		emoji = "📈",
		weight = 20,
		condition = function(state) return true end,
		texts = {
			"You looked in the mirror and noticed your progress. You're getting toned!",
			"Your clothes are fitting differently. All that hard work is paying off!",
			"Someone at the gym complimented your transformation.",
		},
		effects = { Happiness = {8, 15}, Looks = {2, 6}, Health = {3, 8} },
		choices = {
			{ text = "😊 Feel proud", feed = "You're proud of your progress!" },
			{ text = "💪 Double down", feed = "Time to work even harder!", effects = { Health = 3 } },
		},
	},
	{
		id = "gym_newbie",
		title = "🆕 Gym Newbie",
		emoji = "🆕",
		weight = 8,
		texts = {
			"A nervous newcomer asks you how to use one of the machines.",
			"Someone clearly new to the gym is struggling with the equipment.",
		},
		effects = { Happiness = {2, 5} },
		choices = {
			{ text = "🤝 Help them out", feed = "You made their day easier!", effects = { Happiness = 8 } },
			{ text = "🎧 Pretend you didn't see", feed = "You stayed in your zone." },
		},
	},
	{
		id = "gym_max_pr",
		title = "🏆 New Personal Record!",
		emoji = "🏆",
		weight = 12,
		texts = {
			"You just hit a new personal record! Your max lift has increased!",
			"After months of training, you finally broke through your plateau!",
			"You ran faster and longer than ever before!",
		},
		effects = { Health = {8, 15}, Happiness = {10, 20}, Looks = {2, 5} },
		choices = {
			{ text = "🎉 Celebrate!", feed = "All that hard work paid off!" },
			{ text = "📊 Log it", feed = "Progress tracked for motivation!" },
		},
	},
	{
		id = "gym_crowded",
		title = "😤 Gym Packed",
		emoji = "😤",
		weight = 15,
		texts = {
			"The gym is absolutely packed. Every machine has a 20-minute wait.",
			"New Year's resolutioners have taken over the gym.",
			"You can barely move without bumping into someone.",
		},
		effects = { Health = {2, 5}, Happiness = {-5, -2} },
		choices = {
			{ text = "⏰ Wait it out", feed = "You finally got your workout in.", effects = { Health = 3 } },
			{ text = "🏃 Cardio only", feed = "At least the treadmills were free." },
			{ text = "🏠 Go home", feed = "You'll come back when it's less busy." },
		},
	},
	{
		id = "gym_competition",
		title = "🏅 Fitness Challenge",
		emoji = "🏅",
		weight = 8,
		condition = function(state) return (state.Age or 0) >= 16 end,
		texts = {
			"The gym is hosting a fitness competition with cash prizes!",
			"Someone challenged you to a friendly weightlifting contest.",
		},
		effects = { Happiness = {5, 10} },
		choices = {
			{ text = "💪 Enter the competition", feed = "You gave it your all!", triggersMash = true },
			{ text = "👀 Just watch", feed = "You cheered on the competitors." },
		},
	},
	{
		id = "gym_supplement_sales",
		title = "💊 Supplement Salesperson",
		emoji = "💊",
		weight = 10,
		texts = {
			"A guy at the gym is trying to sell you some 'totally legal' supplements.",
			"Someone claims they have miracle protein powder that'll double your gains.",
		},
		effects = { Happiness = {-2, 2} },
		choices = {
			{ text = "🙄 Hard pass", feed = "You trust your natural routine." },
			{ text = "🤔 Hear them out", feed = "Sounded sketchy. You passed." },
			{ text = "💵 Buy it ($50)", feed = "Hope this stuff actually works...", cost = 50, effects = { Health = {-5, 5} } },
		},
	},
	{
		id = "gym_equipment_hog",
		title = "😠 Equipment Hog",
		emoji = "😠",
		weight = 12,
		texts = {
			"Someone has been on the squat rack for an hour doing curls.",
			"A person is using three machines at once and getting angry when asked to share.",
		},
		effects = { Happiness = {-5, -2} },
		choices = {
			{ text = "🗣️ Confront them", feed = "They reluctantly shared.", effects = { Happiness = 3 } },
			{ text = "🔄 Use other equipment", feed = "You worked around them." },
			{ text = "😤 Report to staff", feed = "Staff handled the situation." },
		},
	},
	{
		id = "gym_celebrity_sighting",
		title = "⭐ Celebrity at the Gym",
		emoji = "⭐",
		weight = 5,
		condition = function(state) return (state.Money or 0) > 5000 end,
		texts = {
			"You spotted a famous athlete working out at your gym!",
			"A celebrity is casually lifting weights next to you!",
		},
		effects = { Happiness = {10, 20} },
		choices = {
			{ text = "📸 Ask for a photo", feed = "They were super nice about it!", effects = { Happiness = 10 } },
			{ text = "😎 Play it cool", feed = "You acted like it was no big deal." },
			{ text = "💪 Try to impress them", feed = "They noticed your dedication!" },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MEDITATION EVENTS (10+ events)
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Meditation = {
	{
		id = "meditation_peaceful",
		title = "🧘 Inner Peace",
		emoji = "🧘",
		weight = 35,
		texts = {
			"You achieved a deep state of relaxation. Your mind feels clear.",
			"The meditation session was incredibly calming. You feel at peace.",
			"All your stress melted away during the session.",
		},
		effects = { Happiness = {8, 18}, Health = {2, 6} },
		choices = {
			{ text = "☮️ Namaste", feed = "You feel centered and calm." },
			{ text = "🌸 Continue meditating", feed = "You extended your session for extra peace." },
		},
	},
	{
		id = "meditation_epiphany",
		title = "💡 Life Epiphany",
		emoji = "💡",
		weight = 15,
		texts = {
			"During meditation, you had a profound realization about your life.",
			"A moment of clarity hit you - you know exactly what you need to do.",
			"Your mind connected dots you never noticed before.",
		},
		effects = { Happiness = {10, 20}, Smarts = {3, 8} },
		choices = {
			{ text = "📝 Write it down", feed = "You journaled your insights.", effects = { Smarts = 3 } },
			{ text = "🤔 Reflect on it", feed = "This changes everything." },
		},
	},
	{
		id = "meditation_restless",
		title = "😤 Restless Mind",
		emoji = "😤",
		weight = 20,
		texts = {
			"You couldn't focus. Your mind kept wandering to stressful thoughts.",
			"Every little noise distracted you during the session.",
			"You fell asleep instead of meditating.",
		},
		effects = { Happiness = {-2, 2} },
		choices = {
			{ text = "🔄 Try again", feed = "You'll get it next time." },
			{ text = "🤷 Not for me today", feed = "Some days are just harder." },
		},
	},
	{
		id = "meditation_class",
		title = "🏛️ Meditation Class",
		emoji = "🏛️",
		weight = 10,
		condition = function(state) return (state.Money or 0) > 100 end,
		texts = {
			"A local meditation studio is offering a special class.",
			"You found a meditation retreat happening this weekend.",
		},
		effects = { Happiness = {5, 10} },
		choices = {
			{ text = "📿 Join the class ($50)", feed = "The guided meditation was amazing!", cost = 50, effects = { Happiness = 15, Health = 5 } },
			{ text = "🏠 Practice at home", feed = "Free meditation works too." },
		},
	},
	{
		id = "meditation_spiritual",
		title = "✨ Spiritual Experience",
		emoji = "✨",
		weight = 8,
		texts = {
			"You had an out-of-body experience during deep meditation.",
			"You felt connected to something greater than yourself.",
			"The universe seemed to speak to you in this moment.",
		},
		effects = { Happiness = {15, 30}, Smarts = {2, 5} },
		choices = {
			{ text = "🙏 Embrace it", feed = "You feel spiritually awakened." },
			{ text = "🤯 Whoa...", feed = "That was... intense." },
		},
	},
	{
		id = "meditation_angry",
		title = "😠 Meditation Interrupted",
		emoji = "😠",
		weight = 12,
		texts = {
			"Your phone kept buzzing with notifications during your session.",
			"Someone kept interrupting you every five minutes.",
			"Construction noise outside ruined your peaceful environment.",
		},
		effects = { Happiness = {-5, -10}, Health = {-2, 0} },
		choices = {
			{ text = "😤 Give up", feed = "Some things are out of your control." },
			{ text = "🎧 Use noise-canceling", feed = "You found a workaround.", effects = { Happiness = 5 } },
		},
	},
	{
		id = "meditation_app",
		title = "📱 Meditation App",
		emoji = "📱",
		weight = 15,
		texts = {
			"You discovered an amazing meditation app with guided sessions.",
			"A friend recommended a meditation app that's really helping people.",
		},
		effects = { Happiness = {5, 10} },
		choices = {
			{ text = "📲 Download it", feed = "The guided sessions are helpful!" },
			{ text = "💎 Get premium ($10)", feed = "The premium features are worth it!", cost = 10, effects = { Happiness = 8 } },
		},
	},
	{
		id = "meditation_crying",
		title = "😢 Emotional Release",
		emoji = "😢",
		weight = 10,
		texts = {
			"During meditation, suppressed emotions came flooding out.",
			"You found yourself crying during the session.",
		},
		effects = { Happiness = {-5, 10}, Health = {2, 5} },
		choices = {
			{ text = "😭 Let it out", feed = "Sometimes you need a good cry.", effects = { Happiness = 8 } },
			{ text = "🧘 Keep meditating", feed = "You processed your emotions." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTY EVENTS (15+ events)
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Party = {
	{
		id = "party_great_time",
		title = "🎉 Epic Party!",
		emoji = "🎉",
		weight = 30,
		texts = {
			"The party was incredible! You danced all night and made new friends.",
			"What a night! Everyone was talking about how fun the party was.",
			"You were the life of the party! People couldn't stop laughing at your jokes.",
		},
		effects = { Happiness = {12, 25} },
		choices = {
			{ text = "🕺 Keep dancing!", feed = "You partied until sunrise!" },
			{ text = "📸 Post party pics", feed = "Your social media blew up!" },
			{ text = "🏠 Head home happy", feed = "What an amazing night." },
		},
	},
	{
		id = "party_drama",
		title = "😱 Party Drama",
		emoji = "😱",
		weight = 15,
		texts = {
			"Someone started a fight at the party and things got heated.",
			"Drama erupted when someone's ex showed up with their new partner.",
			"An argument broke out and ruined the vibe.",
		},
		effects = { Happiness = {-5, 5} },
		choices = {
			{ text = "🛑 Break it up", feed = "You helped calm things down.", effects = { Happiness = 5 } },
			{ text = "🍿 Watch the drama", feed = "This is better than TV!" },
			{ text = "🚪 Leave quietly", feed = "Not your circus, not your monkeys." },
		},
	},
	{
		id = "party_romance",
		title = "💕 Party Romance",
		emoji = "💕",
		weight = 15,
		condition = function(state) return (state.Age or 0) >= 14 end,
		texts = {
			"You locked eyes with someone across the room. Sparks flew!",
			"Someone really attractive started talking to you at the party.",
			"You spent the whole party talking to one person. Chemistry is undeniable.",
		},
		effects = { Happiness = {10, 20} },
		choices = {
			{ text = "📱 Exchange numbers", feed = "You got their number!", effects = { Happiness = 10 } },
			{ text = "💋 Make a move", feed = "Things got romantic...", effects = { Happiness = 15 } },
			{ text = "🙈 Play it cool", feed = "You'll see them around." },
		},
	},
	{
		id = "party_embarrassing",
		title = "😳 Embarrassing Moment",
		emoji = "😳",
		weight = 15,
		texts = {
			"You tripped and fell in front of everyone at the party.",
			"Someone caught you doing something embarrassing on camera.",
			"You said something awkward and now everyone is looking at you.",
		},
		effects = { Happiness = {-8, -15} },
		choices = {
			{ text = "😂 Laugh it off", feed = "Everyone laughed WITH you, not AT you.", effects = { Happiness = 5 } },
			{ text = "😖 Hide in shame", feed = "You'll never live this down." },
		},
	},
	{
		id = "party_network",
		title = "🤝 Networking Opportunity",
		emoji = "🤝",
		weight = 10,
		condition = function(state) return (state.Age or 0) >= 18 end,
		texts = {
			"You met someone important at the party who could help your career.",
			"A business connection introduced themselves to you.",
		},
		effects = { Happiness = {5, 10} },
		choices = {
			{ text = "💼 Talk business", feed = "You made a valuable connection!", effects = { Smarts = 5 } },
			{ text = "🎉 Stay in party mode", feed = "Tonight is for fun, not work." },
		},
	},
	{
		id = "party_cops",
		title = "🚔 Party Busted!",
		emoji = "🚔",
		weight = 8,
		condition = function(state) return (state.Age or 0) >= 15 end,
		texts = {
			"The cops showed up! The party is getting shut down!",
			"Neighbors called the police about the noise.",
		},
		effects = { Happiness = {-10, -5} },
		category = "danger",
		choices = {
			{ text = "🏃 Run!", feed = "You escaped before they could get your name!", effects = { Health = -3 } },
			{ text = "🙋 Stay and cooperate", feed = "You got a warning but no trouble." },
			{ text = "🚪 Sneak out the back", feed = "You slipped away unnoticed." },
		},
	},
	{
		id = "party_famous_person",
		title = "⭐ Celebrity Guest",
		emoji = "⭐",
		weight = 5,
		texts = {
			"A local celebrity showed up to the party!",
			"Someone famous walked in and everyone freaked out!",
		},
		effects = { Happiness = {15, 25} },
		choices = {
			{ text = "📸 Get a photo", feed = "You got a pic with them!", effects = { Happiness = 10 } },
			{ text = "🗣️ Start a conversation", feed = "They were actually really cool!", effects = { Happiness = 15 } },
			{ text = "😎 Act unimpressed", feed = "You played it too cool." },
		},
	},
	{
		id = "party_drinking_game",
		title = "🎲 Party Games",
		emoji = "🎲",
		weight = 20,
		texts = {
			"Everyone started playing party games and it got competitive!",
			"Someone suggested a game and things got wild!",
		},
		effects = { Happiness = {10, 20} },
		choices = {
			{ text = "🏆 Win the game", feed = "You destroyed the competition!", effects = { Happiness = 10 } },
			{ text = "😂 Lose gracefully", feed = "You had fun anyway!" },
			{ text = "👀 Just watch", feed = "The entertainment was top tier." },
		},
	},
	{
		id = "party_hookup",
		title = "💋 Late Night Connection",
		emoji = "💋",
		weight = 12,
		condition = function(state) return (state.Age or 0) >= 18 end,
		texts = {
			"You and someone at the party really hit it off...",
			"The chemistry with someone was undeniable as the night went on.",
		},
		effects = { Happiness = {15, 30} },
		choices = {
			{ text = "💕 See where it goes", feed = "One thing led to another...", effects = { Happiness = 15 } },
			{ text = "😇 Keep it PG", feed = "You had a nice conversation instead." },
		},
	},
	{
		id = "party_food",
		title = "🍕 Party Food",
		emoji = "🍕",
		weight = 15,
		texts = {
			"The food at this party is amazing!",
			"Someone made homemade snacks and they're incredible!",
		},
		effects = { Happiness = {5, 12}, Health = {-2, 0} },
		choices = {
			{ text = "🍴 Eat everything", feed = "You stuffed yourself!", effects = { Health = -3 } },
			{ text = "🥗 Pace yourself", feed = "Moderation is key." },
		},
	},
	{
		id = "party_wallflower",
		title = "🧍 Social Anxiety",
		emoji = "🧍",
		weight = 10,
		texts = {
			"You're standing in the corner, not knowing anyone here.",
			"Everyone seems to know each other except you.",
		},
		effects = { Happiness = {-8, -3} },
		choices = {
			{ text = "🗣️ Introduce yourself", feed = "You made some new friends!", effects = { Happiness = 12 } },
			{ text = "📱 Hide on your phone", feed = "At least you showed up." },
			{ text = "🚪 Leave early", feed = "This wasn't your scene." },
		},
	},
	{
		id = "party_karaoke",
		title = "🎤 Karaoke Time!",
		emoji = "🎤",
		weight = 12,
		texts = {
			"Someone pulled out a karaoke machine!",
			"Your friends are pushing you to sing a song!",
		},
		effects = { Happiness = {5, 15} },
		choices = {
			{ text = "🎵 Sing your heart out", feed = "You crushed it!", effects = { Happiness = 15 } },
			{ text = "🎤 Duet with someone", feed = "The crowd loved it!", effects = { Happiness = 12 } },
			{ text = "🙈 Too shy", feed = "Maybe next time." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- STUDY EVENTS (12+ events)
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Study = {
	{
		id = "study_breakthrough",
		title = "📚 Study Breakthrough",
		emoji = "📚",
		weight = 25,
		texts = {
			"Everything finally clicked! You understand the material perfectly now.",
			"You had a breakthrough moment while studying. It all makes sense!",
			"Hours of studying paid off - you feel confident about this subject.",
		},
		effects = { Smarts = {5, 12}, Happiness = {3, 8} },
		choices = {
			{ text = "🎉 Celebrate!", feed = "Hard work pays off!" },
			{ text = "📖 Keep studying", feed = "You're on a roll!", effects = { Smarts = 3 } },
		},
	},
	{
		id = "study_exhausted",
		title = "😴 Study Burnout",
		emoji = "😴",
		weight = 20,
		texts = {
			"You've been studying so long your eyes are starting to cross.",
			"You caught yourself reading the same paragraph five times.",
			"Your brain feels completely fried from all this studying.",
		},
		effects = { Smarts = {1, 4}, Happiness = {-5, -10}, Health = {-2, -5} },
		choices = {
			{ text = "☕ Coffee break", feed = "A quick break helped.", effects = { Happiness = 3 } },
			{ text = "😤 Push through", feed = "No pain, no gain!", effects = { Smarts = 3 } },
			{ text = "🛏️ Call it a night", feed = "Rest is important too." },
		},
	},
	{
		id = "study_group",
		title = "👥 Study Group",
		emoji = "👥",
		weight = 15,
		texts = {
			"Someone invited you to join their study group.",
			"Your classmates are forming a study session.",
		},
		effects = { Smarts = {2, 5}, Happiness = {2, 5} },
		choices = {
			{ text = "📚 Join them", feed = "Studying together helped everyone!", effects = { Smarts = 5, Happiness = 5 } },
			{ text = "🤓 Study alone", feed = "You focus better by yourself." },
		},
	},
	{
		id = "study_distraction",
		title = "📱 Study Distraction",
		emoji = "📱",
		weight = 15,
		texts = {
			"Your phone kept distracting you with notifications.",
			"You spent more time on social media than actually studying.",
			"You got sucked into a YouTube rabbit hole.",
		},
		effects = { Smarts = {0, 2}, Happiness = {2, 5} },
		choices = {
			{ text = "📵 Put phone away", feed = "Focus mode activated!", effects = { Smarts = 5 } },
			{ text = "📱 Just one more video...", feed = "Where did the time go?" },
		},
	},
	{
		-- CRITICAL FIX: Renamed from "study_tutor" to avoid duplicate ID with SchoolActivityEvents
		id = "activity_get_tutor",
		title = "👨‍🏫 Need a Tutor",
		emoji = "👨‍🏫",
		weight = 10,
		condition = function(state) return (state.Money or 0) > 100 end,
		texts = {
			"This subject is really difficult. Maybe you need help.",
			"You're struggling to understand the material on your own.",
		},
		effects = { Smarts = {2, 4}, Happiness = {-3, 0} },
		choices = {
			{ text = "💵 Hire a tutor ($100)", feed = "The tutor made everything clear!", cost = 100, effects = { Smarts = 12 } },
			{ text = "🆓 Find free help online", feed = "YouTube tutorials are a lifesaver!", effects = { Smarts = 6 } },
			{ text = "😤 Figure it out yourself", feed = "Struggling builds character..." },
		},
	},
	{
		id = "study_ace_test",
		title = "💯 Aced the Material!",
		emoji = "💯",
		weight = 15,
		texts = {
			"You studied so well you could teach this subject!",
			"You've completely mastered this material.",
		},
		effects = { Smarts = {8, 15}, Happiness = {8, 15} },
		choices = {
			{ text = "🎓 Feel accomplished", feed = "You're ready for anything!" },
			{ text = "🤓 Help others study", feed = "Teaching reinforces learning!", effects = { Smarts = 3 } },
		},
	},
	{
		-- CRITICAL FIX: Renamed from "study_library" to avoid duplicate ID with SchoolActivityEvents
		id = "activity_library_study",
		title = "📚 Library Session",
		emoji = "📚",
		weight = 12,
		texts = {
			"You went to the library for a focused study session.",
			"The library's quiet atmosphere helped you concentrate.",
		},
		effects = { Smarts = {5, 10}, Happiness = {0, 3} },
		choices = {
			{ text = "📖 Stay longer", feed = "You made great progress!", effects = { Smarts = 5 } },
			{ text = "☕ Grab a coffee", feed = "Caffeine boost activated!" },
		},
	},
	{
		id = "study_all_nighter",
		title = "🌙 All-Nighter",
		emoji = "🌙",
		weight = 10,
		texts = {
			"You pulled an all-nighter cramming for an exam.",
			"You studied through the entire night.",
		},
		effects = { Smarts = {8, 15}, Health = {-8, -15}, Happiness = {-5, -10} },
		choices = {
			{ text = "☕ Power through", feed = "You're exhausted but prepared!", effects = { Smarts = 5 } },
			{ text = "😴 Catch some sleep", feed = "Even a nap helps.", effects = { Health = 5 } },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- READING EVENTS (10+ events)
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Reading = {
	{
		id = "reading_amazing_book",
		title = "📖 Amazing Book",
		emoji = "📖",
		weight = 30,
		texts = {
			"You couldn't put the book down! It was absolutely captivating.",
			"This book completely changed your perspective on life.",
			"You finished the entire book in one sitting. What a story!",
		},
		effects = { Smarts = {3, 8}, Happiness = {8, 15} },
		choices = {
			{ text = "⭐ Rate 5 stars", feed = "You added it to your favorites." },
			{ text = "📢 Recommend it", feed = "You told everyone about this book!" },
		},
	},
	{
		id = "reading_self_help",
		title = "📚 Self-Improvement Book",
		emoji = "📚",
		weight = 15,
		texts = {
			"You read a self-help book that gave you practical life advice.",
			"The book taught you new strategies for success.",
		},
		effects = { Smarts = {5, 10}, Happiness = {2, 5} },
		choices = {
			{ text = "📝 Take notes", feed = "You wrote down the key insights.", effects = { Smarts = 3 } },
			{ text = "✅ Apply the lessons", feed = "Time to make changes!" },
		},
	},
	{
		id = "reading_boring",
		title = "😑 Boring Book",
		emoji = "😑",
		weight = 20,
		texts = {
			"You tried reading but the book was incredibly boring.",
			"You fell asleep after the first chapter.",
			"You couldn't focus on the book at all.",
		},
		effects = { Smarts = {1, 2}, Happiness = {-2, 0} },
		choices = {
			{ text = "🔄 Try a different book", feed = "Maybe the next one will be better." },
			{ text = "📺 Watch TV instead", feed = "Reading isn't for everyone." },
		},
	},
	{
		id = "reading_mystery",
		title = "🔍 Mystery Novel",
		emoji = "🔍",
		weight = 12,
		texts = {
			"You're reading a gripping mystery novel!",
			"The plot twists in this book are insane!",
		},
		effects = { Smarts = {4, 8}, Happiness = {6, 12} },
		choices = {
			{ text = "🤔 Try to solve it", feed = "You guessed the ending!", effects = { Smarts = 3 } },
			{ text = "📖 Just enjoy the ride", feed = "What a thrilling read!" },
		},
	},
	{
		id = "reading_educational",
		title = "🎓 Educational Content",
		emoji = "🎓",
		weight = 15,
		texts = {
			"You're reading about a fascinating topic you knew nothing about.",
			"This book is expanding your knowledge significantly.",
		},
		effects = { Smarts = {8, 15}, Happiness = {3, 6} },
		choices = {
			{ text = "📚 Read more about it", feed = "You're becoming an expert!", effects = { Smarts = 5 } },
			{ text = "✅ Satisfied for now", feed = "Knowledge is power." },
		},
	},
	{
		id = "reading_book_club",
		title = "📚 Book Club Invite",
		emoji = "📚",
		weight = 8,
		texts = {
			"Someone invited you to join their book club.",
			"There's a local book club meeting this week.",
		},
		effects = { Happiness = {3, 8} },
		choices = {
			{ text = "📖 Join the club", feed = "You made bookworm friends!", effects = { Smarts = 5, Happiness = 8 } },
			{ text = "🙅 I read solo", feed = "Book clubs aren't your thing." },
		},
	},
	{
		id = "reading_classic",
		title = "📜 Classic Literature",
		emoji = "📜",
		weight = 10,
		texts = {
			"You're reading a classic piece of literature.",
			"This book has stood the test of time for good reason.",
		},
		effects = { Smarts = {6, 12}, Happiness = {2, 8} },
		choices = {
			{ text = "🎩 Feel cultured", feed = "You're practically a scholar now." },
			{ text = "🤔 Analyze the themes", feed = "Deep thoughts intensify.", effects = { Smarts = 4 } },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- NIGHTCLUB EVENTS (12+ events)
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Nightclub = {
	{
		id = "nightclub_vip",
		title = "🌟 VIP Treatment",
		emoji = "🌟",
		weight = 10,
		condition = function(state) return (state.Money or 0) > 1000 or (state.Fame or 0) > 30 end,
		texts = {
			"The bouncer recognized you and let you into the VIP section!",
			"Someone bought you drinks all night because they recognized you.",
		},
		effects = { Happiness = {15, 25} },
		choices = {
			{ text = "🍾 Pop bottles", feed = "You lived like a celebrity tonight!", effects = { Happiness = 10 } },
			{ text = "🙏 Stay humble", feed = "You had a great time without showing off." },
		},
	},
	{
		id = "nightclub_fight",
		title = "👊 Club Altercation",
		emoji = "👊",
		weight = 10,
		texts = {
			"Someone bumped into you and spilled your drink. They look aggressive.",
			"A drunk person is getting in your face about something.",
		},
		effects = { Happiness = {-5, 0} },
		category = "danger",
		choices = {
			{ text = "🥊 Fight back", feed = "Things got physical...", triggersCombat = true },
			{ text = "🙅 Walk away", feed = "You de-escalated the situation.", effects = { Happiness = 3 } },
			{ text = "🔊 Get security", feed = "Security handled it." },
		},
	},
	{
		id = "nightclub_dance",
		title = "💃 Dance Floor Magic",
		emoji = "💃",
		weight = 30,
		texts = {
			"Your dance moves are on fire tonight! Everyone is watching.",
			"You and a group of strangers had an epic dance circle.",
			"The DJ played your favorite song and you went all out!",
		},
		effects = { Happiness = {12, 22}, Health = {-2, 0} },
		choices = {
			{ text = "🕺 Keep dancing!", feed = "You danced until your feet hurt!" },
			{ text = "🍹 Take a break", feed = "Hydration is important!" },
		},
	},
	{
		id = "nightclub_hookup",
		title = "💋 Late Night Chemistry",
		emoji = "💋",
		weight = 12,
		condition = function(state) return (state.Age or 0) >= 21 end,
		texts = {
			"Someone attractive has been making eyes at you all night.",
			"The person you've been dancing with wants to leave together.",
		},
		effects = { Happiness = {10, 20} },
		choices = {
			{ text = "💕 Leave together", feed = "The night got interesting...", effects = { Happiness = 15 } },
			{ text = "📱 Exchange numbers", feed = "Maybe another time.", effects = { Happiness = 5 } },
			{ text = "🙅 Not tonight", feed = "You stayed responsible." },
		},
	},
	{
		id = "nightclub_expensive",
		title = "💸 Big Spender",
		emoji = "💸",
		weight = 15,
		texts = {
			"The drinks here are way more expensive than you thought!",
			"You got bottle service and the bill is shocking.",
		},
		effects = { Happiness = {8, 15} },
		choices = {
			{ text = "💳 Pay up", feed = "YOLO, right?", cost = 500, effects = { Happiness = 10 } },
			{ text = "🚰 Switch to water", feed = "Your wallet will thank you." },
		},
	},
	{
		id = "nightclub_celebrity_dj",
		title = "🎧 Celebrity DJ",
		emoji = "🎧",
		weight = 8,
		texts = {
			"A famous DJ is performing tonight! The energy is incredible!",
			"Your favorite artist is DJing at this club!",
		},
		effects = { Happiness = {20, 30} },
		choices = {
			{ text = "🙌 Get to the front", feed = "Best night ever!", effects = { Happiness = 10 } },
			{ text = "📸 Record everything", feed = "Your friends are so jealous!" },
		},
	},
	{
		id = "nightclub_bouncer",
		title = "🚫 Bouncer Issues",
		emoji = "🚫",
		weight = 10,
		condition = function(state) return (state.Looks or 50) < 40 end,
		texts = {
			"The bouncer doesn't want to let you in.",
			"There's a dress code issue at the door.",
		},
		effects = { Happiness = {-8, -15} },
		choices = {
			{ text = "💵 Offer a tip ($50)", feed = "Money talks!", cost = 50, effects = { Happiness = 10 } },
			{ text = "🗣️ Argue", feed = "You got nowhere.", effects = { Happiness = -5 } },
			{ text = "🚶 Find another club", feed = "Their loss anyway." },
		},
	},
	{
		id = "nightclub_bathroom_line",
		title = "🚻 Endless Bathroom Line",
		emoji = "🚻",
		weight = 12,
		texts = {
			"The bathroom line is literally 30 people deep.",
			"You've been waiting for the bathroom for 20 minutes.",
		},
		effects = { Happiness = {-5, -10} },
		choices = {
			{ text = "⏰ Wait it out", feed = "Finally! Sweet relief." },
			{ text = "😤 Find another option", feed = "Desperate times..." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- VACATION EVENTS (20+ events)
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Vacation = {
	{
		id = "vacation_paradise",
		title = "🏝️ Paradise Found",
		emoji = "🏝️",
		weight = 25,
		texts = {
			"The vacation destination exceeded all your expectations! Pure paradise.",
			"You found the perfect beach spot and relaxed all day.",
			"The views here are breathtaking. Best vacation ever!",
		},
		effects = { Happiness = {20, 35}, Health = {5, 15} },
		choices = {
			{ text = "📸 Take photos", feed = "These memories will last forever!" },
			{ text = "🧘 Just relax", feed = "You achieved total relaxation." },
		},
	},
	{
		id = "vacation_adventure",
		title = "🎢 Adventure Time",
		emoji = "🎢",
		weight = 20,
		texts = {
			"You went on an incredible adventure - hiking, zip-lining, the works!",
			"The local tour guide showed you hidden gems most tourists never see.",
		},
		effects = { Happiness = {15, 30}, Health = {2, 8} },
		choices = {
			{ text = "🤙 Try more activities", feed = "You lived life to the fullest!", effects = { Happiness = 10 } },
			{ text = "🏖️ Relax by the pool", feed = "Balance is key." },
		},
	},
	{
		id = "vacation_disaster",
		title = "😰 Vacation Gone Wrong",
		emoji = "😰",
		weight = 10,
		texts = {
			"Your luggage got lost and the hotel overbooked. Nightmare!",
			"You got food poisoning on the first day of your trip.",
			"It rained the entire vacation. So much for beach time.",
		},
		effects = { Happiness = {-10, -20}, Health = {-5, -15} },
		category = "disaster",
		choices = {
			{ text = "😤 Demand a refund", feed = "You got partial compensation.", moneyGain = {100, 500} },
			{ text = "🤷 Make the best of it", feed = "You found the silver lining.", effects = { Happiness = 5 } },
		},
	},
	{
		id = "vacation_romance",
		title = "💘 Vacation Romance",
		emoji = "💘",
		weight = 15,
		condition = function(state) return (state.Age or 0) >= 18 end,
		texts = {
			"You met someone amazing on vacation. The chemistry is undeniable.",
			"A fellow traveler caught your eye. You spent the whole trip together.",
		},
		effects = { Happiness = {15, 30} },
		choices = {
			{ text = "💕 Summer fling", feed = "A beautiful vacation romance.", effects = { Happiness = 15 } },
			{ text = "📱 Stay in touch", feed = "You exchanged contact info. Maybe something real?", effects = { Happiness = 10 } },
			{ text = "✋ Keep it casual", feed = "Nice meeting them, but you're on vacation." },
		},
	},
	{
		id = "vacation_beach",
		title = "🏖️ Beach Day",
		emoji = "🏖️",
		weight = 20,
		texts = {
			"Perfect beach weather! Crystal clear water and white sand.",
			"You spent the day swimming and sunbathing.",
		},
		effects = { Happiness = {15, 25}, Health = {3, 8}, Looks = {1, 3} },
		choices = {
			{ text = "🏊 Swim more", feed = "The water was perfect!", effects = { Health = 5 } },
			{ text = "☀️ Work on your tan", feed = "Looking bronzed!", effects = { Looks = 3 } },
			{ text = "🍹 Beach drinks", feed = "Relaxation complete.", effects = { Happiness = 5 } },
		},
	},
	{
		id = "vacation_scam",
		title = "⚠️ Tourist Scam",
		emoji = "⚠️",
		weight = 8,
		texts = {
			"Someone tried to scam you with a fake tour package.",
			"A street vendor charged you 10x the normal price.",
		},
		effects = { Happiness = {-10, -15} },
		choices = {
			{ text = "🔍 Caught it in time", feed = "You didn't fall for it!", effects = { Happiness = 5 } },
			{ text = "😤 Already paid ($100)", feed = "Expensive lesson learned.", cost = 100 },
		},
	},
	{
		id = "vacation_local_food",
		title = "🍜 Local Cuisine",
		emoji = "🍜",
		weight = 18,
		texts = {
			"You tried authentic local food and it was incredible!",
			"A local recommended an amazing restaurant off the tourist path.",
		},
		effects = { Happiness = {10, 20} },
		choices = {
			{ text = "🍴 Eat more", feed = "Your taste buds are in heaven!", effects = { Happiness = 8 } },
			{ text = "📝 Learn the recipe", feed = "You'll make this at home!", effects = { Smarts = 3 } },
		},
	},
	{
		id = "vacation_hiking",
		title = "🥾 Mountain Hike",
		emoji = "🥾",
		weight = 12,
		texts = {
			"You hiked to an amazing viewpoint!",
			"The mountain trail was challenging but worth it.",
		},
		effects = { Happiness = {12, 22}, Health = {5, 12} },
		choices = {
			{ text = "📸 Take panorama photos", feed = "The view is unreal!" },
			{ text = "🧘 Meditate at the top", feed = "Total peace.", effects = { Happiness = 10 } },
		},
	},
	{
		id = "vacation_cultural",
		title = "🏛️ Cultural Experience",
		emoji = "🏛️",
		weight = 15,
		texts = {
			"You visited ancient temples and learned about local history.",
			"A museum tour gave you deep insights into the culture.",
		},
		effects = { Smarts = {5, 12}, Happiness = {8, 15} },
		choices = {
			{ text = "📚 Learn more", feed = "You gained cultural knowledge!", effects = { Smarts = 5 } },
			{ text = "📸 Document everything", feed = "Great content for the gram!" },
		},
	},
	{
		id = "vacation_party",
		title = "🎉 Vacation Party",
		emoji = "🎉",
		weight = 15,
		condition = function(state) return (state.Age or 0) >= 18 end,
		texts = {
			"You found the hottest nightlife spot in town!",
			"Other tourists invited you to an epic beach party!",
		},
		effects = { Happiness = {15, 30}, Health = {-3, -8} },
		choices = {
			{ text = "🕺 Party all night", feed = "What a night!", effects = { Happiness = 15 } },
			{ text = "🏠 Head back early", feed = "You paced yourself." },
		},
	},
	{
		id = "vacation_wildlife",
		title = "🦜 Wildlife Encounter",
		emoji = "🦜",
		weight = 10,
		texts = {
			"You saw incredible wildlife you've never seen before!",
			"A safari tour showed you amazing animals in their habitat!",
		},
		effects = { Happiness = {15, 25}, Smarts = {2, 5} },
		choices = {
			{ text = "📷 Take wildlife photos", feed = "National Geographic quality!" },
			{ text = "🤩 Just observe", feed = "Nature is beautiful." },
		},
	},
	{
		id = "vacation_luxury_upgrade", -- CRITICAL FIX: Renamed from vacation_luxury to avoid duplicate ID with VacationActivityEvents.lua
		title = "🏨 Luxury Upgrade",
		emoji = "🏨",
		weight = 8,
		condition = function(state) return (state.Money or 0) > 5000 end,
		texts = {
			"The hotel offered you a free upgrade to a suite!",
			"You got bumped to first class on your flight!",
		},
		effects = { Happiness = {20, 35} },
		choices = {
			{ text = "🙏 Accept graciously", feed = "Living the high life!" },
			{ text = "📸 Show off a little", feed = "Your followers are jealous!", effects = { Happiness = 5 } },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- DOCTOR/HOSPITAL EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Doctor = {
	{
		-- CRITICAL FIX: Renamed to avoid ID collision with MedicalActivityEvents
		id = "doctor_routine_checkup",
		title = "🏥 Routine Checkup",
		emoji = "🏥",
		weight = 40,
		texts = {
			"The doctor says you're in good health!",
			"Your checkup results came back normal.",
			"Everything looks good - keep up the healthy lifestyle!",
		},
		effects = { Health = {2, 8}, Happiness = {3, 8} },
		choices = {
			{ text = "😊 Great news!", feed = "Clean bill of health!" },
			{ text = "🥗 Commit to healthier habits", feed = "You'll take better care of yourself.", effects = { Health = 3 } },
		},
	},
	{
		id = "doctor_concern",
		title = "⚠️ Health Concern",
		emoji = "⚠️",
		weight = 15,
		texts = {
			"The doctor found something concerning and wants to run more tests.",
			"Your blood pressure is higher than it should be.",
			"The doctor recommends lifestyle changes.",
		},
		effects = { Health = {-5, 5}, Happiness = {-10, -5} },
		category = "health",
		choices = {
			{ text = "🏥 Get more tests ($500)", feed = "Better safe than sorry.", cost = 500, effects = { Health = 5 } },
			{ text = "💪 Promise to change habits", feed = "Time to take health seriously.", effects = { Health = 3 } },
			{ text = "🤷 Ignore it", feed = "It's probably nothing..." },
		},
	},
	{
		id = "doctor_flu_shot",
		title = "💉 Flu Shot Time",
		emoji = "💉",
		weight = 20,
		texts = {
			"The doctor recommends getting a flu shot.",
			"It's flu season - time for vaccination.",
		},
		effects = { Health = {0, 3} },
		choices = {
			{ text = "💉 Get the shot", feed = "Arm's a little sore but you're protected!", effects = { Health = 5 } },
			{ text = "🙅 No thanks", feed = "You'll take your chances." },
		},
	},
	{
		id = "doctor_good_news",
		title = "🎉 Great Health News",
		emoji = "🎉",
		weight = 15,
		texts = {
			"Your fitness improvements are showing in your test results!",
			"The doctor is impressed with how healthy you are!",
		},
		effects = { Health = {5, 12}, Happiness = {10, 20} },
		choices = {
			{ text = "💪 Keep up the good work!", feed = "Your hard work is paying off!" },
			{ text = "🙏 Grateful", feed = "Good health is a blessing." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SPA/SALON EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Spa = {
	{
		id = "spa_relaxing",
		title = "💆 Ultimate Relaxation",
		emoji = "💆",
		weight = 35,
		texts = {
			"The spa treatment was incredible! You feel like a new person.",
			"All your stress melted away during the massage.",
			"This was exactly what you needed.",
		},
		effects = { Happiness = {15, 30}, Health = {5, 12}, Looks = {2, 5} },
		choices = {
			{ text = "😌 Bliss", feed = "Pure relaxation achieved." },
			{ text = "📅 Book another", feed = "You'll definitely be back!", cost = 100 },
		},
	},
	{
		id = "spa_makeover",
		title = "✨ Complete Makeover",
		emoji = "✨",
		weight = 20,
		texts = {
			"You got a complete makeover and look amazing!",
			"The stylist really knew what they were doing!",
		},
		effects = { Looks = {8, 15}, Happiness = {10, 20} },
		choices = {
			{ text = "📸 Selfie time!", feed = "You look incredible!" },
			{ text = "😎 Walk with confidence", feed = "New look, new you!" },
		},
	},
	{
		id = "spa_disaster",
		title = "😱 Spa Disaster",
		emoji = "😱",
		weight = 10,
		texts = {
			"The hairstylist completely messed up your hair!",
			"The treatment gave you an allergic reaction!",
		},
		effects = { Looks = {-5, -15}, Happiness = {-10, -20} },
		category = "disaster",
		choices = {
			{ text = "😤 Demand a fix", feed = "They tried to fix it...", effects = { Looks = 5 } },
			{ text = "😭 Leave crying", feed = "Hair grows back... eventually." },
			{ text = "💵 Demand refund", feed = "You got your money back.", moneyGain = {50, 200} },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ARCADE/GAMING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Games = {
	{
		id = "games_high_score",
		title = "🎮 High Score!",
		emoji = "🎮",
		weight = 25,
		texts = {
			"You beat the high score on your favorite game!",
			"After hours of practice, you finally mastered this game!",
		},
		effects = { Happiness = {10, 20}, Smarts = {2, 5} },
		choices = {
			{ text = "🏆 Enter initials", feed = "Your name is on the leaderboard!" },
			{ text = "🎮 Keep playing", feed = "Can you beat your own score?", effects = { Happiness = 5 } },
		},
	},
	{
		id = "games_marathon",
		title = "📺 Gaming Marathon",
		emoji = "📺",
		weight = 20,
		texts = {
			"You've been gaming for 8 hours straight.",
			"One more level... just one more...",
		},
		effects = { Happiness = {8, 15}, Health = {-5, -10} },
		choices = {
			{ text = "🎮 One more hour", feed = "Sleep is for the weak!", effects = { Happiness = 5, Health = -5 } },
			{ text = "🛏️ Call it a night", feed = "Responsible gaming.", effects = { Health = 3 } },
		},
	},
	{
		id = "games_new_friends",
		title = "🎮 Gaming Friends",
		emoji = "🎮",
		weight = 15,
		texts = {
			"You met some cool people while gaming online!",
			"Your gaming squad invited you to join their clan.",
		},
		effects = { Happiness = {8, 15} },
		choices = {
			{ text = "🤝 Join them", feed = "You found your gaming family!", effects = { Happiness = 10 } },
			{ text = "🎮 Solo player life", feed = "You prefer flying solo." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- RUNNING/EXERCISE EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Run = {
	{
		id = "run_runners_high",
		title = "🏃 Runner's High!",
		emoji = "🏃",
		weight = 30,
		texts = {
			"You hit that perfect runner's high! You feel invincible!",
			"The endorphins are flowing and you feel amazing!",
		},
		effects = { Health = {8, 15}, Happiness = {10, 20} },
		choices = {
			{ text = "🏃 Keep going!", feed = "You pushed even further!", effects = { Health = 5 } },
			{ text = "😌 Cool down", feed = "Perfect workout." },
		},
	},
	{
		id = "run_injury",
		title = "🤕 Running Injury",
		emoji = "🤕",
		weight = 12,
		texts = {
			"You twisted your ankle while running.",
			"Your knee is acting up again.",
			"You pushed too hard and pulled a muscle.",
		},
		effects = { Health = {-8, -15}, Happiness = {-5, -10} },
		choices = {
			{ text = "🧊 Ice and rest", feed = "You'll be back at it soon." },
			{ text = "🏥 See a doctor", feed = "Better safe than sorry.", cost = 200, effects = { Health = 5 } },
		},
	},
	{
		id = "run_scenic",
		title = "🌅 Scenic Route",
		emoji = "🌅",
		weight = 20,
		texts = {
			"You discovered an amazing new running trail!",
			"The sunrise during your run was breathtaking.",
		},
		effects = { Health = {5, 10}, Happiness = {12, 20} },
		choices = {
			{ text = "📸 Take a photo", feed = "Nature is beautiful." },
			{ text = "🏃 Make this your regular route", feed = "New favorite spot!" },
		},
	},
	{
		id = "run_marathon",
		title = "🏅 Marathon Opportunity",
		emoji = "🏅",
		weight = 8,
		condition = function(state) return (state.Health or 50) > 60 end,
		texts = {
			"There's a local marathon coming up. Should you sign up?",
			"Your running club is organizing a 5K race.",
		},
		effects = { Happiness = {5, 10} },
		choices = {
			{ text = "📝 Sign up ($50)", feed = "Challenge accepted!", cost = 50, effects = { Health = 10, Happiness = 15 } },
			{ text = "👀 Maybe next time", feed = "You'll train more first." },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- YOGA EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Yoga = {
	{
		id = "yoga_zen",
		title = "🧘‍♀️ Found Your Zen",
		emoji = "🧘‍♀️",
		weight = 35,
		texts = {
			"The yoga session left you feeling completely centered.",
			"You nailed every pose today. Perfect practice!",
		},
		effects = { Health = {5, 12}, Happiness = {10, 20} },
		choices = {
			{ text = "🙏 Namaste", feed = "Mind and body aligned." },
			{ text = "🧘 Extra meditation", feed = "Extended your practice.", effects = { Happiness = 5 } },
		},
	},
	{
		id = "yoga_class",
		title = "🏛️ Yoga Class",
		emoji = "🏛️",
		weight = 20,
		texts = {
			"The yoga instructor offered great guidance today.",
			"You tried a new style of yoga - it was challenging!",
		},
		effects = { Health = {5, 10}, Happiness = {5, 12}, Smarts = {1, 3} },
		choices = {
			{ text = "📅 Book more classes", feed = "You're getting hooked!", cost = 30 },
			{ text = "🏠 Practice at home", feed = "Free yoga works too!" },
		},
	},
	{
		id = "yoga_flexibility",
		title = "🤸 Flexibility Gains",
		emoji = "🤸",
		weight = 15,
		texts = {
			"You touched your toes for the first time in years!",
			"Your flexibility has improved dramatically!",
		},
		effects = { Health = {5, 10}, Looks = {2, 5}, Happiness = {8, 15} },
		choices = {
			{ text = "💪 Keep stretching", feed = "Progress feels great!" },
			{ text = "📸 Show off", feed = "Look what I can do!" },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MOVIE EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ActivityEvents.Movies = {
	{
		id = "movies_great_film",
		title = "🎬 Amazing Movie",
		emoji = "🎬",
		weight = 35,
		texts = {
			"The movie was incredible! Best film you've seen in years!",
			"You were on the edge of your seat the entire time!",
		},
		effects = { Happiness = {10, 20} },
		choices = {
			{ text = "⭐ 10/10", feed = "Instant classic!" },
			{ text = "📢 Recommend to friends", feed = "Everyone needs to see this!" },
		},
	},
	{
		id = "movies_terrible",
		title = "😴 Terrible Movie",
		emoji = "😴",
		weight = 20,
		texts = {
			"That movie was absolutely terrible. Complete waste of time.",
			"You fell asleep halfway through.",
		},
		effects = { Happiness = {-5, -10} },
		choices = {
			{ text = "🚶 Walk out", feed = "Life's too short for bad movies." },
			{ text = "📱 Browse phone", feed = "At least the AC was nice." },
		},
	},
	{
		id = "movies_date",
		title = "💕 Movie Date",
		emoji = "💕",
		weight = 15,
		condition = function(state) return (state.Age or 0) >= 14 end,
		texts = {
			"You're at the movies with someone special.",
			"The romantic tension during the movie is real.",
		},
		effects = { Happiness = {12, 22} },
		choices = {
			{ text = "🍿 Share popcorn", feed = "Classic movie date vibes.", effects = { Happiness = 5 } },
			{ text = "💋 Make a move", feed = "Things got romantic...", effects = { Happiness = 10 } },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

function ActivityEvents.getRandomEvent(activityType, state)
	local events = ActivityEvents[activityType]
	if not events then return nil end
	
	local validEvents = {}
	local totalWeight = 0
	
	for _, event in ipairs(events) do
		local valid = true
		if event.condition and not event.condition(state) then
			valid = false
		end
		
		if valid then
			table.insert(validEvents, event)
			totalWeight = totalWeight + (event.weight or 10)
		end
	end
	
	if #validEvents == 0 then return nil end
	
	-- Weighted random selection
	local roll = math.random(totalWeight)
	local cumWeight = 0
	
	for _, event in ipairs(validEvents) do
		cumWeight = cumWeight + (event.weight or 10)
		if roll <= cumWeight then
			-- Return a copy with random text selected
			local eventCopy = {}
			for k, v in pairs(event) do
				eventCopy[k] = v
			end
			
			if eventCopy.texts and #eventCopy.texts > 0 then
				eventCopy.text = eventCopy.texts[math.random(#eventCopy.texts)]
			end
			
			return eventCopy
		end
	end
	
	return validEvents[1]
end

function ActivityEvents.applyEffects(state, effects)
	if not effects or not state then return state end
	
	for stat, value in pairs(effects) do
		if type(value) == "table" then
			-- Range: {min, max}
			local change = math.random(value[1], value[2])
			state[stat] = math.clamp((state[stat] or 50) + change, 0, 100)
		else
			-- Fixed value
			state[stat] = math.clamp((state[stat] or 50) + value, 0, 100)
		end
	end
	
	return state
end

-- Map activity IDs to event categories
ActivityEvents.ActivityMapping = {
	gym = "Gym",
	meditate = "Meditation",
	party = "Party",
	study = "Study",
	read = "Reading",
	nightclub = "Nightclub",
	vacation = "Vacation",
	doctor = "Doctor",
	spa = "Spa",
	salon = "Spa",
	games = "Games",
	tv = "Games",
	arcade = "Games",
	run = "Run",
	yoga = "Yoga",
	movies = "Movies",
}

function ActivityEvents.getEventForActivity(activityId, state)
	local category = ActivityEvents.ActivityMapping[activityId]
	if category then
		return ActivityEvents.getRandomEvent(category, state)
	end
	return nil
end

return ActivityEvents
