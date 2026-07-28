class_name Dir3PlayerBoardView
extends Control

const VisualStyle = preload("res://scripts/visual_style.gd")
const DebugStyle = preload("res://scripts/debug_style.gd")

var game_board
var cell_size := float(VisualStyle.CELL_SIZE)
var light_theme := false
var palette: Dictionary = {}
var fallback_font: Font


func initialize(board) -> void:
	game_board = board
	name = "PlayerBoardView"
	palette = VisualStyle.theme(light_theme)
	fallback_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh_layout_size()


func render() -> void:
	refresh_layout_size()
	queue_redraw()


func set_light_theme(enabled: bool) -> void:
	light_theme = enabled
	palette = VisualStyle.theme(light_theme)
	queue_redraw()


func set_cell_size(value: float) -> void:
	cell_size = maxf(16.0, value)
	refresh_layout_size()
	queue_redraw()


func _draw() -> void:
	if game_board == null or game_board.terrain.is_empty():
		return

	draw_ground()
	draw_wall_shadows()
	draw_walls()

	# Player objects retain the debug look until the next visual pass.
	draw_legacy_goals()
	draw_legacy_blocks()
	draw_fences()
	draw_legacy_player()


func draw_ground() -> void:
	var floor_color: Color = palette["floor"]
	var grid_color: Color = palette["grid"]

	for y in range(game_board.terrain.size()):
		for x in range(game_board.terrain[y].size()):
			var cell := Vector2i(x, y)
			if is_wall_cell(cell):
				continue

			var cell_rect := Rect2(
				cell_to_position(cell),
				Vector2(cell_size, cell_size)
			)
			draw_rect(cell_rect, floor_color)
			draw_rect(cell_rect, grid_color, false, 1.0)


func draw_wall_shadows() -> void:
	for y in range(game_board.terrain.size()):
		for x in range(game_board.terrain[y].size()):
			var cell := Vector2i(x, y)
			if is_wall_cell(cell) and not is_wall_cell(cell + Vector2i.DOWN):
				draw_wall_shadow(cell)


func draw_wall_shadow(cell: Vector2i) -> void:
	var shadow_height := maxi(1, roundi(cell_size * VisualStyle.WALL_SHADOW_RATIO))
	var shadow_color: Color = palette["ground_shadow"]
	var wall_position := cell_to_position(cell)

	for stripe in range(shadow_height):
		var progress := float(stripe) / float(maxi(1, shadow_height - 1))
		var stripe_color := shadow_color
		stripe_color.a *= 1.0 - progress
		draw_rect(
			Rect2(
				wall_position + Vector2(0, cell_size + stripe),
				Vector2(cell_size, 1)
			),
			stripe_color
		)


func draw_walls() -> void:
	for y in range(game_board.terrain.size()):
		for x in range(game_board.terrain[y].size()):
			var cell := Vector2i(x, y)
			if is_wall_cell(cell):
				draw_wall(cell)


func draw_wall(cell: Vector2i) -> void:
	var wall_position := cell_to_position(cell)
	var wall_rect := Rect2(wall_position, Vector2(cell_size, cell_size))
	var bevel := maxi(4, roundi(cell_size * VisualStyle.BEVEL_RATIO))
	var base_extra := scaled_px(2.0)
	var wall_color: Color = palette["wall"]
	var wall_edge: Color = palette["wall_edge"]
	var wall_top: Color = palette["wall_top"]
	var wall_side: Color = palette["wall_side"]
	var wall_base: Color = palette["wall_base"]

	draw_rect(wall_rect, wall_color)
	if VisualStyle.WALL_STYLE == VisualStyle.WALL_STYLE_HATCHED:
		draw_wall_hatch(wall_position)

	if not is_wall_cell(cell + Vector2i.UP):
		draw_rect(
			Rect2(wall_position, Vector2(cell_size, bevel)),
			wall_top
		)
	if not is_wall_cell(cell + Vector2i.LEFT):
		draw_rect(
			Rect2(wall_position, Vector2(bevel, cell_size)),
			wall_side
		)
	if not is_wall_cell(cell + Vector2i.RIGHT):
		draw_rect(
			Rect2(
				wall_position + Vector2(cell_size - bevel, 0),
				Vector2(bevel, cell_size)
			),
			wall_side
		)
	if not is_wall_cell(cell + Vector2i.DOWN):
		var base_height := bevel + base_extra
		draw_rect(
			Rect2(
				wall_position + Vector2(0, cell_size - base_height),
				Vector2(cell_size, base_height)
			),
			wall_base
		)

	draw_rect(wall_rect, wall_edge, false, 1.0)


func draw_wall_hatch(wall_position: Vector2) -> void:
	var hatch_position := wall_position + Vector2.ONE
	var hatch_size := maxf(1.0, cell_size - 2.0)
	var extent := roundi(hatch_size)
	var period := maxi(3, roundi(cell_size * VisualStyle.WALL_HATCH_PERIOD_RATIO))
	var line_width := maxf(1.0, cell_size * VisualStyle.WALL_HATCH_WIDTH_RATIO)
	var hatch_color: Color = palette["wall_hatch"]

	for difference in range(-extent, extent + 1, period):
		var start: Vector2
		var end: Vector2
		if difference >= 0:
			start = hatch_position + Vector2(difference, 0)
			end = hatch_position + Vector2(hatch_size, hatch_size - difference)
		else:
			start = hatch_position + Vector2(0, -difference)
			end = hatch_position + Vector2(hatch_size + difference, hatch_size)
		draw_line(start, end, hatch_color, line_width)


func draw_fences() -> void:
	for y in range(game_board.horizontal_edges.size()):
		for x in range(game_board.horizontal_edges[y].size()):
			if game_board.horizontal_edges[y][x]:
				draw_horizontal_fence(Vector2i(x, y))

	for y in range(game_board.vertical_edges.size()):
		for x in range(game_board.vertical_edges[y].size()):
			if game_board.vertical_edges[y][x]:
				draw_vertical_fence(Vector2i(x, y))


func draw_horizontal_fence(edge: Vector2i) -> void:
	var post_width := maxi(6, roundi(cell_size * VisualStyle.FENCE_POST_W_RATIO))
	var post_gap := maxi(5, roundi(cell_size * VisualStyle.FENCE_POST_GAP_RATIO))
	var thickness := maxi(1, roundi(cell_size * VisualStyle.FENCE_THICKNESS_RATIO))
	var pad := roundi(post_gap / 2.0)
	var seam_y := (edge.y + 1) * cell_size
	var start_x := edge.x * cell_size + pad
	var end_x := (edge.x + 1) * cell_size - pad
	var post_x := start_x

	while post_x < end_x:
		var visible_width := minf(post_width, end_x - post_x)
		draw_horizontal_post(
			Rect2(
				Vector2(post_x, seam_y - thickness / 2.0),
				Vector2(visible_width, thickness)
			)
		)
		post_x += post_width + post_gap


func draw_horizontal_post(rect: Rect2) -> void:
	var top_size := maxi(2, roundi(rect.size.y * VisualStyle.FENCE_TOP_RATIO))
	var base_size := maxi(3, roundi(rect.size.y * VisualStyle.FENCE_BASE_RATIO))
	var fill_color: Color = palette["post_fill"]
	var top_color: Color = palette["post_top"]
	var base_color: Color = palette["post_base"]

	draw_rect(rect, fill_color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, top_size)), top_color)
	draw_rect(
		Rect2(
			rect.position + Vector2(0, rect.size.y - base_size),
			Vector2(rect.size.x, base_size)
		),
		base_color
	)


func draw_vertical_fence(edge: Vector2i) -> void:
	var post_width := maxi(6, roundi(cell_size * VisualStyle.FENCE_POST_W_RATIO))
	var post_gap := maxi(5, roundi(cell_size * VisualStyle.FENCE_POST_GAP_RATIO))
	var thickness := maxi(1, roundi(cell_size * VisualStyle.FENCE_THICKNESS_RATIO))
	var pad := roundi(post_gap / 2.0)
	var seam_x := (edge.x + 1) * cell_size
	var start_y := edge.y * cell_size + pad
	var end_y := (edge.y + 1) * cell_size - pad
	var post_y := start_y

	while post_y < end_y:
		var visible_height := minf(post_width, end_y - post_y)
		draw_vertical_post(
			Rect2(
				Vector2(seam_x - thickness / 2.0, post_y),
				Vector2(thickness, visible_height)
			)
		)
		post_y += post_width + post_gap


func draw_vertical_post(rect: Rect2) -> void:
	var light_size := maxi(2, roundi(rect.size.x * VisualStyle.FENCE_TOP_RATIO))
	var base_size := maxi(3, roundi(rect.size.x * VisualStyle.FENCE_BASE_RATIO))
	var fill_color: Color = palette["post_fill"]
	var light_color: Color = palette["post_top"]
	var base_color: Color = palette["post_base"]

	draw_rect(rect, fill_color)
	draw_rect(Rect2(rect.position, Vector2(light_size, rect.size.y)), light_color)
	draw_rect(
		Rect2(
			rect.position + Vector2(rect.size.x - base_size, 0),
			Vector2(base_size, rect.size.y)
		),
		base_color
	)


func draw_legacy_goals() -> void:
	for cell in game_board.goal_cells:
		draw_centered_text(
			cell,
			"*",
			DebugStyle.GOAL_MARKER_COLOR,
			scaled_font_size(36)
		)


func draw_legacy_blocks() -> void:
	for block in game_board.blocks:
		var cell: Vector2i = block["cell"]
		var vector_name: String = block["vector"]
		var recovery_block: bool = game_board.is_recovery_block(block)
		var color := DebugStyle.BLOCK_COLOR

		if recovery_block:
			color = (
				DebugStyle.INSTALLED_RECOVERY_BLOCK_COLOR
				if vector_name != ""
				else DebugStyle.RECOVERY_BLOCK_COLOR
			)
		elif vector_name != "":
			color = DebugStyle.INSTALLED_BLOCK_COLOR

		var block_gap := roundi(cell_size * VisualStyle.BLOCK_INSET_RATIO)
		var block_rect := Rect2(
			cell_to_position(cell) + Vector2(block_gap, block_gap),
			Vector2(cell_size - block_gap * 2, cell_size - block_gap * 2)
		)

		if game_board.goal_cells.has(cell):
			var border_width := scaled_px(4.0)
			draw_rect(
				block_rect.grow(border_width),
				DebugStyle.GOAL_BLOCK_BORDER_COLOR
			)

		draw_rect(block_rect, color)

		if recovery_block:
			draw_text_at(
				cell_to_position(cell) + Vector2(
					cell_size - block_gap - scaled_px(26.0),
					block_gap
				),
				"↺",
				Color.WHITE,
				scaled_font_size(20)
			)
		if vector_name != "":
			draw_centered_text(
				cell,
				momentum_arrow(vector_name),
				Color(1.0, 0.94, 0.35),
				scaled_font_size(DebugStyle.INSTALLED_VECTOR_FONT_SIZE)
			)


func draw_legacy_player() -> void:
	var player_gap := roundi(cell_size * VisualStyle.PLAYER_INSET_RATIO)
	var player_position := cell_to_position(game_board.player_cell)
	draw_rect(
		Rect2(
			player_position + Vector2(player_gap, player_gap),
			Vector2(cell_size - player_gap * 2, cell_size - player_gap * 2)
		),
		DebugStyle.PLAYER_COLOR
	)

	var player_text := (
		"@"
		if game_board.player_queue == ""
		else "@%s" % momentum_arrow(game_board.player_queue)
	)
	draw_centered_text(
		game_board.player_cell,
		player_text,
		Color.WHITE,
		scaled_font_size(22)
	)
	draw_text_at(
		player_position + Vector2(scaled_px(16.0), -scaled_px(24.0)),
		momentum_arrow(game_board.facing_name),
		Color(0.7, 0.9, 1.0),
		scaled_font_size(20)
	)


func draw_centered_text(
	cell: Vector2i,
	text: String,
	color: Color,
	font_size: int
) -> void:
	var text_size := fallback_font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	)
	var ascent := fallback_font.get_ascent(font_size)
	var descent := fallback_font.get_descent(font_size)
	var baseline := cell_to_position(cell) + Vector2(
		(cell_size - text_size.x) / 2.0,
		(cell_size + ascent - descent) / 2.0
	)
	draw_string(
		fallback_font,
		baseline,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color
	)


func draw_text_at(
	text_position: Vector2,
	text: String,
	color: Color,
	font_size: int
) -> void:
	var baseline := text_position + Vector2(0, fallback_font.get_ascent(font_size))
	draw_string(
		fallback_font,
		baseline,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color
	)


func board_width() -> int:
	return game_board.terrain[0].size()


func refresh_layout_size() -> void:
	if game_board == null or game_board.terrain.is_empty():
		return

	var shadow_height := maxi(1, roundi(cell_size * VisualStyle.WALL_SHADOW_RATIO))
	custom_minimum_size = Vector2(
		board_width() * cell_size,
		game_board.terrain.size() * cell_size + shadow_height
	)


func is_wall_cell(cell: Vector2i) -> bool:
	return game_board.is_inside_board(cell) and game_board.is_wall(cell)


func cell_to_position(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size, cell.y * cell_size)


func scaled_px(value: float) -> int:
	return maxi(1, roundi(value * cell_size / float(VisualStyle.CELL_SIZE)))


func scaled_font_size(value: int) -> int:
	return maxi(8, roundi(value * cell_size / float(VisualStyle.CELL_SIZE)))


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
