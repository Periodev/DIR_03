extends Node

const SELECT_SCENE := preload("res://scenes/classic_level_select.tscn")


func _ready() -> void:
	call_deferred("run_verification")


func run_verification() -> void:
	Campaign.reset_progress()
	var selector: Node2D = SELECT_SCENE.instantiate()
	add_child(selector)
	await get_tree().process_frame

	if selector.entries.size() != 33:
		fail("Expected 33 classic selector entries, got %s." % selector.entries.size())
		return
	if (
		selector.area_entries.size() != 3
		or selector.area_entries[0].size() != 12
		or selector.area_entries[1].size() != 12
		or selector.area_entries[2].size() != 9
	):
		fail("Classic selector pages do not match the 12/12/9 campaign areas.")
		return
	if Campaign.level_select_scene_path != Campaign.CLASSIC_LEVEL_SELECT_SCENE_PATH:
		fail("Classic selector did not register itself as the return scene.")
		return

	selector.selected_index = 0
	selector.move_selection(Vector2i.RIGHT)
	if selector.selected_index != 1:
		fail("Right navigation did not advance one entry.")
		return
	selector.move_selection(Vector2i.DOWN)
	if selector.selected_index != 7:
		fail("Down navigation did not advance one six-column row.")
		return
	selector.selected_index = 11
	selector.move_selection(Vector2i.RIGHT)
	if selector.current_area_index != 0:
		fail("Navigation entered Area 2 before it was unlocked.")
		return
	Campaign.completed_levels["1-9"] = true
	selector.move_selection(Vector2i.RIGHT)
	if selector.current_area_index != 1 or selector.selected_index != 0:
		fail("Right-edge navigation did not enter the unlocked Area 2 page.")
		return
	Campaign.completed_levels["2-11"] = true
	selector.current_area_index = 2
	selector.selected_index = 8
	selector.move_selection(Vector2i.DOWN)
	if selector.selected_index != 8:
		fail("Navigation moved beyond the short final row.")
		return

	Campaign.reset_progress()
	var area_2_entry: Dictionary = selector.entries[12]
	var area_3_entry: Dictionary = selector.entries[24]
	if selector.is_entry_unlocked(area_2_entry):
		fail("Area 2 opened before the Area 1 exit requirement.")
		return
	Campaign.completed_levels["1-9"] = true
	if not selector.is_entry_unlocked(area_2_entry):
		fail("Area 2 stayed locked after the Area 1 exit requirement.")
		return
	if selector.is_entry_unlocked(area_3_entry):
		fail("Area 3 opened before the Area 2 exit requirement.")
		return
	Campaign.completed_levels["2-11"] = true
	if not selector.is_entry_unlocked(area_3_entry):
		fail("Area 3 stayed locked after the Area 2 exit requirement.")
		return

	Campaign.reset_progress()
	selector.current_area_index = 0
	selector.selected_index = 0
	selector.complete_selected_level()
	if not Campaign.is_completed("1-0"):
		fail("F4 completion did not update campaign progress.")
		return
	if not selector.is_entry_unlocked(selector.entries[1]):
		fail("F4 completion did not unlock the next level.")
		return

	Campaign.reset_progress()
	Campaign.unlock_all_levels()
	if not selector.is_entry_unlocked(area_3_entry):
		fail("F3 unlock state did not make every area available.")
		return

	print("Classic level select verification passed for 33 levels.")
	get_tree().quit(0)


func fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
