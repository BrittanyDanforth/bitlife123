--[[
	Relationship Events
	Events related to romance, marriage, family, friends
	Many require having or not having a partner
]]

local Relationships = {}

Relationships.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- DATING & ROMANCE
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "dating_app",
		title = "Modern Dating",
		emoji = "📱",
		text = "Your friend suggests you try a dating app.",
		question = "Do you give it a shot?",
		minAge = 18, maxAge = 45,
		baseChance = 0.5,
		cooldown = 3,
		requiresSingle = true,
		-- CRITICAL FIX: Can't use dating apps from prison!
		blockedByFlags = { in_prison = true, incarcerated = true },
		choices = {
			{ text = "Swipe right!", effects = { Happiness = 8 }, setFlags = { has_partner = true, dating = true }, feedText = "You matched with someone great!" },
			{ text = "Be super selective", effects = { Smarts = 2, Happiness = 3 }, feedText = "You're picky, but quality over quantity." },
			{ text = "Dating apps aren't for me", effects = { Happiness = 2 }, feedText = "You prefer meeting people organically." },
		},
	},
	{
		id = "chance_encounter",
		title = "Love at First Sight?",
		emoji = "💘",
		text = "You lock eyes with a stranger. There's an instant connection.",
		question = "What do you do?",
		minAge = 18, maxAge = 50,
		baseChance = 0.4,
		cooldown = 3,
		requiresSingle = true,
		-- CRITICAL FIX: Can't have chance encounters in prison!
		blockedByFlags = { in_prison = true, incarcerated = true },
		choices = {
			{ text = "Go talk to them", effects = { Happiness = 10, Looks = 2 }, setFlags = { has_partner = true, dating = true, met_cute = true }, feedText = "You made the first move!" },
			{ text = "Smile and hope they approach", effects = { Happiness = 5 }, feedText = "You shared a moment but didn't pursue." },
			{ text = "Too nervous to act", effects = { Happiness = -3 }, feedText = "The moment passed. What if...?" },
		},
	},
	{
		id = "new_friendship",
		title = "Potential Friend",
		emoji = "🤝",
		-- CRITICAL FIX: Dynamic friend name using {{FRIEND_NAME}} placeholder
		text = "You've been hitting it off with {{FRIEND_NAME}}. You two seem to really click!",
		question = "Could this be a new friendship?",
		minAge = 13, maxAge = 80,
		baseChance = 0.5,
		cooldown = 2,
		-- Dynamic text generation for the event
		getDynamicText = function(state)
			-- Generate a random name for the potential friend
			local names = state.Gender == "male" 
				and {"Emma", "Olivia", "Sophia", "Ava", "Isabella", "Mia", "Chloe", "Grace", "Lily", "Harper", "Jake", "Alex", "Sam", "Jordan", "Taylor"}
				or {"James", "Michael", "David", "John", "Alex", "Ryan", "Chris", "Jake", "Ethan", "Noah", "Emma", "Sam", "Jordan", "Taylor", "Morgan"}
			local name = names[math.random(1, #names)]
			return {
				text = string.format("You've been hitting it off with %s. You two seem to really click!", name),
				friendName = name,
			}
		end,
		choices = {
			{ 
				text = "Definitely - let's hang out more!", 
				effects = { Happiness = 8 }, 
				setFlags = { has_best_friend = true },
				feedText = "You made a new friend!",
				-- CRITICAL FIX: Create the friend relationship with the dynamic name
				onResolve = function(state, choice, event)
					local friendName = "New Friend"
					if event._dynamicData and event._dynamicData.friendName then
						friendName = event._dynamicData.friendName
					end
					-- Create friend relationship
					state.Relationships = state.Relationships or {}
					local friendId = "friend_" .. tostring(os.clock()):gsub("%.", "")
					state.Relationships[friendId] = {
						id = friendId,
						name = friendName,
						type = "friend",
						role = "Friend",
						relationship = 70,
						alive = true,
						metAt = state.Age or 0,
					}
					-- Update the feedText with the actual name
					choice.feedText = string.format("You became friends with %s!", friendName)
					if state.AddFeed then
						state:AddFeed(string.format("🤝 You made a new friend: %s!", friendName))
					end
				end,
			},
			{ text = "Take it slow", effects = { Happiness = 3 }, feedText = "You're cautiously optimistic about this friendship." },
			{ text = "I'm good on friends right now", effects = { }, feedText = "You decided not to pursue this friendship." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- COMMITTED RELATIONSHIP
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "relationship_milestone",
		title = "Getting Serious",
		emoji = "💕",
		text = "Your relationship is getting more serious.",
		question = "How do you feel about it?",
		minAge = 18, maxAge = 60,
		baseChance = 0.5,
		cooldown = 3,
		requiresPartner = true,
		requiresFlags = { dating = true },
		choices = {
			{ text = "I'm ready for commitment", effects = { Happiness = 10 }, setFlags = { committed_relationship = true }, feedText = "You're all in!" },
			{ text = "I need more time", effects = { Happiness = 2 }, feedText = "You're taking things slow." },
			{ text = "Maybe this isn't right", effects = { Happiness = -5 }, setFlags = { relationship_doubts = true }, feedText = "Doubts are creeping in." },
		},
	},
	{
		id = "move_in_together",
		title = "Living Together",
		emoji = "🏠",
		text = "{{PARTNER_NAME}} suggests moving in together. It's a big step!",
		question = "What's your decision?",
		minAge = 20, maxAge = 50,
		oneTime = true,
		requiresPartner = true,
		requiresFlags = { committed_relationship = true },
		choices = {
			{ text = "Yes! Let's do it!", effects = { Happiness = 10, Money = 500 }, setFlags = { lives_with_partner = true }, feedText = "You moved in together!" },
			{ text = "I'm not ready yet", effects = { Happiness = -3 }, feedText = "You need more time." },
			{ 
				text = "Break up instead", 
				effects = { Happiness = -10 }, 
				setFlags = { recently_single = true }, 
				feedText = "The conversation led to a breakup.",
				-- CRITICAL FIX: Properly clear all relationship flags on breakup
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.has_partner = nil
					state.Flags.dating = nil
					state.Flags.committed_relationship = nil
					state.Flags.engaged = nil
					state.Flags.married = nil
					state.Flags.lives_with_partner = nil
					if state.Relationships then
						state.Relationships.partner = nil
					end
				end,
			},
		},
	},
	{
		id = "proposal",
		title = "The Proposal",
		emoji = "💍",
		text = "You and {{PARTNER_NAME}} have been together for a while now. It feels like the right time to take the next step.",
		question = "Are you ready to pop the question?",
		minAge = 22, maxAge = 50,
		oneTime = true,
		requiresPartner = true,
		requiresFlags = { lives_with_partner = true },
		choices = {
			{ text = "Yes - plan the perfect proposal", effects = { Happiness = 15, Money = -2000 }, setFlags = { engaged = true }, feedText = "They said yes! You're engaged!" },
			{ text = "Simple and intimate", effects = { Happiness = 12, Money = -500 }, setFlags = { engaged = true }, feedText = "A quiet, perfect moment. You're engaged!" },
			{ text = "Not yet", effects = { Happiness = 2 }, feedText = "The timing isn't right." },
		},
	},
	{
		id = "wedding_day",
		title = "💒 Wedding Day!",
		emoji = "👰",
		text = "The big day has arrived!",
		question = "What kind of wedding do you have?",
		minAge = 22, maxAge = 60,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		-- CRITICAL FIX #6: Added "wedding" category for pink event card
		category = "wedding",
		requiresPartner = true,
		requiresFlags = { engaged = true },
		choices = {
			{ text = "Grand celebration", effects = { Happiness = 20, Money = -10000 }, setFlags = { married = true }, feedText = "An unforgettable wedding! You're married!" },
			{ text = "Intimate ceremony", effects = { Happiness = 15, Money = -2000 }, setFlags = { married = true }, feedText = "A beautiful, small wedding. You're married!" },
			{ text = "Courthouse wedding", effects = { Happiness = 10, Money = -200 }, setFlags = { married = true }, feedText = "Quick and official. You're married!" },
			{ text = "Elope!", effects = { Happiness = 12, Money = -1000 }, setFlags = { married = true, eloped = true }, feedText = "You eloped! Romantic and spontaneous!" },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- RELATIONSHIP CHALLENGES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "relationship_conflict",
		title = "Rough Patch",
		emoji = "💔",
		text = "You and {{PARTNER_NAME}} have been arguing a lot lately. Something's not right.",
		question = "How do you handle it?",
		minAge = 18, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		requiresPartner = true,
		choices = {
			{ text = "Communicate openly", effects = { Happiness = 5, Smarts = 2 }, feedText = "You talked it through. Things improved." },
			{ text = "Seek couples counseling", effects = { Happiness = 7, Money = -300 }, feedText = "Professional help made a difference." },
			{ text = "Give each other space", effects = { Happiness = 3 }, feedText = "Some distance helped." },
			{ 
				text = "It's time to break up", 
				effects = { Happiness = -8 }, 
				setFlags = { recently_single = true }, 
				feedText = "You ended the relationship.",
				-- CRITICAL FIX: Properly clear all relationship flags on breakup
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.has_partner = nil
					state.Flags.dating = nil
					state.Flags.married = nil
					state.Flags.engaged = nil
					state.Flags.lives_with_partner = nil
					state.Flags.committed_relationship = nil
					-- Clear partner from relationships
					if state.Relationships then
						state.Relationships.partner = nil
					end
				end,
			},
		},
	},
	{
		id = "partner_achievement",
		title = "Partner's Big Win",
		emoji = "🎉",
		text = "{{PARTNER_NAME}} achieved something amazing! Their success is incredible.",
		question = "How do you celebrate?",
		minAge = 20, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		requiresPartner = true,
		choices = {
			{ text = "Throw a celebration", effects = { Happiness = 10, Money = -200 }, feedText = "You celebrated together!" },
			{ text = "Heartfelt congratulations", effects = { Happiness = 8 }, feedText = "Your sincere joy meant everything to them." },
			{ text = "Feel a bit jealous", effects = { Happiness = -3 }, setFlags = { competitive_with_partner = true }, feedText = "You struggled with mixed feelings." },
		},
	},
	{
		id = "long_distance",
		title = "Long Distance Relationship",
		emoji = "🌍",
		text = "{{PARTNER_NAME}} has to move away for work/school. It would mean a long-distance relationship.",
		question = "Can you make it work?",
		minAge = 18, maxAge = 50,
		baseChance = 0.3,
		cooldown = 5,
		requiresPartner = true,
		choices = {
			{ text = "We'll make it work", effects = { Happiness = 3, Money = -500 }, setFlags = { long_distance = true }, feedText = "You're committed despite the distance." },
			{ text = "Move with them", effects = { Happiness = 8 }, setFlags = { relocated_for_love = true }, feedText = "You moved to stay together!" },
			{ 
				text = "Break up but stay friends", 
				effects = { Happiness = -5 }, 
				setFlags = { recently_single = true }, 
				feedText = "You ended it but remained friends.",
				-- CRITICAL FIX: Properly clear all relationship flags
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.has_partner = nil
					state.Flags.dating = nil
					state.Flags.committed_relationship = nil
					state.Flags.engaged = nil
					state.Flags.married = nil
					state.Flags.lives_with_partner = nil
					if state.Relationships then
						state.Relationships.partner = nil
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
		text = "You and {{PARTNER_NAME}} are discussing having children. It's a life-changing decision.",
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
				feedText = "Congratulations! You're having a baby!",
				-- CRITICAL FIX: Actually create the child in Relationships table!
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local names = isBoy and {"James", "Oliver", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Aiden"} 
						or {"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia", "Amelia", "Harper"}
					local childName = names[math.random(1, #names)]
					local childId = "child_" .. tostring(childCount)
					state.Relationships[childId] = {
						id = childId,
						name = childName,
						type = "family",
						role = isBoy and "Son" or "Daughter",
						relationship = 100,
						age = 0,
						gender = isBoy and "male" or "female",
						alive = true,
						isFamily = true,
						isChild = true,
					}
					if state.AddFeed then
						state:AddFeed(string.format("👶 Welcome to the world, %s!", childName))
					end
				end,
			},
			{ 
				text = "Adopt a child", 
				effects = { Happiness = 15, Money = -5000 }, 
				setFlags = { has_child = true, parent = true, adopted = true }, 
				feedText = "You adopted a child! What a beautiful choice!",
				-- CRITICAL FIX: Actually create the adopted child in Relationships table!
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local names = isBoy and {"James", "Oliver", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Aiden"} 
						or {"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia", "Amelia", "Harper"}
					local childName = names[math.random(1, #names)]
					local childId = "child_" .. tostring(childCount)
					local childAge = math.random(0, 5)  -- Adopted children can be ages 0-5
					state.Relationships[childId] = {
						id = childId,
						name = childName,
						type = "family",
						role = isBoy and "Son" or "Daughter",
						relationship = 85, -- Slightly lower initial bond for adopted
						age = childAge,
						gender = isBoy and "male" or "female",
						alive = true,
						isFamily = true,
						isChild = true,
						adopted = true,
					}
					if state.AddFeed then
						state:AddFeed(string.format("💕 You adopted %s (age %d)! Welcome to the family!", childName, childAge))
					end
				end,
			},
			{ text = "Not right now", effects = { Happiness = 2 }, feedText = "You're not ready for kids yet." },
			{ text = "We don't want children", effects = { Happiness = 5 }, setFlags = { childfree = true }, feedText = "You've decided to remain childfree." },
		},
	},
	{
		id = "parenting_challenge",
		title = "Parenting Dilemma",
		emoji = "👨‍👩‍👧",
		text = "Your child is going through a difficult phase.",
		question = "How do you handle it?",
		minAge = 28, maxAge = 60,
		baseChance = 0.5,
		cooldown = 2,
		requiresFlags = { parent = true },
		choices = {
			{ text = "Patient understanding", effects = { Happiness = 5, Smarts = 2 }, feedText = "Patience paid off." },
			{ text = "Strict discipline", effects = { Happiness = -2 }, feedText = "You laid down the law." },
			{ text = "Get professional advice", effects = { Happiness = 3, Money = -200 }, feedText = "Expert advice helped." },
			{ text = "Just hope they grow out of it", effects = { Happiness = 2 }, feedText = "Time heals many things." },
		},
	},
	{
		id = "child_achievement",
		title = "Proud Parent Moment",
		emoji = "🌟",
		text = "Your child did something amazing!",
		question = "How do you react?",
		minAge = 30, maxAge = 70,
		baseChance = 0.4,
		cooldown = 2,
		requiresFlags = { parent = true },
		choices = {
			{ text = "Celebrate with them", effects = { Happiness = 12 }, feedText = "You shared their joy!" },
			{ text = "Share it with everyone", effects = { Happiness = 8 }, feedText = "You proudly told everyone!" },
			{ text = "Keep encouraging them", effects = { Happiness = 8, Smarts = 2 }, feedText = "You used it as motivation." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- FAMILY RELATIONSHIPS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "sibling_rivalry",
		title = "Sibling Issues",
		emoji = "👊",
		text = "You and your sibling have been at odds lately.",
		question = "How do you deal with it?",
		minAge = 10, maxAge = 60,
		baseChance = 0.4,
		cooldown = 4,
		requiresFlags = { has_siblings = true },
		choices = {
			{ text = "Work it out together", effects = { Happiness = 5 }, feedText = "You reconciled with your sibling." },
			{ text = "Keep your distance", effects = { Happiness = 2 }, feedText = "Some space helped." },
			{ text = "Get parents involved", effects = { }, feedText = "Your parents tried to mediate." },
			{ text = "Accept differences", effects = { Happiness = 3, Smarts = 2 }, feedText = "You accepted that you're different." },
		},
	},
	{
		id = "parent_relationship",
		title = "Connecting with Parents",
		emoji = "👪",
		text = "Your relationship with your parents has been complicated.",
		question = "How do you approach it?",
		minAge = 18, maxAge = 50,
		baseChance = 0.3,
		cooldown = 5,
		choices = {
			{ text = "Make effort to connect", effects = { Happiness = 8 }, setFlags = { close_to_parents = true }, feedText = "You worked on your relationship with your parents." },
			{ text = "Set healthy boundaries", effects = { Happiness = 5, Smarts = 2 }, feedText = "You established boundaries." },
			{ text = "Accept the distance", effects = { Happiness = 2 }, feedText = "Not all families are close." },
			{ text = "Cut contact", effects = { Happiness = -5 }, setFlags = { estranged_from_parents = true }, feedText = "You distanced yourself completely." },
		},
	},
	{
		id = "family_reunion",
		title = "Family Gathering",
		emoji = "🎊",
		text = "There's a big family reunion happening.",
		question = "Will you attend?",
		minAge = 20, maxAge = 80,
		baseChance = 0.4,
		cooldown = 3,
		choices = {
			{ text = "Enthusiastically attend", effects = { Happiness = 8 }, feedText = "You had a great time with family!" },
			{ text = "Go reluctantly", effects = { Happiness = 2 }, feedText = "You showed up. That counts." },
			{ text = "Skip it this time", effects = { Happiness = 3 }, feedText = "You sat this one out." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- LOSS & GRIEF
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "loss_of_loved_one",
		title = "Difficult Goodbye",
		emoji = "🕯️",
		text = "Someone close to you has passed away.",
		question = "How do you cope with the loss?",
		minAge = 20, maxAge = 90,
		baseChance = 0.2,
		cooldown = 5,
		choices = {
			{ text = "Lean on others for support", effects = { Happiness = -5, Health = -2 }, feedText = "Grief is heavy, but you're not alone." },
			{ text = "Celebrate their life", effects = { Happiness = -3, Smarts = 2 }, feedText = "You chose to remember the good times." },
			{ text = "Struggle in silence", effects = { Happiness = -10, Health = -5 }, setFlags = { grief = true }, feedText = "You're struggling but hiding it." },
			{ text = "Seek professional help", effects = { Happiness = -3, Money = -200 }, feedText = "A therapist helped you process." },
		},
	},
	{
		id = "old_friend",
		title = "Reconnecting",
		emoji = "📱",
		text = "An old friend reaches out after years of no contact.",
		question = "Do you reconnect?",
		minAge = 25, maxAge = 80,
		baseChance = 0.4,
		cooldown = 3,
		choices = {
			{ text = "Absolutely!", effects = { Happiness = 8 }, feedText = "You reconnected with an old friend!" },
			{ text = "Cautiously yes", effects = { Happiness = 4 }, feedText = "You're giving it a try." },
			{ text = "Some bridges are meant to stay closed", effects = { Happiness = 2 }, feedText = "You chose not to reconnect." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- ADDITIONAL RELATIONSHIP EVENTS - AAA QUALITY EXPANSION
	-- ══════════════════════════════════════════════════════════════════════════════

	-- DATING EXPANSION
	{
		id = "first_date",
		title = "First Date Jitters",
		emoji = "☕",
		text = "You're going on a first date! How do you approach it?",
		question = "What's your game plan?",
		minAge = 15, maxAge = 55,
		baseChance = 0.5,
		cooldown = 2,
		requiresSingle = true,
		-- CRITICAL FIX: Random first date outcome
		choices = {
			{
				text = "Be confident and be yourself",
				effects = {},
				feedText = "You walked in with confidence...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local happiness = (state.Stats and state.Stats.Happiness) or 50
					local roll = math.random()
					local successChance = 0.35 + (looks / 200) + (happiness / 300)
					if roll < successChance then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						state.Flags.dating = true
						state.Flags.great_first_date = true
						state:AddFeed("☕ Amazing chemistry! Best first date ever! You're smitten.")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("☕ Nice enough, but no real spark. Probably won't call them.")
					else
						state:ModifyStat("Happiness", -4)
						state.Flags = state.Flags or {}
						state.Flags.bad_date_story = true
						state:AddFeed("☕ Awkward disaster. At least it's a funny story now.")
					end
				end,
			},
			{
				text = "Play it cool and mysterious",
				effects = {},
				feedText = "You tried to be mysterious...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local successChance = 0.25 + (looks / 150)
					if roll < successChance then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						state.Flags.dating = true
						state:AddFeed("☕ They found you intriguing! Chemistry is building.")
					elseif roll < successChance + 0.35 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("☕ They couldn't really read you. Mixed signals all around.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("☕ Being mysterious came off as disinterested. Oops.")
					end
				end,
			},
			{
				text = "Be nervous and overthink everything",
				effects = {},
				feedText = "Your nerves got the better of you...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.20 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						state.Flags.dating = true
						state:AddFeed("☕ They found your nervousness endearing! How sweet!")
					elseif roll < 0.50 then
						state:ModifyStat("Happiness", 1)
						state:AddFeed("☕ You were awkward but they were nice about it.")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("☕ Too nervous. The conversation was painful.")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("☕ They never showed up. Crushing.")
					end
				end,
			},
		},
	},
	{
		id = "ex_returns",
		title = "Blast from the Past",
		emoji = "💫",
		text = "Your ex has reached out wanting to reconnect.",
		question = "What do you do?",
		minAge = 18, maxAge = 55,
		baseChance = 0.2,
		cooldown = 5,

		choices = {
			{ text = "Give them another chance", effects = { Happiness = 5 }, setFlags = { back_with_ex = true, has_partner = true }, feedText = "You're giving it another shot..." },
			{ text = "Catch up but keep boundaries", effects = { Happiness = 3 }, feedText = "You caught up. Closure feels good." },
			{ text = "Block and ignore", effects = { Happiness = 5 }, setFlags = { over_ex = true }, feedText = "You're completely over them. Blocked!" },
			{ text = "Petty revenge - show them what they lost", effects = { Happiness = 8, Looks = 2 }, feedText = "You looked amazing. Their loss!" },
		},
	},
	{
		id = "speed_dating",
		title = "Speed Dating Event",
		emoji = "⏰",
		text = "A friend dragged you to a speed dating event. 5 minutes per person!",
		question = "What's your strategy?",
		minAge = 21, maxAge = 50,
		baseChance = 0.3,
		cooldown = 4,
		requiresSingle = true,
		-- CRITICAL FIX: Random speed dating outcome
		choices = {
			{
				text = "Try to make a real connection",
				effects = {},
				feedText = "You gave each person your genuine attention...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.30 + (looks / 200) + (smarts / 300)
					if roll < successChance then
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						state.Flags.dating = true
						state:AddFeed("⏰ You found a real connection in just 5 minutes!")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("⏰ Got a few numbers. We'll see where it goes.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("⏰ Nice people but no real spark with anyone.")
					end
				end,
			},
			{
				text = "Just have fun with it",
				effects = {},
				feedText = "You didn't take it too seriously...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						state.Flags.dating = true
						state:AddFeed("⏰ Someone loved your fun energy! You clicked!")
					elseif roll < 0.60 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("⏰ Fun night out! Made some potential friends too.")
					else
						state:ModifyStat("Happiness", 1)
						state:AddFeed("⏰ Entertaining evening but nobody caught your eye.")
					end
				end,
			},
			{
				text = "Leave early - this isn't for me",
				effects = { Happiness = -2 },
				feedText = "You couldn't handle the awkwardness and left.",
			},
		},
	},
	{
		id = "blind_date",
		title = "Blind Date",
		emoji = "🙈",
		text = "A friend set you up on a blind date. You don't know what they look like!",
		question = "Where do you meet?",
		minAge = 18, maxAge = 50,
		baseChance = 0.3,
		cooldown = 3,
		requiresSingle = true,
		-- CRITICAL FIX: Random blind date outcome
		choices = {
			{
				text = "A nice restaurant",
				effects = { Money = -50 },
				feedText = "You waited at the restaurant...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local successChance = 0.35 + (looks / 250)
					if roll < successChance then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						state.Flags.dating = true
						state.Flags.met_through_friend = true
						state:AddFeed("🙈 Love at first sight! Your friend knows you so well!")
					elseif roll < successChance + 0.30 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🙈 Nice person. Good conversation but no real spark.")
					elseif roll < successChance + 0.50 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🙈 Complete mismatch. What was your friend thinking?")
					else
						state:ModifyStat("Happiness", -8)
						state:AddFeed("🙈 They were creepy. Never trusting that friend's taste again!")
					end
				end,
			},
			{
				text = "A casual coffee shop",
				effects = { Money = -10 },
				feedText = "You met for coffee...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.has_partner = true
						state.Flags.dating = true
						state.Flags.met_through_friend = true
						state:AddFeed("🙈 Great connection! Easy conversation and good vibes.")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🙈 Pleasant coffee. Maybe friends, not romance.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🙈 Awkward silence. Long 30 minutes.")
					end
				end,
			},
			{
				text = "Cancel last minute - too nervous",
				effects = { Happiness = -3 },
				feedText = "You chickened out. Your friend is disappointed.",
			},
		},
	},

	-- RELATIONSHIP DRAMA
	{
		id = "caught_cheating",
		title = "Caught Cheating",
		emoji = "💔",
		text = "You discovered {{PARTNER_NAME}} has been cheating on you. Your heart is shattered.",
		question = "What do you do?",
		minAge = 18, maxAge = 70,
		baseChance = 0.15,
		cooldown = 10,
		requiresPartner = true,

		choices = {
			{ 
				text = "Confront them and break up", 
				effects = { Happiness = -20 }, 
				setFlags = { cheated_on = true, recently_single = true }, 
				feedText = "Your trust is shattered. Relationship over.",
				-- CRITICAL FIX: Properly clear all relationship flags
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.has_partner = nil
					state.Flags.dating = nil
					state.Flags.committed_relationship = nil
					state.Flags.engaged = nil
					state.Flags.married = nil
					state.Flags.lives_with_partner = nil
					if state.Relationships then
						state.Relationships.partner = nil
					end
				end,
			},
			{ text = "Try to work through it", effects = { Happiness = -15, Smarts = 2 }, setFlags = { cheated_on = true, rebuilding_trust = true }, feedText = "Trying to salvage the relationship..." },
			{ text = "Revenge affair", effects = { Happiness = -10 }, setFlags = { cheater = true, toxic_relationship = true }, feedText = "Two wrongs don't make a right, but..." },
			{ 
				text = "Walk away silently", 
				effects = { Happiness = -12 }, 
				setFlags = { cheated_on = true, recently_single = true }, 
				feedText = "You left without a word. Dignity intact.",
				-- CRITICAL FIX: Properly clear all relationship flags
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.has_partner = nil
					state.Flags.dating = nil
					state.Flags.committed_relationship = nil
					state.Flags.engaged = nil
					state.Flags.married = nil
					state.Flags.lives_with_partner = nil
					if state.Relationships then
						state.Relationships.partner = nil
					end
				end,
			},
		},
	},
	{
		id = "jealousy_issues",
		title = "Jealousy Problems",
		emoji = "😠",
		text = "Jealousy is causing issues in your relationship.",
		question = "Who's the jealous one?",
		minAge = 16, maxAge = 60,
		baseChance = 0.3,
		cooldown = 3,
		requiresPartner = true,

		choices = {
			{ text = "You are - and you're working on it", effects = { Happiness = -3, Smarts = 2 }, setFlags = { working_on_jealousy = true }, feedText = "Self-awareness is the first step." },
			{ text = "They are - it's suffocating", effects = { Happiness = -8 }, setFlags = { possessive_partner = true }, feedText = "Their jealousy is exhausting." },
			{ text = "Both of you need to improve", effects = { Happiness = -5 }, feedText = "Mutual growth is needed." },
			{ 
				text = "Time to break up", 
				effects = { Happiness = -10 }, 
				setFlags = { recently_single = true }, 
				feedText = "The jealousy ruined the relationship.",
				-- CRITICAL FIX: Properly clear all relationship flags
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.has_partner = nil
					state.Flags.dating = nil
					state.Flags.committed_relationship = nil
					state.Flags.engaged = nil
					state.Flags.married = nil
					state.Flags.lives_with_partner = nil
					if state.Relationships then
						state.Relationships.partner = nil
					end
				end,
			},
		},
	},
	{
		id = "partner_secret",
		title = "Partner's Secret",
		emoji = "🤫",
		text = "You discovered a major secret {{PARTNER_NAME}} has been keeping from you.",
		question = "What was it?",
		minAge = 20, maxAge = 70,
		baseChance = 0.2,
		cooldown = 5,
		requiresPartner = true,

		choices = {
			{ text = "Hidden debt", effects = { Happiness = -10, Money = -3000 }, setFlags = { partner_debt = true }, feedText = "They've been hiding serious financial problems." },
			{ text = "Secret family you didn't know about", effects = { Happiness = -15 }, setFlags = { partner_secret_family = true }, feedText = "They have a whole other life you didn't know about." },
			{ text = "A harmless surprise for you", effects = { Happiness = 10 }, feedText = "They were planning a surprise for you! Phew!" },
			{ text = "Past they're ashamed of", effects = { Happiness = -5, Smarts = 2 }, feedText = "Their past is complicated but you understand." },
		},
	},
	{
		id = "anniversary",
		title = "Anniversary",
		emoji = "💕",
		text = "It's your anniversary!",
		question = "How do you celebrate?",
		minAge = 20, maxAge = 90,
		baseChance = 0.5,
		cooldown = 2,
		requiresPartner = true,

		choices = {
			{ text = "Romantic getaway", effects = { Happiness = 15, Money = -1500, Health = 3 }, feedText = "A perfect anniversary trip!" },
			{ text = "Fancy dinner", effects = { Happiness = 10, Money = -300 }, feedText = "Romantic dinner at your favorite spot." },
			{ text = "Thoughtful homemade gift", effects = { Happiness = 12, Smarts = 2 }, feedText = "Your handmade gift meant everything to them." },
			{ text = "You forgot...", effects = { Happiness = -15 }, setFlags = { forgot_anniversary = true }, feedText = "You forgot your anniversary. Big trouble." },
		},
	},
	{
		id = "in_laws",
		title = "In-Law Drama",
		emoji = "👨‍👩‍👦",
		text = "Your in-laws are causing problems.",
		question = "What's the issue?",
		minAge = 22, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		requiresFlags = { married = true },

		choices = {
			{ text = "They don't approve of you", effects = { Happiness = -8 }, setFlags = { inlaw_problems = true }, feedText = "You'll never be good enough for them." },
			{ text = "They're too involved in your life", effects = { Happiness = -6 }, feedText = "Boundaries don't exist for them." },
			{ text = "They favor other siblings", effects = { Happiness = -5 }, feedText = "The favoritism is obvious and hurtful." },
			{ text = "Actually, they adore you!", effects = { Happiness = 8 }, setFlags = { loved_by_inlaws = true }, feedText = "You lucked out with amazing in-laws!" },
		},
	},
	{
		id = "marriage_proposal_received",
		title = "They Proposed!",
		emoji = "💍",
		text = "{{PARTNER_NAME}} just proposed to you! This is such a surprise!",
		question = "What do you say?",
		minAge = 20, maxAge = 55,
		oneTime = true,
		requiresPartner = true,
		requiresFlags = { committed_relationship = true },

		choices = {
			{ text = "YES! A thousand times yes!", effects = { Happiness = 20 }, setFlags = { engaged = true }, feedText = "You said yes! You're engaged!" },
			{ text = "Yes, but need a long engagement", effects = { Happiness = 12 }, setFlags = { engaged = true, long_engagement = true }, feedText = "You said yes but want to take it slow." },
			{ text = "I'm not ready yet", effects = { Happiness = -10 }, feedText = "You said no... for now. Awkward." },
			{ 
				text = "We need to break up", 
				effects = { Happiness = -15 }, 
				setFlags = { recently_single = true }, 
				feedText = "This made you realize it's not right.",
				-- CRITICAL FIX: Properly clear all relationship flags
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.has_partner = nil
					state.Flags.dating = nil
					state.Flags.committed_relationship = nil
					state.Flags.engaged = nil
					state.Flags.married = nil
					state.Flags.lives_with_partner = nil
					if state.Relationships then
						state.Relationships.partner = nil
					end
				end,
			},
		},
	},

	-- FRIENDSHIP EVENTS
	{
		id = "friend_betrayal",
		title = "Friend Betrayal",
		emoji = "🗡️",
		text = "A close friend betrayed your trust.",
		question = "What did they do?",
		minAge = 13, maxAge = 70,
		baseChance = 0.2,
		cooldown = 5,
		requiresFlags = { has_best_friend = true },

		choices = {
			{ text = "Shared your secrets", effects = { Happiness = -12 }, setFlags = { betrayed_by_friend = true }, feedText = "They told everyone your private business." },
			{ text = "Stole from you", effects = { Happiness = -15, Money = -500 }, setFlags = { betrayed_by_friend = true }, feedText = "They stole money from you. Unforgivable." },
			{ text = "Dated your ex", effects = { Happiness = -10 }, setFlags = { betrayed_by_friend = true }, feedText = "They broke the friend code." },
			{ text = "Talked behind your back", effects = { Happiness = -8 }, feedText = "You heard what they really think of you." },
		},
		onComplete = function(state)
			state.Flags = state.Flags or {}
			state.Flags.has_best_friend = nil
		end,
	},
	{
		-- CRITICAL FIX: Was god-mode - player picked what drama happened!
		-- Now drama type is random, player chooses how to respond
		id = "friend_group_drama",
		title = "Friend Group Drama",
		emoji = "👯",
		text = "Drama has erupted in your friend group. Two people are fighting.",
		question = "What do you do?",
		minAge = 13, maxAge = 50,
		baseChance = 0.4,
		cooldown = 3,

		choices = {
			{ 
				text = "Try to mediate", 
				effects = { },
				feedText = "You tried to help...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					if roll <= 40 then
						-- Success
						if state.ModifyStat then
							state:ModifyStat("Happiness", 8)
							state:ModifyStat("Smarts", 2)
						end
						if state.AddFeed then
							state:AddFeed("👯 You mediated successfully! The group is stronger now.")
						end
					elseif roll <= 70 then
						-- Got dragged into it
						if state.ModifyStat then
							state:ModifyStat("Happiness", -5)
						end
						if state.AddFeed then
							state:AddFeed("👯 You got dragged into the drama. Had to pick a side.")
						end
					else
						-- Made it worse
						state.Flags.losing_friends = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", -8)
						end
						if state.AddFeed then
							state:AddFeed("👯 Your mediation backfired. Now everyone's mad.")
						end
					end
				end,
			},
			{ text = "Stay out of it", effects = { Happiness = -2 }, feedText = "You stayed neutral. Some friends appreciated that." },
			{ text = "Pick a side", effects = { Happiness = -4 }, feedText = "You chose a side. Hope it was the right one." },
		},
	},
	{
		id = "toxic_friendship",
		title = "Toxic Friendship",
		emoji = "☢️",
		text = "A friendship has become toxic and draining.",
		question = "What do you do?",
		minAge = 15, maxAge = 60,
		baseChance = 0.3,
		cooldown = 4,

		choices = {
			{ text = "Cut them off completely", effects = { Happiness = 5, Health = 3 }, setFlags = { ended_toxic_friendship = true }, feedText = "You're free from that negativity!" },
			{ text = "Distance yourself gradually", effects = { Happiness = 3 }, feedText = "You're slowly pulling away." },
			{ text = "Try to fix the friendship", effects = { Happiness = -3, Smarts = 2 }, feedText = "You're trying to work it out." },
			{ text = "Keep enabling the toxicity", effects = { Happiness = -8, Health = -3 }, feedText = "This friendship is draining you." },
		},
	},
	{
		id = "best_friend_forever",
		title = "BFF Moment",
		emoji = "👯‍♀️",
		text = "You and your best friend had an amazing experience together.",
		question = "What happened?",
		minAge = 10, maxAge = 80,
		baseChance = 0.4,
		cooldown = 2,
		requiresFlags = { has_best_friend = true },

		choices = {
			{ text = "Epic adventure together", effects = { Happiness = 12, Health = 3 }, feedText = "You'll remember this forever!" },
			{ text = "They helped you through tough times", effects = { Happiness = 10, Smarts = 2 }, feedText = "True friends are there when it matters." },
			{ text = "Deep heart-to-heart conversation", effects = { Happiness = 8 }, feedText = "You've never felt closer to them." },
			{ text = "Laughed until you cried", effects = { Happiness = 10 }, feedText = "Inside jokes for life!" },
		},
	},

	-- FAMILY EXPANSION
	{
		id = "parent_divorce",
		title = "Parents Divorcing",
		emoji = "💔",
		text = "Your parents are getting divorced.",
		question = "How do you handle it?",
		minAge = 8, maxAge = 40,
		oneTime = true,
		-- CRITICAL FIX: Block if parents already divorced
		blockedByFlags = { parents_divorced = true },

		choices = {
			{ text = "Devastated - your world is crashing", effects = { Happiness = -20, Health = -5 }, setFlags = { parents_divorced = true }, feedText = "Your family is falling apart." },
			{ text = "Saw it coming - maybe for the best", effects = { Happiness = -8 }, setFlags = { parents_divorced = true }, feedText = "It's sad but not surprising." },
			{ text = "Stuck in the middle - both want your support", effects = { Happiness = -15 }, setFlags = { parents_divorced = true, caught_in_middle = true }, feedText = "They're putting you in impossible positions." },
			{ text = "Try to bring them back together", effects = { Happiness = -10 }, setFlags = { parents_divorced = true }, feedText = "You tried but couldn't save their marriage." },
		},
		
		-- CRITICAL FIX: Actually update parent relationship statuses
		onComplete = function(state, choice, eventDef, outcome)
			-- Mark both parents as divorced/separated
			if state.Relationships then
				local mother = state.Relationships["mother"]
				local father = state.Relationships["father"]
				
				if mother then
					mother.status = "divorced"
					mother.maritalStatus = "Divorced"
					mother.divorced = true
					-- Reduce relationship with non-custodial parent
					if mother.relationship then
						mother.relationship = math.max(20, mother.relationship - 10)
					end
				end
				
				if father then
					father.status = "divorced"
					father.maritalStatus = "Divorced"
					father.divorced = true
					-- Father often becomes less present after divorce
					if father.relationship then
						father.relationship = math.max(10, father.relationship - 15)
					end
				end
				
				-- Add feed entry about the separation
				if state.AddFeed then
					state:AddFeed("💔 Your parents have separated. Your family dynamic has changed.")
				end
			end
		end,
	},
	{
		id = "sibling_success",
		title = "Sibling's Big Success",
		emoji = "🌟",
		text = "Your sibling achieved something major.",
		question = "How do you feel?",
		minAge = 15, maxAge = 70,
		baseChance = 0.3,
		cooldown = 4,
		requiresFlags = { has_siblings = true },

		choices = {
			{ text = "Genuinely proud and happy for them", effects = { Happiness = 8 }, feedText = "You celebrated their success wholeheartedly!" },
			{ text = "Happy but a bit jealous", effects = { Happiness = 3 }, setFlags = { sibling_jealousy = true }, feedText = "Why can't you have that success?" },
			{ text = "It's always about them", effects = { Happiness = -5 }, setFlags = { overlooked_sibling = true }, feedText = "You feel invisible in comparison." },
			{ text = "Inspired to achieve your own goals", effects = { Happiness = 6, Smarts = 2 }, feedText = "Their success motivated you!" },
		},
	},
	{
		id = "family_secret",
		title = "Family Secret Revealed",
		emoji = "🤫",
		text = "You discovered a major family secret.",
		question = "What was it?",
		minAge = 18, maxAge = 70,
		baseChance = 0.15,
		cooldown = 10,

		choices = {
			{ text = "You were adopted", effects = { Happiness = -15, Smarts = 2 }, setFlags = { discovered_adopted = true }, feedText = "Your whole identity is in question now." },
			{ text = "A relative has a secret life", effects = { Happiness = -5 }, feedText = "They've been living a double life." },
			{ text = "Hidden family wealth", effects = { Happiness = 8, Money = 5000 }, setFlags = { family_inheritance = true }, feedText = "There was money you never knew about!" },
			{ text = "Dark family history", effects = { Happiness = -10 }, setFlags = { dark_family_secret = true }, feedText = "Some things were better left buried." },
		},
	},
	{
		id = "parent_remarriage",
		title = "Parent Remarrying",
		emoji = "💒",
		text = "Your parent is getting remarried.",
		question = "How do you feel about your new step-parent?",
		minAge = 10, maxAge = 50,
		baseChance = 0.3,
		cooldown = 10,
		requiresFlags = { parents_divorced = true },

		choices = {
			{ text = "They're amazing - welcome to the family!", effects = { Happiness = 10 }, setFlags = { good_stepparent = true }, feedText = "You gained a wonderful step-parent!" },
			{ text = "They're okay, time will tell", effects = { Happiness = 2 }, feedText = "You're giving them a chance." },
			{ text = "You don't like them", effects = { Happiness = -8 }, setFlags = { bad_stepparent = true }, feedText = "This is going to be difficult." },
			{ text = "Refuse to accept them", effects = { Happiness = -10 }, setFlags = { rejected_stepparent = true }, feedText = "You can't accept this new family dynamic." },
		},
	},
	{
		id = "surprise_pregnancy",
		title = "Surprise Pregnancy",
		emoji = "🍼",
		text = "There's an unexpected pregnancy!",
		question = "How do you react?",
		minAge = 16, maxAge = 45,
		baseChance = 0.15,
		cooldown = 5,

		choices = {
			{ 
				text = "Unexpected but excited!", 
				effects = { Happiness = 10, Money = -2000 }, 
				setFlags = { has_child = true, parent = true, unplanned_pregnancy = true }, 
				feedText = "Surprise! You're having a baby!",
				-- CRITICAL FIX: Actually create the child in Relationships table!
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local names = isBoy and {"James", "Oliver", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Aiden"} 
						or {"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia", "Amelia", "Harper"}
					local childName = names[math.random(1, #names)]
					local childId = "child_" .. tostring(childCount)
					state.Relationships[childId] = {
						id = childId,
						name = childName,
						type = "family",
						role = isBoy and "Son" or "Daughter",
						relationship = 100,
						age = 0,
						gender = isBoy and "male" or "female",
						alive = true,
						isFamily = true,
						isChild = true,
					}
				end,
			},
			{ 
				text = "Terrified but accepting", 
				effects = { Happiness = -5, Money = -2000 }, 
				setFlags = { has_child = true, parent = true, unplanned_pregnancy = true }, 
				feedText = "Ready or not, here comes baby.",
				-- CRITICAL FIX: Actually create the child in Relationships table!
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local childCount = (state.ChildCount or 0) + 1
					state.ChildCount = childCount
					local isBoy = math.random() > 0.5
					local names = isBoy and {"James", "Oliver", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Aiden"} 
						or {"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia", "Amelia", "Harper"}
					local childName = names[math.random(1, #names)]
					local childId = "child_" .. tostring(childCount)
					state.Relationships[childId] = {
						id = childId,
						name = childName,
						type = "family",
						role = isBoy and "Son" or "Daughter",
						relationship = 90,
						age = 0,
						gender = isBoy and "male" or "female",
						alive = true,
						isFamily = true,
						isChild = true,
					}
				end,
			},
			{ text = "Not ready - considering options", effects = { Happiness = -10 }, setFlags = { difficult_decision = true }, feedText = "This is a life-changing decision." },
			{ text = "It's not yours/didn't happen", effects = { Happiness = 3 }, feedText = "False alarm or not your situation." },
		},
	},
	{
		id = "fertility_struggle",
		title = "Fertility Struggles",
		emoji = "💔",
		text = "You and {{PARTNER_NAME}} are struggling to conceive. It's an emotional journey.",
		question = "What do you do?",
		minAge = 25, maxAge = 45,
		baseChance = 0.2,
		cooldown = 5,
		requiresPartner = true,
		requiresFlags = { trying_for_baby = true },

		choices = {
			{ text = "Keep trying naturally", effects = { Happiness = -5 }, feedText = "The waiting and hoping continues." },
			{ text = "Pursue fertility treatments", effects = { Happiness = -3, Money = -10000 }, setFlags = { fertility_treatment = true }, feedText = "You're exploring medical options." },
			{ text = "Consider adoption", effects = { Happiness = 3 }, setFlags = { considering_adoption = true }, feedText = "There are other ways to build a family." },
			{ text = "Accept it might not happen", effects = { Happiness = -8 }, setFlags = { accepted_childless = true }, feedText = "Coming to terms with this possibility." },
		},
	},
	{
		id = "multiple_babies",
		title = "Twins/Triplets!",
		emoji = "👶👶",
		text = "Surprise - it's multiples!",
		question = "How do you handle this news?",
		minAge = 20, maxAge = 45,
		oneTime = true,
		requiresFlags = { trying_for_baby = true },

		choices = {
			{ 
				text = "Double/triple the joy!", 
				effects = { Happiness = 15, Money = -5000, Health = -5 }, 
				setFlags = { has_child = true, parent = true, has_multiples = true }, 
				feedText = "Multiples! Exhausting but amazing!",
				-- CRITICAL FIX: Actually create twin/triplet children in Relationships table!
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local numBabies = math.random() > 0.7 and 3 or 2 -- 30% triplets, 70% twins
					local boyNames = {"James", "Oliver", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Aiden"}
					local girlNames = {"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia", "Amelia", "Harper"}
					local usedNames = {}
					for i = 1, numBabies do
						local childCount = (state.ChildCount or 0) + 1
						state.ChildCount = childCount
						local isBoy = math.random() > 0.5
						local names = isBoy and boyNames or girlNames
						local childName
						repeat
							childName = names[math.random(1, #names)]
						until not usedNames[childName]
						usedNames[childName] = true
						local childId = "child_" .. tostring(childCount)
						state.Relationships[childId] = {
							id = childId,
							name = childName,
							type = "family",
							role = isBoy and "Son" or "Daughter",
							relationship = 100,
							age = 0,
							gender = isBoy and "male" or "female",
							alive = true,
							isFamily = true,
							isChild = true,
							isMultiple = true,
						}
					end
				end,
			},
			{ 
				text = "Overwhelmed but hopeful", 
				effects = { Happiness = 5, Money = -5000, Health = -8 }, 
				setFlags = { has_child = true, parent = true, has_multiples = true }, 
				feedText = "You're going to need a lot of help...",
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local numBabies = 2 -- Twins
					local boyNames = {"James", "Oliver", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Aiden"}
					local girlNames = {"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia", "Amelia", "Harper"}
					local usedNames = {}
					for i = 1, numBabies do
						local childCount = (state.ChildCount or 0) + 1
						state.ChildCount = childCount
						local isBoy = math.random() > 0.5
						local names = isBoy and boyNames or girlNames
						local childName
						repeat
							childName = names[math.random(1, #names)]
						until not usedNames[childName]
						usedNames[childName] = true
						local childId = "child_" .. tostring(childCount)
						state.Relationships[childId] = {
							id = childId,
							name = childName,
							type = "family",
							role = isBoy and "Son" or "Daughter",
							relationship = 85,
							age = 0,
							gender = isBoy and "male" or "female",
							alive = true,
							isFamily = true,
							isChild = true,
							isMultiple = true,
						}
					end
				end,
			},
			{ 
				text = "Terrified - how will we manage?", 
				effects = { Happiness = -5, Money = -5000, Health = -5 }, 
				setFlags = { has_child = true, parent = true, has_multiples = true, overwhelmed_parent = true }, 
				feedText = "Two/three at once? Deep breaths...",
				onResolve = function(state)
					state.Relationships = state.Relationships or {}
					local numBabies = 2 -- Twins
					local boyNames = {"James", "Oliver", "Ethan", "Noah", "Liam", "Mason", "Lucas", "Aiden"}
					local girlNames = {"Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia", "Amelia", "Harper"}
					local usedNames = {}
					for i = 1, numBabies do
						local childCount = (state.ChildCount or 0) + 1
						state.ChildCount = childCount
						local isBoy = math.random() > 0.5
						local names = isBoy and boyNames or girlNames
						local childName
						repeat
							childName = names[math.random(1, #names)]
						until not usedNames[childName]
						usedNames[childName] = true
						local childId = "child_" .. tostring(childCount)
						state.Relationships[childId] = {
							id = childId,
							name = childName,
							type = "family",
							role = isBoy and "Son" or "Daughter",
							relationship = 70,
							age = 0,
							gender = isBoy and "male" or "female",
							alive = true,
							isFamily = true,
							isChild = true,
							isMultiple = true,
						}
					end
				end,
			},
		},
	},
	{
		-- CRITICAL FIX: This was god-mode - player picked what trouble child got into!
		-- Now the trouble is random and player chooses how to respond
		id = "child_trouble",
		title = "Child in Trouble",
		emoji = "😰",
		text = "The school called. Your child got into trouble.",
		question = "How do you handle it?",
		minAge = 30, maxAge = 60,
		baseChance = 0.2,
		cooldown = 5,
		requiresFlags = { parent = true },

		choices = {
			{ 
				text = "Rush to the school immediately", 
				effects = { },
				feedText = "You dropped everything and rushed to school...",
				onResolve = function(state)
					-- CRITICAL FIX: Random trouble type
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					
					if roll <= 25 then
						-- Caught doing something illegal
						state.Flags.child_delinquent = true
						state.Money = (state.Money or 0) - 2000
						if state.ModifyStat then
							state:ModifyStat("Happiness", -15)
						end
						if state.AddFeed then
							state:AddFeed("😰 They were caught shoplifting! Legal fees and serious talks ahead.")
						end
					elseif roll <= 50 then
						-- Failing at school
						if state.ModifyStat then
							state:ModifyStat("Happiness", -8)
						end
						if state.AddFeed then
							state:AddFeed("😰 Their grades have been slipping badly. Time for intervention.")
						end
					elseif roll <= 75 then
						-- Bad crowd
						state.Flags.child_bad_influences = true
						if state.ModifyStat then
							state:ModifyStat("Happiness", -10)
						end
						if state.AddFeed then
							state:AddFeed("😰 They've been hanging with a troublesome crowd. You're worried.")
						end
					else
						-- Fighting
						state.Money = (state.Money or 0) - 500
						if state.ModifyStat then
							state:ModifyStat("Happiness", -12)
						end
						if state.AddFeed then
							state:AddFeed("😰 They got into a fight at school. Suspended for 3 days.")
						end
					end
				end,
			},
			{ text = "Let your partner handle it", effects = { Happiness = -5 }, feedText = "You delegated this one." },
			{ text = "Ignore the call - they'll figure it out", effects = { Happiness = -3 }, setFlags = { distant_parent = true }, feedText = "Maybe not your best parenting moment." },
		},
	},
	{
		id = "child_leaves_home",
		title = "Child Moves Out",
		emoji = "🏠",
		text = "Your child is moving out on their own.",
		question = "How do you feel?",
		minAge = 40, maxAge = 70,
		oneTime = true,
		requiresFlags = { parent = true },

		choices = {
			{ text = "So proud of them!", effects = { Happiness = 10 }, setFlags = { empty_nester = true }, feedText = "They're ready for the world!" },
			{ text = "Sad to see them go", effects = { Happiness = -8 }, setFlags = { empty_nester = true }, feedText = "The house feels so empty now." },
			{ text = "Finally! Some peace and quiet!", effects = { Happiness = 8 }, setFlags = { empty_nester = true }, feedText = "You're enjoying the freedom!" },
			{ text = "Worried they're not ready", effects = { Happiness = -5 }, setFlags = { empty_nester = true, worried_parent = true }, feedText = "Are they really prepared for this?" },
		},
	},
	{
		id = "relationship_rekindled",
		title = "Old Flame Returns",
		emoji = "🔥",
		text = "Someone from your past wants to rekindle romance.",
		question = "What do you do?",
		minAge = 25, maxAge = 65,
		baseChance = 0.2,
		cooldown = 6,
		blockedByFlags = { married = true },

		choices = {
			{ text = "Give love another chance", effects = { Happiness = 10 }, setFlags = { has_partner = true, rekindled_love = true }, feedText = "Second time's the charm?" },
			{ text = "Too much history - say no", effects = { Happiness = 2, Smarts = 2 }, feedText = "You've moved on and won't go back." },
			{ text = "Be friends only", effects = { Happiness = 5 }, feedText = "Friendship is all you can offer now." },
			{ text = "It reawakens old pain", effects = { Happiness = -8 }, feedText = "Some doors are best left closed." },
		},
	},
	{
		id = "vow_renewal",
		title = "Renewing Vows",
		emoji = "💍",
		text = "You're considering renewing your wedding vows.",
		question = "How do you celebrate?",
		minAge = 35, maxAge = 80,
		baseChance = 0.3,
		cooldown = 10,
		requiresFlags = { married = true },

		choices = {
			{ text = "Grand vow renewal ceremony", effects = { Happiness = 15, Money = -5000 }, feedText = "A beautiful celebration of your love!" },
			{ text = "Intimate just-us moment", effects = { Happiness = 12 }, feedText = "Private and perfect." },
			{ text = "Destination vow renewal", effects = { Happiness = 18, Money = -8000 }, feedText = "Renewed your vows in paradise!" },
			{ text = "Not necessary - we know we love each other", effects = { Happiness = 5 }, feedText = "Actions speak louder than ceremonies." },
		},
	},
}

return Relationships
