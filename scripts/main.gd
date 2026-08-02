extends "res://scripts/game_board.gd"

const PlayerBoardView = preload("res://scripts/player_board_view.gd")
const PlayerInterface = preload("res://scripts/player_interface.gd")


func _ready() -> void:
	undo_enabled = true
	super()


func create_board_view():
	return PlayerBoardView.new()


func create_game_hud():
	return PlayerInterface.new()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_level"):
		reset_level()
		return
	if Campaign.has_active_level() and (
		(level_completed and is_confirm_key(event)) or is_cancel_key(event)
	):
		return_to_world_map()
		return
	if input_locked:
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


func is_confirm_key(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return (
		key_event.pressed
		and not key_event.echo
		and (
			key_event.keycode == KEY_ENTER
			or key_event.keycode == KEY_KP_ENTER
			or key_event.keycode == KEY_SPACE
		)
	)


func is_cancel_key(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE


func return_to_world_map() -> void:
	Campaign.leave_active_level()
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")
