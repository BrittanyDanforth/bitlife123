--[[
    Relationships Expanded Events
    Deep relationship events for all life stages
    All events use randomized outcomes - NO god mode
]]

local RelationshipsExpanded = {}

local STAGE = "relationships"

RelationshipsExpanded.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- DATING & ROMANCE (Ages 16+)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "rel_meet_cute",
		title = "Meet Cute",
		emoji = "💕",
		text = "You had an adorable chance encounter with someone!",
		question = "Do you pursue this connection?",
		minAge = 16, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresSingle = true,
		stage = STAGE,
		ageBand = "any",
		category = "romance",
		tags = { "dating", "meeting", "romance" },
		
		choices = {
			{
				text = "Exchange numbers and text later",
				effects = {},
				feedText = "You got their number...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						-- AAA FIX: Check if AddRelationship exists before calling
						if state.AddRelationship then
							state:AddRelationship("Partner", "romantic", 0.65)
						else
							state.Relationships = state.Relationships or {}
							state.Relationships.partner = {
								id = "partner_" .. tostring(state.Age or 0),
								name = "Partner",
								type = "romantic",
								relationship = 65,
								alive = true,
							}
						end
						if state.AddFeed then state:AddFeed("💕 Great connection! You're dating someone new!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("💕 They never texted back. Oh well.") end
					end
				end,
			},
			{
				text = "Too shy to approach",
				effects = { Happiness = -3 },
				feedText = "What if? You'll always wonder.",
			},
			{
				text = "Strike up a conversation immediately",
				effects = {},
				feedText = "Being bold...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local successChance = 0.35 + (looks / 200)
					if roll < successChance then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 10) end
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						-- AAA FIX: Check if AddRelationship exists before calling
						if state.AddRelationship then
							state:AddRelationship("Partner", "romantic", 0.70)
						else
							state.Relationships = state.Relationships or {}
							state.Relationships.partner = {
								id = "partner_" .. tostring(state.Age or 0),
								name = "Partner",
								type = "romantic",
								relationship = 70,
								alive = true,
							}
						end
						if state.AddFeed then state:AddFeed("💕 Chemistry! You're now dating!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -3) end
						if state.AddFeed then state:AddFeed("💕 Awkward interaction. They weren't interested.") end
					end
				end,
			},
		},
	},
	{
		id = "rel_date_night_dilemma",
		title = "Date Night Dilemma",
		emoji = "🌃",
		text = "Planning a date night. Where do you go?",
		question = "Pick the perfect date activity.",
		minAge = 18, maxAge = 70,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresPartner = true,
		stage = STAGE,
		ageBand = "adult",
		category = "romance",
		tags = { "date", "relationship", "romance" },
		
		-- CRITICAL: Random date outcome
		choices = {
		{
			text = "Fancy restaurant ($150)",
			effects = { Money = -150 },
			feedText = "Dressing up for a nice dinner...",
			eligibility = function(state) return (state.Money or 0) >= 150, "💸 Need $150 for fancy dinner" end,
			onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🌃 Romantic dinner! Perfect evening together.")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🌃 Food was meh but the company was good.")
					end
				end,
			},
		{
			text = "Movie and couch cuddles ($20)",
			effects = { Money = -20, Happiness = 6 },
			feedText = "Low-key and perfect. Just being together.",
			eligibility = function(state) return (state.Money or 0) >= 20, "💸 Need $20 for movie night" end,
		},
		{
			text = "Adventure activity together ($100)",
			effects = { Money = -100 },
			feedText = "Trying something new together...",
			eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for adventure" end,
			onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Health", 2)
						state:AddFeed("🌃 Adventure bonding! Best date ever!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🌃 Fun but one of you was scared the whole time.")
					end
				end,
			},
		{
			text = "Cook dinner at home ($30)",
			effects = { Money = -30, Happiness = 7 },
			feedText = "Homemade meal and quality time. Perfect.",
			eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30 for groceries" end,
		},
		{
			text = "Free walk in the park",
			effects = { Happiness = 5, Health = 2 },
			feedText = "Simple and romantic. Just enjoying each other's company.",
		},
		},
	},
	{
		id = "rel_meeting_their_family",
		title = "Meeting The Family",
		emoji = "👨‍👩‍👧",
		text = "Time to meet your partner's family!",
		question = "How does meeting the family go?",
		minAge = 18, maxAge = 60,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresPartner = true,
		stage = STAGE,
		ageBand = "adult",
		category = "romance",
		tags = { "family", "relationship", "milestone" },
		
		-- CRITICAL: Random family meeting outcome
		choices = {
			{
				text = "Be yourself and hope for the best",
				effects = {},
				feedText = "Walking through their front door...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.family_approved = true
						state:AddFeed("👨‍👩‍👧 They LOVE you! Instant family approval!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("👨‍👩‍👧 Went okay. They need time to warm up.")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.family_disapproves = true
						state:AddFeed("👨‍👩‍👧 Oof. They didn't like you. Awkward.")
					end
				end,
			},
			{
				text = "Try too hard to impress",
				effects = {},
				feedText = "Going all out to charm them...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("👨‍👩‍👧 Your efforts paid off! They think you're great!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("👨‍👩‍👧 Came on too strong. They found you fake.")
					end
				end,
			},
			{
				text = "Be nervous and quiet",
				effects = { Happiness = 2 },
				feedText = "Hard to shine when you're anxious. Neutral impression.",
			},
		},
	},
	{
		id = "rel_anniversary",
		title = "Anniversary",
		emoji = "💑",
		text = "It's your anniversary! How do you celebrate?",
		question = "What do you do for your anniversary?",
		minAge = 18, maxAge = 80,
		baseChance = 0.555,
		cooldown = 3,
		requiresPartner = true,
		stage = STAGE,
		ageBand = "adult",
		category = "romance",
		tags = { "anniversary", "celebration", "romance" },
		
		choices = {
		{ text = "Grand romantic gesture ($500)", effects = { Money = -500, Happiness = 12 }, setFlags = { romantic = true }, feedText = "💑 Surprised them with something amazing! They cried happy tears!", eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for grand gesture" end },
		{ text = "Simple but meaningful ($50)", effects = { Money = -50, Happiness = 8 }, feedText = "💑 Quality time together. That's all that matters.", eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50" end },
		{ text = "Completely forget", effects = { Happiness = -10 }, setFlags = { forgot_anniversary = true }, feedText = "💑 Oh no. They remember. You didn't. TROUBLE." },
		{ text = "Re-create your first date ($100)", effects = { Money = -100, Happiness = 10 }, feedText = "💑 Nostalgic and romantic! They loved it!", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100" end },
		{ text = "Homemade card and cuddles", effects = { Happiness = 6 }, feedText = "💑 It's the thought that counts! Sweet and heartfelt." },
		},
	},
	{
		id = "rel_jealousy_issue",
		title = "Jealousy Flare-Up",
		emoji = "😠",
		text = "Something triggered jealousy in your relationship.",
		question = "How do you handle the jealousy?",
		minAge = 16, maxAge = 70,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresPartner = true,
		stage = STAGE,
		ageBand = "adult",
		category = "conflict",
		tags = { "jealousy", "conflict", "relationship" },
		
		choices = {
			{ text = "Talk it out calmly", effects = { Happiness = 3, Smarts = 2 }, setFlags = { healthy_communication = true }, feedText = "😠 Discussed feelings. Cleared the air. Trust restored." },
			{ text = "Let it fester into a fight", effects = { Happiness = -6 }, setFlags = { relationship_tension = true }, feedText = "😠 Blew up into a huge argument. Hurtful words said." },
			{ text = "Realize you're being unreasonable", effects = { Happiness = 2, Smarts = 2 }, feedText = "😠 Checked yourself. The jealousy wasn't warranted." },
			{ text = "Actually... there was something to worry about", effects = { Happiness = -10 }, setFlags = { trust_broken = true }, feedText = "😠 Your instincts were right. Trust shattered." },
		},
	},
	{
		id = "rel_long_distance_test",
		title = "Long Distance Challenge",
		emoji = "🌍",
		text = "Circumstances are separating you and your partner geographically.",
		question = "Can your relationship survive the distance?",
		minAge = 18, maxAge = 55,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresPartner = true,
		stage = STAGE,
		ageBand = "adult",
		category = "challenge",
		tags = { "long_distance", "challenge", "relationship" },
		
		-- CRITICAL: Random long distance outcome
		choices = {
			{
				text = "Commit to making it work",
				effects = {},
				feedText = "Video calls, texts, visits when possible...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.long_distance_success = true
						state:AddFeed("🌍 Love conquers distance! Relationship strengthened!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🌍 Struggling but still together. It's hard.")
					else
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.recently_single = true
						state:AddFeed("🌍 The distance was too much. Relationship ended.")
					end
				end,
			},
			{
				text = "End it rather than drag it out",
				effects = { Happiness = -6 },
				setFlags = { recently_single = true },
				feedText = "🌍 Clean break. Painful but probably right decision.",
			},
		},
	},
	{
		id = "rel_partner_career_vs_you",
		title = "Career vs Relationship",
		emoji = "⚖️",
		text = "Your partner got an amazing opportunity far away.",
		question = "What do you do?",
		minAge = 22, maxAge = 50,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresPartner = true,
		stage = STAGE,
		ageBand = "adult",
		category = "conflict",
		tags = { "career", "relationship", "sacrifice" },
		
		choices = {
			{ text = "Support them - go together ($500)", effects = { Happiness = 4, Money = -500 }, setFlags = { moved_for_partner = true }, feedText = "⚖️ Your turn to support their dreams. New adventure together!", eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 to relocate" end },
			{ text = "Ask them not to go", effects = {}, feedText = "You ask them to stay...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("⚖️ They chose you! Turned down the opportunity!")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.partner_resents = true
						state:AddFeed("⚖️ They stayed but resent the sacrifice.")
					end
				end,
			},
			{ text = "Break up - let them go", effects = { Happiness = -8 }, setFlags = { recently_single = true }, feedText = "⚖️ You loved them enough to let them go." },
			{ text = "Try long distance", effects = { Happiness = -2 }, setFlags = { long_distance = true }, feedText = "⚖️ Going to try to make it work across the miles." },
		},
	},
	{
		id = "rel_proposal_moment",
		title = "The Big Question",
		emoji = "💍",
		text = "It's time to pop the question!",
		question = "How do you propose?",
		minAge = 20, maxAge = 60,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresPartner = true,
		blockedByFlags = { engaged = true, married = true },
		stage = STAGE,
		ageBand = "adult",
		category = "milestone",
		tags = { "proposal", "engagement", "romance" },
		
		eligibility = function(state)
			-- CRITICAL FIX: Lowered to $0 - free proposal option now exists!
			-- Can't propose from prison!
			if state.Flags and (state.Flags.in_prison or state.Flags.incarcerated) then
				return false, "Can't propose from prison"
			end
			return true
		end,
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		-- CRITICAL: Random proposal outcome
		choices = {
			{
				text = "Grand public proposal ($2,000)",
				effects = { Money = -2000 },
				feedText = "Getting down on one knee in front of everyone...",
				eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Need $2,000 for grand proposal" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.75 then
						state:ModifyStat("Happiness", 20)
						state.Flags = state.Flags or {}
						state.Flags.engaged = true
						state:AddFeed("💍 THEY SAID YES! Crowd went wild! You're engaged!")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.engaged = true
						state:AddFeed("💍 Yes! But they wished it was more private.")
					else
						state:ModifyStat("Happiness", -20)
						state.Flags = state.Flags or {}
						state.Flags.recently_single = true
						state:AddFeed("💍 They said no. In public. Devastating humiliation.")
					end
				end,
			},
			{
				text = "Intimate private proposal ($1,000)",
				effects = { Money = -1000 },
				feedText = "Just the two of you, somewhere special...",
				eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Need $1,000 for ring and setup" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.85 then
						state:ModifyStat("Happiness", 18)
						state.Flags = state.Flags or {}
						state.Flags.engaged = true
						state:AddFeed("💍 Perfect moment. They said YES! You're engaged!")
					else
						state:ModifyStat("Happiness", -15)
						state:AddFeed("💍 They said they're not ready. Not a no, but not a yes.")
					end
				end,
			},
			{
				text = "Simple heartfelt proposal ($100)",
				effects = { Money = -100 },
				feedText = "No fancy ring needed - just your words...",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for a simple ring" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.80 then
						state:ModifyStat("Happiness", 16)
						state.Flags = state.Flags or {}
						state.Flags.engaged = true
						state:AddFeed("💍 They said YES! The ring doesn't matter - love does!")
					else
						state:ModifyStat("Happiness", -10)
						state:AddFeed("💍 They said they need time to think...")
					end
				end,
			},
			-- CRITICAL FIX: FREE OPTION to prevent hard lock!
			{
				text = "Just speak from the heart",
				effects = {},
				feedText = "Proposing with just your heart...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 14)
						state.Flags = state.Flags or {}
						state.Flags.engaged = true
						state:AddFeed("💍 They said YES! 'I don't need a ring - I need YOU!'")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.engaged = true
						state:AddFeed("💍 Yes! But they'd like a ring when you can afford one.")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("💍 They were hurt you didn't even get a ring. Things are awkward.")
					end
				end,
			},
		},
	},
	{
		id = "rel_wedding_planning_stress",
		title = "Wedding Planning Stress",
		emoji = "📋",
		text = "Wedding planning is causing major stress!",
		question = "How do you handle wedding planning?",
		minAge = 20, maxAge = 55,
		baseChance = 0.4,
		cooldown = 3,
		requiresPartner = true,
		requiresFlags = { engaged = true },
		stage = STAGE,
		ageBand = "adult",
		category = "planning",
		tags = { "wedding", "stress", "planning" },
		
		choices = {
		{ text = "Bridezilla/Groomzilla mode ($1,000)", effects = { Happiness = -5, Money = -1000 }, setFlags = { wedding_drama = true }, feedText = "📋 This wedding WILL be perfect. Everyone is terrified of you.", eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Need $1,000" end },
		{ text = "Stay calm and delegate ($500)", effects = { Happiness = 2, Money = -500 }, feedText = "📋 Wedding planner, family help. Manageable.", eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500" end },
		{ text = "Elope instead ($200)", effects = { Happiness = 8, Money = -200 }, setFlags = { eloped = true, married = true }, feedText = "📋 Forget all this! Just the two of you! MARRIED!", eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200" end },
		{ text = "Push through together ($700)", effects = { Happiness = 4, Money = -700 }, feedText = "📋 Stressful but you're doing it as a team. That matters.", eligibility = function(state) return (state.Money or 0) >= 700, "💸 Need $700" end },
		{ text = "Courthouse wedding", effects = { Happiness = 5 }, setFlags = { courthouse_wedding = true, married = true }, feedText = "📋 Just you, a judge, and your love. Simple and beautiful." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FRIENDSHIP EVENTS (All Ages)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "rel_friend_in_need",
		title = "Friend In Need",
		emoji = "🆘",
		text = "A close friend is going through something difficult.",
		question = "How do you support them?",
		minAge = 12, maxAge = 90,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "friendship",
		tags = { "friend", "support", "help" },
		
		choices = {
			{ text = "Drop everything to be there", effects = { Happiness = 5, Smarts = 1 }, setFlags = { loyal_friend = true }, feedText = "🆘 You showed up. That's what matters most." },
			{ text = "Help from a distance - check in", effects = { Happiness = 2 }, feedText = "🆘 Texts and calls. Support without overwhelming." },
			{ text = "Offer financial help ($200)", effects = { Money = -200, Happiness = 4 }, feedText = "🆘 Put your money where your mouth is. They're grateful.", eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 to help" end },
			{ text = "Too caught up in own life", effects = { Happiness = -4 }, setFlags = { bad_friend_moment = true }, feedText = "🆘 Wasn't there for them. The guilt lingers." },
		},
	},
	{
		id = "rel_friend_betrayal",
		title = "Friend Betrayal",
		emoji = "🔪",
		text = "A friend did something that deeply hurt you.",
		question = "How do you handle the betrayal?",
		minAge = 13, maxAge = 80,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "conflict",
		tags = { "betrayal", "friend", "conflict" },
		
		choices = {
			{ text = "Confront them directly", effects = {}, feedText = "Demanding an explanation...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🔪 They apologized sincerely. Friendship saved.")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🔪 Made it worse. No apology. Friendship over.")
					end
				end,
			},
			{ text = "Cut them off completely", effects = { Happiness = -4 }, setFlags = { ended_friendship = true }, feedText = "🔪 Done. No second chances. They're dead to you." },
			{ text = "Forgive but don't forget", effects = { Happiness = 2, Smarts = 2 }, feedText = "🔪 Moving forward but trust is damaged forever." },
			{ text = "Revenge", effects = { Happiness = 2 }, setFlags = { vengeful = true }, feedText = "🔪 Got them back. Petty? Yes. Satisfying? Also yes." },
		},
	},
	{
		id = "rel_making_new_friends",
		title = "Making New Friends",
		emoji = "👋",
		text = "You're trying to make new friends!",
		question = "How do you try to make friends?",
		minAge = 15, maxAge = 80,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "friendship",
		tags = { "friends", "social", "meeting" },
		
		-- CRITICAL: Random friend-making outcome
		choices = {
		{
			text = "Join clubs or activities ($50)",
			effects = { Money = -50 },
			feedText = "Putting yourself out there...",
			eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 for club dues" end,
			onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.has_close_friend = true
						state:AddFeed("👋 Made real connections! New friend group!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("👋 Met some people. Nothing clicked yet.")
					end
				end,
			},
			{
				text = "Through apps/online communities",
				effects = {},
				feedText = "Connecting digitally...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.has_online_friends = true
						state:AddFeed("👋 Found your people online! Great community!")
					else
						state:ModifyStat("Happiness", 1)
						state:AddFeed("👋 Some acquaintances but no deep connections.")
					end
				end,
			},
			{
				text = "Through work/school",
				effects = { Happiness = 5 },
				setFlags = { work_friends = true },
				feedText = "👋 Coworkers/classmates became real friends!",
			},
			{
				text = "Stick with existing friends",
				effects = { Happiness = 2 },
				feedText = "👋 Quality over quantity. Keep the friends you have.",
			},
		},
	},
	{
		id = "rel_friend_group_dynamics",
		title = "Friend Group Drama",
		emoji = "👥",
		text = "There's tension in your friend group.",
		question = "How do you handle the group dynamics?",
		minAge = 13, maxAge = 60,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "conflict",
		tags = { "friends", "drama", "conflict" },
		
		choices = {
			{ text = "Stay neutral - don't pick sides", effects = { Happiness = 1, Smarts = 2 }, setFlags = { peacekeeper = true }, feedText = "👥 Switzerland strategy. Friends with everyone." },
			{ text = "Try to mediate", effects = {}, feedText = "Playing peacemaker...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("👥 Resolved the conflict! Group intact!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("👥 Made it about you somehow. Both sides mad now.")
					end
				end,
			},
			{ text = "Pick a side", effects = { Happiness = -3 }, setFlags = { picked_sides = true }, feedText = "👥 Chose your people. Lost some friends." },
			{ text = "Distance yourself from all of it", effects = { Happiness = -2 }, feedText = "👥 Stepping back. The drama is exhausting." },
		},
	},
	{
		id = "rel_losing_touch",
		title = "Losing Touch",
		emoji = "📵",
		text = "You've been losing touch with old friends.",
		question = "Do you try to reconnect?",
		minAge = 20, maxAge = 80,
		baseChance = 0.555,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "friendship",
		tags = { "friends", "reconnection", "loss" },
		
		choices = {
			{
				text = "Reach out and reconnect",
				effects = {},
				feedText = "Sending that long-overdue message...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.rekindled_friendship = true
						state:AddFeed("📵 Like no time passed! Friendship rekindled!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📵 Nice chat but you've both changed. Different people now.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📵 Left on read. Some friendships just end.")
					end
				end,
			},
			{
				text = "Let it fade naturally",
				effects = { Happiness = -2 },
				feedText = "📵 People grow apart. That's life.",
			},
		{
			text = "Plan a reunion ($100)",
			effects = { Money = -100 },
			feedText = "Getting the old gang together...",
			eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for reunion" end,
			onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Happiness", 12)
						state:AddFeed("📵 AMAZING reunion! Old memories and new laughs!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📵 Awkward. You've all changed. Nothing in common anymore.")
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FAMILY RELATIONSHIPS (All Ages)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "rel_parent_approval_struggle",
		title = "Parent Approval",
		emoji = "👨‍👩‍👧",
		text = "Seeking approval from your parents feels impossible.",
		question = "How do you handle wanting parental approval?",
		minAge = 15, maxAge = 50,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "family",
		tags = { "parents", "approval", "struggle" },
		
		choices = {
			{ text = "Live your life regardless", effects = { Happiness = 4, Smarts = 2 }, setFlags = { independent_of_parents = true }, feedText = "👨‍👩‍👧 You don't need their approval to be valid." },
			{ text = "Keep trying to please them", effects = { Happiness = -4 }, setFlags = { seeking_approval = true }, feedText = "👨‍👩‍👧 Never good enough. Always trying." },
			{ text = "Have an honest conversation", effects = {}, feedText = "Opening up about how you feel...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("👨‍👩‍👧 They finally understood! Relationship improved!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("👨‍👩‍👧 They didn't get it. Same as always.")
					end
				end,
			},
			{ text = "Accept they may never change", effects = { Happiness = 2, Smarts = 3 }, setFlags = { accepted_parent_limits = true }, feedText = "👨‍👩‍👧 Stopped expecting change. Peace in acceptance." },
		},
	},
	{
		id = "rel_sibling_rivalry_adult",
		title = "Adult Sibling Rivalry",
		emoji = "⚔️",
		text = "Competition with your sibling continues into adulthood.",
		question = "How do you handle sibling rivalry now?",
		minAge = 22, maxAge = 60,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "sibling", "rivalry", "family" },
		-- CRITICAL FIX: Sibling rivalry requires having siblings!
		requiresFlags = { has_siblings = true },
		
		choices = {
			{ text = "Let it go - life's too short", effects = { Happiness = 5, Smarts = 2 }, setFlags = { sibling_peace = true }, feedText = "⚔️ Stopped competing. You're on the same team." },
			{ text = "Win at all costs", effects = { Happiness = -3, Money = 200 }, setFlags = { competitive_sibling = true }, feedText = "⚔️ WINNING. But at what cost? Relationship strained." },
			{ text = "Celebrate their success", effects = { Happiness = 4 }, feedText = "⚔️ Their win isn't your loss. Supportive sibling." },
			{ text = "Avoid them entirely", effects = { Happiness = -2 }, setFlags = { estranged_sibling = true }, feedText = "⚔️ Easier to not engage. Distance grows." },
		},
	},
	{
		id = "rel_family_gathering",
		title = "Family Gathering",
		emoji = "🍽️",
		text = "It's time for a big family gathering!",
		question = "How does the family gathering go?",
		minAge = 8, maxAge = 90,
		baseChance = 0.555,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "family",
		tags = { "family", "gathering", "holiday" },
		
		-- CRITICAL: Random gathering outcome
		choices = {
			{
				text = "Enjoy the chaos",
				effects = {},
				feedText = "All the relatives in one place...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🍽️ Great time! Good food, good stories, feeling loved!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🍽️ The usual mix. Some drama but mostly fine.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🍽️ Uncle started political arguments. It went downhill fast.")
					end
				end,
			},
			{
				text = "Hide from the awkward relatives",
				effects = { Happiness = 2 },
				feedText = "🍽️ Strategic bathroom breaks and phone checking. Survived.",
			},
			{
				text = "Skip it entirely",
				effects = { Happiness = -1 },
				feedText = "🍽️ Stayed home. FOMO and guilt but also... peace.",
			},
		},
	},
	{
		id = "rel_family_secret_revealed",
		title = "Family Secret",
		emoji = "🤫",
		text = "A major family secret has been revealed!",
		question = "What secret was uncovered?",
		minAge = 16, maxAge = 90,
		baseChance = 0.1,
		cooldown = 4,
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "family",
		tags = { "secret", "family", "revelation" },
		
		choices = {
			{ text = "Hidden sibling exists", effects = { Happiness = -5, Smarts = 2 }, setFlags = { secret_sibling = true }, feedText = "🤫 You have a half-brother/sister. Mind blown." },
			{ text = "Parent had affair years ago", effects = { Happiness = -8 }, setFlags = { parent_affair = true }, feedText = "🤫 The family was built on a lie. Processing this." },
			{ text = "Family wealth secret", effects = { Happiness = 3, Money = 500 }, feedText = "🤫 There's money in the family nobody talked about!" },
			{ text = "Criminal history in family", effects = { Happiness = -4, Smarts = 2 }, setFlags = { family_criminal_past = true }, feedText = "🤫 Grandpa wasn't always a baker... he was a smuggler." },
		},
	},
	{
		id = "rel_caring_for_aging_parent",
		title = "Caring for Parents",
		emoji = "👴",
		text = "Your parents need more care and support.",
		question = "How do you approach caregiving?",
		minAge = 35, maxAge = 70,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "parents", "caregiving", "aging" },
		
		-- CRITICAL FIX: Only show if parents are still alive!
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Check if parents are dead
			if flags.parents_dead or flags.both_parents_dead then
				return false
			end
			-- Check if mother and father are both dead
			if flags.mother_dead and flags.father_dead then
				return false
			end
			-- At least one parent should be alive
			-- Also check Relationships for parent status
			-- CRITICAL FIX: Use pairs() not ipairs() - Relationships is a dictionary not array!
			if state.Relationships then
				local hasLivingParent = false
				for _, rel in pairs(state.Relationships) do
					if type(rel) == "table" and (rel.type == "parent" or rel.role == "Parent" or rel.role == "Mother" or rel.role == "Father")
					   and not rel.deceased and not rel.dead then
						hasLivingParent = true
						break
					end
				end
				-- If we have relationship data but no living parents, don't show event
				if not hasLivingParent then
					-- Only block if we actually have parent data (player is old enough)
					local parentCount = 0
					for _, rel in pairs(state.Relationships) do
						if type(rel) == "table" and (rel.type == "parent" or rel.role == "Parent" or rel.role == "Mother" or rel.role == "Father") then
							parentCount = parentCount + 1
						end
					end
					if parentCount > 0 then
						return false
					end
				end
			end
			return true
		end,
		
		choices = {
		{ text = "Move them in with you ($200)", effects = { Happiness = 3, Money = -200, Health = -2 }, setFlags = { live_in_caregiver = true }, feedText = "👴 They live with you now. Hard but right.", eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for setup" end },
		{ text = "Hire professional help ($500)", effects = { Money = -500, Happiness = 2 }, setFlags = { hired_caregiver = true }, feedText = "👴 Professional care. Expensive but quality.", eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for caregiver" end },
			{ text = "Share duties with siblings", effects = { Happiness = 2 }, feedText = "👴 Family teamwork. Splitting the responsibility." },
			{ text = "Struggling to balance everything", effects = { Happiness = -5, Health = -3 }, setFlags = { caregiver_burnout = true }, feedText = "👴 It's overwhelming. Your own life suffers." },
		},
	},
	{
		id = "rel_inheritance_family_drama",
		title = "Inheritance Drama",
		emoji = "💰",
		text = "A family member passed and left an inheritance.",
		question = "What happens with the inheritance?",
		minAge = 25, maxAge = 80,
		baseChance = 0.1,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "inheritance", "money", "family" },
		
		-- CRITICAL: Random inheritance situation
		choices = {
			{
				text = "Wait for the will reading",
				effects = {},
				feedText = "Finding out what you receive...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						local inheritance = math.random(5000, 20000)
						state.Money = (state.Money or 0) + inheritance
						state:ModifyStat("Happiness", 5)
						state:AddFeed(string.format("💰 Received $%d! Unexpected blessing.", inheritance))
					elseif roll < 0.55 then
						local inheritance = math.random(1000, 5000)
						state.Money = (state.Money or 0) + inheritance
						state:ModifyStat("Happiness", 3)
						state:AddFeed(string.format("💰 Modest inheritance of $%d. Grateful.", inheritance))
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", -2)
						state:AddFeed("💰 Nothing for you. Others got everything.")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.family_inheritance_fight = true
						state:AddFeed("💰 Family fighting over the estate. Ugly.")
					end
				end,
			},
			{
				text = "Don't want to be involved in money talk",
				effects = { Happiness = 1 },
				feedText = "💰 Staying out of it. Not worth family drama.",
			},
		},
	},
	{
		id = "rel_empty_nest",
		title = "Empty Nest",
		emoji = "🏠",
		text = "Your kids have all moved out.",
		question = "How do you handle the empty nest?",
		minAge = 45, maxAge = 70,
		oneTime = true,
		-- CRITICAL FIX: Must have children for empty nest event!
		-- Changed to has_child which is what child events actually set
		requiresFlags = { has_child = true },
		blockedByFlags = { no_children = true, childfree = true },
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "children", "empty_nest", "transition" },
		
		-- CRITICAL FIX: Also check eligibility function for child count
		eligibility = function(state)
			local flags = state.Flags or {}
			if not (flags.has_children or flags.has_child or flags.parent) then
				return false, "Need children for this event"
			end
			return true
		end,
		
		choices = {
			{ text = "Embrace the freedom", effects = { Happiness = 8, Money = 200 }, setFlags = { enjoying_empty_nest = true }, feedText = "🏠 FREEDOM! Quiet house! Do whatever you want! Travel!" },
			{ text = "Devastated - miss them terribly", effects = { Happiness = -8 }, setFlags = { empty_nest_sad = true }, feedText = "🏠 The house feels so empty. Purpose feels lost." },
			{ text = "Rediscover your relationship", effects = { Happiness = 6 }, setFlags = { rekindled_partnership = true }, feedText = "🏠 It's like dating again! Just the two of you!" },
			{ text = "Fill time with new hobbies", effects = { Happiness = 5, Smarts = 3 }, setFlags = { new_chapter = true }, feedText = "🏠 New hobbies, classes, activities! Reinvention!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SOCIAL DYNAMICS (All Ages)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "rel_toxic_person",
		title = "Toxic Person",
		emoji = "☠️",
		text = "Someone in your life is incredibly toxic.",
		question = "How do you deal with the toxic person?",
		minAge = 15, maxAge = 80,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "conflict",
		tags = { "toxic", "boundaries", "conflict" },
		
		choices = {
			{ text = "Cut them out completely", effects = { Happiness = 6, Smarts = 2 }, setFlags = { cut_toxic_person = true }, feedText = "☠️ No contact. Life improved immediately." },
			{ text = "Set firm boundaries", effects = { Happiness = 4, Smarts = 3 }, setFlags = { good_boundaries = true }, feedText = "☠️ Limited interaction. Boundaries protected you." },
			{ text = "Keep giving chances", effects = { Happiness = -6 }, setFlags = { doormat = true }, feedText = "☠️ They keep hurting you. Why do you allow it?" },
			{ text = "Try to fix them", effects = { Happiness = -4, Health = -2 }, setFlags = { fixer_complex = true }, feedText = "☠️ You can't save people who don't want saving." },
		},
	},
	{
		id = "rel_social_comparison",
		title = "Social Comparison",
		emoji = "📱",
		text = "Everyone on social media seems to have better lives.",
		question = "How do you handle social comparison?",
		minAge = 13, maxAge = 50,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "psychology",
		tags = { "social_media", "comparison", "self_esteem" },
		
		choices = {
			{ text = "Remember it's curated highlights", effects = { Happiness = 3, Smarts = 3 }, setFlags = { social_media_aware = true }, feedText = "📱 Their struggles aren't posted. Reality check." },
			{ text = "Take a social media break", effects = { Happiness = 5, Health = 2 }, setFlags = { social_detox = true }, feedText = "📱 Unplugged. So much mental peace!" },
			{ text = "Fall into comparison trap", effects = { Happiness = -6, Looks = -2 }, setFlags = { comparison_trap = true }, feedText = "📱 Everyone is doing better. Why can't you?" },
			{ text = "Use it as motivation", effects = { Happiness = 2, Smarts = 2 }, feedText = "📱 Let it inspire, not depress. Healthy mindset." },
		},
	},
	{
		id = "rel_loneliness_epidemic",
		title = "Feeling Lonely",
		emoji = "😔",
		text = "Despite being around people, you feel deeply lonely.",
		question = "How do you combat loneliness?",
		minAge = 18, maxAge = 90,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "psychology",
		tags = { "loneliness", "mental_health", "connection" },
		
		choices = {
			{
				text = "Actively seek connection",
				effects = {},
				feedText = "Reaching out...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("😔 Found genuine connection! The loneliness lifted!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("😔 Tried but it didn't click. Still searching.")
					end
				end,
			},
			{ text = "Join support group", effects = { Happiness = 5, Smarts = 2 }, setFlags = { support_group = true }, feedText = "😔 Others feel it too. You're not alone in being alone." },
			{ text = "Get a pet ($200)", effects = { Happiness = 7, Money = -200 }, setFlags = { has_pet = true }, feedText = "😔 Unconditional love. A furry friend helped!", eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for pet" end },
			{ text = "Isolate further", effects = { Happiness = -8, Health = -3 }, setFlags = { chronic_loneliness = true }, feedText = "😔 Withdrew more. Spiraling. Need help." },
		},
	},
	{
		id = "rel_reputation_management",
		title = "Reputation at Stake",
		emoji = "🗣️",
		text = "People are talking about you - and not positively.",
		question = "How do you handle your reputation being challenged?",
		minAge = 14, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "social",
		tags = { "reputation", "gossip", "social" },
		
		choices = {
			{ text = "Address it head-on", effects = {}, feedText = "Confronting the situation...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🗣️ Set the record straight. Truth won out.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🗣️ Made a bigger scene. More people involved now.")
					end
				end,
			},
			{ text = "Rise above - don't engage", effects = { Happiness = 2, Smarts = 3 }, feedText = "🗣️ Let them talk. Your life speaks for itself." },
			{ text = "Let it destroy you internally", effects = { Happiness = -8 }, setFlags = { reputation_damaged = true }, feedText = "🗣️ Can't stop thinking about what they say." },
			{ text = "Fight fire with fire", effects = { Happiness = -2 }, setFlags = { gossiper = true }, feedText = "🗣️ Spread some of your own. War escalated." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #205-210: MEET ROYALTY EVENTS
	-- These events allow commoners to meet and potentially marry royalty
	-- Like a fairy tale - meeting a prince or princess!
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "rel_meet_royalty_chance",
		title = "👑 Royal Encounter!",
		emoji = "👑",
		text = "Through an incredible twist of fate, you've caught the eye of a REAL prince/princess from a foreign kingdom! They seem genuinely interested in you.",
		question = "This is like a fairy tale! What do you do?",
		minAge = 18, maxAge = 40,
		baseChance = 0.008, -- Very rare! 0.8% chance
		cooldown = 4,
		requiresSingle = true,
		stage = STAGE,
		ageBand = "adult",
		category = "romance",
		tags = { "royalty", "fairy_tale", "romance", "prince", "princess" },
		weight = 5,
		
		-- CRITICAL: This is the fairy tale event!
		choices = {
			{
				text = "💕 Try to charm them (be yourself)",
				effects = {},
				feedText = "Taking a chance at a royal romance...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.25 + (looks / 250) + (smarts / 500)
					
					if roll < successChance then
						state:ModifyStat("Happiness", 20)
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						state.Flags.dating_royalty = true
						state.Flags.royal_romance = true
						state.Money = (state.Money or 0) + 50000 -- Royal gifts!
						
						-- Create royal partner relationship
						local royalTitles = {"Prince", "Princess"}
						local royalCountries = {"Monaco", "Sweden", "Denmark", "Netherlands", "Belgium"}
						local royalNames_male = {"Alexander", "William", "Henrik", "Frederik", "Carl", "Philippe"}
						local royalNames_female = {"Victoria", "Madeleine", "Mary", "Maxima", "Elisabeth", "Charlotte"}
						
						-- CRITICAL FIX: Normalize gender to lowercase for case-insensitive comparison
						local playerGender = (state.Gender or "male"):lower()
						local partnerGender = (playerGender == "female") and "male" or "female"
						local title = partnerGender == "male" and "Prince" or "Princess"
						local names = partnerGender == "male" and royalNames_male or royalNames_female
						local country = royalCountries[math.random(1, #royalCountries)]
						local name = names[math.random(1, #names)]
						
						state.Relationships = state.Relationships or {}
						state.Relationships.partner = {
							id = "royal_partner",
							name = title .. " " .. name .. " of " .. country,
							type = "romantic",
							role = "Royal Partner",
							relationship = 75,
							gender = partnerGender,
							age = (state.Age or 25) + math.random(-5, 5),
							alive = true,
							metAge = state.Age,
							isRoyalty = true,
							royalCountry = country,
							royalTitle = title,
						}
						
						state:AddFeed("👑💕 FAIRY TALE ROMANCE! You're dating " .. title .. " " .. name .. " of " .. country .. "! The world is watching your love story!")
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("👑 They were charming, but the connection didn't spark. Still, what an experience!")
					end
				end,
			},
			{
				text = "🙈 Be too intimidated to approach",
				effects = { Happiness = -5 },
				feedText = "👑 You froze up. The chance passed. What could have been...",
			},
			{
				text = "📸 Just ask for a photo",
				effects = { Happiness = 8 },
				feedText = "👑 Got a royal selfie! You'll treasure this memory.",
				setFlags = { met_royalty = true },
			},
		},
	},
	{
		id = "rel_royal_proposal",
		title = "👑💍 Royal Proposal!",
		emoji = "👑",
		text = "Your royal partner is proposing! They want to marry you and make you part of the royal family! This is a life-changing moment!",
		question = "Will you become royalty through marriage?",
		minAge = 20, maxAge = 50,
		baseChance = 0.8, -- High chance if you have the flags
		cooldown = 40, -- One-time event
		oneTime = true,
		maxOccurrences = 1,
		requiresFlags = { dating_royalty = true, royal_romance = true },
		stage = STAGE,
		ageBand = "adult",
		category = "romance",
		tags = { "royalty", "proposal", "wedding", "fairy_tale" },
		priority = "high",
		
		choices = {
			{
				text = "💍 YES! Become royalty!",
				effects = { Happiness = 30 },
				setFlags = { engaged = true, engaged_to_royalty = true, married_into_royalty = true },
				feedText = "Planning the royal wedding...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.is_royalty = true -- Become royalty through marriage!
					state.Flags.royal_by_marriage = true
					state.Flags.married = true
					state.Flags.engaged = nil
					state.Flags.dating_royalty = nil
					
					-- Massive wealth boost from marrying royalty
					state.Money = (state.Money or 0) + 10000000
					
					-- Initialize royal state
					state.RoyalState = state.RoyalState or {}
					state.RoyalState.isRoyal = true
					state.RoyalState.isMonarch = false
					state.RoyalState.marriedIntoRoyalty = true
					state.RoyalState.popularity = 70
					state.RoyalState.lineOfSuccession = 99 -- Not in direct succession
					
					local partner = state.Relationships and state.Relationships.partner
					if partner then
						partner.role = "Royal Spouse"
						state.RoyalState.country = partner.royalCountry or "Monaco"
						state.RoyalState.countryName = partner.royalCountry or "Monaco"
						-- CRITICAL FIX: Normalize gender to lowercase for case-insensitive comparison
						local playerGender = (state.Gender or "male"):lower()
						state.RoyalState.title = (playerGender == "male") and "Prince Consort" or "Princess Consort"
					end
					
					state.Fame = math.min(100, (state.Fame or 0) + 50)
					
					state:AddFeed("👑💒 ROYAL WEDDING! You married into royalty! You are now " .. (state.RoyalState.title or "Royal") .. "! Your life will never be the same!")
				end,
			},
			{
				text = "❤️ Yes, but keep it private",
				effects = { Happiness = 25 },
				setFlags = { married = true, married_into_royalty = true, private_royal_wedding = true },
				feedText = "A quiet royal wedding...",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.is_royalty = true
					state.Flags.royal_by_marriage = true
					state.Flags.dating_royalty = nil
					state.Money = (state.Money or 0) + 5000000
					
					state.RoyalState = state.RoyalState or {}
					state.RoyalState.isRoyal = true
					state.RoyalState.marriedIntoRoyalty = true
					state.RoyalState.popularity = 60
					
					local partner = state.Relationships and state.Relationships.partner
					if partner then
						partner.role = "Royal Spouse"
					end
					
					state:AddFeed("👑💒 Private royal wedding! You married into royalty discreetly. A fairytale with privacy.")
				end,
			},
			{
				text = "💔 I can't handle that life... (decline)",
				effects = { Happiness = -15 },
				setFlags = { rejected_royalty = true, recently_single = true },
				feedText = "👑 The pressure of royal life was too much. You turned down the fairy tale...",
			},
		},
	},
	{
		id = "rel_royal_life_adjustment",
		title = "👑 Royal Life Adjustment",
		emoji = "👑",
		text = "Life as a royal spouse is challenging. The media scrutinizes everything, protocols are strict, and privacy is a dream.",
		question = "How do you handle royal life?",
		minAge = 20, maxAge = 70,
		baseChance = 0.6,
		cooldown = 3,
		requiresFlags = { married_into_royalty = true },
		stage = STAGE,
		ageBand = "adult",
		category = "royalty",
		tags = { "royalty", "adjustment", "celebrity" },
		
		choices = {
			{
				text = "Embrace it - become a beloved royal",
				effects = { Happiness = 10 },
				feedText = "Embracing royal duties...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state.Fame = math.min(100, (state.Fame or 0) + 15)
						if state.RoyalState then
							state.RoyalState.popularity = math.min(100, (state.RoyalState.popularity or 50) + 20)
						end
						state:ModifyStat("Happiness", 8)
						state:AddFeed("👑 You're a natural! The public adores you!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("👑 It's harder than it looks. Royal life is exhausting.")
					end
				end,
			},
			{
				text = "Focus on charity work",
				effects = { Happiness = 12 },
				setFlags = { royal_charity_focus = true },
				feedText = "👑 You found purpose in helping others through your platform!",
				onResolve = function(state)
					if state.RoyalState then
						state.RoyalState.popularity = math.min(100, (state.RoyalState.popularity or 50) + 15)
						state.RoyalState.charitiesPatronized = state.RoyalState.charitiesPatronized or {}
						table.insert(state.RoyalState.charitiesPatronized, "Mental Health Foundation")
					end
				end,
			},
			{
				text = "Struggle with the scrutiny",
				effects = { Happiness = -10, Health = -5 },
				setFlags = { royal_struggle = true },
				feedText = "👑 The constant attention is overwhelming. This isn't the fairy tale you imagined.",
			},
		},
	},
	{
		id = "rel_celebrity_party_royal",
		title = "🎉 Exclusive Gala Invite",
		emoji = "🎉",
		text = "You've been invited to an exclusive charity gala attended by celebrities and... actual royalty! A prince/princess might be there!",
		question = "This is your chance to meet royalty!",
		minAge = 21, maxAge = 45,
		baseChance = 0.03, -- 3% chance per year
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresSingle = true,
		stage = STAGE,
		ageBand = "adult",
		category = "romance",
		tags = { "royalty", "gala", "romance", "celebrity" },
		
		-- Requirements: Need some wealth or fame
		eligibility = function(state)
			local money = state.Money or 0
			local fame = state.Fame or 0
			return money >= 100000 or fame >= 30
		end,
		
		choices = {
			{
				text = "💃 Attend and try to mingle with royalty ($5,000 gala ticket)",
				effects = { Money = -5000 }, -- Gala ticket and outfit
				feedText = "Heading to the gala...",
				-- CRITICAL FIX #2: Add eligibility check for gala ticket!
				eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Can't afford gala ticket ($5,000 needed)" end,
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local fame = state.Fame or 0
					local roll = math.random()
					local meetChance = 0.15 + (looks / 300) + (fame / 300)
					
					if roll < meetChance then
						-- Met royalty!
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.met_royalty_at_gala = true
						
						local anotherRoll = math.random()
						if anotherRoll < 0.4 then
							-- Romantic connection!
							state.Flags.has_partner = true
							state.Flags.dating_royalty = true
							state.Flags.royal_romance = true
							
							local royalNames = {"Prince Henrik", "Princess Madeleine", "Prince Joachim", "Princess Beatrice"}
							local chosenName = royalNames[math.random(1, #royalNames)]
							
							state.Relationships = state.Relationships or {}
							state.Relationships.partner = {
								id = "royal_partner",
								name = chosenName,
								type = "romantic",
								role = "Royal Partner",
								relationship = 65,
								gender = chosenName:find("Princess") and "female" or "male",
								age = (state.Age or 30) + math.random(-7, 7),
								alive = true,
								isRoyalty = true,
							}
							
							state:AddFeed("🎉👑💕 INCREDIBLE! You hit it off with " .. chosenName .. "! They asked for your number!")
						else
							state:AddFeed("🎉👑 You spoke with actual royalty! They were charming but no romantic spark.")
						end
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎉 Great gala! Didn't meet royalty, but made valuable connections.")
					end
				end,
			},
			{
				text = "🍾 Just enjoy the party ($5,000 gala ticket)",
				effects = { Money = -5000, Happiness = 8 },
				feedText = "🎉 Amazing night! Great food, music, and people!",
				-- CRITICAL FIX #3: Add eligibility check for gala ticket!
				eligibility = function(state) return (state.Money or 0) >= 5000, "💸 Can't afford gala ticket ($5,000 needed)" end,
			},
		{
			text = "Skip it - too fancy for me",
			effects = { Happiness = -2 },
			feedText = "🎉 Stayed home. Was it a missed opportunity?",
		},
	},
},

-- ══════════════════════════════════════════════════════════════════════════════
-- DYNAMIC FRIEND EVENTS - Events that react to past friendship choices
-- User requested: "FRIEND WISE LIKE JUST LIFE WISE HUGELY EXPANDED"
-- These are NOT hardcoded - they use eligibility functions to react to player state
-- ══════════════════════════════════════════════════════════════════════════════

{
	id = "rel_friend_remembers",
	title = "A Friend Reaches Out",
	emoji = "📱",
	text = "An old friend you haven't talked to in a while sends you a message.",
	question = "What do they want?",
	minAge = 18, maxAge = 80,
	baseChance = 0.45,
	cooldown = 4,
	stage = STAGE,
	ageBand = "adult",
	category = "relationships",
	tags = { "friend", "reconnect", "dynamic" },
	
	-- Dynamic event - content changes based on past actions
	choices = {
		{
			text = "They need help with something",
			effects = {},
			feedText = "Helping a friend...",
			onResolve = function(state)
				local flags = state.Flags or {}
				local roll = math.random()
				
				-- If you've been a good friend, they ask for reasonable help
				if flags.good_friend or flags.helped_friend or flags.supportive then
					if roll < 0.5 then
						state:ModifyStat("Happiness", 5)
						-- CRITICAL FIX: Prevent negative money
						local loanAmount = math.random(100, 500)
						state.Money = math.max(0, (state.Money or 0) - loanAmount)
						state:AddFeed("📱 They needed a small loan. You helped out. Good karma!")
						state.Flags = state.Flags or {}
						state.Flags.helped_friend = true
					else
						state:ModifyStat("Happiness", 8)
						state:AddFeed("📱 They just wanted advice. You talked for hours. Friendship strengthened!")
					end
				else
					-- Neutral friend asks for more
					if roll < 0.3 then
						-- CRITICAL FIX: Prevent negative money
						local loanAmount = math.random(500, 2000)
						state.Money = math.max(0, (state.Money or 0) - loanAmount)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📱 They needed a big loan. Felt pressured to help. Hope they pay back...")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📱 They needed someone to listen. You were there.")
					end
				end
			end,
		},
		{
			text = "They have exciting news",
			effects = { Happiness = 5 },
			feedText = "📱 Great news from a friend! Sharing their joy with you.",
		},
		{
			text = "They want to reconnect",
			effects = {},
			feedText = "Catching up...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.6 then
					state:ModifyStat("Happiness", 10)
					state.Flags = state.Flags or {}
					state.Flags.rekindled_friendship = true
					state:AddFeed("📱 You two reconnected! It's like no time has passed. Best feeling!")
				else
					state:ModifyStat("Happiness", 3)
					state:AddFeed("📱 Nice to catch up, but you've both changed. Life moves on.")
				end
			end,
		},
		{
			text = "Ignore the message",
			effects = { Happiness = -2 },
			feedText = "📱 Left them on read. Might regret that later.",
			onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.ignored_friend = true
			end,
		},
	},
},

{
	id = "rel_friend_needs_you",
	title = "Friend in Crisis",
	emoji = "🆘",
	text = "A friend is going through something really tough and reaches out to you.",
	question = "How do you respond?",
	minAge = 16, maxAge = 80,
	baseChance = 0.4,
	cooldown = 5,
	stage = STAGE,
	ageBand = "any",
	category = "relationships",
	tags = { "friend", "crisis", "support", "dynamic" },
	
	choices = {
		{
			text = "Drop everything to help",
			effects = { Happiness = -3 },
			feedText = "Being there for them...",
			onResolve = function(state)
				local roll = math.random()
				state.Flags = state.Flags or {}
				state.Flags.supportive = true
				state.Flags.good_friend = true
				
				if roll < 0.7 then
					state:ModifyStat("Happiness", 15)
					state:AddFeed("🆘 You helped them through it. They'll never forget this. Friendship forever!")
					state.Flags.friend_owes_you = true
				else
					state:ModifyStat("Happiness", 8)
					state:AddFeed("🆘 You tried your best. They're still struggling but grateful you tried.")
				end
			end,
		},
		{
			text = "Offer support when convenient",
			effects = { Happiness = 2 },
			feedText = "🆘 You helped when you could. Better than nothing.",
		},
		{
			text = "Suggest professional help",
			effects = {},
			feedText = "Redirecting...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.5 then
					state:ModifyStat("Happiness", 5)
					state:AddFeed("🆘 They got professional help and are doing better! Good advice.")
				else
					state:ModifyStat("Happiness", -5)
					state:AddFeed("🆘 They felt abandoned. 'I wanted a friend, not a referral.' Ouch.")
				end
			end,
		},
		{
			text = "I have my own problems",
			effects = { Happiness = -5 },
			feedText = "🆘 You couldn't help. Hope that doesn't damage the friendship.",
			onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.self_focused = true
				if math.random() < 0.3 then
					state.Flags.lost_friend = true
					state:AddFeed("🆘 They stopped reaching out after that. Friendship may be over.")
				end
			end,
		},
	},
},

{
	id = "rel_friend_success",
	title = "Friend's Big Success",
	emoji = "🎊",
	text = "A close friend just achieved something incredible! They got their dream job/house/relationship!",
	question = "How do you react?",
	minAge = 20, maxAge = 70,
	baseChance = 0.5,
	cooldown = 4,
	stage = STAGE,
	ageBand = "adult",
	category = "relationships",
	tags = { "friend", "success", "jealousy", "support", "dynamic" },
	
	choices = {
		{
			text = "Genuinely celebrate with them",
			effects = { Happiness = 8 },
			feedText = "🎊 Their success is your joy! True friendship means sharing happiness!",
			onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.good_friend = true
				state.Flags.not_jealous = true
				-- Their success might open doors for you later
				if math.random() < 0.3 then
					state.Flags.friend_connection = true
					state:AddFeed("🎊 They want to help you succeed too! Connections incoming!")
				end
			end,
		},
		{
			text = "Feel a twinge of jealousy",
			effects = {},
			feedText = "Mixed feelings...",
			onResolve = function(state)
				local happy = (state.Stats and state.Stats.Happiness) or 50
				state.Flags = state.Flags or {}
				
				if happy < 40 then
					state:ModifyStat("Happiness", -8)
					state.Flags.jealous = true
					state:AddFeed("🎊 Why not me? Their success makes yours feel smaller. Dark thoughts creep in.")
				else
					state:ModifyStat("Happiness", 3)
					state:AddFeed("🎊 A little jealous, but mostly happy for them. Human nature.")
				end
			end,
		},
		{
			text = "Use it as motivation",
			effects = { Happiness = 5, Smarts = 2 },
			feedText = "🎊 If they can do it, so can you! Time to level up!",
			setFlags = { motivated = true, ambitious = true },
		},
		{
			text = "Pull away from the friendship",
			effects = { Happiness = -5 },
			feedText = "🎊 Hard to be around their success right now. Distance grows.",
			setFlags = { jealous = true, distancing_friend = true },
		},
	},
},

{
	id = "rel_friend_toxic",
	title = "Toxic Friend Behavior",
	emoji = "☢️",
	text = "{{FRIEND_NAME}} has been acting really poorly lately - gossiping, being negative, or taking advantage.",
	question = "What do you do about this friendship?",
	minAge = 16, maxAge = 70,
	baseChance = 0.4,
	cooldown = 5,
	stage = STAGE,
	ageBand = "any",
	category = "relationships",
	tags = { "friend", "toxic", "boundaries", "dynamic" },
	-- CRITICAL FIX: Only show if player has friends!
	eligibility = function(state)
		local hasFriends = state.Relationships and state.Relationships.friends and #state.Relationships.friends > 0
		if not hasFriends then
			-- Also check flat relationship table for friend types
			if state.Relationships then
				for _, rel in pairs(state.Relationships) do
					if type(rel) == "table" and (rel.type == "friend" or rel.role == "Friend") then
						hasFriends = true
						break
					end
				end
			end
		end
		return hasFriends, "You don't have any friends"
	end,
	
	choices = {
		{
			text = "Confront them about it",
			effects = {},
			feedText = "Having the hard talk...",
			onResolve = function(state)
				local smarts = (state.Stats and state.Stats.Smarts) or 50
				local roll = math.random(1, 100) - math.floor(smarts / 5)
				
				if roll < 40 then
					state:ModifyStat("Happiness", 10)
					state:AddFeed("☢️ They listened and apologized! The friendship is stronger now.")
					state.Flags = state.Flags or {}
					state.Flags.stood_up_for_self = true
				elseif roll < 70 then
					state:ModifyStat("Happiness", -5)
					state:AddFeed("☢️ It got heated. Things are awkward now. Time will tell if it survives.")
				else
					state:ModifyStat("Happiness", -8)
					state:AddFeed("☢️ They turned it around on YOU! Now you're the bad guy. Gaslighting much?")
				end
			end,
		},
		{
			text = "Set strict boundaries",
			effects = { Happiness = 3 },
			feedText = "☢️ Limiting contact. Protecting your peace. Healthy choice.",
			setFlags = { has_boundaries = true },
		},
		{
			text = "End the friendship",
			effects = {},
			feedText = "Cutting them off...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.6 then
					state:ModifyStat("Happiness", 8)
					state:AddFeed("☢️ Weight lifted! Should have done this sooner. Peace restored.")
				else
					state:ModifyStat("Happiness", -3)
					state:AddFeed("☢️ Ending it was hard. Mutual friends are awkward now. But necessary.")
				end
				state.Flags = state.Flags or {}
				state.Flags.ended_toxic_friendship = true
			end,
		},
		{
			text = "Let it slide - avoid conflict",
			effects = { Happiness = -5 },
			feedText = "☢️ Ignoring the behavior. But the resentment builds...",
			onResolve = function(state)
				state.Flags = state.Flags or {}
				state.Flags.conflict_avoidant = true
			end,
		},
	},
},

{
	id = "rel_unexpected_reunion",
	title = "Unexpected Reunion",
	emoji = "👥",
	text = "You ran into someone from your past at the most unexpected place!",
	question = "Who did you encounter?",
	minAge = 20, maxAge = 80,
	baseChance = 0.45,
	cooldown = 4,
	stage = STAGE,
	ageBand = "adult",
	category = "relationships",
	tags = { "reunion", "past", "encounter", "dynamic" },
	
	choices = {
		{
			text = "A childhood friend",
			effects = {},
			feedText = "Blast from the past...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.5 then
					state:ModifyStat("Happiness", 12)
					state:AddFeed("👥 Instant connection! It's like you're kids again! Exchange numbers!")
					state.Flags = state.Flags or {}
					state.Flags.rekindled_friendship = true
				else
					state:ModifyStat("Happiness", 5)
					state:AddFeed("👥 Nice to catch up but you've grown apart. Still, good memories.")
				end
			end,
		},
		{
			text = "Someone you had a falling out with",
			effects = {},
			feedText = "Awkward encounter...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.3 then
					state:ModifyStat("Happiness", 10)
					state:AddFeed("👥 You both apologized. Water under the bridge. Closure at last!")
					state.Flags = state.Flags or {}
					state.Flags.made_amends = true
				elseif roll < 0.6 then
					state:ModifyStat("Happiness", -5)
					state:AddFeed("👥 Icy stares. Neither of you spoke first. The wound is still fresh.")
				else
					state:ModifyStat("Happiness", -8)
					state:AddFeed("👥 They made a scene. Everyone stared. Humiliating.")
				end
			end,
		},
		{
			text = "A mentor who helped shape you",
			effects = { Happiness = 10, Smarts = 2 },
			feedText = "👥 Seeing them reminds you of how far you've come. They're proud of you!",
		},
		{
			text = "Someone you'd rather forget",
			effects = { Happiness = -5 },
			feedText = "👥 Pretended not to see them. Heart racing. Memories flooding back.",
		},
	},
},

{
	id = "rel_group_dynamics",
	title = "Friend Group Drama",
	emoji = "👯",
	text = "There's tension in your friend group. Two friends are fighting and everyone's picking sides.",
	question = "What's your role in this?",
	minAge = 16, maxAge = 50,
	baseChance = 0.4,
	cooldown = 5,
	stage = STAGE,
	ageBand = "any",
	category = "relationships",
	tags = { "friends", "group", "drama", "conflict", "dynamic" },
	
	choices = {
		{
			text = "Be the mediator",
			effects = {},
			feedText = "Trying to make peace...",
			onResolve = function(state)
				local smarts = (state.Stats and state.Stats.Smarts) or 50
				local roll = math.random(1, 100) - math.floor(smarts / 4)
				
				if roll < 35 then
					state:ModifyStat("Happiness", 12)
					state:AddFeed("👯 You brought them together! Both sides thank you. Group saved!")
					state.Flags = state.Flags or {}
					state.Flags.peacemaker = true
				elseif roll < 65 then
					state:ModifyStat("Happiness", 5)
					state:AddFeed("👯 Tensions eased but not resolved. At least they're talking.")
				else
					state:ModifyStat("Happiness", -8)
					state:AddFeed("👯 Both sides now mad at YOU for interfering! Backfired badly.")
				end
			end,
		},
		{
			text = "Pick a side",
			effects = {},
			feedText = "Taking a stance...",
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.5 then
					state:ModifyStat("Happiness", 5)
					state:AddFeed("👯 Your side 'won'. But you lost some friends in the process.")
				else
					state:ModifyStat("Happiness", -5)
					state:AddFeed("👯 Your side 'lost'. Awkward. Wish you'd stayed neutral.")
				end
				state.Flags = state.Flags or {}
				state.Flags.picked_sides = true
			end,
		},
		{
			text = "Stay completely neutral",
			effects = { Happiness = 2 },
			feedText = "👯 Not your circus, not your monkeys. Staying out of it.",
		},
		{
			text = "Distance from the whole group",
			effects = { Happiness = -3 },
			feedText = "👯 Too much drama. Taking a break from everyone. Lonely but peaceful.",
		},
	},
},
}

-- CRITICAL FIX #136: Export events in standard format for LifeEvents loader
RelationshipsExpanded.LifeEvents = RelationshipsExpanded.events

return RelationshipsExpanded
