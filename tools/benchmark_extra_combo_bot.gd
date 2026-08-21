extends SceneTree

const BoardScript = preload("res://scripts/extra_mode/Board.gd")
const ComboBotScript = preload("res://scripts/extra_mode/ComboBot.gd")
const MAX_DECISIONS := 2000
const TIMEOUT_MSEC := 30000
# Two seeds cannot separate two policies: they disagreed on which of the last
# two bots survived longer. Six is still small, but it is enough to see a mean.
const BENCHMARK_SEEDS := [20260811, 20260812, 20260813, 20260814, 20260815, 20260816]

func _initialize() -> void:
	call_deferred("run_benchmark")

func run_benchmark() -> void:
	Engine.time_scale = 20.0
	for benchmark_seed in BENCHMARK_SEEDS:
		await _run_board(int(benchmark_seed))
	Engine.time_scale = 1.0
	quit(0)

func _run_board(benchmark_seed: int) -> void:
	seed(benchmark_seed)
	var board: Node2D = BoardScript.new()
	var bot: DIRExtraComboBot = ComboBotScript.new()
	root.add_child(board)
	await process_frame
	var started_at: int = Time.get_ticks_msec()
	var decisions: int = 0
	# Per-action-type counts, so X/Z usage can be read off directly instead of
	# guessed at from score alone. move_during_step and move_during_ult split
	# out ACTION_MOVE calls that happen while a STEP or ULT chain is already
	# armed (the follow-through presses), from ordinary moves/attacks.
	var count_move: int = 0
	var count_step_arm: int = 0
	var count_ult_arm: int = 0
	var count_wait: int = 0
	var count_move_during_step: int = 0
	var count_move_during_ult: int = 0
	while decisions < MAX_DECISIONS and not board.game_state.is_game_over():
		if Time.get_ticks_msec() - started_at >= TIMEOUT_MSEC:
			break
		if not board.game_state.is_idle():
			await process_frame
			continue
		var action: int = bot.choose_action(board)
		match action:
			DIRExtraComboBot.ACTION_MOVE:
				if board.bonus_step_armed:
					count_move_during_step += 1
				elif board.get_ultimate_dashes_remaining() > 0:
					count_move_during_ult += 1
				else:
					count_move += 1
				board.try_move(bot.chosen_direction)
			DIRExtraComboBot.ACTION_DASH:
				count_step_arm += 1
				board.try_energy_bonus_step()
			DIRExtraComboBot.ACTION_ULT:
				count_ult_arm += 1
				board.try_energy_ultimate()
			DIRExtraComboBot.ACTION_WAIT:
				count_wait += 1
				board.try_wait()
			_:
				break
		decisions += 1
		await process_frame
	print(
		"BENCH seed=%d: score=%d defeats=%d turns=%d decisions=%d maxcombo=%d" % [
			benchmark_seed,
			board.score_manager.score,
			board.score_manager.defeat_count,
			board.survival_turns,
			decisions,
			board.score_manager.max_combo,
		]
	)
	print(
		"  actions: move=%d  X-arm=%d  X-follow=%d  Z-arm=%d  Z-dash=%d  wait=%d" % [
			count_move,
			count_step_arm,
			count_move_during_step,
			count_ult_arm,
			count_move_during_ult,
			count_wait,
		]
	)
	board.queue_free()
	await process_frame
