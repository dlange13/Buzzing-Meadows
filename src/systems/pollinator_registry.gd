## PollinatorRegistry — Autoload singleton managing all pollinator species data.
## Registered in project.godot as an autoload so it is always available.
## Holds the master list of all BeeSpeciesData resources, tracks which species
## the player has discovered, and handles in-world pollinator spawn logic.
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted the first time a species is discovered by the player.
signal species_discovered(species: BeeSpeciesData)
## Emitted when the player donates a species to the museum bestiary.
signal species_donated(species: BeeSpeciesData)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Master list of all BeeSpeciesData resources in the game.
## Populated during _ready() by loading all .tres files from the species directory.
var all_species: Array[BeeSpeciesData] = []

## Path to the directory containing BeeSpeciesData .tres resource files.
const SPECIES_DATA_DIR: String = "res://src/data/species/"

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	## Load all species data resources from disk on startup.
	## TODO: Implement directory scan and ResourceLoader calls once .tres files exist.
	_load_all_species()

# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------

## Load all BeeSpeciesData .tres files from SPECIES_DATA_DIR.
## Called once during _ready(). Populates all_species array.
func _load_all_species() -> void:
	## TODO: Use DirAccess to iterate SPECIES_DATA_DIR and load each .tres file.
	## For now, species are registered manually via register_species() during testing.
	pass

## Manually register a species (used during development and testing).
func register_species(species: BeeSpeciesData) -> void:
	if not all_species.has(species):
		all_species.append(species)

## Returns the BeeSpeciesData for a given common name, or null if not found.
func get_species_by_name(common_name: String) -> BeeSpeciesData:
	for species in all_species:
		if species.common_name == common_name:
			return species
	return null

## Returns all species that are currently discoverable given the active season
## and climate zone. Used by the spawn system to determine what can appear.
func get_discoverable_species(season_name: String, climate_zone: String) -> Array[BeeSpeciesData]:
	var result: Array[BeeSpeciesData] = []
	for species in all_species:
		if season_name in species.active_seasons and climate_zone in species.climate_zones:
			result.append(species)
	return result

## Returns all species the player has already discovered.
func get_discovered_species() -> Array[BeeSpeciesData]:
	var result: Array[BeeSpeciesData] = []
	for species in all_species:
		if species.discovered:
			result.append(species)
	return result

## Returns the number of discovered species (for museum progress display).
func get_discovery_count() -> int:
	var count: int = 0
	for species in all_species:
		if species.discovered:
			count += 1
	return count

# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

## Mark a species as discovered. Emits species_discovered if first encounter.
## Called by the world/garden system when a pollinator is seen by the player.
func discover_species(species: BeeSpeciesData) -> void:
	if species.discovered:
		return  # Already known; no signal needed
	species.discovered = true
	species_discovered.emit(species)

## Mark a species as donated to the museum bestiary.
## Donation unlocks the full educational fact card in the museum UI.
func donate_to_museum(species: BeeSpeciesData) -> void:
	## TODO: Track donation state separately from discovery state.
	species_donated.emit(species)

# ---------------------------------------------------------------------------
# Spawn Logic
# ---------------------------------------------------------------------------

## Attempt to spawn a random discoverable pollinator in the world.
## Returns a BeeSpeciesData to spawn, or null if nothing spawns this tick.
## Called once per in-game day by the world/garden system.
func roll_spawn(season_name: String, climate_zone: String) -> BeeSpeciesData:
	var candidates := get_discoverable_species(season_name, climate_zone)
	if candidates.is_empty():
		return null
	## Weight spawn chances by rarity:
	## Common = 60%, Uncommon = 25%, Rare = 10%, Seasonal = 5%
	## TODO: Implement weighted random selection. For MVP, uniform random.
	return candidates[randi() % candidates.size()]
