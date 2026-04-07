# AGENTS.md – Buzzing Meadows

## Project Identity
A cozy 2D pixel art beekeeping and pollinator life sim. Godot 4, GDScript.
Tone: warm, educational, charming. Like Animal Crossing but you're a beekeeper.

## Game Design Pillars
1. Real beekeeping mechanics (not just honey farming)
2. Pollinator discovery and conservation education
3. Seasonal and climate-based strategy
4. Cozy low-stress progression loop

## Architecture Rules
- All game data lives in Resource files under /src/data/
- Global state managed by autoload singletons in /src/systems/
- No hardcoded magic numbers — use exported constants or config Resources
- Each system gets its own .gd file; no monolithic scripts

## Naming Conventions
- Files: snake_case.gd / snake_case.tscn
- Classes: PascalCase (class_name BeeSpeciesData)
- Signals: past tense verb (hive_inspected, queen_replaced, mite_treated)

## Current Build Scope (v0.1 MVP)
- One climate zone (Temperate Midwest — Wisconsin)
- One hive type (Langstroth)
- Honeybee colony only
- Core inspection loop: open hive, view frame, detect varroa, treat
- Seasonal calendar with 4 seasons, real beekeeping tasks per season

## Do Not (in this phase)
- No multiplayer
- No procedural world generation yet
- No bee genetics system yet (planned for v0.3)
