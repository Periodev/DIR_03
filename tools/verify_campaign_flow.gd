extends SceneTree

const CampaignScript = preload("res://scripts/campaign.gd")
const AsciiMapParserScript = preload("res://scripts/ascii_map.gd")


func _initialize() -> void:
	call_deferred("run_verification")


func run_verification() -> void:
	var campaign: Node = CampaignScript.new()
	var verified_levels := 0
	var verified_ids: Dictionary = {}

	for area_id_value in campaign.AREAS:
		var area_id: int = int(area_id_value)
		var area: Dictionary = campaign.area_data_for(area_id)
		var levels: Array = area["levels"]
		for level_value in levels:
			var level: Dictionary = level_value
			var level_id: String = String(level["id"])
			if verified_ids.has(level_id):
				fail("Duplicate campaign level id: %s." % level_id)
				return
			verified_ids[level_id] = true
			if String(level["name"]) == "":
				fail("Campaign level %s has no name." % level_id)
				return
			if not String(level["source"]).begins_with("!cell-edge-v1"):
				fail("Campaign level %s does not use the unified cell-edge format." % level_id)
				return
			var level_cell: Vector2i = level["cell"]
			if not campaign.begin_level(level_id, area_id, level_cell):
				fail("Could not start %s." % level_id)
				return

			var parsed: Dictionary = AsciiMapParserScript.parse(campaign.active_level_source())
			if parsed.has("error"):
				fail("Could not parse %s: %s" % [level_id, parsed["error"]])
				return
			verified_levels += 1

	if verified_levels != 34:
		fail("Expected 34 campaign levels; found %s." % verified_levels)
		return
	if campaign.level_name_for("1-0") != "Push" or campaign.level_name_for("3-11") != "Phase" or campaign.level_name_for("3-12") != "Fin":
		fail("Campaign level names are not available through the catalog.")
		return

	campaign.unlock_all_levels()
	if not campaign.all_levels_unlocked:
		fail("Unlock-all state was not retained.")
		return
	campaign.reset_progress()
	if campaign.all_levels_unlocked:
		fail("Reset did not clear unlock-all state.")
		return

	campaign.begin_level("1-0", 1, Vector2i(0, 0))
	campaign.complete_active_level()
	if not campaign.is_completed("1-0"):
		fail("Completion state was not retained.")
		return
	if campaign.return_area != 1 or campaign.return_cell != Vector2i(0, 0):
		fail("Return position was not retained.")
		return

	campaign.leave_active_level()
	if campaign.has_active_level():
		fail("Active level was not cleared on map return.")
		return

	print("Campaign flow verification passed for %s levels." % verified_levels)
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
