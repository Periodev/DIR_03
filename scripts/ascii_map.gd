class_name AsciiMapParser
extends RefCounted

const EMPTY := 0
const WALL := 1
const EDGE_FORMAT_HEADER := "!cell-edge-v1"
const BLOCK_KIND_NORMAL := "normal"
const BLOCK_KIND_RECOVERY := "recovery"
const RECOVERY_BLOCK_START_CODE := 82 # R


# Symbols: # wall, . floor, * target, @ player, + player on target.
# A-Q are normal blocks and R-Z are recovery blocks; lowercase variants start on targets.
static func parse(map_text: String) -> Dictionary:
	var normalized_text := map_text.replace("\r\n", "\n").replace("\r", "\n").strip_edges()
	if normalized_text.is_empty():
		return {"error": "Map is empty."}

	var lines: PackedStringArray = normalized_text.split("\n", false)
	if lines[0].strip_edges() == EDGE_FORMAT_HEADER:
		return parse_cell_edge_map(lines)

	var legacy_data := parse_cells(lines)
	if legacy_data.has("error"):
		return legacy_data
	legacy_data["horizontal_edges"] = make_open_edges(legacy_data["terrain"].size() - 1, legacy_data["terrain"][0].size())
	legacy_data["vertical_edges"] = make_open_edges(legacy_data["terrain"].size(), legacy_data["terrain"][0].size() - 1)
	return legacy_data


static func parse_cell_edge_map(lines: PackedStringArray) -> Dictionary:
	var sections := {
		"cells": PackedStringArray(),
		"horizontal_edges": PackedStringArray(),
		"vertical_edges": PackedStringArray(),
	}
	var current_section := ""

	for index in range(1, lines.size()):
		var line := lines[index].strip_edges()
		if line.is_empty():
			continue
		if line.begins_with("[") and line.ends_with("]"):
			var section_name := line.substr(1, line.length() - 2)
			if not sections.has(section_name):
				return {"error": "Unknown section '%s'." % line}
			if not sections[section_name].is_empty():
				return {"error": "Section '%s' appears more than once." % section_name}
			current_section = section_name
			continue
		if current_section.is_empty():
			return {"error": "Map data appears before a section header."}
		var section_lines: PackedStringArray = sections[current_section]
		section_lines.append(line)
		sections[current_section] = section_lines

	for section_name in sections:
		if sections[section_name].is_empty():
			return {"error": "Missing or empty section '[%s]'." % section_name}

	var cell_data := parse_cells(sections["cells"])
	if cell_data.has("error"):
		return cell_data

	var height: int = cell_data["terrain"].size()
	var width: int = cell_data["terrain"][0].size()
	if width < 2 or height < 2:
		return {"error": "!cell-edge-v1 maps must be at least 2 by 2 cells."}

	var horizontal_data := parse_edge_rows(sections["horizontal_edges"], height - 1, width, "-", "horizontal_edges")
	if horizontal_data.has("error"):
		return horizontal_data
	var vertical_data := parse_edge_rows(sections["vertical_edges"], height, width - 1, "|", "vertical_edges")
	if vertical_data.has("error"):
		return vertical_data

	cell_data["horizontal_edges"] = horizontal_data["edges"]
	cell_data["vertical_edges"] = vertical_data["edges"]
	return cell_data


static func parse_cells(lines: PackedStringArray) -> Dictionary:
	if lines.is_empty():
		return {"error": "Map is empty."}

	var width := -1
	var terrain: Array[Array] = []
	var blocks: Array[Dictionary] = []
	var goal_cells: Array[Vector2i] = []
	var block_labels := {}
	var player_cell := Vector2i(-1, -1)

	for y in range(lines.size()):
		var line := lines[y].strip_edges()
		if width == -1:
			width = line.length()
		elif line.length() != width:
			return {"error": "Map row %d has width %d; expected %d." % [y, line.length(), width]}

		var row: Array = []
		for x in range(line.length()):
			var symbol := line.substr(x, 1)
			match symbol:
				"#":
					row.append(WALL)
				".":
					row.append(EMPTY)
				"*":
					goal_cells.append(Vector2i(x, y))
					row.append(EMPTY)
				"@":
					if player_cell != Vector2i(-1, -1):
						return {"error": "Map contains more than one player (@)."}
					player_cell = Vector2i(x, y)
					row.append(EMPTY)
				"+":
					if player_cell != Vector2i(-1, -1):
						return {"error": "Map contains more than one player (@ or +)."}
					player_cell = Vector2i(x, y)
					goal_cells.append(Vector2i(x, y))
					row.append(EMPTY)
				_:
					var symbol_code := symbol.unicode_at(0)
					var is_uppercase_block := symbol_code >= 65 and symbol_code <= 90
					var is_lowercase_block := symbol_code >= 97 and symbol_code <= 122
					if not is_uppercase_block and not is_lowercase_block:
						return {"error": "Unsupported symbol '%s' at (%d, %d)." % [symbol, x, y]}
					var block_label := symbol.to_upper()
					if block_labels.has(block_label):
						return {"error": "Block label '%s' is duplicated." % block_label}
					block_labels[block_label] = true
					var block_kind := BLOCK_KIND_RECOVERY if block_label.unicode_at(0) >= RECOVERY_BLOCK_START_CODE else BLOCK_KIND_NORMAL
					blocks.append({
						"id": blocks.size() + 1,
						"label": block_label,
						"kind": block_kind,
						"cell": Vector2i(x, y),
						"vector": "",
					})
					if is_lowercase_block:
						goal_cells.append(Vector2i(x, y))
					row.append(EMPTY)
		terrain.append(row)

	if width <= 0:
		return {"error": "Map rows cannot be empty."}
	if player_cell == Vector2i(-1, -1):
		return {"error": "Map must contain one player (@)."}

	return {
		"terrain": terrain,
		"player_cell": player_cell,
		"blocks": blocks,
		"goal_cells": goal_cells,
	}


static func parse_edge_rows(lines: PackedStringArray, expected_rows: int, expected_width: int, fence_symbol: String, section_name: String) -> Dictionary:
	if lines.size() != expected_rows:
		return {"error": "[%s] has %d rows; expected %d." % [section_name, lines.size(), expected_rows]}

	var edges: Array[Array] = []
	for y in range(lines.size()):
		var line := lines[y]
		if line.length() != expected_width:
			return {"error": "[%s] row %d has width %d; expected %d." % [section_name, y, line.length(), expected_width]}
		var edge_row: Array = []
		for x in range(line.length()):
			var symbol := line.substr(x, 1)
			if symbol == ".":
				edge_row.append(false)
			elif symbol == fence_symbol:
				edge_row.append(true)
			else:
				return {"error": "Unsupported [%s] symbol '%s' at (%d, %d)." % [section_name, symbol, x, y]}
		edges.append(edge_row)

	return {"edges": edges}


static func make_open_edges(row_count: int, column_count: int) -> Array[Array]:
	var edges: Array[Array] = []
	for _row_index in range(row_count):
		var row: Array = []
		for _column_index in range(column_count):
			row.append(false)
		edges.append(row)
	return edges
