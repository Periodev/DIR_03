class_name DirPlayerInterface
extends CanvasLayer

const VisualStyle = preload("res://scripts/visual_style.gd")

const HEADER_HEIGHT := 60
const STATUS_HEIGHT := 88
const STAGE_MIN_HEIGHT := 480
const MESSAGE_HEIGHT := 20
const MESSAGE_WIDTH := 640

var game_board
var board_view
var light_theme := false
var palette: Dictionary = {}
var result_active := false

var ui_font: Font
var mono_font: Font
var mono_label_font: Font

var root_panel: PanelContainer
var board_host: CenterContainer
var message_label: Label
var goals_value: Label

var label_tone_labels: Array[Label] = []
var text_tone_labels: Array[Label] = []
var high_tone_labels: Array[Label] = []
var dim_tone_labels: Array[Label] = []
var separators: Array[ColorRect] = []
var buttons: Array[Button] = []
var keycap_labels: Array[Label] = []


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

	var brand := make_label("DIR", 14, mono_label_font)
	high_tone_labels.append(brand)
	left_group.add_child(brand)
	left_group.add_child(make_vertical_separator(16))

	var level_number := make_label("01", 12, mono_font)
	label_tone_labels.append(level_number)
	left_group.add_child(level_number)

	var level_name := make_label("LEVEL TEST", 14, ui_font)
	text_tone_labels.append(level_name)
	left_group.add_child(level_name)
	left_group.add_child(make_vertical_separator(16))
	left_group.add_child(build_header_goals_group())

	var flexible_space := Control.new()
	flexible_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(flexible_space)

	var right_group := HBoxContainer.new()
	right_group.add_theme_constant_override("separation", 8)
	right_group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(right_group)

	var previous_button := make_button("‹", 12, 11, 5)
	previous_button.pressed.connect(show_navigation_unavailable.bind("previous"))
	right_group.add_child(previous_button)

	var next_button := make_button("›", 12, 11, 5)
	next_button.pressed.connect(show_navigation_unavailable.bind("next"))
	right_group.add_child(next_button)

	var undo_spacer := Control.new()
	undo_spacer.custom_minimum_size.x = 8
	right_group.add_child(undo_spacer)

	var undo_button := make_button("UNDO · Z", 12, 12, 6)
	undo_button.pressed.connect(game_board.undo_last_command)
	right_group.add_child(undo_button)

	var reset_button := make_button("RESET · R", 12, 12, 6)
	reset_button.pressed.connect(game_board.reset_level)
	right_group.add_child(reset_button)

	header.add_child(make_horizontal_separator(false))
	return header


func build_stage() -> Control:
	var stage := MarginContainer.new()
	stage.name = "Stage"
	stage.custom_minimum_size.y = STAGE_MIN_HEIGHT
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_constant_override("margin_left", 24)
	stage.add_theme_constant_override("margin_top", 52)
	stage.add_theme_constant_override("margin_right", 24)
	stage.add_theme_constant_override("margin_bottom", 44)

	var stage_center := CenterContainer.new()
	stage_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(stage_center)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 32)
	stage_center.add_child(content)

	board_host = CenterContainer.new()
	board_host.name = "BoardHost"
	content.add_child(board_host)
	board_host.add_child(board_view)

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
	status.custom_minimum_size.y = STATUS_HEIGHT
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

	var flexible_space := Control.new()
	flexible_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(flexible_space)
	row.add_child(build_key_hints())

	return status


func build_header_goals_group() -> HBoxContainer:
	var group := HBoxContainer.new()
	group.add_theme_constant_override("separation", 8)
	group.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var title := make_label("GOALS", 10, mono_label_font)
	label_tone_labels.append(title)
	group.add_child(title)

	goals_value = make_label("0", 12, mono_font)
	high_tone_labels.append(goals_value)
	group.add_child(goals_value)
	return group


func build_key_hints() -> HBoxContainer:
	var hints := HBoxContainer.new()
	hints.add_theme_constant_override("separation", 16)
	hints.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_key_hint(hints, "← ↑ ↓ →", "PUSH")
	add_key_hint(hints, "X", "INSTALL")
	add_key_hint(hints, "SPACE", "TRIGGER")
	return hints


func add_key_hint(parent: HBoxContainer, key_text: String, action_text: String) -> void:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", 7)
	parent.add_child(item)

	var keycap := make_label(key_text, 11, mono_font)
	keycap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keycap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	keycap_labels.append(keycap)
	item.add_child(keycap)

	var action := make_label(action_text, 12, ui_font)
	label_tone_labels.append(action)
	item.add_child(action)


func make_label(text: String, font_size: int, font: Font) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func make_button(text: String, font_size: int, padding_x: int, padding_y: int) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", mono_font)
	button.add_theme_font_size_override("font_size", font_size)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.set_meta("padding_x", padding_x)
	button.set_meta("padding_y", padding_y)
	buttons.append(button)
	return button


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

	var filled_goals := 0
	for goal_cell in game_board.goal_cells:
		if game_board.find_block_index_at(goal_cell) != -1:
			filled_goals += 1
	goals_value.text = "%s / %s" % [filled_goals, game_board.goal_cells.size()]


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


func show_navigation_unavailable(direction: String) -> void:
	set_message("No %s level is loaded." % direction)


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
		var normal_background := Color.TRANSPARENT
		var normal_border: Color = palette["stroke"]
		var normal_text: Color = palette["text"]
		var hover_background: Color = (
			normal_background
			if not light_theme
			else palette["hover_bg"]
		)
		var hover_border: Color = (
			normal_border
			if light_theme
			else palette["hover_stroke"]
		)
		var hover_text: Color = palette["text_hi"]

		button.add_theme_stylebox_override(
			"normal",
			make_button_style(normal_background, normal_border, padding_x, padding_y)
		)
		button.add_theme_stylebox_override(
			"hover",
			make_button_style(hover_background, hover_border, padding_x, padding_y)
		)
		button.add_theme_stylebox_override(
			"pressed",
			make_button_style(normal_background, palette["text_hi"], padding_x, padding_y)
		)
		button.add_theme_stylebox_override(
			"focus",
			make_button_style(Color.TRANSPARENT, Color.TRANSPARENT, padding_x, padding_y)
		)
		button.add_theme_color_override("font_color", normal_text)
		button.add_theme_color_override("font_hover_color", hover_text)
		button.add_theme_color_override("font_pressed_color", hover_text)


func apply_keycap_styles() -> void:
	for keycap in keycap_labels:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		set_style_border(style, palette["stroke"])
		style.content_margin_left = 7
		style.content_margin_right = 7
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		keycap.add_theme_stylebox_override("normal", style)
		keycap.add_theme_color_override("font_color", palette["text"])


func make_button_style(
	background: Color,
	border: Color,
	padding_x: int,
	padding_y: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	set_style_border(style, border)
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
