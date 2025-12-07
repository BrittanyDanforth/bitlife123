--[[
    Reputation & Social Standing Events
    Events about reputation, social status, and public perception
    All events use randomized outcomes - NO god mode
]]

local ReputationEvents = {}

local STAGE = "random"

ReputationEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- REPUTATION BUILDING
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "rep_word_of_mouth",
		title = "Word Gets Around",
		emoji = "🗣️",
		text = "People are talking about you!",
		question = "What are they saying?",
		minAge = 15, maxAge = 100,
		baseChance = 0.15,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "reputation",
		tags = { "reputation", "gossip", "social" },
		
		-- CRITICAL: Random reputation outcome
		choices = {
			{
				text = "Find out what they're saying",
				effects = {},
				feedText = "Learning what people think...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.good_reputation = true
						state:AddFeed("🗣️ Good things! People respect you! Reputation is gold!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🗣️ Mixed opinions. Some good, some not. That's life.")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.bad_reputation = true
						state:AddFeed("🗣️ Not good. Reputation damaged. Where did this come from?")
					end
				end,
			},
		},
	},
	{
		id = "rep_public_recognition",
		title = "Public Recognition",
		emoji = "🏅",
		text = "You're being publicly recognized!",
		question = "What are you being recognized for?",
		minAge = 15, maxAge = 100,
		baseChance = 0.1,
		cooldown = 6,
		stage = STAGE,
		ageBand = "any",
		category = "reputation",
		tags = { "recognition", "award", "honor" },
		
		choices = {
			{ text = "Community service", effects = { Happiness = 12, Smarts = 2 }, setFlags = { community_recognized = true }, feedText = "🏅 Recognized for helping others! True honor!" },
			{ text = "Professional excellence", effects = { Happiness = 12, Money = 200 }, setFlags = { professionally_recognized = true }, feedText = "🏅 Recognized for work! Career boost!" },
			{ text = "Random act praised", effects = { Happiness = 10 }, feedText = "🏅 Did something good and people noticed! Feels great!" },
			{ text = "Undeserved recognition", effects = { Happiness = 4, Smarts = 1 }, feedText = "🏅 Don't really deserve this but... won't say no." },
		},
	},
	{
		id = "rep_scandal",
		title = "Scandal Brewing",
		emoji = "😱",
		text = "You're at the center of a scandal!",
		question = "How do you handle the scandal?",
		minAge = 18, maxAge = 90,
		baseChance = 0.08,
		cooldown = 8,
		stage = STAGE,
		ageBand = "any",
		category = "reputation",
		tags = { "scandal", "crisis", "reputation" },
		
		-- CRITICAL: Random scandal outcome
		choices = {
			{
				text = "Address it head-on",
				effects = {},
				feedText = "Confronting the scandal...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.40 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("😱 Cleared your name! Truth prevailed! Reputation intact!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -4)
						state:AddFeed("😱 Damage control helped. Some believe you, some don't.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.scandal_victim = true
						state:AddFeed("😱 Couldn't recover. Reputation in ruins. Starting over.")
					end
				end,
			},
			{ text = "Stay silent", effects = { Happiness = -6 }, setFlags = { scandal_quiet = true }, feedText = "😱 Saying nothing. Hope it blows over. Anxiety high." },
			{ text = "Leave/disappear for a while", effects = { Money = -500, Happiness = -4 }, feedText = "😱 Laying low. Distance from the situation. Self-preservation." },
		},
	},
	{
		id = "rep_trust_built",
		title = "Trust Earned",
		emoji = "🤝",
		text = "You've earned someone's trust!",
		question = "How did you earn their trust?",
		minAge = 12, maxAge = 100,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "reputation",
		tags = { "trust", "reliability", "reputation" },
		
		choices = {
			{ text = "Kept your word", effects = { Happiness = 8, Smarts = 2 }, setFlags = { trustworthy = true }, feedText = "🤝 Promises kept. Trust earned. Integrity matters!" },
			{ text = "Helped in their time of need", effects = { Happiness = 10 }, feedText = "🤝 Was there for them. They'll remember this forever." },
			{ text = "Proved yourself reliable", effects = { Happiness = 7, Smarts = 2 }, feedText = "🤝 Consistent and dependable. Trust is built over time." },
		},
	},
	{
		id = "rep_trust_betrayed",
		title = "Trust Broken",
		emoji = "💔",
		text = "Someone broke your trust!",
		question = "How do you handle the betrayal?",
		minAge = 12, maxAge = 100,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "reputation",
		tags = { "betrayal", "trust", "relationships" },
		
		-- CRITICAL: Random betrayal handling
		choices = {
			{
				text = "Confront them",
				effects = {},
				feedText = "Facing the betrayer...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💔 Got an apology. Will take time but maybe can heal.")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -4)
						state:AddFeed("💔 They made excuses. No real apology. Cutting them off.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.trust_issues = true
						state:AddFeed("💔 It got ugly. Bridges burned. Hard to trust again.")
					end
				end,
			},
			{ text = "Cut them out silently", effects = { Happiness = -3 }, setFlags = { cut_someone_off = true }, feedText = "💔 No confrontation. Just gone. They'll figure it out." },
			{ text = "Forgive and move forward", effects = { Happiness = 3, Smarts = 3 }, feedText = "💔 Chose to forgive. High road. Boundaries strengthened." },
		},
	},
	{
		id = "rep_social_climb",
		title = "Social Climbing",
		emoji = "📈",
		text = "Opportunity to improve your social standing!",
		question = "Do you seize the opportunity?",
		minAge = 18, maxAge = 80,
		baseChance = 0.12,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "reputation",
		tags = { "social", "status", "opportunity" },
		
		-- CRITICAL: Random social climbing outcome
		choices = {
			{
				text = "Network and climb",
				effects = { Money = -50 },
				feedText = "Working the social scene...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.30 + ((looks + smarts) / 400)
					
					if roll < successChance then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.well_connected = true
						state:AddFeed("📈 Connected with important people! Doors opening!")
					elseif roll < (successChance * 2) then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("📈 Made some good connections. Progress!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📈 Felt out of place. Social climbing isn't for everyone.")
					end
				end,
			},
			{ text = "Stay authentic", effects = { Happiness = 4, Smarts = 2 }, feedText = "📈 Not going to fake it. Real connections only. Integrity." },
		},
	},
	{
		id = "rep_rumor_mill",
		title = "Rumor About You",
		emoji = "🤫",
		text = "There's a rumor going around about you!",
		question = "How do you handle the rumor?",
		minAge = 12, maxAge = 90,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "reputation",
		tags = { "rumor", "gossip", "reputation" },
		
		-- CRITICAL: Random rumor type and resolution
		choices = {
			{
				text = "Investigate and respond",
				effects = {},
				feedText = "Finding out what's being said...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🤫 It was actually a GOOD rumor! People impressed with you!")
					elseif roll < 0.60 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🤫 Silly rumor. Addressed it. Should blow over.")
					else
						state:ModifyStat("Happiness", -7)
						state.Flags = state.Flags or {}
						state.Flags.rumor_victim = true
						state:AddFeed("🤫 Nasty rumor. Damaging. Who started this?!")
					end
				end,
			},
			{ text = "Ignore it completely", effects = { Happiness = 1 }, feedText = "🤫 Not dignifying it with a response. Move on." },
		},
	},
	{
		id = "rep_recommendation",
		title = "Recommendation Request",
		emoji = "📜",
		text = "Someone asked you for a recommendation!",
		question = "Do you give them a good recommendation?",
		minAge = 20, maxAge = 90,
		baseChance = 0.15,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "reputation",
		tags = { "recommendation", "reference", "help" },
		
		-- CRITICAL: Random recommendation outcome
		choices = {
			{
				text = "Give honest positive recommendation",
				effects = {},
				feedText = "Writing/giving the recommendation...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("📜 They got it! Your recommendation helped! Feels good!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📜 Did your part. Hope it helps them.")
					end
				end,
			},
			{ text = "Decline politely", effects = { Happiness = -2 }, feedText = "📜 Not comfortable recommending. Said no nicely." },
			{ text = "Inflate it beyond truth", effects = { Happiness = 3 }, setFlags = { inflated_reference = true }, feedText = "📜 Embellished a bit. Hope they live up to it." },
		},
	},
	{
		id = "rep_role_model",
		title = "Becoming a Role Model",
		emoji = "⭐",
		text = "Someone looks up to you as a role model!",
		question = "How do you handle being looked up to?",
		minAge = 20, maxAge = 100,
		baseChance = 0.1,
		cooldown = 6,
		stage = STAGE,
		ageBand = "any",
		category = "reputation",
		tags = { "role_model", "influence", "responsibility" },
		
		choices = {
			{ text = "Accept the responsibility", effects = { Happiness = 8, Smarts = 3 }, setFlags = { role_model = true }, feedText = "⭐ Honored to be looked up to. Will try to be worthy." },
			{ text = "Feel pressure from it", effects = { Happiness = 2, Smarts = 2 }, feedText = "⭐ Pressure to be perfect. Hope not to disappoint them." },
			{ text = "Mentor them actively", effects = { Happiness = 10, Smarts = 4 }, setFlags = { mentor = true }, feedText = "⭐ Taking it seriously! Guiding them! Passing wisdom on!" },
		},
	},
	{
		id = "rep_jealousy_from_others",
		title = "Others Are Jealous",
		emoji = "😒",
		text = "People seem jealous of you!",
		question = "How do you handle their jealousy?",
		minAge = 12, maxAge = 90,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "reputation",
		tags = { "jealousy", "envy", "social" },
		
		-- CRITICAL: Random jealousy outcome
		choices = {
			{
				text = "Stay humble and kind",
				effects = {},
				feedText = "Being gracious about success...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("😒 Humility worked! They came around! Respect earned!")
					else
						state:ModifyStat("Happiness", 1)
						state:AddFeed("😒 Still some resentment but you took the high road.")
					end
				end,
			},
			{ text = "Let them hate", effects = { Happiness = 3 }, setFlags = { haters_gonna_hate = true }, feedText = "😒 Their problem, not yours. Success triggers some people." },
			{ text = "Feel bad about success", effects = { Happiness = -4 }, feedText = "😒 Dimming your light for others. Shouldn't have to." },
		},
	},
}

return ReputationEvents
