--[[
    Pet Events
    Events related to pet ownership and animal companions
    All events use randomized outcomes - NO god mode
]]

local PetEvents = {}

local STAGE = "random"

PetEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- GETTING A PET
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "pet_adoption_urge",
		title = "Pet Adoption Urge",
		emoji = "🐾",
		text = "You really want a pet!",
		question = "Do you adopt a furry friend?",
		minAge = 10, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "pets",
		tags = { "adoption", "pet", "animal" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 200 then
				return false, "Need money for pet adoption and supplies"
			end
			return true
		end,
		
		-- CRITICAL: Pet selection and outcome
		choices = {
			{
				-- CRITICAL FIX: Show price and add per-choice eligibility check
				text = "Adopt a dog ($300)",
				effects = { Money = -300 },
				feedText = "Bringing home a pup...",
				eligibility = function(state)
					if (state.Money or 0) < 300 then
						return false, "Can't afford $300 dog adoption"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					-- CRITICAL FIX: Initialize PetData for lifecycle tracking
					state.PetData = state.PetData or {}
					local dogNames = {"Max", "Buddy", "Charlie", "Rocky", "Cooper", "Duke", "Bear", "Tucker", "Jack", "Zeus", "Bailey", "Luna", "Daisy", "Sadie", "Bella"}
					state.PetData.dogName = dogNames[math.random(1, #dogNames)]
					state.PetData.dogAge = 1 -- Start at age 1
					
					if roll < 0.75 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 15) end
						state.Flags = state.Flags or {}
						state.Flags.has_dog = true
						if state.AddFeed then state:AddFeed(string.format("🐾 BEST FRIEND! %s loves you unconditionally!", state.PetData.dogName)) end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						state.Flags = state.Flags or {}
						state.Flags.has_dog = true
						if state.AddFeed then state:AddFeed(string.format("🐾 %s is adjusting. Puppy phase is challenging but worth it!", state.PetData.dogName)) end
					end
				end,
			},
			{
				-- CRITICAL FIX: Show price and add per-choice eligibility check
				text = "Adopt a cat ($200)",
				effects = { Money = -200 },
				feedText = "New feline overlord...",
				eligibility = function(state)
					if (state.Money or 0) < 200 then
						return false, "Can't afford $200 cat adoption"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					-- CRITICAL FIX: Initialize PetData for lifecycle tracking
					state.PetData = state.PetData or {}
					local catNames = {"Whiskers", "Luna", "Mittens", "Shadow", "Oliver", "Simba", "Cleo", "Tiger", "Milo", "Smokey", "Oreo", "Ginger", "Felix", "Nala", "Tigger"}
					state.PetData.catName = catNames[math.random(1, #catNames)]
					state.PetData.catAge = 1 -- Start at age 1
					
					if roll < 0.70 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 12) end
						state.Flags = state.Flags or {}
						state.Flags.has_cat = true
						if state.AddFeed then state:AddFeed(string.format("🐾 Purrfect companion! %s has chosen you as servant!", state.PetData.catName)) end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 6) end
						state.Flags = state.Flags or {}
						state.Flags.has_cat = true
						if state.AddFeed then state:AddFeed(string.format("🐾 %s is aloof but you love them anyway!", state.PetData.catName)) end
					end
				end,
			},
			{ 
			text = "Get a small pet", 
			effects = { Money = -100, Happiness = 8 }, 
			setFlags = { has_small_pet = true }, 
			feedText = "🐾 Hamster/fish/bird! Low maintenance joy!",
			-- CRITICAL FIX: Initialize PetData for small pet lifecycle tracking
			onResolve = function(state)
				state.PetData = state.PetData or {}
				state.PetData.smallPetAge = 1
				state.PetData.smallPetName = "Little Buddy"
			end,
		},
			{ text = "Not ready for a pet", effects = { Happiness = 2 }, feedText = "🐾 Pets are a big commitment. Maybe later." },
		},
	},
	{
		id = "pet_stray_encounter",
		title = "Stray Animal",
		emoji = "🐕",
		text = "You found a stray animal!",
		question = "What do you do?",
		minAge = 8, maxAge = 90,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "pets",
		tags = { "stray", "rescue", "animal" },
		
		-- CRITICAL: Random stray outcome
		choices = {
			{
				text = "Take it in",
				effects = { Money = -150 },
				feedText = "Rescuing the stray...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 12) end
						state.Flags = state.Flags or {}
						state.Flags.rescued_pet = true
						if state.AddFeed then state:AddFeed("🐕 Rescued! They're so grateful! Forever home found!") end
					elseif roll < 0.85 then
						if state.ModifyStat then state:ModifyStat("Happiness", 6) end
						if state.AddFeed then state:AddFeed("🐕 Temporary foster. Found them a good home!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 3) end
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 200)
						if state.AddFeed then state:AddFeed("🐕 Needed lots of vet care. Worth it to help.") end
					end
				end,
			},
			{ text = "Call animal control", effects = { Happiness = 4 }, feedText = "🐕 Did the responsible thing. Hope they find a home." },
			{ text = "Walk away", effects = { Happiness = -3 }, feedText = "🐕 Couldn't help. Feel guilty but couldn't commit." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- PET OWNERSHIP EVENTS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "pet_vet_visit",
		title = "Vet Visit",
		emoji = "🏥",
		text = "Time for your pet's vet visit!",
		question = "How does the checkup go?",
		minAge = 10, maxAge = 90,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "pets",
		tags = { "vet", "health", "pet" },
		
		eligibility = function(state)
			local hasPet = state.Flags and (state.Flags.has_dog or state.Flags.has_cat or state.Flags.has_small_pet)
			if not hasPet then
				return false, "Need a pet for vet visits"
			end
			return true
		end,
		
		-- CRITICAL: Random vet outcome
		choices = {
			{
				text = "Get the checkup",
				effects = { Money = -100 },
				feedText = "At the vet...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						if state.ModifyStat then state:ModifyStat("Happiness", 6) end
						if state.AddFeed then state:AddFeed("🏥 Clean bill of health! Healthy pet! Good owner!") end
					elseif roll < 0.80 then
						if state.ModifyStat then state:ModifyStat("Happiness", 2) end
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 100)
						if state.AddFeed then state:AddFeed("🏥 Minor issues. Meds prescribed. Extra cost but manageable.") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -5) end
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 500)
						state.Flags = state.Flags or {}
						state.Flags.sick_pet = true
						if state.AddFeed then state:AddFeed("🏥 Serious health issue found. Treatment needed. Expensive.") end
					end
				end,
			},
		},
	},
	{
		id = "pet_training",
		title = "Pet Training",
		emoji = "🎓",
		text = "Working on training your pet!",
		question = "How is training going?",
		minAge = 10, maxAge = 80,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "pets",
		tags = { "training", "pet", "behavior" },
		
		eligibility = function(state)
			local hasPet = state.Flags and (state.Flags.has_dog or state.Flags.has_cat)
			if not hasPet then
				return false, "Need a dog or cat to train"
			end
			return true
		end,
		
		-- CRITICAL: Random training outcome
		choices = {
			{
				text = "DIY training sessions",
				effects = {},
				feedText = "Teaching tricks...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.well_trained_pet = true
						state:AddFeed("🎓 They learned it! Good boy/girl! Training success!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🎓 Some progress. Patience required. Keep trying!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🎓 Stubborn pet. Not listening. Frustrating.")
					end
				end,
			},
			{ text = "Hire professional trainer", effects = { Money = -200, Happiness = 6 }, setFlags = { well_trained_pet = true }, feedText = "🎓 Pro trainer worked wonders! Well-behaved pet!" },
			{ text = "Accept them as they are", effects = { Happiness = 4 }, feedText = "🎓 They're perfect even untrained. Love them anyway." },
		},
	},
	{
		id = "pet_bonding",
		title = "Pet Bonding Time",
		emoji = "💕",
		text = "Quality time with your pet!",
		question = "What do you do together?",
		minAge = 5, maxAge = 100,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "pets",
		tags = { "bonding", "pet", "love" },
		
		eligibility = function(state)
			local hasPet = state.Flags and (state.Flags.has_dog or state.Flags.has_cat or state.Flags.has_small_pet)
			if not hasPet then
				return false, "Need a pet to bond with"
			end
			return true
		end,
		
		choices = {
			{ text = "Cuddles on the couch", effects = { Happiness = 10, Health = 2 }, feedText = "💕 Pure love. Best stress relief. Pet therapy!" },
			{ text = "Playtime", effects = { Happiness = 8, Health = 3 }, feedText = "💕 Running, playing, laughing! Joy for both of you!" },
			{ text = "Adventures together", effects = { Happiness = 10, Health = 4, Money = -20 }, feedText = "💕 Park/hike/outing! Making memories together!" },
			{ text = "Just appreciate them", effects = { Happiness = 6 }, feedText = "💕 Watching them sleep. How did you get so lucky?" },
		},
	},
	{
		id = "pet_mischief",
		title = "Pet Mischief",
		emoji = "😈",
		text = "Your pet got into trouble!",
		question = "What did they do?",
		minAge = 10, maxAge = 90,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "pets",
		tags = { "mischief", "pet", "trouble" },
		
		eligibility = function(state)
			local hasPet = state.Flags and (state.Flags.has_dog or state.Flags.has_cat)
			if not hasPet then
				return false, "Need a pet for mischief events"
			end
			return true
		end,
		
		-- CRITICAL: Random pet mischief
		choices = {
			{
				text = "Destroyed something",
				effects = {},
				feedText = "Surveying the damage...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("😈 Chewed up a shoe. Annoying but not tragic.") end
					elseif roll < 0.80 then
						if state.ModifyStat then state:ModifyStat("Happiness", -4) end
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 50)
						if state.AddFeed then state:AddFeed("😈 Knocked over something valuable. Replacement needed.") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -6) end
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 200)
						if state.AddFeed then state:AddFeed("😈 Major destruction! Expensive damage. Love them anyway.") end
					end
				end,
			},
			{ text = "Made a mess", effects = { Happiness = -3 }, feedText = "😈 Tracked mud everywhere. Big cleanup required." },
			{ text = "Stole food", effects = { Happiness = -1 }, feedText = "😈 Counter-surfed your dinner. Kind of impressed actually." },
			{ text = "Escaped briefly", effects = { Happiness = -5 }, feedText = "😈 Got out! Heart-pounding search. Found them safe. Relief!" },
		},
	},
	{
		id = "pet_social",
		title = "Pet Social Life",
		emoji = "🐕‍🦺",
		text = "Your pet is making friends!",
		question = "How does pet socialization go?",
		minAge = 10, maxAge = 80,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "pets",
		tags = { "social", "pet", "friends" },
		
		eligibility = function(state)
			local hasPet = state.Flags and (state.Flags.has_dog or state.Flags.has_cat)
			if not hasPet then
				return false, "Need a dog or cat for social events"
			end
			return true
		end,
		
		-- CRITICAL: Random pet social outcome
		choices = {
			{
				text = "Dog park visit",
				effects = {},
				feedText = "At the dog park...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🐕‍🦺 So much fun! Made doggy friends! You met other owners!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🐕‍🦺 Good outing. Some awkward dog interactions but okay.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🐕‍🦺 Dog fight situation! No one hurt but stressful!")
					end
				end,
			},
			{ text = "Playdate arranged", effects = { Happiness = 6, Money = -10 }, feedText = "🐕‍🦺 Pet playdate! They have a best friend now!" },
			{ text = "Pet is antisocial", effects = { Happiness = 2 }, feedText = "🐕‍🦺 Prefers just you. That's okay. Introverted pet." },
		},
	},
	{
		id = "pet_health_scare",
		title = "Pet Health Scare",
		emoji = "😰",
		text = "Something's wrong with your pet!",
		question = "How serious is it?",
		minAge = 10, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "pets",
		tags = { "health", "emergency", "pet" },
		
		eligibility = function(state)
			local hasPet = state.Flags and (state.Flags.has_dog or state.Flags.has_cat or state.Flags.has_small_pet)
			if not hasPet then
				return false, "Need a pet for health events"
			end
			return true
		end,
		
		-- CRITICAL: Random health scare outcome
		choices = {
			{
				-- CRITICAL FIX: Show price and add per-choice eligibility check
				text = "Rush to emergency vet ($300)",
				effects = { Money = -300 },
				feedText = "Emergency vet visit...",
				eligibility = function(state)
					if (state.Money or 0) < 300 then
						return false, "Can't afford $300 emergency vet visit"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddFeed then state:AddFeed("😰 False alarm! They're okay! Expensive relief!") end
					elseif roll < 0.80 then
						if state.ModifyStat then state:ModifyStat("Happiness", -3) end
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 300)
						if state.AddFeed then state:AddFeed("😰 Treatable condition. More treatment needed. Scary but hopeful.") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -8) end
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 800)
						state.Flags = state.Flags or {}
						state.Flags.critically_ill_pet = true
						if state.AddFeed then state:AddFeed("😰 Serious diagnosis. Major surgery needed. Devastated.") end
					end
				end,
			},
		},
	},
	{
		id = "pet_aging",
		title = "Aging Pet",
		emoji = "🐕‍🦺",
		text = "Your pet is getting older...",
		question = "How do you handle their golden years?",
		minAge = 25, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "pets",
		tags = { "aging", "senior_pet", "love" },
		
		eligibility = function(state)
			local hasPet = state.Flags and (state.Flags.has_dog or state.Flags.has_cat)
			if not hasPet then
				return false, "Need a pet for aging events"
			end
			return true
		end,
		
		choices = {
			{ text = "Extra love and comfort ($50)", effects = { Happiness = 6, Money = -50 }, feedText = "🐕‍🦺 Making their senior years the best. Soft beds, gentle walks." },
			{ 
				-- CRITICAL FIX: Show price and add per-choice eligibility check
				text = "Expensive treatments ($500)", 
				effects = { Happiness = 4, Money = -500 }, 
				feedText = "🐕‍🦺 Whatever it takes for more time. Money well spent.",
				eligibility = function(state)
					if (state.Money or 0) < 500 then
						return false, "Can't afford $500 pet treatments"
					end
					return true
				end,
			},
			{ text = "Accept the circle of life", effects = { Happiness = 2, Smarts = 2 }, feedText = "🐕‍🦺 Cherishing every moment. Quality of life matters." },
		},
	},
	{
		id = "pet_loss",
		title = "Pet Loss",
		emoji = "🌈",
		text = "Your beloved pet crossed the rainbow bridge...",
		question = "How do you cope with the loss?",
		minAge = 10, maxAge = 100,
		baseChance = 0.32,
		cooldown = 4,
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "milestone",
		tags = { "loss", "grief", "pet" },
		
		eligibility = function(state)
			local hasPet = state.Flags and (state.Flags.has_dog or state.Flags.has_cat or state.Flags.has_small_pet)
			if not hasPet then
				return false, "Need a pet for loss events"
			end
			return true
		end,
		
		choices = {
			{
				text = "Grieve and remember",
				effects = {},
				feedText = "Mourning your companion...",
				onResolve = function(state)
					state:ModifyStat("Happiness", -10)
					state:ModifyStat("Health", -3)
					state.Flags = state.Flags or {}
					state.Flags.has_dog = nil
					state.Flags.has_cat = nil
					state.Flags.has_small_pet = nil
					state.Flags.grieving_pet = true
					state:AddFeed("🌈 Hardest goodbye. They were family. Heartbroken but grateful for the time.")
				end,
			},
			{
				text = "Create a memorial",
				effects = { Money = -100 },
				feedText = "Honoring their memory...",
				onResolve = function(state)
					state:ModifyStat("Happiness", -8)
					state:ModifyStat("Smarts", 2)
					state.Flags = state.Flags or {}
					state.Flags.has_dog = nil
					state.Flags.has_cat = nil
					state.Flags.has_small_pet = nil
					state.Flags.pet_memorial = true
					state:AddFeed("🌈 Memorial planted/created. They're remembered forever.")
				end,
			},
		},
	},
	{
		id = "pet_new_after_loss",
		title = "Ready for New Pet?",
		emoji = "🐾",
		text = "Are you ready to love again?",
		question = "Do you open your heart to a new pet?",
		minAge = 10, maxAge = 90,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "pets",
		tags = { "adoption", "new_pet", "healing" },
		
		requiresFlags = { grieving_pet = true },
		
		choices = {
			{
				text = "Adopt again",
				effects = { Money = -250 },
				feedText = "Opening your home and heart...",
				onResolve = function(state)
					state:ModifyStat("Happiness", 12)
					state.Flags = state.Flags or {}
					state.Flags.grieving_pet = nil
					state.Flags.has_dog = true
					state:AddFeed("🐾 Not replacing, adding to your heart. New friend. New joy.")
				end,
			},
			{ text = "Not yet", effects = { Happiness = 2 }, feedText = "🐾 Still healing. The right time will come." },
			{ text = "Never again - too painful", effects = { Happiness = -2 }, setFlags = { no_more_pets = true }, feedText = "🐾 Can't go through loss again. Understand completely." },
		},
	},
	{
		id = "pet_fame",
		title = "Pet Internet Fame",
		emoji = "⭐",
		text = "Your pet is becoming famous online!",
		question = "How does pet fame go?",
		minAge = 15, maxAge = 80,
		baseChance = 0.25,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "pets",
		tags = { "fame", "social_media", "pet" },
		
		eligibility = function(state)
			local hasPet = state.Flags and (state.Flags.has_dog or state.Flags.has_cat)
			if not hasPet then
				return false, "Need a photogenic pet"
			end
			return true
		end,
		
		-- CRITICAL: Random pet fame outcome
		choices = {
			{
				text = "Embrace the fame",
				effects = {},
				feedText = "Posting more pet content...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 15)
						state.Money = (state.Money or 0) + 500
						state.Flags = state.Flags or {}
						state.Flags.famous_pet = true
						state:AddFeed("⭐ PET INFLUENCER! Brand deals for your pet! Crazy!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 8)
						state.Money = (state.Money or 0) + 100
						state:AddFeed("⭐ Growing following! Pet has more fans than you!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("⭐ Flash in the pan. Fame is fickle. Still love them!")
					end
				end,
			},
			{ text = "Keep them private", effects = { Happiness = 4 }, feedText = "⭐ Not exploiting your pet. They're family, not content." },
		},
	},
}

return PetEvents
