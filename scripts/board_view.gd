class_name Dir3BoardView
extends Node2D

const VisualStyle = preload("res://scripts/visual_style.gd")

var game_board
var board_layer: Node2D
var object_layer: Node2D


func initialize(board) -> void:
	game_board = board
	name = "BoardView"

	board_layer = Node2D.new()
	board_layer.name = "BoardLayer"
	add_child(board_layer)

	object_layer = Node2D.new()
	object_layer.name = "ObjectLayer"
	add_child(object_layer)


func render() -> void:
	clear_children(board_layer)
	clear_children(object_layer)
	draw_board()
	draw_blocks()
	draw_player()


func draw_board() -> void:
	for y in range(game_board.terrain.size()):
		for x in range(game_board.terrain[y].size()):
			var cell := Vector2i(x, y)
			var color := VisualStyle.WALL_COLOR if game_board.terrain[y][x] == game_board.WALL else VisualStyle.FLOOR_COLOR
			add_rect(board_layer, cell_to_position(cell), Vector2(VisualStyle.CELL_SIZE, VisualStyle.CELL_SIZE), color)
			add_rect_outline(board_layer, cell_to_position(cell), Vector2(VisualStyle.CELL_SIZE, VisualStyle.CELL_SIZE), VisualStyle.GRID_LINE_COLOR)
			if game_board.goal_cells.has(cell):
				add_centered_label(board_layer, cell, "*", VisualStyle.GOAL_MARKER_COLOR, 36)
	draw_fences()


func draw_fences() -> void:
	for y in range(game_board.horizontal_edges.size()):
		for x in range(game_board.horizontal_edges[y].size()):
			if game_board.horizontal_edges[y][x]:
				var horizontal_position := cell_to_position(Vector2i(x, y)) + Vector2(
					0,
					VisualStyle.CELL_SIZE - VisualStyle.FENCE_THICKNESS / 2.0
				)
				add_rect(
					board_layer,
					horizontal_position,
					Vector2(VisualStyle.CELL_SIZE, VisualStyle.FENCE_THICKNESS),
					VisualStyle.FENCE_COLOR
				)

	for y in range(game_board.vertical_edges.size()):
		for x in range(game_board.vertical_edges[y].size()):
			if game_board.vertical_edges[y][x]:
				var vertical_position := cell_to_position(Vector2i(x, y)) + Vector2(
					VisualStyle.CELL_SIZE - VisualStyle.FENCE_THICKNESS / 2.0,
					0
				)
				add_rect(
					board_layer,
					vertical_position,
					Vector2(VisualStyle.FENCE_THICKNESS, VisualStyle.CELL_SIZE),
					VisualStyle.FENCE_COLOR
				)


func draw_blocks() -> void:
	for block in game_board.blocks:
		var cell: Vector2i = block["cell"]
		var vector_name: String = block["vector"]
		var recovery_block: bool = game_board.is_recovery_block(block)
		var color := VisualStyle.BLOCK_COLOR
		if recovery_block:
			color = (
				VisualStyle.INSTALLED_RECOVERY_BLOCK_COLOR
				if vector_name != ""
				else VisualStyle.RECOVERY_BLOCK_COLOR
			)
		elif vector_name != "":
			color = VisualStyle.INSTALLED_BLOCK_COLOR

		if game_board.goal_cells.has(cell):
			add_rect(
				object_layer,
				cell_to_position(cell) + Vector2(4, 4),
				Vector2(VisualStyle.CELL_SIZE - 8, VisualStyle.CELL_SIZE - 8),
				VisualStyle.GOAL_BLOCK_BORDER_COLOR
			)
		add_rect(
			object_layer,
			cell_to_position(cell) + Vector2(VisualStyle.CELL_GAP, VisualStyle.CELL_GAP),
			Vector2(
				VisualStyle.CELL_SIZE - VisualStyle.CELL_GAP * 2,
				VisualStyle.CELL_SIZE - VisualStyle.CELL_GAP * 2
			),
			color
		)
		if recovery_block:
			add_recovery_marker(cell)
		if vector_name != "":
			add_centered_label(
				object_layer,
				cell,
				momentum_arrow(vector_name),
				Color(1.0, 0.94, 0.35),
				VisualStyle.INSTALLED_VECTOR_FONT_SIZE
			)


func add_recovery_marker(cell: Vector2i) -> void:
	var marker := Label.new()
	marker.text = "↺"
	marker.add_theme_font_size_override("font_size", 20)
	marker.add_theme_color_override("font_color", Color.WHITE)
	marker.position = cell_to_position(cell) + Vector2(VisualStyle.CELL_SIZE - 34, 8)
	object_layer.add_child(marker)


func draw_player() -> void:
	add_rect(
		object_layer,
		cell_to_position(game_board.player_cell) + Vector2(
			VisualStyle.CELL_GAP,
			VisualStyle.CELL_GAP
		),
		Vector2(
			VisualStyle.CELL_SIZE - VisualStyle.CELL_GAP * 2,
			VisualStyle.CELL_SIZE - VisualStyle.CELL_GAP * 2
		),
		VisualStyle.PLAYER_COLOR
	)
	var player_text := (
		"@"
		if game_board.player_queue == ""
		else "@%s" % momentum_arrow(game_board.player_queue)
	)
	add_centered_label(
		object_layer,
		game_board.player_cell,
		player_text,
		Color.WHITE,
		22
	)

	var facing_label := Label.new()
	facing_label.text = momentum_arrow(game_board.facing_name)
	facing_label.add_theme_font_size_override("font_size", 20)
	facing_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	facing_label.position = cell_to_position(game_board.player_cell) + Vector2(16, -24)
	object_layer.add_child(facing_label)


func add_rect(parent: Node, rect_position: Vector2, size: Vector2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.position = rect_position
	rect.size = size
	rect.color = color
	parent.add_child(rect)


func add_rect_outline(
	parent: Node,
	rect_position: Vector2,
	size: Vector2,
	color: Color
) -> void:
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


func add_centered_label(
	parent: Node,
	cell: Vector2i,
	text: String,
	color: Color,
	font_size: int
) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.position = cell_to_position(cell)
	label.size = Vector2(VisualStyle.CELL_SIZE, VisualStyle.CELL_SIZE)
	parent.add_child(label)


func cell_to_position(cell: Vector2i) -> Vector2:
	return VisualStyle.BOARD_OFFSET + Vector2(
		cell.x * VisualStyle.CELL_SIZE,
		cell.y * VisualStyle.CELL_SIZE
	)


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
