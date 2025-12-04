local events = {
	{
		id = "petty_theft_dare",
		emoji = "🕵️",
		title = "Dare to Steal",
		text = "Friends dare you to pocket a pricey pair of headphones from an electronics store.",
		category = "crime",
		weight = 5,
		conditions = {
			minAge = 13,
			maxAge = 25,
			blockedFlags = { "in_prison" },
		},
		choices = {
			{
				index = 1,
				text = "Do it",
				effects = { Happiness = 2, Looks = -1 },
				onResolve = function(state)
					if Random.new():NextNumber() < 0.45 then
						state:SetFlag("criminal_record", true)
						state:SetFlag("in_prison", true)
						state:AddFeed("Security caught you! You spent a night in juvenile detention.")
					else
						state:AddFeed("You got away with the theft.")
						state:AddMoney(200, "Sold stolen headphones")
					end
				end,
			},
			{
				index = 2,
				text = "Refuse",
				effects = { Happiness = -1, Health = 1 },
			},
		},
	},
	{
		id = "white_collar_scheme",
		emoji = "💼",
		title = "Insider Trading Tip",
		text = "A coworker slips you a stock tip that seems too good to be legal.",
		category = "crime",
		weight = 3,
		conditions = {
			minAge = 25,
			requiredFlags = { "employed" },
		},
		choices = {
			{
				index = 1,
				text = "Invest secretly",
				effects = { Money = 15000, Happiness = 3 },
				onResolve = function(state)
					if Random.new():NextNumber() < 0.25 then
						state:SetFlag("criminal_record", true)
						state:SetFlag("in_prison", true)
						state:AddFeed("Authorities traced suspicious trades back to you. You were arrested.")
					end
				end,
			},
			{
				index = 2,
				text = "Report it",
				effects = { Happiness = -1, Smarts = 2 },
			},
		},
	},
}

return events
