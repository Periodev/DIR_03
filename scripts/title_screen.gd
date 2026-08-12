class_name DirTitleScreen
extends Node2D

const VisualStyle = preload("res://scripts/visual_style.gd")

const TITLE_FONT_SIZE := 64
const OPTION_FONT_SIZE := 28
const GRID_SPACING := 96.0
const MENU_CELL_SIZE := 288.0
const MENU_CENTER_Y_RATIO := 0.61
const TITLE_CONTENT_OFFSET_Y := -40.0
const HORIZONTAL_OPTION_DISTANCE := 290.0
const VERTICAL_OPTION_DISTANCE := 235.0
const OPTION_BOX_SIZE := Vector2(200.0, 72.0)
const OPTION_BOX_WIDTH := 1.0
const HOVER_OPTION_BOX_WIDTH := 2.0
const SELECTED_OPTION_BOX_WIDTH := 3.0
const MAIN_OPTION_OFFSETS := {
	Vector2i.UP: Vector2.UP * VERTICAL_OPTION_DISTANCE,
	Vector2i.LEFT: Vector2.LEFT * HORIZONTAL_OPTION_DISTANCE,
	Vector2i.RIGHT: Vector2.RIGHT * HORIZONTAL_OPTION_DISTANCE,
	Vector2i.DOWN: Vector2.DOWN * VERTICAL_OPTION_DISTANCE,
}
const CONFIRM_HOLD_SECONDS := 0.16
const CONFIG_OPTION_BOX_SIZE := Vector2(360.0, 64.0)
const CONFIG_OPTION_GAP := 78.0
const CONFIG_PANEL_OFFSET_X := 370.0
const INFO_PANEL_OFFSET_X := 370.0
const CONFIG_AUDIO_STEP := 10
const AUDIO_SLIDER_SIZE := Vector2(128.0, 8.0)
const AUDIO_SLIDER_FILL_HEIGHT := 14.0
const CONFIG_ACTION_RETREAT := 12.0
const CONFIG_ACTION_EXTEND := 12.0
const CONFIG_ACTION_RETREAT_SECONDS := 0.030
const CONFIG_ACTION_HOLD_SECONDS := 0.020
const CONFIG_ACTION_EXTEND_SECONDS := 0.050
const CONFIG_ACTION_RETURN_SECONDS := 0.030

enum MenuMode {
	MAIN,
	CONFIG,
	INFO,
}

var palette: Dictionary = VisualStyle.theme(false)
var ui_font: Font
var selected_direction := Vector2i.UP
var stored_direction := Vector2i.ZERO
var activation_locked := false
var menu_mode := MenuMode.MAIN
var config_index := 0
var config_action_offset := 0.0:
	set(value):
		config_action_offset = value
		queue_redraw()
var config_action_tween: Tween
var config_action_callback := Callable()
var hovered_config_index := -1
var info_back_hovered := false


func _ready() -> void:
	ui_font = ThemeDB.fallback_font
	if Campaign.is_single_level_mode():
		call_deferred("open_single_level_test")
		return
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()


func open_single_level_test() -> void:
	SceneTransition.transition_to("res://scenes/main.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if SceneTransition.is_active() or activation_locked:
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
		if menu_mode == MenuMode.CONFIG:
			play_config_action(leave_config)
		elif menu_mode == MenuMode.INFO:
			play_config_action(leave_info)
		return
	if is_unlock_extra_key(event):
		Campaign.unlock_all_levels()
		queue_redraw()
		return
	if menu_mode == MenuMode.CONFIG:
		handle_config_input(event)
		return
	if menu_mode == MenuMode.INFO:
		handle_info_input(event)
		return

	if event.is_action_pressed("move_up"):
		select_direction(Vector2i.UP)
	elif event.is_action_pressed("move_left"):
		select_direction(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		select_direction(Vector2i.RIGHT)
	elif event.is_action_pressed("move_down"):
		select_direction(Vector2i.DOWN)
	elif is_confirm_key(event):
		activate_selection()


func handle_config_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		config_index = posmod(config_index - 1, 4)
		queue_redraw()
	elif event.is_action_pressed("move_down"):
		config_index = posmod(config_index + 1, 4)
		queue_redraw()
	elif event.is_action_pressed("move_left"):
		adjust_config(-1)
	elif event.is_action_pressed("move_right"):
		adjust_config(1)
	elif is_confirm_key(event):
		adjust_config(1)


func handle_info_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_right") or is_confirm_key(event):
		play_config_action(leave_info)


func handle_mouse_motion(pos: Vector2) -> void:
	match menu_mode:
		MenuMode.MAIN:
			for direction in MAIN_OPTION_OFFSETS:
				if direction == Vector2i.DOWN and not extra_unlocked():
					continue
				if main_option_rect(direction).has_point(pos):
					select_direction(direction)
					break
		MenuMode.CONFIG:
			var new_index := -1
			for index in 4:
				if config_option_rect(index).has_point(pos):
					new_index = index
					break
			if new_index != hovered_config_index:
				hovered_config_index = new_index
				queue_redraw()
		MenuMode.INFO:
			var hovered := info_back_rect().has_point(pos)
			if hovered != info_back_hovered:
				info_back_hovered = hovered
				queue_redraw()


func handle_mouse_click(pos: Vector2) -> void:
	match menu_mode:
		MenuMode.MAIN:
			for direction in MAIN_OPTION_OFFSETS:
				if direction == Vector2i.DOWN and not extra_unlocked():
					continue
				if main_option_rect(direction).has_point(pos):
					select_direction(direction)
					activate_selection()
					return
		MenuMode.CONFIG:
			for index in 4:
				if config_option_rect(index).has_point(pos):
					config_index = index
					if index == 2:
						queue_redraw()
					else:
						adjust_config(1)
					return
		MenuMode.INFO:
			if info_back_rect().has_point(pos):
				play_config_action(leave_info)


func reset_hover_state() -> void:
	hovered_config_index = -1
	info_back_hovered = false


func compute_menu_center() -> Vector2:
	var viewport_rect := get_viewport_rect()
	return Vector2(
		viewport_rect.get_center().x,
		viewport_rect.size.y * MENU_CENTER_Y_RATIO + TITLE_CONTENT_OFFSET_Y
	)


func main_option_rect(direction: Vector2i) -> Rect2:
	var offset: Vector2 = MAIN_OPTION_OFFSETS[direction]
	var center: Vector2 = compute_menu_center() + offset
	return Rect2(center - OPTION_BOX_SIZE / 2.0, OPTION_BOX_SIZE)


func config_list_center() -> Vector2:
	var center := compute_menu_center()
	return Vector2(center.x + CONFIG_PANEL_OFFSET_X, center.y - CONFIG_OPTION_GAP * 0.5)


func config_option_rect(index: int) -> Rect2:
	var center := config_list_center() + Vector2(0.0, (float(index) - 1.5) * CONFIG_OPTION_GAP)
	return Rect2(center - CONFIG_OPTION_BOX_SIZE / 2.0, CONFIG_OPTION_BOX_SIZE)


func info_back_rect() -> Rect2:
	var panel_center := compute_menu_center() + Vector2.LEFT * INFO_PANEL_OFFSET_X
	var center := panel_center + Vector2(0.0, 145.0)
	return Rect2(center - CONFIG_OPTION_BOX_SIZE / 2.0, CONFIG_OPTION_BOX_SIZE)


func select_direction(direction: Vector2i) -> void:
	if selected_direction == direction:
		return
	selected_direction = direction
	queue_redraw()


func activate_selection() -> void:
	if selected_direction == Vector2i.DOWN and not extra_unlocked():
		return
	play_config_action(confirm_selection_after_action)


func confirm_selection_after_action() -> void:
	stored_direction = selected_direction
	queue_redraw()
	if selected_direction == Vector2i.UP:
		activation_locked = true
		await get_tree().create_timer(CONFIRM_HOLD_SECONDS).timeout
		Campaign.set_level_select_scene(Campaign.CLASSIC_LEVEL_SELECT_SCENE_PATH)
		SceneTransition.transition_to(Campaign.CLASSIC_LEVEL_SELECT_SCENE_PATH)
	elif selected_direction == Vector2i.RIGHT:
		activation_locked = true
		await get_tree().create_timer(CONFIRM_HOLD_SECONDS).timeout
		menu_mode = MenuMode.CONFIG
		config_index = 0
		reset_hover_state()
		activation_locked = false
		queue_redraw()
	elif selected_direction == Vector2i.LEFT:
		activation_locked = true
		await get_tree().create_timer(CONFIRM_HOLD_SECONDS).timeout
		menu_mode = MenuMode.INFO
		reset_hover_state()
		activation_locked = false
		queue_redraw()
	elif selected_direction == Vector2i.DOWN:
		activation_locked = true
		await get_tree().create_timer(CONFIRM_HOLD_SECONDS).timeout
		SceneTransition.transition_to(Campaign.EXTRA_MODE_SCENE_PATH)


func adjust_config(delta: int) -> void:
	match config_index:
		0:
			toggle_fullscreen()
			play_config_action()
		1:
			Campaign.grid_lines_visible = not Campaign.grid_lines_visible
			play_config_action()
		2:
			Campaign.set_audio_volume(
				Campaign.audio_volume_percent + delta * CONFIG_AUDIO_STEP
			)
			play_config_action()
		3:
			play_config_action(leave_config)
	queue_redraw()


func play_config_action(on_finished := Callable()) -> void:
	if config_action_tween and config_action_tween.is_valid():
		config_action_tween.kill()
	activation_locked = true
	config_action_callback = on_finished
	config_action_offset = 0.0
	config_action_tween = create_tween()
	config_action_tween.set_trans(Tween.TRANS_QUAD)
	config_action_tween.set_ease(Tween.EASE_OUT)
	config_action_tween.tween_property(
		self,
		"config_action_offset",
		-CONFIG_ACTION_RETREAT,
		CONFIG_ACTION_RETREAT_SECONDS
	)
	config_action_tween.tween_interval(CONFIG_ACTION_HOLD_SECONDS)
	config_action_tween.tween_property(
		self,
		"config_action_offset",
		CONFIG_ACTION_EXTEND,
		CONFIG_ACTION_EXTEND_SECONDS
	)
	config_action_tween.tween_property(
		self,
		"config_action_offset",
		0.0,
		CONFIG_ACTION_RETURN_SECONDS
	)
	config_action_tween.finished.connect(finish_config_action)


func finish_config_action() -> void:
	activation_locked = false
	var callback := config_action_callback
	config_action_callback = Callable()
	if callback.is_valid():
		callback.call()


func toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	var next_mode := DisplayServer.WINDOW_MODE_FULLSCREEN
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		next_mode = DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(next_mode)


func leave_config() -> void:
	menu_mode = MenuMode.MAIN
	selected_direction = Vector2i.RIGHT
	config_action_offset = 0.0
	reset_hover_state()
	queue_redraw()


func leave_info() -> void:
	menu_mode = MenuMode.MAIN
	selected_direction = Vector2i.LEFT
	config_action_offset = 0.0
	reset_hover_state()
	queue_redraw()


func is_confirm_key(event: InputEvent) -> bool:
	if event.is_action_pressed("trigger_vector"):
		return true
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return key_event.pressed and key_event.keycode in [KEY_ENTER, KEY_KP_ENTER]


func is_cancel_key(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return key_event.pressed and key_event.keycode == KEY_ESCAPE


func is_unlock_extra_key(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return key_event.pressed and not key_event.echo and key_event.keycode == KEY_F2


func extra_unlocked() -> bool:
	if Campaign.all_levels_unlocked:
		return true
	for area_value in Campaign.AREAS.values():
		var area: Dictionary = area_value
		var levels: Array = area["levels"]
		for level_value in levels:
			var level: Dictionary = level_value
			if not Campaign.is_completed(String(level["id"])):
				return false
	return true


func _draw() -> void:
	var viewport_rect := get_viewport_rect()
	draw_rect(viewport_rect, palette["app_bg"])
	draw_background_grid(viewport_rect)

	var menu_center := Vector2(
		viewport_rect.get_center().x,
		viewport_rect.size.y * MENU_CENTER_Y_RATIO + TITLE_CONTENT_OFFSET_Y
	)
	draw_centered_text(
		Vector2(
			viewport_rect.get_center().x,
			viewport_rect.size.y * 0.16 + TITLE_CONTENT_OFFSET_Y
		),
		"DIR",
		TITLE_FONT_SIZE,
		palette["text_hi"]
	)
	if menu_mode == MenuMode.CONFIG:
		draw_config_menu(menu_center)
	elif menu_mode == MenuMode.INFO:
		draw_info_menu(menu_center)
	else:
		draw_main_menu(menu_center)


func draw_main_menu(menu_center: Vector2) -> void:
	draw_option("START", menu_center + MAIN_OPTION_OFFSETS[Vector2i.UP], Vector2i.UP)
	draw_option("INFO", menu_center + MAIN_OPTION_OFFSETS[Vector2i.LEFT], Vector2i.LEFT)
	draw_option("CONFIG", menu_center + MAIN_OPTION_OFFSETS[Vector2i.RIGHT], Vector2i.RIGHT)
	draw_option(
		"EXTRA",
		menu_center + MAIN_OPTION_OFFSETS[Vector2i.DOWN],
		Vector2i.DOWN,
		extra_unlocked()
	)
	draw_player_mark(menu_center)


func draw_config_menu(menu_center: Vector2) -> void:
	draw_player_mark(menu_center)
	var labels: Array[String] = [
		"FULLSCREEN  %s" % fullscreen_label(),
		"GRID  %s" % ("ON" if Campaign.grid_lines_visible else "OFF"),
		"AUDIO",
		"BACK",
	]
	var list_center := Vector2(
		menu_center.x + CONFIG_PANEL_OFFSET_X,
		menu_center.y - CONFIG_OPTION_GAP * 0.5
	)
	for index in labels.size():
		var center := list_center + Vector2(0.0, (float(index) - 1.5) * CONFIG_OPTION_GAP)
		if index == 2:
			draw_audio_option(center, index == config_index, index == hovered_config_index)
		else:
			draw_config_option(
				labels[index],
				center,
				index == config_index,
				index == hovered_config_index
			)


func draw_info_menu(menu_center: Vector2) -> void:
	draw_player_mark(menu_center)
	var panel_center := menu_center + Vector2.LEFT * INFO_PANEL_OFFSET_X
	draw_centered_text(panel_center + Vector2(0.0, -145.0), "INFO", 34, palette["text_hi"])
	draw_centered_text(
		panel_center + Vector2(0.0, -82.0),
		"A DIRECTIONAL BLOCK PUZZLE",
		20,
		palette["text"]
	)
	draw_centered_text(
		panel_center + Vector2(0.0, -24.0),
		"BUILT WITH GODOT ENGINE",
		18,
		palette["text_dim"]
	)
	draw_centered_text(
		panel_center + Vector2(0.0, 18.0),
		"UI ASSETS BY KENNEY",
		18,
		palette["text_dim"]
	)
	draw_centered_text(
		panel_center + Vector2(0.0, 60.0),
		"PROTOTYPE BUILD",
		18,
		palette["text_dim"]
	)
	draw_config_option("BACK", panel_center + Vector2(0.0, 145.0), true, info_back_hovered)


func fullscreen_label() -> String:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return "ON"
	return "OFF"


func draw_config_option(
	text: String,
	center: Vector2,
	selected: bool,
	hovered: bool = false
) -> void:
	var frame_color: Color = palette["hair"]
	var text_color: Color = palette["text"]
	var frame_width := OPTION_BOX_WIDTH
	if selected:
		frame_color = palette["text_hi"]
		text_color = palette["text_hi"]
		frame_width = SELECTED_OPTION_BOX_WIDTH
	elif hovered:
		frame_color = palette["text"]
		frame_width = HOVER_OPTION_BOX_WIDTH
	draw_rect(
		Rect2(center - CONFIG_OPTION_BOX_SIZE / 2.0, CONFIG_OPTION_BOX_SIZE),
		frame_color,
		false,
		frame_width
	)
	draw_centered_text(center, text, OPTION_FONT_SIZE, text_color)


func draw_audio_option(center: Vector2, selected: bool, hovered: bool = false) -> void:
	var frame_color: Color = palette["hair"]
	var text_color: Color = palette["text"]
	var frame_width := OPTION_BOX_WIDTH
	if selected:
		frame_color = palette["text_hi"]
		text_color = palette["text_hi"]
		frame_width = SELECTED_OPTION_BOX_WIDTH
	elif hovered:
		frame_color = palette["text"]
		frame_width = HOVER_OPTION_BOX_WIDTH
	draw_rect(
		Rect2(center - CONFIG_OPTION_BOX_SIZE / 2.0, CONFIG_OPTION_BOX_SIZE),
		frame_color,
		false,
		frame_width
	)
	draw_centered_text(center + Vector2(-118.0, 0.0), "AUDIO", OPTION_FONT_SIZE, text_color)

	var slider_center := center + Vector2(32.0, 0.0)
	var slider_rect := Rect2(slider_center - AUDIO_SLIDER_SIZE / 2.0, AUDIO_SLIDER_SIZE)
	draw_rect(slider_rect, palette["hair"])
	var fill_ratio := float(Campaign.audio_volume_percent) / 100.0
	var fill_size := Vector2(AUDIO_SLIDER_SIZE.x * fill_ratio, AUDIO_SLIDER_FILL_HEIGHT)
	var fill_rect := Rect2(
		Vector2(slider_rect.position.x, slider_center.y - AUDIO_SLIDER_FILL_HEIGHT / 2.0),
		fill_size
	)
	draw_rect(fill_rect, text_color)
	draw_centered_text(
		center + Vector2(137.0, 0.0),
		str(Campaign.audio_volume_percent),
		OPTION_FONT_SIZE - 4,
		text_color
	)


func draw_background_grid(rect: Rect2) -> void:
	var grid_color: Color = palette["grid"]
	grid_color.a *= 0.28
	var x := rect.position.x
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), grid_color)
		x += GRID_SPACING
	var y := rect.position.y
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), grid_color)
		y += GRID_SPACING


func draw_option(
	text: String,
	center: Vector2,
	direction: Vector2i,
	enabled: bool = true
) -> void:
	var color: Color = palette["text"]
	var frame_color: Color = palette["hair"]
	var frame_width := OPTION_BOX_WIDTH
	if direction == selected_direction:
		color = palette["text_hi"]
		frame_color = palette["text_hi"]
		frame_width = SELECTED_OPTION_BOX_WIDTH
	if not enabled:
		color = palette["text_dim"]
		color.a *= 0.55
		frame_color = color
	var option_rect := Rect2(center - OPTION_BOX_SIZE / 2.0, OPTION_BOX_SIZE)
	draw_rect(option_rect, frame_color, false, frame_width)
	draw_centered_text(center, text, OPTION_FONT_SIZE, color)


func diamond_points(center: Vector2, radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	])


func draw_player_mark(center: Vector2) -> void:
	var body_radius := MENU_CELL_SIZE * VisualStyle.PLAYER_BODY_RATIO / 2.0
	var edge_width := maxf(1.0, MENU_CELL_SIZE * VisualStyle.PLAYER_EDGE_RATIO)
	draw_colored_polygon(
		diamond_points(center, body_radius + edge_width),
		palette["block_edge"]
	)
	draw_colored_polygon(diamond_points(center, body_radius), palette["player"])
	draw_player_facing(center)
	if stored_direction == Vector2i.ZERO:
		return

	var forward := Vector2(stored_direction)
	var triangle_center := (
		center
		+ forward * MENU_CELL_SIZE * VisualStyle.STORED_VECTOR_OFFSET_RATIO
	)
	var side := Vector2(-forward.y, forward.x)
	var triangle_height := MENU_CELL_SIZE * VisualStyle.PLAYER_TRI_H_RATIO
	var triangle_width := triangle_height * 2.0
	var tip := triangle_center + forward * triangle_height / 2.0
	var base_center := triangle_center - forward * triangle_height / 2.0
	draw_colored_polygon(PackedVector2Array([
		tip,
		base_center + side * triangle_width / 2.0,
		base_center - side * triangle_width / 2.0,
	]), palette["direction_fill"])


func draw_player_facing(center: Vector2) -> void:
	var forward := Vector2(selected_direction)
	var chevron_center := (
		center
		+ forward * (
			MENU_CELL_SIZE / 2.0
			- MENU_CELL_SIZE * VisualStyle.FACING_CHV_INSET_RATIO
			+ config_action_offset
		)
	)
	var length := MENU_CELL_SIZE * VisualStyle.FACING_CHV_LEN_RATIO
	var depth := MENU_CELL_SIZE * VisualStyle.FACING_CHV_DEPTH_RATIO
	var stroke := depth * VisualStyle.FACING_CHV_STROKE_RATIO
	var outline := maxf(1.0, MENU_CELL_SIZE * VisualStyle.FACING_CHV_OUTLINE_RATIO)
	var base_points := chevron_points(chevron_center, forward, length, depth, stroke)
	draw_colored_polygon(
		scale_points_from(base_points, chevron_center, (depth + outline * 2.0) / depth),
		palette["direction_fill"]
	)
	draw_colored_polygon(base_points, palette["player"])


func chevron_points(
	center: Vector2,
	forward: Vector2,
	length: float,
	depth: float,
	stroke: float
) -> PackedVector2Array:
	var side := Vector2(-forward.y, forward.x)
	var back_center := center - forward * depth / 2.0
	var outer_tip := center + forward * depth / 2.0
	var inner_tip := outer_tip - forward * stroke
	var outer_half_length := length / 2.0
	var inner_half_length := maxf(1.0, outer_half_length - stroke)
	return PackedVector2Array([
		back_center - side * outer_half_length,
		back_center - side * inner_half_length,
		inner_tip,
		back_center + side * inner_half_length,
		back_center + side * outer_half_length,
		outer_tip,
	])


func scale_points_from(
	points: PackedVector2Array,
	origin: Vector2,
	scale_factor: float
) -> PackedVector2Array:
	var scaled := PackedVector2Array()
	scaled.resize(points.size())
	for index in range(points.size()):
		scaled[index] = origin + (points[index] - origin) * scale_factor
	return scaled


func draw_centered_text(
	center: Vector2,
	text: String,
	font_size: int,
	color: Color
) -> void:
	var text_size := ui_font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	)
	var baseline := Vector2(
		center.x - text_size.x / 2.0,
		center.y
		+ ui_font.get_ascent(font_size) / 2.0
		- ui_font.get_descent(font_size) / 2.0
	)
	draw_string(
		ui_font,
		baseline,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color
	)
