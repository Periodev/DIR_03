class_name DirPlayerInterface
extends CanvasLayer

const VisualStyle = preload("res://scripts/visual_style.gd")
const MOVE_KEYS_TEXTURE = preload("res://shapes/ic_input_arrow-keys_01.svg")
const INSTALL_KEY_TEXTURE = preload(
	"res://assets/input_prompts/keyboard_x_outline.svg"
)
const RELEASE_KEY_TEXTURE = preload(
	"res://assets/input_prompts/keyboard_space_outline.svg"
)
const LEVEL_KEY_TEXTURE = preload(
	"res://assets/input_prompts/keyboard_escape_outline.svg"
)
const UNDO_KEY_TEXTURE = preload(
	"res://assets/input_prompts/keyboard_z_outline.svg"
)
const RESET_KEY_TEXTURE = preload(
	"res://assets/input_prompts/keyboard_r_outline.svg"
)

const HEADER_HEIGHT := 68
const HEADER_LEVEL_NAME_FONT_SIZE := 30
const HEADER_GOAL_LABEL_FONT_SIZE := 18
const HEADER_GOAL_VALUE_FONT_SIZE := 22
const HEADER_BUTTON_FONT_SIZE := 18
const HEADER_KEY_ICON_SIZE := 40
const HEADER_ACTION_GAP := 8
const HEADER_ACTION_TEXT_OFFSET_Y := 1
const BOARD_GOAL_GAP := 4
const BASE_STATUS_HEIGHT := 88
const STAGE_HORIZONTAL_MARGIN := 24
const STAGE_TOP_MARGIN := 52
const STAGE_BOTTOM_MARGIN := 44
const STAGE_CONTENT_SEPARATION := 32
const BOARD_CELL_SIZE_MAX := float(VisualStyle.PLAYER_CELL_SIZE)
const BOARD_CELL_SIZE_MIN := 16.0
const MESSAGE_HEIGHT := 20
const MESSAGE_WIDTH := 640
const CONTROL_HINT_SCALE := 2.0
const CONTROL_HINT_ACTION_FONT_SIZE := 12
const CONTROL_HINT_VERTICAL_PADDING := 48
const CONTROL_HINT_MOVE_ICON_BASE_SIZE := 44
const CONTROL_HINT_GROUP_SEPARATION := 44
const CONTROL_HINT_INACTIVE_ALPHA := 0.35

var game_board
var board_view
var light_theme := false
var palette: Dictionary = {}
var result_active := false
var tutorial_controls_stage := 0

var ui_font: Font
var mono_font: Font
var mono_label_font: Font

var root_panel: PanelContainer
var board_host: CenterContainer
var message_label: Label
var goals_value: Label
var direction_hint: HBoxContainer
var install_hint: HBoxContainer
var release_hint: HBoxContainer

var label_tone_labels: Array[Label] = []
var text_tone_labels: Array[Label] = []
var high_tone_labels: Array[Label] = []
var dim_tone_labels: Array[Label] = []
var separators: Array[ColorRect] = []
var buttons: Array[Button] = []
var keycap_icons: Array[TextureRect] = []


func _ready() -> void:
	get_viewport().size_changed.connect(fit_board_to_viewport)
	call_deferred("fit_board_to_viewport")


func initialize(board, player_board_view) -> void:
	game_board = board
	board_view = player_board_view
	name = "HudLayer"
	palette = VisualStyle.theme(light_theme)
	ui_font = make_system_font(["IBM Plex Sans", "Noto Sans TC", "Arial"])
	mono_font = make_system_font(["IBM Plex Mono", "Consolas"])
	mono_label_font = make_spaced_font(mono_font, 2)
	build_interface()
	apply_palette()
	refresh()


func build_interface() -> void:
	root_panel = PanelContainer.new()
	root_panel.name = "PlayerInterface"
	add_child(root_panel)
	root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 0)
	root_panel.add_child(page)

	page.add_child(build_header())
	page.add_child(build_stage())
	page.add_child(build_status_bar())


func build_header() -> Control:
	var header := Control.new()
	header.name = "Header"
	header.custom_minimum_size.y = HEADER_HEIGHT
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	header.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	var left_group := HBoxContainer.new()
	left_group.add_theme_constant_override("separation", 12)
	left_group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(left_group)

	var level_button := make_button(
		"LEVEL",
		HEADER_BUTTON_FONT_SIZE,
		4,
		0,
		LEVEL_KEY_TEXTURE
	)
	level_button.pressed.connect(return_to_level_select)
	left_group.add_child(level_button)
	left_group.add_child(make_vertical_separator(22))

	var active_level_name: String = Campaign.active_level_name()
	var level_name_text := "LEVEL TEST" if active_level_name == "" else active_level_name.to_upper()
	var level_name := make_header_label(
		level_name_text,
		HEADER_LEVEL_NAME_FONT_SIZE,
		ui_font
	)
	text_tone_labels.append(level_name)
	left_group.add_child(level_name)

	var flexible_space := Control.new()
	flexible_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(flexible_space)

	var right_group := HBoxContainer.new()
	right_group.add_theme_constant_override("separation", 16)
	right_group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(right_group)

	var undo_button := make_button(
		"UNDO",
		HEADER_BUTTON_FONT_SIZE,
		4,
		0,
		UNDO_KEY_TEXTURE
	)
	undo_button.pressed.connect(game_board.undo_last_command)
	right_group.add_child(undo_button)

	var reset_button := make_button(
		"RESET",
		HEADER_BUTTON_FONT_SIZE,
		4,
		0,
		RESET_KEY_TEXTURE
	)
	reset_button.pressed.connect(game_board.reset_level)
	right_group.add_child(reset_button)

	header.add_child(make_horizontal_separator(false))
	return header


func build_stage() -> Control:
	var stage := MarginContainer.new()
	stage.name = "Stage"
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_constant_override("margin_left", STAGE_HORIZONTAL_MARGIN)
	stage.add_theme_constant_override("margin_top", STAGE_TOP_MARGIN)
	stage.add_theme_constant_override("margin_right", STAGE_HORIZONTAL_MARGIN)
	stage.add_theme_constant_override("margin_bottom", STAGE_BOTTOM_MARGIN)

	var stage_center := CenterContainer.new()
	stage_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(stage_center)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", STAGE_CONTENT_SEPARATION)
	stage_center.add_child(content)

	board_host = CenterContainer.new()
	board_host.name = "BoardHost"
	content.add_child(board_host)
	board_host.add_child(board_view)

	var board_goals := build_goal_group()
	board_goals.position = Vector2(
		0,
		-HEADER_KEY_ICON_SIZE - BOARD_GOAL_GAP
	)
	board_view.add_child(board_goals)

	var message_holder := CenterContainer.new()
	message_holder.custom_minimum_size.y = MESSAGE_HEIGHT
	content.add_child(message_holder)

	message_label = make_label("", 13, ui_font)
	message_label.custom_minimum_size = Vector2(MESSAGE_WIDTH, MESSAGE_HEIGHT)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	message_label.clip_text = true
	dim_tone_labels.append(message_label)
	message_holder.add_child(message_label)

	return stage


func build_status_bar() -> Control:
	var status := Control.new()
	status.name = "StatusBar"
	status.custom_minimum_size.y = control_hint_status_height()
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	status.add_child(make_horizontal_separator(true))

	var margin := MarginContainer.new()
	status.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	margin.add_child(row)

	var left_space := Control.new()
	left_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left_space)
	row.add_child(build_key_hints())
	var right_space := Control.new()
	right_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right_space)

	return status


func build_goal_group() -> HBoxContainer:
	var group := HBoxContainer.new()
	group.add_theme_constant_override("separation", 8)
	group.custom_minimum_size.y = HEADER_KEY_ICON_SIZE
	group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var title := make_header_label(
		"GOAL",
		HEADER_GOAL_LABEL_FONT_SIZE,
		mono_label_font
	)
	label_tone_labels.append(title)
	group.add_child(title)

	goals_value = make_header_label("0", HEADER_GOAL_VALUE_FONT_SIZE, mono_font)
	high_tone_labels.append(goals_value)
	group.add_child(goals_value)
	return group


func build_key_hints() -> HBoxContainer:
	var hints := HBoxContainer.new()
	hints.add_theme_constant_override("separation", CONTROL_HINT_GROUP_SEPARATION)
	hints.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	direction_hint = add_icon_key_hint(hints, MOVE_KEYS_TEXTURE, "MOVE")
	install_hint = add_icon_key_hint(hints, INSTALL_KEY_TEXTURE, "INSTALL", 0.5)
	release_hint = add_icon_key_hint(hints, RELEASE_KEY_TEXTURE, "RELEASE")
	return hints


func add_icon_key_hint(
	parent: HBoxContainer,
	key_texture: Texture2D,
	action_text: String,
	icon_scale: float = 1.0
) -> HBoxContainer:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", 7)
	parent.add_child(item)

	var keycap := TextureRect.new()
	var icon_size := control_hint_icon_size() * icon_scale
	keycap.custom_minimum_size = Vector2(
		icon_size,
		icon_size
	)
	keycap.texture = key_texture
	keycap.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	keycap.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	keycap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keycap_icons.append(keycap)
	item.add_child(keycap)

	var action := make_label(
		action_text,
		control_hint_font_size(CONTROL_HINT_ACTION_FONT_SIZE),
		ui_font
	)
	text_tone_labels.append(action)
	item.add_child(action)
	return item

func control_hint_font_size(base_size: int) -> int:
	return maxi(8, roundi(base_size * CONTROL_HINT_SCALE))


func control_hint_icon_size() -> float:
	return maxf(32.0, CONTROL_HINT_MOVE_ICON_BASE_SIZE * CONTROL_HINT_SCALE)


func control_hint_status_height() -> float:
	return maxf(
		BASE_STATUS_HEIGHT,
		maxf(
			control_hint_font_size(CONTROL_HINT_ACTION_FONT_SIZE)
			+ CONTROL_HINT_VERTICAL_PADDING,
			control_hint_icon_size()
		)
	)


func make_label(text: String, font_size: int, font: Font) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func make_header_label(text: String, font_size: int, font: Font) -> Label:
	var label := make_label(text, font_size, font)
	label.custom_minimum_size.y = HEADER_KEY_ICON_SIZE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func make_button(
	text: String,
	font_size: int,
	padding_x: int,
	padding_y: int,
	icon: Texture2D = null
) -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = HEADER_KEY_ICON_SIZE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.set_meta("padding_x", padding_x)
	button.set_meta("padding_y", padding_y)

	var content := HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", HEADER_ACTION_GAP)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = padding_x
	content.offset_right = -padding_x

	var keycap := TextureRect.new()
	keycap.custom_minimum_size = Vector2(HEADER_KEY_ICON_SIZE, HEADER_KEY_ICON_SIZE)
	keycap.texture = icon
	keycap.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	keycap.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	keycap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(keycap)

	var text_size: Vector2 = mono_font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	)
	var action_holder := Control.new()
	action_holder.custom_minimum_size = Vector2(
		ceilf(text_size.x),
		HEADER_KEY_ICON_SIZE
	)
	action_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(action_holder)

	var action := make_label(text, font_size, mono_font)
	action.custom_minimum_size.y = HEADER_KEY_ICON_SIZE
	action.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action.add_theme_color_override("font_color", Color.WHITE)
	action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_holder.add_child(action)
	action.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	action.offset_top += HEADER_ACTION_TEXT_OFFSET_Y
	action.offset_bottom += HEADER_ACTION_TEXT_OFFSET_Y
	button.custom_minimum_size.x = (
		HEADER_KEY_ICON_SIZE
		+ HEADER_ACTION_GAP
		+ ceilf(text_size.x)
		+ padding_x * 2
	)
	button.mouse_entered.connect(set_header_button_hovered.bind(button, true))
	button.mouse_exited.connect(set_header_button_hovered.bind(button, false))
	buttons.append(button)
	return button


func set_header_button_hovered(button: Button, hovered: bool) -> void:
	button.modulate = palette["text_hi"] if hovered else palette["text"]


func make_vertical_separator(height: int) -> ColorRect:
	var separator := ColorRect.new()
	separator.custom_minimum_size = Vector2(1, height)
	separator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	separators.append(separator)
	return separator


func make_horizontal_separator(at_top: bool) -> ColorRect:
	var separator := ColorRect.new()
	separator.anchor_right = 1.0
	separator.anchor_top = 0.0 if at_top else 1.0
	separator.anchor_bottom = separator.anchor_top
	separator.offset_top = 0 if at_top else -1
	separator.offset_bottom = separator.offset_top + 1
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	separators.append(separator)
	return separator


func refresh() -> void:
	if game_board == null or goals_value == null:
		return
	fit_board_to_viewport()
	refresh_control_hints()

	var filled_goals := 0
	for goal_cell in game_board.goal_cells:
		if game_board.find_block_index_at(goal_cell) != -1:
			filled_goals += 1
	goals_value.text = "%s / %s" % [filled_goals, game_board.goal_cells.size()]


func fit_board_to_viewport() -> void:
	if (
		root_panel == null
		or board_view == null
		or game_board == null
		or game_board.terrain.is_empty()
		or root_panel.size.x <= 0.0
		or root_panel.size.y <= 0.0
	):
		return

	var board_rows: int = int(game_board.terrain.size())
	var board_columns: int = int(game_board.terrain[0].size())
	if board_rows <= 0 or board_columns <= 0:
		return

	var available_width: float = maxf(
		BOARD_CELL_SIZE_MIN,
		root_panel.size.x - STAGE_HORIZONTAL_MARGIN * 2.0
	)
	var available_height: float = maxf(
		BOARD_CELL_SIZE_MIN,
		root_panel.size.y
		- HEADER_HEIGHT
		- control_hint_status_height()
		- STAGE_TOP_MARGIN
		- STAGE_BOTTOM_MARGIN
		- STAGE_CONTENT_SEPARATION
		- MESSAGE_HEIGHT
	)
	var width_limited_size: float = available_width / float(board_columns)
	var height_limited_size: float = (
		available_height
		/ (float(board_rows) + VisualStyle.WALL_SHADOW_RATIO)
	)
	var fitted_cell_size: float = floorf(minf(
		BOARD_CELL_SIZE_MAX,
		minf(width_limited_size, height_limited_size)
	))
	board_view.set_cell_size(maxf(BOARD_CELL_SIZE_MIN, fitted_cell_size))


func refresh_control_hints() -> void:
	var level_id: String = Campaign.active_level_id
	if level_id == "1-0":
		tutorial_controls_stage = 0
	elif level_id == "1-1":
		if game_board.install_tutorial_target_cell() != Vector2i(-1, -1):
			tutorial_controls_stage = maxi(tutorial_controls_stage, 1)
		if (
			bool(game_board.install_tutorial_completed)
			or not game_board.install_order.is_empty()
		):
			tutorial_controls_stage = 2
	else:
		tutorial_controls_stage = 2

	direction_hint.visible = true
	install_hint.visible = tutorial_controls_stage >= 1
	release_hint.visible = tutorial_controls_stage >= 2
	install_hint.modulate = Color(
		1.0,
		1.0,
		1.0,
		1.0 if game_board.command_will_change_state("X") else CONTROL_HINT_INACTIVE_ALPHA
	)
	release_hint.modulate = Color(
		1.0,
		1.0,
		1.0,
		1.0 if game_board.command_will_change_state("T") else CONTROL_HINT_INACTIVE_ALPHA
	)


func set_message(text: String) -> void:
	result_active = false
	message_label.text = text


func show_result(text: String) -> void:
	result_active = true
	message_label.text = text


func clear_result() -> void:
	if result_active:
		message_label.text = ""
	result_active = false


func set_light_theme(enabled: bool) -> void:
	light_theme = enabled
	palette = VisualStyle.theme(light_theme)
	if board_view != null:
		board_view.set_light_theme(light_theme)
	apply_palette()
	refresh()


func return_to_level_select() -> void:
	if not Campaign.has_active_level():
		return
	if game_board.has_method("clear_held_movement"):
		game_board.clear_held_movement()
	if game_board.has_method("return_to_world_map"):
		game_board.return_to_world_map()


func apply_palette() -> void:
	var root_style := StyleBoxFlat.new()
	root_style.bg_color = palette["app_bg"]
	set_style_border(root_style, palette["grid"])
	root_panel.add_theme_stylebox_override("panel", root_style)

	for separator in separators:
		separator.color = palette["hair"]
	for label in label_tone_labels:
		label.add_theme_color_override("font_color", palette["label"])
	for label in text_tone_labels:
		label.add_theme_color_override("font_color", palette["text"])
	for label in high_tone_labels:
		label.add_theme_color_override("font_color", palette["text_hi"])
	for label in dim_tone_labels:
		label.add_theme_color_override("font_color", palette["text_dim"])

	apply_button_styles()
	apply_keycap_styles()


func apply_button_styles() -> void:
	for button in buttons:
		var padding_x := int(button.get_meta("padding_x"))
		var padding_y := int(button.get_meta("padding_y"))
		var normal_text: Color = palette["text"]
		var hover_text: Color = palette["text_hi"]

		button.add_theme_stylebox_override(
			"normal",
			make_button_style(padding_x, padding_y)
		)
		button.add_theme_stylebox_override(
			"hover",
			make_button_style(padding_x, padding_y)
		)
		button.add_theme_stylebox_override(
			"pressed",
			make_button_style(padding_x, padding_y)
		)
		button.add_theme_stylebox_override(
			"focus",
			make_button_style(padding_x, padding_y)
		)
		button.modulate = hover_text if button.is_hovered() else normal_text


func apply_keycap_styles() -> void:
	for keycap_icon in keycap_icons:
		keycap_icon.modulate = palette["text"]


func make_button_style(padding_x: int, padding_y: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.content_margin_left = padding_x
	style.content_margin_right = padding_x
	style.content_margin_top = padding_y
	style.content_margin_bottom = padding_y
	return style


func set_style_border(style: StyleBoxFlat, color: Color) -> void:
	style.border_color = color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0


func make_system_font(names: Array[String]) -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(names)
	return font


func make_spaced_font(base_font: Font, spacing: int) -> Font:
	var font := FontVariation.new()
	font.base_font = base_font
	font.spacing_glyph = spacing
	return font
