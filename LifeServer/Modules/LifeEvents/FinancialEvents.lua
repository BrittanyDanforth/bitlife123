--[[
    Financial Events
    Comprehensive financial situations across all life stages
    All events use randomized outcomes - NO god mode
]]

local FinancialEvents = {}

local STAGE = "random"

FinancialEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- INCOME & OPPORTUNITIES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "fin_unexpected_income",
		title = "Unexpected Income",
		emoji = "💵",
		text = "Money came from an unexpected source!",
		question = "Where did it come from?",
		minAge = 18, maxAge = 90,
		baseChance = 0.35, -- CRITICAL FIX: Reduced from 0.4 to prevent spam
		cooldown = 5, -- CRITICAL FIX: Increased from 4 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "money", "income", "windfall" },
		-- CRITICAL FIX: Block in prison/homeless situations
		blockedByFlags = { in_prison = true, incarcerated = true, homeless = true },
		
		-- CRITICAL: Random windfall amounts
		choices = {
			{
				text = "Check the mail",
				effects = {},
				feedText = "Opening the envelope...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 10)
						state:AddFeed("💵 Tax refund! $500 back! Time to treat yourself!")
					elseif roll < 0.55 then
						state.Money = (state.Money or 0) + 200
						state:ModifyStat("Happiness", 6)
						state:AddFeed("💵 Insurance reimbursement! $200!")
					elseif roll < 0.75 then
						state.Money = (state.Money or 0) + 50
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💵 Class action settlement check. $50. Better than nothing!")
					else
						state.Money = (state.Money or 0) + 20
						state:ModifyStat("Happiness", 2)
						state:AddFeed("💵 Found $20 in old jacket. Nice little bonus!")
					end
				end,
			},
			{
				text = "Inheritance notice",
				effects = {},
				feedText = "Reading the letter...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.15 then
						state.Money = (state.Money or 0) + 10000
						state:ModifyStat("Happiness", 12)
						state:AddFeed("💵 Distant relative left you $10,000! Unexpected fortune!")
					elseif roll < 0.40 then
						state.Money = (state.Money or 0) + 2000
						state:ModifyStat("Happiness", 8)
						state:AddFeed("💵 Small inheritance. $2,000. Bittersweet.")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("💵 Inherited sentimental items, not money. Still meaningful.")
					end
				end,
			},
		},
	},
	{
		id = "fin_side_hustle_opportunity",
		title = "Side Hustle Chance",
		emoji = "📱",
		text = "An opportunity for extra income presents itself!",
		question = "What's the side hustle?",
		minAge = 16, maxAge = 70,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "side_hustle", "income", "work" },
		blockedByFlags = { in_prison = true, incarcerated = true }, -- CRITICAL FIX #326: Can't do side hustles from prison
		
		choices = {
			{
				text = "Gig economy work (delivery/rideshare)",
				effects = { Health = -2 },
				feedText = "Doing gig work...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state.Money = (state.Money or 0) + 200
						state:ModifyStat("Happiness", 4)
						state:AddFeed("📱 Made $200 this week! Flexible income!")
					elseif roll < 0.80 then
						state.Money = (state.Money or 0) + 80
						state:ModifyStat("Happiness", 2)
						state:AddFeed("📱 Slow week. Only $80. Gas cost cut into profits.")
					else
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 50)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📱 Car trouble during gig. Actually lost money!")
					end
				end,
			},
			{
				text = "Sell items online",
				effects = {},
				feedText = "Listing items for sale...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state.Money = (state.Money or 0) + 150
						state:ModifyStat("Happiness", 6)
						state:AddFeed("📱 Sold old stuff! $150! Declutter AND profit!")
					else
						state:ModifyStat("Happiness", -1)
						state:AddFeed("📱 No buyers. Maybe lower prices?")
					end
				end,
			},
			{
				text = "Freelance your skills",
				effects = {},
				feedText = "Finding freelance work...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.30 + (smarts / 150) then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.freelancer = true
						state:AddFeed("📱 Great gig! $500 for your expertise!")
					elseif roll < 0.70 then
						state.Money = (state.Money or 0) + 100
						state:ModifyStat("Happiness", 4)
						state:AddFeed("📱 Small project. $100. Building portfolio!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📱 Client ghosted after work done. Frustrating!")
					end
				end,
			},
		},
	},
	{
		id = "fin_bonus_at_work",
		title = "Work Bonus",
		emoji = "💰",
		text = "There's talk of bonuses at work!",
		question = "Did you get a bonus?",
		minAge = 18, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "career",
		tags = { "bonus", "work", "income" },
		requiresJob = true,
		blockedByFlags = { in_prison = true, incarcerated = true }, -- CRITICAL FIX #327: Can't get work bonus from prison
		
		-- CRITICAL: Random bonus outcome
		choices = {
			{
				text = "Wait and see",
				effects = {},
				feedText = "Checking your account...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state.Money = (state.Money or 0) + 1000
						state:ModifyStat("Happiness", 12)
						state:AddFeed("💰 HUGE BONUS! $1000! Hard work recognized!")
					elseif roll < 0.55 then
						state.Money = (state.Money or 0) + 300
						state:ModifyStat("Happiness", 6)
						state:AddFeed("💰 Decent bonus. $300. Not bad!")
					elseif roll < 0.80 then
						state.Money = (state.Money or 0) + 50
						state:ModifyStat("Happiness", 2)
						state:AddFeed("💰 Token bonus. $50. Better than nothing I guess.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("💰 No bonus for you. Budgets tight apparently.")
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- EXPENSES & EMERGENCIES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "fin_major_expense",
		title = "Major Expense",
		emoji = "💸",
		text = "A major expense has come up!",
		question = "What's the big cost?",
		minAge = 18, maxAge = 90,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "expense", "emergency", "cost" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 50 then
				return false, "Already broke"
			end
			return true
		end,
		
		choices = {
			{
				text = "Appliance broke",
				effects = {},
				feedText = "Assessing the damage...",
				onResolve = function(state)
					local roll = math.random()
					-- CRITICAL FIX: Prevent negative money in all branches
					if roll < 0.40 then
						state.Money = math.max(0, (state.Money or 0) - 800)
						state:ModifyStat("Happiness", -6)
						state:AddFeed("💸 Need new fridge. $800. Ouch.")
					elseif roll < 0.70 then
						state.Money = math.max(0, (state.Money or 0) - 400)
						state:ModifyStat("Happiness", -4)
						state:AddFeed("💸 Washing machine died. $400 repair.")
					else
						state.Money = math.max(0, (state.Money or 0) - 150)
						state:ModifyStat("Happiness", -2)
						state:AddFeed("💸 Minor appliance issue. $150. Manageable.")
					end
				end,
			},
			{ text = "Medical bill", effects = { Happiness = -5, Health = 2 }, feedText = "💸 Healthcare is expensive. At least you're treated." },
			-- CRITICAL FIX: Home repair requires owning a home!
			{ 
				text = "Home repair needed", 
				effects = { Happiness = -4 }, 
				feedText = "💸 Roof leak/plumbing/HVAC. Homeowner problems.",
				eligibility = function(state)
					local flags = state.Flags or {}
					return flags.homeowner or flags.has_house or flags.has_home or flags.has_apartment
						or (state.Assets and state.Assets.Properties and #state.Assets.Properties > 0)
				end,
			onResolve = function(state)
				local roll = math.random()
				-- CRITICAL FIX: Prevent negative money
				state.Money = math.max(0, (state.Money or 0) - math.floor(200 + (roll * 1000)))
			end,
			},
			-- CRITICAL FIX: Pet emergency requires owning a pet and show price!
			{ 
				text = "Pet emergency ($500)", 
				effects = { Happiness = -6, Money = -500 }, 
				setFlags = { pet_medical_bills = true }, 
				feedText = "💸 Vet bills are brutal but you love your pet.",
				eligibility = function(state)
					-- Must have money AND a pet
					if (state.Money or 0) < 500 then
						return false, "💸 Need $500 for vet bills"
					end
					local flags = state.Flags or {}
					return flags.has_pet or flags.has_dog or flags.has_cat or flags.has_small_pet
				end,
			},
		},
	},
	{
		id = "fin_car_expense",
		title = "Vehicle Expense",
		emoji = "🚗",
		text = "Your vehicle needs attention!",
		question = "What's wrong with the car?",
		minAge = 18, maxAge = 90,
		baseChance = 0.18,  -- CRITICAL FIX: Reduced from 0.55 to prevent spam (multiple car events exist)
		cooldown = 6,  -- CRITICAL FIX: Increased to space out car expense events
		stage = STAGE,
		ageBand = "any",
		category = "transportation",
		tags = { "car", "expense", "repair" },
		
		eligibility = function(state)
			-- Check if player has a vehicle
			if state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0 then
				return true
			end
			return false, "No vehicle to repair"
		end,
		
		-- CRITICAL: Random car expense
		choices = {
			{
				text = "Take it to the mechanic",
				effects = {},
				feedText = "Getting it checked out...",
				onResolve = function(state)
					local roll = math.random()
					-- CRITICAL FIX: Prevent negative money in all branches
					if roll < 0.25 then
						state.Money = math.max(0, (state.Money or 0) - 1500)
						state:ModifyStat("Happiness", -8)
						state:AddFeed("🚗 Major repair. Transmission/engine. $1500. Devastating.")
					elseif roll < 0.50 then
						state.Money = math.max(0, (state.Money or 0) - 600)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🚗 Moderate repair. Brakes/suspension. $600.")
					elseif roll < 0.75 then
						state.Money = math.max(0, (state.Money or 0) - 200)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🚗 Minor fix. $200. Relief!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🚗 False alarm! Nothing serious wrong!")
					end
				end,
			},
			{ text = "DIY repair attempt", effects = { Smarts = 2 }, feedText = "🚗 YouTube mechanic mode. Saved some money, maybe.",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🚗 Fixed it yourself! Pride AND savings!")
					else
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 300)
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🚗 Made it worse. Now needs real mechanic.")
					end
				end,
			},
		},
	},
	{
		id = "fin_emergency_fund",
		title = "Emergency Fund Decision",
		emoji = "🏦",
		text = "Financial advisors say you need an emergency fund.",
		question = "How do you approach savings?",
		minAge = 20, maxAge = 70,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "savings", "emergency_fund", "planning" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 100 then
				return false, "Not enough to start saving"
			end
			return true
		end,
		
		choices = {
		{ text = "Start automatic savings ($100)", effects = { Money = -100, Happiness = 4, Smarts = 3 }, setFlags = { has_emergency_fund = true }, feedText = "🏦 $100 to start. Future you will thank present you!", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100" end },
		{ text = "Save aggressively ($500)", effects = { Money = -500, Happiness = 2, Smarts = 4 }, setFlags = { has_emergency_fund = true }, feedText = "🏦 Big initial deposit. Financial responsibility!", eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500" end },
		{ text = "Can't afford to save right now", effects = { Happiness = -2 }, feedText = "🏦 Living paycheck to paycheck. Tough situation." },
		{ text = "Track spending instead", effects = { Smarts = 2 }, feedText = "🏦 Started budgeting. Small steps matter!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- INVESTMENTS & FINANCIAL DECISIONS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "fin_stock_market_decision",
		title = "Stock Market Opportunity",
		emoji = "📈",
		text = "Someone's giving you a stock tip!",
		question = "Do you invest?",
		minAge = 18, maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "investment",
		tags = { "stocks", "investment", "risk" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 100 then
				return false, "Need money to invest"
			end
			return true
		end,
		
		-- CRITICAL FIX #28: Stock investments should create actual portfolio assets
		choices = {
		{
			text = "Invest small amount ($100)",
			effects = { Money = -100 },
			feedText = "Buying the stock...",
			eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 to invest" end,
			onResolve = function(state)
					state.Assets = state.Assets or {}
					state.Assets.Investments = state.Assets.Investments or {}
					
					local roll = math.random()
					if roll < 0.20 then
						-- Stock tip was hot - immediate gains AND keep the investment
						local investment = {
							id = "stock_" .. os.time() .. "_" .. math.random(1000),
							name = "Hot Stock Pick",
							type = "stock",
							purchasePrice = 100,
							currentValue = 400,
							purchaseYear = state.Year
						}
						table.insert(state.Assets.Investments, investment)
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.has_investments = true
						state:AddFeed("📈 IT SOARED! +300%! Now worth $400! Holding for more gains!")
					elseif roll < 0.55 then
						-- Decent investment, holds value
						local investment = {
							id = "stock_" .. os.time() .. "_" .. math.random(1000),
							name = "Stock Investment",
							type = "stock",
							purchasePrice = 100,
							currentValue = 120 + math.floor(math.random() * 80),
							purchaseYear = state.Year
						}
						table.insert(state.Assets.Investments, investment)
						state:ModifyStat("Happiness", 4)
						state.Flags = state.Flags or {}
						state.Flags.has_investments = true
						state:AddFeed(string.format("📈 Good pick! Now worth $%d. Building wealth!", investment.currentValue))
					else
						-- Lost the investment
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📈 Stock crashed. Lost $100. That's the risk.")
					end
				end,
			},
		{
			text = "Go big ($500)",
			effects = { Money = -500 },
			feedText = "Big investment...",
			eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 to invest big" end,
			onResolve = function(state)
					state.Assets = state.Assets or {}
					state.Assets.Investments = state.Assets.Investments or {}
					
					local roll = math.random()
					if roll < 0.15 then
						-- Big winner
						local investment = {
							id = "stock_" .. os.time() .. "_" .. math.random(1000),
							name = "Blue Chip Stock",
							type = "stock",
							purchasePrice = 500,
							currentValue = 2000,
							purchaseYear = state.Year
						}
						table.insert(state.Assets.Investments, investment)
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.stock_winner = true
						state.Flags.has_investments = true
						state:AddFeed("📈 JACKPOT! 4x return! $500 became $2000!")
					elseif roll < 0.50 then
						-- Solid investment
						local value = 600 + math.floor(math.random() * 400)
						local investment = {
							id = "stock_" .. os.time() .. "_" .. math.random(1000),
							name = "Diversified Stock",
							type = "stock",
							purchasePrice = 500,
							currentValue = value,
							purchaseYear = state.Year
						}
						table.insert(state.Assets.Investments, investment)
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.has_investments = true
						state:AddFeed(string.format("📈 Solid investment! Now worth $%d!", value))
					else
						-- Lost it
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.stock_loss = true
						state:AddFeed("📈 BAD TIP! Stock tanked! $500 down the drain!")
					end
				end,
			},
			{ text = "Don't trust stock tips", effects = { Happiness = 2 }, feedText = "📈 Smart maybe. You keep your money." },
		},
	},
	{
		id = "fin_crypto_opportunity",
		title = "Cryptocurrency Hype",
		emoji = "₿",
		text = "Everyone's talking about cryptocurrency!",
		question = "Do you invest in crypto?",
		minAge = 18, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "investment",
		tags = { "crypto", "investment", "risk" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 50 then
				return false, "Need money to invest"
			end
			return true
		end,
		
		-- CRITICAL FIX #29: Crypto investments should create actual crypto assets
		choices = {
		{
			text = "Buy some Bitcoin/Ethereum ($200)",
			effects = { Money = -200 },
			feedText = "Buying crypto...",
			eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 to invest" end,
			onResolve = function(state)
					state.Assets = state.Assets or {}
					state.Assets.Crypto = state.Assets.Crypto or {}
					
					local roll = math.random()
					if roll < 0.10 then
						-- To the moon!
						local crypto = {
							id = "crypto_" .. os.time() .. "_" .. math.random(1000),
							name = "Bitcoin",
							type = "crypto",
							purchasePrice = 200,
							currentValue = 2000,
							purchaseYear = state.Year
						}
						table.insert(state.Assets.Crypto, crypto)
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.crypto_winner = true
						state.Flags.has_crypto = true
						state:AddFeed("₿ TO THE MOON! 10x gains! Now worth $2000!")
					elseif roll < 0.40 then
						-- Good gains
						local value = 300 + math.floor(math.random() * 400)
						local crypto = {
							id = "crypto_" .. os.time() .. "_" .. math.random(1000),
							name = "Ethereum",
							type = "crypto",
							purchasePrice = 200,
							currentValue = value,
							purchaseYear = state.Year
						}
						table.insert(state.Assets.Crypto, crypto)
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.has_crypto = true
						state:AddFeed(string.format("₿ Bull run! Crypto now worth $%d!", value))
					elseif roll < 0.65 then
						-- Holding, slight down
						local value = 100 + math.floor(math.random() * 100)
						local crypto = {
							id = "crypto_" .. os.time() .. "_" .. math.random(1000),
							name = "Bitcoin",
							type = "crypto",
							purchasePrice = 200,
							currentValue = value,
							purchaseYear = state.Year
						}
						table.insert(state.Assets.Crypto, crypto)
						state:ModifyStat("Happiness", -2)
						state.Flags = state.Flags or {}
						state.Flags.has_crypto = true
						state:AddFeed(string.format("₿ Down to $%d. HODL and hope.", value))
					else
						-- Lost it all
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.crypto_loss = true
						state:AddFeed("₿ Crypto winter. Lost it all. Exchange went bankrupt.")
					end
				end,
			},
		{
			text = "Buy altcoins/meme coins ($100)",
			effects = { Money = -100 },
			feedText = "YOLO into meme coins...",
			eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 to invest" end,
			onResolve = function(state)
					state.Assets = state.Assets or {}
					state.Assets.Crypto = state.Assets.Crypto or {}
					
					local roll = math.random()
					if roll < 0.05 then
						-- Meme coin miracle
						local crypto = {
							id = "crypto_" .. os.time() .. "_" .. math.random(1000),
							name = "DogeMoon Coin",
							type = "crypto",
							purchasePrice = 100,
							currentValue = 5000,
							purchaseYear = state.Year
						}
						table.insert(state.Assets.Crypto, crypto)
						state:ModifyStat("Happiness", 20)
						state.Flags = state.Flags or {}
						state.Flags.crypto_winner = true
						state.Flags.has_crypto = true
						state:AddFeed("₿ INSANE GAINS! Meme coin viral! $5000!")
					elseif roll < 0.25 then
						-- Lucky pump
						local value = 200 + math.floor(math.random() * 300)
						local crypto = {
							id = "crypto_" .. os.time() .. "_" .. math.random(1000),
							name = "AltCoin",
							type = "crypto",
							purchasePrice = 100,
							currentValue = value,
							purchaseYear = state.Year
						}
						table.insert(state.Assets.Crypto, crypto)
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.has_crypto = true
						state:AddFeed(string.format("₿ Lucky pump! Worth $%d now!", value))
					else
						-- Rug pulled
						state:ModifyStat("Happiness", -5)
						state:AddFeed("₿ Rug pull. Dev disappeared. $100 gone.")
					end
				end,
			},
			{ text = "Too risky for me", effects = { Happiness = 2 }, feedText = "₿ Watched from sidelines. Maybe wise?" },
		},
	},
	{
		id = "fin_retirement_planning",
		title = "Retirement Planning",
		emoji = "🏖️",
		text = "Time to think about retirement savings!",
		question = "How do you approach retirement?",
		minAge = 25, maxAge = 60,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "retirement", "401k", "planning" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 50 then
				return false, "Need money to save for retirement"
			end
			return true
		end,
		
		choices = {
		{ text = "Max out 401k contribution ($300)", effects = { Money = -300, Happiness = 3, Smarts = 4 }, setFlags = { retirement_saver = true }, feedText = "🏖️ Future you will live well! Compound interest magic!", eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300" end },
		{ text = "Open an IRA ($100)", effects = { Money = -100, Happiness = 2, Smarts = 3 }, setFlags = { has_ira = true }, feedText = "🏖️ Tax advantages! Smart money move!", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100" end },
		{ text = "Put it off for now", effects = { Happiness = 2 }, feedText = "🏖️ Future problem. Present you wants fun." },
		{ text = "Can't afford retirement savings", effects = { Happiness = -2 }, feedText = "🏖️ Barely making it now. Retirement seems impossible." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- DEBT & FINANCIAL STRUGGLES
	-- CRITICAL FIX: Completely rewritten! Game DETECTS your debt, doesn't let you choose it!
	-- Like BitLife: You get a letter/call about your ACTUAL debt and choose how to respond
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "fin_debt_situation",
		title = "💳 Debt Notice",
		emoji = "💳",
		text = "You've received a concerning financial notice...",
		question = "What do you do about it?",
		minAge = 18, maxAge = 70,
		baseChance = 0.40,
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "debt", "credit", "financial_trouble" },
		
		-- CRITICAL FIX: Only trigger if player has SOME debt or could plausibly have debt
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Trigger if: has student loans, has credit card debt, has medical debt, went to college, or has low money
			if flags.has_student_loans or flags.student_loans or flags.credit_card_debt or 
			   flags.medical_debt or flags.in_debt or flags.went_to_college or flags.attended_college or
			   (state.Money or 0) < 500 then
				return true
			end
			-- Also trigger randomly for adults who might have accumulated debt
			if (state.Age or 18) >= 22 and math.random() < 0.4 then
				return true
			end
			return false
		end,
		
		-- CRITICAL: onInit determines WHAT debt based on player's actual situation
		onInit = function(event, state)
			local flags = state.Flags or {}
			local debtType = "credit_card" -- Default
			local debtAmount = 0
			local debtText = ""
			
			-- Detect actual debt type from player state
			if flags.has_student_loans or flags.student_loans or flags.went_to_college or flags.attended_college then
				debtType = "student_loans"
				debtAmount = flags.student_loan_amount or math.random(15000, 80000)
				flags.student_loan_amount = debtAmount -- Store it
				debtText = string.format("📬 You received a student loan statement. Your balance is $%d and interest is accruing. Monthly payment due!", debtAmount)
			elseif flags.medical_debt or flags.had_surgery or flags.hospitalized then
				debtType = "medical"
				debtAmount = flags.medical_debt_amount or math.random(2000, 25000)
				flags.medical_debt_amount = debtAmount
				debtText = string.format("🏥 Medical bill arrived! You owe $%d from your hospital visit. Payment demanded.", debtAmount)
			elseif flags.credit_card_debt and type(flags.credit_card_debt) == "number" and flags.credit_card_debt > 0 then
				debtType = "credit_card"
				debtAmount = flags.credit_card_debt
				debtText = string.format("💳 Credit card statement: Balance $%d with %d%% APR. Minimum payment required!", debtAmount, math.random(18, 29))
			else
				-- Random new debt accumulation (realistic - people get into debt)
				local roll = math.random(1, 100)
				if roll <= 40 then
					debtType = "credit_card"
					debtAmount = math.random(1000, 5000)
					flags.credit_card_debt = (flags.credit_card_debt or 0) + debtAmount
					debtText = string.format("💳 Your credit card spending got out of control! New balance: $%d", flags.credit_card_debt)
				elseif roll <= 60 then
					debtType = "car_loan"
					debtAmount = math.random(5000, 20000)
					debtText = string.format("🚗 Car payment reminder: You owe $%d on your auto loan. Don't miss the payment!", debtAmount)
				else
					debtType = "misc"
					debtAmount = math.random(500, 3000)
					debtText = "📬 Unexpected bills have piled up. You're behind on payments and creditors are getting impatient."
				end
			end
			
			-- Store debt info in event
			event._debtType = debtType
			event._debtAmount = debtAmount
			event.text = debtText
			event.title = debtType == "student_loans" and "🎓 Student Loan Statement" or
			              debtType == "medical" and "🏥 Medical Bill" or
			              debtType == "credit_card" and "💳 Credit Card Bill" or
			              debtType == "car_loan" and "🚗 Auto Loan Notice" or "💳 Debt Notice"
			
			return event
		end,
		
		choices = {
			{
				text = "💰 Make a payment",
				effects = {},
				feedText = "Paying what you can...",
				onResolve = function(state, _, event)
					local debtType = event._debtType or "credit_card"
					local debtAmount = event._debtAmount or 1000
					state.Flags = state.Flags or {}
					
					-- Calculate payment (10-25% of debt or what player can afford)
					local idealPayment = math.floor(debtAmount * (math.random(10, 25) / 100))
					local actualPayment = math.min(idealPayment, state.Money or 0)
					
					if actualPayment >= 100 then
						state.Money = (state.Money or 0) - actualPayment
						
						-- Reduce stored debt
						if debtType == "student_loans" then
							state.Flags.student_loan_amount = math.max(0, (state.Flags.student_loan_amount or debtAmount) - actualPayment)
							if state.Flags.student_loan_amount <= 0 then
								state.Flags.has_student_loans = nil
								state.Flags.student_loans = nil
								if state.AddFeed then state:AddFeed(string.format("🎓 Paid $%d! STUDENT LOANS PAID OFF! You're free!", actualPayment)) end
							else
								if state.AddFeed then state:AddFeed(string.format("🎓 Paid $%d toward loans. Remaining: $%d. Progress!", actualPayment, state.Flags.student_loan_amount)) end
							end
						elseif debtType == "medical" then
							state.Flags.medical_debt_amount = math.max(0, (state.Flags.medical_debt_amount or debtAmount) - actualPayment)
							if state.Flags.medical_debt_amount <= 0 then
								state.Flags.medical_debt = nil
								if state.AddFeed then state:AddFeed(string.format("🏥 Paid $%d! Medical debt cleared!", actualPayment)) end
							else
								if state.AddFeed then state:AddFeed(string.format("🏥 Paid $%d. Still owe $%d. Getting there.", actualPayment, state.Flags.medical_debt_amount)) end
							end
						elseif debtType == "credit_card" then
							state.Flags.credit_card_debt = math.max(0, (state.Flags.credit_card_debt or debtAmount) - actualPayment)
							if state.Flags.credit_card_debt <= 0 then
								state.Flags.credit_card_debt = nil
								state.Flags.in_debt = nil
								if state.AddFeed then state:AddFeed(string.format("💳 Paid $%d! Credit card PAID OFF!", actualPayment)) end
							else
								if state.AddFeed then state:AddFeed(string.format("💳 Paid $%d. Balance: $%d. Interest still hurts.", actualPayment, state.Flags.credit_card_debt)) end
							end
						else
							if state.AddFeed then state:AddFeed(string.format("💰 Paid $%d toward the debt. Chipping away at it.", actualPayment)) end
						end
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -5) end
						if state.AddFeed then state:AddFeed("💰 Can't afford to make a meaningful payment right now. The debt grows...") end
						-- Debt grows from interest
						if debtType == "credit_card" then
							state.Flags.credit_card_debt = math.floor((state.Flags.credit_card_debt or debtAmount) * 1.02) -- 2% interest
						end
					end
				end,
			},
			{
				text = "📋 Set up payment plan",
				effects = { Smarts = 2 },
				feedText = "Negotiating terms...",
				onResolve = function(state, _, event)
					local debtType = event._debtType or "credit_card"
					local debtAmount = event._debtAmount or 1000
					state.Flags = state.Flags or {}
					state.Flags.has_payment_plan = true
					state.Flags.responsible_with_debt = true
					
					local monthlyPayment = math.floor(debtAmount / math.random(12, 36))
					if state.ModifyStat then state:ModifyStat("Happiness", 3) end
					if state.AddFeed then state:AddFeed(string.format("📋 Set up a payment plan: $%d/month. Manageable. Responsible choice!", monthlyPayment)) end
				end,
			},
			{
				text = "😰 Ignore it",
				effects = { Happiness = -3 },
				feedText = "Avoiding the problem...",
				onResolve = function(state, _, event)
					local debtType = event._debtType or "credit_card"
					state.Flags = state.Flags or {}
					state.Flags.ignoring_debt = true
					state.Flags.in_debt = true
					
					-- Debt grows when ignored
					if debtType == "student_loans" then
						state.Flags.student_loan_amount = math.floor((state.Flags.student_loan_amount or 20000) * 1.05)
					elseif debtType == "credit_card" then
						state.Flags.credit_card_debt = math.floor((state.Flags.credit_card_debt or 2000) * 1.05)
						state.Flags.bad_credit = true
					end
					
					if state.AddFeed then state:AddFeed("😰 Threw the notice in a drawer. The debt keeps growing with interest. This won't end well.") end
				end,
			},
			{
				text = "📞 Negotiate with creditors",
				effects = {},
				feedText = "Calling to negotiate...",
				onResolve = function(state, _, event)
					local roll = math.random(1, 100)
					state.Flags = state.Flags or {}
					
					if roll <= 35 then
						-- Great negotiation
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						state.Flags.negotiated_debt = true
						if state.AddFeed then state:AddFeed("📞 Amazing! Negotiated a 30% reduction! They'd rather get something than nothing!") end
						-- Reduce all debts by 30%
						if state.Flags.credit_card_debt then state.Flags.credit_card_debt = math.floor(state.Flags.credit_card_debt * 0.7) end
						if state.Flags.medical_debt_amount then state.Flags.medical_debt_amount = math.floor(state.Flags.medical_debt_amount * 0.7) end
					elseif roll <= 70 then
						-- Partial success
						if state.ModifyStat then state:ModifyStat("Happiness", 3) end
						if state.AddFeed then state:AddFeed("📞 Got them to lower the interest rate. Small win.") end
					else
						-- Failed
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("📞 They wouldn't budge. Payment still due. Worth a shot.") end
					end
				end,
			},
			-- ⚡ GOD MODE PREMIUM OPTION - Keep this!
			{
				text = "⚡ [God Mode] Clear all debt",
				effects = { Happiness = 30 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ GOD MODE! All debt wiped clean! Fresh financial start!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.credit_card_debt = nil
					state.Flags.student_loan_amount = nil
					state.Flags.medical_debt_amount = nil
					state.Flags.in_debt = nil
					state.Flags.bad_credit = nil
					state.Flags.has_student_loans = nil
					state.Flags.student_loans = nil
					state.Flags.medical_debt = nil
					state.Flags.ignoring_debt = nil
				end,
			},
		},
	},
	{
		id = "fin_collection_call",
		title = "Collections Call",
		emoji = "📞",
		text = "Debt collectors are calling!",
		question = "How do you handle it?",
		minAge = 18, maxAge = 80,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "collections", "debt", "stress" },
		
		requiresFlags = { in_debt = true },
		
		choices = {
			{
				text = "Negotiate a settlement",
				effects = {},
				feedText = "Negotiating...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.40 + (smarts / 200) then
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 200)
						state:ModifyStat("Happiness", 8)
						state.Flags.in_debt = nil
						state:AddFeed("📞 Settled for less! Debt cleared! Relief!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📞 They won't budge. Full amount or nothing.")
					end
				end,
			},
			{ text = "Set up payment plan", effects = { Happiness = 2 }, feedText = "📞 Structured payments. Manageable now." },
			{ text = "Ignore the calls", effects = { Happiness = -5 }, setFlags = { avoiding_collectors = true }, feedText = "📞 Not answering. This won't end well." },
		},
	},
	{
		id = "fin_bankruptcy_consideration",
		title = "Bankruptcy Consideration",
		emoji = "⚠️",
		text = "Financial situation is dire. Bankruptcy might be an option.",
		question = "What do you do?",
		minAge = 25, maxAge = 70,
		baseChance = 0.32,
		cooldown = 4,
		oneTime = true,
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "bankruptcy", "debt", "crisis" },
		
		eligibility = function(state)
			local money = state.Money or 0
			local inDebt = state.Flags and state.Flags.in_debt
			if money < 100 or inDebt then
				return true
			end
			return false, "Not in financial crisis"
		end,
		
		choices = {
		{
			text = "File for bankruptcy",
			effects = { Happiness = -10, Smarts = 2 },
			feedText = "Filing paperwork...",
			-- CRITICAL FIX #27: Bankruptcy should properly wipe ALL tracked debts
			onResolve = function(state)
				state.Money = 0
				state.Flags = state.Flags or {}
				
				-- CRITICAL: Clear all debt tracking flags
				state.Flags.in_debt = nil
				state.Flags.credit_card_debt = nil -- Wipe credit card debt
				state.Flags.medical_debt = nil -- Wipe medical debt
				state.Flags.has_student_loans = nil -- Student loans can be discharged in bankruptcy (rare but possible)
				state.Flags.mortgage_debt = nil -- Mortgage is discharged
				state.Flags.mortgage_trouble = nil
				state.Flags.avoiding_collectors = nil
				state.Flags.owed_back_taxes = nil
				state.Flags.bad_credit = true -- Credit is ruined
				state.Flags.declared_bankruptcy = true
				state.Flags.bankruptcy_year = state.Year -- Track when bankruptcy happened
				
				-- May lose some assets in bankruptcy
				if state.Assets then
					-- Keep one vehicle (exemption)
					if state.Assets.Vehicles and #state.Assets.Vehicles > 1 then
						local kept = state.Assets.Vehicles[1]
						state.Assets.Vehicles = { kept }
					end
					-- Lose investment accounts
					state.Assets.Investments = {}
					state.Assets.Crypto = {}
					-- May keep primary residence
				end
				
				-- Clear education debt if tracked separately  
				if state.EducationData and state.EducationData.Debt then
					state.EducationData.Debt = 0
				end
				
				state:AddFeed("⚠️ Chapter 7 Bankruptcy filed. ALL debts discharged. Credit ruined for 7-10 years. Fresh start, but lost most assets.")
			end,
		},
		{ text = "Try to power through", effects = { Happiness = -5, Health = -3 }, setFlags = { struggling_financially = true }, feedText = "⚠️ Won't give up. Extra jobs, cutting everything." },
		{ text = "Ask family for help", effects = { Happiness = 2 }, feedText = "⚠️ Swallowed pride. Family helped out. Grateful.",
			-- CRITICAL FIX: Can't ask family for help if ALREADY living with family!
			eligibility = function(state)
				local flags = state.Flags or {}
				if flags.lives_with_parents or flags.living_with_family or flags.boomerang_kid then
					return false, "You already live with your family!"
				end
				return true
			end,
			onResolve = function(state)
				local roll = math.random()
				if roll < 0.60 then
					state.Money = (state.Money or 0) + 500
					state:AddFeed("⚠️ Family came through! Loan to get back on feet!")
				else
					state:ModifyStat("Happiness", -4)
					state:AddFeed("⚠️ Family can't help. They're struggling too.")
				end
			end,
		},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- GAMBLING & RISK
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "fin_casino_trip",
		title = "Casino Opportunity",
		emoji = "🎰",
		text = "There's a casino trip opportunity!",
		question = "Do you gamble?",
		minAge = 21, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "gambling",
		tags = { "gambling", "casino", "risk" },
		blockedByFlags = { in_prison = true, incarcerated = true }, -- CRITICAL FIX #328: Can't go to casino from prison
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 50 then
				return false, "Need money to gamble"
			end
			return true
		end,
		
		-- CRITICAL: High variance gambling outcomes
		choices = {
			{
				-- CRITICAL FIX: Show price and add eligibility!
				text = "Play it safe, small bets ($50)",
				effects = { Money = -50 },
				feedText = "Playing conservatively...",
				eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 to gamble" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.20 then
						state.Money = (state.Money or 0) + 150
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🎰 Came out ahead! $150 profit!")
					elseif roll < 0.50 then
						state.Money = (state.Money or 0) + 20
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🎰 Broke about even. Free entertainment!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🎰 Lost $50. Could have been worse.")
					end
				end,
			},
			{
				-- CRITICAL FIX: Show price and add eligibility!
				text = "Go big or go home ($300)",
				effects = { Money = -300 },
				feedText = "High stakes...",
				eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 to bet big" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.10 then
						state.Money = (state.Money or 0) + 2000
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.casino_winner = true
						state:AddFeed("🎰 JACKPOT! Big win! $2000! Luck was on your side!")
					elseif roll < 0.30 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🎰 Nice win! $500 profit! Hot streak!")
					elseif roll < 0.50 then
						state:ModifyStat("Happiness", 1)
						state:AddFeed("🎰 About even. Thrilling night though.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.gambling_loss = true
						state:AddFeed("🎰 Lost it all. $300 gone. House always wins.")
					end
				end,
			},
			{ text = "Just watch others gamble", effects = { Happiness = 3 }, feedText = "🎰 Free drinks, people watching. Entertainment without risk." },
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Guaranteed jackpot!",
				effects = { Money = 10000, Happiness = 30 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ GOD MODE! You hit the MEGA JACKPOT! $10,000 WIN!",
				setFlags = { casino_winner = true, big_winner = true },
			},
		},
	},
	{
		id = "fin_sports_betting",
		title = "Sports Betting",
		emoji = "🏈",
		text = "Big game coming up. Want to make it interesting?",
		question = "Do you bet on the game?",
		minAge = 21, maxAge = 80,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "gambling",
		tags = { "gambling", "sports", "betting" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 20 then
				return false, "Need money to bet"
			end
			return true
		end,
		
		-- CRITICAL: Random sports betting outcome
		choices = {
			{
				text = "Bet on the favorite ($50)",
				effects = { Money = -50 },
				feedText = "Placing your bet...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state.Money = (state.Money or 0) + 75
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🏈 Winner! Favorites came through! $75!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🏈 UPSET! Favorites lost! $50 gone!")
					end
				end,
			},
			{
				text = "Bet on the underdog ($50)",
				effects = { Money = -50 },
				feedText = "Going with the underdog...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state.Money = (state.Money or 0) + 200
						state:ModifyStat("Happiness", 10)
						state:AddFeed("🏈 UPSET! Underdog won! Big payout! $200!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🏈 No upset. Underdog lost as expected.")
					end
				end,
			},
			{ text = "Just watch the game", effects = { Happiness = 3 }, feedText = "🏈 Enjoyed the game without financial stress." },
			-- ⚡ GOD MODE PREMIUM OPTION
			{
				text = "⚡ [God Mode] Know the winner ($500)",
				effects = { Money = 2500, Happiness = 20 },
				requiresGamepass = "GOD_MODE",
				gamepassEmoji = "⚡",
				feedText = "⚡ GOD MODE! You knew exactly who would win! $3000 payout!",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for big bet" end,
			},
		},
	},
	{
		id = "fin_get_rich_scheme",
		title = "Get Rich Quick Scheme",
		emoji = "🤑",
		text = "Someone's pitching a 'guaranteed' money-making opportunity!",
		question = "Do you invest?",
		minAge = 18, maxAge = 80,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "scam",
		tags = { "scam", "investment", "risk" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 100 then
				return false, "Not enough to be scammed"
			end
			return true
		end,
		
		-- CRITICAL: Mostly bad outcomes - it's a scam
		choices = {
			{
				-- CRITICAL FIX: Show price and add eligibility!
				text = "Invest your savings ($500)",
				effects = { Money = -500 },
				feedText = "Handing over your money...",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 to invest" end,
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local scamChance = 0.85 - (smarts / 300)
					
					if roll < scamChance then
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.got_scammed = true
						state:AddFeed("🤑 SCAM! They disappeared with your money! $500 gone!")
					else
						state.Money = (state.Money or 0) + 200
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🤑 Surprisingly legit? Made $200. Rare luck.")
					end
				end,
			},
			{ text = "Do research first", effects = { Smarts = 3, Happiness = 4 }, feedText = "🤑 Red flags everywhere. SCAM! Avoided disaster!" },
			{ text = "Politely decline", effects = { Happiness = 2 }, feedText = "🤑 If it's too good to be true... Wallet stays safe." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- TAX & GOVERNMENT
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "fin_tax_season",
		title = "Tax Season",
		emoji = "📋",
		text = "It's tax season! Time to file!",
		question = "How do you approach taxes?",
		minAge = 18, maxAge = 90,
		baseChance = 0.555,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "taxes", "IRS", "filing" },
		
		-- CRITICAL: Random tax outcome
		choices = {
			{
				text = "File yourself",
				effects = { Smarts = 2 },
				feedText = "Filling out forms...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.40 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 8)
						state:AddFeed("📋 REFUND! $500 coming back! Tax win!")
					elseif roll < 0.65 then
						state.Money = (state.Money or 0) + 100
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📋 Small refund. $100. Better than owing!")
					elseif roll < 0.85 then
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 200)
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📋 Owe $200. Taxes are painful.")
					else
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 500)
						state:ModifyStat("Happiness", -6)
						state:AddFeed("📋 Big tax bill! $500! Where did this come from?!")
					end
				end,
			},
			{ 
				-- CRITICAL FIX: Show price in text!
				text = "Hire an accountant ($100)", 
				effects = { Money = -100, Smarts = 1 }, 
				feedText = "📋 Professional handled it. Peace of mind worth $100.",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for accountant" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state.Money = (state.Money or 0) + 400
						state:ModifyStat("Happiness", 6)
						state:AddFeed("📋 Accountant found deductions! $400 refund!")
					else
						state:AddFeed("📋 Filed correctly. No surprises. That's the goal.")
					end
				end,
			},
			{ text = "File late/extension", effects = { Happiness = -2 }, feedText = "📋 Procrastinated. Extension filed. Get it together." },
		},
	},
	{
		id = "fin_audit",
		title = "IRS Audit",
		emoji = "😰",
		text = "You've been selected for an IRS audit!",
		question = "How do you handle the audit?",
		minAge = 22, maxAge = 80,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "audit", "taxes", "IRS" },
		
		-- CRITICAL: Random audit outcome
		choices = {
			{
				text = "Cooperate fully",
				effects = {},
				feedText = "Gathering documents...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("😰 Everything checked out! Clear! Relief!")
					elseif roll < 0.85 then
						-- CRITICAL FIX: Prevent negative money
						local owed = math.min(300, state.Money or 0)
						state.Money = math.max(0, (state.Money or 0) - 300)
						state:ModifyStat("Happiness", -3)
						if owed < 300 then
							state.Flags = state.Flags or {}
							state.Flags.irs_debt = true
							state:AddFeed("😰 Small discrepancy. Owe $300. Went into IRS debt!")
						else
							state:AddFeed("😰 Small discrepancy. Owe $300. Could be worse.")
						end
					else
						-- CRITICAL FIX: Prevent negative money - set debt flag if can't pay
						local owed = math.min(1000, state.Money or 0)
						state.Money = math.max(0, (state.Money or 0) - 1000)
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.owed_back_taxes = true
						if owed < 1000 then
							state.Flags.irs_debt = true
							state:AddFeed("😰 Major issues found. Owe $1000. Now in IRS debt!")
						else
							state:AddFeed("😰 Major issues found. Owe $1000 plus penalties.")
						end
					end
				end,
			},
			{ 
				text = "Hire tax attorney ($500)", 
				effects = { Happiness = 2 }, 
				feedText = "😰 Professional representation. Best defense.",
				minMoney = 500, -- CRITICAL FIX: Require money to hire attorney
				onResolve = function(state)
					state.Money = math.max(0, (state.Money or 0) - 500)
					local roll = math.random()
					if roll < 0.80 then
						state:AddFeed("😰 Attorney got you through clean! Worth every penny!")
					else
						state.Money = math.max(0, (state.Money or 0) - 200)
						state:AddFeed("😰 Still owed $200 but avoided bigger problems.")
					end
				end,
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- HOUSING-RELATED FINANCIAL EVENTS
	-- CRITICAL FIX: User complained events suggest buying house but don't link to assets
	-- "IT SAYS IM A COLLEGE STUDEND LIKE LIVING IN COLLEGE DORM ROOM STILL EVEN THO IM LIKE 40"
	-- "ENSURE THE CARD POP UPS ARE ACTUALLY LINKED TO THE ASSETS IN BUYING"
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "fin_housing_suggestion",
		title = "Housing Situation Check",
		emoji = "🏠",
		text = "Your current living situation needs attention...",
		question = "What's your plan?",
		minAge = 25, maxAge = 60,
		baseChance = 0.40,
		cooldown = 3,
		stage = "adult",
		ageBand = "adult",
		category = "finance",
		tags = { "housing", "financial", "life" },
		
		-- CRITICAL: Only trigger for people WITHOUT proper housing
		eligibility = function(state)
			local flags = state.Flags or {}
			local age = state.Age or 25
			
			-- Skip if already owns home
			if flags.homeowner or flags.has_house or flags.owns_property then return false end
			-- Skip if has apartment
			if flags.has_apartment and flags.renting then return false end
			-- Skip if explicitly living somewhere
			if flags.has_own_place or flags.living_independently then return false end
			-- Don't fire for young people still in college
			if flags.in_college or flags.college_student then return false end
			-- Skip if already homeless (different event path)
			if flags.homeless then return false end
			
			-- Only trigger if player has money to do something about it
			local money = state.Money or 0
			return age >= 25 and money > 1000
		end,
		
		-- CRITICAL: Dynamic text based on player state
		preProcess = function(state, eventDef)
			local money = state.Money or 0
			local flags = state.Flags or {}
			local hasJob = state.CurrentJob ~= nil
			
			local situation = "You're currently without stable housing."
			if flags.living_with_parents then
				situation = "You're still living with your parents. Time to consider your own place?"
			elseif flags.couch_surfing then
				situation = "Couch surfing isn't sustainable. Time to find something permanent."
			elseif flags.living_in_car then
				situation = "Living in your car is rough. Can you afford something better?"
			end
			
			local moneyStatus = ""
			if money >= 50000 then
				moneyStatus = " You have enough to buy a small home!"
			elseif money >= 5000 then
				moneyStatus = " You could afford a deposit on a rental."
			else
				moneyStatus = " You'll need to save more or find cheaper options."
			end
			
			eventDef.text = situation .. moneyStatus
			return true
		end,
		
		choices = {
			{
				text = "Get an apartment ($2,000 deposit)",
				effects = { Money = -2000 },
				eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Need $2,000 for deposit" end,
				feedText = "🏠 Found an apartment! $1000/month rent. Your own place at last!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.has_apartment = true
					state.Flags.renting = true
					state.Flags.has_own_place = true
					state.Flags.living_with_parents = nil
					state.HousingState = state.HousingState or {}
					state.HousingState.status = "renter"
					state.HousingState.type = "apartment"
					state.HousingState.rent = 1000
					state.HousingState.moveInYear = state.Year or 2025
				end,
			},
			{
				text = "Save for a house down payment",
				effects = { Happiness = 2, Smarts = 2 },
				setFlags = { saving_for_house = true },
				feedText = "🏠 Setting aside money each month. Building toward homeownership!",
			},
			{
				text = "Get a job first - need income!",
				effects = { Happiness = -2 },
				feedText = "🏠 Housing requires income. Time to focus on employment.",
				eligibility = function(state)
					if state.CurrentJob then
						return false, "You already have a job!"
					end
					return true
				end,
			},
			{
				text = "Stay where I am for now",
				effects = { Happiness = -3 },
				feedText = "🏠 Putting off housing decisions. It'll catch up eventually.",
			},
		},
	},

	{
		id = "fin_rent_due",
		title = "Rent is Due!",
		emoji = "💸",
		text = "It's the first of the month. Your landlord is expecting the rent payment.",
		question = "Your rent is due. What do you do?",
		minAge = 18, maxAge = 75,
		baseChance = 0.65,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = "adult",
		ageBand = "any",
		category = "finance",
		tags = { "housing", "rent", "bills" },
		
	-- CRITICAL FIX: Only for renters who DON'T live with family
	blockedByFlags = { lives_with_parents = true, living_with_family = true, boomerang_kid = true, homeless = true },
	eligibility = function(state)
		local flags = state.Flags or {}
		local housing = state.HousingState or {}
		-- Must be renting AND not living with family
		if flags.lives_with_parents or flags.living_with_family or flags.boomerang_kid then
			return false, "You don't pay rent - you live with family!"
		end
		return (flags.renting or housing.status == "renter") and not flags.homeless
	end,
		
		preProcess = function(state, eventDef)
			local rent = 1000
			if state.HousingState and state.HousingState.rent then
				rent = state.HousingState.rent
			end
			eventDef.question = string.format("Your rent of $%d is due. What do you do?", rent)
			return true
		end,
		
		getDynamicChoices = function(state)
			local rent = 1000
			if state.HousingState and state.HousingState.rent then
				rent = state.HousingState.rent
			end
			return {
				{
					text = string.format("Pay rent in full ($%d)", rent),
					effects = { Happiness = 2, Money = -rent },
					eligibility = function(s) return (s.Money or 0) >= rent, string.format("💸 Need $%d for rent", rent) end,
					feedText = string.format("💸 Rent paid! -$%d. Roof over your head secured.", rent),
					onResolve = function(s)
						s.HousingState = s.HousingState or {}
						s.HousingState.missedRentYears = 0
					end,
				},
				{
					text = "Ask for an extension",
					effects = { Happiness = -3 },
					feedText = "Requesting more time...",
					onResolve = function(s)
						if math.random() < 0.5 then
							if s.AddFeed then s:AddFeed("💸 Landlord gave you until end of month.") end
						else
							s.HousingState = s.HousingState or {}
							s.HousingState.missedRentYears = (s.HousingState.missedRentYears or 0) + 1
							if s.AddFeed then s:AddFeed("💸 No extension. Late fees added.") end
						end
					end,
				},
				{
					text = "Skip this month",
					effects = { Happiness = -5 },
					feedText = "💸 Skipped rent. This will catch up to you.",
					onResolve = function(s)
						s.HousingState = s.HousingState or {}
						s.HousingState.missedRentYears = (s.HousingState.missedRentYears or 0) + 1
						s.Flags = s.Flags or {}
						s.Flags.rent_delinquent = true
						if s.HousingState.missedRentYears >= 2 then
							s.Flags.eviction_warning = true
							if s.AddFeed then s:AddFeed("⚠️ EVICTION WARNING!") end
						end
					end,
				},
			}
		end,
		choices = {
			{
				text = "Ask for an extension",
				effects = { Happiness = -3 },
				feedText = "Requesting more time...",
				onResolve = function(state)
					if math.random() < 0.5 then
						if state.AddFeed then
							state:AddFeed("💸 Landlord gave you until end of month. Don't be late again!")
						end
					else
						state.HousingState = state.HousingState or {}
						state.HousingState.missedRentYears = (state.HousingState.missedRentYears or 0) + 1
						if state.AddFeed then
							state:AddFeed("💸 No extension. Late fees added. Eviction warning issued.")
						end
					end
				end,
			},
			{
				text = "Skip this month",
				effects = { Happiness = -5, Money = 0 },
				feedText = "Keeping your money...",
				onResolve = function(state)
					state.HousingState = state.HousingState or {}
					state.HousingState.missedRentYears = (state.HousingState.missedRentYears or 0) + 1
					state.Flags = state.Flags or {}
					state.Flags.rent_delinquent = true
					if state.HousingState.missedRentYears >= 2 then
						state.Flags.eviction_warning = true
						if state.AddFeed then
							state:AddFeed("⚠️ EVICTION WARNING! Miss rent again and you're out!")
						end
					else
						if state.AddFeed then
							state:AddFeed("💸 Skipped rent. Landlord is furious. This will catch up to you.")
						end
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #934: INVESTMENT EVENTS - Make money work for you!
	-- Stock market, crypto, real estate investments
	-- High risk/reward events for engaged players
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "fin_stock_market_tip",
		title = "Stock Market Tip!",
		emoji = "📈",
		text = "A friend tells you about a 'hot' stock that's about to take off!",
		textVariants = {
			"Your coworker says they made a killing on this stock!",
			"Social media is buzzing about this investment opportunity!",
			"A financial advisor has a 'can't miss' tip for you!",
		},
		question = "Do you invest?",
		minAge = 21, maxAge = 75,
		baseChance = 0.30,
		cooldown = 5,
		stage = STAGE,
		category = "finance",
		tags = { "stocks", "investment", "risk", "money" },
		blockedByFlags = { in_prison = true, incarcerated = true },
		eligibility = function(state)
			return (state.Money or 0) >= 500, "Need at least $500 to invest"
		end,
		
		choices = {
			{
				text = "Go big! Invest $5,000!",
				effects = { Money = -5000 },
				feedText = "All in on this stock...",
				eligibility = function(state) return (state.Money or 0) >= 5000, "Need $5000" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.20 then
						local winnings = math.random(10000, 25000)
						state.Money = (state.Money or 0) + winnings
						state:ModifyStat("Happiness", 30)
						state.Flags = state.Flags or {}
						state.Flags.investor = true
						state.Flags.stock_winner = true
						state:AddFeed(string.format("📈 JACKPOT!!! The stock EXPLODED! Made $%d profit!", winnings - 5000))
					elseif roll < 0.45 then
						local winnings = math.random(6000, 9000)
						state.Money = (state.Money or 0) + winnings
						state:ModifyStat("Happiness", 15)
						state:AddFeed(string.format("📈 Nice! Stock went up! Made $%d profit!", winnings - 5000))
					elseif roll < 0.70 then
						local result = math.random(4000, 5500)
						state.Money = (state.Money or 0) + result
						state:ModifyStat("Happiness", result > 5000 and 3 or -3)
						state:AddFeed(string.format("📈 Stock was flat. Got back $%d.", result))
					else
						local returned = math.random(1000, 3500)
						state.Money = (state.Money or 0) + returned
						state:ModifyStat("Happiness", -15)
						state:AddFeed(string.format("📈 Stock CRASHED! Only got back $%d! Lost $%d!", returned, 5000 - returned))
					end
				end,
			},
			{
				text = "Invest a safe amount ($500)",
				effects = { Money = -500 },
				feedText = "Testing the waters...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						local winnings = math.random(800, 1500)
						state.Money = (state.Money or 0) + winnings
						state:ModifyStat("Happiness", 12)
						state:AddFeed(string.format("📈 Small bet paid off! Made $%d profit!", winnings - 500))
					elseif roll < 0.55 then
						state.Money = (state.Money or 0) + 550
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📈 Small gain. $50 profit. Baby steps!")
					else
						local returned = math.random(200, 450)
						state.Money = (state.Money or 0) + returned
						state:ModifyStat("Happiness", -5)
						state:AddFeed(string.format("📈 Lost $%d. At least it wasn't your life savings.", 500 - returned))
					end
				end,
			},
			{
				text = "Pass - too risky for me",
				effects = { Happiness = 2 },
				feedText = "📈 Played it safe. Your money stays in your pocket.",
			},
		},
	},
	
	{
		-- CRITICAL FIX: Renamed from "fin_crypto_opportunity" to avoid duplicate ID
		id = "fin_crypto_craze_alt",
		title = "Crypto Craze!",
		emoji = "🪙",
		text = "Everyone's talking about this new cryptocurrency!",
		question = "Jump on the crypto train?",
		minAge = 18, maxAge = 60,
		baseChance = 0.25,
		cooldown = 6,
		stage = STAGE,
		category = "finance",
		tags = { "crypto", "investment", "risk", "money" },
		blockedByFlags = { in_prison = true, incarcerated = true },
		eligibility = function(state)
			return (state.Money or 0) >= 200, "Need money to invest"
		end,
		
		choices = {
			{
				text = "YOLO! Invest $2,000!",
				effects = { Money = -2000 },
				feedText = "To the moon...",
				eligibility = function(state) return (state.Money or 0) >= 2000, "Need $2000" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.15 then
						local winnings = math.random(15000, 30000)
						state.Money = (state.Money or 0) + winnings
						state:ModifyStat("Happiness", 35)
						state.Flags = state.Flags or {}
						state.Flags.crypto_rich = true
						state:AddFeed(string.format("🪙 TO THE MOON!!! Made $%d!!!", winnings))
					elseif roll < 0.35 then
						local winnings = math.random(3000, 8000)
						state.Money = (state.Money or 0) + winnings
						state:ModifyStat("Happiness", 15)
						state:AddFeed(string.format("🪙 Nice gains! Made $%d!", winnings - 2000))
					elseif roll < 0.55 then
						state.Money = (state.Money or 0) + 2000
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🪙 Sold at entry point. No loss!")
					else
						local returned = math.random(0, 500)
						state.Money = (state.Money or 0) + returned
						state:ModifyStat("Happiness", -20)
						state.Flags = state.Flags or {}
						state.Flags.crypto_burned = true
						if returned == 0 then
							state:AddFeed("🪙 RUG PULL!!! Lost EVERYTHING!")
						else
							state:AddFeed(string.format("🪙 CRASHED! Only saved $%d!", returned))
						end
					end
				end,
			},
			{
				text = "Small position ($200)",
				effects = { Money = -200 },
				feedText = "Testing crypto...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						local winnings = math.random(500, 1000)
						state.Money = (state.Money or 0) + winnings
						state:ModifyStat("Happiness", 10)
						state:AddFeed(string.format("🪙 Crypto win! $%d profit!", winnings - 200))
					elseif roll < 0.60 then
						state.Money = (state.Money or 0) + 200
						state:AddFeed("🪙 Crypto was sideways. No gain, no loss.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🪙 Coin crashed. Lost $200.")
					end
				end,
			},
			{
				text = "No thanks - crypto is too volatile",
				effects = {},
				feedText = "🪙 You avoided the crypto casino.",
			},
		},
	},
	
	{
		id = "fin_found_money_big",
		title = "Lucky Discovery!",
		emoji = "💎",
		text = "You stumbled upon something valuable!",
		question = "What did you find?",
		minAge = 18, maxAge = 80,
		baseChance = 0.15,
		cooldown = 8,
		stage = STAGE,
		category = "finance",
		tags = { "luck", "money", "treasure" },
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		choices = {
			{
				text = "Investigate the find",
				effects = {},
				feedText = "Looking closer...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.10 then
						local value = math.random(5000, 20000)
						state.Money = (state.Money or 0) + value
						state:ModifyStat("Happiness", 30)
						state.Flags = state.Flags or {}
						state.Flags.treasure_finder = true
						state:AddFeed(string.format("💎 INCREDIBLE! It's a rare antique worth $%d!", value))
					elseif roll < 0.35 then
						local value = math.random(500, 2000)
						state.Money = (state.Money or 0) + value
						state:ModifyStat("Happiness", 15)
						state:AddFeed(string.format("💎 Nice find! Worth $%d!", value))
					elseif roll < 0.60 then
						local value = math.random(50, 300)
						state.Money = (state.Money or 0) + value
						state:ModifyStat("Happiness", 5)
						state:AddFeed(string.format("💎 Worth $%d. Small surprise!", value))
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("💎 Just junk. Oh well.")
					end
				end,
			},
			{
				text = "Leave it - probably nothing",
				effects = {},
				feedText = "💎 You passed it by. Who knows what it was?",
			},
		},
	},
}

return FinancialEvents
