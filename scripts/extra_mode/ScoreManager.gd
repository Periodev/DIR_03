class_name ScoreManager

const ENABLE_COMBO_BONUS := true
# Heat rises on a kill and falls by one tier on a normal non-kill turn. It is
# capped at the highest reward tier so the meter, score, and energy economy all
# describe the same state.
const MAX_COMBO_TIER := 5
# Score multiplier per tier. Deliberately steeper than the energy table
# (1/2/2/4/4): energy saturates because a full bar is all the bar can hold,
# while score is where reaching the top of the chain earns its risk. One entry
# per tier, so its size defines MAX_COMBO_TIER.
const COMBO_SCORE_MULTIPLIERS := [1, 2, 5, 10, 20]
const BASE_KILL_SCORE := 1
# Holding the top tier, not just reaching it, earns its own reward: every five
# straight kills taken without combo ever dropping below MAX_COMBO_TIER pay a
# bonus on top of their own tier-5 score. The count itself never resets on a
# payout, only on a decay -- it is a running record of the current streak, and
# the bonus just repeats every five kills along the way, growing by
# TIER5_STREAK_BONUS_STEP each time up to TIER5_STREAK_BONUS_CAP -- capped
# well under BOARD_CLEAR_BONUS so a long streak still stays a lesser, gradual
# reward next to that one-off milestone.
const TIER5_STREAK_THRESHOLD := 5
const TIER5_STREAK_BONUS_BASE := 200
const TIER5_STREAK_BONUS_STEP := 100
const TIER5_STREAK_BONUS_CAP := 1000

signal score_changed(new_score: int)
signal combo_changed(new_combo: int, new_tier5_streak: int)
signal defeat_changed(new_defeats: int)
signal bonus_scored(amount: int)

var score: int = 0
var combo_counter: int = 0
var max_combo: int = 0
var defeat_count: int = 0
var tier5_streak: int = 0
var max_tier5_streak: int = 0

func advance_combo() -> void:
	combo_counter = mini(combo_counter + 1, MAX_COMBO_TIER)
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0, tier5_streak)

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
	var streak_bonus_awarded: int = 0
	if combo_counter == MAX_COMBO_TIER:
		tier5_streak += 1
		max_tier5_streak = maxi(max_tier5_streak, tier5_streak)
		# The streak count itself never resets on a payout -- only a decay
		# breaks it -- so it keeps climbing as a running record, and the bonus
		# just repeats every five kills along the way.
		if tier5_streak % TIER5_STREAK_THRESHOLD == 0:
			var block: int = tier5_streak / TIER5_STREAK_THRESHOLD
			streak_bonus_awarded = mini(
				TIER5_STREAK_BONUS_BASE + TIER5_STREAK_BONUS_STEP * (block - 1),
				TIER5_STREAK_BONUS_CAP
			)
			points += streak_bonus_awarded
			score += streak_bonus_awarded
	if count_defeat:
		defeat_count += 1
	score_changed.emit(score)
	if streak_bonus_awarded > 0:
		bonus_scored.emit(streak_bonus_awarded)
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0, tier5_streak)
	defeat_changed.emit(defeat_count)
	return points

func award_bonus(amount: int) -> void:
	score += amount
	score_changed.emit(score)
	bonus_scored.emit(amount)

func on_move_to_live() -> void:
	decay_combo()

func decay_combo() -> void:
	# A miss costs one tier. The earlier two-tier decay fixed heat coasting
	# near the cap (88-92% of the top multiplier across 900+ turn benchmarks),
	# but the real leak was tier 3/4 recovery paying off almost as well as
	# holding it -- energy_gain_for_combo() now closes that instead by paying
	# tier 3 and tier 4 the same, so a lighter decay no longer needs to carry
	# the whole fix on its own.
	combo_counter = maxi(0, combo_counter - 1)
	tier5_streak = 0
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0, tier5_streak)

func reset_combo() -> void:
	combo_counter = 0
	tier5_streak = 0
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0, tier5_streak)

func reset() -> void:
	score = 0
	combo_counter = 0
	max_combo = 0
	defeat_count = 0
	tier5_streak = 0
	max_tier5_streak = 0
	score_changed.emit(score)
	combo_changed.emit(combo_counter if ENABLE_COMBO_BONUS else 0, tier5_streak)
	defeat_changed.emit(defeat_count)
