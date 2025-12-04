local events = {
	{
		id = "childhood_playdate",
		emoji = "🧸",
		title = "Neighborhood Playdate",
		text = "Kids on your street invite you over for an afternoon of board games and freeze tag.",
		category = "family",
		weight = 8,
		conditions = {
			minAge = 5,
			maxAge = 10,
		},
		choices = {
			{
				index = 1,
				text = "Join the fun",
				effects = { Happiness = 3, Health = 1 },
				flags = { set = { "has_childhood_friends" } },
			},
			{
				index = 2,
				text = "Stay home",
				effects = { Happiness = -2, Smarts = 1 },
			},
		},
	},
	{
		id = "teen_social_media",
		emoji = "📱",
		title = "First Social Media Account",
		text = "Everyone at school is talking about the newest social platform. Create an account?",
		category = "social",
		weight = 6,
		conditions = {
			minAge = 12,
			maxAge = 18,
		},
		choices = {
			{
				index = 1,
				text = "Yes, sign up",
				effects = { Happiness = 2 },
				flags = { set = { "social_online" } },
			},
			{
				index = 2,
				text = "Not my thing",
				effects = { Happiness = -1, Smarts = 1 },
			},
		},
	},
	{
		id = "young_adult_move_out",
		emoji = "📦",
		title = "Moving Out",
		text = "You feel ready to leave home and get your own place.",
		category = "milestone",
		weight = 5,
		conditions = {
			minAge = 18,
			maxAge = 30,
		},
		choices = {
			{
				index = 1,
				text = "Get an apartment",
				effects = { Happiness = 4, Money = -5000 },
				flags = { set = { "living_independently" } },
			},
			{
				index = 2,
				text = "Stay with family",
				effects = { Happiness = -1, Money = 2000 },
			},
		},
	},
	{
		id = "midlife_burnout",
		emoji = "😫",
		title = "Career Burnout",
		text = "Years of grinding have left you exhausted. Take a sabbatical?",
		category = "work",
		weight = 4,
		conditions = {
			minAge = 35,
			maxAge = 55,
			requiredFlags = { "employed" },
		},
		choices = {
			{
				index = 1,
				text = "Take time off",
				effects = { Happiness = 6, Health = 3, Money = -8000 },
			},
			{
				index = 2,
				text = "Push through",
				effects = { Happiness = -4, Health = -3 },
				flags = { set = { "burnout_warning" } },
			},
		},
	},
}

return events
