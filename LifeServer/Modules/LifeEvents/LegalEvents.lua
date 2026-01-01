--[[
    Legal & Justice Events
    Events related to legal situations, justice system, and civil matters
    All events use randomized outcomes - NO god mode
]]

local LegalEvents = {}

local STAGE = "random"

LegalEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- CIVIL LEGAL MATTERS
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "legal_car_accident",
		title = "Car Accident Aftermath",
		emoji = "🚗",
		text = "There's been a car accident and legal issues to sort out.",
		question = "How do you handle the legal aspects?",
		minAge = 18, maxAge = 90,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "legal",
		tags = { "accident", "legal", "insurance" },
		
		eligibility = function(state)
			local hasCar = state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0
			if not hasCar then
				return false, "Need a vehicle for car accident events"
			end
			return true
		end,
		
		-- CRITICAL: Random accident legal outcome
		choices = {
			{
				text = "Deal with insurance claims",
				effects = {},
				feedText = "Navigating insurance...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🚗 Insurance covered everything! Smooth claim!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -3)
						-- CRITICAL FIX #538: Prevent money going negative
						state.Money = math.max(0, (state.Money or 0) - 300)
						state:AddFeed("🚗 Partial coverage. Deductible plus extra costs.")
					else
						state:ModifyStat("Happiness", -8)
						-- CRITICAL FIX #539: Prevent money going negative
						state.Money = math.max(0, (state.Money or 0) - 1000)
						state.Flags = state.Flags or {}
						state.Flags.insurance_dispute = true
						state:AddFeed("🚗 Insurance denied claim! Disputing. Lawyer maybe needed.")
					end
				end,
			},
			{ text = "Hire accident lawyer ($500)", effects = { Money = -500 }, feedText = "Getting legal representation...",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for lawyer" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state.Money = (state.Money or 0) + 2000
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🚗 Lawyer won the case! Settlement received!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🚗 Case didn't pan out. At least tried everything.")
					end
				end,
			},
		},
	},
	{
		id = "legal_contract_dispute",
		title = "Contract Dispute",
		emoji = "📜",
		text = "You're in a contract dispute!",
		question = "How do you handle the dispute?",
		minAge = 18, maxAge = 80,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "legal",
		tags = { "contract", "dispute", "business" },
		
		-- CRITICAL: Random contract dispute outcome
		choices = {
			{
				text = "Negotiate directly",
				effects = {},
				feedText = "Trying to work it out...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.30 + (smarts / 200)
					
					if roll < successChance then
						state:ModifyStat("Happiness", 6)
						state.Money = (state.Money or 0) + 200
						state:AddFeed("📜 Negotiated a fair resolution! Win-win!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 1)
						state:AddFeed("📜 Settled with compromise. Not perfect but resolved.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📜 They won't budge. May need legal action.")
					end
				end,
			},
			{ text = "Hire a lawyer ($800)", effects = { Money = -800 }, feedText = "Legal action...",
				eligibility = function(state) return (state.Money or 0) >= 800, "💸 Need $800 for lawyer" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state.Money = (state.Money or 0) + 1500
						state:ModifyStat("Happiness", 8)
						state:AddFeed("📜 Won the dispute! Legal fees were worth it!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("📜 Lost or settled for less than expected. Expensive lesson.")
					end
				end,
			},
			{ text = "Let it go", effects = { Happiness = -2, Smarts = 2 }, feedText = "📜 Not worth the fight. Taking the L. Moving on." },
		},
	},
	{
		id = "legal_small_claims",
		title = "Small Claims Court",
		emoji = "⚖️",
		text = "Taking someone to small claims court!",
		question = "How does your case go?",
		minAge = 18, maxAge = 80,
		baseChance = 0.32,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "legal",
		tags = { "court", "claims", "legal" },
		
		-- CRITICAL: Random small claims outcome
		choices = {
			{
				text = "Present your case ($50 filing fee)",
				effects = { Money = -50 },
				feedText = "In front of the judge...",
				eligibility = function(state) return (state.Money or 0) >= 50, "💸 Can't afford filing fee ($50 needed)" end,
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local winChance = 0.35 + (smarts / 200)
					
					if roll < winChance then
						state.Money = (state.Money or 0) + 800
						state:ModifyStat("Happiness", 10)
						state:AddFeed("⚖️ WON! Judge ruled in your favor! Justice!")
					elseif roll < (winChance * 1.5) then
						state.Money = (state.Money or 0) + 200
						state:ModifyStat("Happiness", 4)
						state:AddFeed("⚖️ Partial win. Got some money back. Okay outcome.")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("⚖️ Lost the case. Judge didn't see it your way. Frustrating.")
					end
				end,
			},
			{
				text = "Drop the case",
				effects = { Happiness = -3 },
				feedText = "⚖️ Not worth the hassle. Letting it go.",
			},
		},
	},
	{
		id = "legal_divorce",
		title = "Divorce Proceedings",
		emoji = "💔",
		text = "Going through divorce proceedings.",
		question = "How do the legal matters go?",
		minAge = 20, maxAge = 80,
		baseChance = 0.1,
		cooldown = 4,
		stage = STAGE,
		ageBand = "adult",
		category = "legal",
		tags = { "divorce", "legal", "marriage" },
		requiresFlags = { married = true },
		
		-- CRITICAL: Random divorce outcome
		choices = {
			{
				text = "Amicable divorce ($500)",
				effects = { Money = -500 },
				feedText = "Working through separation...",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Can't afford divorce fees ($500 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.married = nil
						state.Flags.has_spouse = nil
						state.Flags.has_partner = nil
						state.Flags.divorced = true
						-- MINOR FIX #DIVORCE-1: Also clear the spouse relationship!
						if state.Relationships then
							if state.Relationships.spouse then
								state.Relationships.ex_spouse = state.Relationships.spouse
								state.Relationships.spouse = nil
							elseif state.Relationships.partner then
								state.Relationships.ex_spouse = state.Relationships.partner
								state.Relationships.partner = nil
							end
						end
						state:AddFeed("💔 Painful but civil. Fair split. Moving forward.")
					else
						state:ModifyStat("Happiness", -10)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 500)
						state.Flags = state.Flags or {}
						state.Flags.married = nil
						state.Flags.has_spouse = nil
						state.Flags.has_partner = nil
						state.Flags.divorced = true
						-- MINOR FIX #DIVORCE-1: Also clear the spouse relationship!
						if state.Relationships then
							if state.Relationships.spouse then
								state.Relationships.ex_spouse = state.Relationships.spouse
								state.Relationships.spouse = nil
							elseif state.Relationships.partner then
								state.Relationships.ex_spouse = state.Relationships.partner
								state.Relationships.partner = nil
							end
						end
						state:AddFeed("💔 Got contentious. More lawyers. More money gone.")
					end
				end,
			},
			{
				text = "Contested divorce ($2,000 legal fees)",
				effects = { Money = -2000 },
				feedText = "Fighting in court...",
				-- BUG FIX #15: Add eligibility check for legal fees
				eligibility = function(state) return (state.Money or 0) >= 2000, "💸 Can't afford legal fees ($2,000 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					-- MINOR FIX #DIVORCE-2: Clear spouse relationship in contested divorce
					local function clearSpouse()
						if state.Relationships then
							if state.Relationships.spouse then
								state.Relationships.ex_spouse = state.Relationships.spouse
								state.Relationships.spouse = nil
							elseif state.Relationships.partner then
								state.Relationships.ex_spouse = state.Relationships.partner
								state.Relationships.partner = nil
							end
						end
					end
					
					if roll < 0.40 then
						state:ModifyStat("Happiness", -8)
						state.Money = (state.Money or 0) + 3000
						state.Flags = state.Flags or {}
						state.Flags.married = nil
						state.Flags.has_spouse = nil
						state.Flags.has_partner = nil
						state.Flags.divorced = true
						clearSpouse()
						state:AddFeed("💔 Won in court. Better settlement. Still painful.")
					else
						state:ModifyStat("Happiness", -15)
						state.Flags = state.Flags or {}
						state.Flags.married = nil
						state.Flags.has_spouse = nil
						state.Flags.has_partner = nil
						state.Flags.messy_divorce = true
						state.Flags.divorced = true -- MINOR FIX: Also set divorced flag!
						clearSpouse()
						state:AddFeed("💔 Brutal court battle. Lost a lot. Traumatic process.")
					end
				end,
			},
			{
				text = "Try to work things out",
				effects = { Happiness = 3 },
				feedText = "💔 Decided to give it another chance. Marriage counseling maybe.",
			},
		},
	},
	{
		id = "legal_landlord_tenant",
		title = "Landlord/Tenant Issue",
		emoji = "🏠",
		text = "There's a legal issue with your rental situation!",
		question = "What's the dispute about?",
		minAge = 18, maxAge = 80,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "legal",
		tags = { "rental", "housing", "legal" },
		-- CRITICAL FIX: Rental issues require actually renting!
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Must be renting (not a homeowner or homeless)
			if flags.homeless or flags.couch_surfing or flags.living_in_car then
				return false
			end
			-- Must have rental housing
			if flags.renting or flags.has_apartment or flags.renter then
				return true
			end
			-- Check HousingState
			if state.HousingState and state.HousingState.status == "renter" then
				return true
			end
			-- If homeowner, no landlord disputes
			if flags.homeowner or flags.has_house then
				return false
			end
			-- Default: probably renting if has any housing
			return flags.has_home or flags.has_own_place or flags.moved_out
		end,
		blockedByFlags = { homeless = true, in_prison = true },
		
		-- CRITICAL: Random landlord/tenant outcome
		choices = {
			{
				text = "Security deposit dispute",
				effects = {},
				feedText = "Fighting for your deposit...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🏠 Got full deposit back! Documented everything!")
					elseif roll < 0.70 then
						state.Money = (state.Money or 0) + 200
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🏠 Got partial deposit. Some unfair deductions.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🏠 Lost the deposit. Landlord made false claims.")
					end
				end,
			},
			{ text = "Repair/maintenance dispute", effects = { Happiness = -3 }, feedText = "🏠 Landlord won't fix things. Escalating issue." },
			{ text = "Eviction situation (costs $500)", effects = { Happiness = -8, Money = -500 }, setFlags = { eviction_on_record = true }, feedText = "🏠 Facing eviction. Stressful housing crisis.", eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 for moving expenses" end },
		},
	},
	{
		id = "legal_will_estate",
		title = "Will & Estate Planning",
		emoji = "📋",
		text = "Time to think about your will and estate.",
		question = "How do you handle estate planning?",
		minAge = 30, maxAge = 100,
		baseChance = 0.1,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "legal",
		tags = { "will", "estate", "planning" },
		
		choices = {
			{ text = "Create a comprehensive will ($300)", effects = { Money = -300, Happiness = 4, Smarts = 3 }, setFlags = { has_will = true }, feedText = "📋 Proper legal will created. Peace of mind.", eligibility = function(state) return (state.Money or 0) >= 300, "💸 Need $300 for lawyer" end },
			{ text = "DIY will kit ($30)", effects = { Money = -30, Happiness = 2, Smarts = 2 }, setFlags = { has_will = true }, feedText = "📋 Basic will done. Better than nothing.", eligibility = function(state) return (state.Money or 0) >= 30, "💸 Need $30 for will kit" end },
			{ text = "Put it off - morbid topic", effects = { Happiness = 1 }, feedText = "📋 Don't want to think about it. Later." },
		},
	},
	{
		id = "legal_workplace_lawsuit",
		title = "Workplace Legal Issue",
		emoji = "💼",
		text = "Workplace legal matter arising!",
		question = "What's the workplace issue?",
		minAge = 18, maxAge = 70,
		baseChance = 0.1,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "legal",
		tags = { "workplace", "lawsuit", "employment" },
		requiresJob = true,
		
		-- CRITICAL: Random workplace legal outcome
		choices = {
			{
				text = "Wrongful termination claim",
				effects = {},
				feedText = "Pursuing legal action...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state.Money = (state.Money or 0) + 5000
						state:ModifyStat("Happiness", 10)
						state:AddFeed("💼 WON! Wrongful termination proven! Settlement!")
					elseif roll < 0.60 then
						state.Money = (state.Money or 0) + 1000
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💼 Settled out of court. Some compensation.")
					else
						state:ModifyStat("Happiness", -6)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 500)
						state:AddFeed("💼 Case dismissed. Legal fees wasted.")
					end
				end,
			},
			{ text = "Discrimination complaint", effects = { Happiness = -3 }, feedText = "💼 Filing with EEOC. Long process. Standing up for rights." },
			{ text = "Let it go", effects = { Happiness = -2, Smarts = 2 }, feedText = "💼 Not worth the fight. Just move on." },
		},
	},
	{
		id = "legal_witness",
		title = "Called as Witness",
		emoji = "👁️",
		text = "You've been called as a witness in a legal case!",
		question = "How do you handle being a witness?",
		minAge = 18, maxAge = 90,
		baseChance = 0.32,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "legal",
		tags = { "witness", "testimony", "court" },
		
		-- CRITICAL: Random witness experience
		choices = {
			{
				text = "Testify honestly",
				effects = {},
				feedText = "Taking the stand...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("👁️ Testimony went well. Did your civic duty. Justice served.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("👁️ Stressful cross-examination. Twisted your words.")
					end
				end,
			},
			{ text = "Reluctant participant", effects = { Happiness = -2 }, feedText = "👁️ Didn't want involvement. Testified anyway. Civic duty." },
		},
	},
	{
		id = "legal_neighbor_dispute",
		title = "Neighbor Legal Dispute",
		emoji = "🏘️",
		text = "Legal dispute with a neighbor!",
		question = "What's the neighbor issue?",
		minAge = 20, maxAge = 90,
		baseChance = 0.38,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "legal",
		tags = { "neighbor", "dispute", "property" },
		
		-- CRITICAL: Random neighbor dispute
		choices = {
			{
				text = "Property line dispute",
				effects = {},
				feedText = "Arguing over boundaries...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🏘️ Survey proved you right. Boundary settled.")
					elseif roll < 0.65 then
						state:ModifyStat("Happiness", 1)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 200)
						state:AddFeed("🏘️ Compromise reached. Paid for survey. Peace.")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.neighbor_enemy = true
						state:AddFeed("🏘️ Ongoing feud. Awkward living situation. Tension.")
					end
				end,
			},
			{ text = "Nuisance complaint", effects = { Happiness = -3 }, feedText = "🏘️ Filed complaint about noise/eyesore. Relations strained." },
			{ text = "Mediation ($100)", effects = { Money = -100, Happiness = 3 }, feedText = "🏘️ Third party helped resolve. Better outcome.", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for mediator" end },
		},
	},
	{
		id = "legal_lawsuit_target",
		title = "You're Being Sued!",
		emoji = "⚠️",
		text = "Someone is suing you!",
		question = "How do you respond to the lawsuit?",
		minAge = 18, maxAge = 90,
		baseChance = 0.32,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "legal",
		tags = { "lawsuit", "defendant", "legal" },
		
		-- CRITICAL: Random lawsuit defense outcome
		choices = {
			{
				text = "Hire defense lawyer ($1,000)",
				effects = { Money = -1000 },
				feedText = "Fighting the lawsuit...",
				eligibility = function(state) return (state.Money or 0) >= 1000, "💸 Can't afford lawyer ($1,000 needed)" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.45 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("⚠️ Case dismissed! Lawyer proved their claims false!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -2)
						state.Money = math.max(0, (state.Money or 0) - 500)
						state:AddFeed("⚠️ Settled for less than sued for. Could've been worse.")
					else
						state:ModifyStat("Happiness", -10)
						state.Money = math.max(0, (state.Money or 0) - 3000)
						state.Flags = state.Flags or {}
						state.Flags.lost_lawsuit = true
						state:AddFeed("⚠️ Lost the case. Major financial hit. Devastating.")
					end
				end,
			},
			{ text = "Counter-sue ($500)", effects = { Money = -500 }, feedText = "Fighting back...",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Need $500 to file counter-suit" end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state.Money = (state.Money or 0) + 2000
						state:ModifyStat("Happiness", 8)
						state:AddFeed("⚠️ Counter-suit successful! Tables turned!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("⚠️ Counter-suit failed. Made things worse.")
					end
				end,
			},
			-- CRITICAL FIX: FREE OPTION to prevent hard lock!
			{
				text = "Represent yourself in court",
				effects = { Happiness = -5, Smarts = 3 },
				feedText = "Defending yourself pro se...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local winChance = 0.15 + (smarts / 300)
					
					if roll < winChance then
						state:ModifyStat("Happiness", 10)
						state:AddFeed("⚠️ You actually WON! The judge dismissed the case! Amazing!")
					elseif roll < (winChance * 2.5) then
						state:ModifyStat("Happiness", 2)
						state.Money = math.max(0, (state.Money or 0) - 500)
						state:AddFeed("⚠️ Settled for a smaller amount than they asked for.")
					else
						state:ModifyStat("Happiness", -8)
						state.Money = math.max(0, (state.Money or 0) - 1500)
						state:AddFeed("⚠️ Lost the case. At least you didn't pay lawyer fees.")
					end
				end,
			},
			{
				text = "Ignore the lawsuit completely",
				effects = { Happiness = -10 },
				feedText = "You didn't show up to court...",
				onResolve = function(state)
					state.Money = math.max(0, (state.Money or 0) - 2000)
					state.Flags = state.Flags or {}
					state.Flags.default_judgment = true
					state:AddFeed("⚠️ Default judgment against you! They won automatically. Bad move.")
				end,
			},
		},
	},
	{
		id = "legal_traffic_court",
		title = "Traffic Court",
		emoji = "🚦",
		text = "Have to deal with traffic court!",
		question = "How do you handle the traffic violation?",
		minAge = 16, maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "any",
		category = "legal",
		tags = { "traffic", "court", "driving" },
		-- CRITICAL FIX: Traffic court requires owning a car/having a license!
		requiresFlags = { has_car = true },
		eligibility = function(state)
			-- Must have a vehicle to get traffic violations!
			if state.Flags and (state.Flags.has_car or state.Flags.has_vehicle or state.Flags.has_drivers_license) then
				return true
			end
			-- Also check Assets
			if state.Assets and state.Assets.Vehicles and #state.Assets.Vehicles > 0 then
				return true
			end
			return false
		end,
		
		-- CRITICAL: Random traffic court outcome
		choices = {
			{
				text = "Fight the ticket in court",
				effects = {},
				feedText = "Appearing before the judge...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local winChance = 0.25 + (smarts / 200)
					
					if roll < winChance then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🚦 DISMISSED! Beat the ticket! No points, no fine!")
					elseif roll < (winChance * 2) then
						state:ModifyStat("Happiness", 3)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 100)
						state:AddFeed("🚦 Reduced fine. Better than full ticket.")
					else
						state:ModifyStat("Happiness", -4)
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 250)
						state:AddFeed("🚦 Judge wasn't convinced. Full fine plus court costs.")
					end
				end,
			},
			{ text = "Pay the fine ($150)", effects = { Money = -150, Happiness = -2 }, feedText = "🚦 Paid it. Easier than fighting. Points on license.", eligibility = function(state) return (state.Money or 0) >= 150, "💸 Need $150 for fine" end },
			{ text = "Traffic school ($75)", effects = { Money = -75, Smarts = 2, Happiness = -1 }, feedText = "🚦 Boring class but keeps points off license.", eligibility = function(state) return (state.Money or 0) >= 75, "💸 Need $75 for traffic school" end },
		},
	},
}

return LegalEvents
