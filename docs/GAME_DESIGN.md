# Game Design Document — Buzzing Meadows

**Version:** 0.1 (MVP Scope)  
**Engine:** Godot 4, GDScript  
**Resolution:** 320×180 (scaled 4× to 1280×720)

---

## Game Summary

**Buzzing Meadows** is a cozy 2D pixel art beekeeping life simulator inspired by
Animal Crossing's warm pacing and APICO's apiary mechanics. The player manages
real beehives through all four seasons, treats varroa mite infestations, discovers
native pollinator species, crafts hive products, and builds relationships with
charming bee-themed NPC villagers.

Unlike simple honey-farming games, Buzzing Meadows teaches *real* beekeeping
practices: mite treatment timing, seasonal colony dynamics, hive inspections, and
the ecological importance of wild pollinators.

---

## Core Loop

```
Inspect Hive → Identify Issue → Gather Resources → Treat / Improve
       ↑                                                    ↓
Wait for Seasonal Events ←────────────────────── Upgrade Apiary
```

1. **Inspect** — Open hive, examine frames, check brood pattern, mite wash count
2. **Identify** — High varroa load? Low honey stores? Queenless? Defensive colony?
3. **Gather** — Harvest honey, forage plants, buy treatments from the bee supply NPC
4. **Treat / Improve** — Apply varroa treatment, add supers, requeen, feed syrup
5. **Wait** — Advance days/seasons; random events fire (swarm, robbing, pesticide kill)
6. **Repeat** — New season brings new challenges and opportunities

---

## Hive Types (Planned)

| Hive Type      | Pros                              | Cons                                      | Unlock       |
|----------------|-----------------------------------|-------------------------------------------|--------------|
| **Langstroth** | Standard; easiest to inspect      | Heavy boxes; lots of equipment            | Starting hive|
| **Top Bar**    | Low cost; natural comb             | Harder to inspect; no super stacking      | Year 2       |
| **Warré**      | Low intervention; natural cluster  | Difficult varroa management               | Year 2       |
| **Flow Hive**  | Honey harvest without disturbance  | Expensive; limits brood inspection habit  | Year 3       |

---

## Varroa Mite System

Varroa destructor is the most serious threat to managed honeybee colonies worldwide.
The game models this accurately because understanding varroa is central to real
beekeeping education.

### Biology
- Varroa mites reproduce inside **capped brood cells** — one mite enters a cell
  before capping and lays eggs on the developing pupa.
- Population roughly **doubles every 4–5 weeks** during peak brood-rearing season
  (late spring through early fall).
- When the mite-to-bee ratio exceeds **3% (3 mites per 100 bees)**, colony health
  degrades rapidly. Above 5% is critical.

### In-Game Mite Mechanics
- `varroa_mite_load` on `HiveData` is tracked as mites per 100 bees (%).
- Each game day, mite load increases by `SeasonConfig.varroa_growth_multiplier`.
- Consequences of high mite load:
  - `brood_health` degrades → lower bee population
  - Winter survival chance drops sharply above 3% load
  - Colony collapse event triggers if load exceeds 8% unchecked

### Treatment Options

| Treatment         | Active Ingredient | Brood-Free Required | Honey Supers Safe | Duration  | Kill Rate |
|-------------------|-------------------|---------------------|-------------------|-----------|-----------|
| **Oxalic Acid**   | Oxalic acid       | Yes                 | No                | 1 dose    | ~97% phoretic mites |
| **Apivar**        | Amitraz           | No                  | No                | 42–56 days| ~90%      |
| **Apiguard**      | Thymol            | No                  | No                | 28 days   | ~74%      |
| **HopGuard**      | Hop beta acids    | No                  | Yes               | 30 days   | ~65%      |

**Key timing:** In the Temperate Midwest (Wisconsin), treat by **August 15** to
protect the winter bees raised in late August/September. These are the bees that
must survive 5–6 months of winter.

---

## Climate Zones (Planned)

| Zone                    | Key Challenges                              | Unlock   |
|-------------------------|---------------------------------------------|----------|
| **Temperate Midwest**   | Short nectar flow; hard winters; varroa windows | Starting |
| **Pacific Northwest**   | Wet springs; strong summer flow; SHB risk   | Year 2   |
| **Desert Southwest**    | Heat stress; Africanized bee risk; short winters | Year 2 |
| **Southeastern US**     | Small hive beetles; humidity; long season   | Year 3   |
| **Northern Europe**     | Very short season; long cold winters        | Year 3   |

---

## Seasonal Calendar

### 🌸 Spring (Days 1–28)
**Colony State:** Rapid buildup; queen laying at maximum; swarm pressure builds.  
**Player Tasks:**
- First inspection of the year; assess winter losses
- Add honey supers as nectar flow begins
- Monitor for swarm cells; split hives to prevent swarming
- Begin varroa monitoring (alcohol wash or sticky board count)

**Random Events:** Swarm departure, late frost (kills early foragers), dandelion bloom

### ☀️ Summer (Days 29–56)
**Colony State:** Peak population (50,000–80,000 bees); main nectar flow.  
**Player Tasks:**
- Harvest honey from full supers
- Monitor varroa load — begins exponential rise with maximum brood
- Watch for signs of queenlessness or laying workers

**Random Events:** Pesticide event (nearby farm sprays), robbing by other colonies,
nectar dearth (no flow → aggressive bees), yellow jacket pressure

### 🍂 Fall (Days 57–84)
**Colony State:** Population declining; mite load at annual peak; prep for winter.  
**Player Tasks:**
- **Critical:** Varroa treatment window (Apivar or Apiguard before brood tapers off)
- Remove honey supers before treatment (if using Apivar/Apiguard)
- Feed 2:1 sugar syrup to build winter stores
- Reduce entrance to prevent robbing and mouse entry

**Random Events:** Hive robbery event, queen failure, small hive beetle pressure

### ❄️ Winter (Days 85–112)
**Colony State:** Winter cluster; no brood (or very little); living on stored honey.  
**Player Tasks:**
- Oxalic acid dribble treatment (most effective brood-free window)
- Monitor for starvation (heft test: light hive = low stores → emergency feed)
- Check for moisture / condensation issues (add ventilation)
- Plan next year: order new queens, equipment, plant pollinator garden

**Random Events:** Starvation event (if stores < threshold), warm spell (bees fly and
deplete stores), ice storm blocks entrance

---

## Pollinator Bestiary

See `/docs/BEE_SPECIES.md` for full species documentation.

Featured pollinators discoverable in-game:
- Western Honeybee (*Apis mellifera*)
- Common Eastern Bumblebee (*Bombus impatiens*)
- Blue Orchard Mason Bee (*Osmia lignaria*)
- Alfalfa Leafcutter Bee (*Megachile rotundata*)
- Ligated Sweat Bee (*Halictus rubicundus*)
- Squash Bee (*Peponapis pruinosa*)
- Eastern Carpenter Bee (*Xylocopa virginica*)
- Monarch Butterfly (*Danaus plexippus*)
- Painted Lady Butterfly (*Vanessa cardui*)
- Hoverfly (*Syrphidae* family)

---

## Resource Economy

### Primary Resources (harvested from hives)
| Resource      | Source                  | Use                               |
|---------------|-------------------------|-----------------------------------|
| Honey         | Honey supers            | Sell, craft mead, bake, gift NPCs |
| Beeswax       | Cappings / comb         | Craft candles, lip balm, wrap      |
| Propolis      | Hive scrapings          | Craft tinctures, wood finish       |
| Royal Jelly   | Queen cells             | Rare; sell high or gift for quests |
| Pollen        | Pollen traps            | Supplement feed, sell to gardener  |

### Crafted Products (Farmer's Market)
| Product        | Ingredients              | Market Value |
|----------------|--------------------------|--------------|
| Beeswax Candle | Beeswax × 3              | $$           |
| Lip Balm       | Beeswax × 1, Honey × 1   | $$           |
| Honey Mead     | Honey × 5, time          | $$$          |
| Propolis Soap  | Propolis × 2, Beeswax × 1| $$           |
| Creamed Honey  | Honey × 4                | $$$          |

---

## NPC Bee Characters

NPC villagers are anthropomorphized bee and pollinator characters with personalities.
They give quests, share tips, and provide lore — Animal Crossing style.

| Name      | Species          | Personality | Role                            |
|-----------|------------------|-------------|----------------------------------|
| **Mabel** | Queen Honeybee   | Wise, calm  | Mentor; teaches inspection basics|
| **Buzz**  | Drone Bee        | Lazy, funny | Comic relief; lazy quest-giver   |
| **Cora**  | Bumblebee        | Energetic   | Gardening quests; plant unlocks  |
| **Marisol**| Mason Bee       | Shy, precise| Museum donations; accuracy lore  |
| **Otto**  | Carpenter Bee    | Gruff, kind | Woodworking; hive box crafting   |
| **Finn**  | Hoverfly         | Trickster   | Mistaken-identity jokes; ecology |

---

## Museum / Bestiary

Inspired by Animal Crossing's museum, players donate specimen samples to unlock:
- **Fact Cards**: Real educational content about each species
- **Habitat Dioramas**: Pixel art scenes of species' natural habitats
- **Conservation Status**: Real IUCN/NatureServe status for each species
- **Achievements**: "Apiarist" (full honeybee data), "Wildflower Watcher" (all
  native bees discovered)

Donating to the museum unlocks new dialog options with NPCs who reference facts
the player has learned.
