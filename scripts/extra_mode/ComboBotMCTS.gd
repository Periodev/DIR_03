class_name DIRExtraComboBotMCTS
extends DIRExtraComboBot

# F4 evaluates real state transitions in DIRExtraSimBoard. Root actions are
# compared across identical spawn samples; rollout actions use a tactical state
# evaluation instead of random walking. X remains a two-input macro so the
# search can plan a protected LIVE-cell reposition and its follow-up attack.

const ROLLOUT_DEPTH := 16
const ROLLOUTS_PER_ACTION := 6
const GAME_OVER_VALUE := -20000.0
const POLICY_JITTER := 8.0

var _planned_bonus_direction: int = CharacterData.Direction.NONE
var _decision_serial: int = 0

func choose_action(board: Node) -> int:
	chosen_direction = CharacterData.Direction.NONE
	if not board.game_state.is_idle():
		return ACTION_NONE
	if not board.bonus_step_armed:
		_planned_bonus_direction = CharacterData.Direction.NONE

	var base := DIRExtraSimBoard.from_board(board)
	if base.ult_remaining > 0:
		chosen_direction = _best_forced_direction(base)
		return ACTION_MOVE if chosen_direction != CharacterData.Direction.NONE else ACTION_NONE

	if base.bonus_step_armed:
		if _is_legal_bonus_step(base, _planned_bonus_direction):
			chosen_direction = _planned_bonus_direction
		else:
			chosen_direction = _best_sim_bonus_step_direction(base)
		_planned_bonus_direction = CharacterData.Direction.NONE
		return ACTION_MOVE if chosen_direction != CharacterData.Direction.NONE else ACTION_NONE

	var selected: Dictionary = _select_candidate(base, _root_candidates(base))
	var kind: int = int(selected["kind"])
	chosen_direction = int(selected["dir"])
	if kind == ACTION_DASH:
		_planned_bonus_direction = chosen_direction
	return kind

func _root_candidates(base: DIRExtraSimBoard) -> Array:
	var candidates: Array = []
	var directions: Array = _legal_directions(base)
	for direction_value in directions:
		var direction: int = int(direction_value)
		candidates.append({"kind": ACTION_MOVE, "dir": direction})
	if base.energy >= DIRExtraSimBoard.ENERGY_SLOT_COST:
		for direction_value in base.legal_directions_live():
			var direction: int = int(direction_value)
			if _dash_has_follow_up(base, direction):
				candidates.append({"kind": ACTION_DASH, "dir": direction})
	if base.energy >= DIRExtraSimBoard.ENERGY_MAX:
		candidates.append({"kind": ACTION_ULT, "dir": CharacterData.Direction.NONE})
	candidates.append({"kind": ACTION_WAIT, "dir": CharacterData.Direction.NONE})
	return candidates

func _best_forced_direction(base: DIRExtraSimBoard) -> int:
	var candidates: Array = []
	if base.ult_remaining > 0:
		for direction_value in CharacterData.DIR_VECTOR:
			var direction: int = int(direction_value)
			if base.ult_destination(direction) != base.player:
				candidates.append({"kind": ACTION_MOVE, "dir": direction})
	else:
		for direction_value in _legal_directions(base):
			candidates.append({"kind": ACTION_MOVE, "dir": int(direction_value)})
	if candidates.is_empty():
		return CharacterData.Direction.NONE
	return int(_select_candidate(base, candidates)["dir"])

func _select_candidate(base: DIRExtraSimBoard, candidates: Array) -> Dictionary:
	_decision_serial += 1
	var best: Dictionary = {"kind": ACTION_WAIT, "dir": CharacterData.Direction.NONE}
	var best_mean: float = -INF
	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		var mean: float = _candidate_mean(base, candidate)
		if mean > best_mean:
			best_mean = mean
			best = candidate
	return best

func _candidate_mean(base: DIRExtraSimBoard, candidate: Dictionary) -> float:
	var total: float = 0.0
	var sample_count: int = 0
	for sample_index in ROLLOUTS_PER_ACTION:
		var sim: DIRExtraSimBoard = base.duplicate_state()
		var rng := RandomNumberGenerator.new()
		rng.seed = int(_decision_serial * 100003 + sample_index * 7919)
		if not _apply_macro(sim, candidate, rng):
			continue
		_rollout(sim, rng, ROLLOUT_DEPTH)
		total += _rollout_value(sim)
		sample_count += 1
	return total / float(sample_count) if sample_count > 0 else -INF

func _apply_macro(sim: DIRExtraSimBoard, candidate: Dictionary, rng: RandomNumberGenerator) -> bool:
	var kind: int = int(candidate["kind"])
	var direction: int = int(candidate["dir"])
	match kind:
		ACTION_MOVE:
			return sim.try_move(direction, rng)
		ACTION_DASH:
			return sim.try_energy_bonus_step() and sim.try_move(direction, rng)
		ACTION_ULT:
			return sim.try_energy_ultimate()
		ACTION_WAIT:
			return sim.try_wait(rng)
	return false

func _rollout(sim: DIRExtraSimBoard, rng: RandomNumberGenerator, depth: int) -> void:
	for _step in depth:
		if sim.game_over:
			return
		var action: Dictionary = _rollout_policy_action(sim, rng)
		if action.has("seed"):
			rng.seed = int(action["seed"])
		if not _apply_macro(sim, action, rng):
			return

func _rollout_policy_action(sim: DIRExtraSimBoard, rng: RandomNumberGenerator) -> Dictionary:
	var candidates: Array = _policy_candidates(sim)
	if candidates.is_empty():
		return {"kind": ACTION_WAIT, "dir": CharacterData.Direction.NONE}

	# Give every candidate the same random spawn stream. Differences in the
	# estimate then come from the action, not from one candidate getting lucky.
	var sample_seed: int = rng.randi()
	var best: Dictionary = candidates[0]
	var best_value: float = -INF
	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		var probe: DIRExtraSimBoard = sim.duplicate_state()
		var probe_rng := RandomNumberGenerator.new()
		probe_rng.seed = sample_seed
		if not _apply_macro(probe, candidate, probe_rng):
			continue
		var value: float = _policy_action_value(sim, probe, candidate)
		value += rng.randf_range(-POLICY_JITTER, POLICY_JITTER)
		if value > best_value:
			best_value = value
			best = candidate
	best["seed"] = sample_seed
	return best

func _policy_candidates(sim: DIRExtraSimBoard) -> Array:
	var candidates: Array = []
	if sim.ult_remaining > 0:
		for direction_value in CharacterData.DIR_VECTOR:
			var direction: int = int(direction_value)
			if sim.ult_destination(direction) != sim.player:
				candidates.append({"kind": ACTION_MOVE, "dir": direction})
		return candidates

	var directions: Array = (
		sim.legal_directions_live() if sim.bonus_step_armed else _legal_directions(sim)
	)
	for direction_value in directions:
		var direction: int = int(direction_value)
		candidates.append({"kind": ACTION_MOVE, "dir": direction})
	if sim.bonus_step_armed:
		return candidates
	if sim.energy >= DIRExtraSimBoard.ENERGY_SLOT_COST:
		for direction_value in sim.legal_directions_live():
			var direction: int = int(direction_value)
			if _dash_has_follow_up(sim, direction):
				candidates.append({"kind": ACTION_DASH, "dir": direction})
	if sim.energy >= DIRExtraSimBoard.ENERGY_MAX:
		candidates.append({"kind": ACTION_ULT, "dir": CharacterData.Direction.NONE})
	candidates.append({"kind": ACTION_WAIT, "dir": CharacterData.Direction.NONE})
	return candidates

func _dash_has_follow_up(sim: DIRExtraSimBoard, direction: int) -> bool:
	if direction not in sim.legal_directions_live():
		return false
	var probe: DIRExtraSimBoard = sim.duplicate_state()
	var probe_rng := RandomNumberGenerator.new()
	probe_rng.seed = 1
	if not probe.try_energy_bonus_step() or not probe.try_move(direction, probe_rng):
		return false
	return not probe.legal_directions_attack().is_empty()

func _policy_action_value(
	before: DIRExtraSimBoard,
	after: DIRExtraSimBoard,
	candidate: Dictionary
) -> float:
	var value: float = _tactical_value(after)
	var kind: int = int(candidate["kind"])
	if kind == ACTION_DASH:
		# X only repositions onto LIVE cells. Reward concrete attacks available
		# from the landing cell; no attack can consume the armed step itself.
		value += float(after.legal_directions_attack().size()) * 75.0
	elif kind == ACTION_WAIT and not _legal_directions(before).is_empty():
		value -= 240.0
	return value

func _legal_directions(sim: DIRExtraSimBoard) -> Array:
	var directions: Array = []
	directions.append_array(sim.legal_directions_attack())
	directions.append_array(sim.legal_directions_live())
	return directions

func _is_legal_bonus_step(sim: DIRExtraSimBoard, direction: int) -> bool:
	return direction != CharacterData.Direction.NONE and direction in sim.legal_directions_live()

func _best_sim_bonus_step_direction(base: DIRExtraSimBoard) -> int:
	var candidates: Array = []
	for direction_value in base.legal_directions_live():
		candidates.append({"kind": ACTION_MOVE, "dir": int(direction_value)})
	if candidates.is_empty():
		return CharacterData.Direction.NONE
	return int(_select_candidate(base, candidates)["dir"])

func _rollout_value(sim: DIRExtraSimBoard) -> float:
	if sim.game_over:
		return GAME_OVER_VALUE + float(sim.score)
	return float(sim.score) + _tactical_value(sim) * 0.12

func _tactical_value(sim: DIRExtraSimBoard) -> float:
	if sim.game_over:
		return GAME_OVER_VALUE

	var attack_count: int = sim.legal_directions_attack().size()
	var live_count: int = sim.legal_directions_live().size()
	var legal_count: int = attack_count + live_count
	var value: float = float(sim.score) * 4.0
	value += _combo_position_value(sim.combo)
	value += float(sim.energy) * 6.0
	value += float(attack_count) * 85.0
	value += float(live_count) * 28.0
	value += float(_useful_queue_count(sim)) * 18.0
	value -= float(_nearest_attack_setup_distance(sim)) * 10.0

	if sim.combo >= DIRExtraSimBoard.MAX_COMBO_TIER:
		var streak_progress: int = posmod(
			sim.tier5_streak, DIRExtraSimBoard.TIER5_STREAK_THRESHOLD
		)
		value += float(streak_progress) * 55.0
	if sim.energy >= DIRExtraSimBoard.ENERGY_MAX:
		value += 220.0
	if sim.ult_remaining > 0:
		value += float(sim.ult_remaining) * 95.0
		value += float(_ultimate_line_target_count(sim)) * 110.0
	if sim.will_spawn_hit(sim.player):
		if sim.energy < DIRExtraSimBoard.ENERGY_SLOT_COST and sim.queue.size() < 2:
			value -= 5000.0
		else:
			value -= 260.0
	if legal_count == 1:
		value -= 180.0
	return value

func _combo_position_value(combo: int) -> float:
	match combo:
		1: return 18.0
		2: return 45.0
		3: return 110.0
		4: return 230.0
		5: return 420.0
	return 0.0

func _useful_queue_count(sim: DIRExtraSimBoard) -> int:
	var useful: int = 0
	for direction_value in sim.queue:
		var direction: int = int(direction_value)
		var target: Vector2i = sim.neighbour(sim.player, direction)
		if target.x >= 0 and sim.grid[target.y][target.x] != DIRExtraSimBoard.LIVE:
			useful += 1
	return useful

func _nearest_attack_setup_distance(sim: DIRExtraSimBoard) -> int:
	var nearest: int = DIRExtraSimBoard.COLS + DIRExtraSimBoard.ROWS
	for row in DIRExtraSimBoard.ROWS:
		for column in DIRExtraSimBoard.COLS:
			if sim.grid[row][column] == DIRExtraSimBoard.LIVE:
				continue
			var target := Vector2i(column, row)
			var distance: int = absi(target.x - sim.player.x) + absi(target.y - sim.player.y)
			nearest = mini(nearest, distance)
	return nearest

func _ultimate_line_target_count(sim: DIRExtraSimBoard) -> int:
	var count: int = 0
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var destination: Vector2i = sim.ult_destination(direction)
		if destination != sim.player \
				and sim.grid[destination.y][destination.x] != DIRExtraSimBoard.LIVE:
			count += 1
	return count
