--[[
	PremiumIntegratedEvents.lua
	
	Events that tastefully integrate premium gamepasses as optional choices.
	All players can play these events - premium options enhance the experience
	but are NOT required. These are NOT forced purchases or spammy popups.
	
	GAMEPASS INTEGRATIONS:
	- God Mode (⚡): Edit stats, fix problems instantly
	- Mafia (🔫): Criminal organization options  
	- Celebrity (⭐): Fame and entertainment options
	- Royalty (👑): Royal lifestyle options
	
	All events work for everyone - premium choices are just bonuses!
]]

local PremiumIntegratedEvents = {}

local STAGE = "random"

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

local function safeAddFeed(state, message)
	if state and state.AddFeed then
		state:AddFeed(message)
	end
end

local function safeAddMoney(state, amount)
	if state then
		state.Money = math.max(0, (state.Money or 0) + amount)
	end
end

local function safeSubtractMoney(state, amount)
	if state then
		state.Money = math.max(0, (state.Money or 0) - amount)
	end
end

-- CRITICAL FIX: Check if player can do activities (not in prison)
local function canDoActivities(state)
	if not state then return false end
	local flags = state.Flags or {}
	return not (flags.in_prison or flags.incarcerated or flags.in_jail)
end

-- CRITICAL FIX: Check if player has required money for choices
local function hasMinMoney(state, amount)
	return (state.Money or 0) >= amount
end

-- CRITICAL FIX: Initialize MobState safely
local function ensureMobState(state)
	if not state then return end
	state.MobState = state.MobState or {}
	state.MobState.heat = state.MobState.heat or 0
	state.MobState.respect = state.MobState.respect or 0
end

-- CRITICAL FIX: Initialize Flags safely
local function ensureFlags(state)
	if not state then return end
	state.Flags = state.Flags or {}
end

PremiumIntegratedEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- LIFE CRISIS EVENTS - God Mode Integration
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_health_crisis",
		title = "Health Scare",
		emoji = "🏥",
		text = "You've been diagnosed with a concerning health condition. The doctor says it's treatable but will require lifestyle changes.",
		question = "How do you handle this news?",
		minAge = 25, maxAge = 70,
		baseChance = 0.455,
		cooldown = 3,
		oneTime = false,
		maxOccurrences = 3,
		stage = STAGE,
		category = "health",
		tags = { "health", "medical", "life_change" },
		
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Follow treatment plan ($500)",
				effects = { Health = 15, Happiness = 5, Money = -500 },
				setFlags = { health_conscious = true },
				feedText = "You committed to the treatment. Slow but steady recovery!",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for treatment" end,
			},
			{
				text = "Try alternative medicine",
				effects = {},
				feedText = "Going the natural route...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Health", 10)
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🏥 Alternative treatment worked! Feeling better!")
					elseif roll < 0.70 then
						state:ModifyStat("Health", 3)
						state:AddFeed("🏥 Some improvement but not a miracle cure.")
					else
						state:ModifyStat("Health", -10)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🏥 Should've stuck with real medicine. Condition worsened.")
					end
				end,
			},
			{
				text = "Ignore it and hope for the best",
				effects = { Health = -15, Happiness = -5 },
				feedText = "Denial isn't a treatment plan. Things got worse.",
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Fix it instantly",
				effects = { Health = 30, Happiness = 10 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode activated! Health fully restored!",
				setFlags = { god_mode_healed = true },
			},
		},
	},
	{
		id = "premium_financial_crisis",
		title = "Financial Emergency",
		emoji = "💸",
		text = "You're facing a serious financial crisis. Bills are piling up and you're not sure how to make ends meet.",
		question = "How do you handle the money troubles?",
		minAge = 20, maxAge = 70,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		category = "finance",
		tags = { "money", "crisis", "debt" },
		
		eligibility = function(state)
			local money = state.Money or 0
			return money < 5000, "Need low money for financial crisis"
		end,
		
		choices = {
			{
				text = "Get a second job",
				effects = { Money = 800, Health = -8, Happiness = -5 },
				setFlags = { overworked = true },
				feedText = "Working double shifts. Exhausting but the bills are paid.",
			},
		{
			text = "Ask family for help",
			effects = {},
			feedText = "Swallowing your pride...",
			-- CRITICAL FIX: Can't ask family for help if already living with them!
			eligibility = function(state)
				local flags = state.Flags or {}
				if flags.lives_with_parents or flags.living_with_family or flags.boomerang_kid then
					return false, "You already live with your family!"
				end
				return true
			end,
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.60 then
					local help = math.random(500, 2000)
					state.Money = (state.Money or 0) + help
					state:ModifyStat("Happiness", 5)
					state:AddFeed(string.format("💸 Family came through! Got $%d in help.", help))
				else
					state:ModifyStat("Happiness", -8)
					state:AddFeed("💸 Family couldn't help. You're on your own.")
				end
			end,
		},
			{
				text = "File for bankruptcy",
				effects = { Happiness = -15 },
				setFlags = { bankrupt = true, bad_credit = true },
				feedText = "Rock bottom. Starting fresh but credit is destroyed.",
				onResolve = function(state)
					state.Money = 0
				end,
			},
			-- 🔫 MAFIA PREMIUM OPTION
			{
				text = "🔫 [Mafia] Borrow from the family",
				effects = { Money = 5000, Happiness = 5 },
				requiresGamepass = "MAFIA",
				gamepassEmoji = "🔫",
				feedText = "🔫 The family helped you out. But remember... debts must be repaid.",
				setFlags = { owes_mob_money = true },
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.mob_debt = 5000
				end,
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Manifest wealth",
				effects = { Money = 10000, Happiness = 15 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode activated! Financial troubles solved instantly!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CAREER OPPORTUNITIES - Celebrity Integration
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_talent_discovered",
		title = "Talent Discovered!",
		emoji = "🌟",
		text = "Someone noticed you have a special talent! A talent scout approaches you with an interesting proposition.",
		question = "What do you do?",
		minAge = 16, maxAge = 35,
		baseChance = 0.4,
		cooldown = 4,
		oneTime = true,
		stage = STAGE,
		category = "career",
		tags = { "opportunity", "talent", "fame" },
		
		eligibility = function(state)
			local looks = (state.Stats and state.Stats.Looks) or state.Looks or 50
			return looks >= 50 or math.random() < 0.3
		end,
		
		choices = {
			{
				text = "Politely decline - not interested",
				effects = { Happiness = 2 },
				feedText = "Fame isn't for you. Back to normal life.",
			},
			{
				text = "Take their card - maybe later",
				effects = { Happiness = 5 },
				setFlags = { talent_scout_card = true },
				feedText = "Keeping your options open. You never know!",
			},
			{
				text = "Try out but fail",
				effects = {},
				feedText = "You gave it a shot...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🌟 Wait, they actually liked you! Minor local fame!")
						state.Fame = (state.Fame or 0) + 5
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🌟 Didn't make the cut. At least you tried!")
					end
				end,
			},
			-- ⭐ CELEBRITY PREMIUM OPTION
			{
				text = "⭐ [Celebrity] Start your fame career!",
				effects = { Happiness = 20, Fame = 25 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ You got noticed! Your talent is recognized! (+Fame boost)",
				setFlags = { fame_boost = true, talent_discovered = true },
			},
		},
	},
	{
		id = "premium_viral_moment",
		title = "Viral Moment!",
		emoji = "📱",
		text = "Something you did accidentally went viral online! Your phone is blowing up with notifications.",
		question = "How do you handle sudden internet fame?",
		minAge = 13, maxAge = 50,
		baseChance = 0.1,
		cooldown = 5,
		oneTime = true,
		stage = STAGE,
		category = "social_media",
		tags = { "viral", "fame", "internet" },
		
		choices = {
			{
				text = "Enjoy your 15 minutes of fame",
				effects = { Happiness = 10, Fame = 5 },
				feedText = "It was fun while it lasted! Back to obscurity.",
			},
			{
				text = "Delete everything - hate the attention",
				effects = { Happiness = -5, Fame = 0 },
				setFlags = { privacy_conscious = true },
				feedText = "Went dark. Too much unwanted attention.",
			},
			{
				text = "Try to monetize it",
				effects = {},
				feedText = "Attempting to capitalize on the moment...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state.Money = (state.Money or 0) + math.random(1000, 5000)
						state:ModifyStat("Happiness", 10)
						state.Fame = (state.Fame or 0) + 10
						state:AddFeed("📱 Made some money from brand deals! Nice!")
					elseif roll < 0.60 then
						state.Money = (state.Money or 0) + math.random(100, 500)
						state:ModifyStat("Happiness", 5)
						state:AddFeed("📱 Made a little cash. The algorithm moved on.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📱 Tried too hard to stay relevant. Cringe.")
					end
				end,
			},
			-- ⭐ CELEBRITY PREMIUM OPTION
			{
				text = "⭐ [Celebrity] Turn this into stardom!",
				effects = { Happiness = 15, Fame = 35, Money = 5000 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ Celebrity gamepass! Turned viral fame into a real career!",
				setFlags = { influencer_career = true, viral_star = true },
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- POWER & INFLUENCE - Royalty/Mafia Integration
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_power_opportunity",
		title = "An Interesting Offer",
		emoji = "🤝",
		text = "You've been approached by some influential people who see potential in you. They have an... opportunity.",
		question = "What kind of power interests you?",
		minAge = 21, maxAge = 45,
		baseChance = 0.08,
		cooldown = 20,
		oneTime = true,
		stage = STAGE,
		category = "career",
		tags = { "power", "opportunity", "influence" },
		
		choices = {
			{
				text = "Just looking for an honest job",
				effects = { Happiness = 5, Smarts = 2 },
				feedText = "You prefer to earn success the traditional way.",
			},
			{
				text = "Interested in politics",
				effects = { Happiness = 3, Smarts = 3 },
				setFlags = { politically_connected = true },
				feedText = "Made some political connections. Might be useful someday.",
			},
			{
				text = "Business networking sounds good",
				effects = { Happiness = 5, Money = 500 },
				setFlags = { business_networked = true },
				feedText = "Joined some exclusive business circles. Opportunities incoming!",
			},
			-- 🔫 MAFIA PREMIUM OPTION
			{
				text = "🔫 [Mafia] The 'other' kind of family",
				effects = { Happiness = 5, Money = 2000 },
				requiresGamepass = "MAFIA",
				gamepassEmoji = "🔫",
				feedText = "🔫 You've made some powerful connections. They owe you a favor. (+Money)",
				setFlags = { mob_connections = true, knows_family = true },
			},
			-- 👑 ROYALTY PREMIUM OPTION (if married into royalty)
			{
				text = "👑 [Royalty] Royal connections",
				effects = { Happiness = 10, Fame = 20, Money = 50000 },
				requiresGamepass = "ROYALTY",
				gamepassEmoji = "👑",
				feedText = "👑 Royal connections established! Aristocratic doors open to you.",
				setFlags = { royal_connections = true, aristocrat_ally = true },
			},
		},
	},
	{
		id = "premium_enemy_confrontation",
		title = "Confrontation",
		emoji = "😤",
		text = "Someone who has wronged you in the past has reappeared in your life. They're successful now and seem to have forgotten what they did.",
		question = "How do you handle seeing them?",
		minAge = 20, maxAge = 60,
		baseChance = 0.45,
		cooldown = 4,
		stage = STAGE,
		category = "social",
		tags = { "revenge", "confrontation", "past" },
		
		choices = {
			{
				text = "Take the high road - ignore them",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { forgiveness_practiced = true },
				feedText = "You're bigger than petty revenge. Peace of mind is priceless.",
			},
			{
				text = "Confront them publicly",
				effects = {},
				feedText = "Calling them out...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("😤 They apologized! Closure at last!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("😤 They denied everything. At least you spoke up.")
					else
						state:ModifyStat("Happiness", -10)
						state:AddFeed("😤 Made a scene. Others think YOU'RE the problem now.")
					end
				end,
			},
			{
				text = "Plot quiet revenge through success",
				effects = { Smarts = 2, Happiness = 3 },
				setFlags = { revenge_motivated = true },
				feedText = "Living well is the best revenge. Working harder now.",
			},
			-- 🔫 MAFIA PREMIUM OPTION
			{
				text = "🔫 [Mafia] Have the family 'handle' it",
				effects = { Happiness = 15 },
				requiresGamepass = "MAFIA",
				gamepassEmoji = "🔫",
				requiresFlags = { in_mob = true },
				feedText = "🔫 The family made sure they won't bother you again.",
				setFlags = { used_mob_connections = true },
				onResolve = function(state)
					state.MobState = state.MobState or {}
					state.MobState.heat = (state.MobState.heat or 0) + 10
				end,
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Make them fail spectacularly",
				effects = { Happiness = 20 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode! Their business mysteriously failed. Karma!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- RELATIONSHIP EVENTS - Multiple Gamepass Integration
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_dream_wedding",
		title = "Wedding Planning",
		emoji = "💒",
		text = "You're engaged and planning your wedding! What kind of celebration do you want?",
		question = "How do you want your wedding?",
		minAge = 18, maxAge = 70,
		baseChance = 1.0,
		cooldown = 40,
		oneTime = true,
		stage = STAGE,
		category = "relationships",
		tags = { "wedding", "marriage", "celebration" },
		
		eligibility = function(state)
			local flags = state.Flags or {}
			if not (flags.engaged or flags.getting_married) then
				return false, "Not engaged"
			end
			-- CRITICAL FIX: Verify partner exists before wedding!
			local hasPartner = false
			if state.Relationships then
				for _, rel in pairs(state.Relationships) do
					if type(rel) == "table" and (rel.type == "romantic" or rel.type == "partner" or rel.type == "spouse" or rel.type == "fiance") then
						hasPartner = true
						break
					end
				end
			end
			if not hasPartner and not flags.has_partner then
				return false, "No partner to marry"
			end
			return true
		end,
		
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Simple courthouse wedding ($200)",
				effects = { Happiness = 8, Money = -200 },
				setFlags = { married = true, has_partner = true, engaged = false },
				feedText = "Simple but meaningful. You're married!",
				eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for wedding" end,
				-- CRITICAL FIX: Ensure spouse relationship exists
				onResolve = function(state)
					-- Convert partner to spouse
					if state.Relationships and state.Relationships.partner then
						state.Relationships.spouse = state.Relationships.partner
						state.Relationships.spouse.type = "spouse"
						state.Relationships.partner = nil
					elseif state.Relationships then
						-- Find any romantic relationship and convert to spouse
						for key, rel in pairs(state.Relationships) do
							if type(rel) == "table" and (rel.type == "romantic" or rel.type == "partner" or rel.type == "fiance") then
								rel.type = "spouse"
								state.Relationships.spouse = rel
								if key ~= "spouse" then state.Relationships[key] = nil end
								break
							end
						end
					end
					-- Clear engagement flags
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
					state.Flags.getting_married = nil
				end,
			},
			{
				text = "Traditional ceremony ($5,000)",
				effects = { Happiness = 12, Money = -5000 },
				setFlags = { married = true, has_partner = true, traditional_wedding = true, engaged = false },
				feedText = "Beautiful ceremony with family and friends!",
				-- CRITICAL FIX: Add eligibility check for affordability
				eligibility = function(state)
					if (state.Money or 0) < 5000 then
						return false, "Can't afford $5,000 ceremony"
					end
					return true
				end,
				-- CRITICAL FIX: Ensure spouse relationship exists
				onResolve = function(state)
					-- Convert partner to spouse
					if state.Relationships and state.Relationships.partner then
						state.Relationships.spouse = state.Relationships.partner
						state.Relationships.spouse.type = "spouse"
						state.Relationships.partner = nil
					elseif state.Relationships then
						for key, rel in pairs(state.Relationships) do
							if type(rel) == "table" and (rel.type == "romantic" or rel.type == "partner" or rel.type == "fiance") then
								rel.type = "spouse"
								state.Relationships.spouse = rel
								if key ~= "spouse" then state.Relationships[key] = nil end
								break
							end
						end
					end
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
					state.Flags.getting_married = nil
				end,
			},
			{
				text = "Big expensive wedding ($10,000)",
				effects = { Money = -10000, Happiness = 18 },
				setFlags = { married = true, has_partner = true, engaged = false, lavish_wedding = true },
				eligibility = function(state) return (state.Money or 0) >= 10000, "💸 Need $10,000 for big wedding" end,
				feedText = "💒 SPECTACULAR wedding! Everyone will remember it!",
				onResolve = function(state)
					if state.Relationships and state.Relationships.partner then
						state.Relationships.spouse = state.Relationships.partner
						state.Relationships.spouse.type = "spouse"
						state.Relationships.partner = nil
					elseif state.Relationships then
						for key, rel in pairs(state.Relationships) do
							if type(rel) == "table" and (rel.type == "romantic" or rel.type == "partner" or rel.type == "fiance") then
								rel.type = "spouse"
								state.Relationships.spouse = rel
								if key ~= "spouse" then state.Relationships[key] = nil end
								break
							end
						end
					end
					state.Flags.engaged = nil
					state.Flags.getting_married = nil
				end,
			},
			-- 👑 ROYALTY PREMIUM OPTION
			{
				text = "👑 [Royalty] Royal wedding extravaganza",
				effects = { Happiness = 25, Fame = 30 },
				requiresGamepass = "ROYALTY",
				gamepassEmoji = "👑",
				feedText = "👑 A ROYAL-STYLE WEDDING! Fit for a king!",
				setFlags = { married = true, has_partner = true, royal_wedding = true, engaged = false },
				-- CRITICAL FIX: Convert partner to spouse
				onResolve = function(state)
					if state.Relationships and state.Relationships.partner then
						state.Relationships.spouse = state.Relationships.partner
						state.Relationships.spouse.type = "spouse"
						state.Relationships.partner = nil
					elseif state.Relationships then
						for key, rel in pairs(state.Relationships) do
							if type(rel) == "table" and (rel.type == "romantic" or rel.type == "partner" or rel.type == "fiance") then
								rel.type = "spouse"
								state.Relationships.spouse = rel
								if key ~= "spouse" then state.Relationships[key] = nil end
								break
							end
						end
					end
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
					state.Flags.getting_married = nil
				end,
			},
			-- ⭐ CELEBRITY PREMIUM OPTION
			{
				text = "⭐ [Celebrity] Televised celebrity wedding!",
				effects = { Happiness = 20, Fame = 25, Money = 50000 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ Your wedding was on TV! Sponsors paid for everything!",
				setFlags = { married = true, has_partner = true, celebrity_wedding = true, engaged = false },
				-- CRITICAL FIX: Convert partner to spouse
				onResolve = function(state)
					if state.Relationships and state.Relationships.partner then
						state.Relationships.spouse = state.Relationships.partner
						state.Relationships.spouse.type = "spouse"
						state.Relationships.partner = nil
					elseif state.Relationships then
						for key, rel in pairs(state.Relationships) do
							if type(rel) == "table" and (rel.type == "romantic" or rel.type == "partner" or rel.type == "fiance") then
								rel.type = "spouse"
								state.Relationships.spouse = rel
								if key ~= "spouse" then state.Relationships[key] = nil end
								break
							end
						end
					end
					state.Flags = state.Flags or {}
					state.Flags.engaged = nil
					state.Flags.getting_married = nil
				end,
			},
		},
	},
	{
		id = "premium_family_feud",
		title = "Family Drama",
		emoji = "👨‍👩‍👧‍👦",
		text = "There's major drama in your family. Two relatives are fighting and everyone is being forced to take sides.",
		question = "How do you handle the family feud?",
		minAge = 16, maxAge = 80,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		category = "family",
		tags = { "family", "drama", "conflict" },
		
		choices = {
			{
				text = "Try to mediate",
				effects = {},
				feedText = "Attempting to be the peacemaker...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random() + (smarts / 200)
					if roll > 0.6 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("👨‍👩‍👧‍👦 You helped them make up! Family healer!")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("👨‍👩‍👧‍👦 Made it worse somehow. Both sides mad at you now.")
					end
				end,
			},
			{
				text = "Pick a side",
				effects = { Happiness = -5 },
				feedText = "You chose. Half the family isn't speaking to you now.",
			},
			{
				text = "Stay completely out of it",
				effects = { Happiness = 2 },
				feedText = "Not your circus, not your monkeys. Wise choice.",
			},
			-- 👑 ROYALTY PREMIUM OPTION
			{
				text = "👑 [Royalty] Issue a royal decree",
				effects = { Happiness = 15 },
				requiresGamepass = "ROYALTY",
				requiresFlags = { is_royalty = true },
				gamepassEmoji = "👑",
				feedText = "👑 As royalty, you commanded peace. They had to comply.",
				setFlags = { royal_authority_used = true },
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Make everyone get along",
				effects = { Happiness = 20 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode! Everyone suddenly forgave each other. Magic!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- LIFE DECISION EVENTS - Major Choices
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_life_crossroads",
		title = "Life Crossroads",
		emoji = "🔀",
		text = "You're at a major crossroads in life. Everything could change based on your next move.",
		question = "Which path do you choose?",
		minAge = 25, maxAge = 50,
		baseChance = 0.25, -- CRITICAL FIX: Reduced from 0.4 to prevent spam
		cooldown = 15, -- CRITICAL FIX: Increased from 5 to prevent spam
		oneTime = true,
		maxOccurrences = 1, -- CRITICAL FIX: Ensure only once per life
		stage = STAGE,
		category = "milestone",
		tags = { "decision", "life_change", "important" },
		
		-- CRITICAL FIX: Block if already shown premium opportunities or chose a path
		blockedByFlags = { premium_opportunity_shown = true, is_royalty = true, in_mob = true, is_famous = true },
		
		choices = {
			{
				text = "Play it safe - stability",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { chose_stability = true },
				feedText = "Safe choice. Comfort and security.",
			},
			{
				text = "Take a risk - adventure",
				effects = {},
				feedText = "Rolling the dice on life...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state.Money = (state.Money or 0) + math.random(10000, 50000)
						state:ModifyStat("Happiness", 20)
						state:AddFeed("🔀 THE RISK PAID OFF! Life changed for the better!")
						state.Flags = state.Flags or {}
						state.Flags.risk_taker_success = true
					elseif roll < 0.65 then
					state:ModifyStat("Happiness", 5)
					state:AddFeed("🔀 It worked out okay. Not amazing but no regrets.")
				else
					-- CRITICAL FIX: Prevent negative money
					state.Money = math.max(0, (state.Money or 0) - math.random(1000, 5000))
					state:ModifyStat("Happiness", -10)
					state:AddFeed("🔀 The risk didn't pay off. Lesson learned the hard way.")
					end
				end,
			},
			{
				-- CRITICAL FIX: Following passion is about lower income going forward, NOT an upfront cost!
				-- This represents taking a career that pays less but makes you happier
				text = "Follow your passion (lower income)",
				effects = { Happiness = 15 },
				setFlags = { passion_follower = true, chose_passion_over_money = true },
				feedText = "Money isn't everything. Doing what you love! Less pay but more purpose.",
				-- No eligibility - anyone can choose passion over money
			},
			-- 🔫 MAFIA PREMIUM OPTION
			{
				text = "🔫 [Mafia] Take the underground path",
				effects = { Money = 15000, Happiness = 5 },
				requiresGamepass = "MAFIA",
				gamepassEmoji = "🔫",
				feedText = "🔫 You took the underground deal. Easy money! (+$15,000)",
				setFlags = { took_shady_deal = true, crime_connections = true },
			},
			-- ⭐ CELEBRITY PREMIUM OPTION
			{
				text = "⭐ [Celebrity] Chase fame and fortune!",
				effects = { Fame = 20, Happiness = 15 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ You're going to be a STAR! Fame awaits!",
				setFlags = { fame_career = true, chose_fame_life = true },
			},
		-- 👑 ROYALTY PREMIUM OPTION
		-- CRITICAL FIX: This choice should only be available to players who ARE ALREADY royalty
		-- Buying the gamepass does NOT make you royalty - you must be born royal or marry into it
		{
			text = "👑 [Royalty] Embrace your royal duties",
			effects = { Fame = 15, Happiness = 10 },
			requiresGamepass = "ROYALTY",
			requiresFlags = { is_royalty = true }, -- CRITICAL: Must already BE royalty!
			gamepassEmoji = "👑",
			feedText = "👑 You've embraced your royal responsibilities!",
			setFlags = { royal_duties = true, embraced_royalty = true },
			onResolve = function(state)
				-- Only update royal state, don't CREATE it
				if state.RoyalState and state.RoyalState.isRoyal then
					state.RoyalState.dutiesCompleted = (state.RoyalState.dutiesCompleted or 0) + 1
				end
			end,
		},
		},
	},
	{
		id = "premium_mysterious_inheritance",
		title = "Mysterious Inheritance",
		emoji = "📜",
		text = "You've received a mysterious letter about an inheritance from a distant relative you never knew existed. There's a catch - you must choose how to claim it.",
		question = "What do you do?",
		minAge = 25, maxAge = 70,
		baseChance = 0.1,
		cooldown = 40,
		oneTime = true,
		stage = STAGE,
		category = "inheritance",
		tags = { "money", "mystery", "family" },
		
		choices = {
			{
				text = "Accept whatever it is",
				effects = {},
				feedText = "Opening the mystery box...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						local amount = math.random(50000, 200000)
						state.Money = (state.Money or 0) + amount
						state:ModifyStat("Happiness", 20)
						state:AddFeed(string.format("📜 JACKPOT! Inherited $%d! Life changing!", amount))
					elseif roll < 0.55 then
						local amount = math.random(5000, 25000)
						state.Money = (state.Money or 0) + amount
						state:ModifyStat("Happiness", 10)
						state:AddFeed(string.format("📜 Nice! Inherited $%d!", amount))
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📜 Inherited some family heirlooms. Sentimental value.")
						state.Flags = state.Flags or {}
						state.Flags.has_heirloom = true
					else
						state.Money = math.max(0, (state.Money or 0) - math.random(5000, 15000))
						state:ModifyStat("Happiness", -10)
						state:AddFeed("📜 Inherited... their debts. Great. Thanks, dead relative.")
					end
				end,
			},
			{
				text = "Investigate first",
				effects = { Smarts = 3 },
				feedText = "You hired a lawyer to investigate. Smart move.",
				onResolve = function(state)
					-- Safer outcome since you investigated
					local roll = math.random()
					if roll < 0.40 then
						local amount = math.random(20000, 80000)
						state.Money = (state.Money or 0) + amount - 2000 -- lawyer fees
						state:ModifyStat("Happiness", 12)
						state:AddFeed(string.format("📜 After lawyer fees, inherited $%d!", amount - 2000))
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("📜 Lawyer found issues. Avoided a scam. Worth the fee.")
					end
				end,
			},
			{
				text = "Reject it - sounds like a scam",
				effects = { Happiness = 2 },
				feedText = "Better safe than sorry. You declined.",
			},
			-- 👑 ROYALTY PREMIUM OPTION
			{
				text = "👑 [Royalty] Claim your royal lineage",
				effects = { Fame = 40, Money = 500000, Happiness = 25 },
				requiresGamepass = "ROYALTY",
				gamepassEmoji = "👑",
				feedText = "👑 The inheritance revealed royal ancestry in your bloodline! (+Fame, +Money)",
				setFlags = { discovered_royal_heritage = true, has_royal_blood = true },
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- DANGER & CONFLICT EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_mugged",
		title = "Robbery!",
		emoji = "🔪",
		text = "You're being robbed! Someone with a weapon demands your valuables.",
		question = "How do you respond?",
		minAge = 16, maxAge = 70,
		baseChance = 0.4,
		cooldown = 4,
		stage = STAGE,
		category = "crime",
		tags = { "danger", "crime", "robbery" },
		-- CRITICAL FIX: Can't be mugged on the street while in prison!
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		choices = {
			{
				text = "Hand over everything",
				effects = { Happiness = -10, Health = 5 },
				feedText = "You gave them what they wanted. Alive is what matters.",
				onResolve = function(state)
					-- CRITICAL FIX: Ensure values are numbers for math.min
					local currentMoney = tonumber(state.Money) or 0
					local loss = math.min(currentMoney, math.random(100, 500))
					state.Money = currentMoney - loss
					state:AddFeed(string.format("🔪 Lost $%d but you're safe.", loss))
				end,
			},
			{
				text = "Try to run away",
				effects = {},
				feedText = "Running for your life...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random() + (health / 200)
					if roll > 0.5 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", -5)
						state:AddFeed("🔪 Escaped! Heart pounding but safe!")
					else
						-- CRITICAL FIX: Ensure values are numbers for math.min
						local currentMoney = tonumber(state.Money) or 0
						local loss = math.min(currentMoney, math.random(200, 800))
						state.Money = currentMoney - loss
						state:ModifyStat("Health", -20)
						state:ModifyStat("Happiness", -15)
						state:AddFeed(string.format("🔪 Caught and beaten. Lost $%d and your pride.", loss))
					end
				end,
			},
			{
				text = "Fight back",
				effects = {},
				feedText = "Standing your ground...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Health", -10)
						state:AddFeed("🔪 You WON! Beat them off! Feeling invincible!")
						state.Flags = state.Flags or {}
						state.Flags.fought_off_robber = true
					elseif roll < 0.50 then
						state:ModifyStat("Health", -25)
						state:AddFeed("🔪 Survived but badly hurt. Was it worth it?")
					else
						-- CRITICAL FIX: Ensure values are numbers for math.min
						local currentMoney = tonumber(state.Money) or 0
						local loss = math.min(currentMoney, math.random(300, 1000))
						state.Money = currentMoney - loss
						state:ModifyStat("Health", -40)
						state:ModifyStat("Happiness", -20)
						state:AddFeed(string.format("🔪 Beaten badly. Lost $%d. Hospital bound.", loss))
						state.Flags = state.Flags or {}
						state.Flags.hospitalized = true
					end
				end,
			},
			-- 🔫 MAFIA PREMIUM OPTION
			{
				text = "🔫 [Mafia] Show them who they messed with",
				effects = { Happiness = 20 },
				requiresGamepass = "MAFIA",
				requiresFlags = { in_mob = true },
				gamepassEmoji = "🔫",
				feedText = "🔫 They saw your family tattoo and ran. Nobody robs the family.",
				onResolve = function(state)
					state.MobState = state.MobState or {}
					state.MobState.respect = (state.MobState.respect or 0) + 5
				end,
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Freeze time and walk away",
				effects = { Happiness = 15, Health = 10 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode! Time froze. You casually walked away untouched.",
			},
		},
	},
	{
		id = "premium_court_case",
		title = "Day in Court",
		emoji = "⚖️",
		text = "You're involved in a legal case. The outcome could significantly impact your life.",
		question = "How do you approach the case?",
		minAge = 18, maxAge = 80,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		category = "legal",
		tags = { "legal", "court", "law" },
		
		choices = {
			{
				text = "Hire an expensive lawyer ($5,000)",
				effects = { Money = -5000 },
				eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Need $5,000 for lawyer" end,
				feedText = "Getting professional representation...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 15)
						state:AddFeed("⚖️ WON the case! Expensive lawyer was worth it!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("⚖️ Lost despite the expensive lawyer. System is broken.")
					end
				end,
			},
			{
				text = "Use public defender",
				effects = {},
				feedText = "Getting public defender...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("⚖️ Won with public defender! Lucky!")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("⚖️ Lost the case. Should've gotten a better lawyer.")
					end
				end,
			},
			{
				text = "Represent yourself",
				effects = {},
				feedText = "Being your own lawyer...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random() + (smarts / 200)
					if roll > 0.7 then
						state:ModifyStat("Happiness", 20)
						state:ModifyStat("Smarts", 5)
						state:AddFeed("⚖️ WON representing yourself! Impressive!")
					else
						state:ModifyStat("Happiness", -15)
						state.Money = math.max(0, (state.Money or 0) - math.random(2000, 10000))
						state:AddFeed("⚖️ Lost badly. Should've gotten a lawyer.")
					end
				end,
			},
			{
				text = "Settle out of court ($2,000)",
				effects = { Money = -2000, Happiness = 5 },
				feedText = "Reached a settlement. Not ideal but it's over.",
				-- CRITICAL FIX: Add eligibility check for affordability
				eligibility = function(state)
					if (state.Money or 0) < 2000 then
						return false, "Can't afford $2,000 settlement"
					end
					return true
				end,
			},
			-- 🔫 MAFIA PREMIUM OPTION
			{
				text = "🔫 [Mafia] Have witnesses 'persuaded'",
				effects = { Happiness = 10 },
				requiresGamepass = "MAFIA",
				requiresFlags = { in_mob = true },
				gamepassEmoji = "🔫",
				feedText = "🔫 Witnesses mysteriously changed their testimony. Case dismissed.",
				onResolve = function(state)
					state.MobState = state.MobState or {}
					state.MobState.heat = (state.MobState.heat or 0) + 15
				end,
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Judge rules in your favor",
				effects = { Happiness = 20, Money = 10000 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode! Judge inexplicably ruled completely in your favor!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SOCIAL STATUS EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_exclusive_party",
		title = "Exclusive Party Invite",
		emoji = "🎉",
		text = "You've been invited to an exclusive party with important people. This could be a networking goldmine.",
		question = "How do you approach the party?",
		minAge = 21, maxAge = 55,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		category = "social",
		tags = { "party", "networking", "social" },
		
		choices = {
			{
				text = "Network strategically",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { well_connected = true },
				feedText = "Made some valuable connections!",
			},
			{
				text = "Just enjoy the party",
				effects = { Happiness = 10, Health = -2 },
				feedText = "Had a great time! No regrets.",
			},
			{
				text = "Feel out of place and leave early",
				effects = { Happiness = -5 },
				feedText = "Not your scene. Left before dessert.",
			},
			-- ⭐ CELEBRITY PREMIUM OPTION
			{
				text = "⭐ [Celebrity] Become the star of the party!",
				effects = { Happiness = 15, Fame = 10 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ You were the TALK of the party! Everyone wants to know you now!",
				setFlags = { party_star = true, social_elite = true },
			},
			-- 👑 ROYALTY PREMIUM OPTION
			{
				text = "👑 [Royalty] Arrive fashionably late as royalty",
				effects = { Happiness = 20, Fame = 15 },
				requiresGamepass = "ROYALTY",
				requiresFlags = { is_royalty = true },
				gamepassEmoji = "👑",
				feedText = "👑 Your royal presence made it THE event of the season!",
			},
		},
	},
	{
		id = "premium_business_opportunity",
		title = "Business Opportunity",
		emoji = "💼",
		text = "Someone approaches you with a business opportunity. It sounds promising but risky.",
		question = "Do you invest?",
		minAge = 25, maxAge = 60,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		category = "finance",
		tags = { "business", "investment", "opportunity" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 1000 then
				return false, "💸 You need at least $1,000 to see this opportunity"
			end
			return true
		end,
		
		choices = {
			{
				text = "Invest small amount ($1,000)",
				effects = {},
				feedText = "Small investment, small risk...",
				-- CRITICAL FIX: Add eligibility check for affordability
				eligibility = function(state)
					if (state.Money or 0) < 1000 then
						return false, "Need at least $1,000 to invest"
					end
					return true
				end,
				onResolve = function(state)
					-- CRITICAL FIX: Prevent negative money
					state.Money = math.max(0, (state.Money or 0) - 1000)
					local roll = math.random()
					if roll < 0.35 then
						local profit = math.random(2000, 5000)
						state.Money = (state.Money or 0) + profit
						state:ModifyStat("Happiness", 10)
						state:AddFeed(string.format("💼 Investment paid off! Made $%d profit!", profit - 1000))
					elseif roll < 0.65 then
						state.Money = (state.Money or 0) + 1200
						state:ModifyStat("Happiness", 3)
						state:AddFeed("💼 Small profit. Better than nothing!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("💼 Lost the investment. Expensive lesson.")
					end
				end,
			},
			{
				text = "Go all in",
				effects = {},
				feedText = "High risk, high reward...",
				-- CRITICAL FIX: Add eligibility check - need some money to go all in
				eligibility = function(state)
					if (state.Money or 0) < 100 then
						return false, "Need some money to invest"
					end
					return true
				end,
				onResolve = function(state)
					local investment = math.floor((state.Money or 0) * 0.8)
					-- CRITICAL FIX: Prevent negative money
					state.Money = math.max(0, (state.Money or 0) - investment)
					local roll = math.random()
					if roll < 0.25 then
						local multiplier = math.random(3, 10)
						local profit = investment * multiplier
						state.Money = (state.Money or 0) + profit
						state:ModifyStat("Happiness", 25)
						state:AddFeed(string.format("💼 MASSIVE SUCCESS! Turned into $%d!", profit))
						state.Flags = state.Flags or {}
						state.Flags.successful_investor = true
					elseif roll < 0.45 then
						state.Money = (state.Money or 0) + investment * 2
						state:ModifyStat("Happiness", 12)
						state:AddFeed("💼 Doubled your money! Great bet!")
					else
						state:ModifyStat("Happiness", -20)
						state:AddFeed("💼 Lost almost everything. Devastating.")
					end
				end,
			},
			{
				text = "Decline politely",
				effects = { Happiness = 2 },
				feedText = "You passed. Maybe smart, maybe missed out.",
			},
			-- 🔫 MAFIA PREMIUM OPTION
			{
				text = "🔫 [Mafia] Make it a 'family' investment",
				effects = { Money = 10000, Happiness = 10 },
				requiresGamepass = "MAFIA",
				requiresFlags = { in_mob = true },
				gamepassEmoji = "🔫",
				feedText = "🔫 The family's 'investment' always pays off. No questions asked.",
				onResolve = function(state)
					state.MobState = state.MobState or {}
					state.MobState.heat = (state.MobState.heat or 0) + 10
				end,
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Guarantee it succeeds",
				effects = { Money = 50000, Happiness = 20 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode! Investment success was guaranteed!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- YOUNG PERSON EVENTS (Teen Focus)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_teen_future",
		title = "Thinking About the Future",
		emoji = "🎯",
		text = "You're thinking about what you want to do with your life. Adults keep asking about your plans.",
		question = "What's your dream?",
		minAge = 15, maxAge = 18,
		baseChance = 0.4,
		cooldown = 3,
		stage = "teen",
		category = "teen",
		tags = { "future", "dreams", "career" },
		
		choices = {
			{
				text = "I want a stable, normal job",
				effects = { Smarts = 3, Happiness = 2 },
				setFlags = { practical_dreams = true },
				feedText = "Practical goals. Nothing wrong with that!",
			},
			{
				text = "I'm going to be rich",
				effects = { Happiness = 5 },
				setFlags = { ambitious_teen = true },
				feedText = "Big dreams! Hope you achieve them!",
			},
			{
				text = "I have no idea",
				effects = { Happiness = -2 },
				feedText = "Join the club. Most people don't know either.",
			},
			-- ⭐ CELEBRITY PREMIUM OPTION
			{
				text = "⭐ [Celebrity] I'm going to be FAMOUS!",
				effects = { Happiness = 10, Fame = 5 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ With Celebrity access, fame is within reach!",
				setFlags = { fame_dreams = true, future_star = true },
			},
			-- 👑 ROYALTY PREMIUM OPTION
			{
				text = "👑 [Royalty] I was born for greatness",
				effects = { Happiness = 8, Fame = 3 },
				requiresGamepass = "ROYALTY",
				gamepassEmoji = "👑",
				feedText = "👑 Perhaps royalty runs in your blood...",
				setFlags = { royal_aspirations = true },
			},
		},
	},
	{
		id = "premium_school_bully",
		title = "Bully Trouble",
		emoji = "😠",
		text = "Someone at school has been bullying you. Today they pushed you too far.",
		question = "How do you handle the bully?",
		minAge = 10, maxAge = 17,
		baseChance = 0.555,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = "teen",
		category = "teen",
		tags = { "bully", "school", "conflict" },
		
		choices = {
			{
				text = "Tell a teacher or parent",
				effects = { Happiness = 3, Smarts = 2 },
				feedText = "The adults handled it. Bully got in trouble.",
			},
			{
				text = "Stand up to them verbally",
				effects = {},
				feedText = "Confronting the bully...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random() + (smarts / 200)
					if roll > 0.5 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.stood_up_to_bully = true
						state:AddFeed("😠 They backed down! You feel POWERFUL!")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("😠 Made it worse. They're targeting you more now.")
					end
				end,
			},
			{
				text = "Get physical",
				effects = {},
				feedText = "Throwing punches...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random() + (health / 200)
					if roll > 0.6 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Health", -5)
						state.Flags = state.Flags or {}
						state.Flags.won_fight = true
						state:AddFeed("😠 You WON the fight! Respect earned!")
					else
						state:ModifyStat("Happiness", -10)
						state:ModifyStat("Health", -15)
						state:AddFeed("😠 Got beat up. Painful lesson.")
					end
				end,
			},
			{
				text = "Just avoid them",
				effects = { Happiness = -5 },
				feedText = "Taking alternate routes everywhere. Living in fear.",
			},
			-- 🔫 MAFIA PREMIUM OPTION
			{
				text = "🔫 [Mafia] Family connections help",
				effects = { Happiness = 15 },
				requiresGamepass = "MAFIA",
				gamepassEmoji = "🔫",
				feedText = "🔫 Your 'uncle' had a word with the bully's parents. Problem solved.",
				setFlags = { mob_protected = true },
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Make them leave you alone",
				effects = { Happiness = 15 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode! Bully suddenly decided to be nice. Weird!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- ADDITIONAL EXPANDED EVENTS - More Variety
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_lottery_jackpot",
		title = "Lottery Dreams",
		emoji = "🎰",
		text = "You bought a lottery ticket on a whim. The jackpot is huge this week!",
		question = "Check your numbers?",
		minAge = 18, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		category = "luck",
		tags = { "money", "luck", "gambling" },
		
		choices = {
			{
				text = "Check the numbers",
				effects = {},
				feedText = "Checking the winning numbers...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.01 then -- 1% jackpot
						local jackpot = math.random(100000, 1000000)
						state.Money = (state.Money or 0) + jackpot
						state:ModifyStat("Happiness", 50)
						state:AddFeed(string.format("🎰 JACKPOT!!! You won $%d!!! LIFE CHANGING!", jackpot))
						state.Flags = state.Flags or {}
						state.Flags.lottery_winner = true
					elseif roll < 0.10 then -- 9% small win
						local win = math.random(100, 1000)
						state.Money = (state.Money or 0) + win
						state:ModifyStat("Happiness", 10)
						state:AddFeed(string.format("🎰 Won $%d! Not bad!", win))
					else -- 90% nothing
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🎰 No luck this time. That's gambling!")
					end
				end,
			},
			{
				text = "Give the ticket away",
				effects = { Happiness = 2 },
				feedText = "You gave the ticket to someone else. Maybe they'll win!",
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Win the jackpot",
				effects = { Money = 500000, Happiness = 50 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode! You won $500,000! Numbers matched perfectly!",
				setFlags = { lottery_winner = true },
			},
		},
	},
	{
		id = "premium_job_interview",
		title = "Big Job Interview",
		emoji = "💼",
		text = "You have an interview for your dream job. This could change everything!",
		question = "How do you prepare?",
		minAge = 18, maxAge = 60,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased cooldown - don't spam job interviews
		maxOccurrences = 5, -- CRITICAL FIX: Limit total occurrences
		stage = STAGE,
		category = "career",
		tags = { "job", "interview", "career" },
		-- CRITICAL FIX: Job interview should only fire if player is unemployed
		-- or has been in a low-paying job for a while
		blockedByFlags = { in_prison = true, homeless = true },
		eligibility = function(state)
			local hasJob = state.CurrentJob ~= nil
			local flags = state.Flags or {}
			
			-- If unemployed, eligible (great use case!)
			if not hasJob then
				return true
			end
			
			-- If employed but at a low-paying/entry-level job for 2+ years, eligible
			local yearsAtJob = state.CurrentJob and state.CurrentJob.yearsAtJob or 0
			local salary = state.CurrentJob and state.CurrentJob.salary or 0
			
			-- Low-paying job AND been there a while = looking for upgrade
			if salary < 40000 and yearsAtJob >= 2 then
				return true
			end
			
			-- Stuck in same job for 5+ years = career change opportunity
			if yearsAtJob >= 5 then
				return true
			end
			
			-- Has "looking_for_job" flag
			if flags.looking_for_job or flags.job_hunting or flags.career_change then
				return true
			end
			
			-- Otherwise, don't show random job interviews to people with good jobs
			return false
		end,
		
		choices = {
			{
				text = "Prepare extensively",
				effects = {},
				feedText = "Research, practice, dress sharp...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random() + (smarts / 200)
					if roll > 0.5 then
						state:ModifyStat("Happiness", 15)
						state:AddFeed("💼 HIRED! You got the job! Hard work paid off!")
						state.Flags = state.Flags or {}
						state.Flags.recently_hired = true
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("💼 Didn't get it. They went with someone else.")
					end
				end,
			},
			{
				text = "Wing it",
				effects = {},
				feedText = "How hard can it be?",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state:ModifyStat("Happiness", 12)
						state:AddFeed("💼 Somehow got the job! Natural talent!")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("💼 Should've prepared. Complete disaster.")
					end
				end,
			},
			-- ⭐ CELEBRITY PREMIUM OPTION
			{
				text = "⭐ [Celebrity] Use your fame to get hired!",
				effects = { Happiness = 15 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ Your celebrity status impressed them! Hired on the spot!",
				setFlags = { recently_hired = true },
			},
			-- 🔫 MAFIA PREMIUM OPTION
			{
				text = "🔫 [Mafia] The family has connections",
				effects = { Happiness = 12 },
				requiresGamepass = "MAFIA",
				requiresFlags = { in_mob = true },
				gamepassEmoji = "🔫",
				feedText = "🔫 The family made some calls. You're hired.",
				setFlags = { recently_hired = true },
			},
		},
	},
	{
		id = "premium_health_checkup",
		title = "Annual Checkup",
		emoji = "🏥",
		text = "Time for your annual health checkup. The doctor has some news.",
		question = "What did they find?",
		minAge = 30, maxAge = 90,
		baseChance = 0.555,
		cooldown = 3,
		stage = STAGE,
		category = "health",
		tags = { "health", "doctor", "medical" },
		
		choices = {
			{
				text = "Get the results",
				effects = {},
				feedText = "The doctor reviews your results...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🏥 All clear! You're healthy!")
					elseif roll < 0.85 then
						state:ModifyStat("Health", -5)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🏥 Some concerns. Doctor recommends lifestyle changes.")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -15)
						state:AddFeed("🏥 Bad news. You need treatment.")
						state.Flags = state.Flags or {}
						state.Flags.needs_treatment = true
					end
				end,
			},
			{
				text = "Skip the checkup",
				effects = { Happiness = 2 },
				feedText = "You rescheduled. Ignorance is bliss... right?",
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Perfect health guaranteed",
				effects = { Health = 30, Happiness = 15 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode! Doctor says you're in perfect health! Peak condition!",
			},
		},
	},
	{
		id = "premium_inheritance_discovery",
		title = "Hidden Treasure",
		emoji = "🗝️",
		text = "While cleaning out your late relative's house, you find a hidden safe!",
		question = "What's inside?",
		minAge = 20, maxAge = 80,
		baseChance = 0.08,
		cooldown = 5,
		oneTime = true,
		stage = STAGE,
		category = "inheritance",
		tags = { "money", "discovery", "family" },
		
		choices = {
			{
				text = "Open the safe",
				effects = {},
				feedText = "The combination works...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						local cash = math.random(50000, 200000)
						state.Money = (state.Money or 0) + cash
						state:ModifyStat("Happiness", 30)
						state:AddFeed(string.format("🗝️ TREASURE! Found $%d in cash! Incredible!", cash))
					elseif roll < 0.50 then
						local cash = math.random(5000, 25000)
						state.Money = (state.Money or 0) + cash
						state:ModifyStat("Happiness", 15)
						state:AddFeed(string.format("🗝️ Nice! Found $%d and some jewelry!", cash))
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🗝️ Old family photos and letters. Priceless memories.")
						state.Flags = state.Flags or {}
						state.Flags.has_heirloom = true
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🗝️ Empty. Someone got here first.")
					end
				end,
			},
			{
				text = "Leave it sealed",
				effects = { Happiness = -2 },
				feedText = "Some mysteries are best left unsolved.",
			},
			-- 👑 ROYALTY PREMIUM OPTION
			{
				text = "👑 [Royalty] Royal heirlooms revealed",
				effects = { Money = 500000, Fame = 20, Happiness = 25 },
				requiresGamepass = "ROYALTY",
				gamepassEmoji = "👑",
				feedText = "👑 Royal artifacts! Worth a fortune and proves your noble lineage!",
				setFlags = { discovered_royal_heritage = true },
			},
		},
	},
	{
		id = "premium_friendship_test",
		title = "Friendship Tested",
		emoji = "🤝",
		text = "Your best friend needs a big favor. They're asking for $5,000 to help with an emergency.",
		question = "What do you do?",
		minAge = 18, maxAge = 70,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		category = "relationships",
		tags = { "friend", "money", "loyalty" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 1000 then
				return false, "💸 You don't have enough money to help"
			end
			return true
		end,
		
		choices = {
			{
				text = "Loan them $5,000",
				effects = { Money = -5000 },
				eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Need $5,000 to lend" end,
				feedText = "🤝 Helping a friend in need...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 15)
						state:AddFeed("🤝 They paid you back! True friend!")
						state.Money = (state.Money or 0) + 5000
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🤝 Never saw that money again. Lesson learned.")
					end
				end,
			},
			{
				text = "Give them $1,000",
				effects = { Money = -1000, Happiness = 3 },
				eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Need $1,000 to give" end,
				feedText = "🤝 You gave $1,000. They appreciated it.",
			},
			{
				text = "Say no",
				effects = { Happiness = -5 },
				feedText = "You can't help right now. They understood... sort of.",
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				-- CRITICAL FIX: Show price!
				text = "⚡ [God Mode] Give generously ($5,000)",
				effects = { Money = -5000, Happiness = 20 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode! Your generosity changed their life! They'll always remember.",
				setFlags = { generous_friend = true },
				eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Need $5,000 to give" end,
			},
		},
	},
	{
		id = "premium_public_speech",
		title = "Public Speaking",
		emoji = "🎤",
		text = "You've been asked to give a speech at a major event. Hundreds will be watching.",
		question = "How do you handle it?",
		minAge = 20, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		category = "social",
		tags = { "public", "speech", "confidence" },
		
		choices = {
			{
				text = "Practice and nail it",
				effects = {},
				feedText = "Standing at the podium...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random() + (smarts / 200)
					if roll > 0.5 then
						state:ModifyStat("Happiness", 15)
						state.Fame = (state.Fame or 0) + 5
						state:AddFeed("🎤 STANDING OVATION! You crushed it!")
						state.Flags = state.Flags or {}
						state.Flags.great_speaker = true
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🎤 Some stumbles but got through it. Not terrible.")
					end
				end,
			},
			{
				text = "Decline the invitation",
				effects = { Happiness = -3 },
				feedText = "Public speaking isn't for everyone.",
			},
			-- ⭐ CELEBRITY PREMIUM OPTION
			{
				text = "⭐ [Celebrity] Deliver a legendary speech!",
				effects = { Happiness = 20, Fame = 15 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ Your celebrity charisma made it unforgettable! Trending!",
				setFlags = { legendary_speaker = true, viral_speech = true },
			},
			-- 👑 ROYALTY PREMIUM OPTION
			{
				text = "👑 [Royalty] Deliver a royal address",
				effects = { Happiness = 18, Fame = 20 },
				requiresGamepass = "ROYALTY",
				requiresFlags = { is_royalty = true },
				gamepassEmoji = "👑",
				feedText = "👑 Your royal address moved the nation. Historic moment!",
			},
		},
	},
	{
		id = "premium_romantic_gesture",
		title = "Grand Romantic Gesture",
		emoji = "💕",
		text = "You want to do something special for your partner. Time for a grand gesture!",
		question = "What do you plan?",
		minAge = 18, maxAge = 70,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		category = "relationships",
		tags = { "romance", "love", "partner" },
		
		eligibility = function(state)
			return state.Flags and (state.Flags.has_partner or state.Flags.married)
		end,
		
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Plan a surprise dinner ($200)",
				effects = { Money = -200, Happiness = 10 },
				feedText = "The surprise dinner was perfect! Your partner loved it.",
				eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for dinner" end,
			},
			{
				text = "Write a heartfelt letter",
				effects = { Happiness = 8 },
				feedText = "Words from the heart. Your partner was moved to tears.",
			},
			{
				-- CRITICAL FIX: Show price and add eligibility check!
				text = "Plan a romantic trip ($3,000)",
				effects = { Money = -3000, Happiness = 20 },
				feedText = "💕 The trip was AMAZING! Memories for a lifetime!",
				eligibility = function(state) return (state.Money or 0) >= 3000, "💸 Need $3,000 for the trip" end,
			},
			{
				-- CRITICAL FIX: Add a FREE alternative so players aren't stuck!
				text = "Plan a special local date",
				effects = { Happiness = 10 },
				feedText = "💕 Stayed local but made it special. It's the thought that counts.",
			},
			-- ⭐ CELEBRITY PREMIUM OPTION
			{
				text = "⭐ [Celebrity] Televised romantic gesture!",
				effects = { Happiness = 30, Fame = 20, Money = 10000 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ Your romantic gesture went viral! Sponsors paid for everything!",
			},
			-- 👑 ROYALTY PREMIUM OPTION
			{
				text = "👑 [Royalty] Royal ball in their honor",
				effects = { Happiness = 25, Fame = 15 },
				requiresGamepass = "ROYALTY",
				requiresFlags = { is_royalty = true },
				gamepassEmoji = "👑",
				feedText = "👑 A royal ball! The kingdom celebrated your love!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Early-Game Gamepass Opportunities
	-- User complaint: "ONLY TIMES THEY CAN PURCHASE GAMEPASSES IS IN BEGINNING OF LIFE"
	-- These events appear during childhood/teen years to show premium options
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_dream_big",
		title = "Dream Big",
		emoji = "✨",
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #DREAMBIG-1: Added textVariants to prevent "always saying same thing"
		-- User complaint: "its spamming that dream big card every time i hit age 9"
		-- CRITICAL FIX #DREAMBIG-2: Changed minAge from 8 to 10 for better timing
		-- CRITICAL FIX #DREAMBIG-3: ALL choices now set dream_big_complete flag to GUARANTEE once-per-life
		-- CRITICAL FIX #DREAMBIG-4: Reduced baseChance from 0.85 to 0.65
		-- ═══════════════════════════════════════════════════════════════════════════════
		textVariants = {
			"You're lying on your bed, staring at the ceiling, thinking about your future. What will you become?",
			"While looking at the clouds, you imagine what your life could be like when you grow up.",
			"Your teacher asks everyone to write about their dreams. You start to really think about it...",
			"A career day at school has you thinking about all the possibilities in life.",
			"You just watched a movie that made you imagine an exciting future. What path calls to you?",
			"{{PARENT_NAME}} asks what you want to be when you grow up. It's a good question...",
			"While playing with friends, you all talk about your dreams for the future.",
			"A famous person came to your school! It got you thinking about what you could achieve.",
		},
		questionVariants = {
			"What do you dream about?",
			"What future do you imagine?",
			"What kind of life do you want?",
			"Which dream feels most real to you?",
		},
		text = "You're daydreaming about what you want to be when you grow up. The possibilities seem endless!",
		question = "What do you dream about?",
		minAge = 10, maxAge = 15,  -- CHANGED: Was 8-14, now 10-15 for better story timing
		baseChance = 0.65,         -- CHANGED: Was 0.85, reduced to prevent spam
		cooldown = 99,             -- CHANGED: Was 5, now 99 to effectively make it once-per-life
		oneTime = true,
		stage = "childhood",
		category = "dream",
		tags = { "dream", "aspiration", "early" },
		
		-- CRITICAL FIX: Block if player already saw this event OR made a premium wish
		blockedByFlags = { dream_big_complete = true, primary_wish_type = true },
		
		-- CRITICAL FIX: This onResolve runs BEFORE choices, sets the blocking flag no matter what
		onEventStart = function(state)
			state.Flags = state.Flags or {}
			state.Flags.dream_big_complete = true  -- Flag that this event was shown
		end,
		
		choices = {
			{
				text = "💰 Being rich and famous",
				effects = { Happiness = 5 },
				setFlags = { dreams_of_fame = true, dream_big_complete = true },
				feedText = "You dream of mansions, limos, and millions of adoring fans!",
			},
			{
				text = "❤️ Helping people",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { dreams_of_helping = true, dream_big_complete = true },
				feedText = "You want to make a difference in the world!",
			},
			{
				text = "🌍 Going on adventures",
				effects = { Happiness = 8 },
				setFlags = { dreams_of_adventure = true, dream_big_complete = true },
				feedText = "The world is your oyster! Adventure awaits!",
			},
			{
				text = "🔬 Becoming a genius scientist",
				effects = { Happiness = 5, Smarts = 5 },
				setFlags = { dreams_of_science = true, dream_big_complete = true },
				feedText = "You dream of laboratories, discoveries, and Nobel Prizes!",
			},
			{
				text = "🏆 Being a sports champion",
				effects = { Happiness = 5, Health = 3 },
				setFlags = { dreams_of_sports = true, dream_big_complete = true },
				feedText = "You imagine gold medals, roaring crowds, and victory!",
			},
			-- GAMEPASS OPTIONS
			-- CRITICAL FIX: Premium choices set primary_wish_type AND dream_big_complete
			{
				text = "⭐ [Celebrity] Be a famous superstar!",
				effects = { Happiness = 15, Fame = 5 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ You're destined for STARDOM! The spotlight awaits!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.star_dreamer = true
					state.Flags.fame_destiny = true
					state.Flags.fame_wish = true
					state.Flags.primary_wish_type = "celebrity"
					state.Flags.dream_big_complete = true
					-- Clear conflicting wishes
					state.Flags.palace_wish = nil
					state.Flags.royal_fantasies = nil
					state.Flags.power_wish = nil
					state.Flags.fascinated_by_power = nil
				end,
			},
			{
				text = "🔫 [Mafia] Running the underground...",
				effects = { Happiness = 10 },
				requiresGamepass = "MAFIA",
				gamepassEmoji = "🔫",
				feedText = "🔫 You're fascinated by crime movies and gangster stories...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.mob_fascination = true
					state.Flags.power_wish = true
					state.Flags.primary_wish_type = "mafia"
					state.Flags.dream_big_complete = true
					-- Clear conflicting wishes
					state.Flags.palace_wish = nil
					state.Flags.royal_fantasies = nil
					state.Flags.fame_wish = nil
					state.Flags.star_dreams = nil
				end,
			},
			{
				text = "👑 [Royalty] Living like a king or queen!",
				effects = { Happiness = 10, Looks = 2 },
				requiresGamepass = "ROYALTY",
				gamepassEmoji = "👑",
				feedText = "👑 You imagine palaces, crowns, and royal balls!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.royal_fantasies = true
					state.Flags.palace_wish = true
					state.Flags.primary_wish_type = "royalty"
					state.Flags.dream_big_complete = true
					-- Clear conflicting wishes
					state.Flags.power_wish = nil
					state.Flags.fascinated_by_power = nil
					state.Flags.fame_wish = nil
					state.Flags.star_dreams = nil
				end,
			},
		},
	},
	{
		id = "premium_turning_point",
		title = "Turning Point",
		emoji = "🛤️",
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #TURNPOINT-1: Added textVariants for variety
		-- CRITICAL FIX #TURNPOINT-2: ALL choices set turning_point_complete flag
		-- CRITICAL FIX #TURNPOINT-3: Block if dream_big already set a premium path
		-- ═══════════════════════════════════════════════════════════════════════════════
		textVariants = {
			"You feel like you're at a turning point in your young life. Different paths are opening up before you.",
			"High school is almost over. The real world is calling, and you have decisions to make.",
			"You wake up one day realizing you're not a kid anymore. What kind of person will you become?",
			"Your friends are all making plans for the future. It's time to think about yours.",
			"Senior year is a strange time. You're excited but scared about what comes next.",
			"Looking at college brochures, job listings, and life ahead, you feel the weight of choice.",
			"Everyone keeps asking what your plans are. Time to really think about it.",
			"As your teen years wind down, you sense that the path you choose now matters.",
		},
		questionVariants = {
			"Which direction calls to you?",
			"What path will you take?",
			"How will you shape your future?",
			"What's your next move?",
		},
		text = "You feel like you're at a turning point in your young life. Different paths are opening up before you.",
		question = "Which direction calls to you?",
		minAge = 16, maxAge = 19,
		baseChance = 0.60,  -- CHANGED: Was 0.8, reduced
		cooldown = 99,      -- CHANGED: Was 5, effectively once-per-life
		oneTime = true,
		stage = "teen",
		category = "milestone",
		tags = { "decision", "youth", "turning_point" },
		
		-- CRITICAL FIX: Block if already completed
		blockedByFlags = { turning_point_complete = true },
		
		choices = {
			{
				text = "📚 Focus on school and career",
				effects = { Smarts = 5, Happiness = 3 },
				setFlags = { studious_teen = true, turning_point_complete = true },
				feedText = "Education is the key! You buckle down and study hard.",
			},
			{
				text = "🎉 Live in the moment - enjoy being young!",
				effects = { Happiness = 10, Health = 3 },
				setFlags = { enjoying_youth = true, turning_point_complete = true },
				feedText = "YOLO! These are the best years of your life!",
			},
		{
			text = "💵 Start working and save money",
			effects = { Money = 1500 },
			setFlags = { young_earner = true, turning_point_complete = true, has_part_time_job = true },
			feedText = "You get a part-time job. First paycheck feels AMAZING!",
			-- CRITICAL FIX #801: Actually give the player a job!
			-- User complaint: "it said part-time job but I didn't get"
			onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.employed = true
				state.Flags.has_part_time_job = true
				state.Flags.first_job = true
				state.Flags.young_earner = true
				-- Set actual job
				state.CurrentJob = state.CurrentJob or {
					id = "part_time_retail",
					name = "Retail Associate (Part-Time)",
					category = "service",
					salary = 15000,
					isPartTime = true,
					yearsInJob = 0,
				}
				-- Add to job history
				state.JobHistory = state.JobHistory or {}
				table.insert(state.JobHistory, {
					id = "part_time_retail",
					name = "Retail Associate (Part-Time)",
					startAge = state.Age,
				})
				if state.AddFeed then
					state:AddFeed("💵 You got hired at a retail store! $15k/year part-time!")
				end
			end,
		},
			{
				text = "💪 Work on self-improvement",
				effects = { Health = 5, Looks = 3, Smarts = 2 },
				setFlags = { self_improver = true, turning_point_complete = true },
				feedText = "You hit the gym, read more books, and work on becoming your best self!",
			},
			{
				text = "🎨 Pursue your creative passions",
				effects = { Happiness = 8, Fame = 2 },
				setFlags = { creative_teen = true, turning_point_complete = true },
				feedText = "Art, music, writing - you dedicate yourself to your craft!",
			},
			-- GAMEPASS OPTIONS
			{
				text = "⭐ [Celebrity] Chase your dreams of fame!",
				effects = { Fame = 10, Happiness = 15 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				setFlags = { young_star = true, fame_path = true, turning_point_complete = true },
				feedText = "⭐ You start building your personal brand. The fame journey begins!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.primary_wish_type = state.Flags.primary_wish_type or "celebrity"
					state.Flags.turning_point_complete = true
				end,
			},
			{
				text = "🔫 [Mafia] Seek out the connected people...",
				effects = { Money = 5000, Happiness = 5 },
				requiresGamepass = "MAFIA",
				gamepassEmoji = "🔫",
				setFlags = { early_mob_contact = true, turning_point_complete = true },
				feedText = "🔫 You make some... interesting connections. Easy money!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.primary_wish_type = state.Flags.primary_wish_type or "mafia"
					state.Flags.turning_point_complete = true
				end,
			},
		},
	},
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: Premium opportunity events now track when shown to prevent spam
	-- Also reduced base chance and increased cooldown significantly
	-- CRITICAL FIX #2: This event should NOT show if player already made a childhood wish
	-- The childhood wish events are the proper way to enter premium paths
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_special_opportunity",
		title = "Life-Changing Opportunity",
		emoji = "🌟",
		text = "Something unusual is happening! You've caught the attention of some important people, and there's an opportunity to change your life's direction completely.",
		question = "What do you do with this opportunity?",
		minAge = 20, maxAge = 28,
		baseChance = 0.25, -- CRITICAL FIX: Further reduced to prevent spam
		cooldown = 30, -- CRITICAL FIX: Further increased
		oneTime = true,
		maxOccurrences = 1, -- CRITICAL FIX: Ensure it only happens once per life
		stage = "adult",
		category = "opportunity",
		tags = { "opportunity", "special", "life_changing" },
		
		-- CRITICAL FIX: Block if player already chose ANY premium path via childhood wish
		-- Also block if they're already in a premium state
		blockedByFlags = { 
			is_royalty = true, 
			in_mob = true, 
			is_famous = true, 
			celebrity = true, 
			premium_opportunity_shown = true,
			primary_wish_type = true, -- CRITICAL: Block if ANY childhood wish was made!
			dating_royalty = true,
			fame_career = true,
		},
		
		choices = {
			{
				text = "Play it safe - stick to the normal path",
				effects = { Happiness = 3 },
				setFlags = { played_safe = true, premium_opportunity_shown = true },
				feedText = "Sometimes the safe choice is the smart choice.",
			},
			{
				text = "Take a calculated risk",
				effects = {},
				feedText = "Rolling the dice on opportunity...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.premium_opportunity_shown = true
					local roll = math.random()
					if roll < 0.5 then
						state.Money = (state.Money or 0) + math.random(5000, 20000)
						state:ModifyStat("Happiness", 12)
						state:AddFeed("🌟 The risk paid off! Great reward!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🌟 Didn't work out, but at least you tried!")
					end
				end,
			},
			-- PREMIUM OPTIONS - Only for players who DIDN'T make a childhood wish
			-- These set primary_wish_type to ensure no conflicts
			{
				-- CRITICAL FIX: Clearer text explaining this is a PREMIUM path
				text = "⭐ [Celebrity] Pursue fame and stardom!",
				effects = { Fame = 25, Happiness = 15 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ You've been discovered! Hollywood here you come!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.entertainment_career = true
					state.Flags.premium_opportunity_shown = true
					state.Flags.chose_celebrity_path = true
					state.Flags.primary_wish_type = "celebrity" -- CRITICAL: Set to prevent conflicts
				end,
			},
			{
				text = "🔫 [Mafia] Join the family business...",
				effects = { Money = 25000, Happiness = 10 },
				requiresGamepass = "MAFIA",
				gamepassEmoji = "🔫",
				feedText = "🔫 You're in! Welcome to the family. Now the REAL money starts rolling in!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.in_mob = true
					state.Flags.premium_opportunity_shown = true
					state.Flags.chose_mafia_path = true
					state.Flags.primary_wish_type = "mafia" -- CRITICAL: Set to prevent conflicts
					-- Initialize mob state
					state.MobState = state.MobState or {}
					state.MobState.inMob = true
					state.MobState.familyName = "La Famiglia"
					state.MobState.rankLevel = 1
					state.MobState.rankName = "Associate"
					state.MobState.respect = 10
				end,
			},
			{
				text = "👑 [Royalty] Discover your royal lineage!",
				effects = { Fame = 20, Happiness = 20 },
				requiresGamepass = "ROYALTY",
				gamepassEmoji = "👑",
				feedText = "👑 Turns out you have royal blood! A distant connection to nobility!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.royal_bloodline = true
					state.Flags.noble_ancestry = true
					state.Flags.premium_opportunity_shown = true
					state.Flags.chose_royalty_path = true
					state.Flags.primary_wish_type = "royalty" -- CRITICAL: Set to prevent conflicts
				end,
			},
			{
				text = "⚡ [God Mode] Use your power to seize this moment!",
				effects = { Money = 50000, Happiness = 20, Health = 20 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				setFlags = { premium_opportunity_shown = true },
				feedText = "⚡ God Mode activated! You seized the opportunity with supernatural force!",
			},
		},
	},
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: VERY EARLY GAME PREMIUM TEASERS (Ages 5-7)
	-- User complaint: "Make first 5 minutes engaging, fun ASF"
	-- These events show premium content early but still give great options for free players
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "premium_career_day_dream",
		title = "Career Day Dreams",
		emoji = "💭",
		text = "It's career day at school! Everyone's talking about what they want to be when they grow up. What sounds exciting to you?",
		question = "What catches your imagination?",
		minAge = 5, maxAge = 7,
		baseChance = 0.6, -- CRITICAL FIX: Reduced from 0.9 - still good chance but not guaranteed
		cooldown = 99,
		oneTime = true,
		stage = "childhood",
		category = "dream",
		priority = "high",
		tags = { "career_day", "dream", "early", "engaging" },
		
		-- CRITICAL FIX: Block if player already made a premium wish
		blockedByFlags = { primary_wish_type = true },
		
		choices = {
			{
				text = "Doctor - helping people get better!",
				effects = { Smarts = 3, Happiness = 5 },
				setFlags = { dreams_medical = true, curious_about_science = true },
				feedText = "🩺 You put on a toy stethoscope. 'Say ahhh!' Your parents are proud of your caring heart!",
			},
			{
				text = "Astronaut - going to space!",
				effects = { Happiness = 8, Smarts = 2 },
				setFlags = { dreams_space = true, big_imagination = true },
				feedText = "🚀 '3... 2... 1... LIFTOFF!' You zoom around pretending to float in zero gravity!",
			},
			{
				text = "Firefighter - being a hero!",
				effects = { Health = 3, Happiness = 6 },
				setFlags = { dreams_hero = true, brave_spirit = true },
				feedText = "🚒 You slide down an imaginary pole. 'To the rescue!' Everyone claps!",
			},
			{
				text = "Artist - making beautiful things!",
				effects = { Happiness = 7, Looks = 1 },
				setFlags = { creative_spirit = true, artistic_interest = true },
				feedText = "🎨 You draw your dream life - it's colorful and full of possibility!",
			},
			-- PREMIUM TEASERS (Show what's possible with gamepasses!)
			-- CRITICAL FIX: Premium choices now set primary_wish_type to prevent conflicts
			{
				text = "⭐ [Celebrity] A famous movie star!",
				effects = { Happiness = 12, Fame = 8, Looks = 2 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ 'And the award goes to... YOU!' You practice your acceptance speech while everyone laughs and claps!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					-- Set primary wish type and specific flags
					state.Flags.star_dreams = true
					state.Flags.performer = true
					state.Flags.primary_wish_type = "celebrity"
					-- Clear conflicting wishes
					state.Flags.palace_wish = nil
					state.Flags.royal_fantasies = nil
					state.Flags.power_wish = nil
					state.Flags.fascinated_by_power = nil
				end,
			},
			{
				text = "🔫 [Mafia] A mysterious powerful boss...",
				effects = { Happiness = 10, Smarts = 3 },
				requiresGamepass = "MAFIA",
				gamepassEmoji = "🔫",
				feedText = "🔫 You've been watching too many movies... but the idea of being powerful is exciting!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					-- Set primary wish type and specific flag
					state.Flags.fascinated_by_power = true
					state.Flags.primary_wish_type = "mafia"
					-- Clear conflicting wishes
					state.Flags.palace_wish = nil
					state.Flags.royal_fantasies = nil
					state.Flags.fame_wish = nil
					state.Flags.star_dreams = nil
				end,
			},
			{
				text = "👑 [Royalty] A real-life king or queen!",
				effects = { Happiness = 12, Looks = 3 },
				requiresGamepass = "ROYALTY",
				gamepassEmoji = "👑",
				feedText = "👑 You make a paper crown and declare yourself ruler of the playground! Long live the king/queen!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					-- Set primary wish type and specific flag
					state.Flags.royal_fantasies = true
					state.Flags.primary_wish_type = "royalty"
					-- Clear conflicting wishes
					state.Flags.power_wish = nil
					state.Flags.fascinated_by_power = nil
					state.Flags.fame_wish = nil
					state.Flags.star_dreams = nil
				end,
			},
		},
	},
	{
		id = "premium_magic_wish",
		title = "Make a Wish!",
		emoji = "🌠",
		text = "You're blowing out your birthday candles! Everyone says if you make a wish without telling anyone, it might come true!",
		question = "What do you wish for?",
		minAge = 6, maxAge = 10,
		baseChance = 0.55, -- CRITICAL FIX: Reduced from 0.85 to prevent guaranteed trigger
		cooldown = 99,
		oneTime = true,
		stage = "childhood",
		category = "wish",
		priority = "high",
		tags = { "birthday", "wish", "early", "engaging" },
		
		-- CRITICAL FIX: Block if player already made a premium wish
		blockedByFlags = { primary_wish_type = true },
		
	choices = {
		{
			text = "For my family to be healthy!",
			effects = { Happiness = 6, Health = 3 },
			setFlags = { wished_family = true, caring_heart = true },
			feedText = "🎂 Such a sweet wish! Your parents are touched when you finally tell them years later.",
		},
		{
			text = "To be super smart!",
			effects = { Smarts = 5, Happiness = 5 },
			setFlags = { wished_intelligence = true },
			feedText = "🎂 Knowledge is power! Maybe this wish will help in school!",
		},
		{
			text = "For a puppy!",
			effects = { Happiness = 8 },
			setFlags = { wants_pet = true },
			feedText = "🎂 A classic wish! You look at your parents with hopeful eyes...",
		},
			-- PREMIUM OPTIONS
			-- CRITICAL FIX: Premium wishes now set primary_wish_type to prevent conflicts
			{
				text = "⭐ [Celebrity] To be famous!",
				effects = { Fame = 15, Happiness = 12 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ 'I wanna be FAMOUS!' Your parents laugh, but maybe dreams do come true...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					-- Set primary wish type and specific flag
					state.Flags.fame_wish = true
					state.Flags.primary_wish_type = "celebrity"
					-- Clear conflicting wishes
					state.Flags.palace_wish = nil
					state.Flags.royal_fantasies = nil
					state.Flags.power_wish = nil
					state.Flags.fascinated_by_power = nil
				end,
			},
			{
				text = "🔫 [Mafia] For unlimited power!",
				effects = { Happiness = 10, Smarts = 4 },
				requiresGamepass = "MAFIA",
				gamepassEmoji = "🔫",
				feedText = "🔫 An... interesting wish for a kid. You've been watching those crime shows with dad!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					-- Set primary wish type and specific flag
					state.Flags.power_wish = true
					state.Flags.primary_wish_type = "mafia"
					-- Clear conflicting wishes
					state.Flags.palace_wish = nil
					state.Flags.royal_fantasies = nil
					state.Flags.fame_wish = nil
					state.Flags.star_dreams = nil
				end,
			},
			{
				text = "👑 [Royalty] To live in a palace!",
				effects = { Happiness = 12, Looks = 4 },
				requiresGamepass = "ROYALTY",
				gamepassEmoji = "👑",
				feedText = "👑 Castles, crowns, and royal balls! Every kid's fantasy! Maybe someday...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					-- Set primary wish type and specific flag
					state.Flags.palace_wish = true
					state.Flags.primary_wish_type = "royalty"
					-- Clear conflicting wishes
					state.Flags.power_wish = nil
					state.Flags.fascinated_by_power = nil
					state.Flags.fame_wish = nil
					state.Flags.star_dreams = nil
				end,
			},
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX: WISH FOLLOW-UP EVENTS
	-- These events trigger when the player made a premium wish as a child
	-- and actually make their dreams come true!
	-- ══════════════════════════════════════════════════════════════════════════════

	-- ROYALTY PATH: Childhood wish leads to meeting royalty!
	{
		id = "premium_wish_royalty_encounter",
		title = "👑 Dreams Come True!",
		emoji = "👑",
		text = "Remember that birthday wish you made as a child? You wished to live in a palace... and today, at a charity gala, you lock eyes with a REAL prince/princess from a European kingdom. They seem captivated by you!",
		question = "Your childhood dream might be coming true! What do you do?",
		minAge = 18, maxAge = 35,
		baseChance = 0.85, -- High chance if you have the flags!
		cooldown = 50, -- Once per life
		oneTime = true,
		maxOccurrences = 1,
		stage = "random",
		category = "romance",
		priority = "high",
		tags = { "royalty", "romance", "wish_fulfillment", "fairy_tale" },

		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #MUTEX-1: Strict premium path mutex enforcement
		-- User complaint: "wished for mafia stuff royalty popped up"
		-- This event MUST ONLY trigger for players who chose ROYALTY path specifically
		-- ═══════════════════════════════════════════════════════════════════════════════
		blockedByFlags = { 
			married = true, 
			dating_royalty = true, 
			is_royalty = true,
			in_mob = true,
			mafia_member = true,
			is_famous = true,
			fame_career = true,
			mob_fascination = true,     -- CRITICAL: Block if chose mafia path
			power_wish = true,          -- CRITICAL: Block if chose mafia power wish
			star_dreamer = true,        -- CRITICAL: Block if chose celebrity path
			fame_destiny = true,        -- CRITICAL: Block if chose fame path
		},
		-- CRITICAL FIX: Must have ROYALTY wish flags
		requiresFlags = { palace_wish = true },
		requiresAnyFlags = { palace_wish = true, royal_fantasies = true },
		requiresGamepass = "ROYALTY",

		eligibility = function(state)
			-- CRITICAL FIX #MUTEX-2: STRICT check - primary_wish_type MUST be "royalty" or nil
			local primaryWish = state.Flags and state.Flags.primary_wish_type
			
			-- If player has ANY primary wish type set and it's NOT royalty, BLOCK
			if primaryWish and primaryWish ~= "royalty" then
				return false, "Player chose a different primary wish type: " .. tostring(primaryWish)
			end
			
			-- If player has mafia OR celebrity wish flags, BLOCK (double-check)
			if state.Flags then
				if state.Flags.mob_fascination or state.Flags.power_wish or state.Flags.fascinated_by_power then
					return false, "Player has mafia wish flags - cannot get royalty encounter"
				end
				if state.Flags.star_dreamer or state.Flags.fame_destiny or state.Flags.fame_wish then
					return false, "Player has celebrity wish flags - cannot get royalty encounter"
				end
			end
			
			-- Check for EITHER palace_wish OR royal_fantasies flag (required!)
			local hasWish = state.Flags and (state.Flags.palace_wish or state.Flags.royal_fantasies)
			if not hasWish then
				return false, "Player has no royalty wish flags"
			end
			
			local looks = (state.Stats and state.Stats.Looks) or 50
			return looks >= 40, "Need decent looks (40+) for royal romance"
		end,

		choices = {
			{
				text = "💕 Walk up and introduce yourself (be charming!)",
				effects = { Happiness = 20 },
				feedText = "Taking your shot at royalty...",
				onResolve = function(state)
					-- Helper functions for safe state manipulation
					local function modifyStat(statName, delta)
						if state.ModifyStat and type(state.ModifyStat) == "function" then
							state:ModifyStat(statName, delta)
						else
							state.Stats = state.Stats or {}
							local currentVal = tonumber(state.Stats[statName]) or 50
							local newVal = currentVal + (tonumber(delta) or 0)
							state.Stats[statName] = math.max(0, math.min(100, newVal))
						end
					end
					local function addFeed(text)
						if state.AddFeed and type(state.AddFeed) == "function" then
							state:AddFeed(text)
						else
							state.PendingFeed = text
						end
					end
					
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					-- Very high success chance since this is a wish-fulfillment event!
					local successChance = 0.65 + (looks / 200)

					if roll < successChance then
						modifyStat("Happiness", 25)
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						state.Flags.dating_royalty = true
						state.Flags.royal_romance = true
						state.Flags.wish_came_true = true
						state.Money = (state.Money or 0) + 100000 -- Royal gifts!

						-- Create royal partner
						-- CRITICAL FIX: Normalize gender to lowercase for case-insensitive comparison
						local playerGender = (state.Gender or "male"):lower()
						local partnerGender = (playerGender == "female") and "male" or "female"
						local title = partnerGender == "male" and "Prince" or "Princess"
						local royalNames_male = {"Alexander", "William", "Henrik", "Frederik", "Carl", "Philippe", "Guillaume"}
						local royalNames_female = {"Victoria", "Madeleine", "Mary", "Maxima", "Elisabeth", "Charlotte", "Leonor"}
						local royalCountries = {"Monaco", "Sweden", "Denmark", "Netherlands", "Belgium", "Luxembourg", "Norway"}
						local names = partnerGender == "male" and royalNames_male or royalNames_female
						local country = royalCountries[math.random(1, #royalCountries)]
						local name = names[math.random(1, #names)]

						state.Relationships = state.Relationships or {}
						state.Relationships.partner = {
							id = "royal_partner_wish",
							name = title .. " " .. name .. " of " .. country,
							type = "romantic",
							role = "Royal Partner",
							relationship = 85,
							gender = partnerGender,
							age = (state.Age or 25) + math.random(-3, 5),
							alive = true,
							metAge = state.Age,
							isRoyalty = true,
							royalCountry = country,
							royalTitle = title,
						}

						addFeed("👑✨ YOUR CHILDHOOD WISH CAME TRUE! You're dating " .. title .. " " .. name .. " of " .. country .. "! This is a FAIRY TALE come to life!")
					else
						modifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.met_royalty = true
						addFeed("👑 They were charming but had to leave. You exchanged numbers though - maybe next time!")
					end
				end,
			},
			{
				text = "🙈 Too nervous - just admire from afar",
				effects = { Happiness = -5 },
				feedText = "👑 You froze up. The royalty left, and with them, your chance. But dreams don't give up easily...",
				setFlags = { missed_royal_chance = true },
			},
			{
				text = "📱 Casually 'accidentally' bump into them",
				effects = { Happiness = 15 },
				feedText = "Playing it smooth...",
				onResolve = function(state)
					-- Helper functions for safe state manipulation
					local function modifyStat(statName, delta)
						if state.ModifyStat and type(state.ModifyStat) == "function" then
							state:ModifyStat(statName, delta)
						else
							state.Stats = state.Stats or {}
							local currentVal = tonumber(state.Stats[statName]) or 50
							local newVal = currentVal + (tonumber(delta) or 0)
							state.Stats[statName] = math.max(0, math.min(100, newVal))
						end
					end
					local function addFeed(text)
						if state.AddFeed and type(state.AddFeed) == "function" then
							state:AddFeed(text)
						else
							state.PendingFeed = text
						end
					end
					
					local roll = math.random()
					if roll < 0.5 then
						modifyStat("Happiness", 20)
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						state.Flags.dating_royalty = true
						state.Flags.royal_romance = true
						state.Flags.wish_came_true = true
						state.Money = (state.Money or 0) + 75000
						
						-- Also create a partner relationship for this path
						-- CRITICAL FIX: Normalize gender to lowercase for case-insensitive comparison
						local playerGender = (state.Gender or "male"):lower()
						local partnerGender = (playerGender == "female") and "male" or "female"
						local title = partnerGender == "male" and "Prince" or "Princess"
						local royalNames_male = {"Alexander", "William", "Henrik", "Frederik", "Carl", "Philippe"}
						local royalNames_female = {"Victoria", "Madeleine", "Mary", "Maxima", "Elisabeth", "Charlotte"}
						local royalCountries = {"Monaco", "Sweden", "Denmark", "Netherlands", "Belgium", "Luxembourg"}
						local names = partnerGender == "male" and royalNames_male or royalNames_female
						local country = royalCountries[math.random(1, #royalCountries)]
						local name = names[math.random(1, #names)]
						
						state.Relationships = state.Relationships or {}
						state.Relationships.partner = {
							id = "royal_partner_bump",
							name = title .. " " .. name .. " of " .. country,
							type = "romantic",
							role = "Royal Partner",
							relationship = 80,
							gender = partnerGender,
							age = (state.Age or 25) + math.random(-3, 5),
							alive = true,
							metAge = state.Age,
							isRoyalty = true,
							royalCountry = country,
							royalTitle = title,
						}
						
						addFeed("👑💕 Your 'accident' worked! They found it adorable. You're now dating " .. title .. " " .. name .. "! Childhood dreams do come true!")
					else
						modifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.met_royalty = true
						addFeed("👑 The bump was awkward but they were gracious. You got their assistant's card!")
					end
				end,
			},
		},
	},

	-- ROYALTY PROPOSAL - Follows the encounter event
	{
		id = "premium_wish_royal_proposal",
		title = "👑💍 A Royal Proposal!",
		emoji = "👑",
		text = "Your royal partner kneels before you with a stunning ring. 'You've changed my life,' they say. 'I want to make you part of my world - forever. The kingdom awaits their new prince/princess!'",
		question = "This is the ultimate fairy tale moment! What do you say?",
		minAge = 19, maxAge = 50,
		baseChance = 0.9, -- Almost guaranteed if you have the flags
		cooldown = 99,
		oneTime = true,
		maxOccurrences = 1,
		stage = "random",
		category = "romance",
		priority = "critical",
		tags = { "royalty", "proposal", "marriage", "fairy_tale" },

		requiresFlags = { dating_royalty = true, royal_romance = true },
		blockedFlags = { married = true, is_royalty = true },
		requiresGamepass = "ROYALTY",

		choices = {
			{
				text = "💍 YES! I'll be royalty!",
				effects = { Happiness = 50 },
				feedText = "The fairy tale is complete...",
				onResolve = function(state)
					-- Helper functions for safe state manipulation
					local function modifyStat(statName, delta)
						if state.ModifyStat and type(state.ModifyStat) == "function" then
							state:ModifyStat(statName, delta)
						else
							state.Stats = state.Stats or {}
							local currentVal = tonumber(state.Stats[statName]) or 50
							local newVal = currentVal + (tonumber(delta) or 0)
							state.Stats[statName] = math.max(0, math.min(100, newVal))
						end
					end
					local function addFeed(text)
						if state.AddFeed and type(state.AddFeed) == "function" then
							state:AddFeed(text)
						else
							state.PendingFeed = text
						end
					end
					
					modifyStat("Happiness", 30)
					state.Flags = state.Flags or {}
					state.Flags.is_royalty = true
					state.Flags.royal_by_marriage = true
					state.Flags.married = true
					state.Flags.engaged = nil
					state.Flags.dating_royalty = nil
					state.Flags.fairy_tale_complete = true

					-- Massive wealth from marrying into royalty!
					state.Money = (state.Money or 0) + 25000000
					
					-- Update partner to spouse
					if state.Relationships and state.Relationships.partner then
						state.Relationships.partner.role = "Royal Spouse"
					end

					-- Initialize royal state
					state.RoyalState = state.RoyalState or {}
					state.RoyalState.isRoyal = true
					-- CRITICAL FIX: Normalize gender to lowercase for case-insensitive comparison
					local playerGender = (state.Gender or "male"):lower()
					state.RoyalState.title = (playerGender == "female") and "Princess Consort" or "Prince Consort"
					state.RoyalState.popularity = 75
					state.RoyalState.royalDuties = 0
					state.RoyalState.scandals = 0
					state.RoyalState.royalCountry = state.Relationships and state.Relationships.partner and state.Relationships.partner.royalCountry or "Monaco"

					addFeed("👑💍✨ YOU MARRIED INTO ROYALTY! Your childhood wish to live in a palace has COMPLETELY COME TRUE! You are now a member of the royal family with $25 million in royal gifts!")
				end,
			},
			{
				text = "🤔 I need time to think...",
				effects = { Happiness = 5 },
				setFlags = { considering_royal_proposal = true },
				feedText = "👑 They understand. 'Take all the time you need, my love.'",
			},
			{
				text = "💔 I can't handle royal life",
				effects = { Happiness = -20 },
				feedText = "👑💔 You declined. The world might not understand, but it was your choice. The prince/princess left heartbroken...",
				setFlags = { rejected_royalty = true },
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.dating_royalty = nil
					state.Flags.royal_romance = nil
					state.Flags.has_partner = nil
					-- Clear partner relationship
					if state.Relationships then
						state.Relationships.partner = nil
					end
				end,
			},
		},
	},

	-- MAFIA PATH: Childhood wish leads to mob recruitment!
	{
		id = "premium_wish_mafia_approach",
		title = "🔫 An Offer You Can't Refuse",
		emoji = "🔫",
		text = "Remember wishing for 'unlimited power' as a kid? A well-dressed man approaches you at a café. 'I've been watching you,' he says. 'You remind me of myself when I was young. I can offer you power, money, respect... but once you're in, you're family for life.'",
		question = "The mob is recruiting YOU! Your childhood wish for power might come true...",
		minAge = 18, maxAge = 35,
		baseChance = 0.85,
		cooldown = 50,
		oneTime = true,
		maxOccurrences = 1,
		stage = "random",
		category = "crime",
		priority = "high",
		tags = { "mafia", "recruitment", "wish_fulfillment", "power" },
		isMafiaOnly = true, -- CRITICAL: Use init.lua's strict filtering

		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #MUTEX-3: Strict premium path mutex enforcement for MAFIA
		-- This event MUST ONLY trigger for players who chose MAFIA path specifically
		-- ═══════════════════════════════════════════════════════════════════════════════
		blockedByFlags = { 
			in_mob = true, 
			refused_mob = true, 
			is_royalty = true, 
			dating_royalty = true, 
			royal_romance = true,
			is_famous = true,
			fame_career = true,
			palace_wish = true,         -- CRITICAL: Block if chose royalty path
			royal_fantasies = true,     -- CRITICAL: Block if chose royalty path
			star_dreamer = true,        -- CRITICAL: Block if chose celebrity path
			fame_destiny = true,        -- CRITICAL: Block if chose fame path
			fame_wish = true,           -- CRITICAL: Block if chose fame path
		},
		-- CRITICAL FIX: Must have MAFIA wish flags
		requiresAnyFlags = { power_wish = true, fascinated_by_power = true, mob_fascination = true },
		requiresGamepass = "MAFIA",

		eligibility = function(state)
			-- CRITICAL FIX #MUTEX-4: STRICT check - primary_wish_type MUST be "mafia" or nil
			local primaryWish = state.Flags and state.Flags.primary_wish_type
			
			-- If player has ANY primary wish type set and it's NOT mafia, BLOCK
			if primaryWish and primaryWish ~= "mafia" then
				return false, "Player chose a different primary wish type: " .. tostring(primaryWish)
			end
			
			-- If player has royalty OR celebrity wish flags, BLOCK (double-check)
			if state.Flags then
				if state.Flags.palace_wish or state.Flags.royal_fantasies then
					return false, "Player has royalty wish flags - cannot get mafia approach"
				end
				if state.Flags.star_dreamer or state.Flags.fame_destiny or state.Flags.fame_wish then
					return false, "Player has celebrity wish flags - cannot get mafia approach"
				end
			end
			
			-- Check for mafia wish flags (required!)
			local hasWish = state.Flags and (state.Flags.power_wish or state.Flags.fascinated_by_power or state.Flags.mob_fascination)
			if not hasWish then
				return false, "Player has no mafia wish flags"
			end
			
			return true, "Eligible for mafia approach"
		end,

		choices = {
			{
				text = "🔫 Accept - join the family",
				effects = { Happiness = 15, Smarts = 5 },
				feedText = "Becoming part of the family...",
				onResolve = function(state)
					-- Helper functions for safe state manipulation
					local function modifyStat(statName, delta)
						if state.ModifyStat and type(state.ModifyStat) == "function" then
							state:ModifyStat(statName, delta)
						else
							state.Stats = state.Stats or {}
							local currentVal = tonumber(state.Stats[statName]) or 50
							local newVal = currentVal + (tonumber(delta) or 0)
							state.Stats[statName] = math.max(0, math.min(100, newVal))
						end
					end
					local function addFeed(text)
						if state.AddFeed and type(state.AddFeed) == "function" then
							state:AddFeed(text)
						else
							state.PendingFeed = text
						end
					end
					
					modifyStat("Happiness", 20)
					state.Flags = state.Flags or {}
					state.Flags.in_mob = true
					state.Flags.mafia_member = true
					state.Flags.power_wish_granted = true
					state.Money = (state.Money or 0) + 50000 -- Welcome bonus

					-- Initialize mob state
					state.MobState = state.MobState or {}
					state.MobState.inMob = true
					state.MobState.familyId = "italian"
					state.MobState.familyName = "La Cosa Nostra"
					state.MobState.familyEmoji = "🇮🇹"
					state.MobState.rankLevel = 1
					state.MobState.rankName = "Associate"
					state.MobState.rankEmoji = "🔰"
					state.MobState.respect = 10
					state.MobState.heat = 0
					state.MobState.loyalty = 60
					state.MobState.successfulOps = 0
					state.MobState.failedOps = 0

					addFeed("🔫✨ YOUR CHILDHOOD WISH FOR POWER CAME TRUE! You've been initiated into La Cosa Nostra! You received $50,000 as a welcome 'gift'. The life of crime awaits!")
				end,
			},
			{
				text = "🤔 I need to think about it...",
				effects = { Happiness = 0 },
				setFlags = { considering_mob = true },
				feedText = "🔫 'Smart. Take a week. But don't take too long - opportunities like this don't come twice.' He slides a card across the table with just a phone number.",
			},
			{
				text = "❌ No thanks - I'm not cut out for this",
				effects = { Happiness = 5 },
				setFlags = { refused_mob = true },
				feedText = "🔫 He nods slowly. 'Wise choice for some. Cowardly for others. We won't ask again.' He walks away, and the door to that world closes forever.",
			},
			{
				text = "🏃 This is terrifying - RUN!",
				effects = { Happiness = -10, Health = 5 },
				setFlags = { fled_mob = true, refused_mob = true },
				feedText = "🔫 You bolted out the back door. Smart? Maybe. But some opportunities only knock once...",
			},
		},
	},

	-- MAFIA RISE: Follow-up for mob members to rise in ranks
	{
		id = "premium_mafia_big_opportunity",
		title = "🔫 Your Big Chance",
		emoji = "🔫",
		text = "The Don himself summons you. 'You've proven yourself loyal,' he says. 'There's a big job coming up. Pull this off, and you'll be made - a full member of the family. Fail, and...' He doesn't finish the sentence.",
		question = "This is your chance to rise in the mafia! What do you do?",
		minAge = 20, maxAge = 50,
		baseChance = 0.7,
		cooldown = 3,
		oneTime = true,
		maxOccurrences = 1,
		stage = "random",
		category = "crime",
		priority = "high",
		tags = { "mafia", "promotion", "crime" },

		requiresFlags = { in_mob = true },
		requiresGamepass = "MAFIA",

		choices = {
			{
				text = "🎯 Take the job - time to prove myself",
				effects = {},
				feedText = "Taking on the big job...",
				onResolve = function(state)
					-- Helper functions for safe state manipulation
					local function modifyStat(statName, delta)
						if state.ModifyStat and type(state.ModifyStat) == "function" then
							state:ModifyStat(statName, delta)
						else
							state.Stats = state.Stats or {}
							local currentVal = tonumber(state.Stats[statName]) or 50
							local newVal = currentVal + (tonumber(delta) or 0)
							state.Stats[statName] = math.max(0, math.min(100, newVal))
						end
					end
					local function addFeed(text)
						if state.AddFeed and type(state.AddFeed) == "function" then
							state:AddFeed(text)
						else
							state.PendingFeed = text
						end
					end
					
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.4 + (smarts / 200)

					if roll < successChance then
						modifyStat("Happiness", 30)
						state.Money = (state.Money or 0) + 200000
						state.MobState = state.MobState or {}
						state.MobState.rankLevel = (state.MobState.rankLevel or 1) + 2
						state.MobState.rankName = "Made Man"
						state.MobState.rankEmoji = "🔫"
						state.MobState.respect = (state.MobState.respect or 0) + 50
						state.Flags = state.Flags or {}
						state.Flags.made_man = true
						addFeed("🔫🎉 THE JOB WAS A SUCCESS! You've been 'made' - a full member of the family! You received $200,000 and massive respect. You're now a Made Man!")
					else
						modifyStat("Happiness", -20)
						modifyStat("Health", -15)
						state.MobState = state.MobState or {}
						state.MobState.heat = (state.MobState.heat or 0) + 30
						state.MobState.respect = math.max(0, (state.MobState.respect or 0) - 20)
						addFeed("🔫💀 The job went sideways! You barely escaped. The family is disappointed, and you've got heat on you now.")
					end
				end,
			},
			{
				text = "🙏 Ask for more time to prepare",
				effects = { Happiness = -5 },
				setFlags = { delayed_mob_job = true },
				feedText = "🔫 'Time is a luxury in our business. But fine - one week. Don't disappoint me.'",
			},
			{
				text = "😰 I'm not ready for this level",
				effects = { Happiness = -10 },
				feedText = "🔫 The Don's face hardens. 'Disappointing. I had hopes for you.' Your standing in the family drops...",
				onResolve = function(state)
					state.MobState = state.MobState or {}
					state.MobState.respect = math.max(0, (state.MobState.respect or 0) - 30)
					state.MobState.loyalty = math.max(0, (state.MobState.loyalty or 50) - 20)
				end,
			},
		},
	},

	-- CELEBRITY WISH FOLLOW-UP
	{
		id = "premium_wish_fame_discovery",
		title = "⭐ Discovered!",
		emoji = "⭐",
		text = "Remember wishing to be famous? A talent scout approaches you! 'You've got IT - that star quality! I want to make you famous. Movie auditions, TV shows, the whole package. What do you say?'",
		question = "Your childhood dream of fame might come true!",
		minAge = 16, maxAge = 30,
		baseChance = 0.85,
		cooldown = 50,
		oneTime = true,
		maxOccurrences = 1,
		stage = "random",
		category = "career",
		priority = "high",
		tags = { "celebrity", "fame", "wish_fulfillment" },

		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #MUTEX-5: Strict premium path mutex enforcement for CELEBRITY
		-- This event MUST ONLY trigger for players who chose CELEBRITY path specifically
		-- ═══════════════════════════════════════════════════════════════════════════════
		blockedByFlags = { 
			is_famous = true,
			fame_career = true,
			palace_wish = true,         -- CRITICAL: Block if chose royalty path
			royal_fantasies = true,     -- CRITICAL: Block if chose royalty path
			is_royalty = true,
			dating_royalty = true,
			power_wish = true,          -- CRITICAL: Block if chose mafia path
			mob_fascination = true,     -- CRITICAL: Block if chose mafia path
			in_mob = true,
		},
		-- CRITICAL FIX: Must have CELEBRITY wish flags
		requiresAnyFlags = { fame_wish = true, star_dreams = true, star_dreamer = true, fame_destiny = true },
		requiresGamepass = "CELEBRITY",

		eligibility = function(state)
			-- CRITICAL FIX #MUTEX-6: STRICT check - primary_wish_type MUST be "celebrity" or nil
			local primaryWish = state.Flags and state.Flags.primary_wish_type
			
			-- If player has ANY primary wish type set and it's NOT celebrity, BLOCK
			if primaryWish and primaryWish ~= "celebrity" then
				return false, "Player chose a different primary wish type: " .. tostring(primaryWish)
			end
			
			-- If player has royalty OR mafia wish flags, BLOCK (double-check)
			if state.Flags then
				if state.Flags.palace_wish or state.Flags.royal_fantasies then
					return false, "Player has royalty wish flags - cannot get fame discovery"
				end
				if state.Flags.power_wish or state.Flags.mob_fascination or state.Flags.fascinated_by_power then
					return false, "Player has mafia wish flags - cannot get fame discovery"
				end
			end
			
			-- Check for celebrity wish flags (required!)
			local hasWish = state.Flags and (state.Flags.fame_wish or state.Flags.star_dreams or state.Flags.star_dreamer or state.Flags.fame_destiny or state.Flags.performer)
			if not hasWish then
				return false, "Player has no celebrity wish flags"
			end
			
			return true, "Eligible for fame discovery"
		end,

		choices = {
			{
				text = "⭐ YES! Make me a star!",
				effects = { Happiness = 30, Fame = 25 },
				feedText = "Starting your journey to stardom...",
				onResolve = function(state)
					-- Helper functions for safe state manipulation
					local function modifyStat(statName, delta)
						if state.ModifyStat and type(state.ModifyStat) == "function" then
							state:ModifyStat(statName, delta)
						else
							state.Stats = state.Stats or {}
							local currentVal = tonumber(state.Stats[statName]) or 50
							local newVal = currentVal + (tonumber(delta) or 0)
							state.Stats[statName] = math.max(0, math.min(100, newVal))
						end
					end
					local function addFeed(text)
						if state.AddFeed and type(state.AddFeed) == "function" then
							state:AddFeed(text)
						else
							state.PendingFeed = text
						end
					end
					
					modifyStat("Happiness", 25)
					-- Handle Fame specially since it's not a standard stat
					state.Fame = math.min(100, (state.Fame or 0) + 30) -- CRITICAL FIX: Cap fame at 100
					state.Flags = state.Flags or {}
					state.Flags.is_famous = true
					state.Flags.celebrity = true
					state.Flags.discovered = true
					state.Flags.fame_wish_granted = true
					state.Flags.talent_discovered = true
					state.Money = (state.Money or 0) + 100000 -- Signing bonus
					
					-- Initialize fame state for proper celebrity handling
					state.FameState = state.FameState or {}
					state.FameState.careerPath = "entertainment"
					state.FameState.talent = "acting"
					state.FameState.discovered = true

					addFeed("⭐✨ YOUR CHILDHOOD WISH TO BE FAMOUS CAME TRUE! You signed with a major talent agency! You received $100,000 signing bonus and your career has LAUNCHED!")
				end,
			},
			{
				text = "🤔 What's the catch?",
				effects = { Happiness = 5 },
				setFlags = { cautious_about_fame = true },
				feedText = "⭐ 'Smart question! Nothing's free - hard work, long hours, public scrutiny. But the rewards...' They hand you their card.",
			},
			{
				text = "❌ Fame isn't for me anymore",
				effects = { Happiness = 0 },
				setFlags = { rejected_fame = true },
				feedText = "⭐ 'Your loss, kid. Some people dream their whole lives for this chance.' They walk away, shaking their head.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #539: Premium Teaser Events - Show free players what they're missing!
	-- These events give everyone a FUN experience but make premium look amazing
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "premium_teaser_viral_video",
		title = "🎥 Your Video Went Viral!",
		emoji = "🎥",
		text = "You posted a video online and it BLEW UP! Millions of views! Brands are reaching out!",
		question = "What do you do with this moment of fame?",
		minAge = 13, maxAge = 40,
		baseChance = 0.3,
		cooldown = 10,
		oneTime = true,
		stage = STAGE,
		category = "random",
		tags = { "fame", "social_media", "viral", "teaser" },
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #601: Viral video REQUIRES player to have actually posted content!
		-- User complaint: "Video went viral but I never posted any videos"
		-- This event should ONLY fire if player has content creator flags!
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local flags = state.Flags or {}
			-- CRITICAL: Must NOT have celebrity gamepass (this is a teaser event)
			if flags.celebrity_gamepass or flags.celebrity_career_chosen then
				return false
			end
			-- CRITICAL FIX: Player MUST have actually created content!
			-- Check for any flag indicating they've posted videos/content
			local hasCreatedContent = flags.content_creator or flags.streamer or flags.influencer
				or flags.first_video_posted or flags.first_video_uploaded or flags.youtube_started
				or flags.youtube_channel or flags.pursuing_streaming or flags.social_media_active
				or flags.gaming_content or flags.vlog_content or flags.vlogger or flags.daily_uploader
			if not hasCreatedContent then
				return false, "Player hasn't created any content yet"
			end
			return true
		end,
		choices = {
			{
				text = "Try to capitalize on it! 💰",
				effects = { Happiness = 10, Money = 500 },
				feedText = "🎥 You made a few bucks from sponsors... but the fame faded quickly.",
			},
			{
				text = "⭐ [Celebrity] Pursue REAL fame!",
				effects = { Happiness = 15 },
				requiresGamepass = "CELEBRITY",
				setFlags = { celebrity_gamepass = true, content_creator = true },
				feedText = "⭐ With the Celebrity Gamepass, you can turn this into a CAREER!",
			},
			{
				text = "Enjoy the moment and move on 🤷",
				effects = { Happiness = 5 },
				feedText = "🎥 Nice while it lasted!",
			},
		},
	},
	
	{
		id = "premium_teaser_overwhelming_problems",
		title = "😩 Everything Is Going Wrong!",
		emoji = "😩",
		text = "Your health is declining, you're stressed, nothing seems right. If only you could just FIX everything!",
		question = "How do you handle this?",
		minAge = 18, maxAge = 80,
		baseChance = 0.3,
		cooldown = 5,
		oneTime = false,
		maxOccurrences = 2,
		stage = STAGE,
		category = "random",
		tags = { "stress", "problems", "godmode", "teaser" },
		eligibility = function(state)
			local flags = state.Flags or {}
			if flags.god_mode_gamepass then return false end
			local health = (state.Stats and state.Stats.Health) or 50
			local happiness = (state.Stats and state.Stats.Happiness) or 50
			return health < 50 or happiness < 40
		end,
		choices = {
			{
				text = "Try to fix things one at a time... 😤",
				effects = { Happiness = 3, Health = 2, Smarts = 1 },
				feedText = "😤 You're working on it slowly...",
			},
			{
				text = "⚡ Take TOTAL Control! (God Mode Gamepass)",
				effects = { Happiness = 25, Health = 25, Smarts = 5, Looks = 5 },
				requiresGamepass = "GOD_MODE",
				setFlags = { god_mode_gamepass = true },
				feedText = "⚡ With GOD MODE, you have COMPLETE CONTROL! Edit your stats - everything!",
			},
			{
				text = "Accept life as it is 😔",
				effects = { Happiness = -5 },
				feedText = "😔 Sometimes life is just hard...",
			},
		},
	},
}

return PremiumIntegratedEvents
