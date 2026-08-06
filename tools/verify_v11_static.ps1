$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $root "scripts/main.gd"
$gameBoardPath = Join-Path $root "scripts/game_board.gd"
$boardViewPath = Join-Path $root "scripts/board_view.gd"
$playerBoardViewPath = Join-Path $root "scripts/player_board_view.gd"
$gameHudPath = Join-Path $root "scripts/game_hud.gd"
$playerInterfacePath = Join-Path $root "scripts/player_interface.gd"
$sceneTransitionPath = Join-Path $root "scripts/scene_transition.gd"
$debugPanelPath = Join-Path $root "scripts/debug_panel.gd"
$visualStylePath = Join-Path $root "scripts/visual_style.gd"
$debugStylePath = Join-Path $root "scripts/debug_style.gd"
$commandPlayerPath = Join-Path $root "scripts/command_player.gd"
$worldMapPath = Join-Path $root "scripts/world_map.gd"
$classicLevelSelectPath = Join-Path $root "scripts/classic_level_select.gd"
$titleScreenPath = Join-Path $root "scripts/title_screen.gd"
$levelThumbnailRendererPath = Join-Path $root "scripts/level_thumbnail_renderer.gd"
$campaignPath = Join-Path $root "scripts/campaign.gd"
$levelCatalogPath = Join-Path $root "scripts/level_catalog.gd"
$classicLevelSelectScenePath = Join-Path $root "scenes/classic_level_select.tscn"
$titleScreenScenePath = Join-Path $root "scenes/title_screen.tscn"
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
$sceneTransition = Get-Content -LiteralPath $sceneTransitionPath -Raw
$debugPanel = Get-Content -LiteralPath $debugPanelPath -Raw
$visualStyle = Get-Content -LiteralPath $visualStylePath -Raw
$debugStyle = Get-Content -LiteralPath $debugStylePath -Raw
$main = "$mainEntry`n$gameBoard`n$boardView`n$playerBoardView`n$gameHud`n$playerInterface`n$debugPanel`n$visualStyle`n$debugStyle"
$commandPlayer = Get-Content -LiteralPath $commandPlayerPath -Raw
$worldMap = Get-Content -LiteralPath $worldMapPath -Raw
$classicLevelSelect = Get-Content -LiteralPath $classicLevelSelectPath -Raw
$titleScreen = Get-Content -LiteralPath $titleScreenPath -Raw
$levelThumbnailRenderer = Get-Content -LiteralPath $levelThumbnailRendererPath -Raw
$campaign = Get-Content -LiteralPath $campaignPath -Raw
$levelCatalog = Get-Content -LiteralPath $levelCatalogPath -Raw
$classicLevelSelectScene = Get-Content -LiteralPath $classicLevelSelectScenePath -Raw
$titleScreenScene = Get-Content -LiteralPath $titleScreenScenePath -Raw
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
		Name = "campaign level 1-1 provides a delayed contextual install hint"
		Pass = $gameBoard -match 'INSTALL_TUTORIAL_LEVEL_ID\s*:=\s*"1-1"' -and $gameBoard -match 'func\s+install_tutorial_target_cell\(\)\s*->\s*Vector2i' -and $playerBoardView -match 'INSTALL_KEY_TEXTURE\s*=\s*preload\([\s\S]*keyboard_x_outline\.svg' -and $playerBoardView -match 'func\s+draw_install_tutorial_hint\(\)[\s\S]*INSTALL_KEY_TEXTURE[\s\S]*TUTORIAL_X_KEY_SIZE[\s\S]*Rect2\(8\.0,\s*8\.0,\s*48\.0,\s*48\.0\)' -and $playerBoardView -notmatch '"Install"' -and $visualStyle -match 'TUTORIAL_X_KEY_SIZE\s*:=\s*Vector2\(40\.0,\s*40\.0\)'
	},
	@{
		Name = "campaign level 1-1 reveals release above the installed block"
		Pass = $gameBoard -match 'func\s+release_tutorial_target_cell\(\)\s*->\s*Vector2i' -and $gameBoard -notmatch 'goal_cells\.has\(release_target\)' -and $playerBoardView -match 'install_reveal_block_id\s*==\s*-1[\s\S]*displacement_subject\s*==\s*DISPLACEMENT_NONE' -and $playerBoardView -match 'RELEASE_KEY_TEXTURE\s*=\s*preload\([\s\S]*keyboard_space_outline\.svg' -and $playerBoardView -match 'func\s+draw_release_tutorial_hint\(\)' -and $playerBoardView -match 'VisualStyle\.TUTORIAL_SPACE_KEY_SIZE' -and $playerBoardView -match 'VisualStyle\.TUTORIAL_SPACE_KEY_GAP' -and $playerBoardView -notmatch '"Release"' -and $visualStyle -match 'TUTORIAL_SPACE_KEY_SIZE\s*:=\s*Vector2\(96\.0,\s*80\.0\)' -and $visualStyle -match 'TUTORIAL_KEY_GAP\s*:=\s*16\.0' -and $visualStyle -match 'TUTORIAL_SPACE_KEY_GAP\s*:=\s*0\.0' -and $playerBoardView -match 'func\s+scaled_tutorial_key_size\(value:\s*Vector2\)'
	},
	@{
		Name = "campaign level 1-1 precomputes static deadlocks for the undo prompt"
		Pass = $gameBoard -match 'static_dead_cells:\s*Array\[Vector2i\]' -and $gameBoard -match 'static_dead_cells\s*=\s*calculate_static_dead_cells\(\)' -and $gameBoard -match 'func\s+tutorial_undo_deadlock_cell\(\)\s*->\s*Vector2i[\s\S]*install_order\.is_empty\(\)[\s\S]*static_dead_cells\.has\(cell\)[\s\S]*player_queue_can_release_block\(cell\)' -and $gameBoard -match 'func\s+player_queue_can_release_block\(cell:\s*Vector2i\)\s*->\s*bool[\s\S]*can_block_move_to\(cell,\s*cell\s*\+\s*direction\)' -and $playerBoardView -match 'UNDO_KEY_TEXTURE\s*=\s*preload\([\s\S]*keyboard_z_outline\.svg' -and $playerBoardView -match 'func\s+draw_undo_tutorial_prompt\(\)[\s\S]*UNDO_KEY_TEXTURE[\s\S]*"UNDO"' -and $playerBoardView -match 'displacement_subject\s*==\s*DISPLACEMENT_NONE'
	},
	@{
		Name = "main.gd has trigger_vector operation"
		Pass = $main -match "func\s+trigger_vector\(\)"
	},
	@{
		Name = "blocked triggers consume the installed vector"
		Pass = ([regex]::Matches($gameBoard, 'consume_blocked_trigger\(')).Count -eq 5 -and $gameBoard -match 'func\s+consume_blocked_trigger\([\s\S]*consume_carrier_vector\(carrier_index,\s*carrier\)[\s\S]*render_all\(\)[\s\S]*end_atomic_input\(\)'
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
		Pass = $project -match 'config/name="DIR"' -and $playerInterface -notmatch 'make_label\("DIR"' -and $editor -match '<title>DIR Level Editor</title>' -and $pyproject -match 'name\s*=\s*"dir-solver"' -and $pyproject -match 'dir-solve\s*=\s*"solver\.cli:main"' -and $solverCli -match 'prog="dir-solve"' -and "$main`n$project`n$editor`n$pyproject`n$solverCli" -notmatch [regex]::Escape($legacyProductName)
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
		Name = "movement actions support arrow keys and WASD"
		Pass = $project -match 'move_up=\{[\s\S]*?keycode":4194320[\s\S]*?keycode":87' -and $project -match 'move_down=\{[\s\S]*?keycode":4194322[\s\S]*?keycode":83' -and $project -match 'move_left=\{[\s\S]*?keycode":4194319[\s\S]*?keycode":65' -and $project -match 'move_right=\{[\s\S]*?keycode":4194321[\s\S]*?keycode":68'
	},
	@{
		Name = "level entry uses one persistent black scene transition"
		Pass = $project -match 'SceneTransition="\*res://scripts/scene_transition\.gd"' -and $sceneTransition -match 'extends\s+CanvasLayer' -and $sceneTransition -match 'layer\s*=\s*1000' -and $sceneTransition -match 'FADE_OUT_SECONDS\s*:=\s*0\.15' -and $sceneTransition -match 'FADE_IN_SECONDS\s*:=\s*0\.15' -and $sceneTransition -match 'tween_property\(overlay,\s*"color:a",\s*1\.0,\s*FADE_OUT_SECONDS\)' -and $sceneTransition -match 'change_scene_to_file\(scene_path\)' -and $sceneTransition -match 'tween_property\(overlay,\s*"color:a",\s*0\.0,\s*FADE_IN_SECONDS\)' -and $classicLevelSelect -match 'SceneTransition\.transition_to\("res://scenes/main\.tscn"\)' -and $worldMap -match 'SceneTransition\.transition_to\("res://scenes/main\.tscn"\)' -and $mainEntry -match 'SceneTransition\.is_active\(\)[\s\S]*clear_held_movement\(\)' -and $mainEntry -match 'func\s+return_to_world_map\(\)[\s\S]*SceneTransition\.transition_to\(Campaign\.level_select_scene_path\)'
	},
	@{
		Name = "level completion pulses goals and replaces controls with continue"
		Pass = $visualStyle -match 'COMPLETION_PULSE_DELAY_SECONDS\s*:=\s*0\.12' -and $visualStyle -match 'COMPLETION_PULSE_SECONDS\s*:=\s*0\.32' -and $visualStyle -match 'COMPLETION_PULSE_EXPAND_RATIO\s*:=\s*0\.08' -and $visualStyle -match 'COMPLETION_BOARD_FADE_SECONDS\s*:=\s*[0-9]+(?:\.[0-9]+)?' -and $visualStyle -match 'COMPLETION_BOARD_DIM_ALPHA\s*:=\s*[0-9]+(?:\.[0-9]+)?' -and $playerBoardView -match 'func\s+play_completion_feedback\(\)[\s\S]*COMPLETION_PULSE_DELAY_SECONDS[\s\S]*begin_completion_pulse[\s\S]*COMPLETION_PULSE_SECONDS[\s\S]*COMPLETION_BOARD_DIM_ALPHA[\s\S]*COMPLETION_BOARD_FADE_SECONDS' -and $playerBoardView -match 'func\s+draw_completion_pulse\([\s\S]*1\.0\s*-\s*progress[\s\S]*block_rect\.grow\(expansion\)' -and $playerBoardView -match 'func\s+reset_completion_feedback\(\)[\s\S]*modulate\s*=\s*Color\([\s\S]*1\.0\)' -and $gameBoard -match 'func\s+finish_level_completion\([\s\S]*play_completion_feedback\(\)' -and $gameBoard -match 'func\s+reset_level\(\)[\s\S]*reset_completion_feedback\(\)' -and $playerInterface -match 'continue_hint\s*=\s*add_icon_key_hint\(' -and $playerInterface -match '"CONTINUE"' -and $playerInterface -match 'if\s+game_board\.level_completed:[\s\S]*continue_hint\.visible\s*=\s*true' -and $playerInterface -match 'Color\.WHITE\s+if\s+game_board\.level_completed' -and $playerAnimationCheck -match 'board should dim after the completion pulse finishes' -and $playerAnimationCheck -match 'undo should restore full board opacity'
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
		Name = "player interface reserves fixed header and status bars around a flexible stage"
		Pass = $playerInterface -match "HEADER_HEIGHT\s*:=\s*68" -and $playerInterface -match "BASE_STATUS_HEIGHT\s*:=\s*88" -and $playerInterface -notmatch "STAGE_MIN_HEIGHT"
	},
	@{
		Name = "player interface centers a locally positioned board"
		Pass = $playerInterface -match "CenterContainer\.new\(\)" -and $playerInterface -match "board_host\.add_child\(board_view\)" -and $playerBoardView -match "return Vector2\(cell\.x \* cell_size, cell\.y \* cell_size\)"
	},
	@{
		Name = "player mode suppresses core status and debug messages"
		Pass = $playerInterface -notmatch 'message_label|MESSAGE_HEIGHT|MESSAGE_WIDTH' -and $playerInterface -match 'func\s+set_message\(_text:\s*String\)\s*->\s*void:\s*\r?\n\s*pass' -and $playerInterface -match 'func\s+show_result\(_text:\s*String\)\s*->\s*void:\s*\r?\n\s*pass'
	},
	@{
		Name = "player header keeps only a larger level name after the level control"
		Pass = $playerInterface -match 'HEADER_HEIGHT\s*:=\s*68' -and $playerInterface -match 'HEADER_LEVEL_NAME_FONT_SIZE\s*:=\s*30' -and $playerInterface -match 'left_group\.add_child\(level_button\)[\s\S]*left_group\.add_child\(level_name\)' -and $playerInterface -notmatch 'left_group\.add_child\(build_goal_group\(\)\)|make_label\("DIR"|level_number|make_status_group\("(?:FACING|SLOT|STEPS|GOALS)"|slot_chip|slot_description|steps_value|facing_labels'
	},
	@{
		Name = "player header exposes one functional level return button"
		Pass = $playerInterface -match 'LEVEL_KEY_TEXTURE\s*=\s*preload\([\s\S]*keyboard_escape_outline\.svg' -and $playerInterface -match 'var\s+level_button\s*:=\s*make_button\([\s\S]*"LEVEL"[\s\S]*LEVEL_KEY_TEXTURE' -and $playerInterface -match 'level_button\.pressed\.connect\(return_to_level_select\)' -and $playerInterface -match 'func\s+return_to_level_select\(\)\s*->\s*void:[\s\S]*game_board\.return_to_world_map\(\)' -and $playerInterface -notmatch 'previous_button|next_button|show_navigation_unavailable'
	},
	@{
		Name = "player header uses SVG key prompts for escape undo and reset"
		Pass = $playerInterface -match 'HEADER_BUTTON_FONT_SIZE\s*:=\s*18' -and $playerInterface -match 'HEADER_KEY_ICON_SIZE\s*:=\s*40' -and $playerInterface -match 'UNDO_KEY_TEXTURE\s*=\s*preload\([\s\S]*keyboard_z_outline\.svg' -and $playerInterface -match 'RESET_KEY_TEXTURE\s*=\s*preload\([\s\S]*keyboard_r_outline\.svg' -and $playerInterface -match 'make_button\([\s\S]*"UNDO"[\s\S]*UNDO_KEY_TEXTURE' -and $playerInterface -match 'make_button\([\s\S]*"RESET"[\s\S]*RESET_KEY_TEXTURE' -and $playerInterface -match 'keycap\.texture\s*=\s*icon' -and $playerInterface -match 'keycap\.stretch_mode\s*=\s*TextureRect\.STRETCH_KEEP_ASPECT_CENTERED' -and $playerInterface -notmatch '\.icon_max_width\s*='
	},
	@{
		Name = "player header controls use borderless text after their keycaps"
		Pass = $playerInterface -match 'func\s+make_button_style\(padding_x:\s*int,\s*padding_y:\s*int\)[\s\S]*style\.bg_color\s*=\s*Color\.TRANSPARENT' -and $playerInterface -match 'make_button_style\(padding_x,\s*padding_y\)' -and $playerInterface -notmatch 'make_button_style\((?:normal_background|hover_background|Color\.TRANSPARENT)'
	},
	@{
		Name = "player header text and key glyphs share one vertical center"
		Pass = $playerInterface -match 'func\s+make_header_label\(text:\s*String,\s*font_size:\s*int,\s*font:\s*Font\)\s*->\s*Label:[\s\S]*custom_minimum_size\.y\s*=\s*HEADER_KEY_ICON_SIZE[\s\S]*vertical_alignment\s*=\s*VERTICAL_ALIGNMENT_CENTER' -and $playerInterface -match 'var\s+level_name\s*:=\s*make_header_label\(' -and $playerInterface -match 'make_header_label\([\s\S]*"GOAL"' -and $playerInterface -match 'goals_value\s*=\s*make_header_label\(' -and $playerInterface -match 'keycap\.custom_minimum_size\s*=\s*Vector2\(HEADER_KEY_ICON_SIZE,\s*HEADER_KEY_ICON_SIZE\)' -and $playerInterface -match 'action\.custom_minimum_size\.y\s*=\s*HEADER_KEY_ICON_SIZE' -and $playerInterface -match 'action\.vertical_alignment\s*=\s*VERTICAL_ALIGNMENT_CENTER' -and $playerInterface -match 'HEADER_ACTION_TEXT_OFFSET_Y\s*:=\s*1' -and $playerInterface -match 'action\.offset_top\s*\+=\s*HEADER_ACTION_TEXT_OFFSET_Y' -and $playerInterface -match 'button\.custom_minimum_size\.y\s*=\s*HEADER_KEY_ICON_SIZE'
	},
	@{
		Name = "goal count sits above the board at its left edge"
		Pass = $playerInterface -match 'HEADER_GOAL_LABEL_FONT_SIZE\s*:=\s*18' -and $playerInterface -match 'HEADER_GOAL_VALUE_FONT_SIZE\s*:=\s*22' -and $playerInterface -match 'func\s+build_goal_group\(\)\s*->\s*HBoxContainer' -and $playerInterface -match 'var\s+board_goals\s*:=\s*build_goal_group\(\)' -and $playerInterface -match 'board_goals\.position\s*=\s*Vector2\([\s\S]*0,[\s\S]*-HEADER_KEY_ICON_SIZE\s*-\s*BOARD_GOAL_GAP[\s\S]*\)' -and $playerInterface -match 'board_view\.add_child\(board_goals\)'
	},
	@{
		Name = "player board cells shrink independently to preserve the bottom controls"
		Pass = $playerInterface -match 'BOARD_CELL_SIZE_MAX\s*:=\s*float\(VisualStyle\.PLAYER_CELL_SIZE\)' -and $playerInterface -match 'func\s+fit_board_to_viewport\(\)\s*->\s*void:' -and $playerInterface -match 'var\s+viewport\s*:=\s*get_viewport\(\)[\s\S]*if\s+viewport\s*==\s*null:[\s\S]*viewport\.get_visible_rect\(\)\.size' -and $playerInterface -match 'viewport_size\.y[\s\S]*-\s*HEADER_HEIGHT[\s\S]*-\s*control_hint_status_height\(\)[\s\S]*-\s*STAGE_TOP_MARGIN[\s\S]*-\s*STAGE_BOTTOM_MARGIN' -and $playerInterface -match 'width_limited_size[\s\S]*height_limited_size[\s\S]*board_view\.set_cell_size' -and $playerInterface -match 'get_viewport\(\)\.size_changed\.connect\(fit_board_to_viewport\)' -and $playerInterface -match 'func\s+refresh\(\)\s*->\s*void:[\s\S]*fit_board_to_viewport\(\)' -and $playerAnimationCheck -match 'viewport_bottom[\s\S]*status\.get_global_rect\(\)\.end\.y\s*<=\s*viewport_bottom'
	},
	@{
		Name = "player interface progressively reveals tutorial controls"
		Pass = $playerInterface -match 'level_id\s*==\s*"1-0"' -and $playerInterface -match 'level_id\s*==\s*"1-1"' -and $playerInterface -match 'install_tutorial_target_cell\(\)\s*!=\s*Vector2i\(-1,\s*-1\)' -and $playerInterface -match 'tutorial_controls_stage\s*=\s*maxi\(tutorial_controls_stage,\s*1\)' -and $playerInterface -match 'release_hint\.visible\s*=\s*tutorial_controls_stage\s*>=\s*2'
	},
	@{
		Name = "player interface uses English move install and release labels"
		Pass = $playerInterface -match 'MOVE_KEYS_TEXTURE\s*=\s*preload\("res://shapes/ic_input_arrow-keys_01\.svg"\)' -and $playerInterface -match 'INSTALL_KEY_TEXTURE\s*=\s*preload\([\s\S]*keyboard_x_outline\.svg' -and $playerInterface -match 'RELEASE_KEY_TEXTURE\s*=\s*preload\([\s\S]*keyboard_space_outline\.svg' -and $playerInterface -match 'add_icon_key_hint\(hints,\s*MOVE_KEYS_TEXTURE,\s*"MOVE"\)' -and $playerInterface -match 'add_icon_key_hint\(hints,\s*INSTALL_KEY_TEXTURE,\s*"INSTALL",\s*0\.5\)' -and $playerInterface -match 'CONTROL_HINT_SPACE_ICON_BASE_SIZE\s*:=\s*Vector2\([0-9]+(?:\.[0-9]+)?,\s*[0-9]+(?:\.[0-9]+)?\)' -and $playerInterface -match 'CONTROL_HINT_SPACE_SOURCE_RECT\s*:=\s*Rect2\(8\.0,\s*18\.0,\s*48\.0,\s*28\.0\)' -and $playerInterface -match 'RELEASE_KEY_TEXTURE,[\s\S]*"RELEASE",[\s\S]*CONTROL_HINT_SPACE_ICON_BASE_SIZE,[\s\S]*CONTROL_HINT_SPACE_SOURCE_RECT' -and $playerInterface -match 'func\s+add_icon_key_hint\([\s\S]*icon_base_size:\s*Vector2\s*=\s*Vector2\.ZERO[\s\S]*AtlasTexture\.new\(\)[\s\S]*STRETCH_SCALE[\s\S]*SIZE_SHRINK_CENTER[\s\S]*text_tone_labels\.append\(action\)' -and $playerInterface -notmatch '"(?:TRIGGER|\u5b89\u88dd|\u89f8\u767c)"'
	},
	@{
		Name = "player control hints use one adjustable automatic scale"
		Pass = $playerInterface -match 'CONTROL_HINT_SCALE\s*:=\s*[0-9]+(?:\.[0-9]+)?' -and $playerInterface -match 'CONTROL_HINT_GROUP_SEPARATION\s*:=\s*44' -and $playerInterface -match 'add_theme_constant_override\("separation",\s*CONTROL_HINT_GROUP_SEPARATION\)' -and $playerInterface -match 'func\s+control_hint_font_size\(base_size:\s*int\)\s*->\s*int' -and $playerInterface -match 'base_size\s*\*\s*CONTROL_HINT_SCALE' -and $playerInterface -match 'func\s+control_hint_icon_size\(\)\s*->\s*float:[\s\S]*CONTROL_HINT_MOVE_ICON_BASE_SIZE\s*\*\s*CONTROL_HINT_SCALE' -and $playerInterface -match 'func\s+control_hint_status_height\(\)\s*->\s*float[\s\S]*control_hint_icon_size\(\)' -and $playerInterface -match 'status\.custom_minimum_size\.y\s*=\s*control_hint_status_height\(\)'
	},
	@{
		Name = "install and release hints dim when their commands are ineffective"
		Pass = $playerInterface -match 'CONTROL_HINT_INACTIVE_ALPHA\s*:=\s*0\.35' -and $playerInterface -match 'install_hint\.modulate\s*=\s*Color\([\s\S]*command_will_change_state\("X"\)[\s\S]*CONTROL_HINT_INACTIVE_ALPHA' -and $playerInterface -match 'release_hint\.modulate\s*=\s*Color\([\s\S]*command_will_change_state\("T"\)[\s\S]*CONTROL_HINT_INACTIVE_ALPHA' -and $playerAnimationCheck -match 'install hint should dim when X cannot change state' -and $playerAnimationCheck -match 'release hint should brighten when a direction is installed'
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
		Pass = $commandPlayer -match 'preload\("res://scripts/debug_panel\.gd"\)' -and $commandPlayer -match "debug_panel\s*=\s*DebugPanel\.new\(\)" -and $debugPanel -match "class_name\s+DirDebugPanel" -and $debugPanel -match 'background\.color\s*=\s*palette\["app_bg"\]'
	},
	@{
		Name = "command player keeps the debug board renderer"
		Pass = $gameBoard -match 'preload\("res://scripts/board_view\.gd"\)' -and $gameBoard -match "func\s+create_board_view\(\)[\s\S]*BoardView\.new\(\)" -and $commandPlayer -notmatch "create_board_view"
	},
	@{
		Name = "debug renderer frees rebuilt nodes synchronously"
		Pass = $boardView -match 'func\s+clear_children\(node:\s*Node\)[\s\S]*child\.free\(\)' -and $boardView -notmatch 'child\.queue_free\(\)'
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
		Pass = $playerBoardView -match "func\s+draw_blocks\(\)[\s\S]*draw_direction_triangle\([\s\S]*palette\[`"direction_fill`"\]" -and $playerBoardView -match "func\s+draw_player_stored_vector\(\)[\s\S]*draw_direction_triangle\([\s\S]*palette\[`"direction_fill`"\]" -and $visualStyle -match "PLAYER_TRI_H_RATIO\s*:=\s*0\.20" -and $visualStyle -match "PLAYER_TRI_W_RATIO\s*:=\s*PLAYER_TRI_H_RATIO\s*\*\s*2\.0" -and $playerBoardView -match 'var\s+width\s*:=\s*height\s*\*\s*2\.0' -and $playerBoardView -match 'func\s+direction_triangle_points\([\s\S]*tip[\s\S]*base_center\s*\+\s*side\s*\*\s*width\s*/\s*2\.0[\s\S]*base_center\s*-\s*side\s*\*\s*width\s*/\s*2\.0'
	},
	@{
		Name = "player facing chevron uses player fill thin contrast edge and fence clearance"
		Pass = $playerBoardView -match "func\s+draw_player_facing\(\)[\s\S]*palette\[`"floor`"\][\s\S]*palette\[`"direction_fill`"\][\s\S]*chevron_points\(center,\s*forward,\s*length,\s*depth,\s*stroke\)[\s\S]*palette\[`"player`"\]" -and $visualStyle -match "FACING_CHV_OUTLINE_RATIO\s*:=\s*0\.010" -and $visualStyle -match "FACING_CHV_CLEARANCE_RATIO\s*:=\s*0\.014" -and $visualStyle -match '"direction_fill": Color\("#141414"\)' -and $visualStyle -match '"direction_fill": Color\("#f4f3f1"\)'
	},
	@{
		Name = "successful pushes and installs retreat then release the facing chevron"
		Pass = $gameBoard -match "Push succeeded\.[\s\S]*?play_facing_action\(\)[\s\S]*?start_block_displacement\(" -and $gameBoard -match "Install: %s -> block %s; order %s\.[\s\S]*?render_all\(\)\s*[\r\n]+\s*play_facing_action\(\)" -and $gameBoard -match 'has_method\("play_facing_action"\)' -and $playerBoardView -match "func\s+play_facing_action\(\)" -and $playerBoardView -match "FACING_ACTION_RETREAT_SECONDS[\s\S]*FACING_ACTION_HOLD_SECONDS[\s\S]*FACING_ACTION_FORWARD_SECONDS[\s\S]*FACING_ACTION_SETTLE_SECONDS" -and $playerBoardView -match "set_facing_action_offset_ratio[\s\S]*-VisualStyle\.FACING_ACTION_RETREAT_RATIO[\s\S]*set_facing_action_offset_ratio[\s\S]*VisualStyle\.FACING_ACTION_FORWARD_RATIO" -and $playerBoardView -match "FACING_CHV_INSET_RATIO[\s\S]*facing_action_offset_ratio" -and $playerBoardView -notmatch "draw_facing_echo|FACING_ECHO|FACING_FLASH|action_flash|facing_pulse" -and $visualStyle -match "FACING_ACTION_RETREAT_RATIO\s*:=\s*0\.066" -and $visualStyle -match "FACING_ACTION_FORWARD_RATIO\s*:=\s*0\.110" -and $visualStyle -match "FACING_ACTION_RETREAT_SECONDS\s*:=\s*0\.030" -and $visualStyle -match "FACING_ACTION_HOLD_SECONDS\s*:=\s*0\.030" -and $visualStyle -match "FACING_ACTION_FORWARD_SECONDS\s*:=\s*0\.060" -and $visualStyle -match "FACING_ACTION_SETTLE_SECONDS\s*:=\s*0\.030"
	},
	@{
		Name = "successful installs reveal the block vector after an independent delay"
		Pass = $gameBoard -match "play_facing_action\(\)\s*[\r\n]+\s*if\s+start_install_reveal\(int\(block\[`"id`"\]\)\):\s*[\r\n]+\s*return" -and $gameBoard -match "func\s+start_install_reveal\(block_id:\s*int\)\s*->\s*bool:" -and $gameBoard -match 'has_method\("play_install_reveal"\)' -and $playerBoardView -match "func\s+play_install_reveal\(block_id:\s*int,\s*on_finished:\s*Callable\)" -and $playerBoardView -match "INSTALL_VECTOR_DELAY_SECONDS[\s\S]*reveal_installed_vector[\s\S]*FACING_ACTION_SETTLE_SECONDS[\s\S]*finish_displacement" -and $playerBoardView -match 'vector_name\s*!=\s*""\s*and\s*block_id\s*!=\s*install_reveal_block_id' -and $playerBoardView -match "func\s+reveal_installed_vector\(\)[\s\S]*install_reveal_block_id\s*=\s*-1" -and $visualStyle -match "PUSH_DISPLACEMENT_DELAY_SECONDS\s*:=\s*0\.12" -and $visualStyle -match "INSTALL_VECTOR_DELAY_SECONDS\s*:=\s*0\.12"
	},
	@{
		Name = "player facing chevron uses slender inset proportions"
		Pass = $visualStyle -match "FACING_CHV_LEN_RATIO\s*:=\s*0\.44" -and $visualStyle -match "FACING_CHV_DEPTH_RATIO\s*:=\s*0\.20" -and $visualStyle -match "FACING_CHV_STROKE_RATIO\s*:=\s*0\.40" -and $visualStyle -match "FACING_CHV_INSET_RATIO\s*:=\s*0\.025" -and $playerBoardView -match "cell_size\s*/\s*2\.0[\s\S]*cell_size\s*\*\s*VisualStyle\.FACING_CHV_INSET_RATIO"
	},
	@{
		Name = "player mode animates player and block displacement"
		Pass = $gameBoard -match "start_player_displacement\(player_from,\s*target\)" -and $gameBoard -match "start_block_displacement\([\s\S]*pushed_block_id,[\s\S]*block_from,[\s\S]*block_target" -and $gameBoard -match 'has_method\("play_player_displacement"\)' -and $gameBoard -match 'has_method\("play_block_displacement"\)' -and $playerBoardView -match "func\s+play_player_displacement\(" -and $playerBoardView -match "func\s+play_block_displacement\([\s\S]*player_queue_reveal_pending\s*=\s*player_queue_changed[\s\S]*PUSH_DISPLACEMENT_DELAY_SECONDS[\s\S]*tween_callback\(reveal_player_queue\)[\s\S]*set_displacement_progress" -and $playerBoardView -match "func\s+draw_player_stored_vector\(\)[\s\S]*player_queue_reveal_pending" -and $playerBoardView -match "func\s+animated_cell_position\(\)[\s\S]*\.lerp\(" -and $visualStyle -match "PUSH_DISPLACEMENT_DELAY_SECONDS\s*:=\s*0\.\d+" -and $visualStyle -match "DISPLACEMENT_SECONDS\s*:=\s*0\.\d+"
	},
	@{
		Name = "trigger vectors fade while their action runs"
		Pass = ([regex]::Matches($gameBoard, "start_trigger_displacement\(\s*[\r\n]+\s*carrier_id,\s*[\r\n]+\s*vector_name,")).Count -eq 3 -and $gameBoard -match 'has_method\("play_trigger_displacement"\)' -and $playerBoardView -match "func\s+play_trigger_displacement\(" -and $playerBoardView -match "TRIGGER_FLASH_IN_SECONDS[\s\S]*TRIGGER_FLASH_HOLD_SECONDS[\s\S]*set_displacement_progress[\s\S]*parallel\(\)\.tween_method\(\s*[\r\n]+\s*set_trigger_flash_alpha[\s\S]*TRIGGER_FLASH_OUT_SECONDS" -and $playerBoardView -match "func\s+draw_trigger_flash\(\)[\s\S]*var\s+block_index:\s*int\s*=\s*int\([\s\S]*find_block_index_by_id\(trigger_flash_block_id\)[\s\S]*var\s+block_cell:\s*Vector2i\s*=\s*block\[`"cell`"\][\s\S]*draw_direction_triangle\(" -and $playerBoardView -match 'palette\["direction_fill"\]\.lerp\([\s\S]*palette\["trigger_flash"\]' -and $visualStyle -match "TRIGGER_FLASH_OUT_SECONDS\s*:=\s*DISPLACEMENT_SECONDS" -and $visualStyle -match '"trigger_flash": Color\("#dedede"\)' -and $visualStyle -match '"trigger_flash": Color\("#30302f"\)'
	},
	@{
		Name = "collision source approaches holds and returns around target movement"
		Pass = $playerBoardView -match "is_collision\s*:=\s*carrier_id\s*!=\s*moving_block_id" -and $playerBoardView -match "TRIGGER_FLASH_HOLD_SECONDS[\s\S]*set_collision_source_offset_ratio[\s\S]*COLLISION_APPROACH_SECONDS[\s\S]*COLLISION_HOLD_SECONDS[\s\S]*set_collision_lead_progress[\s\S]*COLLISION_TARGET_LEAD_SECONDS[\s\S]*set_collision_follow_progress" -and $playerBoardView -match "func\s+set_collision_lead_progress\([\s\S]*COLLISION_TARGET_LEAD_RATIO[\s\S]*func\s+set_collision_follow_progress\([\s\S]*collision_source_offset_ratio[\s\S]*update_collision_flash" -and $playerBoardView -match "block_id\s*==\s*collision_carrier_block_id[\s\S]*collision_source_offset_ratio" -and $playerBoardView -notmatch "draw_collision_contact|collision_contact_alpha" -and $visualStyle -match "COLLISION_COMPRESSION_RATIO\s*:=\s*0\.010" -and $visualStyle -match "COLLISION_CONTACT_OFFSET_RATIO\s*:=\s*\([\s\S]*BLOCK_INSET_RATIO\s*\+\s*COLLISION_COMPRESSION_RATIO" -and $visualStyle -match "COLLISION_TARGET_SECONDS\s*:=\s*0\.13" -and $visualStyle -match "COLLISION_TARGET_LEAD_RATIO\s*:=\s*0\.05" -and $visualStyle -match "COLLISION_TARGET_LEAD_SECONDS\s*:=\s*0\.025" -and $visualStyle -match "COLLISION_TARGET_FOLLOW_SECONDS\s*:=\s*\([\s\S]*COLLISION_TARGET_SECONDS\s*-\s*COLLISION_TARGET_LEAD_SECONDS" -and $visualStyle -match "COLLISION_APPROACH_SECONDS\s*:=\s*\([\s\S]*COLLISION_TARGET_SECONDS\s*\*\s*COLLISION_CONTACT_OFFSET_RATIO" -and $visualStyle -match "COLLISION_HOLD_SECONDS\s*:=\s*0\.050" -and $visualStyle -match "COLLISION_RETURN_SECONDS\s*:=\s*0\.07"
	},
	@{
		Name = "new atomic input cancels stale displacement callbacks"
		Pass = $gameBoard -match "func\s+begin_atomic_input\(\)\s*->\s*void:\s*[\r\n]+\s*cancel_board_displacement\(\)" -and $gameBoard -match 'has_method\("cancel_displacement"\)' -and $playerBoardView -match "func\s+cancel_displacement\(\)[\s\S]*displacement_tween\.kill\(\)[\s\S]*clear_displacement_state\(\)" -and $playerBoardView -match "displacement_finished\s*=\s*Callable\(\)"
	},
	@{
		Name = "graphics runtime animation check covers movement trigger and reset"
		Pass = $playerAnimationCheck -match "check_player_displacement" -and $playerAnimationCheck -match "check_grid_line_toggle" -and $playerAnimationCheck -match "is_goal_visually_occupied" -and $playerAnimationCheck -match "stored_vector_center" -and $playerAnimationCheck -match "check_push_displacement" -and $playerAnimationCheck -match "check_install_reveal" -and $playerAnimationCheck -match "check_free_trigger_sequence" -and $playerAnimationCheck -match "check_blocked_trigger_sequence" -and $playerAnimationCheck -match "check_collision_trigger_sequence" -and $playerAnimationCheck -match "check_reset_cancels_animation"
	},
	@{
		Name = "empty release flashes the player as an input error"
		Pass = $gameBoard -match 'install_order\.is_empty\(\)[\s\S]*Nothing installed to release\.[\s\S]*start_player_error_feedback\(\)' -and $playerBoardView -match 'func\s+play_player_error_flash\(cell:\s*Vector2i\)[\s\S]*ERROR_FLASH_PLAYER[\s\S]*"error_flash"[\s\S]*ERROR_FLASH_MAX_ALPHA[\s\S]*ERROR_FLASH_SECONDS' -and $playerBoardView -match 'draw_player_body\(\)[\s\S]*draw_player_error_flash\(\)[\s\S]*draw_player_stored_vector\(\)' -and $playerBoardView -match 'func\s+draw_player_error_flash\(\)[\s\S]*ERROR_FLASH_PLAYER[\s\S]*palette\[error_flash_color_key\][\s\S]*draw_colored_polygon\([\s\S]*player_body_points' -and $visualStyle -match 'ERROR_FLASH_MAX_ALPHA\s*:=\s*180\.0\s*/\s*255\.0' -and $visualStyle -match '"error_flash":\s*Color\("#ff3232"\)' -and $playerAnimationCheck -match 'check_empty_release_error\(game\)'
	},
	@{
		Name = "blocked releases shake without becoming errors"
		Pass = $playerBoardView -match 'is_blocked_release\s*:=\s*\([\s\S]*carrier_id\s*==\s*moving_block_id[\s\S]*from_cell\s*==\s*to_cell' -and $playerBoardView -match 'set_blocked_release_shake_progress[\s\S]*BLOCKED_RELEASE_SHAKE_SECONDS' -and $playerBoardView -match 'sin\(progress\s*\*\s*TAU\s*\*\s*VisualStyle\.BLOCKED_RELEASE_SHAKE_CYCLES\)' -and $playerBoardView -match 'animated_cell_position\(\)[\s\S]*blocked_release_offset_ratio' -and $visualStyle -match 'BLOCKED_RELEASE_SHAKE_RATIO\s*:=\s*0\.050' -and $playerAnimationCheck -match 'blocked trigger should shake its carrier along the release axis'
	},
	@{
		Name = "loaded blocks reject installs with a fitted red flash"
		Pass = $gameBoard -match 'block\["vector"\]\s*!=\s*""[\s\S]*Block already has a vector\.[\s\S]*start_block_error_feedback\(block\["cell"\]\)' -and $playerBoardView -match 'func\s+play_block_error_flash\(cell:\s*Vector2i\)[\s\S]*ERROR_FLASH_BLOCK' -and $playerBoardView -match 'func\s+draw_block_error_flash\(\)[\s\S]*BLOCK_INSET_RATIO[\s\S]*draw_rect\(' -and $playerAnimationCheck -match 'check_loaded_block_rejects_install\(game\)'
	},
	@{
		Name = "all empty-hand block interactions use a weak neutral hint"
		Pass = $gameBoard -match 'if\s+player_queue\s*==\s*"":\s*\r?\n\s*start_block_hint_feedback\(block\["cell"\]\)' -and $playerBoardView -match 'func\s+play_block_hint_flash\(cell:\s*Vector2i\)[\s\S]*"hint_flash"[\s\S]*HINT_FLASH_MAX_ALPHA[\s\S]*HINT_FLASH_SECONDS' -and $visualStyle -match 'HINT_FLASH_MAX_ALPHA\s*:=\s*0\.20' -and $playerAnimationCheck -match 'empty-hand retrieval rejection should use the neutral hint' -and $playerAnimationCheck -match 'successful empty-hand recovery should use the neutral hint'
	},
	@{
		Name = "same-direction pushes hold the stored vector without flicker"
		Pass = $gameBoard -match 'var\s+player_queue_changed\s*:=\s*player_queue\s*!=\s*direction_name' -and $gameBoard -match 'start_block_displacement\([\s\S]*player_queue_changed' -and $playerBoardView -match 'player_queue_reveal_pending\s*=\s*player_queue_changed' -and $playerBoardView -match 'if\s+player_queue_changed:\s*\r?\n\s*displacement_tween\.tween_callback\(reveal_player_queue\)' -and $playerAnimationCheck -match 'check_same_direction_push_holds_queue'
	},
	@{
		Name = "only the next installed direction carries a fading outline"
		Pass = $playerBoardView -match 'func\s+queued_release_block_id\(\)\s*->\s*int:[\s\S]*install_order\[0\]' -and $playerBoardView -match 'func\s+update_active_vector_pulse\(delta:\s*float\)[\s\S]*ACTIVE_VECTOR_PULSE_PAUSE_SECONDS' -and $playerBoardView -match 'func\s+draw_active_vector_outline\(center:\s*Vector2,\s*direction_name:\s*String\)[\s\S]*direction_triangle_points[\s\S]*sin\(progress\s*\*\s*PI\)[\s\S]*draw_polyline\(' -and $visualStyle -match 'ACTIVE_VECTOR_PULSE_SECONDS\s*:=\s*0\.60' -and $visualStyle -match 'ACTIVE_VECTOR_OUTLINE_ALPHA\s*:=\s*0\.55' -and $visualStyle -match '"active_vector_outline":\s*Color' -and $playerAnimationCheck -match 'check_active_vector_pulse\(game\)'
	},
	@{
		Name = "player goals use dashed empty markers and replace the block edge when completed"
		Pass = $visualStyle -match "GOAL_INSET_RATIO\s*:=\s*0\.21" -and $playerBoardView -match "func\s+draw_goals\(\)[\s\S]*is_goal_visually_occupied\(cell\)[\s\S]*continue[\s\S]*GOAL_INSET_RATIO[\s\S]*draw_dashed_shape\(" -and $playerBoardView -match 'var\s+on_goal:\s*bool\s*=\s*game_board\.goal_cells\.has\(occupied_cell\)[\s\S]*palette\["goal_complete"\][\s\S]*if\s+on_goal[\s\S]*else\s+palette\["block_edge"\]' -and $playerBoardView -notmatch "outline_rect" -and $visualStyle -match '"goal_complete": Color\("#f2f2f2"\)' -and $visualStyle -match '"goal_complete": Color\("#1e1d1c"\)' -and $visualStyle -notmatch "GOAL_DIAMOND_RATIO"
	},
	@{
		Name = "game board dispatches compact UDLRXT commands"
		Pass = $gameBoard -match 'VALID_COMMANDS\s*:=\s*"UDLRXT"' -and $gameBoard -match 'func\s+execute_command\(command:\s*String\)'
	},
	@{
		Name = "ineffective commands are rejected before history and undo"
		Pass = $gameBoard -match 'if\s+not\s+command_will_change_state\(normalized_command\):[\s\S]*show_ineffective_command_feedback\(normalized_command\)[\s\S]*return\s+false[\s\S]*undo_stack\.append\(capture_board_snapshot\(\)\)[\s\S]*command_history\.append\(normalized_command\)' -and $gameBoard -match 'func\s+command_will_change_state\(command:\s*String\)\s*->\s*bool' -and $gameBoard -notmatch 'gameplay_state_changed_since'
	},
	@{
		Name = "normal input routes through execute_command"
		Pass = $mainEntry -match 'execute_command\(move_command\)' -and $mainEntry -match 'execute_command\("X"\)' -and $mainEntry -match 'execute_command\("T"\)'
	},
	@{
		Name = "world map player position remains anchored during viewport resize"
		Pass = $worldMap -match 'var\s+player_draw_cell\s*:=\s*Vector2\.ZERO' -and $worldMap -match 'func\s+player_draw_center\(\)\s*->\s*Vector2:[\s\S]*map_origin\(\)\s*\+\s*\(player_draw_cell\s*\+\s*Vector2\.ONE\s*\*\s*0\.5\)\s*\*\s*CELL_SIZE' -and $worldMap -match 'tween_method\(set_player_draw_cell' -and $worldMap -notmatch 'player_draw_position'
	},
	@{
		Name = "classic level selector pages campaign areas in a six-by-two grid"
		Pass = $classicLevelSelect -match 'GRID_COLUMNS\s*:=\s*6' -and $classicLevelSelect -match 'func\s+grid_rows\(\)\s*->\s*int:\s*\r?\n\s*return\s+2' -and $classicLevelSelect -match 'area_entries\.append\(page_entries\)' -and $classicLevelSelect -match 'target_index\s*\+=\s*GRID_COLUMNS'
	},
	@{
		Name = "classic level selector preserves area exit gates and F3 unlock"
		Pass = $classicLevelSelect -match 'previous_area\["exit_requirement"\]' -and $classicLevelSelect -match 'Campaign\.all_levels_unlocked' -and $classicLevelSelect -match 'key_event\.keycode\s*==\s*KEY_F3'
	},
	@{
		Name = "campaign levels use one named cell-edge catalog"
		Pass = $campaign -match 'preload\("res://scripts/level_catalog\.gd"\)' -and $campaign -match 'const\s+AREAS\s*:=\s*LevelCatalogData\.AREAS' -and $campaign -notmatch 'collection_path|load_collection_sections' -and ([regex]::Matches($levelCatalog, '"id":\s*"')).Count -eq 35 -and ([regex]::Matches($levelCatalog, '"name":\s*"')).Count -eq 35 -and ([regex]::Matches($levelCatalog, '"source":\s*"!cell-edge-v1')).Count -eq 35
	},
	@{
		Name = "campaign level names reach the player and selector UI"
		Pass = $campaign -match 'func\s+active_level_name\(\)\s*->\s*String' -and $campaign -match 'func\s+level_name_for\(level_id:\s*String\)\s*->\s*String' -and $playerInterface -match 'Campaign\.active_level_name\(\)' -and $classicLevelSelect -match 'String\(entry\["name"\]\)\.to_upper\(\)'
	},
	@{
		Name = "classic level selector F4 records selected level completion"
		Pass = $classicLevelSelect -match 'func\s+complete_selected_level\(\)[\s\S]*Campaign\.complete_level\(String\(entry\["id"\]\)\)[\s\S]*advance_after_completion\(\)' -and $classicLevelSelect -match 'key_event\.keycode\s*==\s*KEY_F4'
	},
	@{
		Name = "player grid lines expose a visual toggle"
		Pass = $visualStyle -match 'SHOW_GRID_LINES\s*:=\s*(?:true|false)' -and $playerBoardView -match 'var\s+grid_lines_visible\s*:=\s*VisualStyle\.SHOW_GRID_LINES' -and $playerBoardView -match 'func\s+set_grid_lines_visible\(lines_visible:\s*bool\)' -and $playerBoardView -match 'if\s+grid_lines_visible:\s*\r?\n\s*draw_rect\(cell_rect,\s*grid_color' -and $playerBoardView -match 'if\s+grid_lines_visible:\s*\r?\n\s*draw_rect\(wall_rect,\s*wall_edge'
	},
	@{
		Name = "GDScript warning-prone names and integer division stay explicit"
		Pass = $gameBoard -notmatch 'const\s+AsciiMapParser\s*=' -and $playerBoardView -notmatch 'func\s+set_grid_lines_visible\(visible:' -and $playerBoardView -notmatch 'start_displacement_tween\([^)]*\bease:' -and $classicLevelSelect -notmatch '\b(?:selected_index|index)\s*/\s*GRID_COLUMNS'
	},
	@{
		Name = "moving blocks reveal goals continuously beneath displacement"
		Pass = $playerBoardView -match 'func\s+is_goal_visually_occupied\(goal_cell:\s*Vector2i\)[\s\S]*displacement_subject\s*==\s*DISPLACEMENT_BLOCK[\s\S]*block_id\s*==\s*displacement_block_id[\s\S]*continue'
	},
	@{
		Name = "stored direction glyphs offset toward their direction"
		Pass = $visualStyle -match 'STORED_VECTOR_OFFSET_RATIO\s*:=\s*PLAYER_TRI_H_RATIO\s*/\s*2\.0' -and ([regex]::Matches($playerBoardView, 'stored_vector_center\(')).Count -ge 4 -and $playerBoardView -match 'direction_vector\(direction_name\)[\s\S]*VisualStyle\.STORED_VECTOR_OFFSET_RATIO'
	},
	@{
		Name = "player F4 quick completion uses the normal completion infrastructure"
		Pass = $mainEntry -match 'is_quick_complete_key\(event\)[\s\S]*complete_level_for_testing\(\)' -and $mainEntry -match 'key_event\.keycode\s*==\s*KEY_F4' -and $gameBoard -match 'func\s+complete_level_for_testing\(\)[\s\S]*begin_atomic_input\(\)[\s\S]*finish_level_completion\(' -and $gameBoard -match 'func\s+finish_level_completion\(completion_log:\s*String\)[\s\S]*Campaign\.complete_active_level\(\)' -and $gameBoard -notmatch 'command_history\.append\("F4"\)'
	},
	@{
		Name = "classic selector advances exactly once after real completion"
		Pass = $mainEntry -match 'Campaign\.level_select_scene_path' -and $classicLevelSelect -match 'Campaign\.consume_completed_return\(\)[\s\S]*advance_after_completion\(\)'
	},
	@{
		Name = "classic level selector scene and return routing are wired"
		Pass = $classicLevelSelectScene -match 'res://scripts/classic_level_select\.gd' -and $mainEntry -match 'SceneTransition\.transition_to\(Campaign\.level_select_scene_path\)' -and $worldMap -match 'Campaign\.WORLD_MAP_SCENE_PATH'
	},
	@{
		Name = "title screen presents the directional main menu"
		Pass = $project -match 'run/main_scene="res://scenes/title_screen\.tscn"' -and $titleScreenScene -match 'res://scripts/title_screen\.gd' -and $campaign -match 'TITLE_SCREEN_SCENE_PATH\s*:=\s*"res://scenes/title_screen\.tscn"' -and $titleScreen -match 'class_name\s+DirTitleScreen' -and $titleScreen -match 'MENU_CELL_SIZE\s*:=\s*288\.0' -and $titleScreen -match 'MENU_CENTER_Y_RATIO\s*:=\s*0\.61' -and $titleScreen -match '"START"[\s\S]*Vector2i\.UP' -and $titleScreen -match '"INFO"[\s\S]*Vector2i\.LEFT' -and $titleScreen -match '"CONFIG"[\s\S]*Vector2i\.RIGHT' -and $titleScreen -match '"EXTRA"[\s\S]*Vector2i\.DOWN' -and $titleScreen -match 'stored_direction\s*:=\s*Vector2i\.ZERO' -and $titleScreen -match 'func\s+activate_selection\(\)[\s\S]*play_config_action\(confirm_selection_after_action\)[\s\S]*func\s+confirm_selection_after_action\(\)[\s\S]*stored_direction\s*=\s*selected_direction' -and $titleScreen -match 'if\s+stored_direction\s*==\s*Vector2i\.ZERO:[\s\S]*return' -and $titleScreen -match 'VisualStyle\.PLAYER_BODY_RATIO' -and $titleScreen -match 'VisualStyle\.PLAYER_TRI_H_RATIO' -and $titleScreen -match 'VisualStyle\.STORED_VECTOR_OFFSET_RATIO' -and $titleScreen -match 'VisualStyle\.FACING_CHV_LEN_RATIO' -and $titleScreen -match 'func\s+chevron_points\(' -and $titleScreen -match 'OPTION_BOX_SIZE[\s\S]*draw_rect\(option_rect,\s*frame_color,\s*false,\s*frame_width\)' -and $titleScreen -match 'CONFIRM_HOLD_SECONDS[\s\S]*create_timer\(CONFIRM_HOLD_SECONDS\)' -and $titleScreen -match 'palette\["direction_fill"\]' -and $titleScreen -match 'SceneTransition\.transition_to\(Campaign\.CLASSIC_LEVEL_SELECT_SCENE_PATH\)' -and $classicLevelSelect -match 'is_cancel_key\(event\)[\s\S]*Campaign\.TITLE_SCREEN_SCENE_PATH'
	},
	@{
		Name = "title info opens as the left branch"
		Pass = $titleScreen -match 'selected_direction\s*==\s*Vector2i\.LEFT[\s\S]*menu_mode\s*=\s*MenuMode\.INFO' -and $titleScreen -match 'func\s+draw_info_menu\(' -and $titleScreen -match 'Vector2\.LEFT\s*\*\s*INFO_PANEL_OFFSET_X' -and $titleScreen -match 'A DIRECTIONAL BLOCK PUZZLE' -and $titleScreen -match 'BUILT WITH GODOT ENGINE' -and $titleScreen -match 'UI ASSETS BY KENNEY' -and $titleScreen -match 'draw_config_option\("BACK"' -and $titleScreen -match 'handle_info_input[\s\S]*move_right[\s\S]*play_config_action\(leave_info\)'
	},
	@{
		Name = "title config orders screen grid audio and back"
		Pass = $titleScreen -match '"SCREEN\s+%s"[\s\S]*"GRID\s+%s"[\s\S]*"AUDIO"[\s\S]*"BACK"' -and $titleScreen -match 'CONFIG_PANEL_OFFSET_X\s*:=\s*370\.0' -and $titleScreen -match 'draw_player_mark\(menu_center\)[\s\S]*menu_center\.x\s*\+\s*CONFIG_PANEL_OFFSET_X' -and $titleScreen -match 'func\s+draw_audio_option\(' -and $titleScreen -match 'AUDIO_SLIDER_SIZE\.x\s*\*\s*fill_ratio' -and $titleScreen -match 'func\s+play_config_action\(' -and $titleScreen -match '"config_action_offset"[\s\S]*-CONFIG_ACTION_RETREAT[\s\S]*CONFIG_ACTION_HOLD_SECONDS[\s\S]*CONFIG_ACTION_EXTEND[\s\S]*CONFIG_ACTION_RETURN_SECONDS' -and $titleScreen -match 'is_cancel_key\(event\)[\s\S]*MenuMode\.CONFIG:[\s\S]*play_config_action\(leave_config\)[\s\S]*MenuMode\.INFO:[\s\S]*play_config_action\(leave_info\)' -and $titleScreen -match 'play_config_action\(leave_config\)' -and $titleScreen -match 'toggle_fullscreen\(\)' -and $titleScreen -match 'Campaign\.grid_lines_visible\s*=\s*not Campaign\.grid_lines_visible' -and $titleScreen -match 'Campaign\.set_audio_volume\(' -and $titleScreen -match 'func\s+leave_config\(' -and $campaign -match 'var\s+grid_lines_visible\s*:=\s*false' -and $campaign -match 'func\s+set_audio_volume\(' -and $mainEntry -match 'set_grid_lines_visible\(Campaign\.grid_lines_visible\)'
	},
	@{
		Name = "classic selector preserves single-level launch mode"
		Pass = $project -match 'launch_mode="(?:campaign|single_level)"' -and $project -match 'single_level:\s*res://levels/level_test\.txt' -and $titleScreen -match 'Campaign\.is_single_level_mode\(\)[\s\S]*call_deferred\("open_single_level_test"\)' -and $titleScreen -match 'func\s+open_single_level_test\(\)[\s\S]*SceneTransition\.transition_to\("res://scenes/main\.tscn"\)'
	},
	@{
		Name = "classic selector uses restrained white teal and dim state colors"
		Pass = $classicLevelSelect -match 'COMPLETED_COLOR\s*:=\s*Color\("#49c9a5"\)' -and $classicLevelSelect -match 'LOCKED_ALPHA\s*:=\s*0\.28' -and $classicLevelSelect -match 'border_color\s*=\s*palette\["label"\]'
	},
	@{
		Name = "classic selector keeps large responsive level tiles"
		Pass = $classicLevelSelect -match 'MAX_SLOT_SIZE\s*:=\s*216\.0' -and $classicLevelSelect -match 'SIDE_MARGIN_RATIO\s*:=\s*0\.05' -and $classicLevelSelect -match 'func\s+slot_size_for\(viewport_size:\s*Vector2\)\s*->\s*float' -and $classicLevelSelect -match 'func\s+side_margin_for\(viewport_width:\s*float\)\s*->\s*float'
	},
	@{
		Name = "classic selector renders cached text-free board thumbnails"
		Pass = $classicLevelSelect -match 'AsciiMapData\.parse\(String\(level\["source"\]\)\)' -and $classicLevelSelect -match 'level\["thumbnail_data"\]\s*=\s*thumbnail_data' -and $classicLevelSelect -match 'ThumbnailRenderer\.draw\(' -and $classicLevelSelect -notmatch 'draw_text_centered\(rect,\s*level_id' -and $levelThumbnailRenderer -match 'CONTENT_RATIO\s*:=\s*0\.80' -and $levelThumbnailRenderer -match 'var\s+first_row:\s*Array\s*=\s*terrain\[0\]' -and $levelThumbnailRenderer -match 'var\s+width:\s*int\s*=\s*first_row\.size\(\)' -and $levelThumbnailRenderer -match 'func\s+draw_terrain\(' -and $levelThumbnailRenderer -match 'func\s+draw_goals\(' -and $levelThumbnailRenderer -match 'func\s+draw_blocks\(' -and $levelThumbnailRenderer -notmatch 'func\s+draw_player\(' -and $levelThumbnailRenderer -match 'func\s+draw_fences\('
	},
	@{
		Name = "completed thumbnails project blocks onto goals without free blocks"
		Pass = $classicLevelSelect -match 'ThumbnailRenderer\.draw\([\s\S]*completed\s*\r?\n\s*\)' -and $levelThumbnailRenderer -match 'func\s+block_cells_for\(level_data:\s*Dictionary,\s*completed:\s*bool\)\s*->\s*Array\[Vector2i\]' -and $levelThumbnailRenderer -match 'if\s+completed:[\s\S]*level_data\["goal_cells"\]' -and $levelThumbnailRenderer -match 'func\s+draw_completed_outlines\('
	},
	@{
		Name = "classic selector floats only the selected level name"
		Pass = $classicLevelSelect -match 'LEVEL_NAME_GAP\s*:=\s*20\.0' -and $classicLevelSelect -match 'LEVEL_NAME_FONT_SIZE\s*:=\s*24' -and $classicLevelSelect -match 'func\s+selected_level_name\(\)\s*->\s*String[\s\S]*return\s+String\(entry\["name"\]\)\.to_upper\(\)' -and $classicLevelSelect -match 'func\s+selected_level_name_rect_for\(index:\s*int,\s*viewport_size:\s*Vector2\)\s*->\s*Rect2' -and $classicLevelSelect -match 'if\s+row\s*==\s*0[\s\S]*selected_rect\.end\.y\s*\+\s*LEVEL_NAME_GAP' -and $classicLevelSelect -match 'func\s+draw_selected_level_name\(\)[\s\S]*LEVEL_NAME_FONT_SIZE' -and $classicLevelSelect -notmatch 'status_message|refresh_status|selected_level_label|%s\s+COMPLETE|%s\s+AVAILABLE'
	},
	@{
		Name = "classic selector limits glow to completed unselected tiles"
		Pass = $classicLevelSelect -match 'COMPLETED_GLOW_ALPHA\s*:=\s*0\.07' -and $classicLevelSelect -match 'if\s+completed\s+and\s+not\s+selected:\s*\r?\n\s*draw_soft_outline_glow' -and $classicLevelSelect -notmatch 'SELECTED_GLOW_ALPHA'
	},
	@{
		Name = "classic selector uses a thick selection frame without branch dots"
		Pass = $classicLevelSelect -match 'SELECT_FRAME_GROW\s*:=\s*4\.0' -and $classicLevelSelect -match 'SELECT_FRAME_WIDTH\s*:=\s*6\.0' -and $classicLevelSelect -match 'rect\.grow\(SELECT_FRAME_GROW\)' -and $classicLevelSelect -match 'palette\["player"\],[\s\r\n]*false,[\s\r\n]*SELECT_FRAME_WIDTH' -and $classicLevelSelect -notmatch 'SELECT_BREATH|selection_breath|SELECTED_GLOW_ALPHA|marker_size'
	},
	@{
		Name = "player movement accepts held repeats without repeating X or T"
		Pass = $mainEntry -match 'HELD_MOVE_INITIAL_DELAY_SECONDS\s*:=\s*0\.30' -and $mainEntry -match 'HELD_MOVE_REPEAT_SECONDS\s*:=\s*0\.20' -and $mainEntry -match 'func\s+_process\(delta:\s*float\)[\s\S]*held_move_time_remaining\s*-=' -and $mainEntry -match 'var\s+move_command:\s*String\s*=\s*String\(held_move_commands\.back\(\)\)' -and $mainEntry -match 'input_locked\s+or\s+level_completed[\s\S]*execute_command\(move_command\)[\s\S]*held_move_time_remaining\s*=\s*HELD_MOVE_REPEAT_SECONDS' -and $mainEntry -match 'event\s+is\s+InputEventKey\s+and\s+event\.echo[\s\S]*return' -and $mainEntry -match 'func\s+update_held_move\([\s\S]*var\s+was_current:\s*bool\s*=' -and $mainEntry -match 'String\(held_move_commands\.back\(\)\)\s*==\s*move_command' -and $mainEntry -match 'is_action_pressed\("install_vector"\)' -and $mainEntry -match 'is_action_pressed\("trigger_vector"\)' -and $mainEntry -notmatch 'is_action_pressed\("(?:install_vector|trigger_vector)",\s*true\)'
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
