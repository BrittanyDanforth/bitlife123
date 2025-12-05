# 🚨 ROUND 3 - CRITICAL EVENT SYSTEM BUGS FOUND!

## Overview
Third deep search into EVENT LOGIC found CRITICAL bugs that break event triggering!

---

## ❌ CRITICAL BUG #16: conditions.flag is NEVER CHECKED!

### The Problem
**File**: `/workspace/LifeServer/Modules/LifeEvents/Adult.lua`, `/workspace/LifeServer/Modules/LifeEvents/Relationships.lua`

**25+ events use this format**:
```lua
{
	id = "marital_problems_emerge",
	title = "Marriage is Struggling",
	// ...
	conditions = { flag = "married" },  // ❌ NEVER CHECKED!
	choices = { /* ... */ }
}
```

**But canEventTrigger() in init.lua**:
```lua
local function canEventTrigger(event, state)
	local cond = event.conditions or {}
	
	// Checks cond.minAge, cond.maxAge ✅
	// Checks cond.requiredFlags (array) ✅
	// Checks cond.blockedFlags (array) ✅
	
	// ❌ NEVER CHECKS cond.flag!
}
```

**Events Using This (BROKEN)**:
1. Adult.lua:
   - Line 59: `conditions = { flag = "plans_for_college" }`
   - Line 81: `conditions = { flag = "plans_for_college" }`
   - Line 167: `conditions = { flag = "engaged" }`
   - Line 189: `conditions = { flag = "married" }`
   - Line 213: `conditions = { flag = "trying_for_baby" }`
   - Line 234: `conditions = { flag = "has_kids" }`
   - Line 255: `conditions = { flag = "married" }`
   - Line 277: `conditions = { flag = "affair" }`
   - Line 340: `conditions = { flag = "has_kids" }`
   - Line 406: `conditions = { flag = "has_kids" }`
   - Line 427: `conditions = { flag = "married" }`

2. Relationships.lua:
   - Line 37: `conditions = { flag = "single" }`
   - Line 58: `conditions = { flag = "single" }`
   - Line 79: `conditions = { flag = "single" }`
   - Line 104: `conditions = { flag = "dating" }`
   - Line 125: `conditions = { flag = "dating" }`
   - Line 146: `conditions = { flag = "dating" }`
   - Line 170: `conditions = { flag = "committed_relationship" }`
   - Line 191: `conditions = { flag = "committed_relationship" }`
   - Line 212: `conditions = { flag = "engaged" }`
   - Line 237: `conditions = { flag = "married" }`
   - Line 258: `conditions = { flag = "married" }`
   - Line 279: `conditions = { flag = "affair_discovered" }`

3. Teen.lua:
   - Line 290: `conditions = { flag = "has_partner" }`
   - Line 312: `conditions = { flag = "has_partner" }`

**Impact**:
- 🔴 **CRITICAL**: 25+ events will TRIGGER WHEN THEY SHOULDN'T!
- Marriage events fire when you're single
- Affair events fire when you've never cheated
- College events fire when you never went to college
- Relationship events fire randomly

**Severity**: 🔴 **GAME-BREAKING**

**Fix Required**:
```lua
local function canEventTrigger(event, state)
	local flags = state.Flags or {}
	local cond = event.conditions or {}
	
	// ... existing checks ...
	
	// 🔥 ADD THIS:
	if cond.flag then
		if not flags[cond.flag] then
			return false  // Missing required flag
		end
	end
	
	return true
end
```

---

## ⚠️ BUG #17: Career.lua Uses BOTH requiresJobCategory AND careerTags

### The Problem
**File**: `/workspace/LifeServer/Modules/LifeEvents/Career.lua`

**5 events use REDUNDANT fields**:
```lua
{
	id = "tech_innovation",
	// ...
	requiresJob = true,
	requiresJobCategory = "tech",  // ❌ Redundant!
	careerTags = { "tech", "startup" },  // ❌ Also tags it!
}
```

**Why This is Bad**:
1. `requiresJobCategory` is checked by canEventTrigger()
2. `careerTags` is used for event weighting/priority
3. Using BOTH is redundant and confusing
4. If they mismatch, unexpected behavior!

**Events Affected**:
- Line 198: `requiresJobCategory = "tech"` + `careerTags = { "tech", "startup" }`
- Line 224: `requiresJobCategory = "medical"` + `careerTags = { "medical" }`
- Line 249: `requiresJobCategory = "law"` + `careerTags = { "law" }`
- Line 274: `requiresJobCategory = "creative"` + `careerTags = { "creative" }`
- Line 300: `requiresJobCategory = "sports"` + `careerTags = { "sports" }`

**Recommended Fix**:
Remove `requiresJobCategory` entirely and ONLY use `careerTags`:
```lua
{
	id = "tech_innovation",
	// ...
	requiresJob = true,
	careerTags = { "tech", "startup" },  // ✅ Just use this!
}
```

**Severity**: 🟡 **MODERATE** - Redundant code

---

## 🔍 BUG #18: Career.lua Event Has requiresJobCategory But NO requiresJob!

### The Problem
**File**: `/workspace/LifeServer/Modules/LifeEvents/Career.lua`  
**Line 352**:

```lua
{
	id = "starting_business",
	// ...
	requiresFlags = { entrepreneur = true },
	// ❌ Has requiresJobCategory but NO requiresJob!
}
```

**What Happens**:
- canEventTrigger() checks if `state.CurrentJob` exists (line 428)
- If no job, returns false
- So event requires job... but doesn't say `requiresJob = true`!

**This is confusing!**

**Fix**:
```lua
{
	id = "starting_business",
	requiresJob = true,  // ✅ Make it explicit!
	requiresFlags = { entrepreneur = true },
}
```

**Severity**: 🟡 **MODERATE** - Confusing code

---

## 📊 Summary

| Bug # | Severity | File(s) | Issue |
|-------|----------|---------|-------|
| #16 | 🔴 CRITICAL | Adult.lua, Relationships.lua, Teen.lua | `conditions.flag` NEVER checked - 25+ events broken! |
| #17 | 🟡 MODERATE | Career.lua | Redundant `requiresJobCategory` + `careerTags` |
| #18 | 🟡 MODERATE | Career.lua | Missing explicit `requiresJob = true` |

---

## 🎯 Priority Fixes

### MUST FIX NOW:
1. 🔴 **Add conditions.flag checking to canEventTrigger()**
   - This breaks 25+ events!
   - Marriage events fire when single
   - Affair events fire randomly
   - **GAME-BREAKING!**

### SHOULD FIX SOON:
2. 🟡 Remove redundant `requiresJobCategory` from Career.lua
3. 🟡 Add explicit `requiresJob = true` to starting_business event

---

## 🔧 Fixes in Progress

Fixing BUG #16 NOW - this is CRITICAL!

---

**Status**: CRITICAL EVENT LOGIC BUG FOUND AND FIXING!
