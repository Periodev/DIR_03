extends SceneTree

# Real-engine A/B for the flat-Monte-Carlo bot (ComboBotMCTS.gd) against the
# shipped bot (ComboBot.gd), same pattern as benchmark_extra_combo_bot_tuned.gd:
# MCTS's rollouts run inside DIRExtraSimBoard, a GDScript replica, so this is
# still the check that actually matters -- it exercises the real Board.gd via
# the same choose_action()/try_move() interface the other benchmarks use.

const BoardScript = preload("res://scripts/extra_mode/Board.gd")
const ComboBotScript = preload("res://scripts/extra_mode/ComboBot.gd")
const ComboBotMCTSScript = preload("res://scripts/extra_mode/ComboBotMCTS.gd")
const MAX_DECISIONS := 2000
const TIMEOUT_MSEC := 60000
const BENCHMARK_SEEDS := [20260811, 20260812, 20260813, 20260814, 20260815, 20260816]

func _initialize() -> void:
	call_deferred("run_benchmark")

func run_benchmark() -> void:
	Engine.time_scale = 20.0
	var shipped_scores: Array = []
	var mcts_scores: Array = []
	var mcts_think_msecs: Array = []
	for benchmark_seed in BENCHMARK_SEEDS:
		var shipped: Dictionary = await _run_board(int(benchmark_seed), ComboBotScript.new())
		var mcts: Dictionary = await _run_board(int(benchmark_seed), ComboBotMCTSScript.new())
		shipped_scores.append(shipped.score)
		mcts_scores.append(mcts.score)
		mcts_think_msecs.append_array(mcts.decision_msecs)
		print(
			"seed=%d  shipped: score=%d turns=%d  |  mcts: score=%d turns=%d  mcts avg think=%.1fms max=%.1fms" % [
				benchmark_seed, shipped.score, shipped.turns,
				mcts.score, mcts.turns,
				_mean(mcts.decision_msecs), mcts.decision_msecs.max() if not mcts.decision_msecs.is_empty() else 0.0
			]
		)
	Engine.time_scale = 1.0
	var shipped_mean: float = _mean(shipped_scores)
	var mcts_mean: float = _mean(mcts_scores)
	print()
	print("shipped mean score = %.1f" % shipped_mean)
	print("mcts    mean score = %.1f  (%+.1f%%)" % [
		mcts_mean, (mcts_mean - shipped_mean) / shipped_mean * 100.0
	])
	print("mcts    think time: avg=%.1fms max=%.1fms over %d decisions  (budget: 160ms)" % [
		_mean(mcts_think_msecs), mcts_think_msecs.max() if not mcts_think_msecs.is_empty() else 0.0,
		mcts_think_msecs.size()
	])
	quit(0)

func _mean(values: Array) -> float:
	var total: float = 0.0
	for v in values:
		total += v
	return total / float(values.size())

func _run_board(benchmark_seed: int, bot) -> Dictionary:
	seed(benchmark_seed)
	var board: Node2D = BoardScript.new()
	root.add_child(board)
	await process_frame
	var started_at: int = Time.get_ticks_msec()
	var decisions: int = 0
	var decision_msecs: Array = []
	while decisions < MAX_DECISIONS and not board.game_state.is_game_over():
		if Time.get_ticks_msec() - started_at >= TIMEOUT_MSEC:
			break
		if not board.game_state.is_idle():
			await process_frame
			continue
		var think_started: int = Time.get_ticks_usec()
		var action: int = bot.choose_action(board)
		decision_msecs.append((Time.get_ticks_usec() - think_started) / 1000.0)
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
		"decision_msecs": decision_msecs,
	}
	# See benchmark_extra_combo_bot_tuned.gd for why this isn't queue_free()'d.
	board.visible = false
	return result
