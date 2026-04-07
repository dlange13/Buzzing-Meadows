# GitHub Copilot Instructions — Buzzing Meadows

## Language & Engine
- This is a **Godot 4 GDScript** project. Always use **GDScript** (not C#).
- All scripts target Godot 4.x API. Do not use deprecated Godot 3 API calls.

## Design Pattern
- Follow a **data-driven design** pattern: game entities are defined as Godot
  `Resource` subclasses loaded from `.tres` files under `/src/data/`.
- Use **autoload singletons** for global managers: `GameManager`, `SeasonManager`,
  `HiveManager`, `PollinatorRegistry`.
- Prefer **composition over inheritance** for entity behavior.
- No hardcoded magic numbers — use exported constants or config Resources.

## Naming Conventions
- All node names use **PascalCase**.
- All variables and functions use **snake_case**.
- Files: `snake_case.gd` / `snake_case.tscn`
- Classes: PascalCase with `class_name` (e.g., `class_name BeeSpeciesData`)
- Signals: past tense verb (e.g., `hive_inspected`, `queen_replaced`, `mite_treated`)

## Code Comments
- This is a **cozy, educational game**. Code comments should explain beekeeping
  concepts where relevant.
- Examples:
  - Explain *why* varroa mite load doubles every 4–5 weeks (reproductive cycle in capped brood).
  - Note treatment window mechanics (Oxalic Acid only works brood-free).
  - Document seasonal calendar logic (winter cluster survival thresholds, etc.).

## Pixel Art Rendering
- Always set `texture_filter = TEXTURE_FILTER_NEAREST` on sprites. **Never** use
  antialiasing on pixel art assets.
- Target resolution: **320×180** (scaled up 4× to 1280×720). Use a fixed viewport.
- Viewport stretch mode: `canvas_items` with `keep` aspect ratio.

## UI Guidelines
- Use Godot's `Control` nodes for all UI elements.
- Match the warm, earthy color palette:
  - Honey Gold: `#F5A623`
  - Forest Green: `#4A7C59`
  - Cream: `#FFF8E7`
  - Soft Brown: `#8B6914`
  - Dark Bark: `#3E2B1A`

## Architecture
- All game data lives in Resource files under `/src/data/`
- Global state managed by autoload singletons in `/src/systems/`
- Each system gets its own `.gd` file; no monolithic scripts
- Scene structure: `/src/ui/` for menus, `/src/world/` for tilemap/worldgen,
  `/src/entities/` for bees, NPCs, hive objects

## Current Build Scope (v0.1 MVP)
- One climate zone (Temperate Midwest — Wisconsin)
- One hive type (Langstroth)
- Honeybee colony only
- Core inspection loop: open hive → view frame → detect varroa → treat
- Seasonal calendar with 4 seasons, real beekeeping tasks per season
