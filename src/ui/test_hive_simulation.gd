## TestHiveSimulation — Debug scene for validating the HiveManager simulation loop.
##
## Quick Test (matches issue spec):
##   1. Open project in Godot 4 (double-click project.godot)
##   2. Run this scene directly (F6 or right-click → Run)
##   3. Click "Advance Day" or "Simulate 60 Days" to watch mite growth
##
## Expected behaviour after 60 days starting at 0.5% varroa (Summer season, ×1.8):
##   ~2.8× growth → ~1.4%  (with default multiplier 1.0 if seasons not yet active)
##   Visible exponential curve in the output log confirms the model is working.
extends Control

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _test_hive: HiveData = null
var _day_count: int = 0

# ---------------------------------------------------------------------------
# UI node references (built programmatically in _ready)
# ---------------------------------------------------------------------------

var _lbl_day: Label
var _lbl_season: Label
var _lbl_population: Label
var _lbl_varroa: Label
var _lbl_honey: Label
var _lbl_brood: Label
var _lbl_treatment: Label
var _lbl_warning: Label
var _log: RichTextLabel

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_build_ui()
	_setup_test_hive()

	# Connect HiveManager signals
	HiveManager.hive_updated.connect(_on_hive_updated)
	HiveManager.colony_at_risk.connect(_on_colony_at_risk)
	HiveManager.hive_collapsed.connect(_on_hive_collapsed)

	_update_stats()
	_log_line("🐝 Test hive ready. Season: %s  Day: %d"
			% [SeasonManager.get_season_name(), _day_count])
	_log_line("Starting varroa load: %.2f%%" % _test_hive.varroa_mite_load)

# ---------------------------------------------------------------------------
# Test hive setup
# ---------------------------------------------------------------------------

func _setup_test_hive() -> void:
	## Matches the Quick Test Setup in the issue spec exactly.
	_test_hive = HiveData.new()
	_test_hive.hive_type = "Langstroth"
	_test_hive.population = 15000
	_test_hive.varroa_mite_load = 0.5  # 0.5% mites
	_test_hive.honey_stores_kg = 5.0
	_test_hive.brood_health = 1.0
	_test_hive.queen_present = true
	HiveManager.add_hive(_test_hive)

# ---------------------------------------------------------------------------
# Button callbacks
# ---------------------------------------------------------------------------

func _on_btn_advance_day() -> void:
	SeasonManager.advance_day()
	_day_count += 1
	_update_stats()

func _on_btn_advance_10() -> void:
	for _i in 10:
		SeasonManager.advance_day()
		_day_count += 1
	_update_stats()
	_log_line("⏩ Advanced 10 days → Day %d" % _day_count)

func _on_btn_simulate_60() -> void:
	## Reproduce the exact loop from the issue Quick Test.
	## Note: calls tick_all_hives() directly (as specified in the issue) rather than
	## SeasonManager.advance_day() — season calendar and GameManager day counter do not
	## advance. This isolates pure hive simulation math from the full day loop.
	## To test the full seasonal pipeline, use "Advance 10 Days" instead.
	_log_line("--- Simulating 60 days (direct tick, season: %s) ---"
			% SeasonManager.get_season_name())
	for i in 60:
		HiveManager.tick_all_hives()
		_day_count += 1
		if i % 10 == 9:
			_log_line("Day %d: mites=%.3f%%  pop=%d" % [
					_day_count,
					_test_hive.varroa_mite_load,
					_test_hive.population])
	_update_stats()
	_log_line("--- Done. Final varroa: %.3f%% ---" % _test_hive.varroa_mite_load)

func _on_btn_apply_oxalic() -> void:
	var treatment: TreatmentData = load("res://src/data/treatments/oxalic_acid.tres")
	var full_effectiveness := HiveManager.apply_treatment(_test_hive, treatment)
	if full_effectiveness:
		_log_line("✅ Oxalic Acid applied. Mites → %.3f%%" % _test_hive.varroa_mite_load)
	else:
		_log_line("⚠️ Oxalic Acid — brood present! Partial kill only. Mites → %.3f%%"
				% _test_hive.varroa_mite_load)

func _on_btn_apply_apivar() -> void:
	var treatment: TreatmentData = load("res://src/data/treatments/apivar.tres")
	var full_effectiveness := HiveManager.apply_treatment(_test_hive, treatment)
	if full_effectiveness:
		_log_line("✅ Apivar strips applied (%d days). Tick daily to see gradual reduction."
				% treatment.duration_days)
	else:
		_log_line("⚠️ Could not apply Apivar.")

func _on_btn_apply_hopguard() -> void:
	var treatment: TreatmentData = load("res://src/data/treatments/hopguard.tres")
	var full_effectiveness := HiveManager.apply_treatment(_test_hive, treatment)
	if full_effectiveness:
		_log_line("✅ HopGuard applied (%d days) — honey supers safe."
				% treatment.duration_days)

func _on_btn_inspect() -> void:
	HiveManager.inspect_hive(_test_hive)
	_log_line("🔍 Hive inspected on day %d" % GameManager.current_day)

func _on_btn_save() -> void:
	GameManager.save_game()
	_log_line("💾 Game saved to user://save_game.tres")

func _on_btn_load() -> void:
	if GameManager.load_game():
		_update_stats()
		_log_line("📂 Game loaded. Day: %d" % GameManager.current_day)
	else:
		_log_line("❌ No save file found.")

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_hive_updated(_hive: HiveData) -> void:
	_update_stats()

func _on_colony_at_risk(hive: HiveData) -> void:
	_lbl_warning.text = "⚠️ COLONY AT RISK — varroa %.2f%%" % hive.varroa_mite_load
	_lbl_warning.add_theme_color_override("font_color", Color.RED)
	_log_line("🚨 colony_at_risk fired! Varroa at %.2f%%" % hive.varroa_mite_load)

func _on_hive_collapsed(_hive: HiveData) -> void:
	_lbl_warning.text = "💀 COLONY COLLAPSED"
	_log_line("💀 hive_collapsed — colony lost to varroa overload.")

# ---------------------------------------------------------------------------
# Stats display
# ---------------------------------------------------------------------------

func _update_stats() -> void:
	if _test_hive == null:
		return
	_lbl_day.text = "Day: %d  (in-season: %d)" % [
			GameManager.current_day, SeasonManager.day_in_season]
	_lbl_season.text = "Season: %s" % SeasonManager.get_season_name()
	_lbl_population.text = "Population: %d bees" % _test_hive.population
	_lbl_varroa.text = "Varroa load: %.3f%%" % _test_hive.varroa_mite_load
	_lbl_honey.text = "Honey stores: %.2f kg (%.1f lbs)" % [
			_test_hive.honey_stores_kg, _test_hive.honey_stores_kg * 2.205]
	_lbl_brood.text = "Brood health: %.0f%%" % (_test_hive.brood_health * 100.0)

	if _test_hive.active_treatment != null:
		_lbl_treatment.text = "Treatment: %s — %d days left" % [
				_test_hive.active_treatment.treatment_name,
				_test_hive.treatment_days_remaining]
	else:
		_lbl_treatment.text = "Treatment: none"

	if _test_hive.varroa_mite_load < HiveManager.VARROA_WARNING_THRESHOLD:
		_lbl_warning.text = "✅ Colony healthy"
		_lbl_warning.add_theme_color_override("font_color", Color(0.29, 0.49, 0.35))
	elif _test_hive.varroa_mite_load < HiveManager.VARROA_CRITICAL_THRESHOLD:
		_lbl_warning.text = "⚠️ Varroa warning (>2%)"
		_lbl_warning.add_theme_color_override("font_color", Color(0.96, 0.65, 0.14))

func _log_line(msg: String) -> void:
	_log.append_text(msg + "\n")
	# Auto-scroll to bottom
	_log.scroll_to_line(_log.get_line_count() - 1)

# ---------------------------------------------------------------------------
# UI builder
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Root: full-viewport control, dark background for readability
	custom_minimum_size = Vector2(640, 480)
	var bg := ColorRect.new()
	bg.color = Color(0.243, 0.169, 0.102)  # Dark Bark #3E2B1A
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	# Title
	var title := Label.new()
	title.text = "🐝 Buzzing Meadows — Hive Simulation Debug"
	title.add_theme_color_override("font_color", Color(0.961, 0.651, 0.137))  # Honey Gold
	root_vbox.add_child(title)

	var divider := HSeparator.new()
	root_vbox.add_child(divider)

	# Stats + Log side by side
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(columns)

	# --- Left column: Stats ---
	var stats_panel := PanelContainer.new()
	stats_panel.custom_minimum_size = Vector2(280, 0)
	columns.add_child(stats_panel)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 6)
	stats_panel.add_child(stats_vbox)

	var stats_title := Label.new()
	stats_title.text = "Hive Stats"
	stats_title.add_theme_color_override("font_color", Color(0.961, 0.651, 0.137))
	stats_vbox.add_child(stats_title)

	_lbl_day       = _make_stat_label(); stats_vbox.add_child(_lbl_day)
	_lbl_season    = _make_stat_label(); stats_vbox.add_child(_lbl_season)
	_lbl_population = _make_stat_label(); stats_vbox.add_child(_lbl_population)
	_lbl_varroa    = _make_stat_label(); stats_vbox.add_child(_lbl_varroa)
	_lbl_honey     = _make_stat_label(); stats_vbox.add_child(_lbl_honey)
	_lbl_brood     = _make_stat_label(); stats_vbox.add_child(_lbl_brood)
	_lbl_treatment = _make_stat_label(); stats_vbox.add_child(_lbl_treatment)

	var warn_sep := HSeparator.new()
	stats_vbox.add_child(warn_sep)

	_lbl_warning = Label.new()
	_lbl_warning.text = "✅ Colony healthy"
	_lbl_warning.add_theme_color_override("font_color", Color(0.29, 0.49, 0.35))
	stats_vbox.add_child(_lbl_warning)

	# Buttons
	var btn_sep := HSeparator.new()
	stats_vbox.add_child(btn_sep)

	var btn_day    := _make_button("Advance 1 Day",    _on_btn_advance_day)
	var btn_10     := _make_button("Advance 10 Days",   _on_btn_advance_10)
	var btn_60     := _make_button("Simulate 60 Days",  _on_btn_simulate_60)
	var btn_oxalic := _make_button("Apply Oxalic Acid", _on_btn_apply_oxalic)
	var btn_apivar := _make_button("Apply Apivar (42d)", _on_btn_apply_apivar)
	var btn_hg     := _make_button("Apply HopGuard",    _on_btn_apply_hopguard)
	var btn_ins    := _make_button("Inspect Hive",      _on_btn_inspect)
	var btn_save   := _make_button("💾 Save Game",      _on_btn_save)
	var btn_load   := _make_button("📂 Load Game",      _on_btn_load)
	for btn in [btn_day, btn_10, btn_60, btn_oxalic, btn_apivar, btn_hg, btn_ins,
			btn_save, btn_load]:
		stats_vbox.add_child(btn)

	# --- Right column: Log ---
	var log_panel := PanelContainer.new()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(log_panel)

	var log_scroll := ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_child(log_scroll)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = false
	_log.fit_content = true
	_log.add_theme_color_override("default_color", Color(1.0, 0.973, 0.906))  # Cream
	log_scroll.add_child(_log)

# ---------------------------------------------------------------------------
# UI factory helpers
# ---------------------------------------------------------------------------

func _make_stat_label() -> Label:
	var lbl := Label.new()
	lbl.add_theme_color_override("font_color", Color(1.0, 0.973, 0.906))  # Cream
	lbl.text = "—"
	return lbl

func _make_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(callback)
	return btn
