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
	{
		id = "paparazzi_chase",
		title = "📸 Paparazzi Chase!",
		emoji = "📸",
		text = "Paparazzi are following you everywhere! They're getting dangerously close.",
		minFame = 30,
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
	{
		id = "fan_encounter",
		title = "😍 Fan Encounter!",
		emoji = "😍",
		text = "A fan recognizes you and wants a photo and autograph!",
		minFame = 20,
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
	{
		id = "stalker",
		title = "😰 Stalker Situation",
		emoji = "😰",
		text = "Someone has been obsessively following you. They've shown up at your home.",
		minFame = 50,
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
	if career.events and #career.events > 0 then
		if math.random(100) <= 15 then
			local possibleEvents = {}
			for _, event in ipairs(career.events) do
				if fameState.currentStage >= event.minStage and fameState.currentStage <= event.maxStage then
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
