## SeasonManager — Autoload singleton for season and calendar logic.
## Registered in project.godot as an autoload so it is always available.
## Tracks the current season, day within the season, triggers seasonal events,
## and advances the in-game day in coordination with GameManager.
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when the season changes (e.g., Spring → Summer).
signal season_changed(new_season: SeasonConfig)
## Emitted when a random seasonal event fires.
signal seasonal_event_triggered(event_id: String)
## Emitted at the end of each in-game day after all daily ticks complete.
signal end_of_day

# ---------------------------------------------------------------------------
# Season Data
# ---------------------------------------------------------------------------

## Ordered list of SeasonConfig resources for the active climate zone.
## Set during game initialization by loading the appropriate .tres files.
var seasons: Array[SeasonConfig] = []
## Index into the seasons array for the currently active season.
var current_season_index: int = 0
## Day within the current season (1-indexed).
var day_in_season: int = 1

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	## SeasonManager loads default (Temperate Midwest) season configs on startup.
	## TODO: Load SeasonConfig .tres files from res://src/data/seasons/
	pass

# ---------------------------------------------------------------------------
# Accessors
# ---------------------------------------------------------------------------

## Returns the currently active SeasonConfig resource, or null if not loaded.
func get_current_season() -> SeasonConfig:
	if seasons.is_empty():
		return null
	return seasons[current_season_index]

## Returns the season name as a String (e.g., "Spring").
func get_season_name() -> String:
	var season := get_current_season()
	if season == null:
		return "Unknown"
	return season.season_name

## True if the current season has an active nectar flow.
func is_nectar_flow_active() -> bool:
	var season := get_current_season()
	if season == null:
		return false
	return season.nectar_flow_active

## Returns the varroa growth multiplier for the current season.
## Used by HiveManager to scale daily mite reproduction.
func get_varroa_multiplier() -> float:
	var season := get_current_season()
	if season == null:
		return 1.0
	return season.varroa_growth_multiplier

# ---------------------------------------------------------------------------
# Day Advancement
# ---------------------------------------------------------------------------

## Advance one in-game day. Called once per player day-end action.
## Fires end_of_day, advances GameManager, rolls for random events,
## and advances the season if the season duration has elapsed.
func advance_day() -> void:
	# Trigger daily hive simulation before advancing the calendar
	HiveManager.simulate_daily_tick()

	day_in_season += 1
	GameManager.advance_day()

	# Check if the current season is over
	var season := get_current_season()
	if season != null and day_in_season > season.days_duration:
		_advance_season()

	# Roll for random seasonal events
	_roll_for_events()

	end_of_day.emit()

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

## Advance to the next season, wrapping around after Winter back to Spring.
func _advance_season() -> void:
	if seasons.is_empty():
		return
	day_in_season = 1
	current_season_index = (current_season_index + 1) % seasons.size()
	season_changed.emit(get_current_season())

## Roll dice for random events defined in the current SeasonConfig.
## Each event in possible_events has an equal chance of firing (simplified for MVP).
func _roll_for_events() -> void:
	var season := get_current_season()
	if season == null or season.possible_events.is_empty():
		return
	## TODO: Implement probability table per event; for MVP each event has ~5% daily chance.
	for event_id in season.possible_events:
		if randf() < 0.05:
			seasonal_event_triggered.emit(event_id)
			break  # Only one event per day (MVP constraint)
