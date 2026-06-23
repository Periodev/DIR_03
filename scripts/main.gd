extends Node2D

const CELL_SIZE := 48
const CELL_GAP := 4
const BOARD_OFFSET := Vector2(96, 96)

const FLOOR_COLOR := Color(0.16, 0.18, 0.22)
const WALL_COLOR := Color(0.06, 0.07, 0.09)
const BLOCK_COLOR := Color(0.86, 0.56, 0.22)
const PLAYER_COLOR := Color(0.25, 0.62, 1.0)
const GRID_LINE_COLOR := Color(0.32, 0.35, 0.40)

const EMPTY := 0
const WALL := 1

var terrain: Array[Array] = [
	[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 1, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
	[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

var player_cell := Vector2i(2, 3)
var block_cells: Array[Vector2i] = [
	Vector2i(4, 4),
	Vector2i(6, 2),
	Vector2i(3, 5),
]
var momentum_slot := ""

var board_layer: Node2D
var object_layer: Node2D
var hud_layer: CanvasLayer
var momentum_label: Label
var message_label: Label


func _ready() -> void:
	board_layer = Node2D.new()
	board_layer.name = "BoardLayer"
	add_child(board_layer)

	object_layer = Node2D.new()
	object_layer.name = "ObjectLayer"
	add_child(object_layer)

	hud_layer = CanvasLayer.new()
	hud_layer.name = "HudLayer"
	add_child(hud_layer)

	momentum_label = Label.new()
	momentum_label.position = Vector2(96, 24)
	momentum_label.add_theme_font_size_override("font_size", 24)
	hud_layer.add_child(momentum_label)

	message_label = Label.new()
	message_label.position = Vector2(96, 54)
	message_label.add_theme_font_size_override("font_size", 16)
	hud_layer.add_child(message_label)

	message_label.text = "Arrow keys: move. Push a block to absorb momentum. Empty movement does not change momentum."
	render_all()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		try_move(Vector2i.UP, "Up")
	elif event.is_action_pressed("move_down"):
		try_move(Vector2i.DOWN, "Down")
	elif event.is_action_pressed("move_left"):
		try_move(Vector2i.LEFT, "Left")
	elif event.is_action_pressed("move_right"):
		try_move(Vector2i.RIGHT, "Right")


func try_move(direction: Vector2i, direction_name: String) -> void:
	var target := player_cell + direction

	if not is_inside_board(target) or is_wall(target):
		message_label.text = "Blocked by wall. Momentum unchanged."
		return

	var block_index := block_cells.find(target)
	if block_index == -1:
		player_cell = target
		message_label.text = "Moved through empty space. Momentum unchanged."
		render_all()
		return

	var block_target := target + direction
	if not can_block_move_to(block_target):
		message_label.text = "Push failed. Momentum unchanged."
		return

	block_cells[block_index] = block_target
	player_cell = target
	momentum_slot = direction_name
	message_label.text = "Successful push. Absorbed momentum: %s." % direction_name
	render_all()


func can_block_move_to(cell: Vector2i) -> bool:
	return is_inside_board(cell) and not is_wall(cell) and block_cells.find(cell) == -1


func is_inside_board(cell: Vector2i) -> bool:
	return cell.y >= 0 and cell.y < terrain.size() and cell.x >= 0 and cell.x < terrain[cell.y].size()


func is_wall(cell: Vector2i) -> bool:
	return terrain[cell.y][cell.x] == WALL


func render_all() -> void:
	clear_children(board_layer)
	clear_children(object_layer)
	draw_board()
	draw_blocks()
	draw_player()
	update_hud()


func draw_board() -> void:
	for y in terrain.size():
		for x in terrain[y].size():
			var cell := Vector2i(x, y)
			var color := WALL_COLOR if terrain[y][x] == WALL else FLOOR_COLOR
			add_rect(board_layer, cell_to_position(cell), Vector2(CELL_SIZE, CELL_SIZE), color)
			add_rect_outline(board_layer, cell_to_position(cell), Vector2(CELL_SIZE, CELL_SIZE), GRID_LINE_COLOR)


func draw_blocks() -> void:
	for cell in block_cells:
		add_rect(object_layer, cell_to_position(cell) + Vector2(CELL_GAP, CELL_GAP), Vector2(CELL_SIZE - CELL_GAP * 2, CELL_SIZE - CELL_GAP * 2), BLOCK_COLOR)
		add_centered_label(object_layer, cell, "B", Color.WHITE, 22)


func draw_player() -> void:
	add_rect(object_layer, cell_to_position(player_cell) + Vector2(CELL_GAP, CELL_GAP), Vector2(CELL_SIZE - CELL_GAP * 2, CELL_SIZE - CELL_GAP * 2), PLAYER_COLOR)
	add_centered_label(object_layer, player_cell, "P", Color.WHITE, 22)

	if momentum_slot != "":
		var arrow := momentum_arrow(momentum_slot)
		var arrow_label := Label.new()
		arrow_label.text = arrow
		arrow_label.add_theme_font_size_override("font_size", 24)
		arrow_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.35))
		arrow_label.position = cell_to_position(player_cell) + Vector2(15, -28)
		object_layer.add_child(arrow_label)


func update_hud() -> void:
	var momentum_text := "None" if momentum_slot == "" else momentum_slot
	momentum_label.text = "Momentum: %s" % momentum_text


func add_rect(parent: Node, position: Vector2, size: Vector2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.position = position
	rect.size = size
	rect.color = color
	parent.add_child(rect)


func add_rect_outline(parent: Node, position: Vector2, size: Vector2, color: Color) -> void:
	var top := ColorRect.new()
	top.position = position
	top.size = Vector2(size.x, 1)
	top.color = color
	parent.add_child(top)

	var left := ColorRect.new()
	left.position = position
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
