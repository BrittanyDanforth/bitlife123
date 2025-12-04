local events = {
	{
		id = "job_offer_barista",
		emoji = "☕",
		title = "Café Job Offer",
		text = "A boutique café downtown desperately needs help. They like your vibe.",
		category = "work",
		weight = 12,
		conditions = {
			minAge = 15,
			maxAge = 30,
			blockedFlags = { "employed" },
		},
		choices = {
			{
				index = 1,
				text = "Accept job",
				flags = { set = { "employed" } },
				onResolve = function(state)
					state:SetCareer({
						id = "barista",
						name = "Barista",
						company = "Bloom Cafe",
						salary = 24000,
						category = "service",
					})
				end,
			},
			{
				index = 2,
				text = "Decline",
				effects = { Happiness = -1 },
			},
		},
	},
	{
		id = "coding_bootcamp_offer",
		emoji = "💻",
		title = "Coding Bootcamp Scholarship",
		text = "You win a partial scholarship to an elite coding bootcamp.",
		category = "education",
		weight = 6,
		conditions = {
			minAge = 17,
			maxAge = 30,
			requiredFlags = { "social_online" },
		},
		choices = {
			{
				index = 1,
				text = "Enroll",
				effects = { Smarts = 4, Money = -4000 },
				flags = { set = { "college_student", "bootcamp_grad_pending" } },
				onResolve = function(state)
					state:EnrollEducation({
						name = "Stacks Academy",
						type = "bootcamp",
						cost = 4000,
					})
				end,
			},
			{
				index = 2,
				text = "Skip it",
				effects = { Happiness = -2 },
			},
		},
	},
	{
		id = "promotion_offer",
		emoji = "⬆️",
		title = "Promotion Consideration",
		text = "Your manager calls you in to discuss a promotion with more responsibility.",
		category = "work",
		weight = 9,
		conditions = {
			minAge = 20,
			requiredFlags = { "employed" },
			minStats = { Smarts = 45 },
		},
		choices = {
			{
				index = 1,
				text = "Accept promotion",
				effects = { Happiness = 3 },
				onResolve = function(state)
					state.Career.salary = math.floor((state.Career.salary or 30000) * 1.35)
					state.Career.jobTitle = "Senior " .. (state.Career.jobTitle or "Associate")
					state:AddFeed("You were promoted!")
				end,
			},
			{
				index = 2,
				text = "Decline politely",
				effects = { Happiness = -1 },
			},
		},
	},
}

return events
