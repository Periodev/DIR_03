extends Node2D

var color: Color = Color(0.8, 0.15, 0.15, 1.0)
const FLASH_RADIUS := 33.0
const DEFAULT_HOLD_SECONDS := 0.05
const DEFAULT_TO_WHITE_SECONDS := 0.05
const DEFAULT_FADE_SECONDS := 0.35
const KILL_HOLD_SECONDS := 0.02
const KILL_TO_WHITE_SECONDS := 0.03
const KILL_FADE_SECONDS := 0.16

var hold_seconds: float = DEFAULT_HOLD_SECONDS
var to_white_seconds: float = DEFAULT_TO_WHITE_SECONDS
var fade_seconds: float = DEFAULT_FADE_SECONDS

func configure_fast_kill() -> void:
	hold_seconds = KILL_HOLD_SECONDS
	to_white_seconds = KILL_TO_WHITE_SECONDS
	fade_seconds = KILL_FADE_SECONDS

func _ready() -> void:
	var tw := create_tween()
	tw.tween_interval(hold_seconds)
	tw.tween_method(_set_color, Color(0.8, 0.15, 0.15, 1.0), Color(1.0, 1.0, 1.0, 1.0), to_white_seconds)\
	  .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_color, Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0), fade_seconds)\
	  .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)

func _set_color(c: Color) -> void:
	color = c
	queue_redraw()

func _draw() -> void:
	if color.a <= 0.0:
		return
	var r := FLASH_RADIUS
	var octagon := PackedVector2Array([
		Vector2(0, -r),
		Vector2(r * 0.7, -r * 0.7),
		Vector2(r, 0),
		Vector2(r * 0.7, r * 0.7),
		Vector2(0, r),
		Vector2(-r * 0.7, r * 0.7),
		Vector2(-r, 0),
		Vector2(-r * 0.7, -r * 0.7),
	])
	draw_polygon(octagon, PackedColorArray([color, color, color, color, color, color, color, color]))
