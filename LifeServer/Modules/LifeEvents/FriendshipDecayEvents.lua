--[[
	FriendshipDecayEvents.lua
	AAA-quality friendship decay and relationship maintenance events.
	
	Like the competition game, tracks when you haven't talked to friends for years
	and triggers events where they're angry, distant, or the friendship fades.
	
	Also includes positive events for maintained friendships.
]]

local FriendshipDecayEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function ensureFlags(state)
	state.Flags = state.Flags or {}
	return state.Flags
end

local function ensureRelationships(state)
	state.Relationships = state.Relationships or {}
	return state.Relationships
end

local function modStatIfPossible(state, key, delta)
	if state.ModifyStat then
		state:ModifyStat(key, delta)
	elseif state.Stats then
		state.Stats[key] = math.max(0, math.min(100, (state.Stats[key] or 50) + delta))
	end
end

local function addFeed(state, msg)
	if not msg or msg == "" then return end
	if state.AddFeed then
		state:AddFeed(msg)
	else
		state.PendingFeed = state.PendingFeed and (state.PendingFeed .. " " .. msg) or msg
	end
end

local function roll100()
	return math.random(1, 100)
end

local function chance(pct)
	return roll100() <= pct
end

-- Get a random friend from the player's relationships
local function getRandomFriend(state)
	local relationships = ensureRelationships(state)
	local friends = {}
	
	-- Collect all friends
	for id, rel in pairs(relationships) do
		if type(rel) == "table" then
			if rel.type == "friend" or rel.role == "Friend" or id:find("friend") then
				if rel.alive ~= false then -- Only living friends
					table.insert(friends, { id = id, data = rel })
				end
			end
		end
	end
	
	-- Also check friends array if it exists
	if relationships.friends and type(relationships.friends) == "table" then
		for i, rel in ipairs(relationships.friends) do
			if type(rel) == "table" and rel.alive ~= false then
				table.insert(friends, { id = rel.id or ("friend_" .. i), data = rel })
			end
		end
	end
	
	if #friends == 0 then
		return nil
	end
	
	return friends[math.random(1, #friends)]
end

-- Get friend name safely
local function getFriendName(friendData)
	if not friendData then return "Your friend" end
	return friendData.name or friendData.firstName or "Your friend"
end

-- Calculate years since last interaction
local function getYearsSinceContact(friendData, currentAge)
	if not friendData then return 0 end
	-- CRITICAL FIX: metAt can be a string like "childhood" or "randomly"!
	-- Only use numeric values for calculations
	local lastContact = friendData.lastContact or friendData.lastInteraction
	if type(lastContact) ~= "number" then
		-- Try metAt if it's numeric
		if type(friendData.metAt) == "number" then
			lastContact = friendData.metAt
		else
			-- Default to 0 (means they haven't contacted in a while)
			lastContact = 0
		end
	end
	return math.max(0, (currentAge or 0) - (tonumber(lastContact) or 0))
end

-- Check if player has any friends
local function hasFriends(state)
	return getRandomFriend(state) ~= nil
end

-- Check if player has neglected friends (2+ years no contact)
local function hasNeglectedFriend(state)
	local friend = getRandomFriend(state)
	if not friend then return false end
	local years = getYearsSinceContact(friend.data, state.Age)
	return years >= 2
end

-- Check if player has very neglected friends (5+ years no contact)
local function hasVeryNeglectedFriend(state)
	local friend = getRandomFriend(state)
	if not friend then return false end
	local years = getYearsSinceContact(friend.data, state.Age)
	return years >= 5
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════

FriendshipDecayEvents.events = {
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FRIEND ANGRY - HAVEN'T TALKED FOR YEARS
	-- ══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "friend_angry_neglect",
		title = "Angry Friend",
		emoji = "😤",
		text = "{{FRIEND_NAME}} is upset that you haven't reached out in years. They feel like you don't care about the friendship anymore.",
		category = "relationships",
		weight = 18,
		minAge = 16, maxAge = 80,
		baseChance = 0.55,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		eligibility = hasNeglectedFriend,
		blockedByFlags = { in_prison = true },
		
		getDynamicText = function(state)
			local friend = getRandomFriend(state)
			if not friend then return nil end
			local name = getFriendName(friend.data)
			local years = getYearsSinceContact(friend.data, state.Age)
			return {
				text = string.format("%s is upset that you haven't reached out in %d years. They feel like you don't care about the friendship anymore.", name, years),
				friendId = friend.id,
				friendName = name,
				yearsApart = years,
			}
		end,
		
		choices = {
			{
				text = "Apologize and reconnect",
				effects = { Happiness = 3 },
				feedText = "Reaching out to apologize...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					modStatIfPossible(state, "Happiness", 3)
					
					local r = roll100()
					if r <= 55 then
						-- They forgive you
						modStatIfPossible(state, "Happiness", 10)
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = math.min(100, (relationships[friendId].relationship or 50) + 20)
							relationships[friendId].lastContact = state.Age
						end
						addFeed(state, string.format("😊 %s forgave you. Your friendship is renewed!", friendName))
					elseif r <= 80 then
						-- They're still hurt but willing to try
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = math.min(100, (relationships[friendId].relationship or 50) + 5)
							relationships[friendId].lastContact = state.Age
						end
						addFeed(state, string.format("🤝 %s is still hurt but willing to give you another chance.", friendName))
					else
						-- They reject your apology
						modStatIfPossible(state, "Happiness", -8)
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = math.max(0, (relationships[friendId].relationship or 50) - 15)
						end
						addFeed(state, string.format("😞 %s said 'it's too late.' The friendship feels broken.", friendName))
					end
				end,
			},
			{
				text = "Make excuses for being busy",
				effects = { Happiness = -2 },
				feedText = "Trying to explain...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					modStatIfPossible(state, "Happiness", -2)
					
					local r = roll100()
					if r <= 30 then
						-- They understand
						modStatIfPossible(state, "Happiness", 5)
						addFeed(state, string.format("😌 %s understood. Life happens.", friendName))
						if friendId and relationships[friendId] then
							relationships[friendId].lastContact = state.Age
						end
					else
						-- They don't buy it
						modStatIfPossible(state, "Happiness", -5)
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = math.max(0, (relationships[friendId].relationship or 50) - 10)
						end
						addFeed(state, string.format("😤 %s didn't buy your excuses. 'Everyone's busy, but real friends make time.'", friendName))
					end
				end,
			},
			{
				text = "Ignore them completely",
				effects = { Happiness = 1 },
				feedText = "Leaving them on read...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					local flags = ensureFlags(state)
					
					modStatIfPossible(state, "Happiness", 1)
					
					-- High chance they stop being your friend
					if chance(70) then
						modStatIfPossible(state, "Happiness", -3)
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = 0
							relationships[friendId].estranged = true
						end
						flags.lost_a_friend = true
						addFeed(state, string.format("💔 %s gave up on the friendship. They're gone.", friendName))
					else
						addFeed(state, string.format("😶 %s stopped reaching out. The silence is mutual now.", friendName))
					end
				end,
			},
		},
	},
	
	{
		id = "friend_confrontation",
		title = "Friendship Confrontation",
		emoji = "😡",
		text = "{{FRIEND_NAME}} finally confronts you: 'I've been there for you, but where were you when I needed you?'",
		category = "relationships",
		weight = 14,
		minAge = 18, maxAge = 70,
		baseChance = 0.45,
		cooldown = 4,
		eligibility = hasVeryNeglectedFriend,
		blockedByFlags = { in_prison = true },
		
		getDynamicText = function(state)
			local friend = getRandomFriend(state)
			if not friend then return nil end
			local name = getFriendName(friend.data)
			return {
				text = string.format("%s finally confronts you: 'I've been there for you, but where were you when I needed you?'", name),
				friendId = friend.id,
				friendName = name,
			}
		end,
		
		choices = {
			{
				text = "Admit you failed as a friend",
				effects = { Happiness = -5 },
				feedText = "Taking responsibility...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					modStatIfPossible(state, "Happiness", -5)
					
					if chance(50) then
						modStatIfPossible(state, "Happiness", 15)
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = math.min(100, (relationships[friendId].relationship or 30) + 30)
							relationships[friendId].lastContact = state.Age
							relationships[friendId].reconciled = true
						end
						addFeed(state, string.format("💕 %s said 'That took courage. Let's rebuild.' Friendship saved.", friendName))
					else
						modStatIfPossible(state, "Happiness", -5)
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = math.max(0, (relationships[friendId].relationship or 30) - 10)
						end
						addFeed(state, string.format("😢 %s said 'I appreciate the honesty, but I need space.' They're distant now.", friendName))
					end
				end,
			},
			{
				text = "Get defensive",
				effects = { Happiness = 2 },
				feedText = "Defending yourself...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					local flags = ensureFlags(state)
					
					modStatIfPossible(state, "Happiness", 2)
					
					if chance(20) then
						addFeed(state, string.format("🤔 Somehow you won the argument. %s backed down.", friendName))
					else
						modStatIfPossible(state, "Happiness", -12)
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = 0
							relationships[friendId].alive = true
							relationships[friendId].estranged = true
						end
						flags.lost_a_friend = true
						addFeed(state, string.format("💔 %s said 'I'm done.' They walked away forever.", friendName))
					end
				end,
			},
			{
				text = "Blame them for not understanding your life",
				effects = {},
				feedText = "Turning it around...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					local flags = ensureFlags(state)
					
					-- This almost never works
					if chance(10) then
						modStatIfPossible(state, "Happiness", 3)
						addFeed(state, string.format("😲 %s actually apologized! They felt guilty.", friendName))
					else
						modStatIfPossible(state, "Happiness", -15)
						if friendId and relationships[friendId] then
							relationships[friendId] = nil
						end
						flags.lost_a_friend = true
						flags.burned_bridge = true
						addFeed(state, string.format("🔥 %s said 'Wow. I'm the problem? Goodbye forever.' Friendship destroyed.", friendName))
					end
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- FRIENDSHIP FADING NATURALLY
	-- ══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "friend_drifting_apart",
		title = "Drifting Apart",
		emoji = "🍂",
		text = "You realize you and {{FRIEND_NAME}} just don't have much in common anymore. Life has taken you in different directions.",
		category = "relationships",
		weight = 12,
		minAge = 20, maxAge = 80,
		baseChance = 0.40,
		cooldown = 5,
		eligibility = hasFriends,
		blockedByFlags = { in_prison = true },
		
		getDynamicText = function(state)
			local friend = getRandomFriend(state)
			if not friend then return nil end
			local name = getFriendName(friend.data)
			return {
				text = string.format("You realize you and %s just don't have much in common anymore. Life has taken you in different directions.", name),
				friendId = friend.id,
				friendName = name,
			}
		end,
		
		choices = {
			{
				text = "Make an effort to stay connected",
				effects = { Happiness = 3 },
				feedText = "Scheduling regular catch-ups...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					modStatIfPossible(state, "Happiness", 3)
					
					if chance(60) then
						modStatIfPossible(state, "Happiness", 8)
						if friendId and relationships[friendId] then
							relationships[friendId].lastContact = state.Age
							relationships[friendId].relationship = math.min(100, (relationships[friendId].relationship or 50) + 10)
						end
						addFeed(state, string.format("🤗 Your effort paid off. You and %s found new things to bond over!", friendName))
					else
						modStatIfPossible(state, "Happiness", -3)
						addFeed(state, string.format("😕 You tried, but conversations feel forced now. The magic is gone.", friendName))
					end
				end,
			},
			{
				text = "Accept that friendships change",
				effects = { Happiness = -2, Smarts = 2 },
				feedText = "Letting go peacefully...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					modStatIfPossible(state, "Happiness", -2)
					modStatIfPossible(state, "Smarts", 2)
					
					if friendId and relationships[friendId] then
						relationships[friendId].relationship = math.max(20, (relationships[friendId].relationship or 50) - 20)
						relationships[friendId].distant = true
					end
					
					addFeed(state, string.format("🍂 You and %s became acquaintances. It's bittersweet but natural.", friendName))
				end,
			},
			{
				text = "Ghost them entirely",
				effects = { Happiness = 1 },
				feedText = "Just... stopping...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					local flags = ensureFlags(state)
					
					modStatIfPossible(state, "Happiness", 1)
					
					if friendId and relationships[friendId] then
						relationships[friendId].relationship = 0
						relationships[friendId].estranged = true
					end
					flags.ghosted_someone = true
					
					addFeed(state, string.format("👻 You stopped responding to %s. They eventually stopped trying.", friendName))
				end,
			},
		},
	},
	
	-- ══════════════════════════════════════════════════════════════════════════════
	-- POSITIVE FRIENDSHIP EVENTS (WHEN MAINTAINED)
	-- ══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "friend_loyalty_test",
		title = "Friend in Need",
		emoji = "💪",
		text = "{{FRIEND_NAME}} is going through a really hard time and asks for your help.",
		category = "relationships",
		weight = 14,
		minAge = 16, maxAge = 80,
		baseChance = 0.50,
		cooldown = 3,
		eligibility = hasFriends,
		blockedByFlags = { in_prison = true },
		
		getDynamicText = function(state)
			local friend = getRandomFriend(state)
			if not friend then return nil end
			local name = getFriendName(friend.data)
			return {
				text = string.format("%s is going through a really hard time and asks for your help.", name),
				friendId = friend.id,
				friendName = name,
			}
		end,
		
		choices = {
			{
				text = "Drop everything and be there for them",
				effects = { Happiness = 5, Health = -2 },
				feedText = "Being a true friend...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					local flags = ensureFlags(state)
					
					modStatIfPossible(state, "Happiness", 5)
					modStatIfPossible(state, "Health", -2)
					
					if friendId and relationships[friendId] then
						relationships[friendId].relationship = math.min(100, (relationships[friendId].relationship or 50) + 25)
						relationships[friendId].lastContact = state.Age
						relationships[friendId].loyal = true
					end
					flags.loyal_friend = true
					
					addFeed(state, string.format("💕 %s said 'I'll never forget this.' Your bond is stronger than ever.", friendName))
				end,
			},
			{
				text = "Help when you can, but set boundaries",
				effects = { Happiness = 3, Smarts = 2 },
				feedText = "Balancing support with self-care...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					modStatIfPossible(state, "Happiness", 3)
					modStatIfPossible(state, "Smarts", 2)
					
					if chance(70) then
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = math.min(100, (relationships[friendId].relationship or 50) + 10)
							relationships[friendId].lastContact = state.Age
						end
						addFeed(state, string.format("🤝 %s appreciated your help. They understood you have limits too.", friendName))
					else
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = math.max(0, (relationships[friendId].relationship or 50) - 5)
						end
						addFeed(state, string.format("😕 %s felt hurt that you couldn't do more. 'I would have done anything for you.'", friendName))
					end
				end,
			},
			{
				text = "Make excuses and avoid helping",
				effects = { Health = 2 },
				feedText = "Dodging the responsibility...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					local flags = ensureFlags(state)
					
					modStatIfPossible(state, "Health", 2)
					
					if chance(20) then
						addFeed(state, string.format("😅 %s found help elsewhere. They never mentioned it.", friendName))
					else
						modStatIfPossible(state, "Happiness", -8)
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = math.max(0, (relationships[friendId].relationship or 50) - 25)
						end
						flags.failed_friend = true
						addFeed(state, string.format("😔 %s said 'I see how it is. I know who my real friends are now.'", friendName))
					end
				end,
			},
		},
	},
	
	{
		id = "friend_success_jealousy",
		title = "Friend's Big Success",
		emoji = "🎉",
		text = "{{FRIEND_NAME}} just achieved something huge - way bigger than anything you've done. They're everywhere now.",
		category = "relationships",
		weight = 12,
		minAge = 20, maxAge = 60,
		baseChance = 0.40,
		cooldown = 4,
		eligibility = hasFriends,
		blockedByFlags = { in_prison = true },
		
		getDynamicText = function(state)
			local friend = getRandomFriend(state)
			if not friend then return nil end
			local name = getFriendName(friend.data)
			return {
				text = string.format("%s just achieved something huge - way bigger than anything you've done. They're everywhere now.", name),
				friendId = friend.id,
				friendName = name,
			}
		end,
		
		choices = {
			{
				text = "Celebrate with genuine happiness",
				effects = { Happiness = 8 },
				feedText = "Being truly happy for them...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					modStatIfPossible(state, "Happiness", 8)
					
					if friendId and relationships[friendId] then
						relationships[friendId].relationship = math.min(100, (relationships[friendId].relationship or 50) + 15)
						relationships[friendId].lastContact = state.Age
					end
					
					addFeed(state, string.format("🎊 %s said 'Your support means everything.' They even helped you network!", friendName))
				end,
			},
			{
				text = "Feel jealous but hide it",
				effects = { Happiness = -5 },
				feedText = "Smiling through gritted teeth...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					
					modStatIfPossible(state, "Happiness", -5)
					
					if chance(60) then
						addFeed(state, string.format("😶 You kept it together. %s never noticed your envy.", friendName))
					else
						modStatIfPossible(state, "Happiness", -5)
						addFeed(state, string.format("😬 %s sensed something was off. Things feel awkward now.", friendName))
					end
				end,
			},
			{
				text = "Distance yourself from them",
				effects = { Happiness = -2 },
				feedText = "Can't handle their success...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					modStatIfPossible(state, "Happiness", -2)
					
					if friendId and relationships[friendId] then
						relationships[friendId].relationship = math.max(0, (relationships[friendId].relationship or 50) - 20)
						relationships[friendId].distant = true
					end
					
					addFeed(state, string.format("😔 You and %s drifted apart. Their success changed everything.", friendName))
				end,
			},
		},
	},
	
	{
		id = "friend_birthday_forgot",
		title = "Forgot a Birthday",
		emoji = "🎂",
		text = "You completely forgot {{FRIEND_NAME}}'s birthday. It was yesterday and you missed it.",
		category = "relationships",
		weight = 14,
		minAge = 16, maxAge = 80,
		baseChance = 0.45,
		cooldown = 4, -- CRITICAL FIX: Increased from 2 to reduce spam
		eligibility = hasFriends,
		blockedByFlags = { in_prison = true },
		
		getDynamicText = function(state)
			local friend = getRandomFriend(state)
			if not friend then return nil end
			local name = getFriendName(friend.data)
			return {
				text = string.format("You completely forgot %s's birthday. It was yesterday and you missed it.", name),
				friendId = friend.id,
				friendName = name,
			}
		end,
		
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Send a belated gift ($50)",
				effects = { Money = -50, Happiness = -2 },
				feedText = "Damage control...",
				eligibility = function(state) return (state.Money or 0) >= 50, "💸 Need $50 for gift" end,
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					state.Money = math.max(0, (state.Money or 0) - 50)
					modStatIfPossible(state, "Happiness", -2)
					
					if chance(70) then
						modStatIfPossible(state, "Happiness", 5)
						if friendId and relationships[friendId] then
							relationships[friendId].lastContact = state.Age
						end
						addFeed(state, string.format("🎁 %s laughed it off: 'Better late than never!' Crisis averted.", friendName))
					else
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = math.max(0, (relationships[friendId].relationship or 50) - 5)
						end
						addFeed(state, string.format("😕 %s accepted the gift but seemed cold. 'You always forget things.'", friendName))
					end
				end,
			},
			{
				text = "Pretend you didn't forget",
				effects = {},
				feedText = "Acting oblivious...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					if chance(30) then
						addFeed(state, string.format("😬 %s didn't bring it up. Maybe they forgot you forgot.", friendName))
					else
						modStatIfPossible(state, "Happiness", -6)
						if friendId and relationships[friendId] then
							relationships[friendId].relationship = math.max(0, (relationships[friendId].relationship or 50) - 10)
						end
						addFeed(state, string.format("😤 %s: 'So you're not even going to acknowledge missing my birthday?' Busted.", friendName))
					end
				end,
			},
			{
				text = "Shrug it off - it's just a birthday",
				effects = { Happiness = 1 },
				feedText = "It's not that serious...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					modStatIfPossible(state, "Happiness", 1)
					
					if friendId and relationships[friendId] then
						relationships[friendId].relationship = math.max(0, (relationships[friendId].relationship or 50) - 15)
					end
					
					addFeed(state, string.format("😒 %s noticed you didn't care. They stopped sending you birthday wishes too.", friendName))
				end,
			},
		},
	},
	
	{
		id = "friend_reconnection",
		title = "Old Friend Reaches Out",
		emoji = "📱",
		text = "{{FRIEND_NAME}}, who you haven't spoken to in years, suddenly reached out. 'Hey, remember me?'",
		category = "relationships",
		weight = 12,
		minAge = 20, maxAge = 80,
		baseChance = 0.40,
		cooldown = 4,
		eligibility = hasNeglectedFriend,
		blockedByFlags = { in_prison = true },
		
		getDynamicText = function(state)
			local friend = getRandomFriend(state)
			if not friend then return nil end
			local name = getFriendName(friend.data)
			local years = getYearsSinceContact(friend.data, state.Age)
			return {
				text = string.format("%s, who you haven't spoken to in %d years, suddenly reached out. 'Hey, remember me?'", name, years),
				friendId = friend.id,
				friendName = name,
			}
		end,
		
		choices = {
			{
				text = "Respond enthusiastically!",
				effects = { Happiness = 8 },
				feedText = "So happy to reconnect!",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					modStatIfPossible(state, "Happiness", 8)
					
					if friendId and relationships[friendId] then
						relationships[friendId].relationship = math.min(100, (relationships[friendId].relationship or 30) + 25)
						relationships[friendId].lastContact = state.Age
						relationships[friendId].reconnected = true
					end
					
					addFeed(state, string.format("🎉 You and %s picked up right where you left off! Friendship renewed.", friendName))
				end,
			},
			{
				text = "Reply politely but keep distance",
				effects = { Happiness = 2 },
				feedText = "Cautiously optimistic...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					local relationships = ensureRelationships(state)
					
					modStatIfPossible(state, "Happiness", 2)
					
					if friendId and relationships[friendId] then
						relationships[friendId].lastContact = state.Age
					end
					
					addFeed(state, string.format("🤝 You and %s had a nice catch-up. No pressure to be besties again.", friendName))
				end,
			},
			{
				text = "Ignore the message",
				effects = {},
				feedText = "Some people are in your past for a reason...",
				onResolve = function(state, choice, event)
					local friendId = event._dynamicData and event._dynamicData.friendId
					local friendName = event._dynamicData and event._dynamicData.friendName or "Your friend"
					
					if chance(50) then
						addFeed(state, string.format("📵 %s got the hint. They moved on.", friendName))
					else
						modStatIfPossible(state, "Happiness", -3)
						addFeed(state, string.format("😬 %s told mutual friends you're stuck up. Gossip spreads.", friendName))
					end
				end,
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #703: CONSEQUENCE EVENTS
	-- User feedback: "ensure stuff u do actually has stuff popup for it in future"
	-- Events that reference past choices/actions from childhood!
	-- ═══════════════════════════════════════════════════════════════════════════════

	{
		id = "consequence_childhood_promise",
		title = "The Forgotten Promise",
		emoji = "😔",
		text = "You remember promising your childhood friend you'd stay in touch forever. Years have passed, and you realize you never kept that promise.",
		category = "relationships",
		weight = 10,
		minAge = 25, maxAge = 45,
		baseChance = 0.4,
		cooldown = 5,
		oneTime = true,
		-- CRITICAL: Only triggers if player made the promise!
		requiresFlags = { promised_friend_letters = true },
		blockedByFlags = { resolved_childhood_promise = true },
		
		choices = {
			{
				text = "Reach out now - it's never too late",
				effects = {},
				feedText = "Searching for their contact info...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.50 then
						modStatIfPossible(state, "Happiness", 15)
						state.Flags = state.Flags or {}
						state.Flags.reconnected_childhood_friend = true
						state.Flags.resolved_childhood_promise = true
						addFeed(state, "📱 They responded! 'I never forgot you either.' Tears. Friendship rekindled!")
					else
						modStatIfPossible(state, "Happiness", -3)
						state.Flags.resolved_childhood_promise = true
						addFeed(state, "📱 Couldn't find them. They've moved on with their life. Some promises fade.")
					end
				end,
			},
			{
				text = "Let sleeping memories lie",
				effects = { Happiness = -5 },
				setFlags = { broken_promise_guilt = true, resolved_childhood_promise = true },
				feedText = "😔 The guilt of broken promises weighs on you. But that's life...",
			},
		},
	},
	{
		id = "consequence_sibling_blame",
		title = "Sibling Remembers",
		emoji = "😤",
		text = "Your sibling brings up that time you blamed them for something YOU did. They've held onto that resentment for years.",
		category = "family",
		weight = 12,
		minAge = 18, maxAge = 50,
		baseChance = 0.35,
		cooldown = 6,
		oneTime = true,
		-- CRITICAL: Only triggers if player blamed their sibling!
		requiresFlags = { blamed_sibling = true },
		blockedByFlags = { resolved_sibling_blame = true },
		
		choices = {
			{
				text = "Finally apologize - they deserve it",
				effects = {},
				feedText = "It's time to make amends...",
				onResolve = function(state)
					local roll = math.random()
					if roll < 0.70 then
						modStatIfPossible(state, "Happiness", 12)
						state.Flags = state.Flags or {}
						state.Flags.resolved_sibling_blame = true
						state.Flags.sibling_forgave = true
						addFeed(state, "😭 'I forgive you. But I'll never forget.' The healing begins.")
					else
						modStatIfPossible(state, "Happiness", -5)
						state.Flags.resolved_sibling_blame = true
						addFeed(state, "😤 'It's too late for sorry.' Some wounds don't heal.")
					end
				end,
			},
			{
				text = "Deny it still",
				effects = { Happiness = -10 },
				setFlags = { sibling_estranged = true, resolved_sibling_blame = true },
				feedText = "😤 They see through you. The relationship may never recover.",
			},
		},
	},
	{
		id = "consequence_brave_defender",
		title = "They Remember You",
		emoji = "🦸",
		text = "Someone approaches you: 'You probably don't remember me, but you stood up to a bully for me when we were kids. That meant everything.'",
		category = "karma",
		weight = 8,
		minAge = 22, maxAge = 55,
		baseChance = 0.3,
		cooldown = 10,
		oneTime = true,
		-- CRITICAL: Only triggers if player stood up to a bully!
		requiresFlags = { stood_up_to_bully = true },
		blockedByFlags = { received_bully_thanks = true },
		
		choices = {
			{
				text = "Accept their gratitude warmly",
				effects = { Happiness = 20, Fame = 1 },
				setFlags = { remembered_hero = true, received_bully_thanks = true },
				feedText = "🦸 'You gave me courage I didn't know I had.' Your past kindness echoes.",
			},
			{
				text = "You barely remember it",
				effects = { Happiness = 10 },
				setFlags = { received_bully_thanks = true },
				feedText = "🦸 What was a moment for you was life-changing for them. Good deeds matter.",
			},
		},
	},
	{
		id = "consequence_artistic_talent",
		title = "Your Childhood Drawings",
		emoji = "🎨",
		text = "Your parent shows you old drawings you made as a child. 'You were always so talented. Did you ever pursue art?'",
		category = "nostalgia",
		weight = 8,
		minAge = 25, maxAge = 50,
		baseChance = 0.35,
		cooldown = 8,
		oneTime = true,
		-- CRITICAL: Only triggers if player had artistic talent!
		requiresFlags = { artistic_talent = true },
		
		choices = {
			{
				text = "I should get back into it",
				effects = { Happiness = 10, Smarts = 3 },
				setFlags = { rekindled_artistic_passion = true },
				feedText = "🎨 Looking at your old work inspires you. Maybe it's time to create again.",
			},
			{
				text = "Life took me in a different direction",
				effects = { Happiness = -2 },
				feedText = "🎨 Some talents fade, but the memories remain. Bittersweet.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #905: MORE CONSEQUENCE EVENTS FOR PAST ACTIONS!
	-- User complaint: "game is shallow, what you do has no impact"
	-- Adding 6 new consequence events that trigger based on childhood/teen choices
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "consequence_rebel_streak",
		title = "Reputation Precedes You",
		emoji = "😈",
		text = "You run into your old teacher. 'I always knew you'd either end up famous or in jail. You were quite the troublemaker!'",
		category = "consequence",
		weight = 10,
		minAge = 25, maxAge = 45,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { rebellious_streak = true },
		
		choices = {
			{
				text = "Proudly own your wild past",
				effects = { Happiness = 8 },
				feedText = "😈 'Best years of my life!' Sometimes breaking rules teaches valuable lessons.",
			},
			{
				text = "Cringe at the memories",
				effects = { Happiness = -3 },
				feedText = "😈 Some memories are better left buried. You've grown since then.",
			},
		},
	},
	{
		id = "consequence_first_love",
		title = "First Love Reunion",
		emoji = "💔",
		text = "You randomly bump into your first crush from school. The memories come flooding back.",
		category = "consequence",
		weight = 8,
		minAge = 22, maxAge = 40,
		baseChance = 0.3,
		cooldown = 15,
		oneTime = true,
		requiresFlags = { had_first_crush = true },
		
		getDynamicText = function(state)
			if state.Flags and state.Flags.married then
				return "You bump into your first crush from school. You're married now, but the memories still make you smile. How different life could have been..."
			else
				return "You randomly bump into your first crush from school. They still look good. Your heart skips a beat."
			end
		end,
		
		choices = {
			{
				text = "Catch up over coffee",
				effects = {},
				feedText = "Reconnecting with your past...",
				onResolve = function(state)
					if state.Flags and state.Flags.married then
						modStatIfPossible(state, "Happiness", 5)
						addFeed(state, "💔 Nice to reminisce. But you love your current life. Some chapters close.")
					else
						local roll = math.random()
						if roll < 0.40 then
							modStatIfPossible(state, "Happiness", 15)
							state.Flags = state.Flags or {}
							state.Flags.rekindled_first_love = true
							addFeed(state, "💕 Sparks fly again! Maybe fate brought you back together...")
						else
							modStatIfPossible(state, "Happiness", 5)
							addFeed(state, "💔 Nice to catch up, but you've both changed. That chapter is closed.")
						end
					end
				end,
			},
			{
				text = "Wave and keep walking",
				effects = { Happiness = 2 },
				feedText = "💔 Some memories are best left as memories. You smile and move on.",
			},
		},
	},
	{
		id = "consequence_pet_loss",
		title = "Visiting Old Memories",
		emoji = "🐾",
		text = "You visit your childhood home and see the spot where your beloved pet is buried. The feelings hit you unexpectedly.",
		category = "consequence",
		weight = 8,
		minAge = 20, maxAge = 50,
		baseChance = 0.25,
		cooldown = 15,
		oneTime = true,
		requiresFlags = { learned_about_loss = true },
		
		choices = {
			{
				text = "Let yourself grieve again",
				effects = { Happiness = -5 },
				feedText = "🐾 Tears flow. That pet taught you about unconditional love. And loss.",
				onResolve = function(state)
					modStatIfPossible(state, "Happiness", -5)
					state.Flags = state.Flags or {}
					state.Flags.processed_pet_grief = true
					addFeed(state, "🐾 You plant a flower on the spot. Some loves never fade.")
				end,
			},
			{
				text = "Smile at the happy memories",
				effects = { Happiness = 5 },
				feedText = "🐾 So many good times. Grief fades but love remains forever.",
			},
		},
	},
	{
		id = "consequence_sports_glory",
		title = "Old Teammate Reunion",
		emoji = "🏆",
		text = "Your old sports teammate reaches out. 'Remember when we won that championship? Best days of my life!'",
		category = "consequence",
		weight = 10,
		minAge = 25, maxAge = 50,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { athletic_talent = true },
		
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Organize a team reunion ($100)",
				effects = { Happiness = 15, Money = -100 },
				feedText = "🏆 The whole gang together again! Laughing about old times. Priceless.",
				eligibility = function(state) return (state.Money or 0) >= 100, "💸 Need $100 for reunion" end,
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.had_team_reunion = true
				end,
			},
			{
				text = "Video call to catch up",
				effects = { Happiness = 8 },
				feedText = "🏆 Different paths, same bond. Sports friends are friends for life.",
			},
		},
	},
	{
		id = "consequence_genius_kid",
		title = "Your Old Report Cards",
		emoji = "📚",
		text = "While cleaning, you find your old report cards. Straight A's. 'Exceptional student' comments. Your parents kept everything.",
		category = "consequence",
		weight = 8,
		minAge = 25, maxAge = 45,
		baseChance = 0.3,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { math_science_talent = true },
		
		getDynamicText = function(state)
			local currentJob = state.CurrentJob
			if currentJob then
				local jobName = currentJob.name or currentJob.title or "your job"
				return "While cleaning, you find your old report cards. Straight A's. 'Exceptional student.' You ended up as a " .. jobName .. ". Did you live up to your potential?"
			else
				return "While cleaning, you find your old report cards. Straight A's. 'Exceptional student' comments. What happened to that kid?"
			end
		end,
		
		choices = {
			{
				text = "I'm proud of my journey",
				effects = { Happiness = 10 },
				feedText = "📚 Intelligence isn't just grades. You've learned things no classroom could teach.",
			},
			{
				text = "I should have done more",
				effects = { Happiness = -5 },
				feedText = "📚 Potential is a heavy burden. But it's never too late to change course.",
			},
		},
	},
	{
		id = "consequence_secret_spot",
		title = "Your Secret Hideout",
		emoji = "🏠",
		text = "You revisit the neighborhood and find your old secret hideout from childhood. It's still there, somehow. Smaller than you remember.",
		category = "consequence",
		weight = 6,
		minAge = 20, maxAge = 45,
		baseChance = 0.25,
		cooldown = 15,
		oneTime = true,
		requiresFlags = { had_secret_spot = true },
		
		choices = {
			{
				text = "Leave a note for future kids",
				effects = { Happiness = 12 },
				feedText = "🏠 'This was my secret spot. Now it's yours. Make good memories.' Passing the torch.",
			},
			{
				text = "Take a moment alone there",
				effects = { Happiness = 8 },
				feedText = "🏠 For a few minutes, you're a kid again. Nothing else matters. Peace.",
			},
		},
	},
	
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CRITICAL FIX #1010-1030: MASSIVE CONSEQUENCE EVENT EXPANSION!
	-- User feedback: "ADD WAY MORE LINKAGE - WHEN I DO A CHOICE HAVE OTHER STUFF SHOWUP LATER"
	-- These events create meaningful connections between past choices and future outcomes!
	-- ═══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "consequence_stem_success",
		title = "Your STEM Education Paid Off",
		emoji = "🧪",
		text = "A recruiter approaches you: 'We've been looking for someone with your science background. Interested in a research position?'",
		category = "consequence",
		weight = 12,
		minAge = 22, maxAge = 35,
		baseChance = 0.40,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { math_science_talent = true },
		blockedByFlags = { got_stem_opportunity = true },
		
		choices = {
			{
				text = "Accept the opportunity",
				effects = { Happiness = 15, Money = 5000 },
				feedText = "🧪 Your childhood love of science opened doors! Career opportunity unlocked!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.got_stem_opportunity = true
					state.Flags.research_career = true
				end,
			},
			{
				text = "Decline - I went a different direction",
				effects = { Happiness = 3 },
				feedText = "🧪 Different path, no regrets. Your talents served you in other ways.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.got_stem_opportunity = true
				end,
			},
		},
	},
	
	{
		id = "consequence_saver_habit",
		title = "Your Savings Habit Saved You",
		emoji = "💰",
		text = "An unexpected expense came up! But wait... you have savings from your careful money habits since childhood!",
		category = "consequence",
		weight = 10,
		minAge = 25, maxAge = 50,
		baseChance = 0.45,
		cooldown = 8,
		oneTime = true,
		requiresFlags = { saver = true },
		blockedByFlags = { savings_saved_you = true },
		
		choices = {
			{
				text = "Thank past you for saving",
				effects = { Happiness = 15, Money = 2000 },
				feedText = "💰 'I knew saving would pay off!' Your childhood habit protected you!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.savings_saved_you = true
				end,
			},
		},
	},
	
	{
		id = "consequence_spender_regret",
		title = "Spending Catches Up",
		emoji = "💸",
		text = "A financial emergency! You need money but... your spending habits left you unprepared.",
		category = "consequence",
		weight = 10,
		minAge = 25, maxAge = 50,
		baseChance = 0.45,
		cooldown = 8,
		oneTime = true,
		requiresFlags = { spender = true },
		blockedByFlags = { spending_lesson_learned = true },
		
		choices = {
			{
				text = "Borrow from family",
				effects = { Happiness = -8, Money = 1000 },
				feedText = "💸 They helped, but gave you a lecture about saving. Fair point.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.spending_lesson_learned = true
				end,
			},
			{
				text = "Figure it out yourself",
				effects = { Happiness = -12, Health = -5 },
				feedText = "💸 Stress. So much stress. But you learned a valuable lesson.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.spending_lesson_learned = true
					state.Flags.learned_to_save = true
				end,
			},
		},
	},
	
	{
		id = "consequence_animal_lover_rescue",
		title = "Animal Lover's Moment",
		emoji = "🐕",
		text = "You find an abandoned animal on the street. Your lifelong love of animals kicks in immediately.",
		category = "consequence",
		weight = 8,
		minAge = 18, maxAge = 60,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { animal_lover = true },
		blockedByFlags = { rescued_animal = true },
		
		choices = {
			{
				-- CRITICAL FIX: Show price!
				text = "Rescue and adopt them ($200)!",
				effects = { Happiness = 20, Money = -200 },
				feedText = "🐕 Your childhood love of animals led to this moment. New best friend!",
				eligibility = function(state) return (state.Money or 0) >= 200, "💸 Need $200 for adoption" end,
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.rescued_animal = true
					state.Flags.has_pet = true
				end,
			},
			{
				text = "Take to a shelter",
				effects = { Happiness = 10 },
				feedText = "🐕 You made sure they'd find a home. Your heart is in the right place.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.rescued_animal = true
				end,
			},
		},
	},
	
	{
		id = "consequence_creative_recognition",
		title = "Your Art Gets Noticed!",
		emoji = "🎨",
		text = "Someone discovered your creative work online. 'This is exactly what I've been looking for! Are you available for a commission?'",
		category = "consequence",
		weight = 10,
		minAge = 20, maxAge = 45,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { artistic_talent = true },
		blockedByFlags = { art_got_noticed = true },
		
		choices = {
			{
				text = "Take the commission!",
				effects = { Happiness = 15 },
				feedText = "🎨 Your childhood doodling evolved into something people pay for! Dreams can come true!",
				onResolve = function(state)
					local payment = math.random(500, 3000)
					state.Money = (state.Money or 0) + payment
					state.Flags = state.Flags or {}
					state.Flags.art_got_noticed = true
					state.Flags.paid_artist = true
					addFeed(state, string.format("🎨 Earned $%d for your art! Those childhood drawings led somewhere!", payment))
				end,
			},
			{
				text = "Decline - art is personal",
				effects = { Happiness = 5 },
				feedText = "🎨 Not everything needs to be monetized. Art remains your peaceful escape.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.art_got_noticed = true
				end,
			},
		},
	},
	
	{
		id = "consequence_romantic_soul",
		title = "Love Finds Romantic Souls",
		emoji = "💕",
		text = "You've always been a romantic at heart. And now, someone special notices the way you see the world.",
		category = "consequence",
		weight = 8,
		minAge = 20, maxAge = 40,
		baseChance = 0.30,
		cooldown = 15,
		oneTime = true,
		requiresFlags = { romantic_soul = true },
		blockedByFlags = { romantic_soulmate_met = true, married = true },
		
		choices = {
			{
				text = "Let yourself fall in love",
				effects = { Happiness = 25 },
				feedText = "💕 Your romantic nature attracted exactly the right person. This feels real.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.romantic_soulmate_met = true
					state.Flags.in_relationship = true
				end,
			},
			{
				text = "Guard your heart",
				effects = { Happiness = 5 },
				feedText = "💕 You've been hurt before. Better to be careful. Maybe next time.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.romantic_soulmate_met = true
				end,
			},
		},
	},
	
	{
		id = "consequence_loyal_friend_reward",
		title = "Loyalty Returned",
		emoji = "🤝",
		text = "Remember when you dropped everything to help your friend? They just did the same for you. When you needed it most.",
		category = "consequence",
		weight = 12,
		minAge = 22, maxAge = 60,
		baseChance = 0.40,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { loyal_friend = true },
		blockedByFlags = { loyalty_returned = true },
		
		choices = {
			{
				text = "Express deep gratitude",
				effects = { Happiness = 20 },
				feedText = "🤝 What goes around comes around. Your loyalty was remembered. True friendship.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.loyalty_returned = true
				end,
			},
		},
	},
	
	{
		id = "consequence_ghosted_karma",
		title = "Karma Visits",
		emoji = "👻",
		text = "Someone you used to know brings up how you ghosted that friend years ago. The word spread.",
		category = "consequence",
		weight = 8,
		minAge = 22, maxAge = 50,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { ghosted_someone = true },
		blockedByFlags = { ghosting_karma_hit = true },
		
		choices = {
			{
				text = "Feel the shame",
				effects = { Happiness = -10 },
				feedText = "👻 Reputation travels. People remember how you treated others.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.ghosting_karma_hit = true
				end,
			},
			{
				text = "Defend yourself",
				effects = { Happiness = -5 },
				feedText = "👻 Excuses don't change facts. Maybe it's time to be better.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.ghosting_karma_hit = true
				end,
			},
		},
	},
	
	{
		id = "consequence_entrepreneur_success",
		title = "Business Instincts Kick In",
		emoji = "💼",
		text = "You spot a business opportunity that others missed. Your entrepreneurial mind from childhood sees the potential immediately.",
		category = "consequence",
		weight = 10,
		minAge = 23, maxAge = 50,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { entrepreneur = true },
		blockedByFlags = { entrepreneur_opportunity_taken = true },
		
		choices = {
			{
				text = "Take the risk!",
				effects = {},
				feedText = "Taking the plunge...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.entrepreneur_opportunity_taken = true
					if roll < 0.60 then
						local profit = math.random(5000, 50000)
						state.Money = (state.Money or 0) + profit
						modStatIfPossible(state, "Happiness", 20)
						state.Flags.successful_entrepreneur = true
						addFeed(state, string.format("💼 IT WORKED! Made $%d! Your childhood instincts were RIGHT!", profit))
					else
						local loss = math.random(1000, 5000)
						state.Money = math.max(0, (state.Money or 0) - loss)
						modStatIfPossible(state, "Happiness", -10)
						addFeed(state, string.format("💼 Lost $%d. But entrepreneurs learn from failure. Next time.", loss))
					end
				end,
			},
			{
				text = "Play it safe",
				effects = { Happiness = -5 },
				feedText = "💼 You let the opportunity pass. Smart? Or a missed chance? Only time will tell.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.entrepreneur_opportunity_taken = true
				end,
			},
		},
	},
	
	{
		id = "consequence_natural_leader_moment",
		title = "Leadership Tested",
		emoji = "👔",
		text = "A crisis situation and everyone looks to YOU for guidance. Your natural leadership abilities activate.",
		category = "consequence",
		weight = 10,
		minAge = 25, maxAge = 55,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { natural_leader = true },
		blockedByFlags = { leadership_tested = true },
		
		choices = {
			{
				text = "Step up and lead!",
				effects = {},
				feedText = "Taking charge...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.leadership_tested = true
					if roll < 0.70 then
						modStatIfPossible(state, "Happiness", 20)
						state.Fame = (state.Fame or 0) + 3
						state.Flags.proven_leader = true
						addFeed(state, "👔 You led everyone through the crisis! People will remember this!")
					else
						modStatIfPossible(state, "Happiness", 5)
						addFeed(state, "👔 You did your best. Not perfect, but you tried. That matters.")
					end
				end,
			},
			{
				text = "Defer to someone else",
				effects = { Happiness = -8 },
				feedText = "👔 You had the skills but held back. Why? Something to reflect on.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.leadership_tested = true
				end,
			},
		},
	},
	
	{
		id = "consequence_gamer_esports",
		title = "Gaming Skills Noticed",
		emoji = "🎮",
		text = "Your gaming skills from childhood caught someone's attention. 'You should try competitive gaming - you're actually good!'",
		category = "consequence",
		weight = 8,
		minAge = 18, maxAge = 30,
		baseChance = 0.30,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { gamer = true },
		blockedByFlags = { esports_chance = true },
		
		choices = {
			{
				text = "Enter a tournament!",
				effects = {},
				feedText = "Time to prove yourself...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.esports_chance = true
					if roll < 0.40 then
						local prize = math.random(1000, 10000)
						state.Money = (state.Money or 0) + prize
						modStatIfPossible(state, "Happiness", 25)
						state.Fame = (state.Fame or 0) + 5
						state.Flags.esports_winner = true
						addFeed(state, string.format("🎮 YOU WON! $%d prize! All those hours gaming paid off!", prize))
					elseif roll < 0.70 then
						modStatIfPossible(state, "Happiness", 10)
						addFeed(state, "🎮 Didn't win, but you held your own! Gaming community respects you!")
					else
						modStatIfPossible(state, "Happiness", -5)
						addFeed(state, "🎮 Got eliminated early. Maybe stick to casual gaming.")
					end
				end,
			},
			{
				text = "Gaming is just for fun",
				effects = { Happiness = 5 },
				feedText = "🎮 Not everything needs to be competitive. Gaming remains your chill time.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.esports_chance = true
				end,
			},
		},
	},
	
	{
		id = "consequence_tech_talent_breakthrough",
		title = "Tech Skills Pay Dividends",
		emoji = "💻",
		text = "Your natural tech talent from youth helped you spot a problem others couldn't. A company wants to hire you!",
		category = "consequence",
		weight = 10,
		minAge = 20, maxAge = 40,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { tech_talent = true },
		blockedByFlags = { tech_breakthrough = true },
		
		choices = {
			{
				text = "Join the company!",
				effects = { Happiness = 15, Money = 10000 },
				feedText = "💻 Your childhood love of computers turned into a career! Signing bonus received!",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.tech_breakthrough = true
					state.Flags.tech_career = true
				end,
			},
			{
				text = "Stay independent",
				effects = { Happiness = 8 },
				feedText = "💻 Freelance life. Your skills open doors whenever you want.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.tech_breakthrough = true
				end,
			},
		},
	},
	
	{
		id = "consequence_cooking_talent_recognition",
		title = "Your Cooking Impresses",
		emoji = "👨‍🍳",
		text = "You made something for a gathering and everyone's asking for the recipe. 'You should open a restaurant!'",
		category = "consequence",
		weight = 8,
		minAge = 25, maxAge = 55,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { cooking_talent = true },
		blockedByFlags = { cooking_recognized = true },
		
		choices = {
			{
				text = "Start selling your food!",
				effects = {},
				feedText = "Taking the plunge...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.cooking_recognized = true
					if roll < 0.60 then
						local income = math.random(1000, 5000)
						state.Money = (state.Money or 0) + income
						modStatIfPossible(state, "Happiness", 15)
						state.Flags.food_business = true
						addFeed(state, string.format("👨‍🍳 Your food is a HIT! Made $%d! Those childhood kitchen experiments paid off!", income))
					else
						modStatIfPossible(state, "Happiness", 5)
						addFeed(state, "👨‍🍳 Food business is HARD. But people love your cooking. Keep at it!")
					end
				end,
			},
			{
				text = "Cooking is just my hobby",
				effects = { Happiness = 8 },
				feedText = "👨‍🍳 Cooking for loved ones is reward enough. No pressure, just love.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.cooking_recognized = true
				end,
			},
		},
	},
	
	{
		id = "consequence_musical_moment",
		title = "Your Musical Gift Shines",
		emoji = "🎵",
		text = "Someone overheard you playing/singing. 'That was beautiful! Have you ever performed publicly?'",
		category = "consequence",
		weight = 8,
		minAge = 18, maxAge = 50,
		baseChance = 0.35,
		cooldown = 10,
		oneTime = true,
		requiresFlags = { musical_talent = true },
		blockedByFlags = { music_moment_happened = true },
		
		choices = {
			{
				text = "Perform at open mic night!",
				effects = {},
				feedText = "Stepping onto the stage...",
				onResolve = function(state)
					local roll = math.random()
					state.Flags = state.Flags or {}
					state.Flags.music_moment_happened = true
					if roll < 0.50 then
						modStatIfPossible(state, "Happiness", 25)
						state.Fame = (state.Fame or 0) + 5
						state.Flags.performed_publicly = true
						addFeed(state, "🎵 STANDING OVATION! Your childhood music practice created magic!")
					elseif roll < 0.80 then
						modStatIfPossible(state, "Happiness", 12)
						addFeed(state, "🎵 Good reception! People clapped and smiled. That felt AMAZING!")
					else
						modStatIfPossible(state, "Happiness", -5)
						addFeed(state, "🎵 Stage fright got you. But you tried! That takes courage.")
					end
				end,
			},
			{
				text = "Music is just for me",
				effects = { Happiness = 5 },
				feedText = "🎵 Private joy. Your music fills your soul even if nobody else hears.",
				onResolve = function(state)
					state.Flags = state.Flags or {}
					state.Flags.music_moment_happened = true
				end,
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCESS YEARLY FRIENDSHIP DECAY
-- Call this during age-up to naturally decay relationships
-- ═══════════════════════════════════════════════════════════════════════════════

function FriendshipDecayEvents.processYearlyDecay(state)
	local relationships = ensureRelationships(state)
	local currentAge = state.Age or 0
	local decayedFriends = {}
	
	for id, rel in pairs(relationships) do
		if type(rel) == "table" then
			if rel.type == "friend" or rel.role == "Friend" or id:find("friend") then
				if rel.alive ~= false then
					-- CRITICAL FIX: metAt can be a string like "childhood" or "randomly"!
					local lastContact = rel.lastContact or rel.lastInteraction
					if type(lastContact) ~= "number" then
						if type(rel.metAt) == "number" then
							lastContact = rel.metAt
						else
							lastContact = 0
						end
					end
					local yearsSince = math.max(0, currentAge - (tonumber(lastContact) or 0))
					
					-- Decay relationship based on years without contact
					if yearsSince >= 1 then
						local decayAmount = 0
						if yearsSince >= 5 then
							decayAmount = 15 -- Severe decay after 5+ years
						elseif yearsSince >= 3 then
							decayAmount = 8 -- Moderate decay after 3+ years
						elseif yearsSince >= 1 then
							decayAmount = 3 -- Light decay after 1+ year
						end
						
						rel.relationship = math.max(0, (rel.relationship or 50) - decayAmount)
						
						-- Mark as estranged if relationship hits 0
						if rel.relationship <= 0 then
							rel.estranged = true
							table.insert(decayedFriends, rel.name or "A friend")
						end
					end
				end
			end
		end
	end
	
	return decayedFriends
end

return FriendshipDecayEvents
