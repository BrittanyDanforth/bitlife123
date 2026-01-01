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

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #16: Added minStats requirements to celebrity careers
-- Actors need Looks, Athletes need Health, Musicians need Smarts for composition
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.ActingCareer = {
	name = "Acting",
	emoji = "🎬",
	description = "Pursue a career in film and television",
	minStartAge = 6,
	maxStartAge = 50,
	-- CRITICAL FIX #16: Acting requires Looks for on-screen presence
	primaryStat = "Looks",
	minStartStat = 40, -- Need decent looks to start
	
	stages = {
		{
			id = "extra",
			name = "Extra",
			emoji = "👥",
			salary = { min = 500, max = 2000 },
			fameRequired = 0,
			minStats = { Looks = 30 }, -- Anyone can be an extra
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
			minStats = { Looks = 40 }, -- Need to look decent on camera
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
			minStats = { Looks = 50, Smarts = 30 }, -- Need memorization skills
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
			minStats = { Looks = 55, Smarts = 40 }, -- Need to carry scenes
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
			minStats = { Looks = 60 }, -- Hollywood standards
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
			minStats = { Looks = 65, Smarts = 50 }, -- Need to carry a show
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
			minStats = { Looks = 70 }, -- Leading actor material
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
			minStats = { Looks = 75 }, -- Hollywood elite
			fameGainPerYear = { min = 5, max = 10 },
			yearsToAdvance = { min = 5, max = 10 },
			description = "Hollywood's elite",
			activities = { "Choose your projects", "Command huge salaries", "Set trends" },
		},
		{
			id = "acting_legend", -- CRITICAL FIX: Renamed from "legend" to avoid duplicate ID with athlete career
			name = "Hollywood Legend",
			emoji = "👑",
			salary = { min = 25000000, max = 100000000 },
			fameRequired = 95,
			minStats = { Looks = 70 }, -- Legends can age gracefully
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
			id = "music_superstar", -- CRITICAL FIX: Renamed from "superstar" to avoid duplicate ID with athlete career
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
			id = "music_icon", -- CRITICAL FIX: Renamed from "icon" to avoid duplicate ID with influencer/model careers
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
			id = "influencer_icon", -- CRITICAL FIX: Renamed from "icon" to avoid duplicate ID with music/model careers
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
			id = "athlete_amateur", -- CRITICAL FIX: Renamed from "amateur" to avoid duplicate ID with model career
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
			id = "athlete_allstar", -- CRITICAL FIX: Renamed from "allstar" to avoid duplicate ID with AwardTypes
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
			id = "athlete_superstar", -- CRITICAL FIX: Renamed from "superstar" to avoid duplicate ID with music career
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
			id = "athlete_legend", -- CRITICAL FIX: Renamed from "legend" to avoid duplicate ID with acting career
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
			id = "model_amateur", -- CRITICAL FIX: Renamed from "amateur" to avoid duplicate ID with athlete career
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
			id = "model_catalog_stage", -- CRITICAL FIX: Renamed from "catalog" to avoid conflict with model type ID
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
			id = "model_commercial_stage", -- CRITICAL FIX: Renamed from "commercial" to avoid conflict with model type ID
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
			id = "model_fashion_stage", -- CRITICAL FIX: Renamed from "fashion" to avoid conflict with model type ID
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
			id = "model_icon", -- CRITICAL FIX: Renamed from "icon" to avoid duplicate ID with music/influencer careers
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam -- CRITICAL FIX: 2 year cooldown between paparazzi events
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam -- CRITICAL FIX: 2 year cooldown
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
		cooldown = 4, -- CRITICAL FIX: 10 year cooldown if it happens again
		choices = {
			{
				text = "Get a restraining order",
				effects = { Happiness = -10 },
				fameEffect = 0,
				setFlags = { had_stalker = true },
				feed = "You took legal action for your safety.",
			},
			{
				text = "Hire more security ($100K)",
				effects = { Happiness = -5, Money = -100000 },
				fameEffect = 0,
				setFlags = { increased_security = true },
				feed = "You beefed up your security team.",
				eligibility = function(state) return (state.Money or 0) >= 100000, "💸 Need $100K for security" end,
			},
			{
				text = "Move to a new location ($500K)",
				effects = { Happiness = -15, Money = -500000 },
				fameEffect = -5,
				feed = "You had to relocate for safety.",
				eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K to relocate" end,
			},
		},
	},
	
	-- ENDORSEMENT DEAL
	{
		id = "endorsement_deal",
		title = "💰 Endorsement Opportunity!",
		emoji = "💰",
		-- CRITICAL FIX: Added text variants for variety!
		textVariants = {
			"A major brand wants you to endorse their product!",
			"A sports drink company reached out - they want YOU as their face!",
			"A luxury watch brand is offering a massive deal for you to be their ambassador!",
			"A clothing line wants you in their next campaign. Big bucks on the table!",
			"A tech company thinks you'd be perfect for their new product launch!",
			"A makeup/skincare brand is offering millions for your endorsement!",
			"A car manufacturer wants you to be their celebrity spokesperson!",
		},
		text = "A major brand wants you to endorse their product!",
		minFame = 40,
		cooldown = 3, -- CRITICAL FIX: Prevent spam
		maxOccurrences = 6, -- CRITICAL FIX: Limit endorsements per life
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
		-- CRITICAL FIX: Added text variants for variety!
		textVariants = {
			"A tabloid is running a story about you. It's completely made up!",
			"BREAKING: You're on the cover of a gossip magazine with a FAKE scandal!",
			"Paparazzi caught you at the worst angle. Now there's a story about 'your secret struggles'!",
			"An 'anonymous source' told a tabloid complete lies about your personal life!",
			"A gossip site is claiming you had a public meltdown. You were just having lunch!",
			"Rumors are swirling that you're feuding with another celebrity. News to you!",
			"A magazine claims you're secretly broke. Your accountant begs to differ.",
		},
		text = "A tabloid is running a story about you. It's completely made up!",
		minFame = 35,
		cooldown = 3, -- CRITICAL FIX: Prevent spam
		maxOccurrences = 5, -- CRITICAL FIX: Limit tabloid stories
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
				-- CRITICAL FIX: Show price!
				text = "Sue for defamation ($50K)",
				effects = { Happiness = -8, Money = -50000 },
				successChance = 60,
				successEffects = { Happiness = 15, Money = 500000 },
				successFame = 10,
				successFeed = "You won the lawsuit!",
				failEffects = { Happiness = -10, Money = -200000 },
				failFame = -5,
				failFeed = "You lost the case.",
				eligibility = function(state) return (state.Money or 0) >= 50000, "💸 Need $50K for legal fees" end,
			},
		},
	},
	
	-- AWARD SHOW INVITE
	{
		id = "award_show_invite",
		title = "🏆 Award Show Invitation!",
		emoji = "🏆",
		-- CRITICAL FIX: Added text variants for variety!
		textVariants = {
			"You've been invited to present at a major award show!",
			"The Grammy/Emmy/Oscar producers want you to present an award! Red carpet time!",
			"You've been nominated for a major industry award! Will you win?",
			"The People's Choice Awards wants you to accept the Favorite Star award!",
			"A prestigious ceremony invited you as a presenter AND a nominee!",
			"You've been asked to host a segment at this year's biggest award show!",
		},
		text = "You've been invited to present at a major award show!",
		minFame = 45,
		cooldown = 3, -- CRITICAL FIX: Prevent spam
		maxOccurrences = 6, -- CRITICAL FIX: Limit award invites
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
		cooldown = 3, -- CRITICAL FIX: Prevent spam (once per 3 years is enough)
		maxOccurrences = 8, -- CRITICAL FIX: Limit red carpet events
		choices = {
			{
				text = "Wear designer outfit ($50K)",
				effects = { Happiness = 10, Money = -50000 },
				fameEffect = 8,
				feed = "You looked stunning on the red carpet!",
				eligibility = function(state) return (state.Money or 0) >= 50000, "💸 Need $50K for designer outfit" end,
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
		cooldown = 3, -- CRITICAL FIX: Prevent spam
		maxOccurrences = 8, -- CRITICAL FIX: Limit interviews
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
		cooldown = 5, -- CRITICAL FIX: Prevent spam
		maxOccurrences = 3, -- CRITICAL FIX: Limit charity offers
		choices = {
			{
				-- CRITICAL FIX: Show donation cost!
				text = "Accept and commit ($100K donation)",
				effects = { Happiness = 15, Money = -100000 },
				fameEffect = 15,
				setFlags = { charity_ambassador = true },
				feed = "You became a voice for an important cause!",
				eligibility = function(state) return (state.Money or 0) >= 100000, "💸 Need $100K for charity donation" end,
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
		cooldown = 5, -- CRITICAL FIX: Prevent spam
		maxOccurrences = 3, -- CRITICAL FIX: Limit scandals
		choices = {
			{
				text = "Pay them off ($500K)",
				effects = { Money = -500000 },
				fameEffect = 0,
				setFlags = { paid_blackmail = true },
				feed = "You made the problem go away... for now.",
				eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K to pay off" end,
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
		-- CRITICAL FIX: Renamed to avoid duplicate ID
		id = "celebrity_viral_clip",
		title = "📱 Going Viral!",
		emoji = "📱",
		text = "Something you did went incredibly viral! Millions of people have seen it.",
		minFame = 15,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
				text = "Launch a fashion line ($500K)",
				effects = { Happiness = 15, Money = -500000 },
				successChance = 60,
				successFame = 15,
				successFeed = "Your fashion line is a hit!",
				failFame = -5,
				failFeed = "Your fashion line flopped.",
				setFlags = { entrepreneur = true },
				eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K to launch fashion line" end,
			},
			{
				text = "Launch a beauty brand ($300K)",
				effects = { Happiness = 12, Money = -300000 },
				successChance = 70,
				successFame = 12,
				successFeed = "Your beauty brand is selling out!",
				setFlags = { entrepreneur = true },
				eligibility = function(state) return (state.Money or 0) >= 300000, "💸 Need $300K to launch beauty brand" end,
			},
			-- CRITICAL FIX: FREE option to prevent hard lock!
			{
				text = "Partner with existing brand (licensing)",
				effects = { Happiness = 10 },
				successChance = 75,
				successFame = 8,
				successFeed = "👔 Your name on their products! Getting royalty checks without the risk!",
				failFame = -2,
				failFeed = "Deal fell through. Business is tough.",
				setFlags = { brand_partner = true },
			},
			{
				text = "Wait for the right opportunity",
				effects = { Happiness = -2, Smarts = 3 },
				feed = "👔 Not ready yet. Building more fame and capital first. Smart.",
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Campaign hard to win ($100K)",
				effects = { Happiness = 10, Money = -100000 },
				successChance = 40,
				successFame = 25,
				successFeed = "YOU WON!",
				setFlags = { award_winner = true },
				eligibility = function(state) return (state.Money or 0) >= 100000, "💸 Need $100K for campaign" end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
				-- CRITICAL FIX: Show price!
				text = "Start a foundation ($500K)",
				effects = { Happiness = 25, Money = -500000 },
				fameEffect = 20,
				setFlags = { has_foundation = true },
				feed = "Your foundation will help millions.",
				eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K for foundation" end,
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
		cooldown = 3,
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
		-- CRITICAL FIX: Renamed to avoid duplicate ID
		id = "celebrity_viral_moment",
		title = "📱 Viral Moment",
		emoji = "📱",
		text = "Something you did just went viral! Millions are watching, sharing, and talking about you.",
		minFame = 20,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4,
		maxOccurrences = 2,
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Get a restraining order ($20K)",
				effects = { Happiness = -10, Money = -20000 },
				fameEffect = 0,
				setFlags = { has_restraining_order = true },
				feed = "The courts are handling it now.",
				eligibility = function(state) return (state.Money or 0) >= 20000, "💸 Need $20K for legal fees" end,
			},
			{
				-- CRITICAL FIX: Show price!
				text = "Upgrade security ($100K)",
				effects = { Happiness = 5, Money = -100000 },
				fameEffect = 0,
				setFlags = { heavy_security = true },
				feed = "You now travel with bodyguards everywhere.",
				eligibility = function(state) return (state.Money or 0) >= 100000, "💸 Need $100K for security" end,
			},
			{
				-- CRITICAL FIX: Show price!
				text = "Move to a new location ($500K)",
				effects = { Happiness = -5, Money = -500000 },
				fameEffect = 0,
				setFlags = { changed_residence = true },
				feed = "Fresh start, new address, new peace.",
				eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K for new residence" end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
				-- CRITICAL FIX: Show price!
				text = "Donate $1M yourself",
				effects = { Happiness = 20, Money = -1000000 },
				fameEffect = 15,
				setFlags = { generous_celebrity = true },
				feed = "Your generosity made headlines!",
				eligibility = function(state) return (state.Money or 0) >= 1000000, "💸 Need $1M to donate" end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 5,
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Go all out with production ($200K)",
				effects = { Happiness = 20, Money = -200000 },
				fameEffect = 18,
				setFlags = { show_stopper = true },
				feed = "Everyone's talking about your performance!",
				eligibility = function(state) return (state.Money or 0) >= 200000, "💸 Need $200K for production" end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
		-- CRITICAL FIX: Renamed from "reality_tv_offer" to avoid duplicate ID
		id = "celebrity_reality_show",
		title = "📺 Reality TV Offer",
		emoji = "📺",
		text = "Network executives want to document your life in a reality series. Fame and fortune, but zero privacy.",
		minFame = 30,
		cooldown = 3,
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
		cooldown = 4,
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
				-- CRITICAL FIX: Show price!
				text = "Low-key indie project ($50K)",
				effects = { Happiness = 18, Money = -50000 },
				fameEffect = 10,
				setFlags = { artsy_comeback = true },
				feed = "Critics praised your artistic growth.",
				eligibility = function(state) return (state.Money or 0) >= 50000, "💸 Need $50K for production" end,
			},
		},
	},
	
	-- SUPER BOWL HALFTIME
	-- CRITICAL FIX #MOBILE-15: Added strict eligibility check - this should ONLY fire for superstars!
	{
		id = "superbowl_halftime",
		title = "🏈 Super Bowl Halftime",
		emoji = "🏈",
		text = "You've been invited to headline the Super Bowl halftime show. THE biggest stage in entertainment.",
		minFame = 80,
		oneTime = true,
		maxOccurrences = 1,
		conditions = { blockedFlags = { did_superbowl = true } },
		-- CRITICAL FIX: Strict eligibility - must be a SUPERSTAR (Fame >= 80) with music career
		eligibility = function(state)
			local fame = state.Fame or 0
			if fame < 80 then
				return false, "Need superstar fame (80+) to headline Super Bowl"
			end
			-- Must be in music/entertainment career
			if state.CurrentJob then
				local category = (state.CurrentJob.category or ""):lower()
				local jobId = (state.CurrentJob.id or ""):lower()
				if category ~= "entertainment" and category ~= "music" and category ~= "celebrity" then
					if not (jobId:find("rapper") or jobId:find("singer") or jobId:find("musician") or jobId:find("artist")) then
						return false, "Not in a music career"
					end
				end
			else
				return false, "No entertainment job"
			end
			return true
		end,
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Pull out all the stops ($1M)",
				effects = { Happiness = 30, Money = -1000000 },
				fameEffect = 20,
				setFlags = { did_superbowl = true, legendary_performance = true },
				feed = "The most-watched performance of the decade!",
				eligibility = function(state) return (state.Money or 0) >= 1000000, "💸 Need $1M for epic production" end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 5,
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Sue for defamation ($500K)",
				effects = { Happiness = -10, Money = -500000 },
				successChance = 60,
				successFame = 10,
				successMoney = 2000000,
				successFeed = "You won the lawsuit!",
				failFame = -5,
				failFeed = "The case was dismissed.",
				eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K for lawsuit" end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
				-- CRITICAL FIX: Show price!
				text = "Send them merchandise ($10K)",
				effects = { Happiness = 8, Money = -10000 },
				fameEffect = 5,
				feed = "Free swag is always welcome.",
				eligibility = function(state) return (state.Money or 0) >= 10000, "💸 Need $10K for merchandise" end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
	
	-- CONCERT VENUE RESIDENCY
	{
		id = "venue_residency_offer",
		title = "🎤 Concert Residency",
		emoji = "🎤",
		text = "A famous concert venue wants you for a multi-year residency. Guaranteed income, less travel.",
		minFame = 65,
		cooldown = 4,
		maxOccurrences = 2,
		conditions = { blockedFlags = { has_residency = true } },
		choices = {
			{
				text = "Accept the lucrative deal",
				effects = { Happiness = 12, Money = 5000000 },
				fameEffect = 10,
				setFlags = { has_residency = true, concert_star = true },
				feed = "Your concert show is sold out for years!",
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 8,
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Wear a show-stopping outfit ($50K)",
				effects = { Happiness = 18, Money = -50000 },
				fameEffect = 15,
				setFlags = { fashion_risk_taker = true },
				feed = "Your outfit dominated headlines!",
				eligibility = function(state) return (state.Money or 0) >= 50000, "💸 Need $50K for designer outfit" end,
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
		cooldown = 3,
		maxOccurrences = 2,
		choices = {
			{
				-- CRITICAL FIX: Show price (contract termination)!
				text = "Drop them publicly ($200K penalty)",
				effects = { Happiness = 10, Money = -200000 },
				fameEffect = 15,
				setFlags = { ethical_celebrity = true },
				feed = "Your quick action was praised!",
				eligibility = function(state) return (state.Money or 0) >= 200000, "💸 Need $200K to break contract" end,
			},
			{
				text = "Stay quiet and let the contract expire",
				effects = { Happiness = -10 },
				fameEffect = -15,
				feed = "Your silence was noticed. And criticized.",
			},
			{
				-- CRITICAL FIX: Show price!
				text = "Donate earnings to charity ($300K)",
				effects = { Happiness = 15, Money = -300000 },
				fameEffect = 20,
				setFlags = { charitable_celebrity = true },
				feed = "You turned a scandal into something positive!",
				eligibility = function(state) return (state.Money or 0) >= 300000, "💸 Need $300K to donate" end,
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
		cooldown = 4,
		maxOccurrences = 2,
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Remove music from platforms ($500K loss)",
				effects = { Happiness = 5, Money = -500000 },
				fameEffect = 20,
				setFlags = { streaming_boycott = true },
				feed = "A bold move that sparked industry debate!",
				eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K to cover revenue loss" end,
			},
			{
				text = "Release a statement but stay on platforms",
				effects = { Happiness = 3 },
				fameEffect = 8,
				feed = "Words without action. Some were disappointed.",
			},
			{
				-- CRITICAL FIX: Show price!
				text = "Start your own platform ($2M)",
				effects = { Happiness = 15, Money = -2000000, Smarts = 8 },
				fameEffect = 25,
				setFlags = { tech_entrepreneur = true },
				feed = "You're now a tech mogul too!",
				eligibility = function(state) return (state.Money or 0) >= 2000000, "💸 Need $2M to start platform" end,
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
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
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
				-- CRITICAL FIX: Show price!
				text = "Take legal action ($500K)",
				effects = { Happiness = -10, Money = -500000 },
				fameEffect = 10,
				setFlags = { privacy_fighter = true },
				feed = "You're fighting back through the courts.",
				eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K for legal battle" end,
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
		-- CRITICAL FIX: Renamed to avoid ID collision
		id = "celebrity_feud_drama",
		title = "🔥 Celebrity Feud",
		emoji = "🔥",
		text = "Another celebrity made shady comments about you. The internet is waiting for your response.",
		minFame = 45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 4,
		category = "celebrity",
		tags = { "celebrity", "drama", "feud" },
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
				-- CRITICAL FIX: Show price!
				text = "Grand public gesture ($50K)",
				effects = { Happiness = 18, Money = -50000 },
				fameEffect = 20,
				setFlags = { generous_celebrity = true },
				feed = "You changed their life forever!",
				eligibility = function(state) return (state.Money or 0) >= 50000, "💸 Need $50K for gift" end,
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
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #71: EXPANDED CELEBRITY EVENTS FOR DEEPER GAMEPLAY
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	-- WORLD TOUR OFFER
	{
		id = "world_tour_offer",
		title = "🌍 World Tour Opportunity",
		emoji = "🌍",
		text = "A promoter wants to send you on a massive world tour. 50 cities, 6 months on the road.",
		minFame = 55,
		cooldown = 3,
		maxOccurrences = 3,
		choices = {
			{
				text = "Full commitment - 50 city tour",
				effects = { Happiness = 15, Health = -20, Money = 5000000 },
				fameEffect = 25,
				setFlags = { world_tour_veteran = true, road_warrior = true },
				feed = "Grueling but legendary! Fans worldwide saw you live!",
			},
			{
				text = "Scaled down - 20 major cities",
				effects = { Happiness = 10, Health = -10, Money = 2000000 },
				fameEffect = 15,
				setFlags = { toured_world = true },
				feed = "Hit the major markets. Solid tour!",
			},
			{
				text = "Decline - focus on studio work",
				effects = { Happiness = 5, Smarts = 3 },
				fameEffect = 0,
				feed = "You stayed home to create instead.",
			},
		},
	},
	
	-- CELEBRITY DATING RUMORS
	{
		id = "celebrity_dating_rumors",
		title = "💕 Celebrity Romance Rumors",
		emoji = "💕",
		text = "Tabloids are linking you romantically with another A-lister. Paparazzi are everywhere!",
		minFame = 40,
		cooldown = 3,
		maxOccurrences = 6,
		choices = {
			{
				text = "Confirm the relationship",
				effects = { Happiness = 15 },
				fameEffect = 20,
				setFlags = { power_couple = true },
				feed = "You're now one of Hollywood's hottest couples!",
			},
			{
				text = "Deny everything",
				effects = { Happiness = -5 },
				fameEffect = 5,
				feed = "They didn't believe you but whatever.",
			},
			{
				text = "No comment - keep them guessing",
				effects = { Happiness = 8 },
				fameEffect = 15,
				setFlags = { mysterious = true },
				feed = "The mystery only made it bigger news!",
			},
		},
	},
	
	-- MUSIC VIDEO MILESTONE
	{
		id = "music_video_billion",
		title = "📺 Billion View Video!",
		emoji = "📺",
		text = "Your music video just hit ONE BILLION views! You're in elite company.",
		minFame = 70,
		oneTime = true,
		maxOccurrences = 1,
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Throw a massive celebration ($100K)",
				effects = { Happiness = 25, Money = -100000 },
				fameEffect = 15,
				setFlags = { billion_club = true },
				feed = "The party of the year!",
				eligibility = function(state) return (state.Money or 0) >= 100000, "💸 Need $100K for party" end,
			},
			{
				text = "Thank fans with a surprise drop",
				effects = { Happiness = 20 },
				fameEffect = 20,
				setFlags = { billion_club = true, fan_favorite = true },
				feed = "The surprise track went viral!",
			},
			{
				text = "Stay humble - acknowledge the team",
				effects = { Happiness = 18, Smarts = 5 },
				fameEffect = 12,
				setFlags = { billion_club = true, humble_celebrity = true },
				feed = "Your gratitude was refreshing.",
			},
		},
	},
	
	-- SOLD OUT ARENA
	{
		id = "sold_out_arena",
		title = "🏟️ Arena Sellout!",
		emoji = "🏟️",
		text = "Your arena show sold out in minutes! Fans are reselling tickets for insane prices.",
		minFame = 60,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 5,
		choices = {
			{
				text = "Add more dates to meet demand",
				effects = { Happiness = 15, Health = -5, Money = 2000000 },
				fameEffect = 15,
				setFlags = { arena_headliner = true },
				feed = "More shows, more fans, more revenue!",
			},
			{
				text = "Keep it exclusive",
				effects = { Happiness = 10 },
				fameEffect = 10,
				setFlags = { exclusive_performer = true },
				feed = "Scarcity made it legendary.",
			},
			{
				-- CRITICAL FIX: Show price!
				text = "Cancel scalped tickets ($500K loss)",
				effects = { Happiness = 20, Money = -500000 },
				fameEffect = 20,
				setFlags = { fan_advocate = true },
				feed = "Fans LOVE you for fighting scalpers!",
				eligibility = function(state) return (state.Money or 0) >= 500000, "💸 Need $500K to cover losses" end,
			},
		},
	},
	
	-- SOCIAL MEDIA CONTROVERSY
	{
		id = "social_media_controversy",
		title = "📱 Tweet Causes Chaos",
		emoji = "📱",
		text = "Something you posted online is causing a massive controversy! Your mentions are on fire.",
		minFame = 35,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 5,
		choices = {
			{
				text = "Delete and apologize immediately",
				effects = { Happiness = -10 },
				fameEffect = -10,
				feed = "Quick damage control. Some accepted it.",
			},
			{
				text = "Double down - stand by your words",
				effects = { Happiness = 5 },
				successChance = 40,
				successFame = 15,
				successFeed = "Your boldness won respect!",
				failFame = -25,
				failFeed = "That made everything so much worse.",
			},
			{
				text = "Clarify with a thoughtful response",
				effects = { Happiness = 0, Smarts = 3 },
				fameEffect = 5,
				setFlags = { measured_response = true },
				feed = "Nuance in the age of outrage. Respect.",
			},
		},
	},
	
	-- AWARD NOMINATION
	{
		-- CRITICAL FIX: Renamed from "major_award_nomination" to avoid duplicate ID
		id = "celebrity_award_nomination",
		title = "🏆 Major Award Nomination!",
		emoji = "🏆",
		text = "You've been nominated for one of the biggest awards in your industry!",
		minFame = 50,
		cooldown = 3,
		maxOccurrences = 10,
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Campaign hard for the win ($200K)",
				effects = { Happiness = 10, Money = -200000 },
				successChance = 50,
				successFame = 25,
				successFeed = "YOU WON! Standing ovation!",
				failFame = 8,
				eligibility = function(state) return (state.Money or 0) >= 200000, "💸 Need $200K for campaign" end,
				failFeed = "You lost, but the nomination was an honor.",
				setFlags = { award_campaigner = true },
			},
			{
				text = "Let the work speak for itself",
				effects = { Happiness = 8 },
				successChance = 30,
				successFame = 30,
				successFeed = "You won without campaigning! Pure merit!",
				failFame = 5,
				failFeed = "Didn't win, but you stayed classy.",
			},
			{
				text = "Skip the ceremony",
				effects = { Happiness = 5 },
				fameEffect = -5,
				feed = "Some thought it was disrespectful.",
			},
		},
	},
	
	-- MAGAZINE COVER
	{
		id = "magazine_cover_offer",
		title = "📰 Magazine Cover Feature",
		emoji = "📰",
		text = "A prestigious magazine wants you on their cover with an exclusive interview.",
		minFame = 45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		maxOccurrences = 8,
		choices = {
			{
				text = "Do a revealing personal interview",
				effects = { Happiness = 8 },
				fameEffect = 15,
				setFlags = { open_book = true },
				feed = "The candid interview resonated with millions.",
			},
			{
				text = "Keep it professional - career focused",
				effects = { Happiness = 5, Smarts = 3 },
				fameEffect = 10,
				feed = "A polished industry piece.",
			},
			{
				text = "Demand editorial control",
				effects = { Happiness = 3 },
				successChance = 40,
				successFame = 12,
				successFeed = "You got final approval!",
				failFame = -3,
				failFeed = "They went with someone else.",
			},
		},
	},
	
	-- FRAGRANCE DEAL
	{
		id = "fragrance_line_offer",
		title = "✨ Fragrance Deal",
		emoji = "✨",
		text = "A major fragrance company wants to create a signature scent with your name on it.",
		minFame = 50,
		oneTime = true,
		maxOccurrences = 1,
		choices = {
			{
				text = "Full creative involvement",
				effects = { Happiness = 15, Money = 2000000 },
				fameEffect = 12,
				setFlags = { has_fragrance = true, creative_celeb = true },
				feed = "Your signature scent is a bestseller!",
			},
			{
				text = "Just put your name on it",
				effects = { Happiness = 8, Money = 5000000 },
				fameEffect = 8,
				setFlags = { has_fragrance = true },
				feed = "Easy money. Fragrance sells okay.",
			},
			{
				text = "Decline - not your brand",
				effects = { Happiness = 3 },
				fameEffect = 0,
				feed = "Not everything needs your name.",
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

	fameState.yearsInCareer = (fameState.yearsInCareer or 0) + 1

	-- CRITICAL FIX: Lua is 1-indexed, so stage 0 is invalid
	-- Auto-fix any existing saves with stage 0 to stage 1
	if not fameState.currentStage or fameState.currentStage < 1 then
		fameState.currentStage = 1
	end

	local currentStage = career.stages[fameState.currentStage]

	-- CRITICAL FIX: Guard against nil currentStage (in case stage exceeds career stages)
	if not currentStage then
		-- If stage exceeds the array, clamp to last stage
		if fameState.currentStage > #career.stages then
			fameState.currentStage = #career.stages
			currentStage = career.stages[fameState.currentStage]
		end
	end
	
	if not currentStage or not currentStage.fameGainPerYear then
		warn("[CelebrityEvents] currentStage or fameGainPerYear is nil for stage:", fameState.currentStage)
		return events
	end

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
-- CRITICAL FIX #432-436: COMPREHENSIVE ENDORSEMENT SYSTEM
-- Track endorsement deals, their value, duration, and effects
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.EndorsementBrands = {
	-- Luxury
	{ id = "rolex", name = "Luxury Watch Brand", category = "luxury", minFame = 60, payment = { min = 500000, max = 5000000 }, duration = 3, emoji = "⌚" },
	{ id = "louis_vuitton", name = "Designer Fashion House", category = "luxury", minFame = 70, payment = { min = 1000000, max = 10000000 }, duration = 2, emoji = "👜" },
	{ id = "bentley", name = "Luxury Car Brand", category = "luxury", minFame = 75, payment = { min = 2000000, max = 15000000 }, duration = 3, emoji = "🚗" },
	
	-- Tech
	{ id = "apple", name = "Tech Giant", category = "tech", minFame = 50, payment = { min = 1000000, max = 8000000 }, duration = 2, emoji = "📱" },
	{ id = "samsung", name = "Electronics Company", category = "tech", minFame = 45, payment = { min = 500000, max = 4000000 }, duration = 2, emoji = "📺" },
	{ id = "beats", name = "Audio Brand", category = "tech", minFame = 40, payment = { min = 200000, max = 2000000 }, duration = 3, emoji = "🎧" },
	
	-- Sports
	{ id = "nike", name = "Athletic Brand", category = "sports", minFame = 35, payment = { min = 500000, max = 20000000 }, duration = 5, emoji = "👟" },
	{ id = "gatorade", name = "Sports Drink", category = "sports", minFame = 45, payment = { min = 300000, max = 5000000 }, duration = 3, emoji = "🥤" },
	{ id = "underarmour", name = "Athletic Apparel", category = "sports", minFame = 40, payment = { min = 400000, max = 8000000 }, duration = 4, emoji = "👕" },
	
	-- Beauty
	{ id = "loreal", name = "Beauty Brand", category = "beauty", minFame = 30, payment = { min = 200000, max = 3000000 }, duration = 2, emoji = "💄" },
	{ id = "maybelline", name = "Cosmetics Company", category = "beauty", minFame = 25, payment = { min = 100000, max = 1000000 }, duration = 2, emoji = "💋" },
	{ id = "dior", name = "Luxury Perfume", category = "beauty", minFame = 55, payment = { min = 500000, max = 5000000 }, duration = 3, emoji = "🌸" },
	
	-- Food & Beverage
	{ id = "pepsi", name = "Soft Drink Giant", category = "food", minFame = 40, payment = { min = 1000000, max = 10000000 }, duration = 2, emoji = "🥤" },
	{ id = "mcdonalds", name = "Fast Food Chain", category = "food", minFame = 35, payment = { min = 500000, max = 5000000 }, duration = 1, emoji = "🍟" },
	{ id = "protein_powder", name = "Fitness Supplement", category = "food", minFame = 25, payment = { min = 50000, max = 500000 }, duration = 2, emoji = "💪" },
	
	-- Lifestyle
	{ id = "airbnb", name = "Travel Platform", category = "lifestyle", minFame = 45, payment = { min = 300000, max = 3000000 }, duration = 2, emoji = "🏠" },
	{ id = "uber", name = "Ride Share App", category = "lifestyle", minFame = 40, payment = { min = 200000, max = 2000000 }, duration = 2, emoji = "🚕" },
	
	-- Gaming
	{ id = "gaming_chair", name = "Gaming Gear Brand", category = "gaming", minFame = 20, payment = { min = 50000, max = 500000 }, duration = 2, emoji = "🎮" },
	{ id = "energy_drink", name = "Energy Drink", category = "gaming", minFame = 25, payment = { min = 100000, max = 1000000 }, duration = 2, emoji = "⚡" },
}

function CelebrityEvents.getAvailableEndorsements(lifeState)
	local fame = lifeState.Fame or 0
	local fameState = lifeState.FameState
	local currentEndorsements = fameState and fameState.endorsements or {}
	
	local available = {}
	
	for _, brand in ipairs(CelebrityEvents.EndorsementBrands) do
		if fame >= brand.minFame then
			-- Check if already have this endorsement
			local hasEndorsement = false
			for _, endorsement in ipairs(currentEndorsements) do
				if endorsement.brandId == brand.id then
					hasEndorsement = true
					break
				end
			end
			
			if not hasEndorsement then
				table.insert(available, brand)
			end
		end
	end
	
	return available
end

function CelebrityEvents.signEndorsementDeal(lifeState, brandId)
	local fameState = lifeState.FameState
	if not fameState then
		return false, "Not a celebrity"
	end
	
	-- Find the brand
	local brand = nil
	for _, b in ipairs(CelebrityEvents.EndorsementBrands) do
		if b.id == brandId then
			brand = b
			break
		end
	end
	
	if not brand then
		return false, "Unknown brand"
	end
	
	-- Check fame requirement
	if (lifeState.Fame or 0) < brand.minFame then
		return false, "Not famous enough"
	end
	
	-- Calculate payment based on fame
	local fameMultiplier = (lifeState.Fame or 0) / 100
	local payment = math.floor(math.random(brand.payment.min, brand.payment.max) * fameMultiplier)
	
	-- Create endorsement
	fameState.endorsements = fameState.endorsements or {}
	local endorsement = {
		brandId = brand.id,
		brandName = brand.name,
		category = brand.category,
		emoji = brand.emoji,
		totalPayment = payment,
		yearlyPayment = math.floor(payment / brand.duration),
		startYear = lifeState.Year,
		endYear = lifeState.Year + brand.duration,
		duration = brand.duration,
		yearsRemaining = brand.duration,
		active = true,
	}
	
	table.insert(fameState.endorsements, endorsement)
	
	-- Initial signing bonus (20% upfront)
	local signingBonus = math.floor(payment * 0.2)
	lifeState.Money = (lifeState.Money or 0) + signingBonus
	
	-- Fame boost
	local fameBoost = math.random(2, 5)
	lifeState.Fame = math.min(100, (lifeState.Fame or 0) + fameBoost)
	
	return true, string.format("Signed endorsement deal with %s %s for $%s! (+%d Fame)", 
		brand.emoji, brand.name, 
		CelebrityEvents.formatMoney(payment),
		fameBoost)
end

function CelebrityEvents.processEndorsementYearly(lifeState)
	local fameState = lifeState.FameState
	if not fameState or not fameState.endorsements then
		return {}
	end
	
	local results = {}
	local currentYear = lifeState.Year or 2025
	local totalYearlyIncome = 0
	
	for i = #fameState.endorsements, 1, -1 do
		local endorsement = fameState.endorsements[i]
		
		if endorsement.active then
			endorsement.yearsRemaining = endorsement.yearsRemaining - 1
			
			if endorsement.yearsRemaining > 0 then
				-- Pay yearly amount
				local yearlyPayment = endorsement.yearlyPayment
				lifeState.Money = (lifeState.Money or 0) + yearlyPayment
				totalYearlyIncome = totalYearlyIncome + yearlyPayment
			else
				-- Contract ended
				endorsement.active = false
				table.insert(results, {
					type = "ended",
					message = string.format("%s endorsement with %s ended", endorsement.emoji, endorsement.brandName),
					brandId = endorsement.brandId,
				})
				
				-- 50% chance they want to renew
				if math.random() < 0.50 then
					table.insert(results, {
						type = "renewal_offer",
						message = string.format("%s wants to renew your endorsement deal!", endorsement.brandName),
						brandId = endorsement.brandId,
					})
				end
			end
		end
	end
	
	if totalYearlyIncome > 0 then
		table.insert(results, 1, {
			type = "income",
			message = string.format("💰 Endorsement income: $%s", CelebrityEvents.formatMoney(totalYearlyIncome)),
			amount = totalYearlyIncome,
		})
	end
	
	return results
end

function CelebrityEvents.getEndorsementIncome(lifeState)
	local fameState = lifeState.FameState
	if not fameState or not fameState.endorsements then
		return 0
	end
	
	local total = 0
	for _, endorsement in ipairs(fameState.endorsements) do
		if endorsement.active then
			total = total + endorsement.yearlyPayment
		end
	end
	
	return total
end

function CelebrityEvents.getActiveEndorsements(lifeState)
	local fameState = lifeState.FameState
	if not fameState or not fameState.endorsements then
		return {}
	end
	
	local active = {}
	for _, endorsement in ipairs(fameState.endorsements) do
		if endorsement.active then
			table.insert(active, endorsement)
		end
	end
	
	return active
end

function CelebrityEvents.formatMoney(amount)
	if amount >= 1000000000 then
		return string.format("%.1fB", amount / 1000000000)
	elseif amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	else
		return tostring(amount)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #437-440: CELEBRITY AWARD TRACKING
-- Track awards won throughout career
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.AwardTypes = {
	-- Acting
	{ id = "oscar", name = "Academy Award", category = "acting", prestige = 100, emoji = "🏆" },
	{ id = "golden_globe", name = "Golden Globe", category = "acting", prestige = 80, emoji = "🌟" },
	{ id = "emmy", name = "Emmy Award", category = "acting", prestige = 75, emoji = "📺" },
	{ id = "sag", name = "SAG Award", category = "acting", prestige = 70, emoji = "🎭" },
	
	-- Music
	{ id = "grammy", name = "Grammy Award", category = "music", prestige = 95, emoji = "🎵" },
	{ id = "mtv_vma", name = "MTV VMA", category = "music", prestige = 60, emoji = "📺" },
	{ id = "ama", name = "American Music Award", category = "music", prestige = 55, emoji = "🇺🇸" },
	{ id = "brit_award", name = "BRIT Award", category = "music", prestige = 65, emoji = "🇬🇧" },
	
	-- Influencer
	{ id = "streamy", name = "Streamy Award", category = "influencer", prestige = 40, emoji = "🎬" },
	{ id = "shorty", name = "Shorty Award", category = "influencer", prestige = 35, emoji = "📱" },
	
	-- Sports
	{ id = "mvp", name = "MVP Award", category = "sports", prestige = 90, emoji = "🏅" },
	{ id = "champion", name = "Championship", category = "sports", prestige = 95, emoji = "🏆" },
	{ id = "allstar", name = "All-Star Selection", category = "sports", prestige = 50, emoji = "⭐" },
	
	-- General
	{ id = "peoples_choice", name = "People's Choice Award", category = "general", prestige = 45, emoji = "🏆" },
	{ id = "teen_choice", name = "Teen Choice Award", category = "general", prestige = 30, emoji = "🎯" },
}

function CelebrityEvents.winAward(lifeState, awardId)
	local fameState = lifeState.FameState
	if not fameState then
		fameState = { awards = {} }
		lifeState.FameState = fameState
	end
	
	fameState.awards = fameState.awards or {}
	
	-- Find award
	local award = nil
	for _, a in ipairs(CelebrityEvents.AwardTypes) do
		if a.id == awardId then
			award = a
			break
		end
	end
	
	if not award then
		return false, "Unknown award"
	end
	
	-- Create award record
	local awardRecord = {
		id = award.id,
		name = award.name,
		category = award.category,
		emoji = award.emoji,
		year = lifeState.Year,
		age = lifeState.Age,
	}
	
	table.insert(fameState.awards, awardRecord)
	
	-- Fame boost based on prestige
	local fameBoost = math.floor(award.prestige / 10)
	lifeState.Fame = math.min(100, (lifeState.Fame or 0) + fameBoost)
	
	-- Happiness boost
	lifeState.Stats = lifeState.Stats or {}
	lifeState.Stats.Happiness = math.min(100, (lifeState.Stats.Happiness or 50) + 15)
	
	return true, string.format("%s You won the %s! (+%d Fame)", award.emoji, award.name, fameBoost)
end

function CelebrityEvents.getAwardCount(lifeState)
	local fameState = lifeState.FameState
	if not fameState or not fameState.awards then
		return 0
	end
	return #fameState.awards
end

function CelebrityEvents.hasMajorAward(lifeState)
	local fameState = lifeState.FameState
	if not fameState or not fameState.awards then
		return false
	end
	
	local majorAwards = {"oscar", "grammy", "mvp", "champion", "emmy"}
	for _, award in ipairs(fameState.awards) do
		for _, major in ipairs(majorAwards) do
			if award.id == major then
				return true
			end
		end
	end
	
	return false
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #578-595: STREAMER CAREER PATH
-- Full streaming/content creator career with proper progression
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.StreamerCareer = {
	name = "Streamer",
	emoji = "🎮",
	description = "Build an audience streaming games and content",
	minStartAge = 13,
	maxStartAge = 45,
	
	platforms = {
		{ id = "streamer_twitch", name = "Twitch", emoji = "🟣", focus = "gaming" }, -- CRITICAL FIX: Renamed from "twitch" to avoid duplicate ID with InfluencerCareer.platforms
		{ id = "youtube_gaming", name = "YouTube Gaming", emoji = "🎮", focus = "gaming" },
		{ id = "kick", name = "Kick", emoji = "🟢", focus = "gaming" },
		{ id = "youtube_live", name = "YouTube Live", emoji = "📺", focus = "variety" },
	},
	
	stages = {
		{
			id = "hobbyist",
			name = "Hobbyist Streamer",
			emoji = "🎮",
			salary = { min = 0, max = 50 },
			subscribers = 10,
			fameRequired = 0,
			fameGainPerYear = { min = 0, max = 1 },
			yearsToAdvance = { min = 1, max = 2 },
			description = "Streaming to a few friends",
			activities = { "Stream to empty rooms", "Learn OBS", "Dream of making it big" },
		},
		{
			id = "affiliate",
			name = "Affiliate Streamer",
			emoji = "🟣",
			salary = { min = 100, max = 500 },
			subscribers = 100,
			fameRequired = 3,
			fameGainPerYear = { min = 1, max = 3 },
			yearsToAdvance = { min = 1, max = 2 },
			description = "Earned affiliate status",
			activities = { "Get your first subscribers", "Earn bits and cheers", "Build a small community" },
		},
		{
			id = "small_streamer",
			name = "Small Streamer",
			emoji = "📺",
			salary = { min = 1000, max = 5000 },
			subscribers = 1000,
			fameRequired = 8,
			fameGainPerYear = { min = 2, max = 5 },
			yearsToAdvance = { min = 1, max = 3 },
			description = "A dedicated audience forming",
			activities = { "Regular streaming schedule", "First sponsorship offers", "Recognize regular viewers" },
		},
		{
			id = "mid_streamer",
			name = "Growing Streamer",
			emoji = "📈",
			salary = { min = 8000, max = 25000 },
			subscribers = 10000,
			fameRequired = 15,
			fameGainPerYear = { min = 4, max = 8 },
			yearsToAdvance = { min = 2, max = 3 },
			description = "A real following developing",
			activities = { "Brand deals coming in", "Your clips go viral", "Community growing fast" },
		},
		{
			id = "established_streamer",
			name = "Established Streamer",
			emoji = "✅",
			salary = { min = 50000, max = 150000 },
			subscribers = 50000,
			fameRequired = 30,
			fameGainPerYear = { min = 6, max = 12 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "A known name in streaming",
			activities = { "Attend gaming events", "Major sponsor deals", "Launch your merch line" },
		},
		{
			id = "partner",
			name = "Partner Streamer",
			emoji = "💎",
			salary = { min = 200000, max = 500000 },
			subscribers = 200000,
			fameRequired = 50,
			fameGainPerYear = { min = 8, max = 15 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Full partner with all perks",
			activities = { "Prime time streaming", "Invited to major tournaments", "Celebrity collaborations" },
		},
		{
			id = "top_streamer",
			name = "Top Streamer",
			emoji = "⭐",
			salary = { min = 1000000, max = 5000000 },
			subscribers = 1000000,
			fameRequired = 70,
			fameGainPerYear = { min = 5, max = 10 },
			yearsToAdvance = { min = 3, max = 5 },
			description = "Among the most watched",
			activities = { "Massive contract deals", "Start your own org", "Shape the platform" },
		},
		{
			id = "legendary_streamer",
			name = "Streaming Legend",
			emoji = "👑",
			salary = { min = 10000000, max = 50000000 },
			subscribers = 10000000,
			fameRequired = 90,
			fameGainPerYear = { min = 2, max = 5 },
			yearsToAdvance = nil,
			description = "A legend of streaming",
			activities = { "Your name is iconic", "Multi-platform deals", "Retired numbers at TwitchCon" },
		},
	},
	
	events = {
		{
			id = "first_raid",
			title = "🎮 You Got Raided!",
			text = "A bigger streamer just raided your channel! Thousands of new viewers are flooding in!",
			minStage = 1,
			maxStage = 4,
			choices = {
				{ text = "Welcome them with energy", fameGain = 8, subscribersGain = 500 },
				{ text = "Keep calm and carry on", fameGain = 3, message = "Some viewers stick around." },
			},
		},
		{
			id = "viral_clip",
			title = "📹 Clip Goes Viral!",
			text = "One of your stream clips is blowing up on social media! Millions of views!",
			minStage = 2,
			maxStage = 6,
			choices = {
				{ text = "Capitalize on the moment", fameGain = 15, subscribersGain = 10000, salaryBonus = 50000 },
				{ text = "Stay humble", fameGain = 8, message = "Fans appreciate your authenticity." },
			},
		},
		{
			-- CRITICAL FIX: Renamed from "sponsorship_deal" to avoid duplicate ID with RacingEvents
			id = "celebrity_sponsorship_offer",
			title = "💰 Major Sponsorship!",
			text = "A gaming chair company / energy drink brand wants you as their face!",
			minStage = 3,
			maxStage = 7,
			choices = {
				{ text = "Take the deal", salaryBonus = 100000, fameGain = 5 },
				{ text = "Negotiate higher", successChance = 50, salaryBonus = 250000, failMessage = "They went with another streamer." },
				{ text = "Decline - Not my brand", fameGain = 2, message = "Your audience respects your integrity." },
			},
		},
		{
			id = "banned_controversy",
			title = "⚠️ You Got Banned!",
			text = "You received a platform ban! Was it deserved or unfair?",
			minStage = 2,
			maxStage = 8,
			choices = {
				{ text = "Appeal and apologize", fameGain = -5, message = "Ban overturned after a week." },
				{ text = "Move to another platform", fameGain = 0, subscribersLoss = 30, message = "You rebuilt on a new platform." },
				{ text = "Create drama about it", successChance = 40, fameGain = 10, failFameLoss = 20, failMessage = "The drama backfired badly." },
			},
		},
		{
			id = "tournament_win",
			title = "🏆 Tournament Victory!",
			text = "You won a major gaming tournament on stream! Your skills are elite!",
			minStage = 4,
			maxStage = 8,
			choices = {
				{ text = "Celebrate with viewers", fameGain = 20, salaryBonus = 500000, subscribersGain = 50000 },
				{ text = "Stay professional", fameGain = 12, message = "Your composure impresses sponsors." },
			},
		},
		{
			id = "org_offer",
			title = "🎯 Esports Org Offer",
			text = "A major esports organization wants to sign you!",
			minStage = 4,
			maxStage = 7,
			choices = {
				{ text = "Join the org", salaryBonus = 300000, fameGain = 10, setFlags = { esports_signed = true } },
				{ text = "Stay independent", fameGain = 5, message = "You maintain full control." },
				{ text = "Start your own org", successChance = 40, salaryBonus = 1000000, fameGain = 15, failMessage = "Running an org is harder than expected." },
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #596-615: RAPPER/HIP-HOP CAREER PATH
-- Full rapper career with proper progression from underground to superstar
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.RapperCareer = {
	name = "Rapper",
	emoji = "🎤",
	description = "Rise from the underground to hip-hop royalty",
	minStartAge = 14,
	maxStartAge = 35,
	
	subgenres = {
		{ id = "trap", name = "Trap", emoji = "🔥" },
		{ id = "boom_bap", name = "Boom Bap", emoji = "🎧" },
		{ id = "drill", name = "Drill", emoji = "🔫" },
		{ id = "conscious", name = "Conscious Rap", emoji = "💭" },
		{ id = "cloud", name = "Cloud Rap", emoji = "☁️" },
		{ id = "melodic", name = "Melodic Rap", emoji = "🎵" },
	},
	
	stages = {
		{
			id = "underground",
			name = "Underground Rapper",
			emoji = "🎤",
			salary = { min = 0, max = 500 },
			streams = 100,
			fameRequired = 0,
			fameGainPerYear = { min = 0, max = 2 },
			yearsToAdvance = { min = 1, max = 3 },
			description = "Spitting bars in cyphers",
			activities = { "Record in bedrooms", "Rap battle at open mics", "Upload to SoundCloud" },
		},
		{
			id = "local_rapper",
			name = "Local Rapper",
			emoji = "📍",
			salary = { min = 1000, max = 5000 },
			streams = 10000,
			fameRequired = 5,
			fameGainPerYear = { min = 2, max = 4 },
			yearsToAdvance = { min = 1, max = 2 },
			description = "Known in your city",
			activities = { "Open for local shows", "Build a local buzz", "Get played on local radio" },
		},
		{
			id = "buzzing",
			name = "Buzzing Artist",
			emoji = "📈",
			salary = { min = 10000, max = 40000 },
			streams = 100000,
			fameRequired = 15,
			fameGainPerYear = { min = 4, max = 8 },
			yearsToAdvance = { min = 1, max = 3 },
			description = "The blogs are talking",
			activities = { "Get on hip-hop blogs", "First mixtape drops", "Connect with producers" },
		},
		{
			id = "signed_rapper",
			name = "Signed Rapper",
			emoji = "📝",
			salary = { min = 50000, max = 200000 },
			streams = 1000000,
			fameRequired = 25,
			fameGainPerYear = { min = 6, max = 12 },
			yearsToAdvance = { min = 2, max = 3 },
			description = "Record deal secured",
			activities = { "Sign your first deal", "Studio time with pros", "Features with bigger artists" },
		},
		{
			id = "hot_rapper",
			name = "Hot Rapper",
			emoji = "🔥",
			salary = { min = 250000, max = 750000 },
			streams = 10000000,
			fameRequired = 40,
			fameGainPerYear = { min = 8, max = 15 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "Your songs are everywhere",
			activities = { "Chart-topping singles", "Headlining shows", "XXL Freshman list" },
		},
		{
			id = "mainstream",
			name = "Mainstream Rapper",
			emoji = "⭐",
			salary = { min = 1000000, max = 5000000 },
			streams = 100000000,
			fameRequired = 60,
			fameGainPerYear = { min = 10, max = 18 },
			yearsToAdvance = { min = 2, max = 4 },
			description = "A household name",
			activities = { "Platinum albums", "Arena tours", "Multiple #1 hits" },
		},
		{
			id = "superstar_rapper",
			name = "Superstar Rapper",
			emoji = "💎",
			salary = { min = 10000000, max = 40000000 },
			streams = 1000000000,
			fameRequired = 80,
			fameGainPerYear = { min = 5, max = 12 },
			yearsToAdvance = { min = 3, max = 5 },
			description = "One of the biggest in the game",
			activities = { "Stadium tours", "Fashion deals", "Business empire" },
		},
		{
			id = "legend_rapper",
			name = "Hip-Hop Legend",
			emoji = "👑",
			salary = { min = 30000000, max = 150000000 },
			streams = 10000000000,
			fameRequired = 95,
			fameGainPerYear = { min = 1, max = 3 },
			yearsToAdvance = nil,
			description = "A true legend of hip-hop",
			activities = { "GOAT debates include your name", "Inducted into hall of fame", "Changed the culture forever" },
		},
	},
	
	events = {
		{
			id = "first_viral_song",
			title = "🔥 Song Goes Viral!",
			text = "Your track is blowing up! TikTok, Instagram, everywhere!",
			minStage = 1,
			maxStage = 5,
			choices = {
				{ text = "Drop a music video ASAP", fameGain = 15, salaryBonus = 100000, streamGain = 5000000 },
				{ text = "Stay mysterious", fameGain = 8, message = "The intrigue builds your legend." },
			},
		},
		{
			id = "beef_starts",
			title = "😤 Rap Beef!",
			text = "Another rapper just dissed you on a track! The internet is watching your response.",
			minStage = 2,
			maxStage = 7,
			choices = {
				{ text = "Drop a devastating diss track", successChance = 70, fameGain = 20, failFameLoss = 10, message = "You won the beef!", failMessage = "Your diss track fell flat..." },
				{ text = "Rise above it", fameGain = 5, message = "Fans respect your maturity." },
				{ text = "Take it to social media", fameGain = 10, message = "The drama keeps you in headlines." },
			},
		},
		{
			id = "xxl_freshman",
			title = "📰 XXL Freshman List!",
			text = "You've been nominated for the XXL Freshman class! This is huge exposure.",
			minStage = 3,
			maxStage = 5,
			choices = {
				{ text = "Nail your freestyle", successChance = 60, fameGain = 25, message = "Your cypher is all anyone talks about!", failMessage = "Your freestyle was mid..." },
				{ text = "Do something controversial", fameGain = 15, message = "The memes are everywhere." },
			},
		},
		{
			id = "collab_drake",
			title = "🎤 Big Feature Opportunity",
			text = "One of the biggest rappers in the game wants you on their album!",
			minStage = 4,
			maxStage = 7,
			choices = {
				{ text = "Steal the show", successChance = 50, fameGain = 30, salaryBonus = 500000, message = "Your verse is the best on the album!", failMessage = "You got outshined..." },
				{ text = "Play it safe", fameGain = 15, salaryBonus = 200000, message = "A solid feature." },
			},
		},
		{
			id = "album_drop",
			title = "💿 Album Drop Decision",
			text = "Your album is ready. How do you want to release it?",
			minStage = 3,
			maxStage = 8,
			choices = {
				{ text = "Surprise drop (Beyoncé style)", successChance = 40, fameGain = 35, salaryBonus = 5000000, failMessage = "Nobody noticed the drop..." },
				{ text = "Full marketing campaign", fameGain = 20, salaryBonus = 2000000, message = "A successful rollout!" },
				{ text = "Leak it yourself for buzz", fameGain = 15, message = "The leak strategy worked!" },
			},
		},
		{
			id = "label_issues",
			title = "📋 Label Problems",
			text = "Your label is holding your music hostage! What do you do?",
			minStage = 4,
			maxStage = 7,
			choices = {
				{ text = "Public war with the label", fameGain = 10, message = "Fans support you!" },
				{ text = "Buy out your contract", salaryLoss = 2000000, setFlags = { independent_artist = true }, message = "Freedom isn't free, but it's yours!" },
				{ text = "Wait it out", message = "Patience is a virtue..." },
			},
		},
		{
			id = "grammy_rap",
			title = "🏆 Grammy Nomination!",
			text = "You've been nominated for Best Rap Album!",
			minStage = 5,
			maxStage = 8,
			choices = {
				{ text = "Win and give epic speech", successChance = 25, fameGain = 40, message = "You won! Your speech goes viral!" },
				{ text = "Get snubbed and complain", fameGain = 10, message = "The Grammys don't understand hip-hop anyway." },
			},
		},
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #616-630: CELEBRITY CAREER CHOICE EVENTS
-- Proper progression from nobody to celebrity with structured career choices
-- ════════════════════════════════════════════════════════════════════════════

CelebrityEvents.CareerProgressionEvents = {
	-- CELEBRITY CAREER START - CHOOSING YOUR PATH
	{
		id = "celebrity_career_choice",
		title = "🌟 Choose Your Fame Path",
		emoji = "🌟",
		text = "You have the Celebrity gamepass! You can pursue fame through various paths. Which career calls to you?",
		minAge = 16,
		maxAge = 35,
		oneTime = true,
		isCelebrityOnly = true,
		priority = "high",
		isMilestone = true,
		conditions = { requiresFlags = { celebrity_gamepass = true } },
		blockedByFlags = { celebrity_career_chosen = true },
		choices = {
			{
				text = "🎬 Acting - Hollywood dreams",
				effects = { Happiness = 10 },
				setFlags = { celebrity_career_chosen = true, pursuing_acting = true, celebrity_path = "actor" },
				feed = "You've decided to pursue an acting career!",
				onResolve = function(state)
					state.FameState = state.FameState or {}
					state.FameState.careerPath = "actor"
					state.FameState.currentStage = 1
					state.FameState.stageName = "Extra"
					state.FameState.yearsInStage = 0
					-- CRITICAL FIX #38: Use proper job ID that exists in JobCatalog!
					state.CurrentJob = {
						id = "extra", -- CRITICAL: Job ID must match JobCatalog
						name = "Extra",
						company = "Casting Agency",
						category = "entertainment",
						emoji = "👥",
						salary = math.random(500, 2000),
						isActing = true,
						isFameCareer = true,
					}
					if state.AddFeed then
						state:AddFeed("🎬 Your acting journey begins! Starting as an extra...")
					end
				end,
			},
			{
				text = "🎵 Music - Become a singer",
				effects = { Happiness = 10 },
				setFlags = { celebrity_career_chosen = true, pursuing_music = true, celebrity_path = "musician" },
				feed = "You've decided to pursue a music career!",
				onResolve = function(state)
					state.FameState = state.FameState or {}
					state.FameState.careerPath = "musician"
					state.FameState.currentStage = 1
					state.FameState.stageName = "Street Performer"
					state.FameState.yearsInStage = 0
					-- CRITICAL FIX #37: Use proper job ID that exists in JobCatalog!
					state.CurrentJob = {
						id = "street_performer", -- CRITICAL: Job ID must match JobCatalog
						name = "Street Performer",
						company = "Self-Employed",
						category = "entertainment",
						emoji = "🎸",
						salary = math.random(50, 500),
						isMusic = true,
						isFameCareer = true,
					}
					if state.AddFeed then
						state:AddFeed("🎵 Your music journey begins! Playing for tips...")
					end
				end,
			},
			{
				text = "🎤 Rapper - Hip-hop dreams",
				effects = { Happiness = 10 },
				setFlags = { celebrity_career_chosen = true, pursuing_rap = true, celebrity_path = "rapper" },
				feed = "You've decided to become a rapper!",
				onResolve = function(state)
					state.FameState = state.FameState or {}
					state.FameState.careerPath = "rapper"
					state.FameState.currentStage = 1
					state.FameState.stageName = "Underground Rapper"
					state.FameState.yearsInStage = 0
					-- CRITICAL FIX #33: Use proper job ID that exists in JobCatalog!
					state.CurrentJob = {
						id = "underground_rapper", -- CRITICAL: Job ID must match JobCatalog
						name = "Underground Rapper",
						company = "Independent",
						category = "entertainment",
						salary = math.random(0, 500),
						emoji = "🎤",
						isRapper = true,
						isFameCareer = true,
					}
					if state.AddFeed then
						state:AddFeed("🎤 Your rap journey begins! Spitting bars in cyphers...")
					end
				end,
			},
			{
				text = "🎮 Streamer - Content creator",
				effects = { Happiness = 10 },
				setFlags = { celebrity_career_chosen = true, pursuing_streaming = true, celebrity_path = "streamer" },
				feed = "You've decided to become a streamer!",
				onResolve = function(state)
					state.FameState = state.FameState or {}
					state.FameState.careerPath = "streamer"
					state.FameState.currentStage = 1
					state.FameState.stageName = "New Streamer"
					state.FameState.yearsInStage = 0
					state.FameState.subscribers = 10
					-- CRITICAL FIX #41: Use proper job ID that exists in JobCatalog!
					state.CurrentJob = {
						id = "new_streamer", -- CRITICAL: Job ID must match JobCatalog
						name = "New Streamer",
						company = "Twitch",
						category = "entertainment",
						emoji = "🎮",
						salary = math.random(0, 50),
						isStreamer = true,
						isFameCareer = true,
					}
					if state.AddFeed then
						state:AddFeed("🎮 Your streaming journey begins! Time to go live!")
					end
				end,
			},
			{
				text = "📱 Influencer - Social media fame",
				effects = { Happiness = 10 },
				setFlags = { celebrity_career_chosen = true, pursuing_influencer = true, celebrity_path = "influencer" },
				feed = "You've decided to become a social media influencer!",
				onResolve = function(state)
					state.FameState = state.FameState or {}
					state.FameState.careerPath = "influencer"
					state.FameState.currentStage = 1
					state.FameState.stageName = "New Creator"
					state.FameState.yearsInStage = 0
					state.FameState.followers = 100
					-- CRITICAL FIX #34: Use proper job ID that exists in JobCatalog!
					state.CurrentJob = {
						id = "new_creator", -- CRITICAL: Job ID must match JobCatalog
						name = "New Creator",
						company = "Social Media",
						category = "entertainment",
						emoji = "📱",
						salary = math.random(0, 100),
						isInfluencer = true,
						isFameCareer = true,
					}
					if state.AddFeed then
						state:AddFeed("📱 Your influencer journey begins! Time to build that following!")
					end
				end,
			},
			{
				text = "🏆 Athlete - Sports superstar",
				effects = { Happiness = 10, Health = 5 },
				setFlags = { celebrity_career_chosen = true, pursuing_sports = true, celebrity_path = "athlete" },
				feed = "You've decided to pursue professional sports!",
				onResolve = function(state)
					state.FameState = state.FameState or {}
					state.FameState.careerPath = "athlete"
					state.FameState.currentStage = 1
					state.FameState.stageName = "Amateur"
					state.FameState.yearsInStage = 0
					-- CRITICAL FIX #39: Use proper job ID that exists in JobCatalog!
					state.CurrentJob = {
						id = "amateur_athlete", -- CRITICAL: Job ID must match JobCatalog
						name = "Amateur",
						company = "Local Leagues",
						category = "entertainment",
						emoji = "🏃",
						salary = math.random(0, 500),
						isAthlete = true,
						isFameCareer = true,
					}
					if state.AddFeed then
						state:AddFeed("🏆 Your athletic journey begins! Train hard!")
					end
				end,
			},
		},
	},
	
	-- NEW CELEBRITY - First year events
	{
		id = "celebrity_year_one",
		title = "⭐ Your First Year",
		emoji = "⭐",
		text = "Your first year pursuing fame has been eventful. The journey is just beginning.",
		minAge = 17,
		maxAge = 100,
		isCelebrityOnly = true,
		cooldown = 3, -- CRITICAL FIX: Increased from 1
		oneTime = true, -- CRITICAL FIX: This should only happen once
		conditions = { requiresFlags = { celebrity_career_chosen = true } },
		blockedByFlags = { completed_year_one = true },
		choices = {
			{
				text = "Work extra hard - Grind mode",
				effects = { Happiness = 3, Health = -5 },
				fameGain = 5,
				setFlags = { completed_year_one = true, hard_worker = true },
				feed = "Your dedication is paying off!",
			},
			{
				text = "Balance work and life",
				effects = { Happiness = 8 },
				fameGain = 2,
				setFlags = { completed_year_one = true, balanced_life = true },
				feed = "You're finding a healthy balance.",
			},
			{
				text = "Network aggressively",
				effects = { Happiness = 5 },
				fameGain = 8,
				setFlags = { completed_year_one = true, good_networker = true },
				feed = "You've made valuable connections!",
			},
		},
	},
	
	-- CAREER STAGE PROGRESSION
	{
		id = "celebrity_promotion",
		title = "📈 Career Advancement!",
		emoji = "📈",
		text = "Your hard work is paying off! You're ready to move up in your career.",
		minAge = 17,
		maxAge = 100,
		isCelebrityOnly = true,
		conditions = { 
			requiresFlags = { celebrity_career_chosen = true },
			custom = function(state)
				if not state.FameState then return false end
				local yearsInStage = state.FameState.yearsInStage or 0
				return yearsInStage >= 2 and (state.Fame or 0) >= 15
			end,
		},
		choices = {
			{
				text = "Accept the promotion",
				effects = { Happiness = 15, Money = 50000 },
				fameGain = 10,
				setFlags = { got_promoted = true },
				feed = "You've moved up in your career!",
				onResolve = function(state)
					state.FameState = state.FameState or {}
					state.FameState.currentStage = (state.FameState.currentStage or 1) + 1
					state.FameState.yearsInStage = 0
					state.FameState.promotions = (state.FameState.promotions or 0) + 1
					
					-- Update salary based on new stage
					local baseSalary = 50000 * (state.FameState.currentStage or 1)
					if state.CurrentJob then
						state.CurrentJob.salary = baseSalary + math.random(0, baseSalary)
					end
					
					if state.AddFeed then
						state:AddFeed("🎉 Your career has advanced to the next level!")
					end
				end,
			},
			{
				text = "Stay where you are - Not ready",
				effects = { Happiness = 2 },
				feed = "You decided to keep building your foundation.",
			},
		},
	},
	
	-- OLDER CELEBRITY EVENTS
	{
		id = "celebrity_midlife",
		title = "🌟 Established Star",
		emoji = "🌟",
		text = "You're now an established name in your industry. What's next for your career?",
		minAge = 35,
		maxAge = 50,
		isCelebrityOnly = true,
		oneTime = true,
		conditions = { 
			requiresFlags = { celebrity_career_chosen = true },
			custom = function(state)
				return (state.Fame or 0) >= 50
			end,
		},
		choices = {
			{
				text = "Mentor the next generation",
				effects = { Happiness = 12, Smarts = 3 },
				fameGain = 5,
				setFlags = { is_mentor = true, respected_veteran = true },
				feed = "You become a mentor to rising stars!",
			},
			{
				text = "Launch a business empire",
				effects = { Money = 5000000 },
				fameGain = 8,
				setFlags = { business_owner = true, mogul_status = true },
				feed = "You leverage your fame into business success!",
			},
			{
				text = "Keep grinding - Stay at the top",
				effects = { Happiness = 5, Health = -3 },
				fameGain = 10,
				feed = "You refuse to slow down!",
			},
			{
				text = "Step back - Enjoy your success",
				effects = { Happiness = 15, Health = 5 },
				fameGain = -3,
				setFlags = { semi_retired = true },
				feed = "You take time to enjoy the fruits of your labor.",
			},
		},
	},
	
	-- SENIOR CELEBRITY - LEGEND STATUS
	{
		id = "celebrity_legend",
		title = "👑 Legend Status",
		emoji = "👑",
		text = "You've become a true legend in your field. Your legacy is secure.",
		minAge = 55,
		maxAge = 100,
		isCelebrityOnly = true,
		oneTime = true,
		conditions = { 
			requiresFlags = { celebrity_career_chosen = true },
			custom = function(state)
				return (state.Fame or 0) >= 80
			end,
		},
		blockedByFlags = { achieved_legend = true },
		choices = {
			{
				text = "Accept lifetime achievement award",
				effects = { Happiness = 20, Money = 1000000 },
				fameGain = 10,
				setFlags = { achieved_legend = true, lifetime_achievement = true },
				feed = "You receive a lifetime achievement award! A legend of the industry!",
			},
			{
				text = "Write your memoirs",
				effects = { Happiness = 12, Money = 10000000 },
				fameGain = 5,
				setFlags = { achieved_legend = true, wrote_memoirs = true },
				feed = "Your autobiography becomes a bestseller!",
			},
			{
				-- CRITICAL FIX: Show price!
				text = "Start a foundation ($5M)",
				effects = { Happiness = 15, Money = -5000000 },
				fameGain = 15,
				setFlags = { achieved_legend = true, philanthropist = true },
				feed = "Your foundation will help others for generations!",
				eligibility = function(state) return (state.Money or 0) >= 5000000, "💸 Need $5M for foundation" end,
			},
		},
	},
	
	-- GRANDPA/GRANDMA CELEBRITY
	{
		id = "celebrity_elder",
		title = "🏆 Icon of an Era",
		emoji = "🏆",
		text = "You're now considered an icon who defined an era. Young artists study your work.",
		minAge = 70,
		maxAge = 100,
		isCelebrityOnly = true,
		oneTime = true,
		conditions = { 
			requiresFlags = { celebrity_career_chosen = true },
			custom = function(state)
				return (state.Fame or 0) >= 60
			end,
		},
		blockedByFlags = { elder_icon = true },
		choices = {
			{
				text = "Make a comeback - One more time",
				effects = { Happiness = 12, Health = -5 },
				fameGain = 15,
				setFlags = { elder_icon = true, made_comeback = true },
				feed = "Your comeback is celebrated! Proving legends never die!",
			},
			{
				text = "Pass on your wisdom",
				effects = { Happiness = 15 },
				fameGain = 5,
				setFlags = { elder_icon = true, elder_statesman = true },
				feed = "You become a respected elder voice in your industry.",
			},
			{
				text = "Retire gracefully",
				effects = { Happiness = 20, Health = 5 },
				setFlags = { elder_icon = true, graceful_retirement = true },
				feed = "You retire on top, a legend remembered fondly.",
			},
		},
	},
}

-- Add career progression events to main list
for _, event in ipairs(CelebrityEvents.CareerProgressionEvents) do
	table.insert(CelebrityEvents.events or {}, event)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #631-640: Celebrity career helper functions
-- ════════════════════════════════════════════════════════════════════════════

function CelebrityEvents.getCareerData(path)
	local careers = {
		actor = CelebrityEvents.ActingCareer,
		musician = CelebrityEvents.MusicCareer,
		influencer = CelebrityEvents.InfluencerCareer,
		athlete = CelebrityEvents.AthleteCareer,
		streamer = CelebrityEvents.StreamerCareer,
		rapper = CelebrityEvents.RapperCareer,
	}
	return careers[path]
end

function CelebrityEvents.getStageInfo(state)
	if not state or not state.FameState then return nil end
	
	local path = state.FameState.careerPath
	local stage = state.FameState.stage or 1
	local career = CelebrityEvents.getCareerData(path)
	
	if career and career.stages and career.stages[stage] then
		return career.stages[stage]
	end
	
	return nil
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: Removed duplicate processYearlyFameUpdates function
-- The primary function is defined at line ~2814 with full career events logic
-- This duplicate was overwriting that function and breaking celebrity events
-- ════════════════════════════════════════════════════════════════════════════════
function CelebrityEvents.processYearlyStatRequirements(state)
	-- RENAMED: This function now only handles stat requirement checks for promotions
	-- It supplements the main processYearlyFameUpdates function
	if not state or not state.FameState then return {} end

	local events = {}
	local fameState = state.FameState

	-- Get current stage info
	local stageInfo = CelebrityEvents.getStageInfo(state)
	if not stageInfo then return events end

	-- Check for automatic promotion based on stats
	local yearsToAdvance = stageInfo.yearsToAdvance
	if yearsToAdvance then
		local requiredYears = math.random(yearsToAdvance.min, yearsToAdvance.max)
		-- CRITICAL FIX: Handle nil fameState.stage (default to 1)
		local currentStage = fameState.stage or 1
		local nextStage = currentStage + 1
		local career = CelebrityEvents.getCareerData(fameState.careerPath)
		
		if career and career.stages[nextStage] then
			local nextStageInfo = career.stages[nextStage]
			
			-- CRITICAL FIX #16: Check stat requirements for promotion
			local meetsStatRequirements = true
			if nextStageInfo.minStats then
				state.Stats = state.Stats or {}
				for statName, minValue in pairs(nextStageInfo.minStats) do
					local playerStat = state.Stats[statName] or state[statName] or 50
					if playerStat < minValue then
						meetsStatRequirements = false
						-- Store which stat is blocking promotion for UI feedback
						state.Flags = state.Flags or {}
						state.Flags.blocked_promotion_stat = statName
						state.Flags.blocked_promotion_required = minValue
						break
					end
				end
			end
			
			if fameState.yearsInStage >= requiredYears and (state.Fame or 0) >= nextStageInfo.fameRequired and meetsStatRequirements then
				-- Eligible for promotion
				state.Flags = state.Flags or {}
				state.Flags.eligible_for_promotion = true
				state.Flags.blocked_promotion_stat = nil
				state.Flags.blocked_promotion_required = nil
			elseif not meetsStatRequirements then
				-- CRITICAL FIX #16: Notify player they need to improve stats
				table.insert(events, {
					id = "stat_block_promotion",
					title = "📉 Career Progress Blocked",
					text = string.format("You need higher %s to advance to %s. Work on improving yourself!", 
						state.Flags.blocked_promotion_stat or "stats", 
						nextStageInfo.name or "the next level"),
					emoji = "⚠️",
					category = "career",
					choices = {
						{ text = "Work on improving", deltas = {}, feed = "resolved to work harder" },
					}
				})
			end
		end
	end
	
	return events
end

-- ════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #42: Export events in standard format for LifeEvents loader
-- The init.lua module loader expects .events, .Events, or .LifeEvents array
-- Combines GeneralFameEvents with all career-specific events
-- ════════════════════════════════════════════════════════════════════════════
CelebrityEvents.events = CelebrityEvents.events or {}

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

-- CRITICAL FIX #641: Add streamer career events
if CelebrityEvents.StreamerCareer and CelebrityEvents.StreamerCareer.events then
	for _, event in ipairs(CelebrityEvents.StreamerCareer.events) do
		event.isCelebrityOnly = true
		event.careerPath = "streamer"
		event.minAge = event.minAge or 13
		event.maxAge = event.maxAge or 99
		table.insert(CelebrityEvents.events, event)
	end
end

-- CRITICAL FIX #642: Add rapper career events
if CelebrityEvents.RapperCareer and CelebrityEvents.RapperCareer.events then
	for _, event in ipairs(CelebrityEvents.RapperCareer.events) do
		event.isCelebrityOnly = true
		event.careerPath = "rapper"
		event.minAge = event.minAge or 14
		event.maxAge = event.maxAge or 99
		table.insert(CelebrityEvents.events, event)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX: Fame Path Events - trigger when player starts Celebrity story path
-- User feedback: "The storypath doesn't rlly do much when I tried becoming famous"
-- Solution: Add specific events that trigger based on pursuing_fame flag
-- ═══════════════════════════════════════════════════════════════════════════════

local FamePathEvents = {
	-- Initial fame discovery event
	{
		id = "fame_path_youtube_idea",
		title = "💡 YouTube Channel Idea",
		emoji = "💡",
		text = "You've been thinking about starting a YouTube channel! The idea of making videos and building an audience excites you. Maybe you could start posting content?",
		category = "celebrity",
		weight = 25,
		minAge = 13,
		maxAge = 35,
		baseChance = 0.65,
		oneTime = true,
		conditions = { requiresFlags = { pursuing_fame = true } },
		blockedByFlags = { youtube_started = true, content_creator = true },
		choices = {
			{
				text = "Start a gaming channel! 🎮",
				effects = { Happiness = 15, Smarts = 2 },
				setFlags = { youtube_started = true, gaming_content = true, content_creator = true },
				feedText = "You created your first gaming YouTube channel! Time to start uploading.",
				onResolve = function(state)
					state.FameState = state.FameState or {}
					local gain = math.random(10, 50)
					state.FameState.socialFollowers = (state.FameState.socialFollowers or 0) + gain
					state.FameState.followers = (state.FameState.followers or 0) + gain  -- BUG FIX: Sync followers
					state.FameState.contentPlatforms = state.FameState.contentPlatforms or {}
					state.FameState.contentPlatforms.youtube = true
					state.Fame = (state.Fame or 0) + 2
				end,
			},
			{
				text = "Start a lifestyle/vlog channel 📹",
				effects = { Happiness = 15, Looks = 2 },
				setFlags = { youtube_started = true, vlog_content = true, content_creator = true },
				feedText = "You started your vlogging journey! Your first video got 23 views.",
				onResolve = function(state)
					state.FameState = state.FameState or {}
					local gain = math.random(10, 50)
					state.FameState.socialFollowers = (state.FameState.socialFollowers or 0) + gain
					state.FameState.followers = (state.FameState.followers or 0) + gain  -- BUG FIX: Sync followers
					state.FameState.contentPlatforms = state.FameState.contentPlatforms or {}
					state.FameState.contentPlatforms.youtube = true
					state.Fame = (state.Fame or 0) + 2
				end,
			},
			{
				text = "Maybe later...",
				effects = { Happiness = -3 },
				feedText = "You're not ready to start creating content yet.",
			},
		},
	},
	
	-- TikTok opportunity
	{
		id = "fame_path_tiktok_viral",
		title = "📱 TikTok Trend Opportunity",
		emoji = "📱",
		text = "There's a viral TikTok trend happening right now! This could be your chance to get noticed.",
		category = "celebrity",
		weight = 20,
		minAge = 13,
		maxAge = 30,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		conditions = { requiresFlags = { pursuing_fame = true } },
		choices = {
			{
				text = "Jump on the trend! 🔥",
				effects = { Happiness = 10 },
				setFlags = { tiktok_active = true },
				feedText = "You posted your video!",
				triggerMinigame = "qte",
				minigameOptions = { difficulty = "easy" },
				onResolve = function(state, minigameResult)
					if minigameResult and minigameResult.success then
						local followersGain = math.random(100, 5000)
						state.FameState = state.FameState or {}
						-- BUG FIX #1: Sync socialFollowers with main followers counter
						state.FameState.socialFollowers = (state.FameState.socialFollowers or 0) + followersGain
						state.FameState.followers = (state.FameState.followers or 0) + followersGain
						state.Fame = (state.Fame or 0) + math.floor(followersGain / 200)
						if state.AddFeed then
							state:AddFeed("📱 Your TikTok went semi-viral! +" .. followersGain .. " followers!")
						end
					else
						if state.AddFeed then
							state:AddFeed("📱 Your TikTok got some views but didn't blow up.")
						end
						state.Fame = (state.Fame or 0) + 1
					end
				end,
			},
			{
				text = "Create something original instead",
				effects = { Happiness = 8, Smarts = 3 },
				setFlags = { creative_creator = true },
				feedText = "You're working on original content.",
			},
			{
				text = "Not interested in TikTok",
				effects = { Happiness = 2 },
				feedText = "TikTok isn't for you.",
			},
		},
	},
	
	-- Social media following milestone
	{
		id = "fame_path_first_1k_followers",
		title = "🎉 First 1,000 Followers!",
		emoji = "🎉",
		text = "You've hit 1,000 followers on social media! People are starting to notice you!",
		category = "celebrity",
		weight = 18,
		minAge = 13,
		maxAge = 50,
		baseChance = 0.6,
		oneTime = true,
		conditions = { 
			requiresFlags = { pursuing_fame = true },
			custom = function(state)
				return state.FameState and (state.FameState.socialFollowers or 0) >= 500
			end,
		},
		blockedByFlags = { hit_1k_followers = true },
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Celebrate with a giveaway ($100)! 🎁",
				effects = { Happiness = 15, Money = -100 },
				setFlags = { hit_1k_followers = true, generous_creator = true },
				feedText = "The giveaway brought in even more followers!",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for giveaway" end,
				onResolve = function(state)
					state.FameState = state.FameState or {}
					local gain = math.random(200, 500)
					state.FameState.socialFollowers = (state.FameState.socialFollowers or 0) + gain
					state.FameState.followers = (state.FameState.followers or 0) + gain  -- BUG FIX: Sync followers
					state.Fame = (state.Fame or 0) + 5
				end,
			},
			{
				text = "Thank your followers with a special post ❤️",
				effects = { Happiness = 12 },
				setFlags = { hit_1k_followers = true, grateful_creator = true },
				feedText = "Your followers appreciate your gratitude!",
				onResolve = function(state)
					state.Fame = (state.Fame or 0) + 3
				end,
			},
		},
	},
	
	-- Brand deal opportunity
	{
		id = "fame_path_first_brand_deal",
		title = "💼 Brand Deal Offer!",
		emoji = "💼",
		text = "A small brand wants to send you free products in exchange for a post! This is your first brand deal opportunity!",
		category = "celebrity",
		weight = 15,
		minAge = 16,
		maxAge = 45,
		baseChance = 0.5,
		oneTime = true,
		conditions = { 
			requiresFlags = { pursuing_fame = true },
			custom = function(state)
				return (state.Fame or 0) >= 5 or (state.FameState and (state.FameState.socialFollowers or 0) >= 1000)
			end,
		},
		blockedByFlags = { first_brand_deal = true },
		choices = {
			{
				text = "Accept the deal! Free stuff! 🎁",
				effects = { Happiness = 12 },
				setFlags = { first_brand_deal = true, has_brand_deals = true },
				feedText = "You received your first brand partnership! Free products incoming!",
				onResolve = function(state)
					state.Fame = (state.Fame or 0) + 3
					-- Gift them some value from the products
					state.Money = (state.Money or 0) + math.random(50, 200)
				end,
			},
			{
				text = "Negotiate for cash payment 💰",
				effects = { Happiness = 8 },
				feedText = "Negotiating for actual payment...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					if roll <= 40 then
						state.Money = (state.Money or 0) + math.random(100, 500)
						state.Flags = state.Flags or {}
						state.Flags.first_brand_deal = true
						state.Flags.has_brand_deals = true
						state.Fame = (state.Fame or 0) + 4
						if state.AddFeed then
							state:AddFeed("💰 They agreed to pay you! Smart negotiation!")
						end
					else
						state.Flags = state.Flags or {}
						state.Flags.first_brand_deal = true
						if state.AddFeed then
							state:AddFeed("💼 They went with someone else. Maybe next time.")
						end
					end
				end,
			},
			{
				text = "Decline - I want to stay authentic",
				effects = { Happiness = 5 },
				setFlags = { authentic_creator = true },
				feedText = "You're staying true to yourself.",
			},
		},
	},
	
	-- Hater/Critic event
	-- CRITICAL FIX: "First Hater" should only happen ONCE (oneTime = true)
	{
		id = "fame_path_first_hater",
		title = "😠 Your First Hater",
		emoji = "😠",
		text = "Someone left a really mean comment on your content. They're criticizing everything about you. This is a rite of passage for creators...",
		category = "celebrity",
		weight = 20,
		minAge = 13,
		maxAge = 50,
		baseChance = 0.55,
		oneTime = true, -- CRITICAL FIX: First hater should only happen ONCE!
		conditions = { requiresFlags = { pursuing_fame = true, content_creator = true } },
		choices = {
			{
				text = "Ignore them - haters gonna hate 😎",
				effects = { Happiness = 5, Smarts = 3 },
				setFlags = { handles_criticism_well = true },
				feedText = "You rose above the negativity. A true professional.",
			},
			{
				text = "Respond with a clap-back 🔥",
				effects = { Happiness = -2 },
				feedText = "The drama might attract attention...",
				onResolve = function(state)
					local roll = math.random(1, 100)
					if roll <= 50 then
						-- Drama brings attention
						state.Fame = (state.Fame or 0) + 5
						state.FameState = state.FameState or {}
						local gain = math.random(100, 500)
						state.FameState.socialFollowers = (state.FameState.socialFollowers or 0) + gain
						state.FameState.followers = (state.FameState.followers or 0) + gain  -- BUG FIX: Sync followers
						if state.AddFeed then
							state:AddFeed("🔥 The drama went viral! People love the content!")
						end
					else
						-- Backlash
						state.Fame = math.max(0, (state.Fame or 0) - 2)
						if state.AddFeed then
							state:AddFeed("😬 The clap-back backfired. Some followers left...")
						end
					end
				end,
			},
			{
				text = "Delete the comment 🗑️",
				effects = { Happiness = 3 },
				feedText = "You deleted the negativity from your space.",
			},
		},
	},
}

-- Add fame path events to main events list
-- CRITICAL FIX: Fame path events should NOT be isCelebrityOnly!
-- Free players pursuing fame via influencer/streamer careers should also get these events
-- Only the rapper/signed musician paths require Celebrity gamepass, NOT influencer/streamer!
-- User feedback: "Story paths don't do much" - this was blocking events for free fame pursuers
for _, event in ipairs(FamePathEvents) do
	-- CRITICAL: DO NOT set isCelebrityOnly = true here!
	-- These events check for pursuing_fame flag OR fame career flags
	-- This allows free players (influencer/streamer) to get fame-related events
	event.isFameEvent = true -- Custom flag for fame events (doesn't require gamepass)
	
	-- Modify conditions to allow fame career holders too, not just story path users
	if event.conditions then
		event.conditions.allowsFameCareers = true -- Custom flag to enable fame career triggering
	else
		event.conditions = { allowsFameCareers = true }
	end
	
	table.insert(CelebrityEvents.events, event)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRITICAL FIX #538: MEGA EXCITING CELEBRITY-ONLY EVENTS
-- User feedback: "Celebrity gamepass needs to be SO SO SO SO FUN"
-- These events are EXCLUSIVE to Celebrity gamepass holders!
-- Premium experiences that make the gamepass worth every Robux!
-- ═══════════════════════════════════════════════════════════════════════════════

local ExclusivePremiumCelebrityEvents = {
	-- VIRAL MOMENT
	{
		-- CRITICAL FIX: Renamed from "celebrity_viral_moment" to avoid duplicate ID
		id = "celebrity_premium_viral",
		title = "🔥 YOU WENT VIRAL!",
		emoji = "🔥",
		text = "OMG! Something you did just blew up on social media! Everyone is talking about you!",
		category = "celebrity",
		weight = 30,
		minAge = 16,
		maxAge = 80,
		baseChance = 0.45,
		cooldown = 3,
		isCelebrityOnly = true,
		conditions = { requiresFlags = { celebrity_career_chosen = true } },
		choices = {
			{
				text = "Capitalize on the moment! 💰",
				effects = { Money = 500000, Happiness = 25 },
				fameGain = 20,
				feedText = "You struck while the iron was hot! Brand deals pouring in!",
				onResolve = function(state)
					-- CRITICAL FIX: Ensure numbers for math.min
					local currentFame = tonumber(state.Fame) or 0
					state.Fame = math.min(100, currentFame + 20)
					state.Flags = state.Flags or {}
					state.Flags.viral_celebrity = true
					if state.AddFeed then
						state:AddFeed("🔥 VIRAL! Your follower count exploded overnight! You're trending everywhere!")
					end
				end,
			},
			{
				text = "Stay humble and grounded 🙏",
				effects = { Happiness = 15, Smarts = 3 },
				fameGain = 10,
				setFlags = { humble_celebrity = true },
				feedText = "You stayed grounded. Fans respect your authenticity.",
			},
			{
				text = "Go even crazier for more attention! 🤪",
				effects = { Happiness = 10 },
				fameGain = 25,
				feedText = "You doubled down! The internet is obsessed!",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.6 then
						-- CRITICAL FIX: Ensure numbers for math.min
						local currentFame = tonumber(state.Fame) or 0
						state.Fame = math.min(100, currentFame + 25)
						state.Money = (state.Money or 0) + 1000000
						if state.AddFeed then
							state:AddFeed("🔥 LEGENDARY! You turned viral into a cultural moment! Sponsors FIGHTING for you!")
						end
					else
						state.Flags = state.Flags or {}
						state.Flags.controversial_celebrity = true
						if state.AddFeed then
							state:AddFeed("😬 You went too far. Some people cancelled you but others love the drama.")
						end
					end
				end,
			},
		},
	},
	
	-- RED CARPET PREMIERE
	{
		id = "celebrity_red_carpet_premiere",
		title = "🌟 RED CARPET PREMIERE!",
		emoji = "🌟",
		text = "You're invited to a major Hollywood premiere! Cameras flashing, fans screaming your name!",
		category = "celebrity",
		weight = 25,
		minAge = 18,
		maxAge = 90,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		isCelebrityOnly = true,
		conditions = { 
			requiresFlags = { celebrity_career_chosen = true },
			custom = function(state) return (state.Fame or 0) >= 25 end
		},
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Slay the red carpet ($50K outfit)! 👗✨",
				effects = { Looks = 5, Happiness = 20, Money = -50000 },
				fameGain = 15,
				feedText = "Your outfit is going viral! Best dressed of the night!",
				eligibility = function(state) return (state.Money or 0) >= 50000, "💸 Need $50K for designer outfit" end,
			},
			{
				text = "Make a controversial statement! 🎤",
				effects = { Happiness = 10 },
				fameGain = 20,
				feedText = "You made headlines! Everyone is talking!",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.5 then
						-- CRITICAL FIX: Ensure numbers for math.min
						local currentFame = tonumber(state.Fame) or 0
						state.Fame = math.min(100, currentFame + 20)
						if state.AddFeed then
							state:AddFeed("🎤 Your statement resonated! You're being called a voice of a generation!")
						end
					else
						state.Flags = state.Flags or {}
						state.Flags.controversial_statement = true
						if state.AddFeed then
							state:AddFeed("🎤 Polarizing! Half love you, half hate you. Engagement through the roof!")
						end
					end
				end,
			},
			{
				text = "Network with A-listers 🤝",
				effects = { Happiness = 15, Smarts = 2 },
				fameGain = 8,
				setFlags = { a_list_connections = true },
				feedText = "You made powerful connections in the industry!",
			},
		},
	},
	
	-- MASSIVE ENDORSEMENT DEAL
	{
		id = "celebrity_mega_endorsement",
		title = "💎 MEGA BRAND DEAL!",
		emoji = "💎",
		text = "A MASSIVE brand wants YOU as their face! This could change everything!",
		category = "celebrity",
		weight = 20,
		minAge = 18,
		maxAge = 70,
		baseChance = 0.35,
		cooldown = 3,
		isCelebrityOnly = true,
		conditions = { 
			requiresFlags = { celebrity_career_chosen = true },
			custom = function(state) return (state.Fame or 0) >= 40 end
		},
		choices = {
			{
				text = "Sign the deal! 💰 ($5 MILLION!)",
				effects = { Money = 5000000, Happiness = 25 },
				fameGain = 10,
				setFlags = { brand_ambassador = true, has_endorsement_deal = true },
				feedText = "$5 MILLION DEAL SIGNED! You're the face of a global brand!",
			},
			{
				text = "Negotiate for more! 🤑 (Risky)",
				effects = { Happiness = 5 },
				feedText = "You pushed for more...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.4 then
						state.Money = (state.Money or 0) + 15000000
						-- CRITICAL FIX: Ensure numbers for math.min
						local currentFame = tonumber(state.Fame) or 0
						state.Fame = math.min(100, currentFame + 15)
						state.Flags = state.Flags or {}
						state.Flags.brand_ambassador = true
						state.Flags.mega_deal = true
						if state.AddFeed then
							state:AddFeed("💎 LEGENDARY NEGOTIATION! $15 MILLION! You're an icon!")
						end
					else
						if state.AddFeed then
							state:AddFeed("😔 They walked away... You pushed too hard.")
						end
					end
				end,
			},
			{
				text = "Reject it - Stay authentic 🙅",
				effects = { Happiness = 10 },
				fameGain = 5,
				setFlags = { authentic_celebrity = true },
				feedText = "You stayed true to yourself. Fans respect that.",
			},
		},
	},
	
	-- AWARD SHOW WIN
	{
		id = "celebrity_award_win",
		title = "🏆 YOU WON AN AWARD!",
		emoji = "🏆",
		text = "Incredible! You've been nominated for a major industry award... and YOU WON!",
		category = "celebrity",
		weight = 15,
		minAge = 20,
		maxAge = 90,
		baseChance = 0.3,
		cooldown = 4,
		isCelebrityOnly = true,
		conditions = { 
			requiresFlags = { celebrity_career_chosen = true },
			custom = function(state) return (state.Fame or 0) >= 50 end
		},
		choices = {
			{
				text = "Give an inspiring speech! 🎤",
				effects = { Happiness = 30, Smarts = 3 },
				fameGain = 25,
				setFlags = { award_winner = true, inspiring_speaker = true },
				feedText = "Standing ovation! Your speech moved millions! The moment is historic!",
			},
			{
				text = "Thank everyone and keep it short 🙏",
				effects = { Happiness = 25 },
				fameGain = 15,
				setFlags = { award_winner = true },
				feedText = "Classy acceptance. A moment you'll never forget.",
			},
			{
				text = "Go wild! Party all night! 🎉",
				effects = { Happiness = 35, Health = -5 },
				fameGain = 20,
				setFlags = { award_winner = true, party_legend = true },
				feedText = "You celebrated like a champion! What a night!",
			},
		},
	},
	
	-- PAPARAZZI CHASE
	{
		id = "celebrity_paparazzi_chase",
		title = "📸 PAPARAZZI SWARM!",
		emoji = "📸",
		text = "A mob of paparazzi has surrounded you! Cameras everywhere! What do you do?!",
		category = "celebrity",
		weight = 30,
		minAge = 18,
		maxAge = 80,
		baseChance = 0.5,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		isCelebrityOnly = true,
		conditions = { 
			requiresFlags = { celebrity_career_chosen = true },
			custom = function(state) return (state.Fame or 0) >= 30 end
		},
		choices = {
			{
				text = "Strike a pose! 💅",
				effects = { Looks = 2, Happiness = 15 },
				fameGain = 10,
				feedText = "You owned the moment! Tomorrow's front page!",
			},
			{
				text = "Run to your car! 🏃",
				effects = { Health = 2, Happiness = -5 },
				feedText = "You escaped! That was intense!",
			},
			{
				-- CRITICAL FIX: Show lawsuit cost!
				text = "Throw hands at camera ($100K lawsuit)! 👊",
				effects = { Happiness = -10, Money = -100000 },
				fameGain = 15,
				setFlags = { paparazzi_incident = true },
				feedText = "You're getting sued BUT you're trending #1!",
				eligibility = function(state) return (state.Money or 0) >= 100000, "💸 Would cost $100K in lawsuits" end,
			},
			{
				text = "Sign autographs for fans in the crowd 📝",
				effects = { Happiness = 20 },
				fameGain = 8,
				setFlags = { fan_favorite = true },
				feedText = "The fans love you! Videos of your kindness go viral!",
			},
		},
	},
	
	-- COLLABORATION WITH LEGEND
	{
		id = "celebrity_legend_collab",
		title = "👑 COLLAB WITH A LEGEND!",
		emoji = "👑",
		text = "An ABSOLUTE LEGEND in your industry wants to collaborate with YOU!",
		category = "celebrity",
		weight = 15,
		minAge = 20,
		maxAge = 70,
		baseChance = 0.25,
		cooldown = 5,
		isCelebrityOnly = true,
		conditions = { 
			requiresFlags = { celebrity_career_chosen = true },
			custom = function(state) return (state.Fame or 0) >= 45 end
		},
		choices = {
			{
				text = "YES! Dream come true! 🤩",
				effects = { Happiness = 30, Money = 2000000 },
				fameGain = 25,
				setFlags = { collab_with_legend = true },
				feedText = "You collaborated with a LEGEND! Your career has peaked!",
				onResolve = function(state)
					-- CRITICAL FIX: Ensure numbers for math.min
					local currentFame = tonumber(state.Fame) or 0
					state.Fame = math.min(100, currentFame + 25)
					if state.AddFeed then
						state:AddFeed("👑 The collab dropped and BROKE THE INTERNET! You're now legendary too!")
					end
				end,
			},
			{
				text = "Nah, I'm making my own lane 🛣️",
				effects = { Happiness = 10, Smarts = 5 },
				fameGain = 5,
				setFlags = { independent_celebrity = true },
				feedText = "You're carving your own path. Respect.",
			},
		},
	},
	
	-- SCANDAL - DRAMA!
	{
		id = "celebrity_scandal_drama",
		title = "😱 SCANDAL BREAKS!",
		emoji = "😱",
		text = "OH NO! A scandal just hit the news and you're at the center of it!",
		category = "celebrity",
		weight = 20,
		minAge = 18,
		maxAge = 80,
		baseChance = 0.35,
		cooldown = 3,
		isCelebrityOnly = true,
		conditions = { 
			requiresFlags = { celebrity_career_chosen = true },
			custom = function(state) return (state.Fame or 0) >= 35 end
		},
		choices = {
			{
				text = "Address it directly and apologize 🙏",
				effects = { Happiness = -10 },
				fameGain = -5,
				feedText = "You took responsibility. Some respect you more, others moved on.",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.7 then
						state.Flags = state.Flags or {}
						state.Flags.scandal_survivor = true
						if state.AddFeed then
							state:AddFeed("🙏 Your apology was well-received. The storm is passing.")
						end
					else
						state.Fame = math.max(0, (state.Fame or 0) - 10)
						if state.AddFeed then
							state:AddFeed("😔 The public wasn't satisfied. Your reputation took a hit.")
						end
					end
				end,
			},
			{
				text = "Deny everything! 🙅",
				effects = { Happiness = -5 },
				feedText = "You denied it all...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.4 then
						-- CRITICAL FIX: Ensure numbers for math.min
						local currentFame = tonumber(state.Fame) or 0
						state.Fame = math.min(100, currentFame + 5)
						if state.AddFeed then
							state:AddFeed("😌 The story died down. Crisis averted... for now.")
						end
					else
						state.Fame = math.max(0, (state.Fame or 0) - 15)
						state.Flags = state.Flags or {}
						state.Flags.caught_lying = true
						if state.AddFeed then
							state:AddFeed("😬 Evidence came out! The lie made it worse!")
						end
					end
				end,
			},
			{
				text = "Embrace the chaos! 'No such thing as bad press' 🔥",
				effects = { Happiness = 5 },
				fameGain = 10,
				feedText = "You leaned into the controversy!",
				onResolve = function(state)
					-- CRITICAL FIX: Ensure numbers for math.min
					local currentFame = tonumber(state.Fame) or 0
					state.Fame = math.min(100, currentFame + 10)
					state.Flags = state.Flags or {}
					state.Flags.controversial_celebrity = true
					if state.AddFeed then
						state:AddFeed("🔥 The drama made you MORE famous! Your followers doubled!")
					end
				end,
			},
		},
	},
	
	-- EXCLUSIVE PARTY
	{
		id = "celebrity_vip_party",
		title = "🥂 VIP PARTY INVITE!",
		emoji = "🥂",
		text = "You're invited to THE most exclusive party in the world! Celebrities, billionaires, royalty!",
		category = "celebrity",
		weight = 20,
		minAge = 21,
		maxAge = 70,
		baseChance = 0.4,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		isCelebrityOnly = true,
		conditions = { 
			requiresFlags = { celebrity_career_chosen = true },
			custom = function(state) return (state.Fame or 0) >= 40 end
		},
		choices = {
			{
				text = "Go all out! Party like a celebrity! 🎉",
				effects = { Happiness = 30, Health = -5, Money = -25000 },
				fameGain = 15,
				setFlags = { party_celebrity = true },
				feedText = "BEST NIGHT EVER! The photos are EVERYWHERE!",
			},
			{
				text = "Network strategically 🤝",
				effects = { Happiness = 15, Smarts = 3, Money = 100000 },
				fameGain = 10,
				setFlags = { well_connected = true },
				feedText = "You made connections that will pay off for years!",
			},
			{
				text = "Find romance at the party 💕",
				effects = { Happiness = 25 },
				fameGain = 12,
				setFlags = { celebrity_romance = true },
				feedText = "Sparks flew! You might have found someone special...",
			},
		},
	},
	
	-- FAN GIFT
	{
		id = "celebrity_superfan_gift",
		title = "🎁 SUPERFAN GIFT!",
		emoji = "🎁",
		text = "A superfan sent you the most thoughtful, heartfelt gift! It made you emotional...",
		category = "celebrity",
		weight = 25,
		minAge = 16,
		maxAge = 90,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		isCelebrityOnly = true,
		conditions = { requiresFlags = { celebrity_career_chosen = true } },
		choices = {
			{
				text = "Post about it and thank them publicly! 📱",
				effects = { Happiness = 20 },
				fameGain = 8,
				setFlags = { grateful_celebrity = true },
				feedText = "Fans LOVE how genuine you are! The post went viral!",
			},
			{
				text = "Send a personal thank you video! 🎥",
				effects = { Happiness = 25, Smarts = 2 },
				fameGain = 5,
				feedText = "You made their ENTIRE LIFE! They'll never forget this!",
			},
			{
				text = "Just appreciate it privately 🙏",
				effects = { Happiness = 15 },
				feedText = "You kept it between you and them. Pure and genuine.",
			},
		},
	},
}

-- Add exclusive premium celebrity events to main events list
for _, event in ipairs(ExclusivePremiumCelebrityEvents) do
	event.isCelebrityOnly = true -- THESE ARE EXCLUSIVE TO GAMEPASS
	table.insert(CelebrityEvents.events, event)
end

-- Also expose as LifeEvents for backwards compatibility
CelebrityEvents.LifeEvents = CelebrityEvents.events

return CelebrityEvents
