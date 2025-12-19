--[[
    Financial Events
    Comprehensive financial situations across all life stages
    All events use randomized outcomes - NO god mode
]]

local FinancialEvents = {}

local STAGE = "random"

-- CRITICAL FIX: Helper for entertainment career check
local function isEntertainmentCareer(state)
	if not state.CurrentJob then return false end
	local jobId = (state.CurrentJob.id or ""):lower()
	local jobCat = (state.CurrentJob.category or ""):lower()
	
	-- CRITICAL FIX: Check for isFameCareer flag on job FIRST
	if state.CurrentJob.isFameCareer then
		return true
	end
	
	if jobCat == "entertainment" or jobCat == "celebrity" or jobCat == "fame" or
	   jobCat == "sports" or jobCat == "music" or jobCat == "acting" or
	   jobCat == "racing" or jobCat == "gaming" then
		return true
	end
	local keywords = {"influencer", "streamer", "rapper", "athlete", "actor", "musician", "youtuber", "content_creator", "model"}
	for _, k in ipairs(keywords) do
		if jobId:find(k) then return true end
	end
	return false
end

local function hasFormalWorkplaceJob(state)
	if not state.CurrentJob then return false end
	if isEntertainmentCareer(state) then return false end
	return true
end

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
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "money", "income", "windfall" },
		
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
		cooldown = 2,
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
						state.Money = (state.Money or 0) - 50
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
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "career",
		tags = { "bonus", "work", "income" },
		requiresJob = true,
		blockedByFlags = { in_prison = true, incarcerated = true }, -- CRITICAL FIX #327: Can't get work bonus from prison
		-- CRITICAL FIX: Entertainment careers get royalties/deals, not work bonuses
		eligibility = hasFormalWorkplaceJob,
		
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
		cooldown = 2,
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
					if roll < 0.40 then
						state.Money = (state.Money or 0) - 800
						state:ModifyStat("Happiness", -6)
						state:AddFeed("💸 Need new fridge. $800. Ouch.")
					elseif roll < 0.70 then
						state.Money = (state.Money or 0) - 400
						state:ModifyStat("Happiness", -4)
						state:AddFeed("💸 Washing machine died. $400 repair.")
					else
						state.Money = (state.Money or 0) - 150
						state:ModifyStat("Happiness", -2)
						state:AddFeed("💸 Minor appliance issue. $150. Manageable.")
					end
				end,
			},
			{ text = "Medical bill", effects = { Happiness = -5, Health = 2 }, feedText = "💸 Healthcare is expensive. At least you're treated." },
			{ text = "Home repair needed", effects = { Happiness = -4 }, feedText = "💸 Roof leak/plumbing/HVAC. Homeowner problems.",
				onResolve = function(state)
					local roll = math.random()
					state.Money = (state.Money or 0) - math.floor(200 + (roll * 1000))
				end,
			},
			{ text = "Pet emergency", effects = { Happiness = -6, Money = -500 }, setFlags = { pet_medical_bills = true }, feedText = "💸 Vet bills are brutal but you love your pet." },
		},
	},
	{
		id = "fin_car_expense",
		title = "Vehicle Expense",
		emoji = "🚗",
		text = "Your vehicle needs attention!",
		question = "What's wrong with the car?",
		minAge = 18, maxAge = 90,
		baseChance = 0.55,
		cooldown = 3,
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
					if roll < 0.25 then
						state.Money = (state.Money or 0) - 1500
						state:ModifyStat("Happiness", -8)
						state:AddFeed("🚗 Major repair. Transmission/engine. $1500. Devastating.")
					elseif roll < 0.50 then
						state.Money = (state.Money or 0) - 600
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🚗 Moderate repair. Brakes/suspension. $600.")
					elseif roll < 0.75 then
						state.Money = (state.Money or 0) - 200
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🚗 Minor fix. $200. Relief!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🚗 False alarm! Nothing serious wrong!")
					end
				end,
			},
			{ text = "DIY repair attempt", effects = { Money = -50, Smarts = 2 }, feedText = "🚗 YouTube mechanic mode. Saved some money, maybe.",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🚗 Fixed it yourself! Pride AND savings!")
					else
						state.Money = (state.Money or 0) - 300
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
		cooldown = 2,
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
			{ text = "Start automatic savings", effects = { Money = -100, Happiness = 4, Smarts = 3 }, setFlags = { has_emergency_fund = true }, feedText = "🏦 $100 to start. Future you will thank present you!" },
			{ text = "Save aggressively", effects = { Money = -500, Happiness = 2, Smarts = 4 }, setFlags = { has_emergency_fund = true }, feedText = "🏦 Big initial deposit. Financial responsibility!" },
			{ text = "Can't afford to save right now", effects = { Happiness = -2 }, feedText = "🏦 Living paycheck to paycheck. Tough situation." },
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
		cooldown = 2,
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
		cooldown = 2,
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
				text = "Buy some Bitcoin/Ethereum",
				effects = { Money = -200 },
				feedText = "Buying crypto...",
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
				text = "Buy altcoins/meme coins",
				effects = { Money = -100 },
				feedText = "YOLO into meme coins...",
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
		cooldown = 2,
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
			{ text = "Max out 401k contribution", effects = { Money = -300, Happiness = 3, Smarts = 4 }, setFlags = { retirement_saver = true }, feedText = "🏖️ Future you will live well! Compound interest magic!" },
			{ text = "Open an IRA", effects = { Money = -100, Happiness = 2, Smarts = 3 }, setFlags = { has_ira = true }, feedText = "🏖️ Tax advantages! Smart money move!" },
			{ text = "Put it off for now", effects = { Happiness = 2 }, feedText = "🏖️ Future problem. Present you wants fun." },
			{ text = "Can't afford retirement savings", effects = { Happiness = -2 }, feedText = "🏖️ Barely making it now. Retirement seems impossible." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- DEBT & FINANCIAL STRUGGLES
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "fin_debt_situation",
		title = "Debt Problems",
		emoji = "💳",
		text = "You're dealing with debt issues!",
		question = "What's the debt situation?",
		minAge = 18, maxAge = 70,
		baseChance = 0.45,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "finance",
		tags = { "debt", "credit", "financial_trouble" },
		
		choices = {
		{
			text = "Credit card debt piling up",
			effects = {},
			feedText = "Looking at the statements...",
			-- CRITICAL FIX #26: Properly track credit card debt as a growing balance
			onResolve = function(state)
				local roll = math.random()
				state.Flags = state.Flags or {}
				
				-- Initialize or increase credit card debt
				local currentDebt = state.Flags.credit_card_debt or 0
				
				if roll < 0.30 then
					-- Debt growing out of control
					local newDebt = 2000 + math.floor(math.random() * 3000) -- $2000-$5000 new debt
					state.Flags.credit_card_debt = currentDebt + newDebt
					state.Flags.in_debt = true
					state.Flags.bad_credit = true
					state:ModifyStat("Happiness", -8)
					state:AddFeed(string.format("💳 Credit cards maxed out! Total debt: $%d. Interest is crushing.", state.Flags.credit_card_debt))
				elseif roll < 0.60 then
					-- Some debt but manageable
					local newDebt = 500 + math.floor(math.random() * 1500) -- $500-$2000 new debt
					state.Flags.credit_card_debt = currentDebt + newDebt
					state.Flags.in_debt = true
					state:ModifyStat("Happiness", -4)
					state:AddFeed(string.format("💳 Racked up $%d in credit card debt. Need to pay this down.", newDebt))
				else
					-- Managed to pay some down
					local payment = math.min(currentDebt, 200 + math.floor(math.random() * 300))
					if payment > 0 then
						state.Flags.credit_card_debt = math.max(0, currentDebt - payment)
						state.Money = (state.Money or 0) - payment
						state:ModifyStat("Happiness", 3)
						state:AddFeed(string.format("💳 Paid $%d toward credit card. Progress!", payment))
						if state.Flags.credit_card_debt <= 0 then
							state.Flags.credit_card_debt = nil
							state.Flags.in_debt = nil
							state:AddFeed("💳 Credit card paid off! Debt free!")
						end
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("💳 No debt to pay down but tight budget.")
					end
				end
			end,
		},
			{ text = "Student loans calling", effects = { Happiness = -4, Money = -200 }, setFlags = { has_student_loans = true }, feedText = "💳 Monthly payment due. Education costs never end." },
			{ text = "Medical debt", effects = { Happiness = -5, Money = -300 }, setFlags = { medical_debt = true }, feedText = "💳 Got sick AND went broke. American healthcare." },
			{ text = "Consolidate and strategize", effects = { Happiness = 3, Smarts = 3, Money = -100 }, feedText = "💳 Working with financial advisor. Plan in place." },
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
		cooldown = 2,
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
						state.Money = (state.Money or 0) - 200
						state:ModifyStat("Happiness", 8)
						state.Flags.in_debt = nil
						state:AddFeed("📞 Settled for less! Debt cleared! Relief!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📞 They won't budge. Full amount or nothing.")
					end
				end,
			},
			{ text = "Set up payment plan", effects = { Money = -100, Happiness = 2 }, feedText = "📞 Structured payments. Manageable now." },
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
		cooldown = 2,
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
				text = "Play it safe, small bets",
				effects = { Money = -50 },
				feedText = "Playing conservatively...",
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
				text = "Go big or go home",
				effects = { Money = -300 },
				feedText = "High stakes...",
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
		cooldown = 2,
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
				text = "Invest your savings",
				effects = { Money = -500 },
				feedText = "Handing over your money...",
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
		cooldown = 2,
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
						state.Money = (state.Money or 0) - 200
						state:ModifyStat("Happiness", -3)
						state:AddFeed("📋 Owe $200. Taxes are painful.")
					else
						state.Money = (state.Money or 0) - 500
						state:ModifyStat("Happiness", -6)
						state:AddFeed("📋 Big tax bill! $500! Where did this come from?!")
					end
				end,
			},
			{ text = "Hire an accountant", effects = { Money = -100, Smarts = 1 }, feedText = "📋 Professional handled it. Peace of mind worth $100.",
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
			{ text = "File late/extension", effects = { Happiness = -2, Money = -25 }, feedText = "📋 Procrastinated. Extension fees. Get it together." },
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
						state.Money = (state.Money or 0) - 300
						state:ModifyStat("Happiness", -3)
						state:AddFeed("😰 Small discrepancy. Owe $300. Could be worse.")
					else
						state.Money = (state.Money or 0) - 1000
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.owed_back_taxes = true
						state:AddFeed("😰 Major issues found. Owe $1000 plus penalties.")
					end
				end,
			},
			{ text = "Hire tax attorney", effects = { Money = -500, Happiness = 2 }, feedText = "😰 Professional representation. Best defense.",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.80 then
						state:AddFeed("😰 Attorney got you through clean! Worth every penny!")
					else
						state.Money = (state.Money or 0) - 200
						state:AddFeed("😰 Still owed $200 but avoided bigger problems.")
					end
				end,
			},
		},
	},
}

return FinancialEvents
