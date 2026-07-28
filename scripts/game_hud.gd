class_name Dir3GameHud
extends CanvasLayer

const VisualStyle = preload("res://scripts/debug_style.gd")

var game_board
var message_label: Label
var result_label: Label


func initialize(board, _board_view = null) -> void:
	game_board = board
	name = "HudLayer"
	add_status_labels()


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


func refresh() -> void:
	pass


func set_message(text: String) -> void:
	message_label.text = text


func show_result(text: String) -> void:
	result_label.text = text
	result_label.visible = true


func clear_result() -> void:
	result_label.text = ""
	result_label.visible = false
