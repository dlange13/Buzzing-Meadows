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
	## Build the default Temperate Midwest (Wisconsin) season configs at startup.
	## These configs drive varroa growth, honey production, and population dynamics.
	## Climate-specific .tres configs will replace these in future zones.
	_load_temperate_midwest_seasons()

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
	HiveManager.tick_all_hives()

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
## Each event in possible_events has a 5% chance of firing per day (MVP).
func _roll_for_events() -> void:
	var season := get_current_season()
	if season == null or season.possible_events.is_empty():
		return
	for event_id in season.possible_events:
		if randf() < 0.05:
			seasonal_event_triggered.emit(event_id)
			break  # Only one event per day (MVP constraint)

## Build Temperate Midwest (Wisconsin) season configs programmatically.
## These values are calibrated to real beekeeping practice for the Upper Midwest.
## Varroa multipliers: summer peaks at 1.8× (max brood), winter near-zero.
## Population multipliers: spring buildup, summer stable, fall/winter decline.
func _load_temperate_midwest_seasons() -> void:
	var spring := SeasonConfig.new()
	spring.season_name = "Spring"
	spring.days_duration = 28
	spring.nectar_flow_active = true
	spring.nectar_flow_intensity = 0.6   # Flow building; colony still expanding
	spring.varroa_growth_multiplier = 1.2
	spring.population_growth_multiplier = 1.5  # Rapid spring buildup
	spring.recommended_tasks = [
		"Perform first spring inspection",
		"Check honey stores and feed if below 10 kg",
		"Add honey supers when dandelion blooms",
		"Monitor for swarm cells after day 14",
		"Assess varroa load (alcohol wash)"
	]
	spring.possible_events = ["late_frost", "dandelion_bloom", "swarm", "early_clover_bloom"]

	var summer := SeasonConfig.new()
	summer.season_name = "Summer"
	summer.days_duration = 28
	summer.nectar_flow_active = true
	summer.nectar_flow_intensity = 1.0   # Peak nectar flow — white clover, basswood
	summer.varroa_growth_multiplier = 1.8  # Maximum brood = maximum mite reproduction
	summer.population_growth_multiplier = 1.0  # Peak population; stable
	summer.recommended_tasks = [
		"Harvest honey from full supers",
		"Monitor varroa load monthly (target <2%)",
		"Watch for nectar dearth in August",
		"Plan fall varroa treatment before August 15"
	]
	summer.possible_events = ["basswood_bloom", "nectar_dearth", "pesticide_event",
			"robbing_attempt", "heat_wave", "queen_supersedure"]

	var fall := SeasonConfig.new()
	fall.season_name = "Fall"
	fall.days_duration = 28
	fall.nectar_flow_active = false
	fall.nectar_flow_intensity = 0.0
	fall.varroa_growth_multiplier = 0.7  # Brood tapering off after summer peak
	fall.population_growth_multiplier = 0.5  # Colony contracting toward winter cluster
	fall.recommended_tasks = [
		"CRITICAL: Apply varroa treatment by day 8 (Aug 15 equivalent)",
		"Remove honey supers before treatment if using Apivar or Apiguard",
		"Feed 2:1 sugar syrup to build winter stores",
		"Reduce entrance to prevent robbing and mouse entry",
		"Install mouse guards"
	]
	fall.possible_events = ["goldenrod_bloom", "mouse_invasion", "varroa_critical_event",
			"yellowjacket_robbing", "queen_failure"]

	var winter := SeasonConfig.new()
	winter.season_name = "Winter"
	winter.days_duration = 28
	winter.nectar_flow_active = false
	winter.nectar_flow_intensity = 0.0
	# Winter: no brood = no mite reproduction; mites survive only phoretically
	winter.varroa_growth_multiplier = 0.05
	winter.population_growth_multiplier = 0.1  # Cluster; minimal emergence
	winter.recommended_tasks = [
		"Apply Oxalic Acid (brood-free window — most effective treatment)",
		"Heft test: lift hive corner to check honey weight",
		"Add candy board if stores feel light",
		"Ensure upper ventilation to prevent condensation",
		"Plan spring: order queens, nucs, equipment"
	]
	winter.possible_events = ["starvation_event", "warm_spell", "ice_storm",
			"winter_survival", "dampness_event"]

	seasons = [spring, summer, fall, winter]
