extends Node

const GameBoardScript = preload("res://scripts/game_board.gd")


func _ready() -> void:
	run_verification()


func run_verification() -> void:
	var game: Node2D = GameBoardScript.new()
	var parse_error: String = String(game.set_level_from_text("@A"))
	if parse_error != "":
		fail("Could not parse blocked-trigger fixture: %s" % parse_error)
		return

	var block: Dictionary = game.blocks[0]
	block["vector"] = "Right"
	game.blocks[0] = block
	game.install_order.append(1)
	game.trigger_vector()

	var consumed_block: Dictionary = game.blocks[0]
	if Vector2i(consumed_block["cell"]) != Vector2i(1, 0):
		fail("Blocked trigger moved its carrier.")
		return
	if String(consumed_block["vector"]) != "":
		fail("Blocked trigger preserved its vector.")
		return
	if not game.install_order.is_empty():
		fail("Blocked trigger preserved its install-order entry.")
		return
	if game.input_locked:
		fail("Blocked trigger did not finish its atomic input.")
		return

	game.free()
	print("Blocked-trigger consumption verification passed.")
	get_tree().quit(0)


func fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
