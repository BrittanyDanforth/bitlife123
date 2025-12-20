--[[
    School & Education Events - Expanded
    Comprehensive school/education experiences from elementary to college
    All events use randomized outcomes - NO god mode
]]

local SchoolExpanded = {}

local STAGE = "childhood"

SchoolExpanded.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- ELEMENTARY SCHOOL (Ages 5-10)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "elem_first_friend",
		title = "First School Friend",
		emoji = "👋",
		text = "Another kid wants to be your friend!",
		question = "How do you respond to their friendship?",
		minAge = 5, maxAge = 8,
		baseChance = 0.5,
		cooldown = 3,
		oneTime = true,
		stage = "childhood",
		ageBand = "early_childhood",
		category = "social",
		tags = { "friendship", "school", "elementary" },
		
		choices = {
			{
				text = "Become best friends",
				effects = {},
				feedText = "Starting a new friendship...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.has_best_friend = true
						state:AddFeed("👋 Instant connection! You two are inseparable!")
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("👋 Good friends, but not BFFs. Still nice!")
					end
				end,
			},
			{ text = "Play together sometimes", effects = { Happiness = 5 }, feedText = "👋 A casual friend. Nice to have options!" },
			{ text = "Too shy to accept", effects = { Happiness = -3 }, setFlags = { shy_kid = true }, feedText = "👋 Retreated into shell. Opportunity missed." },
		},
	},
	{
		id = "elem_spelling_bee",
		title = "Spelling Bee",
		emoji = "🐝",
		text = "The school spelling bee is coming up!",
		question = "Do you participate?",
		minAge = 6, maxAge = 12,
		baseChance = 0.555,
		cooldown = 2,
		stage = "childhood",
		ageBand = "early_childhood",
		category = "academics",
		tags = { "spelling", "competition", "school" },
		
		-- CRITICAL: Spelling bee competition with minigame
		choices = {
			{
				text = "⚡ COMPETE to WIN!",
				effects = {},
				feedText = "Stepping up to the microphone...",
				-- CRITICAL FIX: QTE minigame for spelling bee!
				triggerMinigame = "qte",
				minigameOptions = { difficulty = "easy" },
				onResolve = function(state, minigameResult)
					local won = minigameResult and (minigameResult.success or minigameResult.won)
					state.Flags = state.Flags or {}
					
					if won then
						state:ModifyStat("Happiness", 18)
						state:ModifyStat("Smarts", 6)
						state.Flags.spelling_champion = true
						state:AddFeed("🐝🏆 CHAMPION! You spelled every word perfectly! You're a LEGEND!")
					else
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🐝 You made it far but stumbled on 'onomatopoeia'. Good try!")
					end
				end,
			},
			{
				text = "Study hard and compete",
				effects = {},
				feedText = "Stepping up to the microphone...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local winChance = 0.15 + (smarts / 150)
					
					if roll < winChance then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Smarts", 5)
						state.Flags = state.Flags or {}
						state.Flags.spelling_bee_champ = true
						state:AddFeed("🐝 WINNER! You're the spelling bee champion!")
					elseif roll < (winChance * 2.5) then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("🐝 Made it to the final rounds! Great showing!")
					else
						state:ModifyStat("Happiness", 2)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🐝 Got out early. At least you tried!")
					end
				end,
			},
			{ text = "Watch from the audience", effects = { Happiness = 2, Smarts = 1 }, feedText = "🐝 Cheered on classmates. Safe but boring." },
			{ text = "Get stage fright", effects = { Happiness = -4 }, setFlags = { stage_fright = true }, feedText = "🐝 Froze on first word. Mortifying." },
		},
	},
	{
		id = "elem_show_and_tell",
		title = "Show and Tell",
		emoji = "🎪",
		text = "It's your turn for show and tell!",
		question = "What do you bring?",
		minAge = 5, maxAge = 8,
		baseChance = 0.4,
		cooldown = 3,
		stage = "childhood",
		ageBand = "early_childhood",
		category = "social",
		tags = { "presentation", "school", "sharing" },
		
		choices = {
			{
				text = "Your coolest toy/possession",
				effects = {},
				feedText = "Showing your treasure...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🎪 Everyone thought it was so cool! Popular moment!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🎪 Mild interest. Meh reception.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🎪 Someone said it was lame. Kids are mean.")
					end
				end,
			},
			{ text = "A pet/animal", effects = { Happiness = 8 }, setFlags = { brought_pet_to_school = true }, feedText = "🎪 Everyone went crazy! Best show and tell ever!" },
			{ text = "Forget entirely", effects = { Happiness = -5 }, feedText = "🎪 Had to make something up on the spot. Embarrassing!" },
		},
	},
	{
		id = "elem_art_class_creation",
		title = "Art Class Project",
		emoji = "🎨",
		text = "You made something in art class!",
		question = "How did your project turn out?",
		minAge = 5, maxAge = 12,
		baseChance = 0.4,
		cooldown = 2,
		stage = "childhood",
		ageBand = "early_childhood",
		category = "creativity",
		tags = { "art", "school", "creativity" },
		
		choices = {
			{
				text = "Put your heart into it",
				effects = {},
				feedText = "Creating your masterpiece...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.artistic = true
						state:AddFeed("🎨 Teacher hung it on the wall! Artistic talent!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎨 Proud of what you made! Not bad at all!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🎨 Messy but yours. Art is subjective!")
					end
				end,
			},
			{ text = "Rush through it", effects = { Happiness = 1 }, feedText = "🎨 Got it done. Quantity over quality." },
			{ text = "Get frustrated and quit", effects = { Happiness = -4 }, feedText = "🎨 Crumpled it up. Creativity is hard sometimes." },
		},
	},
	{
		id = "elem_cafeteria_drama",
		title = "Cafeteria Situation",
		emoji = "🍽️",
		text = "Something happened in the cafeteria!",
		question = "What's the lunch drama?",
		minAge = 5, maxAge = 12,
		baseChance = 0.4,
		cooldown = 2,
		stage = "childhood",
		ageBand = "early_childhood",
		category = "social",
		tags = { "lunch", "school", "social" },
		
		choices = {
			{ text = "Someone stole your lunch", effects = { Happiness = -4, Health = -1 }, feedText = "🍽️ Went hungry. School feels unfair today." },
			{ text = "Made a new friend at your table", effects = { Happiness = 6 }, feedText = "🍽️ Random seat assignment led to friendship!" },
			{ text = "Spilled food on yourself", effects = { Happiness = -5, Looks = -1 }, setFlags = { lunch_spill = true }, feedText = "🍽️ Walked around with stain all day. Mortifying." },
			{ text = "Found a cool snack trading partner", effects = { Happiness = 5 }, setFlags = { trading_buddy = true }, feedText = "🍽️ Best trades ever! Upgraded your lunch!" },
		},
	},
	{
		id = "elem_playground_hierarchy",
		title = "Playground Politics",
		emoji = "🛝",
		text = "There's social drama on the playground!",
		question = "What's happening at recess?",
		minAge = 5, maxAge = 10,
		baseChance = 0.4,
		cooldown = 2,
		stage = "childhood",
		ageBand = "early_childhood",
		category = "social",
		tags = { "recess", "playground", "social" },
		
		-- CRITICAL: Random playground outcome
		choices = {
			{
				text = "Try to join the popular game",
				effects = {},
				feedText = "Approaching the group...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🛝 They let you play! Part of the group!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🛝 'No, we have enough players.' Rejected.")
					end
				end,
			},
			{ text = "Start your own game", effects = { Happiness = 5, Smarts = 2 }, setFlags = { natural_leader = true }, feedText = "🛝 Others joined YOUR game! Leader vibes!" },
			{ text = "Play alone", effects = { Happiness = 1 }, feedText = "🛝 Imagination doesn't need others. Solo adventures." },
			{ text = "Sit out with a friend", effects = { Happiness = 4 }, feedText = "🛝 Best conversations happen on the sidelines." },
		},
	},
	{
		id = "elem_field_trip",
		title = "School Field Trip",
		emoji = "🚌",
		text = "The class is going on a field trip!",
		question = "How does the field trip go?",
		minAge = 5, maxAge = 12,
		baseChance = 0.55,
		cooldown = 2,
		stage = "childhood",
		ageBand = "early_childhood",
		category = "experience",
		tags = { "field_trip", "school", "adventure" },
		
		choices = {
			{
				text = "Stay with your group",
				effects = {},
				feedText = "Exploring with classmates...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("🚌 Best day ever! Learned so much and had fun!")
					else
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🚌 Good trip. Some boring parts but overall nice.")
					end
				end,
			},
			{ text = "Get lost/separated briefly", effects = { Happiness = -4, Smarts = 2 }, setFlags = { got_lost_field_trip = true }, feedText = "🚌 Scary few minutes but found the group. Adventure!" },
			{ text = "Get sick on the bus", effects = { Happiness = -6, Health = -2 }, feedText = "🚌 Motion sickness ruined it. Barely remember the trip." },
			{ text = "Buy the best souvenir", effects = { Happiness = 6, Money = -10 }, feedText = "🚌 Still treasure it years later!" },
		},
	},
	{
		id = "elem_teacher_pet",
		title = "Teacher's Favorite?",
		emoji = "📚",
		text = "Your teacher seems to really like you!",
		question = "How do you handle being teacher's pet?",
		minAge = 5, maxAge = 12,
		baseChance = 0.455,
		cooldown = 2,
		stage = "childhood",
		ageBand = "early_childhood",
		category = "school",
		tags = { "teacher", "favorite", "school" },
		
		choices = {
			{ text = "Embrace it", effects = { Smarts = 5, Happiness = 4 }, setFlags = { teachers_pet = true }, feedText = "📚 Extra help, special attention - winning at school!" },
			{ text = "Feel awkward about it", effects = { Happiness = 2, Smarts = 2 }, feedText = "📚 Nice but other kids notice. Mixed feelings." },
			{ text = "Distance yourself from teacher", effects = { Happiness = 1 }, feedText = "📚 Don't want to be THAT kid. Keeping it cool." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MIDDLE SCHOOL (Ages 11-14)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "middle_locker_drama",
		title = "Locker Situation",
		emoji = "🔒",
		text = "Something happened with your locker!",
		question = "What's the locker crisis?",
		minAge = 11, maxAge = 14,
		baseChance = 0.555,
		cooldown = 3,
		stage = "teen",
		ageBand = "teen",
		category = "school",
		tags = { "locker", "middle_school", "problems" },
		
		choices = {
			{ text = "Forgot combination again", effects = { Happiness = -3, Smarts = -1 }, feedText = "🔒 Late to class. This is the third time this week!" },
			{ text = "Someone broke into it", effects = { Happiness = -6 }, setFlags = { locker_violated = true }, feedText = "🔒 Your stuff was messed with. Violation of trust." },
			{ text = "Decorated it and it looks great", effects = { Happiness = 5 }, feedText = "🔒 Best locker in the hall! Personal expression!" },
			{ text = "Got assigned next to your crush", effects = { Happiness = 7 }, setFlags = { near_crush = true }, feedText = "🔒 Heart pounds every time you get books. Best luck!" },
		},
	},
	-- REMOVED: middle_puberty_moment - Roblox TOS compliance
	{
		id = "middle_clique_navigation",
		title = "Middle School Social Groups",
		emoji = "👥",
		text = "Social groups are forming. Where do you fit?",
		question = "Which group do you identify with?",
		minAge = 11, maxAge = 14,
		baseChance = 0.4,
		cooldown = 2,
		stage = "teen",
		ageBand = "teen",
		category = "social",
		tags = { "cliques", "social", "identity" },
		
		choices = {
			{ text = "The popular kids", effects = { Happiness = 5, Looks = 2 }, setFlags = { popular_clique = true }, feedText = "👥 In with the cool crowd. Status achieved." },
			{ text = "The nerds/academics", effects = { Smarts = 5, Happiness = 3 }, setFlags = { nerd_clique = true }, feedText = "👥 Your people! Intelligence celebrated!" },
			{ text = "The artists/creatives", effects = { Happiness = 4, Smarts = 2 }, setFlags = { creative_clique = true }, feedText = "👥 Weirdos unite! Expression over conformity!" },
			{ text = "Float between groups", effects = { Happiness = 4, Smarts = 2 }, setFlags = { social_butterfly = true }, feedText = "👥 Friends everywhere, belong nowhere specific. Free agent!" },
			{ text = "Outcast", effects = { Happiness = -5, Smarts = 3 }, setFlags = { social_outcast = true }, feedText = "👥 Alone but independent. It gets better." },
		},
	},
	{
		id = "middle_first_dance",
		title = "School Dance",
		emoji = "💃",
		text = "The school dance is tonight!",
		question = "How does the dance go?",
		minAge = 11, maxAge = 14,
		baseChance = 0.555,
		cooldown = 2,
		stage = "teen",
		ageBand = "teen",
		category = "social",
		tags = { "dance", "social", "milestone" },
		
		-- CRITICAL: Random dance outcome
		choices = {
			{
				text = "Ask your crush to dance",
				effects = {},
				feedText = "Walking over nervously...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local successChance = 0.35 + (looks / 200)
					
					if roll < successChance then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.first_dance = true
						state:AddFeed("💃 They said YES! Magical slow dance moment!")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("💃 They said no. Awkward walk back alone.")
					end
				end,
			},
			{ text = "Dance with friends only", effects = { Happiness = 7 }, feedText = "💃 Group dancing! No pressure, all fun!" },
			{ text = "Stand by the wall", effects = { Happiness = 1, Smarts = 1 }, setFlags = { wallflower = true }, feedText = "💃 Observed everything. Social anthropology." },
			{ text = "Don't go at all", effects = { Happiness = 2 }, feedText = "💃 Stayed home. Dances are overrated anyway." },
		},
	},
	{
		id = "middle_academic_pressure",
		title = "Grades Matter Now",
		emoji = "📊",
		text = "Suddenly grades feel like they really matter!",
		question = "How do you handle academic pressure?",
		minAge = 11, maxAge = 14,
		baseChance = 0.4,
		cooldown = 3,
		stage = "teen",
		ageBand = "teen",
		category = "academics",
		tags = { "grades", "pressure", "school" },
		
		choices = {
			{
				text = "Rise to the challenge",
				effects = {},
				feedText = "Hitting the books...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.40 + (smarts / 200) then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.honor_student = true
						state:AddFeed("📊 Honor roll! Hard work paid off!")
					elseif roll < 0.75 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📊 Solid grades. B average is respectable!")
					else
						state:ModifyStat("Smarts", 1)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📊 Struggled despite effort. Frustrating.")
					end
				end,
			},
			{ text = "Slack off", effects = { Smarts = -2, Happiness = 3 }, feedText = "📊 Grades aren't everything... right?" },
			{ text = "Get overwhelmed", effects = { Happiness = -5, Health = -2 }, setFlags = { academic_anxiety = true }, feedText = "📊 Too much pressure. Breaking down." },
		},
	},
	{
		id = "middle_sports_tryouts",
		title = "Sports Tryouts",
		emoji = "🏀",
		text = "Sports team tryouts are happening!",
		question = "Do you try out?",
		minAge = 11, maxAge = 14,
		baseChance = 0.555,
		cooldown = 2,
		stage = "teen",
		ageBand = "teen",
		category = "athletics",
		tags = { "sports", "tryouts", "team" },
		
		-- CRITICAL: Random tryout outcome
		choices = {
			{
				text = "Give it your all",
				effects = {},
				feedText = "Showing your best...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					local makeTeamChance = 0.25 + (health / 150)
					
					if roll < makeTeamChance then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Health", 5)
						state.Flags = state.Flags or {}
						state.Flags.school_athlete = true
						state:AddFeed("🏀 MADE THE TEAM! You're on the roster!")
					elseif roll < (makeTeamChance * 1.8) then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Health", 2)
						state:AddFeed("🏀 Made JV. Not varsity but still on a team!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🏀 Cut. Didn't make it. Devastating.")
					end
				end,
			},
			{ text = "Don't try - not sporty", effects = { Happiness = 1 }, feedText = "🏀 Sports aren't for everyone. No shame." },
			{ text = "Manager instead of player", effects = { Happiness = 3, Smarts = 2 }, feedText = "🏀 Part of the team without the athletic pressure!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- HIGH SCHOOL (Ages 14-18)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "high_freshman_year",
		title = "Freshman Experience",
		emoji = "🏫",
		text = "High school begins! Bigger pond, smaller fish.",
		question = "How do you navigate freshman year?",
		minAge = 14, maxAge = 15,
		baseChance = 0.6,
		cooldown = 4,
		oneTime = true,
		stage = "teen",
		ageBand = "teen",
		category = "milestone",
		tags = { "high_school", "freshman", "new" },
		
		choices = {
			{
				text = "Adapt quickly",
				effects = {},
				feedText = "Finding your footing...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.50 then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Smarts", 3)
						state:AddFeed("🏫 Thriving freshman! Made friends, good grades!")
					else
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🏫 Surviving freshman year. Getting the hang of it.")
					end
				end,
			},
			{ text = "Struggle with transition", effects = { Happiness = -4, Smarts = 1 }, setFlags = { tough_freshman_year = true }, feedText = "🏫 Rough year. Everything is so different and hard." },
			{ text = "Find your niche quickly", effects = { Happiness = 10, Smarts = 2 }, setFlags = { found_niche = true }, feedText = "🏫 Club, friend group, identity - sorted!" },
		},
	},
	{
		id = "high_club_leadership",
		title = "Club Leadership Opportunity",
		emoji = "📋",
		text = "You could run for a leadership position in a school club!",
		question = "Do you go for it?",
		minAge = 15, maxAge = 18,
		baseChance = 0.55,
		cooldown = 2,
		stage = "teen",
		ageBand = "teen",
		category = "leadership",
		tags = { "club", "leadership", "extracurricular" },
		
		-- CRITICAL: Random election outcome
		choices = {
			{
				text = "Run for president",
				effects = {},
				feedText = "Campaigning...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local winChance = 0.25 + ((smarts + looks) / 400)
					
					if roll < winChance then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 4)
						state.Flags = state.Flags or {}
						state.Flags.club_president = true
						state:AddFeed("📋 YOU WON! Club president! Resume gold!")
					elseif roll < (winChance * 2) then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("📋 Lost president but won VP. Still leadership!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📋 Lost the election. Public rejection hurts.")
					end
				end,
			},
			{ text = "Stay a regular member", effects = { Happiness = 2, Smarts = 1 }, feedText = "📋 Less responsibility, same fun. Good choice." },
			{ text = "Start your own club", effects = { Happiness = 6, Smarts = 3, Money = -20 }, setFlags = { club_founder = true }, feedText = "📋 Founded something new! Initiative recognized!" },
		},
	},
	{
		id = "high_senior_year_decisions",
		title = "Senior Year Decisions",
		emoji = "🎓",
		text = "It's senior year. Big decisions about the future!",
		question = "What's your post-graduation plan?",
		minAge = 17, maxAge = 18,
		baseChance = 0.7,
		cooldown = 4,
		oneTime = true,
		stage = "teen",
		ageBand = "teen",
		category = "milestone",
		tags = { "senior_year", "future", "college" },
		
		choices = {
			{
				text = "Apply to dream colleges",
				effects = { Money = -100 },
				feedText = "Submitting applications...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local acceptChance = 0.20 + (smarts / 150)
					
					if roll < acceptChance then
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.dream_school_accepted = true
						state:AddFeed("🎓 ACCEPTED to your dream school! Future is bright!")
					elseif roll < (acceptChance * 2) then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.college_bound = true
						state:AddFeed("🎓 Got into safety schools. Not dream but still college!")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.rejection_letters = true
						state:AddFeed("🎓 Rejection letters... Need a backup plan.")
					end
				end,
			},
			{ text = "Trade school path", effects = { Happiness = 6, Smarts = 3 }, setFlags = { trade_school_bound = true }, feedText = "🎓 Practical skills, good pay, no debt. Smart!" },
			{ text = "Gap year", effects = { Happiness = 8 }, setFlags = { taking_gap_year = true }, feedText = "🎓 Year off to figure things out. No rush." },
			{ text = "Straight to work", effects = { Happiness = 4, Money = 200 }, setFlags = { working_after_school = true }, feedText = "🎓 No more school! Real world experience starts now!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- COLLEGE (Ages 18-22+)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "college_dorm_life",
		title = "Dorm Room Drama",
		emoji = "🛏️",
		text = "Living in the dorms has its challenges!",
		question = "What's the dorm situation?",
		minAge = 18, maxAge = 22,
		baseChance = 0.4,
		cooldown = 3,
		stage = "adult",
		ageBand = "young_adult",
		category = "social",
		tags = { "college", "dorm", "roommate" },
		requiresFlags = { college_bound = true },
		
		choices = {
			{
				text = "Roommate issues",
				effects = {},
				feedText = "Dealing with roommate problems...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.roommate_from_hell = true
						state:AddFeed("🛏️ Nightmare roommate. Never sleeps, always loud.")
					elseif roll < 0.60 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🛏️ Roommate is okay. Some conflicts but manageable.")
					else
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.great_roommate = true
						state:AddFeed("🛏️ BEST ROOMMATE! Instant best friend!")
					end
				end,
			},
			{ text = "Dorm floor bonding", effects = { Happiness = 7 }, setFlags = { floor_family = true }, feedText = "🛏️ Whole floor is like family. Late night hangs!" },
			{ text = "Need a single room", effects = { Happiness = 4, Money = -500 }, feedText = "🛏️ Worth the extra cost. Privacy is priceless." },
		},
	},
	{
		id = "college_major_declaration",
		title = "Choosing a Major",
		emoji = "📚",
		text = "Time to declare a major!",
		question = "What do you choose?",
		minAge = 18, maxAge = 22,
		baseChance = 0.5,
		cooldown = 4,
		oneTime = true,
		stage = "adult",
		ageBand = "young_adult",
		category = "academics",
		tags = { "college", "major", "career" },
		requiresFlags = { college_bound = true },
		
		choices = {
			{ text = "Follow your passion", effects = { Happiness = 8, Smarts = 4 }, setFlags = { passion_major = true }, feedText = "📚 Studying what you love! Classes are exciting!" },
			{ text = "Practical/high-paying field", effects = { Happiness = 2, Smarts = 4, Money = 50 }, setFlags = { practical_major = true }, feedText = "📚 Engineering/Business/Medicine - future financial security." },
			{ text = "Undeclared - need more time", effects = { Happiness = 4, Smarts = 2 }, feedText = "📚 Exploring options. No need to rush this decision." },
			{ text = "Change major three times", effects = { Happiness = 2, Money = -200 }, setFlags = { changed_majors = true }, feedText = "📚 Finding yourself is a journey. Extra semester worth it." },
		},
	},
	{
		id = "college_party_scene",
		title = "College Party",
		emoji = "🎉",
		text = "Big party happening this weekend!",
		question = "Do you go?",
		minAge = 18, maxAge = 24,
		baseChance = 0.4,
		cooldown = 2,
		stage = "adult",
		ageBand = "young_adult",
		category = "social",
		tags = { "party", "college", "social" },
		-- CRITICAL FIX #10: College parties require being in college!
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Must be in college to attend college parties
			if flags.college_bound or flags.in_college or flags.college_student or flags.enrolled_college then
				return true
			end
			-- Check for university enrollment through education data
			if state.EducationData and state.EducationData.enrolledUniversity then
				return true
			end
			return false, "Need to be in college for college parties"
		end,
		
		-- CRITICAL: Random party outcome
		choices = {
			{
				text = "Party hard",
				effects = {},
				feedText = "Letting loose...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🎉 LEGENDARY night! Made memories for life!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", -2)
						state:AddFeed("🎉 Fun night but rough morning. Worth it?")
					else
						state:ModifyStat("Happiness", -5)
						state:ModifyStat("Health", -5)
						state.Flags = state.Flags or {}
						state.Flags.party_disaster = true
						state:AddFeed("🎉 Things went wrong. Regrets. Embarrassment.")
					end
				end,
			},
			{ text = "Stay home and study", effects = { Smarts = 3, Happiness = 1 }, feedText = "🎉 FOMO but grades are better for it." },
			{ text = "Show face then leave early", effects = { Happiness = 4 }, feedText = "🎉 Best of both worlds. Social but responsible." },
		},
	},
	{
		id = "college_all_nighter",
		title = "All-Nighter",
		emoji = "☕",
		text = "Major exam tomorrow and you haven't studied enough!",
		question = "How do you handle crunch time?",
		minAge = 18, maxAge = 25,
		baseChance = 0.4,
		cooldown = 2,
		stage = "adult",
		ageBand = "young_adult",
		category = "academics",
		tags = { "studying", "exam", "college" },
		-- CRITICAL FIX #11: All-nighter studying requires being in college!
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Must be in college for exam all-nighters
			if flags.college_bound or flags.in_college or flags.college_student or flags.enrolled_college then
				return true
			end
			-- Check for university enrollment through education data
			if state.EducationData and state.EducationData.enrolledUniversity then
				return true
			end
			return false, "Need to be in college for exam all-nighters"
		end,
		
		-- CRITICAL: Random exam outcome after all-nighter
		choices = {
			{
				text = "Pull an all-nighter",
				effects = { Health = -3 },
				feedText = "Coffee and textbooks...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.35 + (smarts / 200) then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 5)
						state:AddFeed("☕ It worked! Passed the exam! Exhausted but relieved!")
					elseif roll < 0.70 then
						state:ModifyStat("Smarts", 1)
						state:AddFeed("☕ Barely passed. Sleep deprivation didn't help.")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.failed_exam = true
						state:AddFeed("☕ Fell asleep during exam. Failed. Disaster.")
					end
				end,
			},
			{ text = "Accept your fate", effects = { Happiness = -2, Smarts = 1 }, feedText = "☕ Took the L. Some battles aren't worth fighting." },
			{ text = "Study group panic session", effects = { Smarts = 2, Happiness = 3 }, feedText = "☕ Misery loves company. Survived together!" },
		},
	},
	{
		id = "college_internship_hunt",
		title = "Internship Search",
		emoji = "💼",
		text = "Time to get some real-world experience!",
		question = "How does the internship search go?",
		minAge = 19, maxAge = 24,
		baseChance = 0.555,
		cooldown = 2,
		stage = "adult",
		ageBand = "young_adult",
		category = "career",
		tags = { "internship", "college", "career" },
		
		-- CRITICAL FIX #12: Internship hunt requires being in college!
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Must be in college for internship hunting
			if flags.college_bound or flags.in_college or flags.college_student or flags.enrolled_college then
				return true
			end
			-- Check for university enrollment through education data
			if state.EducationData and state.EducationData.enrolledUniversity then
				return true
			end
			return false, "Need to be in college for internship search"
		end,
		
		-- CRITICAL: Random internship outcome
		choices = {
			{
				text = "Apply to top companies",
				effects = {},
				feedText = "Submitting applications...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local acceptChance = 0.15 + (smarts / 150)
					
					if roll < acceptChance then
						state:ModifyStat("Happiness", 15)
						state.Money = (state.Money or 0) + 1000
						state.Flags = state.Flags or {}
						state.Flags.prestigious_internship = true
						state:AddFeed("💼 GOT IT! Prestigious paid internship! Career launchpad!")
					elseif roll < (acceptChance * 2.5) then
						state:ModifyStat("Happiness", 8)
						state.Money = (state.Money or 0) + 300
						state:AddFeed("💼 Got an internship! Not dream company but experience!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("💼 Rejections everywhere. Maybe next semester.")
					end
				end,
			},
			{ text = "Take unpaid for experience", effects = { Happiness = 4, Smarts = 3 }, feedText = "💼 Experience over money. Building resume." },
			{ text = "Focus on academics instead", effects = { Smarts = 3 }, feedText = "💼 Grades first. Internships can wait." },
		},
	},
	{
		-- CRITICAL FIX: Renamed from "college_graduation" to avoid duplicate ID conflict
		-- Milestones.lua has a more complete version
		id = "college_graduation_simple",
		title = "College Graduation",
		emoji = "🎓",
		text = "You made it! Graduation day!",
		question = "How does graduation feel?",
		minAge = 21, maxAge = 26,
		baseChance = 0.8,
		cooldown = 4,
		oneTime = true,
		stage = "adult",
		ageBand = "young_adult",
		category = "milestone",
		tags = { "graduation", "college", "milestone" },
		requiresFlags = { college_bound = true },
		
		choices = {
			{
				text = "Walk across the stage",
				effects = {},
				feedText = "Receiving your diploma...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.30 then
						state:ModifyStat("Happiness", 15)
						state:ModifyStat("Smarts", 5)
						state.Flags = state.Flags or {}
						state.Flags.honors_graduate = true
						state:AddFeed("🎓 Graduated with honors! Summa Cum Laude!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.college_graduate = true
						state:AddFeed("🎓 GRADUATE! Degree in hand! Proud moment!")
					else
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.college_graduate = true
						state:AddFeed("🎓 Barely made it but still counts! Degree is degree!")
					end
				end,
			},
			{ text = "Skip ceremony", effects = { Happiness = 5, Smarts = 3 }, setFlags = { college_graduate = true }, feedText = "🎓 Got degree in mail. Ceremonies are performative." },
		},
	},
}

return SchoolExpanded
