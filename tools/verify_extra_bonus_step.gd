extends SceneTree

const BoardScript = preload("res://scripts/extra_mode/Board.gd")

func _initialize() -> void:
	call_deferred("run_verification")

func run_verification() -> void:
	var board: Node2D = BoardScript.new()
	root.add_child(board)
	await process_frame
	await create_timer(0.5).timeout

	board._charge_energy_for_combo(2)
	if board.get_energy_half_units() != 1 or board.try_energy_bonus_step():
		fail("Two combo must grant only an unusable half energy slot.")
		return

	board._charge_energy_for_combo(2)
	if board.get_energy_half_units() != 2:
		fail("A later two-combo chain did not continue charging the existing half slot.")
		return

	board.energy_half_units = 0
	board._charge_energy_for_combo(2)
	board._charge_energy_for_combo(3)
	if board.get_energy_half_units() != 2 or not board.try_energy_bonus_step():
		fail("Two and three combo must cumulatively grant one full energy slot.")
		return
	if board.get_energy_half_units() != 0 or not board.bonus_step_armed:
		fail("Z must spend energy immediately and arm the next bonus step.")
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
	if board.get_energy_half_units() != 2 or board.survival_turns != 0:
		fail("Four combo did not add one energy slot, or the bonus attack counted as a turn.")
		return

	board._charge_energy_for_combo(5)
	if board.get_energy_half_units() != 4:
		fail("Five combo did not add one energy slot.")
		return
	board._charge_energy_for_combo(6)
	if board.get_energy_half_units() != 6:
		fail("Six combo did not add two energy slots up to the three-slot cap.")
		return

	await create_timer(0.6).timeout
	if not board.try_energy_ultimate():
		fail("Full energy did not activate ULT.")
		return
	if board.get_energy_half_units() != 0 or board.get_ultimate_dashes_remaining() != 4:
		fail("ULT did not consume all three energy slots or grant four dashes.")
		return
	if board.score_manager.combo_counter != 4:
		fail("ULT activation did not preserve the active combo chain.")
		return

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
	if board.get_energy_half_units() != 0:
		fail("ULT attack recharged energy during the active ULT chain.")
		return

	print("PASS: EXTRA energy bonus-step verification.")
	quit(0)

func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)
