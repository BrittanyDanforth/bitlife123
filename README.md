# BitLife-Grade Backend Setup (Zero → Live)

You can start from an empty Roblox place and end with a BitLife-style backend by following this exact checklist. Copy/paste each step and you’ll go from nothing to a scripted, deterministic life simulator with working UI hooks.

---

## 0. Prereqs

- Roblox Studio installed (latest release)
- A clean place file (File → New)
- This repo cloned somewhere handy

```
git clone https://github.com/your-org/bitlife-backend.git
```

---

## 1. Folder Bootstrapping (Studio)

1. Open your place in Studio.
2. In **ServerScriptService**, create a folder named `LifeServer`.
3. Drag/drop the contents of this repo’s `/LifeServer` folder into that Studio folder.
   - Ensure `LifeServer/init.server.lua` sits directly inside (not nested deeper).
4. In **ReplicatedStorage**, no manual setup required (backend will auto-create remotes).
5. In **StarterPlayer > StarterPlayerScripts**, create/drag a folder named `LifeClient` if you don’t already have one.
6. Copy the `/LifeClient` folder from the repo into `StarterPlayerScripts`.

Your Explorer should look like:
```
ServerScriptService
└── LifeServer
    ├── init.server.lua
    ├── LifeBackend.lua
    └── Modules
        ├── LifeState.lua
        ├── LifeStageSystem.lua
        └── LifeEvents
StarterPlayer
└── StarterPlayerScripts
    └── LifeClient
ReplicatedStorage
└── (empty – remotes will spawn at runtime)
```

---

## 2. Server Wiring

No extra scripts required—`LifeServer/init.server.lua` already contains:
```lua
local backendModule = require(script:WaitForChild("LifeBackend"))
backendModule.init()
```
That bootstrapper:
- Creates `ReplicatedStorage/LifeRemotes`
- Instantiates all RemoteEvents/RemoteFunctions
- Hooks into `Players.PlayerAdded/Removing`
- Constructs a `LifeState` per player and keeps it authoritative on the server

---

## 3. Client Wiring

`LifeClient` is a turnkey UI package that expects those remotes. Ensure the folder includes:
- `Main.client.lua` (or similar bootstrap script)
- Screen modules (`ActivitiesScreen`, `OccupationScreen`, `AssetsScreen`, `RelationshipsScreen`, `StoryPathsScreen`, `Minigames`)
- Shared helpers (stat bars, feed, modals)

When the backend fires `SyncState`, the client updates headers, stats, and feed. When `PresentEvent` fires, the client shows the modal. No additional code needed unless you’re customizing UI.

---

## 4. Data Schema (LifeState)

Every player gets a `LifeState` instance with:
- Core identity: `Name`, `Gender`, `Age`, `Year`
- Stats: `Happiness`, `Health`, `Smarts`, `Looks`
- Flags: `state.Flags` (set/clear for story conditions)
- Relationships: flat map keyed by GUID or role
- Career info: `state.Career`, `state.CurrentJob`, `state.CareerInfo`
- Education info: `state.Education`, `state.EducationData`
- Assets: properties, vehicles, items, crypto
- Story: active paths, progress
- Event history: seen IDs, cooldowns, recent feed entries
- Personality traits: generated at birth

Serialization helpers are ready:
```lua
local serialized = lifeState:Serialize()
lifeState = LifeState.fromSerialized(player, serialized)
```
Use these when you plug into DataStores.

---

## 5. Yearly Loop (Age Up)

1. Client fires `RequestAgeUp` (button).
2. Server grabs `LifeState` → `LifeState:AdvanceAge()`.
3. Stage transitions come from `LifeStageSystem.getTransitionEvent(oldAge, newAge)`.
4. Main event queue: `LifeEvents.buildYearQueue(state, { maxEvents = 2 })`.
5. Each event becomes a modal via `PresentEvent` (server → client). Client replies with `SubmitChoice`.
6. `LifeEvents.processChoice` / `EventEngine.completeEvent` apply stats, money, flags, career deltas.
7. After queue empties, `LifeStageSystem.checkDeath(state)` decides if the life ends.
8. Final `SyncState` updates UI with feed entry + `resultData` for screen shakes/flashes.

If the player dies, the backend sets `state.Flags.dead` and pushes a “Life Ended” popup so the UI can run obituaries/retry logic.

---

## 6. Remote Catalog

Created automatically inside `ReplicatedStorage/LifeRemotes`:

| Remote | Type | Purpose |
|--------|------|---------|
| `RequestAgeUp` | RemoteEvent | Client → Server, trigger yearly advance |
| `SyncState` | RemoteEvent | Server → Client, send serialized state + feed + resultData |
| `PresentEvent` | RemoteEvent | Server → Client, show life event modal |
| `SubmitChoice` | RemoteEvent | Client → Server, respond to modal |
| `SetLifeInfo` | RemoteEvent | Client → Server, set name/gender |
| `MinigameStart` / `MinigameResult` | RemoteEvents | For QTE/heist/escape modules |
| `DoActivity`, `CommitCrime`, `DoPrisonAction` | RemoteFunctions | Activities & prison slots |
| `ApplyForJob`, `QuitJob`, `DoWork`, `RequestPromotion`, `RequestRaise` | RemoteFunctions | Career loops |
| `GetCareerInfo`, `GetEducationInfo`, `EnrollEducation` | RemoteFunctions | Info panels + enrollments |
| `BuyProperty`, `BuyVehicle`, `BuyItem`, `SellAsset`, `Gamble` | RemoteFunctions | Assets & gambling |
| `DoInteraction` | RemoteFunction | Relationships screen |
| `StartPath`, `DoPathAction` | RemoteFunctions | Long-form story paths |

You don’t create these manually; `LifeBackend` handles it.

---

## 7. Event Authoring Pipeline

1. Add a ModuleScript under `LifeServer/Modules/LifeEvents/Catalog/YourPack.lua`.
2. Return `return { ...events... }` where each event uses the normalized schema:
   ```lua
   {
     id = "white_collar_scheme",
     emoji = "💼",
     title = "Insider Trading Tip",
     text = "Coworker offers an illegal stock tip.",
     category = "crime",
     weight = 3,
     conditions = {
       minAge = 25,
       requiredFlags = { "employed" },
       blockedFlags = { "in_prison" },
     },
     choices = {
       {
         text = "Invest secretly",
         effects = { Money = 15000, Happiness = 3 },
         onResolve = function(state)
           if Random.new():NextNumber() < 0.25 then
             state:SetFlag("in_prison", true)
             state:AddFeed("Authorities traced the trade. You were arrested.")
           end
         end,
       },
       { text = "Report it", effects = { Happiness = -1, Smarts = 2 } },
     },
   }
   ```
3. Loader finds every module, normalizes conditions/flags, and registers them.
4. Use `LifeEvents.getStats()` in the console to confirm coverage by category/stage.

---

## 8. Activities / Careers / Assets Hooks

- **Activities:** `ActivityCatalog` maps IDs to stat deltas, cost, feed text. Client calls `DoActivity`, backend clamps stats, pushes feed entry, and returns `resultData` for UI effects.
- **Careers:** `CareerSystem` exposes `getJobsForState`, `getJob`, `simulateWork`. Use `ApplyForJob`, `DoWork`, `RequestPromotion`, `RequestRaise` remotes from the Occupation screen.
- **Education:** `EnrollEducation` remote charges tuition, sets `student` flag, updates `LifeState.EducationData`. Graduation triggers feed + flag updates.
- **Assets:** `BuyProperty`, `BuyVehicle`, `BuyItem`, `SellAsset`, `Gamble` handle the Assets screen, always server-authoritative.
- **Crimes & Prison:** `CommitCrime` returns success/caught plus jail years; `DoPrisonAction` exposes workouts, appeals, riots, escape attempts.
- **Story Paths:** `StartPath` and `DoPathAction` mutate `state.Paths` and drive long-form arcs like political or criminal empires.

---

## 9. Testing Script

1. Studio → Test tab → Play (Local Server w/2 players recommended).
2. In the client window:
   - Run through tutorial/introduction.
   - Set life info, hit Age Up repeatedly.
   - Ensure milestone events (child → teen, teen → adult, etc.) show.
   - Try every screen (activities, crimes, jobs, assets, relationships, story paths, minigames).
3. Watch the server output for warnings—any event load failure logs `LifeEvents` warnings.
4. Optional: call `LifeEvents.getStats()` from the console to see event counts by category/stage.

---

## 10. Persistence (Optional)

- Hook into `Players.PlayerRemoving` or a periodic save loop.
- Grab the state: `local data = lifeState:Serialize()`.
- Store it in DataStore keyed by `player.UserId`.
- On join, call `LifeState.fromSerialized(player, data)` before replacing the default newborn state.

---

## 11. Deployment Checklist

- [ ] All required folders placed correctly (ServerScriptService/LifeServer, StarterPlayerScripts/LifeClient).
- [ ] No missing ModuleScripts when `LifeEvents` initializes.
- [ ] Remotes appear under `ReplicatedStorage/LifeRemotes` at runtime.
- [ ] Activities, careers, assets, crimes, relationships, and story paths tested end-to-end.
- [ ] Stage transitions + deaths display proper popups.
- [ ] (Optional) DataStore save/load verified.

---

## 12. Extending Beyond MVP

- Add more catalog packs (medical, celebrity, global crises, etc.).
- Build admin tooling to inspect `LifeState` live.
- Track analytics using `LifeEvents.getStats()` results (e.g., ensure each age bracket has enough content).
- Create seasonal folders by swapping `LifeEvents/Catalog` modules at runtime.

---

**Result:** from an empty place to a fully wired BitLife backend that keeps aging loops deterministic, respects age gates, and drives every UI screen through one server brain. Follow the steps in order and you’re done.