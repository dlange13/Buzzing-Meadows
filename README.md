# 🐝 Buzzing Meadows

> *"A cozy pixel art beekeeping sim where real apiary knowledge is your greatest tool."*

[![Godot 4](https://img.shields.io/badge/Godot-4.x-blue?logo=godot-engine)](https://godotengine.org/)
[![GDScript](https://img.shields.io/badge/Language-GDScript-green)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## About

**Buzzing Meadows** (working title) is a cozy 2D pixel art beekeeping life
simulator built in Godot 4. Inspired by the warm pacing of *Animal Crossing* and
the apiary depth of *APICO*, it puts real beekeeping education at its core. Manage
your Langstroth hives through all four seasons, battle varroa mite infestations
with scientifically accurate treatment windows, discover native pollinator species
in your garden, craft hive products to sell at the farmer's market, and build
relationships with charming bee-themed NPC villagers.

This is not a simple honey-farming idle game. Buzzing Meadows teaches *actual*
apiary practices: mite load thresholds, brood inspection technique, seasonal colony
dynamics, and the ecological importance of wild pollinators.

---

## Tech Stack

| Component       | Details                                      |
|-----------------|----------------------------------------------|
| **Engine**      | Godot 4 (GDScript)                           |
| **Art Style**   | Pixel art, 320×180 base resolution (4× scale to 1280×720) |
| **Architecture**| Data-driven (Godot Resource files); autoload singletons |
| **Platform**    | PC (Windows / macOS / Linux); mobile planned |

---

## Getting Started

### Requirements
- [Godot Engine 4.x](https://godotengine.org/download) (standard edition)
- No additional plugins required for the MVP build

### Opening in Godot
1. Clone or download this repository.
2. Open **Godot 4**.
3. Click **Import** → navigate to the repository root → select `project.godot`.
4. Click **Import & Edit**.

The project will open with the autoload singletons (`GameManager`, `SeasonManager`,
`HiveManager`, `PollinatorRegistry`) already configured.

---

## Project Structure

```
/
├── project.godot          ← Godot 4 project config (pixel art, fixed viewport)
├── README.md
├── AGENTS.md              ← Copilot agent instructions (read on every task)
├── assets/
│   ├── sprites/           ← Pixel art sprites (bees, hives, world, ui)
│   ├── audio/             ← Music and SFX
│   └── fonts/
├── src/
│   ├── data/              ← GDScript Resource definitions (.gd + .tres files)
│   ├── systems/           ← Autoload singletons (GameManager, etc.)
│   ├── ui/                ← UI scenes and scripts
│   ├── world/             ← Tilemap, world gen, climate zones
│   └── entities/          ← Bee NPCs, hive objects
└── docs/
    ├── GAME_DESIGN.md     ← Full game design document
    ├── BEE_SPECIES.md     ← Pollinator species catalog
    ├── BEEKEEPING_CALENDAR.md ← Seasonal task calendar
    └── CLIMATE_ZONES.md   ← Climate zone documentation
```

---

## Documentation

| Document | Description |
|---|---|
| [GAME_DESIGN.md](docs/GAME_DESIGN.md) | Full game design document: core loop, hive types, varroa system, resource economy |
| [BEE_SPECIES.md](docs/BEE_SPECIES.md) | Pollinator species catalog with real biology |
| [BEEKEEPING_CALENDAR.md](docs/BEEKEEPING_CALENDAR.md) | Season-by-season task calendar |
| [CLIMATE_ZONES.md](docs/CLIMATE_ZONES.md) | Climate zone mechanics and variations |
| [AGENTS.md](AGENTS.md) | Copilot agent project identity and architecture rules |

---

## Beekeeping Accuracy

Buzzing Meadows is committed to scientifically accurate beekeeping mechanics.
Key systems are grounded in real apiary science:

- **Varroa mite system**: Modeled on peer-reviewed research showing exponential
  mite population growth during peak brood season and treatment efficacy data from
  the Honey Bee Health Coalition's *Varroa Management Guide*.
- **Seasonal calendar**: Based on real beekeeping practices for each represented
  climate zone, cross-referenced with University Extension apiculture programs
  (University of Wisconsin-Madison, Oregon State, NC State).
- **Treatment options**: All treatments (Oxalic Acid, Apivar, Apiguard, HopGuard)
  are modeled with their actual active ingredients, brood-free requirements, and
  realistic kill-rate percentages.

Educational fact cards in the museum are reviewed for scientific accuracy.

---

## Current Build Scope (v0.1 MVP)

- [x] Project scaffold and folder structure
- [x] Core GDScript Resource types (`HiveData`, `BeeSpeciesData`, etc.)
- [x] Autoload singletons (`GameManager`, `SeasonManager`, `HiveManager`, `PollinatorRegistry`)
- [ ] Hive inspection mini-game (frame viewer)
- [ ] Varroa treatment application UI
- [ ] Seasonal day-advance loop with events
- [ ] Garden with 3 plantable species
- [ ] Farmer's market honey selling
- [ ] First 5 discoverable pollinator species

---

## License

MIT License. See [LICENSE](LICENSE) for details.

Beekeeping educational content is based on publicly available apiary science.
Species data sourced from public-domain biological databases (ITIS, iNaturalist,
USGS Native Bee Monitoring Program).