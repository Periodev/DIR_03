extends SceneTree

# Runs the shipped bot (F4) and the CMA-ES-tuned bot (F5) over the same
# seeds, in the real Godot engine -- the Python port in tools/extra_cma.py is
# a faithful mirror, not the ground truth, so this is the check that actually
# matters before trusting ComboBotTuned.gd's weights in play.

const BoardScript = preload("res://scripts/extra_mode/Board.gd")
const ComboBotScript = preload("res://scripts/extra_mode/ComboBot.gd")
const ComboBotTunedScript = preload("res://scripts/extra_mode/ComboBotTuned.gd")
const MAX_DECISIONS := 2000
const TIMEOUT_MSEC := 30000
const BENCHMARK_SEEDS := [20260811, 20260812, 20260813, 20260814, 20260815, 20260816]

func _initialize() -> void:
	call_deferred("run_benchmark")

func run_benchmark() -> void:
	Engine.time_scale = 20.0
	var shipped_scores: Array = []
	var tuned_scores: Array = []
	for benchmark_seed in BENCHMARK_SEEDS:
		var shipped: Dictionary = await _run_board(int(benchmark_seed), ComboBotScript.new())
		var tuned: Dictionary = await _run_board(int(benchmark_seed), ComboBotTunedScript.new())
		shipped_scores.append(shipped.score)
		tuned_scores.append(tuned.score)
		print(
			"seed=%d  shipped: score=%d turns=%d  |  tuned: score=%d turns=%d" % [
				benchmark_seed, shipped.score, shipped.turns, tuned.score, tuned.turns
			]
		)
	Engine.time_scale = 1.0
	var shipped_mean: float = _mean(shipped_scores)
	var tuned_mean: float = _mean(tuned_scores)
	print()
	print("shipped mean score = %.1f" % shipped_mean)
	print("tuned   mean score = %.1f  (%+.1f%%)" % [
		tuned_mean, (tuned_mean - shipped_mean) / shipped_mean * 100.0
	])
	quit(0)

func _mean(values: Array) -> float:
	var total: float = 0.0
	for v in values:
		total += v
	return total / float(values.size())

func _run_board(benchmark_seed: int, bot: DIRExtraComboBot) -> Dictionary:
	seed(benchmark_seed)
	var board: Node2D = BoardScript.new()
	root.add_child(board)
	await process_frame
	var started_at: int = Time.get_ticks_msec()
	var decisions: int = 0
	while decisions < MAX_DECISIONS and not board.game_state.is_game_over():
		if Time.get_ticks_msec() - started_at >= TIMEOUT_MSEC:
			break
		if not board.game_state.is_idle():
			await process_frame
			continue
		var action: int = bot.choose_action(board)
		match action:
			DIRExtraComboBot.ACTION_MOVE:
				board.try_move(bot.chosen_direction)
			DIRExtraComboBot.ACTION_DASH:
				board.try_energy_bonus_step()
			DIRExtraComboBot.ACTION_ULT:
				board.try_energy_ultimate()
			DIRExtraComboBot.ACTION_WAIT:
				board.try_wait()
			_:
				break
		decisions += 1
		await process_frame
	var result: Dictionary = {
		"score": board.score_manager.score,
		"turns": board.survival_turns,
	}
	# Not queue_free()'d: a kill/spawn animation on the losing turn can still
	# have a pending get_tree().create_timer(...) callback capturing this
	# board when the game-over check fires, and freeing the node out from
	# under that timer crashes ("Lambda capture...was freed") the next time it
	# runs. This script exits shortly after the loop anyway, so leaving twelve
	# small boards as orphaned children of root for the run's remaining
	# lifetime is cheaper than chasing that race.
	board.visible = false
	return result
