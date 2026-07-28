class_name Dir3DebugPanel
extends Control

const VisualStyle = preload("res://scripts/visual_style.gd")

const PANEL_SIZE := Vector2(268, 700)
const PADDING_X := 18
const PADDING_Y := 16

var game_board
var palette: Dictionary = {}
var title_label: Label
var debug_state_label: Label
var debug_log_label: Label
var mono_font: Font


func initialize(board) -> void:
	game_board = board
	name = "DebugPanel"
	size = PANEL_SIZE
	custom_minimum_size = PANEL_SIZE
	palette = VisualStyle.theme(false)
	mono_font = make_mono_font()
	build_panel()
	refresh()


func build_panel() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = palette["bg"]
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var border := ColorRect.new()
	border.color = palette["hair"]
	border.position = Vector2.ZERO
	border.size = Vector2(1, PANEL_SIZE.y)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

	var content := VBoxContainer.new()
	content.position = Vector2(PADDING_X, PADDING_Y)
	content.size = PANEL_SIZE - Vector2(PADDING_X * 2, PADDING_Y * 2)
	content.add_theme_constant_override("separation", 14)
	add_child(content)

	title_label = make_label("DEBUG", 11, palette["label"])
	title_label.custom_minimum_size.y = 16
	content.add_child(title_label)

	debug_state_label = make_label("", 11, palette["text"])
	debug_state_label.custom_minimum_size.y = 250
	debug_state_label.clip_text = true
	content.add_child(debug_state_label)

	debug_log_label = make_label("", 11, palette["label"])
	debug_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(debug_log_label)


func refresh() -> void:
	if game_board == null or debug_state_label == null:
		return

	debug_state_label.text = game_board.debug_state_text()
	var reversed_logs: Array[String] = []
	for index in range(game_board.debug_lines.size() - 1, -1, -1):
		reversed_logs.append(game_board.debug_lines[index])
	debug_log_label.text = game_board.join_strings(reversed_logs, "\n")


func make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", mono_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func make_mono_font() -> Font:
	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray(["IBM Plex Mono", "Consolas"])
	var font := FontVariation.new()
	font.base_font = system_font
	font.spacing_glyph = 1
	return font
