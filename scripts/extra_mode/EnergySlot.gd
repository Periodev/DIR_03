class_name DIRExtraEnergySlot
extends Control

const SLOT_SIZE := Vector2(30.0, 36.0)
const RADIUS := 11.0
const OUTLINE_WIDTH := 2.0
const OUTLINE_COLOR := Color(0.72, 0.74, 0.78)
const FILL_COLOR := Color(0.28, 0.92, 0.48)

var fill_ratio: float = 0.0

func _init() -> void:
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_fill_ratio(value: float) -> void:
	var next_ratio: float = clampf(value, 0.0, 1.0)
	if is_equal_approx(fill_ratio, next_ratio):
		return
	fill_ratio = next_ratio
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -RADIUS),
		center + Vector2(RADIUS, 0.0),
		center + Vector2(0.0, RADIUS),
		center + Vector2(-RADIUS, 0.0),
	])
	if fill_ratio >= 1.0:
		draw_colored_polygon(diamond, FILL_COLOR)
	elif fill_ratio >= 0.75:
		var lower_half := PackedVector2Array([
			center + Vector2(-RADIUS, 0.0),
			center + Vector2(0.0, RADIUS),
			center + Vector2(RADIUS, 0.0),
		])
		var upper_left_quarter := PackedVector2Array([
			center,
			center + Vector2(0.0, -RADIUS),
			center + Vector2(-RADIUS, 0.0),
		])
		draw_colored_polygon(lower_half, FILL_COLOR)
		draw_colored_polygon(upper_left_quarter, FILL_COLOR)
	elif fill_ratio >= 0.5:
		var lower_half := PackedVector2Array([
			center + Vector2(-RADIUS, 0.0),
			center + Vector2(0.0, RADIUS),
			center + Vector2(RADIUS, 0.0),
		])
		draw_colored_polygon(lower_half, FILL_COLOR)
	elif fill_ratio >= 0.25:
		var lower_right_quarter := PackedVector2Array([
			center,
			center + Vector2(0.0, RADIUS),
			center + Vector2(RADIUS, 0.0),
		])
		draw_colored_polygon(lower_right_quarter, FILL_COLOR)
	draw_polyline(diamond + PackedVector2Array([diamond[0]]), OUTLINE_COLOR, OUTLINE_WIDTH, true)
