class_name ScoreManager

const ENABLE_COMBO_BONUS := true
const BASE_KILL_SCORE := 1

signal score_changed(new_score: int)
signal combo_changed(new_combo: int)
signal defeat_changed(new_defeats: int)

var score: int = 0
var combo_counter: int = 0
var max_combo: int = 0
var defeat_count: int = 0

func on_kill(_cell_type: int, count_defeat: bool = true) -> int:
	max_combo = maxi(max_combo, combo_counter)
	var multiplier: int = max(1, combo_counter) if ENABLE_COMBO_BONUS else 1
	var points: int = BASE_KILL_SCORE * multiplier
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
