extends "res://scripts/game_board.gd"


func _ready() -> void:
	undo_enabled = true
	super()


func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return

	if event.is_action_pressed("reset_level"):
		reset_level()
		return
	if event.is_action_pressed("undo_command"):
		undo_last_command()
		return
	if level_completed:
		return

	if event.is_action_pressed("move_up"):
		execute_command("U")
	elif event.is_action_pressed("move_down"):
		execute_command("D")
	elif event.is_action_pressed("move_left"):
		execute_command("L")
	elif event.is_action_pressed("move_right"):
		execute_command("R")
	elif event.is_action_pressed("install_vector"):
		execute_command("X")
	elif event.is_action_pressed("trigger_vector"):
		execute_command("T")
