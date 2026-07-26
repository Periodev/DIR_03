class_name Dir3GameHud
extends CanvasLayer

const VisualStyle = preload("res://scripts/visual_style.gd")

var game_board
var debug_panel: Control
var message_label: Label
var result_label: Label
var debug_state_label: Label
var debug_log_label: Label


func initialize(board) -> void:
	game_board = board
	name = "HudLayer"
	add_status_labels()
	add_debug_panel()


func add_status_labels() -> void:
	message_label = Label.new()
	message_label.position = Vector2(96, 24)
	message_label.add_theme_font_size_override("font_size", 16)
	add_child(message_label)

	result_label = Label.new()
	result_label.position = Vector2(96, 52)
	result_label.size = Vector2(950, 32)
	result_label.add_theme_font_size_override("font_size", 16)
	result_label.add_theme_color_override(
		"font_color",
		VisualStyle.GOAL_MARKER_COLOR
	)
	result_label.visible = false
	add_child(result_label)


func add_debug_panel() -> void:
	debug_panel = Control.new()
	debug_panel.name = "DebugPanel"
	debug_panel.position = VisualStyle.DEBUG_PANEL_POSITION
	debug_panel.size = Vector2(300, 700)
	add_child(debug_panel)

	var panel := ColorRect.new()
	panel.size = Vector2(300, 700)
	panel.color = VisualStyle.PANEL_COLOR
	debug_panel.add_child(panel)

	var title_label := Label.new()
	title_label.text = "Debug"
	title_label.position = Vector2(16, 14)
	title_label.add_theme_font_size_override("font_size", 20)
	debug_panel.add_child(title_label)

	debug_state_label = Label.new()
	debug_state_label.position = Vector2(16, 48)
	debug_state_label.size = Vector2(270, 260)
	debug_state_label.add_theme_font_size_override("font_size", 14)
	debug_panel.add_child(debug_state_label)

	debug_log_label = Label.new()
	debug_log_label.position = Vector2(16, 320)
	debug_log_label.size = Vector2(270, 360)
	debug_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_log_label.add_theme_font_size_override("font_size", 13)
	debug_panel.add_child(debug_log_label)


func refresh() -> void:
	debug_state_label.text = game_board.debug_state_text()
	debug_log_label.text = game_board.join_strings(game_board.debug_lines, "\n")


func set_message(text: String) -> void:
	message_label.text = text


func show_result(text: String) -> void:
	result_label.text = text
	result_label.visible = true


func clear_result() -> void:
	result_label.text = ""
	result_label.visible = false


func set_debug_panel_position(panel_position: Vector2) -> void:
	if debug_panel != null:
		debug_panel.position = panel_position
