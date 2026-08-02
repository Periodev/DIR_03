extends SceneTree

const CampaignScript = preload("res://scripts/campaign.gd")
const AsciiMapParserScript = preload("res://scripts/ascii_map.gd")


func _initialize() -> void:
	call_deferred("run_verification")


func run_verification() -> void:
	var campaign: Node = CampaignScript.new()
	var verified_levels := 0

	for area_id_value in campaign.AREAS:
		var area_id: int = int(area_id_value)
		var area: Dictionary = campaign.area_data_for(area_id)
		var levels: Array = area["levels"]
		for level_value in levels:
			var level: Dictionary = level_value
			var level_id: String = String(level["id"])
			var level_cell: Vector2i = level["cell"]
			if not campaign.begin_level(level_id, area_id, level_cell):
				fail("Could not start %s." % level_id)
				return

			var parsed: Dictionary = AsciiMapParserScript.parse(campaign.active_level_source())
			if parsed.has("error"):
				fail("Could not parse %s: %s" % [level_id, parsed["error"]])
				return
			verified_levels += 1

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
