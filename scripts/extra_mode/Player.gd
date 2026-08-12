extends Node2D

signal animation_done
signal movement_started
signal movement_finished

const CharacterImpl_PLN = preload("res://scripts/extra_mode/CharacterImpl_PLN.gd")
const PLAYER_BODY_SCALE := 0.8

var character_name: String = "PLN"
var character_color: Color = Color(0.2, 0.8, 0.3)
var character_shape: String = "blade_diamond"
var facing_dir: int = CharacterData.Direction.UP
var move_ready_directions: Array[int] = []
var danger_move_directions: Array[int] = []
var attack_ready_directions: Array[int] = []
var bonus_step_directions: Array[int] = []
var ultimate_dash_ready: bool = false
var _char_impl  # CharacterImpl_PLN
var _feedback_tween: Tween
var _move_tween: Tween

func set_character(char_name: String) -> void:
	character_name = char_name
	var data = CharacterData.CHARACTERS[char_name]
	character_color = data["color"]
	character_shape = data["shape"]
	_char_impl = CharacterImpl_PLN.new()
	queue_redraw()

func set_facing(dir: int) -> void:
	if dir == CharacterData.Direction.NONE:
		return
	if dir == facing_dir:
		return
	facing_dir = dir
	queue_redraw()

func set_move_ready_directions(directions: Array[int], danger_directions: Array[int] = []) -> void:
	if move_ready_directions == directions and danger_move_directions == danger_directions:
		return
	move_ready_directions = directions.duplicate()
	danger_move_directions = danger_directions.duplicate()
	queue_redraw()

func set_bonus_step_directions(directions: Array[int]) -> void:
	if bonus_step_directions == directions:
		return
	bonus_step_directions = directions.duplicate()
	queue_redraw()

func set_attack_ready_directions(directions: Array[int]) -> void:
	if attack_ready_directions == directions:
		return
	attack_ready_directions = directions.duplicate()
	queue_redraw()

func set_ultimate_dash_ready(ready: bool) -> void:
	if ultimate_dash_ready == ready:
		return
	ultimate_dash_ready = ready
	queue_redraw()

func _draw() -> void:
	if ultimate_dash_ready:
		_draw_ultimate_dash_arrows()
	elif not bonus_step_directions.is_empty():
		_draw_bonus_step_arrows()
	else:
		if not move_ready_directions.is_empty():
			_draw_move_ready_arrows()
		if not attack_ready_directions.is_empty():
			_draw_attack_ready_arrows()
	var points: PackedVector2Array
	match character_shape:
		"blade_diamond":
			var base := PackedVector2Array([
				Vector2(0, -35),    # 前方尖端
				Vector2(14, 0),     # 右側最寬
				Vector2(0, 14.0 * sqrt(3)),  # 後方 60° 銳角頂點
				Vector2(-14, 0),    # 左側最寬
			])
			var angle := _facing_to_angle(facing_dir)
			points = PackedVector2Array()
			for p in base:
				points.append((p * PLAYER_BODY_SCALE).rotated(angle))
		_:
			points = _make_polygon(6, 20.0, 0.0)

	draw_polygon(points, PackedColorArray([character_color]))
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 2.0)

func _draw_move_ready_arrows() -> void:
	const ARROW_DISTANCE := 42.0
	const ARROW_FRONT_DEPTH := 5.0
	const ARROW_REAR_DEPTH := 3.0
	const ARROW_HALF_HEIGHT := 4.0
	const ARROW_WIDTH := 2.0
	var normal_color := Color(1.0, 1.0, 1.0, 0.72)
	var danger_color := Color(0.94, 0.24, 0.20, 0.95)
	for direction in move_ready_directions:
		var arrow_color: Color = danger_color if direction in danger_move_directions else normal_color
		var forward := Vector2(CharacterData.DIR_VECTOR[direction])
		var side := Vector2(-forward.y, forward.x)
		var center := forward * ARROW_DISTANCE
		var tip := center + forward * ARROW_FRONT_DEPTH
		var rear := center - forward * ARROW_REAR_DEPTH
		var arrow := PackedVector2Array([
			rear + side * ARROW_HALF_HEIGHT,
			tip,
			rear - side * ARROW_HALF_HEIGHT,
		])
		draw_polyline(arrow, arrow_color, ARROW_WIDTH, true)

func _draw_bonus_step_arrows() -> void:
	const ARROW_DISTANCE := 40.0
	const ARROW_FRONT_DEPTH := 8.0
	const ARROW_REAR_DEPTH := 5.0
	const ARROW_HALF_HEIGHT := 6.0
	const OUTLINE_WIDTH := 6.0
	const FILL_WIDTH := 3.5
	var arrow_color := Color("#C8E64A")
	for direction in bonus_step_directions:
		var forward := Vector2(CharacterData.DIR_VECTOR[direction])
		var side := Vector2(-forward.y, forward.x)
		var center := forward * ARROW_DISTANCE
		var tip := center + forward * ARROW_FRONT_DEPTH
		var rear := center - forward * ARROW_REAR_DEPTH
		var arrow := PackedVector2Array([
			rear + side * ARROW_HALF_HEIGHT,
			tip,
			rear - side * ARROW_HALF_HEIGHT,
		])
		draw_polyline(arrow, Color(0.08, 0.09, 0.11, 0.9), OUTLINE_WIDTH, true)
		draw_polyline(arrow, arrow_color, FILL_WIDTH, true)

func _draw_attack_ready_arrows() -> void:
	const ARROW_DISTANCE := 46.0
	const ARROW_FRONT_DEPTH := 6.0
	const ARROW_REAR_DEPTH := 4.0
	const ARROW_HALF_HEIGHT := 5.0
	const OUTLINE_WIDTH := 5.0
	const FILL_WIDTH := 2.5
	var arrow_color := Color(0.28, 0.92, 0.48)
	for direction in attack_ready_directions:
		var forward := Vector2(CharacterData.DIR_VECTOR[direction])
		var side := Vector2(-forward.y, forward.x)
		var center := forward * ARROW_DISTANCE
		var tip := center + forward * ARROW_FRONT_DEPTH
		var rear := center - forward * ARROW_REAR_DEPTH
		var arrow := PackedVector2Array([
			rear + side * ARROW_HALF_HEIGHT,
			tip,
			rear - side * ARROW_HALF_HEIGHT,
		])
		draw_polyline(arrow, Color(0.08, 0.09, 0.11, 0.9), OUTLINE_WIDTH, true)
		draw_polyline(arrow, arrow_color, FILL_WIDTH, true)

func _draw_ultimate_dash_arrows() -> void:
	const ARROW_DISTANCE := 70.0
	const ARROW_FRONT_DEPTH := 10.0
	const ARROW_REAR_DEPTH := 8.0
	const ARROW_HALF_HEIGHT := 8.0
	const OUTLINE_WIDTH := 7.0
	const FILL_WIDTH := 3.5
	const ULT_COLOR := Color(0.28, 0.92, 0.48)
	for direction_value in CharacterData.DIR_VECTOR:
		var direction: int = int(direction_value)
		var forward: Vector2 = Vector2(CharacterData.DIR_VECTOR[direction])
		var side: Vector2 = Vector2(-forward.y, forward.x)
		var center := forward * ARROW_DISTANCE
		var tip := center + forward * ARROW_FRONT_DEPTH
		var rear := center - forward * ARROW_REAR_DEPTH
		var arrow := PackedVector2Array([
			rear + side * ARROW_HALF_HEIGHT,
			tip,
			rear - side * ARROW_HALF_HEIGHT,
		])
		draw_polyline(arrow, Color(0.08, 0.09, 0.11, 0.95), OUTLINE_WIDTH, true)
		draw_polyline(arrow, ULT_COLOR, FILL_WIDTH, true)

func play_move(from_pos: Vector2, move_duration_override: float = -1.0) -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	var to_pos := position          # already set by Board
	position = from_pos             # snap back to start
	_move_tween = _char_impl.play_move(self, from_pos, to_pos, move_duration_override)
	movement_started.emit()
	_move_tween.finished.connect(_finish_move, CONNECT_ONE_SHOT)

func _finish_move() -> void:
	_move_tween = null
	movement_finished.emit()

func play_attack(dir: int, success: bool, is_dash: bool = false) -> void:
	_char_impl.play_attack(self, dir, success, is_dash)
	emit_animation_done_after(get_hit_delay(is_dash))

func emit_animation_done_after(delay: float) -> void:
	get_tree().create_timer(delay).timeout.connect(
		func(): animation_done.emit(), CONNECT_ONE_SHOT)

func play_charge_preview(
	dir: int,
	body_scale: float = CharacterImpl_PLN.NORMAL_CHARGE_SCALE,
	windup_duration: float = CharacterImpl_PLN.WINDUP
) -> void:
	_char_impl.play_charge_preview(self, dir, body_scale, windup_duration)

func get_hit_delay(
	is_dash: bool = false,
	move_duration_override: float = -1.0,
	windup_override: float = -1.0
) -> float:
	return _char_impl.get_hit_delay(is_dash, move_duration_override, windup_override)

func play_spawn_hit() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	var origin := position
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(self, "position", origin + Vector2(-7.0, 0.0), 0.035)
	_feedback_tween.tween_property(self, "position", origin + Vector2(7.0, 0.0), 0.05)
	_feedback_tween.tween_property(self, "position", origin + Vector2(-5.0, 0.0), 0.045)
	_feedback_tween.tween_property(self, "position", origin + Vector2(4.0, 0.0), 0.04)
	_feedback_tween.tween_property(self, "position", origin, 0.04)

func cancel_feedback() -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = null
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_tween = null

func _facing_to_angle(dir: int) -> float:
	match dir:
		CharacterData.Direction.UP:    return 0.0
		CharacterData.Direction.DOWN:  return PI
		CharacterData.Direction.LEFT:  return -PI / 2.0
		CharacterData.Direction.RIGHT: return PI / 2.0
		_: return 0.0

func _make_polygon(sides: int, radius: float, start_angle: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		var angle = start_angle + (TAU / sides) * i
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts
