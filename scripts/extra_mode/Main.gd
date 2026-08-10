extends Node

@onready var board: Node2D = $Board
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	board.setup_character("PLN")
	hud.setup("PLN")

	board.game_over_signal.connect(_on_game_over)
	board.board_updated.connect(_on_board_updated)
	board.spawn_hit_started.connect(_on_spawn_hit_started)
	board.score_manager.score_changed.connect(hud.update_score)
	board.score_manager.combo_changed.connect(hud.update_combo)
	board.score_manager.defeat_changed.connect(hud.update_defeats)

	_on_board_updated()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var keycode: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode

	if keycode == KEY_ESCAPE:
		SceneTransition.transition_to(Campaign.TITLE_SCREEN_SCENE_PATH)
		get_viewport().set_input_as_handled()
		return

	# Restart
	if keycode == KEY_R:
		board.restart()
		hud.setup("PLN")
		_on_board_updated()
		get_viewport().set_input_as_handled()
		return

	# Debug: spawn dead cell adjacent to player (F3)
	if keycode == KEY_F3:
		board.debug_spawn_adjacent_dead()
		get_viewport().set_input_as_handled()
		return

	# Debug: preview PLN charge visual (F6)
	if keycode == KEY_F6:
		board.debug_preview_charge()
		get_viewport().set_input_as_handled()
		return

	if board.game_state.is_game_over():
		return

	# Movement
	var dir = CharacterData.key_to_direction(keycode)
	if dir != CharacterData.Direction.NONE:
		board.try_move(dir)
		get_viewport().set_input_as_handled()
		return

	# Wait / character utility (Space)
	if keycode == KEY_SPACE:
		if board.inventory.has_charge_marker:
			board.try_charge_action()
		elif board.inventory.has_hold:
			board.inventory.toggle_hold()
		else:
			board.try_wait()
		_on_board_updated()
		get_viewport().set_input_as_handled()
		return

	# Wait (X)
	if keycode == KEY_X:
		board.try_wait()
		_on_board_updated()
		get_viewport().set_input_as_handled()
		return

	# Ultimate (Z)
	if keycode == KEY_Z:
		board.try_ultimate()
		_on_board_updated()
		get_viewport().set_input_as_handled()
		return

	# Ultimate (Enter)
	if keycode == KEY_ENTER:
		board.try_ultimate()
		_on_board_updated()
		get_viewport().set_input_as_handled()
		return

func _on_board_updated() -> void:
	hud.update_inventory(board.inventory)
	hud.update_score(board.score_manager.score)
	hud.update_combo(board.score_manager.combo_counter if board.score_manager.ENABLE_COMBO_BONUS else 0)
	hud.update_defeats(board.score_manager.defeat_count)
	hud.update_turns(board.survival_turns)
	hud.update_ultimate(board.ultimate_ready, board.get_ultimate_dashes_remaining())
	hud.update_state(board.game_state.current_state)

func _on_spawn_hit_started(slot_count: int) -> void:
	hud.play_inventory_hit(slot_count)

func _on_game_over(final_score: int) -> void:
	hud.show_game_over(final_score)
