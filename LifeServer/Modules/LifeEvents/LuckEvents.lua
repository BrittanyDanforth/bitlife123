--[[
    Luck Events
    Random lucky and unlucky events
    All events use randomized outcomes - NO god mode
]]

local LuckEvents = {}

local STAGE = "random"

LuckEvents.events = {
	{
		id = "luck_four_leaf",
		title = "Four-Leaf Clover",
		emoji = "🍀",
		text = "You found a four-leaf clover!",
		question = "Does the luck hold?",
		minAge = 5, maxAge = 100,
		baseChance = 0.25,
		cooldown = 4,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "luck", "clover", "fortune" },
		-- AAA FIX: Can't find clovers in prison!
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		choices = {
			{
				text = "Keep it for good luck",
				effects = {},
				feedText = "Keeping the lucky clover...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 8) end
						state.Money = (state.Money or 0) + 100
						state.Flags = state.Flags or {}
						state.Flags.lucky_clover = true
						if state.AddFeed then state:AddFeed("🍀 LUCK IS REAL! Good things happening! Keep the clover!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 4) end
						if state.AddFeed then state:AddFeed("🍀 Nice keepsake! Luck or not, makes you smile!") end
					end
				end,
			},
		},
	},
	{
		id = "luck_bird_poop",
		title = "Bird Poop",
		emoji = "💩",
		text = "A bird pooped on you!",
		question = "Is it actually good luck?",
		minAge = 5, maxAge = 100,
		baseChance = 0.1,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "bird", "luck", "gross" },
		-- AAA FIX: Can't get pooped on by birds in prison (indoor!)
		blockedByFlags = { in_prison = true, incarcerated = true },
		
		choices = {
			{
				text = "Believe it's good luck",
				effects = {},
				feedText = "Choosing to see the positive...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state.Money = (state.Money or 0) + 50
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 5) end
						if state.AddFeed then state:AddFeed("💩 The old wives tale was TRUE! Lucky day after the poop!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("💩 Just gross. No luck. Need a shower.") end
					end
				end,
			},
		},
	},
	{
		id = "luck_shooting_star",
		title = "Shooting Star",
		emoji = "⭐",
		text = "You saw a shooting star!",
		question = "Make a wish!",
		minAge = 5, maxAge = 100,
		baseChance = 0.32,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "star", "wish", "magic" },
		
		choices = {
			{
				text = "Make a heartfelt wish",
				effects = {},
				feedText = "Wishing on the star...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", 15) end
						state.Flags = state.Flags or {}
						state.Flags.wish_came_true = true
						if state.AddFeed then state:AddFeed("⭐ YOUR WISH CAME TRUE! Magic is real! Universe listening!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", 6) end
						if state.AddFeed then state:AddFeed("⭐ Beautiful moment. Wish made. Who knows what's possible?") end
					end
				end,
			},
		},
	},
	{
		id = "luck_broken_mirror",
		title = "Broken Mirror",
		emoji = "🪞",
		text = "You broke a mirror!",
		question = "7 years bad luck?",
		minAge = 8, maxAge = 100,
		baseChance = 0.1,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "mirror", "superstition", "bad_luck" },
		
		choices = {
			{
				text = "Believe in the curse",
				effects = {},
				feedText = "Worrying about bad luck...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						-- AAA FIX: Nil check for all state methods
						if state.ModifyStat then state:ModifyStat("Happiness", -6) end
						if state.AddFeed then state:AddFeed("🪞 Bad things DID happen! Superstition confirmed!") end
					else
						if state.ModifyStat then state:ModifyStat("Happiness", -2) end
						if state.AddFeed then state:AddFeed("🪞 Just a broken mirror. Cleaned it up. Life goes on.") end
					end
				end,
			},
			{ text = "Superstition is silly", effects = { Happiness = 2, Smarts = 2 }, feedText = "🪞 It's just glass. No such thing as curses. Rational." },
		},
	},
}

return LuckEvents
