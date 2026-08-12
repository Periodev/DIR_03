extends SceneTree

const BoardScript = preload("res://scripts/extra_mode/Board.gd")

func _initialize() -> void:
	call_deferred("run_verification")

func run_verification() -> void:
	var inventory_fixture := Inventory.new()
	inventory_fixture.setup("PLN")
	for direction in [
		CharacterData.Direction.UP,
		CharacterData.Direction.DOWN,
		CharacterData.Direction.LEFT,
		CharacterData.Direction.RIGHT,
	]:
		inventory_fixture.push(direction)
	if inventory_fixture.max_size != 3 \
			or inventory_fixture.queue.size() != 3 \
			or inventory_fixture.queue[0] != CharacterData.Direction.DOWN:
		fail("PLN direction inventory is not a three-slot rolling queue.")
		return

	var board: Node2D = BoardScript.new()
	root.add_child(board)
	await process_frame
	if board._player_move_visual_pending:
		fail("Fresh Board startup created a false player movement tween.")
		return
	await create_timer(0.5).timeout
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var surrounded_cell: Vector2i = board.player_pos + CharacterData.DIR_VECTOR[direction]
		board.grid[surrounded_cell.y][surrounded_cell.x] = CharacterData.CellType.DEAD
	board.inventory.reset()
	board.energy_quarter_units = board.ENERGY_QUARTER_UNITS_MAX - 1
	board.game_state.reset()
	board._check_game_over()
	if not board.game_state.is_game_over():
		fail("A surrounded player survived without full ULT energy.")
		return
	board.energy_quarter_units = board.ENERGY_QUARTER_UNITS_MAX
	board.game_state.reset()
	board._check_game_over()
	if board.game_state.is_game_over() or not board.try_energy_ultimate():
		fail("Full ULT energy did not rescue a surrounded player from Game Over.")
		return
	board.restart()
	await process_frame

	board._charge_energy_for_combo(1)
	if board.get_energy_quarter_units() != 1 or board.try_energy_bonus_step():
		fail("One combo must grant only an unusable quarter energy slot.")
		return

	board._charge_energy_for_combo(1)
	if board.get_energy_quarter_units() != 2:
		fail("A later one-combo chain did not continue charging by one quarter slot.")
		return

	board.energy_quarter_units = 0
	board._charge_energy_for_combo(1)
	board._charge_energy_for_combo(2)
	board._charge_energy_for_combo(3)
	if board.get_energy_quarter_units() != 5 or not board.try_energy_bonus_step():
		fail("The first three combo steps must cumulatively grant 1.25 energy slots.")
		return
	if board.get_energy_quarter_units() != 1 or not board.bonus_step_armed:
		fail("X must spend one energy slot, preserve the remaining quarter, and arm DASH.")
		return

	board.score_manager.combo_counter = 3
	board.survival_turns = 5
	board.cycle_counter = 1
	if not board.try_move(CharacterData.Direction.RIGHT):
		fail("A valid live-cell bonus step was rejected.")
		return
	if board.survival_turns != 5 or board.cycle_counter != 1:
		fail("A bonus step advanced the turn or spawn cycle.")
		return
	if board.score_manager.combo_counter != 3 or board.bonus_step_armed:
		fail("A bonus step broke combo or remained armed after use.")
		return

	board.restart()
	board.score_manager.combo_counter = 3
	board._charge_energy_for_combo(1)
	board._charge_energy_for_combo(2)
	board._charge_energy_for_combo(3)
	board.inventory.push(CharacterData.Direction.RIGHT)
	var target: Vector2i = board.player_pos + CharacterData.DIR_VECTOR[CharacterData.Direction.RIGHT]
	board.grid[target.y][target.x] = CharacterData.CellType.DEAD
	if not board.try_energy_bonus_step() or not board.try_move(CharacterData.Direction.RIGHT):
		fail("A valid bonus attack was rejected.")
		return
	if board.score_manager.combo_counter != 4:
		fail("A bonus attack did not continue the combo.")
		return
	if board.get_energy_quarter_units() != 5 or board.survival_turns != 0:
		fail("Four combo did not add one energy slot, or the bonus attack counted as a turn.")
		return

	board._charge_energy_for_combo(5)
	if board.get_energy_quarter_units() != 9:
		fail("Five combo did not add one energy slot.")
		return
	board.energy_quarter_units = 12
	if board.get_energy_quarter_units() != 12 or board.try_energy_ultimate():
		fail("Three energy slots incorrectly activated the four-slot ULT.")
		return
	board._charge_energy_for_combo(6)
	if board.get_energy_quarter_units() != 16:
		fail("Six combo did not add two energy slots up to the four-slot cap.")
		return

	await create_timer(0.6).timeout
	if not board.try_energy_ultimate():
		fail("Full energy did not activate ULT.")
		return
	if board.get_energy_quarter_units() != 0 or board.get_ultimate_dashes_remaining() != 4:
		fail("ULT did not consume all four energy slots or grant four dashes.")
		return
	if board.score_manager.combo_counter != 4:
		fail("ULT activation did not preserve the active combo chain.")
		return
	if not board.player_node.ultimate_dash_ready:
		fail("ULT activation did not show the fixed four-direction dash arrows.")
		return
	var ult_prompt_cell: Node2D = board.cell_nodes[board.player_pos.y][board.player_pos.x]
	ult_prompt_cell.set_attack_prompt(CharacterData.Direction.RIGHT)
	board._refresh_attack_prompts()
	if ult_prompt_cell.attack_prompt_direction != CharacterData.Direction.NONE:
		fail("A normal attack prompt remained visible during ULT.")
		return

	board.player_pos = Vector2i(0, 0)
	var queue_size_before_blocked_dash: int = board.inventory.queue.size()
	if board.try_move(CharacterData.Direction.LEFT):
		fail("A zero-displacement ULT input was accepted.")
		return
	if board.get_ultimate_dashes_remaining() != 4 \
			or board.inventory.queue.size() != queue_size_before_blocked_dash:
		fail("A zero-displacement ULT input consumed a dash or stored a direction.")
		return
	board.player_pos = Vector2i(board.COLS / 2, board.ROWS / 2)

	var ult_target: Vector2i = board.player_pos + CharacterData.DIR_VECTOR[CharacterData.Direction.RIGHT]
	if ult_target.x >= board.COLS:
		ult_target = board.player_pos + CharacterData.DIR_VECTOR[CharacterData.Direction.LEFT]
	board.grid[ult_target.y][ult_target.x] = CharacterData.CellType.DEAD
	var ult_direction: int = CharacterData.Direction.RIGHT if ult_target.x > board.player_pos.x else CharacterData.Direction.LEFT
	if not board.try_move(ult_direction):
		fail("A valid ULT attack was rejected.")
		return
	if board.score_manager.combo_counter != 5 or board.get_ultimate_dashes_remaining() != 3:
		fail("ULT attack did not continue combo or consume exactly one dash.")
		return
	if board.get_energy_quarter_units() != 0:
		fail("ULT attack recharged energy during the active ULT chain.")
		return

	var movement_board: Node2D = BoardScript.new()
	root.add_child(movement_board)
	await process_frame
	if movement_board._player_move_visual_pending:
		fail("Fresh no-kill ULT fixture created a false player movement tween.")
		return
	movement_board.energy_quarter_units = movement_board.ENERGY_QUARTER_UNITS_MAX
	if not movement_board.try_energy_ultimate():
		fail(
			"No-kill ULT fixture did not activate: state=%d energy=%d pending=%s bonus=%s." % [
				movement_board.game_state.current_state,
				movement_board.energy_quarter_units,
				movement_board._player_move_visual_pending,
				movement_board.bonus_step_armed,
			]
		)
		return
	if not movement_board.try_move(CharacterData.Direction.RIGHT):
		fail("A valid no-kill ULT movement was rejected.")
		return
	if movement_board.inventory.find_direction(CharacterData.Direction.RIGHT) < 0:
		fail("A valid no-kill ULT movement did not store its direction.")
		return
	if movement_board.player_node.ultimate_dash_ready:
		fail("ULT direction arrows remained visible during movement.")
		return
	await create_timer(0.6).timeout
	if not movement_board.player_node.ultimate_dash_ready:
		fail("ULT direction arrows did not return after movement completed.")
		return

	print("PASS: EXTRA energy bonus-step verification.")
	quit(0)

func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)
