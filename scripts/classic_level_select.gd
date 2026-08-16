extends Node2D

const VisualStyle = preload("res://scripts/visual_style.gd")
const AsciiMapData = preload("res://scripts/ascii_map.gd")
const ThumbnailRenderer = preload("res://scripts/level_thumbnail_renderer.gd")
const ESCAPE_KEY_TEXTURE = preload("res://assets/input_prompts/keyboard_escape_outline.svg")
const NAVIGATION_STREAM: AudioStream = preload(
	"res://assets/audio/sfx/turn/click2.ogg"
)
const NAVIGATION_VOLUME_DB := -8.0
const CONFIRM_STREAM: AudioStream = preload(
	"res://assets/audio/sfx/confirm/switch34.ogg"
)
const CONFIRM_VOLUME_DB := -4.0

const GRID_COLUMNS := 6
const MAX_SLOT_SIZE := 216.0
const MIN_SIDE_MARGIN := 48.0
const MAX_SIDE_MARGIN := 96.0
const SIDE_MARGIN_RATIO := 0.07
const HEADER_BOTTOM := 96.0
const BOTTOM_MARGIN := 88.0
const TILE_GAP := 8.0
const LEVEL_NAME_GAP := 20.0
const LEVEL_NAME_HEIGHT := 24.0
const LEVEL_NAME_FONT_SIZE := 24
const LEVEL_NAME_MIN_WIDTH := 208.0
const LEVEL_NAME_MAX_WIDTH := 320.0
const COMPLETED_COLOR := Color("#49c9a5")
const LOCKED_ALPHA := 0.28
const COMPLETED_GLOW_ALPHA := 0.07
const SELECT_FRAME_GROW := 4.0
const SELECT_FRAME_WIDTH := 6.0
const HOVER_FRAME_GROW := 2.0
const HOVER_FRAME_WIDTH := 2.0
const AREA_ARROW_SCALE := 2.0
const AREA_ARROW_HIT_SIZE := Vector2(32.0, 44.0) * AREA_ARROW_SCALE
const TITLE_BUTTON_ICON_SIZE := 36.0
const TITLE_BUTTON_GAP := 10.0
const TITLE_BUTTON_FONT_SIZE := 24
const TITLE_BUTTON_MARGIN_X := 18.0
const CONFIRM_HINT_BOTTOM_MARGIN := 36.0
const CONFIRM_HINT_FONT_SIZE := 18

var palette: Dictionary = VisualStyle.theme(false)
var entries: Array[Dictionary] = []
var area_entries: Array = []
var area_selection_indices: Array[int] = []
var current_area_index := 0
var selected_index := 0
var ui_font: Font
var hovered_index := -1
var area_arrow_hovered := Vector2i.ZERO
var title_button_hovered := false
var navigation_player: AudioStreamPlayer
var confirm_player: AudioStreamPlayer


func _ready() -> void:
	Campaign.set_level_select_scene(Campaign.CLASSIC_LEVEL_SELECT_SCENE_PATH)
	ui_font = ThemeDB.fallback_font
	navigation_player = AudioStreamPlayer.new()
	navigation_player.name = "NavigationPlayer"
	navigation_player.volume_db = NAVIGATION_VOLUME_DB
	add_child(navigation_player)
	confirm_player = AudioStreamPlayer.new()
	confirm_player.name = "ConfirmPlayer"
	confirm_player.volume_db = CONFIRM_VOLUME_DB
	add_child(confirm_player)
	if Campaign.is_single_level_mode():
		call_deferred("open_single_level_test")
		return
	build_entries()
	select_return_level()
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()


func open_single_level_test() -> void:
	SceneTransition.transition_to("res://scenes/main.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if SceneTransition.is_active():
		return
	if event is InputEventKey and event.echo:
		return
	if event is InputEventMouseMotion:
		handle_mouse_motion(event.position)
		return
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event
		if button_event.pressed and button_event.button_index == MOUSE_BUTTON_LEFT:
			handle_mouse_click(button_event.position)
		return
	if is_cancel_key(event):
		play_confirm_feedback()
		SceneTransition.transition_to(Campaign.TITLE_SCREEN_SCENE_PATH)
		return
	if event.is_action_pressed("reset_level"):
		reset_progress()
		return
	if is_unlock_all_key(event):
		Campaign.unlock_all_levels()
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
			var thumbnail_data: Dictionary = AsciiMapData.parse(String(level["source"]))
			if thumbnail_data.has("error"):
				push_error("Unable to build thumbnail for %s: %s" % [
					level["id"],
					thumbnail_data["error"],
				])
				thumbnail_data = {}
			level["thumbnail_data"] = thumbnail_data
			level["area_id"] = area_id
			entries.append(level)
			page_entries.append(level)
		area_entries.append(page_entries)
		area_selection_indices.append(0)


func handle_mouse_motion(pos: Vector2) -> void:
	var changed := false

	var new_title_hover := title_button_rect().has_point(pos)
	if new_title_hover != title_button_hovered:
		title_button_hovered = new_title_hover
		changed = true

	var new_arrow_hover := Vector2i.ZERO
	if current_area_index > 0 and left_arrow_rect().has_point(pos):
		new_arrow_hover = Vector2i.LEFT
	elif (
		current_area_index < area_entries.size() - 1
		and is_area_accessible(current_area_index + 1)
		and right_arrow_rect().has_point(pos)
	):
		new_arrow_hover = Vector2i.RIGHT
	if new_arrow_hover != area_arrow_hovered:
		area_arrow_hovered = new_arrow_hover
		changed = true

	var new_hovered_index := -1
	var page: Array = current_page_entries()
	for index in range(page.size()):
		if entry_rect(index).has_point(pos):
			new_hovered_index = index
			break
	if new_hovered_index != hovered_index:
		hovered_index = new_hovered_index
		changed = true

	if changed:
		queue_redraw()


func handle_mouse_click(pos: Vector2) -> void:
	if title_button_rect().has_point(pos):
		play_confirm_feedback()
		SceneTransition.transition_to(Campaign.TITLE_SCREEN_SCENE_PATH)
		return
	if current_area_index > 0 and left_arrow_rect().has_point(pos):
		switch_area(-1)
		return
	if (
		current_area_index < area_entries.size() - 1
		and is_area_accessible(current_area_index + 1)
		and right_arrow_rect().has_point(pos)
	):
		switch_area(1)
		return
	var page: Array = current_page_entries()
	for index in range(page.size()):
		if entry_rect(index).has_point(pos):
			selected_index = index
			area_selection_indices[current_area_index] = selected_index
			start_selected_level()
			return


func title_button_rect() -> Rect2:
	var text_size := ui_font.get_string_size(
		"TITLE",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		TITLE_BUTTON_FONT_SIZE
	)
	var width := TITLE_BUTTON_ICON_SIZE + TITLE_BUTTON_GAP + text_size.x
	var height := maxf(TITLE_BUTTON_ICON_SIZE, text_size.y)
	var top := HEADER_BOTTOM * 0.5 - height * 0.5
	return Rect2(Vector2(TITLE_BUTTON_MARGIN_X, top), Vector2(width, height))


func area_arrow_center_y() -> float:
	return grid_origin().y + slot_size()


func left_arrow_rect() -> Rect2:
	var center := Vector2(side_margin() * 0.5, area_arrow_center_y())
	return Rect2(center - AREA_ARROW_HIT_SIZE / 2.0, AREA_ARROW_HIT_SIZE)


func right_arrow_rect() -> Rect2:
	var center := Vector2(
		get_viewport_rect().size.x - side_margin() * 0.5,
		area_arrow_center_y()
	)
	return Rect2(center - AREA_ARROW_HIT_SIZE / 2.0, AREA_ARROW_HIT_SIZE)


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
	play_navigation_feedback()
	queue_redraw()


func switch_area(offset: int) -> void:
	var target_area_index: int = current_area_index + offset
	if target_area_index < 0 or target_area_index >= area_entries.size():
		return
	if not is_area_accessible(target_area_index):
		queue_redraw()
		return
	current_area_index = target_area_index
	selected_index = area_selection_indices[current_area_index]
	play_navigation_feedback()
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
	queue_redraw()


func start_selected_level() -> void:
	var page: Array = current_page_entries()
	if page.is_empty():
		return
	var entry: Dictionary = page[selected_index]
	var level_id := String(entry["id"])
	if not is_entry_unlocked(entry):
		queue_redraw()
		return
	if not Campaign.begin_level(
		level_id,
		int(entry["area_id"]),
		Vector2i(entry["cell"])
	):
		queue_redraw()
		return
	play_confirm_feedback()
	SceneTransition.transition_to("res://scenes/main.tscn")


func play_navigation_feedback() -> void:
	if navigation_player == null:
		return
	navigation_player.stream = NAVIGATION_STREAM
	navigation_player.play()


func play_confirm_feedback() -> void:
	if confirm_player == null:
		return
	confirm_player.stream = CONFIRM_STREAM
	confirm_player.play()


func reset_progress() -> void:
	Campaign.reset_progress()
	current_area_index = 0
	selected_index = 0
	area_selection_indices.fill(0)
	queue_redraw()


func complete_selected_level() -> void:
	var page: Array = current_page_entries()
	if page.is_empty():
		return
	var entry: Dictionary = page[selected_index]
	Campaign.complete_level(String(entry["id"]))
	advance_after_completion()


func selected_level_name() -> String:
	var page: Array = current_page_entries()
	if page.is_empty():
		return ""
	var entry: Dictionary = page[selected_index]
	return String(entry["name"]).to_upper()


func selected_level_name_rect() -> Rect2:
	return selected_level_name_rect_for(selected_index, get_viewport_rect().size)


func selected_level_name_rect_for(index: int, viewport_size: Vector2) -> Rect2:
	var selected_rect := entry_rect_for(index, viewport_size)
	var margin := side_margin_for(viewport_size.x)
	var available_width := maxf(1.0, viewport_size.x - margin * 2.0)
	var label_width := minf(
		available_width,
		clampf(selected_rect.size.x, LEVEL_NAME_MIN_WIDTH, LEVEL_NAME_MAX_WIDTH)
	)
	var label_x := clampf(
		selected_rect.get_center().x - label_width * 0.5,
		margin,
		viewport_size.x - margin - label_width
	)
	var row: int = floori(float(index) / float(GRID_COLUMNS))
	var label_y := (
		selected_rect.position.y - LEVEL_NAME_GAP - LEVEL_NAME_HEIGHT
		if row == 0
		else selected_rect.end.y + LEVEL_NAME_GAP
	)
	return Rect2(label_x, label_y, label_width, LEVEL_NAME_HEIGHT)


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
	draw_selected_level_name()
	draw_hovered_level_name()
	draw_area_arrows()
	draw_confirm_hint()


func draw_header() -> void:
	draw_title_button()


func draw_confirm_hint() -> void:
	var viewport_rect := get_viewport_rect()
	var page: Array = current_page_entries()
	var color: Color = palette["text_hi"]
	var selection_unlocked := false
	if not page.is_empty():
		var selected_entry: Dictionary = page[selected_index]
		selection_unlocked = is_entry_unlocked(selected_entry)
	if not selection_unlocked:
		color = palette["text_dim"]
		color.a *= 0.55
	draw_text_centered(
		Rect2(
			0.0,
			viewport_rect.end.y - CONFIRM_HINT_BOTTOM_MARGIN - 16.0,
			viewport_rect.size.x,
			32.0
		),
		"SPACE / ENTER  SELECT LEVEL",
		CONFIRM_HINT_FONT_SIZE,
		color
	)


func draw_title_button() -> void:
	var rect := title_button_rect()
	var color: Color = palette["text"] if title_button_hovered else palette["text_dim"]
	var icon_rect := Rect2(
		rect.position + Vector2(0.0, (rect.size.y - TITLE_BUTTON_ICON_SIZE) * 0.5),
		Vector2.ONE * TITLE_BUTTON_ICON_SIZE
	)
	draw_texture_rect(ESCAPE_KEY_TEXTURE, icon_rect, false, color)
	var text_rect := Rect2(
		rect.position + Vector2(TITLE_BUTTON_ICON_SIZE + TITLE_BUTTON_GAP, 0.0),
		Vector2(rect.size.x - TITLE_BUTTON_ICON_SIZE - TITLE_BUTTON_GAP, rect.size.y)
	)
	draw_text_centered(text_rect, "TITLE", TITLE_BUTTON_FONT_SIZE, color)


func draw_selected_level_name() -> void:
	var level_name := selected_level_name()
	if level_name == "":
		return
	draw_text_centered(
		selected_level_name_rect(),
		level_name,
		LEVEL_NAME_FONT_SIZE,
		palette["text_hi"]
	)


func draw_hovered_level_name() -> void:
	if hovered_index == -1 or hovered_index == selected_index:
		return
	var page: Array = current_page_entries()
	if hovered_index >= page.size():
		return
	var entry: Dictionary = page[hovered_index]
	var level_name := String(entry["name"]).to_upper()
	draw_text_centered(
		selected_level_name_rect_for(hovered_index, get_viewport_rect().size),
		level_name,
		LEVEL_NAME_FONT_SIZE,
		palette["text"]
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
	var border_width := 2.0

	if not unlocked:
		floor_color.a = 0.18
		border_color.a = LOCKED_ALPHA
	elif completed:
		border_color = COMPLETED_COLOR
		border_width = 3.0
	else:
		border_color = palette["label"]

	if completed and not selected:
		draw_soft_outline_glow(rect, COMPLETED_COLOR, COMPLETED_GLOW_ALPHA)
	draw_rect(rect, floor_color)
	ThumbnailRenderer.draw(
		self,
		entry["thumbnail_data"],
		rect,
		palette,
		1.0 if unlocked else LOCKED_ALPHA,
		completed
	)
	draw_rect(rect, border_color, false, border_width)
	if selected:
		draw_rect(
			rect.grow(SELECT_FRAME_GROW),
			palette["player"],
			false,
			SELECT_FRAME_WIDTH
		)
	elif index == hovered_index and unlocked:
		draw_rect(
			rect.grow(HOVER_FRAME_GROW),
			palette["text"],
			false,
			HOVER_FRAME_WIDTH
		)


func draw_soft_outline_glow(rect: Rect2, color: Color, alpha: float) -> void:
	var outer_color := color
	outer_color.a = alpha * 0.45
	draw_rect(rect.grow(6.0), outer_color, false, 5.0)
	var inner_color := color
	inner_color.a = alpha
	draw_rect(rect.grow(3.0), inner_color, false, 3.0)


func draw_area_arrows() -> void:
	var viewport_size := get_viewport_rect().size
	var center_y := area_arrow_center_y()
	var margin := side_margin()
	var left_color: Color = palette["text_dim"]
	var right_color: Color = palette["text_dim"]
	if current_area_index == 0:
		left_color.a = 0.16
	elif area_arrow_hovered == Vector2i.LEFT:
		left_color = palette["text"]
	if (
		current_area_index >= area_entries.size() - 1
		or not is_area_accessible(current_area_index + 1)
	):
		right_color.a = 0.16
	elif area_arrow_hovered == Vector2i.RIGHT:
		right_color = palette["text"]
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
	for index in range(points.size()):
		points[index] *= AREA_ARROW_SCALE
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


func is_cancel_key(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE


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
