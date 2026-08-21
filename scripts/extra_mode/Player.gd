extends Node2D

signal animation_done
signal movement_started
signal movement_finished

const CharacterImpl_PLN = preload("res://scripts/extra_mode/CharacterImpl_PLN.gd")
const PLAYER_BODY_SCALE := 0.8
const HIT_SOUND: AudioStream = preload(
	"res://assets/audio/sfx/extra_attack/error_006.ogg"
)
const DIRECTION_REPLACEMENT_FADE_DURATION := 0.10
const BONUS_STEP_FRAME_COLOR := Color("#2FD9A0")
const BONUS_STEP_FRAME_WIDTH := 2.5

var character_name: String = "PLN"
var character_color: Color = Color(0.2, 0.8, 0.3)
var character_shape: String = "blade_diamond"
var facing_dir: int = CharacterData.Direction.UP
var move_ready_directions: Array[int] = []
var danger_move_directions: Array[int] = []
var attack_ready_directions: Array[int] = []
var bonus_step_directions: Array[int] = []
var ultimate_dash_ready: bool = false
var stored_direction_slots: Array[int] = []
var stored_direction_max_size := 3
var _char_impl  # CharacterImpl_PLN
var _feedback_tween: Tween
var _move_tween: Tween
var _direction_fade_tween: Tween
var _direction_transition_tween: Tween
var _expiring_arrow_alpha := 1.0
var _expiring_count_override := -1
var _next_expiring_progress := 0.0
var _next_expiring_start_override := -1
var _next_expiring_count_override := 0
var _direction_update_pending := false
var _pending_arrival_slots: Array[int] = []
var _pending_final_slots: Array[int] = []
var _pending_direction_max_size := 3
var _pending_evicted_count := 0
var _pending_next_expiring_start := -1
var _pending_next_expiring_count := 0

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

func set_stored_direction_slots(directions: Array, max_size: int) -> void:
	var normalized: Array[int] = []
	for direction_value in directions:
		normalized.append(int(direction_value))
	if stored_direction_slots == normalized and stored_direction_max_size == max_size:
		return
	stored_direction_slots = normalized
	stored_direction_max_size = max_size
	queue_redraw()

func prepare_stored_direction_update(
	arrival_directions: Array,
	final_directions: Array,
	max_size: int,
	evicted_count: int,
	animate_next_expiring: bool = false
) -> void:
	_pending_arrival_slots.clear()
	for direction_value in arrival_directions:
		_pending_arrival_slots.append(int(direction_value))
	_pending_final_slots.clear()
	for direction_value in final_directions:
		_pending_final_slots.append(int(direction_value))
	_pending_direction_max_size = max_size
	_pending_evicted_count = evicted_count
	_pending_next_expiring_start = -1
	_pending_next_expiring_count = 0
	if animate_next_expiring:
		var final_expiring_count: int = maxi(0, final_directions.size() - max_size + 1)
		if final_expiring_count > 0:
			_pending_next_expiring_start = evicted_count
			_pending_next_expiring_count = final_expiring_count
	_direction_update_pending = true

func has_pending_stored_direction_update() -> bool:
	return _direction_update_pending

func _draw() -> void:
	if ultimate_dash_ready:
		_draw_ultimate_dash_arrows()
	elif not stored_direction_slots.is_empty():
		_draw_stored_direction_arrows()
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
	if ultimate_dash_ready:
		draw_polyline(
			points + PackedVector2Array([points[0]]),
			Color.WHITE,
			1.5,
			true
		)
	elif not bonus_step_directions.is_empty():
		draw_polyline(
			points + PackedVector2Array([points[0]]),
			BONUS_STEP_FRAME_COLOR,
			BONUS_STEP_FRAME_WIDTH,
			true
		)

func _draw_stored_direction_arrows() -> void:
	const ARROW_DISTANCE := 46.0
	# 2 * atan(11.0 / (4.56 + 3.0)) = 111.0 degrees at the tip.
	const ARROW_FRONT_DEPTH := 4.56
	const ARROW_REAR_DEPTH := 3.0
	const ARROW_HALF_HEIGHT := 11.0
	const SEQUENCE_STEP := 8.4
	const OUTLINE_WIDTH := 6.0
	const FILL_WIDTH := 3.0
	const ACTIVE_COLOR := Color("#7FE85A")
	const EXPIRING_COLOR := Color("#ADDEB7")
	var expiring_count: int = _expiring_count_override
	if expiring_count < 0 and stored_direction_slots.size() >= stored_direction_max_size:
		expiring_count = stored_direction_slots.size() - stored_direction_max_size + 1
	elif expiring_count < 0:
		expiring_count = 0
	var direction_counts := {}
	var transitioning_direction_counts := {}
	var outgoing_direction_counts := {}
	for slot_index in stored_direction_slots.size():
		var counted_direction: int = stored_direction_slots[slot_index]
		direction_counts[counted_direction] = int(direction_counts.get(counted_direction, 0)) + 1
		var counted_as_outgoing: bool = slot_index < expiring_count
		var counted_as_transitioning: bool = (
			_next_expiring_start_override >= 0
			and slot_index >= _next_expiring_start_override
			and slot_index < _next_expiring_start_override + _next_expiring_count_override
		)
		if counted_as_outgoing:
			outgoing_direction_counts[counted_direction] = (
				int(outgoing_direction_counts.get(counted_direction, 0)) + 1
			)
		elif counted_as_transitioning:
			transitioning_direction_counts[counted_direction] = (
				int(transitioning_direction_counts.get(counted_direction, 0)) + 1
			)
	var active_drawn_counts := {}
	var transitioning_drawn_counts := {}
	var outgoing_drawn_counts := {}
	for slot_index in stored_direction_slots.size():
		var direction: int = stored_direction_slots[slot_index]
		var forward := Vector2(CharacterData.DIR_VECTOR[direction])
		var side := Vector2(-forward.y, forward.x)
		var is_outgoing: bool = slot_index < expiring_count
		var is_transitioning: bool = (
			_next_expiring_start_override >= 0
			and slot_index >= _next_expiring_start_override
			and slot_index < _next_expiring_start_override + _next_expiring_count_override
		)
		var duplicate_index: int
		var active_count: int = (
			int(direction_counts[direction])
			- int(transitioning_direction_counts.get(direction, 0))
			- int(outgoing_direction_counts.get(direction, 0))
		)
		if is_outgoing:
			var transitioning_count: int = int(transitioning_direction_counts.get(direction, 0))
			var outgoing_drawn: int = int(outgoing_drawn_counts.get(direction, 0))
			duplicate_index = active_count + transitioning_count + outgoing_drawn
			outgoing_drawn_counts[direction] = outgoing_drawn + 1
		elif is_transitioning:
			var transitioning_drawn: int = int(transitioning_drawn_counts.get(direction, 0))
			duplicate_index = active_count + transitioning_drawn
			transitioning_drawn_counts[direction] = transitioning_drawn + 1
		else:
			duplicate_index = int(active_drawn_counts.get(direction, 0))
			active_drawn_counts[direction] = duplicate_index + 1
		var sequence_distance := ARROW_DISTANCE - float(duplicate_index) * SEQUENCE_STEP
		var center := forward * sequence_distance
		var tip := center + forward * ARROW_FRONT_DEPTH
		var rear := center - forward * ARROW_REAR_DEPTH
		var arrow := PackedVector2Array([
			rear + side * ARROW_HALF_HEIGHT,
			tip,
			rear - side * ARROW_HALF_HEIGHT,
		])
		var arrow_color: Color = ACTIVE_COLOR
		var outline_color := Color(0.08, 0.09, 0.11, 0.9)
		if is_outgoing:
			arrow_color = EXPIRING_COLOR
			arrow_color.a *= _expiring_arrow_alpha
			outline_color.a *= _expiring_arrow_alpha
		elif is_transitioning:
			arrow_color = ACTIVE_COLOR.lerp(EXPIRING_COLOR, _next_expiring_progress)
		draw_polyline(arrow, outline_color, OUTLINE_WIDTH, true)
		draw_polyline(arrow, arrow_color, FILL_WIDTH, true)

func _draw_ultimate_dash_arrows() -> void:
	const ARROW_DISTANCE := 58.0
	const ARROW_FRONT_DEPTH := 12.0
	const ARROW_REAR_DEPTH := 9.6
	const ARROW_HALF_HEIGHT := 9.6
	const OUTLINE_WIDTH := 6.5
	const FILL_WIDTH := 4.2
	const ULT_COLOR := Color(0.20, 0.68, 0.34)
	const ULT_FRAME_COLOR := Color(0.28, 0.92, 0.48)
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
		draw_polyline(arrow, ULT_FRAME_COLOR, OUTLINE_WIDTH, true)
		draw_polyline(arrow, ULT_COLOR, FILL_WIDTH, true)

func play_move(from_pos: Vector2, move_duration_override: float = -1.0, play_sound: bool = true) -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	var to_pos := position          # already set by Board
	position = from_pos             # snap back to start
	_move_tween = _char_impl.play_move(self, from_pos, to_pos, move_duration_override, play_sound)
	movement_started.emit()
	_move_tween.finished.connect(_finish_move, CONNECT_ONE_SHOT)

func _play_pending_direction_replacement() -> void:
	stored_direction_slots = _pending_arrival_slots.duplicate()
	stored_direction_max_size = _pending_direction_max_size
	_expiring_count_override = _pending_evicted_count
	_next_expiring_start_override = _pending_next_expiring_start
	_next_expiring_count_override = _pending_next_expiring_count
	_next_expiring_progress = 0.0
	queue_redraw()
	var has_outgoing: bool = _pending_evicted_count > 0
	var has_transitioning: bool = _pending_next_expiring_count > 0
	if not has_outgoing and not has_transitioning:
		_finish_pending_direction_update()
		return
	if _direction_fade_tween != null and _direction_fade_tween.is_valid():
		_direction_fade_tween.kill()
	if _direction_transition_tween != null and _direction_transition_tween.is_valid():
		_direction_transition_tween.kill()
	_expiring_arrow_alpha = 1.0
	if has_transitioning:
		_direction_transition_tween = create_tween()
		_direction_transition_tween.tween_method(
			_set_next_expiring_progress,
			0.0,
			1.0,
			DIRECTION_REPLACEMENT_FADE_DURATION
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_direction_fade_tween = create_tween()
	if not has_outgoing:
		_direction_fade_tween.tween_interval(DIRECTION_REPLACEMENT_FADE_DURATION)
		_direction_fade_tween.finished.connect(_finish_pending_direction_update, CONNECT_ONE_SHOT)
		return
	_direction_fade_tween.tween_method(
		_set_expiring_arrow_alpha, 1.0, 0.0, DIRECTION_REPLACEMENT_FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_direction_fade_tween.finished.connect(_finish_pending_direction_update, CONNECT_ONE_SHOT)

func _finish_pending_direction_update() -> void:
	_direction_fade_tween = null
	if _direction_transition_tween != null and _direction_transition_tween.is_valid():
		_direction_transition_tween.kill()
	_direction_transition_tween = null
	stored_direction_slots = _pending_final_slots.duplicate()
	stored_direction_max_size = _pending_direction_max_size
	_direction_update_pending = false
	_pending_arrival_slots.clear()
	_pending_final_slots.clear()
	_pending_evicted_count = 0
	_pending_next_expiring_start = -1
	_pending_next_expiring_count = 0
	_expiring_count_override = -1
	_next_expiring_start_override = -1
	_next_expiring_count_override = 0
	_next_expiring_progress = 0.0
	_expiring_arrow_alpha = 1.0
	queue_redraw()
	movement_finished.emit()

func _set_expiring_arrow_alpha(value: float) -> void:
	_expiring_arrow_alpha = value
	queue_redraw()

func _set_next_expiring_progress(value: float) -> void:
	_next_expiring_progress = value
	queue_redraw()

func _finish_move() -> void:
	_move_tween = null
	if _direction_update_pending:
		_play_pending_direction_replacement()
		return
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
	play_hit_sound()

func play_hit_sound() -> void:
	var sound := AudioStreamPlayer.new()
	sound.stream = HIT_SOUND
	add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()

func cancel_feedback() -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = null
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_tween = null
	if _direction_fade_tween != null and _direction_fade_tween.is_valid():
		_direction_fade_tween.kill()
	_direction_fade_tween = null
	if _direction_transition_tween != null and _direction_transition_tween.is_valid():
		_direction_transition_tween.kill()
	_direction_transition_tween = null
	_expiring_arrow_alpha = 1.0
	_expiring_count_override = -1
	_next_expiring_progress = 0.0
	_next_expiring_start_override = -1
	_next_expiring_count_override = 0
	_direction_update_pending = false
	_pending_arrival_slots.clear()
	_pending_final_slots.clear()
	_pending_evicted_count = 0
	_pending_next_expiring_start = -1
	_pending_next_expiring_count = 0

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
