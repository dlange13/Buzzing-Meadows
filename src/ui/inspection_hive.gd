## InspectionHive — Visual hive inspection scene.
##
## Player clicks into each of the 8 Langstroth frames to spot varroa mites,
## then drags treatment strips from the bottom tray onto a frame to apply
## treatment. Educational notes explain the real beekeeping science.
##
## Real-world framing: Varroa concentrate in the brood nest — the center frames
## of the Langstroth box. Outer frames (nectar/honey storage) carry far fewer
## mites because mites need capped brood cells to reproduce.
##
## Usage: loaded by test_hive_simulation.gd via "Open Inspection UI" button.
## Reads the first hive from HiveManager (single-hive MVP, v0.1).
extends Control

## Emitted when the player clicks a frame panel.
signal frame_clicked(frame_index: int)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const FRAME_COUNT := 8
const FRAME_WIDTH := 120
const FRAME_HEIGHT := 190

## Relative mite density per frame position (0–7, left→right).
## Center frames (indices 2–5) hold the brood nest where varroa reproduce.
## Outer frames are honey/pollen storage with far fewer mites.
const FRAME_MITE_MULTIPLIERS: Array[float] = [0.15, 0.40, 0.90, 1.50, 1.40, 0.95, 0.40, 0.15]

## Grid layout constants for honeycomb cell rendering inside each frame panel.
const CELL_SIZE       := 10   # px per comb cell (one "pixel-art pixel" at 1280×720)
const CELL_MARGIN_X   :=  5   # horizontal inset from frame edge
const CELL_START_Y    := 22   # vertical start below the frame label row
const FRAME_LABEL_H   := 28   # height reserved for the frame label

## Inset margins for mite dot placement (keeps dots inside the comb area).
const MITE_MARGIN_X   :=  8   # horizontal inset from frame left/right edge
const MITE_MARGIN_END := 14   # combined dot size + buffer from right/bottom edge
const MITE_START_Y    := 28   # vertical start below the frame label

# UI color palette (matches project spec)
const COLOR_BARK        := Color(0.243, 0.169, 0.102)   # #3E2B1A
const COLOR_HONEY_GOLD  := Color(0.961, 0.651, 0.137)   # #F5A623
const COLOR_CREAM       := Color(1.000, 0.973, 0.906)   # #FFF8E7
const COLOR_GREEN       := Color(0.290, 0.486, 0.349)   # #4A7C59
const COLOR_SOFT_BROWN  := Color(0.545, 0.412, 0.078)   # #8B6914
const COLOR_FRAME_BG    := Color(0.780, 0.600, 0.290)   # warm wood
const COLOR_COMB        := Color(0.870, 0.730, 0.380)   # honeycomb wax
const COLOR_BROOD_CELL  := Color(0.680, 0.520, 0.180)   # capped brood (darker)
const COLOR_MITE        := Color(0.850, 0.100, 0.100)   # varroa red dot

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## The hive currently being inspected (set from HiveManager in _ready).
var _hive: HiveData = null

## Array[Array[ColorRect]] — mite dot nodes per frame for animation.
var _mite_dots: Array = []

## Index of the frame the player last clicked (-1 = none selected).
var _selected_frame: int = -1

## Stored base position for each mite dot, keyed by node path-safe index.
## Layout: _mite_base_pos[fi][di] = Vector2
var _mite_base_pos: Array = []

## Treatment being dragged (null when no drag active).
var _drag_treatment: TreatmentData = null

## Transparent follow-cursor preview shown while dragging.
var _drag_preview: Control = null

## Loaded treatment resources available in the treatment tray.
var _treatments: Array[TreatmentData] = []

## Accumulated time for mite crawl animation.
var _anim_time: float = 0.0

# ---------------------------------------------------------------------------
# UI node references
# ---------------------------------------------------------------------------

var _frame_panels: Array[Control] = []
var _info_panel: PanelContainer
var _info_label: RichTextLabel
var _edu_panel: PanelContainer
var _edu_label: RichTextLabel
var _status_label: Label
var _hive_title_label: Label

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_load_treatments()
	# In the single-hive MVP the inspection scene always works on hive #0.
	# HiveManager.get_hive(0) returns null if no hive has been added yet;
	# the UI handles that gracefully with placeholder text.
	_hive = HiveManager.get_hive(0)
	_build_ui()
	HiveManager.hive_inspected.connect(_on_hive_inspected)
	if _hive != null:
		_refresh_all_frame_mites()

func _process(delta: float) -> void:
	_anim_time += delta
	_animate_mites()
	# Move drag preview to follow cursor
	if _drag_preview != null:
		_drag_preview.global_position = get_viewport().get_mouse_position() - Vector2(80, 20)

# ---------------------------------------------------------------------------
# Setup helpers
# ---------------------------------------------------------------------------

func _load_treatments() -> void:
	var paths: Array[String] = [
		"res://src/data/treatments/apivar.tres",
		"res://src/data/treatments/apiguard.tres",
		"res://src/data/treatments/hopguard.tres",
		"res://src/data/treatments/oxalic_acid.tres",
	]
	for path in paths:
		var t := load(path) as TreatmentData
		if t:
			_treatments.append(t)

# ---------------------------------------------------------------------------
# Frame mite display
# ---------------------------------------------------------------------------

## Recalculate and rebuild all mite dots based on current hive varroa load.
func _refresh_all_frame_mites() -> void:
	for fi in FRAME_COUNT:
		_rebuild_mite_dots(fi)

## Remove existing mite dots for a frame and add the correct number of new ones.
## Mite count is derived from the hive's current varroa_mite_load scaled by the
## per-frame multiplier (center frames have more mites — the brood nest).
func _rebuild_mite_dots(frame_index: int) -> void:
	# Free old dot nodes
	for dot in _mite_dots[frame_index]:
		if is_instance_valid(dot):
			dot.queue_free()
	_mite_dots[frame_index].clear()
	_mite_base_pos[frame_index].clear()

	if _hive == null:
		return

	var dot_count := _dot_count_for_frame(frame_index)
	var panel := _frame_panels[frame_index]

	# Deterministic random placement so the layout is stable across refreshes
	var rng := RandomNumberGenerator.new()
	rng.seed = frame_index * 997 + int(_hive.varroa_mite_load * 1000.0)

	for _i in dot_count:
		var dot := ColorRect.new()
		dot.color = COLOR_MITE
		# 4×4 px = one 16×16 sprite-pixel scaled 4×; matches TEXTURE_FILTER_NEAREST
		dot.size = Vector2(4, 4)
		# Keep dots inside the comb area (below the frame label row)
		var bx := rng.randi_range(MITE_MARGIN_X, FRAME_WIDTH - MITE_MARGIN_END)
		var by := rng.randi_range(MITE_START_Y, FRAME_HEIGHT - MITE_MARGIN_END)
		dot.position = Vector2(bx, by)
		dot.z_index = 3
		panel.add_child(dot)
		_mite_dots[frame_index].append(dot)
		_mite_base_pos[frame_index].append(Vector2(bx, by))

## Number of visible mite dots for a frame given the current global mite load.
## Visual scale: 0% load → 0 dots; 8%+ load → 14 dots (per-frame multiplier applies).
func _dot_count_for_frame(frame_index: int) -> int:
	if _hive == null:
		return 0
	var local_load := _hive.varroa_mite_load * FRAME_MITE_MULTIPLIERS[frame_index]
	# ~1.75 dots per 1% local load, capped at 14 for legibility
	return clampi(int(local_load * 1.75), 0, 14)

# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

## Animate each mite dot with a slow sinusoidal "crawl" offset.
## Real varroa mites move slowly on adult bees between brood inspections.
func _animate_mites() -> void:
	for fi in FRAME_COUNT:
		var dots: Array = _mite_dots[fi]
		var bases: Array = _mite_base_pos[fi]
		for di in dots.size():
			var dot: ColorRect = dots[di]
			if not is_instance_valid(dot):
				continue
			var base: Vector2 = bases[di]
			# Unique phase per dot so they don't all move in sync
			var px := float(fi * 17 + di * 11) * 0.5
			var py := float(fi * 13 + di *  7) * 0.5
			var ox := sin(_anim_time * 1.2 + px) * 1.5
			var oy := cos(_anim_time * 1.5 + py) * 1.5
			dot.position = base + Vector2(ox, oy)

# ---------------------------------------------------------------------------
# Input — drag-and-drop mouse release detection
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if _drag_treatment != null:
				_finish_drag(mb.global_position)

# ---------------------------------------------------------------------------
# Frame click handler
# ---------------------------------------------------------------------------

func _on_frame_clicked(frame_index: int) -> void:
	# Ignore clicks that are actually drag releases
	if _drag_treatment != null:
		return
	_selected_frame = frame_index
	frame_clicked.emit(frame_index)
	_show_frame_info(frame_index)

func _show_frame_info(frame_index: int) -> void:
	if _hive == null:
		return
	var local_load := _hive.varroa_mite_load * FRAME_MITE_MULTIPLIERS[frame_index]
	var dot_count := _dot_count_for_frame(frame_index)

	var status_text: String
	if local_load < 1.0:
		status_text = "[color=#4A7C59]✅ Frame %d looks clean. Mite levels low.[/color]" % (frame_index + 1)
	elif local_load < 2.0:
		status_text = "[color=#F5A623]🟡 Frame %d: Some mites present. Monitor weekly.[/color]" % (frame_index + 1)
	elif local_load < 3.0:
		status_text = "[color=#F5A623]⚠️ Frame %d: Varroa infestation detected — %.1f%% load![/color]" % [frame_index + 1, local_load]
	else:
		status_text = "[color=#ff4444]🚨 Frame %d: HEAVY infestation — %.1f%%! Treat immediately.[/color]" % [frame_index + 1, local_load]

	_info_label.text = (
		"[b]Frame %d of %d[/b]\n"
		+ "Local varroa load: [color=#F5A623]%.2f%%[/color]\n"
		+ "Mites visible: %d\n\n"
		+ "%s\n\n"
		+ "[i]Drag a treatment strip (below) onto this frame to apply treatment.[/i]"
	) % [frame_index + 1, FRAME_COUNT, local_load, dot_count, status_text]

	_info_panel.visible = true
	_edu_panel.visible = false

	# Highlight the selected frame, dim the rest
	for fi in FRAME_COUNT:
		_frame_panels[fi].modulate = Color(1.2, 1.1, 0.7) if fi == frame_index else Color.WHITE

# ---------------------------------------------------------------------------
# Drag-and-drop — treatment application
# ---------------------------------------------------------------------------

## Begin dragging a treatment strip. Called by each pill's button_down signal.
func _start_drag(treatment: TreatmentData, _source_node: Control) -> void:
	_drag_treatment = treatment
	_drag_preview = _build_treatment_pill(treatment, true)
	_drag_preview.modulate.a = 0.75
	_drag_preview.z_index = 200
	add_child(_drag_preview)

## Resolve a drag drop: check if the cursor is over a frame panel and apply.
func _finish_drag(drop_pos: Vector2) -> void:
	if _drag_preview != null:
		_drag_preview.queue_free()
		_drag_preview = null

	var target_frame := -1
	for fi in FRAME_COUNT:
		var fp := _frame_panels[fi]
		if Rect2(fp.global_position, fp.size).has_point(drop_pos):
			target_frame = fi
			break

	if target_frame >= 0 and _hive != null:
		_apply_treatment(_drag_treatment, target_frame)
	else:
		_status_label.text = "Drop a treatment strip onto a hive frame to apply it."

	_drag_treatment = null

## Apply a treatment to the hive and update the UI accordingly.
func _apply_treatment(treatment: TreatmentData, frame_index: int) -> void:
	var success := HiveManager.apply_treatment(_hive, treatment)
	HiveManager.inspect_hive(_hive)

	if success:
		_status_label.text = (
			"✅ %s applied to Frame %d. Active for %d days."
		) % [treatment.treatment_name, frame_index + 1, treatment.duration_days]
	else:
		_status_label.text = (
			"⚠️ %s applied — brood present, partial kill only. Consider a brood break first."
		) % treatment.treatment_name

	# Show the educational note for this treatment
	_edu_label.text = (
		"[b]%s[/b]\n"
		+ "[i]Active ingredient: %s[/i]  |  "
		+ "[i]Effectiveness: %.0f%%[/i]  |  "
		+ "[i]Duration: %d days[/i]\n\n"
		+ "%s"
	) % [
		treatment.treatment_name,
		treatment.active_ingredient,
		treatment.effectiveness * 100.0,
		treatment.duration_days,
		treatment.educational_note,
	]
	_edu_panel.visible = true
	_info_panel.visible = false

	# Rebuild mite dots to reflect the updated varroa load after treatment
	_refresh_all_frame_mites()
	# Re-highlight selected frame if one was active
	if _selected_frame >= 0:
		_frame_panels[_selected_frame].modulate = Color(1.2, 1.1, 0.7)

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_hive_inspected(_hive_data: HiveData) -> void:
	_status_label.text = "🔍 Hive inspected. Day %d recorded." % GameManager.current_day

func _on_btn_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/test_hive_simulation.tscn")

func _on_btn_close_panels() -> void:
	_info_panel.visible = false
	_edu_panel.visible = false
	for fi in FRAME_COUNT:
		_frame_panels[fi].modulate = Color.WHITE
	_selected_frame = -1

# ---------------------------------------------------------------------------
# UI Builder
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	custom_minimum_size = Vector2(1280, 720)

	# Background
	var bg := ColorRect.new()
	bg.color = COLOR_BARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_top", "margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	# --- Title row ---
	_build_title_row(root_vbox)
	root_vbox.add_child(_make_separator())

	# --- Instruction row ---
	var hint := Label.new()
	hint.text = "Click a frame to inspect  ·  Drag a treatment strip (bottom tray) onto a frame to apply treatment"
	hint.add_theme_color_override("font_color", COLOR_CREAM)
	root_vbox.add_child(hint)

	# --- 8 frame panels ---
	var frames_hbox := HBoxContainer.new()
	frames_hbox.add_theme_constant_override("separation", 6)
	frames_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(frames_hbox)

	for fi in FRAME_COUNT:
		_mite_dots.append([])
		_mite_base_pos.append([])
		var fp := _build_frame_panel(fi)
		_frame_panels.append(fp)
		frames_hbox.add_child(fp)

	# --- Info / educational panels (side-by-side) ---
	_build_info_edu_row(root_vbox)

	root_vbox.add_child(_make_separator())

	# --- Treatment tray ---
	_build_treatment_tray(root_vbox)

	root_vbox.add_child(_make_separator())

	# --- Status bar ---
	_status_label = Label.new()
	var hive_state_msg := "Click any frame to begin inspection." if _hive != null else "No hive found — add a hive in the test scene first."
	_status_label.text = hive_state_msg
	_status_label.add_theme_color_override("font_color", COLOR_CREAM)
	root_vbox.add_child(_status_label)

func _build_title_row(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	_hive_title_label = Label.new()
	var title_text := "🐝 Langstroth Hive #1 — Inspection"
	if _hive != null:
		var varroa_str := "%.1f%%" % _hive.varroa_mite_load
		title_text += "   [varroa: %s]" % varroa_str
	_hive_title_label.text = title_text
	_hive_title_label.add_theme_color_override("font_color", COLOR_HONEY_GOLD)
	_hive_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_hive_title_label)

	var btn_back := Button.new()
	btn_back.text = "← Back to Farm"
	btn_back.pressed.connect(_on_btn_back_pressed)
	hbox.add_child(btn_back)

func _build_info_edu_row(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.custom_minimum_size.y = 130
	parent.add_child(hbox)

	# Frame info panel (shown on click)
	_info_panel = PanelContainer.new()
	_info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_panel.visible = false
	hbox.add_child(_info_panel)

	var info_vbox := VBoxContainer.new()
	_info_panel.add_child(info_vbox)

	var info_title := Label.new()
	info_title.text = "🔍 Frame Info"
	info_title.add_theme_color_override("font_color", COLOR_HONEY_GOLD)
	info_vbox.add_child(info_title)

	_info_label = RichTextLabel.new()
	_info_label.bbcode_enabled = true
	_info_label.fit_content = true
	_info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_label.add_theme_color_override("default_color", COLOR_CREAM)
	info_vbox.add_child(_info_label)

	var close_info := Button.new()
	close_info.text = "Close"
	close_info.pressed.connect(_on_btn_close_panels)
	info_vbox.add_child(close_info)

	# Educational popup panel (shown after applying treatment)
	_edu_panel = PanelContainer.new()
	_edu_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edu_panel.visible = false
	hbox.add_child(_edu_panel)

	var edu_vbox := VBoxContainer.new()
	_edu_panel.add_child(edu_vbox)

	var edu_title := Label.new()
	edu_title.text = "📚 Treatment Guide"
	edu_title.add_theme_color_override("font_color", COLOR_HONEY_GOLD)
	edu_vbox.add_child(edu_title)

	_edu_label = RichTextLabel.new()
	_edu_label.bbcode_enabled = true
	_edu_label.fit_content = true
	_edu_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_edu_label.add_theme_color_override("default_color", COLOR_CREAM)
	edu_vbox.add_child(_edu_label)

	var close_edu := Button.new()
	close_edu.text = "Close"
	close_edu.pressed.connect(_on_btn_close_panels)
	edu_vbox.add_child(close_edu)

func _build_treatment_tray(parent: VBoxContainer) -> void:
	var lbl := Label.new()
	lbl.text = "🧪 Treatment Tray — drag a strip onto any frame:"
	lbl.add_theme_color_override("font_color", COLOR_CREAM)
	parent.add_child(lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	parent.add_child(hbox)

	for t in _treatments:
		var pill := _build_treatment_pill(t, false)
		hbox.add_child(pill)

## Build a single Langstroth frame panel with honeycomb cells drawn as colored
## rects. The bottom ~30% of cells are depicted as capped brood (darker color);
## the upper portion as honey/pollen cells (lighter gold).
func _build_frame_panel(frame_index: int) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(FRAME_WIDTH, FRAME_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_FRAME_BG
	style.border_color = COLOR_SOFT_BROWN
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)

	# Frame number label
	var num_lbl := Label.new()
	num_lbl.text = "F%d" % (frame_index + 1)
	num_lbl.add_theme_color_override("font_color", COLOR_BARK)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	num_lbl.position = Vector2(0, 3)
	panel.add_child(num_lbl)

	# Honeycomb cell grid (16×16 "pixel art" cells, TEXTURE_FILTER_NEAREST scale)
	_add_comb_cells(panel, frame_index)

	# Transparent click-through button overlay — sends click to handler
	var click_btn := Button.new()
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.flat = true
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		click_btn.add_theme_stylebox_override(state, empty_style)
	click_btn.pressed.connect(_on_frame_clicked.bind(frame_index))
	panel.add_child(click_btn)

	return panel

## Populate a frame panel with a grid of small honeycomb-style cells.
## Cells near the center of the frame are rendered as capped brood (darker).
## This matches the visual reality: brood occupies the lower/center comb area.
func _add_comb_cells(panel: Panel, frame_index: int) -> void:
	var cols := (FRAME_WIDTH  - 10) / CELL_SIZE
	var rows := (FRAME_HEIGHT - FRAME_LABEL_H) / CELL_SIZE

	# Deterministic per-frame seed so cell layout is stable
	var rng := RandomNumberGenerator.new()
	rng.seed = frame_index * 1009 + 77

	for row in rows:
		for col in cols:
			var cr := ColorRect.new()
			# Bottom ~40% of rows = brood cells; rest = honey/pollen
			if row >= int(rows * 0.60):
				cr.color = COLOR_BROOD_CELL if rng.randf() > 0.15 else COLOR_COMB
			else:
				cr.color = COLOR_COMB if rng.randf() > 0.20 else COLOR_BROOD_CELL
			cr.size    = Vector2(CELL_SIZE - 1, CELL_SIZE - 1)
			cr.position = Vector2(CELL_MARGIN_X + col * CELL_SIZE, CELL_START_Y + row * CELL_SIZE)
			cr.z_index = 1
			panel.add_child(cr)

## Build a colored treatment strip "pill" button.
## When is_preview is false, a transparent button overlay fires _start_drag.
func _build_treatment_pill(treatment: TreatmentData, is_preview: bool) -> Control:
	var pill := Panel.new()
	pill.custom_minimum_size = Vector2(170, 44)

	# Color-code strips by chemistry (matches real beekeeper label conventions)
	var pill_color: Color
	match treatment.active_ingredient:
		"Amitraz":
			pill_color = Color(0.20, 0.45, 0.80)   # blue  — synthetic miticide
		"Thymol":
			pill_color = Color(0.20, 0.65, 0.35)   # green — natural/organic
		"Hop Beta Acids":
			pill_color = Color(0.55, 0.78, 0.22)   # lime  — organic acid
		_:  # Oxalic acid
			pill_color = Color(0.85, 0.82, 0.15)   # yellow — acid treatment

	var style := StyleBoxFlat.new()
	style.bg_color = pill_color
	style.set_corner_radius_all(6)
	pill.add_theme_stylebox_override("panel", style)

	var name_lbl := Label.new()
	name_lbl.text = treatment.treatment_name
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	pill.add_child(name_lbl)

	if not is_preview:
		# Transparent overlay to initiate drag on button_down
		var drag_btn := Button.new()
		drag_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		drag_btn.flat = true
		var empty := StyleBoxEmpty.new()
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			drag_btn.add_theme_stylebox_override(state, empty)
		drag_btn.button_down.connect(_start_drag.bind(treatment, pill))
		pill.add_child(drag_btn)

	return pill

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

func _make_separator() -> HSeparator:
	return HSeparator.new()
