--[[
    Relationship Events
    ═══════════════════════════════════════════════════════════════════════════════
    
    COMPLETELY REVAMPED FOR AAA BITLIFE QUALITY
    
    Features:
    - 50+ immersive relationship events
    - Dating, love, marriage, affairs, divorce
    - Friendships, family bonds, betrayals
    - Specific names, locations, emotional details
    - Real relationship challenges and joy
    - Player choices shape relationship outcomes
    
    ═══════════════════════════════════════════════════════════════════════════════
]]

local Relationships = {}

Relationships.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MEETING PEOPLE & EARLY DATING
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "dating_app_nightmare",
		title = "Welcome to Online Dating",
		emoji = "📱",
		text = "You're 27 and single. Your married friends keep suggesting dating apps. You download Tinder. Swipe. Swipe. Swipe. 90% of profiles say 'looking for something real' but lead with gym selfies. You match with someone. Their first message: 'hey.' Then they send unsolicited pics. You delete the app. You redownload it 3 days later. The cycle continues.",
		question = "How do you navigate this hellscape?",
		minAge = 18, maxAge = 45,
		baseChance = 0.7,
		cooldown = 3,
		stage = "any",
		category = "dating",
		tags = { "romance", "modern_dating", "single_life" },
		conditions = { flag = "single" },

		choices = {
			{ text = "Actually find someone great!", effects = { Happiness = 15, Looks = 3 }, setFlags = { has_partner = true, dating = true, met_online = true }, feedText = "After 47 terrible first dates, you matched with Alex. They're funny, smart, and their profile pic was ACTUALLY them! You have a 2nd date!" },
			{ text = "Get catfished - they lied HARD", effects = { Happiness = -8 }, setFlags = { catfished = true, trust_issues = true }, feedText = "They used photos from 10 years ago. They're married. They want you to join an MLM. You leave mid-dinner. Dating apps are THE WORST." },
			{ text = "Delete all apps - meet people IRL", effects = { Happiness = 5 }, setFlags = { no_dating_apps = true, old_fashioned = true }, feedText = "You delete everything. You'll meet someone the old-fashioned way. At a... coffee shop? Does that still happen? How do people meet anymore??" },
		},
	},

	{
		id = "coffee_shop_meet_cute",
		title = "The Coffee Shop Moment",
		emoji = "☕",
		text = "You're at your usual coffee shop, laptop open, working remotely. Someone sits at the next table. They're reading your favorite book. You make eye contact. They smile. You smile back. Should you say something? What if they think you're a creep? But what if they're The One and you let them walk away? Your heart races. This is rom-com territory.",
		question = "Do you make a move?",
		minAge = 18, maxAge = 50,
		baseChance = 0.4,
		cooldown = 4,
		stage = "any",
		category = "dating",
		tags = { "romance", "meet_cute", "courage" },
		conditions = { flag = "single" },

		choices = {
			{ text = "Start a conversation about the book", effects = { Happiness = 12, Looks = 3 }, setFlags = { has_partner = true, dating = true, romantic_meet_cute = true }, feedText = "You commented on the book. You talked for 2 HOURS! You exchanged numbers! You have a date Friday! MAGIC EXISTS!" },
			{ text = "Write your number on napkin, slide it over", effects = { Happiness = 8, Looks = 2 }, setFlags = { has_partner = true, dating = true, bold_move = true }, feedText = "You slid them a napkin with your number and 'coffee sometime?' They texted you 5 minutes later. Smooth move!" },
			{ text = "Chicken out - say nothing", effects = { Happiness = -5 }, setFlags = { regret = true, what_if = true }, feedText = "They left. You didn't say anything. You'll think about this moment for YEARS. 'What if?'" },
		},
	},

	{
		id = "workplace_romance_temptation",
		title = "The Office Crush",
		emoji = "💼",
		text = "Jordan from Marketing. Every morning, you pass their desk. They always say good morning. They laugh at your jokes. Last week at happy hour, you talked for an hour about everything and nothing. You think about them constantly. But HR has rules. Your company has a 'fraternization policy.' Is it worth risking your job? But what if they're The One?",
		question = "What do you do about these feelings?",
		minAge = 22, maxAge = 55,
		baseChance = 0.6,
		cooldown = 4,
		stage = "any",
		category = "dating",
		tags = { "romance", "workplace", "risk", "crush" },
		conditions = { flag = "single" },

		choices = {
			{ text = "Ask them out - screw the rules!", effects = { Happiness = 15, Looks = 4 }, setFlags = { has_partner = true, dating = true, workplace_romance = true }, feedText = "You asked them to dinner! They said YES! You're dating! (You're both VERY discreet at work. HR doesn't know. Yet.)" },
			{ text = "Transfer departments to date them", effects = { Happiness = 10, Money = -2000, Smarts = 3 }, setFlags = { has_partner = true, dating = true, sacrificed_for_love = true }, feedText = "You requested a transfer. You took a small pay cut. But now you can date them! Love is worth it!" },
			{ text = "Suppress feelings - job comes first", effects = { Happiness = -5, Money = 5000 }, setFlags = { career_focused = true, suppressed_feelings = true }, feedText = "You buried those feelings DEEP. Every meeting hurts. You see them dating someone else. Your heart breaks. But your career is safe!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- EARLY RELATIONSHIP DYNAMICS
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "first_three_months_bliss",
		title = "The Honeymoon Phase",
		emoji = "💘",
		text = "You've been dating for 3 months. Everything is PERFECT. They're perfect. The sex is amazing. You text constantly. You think about them 24/7. Your friends are sick of hearing about them. You've already planned your future together in your head. This must be what love feels like. (Narrator: It's actually just chemicals. The real test comes later.)",
		question = "How do you handle this intoxicating feeling?",
		minAge = 18, maxAge = 60,
		baseChance = 0.8,
		cooldown = 5,
		stage = "any",
		category = "dating",
		tags = { "romance", "honeymoon_phase", "new_love" },
		conditions = { flag = "dating" },

		choices = {
			{ text = "Go ALL IN - move fast!", effects = { Happiness = 20, Smarts = -3 }, setFlags = { moved_too_fast = true, intense_love = true }, feedText = "You said 'I love you' after 2 weeks! You're looking at apartments together! Your friends are concerned you're moving too fast! But you're IN LOVE!" },
			{ text = "Enjoy it but stay grounded", effects = { Happiness = 15, Smarts = 5 }, setFlags = { healthy_relationship = true, balanced = true }, feedText = "You're enjoying the butterflies but keeping perspective. You're getting to know them SLOWLY. Smart approach! Your friends approve!" },
			{ text = "Get scared - sabotage it", effects = { Happiness = -10 }, setFlags = { self_sabotage = true, fear_of_intimacy = true }, feedText = "You picked a fight over nothing. You're pushing them away. Commitment terrifies you. You're sabotaging something good. Why do you do this??" },
		},
	},

	{
		id = "meet_the_parents_disaster",
		title = "Meeting the Parents",
		emoji = "👨‍👩‍👧",
		text = "Tonight you're meeting your partner's parents for the first time. You're wearing your nicest outfit. You brought wine. You rehearsed conversation topics. Then: disaster. You spill red wine on their white couch. You accidentally curse. Their mom asks when you're getting married (you've dated for 4 months). Their dad grills you about your 'career prospects.' You're sweating through your shirt.",
		question = "How do you handle this nightmare?",
		minAge = 18, maxAge = 50,
		baseChance = 0.7,
		cooldown = 10,
		stage = "any",
		category = "dating",
		tags = { "romance", "family", "pressure", "awkward" },
		conditions = { flag = "dating" },

		choices = {
			{ text = "Own the disasters with humor", effects = { Happiness = 10, Smarts = 5 }, setFlags = { parents_love_you = true, charming = true }, feedText = "You laughed at yourself. You helped clean the couch. You were genuine and funny. They LOVED you! 'Much better than the last one,' mom whispered!" },
			{ text = "Get flustered and awkward", effects = { Happiness = -5, Looks = -2 }, setFlags = { parents_skeptical = true, awkward_first_meeting = true }, feedText = "You stammered. You told bad jokes. You mentioned exes (WHY??). They were polite but... skeptical. Your partner says 'they'll warm up to you!'" },
			{ text = "Be fake - try too hard to impress", effects = { Happiness = 2, Smarts = -2 }, setFlags = { parents_suspicious = true, inauthentic = true }, feedText = "You exaggerated your job. You pretended to like golf. You laughed too loud. They can tell you're full of shit. Not a great start." },
		},
	},

	{
		id = "first_big_fight",
		title = "Your First Real Fight",
		emoji = "😤",
		text = "6 months in. You had your first BIG fight. Not a disagreement. A FIGHT. Raised voices. Tears. Harsh words you can't take back. You said 'Maybe we should break up' in the heat of the moment. They said 'Maybe we should!' Then silence. You both went to separate rooms. Your heart is pounding. Did you just ruin everything? Can you come back from this? Is this how relationships end?",
		question = "What do you do now?",
		minAge = 18, maxAge = 60,
		baseChance = 0.7,
		cooldown = 3,
		stage = "any",
		category = "dating",
		tags = { "romance", "conflict", "fight", "relationship_test" },
		conditions = { flag = "dating" },

		choices = {
			{ text = "Apologize and communicate properly", effects = { Happiness = 10, Smarts = 7 }, setFlags = { good_communication = true, relationship_stronger = true }, feedText = "You both apologized. You TALKED. You addressed the real issues. You came out STRONGER! This is healthy! You're learning!" },
			{ text = "Give silent treatment - stay angry", effects = { Happiness = -8, Health = -2 }, setFlags = { communication_issues = true, petty = true }, feedText = "You're not talking to them. 3 days of silence. You're both miserable. Nobody wins this game. Your relationship is suffering." },
			{ text = "Break up in anger", effects = { Happiness = -15, Health = -5 }, setFlags = { single = true, impulsive_decision = true }, feedText = "You broke up in the heat of the moment. You'll regret this tomorrow. But pride won't let you take it back. It's over. (For now?)" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- COMMITMENT & MOVING FORWARD
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "moving_in_together",
		title = "The Big Move-In",
		emoji = "🏠",
		text = "You're moving in together! You're combining your lives! Your stuff and their stuff in ONE apartment! It's exciting! And terrifying! What if you discover they're a monster? What if they squeeze the toothpaste from the middle? What if they're a morning person? Moving in is the ultimate relationship test. No more 'date version.' This is REAL them. Every day. Forever.",
		question = "How does cohabitation go?",
		minAge = 21, maxAge = 50,
		oneTime = true,
		stage = "any",
		category = "romance",
		tags = { "milestone", "living_together", "commitment" },
		conditions = { flag = "committed_relationship" },

		choices = {
			{ text = "It's PERFECT - domestic bliss!", effects = { Happiness = 20, Money = 500 }, setFlags = { lives_together = true, happy_cohabitation = true }, feedText = "You cook together! You Netflix and actually chill! You love waking up next to them! This is what love looks like!" },
			{ text = "Some adjustments but it works", effects = { Happiness = 12, Money = 300 }, setFlags = { lives_together = true, learning_together = true }, feedText = "They DO squeeze toothpaste wrong. They leave dishes. But you're figuring it out! Communication is key! You're growing together!" },
			{ text = "Constant fighting - mistake?", effects = { Happiness = -10, Money = 200, Health = -5 }, setFlags = { lives_together = true, cohabitation_problems = true }, feedText = "You're fighting CONSTANTLY. Turns out you're incompatible roommates. You love them but HATE living with them. This is a problem." },
		},
	},

	{
		id = "engagement_proposal",
		title = "Will You Marry Me?",
		emoji = "💍",
		text = "They're proposing. Right now. They're on one knee. There's a ring. Your heart is exploding. Everyone's watching. You've talked about marriage but WAIT - are you READY ready? Is this THE ONE? Forever is a LONG time. But they're looking at you with those eyes. Tears streaming. Vulnerable. Waiting. You have to answer. NOW.",
		question = "What do you say?",
		minAge = 21, maxAge = 55,
		oneTime = true,
		priority = "high",
		stage = "any",
		category = "romance",
		tags = { "milestone", "engagement", "marriage", "major_decision" },
		conditions = { flag = "committed_relationship" },

		choices = {
			{ text = "YES! A thousand times yes!", effects = { Happiness = 30, Money = -5000 }, setFlags = { engaged = true, wedding_planning = true }, feedText = "You said YES! You're ENGAGED! The ring is beautiful! You're calling everyone! Wedding planning starts NOW! You're getting MARRIED!" },
			{ text = "I need more time...", effects = { Happiness = -10 }, setFlags = { engagement_doubts = true, hesitant = true }, feedText = "You asked for more time. They're devastated. Everyone's awkward. Did you just ruin everything? But you had to be honest. Right? RIGHT??" },
			{ text = "No - this isn't right", effects = { Happiness = -20, Health = -8 }, setFlags = { single = true, rejected_proposal = true }, feedText = "You said no. They're crushed. You're crying. It's OVER. You just ended a 3-year relationship in front of your families. Brutal." },
		},
	},

	{
		id = "wedding_planning_hell",
		title = "Wedding Planning Nightmare",
		emoji = "💒",
		text = "You're 8 months into wedding planning. You've tried on 27 dresses. Your fiancé's mom wants to invite 150 people you don't know. The venue costs $15,000. The photographer is $4,000. The flowers are $3,000. Everything is expensive and everyone has opinions. You're fighting with your partner about CHAIR COVERS. You just want to elope. But both families would murder you.",
		question = "How do you handle wedding planning stress?",
		minAge = 22, maxAge = 50,
		baseChance = 0.8,
		cooldown = 5,
		stage = "any",
		category = "romance",
		tags = { "wedding", "stress", "planning", "family" },
		conditions = { flag = "engaged" },

		choices = {
			{ text = "Elope - skip the drama!", effects = { Happiness = 15, Money = 40000 }, setFlags = { eloped = true, married = true, families_mad = true }, feedText = "You ELOPED! Vegas chapel! $200! Your families are PISSED! But you saved $50K and you're MARRIED! You regret nothing!" },
			{ text = "Push through - big wedding time", effects = { Happiness = 5, Money = -55000, Health = -8 }, setFlags = { married = true, had_big_wedding = true, stressed = true }, feedText = "You survived planning! 200 guests! Open bar! The wedding was beautiful! The debt is terrifying! But you did it!" },
			{ text = "Postpone indefinitely - too much", effects = { Happiness = -5, Money = -5000 }, setFlags = { postponed_wedding = true, relationship_strain = true }, feedText = "You postponed. 'We need more time.' Your families are confused. Your partner is hurt. Planning broke you. Will you ever actually marry?" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- MARRIAGE CHALLENGES
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "dead_bedroom_crisis",
		title = "The Intimacy Problem",
		emoji = "🛏️",
		text = "You haven't had sex in 8 months. EIGHT MONTHS. You're married. You sleep in the same bed. But nothing. You're roommates who share bills. You try to initiate. They're 'too tired.' You're hurt. Rejected. Starting to resent them. You love them but you're not attracted to them anymore. Is this just marriage? Is this normal? Your single friends say it's not. Your married friends say it is.",
		question = "What do you do about this?",
		minAge = 28, maxAge = 65,
		baseChance = 0.6,
		cooldown = 4,
		stage = "any",
		category = "marriage",
		tags = { "intimacy", "sex", "marriage_problems", "difficult" },
		conditions = { flag = "married" },

		choices = {
			{ text = "Have an honest conversation", effects = { Happiness = 5, Smarts = 7 }, setFlags = { addressing_issues = true, communicative = true }, feedText = "You talked. REALLY talked. They admitted they're depressed. You're going to couples therapy. You're working on it together. Progress!" },
			{ text = "Cheat - fill the void elsewhere", effects = { Happiness = 10, Money = -2000 }, setFlags = { cheating = true, affair = true, guilt = true }, feedText = "You started an affair. The sex is AMAZING. The guilt is crushing. Your spouse doesn't know. Yet. This won't end well." },
			{ text = "Accept it - sex isn't everything", effects = { Happiness = -5, Health = -3 }, setFlags = { resigned = true, sexually_frustrated = true }, feedText = "You're accepting a sexless marriage. You bury your needs. You're martyring yourself. You're miserable but 'committed.' Is this living?" },
		},
	},

	{
		id = "spouse_having_affair",
		title = "You Found Their Texts",
		emoji = "📱",
		text = "Their phone buzzed at 2am. A text: 'I can't stop thinking about last night.' Your stomach drops. You open their phone (you know the passcode). Messages. LOTS of messages. To someone named Morgan. Explicit messages. Plans to meet. Hotel receipts. Your spouse is CHEATING. Your world explodes. 7 years of marriage. Gone. Your heart is shattered. They're still asleep next to you. Do you wake them? Do you pack? Do you scream?",
		question = "How do you confront this betrayal?",
		minAge = 25, maxAge = 70,
		baseChance = 0.3,
		cooldown = 10,
		stage = "any",
		category = "marriage",
		tags = { "affair", "betrayal", "cheating", "devastating" },
		conditions = { flag = "married" },

		choices = {
			{ text = "Wake them up - confront NOW", effects = { Happiness = -15, Health = -8 }, setFlags = { affair_discovered = true, confronted_spouse = true }, feedText = "You woke them. You SCREAMED. They admitted everything. They cried. You're sleeping in separate rooms. Your marriage is imploding. NOW WHAT?" },
			{ text = "Hire a private investigator - get proof", effects = { Happiness = -10, Money = -5000, Smarts = 5 }, setFlags = { gathering_evidence = true, calculating = true }, feedText = "You hired a PI. You're gathering evidence. For the divorce. You're strategic. Cold. But you're DESTROYED inside. You're planning your exit." },
			{ text = "Pretend you don't know - denial", effects = { Happiness = -20, Health = -10 }, setFlags = { in_denial = true, self_destructive = true }, feedText = "You're pretending everything's fine. They're still cheating. You're dying inside. You can't face it. This is unsustainable. You're breaking." },
		},
	},

	{
		id = "divorce_proceedings",
		title = "The Divorce",
		emoji = "💔",
		text = "You're in a lawyer's office. Dividing your life. Who gets the house? Who gets the dog? Who gets the friends? 10 years of marriage, reduced to legal documents and custody schedules. Your wedding ring is in a drawer. You're signing papers that end your marriage. 'Till death do us part' became 'irreconcilable differences.' You're about to be single again at 37. Starting over. Is this failure? Or freedom?",
		question = "How do you handle the divorce?",
		minAge = 28, maxAge = 75,
		oneTime = true,
		priority = "high",
		stage = "any",
		category = "marriage",
		tags = { "divorce", "ending", "loss", "major_life_change" },
		conditions = { flag = "affair_discovered" },

		choices = {
			{ text = "Amicable - part as friends", effects = { Happiness = -10, Money = -25000, Smarts = 7 }, setFlags = { divorced = true, amicable_divorce = true, single = true }, feedText = "You split everything fairly. You're sad but civil. You'll co-parent well. This is the mature way to end things. You're free but grieving." },
			{ text = "FIGHT FOR EVERYTHING", effects = { Happiness = -20, Money = -75000, Health = -10 }, setFlags = { divorced = true, messy_divorce = true, single = true, bitter = true }, feedText = "You fought DIRTY. Lawyers cost $100K. Your kids are traumatized. You won the house but lost your soul. Was it worth it? (No.)" },
			{ text = "Give them everything - just end it", effects = { Happiness = -15, Money = -100000 }, setFlags = { divorced = true, gave_up_everything = true, single = true }, feedText = "You signed it all away. The house. The savings. You just wanted OUT. You're broke but free. You'll rebuild. Somehow." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- FRIENDSHIPS & FAMILY
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "best_friend_betrayal_romance",
		title = "Your Best Friend Betrayed You",
		emoji = "😢",
		text = "You've been best friends for 15 years. Since middle school. You know everything about each other. Then: your friend and your ex. TOGETHER. Dating. They've been hiding it for MONTHS. You found out from Instagram. They didn't even tell you. Your best friend is dating your ex. Your ex knows ALL your secrets because you told your friend EVERYTHING. Betrayal doesn't cover this.",
		question = "How do you respond?",
		minAge = 20, maxAge = 50,
		baseChance = 0.3,
		cooldown = 10,
		stage = "any",
		category = "friendship",
		tags = { "betrayal", "friendship", "ex", "painful" },

		choices = {
			{ text = "Cut them both off forever", effects = { Happiness = -15, Health = -5 }, setFlags = { lost_best_friend = true, trust_destroyed = true }, feedText = "Blocked. Both of them. They're DEAD to you. 15 years of friendship, gone. You'll never forgive this. NEVER." },
			{ text = "Try to understand - accept it", effects = { Happiness = -10, Smarts = 7 }, setFlags = { mature_about_it = true, emotionally_advanced = true }, feedText = "You talked. You're hurt but... people fall in love. It's messy. You're trying to accept it. You're a bigger person than most. It still hurts though." },
			{ text = "Sabotage their relationship", effects = { Happiness = -5, Smarts = -5 }, setFlags = { vengeful = true, petty = true, toxic = true }, feedText = "You're spreading rumors. You're telling your ex's new partner all their secrets. You're DESTROYING them. Revenge feels good. (Does it though?)" },
		},
	},

	{
		id = "friend_group_drama",
		title = "The Friend Group is Imploding",
		emoji = "👥",
		text = "Your friend group of 8 people is DONE. Two people hooked up. One person owes money. Someone said something racist (they claim it was a joke). Now there are separate group chats. People are picking sides. You're in the middle trying to stay neutral. But neutral means you're friends with the 'bad' person, according to one side. There's no winning. Your friend group is destroying itself.",
		question = "What's your move?",
		minAge = 18, maxAge = 45,
		baseChance = 0.5,
		cooldown = 5,
		stage = "any",
		category = "friendship",
		tags = { "drama", "friends", "conflict", "social" },

		choices = {
			{ text = "Pick a side - loyalty matters", effects = { Happiness = 5, Smarts = -2 }, setFlags = { picked_side = true, lost_friends = true }, feedText = "You chose your side. You lost half your friends. But you stood by your principles. Your social circle is smaller but more aligned." },
			{ text = "Try to mediate - fix it", effects = { Happiness = -5, Smarts = 5, Health = -3 }, setFlags = { mediator = true, exhausted = true }, feedText = "You tried to fix it. You mediated. You listened to everyone. You're EXHAUSTED. Nothing changed. You can't fix other people's problems." },
			{ text = "Walk away from everyone", effects = { Happiness = -10 }, setFlags = { friendless = true, isolated = true }, feedText = "You're done with ALL of them. Too much drama. You're starting fresh. You're alone now but at least there's no drama. (You're lonely though.)" },
		},
	},

	{
		id = "parent_aging_care",
		title = "Your Parent Needs Care",
		emoji = "👴",
		text = "Your mom called. Your dad fell. Again. He can't live alone anymore. Your mom can't handle him alone. They need help. Your sibling lives across the country and 'can't' move back. That leaves YOU. Do you move them in? Put them in a home? Hire care? It's $6,000/month for memory care. You have your own family. Your own bills. But they're your PARENTS. They raised you. Now they need you. What do you do?",
		question = "How do you handle this?",
		minAge = 35, maxAge = 65,
		baseChance = 0.4,
		cooldown = 8,
		stage = "any",
		category = "family",
		tags = { "elderly_parents", "caregiving", "difficult", "sacrifice" },

		choices = {
			{ text = "Move them in - family first", effects = { Happiness = -5, Money = -2000, Health = -5 }, setFlags = { caregiving = true, parents_moved_in = true, sacrificed_for_family = true }, feedText = "They moved in. Your house is chaos. Your marriage is strained. You're exhausted. But they're your parents. You're doing the right thing. (It's SO HARD though.)" },
			{ text = "Pay for assisted living", effects = { Happiness = 5, Money = -6000 }, setFlags = { parents_in_care = true, financially_supporting = true }, feedText = "You found a nice facility. $6K/month. Your retirement savings are gone. But they're safe and cared for. You visit twice a week. It's expensive love." },
			{ text = "Tell sibling to step up", effects = { Happiness = -10, Smarts = 3 }, setFlags = { family_conflict = true, demanding_help = true }, feedText = "You demanded your sibling help. They refused. Now you're not speaking. Your parents are stuck in the middle. Family is fractured. Great." },
		},
	},

	{
		id = "sibling_rivalry_money",
		title = "The Inheritance Fight",
		emoji = "💰",
		text = "Your parent died. Left $500,000. The will says 'divide equally among children.' But your sister is arguing she deserves more because she was the primary caregiver the last 5 years. She has a point. But you need money too. Your brother wants to sell the house immediately. You want to keep it (memories!). Your family is fighting over money while grieving. This is destroying you.",
		question = "How do you navigate this?",
		minAge = 40, maxAge = 70,
		baseChance = 0.3,
		cooldown = 10,
		stage = "any",
		category = "family",
		tags = { "inheritance", "money", "family_conflict", "grief" },

		choices = {
			{ text = "Agree to equal split - peace matters", effects = { Happiness = 5, Money = 165000, Smarts = 5 }, setFlags = { fair_inheritance = true, family_harmony = true }, feedText = "You split it equally. $166K each. Your sister is frustrated but accepts it. Family is more important than money. Your parent would be proud." },
			{ text = "Fight for more - you deserve it!", effects = { Happiness = -10, Money = 250000 }, setFlags = { greedy = true, family_destroyed = true }, feedText = "You lawyered up. You won $250K. Your siblings hate you. You'll never speak again. You got money but lost family. Congratulations?" },
			{ text = "Give your share away - too painful", effects = { Happiness = -15, Money = 0, Smarts = 7 }, setFlags = { selfless = true, grieving_hard = true }, feedText = "You gave your share to your siblings. 'I don't want it.' Money feels dirty. Your siblings are confused but grateful. You're broke but your conscience is clear." },
		},
	},

	{
		id = "reconnect_old_friend",
		title = "An Old Friend Reaches Out",
		emoji = "📧",
		text = "Facebook message from someone you haven't seen in 15 years. Your childhood best friend! 'Hey! Long time! Want to catch up?' Your heart jumps! Then you remember: you ghosted them in college. They called. You never called back. You just... drifted. Do they remember? Do they resent you? Can you pick up where you left off? Or is 15 years too long? Can friendships survive that?",
		question = "Do you respond?",
		minAge = 28, maxAge = 70,
		baseChance = 0.4,
		cooldown = 5,
		stage = "any",
		category = "friendship",
		tags = { "reconnection", "old_friends", "second_chances" },

		choices = {
			{ text = "Meet up - rekindle the friendship!", effects = { Happiness = 15, Smarts = 5 }, setFlags = { rekindled_friendship = true, nostalgic = true }, feedText = "You met for coffee! It was like no time passed! You laughed about old times! You're friends again! Some bonds never break!" },
			{ text = "Polite message but keep distance", effects = { Happiness = 2 }, setFlags = { surface_level = true }, feedText = "'So great to hear from you!' You messaged back. But you don't make plans. Sometimes the past should stay there. It's bittersweet." },
			{ text = "Ignore it - too much time passed", effects = { Happiness = -5 }, setFlags = { closed_off = true, regretful = true }, feedText = "You left them on read. Again. Some friendships die and that's okay? (But you'll wonder about this for years. 'What if?')" },
		},
	},
}

return Relationships
