--[[
	RomanceActivityEvents.lua
	=========================
	Comprehensive event templates for dating, romance, and relationship activities.
	These events give players immersive BitLife-style event cards for all 
	romantic relationship interactions.
	
	Categories:
	- FirstDate: Initial dates with new partners
	- RegularDate: Ongoing relationship dates
	- Proposal: Marriage proposals
	- Breakup: Ending relationships
	- Flirt: Casual flirting
	- Gift: Giving gifts to partners
	- Argument: Relationship conflicts
	- Makeup: Reconciliation after fights
	- Anniversary: Celebrating milestones
	- Intimacy: Romantic moments (TOS safe)
	- MeetFamily: Meeting partner's family
	- LongDistance: Distance relationship challenges
--]]

local RomanceEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIRST DATE EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.FirstDate = {
	-- Event 1: Coffee date
	{
		id = "date_coffee",
		title = "☕ First Coffee Date",
		texts = {
			"You meet {partner} at a cozy coffee shop for your first date.",
			"Nervous butterflies fill your stomach as you spot {partner} at the cafe.",
			"The smell of fresh coffee fills the air as you sit across from {partner}.",
			"You've been looking forward to this coffee date with {partner} all week.",
		},
		effects = { Happiness = {5, 15}, Relationship = {5, 15} },
		choices = {
			{
				text = "Be charming and confident",
				feedback = {
					"{partner} laughs at your jokes. The chemistry is undeniable!",
					"Your confidence impresses {partner}. They want to see you again!",
					"The conversation flows easily. This is going great!",
				},
				effects = { Happiness = 15, Relationship = 15 },
			},
			{
				text = "Be honest and vulnerable",
				feedback = {
					"Your authenticity touches {partner}. They appreciate your openness.",
					"{partner} opens up too. You feel a real connection forming.",
					"Being real pays off. {partner} likes the genuine you.",
				},
				effects = { Happiness = 12, Relationship = 18 },
			},
			{
				text = "Keep it casual",
				feedback = {
					"You have a pleasant conversation. Nothing too deep.",
					"It's a nice first meeting, but no sparks yet.",
					"You both agree to see how things go.",
				},
				effects = { Happiness = 8, Relationship = 8 },
			},
			{
				text = "Talk about yourself non-stop",
				feedback = {
					"{partner} seems bored. Maybe you should have listened more.",
					"You realize too late you've been monopolizing the conversation.",
					"Oops. Not your best performance.",
				},
				effects = { Happiness = 3, Relationship = -5 },
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Perfect soulmate connection!",
				feedback = {
					"⚡ {partner} falls completely in love with you!",
					"⚡ It's like you've known each other forever!",
					"⚡ This is the beginning of something magical!",
				},
				effects = { Happiness = 30, Relationship = 50 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				setFlags = { soulmate_found = true, perfect_relationship = true },
			},
		},
	},
	-- Event 2: Dinner date
	{
		id = "date_dinner",
		title = "🍽️ Fancy Dinner Date",
		texts = {
			"You take {partner} to an upscale restaurant for your first date.",
			"Candlelight flickers as you sit across from {partner} at the nicest restaurant in town.",
			"You wanted to impress {partner}, so you booked somewhere special.",
		},
		effects = { Happiness = {8, 18}, Relationship = {8, 18} },
		cost = 200,
		choices = {
			{
				text = "Order the most expensive wine",
				feedback = {
					"The sommelier brings an excellent vintage. Very impressive.",
					"{partner} is clearly impressed by your taste.",
					"You raise a toast to new beginnings.",
				},
				effects = { Happiness = 15, Relationship = 20 },
				cost = 150,
			},
			{
				text = "Focus on conversation over food",
				feedback = {
					"You barely notice what you're eating - the conversation is too good!",
					"Hours fly by as you talk about everything and nothing.",
					"The food is secondary to the connection you're building.",
				},
				effects = { Happiness = 18, Relationship = 22 },
			},
			{
				text = "Get food poisoning",
				feedback = {
					"Something didn't agree with you. The date ends early.",
					"How embarrassing! You spend the evening sick.",
					"Not the impression you wanted to make...",
				},
				effects = { Happiness = -10, Relationship = -5, Health = -10 },
			},
		},
	},
	-- Event 3: Movie date
	{
		id = "date_movie",
		title = "🎬 Movie Date",
		texts = {
			"You invite {partner} to see a movie together.",
			"The theater is dark as you sit next to {partner} with popcorn.",
			"Nothing says classic first date like dinner and a movie.",
		},
		effects = { Happiness = {5, 12}, Relationship = {5, 12} },
		cost = 50,
		choices = {
			{
				text = "Pick a romantic comedy",
				feedback = {
					"You both laugh at the same jokes. Great chemistry!",
					"The cute movie puts you both in a romantic mood.",
					"{partner} reaches for your hand during a sweet scene.",
				},
				effects = { Happiness = 12, Relationship = 15 },
			},
			{
				text = "Let them choose",
				feedback = {
					"{partner} appreciates that you care about their preferences.",
					"Whatever movie they picked, being together was the point.",
					"You showed you're considerate. Points earned.",
				},
				effects = { Happiness = 10, Relationship = 12 },
			},
			{
				text = "Pick a scary movie",
				feedback = {
					"Jump scares give you an excuse to get closer!",
					"{partner} grabs your arm during the scary parts.",
					"Maybe not the most romantic, but definitely memorable.",
				},
				effects = { Happiness = 8, Relationship = 10 },
			},
		},
	},
	-- Event 4: Activity date
	{
		id = "date_activity",
		title = "🎳 Fun Activity Date",
		texts = {
			"You take {partner} to do something fun and active.",
			"Instead of a boring dinner, you planned an adventure with {partner}!",
			"Time to show {partner} your fun side with an exciting activity.",
		},
		effects = { Happiness = {10, 20}, Relationship = {8, 15} },
		choices = {
			{
				text = "Go bowling",
				feedback = {
					"You have a blast competing with {partner}!",
					"Who cares about scores? You're having too much fun!",
					"High fives and playful trash talk make for a great date.",
				},
				effects = { Happiness = 15, Relationship = 12 },
			},
			{
				text = "Try mini golf",
				feedback = {
					"The silly obstacles give you plenty to laugh about.",
					"{partner} celebrates a hole-in-one with a victory dance!",
					"Perfect low-key activity for getting to know each other.",
				},
				effects = { Happiness = 14, Relationship = 14 },
			},
			{
				text = "Go to an arcade",
				feedback = {
					"You compete for the high score on every game!",
					"The prizes are cheap, but the memories are priceless.",
					"You win {partner} a stuffed animal. They love it!",
				},
				effects = { Happiness = 18, Relationship = 15 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- REGULAR DATE EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.RegularDate = {
	-- Event 1: Surprise date
	{
		id = "date_surprise",
		title = "🎉 Surprise Date Night",
		texts = {
			"You plan a surprise date for {partner}.",
			"{partner} has no idea what you have planned for tonight!",
			"You blindfold {partner} and lead them to somewhere special.",
		},
		effects = { Happiness = {10, 20}, Relationship = {10, 20} },
		choices = {
			{
				text = "Take them to their favorite place",
				feedback = {
					"{partner}'s face lights up! 'You remembered!'",
					"The fact that you know them so well means everything.",
					"This surprise shows how much you pay attention.",
				},
				effects = { Happiness = 18, Relationship = 25 },
			},
			{
				text = "Try somewhere completely new",
				feedback = {
					"The adventure of something new excites you both!",
					"You discover a new favorite spot together.",
					"Making new memories strengthens your bond.",
				},
				effects = { Happiness = 15, Relationship = 18 },
			},
			{
				text = "Plan an elaborate adventure",
				feedback = {
					"Multiple stops, each one better than the last!",
					"{partner} is overwhelmed by how much effort you put in.",
					"This is a date they'll never forget.",
				},
				effects = { Happiness = 22, Relationship = 28 },
			},
		},
	},
	-- Event 2: Cozy date
	{
		id = "date_cozy",
		title = "🏠 Cozy Night In",
		texts = {
			"You and {partner} decide to stay in tonight.",
			"Sometimes the best dates are at home with your favorite person.",
			"No need to go anywhere - you have everything you need right here.",
		},
		effects = { Happiness = {8, 15}, Relationship = {8, 15} },
		choices = {
			{
				text = "Cook dinner together",
				feedback = {
					"You make a mess but have so much fun!",
					"The food is mediocre but the company is perfect.",
					"Working together in the kitchen brings you closer.",
				},
				effects = { Happiness = 12, Relationship = 15 },
			},
			{
				text = "Binge-watch a series",
				feedback = {
					"You get hooked on a new show together!",
					"Cuddling on the couch is its own kind of romance.",
					"'Just one more episode!' - said five times.",
				},
				effects = { Happiness = 14, Relationship = 12 },
			},
			{
				text = "Play board games",
				feedback = {
					"Competition gets heated but stays fun!",
					"You learn a lot about each other through games.",
					"{partner} is surprisingly competitive!",
				},
				effects = { Happiness = 13, Relationship = 14 },
			},
		},
	},
	-- Event 3: Adventure date
	{
		id = "date_adventure",
		title = "🌄 Adventure Together",
		texts = {
			"You plan an exciting outdoor adventure with {partner}.",
			"Time to get out of your comfort zone together!",
			"Adventures are better when you have someone to share them with.",
		},
		effects = { Happiness = {12, 25}, Relationship = {10, 20} },
		choices = {
			{
				text = "Go hiking",
				feedback = {
					"The view at the top makes the climb worth it!",
					"Being in nature together is incredibly peaceful.",
					"You share a kiss at the summit!",
				},
				effects = { Happiness = 18, Relationship = 20, Health = 10 },
			},
			{
				text = "Try something extreme",
				feedback = {
					"Adrenaline pumps through you both!",
					"Conquering fear together bonds you like nothing else.",
					"You'll never forget this experience!",
				},
				effects = { Happiness = 22, Relationship = 25 },
			},
			{
				text = "Beach day",
				feedback = {
					"Sun, sand, and your favorite person. Perfect!",
					"You build sandcastles like kids.",
					"Watching the sunset together is magical.",
				},
				effects = { Happiness = 16, Relationship = 18 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROPOSAL EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.Proposal = {
	-- Event 1: Classic proposal
	{
		id = "proposal_classic",
		title = "💍 The Big Question",
		texts = {
			"Your heart is pounding. It's time to ask {partner} to marry you.",
			"You've been planning this moment for weeks. The ring is in your pocket.",
			"This is it. The most important question of your life.",
		},
		effects = { Happiness = {20, 50}, Relationship = {20, 40} },
		choices = {
			{
				text = "Get down on one knee",
				feedback = {
					"'Will you marry me?' Tears well up in {partner}'s eyes.",
					"Time seems to stop as you wait for their answer...",
					"The moment is perfect. This memory will last forever.",
				},
				effects = { Happiness = 40, Relationship = 40 },
			},
			{
				text = "Give a heartfelt speech first",
				feedback = {
					"You pour your heart out about your love and future together.",
					"{partner} is overwhelmed by your beautiful words.",
					"'I've never felt more loved,' {partner} says through tears.",
				},
				effects = { Happiness = 45, Relationship = 45 },
			},
			{
				text = "Pop the question casually",
				feedback = {
					"'So... want to get married?' Simple but sincere.",
					"Not every proposal needs fireworks. Sometimes simple is perfect.",
					"{partner} laughs and says yes!",
				},
				effects = { Happiness = 35, Relationship = 38 },
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Guaranteed YES!",
				feedback = {
					"⚡ {partner} IMMEDIATELY says YES!",
					"⚡ It's the most romantic moment ever!",
					"⚡ They've never been more certain of anything!",
				},
				effects = { Happiness = 60, Relationship = 60 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				setFlags = { engaged = true, perfect_proposal = true },
			},
		},
	},
	-- Event 2: Elaborate proposal
	{
		id = "proposal_elaborate",
		title = "✨ Grand Gesture Proposal",
		texts = {
			"You've planned an elaborate proposal for {partner}.",
			"Friends and family are hidden, waiting for your signal.",
			"Everything is set for the most memorable proposal ever.",
		},
		effects = { Happiness = {25, 60}, Relationship = {25, 50} },
		cost = 1000,
		choices = {
			{
				text = "Surprise flash mob",
				feedback = {
					"Dancers appear out of nowhere! {partner} is speechless!",
					"The music builds as you take {partner}'s hand...",
					"Everyone applauds as {partner} says YES!",
				},
				effects = { Happiness = 50, Relationship = 50 },
			},
			{
				text = "Propose at a special location",
				feedback = {
					"This place means everything to your relationship.",
					"{partner} recognizes where you are and starts crying!",
					"The perfect place for the perfect moment.",
				},
				effects = { Happiness = 48, Relationship = 52 },
			},
			{
				text = "Skywriting/Billboard",
				feedback = {
					"Everyone in the city can see your love declaration!",
					"{partner} can't believe you did something this big!",
					"Grand gesture successful! They said YES!",
				},
				effects = { Happiness = 55, Relationship = 48 },
			},
		},
	},
	-- Event 3: Receiving a proposal
	{
		id = "proposal_receiving",
		title = "💕 They Proposed!",
		texts = {
			"{partner} gets down on one knee in front of you!",
			"Is this really happening? {partner} is holding a ring!",
			"'Will you marry me?' Your heart stops.",
		},
		effects = { Happiness = {20, 50} },
		choices = {
			{
				text = "Say YES!",
				feedback = {
					"You throw your arms around {partner}! Of course!",
					"This is the happiest moment of your life!",
					"You're engaged! Dreams really do come true!",
				},
				effects = { Happiness = 50, Relationship = 50 },
			},
			{
				text = "Ask for time to think",
				feedback = {
					"It's a big decision. You need to be sure.",
					"{partner} looks hurt but understands.",
					"The mood is awkward now...",
				},
				effects = { Happiness = -5, Relationship = -20 },
			},
			{
				text = "Say no",
				feedback = {
					"'I'm sorry, but I can't...' {partner}'s face falls.",
					"This is the hardest thing you've ever done.",
					"The relationship may never recover from this.",
				},
				effects = { Happiness = -30, Relationship = -50 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- BREAKUP EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.Breakup = {
	-- Event 1: You break up with them
	{
		id = "breakup_initiate",
		title = "💔 Time to Break Up",
		texts = {
			"You've decided it's time to end things with {partner}.",
			"This relationship isn't working anymore. You need to move on.",
			"The hardest conversations are sometimes necessary.",
		},
		effects = { Happiness = {-30, -10}, Relationship = {-100, -50} },
		choices = {
			{
				text = "Be honest and direct",
				feedback = {
					"You explain your feelings clearly and respectfully.",
					"It hurts, but {partner} deserves the truth.",
					"Sometimes love isn't enough. You both know it.",
				},
				effects = { Happiness = -15, Relationship = -60 },
			},
			{
				text = "Let them down gently",
				feedback = {
					"You try to soften the blow as much as possible.",
					"'It's not you, it's me,' you say. Is that ever helpful?",
					"{partner} cries, but appreciates your kindness.",
				},
				effects = { Happiness = -18, Relationship = -50 },
			},
			{
				text = "Ghost them",
				feedback = {
					"You just... stop responding. Take the easy way out.",
					"Cowardly, but at least you avoid the confrontation.",
					"They'll figure it out eventually.",
				},
				effects = { Happiness = -10, Relationship = -100 },
			},
			{
				text = "Pick a fight and leave",
				feedback = {
					"You start an argument and use it as an excuse to go.",
					"Easier to leave when you're angry.",
					"Not your proudest moment, but it's over.",
				},
				effects = { Happiness = -25, Relationship = -80 },
			},
		},
	},
	-- Event 2: They break up with you
	{
		id = "breakup_receiving",
		title = "😢 They're Breaking Up With You",
		texts = {
			"'We need to talk...' {partner}'s tone says it all.",
			"{partner} sits you down with a serious expression.",
			"You can tell something is wrong. Very wrong.",
		},
		effects = { Happiness = {-40, -20} },
		choices = {
			{
				text = "Accept it gracefully",
				feedback = {
					"You're heartbroken but you understand.",
					"'I hope you find what you're looking for,' you say.",
					"It's over. Time to heal and move on.",
				},
				effects = { Happiness = -25, Relationship = -100 },
			},
			{
				text = "Beg them to stay",
				feedback = {
					"'Please don't leave! I'll change!' you plead.",
					"They look at you with pity. Their mind is made up.",
					"Desperation rarely changes anything.",
				},
				effects = { Happiness = -35, Relationship = -100 },
			},
			{
				text = "Get angry",
				feedback = {
					"'Fine! I never needed you anyway!' you shout.",
					"Anger masks the pain, but it's still there.",
					"You storm off before they can see you cry.",
				},
				effects = { Happiness = -30, Relationship = -100 },
			},
		},
	},
	-- Event 3: Mutual breakup
	{
		id = "breakup_mutual",
		title = "🤝 Mutual Decision",
		texts = {
			"You both know this isn't working anymore.",
			"The spark is gone. You're better as friends.",
			"Sometimes relationships just run their course.",
		},
		effects = { Happiness = {-20, -5}, Relationship = {-80, -40} },
		choices = {
			{
				text = "Stay friends",
				feedback = {
					"You agree to remain in each other's lives.",
					"It's different now, but you still care about each other.",
					"Some connections are meant to evolve, not end.",
				},
				effects = { Happiness = -8, Relationship = -40 },
			},
			{
				text = "Make a clean break",
				feedback = {
					"No contact is probably healthier for both of you.",
					"It's hard, but necessary for moving forward.",
					"Goodbye is never easy, even when it's right.",
				},
				effects = { Happiness = -15, Relationship = -100 },
			},
			{
				text = "Take a break first",
				feedback = {
					"Maybe some time apart will give you clarity.",
					"You agree to separate for now, see how you feel.",
					"The relationship is on pause. Not over, but not together.",
				},
				effects = { Happiness = -10, Relationship = -30 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FLIRT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.Flirt = {
	-- Event 1: Flirt with someone new
	{
		id = "flirt_new",
		title = "😏 Flirting",
		texts = {
			"You see someone attractive across the room.",
			"Your eyes meet with a stranger. There's chemistry.",
			"Maybe it's time to put yourself out there.",
		},
		effects = { Happiness = {3, 10} },
		choices = {
			{
				text = "Use a cheesy pickup line",
				feedback = {
					"'Are you a parking ticket? Because you've got FINE written all over you!'",
					"They laugh. It's so bad it's good!",
					"Sometimes confidence beats quality.",
				},
				effects = { Happiness = 8 },
			},
			{
				text = "Just smile and say hi",
				feedback = {
					"Simple works. They smile back!",
					"'Hi, I'm [your name].' Sometimes that's all you need.",
					"They seem interested in talking more.",
				},
				effects = { Happiness = 10 },
			},
			{
				text = "Do nothing (too nervous)",
				feedback = {
					"You chicken out. Maybe next time.",
					"The opportunity passes. They leave.",
					"Regret is worse than rejection, they say...",
				},
				effects = { Happiness = -3 },
			},
		},
	},
	-- Event 2: Flirt with partner
	{
		id = "flirt_partner",
		title = "💕 Flirting With {partner}",
		texts = {
			"You catch {partner}'s eye and give them a playful wink.",
			"Time to remind {partner} why they fell for you.",
			"Keeping the spark alive means never stopping the chase.",
		},
		effects = { Happiness = {5, 12}, Relationship = {5, 12} },
		choices = {
			{
				text = "Compliment them sincerely",
				feedback = {
					"'You look amazing today,' you say. {partner} blushes!",
					"Genuine compliments never get old.",
					"{partner} feels loved and appreciated.",
				},
				effects = { Happiness = 10, Relationship = 15 },
			},
			{
				text = "Be playfully teasing",
				feedback = {
					"You gently tease {partner} and they play along.",
					"Banter is your love language.",
					"You both end up laughing.",
				},
				effects = { Happiness = 12, Relationship = 10 },
			},
			{
				text = "Physical affection",
				feedback = {
					"You hold {partner}'s hand and pull them close.",
					"Sometimes actions speak louder than words.",
					"The warmth between you is palpable.",
				},
				effects = { Happiness = 15, Relationship = 18 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- GIFT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.Gift = {
	-- Event 1: Give a gift
	{
		id = "gift_give",
		title = "🎁 Giving a Gift",
		texts = {
			"You want to surprise {partner} with something special.",
			"It's time to show {partner} how much you care.",
			"A thoughtful gift can say what words can't.",
		},
		effects = { Relationship = {5, 25} },
		choices = {
			{
				text = "Buy jewelry",
				feedback = {
					"A beautiful piece that shows how much you care!",
					"{partner} is stunned by the beautiful gift!",
					"This gift will be treasured forever.",
				},
				effects = { Relationship = 25, Happiness = 15 },
				cost = 500,
			},
			{
				text = "Give flowers",
				feedback = {
					"Classic romance never goes out of style!",
					"{partner}'s face lights up at the beautiful bouquet.",
					"'You're so sweet!' {partner} says.",
				},
				effects = { Relationship = 15, Happiness = 10 },
				cost = 50,
			},
			{
				text = "Make something personal",
				feedback = {
					"A handmade gift from the heart means everything.",
					"The effort you put in shows how much you care.",
					"{partner} is moved by your thoughtfulness.",
				},
				effects = { Relationship = 20, Happiness = 12 },
			},
			{
				text = "Gift card (lazy choice)",
				feedback = {
					"'Um, thanks?' {partner} tries to seem grateful.",
					"Not exactly romantic, but hey, it's practical.",
					"Next time, maybe put in more thought...",
				},
				effects = { Relationship = 3 },
				cost = 25,
			},
		},
	},
	-- Event 2: Receive a gift
	{
		id = "gift_receive",
		title = "🎀 {partner} Gave You Something!",
		texts = {
			"{partner} hands you a beautifully wrapped gift!",
			"'I saw this and thought of you,' {partner} says.",
			"A surprise gift from your love!",
		},
		effects = { Happiness = {10, 20}, Relationship = {5, 15} },
		choices = {
			{
				text = "Love it! (genuine)",
				feedback = {
					"It's exactly what you wanted! They know you so well!",
					"Your genuine excitement makes {partner} happy.",
					"This gift shows how well they understand you.",
				},
				effects = { Happiness = 20, Relationship = 15 },
			},
			{
				text = "Pretend to love it",
				feedback = {
					"It's... interesting. You smile and say thank you.",
					"The thought counts more than the gift, right?",
					"{partner} seems happy that you're happy.",
				},
				effects = { Happiness = 5, Relationship = 8 },
			},
			{
				text = "Be honest you don't like it",
				feedback = {
					"'I appreciate it, but it's not really my style...'",
					"{partner} looks a bit hurt but respects your honesty.",
					"At least they know for next time?",
				},
				effects = { Happiness = 3, Relationship = -5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ARGUMENT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.Argument = {
	-- Event 1: Fight about something
	{
		id = "argument_generic",
		title = "😤 Relationship Argument",
		texts = {
			"You and {partner} are having a heated disagreement.",
			"Tensions rise as the argument escalates.",
			"This is turning into a real fight.",
		},
		effects = { Happiness = {-15, -5}, Relationship = {-20, -5} },
		choices = {
			{
				text = "Apologize to end it",
				feedback = {
					"'I'm sorry, you're right.' The tension eases.",
					"Being the bigger person isn't always easy.",
					"The fight ends, but feelings linger.",
				},
				effects = { Happiness = -5, Relationship = -5 },
			},
			{
				text = "Stand your ground",
				feedback = {
					"You believe you're right and won't back down!",
					"The argument continues. Neither will budge.",
					"This might take a while to resolve...",
				},
				effects = { Happiness = -10, Relationship = -15 },
			},
			{
				text = "Walk away to cool off",
				feedback = {
					"You need space before saying something you'll regret.",
					"Taking a break from the argument is smart.",
					"You'll discuss this when you're both calmer.",
				},
				effects = { Happiness = -8, Relationship = -8 },
			},
			{
				text = "Say something hurtful",
				feedback = {
					"Words meant to wound fly out of your mouth.",
					"{partner} looks shocked and hurt.",
					"You went too far. This will be hard to fix.",
				},
				effects = { Happiness = -15, Relationship = -30 },
			},
		},
	},
	-- Event 2: Jealousy argument
	{
		id = "argument_jealousy",
		title = "😡 Jealousy Issues",
		texts = {
			"'{partner}' saw you talking to someone attractive.",
			"Your partner is jealous and confronting you.",
			"Trust issues are surfacing in your relationship.",
		},
		effects = { Happiness = {-12, -5}, Relationship = {-15, -5} },
		choices = {
			{
				text = "Reassure them you're faithful",
				feedback = {
					"'I only have eyes for you,' you say sincerely.",
					"Your reassurance calms their fears.",
					"Trust needs to be earned and maintained.",
				},
				effects = { Happiness = -3, Relationship = 5 },
			},
			{
				text = "Tell them they're being irrational",
				feedback = {
					"'You're overreacting!' Wrong thing to say...",
					"Dismissing feelings never helps.",
					"The argument gets worse.",
				},
				effects = { Happiness = -10, Relationship = -20 },
			},
			{
				text = "Turn it around on them",
				feedback = {
					"'What about when YOU talked to...?' Deflection mode.",
					"Two wrongs don't make a right, but...",
					"Now you're both mad.",
				},
				effects = { Happiness = -12, Relationship = -18 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAKEUP EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.Makeup = {
	-- Event 1: Making up after fight
	{
		id = "makeup_after_fight",
		title = "💕 Making Up",
		texts = {
			"It's time to reconcile after your argument with {partner}.",
			"The fight is over. Now to repair the damage.",
			"You miss {partner}. Time to make things right.",
		},
		effects = { Happiness = {10, 25}, Relationship = {10, 25} },
		choices = {
			{
				text = "Sincerely apologize",
				feedback = {
					"'I was wrong and I'm truly sorry.' Healing begins.",
					"{partner} accepts your apology and opens their arms.",
					"Making up feels even better than never fighting.",
				},
				effects = { Happiness = 20, Relationship = 25 },
			},
			{
				text = "Bring a peace offering",
				feedback = {
					"Flowers/their favorite thing shows you're thinking of them.",
					"Actions speak louder than words sometimes.",
					"{partner} appreciates the gesture.",
				},
				effects = { Happiness = 18, Relationship = 20 },
			},
			{
				text = "Just hold them",
				feedback = {
					"No words needed. You pull {partner} into a hug.",
					"Sometimes physical connection says it all.",
					"You hold each other until everything feels okay again.",
				},
				effects = { Happiness = 22, Relationship = 28 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ANNIVERSARY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.Anniversary = {
	-- Event 1: Celebrate anniversary
	{
		id = "anniversary_celebrate",
		title = "🎊 Anniversary!",
		texts = {
			"It's your anniversary with {partner}!",
			"Another year of love to celebrate!",
			"Time flies when you're with the right person.",
		},
		effects = { Happiness = {15, 30}, Relationship = {15, 30} },
		choices = {
			{
				text = "Plan an extravagant celebration",
				feedback = {
					"You go all out! Fancy dinner, gifts, the works!",
					"{partner} feels incredibly special and loved.",
					"A night to remember for years to come!",
				},
				effects = { Happiness = 30, Relationship = 35 },
				cost = 500,
			},
			{
				text = "Keep it intimate and personal",
				feedback = {
					"A quiet celebration, just the two of you.",
					"You reminisce about your journey together.",
					"Simple but meaningful. Perfect.",
				},
				effects = { Happiness = 25, Relationship = 30 },
			},
			{
				text = "Forget... and scramble to recover",
				feedback = {
					"Oh no! You forgot the anniversary!",
					"Quick recovery mode engaged! Damage control!",
					"{partner} is disappointed but forgives you... mostly.",
				},
				effects = { Happiness = 5, Relationship = -10 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MEET FAMILY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.MeetFamily = {
	-- Event 1: Meet their parents
	{
		id = "meet_parents",
		title = "👨‍👩‍👧 Meeting The Parents",
		texts = {
			"It's time to meet {partner}'s parents.",
			"The moment you've been dreading... meeting the family.",
			"This could make or break the relationship.",
		},
		effects = { Happiness = {-5, 15}, Relationship = {5, 20} },
		choices = {
			{
				text = "Be charming and polite",
				feedback = {
					"You're on your best behavior and it shows!",
					"The parents seem impressed by you.",
					"'We like this one!' they whisper to {partner}.",
				},
				effects = { Happiness = 15, Relationship = 20 },
			},
			{
				text = "Bring a nice gift",
				feedback = {
					"A thoughtful gift for the hosts makes a great impression.",
					"'You didn't have to!' But they're clearly pleased.",
					"Good first impression achieved.",
				},
				effects = { Happiness = 12, Relationship = 15 },
			},
			{
				text = "Be yourself completely",
				feedback = {
					"No pretending. If they don't like you, too bad!",
					"Your authenticity is either refreshing or concerning...",
					"{partner} appreciates that you didn't fake it.",
				},
				effects = { Happiness = 10, Relationship = 12 },
			},
			{
				text = "Get nervous and mess up",
				feedback = {
					"You spill something, say something awkward, panic!",
					"The evening is a disaster of awkward moments.",
					"At least it makes for a funny story later?",
				},
				effects = { Happiness = -5, Relationship = 5 },
			},
		},
	},
	-- Event 2: Family dinner
	{
		id = "family_dinner",
		title = "🍽️ Family Dinner",
		texts = {
			"The whole family is gathering for dinner.",
			"Time to show everyone how great you and {partner} are together.",
			"Family events can be stressful but important.",
		},
		effects = { Happiness = {5, 15}, Relationship = {5, 15} },
		choices = {
			{
				text = "Help in the kitchen",
				feedback = {
					"You offer to help prepare the meal. Points earned!",
					"The family appreciates your willingness to pitch in.",
					"Domestic skills impress everyone.",
				},
				effects = { Happiness = 12, Relationship = 15 },
			},
			{
				text = "Engage in conversation",
				feedback = {
					"You chat with family members and make connections.",
					"Finding common interests builds bridges.",
					"By the end, you feel like part of the family.",
				},
				effects = { Happiness = 14, Relationship = 18 },
			},
			{
				text = "Stay quiet and observe",
				feedback = {
					"You let others do the talking and just watch.",
					"Safe approach, but you might seem distant.",
					"At least you didn't say anything wrong?",
				},
				effects = { Happiness = 5, Relationship = 8 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- LONG DISTANCE EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.LongDistance = {
	-- Event 1: Missing them
	{
		id = "long_distance_miss",
		title = "📞 Missing {partner}",
		texts = {
			"Being far from {partner} is hard.",
			"You stare at your phone, wishing they were here.",
			"Long distance relationships take work.",
		},
		effects = { Happiness = {-10, 5}, Relationship = {-5, 10} },
		choices = {
			{
				text = "Video call them",
				feedback = {
					"Seeing their face, even on a screen, helps!",
					"You talk for hours about everything and nothing.",
					"Technology makes distance more bearable.",
				},
				effects = { Happiness = 10, Relationship = 12 },
			},
			{
				text = "Send a care package",
				feedback = {
					"A box full of their favorite things and your love!",
					"They'll know you're thinking of them.",
					"Distance doesn't diminish thoughtfulness.",
				},
				effects = { Happiness = 8, Relationship = 15 },
			},
			{
				text = "Plan a visit",
				feedback = {
					"Counting down the days until you see them again!",
					"Having something to look forward to helps.",
					"Reunions will be extra sweet!",
				},
				effects = { Happiness = 15, Relationship = 10 },
			},
		},
	},
	-- Event 2: Reunion
	{
		id = "long_distance_reunion",
		title = "🤗 Finally Together Again!",
		texts = {
			"After what felt like forever, you're finally reunited with {partner}!",
			"You spot {partner} at the airport and run to them!",
			"The distance made your hearts grow even fonder.",
		},
		effects = { Happiness = {20, 40}, Relationship = {15, 30} },
		choices = {
			{
				text = "Never let go",
				feedback = {
					"You hold {partner} like you'll never let go!",
					"Time stops as you embrace each other.",
					"This feeling makes all the waiting worth it.",
				},
				effects = { Happiness = 40, Relationship = 30 },
			},
			{
				text = "Plan every moment together",
				feedback = {
					"You have limited time, so make it count!",
					"Every second is precious when you're reunited.",
					"An unforgettable time together!",
				},
				effects = { Happiness = 35, Relationship = 25 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAPPING TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
RomanceEvents.ActivityMapping = {
	["first_date"] = "FirstDate",
	["date"] = "RegularDate",
	["go_on_date"] = "RegularDate",
	["propose"] = "Proposal",
	["proposal"] = "Proposal",
	["get_engaged"] = "Proposal",
	["break_up"] = "Breakup",
	["breakup"] = "Breakup",
	["end_relationship"] = "Breakup",
	["flirt"] = "Flirt",
	["compliment"] = "Flirt",
	["give_gift"] = "Gift",
	["gift"] = "Gift",
	["present"] = "Gift",
	["argue"] = "Argument",
	["argument"] = "Argument",
	["fight"] = "Argument",
	["make_up"] = "Makeup",
	["apologize"] = "Makeup",
	["reconcile"] = "Makeup",
	["anniversary"] = "Anniversary",
	["celebrate"] = "Anniversary",
	["meet_family"] = "MeetFamily",
	["meet_parents"] = "MeetFamily",
	["long_distance"] = "LongDistance",
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════
function RomanceEvents.getEventForActivity(activityId, partnerName)
	local categoryName = RomanceEvents.ActivityMapping[activityId]
	if not categoryName then
		-- Try partial matching
		for key, cat in pairs(RomanceEvents.ActivityMapping) do
			if string.find(activityId, key) or string.find(key, activityId) then
				categoryName = cat
				break
			end
		end
	end
	
	if not categoryName then
		return nil
	end
	
	local eventList = RomanceEvents[categoryName]
	if not eventList or #eventList == 0 then
		return nil
	end
	
	-- Get random event
	local event = eventList[math.random(1, #eventList)]
	
	-- Replace {partner} placeholders with actual name
	if partnerName and event then
		-- Deep copy and replace
		local processedEvent = {}
		for k, v in pairs(event) do
			if type(v) == "string" then
				processedEvent[k] = string.gsub(v, "{partner}", partnerName)
			elseif type(v) == "table" then
				processedEvent[k] = {}
				for i, item in ipairs(v) do
					if type(item) == "string" then
						processedEvent[k][i] = string.gsub(item, "{partner}", partnerName)
					else
						processedEvent[k][i] = item
					end
				end
			else
				processedEvent[k] = v
			end
		end
		return processedEvent
	end
	
	return event
end

function RomanceEvents.getAllCategories()
	return {"FirstDate", "RegularDate", "Proposal", "Breakup", "Flirt", "Gift", "Argument", "Makeup", "Anniversary", "MeetFamily", "LongDistance"}
end

return RomanceEvents
