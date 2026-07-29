extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")
const VisualStyle = preload("res://scripts/visual_style.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await create_timer(0.25).timeout

	await check_player_displacement(game)
	await check_push_displacement(game)
	await check_install_reveal(game)
	await check_free_trigger_sequence(game)
	await check_collision_trigger_sequence(game)
	await check_reset_cancels_animation(game)

	if failures == 0:
		print("PASS: player displacement and trigger animation checks passed.")
		quit(0)
	else:
		push_error("%s player animation check(s) failed." % failures)
		quit(1)


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


func check_push_displacement(game: Node) -> void:
	require_level(game, "@A.*")
	var started: bool = bool(game.execute_command("R"))
	require(started, "push command should be accepted")
	require(bool(game.input_locked), "push should lock input")
	await create_timer(
		VisualStyle.FACING_ACTION_RETREAT_SECONDS / 2.0
	).timeout
	var view: Node = game.board_view
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


func check_install_reveal(game: Node) -> void:
	require_level(game, "@A.")
	game.player_queue = "Right"
	game.render_all()
	var started: bool = bool(game.execute_command("X"))
	require(started, "install command should be accepted")
	require(bool(game.input_locked), "install reveal should lock input")
	var view: Node = game.board_view
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


func check_collision_trigger_sequence(game: Node) -> void:
	require_level(game, "@AB.*")
	install_test_vector(game, 1, "Right")
	var started: bool = bool(game.execute_command("T"))
	require(started, "collision trigger command should be accepted")
	require(bool(game.input_locked), "collision trigger should lock input")
	await create_timer(trigger_total_seconds() + 0.05).timeout
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


func check_reset_cancels_animation(game: Node) -> void:
	require_level(game, "@AB.*")
	install_test_vector(game, 1, "Right")
	game.execute_command("T")
	require(bool(game.input_locked), "trigger should be active before reset")
	game.reset_level()
	require(not bool(game.input_locked), "reset should unlock immediately")
	await create_timer(trigger_total_seconds() + 0.05).timeout
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
