class_name LevelThumbnailRenderer
extends RefCounted

const CONTENT_RATIO := 0.80
const FLOOR_LIGHTEN_AMOUNT := 0.08
const GOAL_SIZE_RATIO := 0.48
const BLOCK_SIZE_RATIO := 0.58
const COMPLETED_OUTLINE_SIZE_RATIO := 0.68
const FENCE_END_INSET_RATIO := 0.20


static func draw(
	canvas: CanvasItem,
	level_data: Dictionary,
	rect: Rect2,
	palette: Dictionary,
	alpha: float = 1.0,
	completed: bool = false
) -> void:
	if level_data.is_empty():
		return
	var terrain: Array = level_data["terrain"]
	if terrain.is_empty() or terrain[0].is_empty():
		return

	var layout: Dictionary = layout_for(level_data, rect)
	var origin: Vector2 = layout["origin"]
	var cell_size: float = float(layout["cell_size"])
	draw_terrain(canvas, terrain, origin, cell_size, palette, alpha)
	draw_goals(canvas, level_data["goal_cells"], origin, cell_size, palette, alpha)
	var block_cells: Array[Vector2i] = block_cells_for(level_data, completed)
	draw_blocks(canvas, block_cells, origin, cell_size, palette, alpha)
	if completed:
		draw_completed_outlines(
			canvas,
			block_cells,
			origin,
			cell_size,
			palette,
			alpha
		)
	draw_fences(canvas, level_data, origin, cell_size, palette, alpha)


static func block_cells_for(level_data: Dictionary, completed: bool) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if completed:
		for goal_value in level_data["goal_cells"]:
			result.append(Vector2i(goal_value))
		return result
	for block_value in level_data["blocks"]:
		var block: Dictionary = block_value
		result.append(Vector2i(block["cell"]))
	return result


static func layout_for(level_data: Dictionary, rect: Rect2) -> Dictionary:
	var terrain: Array = level_data["terrain"]
	var height: int = terrain.size()
	var first_row: Array = terrain[0]
	var width: int = first_row.size()
	var available_size: Vector2 = rect.size * CONTENT_RATIO
	var cell_size: float = floorf(minf(
		available_size.x / float(width),
		available_size.y / float(height)
	))
	cell_size = maxf(1.0, cell_size)
	var board_size: Vector2 = Vector2(float(width), float(height)) * cell_size
	return {
		"origin": rect.get_center() - board_size * 0.5,
		"cell_size": cell_size,
		"board_size": board_size,
	}


static func draw_terrain(
	canvas: CanvasItem,
	terrain: Array,
	origin: Vector2,
	cell_size: float,
	palette: Dictionary,
	alpha: float
) -> void:
	var gap := maxf(1.0, floorf(cell_size * 0.04))
	var floor_color: Color = with_alpha(
		Color(palette["floor"]).lightened(FLOOR_LIGHTEN_AMOUNT),
		alpha
	)
	var wall_color: Color = with_alpha(palette["wall"], alpha)
	for y in range(terrain.size()):
		var row: Array = terrain[y]
		for x in range(row.size()):
			var cell_rect := Rect2(
				origin + Vector2(x, y) * cell_size + Vector2.ONE * gap * 0.5,
				Vector2.ONE * (cell_size - gap)
			)
			canvas.draw_rect(cell_rect, wall_color if int(row[x]) == 1 else floor_color)


static func draw_goals(
	canvas: CanvasItem,
	goal_cells: Array,
	origin: Vector2,
	cell_size: float,
	palette: Dictionary,
	alpha: float
) -> void:
	var color: Color = with_alpha(palette["goal"], alpha)
	var line_width := maxf(1.0, cell_size * 0.07)
	for goal_value in goal_cells:
		var cell: Vector2i = goal_value
		var goal_rect := centered_cell_rect(
			cell,
			origin,
			cell_size,
			GOAL_SIZE_RATIO
		)
		canvas.draw_rect(goal_rect, color, false, line_width)


static func draw_blocks(
	canvas: CanvasItem,
	block_cells: Array[Vector2i],
	origin: Vector2,
	cell_size: float,
	palette: Dictionary,
	alpha: float
) -> void:
	var color: Color = with_alpha(palette["block"], alpha)
	for cell in block_cells:
		canvas.draw_rect(
			centered_cell_rect(cell, origin, cell_size, BLOCK_SIZE_RATIO),
			color
		)


static func draw_completed_outlines(
	canvas: CanvasItem,
	block_cells: Array[Vector2i],
	origin: Vector2,
	cell_size: float,
	palette: Dictionary,
	alpha: float
) -> void:
	var color: Color = with_alpha(palette["goal_complete"], alpha)
	var line_width := maxf(1.0, cell_size * 0.06)
	for cell in block_cells:
		canvas.draw_rect(
			centered_cell_rect(
				cell,
				origin,
				cell_size,
				COMPLETED_OUTLINE_SIZE_RATIO
			),
			color,
			false,
			line_width
		)


static func draw_fences(
	canvas: CanvasItem,
	level_data: Dictionary,
	origin: Vector2,
	cell_size: float,
	palette: Dictionary,
	alpha: float
) -> void:
	var color: Color = with_alpha(palette["post_top"], alpha)
	var line_width := maxf(2.0, cell_size * 0.09)
	var inset := cell_size * FENCE_END_INSET_RATIO
	var horizontal_edges: Array = level_data["horizontal_edges"]
	for y in range(horizontal_edges.size()):
		var row: Array = horizontal_edges[y]
		for x in range(row.size()):
			if not bool(row[x]):
				continue
			var edge_y := origin.y + float(y + 1) * cell_size
			canvas.draw_line(
				Vector2(origin.x + float(x) * cell_size + inset, edge_y),
				Vector2(origin.x + float(x + 1) * cell_size - inset, edge_y),
				color,
				line_width
			)

	var vertical_edges: Array = level_data["vertical_edges"]
	for y in range(vertical_edges.size()):
		var row: Array = vertical_edges[y]
		for x in range(row.size()):
			if not bool(row[x]):
				continue
			var edge_x := origin.x + float(x + 1) * cell_size
			canvas.draw_line(
				Vector2(edge_x, origin.y + float(y) * cell_size + inset),
				Vector2(edge_x, origin.y + float(y + 1) * cell_size - inset),
				color,
				line_width
			)


static func centered_cell_rect(
	cell: Vector2i,
	origin: Vector2,
	cell_size: float,
	size_ratio: float
) -> Rect2:
	var size := Vector2.ONE * cell_size * size_ratio
	return Rect2(cell_center(cell, origin, cell_size) - size * 0.5, size)


static func cell_center(cell: Vector2i, origin: Vector2, cell_size: float) -> Vector2:
	return origin + (Vector2(cell) + Vector2.ONE * 0.5) * cell_size


static func with_alpha(color_value, alpha: float) -> Color:
	var color: Color = color_value
	color.a *= clampf(alpha, 0.0, 1.0)
	return color
