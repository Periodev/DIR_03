extends Node2D

const CharacterImpl_PLN = preload("res://scripts/extra_mode/CharacterImpl_PLN.gd")

const COLS := 5
const ROWS := 5
const SPAWN_CYCLE_STEPS := 2
const SPAWNS_PER_CYCLE := 2
const OPENING_GRACE_TURNS := 1
const ENERGY_HALF_UNITS_MAX := 6
const ENERGY_SLOT_COST := 2
const ULT_DASH_COUNT := 4
const ULT_SLASH_TIP_EXTENSION_RATIO := 0.65
const SPAWN_CELL_TYPE := CharacterData.CellType.DEAD
const BLOCK_OUTER_RING_SPAWN := false
const CELL_SIZE := 100.0
const CELL_GAP := 8.0
const CELL_STEP := CELL_SIZE + CELL_GAP
const SPAWN_HIT_SETTLE_SECONDS := 0.08
const SPAWN_HIT_FEEDBACK_SECONDS := 0.24
const SPAWN_FADE_SECONDS := 0.16

signal game_over_signal(final_score: int)
signal board_updated
signal spawn_hit_started(slot_count: int)

var grid: Array = []  # grid[row][col] = CellType
var player_pos: Vector2i = Vector2i(COLS / 2, ROWS / 2)
var player_facing_dir: int = CharacterData.Direction.UP
var candidate_cells: Array = []  # Array of Vector2i
var cycle_counter: int = 0
var _opening_grace_turns_remaining: int = OPENING_GRACE_TURNS
var _spawn_hit_pending: bool = false
var _spawn_fade_pending: bool = false
var _player_move_visual_pending: bool = false
var _action_animation_pending: bool = false
var _turn_resolution_pending: bool = false
var _turn_freezes_spawn: bool = false
var _suppress_hit_effect_once: bool = false
var _pending_kill_visual: Array[Vector2i] = []  # 正在等待延遲視覺更新的格子
var survival_turns: int = 0
var energy_half_units: int = 0
var bonus_step_armed: bool = false
var ultimate_dashes_remaining: int = 0
var _ultimate_chain_started: bool = false

var inventory: Inventory
var score_manager: ScoreManager
var game_state: GameStateMachine
var current_character: String = "PLN"
var current_attack_mode_override: int = -1

var cell_nodes: Array = []  # cell_nodes[row][col] = Cell node
var player_node: Node2D
var _char_impl  # CharacterImpl_PLN

var _cell_scene: PackedScene
var _hit_effect_scene: PackedScene

func _ready() -> void:
	_cell_scene = load("res://scenes/extra_mode/cell.tscn")
	_hit_effect_scene = load("res://scenes/extra_mode/hit_effect.tscn")
	var player_scene = load("res://scenes/extra_mode/player.tscn")

	inventory = Inventory.new()
	score_manager = ScoreManager.new()
	game_state = GameStateMachine.new()

	# Build grid of cell nodes
	for r in ROWS:
		var row_nodes := []
		for c in COLS:
			var cell = _cell_scene.instantiate()
			cell.grid_pos = Vector2i(c, r)
			cell.position = Vector2(c * CELL_STEP, r * CELL_STEP)
			add_child(cell)
			row_nodes.append(cell)
		cell_nodes.append(row_nodes)

	# Player node
	player_node = player_scene.instantiate()
	add_child(player_node)
	player_node.animation_done.connect(_on_player_animation_done)
	player_node.movement_started.connect(_on_player_movement_started)
	player_node.movement_finished.connect(_finish_player_move_visual)

	get_viewport().size_changed.connect(_update_board_offset)
	_update_board_offset()
	restart()

func setup_character(char_name: String, attack_mode_override: int = -1) -> void:
	current_character = char_name
	current_attack_mode_override = attack_mode_override
	inventory.setup(char_name)
	player_node.set_character(char_name)
	_char_impl = CharacterImpl_PLN.new()

func restart() -> void:
	# Reset grid
	grid.clear()
	for r in ROWS:
		var row := []
		for c in COLS:
			row.append(CharacterData.CellType.LIVE)
		grid.append(row)

	player_pos = Vector2i(COLS / 2, ROWS / 2)
	player_facing_dir = CharacterData.Direction.UP
	candidate_cells.clear()
	cycle_counter = 0
	_opening_grace_turns_remaining = OPENING_GRACE_TURNS
	cycle_resolved = false
	_spawn_hit_pending = false
	_spawn_fade_pending = false
	_player_move_visual_pending = false
	_action_animation_pending = false
	_turn_resolution_pending = false
	_turn_freezes_spawn = false
	_suppress_hit_effect_once = false
	_pending_kill_visual.clear()
	survival_turns = 0
	energy_half_units = 0
	bonus_step_armed = false
	ultimate_dashes_remaining = 0
	_ultimate_chain_started = false
	player_node.cancel_feedback()

	setup_character(current_character, current_attack_mode_override)
	score_manager.reset()
	game_state.reset()

	_refresh_visuals()

func debug_spawn_adjacent_dead() -> void:
	for dv: Vector2i in CharacterData.DIR_VECTOR.values():
		var neighbor: Vector2i = player_pos + dv
		if neighbor.x < 0 or neighbor.x >= COLS or neighbor.y < 0 or neighbor.y >= ROWS:
			continue
		if grid[neighbor.y][neighbor.x] == CharacterData.CellType.LIVE:
			grid[neighbor.y][neighbor.x] = CharacterData.CellType.DEAD
			_refresh_visuals()
			return

func debug_preview_charge() -> void:
	game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
	_sync_player_move_ready()
	player_node.play_attack(player_facing_dir, true, true)

func try_move(dir: int) -> bool:
	if not game_state.is_idle():
		return false
	if _player_move_visual_pending:
		return false
	if ultimate_dashes_remaining > 0:
		return _try_ultimate_dash(dir)
	var is_bonus_step: bool = bonus_step_armed

	var dv = CharacterData.DIR_VECTOR[dir]
	var target = player_pos + dv

	# Bounds check
	if target.x < 0 or target.x >= COLS or target.y < 0 or target.y >= ROWS:
		return false

	var target_type = grid[target.y][target.x]

	if target_type == CharacterData.CellType.LIVE:
		# Move to live cell
		player_facing_dir = dir
		player_pos = target
		if is_bonus_step or not _will_spawn_hit_target_this_turn(target):
			inventory.push(_get_move_memory_token(dir))
			inventory.register_move(dir)
			if not is_bonus_step:
				score_manager.on_move_to_live()

		if is_bonus_step:
			bonus_step_armed = false
			return _finalize_turn_after_action(true, false)
		return _finalize_turn_after_action()

	else:
		# Dead cell - check inventory for matching direction (any position)
		if not _consume_attack_direction(dir):
			return false  # No matching direction in queue
		_clear_attack_prompts()

		var origin := player_pos
		player_facing_dir = dir
		_resolve_attack(dir, target, target_type)
		if grid[target.y][target.x] == CharacterData.CellType.LIVE:
			player_pos = target
			_action_animation_pending = true
			_char_impl.begin_kill_anim(self, origin, target, dir)
			game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
			player_node.emit_animation_done_after(player_node.get_hit_delay(true))
		else:
			_action_animation_pending = true
			game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
			player_node.play_attack(dir, false, true)
		if is_bonus_step:
			bonus_step_armed = false
			return _finalize_turn_after_action(true, false)
		return _finalize_turn_after_action()

func try_charge_action() -> bool:
	if not game_state.is_idle():
		return false
	if not inventory.has_charge_marker:
		return false
	if not inventory.is_charge_full():
		return false
	if inventory.charge_direction == CharacterData.Direction.NONE:
		return false

	var dir := inventory.charge_direction
	var dv = CharacterData.DIR_VECTOR[dir]
	var target = player_pos + dv
	if target.x < 0 or target.x >= COLS or target.y < 0 or target.y >= ROWS:
		return false

	if not inventory.consume_charge():
		return false

	player_facing_dir = dir
	var target_type = grid[target.y][target.x]
	if target_type == CharacterData.CellType.LIVE:
		player_pos = target
		score_manager.on_move_to_live()
	else:
		var pos_before_attack := player_pos
		if _get_attack_mode() == CharacterData.AttackMode.DASH:
			_resolve_attack(dir, target, target_type)
			if grid[target.y][target.x] == CharacterData.CellType.LIVE:
				player_pos = target
		else:
			_resolve_attack(dir, target, target_type)
		if player_pos == pos_before_attack:
			var attack_hit: bool = (grid[target.y][target.x] == CharacterData.CellType.LIVE)
			var was_dash := _get_attack_mode() == CharacterData.AttackMode.DASH
			_action_animation_pending = true
			game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
			player_node.play_attack(dir, attack_hit, was_dash)
	return _finalize_turn_after_action()

func try_wait() -> bool:
	if not game_state.is_idle():
		return false
	if _player_move_visual_pending:
		return false
	if bonus_step_armed or ultimate_dashes_remaining > 0:
		return false
	score_manager.reset_combo()
	return _finalize_turn_after_action()

func _get_attack_mode() -> int:
	if current_attack_mode_override >= 0:
		return current_attack_mode_override
	var data = CharacterData.CHARACTERS[current_character]
	return data.get("attack_mode", CharacterData.AttackMode.DASH)

func _has_pierce_passive() -> bool:
	var data = CharacterData.CHARACTERS[current_character]
	if not data.get("has_pierce", false):
		return false
	return _get_attack_mode() != CharacterData.AttackMode.DASH

func _get_move_memory_token(dir: int) -> int:
	return dir

func _will_spawn_hit_target_this_turn(target: Vector2i) -> bool:
	if cycle_resolved:
		return false
	if cycle_counter + 1 < SPAWN_CYCLE_STEPS:
		return false
	return target in candidate_cells

func _resolve_attack(dir: int, target: Vector2i, target_type: int) -> void:
	_kill_flow(target, dir, target_type)

	if not _has_pierce_passive():
		return
	if grid[target.y][target.x] != CharacterData.CellType.LIVE:
		return

	var next_pos = target + CharacterData.DIR_VECTOR[dir]
	if next_pos.x < 0 or next_pos.x >= COLS or next_pos.y < 0 or next_pos.y >= ROWS:
		return

	var next_type = grid[next_pos.y][next_pos.x]
	if next_type == CharacterData.CellType.LIVE:
		return

	_kill_flow(next_pos, dir, next_type)

func _finalize_turn_after_action(freeze_spawn_cycle: bool = false, count_turn: bool = true) -> bool:
	if count_turn:
		survival_turns += 1
	_turn_resolution_pending = true
	_turn_freezes_spawn = freeze_spawn_cycle
	game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
	_refresh_visuals()
	if not _player_move_visual_pending and not _action_animation_pending:
		call_deferred("_complete_turn_after_motion")
	return true

func try_energy_bonus_step() -> bool:
	if not game_state.is_idle():
		return false
	if _player_move_visual_pending:
		return false
	if bonus_step_armed or ultimate_dashes_remaining > 0:
		return false
	if energy_half_units < ENERGY_SLOT_COST:
		return false
	energy_half_units -= ENERGY_SLOT_COST
	bonus_step_armed = true
	_refresh_visuals()
	return true

func get_energy_half_units() -> int:
	return energy_half_units

func try_energy_ultimate() -> bool:
	if not game_state.is_idle():
		return false
	if _player_move_visual_pending or bonus_step_armed:
		return false
	if energy_half_units < ENERGY_HALF_UNITS_MAX:
		return false
	var data: Dictionary = CharacterData.CHARACTERS[current_character]
	if not bool(data["has_ult"]):
		return false
	energy_half_units = 0
	ultimate_dashes_remaining = ULT_DASH_COUNT
	_ultimate_chain_started = false
	_refresh_visuals()
	return true

func get_ultimate_dashes_remaining() -> int:
	return ultimate_dashes_remaining

func _has_attack_direction(dir: int) -> bool:
	if ultimate_dashes_remaining > 0:
		return CharacterData.DIR_VECTOR.has(dir)
	return inventory.find_direction(dir) >= 0

func _consume_attack_direction(dir: int) -> bool:
	if ultimate_dashes_remaining > 0:
		if not CharacterData.DIR_VECTOR.has(dir):
			return false
		ultimate_dashes_remaining -= 1
		_ultimate_chain_started = true
		return true
	var inventory_index: int = inventory.find_direction(dir)
	if inventory_index < 0:
		return false
	inventory.remove_at(inventory_index)
	return true

func _finish_ultimate_chain() -> void:
	if _ultimate_chain_started and ultimate_dashes_remaining == 0:
		_ultimate_chain_started = false

func _try_ultimate_dash(dir: int) -> bool:
	if ultimate_dashes_remaining <= 0 or not CharacterData.DIR_VECTOR.has(dir):
		return false

	var origin := player_pos
	var destination := _get_ultimate_dash_destination(dir)
	var hits_dead: bool = destination != origin and grid[destination.y][destination.x] == CharacterData.CellType.DEAD
	if not _consume_attack_direction(dir):
		return false
	var freeze_spawn_cycle: bool = ultimate_dashes_remaining > 0
	_clear_attack_prompts()
	player_facing_dir = dir

	if destination == origin:
		_finish_ultimate_chain()
		_action_animation_pending = true
		game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
		player_node.play_attack(dir, false, true)
		return _finalize_turn_after_action(freeze_spawn_cycle)

	if hits_dead:
		_perform_dash_kill(destination, dir)
		inventory.push(dir)
		_finish_ultimate_chain()
		return _finalize_turn_after_action(freeze_spawn_cycle)

	player_pos = destination
	_finish_ultimate_chain()
	return _finalize_turn_after_action(freeze_spawn_cycle)

func _get_ultimate_dash_destination(dir: int) -> Vector2i:
	var step: Vector2i = CharacterData.DIR_VECTOR[dir]
	var cursor := player_pos + step
	var destination := player_pos
	while _is_inside_board(cursor):
		destination = cursor
		if grid[cursor.y][cursor.x] == CharacterData.CellType.DEAD:
			break
		cursor += step
	return destination

func _perform_dash_kill(target: Vector2i, dir: int) -> void:
	var origin := player_pos
	var target_type: int = grid[target.y][target.x]
	_resolve_attack(dir, target, target_type)
	if grid[target.y][target.x] == CharacterData.CellType.LIVE:
		player_pos = target
		_action_animation_pending = true
		var slash_length: float = maxf(
			175.0,
			float(origin.distance_to(target)) * CELL_STEP + CELL_SIZE * ULT_SLASH_TIP_EXTENSION_RATIO
		)
		_char_impl.begin_kill_anim(
			self,
			origin,
			target,
			dir,
			slash_length,
			CharacterImpl_PLN.ULT_SLASH_WIDTH,
			CharacterImpl_PLN.ULT_MOVE_DURATION
		)
		game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
		player_node.emit_animation_done_after(
			player_node.get_hit_delay(true, CharacterImpl_PLN.ULT_MOVE_DURATION)
		)
	else:
		_action_animation_pending = true
		game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
		player_node.play_attack(dir, false, true)

func _is_inside_board(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < COLS and pos.y >= 0 and pos.y < ROWS

func _on_failed_kill(attack_dir: int) -> void:
	_char_impl.on_failed_kill(self, attack_dir)

func _spawn_hit_effect(pos: Vector2i) -> void:
	var world_pos := Vector2(pos.x * CELL_STEP + CELL_SIZE / 2.0,
							 pos.y * CELL_STEP + CELL_SIZE / 2.0)
	_pending_kill_visual.append(pos)
	player_node.animation_done.connect(func():
		_pending_kill_visual.erase(pos)
		cell_nodes[pos.y][pos.x].set_type(CharacterData.CellType.LIVE)
		var fx := _hit_effect_scene.instantiate()
		fx.configure_fast_kill()
		fx.z_index = 5
		fx.position = world_pos
		add_child(fx)
	, CONNECT_ONE_SHOT)

func _on_player_animation_done() -> void:
	if _char_impl.pending_kill_pos != Vector2i(-1, -1):
		_char_impl.resolve_kill_visual()
	_action_animation_pending = false
	if _turn_resolution_pending:
		if not _player_move_visual_pending:
			call_deferred("_complete_turn_after_motion")
	elif game_state.current_state == CharacterData.GameStateEnum.PRESENTING:
		game_state.set_state(CharacterData.GameStateEnum.IDLE)
		_sync_player_move_ready()

func _kill_flow(pos: Vector2i, attack_dir: int, cell_type: int) -> void:
	# Set to LIVE
	grid[pos.y][pos.x] = CharacterData.CellType.LIVE
	score_manager.combo_counter += 1
	score_manager.on_kill(cell_type)
	if not _ultimate_chain_started:
		_charge_energy_for_combo(score_manager.combo_counter)
	_spawn_hit_effect(pos)
	_char_impl.on_kill(self, pos, attack_dir)

func _charge_energy_for_combo(combo: int) -> void:
	match combo:
		2, 3:
			energy_half_units = mini(energy_half_units + 1, ENERGY_HALF_UNITS_MAX)
		4, 5:
			energy_half_units = mini(energy_half_units + 2, ENERGY_HALF_UNITS_MAX)
		_:
			if combo >= 6:
				energy_half_units = mini(energy_half_units + 4, ENERGY_HALF_UNITS_MAX)

var cycle_resolved: bool = false  # true = this cycle already spawned, remaining turns idle

func _advance_cycle() -> void:
	cycle_counter += 1

	if cycle_resolved:
		# Already spawned this cycle, idle until cycle ends
		if cycle_counter >= SPAWN_CYCLE_STEPS:
			cycle_counter = 0
			cycle_resolved = false
	elif cycle_counter == 1:
		_start_new_cycle()
	elif cycle_counter >= SPAWN_CYCLE_STEPS:
		_clean_candidates()
		for pos in candidate_cells:
			_apply_candidate_spawn(pos)
		candidate_cells.clear()
		cycle_counter = 0
		cycle_resolved = false

func _start_new_cycle() -> void:
	candidate_cells.clear()
	var available: Array = []
	for r in ROWS:
		for c in COLS:
			var pos = Vector2i(c, r)
			if _is_spawnable_live_cell(pos):
				available.append(pos)
	available.shuffle()
	var count = min(SPAWNS_PER_CYCLE, available.size())
	for i in count:
		candidate_cells.append(available[i])

func _clean_candidates() -> void:
	var cleaned: Array = []
	for pos in candidate_cells:
		if grid[pos.y][pos.x] == CharacterData.CellType.LIVE:
			cleaned.append(pos)
	candidate_cells = cleaned

func _apply_candidate_spawn(pos: Vector2i) -> void:
	if grid[pos.y][pos.x] != CharacterData.CellType.LIVE:
		return
	var cell_type: int = SPAWN_CELL_TYPE

	if pos == player_pos:
		_begin_player_spawn_hit(pos, cell_type)
		return

	_spawn_dead(pos, cell_type)
	_spawn_fade_pending = true
	cell_nodes[pos.y][pos.x].set_type(cell_type)
	cell_nodes[pos.y][pos.x].play_spawn_fade(SPAWN_FADE_SECONDS)

func _begin_player_spawn_hit(pos: Vector2i, cell_type: int) -> void:
	if _spawn_hit_pending:
		return
	_spawn_hit_pending = true
	game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
	get_tree().create_timer(SPAWN_HIT_SETTLE_SECONDS).timeout.connect(
		func(): _play_player_spawn_hit_feedback(pos, cell_type), CONNECT_ONE_SHOT)

func _play_player_spawn_hit_feedback(pos: Vector2i, cell_type: int) -> void:
	if not _spawn_hit_pending:
		return
	var slot_count: int = mini(2, inventory.queue.size())
	spawn_hit_started.emit(slot_count)
	player_node.play_spawn_hit()
	if slot_count >= 2:
		_show_spawn_block_effect(pos)
	else:
		cell_nodes[pos.y][pos.x].set_type(cell_type)
	get_tree().create_timer(SPAWN_HIT_FEEDBACK_SECONDS).timeout.connect(
		func(): _resolve_player_spawn_hit(pos, cell_type), CONNECT_ONE_SHOT)

func _show_spawn_block_effect(pos: Vector2i) -> void:
	var effect := _hit_effect_scene.instantiate()
	effect.z_index = 5
	effect.position = Vector2(
		pos.x * CELL_STEP + CELL_SIZE / 2.0,
		pos.y * CELL_STEP + CELL_SIZE / 2.0
	)
	add_child(effect)

func _resolve_player_spawn_hit(pos: Vector2i, cell_type: int) -> void:
	if not _spawn_hit_pending:
		return
	_spawn_hit_pending = false
	var consumed_count := 0
	for i in mini(2, inventory.queue.size()):
		inventory.pop()
		consumed_count += 1
	if consumed_count >= 2:
		score_manager.on_kill(cell_type)
	else:
		_spawn_dead(pos, cell_type)
	_refresh_visuals()
	_finish_spawn_stage_if_ready()

func _spawn_dead(pos: Vector2i, cell_type: int) -> void:
	grid[pos.y][pos.x] = cell_type

func _is_spawnable_live_cell(pos: Vector2i) -> bool:
	if grid[pos.y][pos.x] != CharacterData.CellType.LIVE:
		return false
	if not BLOCK_OUTER_RING_SPAWN:
		return true
	return pos.x > 0 and pos.x < COLS - 1 and pos.y > 0 and pos.y < ROWS - 1

func _check_game_over() -> void:
	if _spawn_hit_pending:
		return
	if grid[player_pos.y][player_pos.x] != CharacterData.CellType.LIVE:
		game_state.set_state(CharacterData.GameStateEnum.GAME_OVER)
		game_over_signal.emit(score_manager.score)
		return

	for dv in CharacterData.DIR_VECTOR.values():
		var neighbor = player_pos + dv
		if neighbor.x < 0 or neighbor.x >= COLS or neighbor.y < 0 or neighbor.y >= ROWS:
			continue
		var n_type = grid[neighbor.y][neighbor.x]
		if n_type == CharacterData.CellType.LIVE:
			return  # Has escape

	# All neighbors are DEAD or out of bounds - check inventory + hold
	for dv_dir in CharacterData.DIR_VECTOR:
		var dv: Vector2i = CharacterData.DIR_VECTOR[dv_dir]
		var neighbor: Vector2i = player_pos + dv
		if neighbor.x < 0 or neighbor.x >= COLS or neighbor.y < 0 or neighbor.y >= ROWS:
			continue
		if grid[neighbor.y][neighbor.x] != CharacterData.CellType.LIVE:
			if _has_attack_direction(dv_dir):
				return  # Can consume and move

	game_state.set_state(CharacterData.GameStateEnum.GAME_OVER)
	game_over_signal.emit(score_manager.score)

func _refresh_visuals() -> void:
	# Update all cells
	for r in ROWS:
		for c in COLS:
			var pos := Vector2i(c, r)
			var cell = cell_nodes[r][c]
			if pos in _pending_kill_visual:
				continue   # 延遲處理，保持 DEAD 外觀
			cell.set_type(grid[r][c])
			cell.set_candidate(0)

	# Mark candidates
	if cycle_counter >= 1:
		for i in candidate_cells.size():
			var pos: Vector2i = candidate_cells[i]
			var phase: int = _get_candidate_preview_phase()
			cell_nodes[pos.y][pos.x].set_candidate(phase)

	_refresh_attack_prompts()

	player_node.set_facing(player_facing_dir)
	_sync_player_move_ready()

	# Update player position (skip if move is deferred to timer)
	if not _char_impl.defer_player_move:
		var old_player_visual_pos := player_node.position
		player_node.position = Vector2(
			player_pos.x * CELL_STEP + CELL_SIZE / 2.0,
			player_pos.y * CELL_STEP + CELL_SIZE / 2.0
		)
		if player_node.position != old_player_visual_pos:
			player_node.play_move(old_player_visual_pos)

	board_updated.emit()

func _on_player_movement_started() -> void:
	_player_move_visual_pending = true

func _finish_player_move_visual() -> void:
	_player_move_visual_pending = false
	if _turn_resolution_pending and not _action_animation_pending:
		_complete_turn_after_motion()

func _complete_turn_after_motion() -> void:
	if not _turn_resolution_pending:
		return
	_turn_resolution_pending = false
	var freeze_spawn_cycle: bool = _turn_freezes_spawn
	_turn_freezes_spawn = false
	if not freeze_spawn_cycle:
		if _opening_grace_turns_remaining > 0:
			_opening_grace_turns_remaining -= 1
		else:
			_advance_cycle()
	_refresh_visuals()
	if _spawn_fade_pending:
		get_tree().create_timer(SPAWN_FADE_SECONDS).timeout.connect(
			_finish_spawn_fade, CONNECT_ONE_SHOT)
	if _spawn_hit_pending or _spawn_fade_pending:
		return
	_finish_turn_presentation()

func _finish_spawn_fade() -> void:
	if not _spawn_fade_pending:
		return
	_spawn_fade_pending = false
	_finish_spawn_stage_if_ready()

func _finish_spawn_stage_if_ready() -> void:
	if _spawn_hit_pending or _spawn_fade_pending:
		return
	_finish_turn_presentation()

func _finish_turn_presentation() -> void:
	if game_state.current_state == CharacterData.GameStateEnum.GAME_OVER:
		return
	game_state.set_state(CharacterData.GameStateEnum.IDLE)
	_check_game_over()
	_refresh_attack_prompts()
	_sync_player_move_ready()

func _sync_player_move_ready() -> void:
	var ready_directions: Array[int] = []
	var bonus_directions: Array[int] = []
	if game_state.is_idle() and bonus_step_armed:
		for direction in CharacterData.DIR_VECTOR:
			var target: Vector2i = player_pos + CharacterData.DIR_VECTOR[direction]
			if not _is_inside_board(target):
				continue
			if grid[target.y][target.x] == CharacterData.CellType.LIVE or _has_attack_direction(direction):
				bonus_directions.append(direction)
	elif game_state.is_idle() and ultimate_dashes_remaining == 0:
		for direction in CharacterData.DIR_VECTOR:
			var target: Vector2i = player_pos + CharacterData.DIR_VECTOR[direction]
			if not _is_inside_board(target):
				continue
			if grid[target.y][target.x] == CharacterData.CellType.LIVE:
				ready_directions.append(direction)
	player_node.set_move_ready_directions(ready_directions)
	player_node.set_bonus_step_directions(bonus_directions)

func _clear_attack_prompts() -> void:
	for row_value in cell_nodes:
		var row: Array = row_value
		for cell_value in row:
			var cell: Node2D = cell_value
			cell.set_attack_prompt(CharacterData.Direction.NONE)

func _refresh_attack_prompts() -> void:
	_clear_attack_prompts()
	if not game_state.is_idle() or bonus_step_armed:
		return
	for direction in CharacterData.DIR_VECTOR:
		var target: Vector2i = player_pos + CharacterData.DIR_VECTOR[direction]
		if not _is_inside_board(target):
			continue
		if grid[target.y][target.x] == CharacterData.CellType.DEAD and _has_attack_direction(direction):
			cell_nodes[target.y][target.x].set_attack_prompt(direction)

func _update_board_offset() -> void:
	var board_width: float = float(COLS - 1) * CELL_STEP + CELL_SIZE
	var board_height: float = float(ROWS - 1) * CELL_STEP + CELL_SIZE
	var viewport_size: Vector2 = get_viewport_rect().size
	position = Vector2(
		(viewport_size.x - board_width) * 0.5,
		(viewport_size.y - board_height) * 0.5
	)

func _get_candidate_preview_phase() -> int:
	if SPAWN_CYCLE_STEPS <= 1:
		return 4
	var progress: float = float(cycle_counter - 1) / float(SPAWN_CYCLE_STEPS - 1)
	return clampi(int(floor(progress * 4.0)) + 1, 1, 4)
