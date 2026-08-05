class_name DirPlayerBoardView
extends Control

const VisualStyle = preload("res://scripts/visual_style.gd")

const DISPLACEMENT_NONE := 0
const DISPLACEMENT_PLAYER := 1
const DISPLACEMENT_BLOCK := 2
const ERROR_FLASH_NONE := 0
const ERROR_FLASH_PLAYER := 1
const ERROR_FLASH_BLOCK := 2

var game_board
var cell_size := float(VisualStyle.PLAYER_CELL_SIZE)
var light_theme := false
var grid_lines_visible := VisualStyle.SHOW_GRID_LINES
var palette: Dictionary = {}
var fallback_font: Font
var facing_action_offset_ratio := 0.0
var facing_action_tween: Tween
var displacement_subject := DISPLACEMENT_NONE
var displacement_block_id := -1
var displacement_from := Vector2i.ZERO
var displacement_to := Vector2i.ZERO
var displacement_progress := 0.0
var displacement_tween: Tween
var displacement_finished: Callable = Callable()
var trigger_flash_block_id := -1
var trigger_flash_direction := ""
var trigger_flash_mix := 0.0
var trigger_flash_alpha := 0.0
var collision_carrier_block_id := -1
var collision_direction := ""
var collision_source_offset_ratio := 0.0
var blocked_release_block_id := -1
var blocked_release_direction := ""
var blocked_release_offset_ratio := 0.0
var install_reveal_block_id := -1
var player_queue_reveal_pending := false
var error_flash_subject := ERROR_FLASH_NONE
var error_flash_cell := Vector2i(-1, -1)
var error_flash_alpha := 0.0
var error_flash_tween: Tween
var error_flash_color_key := "error_flash"
var error_flash_max_alpha := VisualStyle.ERROR_FLASH_MAX_ALPHA
var active_vector_pulse_block_id := -1
var active_vector_pulse_elapsed := 0.0
var install_tutorial_hint_cell := Vector2i(-1, -1)
var install_tutorial_hint_elapsed := 0.0
var release_tutorial_hint_cell := Vector2i(-1, -1)
var release_tutorial_hint_elapsed := 0.0
var completion_pulse_progress := -1.0
var completion_pulse_tween: Tween


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


func _process(delta: float) -> void:
	update_active_vector_pulse(delta)
	update_install_tutorial_hint(delta)
	update_release_tutorial_hint(delta)


func set_light_theme(enabled: bool) -> void:
	light_theme = enabled
	palette = VisualStyle.theme(light_theme)
	queue_redraw()


func set_cell_size(value: float) -> void:
	cell_size = maxf(16.0, value)
	refresh_layout_size()
	queue_redraw()


func play_facing_action() -> void:
	if facing_action_tween != null and facing_action_tween.is_valid():
		facing_action_tween.kill()

	facing_action_offset_ratio = 0.0
	facing_action_tween = create_tween()
	facing_action_tween.tween_method(
		set_facing_action_offset_ratio,
		0.0,
		-VisualStyle.FACING_ACTION_RETREAT_RATIO,
		VisualStyle.FACING_ACTION_RETREAT_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	facing_action_tween.tween_interval(
		VisualStyle.FACING_ACTION_HOLD_SECONDS
	)
	facing_action_tween.tween_method(
		set_facing_action_offset_ratio,
		-VisualStyle.FACING_ACTION_RETREAT_RATIO,
		VisualStyle.FACING_ACTION_FORWARD_RATIO,
		VisualStyle.FACING_ACTION_FORWARD_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	facing_action_tween.tween_method(
		set_facing_action_offset_ratio,
		VisualStyle.FACING_ACTION_FORWARD_RATIO,
		0.0,
		VisualStyle.FACING_ACTION_SETTLE_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func set_facing_action_offset_ratio(value: float) -> void:
	facing_action_offset_ratio = value
	queue_redraw()


func set_grid_lines_visible(lines_visible: bool) -> void:
	grid_lines_visible = lines_visible
	queue_redraw()


func play_completion_feedback() -> void:
	reset_completion_feedback()
	completion_pulse_tween = create_tween()
	completion_pulse_tween.tween_interval(
		VisualStyle.COMPLETION_PULSE_DELAY_SECONDS
	)
	completion_pulse_tween.tween_callback(begin_completion_pulse)
	completion_pulse_tween.tween_method(
		set_completion_pulse_progress,
		0.0,
		1.0,
		VisualStyle.COMPLETION_PULSE_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	completion_pulse_tween.tween_callback(finish_completion_pulse)


func begin_completion_pulse() -> void:
	completion_pulse_progress = 0.0
	queue_redraw()


func reset_completion_feedback() -> void:
	if completion_pulse_tween != null and completion_pulse_tween.is_valid():
		completion_pulse_tween.kill()
	completion_pulse_tween = null
	completion_pulse_progress = -1.0
	queue_redraw()


func set_completion_pulse_progress(value: float) -> void:
	completion_pulse_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func finish_completion_pulse() -> void:
	completion_pulse_tween = null
	completion_pulse_progress = -1.0
	queue_redraw()


func play_player_error_flash(cell: Vector2i) -> void:
	play_error_flash(
		ERROR_FLASH_PLAYER,
		cell,
		"error_flash",
		VisualStyle.ERROR_FLASH_MAX_ALPHA,
		VisualStyle.ERROR_FLASH_SECONDS
	)


func play_block_error_flash(cell: Vector2i) -> void:
	play_error_flash(
		ERROR_FLASH_BLOCK,
		cell,
		"error_flash",
		VisualStyle.ERROR_FLASH_MAX_ALPHA,
		VisualStyle.ERROR_FLASH_SECONDS
	)


func play_block_hint_flash(cell: Vector2i) -> void:
	play_error_flash(
		ERROR_FLASH_BLOCK,
		cell,
		"hint_flash",
		VisualStyle.HINT_FLASH_MAX_ALPHA,
		VisualStyle.HINT_FLASH_SECONDS
	)


func play_error_flash(
	subject: int,
	cell: Vector2i,
	color_key: String,
	max_alpha: float,
	duration: float
) -> void:
	cancel_error_cell_flash()
	error_flash_subject = subject
	error_flash_cell = cell
	error_flash_color_key = color_key
	error_flash_max_alpha = max_alpha
	error_flash_alpha = max_alpha
	error_flash_tween = create_tween()
	error_flash_tween.tween_method(
		set_error_flash_alpha,
		max_alpha,
		0.0,
		duration
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	error_flash_tween.tween_callback(clear_error_cell_flash)
	queue_redraw()


func set_error_flash_alpha(value: float) -> void:
	error_flash_alpha = clampf(value, 0.0, error_flash_max_alpha)
	queue_redraw()


func clear_error_cell_flash() -> void:
	error_flash_tween = null
	error_flash_subject = ERROR_FLASH_NONE
	error_flash_cell = Vector2i(-1, -1)
	error_flash_alpha = 0.0
	error_flash_color_key = "error_flash"
	error_flash_max_alpha = VisualStyle.ERROR_FLASH_MAX_ALPHA
	queue_redraw()


func cancel_error_cell_flash() -> void:
	if error_flash_tween != null and error_flash_tween.is_valid():
		error_flash_tween.kill()
	clear_error_cell_flash()


func play_install_reveal(block_id: int, on_finished: Callable) -> void:
	cancel_displacement()
	install_reveal_block_id = block_id
	displacement_finished = on_finished
	displacement_tween = create_tween()
	displacement_tween.tween_interval(
		VisualStyle.INSTALL_VECTOR_DELAY_SECONDS
	)
	displacement_tween.tween_callback(reveal_installed_vector)
	displacement_tween.tween_interval(
		VisualStyle.FACING_ACTION_SETTLE_SECONDS
	)
	displacement_tween.tween_callback(finish_displacement)
	queue_redraw()


func reveal_installed_vector() -> void:
	install_reveal_block_id = -1
	queue_redraw()


func play_player_displacement(
	from_cell: Vector2i,
	to_cell: Vector2i,
	on_finished: Callable
) -> void:
	prepare_displacement(
		DISPLACEMENT_PLAYER,
		-1,
		from_cell,
		to_cell,
		on_finished
	)
	start_displacement_tween(Tween.TRANS_SINE, Tween.EASE_IN_OUT)


func play_block_displacement(
	block_id: int,
	from_cell: Vector2i,
	to_cell: Vector2i,
	player_queue_changed: bool,
	on_finished: Callable
) -> void:
	prepare_displacement(
		DISPLACEMENT_BLOCK,
		block_id,
		from_cell,
		to_cell,
		on_finished
	)
	player_queue_reveal_pending = player_queue_changed
	displacement_tween = create_tween()
	displacement_tween.tween_interval(
		VisualStyle.PUSH_DISPLACEMENT_DELAY_SECONDS
	)
	if player_queue_changed:
		displacement_tween.tween_callback(reveal_player_queue)
	displacement_tween.tween_method(
		set_displacement_progress,
		0.0,
		1.0,
		VisualStyle.DISPLACEMENT_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	displacement_tween.tween_callback(finish_displacement)


func reveal_player_queue() -> void:
	player_queue_reveal_pending = false
	queue_redraw()


func play_trigger_displacement(
	carrier_id: int,
	direction_name: String,
	moving_block_id: int,
	from_cell: Vector2i,
	to_cell: Vector2i,
	on_finished: Callable
) -> void:
	prepare_displacement(
		DISPLACEMENT_BLOCK,
		moving_block_id,
		from_cell,
		to_cell,
		on_finished
	)
	trigger_flash_block_id = carrier_id
	trigger_flash_direction = direction_name
	trigger_flash_mix = 0.0
	trigger_flash_alpha = 1.0
	var is_collision := carrier_id != moving_block_id
	var is_blocked_release := (
		carrier_id == moving_block_id
		and from_cell == to_cell
	)
	collision_carrier_block_id = carrier_id if is_collision else -1
	collision_direction = direction_name if is_collision else ""
	collision_source_offset_ratio = 0.0
	blocked_release_block_id = carrier_id if is_blocked_release else -1
	blocked_release_direction = direction_name if is_blocked_release else ""
	blocked_release_offset_ratio = 0.0

	displacement_tween = create_tween()
	displacement_tween.tween_method(
		set_trigger_flash_mix,
		0.0,
		1.0,
		VisualStyle.TRIGGER_FLASH_IN_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	displacement_tween.tween_interval(VisualStyle.TRIGGER_FLASH_HOLD_SECONDS)
	if is_collision:
		displacement_tween.tween_method(
			set_collision_source_offset_ratio,
			0.0,
			VisualStyle.COLLISION_CONTACT_OFFSET_RATIO,
			VisualStyle.COLLISION_APPROACH_SECONDS
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		displacement_tween.tween_interval(VisualStyle.COLLISION_HOLD_SECONDS)
	if is_collision:
		displacement_tween.tween_method(
			set_collision_lead_progress,
			0.0,
			1.0,
			VisualStyle.COLLISION_TARGET_LEAD_SECONDS
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		displacement_tween.tween_method(
			set_collision_follow_progress,
			0.0,
			1.0,
			VisualStyle.COLLISION_TARGET_FOLLOW_SECONDS
		)
	elif is_blocked_release:
		displacement_tween.tween_method(
			set_blocked_release_shake_progress,
			0.0,
			1.0,
			VisualStyle.BLOCKED_RELEASE_SHAKE_SECONDS
		).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		displacement_tween.parallel().tween_method(
			set_trigger_flash_alpha,
			1.0,
			0.0,
			VisualStyle.BLOCKED_RELEASE_SHAKE_SECONDS
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		displacement_tween.tween_method(
			set_displacement_progress,
			0.0,
			1.0,
			VisualStyle.DISPLACEMENT_SECONDS
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		displacement_tween.parallel().tween_method(
			set_trigger_flash_alpha,
			1.0,
			0.0,
			VisualStyle.TRIGGER_FLASH_OUT_SECONDS
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	displacement_tween.tween_callback(finish_displacement)


func prepare_displacement(
	subject: int,
	block_id: int,
	from_cell: Vector2i,
	to_cell: Vector2i,
	on_finished: Callable
) -> void:
	cancel_displacement()
	displacement_subject = subject
	displacement_block_id = block_id
	displacement_from = from_cell
	displacement_to = to_cell
	displacement_progress = 0.0
	displacement_finished = on_finished
	queue_redraw()


func start_displacement_tween(
	transition: Tween.TransitionType,
	ease_type: Tween.EaseType
) -> void:
	displacement_tween = create_tween()
	displacement_tween.tween_method(
		set_displacement_progress,
		0.0,
		1.0,
		VisualStyle.DISPLACEMENT_SECONDS
	).set_trans(transition).set_ease(ease_type)
	displacement_tween.tween_callback(finish_displacement)


func cancel_displacement() -> void:
	cancel_error_cell_flash()
	if displacement_tween != null and displacement_tween.is_valid():
		displacement_tween.kill()
	clear_displacement_state()


func finish_displacement() -> void:
	var on_finished: Callable = displacement_finished
	clear_displacement_state()
	if on_finished.is_valid():
		on_finished.call()


func clear_displacement_state() -> void:
	displacement_tween = null
	displacement_subject = DISPLACEMENT_NONE
	displacement_block_id = -1
	displacement_from = Vector2i.ZERO
	displacement_to = Vector2i.ZERO
	displacement_progress = 0.0
	displacement_finished = Callable()
	trigger_flash_block_id = -1
	trigger_flash_direction = ""
	trigger_flash_mix = 0.0
	trigger_flash_alpha = 0.0
	collision_carrier_block_id = -1
	collision_direction = ""
	collision_source_offset_ratio = 0.0
	blocked_release_block_id = -1
	blocked_release_direction = ""
	blocked_release_offset_ratio = 0.0
	install_reveal_block_id = -1
	player_queue_reveal_pending = false
	queue_redraw()


func set_displacement_progress(value: float) -> void:
	displacement_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func set_trigger_flash_mix(value: float) -> void:
	trigger_flash_mix = clampf(value, 0.0, 1.0)
	queue_redraw()


func set_trigger_flash_alpha(value: float) -> void:
	trigger_flash_alpha = clampf(value, 0.0, 1.0)
	queue_redraw()


func set_collision_source_offset_ratio(value: float) -> void:
	collision_source_offset_ratio = clampf(
		value,
		0.0,
		VisualStyle.COLLISION_CONTACT_OFFSET_RATIO
	)
	queue_redraw()


func set_blocked_release_shake_progress(value: float) -> void:
	var progress := clampf(value, 0.0, 1.0)
	blocked_release_offset_ratio = (
		sin(progress * TAU * VisualStyle.BLOCKED_RELEASE_SHAKE_CYCLES)
		* (1.0 - progress)
		* VisualStyle.BLOCKED_RELEASE_SHAKE_RATIO
	)
	queue_redraw()


func set_collision_lead_progress(value: float) -> void:
	var progress := clampf(value, 0.0, 1.0)
	displacement_progress = (
		VisualStyle.COLLISION_TARGET_LEAD_RATIO * progress
	)
	update_collision_flash(
		progress * VisualStyle.COLLISION_TARGET_LEAD_SECONDS
	)
	queue_redraw()


func set_collision_follow_progress(value: float) -> void:
	var progress := clampf(value, 0.0, 1.0)
	var elapsed := progress * VisualStyle.COLLISION_TARGET_FOLLOW_SECONDS
	displacement_progress = lerpf(
		VisualStyle.COLLISION_TARGET_LEAD_RATIO,
		1.0,
		sin(progress * PI / 2.0)
	)
	var return_progress := clampf(
		elapsed / VisualStyle.COLLISION_RETURN_SECONDS,
		0.0,
		1.0
	)
	collision_source_offset_ratio = (
		VisualStyle.COLLISION_CONTACT_OFFSET_RATIO
		* (1.0 - sin(return_progress * PI / 2.0))
	)
	update_collision_flash(
		VisualStyle.COLLISION_TARGET_LEAD_SECONDS + elapsed
	)
	queue_redraw()


func update_collision_flash(elapsed: float) -> void:
	var flash_progress := clampf(
		elapsed / VisualStyle.TRIGGER_FLASH_OUT_SECONDS,
		0.0,
		1.0
	)
	trigger_flash_alpha = 1.0 - sin(flash_progress * PI / 2.0)


func _draw() -> void:
	if game_board == null or game_board.terrain.is_empty():
		return

	draw_ground()
	draw_wall_shadows()
	draw_walls()

	draw_goals()
	draw_blocks()
	draw_trigger_flash()
	draw_block_error_flash()
	draw_fences()
	draw_player_body()
	draw_player_error_flash()
	draw_player_stored_vector()
	draw_player_facing()
	draw_install_tutorial_hint()
	draw_release_tutorial_hint()
	draw_undo_tutorial_prompt()


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
			if grid_lines_visible:
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

	if grid_lines_visible:
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


func draw_goals() -> void:
	for cell in game_board.goal_cells:
		if is_goal_visually_occupied(cell):
			continue

		var inset := roundi(cell_size * VisualStyle.GOAL_INSET_RATIO)
		var goal_rect := Rect2(
			cell_to_position(cell) + Vector2(inset, inset),
			Vector2(cell_size - inset * 2, cell_size - inset * 2)
		)
		draw_dashed_shape(
			PackedVector2Array([
				goal_rect.position,
				Vector2(goal_rect.end.x, goal_rect.position.y),
				goal_rect.end,
				Vector2(goal_rect.position.x, goal_rect.end.y),
			]),
			palette["goal"]
		)


func draw_blocks() -> void:
	for block in game_board.blocks:
		var block_id: int = int(block["id"])
		if (
			displacement_subject == DISPLACEMENT_BLOCK
			and block_id == displacement_block_id
		):
			continue

		var cell: Vector2i = block["cell"]
		var block_position := cell_to_position(cell)
		if block_id == collision_carrier_block_id:
			block_position += (
				direction_vector(collision_direction)
				* cell_size
				* collision_source_offset_ratio
			)
		draw_block_at(block, block_position, cell)

	if displacement_subject != DISPLACEMENT_BLOCK:
		return

	var block_index: int = int(
		game_board.find_block_index_by_id(displacement_block_id)
	)
	if block_index == -1:
		return

	var moving_block: Dictionary = game_board.blocks[block_index]
	draw_block_at(
		moving_block,
		animated_cell_position(),
		displacement_from
	)


func draw_block_at(
	block: Dictionary,
	block_position: Vector2,
	occupied_cell: Vector2i
) -> void:
	var block_id: int = int(block["id"])
	var vector_name: String = block["vector"]
	var recovery_block: bool = game_board.is_recovery_block(block)
	var color: Color = palette["block"]
	var block_gap := roundi(cell_size * VisualStyle.BLOCK_INSET_RATIO)
	var block_rect := Rect2(
		block_position + Vector2(block_gap, block_gap),
		Vector2(cell_size - block_gap * 2, cell_size - block_gap * 2)
	)
	var edge_width := maxf(
		1.0,
		roundi(cell_size * VisualStyle.BLOCK_EDGE_RATIO)
	)
	var on_goal: bool = game_board.goal_cells.has(occupied_cell)
	var edge_color: Color = (
		palette["goal_complete"]
		if on_goal
		else palette["block_edge"]
	)
	draw_rect(block_rect, edge_color)
	draw_rect(block_rect.grow(-edge_width), color)
	if on_goal and completion_pulse_progress >= 0.0:
		draw_completion_pulse(block_rect, edge_width)

	if recovery_block:
		var marker_size := scaled_font_size(16)
		draw_text_at(
			block_rect.position + Vector2(
				scaled_px(4.0),
				block_rect.size.y - marker_size - scaled_px(3.0)
			),
			"↺",
			palette["block_glyph"],
			marker_size
		)
	if vector_name != "" and block_id != install_reveal_block_id:
		var vector_center := stored_vector_center(
			block_position + Vector2.ONE * cell_size / 2.0,
			vector_name
		)
		draw_direction_triangle(
			vector_center,
			vector_name,
			palette["direction_fill"]
		)
		if should_draw_active_vector_pulse(block_id):
			draw_active_vector_outline(vector_center, vector_name)


func draw_completion_pulse(block_rect: Rect2, edge_width: float) -> void:
	var progress := clampf(completion_pulse_progress, 0.0, 1.0)
	var expansion := (
		cell_size
		* VisualStyle.COMPLETION_PULSE_EXPAND_RATIO
		* sin(progress * PI / 2.0)
	)
	var pulse_color: Color = palette["goal_complete"]
	pulse_color.a *= 1.0 - progress
	draw_rect(
		block_rect.grow(expansion),
		pulse_color,
		false,
		edge_width,
		true
	)


func queued_release_block_id() -> int:
	if game_board == null or game_board.install_order.is_empty():
		return -1
	return int(game_board.install_order[0])


func should_draw_active_vector_pulse(block_id: int) -> bool:
	return (
		block_id == active_vector_pulse_block_id
		and block_id != install_reveal_block_id
		and trigger_flash_block_id == -1
		and active_vector_pulse_progress() >= 0.0
	)


func update_active_vector_pulse(delta: float) -> void:
	var queued_block_id: int = queued_release_block_id()
	var pulse_suppressed := (
		queued_block_id == -1
		or queued_block_id == install_reveal_block_id
		or trigger_flash_block_id != -1
	)
	if pulse_suppressed:
		if active_vector_pulse_block_id != -1:
			active_vector_pulse_block_id = -1
			active_vector_pulse_elapsed = 0.0
			queue_redraw()
		return

	if active_vector_pulse_block_id != queued_block_id:
		active_vector_pulse_block_id = queued_block_id
		active_vector_pulse_elapsed = 0.0
		queue_redraw()
		return

	var previous_progress := active_vector_pulse_progress()
	var cycle_seconds := (
		VisualStyle.ACTIVE_VECTOR_PULSE_SECONDS
		+ VisualStyle.ACTIVE_VECTOR_PULSE_PAUSE_SECONDS
	)
	active_vector_pulse_elapsed = fmod(
		active_vector_pulse_elapsed + delta,
		cycle_seconds
	)
	var current_progress := active_vector_pulse_progress()
	if previous_progress >= 0.0 or current_progress >= 0.0:
		queue_redraw()


func active_vector_pulse_progress() -> float:
	if active_vector_pulse_block_id == -1:
		return -1.0
	if active_vector_pulse_elapsed > VisualStyle.ACTIVE_VECTOR_PULSE_SECONDS:
		return -1.0
	return clampf(
		active_vector_pulse_elapsed / VisualStyle.ACTIVE_VECTOR_PULSE_SECONDS,
		0.0,
		1.0
	)


func draw_active_vector_outline(center: Vector2, direction_name: String) -> void:
	var progress := active_vector_pulse_progress()
	if progress < 0.0:
		return
	var points := direction_triangle_points(center, direction_name)
	if points.is_empty():
		return
	var color: Color = palette["active_vector_outline"]
	color.a = sin(progress * PI) * VisualStyle.ACTIVE_VECTOR_OUTLINE_ALPHA
	var stroke_width := maxf(
		1.0,
		roundi(cell_size * VisualStyle.ACTIVE_VECTOR_OUTLINE_WIDTH_RATIO)
	)
	draw_polyline(
		PackedVector2Array([points[0], points[1], points[2], points[0]]),
		color,
		stroke_width,
		true
	)


func is_goal_visually_occupied(goal_cell: Vector2i) -> bool:
	for block in game_board.blocks:
		var block_id: int = int(block["id"])
		if (
			displacement_subject == DISPLACEMENT_BLOCK
			and block_id == displacement_block_id
		):
			continue
		var block_cell: Vector2i = block["cell"]
		if block_cell == goal_cell:
			return true
	return false


func draw_trigger_flash() -> void:
	if trigger_flash_block_id == -1 or trigger_flash_direction == "":
		return

	var block_index: int = int(
		game_board.find_block_index_by_id(trigger_flash_block_id)
	)
	if block_index == -1:
		return

	var block: Dictionary = game_board.blocks[block_index]
	var block_cell: Vector2i = block["cell"]
	var flash_center := cell_center(block_cell)
	if trigger_flash_block_id == collision_carrier_block_id:
		flash_center += (
			direction_vector(collision_direction)
			* cell_size
			* collision_source_offset_ratio
		)
	if (
		displacement_subject == DISPLACEMENT_BLOCK
		and trigger_flash_block_id == displacement_block_id
	):
		flash_center = animated_cell_position() + Vector2.ONE * cell_size / 2.0
	flash_center = stored_vector_center(flash_center, trigger_flash_direction)
	var color: Color = palette["direction_fill"].lerp(
		palette["trigger_flash"],
		trigger_flash_mix
	)
	color.a *= trigger_flash_alpha
	draw_direction_triangle(
		flash_center,
		trigger_flash_direction,
		color
	)


func draw_player_body() -> void:
	var center := player_draw_center()
	draw_colored_polygon(
		player_body_points(center),
		palette["player"]
	)


func draw_player_error_flash() -> void:
	if error_flash_subject != ERROR_FLASH_PLAYER or error_flash_alpha <= 0.0:
		return
	var color: Color = palette[error_flash_color_key]
	color.a = error_flash_alpha
	draw_colored_polygon(
		player_body_points(cell_center(error_flash_cell)),
		color
	)


func draw_block_error_flash() -> void:
	if error_flash_subject != ERROR_FLASH_BLOCK or error_flash_alpha <= 0.0:
		return
	var block_gap := roundi(cell_size * VisualStyle.BLOCK_INSET_RATIO)
	var color: Color = palette[error_flash_color_key]
	color.a = error_flash_alpha
	draw_rect(
		Rect2(
			cell_to_position(error_flash_cell) + Vector2.ONE * block_gap,
			Vector2.ONE * (cell_size - block_gap * 2)
		),
		color
	)


func player_body_points(center: Vector2) -> PackedVector2Array:
	var body_size := roundi(cell_size * VisualStyle.PLAYER_BODY_RATIO)
	var chevron_depth := roundi(cell_size * VisualStyle.FACING_CHV_DEPTH_RATIO)
	var chevron_gap := maxf(
		2.0,
		roundi(cell_size * VisualStyle.FACING_CHV_GAP_RATIO)
	)
	var radius := minf(
		floorf(body_size / 2.0),
		cell_size / 2.0 - chevron_depth / 2.0 - chevron_gap
	)
	return PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0),
	])


func draw_player_stored_vector() -> void:
	if game_board.player_queue == "" or player_queue_reveal_pending:
		return

	draw_direction_triangle(
		stored_vector_center(player_draw_center(), game_board.player_queue),
		game_board.player_queue,
		palette["direction_fill"]
	)


func draw_player_facing() -> void:
	var forward := direction_vector(game_board.facing_name)
	if forward == Vector2.ZERO:
		return

	var center := (
		player_draw_center()
		+ forward * (
			cell_size / 2.0
			- cell_size * VisualStyle.FACING_CHV_INSET_RATIO
			+ cell_size * facing_action_offset_ratio
		)
	)
	var length := float(roundi(cell_size * VisualStyle.FACING_CHV_LEN_RATIO))
	var depth := float(roundi(cell_size * VisualStyle.FACING_CHV_DEPTH_RATIO))
	var stroke := float(roundi(depth * VisualStyle.FACING_CHV_STROKE_RATIO))
	var outline := maxf(
		1.0,
		roundi(cell_size * VisualStyle.FACING_CHV_OUTLINE_RATIO)
	)
	var clearance := maxf(
		2.0,
		roundi(cell_size * VisualStyle.FACING_CHV_CLEARANCE_RATIO)
	)
	var outer_padding := outline + clearance

	draw_colored_polygon(
		chevron_points(
			center,
			forward,
			length + outer_padding * 2.0,
			depth + outer_padding * 2.0,
			stroke + outer_padding * 2.0
		),
		palette["floor"]
	)
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


func update_install_tutorial_hint(delta: float) -> void:
	if game_board == null or not game_board.has_method("install_tutorial_target_cell"):
		return

	var target: Vector2i = game_board.install_tutorial_target_cell()
	if target != install_tutorial_hint_cell:
		install_tutorial_hint_cell = target
		install_tutorial_hint_elapsed = 0.0
		queue_redraw()
		return

	if target == Vector2i(-1, -1):
		return

	var previous_elapsed := install_tutorial_hint_elapsed
	install_tutorial_hint_elapsed += delta
	if (
		previous_elapsed < VisualStyle.INSTALL_TUTORIAL_HINT_DELAY_SECONDS
		or install_tutorial_hint_alpha() < 1.0
	):
		queue_redraw()


func install_tutorial_hint_alpha() -> float:
	return clampf(
		(
			install_tutorial_hint_elapsed
			- VisualStyle.INSTALL_TUTORIAL_HINT_DELAY_SECONDS
		) / VisualStyle.INSTALL_TUTORIAL_HINT_FADE_SECONDS,
		0.0,
		1.0
	)


func draw_install_tutorial_hint() -> void:
	if install_tutorial_hint_cell == Vector2i(-1, -1):
		return

	var alpha := install_tutorial_hint_alpha()
	if alpha <= 0.0:
		return

	draw_tutorial_hint(
		install_tutorial_hint_cell,
		"[X] Install",
		alpha
	)


func update_release_tutorial_hint(delta: float) -> void:
	if game_board == null or not game_board.has_method("release_tutorial_target_cell"):
		return

	var target := Vector2i(-1, -1)
	if (
		install_reveal_block_id == -1
		and displacement_subject == DISPLACEMENT_NONE
	):
		target = game_board.release_tutorial_target_cell()
	if target != release_tutorial_hint_cell:
		release_tutorial_hint_cell = target
		release_tutorial_hint_elapsed = 0.0
		queue_redraw()
		return

	if target == Vector2i(-1, -1):
		return
	release_tutorial_hint_elapsed += delta
	if release_tutorial_hint_alpha() < 1.0:
		queue_redraw()


func release_tutorial_hint_alpha() -> float:
	return clampf(
		release_tutorial_hint_elapsed
		/ VisualStyle.INSTALL_TUTORIAL_HINT_FADE_SECONDS,
		0.0,
		1.0
	)


func draw_release_tutorial_hint() -> void:
	if release_tutorial_hint_cell == Vector2i(-1, -1):
		return
	var alpha := release_tutorial_hint_alpha()
	if alpha <= 0.0:
		return
	draw_tutorial_hint(
		release_tutorial_hint_cell,
		"[SPACE] Release",
		alpha
	)


func draw_tutorial_hint(cell: Vector2i, hint_text: String, alpha: float) -> void:
	var block_gap := roundi(cell_size * VisualStyle.BLOCK_INSET_RATIO)
	var block_rect := Rect2(
		cell_to_position(cell) + Vector2.ONE * block_gap,
		Vector2.ONE * (cell_size - block_gap * 2)
	)
	var horizontal_padding := scaled_px(5.0)
	var available_width := cell_size * 1.6 - horizontal_padding * 2.0
	var font_size := scaled_font_size(14)
	var text_size := fallback_font.get_string_size(
		hint_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	)
	while text_size.x > available_width and font_size > 8:
		font_size -= 1
		text_size = fallback_font.get_string_size(
			hint_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size
		)
	var text_position := Vector2(
		block_rect.get_center().x - text_size.x / 2.0,
		block_rect.position.y - scaled_px(6.0)
	)
	var shadow_color: Color = palette["direction_fill"]
	shadow_color.a *= alpha
	var hint_color: Color = palette["tutorial_hint"]
	hint_color.a *= alpha
	draw_string(
		fallback_font,
		text_position + Vector2(scaled_px(2.0), scaled_px(2.0)),
		hint_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		shadow_color
	)
	draw_string(
		fallback_font,
		text_position,
		hint_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		hint_color
	)


func should_draw_undo_tutorial_prompt() -> bool:
	return (
		displacement_subject == DISPLACEMENT_NONE
		and game_board != null
		and game_board.has_method("tutorial_undo_deadlock_cell")
		and game_board.tutorial_undo_deadlock_cell() != Vector2i(-1, -1)
	)


func draw_undo_tutorial_prompt() -> void:
	if not should_draw_undo_tutorial_prompt():
		return

	var prompt := "[Z] UNDO"
	var font_size := scaled_font_size(28)
	var text_size := fallback_font.get_string_size(
		prompt,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	)
	var wall_rect := Rect2(
		cell_to_position(Vector2i.ZERO),
		Vector2(cell_size * 2.0, cell_size)
	)
	var baseline := Vector2(
		wall_rect.get_center().x - text_size.x / 2.0,
		wall_rect.get_center().y
		+ fallback_font.get_ascent(font_size) / 2.0
		- fallback_font.get_descent(font_size) / 2.0
	)
	var shadow_color: Color = palette["direction_fill"]
	var prompt_color: Color = palette["tutorial_hint"]
	draw_string(
		fallback_font,
		baseline + Vector2(scaled_px(2.0), scaled_px(2.0)),
		prompt,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		shadow_color
	)
	draw_string(
		fallback_font,
		baseline,
		prompt,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		prompt_color
	)


func draw_direction_triangle(
	center: Vector2,
	direction_name: String,
	color: Color
) -> void:
	var points := direction_triangle_points(center, direction_name)
	if points.is_empty():
		return
	draw_colored_polygon(points, color)


func direction_triangle_points(
	center: Vector2,
	direction_name: String
) -> PackedVector2Array:
	var forward := direction_vector(direction_name)
	if forward == Vector2.ZERO:
		return PackedVector2Array()

	var side := Vector2(-forward.y, forward.x)
	var height := float(roundi(cell_size * VisualStyle.PLAYER_TRI_H_RATIO))
	var width := height * 2.0
	var tip := center + forward * height / 2.0
	var base_center := center - forward * height / 2.0
	return PackedVector2Array([
		tip,
		base_center + side * width / 2.0,
		base_center - side * width / 2.0,
	])


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


func draw_dashed_shape(points: PackedVector2Array, color: Color) -> void:
	var width := maxf(1.0, cell_size * VisualStyle.GOAL_STROKE_RATIO)
	var dash_length := maxf(2.0, cell_size * VisualStyle.GOAL_DASH_RATIO)
	var dash_gap := maxf(2.0, cell_size * VisualStyle.GOAL_DASH_GAP_RATIO)
	for index in range(points.size()):
		draw_dashed_segment(
			points[index],
			points[(index + 1) % points.size()],
			color,
			width,
			dash_length,
			dash_gap
		)


func draw_dashed_segment(
	start: Vector2,
	end: Vector2,
	color: Color,
	width: float,
	dash_length: float,
	dash_gap: float
) -> void:
	var segment_length := start.distance_to(end)
	if segment_length <= 0.0:
		return

	var direction := (end - start) / segment_length
	var offset := 0.0
	while offset < segment_length:
		var dash_end := minf(offset + dash_length, segment_length)
		draw_line(
			start + direction * offset,
			start + direction * dash_end,
			color,
			width,
			true
		)
		offset += dash_length + dash_gap


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


func cell_center(cell: Vector2i) -> Vector2:
	return cell_to_position(cell) + Vector2.ONE * cell_size / 2.0


func animated_cell_position() -> Vector2:
	var result := cell_to_position(displacement_from).lerp(
		cell_to_position(displacement_to),
		displacement_progress
	)
	if displacement_block_id == blocked_release_block_id:
		result += (
			direction_vector(blocked_release_direction)
			* cell_size
			* blocked_release_offset_ratio
		)
	return result


func stored_vector_center(center: Vector2, direction_name: String) -> Vector2:
	return (
		center
		+ direction_vector(direction_name)
		* cell_size
		* VisualStyle.STORED_VECTOR_OFFSET_RATIO
	)


func player_draw_center() -> Vector2:
	if displacement_subject == DISPLACEMENT_PLAYER:
		return animated_cell_position() + Vector2.ONE * cell_size / 2.0
	return cell_center(game_board.player_cell)


func scaled_px(value: float) -> int:
	return maxi(1, roundi(value * cell_size / float(VisualStyle.CELL_SIZE)))


func scaled_font_size(value: int) -> int:
	return maxi(8, roundi(value * cell_size / float(VisualStyle.CELL_SIZE)))


func direction_vector(direction_name: String) -> Vector2:
	match direction_name:
		"Up":
			return Vector2.UP
		"Down":
			return Vector2.DOWN
		"Left":
			return Vector2.LEFT
		"Right":
			return Vector2.RIGHT
		_:
			return Vector2.ZERO
