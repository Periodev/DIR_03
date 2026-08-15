extends Node2D

const BoardView = preload("res://scripts/board_view.gd")
const GameHud = preload("res://scripts/game_hud.gd")
const AudioFeedback = preload("res://scripts/audio_feedback.gd")

const MAX_DEBUG_LINES := 10

const EMPTY := 0
const WALL := 1
const INITIAL_LEVEL_PATH := "res://levels/level_test.txt"
const VALID_COMMANDS := "UDLRXT"
const INSTALL_TUTORIAL_LEVEL_ID := "1-1"
const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT,
]


class BoardSnapshot:
	extends RefCounted

	var player_cell := Vector2i.ZERO
	var player_queue := ""
	var facing_direction := Vector2i.RIGHT
	var facing_name := "Right"
	var blocks: Array[Dictionary] = []
	var install_order: Array[int] = []
	var command_history: Array[String] = []
	var level_completed := false


var terrain: Array[Array] = []
var initial_player_cell := Vector2i.ZERO
var initial_blocks: Array[Dictionary] = []
var goal_cells: Array[Vector2i] = []
var horizontal_edges: Array[Array] = []
var vertical_edges: Array[Array] = []
var static_dead_cells: Array[Vector2i] = []
var player_cell := Vector2i.ZERO
var player_queue := ""
var facing_direction := Vector2i.RIGHT
var facing_name := "Right"
var input_locked := false
var level_completed := false

var blocks: Array[Dictionary] = []
var install_order: Array[int] = []
var command_history: Array[String] = []
var debug_lines: Array[String] = []
var level_source_text := ""
var undo_enabled := false
var undo_stack: Array[BoardSnapshot] = []
var install_tutorial_completed := false

var board_view
var game_hud
var audio_feedback: DirAudioFeedback
var debug_panel
var hud_layer: CanvasLayer


func _ready() -> void:
	if not load_initial_level():
		return

	audio_feedback = AudioFeedback.new()
	add_child(audio_feedback)

	board_view = create_board_view()
	board_view.initialize(self)

	game_hud = create_game_hud()
	game_hud.initialize(self, board_view)
	if board_view.get_parent() == null:
		add_child(board_view)
	add_child(game_hud)
	hud_layer = game_hud

	set_message("Arrow keys: move/push. X: install; when empty-handed, retrieve from a recovery block. Space: trigger oldest installed vector.")
	append_debug_log("Ready: v1.1 vector queue prototype.")
	check_level_completion()
	render_all()


func create_board_view():
	return BoardView.new()


func create_game_hud():
	return GameHud.new()


func execute_command(command: String) -> bool:
	if input_locked or level_completed:
		return false

	var normalized_command := command.to_upper()
	if normalized_command.length() != 1 or not VALID_COMMANDS.contains(normalized_command):
		return false

	if not command_will_change_state(normalized_command):
		show_ineffective_command_feedback(normalized_command)
		return false

	if undo_enabled:
		undo_stack.append(capture_board_snapshot())
	command_history.append(normalized_command)
	match normalized_command:
		"U":
			try_move(Vector2i.UP, "Up")
		"D":
			try_move(Vector2i.DOWN, "Down")
		"L":
			try_move(Vector2i.LEFT, "Left")
		"R":
			try_move(Vector2i.RIGHT, "Right")
		"X":
			install_vector()
		"T":
			trigger_vector()
	return true


func command_will_change_state(command: String) -> bool:
	match command:
		"U":
			return movement_will_change_state(Vector2i.UP)
		"D":
			return movement_will_change_state(Vector2i.DOWN)
		"L":
			return movement_will_change_state(Vector2i.LEFT)
		"R":
			return movement_will_change_state(Vector2i.RIGHT)
		"X":
			return install_will_change_state()
		"T":
			return not install_order.is_empty()
	return false


func movement_will_change_state(direction: Vector2i) -> bool:
	if facing_direction != direction:
		return true

	var target: Vector2i = player_cell + direction
	var block_index: int = find_block_index_at(target)
	if block_index == -1:
		return is_cell_walkable_for_player(player_cell, target)
	return can_block_move_to(target, target + direction)


func install_will_change_state() -> bool:
	var target: Vector2i = player_cell + facing_direction
	var block_index: int = find_block_index_at(target)
	if block_index == -1:
		return false

	var block: Dictionary = blocks[block_index]
	if player_queue == "":
		return is_recovery_block(block) and String(block["vector"]) != ""
	return String(block["vector"]) == ""


func show_ineffective_command_feedback(command: String) -> void:
	match command:
		"U":
			show_ineffective_move_feedback(Vector2i.UP, "Up")
		"D":
			show_ineffective_move_feedback(Vector2i.DOWN, "Down")
		"L":
			show_ineffective_move_feedback(Vector2i.LEFT, "Left")
		"R":
			show_ineffective_move_feedback(Vector2i.RIGHT, "Right")
		"X":
			show_ineffective_install_feedback()
		"T":
			set_message("Nothing installed to release.")
			append_debug_log("Release unavailable: no installed vectors.")
			start_player_hint_feedback()
	update_hud()


func show_ineffective_move_feedback(direction: Vector2i, direction_name: String) -> void:
	var target: Vector2i = player_cell + direction
	var block_index: int = find_block_index_at(target)
	if block_index == -1:
		set_message("Blocked by wall, fence or board edge. Queue unchanged.")
		append_debug_log("Move %s failed: wall, fence or edge." % direction_name)
		return

	var block_id: int = int(blocks[block_index]["id"])
	set_message("Push failed. Queue unchanged.")
	append_debug_log("Push %s failed: block %s is blocked." % [
		direction_name,
		block_label(block_id),
	])


func show_ineffective_install_feedback() -> void:
	var target: Vector2i = player_cell + facing_direction
	var block_index: int = find_block_index_at(target)
	if block_index == -1:
		set_message("Interact failed. Face a block.")
		append_debug_log("Interact failed: no block at %s." % cell_text(target))
		return

	var block: Dictionary = blocks[block_index]
	if player_queue == "":
		start_block_hint_feedback(block["cell"])
		if String(block["vector"]) == "":
			set_message("Nothing held to install.")
			append_debug_log("Install unchanged: player and block are empty.")
		else:
			set_message("Retrieve failed. Only recovery blocks return installed vectors.")
			append_debug_log("Retrieve failed: block %s is not a recovery block." % block_label(block["id"]))
		return

	set_message("Install failed. Block already has a vector.")
	append_debug_log("Install %s failed: block %s already has %s." % [
		player_queue,
		block_label(block["id"]),
		block["vector"],
	])
	start_block_error_feedback(block["cell"])


func try_move(direction: Vector2i, direction_name: String) -> void:
	begin_atomic_input()
	var target := player_cell + direction
	var block_index := find_block_index_at(target)
	var facing_changed := facing_direction != direction

	if block_index != -1 and facing_changed:
		facing_direction = direction
		facing_name = direction_name
		var block_id := int(blocks[block_index]["id"])
		set_message("Turned %s to face block. Press again to push." % direction_name)
		append_debug_log("Turn %s: faced block %s without pushing." % [direction_name, block_label(block_id)])
		play_turn_feedback()
		render_all()
		end_atomic_input()
		return

	facing_direction = direction
	facing_name = direction_name

	if not is_cell_walkable_for_player(player_cell, target):
		set_message("Blocked by wall, fence or board edge. Queue unchanged.")
		append_debug_log("Move %s failed: wall, fence or edge." % direction_name)
		if facing_changed:
			play_turn_feedback()
		render_all()
		end_atomic_input()
		return

	if block_index == -1:
		var player_from: Vector2i = player_cell
		player_cell = target
		set_message("Moved through empty space. Queue unchanged.")
		append_debug_log("Move %s: player -> %s." % [direction_name, cell_text(player_cell)])
		play_player_move_feedback()
		if start_player_displacement(player_from, target):
			return
		finish_displacement_action(false)
		return

	var block_target := target + direction
	if not can_block_move_to(target, block_target):
		var block_id := int(blocks[block_index]["id"])
		set_message("Push failed. Queue unchanged.")
		append_debug_log("Push %s failed: block %s is blocked." % [direction_name, block_label(block_id)])
		render_all()
		end_atomic_input()
		return

	var pushed_block: Dictionary = blocks[block_index]
	var block_from: Vector2i = pushed_block["cell"]
	var pushed_block_id: int = int(pushed_block["id"])
	pushed_block["cell"] = block_target
	blocks[block_index] = pushed_block

	var player_queue_changed := player_queue != direction_name
	enqueue_player_queue(direction_name)
	set_message("Push succeeded. Player stayed in place. Queue is now %s." % direction_name)
	append_debug_log("Push %s: block %s -> %s; %s" % [
		direction_name,
		block_label(pushed_block["id"]),
		cell_text(block_target),
		"queue overwritten",
	])
	play_block_push_feedback()
	play_facing_action()
	if start_block_displacement(
		pushed_block_id,
		block_from,
		block_target,
		player_queue_changed
	):
		return
	finish_displacement_action(true)


func install_vector() -> void:
	begin_atomic_input()
	var target := player_cell + facing_direction
	var block_index := find_block_index_at(target)
	if block_index == -1:
		set_message("Interact failed. Face a block.")
		append_debug_log("Interact failed: no block at %s." % cell_text(target))
		end_atomic_input()
		return

	var block: Dictionary = blocks[block_index]
	if player_queue == "":
		start_block_hint_feedback(block["cell"])
		if is_recovery_block(block) and block["vector"] != "":
			retrieve_recovery_vector(block_index, block)
			end_atomic_input()
			return

		if block["vector"] == "":
			set_message("Nothing held to install.")
			append_debug_log("Install unchanged: player and block are empty.")
		else:
			set_message("Retrieve failed. Only recovery blocks return installed vectors.")
			append_debug_log("Retrieve failed: block %s is not a recovery block." % block_label(block["id"]))
		end_atomic_input()
		return

	if block["vector"] != "":
		set_message("Install failed. Block already has a vector.")
		append_debug_log("Install %s failed: block %s already has %s." % [
			player_queue,
			block_label(block["id"]),
			block["vector"],
		])
		start_block_error_feedback(block["cell"])
		end_atomic_input()
		return

	var installed_vector := player_queue
	block["vector"] = installed_vector
	blocks[block_index] = block
	install_order.append(block["id"])
	player_queue = ""
	if Campaign.active_level_id == INSTALL_TUTORIAL_LEVEL_ID:
		install_tutorial_completed = true

	set_message("Installed %s on block %s." % [installed_vector, block_label(block["id"])])
	append_debug_log("Install: %s -> block %s; order %s." % [
		installed_vector,
		block_label(block["id"]),
		install_order_text(),
	])
	play_install_feedback()
	render_all()
	play_facing_action()
	if start_install_reveal(int(block["id"])):
		return
	end_atomic_input()


func trigger_vector() -> void:
	begin_atomic_input()

	if install_order.is_empty():
		set_message("Nothing installed to release.")
		append_debug_log("Release unavailable: no installed vectors.")
		start_player_hint_feedback()
		end_atomic_input()
		return

	var carrier_id := install_order[0]
	var carrier_index := find_block_index_by_id(carrier_id)
	if carrier_index == -1:
		install_order.remove_at(0)
		set_message("Trigger skipped stale install entry.")
		append_debug_log("Trigger skipped stale block id %s." % carrier_id)
		render_all()
		end_atomic_input()
		return

	var carrier: Dictionary = blocks[carrier_index]
	var vector_name: String = carrier["vector"]
	if vector_name == "":
		install_order.remove_at(0)
		set_message("Trigger skipped block without vector.")
		append_debug_log("Trigger skipped block %s: no vector." % block_label(carrier_id))
		render_all()
		end_atomic_input()
		return

	play_trigger_activation_feedback()
	var direction := direction_from_name(vector_name)
	var target: Vector2i = carrier["cell"] + direction

	if not is_inside_board(target) or is_wall(target):
		consume_blocked_trigger(
			carrier_index,
			carrier,
			"Vector dissipated against wall or edge.",
			"Trigger %s consumed: block %s faces wall/edge." % [vector_name, block_label(carrier_id)]
		)
		return
	if is_fence_between(carrier["cell"], target):
		consume_blocked_trigger(
			carrier_index,
			carrier,
			"Vector dissipated against a fence.",
			"Trigger %s consumed: fence blocks block %s." % [vector_name, block_label(carrier_id)]
		)
		return

	if target == player_cell:
		consume_blocked_trigger(
			carrier_index,
			carrier,
			"Vector dissipated against the player.",
			"Trigger %s consumed: player blocks block %s." % [vector_name, block_label(carrier_id)]
		)
		return

	var front_block_index := find_block_index_at(target)
	if front_block_index == -1:
		var carrier_from: Vector2i = carrier["cell"]
		carrier["cell"] = target
		consume_carrier_vector(carrier_index, carrier)
		set_message("Triggered %s. Block %s moved one cell." % [vector_name, block_label(carrier_id)])
		append_debug_log("Trigger %s: block %s -> %s." % [
			vector_name,
			block_label(carrier_id),
			cell_text(target),
		])
		if start_trigger_displacement(
			carrier_id,
			vector_name,
			carrier_id,
			carrier_from,
			target
		):
			return
		finish_displacement_action(true)
		return

	var pushed_target := target + direction
	if not can_block_move_to(target, pushed_target):
		consume_blocked_trigger(
			carrier_index,
			carrier,
			"Vector dissipated against a blocked target.",
			"Trigger %s consumed: block %s cannot push block %s." % [
				vector_name,
				block_label(carrier_id),
				block_label(blocks[front_block_index]["id"]),
			]
		)
		return

	var pushed_block: Dictionary = blocks[front_block_index]
	var pushed_from: Vector2i = pushed_block["cell"]
	var pushed_block_id: int = int(pushed_block["id"])
	pushed_block["cell"] = pushed_target
	blocks[front_block_index] = pushed_block
	consume_carrier_vector(carrier_index, carrier)
	set_message("Triggered %s. Block %s anchored; block %s moved." % [
		vector_name,
		block_label(carrier_id),
		block_label(pushed_block["id"]),
	])
	append_debug_log("Trigger %s: block %s anchored; block %s -> %s." % [
		vector_name,
		block_label(carrier_id),
		block_label(pushed_block["id"]),
		cell_text(pushed_target),
	])
	if start_trigger_displacement(
		carrier_id,
		vector_name,
		pushed_block_id,
		pushed_from,
		pushed_target
	):
		return
	finish_displacement_action(true)


func undo_last_command() -> bool:
	if not undo_enabled or input_locked:
		return false

	if undo_stack.is_empty():
		set_message("Nothing to undo.")
		append_debug_log("Undo failed: history empty.")
		update_hud()
		return false

	begin_atomic_input()
	var undone_command := "?"
	if not command_history.is_empty():
		undone_command = command_history.back()

	var snapshot: BoardSnapshot = undo_stack.pop_back()
	restore_board_snapshot(snapshot)
	if game_hud != null:
		game_hud.clear_result()
	set_message("Undid %s." % undone_command)
	append_debug_log("Undo %s: restored previous board; %s step(s) remain." % [
		undone_command,
		undo_stack.size(),
	])
	render_all()
	end_atomic_input()
	return true


func reset_level() -> void:
	begin_atomic_input()
	reset_completion_feedback()
	player_cell = initial_player_cell
	player_queue = ""
	level_completed = false
	blocks = duplicate_initial_blocks()
	face_nearest_initial_block()
	install_order.clear()
	command_history.clear()
	undo_stack.clear()
	debug_lines.clear()
	game_hud.clear_result()
	set_message("Level reset.")
	append_debug_log("Reset: restored initial board, queue, and install order.")
	check_level_completion()
	render_all()
	end_atomic_input()


func install_tutorial_target_cell() -> Vector2i:
	if (
		Campaign.active_level_id != INSTALL_TUTORIAL_LEVEL_ID
		or install_tutorial_completed
		or player_queue == ""
	):
		return Vector2i(-1, -1)

	var target: Vector2i = player_cell + facing_direction
	var block_index: int = find_block_index_at(target)
	if block_index == -1:
		return Vector2i(-1, -1)

	var block: Dictionary = blocks[block_index]
	if String(block["vector"]) != "":
		return Vector2i(-1, -1)
	return target


func release_tutorial_target_cell() -> Vector2i:
	if (
		Campaign.active_level_id != INSTALL_TUTORIAL_LEVEL_ID
		or not install_tutorial_completed
		or install_order.is_empty()
	):
		return Vector2i(-1, -1)

	var block_index: int = find_block_index_by_id(install_order[0])
	if block_index == -1:
		return Vector2i(-1, -1)
	var block: Dictionary = blocks[block_index]
	if String(block["vector"]) == "":
		return Vector2i(-1, -1)
	return Vector2i(block["cell"])


func capture_board_snapshot() -> BoardSnapshot:
	var snapshot := BoardSnapshot.new()
	snapshot.player_cell = player_cell
	snapshot.player_queue = player_queue
	snapshot.facing_direction = facing_direction
	snapshot.facing_name = facing_name
	snapshot.level_completed = level_completed

	for block in blocks:
		var block_copy: Dictionary = block.duplicate(true)
		snapshot.blocks.append(block_copy)
	for block_id in install_order:
		snapshot.install_order.append(block_id)
	for command in command_history:
		snapshot.command_history.append(command)

	return snapshot


func restore_board_snapshot(snapshot: BoardSnapshot) -> void:
	player_cell = snapshot.player_cell
	player_queue = snapshot.player_queue
	facing_direction = snapshot.facing_direction
	facing_name = snapshot.facing_name
	level_completed = snapshot.level_completed

	blocks.clear()
	for block in snapshot.blocks:
		var block_copy: Dictionary = block.duplicate(true)
		blocks.append(block_copy)

	install_order.clear()
	for block_id in snapshot.install_order:
		install_order.append(block_id)

	command_history.clear()
	for command in snapshot.command_history:
		command_history.append(command)
	reset_completion_feedback()


func duplicate_initial_blocks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for block in initial_blocks:
		result.append(block.duplicate(true))

	return result


func load_initial_level() -> bool:
	if Campaign.has_active_level():
		var campaign_source := Campaign.active_level_source()
		if campaign_source == "":
			push_error("Unable to load campaign level: %s" % Campaign.active_level_id)
			return false

		var campaign_error := set_level_from_text(campaign_source)
		if campaign_error != "":
			push_error("Invalid campaign level %s: %s" % [Campaign.active_level_id, campaign_error])
			return false
		return true

	var level_file := FileAccess.open(INITIAL_LEVEL_PATH, FileAccess.READ)
	if level_file == null:
		push_error("Unable to open level file: %s" % INITIAL_LEVEL_PATH)
		return false

	var error := set_level_from_text(level_file.get_as_text())
	if error != "":
		push_error("Invalid level file %s: %s" % [INITIAL_LEVEL_PATH, error])
		return false

	return true


func replace_level_from_text(source: String) -> String:
	var error := set_level_from_text(source)
	if error != "":
		return error

	reset_level()
	return ""


func set_level_from_text(source: String) -> String:
	var level_data := AsciiMapParser.parse(source)
	if level_data.has("error"):
		return str(level_data["error"])

	level_source_text = source
	terrain = level_data["terrain"]
	initial_player_cell = level_data["player_cell"]
	initial_blocks = level_data["blocks"]
	goal_cells = level_data["goal_cells"]
	horizontal_edges = level_data["horizontal_edges"]
	vertical_edges = level_data["vertical_edges"]
	static_dead_cells = calculate_static_dead_cells()
	player_cell = initial_player_cell
	blocks = duplicate_initial_blocks()
	face_nearest_initial_block()
	return ""


func face_nearest_initial_block() -> void:
	facing_direction = Vector2i.RIGHT
	facing_name = "Right"
	if blocks.is_empty():
		return

	var nearest_cell: Vector2i = Vector2i(blocks[0]["cell"])
	var nearest_distance: int = manhattan_distance(player_cell, nearest_cell)
	for block_index in range(1, blocks.size()):
		var block_cell: Vector2i = Vector2i(blocks[block_index]["cell"])
		var block_distance: int = manhattan_distance(player_cell, block_cell)
		if block_distance < nearest_distance:
			nearest_cell = block_cell
			nearest_distance = block_distance

	var delta: Vector2i = nearest_cell - player_cell
	if absi(delta.x) >= absi(delta.y) and delta.x != 0:
		facing_direction = Vector2i(signi(delta.x), 0)
	elif delta.y != 0:
		facing_direction = Vector2i(0, signi(delta.y))
	facing_name = direction_name_from_vector(facing_direction)


func manhattan_distance(from_cell: Vector2i, to_cell: Vector2i) -> int:
	var delta: Vector2i = to_cell - from_cell
	return absi(delta.x) + absi(delta.y)


func calculate_static_dead_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(terrain.size()):
		for x in range(terrain[y].size()):
			var cell := Vector2i(x, y)
			if is_wall(cell):
				continue
			var can_be_pushed := false
			for direction in CARDINAL_DIRECTIONS:
				var destination: Vector2i = cell + direction
				var support: Vector2i = cell - direction
				if (
					static_cell_is_open(destination)
					and static_cell_is_open(support)
					and not is_fence_between(cell, destination)
					and not is_fence_between(support, cell)
				):
					can_be_pushed = true
					break
			if not can_be_pushed:
				result.append(cell)
	return result


func static_cell_is_open(cell: Vector2i) -> bool:
	return is_inside_board(cell) and not is_wall(cell)


func tutorial_undo_deadlock_cell() -> Vector2i:
	if (
		Campaign.active_level_id != INSTALL_TUTORIAL_LEVEL_ID
		or level_completed
		or not install_order.is_empty()
	):
		return Vector2i(-1, -1)

	for block in blocks:
		if String(block["vector"]) != "":
			return Vector2i(-1, -1)
	for block in blocks:
		var cell: Vector2i = block["cell"]
		if (
			not goal_cells.has(cell)
			and static_dead_cells.has(cell)
			and not player_queue_can_release_block(cell)
		):
			return cell
	return Vector2i(-1, -1)


func player_queue_can_release_block(cell: Vector2i) -> bool:
	if player_queue == "":
		return false
	var direction: Vector2i = direction_from_name(player_queue)
	return direction != Vector2i.ZERO and can_block_move_to(cell, cell + direction)


func enqueue_player_queue(direction_name: String) -> String:
	player_queue = direction_name
	return "Queue set to %s." % direction_name


func consume_carrier_vector(carrier_index: int, carrier: Dictionary) -> void:
	carrier["vector"] = ""
	blocks[carrier_index] = carrier
	install_order.remove_at(0)


func consume_blocked_trigger(
	carrier_index: int,
	carrier: Dictionary,
	message: String,
	log_line: String
) -> void:
	var carrier_id: int = int(carrier["id"])
	var vector_name: String = String(carrier["vector"])
	var carrier_cell: Vector2i = carrier["cell"]
	consume_carrier_vector(carrier_index, carrier)
	set_message(message)
	append_debug_log(log_line)
	if start_trigger_displacement(
		carrier_id,
		vector_name,
		carrier_id,
		carrier_cell,
		carrier_cell
	):
		return
	render_all()
	end_atomic_input()


func retrieve_recovery_vector(block_index: int, block: Dictionary) -> void:
	var vector_name: String = block["vector"]
	block["vector"] = ""
	blocks[block_index] = block
	install_order.erase(block["id"])
	player_queue = vector_name

	set_message("Retrieved %s from recovery block %s." % [vector_name, block_label(block["id"])])
	append_debug_log("Retrieve: %s <- block %s; order %s." % [
		vector_name,
		block_label(block["id"]),
		install_order_text(),
	])
	render_all()


func is_recovery_block(block: Dictionary) -> bool:
	return block.get("kind", AsciiMapParser.BLOCK_KIND_NORMAL) == AsciiMapParser.BLOCK_KIND_RECOVERY


func is_level_solved() -> bool:
	if goal_cells.is_empty():
		return false

	for goal_cell in goal_cells:
		if find_block_index_at(goal_cell) == -1:
			return false

	return true


func check_level_completion() -> bool:
	if level_completed or not is_level_solved():
		return false
	return finish_level_completion(
		"Complete: all %s goals contain blocks." % goal_cells.size()
	)


func complete_level_for_testing() -> bool:
	if level_completed:
		return false
	begin_atomic_input()
	var completed := finish_level_completion("Complete (F4): marked for testing.")
	end_atomic_input()
	return completed


func finish_level_completion(completion_log: String) -> bool:
	level_completed = true
	play_completion_feedback()
	if Campaign.has_active_level():
		Campaign.complete_active_level()
	var input_result := command_history_text()
	set_message("Level complete. Press F5 to reset.")
	append_debug_log(completion_log)
	append_debug_log("Input result (%s): %s" % [
		command_history.size(),
		"(empty)" if input_result == "" else input_result,
	])
	var result_prefix := "Input result"
	if Campaign.has_active_level():
		result_prefix = "Level complete. Enter: return to map. Input result"
	game_hud.show_result("%s (%s): %s" % [
		result_prefix,
		command_history.size(),
		"(empty)" if input_result == "" else input_result,
	])
	return true


func play_completion_feedback() -> void:
	if board_view != null and board_view.has_method("play_completion_feedback"):
		board_view.play_completion_feedback()


func play_completion_sound_feedback() -> void:
	if audio_feedback != null:
		audio_feedback.play_completion()


func reset_completion_feedback() -> void:
	if board_view != null and board_view.has_method("reset_completion_feedback"):
		board_view.reset_completion_feedback()


func can_block_move_to(from: Vector2i, cell: Vector2i) -> bool:
	return not is_fence_between(from, cell) and is_inside_board(cell) and not is_wall(cell) and find_block_index_at(cell) == -1 and cell != player_cell


func is_cell_walkable_for_player(from: Vector2i, cell: Vector2i) -> bool:
	return not is_fence_between(from, cell) and is_inside_board(cell) and not is_wall(cell)


func is_fence_between(from: Vector2i, to: Vector2i) -> bool:
	if not is_inside_board(from) or not is_inside_board(to):
		return true

	var delta := to - from
	if delta == Vector2i.RIGHT:
		return vertical_edges[from.y][from.x]
	if delta == Vector2i.LEFT:
		return vertical_edges[from.y][to.x]
	if delta == Vector2i.DOWN:
		return horizontal_edges[from.y][from.x]
	if delta == Vector2i.UP:
		return horizontal_edges[to.y][from.x]
	return true


func is_inside_board(cell: Vector2i) -> bool:
	return cell.y >= 0 and cell.y < terrain.size() and cell.x >= 0 and cell.x < terrain[cell.y].size()


func is_wall(cell: Vector2i) -> bool:
	return terrain[cell.y][cell.x] == WALL


func find_block_index_at(cell: Vector2i) -> int:
	for index in range(blocks.size()):
		if blocks[index]["cell"] == cell:
			return index

	return -1


func find_block_index_by_id(block_id: int) -> int:
	for index in range(blocks.size()):
		if blocks[index]["id"] == block_id:
			return index

	return -1


func render_all() -> void:
	if board_view != null:
		board_view.render()
	update_hud()


func play_facing_action() -> void:
	if board_view != null and board_view.has_method("play_facing_action"):
		board_view.play_facing_action()


func start_install_reveal(block_id: int) -> bool:
	if board_view == null or not board_view.has_method("play_install_reveal"):
		return false

	board_view.play_install_reveal(
		block_id,
		Callable(self, "finish_install_action")
	)
	return true


func finish_install_action() -> void:
	render_all()
	end_atomic_input()


func start_player_displacement(
	from_cell: Vector2i,
	to_cell: Vector2i
) -> bool:
	if board_view == null or not board_view.has_method("play_player_displacement"):
		return false

	board_view.play_player_displacement(
		from_cell,
		to_cell,
		Callable(self, "finish_displacement_action").bind(false)
	)
	return true


func start_block_displacement(
	block_id: int,
	from_cell: Vector2i,
	to_cell: Vector2i,
	player_queue_changed: bool
) -> bool:
	if board_view == null or not board_view.has_method("play_block_displacement"):
		return false

	board_view.play_block_displacement(
		block_id,
		from_cell,
		to_cell,
		player_queue_changed,
		Callable(self, "finish_displacement_action").bind(true)
	)
	return true


func start_trigger_displacement(
	carrier_id: int,
	direction_name: String,
	moving_block_id: int,
	from_cell: Vector2i,
	to_cell: Vector2i
) -> bool:
	if board_view == null or not board_view.has_method("play_trigger_displacement"):
		return false

	board_view.play_trigger_displacement(
		carrier_id,
		direction_name,
		moving_block_id,
		from_cell,
		to_cell,
		Callable(self, "finish_displacement_action").bind(true)
	)
	return true


func start_player_hint_feedback() -> void:
	play_interact_hint_feedback()
	if board_view == null or not board_view.has_method("play_player_hint_flash"):
		return
	board_view.play_player_hint_flash(player_cell)


func start_block_error_feedback(block_cell: Vector2i) -> void:
	play_error_red_feedback()
	if board_view == null or not board_view.has_method("play_block_error_flash"):
		return
	board_view.play_block_error_flash(block_cell)


func play_error_red_feedback() -> void:
	if audio_feedback != null:
		audio_feedback.play_error_red()


func start_block_hint_feedback(block_cell: Vector2i) -> void:
	play_interact_hint_feedback()
	if board_view == null or not board_view.has_method("play_block_hint_flash"):
		return
	board_view.play_block_hint_flash(block_cell)


func play_interact_hint_feedback() -> void:
	if audio_feedback != null:
		audio_feedback.play_interact_hint()


func play_trigger_activation_feedback() -> void:
	if audio_feedback != null:
		audio_feedback.play_trigger_activation()


func play_install_feedback() -> void:
	if audio_feedback != null:
		audio_feedback.play_install()


func play_turn_feedback() -> void:
	if audio_feedback != null:
		audio_feedback.play_turn()


func play_block_push_feedback() -> void:
	if audio_feedback != null:
		audio_feedback.play_block_push()


func play_release_dissipate_feedback() -> void:
	if audio_feedback != null:
		audio_feedback.play_release_dissipate()


func play_collision_impact_feedback() -> void:
	if audio_feedback != null:
		audio_feedback.play_collision_impact()


func play_player_move_feedback() -> void:
	if audio_feedback != null:
		audio_feedback.play_player_move()


func finish_displacement_action(check_completion: bool) -> void:
	if check_completion:
		check_level_completion()
	render_all()
	end_atomic_input()


func cancel_board_displacement() -> void:
	if board_view != null and board_view.has_method("cancel_displacement"):
		board_view.cancel_displacement()


func update_hud() -> void:
	if game_hud != null:
		game_hud.refresh()
	if debug_panel != null:
		debug_panel.refresh()


func set_debug_panel_position(panel_position: Vector2) -> void:
	if debug_panel != null:
		debug_panel.position = panel_position


func append_debug_log(line: String) -> void:
	debug_lines.append(line)
	print("[DIR] %s" % line)
	while debug_lines.size() > MAX_DEBUG_LINES:
		debug_lines.remove_at(0)


func debug_state_text() -> String:
	var lines: Array[String] = []
	lines.append("Player: %s" % cell_text(player_cell))
	lines.append("Facing: %s" % facing_name)
	lines.append("Queue: %s" % ("None" if player_queue == "" else player_queue))
	lines.append("Install order: %s" % install_order_text())
	lines.append("Inputs: %s" % command_history.size())
	lines.append("Completed: %s" % ("Yes" if level_completed else "No"))
	lines.append("")
	for block in blocks:
		lines.append("%s: kind=%s cell=%s vector=%s" % [
			block_label(block["id"]),
			block.get("kind", AsciiMapParser.BLOCK_KIND_NORMAL),
			cell_text(block["cell"]),
			"None" if block["vector"] == "" else block["vector"],
		])

	return join_strings(lines, "\n")


func install_order_text() -> String:
	if install_order.is_empty():
		return "[]"

	var labels: Array[String] = []
	for block_id in install_order:
		labels.append(block_label(block_id))

	return "[%s]" % join_strings(labels, ", ")


func block_label(block_id) -> String:
	match block_id:
		1:
			return "A"
		2:
			return "B"
		3:
			return "C"
		_:
			return str(block_id)


func join_strings(lines: Array[String], separator: String) -> String:
	var result := ""
	for index in range(lines.size()):
		if index > 0:
			result += separator
		result += lines[index]

	return result


func command_history_text() -> String:
	return join_strings(command_history, "")


func set_message(text: String) -> void:
	if game_hud != null:
		game_hud.set_message(text)


func begin_atomic_input() -> void:
	cancel_board_displacement()
	input_locked = true


func end_atomic_input() -> void:
	input_locked = false
	update_hud()


func cell_text(cell) -> String:
	return "(%d, %d)" % [cell.x, cell.y]


func direction_from_name(direction_name: String) -> Vector2i:
	match direction_name:
		"Up":
			return Vector2i.UP
		"Down":
			return Vector2i.DOWN
		"Left":
			return Vector2i.LEFT
		"Right":
			return Vector2i.RIGHT
		_:
			return Vector2i.ZERO


func direction_name_from_vector(direction: Vector2i) -> String:
	if direction == Vector2i.UP:
		return "Up"
	if direction == Vector2i.DOWN:
		return "Down"
	if direction == Vector2i.LEFT:
		return "Left"
	return "Right"
