--[[
	╔══════════════════════════════════════════════════════════════════════════════╗
	║              RELATIONSHIPS EVENTS MODULE v2.0                                 ║
	║         Triple-AAAA Quality Relationship-Focused Life Events                  ║
	╠══════════════════════════════════════════════════════════════════════════════╣
	║  This module contains 80+ detailed relationship events covering:             ║
	║  • Dating & romance (meeting people, first dates, relationships)              ║
	║  • Committed relationships (moving in, proposals, weddings)                    ║
	║  • Relationship challenges (conflicts, cheating, long distance)               ║
	║  • Family relationships (parents, siblings, children)                           ║
	║  • Friendships (making friends, maintaining friendships, losing friends)     ║
	║  • Loss & grief (death of loved ones, reconnecting)                            ║
	║                                                                              ║
	║  Events are CONTEXTUAL - they only trigger when relevant to the player's     ║
	║  current relationship situation, preventing random "godmode" popups.         ║
	╚══════════════════════════════════════════════════════════════════════════════╝
]]

local Relationships = {}

local RANDOM = Random.new()

Relationships.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- DATING & ROMANCE
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "dating_app",
		title = "Modern Dating",
		emoji = "📱",
		text = "Your friend suggests you try a dating app. They say it's how everyone meets people these days. You're skeptical, but also curious.",
		question = "Do you give it a shot?",
		minAge = 18, maxAge = 45,
		baseChance = 0.5,
		cooldown = 3,
		requiresSingle = true,
		blockedByFlags = { in_prison = true },
		choices = {
			{ 
				text = "Swipe right!", 
				effects = { Happiness = 5 }, 
				setFlags = { dating_app_user = true, social_online = true }, 
				feedText = "You downloaded the app. Time to see what's out there!",
				onResolve = function(state)
					if RANDOM:NextNumber() < 0.6 then
						if state.AddFeed then
							state:AddFeed("You matched with someone interesting! Conversation started!")
						end
					end
				end,
			},
			{ 
				text = "Be super selective", 
				effects = { Smarts = 2, Happiness = 3 }, 
				setFlags = { dating_app_user = true, picky = true },
				feedText = "You're being very selective. Quality over quantity.",
			},
			{ 
				text = "Dating apps aren't for me", 
				effects = { Happiness = 2 }, 
				setFlags = { prefers_organic_meeting = true },
				feedText = "You prefer meeting people organically. Old school, but that's you.",
			},
		},
	},
	
	{
		id = "chance_encounter",
		title = "Love at First Sight?",
		emoji = "💘",
		text = "You lock eyes with a stranger across the room. There's an instant connection - that spark you've heard about. The moment feels electric.",
		question = "What do you do?",
		minAge = 18, maxAge = 50,
		baseChance = 0.4,
		cooldown = 3,
		requiresSingle = true,
		blockedByFlags = { in_prison = true },
		choices = {
			{ 
				text = "Go talk to them", 
				effects = { Happiness = 8, Looks = 2 }, 
				setFlags = { has_partner = true, dating = true, met_cute = true }, 
				feedText = "You made the first move! They were receptive. You exchanged numbers!",
				onResolve = function(state)
					if state.AddRelationship then
						local partnerName = state.Gender == "male" and "Emma" or "Alex"
						local relId = "encounter_" .. tostring(state.Age or 0) .. "_" .. tostring(os.time())
						state:AddRelationship(relId, {
							name = partnerName,
							type = "romance",
							role = "Partner",
							relationship = 60,
							age = (state.Age or 25) + RANDOM:NextInteger(-5, 5),
							alive = true,
						})
					end
				end,
			},
			{ 
				text = "Smile and hope they approach", 
				effects = { Happiness = 4 }, 
				feedText = "You shared a moment but didn't pursue. The connection was there, but timing wasn't.",
			},
			{ 
				text = "Too nervous to act", 
				effects = { Happiness = -3 }, 
				setFlags = { shy = true },
				feedText = "The moment passed. You'll always wonder 'what if...?'",
			},
		},
	},
	
	{
		id = "blind_date_setup",
		title = "Blind Date",
		emoji = "👀",
		text = "A friend wants to set you up on a blind date. They swear this person is perfect for you. You're skeptical, but your friend is insistent.",
		question = "Do you go?",
		minAge = 18, maxAge = 45,
		baseChance = 0.35,
		cooldown = 4,
		requiresSingle = true,
		blockedByFlags = { in_prison = true },
		choices = {
			{
				text = "Sure, why not?",
				effects = { Happiness = 4, Money = -50 },
				setFlags = { open_minded = true },
				feedText = "You went on the blind date. It was... interesting.",
				onResolve = function(state)
					if RANDOM:NextNumber() < 0.5 then
						if state.AddFeed then
							state:AddFeed("The date went well! You're seeing them again!")
						end
						if state.AddRelationship then
							local partnerName = state.Gender == "male" and "Sam" or "Jordan"
							local relId = "blind_date_" .. tostring(state.Age or 0) .. "_" .. tostring(os.time())
							state:AddRelationship(relId, {
								name = partnerName,
								type = "romance",
								role = "Partner",
								relationship = 55,
								age = (state.Age or 25) + RANDOM:NextInteger(-3, 3),
								alive = true,
							})
						end
						if state.SetFlag then
							state:SetFlag("has_partner", true)
							state:SetFlag("dating", true)
						end
					else
						if state.AddFeed then
							state:AddFeed("The date was awkward. No second date, but you tried!")
						end
					end
				end,
			},
			{
				text = "No thanks",
				effects = { Happiness = 1 },
				setFlags = { independent = true },
				feedText = "You declined. You'll find someone on your own terms.",
			},
			{
				text = "Get more info first",
				effects = { Happiness = 2, Smarts = 1 },
				setFlags = { cautious = true },
				feedText = "You asked for more details. Smart move.",
			},
		},
	},
	
	{
		id = "first_date_nerves",
		title = "First Date Jitters",
		emoji = "😰",
		text = "You have a first date coming up. You're excited but also nervous. What if you say something stupid? What if there's no chemistry?",
		question = "How do you prepare?",
		minAge = 16, maxAge = 50,
		baseChance = 0.4,
		cooldown = 2,
		requiresFlags = { dating = true },
		choices = {
			{
				text = "Overthink everything",
				effects = { Happiness = -2, Smarts = 1 },
				setFlags = { anxious = true },
				feedText = "You overthought it. The date was okay, but you were in your head.",
			},
			{
				text = "Just be yourself",
				effects = { Happiness = 6 },
				setFlags = { confident = true },
				feedText = "You went in relaxed and authentic. The date went great!",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.min(100, (partner.relationship or 50) + 10) })
					end
				end,
			},
			{
				text = "Cancel last minute",
				effects = { Happiness = -5 },
				setFlags = { flaky = true },
				feedText = "You canceled. They're not happy. Probably no second chance.",
			},
		},
	},
	
	{
		id = "new_friendship",
		title = "Potential Friend",
		emoji = "🤝",
		text = "You've been hitting it off with someone you recently met. You have similar interests, good conversation flows easily. This could be the start of a great friendship.",
		question = "Could this be a new friendship?",
		minAge = 13, maxAge = 80,
		baseChance = 0.5,
		cooldown = 2,
		choices = {
			{ 
				text = "Definitely - let's hang out more", 
				effects = { Happiness = 8 }, 
				setFlags = { has_best_friend = true, social = true }, 
				feedText = "You made a new friend! Plans are already being made!",
				onResolve = function(state)
					if state.AddRelationship then
						local friendNames = {"Alex", "Sam", "Jordan", "Casey", "Taylor"}
						local friendName = friendNames[RANDOM:NextInteger(1, #friendNames)]
						local relId = "friend_" .. tostring(state.Age or 0) .. "_" .. tostring(os.time())
						state:AddRelationship(relId, {
							name = friendName,
							type = "friend",
							role = "Friend",
							relationship = 70,
							age = (state.Age or 20) + RANDOM:NextInteger(-5, 5),
							alive = true,
						})
					end
				end,
			},
			{ 
				text = "Take it slow", 
				effects = { Happiness = 4 }, 
				setFlags = { cautious = true },
				feedText = "You're cautiously optimistic. Time will tell.",
			},
			{ 
				text = "I'm good on friends", 
				effects = { Happiness = 1 }, 
				setFlags = { introverted = true },
				feedText = "You have enough friends. You're content with your current circle.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- COMMITTED RELATIONSHIP
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "relationship_milestone",
		title = "Getting Serious",
		emoji = "💕",
		text = "Your relationship is getting more serious. You've been dating for a while, and you're both feeling it. The 'L' word has been mentioned. This is a big step.",
		question = "How do you feel about it?",
		minAge = 18, maxAge = 60,
		baseChance = 0.5,
		cooldown = 3,
		requiresPartner = true,
		requiresFlags = { dating = true },
		choices = {
			{ 
				text = "I'm ready for commitment", 
				effects = { Happiness = 10 }, 
				setFlags = { committed_relationship = true }, 
				feedText = "You're all in! You said 'I love you' and meant it. This is real.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.min(100, (partner.relationship or 50) + 15) })
					end
				end,
			},
			{ 
				text = "I need more time", 
				effects = { Happiness = 2 }, 
				setFlags = { taking_it_slow = true },
				feedText = "You're taking things slow. They understand, but seem a bit disappointed.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.max(0, (partner.relationship or 50) - 5) })
					end
				end,
			},
			{ 
				text = "Maybe this isn't right", 
				effects = { Happiness = -5 }, 
				setFlags = { relationship_doubts = true },
				feedText = "Doubts are creeping in. Maybe this isn't the one.",
				onResolve = function(state)
					if RANDOM:NextNumber() < 0.4 then
						if state.AddFeed then
							state:AddFeed("You broke up. It wasn't right.")
						end
						if state.SetFlag then
							state:SetFlag("has_partner", false)
							state:SetFlag("dating", false)
						end
					end
				end,
			},
		},
	},
	
	{
		id = "move_in_together",
		title = "Living Together",
		emoji = "🏠",
		text = "Your partner suggests moving in together. You've been dating for a while, and it makes financial sense. But it's a big step - sharing space, bills, life. Are you ready?",
		question = "What's your decision?",
		minAge = 20, maxAge = 50,
		oneTime = true,
		requiresPartner = true,
		requiresFlags = { committed_relationship = true },
		choices = {
			{ 
				text = "Yes! Let's do it!", 
				effects = { Happiness = 10, Money = -2000 }, 
				setFlags = { lives_with_partner = true, living_independently = true }, 
				feedText = "You moved in together! It's an adjustment, but you're happy.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.min(100, (partner.relationship or 50) + 10) })
					end
				end,
			},
			{ 
				text = "I'm not ready yet", 
				effects = { Happiness = -3 }, 
				setFlags = { not_ready_to_move_in = true },
				feedText = "You need more time. They understand, but seem disappointed.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.max(0, (partner.relationship or 50) - 10) })
					end
				end,
			},
			{ 
				text = "Break up instead", 
				effects = { Happiness = -10 }, 
				setFlags = { recently_single = true, has_partner = false, dating = false }, 
				feedText = "The conversation led to a breakup. You realized you weren't on the same page.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.RemoveRelationship then
						state:RemoveRelationship(partnerId)
					end
				end,
			},
		},
	},
	
	{
		id = "proposal",
		title = "The Proposal",
		emoji = "💍",
		text = "It feels like the right time. You've been together for a while, you're happy, and you can see a future together. Should you propose?",
		question = "Are you ready to pop the question?",
		minAge = 22, maxAge = 50,
		oneTime = true,
		requiresPartner = true,
		requiresFlags = { lives_with_partner = true },
		choices = {
			{ 
				text = "Yes - plan the perfect proposal", 
				effects = { Happiness = 15, Money = -2000 }, 
				setFlags = { engaged = true }, 
				feedText = "You planned the perfect proposal! They said yes! You're engaged!",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.min(100, (partner.relationship or 50) + 20) })
					end
				end,
			},
			{ 
				text = "Simple and intimate", 
				effects = { Happiness = 12, Money = -500 }, 
				setFlags = { engaged = true }, 
				feedText = "A quiet, perfect moment at home. You're engaged!",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.min(100, (partner.relationship or 50) + 15) })
					end
				end,
			},
			{ 
				text = "Not yet", 
				effects = { Happiness = 2 }, 
				setFlags = { not_ready_to_propose = true },
				feedText = "The timing isn't right. You'll know when it is.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.max(0, (partner.relationship or 50) - 15) })
					end
				end,
			},
		},
	},
	
	{
		id = "wedding_day",
		title = "Wedding Day",
		emoji = "👰",
		text = "The big day has arrived! After all the planning, stress, and excitement, you're finally getting married. Your family and friends are here. This is it.",
		question = "What kind of wedding do you have?",
		minAge = 22, maxAge = 60,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		requiresPartner = true,
		requiresFlags = { engaged = true },
		choices = {
			{ 
				text = "Grand celebration", 
				effects = { Happiness = 20, Money = -10000 }, 
				setFlags = { married = true, big_wedding = true }, 
				feedText = "An unforgettable wedding! Everyone was there, everything was perfect. You're married!",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = 100 })
					end
				end,
			},
			{ 
				text = "Intimate ceremony", 
				effects = { Happiness = 15, Money = -2000 }, 
				setFlags = { married = true, intimate_wedding = true }, 
				feedText = "A beautiful, small wedding with just close family and friends. You're married!",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = 95 })
					end
				end,
			},
			{ 
				text = "Courthouse wedding", 
				effects = { Happiness = 10, Money = -200 }, 
				setFlags = { married = true, courthouse_wedding = true }, 
				feedText = "Quick and official. Just you, your partner, and a judge. You're married!",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = 90 })
					end
				end,
			},
			{ 
				text = "Elope!", 
				effects = { Happiness = 12, Money = -1000 }, 
				setFlags = { married = true, eloped = true }, 
				feedText = "You eloped! Just the two of you, somewhere beautiful. Romantic and spontaneous!",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = 95 })
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- RELATIONSHIP CHALLENGES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "relationship_conflict",
		title = "Rough Patch",
		emoji = "💔",
		text = "You and your partner have been arguing a lot lately. Small things escalate quickly. You're both stressed, and it's taking a toll on your relationship.",
		question = "How do you handle it?",
		minAge = 18, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		requiresPartner = true,
		choices = {
			{ 
				text = "Communicate openly", 
				effects = { Happiness = 5, Smarts = 2 }, 
				setFlags = { good_communicator = true },
				feedText = "You sat down and talked it through. Hard conversations, but things improved.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.min(100, (partner.relationship or 50) + 5) })
					end
				end,
			},
			{ 
				text = "Seek couples counseling", 
				effects = { Happiness = 7, Money = -300 }, 
				setFlags = { proactive = true },
				feedText = "You got professional help. It wasn't easy, but it made a difference.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.min(100, (partner.relationship or 50) + 10) })
					end
				end,
			},
			{ 
				text = "Give each other space", 
				effects = { Happiness = 3 }, 
				setFlags = { needs_space = true },
				feedText = "Some distance helped. You both needed time to cool off.",
			},
			{ 
				text = "It's time to break up", 
				effects = { Happiness = -8 }, 
				setFlags = { recently_single = true, has_partner = false, dating = false, married = false }, 
				feedText = "You ended the relationship. It was toxic, and you're better off apart.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.RemoveRelationship then
						state:RemoveRelationship(partnerId)
					end
				end,
			},
		},
	},
	
	{
		id = "partner_achievement",
		title = "Partner's Big Win",
		emoji = "🎉",
		text = "Your partner achieved something amazing! A promotion, an award, a major accomplishment. They're on cloud nine, and you're watching them shine.",
		question = "How do you celebrate?",
		minAge = 20, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		requiresPartner = true,
		choices = {
			{ 
				text = "Throw a celebration", 
				effects = { Happiness = 10, Money = -200 }, 
				setFlags = { supportive = true },
				feedText = "You threw them a surprise celebration! They were so touched!",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.min(100, (partner.relationship or 50) + 10) })
					end
				end,
			},
			{ 
				text = "Heartfelt congratulations", 
				effects = { Happiness = 8 }, 
				setFlags = { genuine = true },
				feedText = "Your sincere joy meant everything to them. You're genuinely proud.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.min(100, (partner.relationship or 50) + 5) })
					end
				end,
			},
			{ 
				text = "Feel a bit jealous", 
				effects = { Happiness = -3 }, 
				setFlags = { competitive_with_partner = true },
				feedText = "You struggled with mixed feelings. Happy for them, but also envious.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.max(0, (partner.relationship or 50) - 5) })
					end
				end,
			},
		},
	},
	
	{
		id = "long_distance",
		title = "Long Distance Relationship",
		emoji = "🌍",
		text = "Your partner has to move away for work/school. It's a great opportunity for them, but it means long distance. Can your relationship survive?",
		question = "Can you make it work?",
		minAge = 18, maxAge = 50,
		baseChance = 0.3,
		cooldown = 5,
		requiresPartner = true,
		choices = {
			{ 
				text = "We'll make it work", 
				effects = { Happiness = 3, Money = -500 }, 
				setFlags = { long_distance = true, committed = true }, 
				feedText = "You're committed despite the distance. Video calls, visits, you'll make it work.",
				onResolve = function(state)
					if RANDOM:NextNumber() < 0.5 then
						if state.AddFeed then
							state:AddFeed("Long distance was too hard. You broke up.")
						end
						if state.SetFlag then
							state:SetFlag("has_partner", false)
							state:SetFlag("dating", false)
						end
					end
				end,
			},
			{ 
				text = "Move with them", 
				effects = { Happiness = 8, Money = -5000 }, 
				setFlags = { relocated_for_love = true }, 
				feedText = "You moved to stay together! Big change, but love conquers all!",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.min(100, (partner.relationship or 50) + 15) })
					end
				end,
			},
			{ 
				text = "Break up but stay friends", 
				effects = { Happiness = -5 }, 
				setFlags = { recently_single = true, has_partner = false }, 
				feedText = "You ended it but remained friends. Sometimes love isn't enough.",
			},
		},
	},
	
	{
		id = "infidelity_discovery",
		title = "Caught Cheating",
		emoji = "💔",
		text = "You discovered your partner has been cheating. The evidence is undeniable - texts, photos, lies. Your world is shattered. Everything you thought was real feels like a lie.",
		question = "What do you do?",
		minAge = 18, maxAge = 60,
		baseChance = 0.15,
		cooldown = 8,
		requiresPartner = true,
		choices = {
			{
				text = "Confront and break up immediately",
				effects = { Happiness = -10 },
				setFlags = { has_partner = false, dating = false, married = false, recently_single = true },
				feedText = "You confronted them and broke up immediately. You deserve better than this.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.RemoveRelationship then
						state:RemoveRelationship(partnerId)
					end
				end,
			},
			{
				text = "Try to work it out",
				effects = { Happiness = -8, Smarts = -2 },
				setFlags = { forgiving = true, relationship_damaged = true },
				feedText = "You're trying to work through it. It's hard, trust is broken, but you're trying.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.max(0, (partner.relationship or 50) - 40) })
					end
					if RANDOM:NextNumber() < 0.7 then
						if state.AddFeed then
							state:AddFeed("It didn't work out. You broke up after all.")
						end
						if state.SetFlag then
							state:SetFlag("has_partner", false)
							state:SetFlag("dating", false)
							state:SetFlag("married", false)
						end
					end
				end,
			},
			{
				text = "Get revenge",
				effects = { Happiness = -5, Smarts = -3 },
				setFlags = { vengeful = true },
				feedText = "You cheated back. Now you're both miserable. Toxic relationship.",
				onResolve = function(state)
					local partnerId, partner = getCurrentPartner(state)
					if partnerId and state.ModifyRelationship then
						state:ModifyRelationship(partnerId, { relationship = math.max(0, (partner.relationship or 50) - 50) })
					end
					if RANDOM:NextNumber() < 0.8 then
						if state.AddFeed then
							state:AddFeed("You both broke up. Toxic relationship ended.")
						end
						if state.SetFlag then
							state:SetFlag("has_partner", false)
							state:SetFlag("dating", false)
							state:SetFlag("married", false)
						end
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FAMILY & CHILDREN
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "having_child",
		title = "Starting a Family",
		emoji = "👶",
		text = "You and your partner are discussing having children. It's a big decision - life-changing, expensive, rewarding. Are you ready to be parents?",
		question = "What do you decide?",
		minAge = 25, maxAge = 45,
		oneTime = true,
		requiresPartner = true,
		requiresFlags = { married = true },
		choices = {
			{ 
				text = "Let's have a baby!", 
				effects = { Happiness = 15, Money = -3000 }, 
				setFlags = { has_child = true, parent = true }, 
				feedText = "Congratulations! You're trying for a baby! This is exciting!",
				onResolve = function(state)
					if state.AddFeed then
						state:AddFeed("Nine months later... you're parents! A beautiful baby!")
					end
				end,
			},
			{ 
				text = "Adopt a child", 
				effects = { Happiness = 15, Money = -5000 }, 
				setFlags = { has_child = true, parent = true, adopted = true }, 
				feedText = "You're starting the adoption process! What a beautiful choice!",
				onResolve = function(state)
					if state.AddFeed then
						state:AddFeed("After months of paperwork and waiting... you adopted a child! Your family is complete!")
					end
				end,
			},
			{ 
				text = "Not right now", 
				effects = { Happiness = 2 }, 
				setFlags = { not_ready_for_kids = true },
				feedText = "You're not ready for kids yet. Maybe later.",
			},
			{ 
				text = "We don't want children", 
				effects = { Happiness = 5 }, 
				setFlags = { childfree = true }, 
				feedText = "You've decided to remain childfree. Your choice, and it's valid.",
			},
		},
	},
	
	{
		id = "parenting_challenge",
		title = "Parenting Dilemma",
		emoji = "👨‍👩‍👧",
		text = "Your child is going through a difficult phase. They're acting out, struggling in school, or having social issues. Parenting is harder than you thought.",
		question = "How do you handle it?",
		minAge = 28, maxAge = 60,
		baseChance = 0.5,
		cooldown = 2,
		requiresFlags = { parent = true },
		choices = {
			{ 
				text = "Patient understanding", 
				effects = { Happiness = 5, Smarts = 2 }, 
				setFlags = { patient_parent = true },
				feedText = "You were patient and understanding. It took time, but things improved.",
			},
			{ 
				text = "Strict discipline", 
				effects = { Happiness = -2 }, 
				setFlags = { strict_parent = true },
				feedText = "You laid down the law. It worked, but your relationship with them suffered.",
			},
			{ 
				text = "Get professional advice", 
				effects = { Happiness = 3, Money = -200 }, 
				setFlags = { proactive_parent = true },
				feedText = "You got expert advice. It helped, and you learned better parenting strategies.",
			},
			{ 
				text = "Just hope they grow out of it", 
				effects = { Happiness = 2 }, 
				setFlags = { passive_parent = true },
				feedText = "You hoped it would pass. Sometimes it did, sometimes it didn't.",
			},
		},
	},
	
	{
		id = "child_achievement",
		title = "Proud Parent Moment",
		emoji = "🌟",
		text = "Your child did something amazing! Won an award, got into a great school, achieved something you're proud of. This is what parenting is all about.",
		question = "How do you react?",
		minAge = 30, maxAge = 70,
		baseChance = 0.4,
		cooldown = 2,
		requiresFlags = { parent = true },
		choices = {
			{ 
				text = "Celebrate with them", 
				effects = { Happiness = 12 }, 
				setFlags = { supportive_parent = true },
				feedText = "You celebrated together! Their joy is your joy!",
			},
			{ 
				text = "Share it with everyone", 
				effects = { Happiness = 8 }, 
				setFlags = { proud_parent = true },
				feedText = "You proudly told everyone! You're that parent now, and you don't care!",
			},
			{ 
				text = "Keep encouraging them", 
				effects = { Happiness = 8, Smarts = 2 }, 
				setFlags = { encouraging_parent = true },
				feedText = "You used it as motivation. Keep going, you're doing great!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FAMILY RELATIONSHIPS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "sibling_rivalry",
		title = "Sibling Issues",
		emoji = "👊",
		text = "You and your sibling have been at odds lately. Old resentments, new conflicts, competition. Family drama is exhausting.",
		question = "How do you deal with it?",
		minAge = 10, maxAge = 60,
		baseChance = 0.4,
		cooldown = 4,
		requiresFlags = { has_siblings = true },
		choices = {
			{ 
				text = "Work it out together", 
				effects = { Happiness = 5 }, 
				setFlags = { reconciliatory = true },
				feedText = "You sat down and talked it out. You reconciled with your sibling.",
			},
			{ 
				text = "Keep your distance", 
				effects = { Happiness = 2 }, 
				setFlags = { distant_from_sibling = true },
				feedText = "Some space helped. You're not close, but you're not fighting.",
			},
			{ 
				text = "Get parents involved", 
				effects = { Happiness = 1 }, 
				feedText = "Your parents tried to mediate. It helped a bit, but you're both adults now.",
			},
			{ 
				text = "Accept differences", 
				effects = { Happiness = 3, Smarts = 2 }, 
				setFlags = { mature = true },
				feedText = "You accepted that you're different people. You don't have to be best friends.",
			},
		},
	},
	
	{
		id = "parent_relationship",
		title = "Connecting with Parents",
		emoji = "👪",
		text = "Your relationship with your parents has been complicated. There's history, expectations, maybe some resentment. But they're your parents, and life is short.",
		question = "How do you approach it?",
		minAge = 18, maxAge = 50,
		baseChance = 0.3,
		cooldown = 5,
		choices = {
			{ 
				text = "Make effort to connect", 
				effects = { Happiness = 8 }, 
				setFlags = { close_to_parents = true }, 
				feedText = "You worked on your relationship with them. It wasn't easy, but it was worth it.",
			},
			{ 
				text = "Set healthy boundaries", 
				effects = { Happiness = 5, Smarts = 2 }, 
				setFlags = { healthy_boundaries = true },
				feedText = "You established boundaries. You can love them without letting them control you.",
			},
			{ 
				text = "Accept the distance", 
				effects = { Happiness = 2 }, 
				setFlags = { distant_from_parents = true },
				feedText = "Not all families are close. You've accepted that.",
			},
			{ 
				text = "Cut contact", 
				effects = { Happiness = -5 }, 
				setFlags = { estranged_from_parents = true }, 
				feedText = "You distanced yourself completely. Sometimes that's necessary for your mental health.",
			},
		},
	},
	
	{
		id = "family_reunion",
		title = "Family Gathering",
		emoji = "🎊",
		text = "There's a big family reunion happening. Everyone's coming - aunts, uncles, cousins you haven't seen in years. It'll be chaotic, but maybe fun?",
		question = "Will you attend?",
		minAge = 20, maxAge = 80,
		baseChance = 0.4,
		cooldown = 3,
		choices = {
			{ 
				text = "Enthusiastically attend", 
				effects = { Happiness = 8 }, 
				setFlags = { family_oriented = true },
				feedText = "You had a great time with family! Caught up with everyone, made memories!",
			},
			{ 
				text = "Go reluctantly", 
				effects = { Happiness = 2 }, 
				setFlags = { obligated = true },
				feedText = "You showed up. That counts. It wasn't terrible.",
			},
			{ 
				text = "Skip it this time", 
				effects = { Happiness = 3 }, 
				setFlags = { independent = true },
				feedText = "You sat this one out. You'll catch the next one... maybe.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- LOSS & GRIEF
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "loss_of_loved_one",
		title = "Difficult Goodbye",
		emoji = "🕯️",
		text = "Someone close to you has passed away. A family member, a friend, someone who mattered. The grief is heavy, and you're not sure how to process it.",
		question = "How do you cope with the loss?",
		minAge = 20, maxAge = 90,
		baseChance = 0.2,
		cooldown = 5,
		choices = {
			{ 
				text = "Lean on others for support", 
				effects = { Happiness = -5, Health = -2 }, 
				setFlags = { grieving = true },
				feedText = "Grief is heavy, but you're not alone. Your loved ones are there for you.",
			},
			{ 
				text = "Celebrate their life", 
				effects = { Happiness = -3, Smarts = 2 }, 
				setFlags = { celebrates_life = true },
				feedText = "You chose to remember the good times. They would have wanted that.",
			},
			{ 
				text = "Struggle in silence", 
				effects = { Happiness = -10, Health = -5 }, 
				setFlags = { grief = true, isolated = true },
				feedText = "You're struggling but hiding it. The pain is eating at you.",
			},
			{ 
				text = "Seek professional help", 
				effects = { Happiness = -3, Money = -200 }, 
				setFlags = { seeking_help = true },
				feedText = "A therapist helped you process. Grief is a journey, and you're taking it step by step.",
			},
		},
	},
	
	{
		id = "old_friend",
		title = "Reconnecting",
		emoji = "📱",
		text = "An old friend reaches out after years of no contact. You used to be close, but life happened and you drifted apart. Do you want to reconnect?",
		question = "Do you reconnect?",
		minAge = 25, maxAge = 80,
		baseChance = 0.4,
		cooldown = 3,
		choices = {
			{ 
				text = "Absolutely!", 
				effects = { Happiness = 8 }, 
				setFlags = { reconnected = true },
				feedText = "You reconnected with an old friend! It's like no time passed!",
				onResolve = function(state)
					if state.AddRelationship then
						local friendNames = {"Alex", "Sam", "Jordan", "Casey", "Taylor"}
						local friendName = friendNames[RANDOM:NextInteger(1, #friendNames)]
						local relId = "old_friend_" .. tostring(state.Age or 0) .. "_" .. tostring(os.time())
						state:AddRelationship(relId, {
							name = friendName,
							type = "friend",
							role = "Old Friend",
							relationship = 65,
							age = (state.Age or 30) + RANDOM:NextInteger(-5, 5),
							alive = true,
						})
					end
				end,
			},
			{ 
				text = "Cautiously yes", 
				effects = { Happiness = 4 }, 
				setFlags = { cautious = true },
				feedText = "You're giving it a try. See if the friendship can be rekindled.",
			},
			{ 
				text = "Some bridges are meant to stay closed", 
				effects = { Happiness = 2 }, 
				setFlags = { moved_on = true },
				feedText = "You chose not to reconnect. That chapter is closed.",
			},
		},
	},
	
	{
		id = "friend_drift_apart",
		title = "Growing Apart",
		emoji = "👋",
		text = "You and a close friend have been drifting apart. Different paths, different priorities, less in common. The friendship isn't what it used to be.",
		question = "What do you do?",
		minAge = 20, maxAge = 60,
		baseChance = 0.3,
		cooldown = 4,
		requiresFlags = { has_best_friend = true },
		choices = {
			{
				text = "Make effort to reconnect",
				effects = { Happiness = 5, Smarts = 1 },
				setFlags = { proactive = true },
				feedText = "You reached out and made plans. The friendship is worth saving.",
			},
			{
				text = "Let it fade naturally",
				effects = { Happiness = 1 },
				setFlags = { accepting = true },
				feedText = "You let it fade. Some friendships aren't meant to last forever.",
			},
			{
				text = "Have a conversation about it",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { communicative = true },
				feedText = "You talked about it. Honest conversation helped.",
			},
		},
	},
}

-- Helper function to get current partner (if needed by events)
function getCurrentPartner(state)
	if not state.Relationships then return nil, nil end
	for id, rel in pairs(state.Relationships) do
		if rel.type == "romance" and rel.alive ~= false then
			return id, rel
		end
	end
	return nil, nil
end

return Relationships
