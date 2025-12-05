# 🔍 ASSET SYNC - COMPREHENSIVE DEBUG GUIDE

## Overview
I've added EXTENSIVE debug logging throughout the ENTIRE asset system to trace exactly where assets are getting lost between events/purchases and the AssetsScreen display.

---

## 🎯 Debug Points Added

### 1. **LifeBackend.lua** - `handleAssetPurchase()`
**Location**: Server-side asset purchase handler
**What it logs**:
- Asset purchase request (player, type, ID)
- Player's current age, money, and asset counts
- Asset found in catalog (name, price)
- Asset being added to state (ID, name, value, category)
- New count after addition
- Full list of assets in that category
- Flags set (has_vehicle, has_property, etc.)
- Money subtraction
- **Final state being pushed to client** with asset counts

**Log prefix**: `[ASSET PURCHASE]`

### 2. **EventEngine.addAsset()** - `/LifeServer/Modules/LifeEvents/init.lua`
**Location**: Event-based asset acquisition
**What it logs**:
- Event trying to add asset (type, name)
- Category normalization (property → Properties)
- Built asset entry (ID, name, value, isEventAcquired)
- Asset count BEFORE adding
- Whether using `state:AddAsset()` or direct `table.insert`
- Asset count AFTER adding
- Full list of assets in that category
- Confirmation of completion

**Log prefix**: `[EventEngine.addAsset]`

### 3. **LifeClient** - `SyncState.OnClientEvent`
**Location**: Client receiving state updates from server
**What it logs**:
- State received notification
- Player age and money
- **FULL Assets structure with counts per category**
- **Every individual asset** (ID and name) in each category
- Total assets in state
- Warning if Assets table is missing

**Log prefix**: `[LifeClient SyncState]`

### 4. **AssetsScreen** - `updateState()`
**Location**: Screen receiving state update
**What it logs**:
- Update notification
- Age and money
- **Deep inspection of Assets.Properties, Assets.Vehicles, Assets.Items, etc.**
- Total assets found
- Whether screen is visible (determines if refresh happens)
- Warning if Assets is nil

**Log prefix**: `[AssetsScreen]`

### 5. **AssetsScreen** - `getAssets()`
**Location**: Flattening assets into lookup table
**What it logs**:
- Flattening start
- Each category being processed (Properties, Vehicles, Items, Crypto, Businesses, Investments)
- **Every individual asset** being added to flat table (ID, name, value)
- Warnings for invalid entries (missing ID)
- Total flattened asset count

**Log prefix**: `[AssetsScreen]`

### 6. **AssetsScreen** - `deepLog()` utility
**Location**: Deep structure inspection
**What it logs**:
- Nested table structures
- Empty tables
- Non-table values

---

## 🧪 Testing Scenarios

### Test 1: Buy Property via AssetsScreen UI
**Steps**:
1. Start game, age up to 18+
2. Open AssetsScreen
3. Buy a property (e.g., Studio Apartment)

**What to watch in console**:
```
[ASSET PURCHASE] ═════════════════════════════════════════════════════════════
[ASSET PURCHASE] ASSET PURCHASE REQUEST
[ASSET PURCHASE] Player: YourName
[ASSET PURCHASE] Asset Type: Properties
[ASSET PURCHASE] Asset ID: studio
[ASSET PURCHASE] ═════════════════════════════════════════════════════════════
...
[ASSET PURCHASE] ✅ Asset added! New count in Properties : 1
[ASSET PURCHASE] Full Properties list:
[ASSET PURCHASE]   [1] studio - Studio Apartment
...
[ASSET PURCHASE] PUSHING STATE TO CLIENT
[ASSET PURCHASE] Assets being sent:
[ASSET PURCHASE]   Properties: 1
[ASSET PURCHASE]   Vehicles: 0
[ASSET PURCHASE]   Items: 0
```

Then immediately:
```
[LifeClient SyncState] ═══════════════════════════════════════════════════════════
[LifeClient SyncState] STATE RECEIVED FROM SERVER
[LifeClient SyncState] Assets structure received:
[LifeClient SyncState]   Properties: 1 items
[LifeClient SyncState]     [1] studio - Studio Apartment
[LifeClient SyncState] TOTAL ASSETS IN STATE: 1
```

Then:
```
[AssetsScreen] ═══════════════════════════════════════════════════════════════
[AssetsScreen] UPDATING ASSETSSCREEN STATE
[AssetsScreen] ASSETS STRUCTURE:
[AssetsScreen]   Assets.Properties
[AssetsScreen]     [Properties] = {...}
[AssetsScreen] Properties: 1 assets
[AssetsScreen] TOTAL ASSETS FOUND: 1
```

**Expected**: Studio Apartment should now show in "🏠 My Properties" section at top of Properties tab!

**If it fails**: Check which log shows Assets disappearing or being empty!

---

### Test 2: Inherit Property from Event (Random.lua)
**Steps**:
1. Age up repeatedly until you get "Unexpected Inheritance" event
2. Choose "An old house" option
3. Check AssetsScreen

**What to watch**:
```
[EventEngine.addAsset] ═══════════════════════════════════════════════════════════
[EventEngine.addAsset] EVENT ADDING ASSET
[EventEngine.addAsset] Asset Type: property
[EventEngine.addAsset] Asset Data: Inherited House
[EventEngine.addAsset] Normalized category: Properties
[EventEngine.addAsset] Built asset entry:
[EventEngine.addAsset]   ID: inherited_house_25
[EventEngine.addAsset]   Name: Inherited House
[EventEngine.addAsset]   Value: 120000
[EventEngine.addAsset]   IsEventAcquired: true
[EventEngine.addAsset] Assets BEFORE adding:
[EventEngine.addAsset]   Properties: 0 items
[EventEngine.addAsset] Using state:AddAsset() method
[EventEngine.addAsset] Assets AFTER adding:
[EventEngine.addAsset]   Properties: 1 items
[EventEngine.addAsset]     [1] inherited_house_25 - Inherited House
[EventEngine.addAsset] ✅ Asset addition COMPLETE
```

Then should see LifeClient SyncState receive it, then AssetsScreen update.

**Expected**: Inherited House appears in AssetsScreen Properties tab with 🏚️ emoji!

---

### Test 3: Get First Car from Milestone Event
**Steps**:
1. Age up to 16-18
2. Get "Your First Car" milestone event
3. Choose any car option
4. Check AssetsScreen Vehicles tab

**What to watch**:
```
[EventEngine.addAsset] ═══════════════════════════════════════════════════════════
[EventEngine.addAsset] EVENT ADDING ASSET
[EventEngine.addAsset] Asset Type: vehicle
[EventEngine.addAsset] Asset Data: Beat-up Used Car
[EventEngine.addAsset] Normalized category: Vehicles
...
[EventEngine.addAsset] Assets AFTER adding:
[EventEngine.addAsset]   Vehicles: 1 items
[EventEngine.addAsset]     [1] beater_car_16 - Beat-up Used Car
```

**Expected**: Car shows in "🚗 My Garage" section of Vehicles tab!

---

## 🚨 Common Issues to Look For

### Issue 1: Assets Added But Not Synced
**Symptom**: Server logs show asset added, client never receives it
**Check**: 
- Does `[ASSET PURCHASE] PUSHING STATE TO CLIENT` show the asset?
- Does `[LifeClient SyncState]` receive empty Assets?
- **Possible cause**: Serialization bug in LifeState:Serialize()

### Issue 2: Client Receives But Screen Doesn't Update
**Symptom**: LifeClient logs show Assets, AssetsScreen shows empty
**Check**:
- Is AssetsScreen visible when state updates?
- Does `[AssetsScreen] Screen is NOT visible` appear?
- **Possible cause**: Screen not refreshing when invisible

### Issue 3: Assets Have Wrong Structure
**Symptom**: Assets exist but getAssets() can't find them
**Check**:
- Are assets arrays or objects?
- Do they have `id` fields?
- **Possible cause**: ID mismatch between catalog and added asset

### Issue 4: Catalog vs Event-Acquired Mismatch
**Symptom**: Shop purchases work, event acquisitions don't
**Check**:
- Does event use EventEngine.addAsset() correctly?
- Does asset have `isEventAcquired = true` flag?
- Is the ID unique (not conflicting with catalog)?
- **Possible cause**: populateProperty() only showing catalog items

---

## 🔧 Quick Fixes

### If Assets Aren't Showing in UI:
1. Open AssetsScreen
2. Check console for `[AssetsScreen] TOTAL ASSETS FOUND: X`
3. If 0, but LifeClient shows assets → **AssetsScreen.getAssets() bug**
4. If LifeClient shows 0 assets → **Serialization or sync bug**
5. If server never adds asset → **Purchase/event bug**

### If Event-Acquired Assets Work But UI Purchases Don't:
1. Check `[ASSET PURCHASE]` logs
2. Verify assetType matches ("Properties" not "property")
3. Check catalog has the asset ID

### If UI Shows Assets Initially But They Disappear:
1. Check if state is being reset
2. Look for "A new life begins..." in logs
3. Check if LifeBackend is creating new state on accident

---

## ✅ Success Criteria
When working correctly, you should see:
1. **Server** logs asset addition with new count
2. **Server** pushes state with Assets included
3. **Client** receives Assets in state
4. **AssetsScreen** updates with Assets structure
5. **AssetsScreen** flattens and displays assets in UI
6. **UI** shows asset in "My Properties/Garage/Stuff" section

**All 6 steps must succeed for assets to display!**

---

## 📝 Notes
- Debug logging is ENABLED by default in all asset-related code
- Logs are prefixed for easy filtering
- Deep structure inspection shows exact table contents
- Total counts help identify WHERE assets disappear

---

## 🎯 Next Steps
1. Test all 3 scenarios above
2. Paste console logs if assets still don't show
3. Identify which step fails (1-6 from Success Criteria)
4. I'll fix the exact point of failure!

---

**This debug system will pinpoint EXACTLY where your assets are getting lost!** 🔍
