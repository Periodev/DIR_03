class_name DIRExtraComboBotTuned
extends DIRExtraComboBot

# NOT a CMA-ES result. An earlier CMA-ES search over the full weight set
# looked validated in the Python port (tools/extra_cma.py) -- 24 held-out
# seeds, four of seven independent restarts converging to the same score
# band -- but the "held-out" seeds were drawn from Python's random module,
# not Godot's. A same-numbered seed produces a different board in each RNG,
# so that validation only proved the weights generalised across Python-
# generated boards; a real-engine A/B (tools/benchmark_extra_combo_bot_tuned.gd)
# showed the same weights dying in under 45 turns on 3 of 6 real seeds,
# averaging 28.6% BELOW the shipped bot. Sampling-based validation cannot be
# trusted across that RNG boundary, so this file no longer uses it.
#
# Every value here is unchanged from DIRExtraComboBot except the two the
# original diagnosis actually identified as broken, each derived from the
# game's real payoff numbers rather than fit to any sample of games:
#
# ULT_CONTINUATION_VALUE (1800 -> 300): continuation_count multiplies this
# once per open direction after a chain ends, up to 4. At 1800 the worst
# case (4 directions) was worth 7200 -- six times COMBO_KILL_MULT(60) times
# the top payout tier(20) = 1200, the most a single real kill is worth
# anywhere in this file. Reasoned value: cap the total continuation bonus at
# that one figure, so "the board looks promising afterward" can be worth at
# most one top-tier kill, never several. 1200 / 4 = 300.
#
# COMBO_GATE_FOR_STEP (4 -> 1): STEP costs a flat 4 energy regardless of
# combo and protects whatever combo currently exists -- there is no rule
# reason to withhold it until combo reaches 4 specifically. Set to 1: STEP
# becomes worth considering as soon as there is any combo to protect.
func _init() -> void:
	ULT_CONTINUATION_VALUE = 300.0
	COMBO_GATE_FOR_STEP = 1
