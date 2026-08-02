extends Node

const LAUNCH_MODE_CAMPAIGN := "campaign"
const LAUNCH_MODE_SINGLE_LEVEL := "single_level"
const WORLD_MAP_SCENE_PATH := "res://scenes/world_map.tscn"
const CLASSIC_LEVEL_SELECT_SCENE_PATH := "res://scenes/classic_level_select.tscn"

const AREA_01_LEVELS := [
	{"id": "1-0", "cell": Vector2i(0, 0), "route": "main", "requires": []},
	{"id": "1-1", "cell": Vector2i(1, 0), "route": "main", "requires": ["1-0"]},
	{"id": "1-2", "cell": Vector2i(2, 0), "route": "main", "requires": ["1-1"]},
	{"id": "1-3", "cell": Vector2i(3, 0), "route": "main", "requires": ["1-2"]},
	{"id": "1-4", "cell": Vector2i(3, 1), "route": "main", "requires": ["1-3"]},
	{"id": "1-5", "cell": Vector2i(2, 1), "route": "main", "requires": ["1-4"]},
	{"id": "1-6", "cell": Vector2i(1, 1), "route": "branch", "requires": ["1-5"]},
	{"id": "1-7", "cell": Vector2i(0, 1), "route": "main", "requires": ["1-5"]},
	{"id": "1-8", "cell": Vector2i(0, 2), "route": "branch", "requires": ["1-7"]},
	{"id": "1-9", "cell": Vector2i(1, 2), "route": "main", "requires": ["1-7"]},
	{"id": "1-10", "cell": Vector2i(2, 2), "route": "branch", "requires": ["1-9"]},
	{"id": "1-11", "cell": Vector2i(3, 2), "route": "branch", "requires": ["1-9"]},
]

const AREA_02_LEVELS := [
	{"id": "2-1", "cell": Vector2i(0, 0), "route": "main", "requires": []},
	{"id": "2-2", "cell": Vector2i(1, 0), "route": "branch", "requires": ["2-1"]},
	{"id": "2-3", "cell": Vector2i(2, 0), "route": "main", "requires": ["2-1"]},
	{"id": "2-4", "cell": Vector2i(3, 0), "route": "branch", "requires": ["2-3"]},
	{"id": "2-5", "cell": Vector2i(3, 1), "route": "main", "requires": ["2-3"]},
	{"id": "2-6", "cell": Vector2i(2, 1), "route": "branch", "requires": ["2-5"]},
	{"id": "2-7", "cell": Vector2i(1, 1), "route": "main", "requires": ["2-5"]},
	{"id": "2-8", "cell": Vector2i(0, 1), "route": "branch", "requires": ["2-7"]},
	{"id": "2-9", "cell": Vector2i(0, 2), "route": "main", "requires": ["2-7"]},
	{"id": "2-10", "cell": Vector2i(1, 2), "route": "branch", "requires": ["2-9"]},
	{"id": "2-11", "cell": Vector2i(2, 2), "route": "main", "requires": ["2-9"]},
	{"id": "2-12", "cell": Vector2i(3, 2), "route": "branch", "requires": ["2-11"]},
]

const AREA_03_LEVELS := [
	{"id": "3-1", "cell": Vector2i(0, 0), "route": "main", "requires": []},
	{"id": "3-2", "cell": Vector2i(1, 0), "route": "main", "requires": ["3-1"]},
	{"id": "3-3", "cell": Vector2i(2, 0), "route": "main", "requires": ["3-2"]},
	{"id": "3-4", "cell": Vector2i(2, 1), "route": "main", "requires": ["3-3"]},
	{"id": "3-5", "cell": Vector2i(1, 1), "route": "main", "requires": ["3-4"]},
	{"id": "3-6", "cell": Vector2i(0, 1), "route": "main", "requires": ["3-5"]},
	{"id": "3-7", "cell": Vector2i(0, 2), "route": "main", "requires": ["3-6"]},
	{"id": "3-8", "cell": Vector2i(1, 2), "route": "main", "requires": ["3-7"]},
	{"id": "3-9", "cell": Vector2i(2, 2), "route": "main", "requires": ["3-8"]},
]

const AREAS := {
	1: {
		"collection_path": "res://levels/area_01.txt",
		"size": Vector2i(4, 3),
		"start_cell": Vector2i(0, 0),
		"exit_requirement": "1-9",
		"previous_area": 0,
		"next_area": 2,
		"levels": AREA_01_LEVELS,
	},
	2: {
		"collection_path": "res://levels/area_02.txt",
		"size": Vector2i(4, 3),
		"start_cell": Vector2i(0, 0),
		"exit_requirement": "2-11",
		"previous_area": 1,
		"next_area": 3,
		"levels": AREA_02_LEVELS,
	},
	3: {
		"collection_path": "res://levels/area_03.txt",
		"size": Vector2i(3, 3),
		"start_cell": Vector2i(0, 0),
		"exit_requirement": "3-9",
		"previous_area": 2,
		"next_area": 0,
		"levels": AREA_03_LEVELS,
	},
}

var completed_levels: Dictionary = {}
var active_level_id := ""
var return_area := 1
var return_cell := Vector2i.ZERO
var cached_sources: Dictionary = {}
var all_levels_unlocked := false
var level_select_scene_path := WORLD_MAP_SCENE_PATH
var return_after_completion := false


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


func complete_active_level() -> void:
	if active_level_id != "":
		complete_level(active_level_id)
		return_after_completion = true


func complete_level(level_id: String) -> void:
	if area_id_for_level(level_id) != 0:
		completed_levels[level_id] = true


func leave_active_level() -> void:
	active_level_id = ""


func reset_progress() -> void:
	completed_levels.clear()
	active_level_id = ""
	return_area = 1
	return_cell = start_cell_for(1)
	all_levels_unlocked = false
	return_after_completion = false


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


func start_cell_for(area_id: int) -> Vector2i:
	var area: Dictionary = area_data_for(area_id)
	if area.is_empty():
		return Vector2i.ZERO
	return Vector2i(area["start_cell"])


func level_source_for(level_id: String) -> String:
	var cached_source: String = str(cached_sources.get(level_id, ""))
	if cached_source != "":
		return cached_source

	var area_id := area_id_for_level(level_id)
	var area: Dictionary = area_data_for(area_id)
	if area.is_empty():
		push_error("Unknown campaign level: %s" % level_id)
		return ""

	var levels: Array = area["levels"]
	var level_index := level_index_for(levels, level_id)
	if level_index == -1:
		push_error("Campaign level is not registered: %s" % level_id)
		return ""

	var collection_path := String(area["collection_path"])
	var sections := load_collection_sections(collection_path)
	if level_index >= sections.size():
		push_error("Campaign level index %s is missing from %s." % [level_index, collection_path])
		return ""

	var source: String = sections[level_index]
	cached_sources[level_id] = source
	return source


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


func load_collection_sections(collection_path: String) -> Array[String]:
	var level_file := FileAccess.open(collection_path, FileAccess.READ)
	if level_file == null:
		push_error("Unable to open campaign collection: %s" % collection_path)
		return []

	var normalized_source := level_file.get_as_text().replace("\r\n", "\n")
	var raw_sections := normalized_source.split("\n---------\n")
	var sections: Array[String] = []
	for raw_section in raw_sections:
		var section := raw_section.strip_edges()
		var title_end := section.find("\n")
		if title_end == -1:
			continue
		var level_source := section.substr(title_end + 1).strip_edges()
		if level_source != "":
			sections.append(level_source)
	return sections
