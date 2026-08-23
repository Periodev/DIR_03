extends Node

const ComboBotMCTSScript = preload("res://scripts/extra_mode/ComboBotMCTS.gd")
const ComboBotTunedScript = preload("res://scripts/extra_mode/ComboBotTuned.gd")
const AI_ACTION_INTERVAL_SECONDS := 0.16
const WINDOW_BACKGROUND_COLOR := Color("#0C0E11")

@onready var board: Node2D = $Board
@onready var hud: CanvasLayer = $HUD

var combo_bot_mcts: DIRExtraComboBotMCTS
var combo_bot_tuned: DIRExtraComboBotTuned
# null = no AI driving input; otherwise whichever of the two bots above is
# active. Only one can run at a time, so this doubles as the "which" and the
# "is any AI on" state instead of tracking them separately.
var active_bot: DIRExtraComboBot = null
var _ai_action_cooldown: float = 0.0
var _buffered_move_direction: int = CharacterData.Direction.NONE
var _previous_clear_color := Color.BLACK

func _ready() -> void:
	_previous_clear_color = RenderingServer.get_default_clear_color()
	RenderingServer.set_default_clear_color(WINDOW_BACKGROUND_COLOR)
	combo_bot_mcts = ComboBotMCTSScript.new()
	combo_bot_tuned = ComboBotTunedScript.new()
	board.setup_character("PLN")
	hud.setup("PLN")

	board.game_over_signal.connect(_on_game_over)
	board.board_updated.connect(_on_board_updated)
	board.spawn_hit_started.connect(_on_spawn_hit_started)
	board.score_manager.score_changed.connect(hud.update_score)
	board.score_manager.combo_changed.connect(hud.update_combo)
	board.score_manager.bonus_scored.connect(hud.show_score_bonus)
	hud.nav_action_requested.connect(_on_nav_action_requested)

	_on_board_updated()
	_update_ai_status_label()

func _exit_tree() -> void:
	RenderingServer.set_default_clear_color(_previous_clear_color)

func _process(delta: float) -> void:
	if hud.is_help_visible():
		return
	_execute_buffered_move_if_ready()
	if active_bot == null or board.game_state.is_game_over():
		return
	_ai_action_cooldown = maxf(0.0, _ai_action_cooldown - delta)
	if _ai_action_cooldown > 0.0 or not board.game_state.is_idle():
		return
	var action: int = active_bot.choose_action(board)
	if action == DIRExtraComboBot.ACTION_NONE:
		return
	_execute_ai_action(action)
	_ai_action_cooldown = AI_ACTION_INTERVAL_SECONDS

func _execute_ai_action(action: int) -> void:
	match action:
		DIRExtraComboBot.ACTION_MOVE:
			board.try_move(active_bot.chosen_direction)
		DIRExtraComboBot.ACTION_DASH:
			board.try_energy_bonus_step()
		DIRExtraComboBot.ACTION_ULT:
			board.try_energy_ultimate()
		DIRExtraComboBot.ACTION_WAIT:
			board.try_wait()
	_on_board_updated()

func _execute_buffered_move_if_ready() -> void:
	if _buffered_move_direction == CharacterData.Direction.NONE:
		return
	if active_bot != null or board.game_state.is_game_over() or not board.game_state.is_idle():
		return
	var direction: int = _buffered_move_direction
	_buffered_move_direction = CharacterData.Direction.NONE
	board.try_move(direction)

func _toggle_bot(bot: DIRExtraComboBot) -> void:
	active_bot = null if active_bot == bot else bot
	_buffered_move_direction = CharacterData.Direction.NONE
	_ai_action_cooldown = 0.0
	_update_ai_status_label()

func _update_ai_status_label() -> void:
	if active_bot == combo_bot_mcts:
		hud.update_ai_status("[F4] SEARCH")
	elif active_bot == combo_bot_tuned:
		hud.update_ai_status("[F5] TUNED ON")
	else:
		hud.update_ai_status("[F4] SEARCH  [F5] TUNED")

func _return_to_title() -> void:
	_buffered_move_direction = CharacterData.Direction.NONE
	SceneTransition.transition_to(Campaign.TITLE_SCREEN_SCENE_PATH)

func _toggle_help() -> void:
	_buffered_move_direction = CharacterData.Direction.NONE
	hud.toggle_help()

func _restart_game() -> void:
	_buffered_move_direction = CharacterData.Direction.NONE
	board.restart()
	hud.setup("PLN")
	_on_board_updated()
	_update_ai_status_label()

func _on_nav_action_requested(action: StringName) -> void:
	match action:
		&"title":
			_return_to_title()
		&"help":
			_toggle_help()
		&"restart":
			_restart_game()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var keycode: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode

	if hud.is_help_visible():
		if keycode in [KEY_ESCAPE, KEY_F1, KEY_SPACE]:
			_toggle_help()
		get_viewport().set_input_as_handled()
		return

	if keycode == KEY_ESCAPE:
		_return_to_title()
		get_viewport().set_input_as_handled()
		return

	if keycode == KEY_F1:
		_toggle_help()
		get_viewport().set_input_as_handled()
		return

	if keycode == KEY_F4:
		_toggle_bot(combo_bot_mcts)
		get_viewport().set_input_as_handled()
		return

	if keycode == KEY_F5:
		_toggle_bot(combo_bot_tuned)
		get_viewport().set_input_as_handled()
		return

	# Restart
	if keycode == KEY_R:
		_restart_game()
		get_viewport().set_input_as_handled()
		return

	if active_bot != null:
		get_viewport().set_input_as_handled()
		return

	# Debug: fill energy to max (F2)
	if keycode == KEY_F2:
		board.debug_fill_energy()
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
		if board.game_state.is_idle():
			board.try_move(dir)
		else:
			_buffered_move_direction = int(dir)
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

	# Spend one energy slot to make the next action a dash step (X)
	if keycode == KEY_X:
		board.try_energy_bonus_step()
		_on_board_updated()
		get_viewport().set_input_as_handled()
		return

	# Spend full energy on ULT (Z)
	if keycode == KEY_Z:
		board.try_energy_ultimate()
		_on_board_updated()
		get_viewport().set_input_as_handled()
		return

func _on_board_updated() -> void:
	hud.update_inventory(board.inventory)
	hud.update_score(board.score_manager.score)
	hud.update_combo(
		board.score_manager.combo_counter if board.score_manager.ENABLE_COMBO_BONUS else 0,
		board.score_manager.tier5_streak
	)
	hud.update_energy(
		board.get_energy_quarter_units(),
		board.bonus_step_armed,
		board.get_ultimate_dashes_remaining(),
		board.get_bonus_step_cost()
	)
	hud.update_energy_gain(board.get_last_energy_gain())
	hud.update_turns(board.survival_turns)
	hud.update_state(board.game_state.current_state)

func _on_spawn_hit_started(slot_count: int, energy_slot_index: int) -> void:
	if energy_slot_index >= 0:
		hud.play_energy_hit(energy_slot_index)
	else:
		hud.play_inventory_hit(slot_count)

func _on_game_over(final_score: int) -> void:
	_buffered_move_direction = CharacterData.Direction.NONE
	hud.show_game_over(final_score, board.score_manager.max_tier5_streak)
