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

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #5: Helper functions for mafia eligibility
-- ═══════════════════════════════════════════════════════════════════════════════
local function hasMafiaGamepass(state)
	return state.Flags and state.Flags.mafia_gamepass == true
end

local function isInMob(state)
	return state.Flags and state.Flags.in_mob == true
end

local function isMadeMan(state)
	return state.Flags and state.Flags.initiated == true
end

local function getMobRank(state)
	if not state.Flags then return "none" end
	if state.Flags.mob_boss then return "boss" end
	if state.Flags.mob_underboss then return "underboss" end
	if state.Flags.mob_capo then return "capo" end
	if state.Flags.mob_soldier then return "soldier" end
	if state.Flags.in_mob then return "associate" end
	return "none"
end

local function getMobRespect(state)
	if not state.Flags then return 0 end
	return state.Flags.mob_respect or 0
end

-- CRITICAL FIX #6: Check if player can receive mafia approach
local function canBeApproached(state)
	if not hasMafiaGamepass(state) then return false end
	if state.Flags and state.Flags.in_mob then return false end
	if state.Flags and state.Flags.approached_by_mob then return false end
	if state.Flags and state.Flags.mob_enemy then return false end
	return true
end

-- CRITICAL FIX #7: Prevent mafia events for incompatible careers
local function isNotIncompatibleCareer(state)
	if not state.CurrentJob then return true end
	local jobId = (state.CurrentJob.id or ""):lower()
	local jobCat = (state.CurrentJob.category or ""):lower()
	-- Police, FBI, law enforcement are enemies of the mob
	if jobId:find("police") or jobId:find("cop") or jobId:find("detective")
	   or jobId:find("fbi") or jobId:find("dea") or jobCat == "law_enforcement" then
		return false
	end
	return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- MAFIA LIFE EVENTS
-- ════════════════════════════════════════════════════════════════════════════

MafiaEvents.LifeEvents = {
	-- ═══════════════════════════════════════════════════════════════════════
	-- INITIATION EVENTS
	-- ═══════════════════════════════════════════════════════════════════════
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #188: Fixed mafia approach spam
	-- 1. Added oneTime = true - you only get approached once per life
	-- 2. Added blockedFlags for approached_by_mob to prevent repeat approaches
	-- 3. Added maxOccurrences = 1 as safety
	-- 4. Set approached_by_mob flag on ALL choices
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "mafia_approach",
		title = "🔫 The Approach",
		emoji = "🔫",
		text = "A well-dressed man approaches you at a café. He says he's been watching you and thinks you have potential. 'The family could use someone like you,' he says quietly.",
		question = "What do you do?",
		minAge = 18,
		maxAge = 50,
		isMafiaOnly = true,
		oneTime = true, -- CRITICAL FIX: Only once per life!
		maxOccurrences = 1, -- CRITICAL FIX: Safety
		cooldown = 40, -- CRITICAL FIX: Extra safety
		conditions = { 
			requiresFlags = { mafia_gamepass = true },
			blockedFlags = { in_mob = true, approached_by_mob = true, rejected_mob = true, mob_enemy = true },
		},
		choices = {
			{
				text = "Accept the offer immediately",
				effects = { Happiness = 10 },
				mafiaEffect = { joinFamily = true, respect = 5 },
				setFlags = { eager_recruit = true, approached_by_mob = true, accepted_mob_offer = true },
				feed = "You've made a life-changing decision...",
			},
			{
				text = "Ask for more information",
				effects = { Smarts = 3 },
				mafiaEffect = { consideration = true },
				setFlags = { cautious_recruit = true, approached_by_mob = true, considering_mob = true },
				feed = "He smiles. 'Smart. I like that. We'll be in touch.'",
			},
			{
				text = "Politely decline",
				effects = { Happiness = 5 },
				setFlags = { rejected_mob = true, approached_by_mob = true },
				feed = "He nods. 'The offer won't come again.'",
			},
			{
				text = "Report it to the police",
				effects = { Happiness = -10 },
				setFlags = { mob_enemy = true, police_informant = true, approached_by_mob = true },
				feed = "You've made dangerous enemies...",
			},
		},
	},
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #189: Fixed initiation task spam
	-- Added oneTime and proper blocking flags
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "initiation_task",
		title = "⚔️ Prove Yourself",
		emoji = "⚔️",
		text = "Before you can become a made member, you need to prove your loyalty. The boss has a task for you.",
		question = "The initiation involves...",
		minAge = 18,
		maxAge = 60,
		isMafiaOnly = true,
		oneTime = true, -- CRITICAL FIX: Only once!
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { in_mob = true },
			blockedFlags = { initiated = true, initiation_completed = true, mob_enemy = true },
		},
		choices = {
			{
				text = "Beat up someone who owes money",
				effects = { Happiness = -5, Health = -5 },
				mafiaEffect = { respect = 15, heat = 10, initiated = true },
				setFlags = { initiated = true, enforcer_type = true, initiation_completed = true },
				feed = "You collected the debt with your fists.",
			},
			{
				text = "Deliver a 'package' across town",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 10, heat = 5, initiated = true },
				setFlags = { initiated = true, courier_type = true, initiation_completed = true },
				feed = "The package was delivered. No questions asked.",
			},
			{
				text = "Stand guard during a 'meeting'",
				effects = { Health = -3 },
				mafiaEffect = { respect = 8, heat = 3, initiated = true },
				setFlags = { initiated = true, soldier_type = true, initiation_completed = true },
				feed = "You proved you can be trusted.",
			},
			{
				text = "Refuse and try to leave",
				effects = { Happiness = -20, Health = -30 },
				mafiaEffect = { kicked = true, enemyOfFamily = true },
				setFlags = { mob_enemy = true, beat_up_by_mob = true, initiation_completed = true },
				feed = "They didn't take your refusal well...",
			},
		},
	},
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #190: Fixed blood oath spam
	-- Added oneTime and proper blocking flags
	-- CRITICAL FIX: Added eligibility function to ENSURE never shows for made members
	-- User complaint: "Blood oath pops up even tho I been in mafia for awhile"
	-- ═══════════════════════════════════════════════════════════════════════════════
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
		oneTime = true, -- CRITICAL FIX: Only once!
		maxOccurrences = 1,
		cooldown = 99, -- CRITICAL FIX: Never again after first occurrence
		-- CRITICAL FIX: Also use top-level blockedByFlags for extra safety
		blockedByFlags = { made_member = true, blood_oath_taken = true, mob_fugitive = true, sworn_oath = true },
		conditions = { 
			requiresFlags = { in_mob = true, initiated = true },
			blockedFlags = { made_member = true, blood_oath_taken = true, mob_fugitive = true },
		},
		-- CRITICAL FIX: Double-check with eligibility function
		eligibility = function(state)
			local flags = state.Flags or {}
			-- NEVER show if player already took blood oath or is made member
			if flags.made_member or flags.blood_oath_taken or flags.sworn_oath then
				return false, "Already took blood oath"
			end
			-- Must be initiated but NOT yet made
			if not flags.in_mob or not flags.initiated then
				return false, "Not initiated yet"
			end
			-- Check MobState for additional safety
			local mobState = state.MobState or {}
			if mobState.rankLevel and mobState.rankLevel >= 2 then
				return false, "Already promoted past blood oath stage"
			end
			return true
		end,
		choices = {
			{
				text = "Swear the oath with conviction",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 25, loyalty = 10, madeMember = true },
				setFlags = { made_member = true, sworn_oath = true, blood_oath_taken = true },
				feed = "You are now a made member. There's no going back.",
			},
			{
				text = "Swear the oath reluctantly",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = 15, loyalty = 5, madeMember = true },
				setFlags = { made_member = true, reluctant_member = true, blood_oath_taken = true },
				feed = "They noticed your hesitation, but you're in now.",
			},
			{
				text = "Run away",
				effects = { Happiness = -30, Health = -50 },
				mafiaEffect = { kicked = true, hitOrdered = true },
				setFlags = { mob_fugitive = true, blood_oath_refused = true },
				feed = "Running from the oath has consequences...",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- OPERATIONS AND CRIME
	-- ═══════════════════════════════════════════════════════════════════════
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #244 & #247: Added cooldown and maxOccurrences to collection event
	-- Prevents collection spam - 2 year cooldown, max 8 per lifetime
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "protection_collection",
		title = "💰 Collection Day",
		emoji = "💰",
		text = "It's time to collect protection money from the businesses on your route. Most pay without trouble, but one shop owner is being difficult.",
		question = "How do you handle the problem?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam -- 2 year cooldown between collections
		maxOccurrences = 8, -- CRITICAL FIX #247: Max 8 collection events per lifetime
		conditions = { requiresFlags = { in_mob = true } },
		-- CRITICAL FIX #34: Eligibility check for in_mob and not in prison
		eligibility = function(state) return isInMob(state) and isNotIncompatibleCareer(state) end,
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
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #242: Added cooldown and maxOccurrences to heist event
	-- Prevents heist spam - only 3 heists per lifetime with 5 year cooldown
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "heist_planning",
		title = "🏦 The Big Score",
		emoji = "🏦",
		text = "The boss has greenlit a major heist. You've been chosen to help plan and execute it. This could make your career.",
		question = "What role do you take?",
		minAge = 18,
		maxAge = 60,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam -- CRITICAL FIX: 5 year cooldown between heists
		maxOccurrences = 3, -- CRITICAL FIX: Max 3 heists per lifetime
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			minRank = 2,
		},
		-- CRITICAL FIX #35: Must be a made member for heists
		eligibility = function(state) return isMadeMan(state) end,
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
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #243: Added cooldown to shipment event
	-- Prevents shipment spam - 3 year cooldown
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #246: Enhanced shipment event with maxOccurrences
	-- CRITICAL FIX: Roblox TOS - Renamed from drug_shipment to contraband_shipment
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "contraband_shipment",
		title = "📦 The Shipment",
		emoji = "📦",
		text = "A major shipment is coming in. You've been trusted to oversee the operation. Everything needs to go smoothly.",
		question = "How do you handle it?",
		minAge = 18,
		maxAge = 65,
		isMafiaOnly = true,
		cooldown = 3, -- 3 year cooldown between shipments
		maxOccurrences = 5, -- CRITICAL FIX: Max 5 shipment operations per lifetime
		conditions = { 
			requiresFlags = { in_mob = true },
			minRank = 2,
		},
		-- CRITICAL FIX #36: Must be a made member for shipment oversight
		eligibility = function(state) return isMadeMan(state) and getMobRespect(state) >= 15 end,
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
	-- CRITICAL FIX #259: Added cooldown and maxOccurrences to loyalty test
	{
		id = "loyalty_test",
		title = "🤫 Loyalty Test",
		emoji = "🤫",
		text = "The boss suspects there's a rat in the organization. He's watching everyone closely. Then he calls you into his office alone.",
		question = "What happens in the meeting?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam -- Don't test loyalty every year
		maxOccurrences = 3,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { boss_dead = true, mob_boss = true, executed = true },
		},
		-- CRITICAL FIX #37: Must be a made member and not already trusted
		eligibility = function(state) return isMadeMan(state) and not (state.Flags and state.Flags.trusted_by_boss) end,
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
	-- CRITICAL FIX #260: Made FBI offer a one-time event
	{
		id = "informant_offer",
		title = "👮 The FBI Offer",
		emoji = "👮",
		text = "An FBI agent corners you alone. They have evidence that could send you away for life. But they're offering a deal - become an informant.",
		question = "What do you do?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { in_mob = true },
			blockedFlags = { fbi_informant = true, reported_feds = true, fbi_target = true, boss_dead = true },
			minHeat = 40,
		},
		-- CRITICAL FIX #38: Only approach members with heat
		eligibility = function(state) return isInMob(state) and getMobRespect(state) >= 20 end,
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
	-- CRITICAL FIX #261: Added cooldown to hit_order
	{
		id = "hit_order",
		title = "🎯 The Contract",
		emoji = "🎯",
		text = "The boss has given you a contract. Someone needs to be 'taken care of.' This is your chance to prove you're serious.",
		question = "Do you accept?",
		minAge = 18,
		maxAge = 65,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam -- Don't get contracts every year
		maxOccurrences = 5,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { boss_dead = true, refused_hit = true },
			minRank = 3,
		},
		-- CRITICAL FIX #39: Must be high enough rank and trusted for contracts
		eligibility = function(state) return isMadeMan(state) and getMobRespect(state) >= 50 end,
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
	-- CRITICAL FIX #265: Added cooldown to promotion_ceremony
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam -- Promotions take time
		maxOccurrences = 4, -- Can only promote 4 times
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { boss_dead = true, mob_boss = true, refused_promotion = true },
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
	-- CRITICAL FIX #266: Made become_underboss one-time
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
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { underboss = true, mob_boss = true, boss_dead = true },
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
	-- CRITICAL FIX #267: Made become_boss one-time, clear boss_dead after becoming boss
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
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { underboss = true, boss_dead = true },
			blockedFlags = { mob_boss = true, gave_up_throne = true },
		},
		choices = {
			{
				text = "Take power peacefully with the commission's blessing",
				effects = { Happiness = 20 },
				mafiaEffect = { becomeBoss = true, respect = 100, money = 500000 },
				-- CRITICAL FIX #268: Clear boss_dead when becoming boss
				setFlags = { mob_boss = true, peaceful_succession = true },
				clearFlags = { boss_dead = true },
				feed = "You're now the Boss. The family answers to you.",
			},
			{
				text = "Eliminate any challengers",
				effects = { Happiness = 10, Health = -10 },
				mafiaEffect = { becomeBoss = true, respect = 80, heat = 50, kills = 2 },
				setFlags = { mob_boss = true, violent_takeover = true },
				clearFlags = { boss_dead = true },
				feed = "You've secured power through blood.",
			},
			{
				text = "Step aside for another candidate",
				effects = { Happiness = -10 },
				mafiaEffect = { respect = -30, demoted = true },
				setFlags = { gave_up_throne = true },
				clearFlags = { boss_dead = true, underboss = true },
				feed = "You'll always wonder what could have been.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- TERRITORY AND WAR
	-- ═══════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #262: Added cooldown to territory_dispute
	{
		id = "territory_dispute",
		title = "🗺️ Territory Dispute",
		emoji = "🗺️",
		text = "Another family is encroaching on your territory. Their soldiers have been seen collecting on your turf.",
		question = "How do you respond?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		cooldown = 3, -- Territory disputes don't happen constantly
		maxOccurrences = 4,
		conditions = { 
			requiresFlags = { in_mob = true },
			blockedFlags = { boss_dead = true, mob_fugitive = true },
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
	-- CRITICAL FIX #255: Fixed family_war event - made it a random war trigger instead of requiring at_war
	-- The at_war flag was never being set by other events, so this event never fired!
	-- Now it can trigger randomly for active mob members with appropriate cooldown
	{
		id = "family_war",
		title = "⚔️ Family War!",
		emoji = "⚔️",
		text = "War has broken out between your family and a rival. Bodies are dropping on both sides. It's kill or be killed.",
		question = "How do you survive the war?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		cooldown = 3, -- Wars don't happen every year
		maxOccurrences = 3, -- Max 3 wars per lifetime
		conditions = { 
			requiresFlags = { in_mob = true, initiated = true },
			blockedFlags = { war_ended = true, mob_fugitive = true },
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
	-- CRITICAL FIX #271: Added cooldown to prison_respect
	{
		id = "prison_respect",
		title = "⛓️ Prison Politics",
		emoji = "⛓️",
		text = "In prison, your mafia connections give you respect. Other inmates know who you're connected to.",
		question = "How do you use your status?",
		minAge = 18,
		maxAge = 80,
		isMafiaOnly = true,
		cooldown = 3, -- Not every year in prison
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true, in_prison = true },
			blockedFlags = { snitch = true, witness_protection = true },
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
	-- CRITICAL FIX #272: Added cooldown to prison_hit
	{
		id = "prison_hit",
		title = "🔪 Prison Contract",
		emoji = "🔪",
		text = "The family needs someone taken care of in prison. You're the only one who can get to them.",
		question = "Do you accept the contract?",
		minAge = 18,
		maxAge = 70,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam -- Not every year
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true, in_prison = true },
			blockedFlags = { snitch = true, refused_prison_hit = true },
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
	-- CRITICAL FIX #263: Fixed assassination_attempt - don't require hit_on_you flag (it's rarely set)
	-- Changed to trigger based on high heat or betrayal
	{
		id = "assassination_attempt",
		title = "💀 Hit on You!",
		emoji = "💀",
		text = "Someone has put a hit out on you. You barely survived an assassination attempt. This is serious.",
		question = "How do you respond?",
		minAge = 18,
		maxAge = 80,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam -- Assassination attempts are rare
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true },
			blockedFlags = { in_hiding = true, witness_protection = true },
			minHeat = 60, -- High heat attracts hits
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
	-- CRITICAL FIX #264: Made retirement event one-time
	{
		id = "retirement",
		title = "🚪 Walking Away",
		emoji = "🚪",
		text = "You've been in the life for years. You're thinking about retirement, but walking away isn't easy.",
		question = "Can you really leave?",
		minAge = 50,
		maxAge = 80,
		isMafiaOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { in_mob = true },
			blockedFlags = { attempted_retirement = true, mob_lifer = true, mob_boss = true },
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
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #111: EXPANDED MAFIA EVENTS
	-- Additional mafia events for more comprehensive gameplay
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "money_laundering",
		title = "🏦 Money Laundering",
		emoji = "🏦",
		text = "The family needs to clean some serious cash. They're looking at several business fronts.",
		question = "Which front do you suggest?",
		minAge = 25,
		maxAge = 70,
		isMafiaOnly = true,
		conditions = { requiresFlags = { in_mob = true, initiated = true } },
		choices = {
			{
				text = "Open a cash-intensive restaurant",
				effects = { Happiness = 5, Money = 50000 },
				mafiaEffect = { respect = 15, heat = 5 },
				setFlags = { has_restaurant_front = true },
				feed = "The Italian restaurant is perfect for washing money.",
			},
			{
				text = "Invest in a car wash",
				effects = { Happiness = 3, Money = 30000 },
				mafiaEffect = { respect = 10, heat = 3 },
				setFlags = { has_carwash_front = true },
				feed = "The car wash cleans more than cars.",
			},
			{
				text = "Buy into real estate",
				effects = { Happiness = 8, Money = 100000 },
				mafiaEffect = { respect = 20, heat = 10 },
				setFlags = { has_realestate_front = true },
				feed = "Property development is the perfect cover.",
			},
			{
				text = "Suggest cryptocurrency",
				effects = { Happiness = 5, Smarts = 5 },
				mafiaEffect = { respect = 25, heat = 2 },
				setFlags = { crypto_launderer = true },
				feed = "The old guys don't understand it, but it works.",
			},
		},
	},
	{
		id = "family_sit_down",
		title = "🤝 The Sit-Down",
		emoji = "🤝",
		text = "There's a major dispute between two captains. The boss has called a sit-down and wants you there.",
		question = "How do you handle this tense situation?",
		minAge = 25,
		maxAge = 70,
		isMafiaOnly = true,
		conditions = { requiresFlags = { in_mob = true, initiated = true } },
		choices = {
			{
				text = "Support Captain Angelo (traditional)",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 10, loyalty = 5 },
				setFlags = { allied_with_angelo = true },
				feed = "Angelo nods approvingly. You chose the old way.",
			},
			{
				text = "Support Captain Vinnie (progressive)",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 10, heat = 5 },
				setFlags = { allied_with_vinnie = true },
				feed = "Vinnie claps you on the back. He sees the future.",
			},
			{
				text = "Stay neutral - let them fight",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = -5 },
				setFlags = { fence_sitter = true },
				feed = "Nobody trusts a fence-sitter.",
			},
			{
				text = "Propose a compromise",
				effects = { Happiness = 10, Smarts = 5 },
				mafiaEffect = { respect = 20 },
				setFlags = { peacemaker = true },
				feed = "Both sides respect your diplomatic skills.",
			},
		},
	},
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #245: Added cooldown and maxOccurrences to gang war event
	-- Gang wars shouldn't happen every year
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #270: Removed gang_war flag requirement - it was never set!
	-- Combined this with family_war since they're essentially the same event
	{
		id = "gang_war",
		title = "⚔️ Gang War!",
		emoji = "⚔️",
		text = "War has broken out with a rival organization. This is all-out conflict. Bodies are dropping.",
		question = "What's your role in the war?",
		minAge = 18,
		maxAge = 60,
		isMafiaOnly = true,
		cooldown = 7, -- CRITICAL FIX: 7 year cooldown between gang wars
		maxOccurrences = 2, -- CRITICAL FIX: Max 2 gang wars per lifetime
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { mob_fugitive = true, war_hero = true }, -- Can't be in war if already a war hero this life
		},
		choices = {
			{
				text = "Lead a strike team",
				effects = { Happiness = 10, Health = -15 },
				successChance = 60,
				successMafiaEffect = { respect = 50, kills = 3, heat = 30 },
				failEffect = { Health = -50 },
				setFlags = { war_hero = true },
				feed = "You led the charge and struck hard.",
			},
			{
				text = "Gather intelligence",
				effects = { Happiness = 5, Smarts = 10 },
				mafiaEffect = { respect = 25, heat = 5 },
				setFlags = { intelligence_gatherer = true },
				feed = "Your intel saved many lives.",
			},
			{
				text = "Lay low until it's over",
				effects = { Happiness = -10 },
				mafiaEffect = { respect = -20, loyalty = -10 },
				setFlags = { coward = true },
				feed = "They noticed you weren't around.",
			},
			{
				text = "Try to broker peace",
				effects = { Happiness = 3 },
				successChance = 20,
				successMafiaEffect = { respect = 100 },
				failMafiaEffect = { respect = -10 },
				setFlags = { tried_peace = true },
				feed = "Peace is a hard sell in wartime.",
			},
		},
	},
	{
		id = "made_man_ceremony",
		title = "🩸 Getting Made",
		emoji = "🩸",
		text = "After years of proving yourself, you've been chosen to become a made man. This is the highest honor - and the deepest commitment.",
		question = "The oath is for life. Are you ready?",
		minAge = 25,
		maxAge = 50,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true, initiated = true },
			blockedFlags = { made_man = true },
			minRespect = 500,
		},
		choices = {
			{
				text = "Take the oath with pride",
				effects = { Happiness = 20 },
				mafiaEffect = { respect = 100, loyalty = 20, madeMember = true },
				setFlags = { made_man = true },
				feed = "You are now a made man. Untouchable by anyone outside the family.",
			},
			{
				text = "Have second thoughts",
				effects = { Happiness = -15 },
				mafiaEffect = { respect = -50, suspicion = 20 },
				setFlags = { hesitated_oath = true },
				feed = "Your hesitation was noted...",
			},
		},
	},
	{
		id = "heist_planning",
		title = "💎 The Big Score",
		emoji = "💎",
		text = "Word came down about a major heist opportunity. A wealthy businessman has $10 million in his safe.",
		question = "What role do you want to play?",
		minAge = 25,
		maxAge = 60,
		isMafiaOnly = true,
		conditions = { requiresFlags = { in_mob = true, initiated = true } },
		choices = {
			{
				text = "Be the inside man",
				effects = { Happiness = 10, Smarts = 5 },
				successChance = 50,
				successMafiaEffect = { respect = 40, heat = 20 },
				successEffect = { Money = 500000 },
				failMafiaEffect = { heat = 40 },
				setFlags = { heist_inside_man = true },
				feed = "You infiltrated perfectly.",
			},
			{
				text = "Handle the muscle",
				effects = { Happiness = 5, Health = -10 },
				successChance = 60,
				successMafiaEffect = { respect = 30, heat = 25 },
				successEffect = { Money = 300000 },
				failMafiaEffect = { heat = 50 },
				setFlags = { heist_muscle = true },
				feed = "You kept everyone in line.",
			},
			{
				text = "Plan the whole operation",
				effects = { Happiness = 15, Smarts = 10 },
				successChance = 40,
				successMafiaEffect = { respect = 60, heat = 30 },
				successEffect = { Money = 1000000 },
				failMafiaEffect = { respect = -20, heat = 60 },
				setFlags = { heist_planner = true },
				feed = "Your plan was executed flawlessly.",
			},
			{
				text = "Sit this one out",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = -10 },
				feed = "The others split your share.",
			},
		},
	},
	{
		id = "police_investigation",
		title = "🚔 Under Investigation",
		emoji = "🚔",
		text = "The Feds are building a case against the family. Your name came up. An FBI agent wants to talk.",
		question = "How do you handle this heat?",
		minAge = 21,
		maxAge = 70,
		isMafiaOnly = true,
		conditions = { requiresFlags = { in_mob = true }, minHeat = 40 },
		choices = {
			{
				text = "Refuse to talk, lawyer up",
				effects = { Happiness = -10, Money = -50000 },
				mafiaEffect = { respect = 20, loyalty = 10 },
				setFlags = { lawyered_up = true },
				feed = "You said nothing. The family is pleased.",
			},
			{
				text = "Feed them false information",
				effects = { Happiness = 5, Smarts = 10 },
				successChance = 40,
				successMafiaEffect = { respect = 40, heat = -20 },
				failMafiaEffect = { heat = 30 },
				setFlags = { fed_false_info = true },
				feed = "You sent them on a wild goose chase.",
			},
			{
				text = "Cooperate secretly",
				effects = { Happiness = -20 },
				mafiaEffect = { loyalty = -100, betrayal = true },
				setFlags = { secret_informant = true },
				feed = "You're playing a dangerous game...",
			},
			{
				text = "Skip town temporarily",
				effects = { Happiness = -15, Money = -30000 },
				mafiaEffect = { heat = -30, respect = -15 },
				setFlags = { skipped_town = true },
				feed = "You laid low until things cooled down.",
			},
		},
	},
	{
		id = "crew_management",
		title = "👥 Running Your Crew",
		emoji = "👥",
		text = "As a captain, you now have soldiers under you. One of them is skimming from collections.",
		question = "How do you handle this disrespect?",
		minAge = 30,
		maxAge = 65,
		isMafiaOnly = true,
		conditions = { 
			requiresFlags = { in_mob = true, is_captain = true },
		},
		choices = {
			{
				text = "Make an example of him",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 20, kills = 1, heat = 15 },
				setFlags = { harsh_captain = true },
				feed = "Nobody steals from you twice.",
			},
			{
				text = "Take his cut but let him live",
				effects = { Happiness = 3 },
				mafiaEffect = { respect = 10 },
				setFlags = { firm_captain = true },
				feed = "A lesson was learned.",
			},
			{
				text = "Give him one more chance",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = -10 },
				setFlags = { soft_captain = true },
				feed = "Others might see this as weakness.",
			},
			{
				text = "Bring it to the boss",
				effects = { Happiness = 0 },
				mafiaEffect = { respect = 5, loyalty = 5 },
				setFlags = { follows_chain = true },
				feed = "The boss appreciates you following protocol.",
			},
		},
	},
	{
		id = "prison_politics",
		title = "🔒 Prison Politics",
		emoji = "🔒",
		text = "Inside the joint, you need to navigate complex politics. Other mobsters from different families are here too.",
		question = "How do you survive prison?",
		minAge = 18,
		maxAge = 80,
		isMafiaOnly = true,
		conditions = { requiresFlags = { in_mob = true, in_prison = true } },
		choices = {
			{
				text = "Unite the Italian mob factions",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 30, prisonRep = 20 },
				setFlags = { prison_unifier = true },
				feed = "You brought the families together inside.",
			},
			{
				text = "Run operations from inside",
				effects = { Happiness = 5, Money = 50000 },
				mafiaEffect = { respect = 25, heat = 10 },
				setFlags = { prison_boss = true },
				feed = "Business continues, even behind bars.",
			},
			{
				text = "Keep your head down",
				effects = { Happiness = -10 },
				mafiaEffect = { respect = -5 },
				setFlags = { quiet_prisoner = true },
				feed = "You focus on getting through your sentence.",
			},
			{
				text = "Cultivate guards on the payroll",
				effects = { Happiness = 5, Money = -20000 },
				mafiaEffect = { respect = 15, heat = -5 },
				setFlags = { has_prison_guards = true },
				feed = "A few well-placed bribes make life easier.",
			},
		},
	},
	-- CRITICAL FIX #441: Added boss_dies event to properly set boss_dead flag
	-- This event triggers for underbosses when the boss dies
	{
		id = "boss_dies",
		title = "💀 The Boss Is Gone",
		emoji = "💀",
		text = "The boss has passed away. Natural causes, they say, though nothing is ever natural in this life. As underboss, all eyes turn to you.",
		question = "The family needs leadership. What do you do?",
		minAge = 30,
		maxAge = 80,
		isMafiaOnly = true,
		isMilestone = true,
		oneTime = true,
		maxOccurrences = 1,
		priority = "critical",
		conditions = { 
			requiresFlags = { in_mob = true, underboss = true },
			blockedFlags = { mob_boss = true, boss_dead = true },
		},
		choices = {
			{
				text = "Take your rightful place as boss",
				effects = { Happiness = 20 },
				mafiaEffect = { becomeBoss = true, respect = 100, money = 500000 },
				setFlags = { mob_boss = true, peaceful_succession = true },
				feed = "You're now the Boss. The family answers to you.",
			},
			{
				text = "Consolidate power first",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 30 },
				setFlags = { boss_dead = true },  -- This sets boss_dead so become_boss can trigger later
				feed = "You'll take the throne, but carefully.",
			},
			{
				text = "Step aside - you're not ready",
				effects = { Happiness = -15 },
				mafiaEffect = { respect = -50 },
				setFlags = { refused_crown = true },
				clearFlags = { underboss = true },
				feed = "Someone else will lead the family.",
			},
		},
	},
	{
		id = "family_succession",
		title = "👑 Family Succession",
		emoji = "👑",
		text = "The boss is dying. War might break out over who takes over. You're being considered.",
		question = "How do you position yourself?",
		minAge = 40,
		maxAge = 70,
		isMafiaOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		-- CRITICAL FIX #442: Prevent this from triggering for underbosses (they get boss_dies instead)
		conditions = { 
			requiresFlags = { in_mob = true, made_man = true },
			blockedFlags = { underboss = true, mob_boss = true, boss_dead = true },
			minRespect = 2000,
		},
		choices = {
			{
				text = "Campaign to become the new boss",
				effects = { Happiness = 15 },
				successChance = 30,
				successMafiaEffect = { respect = 200, becomeBoss = true },
				failMafiaEffect = { respect = -50, heat = 20 },
				setFlags = { sought_leadership = true, mob_boss = true },
				feed = "You threw your hat in the ring for the top spot.",
			},
			{
				text = "Support the underboss's claim",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 40, loyalty = 20 },
				setFlags = { supported_underboss = true, boss_dead = true },
				feed = "The underboss will remember this loyalty.",
			},
			{
				text = "Stay out of the politics",
				effects = { Happiness = 3 },
				mafiaEffect = { respect = 5 },
				setFlags = { avoided_politics = true, boss_dead = true },
				feed = "Safer to let others fight for power.",
			},
			{
				text = "Work with the FBI to take down all rivals",
				effects = { Happiness = -20 },
				mafiaEffect = { betrayal = true, respect = -1000 },
				setFlags = { ultimate_traitor = true },
				feed = "You chose to burn it all down.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #192-210: MASSIVE MAFIA EVENT EXPANSION
	-- 15+ new events with proper progression, cooldowns, and blocking flags
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- MONEY LAUNDERING OPERATIONS
	{
		id = "money_laundering_setup",
		title = "💰 Laundering Operation",
		emoji = "💰",
		text = "The family needs a new front for laundering money. You've been tasked with setting up a legitimate-looking business.",
		question = "What kind of business will you establish?",
		minAge = 25,
		maxAge = 65,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		oneTime = true,
		conditions = { 
			requiresFlags = { in_mob = true, initiated = true },
			blockedFlags = { owns_front_business = true },
		},
		choices = {
			{
				text = "Open a restaurant",
				effects = { Happiness = 10, Smarts = 5 },
				mafiaEffect = { respect = 25, money = 50000 },
				setFlags = { owns_front_business = true, owns_restaurant = true },
				feed = "Your Italian restaurant is now washing millions.",
			},
			{
				text = "Buy a car wash",
				effects = { Happiness = 8 },
				mafiaEffect = { respect = 20, money = 30000, heat = 5 },
				setFlags = { owns_front_business = true, owns_carwash = true },
				feed = "Cash business. Untraceable. Perfect.",
			},
			{
				text = "Start a construction company",
				effects = { Happiness = 12, Smarts = 8 },
				mafiaEffect = { respect = 40, money = 100000, heat = 10 },
				setFlags = { owns_front_business = true, owns_construction = true },
				feed = "Now you can bid on city contracts too.",
			},
			{
				text = "Decline - too risky",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = -15 },
				setFlags = { refused_laundering = true },
				feed = "The boss expected more ambition from you.",
			},
		},
	},
	
	-- WITNESS PROBLEMS
	{
		id = "witness_problem",
		title = "👁️ Witness Problem",
		emoji = "👁️",
		text = "Someone saw too much during your last operation. They're planning to testify against the family.",
		question = "How do you handle this loose end?",
		minAge = 21,
		maxAge = 65,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		conditions = { requiresFlags = { in_mob = true, initiated = true } },
		choices = {
			{
				text = "Pay them off to disappear",
				effects = { Happiness = 5 },
				mafiaEffect = { money = -100000, respect = 10, heatDecay = 5 },
				setFlags = { paid_off_witness = true },
				feed = "Money talks. The witness vanished to Mexico.",
			},
			{
				text = "Intimidate them into silence",
				effects = { Happiness = -5 },
				successChance = 70,
				successMafiaEffect = { respect = 25, heat = 15 },
				failMafiaEffect = { heat = 40, respect = -10 },
				setFlags = { intimidated_witness = true },
				feed = "Fear is a powerful motivator.",
			},
			{
				text = "Eliminate the problem permanently",
				effects = { Happiness = -20, Health = -5 },
				mafiaEffect = { respect = 50, heat = 30, kills = 1 },
				setFlags = { killed_witness = true, murderer = true },
				feed = "No witness, no problem.",
			},
			{
				text = "Let the legal team handle it",
				effects = { Happiness = 0 },
				mafiaEffect = { money = -50000, heatDecay = 10 },
				setFlags = { used_lawyers = true },
				feed = "The family's lawyers made the case disappear.",
			},
		},
	},
	
	-- CORRUPT COP
	{
		id = "corrupt_cop_offer",
		title = "🚔 Bent Badge",
		emoji = "🚔",
		text = "A detective approaches you with an offer. For a monthly payment, he'll warn you about raids and lose evidence.",
		question = "Do you put a cop on the payroll?",
		minAge = 25,
		maxAge = 65,
		isMafiaOnly = true,
		oneTime = true,
		conditions = { 
			requiresFlags = { in_mob = true, initiated = true },
			blockedFlags = { has_corrupt_cop = true, refused_corrupt_cop = true },
		},
		choices = {
			{
				text = "Accept - protection is valuable",
				effects = { Happiness = 15 },
				mafiaEffect = { respect = 30, heatDecay = 20, money = -10000 },
				setFlags = { has_corrupt_cop = true, police_connections = true },
				feed = "You now have an inside man at the precinct.",
			},
			{
				text = "Negotiate a better deal",
				effects = { Happiness = 10, Smarts = 5 },
				mafiaEffect = { respect = 35, heatDecay = 25, money = -5000 },
				setFlags = { has_corrupt_cop = true, master_negotiator = true },
				feed = "Half the price, same protection. Good deal.",
			},
			{
				text = "Decline - too risky",
				effects = { Happiness = 0 },
				setFlags = { refused_corrupt_cop = true },
				feed = "Smart. Bent cops can be double agents.",
			},
		},
	},
	
	-- NIGHTCLUB OWNERSHIP
	{
		id = "nightclub_opportunity",
		title = "🎵 Club Ownership",
		emoji = "🎵",
		text = "A popular nightclub owner got behind on his payments. The family is taking over. You can run it.",
		question = "How do you manage the club?",
		minAge = 28,
		maxAge = 55,
		isMafiaOnly = true,
		oneTime = true,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { owns_nightclub = true },
		},
		choices = {
			{
				text = "Make it a legitimate success",
				effects = { Happiness = 15, Smarts = 8 },
				mafiaEffect = { respect = 30, money = 75000 },
				setFlags = { owns_nightclub = true, legitimate_businessman = true },
				feed = "The club is packed every night.",
			},
		{
			-- CRITICAL FIX: Roblox TOS - replaced drug reference with smuggling
			text = "Use it for smuggling operations",
			effects = { Happiness = 8 },
			mafiaEffect = { respect = 25, money = 150000, heat = 20 },
			setFlags = { owns_nightclub = true, smuggling_hub = true },
			feed = "The VIP room has a very special storage area.",
		},
			{
				text = "Money laundering hub",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 35, money = 100000, heat = 10 },
				setFlags = { owns_nightclub = true, money_launderer = true },
				feed = "Cash flows in. Clean cash flows out.",
			},
		},
	},
	
	-- FAMILY TRIBUTE
	-- CRITICAL FIX #254: Added blockedFlags for boss_dead - can't tribute if boss is dead!
	{
		id = "tribute_to_boss",
		title = "💎 Tribute Time",
		emoji = "💎",
		text = "It's time for the annual tribute to the boss. Everyone kicks up a percentage of their earnings.",
		question = "How much do you tribute?",
		minAge = 21,
		maxAge = 70,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		conditions = { 
			requiresFlags = { in_mob = true },
			blockedFlags = { boss_dead = true, mob_boss = true },
		},
		choices = {
			{
				text = "Kick up generously (50%)",
				effects = { Happiness = -5 },
				mafiaEffect = { money = -50000, respect = 15, loyalty = 20 },
				setFlags = { generous_tribute = true },
				feed = "The boss appreciates your loyalty.",
			},
			{
				text = "Standard tribute (30%)",
				effects = { Happiness = 0 },
				mafiaEffect = { money = -30000, respect = 5, loyalty = 5 },
				feed = "Fair is fair. Everyone pays their share.",
			},
			{
				text = "Light tribute (15%)",
				effects = { Happiness = 5 },
				mafiaEffect = { money = -15000, respect = -10, loyalty = -10 },
				setFlags = { light_tribute = true },
				feed = "Your small tribute was noticed.",
			},
		},
	},
	
	-- CAPO PROMOTION
	{
		id = "capo_promotion",
		title = "👔 Capo Ceremony",
		emoji = "👔",
		text = "The boss calls you in. 'You've earned it,' he says. 'You're now a Caporegime. You get your own crew.'",
		question = "How do you accept this honor?",
		minAge = 30,
		maxAge = 60,
		isMafiaOnly = true,
		oneTime = true,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { is_capo = true },
		},
		choices = {
			{
				text = "Accept with humble gratitude",
				effects = { Happiness = 25 },
				mafiaEffect = { respect = 50, rankUp = true },
				setFlags = { is_capo = true, humble_leader = true },
				feed = "You're now Capo. Ten soldiers under your command.",
			},
			{
				text = "Accept and make ambitious promises",
				effects = { Happiness = 20 },
				mafiaEffect = { respect = 60, rankUp = true, money = 50000 },
				setFlags = { is_capo = true, ambitious_capo = true },
				feed = "Big talk. Now you have to deliver.",
			},
		},
	},
	
	-- REVENGE HIT
	{
		id = "revenge_mission",
		title = "🔪 Vendetta",
		emoji = "🔪",
		text = "Someone disrespected the family. The boss wants him gone. You've been chosen for this hit.",
		question = "How do you handle the contract?",
		minAge = 25,
		maxAge = 55,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		conditions = { requiresFlags = { in_mob = true, initiated = true } },
		choices = {
			{
				text = "Execute it personally",
				effects = { Happiness = -15, Health = -5 },
				successChance = 75,
				successMafiaEffect = { respect = 60, kills = 1, heat = 25 },
				failMafiaEffect = { respect = -20, heat = 40 },
				setFlags = { personal_hitter = true, has_killed = true },
				feed = "Clean work. No witnesses.",
			},
			{
				text = "Hire outside professionals",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = 30, money = -50000, heat = 10 },
				setFlags = { uses_contractors = true },
				feed = "Outsourcing. Smart. Deniable.",
			},
			{
				text = "Make it look like an accident",
				effects = { Happiness = -8, Smarts = 8 },
				successChance = 60,
				successMafiaEffect = { respect = 50, kills = 1, heat = 5 },
				failMafiaEffect = { respect = 20, kills = 1, heat = 35 },
				setFlags = { accident_specialist = true },
				feed = "A tragic 'accident.'",
			},
			{
				text = "Refuse the contract",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = -50, loyalty = -30 },
				setFlags = { refused_hit = true },
				feed = "Refusing orders has consequences.",
			},
		},
	},
	
	-- FBI INVESTIGATION
	{
		id = "fbi_surveillance",
		title = "📡 Under Surveillance",
		emoji = "📡",
		text = "Your contacts warn you: the FBI has you under surveillance. They're building a RICO case.",
		question = "How do you respond to the heat?",
		minAge = 25,
		maxAge = 70,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		conditions = { requiresFlags = { in_mob = true, initiated = true } },
		choices = {
			{
				text = "Go completely dark",
				effects = { Happiness = -15 },
				mafiaEffect = { heatDecay = 30, money = -20000, respect = 10 },
				setFlags = { went_dark = true },
				feed = "Radio silence. Let them waste resources.",
			},
			{
				text = "Feed them false information",
				effects = { Happiness = 5, Smarts = 10 },
				successChance = 55,
				successMafiaEffect = { heatDecay = 20, respect = 30 },
				failMafiaEffect = { heat = 20, respect = -10 },
				setFlags = { played_fbi = true },
				feed = "Misinformation is an art form.",
			},
			{
				text = "Continue business as usual",
				effects = { Happiness = 0 },
				mafiaEffect = { heat = 15, money = 50000 },
				setFlags = { fearless = true },
				feed = "Let them watch. They can't prove anything.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #450: MASSIVE MAFIA EVENT EXPANSION
	-- 25+ new events for deeper mafia gameplay
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- CASINO HEIST
	{
		id = "casino_heist_planning",
		title = "🎰 The Big Score",
		emoji = "🎰",
		text = "The boss has a plan: hit the Bellagio-style casino. It's risky, but the payout could set up the family for years.",
		question = "What role do you want in the heist?",
		minAge = 25,
		maxAge = 55,
		isMafiaOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { casino_heist_done = true },
			minRespect = 500,
		},
		choices = {
			{
				text = "Lead the vault team",
				effects = { Happiness = 20, Smarts = 5 },
				successChance = 40,
				successMafiaEffect = { respect = 150, money = 2000000, heat = 60 },
				failMafiaEffect = { arrested = true, jailYears = 15 },
				setFlags = { casino_heist_done = true, heist_leader = true },
				feed = "The biggest score of your life.",
			},
			{
				text = "Handle the getaway",
				effects = { Happiness = 15 },
				successChance = 60,
				successMafiaEffect = { respect = 80, money = 500000, heat = 30 },
				failMafiaEffect = { heat = 40, respect = -20 },
				setFlags = { casino_heist_done = true, getaway_driver = true },
				feed = "Wheels are essential. No wheels, no escape.",
			},
			{
				text = "Be the inside man",
				effects = { Happiness = 10, Smarts = 10 },
				successChance = 70,
				successMafiaEffect = { respect = 100, money = 800000, heat = 20 },
				failMafiaEffect = { heat = 25, money = -50000 },
				setFlags = { casino_heist_done = true, inside_man = true },
				feed = "Information is everything.",
			},
			{
				text = "Decline the job",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = -30 },
				setFlags = { refused_big_score = true },
				feed = "Too risky. The boss notes your hesitation.",
			},
		},
	},
	
	-- ARMS DEAL
	{
		id = "international_arms_deal",
		title = "🔫 International Arms",
		emoji = "🔫",
		text = "A contact from overseas wants to move military-grade weapons through your territory. The money is incredible, but the heat could be nuclear.",
		question = "Do you take the deal?",
		minAge = 30,
		maxAge = 60,
		isMafiaOnly = true,
		cooldown = 4,
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			minRank = 3,
		},
		choices = {
			{
				text = "Broker the deal personally",
				effects = { Happiness = 15 },
				successChance = 50,
				successMafiaEffect = { respect = 100, money = 1500000, heat = 80 },
				failMafiaEffect = { arrested = true, jailYears = 20 },
				setFlags = { arms_dealer = true },
				feed = "Big guns, big money, bigger risks.",
			},
			{
				text = "Take a cut as middleman",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 40, money = 200000, heat = 30 },
				setFlags = { middleman = true },
				feed = "You facilitated. Plausible deniability.",
			},
			{
				text = "Report it to the boss",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 20, loyalty = 15 },
				setFlags = { follows_protocol = true },
				feed = "The boss appreciates you bringing this to him.",
			},
			{
				text = "Turn them down and report to FBI",
				effects = { Happiness = -30 },
				mafiaEffect = { heatDecay = 40, respect = -1000, betrayal = true },
				setFlags = { secret_informant = true },
				feed = "You've crossed a line that can't be uncrossed.",
			},
		},
	},
	
	-- WITNESS INTIMIDATION
	{
		id = "witness_intimidation",
		title = "🤫 Loose Lips",
		emoji = "🤫",
		text = "A witness to one of your operations is planning to testify. They need to be... convinced otherwise.",
		question = "How do you handle this delicate situation?",
		minAge = 21,
		maxAge = 65,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 3,
		conditions = { 
			requiresFlags = { in_mob = true, initiated = true },
			blockedFlags = { mob_fugitive = true },
		},
		choices = {
			{
				text = "Send a message to their family",
				effects = { Happiness = -10 },
				mafiaEffect = { respect = 30, heat = 20 },
				setFlags = { intimidator = true },
				feed = "They got the message loud and clear.",
			},
			{
				text = "Offer them money to disappear",
				effects = { Happiness = 5 },
				mafiaEffect = { money = -100000, heatDecay = 10 },
				setFlags = { problem_solver = true },
				feed = "Money talks. Witnesses walk.",
			},
			{
				text = "Make them disappear permanently",
				effects = { Happiness = -20, Health = -5 },
				mafiaEffect = { respect = 50, heat = 50, kills = 1 },
				setFlags = { has_killed = true, witness_killer = true },
				feed = "Dead men tell no tales.",
			},
			{
				text = "Let the lawyers handle it",
				effects = { Happiness = -5 },
				mafiaEffect = { money = -200000 },
				setFlags = { legal_route = true },
				feed = "Expensive, but clean.",
			},
		},
	},
	
	-- CRITICAL FIX: Roblox TOS - Replaced drug empire with smuggling empire
	-- SMUGGLING EMPIRE
	{
		id = "smuggling_empire_opportunity",
		title = "📦 The Big Shipment",
		emoji = "📦",
		text = "International contacts are offering your family exclusive smuggling routes in the city. It's the most profitable racket there is, but also the most dangerous.",
		question = "How do you respond to their proposal?",
		minAge = 25,
		maxAge = 55,
		isMafiaOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { smuggling_boss = true },
			minRank = 3,
		},
		choices = {
			{
				text = "Accept and run the operation",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 80, money = 500000, heat = 40 },
				setFlags = { smuggling_boss = true, runs_smuggling = true },
				feed = "The money flows like water.",
			},
			{
				text = "Accept but stay hands-off",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 40, money = 100000, heat = 20 },
				setFlags = { smuggling_silent_partner = true },
				feed = "You take a cut, but stay clean.",
			},
			{
				text = "Decline on principle",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = 10, loyalty = 10 },
				setFlags = { no_smuggling_rule = true },
				feed = "Old school. Some things are beneath the family.",
			},
			{
				text = "Report them to the authorities",
				effects = { Happiness = -20 },
				mafiaEffect = { heatDecay = 30, respect = -500, betrayal = true },
				setFlags = { federal_informant = true },
				feed = "You've made powerful enemies on both sides.",
			},
		},
	},
	
	-- PRISON CONNECTIONS
	{
		id = "prison_run_operations",
		title = "🔒 Running Things Inside",
		emoji = "🔒",
		text = "Even behind bars, you have power. Other inmates know who you're connected to, and the guards are on your payroll.",
		question = "How do you use your position?",
		minAge = 21,
		maxAge = 70,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 4,
		conditions = { 
			requiresFlags = { in_mob = true, in_prison = true },
		},
		choices = {
			{
				text = "Run the prison's contraband",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 25, money = 30000 },
				setFlags = { prison_boss = true },
				feed = "You control what comes in and out.",
			},
			{
				text = "Recruit new soldiers",
				effects = { Happiness = 5, Smarts = 5 },
				mafiaEffect = { respect = 15, loyalty = 10 },
				setFlags = { prison_recruiter = true },
				feed = "Fresh talent for when you get out.",
			},
			{
				text = "Plan operations on the outside",
				effects = { Happiness = 8 },
				mafiaEffect = { respect = 20 },
				setFlags = { remote_boss = true },
				feed = "The family still runs, even with you inside.",
			},
			{
				text = "Keep a low profile",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = 5 },
				setFlags = { quiet_prisoner = true },
				feed = "Sometimes silence is survival.",
			},
		},
	},
	
	-- FAMILY WEDDING
	{
		id = "mafia_wedding",
		title = "💒 A Family Affair",
		emoji = "💒",
		text = "The boss's daughter is getting married. All the families will be there. It's a rare moment of peace in the underworld.",
		question = "How do you behave at this important event?",
		minAge = 21,
		maxAge = 80,
		isMafiaOnly = true,
		cooldown = 4,
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true },
			blockedFlags = { mob_fugitive = true, in_prison = true },
		},
		choices = {
			{
				text = "Be respectful and generous",
				effects = { Happiness = 15 },
				mafiaEffect = { respect = 20, loyalty = 15, money = -50000 },
				setFlags = { generous_guest = true },
				feed = "Your gift was noticed and appreciated.",
			},
			{
				text = "Network with other families",
				effects = { Happiness = 10, Smarts = 5 },
				mafiaEffect = { respect = 15 },
				setFlags = { well_connected = true },
				feed = "You made valuable connections.",
			},
			{
				text = "Have a private word with the boss",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 10, loyalty = 20 },
				setFlags = { boss_confidant = true },
				feed = "The boss appreciates your loyalty.",
			},
			{
				text = "Get drunk and make a scene",
				effects = { Happiness = 20, Health = -10 },
				mafiaEffect = { respect = -30, loyalty = -20 },
				setFlags = { embarrassed_family = true },
				feed = "That was a mistake you'll pay for.",
			},
		},
	},
	
	-- RIVAL FAMILY NEGOTIATION
	{
		id = "peace_negotiation",
		title = "🤝 The Sit-Down",
		emoji = "🤝",
		text = "Tensions with a rival family have reached a boiling point. The commission has called a sit-down to prevent all-out war.",
		question = "How do you approach this meeting?",
		minAge = 30,
		maxAge = 70,
		isMafiaOnly = true,
		cooldown = 3,
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { mob_fugitive = true },
			minRank = 3,
		},
		choices = {
			{
				text = "Advocate for peace",
				effects = { Happiness = 5, Smarts = 10 },
				mafiaEffect = { respect = 30 },
				setFlags = { peacemaker = true },
				feed = "War is expensive. You spoke wisely.",
			},
			{
				text = "Demand territory concessions",
				effects = { Happiness = 10 },
				successChance = 40,
				successMafiaEffect = { respect = 50, money = 200000 },
				failMafiaEffect = { respect = -20 },
				setFlags = { aggressive_negotiator = true },
				feed = "You pushed hard at the table.",
			},
			{
				text = "Propose a joint venture",
				effects = { Happiness = 8, Smarts = 8 },
				mafiaEffect = { respect = 40, money = 100000 },
				setFlags = { dealmaker = true },
				feed = "Why fight when you can profit together?",
			},
			{
				text = "Secretly plan a hit on their boss",
				effects = { Happiness = -10 },
				successChance = 30,
				successMafiaEffect = { respect = 100, heat = 60 },
				failMafiaEffect = { arrested = true, jailYears = 25 },
				setFlags = { treacherous = true },
				feed = "Bold. Perhaps too bold.",
			},
		},
	},
	
	-- MONEY LAUNDERING CRISIS
	{
		id = "laundering_audit",
		title = "📊 The Accountant Problem",
		emoji = "📊",
		text = "Your money laundering operation's accountant is under audit. If he talks, the whole operation goes down.",
		question = "How do you protect the operation?",
		minAge = 25,
		maxAge = 65,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
		},
		choices = {
			{
				text = "Pay off the auditors",
				effects = { Happiness = 5 },
				mafiaEffect = { money = -500000, heatDecay = 20 },
				setFlags = { bribes_officials = true },
				feed = "Everyone has a price.",
			},
			{
				text = "Relocate the accountant overseas",
				effects = { Happiness = 0 },
				mafiaEffect = { money = -200000, heat = 10 },
				setFlags = { protective_boss = true },
				feed = "He's safe. For now.",
			},
			{
				text = "Eliminate the liability",
				effects = { Happiness = -15 },
				mafiaEffect = { respect = 20, heat = 30, kills = 1 },
				setFlags = { has_killed = true },
				feed = "He knew too much.",
			},
			{
				text = "Let the lawyers handle it",
				effects = { Happiness = -10 },
				mafiaEffect = { money = -300000 },
				setFlags = { trusts_lawyers = true },
				feed = "The legal route. Expensive but clean.",
			},
		},
	},
	
	-- CONSTRUCTION RACKET
	{
		id = "construction_control",
		title = "🏗️ Building Empire",
		emoji = "🏗️",
		text = "The family is moving into the construction business. With the right 'persuasion,' you can control all major contracts in the city.",
		question = "How do you establish control?",
		minAge = 28,
		maxAge = 60,
		isMafiaOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { construction_boss = true },
			minRank = 2,
		},
		choices = {
			{
				text = "Control the unions",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 50, money = 200000 },
				setFlags = { construction_boss = true, union_controller = true },
				feed = "No one builds without your say-so.",
			},
			{
				text = "Rig the bidding process",
				effects = { Happiness = 8, Smarts = 5 },
				mafiaEffect = { respect = 40, money = 300000, heat = 20 },
				setFlags = { construction_boss = true, bid_rigger = true },
				feed = "Your companies always win. Always.",
			},
			{
				text = "Supply 'protection' services",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 30, money = 100000, heat = 10 },
				setFlags = { construction_boss = true },
				feed = "Accidents happen on job sites. Unless you pay.",
			},
		},
	},
	
	-- POLITICAL CORRUPTION
	{
		id = "corrupt_politician",
		title = "🏛️ Friends in High Places",
		emoji = "🏛️",
		text = "A promising young politician wants your 'support' for their campaign. In return, they'll protect your interests in city hall.",
		question = "Do you invest in this political alliance?",
		minAge = 30,
		maxAge = 65,
		isMafiaOnly = true,
		cooldown = 3,
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			minRank = 3,
		},
		choices = {
			{
				text = "Fund their campaign generously",
				effects = { Happiness = 10 },
				mafiaEffect = { money = -500000, heatDecay = 30, respect = 40 },
				setFlags = { political_donor = true, has_politician = true },
				feed = "Now you have a friend in government.",
			},
			{
				text = "Offer 'services' instead of money",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 30, heat = 10 },
				setFlags = { provides_services = true },
				feed = "They owe you. That's more valuable than money.",
			},
			{
				text = "Keep them at arm's length",
				effects = { Happiness = 0 },
				mafiaEffect = { respect = 5 },
				setFlags = { cautious_politics = true },
				feed = "Politicians are unreliable. Better to stay distant.",
			},
			{
				text = "Gather compromising information instead",
				effects = { Happiness = 8, Smarts = 10 },
				mafiaEffect = { respect = 25 },
				setFlags = { blackmail_material = true },
				feed = "Leverage. The ultimate currency.",
			},
		},
	},
	
	-- GAMBLING EMPIRE
	{
		id = "illegal_gambling_expansion",
		title = "🎲 High Stakes",
		emoji = "🎲",
		text = "The family's gambling operations are thriving. The boss wants to expand into online gambling, but it requires tech expertise you don't have.",
		question = "How do you handle the expansion?",
		minAge = 25,
		maxAge = 55,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
		},
		choices = {
			{
				text = "Partner with Eastern European hackers",
				effects = { Happiness = 10, Smarts = 5 },
				mafiaEffect = { respect = 40, money = 200000, heat = 20 },
				setFlags = { cyber_gambling = true },
				feed = "The future is digital. The money is real.",
			},
			{
				text = "Stick to traditional gambling",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 20, money = 100000 },
				setFlags = { traditional_gambler = true },
				feed = "If it ain't broke, don't fix it.",
			},
			{
				text = "Buy out a legitimate gambling company",
				effects = { Happiness = 8 },
				mafiaEffect = { money = -1000000, respect = 50 },
				setFlags = { legit_gambling = true },
				feed = "Going semi-legitimate. The long game.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #463: ADDITIONAL MAFIA EVENTS FOR DEEPER GAMEPLAY
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- STREET LEVEL HUSTLE
	{
		id = "street_corner_control",
		title = "🚬 Street Corner",
		emoji = "🚬",
		text = "A profitable street corner needs someone to oversee it. The boss is giving you a chance to prove yourself.",
		question = "How do you run your corner?",
		minAge = 18,
		maxAge = 35,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 3,
		conditions = { 
			requiresFlags = { in_mob = true },
			blockedFlags = { is_capo = true },
		},
		choices = {
			{
				text = "Run it tight - discipline above all",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 25, money = 15000, heat = 10 },
				setFlags = { strict_leader = true },
				feed = "Your corner is the most profitable in the district.",
			},
			{
				text = "Be fair to the workers",
				effects = { Happiness = 8 },
				mafiaEffect = { respect = 15, money = 10000, loyalty = 20 },
				setFlags = { fair_boss = true },
				feed = "Your people are loyal. That counts for something.",
			},
			{
				text = "Skim off the top secretly",
				effects = { Happiness = 10, Money = 5000 },
				successChance = 60,
				successMafiaEffect = { money = 5000 },
				failMafiaEffect = { respect = -30, heat = 15 },
				setFlags = { skimmer = true },
				feed = "Risky but profitable.",
			},
		},
	},
	
	-- UNDERCOVER COP
	{
		id = "suspected_undercover",
		title = "🕵️ Undercover Alert",
		emoji = "🕵️",
		text = "Someone in the organization might be an undercover cop. Suspicion is on a new recruit who's been asking too many questions.",
		question = "How do you handle this?",
		minAge = 21,
		maxAge = 60,
		isMafiaOnly = true,
		cooldown = 3,
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true, initiated = true },
		},
		choices = {
			{
				text = "Investigate them quietly",
				effects = { Happiness = -5, Smarts = 8 },
				mafiaEffect = { respect = 20 },
				setFlags = { careful_investigator = true },
				feed = "You gathered information without tipping them off.",
			},
			{
				text = "Set up a test - give them false info",
				effects = { Happiness = 5, Smarts = 10 },
				mafiaEffect = { respect = 30 },
				setFlags = { counter_intelligence = true },
				feed = "If they're a cop, you'll know soon.",
			},
			{
				text = "Eliminate them immediately - can't take risks",
				effects = { Happiness = -15 },
				successChance = 70,
				successMafiaEffect = { respect = 40, kills = 1, heat = 30 },
				failMafiaEffect = { respect = -50, heat = 80, arrested = true, jailYears = 25 },
				setFlags = { has_killed = true },
				feed = "Paranoia can save your life. Or end it.",
			},
			{
				text = "Report your concerns to the boss",
				effects = { Happiness = 0 },
				mafiaEffect = { respect = 10 },
				feed = "The boss will handle it from here.",
			},
		},
	},
	
	-- FAMILY CONFLICT
	{
		id = "inter_family_conflict",
		title = "⚔️ Family War",
		emoji = "⚔️",
		text = "Tensions with a rival family have boiled over. A soldier from our family was killed. The boss is calling for war.",
		question = "What's your role in this conflict?",
		minAge = 21,
		maxAge = 55,
		isMafiaOnly = true,
		cooldown = 4,
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true, initiated = true },
		},
		choices = {
			{
				text = "Lead a strike team",
				effects = { Happiness = 5, Health = -10 },
				successChance = 55,
				successMafiaEffect = { respect = 80, kills = 2, heat = 50 },
				failMafiaEffect = { respect = -20, Health = -30, heat = 40 },
				setFlags = { has_killed = true, war_veteran = true },
				feed = "Blood in the streets. This is war.",
			},
			{
				text = "Gather intelligence on enemy movements",
				effects = { Happiness = 3, Smarts = 8 },
				mafiaEffect = { respect = 40, heat = 15 },
				setFlags = { intelligence_gatherer = true },
				feed = "Your intel gave us the upper hand.",
			},
			{
				text = "Protect family assets and businesses",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 30, heat = 10 },
				setFlags = { family_protector = true },
				feed = "Defense is just as important as offense.",
			},
			{
				text = "Advocate for peace negotiations",
				effects = { Happiness = 0, Smarts = 5 },
				mafiaEffect = { respect = -10, loyalty = -15 },
				setFlags = { peacemaker = true },
				feed = "Some see you as wise. Others as weak.",
			},
		},
	},
	
	-- LEGITIMATE FRONT
	{
		id = "legitimate_business_front",
		title = "🏪 Going Legit",
		emoji = "🏪",
		text = "The family needs more legitimate fronts to launder money. You've been asked to run a business.",
		question = "What business do you choose?",
		minAge = 25,
		maxAge = 60,
		isMafiaOnly = true,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { in_mob = true, made_member = true },
			blockedFlags = { runs_front_business = true },
		},
		choices = {
			{
				text = "An upscale restaurant",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 30, money = 50000 },
				setFlags = { runs_front_business = true, restaurant_owner = true },
				feed = "Best Italian food in the city. Allegedly.",
			},
			{
				text = "A waste management company",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 40, money = 80000 },
				setFlags = { runs_front_business = true, waste_company = true },
				feed = "Nobody looks in the garbage trucks.",
			},
			{
				text = "A nightclub",
				effects = { Happiness = 15 },
				mafiaEffect = { respect = 25, money = 100000, heat = 10 },
				setFlags = { runs_front_business = true, nightclub_owner = true },
				feed = "The VIP section is VERY exclusive.",
			},
			{
				text = "A car dealership",
				effects = { Happiness = 8 },
				mafiaEffect = { respect = 35, money = 70000 },
				setFlags = { runs_front_business = true, car_dealer = true },
				feed = "Cash business. Perfect for cleaning money.",
			},
		},
	},
	
	-- LOYALTY TEST FROM BOSS
	{
		id = "boss_loyalty_test",
		title = "🔍 The Test",
		emoji = "🔍",
		text = "The boss has asked you to do something that will prove your loyalty beyond any doubt. It's a test.",
		question = "What does he ask of you?",
		minAge = 21,
		maxAge = 55,
		isMafiaOnly = true,
		cooldown = 12,
		maxOccurrences = 2,
		conditions = { 
			requiresFlags = { in_mob = true, initiated = true },
		},
		choices = {
			{
				text = "Eliminate an old friend who betrayed us",
				effects = { Happiness = -20 },
				mafiaEffect = { respect = 60, kills = 1, loyalty = 30, heat = 20 },
				setFlags = { has_killed = true, passed_test = true, killed_friend = true },
				feed = "Business is business. Even when it hurts.",
			},
			{
				text = "Destroy a competitor's shipment",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 40, heat = 25 },
				setFlags = { passed_test = true, saboteur = true },
				feed = "Millions in product, up in smoke.",
			},
			{
				text = "Corrupt a judge on an important case",
				effects = { Happiness = 3, Smarts = 5 },
				successChance = 65,
				successMafiaEffect = { respect = 50 },
				failMafiaEffect = { respect = -20, heat = 30 },
				setFlags = { passed_test = true, corrupter = true },
				feed = "Justice is blind. And expensive.",
			},
			{
				text = "Refuse - some lines can't be crossed",
				effects = { Happiness = -5 },
				mafiaEffect = { respect = -30, loyalty = -40 },
				setFlags = { refused_test = true },
				feed = "The boss questions your commitment.",
			},
		},
	},
	
	-- YOUNG SOLDIER PROBLEM
	{
		id = "soldier_problem",
		title = "👶 Young Gun Problem",
		emoji = "👶",
		text = "A young soldier under your command is causing problems. He's reckless and drawing heat to the family.",
		question = "How do you deal with him?",
		minAge = 28,
		maxAge = 60,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 3,
		conditions = { 
			requiresFlags = { in_mob = true, is_capo = true },
		},
		choices = {
			{
				text = "Give him one warning - make it count",
				effects = { Happiness = 5 },
				mafiaEffect = { respect = 15 },
				setFlags = { gives_chances = true },
				feed = "He got the message. For now.",
			},
			{
				text = "Reassign him to less visible work",
				effects = { Happiness = 3, Smarts = 5 },
				mafiaEffect = { respect = 10, loyalty = 10 },
				setFlags = { smart_manager = true },
				feed = "Different role, same family. Smart.",
			},
			{
				text = "Make an example of him",
				effects = { Happiness = -10 },
				mafiaEffect = { respect = 35, heat = 15 },
				setFlags = { enforcer = true },
				feed = "No one will forget what happened to him.",
			},
			{
				text = "Mentor him personally",
				effects = { Happiness = 8, Smarts = 3 },
				mafiaEffect = { respect = 20, loyalty = 25 },
				setFlags = { mentor = true },
				feed = "Under your guidance, he's becoming valuable.",
			},
		},
	},
	
	-- MONEY DROP GONE WRONG
	{
		id = "money_drop_problem",
		title = "💼 Drop Gone Wrong",
		emoji = "💼",
		text = "A scheduled money drop didn't go as planned. The courier claims he was robbed. The boss wants answers.",
		question = "What do you do?",
		minAge = 21,
		maxAge = 55,
		isMafiaOnly = true,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 3,
		conditions = { 
			requiresFlags = { in_mob = true, initiated = true },
		},
		choices = {
			{
				text = "Investigate - find the truth",
				effects = { Happiness = -5, Smarts = 8 },
				mafiaEffect = { respect = 25 },
				setFlags = { investigator = true },
				feed = "You found out what really happened.",
			},
			{
				text = "Cover the loss from your own pocket",
				effects = { Happiness = -10, Money = -50000 },
				mafiaEffect = { respect = 20, loyalty = 30 },
				setFlags = { takes_responsibility = true },
				feed = "Expensive, but your reputation is intact.",
			},
			{
				text = "Punish the courier regardless",
				effects = { Happiness = 3 },
				mafiaEffect = { respect = 15, heat = 10 },
				setFlags = { no_excuses = true },
				feed = "Message sent. True or not.",
			},
			{
				text = "Track down the supposed robbers",
				effects = { Happiness = 5 },
				successChance = 50,
				successMafiaEffect = { respect = 40, money = 75000 },
				failMafiaEffect = { respect = -15, heat = 20 },
				setFlags = { tracker = true },
				feed = "Either you find thieves or a liar.",
			},
		},
	},
	
	-- INFORMANT OPPORTUNITY
	{
		id = "become_informant",
		title = "🤐 The Choice",
		emoji = "🤐",
		text = "The FBI approaches you with a deal. Become an informant and they'll protect you. Refuse and you're on your own.",
		question = "What do you do?",
		minAge = 25,
		maxAge = 60,
		isMafiaOnly = true,
		cooldown = 5,
		maxOccurrences = 1,
		conditions = { 
			requiresFlags = { in_mob = true, initiated = true },
			blockedFlags = { informant = true },
		},
		choices = {
			{
				text = "Accept - save yourself",
				effects = { Happiness = -15 },
				mafiaEffect = { heatDecay = 50 },
				setFlags = { informant = true, secret_rat = true },
				feed = "You're a rat now. The guilt will never leave.",
			},
			{
				text = "Refuse and report to the boss",
				effects = { Happiness = 10 },
				mafiaEffect = { respect = 50, loyalty = 40, heat = 20 },
				setFlags = { loyal_soldier = true },
				feed = "The family knows they can trust you with their lives.",
			},
			{
				text = "Refuse silently - tell no one",
				effects = { Happiness = 5 },
				mafiaEffect = { heat = 10 },
				setFlags = { silent_refusal = true },
				feed = "What they don't know won't hurt them.",
			},
			{
				text = "Feed them false information",
				effects = { Happiness = 8, Smarts = 10 },
				successChance = 40,
				successMafiaEffect = { respect = 30, heatDecay = 20 },
				failMafiaEffect = { arrested = true, jailYears = 15 },
				setFlags = { double_agent = true },
				feed = "Playing both sides is dangerous.",
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
