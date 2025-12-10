# Premium Features System - BitLife Style

## Overview
This document describes the premium gamepass features implemented in the BitLife-style game. Features are integrated naturally into gameplay (like BitLife) rather than a separate shop.

---

## 🎮 Gamepasses Available

### 👑 Bitizenship (R$ 299)
Unlock premium features and enhanced gameplay.
- Ad-free experience
- Access to Royalty careers
- Special character customization
- Exclusive random events
- Start with bonus money

### ⚡ God Mode (R$ 499)
Edit your stats anytime - become the perfect person.
- Edit Happiness, Health, Smarts, Looks (0-100)
- Change your character's appearance
- Modify relationship levels
- Instant skill boosts

### ⏰ Time Machine (R$ 399)
Go back in time when you die - fix your mistakes.
- Go back 5 years
- Go back 10 years
- Go back 20 years
- Go back 30 years
- Restart as baby (same character)

### 🔫 Organized Crime / Mafia (R$ 499)
Join the criminal underworld and rise through the ranks.
- Join 5 crime families (Italian, Russian, Yakuza, Cartel, Triad)
- Rise from Associate to Boss
- Run criminal operations
- Territory wars
- Special mafia events

### 💼 Boss Mode (R$ 399)
Start your own business empire.
- Start any type of business
- Hire and fire employees
- Expand to multiple locations
- Go public with IPO
- Franchise your business

### 👸 Royalty (R$ 299)
Be born into royalty.
- Born as royalty (random country)
- Inherit the throne
- Royal duties and events
- Massive wealth
- Royal scandals

---

## 📁 Files Created

### Server-Side Modules (`/workspace/LifeServer/Modules/`)

#### `GamepassSystem.lua`
Core gamepass management system.
- Gamepass definitions with prices and features
- Ownership checking via MarketplaceService
- Purchase prompting
- Premium status tracking for players

#### `MobSystem.lua`
Organized crime/Mafia system.
- 5 crime families with unique themes, colors, and ranks
- Operations system with risk/reward
- Rank progression (Associate → Boss)
- Heat/notoriety tracking
- Annual mob events

#### `TimeMachine.lua`
Time travel system for death screen.
- Snapshot system saves state every 5 years
- Multiple time travel options
- Default stats calculation for target age
- Integration with death screen

### Client-Side (`/workspace/`)

#### `PremiumUI.lua`
Client UI components for premium features.
- Premium Store modal
- Time Machine death screen
- Mob family selection UI
- God Mode stat editor
- BitLife-style purchase prompts

#### `ActivitiesScreen` (Modified)
Integrated Organized Crime into Crime tab.
- "Organized Crime" section with crown icon
- 5 crime families to join
- Mob status display when in a family
- Criminal operations cards
- BitLife-style purchase prompts when locked

---

## 🎯 How It Works (BitLife Style)

### Organized Crime
1. Go to **Activities → Crime** tab
2. Scroll to **"🔫 Organized Crime"** section (marked with 👑)
3. Choose a crime family to join
4. If you don't own the gamepass, a BitLife-style purchase prompt appears
5. If you own it, you join and can do operations

### Time Machine (Death Screen)
1. When your character dies, the Time Machine UI appears
2. Shows options: 5, 10, 20, 30 years back, or restart as baby
3. If you own the gamepass, click to go back
4. If not, purchase prompt appears
5. Alternative: "Start New Life" to begin fresh

### God Mode
1. Access via stats area (integration point)
2. Sliders for each stat (0-100)
3. Apply changes instantly
4. Requires God Mode gamepass

---

## 🔧 Server Remotes Needed

Create these RemoteEvents/Functions in `ReplicatedStorage.LifeRemotes`:

```
- CheckGamepass (RemoteFunction) - Check if player owns gamepass
- PromptGamepass (RemoteEvent) - Prompt gamepass purchase
- JoinMob (RemoteFunction) - Join a crime family
- LeaveMob (RemoteFunction) - Leave crime family
- DoMobOperation (RemoteFunction) - Execute mob operation
- ApplyGodMode (RemoteFunction) - Apply god mode stat changes
- TimeTravel (RemoteFunction) - Execute time travel
```

---

## 🎨 UI Design Notes

### BitLife-Style Purchase Prompts
- Gold/yellow accent color (#FFD700)
- Crown emoji (👑) for premium features
- Clean white card with colored border
- "Unlock Now" primary button
- "Maybe Later" secondary button

### Mob Cards
- Each family has unique flag emoji and color
- Shows name and short description
- "Join" button (or 👑 Join if locked)
- Status card when in a mob shows rank, respect, heat

### Time Machine
- Blue theme (#3B82F6)
- Clock emoji (⏰) header
- List of time travel options
- Grayed out if not applicable (e.g., can't go back 30 years at age 25)

---

## 📝 Implementation Notes

1. **Gamepass IDs**: Replace `id = 0` in `GamepassSystem.lua` with actual Roblox gamepass IDs after creating them in Roblox Studio.

2. **Product IDs**: For consumable purchases (single time travel uses), create Developer Products and update IDs.

3. **State Persistence**: MobState is added to LifeState and should be serialized/deserialized with player data.

4. **Testing**: Set gamepass IDs to 0 for testing - the system returns `false` for ownership, allowing you to test purchase prompts.

---

## ✅ Integration Checklist

- [x] GamepassSystem module created
- [x] MobSystem module created  
- [x] TimeMachine module created
- [x] PremiumUI client module created
- [x] Organized Crime in Activities Crime tab
- [x] BitLife-style purchase prompts
- [ ] Create actual Roblox gamepasses
- [ ] Set up server remotes
- [ ] Add MobState to LifeState serialization
- [ ] Integrate Time Machine with death flow
- [ ] Add God Mode button to stats UI
