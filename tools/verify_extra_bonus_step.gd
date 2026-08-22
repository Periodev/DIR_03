extends SceneTree

const BoardScript = preload("res://scripts/extra_mode/Board.gd")
const CharacterImpl_PLN = preload("res://scripts/extra_mode/CharacterImpl_PLN.gd")
const ComboBotScript = preload("res://scripts/extra_mode/ComboBot.gd")

func _initialize() -> void:
	call_deferred("run_verification")

func run_verification() -> void:
	if not is_equal_approx(CharacterImpl_PLN.NORMAL_CHARGE_SCALE, 0.8) \
			or not is_equal_approx(CharacterImpl_PLN.ULT_WINDUP, CharacterImpl_PLN.WINDUP * 1.1):
		fail("Normal and ULT charge presentation no longer use their distinct scale and timing.")
		return
	if not is_equal_approx(CharacterImpl_PLN.NORMAL_SLASH_LENGTH, 145.0):
		fail("Normal slash no longer ends just beyond an adjacent enemy.")
		return

	var score_fixture := ScoreManager.new()
	score_fixture.combo_counter = 4
	score_fixture.on_kill(CharacterData.CellType.DEAD)
	score_fixture.on_move_to_live()
	if score_fixture.combo_counter != 3:
		fail("A normal non-kill turn did not lower heat by exactly one tier.")
		return
	score_fixture.reset_combo()
	if score_fixture.max_combo != 4:
		fail("ScoreManager did not preserve the session max heat after cooling.")
		return

	var streak_fixture := ScoreManager.new()
	streak_fixture.combo_counter = ScoreManager.MAX_COMBO_TIER
	for _kill in ScoreManager.TIER5_STREAK_THRESHOLD - 1:
		streak_fixture.on_kill(CharacterData.CellType.DEAD)
	var score_before_streak_bonus: int = streak_fixture.score
	streak_fixture.on_kill(CharacterData.CellType.DEAD)
	if streak_fixture.score != score_before_streak_bonus + 20 + ScoreManager.TIER5_STREAK_BONUS_BASE:
		fail(
			"Five straight tier-5 kills did not pay the first streak bonus on top of their own score, reached %s."
			% streak_fixture.score
		)
		return
	if streak_fixture.tier5_streak != ScoreManager.TIER5_STREAK_THRESHOLD:
		fail("The tier-5 streak count reset after paying out instead of continuing to climb.")
		return
	var score_before_second_bonus: int = streak_fixture.score
	for _kill in ScoreManager.TIER5_STREAK_THRESHOLD:
		streak_fixture.on_kill(CharacterData.CellType.DEAD)
	var second_bonus: int = ScoreManager.TIER5_STREAK_BONUS_BASE + ScoreManager.TIER5_STREAK_BONUS_STEP
	if streak_fixture.score != score_before_second_bonus + 100 + second_bonus:
		fail(
			"A second five-kill stretch at tier5 did not pay a bigger streak bonus, reached %s."
			% streak_fixture.score
		)
		return
	if streak_fixture.tier5_streak != 2 * ScoreManager.TIER5_STREAK_THRESHOLD:
		fail("The tier-5 streak count did not keep climbing across a second payout.")
		return

	# Run well past the cap and confirm growth stops there instead of climbing
	# forever: at TIER5_STREAK_BONUS_STEP := 100 the cap of 1000 lands on the
	# 9th block, so the 10th must repeat 1000, not 1100.
	var blocks_to_cap: int = (
		(ScoreManager.TIER5_STREAK_BONUS_CAP - ScoreManager.TIER5_STREAK_BONUS_BASE)
		/ ScoreManager.TIER5_STREAK_BONUS_STEP + 1
	)
	for _block in blocks_to_cap - 2:
		for _kill in ScoreManager.TIER5_STREAK_THRESHOLD:
			streak_fixture.on_kill(CharacterData.CellType.DEAD)
	var score_before_capped_block: int = streak_fixture.score
	for _kill in ScoreManager.TIER5_STREAK_THRESHOLD:
		streak_fixture.on_kill(CharacterData.CellType.DEAD)
	if streak_fixture.score != score_before_capped_block + 100 + ScoreManager.TIER5_STREAK_BONUS_CAP:
		fail(
			"The streak bonus did not stop growing at its cap, reached %s."
			% streak_fixture.score
		)
		return

	streak_fixture.decay_combo()
	if streak_fixture.tier5_streak != 0:
		fail("A decay mid-streak did not clear the tier-5 streak count.")
		return

	var clear_board: Node2D = BoardScript.new()
	root.add_child(clear_board)
	await process_frame
	clear_board.spawn_warning_player.stop()
	for row in clear_board.grid.size():
		for col in clear_board.grid[row].size():
			clear_board.grid[row][col] = CharacterData.CellType.LIVE
	var clear_pos: Vector2i = clear_board.player_pos + CharacterData.DIR_VECTOR[CharacterData.Direction.RIGHT]
	clear_board.grid[clear_pos.y][clear_pos.x] = CharacterData.CellType.DEAD
	var score_before_clear: int = clear_board.score_manager.score
	clear_board._kill_flow(clear_pos, CharacterData.Direction.RIGHT, CharacterData.CellType.DEAD)
	if clear_board.score_manager.score != score_before_clear + 1 + clear_board.BOARD_CLEAR_BONUS:
		fail(
			"Clearing the last DEAD cell on the board did not pay the board-clear bonus, reached %s."
			% clear_board.score_manager.score
		)
		return

	var cap_fixture := ScoreManager.new()
	for _kill in 12:
		cap_fixture.advance_combo()
	if cap_fixture.combo_counter != ScoreManager.MAX_COMBO_TIER:
		fail(
			"Heat exceeded or failed to reach its top tier: %s."
			% cap_fixture.combo_counter
		)
		return
	if ScoreManager.COMBO_SCORE_MULTIPLIERS.size() != ScoreManager.MAX_COMBO_TIER \
			or ScoreManager.MAX_COMBO_TIER != 5:
		fail("The score multiplier curve does not carry one entry per reward tier.")
		return
	if cap_fixture.combo_tier(50) != ScoreManager.MAX_COMBO_TIER:
		fail("A chain past the top tier did not clamp to it.")
		return
	var expected_multipliers: Array = [1, 2, 5, 10, 20]
	for step in expected_multipliers.size():
		if cap_fixture.combo_multiplier(step + 1) != int(expected_multipliers[step]):
			fail(
				"Combo %s paid x%s, expected x%s." % [
					step + 1,
					cap_fixture.combo_multiplier(step + 1),
					expected_multipliers[step],
				]
			)
			return
	var capped_points: int = cap_fixture.on_kill(CharacterData.CellType.DEAD)
	if capped_points != 20:
		fail("A kill at the combo cap did not pay the top multiplier exactly once.")
		return
	if cap_fixture.combo_multiplier(99) != 20:
		fail("A combo past the table paid more than the top multiplier.")
		return
	score_fixture.reset()
	if score_fixture.max_combo != 0:
		fail("ScoreManager did not clear max combo on restart.")
		return

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
	board.spawn_warning_player.stop()
	board._start_new_cycle()
	if board.candidate_cells.size() != board.SPAWNS_PER_CYCLE \
			or not board.spawn_warning_player.playing:
		fail("The legacy spawn batch did not play its warning sound when candidates appeared.")
		return
	board.survival_turns = board.THREE_SPAWN_TURN_THRESHOLD - 1
	board._start_new_cycle()
	if board.candidate_cells.size() != board.SPAWNS_PER_CYCLE:
		fail("Spawn count increased before the turn threshold.")
		return
	board.survival_turns = board.THREE_SPAWN_TURN_THRESHOLD
	board._start_new_cycle()
	if board.candidate_cells.size() != 3:
		fail("Spawn count did not increase to three at 100 turns.")
		return
	board.survival_turns = board.FOUR_SPAWN_TURN_THRESHOLD
	board._start_new_cycle()
	if board.candidate_cells.size() != 4:
		fail("Spawn count did not increase to four at 200 turns.")
		return
	board.survival_turns = board.FIVE_SPAWN_TURN_THRESHOLD
	board._start_new_cycle()
	if board.candidate_cells.size() != 5:
		fail("Spawn count did not increase to five at 300 turns.")
		return
	board.restart()
	await process_frame
	if board._player_move_visual_pending:
		fail("Fresh Board startup created a false player movement tween.")
		return
	var danger_direction: int = CharacterData.Direction.LEFT
	var danger_target: Vector2i = board.player_pos + CharacterData.DIR_VECTOR[danger_direction]
	board.candidate_cells = [danger_target]
	board.cycle_counter = board.SPAWN_CYCLE_STEPS - 1
	board._opening_grace_turns_remaining = 1
	board._sync_player_move_ready()
	if danger_direction in board.player_node.danger_move_directions:
		fail("Opening grace incorrectly marked a move as immediate spawn danger.")
		return
	board._opening_grace_turns_remaining = 0
	board._sync_player_move_ready()
	if danger_direction not in board.player_node.danger_move_directions:
		fail("A move into this turn's spawn cell was not marked as dangerous.")
		return
	board.bonus_step_armed = true
	board._sync_player_move_ready()
	if not board.player_node.danger_move_directions.is_empty():
		fail("A spawn-frozen bonus step retained an immediate danger marker.")
		return
	board.restart()
	await process_frame
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
		fail("X must spend one energy slot, preserve the remaining quarters, and arm DASH.")
		return

	board.score_manager.combo_counter = 3
	board.survival_turns = 5
	board.cycle_counter = 1
	board.inventory.reset()
	for filler_direction in [
		CharacterData.Direction.UP,
		CharacterData.Direction.DOWN,
		CharacterData.Direction.LEFT,
	]:
		board.inventory.push(filler_direction)
	if not board.try_move(CharacterData.Direction.RIGHT):
		fail("A valid live-cell bonus step was rejected.")
		return
	if board.survival_turns != 5 or board.cycle_counter != 1:
		fail("A bonus step advanced the turn or spawn cycle.")
		return
	if board.score_manager.combo_counter != 3 or board.bonus_step_armed:
		fail("A bonus step broke combo or remained armed after use.")
		return
	if board.inventory.queue.size() != board.inventory.max_size \
			or board.inventory.is_overflowing() \
			or board.inventory.queue[0] != CharacterData.Direction.DOWN:
		fail("A bonus step did not use the ordinary rolling direction queue.")
		return

	await create_timer(0.6).timeout
	if not board.game_state.is_idle():
		fail("The board never returned to idle after a bonus step.")
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
	if board.get_energy_quarter_units() != 1 or board.survival_turns != 0:
		fail("A bonus attack recharged energy, or it counted as a turn.")
		return
	if board.inventory.find_direction(CharacterData.Direction.RIGHT) < 0:
		fail("A bonus attack consumed its direction instead of keeping it for the chain.")
		return
	if board.get_bonus_step_cost() != board.ENERGY_SLOT_COST:
		fail("X no longer costs one flat energy slot.")
		return

	var combo_bot_board: Node2D = BoardScript.new()
	root.add_child(combo_bot_board)
	await process_frame
	combo_bot_board.spawn_warning_player.stop()
	combo_bot_board.inventory.reset()
	combo_bot_board.score_manager.combo_counter = ScoreManager.MAX_COMBO_TIER
	combo_bot_board.score_manager.tier5_streak = ScoreManager.TIER5_STREAK_THRESHOLD
	combo_bot_board.energy_quarter_units = 3 * combo_bot_board.ENERGY_SLOT_COST
	var chain_direction: int = CharacterData.Direction.RIGHT
	var chain_target: Vector2i = combo_bot_board.player_pos \
			+ CharacterData.DIR_VECTOR[chain_direction]
	var chain_follow_up: Vector2i = chain_target + CharacterData.DIR_VECTOR[chain_direction]
	combo_bot_board.grid[chain_target.y][chain_target.x] = CharacterData.CellType.DEAD
	combo_bot_board.grid[chain_follow_up.y][chain_follow_up.x] = CharacterData.CellType.DEAD
	combo_bot_board.inventory.push(chain_direction)
	var combo_bot := ComboBotScript.new()
	if combo_bot.choose_action(combo_bot_board) != combo_bot.ACTION_DASH:
		fail("F4 did not arm X before an available established-streak handoff.")
		return
	if not combo_bot_board.try_energy_bonus_step():
		fail("F4 chain fixture could not arm its first X.")
		return
	if combo_bot.choose_action(combo_bot_board) != combo_bot.ACTION_MOVE \
			or combo_bot.chosen_direction != chain_direction:
		fail("F4 did not follow its armed X with the available attack.")
		return
	if not combo_bot_board.try_move(chain_direction):
		fail("F4 chain fixture rejected the first X-protected attack.")
		return
	await create_timer(0.6).timeout
	if not combo_bot_board.game_state.is_idle() or combo_bot_board.bonus_step_armed:
		fail("The first X-protected attack did not return to an idle re-arm state.")
		return
	if combo_bot_board.score_manager.tier5_streak != ScoreManager.TIER5_STREAK_THRESHOLD + 1:
		fail("The first X-protected attack did not advance the established streak.")
		return
	if combo_bot.choose_action(combo_bot_board) != combo_bot.ACTION_DASH:
		fail("F4 did not re-arm X for the next high-heat attack.")
		return

	var ult_charge_board: Node2D = BoardScript.new()
	root.add_child(ult_charge_board)
	await process_frame
	ult_charge_board.spawn_warning_player.stop()
	ult_charge_board.inventory.reset()
	ult_charge_board.score_manager.combo_counter = ScoreManager.MAX_COMBO_TIER
	ult_charge_board.score_manager.tier5_streak = ScoreManager.TIER5_STREAK_THRESHOLD - 2
	ult_charge_board.energy_quarter_units = 10
	var ult_charge_direction: int = CharacterData.Direction.RIGHT
	var ult_charge_target: Vector2i = ult_charge_board.player_pos \
			+ CharacterData.DIR_VECTOR[ult_charge_direction]
	ult_charge_board.grid[ult_charge_target.y][ult_charge_target.x] = CharacterData.CellType.DEAD
	ult_charge_board.inventory.push(ult_charge_direction)
	if combo_bot.choose_action(ult_charge_board) != combo_bot.ACTION_MOVE:
		fail("F4 spent X instead of taking a Heat-5 kill that fills ULT.")
		return

	board._charge_energy_for_combo(4)
	if board.get_energy_quarter_units() != 5:
		fail("Heat 4 did not add one energy slot.")
		return
	board.score_manager.tier5_streak = 1
	board._charge_energy_for_combo(5)
	if board.get_energy_quarter_units() != 9:
		fail("Heat 5 base income did not remain one energy slot.")
		return
	board.energy_quarter_units = 0
	board.score_manager.tier5_streak = ScoreManager.TIER5_STREAK_THRESHOLD
	board._charge_energy_for_combo(5)
	if board.get_energy_quarter_units() != 8:
		fail("Every fifth Heat-5 kill did not add its extra energy slot.")
		return
	board.energy_quarter_units = 12
	if board.get_energy_quarter_units() != 12 or board.try_energy_ultimate():
		fail("Three energy slots incorrectly activated the four-slot ULT.")
		return
	board.score_manager.tier5_streak = ScoreManager.TIER5_STREAK_THRESHOLD + 1
	board._charge_energy_for_combo(5)
	if board.get_energy_quarter_units() != 16:
		fail("Heat 5 base income did not add up to the four-slot cap.")
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
	if not board.player_node.attack_ready_directions.is_empty():
		fail("A player-layer attack prompt remained visible during ULT.")
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
	board.score_manager.tier5_streak = ScoreManager.TIER5_STREAK_THRESHOLD - 1

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
	if board.get_energy_quarter_units() != board.TIER5_STREAK_ENERGY_BONUS:
		fail("The fifth Heat-5 DASH kill did not grant its streak energy bonus.")
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

	var flat_price_board: Node2D = BoardScript.new()
	root.add_child(flat_price_board)
	await process_frame
	flat_price_board.spawn_warning_player.stop()
	# X keeps one flat price no matter how deep the chain runs; what caps a
	# STEP run is that an X-paid kill returns nothing, so the bar only drains.
	flat_price_board.energy_quarter_units = board.ENERGY_QUARTER_UNITS_MAX
	var frozen_actions: int = 0
	while flat_price_board.try_energy_bonus_step():
		frozen_actions += 1
		flat_price_board.bonus_step_armed = false
		if frozen_actions > 8:
			break
	if frozen_actions != board.ENERGY_QUARTER_UNITS_MAX / board.ENERGY_SLOT_COST:
		fail(
			"A full energy bar armed %s STEPs, expected exactly four."
			% frozen_actions
		)
		return
	if flat_price_board.get_energy_quarter_units() != 0:
		fail("Four STEPs did not drain the whole bar at one flat slot each.")
		return

	var normal_attack_board: Node2D = BoardScript.new()
	root.add_child(normal_attack_board)
	await process_frame
	normal_attack_board.spawn_warning_player.stop()
	normal_attack_board.inventory.push(CharacterData.Direction.RIGHT)
	var normal_target: Vector2i = normal_attack_board.player_pos \
			+ CharacterData.DIR_VECTOR[CharacterData.Direction.RIGHT]
	normal_attack_board.grid[normal_target.y][normal_target.x] = CharacterData.CellType.DEAD
	if not normal_attack_board.try_move(CharacterData.Direction.RIGHT):
		fail("A valid normal attack was rejected.")
		return
	if normal_attack_board.inventory.find_direction(CharacterData.Direction.RIGHT) >= 0:
		fail("A normal attack kept its direction instead of consuming it.")
		return
	if normal_attack_board.get_energy_quarter_units() != 1:
		fail("A normal attack kill did not charge energy for the first combo.")
		return

	var energy_shield_board: Node2D = BoardScript.new()
	root.add_child(energy_shield_board)
	await process_frame
	energy_shield_board.spawn_warning_player.stop()
	energy_shield_board.score_manager.combo_counter = 3
	energy_shield_board.energy_quarter_units = energy_shield_board.ENERGY_QUARTER_UNITS_MAX
	energy_shield_board._spawn_hit_pending = true
	energy_shield_board._spawn_hit_uses_energy = true
	energy_shield_board._resolve_player_spawn_hit(
		energy_shield_board.player_pos, CharacterData.CellType.DEAD
	)
	if energy_shield_board.score_manager.combo_counter != 2:
		fail(
			"An energy-shielded spawn hit did not cool heat by one tier, reached %s."
			% energy_shield_board.score_manager.combo_counter
		)
		return
	if energy_shield_board.score_manager.score != 2:
		fail(
			"An energy-shielded spawn hit scored %s instead of the post-cooldown tier."
			% energy_shield_board.score_manager.score
		)
		return

	var direction_shield_board: Node2D = BoardScript.new()
	root.add_child(direction_shield_board)
	await process_frame
	direction_shield_board.spawn_warning_player.stop()
	direction_shield_board.score_manager.combo_counter = 4
	direction_shield_board.inventory.push(CharacterData.Direction.UP)
	direction_shield_board.inventory.push(CharacterData.Direction.DOWN)
	direction_shield_board._spawn_hit_pending = true
	direction_shield_board._spawn_hit_uses_energy = false
	direction_shield_board._resolve_player_spawn_hit(
		direction_shield_board.player_pos, CharacterData.CellType.DEAD
	)
	if direction_shield_board.score_manager.combo_counter != 3:
		fail(
			"A direction-shielded spawn hit did not cool heat by one tier, reached %s."
			% direction_shield_board.score_manager.combo_counter
		)
		return
	if direction_shield_board.inventory.queue.size() != 0:
		fail("A direction-shielded spawn hit did not spend both direction slots.")
		return

	print("PASS: EXTRA energy bonus-step verification.")
	quit(0)

func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)
