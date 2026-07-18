class_name AsciiMapParser
extends RefCounted

const EMPTY := 0
const WALL := 1


# Map symbols: # wall, . floor, * block target, @ player, A-Z named blocks.
static func parse(map_text: String) -> Dictionary:
	var lines: PackedStringArray = map_text.strip_edges().split("\n", false)
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
				_:
					var symbol_code := symbol.unicode_at(0)
					if symbol_code < 65 or symbol_code > 90:
						return {"error": "Unsupported symbol '%s' at (%d, %d)." % [symbol, x, y]}
					if block_labels.has(symbol):
						return {"error": "Block label '%s' is duplicated." % symbol}
					block_labels[symbol] = true
					blocks.append({
						"id": blocks.size() + 1,
						"label": symbol,
						"cell": Vector2i(x, y),
						"vector": "",
					})
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
