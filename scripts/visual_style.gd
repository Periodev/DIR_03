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
const BLOCK_GLYPH_RATIO := 0.32
const PLATE_SAFE_RATIO := 0.62
const GOAL_STROKE_RATIO := 3.0 / 96.0
const GOAL_DASH_RATIO := 7.0 / 96.0
const GOAL_DASH_GAP_RATIO := 5.0 / 96.0

const PLAYER_BODY_RATIO := 0.66
const PLAYER_TRI_W_RATIO := 0.21
const PLAYER_TRI_H_RATIO := 0.18
const FACING_CHV_LEN_RATIO := 0.38
const FACING_CHV_DEPTH_RATIO := 0.17
const FACING_CHV_STROKE_RATIO := 0.48
const FACING_CHV_GAP_RATIO := 0.026
const FACING_CHV_CLEARANCE_RATIO := 0.02

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
	"floor": Color("#19212a"),
	"grid": Color("#27333e"),
	"wall": Color("#303337"),
	"wall_hatch": Color("#404449"),
	"wall_edge": Color("#4a4f55"),
	"wall_top": Color("#585e64"),
	"wall_side": Color("#3d4146"),
	"wall_base": Color("#0d0e10"),
	"ground_shadow": Color(0, 0, 0, 0.55),
	"post_fill": Color("#4e4e4e"),
	"post_top": Color("#9c9c9c"),
	"post_base": Color("#0a0a0a"),
	"goal": Color("#8c8c8c"),
	"block": Color("#b9823d"),
	"block_band": Color("#8e622f"),
	"block_loaded": Color("#b9823d"),
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
	"floor": Color("#d9e0e6"),
	"grid": Color("#c3cdd5"),
	"wall": Color("#cbc9c5"),
	"wall_hatch": Color("#bbb9b5"),
	"wall_edge": Color("#aaa8a4"),
	"wall_top": Color("#e5e3df"),
	"wall_side": Color("#bebcb7"),
	"wall_base": Color("#a4a19c"),
	"ground_shadow": Color(0, 0, 0, 0.16),
	"post_fill": Color("#8f8d88"),
	"post_top": Color("#d9d7d2"),
	"post_base": Color("#4a4947"),
	"goal": Color("#807e7a"),
	"block": Color("#a66f34"),
	"block_band": Color("#c18a50"),
	"block_loaded": Color("#a66f34"),
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
