extends "res://scripts/game_board.gd"

const PlayerBoardView = preload("res://scripts/player_board_view.gd")
const PlayerInterface = preload("res://scripts/player_interface.gd")
const HELD_MOVE_INITIAL_DELAY_SECONDS := 0.30
const HELD_MOVE_REPEAT_SECONDS := 0.20

var held_move_commands: Array[String] = []
var held_move_time_remaining := 0.0


func _ready() -> void:
	undo_enabled = true
	super()


func create_board_view():
	var player_view: DirPlayerBoardView = PlayerBoardView.new()
	player_view.set_grid_lines_visible(Campaign.grid_lines_visible)
	return player_view


func create_game_hud():
	return PlayerInterface.new()


func _process(delta: float) -> void:
	if held_move_commands.is_empty():
		return
	held_move_time_remaining -= delta
	if held_move_time_remaining > 0.0 or input_locked or level_completed:
		return

	var move_command: String = String(held_move_commands.back())
	execute_command(move_command)
	held_move_time_remaining = HELD_MOVE_REPEAT_SECONDS


func _unhandled_input(event: InputEvent) -> void:
	if SceneTransition.is_active():
		clear_held_movement()
		return
	if event is InputEventKey and event.echo:
		return
	var move_command := movement_command(event)
	if not move_command.is_empty():
		var key_event: InputEventKey = event
		update_held_move(move_command, key_event.pressed)
		if not key_event.pressed:
			return
	if event.is_action_pressed("reset_level"):
		clear_held_movement()
		reset_level()
		return
	if is_quick_complete_key(event):
		clear_held_movement()
		complete_level_for_testing()
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

	if not move_command.is_empty():
		execute_command(move_command)
	elif event.is_action_pressed("install_vector"):
		execute_command("X")
	elif event.is_action_pressed("trigger_vector"):
		execute_command("T")


func movement_command(event: InputEvent) -> String:
	if not event is InputEventKey:
		return ""
	if event.is_action_pressed("move_up") or event.is_action_released("move_up"):
		return "U"
	if event.is_action_pressed("move_down") or event.is_action_released("move_down"):
		return "D"
	if event.is_action_pressed("move_left") or event.is_action_released("move_left"):
		return "L"
	if event.is_action_pressed("move_right") or event.is_action_released("move_right"):
		return "R"
	return ""


func update_held_move(move_command: String, pressed: bool) -> void:
	var was_current: bool = (
		not held_move_commands.is_empty()
		and String(held_move_commands.back()) == move_command
	)
	held_move_commands.erase(move_command)
	if pressed:
		held_move_commands.append(move_command)
		held_move_time_remaining = HELD_MOVE_INITIAL_DELAY_SECONDS
	elif was_current and not held_move_commands.is_empty():
		held_move_time_remaining = HELD_MOVE_INITIAL_DELAY_SECONDS


func clear_held_movement() -> void:
	held_move_commands.clear()
	held_move_time_remaining = 0.0


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


func is_quick_complete_key(event: InputEvent) -> bool:
	if not Campaign.DEBUG_SHORTCUTS_ENABLED:
		return false
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return key_event.pressed and not key_event.echo and key_event.keycode == KEY_F4


func return_to_world_map() -> void:
	Campaign.leave_active_level()
	SceneTransition.transition_to(Campaign.level_select_scene_path)
