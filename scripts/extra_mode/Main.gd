extends Node

const ChainBotScript = preload("res://scripts/extra_mode/ChainBot.gd")
const AI_ACTION_INTERVAL_SECONDS := 0.16

@onready var board: Node2D = $Board
@onready var hud: CanvasLayer = $HUD

var chain_bot: DIRExtraChainBot
var ai_enabled: bool = false
var _ai_action_cooldown: float = 0.0

func _ready() -> void:
	chain_bot = ChainBotScript.new()
	board.setup_character("PLN")
	hud.setup("PLN")

	board.game_over_signal.connect(_on_game_over)
	board.board_updated.connect(_on_board_updated)
	board.spawn_hit_started.connect(_on_spawn_hit_started)
	board.score_manager.score_changed.connect(hud.update_score)
	board.score_manager.combo_changed.connect(hud.update_combo)

	_on_board_updated()
	hud.update_ai_status(ai_enabled)

func _process(delta: float) -> void:
	if not ai_enabled or board.game_state.is_game_over():
		return
	_ai_action_cooldown = maxf(0.0, _ai_action_cooldown - delta)
	if _ai_action_cooldown > 0.0 or not board.game_state.is_idle():
		return
	var action: int = chain_bot.choose_action(board)
	if action == DIRExtraComboBot.ACTION_NONE:
		return
	_execute_ai_action(action)
	_ai_action_cooldown = AI_ACTION_INTERVAL_SECONDS

func _execute_ai_action(action: int) -> void:
	match action:
		DIRExtraComboBot.ACTION_MOVE:
			board.try_move(chain_bot.chosen_direction)
		DIRExtraComboBot.ACTION_DASH:
			board.try_energy_bonus_step()
		DIRExtraComboBot.ACTION_ULT:
			board.try_energy_ultimate()
		DIRExtraComboBot.ACTION_WAIT:
			board.try_wait()
	_on_board_updated()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var keycode: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode

	if keycode == KEY_ESCAPE:
		SceneTransition.transition_to(Campaign.TITLE_SCREEN_SCENE_PATH)
		get_viewport().set_input_as_handled()
		return

	if keycode == KEY_F4:
		ai_enabled = not ai_enabled
		_ai_action_cooldown = 0.0
		hud.update_ai_status(ai_enabled)
		get_viewport().set_input_as_handled()
		return

	# Restart
	if keycode == KEY_R:
		board.restart()
		hud.setup("PLN")
		_on_board_updated()
		hud.update_ai_status(ai_enabled)
		get_viewport().set_input_as_handled()
		return

	if ai_enabled:
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
	hud.update_combo(board.score_manager.combo_counter if board.score_manager.ENABLE_COMBO_BONUS else 0)
	hud.update_energy(
		board.get_energy_quarter_units(),
		board.bonus_step_armed,
		board.get_ultimate_dashes_remaining()
	)
	hud.update_state(board.game_state.current_state)

func _on_spawn_hit_started(slot_count: int) -> void:
	hud.play_inventory_hit(slot_count)

func _on_game_over(final_score: int) -> void:
	hud.show_game_over(final_score, board.score_manager.max_combo)
