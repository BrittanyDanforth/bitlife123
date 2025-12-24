--[[
	VacationActivityEvents.lua
	==========================
	Comprehensive event templates for vacation and travel activities.
	These events give players immersive BitLife-style event cards for all
	travel-related experiences with 20+ unique destinations.
	
	Destinations:
	- Beach: Tropical beach vacations
	- Mountain: Mountain retreats
	- City: Urban tourism
	- Cruise: Cruise ship vacations
	- Safari: Wildlife adventures
	- Historical: Historical site visits
	- Theme Park: Amusement park trips
	- Ski Resort: Winter sports vacations
	- Island: Island getaways
	- Road Trip: Cross-country adventures
	- Camping: Outdoor camping
	- European: European destinations
	- Asian: Asian destinations
	- Caribbean: Caribbean islands
	- Adventure: Extreme adventure travel
	- Luxury: High-end luxury vacations
	- Budget: Budget backpacking
	- Romantic: Couple's getaways
	- Family: Family-friendly destinations
	- Solo: Solo travel adventures
--]]

local VacationEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS (CRITICAL FIX: Nil-safe operations)
-- ═══════════════════════════════════════════════════════════════════════════════
local function safeModifyStat(state, stat, amount)
	if not state then return end
	if state.ModifyStat then
		state:ModifyStat(stat, amount)
	elseif state.Stats then
		state.Stats[stat] = math.clamp((state.Stats[stat] or 50) + amount, 0, 100)
	else
		state[stat] = math.clamp((state[stat] or 50) + amount, 0, 100)
	end
end

-- CRITICAL FIX: Check if player can go on vacation
local function canGoOnVacation(state)
	if not state then return false end
	local flags = state.Flags or {}
	-- Can't go on vacation from prison!
	if flags.in_prison or flags.incarcerated or flags.in_jail then
		return false
	end
	-- Can't travel if homeless (no money for travel)
	if flags.homeless and (state.Money or 0) < 500 then
		return false
	end
	return true
end

-- CRITICAL FIX: Check if player can afford vacation
local function canAffordVacation(state, cost)
	return (state.Money or 0) >= (cost or 0)
end

-- CRITICAL FIX: Process vacation cost safely
local function processVacationCost(state, cost)
	if not cost or cost <= 0 then return true end
	if not state then return false end
	
	local money = state.Money or 0
	if money < cost then return false end
	
	state.Money = money - cost
	return true
end

-- CRITICAL FIX: Module-wide eligibility
VacationEvents.moduleEligibility = function(state)
	return canGoOnVacation(state)
end

VacationEvents.moduleBlockedFlags = { in_prison = true, incarcerated = true, in_jail = true }

-- ═══════════════════════════════════════════════════════════════════════════════
-- BEACH VACATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Beach = {
	-- CRITICAL FIX: Category eligibility
	eligibility = function(state) return canGoOnVacation(state) and canAffordVacation(state, 2000) end,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	{
		id = "vacation_beach_paradise",
		title = "🏖️ Beach Paradise",
		texts = {
			"White sand, crystal clear water, perfect weather!",
			"You've arrived at a tropical beach paradise!",
			"The sound of waves and palm trees swaying...",
		},
		effects = { Happiness = {20, 35}, Health = {5, 15} },
		cost = 2000,
		choices = {
			{
				text = "Relax by the water",
				feedback = {
					"You lounge on the beach all day!",
					"Absolute relaxation and peace!",
					"This is what vacation is all about!",
				},
				effects = { Happiness = 35, Health = 15 },
			},
			{
				text = "Try water sports",
				feedback = {
					"Surfing, snorkeling, jet skiing!",
					"Adventure on the water!",
					"Adrenaline and ocean vibes!",
				},
				effects = { Happiness = 32, Health = 10 },
			},
			{
				text = "Explore the local area",
				feedback = {
					"You discover hidden beaches and local spots!",
					"The best experiences are off the beaten path!",
					"Cultural immersion at its finest!",
				},
				effects = { Happiness = 28, Smarts = 5 },
			},
		},
	},
	{
		id = "vacation_beach_sunset",
		title = "🌅 Beach Sunset",
		texts = {
			"The sun is setting over the ocean.",
			"Colors paint the sky in orange and purple.",
			"A perfect end to a perfect day.",
		},
		effects = { Happiness = {15, 25} },
		choices = {
			{
				text = "Take photos",
				feedback = {
					"You capture the perfect shot!",
					"Memories preserved forever!",
					"Social media gold!",
				},
				effects = { Happiness = 22 },
			},
			{
				text = "Just enjoy the moment",
				feedback = {
					"Some moments are best lived, not photographed.",
					"Peace washes over you.",
					"Pure contentment.",
				},
				effects = { Happiness = 25 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MOUNTAIN VACATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Mountain = {
	-- CRITICAL FIX: Category eligibility
	eligibility = function(state) return canGoOnVacation(state) and canAffordVacation(state, 1500) end,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	{
		id = "vacation_mountain_retreat",
		title = "⛰️ Mountain Retreat",
		texts = {
			"You arrive at a cozy mountain lodge.",
			"Fresh air and stunning views surround you.",
			"The mountains are calling!",
		},
		effects = { Happiness = {20, 32}, Health = {8, 18} },
		cost = 1500,
		choices = {
			{
				text = "Go hiking",
				feedback = {
					"You trek through beautiful trails!",
					"The view from the summit is breathtaking!",
					"Nature at its finest!",
				},
				effects = { Happiness = 30, Health = 18 },
			},
			{
				text = "Relax at the lodge",
				feedback = {
					"Hot cocoa by the fireplace!",
					"Cozy mountain vibes!",
					"Rest and relaxation in nature!",
				},
				effects = { Happiness = 25, Health = 10 },
			},
			{
				text = "Wildlife watching",
				feedback = {
					"You spot deer, eagles, and more!",
					"Nature's creatures in their habitat!",
					"Magical wildlife encounters!",
				},
				effects = { Happiness = 28, Smarts = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CITY VACATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.City = {
	-- CRITICAL FIX: Category eligibility
	eligibility = function(state) return canGoOnVacation(state) and canAffordVacation(state, 1800) end,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	{
		id = "vacation_city_explore",
		title = "🏙️ City Adventure",
		texts = {
			"The big city has so much to offer!",
			"Skyscrapers, restaurants, culture galore!",
			"Urban exploration awaits!",
		},
		effects = { Happiness = {18, 30}, Smarts = {5, 12} },
		cost = 1800,
		choices = {
			{
				text = "Visit famous landmarks",
				feedback = {
					"You see all the must-see attractions!",
					"Iconic sights checked off your list!",
					"Tourist mode: activated!",
				},
				effects = { Happiness = 28, Smarts = 10 },
			},
			{
				text = "Try local cuisine",
				feedback = {
					"Food tour through the city!",
					"Your taste buds are on vacation too!",
					"Culinary adventure!",
				},
				effects = { Happiness = 30 },
			},
			{
				text = "Experience the nightlife",
				feedback = {
					"The city comes alive at night!",
					"Dancing, music, excitement!",
					"Unforgettable nights out!",
				},
				effects = { Happiness = 32 },
			},
			{
				text = "Museum and gallery hopping",
				feedback = {
					"Art and history everywhere!",
					"Cultural enrichment at every turn!",
					"Your mind is expanded!",
				},
				effects = { Happiness = 22, Smarts = 15 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CRUISE VACATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Cruise = {
	-- CRITICAL FIX: Category eligibility - cruises are expensive!
	eligibility = function(state) return canGoOnVacation(state) and canAffordVacation(state, 3500) end,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	{
		id = "vacation_cruise_luxury",
		title = "🚢 Luxury Cruise",
		texts = {
			"All aboard the luxury cruise ship!",
			"The open ocean awaits!",
			"Days of pampering and adventure on the seas!",
		},
		effects = { Happiness = {25, 40}, Health = {5, 12} },
		cost = 3500,
		choices = {
			{
				text = "Enjoy the ship amenities",
				feedback = {
					"Pools, spas, shows, unlimited food!",
					"Living like royalty at sea!",
					"This ship has everything!",
				},
				effects = { Happiness = 38 },
			},
			{
				text = "Explore port destinations",
				feedback = {
					"New places at every stop!",
					"The best of multiple destinations!",
					"A different adventure each day!",
				},
				effects = { Happiness = 35, Smarts = 8 },
			},
			{
				text = "Make friends on board",
				feedback = {
					"You meet amazing people from around the world!",
					"Cruise friends are special!",
					"Social butterfly at sea!",
				},
				effects = { Happiness = 30 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SAFARI VACATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Safari = {
	-- CRITICAL FIX: Category eligibility - safaris are very expensive!
	eligibility = function(state) return canGoOnVacation(state) and canAffordVacation(state, 5000) end,
	blockedByFlags = { in_prison = true, incarcerated = true, in_jail = true },
	{
		id = "vacation_safari_africa",
		title = "🦁 African Safari",
		texts = {
			"The savanna stretches before you!",
			"Wildlife as far as the eye can see!",
			"This is a once-in-a-lifetime experience!",
		},
		effects = { Happiness = {30, 45}, Smarts = {8, 15} },
		cost = 5000,
		choices = {
			{
				text = "Go on a game drive",
				feedback = {
					"You see the Big Five!",
					"Lions, elephants, buffalo, leopards, rhinos!",
					"Nature documentary come to life!",
				},
				effects = { Happiness = 45, Smarts = 15 },
			},
			{
				text = "Photography focus",
				feedback = {
					"You capture National Geographic-worthy shots!",
					"Every frame tells a story!",
					"Wildlife photography dreams!",
				},
				effects = { Happiness = 40, Smarts = 10 },
			},
			{
				text = "Learn about conservation",
				feedback = {
					"You understand the importance of wildlife preservation!",
					"Educational and inspiring!",
					"A changed perspective on nature!",
				},
				effects = { Happiness = 35, Smarts = 18 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HISTORICAL VACATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Historical = {
	{
		id = "vacation_historical_tour",
		title = "🏛️ Historical Journey",
		texts = {
			"You visit ancient ruins and historical sites!",
			"History comes alive before your eyes!",
			"Walking where legends once walked!",
		},
		effects = { Happiness = {20, 32}, Smarts = {10, 20} },
		cost = 2200,
		choices = {
			{
				text = "Take a guided tour",
				feedback = {
					"The guide's knowledge is incredible!",
					"Stories and facts fill your mind!",
					"History becomes fascinating!",
				},
				effects = { Happiness = 28, Smarts = 20 },
			},
			{
				text = "Explore independently",
				feedback = {
					"You wander at your own pace!",
					"Discovering hidden gems!",
					"Personal connection with history!",
				},
				effects = { Happiness = 30, Smarts = 15 },
			},
			{
				text = "Research before visiting",
				feedback = {
					"Your prep makes everything more meaningful!",
					"You understand the significance of everything!",
					"Well-prepared tourist!",
				},
				effects = { Happiness = 25, Smarts = 22 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- THEME PARK VACATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.ThemePark = {
	{
		id = "vacation_theme_park",
		title = "🎢 Theme Park Adventure!",
		texts = {
			"Roller coasters, characters, and magic!",
			"The happiest place on Earth!",
			"Theme park dreams come true!",
		},
		effects = { Happiness = {30, 45} },
		cost = 1500,
		choices = {
			{
				text = "Ride every coaster",
				feedback = {
					"Adrenaline junkie paradise!",
					"Screaming with joy on every ride!",
					"Thrill seeker status achieved!",
				},
				effects = { Happiness = 45 },
			},
			{
				text = "See all the shows",
				feedback = {
					"Entertainment everywhere!",
					"Parades, fireworks, performances!",
					"Pure magic!",
				},
				effects = { Happiness = 40 },
			},
			{
				text = "Meet characters",
				feedback = {
					"Your childhood heroes in person!",
					"Photos and hugs with beloved characters!",
					"Dreams really do come true!",
				},
				effects = { Happiness = 42 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SKI RESORT VACATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.SkiResort = {
	{
		id = "vacation_ski_resort",
		title = "⛷️ Ski Resort Fun!",
		texts = {
			"Fresh powder and mountain peaks!",
			"Winter wonderland vacation!",
			"The slopes are calling!",
		},
		effects = { Happiness = {25, 38}, Health = {8, 18} },
		cost = 2500,
		choices = {
			{
				text = "Hit the slopes",
				feedback = {
					"Carving through fresh snow!",
					"What a rush!",
					"Skiing/snowboarding paradise!",
				},
				effects = { Happiness = 38, Health = 18 },
			},
			{
				text = "Take lessons",
				feedback = {
					"Learning from the pros!",
					"Your skills improve dramatically!",
					"From beginner to intermediate!",
				},
				effects = { Happiness = 30, Smarts = 8, Health = 12 },
			},
			{
				text = "Après-ski relaxation",
				feedback = {
					"Hot tub and warm drinks after the slopes!",
					"The perfect end to a ski day!",
					"Mountain lodge luxury!",
				},
				effects = { Happiness = 35, Health = 10 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ISLAND GETAWAY
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Island = {
	{
		id = "vacation_island_escape",
		title = "🏝️ Private Island Escape",
		texts = {
			"Your own slice of paradise!",
			"Turquoise waters and swaying palms!",
			"Island time has officially begun!",
		},
		effects = { Happiness = {28, 42}, Health = {10, 18} },
		cost = 4000,
		choices = {
			{
				text = "Disconnect completely",
				feedback = {
					"No phone, no stress, no problems!",
					"True digital detox!",
					"Peace like you've never known!",
				},
				effects = { Happiness = 42, Health = 18 },
			},
			{
				text = "Island hopping",
				feedback = {
					"Explore multiple islands!",
					"Each one more beautiful than the last!",
					"Endless discoveries!",
				},
				effects = { Happiness = 38, Health = 12 },
			},
			{
				text = "Scuba diving",
				feedback = {
					"Underwater paradise awaits!",
					"Coral reefs and tropical fish!",
					"Another world beneath the waves!",
				},
				effects = { Happiness = 40, Health = 10, Smarts = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROAD TRIP
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.RoadTrip = {
	{
		id = "vacation_road_trip",
		title = "🚗 Epic Road Trip!",
		texts = {
			"Open road, great music, endless possibilities!",
			"Adventure awaits around every corner!",
			"The journey is the destination!",
		},
		effects = { Happiness = {22, 35} },
		cost = 1000,
		choices = {
			{
				text = "Follow the plan",
				feedback = {
					"Every stop planned perfectly!",
					"Efficient and satisfying!",
					"No time wasted!",
				},
				effects = { Happiness = 30 },
			},
			{
				text = "Go wherever the road takes you",
				feedback = {
					"Spontaneous adventures are the best!",
					"You discover places you never knew existed!",
					"True road trip spirit!",
				},
				effects = { Happiness = 35 },
			},
			{
				text = "Stop at every quirky attraction",
				feedback = {
					"World's largest ball of yarn? Yes!",
					"Weird roadside attractions are your thing!",
					"Instagram-worthy weirdness!",
				},
				effects = { Happiness = 32 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CAMPING
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Camping = {
	{
		id = "vacation_camping",
		title = "⛺ Camping Adventure",
		texts = {
			"Nature, campfires, and starry nights!",
			"Back to basics in the great outdoors!",
			"The wilderness awaits!",
		},
		effects = { Happiness = {18, 32}, Health = {8, 15} },
		cost = 200,
		choices = {
			{
				text = "Rough it authentic style",
				feedback = {
					"No luxuries, just you and nature!",
					"Survival skills put to the test!",
					"A true outdoor experience!",
				},
				effects = { Happiness = 28, Health = 15, Smarts = 5 },
			},
			{
				text = "Glamping with comfort",
				feedback = {
					"Nature with a touch of luxury!",
					"Best of both worlds!",
					"Comfortable camping!",
				},
				effects = { Happiness = 32, Health = 10 },
			},
			{
				text = "Focus on campfire activities",
				feedback = {
					"S'mores, stories, stargazing!",
					"Classic camping vibes!",
					"Making memories around the fire!",
				},
				effects = { Happiness = 30, Health = 8 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- EUROPEAN DESTINATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.European = {
	{
		id = "vacation_europe_tour",
		title = "🗼 European Adventure",
		texts = {
			"Europe is full of history, culture, and amazing food!",
			"From ancient ruins to modern marvels!",
			"The Old World has so much to offer!",
		},
		effects = { Happiness = {28, 42}, Smarts = {10, 18} },
		cost = 4000,
		choices = {
			{
				text = "Paris, city of lights",
				feedback = {
					"The Eiffel Tower, the Louvre, croissants!",
					"Romance and art everywhere!",
					"Très magnifique!",
				},
				effects = { Happiness = 40, Smarts = 15 },
			},
			{
				text = "Rome, eternal city",
				feedback = {
					"The Colosseum, Vatican, incredible pasta!",
					"Walking through history!",
					"When in Rome!",
				},
				effects = { Happiness = 38, Smarts = 18 },
			},
			{
				text = "Multi-country train tour",
				feedback = {
					"Multiple countries, endless experiences!",
					"The beauty of European rail travel!",
					"Each stop a new adventure!",
				},
				effects = { Happiness = 42, Smarts = 15 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ASIAN DESTINATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Asian = {
	{
		id = "vacation_asia_explore",
		title = "🏯 Asian Exploration",
		texts = {
			"Ancient temples, modern cities, exotic cuisine!",
			"The Far East has so much to discover!",
			"Culture shock in the best way!",
		},
		effects = { Happiness = {28, 40}, Smarts = {10, 18} },
		cost = 3500,
		choices = {
			{
				text = "Tokyo, Japan",
				feedback = {
					"Technology meets tradition!",
					"Sushi, anime, cherry blossoms!",
					"Mind-blowing in every way!",
				},
				effects = { Happiness = 40, Smarts = 15 },
			},
			{
				text = "Thailand adventure",
				feedback = {
					"Temples, beaches, incredible food!",
					"Thai hospitality is unmatched!",
					"Land of Smiles indeed!",
				},
				effects = { Happiness = 38, Smarts = 12 },
			},
			{
				text = "Bali, Indonesia",
				feedback = {
					"Spiritual retreats and natural beauty!",
					"Find your zen in paradise!",
					"Soul-enriching experience!",
				},
				effects = { Happiness = 35, Health = 10, Smarts = 10 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CARIBBEAN DESTINATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Caribbean = {
	{
		id = "vacation_caribbean",
		title = "🌴 Caribbean Paradise",
		texts = {
			"Reggae music, rum cocktails, and endless beaches!",
			"Island vibes at their finest!",
			"Paradise found in the Caribbean!",
		},
		effects = { Happiness = {28, 40}, Health = {8, 15} },
		cost = 2800,
		choices = {
			{
				text = "Jamaica, mon",
				feedback = {
					"Jerk chicken, waterfalls, and good vibes!",
					"One love, one heart!",
					"Caribbean culture at its best!",
				},
				effects = { Happiness = 38, Health = 12 },
			},
			{
				text = "Bahamas luxury",
				feedback = {
					"Crystal clear waters and white sand!",
					"Luxury resort living!",
					"Bahamian bliss!",
				},
				effects = { Happiness = 40, Health = 15 },
			},
			{
				text = "Island hop multiple destinations",
				feedback = {
					"Each island has its own personality!",
					"So much variety in the Caribbean!",
					"Island exploration mode!",
				},
				effects = { Happiness = 35, Smarts = 8 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ADVENTURE TRAVEL
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Adventure = {
	{
		id = "vacation_extreme",
		title = "🪂 Extreme Adventure!",
		texts = {
			"For adrenaline junkies only!",
			"Push your limits and face your fears!",
			"Adventure of a lifetime!",
		},
		effects = { Happiness = {25, 50}, Health = {-5, 15} },
		cost = 3000,
		choices = {
			{
				text = "Skydiving",
				feedback = {
					"JUMPING OUT OF A PLANE!",
					"The ultimate rush!",
					"You did it! You flew!",
				},
				effects = { Happiness = 50, Health = 10 },
			},
			{
				text = "Bungee jumping",
				feedback = {
					"Leap of faith off a bridge!",
					"Your heart has never beat this fast!",
					"Terrifying and amazing!",
				},
				effects = { Happiness = 45, Health = 5 },
			},
			{
				text = "White water rafting",
				feedback = {
					"Class V rapids ahead!",
					"Teamwork and adrenaline!",
					"Wild ride!",
				},
				effects = { Happiness = 40, Health = 15 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- LUXURY TRAVEL
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Luxury = {
	{
		id = "vacation_luxury",
		title = "💎 Luxury Vacation",
		texts = {
			"No expense spared for this trip!",
			"Five-star everything!",
			"Living like royalty!",
		},
		effects = { Happiness = {35, 50} },
		cost = 10000,
		choices = {
			{
				text = "Private villa experience",
				feedback = {
					"Your own private paradise!",
					"Butler service, private pool, absolute luxury!",
					"This is the life!",
				},
				effects = { Happiness = 50 },
			},
			{
				text = "Fine dining tour",
				feedback = {
					"Michelin-starred restaurants every night!",
					"Your palate has ascended!",
					"Culinary excellence!",
				},
				effects = { Happiness = 45 },
			},
			{
				text = "Spa retreat",
				feedback = {
					"Pampered from head to toe!",
					"Stress? What stress?",
					"Complete rejuvenation!",
				},
				effects = { Happiness = 48, Health = 20 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- BUDGET TRAVEL
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Budget = {
	{
		id = "vacation_backpacking",
		title = "🎒 Budget Backpacking",
		texts = {
			"Traveling on a shoestring budget!",
			"Hostels, street food, and adventure!",
			"Who needs luxury when you have experiences?",
		},
		effects = { Happiness = {20, 35}, Smarts = {8, 15} },
		cost = 500,
		choices = {
			{
				text = "Embrace hostel life",
				feedback = {
					"You meet amazing fellow travelers!",
					"Stories and friendships from around the world!",
					"The backpacker community is amazing!",
				},
				effects = { Happiness = 35, Smarts = 12 },
			},
			{
				text = "Find local hidden gems",
				feedback = {
					"Authentic experiences off the tourist trail!",
					"You eat where locals eat!",
					"Real cultural immersion!",
				},
				effects = { Happiness = 32, Smarts = 15 },
			},
			{
				text = "Stretch every dollar",
				feedback = {
					"Creative budget travel hacks!",
					"Maximum experience, minimum cost!",
					"Proud of your resourcefulness!",
				},
				effects = { Happiness = 28, Smarts = 10 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROMANTIC GETAWAY
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Romantic = {
	{
		id = "vacation_romantic",
		title = "💕 Romantic Getaway",
		texts = {
			"A trip just for the two of you!",
			"Romance is in the air!",
			"Creating memories together!",
		},
		effects = { Happiness = {30, 45}, Relationship = {15, 30} },
		cost = 3000,
		choices = {
			{
				text = "Candlelit dinners every night",
				feedback = {
					"Wine, food, and deep conversations!",
					"Your connection deepens!",
					"Romance at its finest!",
				},
				effects = { Happiness = 42, Relationship = 28 },
			},
			{
				text = "Adventure together",
				feedback = {
					"Couples who adventure together stay together!",
					"Shared thrills bond you closer!",
					"Team couple!",
				},
				effects = { Happiness = 40, Relationship = 25 },
			},
			{
				text = "Relaxation and spa",
				feedback = {
					"Couples massage and relaxation!",
					"De-stress together!",
					"Peaceful bonding time!",
				},
				effects = { Happiness = 38, Relationship = 30, Health = 10 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FAMILY VACATION
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Family = {
	{
		id = "vacation_family",
		title = "👨‍👩‍👧‍👦 Family Vacation!",
		texts = {
			"Quality time with the whole family!",
			"Making memories together!",
			"Family adventures are the best!",
		},
		effects = { Happiness = {25, 40} },
		cost = 3500,
		choices = {
			{
				text = "Kid-friendly activities",
				feedback = {
					"The kids are having the time of their lives!",
					"Their joy is contagious!",
					"Family fun for everyone!",
				},
				effects = { Happiness = 38 },
			},
			{
				text = "Educational experiences",
				feedback = {
					"Learning and fun combined!",
					"The family learns together!",
					"Making memories AND knowledge!",
				},
				effects = { Happiness = 32, Smarts = 10 },
			},
			{
				text = "Classic family traditions",
				feedback = {
					"Creating traditions that will last generations!",
					"These moments are priceless!",
					"Family bonds strengthened!",
				},
				effects = { Happiness = 40 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOLO TRAVEL
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.Solo = {
	{
		id = "vacation_solo",
		title = "🚶 Solo Adventure",
		texts = {
			"Just you and the world!",
			"Self-discovery through travel!",
			"Independent exploration!",
		},
		effects = { Happiness = {20, 38}, Smarts = {5, 15} },
		cost = 1500,
		choices = {
			{
				text = "Meet locals and travelers",
				feedback = {
					"You're never truly alone when traveling!",
					"Amazing people everywhere!",
					"Solo travel, social experiences!",
				},
				effects = { Happiness = 38, Smarts = 10 },
			},
			{
				text = "Introspective journey",
				feedback = {
					"Time alone with your thoughts.",
					"Self-reflection and growth.",
					"You understand yourself better.",
				},
				effects = { Happiness = 32, Smarts = 15 },
			},
			{
				text = "Complete freedom",
				feedback = {
					"No compromises, no schedules!",
					"Do whatever YOU want!",
					"Ultimate travel freedom!",
				},
				effects = { Happiness = 35 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAPPING TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
VacationEvents.DestinationMapping = {
	["beach"] = "Beach",
	["tropical"] = "Beach",
	["mountain"] = "Mountain",
	["ski"] = "SkiResort",
	["skiing"] = "SkiResort",
	["city"] = "City",
	["urban"] = "City",
	["cruise"] = "Cruise",
	["ship"] = "Cruise",
	["safari"] = "Safari",
	["africa"] = "Safari",
	["historical"] = "Historical",
	["history"] = "Historical",
	["ruins"] = "Historical",
	["theme_park"] = "ThemePark",
	["amusement"] = "ThemePark",
	["disney"] = "ThemePark",
	["island"] = "Island",
	["road_trip"] = "RoadTrip",
	["driving"] = "RoadTrip",
	["camping"] = "Camping",
	["tent"] = "Camping",
	["europe"] = "European",
	["paris"] = "European",
	["rome"] = "European",
	["asia"] = "Asian",
	["japan"] = "Asian",
	["tokyo"] = "Asian",
	["caribbean"] = "Caribbean",
	["jamaica"] = "Caribbean",
	["bahamas"] = "Caribbean",
	["adventure"] = "Adventure",
	["extreme"] = "Adventure",
	["luxury"] = "Luxury",
	["5star"] = "Luxury",
	["budget"] = "Budget",
	["backpack"] = "Budget",
	["romantic"] = "Romantic",
	["honeymoon"] = "Romantic",
	["family"] = "Family",
	["kids"] = "Family",
	["solo"] = "Solo",
	["alone"] = "Solo",
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════
function VacationEvents.getEventForDestination(destinationId)
	local categoryName = VacationEvents.DestinationMapping[destinationId]
	if not categoryName then
		-- Try partial matching
		for key, cat in pairs(VacationEvents.DestinationMapping) do
			if string.find(destinationId:lower(), key) or string.find(key, destinationId:lower()) then
				categoryName = cat
				break
			end
		end
	end
	
	if not categoryName then
		-- Return random destination
		local allCategories = VacationEvents.getAllDestinations()
		categoryName = allCategories[math.random(1, #allCategories)]
	end
	
	local eventList = VacationEvents[categoryName]
	if not eventList or #eventList == 0 then
		return nil
	end
	
	-- Return random event from category
	return eventList[math.random(1, #eventList)]
end

function VacationEvents.getRandomVacation()
	local allCategories = VacationEvents.getAllDestinations()
	local categoryName = allCategories[math.random(1, #allCategories)]
	local eventList = VacationEvents[categoryName]
	if eventList and #eventList > 0 then
		return eventList[math.random(1, #eventList)]
	end
	return nil
end

function VacationEvents.getAllDestinations()
	return {"Beach", "Mountain", "City", "Cruise", "Safari", "Historical", "ThemePark", "SkiResort", "Island", "RoadTrip", "Camping", "European", "Asian", "Caribbean", "Adventure", "Luxury", "Budget", "Romantic", "Family", "Solo"}
end

return VacationEvents
