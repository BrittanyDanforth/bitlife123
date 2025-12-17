--[[
    Social Media & Online Events
    Events related to social media, internet, and digital life
    All events use randomized outcomes - NO god mode
]]

local SocialMediaEvents = {}

local STAGE = "random"

SocialMediaEvents.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SOCIAL MEDIA CONTENT
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "social_viral_post",
		title = "Viral Post Opportunity",
		emoji = "📱",
		text = "One of your posts is gaining traction!",
		question = "How does the post perform?",
		minAge = 13, maxAge = 80,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "social_media",
		tags = { "viral", "social_media", "fame" },
		
		-- CRITICAL: Random viral post outcome
		choices = {
			{
				text = "Watch it blow up",
				effects = {},
				feedText = "Notifications exploding...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.20 then
						state:ModifyStat("Happiness", 15)
						state.Money = (state.Money or 0) + 500
						state.Flags = state.Flags or {}
						state.Flags.went_viral = true
						state:AddFeed("📱 MEGA VIRAL! Millions of views! Brand deals incoming!")
					elseif roll < 0.45 then
						state:ModifyStat("Happiness", 10)
						state.Money = (state.Money or 0) + 100
						state:AddFeed("📱 Trending! Thousands of new followers! Internet famous!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("📱 Decent engagement! More likes than usual!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("📱 False hope. Algorithm stopped pushing it.")
					end
				end,
			},
		},
	},
	{
		id = "social_content_creation",
		title = "Content Creation",
		emoji = "🎬",
		text = "Time to create some content!",
		question = "What do you post?",
		minAge = 13, maxAge = 70,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "social_media",
		tags = { "content", "creator", "social_media" },
		
		-- CRITICAL: Random content success
		choices = {
			{
				text = "Try making videos",
				effects = {},
				feedText = "Recording and editing...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.25 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.content_creator = true
						state:AddFeed("🎬 Video did well! Audience growing! Creator life!")
					elseif roll < 0.60 then
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("🎬 Learning the craft. Small but engaged audience!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🎬 Flopped. Low views. Algorithm is cruel.")
					end
				end,
			},
			{
				text = "Start streaming",
				effects = { Money = -50 },
				feedText = "Going live...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.20 then
						state:ModifyStat("Happiness", 12)
						state.Money = (state.Money or 0) + 200
						state.Flags = state.Flags or {}
						state.Flags.streamer = true
						state:AddFeed("🎬 Built a community! Donations rolling in! Streamer life!")
					elseif roll < 0.55 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🎬 Small but loyal viewers. Building something!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🎬 Talking to empty room. Streaming is hard.")
					end
				end,
			},
			{ text = "Share photos", effects = { Happiness = 5 }, feedText = "🎬 Posted some pics. Likes make you feel good!" },
		},
	},
	{
		id = "social_online_drama",
		title = "Online Drama",
		emoji = "💢",
		text = "You've been pulled into online drama!",
		question = "How do you handle it?",
		minAge = 13, maxAge = 70,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "social_media",
		tags = { "drama", "conflict", "social_media" },
		
		-- CRITICAL: Random drama outcome
		choices = {
			{
				text = "Engage and defend yourself",
				effects = {},
				feedText = "Clapping back...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.30 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("💢 Won the argument! Public opinion on your side!")
					elseif roll < 0.60 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("💢 Stalemate. Both sides look bad. Exhausting.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.cancelled = true
						state:AddFeed("💢 CANCELLED! Pile-on was brutal. Reputation damaged.")
					end
				end,
			},
			{ text = "Stay silent, let it blow over", effects = { Happiness = 2, Smarts = 2 }, feedText = "💢 Didn't engage. Storm passed. Wisdom." },
			{ text = "Delete social media temporarily", effects = { Happiness = 4, Health = 2 }, setFlags = { social_media_break = true }, feedText = "💢 Taking a break from toxic internet. Mental health first." },
		},
	},
	{
		id = "social_influencer_deal",
		title = "Influencer Opportunity",
		emoji = "💰",
		text = "A brand wants to work with you!",
		question = "Do you take the sponsorship?",
		minAge = 16, maxAge = 60,
		baseChance = 0.1,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "social_media",
		tags = { "influencer", "brand", "money" },
		
		eligibility = function(state)
			local hasAudience = state.Flags and (state.Flags.content_creator or state.Flags.streamer or state.Flags.went_viral)
			if not hasAudience then
				return false, "Need social media following for brand deals"
			end
			return true
		end,
		
		-- CRITICAL: Random brand deal outcome
		choices = {
			{
				text = "Take the deal",
				effects = {},
				feedText = "Working with the brand...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.influencer = true
						state:AddFeed("💰 Easy money! Brand happy, followers happy!")
					elseif roll < 0.80 then
						state.Money = (state.Money or 0) + 200
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💰 Decent pay. Some followers criticized the sellout.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("💰 Brand deal was scammy. Didn't pay properly. Lesson learned.")
					end
				end,
			},
			{ text = "Decline - not the right fit", effects = { Happiness = 2, Smarts = 2 }, feedText = "💰 Kept authenticity. Followers respect that." },
		},
	},
	{
		id = "social_dating_apps",
		title = "Dating App Experience",
		emoji = "💕",
		text = "Using dating apps!",
		question = "How's the dating app scene?",
		minAge = 18, maxAge = 70,
		baseChance = 0.455,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "dating",
		tags = { "dating", "apps", "romance" },
		requiresSingle = true,
		blockedByFlags = { in_prison = true, incarcerated = true }, -- CRITICAL FIX #331: No dating apps from prison
		
		-- CRITICAL: Random dating app outcome
		choices = {
			{
				text = "Swipe and match",
				effects = {},
				feedText = "Swiping through profiles...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local matchChance = 0.25 + (looks / 200)
					
					if roll < matchChance then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.dating_app_match = true
						state:AddFeed("💕 MATCH! Great conversation! Date planned!")
					elseif roll < (matchChance * 2) then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💕 Some matches! Conversations fizzled but trying!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("💕 Ghosted again. Dating apps are brutal.")
					else
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.catfished = true
						state:AddFeed("💕 Got catfished! Profile was fake! Trust issues rising.")
					end
				end,
			},
			{ text = "Delete the apps", effects = { Happiness = 3, Health = 1 }, setFlags = { deleted_dating_apps = true }, feedText = "💕 Done with swiping. Real life connections instead." },
		},
	},
	{
		id = "social_online_friend",
		title = "Online Friendship",
		emoji = "👥",
		text = "You've connected with someone online!",
		question = "How does the online friendship develop?",
		minAge = 12, maxAge = 80,
		baseChance = 0.45,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "social",
		tags = { "friendship", "online", "connection" },
		
		-- CRITICAL: Random online friendship outcome
		choices = {
			{
				text = "Build the friendship",
				effects = {},
				feedText = "Getting to know them online...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.online_friend = true
						state:AddFeed("👥 Real connection! True friend even if only online!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("👥 Good chat buddy. Casual but nice to have.")
					else
						state:ModifyStat("Happiness", -3)
						state.Flags = state.Flags or {}
						state.Flags.online_scam_attempt = true
						state:AddFeed("👥 Something felt off. They wanted money. Scam avoided.")
					end
				end,
			},
			{ text = "Meet in person", effects = { Money = -50 }, feedText = "Meeting your online friend IRL...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.65 then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.met_online_friend = true
						state:AddFeed("👥 Even better in person! Real friendship confirmed!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("👥 Awkward in person. Online chemistry didn't translate.")
					end
				end,
			},
		},
	},
	{
		id = "social_online_shopping",
		title = "Online Shopping Spree",
		emoji = "🛒",
		text = "The urge to online shop is strong!",
		question = "Do you resist?",
		minAge = 16, maxAge = 90,
		baseChance = 0.55,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "shopping",
		tags = { "shopping", "online", "spending" },
		
		eligibility = function(state)
			local money = state.Money or 0
			if money < 50 then
				return false, "Need money to shop"
			end
			return true
		end,
		
		-- CRITICAL: Random shopping outcome
		choices = {
			{
				-- CRITICAL FIX: Show price and add per-choice eligibility check
				text = "Buy all the things ($200)",
				effects = { Money = -200 },
				feedText = "Click, click, checkout...",
				eligibility = function(state)
					if (state.Money or 0) < 200 then
						return false, "Can't afford $200 shopping spree"
					end
					return true
				end,
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("🛒 Great haul! Love everything! Worth it!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🛒 Some hits, some misses. Returns needed.")
					else
						state:ModifyStat("Happiness", -4)
						state.Flags = state.Flags or {}
						state.Flags.shopping_regret = true
						state:AddFeed("🛒 Buyer's remorse. What did I need this for?")
					end
				end,
			},
			{ text = "Add to cart but don't checkout", effects = { Happiness = 4, Smarts = 2 }, feedText = "🛒 Filled cart. Closed tab. Self-control win!" },
			{ text = "Treat yourself responsibly", effects = { Money = -50, Happiness = 5 }, feedText = "🛒 One nice thing. Budget maintained. Balance." },
		},
	},
	{
		id = "social_online_learning",
		title = "Online Learning",
		emoji = "💻",
		text = "Found an interesting online course!",
		question = "Do you take the course?",
		minAge = 14, maxAge = 90,
		baseChance = 0.45,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "education",
		tags = { "learning", "online", "skills" },
		
		-- CRITICAL: Random learning outcome
		choices = {
			{
				text = "Enroll and commit",
				effects = { Money = -50 },
				feedText = "Taking the course...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					
					if roll < 0.50 then
						state:ModifyStat("Smarts", 6)
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.online_learner = true
						state:AddFeed("💻 Course complete! New skills acquired! Certificate earned!")
					elseif roll < 0.80 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("💻 Made it halfway. Learned some stuff.")
					else
						state:ModifyStat("Happiness", -2)
						state.Flags = state.Flags or {}
						state.Flags.course_abandoned = true
						state:AddFeed("💻 Started strong. Life got busy. Abandoned course.")
					end
				end,
			},
			{ text = "Free resources instead", effects = { Smarts = 4, Happiness = 4 }, feedText = "💻 YouTube tutorials for the win! Free education!" },
			{ text = "Save it for later", effects = { Happiness = 1 }, setFlags = { course_bookmarked = true }, feedText = "💻 Bookmarked. Will definitely do it. (Probably won't.)" },
		},
	},
	{
		id = "social_cybersecurity_issue",
		title = "Cybersecurity Alert",
		emoji = "🔐",
		text = "There's a security issue with your accounts!",
		question = "What happened?",
		minAge = 13, maxAge = 90,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "security",
		tags = { "security", "hacking", "online" },
		
		-- CRITICAL: Random security outcome
		choices = {
			{
				text = "Deal with the breach",
				effects = {},
				feedText = "Assessing the damage...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", -3)
						state:AddFeed("🔐 Password leaked in a breach. Changed everything. Annoying.")
					elseif roll < 0.60 then
						state:ModifyStat("Happiness", -6)
						state.Flags = state.Flags or {}
						state.Flags.account_hacked = true
						state:AddFeed("🔐 Account hacked! Had to recover. Stressful but recovered.")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", -8)
						state.Money = (state.Money or 0) - 200
						state:AddFeed("🔐 Unauthorized purchases! Disputed but lost some money!")
					else
						state:ModifyStat("Happiness", -12)
						state.Money = (state.Money or 0) - 1000
						state.Flags = state.Flags or {}
						state.Flags.identity_stolen = true
						state:AddFeed("🔐 IDENTITY THEFT! Major damage. Long recovery ahead.")
					end
				end,
			},
		},
	},
	{
		id = "social_review_drama",
		title = "Review Situation",
		emoji = "⭐",
		text = "Review drama is happening!",
		question = "What's the review situation?",
		minAge = 18, maxAge = 90,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "consumer",
		tags = { "reviews", "consumer", "online" },
		
		choices = {
			{
				text = "Leave an honest review",
				effects = {},
				feedText = "Writing your review...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("⭐ Good review for good service! Karma points!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 3)
						state:AddFeed("⭐ Negative but fair review. They needed the feedback.")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("⭐ Business owner responded angrily. Review drama.")
					end
				end,
			},
			{ text = "Got a fake bad review", effects = { Happiness = -5 }, feedText = "⭐ Someone left fake review on YOUR business/profile. Frustrating!" },
			{ text = "Manipulate reviews", effects = { Happiness = 2 }, setFlags = { fake_reviews = true }, feedText = "⭐ Left fake reviews. Ethically gray but whatever." },
		},
	},
	{
		id = "social_digital_detox",
		title = "Digital Detox",
		emoji = "🌿",
		text = "Considering a digital detox!",
		question = "Can you survive without screens?",
		minAge = 10, maxAge = 80,
		baseChance = 0.4,
		cooldown = 2,
		stage = STAGE,
		ageBand = "any",
		category = "wellness",
		tags = { "detox", "digital", "wellness" },
		
		-- CRITICAL: Random detox outcome
		choices = {
			{
				text = "Full week detox",
				effects = {},
				feedText = "Putting down all devices...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Health", 5)
						state:ModifyStat("Smarts", 3)
						state.Flags = state.Flags or {}
						state.Flags.completed_detox = true
						state:AddFeed("🌿 SURVIVED! So refreshed! New perspective! Changed!")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", 6)
						state:ModifyStat("Health", 3)
						state:AddFeed("🌿 Made it most of the week. Slipped up but beneficial!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🌿 Lasted 2 days. FOMO won. Maybe next time.")
					end
				end,
			},
			{ text = "Just reduce screen time", effects = { Happiness = 4, Health = 2 }, feedText = "🌿 Set limits. More sustainable. Small wins." },
			{ text = "Can't do it", effects = { Happiness = 1 }, feedText = "🌿 Life is too connected. Can't unplug fully." },
		},
	},
	{
		id = "social_meme_culture",
		title = "Meme Moment",
		emoji = "😂",
		text = "Something meme-worthy happened!",
		question = "What's the meme situation?",
		minAge = 13, maxAge = 60,
		baseChance = 0.45,
		cooldown = 3,
		stage = STAGE,
		ageBand = "any",
		category = "entertainment",
		tags = { "memes", "funny", "culture" },
		
		choices = {
			{ text = "You became a meme", effects = {}, feedText = "Your face/moment going viral...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 8)
						state:AddFeed("😂 Funny meme fame! People love it! 15 min of fame!")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("😂 Became a meme but not in a good way. Cringe.")
					end
				end,
			},
			{ text = "Made a viral meme", effects = { Happiness = 10 }, setFlags = { meme_creator = true }, feedText = "😂 Created viral meme! Internet credits earned!" },
			{ text = "Deep into meme hole", effects = { Happiness = 5, Smarts = -1 }, feedText = "😂 Spent hours looking at memes. Unproductive but fun." },
		},
	},
}

return SocialMediaEvents
