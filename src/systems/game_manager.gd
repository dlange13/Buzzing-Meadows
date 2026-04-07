## GameManager — Autoload singleton for global game state.
## Registered in project.godot as an autoload so it is always available.
## Handles save/load, the global day counter, and core player data.
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted whenever the in-game day advances.
signal day_advanced(new_day: int)
## Emitted when a new save file is loaded or a new game starts.
signal game_loaded
## Emitted when the game is saved successfully.
signal game_saved

# ---------------------------------------------------------------------------
# Exported / Configurable
# ---------------------------------------------------------------------------

## Path where the save file is written.
const SAVE_FILE_PATH: String = "user://save_game.tres"

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Current in-game day (1-indexed). Day 1 = first day of Spring.
var current_day: int = 1
## Total in-game days elapsed since the start of the first year.
var total_days_elapsed: int = 0
## Player's display name (set during new game creation).
var player_name: String = "Keeper"
## Player's currency (honey coins).
var honey_coins: int = 0
## Whether a game is currently active (vs. on the main menu).
var game_active: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	## GameManager is an autoload; it initializes before any scene is loaded.
	pass

# ---------------------------------------------------------------------------
# Day Progression
# ---------------------------------------------------------------------------

## Advance the game by one day. Called by SeasonManager at end-of-day.
## Notifies all systems via the day_advanced signal.
func advance_day() -> void:
	current_day += 1
	total_days_elapsed += 1
	day_advanced.emit(current_day)

## Returns the current year (each year = 112 days: 4 seasons × 28 days).
func get_current_year() -> int:
	return (total_days_elapsed / 112) + 1

# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

## Save the current game state to disk using ResourceSaver.
## Serializes player data, all hive states, and season position into SaveData.
func save_game() -> void:
	var data := SaveData.new()
	data.player_name = player_name
	data.current_day = current_day
	data.total_days_elapsed = total_days_elapsed
	data.honey_coins = honey_coins
	data.current_season_index = SeasonManager.current_season_index
	data.day_in_season = SeasonManager.day_in_season
	data.hives = HiveManager.get_hives_for_save()
	var err := ResourceSaver.save(data, SAVE_FILE_PATH)
	if err != OK:
		push_error("GameManager: Failed to save game — %s" % error_string(err))
		return
	game_saved.emit()

## Load a saved game from disk. Returns false if no save file exists or load fails.
## Restores all player data, season position, and hive states.
func load_game() -> bool:
	if not ResourceLoader.exists(SAVE_FILE_PATH):
		return false
	var data := ResourceLoader.load(SAVE_FILE_PATH) as SaveData
	if data == null:
		push_error("GameManager: Save file exists but could not be loaded as SaveData.")
		return false
	player_name = data.player_name
	current_day = data.current_day
	total_days_elapsed = data.total_days_elapsed
	honey_coins = data.honey_coins
	SeasonManager.current_season_index = data.current_season_index
	SeasonManager.day_in_season = data.day_in_season
	HiveManager.restore_from_save(data.hives)
	game_active = true
	game_loaded.emit()
	return true

## Start a fresh new game with default values.
func new_game(p_player_name: String) -> void:
	player_name = p_player_name
	current_day = 1
	total_days_elapsed = 0
	honey_coins = 50  # Starting budget
	game_active = true
	game_loaded.emit()

# ---------------------------------------------------------------------------
# Economy
# ---------------------------------------------------------------------------

## Add honey_coins to the player's wallet. Use positive values only.
func earn_coins(amount: int) -> void:
	honey_coins += amount

## Spend honey_coins. Returns false if the player cannot afford it.
func spend_coins(amount: int) -> bool:
	if honey_coins < amount:
		return false
	honey_coins -= amount
	return true
