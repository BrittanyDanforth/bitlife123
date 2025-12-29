--[[
    Community & Social Events
    Events related to community involvement, neighborhood, and social situations
    All events use randomized outcomes - NO god mode
]]

local CommunityEvents = {}

local STAGE = "random"

CommunityEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- NEIGHBORHOOD EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "community_new_neighbors",
		title = "New Neighbors",
		emoji = "🏠",
		text = "New people moved in next door!",
		question = "How do you greet them?",
		minAge = 18, maxAge = 90,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "community",
		tags = { "neighbors", "social", "community" },
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true }, -- CRITICAL FIX #329: No neighbors in prison/homeless
		
		-- CRITICAL: Random neighbor outcome
		choices = {
			{
				text = "Bring them a welcome gift ($20)",
				effects = { Money = -20 },
				eligibility = function(state) return (state.Money or 0) >= 20, "Can't afford a gift right now" end,
				feedText = "Knocking on their door...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.good_neighbors = true
						state:AddFeed("🏠 They're wonderful! New friends made!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🏠 Nice enough. Polite wave neighbors.")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🏠 Barely acknowledged your gift. Cold.")
					end
				end,
			},
			{
				text = "Wait for them to introduce themselves",
				effects = {},
				feedText = "Waiting...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🏠 They came over! Nice people!")
					else
						state:ModifyStat("Happiness", 1)
						state:AddFeed("🏠 Never introduced themselves. Strangers forever.")
					end
				end,
			},
			{ text = "Keep to yourself", effects = { Happiness = 1 }, feedText = "🏠 Good fences make good neighbors." },
		},
	},
	{
		id = "community_neighborhood_dispute",
		title = "Neighborhood Dispute",
		emoji = "😤",
		text = "There's a conflict brewing in the neighborhood!",
		question = "What's the dispute about?",
		minAge = 18, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "community",
		tags = { "conflict", "neighbors", "dispute" },
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true }, -- CRITICAL FIX #330: No neighborhood disputes in prison
		
		choices = {
			{
				text = "Noise complaints",
				effects = {},
				feedText = "Dealing with noise issues...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("😤 Talked it out. They'll keep it down.")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("😤 Ongoing issue. Earplugs became necessary.")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.bad_neighbors = true
						state:AddFeed("😤 They're hostile now. Neighborhood feud begins.")
					end
				end,
			},
			{ text = "Parking wars", effects = { Happiness = -4 }, setFlags = { parking_feud = true }, feedText = "😤 Someone took your spot. This means war." },
			{ text = "Property line disagreement", effects = { Happiness = -3 }, feedText = "😤 Had to deal with boundary disputes. Stressful." },
			{ text = "Pet issues", effects = { Happiness = -3 }, feedText = "😤 Their pet is causing problems. Awkward confrontation." },
		},
	},
	{
		id = "community_block_party",
		title = "Block Party",
		emoji = "🎊",
		text = "The neighborhood is having a block party!",
		question = "Do you participate?",
		minAge = 8, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "community",
		tags = { "party", "neighbors", "community" },
		
		choices = {
			{
				text = "Help organize and host ($30)",
				effects = { Money = -30 },
				feedText = "Setting up the party...",
				eligibility = function(state) return (state.Money or 0) >= 30, "Need $30 to help with supplies" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 12) end
						state.Flags = state.Flags or {}
						state.Flags.community_leader = true
						if state.AddFeed then state:AddFeed("🎊 Huge success! Everyone loves you now!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 4) end
						if state.AddFeed then state:AddFeed("🎊 It was okay. Some hiccups but overall good.") end
					end
				end,
			},
			{ text = "Attend and mingle", effects = { Happiness = 7 }, feedText = "🎊 Free food, good company! Love the community!" },
			{ text = "Make a brief appearance", effects = { Happiness = 3 }, feedText = "🎊 Said hi to a few people. Social quota met." },
			{ text = "Stay inside", effects = { Happiness = 2 }, feedText = "🎊 Crowds aren't your thing. That's okay." },
		},
	},
	{
		id = "community_crime_incident",
		title = "Neighborhood Crime",
		emoji = "🚔",
		text = "Something happened in your neighborhood!",
		question = "What was the incident?",
		minAge = 12, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "crime",
		tags = { "crime", "neighborhood", "safety" },
		-- CRITICAL FIX: Can't have neighborhood crime while YOU are in prison!
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		choices = {
			{
				text = "Break-in nearby",
				effects = {},
				feedText = "Police in the neighborhood...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.20 then
						if state.ModifyStat then state:ModifyStat("Happiness", -10) end
						-- CRITICAL FIX: Don't go negative
						local loss = math.min(500, state.Money or 0)
						state.Money = math.max(0, (state.Money or 0) - loss)
						state.Flags = state.Flags or {}
						state.Flags.home_burglarized = true
						if state.AddFeed then 
							if loss > 0 then
								state:AddFeed(string.format("🚔 YOUR place was hit. Violated. Lost $%d in valuables.", loss))
							else
								state:AddFeed("🚔 YOUR place was hit. Luckily nothing valuable was taken.")
							end
						end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -4) end
						if state.AddFeed then state:AddFeed("🚔 Neighbor got hit. Scary. Upgrading security.") end
					end
				end,
			},
			{ text = "Car vandalized", effects = { Happiness = -6 }, feedText = "🚔 Someone keyed your car. Why?!" },
			{ text = "Package theft", effects = { Happiness = -4 }, setFlags = { package_stolen = true }, feedText = "🚔 Porch pirates took your delivery. Frustrating." },
			{ text = "Suspicious person reported", effects = { Happiness = -2 }, feedText = "🚔 Neighborhood on alert. Staying vigilant." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- VOLUNTEERING & CHARITY
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "community_volunteer_opportunity",
		title = "Volunteer Opportunity",
		emoji = "🤝",
		text = "There's a chance to volunteer for a good cause!",
		question = "Do you volunteer your time?",
		minAge = 12, maxAge = 90,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "charity",
		tags = { "volunteer", "charity", "giving" },
		
		choices = {
			{
				text = "Give it your all",
				effects = {},
				feedText = "Volunteering your time...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then
							state:ModifyStat("Happiness", 12)
							state:ModifyStat("Smarts", 2)
						end
						state.Flags = state.Flags or {}
						state.Flags.active_volunteer = true
						if state.AddFeed then state:AddFeed("🤝 Made a real difference! Fulfilling experience!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 6) end
						if state.AddFeed then state:AddFeed("🤝 Helped out. Good for the soul.") end
					end
				end,
			},
			{ text = "Donate money instead ($50)", effects = { Happiness = 5, Money = -50 }, feedText = "🤝 Time is money, gave money instead. Still helps!", eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 to donate" end },
			{ text = "Too busy right now", effects = { Happiness = -1 }, feedText = "🤝 Maybe next time. Life is hectic." },
		},
	},
	{
		id = "community_charity_event",
		title = "Charity Event",
		emoji = "💝",
		text = "A charity event is happening in your community!",
		question = "How do you participate?",
		minAge = 15, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "charity",
		tags = { "charity", "fundraising", "community" },
		
		choices = {
			{
				text = "Participate in charity run/walk ($30)",
				effects = { Health = 3, Money = -30 },
				feedText = "Running for a cause...",
				eligibility = function(state) return (state.Money or 0) >= 30, "💸 Can't afford entry fee ($30)" end,
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					
					if roll < 0.70 then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("💝 Finished! Raised money and felt great!")
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("💝 Struggled but completed it. Proud of trying.")
					end
				end,
			},
			{ text = "Attend charity gala ($100)", effects = { Happiness = 7, Money = -100, Looks = 2 }, feedText = "💝 Fancy night for a good cause. Networking bonus!",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Can't afford gala ticket ($100)" end },
			{ text = "Silent auction bid ($200)", effects = { Money = -200, Happiness = 6 }, feedText = "💝 Won something nice! And supported charity!",
				eligibility = function(state) return (state.Money or 0) >= 200, "💸 Can't afford to bid ($200)" end },
			{ text = "Just donate ($25)", effects = { Money = -25, Happiness = 4 }, feedText = "💝 Quick donation. Every bit helps.",
				eligibility = function(state) return (state.Money or 0) >= 25, "💸 Can't afford donation ($25)" end },
			{ text = "Volunteer time instead", effects = { Happiness = 8, Health = -1 }, feedText = "💝 Time is valuable too! Helped set up and run the event." },
		},
	},
	{
		id = "community_food_bank",
		title = "Food Bank",
		emoji = "🍲",
		text = "The local food bank needs help!",
		question = "How do you help?",
		minAge = 10, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "charity",
		tags = { "food_bank", "volunteer", "helping" },
		
		choices = {
			{ text = "Volunteer to sort/distribute", effects = { Happiness = 10, Health = -1 }, setFlags = { food_bank_volunteer = true }, feedText = "🍲 Hard work but so rewarding! Making a difference!" },
			{ 
				text = "Donate food items ($40)", 
				effects = { Happiness = 6, Money = -40 }, 
				feedText = "🍲 Cleaned out pantry for a good cause!",
				eligibility = function(state) return (state.Money or 0) >= 40, "💸 Can't afford to donate food ($40)" end,
			},
			{ text = "Organize a food drive", effects = { Happiness = 8, Smarts = 2 }, setFlags = { organized_drive = true }, feedText = "🍲 Rallied the community! Collected tons!" },
		},
	},
	{
		id = "community_animal_shelter",
		title = "Animal Shelter",
		emoji = "🐕",
		text = "The local animal shelter needs support!",
		question = "How do you help the animals?",
		minAge = 10, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "charity",
		tags = { "animals", "volunteer", "shelter" },
		
		choices = {
			{
				text = "Volunteer to walk dogs",
				effects = {},
				feedText = "Walking shelter dogs...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Health", 2)
						state.Flags = state.Flags or {}
						state.Flags.animal_volunteer = true
						state:AddFeed("🐕 Pure joy! Dogs are the best! Want to adopt all of them!")
					else
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🐕 Good experience. Helped some good boys.")
					end
				end,
			},
			{ 
				text = "Foster an animal temporarily ($50)", 
				effects = { Happiness = 8, Money = -50 }, 
				setFlags = { fostered_animal = true }, 
				feedText = "🐕 Temporary pet parent! Emotional but rewarding!",
				eligibility = function(state) return (state.Money or 0) >= 50, "💸 Can't afford fostering supplies ($50)" end,
			},
			{ 
				text = "Donate supplies ($30)", 
				effects = { Happiness = 5, Money = -30 }, 
				feedText = "🐕 Food, toys, blankets - they need it all!",
				eligibility = function(state) return (state.Money or 0) >= 30, "💸 Can't afford to donate ($30)" end,
			},
			{ 
				text = "Adopt! ($100)", 
				effects = { Happiness = 15, Money = -100 }, 
				setFlags = { adopted_pet = true }, 
				feedText = "🐕 Fell in love. Now have a furry family member!",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Can't afford adoption fee ($100)" end,
			},
			{ text = "Just spend time with the animals", effects = { Happiness = 6 }, feedText = "🐕 Petted all the cute animals! They love visitors!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CIVIC ENGAGEMENT
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "community_voting",
		title = "Election Day",
		emoji = "🗳️",
		text = "It's election day! Time to vote!",
		question = "Do you exercise your civic duty?",
		minAge = 18, maxAge = 100,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "civic",
		tags = { "voting", "election", "civic" },
		
		choices = {
			{
				text = "Vote after researching candidates",
				effects = { Smarts = 2 },
				feedText = "Casting your informed vote...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.voted = true
						state:AddFeed("🗳️ Your candidate won! Voice heard! Democracy works!")
					else
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.voted = true
						state:AddFeed("🗳️ Your candidate lost but you participated.")
					end
				end,
			},
			{ text = "Quick vote on party lines", effects = { Happiness = 3 }, setFlags = { voted = true }, feedText = "🗳️ Civic duty done. Hope it matters." },
			{ text = "Skip voting", effects = { Happiness = -1 }, feedText = "🗳️ Didn't vote. Can't complain about results then." },
		},
	},
	{
		id = "community_town_hall",
		title = "Town Hall Meeting",
		emoji = "🏛️",
		text = "There's a town hall meeting about a local issue!",
		question = "Do you attend and participate?",
		minAge = 18, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "civic",
		tags = { "politics", "local", "community" },
		
		choices = {
			{
				text = "Speak up about your concerns",
				effects = {},
				feedText = "Taking the microphone...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.40 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.civic_activist = true
						state:AddFeed("🏛️ Your point resonated! People agreed! Change possible!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🏛️ Said your piece. Some nodded. Progress maybe?")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🏛️ Booed or ignored. Politics is frustrating.")
					end
				end,
			},
			{ text = "Listen and observe", effects = { Smarts = 3, Happiness = 2 }, feedText = "🏛️ Learned a lot about local issues." },
			{ text = "Skip it - doesn't affect you", effects = {}, feedText = "🏛️ Had better things to do. Probably." },
		},
	},
	{
		id = "community_petition",
		title = "Community Petition",
		emoji = "📝",
		text = "Someone is collecting signatures for a local petition!",
		question = "Do you sign?",
		minAge = 16, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "civic",
		tags = { "petition", "activism", "community" },
		
		choices = {
			{
				text = "Read it and sign if you agree",
				effects = {},
				feedText = "Reading the petition...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.signed_petition = true
						state:AddFeed("📝 Good cause! Signed proudly!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📝 Didn't agree. Politely declined.")
					end
				end,
			},
			{ text = "Help collect signatures", effects = { Happiness = 6, Smarts = 2 }, setFlags = { petition_collector = true }, feedText = "📝 Activist mode! Collected dozens of signatures!" },
			{ text = "Walk past", effects = {}, feedText = "📝 Not today. Avoided eye contact." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- LOCAL BUSINESSES & SERVICES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "community_local_business",
		title = "Local Business",
		emoji = "🏪",
		text = "A local business is having a situation!",
		question = "What's happening?",
		minAge = 15, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "community",
		tags = { "business", "local", "shopping" },
		
		choices = {
			{ text = "Grand opening celebration ($20)", effects = { Happiness = 6, Money = -20 }, feedText = "🏪 New store! Free samples! Supporting local!" },
			{ text = "Going out of business sale ($50)", effects = { Happiness = 3, Money = -50 }, feedText = "🏪 Sad to see them go. Got some deals though." },
			{ text = "Become a regular customer ($30)", effects = { Happiness = 5, Money = -30 }, setFlags = { supports_local = true }, feedText = "🏪 Know the staff by name now. Community!" },
			{ text = "Just window shopping", effects = { Happiness = 3 }, feedText = "🏪 Nice to look around! Didn't buy anything but enjoyed it." },
			{ text = "Bad service experience", effects = { Happiness = -4 }, feedText = "🏪 Not going back there. Left bad review." },
		},
	},
	{
		id = "community_farmers_market",
		title = "Farmers Market",
		emoji = "🥕",
		text = "The weekly farmers market is happening!",
		question = "Do you check it out?",
		minAge = 10, maxAge = 90,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "community",
		tags = { "farmers_market", "food", "local" },
		
		choices = {
			{ text = "Buy fresh local produce ($25)", effects = { Happiness = 6, Health = 3, Money = -25 }, feedText = "🥕 Fresh veggies! Supporting local farmers!" },
			{ text = "Browse and sample ($5)", effects = { Happiness = 4, Money = -5 }, feedText = "🥕 Free samples! Discovered new favorite foods!" },
			{ text = "Buy artisan goods ($40)", effects = { Happiness = 5, Money = -40 }, feedText = "🥕 Unique handmade items. Worth the premium." },
			{ text = "Just enjoy the atmosphere", effects = { Happiness = 4 }, feedText = "🥕 Live music, fresh air, good vibes! No purchase needed." },
			{ text = "Too crowded - leave", effects = { Happiness = -1 }, feedText = "🥕 Wall-to-wall people. Maybe next time." },
		},
	},
	{
		id = "community_library",
		title = "Library Visit",
		emoji = "📚",
		text = "You're at the local library!",
		question = "How do you spend your time?",
		minAge = 6, maxAge = 90,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "community",
		tags = { "library", "reading", "community" },
		
		choices = {
			{ text = "Get lost in books", effects = { Happiness = 7, Smarts = 4 }, setFlags = { library_regular = true }, feedText = "📚 Hours disappeared! Found amazing reads!" },
			{ text = "Attend a free program/event", effects = { Happiness = 5, Smarts = 3 }, feedText = "📚 Libraries offer so much! Free education!" },
			{ text = "Use free wifi and computers", effects = { Happiness = 4, Smarts = 2 }, feedText = "📚 Free internet! Productive time!" },
			{ text = "Study/work in quiet space", effects = { Smarts = 5, Happiness = 3 }, feedText = "📚 Perfect focus. Got so much done." },
		},
	},
	{
		id = "community_gym_class",
		title = "Community Fitness Class",
		emoji = "💪",
		text = "Free fitness class at the community center!",
		question = "Do you join?",
		minAge = 15, maxAge = 80,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "fitness", "exercise", "community" },
		
		-- CRITICAL: Random fitness class outcome
		choices = {
			{
				text = "Give it your all",
				effects = {},
				feedText = "Working out...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					
					if roll < 0.60 then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 8)
						state:AddFeed("💪 Great workout! Endorphins pumping!")
					elseif roll < 0.85 then
						state:ModifyStat("Health", 3)
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💪 Struggled but finished! Progress!")
					else
						state:ModifyStat("Health", 1)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("💪 Pulled something. Ouch. Take it easy.")
					end
				end,
			},
			{ text = "Watch from the side", effects = { Happiness = 2 }, feedText = "💪 Too intimidated to join. Maybe next time." },
			{ text = "Make gym friends", effects = { Happiness = 6, Health = 3 }, setFlags = { gym_buddies = true }, feedText = "💪 Workout accountability partners! Social AND fit!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SOCIAL SITUATIONS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "community_group_join",
		title = "Join a Group",
		emoji = "👋",
		text = "There's a community group you could join!",
		question = "What kind of group interests you?",
		minAge = 15, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "social",
		tags = { "club", "social", "hobbies" },
		
		choices = {
			{
				text = "Hobby/interest group",
				effects = {},
				feedText = "Joining the group...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.hobby_group_member = true
						state:AddFeed("👋 Found your people! Same interests, new friends!")
					else
						state:ModifyStat("Happiness", 4)
						state:AddFeed("👋 Not quite your vibe. Tried it though.")
					end
				end,
			},
			{ text = "Professional networking group", effects = { Smarts = 3, Happiness = 4, Money = 50 }, setFlags = { networker = true }, feedText = "👋 Building connections! Career opportunities!" },
			{ text = "Sports/recreation league", effects = { Health = 4, Happiness = 6 }, setFlags = { rec_league = true }, feedText = "👋 Active social life! Team bonding!" },
			{ text = "Book club", effects = { Smarts = 4, Happiness = 5 }, setFlags = { book_club = true }, feedText = "👋 Deep discussions! Intellectual friends!" },
		},
	},
	{
		id = "community_public_event",
		title = "Public Event",
		emoji = "🎪",
		text = "There's a big public event happening!",
		question = "What kind of event is it?",
		minAge = 8, maxAge = 90,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "experience",
		tags = { "event", "public", "entertainment" },
		
		choices = {
			{ text = "Concert in the park", effects = { Happiness = 10 }, feedText = "🎪 Free music! Dancing! Summer vibes!" },
			{ text = "Local festival", effects = { Happiness = 8 }, feedText = "🎪 Food, games, culture! Community celebration!" },
			{ text = "Art walk/gallery night", effects = { Happiness = 6, Smarts = 3 }, feedText = "🎪 Culture vulture! Local art appreciation!" },
			{ text = "Outdoor movie", effects = { Happiness = 7 }, feedText = "🎪 Blankets and popcorn! Movie magic under stars!" },
			{ text = "Skip it - stay home", effects = { Happiness = 2 }, feedText = "🎪 FOMO is real but couch is comfy." },
		},
	},
	{
		id = "community_religious_event",
		title = "Religious/Spiritual Event",
		emoji = "🙏",
		text = "There's a religious or spiritual event in your community.",
		question = "Do you participate?",
		minAge = 10, maxAge = 100,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "spiritual",
		tags = { "religion", "spiritual", "community" },
		
		choices = {
			{ text = "Attend as a believer", effects = { Happiness = 8, Smarts = 1 }, setFlags = { religious = true }, feedText = "🙏 Spiritually fulfilling. Community of faith." },
			{ text = "Attend to learn/observe", effects = { Happiness = 4, Smarts = 3 }, feedText = "🙏 Interesting cultural experience. Respectful curiosity." },
			{ text = "Not your thing", effects = { Happiness = 1 }, feedText = "🙏 Different beliefs. That's okay." },
		},
	},
	{
		id = "community_support_group",
		title = "Support Group",
		emoji = "💙",
		text = "There's a support group that might help you.",
		question = "Do you attend?",
		minAge = 16, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "health",
		tags = { "support", "mental_health", "community" },
		
		choices = {
			{
				text = "Open up and share",
				effects = {},
				feedText = "Sharing your story...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Health", 3)
						state.Flags = state.Flags or {}
						state.Flags.support_group = true
						state:AddFeed("💙 You're not alone. Understanding and growth.")
					else
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💙 Hard to open up but first step taken.")
					end
				end,
			},
			{ text = "Just listen", effects = { Happiness = 5, Smarts = 2 }, feedText = "💙 Learned from others' experiences. Helpful." },
			{ text = "Not ready yet", effects = { Happiness = 1 }, feedText = "💙 Maybe another time. No pressure." },
		},
	},
	{
		id = "community_coaching",
		title = "Youth Coaching",
		emoji = "🏅",
		text = "The community youth sports team needs volunteer coaches!",
		question = "Do you help out?",
		minAge = 25, maxAge = 70,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "volunteer",
		tags = { "coaching", "youth", "sports" },
		
		-- CRITICAL: Random coaching outcome
		choices = {
			{
				text = "Become assistant coach",
				effects = {},
				feedText = "Taking on coaching duties...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Health", 2)
						state.Flags = state.Flags or {}
						state.Flags.youth_coach = true
						state:AddFeed("🏅 Kids are amazing! Making a difference! Rewarding!")
					else
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Health", -1)
						state:AddFeed("🏅 Harder than expected. Kids are a handful.")
					end
				end,
			},
			{ text = "Just be a supportive parent/attendee", effects = { Happiness = 4 }, feedText = "🏅 Cheering from sidelines. Good enough." },
			{ text = "No time for that", effects = { Happiness = 1 }, feedText = "🏅 Someone else will step up. Too busy." },
		},
	},
}

return CommunityEvents
