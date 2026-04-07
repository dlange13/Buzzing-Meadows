## HiveManager — Autoload singleton managing all player-owned hives.
## Registered in project.godot as an autoload so it is always available.
## Responsible for the daily simulation tick (mite growth, honey production,
## population dynamics) and for driving the inspection gameplay loop.
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted after a hive is successfully inspected by the player.
signal hive_inspected(hive: HiveData)
## Emitted when a new hive is added to the player's apiary.
signal hive_added(hive: HiveData)
## Emitted when a hive collapses (population reaches 0 or mite load critical).
signal hive_collapsed(hive: HiveData)
## Emitted when varroa load crosses the critical threshold (3%).
signal varroa_critical(hive: HiveData)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Varroa load percentage at which the game warns the player.
const VARROA_WARNING_THRESHOLD: float = 2.0
## Varroa load percentage at which colony health degrades rapidly.
const VARROA_CRITICAL_THRESHOLD: float = 3.0
## Varroa load percentage that triggers colony collapse if untreated.
const VARROA_COLLAPSE_THRESHOLD: float = 8.0
## Reference population size used to normalize honey production calculations.
## Represents a full-strength summer colony.
const REFERENCE_POPULATION: float = 50000.0
## Daily honey production factor per reference-population bee.
## Scaled by actual population and brood health during nectar flow.
const DAILY_PRODUCTION_FACTOR: float = 0.05
## Expected daily bee emergence from healthy brood in a full-strength colony.
const DAILY_BEE_EMERGENCE_RATE: float = 1500.0
## Fraction of adult bees that die per day under normal conditions (~0.7% daily).
## A summer forager lifespan is roughly 6 weeks (42 days), so 1/42 ≈ 2.4% per day;
## this lower value accounts for younger house bees and nurse bees with longer lives.
const DAILY_MORTALITY_RATE: float = 0.007
## Base daily varroa growth rate (mites per 100 bees, per day).
## Actual growth is multiplied by SeasonManager.get_varroa_multiplier().
## Varroa reproduces inside capped brood — one reproductive cycle per ~10 days
## in summer, meaning the population roughly doubles every 4–5 weeks.
const BASE_VARROA_DAILY_GROWTH: float = 0.05

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## All hives currently owned by the player.
## Each element is a HiveData resource.
var hives: Array[HiveData] = []

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	## HiveManager starts empty; hives are added via add_hive() or loaded from save.
	pass

# ---------------------------------------------------------------------------
# Hive Management
# ---------------------------------------------------------------------------

## Add a new hive to the player's apiary.
func add_hive(hive: HiveData) -> void:
	hives.append(hive)
	hive_added.emit(hive)

## Remove a hive from the player's apiary (e.g., after collapse or sale).
func remove_hive(hive: HiveData) -> void:
	hives.erase(hive)

## Returns the hive at the given index, or null if out of range.
func get_hive(index: int) -> HiveData:
	if index < 0 or index >= hives.size():
		return null
	return hives[index]

# ---------------------------------------------------------------------------
# Daily Simulation Tick
# ---------------------------------------------------------------------------

## Called once per in-game day by SeasonManager before end_of_day fires.
## Updates all hives: mite growth, honey production, population change.
func simulate_daily_tick() -> void:
	for hive in hives:
		_tick_varroa(hive)
		_tick_honey_production(hive)
		_tick_population(hive)

## Simulate varroa mite population growth for one day.
## Mite load grows faster in summer (high brood) and nearly stops in winter
## (no brood = no mite reproduction; only phoretic mites survive on adult bees).
func _tick_varroa(hive: HiveData) -> void:
	if not hive.queen_present:
		# No queen → no brood → mites can only reproduce on existing adults
		hive.varroa_mite_load += BASE_VARROA_DAILY_GROWTH * 0.1
	else:
		var multiplier := SeasonManager.get_varroa_multiplier()
		hive.varroa_mite_load += BASE_VARROA_DAILY_GROWTH * multiplier

	# Clamp to prevent negative (shouldn't happen, but defensive)
	hive.varroa_mite_load = maxf(0.0, hive.varroa_mite_load)

	# Emit signals at critical thresholds
	if hive.varroa_mite_load >= VARROA_CRITICAL_THRESHOLD:
		varroa_critical.emit(hive)
		# Degrade brood health when mites are critical
		hive.brood_health -= 0.01

	# Colony collapse if load is catastrophic and untreated
	if hive.varroa_mite_load >= VARROA_COLLAPSE_THRESHOLD:
		_trigger_collapse(hive)

## Simulate honey production for one day.
## Only produces honey during active nectar flow and when queen/bees are healthy.
func _tick_honey_production(hive: HiveData) -> void:
	if not SeasonManager.is_nectar_flow_active():
		return
	# Production scales with population and brood health
	var daily_kg: float = (float(hive.population) / REFERENCE_POPULATION) * hive.brood_health * DAILY_PRODUCTION_FACTOR
	hive.honey_stores_kg += daily_kg

## Simulate population change for one day.
## Population grows with a healthy queen and healthy brood, declines otherwise.
func _tick_population(hive: HiveData) -> void:
	if not hive.queen_present:
		# Queenless: population declines as bees die with no replacements
		hive.population -= int(hive.population * 0.01)
		return

	# Net daily population change: new bees emerge minus daily bee deaths
	# A healthy summer colony has roughly 1,500 bees emerging per day
	var daily_emergence: int = int(DAILY_BEE_EMERGENCE_RATE * hive.brood_health)
	var daily_deaths: int = int(float(hive.population) * DAILY_MORTALITY_RATE)  # ~0.7% daily mortality
	hive.population = max(0, hive.population + daily_emergence - daily_deaths)

	if hive.population == 0:
		_trigger_collapse(hive)

# ---------------------------------------------------------------------------
# Inspection
# ---------------------------------------------------------------------------

## Mark a hive as inspected on the current day.
## The player must call this after completing a hive inspection interaction.
func inspect_hive(hive: HiveData) -> void:
	hive.last_inspected_day = GameManager.current_day
	hive_inspected.emit(hive)

# ---------------------------------------------------------------------------
# Treatment
# ---------------------------------------------------------------------------

## Apply a varroa treatment to a hive.
## Reduces mite load based on TreatmentData.effectiveness.
## Does nothing if treatment requires brood-free hive but brood is present.
func apply_treatment(hive: HiveData, treatment: TreatmentData) -> bool:
	## TODO: Track treatment duration; apply mite reduction over time rather than instantly.
	## For MVP, apply immediate reduction.
	if treatment.requires_brood_free and hive.queen_present and hive.brood_health > 0.1:
		# Brood is present; treatment will be less effective
		# Oxalic acid, for example, cannot reach mites in capped brood cells
		hive.varroa_mite_load *= (1.0 - treatment.effectiveness * 0.3)
		return false  # Partial application; warn player
	hive.varroa_mite_load *= (1.0 - treatment.effectiveness)
	hive.varroa_mite_load = maxf(0.0, hive.varroa_mite_load)
	return true

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _trigger_collapse(hive: HiveData) -> void:
	hive.population = 0
	hive.brood_health = 0.0
	hive.queen_present = false
	hive_collapsed.emit(hive)
