--[[
    Family Events
    Events related to family relationships, parenting, and family milestones
    All events use randomized outcomes - NO god mode
]]

local FamilyEvents = {}

local STAGE = "random"

FamilyEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- PARENTING EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "family_pregnancy_news",
		title = "Pregnancy News",
		emoji = "🤰",
		text = "There's big pregnancy news!",
		question = "What's the situation?",
		minAge = 18, maxAge = 45,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "pregnancy", "baby", "family" },
		requiresPartner = true,
		
		-- CRITICAL: Random pregnancy outcome
		choices = {
			{
				text = "We're expecting!",
				effects = {},
				feedText = "Processing the big news...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.expecting = true
						state.Stats = state.Stats or {}
						state.Stats.ChildCount = (state.Stats.ChildCount or 0) + 1
						state:AddFeed("🤰 BABY ON THE WAY! Overjoyed! Life about to change!")
					else
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.expecting = true
						state.Stats = state.Stats or {}
						state.Stats.ChildCount = (state.Stats.ChildCount or 0) + 1
						state:AddFeed("🤰 Pregnant! Excited and terrified! Ready or not!")
					end
				end,
			},
			{ text = "Unexpected pregnancy", effects = { Happiness = -2, Money = -200 }, setFlags = { unexpected_pregnancy = true }, feedText = "🤰 Not planned but happening. Adjusting expectations." },
			{ text = "False alarm", effects = { Happiness = 2 }, feedText = "🤰 Thought we were pregnant. Mixed emotions about negative test." },
		},
	},
	{
		id = "family_birth",
		title = "Baby Arrives!",
		emoji = "👶",
		text = "The baby is coming!",
		question = "How does the birth go?",
		minAge = 18, maxAge = 50,
		baseChance = 0.8,
		cooldown = 10,
		oneTime = false,
		stage = STAGE,
		ageBand = "adult",
		category = "milestone",
		tags = { "birth", "baby", "milestone" },
		requiresFlags = { expecting = true },
		
		-- CRITICAL: Random birth outcome
		choices = {
			{
				text = "Welcome the new arrival",
				effects = { Money = -1000 },
				feedText = "In the delivery room...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 20)
						state.Flags = state.Flags or {}
						state.Flags.expecting = nil
						state.Flags.new_parent = true
						state:AddFeed("👶 HEALTHY BABY! Perfect delivery! Overwhelming love!")
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Health", -3)
						state.Flags = state.Flags or {}
						state.Flags.expecting = nil
						state.Flags.new_parent = true
						state:AddFeed("👶 Baby is here! Difficult delivery but everyone's okay!")
					else
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Health", -8)
						state.Money = (state.Money or 0) - 2000
						state.Flags = state.Flags or {}
						state.Flags.expecting = nil
						state.Flags.new_parent = true
						state.Flags.nicu_baby = true
						state:AddFeed("👶 Complications. Baby in NICU. Scary but hopeful.")
					end
				end,
			},
		},
	},
	{
		id = "family_newborn_phase",
		title = "Newborn Life",
		emoji = "🍼",
		text = "The newborn phase is intense!",
		question = "How are you handling it?",
		minAge = 18, maxAge = 55,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "newborn", "parenting", "baby" },
		requiresFlags = { new_parent = true },
		
		-- CRITICAL: Random newborn experience
		choices = {
			{
				text = "Survive on no sleep",
				effects = {},
				feedText = "Up all night with baby...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", -3)
						state:AddFeed("🍼 Exhausted but bonding moments make it worth it!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Health", -5)
						state:AddFeed("🍼 So tired. Crying (you and baby). This is HARD.")
					else
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Health", -2)
						state.Flags = state.Flags or {}
						state.Flags.good_baby = true
						state:AddFeed("🍼 Lucky - baby sleeps well! Parents envy you!")
					end
				end,
			},
			{ text = "Get help from family", effects = { Happiness = 4, Health = 1 }, feedText = "🍼 Grandparents to the rescue! Grateful for the support!" },
			{ text = "Hire night nurse", effects = { Money = -500, Happiness = 6, Health = 4 }, feedText = "🍼 Worth every penny. SLEEP!" },
		},
	},
	{
		id = "family_child_milestone",
		title = "Child Development Milestone",
		emoji = "🌟",
		text = "Your child reached a milestone!",
		question = "What did they achieve?",
		minAge = 20, maxAge = 60,
		baseChance = 0.3,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "milestone", "child", "parenting" },
		
		eligibility = function(state)
			local childCount = (state.Stats and state.Stats.ChildCount) or 0
			if childCount < 1 then
				return false, "Need children for this event"
			end
			return true
		end,
		
		choices = {
			{ text = "First steps!", effects = { Happiness = 12 }, setFlags = { saw_first_steps = true }, feedText = "🌟 Walking! Your baby is walking! Video everything!" },
			{ text = "First words!", effects = { Happiness = 12 }, setFlags = { heard_first_words = true }, feedText = "🌟 They said 'mama/dada'! Heart melting!" },
			{ text = "Graduated to new grade", effects = { Happiness = 8, Money = -50 }, feedText = "🌟 Growing up so fast! Pride and tears!" },
			{ text = "Won award/achievement", effects = { Happiness = 10, Smarts = 2 }, feedText = "🌟 Your kid is amazing! Proud parent moment!" },
		},
	},
	{
		id = "family_child_discipline",
		title = "Discipline Dilemma",
		emoji = "😤",
		text = "Your child needs discipline!",
		question = "How do you handle it?",
		minAge = 22, maxAge = 60,
		baseChance = 0.25,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "discipline", "parenting", "challenge" },
		
		eligibility = function(state)
			local childCount = (state.Stats and state.Stats.ChildCount) or 0
			if childCount < 1 then
				return false, "Need children for this event"
			end
			return true
		end,
		
		-- CRITICAL: Random discipline outcome
		choices = {
			{
				text = "Have a serious talk",
				effects = {},
				feedText = "Explaining why their behavior was wrong...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("😤 They understood! Good conversation. Progress!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 1)
						state:AddFeed("😤 Eye rolls but message received. Parenting is hard.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("😤 Escalated into argument. Not how you wanted it to go.")
					end
				end,
			},
			{ text = "Take away privileges", effects = { Happiness = -1 }, feedText = "😤 No screens/phone/outings. Consequences enforced." },
			{ text = "Let it slide", effects = { Happiness = 2 }, setFlags = { pushover_parent = true }, feedText = "😤 Picking battles. This one not worth it." },
		},
	},
	{
		id = "family_teen_troubles",
		title = "Teen Problems",
		emoji = "🙄",
		text = "Your teenager is going through... stuff.",
		question = "How do you handle teenage drama?",
		minAge = 30, maxAge = 65,
		baseChance = 0.25,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "teen", "parenting", "challenge" },
		
		eligibility = function(state)
			local childCount = (state.Stats and state.Stats.ChildCount) or 0
			if childCount < 1 then
				return false, "Need children for this event"
			end
			return true
		end,
		
		-- CRITICAL: Random teen drama outcome
		choices = {
			{
				text = "Try to connect with them",
				effects = {},
				feedText = "Attempting to understand...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🙄 Breakthrough! They opened up! Bonding moment!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🙄 Small progress. At least they talked a little.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🙄 'You don't understand!' Door slammed. Rough phase.")
					end
				end,
			},
			{ text = "Give them space", effects = { Happiness = 2 }, feedText = "🙄 They need independence. Watching from afar." },
			{ text = "Worry constantly", effects = { Happiness = -4, Health = -2 }, setFlags = { worried_parent = true }, feedText = "🙄 Can't sleep. Are they okay? What are they doing?" },
		},
	},
	{
		id = "family_empty_nest",
		title = "Empty Nest",
		emoji = "🏠",
		text = "Your last child is moving out!",
		question = "How do you feel about the empty nest?",
		minAge = 40, maxAge = 70,
		baseChance = 0.2,
		cooldown = 10,
		oneTime = true,
		stage = STAGE,
		ageBand = "adult",
		category = "milestone",
		tags = { "empty_nest", "milestone", "transition" },
		
		eligibility = function(state)
			local childCount = (state.Stats and state.Stats.ChildCount) or 0
			if childCount < 1 then
				return false, "Need children for this event"
			end
			return true
		end,
		
		choices = {
			{ text = "Celebrate freedom", effects = { Happiness = 10, Money = 200 }, setFlags = { empty_nester = true }, feedText = "🏠 Free at last! New chapter! Second wind!" },
			{ text = "Feel the loss deeply", effects = { Happiness = -6, Health = -2 }, setFlags = { empty_nest_syndrome = true }, feedText = "🏠 House is so quiet. Miss them so much. Adjusting." },
			{ text = "Mixed emotions", effects = { Happiness = 3 }, setFlags = { empty_nester = true }, feedText = "🏠 Proud they're independent. Miss the chaos. Bittersweet." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EXTENDED FAMILY
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "family_reunion",
		title = "Family Reunion",
		emoji = "👨‍👩‍👧‍👦",
		text = "Big family reunion happening!",
		question = "Do you attend?",
		minAge = 10, maxAge = 90,
		baseChance = 0.15,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "family",
		tags = { "reunion", "family", "gathering" },
		
		-- CRITICAL: Random family reunion outcome
		choices = {
			{
				text = "Go and participate",
				effects = { Money = -50 },
				feedText = "At the family reunion...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("👨‍👩‍👧‍👦 So good to see everyone! Reconnected with cousins!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("👨‍👩‍👧‍👦 Some awkward moments but overall nice.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("👨‍👩‍👧‍👦 Family drama! Arguments erupted. Stressful.")
					end
				end,
			},
			{ text = "Skip it", effects = { Happiness = 2 }, setFlags = { family_avoider = true }, feedText = "👨‍👩‍👧‍👦 Too much family is too much. Next time maybe." },
		},
	},
	{
		id = "family_in_laws",
		title = "In-Law Situation",
		emoji = "👵",
		text = "Something's happening with the in-laws!",
		question = "What's the in-law situation?",
		minAge = 20, maxAge = 80,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "in_laws", "family", "relationships" },
		requiresPartner = true,
		
		choices = {
			{
				text = "Visit or host them",
				effects = {},
				feedText = "Time with in-laws...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.good_in_laws = true
						state:AddFeed("👵 Actually pleasant! They're growing on you!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 1)
						state:AddFeed("👵 Survived. Some tension but cordial.")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.in_law_issues = true
						state:AddFeed("👵 Criticism, judgment, stress. Dreading next visit.")
					end
				end,
			},
			{ text = "Help in-laws with something", effects = { Money = -100, Happiness = 4 }, feedText = "👵 Earned some brownie points. Good will building." },
			{ text = "Boundary issues", effects = { Happiness = -4 }, feedText = "👵 They're overstepping. Need to have a talk." },
		},
	},
	{
		id = "family_sibling_dynamics",
		title = "Sibling Relationship",
		emoji = "👫",
		text = "Something's happening with your sibling!",
		question = "What's the sibling situation?",
		minAge = 15, maxAge = 90,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "family",
		tags = { "sibling", "family", "relationships" },
		
		choices = {
			{
				text = "Reconnect after time apart",
				effects = {},
				feedText = "Catching up with sibling...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.close_sibling = true
						state:AddFeed("👫 Like no time passed! Best friend energy!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("👫 Good to see them. Different now but still family.")
					end
				end,
			},
			{ text = "Sibling rivalry flare-up", effects = { Happiness = -5 }, setFlags = { sibling_rivalry = true }, feedText = "👫 Old competition resurfaces. Some things never change." },
			{ text = "Support sibling through tough time", effects = { Happiness = 4, Money = -100 }, feedText = "👫 They needed you. Glad to be there for them." },
		},
	},
	{
		id = "family_parent_aging",
		title = "Aging Parents",
		emoji = "👴",
		text = "Your parents are getting older.",
		question = "How do you handle their aging?",
		minAge = 30, maxAge = 70,
		baseChance = 0.2,
		cooldown = 4,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "parents", "aging", "caregiving" },
		
		-- CRITICAL: Random aging parent situation
		choices = {
			{
				text = "Help with their care",
				effects = { Money = -200 },
				feedText = "Taking care of parents...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("👴 Quality time with parents. Grateful for these moments.")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", -2)
						state:ModifyStat("Health", -2)
						state.Flags = state.Flags or {}
						state.Flags.caregiver = true
						state:AddFeed("👴 Caregiving is hard. Exhausting but important.")
					else
						state:ModifyStat("Happiness", -6)
						state:ModifyStat("Health", -4)
						state.Money = (state.Money or 0) - 500
						state:AddFeed("👴 Their health declining. Medical costs rising. Stressful.")
					end
				end,
			},
			{ text = "Move them to assisted living", effects = { Happiness = -4, Money = -1000 }, setFlags = { parents_in_care = true }, feedText = "👴 Hard decision but necessary. Guilt but relief." },
			{ text = "Check in from afar", effects = { Happiness = 2 }, feedText = "👴 Calling regularly. Doing what you can from distance." },
		},
	},
	{
		id = "family_loss",
		title = "Family Loss",
		emoji = "😢",
		text = "A family member has passed away.",
		question = "How do you cope with the loss?",
		minAge = 10, maxAge = 100,
		baseChance = 0.08,
		cooldown = 8,
		stage = STAGE,
		ageBand = "any",
		category = "milestone",
		tags = { "death", "grief", "family" },
		
		choices = {
			{
				text = "Grieve and process",
				effects = {},
				feedText = "Mourning the loss...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", -8)
						state:ModifyStat("Health", -3)
						state.Flags = state.Flags or {}
						state.Flags.grieving = true
						state:AddFeed("😢 Devastating loss. Grief is overwhelming. Processing slowly.")
					else
						state:ModifyStat("Happiness", -5)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("😢 Sad but finding peace. Cherishing memories.")
					end
				end,
			},
			{ text = "Inheritance situation", effects = {}, feedText = "Dealing with the estate...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state.Money = (state.Money or 0) + 5000
						state:ModifyStat("Happiness", -2)
						state:AddFeed("😢 Unexpected inheritance. Money can't replace them.")
					elseif roll < 0.70 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", -4)
						state:AddFeed("😢 Small inheritance. Memories matter more.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.inheritance_drama = true
						state:AddFeed("😢 Family fighting over estate. Grief compounded by greed.")
					end
				end,
			},
		},
	},
	{
		id = "family_tradition",
		title = "Family Tradition",
		emoji = "🎄",
		text = "Time for a family tradition!",
		question = "How do you participate?",
		minAge = 5, maxAge = 100,
		baseChance = 0.25,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "family",
		tags = { "tradition", "holiday", "family" },
		
		choices = {
			{ text = "Embrace the tradition fully", effects = { Happiness = 10, Money = -100 }, setFlags = { family_traditions = true }, feedText = "🎄 Love these moments! Creating memories together!" },
			{ text = "Go through the motions", effects = { Happiness = 3, Money = -50 }, feedText = "🎄 Participating. Not as magical but family time." },
			{ text = "Start a new tradition", effects = { Happiness = 8, Smarts = 2 }, feedText = "🎄 Out with old, in with new! Family evolution!" },
			{ text = "Skip this year", effects = { Happiness = -2 }, feedText = "🎄 Couldn't make it. Guilt about missing it." },
		},
	},
	{
		id = "family_grandparent_bond",
		title = "Grandparent Connection",
		emoji = "👴👶",
		text = "Grandparent-grandchild bonding time!",
		question = "How does the bonding go?",
		minAge = 55, maxAge = 100,
		baseChance = 0.2,
		cooldown = 3,
		stage = STAGE,
		ageBand = "senior",
		category = "family",
		tags = { "grandparent", "grandchild", "bonding" },
		
		eligibility = function(state)
			local childCount = (state.Stats and state.Stats.ChildCount) or 0
			if childCount < 1 then
				return false, "Need to have had children to have grandchildren"
			end
			return true
		end,
		
		choices = {
			{ text = "Spoil them rotten", effects = { Happiness = 12, Money = -50 }, setFlags = { doting_grandparent = true }, feedText = "👴👶 Ice cream for breakfast! Grandparent privilege!" },
			{ text = "Share family stories", effects = { Happiness = 10, Smarts = 2 }, feedText = "👴👶 Passing down history and wisdom! Legacy continues!" },
			{ text = "Teach them a skill", effects = { Happiness = 8, Smarts = 3 }, feedText = "👴👶 Learning together! Bridging generations!" },
			{ text = "Just enjoy their company", effects = { Happiness = 10, Health = 2 }, feedText = "👴👶 Pure joy. Kids keep you young at heart!" },
		},
	},
}

return FamilyEvents
