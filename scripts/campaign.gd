extends Node

const LevelCatalogData = preload("res://scripts/level_catalog.gd")

const LAUNCH_MODE_CAMPAIGN := "campaign"
const LAUNCH_MODE_SINGLE_LEVEL := "single_level"
const TITLE_SCREEN_SCENE_PATH := "res://scenes/title_screen.tscn"
const WORLD_MAP_SCENE_PATH := "res://scenes/world_map.tscn"
const CLASSIC_LEVEL_SELECT_SCENE_PATH := "res://scenes/classic_level_select.tscn"
const EXTRA_MODE_SCENE_PATH := "res://scenes/extra_mode/extra_mode.tscn"
const AREAS := LevelCatalogData.AREAS
const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://progress.cfg"

var completed_levels: Dictionary = {}
var active_level_id := ""
var return_area := 1
var return_cell := Vector2i.ZERO
var all_levels_unlocked := false
var level_select_scene_path := WORLD_MAP_SCENE_PATH
var return_after_completion := false
var grid_lines_visible := false
var audio_volume_percent := 100
var save_path := DEFAULT_SAVE_PATH


func _ready() -> void:
	load_progress()


func set_audio_volume(percent: int) -> void:
	audio_volume_percent = clampi(percent, 0, 100)
	var master_bus_index: int = AudioServer.get_bus_index("Master")
	if master_bus_index == -1:
		return
	AudioServer.set_bus_mute(master_bus_index, audio_volume_percent == 0)
	if audio_volume_percent > 0:
		AudioServer.set_bus_volume_db(
			master_bus_index,
			linear_to_db(float(audio_volume_percent) / 100.0)
		)


func is_single_level_mode() -> bool:
	var launch_mode: String = str(ProjectSettings.get_setting(
		"dir/launch_mode",
		LAUNCH_MODE_CAMPAIGN,
	))
	return launch_mode == LAUNCH_MODE_SINGLE_LEVEL


func begin_level(level_id: String, area_id: int, cell: Vector2i) -> bool:
	if level_source_for(level_id) == "":
		return false
	active_level_id = level_id
	return_area = area_id
	return_cell = cell
	return_after_completion = false
	return true


func has_active_level() -> bool:
	return active_level_id != ""


func active_level_source() -> String:
	if active_level_id == "":
		return ""
	return level_source_for(active_level_id)


func active_level_name() -> String:
	if active_level_id == "":
		return ""
	return level_name_for(active_level_id)


func complete_active_level() -> void:
	if active_level_id != "":
		complete_level(active_level_id)
		return_after_completion = true


func complete_level(level_id: String) -> void:
	if is_known_level_id(level_id):
		completed_levels[level_id] = true
		save_progress()


func leave_active_level() -> void:
	active_level_id = ""


func reset_progress() -> void:
	completed_levels.clear()
	active_level_id = ""
	return_area = 1
	return_cell = start_cell_for(1)
	all_levels_unlocked = false
	return_after_completion = false
	save_progress()


func save_progress() -> void:
	var completed_ids: Array[String] = []
	for level_id_value in completed_levels:
		var level_id := String(level_id_value)
		if bool(completed_levels[level_id_value]) and is_known_level_id(level_id):
			completed_ids.append(level_id)
	completed_ids.sort()

	var config := ConfigFile.new()
	config.set_value("meta", "version", SAVE_VERSION)
	config.set_value("progress", "completed_levels", completed_ids)
	var save_error: Error = config.save(save_path)
	if save_error != OK:
		push_warning("Unable to save campaign progress: %s" % error_string(save_error))


func load_progress() -> void:
	completed_levels.clear()
	var config := ConfigFile.new()
	var load_error: Error = config.load(save_path)
	if load_error == ERR_FILE_NOT_FOUND:
		return
	if load_error != OK:
		push_warning("Unable to load campaign progress: %s" % error_string(load_error))
		return

	var version_value: Variant = config.get_value("meta", "version", 0)
	if int(version_value) != SAVE_VERSION:
		return
	var completed_value: Variant = config.get_value(
		"progress",
		"completed_levels",
		[],
	)
	if not completed_value is Array:
		return
	var saved_ids: Array = completed_value
	for level_id_value in saved_ids:
		var level_id := String(level_id_value)
		if is_known_level_id(level_id):
			completed_levels[level_id] = true


func unlock_all_levels() -> void:
	all_levels_unlocked = true


func set_level_select_scene(scene_path: String) -> void:
	level_select_scene_path = scene_path


func consume_completed_return() -> bool:
	var was_completed_return := return_after_completion
	return_after_completion = false
	return was_completed_return


func is_completed(level_id: String) -> bool:
	return bool(completed_levels.get(level_id, false))


func area_data_for(area_id: int) -> Dictionary:
	return AREAS.get(area_id, {})


func is_known_level_id(level_id: String) -> bool:
	var area_id := area_id_for_level(level_id)
	var area: Dictionary = area_data_for(area_id)
	if area.is_empty():
		return false
	var levels_value: Variant = area.get("levels", [])
	if not levels_value is Array:
		return false
	var levels: Array = levels_value
	return level_index_for(levels, level_id) != -1


func start_cell_for(area_id: int) -> Vector2i:
	var area: Dictionary = area_data_for(area_id)
	if area.is_empty():
		return Vector2i.ZERO
	return Vector2i(area["start_cell"])


func level_source_for(level_id: String) -> String:
	var area_id: int = area_id_for_level(level_id)
	var area: Dictionary = area_data_for(area_id)
	if area.is_empty():
		push_error("Unknown campaign level: %s" % level_id)
		return ""

	var levels: Array = area["levels"]
	var level_index: int = level_index_for(levels, level_id)
	if level_index == -1:
		push_error("Campaign level is not registered: %s" % level_id)
		return ""
	var level: Dictionary = levels[level_index]
	return String(level["source"])


func level_name_for(level_id: String) -> String:
	var area_id: int = area_id_for_level(level_id)
	var area: Dictionary = area_data_for(area_id)
	if area.is_empty():
		return ""
	var levels: Array = area["levels"]
	var level_index: int = level_index_for(levels, level_id)
	if level_index == -1:
		return ""
	var level: Dictionary = levels[level_index]
	return String(level["name"])


func area_id_for_level(level_id: String) -> int:
	var parts := level_id.split("-", false, 1)
	if parts.size() != 2:
		return 0
	return int(parts[0])


func level_index_for(levels: Array, level_id: String) -> int:
	for index in levels.size():
		var level: Dictionary = levels[index]
		if String(level["id"]) == level_id:
			return index
	return -1
