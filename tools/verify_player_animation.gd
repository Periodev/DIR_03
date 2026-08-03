extends Node

const MAIN_SCENE := preload("res://scenes/main.tscn")
const VisualStyle = preload("res://scripts/visual_style.gd")

var failures := 0


func _ready() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await create_timer(0.25).timeout

	await check_player_displacement(game)
	check_grid_line_toggle(game)
	check_active_vector_pulse(game)
	await check_install_tutorial_hint(game)
	await check_empty_release_error(game)
	await check_empty_install_hint(game)
	await check_loaded_block_rejects_install(game)
	await check_push_displacement(game)
	await check_same_direction_push_holds_queue(game)
	await check_install_reveal(game)
	await check_free_trigger_sequence(game)
	await check_blocked_trigger_sequence(game)
	await check_collision_trigger_sequence(game)
	await check_reset_cancels_animation(game)

	if failures == 0:
		print("PASS: player displacement and trigger animation checks passed.")
		quit(0)
	else:
		push_error("%s player animation check(s) failed." % failures)
		quit(1)


func create_timer(seconds: float) -> SceneTreeTimer:
	return get_tree().create_timer(seconds)


func quit(exit_code: int) -> void:
	get_tree().quit(exit_code)


func check_player_displacement(game: Node) -> void:
	require_level(game, "@..")
	var started: bool = bool(game.execute_command("R"))
	require(started, "player move command should be accepted")
	require(bool(game.input_locked), "player move should lock input")
	await create_timer(0.25).timeout
	require(not bool(game.input_locked), "player move should unlock after animation")
	require(
		Vector2i(game.player_cell) == Vector2i(1, 0),
		"player move should finish at the target cell"
	)


func check_grid_line_toggle(game: Node) -> void:
	var view: Node = game.board_view
	view.set_grid_lines_visible(false)
	require(not bool(view.grid_lines_visible), "grid lines should support being hidden")
	view.set_grid_lines_visible(true)
	require(bool(view.grid_lines_visible), "grid lines should support being restored")


func check_install_tutorial_hint(game: Node) -> void:
	var previous_level_id: String = Campaign.active_level_id
	require_level(game, "@A.")
	Campaign.active_level_id = "1-1"
	game.install_tutorial_completed = false
	game.player_queue = "Right"
	game.render_all()

	var view: Node = game.board_view
	view.update_install_tutorial_hint(0.0)
	require(
		Vector2i(view.install_tutorial_hint_cell) == Vector2i(1, 0),
		"install tutorial should target the faced empty block"
	)
	require(
		float(view.install_tutorial_hint_alpha()) == 0.0,
		"install tutorial should wait before appearing"
	)
	view.update_install_tutorial_hint(
		VisualStyle.INSTALL_TUTORIAL_HINT_DELAY_SECONDS
		+ VisualStyle.INSTALL_TUTORIAL_HINT_FADE_SECONDS
	)
	require(
		float(view.install_tutorial_hint_alpha()) >= 0.99,
		"install tutorial should fade in after the hesitation delay"
	)

	game.execute_command("X")
	view.update_install_tutorial_hint(0.0)
	require(
		Vector2i(view.install_tutorial_hint_cell) == Vector2i(-1, -1),
		"install tutorial should disappear after a successful install"
	)
	await create_timer(
		VisualStyle.INSTALL_VECTOR_DELAY_SECONDS
		+ VisualStyle.FACING_ACTION_SETTLE_SECONDS
		+ 0.05
	).timeout
	Campaign.active_level_id = previous_level_id


func check_empty_release_error(game: Node) -> void:
	require_level(game, "@..")
	var view: Node = game.board_view
	var command_count_before: int = game.command_history.size()
	var started: bool = bool(game.execute_command("T"))
	require(started, "empty release command should be accepted")
	require(not bool(game.input_locked), "empty release feedback should not lock input")
	require(
		game.command_history.size() == command_count_before + 1,
		"empty release should preserve existing command history behavior"
	)
	require(
		Vector2i(view.error_flash_cell) == Vector2i(game.player_cell),
		"empty release should target the player's cell"
	)
	require(
		float(view.error_flash_alpha) > 0.65,
		"empty release should start with a visible red overlay"
	)
	await create_timer(VisualStyle.ERROR_FLASH_SECONDS + 0.05).timeout
	require(float(view.error_flash_alpha) < 0.01, "error overlay should fade out")
	require(Vector2i(view.error_flash_cell) == Vector2i(-1, -1), "error cell should clear")


func check_active_vector_pulse(game: Node) -> void:
	require_level(game, "@AB.")
	var first_index: int = int(game.find_block_index_by_id(1))
	var first_block: Dictionary = game.blocks[first_index]
	first_block["vector"] = "Right"
	game.blocks[first_index] = first_block
	var second_index: int = int(game.find_block_index_by_id(2))
	var second_block: Dictionary = game.blocks[second_index]
	second_block["vector"] = "Down"
	game.blocks[second_index] = second_block
	game.install_order.assign([1, 2])
	game.render_all()
	var view: Node = game.board_view
	view.update_active_vector_pulse(0.0)
	require(int(view.queued_release_block_id()) == 1, "first installed block should be queued to release")
	require(int(view.active_vector_pulse_block_id) == 1, "first installed direction should pulse")
	view.active_vector_pulse_elapsed = VisualStyle.ACTIVE_VECTOR_PULSE_SECONDS / 2.0
	require(bool(view.should_draw_active_vector_pulse(1)), "active direction should draw its pulse")
	require(not bool(view.should_draw_active_vector_pulse(2)), "later direction should remain static")
	game.install_order.remove_at(0)
	view.update_active_vector_pulse(0.0)
	require(int(view.active_vector_pulse_block_id) == 2, "next direction should pulse after release")
	view.install_reveal_block_id = 2
	view.update_active_vector_pulse(0.0)
	require(
		not bool(view.should_draw_active_vector_pulse(2)),
		"active pulse should wait for the installed direction reveal"
	)
	view.install_reveal_block_id = -1


func check_loaded_block_rejects_install(game: Node) -> void:
	require_level(game, "@A.")
	install_test_vector(game, 1, "Right")
	game.player_queue = "Left"
	game.render_all()
	var view: Node = game.board_view
	var started: bool = bool(game.execute_command("X"))
	require(started, "install rejection command should be accepted")
	require(not bool(game.input_locked), "install rejection feedback should not lock input")
	require(String(game.player_queue) == "Left", "rejected install should keep player vector")
	var block_index: int = int(game.find_block_index_by_id(1))
	var block: Dictionary = game.blocks[block_index]
	require(String(block["vector"]) == "Right", "rejected install should keep block vector")
	require(
		int(view.error_flash_subject) == int(view.ERROR_FLASH_BLOCK),
		"rejected install should flash the target block"
	)
	require(
		Vector2i(view.error_flash_cell) == Vector2i(1, 0),
		"install rejection should target the occupied block cell"
	)
	require(float(view.error_flash_alpha) > 0.65, "target block flash should be visible")
	await create_timer(VisualStyle.ERROR_FLASH_SECONDS + 0.05).timeout
	require(int(view.error_flash_subject) == int(view.ERROR_FLASH_NONE), "block error should clear")


func check_empty_install_hint(game: Node) -> void:
	require_level(game, "@A.")
	var view: Node = game.board_view
	var started: bool = bool(game.execute_command("X"))
	require(started, "empty install command should be accepted")
	require(not bool(game.input_locked), "empty install hint should not lock input")
	require(String(game.player_queue) == "", "empty install should keep player empty")
	var block_index: int = int(game.find_block_index_by_id(1))
	var block: Dictionary = game.blocks[block_index]
	require(String(block["vector"]) == "", "empty install should keep block empty")
	require(
		int(view.error_flash_subject) == int(view.ERROR_FLASH_BLOCK),
		"empty install should hint on the target block"
	)
	require(String(view.error_flash_color_key) == "hint_flash", "empty install should use neutral hint color")
	require(
		is_equal_approx(float(view.error_flash_alpha), VisualStyle.HINT_FLASH_MAX_ALPHA),
		"empty install hint should stay low intensity"
	)
	await create_timer(VisualStyle.HINT_FLASH_SECONDS + 0.05).timeout
	require(int(view.error_flash_subject) == int(view.ERROR_FLASH_NONE), "empty install hint should clear")

	require_level(game, "@A.")
	install_test_vector(game, 1, "Right")
	started = bool(game.execute_command("X"))
	require(started, "empty-hand retrieval rejection should be accepted")
	require(String(game.player_queue) == "", "normal block should not return its vector")
	block_index = int(game.find_block_index_by_id(1))
	block = game.blocks[block_index]
	require(String(block["vector"]) == "Right", "normal block should keep its vector")
	require(
		String(view.error_flash_color_key) == "hint_flash",
		"empty-hand retrieval rejection should use the neutral hint"
	)
	await create_timer(VisualStyle.HINT_FLASH_SECONDS + 0.05).timeout

	require_level(game, "@R.")
	install_test_vector(game, 1, "Right")
	started = bool(game.execute_command("X"))
	require(started, "recovery interaction should be accepted")
	require(String(game.player_queue) == "Right", "recovery block should return its vector")
	block_index = int(game.find_block_index_by_id(1))
	block = game.blocks[block_index]
	require(String(block["vector"]) == "", "recovery block should become empty")
	require(
		String(view.error_flash_color_key) == "hint_flash",
		"successful empty-hand recovery should use the neutral hint"
	)
	await create_timer(VisualStyle.HINT_FLASH_SECONDS + 0.05).timeout


func check_push_displacement(game: Node) -> void:
	require_level(game, "@A.*")
	game.goal_cells.clear()
	game.goal_cells.append(Vector2i(1, 0))
	game.goal_cells.append(Vector2i(3, 0))
	game.render_all()
	var view: Node = game.board_view
	require(
		bool(view.is_goal_visually_occupied(Vector2i(1, 0))),
		"a stationary block should hide its occupied goal marker"
	)
	var started: bool = bool(game.execute_command("R"))
	require(started, "push command should be accepted")
	require(bool(game.input_locked), "push should lock input")
	require(
		not bool(view.is_goal_visually_occupied(Vector2i(1, 0))),
		"a moving block should reveal its source goal beneath the animation"
	)
	await create_timer(
		VisualStyle.FACING_ACTION_RETREAT_SECONDS / 2.0
	).timeout
	require(
		bool(view.player_queue_reveal_pending),
		"pushed direction should remain hidden before movement starts"
	)
	require(
		float(view.facing_action_offset_ratio) < 0.0,
		"push should retreat the facing chevron before release"
	)
	require(
		float(view.displacement_progress) < 0.01,
		"pushed block should wait for the push delay"
	)
	await create_timer(
		VisualStyle.FACING_ACTION_RETREAT_SECONDS / 2.0
		+ VisualStyle.FACING_ACTION_HOLD_SECONDS
		+ VisualStyle.FACING_ACTION_FORWARD_SECONDS * 0.7
	).timeout
	require(
		float(view.facing_action_offset_ratio) > 0.0,
		"push should send the facing chevron slightly forward"
	)
	require(
		float(view.displacement_progress) < 0.01,
		"pushed block should remain still until the facing action finishes"
	)
	require(
		bool(view.player_queue_reveal_pending),
		"pushed direction should remain hidden through the push delay"
	)
	await create_timer(
		VisualStyle.PUSH_DISPLACEMENT_DELAY_SECONDS * 0.5
	).timeout
	require(
		not bool(view.player_queue_reveal_pending),
		"pushed direction should appear when block movement starts"
	)
	await create_timer(
		VisualStyle.DISPLACEMENT_SECONDS + 0.05
	).timeout
	var block_index: int = int(game.find_block_index_by_id(1))
	var block: Dictionary = game.blocks[block_index]
	require(
		Vector2i(block["cell"]) == Vector2i(2, 0),
		"pushed block should finish at the target cell"
	)
	require(not bool(game.input_locked), "push should unlock after animation")


func check_same_direction_push_holds_queue(game: Node) -> void:
	require_level(game, "@A.*")
	game.player_queue = "Right"
	game.render_all()
	var started: bool = bool(game.execute_command("R"))
	require(started, "same-direction push command should be accepted")
	var view: Node = game.board_view
	require(
		not bool(view.player_queue_reveal_pending),
		"same-direction push should keep the stored vector visible"
	)
	await create_timer(VisualStyle.PUSH_DISPLACEMENT_DELAY_SECONDS * 0.6).timeout
	require(
		not bool(view.player_queue_reveal_pending),
		"same-direction stored vector should hold through the push delay"
	)
	await create_timer(VisualStyle.DISPLACEMENT_SECONDS + 0.1).timeout
	require(
		String(game.player_queue) == "Right",
		"same-direction push should preserve the queue value"
	)
	require(not bool(game.input_locked), "same-direction push should unlock normally")


func check_install_reveal(game: Node) -> void:
	require_level(game, "@A.")
	game.player_queue = "Right"
	game.render_all()
	var started: bool = bool(game.execute_command("X"))
	require(started, "install command should be accepted")
	require(bool(game.input_locked), "install reveal should lock input")
	var view: Node = game.board_view
	var block_center: Vector2 = view.cell_center(Vector2i(1, 0))
	var stored_center: Vector2 = view.stored_vector_center(block_center, "Right")
	require(
		stored_center.x > block_center.x and is_equal_approx(stored_center.y, block_center.y),
		"stored direction glyph should offset toward its direction"
	)
	var triangle: PackedVector2Array = view.direction_triangle_points(
		stored_center,
		"Right"
	)
	var first_leg: Vector2 = (triangle[1] - triangle[0]).normalized()
	var second_leg: Vector2 = (triangle[2] - triangle[0]).normalized()
	require(
		is_zero_approx(first_leg.dot(second_leg)),
		"stored direction glyph should have a forward-facing right angle"
	)
	require(
		int(view.install_reveal_block_id) == 1,
		"installed direction should remain hidden during the reveal delay"
	)
	await create_timer(
		VisualStyle.INSTALL_VECTOR_DELAY_SECONDS * 0.55
	).timeout
	require(
		float(view.facing_action_offset_ratio) < 0.0,
		"install should hold then release the facing chevron before reveal"
	)
	require(
		int(view.install_reveal_block_id) == 1,
		"installed direction should still be hidden halfway through the delay"
	)
	await create_timer(
		VisualStyle.INSTALL_VECTOR_DELAY_SECONDS * 0.45
	).timeout
	var block_index: int = int(game.find_block_index_by_id(1))
	var block: Dictionary = game.blocks[block_index]
	require(
		String(block["vector"]) == "Right",
		"install reveal should preserve the installed direction"
	)
	require(
		int(view.install_reveal_block_id) == -1,
		"installed direction should appear after the reveal delay"
	)
	require(
		bool(game.input_locked),
		"install should remain locked while the facing chevron settles"
	)
	await create_timer(
		VisualStyle.FACING_ACTION_SETTLE_SECONDS + 0.05
	).timeout
	require(
		not bool(game.input_locked),
		"install should unlock after the facing chevron settles"
	)


func check_free_trigger_sequence(game: Node) -> void:
	require_level(game, "@A.*")
	install_test_vector(game, 1, "Right")
	var started: bool = bool(game.execute_command("T"))
	require(started, "free trigger command should be accepted")
	require(bool(game.input_locked), "free trigger should lock input")
	await create_timer(
		VisualStyle.TRIGGER_FLASH_IN_SECONDS
		+ VisualStyle.TRIGGER_FLASH_HOLD_SECONDS / 2.0
	).timeout
	var view: Node = game.board_view
	require(
		float(view.trigger_flash_mix) > 0.9,
		"trigger direction should reach its white flash before movement"
	)
	require(
		float(view.displacement_progress) < 0.01,
		"triggered block should wait for the white flash"
	)
	require(
		int(view.collision_carrier_block_id) == -1,
		"free trigger should not animate a collision source"
	)
	await create_timer(
		VisualStyle.TRIGGER_FLASH_HOLD_SECONDS / 2.0
		+ VisualStyle.DISPLACEMENT_SECONDS / 2.0
	).timeout
	require(
		float(view.trigger_flash_alpha) < 0.9,
		"trigger direction should fade during movement"
	)
	require(
		float(view.displacement_progress) > 0.05,
		"triggered block should move while the flash fades"
	)
	await create_timer(
		VisualStyle.DISPLACEMENT_SECONDS / 2.0
		+ VisualStyle.DISPLACEMENT_SECONDS
	).timeout
	var block_index: int = int(game.find_block_index_by_id(1))
	var block: Dictionary = game.blocks[block_index]
	require(
		Vector2i(block["cell"]) == Vector2i(2, 0),
		"free trigger should move its carrier"
	)
	require(not bool(game.input_locked), "free trigger should unlock after animation")


func check_blocked_trigger_sequence(game: Node) -> void:
	require_level(game, "@A")
	install_test_vector(game, 1, "Right")
	var started: bool = bool(game.execute_command("T"))
	require(started, "blocked trigger command should be accepted")
	require(bool(game.input_locked), "blocked trigger should lock input")
	require(game.install_order.is_empty(), "blocked trigger should consume install order")
	var block_index: int = int(game.find_block_index_by_id(1))
	var block: Dictionary = game.blocks[block_index]
	require(String(block["vector"]) == "", "blocked trigger should consume vector")
	require(
		Vector2i(block["cell"]) == Vector2i(1, 0),
		"blocked trigger should not move its carrier"
	)
	await create_timer(
		VisualStyle.TRIGGER_FLASH_IN_SECONDS
		+ VisualStyle.TRIGGER_FLASH_HOLD_SECONDS / 2.0
	).timeout
	var view: Node = game.board_view
	require(
		float(view.trigger_flash_mix) > 0.9,
		"blocked trigger direction should reach its white flash"
	)
	require(
		Vector2i(view.displacement_from) == Vector2i(view.displacement_to),
		"blocked trigger should preserve its logical cell"
	)
	await create_timer(VisualStyle.TRIGGER_FLASH_HOLD_SECONDS / 2.0).timeout
	var peak_shake := 0.0
	var fade_observed := false
	for _frame in range(8):
		await get_tree().process_frame
		peak_shake = maxf(
			peak_shake,
			absf(float(view.blocked_release_offset_ratio))
		)
		fade_observed = fade_observed or float(view.trigger_flash_alpha) < 0.9
	require(
		peak_shake > 0.01,
		"blocked trigger should shake its carrier along the release axis"
	)
	require(
		fade_observed,
		"blocked trigger direction should fade after flashing"
	)
	await create_timer(VisualStyle.BLOCKED_RELEASE_SHAKE_SECONDS + 0.05).timeout
	require(not bool(game.input_locked), "blocked trigger should unlock after animation")
	require(
		int(view.trigger_flash_block_id) == -1,
		"blocked trigger flash should clear after animation"
	)
	require(
		absf(float(view.blocked_release_offset_ratio)) < 0.001,
		"blocked trigger shake should return to the cell center"
	)


func check_collision_trigger_sequence(game: Node) -> void:
	require_level(game, "@AB.*")
	install_test_vector(game, 1, "Right")
	var started: bool = bool(game.execute_command("T"))
	require(started, "collision trigger command should be accepted")
	require(bool(game.input_locked), "collision trigger should lock input")
	var approach_start := (
		VisualStyle.TRIGGER_FLASH_IN_SECONDS
		+ VisualStyle.TRIGGER_FLASH_HOLD_SECONDS
	)
	await create_timer(
		approach_start + VisualStyle.COLLISION_APPROACH_SECONDS / 2.0
	).timeout
	var view: Node = game.board_view
	require(
		int(view.collision_carrier_block_id) == 1,
		"collision should identify the anchored source block"
	)
	require(
		float(view.collision_source_offset_ratio) > 0.0,
		"collision source should approach the target"
	)
	require(
		float(view.collision_source_offset_ratio)
			<= VisualStyle.COLLISION_CONTACT_OFFSET_RATIO,
		"collision source should not pass the contact boundary"
	)
	require(
		float(view.displacement_progress) < 0.01,
		"collision target should wait until after contact"
	)
	await create_timer(
		VisualStyle.COLLISION_APPROACH_SECONDS / 2.0
		+ VisualStyle.COLLISION_HOLD_SECONDS
		+ VisualStyle.COLLISION_TARGET_LEAD_SECONDS
		+ 0.02
	).timeout
	require(
		float(view.displacement_progress)
			> VisualStyle.COLLISION_TARGET_LEAD_RATIO,
		"collision target should continue after the lead handoff"
	)
	require(
		float(view.collision_source_offset_ratio)
			< VisualStyle.COLLISION_CONTACT_OFFSET_RATIO,
		"collision source should return only after the target lead"
	)
	require(
		float(view.collision_source_offset_ratio) > 0.0,
		"collision source should still be returning after the handoff"
	)
	await create_timer(
		collision_trigger_total_seconds()
		- approach_start
		- VisualStyle.COLLISION_APPROACH_SECONDS
		- VisualStyle.COLLISION_HOLD_SECONDS
		+ 0.05
	).timeout
	var carrier_index: int = int(game.find_block_index_by_id(1))
	var pushed_index: int = int(game.find_block_index_by_id(2))
	var carrier: Dictionary = game.blocks[carrier_index]
	var pushed: Dictionary = game.blocks[pushed_index]
	require(
		Vector2i(carrier["cell"]) == Vector2i(1, 0),
		"collision carrier should remain anchored"
	)
	require(
		Vector2i(pushed["cell"]) == Vector2i(3, 0),
		"collision target should finish one cell forward"
	)
	require(
		not bool(game.input_locked),
		"collision trigger should unlock after animation"
	)
	require(
		int(view.collision_carrier_block_id) == -1,
		"collision source animation should clear after movement"
	)


func check_reset_cancels_animation(game: Node) -> void:
	require_level(game, "@AB.*")
	install_test_vector(game, 1, "Right")
	game.execute_command("T")
	require(bool(game.input_locked), "trigger should be active before reset")
	game.reset_level()
	require(not bool(game.input_locked), "reset should unlock immediately")
	await create_timer(collision_trigger_total_seconds() + 0.05).timeout
	var carrier_index: int = int(game.find_block_index_by_id(1))
	var pushed_index: int = int(game.find_block_index_by_id(2))
	var carrier: Dictionary = game.blocks[carrier_index]
	var pushed: Dictionary = game.blocks[pushed_index]
	require(
		Vector2i(carrier["cell"]) == Vector2i(1, 0),
		"reset should restore the carrier cell"
	)
	require(
		Vector2i(pushed["cell"]) == Vector2i(2, 0),
		"reset should restore the pushed block cell"
	)
	require(
		not bool(game.level_completed),
		"a cancelled animation must not complete the reset level"
	)


func require_level(game: Node, source: String) -> void:
	var error: String = str(game.replace_level_from_text(source))
	require(error == "", "test level should parse: %s" % error)


func trigger_total_seconds() -> float:
	return (
		VisualStyle.TRIGGER_FLASH_IN_SECONDS
		+ VisualStyle.TRIGGER_FLASH_HOLD_SECONDS
		+ maxf(
			VisualStyle.TRIGGER_FLASH_OUT_SECONDS,
			VisualStyle.DISPLACEMENT_SECONDS
		)
	)


func collision_trigger_total_seconds() -> float:
	return (
		VisualStyle.TRIGGER_FLASH_IN_SECONDS
		+ VisualStyle.TRIGGER_FLASH_HOLD_SECONDS
		+ VisualStyle.COLLISION_APPROACH_SECONDS
		+ VisualStyle.COLLISION_HOLD_SECONDS
		+ VisualStyle.COLLISION_TARGET_SECONDS
	)


func install_test_vector(
	game: Node,
	block_id: int,
	direction_name: String
) -> void:
	var block_index: int = int(game.find_block_index_by_id(block_id))
	var block: Dictionary = game.blocks[block_index]
	block["vector"] = direction_name
	game.blocks[block_index] = block
	game.install_order.clear()
	game.install_order.append(block_id)
	game.render_all()


func require(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
