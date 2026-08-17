extends SceneTree

const BoardScript = preload("res://scripts/extra_mode/Board.gd")
const ChainBotScript = preload("res://scripts/extra_mode/ChainBot.gd")

func _initialize() -> void:
	call_deferred("run_verification")

func run_verification() -> void:
	var board: Node2D = BoardScript.new()
	var bot: DIRExtraChainBot = ChainBotScript.new()
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
			or bot.chosen_direction == CharacterData.Direction.RIGHT:
		fail("Armed STEP selected an attack instead of an empty-cell movement.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 1
	board.energy_quarter_units = board.ENERGY_SLOT_COST
	board.inventory.push(CharacterData.Direction.DOWN)
	board.grid[3][3] = CharacterData.CellType.DEAD
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_DASH:
		fail("CHAIN AI did not spend STEP to extend a one-combo chain.")
		return
	if not board.try_energy_bonus_step() \
			or bot.choose_action(board) != DIRExtraComboBot.ACTION_MOVE \
			or bot.chosen_direction != CharacterData.Direction.RIGHT:
		fail("CHAIN AI armed STEP but did not take the verified continuation route.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 4
	board.energy_quarter_units = board.ENERGY_SLOT_COST
	board.inventory.push(CharacterData.Direction.DOWN)
	board.grid[3][3] = CharacterData.CellType.DEAD
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_DASH:
		fail("STEP was not used to bridge a high combo into an immediate attack.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 4
	board.energy_quarter_units = board.ENERGY_SLOT_COST * 2
	board.inventory.push(CharacterData.Direction.DOWN)
	board.grid[3][3] = CharacterData.CellType.DEAD
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_DASH:
		fail("High combo did not spend available energy on a verified STEP continuation.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 4
	board.energy_quarter_units = board.ENERGY_QUARTER_UNITS_MAX
	board.grid[2][4] = CharacterData.CellType.DEAD
	board.grid[0][2] = CharacterData.CellType.DEAD
	if bot.choose_action(board) == DIRExtraComboBot.ACTION_ULT:
		fail("CHAIN AI spent Z DASH while ordinary movement remained safe.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 4
	board.energy_quarter_units = board.ENERGY_QUARTER_UNITS_MAX
	for direction_value in CharacterData.DIR_VECTOR:
		var surround_direction: int = int(direction_value)
		var surround_target: Vector2i = (
			board.player_pos + Vector2i(CharacterData.DIR_VECTOR[surround_direction])
		)
		board.grid[surround_target.y][surround_target.x] = CharacterData.CellType.DEAD
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_ULT:
		fail("CHAIN AI did not reserve Z DASH for a surrounded emergency.")
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
	if not board.try_energy_ultimate():
		fail("ULT continuation fixture could not activate Z DASH directly.")
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
	board.cycle_resolved = false
	board.candidate_cells = [Vector2i(3, 2)]
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_MOVE \
			or bot.chosen_direction == CharacterData.Direction.RIGHT:
		fail("Normal movement selected the cell due to become lethal this turn.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 4
	board.energy_quarter_units = board.ENERGY_SLOT_COST
	board.inventory.push(CharacterData.Direction.DOWN)
	board.grid[3][3] = CharacterData.CellType.DEAD
	board.cycle_counter = board.SPAWN_CYCLE_STEPS - 1
	board.cycle_resolved = false
	board.candidate_cells = [Vector2i(3, 2)]
	if bot.choose_action(board) == DIRExtraComboBot.ACTION_DASH:
		fail("CHAIN AI armed STEP for a continuation route that spawns lethally this turn.")
		return

	_reset_fixture(board)
	board.score_manager.combo_counter = 4
	board.energy_quarter_units = board.ENERGY_QUARTER_UNITS_MAX
	board.cycle_counter = board.SPAWN_CYCLE_STEPS - 1
	board.cycle_resolved = false
	for direction_value in CharacterData.DIR_VECTOR:
		var danger_direction: int = int(direction_value)
		board.candidate_cells.append(
			board.player_pos + Vector2i(CharacterData.DIR_VECTOR[danger_direction])
		)
	if bot.choose_action(board) != DIRExtraComboBot.ACTION_ULT:
		fail("CHAIN AI did not use ULT when every ordinary move would resolve lethally.")
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
	board.cycle_counter = -1000
	board.cycle_resolved = true
	board.game_state.reset()

func _wait_until_idle(board: Node2D) -> void:
	while not board.game_state.is_idle() and not board.game_state.is_game_over():
		await process_frame

func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)
