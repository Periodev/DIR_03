extends SceneTree

const BoardScript = preload("res://scripts/extra_mode/Board.gd")
const ComboBotScript = preload("res://scripts/extra_mode/ComboBot.gd")

func _initialize() -> void:
	call_deferred("run_verification")

func run_verification() -> void:
	var board: Node2D = BoardScript.new()
	var bot: DIRExtraComboBot = ComboBotScript.new()
	root.add_child(board)
	await process_frame
	await create_timer(0.5).timeout

	_reset_fixture(board)
	board.score_manager.combo_counter = 3
	board.energy_quarter_units = board.ENERGY_SLOT_COST
	board.inventory.push(CharacterData.Direction.RIGHT)
	board.grid[2][3] = CharacterData.CellType.DEAD
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_MOVE:
		fail("An adjacent target spent DASH instead of charging energy with a normal attack.")
		return

	board.bonus_step_armed = true
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_MOVE \
		or bot.chosen_direction != CharacterData.Direction.RIGHT:
		fail("Armed DASH did not immediately select the available combo attack.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 2
	board.energy_quarter_units = board.ENERGY_SLOT_COST
	board.inventory.push(CharacterData.Direction.RIGHT)
	board.grid[2][3] = CharacterData.CellType.DEAD
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_MOVE:
		fail("Low combo spent DASH on an attack that cannot repay its energy cost.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 4
	board.energy_quarter_units = board.ENERGY_SLOT_COST
	board.inventory.push(CharacterData.Direction.DOWN)
	board.grid[3][3] = CharacterData.CellType.DEAD
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_DASH:
		fail("DASH was not used to bridge a high combo into an immediate attack.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 4
	board.energy_quarter_units = board.ENERGY_SLOT_COST * 2
	board.inventory.push(CharacterData.Direction.DOWN)
	board.grid[3][3] = CharacterData.CellType.DEAD
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_DASH:
		fail("High combo did not spend available energy on a verified DASH continuation.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 2
	board.energy_quarter_units = board.ENERGY_SLOT_COST
	if bot.choose_action(board) == DIRExtraComboBot.ACTION_DASH:
		fail("DASH was spent without an immediate combo continuation.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 4
	board.energy_quarter_units = board.ENERGY_QUARTER_UNITS_MAX
	board.grid[2][4] = CharacterData.CellType.DEAD
	board.grid[0][2] = CharacterData.CellType.DEAD
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_ULT:
		fail("Full energy with two line targets did not activate ULT.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 4
	board.energy_quarter_units = board.ENERGY_QUARTER_UNITS_MAX
	board.grid[2][4] = CharacterData.CellType.DEAD
	board.grid[4][4] = CharacterData.CellType.DEAD
	board.grid[4][0] = CharacterData.CellType.DEAD
	board.grid[0][0] = CharacterData.CellType.DEAD
	board.grid[1][0] = CharacterData.CellType.DEAD
	board.grid[1][1] = CharacterData.CellType.DEAD
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_ULT \
			or not board.try_energy_ultimate():
		fail("ULT continuation fixture did not activate ULT.")
		return
	for _dash_index in board.ULT_DASH_COUNT:
		if bot.choose_action(board) != DIRExtraComboBot.ACTION_MOVE:
			fail("ULT planner did not provide all four dash directions.")
			return
		if not board.try_move(bot.chosen_direction):
			fail("ULT planner selected an invalid dash direction.")
			return
		await _wait_until_idle(board)
	if bot._attack_directions(board).is_empty():
		fail("ULT sequence did not finish beside an attackable enemy for combo continuation.")
		return

	_reset_fixture(board)
	board.cycle_counter = board.SPAWN_CYCLE_STEPS - 1
	board.candidate_cells = [Vector2i(3, 2)]
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_MOVE \
		or bot.chosen_direction == CharacterData.Direction.RIGHT:
		fail("Normal movement selected the cell due to become lethal this turn.")
		return

	print("PASS: EXTRA combo bot decision verification.")
	quit(0)

func _reset_fixture(board: Node2D) -> void:
	for row in board.ROWS:
		for column in board.COLS:
			board.grid[row][column] = CharacterData.CellType.LIVE
	board.player_pos = Vector2i(2, 2)
	board.inventory.reset()
	board.score_manager.combo_counter = 0
	board.energy_quarter_units = 0
	board.bonus_step_armed = false
	board.ultimate_dashes_remaining = 0
	board.candidate_cells.clear()
	board.cycle_counter = 0
	board._opening_grace_turns_remaining = 10
	board.game_state.reset()

func _wait_until_idle(board: Node2D) -> void:
	while not board.game_state.is_idle() and not board.game_state.is_game_over():
		await process_frame

func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)
