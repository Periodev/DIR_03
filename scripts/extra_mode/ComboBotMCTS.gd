class_name DIRExtraComboBotMCTS
extends RefCounted

# Flat Monte Carlo action selection: no hand-weighted evaluation function, no
# constants to mistune. Every legal action this turn is rolled out several
# times against DIRExtraSimBoard (a native GDScript replica of Board.gd's
# rules) to a fixed depth, scored by the REAL points gained during that
# rollout, and the action with the highest mean wins. A move that leads
# toward death simply stops earning points early -- there is no separate
# death-penalty constant to calibrate, because "no more score arrives" is
# already the correct, proportionate consequence.
#
# This is deliberately not full MCTS (no UCB tree, no node reuse across
# turns): at ROLLOUTS_PER_ACTION x ROLLOUT_DEPTH samples inside a 0.16s
# real-time budget, a full tree's bookkeeping overhead would eat into the
# sampling budget it exists to spend better. Flat per-action averaging is the
# simpler thing that still gets the core benefit -- decisions driven by
# simulated real outcomes, not a fitted heuristic -- at this budget.
#
# The one deliberately hand-written piece is _rollout_policy_action(): what
# the simulated player does on turns AFTER the root decision, for the rest of
# each rollout. It only needs to be reasonably non-suicidal, applied
# identically to every candidate's rollouts -- it does not need tuning,
# because any consistent policy still ranks the root candidates correctly
# by their real relative outcomes. That is what makes this robust in a way
# ComboBotTuned.gd's weights were not: nothing here is fit to a distribution
# of games that might not match the real one.

const ACTION_NONE := 0
const ACTION_MOVE := 1
const ACTION_DASH := 2
const ACTION_ULT := 3
const ACTION_WAIT := 4

const ROLLOUT_DEPTH := 24
const ROLLOUTS_PER_ACTION := 20

var chosen_direction: int = CharacterData.Direction.NONE
var _rng := RandomNumberGenerator.new()

func choose_action(board: Node) -> int:
	chosen_direction = CharacterData.Direction.NONE
	if not board.game_state.is_idle():
		return ACTION_NONE

	# Forced follow-through: these aren't real choices, the board requires
	# exactly one action here, so there is nothing to compare.
	if board.get_ultimate_dashes_remaining() > 0:
		var sim := DIRExtraSimBoard.from_board(board)
		var direction: int = _greedy_ultimate_direction(sim)
		chosen_direction = direction
		return ACTION_MOVE if direction != CharacterData.Direction.NONE else ACTION_NONE

	if board.bonus_step_armed:
		var sim := DIRExtraSimBoard.from_board(board)
		var direction: int = _greedy_follow_up_direction(sim)
		chosen_direction = direction
		return ACTION_MOVE if direction != CharacterData.Direction.NONE else ACTION_NONE

	var base := DIRExtraSimBoard.from_board(board)
	var candidates: Array = []
	for d in base.legal_directions_attack():
		candidates.append({"kind": ACTION_MOVE, "dir": d})
	for d in base.legal_directions_live():
		candidates.append({"kind": ACTION_MOVE, "dir": d})
	if board.get_energy_quarter_units() >= int(board.ENERGY_SLOT_COST):
		candidates.append({"kind": ACTION_DASH, "dir": CharacterData.Direction.NONE})
	if board.get_energy_quarter_units() >= int(board.ENERGY_QUARTER_UNITS_MAX):
		candidates.append({"kind": ACTION_ULT, "dir": CharacterData.Direction.NONE})
	candidates.append({"kind": ACTION_WAIT, "dir": CharacterData.Direction.NONE})

	var best_kind: int = ACTION_WAIT
	var best_dir: int = CharacterData.Direction.NONE
	var best_mean: float = -INF
	for candidate in candidates:
		var kind: int = candidate.kind
		var direction: int = candidate.dir
		var total: float = 0.0
		var legal: bool = true
		for _i in ROLLOUTS_PER_ACTION:
			var sim: DIRExtraSimBoard = base.duplicate_state()
			if not _apply_root(sim, kind, direction):
				legal = false
				break
			_rollout(sim, ROLLOUT_DEPTH)
			total += float(sim.score)
		if not legal:
			continue
		var mean: float = total / float(ROLLOUTS_PER_ACTION)
		if mean > best_mean:
			best_mean = mean
			best_kind = kind
			best_dir = direction

	chosen_direction = best_dir
	return best_kind

func _apply_root(sim: DIRExtraSimBoard, kind: int, direction: int) -> bool:
	match kind:
		ACTION_MOVE:
			return sim.try_move(direction, _rng)
		ACTION_DASH:
			return sim.try_energy_bonus_step()
		ACTION_ULT:
			return sim.try_energy_ultimate()
		ACTION_WAIT:
			return sim.try_wait(_rng)
	return false

func _rollout(sim: DIRExtraSimBoard, depth: int) -> void:
	for _i in depth:
		if sim.game_over:
			return
		var step: Dictionary = _rollout_policy_action(sim)
		match int(step.kind):
			ACTION_MOVE:
				sim.try_move(int(step.dir), _rng)
			ACTION_ULT:
				sim.try_energy_ultimate()
			ACTION_WAIT:
				sim.try_wait(_rng)
		if sim.game_over:
			return

func _rollout_policy_action(sim: DIRExtraSimBoard) -> Dictionary:
	if sim.ult_remaining > 0:
		var direction: int = _greedy_ultimate_direction(sim)
		if direction != CharacterData.Direction.NONE:
			return {"kind": ACTION_MOVE, "dir": direction}
		return {"kind": ACTION_WAIT, "dir": CharacterData.Direction.NONE}
	if sim.bonus_step_armed:
		var direction: int = _greedy_follow_up_direction(sim)
		if direction != CharacterData.Direction.NONE:
			return {"kind": ACTION_MOVE, "dir": direction}
		return {"kind": ACTION_WAIT, "dir": CharacterData.Direction.NONE}
	if sim.energy >= DIRExtraSimBoard.ENERGY_MAX:
		return {"kind": ACTION_ULT, "dir": CharacterData.Direction.NONE}
	var attacks: Array = sim.legal_directions_attack()
	if not attacks.is_empty():
		return {"kind": ACTION_MOVE, "dir": attacks[_rng.randi_range(0, attacks.size() - 1)]}
	var moves: Array = sim.legal_directions_live()
	if not moves.is_empty():
		return {"kind": ACTION_MOVE, "dir": moves[_rng.randi_range(0, moves.size() - 1)]}
	return {"kind": ACTION_WAIT, "dir": CharacterData.Direction.NONE}

func _greedy_follow_up_direction(sim: DIRExtraSimBoard) -> int:
	var attacks: Array = sim.legal_directions_attack()
	if not attacks.is_empty():
		return attacks[0]
	var moves: Array = sim.legal_directions_live()
	if not moves.is_empty():
		return moves[_rng.randi_range(0, moves.size() - 1)]
	return CharacterData.Direction.NONE

func _greedy_ultimate_direction(sim: DIRExtraSimBoard) -> int:
	var fallback: int = CharacterData.Direction.NONE
	for d in CharacterData.DIR_VECTOR:
		var destination: Vector2i = sim.ult_destination(d)
		if destination == sim.player:
			continue
		if fallback == CharacterData.Direction.NONE:
			fallback = d
		if sim.grid[destination.y][destination.x] == DIRExtraSimBoard.DEAD:
			return d
	return fallback
