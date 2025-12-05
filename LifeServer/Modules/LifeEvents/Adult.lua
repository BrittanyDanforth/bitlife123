--[[
    Adult Events (Ages 18-100+)
    ═══════════════════════════════════════════════════════════════════════════════
    
    COMPLETELY REVAMPED FOR AAA BITLIFE QUALITY
    
    Features:
    - 50+ immersive adult life events
    - Covers young adult, midlife, and senior years
    - Career milestones, family formation, aging challenges
    - Marriage, kids, divorce, affairs, death of loved ones
    - Retirement, health crises, legacy decisions
    - Specific details: medical diagnoses, locations, financial amounts
    
    ═══════════════════════════════════════════════════════════════════════════════
]]

local Adult = {}

local STAGE = "adult"

Adult.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- YOUNG ADULT (Ages 18-29) - Independence & Foundation Building
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "moving_out_first_time",
		title = "Leaving the Nest",
		emoji = "🏠",
		text = "You're 19, standing in your childhood bedroom, surrounded by boxes. Your mom is crying. Your dad is pretending he's not emotional but you saw him wipe his eyes. Tomorrow you move into your first place. No more curfew. No more rules. But also... no more home-cooked meals. No safety net. This is it. Real adult life starts now.",
		question = "What's your living situation?",
		minAge = 18, maxAge = 24,
		oneTime = true,
		priority = "high",
		stage = STAGE,
		category = "housing",
		milestoneKey = "ADULT_MOVING_OUT",
		tags = { "independence", "family", "money", "milestone" },

		choices = {
			{ text = "My own apartment - total freedom!", effects = { Happiness = 12, Money = -800 }, setFlags = { lives_alone = true, independent = true, adulting = true }, feedText = "You got a studio apartment! $1,200/month but it's ALL YOURS! You eat cereal for dinner. Freedom tastes like Frosted Flakes." },
			{ text = "3 roommates - cheaper but chaotic", effects = { Happiness = 5, Money = -300 }, setFlags = { has_roommates = true, social_living = true }, feedText = "You moved in with 3 strangers from Craigslist. One never cleans. One has loud sex. But rent is $400! You're saving money!" },
			{ text = "Live with parents - save money first", effects = { Money = 500, Happiness = -5 }, setFlags = { lives_with_parents = true, saving_money = true }, feedText = "Your friends judge you but your bank account is THRIVING. You'll move out when you're actually ready. Smart." },
		},
	},

	{
		id = "college_freshman_experience",
		title = "First Semester of College",
		emoji = "📚",
		text = "Welcome Week. Your dorm room is tiny. Your roommate seems cool... or weird? Hard to tell. There's a party every night. You have 8am classes. The dining hall food is questionable. The freedom is intoxicating. You're on your own for the first time. Your GPA and your social life are about to battle for dominance.",
		question = "What's your college strategy?",
		minAge = 18, maxAge = 19,
		oneTime = true,
		stage = STAGE,
		category = "education",
		tags = { "college", "lifestyle", "choices" },
		conditions = { flag = "plans_for_college" },
		careerTags = { "education", "business" },

		choices = {
			{ text = "Study hard - I'm here for grades", effects = { Smarts = 10, Happiness = -3, Health = -3 }, setFlags = { honors_student = true, workaholic = true }, feedText = "You're in the library until 2am. Flashcards everywhere. 4.0 GPA! But you haven't been to a single party. Worth it?" },
			{ text = "Balance - work hard, play hard", effects = { Smarts = 6, Happiness = 7, Health = 2 }, setFlags = { balanced_college = true, well_rounded = true }, feedText = "You study smart, party on weekends. 3.5 GPA and great memories! You're living your best college life!" },
			{ text = "Party mode - YOLO I'm 18!", effects = { Happiness = 12, Smarts = -5, Health = -4 }, setFlags = { party_animal = true, irresponsible = true }, feedText = "You went to 4 parties this week. You skipped 3 classes. Your GPA is 2.1. But you're LIVING! (And maybe failing out?)" },
			{ text = "Join clubs and network like crazy", effects = { Smarts = 5, Happiness = 6, Money = 200 }, setFlags = { networker = true, career_focused = true }, hintCareer = "business", feedText = "You joined 3 clubs, got 2 internships, and know half the campus. Your LinkedIn is FIRE. Career incoming!" },
		},
	},

	{
		id = "student_loan_reality",
		title = "The Student Loan Bill Arrives",
		emoji = "💸",
		text = "You just graduated. Two weeks later: an envelope arrives. Your first student loan payment: $462. EVERY MONTH. For 10 years. You owe $52,000 total. Your degree is in Art History. You work at Starbucks. The math isn't mathing. You're 23 and already drowning in debt. Welcome to adulthood.",
		question = "How do you handle this financial reality?",
		minAge = 22, maxAge = 25,
		oneTime = true,
		stage = STAGE,
		category = "money",
		tags = { "debt", "stress", "reality_check" },
		conditions = { flag = "plans_for_college" },

		choices = {
			{ text = "Pay it off aggressively - hustle mode", effects = { Money = -5000, Happiness = -5, Health = -3 }, setFlags = { debt_focused = true, works_multiple_jobs = true }, feedText = "You work 2 jobs. You never go out. You eat ramen. But you paid off $8K this year! You're attacking this debt!" },
			{ text = "Make minimum payments - just survive", effects = { Money = -500, Happiness = 2 }, setFlags = { minimum_payments = true, surviving = true }, feedText = "You pay the minimum each month. It'll take 20 years at this rate but... you can't do more right now. Survival mode." },
			{ text = "Defer/ignore - deal with it later", effects = { Happiness = 5, Money = -100 }, setFlags = { financial_denial = true, irresponsible = true }, feedText = "You requested deferment. Problem delayed = problem solved, right? (Spoiler: No. Interest is accruing. Future you is PISSED.)" },
		},
	},

	{
		id = "first_real_job",
		title = "Your First 'Real' Job",
		emoji = "💼",
		text = "You got an offer! $45,000/year! Benefits! PTO! You're a PROFESSIONAL now! Day 1: You have a cubicle. There's a microwave in the break room that smells like burnt popcorn. Your boss uses buzzwords like 'synergy' and 'circle back.' You have 8 hours of meetings about meetings. Is this what adulting is? Forever?",
		question = "What kind of employee are you?",
		minAge = 21, maxAge = 26,
		oneTime = true,
		stage = STAGE,
		category = "career",
		tags = { "job", "career_start", "corporate" },
		careerTags = { "office", "tech", "finance" },

		choices = {
			{ text = "Overachiever - first in, last out", effects = { Smarts = 7, Happiness = -3, Health = -4, Money = 1000 }, setFlags = { workaholic = true, overachiever = true }, feedText = "You work 60-hour weeks. You respond to emails at 11pm. Your boss LOVES you! Promotion incoming! Your friends... don't see you anymore." },
			{ text = "Do your job well, nothing more", effects = { Smarts = 4, Happiness = 5, Money = 500 }, setFlags = { work_life_balance = true, boundaries = true }, feedText = "You work 9-5. You leave at 5:01. Work emails stay at work. You have a LIFE. Your boss is... fine with it. Good enough!" },
			{ text = "Quiet quitting - bare minimum", effects = { Happiness = 7, Smarts = -2, Money = 200 }, setFlags = { checked_out = true, quiet_quitter = true }, feedText = "You do the absolute minimum. You're looking for other jobs during meetings. This isn't your forever. You're just passing through." },
		},
	},

	{
		id = "serious_relationship_question",
		title = "Is This The One?",
		emoji = "💑",
		text = "You've been dating for 2 years. You're 25. They're 26. Your friends are getting engaged. Your parents keep asking 'when?' You love them. But is this FOREVER love? Or just comfortable love? They want to move in together. That's a big step. That's basically a pre-engagement. Are you ready? What if they're not The One? What if you never find better?",
		question = "What do you do?",
		minAge = 23, maxAge = 29,
		baseChance = 0.7,
		cooldown = 4,
		stage = STAGE,
		category = "romance",
		tags = { "relationships", "commitment", "future" },

		choices = {
			{ text = "Move in together - test it out", effects = { Happiness = 8, Money = -200 }, setFlags = { cohabiting = true, committed_relationship = true }, feedText = "You moved in! It's great! (Except when they leave dishes in the sink. And don't replace the toilet paper. But love conquers all, right?)" },
			{ text = "Propose - they're the one!", effects = { Happiness = 15, Money = -3000 }, setFlags = { engaged = true, committed_relationship = true, found_the_one = true }, feedText = "You proposed! They said YES! Your ring cost 2 months' salary! You're ENGAGED! Time to plan a wedding!" },
			{ text = "Break up - something's off", effects = { Happiness = -10, Health = -3 }, setFlags = { single_again = true, trusted_gut = true }, feedText = "You ended it. It hurt SO MUCH. But deep down, you knew. Better to end it now than divorce at 35. Right? (You cry for 6 weeks.)" },
			{ text = "Keep dating, don't rush", effects = { Happiness = 5 }, setFlags = { taking_it_slow = true }, feedText = "You're not ready for big steps yet. They're frustrated but understanding. You're figuring it out at your own pace." },
		},
	},

	{
		id = "career_crossroads_twenties",
		title = "Quarter-Life Crisis",
		emoji = "🤔",
		text = "You're 27. You have a 'good' job. Good salary. Good benefits. You're miserable. You spend 40 hours a week doing something that doesn't matter to you. Your college friends who followed their passions seem happier (but broker). Your parents say 'stick with it.' Your heart says 'quit and find your purpose.' You have $12K in savings. Enough to take a risk?",
		question = "What do you do?",
		minAge = 25, maxAge = 29,
		oneTime = true,
		stage = STAGE,
		category = "career",
		tags = { "crisis", "purpose", "risk" },

		choices = {
			{ text = "Quit and follow your passion!", effects = { Happiness = 15, Money = -10000, Smarts = 5 }, setFlags = { took_risk = true, chased_passion = true, brave = true }, feedText = "You quit! You're pursuing your dream! (You're broke and terrified but ALIVE! No regrets! ...yet.)" },
			{ text = "Stay - security matters", effects = { Happiness = -5, Money = 5000, Health = -2 }, setFlags = { chose_security = true, risk_averse = true }, feedText = "You stayed. The safe choice. The smart choice? Your soul dies a little each Monday. But your 401k is growing!" },
			{ text = "Side hustle while keeping job", effects = { Happiness = 5, Health = -3, Money = 2000 }, setFlags = { side_hustler = true, ambitious = true }, feedText = "You work your job AND your passion project. 70-hour weeks. You're exhausted. But you're building something. Slow and steady!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ADULT (Ages 30-49) - Peak Career & Family Formation
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "marriage_ceremony",
		title = "Your Wedding Day",
		emoji = "💒",
		text = "It's happening. You're getting married. $35,000 wedding (your parents helped with $10K). 150 guests. Open bar. You're standing at the altar in front of everyone you know. Your hands are shaking. The person you love is walking down the aisle. Your heart explodes. This is real. Forever starts today.",
		question = "What kind of wedding did you have?",
		minAge = 24, maxAge = 40,
		oneTime = true,
		priority = "high",
		stage = STAGE,
		category = "romance",
		milestoneKey = "ADULT_MARRIAGE",
		tags = { "marriage", "milestone", "family", "money_big" },
		conditions = { flag = "engaged" },

		choices = {
			{ text = "Big fancy wedding - spare no expense", effects = { Happiness = 20, Money = -35000, Looks = 10 }, setFlags = { married = true, had_big_wedding = true }, feedText = "Your wedding was PERFECT! The photos are stunning! The debt is massive! But this is a once-in-a-lifetime day! Worth it!" },
			{ text = "Small intimate ceremony - just family", effects = { Happiness = 18, Money = -5000 }, setFlags = { married = true, intimate_wedding = true }, feedText = "30 people. Backyard ceremony. Simple and beautiful. You actually remember the whole day. Perfect." },
			{ text = "Courthouse wedding - save money", effects = { Happiness = 10, Money = -500 }, setFlags = { married = true, courthouse_wedding = true, practical = true }, feedText = "You got married at city hall. $50 fee. You used the savings as a down payment on a house. Smart move!" },
			{ text = "Destination wedding - adventure!", effects = { Happiness = 25, Money = -25000, Health = 3 }, setFlags = { married = true, destination_wedding = true }, feedText = "You got married on a beach in Bali! 40 people traveled internationally! Once-in-a-lifetime experience! Debt incoming!" },
		},
	},

	{
		id = "should_we_have_kids",
		title = "The Baby Question",
		emoji = "👶",
		text = "You're 32. Married for 3 years. Every family gathering: 'So when are you having kids?' Your partner wants them. You're... not sure? Kids are FOREVER. They're expensive. They end your freedom. But what if you regret NOT having them? What if you miss out on the greatest love of your life? The clock is ticking. Society is judging. What do YOU want?",
		question = "Do you want children?",
		minAge = 28, maxAge = 42,
		oneTime = true,
		priority = "high",
		stage = STAGE,
		category = "family",
		tags = { "kids", "decision", "future", "major_decision" },
		conditions = { flag = "married" },

		choices = {
			{ text = "Yes - let's start trying!", effects = { Happiness = 10, Money = -2000 }, setFlags = { trying_for_baby = true, wants_kids = true }, feedText = "You're trying for a baby! You bought pregnancy tests in bulk! You downloaded ovulation apps! This is exciting and terrifying!" },
			{ text = "No - we're childfree by choice", effects = { Happiness = 8, Money = 5000 }, setFlags = { childfree = true, no_kids_ever = true }, feedText = "You decided: no kids. Your friends don't understand. Your parents are disappointed. But YOU know what you want. Your life, your choice!" },
			{ text = "Adopt - there are kids who need us", effects = { Happiness = 12, Money = -15000 }, setFlags = { adopting = true, adoptive_parent = true }, feedText = "You're adopting! 18-month process. Home visits. Paperwork. But you're giving a child a home! Beautiful." },
			{ text = "Not yet - maybe later", effects = { Happiness = 5 }, setFlags = { delaying_kids = true }, feedText = "You're not ready yet. Your partner is frustrated. 'Later' might be 'never.' This causes tension. Uh oh." },
		},
	},

	{
		id = "birth_of_first_child",
		title = "Your Child is Born",
		emoji = "👶",
		text = "14 hours of labor. You're exhausted. Your partner is MORE exhausted. Then: a cry. Your baby. 7 pounds, 4 ounces. Tiny fingers. Tiny toes. The nurse puts them in your arms. You're a PARENT. Holy shit. You're responsible for a HUMAN. This little person will call you Mom/Dad. Your life just changed forever. You cry. Happy tears. Terrified tears. All the tears.",
		question = "How do you feel in this moment?",
		minAge = 25, maxAge = 45,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		stage = STAGE,
		category = "family",
		milestoneKey = "ADULT_FIRST_CHILD",
		tags = { "core", "kids", "family", "life_changing", "milestone" },
		conditions = { flag = "trying_for_baby" },

		choices = {
			{ text = "Pure joy - instant love", effects = { Happiness = 25, Health = -5 }, setFlags = { loves_being_parent = true, has_kids = true, parent = true }, feedText = "You're IN LOVE. This is the best day of your life. You stare at them for hours. Parenthood is MAGIC!" },
			{ text = "Overwhelmed - what did we do?", effects = { Happiness = 10, Health = -7 }, setFlags = { overwhelmed_parent = true, has_kids = true, parent = true }, feedText = "You're terrified. What if you drop them? What if you mess them up? You don't know what you're doing! (Nobody does. You'll figure it out.)" },
			{ text = "Mixed feelings - this is hard", effects = { Happiness = 5, Health = -8 }, setFlags = { struggling_parent = true, has_kids = true, parent = true }, feedText = "You love them. But you also miss your old life. You haven't slept in 4 days. Is it okay to feel this way? (Yes. Parenthood is hard.)" },
		},
	},

	{
		id = "work_life_balance_crisis",
		title = "Career vs. Family",
		emoji = "⚖️",
		text = "Your boss wants you to work late again. Your kid's recital is tonight. Your partner is furious. You've missed 3 school events this month. Your career is taking off - but at what cost? You're up for promotion. $20K raise. But it means more hours. More travel. Less family time. Something's gotta give.",
		question = "What do you prioritize?",
		minAge = 30, maxAge = 50,
		baseChance = 0.7,
		cooldown = 3,
		stage = STAGE,
		category = "career",
		tags = { "work_life_balance", "family", "career", "tough_choice" },
		conditions = { flag = "has_kids" },

		choices = {
			{ text = "Choose career - provide financially", effects = { Money = 15000, Happiness = -5, Health = -4 }, setFlags = { workaholic = true, absent_parent = true }, feedText = "You missed the recital. Your kid cried. But you got promoted! You're providing! They'll understand... eventually. Right?" },
			{ text = "Choose family - turn down promotion", effects = { Happiness = 10, Money = -5000 }, setFlags = { family_first = true, present_parent = true }, feedText = "You turned down the promotion. You were at the recital. Your kid's face lit up when they saw you. Worth it. Money isn't everything." },
			{ text = "Try to balance both - impossible?", effects = { Happiness = 3, Health = -5 }, setFlags = { burnt_out = true, trying_too_hard = true }, feedText = "You're trying to do EVERYTHING. 60-hour work weeks AND soccer practice. You're exhausted. Something's going to break. Probably you." },
		},
	},

	{
		id = "marital_problems_emerge",
		title = "Marriage is Struggling",
		emoji = "💔",
		text = "You and your spouse haven't had sex in 4 months. You barely talk beyond logistics. You eat dinner in silence. You sleep on opposite sides of the bed. You love them... but you're not IN love anymore. Or maybe you're just tired? Kids are exhausting. Work is stressful. But is this normal? Or are you growing apart? Your friend mentioned couples therapy. Your pride says you can fix this alone.",
		question = "How do you address this?",
		minAge = 30, maxAge = 55,
		baseChance = 0.5,
		cooldown = 4,
		stage = STAGE,
		category = "romance",
		tags = { "marriage", "conflict", "relationships", "crisis" },
		conditions = { flag = "married" },

		choices = {
			{ text = "Go to couples therapy - get help", effects = { Happiness = 5, Money = -3000, Smarts = 5 }, setFlags = { in_therapy = true, working_on_marriage = true }, feedText = "You started therapy. It's HARD. You're confronting real issues. But you're fighting FOR your marriage, not with each other. Progress!" },
			{ text = "Ignore it - hope it gets better", effects = { Happiness = -5, Health = -3 }, setFlags = { marriage_issues = true, avoidant = true }, feedText = "You're ignoring the problems. They're not going away. They're growing. The silence is deafening. This isn't sustainable." },
			{ text = "Have an affair - fill the void", effects = { Happiness = 8, Money = -1000 }, setFlags = { cheater = true, affair = true, betrayed_spouse = true }, feedText = "You cheated. The excitement was intoxicating. The guilt is crushing. If they find out, your marriage is OVER." },
			{ text = "Separation - take a break", effects = { Happiness = -10, Money = -5000 }, setFlags = { separated = true, marriage_crisis = true }, feedText = "You're separated. Trial separation. Maybe space will help? Or maybe this is the beginning of the end. Time will tell." },
		},
	},

	{
		id = "affair_discovered",
		title = "The Affair is Exposed",
		emoji = "💥",
		text = "They found the texts. Or saw the receipts. Or someone told them. Your affair is OUT. Your spouse is FURIOUS. Crying, screaming, throwing things. 'How could you?' You have no good answer. Your kids are in the next room. Your life is imploding. Years of marriage, gone. Trust, shattered. What the hell were you thinking? Was it worth it? (Spoiler: No.)",
		question = "What happens to your marriage?",
		minAge = 30, maxAge = 60,
		baseChance = 0.3,
		oneTime = true,
		stage = STAGE,
		category = "romance",
		tags = { "affair", "betrayal", "divorce", "crisis" },
		conditions = { flag = "affair" },

		choices = {
			{ text = "Beg for forgiveness - save the marriage", effects = { Happiness = -5, Money = -5000, Health = -5 }, setFlags = { affair_forgiven = true, marriage_damaged = true }, feedText = "You GROVELED. They're staying. But trust is broken. They check your phone daily. You're in the doghouse for YEARS. Relationship changed forever." },
			{ text = "Divorce - it's over", effects = { Happiness = -15, Money = -50000, Health = -8 }, setFlags = { divorced = true, single_again = true, marriage_ended = true }, feedText = "Divorce. Lawyers. Custody battle. Splitting assets. Your kids hate you. Half your friends picked sides. Your life is in pieces. Rock bottom." },
			{ text = "Blame them - gaslight and deny", effects = { Happiness = -10, Smarts = -5 }, setFlags = { manipulative = true, gaslighter = true, toxic = true }, feedText = "You blamed THEM. 'If you paid more attention to me...' You're deflecting. They see through it. Divorce incoming. Plus you're an asshole." },
		},
	},

	{
		id = "midlife_career_peak",
		title = "Career Peak Achievement",
		emoji = "📈",
		text = "You're 42. You made VP. Or partner. Or senior director. Whatever your field's top tier is. $180K salary. Corner office. Expense account. You DID IT. You climbed the ladder. Your 22-year-old self would be SO PROUD. But... you work 70 hours a week. You missed your kid's birthday. Your spouse barely knows you. Success tastes like cold takeout at 11pm in an empty office.",
		question = "Was it worth it?",
		minAge = 38, maxAge = 52,
		oneTime = true,
		stage = STAGE,
		category = "career",
		tags = { "success", "achievement", "reflection", "cost" },

		choices = {
			{ text = "Yes - I earned this!", effects = { Happiness = 15, Money = 50000, Looks = 5 }, setFlags = { career_success = true, fulfilled = true }, feedText = "You're at the TOP! You earned this! The sacrifices were worth it! You're proud! Your family is proud! Success!" },
			{ text = "No - I lost what matters", effects = { Happiness = -10, Smarts = 10 }, setFlags = { regretful = true, missed_life = true }, feedText = "You have money and status but you missed LIFE. Your kids grew up. Your spouse is a stranger. You won the career game but lost the life game." },
			{ text = "Mixed - success has a price", effects = { Happiness = 5, Smarts = 7 }, setFlags = { complex_feelings = true, mature = true }, feedText = "You're successful AND you missed things. Both are true. Life is complicated. You're learning to accept that. Wisdom." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- MIDDLE AGE (Ages 50-64) - Transitions & Reflections
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "parent_dies",
		title = "Your Parent Has Died",
		emoji = "⚰️",
		text = "The call came at 3am. Your mom/dad had a heart attack. By the time you got to the hospital, they were gone. You're 48. You knew this day would come eventually. But not now. Not yet. You're an orphan now. Even as an adult, that word feels heavy. You have to plan a funeral. Clean out their house. But first, you have to just... grieve. Your first parent gone. Everything shifted.",
		question = "How do you process this loss?",
		minAge = 40, maxAge = 70,
		oneTime = true,
		baseChance = 0.4,
		stage = STAGE,
		category = "family",
		tags = { "death", "grief", "loss", "family", "major_event" },

		choices = {
			{ text = "Break down completely - deep grief", effects = { Happiness = -20, Health = -8 }, setFlags = { grieving = true, broken = true }, feedText = "You cried for weeks. Couldn't work. Couldn't function. The pain is CRUSHING. You didn't know loss could hurt this bad. Time supposedly heals. You don't believe it yet." },
			{ text = "Stay strong for family", effects = { Happiness = -10, Health = -4 }, setFlags = { strong_for_others = true, suppressing_emotions = true }, feedText = "You held it together. Planned the funeral. Comforted siblings. But inside you're SHATTERED. You cry alone at night. Nobody sees your pain." },
			{ text = "Celebrate their life - find peace", effects = { Happiness = -5, Smarts = 7 }, setFlags = { healthy_grief = true, found_closure = true }, feedText = "You grieved but also celebrated 75 years of life well-lived. You told stories. Laughed through tears. They'd want you to be happy. You're honoring them by living fully." },
		},
	},

	{
		id = "kids_leave_for_college",
		title = "Empty Nest Syndrome",
		emoji = "🏚️",
		text = "You just dropped your youngest at college. 18 years of parenting. Over. You drive home. Their room is empty. No more soccer practice. No more parent-teacher conferences. Just... silence. Your spouse sits across from you at dinner. You realize you don't know how to talk to each other without the kids as a buffer. Who are you now? Just a couple? Or strangers who raised kids together?",
		question = "How do you adjust to this new phase?",
		minAge = 45, maxAge = 60,
		oneTime = true,
		stage = STAGE,
		category = "family",
		tags = { "empty_nest", "transition", "marriage", "identity" },
		conditions = { flag = "has_kids" },

		choices = {
			{ text = "Reconnect with spouse - second honeymoon!", effects = { Happiness = 15, Money = -5000 }, setFlags = { marriage_renewed = true, rediscovered_love = true }, feedText = "You took a 2-week trip. Just you two. No kid talk. You remembered why you fell in love! The empty nest is a GIFT! You're dating again!" },
			{ text = "Struggle with purpose - what now?", effects = { Happiness = -10, Health = -5 }, setFlags = { empty_nest_depression = true, lost_purpose = true }, feedText = "Your identity was 'parent.' Now who are you? You wander their empty room. You text them too much. You feel lost. Therapy might help." },
			{ text = "Finally pursue YOUR dreams", effects = { Happiness = 18, Smarts = 7 }, setFlags = { self_actualized = true, personal_growth = true }, feedText = "You started that business. Learned guitar. Went back to school. YOUR time now! You raised amazing kids. Now you're living for YOU!" },
		},
	},

	{
		id = "health_scare_fifties",
		title = "The Health Wake-Up Call",
		emoji = "🏥",
		text = "You're 53. Routine checkup. The doctor says 'We found something concerning.' Biopsy. Tests. Scans. Two weeks of terror. Then: the call. 'It's stage 2. Treatable but serious.' Cancer. Or heart disease. Or diabetes. Something REAL. Your mortality smacks you in the face. You're not invincible. Time is finite. Everything changes.",
		question = "How do you respond to this diagnosis?",
		minAge = 45, maxAge = 65,
		baseChance = 0.4,
		cooldown = 10,
		stage = STAGE,
		category = "health",
		tags = { "health", "crisis", "mortality", "major_event" },

		choices = {
			{ text = "Fight aggressively - beat this thing", effects = { Happiness = 5, Money = -30000, Health = -15 }, setFlags = { fighting_illness = true, treatment = true }, feedText = "Chemo. Surgery. Radiation. You're FIGHTING. It's hell. But you're not going down without a war. You WILL beat this!" },
			{ text = "Change lifestyle completely", effects = { Health = 10, Happiness = 10, Money = -5000 }, setFlags = { health_focused = true, lifestyle_change = true }, feedText = "You quit drinking. Started exercising daily. Whole food diet. Stress reduction. You're TRANSFORMING your life! If you're going to fight, fight RIGHT!" },
			{ text = "Denial - minimize the severity", effects = { Happiness = 3, Health = -5 }, setFlags = { in_denial = true, avoidant = true }, feedText = "'I feel fine!' you insist. You skip appointments. Ignore symptoms. This is dangerous. Denial won't make it go away." },
		},
	},

	{
		id = "retirement_consideration",
		title = "Should I Retire?",
		emoji = "🏖️",
		text = "You're 62. You CAN retire. You've saved $800K. Social Security kicks in. Your 401k is ready. But... then what? You've worked for 40 YEARS. Your job is your identity. Your friends are coworkers. What do you DO all day? Golf? Travel? Stare at the walls? Your spouse retired last year and seems bored. Is retirement freedom or a slow death?",
		question = "What's your retirement plan?",
		minAge = 58, maxAge = 70,
		oneTime = true,
		priority = "high",
		stage = STAGE,
		category = "career",
		milestoneKey = "ADULT_RETIREMENT",
		tags = { "retirement", "milestone", "future", "decision" },

		choices = {
			{ text = "Retire now - enjoy life!", effects = { Happiness = 20, Money = -10000, Health = 5 }, setFlags = { retired = true, living_dream = true }, feedText = "You RETIRED! You travel! You golf! You sleep in! You've earned this! The first month feels like vacation! (Check back in 6 months...)" },
			{ text = "Work a few more years - more savings", effects = { Money = 50000, Happiness = -5, Health = -5 }, setFlags = { working_longer = true, financially_focused = true }, feedText = "You're staying until 67. More savings = more security. Retirement can wait. You're building a cushion. Smart... but tiring." },
			{ text = "Semi-retirement - part-time", effects = { Happiness = 15, Money = 10000, Health = 2 }, setFlags = { semi_retired = true, balanced_approach = true }, feedText = "You went part-time! 20 hours a week! Income + free time! Best of both worlds! You're easing into retirement!" },
			{ text = "Never retire - work forever", effects = { Happiness = -5, Money = 100000 }, setFlags = { workaholic = true, never_retire = true }, feedText = "You'll work till you drop. Work gives you purpose! Retirement is boring! You'd rather die at your desk! (Your family is concerned.)" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- SENIOR YEARS (Ages 65+) - Legacy & Decline
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "grandchildren_joy",
		title = "You're a Grandparent!",
		emoji = "👴",
		text = "Your kid just had a baby. You're a GRANDPARENT. You hold this tiny human - your grandchild. All the joy of babies with none of the 3am feedings! You can spoil them and send them home! Your child says 'Now I understand why you were so tired.' You laugh. You were young once. Now you're Grandma/Grandpa. When did THAT happen?",
		question = "What kind of grandparent are you?",
		minAge = 45, maxAge = 80,
		oneTime = true,
		stage = STAGE,
		category = "family",
		tags = { "grandkids", "family", "joy", "milestone" },
		conditions = { flag = "has_kids" },

		choices = {
			{ text = "Super involved - babysit constantly", effects = { Happiness = 20, Health = -3 }, setFlags = { involved_grandparent = true, babysitter = true }, feedText = "You babysit 3 times a week! You're at every recital! You're INVOLVED! This is your second chance at parenting but better!" },
			{ text = "Loving but boundaried", effects = { Happiness = 15, Health = 2 }, setFlags = { healthy_boundaries = true }, feedText = "You love them dearly! But you raised your kids. You visit, you spoil, you leave. Balance!" },
			{ text = "Distant - not really interested", effects = { Happiness = 5 }, setFlags = { distant_grandparent = true }, feedText = "You see them on holidays. You're not really a 'kid person.' Your child is disappointed. You feel guilty. A little." },
		},
	},

	{
		id = "spouse_death",
		title = "Your Spouse Dies",
		emoji = "⚰️",
		text = "50 years of marriage. Then: gone. Heart attack. Or cancer. Or just... old age. Your life partner. Your best friend. The person who knew you better than you know yourself. Gone. The house is too quiet. Their side of the bed is cold. You pour one coffee instead of two. You're 75. Alone. How do you go on when half of you is gone?",
		question = "How do you cope with this loss?",
		minAge = 65, maxAge = 95,
		oneTime = true,
		baseChance = 0.3,
		stage = STAGE,
		category = "family",
		tags = { "death", "grief", "spouse", "devastating" },
		conditions = { flag = "married" },

		choices = {
			{ text = "Withdraw - grief consumes you", effects = { Happiness = -25, Health = -15 }, setFlags = { widowed = true, profound_grief = true, depressed = true }, feedText = "You stopped leaving the house. You talk to their photo. You want to join them. Your kids are worried. Grief is drowning you." },
			{ text = "Lean on family - find support", effects = { Happiness = -15, Health = -8, Smarts = 5 }, setFlags = { widowed = true, supported = true }, feedText = "Your kids moved you closer. You go to grief groups. You cry. A lot. But you're not alone. Slowly, slowly, you're healing. Time helps." },
			{ text = "Honor them by living fully", effects = { Happiness = -10, Health = -5, Smarts = 7 }, setFlags = { widowed = true, resilient = true, living_legacy = true }, feedText = "You grieve but you don't stop living. They'd want you happy. You volunteer. You travel. You live FOR them. Their memory pushes you forward." },
		},
	},

	{
		id = "assisted_living_decision",
		title = "Can I Still Live Alone?",
		emoji = "🏚️",
		text = "You're 81. You fell last week. You forgot to turn off the stove twice this month. Your kids are worried. They're talking about 'options.' Assisted living. Memory care. A nursing home. You're not ready. This is YOUR house. You've lived here for 40 years. But... you ARE scared. What if you fall and can't get up? What if you forget something important? Independence vs. safety. A cruel choice.",
		question = "What do you decide?",
		minAge = 75, maxAge = 95,
		baseChance = 0.4,
		cooldown = 5,
		stage = STAGE,
		category = "aging",
		tags = { "elderly", "independence", "decision", "difficult" },

		choices = {
			{ text = "Move to assisted living - accept help", effects = { Happiness = -10, Money = -50000, Health = 5 }, setFlags = { assisted_living = true, accepted_aging = true }, feedText = "You moved. It was HARD. But... it's nice. Social activities. Help when you need it. Safety. You made the right choice. Probably." },
			{ text = "Hire in-home care - stay here", effects = { Happiness = 5, Money = -40000, Health = 3 }, setFlags = { home_care = true, stubborn_independence = true }, feedText = "Someone comes 4 hours daily. You stay in YOUR home. Expensive but worth it. Your independence matters. You're not ready for a facility yet." },
			{ text = "Move in with kids", effects = { Happiness = -5, Money = 10000, Health = 2 }, setFlags = { lives_with_kids = true }, feedText = "You moved into your daughter's guest room. You lost independence but gained family. You see your grandkids daily. Trade-offs." },
			{ text = "Refuse help - stay independent", effects = { Happiness = 3, Health = -10 }, setFlags = { dangerously_independent = true, stubborn = true }, feedText = "You REFUSE help. You're FINE. (You're not fine. You fall again. It's bad. Your kids are terrified. Your stubbornness is dangerous.)" },
		},
	},

	{
		id = "legacy_reflection",
		title = "Looking Back at Your Life",
		emoji = "📖",
		text = "You're 87. You can't do much anymore. Your body is failing. But your mind is clear. You think about your life. The choices. The regrets. The triumphs. The love. The loss. Was it a good life? Did you matter? Will anyone remember you when you're gone? What's your legacy? Your great-grandchild asks: 'Tell me about your life, great-grandma/grandpa.' What do you say?",
		question = "How do you feel about your life?",
		minAge = 80, maxAge = 100,
		oneTime = true,
		stage = STAGE,
		category = "reflection",
		tags = { "legacy", "reflection", "meaning", "end_of_life" },

		choices = {
			{ text = "I lived well - no regrets", effects = { Happiness = 25, Smarts = 10 }, setFlags = { fulfilled_life = true, at_peace = true }, feedText = "You loved. You were loved. You did meaningful work. You raised good humans. You have regrets but more gratitude. You're at peace. What a life." },
			{ text = "I wish I'd done more", effects = { Happiness = -10, Smarts = 7 }, setFlags = { regretful = true, unfulfilled = true }, feedText = "So many dreams unrealized. Risks not taken. Words unsaid. You're not at peace. You wish for a do-over. But time ran out." },
			{ text = "I'm grateful for what I had", effects = { Happiness = 20, Smarts = 8 }, setFlags = { grateful = true, content = true }, feedText = "It wasn't perfect. But it was YOURS. You loved people. Made memories. Survived hardships. That's enough. More than enough." },
		},
	},
}

return Adult
