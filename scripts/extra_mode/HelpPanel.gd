class_name DIRExtraHelpPanel
extends PanelContainer

# One page, four sections: what the keys are, the move/bank/kill loop the whole
# game runs on, what kills you, and what pays. It is deliberately illustrated
# rather than a key list -- the loop's rule (a move banks a direction, and only
# a banked direction can attack) is the one thing a new player cannot guess
# from the board, and a picture of two cells says it faster than a sentence.
#
# Glyph colours are taken from Cell.gd, Player.gd, and CharacterData.gd rather
# than re-picked by eye, so the diagrams read as the same objects on the board.

const CELL_LIVE_COLOR := Color("#14161C")
const CELL_EDGE_COLOR := Color("#262A31")
const ENEMY_FILL_COLOR := Color("#6B242B")
const ENEMY_EDGE_COLOR := Color("#8E3139")
const SPAWN_WARNING_COLOR := Color("#FF5140")
const PLAYER_COLOR := Color(0.2, 0.8, 0.3)
const DIRECTION_COLOR := Color("#7FE85A")
const ENERGY_COLOR := Color("#2FD9A0")
const BONUS_COLOR := Color("#FFD75E")
const HEADING_COLOR := Color("#8FA6B2")
const BODY_COLOR := Color(0.86, 0.88, 0.91)
const DIM_COLOR := Color(0.62, 0.65, 0.70)
const RULE_BODY_COLOR := Color(0.54, 0.57, 0.62)

const PANEL_SIZE := Vector2(900, 700)

func _init() -> void:
	visible = false
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.052, 0.064, 0.98)
	style.border_color = Color("#24755E")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	add_theme_stylebox_override("panel", style)
	_build()

func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	# F1, R and ESC are on the permanent nav row above this panel, so repeating
	# them here would spend the page on keys the player can already see. Only
	# the two turn actions with no on-screen prompt are listed; X and Z are
	# named where their rules are, in ENERGY below.
	_section(root, "CONTROLS")
	var keys := HBoxContainer.new()
	keys.add_theme_constant_override("separation", 34)
	root.add_child(keys)
	keys.add_child(_key_column([["MOVE", "WASD / ARROWS"], ["WAIT", "SPACE"]]))

	# Everything needed to actually play, in one block: how a move banks a
	# direction, how a banked direction kills, and what ends the run. The two
	# meters get their own sections below, because a player can survive a long
	# time without ever choosing to spend either one.
	#
	# Full-width rows rather than three columns: a column only fits about thirty
	# characters, which is what forced the earlier one-clause summaries. Across
	# the page each rule has room to say what actually happens -- that an attack
	# spends the direction, that you end up standing on the cleared cell.
	_section(root, "BASIC RULES")
	root.add_child(_loop_row(
		Glyph.KIND_BANK,
		"Move and store a direction",
		"Move to an empty cell to store that direction.\n"
		+ "DIR holds three; a fourth replaces the oldest."
	))
	root.add_child(_loop_row(
		Glyph.KIND_KILL,
		"Attack with a stored direction",
		"Move into an adjacent enemy with a matching DIR.\n"
		+ "That DIR is spent, and you take the cleared cell."
	))
	root.add_child(_loop_row(
		Glyph.KIND_WARNING,
		"Enemy spawn warning",
		"A cell marked by red corners spawns an enemy after the next normal turn.\n"
		+ "A hit spends 1 full ENERGY slot; without one, it needs 2 DIR.\n"
		+ "Fewer than 2 DIR or no legal action means GAME OVER."
	))

	_section(root, "HEAT")
	root.add_child(_loop_row(
		Glyph.KIND_COOL,
		"Kills raise HEAT",
		"A normal turn without a kill lowers HEAT by one; a hit resets it.\n"
		+ "Higher HEAT gives more ENERGY from normal kills."
	))

	_section(root, "ENERGY")
	root.add_child(_ability_table())

# -- small builders --------------------------------------------------------

func _text(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("line_spacing", 4)
	return label

func _section(parent: Node, heading: String) -> void:
	# The tight row rhythm keeps the page on one screen, so each heading buys
	# back its own separation instead of widening the gap between every row.
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(_text(heading, 20, HEADING_COLOR))
	parent.add_child(pad)

func _key_column(rows: Array) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	for row in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		var name_label := _text(String(row[0]), 17, DIM_COLOR)
		name_label.custom_minimum_size = Vector2(80, 22)
		line.add_child(name_label)
		line.add_child(_text(String(row[1]), 17, BODY_COLOR))
		column.add_child(line)
	return column

func _ability_table() -> GridContainer:
	var table := GridContainer.new()
	table.columns = 3
	table.add_theme_constant_override("h_separation", 18)
	table.add_theme_constant_override("v_separation", 4)
	_add_ability_row(
		table,
		"STEP (X)",
		"1 slot",
		"Move to an empty cell without cooling HEAT or advancing the turn."
	)
	_add_ability_row(
		table,
		"DASH (Z)",
		"full bar",
		"Four freely aimed dashes. First 3 pause spawning."
	)
	return table

func _add_ability_row(table: GridContainer, ability: String, cost: String, detail: String) -> void:
	var ability_label := _text(ability, 17, BODY_COLOR)
	ability_label.custom_minimum_size.x = 92.0
	table.add_child(ability_label)
	var cost_label := _text(cost, 15, HEADING_COLOR)
	cost_label.custom_minimum_size.x = 72.0
	table.add_child(cost_label)
	table.add_child(_text(detail, 15, DIM_COLOR))

func _glyph(kind: int, glyph_size: Vector2) -> Control:
	var glyph := Glyph.new()
	glyph.kind = kind
	glyph.custom_minimum_size = glyph_size
	return glyph

func _loop_row(kind: int, heading: String, body: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.add_child(_glyph(kind, Vector2(248, 72)))
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 4)
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_child(_text(heading, 20, BODY_COLOR))
	copy.add_child(_text(body, 15, RULE_BODY_COLOR))
	row.add_child(copy)
	return row

# -- the drawn diagrams ----------------------------------------------------

class Glyph extends Control:
	const KIND_BANK := 0
	const KIND_KILL := 1
	const KIND_COOL := 2
	const KIND_WARNING := 3

	var kind: int = KIND_BANK

	func _draw() -> void:
		match kind:
			KIND_BANK:
				_draw_bank()
			KIND_KILL:
				_draw_kill()
			KIND_COOL:
				_draw_cool()
			KIND_WARNING:
				_draw_warning()

	func _cell(at: Vector2, cell_size: float) -> void:
		var rect := Rect2(at, Vector2(cell_size, cell_size))
		draw_rect(rect, DIRExtraHelpPanel.CELL_LIVE_COLOR)
		draw_rect(rect, DIRExtraHelpPanel.CELL_EDGE_COLOR, false, 2.0)

	func _diamond(center: Vector2, radius: float, color: Color) -> void:
		draw_colored_polygon(
			PackedVector2Array([
				center + Vector2(0, -radius),
				center + Vector2(radius, 0),
				center + Vector2(0, radius),
				center + Vector2(-radius, 0),
			]),
			color
		)

	func _octagon(center: Vector2, radius: float) -> void:
		# Same point-up orientation as the board enemy, rather than the flat-top
		# regular-octagon approximation used by the first help draft.
		var points := PackedVector2Array([
			center + Vector2(0, -radius),
			center + Vector2(radius * 0.7, -radius * 0.7),
			center + Vector2(radius, 0),
			center + Vector2(radius * 0.7, radius * 0.7),
			center + Vector2(0, radius),
			center + Vector2(-radius * 0.7, radius * 0.7),
			center + Vector2(-radius, 0),
			center + Vector2(-radius * 0.7, -radius * 0.7),
		])
		draw_colored_polygon(points, DIRExtraHelpPanel.ENEMY_FILL_COLOR)
		points.append(points[0])
		draw_polyline(points, DIRExtraHelpPanel.ENEMY_EDGE_COLOR, 2.0)

	func _chevron(tip: Vector2, depth: float, half_height: float, color: Color) -> void:
		draw_polyline(
			PackedVector2Array([
				tip + Vector2(-depth, -half_height),
				tip,
				tip + Vector2(-depth, half_height),
			]),
			color,
			3.0
		)

	const CELL := 54.0
	const CELL_TOP := 9.0
	const MID := 36.0

	func _draw_bank() -> void:
		# Player steps right into an empty cell, and the direction it moved
		# appears as a banked chevron.
		_cell(Vector2(4, CELL_TOP), CELL)
		_cell(Vector2(82, CELL_TOP), CELL)
		_diamond(Vector2(31, MID), 14, DIRExtraHelpPanel.PLAYER_COLOR)
		_chevron(Vector2(78, MID), 10, 9, DIRExtraHelpPanel.DIM_COLOR)
		draw_line(Vector2(150, MID), Vector2(172, MID), DIRExtraHelpPanel.DIM_COLOR, 2.0)
		_chevron(Vector2(178, MID), 8, 7, DIRExtraHelpPanel.DIM_COLOR)
		# The banked slot it produces.
		_chevron(Vector2(214, MID), 12, 11, DIRExtraHelpPanel.DIRECTION_COLOR)

	func _draw_kill() -> void:
		# The banked chevron is spent, and the enemy beside the player dies.
		_cell(Vector2(4, CELL_TOP), CELL)
		_cell(Vector2(82, CELL_TOP), CELL)
		_diamond(Vector2(31, MID), 14, DIRExtraHelpPanel.PLAYER_COLOR)
		_octagon(Vector2(109, MID), 19)
		_chevron(Vector2(78, MID), 10, 9, DIRExtraHelpPanel.DIRECTION_COLOR)
		draw_line(Vector2(150, MID), Vector2(172, MID), DIRExtraHelpPanel.DIM_COLOR, 2.0)
		_cell(Vector2(180, CELL_TOP), CELL)
		_diamond(Vector2(207, MID), 14, DIRExtraHelpPanel.PLAYER_COLOR)

	func _draw_cool() -> void:
		# A full meter exposes the actual five-stage heat palette.
		var segment_width: float = 32.0
		var gap: float = 5.0
		for i in ScoreManager.MAX_COMBO_TIER:
			var at := Vector2(4 + float(i) * (segment_width + gap), MID - 9.0)
			draw_rect(
				Rect2(at, Vector2(segment_width, 18)),
				DIRExtraHeatMeter.HEAT_COLORS[i]
			)

	func _draw_warning() -> void:
		# Match the board's corner warning exactly; a separate outline shape would
		# look like a fourth cell state.
		_cell(Vector2(4, CELL_TOP), CELL)
		_draw_warning_corners(Vector2(4, CELL_TOP), CELL)
		draw_line(Vector2(74, MID), Vector2(96, MID), DIRExtraHelpPanel.DIM_COLOR, 2.0)
		_chevron(Vector2(102, MID), 8, 7, DIRExtraHelpPanel.DIM_COLOR)
		_cell(Vector2(118, CELL_TOP), CELL)
		_octagon(Vector2(145, MID), 19)

	func _draw_warning_corners(at: Vector2, cell_size: float) -> void:
		const INSET := 7.0
		const ARM_LENGTH := 12.0
		const LINE_WIDTH := 3.0
		var left: float = at.x + INSET
		var right: float = at.x + cell_size - INSET
		var top: float = at.y + INSET
		var bottom: float = at.y + cell_size - INSET
		var segments: Array[PackedVector2Array] = [
			PackedVector2Array([Vector2(left, top + ARM_LENGTH), Vector2(left, top), Vector2(left + ARM_LENGTH, top)]),
			PackedVector2Array([Vector2(right - ARM_LENGTH, top), Vector2(right, top), Vector2(right, top + ARM_LENGTH)]),
			PackedVector2Array([Vector2(left, bottom - ARM_LENGTH), Vector2(left, bottom), Vector2(left + ARM_LENGTH, bottom)]),
			PackedVector2Array([Vector2(right - ARM_LENGTH, bottom), Vector2(right, bottom), Vector2(right, bottom - ARM_LENGTH)]),
		]
		for segment: PackedVector2Array in segments:
			draw_polyline(segment, DIRExtraHelpPanel.SPAWN_WARNING_COLOR, LINE_WIDTH, true)
