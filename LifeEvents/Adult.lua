-- LifeEvents/Adult.lua
-- Adult life events (ages 18+) - Career, family, major life decisions

local AdultEvents = {}

AdultEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════
	-- YOUNG ADULT (18-29) - Finding your path
	-- ══════════════════════════════════════════════════════════════════════
	
	{
		id = "moving_out",
		title = "Time to Leave the Nest",
		emoji = "🏠",
		category = "milestone",
		text = "You're considering moving out of your parents' house.",
		question = "What's your plan?",
		minAge = 18, maxAge = 24,
		oneTime = true,
		choices = {
			{
				text = "Get my own apartment",
				effects = { Happiness = 10, Money = -500 },
				setFlags = { lives_alone = true, independent = true },
				feedText = "You got your own place! Freedom!",
			},
			{
				text = "Find roommates",
				effects = { Happiness = 5, Money = -200 },
				setFlags = { has_roommates = true },
				feedText = "You moved in with roommates. Cheaper but... interesting.",
			},
			{
				text = "Stay home to save money",
				effects = { Money = 300, Happiness = -3 },
				setFlags = { lives_with_parents = true },
				feedText = "You're staying home. Smart financially.",
			},
		},
	},
	
	{
		id = "college_experience",
		title = "College Life",
		emoji = "📚",
		category = "education",
		text = "College is a whole new world of experiences.",
		question = "What's your focus?",
		minAge = 18, maxAge = 22,
		requiresFlags = { college_bound = true },
		cooldown = 2,
		choices = {
			{
				text = "Study hard, get great grades",
				effects = { Smarts = 7, Happiness = -2, Health = -2 },
				setFlags = { honors_student = true },
				feedText = "You're crushing it academically!",
			},
			{
				text = "Balance academics and social life",
				effects = { Smarts = 4, Happiness = 5 },
				feedText = "You're getting the full college experience.",
			},
			{
				text = "Party now, study later",
				effects = { Happiness = 8, Smarts = -2, Health = -3 },
				setFlags = { party_animal = true },
				feedText = "College is about the experience, right?",
			},
			{
				text = "Focus on networking and internships",
				effects = { Smarts = 3, Money = 100 },
				setFlags = { career_focused = true },
				hintCareer = "business",
				feedText = "You're building your professional network early.",
			},
		},
	},
	
	{
		id = "major_choice",
		title = "Declaring Your Major",
		emoji = "📋",
		category = "education",
		text = "It's time to officially declare your major.",
		question = "What will you study?",
		minAge = 19, maxAge = 21,
		oneTime = true,
		requiresFlags = { college_bound = true },
		choices = {
			{
				text = "STEM (Science/Tech/Engineering/Math)",
				effects = { Smarts = 5 },
				setFlags = { stem_major = true },
				hintCareer = "tech",
				feedText = "You're majoring in STEM. Challenging but rewarding.",
			},
			{
				text = "Business/Finance",
				effects = { Smarts = 3, Money = 50 },
				setFlags = { business_major = true },
				hintCareer = "finance",
				feedText = "You're studying business. Follow the money!",
			},
			{
				text = "Pre-Med/Health Sciences",
				effects = { Smarts = 7, Health = -2 },
				setFlags = { premed = true },
				hintCareer = "medical",
				feedText = "You're on the pre-med track. Intense!",
			},
			{
				text = "Pre-Law",
				effects = { Smarts = 5 },
				setFlags = { prelaw = true },
				hintCareer = "law",
				feedText = "You're preparing for law school.",
			},
			{
				text = "Arts/Humanities",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { arts_major = true },
				hintCareer = "creative",
				feedText = "You're following your creative passions.",
			},
			{
				text = "Education",
				effects = { Smarts = 3, Happiness = 3 },
				setFlags = { education_major = true },
				hintCareer = "education",
				feedText = "You want to shape young minds.",
			},
		},
	},
	
	{
		id = "first_real_job",
		title = "Career Beginning",
		emoji = "💼",
		category = "career",
		text = "You're starting your first 'real' job in your field.",
		question = "How do you approach your new role?",
		minAge = 21, maxAge = 28,
		oneTime = true,
		choices = {
			{
				text = "Work extra hard to impress",
				effects = { Smarts = 3, Health = -3, Money = 100 },
				setFlags = { hard_worker = true },
				feedText = "You're giving 110% to prove yourself.",
			},
			{
				text = "Do good work, maintain balance",
				effects = { Happiness = 5, Money = 50 },
				setFlags = { work_life_balance = true },
				feedText = "You're doing well while maintaining your life.",
			},
			{
				text = "Network and build relationships",
				effects = { Happiness = 3 },
				setFlags = { networker = true },
				feedText = "You're focused on making connections.",
			},
			{
				text = "Minimal effort, maximum coasting",
				effects = { Happiness = 3, Smarts = -2 },
				setFlags = { slacker = true },
				feedText = "You're doing just enough to get by.",
			},
		},
	},
	
	{
		id = "serious_relationship",
		title = "Getting Serious",
		emoji = "💑",
		category = "romance",
		text = "Your relationship is getting more serious. They want to talk about the future.",
		question = "How do you feel?",
		minAge = 20, maxAge = 35,
		baseChance = 0.6,
		cooldown = 3,
		choices = {
			{
				text = "I'm ready to commit",
				effects = { Happiness = 10 },
				setFlags = { committed_relationship = true },
				feedText = "You're ready for a serious commitment!",
			},
			{
				text = "Let's take it slow",
				effects = { Happiness = 3 },
				feedText = "You want to take things one step at a time.",
			},
			{
				text = "I'm not sure about this",
				effects = { Happiness = -5 },
				feedText = "You have doubts about the relationship.",
			},
			{
				text = "I need to end this",
				effects = { Happiness = -8 },
				setFlags = { recently_single = true },
				feedText = "You ended the relationship. It's hard but necessary.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════
	-- ADULT (30-49) - Building life, family, career peak
	-- ══════════════════════════════════════════════════════════════════════
	
	{
		id = "stage_transition_adult",
		title = "The Big 3-0",
		emoji = "🎂",
		category = "milestone",
		text = "You're turning 30! A new chapter of adulthood begins.",
		question = "How do you feel about this milestone?",
		minAge = 30, maxAge = 30,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		choices = {
			{
				text = "Excited for what's ahead",
				effects = { Happiness = 5 },
				feedText = "30 is the new 20! You're just getting started.",
			},
			{
				text = "Reflective and content",
				effects = { Happiness = 3, Smarts = 2 },
				feedText = "You're proud of how far you've come.",
			},
			{
				text = "A bit anxious",
				effects = { Happiness = -3 },
				feedText = "Where did the time go? Mild existential crisis.",
			},
			{
				text = "Time to make changes",
				effects = { Happiness = 3 },
				setFlags = { making_changes = true },
				feedText = "This birthday inspired some life changes.",
			},
		},
	},
	
	{
		id = "marriage_proposal",
		title = "The Big Question",
		emoji = "💍",
		category = "romance",
		text = "It's time to consider marriage.",
		question = "What happens?",
		minAge = 24, maxAge = 45,
		oneTime = true,
		requiresFlags = { committed_relationship = true },
		choices = {
			{
				text = "Pop the question (they say yes!)",
				effects = { Happiness = 15 },
				setFlags = { engaged = true, marriage_pending = true },
				feedText = "They said YES! Wedding planning begins!",
			},
			{
				text = "Pop the question (they say no)",
				effects = { Happiness = -15 },
				setFlags = { proposal_rejected = true },
				feedText = "They said no. Devastating.",
			},
			{
				text = "Get proposed to (say yes!)",
				effects = { Happiness = 15 },
				setFlags = { engaged = true, marriage_pending = true },
				feedText = "You said YES! Wedding planning begins!",
			},
			{
				text = "Not ready yet",
				effects = { Happiness = -2 },
				feedText = "Marriage can wait.",
			},
		},
	},
	
	{
		id = "buying_home",
		title = "Buying a Home",
		emoji = "🏡",
		category = "finance",
		text = "You're considering buying your first home.",
		question = "What's your approach?",
		minAge = 25, maxAge = 50,
		oneTime = true,
		requiresStats = { Money = { min = 1000 } },
		choices = {
			{
				text = "Buy a starter home",
				effects = { Happiness = 10, Money = -5000 },
				setFlags = { homeowner = true },
				feedText = "You bought your first home! A big milestone!",
			},
			{
				text = "Stretch for your dream home",
				effects = { Happiness = 15, Money = -15000, Health = -3 },
				setFlags = { homeowner = true, high_mortgage = true },
				feedText = "You got your dream home! But the mortgage is steep.",
			},
			{
				text = "Keep renting for now",
				effects = { Money = 500 },
				feedText = "You'll rent a bit longer. More flexibility.",
			},
			{
				text = "Move to a cheaper area",
				effects = { Happiness = 5, Money = -3000 },
				setFlags = { homeowner = true, relocated = true },
				feedText = "You moved somewhere more affordable!",
			},
		},
	},
	
	{
		id = "having_children",
		title = "Starting a Family",
		emoji = "👶",
		category = "family",
		text = "You and your partner are talking about having children.",
		question = "What's the decision?",
		minAge = 25, maxAge = 45,
		oneTime = true,
		requiresFlags = { married = true },
		choices = {
			{
				text = "Yes, we want children!",
				effects = { Happiness = 10, Money = -2000, Health = -2 },
				setFlags = { has_children = true, parent = true },
				feedText = "You're going to be a parent! Life changes forever.",
			},
			{
				text = "Maybe someday",
				effects = { Happiness = 2 },
				feedText = "Kids are on the horizon, but not yet.",
			},
			{
				text = "We prefer to stay child-free",
				effects = { Happiness = 5, Money = 1000 },
				setFlags = { childfree = true },
				feedText = "You've decided not to have children. More freedom!",
			},
			{
				text = "Adopt a child",
				effects = { Happiness = 12, Money = -3000 },
				setFlags = { has_children = true, parent = true, adopted = true },
				feedText = "You adopted a child! Welcome to the family!",
			},
		},
	},
	
	{
		id = "career_crossroads",
		title = "Career Crossroads",
		emoji = "🛤️",
		category = "career",
		text = "You're at a turning point in your career.",
		question = "What path do you take?",
		minAge = 28, maxAge = 45,
		baseChance = 0.5,
		cooldown = 5,
		choices = {
			{
				text = "Push for a promotion",
				effects = { Smarts = 2, Money = {-100, 500}, Happiness = {-3, 10} },
				feedText = "You went for the promotion!",
			},
			{
				text = "Change companies for better pay",
				effects = { Money = 1000, Happiness = 3 },
				setFlags = { job_hopper = true },
				feedText = "You switched jobs for a raise!",
			},
			{
				text = "Pivot to a new career entirely",
				effects = { Smarts = 5, Money = -1000, Happiness = 5 },
				setFlags = { career_changer = true },
				feedText = "You're starting over in a new field!",
			},
			{
				text = "Stay the course",
				effects = { Happiness = 2 },
				feedText = "You're content where you are.",
			},
		},
	},
	
	{
		id = "midlife_health",
		title = "Health Wake-Up Call",
		emoji = "🏥",
		category = "health",
		text = "A routine checkup reveals you need to pay more attention to your health.",
		question = "How do you respond?",
		minAge = 35, maxAge = 50,
		baseChance = 0.4,
		cooldown = 5,
		choices = {
			{
				text = "Complete lifestyle overhaul",
				effects = { Health = 15, Happiness = 5, Money = -500 },
				setFlags = { health_conscious = true },
				feedText = "You transformed your lifestyle. Feeling great!",
			},
			{
				text = "Make gradual improvements",
				effects = { Health = 8, Happiness = 3 },
				feedText = "You're making steady health improvements.",
			},
			{
				text = "Ignore it and hope for the best",
				effects = { Health = -10, Happiness = -5 },
				feedText = "You ignored the warning signs...",
			},
			{
				text = "Become obsessive about health",
				effects = { Health = 10, Happiness = -5, Money = -1000 },
				setFlags = { health_obsessed = true },
				feedText = "Health became your entire focus. Maybe too much.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════
	-- MIDDLE AGE (50-64) - Legacy, transitions
	-- ══════════════════════════════════════════════════════════════════════
	
	{
		id = "stage_transition_middle_age",
		title = "Turning 50",
		emoji = "🎉",
		category = "milestone",
		text = "You're turning 50! Half a century of experiences.",
		question = "How do you celebrate?",
		minAge = 50, maxAge = 50,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		choices = {
			{
				text = "Big party with friends and family",
				effects = { Happiness = 10, Money = -500 },
				feedText = "You celebrated in style!",
			},
			{
				text = "Travel somewhere special",
				effects = { Happiness = 12, Money = -2000 },
				feedText = "You took a memorable trip!",
			},
			{
				text = "Quiet reflection",
				effects = { Happiness = 5, Smarts = 3 },
				feedText = "You took time to reflect on your journey.",
			},
			{
				text = "Ignore it completely",
				effects = { Happiness = -3 },
				feedText = "Just another day... right?",
			},
		},
	},
	
	{
		id = "empty_nest",
		title = "Empty Nest",
		emoji = "🪹",
		category = "family",
		text = "Your children have grown up and moved out.",
		question = "How do you feel?",
		minAge = 45, maxAge = 60,
		oneTime = true,
		requiresFlags = { has_children = true },
		choices = {
			{
				text = "Sad but proud",
				effects = { Happiness = -3 },
				setFlags = { empty_nester = true },
				feedText = "You miss them, but you raised them well.",
			},
			{
				text = "Excited for new freedom",
				effects = { Happiness = 10, Money = 500 },
				setFlags = { empty_nester = true },
				feedText = "A new chapter of freedom begins!",
			},
			{
				text = "Focus on your relationship",
				effects = { Happiness = 8 },
				setFlags = { empty_nester = true },
				feedText = "You and your partner reconnect.",
			},
			{
				text = "Fill the void with new hobbies",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { empty_nester = true },
				feedText = "You discovered new passions.",
			},
		},
	},
	
	{
		id = "retirement_planning",
		title = "Thinking About Retirement",
		emoji = "📊",
		category = "finance",
		text = "Retirement is on the horizon. Are you prepared?",
		question = "What's your retirement outlook?",
		minAge = 50, maxAge = 62,
		oneTime = true,
		choices = {
			{
				text = "Well prepared - saved consistently",
				effects = { Happiness = 10, Money = 5000 },
				setFlags = { retirement_ready = true },
				feedText = "Your years of saving paid off!",
			},
			{
				text = "Moderately prepared",
				effects = { Happiness = 5, Money = 1000 },
				setFlags = { retirement_possible = true },
				feedText = "You'll be okay, but not lavish.",
			},
			{
				text = "Not at all - need to work longer",
				effects = { Happiness = -5 },
				setFlags = { must_keep_working = true },
				feedText = "Retirement will have to wait.",
			},
			{
				text = "Planning early retirement",
				effects = { Happiness = 8, Money = -2000 },
				setFlags = { early_retirement = true },
				feedText = "You're cutting out early!",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════
	-- SENIOR (65+) - Wisdom, legacy, final chapters
	-- ══════════════════════════════════════════════════════════════════════
	
	{
		id = "stage_transition_senior",
		title = "Golden Years Begin",
		emoji = "🌅",
		category = "milestone",
		text = "You've reached 65! The senior years begin.",
		question = "How do you approach this new phase?",
		minAge = 65, maxAge = 65,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		choices = {
			{
				text = "Embrace retirement fully",
				effects = { Happiness = 10 },
				setFlags = { retired = true },
				feedText = "Retirement is here! Time to relax.",
			},
			{
				text = "Keep working part-time",
				effects = { Happiness = 5, Money = 500 },
				setFlags = { semi_retired = true },
				feedText = "You're staying active in the workforce.",
			},
			{
				text = "Focus on hobbies and travel",
				effects = { Happiness = 12, Money = -1000 },
				feedText = "Time to enjoy life to the fullest!",
			},
			{
				text = "Dedicate time to family",
				effects = { Happiness = 8 },
				feedText = "Family becomes your focus.",
			},
		},
	},
	
	{
		id = "grandchildren",
		title = "Becoming a Grandparent",
		emoji = "👴",
		category = "family",
		text = "Your child is having a baby. You're going to be a grandparent!",
		question = "How do you feel?",
		minAge = 45, maxAge = 75,
		oneTime = true,
		requiresFlags = { has_children = true },
		choices = {
			{
				text = "Overjoyed!",
				effects = { Happiness = 15 },
				setFlags = { grandparent = true },
				feedText = "You're a grandparent! The circle of life continues.",
			},
			{
				text = "Happy but feeling old",
				effects = { Happiness = 8 },
				setFlags = { grandparent = true },
				feedText = "A grandparent... when did that happen?",
			},
			{
				text = "Ready to spoil them",
				effects = { Happiness = 10, Money = -500 },
				setFlags = { grandparent = true, spoiling_grandparent = true },
				feedText = "Grandparent privileges: spoil and return!",
			},
		},
	},
	
	{
		id = "legacy_reflection",
		title = "Reflecting on Legacy",
		emoji = "📖",
		category = "personal",
		text = "You're thinking about the legacy you'll leave behind.",
		question = "What matters most to you?",
		minAge = 60, maxAge = 80,
		oneTime = true,
		choices = {
			{
				text = "Family and relationships",
				effects = { Happiness = 10 },
				setFlags = { family_legacy = true },
				feedText = "Your greatest legacy is the people you love.",
			},
			{
				text = "Career achievements",
				effects = { Happiness = 5, Smarts = 2 },
				setFlags = { professional_legacy = true },
				feedText = "You're proud of what you accomplished.",
			},
			{
				text = "Helping others",
				effects = { Happiness = 12 },
				setFlags = { charitable_legacy = true },
				feedText = "Making a difference was your calling.",
			},
			{
				text = "Still building my legacy",
				effects = { Happiness = 5 },
				feedText = "You're not done yet!",
			},
		},
	},
	
	{
		id = "health_challenge_senior",
		title = "Health Challenges",
		emoji = "🏥",
		category = "health",
		text = "Age brings some health challenges that need attention.",
		question = "How do you handle them?",
		minAge = 65, maxAge = 90,
		baseChance = 0.5,
		cooldown = 3,
		choices = {
			{
				text = "Follow doctor's orders carefully",
				effects = { Health = 5, Money = -500 },
				feedText = "You're taking good care of yourself.",
			},
			{
				text = "Stay as active as possible",
				effects = { Health = 8, Happiness = 5 },
				feedText = "Movement is medicine!",
			},
			{
				text = "Accept limitations gracefully",
				effects = { Happiness = 3, Smarts = 2 },
				feedText = "You're adapting with wisdom.",
			},
			{
				text = "Fight against aging stubbornly",
				effects = { Happiness = {-5, 5}, Health = {-5, 5} },
				feedText = "You refuse to slow down!",
			},
		},
	},
}

return AdultEvents
