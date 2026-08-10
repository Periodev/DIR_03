class_name ScoreManager

const ENABLE_COMBO_BONUS := true

signal score_changed(new_score: int)
signal combo_changed(new_combo: int)
signal defeat_changed(new_defeats: int)

var score: int = 0
var combo_counter: int = 0
var defeat_count: int = 0

func on_kill(_cell_type: int, count_defeat: bool = true) -> int:
	var base := 10
	var multiplier: int = max(1, combo_counter) if ENABLE_COMBO_BONUS else 1
	var points: int = base * multiplier
	score += points
	if count_defeat:
		defeat_count += 1
	score_changed.emit(score)
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0)
	defeat_changed.emit(defeat_count)
	return points

func on_move_to_live() -> void:
	combo_counter = 0
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0)

func reset() -> void:
	score = 0
	combo_counter = 0
	defeat_count = 0
	score_changed.emit(score)
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0)
	defeat_changed.emit(defeat_count)
