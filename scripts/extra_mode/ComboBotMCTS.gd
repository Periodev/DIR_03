class_name DIRExtraComboBotMCTS
extends DIRExtraComboBot

# F4 evaluates real state transitions in DIRExtraSimBoard instead of scoring
# directions with the shipped heuristic. X is modeled as a two-input macro:
# arm the frozen step, then execute a specific direction before the spawn clock
# resumes. That lets the search distinguish preserving an adjacent attack from
# stepping into the next attack position.

const ROLLOUT_DEPTH := 32
const ROLLOUTS_PER_ACTION := 16
const GAME_OVER_VALUE := -1000000.0

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
		if _is_legal_follow_up(base, _planned_bonus_direction):
			chosen_direction = _planned_bonus_direction
		else:
			chosen_direction = _best_forced_direction(base)
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
		for direction_value in directions:
			var direction: int = int(direction_value)
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
		if not _apply_macro(sim, action, rng):
			return

func _rollout_policy_action(sim: DIRExtraSimBoard, rng: RandomNumberGenerator) -> Dictionary:
	if sim.ult_remaining > 0 or sim.bonus_step_armed:
		var direction: int = _first_legal_direction(sim)
		return {"kind": ACTION_MOVE, "dir": direction}

	if sim.energy >= DIRExtraSimBoard.ENERGY_MAX:
		return {"kind": ACTION_ULT, "dir": CharacterData.Direction.NONE}

	var attacks: Array = sim.legal_directions_attack()
	if attacks.is_empty() and sim.energy >= DIRExtraSimBoard.ENERGY_SLOT_COST \
			and sim.combo >= ScoreManager.MAX_COMBO_TIER:
		var chase_direction: int = _find_chase_direction(sim, rng)
		if chase_direction != CharacterData.Direction.NONE:
			return {"kind": ACTION_DASH, "dir": chase_direction}

	var directions: Array = _legal_directions(sim)
	if not directions.is_empty():
		return {"kind": ACTION_MOVE, "dir": int(directions[rng.randi_range(0, directions.size() - 1)])}
	return {"kind": ACTION_WAIT, "dir": CharacterData.Direction.NONE}

func _find_chase_direction(sim: DIRExtraSimBoard, rng: RandomNumberGenerator) -> int:
	var live_directions: Array = sim.legal_directions_live().duplicate()
	for index in range(live_directions.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var current: int = int(live_directions[index])
		live_directions[index] = live_directions[swap_index]
		live_directions[swap_index] = current
	for direction_value in live_directions:
		var direction: int = int(direction_value)
		var chase: DIRExtraSimBoard = sim.duplicate_state()
		if not chase.try_energy_bonus_step() or not chase.try_move(direction, rng):
			continue
		if not chase.legal_directions_attack().is_empty():
			return direction
	return CharacterData.Direction.NONE

func _first_legal_direction(sim: DIRExtraSimBoard) -> int:
	if sim.ult_remaining > 0:
		for direction_value in CharacterData.DIR_VECTOR:
			var direction: int = int(direction_value)
			if sim.ult_destination(direction) != sim.player:
				return direction
	var directions: Array = _legal_directions(sim)
	return int(directions[0]) if not directions.is_empty() else CharacterData.Direction.NONE

func _legal_directions(sim: DIRExtraSimBoard) -> Array:
	var directions: Array = []
	directions.append_array(sim.legal_directions_attack())
	directions.append_array(sim.legal_directions_live())
	return directions

func _is_legal_follow_up(sim: DIRExtraSimBoard, direction: int) -> bool:
	return direction != CharacterData.Direction.NONE and direction in _legal_directions(sim)

func _rollout_value(sim: DIRExtraSimBoard) -> float:
	if sim.game_over:
		return GAME_OVER_VALUE + float(sim.score)
	# Real score is the objective. Heat and energy only break otherwise-equal
	# rollouts, so they cannot outweigh even a single real score point.
	return float(sim.score) + float(sim.combo) * 0.1 + float(sim.energy) * 0.01
