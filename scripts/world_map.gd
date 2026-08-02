extends Node2D

const VisualStyle = preload("res://scripts/visual_style.gd")

const CELL_SIZE := VisualStyle.PLAYER_CELL_SIZE
const MOVE_SECONDS := 0.10
const AREA_TRANSITION_SECONDS := 0.14
const COMPLETED_COLOR := Color("#79b995")

var palette: Dictionary = VisualStyle.theme(false)
var current_area := 1
var player_cell := Vector2i.ZERO
var player_draw_cell := Vector2.ZERO
var facing := Vector2i.RIGHT
var input_locked := false
var status_message := "AREA 01"
var ui_font: Font
var transition_tween: Tween


func _ready() -> void:
	ui_font = ThemeDB.fallback_font
	Campaign.set_level_select_scene(Campaign.WORLD_MAP_SCENE_PATH)
	Campaign.consume_completed_return()
	if Campaign.is_single_level_mode():
		call_deferred("open_single_level_test")
		return
	current_area = Campaign.return_area
	player_cell = Campaign.return_cell
	player_draw_cell = Vector2(player_cell)
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()


func open_single_level_test() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("reset_level"):
		reset_progress()
		return
	if is_unlock_all_key(event):
		unlock_all_levels()
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
	elif is_confirm_key(event):
		start_current_level()


func try_move(direction: Vector2i) -> void:
	facing = direction
	if (
		direction == Vector2i.UP
		and player_cell.y == 0
		and area_previous() > 0
	):
		try_previous_area()
		return
	if (
		direction == Vector2i.DOWN
		and player_cell.y == area_size().y - 1
		and area_next() > 0
	):
		try_next_area()
		return

	var target := player_cell + direction
	if not is_walkable(target):
		status_message = "LOCKED"
		queue_redraw()
		return

	var from := player_draw_cell
	player_cell = target
	var destination := Vector2(player_cell)
	input_locked = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(set_player_draw_cell, from, destination, MOVE_SECONDS)
	tween.tween_callback(finish_move)


func set_player_draw_cell(value: Vector2) -> void:
	player_draw_cell = value
	queue_redraw()


func finish_move() -> void:
	input_locked = false
	var level := level_at(player_cell)
	if level.is_empty():
		status_message = area_name()
	else:
		var level_id := String(level["id"])
		status_message = "%s  %s" % [
			level_id,
			"COMPLETE" if is_completed(level_id) else "AVAILABLE",
		]
	queue_redraw()


func try_next_area() -> void:
	if not Campaign.all_levels_unlocked and not is_completed(area_exit_requirement()):
		status_message = "EXIT LOCKED"
		queue_redraw()
		return

	var next_area := area_next()
	transition_to_area(next_area, area_start_cell_for(next_area))


func try_previous_area() -> void:
	var previous_area := area_previous()
	transition_to_area(previous_area, area_exit_cell_for(previous_area))


func start_current_level() -> void:
	var level := level_at(player_cell)
	if level.is_empty():
		return
	var level_id := String(level["id"])
	if not is_unlocked(level_id):
		status_message = "LOCKED"
		queue_redraw()
		return
	if not Campaign.begin_level(level_id, current_area, player_cell):
		status_message = "LOAD FAILED"
		queue_redraw()
		return
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func reset_progress() -> void:
	if is_instance_valid(transition_tween):
		transition_tween.kill()
	Campaign.reset_progress()
	current_area = 1
	player_cell = area_start_cell()
	player_draw_cell = Vector2(player_cell)
	facing = Vector2i.RIGHT
	input_locked = false
	modulate.a = 1.0
	status_message = area_name()
	queue_redraw()


func unlock_all_levels() -> void:
	Campaign.unlock_all_levels()
	status_message = "ALL LEVELS UNLOCKED"
	queue_redraw()


func transition_to_area(target_area: int, destination_cell: Vector2i) -> void:
	input_locked = true
	transition_tween = create_tween()
	transition_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		AREA_TRANSITION_SECONDS
	)
	transition_tween.tween_callback(apply_area.bind(target_area, destination_cell))
	transition_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		AREA_TRANSITION_SECONDS
	)
	transition_tween.tween_callback(finish_area_transition)


func apply_area(target_area: int, destination_cell: Vector2i) -> void:
	current_area = target_area
	player_cell = destination_cell
	player_draw_cell = Vector2(player_cell)
	facing = Vector2i.RIGHT
	status_message = area_name()
	queue_redraw()


func finish_area_transition() -> void:
	input_locked = false
	transition_tween = null
	queue_redraw()


func is_walkable(cell: Vector2i) -> bool:
	if cell == area_start_cell():
		return true
	var level := level_at(cell)
	if level.is_empty():
		return false
	return is_unlocked(String(level["id"]))


func is_level_visible(level: Dictionary) -> bool:
	return not level.is_empty()


func is_unlocked(level_id: String) -> bool:
	if Campaign.all_levels_unlocked:
		return true
	var level := level_by_id(level_id)
	if level.is_empty():
		return false
	var requirements: Array = level["requires"]
	for requirement_value in requirements:
		if not is_completed(String(requirement_value)):
			return false
	return true


func is_completed(level_id: String) -> bool:
	return Campaign.is_completed(level_id)


func area_data() -> Dictionary:
	return Campaign.area_data_for(current_area)


func area_levels() -> Array:
	return area_data()["levels"]


func area_size() -> Vector2i:
	return Vector2i(area_data()["size"])


func area_start_cell() -> Vector2i:
	return Vector2i(area_data()["start_cell"])


func area_start_cell_for(area_id: int) -> Vector2i:
	return Campaign.start_cell_for(area_id)


func area_exit_cell_for(area_id: int) -> Vector2i:
	var data: Dictionary = Campaign.area_data_for(area_id)
	var exit_requirement := String(data["exit_requirement"])
	var levels: Array = data["levels"]
	for level_value in levels:
		var level: Dictionary = level_value
		if String(level["id"]) == exit_requirement:
			return Vector2i(level["cell"])
	return Vector2i(data["start_cell"])


func area_exit_requirement() -> String:
	return String(area_data()["exit_requirement"])


func area_previous() -> int:
	return int(area_data()["previous_area"])


func area_next() -> int:
	return int(area_data()["next_area"])


func area_name() -> String:
	return "AREA %02d" % current_area


func area_completed_count() -> int:
	var count := 0
	for level_value in area_levels():
		var level: Dictionary = level_value
		if is_completed(String(level["id"])):
			count += 1
	return count


func level_at(cell: Vector2i) -> Dictionary:
	for level_value in area_levels():
		var level: Dictionary = level_value
		if Vector2i(level["cell"]) == cell:
			return level
	return {}


func level_by_id(level_id: String) -> Dictionary:
	for level_value in area_levels():
		var level: Dictionary = level_value
		if String(level["id"]) == level_id:
			return level
	return {}


func map_origin() -> Vector2:
	var map_pixel_size := Vector2(area_size()) * CELL_SIZE
	var viewport_size := get_viewport_rect().size
	return (viewport_size - map_pixel_size) * 0.5 + Vector2(0, 24)


func cell_position(cell: Vector2i) -> Vector2:
	return map_origin() + Vector2(cell) * CELL_SIZE


func player_draw_center() -> Vector2:
	return map_origin() + (player_draw_cell + Vector2.ONE * 0.5) * CELL_SIZE


func _draw() -> void:
	draw_rect(get_viewport_rect(), palette["app_bg"])
	draw_header()

	for level_value in area_levels():
		var level: Dictionary = level_value
		if is_level_visible(level):
			draw_level_cell(level)

	draw_area_navigation_arrows()
	draw_player()


func draw_header() -> void:
	var viewport_width := get_viewport_rect().size.x
	var completed_count := area_completed_count()
	draw_text_centered(
		Rect2(0, 22, viewport_width, 28),
		"DIR / %s" % area_name(),
		18,
		palette["text_hi"]
	)
	draw_text_centered(
		Rect2(0, 51, viewport_width, 22),
		"%02d / %02d    %s" % [completed_count, area_levels().size(), status_message],
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


func draw_area_navigation_arrows() -> void:
	if area_previous() > 0:
		draw_area_navigation_arrow(Vector2i.UP, true)
	if area_next() > 0:
		draw_area_navigation_arrow(
			Vector2i.DOWN,
			is_completed(area_exit_requirement())
		)


func draw_area_navigation_arrow(direction: Vector2i, unlocked: bool) -> void:
	var arrow_color: Color = COMPLETED_COLOR
	if not unlocked:
		arrow_color = palette["label"]
		arrow_color.a = 0.28

	var map_width := float(area_size().x) * CELL_SIZE
	var map_height := float(area_size().y) * CELL_SIZE
	var center_y := map_height + CELL_SIZE * 0.42
	if direction == Vector2i.UP:
		center_y = -CELL_SIZE * 0.42
	var center := map_origin() + Vector2(map_width * 0.5, center_y)
	var forward := Vector2(direction)
	var length := CELL_SIZE * 1.30
	var depth := CELL_SIZE * 0.40
	var stroke := CELL_SIZE * 0.10
	draw_colored_polygon(
		chevron_points(center, forward, length, depth, stroke),
		arrow_color
	)


func draw_player() -> void:
	var player_center := player_draw_center()
	var body_size := CELL_SIZE * VisualStyle.PLAYER_BODY_RATIO
	var chevron_depth := CELL_SIZE * VisualStyle.FACING_CHV_DEPTH_RATIO
	var gap := maxf(2.0, CELL_SIZE * VisualStyle.FACING_CHV_GAP_RATIO)
	var radius := minf(body_size * 0.5, CELL_SIZE * 0.5 - chevron_depth * 0.5 - gap)
	draw_colored_polygon(
		PackedVector2Array([
			player_center + Vector2(0, -radius),
			player_center + Vector2(radius, 0),
			player_center + Vector2(0, radius),
			player_center + Vector2(-radius, 0),
		]),
		palette["player"]
	)
	draw_facing_chevron()


func draw_facing_chevron() -> void:
	var forward := Vector2(facing)
	var center := (
		player_draw_center()
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


func is_confirm_key(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return (
		key_event.pressed
		and not key_event.echo
		and (
			key_event.keycode == KEY_ENTER
			or key_event.keycode == KEY_KP_ENTER
			or key_event.keycode == KEY_SPACE
		)
	)


func is_unlock_all_key(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return key_event.pressed and not key_event.echo and key_event.keycode == KEY_F3
