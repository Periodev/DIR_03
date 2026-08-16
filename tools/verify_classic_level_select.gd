extends Node

const SELECT_SCENE := preload("res://scenes/classic_level_select.tscn")
const THUMBNAIL_RENDERER := preload("res://scripts/level_thumbnail_renderer.gd")
const TEST_SAVE_PATH := "user://verify_classic_level_select_progress.cfg"


func _ready() -> void:
	call_deferred("run_verification")


func run_verification() -> void:
	remove_test_save()
	Campaign.save_path = TEST_SAVE_PATH
	Campaign.reset_progress()
	var selector: Node2D = SELECT_SCENE.instantiate()
	add_child(selector)
	await get_tree().process_frame

	if selector.entries.size() != 36:
		fail("Expected 36 classic selector entries, got %s." % selector.entries.size())
		return
	if (
		selector.area_entries.size() != 3
		or selector.area_entries[0].size() != 12
		or selector.area_entries[1].size() != 12
		or selector.area_entries[2].size() != 12
	):
		fail("Classic selector pages do not match the 12/12/12 campaign areas.")
		return
	if Campaign.level_select_scene_path != Campaign.CLASSIC_LEVEL_SELECT_SCENE_PATH:
		fail("Classic selector did not register itself as the return scene.")
		return
	for entry_value in selector.entries:
		var thumbnail_entry: Dictionary = entry_value
		var thumbnail_data: Dictionary = thumbnail_entry["thumbnail_data"]
		if thumbnail_data.is_empty():
			fail("Classic selector thumbnail data is missing for %s." % thumbnail_entry["id"])
			return
	var redundant_entry: Dictionary = selector.entries[21]
	var redundant_data: Dictionary = redundant_entry["thumbnail_data"]
	var initial_block_cells: Array[Vector2i] = THUMBNAIL_RENDERER.block_cells_for(
		redundant_data,
		false
	)
	var completed_block_cells: Array[Vector2i] = THUMBNAIL_RENDERER.block_cells_for(
		redundant_data,
		true
	)
	if initial_block_cells.size() <= completed_block_cells.size():
		fail("Completion thumbnail test level does not contain a redundant free block.")
		return
	if completed_block_cells.size() != redundant_data["goal_cells"].size():
		fail("Completed thumbnail does not project exactly one block per goal.")
		return
	for goal_value in redundant_data["goal_cells"]:
		if not completed_block_cells.has(Vector2i(goal_value)):
			fail("Completed thumbnail omitted a goal cell.")
			return
	if not is_equal_approx(selector.slot_size_for(Vector2(1440, 960)), 208.0):
		fail("Classic selector did not use the current 208px adaptive slots at 1440x960.")
		return
	var layout_viewport := Vector2(1440, 960)
	var first_rect: Rect2 = selector.entry_rect_for(0, layout_viewport)
	var last_rect: Rect2 = selector.entry_rect_for(11, layout_viewport)
	var viewport_rect := Rect2(Vector2.ZERO, layout_viewport)
	if not viewport_rect.encloses(first_rect) or not viewport_rect.encloses(last_rect):
		fail("Adaptive classic selector tiles extend beyond the viewport.")
		return
	var top_name_rect: Rect2 = selector.selected_level_name_rect_for(0, layout_viewport)
	var bottom_name_rect: Rect2 = selector.selected_level_name_rect_for(7, layout_viewport)
	if top_name_rect.end.y >= first_rect.position.y:
		fail("Top-row level name does not stay above the selected tile.")
		return
	if bottom_name_rect.position.y <= selector.entry_rect_for(7, layout_viewport).end.y:
		fail("Bottom-row level name does not stay below the selected tile.")
		return
	if not viewport_rect.encloses(top_name_rect) or not viewport_rect.encloses(bottom_name_rect):
		fail("Selected level name extends beyond the viewport.")
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
	Campaign.completed_levels["1-10"] = true
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
	Campaign.completed_levels["1-10"] = true
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
	if selector.selected_index != 1:
		fail("F4 completion did not advance selection to the next level.")
		return
	if not selector.is_entry_unlocked(selector.entries[1]):
		fail("F4 completion did not unlock the next level.")
		return

	Campaign.reset_progress()
	Campaign.begin_level("1-0", 1, Vector2i(0, 0))
	Campaign.complete_active_level()
	Campaign.leave_active_level()
	selector.select_return_level()
	if selector.current_area_index != 0 or selector.selected_index != 1:
		fail("A completed gameplay return did not select the next level.")
		return
	selector.select_return_level()
	if selector.selected_index != 0:
		fail("Completed return state was not consumed after one selection advance.")
		return

	Campaign.reset_progress()
	Campaign.unlock_all_levels()
	if not selector.is_entry_unlocked(area_3_entry):
		fail("F3 unlock state did not make every area available.")
		return

	remove_test_save()
	print("Classic level select verification passed for %s levels." % selector.entries.size())
	get_tree().quit(0)


func fail(message: String) -> void:
	remove_test_save()
	push_error(message)
	get_tree().quit(1)


func remove_test_save() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)
