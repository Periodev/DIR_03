class_name Dir3VisualStyle
extends RefCounted

const CELL_SIZE := 96
const BOARD_OFFSET := Vector2(96, 96)
const DEBUG_PANEL_POSITION := Vector2(1090, 96)

const BEVEL_RATIO := 0.07
const WALL_SHADOW_RATIO := 0.16
const WALL_HATCH_WIDTH_RATIO := 2.0 / 96.0
const WALL_HATCH_PERIOD_RATIO := 9.0 / 96.0
const BLOCK_INSET_RATIO := 0.19
const GOAL_INSET_RATIO := 0.19
const PLAYER_INSET_RATIO := 0.16
const BLOCK_GLYPH_RATIO := 0.32
const PLAYER_GLYPH_RATIO := 0.34
const PLATE_SAFE_RATIO := 0.62

const FENCE_POST_W_RATIO := 0.145
const FENCE_POST_GAP_RATIO := 0.105
const FENCE_THICKNESS_RATIO := 0.14
const FENCE_TOP_RATIO := 0.16
const FENCE_BASE_RATIO := 0.20

const WALL_STYLE_SOLID := 0
const WALL_STYLE_HATCHED := 1
const WALL_STYLE := WALL_STYLE_SOLID

const MONO_DARK := {
	"app_bg": Color("#111111"),
	"floor": Color("#1b2025"),
	"grid": Color("#293139"),
	"wall": Color("#2c333a"),
	"wall_hatch": Color("#3a444d"),
	"wall_edge": Color("#4d5a66"),
	"wall_top": Color("#566370"),
	"wall_side": Color("#39434c"),
	"wall_base": Color("#0b0e11"),
	"ground_shadow": Color(0, 0, 0, 0.55),
	"post_fill": Color("#4e4e4e"),
	"post_top": Color("#9c9c9c"),
	"post_base": Color("#0a0a0a"),
	"goal": Color("#8c8c8c"),
	"block": Color("#9a9a9a"),
	"block_band": Color("#7e7e7e"),
	"block_loaded": Color("#c9c9c9"),
	"block_glyph": Color("#141414"),
	"player": Color("#f2f2f2"),
	"player_glyph": Color("#141414"),
	"hair": Color("#282828"),
	"stroke": Color("#3a3a3a"),
	"label": Color("#6e6e6e"),
	"text": Color("#d6d6d6"),
	"text_hi": Color("#f2f2f2"),
	"text_dim": Color("#8a8a8a"),
	"hover_bg": Color(0, 0, 0, 0),
	"hover_stroke": Color("#5c5c5c"),
}

const MONO_LIGHT := {
	"app_bg": Color("#d4d2cd"),
	"floor": Color("#d9dfe4"),
	"grid": Color("#c5ced6"),
	"wall": Color("#cbd3da"),
	"wall_hatch": Color("#b9c4cd"),
	"wall_edge": Color("#a8b5c0"),
	"wall_top": Color("#e7ebee"),
	"wall_side": Color("#c0cad2"),
	"wall_base": Color("#a5b0ba"),
	"ground_shadow": Color(0, 0, 0, 0.16),
	"post_fill": Color("#8f8d88"),
	"post_top": Color("#d9d7d2"),
	"post_base": Color("#4a4947"),
	"goal": Color("#807e7a"),
	"block": Color("#6e6c68"),
	"block_band": Color("#8b8985"),
	"block_loaded": Color("#3f3e3b"),
	"block_glyph": Color("#f4f3f1"),
	"player": Color("#1e1d1c"),
	"player_glyph": Color("#f4f3f1"),
	"hair": Color("#cbc9c4"),
	"stroke": Color("#b9b7b2"),
	"label": Color("#8b8a86"),
	"text": Color("#3a3a38"),
	"text_hi": Color("#171717"),
	"text_dim": Color("#6a6a67"),
	"hover_bg": Color("#e6e4df"),
	"hover_stroke": Color("#cfcdc8"),
}


static func theme(light: bool = false) -> Dictionary:
	return MONO_LIGHT if light else MONO_DARK
