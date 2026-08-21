class_name ScoreManager

const ENABLE_COMBO_BONUS := true
# Heat rises on a kill and falls by one tier on a normal non-kill turn. It is
# capped at the highest reward tier so the meter, score, and energy economy all
# describe the same state.
const MAX_COMBO_TIER := 5
# Score multiplier per tier. Deliberately steeper than the energy table
# (1/2/2/4/6): energy saturates because a full bar is all the bar can hold,
# while score is where reaching the top of the chain earns its risk. One entry
# per tier, so its size defines MAX_COMBO_TIER.
const COMBO_SCORE_MULTIPLIERS := [1, 2, 5, 10, 20]
const BASE_KILL_SCORE := 1

signal score_changed(new_score: int)
signal combo_changed(new_combo: int)
signal defeat_changed(new_defeats: int)

var score: int = 0
var combo_counter: int = 0
var max_combo: int = 0
var defeat_count: int = 0

func advance_combo() -> void:
	combo_counter = mini(combo_counter + 1, MAX_COMBO_TIER)
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0)

func combo_tier(combo: int) -> int:
	return clampi(combo, 1, MAX_COMBO_TIER)

func combo_multiplier(combo: int) -> int:
	if not ENABLE_COMBO_BONUS:
		return 1
	return int(COMBO_SCORE_MULTIPLIERS[combo_tier(combo) - 1])

func on_kill(_cell_type: int, count_defeat: bool = true) -> int:
	max_combo = maxi(max_combo, combo_counter)
	var points: int = BASE_KILL_SCORE * combo_multiplier(combo_counter)
	score += points
	if count_defeat:
		defeat_count += 1
	score_changed.emit(score)
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0)
	defeat_changed.emit(defeat_count)
	return points

func on_move_to_live() -> void:
	decay_combo()

func decay_combo() -> void:
	# A miss costs two tiers, not one: a single tier of decay let heat coast
	# near the cap for an entire run (bot benchmarks averaged 88-92% of the
	# top multiplier across 900+ turn sessions), collapsing the tier system
	# into a survival timer instead of a maintained-chain reward.
	combo_counter = maxi(0, combo_counter - 2)
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0)

func reset_combo() -> void:
	combo_counter = 0
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0)

func reset() -> void:
	score = 0
	combo_counter = 0
	max_combo = 0
	defeat_count = 0
	score_changed.emit(score)
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0)
	defeat_changed.emit(defeat_count)
