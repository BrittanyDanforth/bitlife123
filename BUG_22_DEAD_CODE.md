# 🚨 BUG #22: 200+ LINES OF DEAD EVENT CODE IN LIFEBACKEND

## The Problem
**Severity**: 🟡 **MODERATE - CODE QUALITY ISSUE**

`LifeBackend.lua` contains **200+ lines of DEAD EVENT CODE** that's NEVER USED!

### Dead Code Location:
**Lines 531-730 in `/workspace/LifeBackend.lua`**

```lua
local EventCatalog = {
	childhood = {
		{
			id = "child_schoolyard",
			title = "Schoolyard Antics",
			emoji = "🎒",
			text = "A bully keeps bothering you during recess.",
			// ... 20+ events in old format
		},
	},
	teen = { /* more dead events */ },
	adult = { /* more dead events */ },
	career = { /* more dead events */ },
	romance = { /* more dead events */ },
	crime = { /* more dead events */ },
	general = { /* more dead events */ },
}
```

---

## Why It's Dead Code

### The System Currently Uses:
```lua
-- Line 1293: LifeBackend uses LifeEvents module!
local yearlyEvents = LifeEvents.buildYearQueue(state, { maxEvents = 1 }) or {}
```

### EventCatalog is NEVER Referenced:
```bash
$ grep "EventCatalog\[" /workspace/LifeBackend.lua
# NO RESULTS! ❌
```

The `EventCatalog` table is **defined** but **NEVER ACCESSED**!

---

## The Impact

### Problems:
1. **Code Bloat** - 200+ lines of unused code
2. **Confusion** - Developers might think this is active
3. **Maintenance** - Dead code still needs to be read/understood
4. **Performance** - Unnecessarily large file size (2690 lines!)
5. **Outdated Format** - Uses old format (deltas, flags, feed) instead of new format (effects, setFlags, feedText)

### File Size:
- **Total**: 2690 lines
- **Dead EventCatalog**: ~200 lines (7.4% of file!)
- **Could be reduced to**: ~2490 lines

---

## Old vs New Event Format

### Old Format (DEAD CODE):
```lua
{
	id = "teen_party",
	title = "House Party Invite",
	emoji = "🥳",
	text = "Friends invite you to a rowdy party...",
	question = "What's the move?",
	choices = {
		{ 
			text = "Stay in and study", 
			deltas = { Smarts = 3, Happiness = -2 }, // ❌ OLD: "deltas"
			feed = "skipped a party to study."         // ❌ OLD: "feed"
		},
	},
}
```

### New Format (ACTIVE):
```lua
{
	id = "first_college_party",
	title = "The College Party",
	emoji = "🎉",
	text = "Your roommate drags you to your first college party...",
	question = "What do you do?",
	minAge = 18, maxAge = 20,
	stage = "adult",
	category = "social",
	conditions = { flag = "plans_for_college" },
	choices = {
		{ 
			text = "Drink and party hard", 
			effects = { Happiness = 10, Health = -5 }, // ✅ NEW: "effects"
			setFlags = { party_animal = true },        // ✅ NEW: "setFlags"
			feedText = "You got WASTED..."             // ✅ NEW: "feedText"
		},
	},
}
```

---

## What Should Be Done

### Option 1: DELETE IT (Recommended)
Remove lines 531-730 entirely. The events are:
- Not being used
- In outdated format
- Redundant with LifeEvents modules

### Option 2: MIGRATE IT
Convert the EventCatalog events to the new format and move them to:
- `/workspace/LifeServer/Modules/LifeEvents/Catalog/CoreMilestones`
- `/workspace/LifeServer/Modules/LifeEvents/Catalog/CrimeEvents`
- etc.

But this is probably NOT needed since the LifeEvents modules already have better versions of these events!

---

## Events That Are Dead Code

### Childhood Events (Dead):
- `child_schoolyard` - Schoolyard Antics
- `child_sickday` - Sick Day

### Teen Events (Dead):
- `teen_exam` - Entrance Exam
- `teen_party` - House Party Invite

### Adult Events (Dead):
- `adult_midlife` - Midlife Crisis
- `adult_car` - First Car

### Career Events (Dead):
- `career_promotion` - Surprise Promotion
- `career_conflict` - Office Drama

### Romance Events (Dead):
- `romance_conflict` - Heart-to-Heart

### Crime Events (Dead):
- `crime_dilemma` - Risky Opportunity

### General Events (Dead):
- `general_raise` - Unexpected Raise
- `general_volunteer` - Volunteer Day

**Total**: ~20+ events in old format, NEVER USED!

---

## Recommendation

**DELETE DEAD CODE!**

Remove lines 531-730 from `/workspace/LifeBackend.lua` to:
- Reduce file size by 200+ lines
- Eliminate confusion
- Improve code maintainability
- Remove outdated event format

The LifeEvents module system is far superior and already active!

---

## Status

🟡 **MODERATE CODE QUALITY ISSUE**

**BUG #22 IDENTIFIED: 200+ lines of dead event code in LifeBackend.lua!**
