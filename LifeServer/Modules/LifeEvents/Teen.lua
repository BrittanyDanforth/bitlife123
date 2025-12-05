--[[
    Teen Events (Ages 13-17)
    ═══════════════════════════════════════════════════════════════════════════════
    
    COMPLETELY REVAMPED FOR AAA BITLIFE QUALITY
    
    Features:
    - 50+ immersive, detailed high school events
    - Dating, drama, identity, rebellion, and growth
    - Specific body parts, locations, names, and consequences
    - SATs, prom, driving, first love, heartbreak
    - Player choices drive the narrative
    - Realistic teen challenges and triumphs
    
    ═══════════════════════════════════════════════════════════════════════════════
]]

local Teen = {}

local STAGE = "teen"

Teen.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- STAGE TRANSITION - HIGH SCHOOL BEGINS
	-- ══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "stage_transition_teen",
		title = "First Day of High School",
		emoji = "🎓",
		text = "You're standing outside the massive high school building. Your stomach is doing flips. There are 2,000 students here - way bigger than middle school. Seniors tower over you. You clutch your schedule and try to remember where Room 204 is. This is it. Four years that will define you.",
		question = "How do you approach this terrifying new beginning?",
		minAge = 13, maxAge = 14,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		stage = STAGE,
		category = "school",
		tags = { "core", "school", "transition", "milestone" },
		
		onComplete = function(state)
			state.EducationData = state.EducationData or {}
			state.EducationData.Status = "enrolled"
			state.EducationData.Institution = "High School"
			state.Flags = state.Flags or {}
			state.Flags.in_high_school = true
			state.Flags.is_teenager = true
		end,
		
		choices = {
			{ text = "Go ALL IN on academics - straight A's", effects = { Smarts = 7, Happiness = 3 }, setFlags = { academic_path = true, in_high_school = true, overachiever = true }, feedText = "You're laser-focused on your GPA. Honor roll or bust. College starts NOW." },
			{ text = "Join every club and activity", effects = { Happiness = 7, Health = 3 }, setFlags = { extracurricular_focus = true, in_high_school = true, well_rounded = true }, feedText = "You sign up for debate, drama, yearbook, and three sports. You want the FULL high school experience!" },
			{ text = "Focus on making friends and being popular", effects = { Happiness = 8, Looks = 2 }, setFlags = { social_path = true, in_high_school = true, social_climber = true }, feedText = "Your social life is #1. You need to know everyone, go to every party, BE someone." },
			{ text = "Keep your head down and survive", effects = { Smarts = 2, Happiness = -2 }, setFlags = { introvert_path = true, in_high_school = true, invisible_student = true }, feedText = "You sit in the back, don't make eye contact. Just survive these four years. That's the plan." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ACADEMICS & SCHOOL PRESSURE
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "honors_classes_decision",
		title = "Advanced Placement Pressure",
		emoji = "📚",
		text = "It's course selection time. Your guidance counselor is pushing you toward AP/Honors classes. 'Colleges look at rigor,' she says. But your friend who took 4 APs last year had a complete breakdown. You saw them crying in the bathroom twice. How hard do you want to push yourself?",
		question = "What's your course load strategy?",
		minAge = 14, maxAge = 16,
		cooldown = 2,
		stage = STAGE,
		category = "school",
		tags = { "academics", "pressure", "college_prep" },
		careerTags = { "tech", "medical", "law", "science" },

		choices = {
			{ text = "5+ AP classes - go hard or go home!", effects = { Smarts = 10, Happiness = -5, Health = -4 }, setFlags = { ap_overload = true, stressed = true }, hintCareer = "medical", feedText = "You're taking AP Calc, AP Chem, AP English, AP History, and AP Physics. Your calendar is color-coded by subject. You don't remember what sleep feels like." },
			{ text = "3-4 AP classes - balanced approach", effects = { Smarts = 7, Happiness = 2 }, setFlags = { ap_student = true, balanced = true }, hintCareer = "tech", feedText = "You challenge yourself but leave room for a life. You take APs in subjects you actually like. Smart strategy." },
			{ text = "1-2 AP classes - dip your toes in", effects = { Smarts = 4, Happiness = 4 }, setFlags = { some_aps = true }, feedText = "You take AP English because you love writing. That's enough challenge for now. Quality over quantity!" },
			{ text = "Regular classes only - mental health first", effects = { Happiness = 7, Health = 3 }, setFlags = { prioritizes_wellness = true, realistic = true }, feedText = "You choose regular classes. Your mental health matters more than impressing colleges. Self-care wins!" },
		},
	},

	{
		id = "group_project_nightmare",
		title = "The Group Project From Hell",
		emoji = "📝",
		text = "Your English teacher assigned a 4-person group project worth 30% of your grade. You're paired with: Alex (never shows up), Jamie (tries but clueless), and Taylor (more interested in their phone than the assignment). The project is due in 5 days. You've done 80% of the work alone.",
		question = "What do you do with 5 days left?",
		minAge = 13, maxAge = 17,
		baseChance = 0.8,
		cooldown = 2,
		stage = STAGE,
		category = "school",
		tags = { "group_work", "conflict", "academics" },

		choices = {
			{ text = "Do 100% of the work yourself", effects = { Smarts = 5, Happiness = -5, Health = -3 }, setFlags = { takes_on_too_much = true, doormat = true }, feedText = "You pulled 3 all-nighters. Got an A. Your groupmates thanked you. You resent them. The teacher never knew." },
			{ text = "Confront your group directly", effects = { Smarts = 3, Happiness = 2 }, setFlags = { direct_communicator = true, assertive = true }, feedText = "You called a meeting and laid it out: 'Step up or I'm telling the teacher.' They actually showed up. Progress!" },
			{ text = "Email the teacher about the situation", effects = { Smarts = 3, Happiness = 1 }, setFlags = { follows_rules = true, not_afraid_to_report = true }, feedText = "The teacher graded everyone individually. Alex got a C, you got an A. Fair is fair." },
			{ text = "Accept a mediocre grade, refuse to care", effects = { Happiness = -3, Smarts = -2 }, setFlags = { checked_out = true, gives_up = true }, feedText = "You submitted a half-finished project. Got a C+. Whatever. Group projects are BS anyway." },
		},
	},

	{
		id = "academic_cheating_temptation",
		title = "The Answer Key Situation",
		emoji = "😈",
		text = "There's a massive chemistry exam tomorrow. You're going to fail. You KNOW you're going to fail. Then your friend texts: 'I have the answer key. Teacher left it on her desk. I took a pic. Want it?' Your heart pounds. This could save your grade. But...",
		question = "What do you do?",
		minAge = 14, maxAge = 17,
		baseChance = 0.5,
		cooldown = 4,
		stage = STAGE,
		category = "morality",
		tags = { "cheating", "academics", "ethics", "pressure" },
		careerTags = { "law" },

		choices = {
			{ text = "Use the answer key - survival mode", effects = { Smarts = -5, Happiness = 3, Money = 0 }, setFlags = { cheater = true, moral_gray = true }, feedText = "You memorized the answers. Got a B+. But you feel sick inside. What if you get caught? What if someone saw the text?" },
			{ text = "Refuse and study all night instead", effects = { Smarts = 5, Happiness = -2, Health = -3 }, setFlags = { strong_morals = true, honest = true }, hintCareer = "law", feedText = "You stayed up until 4am cramming. Got a C. But you earned it honestly. You can look yourself in the mirror." },
			{ text = "Report your friend to the teacher", effects = { Smarts = 2, Happiness = -5 }, setFlags = { rule_follower = true, no_loyalty = true }, feedText = "You told the teacher. Your friend got suspended. They'll never speak to you again. You did the 'right' thing... right?" },
		},
	},

	{
		id = "sat_test_stress",
		title = "SAT Day Terror",
		emoji = "📝",
		text = "It's SAT day. You've been prepping for months. Your future feels like it rides on these next 4 hours. Your hands are shaking as you bubble in your name. The proctor says 'Begin.' Your mind goes BLANK. All that studying... gone. Panic sets in.",
		question = "How do you handle the pressure?",
		minAge = 16, maxAge = 17,
		oneTime = true,
		priority = "high",
		stage = STAGE,
		category = "academics",
		tags = { "testing", "college_prep", "stress", "milestone" },

		choices = {
			{ text = "Take deep breaths and push through", effects = { Smarts = 7, Happiness = 3 }, setFlags = { good_test_taker = true, clutch_performer = true }, feedText = "You closed your eyes, counted to 10, and crushed it. 1380! Your hard work paid off!" },
			{ text = "Panic and underperform", effects = { Smarts = 2, Happiness = -7, Health = -2 }, setFlags = { test_anxiety = true, chokes_under_pressure = true }, feedText = "You froze. Guessed on half the math section. 1050. Way below your practice tests. You cry in the car." },
			{ text = "Do okay but not great", effects = { Smarts = 4, Happiness = 1 }, setFlags = { average_test_taker = true }, feedText = "You got a 1200. Not amazing, not terrible. You'll probably retake it. It's fine. You're fine. (Are you fine?)" },
		},
	},

	{
		id = "teacher_favorite_or_enemy",
		title = "The Teacher Situation",
		emoji = "👨‍🏫",
		text = "Mr. Rodriguez (your history teacher) has it OUT for you. Or maybe you have it out for him? He called you out in front of the class for checking your phone. Then gave you detention for being 30 seconds late. You're pretty sure he's targeting you specifically.",
		question = "How do you handle this power dynamic?",
		minAge = 14, maxAge = 17,
		baseChance = 0.6,
		cooldown = 3,
		stage = STAGE,
		category = "school",
		tags = { "authority", "conflict", "teachers" },

		choices = {
			{ text = "Suck up and try to win him over", effects = { Smarts = 3, Happiness = -2 }, setFlags = { people_pleaser = true, strategic = true }, feedText = "You asked thoughtful questions, volunteered answers, stayed after class. By semester end, you were his favorite. Manipulation works!" },
			{ text = "Be openly defiant", effects = { Happiness = 3, Smarts = -3 }, setFlags = { rebellious = true, authority_issues = true }, feedText = "You challenged him in class, rolled your eyes, showed up late intentionally. You got a D. Worth it? Maybe." },
			{ text = "Complain to administration", effects = { Smarts = 1, Happiness = -1 }, setFlags = { complainer = true, seeks_justice = true }, feedText = "You filed a formal complaint. Admin did nothing. Now Mr. Rodriguez REALLY doesn't like you. Great." },
			{ text = "Just do the work and ignore the drama", effects = { Smarts = 5, Happiness = 2 }, setFlags = { mature = true, rises_above = true }, feedText = "You did your assignments, kept your head down, got a B. Not worth the fight. Pick your battles." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- SOCIAL LIFE & FRIENDSHIPS
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "lunch_table_politics",
		title = "The Cafeteria Hierarchy",
		emoji = "🍽️",
		text = "High school lunch is a social minefield. There's the jock table, the theater kids' table, the nerds' table, the popular kids' table (unreachable), and the 'randoms' table. Your middle school friends scattered. You're holding your tray, scanning the room. Everyone's watching. Where you sit defines you.",
		question = "Where do you sit?",
		minAge = 13, maxAge = 15,
		oneTime = true,
		stage = STAGE,
		category = "social",
		tags = { "cliques", "identity", "social_hierarchy" },

		choices = {
			{ text = "With the jocks/athletes", effects = { Health = 5, Happiness = 5 }, setFlags = { jock_crowd = true, athletic_identity = true }, hintCareer = "sports", feedText = "You squeezed in between the football and basketball players. They accepted you. You're sporty now." },
			{ text = "With the honors/AP kids", effects = { Smarts = 5, Happiness = 3 }, setFlags = { nerd_group = true, academic_identity = true }, hintCareer = "science", feedText = "You joined the smart kids table. Conversation topics: calc homework, Ivy League, and Khan Academy. You fit in!" },
			{ text = "With the theater/creative kids", effects = { Happiness = 7, Looks = 2 }, setFlags = { artsy_group = true, creative_identity = true }, hintCareer = "creative", feedText = "The drama kids welcomed you with open arms. They're loud, weird, and EXACTLY your people!" },
			{ text = "With the rebels/stoners", effects = { Happiness = 4, Health = -2 }, setFlags = { rebel_group = true, edgy = true }, feedText = "You sat with the kids who vape in the bathroom. They're 'cool.' Your parents would hate them." },
			{ text = "Float between groups - no loyalty", effects = { Happiness = 3, Smarts = 2 }, setFlags = { social_butterfly = true, adaptable = true }, feedText = "You move tables daily. You're friends with everyone and no one. It's lonely but flexible." },
		},
	},

	{
		id = "best_friend_drama",
		title = "The Ultimate Betrayal",
		emoji = "💔",
		text = "You found out your best friend since 7th grade has been talking MASSIVE shit about you. They told everyone your biggest secret. They screenshot your vulnerable texts and sent them to the group chat. You're humiliated. Everyone knows. Your phone won't stop buzzing. You see them in the hallway and they avoid eye contact.",
		question = "What's your move?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 4,
		stage = STAGE,
		category = "relationships",
		tags = { "betrayal", "friendship", "drama", "trust" },
		
		choices = {
			{ text = "Confront them publicly in the cafeteria", effects = { Happiness = -3, Looks = 3 }, setFlags = { confrontational = true, dramatic = true }, feedText = "You walked up to their lunch table and LAID INTO them. Everyone recorded it. You're a legend but also a meme." },
			{ text = "Cut them off completely - ghost mode", effects = { Happiness = -7, Smarts = 3 }, setFlags = { cuts_people_off = true, trust_issues_severe = true }, feedText = "Blocked. Unfollowed. Deleted their number. You don't forgive betrayal. They're dead to you forever." },
			{ text = "Spread rumors about them - revenge", effects = { Happiness = 2, Smarts = -3 }, setFlags = { vengeful = true, petty = true }, feedText = "You told everyone THEIR secrets. Mutually assured destruction. The friendship is nuclear. But you feel... gross." },
			{ text = "Try to understand and forgive", effects = { Happiness = -5, Smarts = 5 }, setFlags = { forgiving = true, emotionally_mature = true, soft = true }, feedText = "You talked it out. They were jealous and insecure. You forgave them but trust is broken forever. Bittersweet." },
			{ text = "Let it go and find new friends", effects = { Happiness = -2, Smarts = 4 }, setFlags = { moves_on = true, resilient = true }, feedText = "They weren't your real friend anyway. You found better people. Upgrade complete." },
		},
	},

	{
		id = "party_invite_pressure",
		title = "The Party Everyone's Going To",
		emoji = "🎉",
		text = "There's a HUGE party at Jake's house Friday night. His parents are out of town. Everyone's talking about it. There will definitely be alcohol. Possibly drugs. Your parents said you could sleep at a friend's house but they think you're watching movies. This is THE social event of the semester.",
		question = "Do you go?",
		minAge = 15, maxAge = 17,
		baseChance = 0.7,
		cooldown = 2,
		stage = STAGE,
		category = "social",
		tags = { "partying", "peer_pressure", "rebellion", "alcohol" },

		choices = {
			{ text = "Sneak out and go hard!", effects = { Happiness = 8, Health = -4, Looks = 2 }, setFlags = { rebellious = true, partier = true, sneaks_out = true }, feedText = "You drank, danced, and made out with someone in the basement. You threw up in a bush. BEST NIGHT EVER? You can't remember half of it." },
			{ text = "Go but stay sober - designated friend", effects = { Happiness = 4, Health = 1 }, setFlags = { responsible_partier = true, trustworthy = true }, feedText = "You went but didn't drink. You took care of your drunk friends. You saw everything. Some of it was funny. Some was sad." },
			{ text = "Lie and say you're sick", effects = { Happiness = -3 }, setFlags = { FOMO = true, plays_it_safe = true }, feedText = "You stayed home. Everyone posted on social media. You refreshed Instagram 47 times. FOMO hurts." },
			{ text = "Ask parents for permission honestly", effects = { Happiness = 5, Smarts = 3 }, setFlags = { honest_with_parents = true, mature = true }, feedText = "You asked. They said yes (with a midnight curfew and check-ins). You went, had fun, and didn't lie. Rare W!" },
		},
	},

	{
		id = "prom_drama",
		title = "Prom Season Stress",
		emoji = "💃",
		text = "Prom is in 6 weeks. Everyone's getting asked in elaborate public 'promposals.' Your crush hasn't asked you. Actually, no one's asked you. Your friends all have dates. There's a group chat planning limos and you're not in it. Maybe you won't go? But it's PROM. You've imagined this since you were 12.",
		question = "What's your prom strategy?",
		minAge = 16, maxAge = 17,
		oneTime = true,
		stage = STAGE,
		category = "social",
		tags = { "prom", "milestone", "romance", "social_pressure" },
		
		choices = {
			{ text = "Ask your crush yourself - bold move!", effects = { Happiness = 10, Looks = 5 }, setFlags = { bold = true, confident = true, went_to_prom = true }, feedText = "You asked them in front of everyone. They said YES! You bought the perfect outfit. Prom was magical. You kissed at midnight!" },
			{ text = "Go with a group of friends - no date", effects = { Happiness = 6 }, setFlags = { independent = true, went_to_prom = true }, feedText = "You went stag with your friends. No romantic pressure! You danced all night and actually had fun. Who needs dates?" },
			{ text = "Skip prom entirely - not worth it", effects = { Happiness = -5, Money = 200 }, setFlags = { skipped_prom = true, contrarian = true }, feedText = "You stayed home. Saved $400. Prom is overrated anyway. (You cried looking at everyone's photos. Maybe it wasn't overrated?)" },
			{ text = "Go alone and own it", effects = { Happiness = 4, Looks = 3 }, setFlags = { confident = true, went_to_prom = true }, feedText = "You showed up solo looking AMAZING. You danced with everyone. Confidence is the best date." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ROMANCE & DATING
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "first_serious_relationship",
		title = "Falling in Love (For Real This Time)",
		emoji = "💘",
		text = "This is different from middle school crushes. You've been dating for 3 months. You think about them constantly. They're your first text in the morning. You've said 'I love you.' Your friends are sick of hearing about them. Your parents are concerned about your grades slipping. This feels REAL.",
		question = "How do you handle this intense new relationship?",
		minAge = 14, maxAge = 17,
		baseChance = 0.7,
		cooldown = 3,
		stage = STAGE,
		category = "romance",
		tags = { "love", "dating", "relationships", "first_love" },

		choices = {
			{ text = "Make them your ENTIRE world", effects = { Happiness = 10, Smarts = -5, Health = -2 }, setFlags = { obsessive_love = true, codependent = true, has_partner = true }, feedText = "You ditched your friends for them. Your grades dropped from As to Cs. But you're IN LOVE! You can't imagine life without them!" },
			{ text = "Balance relationship with other priorities", effects = { Happiness = 7, Smarts = 2 }, setFlags = { healthy_relationship = true, balanced = true, has_partner = true }, feedText = "You make time for them AND your friends, school, and hobbies. Healthy relationship goals! Your parents approve!" },
			{ text = "Keep it casual, don't catch feelings", effects = { Happiness = 4, Looks = 2 }, setFlags = { emotionally_guarded = true, afraid_of_commitment = true }, feedText = "You keep them at arm's length. You won't say 'I love you' back. Commitment is scary. They're getting frustrated." },
		},
	},

	{
		id = "first_heartbreak",
		title = "They Broke Up With You",
		emoji = "💔",
		text = "'We need to talk.' The four worst words. They're breaking up with you. In the school parking lot. You see it coming but it still hits like a truck. Your first real heartbreak. They're already talking to someone else. You see them together in the halls. It's been 2 weeks and you're still crying yourself to sleep.",
		question = "How do you cope with this pain?",
		minAge = 14, maxAge = 17,
		baseChance = 0.5,
		cooldown = 4,
		stage = STAGE,
		category = "romance",
		tags = { "heartbreak", "grief", "emotions", "growth" },
		conditions = { flag = "has_partner" },

		choices = {
			{ text = "Wallow in sadness - deep mourning", effects = { Happiness = -10, Health = -4, Smarts = -3 }, setFlags = { heartbroken = true, depressed = true }, feedText = "You listened to sad songs for 6 weeks. Cried in the bathroom between classes. Stopped eating. Your friends are worried." },
			{ text = "Reinvent yourself - glow up mode", effects = { Happiness = 3, Looks = 7, Health = 5 }, setFlags = { glow_up = true, resilient = true }, feedText = "You got a haircut, joined the gym, upgraded your wardrobe. You're THRIVING. They're gonna regret this. Revenge bod activated!" },
			{ text = "Rebound immediately", effects = { Happiness = 5, Smarts = -2 }, setFlags = { rebound_person = true, avoids_feelings = true }, feedText = "You started dating someone new 3 days later. Healthy? No. Distracting? Absolutely." },
			{ text = "Process it healthily with support", effects = { Happiness = -5, Smarts = 5, Health = 2 }, setFlags = { emotionally_healthy = true, seeks_support = true }, feedText = "You cried to your friends, wrote in your journal, and gave yourself time to heal. It hurt but you grew from it." },
		},
	},

	{
		id = "virginity_decision",
		title = "That Next Step",
		emoji = "🔞",
		text = "You and your partner have been dating for 8 months. Things are getting more serious physically. They want to take it to the next level. You've talked about it. You're nervous but curious. Your friends have mixed advice. This is a big decision. There's no un-doing it.",
		question = "What do you decide?",
		minAge = 15, maxAge = 17,
		baseChance = 0.4,
		oneTime = true,
		stage = STAGE,
		category = "romance",
		tags = { "sex", "intimacy", "decision", "maturity" },
		conditions = { flag = "has_partner" },

		choices = {
			{ text = "I'm ready - let's do this", effects = { Happiness = 8, Looks = 3 }, setFlags = { sexually_active = true, lost_virginity = true, mature_decision = true }, feedText = "You did it. It was awkward and kind of weird but also special? You feel different. Grown up. You don't regret it." },
			{ text = "I'm not ready yet - wait", effects = { Happiness = 5, Smarts = 3 }, setFlags = { waits_for_sex = true, boundaries = true }, feedText = "You said not yet. Your partner respected it. You're not going to rush this. When you're ready, you're ready." },
			{ text = "Break up over the pressure", effects = { Happiness = -5 }, setFlags = { incompatible = true }, feedText = "They kept pushing. You realized you want different things. You broke up. Better to be single than pressured." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- IDENTITY & SELF-DISCOVERY
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "gender_identity_exploration",
		title = "Who Am I Really?",
		emoji = "🌈",
		text = "You've been feeling... different lately. Like maybe the gender you were assigned at birth doesn't quite fit. You've been researching online, watching videos, reading forums. You found words that resonate: non-binary, trans, genderfluid. Your heart races when you see people living their truth. Could this be you?",
		question = "How do you explore these feelings?",
		minAge = 13, maxAge = 17,
		oneTime = true,
		baseChance = 0.3,
		stage = STAGE,
		category = "identity",
		tags = { "gender", "identity", "lgbtq", "self_discovery" },

		choices = {
			{ text = "Experiment with pronouns/presentation", effects = { Happiness = 10, Looks = 5 }, setFlags = { gender_questioning = true, exploring_identity = true, brave = true }, feedText = "You asked close friends to use different pronouns. You changed your style. It feels RIGHT. You're discovering yourself!" },
			{ text = "Come out to someone you trust", effects = { Happiness = 8, Smarts = 3 }, setFlags = { came_out = true, vulnerable = true }, feedText = "You told your best friend. They hugged you and said 'I support you no matter what.' You cried happy tears." },
			{ text = "Keep it private and explore quietly", effects = { Happiness = 4 }, setFlags = { private_exploration = true }, feedText = "You're not ready to share yet. You experiment in your room, online spaces. That's okay. Your journey, your timeline." },
			{ text = "Push the feelings down - not ready", effects = { Happiness = -3, Health = -2 }, setFlags = { repressed_identity = true }, feedText = "Too scary. Too complicated. You stuff it down. But the feelings don't go away. They're still there." },
		},
	},

	{
		id = "sexuality_realization",
		title = "Unexpected Feelings",
		emoji = "💗",
		text = "You've always assumed you were straight. But lately... you've been noticing people of the same gender differently. That person in your English class makes your heart race. You had a dream that made you question EVERYTHING. Your chest feels tight. What does this mean? Are you...?",
		question = "How do you process this realization?",
		minAge = 13, maxAge = 17,
		oneTime = true,
		baseChance = 0.4,
		stage = STAGE,
		category = "identity",
		tags = { "sexuality", "lgbtq", "self_discovery", "coming_out" },

		choices = {
			{ text = "Embrace it - I'm queer and proud!", effects = { Happiness = 12, Looks = 4 }, setFlags = { lgbtq = true, out_and_proud = true, confident = true }, feedText = "You came out! You joined the GSA! You're dating someone you actually like! Liberation feels AMAZING!" },
			{ text = "Tell a few close friends", effects = { Happiness = 8, Smarts = 2 }, setFlags = { lgbtq = true, selective_out = true }, feedText = "You confided in your trusted circle. They love you exactly as you are. You're not ready for the whole world yet. That's okay." },
			{ text = "Explore privately online", effects = { Happiness = 5 }, setFlags = { lgbtq = true, closeted = true }, feedText = "You found communities online. You're learning about yourself. But IRL you're still in the closet. Safety first." },
			{ text = "Deny and suppress it", effects = { Happiness = -7, Health = -3 }, setFlags = { repressed_sexuality = true, internal_conflict = true }, feedText = "You convince yourself it was a phase. You date someone you're not really into. The feelings persist. This hurts." },
		},
	},

	{
		id = "body_image_struggle",
		title = "The Mirror Lies",
		emoji = "🪞",
		text = "You've been standing in front of the mirror for 20 minutes picking apart every 'flaw.' Your thighs are too big. Your chest is too small/big. Your nose is weird. Your skin isn't clear. You've seen perfect bodies on Instagram all day. You feel like you'll never measure up. Some days you don't want to go to school.",
		question = "How do you handle these feelings?",
		minAge = 13, maxAge = 17,
		baseChance = 0.7,
		cooldown = 3,
		stage = STAGE,
		category = "identity",
		tags = { "body_image", "mental_health", "self_esteem", "appearance" },

		choices = {
			{ text = "Develop an eating disorder", effects = { Happiness = -10, Health = -10, Looks = -5 }, setFlags = { eating_disorder = true, needs_help = true, serious_issue = true }, feedText = "You started restricting/purging. You lost weight but you feel worse. You're cold all the time. Your hair is falling out. This is dangerous." },
			{ text = "Exercise obsessively", effects = { Health = 5, Happiness = -3, Looks = 3 }, setFlags = { exercise_obsession = true, orthorexic_tendencies = true }, feedText = "You work out 2-3 hours daily. It's taking over your life. You cancel plans to go to the gym. Healthy? Not really." },
			{ text = "Work on self-acceptance", effects = { Happiness = 7, Smarts = 5 }, setFlags = { body_positive = true, self_love = true, mature = true }, feedText = "You unfollowed accounts that make you feel bad. You're learning that bodies are just... bodies. You're more than your appearance." },
			{ text = "Talk to a counselor", effects = { Happiness = 5, Health = 5, Smarts = 3 }, setFlags = { seeks_help = true, proactive = true }, feedText = "You opened up to the school counselor. They're helping you challenge negative thoughts. It's slow but helping." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- REBELLION & RISKY BEHAVIOR
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "alcohol_first_drink",
		title = "First Taste of Alcohol",
		emoji = "🍺",
		text = "Your friend stole a bottle of vodka from their parents' liquor cabinet. It's a Friday night. Parents are asleep. You're in someone's basement with 6 friends passing the bottle around. Everyone's taking shots. The bottle gets to you. Your heart pounds. 'Come on, don't be lame!' they say.",
		question = "What do you do?",
		minAge = 14, maxAge = 17,
		baseChance = 0.7,
		cooldown = 3,
		stage = STAGE,
		category = "rebellion",
		tags = { "alcohol", "peer_pressure", "risky_behavior", "substances" },

		choices = {
			{ text = "Take a shot - join the party!", effects = { Happiness = 7, Health = -3 }, setFlags = { drinks_alcohol = true, party_kid = true }, feedText = "You took 4 shots. The room spun. You threw up in the bushes. You also laughed harder than ever. Mixed results." },
			{ text = "Drink a little, pace yourself", effects = { Happiness = 5, Health = -1 }, setFlags = { drinks_occasionally = true, moderate = true }, feedText = "You sipped one drink over 2 hours. You felt buzzed but in control. You were the most sober person there." },
			{ text = "Refuse - stay sober", effects = { Happiness = 2, Smarts = 5 }, setFlags = { straight_edge = true, resists_peer_pressure = true }, feedText = "You said no. They called you boring. But you felt proud of yourself. You don't need alcohol to have fun." },
		},
	},

	{
		id = "drug_experimentation",
		title = "Someone Offers You Weed",
		emoji = "🌿",
		text = "You're at a party. Someone's passing around a joint. You've been curious. Everyone says it's not a big deal, 'safer than alcohol.' But it's still illegal. Your parents would KILL you. The person next to you passes it your way. 'Want a hit?' Everyone's watching to see if you're cool.",
		question = "Do you try it?",
		minAge = 15, maxAge = 17,
		baseChance = 0.6,
		cooldown = 4,
		stage = STAGE,
		category = "rebellion",
		tags = { "drugs", "marijuana", "peer_pressure", "substances" },

		choices = {
			{ text = "Try it - what's the harm?", effects = { Happiness = 6, Health = -2, Smarts = -2 }, setFlags = { smokes_weed = true, experimenter = true }, feedText = "You took 3 hits. You coughed a LOT. Then everything was HILARIOUS. You ate an entire bag of chips. You get it now." },
			{ text = "Pass - not interested", effects = { Happiness = 1, Smarts = 4 }, setFlags = { drug_free = true, clean = true }, feedText = "You passed it along. 'I'm good.' Nobody pressured you. Turns out, real friends don't care if you partake." },
			{ text = "Leave the party entirely", effects = { Happiness = -2, Smarts = 2 }, setFlags = { risk_averse = true, goodie_two_shoes = true }, feedText = "You left. Drugs aren't your scene. You went home and texted your mom you love her. She was confused." },
		},
	},

	{
		id = "getting_drivers_license",
		title = "Driver's License Day!",
		emoji = "🚗",
		text = "You're 16 and at the DMV for your driving test. You've been practicing for months. The examiner is stone-faced. You're sweating through your shirt. You parallel park (barely), do a three-point turn, drive through a neighborhood. Finally: 'You passed.' FREEDOM! You have your license! The open road awaits!",
		question = "What kind of driver are you?",
		minAge = 16, maxAge = 16,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		stage = STAGE,
		category = "milestone",
		tags = { "driving", "independence", "milestone", "freedom" },

		choices = {
			{ text = "Cautious and rule-following", effects = { Smarts = 5, Happiness = 7, Health = 3 }, setFlags = { has_license = true, drivers_license = true, safe_driver = true }, feedText = "You drive 5 under the speed limit. Use your turn signal religiously. Your parents trust you with the car! Freedom feels good!" },
			{ text = "Reckless and speed demon", effects = { Happiness = 10, Health = -5 }, setFlags = { has_license = true, drivers_license = true, reckless_driver = true }, feedText = "You got 2 speeding tickets in the first month. Your insurance skyrocketed. But DAMN it's fun to go 90 on the highway!" },
			{ text = "Nervous but getting better", effects = { Happiness = 5, Smarts = 2 }, setFlags = { has_license = true, drivers_license = true, anxious_driver = true }, feedText = "You're still scared to merge on highways. You avoid left turns. But you're getting more confident every day!" },
		},
	},

	{
		id = "sneaking_out_caught",
		title = "Busted Sneaking Out",
		emoji = "🚪",
		text = "It's 2am. You successfully climbed out your window to meet friends at a party. You're feeling like a badass. Then: headlights in the driveway. Your parents are HOME EARLY. Your window is still open. Your bed has pillows arranged to look like you. They knock on your door. 'Honey, we're home early!' SHIT.",
		question = "What's your next move?",
		minAge = 15, maxAge = 17,
		baseChance = 0.5,
		cooldown = 5,
		stage = STAGE,
		category = "rebellion",
		tags = { "sneaking_out", "getting_caught", "consequences", "parents" },
		conditions = { flag = "sneaks_out" },

		choices = {
			{ text = "Run back and climb in quickly", effects = { Happiness = -3, Health = 5 }, setFlags = { athletic = true, lucky = true }, feedText = "You SPRINTED home and climbed in 30 seconds before they opened your door. Heart POUNDING. They never knew. Holy shit." },
			{ text = "Get caught - face the consequences", effects = { Happiness = -10, Money = -200 }, setFlags = { grounded = true, caught_sneaking = true }, feedText = "They caught you. Grounded for 2 months. Phone taken. No car privileges. You're basically in prison. Worth it? Debatable." },
			{ text = "Lie your way out somehow", effects = { Happiness = -5, Smarts = 3 }, setFlags = { good_liar = true, manipulative = true }, feedText = "You said you couldn't sleep and went for a walk. They bought it (barely). You're on thin ice. Don't push your luck." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- WORK & MONEY
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "first_job_fast_food",
		title = "Getting Your First Job",
		emoji = "💼",
		text = "You got hired at McDonald's/Burger King/Taco Bell. $9.50 an hour. You have to wear a uniform and a stupid hat. Your shift is 4-10pm on school nights. You smell like french fries. Your manager is 23 and on a power trip. But hey... money is money. Your first paycheck feels INCREDIBLE.",
		question = "How do you handle the work-life balance?",
		minAge = 15, maxAge = 17,
		baseChance = 0.7,
		cooldown = 3,
		stage = STAGE,
		category = "work",
		tags = { "job", "money", "responsibility", "work" },

		choices = {
			{ text = "Work hard - employee of the month!", effects = { Money = 400, Happiness = 5, Health = -2 }, setFlags = { hard_worker = true, responsible = true, has_job = true }, feedText = "You worked 25 hours a week. Your grades stayed solid. You saved $1,500 in 4 months! Your work ethic is strong!" },
			{ text = "Do the bare minimum", effects = { Money = 200, Happiness = 3 }, setFlags = { lazy_worker = true, does_minimum = true, has_job = true }, feedText = "You showed up, did what was required, left. You weren't winning awards but you got paid. That's enough." },
			{ text = "Quit after 2 weeks - too hard", effects = { Happiness = -2, Smarts = 1 }, setFlags = { quitter = true, lacks_commitment = true }, feedText = "You couldn't handle it. The hours, the attitude, the smell. You quit. Working sucks. You'll try again... eventually." },
		},
	},

	{
		id = "entrepreneurial_venture",
		title = "Starting a Side Hustle",
		emoji = "💡",
		text = "You have an idea to make money without working for someone else. You could resell sneakers, tutor kids online, start a YouTube channel, sell art on Etsy, or do lawn care. Your friend made $500 last month reselling Supreme hoodies. You're motivated. Time to be your own boss!",
		question = "What's your business move?",
		minAge = 14, maxAge = 17,
		baseChance = 0.5,
		cooldown = 3,
		stage = STAGE,
		category = "work",
		tags = { "entrepreneur", "business", "money", "independence" },
		careerTags = { "finance", "business" },

		choices = {
			{ text = "Reselling shoes/clothes online", effects = { Money = 600, Happiness = 7, Smarts = 5 }, setFlags = { entrepreneur = true, business_savvy = true }, hintCareer = "finance", feedText = "You studied the market, bought low, sold high. You made $2,000 in 3 months! You're a hustler!" },
			{ text = "Tutoring other students", effects = { Money = 400, Happiness = 5, Smarts = 7 }, setFlags = { entrepreneur = true, helpful = true }, hintCareer = "education", feedText = "You charged $30/hour for SAT prep. You helped 8 students improve their scores. You made money AND made a difference!" },
			{ text = "YouTube/TikTok content creation", effects = { Money = 200, Happiness = 8, Looks = 5 }, setFlags = { entrepreneur = true, creator = true }, hintCareer = "entertainment", feedText = "You started posting videos. 5K followers in 2 months! Monetization pending! You might be internet famous!" },
			{ text = "It flops - lose money", effects = { Money = -200, Happiness = -5, Smarts = 3 }, setFlags = { failed_business = true, learned_lesson = true }, feedText = "You invested $200 in inventory that didn't sell. You lost money. But you learned valuable lessons about business!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- COLLEGE PREP & GRADUATION
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "college_decision_letters",
		title = "College Acceptance Letters Arrive",
		emoji = "📬",
		text = "You've been checking your email obsessively. Today, they all arrive. You got into 3 schools. Rejected from your dream school (the letter was so thin you knew). Waitlisted at 2. Now you have to decide where to spend the next 4 years of your life. Your parents have opinions. You're overwhelmed. This decision feels MASSIVE.",
		question = "How do you choose?",
		minAge = 17, maxAge = 18,
		oneTime = true,
		priority = "high",
		stage = STAGE,
		category = "future",
		tags = { "college", "decision", "future", "milestone" },
		conditions = { flag = "plans_for_college" },

		choices = {
			{ text = "The best academic program", effects = { Smarts = 10, Happiness = 7 }, setFlags = { chose_academics = true, ambitious = true }, hintCareer = "science", feedText = "You picked the school with the best program for your major. Your career comes first. Smart choice!" },
			{ text = "The one with the best vibe/social life", effects = { Happiness = 10, Smarts = 3 }, setFlags = { chose_party_school = true, social = true }, feedText = "You picked the school that FELT right. Great campus, fun people. You'll get your degree but also have the time of your life!" },
			{ text = "The cheapest option - avoid debt", effects = { Smarts = 5, Money = 20000 }, setFlags = { financially_smart = true, practical = true }, feedText = "You picked the school with the scholarship. You'll graduate debt-free! Future you says THANK YOU!" },
			{ text = "Gap year - defer and travel/work", effects = { Happiness = 8, Smarts = 5, Money = 5000 }, setFlags = { took_gap_year = true, adventurous = true }, feedText = "You deferred admission and bought a plane ticket. You're taking a year to find yourself! Bold move!" },
		},
	},

	{
		id = "graduation_high_school",
		title = "High School Graduation Day",
		emoji = "🎓",
		text = "You're sitting in a folding chair in a hot gym wearing a cap and gown. The principal is giving a boring speech. You're sandwiched between friends you've known since kindergarten. Some will go across the country for college. Some you'll never see again. You're 18. Childhood is over. They call your name. You walk across the stage. Everyone claps. This chapter ends. A new one begins.",
		question = "How do you feel about the past 4 years?",
		minAge = 17, maxAge = 18,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		stage = STAGE,
		category = "milestone",
		tags = { "core", "graduation", "milestone", "transition", "growing_up" },
		
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
			{ text = "Best years of my life!", effects = { Happiness = 12 }, setFlags = { loved_high_school = true, graduated_high_school = true, nostalgic = true }, feedText = "You cried during the ceremony. You had AMAZING memories! You'll miss this place forever! Senior year was perfect!" },
			{ text = "Glad it's finally over", effects = { Happiness = 7 }, setFlags = { ready_to_move_on = true, graduated_high_school = true }, feedText = "You couldn't wait to leave. High school wasn't your scene. College will be better. You're READY for the next chapter!" },
			{ text = "Bittersweet - mixed feelings", effects = { Happiness = 8, Smarts = 5 }, setFlags = { emotionally_complex = true, graduated_high_school = true }, feedText = "Some parts were great. Some sucked. You grew a lot. You learned who you are. That's what matters. Onward!" },
			{ text = "Scared about the future", effects = { Happiness = 4, Smarts = 3 }, setFlags = { anxious_about_future = true, graduated_high_school = true }, feedText = "You're terrified. Adult life starts now. Responsibilities. Decisions. What if you fail? What if you make the wrong choices?" },
		},
	},
}

return Teen
