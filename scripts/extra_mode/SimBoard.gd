class_name DIRExtraSimBoard
extends RefCounted

# Headless, node-free replica of Board.gd's rules -- no Node2D, no visuals, no
# timers, just the grid/queue/energy/heat state and the same turn/spawn-cycle
# logic, so it can be copied and stepped thousands of times per decision for
# a rollout-based search (see ComboBotMCTS.gd) without the cost of real scene
# nodes and without the risk that sank the CMA-ES weights: those were tuned
# and "validated" entirely inside a Python port, whose random-number
# generator produces different boards than Godot's for the same seed number,
# so the validation never actually applied to the real game. This file is
# GDScript from the start; a rollout run with it IS a rollout of the real
# rules, not of a foreign model of them.
#
# Ported from tools/extra_cma.py's Board class (validated there against real
# Board.gd's benchmark action ratios). If Board.gd's rules change, this and
# that Python port both drift out of sync -- update both, per AGENTS.md's
# parity requirement.

const COLS := 5
const ROWS := 5
const SPAWN_CYCLE_STEPS := 2
const SPAWNS_PER_CYCLE := 2
const DELAYED_SPAWN_SCORE_THRESHOLD := 10000
const DELAYED_SPAWN_MAX_PER_CYCLE := 2
const DELAYED_SPAWN_COUNTDOWN := 2
const OPENING_GRACE_TURNS := 1
const ENERGY_MAX := 16
const ENERGY_SLOT_COST := 4
const ULT_DASH_COUNT := 4
const QUEUE_MAX := 3
const ULT_COMPLETION_OVERFLOW := 1

const LIVE := 0
const DEAD := 1

const MAX_COMBO_TIER := 5
const COMBO_SCORE_MULTIPLIERS := [1, 2, 5, 10, 20]
const BASE_KILL_SCORE := 1
const TIER5_STREAK_THRESHOLD := 5
const TIER5_STREAK_ENERGY_BONUS := 4
const TIER5_STREAK_BONUS_BASE := 200
const TIER5_STREAK_BONUS_STEP := 100
const TIER5_STREAK_BONUS_CAP := 1000
const BOARD_CLEAR_BONUS := 2000

var grid: Array = []  # grid[row][col] = LIVE/DEAD
var player: Vector2i
var queue: Array = []  # Array[int] of CharacterData.Direction, oldest first
var energy: int = 0
var combo: int = 0
var score: int = 0
var run_score: int = 0
var max_combo: int = 0
var tier5_streak: int = 0
var defeats: int = 0
var cycle_counter: int = 0
var cycle_resolved: bool = false
var candidates: Array = []  # Array[Vector2i]
var delayed_candidates: Array = []  # Array[Vector2i]
var delayed_spawn_countdown: int = 0
var opening_grace: int = OPENING_GRACE_TURNS
var bonus_step_armed: bool = false
var ult_remaining: int = 0
var ult_chain_started: bool = false
var survival_turns: int = 0
var game_over: bool = false

func duplicate_state() -> DIRExtraSimBoard:
	var copy := DIRExtraSimBoard.new()
	copy.grid = grid.duplicate(true)
	copy.player = player
	copy.queue = queue.duplicate()
	copy.energy = energy
	copy.combo = combo
	copy.score = score
	copy.run_score = run_score
	copy.max_combo = max_combo
	copy.defeats = defeats
	copy.cycle_counter = cycle_counter
	copy.cycle_resolved = cycle_resolved
	copy.candidates = candidates.duplicate()
	copy.delayed_candidates = delayed_candidates.duplicate()
	copy.delayed_spawn_countdown = delayed_spawn_countdown
	copy.opening_grace = opening_grace
	copy.bonus_step_armed = bonus_step_armed
	copy.ult_remaining = ult_remaining
	copy.ult_chain_started = ult_chain_started
	copy.survival_turns = survival_turns
	copy.game_over = game_over
	copy.tier5_streak = tier5_streak
	return copy

static func from_board(board: Node) -> DIRExtraSimBoard:
	var sim := DIRExtraSimBoard.new()
	sim.grid = []
	for row in board.grid:
		sim.grid.append((row as Array).duplicate())
	sim.player = board.player_pos
	sim.queue = board.inventory.queue.duplicate()
	sim.energy = board.get_energy_quarter_units()
	sim.combo = board.score_manager.combo_counter
	sim.score = 0  # rollouts score their own delta, not the real running total
	sim.run_score = board.score_manager.score
	sim.max_combo = sim.combo
	sim.cycle_counter = board.cycle_counter
	sim.cycle_resolved = board.cycle_resolved
	sim.candidates = (board.candidate_cells as Array).duplicate()
	sim.delayed_candidates = (board.delayed_candidate_cells as Array).duplicate()
	sim.delayed_spawn_countdown = board.delayed_spawn_countdown
	sim.opening_grace = board._opening_grace_turns_remaining
	sim.bonus_step_armed = board.bonus_step_armed
	sim.ult_remaining = board.get_ultimate_dashes_remaining()
	sim.ult_chain_started = false
	sim.tier5_streak = board.score_manager.tier5_streak
	sim.survival_turns = board.survival_turns
	return sim

static func energy_gain_for_combo(c: int) -> int:
	match c:
		1: return 1
		2: return 2
		3: return 2
		4: return 4
		_:
			if c >= 5:
				return 4
	return 0

static func energy_gain_for_kill(c: int, streak: int) -> int:
	return energy_gain_for_combo(c) + tier5_streak_energy_bonus(c, streak)

static func tier5_streak_energy_bonus(c: int, streak: int) -> int:
	if c >= MAX_COMBO_TIER and streak > 0 and streak % TIER5_STREAK_THRESHOLD == 0:
		return TIER5_STREAK_ENERGY_BONUS
	return 0

static func combo_tier(c: int) -> int:
	return clampi(c, 1, MAX_COMBO_TIER)

static func combo_multiplier(c: int) -> int:
	return COMBO_SCORE_MULTIPLIERS[combo_tier(c) - 1]

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < COLS and p.y >= 0 and p.y < ROWS

func neighbour(p: Vector2i, d: int) -> Vector2i:
	var np: Vector2i = p + CharacterData.DIR_VECTOR[d]
	return np if in_bounds(np) else Vector2i(-1, -1)

func push(d: int) -> void:
	while queue.size() >= QUEUE_MAX:
		queue.pop_front()
	queue.push_back(d)

func push_ult_completion(d: int) -> void:
	var limit: int = QUEUE_MAX + ULT_COMPLETION_OVERFLOW
	while queue.size() >= limit:
		queue.pop_front()
	queue.push_back(d)

func advance_combo() -> void:
	combo = mini(combo + 1, MAX_COMBO_TIER)

func decay_combo() -> void:
	combo = maxi(0, combo - 1)
	tier5_streak = 0

func reset_combo() -> void:
	combo = 0
	tier5_streak = 0

func on_kill() -> int:
	max_combo = maxi(max_combo, combo)
	var points: int = BASE_KILL_SCORE * combo_multiplier(combo)
	score += points
	if combo == MAX_COMBO_TIER:
		tier5_streak += 1
		if tier5_streak % TIER5_STREAK_THRESHOLD == 0:
			var block := floori(
				float(tier5_streak) / float(TIER5_STREAK_THRESHOLD)
			)
			var streak_bonus: int = mini(
				TIER5_STREAK_BONUS_BASE + TIER5_STREAK_BONUS_STEP * (block - 1),
				TIER5_STREAK_BONUS_CAP
			)
			points += streak_bonus
			score += streak_bonus
	defeats += 1
	return points

func will_spawn_hit(target: Vector2i) -> bool:
	if opening_grace > 0:
		return false
	var regular_spawn_due: bool = not cycle_resolved \
			and cycle_counter + 1 >= SPAWN_CYCLE_STEPS \
			and target in candidates
	var delayed_spawn_due: bool = delayed_spawn_countdown == 1 \
			and target in delayed_candidates
	return regular_spawn_due or delayed_spawn_due

func charge_energy(c: int) -> void:
	energy = mini(energy + energy_gain_for_kill(c, tier5_streak), ENERGY_MAX)

func charge_streak_energy(c: int) -> void:
	energy = mini(energy + tier5_streak_energy_bonus(c, tier5_streak), ENERGY_MAX)

func has_attack_direction(d: int) -> bool:
	if ult_remaining > 0:
		return true
	return d in queue

func consume_attack_direction(d: int) -> bool:
	if ult_remaining > 0:
		ult_remaining -= 1
		ult_chain_started = true
		return true
	var idx: int = queue.find(d)
	if idx < 0:
		return false
	queue.remove_at(idx)
	return true

# -- actions --------------------------------------------------------------

func try_move(d: int, rng: RandomNumberGenerator) -> bool:
	if ult_remaining > 0:
		return _try_ultimate_dash(d, rng)
	var is_bonus: bool = bonus_step_armed
	var target: Vector2i = neighbour(player, d)
	if target.x < 0:
		return false
	if grid[target.y][target.x] == LIVE:
		return _complete_live_move(d, target, is_bonus, rng)
	if is_bonus:
		return false
	if not consume_attack_direction(d):
		return false
	_kill_flow(target, false)
	var killed: bool = grid[target.y][target.x] == LIVE
	if killed:
		player = target
	return _finalize_turn(false, true, rng)

func _complete_live_move(d: int, target: Vector2i, is_bonus: bool, rng: RandomNumberGenerator) -> bool:
	player = target
	if is_bonus:
		push(d)
		bonus_step_armed = false
		return _finalize_turn(true, false, rng)
	decay_combo()
	if not will_spawn_hit(target):
		push(d)
	return _finalize_turn(false, true, rng)

func try_wait(rng: RandomNumberGenerator) -> bool:
	if bonus_step_armed or ult_remaining > 0:
		return false
	decay_combo()
	return _finalize_turn(false, true, rng)

func try_energy_bonus_step() -> bool:
	if bonus_step_armed or ult_remaining > 0:
		return false
	if energy < ENERGY_SLOT_COST:
		return false
	energy -= ENERGY_SLOT_COST
	bonus_step_armed = true
	return true

func try_energy_ultimate() -> bool:
	if bonus_step_armed or ult_remaining > 0:
		return false
	if energy < ENERGY_MAX:
		return false
	energy = 0
	ult_remaining = ULT_DASH_COUNT
	ult_chain_started = false
	return true

func ult_destination(d: int) -> Vector2i:
	var step: Vector2i = CharacterData.DIR_VECTOR[d]
	var cursor: Vector2i = player + step
	var destination: Vector2i = player
	while in_bounds(cursor):
		destination = cursor
		if grid[cursor.y][cursor.x] != LIVE:
			break
		cursor += step
	return destination

func _try_ultimate_dash(d: int, rng: RandomNumberGenerator) -> bool:
	if ult_remaining <= 0:
		return false
	var destination: Vector2i = ult_destination(d)
	if destination == player:
		return false
	var hits_dead: bool = grid[destination.y][destination.x] == DEAD
	if not consume_attack_direction(d):
		return false
	var freeze: bool = ult_remaining > 0
	var completes: bool = ult_remaining == 0
	if hits_dead:
		_kill_flow(destination, true, true)
		if grid[destination.y][destination.x] == LIVE:
			player = destination
	else:
		player = destination
	if completes:
		push_ult_completion(d)
	else:
		push(d)
	if ult_chain_started and ult_remaining == 0:
		ult_chain_started = false
	return _finalize_turn(freeze, false, rng)

func _kill_flow(pos: Vector2i, energy_sterile: bool, allow_streak_energy: bool = false) -> void:
	grid[pos.y][pos.x] = LIVE
	advance_combo()
	on_kill()
	if allow_streak_energy:
		charge_streak_energy(combo)
	elif not energy_sterile:
		charge_energy(combo)
	if not _has_any_dead_cell():
		score += BOARD_CLEAR_BONUS
		energy = ENERGY_MAX

func _has_any_dead_cell() -> bool:
	for row in grid:
		if DEAD in row:
			return true
	return false

# -- turn / spawn clock -----------------------------------------------------

func _finalize_turn(freeze: bool, count_turn: bool, rng: RandomNumberGenerator) -> bool:
	if count_turn:
		survival_turns += 1
	if not freeze:
		if opening_grace > 0:
			opening_grace -= 1
		else:
			_advance_cycle(rng)
	_check_game_over()
	return true

func _start_new_cycle(rng: RandomNumberGenerator) -> void:
	var available: Array = []
	for y in ROWS:
		for x in COLS:
			if grid[y][x] == LIVE:
				available.append(Vector2i(x, y))
	# Fisher-Yates using the rollout's own RNG stream, matching
	# Array.shuffle()'s effect without touching the engine-global RNG (which
	# would make every parallel rollout share one stream).
	for i in range(available.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = available[i]
		available[i] = available[j]
		available[j] = tmp
	var regular_count: int = mini(get_spawns_per_cycle(), available.size())
	candidates = available.slice(0, regular_count)
	if run_score + score >= DELAYED_SPAWN_SCORE_THRESHOLD:
		var delayed_count: int = mini(
			rng.randi_range(0, DELAYED_SPAWN_MAX_PER_CYCLE),
			available.size() - regular_count
		)
		delayed_candidates = available.slice(
			regular_count,
			regular_count + delayed_count
		)
		if delayed_count > 0:
			delayed_spawn_countdown = DELAYED_SPAWN_COUNTDOWN

func get_spawns_per_cycle() -> int:
	return SPAWNS_PER_CYCLE

func _advance_cycle(rng: RandomNumberGenerator) -> void:
	_advance_delayed_candidates()
	cycle_counter += 1
	if cycle_resolved:
		if cycle_counter >= SPAWN_CYCLE_STEPS:
			cycle_counter = 0
			cycle_resolved = false
		return
	if cycle_counter == 1:
		_start_new_cycle(rng)
	elif cycle_counter >= SPAWN_CYCLE_STEPS:
		var cleaned: Array = []
		for pos in candidates:
			if grid[pos.y][pos.x] == LIVE:
				cleaned.append(pos)
		candidates = cleaned
		for pos in candidates:
			_apply_candidate_spawn(pos)
		candidates = []
		cycle_counter = 0
		cycle_resolved = false

func _advance_delayed_candidates() -> void:
	if delayed_candidates.is_empty():
		delayed_spawn_countdown = 0
		return
	delayed_spawn_countdown -= 1
	if delayed_spawn_countdown > 0:
		return
	for pos in delayed_candidates:
		_apply_candidate_spawn(pos)
	delayed_candidates = []
	delayed_spawn_countdown = 0

func _apply_candidate_spawn(pos: Vector2i) -> void:
	if grid[pos.y][pos.x] != LIVE:
		return
	if pos == player:
		_resolve_player_spawn_hit(pos)
		return
	grid[pos.y][pos.x] = DEAD

func _resolve_player_spawn_hit(pos: Vector2i) -> void:
	if energy >= ENERGY_SLOT_COST:
		energy -= ENERGY_SLOT_COST
		reset_combo()
		on_kill()
		return
	var consumed: int = 0
	for _i in mini(2, queue.size()):
		queue.pop_front()
		consumed += 1
	if consumed >= 2:
		reset_combo()
		on_kill()
	else:
		grid[pos.y][pos.x] = DEAD

func _check_game_over() -> void:
	if grid[player.y][player.x] != LIVE:
		game_over = true
		return
	for d in CharacterData.DIR_VECTOR:
		var n: Vector2i = neighbour(player, d)
		if n.x >= 0 and grid[n.y][n.x] == LIVE:
			return
	if energy >= ENERGY_MAX:
		return
	for d in CharacterData.DIR_VECTOR:
		var n: Vector2i = neighbour(player, d)
		if n.x >= 0 and grid[n.y][n.x] != LIVE and has_attack_direction(d):
			return
	game_over = true

# -- legal actions, for the search that drives this ------------------------

func legal_directions_live() -> Array:
	var out: Array = []
	for d in CharacterData.DIR_VECTOR:
		var t: Vector2i = neighbour(player, d)
		if t.x >= 0 and grid[t.y][t.x] == LIVE:
			out.append(d)
	return out

func legal_directions_attack() -> Array:
	var out: Array = []
	for d in CharacterData.DIR_VECTOR:
		var t: Vector2i = neighbour(player, d)
		if t.x >= 0 and grid[t.y][t.x] != LIVE and has_attack_direction(d):
			out.append(d)
	return out
