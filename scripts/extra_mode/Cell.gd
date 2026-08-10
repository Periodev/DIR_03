extends Node2D

const CELL_SIZE := 100.0
const DIAMOND_RADIUS := 30.0

var cell_type: int = CharacterData.CellType.LIVE
var grid_pos: Vector2i = Vector2i.ZERO
var candidate_phase: int = 0  # 0=none, 1..4=spawn preview gradient
var attack_prompt_direction: int = CharacterData.Direction.NONE
var dead_indicator_alpha: float = 1.0
var _spawn_fade_tween: Tween

func set_type(t: int) -> void:
	if t == CharacterData.CellType.LIVE:
		_cancel_spawn_fade()
		dead_indicator_alpha = 1.0
	cell_type = t
	queue_redraw()

func play_spawn_fade(duration: float) -> void:
	_cancel_spawn_fade()
	dead_indicator_alpha = 0.0
	queue_redraw()
	_spawn_fade_tween = create_tween()
	_spawn_fade_tween.tween_method(_set_dead_indicator_alpha, 0.0, 1.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _set_dead_indicator_alpha(value: float) -> void:
	dead_indicator_alpha = value
	queue_redraw()

func _cancel_spawn_fade() -> void:
	if _spawn_fade_tween != null and _spawn_fade_tween.is_valid():
		_spawn_fade_tween.kill()
	_spawn_fade_tween = null

func set_candidate(phase: int) -> void:
	candidate_phase = phase
	queue_redraw()

func set_attack_prompt(direction: int) -> void:
	attack_prompt_direction = direction
	queue_redraw()

func _draw() -> void:
	# Background
	var bg_color := Color(0.10, 0.10, 0.13)

	var rect = Rect2(0, 0, CELL_SIZE, CELL_SIZE)
	draw_rect(rect, bg_color)

	# Outer border: spawn-preview danger gradient (independent of bonus options)
	if candidate_phase >= 1 and candidate_phase <= 4:
		var preview_colors: Dictionary = {
			1: Color(0.78, 0.88, 0.28),
			2: Color(0.95, 0.85, 0.18),
			3: Color(0.98, 0.63, 0.14),
			4: Color(0.94, 0.30, 0.18),
		}
		draw_rect(rect, preview_colors[candidate_phase], false, 3.0)
	else:
		draw_rect(rect, Color(0.25, 0.25, 0.30), false, 1.0)

	# Dead indicator - red octagon
	var center = Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
	if cell_type != CharacterData.CellType.LIVE:
		var r = DIAMOND_RADIUS
		var octagon = PackedVector2Array([
			center + Vector2(0, -r),
			center + Vector2(r * 0.7, -r * 0.7),
			center + Vector2(r, 0),
			center + Vector2(r * 0.7, r * 0.7),
			center + Vector2(0, r),
			center + Vector2(-r * 0.7, r * 0.7),
			center + Vector2(-r, 0),
			center + Vector2(-r * 0.7, -r * 0.7),
		])
		draw_polygon(octagon, PackedColorArray([Color(0.8, 0.15, 0.15, dead_indicator_alpha)]))

	# Candidate warning text
	if candidate_phase >= 1 and candidate_phase <= 4 and cell_type == CharacterData.CellType.LIVE:
		var preview_dot_colors: Dictionary = {
			1: Color(0.78, 0.88, 0.28),
			2: Color(0.95, 0.85, 0.18),
			3: Color(0.98, 0.63, 0.14),
			4: Color(0.94, 0.30, 0.18),
		}
		draw_circle(center + Vector2(0, -CELL_SIZE * 0.3), 6.0, preview_dot_colors[candidate_phase])

	if attack_prompt_direction != CharacterData.Direction.NONE:
		_draw_attack_chevron(center, attack_prompt_direction)


func _draw_attack_chevron(center: Vector2, direction: int) -> void:
	var forward := Vector2(CharacterData.DIR_VECTOR[direction])
	var side := Vector2(-forward.y, forward.x)
	var edge_center := center - forward * (CELL_SIZE * 0.38)
	var attack_color := Color(0.28, 0.92, 0.48)
	_draw_chevron(edge_center, forward, side, 10.0, 8.0, 8.0, 7.0, 3.5, attack_color)


func _draw_chevron(
	center: Vector2,
	forward: Vector2,
	side: Vector2,
	front_depth: float,
	rear_depth: float,
	half_height: float,
	outline_width: float,
	fill_width: float,
	fill_color: Color
) -> void:
	var tip := center + forward * front_depth
	var rear := center - forward * rear_depth
	var points := PackedVector2Array([
		rear + side * half_height,
		tip,
		rear - side * half_height,
	])
	draw_polyline(points, Color(0.08, 0.09, 0.11, 0.9), outline_width, true)
	draw_polyline(points, fill_color, fill_width, true)
