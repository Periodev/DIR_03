class_name DIRExtraHeatMeter
extends Control

const SEGMENT_COUNT := 5
const SEGMENT_GAP := 4.0
const EMPTY_COLOR := Color("#343941")
const HEAT_COLORS := [
	Color("#C9A84A"),
	Color("#D5A047"),
	Color("#E09543"),
	Color("#E98740"),
	Color("#FF6045"),
]

var heat: int = 0

func _ready() -> void:
	custom_minimum_size = Vector2(166.0, 18.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_heat(value: int) -> void:
	heat = clampi(value, 0, SEGMENT_COUNT)
	queue_redraw()

func _draw() -> void:
	var segment_width: float = (size.x - SEGMENT_GAP * float(SEGMENT_COUNT - 1)) / float(SEGMENT_COUNT)
	var segment_height: float = minf(10.0, size.y)
	var y: float = (size.y - segment_height) * 0.5
	for index in SEGMENT_COUNT:
		var rect := Rect2(
			Vector2(float(index) * (segment_width + SEGMENT_GAP), y),
			Vector2(segment_width, segment_height)
		)
		var color: Color = HEAT_COLORS[index] if index < heat else EMPTY_COLOR
		draw_rect(rect, color)
