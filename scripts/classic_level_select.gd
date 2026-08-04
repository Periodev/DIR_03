extends Node2D

const VisualStyle = preload("res://scripts/visual_style.gd")

const GRID_COLUMNS := 6
const MAX_SLOT_SIZE := 216.0
const MIN_SIDE_MARGIN := 32.0
const MAX_SIDE_MARGIN := 72.0
const SIDE_MARGIN_RATIO := 0.05
const HEADER_BOTTOM := 96.0
const BOTTOM_MARGIN := 48.0
const TILE_GAP := 8.0
const COMPLETED_COLOR := Color("#49c9a5")
const LOCKED_ALPHA := 0.28
const SELECTED_GLOW_ALPHA := 0.11
const COMPLETED_GLOW_ALPHA := 0.07

var palette: Dictionary = VisualStyle.theme(false)
var entries: Array[Dictionary] = []
var area_entries: Array = []
var area_selection_indices: Array[int] = []
var current_area_index := 0
var selected_index := 0
var status_message := "LEVEL SELECT"
var ui_font: Font


func _ready() -> void:
	Campaign.set_level_select_scene(Campaign.CLASSIC_LEVEL_SELECT_SCENE_PATH)
	ui_font = ThemeDB.fallback_font
	if Campaign.is_single_level_mode():
		call_deferred("open_single_level_test")
		return
	build_entries()
	select_return_level()
	refresh_status()
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
		Campaign.unlock_all_levels()
		status_message = "ALL LEVELS UNLOCKED"
		queue_redraw()
		return
	if is_complete_selected_key(event):
		complete_selected_level()
		return

	if event.is_action_pressed("move_left"):
		move_selection(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		move_selection(Vector2i.RIGHT)
	elif event.is_action_pressed("move_up"):
		move_selection(Vector2i.UP)
	elif event.is_action_pressed("move_down"):
		move_selection(Vector2i.DOWN)
	elif is_confirm_key(event):
		start_selected_level()


func build_entries() -> void:
	entries.clear()
	area_entries.clear()
	area_selection_indices.clear()
	for area_id in range(1, Campaign.AREAS.size() + 1):
		var area: Dictionary = Campaign.area_data_for(area_id)
		var levels: Array = area["levels"]
		var page_entries: Array[Dictionary] = []
		for level_value in levels:
			var level: Dictionary = level_value.duplicate()
			level["area_id"] = area_id
			entries.append(level)
			page_entries.append(level)
		area_entries.append(page_entries)
		area_selection_indices.append(0)


func select_return_level() -> void:
	current_area_index = clampi(Campaign.return_area - 1, 0, area_entries.size() - 1)
	var page: Array = current_page_entries()
	for index in range(page.size()):
		var entry: Dictionary = page[index]
		if Vector2i(entry["cell"]) == Campaign.return_cell:
			selected_index = index
			area_selection_indices[current_area_index] = index
			if Campaign.consume_completed_return():
				advance_after_completion()
			return
	selected_index = 0
	Campaign.consume_completed_return()


func current_page_entries() -> Array:
	if current_area_index < 0 or current_area_index >= area_entries.size():
		return []
	var page: Array = area_entries[current_area_index]
	return page


func move_selection(direction: Vector2i) -> void:
	var page: Array = current_page_entries()
	if page.is_empty():
		return
	var row: int = floori(float(selected_index) / float(GRID_COLUMNS))
	var column: int = selected_index % GRID_COLUMNS
	var target_index: int = selected_index

	if direction == Vector2i.LEFT and column > 0:
		target_index -= 1
	elif direction == Vector2i.LEFT:
		switch_area(-1)
		return
	elif (
		direction == Vector2i.RIGHT
		and column < GRID_COLUMNS - 1
		and target_index + 1 < page.size()
	):
		target_index += 1
	elif direction == Vector2i.RIGHT:
		switch_area(1)
		return
	elif direction == Vector2i.UP and row > 0:
		target_index -= GRID_COLUMNS
	elif direction == Vector2i.DOWN and target_index + GRID_COLUMNS < page.size():
		target_index += GRID_COLUMNS

	if target_index == selected_index:
		return
	selected_index = target_index
	area_selection_indices[current_area_index] = selected_index
	refresh_status()
	queue_redraw()


func switch_area(offset: int) -> void:
	var target_area_index: int = current_area_index + offset
	if target_area_index < 0 or target_area_index >= area_entries.size():
		return
	if not is_area_accessible(target_area_index):
		status_message = "AREA %s  LOCKED" % (target_area_index + 1)
		queue_redraw()
		return
	current_area_index = target_area_index
	selected_index = area_selection_indices[current_area_index]
	refresh_status()
	queue_redraw()


func advance_after_completion() -> void:
	var page: Array = current_page_entries()
	if selected_index + 1 < page.size():
		selected_index += 1
		area_selection_indices[current_area_index] = selected_index
	elif (
		current_area_index + 1 < area_entries.size()
		and is_area_accessible(current_area_index + 1)
	):
		current_area_index += 1
		selected_index = area_selection_indices[current_area_index]
	refresh_status()
	queue_redraw()


func start_selected_level() -> void:
	var page: Array = current_page_entries()
	if page.is_empty():
		return
	var entry: Dictionary = page[selected_index]
	var level_id := String(entry["id"])
	if not is_entry_unlocked(entry):
		status_message = "%s  LOCKED" % level_id
		queue_redraw()
		return
	if not Campaign.begin_level(
		level_id,
		int(entry["area_id"]),
		Vector2i(entry["cell"])
	):
		status_message = "%s  LOAD FAILED" % level_id
		queue_redraw()
		return
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func reset_progress() -> void:
	Campaign.reset_progress()
	current_area_index = 0
	selected_index = 0
	area_selection_indices.fill(0)
	refresh_status()
	queue_redraw()


func complete_selected_level() -> void:
	var page: Array = current_page_entries()
	if page.is_empty():
		return
	var entry: Dictionary = page[selected_index]
	Campaign.complete_level(String(entry["id"]))
	advance_after_completion()


func refresh_status() -> void:
	var page: Array = current_page_entries()
	if page.is_empty():
		status_message = "NO LEVELS"
		return
	var entry: Dictionary = page[selected_index]
	var level_id: String = String(entry["id"])
	var level_label := "%s  %s" % [level_id, String(entry["name"]).to_upper()]
	if Campaign.is_completed(level_id):
		status_message = "%s  COMPLETE" % level_label
	elif is_entry_unlocked(entry):
		status_message = "%s  AVAILABLE" % level_label
	else:
		status_message = "%s  LOCKED" % level_label


func is_entry_unlocked(entry: Dictionary) -> bool:
	if Campaign.all_levels_unlocked:
		return true
	var requirements: Array = entry["requires"]
	for required_value in requirements:
		if not Campaign.is_completed(String(required_value)):
			return false

	var area_id := int(entry["area_id"])
	if area_id <= 1:
		return true
	var previous_area: Dictionary = Campaign.area_data_for(area_id - 1)
	return Campaign.is_completed(String(previous_area["exit_requirement"]))


func is_area_accessible(area_index: int) -> bool:
	if area_index <= 0 or Campaign.all_levels_unlocked:
		return true
	var previous_area: Dictionary = Campaign.area_data_for(area_index)
	return Campaign.is_completed(String(previous_area["exit_requirement"]))


func completed_count() -> int:
	var count := 0
	var page: Array = current_page_entries()
	for entry_value in page:
		var entry: Dictionary = entry_value
		if Campaign.is_completed(String(entry["id"])):
			count += 1
	return count


func grid_rows() -> int:
	return 2


func slot_size() -> float:
	return slot_size_for(get_viewport_rect().size)


func slot_size_for(viewport_size: Vector2) -> float:
	var rows := maxi(1, grid_rows())
	var margin := side_margin_for(viewport_size.x)
	var width_limit := (viewport_size.x - margin * 2.0) / float(GRID_COLUMNS)
	var height_limit := (
		viewport_size.y - HEADER_BOTTOM - BOTTOM_MARGIN
	) / float(rows)
	return floorf(minf(MAX_SLOT_SIZE, minf(width_limit, height_limit)))


func side_margin() -> float:
	return side_margin_for(get_viewport_rect().size.x)


func side_margin_for(viewport_width: float) -> float:
	return clampf(
		viewport_width * SIDE_MARGIN_RATIO,
		MIN_SIDE_MARGIN,
		MAX_SIDE_MARGIN
	)


func grid_origin() -> Vector2:
	return grid_origin_for(get_viewport_rect().size)


func grid_origin_for(viewport_size: Vector2) -> Vector2:
	var size := slot_size_for(viewport_size)
	var grid_pixel_size := Vector2(
		float(GRID_COLUMNS) * size,
		float(grid_rows()) * size
	)
	var available_center_y := (
		HEADER_BOTTOM + viewport_size.y - BOTTOM_MARGIN
	) * 0.5
	return Vector2(
		(viewport_size.x - grid_pixel_size.x) * 0.5,
		available_center_y - grid_pixel_size.y * 0.5
	)


func entry_rect(index: int) -> Rect2:
	return entry_rect_for(index, get_viewport_rect().size)


func entry_rect_for(index: int, viewport_size: Vector2) -> Rect2:
	var size := slot_size_for(viewport_size)
	var row: int = floori(float(index) / float(GRID_COLUMNS))
	var column := index % GRID_COLUMNS
	var slot_position := grid_origin_for(viewport_size) + Vector2(column, row) * size
	return Rect2(
		slot_position + Vector2.ONE * TILE_GAP * 0.5,
		Vector2.ONE * (size - TILE_GAP)
	)


func _draw() -> void:
	draw_rect(get_viewport_rect(), palette["app_bg"])
	draw_header()
	var page: Array = current_page_entries()
	for index in range(page.size()):
		draw_level_entry(index)
	draw_area_arrows()


func draw_header() -> void:
	var viewport_width := get_viewport_rect().size.x
	draw_text_centered(
		Rect2(0, 22, viewport_width, 28),
		"DIR / LEVEL SELECT",
		21,
		palette["text_hi"]
	)
	draw_text_centered(
		Rect2(0, 51, viewport_width, 22),
		"AREA %s    %02d / %02d COMPLETE    %s" % [
			current_area_index + 1,
			completed_count(),
			current_page_entries().size(),
			status_message,
		],
		15,
		palette["text_dim"]
	)


func draw_level_entry(index: int) -> void:
	var page: Array = current_page_entries()
	var entry: Dictionary = page[index]
	var level_id := String(entry["id"])
	var unlocked := is_entry_unlocked(entry)
	var completed := Campaign.is_completed(level_id)
	var selected := index == selected_index
	var rect := entry_rect(index)
	var floor_color: Color = palette["floor"]
	var border_color: Color = palette["label"]
	var text_color: Color = palette["text"]
	var border_width := 2.0

	if not unlocked:
		floor_color.a = 0.18
		border_color.a = LOCKED_ALPHA
		text_color.a = LOCKED_ALPHA
	elif completed:
		border_color = COMPLETED_COLOR
		text_color = COMPLETED_COLOR
		border_width = 3.0
	else:
		border_color = palette["label"]

	if selected:
		draw_soft_outline_glow(rect, palette["player"], SELECTED_GLOW_ALPHA)
	elif completed:
		draw_soft_outline_glow(rect, COMPLETED_COLOR, COMPLETED_GLOW_ALPHA)
	draw_rect(rect, floor_color)
	draw_rect(rect, border_color, false, border_width)
	if selected:
		draw_rect(rect.grow(4.0), palette["player"], false, 6.0)
	draw_text_centered(rect, level_id, 21, text_color)


func draw_soft_outline_glow(rect: Rect2, color: Color, alpha: float) -> void:
	var outer_color := color
	outer_color.a = alpha * 0.45
	draw_rect(rect.grow(6.0), outer_color, false, 5.0)
	var inner_color := color
	inner_color.a = alpha
	draw_rect(rect.grow(3.0), inner_color, false, 3.0)


func draw_area_arrows() -> void:
	var viewport_size := get_viewport_rect().size
	var center_y := grid_origin().y + slot_size()
	var margin := side_margin()
	var left_color: Color = palette["text_dim"]
	var right_color: Color = palette["text_dim"]
	if current_area_index == 0:
		left_color.a = 0.16
	if (
		current_area_index >= area_entries.size() - 1
		or not is_area_accessible(current_area_index + 1)
	):
		right_color.a = 0.16
	draw_chevron(Vector2(margin * 0.5, center_y), Vector2i.LEFT, left_color)
	draw_chevron(
		Vector2(viewport_size.x - margin * 0.5, center_y),
		Vector2i.RIGHT,
		right_color
	)


func draw_chevron(center: Vector2, direction: Vector2i, color: Color) -> void:
	var points := PackedVector2Array([
		Vector2(-5, -13),
		Vector2(7, 0),
		Vector2(-5, 13),
		Vector2(-9, 9),
		Vector2(-1, 0),
		Vector2(-9, -9),
	])
	if direction == Vector2i.LEFT:
		for index in range(points.size()):
			points[index].x *= -1.0
	for index in range(points.size()):
		points[index] += center
	draw_colored_polygon(points, color)


func draw_text_centered(
	rect: Rect2,
	text: String,
	font_size: int,
	color: Color
) -> void:
	var baseline := rect.position.y + (
		rect.size.y + ui_font.get_ascent(font_size)
	) * 0.5
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


func is_complete_selected_key(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return key_event.pressed and not key_event.echo and key_event.keycode == KEY_F4
