# BitLife-Grade Backend Setup

**Purpose:** deliver a "triple-AAAA" BitLife-style backend that stays fully deterministic, supports 100+ careers, and feeds every premium UI screen without random junk events.

---

## 🔩 What’s Inside

```
/LifeClient                 -- BitLife-grade UI already wired to LifeRemotes
/LifeServer
  ├── LifeBackend.lua       -- singleton bootstrap; wires remotes & yearly queue
  └── Modules
      ├── LifeState.lua         -- per-player save: stats, flags, traits, assets, history
      ├── LifeStageSystem.lua   -- age stages, capability gates, death math
      └── LifeEvents
          ├── init.lua          -- event loader/registry facade
          ├── EventEngine.lua   -- normalization, eligibility, weighted picks, choice resolver
          ├── CareerSystem.lua  -- starter job catalog + helpers
          └── Catalog/*.lua     -- drop-in event packs (CoreMilestones, CareerEvents, RomanceEvents, CrimeEvents, …)
```

---

## ⚙️ Install & Boot

1. **Server placement**
   - Drop the entire `LifeServer` folder into `ServerScriptService`.
   - `LifeServer/init.server.lua` stays as-is (require + `.init()`).

2. **Client placement**
   - Put `LifeClient` into `StarterPlayerScripts` (or wherever you mount your UI).
   - It already waits on `ReplicatedStorage/LifeRemotes`.

3. **Playtest**
   - In Studio, launch a Local Server, hit “Age Up”, and you should see authored event queues, stat adjustments, and UI flashes.

> **Persistence:** hook DataStores into `LifeState:Serialize()` / `LifeState.fromSerialized()` when you’re ready to save lives.

---

## 🧠 Core Concepts

| Piece | Highlights |
|-------|------------|
| `LifeState` | traits, stats, money, assets, relationships, education, career, paths, event history, feed buffer, serializer/deserializer |
| `LifeStageSystem` | converts age → stage (infant → elder), exposes capability flags (`canWork`, `canDate`, etc.), validates categories, injects guaranteed milestone events, runs health-aware death rolls |
| `LifeEvents` | auto-loads event modules, normalizes conditions, surfaces helpers like `selectEventsForYear`, `processChoice`, `getStats` |
| `EventEngine` | deterministically filters eligible events, does weighted selection, resolves choice effects (stats, money, relationships, flags) |
| `CareerSystem` | baseline career catalog + helpers for applications, income drift, promotions |
| `LifeBackend` | remote wiring, aging loop, queue orchestration, feed pushes, bridging existing UI remotes |

The backend delivers data to `LifeClient` through `SyncState` and `PresentEvent`. UI responds with `SubmitChoice`, and the server resolves everything — no client trust.

---

## 🔁 Yearly Flow

1. `RequestAgeUp` (client) → server grabs `LifeState`.
2. `LifeState:AdvanceAge()` increments year, logs feed, and updates career stats.
3. `LifeStageSystem.getTransitionEvent()` adds guaranteed “stage change” milestones.
4. `LifeEvents.buildYearQueue()` curates contextual events (career, romance, crime, etc.) filtered through stage gates and flag requirements.
5. Each event is sent to the client via `PresentEvent`. Player choice returns through `SubmitChoice`.
6. `EventEngine.completeEvent()` mutates `LifeState` deterministically, records history, and builds `resultData` (for UI shakes/flash).
7. After the queue clears, `LifeStageSystem.checkDeath()` determines if the life ends; `SyncState` pushes the final state + feed entry.

---

## 🛰 Remote Overview

**RemoteEvents**
- `RequestAgeUp`, `SyncState`, `PresentEvent`, `SubmitChoice`, `SetLifeInfo`, `MinigameStart`, `MinigameResult`

**RemoteFunctions**
- Activities & risk: `DoActivity`, `CommitCrime`, `DoPrisonAction`
- Careers/Education: `ApplyForJob`, `QuitJob`, `DoWork`, `RequestPromotion`, `RequestRaise`, `GetCareerInfo`, `GetEducationInfo`, `EnrollEducation`
- Assets/Money: `BuyProperty`, `BuyVehicle`, `BuyItem`, `SellAsset`, `Gamble`
- Social & Story: `DoInteraction`, `StartPath`, `DoPathAction`

All remotes are created automatically under `ReplicatedStorage/LifeRemotes`.

---

## 🧩 Authoring Events

1. New ModuleScript inside `LifeServer/Modules/LifeEvents/Catalog`.
2. Return a table of events; each event can include:
   ```lua
   {
     id = "karting_chance",
     emoji = "🏎️",
     title = "Karting Opportunity",
     category = "motorsport",
     conditions = {
       minAge = 8,
       maxAge = 15,
       requiredFlags = { "racing_interest" },
       minStats = { Health = 40 },
     },
     choices = {
       {
         text = "Sign up",
         effects = { Happiness = 4, Money = -500 },
         flags = { set = { "karting_started" } },
       },
       { text = "Skip", effects = { Happiness = -2 } },
     },
   }
   ```
3. Loader auto-normalizes IDs, conditions, flags, weights, and injects into the master registry.
4. Use `conditions.custom = function(state) ... end` for bespoke logic.

---

## 🪙 Careers, Education, Assets, Crime

- `LifeState:SetCareer(jobDef)` handles feeds, flags, and progress.
- `CareerSystem.getJobsForState(state)` filters the catalog by education/flags.
- Education flows through `LifeState:EnrollEducation()` and `LifeState:Graduate()`.
- Crime/prison actions set `in_prison` flags so `LifeStageSystem` blocks certain categories automatically.
- Assets & gambling APIs are exposed through RemoteFunctions and update net worth and feed entries server-side.

---

## ✅ Suggested QA Pass

- [ ] Create a life, set name/gender, and age up repeatedly — check that stage events trigger.
- [ ] Apply for jobs, enroll in school, buy/sell assets, commit crimes — ensure state stays deterministic.
- [ ] Spam `DoInteraction` to confirm relationship helpers work across families, friends, romance.
- [ ] Verify `resultData` values animate the client (shakes/red flashes) for big negative outcomes.
- [ ] Call `LifeEvents.getStats()` in the console to verify coverage after adding new packs.

---

## 🚀 Extending

- Add more catalog modules for medical, celebrity, political, global story arcs.
- Wire DataStores for persistence (serialization already done).
- Feed analytics dashboards using `LifeEvents.getStats()` to catch content gaps.
- Swap catalog folders at runtime for seasonal updates.

---

_Drop this backend into your experience and you get BitLife vibes: contextual events, authored deaths, screen shakes for bad beats, and zero random nonsense._