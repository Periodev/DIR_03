extends Node2D

const VisualStyle = preload("res://scripts/visual_style.gd")

const CELL_SIZE := VisualStyle.PLAYER_CELL_SIZE
const MAP_SIZE := Vector2i(4, 4)
const START_CELL := Vector2i(0, 0)
const EXIT_CELL := Vector2i(0, 3)
const EXIT_REQUIREMENT := "1-9"
const MOVE_SECONDS := 0.10
const COMPLETED_COLOR := Color("#79b995")

const LEVELS := [
	{"id": "1-0", "cell": Vector2i(0, 0), "route": "main", "requires": []},
	{"id": "1-1", "cell": Vector2i(1, 0), "route": "main", "requires": ["1-0"]},
	{"id": "1-2", "cell": Vector2i(2, 0), "route": "main", "requires": ["1-1"]},
	{"id": "1-3", "cell": Vector2i(3, 0), "route": "main", "requires": ["1-2"]},
	{"id": "1-4", "cell": Vector2i(0, 1), "route": "main", "requires": ["1-3"]},
	{"id": "1-5", "cell": Vector2i(1, 1), "route": "main", "requires": ["1-4"]},
	{"id": "1-6", "cell": Vector2i(2, 1), "route": "branch", "requires": ["1-5"]},
	{"id": "1-7", "cell": Vector2i(3, 1), "route": "main", "requires": ["1-5"]},
	{"id": "1-8", "cell": Vector2i(0, 2), "route": "branch", "requires": ["1-7"]},
	{"id": "1-9", "cell": Vector2i(1, 2), "route": "main", "requires": ["1-7"]},
	{"id": "1-10", "cell": Vector2i(2, 2), "route": "branch", "requires": ["1-9"]},
	{"id": "1-11", "cell": Vector2i(3, 2), "route": "branch", "requires": ["1-9"]},
]

var palette: Dictionary = VisualStyle.theme(false)
var completed_levels: Dictionary = {}
var player_cell := START_CELL
var player_draw_position := Vector2.ZERO
var facing := Vector2i.RIGHT
var input_locked := false
var status_message := "AREA 01"
var ui_font: Font


func _ready() -> void:
	ui_font = ThemeDB.fallback_font
	player_draw_position = cell_center(player_cell)
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("reset_level"):
		reset_progress()
		return
	if input_locked:
		return

	if event.is_action_pressed("move_up"):
		try_move(Vector2i.UP)
	elif event.is_action_pressed("move_down"):
		try_move(Vector2i.DOWN)
	elif event.is_action_pressed("move_left"):
		try_move(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		try_move(Vector2i.RIGHT)
	elif event.is_action_pressed("trigger_vector"):
		complete_current_level()


func try_move(direction: Vector2i) -> void:
	facing = direction
	var target := player_cell + direction
	if not is_walkable(target):
		status_message = "LOCKED"
		queue_redraw()
		return

	var from := player_draw_position
	player_cell = target
	var destination := cell_center(player_cell)
	input_locked = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(set_player_draw_position, from, destination, MOVE_SECONDS)
	tween.tween_callback(finish_move)


func set_player_draw_position(value: Vector2) -> void:
	player_draw_position = value
	queue_redraw()


func finish_move() -> void:
	input_locked = false
	var level := level_at(player_cell)
	if level.is_empty():
		status_message = "AREA 01"
	else:
		var level_id := String(level["id"])
		status_message = "%s  %s" % [
			level_id,
			"COMPLETE" if is_completed(level_id) else "AVAILABLE",
		]
	queue_redraw()


func complete_current_level() -> void:
	var level := level_at(player_cell)
	if level.is_empty():
		return
	var level_id := String(level["id"])
	if not is_unlocked(level_id):
		return
	if is_completed(level_id):
		status_message = "%s  COMPLETE" % level_id
		queue_redraw()
		return

	completed_levels[level_id] = true
	status_message = "%s  COMPLETE" % level_id
	queue_redraw()


func reset_progress() -> void:
	completed_levels.clear()
	player_cell = START_CELL
	player_draw_position = cell_center(player_cell)
	facing = Vector2i.RIGHT
	input_locked = false
	status_message = "AREA 01"
	queue_redraw()


func is_walkable(cell: Vector2i) -> bool:
	if cell == START_CELL:
		return true
	if cell == EXIT_CELL:
		return is_completed(EXIT_REQUIREMENT)
	var level := level_at(cell)
	if level.is_empty():
		return false
	return is_unlocked(String(level["id"]))


func is_level_visible(level: Dictionary) -> bool:
	return not level.is_empty()


func is_unlocked(level_id: String) -> bool:
	var level := level_by_id(level_id)
	if level.is_empty():
		return false
	var requirements: Array = level["requires"]
	for requirement_value in requirements:
		if not is_completed(String(requirement_value)):
			return false
	return true


func is_completed(level_id: String) -> bool:
	return bool(completed_levels.get(level_id, false))


func level_at(cell: Vector2i) -> Dictionary:
	for level_value in LEVELS:
		var level: Dictionary = level_value
		if Vector2i(level["cell"]) == cell:
			return level
	return {}


func level_by_id(level_id: String) -> Dictionary:
	for level_value in LEVELS:
		var level: Dictionary = level_value
		if String(level["id"]) == level_id:
			return level
	return {}


func map_origin() -> Vector2:
	var map_pixel_size := Vector2(MAP_SIZE) * CELL_SIZE
	var viewport_size := get_viewport_rect().size
	return (viewport_size - map_pixel_size) * 0.5 + Vector2(0, 24)


func cell_position(cell: Vector2i) -> Vector2:
	return map_origin() + Vector2(cell) * CELL_SIZE


func cell_center(cell: Vector2i) -> Vector2:
	return cell_position(cell) + Vector2.ONE * CELL_SIZE * 0.5


func _draw() -> void:
	draw_rect(get_viewport_rect(), palette["app_bg"])
	draw_header()

	for level_value in LEVELS:
		var level: Dictionary = level_value
		if is_level_visible(level):
			draw_level_cell(level)

	draw_exit_cell()
	draw_player()


func draw_header() -> void:
	var viewport_width := get_viewport_rect().size.x
	var completed_count := completed_levels.size()
	draw_text_centered(
		Rect2(0, 22, viewport_width, 28),
		"DIR / AREA 01",
		18,
		palette["text_hi"]
	)
	draw_text_centered(
		Rect2(0, 51, viewport_width, 22),
		"%02d / %02d    %s" % [completed_count, LEVELS.size(), status_message],
		13,
		palette["text_dim"]
	)


func draw_level_cell(level: Dictionary) -> void:
	var level_id := String(level["id"])
	var cell := Vector2i(level["cell"])
	var unlocked := is_unlocked(level_id)
	var completed := is_completed(level_id)
	var floor_color: Color = palette["floor"]
	var grid_color: Color = palette["grid"]
	var label_color: Color = palette["text"]
	if not unlocked:
		floor_color.a = 0.22
		grid_color.a = 0.32
		label_color.a = 0.32
	elif completed:
		label_color = COMPLETED_COLOR

	var rect := Rect2(cell_position(cell), Vector2.ONE * CELL_SIZE)
	draw_rect(rect, floor_color)
	draw_rect(rect, grid_color, false, 1.0)

	var plate_inset := CELL_SIZE * 0.17
	var plate := rect.grow(-plate_inset)
	var plate_color: Color = palette["label"]
	var plate_width := 2.0
	if completed:
		plate_color = COMPLETED_COLOR
		plate_width = 3.0
	elif unlocked:
		plate_color = palette["player"]
	else:
		plate_color.a = 0.28
	draw_rect(plate, plate_color, false, plate_width)

	if cell != player_cell:
		draw_text_centered(rect, level_id, 16, label_color)


func draw_exit_cell() -> void:
	var unlocked := is_completed(EXIT_REQUIREMENT)
	var floor_color: Color = palette["floor"]
	var line_color: Color = palette["player"]
	if not unlocked:
		floor_color.a = 0.20
		line_color.a = 0.25
	var rect := Rect2(cell_position(EXIT_CELL), Vector2.ONE * CELL_SIZE)
	draw_rect(rect, floor_color)
	draw_rect(rect, palette["grid"], false, 1.0)
	draw_rect(rect.grow(-CELL_SIZE * 0.25), line_color, false, 2.0)
	if EXIT_CELL != player_cell:
		draw_text_centered(rect, "EXIT", 12, line_color)


func draw_player() -> void:
	var body_size := CELL_SIZE * VisualStyle.PLAYER_BODY_RATIO
	var chevron_depth := CELL_SIZE * VisualStyle.FACING_CHV_DEPTH_RATIO
	var gap := maxf(2.0, CELL_SIZE * VisualStyle.FACING_CHV_GAP_RATIO)
	var radius := minf(body_size * 0.5, CELL_SIZE * 0.5 - chevron_depth * 0.5 - gap)
	draw_colored_polygon(
		PackedVector2Array([
			player_draw_position + Vector2(0, -radius),
			player_draw_position + Vector2(radius, 0),
			player_draw_position + Vector2(0, radius),
			player_draw_position + Vector2(-radius, 0),
		]),
		palette["player"]
	)
	draw_facing_chevron()


func draw_facing_chevron() -> void:
	var forward := Vector2(facing)
	var center := (
		player_draw_position
		+ forward * (
			CELL_SIZE * 0.5
			- CELL_SIZE * VisualStyle.FACING_CHV_INSET_RATIO
		)
	)
	var length := CELL_SIZE * VisualStyle.FACING_CHV_LEN_RATIO
	var depth := CELL_SIZE * VisualStyle.FACING_CHV_DEPTH_RATIO
	var stroke := depth * VisualStyle.FACING_CHV_STROKE_RATIO
	var outline := maxf(1.0, CELL_SIZE * VisualStyle.FACING_CHV_OUTLINE_RATIO)

	draw_colored_polygon(
		chevron_points(
			center,
			forward,
			length + outline * 2.0,
			depth + outline * 2.0,
			stroke + outline * 2.0
		),
		palette["direction_fill"]
	)
	draw_colored_polygon(
		chevron_points(center, forward, length, depth, stroke),
		palette["player"]
	)


func chevron_points(
	center: Vector2,
	forward: Vector2,
	length: float,
	depth: float,
	stroke: float
) -> PackedVector2Array:
	var side := Vector2(-forward.y, forward.x)
	var back_center := center - forward * depth * 0.5
	var outer_tip := center + forward * depth * 0.5
	var inner_tip := outer_tip - forward * stroke
	var outer_half_length := length * 0.5
	var inner_half_length := maxf(1.0, outer_half_length - stroke)
	return PackedVector2Array([
		back_center - side * outer_half_length,
		back_center - side * inner_half_length,
		inner_tip,
		back_center + side * inner_half_length,
		back_center + side * outer_half_length,
		outer_tip,
	])


func draw_text_centered(
	rect: Rect2,
	text: String,
	font_size: int,
	color: Color
) -> void:
	var baseline := rect.position.y + (rect.size.y + ui_font.get_ascent(font_size)) * 0.5
	draw_string(
		ui_font,
		Vector2(rect.position.x, baseline),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		font_size,
		color
	)
