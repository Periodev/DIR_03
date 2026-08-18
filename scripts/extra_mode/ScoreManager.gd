class_name ScoreManager

const ENABLE_COMBO_BONUS := true
# The combo counter stops where its rewards stop. The energy table already
# saturates at six (+8 and no higher), so letting the counter climb past it
# would leave a number on screen that no longer buys anything -- and, because
# score is 10 * combo, would make score the only unbounded quantity in the
# game and therefore the only thing worth farming.
# The chain counter itself is not capped -- it counts every link the player
# actually made, and that is the number the HUD shows. What is capped is the
# reward tier: past the sixth link a kill pays the top multiplier and the top
# energy gain and no more. Bounding the payout rather than the counter is what
# keeps score linear in time, so a long chain stays worth showing off without
# ever becoming a way to farm.
const MAX_COMBO_TIER := 6
# Score multiplier per tier. Deliberately steeper than the energy table
# (1/2/2/4/4/8): energy saturates because a full bar is all the bar can hold,
# while score is where reaching the top of the chain earns its risk. One entry
# per tier, so its size defines MAX_COMBO_TIER.
const COMBO_SCORE_MULTIPLIERS := [1, 2, 3, 5, 10, 20]

signal score_changed(new_score: int)
signal combo_changed(new_combo: int)
signal defeat_changed(new_defeats: int)

var score: int = 0
var combo_counter: int = 0
var max_combo: int = 0
var defeat_count: int = 0

func advance_combo() -> void:
	combo_counter += 1
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0)

func combo_tier(combo: int) -> int:
	return clampi(combo, 1, MAX_COMBO_TIER)

func combo_multiplier(combo: int) -> int:
	if not ENABLE_COMBO_BONUS:
		return 1
	return int(COMBO_SCORE_MULTIPLIERS[combo_tier(combo) - 1])

func on_kill(_cell_type: int, count_defeat: bool = true) -> int:
	var base := 10
	max_combo = maxi(max_combo, combo_counter)
	var points: int = base * combo_multiplier(combo_counter)
	score += points
	if count_defeat:
		defeat_count += 1
	score_changed.emit(score)
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0)
	defeat_changed.emit(defeat_count)
	return points

func on_move_to_live() -> void:
	reset_combo()

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
