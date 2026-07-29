$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $root "scripts/main.gd"
$gameBoardPath = Join-Path $root "scripts/game_board.gd"
$boardViewPath = Join-Path $root "scripts/board_view.gd"
$playerBoardViewPath = Join-Path $root "scripts/player_board_view.gd"
$gameHudPath = Join-Path $root "scripts/game_hud.gd"
$playerInterfacePath = Join-Path $root "scripts/player_interface.gd"
$debugPanelPath = Join-Path $root "scripts/debug_panel.gd"
$visualStylePath = Join-Path $root "scripts/visual_style.gd"
$debugStylePath = Join-Path $root "scripts/debug_style.gd"
$commandPlayerPath = Join-Path $root "scripts/command_player.gd"
$commandPlayerScenePath = Join-Path $root "scenes/command_player.tscn"
$asciiMapPath = Join-Path $root "scripts/ascii_map.gd"
$levelPath = Join-Path $root "levels/level_test.txt"
$projectPath = Join-Path $root "project.godot"
$editorPath = Join-Path $root "tools/level_editor.html"
$playerAnimationCheckPath = Join-Path $root "tools/verify_player_animation.gd"
$pyprojectPath = Join-Path $root "pyproject.toml"
$solverCliPath = Join-Path $root "solver/cli.py"

$mainEntry = Get-Content -LiteralPath $mainPath -Raw
$gameBoard = Get-Content -LiteralPath $gameBoardPath -Raw
$boardView = Get-Content -LiteralPath $boardViewPath -Raw
$playerBoardView = Get-Content -LiteralPath $playerBoardViewPath -Raw
$gameHud = Get-Content -LiteralPath $gameHudPath -Raw
$playerInterface = Get-Content -LiteralPath $playerInterfacePath -Raw
$debugPanel = Get-Content -LiteralPath $debugPanelPath -Raw
$visualStyle = Get-Content -LiteralPath $visualStylePath -Raw
$debugStyle = Get-Content -LiteralPath $debugStylePath -Raw
$main = "$mainEntry`n$gameBoard`n$boardView`n$playerBoardView`n$gameHud`n$playerInterface`n$debugPanel`n$visualStyle`n$debugStyle"
$commandPlayer = Get-Content -LiteralPath $commandPlayerPath -Raw
$commandPlayerScene = Get-Content -LiteralPath $commandPlayerScenePath -Raw
$asciiMap = Get-Content -LiteralPath $asciiMapPath -Raw
$level = Get-Content -LiteralPath $levelPath -Raw
$project = Get-Content -LiteralPath $projectPath -Raw
$editor = Get-Content -LiteralPath $editorPath -Raw
$playerAnimationCheck = Get-Content -LiteralPath $playerAnimationCheckPath -Raw
$pyproject = Get-Content -LiteralPath $pyprojectPath -Raw
$solverCli = Get-Content -LiteralPath $solverCliPath -Raw
$legacyProductName = "DIR" + "3"

$checks = @(
	@{
		Name = "main.gd uses player_queue"
		Pass = $main -match "var\s+player_queue\s*:="
	},
	@{
		Name = "main.gd uses block dictionaries"
		Pass = $main -match "var\s+blocks:\s*Array\[Dictionary\]"
	},
	@{
		Name = "main.gd tracks install_order by block id"
		Pass = $main -match "var\s+install_order:\s*Array\[int\]"
	},
	@{
		Name = "main.gd removed old momentum_slot"
		Pass = $main -notmatch "momentum_slot"
	},
	@{
		Name = "main.gd removed old block_cells"
		Pass = $main -notmatch "block_cells"
	},
	@{
		Name = "main.gd has install_vector operation"
		Pass = $main -match "func\s+install_vector\(\)"
	},
	@{
		Name = "main.gd has trigger_vector operation"
		Pass = $main -match "func\s+trigger_vector\(\)"
	},
	@{
		Name = "main.gd has debug log panel support"
		Pass = $main -match "debug_log_label" -and $main -match "append_debug_log"
	},
	@{
		Name = "main.gd writes debug logs to the IDE console"
		Pass = $main -match 'print\("\[DIR\] %s" % line\)'
	},
	@{
		Name = "project consistently uses the formal DIR product name"
		Pass = $project -match 'config/name="DIR"' -and $playerInterface -match 'make_label\("DIR",\s*14,\s*mono_label_font\)' -and $editor -match '<title>DIR Level Editor</title>' -and $pyproject -match 'name\s*=\s*"dir-solver"' -and $pyproject -match 'dir-solve\s*=\s*"solver\.cli:main"' -and $solverCli -match 'prog="dir-solve"' -and "$main`n$project`n$editor`n$pyproject`n$solverCli" -notmatch [regex]::Escape($legacyProductName)
	},
	@{
		Name = "GDScript global classes use the DIR prefix"
		Pass = $boardView -match "class_name\s+DirBoardView" -and $debugPanel -match "class_name\s+DirDebugPanel" -and $debugStyle -match "class_name\s+DirDebugStyle" -and $gameHud -match "class_name\s+DirGameHud" -and $playerBoardView -match "class_name\s+DirPlayerBoardView" -and $playerInterface -match "class_name\s+DirPlayerInterface" -and $visualStyle -match "class_name\s+DirVisualStyle"
	},
	@{
		Name = "project.godot defines install_vector input"
		Pass = $project -match "install_vector="
	},
	@{
		Name = "project.godot defines trigger_vector input"
		Pass = $project -match "trigger_vector="
	},
	@{
		Name = "project.godot defines reset_level input"
		Pass = $project -match "reset_level="
	},
	@{
		Name = "project.godot binds player reset to R"
		Pass = $project -match 'reset_level=\{[\s\S]*?keycode":82'
	},
	@{
		Name = "project.godot defines Z undo input"
		Pass = $project -match "undo_command=" -and $project -match 'keycode":90'
	},
	@{
		Name = "main.gd has reset_level operation"
		Pass = $main -match "func\s+reset_level\(\)"
	},
	@{
		Name = "main.gd handles reset_level input"
		Pass = $mainEntry -match 'is_action_pressed\("reset_level"\)[\s\S]*if input_locked:'
	},
	@{
		Name = "main game handles undo before completion lock"
		Pass = $mainEntry -match 'is_action_pressed\("undo_command"\)[\s\S]*if level_completed:'
	},
	@{
		Name = "game board snapshots complete dynamic state"
		Pass = $gameBoard -match "class\s+BoardSnapshot" -and $gameBoard -match "blocks:\s*Array\[Dictionary\]" -and $gameBoard -match "command_history:\s*Array\[String\]"
	},
	@{
		Name = "undo pops without adding another snapshot"
		Pass = $gameBoard -match "undo_stack\.pop_back\(\)" -and $gameBoard -notmatch 'func\s+undo_last_command\(\)[\s\S]*?undo_stack\.append\('
	},
	@{
		Name = "reset clears undo history"
		Pass = $gameBoard -match "func\s+reset_level\(\)[\s\S]*?undo_stack\.clear\(\)"
	},
	@{
		Name = "command player has no undo controls"
		Pass = $commandPlayer -notmatch "undo_command|undo_last_command"
	},
	@{
		Name = "main.gd does not draw block labels in board cells"
		Pass = $main -notmatch "add_centered_label\(object_layer,\s*cell,\s*block_label"
	},
	@{
		Name = "main.gd draws installed vector arrows in board cells"
		Pass = $main -match "add_centered_label\([\s\S]*?object_layer,[\s\S]*?cell,[\s\S]*?momentum_arrow\(vector_name\)"
	},
	@{
		Name = "main.gd uses large installed vector arrow font"
		Pass = $main -match "const\s+INSTALLED_VECTOR_FONT_SIZE\s*:=\s*(4[4-9]|[5-9][0-9])"
	},
	@{
		Name = "main.gd overwrites player queue on successful push"
		Pass = $main -match "player_queue\s*=\s*direction_name"
	},
	@{
		Name = "main.gd turns toward blocks before attempting a push"
		Pass = $main -match "block_index\s*!=\s*-1\s+and\s+facing_direction\s*!=\s*direction" -and $main -match "faced block.*without pushing"
	},
	@{
		Name = "main.gd has no queue rejection feedback"
		Pass = $main -notmatch "Queue full|rejected|reject"
	},
	@{
		Name = "ASCII map parser supports block target markers"
		Pass = $asciiMap -match '"\*"' -and $asciiMap -match '"goal_cells"'
	},
	@{
		Name = "ASCII map parser supports lowercase blocks on targets"
		Pass = $asciiMap -match "is_lowercase_block" -and $asciiMap -match "symbol\.to_upper\(\)"
	},
	@{
		Name = "ASCII map parser classifies R-Z as recovery blocks"
		Pass = $asciiMap -match "RECOVERY_BLOCK_START_CODE\s*:=\s*82" -and $asciiMap -match '"kind":\s*block_kind'
	},
	@{
		Name = "main.gd retrieves vectors from recovery blocks only while empty-handed"
		Pass = $main -match 'player_queue\s*==\s*""' -and $main -match 'is_recovery_block\(block\)' -and $main -match 'retrieve_recovery_vector\(block_index, block\)'
	},
	@{
		Name = "main.gd removes retrieved recovery blocks from install order by id"
		Pass = $main -match 'install_order\.erase\(block\["id"\]\)'
	},
	@{
		Name = "main.gd no longer recovers vectors when blocks hit the player"
		Pass = $main -notmatch 'is_recovery_block\(carrier\)'
	},
	@{
		Name = "main.gd visually distinguishes recovery blocks"
		Pass = $main -match "RECOVERY_BLOCK_COLOR" -and $main -match "add_recovery_marker"
	},
	@{
		Name = "level editor has a dedicated recovery block tool"
		Pass = $editor -match 'data-tool="recovery-block"' -and $editor -match 'swatch recovery'
	},
	@{
		Name = "level editor constrains block labels by block kind"
		Pass = $editor -match 'blockToolRanges' -and $editor -match '"recovery-block":\s*\{\s*first:\s*"R",\s*last:\s*"Z"'
	},
	@{
		Name = "ASCII map parser supports players on targets"
		Pass = $asciiMap -match '"\+"' -and $asciiMap -match 'player on target'
	},
	@{
		Name = "main.gd draws block target markers"
		Pass = $main -match "goal_cells\.has\(cell\)" -and $main -match "GOAL_MARKER_COLOR"
	},
	@{
		Name = "main.gd highlights blocks on target markers"
		Pass = $main -match "GOAL_BLOCK_BORDER_COLOR" -and $main -match "if game_board\.goal_cells\.has\(cell\):[\s\S]*?add_rect\("
	},
	@{
		Name = "main scene and command player share game_board.gd"
		Pass = $mainEntry -match 'extends\s+"res://scripts/game_board\.gd"' -and $commandPlayer -match 'extends\s+"res://scripts/game_board\.gd"'
	},
	@{
		Name = "player mode injects the monochrome board renderer"
		Pass = $mainEntry -match 'preload\("res://scripts/player_board_view\.gd"\)' -and $mainEntry -match "func\s+create_board_view\(\)[\s\S]*PlayerBoardView\.new\(\)"
	},
	@{
		Name = "player mode injects the player interface shell"
		Pass = $mainEntry -match 'preload\("res://scripts/player_interface\.gd"\)' -and $mainEntry -match "func\s+create_game_hud\(\)[\s\S]*PlayerInterface\.new\(\)"
	},
	@{
		Name = "player interface uses fixed header and status bars"
		Pass = $playerInterface -match "HEADER_HEIGHT\s*:=\s*60" -and $playerInterface -match "STATUS_HEIGHT\s*:=\s*88" -and $playerInterface -match "STAGE_MIN_HEIGHT\s*:=\s*480"
	},
	@{
		Name = "player interface centers a locally positioned board"
		Pass = $playerInterface -match "CenterContainer\.new\(\)" -and $playerInterface -match "board_host\.add_child\(board_view\)" -and $playerBoardView -match "return Vector2\(cell\.x \* cell_size, cell\.y \* cell_size\)"
	},
	@{
		Name = "player message keeps a fixed-height layout slot"
		Pass = $playerInterface -match "MESSAGE_HEIGHT\s*:=\s*20" -and $playerInterface -match "message_label\.clip_text\s*=\s*true"
	},
	@{
		Name = "player interface exposes facing slot goals and steps"
		Pass = $playerInterface -match "build_facing_group" -and $playerInterface -match "build_slot_group" -and $playerInterface -match 'build_value_group\("GOALS"' -and $playerInterface -match 'build_value_group\("STEPS"'
	},
	@{
		Name = "player interface uses English status and action labels"
		Pass = $playerInterface -match '"EMPTY"' -and $playerInterface -match '"HOLDING %s"' -and $playerInterface -match '"PUSH"' -and $playerInterface -match '"INSTALL"' -and $playerInterface -match '"TRIGGER"' -and $playerInterface -notmatch '"(\u7a7a|\u6301\u6709|\u63a8|\u5b89\u88dd|\u89f8\u767c)"'
	},
	@{
		Name = "player interface buttons do not capture gameplay keys"
		Pass = $playerInterface -match "func\s+make_button\([\s\S]*focus_mode\s*=\s*Control\.FOCUS_NONE"
	},
	@{
		Name = "player mode does not create a debug panel"
		Pass = $playerInterface -notmatch "DebugPanel" -and $gameHud -notmatch "add_debug_panel"
	},
	@{
		Name = "command player owns the separated debug panel"
		Pass = $commandPlayer -match 'preload\("res://scripts/debug_panel\.gd"\)' -and $commandPlayer -match "debug_panel\s*=\s*DebugPanel\.new\(\)" -and $debugPanel -match "class_name\s+DirDebugPanel"
	},
	@{
		Name = "command player keeps the debug board renderer"
		Pass = $gameBoard -match 'preload\("res://scripts/board_view\.gd"\)' -and $gameBoard -match "func\s+create_board_view\(\)[\s\S]*BoardView\.new\(\)" -and $commandPlayer -notmatch "create_board_view"
	},
	@{
		Name = "player style defines dark and light monochrome themes"
		Pass = $visualStyle -match "MONO_DARK" -and $visualStyle -match "MONO_LIGHT" -and $visualStyle -match '"app_bg"' -and $visualStyle -match '"floor"' -and $visualStyle -match '"wall_hatch"' -and $visualStyle -match '"post_fill"'
	},
	@{
		Name = "player style uses the revised low-contrast interface tones"
		Pass = $visualStyle -match '"hair": Color\("#282828"\)' -and $visualStyle -match '"stroke": Color\("#3a3a3a"\)' -and $visualStyle -match '"hair": Color\("#cbc9c4"\)' -and $visualStyle -match '"stroke": Color\("#b9b7b2"\)'
	},
	@{
		Name = "player and trigger tones reserve contrast headroom"
		Pass = $visualStyle -match '"player": Color\("#b8bec4"\)' -and $visualStyle -match '"trigger_flash": Color\("#dedede"\)' -and $visualStyle -match '"player": Color\("#484746"\)' -and $visualStyle -match '"trigger_flash": Color\("#30302f"\)'
	},
	@{
		Name = "player style separates cool floors from neutral steel walls"
		Pass = $visualStyle -match '"floor": Color\("#19212a"\)' -and $visualStyle -match '"grid": Color\("#27333e"\)' -and $visualStyle -match '"wall": Color\("#303337"\)' -and $visualStyle -match '"floor": Color\("#d9e0e6"\)' -and $visualStyle -match '"grid": Color\("#c3cdd5"\)' -and $visualStyle -match '"wall": Color\("#cbc9c5"\)'
	},
	@{
		Name = "player style keeps warm amber blocks unchanged when loaded"
		Pass = $visualStyle -match '"block": Color\("#b9823d"\)' -and $visualStyle -match '"block_loaded": Color\("#b9823d"\)' -and $visualStyle -match '"block": Color\("#a66f34"\)' -and $visualStyle -match '"block_loaded": Color\("#a66f34"\)' -and $playerBoardView -match 'var\s+color:\s*Color\s*=\s*palette\["block"\]'
	},
	@{
		Name = "player blocks use a scaled dark edge"
		Pass = $visualStyle -match "BLOCK_EDGE_RATIO\s*:=\s*2\.0\s*/\s*96\.0" -and $visualStyle -match '"block_edge": Color\("#101316"\)' -and $visualStyle -match '"block_edge": Color\("#4b3521"\)' -and $playerBoardView -match 'draw_rect\(block_rect,\s*edge_color\)[\s\S]*draw_rect\(block_rect\.grow\(-edge_width\),\s*color\)'
	},
	@{
		Name = "player renderer separates the app background from walkable floor cells"
		Pass = $playerInterface -match 'palette\["app_bg"\]' -and $playerBoardView -match 'palette\["floor"\]' -and $playerBoardView -match "if\s+is_wall_cell\(cell\):[\s\S]*continue"
	},
	@{
		Name = "debug views retain the original debug style"
		Pass = $boardView -match 'preload\("res://scripts/debug_style\.gd"\)' -and $gameHud -match 'preload\("res://scripts/debug_style\.gd"\)' -and $commandPlayer -match 'preload\("res://scripts/debug_style\.gd"\)'
	},
	@{
		Name = "player renderer draws ground shadows before walls"
		Pass = $playerBoardView -match "draw_ground\(\)[\s\S]*draw_wall_shadows\(\)[\s\S]*draw_walls\(\)"
	},
	@{
		Name = "player walls retain solid and hatched surface variants"
		Pass = $visualStyle -match "WALL_STYLE_SOLID\s*:=\s*0" -and $visualStyle -match "WALL_STYLE_HATCHED\s*:=\s*1" -and $visualStyle -match "WALL_STYLE\s*:=\s*WALL_STYLE_SOLID" -and $playerBoardView -match "WALL_STYLE\s*==\s*VisualStyle\.WALL_STYLE_HATCHED[\s\S]*draw_wall_hatch"
	},
	@{
		Name = "player walls use exposed-side bevels"
		Pass = $playerBoardView -match "is_wall_cell\(cell \+ Vector2i\.UP\)" -and $playerBoardView -match "is_wall_cell\(cell \+ Vector2i\.DOWN\)"
	},
	@{
		Name = "player fences use separated lit posts above blocks and below facing"
		Pass = $playerBoardView -match "draw_blocks\(\)[\s\S]*draw_fences\(\)[\s\S]*draw_player_body\(\)[\s\S]*draw_player_stored_vector\(\)[\s\S]*draw_player_facing\(\)" -and $playerBoardView -match "post_width \+ post_gap" -and $playerBoardView -match '"post_top"' -and $playerBoardView -match '"post_base"'
	},
	@{
		Name = "player renderer uses compact block and diamond body proportions"
		Pass = $visualStyle -match "PLAYER_BODY_RATIO\s*:=\s*0\.66" -and $playerBoardView -match "cell_size\s*\*\s*VisualStyle\.BLOCK_INSET_RATIO" -and $playerBoardView -match "cell_size\s*\*\s*VisualStyle\.PLAYER_BODY_RATIO" -and $playerBoardView -notmatch "DebugStyle"
	},
	@{
		Name = "player mode scales board cells to 1.5x without changing debug cells"
		Pass = $visualStyle -match "PLAYER_CELL_SCALE\s*:=\s*1\.5" -and $visualStyle -match "PLAYER_CELL_SIZE\s*:=\s*CELL_SIZE\s*\*\s*PLAYER_CELL_SCALE" -and $playerBoardView -match "cell_size\s*:=\s*float\(VisualStyle\.PLAYER_CELL_SIZE\)" -and $boardView -match 'preload\("res://scripts/debug_style\.gd"\)' -and $debugStyle -match "CELL_SIZE\s*:=\s*96"
	},
	@{
		Name = "player renderer shares one direction triangle with installed blocks"
		Pass = $playerBoardView -match "func\s+draw_blocks\(\)[\s\S]*draw_direction_triangle\(" -and $playerBoardView -match "func\s+draw_player_stored_vector\(\)[\s\S]*draw_direction_triangle\(" -and $visualStyle -match "PLAYER_TRI_W_RATIO\s*:=\s*0\.21" -and $visualStyle -match "PLAYER_TRI_H_RATIO\s*:=\s*0\.18"
	},
	@{
		Name = "player facing chevron renders last with fence clearance"
		Pass = $playerBoardView -match "func\s+draw_player_facing\(\)[\s\S]*chevron_points\([\s\S]*palette\[`"floor`"\][\s\S]*chevron_points\(center,\s*forward,\s*length,\s*depth,\s*stroke\)[\s\S]*palette\[`"player`"\]" -and $visualStyle -match "FACING_CHV_CLEARANCE_RATIO\s*:=\s*0\.02"
	},
	@{
		Name = "successful pushes and installs retreat then release the facing chevron"
		Pass = $gameBoard -match "Push succeeded\.[\s\S]*?play_facing_action\(\)[\s\S]*?start_block_displacement\(" -and $gameBoard -match "Install: %s -> block %s; order %s\.[\s\S]*?render_all\(\)\s*[\r\n]+\s*play_facing_action\(\)" -and $gameBoard -match 'has_method\("play_facing_action"\)' -and $playerBoardView -match "func\s+play_facing_action\(\)" -and $playerBoardView -match "FACING_ACTION_RETREAT_SECONDS[\s\S]*FACING_ACTION_HOLD_SECONDS[\s\S]*FACING_ACTION_FORWARD_SECONDS[\s\S]*FACING_ACTION_SETTLE_SECONDS" -and $playerBoardView -match "set_facing_action_offset_ratio[\s\S]*-VisualStyle\.FACING_ACTION_RETREAT_RATIO[\s\S]*set_facing_action_offset_ratio[\s\S]*VisualStyle\.FACING_ACTION_FORWARD_RATIO" -and $playerBoardView -match "FACING_CHV_INSET_RATIO[\s\S]*facing_action_offset_ratio" -and $playerBoardView -notmatch "draw_facing_echo|FACING_ECHO|FACING_FLASH|action_flash|facing_pulse" -and $visualStyle -match "FACING_ACTION_RETREAT_RATIO\s*:=\s*0\.033" -and $visualStyle -match "FACING_ACTION_FORWARD_RATIO\s*:=\s*0\.055" -and $visualStyle -match "FACING_ACTION_RETREAT_SECONDS\s*:=\s*0\.030" -and $visualStyle -match "FACING_ACTION_HOLD_SECONDS\s*:=\s*0\.030" -and $visualStyle -match "FACING_ACTION_FORWARD_SECONDS\s*:=\s*0\.060" -and $visualStyle -match "FACING_ACTION_SETTLE_SECONDS\s*:=\s*0\.030"
	},
	@{
		Name = "successful installs reveal the block vector after an independent delay"
		Pass = $gameBoard -match "play_facing_action\(\)\s*[\r\n]+\s*if\s+start_install_reveal\(int\(block\[`"id`"\]\)\):\s*[\r\n]+\s*return" -and $gameBoard -match "func\s+start_install_reveal\(block_id:\s*int\)\s*->\s*bool:" -and $gameBoard -match 'has_method\("play_install_reveal"\)' -and $playerBoardView -match "func\s+play_install_reveal\(block_id:\s*int,\s*on_finished:\s*Callable\)" -and $playerBoardView -match "INSTALL_VECTOR_DELAY_SECONDS[\s\S]*reveal_installed_vector[\s\S]*FACING_ACTION_SETTLE_SECONDS[\s\S]*finish_displacement" -and $playerBoardView -match 'vector_name\s*!=\s*""\s*and\s*block_id\s*!=\s*install_reveal_block_id' -and $playerBoardView -match "func\s+reveal_installed_vector\(\)[\s\S]*install_reveal_block_id\s*=\s*-1" -and $visualStyle -match "PUSH_DISPLACEMENT_DELAY_SECONDS\s*:=\s*0\.12" -and $visualStyle -match "INSTALL_VECTOR_DELAY_SECONDS\s*:=\s*0\.12"
	},
	@{
		Name = "player facing chevron uses thick inset proportions"
		Pass = $visualStyle -match "FACING_CHV_LEN_RATIO\s*:=\s*0\.44" -and $visualStyle -match "FACING_CHV_DEPTH_RATIO\s*:=\s*0\.20" -and $visualStyle -match "FACING_CHV_STROKE_RATIO\s*:=\s*0\.62" -and $visualStyle -match "FACING_CHV_INSET_RATIO\s*:=\s*0\.025" -and $playerBoardView -match "cell_size\s*/\s*2\.0[\s\S]*cell_size\s*\*\s*VisualStyle\.FACING_CHV_INSET_RATIO"
	},
	@{
		Name = "player mode animates player and block displacement"
		Pass = $gameBoard -match "start_player_displacement\(player_from,\s*target\)" -and $gameBoard -match "start_block_displacement\([\s\S]*pushed_block_id,[\s\S]*block_from,[\s\S]*block_target" -and $gameBoard -match 'has_method\("play_player_displacement"\)' -and $gameBoard -match 'has_method\("play_block_displacement"\)' -and $playerBoardView -match "func\s+play_player_displacement\(" -and $playerBoardView -match "func\s+play_block_displacement\([\s\S]*PUSH_DISPLACEMENT_DELAY_SECONDS[\s\S]*set_displacement_progress" -and $playerBoardView -match "func\s+animated_cell_position\(\)[\s\S]*\.lerp\(" -and $visualStyle -match "PUSH_DISPLACEMENT_DELAY_SECONDS\s*:=\s*0\.\d+" -and $visualStyle -match "DISPLACEMENT_SECONDS\s*:=\s*0\.\d+"
	},
	@{
		Name = "successful triggers fade while displacement runs"
		Pass = ([regex]::Matches($gameBoard, "start_trigger_displacement\(\s*[\r\n]+\s*carrier_id,\s*[\r\n]+\s*vector_name,")).Count -eq 2 -and $gameBoard -match 'has_method\("play_trigger_displacement"\)' -and $playerBoardView -match "func\s+play_trigger_displacement\(" -and $playerBoardView -match "TRIGGER_FLASH_IN_SECONDS[\s\S]*TRIGGER_FLASH_HOLD_SECONDS[\s\S]*set_displacement_progress[\s\S]*parallel\(\)\.tween_method\(\s*[\r\n]+\s*set_trigger_flash_alpha[\s\S]*TRIGGER_FLASH_OUT_SECONDS" -and $playerBoardView -match "func\s+draw_trigger_flash\(\)[\s\S]*var\s+block_index:\s*int\s*=\s*int\([\s\S]*find_block_index_by_id\(trigger_flash_block_id\)[\s\S]*var\s+block_cell:\s*Vector2i\s*=\s*block\[`"cell`"\][\s\S]*draw_direction_triangle\(" -and $playerBoardView -match 'palette\["block_glyph"\]\.lerp\([\s\S]*palette\["trigger_flash"\]' -and $visualStyle -match "TRIGGER_FLASH_OUT_SECONDS\s*:=\s*DISPLACEMENT_SECONDS" -and $visualStyle -match '"trigger_flash": Color\("#dedede"\)' -and $visualStyle -match '"trigger_flash": Color\("#30302f"\)'
	},
	@{
		Name = "new atomic input cancels stale displacement callbacks"
		Pass = $gameBoard -match "func\s+begin_atomic_input\(\)\s*->\s*void:\s*[\r\n]+\s*cancel_board_displacement\(\)" -and $gameBoard -match 'has_method\("cancel_displacement"\)' -and $playerBoardView -match "func\s+cancel_displacement\(\)[\s\S]*displacement_tween\.kill\(\)[\s\S]*clear_displacement_state\(\)" -and $playerBoardView -match "displacement_finished\s*=\s*Callable\(\)"
	},
	@{
		Name = "graphics runtime animation check covers movement trigger and reset"
		Pass = $playerAnimationCheck -match "check_player_displacement" -and $playerAnimationCheck -match "check_push_displacement" -and $playerAnimationCheck -match "check_install_reveal" -and $playerAnimationCheck -match "check_free_trigger_sequence" -and $playerAnimationCheck -match "check_collision_trigger_sequence" -and $playerAnimationCheck -match "check_reset_cancels_animation"
	},
	@{
		Name = "player goals use dashed empty markers and replace the block edge when completed"
		Pass = $visualStyle -match "GOAL_INSET_RATIO\s*:=\s*0\.21" -and $playerBoardView -match "func\s+draw_goals\(\)[\s\S]*is_goal_visually_occupied\(cell\)[\s\S]*continue[\s\S]*GOAL_INSET_RATIO[\s\S]*draw_dashed_shape\(" -and $playerBoardView -match 'palette\["goal_complete"\][\s\S]*if\s+game_board\.goal_cells\.has\(occupied_cell\)[\s\S]*else\s+palette\["block_edge"\]' -and $playerBoardView -notmatch "outline_rect" -and $visualStyle -match '"goal_complete": Color\("#f2f2f2"\)' -and $visualStyle -match '"goal_complete": Color\("#1e1d1c"\)' -and $visualStyle -notmatch "GOAL_DIAMOND_RATIO"
	},
	@{
		Name = "game board dispatches compact UDLRXT commands"
		Pass = $gameBoard -match 'VALID_COMMANDS\s*:=\s*"UDLRXT"' -and $gameBoard -match 'func\s+execute_command\(command:\s*String\)'
	},
	@{
		Name = "normal input routes through execute_command"
		Pass = $mainEntry -match 'execute_command\("U"\)' -and $mainEntry -match 'execute_command\("X"\)' -and $mainEntry -match 'execute_command\("T"\)'
	},
	@{
		Name = "standalone command player scene is wired"
		Pass = $commandPlayerScene -match 'res://scripts/command_player\.gd' -and $commandPlayer -match 'func\s+parse_commands\(source:\s*String\)' -and $commandPlayer -match 'execute_command\(command\)'
	},
	@{
		Name = "main.gd completes levels when every goal contains a block"
		Pass = $main -match "func\s+is_level_solved\(\)" -and $main -match "goal_cells\.is_empty\(\)" -and $main -match "find_block_index_at\(goal_cell\)"
	},
	@{
		Name = "main.gd locks completed levels while keeping reset available"
		Pass = $main -match "var\s+level_completed\s*:=\s*false" -and $main -match 'is_action_pressed\("reset_level"\)[\s\S]*if level_completed:'
	},
	@{
		Name = "main.gd records accepted compact commands"
		Pass = $main -match "var\s+command_history:\s*Array\[String\]" -and $main -match "command_history\.append\(normalized_command\)"
	},
	@{
		Name = "main.gd reports and clears completed command history"
		Pass = $main -match 'Input result \(%s\)' -and $main -match "command_history\.clear\(\)"
	},
	@{
		Name = "main.gd loads the independent level file"
		Pass = $main -match 'INITIAL_LEVEL_PATH\s*:=\s*"res://levels/level_test\.txt"' -and $main -match "FileAccess\.open\(INITIAL_LEVEL_PATH"
	},
	@{
		Name = "level file contains a player start"
		Pass = $level -match "[@+]"
	}
)

$failed = @()
foreach ($check in $checks) {
	if ($check.Pass) {
		Write-Output "PASS: $($check.Name)"
	} else {
		Write-Output "FAIL: $($check.Name)"
		$failed += $check.Name
	}
}

if ($failed.Count -gt 0) {
	Write-Error "$($failed.Count) v1.1 static checks failed."
	exit 1
}

Write-Output "PASS: all v1.1 static checks passed."
