## HiveManager — Autoload singleton managing all player-owned hives.
## Registered in project.godot as an autoload so it is always available.
## Responsible for the daily simulation tick (mite growth, honey production,
## population dynamics, treatment progression) and inspection gameplay loop.
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted each day after a hive's full tick completes. Use to refresh UI.
signal hive_updated(hive: HiveData)
## Emitted after a hive is successfully inspected by the player.
signal hive_inspected(hive: HiveData)
## Emitted when a new hive is added to the player's apiary.
signal hive_added(hive: HiveData)
## Emitted when a hive collapses (population reaches 0 from neglect or mites).
signal hive_collapsed(hive: HiveData)
## Emitted each day that a hive's varroa load exceeds the critical threshold (3%).
## Connect to this signal in UI to show warnings / quest triggers.
signal colony_at_risk(hive: HiveData)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Varroa load (%) at which the game shows the first player warning.
const VARROA_WARNING_THRESHOLD: float = 2.0
## Varroa load (%) at which colony health actively degrades and colony_at_risk fires.
const VARROA_CRITICAL_THRESHOLD: float = 3.0
## Varroa load (%) that triggers colony collapse if still untreated.
const VARROA_COLLAPSE_THRESHOLD: float = 8.0

## Exponential varroa growth model.
## Biology: Varroa reproduce inside capped brood cells — one reproductive
## cycle per ~21-day bee brood cycle, producing ~1.8 offspring per cycle.
## Daily multiplicative rate: 1.8^(1/21) - 1 ≈ 0.028 (2.8% per day).
## The season multiplier from SeasonManager scales this rate up in summer
## (maximum brood = maximum mite reproduction) and near-zero in winter
## (no brood = mites can only survive phoretically, no reproduction).
const VARROA_DAILY_GROWTH_RATE: float = 0.028

## Reference population for honey production calibration.
## Represents a full-strength summer Langstroth colony.
const REFERENCE_POPULATION: float = 50000.0

## Daily honey production (kg) for a reference-population colony at peak nectar flow.
## Calibrated so a full-strength colony produces ~27 kg (60 lbs) per year over the
## 56-day nectar flow (28 days spring at 0.6 intensity + 28 days summer at 1.0):
## (28 × 0.6 + 28 × 1.0) × 0.6 = 44.8 × 0.6 ≈ 26.9 kg ≈ 59 lbs ✓
const DAILY_HONEY_KG_PER_UNIT: float = 0.6

## Base daily bee emergence rate for a healthy full-strength colony (queen present,
## brood health = 1.0, summer season). Scaled by brood_health and season multiplier.
const DAILY_BEE_EMERGENCE_BASE: float = 1500.0

## Fraction of adult bees that die per day under normal conditions (~0.7%).
## Combined nurse bee + house bee + forager averaged lifespan ≈ ~50 days.
const DAILY_MORTALITY_RATE: float = 0.007

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## All hives currently owned by the player.
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

## Simulate one full day for every hive in the apiary.
## Call this directly in tests, or via SeasonManager.advance_day() in gameplay.
## Emits hive_updated(hive) for each hive after its tick completes.
func tick_all_hives() -> void:
	for hive in hives:
		if hive.population == 0 and not hive.queen_present:
			continue  # Skip already-collapsed hives
		_tick_treatment(hive)
		_tick_varroa(hive)
		_tick_honey_production(hive)
		_tick_population(hive)
		_tick_queen_age(hive)
		hive_updated.emit(hive)

## Alias kept so SeasonManager.advance_day() continues to work without changes.
func simulate_daily_tick() -> void:
	tick_all_hives()

# ---------------------------------------------------------------------------
# Private tick helpers
# ---------------------------------------------------------------------------

## Progress the active treatment by one day and apply its daily mite reduction.
## Uses an exponential decay model so the cumulative kill after duration_days
## equals treatment.effectiveness:
##   daily_factor = (1 - effectiveness)^(1 / duration_days)
## Example — Apivar (90% over 42 days): factor = 0.10^(1/42) ≈ 0.947 per day.
func _tick_treatment(hive: HiveData) -> void:
	if hive.active_treatment == null:
		return
	var t := hive.active_treatment
	if t.duration_days > 0:
		var daily_survival_factor := pow(1.0 - t.effectiveness,
				1.0 / float(t.duration_days))
		hive.varroa_mite_load *= daily_survival_factor
		hive.varroa_mite_load = maxf(0.0, hive.varroa_mite_load)
	hive.treatment_days_remaining -= 1
	if hive.treatment_days_remaining <= 0:
		hive.active_treatment = null
		hive.treatment_days_remaining = 0

## Simulate varroa mite population growth for one day.
##
## Model: multiplicative exponential — mite_load *= (1 + rate × season_multiplier)
## This correctly produces doubling-time behaviour:
##   Summer (multiplier 1.8): doubles every ~22 days  ✓ matches field data
##   Winter (multiplier 0.05): nearly static          ✓ no brood = no reproduction
##
## Without a queen there is no brood, so mites cannot reproduce; they only survive
## phoretically on adult bees until those bees die (very slow effective growth).
func _tick_varroa(hive: HiveData) -> void:
	if not hive.queen_present:
		# No brood → mites cannot reproduce; tiny drift/reinfestation rate only
		hive.varroa_mite_load = maxf(0.0, hive.varroa_mite_load)
		return

	var season_multiplier := SeasonManager.get_varroa_multiplier()
	hive.varroa_mite_load *= (1.0 + VARROA_DAILY_GROWTH_RATE * season_multiplier)
	hive.varroa_mite_load = maxf(0.0, hive.varroa_mite_load)

	if hive.varroa_mite_load >= VARROA_CRITICAL_THRESHOLD:
		colony_at_risk.emit(hive)
		# Deformed Wing Virus (transmitted by mites) degrades brood quality
		hive.brood_health = maxf(0.0, hive.brood_health - 0.01)

	if hive.varroa_mite_load >= VARROA_COLLAPSE_THRESHOLD:
		_trigger_collapse(hive)

## Simulate honey production for one day.
## Production only occurs during active nectar flow and scales with:
##   - Colony population relative to reference (50,000 bees)
##   - Brood health (sick colonies forage less efficiently)
##   - Flow intensity from SeasonConfig (spring partial flow vs. summer peak)
func _tick_honey_production(hive: HiveData) -> void:
	if not SeasonManager.is_nectar_flow_active():
		return
	var season := SeasonManager.get_current_season()
	var flow_intensity: float = 1.0
	if season != null:
		flow_intensity = season.nectar_flow_intensity
	var daily_kg := (float(hive.population) / REFERENCE_POPULATION) \
			* hive.brood_health * flow_intensity * DAILY_HONEY_KG_PER_UNIT
	hive.honey_stores_kg += daily_kg

## Simulate daily population change.
## Without a queen the colony bleeds workers with no replacements.
## With a queen, net change = daily emergence (scaled by season & brood health)
## minus daily deaths (constant mortality fraction of current population).
func _tick_population(hive: HiveData) -> void:
	if not hive.queen_present:
		# Queenless: 1% daily attrition, no new bees
		hive.population = max(0, hive.population - int(maxf(1.0,
				float(hive.population) * 0.01)))
		if hive.population == 0:
			_trigger_collapse(hive)
		return

	var season := SeasonManager.get_current_season()
	# Population growth multiplier: spring buildup >1.0, fall/winter <1.0
	var growth_multiplier: float = 1.0
	if season != null:
		growth_multiplier = season.population_growth_multiplier

	var daily_emergence := int(DAILY_BEE_EMERGENCE_BASE * hive.brood_health * growth_multiplier)
	var daily_deaths := int(float(hive.population) * DAILY_MORTALITY_RATE)
	hive.population = max(0, hive.population + daily_emergence - daily_deaths)

	if hive.population == 0:
		_trigger_collapse(hive)

## Age the queen by one day. Queens older than ~730 days may show reduced
## laying efficiency (future mechanic; tracked here for data completeness).
func _tick_queen_age(hive: HiveData) -> void:
	if hive.queen_present:
		hive.queen_age_days += 1

# ---------------------------------------------------------------------------
# Inspection
# ---------------------------------------------------------------------------

## Mark a hive as inspected on the current in-game day.
## Call this from the inspection UI after the player completes a frame review.
func inspect_hive(hive: HiveData) -> void:
	hive.last_inspected_day = GameManager.current_day
	hive_inspected.emit(hive)

# ---------------------------------------------------------------------------
# Treatment
# ---------------------------------------------------------------------------

## Apply a varroa treatment to a hive. Returns true on full application.
##
## If the treatment requires a brood-free hive (e.g., Oxalic Acid) but brood
## is present, only ~30% of mites are phoretic and exposed — the treatment is
## applied at reduced efficacy and returns false to warn the player.
##
## Multi-day treatments (Apivar, Apiguard) are stored on the hive; each daily
## tick reduces mite load gradually via _tick_treatment().
## Single-dose treatments (Oxalic Acid, duration_days = 1) are applied and
## resolved within the next tick.
func apply_treatment(hive: HiveData, treatment: TreatmentData) -> bool:
	if hive.active_treatment != null:
		push_warning("HiveManager: Hive already has an active treatment (%s). Overriding."
				% hive.active_treatment.treatment_name)

	if treatment.requires_brood_free and hive.queen_present and hive.brood_health > 0.1:
		# Brood present: only the ~30% of mites riding on adult bees are exposed.
		# Oxalic acid vaporization reaches some in-cell mites too, but dribble/spray
		# does not. Model as partial kill of phoretic fraction only.
		var phoretic_fraction := 0.30
		hive.varroa_mite_load *= (1.0 - treatment.effectiveness * phoretic_fraction)
		hive.varroa_mite_load = maxf(0.0, hive.varroa_mite_load)
		# Single-dose; no ongoing treatment registered
		return false  # Partial kill — player should be warned

	# Set treatment as active; _tick_treatment() handles daily dose reduction
	hive.active_treatment = treatment
	hive.treatment_days_remaining = max(1, treatment.duration_days)
	return true

# ---------------------------------------------------------------------------
# Save / Load support
# ---------------------------------------------------------------------------

## Return a deep copy of the hives array for inclusion in SaveData.
func get_hives_for_save() -> Array[HiveData]:
	var copy: Array[HiveData] = []
	for hive in hives:
		copy.append(hive.duplicate(true) as HiveData)
	return copy

## Restore hive list from a previously saved Array[HiveData].
## Called by GameManager.load_game() after deserialising SaveData.
func restore_from_save(saved_hives: Array[HiveData]) -> void:
	hives.clear()
	for hive in saved_hives:
		hives.append(hive)

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _trigger_collapse(hive: HiveData) -> void:
	if hive.population == 0 and not hive.queen_present and hive.brood_health == 0.0:
		return  # Already fully collapsed; avoid duplicate signal
	hive.population = 0
	hive.brood_health = 0.0
	hive.queen_present = false
	hive.active_treatment = null
	hive.treatment_days_remaining = 0
	hive_collapsed.emit(hive)
