local events = {
	{
		id = "highschool_crush",
		emoji = "💘",
		title = "Hallway Crush",
		text = "You keep running into the same person between classes. Ask them out?",
		category = "romance",
		weight = 7,
		conditions = {
			minAge = 14,
			maxAge = 19,
			blockedFlags = { "in_prison" },
		},
		choices = {
			{
				index = 1,
				text = "Shoot your shot",
				effects = { Happiness = 4 },
				onResolve = function(state)
					state:AddRelationship({
						name = "Hallway Crush",
						type = "romance",
						role = "Partner",
						relationship = 65,
					})
				end,
			},
			{
				index = 2,
				text = "Stay quiet",
				effects = { Happiness = -2 },
			},
		},
	},
	{
		id = "adulthood_engagement",
		emoji = "💍",
		title = "Perfect Proposal Moment",
		text = "Your partner hints they'd say yes if you popped the question.",
		category = "romance",
		weight = 5,
		conditions = {
			minAge = 21,
			requiredFlags = { "has_romantic_partner" },
		},
		choices = {
			{
				index = 1,
				text = "Propose",
				effects = { Happiness = 6, Money = -3000 },
				flags = { set = { "engaged" } },
			},
			{
				index = 2,
				text = "Not yet",
				effects = { Happiness = -3 },
			},
		},
	},
}

return events
