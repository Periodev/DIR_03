class_name DIRExtraChainBot
extends DIRExtraComboBot

func choose_action(board: Node) -> int:
	chosen_direction = CharacterData.Direction.NONE
	if not board.game_state.is_idle():
		return ACTION_NONE

	if board.get_ultimate_dashes_remaining() > 0:
		chosen_direction = _best_ultimate_direction(board)
		return ACTION_MOVE if chosen_direction != CharacterData.Direction.NONE else ACTION_NONE

	var attacks: Array[int] = _attack_directions(board)
	if board.bonus_step_armed:
		chosen_direction = _best_step_continuation_direction(board)
		if chosen_direction == CharacterData.Direction.NONE:
			chosen_direction = _best_bonus_move_direction(board)
		return ACTION_MOVE if chosen_direction != CharacterData.Direction.NONE else ACTION_NONE

	var energy: int = board.get_energy_quarter_units()
	var can_step: bool = energy >= board.ENERGY_SLOT_COST
	var safe_attacks: Array[int] = _safe_attack_directions(board, attacks)
	if not safe_attacks.is_empty():
		chosen_direction = _best_attack_direction(board, safe_attacks)
		return ACTION_MOVE

	var combo: int = board.score_manager.combo_counter
	if combo > 0 and can_step \
			and _best_step_continuation_direction(board) != CharacterData.Direction.NONE:
		return ACTION_DASH

	chosen_direction = _best_safe_normal_direction(board)
	if chosen_direction != CharacterData.Direction.NONE:
		return ACTION_MOVE

	if energy >= board.ENERGY_QUARTER_UNITS_MAX and _is_extreme_danger(board):
		return ACTION_ULT

	if not attacks.is_empty():
		chosen_direction = _best_attack_direction(board, attacks)
		return ACTION_MOVE

	chosen_direction = _best_normal_direction(board, false)
	if chosen_direction != CharacterData.Direction.NONE:
		return ACTION_MOVE
	return ACTION_WAIT

func _safe_attack_directions(board: Node, attacks: Array[int]) -> Array[int]:
	var safe: Array[int] = []
	for direction in attacks:
		var target: Vector2i = board.player_pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if not board._will_spawn_hit_target_this_turn(target):
			safe.append(direction)
	return safe

func _best_step_continuation_direction(board: Node) -> int:
	var best_direction: int = CharacterData.Direction.NONE
	var best_score: float = -INF
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var target: Vector2i = board.player_pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if not board._is_inside_board(target):
			continue
		if board.grid[target.y][target.x] != CharacterData.CellType.LIVE:
			continue
		if board._will_spawn_hit_target_this_turn(target):
			continue
		if _future_attack_count(board, target, direction) <= 0:
			continue
		var score: float = _direction_plan_score(board, direction, true)
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction

func _best_bonus_move_direction(board: Node) -> int:
	var best_direction: int = CharacterData.Direction.NONE
	var best_score: float = -INF
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var target: Vector2i = board.player_pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if not board._is_inside_board(target):
			continue
		if board.grid[target.y][target.x] != CharacterData.CellType.LIVE:
			continue
		if board._will_spawn_hit_target_this_turn(target):
			continue
		var score: float = _direction_plan_score(board, direction, true)
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction

func _best_safe_normal_direction(board: Node) -> int:
	var best_direction: int = CharacterData.Direction.NONE
	var best_score: float = -INF
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var target: Vector2i = board.player_pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if not board._is_inside_board(target):
			continue
		if board.grid[target.y][target.x] != CharacterData.CellType.LIVE:
			continue
		if board._will_spawn_hit_target_this_turn(target):
			continue
		var score: float = _direction_plan_score(board, direction, false)
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction

func _has_safe_live_neighbor(board: Node) -> bool:
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var target: Vector2i = board.player_pos + Vector2i(CharacterData.DIR_VECTOR[direction])
		if board._is_inside_board(target) \
				and board.grid[target.y][target.x] == CharacterData.CellType.LIVE \
				and not board._will_spawn_hit_target_this_turn(target):
			return true
	return false

func _is_extreme_danger(board: Node) -> bool:
	var attacks: Array[int] = _attack_directions(board)
	return _safe_attack_directions(board, attacks).is_empty() \
			and not _has_safe_live_neighbor(board)
