extends CanvasLayer

const HeatMeterScript = preload("res://scripts/extra_mode/HeatMeter.gd")
const HelpPanelScript = preload("res://scripts/extra_mode/HelpPanel.gd")

const ENERGY_GAIN_COLOR := Color("#2FD9A0")
const SCORE_BONUS_COLOR := Color("#FFD75E")
const SCORE_BONUS_DISPLAY_SECONDS := 1.5
const ENERGY_GAIN_IDLE_COLOR := Color(1.0, 1.0, 1.0, 0.28)
const STEP_AVAILABLE_COLOR := Color("#2FD9A0")
const STEP_UNAVAILABLE_COLOR := Color("#4A5058")
const DIRECTION_ACTIVE_COLOR := Color("#7FE85A")
const DIRECTION_EXPIRING_COLOR := Color("#AAB58A")
const DIRECTION_EMPTY_COLOR := Color("#4A5058")
const DASH_AVAILABLE_COLOR := Color("#DFFFE9")
const NAV_KEY_COLOR := Color("#6E7A85")
const NAV_ACTION_COLOR := Color(0.86, 0.88, 0.91)
const SIDEBAR_MARGIN := 20.0
const SIDEBAR_WIDTH := 320.0
const NAV_ROW_TOP := 12.0
const NAV_ROW_WIDTH := 520.0
const STATUS_GROUP_TOP := 94.0
const STATUS_GROUP_HEIGHT := 322.0
const STATUS_CONTENT_LEFT := 34.0
const HEAT_METER_LEFT := 98.0
const HEAT_VALUE_LEFT := 254.0
const SCORE_ROW_TOP := 108.0
const HEAT_ROW_TOP := 174.0
const STATUS_PANEL_TOP := 214.0
const STATUS_PANEL_HEIGHT := 190.0
const BOTTOM_INFO_MARGIN := 18.0
const BOTTOM_INFO_ROW_HEIGHT := 28.0
const ENERGY_ROW_CONTENT_WIDTH := 205.0
const ENERGY_GAIN_WIDTH := 44.0

var nav_row: HBoxContainer
var status_group_panel: PanelContainer
var score_label: Label
var score_bonus_label: Label
var score_bonus_timer: Timer
var combo_label: Label
var heat_meter: Control
var heat_value_label: Label
var turn_label: Label
var energy_gain_label: Label
var inventory_container: HBoxContainer
var inventory_panel: MarginContainer
var energy_container: HBoxContainer
var hold_container: HBoxContainer
var hold_label: Label
var hold_slot: Label
var dash_action_label: Label
var ultimate_action_label: Label
var gameover_panel: PanelContainer
var gameover_score: Label
var gameover_max_streak: Label
var message_label: Label
var ai_status_label: Label
var help_panel: PanelContainer

var slot_labels: Array = []
var energy_slots: Array[DIRExtraEnergySlot] = []
var _max_slots: int = 3
var _has_hold: bool = false
var _has_charge_marker: bool = false
var _charge_max: int = 0
var _slot_flash_tweens: Array[Tween] = []
var _energy_flash_tweens: Array[Tween] = []

func _ready() -> void:
	# Built from separate labels rather than one string: as a single run of text
	# at one colour and size, the key and the thing it does read as one blurred
	# token. The key is set smaller and muted so the action word carries the row.
	nav_row = HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 30)
	add_child(nav_row)
	for entry in [["ESC", "TITLE"], ["F1", "HELP"], ["R", "RESTART"]]:
		nav_row.add_child(_nav_entry(String(entry[0]), String(entry[1])))

	status_group_panel = PanelContainer.new()
	status_group_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var status_group_style := StyleBoxFlat.new()
	status_group_style.bg_color = Color("#10151A")
	status_group_style.border_color = Color("#24755E")
	status_group_style.set_border_width_all(2)
	status_group_style.set_corner_radius_all(4)
	status_group_panel.add_theme_stylebox_override("panel", status_group_style)
	add_child(status_group_panel)

	# Score and heat - top left
	score_label = Label.new()
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 56)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_label.position = Vector2(STATUS_CONTENT_LEFT, SCORE_ROW_TOP)
	score_label.size = Vector2(280, 64)
	add_child(score_label)

	score_bonus_label = Label.new()
	score_bonus_label.text = ""
	score_bonus_label.add_theme_font_size_override("font_size", 26)
	score_bonus_label.add_theme_color_override("font_color", SCORE_BONUS_COLOR)
	score_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_bonus_label.size = Vector2(120, 32)
	score_bonus_label.visible = false
	add_child(score_bonus_label)

	score_bonus_timer = Timer.new()
	score_bonus_timer.one_shot = true
	score_bonus_timer.wait_time = SCORE_BONUS_DISPLAY_SECONDS
	score_bonus_timer.timeout.connect(func(): score_bonus_label.visible = false)
	add_child(score_bonus_timer)

	combo_label = Label.new()
	combo_label.text = "HEAT"
	combo_label.add_theme_font_size_override("font_size", 22)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	combo_label.position = Vector2(STATUS_CONTENT_LEFT, HEAT_ROW_TOP)
	combo_label.size = Vector2(66, 30)
	add_child(combo_label)

	heat_meter = HeatMeterScript.new()
	heat_meter.position = Vector2(HEAT_METER_LEFT, HEAT_ROW_TOP + 6.0)
	heat_meter.size = Vector2(166, 18)
	add_child(heat_meter)

	heat_value_label = Label.new()
	heat_value_label.text = "0"
	heat_value_label.add_theme_font_size_override("font_size", 14)
	heat_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heat_value_label.position = Vector2(HEAT_VALUE_LEFT, HEAT_ROW_TOP + 4.0)
	heat_value_label.size = Vector2(80, 22)
	add_child(heat_value_label)

	turn_label = Label.new()
	turn_label.text = "TURN 0"
	turn_label.add_theme_font_size_override("font_size", 20)
	turn_label.add_theme_color_override("font_color", Color(0.68, 0.70, 0.74))
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	turn_label.position = Vector2(SIDEBAR_MARGIN, 0)
	turn_label.size = Vector2(SIDEBAR_WIDTH, 28)
	add_child(turn_label)

	# Three-row status panel in the left sidebar.
	inventory_panel = MarginContainer.new()
	inventory_panel.position = Vector2(SIDEBAR_MARGIN, STATUS_PANEL_TOP)
	inventory_panel.size = Vector2(SIDEBAR_WIDTH, STATUS_PANEL_HEIGHT)
	add_child(inventory_panel)

	var status_vbox := VBoxContainer.new()
	status_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	status_vbox.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(status_vbox)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 10)

	ultimate_action_label = Label.new()
	ultimate_action_label.text = "[Z] DASH"
	ultimate_action_label.add_theme_font_size_override("font_size", 20)
	ultimate_action_label.add_theme_color_override("font_color", DIRECTION_EMPTY_COLOR)
	ultimate_action_label.custom_minimum_size = Vector2(104, 36)
	ultimate_action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ultimate_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_row.add_child(ultimate_action_label)

	dash_action_label = Label.new()
	dash_action_label.text = "[X] STEP"
	dash_action_label.add_theme_font_size_override("font_size", 20)
	dash_action_label.add_theme_color_override("font_color", STEP_UNAVAILABLE_COLOR)
	dash_action_label.custom_minimum_size = Vector2(116, 36)
	dash_action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dash_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_row.add_child(dash_action_label)

	var energy_row := HBoxContainer.new()
	energy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	energy_row.add_theme_constant_override("separation", 6)
	status_vbox.add_child(energy_row)

	var energy_label := Label.new()
	energy_label.text = "ENERGY"
	energy_label.add_theme_font_size_override("font_size", 20)
	energy_row.add_child(energy_label)

	energy_container = HBoxContainer.new()
	energy_container.add_theme_constant_override("separation", 2)
	energy_row.add_child(energy_container)
	for _i in 4:
		var energy_slot := DIRExtraEnergySlot.new()
		energy_container.add_child(energy_slot)
		energy_slots.append(energy_slot)

	# Last resolved energy gain. This lives outside the HBox so changing or
	# hiding it never shifts the ENERGY label and its four energy slots.
	energy_gain_label = Label.new()
	energy_gain_label.text = ""
	energy_gain_label.add_theme_font_size_override("font_size", 20)
	energy_gain_label.add_theme_color_override("font_color", ENERGY_GAIN_COLOR)
	energy_gain_label.size = Vector2(ENERGY_GAIN_WIDTH, 36)
	energy_gain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_gain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_gain_label.visible = false
	add_child(energy_gain_label)

	var direction_row := HBoxContainer.new()
	direction_row.alignment = BoxContainer.ALIGNMENT_CENTER
	direction_row.add_theme_constant_override("separation", 6)
	status_vbox.add_child(direction_row)
	status_vbox.add_child(action_row)

	var direction_label := Label.new()
	direction_label.text = "DIR"
	direction_label.add_theme_font_size_override("font_size", 20)
	direction_row.add_child(direction_label)

	inventory_container = HBoxContainer.new()
	inventory_container.add_theme_constant_override("separation", 4)
	direction_row.add_child(inventory_container)

	hold_label = Label.new()
	hold_label.text = "HOLD "
	hold_label.add_theme_font_size_override("font_size", 20)
	direction_row.add_child(hold_label)

	hold_slot = Label.new()
	hold_slot.text = "-"
	hold_slot.add_theme_font_size_override("font_size", 28)
	hold_slot.add_theme_color_override("font_color", DIRECTION_EMPTY_COLOR)
	hold_slot.custom_minimum_size = Vector2(72, 36)
	hold_slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	direction_row.add_child(hold_slot)

	hold_container = direction_row

	message_label = Label.new()
	message_label.text = "WASD: Move | Space: Wait"
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	message_label.position = Vector2(
		SIDEBAR_MARGIN,
		STATUS_GROUP_TOP + STATUS_GROUP_HEIGHT + 10.0
	)
	message_label.size = Vector2(SIDEBAR_WIDTH, 30)
	message_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(message_label)

	ai_status_label = Label.new()
	ai_status_label.text = "[F4] AI"
	ai_status_label.add_theme_font_size_override("font_size", 18)
	ai_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ai_status_label.add_theme_color_override("font_color", Color(0.68, 0.70, 0.74))
	add_child(ai_status_label)

	gameover_panel = PanelContainer.new()
	gameover_panel.position = Vector2(200, 250)
	gameover_panel.size = Vector2(400, 250)
	gameover_panel.visible = false
	add_child(gameover_panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	gameover_panel.add_child(vbox)

	var go_title = Label.new()
	go_title.text = "GAME OVER"
	go_title.add_theme_font_size_override("font_size", 40)
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(go_title)

	gameover_score = Label.new()
	gameover_score.text = "0"
	gameover_score.add_theme_font_size_override("font_size", 60)
	gameover_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameover_score.add_theme_color_override("font_color", Color(0.95, 0.77, 0.06))
	vbox.add_child(gameover_score)

	gameover_max_streak = Label.new()
	gameover_max_streak.text = "MAX COMBO 0"
	gameover_max_streak.add_theme_font_size_override("font_size", 26)
	gameover_max_streak.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameover_max_streak.add_theme_color_override("font_color", SCORE_BONUS_COLOR)
	vbox.add_child(gameover_max_streak)

	var restart_hint = Label.new()
	restart_hint.text = "Press R to restart"
	restart_hint.add_theme_font_size_override("font_size", 20)
	restart_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(restart_hint)

	help_panel = HelpPanelScript.new()
	add_child(help_panel)

	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()

func setup(char_name: String) -> void:
	_cancel_slot_flashes()
	var data = CharacterData.CHARACTERS[char_name]
	_max_slots = data["seq"]
	_has_hold = data["has_hold"]
	_has_charge_marker = data.get("has_charge_marker", false)
	_charge_max = data.get("charge_max", 0)

	for child in inventory_container.get_children():
		child.queue_free()
	slot_labels.clear()

	for i in _max_slots + Inventory.ULT_COMPLETION_OVERFLOW_SLOTS:
		var slot = Label.new()
		slot.text = "-"
		slot.add_theme_font_size_override("font_size", 28)
		slot.custom_minimum_size = Vector2(36, 36)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if i >= _max_slots:
			# Temporary final-ULT slot: shown only while it actually holds a
			# direction, tinted with the ULT colour.
			slot.add_theme_color_override("font_color", DASH_AVAILABLE_COLOR)
			slot.visible = false
		else:
			slot.add_theme_color_override("font_color", DIRECTION_EMPTY_COLOR)
		inventory_container.add_child(slot)
		slot_labels.append(slot)

	var has_extra_slot := _has_hold or _has_charge_marker
	hold_slot.visible = has_extra_slot
	hold_label.visible = has_extra_slot
	if _has_charge_marker:
		hold_label.text = "CHG "
	elif _has_hold:
		hold_label.text = "HOLD "

	gameover_panel.visible = false
	help_panel.visible = false

func toggle_help() -> void:
	help_panel.visible = not help_panel.visible

func is_help_visible() -> bool:
	return help_panel.visible

func update_inventory(inv: Inventory) -> void:
	var expiring_count := 0
	if inv.queue.size() >= _max_slots:
		expiring_count = inv.queue.size() - _max_slots + 1
	for i in slot_labels.size():
		var slot: Label = slot_labels[i]
		if i >= _max_slots:
			slot.visible = i < inv.queue.size()
		if i < inv.queue.size():
			slot.text = CharacterData.DIR_ARROWS[inv.queue[i]]
			if i < expiring_count:
				slot.add_theme_color_override("font_color", DIRECTION_EXPIRING_COLOR)
			elif i >= _max_slots:
				slot.add_theme_color_override("font_color", STEP_AVAILABLE_COLOR)
			else:
				slot.add_theme_color_override("font_color", DIRECTION_ACTIVE_COLOR)
		else:
			slot.text = "-"
			slot.add_theme_color_override("font_color", DIRECTION_EMPTY_COLOR)

	if _has_hold:
		hold_slot.text = CharacterData.DIR_ARROWS[inv.hold] if inv.hold != CharacterData.Direction.NONE else "-"
		hold_slot.add_theme_color_override(
			"font_color",
			DIRECTION_ACTIVE_COLOR if inv.hold != CharacterData.Direction.NONE else DIRECTION_EMPTY_COLOR
		)
	elif _has_charge_marker:
		if inv.charge_direction == CharacterData.Direction.NONE:
			hold_slot.text = "- 0/%d" % _charge_max
		else:
			var arrow = CharacterData.DIR_ARROWS[inv.charge_direction]
			var charge_text = "FULL" if inv.is_charge_full() else "%d/%d" % [inv.charge_value, _charge_max]
			hold_slot.text = "%s %s" % [arrow, charge_text]

func update_score(score: int) -> void:
	score_label.text = str(score)

func show_score_bonus(amount: int) -> void:
	score_bonus_label.text = "+%d" % amount
	var font: Font = score_label.get_theme_font("font")
	var font_size: int = score_label.get_theme_font_size("font_size")
	var score_text_width: float = font.get_string_size(
		score_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	).x
	score_bonus_label.position = Vector2(
		score_label.position.x + score_text_width + 12.0,
		score_label.position.y + score_label.size.y / 2.0 - score_bonus_label.size.y / 2.0
	)
	score_bonus_label.visible = true
	score_bonus_timer.start()

func update_combo(combo: int, tier5_streak: int) -> void:
	combo_label.text = "HEAT"
	# The small readout is not a heat display at all -- heat already has the
	# meter for that. It exists only to show progress toward ScoreManager's
	# tier-5 streak bonus, so it has nothing to say until heat is capped.
	heat_value_label.visible = combo >= ScoreManager.MAX_COMBO_TIER
	if heat_value_label.visible:
		heat_value_label.text = "%d combo" % tier5_streak
	heat_meter.set_heat(combo)

func update_turns(turn_count: int) -> void:
	turn_label.text = "TURN %d" % turn_count

func update_energy_gain(quarter_units: int) -> void:
	energy_gain_label.visible = quarter_units > 0
	if quarter_units <= 0:
		return
	energy_gain_label.text = "+%d" % quarter_units
	energy_gain_label.add_theme_color_override("font_color", ENERGY_GAIN_COLOR)

func update_energy(
	quarter_units: int,
	bonus_step_armed: bool,
	ultimate_steps: int,
	bonus_step_cost: int = 4
) -> void:
	for i in energy_slots.size():
		var slot_quarter_units: int = clampi(quarter_units - i * 4, 0, 4)
		var fill_ratio: float = float(slot_quarter_units) / 4.0
		energy_slots[i].set_fill_ratio(fill_ratio)
		energy_slots[i].set_full_charge_ready(quarter_units >= 16)
	var step_available: bool = quarter_units >= bonus_step_cost or bonus_step_armed
	dash_action_label.modulate = Color.WHITE
	dash_action_label.add_theme_color_override(
		"font_color",
		STEP_AVAILABLE_COLOR if step_available else STEP_UNAVAILABLE_COLOR
	)
	var ultimate_available: bool = quarter_units >= 16 or ultimate_steps > 0
	ultimate_action_label.modulate = Color.WHITE
	ultimate_action_label.add_theme_color_override(
		"font_color",
		DASH_AVAILABLE_COLOR if ultimate_available else DIRECTION_EMPTY_COLOR
	)
	if ultimate_steps > 0:
		ultimate_action_label.text = "[Z] DASH %d" % ultimate_steps
	else:
		ultimate_action_label.text = "[Z] DASH"

func update_ai_status(label: String) -> void:
	# label carries both "which bot" and "is one active" -- Main.gd owns that
	# decision (F4's untuned bot vs F5's CMA-ES-tuned bot are mutually
	# exclusive), this just renders whatever it's told.
	var enabled: bool = label.ends_with("ON")
	ai_status_label.text = label
	ai_status_label.add_theme_color_override(
		"font_color",
		Color("#C8E64A") if enabled else Color(0.68, 0.70, 0.74)
	)

func play_inventory_hit(slot_count: int) -> void:
	_cancel_slot_flashes()
	var count: int = mini(slot_count, slot_labels.size())
	for i in count:
		var slot: Label = slot_labels[i]
		slot.modulate = Color.WHITE
		var tween := create_tween()
		_slot_flash_tweens.append(tween)
		tween.tween_property(slot, "modulate", Color(1.0, 0.18, 0.18), 0.04)
		tween.tween_property(slot, "modulate", Color.WHITE, 0.055)
		tween.tween_property(slot, "modulate", Color(1.0, 0.18, 0.18), 0.045)
		tween.tween_property(slot, "modulate", Color.WHITE, 0.07)

func play_energy_hit(slot_index: int) -> void:
	_cancel_energy_flashes()
	if slot_index < 0 or slot_index >= energy_slots.size():
		return
	var slot: Control = energy_slots[slot_index]
	slot.modulate = Color.WHITE
	var tween := create_tween()
	_energy_flash_tweens.append(tween)
	tween.tween_property(slot, "modulate", Color(1.0, 0.16, 0.16), 0.05)
	tween.tween_property(slot, "modulate", Color.WHITE, 0.06)
	tween.tween_property(slot, "modulate", Color(1.0, 0.16, 0.16), 0.05)
	tween.tween_property(slot, "modulate", Color.WHITE, 0.08)

func _cancel_slot_flashes() -> void:
	for tween in _slot_flash_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_slot_flash_tweens.clear()
	for slot_value in slot_labels:
		var slot: Label = slot_value
		slot.modulate = Color.WHITE

func _cancel_energy_flashes() -> void:
	for tween in _energy_flash_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_energy_flash_tweens.clear()
	for slot in energy_slots:
		slot.modulate = Color.WHITE

func _nav_entry(key: String, action: String) -> HBoxContainer:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", 8)
	var key_label := Label.new()
	key_label.text = "[%s]" % key
	key_label.add_theme_font_size_override("font_size", 16)
	key_label.add_theme_color_override("font_color", NAV_KEY_COLOR)
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	entry.add_child(key_label)
	var action_label := Label.new()
	action_label.text = action
	action_label.add_theme_font_size_override("font_size", 22)
	action_label.add_theme_color_override("font_color", NAV_ACTION_COLOR)
	action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	entry.add_child(action_label)
	return entry

func update_state(_state: int) -> void:
	# R is already named in the nav row above; repeating it here spends the
	# turn-action hint on a key the player can always see.
	message_label.text = "WASD: Move | Space: Wait"

func show_game_over(final_score: int, max_tier5_streak: int) -> void:
	gameover_score.text = str(final_score)
	gameover_max_streak.text = "MAX COMBO %d" % max_tier5_streak
	gameover_panel.visible = true

func _layout_ui() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var sidebar_width: float = min(SIDEBAR_WIDTH, viewport_size.x - SIDEBAR_MARGIN * 2.0)
	nav_row.position = Vector2(SIDEBAR_MARGIN, NAV_ROW_TOP)
	nav_row.size = Vector2(NAV_ROW_WIDTH, 32)
	status_group_panel.position = Vector2(SIDEBAR_MARGIN, STATUS_GROUP_TOP)
	status_group_panel.size = Vector2(sidebar_width, STATUS_GROUP_HEIGHT)
	score_label.position = Vector2(STATUS_CONTENT_LEFT, SCORE_ROW_TOP)
	score_label.size = Vector2(280, 64)

	combo_label.position = Vector2(STATUS_CONTENT_LEFT, HEAT_ROW_TOP)
	combo_label.size = Vector2(66, 30)
	heat_meter.position = Vector2(HEAT_METER_LEFT, HEAT_ROW_TOP + 6.0)
	heat_meter.size = Vector2(166, 18)
	heat_value_label.position = Vector2(HEAT_VALUE_LEFT, HEAT_ROW_TOP + 4.0)
	heat_value_label.size = Vector2(80, 22)
	turn_label.position = Vector2(
		SIDEBAR_MARGIN,
		viewport_size.y - BOTTOM_INFO_MARGIN - BOTTOM_INFO_ROW_HEIGHT * 2.0
	)
	turn_label.size = Vector2(sidebar_width, 28)

	inventory_panel.position = Vector2(SIDEBAR_MARGIN, STATUS_PANEL_TOP)
	inventory_panel.size = Vector2(sidebar_width, STATUS_PANEL_HEIGHT)
	energy_gain_label.position = Vector2(
		SIDEBAR_MARGIN + (sidebar_width + ENERGY_ROW_CONTENT_WIDTH) * 0.5 + 4.0,
		STATUS_PANEL_TOP + 24.0
	)
	energy_gain_label.size = Vector2(ENERGY_GAIN_WIDTH, 36.0)

	message_label.position = Vector2(
		SIDEBAR_MARGIN,
		STATUS_GROUP_TOP + STATUS_GROUP_HEIGHT + 10.0
	)
	message_label.size = Vector2(sidebar_width, 30)

	ai_status_label.position = Vector2(
		SIDEBAR_MARGIN,
		viewport_size.y - BOTTOM_INFO_MARGIN - BOTTOM_INFO_ROW_HEIGHT
	)
	ai_status_label.size = Vector2(150, 30)
	ai_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	gameover_panel.position = Vector2(
		(viewport_size.x - gameover_panel.size.x) * 0.5,
		(viewport_size.y - gameover_panel.size.y) * 0.5
	)
	# The help page sizes itself from its own content, which can be taller than
	# the size field still reports when this runs; centring on the combined
	# minimum instead keeps it from hanging off the bottom of the screen.
	var help_size: Vector2 = help_panel.get_combined_minimum_size()
	help_panel.size = help_size
	help_panel.position = Vector2(
		(viewport_size.x - help_size.x) * 0.5,
		(viewport_size.y - help_size.y) * 0.5
	)
