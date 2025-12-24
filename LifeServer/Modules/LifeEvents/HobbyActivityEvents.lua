--[[
	HobbyActivityEvents.lua
	=======================
	Comprehensive event templates for hobby and leisure activities.
	These events give players immersive BitLife-style event cards for all
	hobby-related interactions and experiences.
	
	Categories:
	- Music: Playing instruments, concerts
	- Art: Painting, drawing, creativity
	- Gaming: Video games, board games
	- Sports: Individual sports activities
	- Cooking: Culinary adventures
	- Photography: Camera and photo activities
	- Writing: Creative and journal writing
	- Gardening: Green thumb activities
	- Crafts: DIY and handmade projects
	- Collecting: Hoarding treasures
--]]

local HobbyEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS (CRITICAL FIX: Nil-safe operations)
-- ═══════════════════════════════════════════════════════════════════════════════
local function safeModifyStat(state, stat, amount)
	if not state then return end
	if state.ModifyStat then
		state:ModifyStat(stat, amount)
	elseif state.Stats then
		state.Stats[stat] = math.clamp((state.Stats[stat] or 50) + amount, 0, 100)
	else
		state[stat] = math.clamp((state[stat] or 50) + amount, 0, 100)
	end
end

-- CRITICAL FIX: Check if player can do hobby activities
local function canDoHobbies(state)
	if not state then return false end
	local flags = state.Flags or {}
	-- Can't do hobbies from prison! (limited activities there)
	if flags.in_prison or flags.incarcerated or flags.in_jail then
		return false
	end
	return true
end

-- CRITICAL FIX: Check if hobby requires minimum age
local function isOldEnoughForHobby(state, minAge)
	local age = state.Age or 0
	return age >= (minAge or 5)
end

-- CRITICAL FIX: Check if player has hobby-related flags
local function hasHobbyFlag(state, hobbyFlag)
	if not state then return false end
	local flags = state.Flags or {}
	return flags[hobbyFlag] or false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MUSIC EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
HobbyEvents.Music = {
	-- CRITICAL FIX: Category-wide eligibility
	eligibility = function(state) return canDoHobbies(state) and isOldEnoughForHobby(state, 6) end,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Practice session
	{
		id = "music_practice",
		title = "🎵 Music Practice",
		texts = {
			"Time to practice your instrument!",
			"You pick up your instrument and start playing.",
			"Practice makes perfect. Let's make some music!",
			"The notes flow as you work on your skills.",
		},
		effects = { Happiness = {5, 15}, Smarts = {2, 5} },
		choices = {
			{
				text = "Practice scales and basics",
				feedback = {
					"Fundamentals are important! You work on technique.",
					"Your fingers move more naturally now.",
					"Boring but necessary practice!",
				},
				effects = { Smarts = 5, Happiness = 8 },
			},
			{
				text = "Learn a new song",
				feedback = {
					"You tackle something new and challenging!",
					"After many attempts, you nail it!",
					"Adding to your repertoire!",
				},
				effects = { Happiness = 15, Smarts = 3 },
			},
			{
				text = "Just jam freely",
				feedback = {
					"You play whatever comes to mind!",
					"Improvisation is its own art form.",
					"Pure musical joy!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Compose something original",
				feedback = {
					"You create your own music!",
					"The melody comes from your soul.",
					"A new original piece is born!",
				},
				effects = { Happiness = 20, Smarts = 5 },
			},
		},
	},
	-- Event 2: Performance
	{
		id = "music_performance",
		title = "🎤 Music Performance",
		texts = {
			"You have a chance to perform in front of people!",
			"The spotlight is on you. Time to show what you've got!",
			"An audience awaits your musical talent.",
		},
		effects = { Happiness = {-5, 25} },
		choices = {
			{
				text = "Give it your all",
				feedback = {
					"You pour your heart into the performance!",
					"The audience is captivated by your passion!",
					"Standing ovation material!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Play it safe",
				feedback = {
					"You stick to what you know best.",
					"A solid, consistent performance.",
					"Nothing flashy but well-executed.",
				},
				effects = { Happiness = 15 },
			},
			{
				text = "Get stage fright",
				feedback = {
					"Your nerves get the better of you...",
					"Some mistakes, but you push through.",
					"Next time will be better!",
				},
				effects = { Happiness = -5 },
			},
		},
	},
	-- Event 3: Joining a band
	{
		id = "music_band",
		title = "🎸 Band Opportunity",
		texts = {
			"Some musicians want you to join their band!",
			"You could be part of a musical group!",
			"A band is looking for someone with your skills.",
		},
		effects = { Happiness = {10, 25} },
		choices = {
			{
				text = "Join the band!",
				feedback = {
					"You're now part of a musical family!",
					"Making music with others is incredible!",
					"Band practice is the best!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Stay solo",
				feedback = {
					"You prefer making music on your own.",
					"Independence has its advantages.",
					"A lone wolf musician.",
				},
				effects = { Happiness = 12 },
			},
			{
				text = "Form your own band instead",
				feedback = {
					"Why join when you can lead?",
					"You gather musicians for YOUR band!",
					"Leadership and music combined!",
				},
				effects = { Happiness = 20 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ART EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
HobbyEvents.Art = {
	-- CRITICAL FIX: Category-wide eligibility
	eligibility = function(state) return canDoHobbies(state) and isOldEnoughForHobby(state, 4) end,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Creating art
	{
		id = "art_create",
		title = "🎨 Creating Art",
		texts = {
			"Canvas ready, inspiration flowing!",
			"Time to express yourself through art.",
			"The blank canvas calls to you.",
			"Creativity wants to come out and play!",
		},
		effects = { Happiness = {8, 20} },
		choices = {
			{
				text = "Paint a masterpiece",
				feedback = {
					"Colors blend beautifully on the canvas!",
					"Your vision comes to life!",
					"This might be your best work yet!",
				},
				effects = { Happiness = 20 },
			},
			{
				text = "Sketch something quick",
				feedback = {
					"A quick sketch exercises your skills!",
					"Simple but satisfying.",
					"Practice sketches make perfect!",
				},
				effects = { Happiness = 12 },
			},
			{
				text = "Experiment with new techniques",
				feedback = {
					"You try something completely different!",
					"Some experiments fail, but you learn!",
					"Growth comes from experimentation!",
				},
				effects = { Happiness = 15, Smarts = 5 },
			},
			{
				text = "Draw what you feel",
				feedback = {
					"Emotions flow through your artwork.",
					"Art as therapy is powerful.",
					"Your feelings are captured on canvas.",
				},
				effects = { Happiness = 18 },
			},
		},
	},
	-- Event 2: Art show
	{
		id = "art_show",
		title = "🖼️ Art Exhibition",
		texts = {
			"Your art is being displayed at a show!",
			"People will see and judge your work.",
			"The art world awaits your creations!",
		},
		effects = { Happiness = {-5, 30} },
		choices = {
			{
				text = "Display your best work",
				feedback = {
					"You showcase your finest pieces!",
					"Critics and viewers are impressed!",
					"Your art gets great feedback!",
				},
				effects = { Happiness = 30 },
			},
			{
				text = "Show experimental pieces",
				feedback = {
					"You go with your bold, unusual work.",
					"Divisive reactions - some love it, some don't.",
					"At least it's memorable!",
				},
				effects = { Happiness = 20 },
			},
			{
				text = "Feel too vulnerable to show",
				feedback = {
					"Art feels so personal to share...",
					"Maybe next time you'll be ready.",
					"Creating for yourself is valid too.",
				},
				effects = { Happiness = -5 },
			},
		},
	},
	-- Event 3: Commission
	{
		id = "art_commission",
		title = "💰 Art Commission",
		texts = {
			"Someone wants to pay you to create art!",
			"A commission opportunity arises!",
			"Your talent could earn you money!",
		},
		effects = { Happiness = {10, 25} },
		choices = {
			{
				text = "Accept the commission",
				feedback = {
					"You create custom art for a paying client!",
					"Money for doing what you love!",
					"Professional artist status achieved!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Decline - art shouldn't be work",
				feedback = {
					"You prefer keeping art as a pure hobby.",
					"No pressure, no expectations.",
					"Art for art's sake!",
				},
				effects = { Happiness = 12 },
			},
			{
				text = "Negotiate a higher price",
				feedback = {
					"Your art is worth more than they offered!",
					"They agree to your terms!",
					"Know your worth, artist!",
				},
				effects = { Happiness = 28 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- GAMING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
HobbyEvents.Gaming = {
	-- CRITICAL FIX: Category-wide eligibility
	eligibility = function(state) return canDoHobbies(state) and isOldEnoughForHobby(state, 5) end,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Gaming session
	{
		id = "gaming_session",
		title = "🎮 Gaming Time",
		texts = {
			"Controller in hand, game loaded. Let's go!",
			"Time for some quality gaming!",
			"The virtual world awaits your presence.",
			"Gaming is the best way to unwind!",
		},
		effects = { Happiness = {10, 20} },
		choices = {
			{
				text = "Play competitively online",
				feedback = {
					"You queue up for ranked matches!",
					"Win some, lose some, but always fun!",
					"Your gaming skills are tested!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Explore a story-driven game",
				feedback = {
					"You immerse yourself in a rich narrative!",
					"Games can tell amazing stories!",
					"Hours disappear as you adventure!",
				},
				effects = { Happiness = 20, Smarts = 3 },
			},
			{
				text = "Play with friends",
				feedback = {
					"Gaming with friends is double the fun!",
					"Laughter and teamwork fill the session!",
					"Memories made in virtual worlds!",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Lose track of time gaming",
				feedback = {
					"You look up and hours have passed!",
					"So addicting! Can't stop, won't stop!",
					"Just one more match... or ten.",
				},
				effects = { Happiness = 15 },
			},
		},
	},
	-- Event 2: Achievement unlock
	{
		id = "gaming_achievement",
		title = "🏆 Achievement Unlocked!",
		texts = {
			"You've accomplished something epic in your game!",
			"That achievement notification feels so good!",
			"All that effort paid off!",
		},
		effects = { Happiness = {15, 25} },
		choices = {
			{
				text = "Show it off to friends",
				feedback = {
					"'Look what I did!' Your friends are impressed!",
					"Bragging rights earned!",
					"Gaming achievements are accomplishments too!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Go for the next challenge",
				feedback = {
					"No rest! On to the next achievement!",
					"The completionist grind continues!",
					"100% completion is the goal!",
				},
				effects = { Happiness = 20 },
			},
			{
				text = "Take a screenshot",
				feedback = {
					"Documenting your gaming victories!",
					"This one's going on social media!",
					"Preserved for posterity!",
				},
				effects = { Happiness = 18 },
			},
		},
	},
	-- Event 3: Gaming tournament
	{
		id = "gaming_tournament",
		title = "🎯 Gaming Tournament",
		texts = {
			"There's a gaming tournament happening!",
			"Competitive gaming opportunity!",
			"Time to prove you're the best!",
		},
		effects = { Happiness = {5, 30} },
		choices = {
			{
				text = "Enter and try to win",
				feedback = {
					"You compete against the best!",
					"Win or lose, the competition is thrilling!",
					"Gaming at its most intense!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Just watch and learn",
				feedback = {
					"You observe top players in action!",
					"So much to learn from the pros!",
					"Inspiration for your own gameplay!",
				},
				effects = { Happiness = 15, Smarts = 3 },
			},
			{
				text = "Too scared to compete",
				feedback = {
					"Public competition is intimidating...",
					"Maybe you'll enter next time.",
					"Spectating is fun too!",
				},
				effects = { Happiness = 8 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SPORTS HOBBY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
HobbyEvents.Sports = {
	-- CRITICAL FIX: Category-wide eligibility
	eligibility = function(state) return canDoHobbies(state) and isOldEnoughForHobby(state, 5) end,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	-- Event 1: Working out
	{
		id = "sports_workout",
		title = "💪 Getting Active",
		texts = {
			"Time to get moving and work up a sweat!",
			"Your body craves physical activity!",
			"Exercise is calling!",
		},
		effects = { Health = {8, 15}, Happiness = {5, 12} },
		choices = {
			{
				text = "Go for a run",
				feedback = {
					"Feet pounding, heart pumping!",
					"Running clears your mind!",
					"Endorphins are flowing!",
				},
				effects = { Health = 15, Happiness = 10 },
			},
			{
				text = "Hit the gym",
				feedback = {
					"Weights clanking, muscles working!",
					"Getting stronger every session!",
					"Gym gains incoming!",
				},
				effects = { Health = 15, Happiness = 8 },
			},
			{
				text = "Play a pickup game",
				feedback = {
					"You join a casual game with others!",
					"Sports are more fun with people!",
					"Great exercise and great fun!",
				},
				effects = { Health = 12, Happiness = 15 },
			},
			{
				text = "Try a new sport",
				feedback = {
					"You attempt something you've never done!",
					"Clumsy but exciting to learn!",
					"New activities keep things fresh!",
				},
				effects = { Health = 10, Happiness = 12, Smarts = 3 },
			},
		},
	},
	-- Event 2: Personal best
	{
		id = "sports_personal_best",
		title = "🥇 Personal Best!",
		texts = {
			"You've beaten your personal record!",
			"All that training paid off!",
			"A new milestone achieved!",
		},
		effects = { Health = {5, 10}, Happiness = {15, 25} },
		choices = {
			{
				text = "Celebrate!",
				feedback = {
					"You did it! Time to be proud!",
					"Hard work leads to results!",
					"You're stronger than yesterday!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Set a new goal",
				feedback = {
					"Good, but you can do better!",
					"The next record awaits!",
					"Always improving!",
				},
				effects = { Happiness = 18, Health = 5 },
			},
			{
				text = "Share your achievement",
				feedback = {
					"Friends and family celebrate with you!",
					"Your accomplishment inspires others!",
					"Proud moment!",
				},
				effects = { Happiness = 22 },
			},
		},
	},
	-- Event 3: Sports injury
	{
		id = "sports_injury",
		title = "🤕 Sports Injury",
		texts = {
			"Ouch! You've hurt yourself during exercise!",
			"Something doesn't feel right...",
			"An injury interrupts your routine.",
		},
		effects = { Health = {-15, -5}, Happiness = {-15, -5} },
		choices = {
			{
				text = "Rest and recover",
				feedback = {
					"You take time off to heal properly.",
					"Rest is part of training too.",
					"You'll be back stronger!",
				},
				effects = { Health = -5, Happiness = -5 },
			},
			{
				text = "Push through it",
				feedback = {
					"You try to ignore the pain...",
					"This might make it worse.",
					"Stubborn but risky.",
				},
				effects = { Health = -15, Happiness = -8 },
			},
			{
				text = "See a doctor",
				feedback = {
					"Professional medical advice is smart.",
					"The doctor helps you recover faster.",
					"Taking care of your body!",
				},
				effects = { Health = -8, Happiness = -5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- COOKING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
HobbyEvents.Cooking = {
	-- Event 1: Cooking at home
	{
		id = "cooking_home",
		title = "👨‍🍳 Cooking at Home",
		texts = {
			"Time to make something delicious!",
			"The kitchen awaits your culinary creativity!",
			"What's cooking? Something amazing!",
		},
		effects = { Happiness = {8, 18}, Smarts = {2, 5} },
		choices = {
			{
				text = "Try a complex recipe",
				feedback = {
					"You tackle a challenging dish!",
					"It takes time, but the result is worth it!",
					"Master chef in training!",
				},
				effects = { Happiness = 18, Smarts = 5 },
			},
			{
				text = "Make comfort food",
				feedback = {
					"Simple, satisfying, delicious!",
					"Sometimes classics are best.",
					"Soul-warming food!",
				},
				effects = { Happiness = 15 },
			},
			{
				text = "Experiment with flavors",
				feedback = {
					"You throw together unexpected ingredients!",
					"Sometimes experiments are genius, sometimes... not.",
					"Culinary adventure!",
				},
				effects = { Happiness = 12, Smarts = 3 },
			},
			{
				text = "Burn everything",
				feedback = {
					"Oops! Smoke alarm goes off!",
					"Better luck next time, chef.",
					"Cooking is harder than it looks!",
				},
				effects = { Happiness = -5 },
			},
		},
	},
	-- Event 2: Cooking for others
	{
		id = "cooking_guests",
		title = "🍽️ Cooking for Others",
		texts = {
			"You're cooking a meal for friends/family!",
			"Time to impress with your cooking skills!",
			"Your guests are hungry and waiting!",
		},
		effects = { Happiness = {10, 25} },
		choices = {
			{
				text = "Make your signature dish",
				feedback = {
					"You cook what you know best!",
					"Everyone loves it! You're a hit!",
					"'Can I have the recipe?' they ask!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Try something impressive",
				feedback = {
					"You go all out to impress!",
					"Risk pays off - they're amazed!",
					"Restaurant-quality at home!",
				},
				effects = { Happiness = 28 },
			},
			{
				text = "Keep it simple",
				feedback = {
					"Simple food, good company.",
					"The food is secondary to the togetherness.",
					"Quality time over fancy meals!",
				},
				effects = { Happiness = 18 },
			},
		},
	},
	-- Event 3: Baking
	{
		id = "cooking_baking",
		title = "🧁 Baking Time",
		texts = {
			"The oven is preheating, let's bake!",
			"Sweet treats await!",
			"Baking is science AND art!",
		},
		effects = { Happiness = {10, 20} },
		choices = {
			{
				text = "Bake cookies",
				feedback = {
					"The house smells amazing!",
					"Warm cookies fresh from the oven!",
					"Can't stop eating them!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Make a fancy cake",
				feedback = {
					"You create a beautiful layered cake!",
					"Decorating takes patience but looks great!",
					"Too pretty to eat! (You eat it anyway)",
				},
				effects = { Happiness = 22, Smarts = 3 },
			},
			{
				text = "Try a new recipe",
				feedback = {
					"You attempt something new!",
					"Baking requires precision - you followed it exactly!",
					"Success! A new favorite!",
				},
				effects = { Happiness = 20, Smarts = 4 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PHOTOGRAPHY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
HobbyEvents.Photography = {
	-- Event 1: Photo walk
	{
		id = "photo_walk",
		title = "📷 Photo Walk",
		texts = {
			"Camera in hand, you set out to capture the world!",
			"There's beauty everywhere if you look for it.",
			"Time to find the perfect shot!",
		},
		effects = { Happiness = {10, 18}, Smarts = {2, 5} },
		choices = {
			{
				text = "Photograph nature",
				feedback = {
					"The natural world has endless beauty!",
					"You capture stunning landscapes and wildlife!",
					"Nature photography is therapeutic!",
				},
				effects = { Happiness = 18, Health = 5 },
			},
			{
				text = "Street photography",
				feedback = {
					"You capture candid moments of urban life!",
					"Stories unfold through your lens!",
					"The city comes alive in your photos!",
				},
				effects = { Happiness = 16, Smarts = 3 },
			},
			{
				text = "Portrait photography",
				feedback = {
					"You photograph people and their expressions!",
					"Every face tells a story!",
					"Connecting with subjects is rewarding!",
				},
				effects = { Happiness = 15 },
			},
		},
	},
	-- Event 2: Perfect shot
	{
		id = "photo_perfect",
		title = "✨ The Perfect Shot",
		texts = {
			"You captured something truly special!",
			"This photo is portfolio-worthy!",
			"That's the shot you've been waiting for!",
		},
		effects = { Happiness = {18, 28} },
		choices = {
			{
				text = "Share it with the world",
				feedback = {
					"You post it online and get lots of love!",
					"People appreciate your artistic eye!",
					"Your photography inspires others!",
				},
				effects = { Happiness = 28 },
			},
			{
				text = "Print and frame it",
				feedback = {
					"A physical print to admire!",
					"Your work deserves to be displayed!",
					"Art for your walls!",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Add it to your portfolio",
				feedback = {
					"Building a collection of your best work!",
					"Every great photo adds to your skills!",
					"Your portfolio grows stronger!",
				},
				effects = { Happiness = 20, Smarts = 3 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- WRITING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
HobbyEvents.Writing = {
	-- Event 1: Writing session
	{
		id = "writing_session",
		title = "✍️ Writing Time",
		texts = {
			"Words want to flow from your mind to the page.",
			"The blank page awaits your creativity.",
			"Time to write something meaningful.",
		},
		effects = { Happiness = {8, 18}, Smarts = {3, 8} },
		choices = {
			{
				text = "Write fiction",
				feedback = {
					"You create worlds and characters from imagination!",
					"Your story takes you places!",
					"Fiction writing is pure creation!",
				},
				effects = { Happiness = 18, Smarts = 5 },
			},
			{
				text = "Write in your journal",
				feedback = {
					"Processing thoughts through writing helps!",
					"Your journal is your confidant.",
					"Self-reflection through words!",
				},
				effects = { Happiness = 15, Smarts = 3 },
			},
			{
				text = "Write poetry",
				feedback = {
					"Emotions condensed into beautiful language!",
					"Poetry speaks what prose can't.",
					"Your soul in verse!",
				},
				effects = { Happiness = 16, Smarts = 4 },
			},
			{
				text = "Struggle with writer's block",
				feedback = {
					"The words just won't come today...",
					"Every writer faces this sometimes.",
					"Tomorrow will be better.",
				},
				effects = { Happiness = -3 },
			},
		},
	},
	-- Event 2: Completing a piece
	{
		id = "writing_complete",
		title = "📖 Finished Writing!",
		texts = {
			"You've completed a piece of writing!",
			"The final word is written. It's done!",
			"Your writing project is finished!",
		},
		effects = { Happiness = {15, 28}, Smarts = {5, 10} },
		choices = {
			{
				text = "Share it with others",
				feedback = {
					"You let others read your work!",
					"Feedback - good and bad - helps you grow!",
					"Putting your work out there is brave!",
				},
				effects = { Happiness = 25, Smarts = 5 },
			},
			{
				text = "Keep it private",
				feedback = {
					"Some writing is just for you.",
					"Not everything needs an audience.",
					"Personal satisfaction is enough!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Try to publish it",
				feedback = {
					"You submit your work for publication!",
					"The professional world awaits!",
					"Every published writer started somewhere!",
				},
				effects = { Happiness = 22, Smarts = 8 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- GARDENING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
HobbyEvents.Gardening = {
	-- Event 1: Planting
	{
		id = "gardening_plant",
		title = "🌱 Planting Time",
		texts = {
			"Hands in the dirt, seeds ready to plant!",
			"Time to grow something beautiful!",
			"Gardening connects you to nature.",
		},
		effects = { Happiness = {10, 18}, Health = {3, 8} },
		choices = {
			{
				text = "Plant flowers",
				feedback = {
					"Beauty grows from the earth!",
					"Your garden will be colorful!",
					"Nature's art at your fingertips!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Grow vegetables",
				feedback = {
					"Food from your own garden!",
					"Sustainable and satisfying!",
					"Farm-to-table from your backyard!",
				},
				effects = { Happiness = 15, Health = 5 },
			},
			{
				text = "Start an herb garden",
				feedback = {
					"Fresh herbs for cooking!",
					"Practical and pretty!",
					"Your kitchen will smell amazing!",
				},
				effects = { Happiness = 14, Health = 3 },
			},
		},
	},
	-- Event 2: Harvest time
	{
		id = "gardening_harvest",
		title = "🍅 Harvest Time!",
		texts = {
			"Your garden has produced!",
			"Time to reap what you've sown!",
			"The fruits (or vegetables) of your labor!",
		},
		effects = { Happiness = {15, 25} },
		choices = {
			{
				text = "Enjoy the harvest",
				feedback = {
					"Nothing tastes better than home-grown!",
					"Your patience paid off!",
					"The cycle of growth is complete!",
				},
				effects = { Happiness = 25, Health = 5 },
			},
			{
				text = "Share with neighbors",
				feedback = {
					"You spread the bounty!",
					"Your generosity is appreciated!",
					"Gardens bring communities together!",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Plan next season",
				feedback = {
					"Already thinking about improvements!",
					"Gardening is a year-round hobby!",
					"Next year will be even better!",
				},
				effects = { Happiness = 18, Smarts = 3 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRAFTS EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
HobbyEvents.Crafts = {
	-- Event 1: Making something
	{
		id = "crafts_make",
		title = "🧶 Crafting Time",
		texts = {
			"Time to make something with your hands!",
			"DIY projects are waiting!",
			"Create something unique and handmade!",
		},
		effects = { Happiness = {10, 20}, Smarts = {2, 5} },
		choices = {
			{
				text = "Knit or crochet",
				feedback = {
					"Yarn turns into something beautiful!",
					"Repetitive motions are meditative.",
					"Handmade warmth!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Build something",
				feedback = {
					"Wood, tools, creation!",
					"You make something functional and beautiful!",
					"The satisfaction of building!",
				},
				effects = { Happiness = 20, Smarts = 5 },
			},
			{
				text = "Upcycle old items",
				feedback = {
					"Trash becomes treasure!",
					"Sustainable creativity!",
					"New life for old things!",
				},
				effects = { Happiness = 16, Smarts = 3 },
			},
		},
	},
	-- Event 2: Gift making
	{
		id = "crafts_gift",
		title = "🎁 Making a Gift",
		texts = {
			"You're making a handmade gift for someone!",
			"The personal touch means everything!",
			"Handmade gifts show you care!",
		},
		effects = { Happiness = {15, 25} },
		choices = {
			{
				text = "Pour your heart into it",
				feedback = {
					"Every stitch/detail shows your love!",
					"This gift is one of a kind!",
					"They'll treasure it forever!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Keep it simple but meaningful",
				feedback = {
					"Simple doesn't mean less valuable.",
					"The thought counts most!",
					"A heartfelt handmade gift!",
				},
				effects = { Happiness = 20 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- COLLECTING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
HobbyEvents.Collecting = {
	-- Event 1: Finding a treasure
	{
		id = "collecting_find",
		title = "💎 Found Something Special!",
		texts = {
			"You've found an addition to your collection!",
			"A rare find for your hobby!",
			"Your collection grows!",
		},
		effects = { Happiness = {15, 25} },
		choices = {
			{
				text = "Add it proudly",
				feedback = {
					"A new treasure for your collection!",
					"The thrill of the find never gets old!",
					"Your collection is better than ever!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Research its value",
				feedback = {
					"You learn everything about your find!",
					"Knowledge makes collecting richer!",
					"Informed collecting is best!",
				},
				effects = { Happiness = 20, Smarts = 5 },
			},
			{
				text = "Trade for something better",
				feedback = {
					"You leverage this find for an upgrade!",
					"Strategic collecting!",
					"The art of the deal!",
				},
				effects = { Happiness = 22 },
			},
		},
	},
	-- Event 2: Showing collection
	{
		id = "collecting_show",
		title = "🏆 Showing Your Collection",
		texts = {
			"Someone wants to see your collection!",
			"Time to show off your treasures!",
			"Your collection impresses others!",
		},
		effects = { Happiness = {12, 22} },
		choices = {
			{
				text = "Share your passion",
				feedback = {
					"You enthusiastically explain each item!",
					"Your passion is contagious!",
					"Fellow collectors appreciate the details!",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Let the collection speak",
				feedback = {
					"The items are impressive on their own!",
					"Quality speaks for itself!",
					"An impressive display!",
				},
				effects = { Happiness = 18 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAPPING TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
HobbyEvents.ActivityMapping = {
	["music"] = "Music",
	["play_instrument"] = "Music",
	["practice_music"] = "Music",
	["guitar"] = "Music",
	["piano"] = "Music",
	["art"] = "Art",
	["paint"] = "Art",
	["draw"] = "Art",
	["sketch"] = "Art",
	["gaming"] = "Gaming",
	["video_games"] = "Gaming",
	["play_games"] = "Gaming",
	["sports"] = "Sports",
	["exercise"] = "Sports",
	["workout"] = "Sports",
	["run"] = "Sports",
	["cooking"] = "Cooking",
	["cook"] = "Cooking",
	["bake"] = "Cooking",
	["photography"] = "Photography",
	["photos"] = "Photography",
	["camera"] = "Photography",
	["writing"] = "Writing",
	["write"] = "Writing",
	["journal"] = "Writing",
	["gardening"] = "Gardening",
	["garden"] = "Gardening",
	["plant"] = "Gardening",
	["crafts"] = "Crafts",
	["diy"] = "Crafts",
	["knit"] = "Crafts",
	["collecting"] = "Collecting",
	["collect"] = "Collecting",
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════
function HobbyEvents.getEventForActivity(activityId)
	local categoryName = HobbyEvents.ActivityMapping[activityId]
	if not categoryName then
		-- Try partial matching
		for key, cat in pairs(HobbyEvents.ActivityMapping) do
			if string.find(activityId:lower(), key) or string.find(key, activityId:lower()) then
				categoryName = cat
				break
			end
		end
	end
	
	if not categoryName then
		return nil
	end
	
	local eventList = HobbyEvents[categoryName]
	if not eventList or #eventList == 0 then
		return nil
	end
	
	-- Return random event from category
	return eventList[math.random(1, #eventList)]
end

function HobbyEvents.getAllCategories()
	return {"Music", "Art", "Gaming", "Sports", "Cooking", "Photography", "Writing", "Gardening", "Crafts", "Collecting"}
end

return HobbyEvents
