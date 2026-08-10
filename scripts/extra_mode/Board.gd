extends Node2D

const CharacterImpl_PLN = preload("res://scripts/extra_mode/CharacterImpl_PLN.gd")

const COLS := 5
const ROWS := 5
const SPAWN_CYCLE_STEPS := 2
const SPAWNS_PER_CYCLE := 2
const SPAWN_CELL_TYPE := CharacterData.CellType.DEAD
const BLOCK_OUTER_RING_SPAWN := false
const CELL_SIZE := 100.0
const CELL_GAP := 8.0
const CELL_STEP := CELL_SIZE + CELL_GAP
const SPAWN_HIT_SETTLE_SECONDS := 0.08
const SPAWN_HIT_FEEDBACK_SECONDS := 0.24

signal game_over_signal(final_score: int)
signal board_updated
signal spawn_hit_started(slot_count: int)

var grid: Array = []  # grid[row][col] = CellType
var player_pos: Vector2i = Vector2i(COLS / 2, ROWS / 2)
var player_facing_dir: int = CharacterData.Direction.UP
var candidate_cells: Array = []  # Array of Vector2i
var bonus_move_options: Dictionary = {}  # Direction -> Vector2i (adjacent LIVE cells)
var bonus_attack_options: Dictionary = {}  # Direction -> Vector2i (adjacent DEAD cells, chain attack)
var bonus_move_can_stay: bool = false
var bonus_move_advances_turn: bool = false
var bonus_move_stores_memory: bool = false
var bonus_move_stores_directional_memory: bool = false
var cycle_counter: int = 0
var _spawn_hit_pending: bool = false
var _suppress_hit_effect_once: bool = false
var _pending_kill_visual: Array[Vector2i] = []  # 正在等待延遲視覺更新的格子
var survival_turns: int = 0
var ultimate_ready: bool = false
var ultimate_directions: Array[int] = []
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
	bonus_move_options.clear()
	bonus_attack_options.clear()
	bonus_move_can_stay = false
	bonus_move_advances_turn = false
	bonus_move_stores_memory = false
	bonus_move_stores_directional_memory = false
	cycle_counter = 0
	cycle_resolved = false
	_spawn_hit_pending = false
	_suppress_hit_effect_once = false
	_pending_kill_visual.clear()
	survival_turns = 0
	ultimate_ready = false
	ultimate_directions.clear()
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
	player_node.play_attack(player_facing_dir, true, true)

func try_move(dir: int) -> bool:
	if not game_state.is_idle():
		return false

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
		if not _will_spawn_hit_target_this_turn(target):
			inventory.push(_get_move_memory_token(dir))
			inventory.register_move(dir)
		score_manager.on_move_to_live()

		return _finalize_turn_after_action()

	else:
		# Dead cell - check inventory for matching direction (any position)
		if not _consume_attack_direction(dir):
			return false  # No matching direction in queue

		var origin := player_pos

		player_facing_dir = dir
		if _get_attack_mode() == CharacterData.AttackMode.DASH:
			_resolve_attack(dir, target, target_type)
			if grid[target.y][target.x] == CharacterData.CellType.LIVE:
				player_pos = target
				if _has_post_kill_reposition():
					_char_impl.begin_kill_anim(self, origin, target, dir)
					game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
					player_node.emit_animation_done_after(player_node.get_hit_delay(true))
				else:
					inventory.register_move(dir)
					game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
					player_node.play_attack(dir, true, true)
		else:
			_resolve_attack(dir, target, target_type)
		if player_pos == origin:
			var attack_hit: bool = (grid[target.y][target.x] == CharacterData.CellType.LIVE)
			var was_dash := _get_attack_mode() == CharacterData.AttackMode.DASH
			if _char_impl.pending_kill_pos == Vector2i(-1, -1):
				game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
				player_node.play_attack(dir, attack_hit, was_dash)

		if _begin_post_kill_reposition_if_needed(target, dir):
			_refresh_visuals()
			return true
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
			game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
			player_node.play_attack(dir, attack_hit, was_dash)
	return _finalize_turn_after_action()

func try_wait() -> bool:
	if not game_state.is_idle():
		return false
	return _finalize_turn_after_action()

func try_bonus_move(dir: int) -> bool:
	if not game_state.is_bonus_move_select():
		return false

	if bonus_attack_options.has(dir):
		if not _consume_attack_direction(dir):
			return false  # Queue no longer holds this direction
		var target: Vector2i = bonus_attack_options[dir]
		bonus_move_options.clear()
		bonus_attack_options.clear()
		bonus_move_can_stay = false
		bonus_move_advances_turn = false
		player_facing_dir = dir
		_perform_chain_kill(target, dir)
		if _begin_post_kill_reposition_if_needed(target, dir):
			_refresh_visuals()
			return true
		return _finalize_turn_after_action()

	if not bonus_move_options.has(dir):
		return false

	player_facing_dir = dir
	player_pos = bonus_move_options[dir]
	if _char_impl.pending_kill_pos != Vector2i(-1, -1):
		inventory.register_move(dir)
		_char_impl.resolve_kill_visual()
	bonus_move_options.clear()
	bonus_attack_options.clear()
	bonus_move_can_stay = false
	if bonus_move_stores_directional_memory:
		inventory.push(dir)
	elif bonus_move_stores_memory:
		inventory.push(_get_move_memory_token(dir))
	bonus_move_stores_memory = false
	bonus_move_stores_directional_memory = false
	if bonus_move_advances_turn:
		bonus_move_advances_turn = false
		_finish_ultimate_chain()
		score_manager.reset_combo()
		return _finalize_turn_after_action()
	bonus_move_advances_turn = false
	game_state.set_state(CharacterData.GameStateEnum.IDLE)
	_refresh_visuals()
	_check_game_over()
	return true

# Free chain-attack from the bonus step: resolves a kill on an adjacent DEAD
# cell without consuming an inventory slot, occupying it exactly like a
# normal dash-kill so it can chain into another bonus step.
func _perform_chain_kill(target: Vector2i, dir: int) -> void:
	var origin := player_pos
	var target_type: int = grid[target.y][target.x]
	_resolve_attack(dir, target, target_type)
	if grid[target.y][target.x] == CharacterData.CellType.LIVE:
		player_pos = target
		_char_impl.begin_kill_anim(self, origin, target, dir)
		game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
		player_node.emit_animation_done_after(player_node.get_hit_delay(true))
	else:
		game_state.set_state(CharacterData.GameStateEnum.PRESENTING)
		player_node.play_attack(dir, false, true)

func try_bonus_stay() -> bool:
	if not game_state.is_bonus_move_select():
		return false
	if not bonus_move_can_stay:
		return false

	bonus_move_options.clear()
	bonus_attack_options.clear()
	bonus_move_can_stay = false
	bonus_move_stores_memory = false
	bonus_move_stores_directional_memory = false
	_char_impl.resolve_kill_visual()
	if bonus_move_advances_turn:
		bonus_move_advances_turn = false
		_finish_ultimate_chain()
		score_manager.reset_combo()
		return _finalize_turn_after_action()
	bonus_move_advances_turn = false
	game_state.set_state(CharacterData.GameStateEnum.IDLE)
	_refresh_visuals()
	_check_game_over()
	return true

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

func _has_post_kill_reposition() -> bool:
	var data = CharacterData.CHARACTERS[current_character]
	return data.get("has_post_kill_reposition", false)

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

func _begin_post_kill_reposition_if_needed(target: Vector2i, entry_dir: int) -> bool:
	if not _has_post_kill_reposition():
		return false
	if grid[target.y][target.x] != CharacterData.CellType.LIVE:
		return false

	bonus_move_options.clear()
	bonus_attack_options.clear()
	bonus_move_can_stay = true
	bonus_move_advances_turn = true
	bonus_move_stores_memory = false
	bonus_move_stores_directional_memory = true
	for dir in CharacterData.DIR_VECTOR:
		var pos = player_pos + CharacterData.DIR_VECTOR[dir]
		if pos.x < 0 or pos.x >= COLS or pos.y < 0 or pos.y >= ROWS:
			continue
		var neighbor_type: int = grid[pos.y][pos.x]
		if neighbor_type == CharacterData.CellType.LIVE:
			bonus_move_options[dir] = pos
		elif neighbor_type == CharacterData.CellType.DEAD and _has_attack_direction(dir):
			bonus_attack_options[dir] = pos

	if bonus_move_options.is_empty() and bonus_attack_options.is_empty() and not bonus_move_can_stay:
		return false

	game_state.set_state(CharacterData.GameStateEnum.BONUS_MOVE_SELECT)
	return true

func _finalize_turn_after_action() -> bool:
	survival_turns += 1
	_advance_cycle()
	_refresh_visuals()
	_check_game_over()
	return true

func try_ultimate() -> bool:
	if not game_state.is_idle():
		return false
	var data = CharacterData.CHARACTERS[current_character]
	if not data["has_ult"]:
		return false
	if not ultimate_ready:
		return false
	ultimate_ready = false
	ultimate_directions.assign([
		CharacterData.Direction.UP,
		CharacterData.Direction.DOWN,
		CharacterData.Direction.LEFT,
		CharacterData.Direction.RIGHT,
	])
	_ultimate_chain_started = false
	score_manager.reset_combo()
	_refresh_visuals()
	return true

func get_ultimate_directions() -> Array[int]:
	return ultimate_directions.duplicate()

func _has_attack_direction(dir: int) -> bool:
	return dir in ultimate_directions or inventory.find_direction(dir) >= 0

func _consume_attack_direction(dir: int) -> bool:
	var ultimate_index: int = ultimate_directions.find(dir)
	if ultimate_index >= 0:
		ultimate_directions.remove_at(ultimate_index)
		_ultimate_chain_started = true
		return true
	var inventory_index: int = inventory.find_direction(dir)
	if inventory_index < 0:
		return false
	inventory.remove_at(inventory_index)
	return true

func _finish_ultimate_chain() -> void:
	if not _ultimate_chain_started:
		return
	ultimate_directions.clear()
	_ultimate_chain_started = false

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
		fx.z_index = 5
		fx.position = world_pos
		add_child(fx)
	, CONNECT_ONE_SHOT)

func _on_player_animation_done() -> void:
	if game_state.current_state == CharacterData.GameStateEnum.PRESENTING:
		game_state.set_state(CharacterData.GameStateEnum.IDLE)

func _kill_flow(pos: Vector2i, attack_dir: int, cell_type: int) -> void:
	# Set to LIVE
	grid[pos.y][pos.x] = CharacterData.CellType.LIVE
	score_manager.combo_counter += 1
	score_manager.on_kill(cell_type)
	if score_manager.combo_counter >= 4 and not _ultimate_chain_started:
		ultimate_ready = true
	_spawn_hit_effect(pos)
	_char_impl.on_kill(self, pos, attack_dir)

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

	if not game_state.is_presenting():
		game_state.set_state(CharacterData.GameStateEnum.IDLE)

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
		game_state.set_state(CharacterData.GameStateEnum.IDLE)
	else:
		_spawn_dead(pos, cell_type)
	_refresh_visuals()
	_check_game_over()

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
			# Check if any slot in queue has this direction
			if inventory.has_direction(dv_dir):
				return  # Can consume and move

	game_state.set_state(CharacterData.GameStateEnum.GAME_OVER)
	game_over_signal.emit(score_manager.score)

func _refresh_visuals() -> void:
	# Update all cells
	for r in ROWS:
		for c in COLS:
			var pos := Vector2i(c, r)
			if pos in _pending_kill_visual:
				continue   # 延遲處理，保持 DEAD 外觀
			var cell = cell_nodes[r][c]
			cell.set_type(grid[r][c])
			cell.set_candidate(0)
			cell.set_bonus_option(0)

	# Mark candidates
	if cycle_counter >= 1:
		for i in candidate_cells.size():
			var pos: Vector2i = candidate_cells[i]
			var phase: int = _get_candidate_preview_phase()
			cell_nodes[pos.y][pos.x].set_candidate(phase)

	for dir in bonus_move_options:
		var pos: Vector2i = bonus_move_options[dir]
		cell_nodes[pos.y][pos.x].set_bonus_option(10, dir)
	for dir in bonus_attack_options:
		var pos: Vector2i = bonus_attack_options[dir]
		cell_nodes[pos.y][pos.x].set_bonus_option(20, dir)
	if bonus_move_can_stay:
		cell_nodes[player_pos.y][player_pos.x].set_bonus_option(10)

	player_node.set_facing(player_facing_dir)

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
