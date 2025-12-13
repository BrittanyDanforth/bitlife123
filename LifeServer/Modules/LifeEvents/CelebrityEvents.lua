--[[
	CelebrityEvents.lua
	
	Comprehensive celebrity/fame system for BitLife-style game.
	Handles all aspects of famous life including:
	- Actor career path (Extra → Hollywood Legend)
	- Music career path (Street Performer → Music Icon)
	- Social media influencer path
	- Professional athlete career
	- Model career path
	- Fame events and paparazzi
	- Award shows and red carpets
	- Celebrity scandals and drama
	- Endorsement deals
	- Fan interactions
	
	REQUIRES: Celebrity gamepass (ID: 1626461980)
	
	This is a PREMIUM feature - full 1200+ line implementation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CelebrityEvents = {}

-- ════════════════════════════════════════════════════════════════════════════
-- FAME THRESHOLDS
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.FameLevels = {
	{ min = 0, max = 5, name = "Unknown", emoji = "👤" },
	{ min = 6, max = 15, name = "Local Celebrity", emoji = "📍" },
	{ min = 16, max = 30, name = "Rising Star", emoji = "⭐" },
	{ min = 31, max = 50, name = "Well-Known", emoji = "🌟" },
	{ min = 51, max = 70, name = "Famous", emoji = "✨" },
	{ min = 71, max = 85, name = "Very Famous", emoji = "💫" },
	{ min = 86, max = 95, name = "Superstar", emoji = "🌠" },
	{ min = 96, max = 100, name = "Legend", emoji = "👑" },
}

-- ════════════════════════════════════════════════════════════════════════════
-- ACTING CAREER PATH
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.ActingCareer = {
	name = "Acting",
	emoji = "🎬",
	description = "Pursue a career in film and television",
	minStartAge = 6,
	maxStartAge = 50,
	
	stages = {
		{
			id = "extra",
			name = "Extra",
			emoji = "👥",
			salary = { min = 500, max = 2000 },
			fameRequired = 0,
			fameGainPerYear = { min = 0, max = 2 },
			yearsToAdvance = { min = 1, max = 3 },
			description = "Stand in the background of scenes",
			activities = { "Stand in crowd scenes", "Wait on set all day", "Hope to be noticed" },
		},
		{
			id = "background",
			name = "Background Actor",
			emoji = "🎭",
			salary = { min = 2000, max = 8000 },
			fameRequired = 2,
			fameGainPerYear = { min = 1, max = 3 },
			yearsToAdvance = { min = 1, max = 2 },
			description = "Featured background roles",
			activities = { "Get featured in shots", "Learn from watching stars", "Network at craft services" },
		},
		{
			id = "bit_part",
			name = "Bit Part Actor",
			emoji = "🗣️",
			salary = { min = 8000, max = 25000 },
			fameRequired = 5,
			fameGainPerYear = { min = 2, max = 5 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Small speaking roles",
			activities = { "Deliver a few lines", "Get your SAG card", "Audition constantly" },
		},
		{
			id = "guest_star",
			name = "Guest Star",
			emoji = "📺",
			salary = { min = 25000, max = 75000 },
			fameRequired = 15,
			fameGainPerYear = { min = 3, max = 8 },
			yearsToAdvance = { min = 2, max = 3 },
			description = "Recurring guest appearances on TV shows",
			activities = { "Guest on popular shows", "Build your following", "Get recognized on the street" },
		},
		{
			id = "supporting",
			name = "Supporting Actor",
			emoji = "🎬",
			salary = { min = 75000, max = 200000 },
			fameRequired = 25,
			fameGainPerYear = { min = 5, max = 12 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Notable supporting roles in films",
			activities = { "Work with A-list actors", "Attend premieres", "Get award nominations" },
		},
		{
			id = "lead_tv",
			name = "TV Lead",
			emoji = "📺",
			salary = { min = 200000, max = 500000 },
			fameRequired = 40,
			fameGainPerYear = { min = 8, max = 15 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Lead your own TV series",
			activities = { "Star in your own show", "Do talk show appearances", "Sign autographs" },
		},
		{
			id = "lead_film",
			name = "Movie Star",
			emoji = "🎥",
			salary = { min = 1000000, max = 10000000 },
			fameRequired = 60,
			fameGainPerYear = { min = 10, max = 20 },
			yearsToAdvance = { min = 3, max = 5 },
			description = "Lead roles in major films",
			activities = { "Star in blockbusters", "Walk red carpets", "Do worldwide press tours" },
		},
		{
			id = "a_list",
			name = "A-List Celebrity",
			emoji = "⭐",
			salary = { min = 10000000, max = 30000000 },
			fameRequired = 80,
			fameGainPerYear = { min = 5, max = 10 },
			yearsToAdvance = { min = 5, max = 10 },
			description = "Hollywood's elite",
			activities = { "Choose your projects", "Command huge salaries", "Set trends" },
		},
		{
			id = "legend",
			name = "Hollywood Legend",
			emoji = "👑",
			salary = { min = 25000000, max = 100000000 },
			fameRequired = 95,
			fameGainPerYear = { min = 1, max = 3 },
			yearsToAdvance = nil, -- Final stage
			description = "An icon of cinema",
			activities = { "Receive lifetime achievement awards", "Have your star on the Walk of Fame", "Inspire generations" },
		},
	},
	
	-- Acting-specific events
	events = {
		{
			id = "audition_callback",
			title = "🎬 Audition Callback!",
			text = "You got a callback for a major role! This could be your big break.",
			minStage = 1,
			maxStage = 4,
			choices = {
				{ text = "Nail the audition", successChance = 60, fameGain = 10, salaryBonus = 50000 },
				{ text = "Choke under pressure", successChance = 100, fameGain = 0, message = "Better luck next time." },
			},
		},
		{
			id = "oscar_nomination",
			title = "🏆 Oscar Nomination!",
			text = "You've been nominated for an Academy Award! The whole world is watching.",
			minStage = 5,
			maxStage = 9,
			choices = {
				{ text = "Win the Oscar", successChance = 25, fameGain = 25, message = "You won! Your career is forever changed!" },
				{ text = "Lose gracefully", successChance = 100, fameGain = 10, message = "You didn't win, but the nomination itself is an honor." },
			},
		},
		{
			id = "blockbuster_offer",
			title = "💰 Blockbuster Offer",
			text = "A major studio wants you for their next franchise film!",
			minStage = 4,
			maxStage = 8,
			choices = {
				{ text = "Accept the role", fameGain = 15, salaryBonus = 5000000 },
				{ text = "Hold out for more money", successChance = 40, salaryBonus = 10000000, failMessage = "They went with someone else." },
				{ text = "Decline for an indie project", fameGain = 5, message = "Critics love your artistic integrity." },
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- MUSIC CAREER PATH
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.MusicCareer = {
	name = "Music",
	emoji = "🎵",
	description = "Pursue a career in music",
	minStartAge = 10,
	maxStartAge = 40,
	
	genres = {
		{ id = "pop", name = "Pop", emoji = "🎤" },
		{ id = "rock", name = "Rock", emoji = "🎸" },
		{ id = "hiphop", name = "Hip-Hop", emoji = "🎤" },
		{ id = "country", name = "Country", emoji = "🤠" },
		{ id = "electronic", name = "Electronic", emoji = "🎧" },
		{ id = "rnb", name = "R&B", emoji = "🎶" },
		{ id = "classical", name = "Classical", emoji = "🎻" },
		{ id = "jazz", name = "Jazz", emoji = "🎷" },
	},
	
	stages = {
		{
			id = "street",
			name = "Street Performer",
			emoji = "🎸",
			salary = { min = 50, max = 500 },
			fameRequired = 0,
			fameGainPerYear = { min = 0, max = 2 },
			yearsToAdvance = { min = 1, max = 3 },
			description = "Playing for tips on the street",
			activities = { "Busk on street corners", "Play open mic nights", "Record demos on your phone" },
		},
		{
			id = "local",
			name = "Local Artist",
			emoji = "🎤",
			salary = { min = 1000, max = 5000 },
			fameRequired = 3,
			fameGainPerYear = { min = 1, max = 4 },
			yearsToAdvance = { min = 1, max = 2 },
			description = "Known in your local music scene",
			activities = { "Play local venues", "Build a local following", "Sell CDs at shows" },
		},
		{
			id = "indie",
			name = "Indie Artist",
			emoji = "🎵",
			salary = { min = 10000, max = 40000 },
			fameRequired = 10,
			fameGainPerYear = { min = 3, max = 8 },
			yearsToAdvance = { min = 2, max = 3 },
			description = "Self-released music gaining traction",
			activities = { "Release music independently", "Tour small venues", "Build online following" },
		},
		{
			id = "signed",
			name = "Signed Artist",
			emoji = "📝",
			salary = { min = 50000, max = 150000 },
			fameRequired = 20,
			fameGainPerYear = { min = 5, max = 12 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Signed to a record label",
			activities = { "Record in professional studios", "Get radio play", "Appear on music shows" },
		},
		{
			id = "touring",
			name = "Touring Artist",
			emoji = "🚌",
			salary = { min = 200000, max = 500000 },
			fameRequired = 35,
			fameGainPerYear = { min = 8, max = 15 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Headlining your own tours",
			activities = { "Tour nationally", "Perform at festivals", "Release hit singles" },
		},
		{
			id = "platinum",
			name = "Platinum Artist",
			emoji = "💿",
			salary = { min = 1000000, max = 5000000 },
			fameRequired = 55,
			fameGainPerYear = { min = 10, max = 18 },
			yearsToAdvance = { min = 3, max = 5 },
			description = "Selling millions of records",
			activities = { "Release platinum albums", "Win music awards", "Collaborate with other stars" },
		},
		{
			id = "superstar",
			name = "Superstar",
			emoji = "🌟",
			salary = { min = 10000000, max = 50000000 },
			fameRequired = 75,
			fameGainPerYear = { min = 5, max = 12 },
			yearsToAdvance = { min = 4, max = 8 },
			description = "Global superstar status",
			activities = { "World tours", "Super Bowl halftime shows", "Break streaming records" },
		},
		{
			id = "icon",
			name = "Music Icon",
			emoji = "👑",
			salary = { min = 30000000, max = 150000000 },
			fameRequired = 95,
			fameGainPerYear = { min = 1, max = 3 },
			yearsToAdvance = nil,
			description = "A legend of music",
			activities = { "Rock & Roll Hall of Fame", "Influence generations", "Cultural icon status" },
		},
	},
	
	events = {
		{
			id = "viral_song",
			title = "🎵 Song Goes Viral!",
			text = "Your latest song is blowing up on social media! Millions are streaming it.",
			minStage = 2,
			maxStage = 6,
			choices = {
				{ text = "Capitalize on the moment", fameGain = 20, salaryBonus = 500000 },
				{ text = "Stay humble", fameGain = 10, message = "Fans love your authenticity." },
			},
		},
		{
			id = "grammy_nomination",
			title = "🏆 Grammy Nomination!",
			text = "You've been nominated for a Grammy Award!",
			minStage = 4,
			maxStage = 8,
			choices = {
				{ text = "Win the Grammy", successChance = 25, fameGain = 30, message = "You won! Thank you speech time!" },
				{ text = "Lose but perform", fameGain = 15, message = "Your performance stole the show!" },
			},
		},
		{
			id = "collab_offer",
			title = "🤝 Collaboration Offer",
			text = "A major artist wants to collaborate with you!",
			minStage = 3,
			maxStage = 7,
			choices = {
				{ text = "Accept and create a hit", fameGain = 15, salaryBonus = 1000000 },
				{ text = "Decline to stay independent", fameGain = 2, message = "You maintain your artistic vision." },
			},
		},
		{
			id = "world_tour",
			title = "🌍 World Tour Opportunity",
			text = "You have the chance to go on a massive world tour!",
			minStage = 5,
			maxStage = 8,
			choices = {
				{ text = "Go on tour (exhausting)", fameGain = 25, salaryBonus = 50000000, healthLoss = 15 },
				{ text = "Take a break instead", fameGain = 0, healthGain = 10, message = "You rest and recharge." },
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- SOCIAL MEDIA INFLUENCER PATH
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.InfluencerCareer = {
	name = "Social Media Influencer",
	emoji = "📱",
	description = "Build a following on social media",
	minStartAge = 13,
	maxStartAge = 35,
	
	platforms = {
		{ id = "instagram", name = "Instagram", emoji = "📸" },
		{ id = "youtube", name = "YouTube", emoji = "▶️" },
		{ id = "tiktok", name = "TikTok", emoji = "🎵" },
		{ id = "twitter", name = "Twitter", emoji = "🐦" },
		{ id = "twitch", name = "Twitch", emoji = "🎮" },
	},
	
	stages = {
		{
			id = "newbie",
			name = "New Creator",
			emoji = "📱",
			salary = { min = 0, max = 100 },
			followers = 100,
			fameRequired = 0,
			fameGainPerYear = { min = 0, max = 2 },
			yearsToAdvance = { min = 1, max = 2 },
			description = "Just starting your social media journey",
			activities = { "Post daily", "Learn the algorithm", "Hope for your first viral post" },
		},
		{
			id = "micro",
			name = "Micro Influencer",
			emoji = "📲",
			salary = { min = 500, max = 5000 },
			followers = 10000,
			fameRequired = 5,
			fameGainPerYear = { min = 2, max = 5 },
			yearsToAdvance = { min = 1, max = 2 },
			description = "Building a loyal following",
			activities = { "Get your first brand deal", "Engage with followers", "Establish your niche" },
		},
		{
			id = "growing",
			name = "Growing Influencer",
			emoji = "📈",
			salary = { min = 10000, max = 50000 },
			followers = 100000,
			fameRequired = 15,
			fameGainPerYear = { min = 4, max = 10 },
			yearsToAdvance = { min = 2, max = 3 },
			description = "Your content is reaching more people",
			activities = { "Multiple brand partnerships", "Attend influencer events", "Create merch" },
		},
		{
			id = "established",
			name = "Established Creator",
			emoji = "✅",
			salary = { min = 75000, max = 200000 },
			followers = 500000,
			fameRequired = 30,
			fameGainPerYear = { min = 6, max = 12 },
			yearsToAdvance = { min = 2, max = 3 },
			description = "A recognized name in the creator space",
			activities = { "Launch your own products", "Get verified", "Speak at events" },
		},
		{
			id = "famous",
			name = "Famous Influencer",
			emoji = "⭐",
			salary = { min = 300000, max = 800000 },
			followers = 2000000,
			fameRequired = 50,
			fameGainPerYear = { min = 8, max = 15 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Millions follow your every post",
			activities = { "Major brand ambassadorships", "Create your own show", "Launch business ventures" },
		},
		{
			id = "mega",
			name = "Mega Influencer",
			emoji = "💎",
			salary = { min = 1000000, max = 5000000 },
			followers = 10000000,
			fameRequired = 70,
			fameGainPerYear = { min = 5, max = 10 },
			yearsToAdvance = { min = 3, max = 5 },
			description = "One of the biggest influencers",
			activities = { "Build a media empire", "Launch multiple brands", "Shape culture" },
		},
		{
			id = "celebrity",
			name = "Internet Celebrity",
			emoji = "🌟",
			salary = { min = 5000000, max = 20000000 },
			followers = 50000000,
			fameRequired = 85,
			fameGainPerYear = { min = 3, max = 8 },
			yearsToAdvance = { min = 3, max = 5 },
			description = "Transcended influencer to full celebrity",
			activities = { "Appear on talk shows", "Write bestselling books", "Star in productions" },
		},
		{
			id = "icon",
			name = "Social Media Icon",
			emoji = "👑",
			salary = { min = 20000000, max = 100000000 },
			followers = 100000000,
			fameRequired = 95,
			fameGainPerYear = { min = 1, max = 3 },
			yearsToAdvance = nil,
			description = "An icon who defined an era of social media",
			activities = { "Your name is synonymous with influence", "Billions of impressions", "Legacy secured" },
		},
	},
	
	events = {
		{
			id = "viral_post",
			title = "📱 Post Goes Viral!",
			text = "Your latest post is exploding! Millions of views and counting!",
			minStage = 1,
			maxStage = 6,
			choices = {
				{ text = "Ride the wave", fameGain = 15, followersGain = 500000 },
				{ text = "Stay grounded", fameGain = 8, message = "You handle the attention maturely." },
			},
		},
		{
			id = "brand_deal",
			title = "💰 Major Brand Deal",
			text = "A Fortune 500 company wants you as their brand ambassador!",
			minStage = 3,
			maxStage = 7,
			choices = {
				{ text = "Accept the deal", salaryBonus = 2000000, fameGain = 10 },
				{ text = "Negotiate for more", successChance = 50, salaryBonus = 5000000, failMessage = "They went with someone else." },
				{ text = "Decline (doesn't fit your brand)", fameGain = 3, message = "Your followers appreciate your authenticity." },
			},
		},
		{
			id = "cancelled",
			title = "❌ You're Being Cancelled!",
			text = "Something from your past surfaced and people are calling you out!",
			minStage = 3,
			maxStage = 8,
			choices = {
				{ text = "Apologize sincerely", fameGain = -10, message = "Some accept your apology, others don't." },
				{ text = "Double down", successChance = 30, fameGain = 5, failFameLoss = 25, failMessage = "This made things much worse." },
				{ text = "Stay quiet and wait", fameGain = -5, message = "The storm eventually passes." },
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- PROFESSIONAL ATHLETE PATH
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.AthleteCareer = {
	name = "Professional Athlete",
	emoji = "🏆",
	description = "Compete at the highest level of sports",
	minStartAge = 16,
	maxStartAge = 28,
	retirementAge = 40,
	
	sports = {
		{ id = "football", name = "Football (NFL)", emoji = "🏈", avgCareerLength = 6 },
		{ id = "basketball", name = "Basketball (NBA)", emoji = "🏀", avgCareerLength = 8 },
		{ id = "soccer", name = "Soccer", emoji = "⚽", avgCareerLength = 12 },
		{ id = "baseball", name = "Baseball (MLB)", emoji = "⚾", avgCareerLength = 10 },
		{ id = "tennis", name = "Tennis", emoji = "🎾", avgCareerLength = 15 },
		{ id = "golf", name = "Golf", emoji = "⛳", avgCareerLength = 20 },
		{ id = "mma", name = "MMA/UFC", emoji = "🥊", avgCareerLength = 8 },
		{ id = "boxing", name = "Boxing", emoji = "🥊", avgCareerLength = 12 },
		{ id = "hockey", name = "Hockey (NHL)", emoji = "🏒", avgCareerLength = 10 },
	},
	
	stages = {
		{
			id = "amateur",
			name = "Amateur",
			emoji = "🏃",
			salary = { min = 0, max = 500 },
			fameRequired = 0,
			fameGainPerYear = { min = 0, max = 2 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Training and competing as an amateur",
			activities = { "Train daily", "Compete in local events", "Get scouted" },
		},
		{
			id = "college",
			name = "College Athlete",
			emoji = "🎓",
			salary = { min = 0, max = 10000 },
			fameRequired = 3,
			fameGainPerYear = { min = 1, max = 4 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Playing at the collegiate level",
			activities = { "Star for your team", "Get NIL deals", "Prepare for the draft" },
		},
		{
			id = "rookie",
			name = "Professional Rookie",
			emoji = "🌱",
			salary = { min = 100000, max = 500000 },
			fameRequired = 10,
			fameGainPerYear = { min = 3, max = 8 },
			yearsToAdvance = { min = 1, max = 2 },
			description = "Your first year as a professional",
			activities = { "Adjust to pro level", "Prove yourself", "Learn from veterans" },
		},
		{
			id = "regular",
			name = "Regular Player",
			emoji = "👟",
			salary = { min = 500000, max = 3000000 },
			fameRequired = 20,
			fameGainPerYear = { min = 5, max = 12 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "An established professional",
			activities = { "Compete regularly", "Build your reputation", "Sign endorsements" },
		},
		{
			id = "starter",
			name = "Starter/Key Player",
			emoji = "⭐",
			salary = { min = 3000000, max = 10000000 },
			fameRequired = 35,
			fameGainPerYear = { min = 8, max = 15 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "A crucial part of your team",
			activities = { "Lead your team", "Make highlight reels", "Get national coverage" },
		},
		{
			id = "allstar",
			name = "All-Star",
			emoji = "🌟",
			salary = { min = 10000000, max = 30000000 },
			fameRequired = 55,
			fameGainPerYear = { min = 10, max = 18 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Among the best in the league",
			activities = { "All-Star selections", "MVP voting", "Massive endorsements" },
		},
		{
			id = "superstar",
			name = "Superstar",
			emoji = "💫",
			salary = { min = 30000000, max = 60000000 },
			fameRequired = 75,
			fameGainPerYear = { min = 5, max = 12 },
			yearsToAdvance = { min = 3, max = 6 },
			description = "A household name",
			activities = { "Face of the franchise", "Global recognition", "Legacy building" },
		},
		{
			id = "legend",
			name = "Sports Legend",
			emoji = "👑",
			salary = { min = 50000000, max = 150000000 },
			fameRequired = 92,
			fameGainPerYear = { min = 2, max = 5 },
			yearsToAdvance = nil,
			description = "One of the greatest of all time",
			activities = { "Hall of Fame bound", "Jersey retired", "GOAT debates" },
		},
	},
	
	events = {
		{
			id = "championship",
			title = "🏆 Championship Game!",
			text = "Your team made it to the championship! It all comes down to this.",
			minStage = 4,
			maxStage = 8,
			choices = {
				{ text = "Win the championship", successChance = 40, fameGain = 30, message = "CHAMPION! You're on top of the world!" },
				{ text = "Lose in a close game", fameGain = 10, message = "So close! There's always next year." },
			},
		},
		{
			id = "injury",
			title = "🤕 Injury Scare",
			text = "You've suffered an injury during competition. How bad is it?",
			minStage = 2,
			maxStage = 8,
			choices = {
				{ text = "Minor - play through it", healthLoss = 5, message = "You tough it out." },
				{ text = "Serious - season ending", healthLoss = 20, yearsLost = 1, message = "You'll be back stronger." },
				{ text = "Career threatening", successChance = 60, healthLoss = 30, failMessage = "Your career may never be the same..." },
			},
		},
		{
			id = "contract_negotiation",
			title = "💰 Contract Negotiation",
			text = "It's time to negotiate your new contract!",
			minStage = 3,
			maxStage = 7,
			choices = {
				{ text = "Demand max money", successChance = 50, salaryBonus = 20000000, failMessage = "They called your bluff." },
				{ text = "Take a team-friendly deal", salaryBonus = 5000000, fameGain = 5, message = "Fans love your loyalty." },
				{ text = "Test free agency", successChance = 70, salaryBonus = 15000000, failMessage = "The market wasn't as strong as hoped." },
			},
		},
		{
			id = "mvp_race",
			title = "🏅 MVP Race",
			text = "You're in the running for Most Valuable Player!",
			minStage = 5,
			maxStage = 8,
			choices = {
				{ text = "Win MVP", successChance = 30, fameGain = 25, salaryBonus = 5000000, message = "MVP! The highest individual honor!" },
				{ text = "Finish runner-up", fameGain = 12, message = "So close to the top honor." },
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- MODEL CAREER PATH
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.ModelCareer = {
	name = "Modeling",
	emoji = "📸",
	description = "Work as a professional model",
	minStartAge = 14,
	maxStartAge = 35,
	
	types = {
		{ id = "fashion", name = "Fashion", emoji = "👗" },
		{ id = "commercial", name = "Commercial", emoji = "📺" },
		{ id = "fitness", name = "Fitness", emoji = "💪" },
		{ id = "plus_size", name = "Plus Size", emoji = "👑" },
		{ id = "catalog", name = "Catalog", emoji = "📖" },
	},
	
	stages = {
		{
			id = "amateur",
			name = "Amateur Model",
			emoji = "📷",
			salary = { min = 100, max = 1000 },
			fameRequired = 0,
			looksRequired = 60,
			fameGainPerYear = { min = 0, max = 2 },
			yearsToAdvance = { min = 1, max = 2 },
			description = "Building your portfolio",
			activities = { "TFP shoots", "Build portfolio", "Find an agency" },
		},
		{
			id = "catalog",
			name = "Catalog Model",
			emoji = "📖",
			salary = { min = 5000, max = 20000 },
			fameRequired = 5,
			looksRequired = 65,
			fameGainPerYear = { min = 1, max = 4 },
			yearsToAdvance = { min = 1, max = 2 },
			description = "Modeling for catalogs and ads",
			activities = { "Department store catalogs", "Local advertisements", "Steady work" },
		},
		{
			id = "commercial",
			name = "Commercial Model",
			emoji = "📺",
			salary = { min = 30000, max = 80000 },
			fameRequired = 15,
			looksRequired = 70,
			fameGainPerYear = { min = 3, max = 8 },
			yearsToAdvance = { min = 2, max = 3 },
			description = "National commercials and campaigns",
			activities = { "TV commercials", "Billboard campaigns", "Brand spokesmodel" },
		},
		{
			id = "fashion",
			name = "Fashion Model",
			emoji = "👗",
			salary = { min = 100000, max = 300000 },
			fameRequired = 30,
			looksRequired = 80,
			fameGainPerYear = { min = 6, max = 12 },
			yearsToAdvance = { min = 2, max = 3 },
			description = "Fashion week and editorial",
			activities = { "Magazine editorials", "Fashion week shows", "Designer campaigns" },
		},
		{
			id = "runway",
			name = "Runway Model",
			emoji = "🌟",
			salary = { min = 300000, max = 800000 },
			fameRequired = 50,
			looksRequired = 85,
			fameGainPerYear = { min = 8, max = 15 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Walking the world's top runways",
			activities = { "Paris Fashion Week", "Milan shows", "Exclusive campaigns" },
		},
		{
			id = "top",
			name = "Top Model",
			emoji = "✨",
			salary = { min = 1000000, max = 3000000 },
			fameRequired = 70,
			looksRequired = 90,
			fameGainPerYear = { min = 5, max = 12 },
			yearsToAdvance = { min = 3, max = 5 },
			description = "One of the world's top models",
			activities = { "Vogue covers", "Luxury brand campaigns", "Celebrity status" },
		},
		{
			id = "super",
			name = "Supermodel",
			emoji = "💎",
			salary = { min = 5000000, max = 20000000 },
			fameRequired = 85,
			looksRequired = 92,
			fameGainPerYear = { min = 3, max = 8 },
			yearsToAdvance = { min = 3, max = 6 },
			description = "A supermodel known by first name alone",
			activities = { "Global icon status", "Your own beauty line", "Victoria's Secret Angel" },
		},
		{
			id = "icon",
			name = "Fashion Icon",
			emoji = "👑",
			salary = { min = 15000000, max = 50000000 },
			fameRequired = 95,
			looksRequired = 90,
			fameGainPerYear = { min = 1, max = 3 },
			yearsToAdvance = nil,
			description = "A legendary figure in fashion",
			activities = { "Define beauty standards", "Launch fashion empire", "Timeless legacy" },
		},
	},
	
	events = {
		{
			id = "vogue_cover",
			title = "📸 Vogue Cover Offer!",
			text = "Vogue wants you for their cover! This is the pinnacle of modeling.",
			minStage = 4,
			maxStage = 8,
			choices = {
				{ text = "Accept and slay", fameGain = 20, salaryBonus = 500000, message = "Your cover is iconic!" },
				{ text = "Negotiate creative control", successChance = 50, fameGain = 25, failMessage = "They went with someone else." },
			},
		},
		{
			id = "body_shaming",
			title = "😔 Body Shaming Incident",
			text = "Someone in the industry made cruel comments about your appearance.",
			minStage = 2,
			maxStage = 6,
			choices = {
				{ text = "Speak out against it", fameGain = 10, happinessLoss = 5, message = "You became an advocate for body positivity." },
				{ text = "Ignore it professionally", happinessLoss = 10, message = "You focused on your work." },
				{ text = "It affects your confidence", happinessLoss = 15, looksLoss = 5, message = "The industry can be cruel." },
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- FAME EVENTS (General events for all famous people)
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.GeneralFameEvents = {
	-- PAPARAZZI EVENTS
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #249: Added cooldown to prevent paparazzi event spam
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "paparazzi_chase",
		title = "📸 Paparazzi Chase!",
		emoji = "📸",
		text = "Paparazzi are following you everywhere! They're getting dangerously close.",
		minFame = 30,
		cooldown = 2, -- CRITICAL FIX: 2 year cooldown between paparazzi events
		choices = {
			{
				text = "Smile and wave professionally",
				effects = { Happiness = -3 },
				fameEffect = 5,
				feed = "You handled the paparazzi with grace.",
			},
			{
				text = "Tell them off angrily",
				effects = { Happiness = 5 },
				fameEffect = -10,
				setFlags = { media_enemy = true },
				feed = "Your outburst will be front page news!",
			},
			{
				text = "Run and hide",
				effects = { Happiness = -5 },
				fameEffect = 0,
				feed = "You escaped... for now.",
			},
			{
				text = "Pose for photos on your terms",
				effects = { Happiness = 2 },
				fameEffect = 8,
				feed = "You controlled the narrative.",
			},
		},
	},
	
	-- FAN ENCOUNTERS
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #248: Added cooldown to prevent fan encounter spam
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "fan_encounter",
		title = "😍 Fan Encounter!",
		emoji = "😍",
		text = "A fan recognizes you and wants a photo and autograph!",
		minFame = 20,
		cooldown = 2, -- CRITICAL FIX: 2 year cooldown
		choices = {
			{
				text = "Happily oblige",
				effects = { Happiness = 5 },
				fameEffect = 3,
				feed = "You made someone's day!",
			},
			{
				text = "Politely decline (you're busy)",
				effects = { Happiness = 0 },
				fameEffect = -2,
				feed = "They understood.",
			},
			{
				text = "Be rude about it",
				effects = { Happiness = 3 },
				fameEffect = -10,
				setFlags = { fan_unfriendly = true },
				feed = "That fan will tell everyone...",
			},
			{
				text = "Spend time talking to them",
				effects = { Happiness = 8 },
				fameEffect = 8,
				setFlags = { fan_friendly = true },
				feed = "Your genuine connection went viral!",
			},
		},
	},
	
	-- STALKER SITUATION
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #250: Stalker events should be rare (once per lifetime max)
	-- ═══════════════════════════════════════════════════════════════════════════════
	{
		id = "stalker",
		title = "😰 Stalker Situation",
		emoji = "😰",
		text = "Someone has been obsessively following you. They've shown up at your home.",
		minFame = 50,
		oneTime = true, -- CRITICAL FIX: Only one stalker situation per lifetime
		cooldown = 10, -- CRITICAL FIX: 10 year cooldown if it happens again
		choices = {
			{
				text = "Get a restraining order",
				effects = { Happiness = -10 },
				fameEffect = 0,
				setFlags = { had_stalker = true },
				feed = "You took legal action for your safety.",
			},
			{
				text = "Hire more security",
				effects = { Happiness = -5, Money = -100000 },
				fameEffect = 0,
				setFlags = { increased_security = true },
				feed = "You beefed up your security team.",
			},
			{
				text = "Move to a new location",
				effects = { Happiness = -15, Money = -500000 },
				fameEffect = -5,
				feed = "You had to relocate for safety.",
			},
		},
	},
	
	-- ENDORSEMENT DEAL
	{
		id = "endorsement_deal",
		title = "💰 Endorsement Opportunity!",
		emoji = "💰",
		text = "A major brand wants you to endorse their product!",
		minFame = 40,
		choices = {
			{
				text = "Accept the deal",
				effects = { Happiness = 8, Money = 500000 },
				fameEffect = 5,
				feed = "You signed a lucrative endorsement deal!",
			},
			{
				text = "Hold out for more money",
				effects = {},
				successChance = 50,
				successEffects = { Happiness = 10, Money = 2000000 },
				successFame = 8,
				successFeed = "They doubled their offer!",
				failEffects = { Happiness = -5 },
				failFame = -2,
				failFeed = "They went with someone else.",
			},
			{
				text = "Decline (doesn't fit your image)",
				effects = { Happiness = 3 },
				fameEffect = 2,
				setFlags = { selective_endorsements = true },
				feed = "You stayed true to your brand.",
			},
		},
	},
	
	-- TABLOID STORY
	{
		id = "tabloid_story",
		title = "📰 Tabloid Story!",
		emoji = "📰",
		text = "A tabloid is running a story about you. It's completely made up!",
		minFame = 35,
		choices = {
			{
				text = "Ignore it completely",
				effects = { Happiness = -5 },
				fameEffect = -3,
				feed = "You let the story fade away.",
			},
			{
				text = "Deny it on social media",
				effects = { Happiness = 0 },
				fameEffect = 5,
				feed = "Your denial got more attention than the story.",
			},
			{
				text = "Sue for defamation",
				effects = { Happiness = -8, Money = -50000 },
				successChance = 60,
				successEffects = { Happiness = 15, Money = 500000 },
				successFame = 10,
				successFeed = "You won the lawsuit!",
				failEffects = { Happiness = -10, Money = -200000 },
				failFame = -5,
				failFeed = "You lost the case.",
			},
		},
	},
	
	-- AWARD SHOW INVITE
	{
		id = "award_show_invite",
		title = "🏆 Award Show Invitation!",
		emoji = "🏆",
		text = "You've been invited to present at a major award show!",
		minFame = 45,
		choices = {
			{
				text = "Attend and present",
				effects = { Happiness = 10 },
				fameEffect = 12,
				setFlags = { award_presenter = true },
				feed = "You shined on the award show stage!",
			},
			{
				text = "Attend and steal the show",
				effects = { Happiness = 15 },
				successChance = 60,
				successFame = 20,
				successFeed = "Everyone's talking about your moment!",
				failFame = -10,
				failFeed = "Your attempt to stand out backfired.",
			},
			{
				text = "Skip it",
				effects = { Happiness = 5 },
				fameEffect = -5,
				feed = "You stayed home instead.",
			},
		},
	},
	
	-- RED CARPET EVENT
	{
		id = "red_carpet",
		title = "✨ Red Carpet Event!",
		emoji = "✨",
		text = "You're walking the red carpet at a major premiere!",
		minFame = 40,
		choices = {
			{
				text = "Wear designer outfit",
				effects = { Happiness = 10, Money = -50000 },
				fameEffect = 8,
				feed = "You looked stunning on the red carpet!",
			},
			{
				text = "Wear something bold/controversial",
				effects = { Happiness = 8 },
				successChance = 50,
				successFame = 20,
				successFeed = "Your look broke the internet!",
				failFame = -15,
				failFeed = "You made the worst dressed list.",
			},
			{
				text = "Wear something understated",
				effects = { Happiness = 5 },
				fameEffect = 3,
				feed = "You looked classic and elegant.",
			},
		},
	},
	
	-- INTERVIEW OPPORTUNITY
	{
		id = "major_interview",
		title = "🎤 Major Interview!",
		emoji = "🎤",
		text = "A famous talk show host wants to interview you!",
		minFame = 50,
		choices = {
			{
				text = "Give a great interview",
				effects = { Happiness = 10 },
				fameEffect = 15,
				feed = "Your interview was a hit!",
			},
			{
				text = "Open up about personal struggles",
				effects = { Happiness = -5 },
				fameEffect = 20,
				setFlags = { vulnerable_celebrity = true },
				feed = "Your honesty resonated with millions.",
			},
			{
				text = "Say something controversial",
				effects = { Happiness = 5 },
				successChance = 40,
				successFame = 25,
				successFeed = "Your bold statements went viral!",
				failFame = -20,
				failFeed = "The backlash was intense.",
			},
		},
	},
	
	-- CHARITY OPPORTUNITY
	{
		id = "charity_ambassador",
		title = "💝 Charity Ambassador Offer",
		emoji = "💝",
		text = "A major charity wants you as their global ambassador!",
		minFame = 55,
		choices = {
			{
				text = "Accept and commit fully",
				effects = { Happiness = 15, Money = -100000 },
				fameEffect = 15,
				setFlags = { charity_ambassador = true },
				feed = "You became a voice for an important cause!",
			},
			{
				text = "Accept but minimal involvement",
				effects = { Happiness = 5 },
				fameEffect = 8,
				feed = "You lent your name to the cause.",
			},
			{
				text = "Decline politely",
				effects = { Happiness = 0 },
				fameEffect = -3,
				feed = "You weren't ready for the commitment.",
			},
		},
	},
	
	-- SCANDAL BREWING
	{
		id = "scandal_brewing",
		title = "⚠️ Scandal Brewing!",
		emoji = "⚠️",
		text = "Someone is threatening to release damaging information about you!",
		minFame = 45,
		choices = {
			{
				text = "Pay them off",
				effects = { Money = -500000 },
				fameEffect = 0,
				setFlags = { paid_blackmail = true },
				feed = "You made the problem go away... for now.",
			},
			{
				text = "Get ahead of it and confess",
				effects = { Happiness = -15 },
				fameEffect = -10,
				setFlags = { owned_mistake = true },
				feed = "You controlled the narrative by confessing first.",
			},
			{
				text = "Deny everything and fight it",
				effects = { Happiness = -10 },
				successChance = 40,
				successFame = 5,
				successFeed = "The truth never came out.",
				failFame = -30,
				failFeed = "The scandal exploded everywhere.",
			},
			{
				text = "Report them to the police",
				effects = { Happiness = -5 },
				fameEffect = 5,
				feed = "You took the high road.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #211-225: MASSIVE CELEBRITY EVENT EXPANSION
	-- 15+ new events with proper progression and blocking flags
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- CAREER BREAKTHROUGH
	{
		id = "career_breakthrough",
		title = "🌟 Career Breakthrough!",
		emoji = "🌟",
		text = "You've been offered a role/opportunity that could define your career. This is the big one.",
		minFame = 25,
		maxFame = 60,
		oneTime = true,
		choices = {
			{
				text = "Go all in",
				effects = { Happiness = 15, Health = -10 },
				fameEffect = 25,
				setFlags = { career_breakthrough = true },
				feed = "Your breakthrough moment arrived!",
			},
			{
				text = "Take it but maintain balance",
				effects = { Happiness = 10 },
				fameEffect = 15,
				feed = "You handled the opportunity professionally.",
			},
		},
	},
	
	-- VIRAL MOMENT
	{
		id = "viral_moment",
		title = "📱 Going Viral!",
		emoji = "📱",
		text = "Something you did went incredibly viral! Millions of people have seen it.",
		minFame = 15,
		cooldown = 5,
		choices = {
			{
				text = "Lean into the attention",
				effects = { Happiness = 15 },
				fameEffect = 20,
				setFlags = { went_viral = true },
				feed = "You rode the viral wave to new heights!",
			},
			{
				text = "Stay humble",
				effects = { Happiness = 8, Smarts = 5 },
				fameEffect = 10,
				feed = "You handled it with grace.",
			},
		},
	},
	
	-- BRAND EMPIRE
	{
		id = "brand_empire",
		title = "👔 Build Your Brand Empire",
		emoji = "👔",
		text = "You have enough fame to launch your own brand.",
		minFame = 50,
		oneTime = true,
		choices = {
			{
				text = "Launch a fashion line",
				effects = { Happiness = 15, Money = -500000 },
				successChance = 60,
				successFame = 15,
				successFeed = "Your fashion line is a hit!",
				failFame = -5,
				failFeed = "Your fashion line flopped.",
				setFlags = { entrepreneur = true },
			},
			{
				text = "Launch a beauty brand",
				effects = { Happiness = 12, Money = -300000 },
				successChance = 70,
				successFame = 12,
				successFeed = "Your beauty brand is selling out!",
				setFlags = { entrepreneur = true },
			},
		},
	},
	
	-- CELEBRITY FEUD
	{
		id = "celebrity_feud",
		title = "⚡ Celebrity Feud!",
		emoji = "⚡",
		text = "Another celebrity publicly called you out!",
		minFame = 35,
		cooldown = 4,
		choices = {
			{
				text = "Clap back hard",
				effects = { Happiness = 8 },
				successChance = 50,
				successFame = 15,
				successFeed = "You won the feud!",
				failFame = -10,
				failFeed = "Your response backfired.",
			},
			{
				text = "Take the high road",
				effects = { Happiness = 5, Smarts = 5 },
				fameEffect = 5,
				feed = "Your mature response earned respect.",
			},
		},
	},
	
	-- REALITY TV OFFER
	{
		id = "reality_tv_offer",
		title = "📺 Reality TV Offer",
		emoji = "📺",
		text = "A major network wants you for their reality show.",
		minFame = 30,
		oneTime = true,
		choices = {
			{
				text = "Accept - show everything",
				effects = { Happiness = 5, Money = 500000 },
				fameEffect = 25,
				setFlags = { reality_tv_star = true },
				feed = "Your life is now an open book!",
			},
			{
				text = "Decline",
				effects = { Happiness = 10 },
				feed = "You valued your privacy.",
			},
		},
	},
	
	-- AWARD NOMINATION
	{
		id = "major_award_nomination",
		title = "🏆 Award Nomination!",
		emoji = "🏆",
		text = "You've been nominated for a major award!",
		minFame = 55,
		cooldown = 5,
		choices = {
			{
				text = "Campaign hard to win",
				effects = { Happiness = 10, Money = -100000 },
				successChance = 40,
				successFame = 25,
				successFeed = "YOU WON!",
				setFlags = { award_winner = true },
				failFame = 5,
				failFeed = "You didn't win, but the nomination was an honor.",
			},
			{
				text = "Let the work speak for itself",
				effects = { Happiness = 8 },
				successChance = 30,
				successFame = 30,
				successFeed = "You won on merit!",
				failFame = 5,
			},
		},
	},
	
	-- MENTAL HEALTH
	{
		id = "fame_mental_health",
		title = "😔 The Dark Side of Fame",
		emoji = "😔",
		text = "The constant spotlight is taking its toll.",
		minFame = 50,
		cooldown = 5,
		choices = {
			{
				text = "Speak openly about struggles",
				effects = { Happiness = 10, Health = 5 },
				fameEffect = 15,
				setFlags = { mental_health_advocate = true },
				feed = "Your honesty inspired millions.",
			},
			{
				text = "Take a break",
				effects = { Happiness = 15, Health = 10 },
				fameEffect = -10,
				feed = "You stepped back to focus on yourself.",
			},
		},
	},
	
	-- MEGA DEAL
	{
		id = "mega_endorsement_deal",
		title = "💰 Mega Deal!",
		emoji = "💰",
		text = "A massive brand wants you as their global spokesperson.",
		minFame = 70,
		oneTime = true,
		choices = {
			{
				text = "Sign the deal",
				effects = { Happiness = 20, Money = 5000000 },
				fameEffect = 15,
				setFlags = { mega_endorsement = true },
				feed = "You signed a $5 million deal!",
			},
			{
				text = "Negotiate for more",
				effects = { Happiness = 15 },
				successChance = 50,
				successEffects = { Money = 10000000 },
				successFame = 20,
				successFeed = "$10 million! Legendary!",
				failFeed = "They walked away.",
			},
		},
	},
	
	-- LEGACY
	{
		id = "legacy_project",
		title = "🌟 Legacy Project",
		emoji = "🌟",
		text = "You have the opportunity to create something that will outlast you.",
		minFame = 80,
		oneTime = true,
		choices = {
			{
				text = "Start a foundation",
				effects = { Happiness = 25, Money = -500000 },
				fameEffect = 20,
				setFlags = { has_foundation = true },
				feed = "Your foundation will help millions.",
			},
			{
				text = "Create a masterwork",
				effects = { Happiness = 20, Health = -10 },
				fameEffect = 25,
				setFlags = { created_masterwork = true },
				feed = "You created something eternal.",
			},
		},
	},
	
	-- CANCELLED
	{
		id = "getting_cancelled",
		title = "❌ Getting Cancelled!",
		emoji = "❌",
		text = "Something from your past surfaced. The internet mob is out for blood.",
		minFame = 45,
		cooldown = 8,
		choices = {
			{
				text = "Apologize sincerely",
				effects = { Happiness = -15 },
				fameEffect = -10,
				setFlags = { was_cancelled = true },
				feed = "You owned your mistakes.",
			},
			{
				text = "Fight back",
				effects = { Happiness = -5 },
				successChance = 30,
				successFame = 5,
				successFeed = "You turned the tide.",
				failFame = -30,
				failFeed = "Fighting back made it worse.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #452: MASSIVE CELEBRITY EVENT EXPANSION
	-- 25+ new events for deeper celebrity gameplay
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- VIRAL MOMENT
	{
		id = "viral_moment",
		title = "📱 Viral Moment",
		emoji = "📱",
		text = "Something you did just went viral! Millions are watching, sharing, and talking about you.",
		minFame = 20,
		cooldown = 4,
		maxOccurrences = 5,
		choices = {
			{
				text = "Embrace it and lean into the meme",
				effects = { Happiness = 20 },
				fameEffect = 15,
				setFlags = { meme_friendly = true },
				feed = "You became the internet's favorite!",
			},
			{
				text = "Use it to promote your work",
				effects = { Happiness = 10, Money = 50000 },
				fameEffect = 10,
				setFlags = { savvy_promoter = true },
				feed = "Smart marketing from a viral moment!",
			},
			{
				text = "Ignore it completely",
				effects = { Happiness = 5 },
				fameEffect = 5,
				feed = "It faded as quickly as it came.",
			},
			{
				text = "Try to get it removed",
				effects = { Happiness = -10 },
				fameEffect = 10,
				setFlags = { streisand_effect = true },
				feed = "The Streisand Effect made it even bigger!",
			},
		},
	},
	
	-- STALKER FAN
	{
		id = "stalker_fan",
		title = "😰 Obsessed Fan",
		emoji = "😰",
		text = "Security discovered someone has been following you everywhere. They know your schedule, your home, everything.",
		minFame = 40,
		cooldown = 10,
		maxOccurrences = 2,
		choices = {
			{
				text = "Get a restraining order",
				effects = { Happiness = -10, Money = -20000 },
				fameEffect = 0,
				setFlags = { has_restraining_order = true },
				feed = "The courts are handling it now.",
			},
			{
				text = "Upgrade security significantly",
				effects = { Happiness = 5, Money = -100000 },
				fameEffect = 0,
				setFlags = { heavy_security = true },
				feed = "You now travel with bodyguards everywhere.",
			},
			{
				text = "Move to a new location",
				effects = { Happiness = -5, Money = -500000 },
				fameEffect = 0,
				setFlags = { changed_residence = true },
				feed = "Fresh start, new address, new peace.",
			},
			{
				text = "Try to meet them and de-escalate",
				effects = { Happiness = -20, Health = -5 },
				successChance = 30,
				successFame = 5,
				successFeed = "They apologized and left you alone.",
				failFame = -5,
				failFeed = "That was a terrible idea. Security had to intervene.",
			},
		},
	},
	
	-- CHARITY GALA HOST
	{
		id = "charity_gala_host",
		title = "🎪 Gala Host",
		emoji = "🎪",
		text = "You've been asked to host the biggest charity gala of the year. All eyes will be on you.",
		minFame = 60,
		cooldown = 6,
		maxOccurrences = 3,
		choices = {
			{
				text = "Give an inspiring speech",
				effects = { Happiness = 15, Smarts = 5 },
				fameEffect = 12,
				setFlags = { great_speaker = true },
				feed = "Your words moved the room to tears and donations!",
			},
			{
				text = "Donate a huge amount yourself",
				effects = { Happiness = 20, Money = -1000000 },
				fameEffect = 15,
				setFlags = { generous_celebrity = true },
				feed = "Your generosity made headlines!",
			},
			{
				text = "Network with other celebrities",
				effects = { Happiness = 10, Smarts = 3 },
				fameEffect = 8,
				setFlags = { well_connected = true },
				feed = "You made valuable industry connections.",
			},
			{
				text = "Just show up and smile",
				effects = { Happiness = 5 },
				fameEffect = 3,
				feed = "You did the bare minimum.",
			},
		},
	},
	
	-- COLLABORATION OFFER
	{
		id = "major_collaboration",
		title = "🤝 Dream Collab",
		emoji = "🤝",
		text = "One of the biggest names in entertainment wants to collaborate with you. This could change everything.",
		minFame = 50,
		cooldown = 5,
		maxOccurrences = 4,
		choices = {
			{
				text = "Accept enthusiastically",
				effects = { Happiness = 25 },
				fameEffect = 20,
				setFlags = { collaborated_legend = true },
				feed = "This collaboration is already iconic!",
			},
			{
				text = "Negotiate for creative control",
				effects = { Happiness = 15, Smarts = 5 },
				successChance = 50,
				successFame = 25,
				successFeed = "Your vision shapes the project!",
				failFame = 10,
				failFeed = "They went with someone else.",
			},
			{
				text = "Decline - wrong fit for your brand",
				effects = { Happiness = 5 },
				fameEffect = -5,
				setFlags = { brand_focused = true },
				feed = "You stayed true to yourself.",
			},
		},
	},
	
	-- AWARD SHOW PERFORMANCE
	{
		id = "award_show_performance",
		title = "🎤 Award Show Stage",
		emoji = "🎤",
		text = "You've been invited to perform at the biggest award show of the year. Billions will be watching.",
		minFame = 55,
		cooldown = 4,
		maxOccurrences = 5,
		choices = {
			{
				text = "Go all out with production",
				effects = { Happiness = 20, Money = -200000 },
				fameEffect = 18,
				setFlags = { show_stopper = true },
				feed = "Everyone's talking about your performance!",
			},
			{
				text = "Keep it simple and raw",
				effects = { Happiness = 15 },
				fameEffect = 12,
				setFlags = { raw_talent = true },
				feed = "Sometimes less is more. Stunning.",
			},
			{
				text = "Add a controversial element",
				effects = { Happiness = 10 },
				successChance = 50,
				successFame = 25,
				successFeed = "Controversial but iconic!",
				failFame = -15,
				failFeed = "It backfired spectacularly.",
			},
			{
				text = "Decline - too much pressure",
				effects = { Happiness = -10 },
				fameEffect = -5,
				feed = "A missed opportunity.",
			},
		},
	},
	
	-- PODCAST INTERVIEW
	{
		id = "major_podcast",
		title = "🎙️ Big Podcast",
		emoji = "🎙️",
		text = "A popular podcast wants a deep-dive interview. No scripts, no edits. Just real conversation.",
		minFame = 40,
		cooldown = 4,
		maxOccurrences = 6,
		choices = {
			{
				text = "Be completely open and honest",
				effects = { Happiness = 15 },
				fameEffect = 15,
				setFlags = { authentic_celebrity = true },
				feed = "Fans love the real you!",
			},
			{
				text = "Promote your latest project",
				effects = { Happiness = 8, Money = 50000 },
				fameEffect = 5,
				feed = "A standard promo appearance.",
			},
			{
				text = "Drop some tea about the industry",
				effects = { Happiness = 12 },
				fameEffect = 20,
				setFlags = { spilled_tea = true },
				feed = "The clips went viral!",
			},
			{
				text = "Give vague non-answers",
				effects = { Happiness = 5 },
				fameEffect = -5,
				feed = "Fans were disappointed.",
			},
		},
	},
	
	-- MOVIE ROLE OFFER
	{
		id = "blockbuster_role",
		title = "🎬 Blockbuster Role",
		emoji = "🎬",
		text = "A major studio wants you for their next blockbuster. But the role requires a dramatic transformation.",
		minFame = 55,
		cooldown = 6,
		maxOccurrences = 3,
		conditions = { blockedFlags = { retired = true } },
		choices = {
			{
				text = "Commit fully - gain/lose weight, learn new skills",
				effects = { Happiness = 15, Health = -15 },
				fameEffect = 20,
				setFlags = { method_actor = true },
				money = 2000000,
				feed = "Your dedication stunned critics!",
			},
			{
				text = "Do it with movie magic instead",
				effects = { Happiness = 10 },
				fameEffect = 12,
				money = 1500000,
				feed = "A solid performance.",
			},
			{
				text = "Ask for script changes to suit you",
				effects = { Happiness = 8, Smarts = 5 },
				successChance = 40,
				successFame = 15,
				successMoney = 2500000,
				successFeed = "They rewrote the role for you!",
				failFame = -10,
				failFeed = "They cast someone else.",
			},
			{
				text = "Pass on the role",
				effects = { Happiness = 5 },
				fameEffect = -3,
				feed = "It went to another star.",
			},
		},
	},
	
	-- FASHION LINE LAUNCH
	{
		id = "fashion_line_launch",
		title = "👗 Fashion Empire",
		emoji = "👗",
		text = "A major fashion house wants you to launch your own clothing line. Your name on every label.",
		minFame = 60,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { has_fashion_line = true } },
		choices = {
			{
				text = "High-end luxury brand",
				effects = { Happiness = 20, Money = 500000 },
				fameEffect = 15,
				setFlags = { has_fashion_line = true, luxury_brand = true },
				feed = "Your couture line debuted to rave reviews!",
			},
			{
				text = "Affordable accessible fashion",
				effects = { Happiness = 18, Money = 1000000 },
				fameEffect = 18,
				setFlags = { has_fashion_line = true, accessible_brand = true },
				feed = "Everyone can wear your designs now!",
			},
			{
				text = "Sustainable eco-fashion",
				effects = { Happiness = 22, Money = 300000 },
				fameEffect = 20,
				setFlags = { has_fashion_line = true, eco_brand = true },
				feed = "Your eco-conscious brand is a hit!",
			},
			{
				text = "Decline - stick to your core career",
				effects = { Happiness = 5 },
				fameEffect = 0,
				feed = "Fashion isn't your thing.",
			},
		},
	},
	
	-- REALITY TV OFFER
	{
		id = "reality_tv_offer",
		title = "📺 Reality TV Offer",
		emoji = "📺",
		text = "Network executives want to document your life in a reality series. Fame and fortune, but zero privacy.",
		minFame = 30,
		cooldown = 8,
		maxOccurrences = 2,
		conditions = { blockedFlags = { has_reality_show = true } },
		choices = {
			{
				text = "Let cameras follow everything",
				effects = { Happiness = 10, Money = 2000000 },
				fameEffect = 25,
				setFlags = { has_reality_show = true, open_book = true },
				feed = "Your show is a ratings hit!",
			},
			{
				text = "Only film curated content",
				effects = { Happiness = 8, Money = 1000000 },
				fameEffect = 15,
				setFlags = { has_reality_show = true, controlled_image = true },
				feed = "A polished version of your life.",
			},
			{
				text = "Decline - value privacy too much",
				effects = { Happiness = 10 },
				fameEffect = 0,
				setFlags = { values_privacy = true },
				feed = "Some things should stay private.",
			},
		},
	},
	
	-- MUSIC COMEBACK
	{
		id = "comeback_opportunity",
		title = "🎵 Comeback Time",
		emoji = "🎵",
		text = "After a break from the spotlight, the industry is ready for your comeback. Make it count.",
		minFame = 40,
		cooldown = 10,
		maxOccurrences = 2,
		conditions = { requiresFlags = { took_break = true } },
		choices = {
			{
				text = "Complete reinvention",
				effects = { Happiness = 20 },
				fameEffect = 25,
				setFlags = { reinvented = true },
				feed = "The new you is even bigger than before!",
			},
			{
				text = "Return to classic style",
				effects = { Happiness = 15 },
				fameEffect = 15,
				setFlags = { classic_comeback = true },
				feed = "Fans love the return to form!",
			},
			{
				text = "Low-key indie project",
				effects = { Happiness = 18, Money = -50000 },
				fameEffect = 10,
				setFlags = { artsy_comeback = true },
				feed = "Critics praised your artistic growth.",
			},
		},
	},
	
	-- SUPER BOWL HALFTIME
	{
		id = "superbowl_halftime",
		title = "🏈 Super Bowl Halftime",
		emoji = "🏈",
		text = "You've been invited to headline the Super Bowl halftime show. THE biggest stage in entertainment.",
		minFame = 80,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { did_superbowl = true } },
		choices = {
			{
				text = "Pull out all the stops",
				effects = { Happiness = 30, Money = -1000000 },
				fameEffect = 20,
				setFlags = { did_superbowl = true, legendary_performance = true },
				feed = "The most-watched performance of the decade!",
			},
			{
				text = "Bring out surprise guests",
				effects = { Happiness = 25 },
				fameEffect = 25,
				setFlags = { did_superbowl = true, surprise_guests = true },
				feed = "The surprise appearances broke the internet!",
			},
			{
				text = "Focus on the music, not spectacle",
				effects = { Happiness = 20 },
				fameEffect = 12,
				setFlags = { did_superbowl = true, purist_performance = true },
				feed = "A stripped-down but powerful show.",
			},
		},
	},
	
	-- TABLOID LIES
	{
		id = "tabloid_lies",
		title = "📰 Tabloid Lies",
		emoji = "📰",
		text = "A major tabloid printed completely false stories about you. The lies are spreading everywhere.",
		minFame = 35,
		cooldown = 5,
		maxOccurrences = 5,
		choices = {
			{
				text = "Sue for defamation",
				effects = { Happiness = -10, Money = -500000 },
				successChance = 60,
				successFame = 10,
				successMoney = 2000000,
				successFeed = "You won the lawsuit!",
				failFame = -5,
				failFeed = "The case was dismissed.",
			},
			{
				text = "Address it publicly on social media",
				effects = { Happiness = 5 },
				fameEffect = 5,
				feed = "Your fans rallied to support you.",
			},
			{
				text = "Ignore it and move on",
				effects = { Happiness = -5 },
				fameEffect = -5,
				feed = "Some believed the lies.",
			},
			{
				text = "Post receipts proving them wrong",
				effects = { Happiness = 15 },
				fameEffect = 15,
				setFlags = { exposed_tabloid = true },
				feed = "The evidence destroyed their credibility!",
			},
		},
	},
	
	-- FAN MEETUP
	{
		id = "surprise_fan_meetup",
		title = "👋 Fan Meet",
		emoji = "👋",
		text = "Your fans organized a massive meetup hoping you'd show. Word got back to your team.",
		minFame = 45,
		cooldown = 4,
		maxOccurrences = 8,
		choices = {
			{
				text = "Surprise them by showing up!",
				effects = { Happiness = 25 },
				fameEffect = 15,
				setFlags = { loves_fans = true },
				feed = "Fans cried tears of joy! Videos went viral!",
			},
			{
				text = "Send a video message instead",
				effects = { Happiness = 10 },
				fameEffect = 8,
				feed = "They appreciated the acknowledgment.",
			},
			{
				text = "Send them merchandise",
				effects = { Happiness = 8, Money = -10000 },
				fameEffect = 5,
				feed = "Free swag is always welcome.",
			},
			{
				text = "Ignore it",
				effects = { Happiness = 0 },
				fameEffect = -5,
				feed = "Some fans were disappointed.",
			},
		},
	},
	
	-- MENTORSHIP OPPORTUNITY
	{
		id = "mentor_rising_star",
		title = "🌟 Mentoring Talent",
		emoji = "🌟",
		text = "A young rising star wants you to mentor them. You could shape the next generation.",
		minFame = 60,
		cooldown = 6,
		maxOccurrences = 3,
		choices = {
			{
				text = "Take them under your wing",
				effects = { Happiness = 15, Smarts = 5 },
				fameEffect = 10,
				setFlags = { industry_mentor = true },
				feed = "Your mentee is rising fast!",
			},
			{
				text = "Collaborate on a project together",
				effects = { Happiness = 12, Money = 100000 },
				fameEffect = 12,
				setFlags = { collaborative_mentor = true },
				feed = "The cross-generational collab is a hit!",
			},
			{
				text = "Decline - you're too busy",
				effects = { Happiness = 0 },
				fameEffect = -3,
				feed = "Opportunity to give back missed.",
			},
		},
	},
	
	-- VEGAS RESIDENCY
	{
		id = "vegas_residency_offer",
		title = "🎰 Vegas Residency",
		emoji = "🎰",
		text = "A Las Vegas casino wants you for a multi-year residency. Guaranteed income, less travel.",
		minFame = 65,
		cooldown = 10,
		maxOccurrences = 2,
		conditions = { blockedFlags = { has_residency = true } },
		choices = {
			{
				text = "Accept the lucrative deal",
				effects = { Happiness = 12, Money = 5000000 },
				fameEffect = 10,
				setFlags = { has_residency = true, vegas_star = true },
				feed = "Your Vegas show is sold out for years!",
			},
			{
				text = "Negotiate for shorter commitment",
				effects = { Happiness = 10, Money = 2000000 },
				fameEffect = 8,
				setFlags = { has_residency = true },
				feed = "A flexible arrangement.",
			},
			{
				text = "Decline - need to stay on the road",
				effects = { Happiness = 5 },
				fameEffect = 0,
				feed = "You prefer touring the world.",
			},
		},
	},
	
	-- MOVIE PREMIERE
	{
		id = "movie_premiere_event",
		title = "🎬 World Premiere",
		emoji = "🎬",
		text = "It's the world premiere of your biggest movie! The red carpet stretches endlessly.",
		minFame = 50,
		cooldown = 4,
		maxOccurrences = 8,
		choices = {
			{
				text = "Wear a show-stopping outfit",
				effects = { Happiness = 18, Money = -50000 },
				fameEffect = 15,
				setFlags = { fashion_risk_taker = true },
				feed = "Your outfit dominated headlines!",
			},
			{
				text = "Focus on thanking the cast and crew",
				effects = { Happiness = 15, Smarts = 3 },
				fameEffect = 10,
				setFlags = { gracious_star = true },
				feed = "Your humility was noted.",
			},
			{
				text = "Bring your biggest fans to the premiere",
				effects = { Happiness = 20 },
				fameEffect = 18,
				setFlags = { fan_favorite = true },
				feed = "The fans-on-carpet moment went viral!",
			},
			{
				text = "Skip the red carpet entirely",
				effects = { Happiness = 5 },
				fameEffect = -5,
				feed = "People wondered where you were.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #465: ADDITIONAL CELEBRITY EVENTS FOR DEEPER GAMEPLAY
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- BRAND DEAL CONTROVERSY
	{
		id = "brand_deal_controversy",
		title = "💰 Problematic Sponsor",
		emoji = "💰",
		text = "One of your sponsors has been exposed for unethical practices. You're associated with their brand.",
		minFame = 45,
		cooldown = 8,
		maxOccurrences = 2,
		choices = {
			{
				text = "Drop them immediately and publicly",
				effects = { Happiness = 10, Money = -200000 },
				fameEffect = 15,
				setFlags = { ethical_celebrity = true },
				feed = "Your quick action was praised!",
			},
			{
				text = "Stay quiet and let the contract expire",
				effects = { Happiness = -10 },
				fameEffect = -15,
				feed = "Your silence was noticed. And criticized.",
			},
			{
				text = "Donate your earnings to charity",
				effects = { Happiness = 15, Money = -300000 },
				fameEffect = 20,
				setFlags = { charitable_celebrity = true },
				feed = "You turned a scandal into something positive!",
			},
		},
	},
	
	-- MUSIC STREAMING DISPUTE
	{
		id = "streaming_dispute",
		title = "🎵 Streaming Fight",
		emoji = "🎵",
		text = "You're unhappy with what streaming platforms pay artists. Will you take a stand?",
		minFame = 55,
		cooldown = 10,
		maxOccurrences = 2,
		choices = {
			{
				text = "Remove your music from all platforms",
				effects = { Happiness = 5, Money = -500000 },
				fameEffect = 20,
				setFlags = { streaming_boycott = true },
				feed = "A bold move that sparked industry debate!",
			},
			{
				text = "Release a statement but stay on platforms",
				effects = { Happiness = 3 },
				fameEffect = 8,
				feed = "Words without action. Some were disappointed.",
			},
			{
				text = "Start your own platform",
				effects = { Happiness = 15, Money = -2000000, Smarts = 8 },
				fameEffect = 25,
				setFlags = { tech_entrepreneur = true },
				feed = "You're now a tech mogul too!",
			},
		},
	},
	
	-- PUBLICITY STUNT
	{
		id = "publicity_stunt_opportunity",
		title = "🎪 Publicity Stunt",
		emoji = "🎪",
		text = "Your PR team proposes an outrageous publicity stunt. It's risky but could get massive attention.",
		minFame = 35,
		cooldown = 6,
		maxOccurrences = 4,
		choices = {
			{
				text = "Go for it - all attention is good attention",
				effects = { Happiness = 15 },
				successChance = 60,
				successFame = 20,
				successFeed = "It worked! Everyone's talking about you!",
				failFame = -15,
				failFeed = "That backfired spectacularly.",
			},
			{
				text = "Tone it down to something safer",
				effects = { Happiness = 8 },
				fameEffect = 8,
				feed = "Moderate buzz. Safe but not viral.",
			},
			{
				text = "Decline - protect your image",
				effects = { Happiness = 5 },
				fameEffect = 0,
				setFlags = { plays_it_safe = true },
				feed = "Your brand stays consistent.",
			},
		},
	},
	
	-- PERSONAL LIFE EXPOSED
	{
		id = "personal_life_exposed",
		title = "📸 Private Photos Leaked",
		emoji = "📸",
		text = "Private photos of you were leaked online. Your privacy has been violated.",
		minFame = 40,
		cooldown = 12,
		maxOccurrences = 2,
		choices = {
			{
				text = "Take legal action aggressively",
				effects = { Happiness = -10, Money = -500000 },
				fameEffect = 10,
				setFlags = { privacy_fighter = true },
				feed = "You're fighting back through the courts.",
			},
			{
				text = "Address it and move on",
				effects = { Happiness = -5 },
				fameEffect = 5,
				feed = "You handled it with grace.",
			},
			{
				text = "Turn it into a body positivity moment",
				effects = { Happiness = 10 },
				fameEffect = 20,
				setFlags = { body_positive = true },
				feed = "You transformed violation into empowerment!",
			},
		},
	},
	
	-- CELEBRITY FEUD
	{
		id = "celebrity_feud",
		title = "🔥 Celebrity Feud",
		emoji = "🔥",
		text = "Another celebrity made shady comments about you. The internet is waiting for your response.",
		minFame = 45,
		cooldown = 5,
		maxOccurrences = 4,
		choices = {
			{
				text = "Epic clap back on social media",
				effects = { Happiness = 10 },
				fameEffect = 15,
				setFlags = { clap_back_champion = true },
				feed = "Your response was legendary!",
			},
			{
				text = "Take the high road publicly",
				effects = { Happiness = 8, Smarts = 5 },
				fameEffect = 10,
				setFlags = { takes_high_road = true },
				feed = "Maturity wins. Most people respect that.",
			},
			{
				text = "Collab with them as a peace treaty",
				effects = { Happiness = 15 },
				fameEffect = 20,
				setFlags = { peacemaker = true },
				feed = "The unexpected collab broke the internet!",
			},
			{
				text = "Ignore completely",
				effects = { Happiness = 3 },
				fameEffect = 0,
				feed = "No engagement. The drama died down.",
			},
		},
	},
	
	-- FAN SAVES YOUR LIFE
	{
		id = "fan_saves_life",
		title = "🦸 Heroic Fan",
		emoji = "🦸",
		text = "A fan literally saved your life in an emergency situation. The story is everywhere.",
		minFame = 50,
		oneTime = true,
		maxOccurrences = 1,
		choices = {
			{
				text = "Meet them privately and thank them",
				effects = { Happiness = 20 },
				fameEffect = 10,
				setFlags = { grateful_celebrity = true },
				feed = "A genuine private moment.",
			},
			{
				text = "Grand public gesture of thanks",
				effects = { Happiness = 18, Money = -50000 },
				fameEffect = 20,
				setFlags = { generous_celebrity = true },
				feed = "You changed their life forever!",
			},
			{
				text = "Feature them in your next project",
				effects = { Happiness = 25 },
				fameEffect = 25,
				setFlags = { fan_champion = true },
				feed = "The ultimate fan wish came true!",
			},
		},
	},
	
	-- LIFETIME ACHIEVEMENT
	{
		id = "lifetime_achievement_award",
		title = "🏆 Lifetime Achievement",
		emoji = "🏆",
		text = "You're being honored with a Lifetime Achievement Award. A career milestone!",
		minFame = 80,
		oneTime = true,
		maxOccurrences = 1,
		choices = {
			{
				text = "Accept with emotional speech",
				effects = { Happiness = 30 },
				fameEffect = 15,
				setFlags = { lifetime_achievement = true },
				feed = "There wasn't a dry eye in the house.",
			},
			{
				text = "Use the platform for a cause",
				effects = { Happiness = 25, Smarts = 5 },
				fameEffect = 20,
				setFlags = { lifetime_achievement = true, activist_celebrity = true },
				feed = "You used your moment to spotlight an issue.",
			},
			{
				text = "Decline - you're not done yet",
				effects = { Happiness = 10 },
				fameEffect = 10,
				setFlags = { still_going = true },
				feed = "You're not ready to be a legend yet. Respect.",
			},
		},
	},
	
	-- BIOPIC ANNOUNCEMENT
	{
		id = "biopic_announcement",
		title = "🎬 Your Biopic",
		emoji = "🎬",
		text = "Hollywood wants to make a movie about your life! You have some creative control.",
		minFame = 70,
		oneTime = true,
		maxOccurrences = 1,
		choices = {
			{
				text = "Let them tell the full story",
				effects = { Happiness = 15, Money = 1000000 },
				fameEffect = 20,
				setFlags = { has_biopic = true },
				feed = "The unfiltered story. Warts and all.",
			},
			{
				text = "Demand a sanitized version",
				effects = { Happiness = 10, Money = 500000 },
				fameEffect = 10,
				setFlags = { has_biopic = true },
				feed = "A polished but less compelling story.",
			},
			{
				text = "Play yourself in it",
				effects = { Happiness = 25, Smarts = 5 },
				fameEffect = 25,
				setFlags = { has_biopic = true, played_self = true },
				feed = "Bold and meta! Critics loved it!",
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

function CelebrityEvents.getFameLevelInfo(fameValue)
	for _, level in ipairs(CelebrityEvents.FameLevels) do
		if fameValue >= level.min and fameValue <= level.max then
			return level
		end
	end
	return CelebrityEvents.FameLevels[#CelebrityEvents.FameLevels]
end

function CelebrityEvents.getCareerByPath(pathId)
	local careers = {
		actor = CelebrityEvents.ActingCareer,
		musician = CelebrityEvents.MusicCareer,
		influencer = CelebrityEvents.InfluencerCareer,
		athlete = CelebrityEvents.AthleteCareer,
		model = CelebrityEvents.ModelCareer,
	}
	return careers[pathId]
end

function CelebrityEvents.getStageByIndex(career, stageIndex)
	if career and career.stages and career.stages[stageIndex] then
		return career.stages[stageIndex]
	end
	return nil
end

function CelebrityEvents.calculateYearlySalary(career, stageIndex)
	local stage = CelebrityEvents.getStageByIndex(career, stageIndex)
	if stage then
		return math.random(stage.salary.min, stage.salary.max)
	end
	return 0
end

function CelebrityEvents.checkPromotion(lifeState)
	local fameState = lifeState.FameState
	if not fameState then
		return false, nil
	end
	
	local career = CelebrityEvents.getCareerByPath(fameState.careerPath)
	if not career then
		return false, nil
	end
	
	local currentStage = career.stages[fameState.currentStage]
	local nextStage = career.stages[fameState.currentStage + 1]
	
	if not nextStage then
		return false, nil -- Already at max stage
	end
	
	-- Check fame requirement
	if lifeState.Fame >= nextStage.fameRequired then
		-- Check years requirement
		local yearsInStage = fameState.yearsInCareer - (fameState.lastPromotionYear or 0)
		local minYears = currentStage.yearsToAdvance and currentStage.yearsToAdvance.min or 1
		
		if yearsInStage >= minYears then
			return true, nextStage
		end
	end
	
	return false, nil
end

function CelebrityEvents.promoteToStage(lifeState, stageIndex)
	local fameState = lifeState.FameState
	if not fameState then
		return false
	end
	
	local career = CelebrityEvents.getCareerByPath(fameState.careerPath)
	if not career then
		return false
	end
	
	local stage = career.stages[stageIndex]
	if not stage then
		return false
	end
	
	fameState.currentStage = stageIndex
	fameState.stageName = stage.name
	fameState.lastPromotionYear = fameState.yearsInCareer
	
	-- Update salary
	if lifeState.CurrentJob then
		lifeState.CurrentJob.salary = math.random(stage.salary.min, stage.salary.max)
		lifeState.CurrentJob.name = stage.name
	end
	
	return true
end

function CelebrityEvents.initializeFameCareer(lifeState, careerPath, subType)
	local career = CelebrityEvents.getCareerByPath(careerPath)
	if not career then
		return false, "Invalid career path"
	end
	
	local firstStage = career.stages[1]
	
	lifeState.FameState = {
		isFamous = false,
		careerPath = careerPath,
		careerName = career.name,
		currentStage = 1,
		stageName = firstStage.name,
		subType = subType, -- e.g., genre for music, sport for athlete
		yearsInCareer = 0,
		lastPromotionYear = 0,
		followers = firstStage.followers or 0,
		endorsements = {},
		awards = {},
		scandals = 0,
	}
	
	lifeState.CurrentJob = {
		id = careerPath .. "_" .. firstStage.id,
		name = firstStage.name,
		company = career.name .. " Industry",
		salary = math.random(firstStage.salary.min, firstStage.salary.max),
		category = "entertainment",
		isFameCareer = true,
	}
	
	lifeState.Flags = lifeState.Flags or {}
	lifeState.Flags.fame_career = true
	lifeState.Flags["career_" .. careerPath] = true
	
	return true, string.format("Started career as %s!", firstStage.name)
end

function CelebrityEvents.processYearlyFameUpdates(lifeState)
	local fameState = lifeState.FameState
	if not fameState then
		return {}
	end
	
	local events = {}
	local career = CelebrityEvents.getCareerByPath(fameState.careerPath)
	if not career then
		return events
	end
	
	fameState.yearsInCareer = fameState.yearsInCareer + 1
	
	local currentStage = career.stages[fameState.currentStage]
	
	-- Fame gain
	local fameGain = math.random(currentStage.fameGainPerYear.min, currentStage.fameGainPerYear.max)
	lifeState.Fame = math.min(100, (lifeState.Fame or 0) + fameGain)
	
	-- Update salary
	if lifeState.CurrentJob then
		lifeState.CurrentJob.salary = math.random(currentStage.salary.min, currentStage.salary.max)
		lifeState.Money = (lifeState.Money or 0) + lifeState.CurrentJob.salary
	end
	
	-- Check promotion
	local canPromote, nextStage = CelebrityEvents.checkPromotion(lifeState)
	if canPromote then
		CelebrityEvents.promoteToStage(lifeState, fameState.currentStage + 1)
		table.insert(events, {
			type = "promotion",
			message = string.format("🎉 You've been promoted to %s!", nextStage.name),
		})
	end
	
	-- Random career event
	-- CRITICAL FIX #117: Add nil safety for career events with proper stage checking
	if career.events and #career.events > 0 then
		if math.random(100) <= 15 then
			local possibleEvents = {}
			local currentStage = fameState.currentStage or 1
			for _, event in ipairs(career.events) do
				-- CRITICAL FIX #118: Default minStage and maxStage to prevent nil comparisons
				local minStage = event.minStage or 1
				local maxStage = event.maxStage or 999
				if currentStage >= minStage and currentStage <= maxStage then
					table.insert(possibleEvents, event)
				end
			end
			if #possibleEvents > 0 then
				local chosenEvent = possibleEvents[math.random(1, #possibleEvents)]
				table.insert(events, {
					type = "career_event",
					event = chosenEvent,
				})
			end
		end
	end
	
	-- Update fame status
	local fameLevel = CelebrityEvents.getFameLevelInfo(lifeState.Fame)
	fameState.isFamous = lifeState.Fame >= 30
	fameState.fameLevel = fameLevel.name
	
	return events
end

function CelebrityEvents.getAvailableFameEvents(lifeState)
	local fame = lifeState.Fame or 0
	local availableEvents = {}
	
	for _, event in ipairs(CelebrityEvents.GeneralFameEvents) do
		if fame >= event.minFame then
			table.insert(availableEvents, event)
		end
	end
	
	return availableEvents
end

function CelebrityEvents.getRandomFameEvent(lifeState)
	local availableEvents = CelebrityEvents.getAvailableFameEvents(lifeState)
	if #availableEvents == 0 then
		return nil
	end
	return availableEvents[math.random(1, #availableEvents)]
end

-- ════════════════════════════════════════════════════════════════════════════
-- SERIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

function CelebrityEvents.serializeFameState(lifeState)
	local fameState = lifeState.FameState
	if not fameState then
		return {
			isFamous = false,
			fame = lifeState.Fame or 0,
		}
	end
	
	local fameLevel = CelebrityEvents.getFameLevelInfo(lifeState.Fame or 0)
	
	return {
		isFamous = fameState.isFamous,
		fame = lifeState.Fame or 0,
		fameLevelName = fameLevel.name,
		fameLevelEmoji = fameLevel.emoji,
		careerPath = fameState.careerPath,
		careerName = fameState.careerName,
		currentStage = fameState.currentStage,
		stageName = fameState.stageName,
		subType = fameState.subType,
		yearsInCareer = fameState.yearsInCareer,
		followers = fameState.followers,
		endorsements = fameState.endorsements,
		awards = fameState.awards,
		scandals = fameState.scandals,
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #42: Export events in standard format for LifeEvents loader
-- The init.lua module loader expects .events, .Events, or .LifeEvents array
-- Combines GeneralFameEvents with all career-specific events
-- ════════════════════════════════════════════════════════════════════════════
CelebrityEvents.events = {}

-- Add general fame events
for _, event in ipairs(CelebrityEvents.GeneralFameEvents or {}) do
	event.isCelebrityOnly = true
	event.minAge = event.minAge or 16
	event.maxAge = event.maxAge or 99
	table.insert(CelebrityEvents.events, event)
end

-- Add acting career events with proper tagging
if CelebrityEvents.ActingCareer and CelebrityEvents.ActingCareer.events then
	for _, event in ipairs(CelebrityEvents.ActingCareer.events) do
		event.isCelebrityOnly = true
		event.careerPath = "actor"
		event.minAge = event.minAge or 18
		event.maxAge = event.maxAge or 99
		table.insert(CelebrityEvents.events, event)
	end
end

-- Add music career events with proper tagging
if CelebrityEvents.MusicCareer and CelebrityEvents.MusicCareer.events then
	for _, event in ipairs(CelebrityEvents.MusicCareer.events) do
		event.isCelebrityOnly = true
		event.careerPath = "musician"
		event.minAge = event.minAge or 16
		event.maxAge = event.maxAge or 99
		table.insert(CelebrityEvents.events, event)
	end
end

-- Add influencer career events with proper tagging
if CelebrityEvents.InfluencerCareer and CelebrityEvents.InfluencerCareer.events then
	for _, event in ipairs(CelebrityEvents.InfluencerCareer.events) do
		event.isCelebrityOnly = true
		event.careerPath = "influencer"
		event.minAge = event.minAge or 13
		event.maxAge = event.maxAge or 99
		table.insert(CelebrityEvents.events, event)
	end
end

-- Also expose as LifeEvents for backwards compatibility
CelebrityEvents.LifeEvents = CelebrityEvents.events

return CelebrityEvents
