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
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
						-- CRITICAL FIX: Use state.ChildCount not state.Stats.ChildCount for consistency
						state.ChildCount = (state.ChildCount or 0) + 1
						state:AddFeed("🤰 BABY ON THE WAY! Overjoyed! Life about to change!")
					else
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.expecting = true
						-- CRITICAL FIX: Use state.ChildCount not state.Stats.ChildCount for consistency
						state.ChildCount = (state.ChildCount or 0) + 1
						state:AddFeed("👶 Expecting a baby! Excited and nervous! Ready or not!")
					end
				end,
			},
			{ 
			text = "Unexpected pregnancy (prenatal care $200)", 
			effects = { Happiness = -2, Money = -200 }, 
			setFlags = { unexpected_pregnancy = true, expecting = true }, 
			feedText = "🤰 Not planned but happening. Adjusting expectations.",
			-- CRITICAL FIX #1: Add eligibility check for prenatal care cost!
			eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for prenatal care" end,
			-- CRITICAL FIX: Track child count for unexpected pregnancy too
			onResolve = function(state)
				state.ChildCount = (state.ChildCount or 0) + 1
			end,
		},
			{ text = "False alarm", effects = { Happiness = 2 }, feedText = "👶 Thought we were expecting. Mixed emotions about the test results." },
		},
	},
	{
		id = "family_birth",
		title = "Baby Arrives!",
		emoji = "👶",
		text = "The baby is coming!",
		question = "How does the birth go?",
		minAge = 18, maxAge = 50,
		baseChance = 0.65, -- CRITICAL FIX: Reduced from 0.8 to prevent spam
		cooldown = 5, -- CRITICAL FIX: Increased to prevent spam
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
				effects = {},  -- Handle costs in onResolve based on what player has
				feedText = "In the delivery room...",
				onResolve = function(state)
					-- Take hospital costs proportionally - poor players pay less
					local currentMoney = state.Money or 0
					local hospitalCost = math.min(1000, math.max(100, math.floor(currentMoney * 0.2)))
					state.Money = math.max(0, currentMoney - hospitalCost)
					local roll = math.random()
					
					-- CRITICAL FIX: Create child relationship
					state.Relationships = state.Relationships or {}
					local isBoy = math.random() > 0.5
					local boyNames = {"James", "William", "Oliver", "Benjamin", "Lucas", "Henry", "Alexander", "Mason", "Ethan", "Noah"}
					local girlNames = {"Emma", "Olivia", "Ava", "Isabella", "Sophia", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn"}
					local childName = isBoy and boyNames[math.random(1, #boyNames)] or girlNames[math.random(1, #girlNames)]
					local childId = "child_" .. tostring(os.clock()):gsub("%.", "")
					
					state.Relationships[childId] = {
						id = childId,
						name = childName,
						type = "family",
						role = isBoy and "Son" or "Daughter",
						relationship = 100, -- Babies start with max love!
						age = 0,
						gender = isBoy and "male" or "female",
						alive = true,
						isChild = true,
						isFamily = true,
						birthYear = state.Year or 2025,
					}
					
					state.Flags = state.Flags or {}
					state.Flags.expecting = nil
					state.Flags.new_parent = true
					state.Flags.parent = true
					state.Flags.has_child = true
					
					if roll < 0.60 then
						state:ModifyStat("Happiness", 20)
						state:AddFeed(string.format("👶 HEALTHY BABY! Welcome %s! Perfect delivery! Overwhelming love!", childName))
					elseif roll < 0.90 then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Health", -3)
						state:AddFeed(string.format("👶 %s is here! Difficult delivery but everyone's okay!", childName))
					else
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Health", -8)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 2000)
						state.Flags.nicu_baby = true
						state:AddFeed(string.format("👶 Complications. %s is in NICU. Scary but hopeful.", childName))
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
			{ text = "Hire night nurse ($500)", effects = { Money = -500, Happiness = 6, Health = 4 }, feedText = "🍼 Worth every penny. SLEEP!",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Can't afford night nurse ($500 needed)" end,
			},
		},
	},
	{
		id = "family_child_milestone",
		title = "Child Development Milestone",
		emoji = "🌟",
		text = "Your child reached a milestone!",
		question = "What did they achieve?",
		minAge = 20, maxAge = 60,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "milestone", "child", "parenting" },
		
		eligibility = function(state)
			-- CRITICAL FIX: Use state.ChildCount not state.Stats.ChildCount
			local childCount = state.ChildCount or 0
			if childCount < 1 then
				return false, "Need children for this event"
			end
			return true
		end,
		
		choices = {
			{ text = "First steps!", effects = { Happiness = 12 }, setFlags = { saw_first_steps = true }, feedText = "🌟 Walking! Your baby is walking! Video everything!" },
			{ text = "First words!", effects = { Happiness = 12 }, setFlags = { heard_first_words = true }, feedText = "🌟 They said 'mama/dada'! Heart melting!" },
			{ text = "Graduated to new grade", effects = { Happiness = 8 }, feedText = "🌟 Growing up so fast! Pride and tears!" },
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
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "discipline", "parenting", "challenge" },
		
		eligibility = function(state)
			-- CRITICAL FIX: Use state.ChildCount not state.Stats.ChildCount
			local childCount = state.ChildCount or 0
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
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "teen", "parenting", "challenge" },
		
		eligibility = function(state)
			-- CRITICAL FIX: Use state.ChildCount not state.Stats.ChildCount
			local childCount = state.ChildCount or 0
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
		baseChance = 0.45,
		cooldown = 4,
		oneTime = true,
		stage = STAGE,
		ageBand = "adult",
		category = "milestone",
		tags = { "empty_nest", "milestone", "transition" },
		
		eligibility = function(state)
			-- CRITICAL FIX: Use state.ChildCount not state.Stats.ChildCount
			local childCount = state.ChildCount or 0
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
		-- CRITICAL FIX: Renamed from "family_reunion" to avoid duplicate ID conflict
		id = "family_reunion_extended",
		title = "Family Reunion",
		emoji = "👨‍👩‍👧‍👦",
		text = "Big family reunion happening!",
		question = "Do you attend?",
		minAge = 10, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "family",
		tags = { "reunion", "family", "gathering" },
		
		-- CRITICAL: Random family reunion outcome
		choices = {
			{
				text = "Go and participate ($50)",
				effects = { Money = -50 },
				feedText = "At the family reunion...",
				eligibility = function(state) return (state.Money or 0) >= 50, "Can't afford travel costs" end,
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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
			{ text = "Help in-laws with something", effects = { Happiness = 4 }, feedText = "👵 Earned some brownie points. Good will building." },
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
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "family",
		tags = { "sibling", "family", "relationships" },
		-- CRITICAL FIX: Sibling events require having siblings!
		requiresFlags = { has_siblings = true },
		
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
			{ text = "Support sibling through tough time", effects = { Happiness = 4 }, feedText = "👫 They needed you. Glad to be there for them." },
		},
	},
	{
		id = "family_parent_aging",
		title = "Aging Parents",
		emoji = "👴",
		text = "Your parents are getting older.",
		question = "How do you handle their aging?",
		minAge = 30, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "parents", "aging", "caregiving" },
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #537: Only show if parents are still alive!
		-- User complaint: "IT SAYS CARING FOR PARENTS WHEN IM 70 AND MY PARENTS ARE DEAD"
		-- ═══════════════════════════════════════════════════════════════════════════════
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
			-- Check Relationships for parent status
			if state.Relationships then
				local hasLivingParent = false
				for _, rel in ipairs(state.Relationships) do
					if (rel.type == "parent" or rel.role == "Parent" or rel.role == "Mother" or rel.role == "Father")
					   and not rel.deceased and not rel.dead then
						hasLivingParent = true
						break
					end
				end
				-- If we have relationship data but no living parents, don't show event
				if not hasLivingParent then
					local parentCount = 0
					for _, rel in ipairs(state.Relationships) do
						if rel.type == "parent" or rel.role == "Parent" or rel.role == "Mother" or rel.role == "Father" then
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
		
		-- CRITICAL: Random aging parent situation
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Help with their care ($200)",
				effects = { Money = -200 },
				feedText = "Taking care of parents...",
				eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for care expenses" end,
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
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 500)
						state:AddFeed("👴 Their health declining. Medical costs rising. Stressful.")
					end
				end,
			},
			{ text = "Move them to assisted living ($1000)", effects = { Happiness = -4, Money = -1000 }, setFlags = { parents_in_care = true }, feedText = "👴 Hard decision but necessary. Guilt but relief.",
				eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Can't afford assisted living deposit ($1000 needed)" end,
			},
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
		baseChance = 0.32,
		cooldown = 3,
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
				local age = state.Age or 0
				local roll = math.random()
				
				-- CRITICAL FIX: Children can't directly receive inheritance
				-- If under 18, the inheritance goes to parents/guardians
				if age < 18 then
					state:ModifyStat("Happiness", -4)
					state:AddFeed("😢 Adults are handling the estate matters. Too young to be involved.")
					return
				end
				
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
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "family",
		tags = { "tradition", "holiday", "family" },
		
		choices = {
			{ text = "Embrace the tradition fully", effects = { Happiness = 10 }, setFlags = { family_traditions = true }, feedText = "🎄 Love these moments! Creating memories together!" },
			{ text = "Go through the motions", effects = { Happiness = 3 }, feedText = "🎄 Participating. Not as magical but family time." },
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
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "senior",
		category = "family",
		tags = { "grandparent", "grandchild", "bonding" },
		
		eligibility = function(state)
			-- CRITICAL FIX: Use state.ChildCount not state.Stats.ChildCount
			local childCount = state.ChildCount or 0
			if childCount < 1 then
				return false, "Need to have had children to have grandchildren"
			end
			return true
		end,
		
		choices = {
			{ text = "Spoil them rotten", effects = { Happiness = 12 }, setFlags = { doting_grandparent = true }, feedText = "👴👶 Ice cream for breakfast! Grandparent privilege!" },
			{ text = "Share family stories", effects = { Happiness = 10, Smarts = 2 }, feedText = "👴👶 Passing down history and wisdom! Legacy continues!" },
			{ text = "Teach them a skill", effects = { Happiness = 8, Smarts = 3 }, feedText = "👴👶 Learning together! Bridging generations!" },
			{ text = "Just enjoy their company", effects = { Happiness = 10, Health = 2 }, feedText = "👴👶 Pure joy. Kids keep you young at heart!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- INHERITANCE / CONTINUE AS KID EVENTS
	-- Special events that trigger when playing as a character who inherited
	-- User requested: "ENSURE CONTINUE AS KID WORKS BETTER AND ISN'T BORING"
	-- ══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "fam_inheritance_grief",
		title = "Grieving Your Parent",
		emoji = "🕯️",
		text = "The loss of your parent still weighs heavily on you. The house feels empty.",
		question = "How do you cope with the grief?",
		minAge = 18, maxAge = 60,
		baseChance = 0.55, -- CRITICAL FIX: Reduced from 0.8 to prevent spam
		cooldown = 5, -- CRITICAL FIX: Increased to prevent spam
		oneTime = true,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "inheritance", "grief", "loss", "parent" },
		requiresFlags = { inherited_from_parent = true, grieving = true },
		
		choices = {
			{
				text = "Honor their memory with a charity donation ($2,000)",
				effects = { Money = -2000, Happiness = 8 },
				feedText = "🕯️ Donated to their favorite cause. They would be proud.",
				-- BUG FIX #6: Add eligibility check for donation cost
				eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Can't afford donation ($2,000 needed)" end,
				onResolve = function(state)
					state.Flags.charitable = true
					state.Flags.honoring_parent = true
					state.Flags.grieving = nil
					state:AddFeed("🕯️ Your generosity in their name brought peace to your heart.")
				end,
			},
			{
				text = "Throw yourself into work to distract",
				effects = { Happiness = -3, Smarts = 3 },
				feedText = "🕯️ Burying yourself in work. Not healthy, but keeps you going.",
				onResolve = function(state)
					state.Flags.workaholic = true
					local roll = math.random()
					if roll < 0.3 then
						state:AddFeed("🕯️ Your work ethic impressed your boss. Promotion incoming?")
						state.Flags.hard_worker = true
					end
				end,
			},
			{
				-- CRITICAL FIX: Show price!
				text = "See a therapist ($500)",
				effects = { Money = -500, Happiness = 6, Health = 3 },
				feedText = "🕯️ Professional help. Processing grief properly.",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for therapy" end,
				onResolve = function(state)
					state.Flags.grieving = nil
					state.Flags.in_therapy = true
					state.Flags.mental_health_aware = true
					state:AddFeed("🕯️ Therapy helped. You're learning to carry the grief, not be crushed by it.")
				end,
			},
			{
				text = "Isolate and process alone",
				effects = { Happiness = -5 },
				feedText = "🕯️ Shutting everyone out. The grief is overwhelming.",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.5 then
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🕯️ Depression is setting in. You need help.")
						state.Flags.depressed = true
					else
						state:ModifyStat("Happiness", 5)
						state.Flags.grieving = nil
						state:AddFeed("🕯️ After weeks alone, you finally cried it out. Healing begins.")
					end
				end,
			},
		},
	},
	
	{
		id = "fam_parent_legacy_choice",
		title = "Your Parent's Legacy",
		emoji = "📜",
		text = "Going through your late parent's belongings, you found something that reveals a side of them you never knew.",
		question = "What did you discover?",
		minAge = 18, maxAge = 80,
		baseChance = 0.7,
		cooldown = 5,
		oneTime = true,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "inheritance", "legacy", "parent", "discovery" },
		requiresFlags = { inherited_from_parent = true },
		
		choices = {
			{
				text = "Hidden savings account",
				effects = {},
				feedText = "A surprise nest egg...",
				onResolve = function(state)
					local amount = math.random(5000, 25000)
					state.Money = (state.Money or 0) + amount
					state:ModifyStat("Happiness", 12)
					state:AddFeed("📜 Found $" .. amount .. " in a hidden account! They were saving for your future!")
					state.Flags.parent_secret_gift = true
				end,
			},
			{
				text = "Letters from a secret admirer",
				effects = { Happiness = 5 },
				feedText = "📜 Your parent had a romantic side you never knew. Bittersweet discovery.",
				onResolve = function(state)
					if math.random() < 0.3 then
						state:AddFeed("📜 The letters reveal you might have a half-sibling out there...")
						state.Flags.potential_sibling = true
					end
				end,
			},
			{
				text = "A business opportunity they never pursued",
				effects = { Smarts = 3 },
				feedText = "📜 An unfinished dream. Maybe you can complete it for them?",
				setFlags = { parent_dream_opportunity = true, has_business_idea = true },
			},
			{
				text = "Debts you didn't know about",
				effects = { Happiness = -10 },
				feedText = "📜 Bills, loans, IOUs... Your parent was struggling more than you knew.",
				onResolve = function(state)
					local debt = math.random(5000, 20000)
					state.Money = math.max(0, (state.Money or 0) - debt)
					state.Flags.inherited_debt = true
					state:AddFeed("📜 Had to pay off $" .. debt .. " in hidden debts. Inheritance reduced significantly.")
				end,
			},
		},
	},
	
	{
		id = "fam_carrying_on_tradition",
		title = "Carrying On the Family Name",
		emoji = "🏛️",
		text = "People in town keep mentioning your late parent. Their reputation lives on.",
		question = "How does the community remember them?",
		minAge = 18, maxAge = 70,
		baseChance = 0.6,
		cooldown = 4,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "inheritance", "legacy", "reputation", "community" },
		requiresFlags = { inherited_from_parent = true },
		
		choices = {
			{
				text = "They were beloved - doors open for you",
				effects = { Happiness = 10 },
				feedText = "🏛️ Everyone loved your parent. Their reputation is now your advantage.",
				setFlags = { good_family_name = true, community_connections = true },
			},
			{
				text = "They were respected for their work",
				effects = { Happiness = 6, Smarts = 2 },
				feedText = "🏛️ Professionals remember your parent's skill. Expectations are high.",
				setFlags = { parent_reputation = true },
			},
			{
				text = "They had a complicated past",
				effects = { Happiness = -3 },
				feedText = "🏛️ Some people give you strange looks. Not everyone has fond memories.",
				onResolve = function(state)
					if math.random() < 0.5 then
						state.Flags.family_secrets = true
						state:AddFeed("🏛️ Someone muttered something about 'old debts'... What did your parent do?")
					end
				end,
			},
			{
				text = "They were a stranger here - you're on your own",
				effects = { Happiness = -2 },
				feedText = "🏛️ No one really knew your parent. You're starting fresh with no legacy.",
			},
		},
	},
	
	{
		id = "fam_sibling_inheritance_dispute",
		title = "Sibling Dispute",
		emoji = "💢",
		text = "Your sibling is contesting the inheritance! They think they deserve more.",
		question = "How do you handle this family conflict?",
		minAge = 18, maxAge = 80,
		baseChance = 0.5,
		cooldown = 6,
		oneTime = true,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "inheritance", "conflict", "sibling", "money" },
		requiresFlags = { inherited_from_parent = true },
		-- Only if player has siblings
		eligibility = function(state)
			if not state.Relationships then return false end
			for _, rel in pairs(state.Relationships) do
				if type(rel) == "table" and rel.type == "sibling" and rel.alive ~= false then
					return true
				end
			end
			return false
		end,
		
		choices = {
			{
				text = "Split it evenly - family peace matters",
				effects = { Happiness = 5 },
				feedText = "💢 You gave up half. But your relationship with your sibling survived.",
				onResolve = function(state)
					state.Money = math.floor((state.Money or 0) / 2)
					state.Flags.generous = true
					state.Flags.sibling_harmony = true
					state:AddFeed("💢 Money is money, but family is family. You did the right thing.")
				end,
			},
			{
				text = "Fight it in court ($3,000 in legal fees)",
				effects = { Money = -3000, Happiness = -5 },
				feedText = "Lawyer up...",
				-- BUG FIX #7: Add eligibility check for legal costs
				eligibility = function(state) return (state.Money or 0) >= 3000, "💸 Can't afford legal fees ($3,000 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.6 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("💢 Won the case! But your sibling will never forgive you.")
						state.Flags.won_lawsuit = true
						state.Flags.sibling_enemy = true
					else
						state.Money = math.floor((state.Money or 0) / 2)
						state:ModifyStat("Happiness", -10)
						state:AddFeed("💢 Lost the case. Had to split it AND pay legal fees. Double loss.")
						state.Flags.sibling_enemy = true
					end
				end,
			},
			{
				text = "Offer a compromise - give them one asset",
				effects = { Happiness = 2 },
				feedText = "💢 You kept most of it but gave them something. Tense but tolerable.",
				onResolve = function(state)
					-- Remove one property if any
					if state.Assets and state.Assets.Properties and #state.Assets.Properties > 1 then
						table.remove(state.Assets.Properties)
						state:AddFeed("💢 Gave them one of the properties. Fair enough?")
					elseif state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0 then
						table.remove(state.Assets.Vehicles)
						state:AddFeed("💢 Gave them the car. Hopefully that's enough.")
					else
						state.Money = math.floor((state.Money or 0) * 0.8)
						state:AddFeed("💢 Gave them 20% cash. They're not happy but accepted.")
					end
					state.Flags.sibling_tension = true
				end,
			},
			{
				text = "Cut them off entirely",
				effects = { Happiness = -3 },
				feedText = "💢 You kept everything. But you may never speak to your sibling again.",
				setFlags = { sibling_estranged = true, selfish = true },
			},
		},
	},
	
	{
		id = "fam_making_them_proud",
		title = "Would They Be Proud?",
		emoji = "👻",
		text = "On the anniversary of your parent's death, you reflect on how you've been living.",
		question = "Would your parent be proud of who you've become?",
		minAge = 19, maxAge = 80,
		baseChance = 0.7,
		cooldown = 5,
		stage = STAGE,
		ageBand = "adult",
		category = "family",
		tags = { "inheritance", "reflection", "legacy", "memory" },
		requiresFlags = { inherited_from_parent = true },
		
		choices = {
			{
				text = "Yes - I've done well",
				effects = { Happiness = 10 },
				feedText = "👻 Living your best life. They'd be so proud.",
				eligibility = function(state)
					local happy = (state.Stats and state.Stats.Happiness) or 50
					local money = state.Money or 0
					return happy >= 60 or money >= 50000 or state.Flags.successful
				end,
			},
			{
				text = "I'm trying my best",
				effects = { Happiness = 5 },
				feedText = "👻 Life is hard but you're fighting. They'd understand.",
			},
			{
				text = "I've made some mistakes",
				effects = { Happiness = -3 },
				feedText = "👻 Regrets. But there's still time to turn things around.",
				onResolve = function(state)
					state.Flags.seeking_redemption = true
					state:AddFeed("👻 Time to make some changes. For them. For you.")
				end,
			},
			{
				text = "I've failed them completely",
				effects = { Happiness = -10 },
				feedText = "👻 Rock bottom. They would be disappointed. But disappointment comes from love.",
				eligibility = function(state)
					local happy = (state.Stats and state.Stats.Happiness) or 50
					return happy < 30 or state.Flags.homeless or state.Flags.in_prison or state.Flags.addicted
				end,
			},
		},
	},
}

return FamilyEvents
