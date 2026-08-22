class_name DIRExtraComboBot
extends RefCounted

const ACTION_NONE := 0
const ACTION_MOVE := 1
const ACTION_DASH := 2
const ACTION_ULT := 3
const ACTION_WAIT := 4
const LOOKAHEAD_DEPTH := 3

# Every value below is a weight in the lookahead's scoring function, tuned by
# feel and never checked against the others. They are instance vars (not
# consts) purely so a subclass can override the whole set at once -- see
# ComboBotTuned.gd, which plugs in weights a CMA-ES search over these exact
# fields found (tools/extra_cma.py), validated against 24 held-out seeds
# never used in that search. Keep this list in the same order and names as
# tools/extra_cma.py's Weights dataclass so the two stay easy to diff.
var LOOKAHEAD_DISCOUNT := 0.72
var ENERGY_UNIT_VALUE := 2.0
var FULL_BAR_INSURANCE := 800.0
var TARGET_DISTANCE_WEIGHT := 8.0
var APPROACH_MATCH_BONUS := 40.0
var ENERGY_SHIELD_VALUE := 160.0
var DIRECTION_SHIELD_VALUE := 95.0
var ENERGY_SHIELD_SPEND_PENALTY := 110.0
var DIRECTION_SHIELD_SPEND_PENALTY := 80.0
var SPAWN_HIT_DEATH_PENALTY := 5000.0
var COMBO_KILL_MULT := 60.0
var COMBO_HOLD_MULT := 30.0
var COMBO_BREAK_MULT := 45.0
var LIVE_EXIT_VALUE := 55.0
var ATTACK_EXIT_VALUE := 95.0
var USEFUL_DIRECTION_VALUE := 45.0
var UNIQUE_DIRECTION_VALUE := 16.0
var CENTER_DISTANCE_PENALTY := 12.0
var SINGLE_EXIT_PENALTY := 420.0
var ULT_CONTINUATION_VALUE := 1800.0
var COMBO_GATE_FOR_STEP := 4

var chosen_direction: int = CharacterData.Direction.NONE

func choose_action(board: Node) -> int:
	chosen_direction = CharacterData.Direction.NONE
	if not board.game_state.is_idle():
		return ACTION_NONE

	if board.get_ultimate_dashes_remaining() > 0:
		chosen_direction = _best_ultimate_direction(board)
		return ACTION_MOVE if chosen_direction != CharacterData.Direction.NONE else ACTION_NONE

	var attack_directions: Array[int] = _attack_directions(board)
	if board.bonus_step_armed:
		chosen_direction = _best_normal_direction(board, true)
		return ACTION_MOVE if chosen_direction != CharacterData.Direction.NONE else ACTION_NONE

	var combo: int = board.score_manager.combo_counter
	var energy: int = board.get_energy_quarter_units()
	if energy >= board.ENERGY_QUARTER_UNITS_MAX and _should_activate_ultimate(board, combo):
		return ACTION_ULT

	# A charged X keeps the next move off the spawn clock. Evaluate it before
	# an ordinary attack so a high-heat chain may pay X repeatedly rather than
	# advancing the spawn clock between its top-tier kills.
	if _should_spend_dash_for_continuation(board, attack_directions, combo, energy):
		return ACTION_DASH

	if not attack_directions.is_empty():
		chosen_direction = _best_attack_direction(board, attack_directions)
		return ACTION_MOVE

	if energy >= board.ENERGY_QUARTER_UNITS_MAX and _count_ultimate_targets(board) > 0:
		return ACTION_ULT

	chosen_direction = _best_normal_direction(board, false)
	if chosen_direction != CharacterData.Direction.NONE:
		return ACTION_MOVE
	return ACTION_WAIT

func _attack_directions(board: Node) -> Array[int]:
	var result: Array[int] = []
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var target: Vector2i = board.player_pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if not board._is_inside_board(target):
			continue
		if board.grid[target.y][target.x] != CharacterData.CellType.LIVE \
				and board.inventory.find_direction(direction) >= 0:
			result.append(direction)
	return result

func _best_attack_direction(board: Node, directions: Array[int]) -> int:
	var best_direction: int = CharacterData.Direction.NONE
	var best_score: float = -INF
	for direction in directions:
		var score: float = _direction_plan_score(board, direction, board.bonus_step_armed)
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction

func _best_normal_direction(board: Node, preserve_combo: bool) -> int:
	var attacks: Array[int] = _attack_directions(board)
	if not attacks.is_empty():
		return _best_attack_direction(board, attacks)

	var best_direction: int = CharacterData.Direction.NONE
	var best_score: float = -INF
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var target: Vector2i = board.player_pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if not board._is_inside_board(target):
			continue
		if board.grid[target.y][target.x] != CharacterData.CellType.LIVE:
			continue
		var score: float = _direction_plan_score(board, direction, preserve_combo)
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction

func _has_dash_continuation(board: Node) -> bool:
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var target: Vector2i = board.player_pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if not board._is_inside_board(target):
			continue
		if board.grid[target.y][target.x] != CharacterData.CellType.LIVE:
			continue
		if _future_attack_count(board, target, direction) > 0:
			return true
	return false

func _should_spend_dash_for_continuation(
	board: Node,
	attack_directions: Array[int],
	combo: int,
	energy: int
) -> bool:
	var cost: int = int(board.get_bonus_step_cost())
	if combo < maxi(COMBO_GATE_FOR_STEP, ScoreManager.MAX_COMBO_TIER) or energy < cost:
		return false

	var protects_spawn_hit: bool = _attack_will_land_on_spawn(board, attack_directions)
	var protects_streak: bool = _is_streak_payout_near(board) \
			or _has_established_attack_chain(board, attack_directions)
	if not protects_spawn_hit and not protects_streak:
		return false
	# An X-paid kill is energy-sterile. With the current Heat 5 +6 payout,
	# prefer the normal hit when it fills ULT; the next decision can then spend
	# four frozen dashes instead of burning a single protected move now.
	if not protects_spawn_hit and _normal_kill_completes_ultimate(board, energy):
		return false
	# A long-chain X must leave one full energy unit for the next spawn hit.
	# An imminent spawn hit is the exception: freezing that move is safer than
	# taking the hit now, even when it empties the bar.
	if not protects_spawn_hit and energy < 2 * cost:
		return false
	if not attack_directions.is_empty():
		return true
	return protects_streak and _has_dash_continuation(board)

func _normal_kill_completes_ultimate(board: Node, energy: int) -> bool:
	var next_energy: int = energy + int(board.get_next_kill_energy_gain())
	return next_energy >= int(board.ENERGY_QUARTER_UNITS_MAX)

func _is_streak_payout_near(board: Node) -> bool:
	var streak: int = board.score_manager.tier5_streak
	var progress: int = posmod(streak, ScoreManager.TIER5_STREAK_THRESHOLD)
	return progress >= ScoreManager.TIER5_STREAK_THRESHOLD - 2

func _has_established_attack_chain(board: Node, attack_directions: Array[int]) -> bool:
	# Before the first payout, X remains a near-payout tool. Once the streak
	# has paid once, spend it to preserve only concrete two-kill handoffs -- a
	# visible continuation, not a speculative route across the board.
	if board.score_manager.tier5_streak < ScoreManager.TIER5_STREAK_THRESHOLD:
		return false
	for attack_direction in attack_directions:
		var attack_target: Vector2i = board.player_pos \
				+ Vector2i(CharacterData.DIR_VECTOR[attack_direction])
		for follow_direction_value in CharacterData.DIR_VECTOR:
			var follow_direction: int = int(follow_direction_value)
			var follow_target: Vector2i = attack_target \
					+ Vector2i(CharacterData.DIR_VECTOR[follow_direction])
			if not board._is_inside_board(follow_target):
				continue
			if board.grid[follow_target.y][follow_target.x] != CharacterData.CellType.LIVE \
					and board.inventory.find_direction(follow_direction) >= 0:
				return true
	return false

func _attack_will_land_on_spawn(board: Node, attack_directions: Array[int]) -> bool:
	for direction in attack_directions:
		var target: Vector2i = board.player_pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if board._will_spawn_hit_target_this_turn(target):
			return true
	return false

func _direction_plan_score(board: Node, direction: int, preserve_combo: bool) -> float:
	var target: Vector2i = board.player_pos + Vector2i(CharacterData.DIR_VECTOR[direction])
	var simulated_grid: Array = board.grid.duplicate(true)
	var simulated_queue: Array = board.inventory.queue.duplicate()
	var combo: int = board.score_manager.combo_counter
	var tier5_streak: int = board.score_manager.tier5_streak
	var energy: int = int(board.get_energy_quarter_units())
	var reward: float = 0.0
	if simulated_grid[target.y][target.x] == CharacterData.CellType.LIVE:
		_push_simulated_direction(simulated_queue, board.inventory.max_size, direction)
		if not preserve_combo:
			reward -= _combo_break_penalty(combo)
			combo = _decayed_combo(combo)
			tier5_streak = 0
	else:
		var inventory_index: int = simulated_queue.find(direction)
		if inventory_index < 0:
			return -INF
		# preserve_combo means the STEP is armed, and an X-paid attack keeps its
		# direction and grants no energy.
		if not preserve_combo:
			simulated_queue.remove_at(inventory_index)
		simulated_grid[target.y][target.x] = CharacterData.CellType.LIVE
		var kill_state: Vector2i = _advance_combo_and_streak(combo, tier5_streak)
		combo = kill_state.x
		tier5_streak = kill_state.y
		if not preserve_combo:
			energy = _charged_energy(board, energy, combo, tier5_streak)
		reward += _combo_kill_value(combo)
		reward += _tier5_streak_value(combo, tier5_streak)
		if not _grid_has_dead_cell(simulated_grid):
			reward += float(board.BOARD_CLEAR_BONUS)
			energy = int(board.ENERGY_QUARTER_UNITS_MAX)

	if not preserve_combo:
		var spawn_defense: Vector2i = _apply_simulated_spawn_hit(
			board, target, simulated_queue, energy
		)
		energy = spawn_defense.x
		match spawn_defense.y:
			1:
				reward -= ENERGY_SHIELD_SPEND_PENALTY
			2:
				reward -= DIRECTION_SHIELD_SPEND_PENALTY
			-1:
				reward -= SPAWN_HIT_DEATH_PENALTY
		if target in board.candidate_cells and spawn_defense.y == 0:
			reward -= 260.0
	return reward + LOOKAHEAD_DISCOUNT * _lookahead_score(
		board,
		target,
		simulated_grid,
		simulated_queue,
		combo,
		tier5_streak,
		energy,
		LOOKAHEAD_DEPTH - 1
	)

func _advanced_combo(combo: int) -> int:
	return mini(combo + 1, ScoreManager.MAX_COMBO_TIER)

func _decayed_combo(combo: int) -> int:
	return maxi(0, combo - 1)

func _advance_combo_and_streak(combo: int, tier5_streak: int) -> Vector2i:
	var next_combo: int = _advanced_combo(combo)
	var next_streak: int = tier5_streak + 1 if next_combo == ScoreManager.MAX_COMBO_TIER else 0
	return Vector2i(next_combo, next_streak)

func _tier5_streak_value(combo: int, tier5_streak: int) -> float:
	if combo != ScoreManager.MAX_COMBO_TIER:
		return 0.0
	var streak_bonus: int = _tier5_streak_bonus(tier5_streak)
	var progress: int = posmod(tier5_streak, ScoreManager.TIER5_STREAK_THRESHOLD)
	if progress == 0:
		return float(streak_bonus)
	# The lookahead is only three moves deep, while the next streak payout can
	# be five kills away. Preserve a proportionate part of that real reward as
	# terminal-state value so F4 will spend X to protect a growing streak.
	var next_payout_streak: int = tier5_streak + ScoreManager.TIER5_STREAK_THRESHOLD - progress
	var next_bonus: int = _tier5_streak_bonus(next_payout_streak)
	return float(streak_bonus) + float(next_bonus * progress) / float(ScoreManager.TIER5_STREAK_THRESHOLD)

func _tier5_streak_bonus(tier5_streak: int) -> int:
	if tier5_streak <= 0 or tier5_streak % ScoreManager.TIER5_STREAK_THRESHOLD != 0:
		return 0
	var block: int = tier5_streak / ScoreManager.TIER5_STREAK_THRESHOLD
	return mini(
		ScoreManager.TIER5_STREAK_BONUS_BASE + ScoreManager.TIER5_STREAK_BONUS_STEP * (block - 1),
		ScoreManager.TIER5_STREAK_BONUS_CAP
	)

func _charged_energy(board: Node, energy: int, combo: int, tier5_streak: int) -> int:
	# Mirrors Board._charge_energy_for_combo so the lookahead can see the bar
	# fill, which is what makes saving toward ULT visible to the search at all.
	var gain: int = int(board.energy_gain_for_kill(combo, tier5_streak))
	return mini(energy + gain, int(board.ENERGY_QUARTER_UNITS_MAX))

func _grid_has_dead_cell(grid: Array) -> bool:
	for row_value in grid:
		var row: Array = row_value
		if CharacterData.CellType.DEAD in row:
			return true
	return false

func _apply_simulated_spawn_hit(
	board: Node,
	position: Vector2i,
	queue: Array,
	energy: int
) -> Vector2i:
	# Board spends a complete energy unit first. Below that threshold, the two
	# oldest directions absorb the hit instead.
	if not board._will_spawn_hit_target_this_turn(position):
		return Vector2i(energy, 0)
	if energy >= int(board.ENERGY_SLOT_COST):
		return Vector2i(energy - int(board.ENERGY_SLOT_COST), 1)
	if queue.size() >= 2:
		queue.pop_front()
		queue.pop_front()
		return Vector2i(energy, 2)
	return Vector2i(energy, -1)

func _lookahead_score(
	board: Node,
	pos: Vector2i,
	grid: Array,
	queue: Array,
	combo: int,
	tier5_streak: int,
	energy: int,
	depth: int
) -> float:
	if depth <= 0:
		return _simulated_state_score(board, pos, grid, queue, combo, tier5_streak, energy)

	var best_score: float = -INF
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var target: Vector2i = pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if not board._is_inside_board(target):
			continue
		var next_grid: Array = grid.duplicate(true)
		var next_queue: Array = queue.duplicate()
		var next_combo: int = combo
		var next_tier5_streak: int = tier5_streak
		var next_energy: int = energy
		var reward: float = 0.0
		if next_grid[target.y][target.x] == CharacterData.CellType.LIVE:
			_push_simulated_direction(next_queue, board.inventory.max_size, direction)
			reward -= _combo_break_penalty(next_combo)
			next_combo = _decayed_combo(next_combo)
			next_tier5_streak = 0
			var spawn_defense: Vector2i = _apply_simulated_spawn_hit(
				board, target, next_queue, next_energy
			)
			next_energy = spawn_defense.x
			match spawn_defense.y:
				1:
					reward -= ENERGY_SHIELD_SPEND_PENALTY
				2:
					reward -= DIRECTION_SHIELD_SPEND_PENALTY
				-1:
					reward -= SPAWN_HIT_DEATH_PENALTY
		else:
			var inventory_index: int = next_queue.find(direction)
			if inventory_index < 0:
				continue
			next_queue.remove_at(inventory_index)
			next_grid[target.y][target.x] = CharacterData.CellType.LIVE
			var kill_state: Vector2i = _advance_combo_and_streak(next_combo, next_tier5_streak)
			next_combo = kill_state.x
			next_tier5_streak = kill_state.y
			next_energy = _charged_energy(
				board, next_energy, next_combo, next_tier5_streak
			)
			reward += _combo_kill_value(next_combo)
			reward += _tier5_streak_value(next_combo, next_tier5_streak)
			if not _grid_has_dead_cell(next_grid):
				reward += float(board.BOARD_CLEAR_BONUS)
				next_energy = int(board.ENERGY_QUARTER_UNITS_MAX)
		var branch_score: float = reward + LOOKAHEAD_DISCOUNT * _lookahead_score(
			board,
			target,
			next_grid,
			next_queue,
			next_combo,
			next_tier5_streak,
			next_energy,
			depth - 1
		)
		best_score = maxf(best_score, branch_score)
	if best_score == -INF:
		return _simulated_state_score(board, pos, grid, queue, combo, tier5_streak, energy) - 3000.0
	return best_score

func _simulated_state_score(
	board: Node,
	pos: Vector2i,
	grid: Array,
	queue: Array,
	combo: int,
	tier5_streak: int,
	energy: int
) -> float:
	var live_exits: int = 0
	var attack_exits: int = 0
	var useful_directions: int = 0
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var target: Vector2i = pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if not board._is_inside_board(target):
			continue
		if grid[target.y][target.x] == CharacterData.CellType.LIVE:
			live_exits += 1
		elif direction in queue:
			attack_exits += 1
			useful_directions += 1
	var legal_exits: int = live_exits + attack_exits
	var energy_max: int = int(board.ENERGY_QUARTER_UNITS_MAX)
	var has_energy_shield: bool = energy >= int(board.ENERGY_SLOT_COST)
	var has_direction_shield: bool = queue.size() >= 2
	if legal_exits == 0 and energy < energy_max and not has_energy_shield and not has_direction_shield:
		return -6000.0
	var center: Vector2 = Vector2(float(board.COLS - 1), float(board.ROWS - 1)) * 0.5
	var center_distance: float = Vector2(pos).distance_to(center)
	var score: float = float(live_exits) * LIVE_EXIT_VALUE + float(attack_exits) * ATTACK_EXIT_VALUE
	score += float(useful_directions) * USEFUL_DIRECTION_VALUE
	score += float(_unique_direction_count(queue)) * UNIQUE_DIRECTION_VALUE
	score += _combo_hold_value(combo)
	score += _tier5_streak_value(combo, tier5_streak)
	score -= center_distance * CENTER_DISTANCE_PENALTY
	if legal_exits == 1:
		score -= SINGLE_EXIT_PENALTY

	# A full bar is a guaranteed escape from being surrounded, so the last
	# quarter unit is worth far more than the ones before it. Without this the
	# search prices energy at nothing and spends the escape without noticing.
	score += float(energy) * ENERGY_UNIT_VALUE
	if has_energy_shield:
		score += ENERGY_SHIELD_VALUE
	if has_direction_shield:
		score += DIRECTION_SHIELD_VALUE
	if energy >= energy_max:
		score += FULL_BAR_INSURANCE

	# Distance to the nearest kill, and whether the direction that points at it
	# is banked. Nothing else in this function can tell a reachable target apart
	# from one on the far side of the board.
	var nearest_distance: int = -1
	var approach_direction: int = CharacterData.Direction.NONE
	for row in board.ROWS:
		for column in board.COLS:
			if grid[row][column] == CharacterData.CellType.LIVE:
				continue
			var distance: int = absi(column - pos.x) + absi(row - pos.y)
			if nearest_distance >= 0 and distance >= nearest_distance:
				continue
			nearest_distance = distance
			if column != pos.x:
				approach_direction = CharacterData.Direction.RIGHT if column > pos.x \
					else CharacterData.Direction.LEFT
			elif row != pos.y:
				approach_direction = CharacterData.Direction.DOWN if row > pos.y \
					else CharacterData.Direction.UP
			else:
				approach_direction = CharacterData.Direction.NONE
	if nearest_distance >= 0:
		score -= float(nearest_distance) * TARGET_DISTANCE_WEIGHT
		if approach_direction != CharacterData.Direction.NONE and approach_direction in queue:
			score += APPROACH_MATCH_BONUS
	return score

func _push_simulated_direction(queue: Array, max_size: int, direction: int) -> void:
	if queue.size() >= max_size:
		queue.pop_front()
	queue.push_back(direction)

func _unique_direction_count(queue: Array) -> int:
	var unique: Dictionary = {}
	for direction_value in queue:
		unique[int(direction_value)] = true
	return unique.size()

func _combo_payout(combo: int) -> float:
	# Heat is capped at the top reward tier, and this remains defensive for
	# simulated values supplied by verification fixtures.
	var tier: int = clampi(combo, 1, ScoreManager.MAX_COMBO_TIER)
	return float(ScoreManager.COMBO_SCORE_MULTIPLIERS[tier - 1])

func _combo_kill_value(combo: int) -> float:
	return _combo_payout(combo) * COMBO_KILL_MULT

func _combo_hold_value(combo: int) -> float:
	return _combo_payout(combo) * COMBO_HOLD_MULT

func _combo_break_penalty(combo: int) -> float:
	return maxf(0.0, _combo_payout(combo) - _combo_payout(_decayed_combo(combo))) * COMBO_BREAK_MULT

func _future_attack_count(board: Node, from_pos: Vector2i, gained_direction: int) -> int:
	var simulated_queue: Array = board.inventory.queue.duplicate()
	if simulated_queue.size() >= board.inventory.max_size:
		simulated_queue.pop_front()
	simulated_queue.push_back(gained_direction)
	var count: int = 0
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var target: Vector2i = from_pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if not board._is_inside_board(target):
			continue
		if board.grid[target.y][target.x] != CharacterData.CellType.LIVE and direction in simulated_queue:
			count += 1
	return count

func _should_activate_ultimate(board: Node, combo: int) -> bool:
	if _count_dead_cells(board) == 0:
		return false
	return _best_ultimate_plan_score(board) > _combo_hold_value(combo)

func _count_dead_cells(board: Node) -> int:
	var count: int = 0
	for row in board.ROWS:
		for column in board.COLS:
			if board.grid[row][column] != CharacterData.CellType.LIVE:
				count += 1
	return count

func _count_ultimate_targets(board: Node) -> int:
	var count: int = 0
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var destination: Vector2i = _ultimate_destination(board, direction)
		if destination != board.player_pos \
				and board.grid[destination.y][destination.x] != CharacterData.CellType.LIVE:
			count += 1
	return count

func _best_ultimate_direction(board: Node) -> int:
	var best_direction: int = CharacterData.Direction.NONE
	var best_score: float = -INF
	var grid: Array = board.grid.duplicate(true)
	var queue: Array = board.inventory.queue.duplicate()
	var remaining: int = board.get_ultimate_dashes_remaining()
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var destination: Vector2i = _ultimate_destination_on_grid(
			board, board.player_pos, grid, direction
		)
		if destination == board.player_pos:
			continue
		var next_grid: Array = grid.duplicate(true)
		var next_queue: Array = queue.duplicate()
		var next_combo: int = board.score_manager.combo_counter
		var next_tier5_streak: int = board.score_manager.tier5_streak
		var score: float = _apply_simulated_ultimate_dash(
			board,
			destination,
			direction,
			next_grid,
			next_queue,
			next_combo,
			next_tier5_streak,
			remaining
		)
		if next_grid[destination.y][destination.x] == CharacterData.CellType.LIVE \
				and grid[destination.y][destination.x] != CharacterData.CellType.LIVE:
			var kill_state: Vector2i = _advance_combo_and_streak(next_combo, next_tier5_streak)
			next_combo = kill_state.x
			next_tier5_streak = kill_state.y
		score += _ultimate_sequence_score(
			board,
			destination,
			next_grid,
			next_queue,
			next_combo,
			next_tier5_streak,
			remaining - 1
		)
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction

func _best_ultimate_plan_score(board: Node) -> float:
	var best_score: float = -INF
	var grid: Array = board.grid.duplicate(true)
	var queue: Array = board.inventory.queue.duplicate()
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var destination: Vector2i = _ultimate_destination_on_grid(
			board, board.player_pos, grid, direction
		)
		if destination == board.player_pos:
			continue
		var next_grid: Array = grid.duplicate(true)
		var next_queue: Array = queue.duplicate()
		var next_combo: int = board.score_manager.combo_counter
		var next_tier5_streak: int = board.score_manager.tier5_streak
		var score: float = _apply_simulated_ultimate_dash(
			board,
			destination,
			direction,
			next_grid,
			next_queue,
			next_combo,
			next_tier5_streak,
			board.ULT_DASH_COUNT
		)
		if next_grid[destination.y][destination.x] == CharacterData.CellType.LIVE \
				and grid[destination.y][destination.x] != CharacterData.CellType.LIVE:
			var kill_state: Vector2i = _advance_combo_and_streak(next_combo, next_tier5_streak)
			next_combo = kill_state.x
			next_tier5_streak = kill_state.y
		score += _ultimate_sequence_score(
			board,
			destination,
			next_grid,
			next_queue,
			next_combo,
			next_tier5_streak,
			board.ULT_DASH_COUNT - 1
		)
		best_score = maxf(best_score, score)
	return best_score

func _ultimate_sequence_score(
	board: Node,
	pos: Vector2i,
	grid: Array,
	queue: Array,
	combo: int,
	tier5_streak: int,
	remaining: int
) -> float:
	if remaining <= 0:
		return _ultimate_terminal_score(board, pos, grid, queue, combo, tier5_streak)
	var best_score: float = -INF
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var destination: Vector2i = _ultimate_destination_on_grid(board, pos, grid, direction)
		if destination == pos:
			continue
		var next_grid: Array = grid.duplicate(true)
		var next_queue: Array = queue.duplicate()
		var next_combo: int = combo
		var next_tier5_streak: int = tier5_streak
		var score: float = _apply_simulated_ultimate_dash(
			board,
			destination,
			direction,
			next_grid,
			next_queue,
			next_combo,
			next_tier5_streak,
			remaining
		)
		if next_grid[destination.y][destination.x] == CharacterData.CellType.LIVE \
				and grid[destination.y][destination.x] != CharacterData.CellType.LIVE:
			var kill_state: Vector2i = _advance_combo_and_streak(next_combo, next_tier5_streak)
			next_combo = kill_state.x
			next_tier5_streak = kill_state.y
		score += _ultimate_sequence_score(
			board,
			destination,
			next_grid,
			next_queue,
			next_combo,
			next_tier5_streak,
			remaining - 1
		)
		best_score = maxf(best_score, score)
	if best_score == -INF:
		return _ultimate_terminal_score(board, pos, grid, queue, combo, tier5_streak) - 3000.0
	return best_score

func _apply_simulated_ultimate_dash(
	board: Node,
	destination: Vector2i,
	direction: int,
	grid: Array,
	queue: Array,
	combo: int,
	tier5_streak: int,
	remaining: int
) -> float:
	var score: float = 0.0
	if grid[destination.y][destination.x] != CharacterData.CellType.LIVE:
		var kill_state: Vector2i = _advance_combo_and_streak(combo, tier5_streak)
		grid[destination.y][destination.x] = CharacterData.CellType.LIVE
		score += _combo_kill_value(kill_state.x)
		score += _tier5_streak_value(kill_state.x, kill_state.y)
		if not _grid_has_dead_cell(grid):
			score += float(board.BOARD_CLEAR_BONUS)
	var queue_limit: int = board.inventory.max_size + 1 if remaining == 1 else board.inventory.max_size
	_push_simulated_direction(queue, queue_limit, direction)
	if remaining == 1 and board._will_spawn_hit_target_this_turn(destination):
		score -= 5000.0
	return score

func _ultimate_terminal_score(
	board: Node,
	pos: Vector2i,
	grid: Array,
	queue: Array,
	combo: int,
	tier5_streak: int
) -> float:
	var continuation_count: int = 0
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var target: Vector2i = pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if not board._is_inside_board(target):
			continue
		if grid[target.y][target.x] != CharacterData.CellType.LIVE and direction in queue:
			continuation_count += 1
	var terminal_energy: int = (
		int(board.ENERGY_QUARTER_UNITS_MAX) if not _grid_has_dead_cell(grid) else 0
	)
	return (
		_simulated_state_score(
			board, pos, grid, queue, combo, tier5_streak, terminal_energy
		)
		+ float(continuation_count) * ULT_CONTINUATION_VALUE
	)

func _ultimate_destination(board: Node, direction: int) -> Vector2i:
	return _ultimate_destination_on_grid(board, board.player_pos, board.grid, direction)

func _ultimate_destination_on_grid(
	board: Node,
	pos: Vector2i,
	grid: Array,
	direction: int
) -> Vector2i:
	var step: Vector2i = Vector2i(CharacterData.DIR_VECTOR[direction])
	var cursor: Vector2i = pos + step
	var destination: Vector2i = pos
	while board._is_inside_board(cursor):
		destination = cursor
		if grid[cursor.y][cursor.x] != CharacterData.CellType.LIVE:
			break
		cursor += step
	return destination
