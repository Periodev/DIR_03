class_name DirVisualStyle
extends RefCounted

const CELL_SIZE := 96
const PLAYER_CELL_SCALE := 1.5
const PLAYER_CELL_SIZE := CELL_SIZE * PLAYER_CELL_SCALE
const BOARD_OFFSET := Vector2(96, 96)
const DEBUG_PANEL_POSITION := Vector2(1090, 96)

const BEVEL_RATIO := 0.07
const WALL_SHADOW_RATIO := 0.16
const WALL_HATCH_WIDTH_RATIO := 2.0 / 96.0
const WALL_HATCH_PERIOD_RATIO := 9.0 / 96.0
const BLOCK_INSET_RATIO := 0.19
const BLOCK_EDGE_RATIO := 2.0 / 96.0
const GOAL_INSET_RATIO := 0.21
const BLOCK_GLYPH_RATIO := 0.32
const PLATE_SAFE_RATIO := 0.62
const GOAL_STROKE_RATIO := 3.0 / 96.0
const GOAL_DASH_RATIO := 7.0 / 96.0
const GOAL_DASH_GAP_RATIO := 5.0 / 96.0
const SHOW_GRID_LINES := false

const PLAYER_BODY_RATIO := 0.66
const PLAYER_TRI_H_RATIO := 0.20
const PLAYER_TRI_W_RATIO := PLAYER_TRI_H_RATIO * 2.0
const STORED_VECTOR_OFFSET_RATIO := PLAYER_TRI_H_RATIO / 2.0
const FACING_CHV_LEN_RATIO := 0.44
const FACING_CHV_DEPTH_RATIO := 0.20
const FACING_CHV_STROKE_RATIO := 0.40
const FACING_CHV_GAP_RATIO := 0.026
const FACING_CHV_INSET_RATIO := 0.025
const FACING_CHV_OUTLINE_RATIO := 0.010
const FACING_CHV_CLEARANCE_RATIO := 0.014
const FACING_ACTION_RETREAT_RATIO := 0.066
const FACING_ACTION_FORWARD_RATIO := 0.110
const FACING_ACTION_RETREAT_SECONDS := 0.030
const FACING_ACTION_HOLD_SECONDS := 0.030
const FACING_ACTION_FORWARD_SECONDS := 0.060
const FACING_ACTION_SETTLE_SECONDS := 0.030
const PUSH_DISPLACEMENT_DELAY_SECONDS := 0.12
const INSTALL_VECTOR_DELAY_SECONDS := 0.12
const DISPLACEMENT_SECONDS := 0.10
const TRIGGER_FLASH_IN_SECONDS := 0.04
const TRIGGER_FLASH_HOLD_SECONDS := 0.05
const TRIGGER_FLASH_OUT_SECONDS := DISPLACEMENT_SECONDS
const ERROR_FLASH_SECONDS := 0.30
const ERROR_FLASH_MAX_ALPHA := 180.0 / 255.0
const HINT_FLASH_SECONDS := 0.18
const HINT_FLASH_MAX_ALPHA := 0.20
const ACTIVE_VECTOR_PULSE_SECONDS := 0.60
const ACTIVE_VECTOR_PULSE_PAUSE_SECONDS := 1.40
const ACTIVE_VECTOR_OUTLINE_WIDTH_RATIO := 2.0 / 96.0
const ACTIVE_VECTOR_OUTLINE_ALPHA := 0.55
const INSTALL_TUTORIAL_HINT_DELAY_SECONDS := 0.0
const INSTALL_TUTORIAL_HINT_FADE_SECONDS := 0.15
const TUTORIAL_X_KEY_SIZE := Vector2(40.0, 40.0)
const TUTORIAL_SPACE_KEY_SIZE := Vector2(96.0, 80.0)
const TUTORIAL_KEY_GAP := 16.0
const TUTORIAL_SPACE_KEY_GAP := 0.0
const BLOCKED_RELEASE_SHAKE_RATIO := 0.050
const BLOCKED_RELEASE_SHAKE_SECONDS := 0.12
const BLOCKED_RELEASE_SHAKE_CYCLES := 2.0
const COLLISION_COMPRESSION_RATIO := 0.010
const COLLISION_CONTACT_OFFSET_RATIO := (
	BLOCK_INSET_RATIO + COLLISION_COMPRESSION_RATIO
)
const COLLISION_TARGET_SECONDS := 0.13
const COLLISION_TARGET_LEAD_RATIO := 0.05
const COLLISION_TARGET_LEAD_SECONDS := 0.025
const COLLISION_TARGET_FOLLOW_SECONDS := (
	COLLISION_TARGET_SECONDS - COLLISION_TARGET_LEAD_SECONDS
)
const COLLISION_APPROACH_SECONDS := (
	COLLISION_TARGET_SECONDS * COLLISION_CONTACT_OFFSET_RATIO
)
const COLLISION_HOLD_SECONDS := 0.050
const COLLISION_RETURN_SECONDS := 0.07
const COMPLETION_PULSE_DELAY_SECONDS := 0.12
const COMPLETION_PULSE_SECONDS := 0.32
const COMPLETION_PULSE_EXPAND_RATIO := 0.08

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
	"goal_complete": Color("#f2f2f2"),
	"block": Color("#b9823d"),
	"block_edge": Color("#101316"),
	"block_band": Color("#8e622f"),
	"block_loaded": Color("#b9823d"),
	"block_glyph": Color("#141414"),
	"direction_fill": Color("#141414"),
	"active_vector_outline": Color("#f2f2f2"),
	"tutorial_hint": Color("#f2f2f2"),
	"player": Color("#b8bec4"),
	"error_flash": Color("#ff3232"),
	"hint_flash": Color("#dedede"),
	"trigger_flash": Color("#dedede"),
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
	"goal_complete": Color("#1e1d1c"),
	"block": Color("#a66f34"),
	"block_edge": Color("#4b3521"),
	"block_band": Color("#c18a50"),
	"block_loaded": Color("#a66f34"),
	"block_glyph": Color("#f4f3f1"),
	"direction_fill": Color("#f4f3f1"),
	"active_vector_outline": Color("#1e1d1c"),
	"tutorial_hint": Color("#1e1d1c"),
	"player": Color("#484746"),
	"error_flash": Color("#ff3232"),
	"hint_flash": Color("#30302f"),
	"trigger_flash": Color("#30302f"),
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
