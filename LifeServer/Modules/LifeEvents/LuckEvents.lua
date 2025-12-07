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
		baseChance = 0.05,
		cooldown = 10,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "luck", "clover", "fortune" },
		
		choices = {
			{
				text = "Keep it for good luck",
				effects = {},
				feedText = "Keeping the lucky clover...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 8)
						state.Money = (state.Money or 0) + 100
						state.Flags = state.Flags or {}
						state.Flags.lucky_clover = true
						state:AddFeed("🍀 LUCK IS REAL! Good things happening! Keep the clover!")
					else
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🍀 Nice keepsake! Luck or not, makes you smile!")
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
		cooldown = 5,
		stage = STAGE,
		ageBand = "any",
		category = "luck",
		tags = { "bird", "luck", "gross" },
		
		choices = {
			{
				text = "Believe it's good luck",
				effects = {},
				feedText = "Choosing to see the positive...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state.Money = (state.Money or 0) + 50
						state:ModifyStat("Happiness", 5)
						state:AddFeed("💩 The old wives tale was TRUE! Lucky day after the poop!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("💩 Just gross. No luck. Need a shower.")
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
		baseChance = 0.08,
		cooldown = 8,
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
						state:ModifyStat("Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.wish_came_true = true
						state:AddFeed("⭐ YOUR WISH CAME TRUE! Magic is real! Universe listening!")
					else
						state:ModifyStat("Happiness", 6)
						state:AddFeed("⭐ Beautiful moment. Wish made. Who knows what's possible?")
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
		cooldown = 8,
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
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🪞 Bad things DID happen! Superstition confirmed!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🪞 Just a broken mirror. Cleaned it up. Life goes on.")
					end
				end,
			},
			{ text = "Superstition is silly", effects = { Happiness = 2, Smarts = 2 }, feedText = "🪞 It's just glass. No such thing as curses. Rational." },
		},
	},
}

return LuckEvents
