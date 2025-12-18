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
				text = "Follow the treatment plan religiously",
				effects = { Health = 15, Happiness = 5, Money = -500 },
				setFlags = { health_conscious = true },
				feedText = "You committed to the treatment. Slow but steady recovery!",
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
		cooldown = 2,
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
				text = "⭐ [Celebrity] Launch your career NOW",
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
				text = "⭐ [Celebrity] Parlay into stardom",
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
			return flags.engaged or flags.getting_married
		end,
		
		choices = {
			{
				text = "Simple courthouse wedding",
				effects = { Happiness = 8, Money = -200 },
				setFlags = { married = true, has_partner = true },
				feedText = "Simple but meaningful. You're married!",
			},
			{
				text = "Traditional ceremony",
				effects = { Happiness = 12, Money = -5000 },
				setFlags = { married = true, has_partner = true, traditional_wedding = true },
				feedText = "Beautiful ceremony with family and friends!",
			},
			{
				text = "Big expensive wedding",
				effects = {},
				setFlags = { married = true, has_partner = true },
				feedText = "Going all out...",
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 20000 then
						state.Money = money - 20000
						state:ModifyStat("Happiness", 18)
						state:AddFeed("💒 SPECTACULAR wedding! Everyone will remember it!")
						state.Flags = state.Flags or {}
						state.Flags.lavish_wedding = true
					else
						state.Money = math.max(0, money - 15000)
						state:ModifyStat("Happiness", 10)
						state:AddFeed("💒 Great wedding but went over budget. Worth it?")
						state.Flags = state.Flags or {}
						state.Flags.wedding_debt = true
					end
				end,
			},
			-- 👑 ROYALTY PREMIUM OPTION
			{
				text = "👑 [Royalty] Royal wedding extravaganza",
				effects = { Happiness = 25, Fame = 30 },
				requiresGamepass = "ROYALTY",
				gamepassEmoji = "👑",
				feedText = "👑 A ROYAL-STYLE WEDDING! Fit for a king!",
				setFlags = { married = true, has_partner = true, royal_wedding = true },
			},
			-- ⭐ CELEBRITY PREMIUM OPTION
			{
				text = "⭐ [Celebrity] Televised celebrity wedding",
				effects = { Happiness = 20, Fame = 25, Money = 50000 },
				requiresGamepass = "CELEBRITY",
				gamepassEmoji = "⭐",
				feedText = "⭐ Your wedding was on TV! Sponsors paid for everything!",
				setFlags = { married = true, has_partner = true, celebrity_wedding = true },
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
		cooldown = 2,
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
		baseChance = 0.4,
		cooldown = 5,
		oneTime = true,
		stage = STAGE,
		category = "milestone",
		tags = { "decision", "life_change", "important" },
		
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
						state.Money = (state.Money or 0) - math.random(1000, 5000)
						state:ModifyStat("Happiness", -10)
						state:AddFeed("🔀 The risk didn't pay off. Lesson learned the hard way.")
					end
				end,
			},
			{
				text = "Follow your passion",
				effects = { Happiness = 12, Money = -500 },
				setFlags = { passion_follower = true },
				feedText = "Money isn't everything. Doing what you love!",
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
				text = "⭐ [Celebrity] Chase fame and fortune",
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
					local loss = math.min(state.Money or 0, math.random(100, 500))
					state.Money = (state.Money or 0) - loss
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
						local loss = math.min(state.Money or 0, math.random(200, 800))
						state.Money = (state.Money or 0) - loss
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
						local loss = math.min(state.Money or 0, math.random(300, 1000))
						state.Money = (state.Money or 0) - loss
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
				text = "Hire an expensive lawyer",
				effects = {},
				feedText = "Getting professional representation...",
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 5000 then
						state.Money = money - 5000
						local roll = math.random()
						if roll < 0.70 then
							state:ModifyStat("Happiness", 15)
							state:AddFeed("⚖️ WON the case! Expensive lawyer was worth it!")
						else
							state:ModifyStat("Happiness", -5)
							state:AddFeed("⚖️ Lost despite the expensive lawyer. System is broken.")
						end
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("⚖️ Couldn't afford the good lawyer. Had to go with public defender.")
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
				text = "Settle out of court",
				effects = { Money = -2000, Happiness = 5 },
				feedText = "Reached a settlement. Not ideal but it's over.",
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
		cooldown = 2,
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
				text = "⭐ [Celebrity] Become the star of the party",
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
		cooldown = 2,
		stage = STAGE,
		category = "finance",
		tags = { "business", "investment", "opportunity" },
		
		eligibility = function(state)
			return (state.Money or 0) >= 1000
		end,
		
		choices = {
			{
				text = "Invest small amount ($1,000)",
				effects = {},
				feedText = "Small investment, small risk...",
				onResolve = function(state)
					state.Money = (state.Money or 0) - 1000
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
				onResolve = function(state)
					local investment = math.floor((state.Money or 0) * 0.8)
					state.Money = (state.Money or 0) - investment
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
		cooldown = 2,
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
		cooldown = 2,
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
		cooldown = 2,
		stage = STAGE,
		category = "career",
		tags = { "job", "interview", "career" },
		
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
				text = "⭐ [Celebrity] Use your fame to get hired",
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
			return (state.Money or 0) >= 1000
		end,
		
		choices = {
			{
				text = "Give them the money",
				effects = {},
				feedText = "Helping a friend in need...",
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 5000 then
						state.Money = money - 5000
						local roll = math.random()
						if roll < 0.60 then
							state:ModifyStat("Happiness", 15)
							state:AddFeed("🤝 They paid you back! True friend!")
							state.Money = (state.Money or 0) + 5000
						else
							state:ModifyStat("Happiness", -5)
							state:AddFeed("🤝 Never saw that money again. Lesson learned.")
						end
					else
						state:ModifyStat("Happiness", 5)
						local gift = math.floor(money * 0.5)
						state.Money = money - gift
						state:AddFeed(string.format("🤝 Gave what you could: $%d. They appreciated it.", gift))
					end
				end,
			},
			{
				text = "Say no",
				effects = { Happiness = -5 },
				feedText = "You can't afford to help. They understood... sort of.",
			},
			{
				text = "Offer less",
				effects = { Money = -1000, Happiness = 3 },
				feedText = "You gave $1,000. It's something.",
			},
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Give generously and they prosper",
				effects = { Money = -5000, Happiness = 20 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ God Mode! Your generosity changed their life! They'll always remember.",
				setFlags = { generous_friend = true },
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
		cooldown = 2,
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
				text = "⭐ [Celebrity] Deliver a legendary speech",
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
		cooldown = 2,
		stage = STAGE,
		category = "relationships",
		tags = { "romance", "love", "partner" },
		
		eligibility = function(state)
			return state.Flags and (state.Flags.has_partner or state.Flags.married)
		end,
		
		choices = {
			{
				text = "Plan a surprise dinner",
				effects = { Money = -200, Happiness = 10 },
				feedText = "The surprise dinner was perfect! Your partner loved it.",
			},
			{
				text = "Write a heartfelt letter",
				effects = { Happiness = 8 },
				feedText = "Words from the heart. Your partner was moved to tears.",
			},
			{
				text = "Plan an expensive trip",
				effects = {},
				feedText = "Planning a getaway...",
				onResolve = function(state)
					local money = state.Money or 0
					if money >= 3000 then
						state.Money = money - 3000
						state:ModifyStat("Happiness", 20)
						state:AddFeed("💕 The trip was AMAZING! Memories for a lifetime!")
					else
						state:ModifyStat("Happiness", 8)
						state:AddFeed("💕 Stayed local but made it special. It's the thought that counts.")
					end
				end,
			},
			-- ⭐ CELEBRITY PREMIUM OPTION
			{
				text = "⭐ [Celebrity] Televised proposal/vow renewal",
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
}

return PremiumIntegratedEvents
