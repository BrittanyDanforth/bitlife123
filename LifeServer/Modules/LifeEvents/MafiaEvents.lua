--[[
	MafiaEvents.lua
	
	Comprehensive organized crime events for BitLife-style game.
	Handles all aspects of mafia life including:
	- Joining crime families
	- Rising through the ranks
	- Criminal operations
	- Territory wars
	- Loyalty tests
	- Prison events
	- Death and betrayal
	
	REQUIRES: Mafia gamepass (ID: 1626238769)
	
	This is a PREMIUM feature - full 1000+ line implementation
	Works in conjunction with MobSystem.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MafiaEvents = {}

-- ════════════════════════════════════════════════════════════════════════════
-- MAFIA LIFE EVENTS
-- ════════════════════════════════════════════════════════════════════════════

MafiaEvents.LifeEvents = {
	-- ═══════════════════════════════════════════════════════════════════════
	-- INITIATION EVENTS
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "mafia_approach",
		title = "🔫 The Approach",
		emoji = "🔫",
		text = "A well-dressed man approaches you at a bar. He says he's been watching you and thinks you have potential. 'The family could use someone like you,' he says quietly.",
		question = "What do you do?",
		minAge = 18,
		maxAge = 50,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { mafia_gamepass = true },
			blockedFlags = { in_mob = true },
		},
		choices = {
			{
				text = "Accept the offer immediately",
				effects = { Happiness = 10 },
				mafiaEffect = { joinFamily = true, respect = 5 },
				setFlags = { eager_recruit = true },
				feed = "You've made a life-changing decision...",
			},
			{
				text = "Ask for more information",
				effects = { Smarts = 3 },
				mafiaEffect = { consideration = true },
				setFlags = { cautious_recruit = true },
				feed = "He smiles. 'Smart. I like that.'",
			},
			{
				text = "Politely decline",
				effects = { Happiness = 5 },
				setFlags = { rejected_mob = true },
				feed = "He nods. 'The offer will stand... for now.'",
			},
			{
				text = "Report it to the police",
				effects = { Happiness = -10 },
				setFlags = { mob_enemy = true, police_informant = true },
				feed = "You've made dangerous enemies...",
			},
		},
	},
	{
		id = "initiation_task",
		title = "⚔️ Prove Yourself",
		emoji = "⚔️",
		text = "Before you can become a made member, you need to prove your loyalty. The boss has a task for you.",
		question = "The initiation involves...",
		minAge = 18,
		maxAge = 60,
		isMafiaOnly = true,
		conditions = { requiresFlags = { in_mob = true, initiated = nil } },
		choices = {
			{
				text = "Beat up someone who owes money",
				effects = { Happiness = -5, Health = -5 },
				mafiaEffect = { respect = 15, heat = 10, initiated = true },
				setFlags = { initiated = true, enforcer_type = true },
				feed = "You collected the debt with your fists.",
			},
			{
				text = "Deliver a 'package' across town",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 10, heat = 5, initiated = true },
				setFlags = { initiated = true, courier_type = true },
				feed = "The package was delivered. No questions asked.",
			},
			{
				text = "Stand guard during a 'meeting'",
				effects = { Health = -3 },
				mafiaEffect = { respect = 8, heat = 3, initiated = true },
				setFlags = { initiated = true, soldier_type = true },
				feed = "You proved you can be trusted.",
			},
			{
				text = "Refuse and try to leave",
				effects = { Happiness = -20, Health = -30 },
				mafiaEffect = { kicked = true, enemyOfFamily = true },
				setFlags = { mob_enemy = true, beat_up_by_mob = true },
				feed = "They didn't take your refusal well...",
			},
		},
	},
	{
		id = "blood_oath",
		title = "🩸 The Blood Oath",
		emoji = "🩸",
		text = "It's time for the formal ceremony. In a dimly lit room, surrounded by made members, you're asked to take the blood oath of loyalty.",
		question = "Do you take the oath?",
		minAge = 18,
		maxAge = 60,
		isMafiaOnly = true,
		isMilestone = true,
		conditions = { requiresFlags = { in_mob = true, initiated = true, made_member = nil } },
		choices = {
			{
				text = "Swear the oath with conviction",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 25, loyalty = 10, madeMember = true },
				setFlags = { made_member = true, sworn_oath = true },
				feed = "You are now a made member. There's no going back.",
			},
			{
				text = "Swear the oath reluctantly",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = 15, loyalty = 5, madeMember = true },
				setFlags = { made_member = true, reluctant_member = true },
				feed = "They noticed your hesitation, but you're in now.",
			},
			{
				text = "Run away",
				effects = { Happiness = -30, Health = -50 },
				mafiaEffect = { kicked = true, hitOrdered = true },
				setFlags = { mob_fugitive = true },
				feed = "Running from the oath has consequences...",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- OPERATIONS AND CRIME
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "protection_collection",
		title = "💰 Collection Day",
		emoji = "💰",
		text = "It's time to collect protection money from the businesses on your route. Most pay without trouble, but one shop owner is being difficult.",
		question = "How do you handle the problem?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		conditions = { requiresFlags = { in_mob = true } },
		choices = {
			{
				text = "Rough him up as a warning",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = 15, heat = 15, money = 5000 },
				setFlags = { used_violence = true },
				feed = "He'll pay on time from now on.",
			},
			{
				text = "Threaten his family",
				effects = { Happiness = -10 },
				mafiaEffect = { respect = 20, heat = 20, money = 8000, loyalty = 5 },
				setFlags = { made_threats = true, ruthless = true },
				feed = "Fear is an effective motivator.",
			},
			{
				text = "Give him more time",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = -10, loyalty = -5, money = 0 },
				setFlags = { showed_mercy = true },
				feed = "The boss won't be happy about this.",
			},
			{
				text = "Smash up his shop",
				effects = { Happiness = 3 },
				mafiaEffect = { respect = 10, heat = 25, money = 0 },
				setFlags = { destructive = true },
				feed = "The message was sent loud and clear.",
			},
		},
	},
	{
		id = "heist_planning",
		title = "🏦 The Big Score",
		emoji = "🏦",
		text = "The boss has greenlit a major heist. You've been chosen to help plan and execute it. This could make your career.",
		question = "What role do you take?",
		minAge = 18,
		maxAge = 60,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			minRank = 2,
		},
		choices = {
			{
				text = "Lead the crew inside",
				effects = { Happiness = 10, Health = -10 },
				successChance = 60,
				successMafiaEffect = { respect = 50, money = 100000, heat = 40 },
				failMafiaEffect = { heat = 60, arrested = true, jailYears = 10 },
				setFlags = { heist_leader = true },
				feed = "High risk, high reward.",
			},
			{
				text = "Be the getaway driver",
				effects = { Happiness = 8, Health = -5 },
				successChance = 75,
				successMafiaEffect = { respect = 30, money = 50000, heat = 25 },
				failMafiaEffect = { heat = 40, arrested = true, jailYears = 5 },
				setFlags = { getaway_driver = true },
				feed = "Your driving skills are legendary.",
			},
			{
				text = "Handle logistics from outside",
				effects = { Happiness = 5 },
				successChance = 85,
				successMafiaEffect = { respect = 25, money = 30000, heat = 15 },
				failMafiaEffect = { heat = 20, respect = -10 },
				setFlags = { logistics_expert = true },
				feed = "Safe but still profitable.",
			},
			{
				text = "Decline the job",
				effects = { Happiness = 0 },
				mafiaEffect = { respect = -20, loyalty = -10 },
				setFlags = { refused_heist = true },
				feed = "The boss questions your commitment.",
			},
		},
	},
	{
		id = "drug_shipment",
		title = "📦 The Shipment",
		emoji = "📦",
		text = "A major shipment is coming in. You've been trusted to oversee the operation. Everything needs to go smoothly.",
		question = "How do you handle it?",
		minAge = 18,
		maxAge = 65,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true },
			minRank = 2,
		},
		choices = {
			{
				text = "Run it by the book",
				effects = { Happiness = 5, Smarts = 3 },
				successChance = 80,
				successMafiaEffect = { respect = 20, money = 25000, heat = 10 },
				failMafiaEffect = { heat = 30, money = -10000 },
				setFlags = { reliable_operator = true },
				feed = "Clean operation, no problems.",
			},
			{
				text = "Skim a little off the top",
				effects = { Happiness = 8 },
				successChance = 50,
				successMafiaEffect = { money = 50000, heat = 5 },
				failMafiaEffect = { respect = -50, loyalty = -30, punishment = true },
				setFlags = { skimmer = true },
				feed = "Risky but lucrative if you're not caught.",
			},
			{
				text = "Tip off a rival family",
				effects = { Happiness = -10 },
				mafiaEffect = { betrayal = true, marked = true },
				setFlags = { traitor = true },
				feed = "You've signed your own death warrant.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- LOYALTY AND BETRAYAL
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "loyalty_test",
		title = "🤫 Loyalty Test",
		emoji = "🤫",
		text = "The boss suspects there's a rat in the organization. He's watching everyone closely. Then he calls you into his office alone.",
		question = "What happens in the meeting?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		conditions = { requiresFlags = { in_mob = true, made_member = true } },
		choices = {
			{
				text = "Prove your loyalty convincingly",
				effects = { Happiness = 10, Smarts = 5 },
				mafiaEffect = { respect = 25, loyalty = 20, innerCircle = true },
				setFlags = { trusted_by_boss = true, inner_circle = true },
				feed = "The boss trusts you completely now.",
			},
			{
				text = "Act nervous (you're innocent but scared)",
				effects = { Happiness = -15 },
				mafiaEffect = { loyalty = -15, suspicion = true },
				setFlags = { under_suspicion = true },
				feed = "Your nervousness raised questions.",
			},
			{
				text = "Deflect suspicion onto someone else",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 10, otherSuspected = true },
				setFlags = { cunning = true, deflector = true },
				feed = "Someone else is taking the heat.",
			},
			{
				text = "Confess you've been talking to the feds",
				effects = { Happiness = -50, Health = -100 },
				mafiaEffect = { execution = true },
				setFlags = { executed = true },
				feed = "The last thing you see is...",
			},
		},
	},
	{
		id = "informant_offer",
		title = "👮 The FBI Offer",
		emoji = "👮",
		text = "An FBI agent corners you alone. They have evidence that could send you away for life. But they're offering a deal - become an informant.",
		question = "What do you do?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true },
			minHeat = 40,
		},
		choices = {
			{
				text = "Accept the deal - become an informant",
				effects = { Happiness = -20 },
				mafiaEffect = { informant = true },
				setFlags = { fbi_informant = true, wearing_wire = true },
				feed = "You're playing a dangerous double game.",
			},
			{
				text = "Refuse and tell the family",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 30, loyalty = 25, heat = 20 },
				setFlags = { reported_feds = true, loyal_soldier = true },
				feed = "Your loyalty is noted and rewarded.",
			},
			{
				text = "Refuse but keep it secret",
				effects = { Happiness = -10 },
				setFlags = { fbi_target = true },
				feed = "The feds will be watching you closely.",
			},
			{
				text = "Try to flee the country",
				effects = { Happiness = -30, Money = -100000 },
				successChance = 40,
				successEffect = { escaped = true },
				failMafiaEffect = { caught = true, punished = true },
				setFlags = { attempted_flight = true },
				feed = "Running is rarely the answer.",
			},
		},
	},
	{
		id = "hit_order",
		title = "🎯 The Contract",
		emoji = "🎯",
		text = "The boss has given you a contract. Someone needs to be 'taken care of.' This is your chance to prove you're serious.",
		question = "Do you accept?",
		minAge = 18,
		maxAge = 65,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			minRank = 3,
		},
		choices = {
			{
				text = "Accept and complete the job",
				effects = { Happiness = -20, Health = -5 },
				mafiaEffect = { respect = 75, loyalty = 25, kills = 1, heat = 50 },
				setFlags = { has_killed = true, made_bones = true },
				feed = "You've made your bones. No turning back now.",
			},
			{
				text = "Accept but let the target escape",
				effects = { Happiness = 5 },
				successChance = 40,
				successMafiaEffect = { respect = 10 },
				failMafiaEffect = { respect = -40, loyalty = -30, punishment = true },
				setFlags = { showed_mercy_secretly = true },
				feed = "A risky act of mercy.",
			},
			{
				text = "Refuse the contract",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = -30, loyalty = -20 },
				setFlags = { refused_hit = true },
				feed = "The boss is disappointed in you.",
			},
			{
				text = "Warn the target and help them escape",
				effects = { Happiness = 5 },
				mafiaEffect = { betrayal = true, hitOrdered = true },
				setFlags = { traitor = true, saved_target = true },
				feed = "You've betrayed the family.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- RANK ADVANCEMENT
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "promotion_ceremony",
		title = "📈 Moving Up",
		emoji = "📈",
		text = "Your hard work has been noticed. The boss wants to see you about a promotion. This is what you've been working toward.",
		question = "The promotion ceremony...",
		minAge = 21,
		maxAge = 70,
		isMafiaOnly = true,
		isMilestone = true,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			promotionReady = true,
		},
		choices = {
			{
				text = "Accept with gratitude and humility",
				effects = { Happiness = 15 },
				mafiaEffect = { rankUp = true, respect = 20, loyalty = 10 },
				setFlags = { humble_leader = true },
				feed = "You've risen in the ranks. More power, more responsibility.",
			},
			{
				text = "Accept and celebrate lavishly",
				effects = { Happiness = 20, Money = -10000 },
				mafiaEffect = { rankUp = true, respect = 15 },
				setFlags = { flashy_leader = true },
				feed = "Your celebration was legendary.",
			},
			{
				text = "Decline the promotion",
				effects = { Happiness = 0 },
				mafiaEffect = { respect = -20 },
				setFlags = { refused_promotion = true },
				feed = "The boss is confused by your refusal.",
			},
		},
	},
	{
		id = "become_underboss",
		title = "👔 Underboss",
		emoji = "👔",
		text = "The current underboss has 'retired.' The boss wants you to take his place. You'll be second in command of the entire family.",
		question = "This is a huge responsibility...",
		minAge = 30,
		maxAge = 70,
		isMafiaOnly = true,
		isMilestone = true,
		conditions = { 
			requiresFlags = { in_mob = true },
			minRank = 4,
		},
		choices = {
			{
				text = "Accept the position",
				effects = { Happiness = 20 },
				mafiaEffect = { becomeUnderboss = true, respect = 50, money = 100000 },
				setFlags = { underboss = true },
				feed = "You're now the underboss. Power is intoxicating.",
			},
			{
				text = "Accept and plan to take over",
				effects = { Happiness = 15 },
				mafiaEffect = { becomeUnderboss = true, ambition = true },
				setFlags = { underboss = true, ambitious = true, planning_takeover = true },
				feed = "One day, you'll be the boss...",
			},
		},
	},
	{
		id = "become_boss",
		title = "👑 The Throne",
		emoji = "👑",
		text = "The boss is dead. As underboss, you're expected to take over. But others might challenge your claim.",
		question = "How do you secure your position?",
		minAge = 35,
		maxAge = 80,
		isMafiaOnly = true,
		isMilestone = true,
		priority = "critical",
		conditions = { 
			requiresFlags = { underboss = true, boss_dead = true },
		},
		choices = {
			{
				text = "Take power peacefully with the commission's blessing",
				effects = { Happiness = 20 },
				mafiaEffect = { becomeBoss = true, respect = 100, money = 500000 },
				setFlags = { mob_boss = true, peaceful_succession = true },
				feed = "You're now the Boss. The family answers to you.",
			},
			{
				text = "Eliminate any challengers",
				effects = { Happiness = 10, Health = -10 },
				mafiaEffect = { becomeBoss = true, respect = 80, heat = 50, kills = 2 },
				setFlags = { mob_boss = true, violent_takeover = true },
				feed = "You've secured power through blood.",
			},
			{
				text = "Step aside for another candidate",
				effects = { Happiness = -10 },
				mafiaEffect = { respect = -30, demoted = true },
				setFlags = { gave_up_throne = true },
				feed = "You'll always wonder what could have been.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- TERRITORY AND WAR
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "territory_dispute",
		title = "🗺️ Territory Dispute",
		emoji = "🗺️",
		text = "Another family is encroaching on your territory. Their soldiers have been seen collecting on your turf.",
		question = "How do you respond?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true },
			minRank = 2,
		},
		choices = {
			{
				text = "Confront them directly",
				effects = { Happiness = 5, Health = -15 },
				mafiaEffect = { respect = 25, heat = 20 },
				setFlags = { territorial = true },
				feed = "You made it clear this is your territory.",
			},
			{
				text = "Report to the boss and let him handle it",
				effects = { Happiness = 0 },
				mafiaEffect = { respect = 5, loyalty = 5 },
				feed = "The boss will deal with this.",
			},
			{
				text = "Start a war",
				effects = { Happiness = 10, Health = -30 },
				mafiaEffect = { war = true, respect = 40, heat = 60 },
				setFlags = { warmonger = true },
				feed = "Blood will flow on both sides.",
			},
			{
				text = "Try to negotiate a peaceful solution",
				effects = { Happiness = 5, Smarts = 5 },
				mafiaEffect = { respect = -10, diplomatic = true },
				setFlags = { diplomat = true },
				feed = "Violence isn't always the answer.",
			},
		},
	},
	{
		id = "family_war",
		title = "⚔️ Family War!",
		emoji = "⚔️",
		text = "War has broken out between your family and a rival. Bodies are dropping on both sides. It's kill or be killed.",
		question = "How do you survive the war?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true, at_war = true },
		},
		choices = {
			{
				text = "Fight on the front lines",
				effects = { Happiness = 5, Health = -40 },
				successChance = 60,
				successMafiaEffect = { respect = 60, kills = 3, warHero = true },
				failEffect = { Health = -100, death = true },
				setFlags = { war_veteran = true },
				feed = "You fought bravely in the war.",
			},
			{
				text = "Work behind the scenes",
				effects = { Happiness = 0, Smarts = 5 },
				mafiaEffect = { respect = 20, loyalty = 10 },
				setFlags = { strategic_thinker = true },
				feed = "Your planning helped win the war.",
			},
			{
				text = "Lay low until it's over",
				effects = { Happiness = -10 },
				mafiaEffect = { respect = -30, loyalty = -20 },
				setFlags = { coward = true },
				feed = "Your absence was noticed.",
			},
			{
				text = "Try to broker peace",
				effects = { Happiness = 5 },
				successChance = 30,
				successMafiaEffect = { respect = 50, peacemaker = true, warEnded = true },
				failMafiaEffect = { respect = -20 },
				setFlags = { attempted_peace = true },
				feed = "Peace is never easy.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- PRISON EVENTS
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "prison_respect",
		title = "⛓️ Prison Politics",
		emoji = "⛓️",
		text = "In prison, your mafia connections give you respect. Other inmates know who you're connected to.",
		question = "How do you use your status?",
		minAge = 18,
		maxAge = 80,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true, in_prison = true },
		},
		choices = {
			{
				text = "Run the prison operation for the family",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 20, loyalty = 15, prisonMoney = 5000 },
				setFlags = { prison_boss = true },
				feed = "Even behind bars, you're earning.",
			},
			{
				text = "Keep your head down",
				effects = { Happiness = 0 },
				mafiaEffect = { respect = 5 },
				feed = "You served your time quietly.",
			},
			{
				text = "Recruit for the family",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 15, newRecruits = true },
				setFlags = { prison_recruiter = true },
				feed = "You found new blood for the family.",
			},
			{
				text = "Turn informant for early release",
				effects = { Happiness = -10 },
				mafiaEffect = { betrayal = true, earlyRelease = true },
				setFlags = { snitch = true, witness_protection = true },
				feed = "Freedom came at the cost of your soul.",
			},
		},
	},
	{
		id = "prison_hit",
		title = "🔪 Prison Contract",
		emoji = "🔪",
		text = "The family needs someone taken care of in prison. You're the only one who can get to them.",
		question = "Do you accept the contract?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true, in_prison = true },
			minRank = 2,
		},
		choices = {
			{
				text = "Complete the contract",
				effects = { Happiness = -15, Health = -10 },
				successChance = 70,
				successMafiaEffect = { respect = 50, loyalty = 30, kills = 1, extraSentence = 10 },
				failMafiaEffect = { respect = 10, extraSentence = 5 },
				setFlags = { prison_killer = true },
				feed = "You handled business inside.",
			},
			{
				text = "Refuse - too risky",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = -15, loyalty = -10 },
				setFlags = { refused_prison_hit = true },
				feed = "The family is disappointed.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- DEATH AND ENDINGS
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "assassination_attempt",
		title = "💀 Hit on You!",
		emoji = "💀",
		text = "Someone has put a hit out on you. You barely survived an assassination attempt. This is serious.",
		question = "How do you respond?",
		minAge = 18,
		maxAge = 80,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true, hit_on_you = true },
		},
		choices = {
			{
				text = "Go into hiding",
				effects = { Happiness = -20 },
				mafiaEffect = { hideout = true, respect = -10 },
				setFlags = { in_hiding = true },
				feed = "You went underground.",
			},
			{
				text = "Find out who ordered it and strike back",
				effects = { Happiness = 10, Health = -20 },
				successChance = 50,
				successMafiaEffect = { respect = 60, kills = 1, revenged = true },
				failEffect = { Health = -100, death = true },
				setFlags = { sought_revenge = true },
				feed = "An eye for an eye.",
			},
			{
				text = "Ask the boss for protection",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = -20, protection = true },
				setFlags = { needed_protection = true },
				feed = "You're under the boss's protection now.",
			},
			{
				text = "Turn yourself into witness protection",
				effects = { Happiness = -30 },
				mafiaEffect = { betrayal = true, witnessProtection = true },
				setFlags = { witness_protection = true, former_mobster = true },
				feed = "You traded everything for safety.",
			},
		},
	},
	{
		id = "retirement",
		title = "🚪 Walking Away",
		emoji = "🚪",
		text = "You've been in the life for years. You're thinking about retirement, but walking away isn't easy.",
		question = "Can you really leave?",
		minAge = 50,
		maxAge = 80,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true },
			minYearsInMob = 10,
		},
		choices = {
			{
				text = "Ask the boss for permission to retire",
				effects = { Happiness = 10 },
				successChance = 60,
				successMafiaEffect = { retired = true, respect = 10, honorableExit = true },
				failMafiaEffect = { respect = -10, denied = true },
				setFlags = { attempted_retirement = true },
				feed = "Retirement in the mob is complicated.",
			},
			{
				text = "Just disappear",
				effects = { Happiness = -10 },
				successChance = 30,
				successMafiaEffect = { escaped = true },
				failMafiaEffect = { hitOrdered = true },
				setFlags = { disappeared = true },
				feed = "Running is risky.",
			},
			{
				text = "Stay until the end",
				effects = { Happiness = 5 },
				mafiaEffect = { loyalty = 10, lifer = true },
				setFlags = { mob_lifer = true },
				feed = "This life is all you know.",
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- YEARLY MOB EVENTS (Random events each year for mob members)
-- ════════════════════════════════════════════════════════════════════════════

MafiaEvents.YearlyEvents = {
	{
		id = "police_crackdown",
		name = "Police Crackdown",
		emoji = "🚔",
		chance = 10,
		minHeat = 50,
		description = "The police are cracking down on organized crime",
		heatIncrease = 20,
		arrestChance = 15,
	},
	{
		id = "federal_investigation",
		name = "Federal Investigation",
		emoji = "🏛️",
		chance = 5,
		minHeat = 70,
		description = "The feds have opened an investigation into your family",
		heatIncrease = 30,
		arrestChance = 20,
	},
	{
		id = "tribute_time",
		name = "Tribute Payment",
		emoji = "💰",
		chance = 100, -- Always happens
		description = "Time to pay tribute to the boss",
		tributePercent = 10, -- 10% of respect as dollar amount
	},
	{
		id = "family_meeting",
		name = "Family Meeting",
		emoji = "🤝",
		chance = 30,
		description = "Important family meeting called",
		respectGain = 5,
	},
	{
		id = "new_territory",
		name = "New Territory",
		emoji = "🗺️",
		chance = 15,
		minRank = 3,
		description = "Opportunity to expand into new territory",
		respectGain = 15,
		moneyGain = 20000,
	},
	{
		id = "rat_discovered",
		name = "Rat in the Family",
		emoji = "🐀",
		chance = 8,
		description = "An informant has been discovered in the family",
		heatDecrease = 20,
		dramaTension = true,
	},
	{
		id = "good_year",
		name = "Good Earnings Year",
		emoji = "📈",
		chance = 25,
		description = "Business has been good this year",
		moneyGain = 50000,
		respectGain = 10,
	},
	{
		id = "bad_year",
		name = "Tough Year",
		emoji = "📉",
		chance = 20,
		description = "Business has been slow this year",
		moneyLoss = 20000,
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

function MafiaEvents.getEventsForState(lifeState)
	local availableEvents = {}
	local age = lifeState.Age or 18
	local flags = lifeState.Flags or {}
	local mobState = lifeState.MobState or {}
	
	for _, event in ipairs(MafiaEvents.LifeEvents) do
		local meetsRequirements = true
		
		-- Check age
		if age < (event.minAge or 0) or age > (event.maxAge or 999) then
			meetsRequirements = false
		end
		
		-- Check conditions
		if event.conditions and meetsRequirements then
			if event.conditions.requiresFlags then
				for flag, value in pairs(event.conditions.requiresFlags) do
					if flags[flag] ~= value then
						meetsRequirements = false
						break
					end
				end
			end
			if event.conditions.blockedFlags then
				for flag, value in pairs(event.conditions.blockedFlags) do
					if flags[flag] == value then
						meetsRequirements = false
						break
					end
				end
			end
			if event.conditions.minRank and mobState.rankIndex then
				if mobState.rankIndex < event.conditions.minRank then
					meetsRequirements = false
				end
			end
			if event.conditions.minHeat and mobState.heat then
				if mobState.heat < event.conditions.minHeat then
					meetsRequirements = false
				end
			end
		end
		
		if meetsRequirements then
			table.insert(availableEvents, event)
		end
	end
	
	return availableEvents
end

function MafiaEvents.getRandomMafiaEvent(lifeState)
	local availableEvents = MafiaEvents.getEventsForState(lifeState)
	if #availableEvents == 0 then
		return nil
	end
	return availableEvents[math.random(1, #availableEvents)]
end

function MafiaEvents.processYearlyMobUpdate(lifeState)
	local mobState = lifeState.MobState
	if not mobState or not mobState.inMob then
		return {}
	end
	
	local events = {}
	
	for _, yearlyEvent in ipairs(MafiaEvents.YearlyEvents) do
		if math.random(100) <= yearlyEvent.chance then
			-- Check requirements
			local meetsReqs = true
			
			if yearlyEvent.minHeat and mobState.heat < yearlyEvent.minHeat then
				meetsReqs = false
			end
			if yearlyEvent.minRank and mobState.rankIndex < yearlyEvent.minRank then
				meetsReqs = false
			end
			
			if meetsReqs then
				local eventResult = {
					type = yearlyEvent.id,
					name = yearlyEvent.name,
					emoji = yearlyEvent.emoji,
					message = yearlyEvent.description,
				}
				
				-- Apply effects
				if yearlyEvent.heatIncrease then
					mobState.heat = math.min(100, mobState.heat + yearlyEvent.heatIncrease)
				end
				if yearlyEvent.heatDecrease then
					mobState.heat = math.max(0, mobState.heat - yearlyEvent.heatDecrease)
				end
				if yearlyEvent.respectGain then
					mobState.respect = mobState.respect + yearlyEvent.respectGain
				end
				if yearlyEvent.moneyGain then
					lifeState.Money = (lifeState.Money or 0) + yearlyEvent.moneyGain
					eventResult.money = yearlyEvent.moneyGain
				end
				if yearlyEvent.moneyLoss then
					lifeState.Money = math.max(0, (lifeState.Money or 0) - yearlyEvent.moneyLoss)
					eventResult.money = -yearlyEvent.moneyLoss
				end
				if yearlyEvent.arrestChance then
					if math.random(100) <= yearlyEvent.arrestChance then
						lifeState.InJail = true
						lifeState.JailYearsLeft = math.random(3, 15)
						eventResult.arrested = true
						eventResult.jailYears = lifeState.JailYearsLeft
					end
				end
				if yearlyEvent.tributePercent then
					local tribute = math.floor(mobState.respect * 10 * (yearlyEvent.tributePercent / 100))
					if lifeState.Money >= tribute then
						lifeState.Money = lifeState.Money - tribute
						mobState.loyalty = math.min(100, mobState.loyalty + 5)
						eventResult.tributePaid = tribute
					else
						mobState.loyalty = math.max(0, mobState.loyalty - 15)
						eventResult.tributeFailed = true
					end
				end
				
				table.insert(events, eventResult)
			end
		end
	end
	
	return events
end

function MafiaEvents.checkForPromotion(lifeState)
	local mobState = lifeState.MobState
	if not mobState or not mobState.inMob then
		return false
	end
	
	-- Get family info (would come from MobSystem)
	local respectThresholds = { 0, 100, 500, 2000, 10000 }
	local nextRankIndex = mobState.rankIndex + 1
	
	if nextRankIndex <= #respectThresholds then
		local requiredRespect = respectThresholds[nextRankIndex]
		if mobState.respect >= requiredRespect then
			return true, nextRankIndex
		end
	end
	
	return false, nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- SERIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

function MafiaEvents.serializeMafiaEventState(lifeState)
	local mobState = lifeState.MobState
	local flags = lifeState.Flags or {}
	
	return {
		inMob = mobState and mobState.inMob or false,
		hasGamepass = flags.mafia_gamepass or false,
		availableEventCount = #MafiaEvents.getEventsForState(lifeState),
		canBeApproached = not (mobState and mobState.inMob) and (lifeState.Age or 0) >= 18,
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #17: PROPER MAFIA EVENT INITIALIZATION
-- Ensures events are properly triggered based on mob state
-- ════════════════════════════════════════════════════════════════════════════

function MafiaEvents.initializeMobMember(lifeState, familyData)
	lifeState.MobState = lifeState.MobState or {}
	
	lifeState.MobState.inMob = true
	lifeState.MobState.familyId = familyData.id
	lifeState.MobState.familyName = familyData.name
	lifeState.MobState.familyEmoji = familyData.emoji
	lifeState.MobState.rankIndex = 1
	lifeState.MobState.rankLevel = 1
	lifeState.MobState.rankName = "Associate"
	lifeState.MobState.rankEmoji = "👤"
	lifeState.MobState.respect = 0
	lifeState.MobState.loyalty = 100
	lifeState.MobState.heat = 0
	lifeState.MobState.yearsInMob = 0
	lifeState.MobState.operationsCompleted = 0
	lifeState.MobState.operationsFailed = 0
	lifeState.MobState.earnings = 0
	lifeState.MobState.kills = 0
	
	-- Set proper flags
	lifeState.Flags = lifeState.Flags or {}
	lifeState.Flags.in_mob = true
	lifeState.Flags.mafia_member = true
	lifeState.Flags.criminal_lifestyle = true
	
	return true, "You've joined " .. familyData.name .. "!"
end

function MafiaEvents.getMobRankForRespect(respect)
	local ranks = {
		{ name = "Associate", emoji = "👤", minRespect = 0 },
		{ name = "Soldier", emoji = "🔫", minRespect = 100 },
		{ name = "Caporegime", emoji = "💰", minRespect = 500 },
		{ name = "Underboss", emoji = "🎩", minRespect = 2000 },
		{ name = "Boss", emoji = "👑", minRespect = 10000 },
	}
	
	local currentRank = ranks[1]
	for i, rank in ipairs(ranks) do
		if respect >= rank.minRespect then
			currentRank = rank
			currentRank.index = i
		end
	end
	
	return currentRank
end

function MafiaEvents.checkMobPromotion(lifeState)
	local mobState = lifeState.MobState
	if not mobState or not mobState.inMob then
		return false, nil
	end
	
	local currentRank = MafiaEvents.getMobRankForRespect(mobState.respect)
	
	if currentRank.index > mobState.rankIndex then
		-- Promotion available!
		mobState.rankIndex = currentRank.index
		mobState.rankLevel = currentRank.index
		mobState.rankName = currentRank.name
		mobState.rankEmoji = currentRank.emoji
		
		return true, string.format("🎉 Promoted to %s %s!", currentRank.emoji, currentRank.name)
	end
	
	return false, nil
end

function MafiaEvents.applyOperationResult(lifeState, operation, success, result)
	local mobState = lifeState.MobState
	if not mobState then return end
	
	if success then
		mobState.respect = mobState.respect + (result.respect or 0)
		mobState.earnings = mobState.earnings + (result.money or 0)
		mobState.operationsCompleted = (mobState.operationsCompleted or 0) + 1
		mobState.heat = math.min(100, mobState.heat + (result.heat or 0))
		lifeState.Money = (lifeState.Money or 0) + (result.money or 0)
		
		if result.kills then
			mobState.kills = (mobState.kills or 0) + result.kills
		end
		
		-- Check for promotion
		local promoted, promoMsg = MafiaEvents.checkMobPromotion(lifeState)
		if promoted then
			result.promotionMessage = promoMsg
		end
	else
		mobState.operationsFailed = (mobState.operationsFailed or 0) + 1
		mobState.heat = math.min(100, mobState.heat + (result.heat or 10))
		
		if result.arrested then
			lifeState.InJail = true
			lifeState.JailYearsLeft = result.jailYears or 5
			lifeState.Flags.in_prison = true
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- MAFIA CRIME FAMILY DATA (for reference)
-- ════════════════════════════════════════════════════════════════════════════

MafiaEvents.CrimeFamilies = {
	italian = { id = "italian", name = "Italian Mafia", emoji = "🇮🇹" },
	russian = { id = "russian", name = "Russian Bratva", emoji = "🇷🇺" },
	yakuza = { id = "yakuza", name = "Japanese Yakuza", emoji = "🇯🇵" },
	cartel = { id = "cartel", name = "Mexican Cartel", emoji = "🇲🇽" },
	triad = { id = "triad", name = "Chinese Triad", emoji = "🇨🇳" },
}

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #41: Export events in standard format for LifeEvents loader
-- The init.lua module loader expects .events, .Events, or .LifeEvents array
-- ════════════════════════════════════════════════════════════════════════════
MafiaEvents.events = MafiaEvents.LifeEvents

return MafiaEvents
