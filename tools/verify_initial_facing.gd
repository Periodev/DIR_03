extends Node

const GameBoardScript = preload("res://scripts/game_board.gd")


func _ready() -> void:
	run_verification.call_deferred()


func run_verification() -> void:
	var board: Node2D = GameBoardScript.new()
	add_child(board)
	await get_tree().process_frame
	var error: String = board.set_level_from_text("@..A\nB...")
	if error != "":
		fail("Could not load horizontal nearest-block fixture: %s" % error)
		return
	if board.facing_direction != Vector2i.DOWN or board.facing_name != "Down":
		fail("Player did not face the nearest block.")
		return

	error = board.set_level_from_text("@..\n...\n..A")
	if error != "":
		fail("Could not load diagonal fixture: %s" % error)
		return
	if board.facing_direction != Vector2i.RIGHT:
		fail("Diagonal tie did not use the stable horizontal preference.")
		return

	board.facing_direction = Vector2i.UP
	board.facing_name = "Up"
	board.reset_level()
	if board.facing_direction != Vector2i.RIGHT or board.facing_name != "Right":
		fail("Reset did not restore facing toward the nearest initial block.")
		return

	print("PASS: initial facing follows the nearest block.")
	get_tree().quit(0)


func fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
