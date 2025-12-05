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
		text = "You've been hitting it off with someone you recently met.",
		question = "Could this be a new friendship?",
		minAge = 13, maxAge = 80,
		baseChance = 0.5,
		cooldown = 2,
		choices = {
			{ text = "Definitely - let's hang out more", effects = { Happiness = 8 }, setFlags = { has_best_friend = true }, feedText = "You made a new friend!" },
			{ text = "Take it slow", effects = { Happiness = 3 }, feedText = "You're cautiously optimistic." },
			{ text = "I'm good on friends", effects = { }, feedText = "You have enough friends." },
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
		text = "Your partner suggests moving in together.",
		question = "What's your decision?",
		minAge = 20, maxAge = 50,
		oneTime = true,
		requiresPartner = true,
		requiresFlags = { committed_relationship = true },
		choices = {
			{ text = "Yes! Let's do it!", effects = { Happiness = 10, Money = 500 }, setFlags = { lives_with_partner = true }, feedText = "You moved in together!" },
			{ text = "I'm not ready yet", effects = { Happiness = -3 }, feedText = "You need more time." },
			{ text = "Break up instead", effects = { Happiness = -10 }, setFlags = { recently_single = true, has_partner = false, dating = false }, feedText = "The conversation led to a breakup." },
		},
	},
	{
		id = "proposal",
		title = "The Proposal",
		emoji = "💍",
		text = "It feels like the right time. Should you propose?",
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
		title = "Wedding Day",
		emoji = "👰",
		text = "The big day has arrived!",
		question = "What kind of wedding do you have?",
		minAge = 22, maxAge = 60,
		oneTime = true,
		priority = "high",
		isMilestone = true,
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
		text = "You and your partner have been arguing a lot lately.",
		question = "How do you handle it?",
		minAge = 18, maxAge = 70,
		baseChance = 0.4,
		cooldown = 3,
		requiresPartner = true,
		choices = {
			{ text = "Communicate openly", effects = { Happiness = 5, Smarts = 2 }, feedText = "You talked it through. Things improved." },
			{ text = "Seek couples counseling", effects = { Happiness = 7, Money = -300 }, feedText = "Professional help made a difference." },
			{ text = "Give each other space", effects = { Happiness = 3 }, feedText = "Some distance helped." },
			{ text = "It's time to break up", effects = { Happiness = -8 }, setFlags = { recently_single = true, has_partner = false, dating = false, married = false }, feedText = "You ended the relationship." },
		},
	},
	{
		id = "partner_achievement",
		title = "Partner's Big Win",
		emoji = "🎉",
		text = "Your partner achieved something amazing!",
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
		text = "Your partner has to move away for work/school. It will be long distance.",
		question = "Can you make it work?",
		minAge = 18, maxAge = 50,
		baseChance = 0.3,
		cooldown = 5,
		requiresPartner = true,
		choices = {
			{ text = "We'll make it work", effects = { Happiness = 3, Money = -500 }, setFlags = { long_distance = true }, feedText = "You're committed despite the distance." },
			{ text = "Move with them", effects = { Happiness = 8 }, setFlags = { relocated_for_love = true }, feedText = "You moved to stay together!" },
			{ text = "Break up but stay friends", effects = { Happiness = -5 }, setFlags = { recently_single = true, has_partner = false }, feedText = "You ended it but remained friends." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- FAMILY & CHILDREN
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "having_child",
		title = "Starting a Family",
		emoji = "👶",
		text = "You and your partner are discussing having children.",
		question = "What do you decide?",
		minAge = 25, maxAge = 45,
		oneTime = true,
		requiresPartner = true,
		requiresFlags = { married = true },
		choices = {
			{ text = "Let's have a baby!", effects = { Happiness = 15, Money = -3000 }, setFlags = { has_child = true, parent = true }, feedText = "Congratulations! You're having a baby!" },
			{ text = "Adopt a child", effects = { Happiness = 15, Money = -5000 }, setFlags = { has_child = true, parent = true, adopted = true }, feedText = "You adopted a child! What a beautiful choice!" },
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
			{ text = "Make effort to connect", effects = { Happiness = 8 }, setFlags = { close_to_parents = true }, feedText = "You worked on your relationship with them." },
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
}

return Relationships
