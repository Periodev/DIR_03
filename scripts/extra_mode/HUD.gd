extends CanvasLayer

const HeatMeterScript = preload("res://scripts/extra_mode/HeatMeter.gd")

const ENERGY_GAIN_COLOR := Color("#2FD9A0")
const ENERGY_GAIN_IDLE_COLOR := Color(1.0, 1.0, 1.0, 0.28)
const STEP_AVAILABLE_COLOR := Color("#2FD9A0")
const STEP_UNAVAILABLE_COLOR := Color("#4A5058")
const DIRECTION_ACTIVE_COLOR := Color("#7FE85A")
const DIRECTION_EXPIRING_COLOR := Color("#AAB58A")
const DIRECTION_EMPTY_COLOR := Color("#4A5058")
const DASH_AVAILABLE_COLOR := Color("#DFFFE9")
const SIDEBAR_MARGIN := 20.0
const SIDEBAR_WIDTH := 320.0
const STATUS_PANEL_TOP := 158.0
const STATUS_PANEL_HEIGHT := 176.0

var score_label: Label
var combo_label: Label
var heat_meter: Control
var heat_value_label: Label
var energy_gain_label: Label
var inventory_container: HBoxContainer
var inventory_panel: PanelContainer
var energy_container: HBoxContainer
var hold_container: HBoxContainer
var hold_label: Label
var hold_slot: Label
var dash_action_label: Label
var ultimate_action_label: Label
var gameover_panel: PanelContainer
var gameover_score: Label
var gameover_max_combo: Label
var message_label: Label
var ai_status_label: Label

var slot_labels: Array = []
var energy_slots: Array[DIRExtraEnergySlot] = []
var _max_slots: int = 3
var _has_hold: bool = false
var _has_charge_marker: bool = false
var _charge_max: int = 0
var _slot_flash_tweens: Array[Tween] = []

func _ready() -> void:
	# Score and heat - top left
	score_label = Label.new()
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 56)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_label.position = Vector2(20, 8)
	score_label.size = Vector2(280, 64)
	add_child(score_label)

	combo_label = Label.new()
	combo_label.text = "HEAT"
	combo_label.add_theme_font_size_override("font_size", 22)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	combo_label.position = Vector2(20, 72)
	combo_label.size = Vector2(66, 30)
	add_child(combo_label)

	heat_meter = HeatMeterScript.new()
	heat_meter.position = Vector2(84, 78)
	heat_meter.size = Vector2(166, 18)
	add_child(heat_meter)

	heat_value_label = Label.new()
	heat_value_label.text = "0"
	heat_value_label.add_theme_font_size_override("font_size", 20)
	heat_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heat_value_label.position = Vector2(256, 72)
	heat_value_label.size = Vector2(44, 30)
	add_child(heat_value_label)

	# Three-row status panel in the left sidebar.
	inventory_panel = PanelContainer.new()
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

	var q_label = Label.new()
	q_label.text = "DIR"
	q_label.add_theme_font_size_override("font_size", 20)
	energy_row.add_child(q_label)

	energy_container = HBoxContainer.new()
	energy_container.add_theme_constant_override("separation", 2)
	energy_row.add_child(energy_container)
	for _i in 4:
		var energy_slot := DIRExtraEnergySlot.new()
		energy_container.add_child(energy_slot)
		energy_slots.append(energy_slot)

	# What the next kill would add to the bar. Reads +0 while a STEP or an ULT
	# chain is queued, because those kills are energy-sterile.
	energy_gain_label = Label.new()
	energy_gain_label.text = "+0"
	energy_gain_label.add_theme_font_size_override("font_size", 20)
	energy_gain_label.add_theme_color_override("font_color", ENERGY_GAIN_COLOR)
	energy_gain_label.custom_minimum_size = Vector2(44, 36)
	energy_gain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_gain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_row.add_child(energy_gain_label)

	var direction_row := HBoxContainer.new()
	direction_row.alignment = BoxContainer.ALIGNMENT_CENTER
	direction_row.add_theme_constant_override("separation", 6)
	status_vbox.add_child(direction_row)
	status_vbox.add_child(action_row)

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
	message_label.text = "WASD: Move | Space: Wait | R: Restart"
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	message_label.position = Vector2(SIDEBAR_MARGIN, STATUS_PANEL_TOP + STATUS_PANEL_HEIGHT + 10.0)
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

	gameover_max_combo = Label.new()
	gameover_max_combo.text = "MAX HEAT 0"
	gameover_max_combo.add_theme_font_size_override("font_size", 26)
	gameover_max_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameover_max_combo.add_theme_color_override("font_color", Color(0.86, 0.88, 0.91))
	vbox.add_child(gameover_max_combo)

	var restart_hint = Label.new()
	restart_hint.text = "Press R to restart"
	restart_hint.add_theme_font_size_override("font_size", 20)
	restart_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(restart_hint)

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

func update_combo(combo: int) -> void:
	combo_label.text = "HEAT"
	heat_value_label.text = str(combo)
	heat_meter.set_heat(combo)

func update_energy_gain(quarter_units: int) -> void:
	energy_gain_label.text = "+%d" % quarter_units
	energy_gain_label.add_theme_color_override(
		"font_color",
		ENERGY_GAIN_COLOR if quarter_units > 0 else ENERGY_GAIN_IDLE_COLOR
	)

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

func update_ai_status(enabled: bool) -> void:
	ai_status_label.text = "[F4] AI ON" if enabled else "[F4] AI"
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

func _cancel_slot_flashes() -> void:
	for tween in _slot_flash_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_slot_flash_tweens.clear()
	for slot_value in slot_labels:
		var slot: Label = slot_value
		slot.modulate = Color.WHITE

func update_state(_state: int) -> void:
	message_label.text = "WASD: Move | Space: Wait | R: Restart"

func show_game_over(final_score: int, max_combo: int) -> void:
	gameover_score.text = str(final_score)
	gameover_max_combo.text = "MAX HEAT %d" % max_combo
	gameover_panel.visible = true

func _layout_ui() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	score_label.position = Vector2(20, 8)
	score_label.size = Vector2(280, 64)

	combo_label.position = Vector2(20, 72)
	combo_label.size = Vector2(66, 30)
	heat_meter.position = Vector2(84, 78)
	heat_meter.size = Vector2(166, 18)
	heat_value_label.position = Vector2(256, 72)
	heat_value_label.size = Vector2(44, 30)

	var sidebar_width: float = min(SIDEBAR_WIDTH, viewport_size.x - SIDEBAR_MARGIN * 2.0)
	inventory_panel.position = Vector2(SIDEBAR_MARGIN, STATUS_PANEL_TOP)
	inventory_panel.size = Vector2(sidebar_width, STATUS_PANEL_HEIGHT)

	message_label.position = Vector2(SIDEBAR_MARGIN, STATUS_PANEL_TOP + STATUS_PANEL_HEIGHT + 10.0)
	message_label.size = Vector2(sidebar_width, 30)

	ai_status_label.position = Vector2(20, 116)
	ai_status_label.size = Vector2(150, 30)
	ai_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	gameover_panel.position = Vector2(
		(viewport_size.x - gameover_panel.size.x) * 0.5,
		(viewport_size.y - gameover_panel.size.y) * 0.5
	)
