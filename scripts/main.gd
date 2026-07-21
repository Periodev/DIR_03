extends Node2D

const AsciiMapParser = preload("res://scripts/ascii_map.gd")

const CELL_SIZE := 96
const CELL_GAP := 8
const BOARD_OFFSET := Vector2(96, 96)
const DEBUG_PANEL_POSITION := Vector2(1090, 96)
const MAX_DEBUG_LINES := 10
const INSTALLED_VECTOR_FONT_SIZE := 48

const FLOOR_COLOR := Color(0.16, 0.18, 0.22)
const WALL_COLOR := Color(0.06, 0.07, 0.09)
const BLOCK_COLOR := Color(0.86, 0.56, 0.22)
const INSTALLED_BLOCK_COLOR := Color(0.95, 0.68, 0.28)
const PLAYER_COLOR := Color(0.25, 0.62, 1.0)
const GOAL_MARKER_COLOR := Color(0.35, 0.95, 0.62)
const GOAL_BLOCK_BORDER_COLOR := Color(0.35, 0.95, 0.62)
const GRID_LINE_COLOR := Color(0.32, 0.35, 0.40)
const FENCE_COLOR := Color(0.96, 0.76, 0.24)
const FENCE_THICKNESS := 6.0
const DEBUG_PANEL_COLOR := Color(0.08, 0.09, 0.11, 0.92)

const EMPTY := 0
const WALL := 1
const INITIAL_LEVEL_PATH := "res://levels/level_01.txt"

var terrain: Array[Array] = []
var initial_player_cell := Vector2i.ZERO
var initial_blocks: Array[Dictionary] = []
var goal_cells: Array[Vector2i] = []
var horizontal_edges: Array[Array] = []
var vertical_edges: Array[Array] = []
var player_cell := Vector2i.ZERO
var player_queue := ""
var facing_direction := Vector2i.RIGHT
var facing_name := "Right"
var input_locked := false

var blocks: Array[Dictionary] = []
var install_order: Array[int] = []
var debug_lines: Array[String] = []

var board_layer: Node2D
var object_layer: Node2D
var hud_layer: CanvasLayer
var message_label: Label
var debug_state_label: Label
var debug_log_label: Label


func _ready() -> void:
	if not load_initial_level():
		return

	board_layer = Node2D.new()
	board_layer.name = "BoardLayer"
	add_child(board_layer)

	object_layer = Node2D.new()
	object_layer.name = "ObjectLayer"
	add_child(object_layer)

	hud_layer = CanvasLayer.new()
	hud_layer.name = "HudLayer"
	add_child(hud_layer)

	message_label = Label.new()
	message_label.position = Vector2(96, 24)
	message_label.add_theme_font_size_override("font_size", 16)
	hud_layer.add_child(message_label)

	add_debug_panel()
	message_label.text = "Arrow keys: move/push. X: install queue to faced block. Space: trigger oldest installed vector."
	append_debug_log("Ready: v1.1 vector queue prototype.")
	render_all()


func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return

	if event.is_action_pressed("move_up"):
		try_move(Vector2i.UP, "Up")
	elif event.is_action_pressed("move_down"):
		try_move(Vector2i.DOWN, "Down")
	elif event.is_action_pressed("move_left"):
		try_move(Vector2i.LEFT, "Left")
	elif event.is_action_pressed("move_right"):
		try_move(Vector2i.RIGHT, "Right")
	elif event.is_action_pressed("install_vector"):
		install_vector()
	elif event.is_action_pressed("trigger_vector"):
		trigger_vector()
	elif event.is_action_pressed("reset_level"):
		reset_level()


func try_move(direction: Vector2i, direction_name: String) -> void:
	begin_atomic_input()
	facing_direction = direction
	facing_name = direction_name
	var target := player_cell + direction

	if not is_cell_walkable_for_player(player_cell, target):
		set_message("Blocked by wall, fence or board edge. Queue unchanged.")
		append_debug_log("Move %s failed: wall, fence or edge." % direction_name)
		end_atomic_input()
		return

	var block_index := find_block_index_at(target)
	if block_index == -1:
		player_cell = target
		set_message("Moved through empty space. Queue unchanged.")
		append_debug_log("Move %s: player -> %s." % [direction_name, cell_text(player_cell)])
		render_all()
		end_atomic_input()
		return

	var block_target := target + direction
	if not can_block_move_to(target, block_target):
		var block_id := int(blocks[block_index]["id"])
		set_message("Push failed. Queue unchanged.")
		append_debug_log("Push %s failed: block %s is blocked." % [direction_name, block_label(block_id)])
		end_atomic_input()
		return

	var pushed_block: Dictionary = blocks[block_index]
	pushed_block["cell"] = block_target
	blocks[block_index] = pushed_block

	enqueue_player_queue(direction_name)
	set_message("Push succeeded. Player stayed in place. Queue is now %s." % direction_name)
	append_debug_log("Push %s: block %s -> %s; %s" % [
		direction_name,
		block_label(pushed_block["id"]),
		cell_text(block_target),
		"queue overwritten",
	])
	render_all()
	end_atomic_input()


func install_vector() -> void:
	begin_atomic_input()
	var target := player_cell + facing_direction

	if player_queue == "":
		set_message("Install failed. Player queue is empty.")
		append_debug_log("Install failed: queue empty.")
		end_atomic_input()
		return

	var block_index := find_block_index_at(target)
	if block_index == -1:
		set_message("Install failed. Face an empty-vector block.")
		append_debug_log("Install %s failed: no block at %s." % [player_queue, cell_text(target)])
		end_atomic_input()
		return

	var block: Dictionary = blocks[block_index]
	if block["vector"] != "":
		set_message("Install failed. Block already has a vector.")
		append_debug_log("Install %s failed: block %s already has %s." % [
			player_queue,
			block_label(block["id"]),
			block["vector"],
		])
		end_atomic_input()
		return

	var installed_vector := player_queue
	block["vector"] = installed_vector
	blocks[block_index] = block
	install_order.append(block["id"])
	player_queue = ""

	set_message("Installed %s on block %s." % [installed_vector, block_label(block["id"])])
	append_debug_log("Install: %s -> block %s; order %s." % [
		installed_vector,
		block_label(block["id"]),
		install_order_text(),
	])
	render_all()
	end_atomic_input()


func trigger_vector() -> void:
	begin_atomic_input()

	if install_order.is_empty():
		set_message("Trigger failed. Install order is empty.")
		append_debug_log("Trigger failed: install order empty.")
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

	var direction := direction_from_name(vector_name)
	var target: Vector2i = carrier["cell"] + direction

	if not is_inside_board(target) or is_wall(target):
		set_message("Trigger failed. Vector points into wall or edge.")
		append_debug_log("Trigger %s failed: block %s faces wall/edge." % [vector_name, block_label(carrier_id)])
		end_atomic_input()
		return
	if is_fence_between(carrier["cell"], target):
		set_message("Trigger failed. Fence blocks the vector.")
		append_debug_log("Trigger %s failed: fence blocks block %s." % [vector_name, block_label(carrier_id)])
		end_atomic_input()
		return

	if target == player_cell:
		set_message("Trigger failed. Player blocks the path.")
		append_debug_log("Trigger %s failed: player blocks block %s." % [vector_name, block_label(carrier_id)])
		end_atomic_input()
		return

	var front_block_index := find_block_index_at(target)
	if front_block_index == -1:
		carrier["cell"] = target
		consume_carrier_vector(carrier_index, carrier)
		set_message("Triggered %s. Block %s moved one cell." % [vector_name, block_label(carrier_id)])
		append_debug_log("Trigger %s: block %s -> %s." % [
			vector_name,
			block_label(carrier_id),
			cell_text(target),
		])
		render_all()
		end_atomic_input()
		return

	var pushed_target := target + direction
	if not can_block_move_to(target, pushed_target):
		set_message("Trigger failed. Anchor-push target is blocked.")
		append_debug_log("Trigger %s failed: block %s cannot push block %s." % [
			vector_name,
			block_label(carrier_id),
			block_label(blocks[front_block_index]["id"]),
		])
		end_atomic_input()
		return

	var pushed_block: Dictionary = blocks[front_block_index]
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
	render_all()
	end_atomic_input()


func reset_level() -> void:
	begin_atomic_input()
	player_cell = initial_player_cell
	player_queue = ""
	facing_direction = Vector2i.RIGHT
	facing_name = "Right"
	blocks = duplicate_initial_blocks()
	install_order.clear()
	debug_lines.clear()
	set_message("Level reset.")
	append_debug_log("Reset: restored initial board, queue, and install order.")
	render_all()
	end_atomic_input()


func duplicate_initial_blocks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for block in initial_blocks:
		result.append(block.duplicate(true))

	return result


func load_initial_level() -> bool:
	var level_file := FileAccess.open(INITIAL_LEVEL_PATH, FileAccess.READ)
	if level_file == null:
		push_error("Unable to open level file: %s" % INITIAL_LEVEL_PATH)
		return false

	var level_data := AsciiMapParser.parse(level_file.get_as_text())
	if level_data.has("error"):
		push_error("Invalid level file %s: %s" % [INITIAL_LEVEL_PATH, level_data["error"]])
		return false

	terrain = level_data["terrain"]
	initial_player_cell = level_data["player_cell"]
	initial_blocks = level_data["blocks"]
	goal_cells = level_data["goal_cells"]
	horizontal_edges = level_data["horizontal_edges"]
	vertical_edges = level_data["vertical_edges"]
	player_cell = initial_player_cell
	blocks = duplicate_initial_blocks()
	return true


func enqueue_player_queue(direction_name: String) -> String:
	player_queue = direction_name
	return "Queue set to %s." % direction_name


func consume_carrier_vector(carrier_index: int, carrier: Dictionary) -> void:
	carrier["vector"] = ""
	blocks[carrier_index] = carrier
	install_order.remove_at(0)


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
	clear_children(board_layer)
	clear_children(object_layer)
	draw_board()
	draw_blocks()
	draw_player()
	update_hud()


func draw_board() -> void:
	for y in range(terrain.size()):
		for x in range(terrain[y].size()):
			var cell := Vector2i(x, y)
			var color := WALL_COLOR if terrain[y][x] == WALL else FLOOR_COLOR
			add_rect(board_layer, cell_to_position(cell), Vector2(CELL_SIZE, CELL_SIZE), color)
			add_rect_outline(board_layer, cell_to_position(cell), Vector2(CELL_SIZE, CELL_SIZE), GRID_LINE_COLOR)
			if goal_cells.has(cell):
				add_centered_label(board_layer, cell, "*", GOAL_MARKER_COLOR, 36)
	draw_fences()


func draw_fences() -> void:
	for y in range(horizontal_edges.size()):
		for x in range(horizontal_edges[y].size()):
			if horizontal_edges[y][x]:
				var horizontal_position := cell_to_position(Vector2i(x, y)) + Vector2(0, CELL_SIZE - FENCE_THICKNESS / 2.0)
				add_rect(board_layer, horizontal_position, Vector2(CELL_SIZE, FENCE_THICKNESS), FENCE_COLOR)

	for y in range(vertical_edges.size()):
		for x in range(vertical_edges[y].size()):
			if vertical_edges[y][x]:
				var vertical_position := cell_to_position(Vector2i(x, y)) + Vector2(CELL_SIZE - FENCE_THICKNESS / 2.0, 0)
				add_rect(board_layer, vertical_position, Vector2(FENCE_THICKNESS, CELL_SIZE), FENCE_COLOR)


func draw_blocks() -> void:
	for block in blocks:
		var cell: Vector2i = block["cell"]
		var vector_name: String = block["vector"]
		var color := INSTALLED_BLOCK_COLOR if vector_name != "" else BLOCK_COLOR
		if goal_cells.has(cell):
			add_rect(object_layer, cell_to_position(cell) + Vector2(4, 4), Vector2(CELL_SIZE - 8, CELL_SIZE - 8), GOAL_BLOCK_BORDER_COLOR)
		add_rect(object_layer, cell_to_position(cell) + Vector2(CELL_GAP, CELL_GAP), Vector2(CELL_SIZE - CELL_GAP * 2, CELL_SIZE - CELL_GAP * 2), color)

		if vector_name != "":
			add_centered_label(object_layer, cell, momentum_arrow(vector_name), Color(1.0, 0.94, 0.35), INSTALLED_VECTOR_FONT_SIZE)


func draw_player() -> void:
	add_rect(object_layer, cell_to_position(player_cell) + Vector2(CELL_GAP, CELL_GAP), Vector2(CELL_SIZE - CELL_GAP * 2, CELL_SIZE - CELL_GAP * 2), PLAYER_COLOR)
	var player_text := "@" if player_queue == "" else "@%s" % momentum_arrow(player_queue)
	add_centered_label(object_layer, player_cell, player_text, Color.WHITE, 22)

	var facing_label := Label.new()
	facing_label.text = momentum_arrow(facing_name)
	facing_label.add_theme_font_size_override("font_size", 20)
	facing_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	facing_label.position = cell_to_position(player_cell) + Vector2(16, -24)
	object_layer.add_child(facing_label)


func update_hud() -> void:
	debug_state_label.text = debug_state_text()
	debug_log_label.text = join_strings(debug_lines, "\n")


func add_debug_panel() -> void:
	var panel := ColorRect.new()
	panel.position = DEBUG_PANEL_POSITION
	panel.size = Vector2(300, 700)
	panel.color = DEBUG_PANEL_COLOR
	hud_layer.add_child(panel)

	var title_label := Label.new()
	title_label.text = "Debug"
	title_label.position = DEBUG_PANEL_POSITION + Vector2(16, 14)
	title_label.add_theme_font_size_override("font_size", 20)
	hud_layer.add_child(title_label)

	debug_state_label = Label.new()
	debug_state_label.position = DEBUG_PANEL_POSITION + Vector2(16, 48)
	debug_state_label.size = Vector2(270, 260)
	debug_state_label.add_theme_font_size_override("font_size", 14)
	hud_layer.add_child(debug_state_label)

	debug_log_label = Label.new()
	debug_log_label.position = DEBUG_PANEL_POSITION + Vector2(16, 320)
	debug_log_label.size = Vector2(270, 360)
	debug_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_log_label.add_theme_font_size_override("font_size", 13)
	hud_layer.add_child(debug_log_label)


func append_debug_log(line: String) -> void:
	debug_lines.append(line)
	print("[DIR3] %s" % line)
	while debug_lines.size() > MAX_DEBUG_LINES:
		debug_lines.remove_at(0)


func debug_state_text() -> String:
	var lines: Array[String] = []
	lines.append("Player: %s" % cell_text(player_cell))
	lines.append("Facing: %s" % facing_name)
	lines.append("Queue: %s" % ("None" if player_queue == "" else player_queue))
	lines.append("Install order: %s" % install_order_text())
	lines.append("")
	for block in blocks:
		lines.append("%s: cell=%s vector=%s" % [
			block_label(block["id"]),
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


func set_message(text: String) -> void:
	message_label.text = text


func begin_atomic_input() -> void:
	input_locked = true


func end_atomic_input() -> void:
	input_locked = false
	update_hud()


func add_rect(parent: Node, rect_position: Vector2, size: Vector2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.position = rect_position
	rect.size = size
	rect.color = color
	parent.add_child(rect)


func add_rect_outline(parent: Node, rect_position: Vector2, size: Vector2, color: Color) -> void:
	var top := ColorRect.new()
	top.position = rect_position
	top.size = Vector2(size.x, 1)
	top.color = color
	parent.add_child(top)

	var left := ColorRect.new()
	left.position = rect_position
	left.size = Vector2(1, size.y)
	left.color = color
	parent.add_child(left)


func add_centered_label(parent: Node, cell: Vector2i, text: String, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.position = cell_to_position(cell)
	label.size = Vector2(CELL_SIZE, CELL_SIZE)
	parent.add_child(label)


func cell_to_position(cell: Vector2i) -> Vector2:
	return BOARD_OFFSET + Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)


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


func momentum_arrow(direction_name: String) -> String:
	match direction_name:
		"Up":
			return "^"
		"Down":
			return "v"
		"Left":
			return "<"
		"Right":
			return ">"
		_:
			return ""


func clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
