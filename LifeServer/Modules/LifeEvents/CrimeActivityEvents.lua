-- CrimeActivityEvents.lua
-- BitLife-style event cards for crime activities
-- Rich narrative events with choices and consequences

local CrimeActivityEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SHOPLIFTING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CrimeActivityEvents.Shoplift = {
	{
		id = "shoplift_easy",
		title = "🛒 Shoplifting",
		emoji = "🛒",
		weight = 30,
		texts = {
			"You're eyeing some merchandise at the store. The security guard looks distracted.",
			"The store is crowded. Perfect cover for some five-finger discount.",
			"You spot an expensive item with no security tag. Easy pickings.",
		},
		choices = {
			{ text = "🤫 Pocket it quickly", feed = "You slipped the item into your pocket.", successChance = 75, reward = {20, 150} },
			{ text = "🛍️ Hide it in a bag", feed = "You concealed the item in your bag.", successChance = 60, reward = {50, 200} },
			{ text = "👀 Wait for better opportunity", feed = "Patience is key...", successChance = 85, reward = {10, 80} },
			{ text = "🚶 Walk away", feed = "You decided not to risk it.", abort = true },
		},
	},
	{
		id = "shoplift_caught",
		title = "🚨 You're Being Watched!",
		emoji = "🚨",
		weight = 20,
		category = "danger",
		texts = {
			"The security guard is looking right at you!",
			"You noticed a loss prevention officer following you through the store.",
			"The shopkeeper keeps glancing at you suspiciously.",
		},
		choices = {
			{ text = "🏃 Run for it!", feed = "You bolted for the exit!", escapeChance = 50, risk = 60 },
			{ text = "🤷 Act casual", feed = "You pretended nothing happened.", escapeChance = 40, risk = 40 },
			{ text = "🙏 Put it back", feed = "You quietly returned the item.", abort = true, noConsequence = true },
		},
	},
	{
		id = "shoplift_jackpot",
		title = "💎 Expensive Find",
		emoji = "💎",
		weight = 10,
		texts = {
			"You spot an extremely valuable item without any security measures!",
			"Someone left their designer bag unattended near the entrance.",
		},
		choices = {
			{ text = "💰 Go for the big score", feed = "High risk, high reward!", successChance = 45, reward = {200, 500} },
			{ text = "🤏 Stick to small items", feed = "Play it safe.", successChance = 80, reward = {30, 100} },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PICKPOCKETING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CrimeActivityEvents.Pickpocket = {
	{
		id = "pickpocket_crowded",
		title = "👛 Pickpocketing",
		emoji = "👛",
		weight = 30,
		texts = {
			"You're in a crowded area. The perfect hunting ground.",
			"A distracted tourist has their wallet sticking out of their pocket.",
			"Someone just pulled cash from an ATM and shoved it loosely in their pocket.",
		},
		choices = {
			{ text = "🤏 Quick fingers", feed = "Your hands moved like lightning.", successChance = 70, reward = {30, 300} },
			{ text = "💨 Bump and grab", feed = "Classic technique.", successChance = 60, reward = {50, 400} },
			{ text = "👀 Wait for drunk targets", feed = "Easy marks after dark.", successChance = 80, reward = {20, 200} },
			{ text = "🚶 Not worth the risk", feed = "You walked away.", abort = true },
		},
	},
	{
		id = "pickpocket_wrong_person",
		title = "😰 Wrong Target!",
		emoji = "😰",
		weight = 15,
		category = "danger",
		texts = {
			"The person you targeted turns around - they're massive and angry!",
			"You picked the pocket of an off-duty cop!",
			"The mark grabbed your wrist mid-attempt!",
		},
		choices = {
			{ text = "👊 Fight your way out", feed = "Things got physical!", triggersCombat = true },
			{ text = "🏃 Run!", feed = "You broke free and ran!", escapeChance = 55, risk = 40 },
			{ text = "🙏 Apologize profusely", feed = "You begged for mercy.", risk = 30 },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- BURGLARY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CrimeActivityEvents.Burglary = {
	{
		id = "burglary_house",
		title = "🏠 Breaking In",
		emoji = "🏠",
		weight = 30,
		texts = {
			"You've cased this house for days. The owners are on vacation.",
			"The house looks empty. No cars in the driveway.",
			"A wealthy neighborhood with an unlocked window. Tempting.",
		},
		choices = {
			{ text = "🪟 Go through the window", feed = "You slipped inside through a window.", successChance = 65, reward = {500, 2000} },
			{ text = "🚪 Pick the lock", feed = "The lock gave way after some work.", successChance = 50, reward = {800, 3000}, triggersMinigame = "heist" },
			{ text = "🔨 Break in quickly", feed = "Loud but fast.", successChance = 40, reward = {300, 1500}, risk = 70 },
			{ text = "👀 Abort - too risky", feed = "You had a bad feeling.", abort = true },
		},
	},
	{
		id = "burglary_alarm",
		title = "🚨 ALARM!",
		emoji = "🚨",
		weight = 20,
		category = "danger",
		texts = {
			"A silent alarm just triggered! You can hear sirens in the distance!",
			"Motion sensors! Red lights are flashing everywhere!",
			"A dog starts barking loudly from inside the house!",
		},
		choices = {
			{ text = "🏃 Run NOW!", feed = "You fled empty-handed!", escapeChance = 70, abort = true },
			{ text = "⏱️ Grab what you can", feed = "Quick sweep!", successChance = 40, reward = {200, 800}, risk = 80 },
			{ text = "🙈 Hide and wait", feed = "You held your breath...", escapeChance = 30, risk = 50 },
		},
	},
	{
		id = "burglary_jackpot",
		title = "💰 Jackpot!",
		emoji = "💰",
		weight = 10,
		texts = {
			"You found a hidden safe behind a painting!",
			"There's a jewelry box overflowing with valuables!",
			"You stumbled upon a cash stash in the closet!",
		},
		choices = {
			{ text = "💎 Take everything", feed = "You loaded up!", successChance = 60, reward = {2000, 8000} },
			{ text = "🔓 Crack the safe", feed = "The real prize...", successChance = 35, reward = {5000, 15000}, triggersMinigame = "heist" },
			{ text = "🤏 Just the cash", feed = "Quick and clean.", successChance = 80, reward = {1000, 3000} },
		},
	},
	{
		id = "burglary_someone_home",
		title = "😱 Someone's Home!",
		emoji = "😱",
		weight = 15,
		category = "danger",
		texts = {
			"You hear footsteps! Someone IS home!",
			"A light just turned on upstairs!",
			"You hear someone calling the police!",
		},
		choices = {
			{ text = "🏃 Get out NOW!", feed = "You escaped through the window!", escapeChance = 65, abort = true },
			{ text = "🤫 Hide quietly", feed = "You froze in the shadows...", escapeChance = 40, risk = 50 },
			{ text = "👊 Confront them", feed = "This just became a home invasion!", triggersCombat = true, upgradedCrime = "home_invasion", risk = 90 },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CAR THEFT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CrimeActivityEvents.CarTheft = {
	{
		id = "car_theft_easy",
		title = "🚗 Grand Theft Auto",
		emoji = "🚗",
		weight = 30,
		texts = {
			"You spot a nice car with the keys left in the ignition.",
			"A luxury car is parked in a dark alley. Perfect.",
			"Someone just left their car running while they ran into a store.",
		},
		choices = {
			{ text = "🔑 Jump in and drive", feed = "You hopped in and floored it!", successChance = 70, reward = {3000, 15000} },
			{ text = "🔧 Hotwire it", feed = "Working on the wires...", successChance = 55, reward = {5000, 20000}, triggersMinigame = "qte" },
			{ text = "📱 Call for backup", feed = "You're bringing friends.", successChance = 60, reward = {4000, 12000} },
			{ text = "🚶 Walk away", feed = "Too much heat.", abort = true },
		},
	},
	{
		id = "car_theft_chase",
		title = "🚔 Police Chase!",
		emoji = "🚔",
		weight = 20,
		category = "danger",
		texts = {
			"Sirens! The cops are right behind you!",
			"A police cruiser spotted you and is in pursuit!",
			"Helicopter spotlight! You're being tracked from above!",
		},
		choices = {
			{ text = "🚗 Gun it!", feed = "FLOOR IT!", triggersMinigame = "getaway", risk = 70 },
			{ text = "🏃 Bail and run", feed = "You ditched the car and ran!", escapeChance = 50, abort = true },
			{ text = "🛑 Pull over", feed = "You gave up...", surrender = true },
		},
	},
	{
		id = "car_theft_luxury",
		title = "💎 Exotic Car",
		emoji = "💎",
		weight = 10,
		texts = {
			"A Lamborghini sits unattended in a parking garage.",
			"There's a limited edition sports car with a 'For Sale' sign.",
		},
		choices = {
			{ text = "🔑 Go for it", feed = "This is the big leagues!", successChance = 40, reward = {20000, 100000}, risk = 80 },
			{ text = "🚗 Stick to normal cars", feed = "Less attention.", successChance = 70, reward = {3000, 10000} },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- BANK ROBBERY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CrimeActivityEvents.BankRobbery = {
	{
		id = "bank_robbery_heist",
		title = "🏦 Bank Heist",
		emoji = "🏦",
		weight = 25,
		texts = {
			"You've planned this heist for months. It's time to execute.",
			"The bank security rotations have a 3-minute gap. That's your window.",
			"Your crew is in position. This is it.",
		},
		choices = {
			{ text = "🎭 Go in masked", feed = "Everyone down on the ground!", successChance = 45, reward = {50000, 200000}, triggersMinigame = "heist", risk = 85 },
			{ text = "🤫 Subtle approach", feed = "You walked in calm and collected.", successChance = 35, reward = {30000, 100000}, risk = 70 },
			{ text = "🚪 Hit the vault directly", feed = "Cut straight to the prize!", successChance = 25, reward = {100000, 500000}, triggersMinigame = "heist", risk = 95 },
			{ text = "😰 Abort mission", feed = "Cold feet at the last moment.", abort = true },
		},
	},
	{
		id = "bank_robbery_vault",
		title = "🔐 The Vault",
		emoji = "🔐",
		weight = 20,
		texts = {
			"You're inside! The vault is right there!",
			"The vault door is more complex than you thought.",
		},
		choices = {
			{ text = "🔓 Crack the code", feed = "Numbers flying through your head...", triggersMinigame = "heist", successChance = 40, reward = {100000, 300000} },
			{ text = "💣 Blow it open", feed = "BOOM!", successChance = 50, reward = {80000, 200000}, risk = 90, loudAlarm = true },
			{ text = "💼 Take the cash drawers", feed = "Settling for what you can grab.", successChance = 70, reward = {20000, 50000} },
		},
	},
	{
		id = "bank_robbery_hostage",
		title = "👥 Hostage Situation",
		emoji = "👥",
		weight = 15,
		category = "danger",
		texts = {
			"The cops have the building surrounded! You have hostages!",
			"A silent alarm was triggered. SWAT is outside!",
		},
		choices = {
			{ text = "🗣️ Negotiate", feed = "You demanded a helicopter...", escapeChance = 20, risk = 60 },
			{ text = "😇 Release hostages", feed = "You let everyone go.", surrender = true, reducedSentence = true },
			{ text = "🏃 Find an escape route", feed = "There has to be a back way out!", escapeChance = 30, risk = 75 },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ASSAULT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CrimeActivityEvents.Assault = {
	{
		id = "assault_confrontation",
		title = "👊 Violent Confrontation",
		emoji = "👊",
		weight = 30,
		texts = {
			"You've tracked down the person who wronged you. It's time for payback.",
			"Someone is talking smack about you. Are you gonna take that?",
			"This person has it coming. They've pushed you too far.",
		},
		choices = {
			{ text = "👊 Attack them", feed = "You threw the first punch!", triggersCombat = true },
			{ text = "🗣️ Intimidate them", feed = "You got in their face.", successChance = 60, effects = { respect = 5 } },
			{ text = "😤 Threaten them", feed = "You made your intentions clear.", risk = 30 },
			{ text = "🚶 Walk away", feed = "They're not worth it.", abort = true, effects = { Happiness = -5 } },
		},
	},
	{
		id = "assault_fight_result_win",
		title = "🏆 Victory!",
		emoji = "🏆",
		weight = 25,
		condition = function(state) return state.lastCombatWon == true end,
		texts = {
			"You beat them down! They're not getting up anytime soon.",
			"They never saw it coming. You destroyed them.",
		},
		effects = { Happiness = {5, 15} },
		choices = {
			{ text = "😤 Stand over them", feed = "Let that be a lesson.", effects = { respect = 10 } },
			{ text = "🚶 Walk away cool", feed = "Justice served." },
			{ text = "📱 Someone's filming!", feed = "This might go viral...", risk = 40 },
		},
	},
	{
		id = "assault_fight_result_lose",
		title = "😵 Beaten Down",
		emoji = "😵",
		weight = 25,
		condition = function(state) return state.lastCombatWon == false end,
		texts = {
			"They were tougher than you expected. You're on the ground.",
			"You got destroyed. This is embarrassing.",
		},
		effects = { Health = {-15, -30}, Happiness = {-10, -20} },
		choices = {
			{ text = "😤 Swear revenge", feed = "This isn't over..." },
			{ text = "😔 Lick your wounds", feed = "You learned your lesson." },
			{ text = "🏥 Go to hospital", feed = "You need medical attention.", cost = 500, effects = { Health = 20 } },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MUGGING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
CrimeActivityEvents.Mugging = {
	{
		id = "mugging_target",
		title = "🔪 Mugging",
		emoji = "🔪",
		weight = 30,
		texts = {
			"A lone person is walking through a dark alley.",
			"Someone looks lost and vulnerable. Easy target.",
			"A drunk person is stumbling home alone late at night.",
		},
		choices = {
			{ text = "🔪 Threaten with weapon", feed = "Give me everything!", successChance = 70, reward = {50, 500}, risk = 60 },
			{ text = "👊 Strong-arm them", feed = "Physical intimidation!", triggersCombat = true, reward = {30, 300} },
			{ text = "🗣️ Verbal intimidation", feed = "You look scary enough.", successChance = 50, reward = {20, 200}, risk = 40 },
			{ text = "🚶 Changed my mind", feed = "This isn't you.", abort = true },
		},
	},
	{
		id = "mugging_fight_back",
		title = "⚠️ They're Fighting Back!",
		emoji = "⚠️",
		weight = 20,
		category = "danger",
		texts = {
			"The victim pulled out a weapon!",
			"They're not backing down - they want to fight!",
			"This person knows how to handle themselves!",
		},
		choices = {
			{ text = "👊 Fight!", feed = "It's on!", triggersCombat = true },
			{ text = "🏃 Run away!", feed = "Not worth it!", escapeChance = 65, abort = true },
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

function CrimeActivityEvents.getRandomEvent(crimeType, state)
	local events = CrimeActivityEvents[crimeType]
	if not events then return nil end
	
	local validEvents = {}
	local totalWeight = 0
	
	for _, event in ipairs(events) do
		local valid = true
		if event.condition and not event.condition(state) then
			valid = false
		end
		
		if valid then
			table.insert(validEvents, event)
			totalWeight = totalWeight + (event.weight or 10)
		end
	end
	
	if #validEvents == 0 then return nil end
	
	local roll = math.random(totalWeight)
	local cumWeight = 0
	
	for _, event in ipairs(validEvents) do
		cumWeight = cumWeight + (event.weight or 10)
		if roll <= cumWeight then
			local eventCopy = {}
			for k, v in pairs(event) do
				eventCopy[k] = v
			end
			
			if eventCopy.texts and #eventCopy.texts > 0 then
				eventCopy.text = eventCopy.texts[math.random(#eventCopy.texts)]
			end
			
			return eventCopy
		end
	end
	
	return validEvents[1]
end

-- Map crime IDs to event categories
CrimeActivityEvents.CrimeMapping = {
	shoplift = "Shoplift",
	pickpocket = "Pickpocket",
	burglary = "Burglary",
	car_theft = "CarTheft",
	gta = "CarTheft",
	bank_robbery = "BankRobbery",
	assault = "Assault",
	mugging = "Mugging",
}

function CrimeActivityEvents.getEventForCrime(crimeId, state)
	local category = CrimeActivityEvents.CrimeMapping[crimeId]
	if category then
		return CrimeActivityEvents.getRandomEvent(category, state)
	end
	return nil
end

return CrimeActivityEvents
