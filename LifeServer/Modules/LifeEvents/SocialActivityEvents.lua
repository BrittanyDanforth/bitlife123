--[[
	SocialActivityEvents.lua
	========================
	Comprehensive event templates for social and nightlife activities.
	These events give players immersive BitLife-style event cards for all
	social outings and nightlife experiences.
	
	NOTE: All alcohol references are removed for Roblox TOS compliance.
	Bar renamed to "Juice Bar" or "Hangout Spot"
	
	Categories:
	- JuiceBar: Hangout spot events (TOS-safe)
	- Nightclub: Dance club events
	- Party: House/social parties
	- Concert: Live music events
	- FriendHangout: Hanging with friends
	- SocialMedia: Online social activities
	- ClubMembership: Social clubs
	- Networking: Professional social events
--]]

local SocialEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- JUICE BAR / HANGOUT SPOT EVENTS (TOS-Safe replacement for bar)
-- ═══════════════════════════════════════════════════════════════════════════════
SocialEvents.JuiceBar = {
	-- Event 1: Regular visit
	{
		id = "juicebar_visit",
		title = "🍹 Hangout Spot",
		texts = {
			"You head to your favorite juice bar to unwind.",
			"The vibe at the hangout spot is perfect tonight.",
			"Music plays as you settle in at the lounge.",
			"Time to relax and socialize at the local spot.",
		},
		effects = { Happiness = {8, 18} },
		choices = {
			{
				text = "Chat with strangers",
				feedback = {
					"You strike up conversation with someone interesting!",
					"Making new connections is exciting!",
					"You might have just made a new friend!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Enjoy the atmosphere alone",
				feedback = {
					"Sometimes solitude is refreshing.",
					"You people-watch and relax.",
					"A peaceful evening to yourself.",
				},
				effects = { Happiness = 12 },
			},
			{
				text = "Join a game of pool/darts",
				feedback = {
					"You challenge someone to a friendly game!",
					"Competition makes the evening more fun!",
					"Win or lose, you have a blast!",
				},
				effects = { Happiness = 15 },
			},
			{
				text = "Leave early - not feeling it",
				feedback = {
					"Tonight's not the night. You head home.",
					"Sometimes the vibe just isn't right.",
					"Maybe next time will be better.",
				},
				effects = { Happiness = -2 },
			},
		},
	},
	-- Event 2: Meeting someone
	{
		id = "juicebar_meet",
		title = "💫 Catching Someone's Eye",
		texts = {
			"Someone attractive keeps glancing your way...",
			"You notice someone cute at the other end of the bar.",
			"There's chemistry in the air tonight.",
		},
		effects = { Happiness = {5, 20} },
		choices = {
			{
				text = "Approach them confidently",
				feedback = {
					"You walk over with a smile. 'Hi there!'",
					"They seem happy you came over!",
					"Confidence is attractive!",
				},
				effects = { Happiness = 20 },
			},
			{
				text = "Send them a smoothie",
				feedback = {
					"A classic move! They raise their glass to you.",
					"Ice broken! Now they're coming over!",
					"Smooth operator!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Smile and wait",
				feedback = {
					"You play it cool and let them come to you.",
					"They gather courage and approach!",
					"Patience pays off!",
				},
				effects = { Happiness = 15 },
			},
			{
				text = "Too nervous - do nothing",
				feedback = {
					"The moment passes... They leave with friends.",
					"Regret settles in. Should've said hi.",
					"Maybe next time you'll be braver.",
				},
				effects = { Happiness = -5 },
			},
		},
	},
	-- Event 3: Karaoke night
	{
		id = "juicebar_karaoke",
		title = "🎤 Karaoke Night!",
		texts = {
			"It's karaoke night at the hangout spot!",
			"The stage is open and the mic awaits!",
			"Will you take your chance to shine?",
		},
		effects = { Happiness = {5, 25} },
		choices = {
			{
				text = "Sing your heart out",
				feedback = {
					"You belt out a power ballad! The crowd goes wild!",
					"Your performance is legendary!",
					"Standing ovation! You're a star!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Do a funny song",
				feedback = {
					"You pick something ridiculous and own it!",
					"Laughter fills the room!",
					"Comedy gold! Everyone's having a blast!",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Duet with a stranger",
				feedback = {
					"You grab a random partner for a duet!",
					"You harmonize surprisingly well!",
					"A memorable performance with a new friend!",
				},
				effects = { Happiness = 20 },
			},
			{
				text = "Stay in the audience",
				feedback = {
					"You enjoy watching others perform.",
					"Some performances are hilarious!",
					"Being in the audience is fun too!",
				},
				effects = { Happiness = 12 },
			},
		},
	},
	-- Event 4: Awkward encounter
	{
		id = "juicebar_awkward",
		title = "😬 Awkward Encounter",
		texts = {
			"You run into your ex at the hangout spot...",
			"Your boss shows up at the same spot you're at!",
			"Someone you'd rather avoid is here tonight.",
		},
		effects = { Happiness = {-10, 5} },
		choices = {
			{
				text = "Say a polite hello",
				feedback = {
					"You keep it civil. Quick hello, then move on.",
					"Mature handling of an awkward situation.",
					"No drama tonight. Well done.",
				},
				effects = { Happiness = 3 },
			},
			{
				text = "Pretend you didn't see them",
				feedback = {
					"You suddenly find your phone very interesting...",
					"They walk past. Crisis averted!",
					"Avoidance successful!",
				},
				effects = { Happiness = -2 },
			},
			{
				text = "Leave immediately",
				feedback = {
					"Nope! Time to go! You're out of there!",
					"Your evening is cut short but drama-free.",
					"Sometimes retreat is the best option.",
				},
				effects = { Happiness = -5 },
			},
			{
				text = "Have an actual conversation",
				feedback = {
					"You decide to face it head-on.",
					"The conversation is... okay, actually?",
					"Maybe it wasn't as bad as you thought.",
				},
				effects = { Happiness = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- NIGHTCLUB EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SocialEvents.Nightclub = {
	-- Event 1: Club night
	{
		id = "nightclub_visit",
		title = "🪩 Club Night!",
		texts = {
			"The bass is thumping and the lights are flashing!",
			"Time to dance the night away at the club!",
			"The dance floor is calling your name!",
		},
		effects = { Happiness = {10, 25} },
		cost = 50,
		choices = {
			{
				text = "Hit the dance floor",
				feedback = {
					"You dance like nobody's watching!",
					"The music flows through you!",
					"This is what living feels like!",
				},
				effects = { Happiness = 25, Health = 5 },
			},
			{
				text = "VIP section",
				feedback = {
					"You splurge on VIP treatment!",
					"Bottle service and velvet ropes!",
					"Living large tonight!",
				},
				effects = { Happiness = 28 },
				cost = 200,
			},
			{
				text = "Hang back and vibe",
				feedback = {
					"You find a good spot to enjoy the scene.",
					"The energy is contagious even from here.",
					"A chill night at the club.",
				},
				effects = { Happiness = 15 },
			},
		},
	},
	-- Event 2: Dance battle
	{
		id = "nightclub_dance_battle",
		title = "💃 Dance Circle!",
		texts = {
			"A dance circle forms and everyone's showing off!",
			"The DJ plays a banger and a battle starts!",
			"People are taking turns showing their moves!",
		},
		effects = { Happiness = {5, 30} },
		choices = {
			{
				text = "Jump in and show off",
				feedback = {
					"You bust out your best moves!",
					"The crowd goes crazy!",
					"You owned that dance floor!",
				},
				effects = { Happiness = 30 },
			},
			{
				text = "Cheer others on",
				feedback = {
					"You hype up the dancers!",
					"Being a great audience is a skill too!",
					"The energy is amazing!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Record it for social media",
				feedback = {
					"You capture the best moments!",
					"This is going viral!",
					"Content creator mode activated!",
				},
				effects = { Happiness = 15 },
			},
		},
	},
	-- Event 3: Meeting DJ
	{
		id = "nightclub_dj",
		title = "🎧 Meeting the DJ",
		texts = {
			"You somehow end up backstage with the DJ!",
			"The DJ notices you vibing to their set!",
			"A chance to connect with the person spinning the tracks!",
		},
		effects = { Happiness = {15, 25} },
		choices = {
			{
				text = "Request a song",
				feedback = {
					"They play your favorite track!",
					"The whole club is dancing to your request!",
					"This is YOUR moment!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Ask about their equipment",
				feedback = {
					"They geek out about their setup!",
					"You learn something about the craft!",
					"Behind-the-scenes knowledge!",
				},
				effects = { Happiness = 18, Smarts = 3 },
			},
			{
				text = "Just say you're a fan",
				feedback = {
					"They appreciate the genuine compliment!",
					"A brief but meaningful connection.",
					"Made their night!",
				},
				effects = { Happiness = 20 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SocialEvents.Party = {
	-- Event 1: House party
	{
		id = "party_house",
		title = "🎉 House Party!",
		texts = {
			"You're invited to a house party!",
			"The party is already in full swing when you arrive!",
			"Music, people, and good vibes await!",
		},
		effects = { Happiness = {10, 22} },
		choices = {
			{
				text = "Be the life of the party",
				feedback = {
					"You're everywhere! Dancing, chatting, having fun!",
					"Everyone seems to know you by the end!",
					"Party MVP!",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Stick with your crew",
				feedback = {
					"You have a great time with your friends!",
					"Quality time with people you love!",
					"Inner circle vibes!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Make new friends",
				feedback = {
					"You branch out and meet new people!",
					"Several interesting conversations!",
					"Expanded your social circle!",
				},
				effects = { Happiness = 20 },
			},
			{
				text = "Find a quiet corner",
				feedback = {
					"You find a chill spot away from the chaos.",
					"Deep conversations happen in quiet corners!",
					"Introverts can party too!",
				},
				effects = { Happiness = 12 },
			},
		},
	},
	-- Event 2: Hosting a party
	{
		id = "party_host",
		title = "🏠 Hosting a Party!",
		texts = {
			"You're throwing a party at your place!",
			"Guests are arriving - time to be an amazing host!",
			"Your party, your rules, your fun!",
		},
		effects = { Happiness = {12, 28} },
		cost = 100,
		choices = {
			{
				text = "Go all out with decorations",
				feedback = {
					"Your place looks amazing!",
					"Guests are impressed by the ambiance!",
					"Pinterest-worthy party!",
				},
				effects = { Happiness = 25 },
				cost = 50,
			},
			{
				text = "Focus on the music",
				feedback = {
					"The playlist is perfect!",
					"Everyone's dancing and having fun!",
					"DJ host in the house!",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Make sure everyone's comfortable",
				feedback = {
					"You're an attentive host!",
					"Guests feel welcome and taken care of!",
					"Hosting skills on point!",
				},
				effects = { Happiness = 20 },
			},
		},
	},
	-- Event 3: Party games
	{
		id = "party_games",
		title = "🎮 Party Games!",
		texts = {
			"Time for party games!",
			"Someone suggests playing a game!",
			"Let the competition begin!",
		},
		effects = { Happiness = {8, 20} },
		choices = {
			{
				text = "Dominate at the game",
				feedback = {
					"You're unstoppable! Victory is yours!",
					"Champion of party games!",
					"Competitive spirit wins!",
				},
				effects = { Happiness = 20 },
			},
			{
				text = "Play for fun, not to win",
				feedback = {
					"You're just here for a good time!",
					"Laughing at your mistakes is the best!",
					"It's not about winning!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Be a good sport about losing",
				feedback = {
					"You lose gracefully!",
					"Good sportsmanship is attractive!",
					"How you lose matters!",
				},
				effects = { Happiness = 12 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONCERT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SocialEvents.Concert = {
	-- Event 1: Live concert
	{
		id = "concert_attend",
		title = "🎵 Live Concert!",
		texts = {
			"You're at a live concert!",
			"The crowd is electric with anticipation!",
			"The band/artist is about to perform!",
		},
		effects = { Happiness = {15, 30} },
		cost = 100,
		choices = {
			{
				text = "Push to the front",
				feedback = {
					"You make it to the front row!",
					"So close you can feel the energy!",
					"Unforgettable experience!",
				},
				effects = { Happiness = 30 },
			},
			{
				text = "Enjoy from a good spot",
				feedback = {
					"You find the perfect viewing spot!",
					"Great sound and view!",
					"Concert experience perfected!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Dance and sing along",
				feedback = {
					"You know every word!",
					"Lost in the music!",
					"This is what concerts are for!",
				},
				effects = { Happiness = 28 },
			},
		},
	},
	-- Event 2: Meeting fans
	{
		id = "concert_fans",
		title = "👥 Concert Friends",
		texts = {
			"You bond with people around you at the concert!",
			"Shared music taste creates instant connections!",
			"The fan community is welcoming!",
		},
		effects = { Happiness = {12, 22} },
		choices = {
			{
				text = "Exchange social media",
				feedback = {
					"New concert buddies added!",
					"You'll hit up shows together now!",
					"Friends through music!",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Just enjoy the moment",
				feedback = {
					"A connection for tonight!",
					"Not everything needs to last forever.",
					"Beautiful temporary friendship!",
				},
				effects = { Happiness = 18 },
			},
		},
	},
	-- Event 3: Encore
	{
		id = "concert_encore",
		title = "🌟 Encore!",
		texts = {
			"The show 'ends' but the crowd wants more!",
			"'ENCORE! ENCORE!' the audience chants!",
			"Will they come back out?",
		},
		effects = { Happiness = {18, 30} },
		choices = {
			{
				text = "Chant with everyone",
				feedback = {
					"The unified chanting works! They return!",
					"THEY'RE PLAYING THE HIT!",
					"Best. Encore. Ever!",
				},
				effects = { Happiness = 30 },
			},
			{
				text = "Enjoy watching the crowd",
				feedback = {
					"The collective energy is beautiful.",
					"Everyone united in wanting more.",
					"This is community!",
				},
				effects = { Happiness = 22 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FRIEND HANGOUT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SocialEvents.FriendHangout = {
	-- Event 1: Casual hangout
	{
		id = "friend_casual",
		title = "👋 Hanging With Friends",
		texts = {
			"Time to hang out with your friends!",
			"Your crew is getting together!",
			"Nothing beats quality time with friends!",
		},
		effects = { Happiness = {12, 22} },
		choices = {
			{
				text = "Go out somewhere fun",
				feedback = {
					"Adventure with friends!",
					"Making memories together!",
					"Best day ever with the crew!",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Chill at someone's place",
				feedback = {
					"Low-key hangout vibes!",
					"Relaxation with your favorite people!",
					"Sometimes simple is best!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Try something new together",
				feedback = {
					"You all experience something for the first time!",
					"Shared new experiences bond you closer!",
					"Adventure squad!",
				},
				effects = { Happiness = 20 },
			},
		},
	},
	-- Event 2: Deep conversation
	{
		id = "friend_deep_talk",
		title = "💭 Real Talk",
		texts = {
			"The conversation gets real with your friends.",
			"You have a meaningful heart-to-heart.",
			"True friendship goes beyond surface level.",
		},
		effects = { Happiness = {15, 25} },
		choices = {
			{
				text = "Open up about your life",
				feedback = {
					"You share what's really going on with you.",
					"Your friends listen and support you.",
					"Vulnerability strengthens bonds.",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Listen and be there for them",
				feedback = {
					"Your friend needs you and you're there.",
					"Sometimes being present is enough.",
					"Friendship is about being there.",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Laugh about life together",
				feedback = {
					"You find humor in the struggles.",
					"Laughter is the best medicine!",
					"Friends who laugh together stay together!",
				},
				effects = { Happiness = 20 },
			},
		},
	},
	-- Event 3: Friend group drama
	{
		id = "friend_drama",
		title = "😮 Friend Drama",
		texts = {
			"There's some tension in your friend group...",
			"Two of your friends are having issues.",
			"Drama has entered the chat.",
		},
		effects = { Happiness = {-10, 5} },
		choices = {
			{
				text = "Try to mediate",
				feedback = {
					"You try to help them work it out.",
					"Your peacemaking skills are tested.",
					"Maybe you helped, maybe you didn't.",
				},
				effects = { Happiness = 3 },
			},
			{
				text = "Stay neutral",
				feedback = {
					"You refuse to pick sides.",
					"Smart but uncomfortable.",
					"Neutrality is its own position.",
				},
				effects = { Happiness = -2 },
			},
			{
				text = "Support one friend",
				feedback = {
					"You believe one friend is right.",
					"Your loyalty is clear.",
					"Hope it doesn't backfire...",
				},
				effects = { Happiness = -5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOCIAL MEDIA EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SocialEvents.SocialMedia = {
	-- Event 1: Posting content
	{
		id = "social_post",
		title = "📱 Posting Online",
		texts = {
			"Time to share something on social media!",
			"Your followers await your content!",
			"What to post today?",
		},
		effects = { Happiness = {5, 18} },
		choices = {
			{
				text = "Post something authentic",
				feedback = {
					"Real content resonates with people!",
					"Your genuine post gets positive reactions!",
					"Authenticity wins!",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Share a meme",
				feedback = {
					"Your meme game is strong!",
					"Laughter spreads across the internet!",
					"Comedy content creator!",
				},
				effects = { Happiness = 15 },
			},
			{
				text = "Post an achievement",
				feedback = {
					"You share something you're proud of!",
					"Celebration with your online community!",
					"Humble brag executed successfully!",
				},
				effects = { Happiness = 16 },
			},
		},
	},
	-- Event 2: Going viral
	{
		id = "social_viral",
		title = "🔥 Going Viral!",
		texts = {
			"Your post is blowing up!",
			"Notifications won't stop coming!",
			"You've gone viral!",
		},
		effects = { Happiness = {20, 35} },
		choices = {
			{
				text = "Enjoy the attention",
				feedback = {
					"This is your 15 minutes of fame!",
					"Ride the wave!",
					"Internet famous!",
				},
				effects = { Happiness = 35 },
			},
			{
				text = "Engage with new followers",
				feedback = {
					"You respond to comments and DMs!",
					"Building a community!",
					"Social media mogul in the making!",
				},
				effects = { Happiness = 30 },
			},
			{
				text = "Get overwhelmed",
				feedback = {
					"Too much attention too fast!",
					"The internet can be intense.",
					"Fame isn't always comfortable.",
				},
				effects = { Happiness = 15 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- NETWORKING EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SocialEvents.Networking = {
	-- Event 1: Professional event
	{
		id = "network_event",
		title = "🤝 Networking Event",
		texts = {
			"You attend a professional networking event.",
			"Time to make some career connections!",
			"Business cards at the ready!",
		},
		effects = { Happiness = {5, 15}, Smarts = {3, 8} },
		choices = {
			{
				text = "Work the room confidently",
				feedback = {
					"You meet several interesting people!",
					"Connections that could help your career!",
					"Networking pro!",
				},
				effects = { Happiness = 15, Smarts = 8 },
			},
			{
				text = "Focus on quality conversations",
				feedback = {
					"You have meaningful talks with a few people.",
					"Depth over breadth.",
					"Real connections made!",
				},
				effects = { Happiness = 12, Smarts = 5 },
			},
			{
				text = "Feel awkward and leave early",
				feedback = {
					"Networking isn't for everyone...",
					"You tried, at least.",
					"Social energy depleted.",
				},
				effects = { Happiness = -5 },
			},
		},
	},
	-- Event 2: Valuable connection
	{
		id = "network_valuable",
		title = "💼 Valuable Connection!",
		texts = {
			"You meet someone important in your industry!",
			"This person could really help your career!",
			"An opportunity to make an impression!",
		},
		effects = { Happiness = {10, 22}, Smarts = {5, 10} },
		choices = {
			{
				text = "Impress them with your knowledge",
				feedback = {
					"You demonstrate your expertise!",
					"They're clearly impressed!",
					"Door opened for future opportunities!",
				},
				effects = { Happiness = 22, Smarts = 10 },
			},
			{
				text = "Be genuinely interested in them",
				feedback = {
					"You ask thoughtful questions!",
					"People love talking about themselves!",
					"A real connection forms!",
				},
				effects = { Happiness = 20, Smarts = 5 },
			},
			{
				text = "Exchange contact info quickly",
				feedback = {
					"You secure the connection!",
					"Brief but potentially valuable.",
					"Follow-up is key now!",
				},
				effects = { Happiness = 15, Smarts = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAPPING TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
SocialEvents.ActivityMapping = {
	["bar"] = "JuiceBar",
	["juice_bar"] = "JuiceBar",
	["hangout_spot"] = "JuiceBar",
	["lounge"] = "JuiceBar",
	["nightclub"] = "Nightclub",
	["club"] = "Nightclub",
	["dancing"] = "Nightclub",
	["party"] = "Party",
	["house_party"] = "Party",
	["host_party"] = "Party",
	["concert"] = "Concert",
	["live_music"] = "Concert",
	["show"] = "Concert",
	["friend"] = "FriendHangout",
	["hangout"] = "FriendHangout",
	["hang_out"] = "FriendHangout",
	["social_media"] = "SocialMedia",
	["post"] = "SocialMedia",
	["online"] = "SocialMedia",
	["network"] = "Networking",
	["networking"] = "Networking",
	["professional"] = "Networking",
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════
function SocialEvents.getEventForActivity(activityId)
	local categoryName = SocialEvents.ActivityMapping[activityId]
	if not categoryName then
		-- Try partial matching
		for key, cat in pairs(SocialEvents.ActivityMapping) do
			if string.find(activityId:lower(), key) or string.find(key, activityId:lower()) then
				categoryName = cat
				break
			end
		end
	end
	
	if not categoryName then
		return nil
	end
	
	local eventList = SocialEvents[categoryName]
	if not eventList or #eventList == 0 then
		return nil
	end
	
	-- Return random event from category
	return eventList[math.random(1, #eventList)]
end

function SocialEvents.getAllCategories()
	return {"JuiceBar", "Nightclub", "Party", "Concert", "FriendHangout", "SocialMedia", "Networking"}
end

return SocialEvents
