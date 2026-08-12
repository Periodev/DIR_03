extends CanvasLayer

var score_label: Label
var combo_label: Label
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
	# Score and combo - top left
	score_label = Label.new()
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 56)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_label.position = Vector2(20, 8)
	score_label.size = Vector2(280, 64)
	add_child(score_label)

	combo_label = Label.new()
	combo_label.text = ""
	combo_label.add_theme_font_size_override("font_size", 32)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	combo_label.position = Vector2(20, 68)
	combo_label.size = Vector2(280, 42)
	add_child(combo_label)

	# Inventory container - bottom
	inventory_panel = PanelContainer.new()
	inventory_panel.position = Vector2(20, 700)
	inventory_panel.size = Vector2(760, 60)
	add_child(inventory_panel)

	var inv_hbox = HBoxContainer.new()
	inv_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inv_hbox.add_theme_constant_override("separation", 10)
	inventory_panel.add_child(inv_hbox)

	ultimate_action_label = Label.new()
	ultimate_action_label.text = "[Z] ULT"
	ultimate_action_label.add_theme_font_size_override("font_size", 20)
	ultimate_action_label.add_theme_color_override("font_color", Color(0.28, 0.92, 0.48))
	ultimate_action_label.custom_minimum_size = Vector2(104, 36)
	ultimate_action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ultimate_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_hbox.add_child(ultimate_action_label)

	dash_action_label = Label.new()
	dash_action_label.text = "[X] DASH"
	dash_action_label.add_theme_font_size_override("font_size", 20)
	dash_action_label.add_theme_color_override("font_color", Color("#C8E64A"))
	dash_action_label.custom_minimum_size = Vector2(116, 36)
	dash_action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dash_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_hbox.add_child(dash_action_label)

	var bonus_separator := VSeparator.new()
	inv_hbox.add_child(bonus_separator)

	var q_label = Label.new()
	q_label.text = "DIR"
	q_label.add_theme_font_size_override("font_size", 20)
	inv_hbox.add_child(q_label)

	energy_container = HBoxContainer.new()
	energy_container.add_theme_constant_override("separation", 2)
	inv_hbox.add_child(energy_container)
	for _i in 4:
		var energy_slot := DIRExtraEnergySlot.new()
		energy_container.add_child(energy_slot)
		energy_slots.append(energy_slot)

	var energy_separator := VSeparator.new()
	inv_hbox.add_child(energy_separator)

	inventory_container = HBoxContainer.new()
	inventory_container.add_theme_constant_override("separation", 4)
	inv_hbox.add_child(inventory_container)

	var sep = VSeparator.new()
	inv_hbox.add_child(sep)

	hold_label = Label.new()
	hold_label.text = "HOLD "
	hold_label.add_theme_font_size_override("font_size", 20)
	inv_hbox.add_child(hold_label)

	hold_slot = Label.new()
	hold_slot.text = "-"
	hold_slot.add_theme_font_size_override("font_size", 28)
	hold_slot.custom_minimum_size = Vector2(72, 36)
	hold_slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_hbox.add_child(hold_slot)

	hold_container = inv_hbox

	message_label = Label.new()
	message_label.text = "WASD: Move | Space: Wait | R: Restart"
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.position = Vector2(0, 770)
	message_label.size = Vector2(800, 30)
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
	gameover_max_combo.text = "MAX COMBO x0"
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

	for i in _max_slots:
		var slot = Label.new()
		slot.text = "-"
		slot.add_theme_font_size_override("font_size", 28)
		slot.custom_minimum_size = Vector2(36, 36)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	for i in _max_slots:
		if i < inv.queue.size():
			slot_labels[i].text = CharacterData.DIR_ARROWS[inv.queue[i]]
		else:
			slot_labels[i].text = "-"

	if _has_hold:
		hold_slot.text = CharacterData.DIR_ARROWS[inv.hold] if inv.hold != CharacterData.Direction.NONE else "-"
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
	if combo >= 2:
		combo_label.text = "COMBO x%d" % combo
	else:
		combo_label.text = ""

func update_energy(quarter_units: int, bonus_step_armed: bool, ultimate_steps: int) -> void:
	for i in energy_slots.size():
		var slot_quarter_units: int = clampi(quarter_units - i * 4, 0, 4)
		var fill_ratio: float = float(slot_quarter_units) / 4.0
		energy_slots[i].set_fill_ratio(fill_ratio)
	dash_action_label.modulate = Color.WHITE if quarter_units >= 4 or bonus_step_armed else Color(1.0, 1.0, 1.0, 0.28)
	ultimate_action_label.modulate = Color.WHITE if quarter_units >= 16 or ultimate_steps > 0 else Color(1.0, 1.0, 1.0, 0.28)
	if ultimate_steps > 0:
		ultimate_action_label.text = "[Z] ULT %d" % ultimate_steps
	else:
		ultimate_action_label.text = "[Z] ULT"

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
	gameover_max_combo.text = "MAX COMBO x%d" % max_combo
	gameover_panel.visible = true

func hide_game_over() -> void:
	gameover_panel.visible = false

func _layout_ui() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	score_label.position = Vector2(20, 8)
	score_label.size = Vector2(280, 64)

	combo_label.position = Vector2(20, 68)
	combo_label.size = Vector2(280, 42)

	var inventory_width: float = min(viewport_size.x - 40.0, 960.0)
	var inventory_x: float = (viewport_size.x - inventory_width) * 0.5
	var inventory_y: float = viewport_size.y - 100.0
	inventory_panel.position = Vector2(inventory_x, inventory_y)
	inventory_panel.size = Vector2(inventory_width, 60)

	message_label.position = Vector2(0, viewport_size.y - 30.0)
	message_label.size = Vector2(viewport_size.x, 30)

	ai_status_label.position = Vector2(20, 116)
	ai_status_label.size = Vector2(150, 30)
	ai_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	gameover_panel.position = Vector2(
		(viewport_size.x - gameover_panel.size.x) * 0.5,
		(viewport_size.y - gameover_panel.size.y) * 0.5
	)
