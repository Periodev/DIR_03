extends SceneTree

const BoardScript = preload("res://scripts/extra_mode/Board.gd")
const ChainBotScript = preload("res://scripts/extra_mode/ChainBot.gd")
const MAX_DECISIONS := 2000
const TIMEOUT_MSEC := 30000
const BENCHMARK_SEEDS := [20260811, 20260812]

func _initialize() -> void:
	call_deferred("run_benchmark")

func run_benchmark() -> void:
	Engine.time_scale = 20.0
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if not user_args.is_empty():
		await _run_board(int(user_args[0]))
		Engine.time_scale = 1.0
		quit(0)
		return
	for benchmark_seed in BENCHMARK_SEEDS:
		await _run_board(int(benchmark_seed))
	Engine.time_scale = 1.0
	quit(0)

func _run_board(benchmark_seed: int) -> void:
	seed(benchmark_seed)
	var board: Node2D = BoardScript.new()
	var bot: DIRExtraChainBot = ChainBotScript.new()
	root.add_child(board)
	await process_frame
	var started_at: int = Time.get_ticks_msec()
	var decisions: int = 0
	var step_uses: int = 0
	var dash_uses: int = 0
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
				step_uses += 1
				board.try_energy_bonus_step()
			DIRExtraComboBot.ACTION_ULT:
				dash_uses += 1
				board.try_energy_ultimate()
			DIRExtraComboBot.ACTION_WAIT:
				board.try_wait()
			_:
				break
		decisions += 1
		await process_frame
	print(
		"BENCH seed=%d: score=%d defeats=%d turns=%d decisions=%d max_combo=%d step=%d dash=%d" % [
			benchmark_seed,
			board.score_manager.score,
			board.score_manager.defeat_count,
			board.survival_turns,
			decisions,
			board.score_manager.max_combo,
			step_uses,
			dash_uses,
		]
	)
