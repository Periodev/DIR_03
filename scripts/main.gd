extends "res://scripts/game_board.gd"


func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return

	if event.is_action_pressed("reset_level"):
		reset_level()
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
