--[[
    Teen Expanded Events (Ages 13-17)
    100+ additional teen events with deep, realistic scenarios
    All events use randomized outcomes - NO god mode
]]

local TeenExpanded = {}

local STAGE = "teen"

TeenExpanded.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- SOCIAL & IDENTITY (Ages 13-17)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_identity_crisis",
		title = "Who Am I?",
		emoji = "🪞",
		text = "You're questioning everything about yourself - your identity, beliefs, who you want to be.",
		question = "How do you handle the identity crisis?",
		minAge = 14, maxAge = 17,
		oneTime = true,
		stage = STAGE,
		ageBand = "teen",
		category = "psychology",
		tags = { "identity", "growing_up", "self_discovery" },
		
		choices = {
			{
				text = "Experiment with different styles/personas",
				effects = { Happiness = 2, Looks = 2 },
				setFlags = { exploring_identity = true },
				feedText = "Every week a new look, new music, new you. Finding yourself.",
			},
			{
				text = "Stick with what feels comfortable",
				effects = { Happiness = 3, Smarts = 1 },
				setFlags = { knows_self = true },
				feedText = "You know who you are. That's rare at this age.",
			},
			{
				text = "Feel lost and confused",
				effects = { Happiness = -5 },
				setFlags = { identity_struggle = true },
				feedText = "Everyone seems to have it figured out except you.",
			},
			{
				text = "Talk to someone about it",
				effects = { Happiness = 4, Smarts = 2 },
				feedText = "Opening up helps. You're not alone in this.",
			},
		},
	},
	{
		id = "teen_friend_group_change",
		title = "Friend Group Drama",
		emoji = "👥",
		text = "Your friend group is fracturing. Alliances are shifting.",
		question = "What happens to your social circle?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "social",
		tags = { "friends", "drama", "social" },
		
		choices = {
			{
				text = "Stuck in the middle",
				effects = { Happiness = -6 },
				setFlags = { caught_in_middle = true },
				feedText = "Both sides want you to choose. Impossible position.",
			},
			{
				text = "Stay loyal to original friends",
				effects = { Happiness = 2 },
				setFlags = { loyal_friend = true },
				feedText = "You know who your real friends are.",
			},
			{
				text = "Find a whole new friend group",
				effects = {},
				feedText = "Time for a fresh start...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 6)
						state.Flags = state.Flags or {}
						state.Flags.new_friends = true
						state:AddFeed("👥 New friends are even better! Fresh start worked!")
					else
						state:ModifyStat("Happiness", -3)
						state:AddFeed("👥 Hard to break into new groups. Lonely period.")
					end
				end,
			},
			{
				text = "Prefer being alone anyway",
				effects = { Happiness = -2, Smarts = 3 },
				setFlags = { loner_teen = true },
				feedText = "Less drama when you're solo. Peaceful but lonely.",
			},
		},
	},
	{
		id = "teen_popularity_contest",
		title = "The Popularity Game",
		emoji = "👑",
		text = "High school is a popularity contest. Where do you rank?",
		question = "What's your social standing?",
		minAge = 14, maxAge = 17,
		oneTime = true,
		stage = STAGE,
		ageBand = "teen",
		category = "social",
		tags = { "popularity", "social", "high_school" },
		
		choices = {
			{
				text = "Rising in popularity",
				effects = {},
				feedText = "You're gaining social status...",
				onResolve = function(state)
					local looks = (state.Stats and state.Stats.Looks) or 50
					local roll = math.random()
					local successChance = 0.35 + (looks / 150)
					if roll < successChance then
						state:ModifyStat("Happiness", 8)
						state:ModifyStat("Looks", 2)
						state.Flags = state.Flags or {}
						state.Flags.popular_teen = true
						state:AddFeed("👑 You're IN! Popular crowd accepts you!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("👑 Middle tier. Not unpopular, not popular. Neutral.")
					end
				end,
			},
			{
				text = "Don't care about popularity",
				effects = { Happiness = 4, Smarts = 2 },
				setFlags = { above_popularity = true },
				feedText = "That game is stupid. You have real friends.",
			},
			{
				text = "Social outcast",
				effects = { Happiness = -6 },
				setFlags = { unpopular = true },
				feedText = "Bottom of the social ladder. It hurts.",
			},
			{
				text = "Popular for the wrong reasons",
				effects = { Happiness = 3, Looks = 2 },
				setFlags = { fake_popular = true },
				feedText = "People like you for superficial reasons. Is it real?",
			},
		},
	},
	{
		id = "teen_clique_pressure",
		title = "Clique Pressure",
		emoji = "🔒",
		text = "Your clique wants you to do something to prove your loyalty.",
		question = "What do they want you to do?",
		minAge = 14, maxAge = 17,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "social",
		tags = { "peer_pressure", "clique", "choices" },
		
		choices = {
			{
				text = "Spread a rumor about someone",
				effects = {},
				feedText = "They want you to start gossip...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", -2)
						state.Flags = state.Flags or {}
						state.Flags.spread_rumors = true
						state:AddFeed("🔒 You did it. Feel gross but still in the group.")
					else
						state:ModifyStat("Happiness", -6)
						state:AddFeed("🔒 It backfired. You're the villain now.")
					end
				end,
			},
			{
				text = "Ditch someone publicly",
				effects = { Happiness = -4 },
				setFlags = { ditched_friend = true },
				feedText = "You publicly embarrassed someone to prove loyalty. Cruel.",
			},
			{
				text = "Refuse and face consequences",
				effects = { Happiness = -5 },
				setFlags = { stood_ground = true },
				feedText = "You said no. They might kick you out.",
			},
			{
				text = "Make an excuse to avoid it",
				effects = { Smarts = 2 },
				feedText = "Clever excuse avoided the situation. For now.",
			},
		},
	},
	{
		id = "teen_online_life",
		title = "Online Life vs Real Life",
		emoji = "📱",
		text = "Your online presence and real life feel like two different worlds.",
		question = "How's your digital life?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "technology",
		tags = { "social_media", "online", "identity" },
		
		choices = {
			{
				text = "Curated perfect online image",
				effects = { Happiness = -2, Looks = 3 },
				setFlags = { online_perfectionist = true },
				feedText = "Your profile is flawless. Real life doesn't match.",
			},
			{
				text = "Authentic and real online",
				effects = { Happiness = 4 },
				setFlags = { authentic_online = true },
				feedText = "What you see is what you get. No fakeness.",
			},
			{
				text = "Barely use social media",
				effects = { Happiness = 2, Smarts = 2 },
				setFlags = { minimal_social_media = true },
				feedText = "Missing out? Or saving yourself? You don't care.",
			},
			{
				text = "Addicted - can't put phone down",
				effects = { Happiness = -3, Health = -2, Smarts = -2 },
				setFlags = { phone_addiction = true },
				feedText = "Screen time is HOURS. Parents are worried.",
			},
		},
	},
	{
		-- CRITICAL FIX: Renamed from "teen_viral_moment" to avoid duplicate ID with Teen.lua
		id = "teen_viral_post",
		title = "Going Viral",
		emoji = "🔥",
		text = "Something you posted went viral!",
		question = "What kind of viral?",
		minAge = 13, maxAge = 17,
		baseChance = 0.1,
		cooldown = 6,
		stage = STAGE,
		ageBand = "teen",
		category = "technology",
		tags = { "viral", "fame", "social_media" },
		
		-- ═══════════════════════════════════════════════════════════════════════════════
		-- CRITICAL FIX #602: Viral events REQUIRE player to have actually posted content!
		-- User complaint: "Video went viral but I never posted any videos"
		-- ═══════════════════════════════════════════════════════════════════════════════
		eligibility = function(state)
			local flags = state.Flags or {}
			-- Player MUST have some form of social media/content activity!
			local hasPostedContent = flags.content_creator or flags.streamer or flags.influencer
				or flags.first_video_posted or flags.first_video_uploaded or flags.youtube_started
				or flags.social_media_active or flags.pursuing_streaming or flags.youtube_channel
				or flags.gaming_content or flags.vlogger or flags.social_media_star
			if not hasPostedContent then
				return false, "Player hasn't posted content yet"
			end
			return true
		end,
		
		-- CRITICAL: Random viral outcome - not all fame is good
		choices = {
			{
				text = "Viral for something good",
				effects = {},
				feedText = "Millions of views...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 10)
						state:ModifyStat("Looks", 3)
						state.Flags = state.Flags or {}
						state.Flags.internet_famous = true
						state:AddFeed("🔥 You're FAMOUS! Everyone knows you! This is amazing!")
					else
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🔥 Viral fame faded fast. 15 minutes of fame are over.")
					end
				end,
			},
			{
				text = "Viral for something embarrassing",
				effects = { Happiness = -10 },
				setFlags = { viral_embarrassment = true },
				feedText = "EVERYONE saw it. You can never show your face again.",
			},
			{
				text = "Viral but getting hate",
				effects = { Happiness = -6 },
				setFlags = { viral_hate = true },
				feedText = "Famous but the comments are BRUTAL. Internet is cruel.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- ROMANTIC & RELATIONSHIPS (Ages 14-17)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_relationship_stages",
		title = "Relationship Status",
		emoji = "💕",
		text = "How's your love life going?",
		question = "What's your romantic situation?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "romance",
		tags = { "dating", "relationships", "love" },
		
		choices = {
			{
				text = "In a serious relationship",
				effects = { Happiness = 5 },
				setFlags = { teen_relationship = true },
				feedText = "You've found someone special. Teen love is intense!",
			},
			{
				text = "Single and not looking",
				effects = { Happiness = 3, Smarts = 2 },
				setFlags = { focused_single = true },
				feedText = "Relationships can wait. You have priorities.",
			},
			{
				text = "Crushing hard on someone",
				effects = { Happiness = 2 },
				setFlags = { teen_crush = true },
				feedText = "Can't stop thinking about them. It's all-consuming.",
			},
			{
				text = "Dating around casually",
				effects = { Happiness = 3, Looks = 1 },
				setFlags = { casual_dating = true },
				feedText = "Playing the field. Nothing too serious.",
			},
		},
	},
	{
		id = "teen_heartbreak",
		title = "First Heartbreak",
		emoji = "💔",
		text = "Your heart has been shattered into a million pieces.",
		question = "How do you cope with the pain?",
		minAge = 14, maxAge = 17,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "romance",
		tags = { "heartbreak", "breakup", "emotions" },
		
		choices = {
			{ text = "Cry for days", effects = { Happiness = -8, Health = -2 }, setFlags = { heartbroken = true }, feedText = "The pain is REAL. Everything hurts." },
			{ text = "Listen to sad music on repeat", effects = { Happiness = -5 }, feedText = "The playlist of pain. Every song is about them." },
			{ text = "Try to move on quickly", effects = { Happiness = -3, Smarts = 2 }, feedText = "Fake it til you make it. Pretending you're fine." },
			{ text = "Talk it out with friends", effects = { Happiness = -4 }, setFlags = { emotional_support = true }, feedText = "Friends help you through it. You're not alone." },
			{ text = "Use it as motivation", effects = { Happiness = 2, Smarts = 3, Health = 3 }, setFlags = { revenge_body = true }, feedText = "Their loss. Time for a glow-up!" },
		},
	},
	{
		id = "teen_prom_drama",
		title = "Prom Season",
		emoji = "💃",
		text = "Prom is coming up. The pressure is INTENSE.",
		question = "What's your prom situation?",
		minAge = 16, maxAge = 18,
		oneTime = true,
		stage = STAGE,
		ageBand = "teen",
		category = "events",
		tags = { "prom", "dance", "high_school" },
		
		-- CRITICAL: Random prom outcome
		choices = {
			{
				text = "Got asked by your crush!",
				effects = {},
				feedText = "Dream scenario...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Looks", 3)
						state.Flags = state.Flags or {}
						state.Flags.prom_success = true
						state:AddFeed("💃 BEST NIGHT EVER! Magical prom with your crush!")
					else
						state:ModifyStat("Happiness", 4)
						state:AddFeed("💃 Good night, but didn't live up to expectations.")
					end
				end,
			},
			{
				text = "Going with friends instead",
				effects = { Happiness = 6 },
				setFlags = { prom_with_friends = true },
				feedText = "Who needs a date? Friends make it better anyway!",
			},
			{
				text = "Rejected when asking someone",
				effects = { Happiness = -8 },
				setFlags = { prom_rejection = true },
				feedText = "They said no. In front of everyone. Devastating.",
			},
			{
				text = "Skipping prom entirely",
				effects = { Happiness = -2, Money = 200 },
				setFlags = { skipped_prom = true },
				feedText = "It's overrated anyway. Right? ...Right?",
			},
		},
	},
	{
		id = "teen_dating_app_secret",
		title = "Secret Dating App",
		emoji = "🔞",
		text = "You've been using a dating app you're probably too young for.",
		question = "What happens?",
		minAge = 15, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "romance",
		tags = { "dating", "app", "risky" },
		
		-- CRITICAL: Random outcome - risky behavior has consequences
		choices = {
			{
				text = "Parents found out",
				effects = { Happiness = -8 },
				setFlags = { dating_app_caught = true },
				feedText = "GROUNDED. Phone confiscated. The talk. Awful.",
			},
			{
				text = "Deleted it - felt unsafe",
				effects = { Happiness = 2, Smarts = 3 },
				setFlags = { made_smart_choice = true },
				feedText = "Good instincts. That wasn't safe.",
			},
			{
				text = "Met someone nice",
				effects = {},
				feedText = "You connected with someone...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🔞 Actually met a cool person your age. Got lucky.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🔞 They weren't who they claimed to be. Scary wake-up call.")
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- ACADEMIC & FUTURE PLANNING (Ages 14-17)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_academic_pressure",
		title = "Academic Pressure",
		emoji = "📚",
		text = "The pressure to get good grades is overwhelming.",
		question = "How are you handling the stress?",
		minAge = 14, maxAge = 17,
		baseChance = 0.5,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "academics",
		tags = { "grades", "stress", "school" },
		
		choices = {
			{ text = "Thriving under pressure", effects = { Smarts = 4, Happiness = -2, Health = -1 }, setFlags = { academic_pressure_thrives = true }, feedText = "Pressure makes diamonds. Grades are stellar." },
			{ text = "Crumbling under stress", effects = { Smarts = -2, Happiness = -6, Health = -3 }, setFlags = { academic_burnout = true }, feedText = "Can't handle it. Anxiety is through the roof." },
			{ text = "Found healthy balance", effects = { Smarts = 2, Happiness = 3, Health = 2 }, setFlags = { balanced_student = true }, feedText = "Work hard, rest hard. You've got this figured out." },
			{ text = "Given up caring", effects = { Smarts = -3, Happiness = 4 }, setFlags = { academic_apathy = true }, feedText = "Whatever. Grades don't define you. (But they might open doors...)" },
		},
	},
	{
		id = "teen_college_prep",
		title = "College Prep Chaos",
		emoji = "🎓",
		text = "College applications are approaching. Time to prepare.",
		question = "How's your college prep going?",
		minAge = 16, maxAge = 17,
		oneTime = true,
		stage = STAGE,
		ageBand = "teen",
		category = "academics",
		tags = { "college", "future", "applications" },
		
		choices = {
			{ 
				text = "Tutors, SAT prep, perfect applications ($500)", 
				effects = { Smarts = 5, Happiness = -3, Money = -500 }, 
				setFlags = { overachiever = true }, 
				feedText = "Every advantage possible. This is your life now.",
				eligibility = function(state) return (state.Money or 0) >= 500, "💸 Can't afford tutors/SAT prep ($500)" end,
			},
			{ text = "Doing your best without extra help", effects = { Smarts = 3, Happiness = 1 }, feedText = "Working hard with what you have. That's commendable." },
			{ text = "Considering trade school instead", effects = { Smarts = 2, Happiness = 3 }, setFlags = { trade_school_path = true }, hintCareer = "trades", feedText = "College isn't the only path. Skills matter." },
			{ text = "No idea what you want to do", effects = { Happiness = -4 }, setFlags = { undecided_future = true }, feedText = "Everyone else has a plan. You're lost." },
			{ text = "Taking a gap year", effects = { Happiness = 4 }, setFlags = { gap_year_planned = true }, feedText = "Time to figure things out. No rush." },
		},
	},
	{
		id = "teen_standardized_test",
		title = "The Big Test",
		emoji = "📝",
		text = "SAT/ACT day. Your future might depend on this score.",
		question = "How did you do?",
		minAge = 16, maxAge = 17,
		oneTime = true,
		stage = STAGE,
		ageBand = "teen",
		category = "academics",
		tags = { "test", "SAT", "college" },
		
		-- CRITICAL: Random test outcome based on Smarts
		choices = {
			{
				text = "Give it your all",
				effects = {},
				feedText = "Bubble sheet filled, pencil down...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.20 + (smarts / 125)
					if roll < successChance then
						state:ModifyStat("Smarts", 5)
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.perfect_sat = true
						state:AddFeed("📝 INCREDIBLE SCORE! Dream schools are possible!")
					elseif roll < successChance + 0.35 then
						state:ModifyStat("Smarts", 2)
						state:ModifyStat("Happiness", 4)
						state:AddFeed("📝 Good score! You're competitive for good schools.")
					else
						state:ModifyStat("Happiness", -5)
						state:AddFeed("📝 Lower than hoped. Maybe retake? Or different path?")
					end
				end,
			},
			{
				text = "Had a panic attack during the test",
				effects = { Happiness = -8, Smarts = -2 },
				setFlags = { test_anxiety = true },
				feedText = "Froze up. Couldn't focus. Disaster.",
			},
		},
	},
	{
		id = "teen_extracurricular_overload",
		title = "Overcommitted",
		emoji = "📋",
		text = "You've signed up for way too many activities.",
		question = "How do you handle the overload?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "activities",
		tags = { "activities", "stress", "schedule" },
		
		choices = {
			{ text = "Keep juggling everything", effects = { Smarts = 3, Health = -4, Happiness = -3 }, setFlags = { overscheduled = true }, feedText = "No free time EVER. Resume looks great though." },
			{ text = "Drop some activities", effects = { Happiness = 4, Smarts = 1 }, feedText = "Quality over quantity. You can breathe again." },
			{ text = "Have a breakdown", effects = { Happiness = -8, Health = -3 }, setFlags = { burnout = true }, feedText = "Everything came crashing down. Too much." },
			{ text = "Get better at time management", effects = { Smarts = 4, Happiness = 2 }, setFlags = { time_management = true }, feedText = "Learned to balance. Master scheduler now." },
		},
	},
	{
		id = "teen_scholarship_opportunity",
		title = "Scholarship Opportunity",
		emoji = "🎁",
		text = "There's a scholarship you could apply for!",
		question = "Do you go for it?",
		minAge = 16, maxAge = 17,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "academics",
		tags = { "scholarship", "college", "money" },
		
		-- CRITICAL: Random scholarship outcome
		choices = {
			{
				text = "Apply and give it everything",
				effects = {},
				feedText = "Hours on the application, perfect essay...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.15 + (smarts / 200)
					if roll < successChance then
						state.Money = (state.Money or 0) + 10000
						state:ModifyStat("Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.scholarship_winner = true
						state:AddFeed("🎁 YOU WON! $10,000 scholarship! Future secured!")
					elseif roll < 0.50 then
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🎁 Honorable mention! Not money, but looks good.")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("🎁 Didn't get it. All that work for nothing.")
					end
				end,
			},
			{
				text = "Don't bother - won't win anyway",
				effects = { Happiness = -2 },
				setFlags = { self_limiting = true },
				feedText = "You talked yourself out of trying.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- RISKY BEHAVIOR & CHOICES (Ages 14-17)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		-- CRITICAL FIX: Renamed from "teen_party_invitation" to avoid duplicate ID with Teen.lua
		id = "teen_risky_party_invite",
		title = "Party Invite",
		emoji = "🎉",
		text = "You're invited to a party where there might be... things.",
		question = "What do you do?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "social",
		tags = { "party", "peer_pressure", "choices" },
		
		-- CRITICAL: Random party outcome
		choices = {
			{
				text = "Go and stay responsible",
				effects = {},
				feedText = "You went to the party...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Happiness", 6)
						state:AddFeed("🎉 Great night! Danced, had fun, stayed smart!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🎉 Kinda boring actually. Left early.")
					end
				end,
			},
			{
				text = "Go and get pressured into stuff",
				effects = {},
				feedText = "The pressure was intense...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 4)
						state:ModifyStat("Health", -3)
						state:AddFeed("🎉 Did some things you regret. Nothing too bad.")
					else
						state:ModifyStat("Happiness", -5)
						state:ModifyStat("Health", -5)
						state.Flags = state.Flags or {}
						state.Flags.party_mistake = true
						state:AddFeed("🎉 Huge mistake. Ended up in trouble.")
					end
				end,
			},
			{
				text = "Skip it entirely",
				effects = { Happiness = -1, Smarts = 1 },
				feedText = "FOMO is real but you stayed home.",
			},
			{
				text = "Go but leave early",
				effects = { Happiness = 2 },
				feedText = "Showed your face, then bounced. Smart.",
			},
		},
	},
	{
		id = "teen_sneaking_out",
		title = "Sneaking Out",
		emoji = "🌙",
		text = "Your friends want you to sneak out tonight.",
		question = "Do you risk it?",
		minAge = 14, maxAge = 17,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "risky",
		tags = { "sneaking", "rules", "night" },
		
		-- CRITICAL: Random sneaking outcome
		choices = {
			{
				text = "Sneak out successfully",
				effects = {},
				feedText = "Out the window, into the night...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						state:ModifyStat("Happiness", 7)
						state.Flags = state.Flags or {}
						state.Flags.snuck_out_success = true
						state:AddFeed("🌙 Best night ever! And didn't get caught!")
					elseif roll < 0.80 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🌙 Fun night. Snuck back in without issues.")
					else
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.caught_sneaking = true
						state:AddFeed("🌙 CAUGHT! Parents were waiting up. SO grounded.")
					end
				end,
			},
			{
				text = "Decide it's not worth the risk",
				effects = { Happiness = -2, Smarts = 2 },
				feedText = "Stayed in bed. The responsible choice.",
			},
		},
	},
	{
		id = "teen_driving_reckless",
		title = "Reckless Driving",
		emoji = "🚗",
		text = "Friends want you to drive fast or recklessly.",
		question = "What do you do behind the wheel?",
		minAge = 16, maxAge = 17,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresFlags = { has_license = true },
		stage = STAGE,
		ageBand = "teen",
		category = "risky",
		tags = { "driving", "risk", "peer_pressure" },
		
		-- CRITICAL: Random driving outcome
		choices = {
			{
				text = "Drive responsibly despite pressure",
				effects = { Smarts = 3, Happiness = 1 },
				setFlags = { responsible_driver = true },
				feedText = "Your car, your rules. Safe driving.",
			},
			{
				text = "Give in and speed",
				effects = {},
				feedText = "Pedal to the metal...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🚗 Adrenaline rush! Got away with it.")
					elseif roll < 0.70 then
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 200)
						state:ModifyStat("Happiness", -5)
						state:AddFeed("🚗 SPEEDING TICKET! $200 fine. Parents furious.")
					else
						state:ModifyStat("Health", -15)
						state:ModifyStat("Happiness", -10)
						state.Flags = state.Flags or {}
						state.Flags.car_accident = true
						state:AddFeed("🚗 ACCIDENT! Everyone okay but car is totaled.")
					end
				end,
			},
			{
				text = "Let someone else drive",
				effects = { Happiness = 2 },
				feedText = "Handed over the keys. Not your responsibility.",
			},
		},
	},
	{
		id = "teen_shoplifting_dare",
		title = "Shoplifting Dare",
		emoji = "🏪",
		text = "Someone dares you to shoplift something small.",
		question = "What do you do?",
		minAge = 13, maxAge = 17,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "crime",
		tags = { "stealing", "dare", "risk" },
		
		-- CRITICAL: Random shoplifting outcome
		choices = {
			{
				text = "Refuse - not worth it",
				effects = { Smarts = 3, Happiness = 2 },
				setFlags = { resists_peer_pressure = true },
				feedText = "Hard no. Not risking your future for a dare.",
			},
			{
				text = "Take the dare",
				effects = {},
				feedText = "Heart pounding, you slip something in your pocket...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.35 then
						state:ModifyStat("Happiness", 2)
						state.Flags = state.Flags or {}
						state.Flags.shoplifted = true
						state:AddFeed("🏪 Got away with it. Adrenaline and guilt mix.")
					elseif roll < 0.70 then
						state:ModifyStat("Happiness", -8)
						state.Flags = state.Flags or {}
						state.Flags.caught_shoplifting = true
						state:AddFeed("🏪 CAUGHT! Security grabbed you. Parents called.")
					else
						state:ModifyStat("Happiness", -12)
						state.Flags = state.Flags or {}
						state.Flags.juvenile_record = true
						state:AddFeed("🏪 ARRESTED! Juvenile record. Life-changing mistake.")
					end
				end,
			},
			{
				text = "Walk away from those 'friends'",
				effects = { Happiness = 3 },
				setFlags = { ditched_bad_influence = true },
				feedText = "Real friends don't dare you to commit crimes.",
			},
		},
	},
	{
		id = "teen_substance_pressure",
		title = "Substance Pressure",
		emoji = "🚬",
		text = "Someone offers you something you know you shouldn't have.",
		question = "How do you handle the pressure?",
		minAge = 14, maxAge = 17,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "risky",
		tags = { "substances", "alcohol", "peer_pressure" },
		
		choices = {
			{
				text = "Firmly decline",
				effects = { Smarts = 3, Health = 2, Happiness = 2 },
				setFlags = { substance_free = true },
				feedText = "No thanks. You know what's right for you.",
			},
			{
				text = "Try it once",
				effects = {},
				feedText = "Just once can't hurt... right?",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.40 then
						state:ModifyStat("Happiness", 3)
						state:ModifyStat("Health", -2)
						state:AddFeed("🚬 Tried it. Meh. Not for you.")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Health", -5)
						state.Flags = state.Flags or {}
						state.Flags.experimented = true
						state:AddFeed("🚬 Bad experience. Learned your lesson the hard way.")
					else
						state:ModifyStat("Happiness", -8)
						state:ModifyStat("Health", -8)
						state.Flags = state.Flags or {}
						state.Flags.substance_issue = true
						state:AddFeed("🚬 This opened a door that's hard to close.")
					end
				end,
			},
			{
				text = "Make an excuse to leave",
				effects = { Smarts = 2 },
				feedText = "Gotta go... anywhere else. Avoided the situation.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- MENTAL HEALTH & PERSONAL GROWTH (Ages 13-17)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_anxiety_episode",
		title = "Anxiety Attack",
		emoji = "😰",
		text = "Your heart is racing, you can't breathe, everything feels wrong.",
		question = "How do you cope with anxiety?",
		minAge = 13, maxAge = 17,
		baseChance = 0.555,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "mental_health",
		tags = { "anxiety", "mental_health", "stress" },
		
		choices = {
			{ text = "Learn coping techniques", effects = { Smarts = 3, Happiness = 2, Health = 2 }, setFlags = { anxiety_coping = true }, feedText = "Deep breaths, grounding exercises. You're learning to manage." },
			{ text = "Suffer in silence", effects = { Happiness = -6, Health = -3 }, setFlags = { hidden_anxiety = true }, feedText = "No one knows you're struggling. That's lonely." },
			{ text = "Talk to a therapist", effects = { Happiness = 5, Smarts = 2 }, setFlags = { in_therapy = true }, feedText = "Getting professional help. That takes courage." },
			{ text = "Avoid everything that triggers it", effects = { Happiness = -2, Smarts = -2 }, setFlags = { avoidant = true }, feedText = "Can't trigger anxiety if you never do anything. Right?" },
		},
	},
	{
		id = "teen_depression_warning",
		title = "Dark Days",
		emoji = "🌧️",
		text = "Nothing feels good anymore. Everything is gray.",
		question = "How do you handle these feelings?",
		minAge = 13, maxAge = 17,
		baseChance = 0.455,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "mental_health",
		tags = { "depression", "mental_health", "support" },
		
		choices = {
			{ text = "Reach out for help", effects = { Happiness = 5, Health = 3 }, setFlags = { seeking_help = true }, feedText = "You told someone. That's the hardest and bravest first step." },
			{ text = "Try to push through alone", effects = { Happiness = -4, Health = -2 }, feedText = "Going through the motions. Empty inside." },
			{ text = "Find solace in a hobby", effects = { Happiness = 3, Smarts = 2 }, setFlags = { coping_hobby = true }, feedText = "Music, art, games - something that makes you feel." },
			{ text = "Withdraw from everyone", effects = { Happiness = -6 }, setFlags = { withdrawn = true }, feedText = "Cutting yourself off from the world. It hurts." },
		},
	},
	{
		id = "teen_self_esteem_crisis",
		title = "Self-Esteem Crisis",
		emoji = "😔",
		text = "You hate everything about yourself right now.",
		question = "How do you deal with these feelings?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "mental_health",
		tags = { "self_esteem", "body_image", "identity" },
		
		choices = {
			{ text = "Compare yourself to others constantly", effects = { Happiness = -5, Looks = -2 }, setFlags = { comparison_trap = true }, feedText = "Everyone seems better. Social media makes it worse." },
			{ text = "Work on self-improvement", effects = { Happiness = 2, Health = 3, Looks = 2 }, setFlags = { self_improvement = true }, feedText = "Gym, skincare, skills - working on becoming better." },
			{ text = "Try to accept yourself as you are", effects = { Happiness = 4, Smarts = 2 }, setFlags = { self_acceptance = true }, feedText = "You're enough. Hard to believe but you're trying." },
			{ text = "Develop a hard exterior", effects = { Happiness = -2, Smarts = 1 }, setFlags = { tough_exterior = true }, feedText = "If you act like you don't care, it doesn't hurt. Mostly." },
		},
	},
	{
		id = "teen_therapy_decision",
		title = "Therapy Option",
		emoji = "🛋️",
		text = "Parents suggest you talk to a therapist.",
		question = "How do you feel about it?",
		minAge = 13, maxAge = 17,
		baseChance = 0.45,
		cooldown = 6,
		stage = STAGE,
		ageBand = "teen",
		category = "mental_health",
		tags = { "therapy", "help", "mental_health" },
		
		choices = {
			{ text = "Give it a try", effects = { Happiness = 4, Smarts = 3, Health = 2 }, setFlags = { therapy_positive = true }, feedText = "Actually helpful! Having someone to talk to is good." },
			{ text = "Refuse - don't need help", effects = { Happiness = -2 }, setFlags = { therapy_refused = true }, feedText = "Nothing wrong with you. Or so you tell yourself." },
			{ text = "Go but don't open up", effects = { Happiness = 1 }, feedText = "Attending but not really participating. Waste of time." },
			{ text = "Ask for it yourself", effects = { Happiness = 6, Smarts = 2 }, setFlags = { self_advocated_therapy = true }, feedText = "You recognized you needed help and asked. That's mature." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FAMILY DYNAMICS (Ages 13-17)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_parent_fight",
		title = "Parent Blowout",
		emoji = "💥",
		text = "You and your parent(s) had a massive fight.",
		question = "What was it about?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "family",
		tags = { "parents", "conflict", "family" },
		
		choices = {
			{ text = "Rules and restrictions", effects = { Happiness = -5 }, setFlags = { rebellious = true }, feedText = "They don't understand. They never will." },
			{ text = "Your grades or future", effects = { Happiness = -4, Smarts = 1 }, feedText = "Pressure, pressure, pressure. It's suffocating." },
			{ text = "Your friends or relationships", effects = { Happiness = -5 }, setFlags = { parents_disapprove_friends = true }, feedText = "They don't like your friends. But they're YOUR friends." },
			{ text = "Something you did wrong", effects = { Happiness = -6 }, feedText = "You messed up. They're disappointed. That hurts most." },
			{ text = "Made up quickly", effects = { Happiness = 2 }, feedText = "Blowout was brief. Apologies exchanged. Family." },
		},
	},
	{
		id = "teen_sibling_relationship_teen",
		title = "Sibling Dynamics",
		emoji = "👫",
		text = "Your relationship with your sibling is evolving.",
		question = "How are things with your sibling?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "family",
		tags = { "sibling", "family", "relationships" },
		-- CRITICAL FIX #13: Sibling events require having siblings!
		requiresFlags = { has_siblings = true },
		
		choices = {
			{ text = "Becoming real friends", effects = { Happiness = 6 }, setFlags = { sibling_friends = true }, feedText = "You actually like each other now. Who knew?" },
			{ text = "Constant rivalry and competition", effects = { Happiness = -3, Smarts = 1 }, setFlags = { sibling_rival = true }, feedText = "Everything is a competition. Exhausting." },
			{ text = "Growing apart", effects = { Happiness = -2 }, setFlags = { sibling_distant = true }, feedText = "Different interests, different lives. That's normal." },
			{ text = "Protecting them from stuff", effects = { Happiness = 3, Smarts = 1 }, setFlags = { protective_sibling = true }, feedText = "You shield them from what you've learned the hard way." },
		},
	},
	{
		id = "teen_family_secret",
		title = "Family Secret",
		emoji = "🤫",
		text = "You discovered a secret about your family.",
		question = "What did you find out?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 6,
		oneTime = true,
		stage = STAGE,
		ageBand = "teen",
		category = "family",
		tags = { "secret", "family", "drama" },
		
		choices = {
			{ text = "Financial problems they hid", effects = { Happiness = -5, Smarts = 2 }, setFlags = { knows_money_problems = true }, feedText = "Things are worse than they let on. Scary." },
			{ text = "A relative's hidden past", effects = { Happiness = -2, Smarts = 2 }, setFlags = { family_secret_revealed = true }, feedText = "Everyone has secrets. Even family." },
			{ text = "Parents considering divorce", effects = { Happiness = -10 }, setFlags = { divorce_pending = true }, feedText = "The whispered arguments make sense now. World shaking." },
			{ text = "You were adopted", effects = { Happiness = -5, Smarts = 2 }, setFlags = { discovered_adoption = true }, feedText = "Everything you knew feels different now." },
		},
	},
	{
		id = "teen_family_move",
		title = "Family Moving",
		emoji = "📦",
		text = "Your family is moving to a new place.",
		question = "How do you handle the move?",
		minAge = 13, maxAge = 17,
		oneTime = true,
		baseChance = 0.4,
		stage = STAGE,
		ageBand = "teen",
		category = "family",
		tags = { "moving", "change", "school" },
		
		choices = {
			{
				text = "Fresh start - embrace it",
				effects = {},
				feedText = "New city, new school, new you...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Happiness", 8)
						state.Flags = state.Flags or {}
						state.Flags.successful_move = true
						state:AddFeed("📦 Best thing that ever happened! New life is amazing!")
					else
						state:ModifyStat("Happiness", -4)
						state:AddFeed("📦 Optimistic but struggling to fit in. It's hard.")
					end
				end,
			},
			{
				text = "Fight it desperately",
				effects = { Happiness = -6 },
				setFlags = { resents_move = true },
				feedText = "This is ruining your life. You'll never forgive them.",
			},
			{
				text = "Try long-distance with friends",
				effects = { Happiness = -2 },
				feedText = "Texting and video calls aren't the same. But you try.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- HOBBIES & INTERESTS (Ages 13-17)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_sports_tryouts",
		title = "Sports Tryouts",
		emoji = "⚽",
		text = "Tryouts for a sports team are happening.",
		question = "How do tryouts go?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "sports",
		tags = { "sports", "team", "competition" },
		
		-- CRITICAL: Random tryout outcome based on Health
		choices = {
			{
				text = "Try your absolute hardest",
				effects = {},
				feedText = "You gave everything you had...",
				onResolve = function(state)
					local health = (state.Stats and state.Stats.Health) or 50
					local roll = math.random()
					local successChance = 0.25 + (health / 150)
					if roll < successChance then
						state:ModifyStat("Health", 5)
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.made_sports_team = true
						state:AddFeed("⚽ YOU MADE THE TEAM! Hard work paid off!")
					elseif roll < successChance + 0.25 then
						state:ModifyStat("Health", 2)
						state:ModifyStat("Happiness", 4)
						state:AddFeed("⚽ Made JV! Not varsity but still on a team!")
					else
						state:ModifyStat("Happiness", -6)
						state:ModifyStat("Health", 1)
						state:AddFeed("⚽ Cut. Didn't make it. Crushing disappointment.")
					end
				end,
			},
			{
				text = "Don't try out - too risky",
				effects = { Happiness = -3 },
				setFlags = { avoided_tryouts = true },
				feedText = "Can't fail if you don't try. But you'll always wonder.",
			},
		},
	},
	{
		id = "teen_artistic_expression",
		title = "Artistic Journey",
		emoji = "🎨",
		text = "Your artistic side is developing!",
		question = "What's your artistic outlet?",
		minAge = 13, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "creativity",
		tags = { "art", "creativity", "expression" },
		careerTags = { "creative" },
		
		choices = {
			{ text = "Digital art and design", effects = { Smarts = 3, Happiness = 4 }, setFlags = { digital_artist = true }, hintCareer = "creative", feedText = "Tablet and software. Creating digital masterpieces." },
			{ text = "Music - learning instrument", effects = { Smarts = 2, Happiness = 5 }, setFlags = { teen_musician = true }, hintCareer = "creative", feedText = "Hours of practice. Getting really good." },
			{ text = "Writing stories or poetry", effects = { Smarts = 4, Happiness = 3 }, setFlags = { teen_writer = true }, hintCareer = "creative", feedText = "Words are your canvas. Creating worlds." },
			{ text = "Photography", effects = { Smarts = 2, Happiness = 4, Looks = 1 }, setFlags = { photographer = true }, hintCareer = "creative", feedText = "Capturing moments. Seeing the world differently." },
			{ text = "Theater and drama", effects = { Happiness = 5, Looks = 2 }, setFlags = { theater_kid = true }, hintCareer = "creative", feedText = "The stage is your home. Born performer!" },
		},
	},
	{
		id = "teen_gaming_serious",
		title = "Competitive Gaming",
		emoji = "🎮",
		text = "You're getting serious about competitive gaming.",
		question = "How far do you take it?",
		minAge = 13, maxAge = 17,
		baseChance = 0.555,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "hobbies",
		tags = { "gaming", "competition", "esports" },
		careerTags = { "esports" },
		
		choices = {
			{
				text = "Try esports tournaments",
				effects = {},
				feedText = "Competing against the best...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					if roll < 0.20 then
						state.Money = (state.Money or 0) + 500
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.esports_winner = true
						state:AddFeed("🎮 WON PRIZE MONEY! $500! You're actually good!")
					elseif roll < 0.50 then
						state:ModifyStat("Happiness", 4)
						state:AddFeed("🎮 Decent placement! You can compete at this level!")
					else
						state:ModifyStat("Happiness", -2)
						state:AddFeed("🎮 Got destroyed. These pros are on another level.")
					end
				end,
			},
			{
				text = "Stream on Twitch/YouTube",
				effects = {},
				feedText = "Live streaming your gameplay...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.15 then
						state:ModifyStat("Happiness", 8)
						state.Money = (state.Money or 0) + 200
						state.Flags = state.Flags or {}
						state.Flags.streamer = true
						state:AddFeed("🎮 Building a following! People watch you! Making a little money!")
					else
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🎮 Streaming to 3 viewers. Mostly bots. It's a start?")
					end
				end,
			},
			{
				text = "Keep it casual",
				effects = { Happiness = 3 },
				feedText = "Gaming is fun. Doesn't need to be a career.",
			},
		},
	},
	{
		id = "teen_fitness_journey",
		title = "Fitness Journey",
		emoji = "💪",
		text = "You've started taking fitness seriously.",
		question = "How's your fitness journey going?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "health",
		tags = { "fitness", "gym", "health" },
		
		choices = {
			{
				text = "Consistent gym routine",
				effects = {},
				feedText = "Weeks of consistent work...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.60 then
						state:ModifyStat("Health", 8)
						state:ModifyStat("Looks", 4)
						state:ModifyStat("Happiness", 5)
						state.Flags = state.Flags or {}
						state.Flags.fitness_buff = true
						state:AddFeed("💪 RESULTS! Visible progress! Feeling amazing!")
					else
						state:ModifyStat("Health", 3)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("💪 Progress is slow but you're healthier.")
					end
				end,
			},
			{
				text = "Started but quit already",
				effects = { Health = 1, Happiness = -2 },
				setFlags = { gym_quitter = true },
				feedText = "New Year's resolution lasted 2 weeks. Classic.",
			},
			{
				text = "Obsessing over it unhealthily",
				effects = { Health = 3, Looks = 2, Happiness = -4 },
				setFlags = { fitness_obsessed = true },
				feedText = "Counting every calorie, hours at gym. It's consuming you.",
			},
		},
	},
	{
		id = "teen_reading_habit",
		title = "Book Phase",
		emoji = "📚",
		text = "You've discovered a love for reading!",
		question = "What are you reading?",
		minAge = 13, maxAge = 17,
		baseChance = 0.55,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "hobbies",
		tags = { "reading", "books", "learning" },
		
		choices = {
			{ text = "Fantasy/Sci-Fi series obsession", effects = { Smarts = 3, Happiness = 5 }, setFlags = { fantasy_reader = true }, feedText = "Lost in other worlds. The real world can wait." },
			{ text = "Self-improvement books", effects = { Smarts = 5, Happiness = 2 }, setFlags = { self_help_reader = true }, feedText = "Trying to optimize yourself. Very mature." },
			{ text = "Classics for school, loving them", effects = { Smarts = 6, Happiness = 3 }, setFlags = { literature_lover = true }, feedText = "Shakespeare makes sense! Literature is beautiful!" },
			{ text = "True crime and mysteries", effects = { Smarts = 4, Happiness = 3 }, setFlags = { mystery_reader = true }, feedText = "Solving crimes from your bedroom. Armchair detective." },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- WORK & MONEY (Ages 14-17)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_first_job_experience",
		title = "First Job Reality",
		emoji = "💼",
		text = "Your first job is teaching you about the real world.",
		question = "What's the job experience like?",
		minAge = 15, maxAge = 17,
		baseChance = 0.5,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		requiresJob = true,
		stage = STAGE,
		ageBand = "teen",
		category = "work",
		tags = { "job", "work", "money" },
		
		choices = {
			{ text = "Learning valuable skills", effects = { Smarts = 4, Happiness = 2, Money = 100 }, setFlags = { work_ethic = true }, feedText = "Responsibility, time management, customer service. Growing up." },
			{ text = "Hating every second", effects = { Happiness = -4, Money = 100 }, setFlags = { hates_work = true }, feedText = "This is what adult life is? No thanks." },
			{ text = "Made work friends", effects = { Happiness = 5, Money = 100 }, setFlags = { work_friends = true }, feedText = "Coworkers are actually cool! Makes it bearable." },
			{ text = "Getting exploited", effects = { Happiness = -5, Money = 50, Smarts = 2 }, setFlags = { exploited_worker = true }, feedText = "Overworked, underpaid. Welcome to capitalism." },
		},
	},
	{
		id = "teen_money_management",
		title = "Managing Money",
		emoji = "💰",
		text = "You're learning how to handle your own money.",
		question = "How are you with finances?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "money",
		tags = { "money", "saving", "spending" },
		careerTags = { "finance" },
		
		choices = {
			{ text = "Saving everything", effects = { Smarts = 3, Money = 200 }, setFlags = { teen_saver = true }, hintCareer = "finance", feedText = "Every dollar saved. Watching that balance grow." },
			{ text = "Spending it all immediately ($100)", effects = { Happiness = 4, Money = -100 }, setFlags = { teen_spender = true }, feedText = "Money burns a hole in your pocket. Broke but happy?", eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 to spend" end },
			{ text = "Investing with help from parents", effects = { Smarts = 5, Money = 100 }, setFlags = { young_investor = true }, hintCareer = "finance", feedText = "Learning about stocks and compound interest. Head start!" },
			{ text = "Don't really have money to manage", effects = { Happiness = -2 }, feedText = "What money? You're broke." },
		},
	},
	{
		id = "teen_entrepreneurship",
		title = "Teen Entrepreneur",
		emoji = "💡",
		text = "You have a business idea!",
		question = "What do you do with your idea?",
		minAge = 14, maxAge = 17,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "business",
		tags = { "business", "entrepreneur", "money" },
		
		-- CRITICAL: Random business outcome
		choices = {
			{
				text = "Actually try to start it",
				effects = {},
				feedText = "You put your idea into action...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.15 + (smarts / 200)
					if roll < successChance then
						state.Money = (state.Money or 0) + 1000
						state:ModifyStat("Smarts", 6)
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						state.Flags.teen_entrepreneur = true
						state:AddFeed("💡 IT WORKED! Making real money! Teen CEO!")
					elseif roll < 0.50 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("💡 Modest success. Not rich but learned a lot.")
					else
						-- CRITICAL FIX: Prevent negative money
						state.Money = math.max(0, (state.Money or 0) - 100)
						state:ModifyStat("Happiness", -3)
						state:ModifyStat("Smarts", 2)
						state:AddFeed("💡 Failed. Lost some money. But failure teaches.")
					end
				end,
			},
			{
				text = "Just a daydream - don't pursue it",
				effects = { Happiness = -1 },
				feedText = "Good idea. Never acted on it. What if?",
			},
			{
				text = "Research and plan for later",
				effects = { Smarts = 3 },
				setFlags = { business_planner = true },
				feedText = "Writing a business plan. Preparing for the future.",
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- LIFE SKILLS (Ages 14-17)
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_learning_drive",
		title = "Learning to Drive",
		emoji = "🚗",
		text = "Time to learn how to drive!",
		question = "How are driving lessons going?",
		minAge = 15, maxAge = 17,
		oneTime = true,
		stage = STAGE,
		ageBand = "teen",
		category = "skills",
		tags = { "driving", "license", "skills" },
		-- CRITICAL FIX: Block if already learned to drive from ANY of the 3 driving events!
		blockedByFlags = { 
			has_license = true, drivers_license = true, driver_license = true, 
			has_drivers_license = true, learned_driving = true, good_driver = true,
			driving_done = true, in_prison = true 
		},
		
		-- CRITICAL: Random driving test outcome
		choices = {
			{
				text = "Take the test",
				effects = {},
				feedText = "Parallel parking, three-point turn...",
				onResolve = function(state)
					local smarts = (state.Stats and state.Stats.Smarts) or 50
					local roll = math.random()
					local successChance = 0.50 + (smarts / 200)
					if roll < successChance then
						state:ModifyStat("Happiness", 10)
						state.Flags = state.Flags or {}
						-- CRITICAL FIX: Set ALL license flag variations for compatibility!
						state.Flags.has_license = true
						state.Flags.drivers_license = true
						state.Flags.driver_license = true
						state.Flags.has_drivers_license = true
						state.Flags.learned_driving = true
						state:AddFeed("🚗 PASSED! You have a LICENSE! FREEDOM!")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags = state.Flags or {}
						state.Flags.learned_driving = true -- Still mark as attempted
						state:AddFeed("🚗 Failed the test. Gotta try again. Embarrassing.")
					end
				end,
			},
			{
				text = "Too nervous - not ready yet",
				effects = { Happiness = -2 },
				feedText = "Anxiety about driving. Need more practice.",
			},
		},
	},
	{
		id = "teen_cooking_skills",
		title = "Cooking for Yourself",
		emoji = "🍳",
		text = "Time to learn to feed yourself!",
		question = "How are your cooking skills?",
		minAge = 14, maxAge = 17,
		baseChance = 0.4,
		cooldown = 3,
		stage = STAGE,
		ageBand = "teen",
		category = "skills",
		tags = { "cooking", "independence", "skills" },
		
		choices = {
			{
				text = "Learning and loving it",
				effects = {},
				feedText = "Following recipes, experimenting...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.55 then
						state:ModifyStat("Smarts", 3)
						state:ModifyStat("Happiness", 5)
						state:ModifyStat("Health", 2)
						state.Flags = state.Flags or {}
						state.Flags.good_cook = true
						state:AddFeed("🍳 You can cook! Real food! Not just microwave stuff!")
					else
						state:ModifyStat("Smarts", 1)
						state:ModifyStat("Happiness", 2)
						state:AddFeed("🍳 Basic skills. Won't starve but not a chef.")
					end
				end,
			},
		{
			text = "Survive on snacks and takeout ($50)",
			effects = { Health = -3, Happiness = 2, Money = -50 },
			setFlags = { cant_cook = true },
			feedText = "Who needs to cook? That's future you's problem.",
			eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 for takeout" end,
		},
		},
	},
	{
		id = "teen_laundry_disaster",
		title = "Laundry Lesson",
		emoji = "🧺",
		text = "You tried to do laundry by yourself!",
		question = "How did it go?",
		minAge = 14, maxAge = 17,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		stage = STAGE,
		ageBand = "teen",
		category = "skills",
		tags = { "laundry", "independence", "skills" },
		
		choices = {
			{ text = "Nailed it - clean clothes!", effects = { Smarts = 2, Happiness = 3 }, setFlags = { can_do_laundry = true }, feedText = "Whites with whites, colors with colors. You got this!" },
			{ text = "Turned everything pink", effects = { Happiness = -3, Looks = -1 }, feedText = "One red sock. ONE. Everything is pink now." },
			{ text = "Shrunk your favorite clothes", effects = { Happiness = -5, Looks = -2 }, feedText = "Hot water was a mistake. RIP favorite shirt." },
			{ text = "Still make parents do it", effects = { Happiness = 1 }, feedText = "Why learn when Mom's got it covered?" },
		},
	},
	{
		id = "teen_independence_moment",
		title = "Independence Moment",
		emoji = "🦅",
		text = "You did something completely on your own for the first time!",
		question = "What was your independent moment?",
		minAge = 15, maxAge = 17,
		baseChance = 0.55,
		cooldown = 4,
		stage = STAGE,
		ageBand = "teen",
		category = "growth",
		tags = { "independence", "growing_up", "milestone" },
		
		choices = {
			{ text = "Traveled somewhere alone", effects = { Smarts = 3, Happiness = 6 }, setFlags = { solo_traveler = true }, feedText = "Navigated public transit, didn't get lost. Victory!" },
			{ text = "Handled a problem without parents", effects = { Smarts = 4, Happiness = 5 }, setFlags = { problem_solver = true }, feedText = "Fixed it yourself. Didn't need mom or dad. Growth!" },
			{ text = "Made a major decision yourself", effects = { Smarts = 3, Happiness = 4 }, setFlags = { decisive = true }, feedText = "Your choice, your consequences. That's adulthood." },
			{ text = "Organized something important", effects = { Smarts = 4, Happiness = 4 }, setFlags = { organizer = true }, feedText = "Event, trip, project - you made it happen!" },
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- PASSION-BASED EVENTS - Triggered by childhood passion discovery!
	-- These reward players who followed their passion with extra opportunities
	-- ══════════════════════════════════════════════════════════════════════════════
	{
		id = "teen_coding_project",
		title = "Your First App!",
		emoji = "💻",
		text = "You've been coding for years now. Time to build something REAL!",
		textVariants = {
			"All those hours learning to code are paying off. You have an idea for an app!",
			"You've been dreaming about this app for months. Time to build it!",
			"Your coding skills have gotten good. Really good. Build something epic?",
		},
		question = "What do you create?",
		minAge = 14, maxAge = 17,
		baseChance = 0.6,
		cooldown = 5,
		oneTime = true,
		stage = STAGE,
		category = "hobbies",
		tags = { "coding", "tech", "passion" },
		-- Only for those who discovered coding as their passion!
		requiresFlags = { passionate_coder = true },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "🎮 A simple game",
				effects = { Smarts = 8, Happiness = 10 },
				setFlags = { made_first_game = true, game_developer = true },
				feedText = "💻 You made a GAME! Friends are playing it! This is incredible!",
			},
			{
				text = "📱 A useful app",
				effects = { Smarts = 10, Happiness = 8, Money = 100 },
				setFlags = { made_first_app = true, app_developer = true },
				feedText = "💻 Your app works! People are downloading it! You're a real dev!",
			},
			{
				text = "🌐 A cool website",
				effects = { Smarts = 7, Happiness = 6 },
				setFlags = { made_first_website = true, web_developer = true },
				feedText = "💻 Your website is LIVE! You built this from scratch!",
			},
			{
				text = "🤖 A Discord bot",
				effects = { Smarts = 6, Happiness = 8 },
				setFlags = { made_first_bot = true, bot_developer = true },
				feedText = "💻 Your bot is running on servers! People love it!",
			},
		},
	},
	{
		id = "teen_gaming_tournament",
		title = "Gaming Tournament!",
		emoji = "🎮",
		text = "There's a gaming tournament with a CASH PRIZE. You've been training for this!",
		textVariants = {
			"An esports tournament is happening. Your chance to prove yourself!",
			"Friends want you on their team for the gaming competition!",
			"Your gaming skills are legendary in your friend group. Time to go big?",
		},
		question = "Do you compete?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 4,
		stage = STAGE,
		category = "hobbies",
		tags = { "gaming", "competition", "passion" },
		requiresFlags = { passionate_gamer = true },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "⚡ Go for the WIN!",
				effects = {},
				feedText = "Tournament time...",
				triggerMinigame = "mash",
				onResolve = function(state, minigameResult)
					local won = minigameResult and (minigameResult.success or minigameResult.won)
					state.Flags = state.Flags or {}
					if won then
						state.Money = (state.Money or 0) + math.random(200, 500)
						state:ModifyStat("Happiness", 20)
						state.Flags.tournament_winner = true
						state.Flags.esports_potential = true
						state:AddFeed("🎮🏆 TOURNAMENT CHAMPION! You WON! Prize money AND fame!")
					else
						state:ModifyStat("Happiness", 5)
						state:AddFeed("🎮 Didn't win but gained experience. Next time!")
					end
				end,
			},
			{
				text = "Watch and learn",
				effects = { Smarts = 3, Happiness = 3 },
				feedText = "Studying the pros. Taking notes. Getting better.",
			},
		},
	},
	{
		id = "teen_art_showcase",
		title = "Art Show Opportunity!",
		emoji = "🎨",
		text = "A local gallery wants to display student art. Your work is GOOD enough!",
		textVariants = {
			"Your art teacher nominated you for the student showcase!",
			"People keep saying your art is amazing. Time to show the world?",
			"An art competition has prizes. Your style is unique enough to win!",
		},
		question = "Do you submit your work?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 5,
		stage = STAGE,
		category = "hobbies",
		tags = { "art", "creative", "passion" },
		requiresFlags = { passionate_artist = true },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "🖼️ Submit my best piece!",
				effects = {},
				feedText = "Your art is on display...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.4 then
						state:ModifyStat("Happiness", 20)
						state:ModifyStat("Looks", 2)
						state.Money = (state.Money or 0) + 150
						state.Flags.art_award_winner = true
						state:AddFeed("🎨🏆 YOUR ART WON! People are buying prints! You're a real artist!")
					elseif roll < 0.8 then
						state:ModifyStat("Happiness", 10)
						state.Flags.exhibited_artist = true
						state:AddFeed("🎨 People loved your work! Great feedback! Keep creating!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("🎨 Didn't win but your art was SEEN. That's what matters!")
					end
				end,
			},
			{
				text = "Too nervous to share",
				effects = { Happiness = -3 },
				setFlags = { stage_fright = true },
				feedText = "Maybe next time. Your art stays private for now.",
			},
		},
	},
	{
		id = "teen_music_performance",
		title = "Your First Gig!",
		emoji = "🎵",
		text = "You've been practicing music for years. Someone wants you to PERFORM!",
		textVariants = {
			"The school talent show is coming. Your musical skills could shine!",
			"A local coffee shop has open mic night. Your chance to perform!",
			"Your band got asked to play at a party. Real audience!",
		},
		question = "Do you perform?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 5,
		stage = STAGE,
		category = "hobbies",
		tags = { "music", "performance", "passion" },
		requiresFlags = { passionate_performer = true },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "🎤 Take the stage!",
				effects = {},
				feedText = "The spotlight is on you...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.5 then
						state:ModifyStat("Happiness", 25)
						state:ModifyStat("Looks", 3)
						state.Flags.stage_performer = true
						state.Flags.crowd_pleaser = true
						state:AddFeed("🎵🌟 AMAZING! The crowd went WILD! You were BORN for this!")
					elseif roll < 0.85 then
						state:ModifyStat("Happiness", 10)
						state.Flags.stage_performer = true
						state:AddFeed("🎵 Good performance! Some mistakes but the crowd loved it!")
					else
						state:ModifyStat("Happiness", -5)
						state.Flags.stage_fright = true
						state:AddFeed("🎵 Froze on stage... embarrassing but you learned from it.")
					end
				end,
			},
			{
				text = "Not ready yet",
				effects = { Happiness = -2 },
				feedText = "Practice more. Next time will be YOUR time.",
			},
		},
	},
	{
		id = "teen_writing_published",
		title = "Your Story Got Noticed!",
		emoji = "📝",
		text = "You've been writing stories for years. Someone wants to PUBLISH your work!",
		textVariants = {
			"A teen writing contest is accepting submissions. You've got a killer story!",
			"Your creative writing teacher wants to submit your work to a magazine!",
			"You posted a story online and it's getting THOUSANDS of reads!",
		},
		question = "What do you do?",
		minAge = 13, maxAge = 17,
		baseChance = 0.5,
		cooldown = 5,
		stage = STAGE,
		category = "hobbies",
		tags = { "writing", "creative", "passion" },
		requiresFlags = { passionate_writer = true },
		blockedByFlags = { in_prison = true },
		
		choices = {
			{
				text = "📖 Submit for publication!",
				effects = {},
				feedText = "Your words are out there...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					if roll < 0.35 then
						state:ModifyStat("Happiness", 25)
						state:ModifyStat("Smarts", 5)
						state.Money = (state.Money or 0) + 200
						state.Flags.published_author = true
						state:AddFeed("📝🏆 PUBLISHED! Your story is IN PRINT! You're an AUTHOR!")
					elseif roll < 0.75 then
						state:ModifyStat("Happiness", 12)
						state:ModifyStat("Smarts", 3)
						state.Flags.recognized_writer = true
						state:AddFeed("📝 Honorable mention! Editors loved your voice! Keep writing!")
					else
						state:ModifyStat("Happiness", 3)
						state:AddFeed("📝 Rejected this time. Every famous writer got rejected. Keep going!")
					end
				end,
			},
			{
				text = "Keep it private for now",
				effects = { Happiness = 1 },
				feedText = "Your stories are just for you. Maybe someday...",
			},
		},
	},
}

return TeenExpanded
