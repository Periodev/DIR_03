extends CanvasLayer

const FADE_OUT_SECONDS := 0.15
const FADE_IN_SECONDS := 0.15

var transition_active := false
var overlay: ColorRect


func _ready() -> void:
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = ColorRect.new()
	overlay.name = "SceneTransitionOverlay"
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func is_active() -> bool:
	return transition_active


func transition_to(scene_path: String) -> void:
	if transition_active:
		return
	transition_active = true
	overlay.visible = true
	overlay.color.a = 0.0

	var fade_out := create_tween()
	fade_out.set_trans(Tween.TRANS_SINE)
	fade_out.set_ease(Tween.EASE_IN_OUT)
	fade_out.tween_property(overlay, "color:a", 1.0, FADE_OUT_SECONDS)
	await fade_out.finished

	var change_error: Error = get_tree().change_scene_to_file(scene_path)
	if change_error != OK:
		push_error("Unable to change scene during transition: %s" % scene_path)
		await fade_back_to_current_scene()
		return

	await get_tree().process_frame
	await get_tree().process_frame
	var fade_in := create_tween()
	fade_in.set_trans(Tween.TRANS_SINE)
	fade_in.set_ease(Tween.EASE_IN_OUT)
	fade_in.tween_property(overlay, "color:a", 0.0, FADE_IN_SECONDS)
	await fade_in.finished
	overlay.visible = false
	transition_active = false


func fade_back_to_current_scene() -> void:
	var fade_back := create_tween()
	fade_back.tween_property(overlay, "color:a", 0.0, FADE_IN_SECONDS)
	await fade_back.finished
	overlay.visible = false
	transition_active = false
