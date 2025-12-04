# BitLife-Style Game Backend

## 🎮 Overview

A comprehensive, AAA-quality backend for a BitLife-style life simulation game. Features **100+ careers** with **specific, non-random events**, deep trait systems, relationship dynamics, criminal enterprises, and long-term story paths.

## 📁 Structure

```
Server/
├── LifeServer.lua           # Main backend server
├── Data/
│   ├── CareerData.lua       # Main career module (combines all parts)
│   ├── CareerData_Part1.lua # Entry Level, Service, Food Industry careers
│   ├── CareerData_Part2.lua # Trades, Office, Technology careers
│   ├── CareerData_Part3.lua # Medical, Legal, Finance careers
│   ├── CareerData_Part4.lua # Creative, Entertainment, Government, Education careers
│   ├── CareerData_Part5.lua # Sports, Military, Criminal, Unique careers
│   ├── TraitData.lua        # 50+ personality traits with effects
│   ├── EventData.lua        # Age-based random life events
│   ├── ActivityData.lua     # Activities, crimes, prison actions
│   ├── AssetData.lua        # Properties, vehicles, items
│   └── StoryPathData.lua    # Long-term story progression paths
└── Systems/
    ├── PlayerStateManager.lua # Player state management
    └── EventEngine.lua        # Context-aware event selection
```

## 🎯 Key Features

### 100+ Careers with Specific Events

Each career has **unique events that ONLY happen in that job**:

- **Fast Food Worker**: Grease fires, Karen customers, secret shoppers, robberies
- **Surgeon**: Surgical complications, malpractice suits, shaky hands, OR emergencies  
- **Lawyer**: Courtroom showdowns, ethical dilemmas, partnership decisions
- **Drug Dealer**: Police raids, territory disputes, snitch situations
- **Professional Athlete**: Injuries, contract negotiations, championship games
- **Content Creator**: Viral moments, cancellation attempts, burnout, sponsors
- ...and 95+ more careers!

### Career Categories
- Entry Level & Service
- Food Industry & Retail
- Trades (Electrician, Plumber, Carpenter)
- Office & Administration
- Technology (Developer, IT Support, Sysadmin)
- Medical (Nurse, Doctor, Surgeon)
- Legal (Paralegal, Lawyer, Judge)
- Finance (Bank Teller, Analyst, Investment Banker)
- Creative (Designer, Writer, Musician)
- Entertainment (Actor, Content Creator)
- Government & Emergency Services
- Education (Teacher, Professor)
- Sports & Fitness
- Military
- Criminal (Drug Dealer, Hitman)
- Transportation & Aviation
- Real Estate

### Trait System (50+ Traits)

Traits affect gameplay, events, and outcomes:

**Personality**: Ambitious, Lazy, Brave, Coward, Rebellious, Obedient
**Intelligence**: Genius, Intelligent, Slow Learner
**Physical**: Athletic, Weak, Attractive, Ugly, Fertile
**Social**: Charismatic, Shy, Empathetic
**Mental**: Anxious, Calm, Depressed, Confident, Addictive Personality
**Moral**: Kind, Cruel, Honest, Liar, Psychopath
**Special**: Lucky, Unlucky, Famous, Royal Blood

### Context-Aware Event Engine

The EventEngine intelligently selects events based on:
- Current career and years in job
- Player traits and modifiers
- Age and life stage
- Relationship status
- Recent event history (no repeats)
- Performance and achievements

### Life Events by Age

**Childhood (0-12)**: Bullies, pets, hidden talents
**Teenage (13-17)**: First kiss, parties, driver's license, college decisions
**Young Adult (18-30)**: Moving out, career changes, relationships
**Adult (30-60)**: Major purchases, health concerns, family
**Senior (60+)**: Retirement, health issues, legacy

### Activity System

**Mind & Body**: Gym, meditation, yoga, martial arts, therapy, doctor
**Social**: Parties, bars, clubs, volunteering, dating, concerts
**Entertainment**: Movies, video games, reading, gambling, shopping, vacations

### Crime System

**Petty**: Shoplifting, pickpocketing
**Felony**: Burglary, car theft, robbery, drug dealing
**Violent**: Assault, murder
**White Collar**: Fraud, extortion

Each crime has:
- Skill-based success chance
- Reward ranges
- Sentences and fines
- Skill gains

### Prison System

Activities in prison:
- Exercise in yard
- Prison library
- Work details (reduce sentence)
- Start a riot (dangerous escape attempt)
- Escape attempts
- Good behavior (early release)
- Join prison gang

### Asset System

**Properties**: Studios to Private Islands
- Apartments, houses, mansions, penthouses, castles
- Beach houses, ski chalets
- Appreciation/depreciation
- Rental income

**Vehicles**: Used cars to Superyachts
- Economy, midrange, luxury, supercars
- Motorcycles, boats, aircraft
- Maintenance costs, insurance

**Items**: Jewelry, tech, pets, collectibles

### Story Paths

Long-term multi-stage storylines:
- **Political Career**: Local → State → National → President
- **Crime Empire**: Street level → Organized → Kingpin
- **Fame & Fortune**: Aspiring → Breakthrough → A-List
- **Business Tycoon**: Startup → Growth → Empire

## 🔌 Integration with Frontend

### Remote Functions
```lua
-- Career
GetAvailableJobs, ApplyForJob, QuitJob, DoWork, RequestPromotion, RequestRaise

-- Education  
EnrollEducation, GetEducationInfo

-- Activities
DoActivity, CommitCrime, DoPrisonAction

-- Assets
BuyProperty, BuyVehicle, BuyItem, SellAsset, Gamble

-- Relationships
DoInteraction

-- Story Paths
StartPath, DoPathAction

-- Core
RequestAgeUp, SubmitChoice, GetPlayerState, StartNewLife
```

### Remote Events
```lua
SyncState      -- Sync player state to client
PresentEvent   -- Present event popup to client
SetLifeInfo    -- Update life info display
MinigameStart  -- Start a minigame
MinigameResult -- Receive minigame result
```

## 💾 Data Persistence

Uses Roblox DataStoreService for:
- Auto-save every 60 seconds
- Save on player disconnect
- Full state serialization
- Generation tracking for inherited lives

## 🎲 Event Probability System

Events are scored and selected using weighted random selection:
1. Check critical/forced events (death, graduation)
2. Collect career-specific events
3. Collect education events if enrolled
4. Collect relationship events
5. Collect age-appropriate life events
6. Score each event based on context, traits, and recency
7. Select using weighted random

## 📊 Stats Tracked

- Total money earned/spent
- Crimes committed
- Time in prison
- Relationships had
- Children born
- Jobs held
- Degrees earned
- Net worth over time

## 🎨 BitLife Authenticity

This backend replicates key BitLife features:
- Age-by-age progression
- Specific career events (not random)
- Trait-based personality effects
- Family relationships that age and die
- Criminal paths with real consequences
- Education paths with GPA and debt
- Property and vehicle ownership
- Fame and prestige systems
- Legacy/inheritance system ready

## 🚀 Getting Started

1. Place the `Server` folder in `ServerScriptService`
2. The `LifeServer.lua` will automatically initialize
3. Frontend screens connect via `ReplicatedStorage.LifeRemotes`
4. Call `StartNewLife` to begin a new character

## 📝 License

Created for BitLife-style gameplay. Designed to work with Roblox UI frontend.
