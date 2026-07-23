extends "res://scripts/game_board.gd"

const PANEL_SIZE := Vector2(390, 700)
const PANEL_TOP := 96.0
const PANEL_MARGIN := 16.0
const PANEL_GAP := 16.0
const DEBUG_PANEL_SIZE := Vector2(300, 700)
const DEFAULT_STEP_SECONDS := 0.3

var command_panel: Control
var level_text_edit: TextEdit
var command_text_edit: TextEdit
var playback_status_label: Label
var pause_button: Button
var speed_label: Label
var speed_slider: HSlider
var playback_timer: Timer

var playback_commands: Array[String] = []
var playback_index := 0
var loaded_command_source := ""
var playback_running := false


func _ready() -> void:
	super()
	if hud_layer == null:
		return

	add_command_player_panel()
	add_playback_timer()
	get_viewport().size_changed.connect(layout_side_panels)
	layout_side_panels()
	level_text_edit.text = level_source_text
	update_playback_status("Paste commands, then Run or Step.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_level"):
		stop_playback()
		reset_level()
		update_playback_status("Level reset.")


func add_command_player_panel() -> void:
	command_panel = Control.new()
	command_panel.name = "CommandPanel"
	command_panel.size = PANEL_SIZE
	hud_layer.add_child(command_panel)

	var panel := ColorRect.new()
	panel.size = PANEL_SIZE
	panel.color = DEBUG_PANEL_COLOR
	command_panel.add_child(panel)

	add_panel_label("Command Player", Vector2(16, 14), Vector2(358, 28), 20)
	add_panel_label("LEVEL DATA", Vector2(16, 52), Vector2(358, 22), 13)

	level_text_edit = TextEdit.new()
	level_text_edit.position = Vector2(16, 78)
	level_text_edit.size = Vector2(358, 250)
	level_text_edit.add_theme_font_size_override("font_size", 14)
	command_panel.add_child(level_text_edit)

	var apply_button := add_panel_button("Apply Level", Vector2(16, 338), Vector2(358, 36))
	apply_button.tooltip_text = "Parse the level text and reset the board."
	apply_button.pressed.connect(apply_level_text)

	add_panel_label("COMMANDS (U D L R X T)", Vector2(16, 392), Vector2(358, 22), 13)

	command_text_edit = TextEdit.new()
	command_text_edit.position = Vector2(16, 418)
	command_text_edit.size = Vector2(358, 80)
	command_text_edit.placeholder_text = "R U X L L U T"
	command_text_edit.add_theme_font_size_override("font_size", 16)
	command_panel.add_child(command_text_edit)

	playback_status_label = add_panel_label("", Vector2(16, 506), Vector2(358, 52), 13)
	playback_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var run_button := add_panel_button("Run", Vector2(16, 566), Vector2(82, 36))
	run_button.tooltip_text = "Reset the level and play the full command stream."
	run_button.pressed.connect(run_from_reset)

	pause_button = add_panel_button("Pause", Vector2(108, 566), Vector2(82, 36))
	pause_button.tooltip_text = "Pause or resume timed playback."
	pause_button.pressed.connect(toggle_pause)

	var step_button := add_panel_button("Step", Vector2(200, 566), Vector2(82, 36))
	step_button.tooltip_text = "Execute one command. A changed stream starts from reset."
	step_button.pressed.connect(step_once)

	var stop_button := add_panel_button("Stop", Vector2(292, 566), Vector2(82, 36))
	stop_button.tooltip_text = "Stop playback and keep the current board state."
	stop_button.pressed.connect(stop_playback)

	speed_label = add_panel_label("", Vector2(16, 618), Vector2(120, 24), 13)

	speed_slider = HSlider.new()
	speed_slider.position = Vector2(132, 616)
	speed_slider.size = Vector2(242, 28)
	speed_slider.min_value = 0.05
	speed_slider.max_value = 1.0
	speed_slider.step = 0.05
	speed_slider.value = DEFAULT_STEP_SECONDS
	speed_slider.value_changed.connect(update_speed)
	command_panel.add_child(speed_slider)
	update_speed(DEFAULT_STEP_SECONDS)

	var help_label := add_panel_label(
		"Run always resets first. Step keeps the current state until commands change. F5 stops and resets.",
		Vector2(16, 654),
		Vector2(358, 38),
		12
	)
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func layout_side_panels() -> void:
	if command_panel == null:
		return

	var viewport_width := get_viewport_rect().size.x
	var command_x := maxf(PANEL_MARGIN, viewport_width - PANEL_MARGIN - PANEL_SIZE.x)
	command_panel.position = Vector2(command_x, PANEL_TOP)

	var debug_x := maxf(PANEL_MARGIN, command_x - PANEL_GAP - DEBUG_PANEL_SIZE.x)
	set_debug_panel_position(Vector2(debug_x, PANEL_TOP))


func add_panel_label(text: String, offset: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = offset
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	command_panel.add_child(label)
	return label


func add_panel_button(text: String, offset: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = offset
	button.size = size
	command_panel.add_child(button)
	return button


func add_playback_timer() -> void:
	playback_timer = Timer.new()
	playback_timer.wait_time = DEFAULT_STEP_SECONDS
	playback_timer.timeout.connect(execute_next_command)
	add_child(playback_timer)


func parse_commands(source: String) -> Dictionary:
	var commands: Array[String] = []
	for index in range(source.length()):
		var character := source.substr(index, 1).to_upper()
		if VALID_COMMANDS.contains(character):
			commands.append(character)
		elif character not in [" ", "\t", "\r", "\n", ","]:
			return {"error": "Unsupported command '%s' at character %s." % [character, index + 1]}

	if commands.is_empty():
		return {"error": "Command stream is empty."}

	return {"commands": commands}


func load_commands_from_input() -> String:
	var parsed := parse_commands(command_text_edit.text)
	if parsed.has("error"):
		return str(parsed["error"])

	playback_commands = parsed["commands"]
	loaded_command_source = command_text_edit.text
	playback_index = 0
	return ""


func apply_level_text() -> void:
	stop_playback()
	var error := replace_level_from_text(level_text_edit.text)
	if error != "":
		update_playback_status("Level error: %s" % error)
		return

	loaded_command_source = ""
	playback_commands.clear()
	playback_index = 0
	update_playback_status("Level applied. Enter commands.")


func run_from_reset() -> void:
	stop_playback()
	var error := load_commands_from_input()
	if error != "":
		update_playback_status(error)
		return

	reset_level()
	playback_running = true
	pause_button.text = "Pause"
	playback_timer.paused = false
	playback_timer.start()
	update_playback_status("Ready: 0 / %s." % playback_commands.size())


func toggle_pause() -> void:
	if not playback_running:
		update_playback_status("Nothing is running.")
		return

	playback_timer.paused = not playback_timer.paused
	pause_button.text = "Resume" if playback_timer.paused else "Pause"
	update_playback_status(
		"Paused at %s / %s." % [playback_index, playback_commands.size()]
		if playback_timer.paused
		else "Running: %s / %s." % [playback_index, playback_commands.size()]
	)


func step_once() -> void:
	if playback_running:
		playback_timer.stop()
		playback_timer.paused = false
		playback_running = false
		pause_button.text = "Pause"

	if loaded_command_source != command_text_edit.text or playback_index >= playback_commands.size():
		var error := load_commands_from_input()
		if error != "":
			update_playback_status(error)
			return
		reset_level()

	execute_next_command()


func execute_next_command() -> void:
	if playback_index >= playback_commands.size():
		finish_playback(false)
		return
	if level_completed:
		finish_playback(true)
		return

	var command := playback_commands[playback_index]
	execute_command(command)
	playback_index += 1

	if level_completed:
		finish_playback(true)
	elif playback_index >= playback_commands.size():
		finish_playback(false)
	else:
		update_playback_status(
			"Executed %s: %s / %s." % [command, playback_index, playback_commands.size()]
		)


func finish_playback(solved: bool) -> void:
	playback_timer.stop()
	playback_timer.paused = false
	playback_running = false
	pause_button.text = "Pause"

	if solved:
		update_playback_status(
			"Solved after %s / %s commands." % [playback_index, playback_commands.size()]
		)
	else:
		update_playback_status(
			"Finished without solving: %s / %s." % [playback_index, playback_commands.size()]
		)


func stop_playback() -> void:
	if playback_timer != null:
		playback_timer.stop()
		playback_timer.paused = false
	playback_running = false
	if pause_button != null:
		pause_button.text = "Pause"
	if playback_status_label != null and not playback_commands.is_empty():
		update_playback_status("Stopped at %s / %s." % [playback_index, playback_commands.size()])


func update_speed(seconds: float) -> void:
	if speed_label != null:
		speed_label.text = "Step: %.2f s" % seconds
	if playback_timer != null:
		playback_timer.wait_time = seconds


func update_playback_status(text: String) -> void:
	if playback_status_label != null:
		playback_status_label.text = text
