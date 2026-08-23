$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $root "scripts/main.gd"
$gameBoardPath = Join-Path $root "scripts/game_board.gd"
$audioFeedbackPath = Join-Path $root "scripts/audio_feedback.gd"
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
$initialFacingCheckPath = Join-Path $root "tools/verify_initial_facing.gd"
$campaignFlowCheckPath = Join-Path $root "tools/verify_campaign_flow.gd"
$classicLevelSelectCheckPath = Join-Path $root "tools/verify_classic_level_select.gd"
$pyprojectPath = Join-Path $root "pyproject.toml"
$solverCliPath = Join-Path $root "solver/cli.py"
$extraBoardPath = Join-Path $root "scripts/extra_mode/Board.gd"
$extraSimBoardPath = Join-Path $root "scripts/extra_mode/SimBoard.gd"
$extraMainPath = Join-Path $root "scripts/extra_mode/Main.gd"
$extraPlayerPath = Join-Path $root "scripts/extra_mode/Player.gd"
$extraCellPath = Join-Path $root "scripts/extra_mode/Cell.gd"
$extraHudPath = Join-Path $root "scripts/extra_mode/HUD.gd"
$extraHeatMeterPath = Join-Path $root "scripts/extra_mode/HeatMeter.gd"
$extraEnergySlotPath = Join-Path $root "scripts/extra_mode/EnergySlot.gd"
$extraSlashEffectPath = Join-Path $root "scripts/extra_mode/PLNSlashEffect.gd"
$extraComboBotPath = Join-Path $root "scripts/extra_mode/ComboBot.gd"
$extraComboBotMctsPath = Join-Path $root "scripts/extra_mode/ComboBotMCTS.gd"
$extraComboBotTunedPath = Join-Path $root "scripts/extra_mode/ComboBotTuned.gd"
$extraCharacterDataPath = Join-Path $root "scripts/extra_mode/CharacterData.gd"
$extraScoreManagerPath = Join-Path $root "scripts/extra_mode/ScoreManager.gd"
$extraCmaPath = Join-Path $root "tools/extra_cma.py"
$extraInventoryPath = Join-Path $root "scripts/extra_mode/Inventory.gd"
$extraSpawnWarningSoundPath = Join-Path $root "assets/audio/sfx/extra_spawn/question_004.ogg"
$errorSound005Path = Join-Path $root "assets/audio/sfx/error/error_005.ogg"
$hintSoundPath = Join-Path $root "assets/audio/sfx/hint/bong_001.ogg"
$triggerActivationSoundPath = Join-Path $root "assets/audio/sfx/release/cloth2.ogg"
$confirmSoundPath = Join-Path $root "assets/audio/sfx/confirm/switch34.ogg"
$turnSoundPath = Join-Path $root "assets/audio/sfx/turn/click2.ogg"
$completionSoundPath = Join-Path $root "assets/audio/sfx/complete/confirmation_003.ogg"
$blockPushSoundPath = Join-Path $root "assets/audio/sfx/push/handleSmallLeather2.ogg"
$releaseSoundPaths = 0..4 | ForEach-Object {
	Join-Path $root ("assets/audio/sfx/release/impactPlank_medium_{0:D3}.ogg" -f $_)
}
$collisionImpactSoundPaths = 0..4 | ForEach-Object {
	Join-Path $root ("assets/audio/sfx/collision/impactWood_light_{0:D3}.ogg" -f $_)
}
$moveSoundPaths = 0..4 | ForEach-Object {
	Join-Path $root ("assets/audio/sfx/move/footstep_concrete_{0:D3}.ogg" -f $_)
}

$mainEntry = Get-Content -LiteralPath $mainPath -Raw
$gameBoard = Get-Content -LiteralPath $gameBoardPath -Raw
$audioFeedback = Get-Content -LiteralPath $audioFeedbackPath -Raw
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
$campaignFlowCheck = Get-Content -LiteralPath $campaignFlowCheckPath -Raw
$classicLevelSelectCheck = Get-Content -LiteralPath $classicLevelSelectCheckPath -Raw
$initialFacingCheck = Get-Content -LiteralPath $initialFacingCheckPath -Raw
$pyproject = Get-Content -LiteralPath $pyprojectPath -Raw
$solverCli = Get-Content -LiteralPath $solverCliPath -Raw
$extraBoard = Get-Content -LiteralPath $extraBoardPath -Raw
$extraSimBoard = Get-Content -LiteralPath $extraSimBoardPath -Raw
$extraMain = Get-Content -LiteralPath $extraMainPath -Raw
$extraPlayer = Get-Content -LiteralPath $extraPlayerPath -Raw
$extraCell = Get-Content -LiteralPath $extraCellPath -Raw
$extraHud = Get-Content -LiteralPath $extraHudPath -Raw
$extraHeatMeter = Get-Content -LiteralPath $extraHeatMeterPath -Raw
$extraEnergySlot = Get-Content -LiteralPath $extraEnergySlotPath -Raw
$extraSlashEffect = Get-Content -LiteralPath $extraSlashEffectPath -Raw
$extraComboBot = Get-Content -LiteralPath $extraComboBotPath -Raw
$extraComboBotMcts = Get-Content -LiteralPath $extraComboBotMctsPath -Raw
$extraComboBotTuned = Get-Content -LiteralPath $extraComboBotTunedPath -Raw
$extraCharacterData = Get-Content -LiteralPath $extraCharacterDataPath -Raw
$extraScoreManager = Get-Content -LiteralPath $extraScoreManagerPath -Raw
$extraCma = Get-Content -LiteralPath $extraCmaPath -Raw
$extraInventory = Get-Content -LiteralPath $extraInventoryPath -Raw
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
		Name = "levels initialize player facing toward the nearest block"
		Pass = $gameBoard -match 'func\s+face_nearest_initial_block\(' -and ([regex]::Matches($gameBoard, 'face_nearest_initial_block\(\)').Count -ge 3) -and $gameBoard -match 'func\s+manhattan_distance\(' -and $initialFacingCheck -match 'PASS: initial facing follows the nearest block'
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
		Pass = $gameBoard -match 'func\s+release_tutorial_target_cell\(\)\s*->\s*Vector2i' -and $gameBoard -notmatch 'goal_cells\.has\(release_target\)' -and $playerBoardView -match 'install_reveal_block_id\s*==\s*-1[\s\S]*displacement_subject\s*==\s*DISPLACEMENT_NONE' -and $playerBoardView -match 'RELEASE_KEY_TEXTURE\s*=\s*preload\([\s\S]*keyboard_space_outline\.svg' -and $playerBoardView -match 'func\s+draw_release_tutorial_hint\(\)' -and $playerBoardView -match 'VisualStyle\.TUTORIAL_SPACE_KEY_SIZE' -and $playerBoardView -match 'VisualStyle\.TUTORIAL_SPACE_KEY_GAP' -and $playerBoardView -notmatch '"Release"' -and $visualStyle -match 'SPACE_KEY_ASPECT\s*:=\s*[0-9]+(?:\.[0-9]+)?' -and $visualStyle -match 'TUTORIAL_SPACE_KEY_HEIGHT\s*:=\s*[0-9]+(?:\.[0-9]+)?' -and $visualStyle -match 'TUTORIAL_SPACE_KEY_SIZE\s*:=\s*Vector2\(\s*[\r\n]*\s*TUTORIAL_SPACE_KEY_HEIGHT\s*\*\s*SPACE_KEY_ASPECT' -and $visualStyle -match 'SPACE_KEY_SOURCE_RECT\s*:=\s*Rect2\(' -and $playerBoardView -match 'VisualStyle\.SPACE_KEY_SOURCE_RECT' -and $visualStyle -match 'TUTORIAL_KEY_GAP\s*:=\s*16\.0' -and $visualStyle -match 'TUTORIAL_SPACE_KEY_GAP\s*:=\s*8\.0' -and $playerBoardView -match 'func\s+scaled_tutorial_key_size\(value:\s*Vector2\)'
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
		Name = "command player waits for animations without skipping commands"
		Pass = $commandPlayer -match 'func\s+execute_next_command\(\)[\s\S]*?if\s+input_locked:[\s\S]*?return[\s\S]*?if\s+not\s+execute_command\(command\):[\s\S]*?return[\s\S]*?playback_index\s*\+=\s*1'
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
		Pass = $main -match "var\s+facing_changed\s*:=\s*facing_direction\s*!=\s*direction" -and $main -match "block_index\s*!=\s*-1\s+and\s+facing_changed" -and $main -match "faced block.*without pushing"
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
		Pass = $playerInterface -match 'MOVE_KEYS_TEXTURE\s*=\s*preload\("res://shapes/ic_input_arrow-keys_01\.svg"\)' -and $playerInterface -match 'INSTALL_KEY_TEXTURE\s*=\s*preload\([\s\S]*keyboard_x_outline\.svg' -and $playerInterface -match 'RELEASE_KEY_TEXTURE\s*=\s*preload\([\s\S]*keyboard_space_outline\.svg' -and $playerInterface -match 'add_icon_key_hint\(hints,\s*MOVE_KEYS_TEXTURE,\s*"MOVE"\)' -and $playerInterface -match 'add_icon_key_hint\(hints,\s*INSTALL_KEY_TEXTURE,\s*"INSTALL",\s*0\.5\)' -and $playerInterface -match 'CONTROL_HINT_SPACE_ICON_BASE_SIZE\s*:=\s*Vector2\(' -and $playerInterface -match 'CONTROL_HINT_SPACE_SOURCE_RECT\s*:=\s*VisualStyle\.SPACE_KEY_SOURCE_RECT' -and $playerInterface -match 'CONTROL_HINT_SPACE_ICON_HEIGHT\s*\*\s*VisualStyle\.SPACE_KEY_ASPECT' -and $playerInterface -match 'RELEASE_KEY_TEXTURE,[\s\S]*"RELEASE",[\s\S]*CONTROL_HINT_SPACE_ICON_BASE_SIZE,[\s\S]*CONTROL_HINT_SPACE_SOURCE_RECT' -and $playerInterface -match 'func\s+add_icon_key_hint\([\s\S]*icon_base_size:\s*Vector2\s*=\s*Vector2\.ZERO[\s\S]*AtlasTexture\.new\(\)[\s\S]*STRETCH_SCALE[\s\S]*SIZE_SHRINK_CENTER[\s\S]*text_tone_labels\.append\(action\)' -and $playerInterface -notmatch '"(?:TRIGGER|\u5b89\u88dd|\u89f8\u767c)"'
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
		Name = "player facing chevron uses player fill thin contrast edge"
		Pass = $playerBoardView -match "func\s+draw_player_facing\(\)[\s\S]*var\s+base_points\s*:=\s*chevron_points\(center,\s*forward,\s*length,\s*depth,\s*stroke\)[\s\S]*palette\[`"direction_fill`"\][\s\S]*base_points,[\s\S]*palette\[`"player`"\]" -and $playerBoardView -notmatch 'func\s+draw_player_facing\(\)[\s\S]*palette\[`"floor`"\]' -and $playerBoardView -match 'func\s+scale_points_from\(' -and $visualStyle -match "FACING_CHV_OUTLINE_RATIO\s*:=\s*0\.017" -and $visualStyle -notmatch 'FACING_CHV_CLEARANCE_RATIO' -and $visualStyle -match '"direction_fill": Color\("#141414"\)' -and $visualStyle -match '"direction_fill": Color\("#f4f3f1"\)'
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
		Name = "player facing chevron uses slender inset proportions with a right-angle tip"
		Pass = $visualStyle -match "FACING_CHV_LEN_RATIO\s*:=\s*0\.40" -and $visualStyle -match "FACING_CHV_DEPTH_RATIO\s*:=\s*0\.20" -and $visualStyle -match "FACING_CHV_STROKE_RATIO\s*:=\s*0\.40" -and $visualStyle -match "FACING_CHV_INSET_RATIO\s*:=\s*0\.025" -and $playerBoardView -match "cell_size\s*/\s*2\.0[\s\S]*cell_size\s*\*\s*VisualStyle\.FACING_CHV_INSET_RATIO"
	},
	@{
		Name = "player mode animates player and block displacement"
		Pass = $gameBoard -match "start_player_displacement\(player_from,\s*target\)" -and $gameBoard -match "start_block_displacement\([\s\S]*pushed_block_id,[\s\S]*block_from,[\s\S]*block_target" -and $gameBoard -match 'has_method\("play_player_displacement"\)' -and $gameBoard -match 'has_method\("play_block_displacement"\)' -and $playerBoardView -match "func\s+play_player_displacement\(" -and $playerBoardView -match "func\s+play_block_displacement\([\s\S]*player_queue_reveal_pending\s*=\s*player_queue_changed[\s\S]*PUSH_DISPLACEMENT_DELAY_SECONDS[\s\S]*tween_callback\(reveal_player_queue\)[\s\S]*set_displacement_progress" -and $playerBoardView -match "func\s+draw_player_stored_vector\(\)[\s\S]*player_queue_reveal_pending" -and $playerBoardView -match "func\s+animated_cell_position\(\)[\s\S]*\.lerp\(" -and $visualStyle -match "PUSH_DISPLACEMENT_DELAY_SECONDS\s*:=\s*0\.\d+" -and $visualStyle -match "DISPLACEMENT_SECONDS\s*:=\s*0\.\d+"
	},
	@{
		Name = "trigger vectors fade while their action runs"
		Pass = ([regex]::Matches($gameBoard, "start_trigger_displacement\(\s*[\r\n]+\s*carrier_id,\s*[\r\n]+\s*vector_name,")).Count -eq 3 -and $gameBoard -match 'has_method\("play_trigger_displacement"\)' -and $playerBoardView -match "func\s+play_trigger_displacement\(" -and $playerBoardView -match "TRIGGER_FLASH_IN_SECONDS[\s\S]*TRIGGER_FLASH_HOLD_SECONDS[\s\S]*set_displacement_progress[\s\S]*parallel\(\)\.tween_method\(\s*[\r\n]+\s*set_trigger_flash_alpha[\s\S]*TRIGGER_FLASH_OUT_SECONDS" -and $playerBoardView -match "func\s+draw_trigger_flash\(\)[\s\S]*var\s+block_index:\s*int\s*=\s*int\([\s\S]*find_block_index_by_id\(trigger_flash_block_id\)[\s\S]*var\s+block_cell:\s*Vector2i\s*=\s*block\[`"cell`"\][\s\S]*draw_direction_triangle\(" -and $playerBoardView -match 'palette\["direction_fill"\]\.lerp\([\s\S]*palette\["trigger_flash"\]' -and $visualStyle -match "TRIGGER_FLASH_IN_SECONDS\s*:=\s*0\.04" -and $visualStyle -match "TRIGGER_FLASH_HOLD_SECONDS\s*:=\s*0\.08" -and $visualStyle -match "TRIGGER_FLASH_OUT_SECONDS\s*:=\s*DISPLACEMENT_SECONDS" -and $visualStyle -match '"trigger_flash": Color\("#dedede"\)' -and $visualStyle -match '"trigger_flash": Color\("#30302f"\)'
	},
	@{
		Name = "collision source approaches holds and returns around target movement"
		Pass = $playerBoardView -match "is_collision\s*:=\s*carrier_id\s*!=\s*moving_block_id" -and $playerBoardView -match "TRIGGER_FLASH_HOLD_SECONDS[\s\S]*set_collision_source_offset_ratio[\s\S]*COLLISION_APPROACH_SECONDS[\s\S]*COLLISION_HOLD_SECONDS[\s\S]*set_collision_lead_progress[\s\S]*COLLISION_TARGET_LEAD_SECONDS[\s\S]*set_collision_follow_progress" -and $playerBoardView -match "func\s+set_collision_lead_progress\([\s\S]*COLLISION_TARGET_LEAD_RATIO[\s\S]*func\s+set_collision_follow_progress\([\s\S]*collision_source_offset_ratio[\s\S]*update_collision_flash" -and $playerBoardView -match "block_id\s*==\s*collision_carrier_block_id[\s\S]*collision_source_offset_ratio" -and $playerBoardView -notmatch "draw_collision_contact|collision_contact_alpha" -and $visualStyle -match "COLLISION_COMPRESSION_RATIO\s*:=\s*0\.010" -and $visualStyle -match "COLLISION_CONTACT_OFFSET_RATIO\s*:=\s*\([\s\S]*BLOCK_INSET_RATIO\s*\+\s*COLLISION_COMPRESSION_RATIO" -and $visualStyle -match "COLLISION_TARGET_SECONDS\s*:=\s*0\.13" -and $visualStyle -match "COLLISION_TARGET_LEAD_RATIO\s*:=\s*0\.05" -and $visualStyle -match "COLLISION_TARGET_LEAD_SECONDS\s*:=\s*0\.025" -and $visualStyle -match "COLLISION_TARGET_FOLLOW_SECONDS\s*:=\s*\([\s\S]*COLLISION_TARGET_SECONDS\s*-\s*COLLISION_TARGET_LEAD_SECONDS" -and $visualStyle -match "COLLISION_APPROACH_SECONDS\s*:=\s*\([\s\S]*COLLISION_TARGET_SECONDS\s*\*\s*COLLISION_CONTACT_OFFSET_RATIO" -and $visualStyle -match "COLLISION_HOLD_SECONDS\s*:=\s*0\.050" -and $visualStyle -match "COLLISION_RETURN_SECONDS\s*:=\s*0\.07"
	},
	@{
		Name = "collision contact uses nonrepeating light wood impacts"
		Pass = @($collisionImpactSoundPaths | Where-Object { -not (Test-Path -LiteralPath $_) }).Count -eq 0 -and $audioFeedback -match 'COLLISION_IMPACT_STREAMS:\s*Array\[AudioStream\][\s\S]*impactWood_light_000\.ogg[\s\S]*impactWood_light_004\.ogg' -and $audioFeedback -match 'TRIGGER_ACTIVATION_COLLISION_VOLUME_DB\s*:=\s*-16\.0' -and $audioFeedback -match 'COLLISION_IMPACT_VOLUME_DB\s*:=\s*2\.0' -and $audioFeedback -match 'collision_impact_player\.volume_db\s*=\s*COLLISION_IMPACT_VOLUME_DB' -and $audioFeedback -match 'func\s+play_collision_impact\(\)[\s\S]*trigger_activation_player\.volume_db\s*=\s*\([\s\S]*TRIGGER_ACTIVATION_COLLISION_VOLUME_DB[\s\S]*nonrepeating_index\([\s\S]*collision_impact_player\.play\(\)' -and $gameBoard -match 'func\s+play_collision_impact_feedback\(\)[\s\S]*audio_feedback\.play_collision_impact\(\)' -and $playerBoardView -match 'COLLISION_APPROACH_SECONDS[\s\S]*tween_callback\(play_collision_contact_feedback\)[\s\S]*COLLISION_HOLD_SECONDS' -and $playerBoardView -match 'func\s+play_collision_contact_feedback\(\)[\s\S]*play_collision_impact_feedback\(\)' -and $playerAnimationCheck -match 'collision impact should play at visual contact' -and $playerAnimationCheck -match 'collision impact should begin only at the contact boundary' -and $playerAnimationCheck -match 'collision contact should duck the release sound'
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
		Name = "empty release gives the player a weak neutral hint"
		Pass = $gameBoard -match 'install_order\.is_empty\(\)[\s\S]*Nothing installed to release\.[\s\S]*start_player_hint_feedback\(\)' -and $playerBoardView -match 'func\s+play_player_hint_flash\(cell:\s*Vector2i\)[\s\S]*ERROR_FLASH_PLAYER[\s\S]*"hint_flash"[\s\S]*HINT_FLASH_MAX_ALPHA[\s\S]*HINT_FLASH_SECONDS' -and $playerBoardView -match 'draw_player_body\(\)[\s\S]*draw_player_error_flash\(\)[\s\S]*draw_player_stored_vector\(\)' -and $playerBoardView -match 'func\s+draw_player_error_flash\(\)[\s\S]*ERROR_FLASH_PLAYER[\s\S]*palette\[error_flash_color_key\][\s\S]*draw_colored_polygon\([\s\S]*player_body_points' -and $playerAnimationCheck -match 'check_empty_release_hint\(game\)'
	},
	@{
		Name = "red error flashes share one error sound"
		Pass = (Test-Path -LiteralPath $errorSound005Path) -and $gameBoard -match 'func\s+start_block_error_feedback\([^)]*\)[\s\S]*play_error_red_feedback\(\)' -and $gameBoard -notmatch 'start_player_error_feedback|play_player_error_flash' -and $audioFeedback -match 'ERROR_RED_STREAM:\s*AudioStream[\s\S]*error_005\.ogg' -and $audioFeedback -notmatch 'error_006\.ogg|last_error_red_index'
	},
	@{
		Name = "neutral hints and blocked releases use distinct sound families"
		Pass = (Test-Path -LiteralPath $hintSoundPath) -and @($releaseSoundPaths | Where-Object { -not (Test-Path -LiteralPath $_) }).Count -eq 0 -and $gameBoard -match 'func\s+start_player_hint_feedback\(\)[\s\S]*play_interact_hint_feedback\(\)' -and $gameBoard -match 'func\s+start_block_hint_feedback\([^)]*\)[\s\S]*play_interact_hint_feedback\(\)' -and $audioFeedback -match 'INTERACT_HINT_STREAM:\s*AudioStream[\s\S]*bong_001\.ogg' -and $audioFeedback -match 'RELEASE_DISSIPATE_STREAMS:\s*Array\[AudioStream\][\s\S]*impactPlank_medium_000\.ogg[\s\S]*impactPlank_medium_004\.ogg' -and $playerBoardView -match 'elif\s+is_blocked_release:[\s\S]*tween_callback\(\s*play_blocked_release_contact_feedback\s*\)[\s\S]*set_blocked_release_shake_progress' -and $playerBoardView -match 'func\s+play_blocked_release_contact_feedback\(\)[\s\S]*play_release_dissipate_feedback\(\)'
	},
	@{
		Name = "releases use restrained cloth movement audio"
		Pass = (Test-Path -LiteralPath $triggerActivationSoundPath) -and ([regex]::Matches($gameBoard, '(?m)^\s+play_trigger_activation_feedback\(\)\s*$')).Count -eq 1 -and ([regex]::Matches($gameBoard, '(?m)^\s+play_block_push_feedback\(\)\s*$')).Count -eq 1 -and $gameBoard -match 'vector_name\s*==\s*""[\s\S]*play_trigger_activation_feedback\(\)[\s\S]*var\s+direction' -and $playerBoardView -notmatch 'play_release_block_motion_feedback' -and $audioFeedback -match 'TRIGGER_ACTIVATION_STREAM:\s*AudioStream[\s\S]*cloth2\.ogg' -and $audioFeedback -match 'TRIGGER_ACTIVATION_VOLUME_DB\s*:=\s*0\.0' -and $audioFeedback -match 'func\s+play_trigger_activation\(\)[\s\S]*trigger_activation_player\.stream\s*=\s*TRIGGER_ACTIVATION_STREAM[\s\S]*trigger_activation_player\.play\(\)' -and $audioFeedback -notmatch 'dragon-studio-simple-whoosh|TRIGGER_ACTIVATION_FADE|forceField_001\.ogg|func\s+play_release\(' -and $audioFeedback -match 'release_dissipate_player:\s*AudioStreamPlayer' -and $playerAnimationCheck -match 'release activation sound should cover release movement' -and $playerAnimationCheck -match 'release sound should keep its configured volume' -and $playerAnimationCheck -match 'blocked trigger should never play successful block movement'
	},
	@{
		Name = "install and title confirmation share switch34"
		Pass = (Test-Path -LiteralPath $confirmSoundPath) -and $audioFeedback -match 'INSTALL_STREAM:\s*AudioStream[\s\S]*switch34\.ogg' -and $audioFeedback -match 'INSTALL_VOLUME_DB\s*:=\s*-4\.0' -and $audioFeedback -match 'func\s+play_install\(\)[\s\S]*install_player\.play\(\)' -and $gameBoard -match 'func\s+play_install_feedback\(\)[\s\S]*audio_feedback\.play_install\(\)' -and $gameBoard -match 'play_install_feedback\(\)\s*[\r\n]+\s*render_all\(\)\s*[\r\n]+\s*play_facing_action\(\)' -and $titleScreen -match 'CONFIRM_STREAM:\s*AudioStream[\s\S]*switch34\.ogg' -and $titleScreen -match 'CONFIRM_VOLUME_DB\s*:=\s*-4\.0' -and $titleScreen -notmatch 'SELECT_STREAM|SELECT_VOLUME_DB|play_select_feedback|select_player' -and $titleScreen -match 'func\s+play_confirm_feedback\(\)[\s\S]*confirm_player\.play\(\)' -and $titleScreen -match 'func\s+activate_selection\(\)[\s\S]*extra_unlocked\(\)[\s\S]*play_confirm_feedback\(\)[\s\S]*play_config_action\('
	},
	@{
		Name = "stationary turns and title selection share click2"
		Pass = (Test-Path -LiteralPath $turnSoundPath) -and $audioFeedback -match 'TURN_STREAM:\s*AudioStream[\s\S]*click2\.ogg' -and $audioFeedback -match 'TURN_VOLUME_DB\s*:=\s*-8\.0' -and $audioFeedback -match 'func\s+play_turn\(\)[\s\S]*turn_player\.play\(\)' -and $gameBoard -match 'var\s+facing_changed\s*:=\s*facing_direction\s*!=\s*direction' -and $gameBoard -match 'block_index\s*!=\s*-1\s+and\s+facing_changed[\s\S]*play_turn_feedback\(\)[\s\S]*render_all\(\)' -and $gameBoard -match 'not\s+is_cell_walkable_for_player\([^)]*\)[\s\S]*if\s+facing_changed:\s*[\r\n]+\s*play_turn_feedback\(\)' -and ([regex]::Matches($gameBoard, '(?m)^\s*play_turn_feedback\(\)\s*$')).Count -eq 2 -and $gameBoard -match 'func\s+play_turn_feedback\(\)[\s\S]*audio_feedback\.play_turn\(\)' -and $titleScreen -match 'TURN_STREAM:\s*AudioStream[\s\S]*click2\.ogg' -and $titleScreen -match 'TURN_VOLUME_DB\s*:=\s*-8\.0' -and $titleScreen -match 'func\s+select_direction\([^)]*\)[\s\S]*selected_direction\s*==\s*direction[\s\S]*return[\s\S]*play_turn_feedback\(\)' -and $titleScreen -match 'func\s+play_turn_feedback\(\)[\s\S]*turn_player\.play\(\)'
	},
	@{
		Name = "completion confirmation begins with the delayed goal pulse"
		Pass = (Test-Path -LiteralPath $completionSoundPath) -and $audioFeedback -match 'COMPLETION_STREAM:\s*AudioStream[\s\S]*confirmation_003\.ogg' -and $audioFeedback -match 'COMPLETION_VOLUME_DB\s*:=\s*-4\.0' -and $audioFeedback -match 'func\s+play_completion\(\)[\s\S]*completion_player\.play\(\)' -and $gameBoard -match 'func\s+play_completion_sound_feedback\(\)[\s\S]*audio_feedback\.play_completion\(\)' -and $playerBoardView -match 'func\s+begin_completion_pulse\(\)[\s\S]*play_completion_sound_feedback\(\)[\s\S]*queue_redraw\(\)' -and $playerAnimationCheck -match 'completion sound should remain silent during the pulse delay' -and $playerAnimationCheck -match 'completion sound should begin with the completed-goal pulse'
	},
	@{
		Name = "successful player movement uses concrete footstep variants"
		Pass = @($moveSoundPaths | Where-Object { -not (Test-Path -LiteralPath $_) }).Count -eq 0 -and $gameBoard -match 'Moved through empty space\.[\s\S]*play_player_move_feedback\(\)[\s\S]*start_player_displacement\(' -and $audioFeedback -match 'PLAYER_MOVE_STREAMS:\s*Array\[AudioStream\][\s\S]*footstep_concrete_000\.ogg[\s\S]*footstep_concrete_004\.ogg' -and $audioFeedback -match 'func\s+play_player_move\(\)[\s\S]*nonrepeating_index\('
	},
	@{
		Name = "successful player pushes use the amplified leather slide"
		Pass = (Test-Path -LiteralPath $blockPushSoundPath) -and $gameBoard -match 'Push %s: block %s[\s\S]*play_block_push_feedback\(\)[\s\S]*play_facing_action\(\)[\s\S]*start_block_displacement\(' -and $audioFeedback -match 'BLOCK_PUSH_STREAM:\s*AudioStream[\s\S]*handleSmallLeather2\.ogg' -and $audioFeedback -match 'BLOCK_PUSH_VOLUME_DB\s*:=\s*10\.0' -and $audioFeedback -match 'func\s+play_block_push\(\)[\s\S]*block_push_player\.play\(\)'
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
		Pass = $campaign -match 'preload\("res://scripts/level_catalog\.gd"\)' -and $campaign -match 'const\s+AREAS\s*:=\s*LevelCatalogData\.AREAS' -and $campaign -notmatch 'collection_path|load_collection_sections' -and ([regex]::Matches($levelCatalog, '"id":\s*"')).Count -eq 36 -and ([regex]::Matches($levelCatalog, '"name":\s*"')).Count -eq 36 -and ([regex]::Matches($levelCatalog, '"source":\s*"!cell-edge-v1')).Count -eq 36
	},
	@{
		Name = "campaign progress persists automatically through ConfigFile"
		Pass = $campaign -match 'SAVE_VERSION\s*:=\s*1' -and $campaign -match 'DEFAULT_SAVE_PATH\s*:=\s*"user://progress\.cfg"' -and $campaign -match 'func\s+_ready\(\)[\s\S]*load_progress\(\)' -and $campaign -match 'func\s+complete_level\([^)]*\)[\s\S]*completed_levels\[level_id\]\s*=\s*true[\s\S]*save_progress\(\)' -and $campaign -match 'func\s+reset_progress\(\)[\s\S]*completed_levels\.clear\(\)[\s\S]*save_progress\(\)' -and $campaign -match 'func\s+save_progress\(\)[\s\S]*ConfigFile\.new\(\)[\s\S]*config\.save\(save_path\)' -and $campaign -match 'func\s+load_progress\(\)[\s\S]*config\.load\(save_path\)[\s\S]*is_known_level_id\(level_id\)' -and $campaignFlowCheck -match 'Saved completion did not reload from ConfigFile' -and $campaignFlowCheck -match 'Reset progress did not overwrite the persisted completion state' -and $classicLevelSelectCheck -match 'Campaign\.save_path\s*=\s*TEST_SAVE_PATH'
	},
	@{
		Name = "area three hard branches jointly unlock Fin"
		Pass = $levelCatalog -match '"id":\s*"3-9"[\s\S]*?"requires":\s*\["3-8"\]' -and $levelCatalog -match '"id":\s*"3-10"[\s\S]*?"requires":\s*\["3-8"\]' -and $levelCatalog -match '"id":\s*"3-11"[\s\S]*?"requires":\s*\["3-8"\]' -and $levelCatalog -match '"id":\s*"3-12"[\s\S]*?"name":\s*"Fin"[\s\S]*?"requires":\s*\["3-9",\s*"3-10",\s*"3-11"\]' -and $classicLevelSelect -match 'for\s+required_value\s+in\s+requirements:[\s\S]*if\s+not\s+Campaign\.is_completed\(String\(required_value\)\):[\s\S]*return\s+false'
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
		Pass = $gameBoard -notmatch 'const\s+AsciiMapParser\s*=' -and $playerBoardView -notmatch 'func\s+set_grid_lines_visible\(visible:' -and $playerBoardView -notmatch 'start_displacement_tween\([^)]*\bease:' -and $classicLevelSelect -notmatch '\b(?:selected_index|index)\s*/\s*GRID_COLUMNS' -and $playerBoardView -notmatch 'func\s+scale_points_from\([^)]*\bscale:\s*float' -and $worldMap -notmatch 'func\s+scale_points_from\([^)]*\bscale:\s*float' -and $titleScreen -notmatch 'func\s+scale_points_from\([^)]*\bscale:\s*float' -and $extraBoard -notmatch '\b(?:COLS|ROWS)\s*/\s*2(?!\.)'
	},
	@{
		Name = "EXTRA PLN uses a three-slot rolling direction inventory plus one temporary final-ULT slot"
		Pass = $extraCharacterData -match '"PLN"\s*:\s*\{(?:(?!\r?\n\s*\},)[\s\S])*?"seq"\s*:\s*3' -and $extraHud -match 'for\s+i\s+in\s+_max_slots\s*\+\s*Inventory\.ULT_COMPLETION_OVERFLOW_SLOTS' -and $extraBoard -match 'inventory\.setup\(char_name\)'
	},
	@{
		Name = "EXTRA only grants temporary overflow on the final ULT dash"
		Pass = $extraInventory -match 'const\s+ULT_COMPLETION_OVERFLOW_SLOTS\s*:=\s*1' -and $extraInventory -match 'func\s+push_ultimate_completion\(dir:\s*int\)' -and $extraBoard -match 'func\s+_complete_live_move\((?:(?!\r?\nfunc\s)[\s\S])*?if\s+is_bonus_step:(?:(?!\r?\nfunc\s)[\s\S])*?inventory\.push\(memory_token\)' -and $extraBoard -match 'func\s+_try_ultimate_dash\((?:(?!\r?\nfunc\s)[\s\S])*?var\s+completes_ultimate:\s*bool\s*=\s*ultimate_dashes_remaining\s*==\s*0(?:(?!\r?\nfunc\s)[\s\S])*?inventory\.push_ultimate_completion\(dir\)'
	},
	@{
		Name = "EXTRA STEP only moves onto LIVE cells while normal attacks consume directions"
		Pass = $extraBoard -match 'func\s+try_move\(dir:\s*int\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+is_bonus_step:\s*\r?\n\s*return\s+false\s*\r?\n\s*#\s*Dead cell(?:(?!\r?\nfunc\s)[\s\S])*?if\s+not\s+_consume_attack_direction\(dir\):' -and $extraSimBoard -match 'if\s+is_bonus:\s*\r?\n\s*return\s+false\s*\r?\n\s*if\s+not\s+consume_attack_direction\(d\):' -and $extraCma -match 'if\s+is_bonus:\s*\r?\n\s*return\s+False\s*\r?\n\s*if\s+not\s+self\.consume_attack_direction\(d\):'
	},
	@{
		Name = "EXTRA HUD shows the last full Heat and streak energy reward"
		Pass = $extraHud -match 'HeatMeterScript\s*=\s*preload\("res://scripts/extra_mode/HeatMeter\.gd"\)' -and $extraHud -match 'func\s+update_combo\(combo:\s*int,\s*tier5_streak:\s*int\)(?:(?!\r?\nfunc\s)[\s\S])*?combo_label\.text\s*=\s*"HEAT"(?:(?!\r?\nfunc\s)[\s\S])*?heat_meter\.set_heat\(combo\)' -and $extraHeatMeter -match 'SEGMENT_COUNT\s*:=\s*5' -and $extraHeatMeter -match 'func\s+set_heat\(value:\s*int\)' -and $extraHud -match 'var\s+energy_gain_label:\s*Label' -and $extraHud -match 'func\s+update_energy_gain\(quarter_units:\s*int\)(?:(?!\r?\nfunc\s)[\s\S])*?energy_gain_label\.visible\s*=\s*quarter_units\s*>\s*0(?:(?!\r?\nfunc\s)[\s\S])*?if\s+quarter_units\s*<=\s*0:\s*\r?\n\s*return(?:(?!\r?\nfunc\s)[\s\S])*?"\+%d"\s*%\s*quarter_units' -and $extraBoard -match 'func\s+get_last_energy_gain\(\)\s*->\s*int:\s*\r?\n\s*return\s+last_energy_gain_quarter_units' -and $extraBoard -match 'func\s+_charge_energy_for_combo\(combo:\s*int\)\s*->\s*void:\s*\r?\n\s*_apply_energy_gain\(energy_gain_for_kill\(combo,\s*score_manager\.tier5_streak\)\)' -and $extraBoard -match 'func\s+_apply_energy_gain\(energy_gain:\s*int\)(?:(?!\r?\nfunc\s)[\s\S])*?last_energy_gain_quarter_units\s*=\s*energy_gain' -and $extraMain -match 'hud\.update_energy_gain\(board\.get_last_energy_gain\(\)\)'
	},
	@{
		Name = "EXTRA heat rises to six and cools one tier on interruption"
		Pass = $extraScoreManager -match 'const\s+BASE_KILL_SCORE\s*:=\s*1' -and $extraScoreManager -match 'const\s+MAX_COMBO_TIER\s*:=\s*5' -and $extraScoreManager -match 'const\s+COMBO_SCORE_MULTIPLIERS\s*:=\s*\[1,\s*2,\s*5,\s*10,\s*20\]' -and $extraScoreManager -match 'func\s+advance_combo\(\)(?:(?!\r?\nfunc\s)[\s\S])*?mini\(combo_counter\s*\+\s*1,\s*MAX_COMBO_TIER\)' -and $extraScoreManager -match 'func\s+decay_combo\(\)(?:(?!\r?\nfunc\s)[\s\S])*?maxi\(0,\s*combo_counter\s*-\s*1\)' -and $extraScoreManager -match 'func\s+on_move_to_live\(\)\s*->\s*void:\s*\r?\n\s*decay_combo\(\)' -and $extraBoard -match 'score_manager\.advance_combo\(\)' -and $extraBoard -match 'func\s+try_wait\(\)(?:(?!\r?\nfunc\s)[\s\S])*?score_manager\.on_move_to_live\(\)' -and $extraComboBot -match 'func\s+_advanced_combo\(combo:\s*int\)(?:(?!\r?\nfunc\s)[\s\S])*?mini\(combo\s*\+\s*1,\s*ScoreManager\.MAX_COMBO_TIER\)' -and $extraComboBot -match 'func\s+_decayed_combo\(combo:\s*int\)(?:(?!\r?\nfunc\s)[\s\S])*?maxi\(0,\s*combo\s*-\s*1\)'
	},
	@{
		Name = "EXTRA spawn-hit shields reset heat instead of leaving it intact"
		Pass = $extraBoard -match 'func\s+_resolve_player_spawn_hit\(pos:\s*Vector2i,\s*cell_type:\s*int\)(?:(?!
?
func\s)[\s\S])*?if\s+_spawn_hit_uses_energy:(?:(?!
?
func\s)[\s\S])*?score_manager\.reset_combo\(\)(?:(?!
?
func\s)[\s\S])*?score_manager\.on_kill\(cell_type\)(?:(?!
?
func\s)[\s\S])*?if\s+consumed_count\s*>=\s*2:\s*
?
\s*score_manager\.reset_combo\(\)\s*
?
\s*score_manager\.on_kill\(cell_type\)'
	},
	@{
		Name = "EXTRA spawn-hit Heat reset stays aligned with F4 and Python simulators"
		Pass = $extraSimBoard -match 'func\s+reset_combo\(\)\s*->\s*void:\s*\r?\n\s*combo\s*=\s*0' -and $extraSimBoard -match 'func\s+_resolve_player_spawn_hit\(pos:\s*Vector2i\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+energy\s*>=\s*ENERGY_SLOT_COST(?:(?!\r?\nfunc\s)[\s\S])*?reset_combo\(\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+consumed\s*>=\s*2:\s*\r?\n\s*reset_combo\(\)' -and $extraCma -match 'def\s+reset_combo\(self\)[\s\S]*?self\.combo\s*=\s*0' -and $extraCma -match 'def\s+_resolve_player_spawn_hit\(self,\s*pos[\s\S]*?self\.reset_combo\(\)[\s\S]*?if\s+consumed\s*>=\s*2:\s*\r?\n\s*self\.reset_combo\(\)'
	},
	@{
		Name = "EXTRA ULT grants only repeating streak energy while X cannot attack"
		Pass = $extraBoard -notmatch '_bonus_step_kill_active' -and $extraBoard -match 'func\s+_kill_flow\((?:(?!\r?\nfunc\s)[\s\S])*?if\s+_ultimate_chain_started:\s*\r?\n\s*_charge_tier5_streak_energy_bonus\(score_manager\.combo_counter\)\s*\r?\n\s*else:\s*\r?\n\s*_charge_energy_for_combo' -and $extraSimBoard -match 'func\s+_kill_flow\((?:(?!\r?\nfunc\s)[\s\S])*?if\s+allow_streak_energy:\s*\r?\n\s*charge_streak_energy\(combo\)\s*\r?\n\s*elif\s+not\s+energy_sterile:\s*\r?\n\s*charge_energy\(combo\)' -and $extraCma -match 'def\s+_kill_flow\((?:(?!\r?\n\s*def\s)[\s\S])*?if\s+allow_streak_energy:\s*\r?\n\s*self\.charge_streak_energy\(self\.combo\)\s*\r?\n\s*elif\s+not\s+energy_sterile:\s*\r?\n\s*self\.charge_energy\(self\.combo\)'
	},
	@{
		Name = "EXTRA spends one full energy slot to arm a free combo-preserving bonus step"
		Pass = $extraBoard -match 'ENERGY_QUARTER_UNITS_MAX\s*:=\s*16' -and $extraBoard -match 'ENERGY_SLOT_COST\s*:=\s*4' -and $extraBoard -match 'TIER5_STREAK_ENERGY_BONUS\s*:=\s*4' -and $extraBoard -match 'func\s+try_energy_bonus_step\(\)(?:(?!\r?\nfunc\s)[\s\S])*?energy_quarter_units\s*-=\s*cost(?:(?!\r?\nfunc\s)[\s\S])*?bonus_step_armed\s*=\s*true' -and $extraBoard -match 'func\s+energy_gain_for_combo\(combo:\s*int\)(?:(?!\r?\nfunc\s)[\s\S])*?1:\s*\r?\n\s*return\s+1(?:(?!\r?\nfunc\s)[\s\S])*?2:\s*\r?\n\s*return\s+2(?:(?!\r?\nfunc\s)[\s\S])*?3:\s*\r?\n\s*return\s+2(?:(?!\r?\nfunc\s)[\s\S])*?4:\s*\r?\n\s*return\s+4(?:(?!\r?\nfunc\s)[\s\S])*?combo\s*>=\s*5:\s*\r?\n\s*return\s+4' -and $extraBoard -match 'func\s+tier5_streak_energy_bonus\(combo:\s*int,\s*tier5_streak:\s*int\)(?:(?!\r?\nfunc\s)[\s\S])*?tier5_streak\s*%\s*ScoreManager\.TIER5_STREAK_THRESHOLD\s*==\s*0(?:(?!\r?\nfunc\s)[\s\S])*?return\s+TIER5_STREAK_ENERGY_BONUS' -and $extraMain -match 'KEY_X(?:(?!\r?\n\s*#)[\s\S])*?try_energy_bonus_step\(\)'
	},
	@{
		Name = "EXTRA board clear pays 2000 and refills all energy"
		Pass = $extraBoard -match 'const\s+BOARD_CLEAR_BONUS\s*:=\s*2000' -and $extraBoard -match 'if\s+not\s+_has_any_dead_cell\(\):\s*\r?\n\s*score_manager\.award_bonus\(BOARD_CLEAR_BONUS\)\s*\r?\n\s*_fill_energy_for_board_clear\(\)' -and $extraBoard -match 'func\s+_fill_energy_for_board_clear\(\)(?:(?!\r?\nfunc\s)[\s\S])*?energy_quarter_units\s*=\s*ENERGY_QUARTER_UNITS_MAX' -and $extraSimBoard -match 'if\s+not\s+_has_any_dead_cell\(\):\s*\r?\n\s*score\s*\+=\s*BOARD_CLEAR_BONUS\s*\r?\n\s*energy\s*=\s*ENERGY_MAX' -and $extraCma -match 'if\s+not\s+any\(DEAD\s+in\s+row\s+for\s+row\s+in\s+self\.grid\):\s*\r?\n\s*self\.score\s*\+=\s*BOARD_CLEAR_BONUS\s*\r?\n\s*self\.energy\s*=\s*ENERGY_MAX'
	},
	@{
		Name = "EXTRA consumes full energy on Z to activate the four-dash ULT"
		Pass = $extraBoard -match 'ULT_DASH_COUNT\s*:=\s*4' -and $extraBoard -match 'func\s+try_energy_ultimate\(\)(?:(?!\r?\nfunc\s)[\s\S])*?energy_quarter_units\s*<\s*ENERGY_QUARTER_UNITS_MAX(?:(?!\r?\nfunc\s)[\s\S])*?energy_quarter_units\s*=\s*0(?:(?!\r?\nfunc\s)[\s\S])*?ultimate_dashes_remaining\s*=\s*ULT_DASH_COUNT' -and $extraBoard -notmatch 'func\s+try_energy_ultimate\(\)(?:(?!\r?\nfunc\s)[\s\S])*?score_manager\.reset_combo\(\)' -and $extraBoard -match 'func\s+_try_ultimate_dash\(dir:\s*int\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+destination\s*==\s*origin:\s*\r?\n\s*return\s+false(?:(?!\r?\nfunc\s)[\s\S])*?_consume_attack_direction\(dir\)' -and $extraBoard -match 'func\s+_try_ultimate_dash\(dir:\s*int\)(?:(?!\r?\nfunc\s)[\s\S])*?player_pos\s*=\s*destination\s*\r?\n\s*if\s+completes_ultimate:\s*\r?\n\s*inventory\.push_ultimate_completion\(dir\)\s*\r?\n\s*else:\s*\r?\n\s*inventory\.push\(dir\)' -and $extraBoard -match 'var\s+freeze_spawn_cycle:\s*bool\s*=\s*ultimate_dashes_remaining\s*>\s*0(?:(?!\r?\nfunc\s)[\s\S])*?_finalize_turn_after_action\(freeze_spawn_cycle\)' -and $extraBoard -notmatch 'func\s+_try_ultimate_dash\(dir:\s*int\)(?:(?!\r?\nfunc\s)[\s\S])*?score_manager\.reset_combo\(\)' -and $extraBoard -match 'if\s+_ultimate_chain_started:\s*\r?\n\s*_charge_tier5_streak_energy_bonus\(score_manager\.combo_counter\)' -and $extraMain -match 'KEY_Z(?:(?!\r?\n\s*#)[\s\S])*?try_energy_ultimate\(\)' -and $extraMain -notmatch 'KEY_X(?:(?!\r?\n\s*#)[\s\S])*?try_wait\(\)'
	},
	@{
		Name = "EXTRA full ULT energy prevents surrounded Game Over"
		Pass = $extraBoard -match 'func\s+_check_game_over\(\)(?:(?!\r?\nfunc\s)[\s\S])*?var\s+character_data:\s*Dictionary\s*=\s*CharacterData\.CHARACTERS\[current_character\](?:(?!\r?\nfunc\s)[\s\S])*?energy_quarter_units\s*>=\s*ENERGY_QUARTER_UNITS_MAX\s+and\s+bool\(character_data\["has_ult"\]\):\s*\r?\n\s*return'
	},
	@{
		Name = "EXTRA shows fixed large chevrons while ULT input is ready"
		Pass = $extraBoard -match 'var\s+ultimate_ready:\s*bool\s*=\s*game_state\.is_idle\(\)\s+and\s+ultimate_dashes_remaining\s*>\s*0' -and $extraBoard -match 'player_node\.set_ultimate_dash_ready\(ultimate_ready\)' -and $extraPlayer -match 'func\s+set_ultimate_dash_ready\(ready:\s*bool\)' -and $extraPlayer -match 'func\s+_draw_ultimate_dash_arrows\(\)' -and $extraPlayer -match 'ARROW_DISTANCE\s*:=\s*58\.0' -and $extraPlayer -match 'ARROW_FRONT_DEPTH\s*:=\s*12\.0' -and $extraPlayer -match 'ARROW_REAR_DEPTH\s*:=\s*9\.6' -and $extraPlayer -match 'ARROW_HALF_HEIGHT\s*:=\s*9\.6' -and $extraPlayer -match 'ULT_STATE_COLOR\s*:=\s*Color\("#DFFFE9"\)' -and $extraPlayer -match 'ULT_ARROW_COLOR\s*:=\s*Color\("#B4F2C2"\)' -and $extraPlayer -match 'ARROW_WIDTH\s*:=\s*6\.5' -and $extraPlayer -match 'draw_polyline\(arrow,\s*ULT_ARROW_COLOR,\s*ARROW_WIDTH,\s*true\)' -and $extraPlayer -notmatch 'ULT_FRAME_COLOR|ULT_COLOR' -and $extraPlayer -match 'if\s+ultimate_dash_ready:(?:(?!elif\s+not\s+bonus_step_directions)[\s\S])*?ULT_STATE_COLOR(?:(?!elif\s+not\s+bonus_step_directions)[\s\S])*?STATE_FRAME_GAP_COLOR(?:(?!elif\s+not\s+bonus_step_directions)[\s\S])*?draw_polygon\(points'
	},
	@{
		Name = "EXTRA separates window, grid gaps, live cells, enemies, and spawn warnings"
		Pass = $extraMain -match 'WINDOW_BACKGROUND_COLOR\s*:=\s*Color\("#0C0E11"\)' -and $extraMain -match 'RenderingServer\.set_default_clear_color\(WINDOW_BACKGROUND_COLOR\)' -and $extraMain -match 'func\s+_exit_tree\(\)\s*->\s*void:\s*\r?\n\s*RenderingServer\.set_default_clear_color\(_previous_clear_color\)' -and $extraBoard -match 'GRID_GAP_COLOR\s*:=\s*Color\("#262A31"\)' -and $extraBoard -match 'func\s+_draw\(\)(?:(?!\r?\nfunc\s)[\s\S])*?draw_rect\(Rect2\(Vector2\.ZERO,\s*board_size\),\s*GRID_GAP_COLOR\)' -and $extraCell -match 'LIVE_COLOR\s*:=\s*Color\("#14161C"\)' -and $extraCell -match 'DEAD_FILL_COLOR\s*:=\s*Color\("#6B242B"\)' -and $extraCell -match 'DEAD_OUTLINE_COLOR\s*:=\s*Color\("#8E3139"\)' -and $extraCell -match 'DEAD_OUTLINE_WIDTH\s*:=\s*2\.0' -and $extraCell -match 'draw_polyline\(\s*\r?\n\s*octagon\s*\+\s*PackedVector2Array\(\[octagon\[0\]\]\)' -and $extraCell -match 'SPAWN_WARNING_COLOR\s*:=\s*Color\("#FF5140"\)'
	},
	@{
		Name = "EXTRA grants one opening charge turn before spawn progression"
		Pass = $extraBoard -match 'OPENING_GRACE_TURNS\s*:=\s*1' -and $extraBoard -match '_opening_grace_turns_remaining\s*=\s*OPENING_GRACE_TURNS' -and $extraBoard -match 'func\s+_complete_turn_after_motion\(\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+_opening_grace_turns_remaining\s*>\s*0:(?:(?!\r?\nfunc\s)[\s\S])*?_opening_grace_turns_remaining\s*-=\s*1(?:(?!\r?\nfunc\s)[\s\S])*?else:\s*\r?\n\s*_advance_cycle\(\)'
	},
	@{
		Name = "EXTRA keeps every spawn batch fixed at two"
		Pass = (Test-Path -LiteralPath $extraSpawnWarningSoundPath) -and $extraBoard -match 'SPAWN_CYCLE_STEPS\s*:=\s*2' -and $extraBoard -match 'SPAWNS_PER_CYCLE\s*:=\s*2' -and $extraBoard -notmatch 'SPAWN_TURN_THRESHOLD' -and $extraBoard -match 'func\s+get_spawns_per_cycle\(\)\s*->\s*int:\s*\r?\n\s*return\s+SPAWNS_PER_CYCLE' -and $extraBoard -match 'func\s+_start_new_cycle\(\)(?:(?!\r?\nfunc\s)[\s\S])*?min\(get_spawns_per_cycle\(\),\s*available\.size\(\)\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+not\s+candidate_cells\.is_empty\(\)\s+or\s+not\s+delayed_candidate_cells\.is_empty\(\):\s*\r?\n\s*play_spawn_warning_sound\(\)'
	},
	@{
		Name = "EXTRA MCTS and Python simulators mirror fixed two-spawn batches"
		Pass = $extraSimBoard -match 'SPAWNS_PER_CYCLE\s*:=\s*2' -and $extraSimBoard -notmatch 'SPAWN_TURN_THRESHOLD' -and $extraSimBoard -match 'func\s+get_spawns_per_cycle\(\)\s*->\s*int:\s*\r?\n\s*return\s+SPAWNS_PER_CYCLE' -and $extraCma -match 'SPAWNS_PER_CYCLE\s*=\s*2' -and $extraCma -notmatch 'SPAWN_TURN_THRESHOLD' -and $extraCma -match 'def\s+spawns_per_cycle\(self\)\s*->\s*int:\s*\r?\n\s*return\s+SPAWNS_PER_CYCLE'
	},
	@{
		Name = "EXTRA keeps delayed high-score spawns but shows only final-turn bright warnings"
		Pass = $extraBoard -match 'DELAYED_SPAWN_SCORE_THRESHOLD\s*:=\s*10000' -and $extraBoard -match 'DELAYED_SPAWN_MAX_PER_CYCLE\s*:=\s*2' -and $extraBoard -match 'DELAYED_SPAWN_COUNTDOWN\s*:=\s*2' -and $extraBoard -match 'score_manager\.score\s*>=\s*DELAYED_SPAWN_SCORE_THRESHOLD' -and $extraBoard -match 'randi_range\(0,\s*DELAYED_SPAWN_MAX_PER_CYCLE\)' -and $extraBoard -match 'func\s+_advance_delayed_candidates\(' -and $extraBoard -match 'delayed_spawn_countdown\s*==\s*1' -and $extraSimBoard -match 'run_score\s*\+\s*score\s*>=\s*DELAYED_SPAWN_SCORE_THRESHOLD' -and $extraSimBoard -match 'rng\.randi_range\(0,\s*DELAYED_SPAWN_MAX_PER_CYCLE\)' -and $extraCma -match 'self\.score\s*>=\s*DELAYED_SPAWN_SCORE_THRESHOLD' -and $extraCma -match 'self\.rng\.randint\(0,\s*DELAYED_SPAWN_MAX_PER_CYCLE\)' -and $extraCell -notmatch 'candidate_phase\s*==\s*1' -and $extraCell -notmatch 'warning_color\.a'
	},
	@{
		Name = "EXTRA F4 imports current survival turn pressure"
		Pass = $extraSimBoard -match 'sim\.survival_turns\s*=\s*board\.survival_turns'
	},
	@{
		Name = "EXTRA resolves movement before spawning and unlocking input"
		Pass = $extraBoard -match 'func\s+_finalize_turn_after_action\([^)]*\)(?:(?!\r?\nfunc\s)[\s\S])*?_turn_resolution_pending\s*=\s*true(?:(?!\r?\nfunc\s)[\s\S])*?_refresh_visuals\(\)(?:(?!\r?\nfunc\s)[\s\S])*?call_deferred\("_complete_turn_after_motion"\)' -and $extraBoard -notmatch 'func\s+_finalize_turn_after_action\([^)]*\)(?:(?!\r?\nfunc\s)[\s\S])*?_advance_cycle\(\)' -and $extraBoard -match 'func\s+_complete_turn_after_motion\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_advance_cycle\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_refresh_visuals\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_finish_turn_presentation\(\)' -and $extraBoard -match 'func\s+_finish_turn_presentation\(\)(?:(?!\r?\nfunc\s)[\s\S])*?set_state\(CharacterData\.GameStateEnum\.IDLE\)(?:(?!\r?\nfunc\s)[\s\S])*?_check_game_over\(\)'
	},
	@{
		Name = "EXTRA startup snaps the player without a false movement tween"
		Pass = $extraBoard -match 'setup_character\(current_character,\s*current_attack_mode_override\)\s*\r?\n\s*player_node\.position\s*=\s*Vector2\(' -and $extraBoard -match 'player_pos\.x\s*\*\s*CELL_STEP\s*\+\s*CELL_SIZE\s*/\s*2\.0' -and $extraBoard -match 'player_pos\.y\s*\*\s*CELL_STEP\s*\+\s*CELL_SIZE\s*/\s*2\.0'
	},
	@{
		Name = "EXTRA waits for real movement completion before showing ready arrows"
		Pass = $extraBoard -match 'movement_started\.connect\(_on_player_movement_started\)' -and $extraBoard -match 'movement_finished\.connect\(_finish_player_move_visual\)' -and $extraBoard -match 'func\s+_on_player_animation_done\(\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+not\s+_player_move_visual_pending:' -and $extraBoard -match 'func\s+_finish_player_move_visual\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_turn_resolution_pending\s+and\s+not\s+_action_animation_pending' -and $extraBoard -match 'func\s+_refresh_attack_prompts\(\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+not\s+game_state\.is_idle\(\)\s+or\s+bonus_step_armed\s+or\s+ultimate_dashes_remaining\s*>\s*0:\s*\r?\n\s*return' -and $extraBoard -match 'func\s+_sync_player_move_ready\(\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+game_state\.is_idle\(\)\s+and\s+bonus_step_armed(?:(?!\r?\nfunc\s)[\s\S])*?set_bonus_step_directions\(bonus_directions\)'
	},
	@{
		Name = "EXTRA replaces movement and attack prompts with obtuse stored direction arrows"
		Pass = $extraBoard -match 'set_stored_direction_slots\(stored_directions,\s*inventory\.max_size\)' -and $extraBoard -match 'for\s+direction_value\s+in\s+inventory\.queue:' -and $extraPlayer -match 'func\s+set_stored_direction_slots\(directions:\s*Array,\s*max_size:\s*int\)' -and $extraPlayer -match 'func\s+_draw_stored_direction_arrows\(\)' -and $extraPlayer -match 'ARROW_FRONT_DEPTH\s*:=\s*4\.56' -and $extraPlayer -match 'ARROW_REAR_DEPTH\s*:=\s*3\.0' -and $extraPlayer -match 'ARROW_HALF_HEIGHT\s*:=\s*11\.0' -and $extraPlayer -match 'SEQUENCE_STEP\s*:=\s*8\.4' -and $extraPlayer -match 'OUTLINE_WIDTH\s*:=\s*6\.0' -and $extraPlayer -match 'FILL_WIDTH\s*:=\s*3\.0' -and $extraPlayer -match 'ARROW_DISTANCE\s*-\s*float\(duplicate_index\)\s*\*\s*SEQUENCE_STEP' -and $extraPlayer -match 'EXPIRING_COLOR\s*:=\s*Color\("#AAB58A"\)' -and $extraPlayer -match 'stored_direction_slots\.size\(\)\s*-\s*stored_direction_max_size\s*\+\s*1' -and $extraPlayer -notmatch 'func\s+_draw_move_ready_arrows\(\)' -and $extraPlayer -notmatch 'func\s+_draw\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_draw_attack_ready_arrows\(\)'
	},
	@{
		Name = "EXTRA places expiring duplicate directions at the inner end of their sequence"
		Pass = $extraPlayer -match 'var\s+direction_counts\s*:=\s*\{\}' -and $extraPlayer -match 'var\s+transitioning_direction_counts\s*:=\s*\{\}' -and $extraPlayer -match 'var\s+outgoing_direction_counts\s*:=\s*\{\}' -and $extraPlayer -match 'var\s+active_count:\s*int\s*=\s*\(\s*int\(direction_counts\[direction\]\)\s*-\s*int\(transitioning_direction_counts\.get\(direction,\s*0\)\)\s*-\s*int\(outgoing_direction_counts\.get\(direction,\s*0\)\)\s*\)' -and $extraPlayer -match 'duplicate_index\s*=\s*active_count\s*\+\s*transitioning_count\s*\+\s*outgoing_drawn' -and $extraPlayer -match 'duplicate_index\s*=\s*active_count\s*\+\s*transitioning_drawn' -and $extraPlayer -match 'else:\s*\r?\n\s*duplicate_index\s*=\s*int\(active_drawn_counts\.get\(direction,\s*0\)\)'
	},
	@{
		Name = "EXTRA fades outgoing and next-expiring directions in sync"
		Pass = $extraBoard -match 'prepare_stored_direction_update\(\s*arrival_directions,\s*final_directions,\s*inventory\.max_size,\s*evicted_count,\s*gained_direction\s*\)' -and $extraPlayer -match 'animate_next_expiring:\s*bool\s*=\s*false' -and $extraPlayer -match 'final_expiring_count:\s*int\s*=\s*maxi\(0,\s*final_directions\.size\(\)\s*-\s*max_size\s*\+\s*1\)' -and $extraPlayer -match '_pending_next_expiring_start\s*=\s*evicted_count' -and $extraPlayer -match 'ACTIVE_COLOR\.lerp\(EXPIRING_COLOR,\s*_next_expiring_progress\)' -and $extraPlayer -match '_direction_transition_tween\.tween_method\(\s*_set_next_expiring_progress,\s*0\.0,\s*1\.0,\s*DIRECTION_REPLACEMENT_FADE_DURATION\s*\)' -and $extraPlayer -match 'if\s+not\s+has_outgoing:\s*\r?\n\s*_direction_fade_tween\.tween_interval\(DIRECTION_REPLACEMENT_FADE_DURATION\)'
	},
	@{
		Name = "EXTRA adds the new direction after movement before evicting old arrows"
		Pass = $extraBoard -match 'func\s+_complete_live_move\((?:(?!\r?\nfunc\s)[\s\S])*?var\s+previous_directions:\s*Array\s*=\s*inventory\.queue\.duplicate\(\)(?:(?!\r?\nfunc\s)[\s\S])*?arrival_directions\.append\(memory_token\)(?:(?!\r?\nfunc\s)[\s\S])*?_hold_stored_direction_visual_until_idle\s*=\s*true(?:(?!\r?\nfunc\s)[\s\S])*?prepare_stored_direction_update\(' -and $extraBoard -match 'if\s+not\s+player_node\.has_pending_stored_direction_update\(\)\s+and\s+not\s+_hold_stored_direction_visual_until_idle:\s*\r?\n\s*player_node\.set_stored_direction_slots' -and $extraPlayer -match 'DIRECTION_REPLACEMENT_FADE_DURATION\s*:=\s*0\.10' -and $extraPlayer -notmatch 'DIRECTION_REPLACEMENT_BLINK' -and $extraPlayer -notmatch 'DIRECTION_REPLACEMENT_HIDDEN_HOLD' -and $extraPlayer -match 'func\s+prepare_stored_direction_update\(' -and $extraPlayer -match 'func\s+_finish_move\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_play_pending_direction_replacement\(\)' -and $extraPlayer -match 'func\s+_play_pending_direction_replacement\(\)(?:(?!\r?\nfunc\s)[\s\S])*?stored_direction_slots\s*=\s*_pending_arrival_slots\.duplicate\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_set_expiring_arrow_alpha,\s*1\.0,\s*0\.0,\s*DIRECTION_REPLACEMENT_FADE_DURATION' -and $extraPlayer -match 'func\s+_finish_pending_direction_update\(\)(?:(?!\r?\nfunc\s)[\s\S])*?stored_direction_slots\s*=\s*_pending_final_slots\.duplicate\(\)(?:(?!\r?\nfunc\s)[\s\S])*?movement_finished\.emit\(\)' -and $extraPlayer -match 'func\s+cancel_feedback\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_direction_fade_tween\.kill\(\)'
	},
	@{
		Name = "EXTRA skips four-arrow staging when recycling the expiring direction"
		Pass = $extraBoard -match 'var\s+replaces_same_direction:\s*bool\s*=\s*\(\s*evicted_count\s*==\s*1\s*and\s+not\s+previous_directions\.is_empty\(\)\s*and\s+int\(previous_directions\[0\]\)\s*==\s*memory_token\s*\)' -and $extraBoard -match 'if\s+replaces_same_direction:\s*\r?\n(?:(?!\r?\nfunc\s)[\s\S])*?arrival_directions\s*=\s*final_directions\.duplicate\(\)\s*\r?\n\s*evicted_count\s*=\s*0'
	},
	@{
		Name = "EXTRA keeps consumed attack direction visible through movement"
		Pass = $extraBoard -match 'var\s+attack_start_directions:\s*Array\s*=\s*inventory\.queue\.duplicate\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_consume_attack_direction\(dir\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+grid\[target\.y\]\[target\.x\]\s*==\s*CharacterData\.CellType\.LIVE:(?:(?!\r?\nfunc\s)[\s\S])*?_hold_stored_direction_visual_until_idle\s*=\s*true(?:(?!\r?\nfunc\s)[\s\S])*?prepare_stored_direction_update\(\s*attack_start_directions,\s*inventory\.queue\.duplicate\(\),\s*inventory\.max_size,\s*0\s*\)(?:(?!\r?\nfunc\s)[\s\S])*?begin_kill_anim\(' -and $extraPlayer -match 'if\s+not\s+has_outgoing\s+and\s+not\s+has_transitioning:\s*\r?\n\s*_finish_pending_direction_update\(\)' -and $extraBoard -match 'func\s+_sync_player_move_ready\(\)(?:(?!\r?\nfunc\s)[\s\S])*?not\s+player_node\.has_pending_stored_direction_update\(\)\s+and\s+not\s+_hold_stored_direction_visual_until_idle' -and $extraBoard -match 'func\s+_finish_turn_presentation\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_hold_stored_direction_visual_until_idle\s*=\s*false(?:(?!\r?\nfunc\s)[\s\S])*?GameStateEnum\.IDLE' -and $extraBoard -match 'func\s+restart\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_hold_stored_direction_visual_until_idle\s*=\s*false'
	},
	@{
		Name = "EXTRA buffers the latest direction pressed during presentation"
		Pass = $extraMain -match 'var\s+_buffered_move_direction:\s*int\s*=\s*CharacterData\.Direction\.NONE' -and $extraMain -match 'func\s+_process\(delta:\s*float\)\s*->\s*void:(?:(?!\r?\nfunc\s)[\s\S])*?if\s+hud\.is_help_visible\(\):\s*\r?\n\s*return\s*\r?\n\s*_execute_buffered_move_if_ready\(\)' -and $extraMain -match 'func\s+_execute_buffered_move_if_ready\(\)(?:(?!\r?\nfunc\s)[\s\S])*?not\s+board\.game_state\.is_idle\(\):\s*\r?\n\s*return(?:(?!\r?\nfunc\s)[\s\S])*?var\s+direction:\s*int\s*=\s*_buffered_move_direction(?:(?!\r?\nfunc\s)[\s\S])*?_buffered_move_direction\s*=\s*CharacterData\.Direction\.NONE(?:(?!\r?\nfunc\s)[\s\S])*?board\.try_move\(direction\)' -and $extraMain -match 'if\s+dir\s*!=\s*CharacterData\.Direction\.NONE:(?:(?!\r?\nfunc\s)[\s\S])*?if\s+board\.game_state\.is_idle\(\):\s*\r?\n\s*board\.try_move\(dir\)\s*\r?\n\s*else:\s*\r?\n\s*_buffered_move_direction\s*=\s*int\(dir\)' -and $extraMain -match 'if\s+keycode\s*==\s*KEY_R:(?:(?!\r?\nfunc\s)[\s\S])*?_buffered_move_direction\s*=\s*CharacterData\.Direction\.NONE(?:(?!\r?\nfunc\s)[\s\S])*?board\.restart\(\)'
	},
	@{
		Name = "EXTRA keeps input locked through enemy spawn fade"
		Pass = $extraBoard -match 'SPAWN_FADE_SECONDS\s*:=\s*0\.\d+' -and $extraBoard -match 'func\s+_apply_candidate_spawn\([^)]*\)(?:(?!\r?\nfunc\s)[\s\S])*?_spawn_fade_pending\s*=\s*true(?:(?!\r?\nfunc\s)[\s\S])*?play_spawn_fade\(SPAWN_FADE_SECONDS\)' -and $extraBoard -match 'func\s+_complete_turn_after_motion\(\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+_spawn_hit_pending\s+or\s+_spawn_fade_pending:\s*\r?\n\s*return' -and $extraBoard -match 'func\s+_finish_spawn_stage_if_ready\(\)(?:(?!\r?\nfunc\s)[\s\S])*?_finish_turn_presentation\(\)'
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
		Name = "classic selector reserves a footer for level confirmation"
		Pass = $classicLevelSelect -match 'BOTTOM_MARGIN\s*:=\s*88\.0' -and $classicLevelSelect -match 'func\s+draw_confirm_hint\(\)[\s\S]*"SPACE / ENTER\s+SELECT LEVEL"' -and $classicLevelSelect -match 'draw_area_arrows\(\)\s*\r?\n\s*draw_confirm_hint\(\)' -and $classicLevelSelect -notmatch '"LEVEL SELECT"'
	},
	@{
		Name = "title screen presents the directional main menu"
		Pass = $project -match 'run/main_scene="res://scenes/title_screen\.tscn"' -and $titleScreenScene -match 'res://scripts/title_screen\.gd' -and $campaign -match 'TITLE_SCREEN_SCENE_PATH\s*:=\s*"res://scenes/title_screen\.tscn"' -and $titleScreen -match 'class_name\s+DirTitleScreen' -and $titleScreen -match 'MENU_CELL_SIZE\s*:=\s*288\.0' -and $titleScreen -match 'MENU_CENTER_Y_RATIO\s*:=\s*0\.5' -and $titleScreen -match 'TITLE_CONTENT_OFFSET_Y\s*:=\s*-64\.0' -and $titleScreen -match 'OPTION_BOX_SIZE\s*:=\s*Vector2\(168\.0,\s*58\.0\)' -and $titleScreen -match '"START"[\s\S]*Vector2i\.UP' -and $titleScreen -match '"INFO"[\s\S]*Vector2i\.LEFT' -and $titleScreen -match '"CONFIG"[\s\S]*Vector2i\.RIGHT' -and $titleScreen -match '"EXTRA"[\s\S]*Vector2i\.DOWN' -and $titleScreen -match 'stored_direction\s*:=\s*Vector2i\.ZERO' -and $titleScreen -match 'func\s+activate_selection\(\)[\s\S]*play_config_action\(confirm_selection_after_action\)[\s\S]*func\s+confirm_selection_after_action\(\)[\s\S]*stored_direction\s*=\s*selected_direction' -and $titleScreen -match 'if\s+stored_direction\s*==\s*Vector2i\.ZERO:[\s\S]*return' -and $titleScreen -match 'VisualStyle\.PLAYER_BODY_RATIO' -and $titleScreen -match 'VisualStyle\.PLAYER_TRI_H_RATIO' -and $titleScreen -match 'VisualStyle\.STORED_VECTOR_OFFSET_RATIO' -and $titleScreen -match 'VisualStyle\.FACING_CHV_LEN_RATIO' -and $titleScreen -match 'func\s+chevron_points\(' -and $titleScreen -match 'OPTION_BOX_SIZE[\s\S]*draw_rect\(option_rect,\s*frame_color,\s*false,\s*frame_width\)' -and $titleScreen -match 'CONFIRM_HOLD_SECONDS[\s\S]*create_timer\(CONFIRM_HOLD_SECONDS\)' -and $titleScreen -match 'func\s+draw_confirm_hint\([\s\S]*"SPACE"[\s\S]*"ENTER"[\s\S]*"SELECT"' -and $titleScreen -notmatch 'func\s+draw_keycap\(' -and $titleScreen -match 'func\s+pulse_confirm_hint\([\s\S]*"confirm_hint_alpha"' -and $titleScreen -match 'palette\["direction_fill"\]' -and $titleScreen -match 'SceneTransition\.transition_to\(Campaign\.CLASSIC_LEVEL_SELECT_SCENE_PATH\)' -and $classicLevelSelect -match 'is_cancel_key\(event\)[\s\S]*Campaign\.TITLE_SCREEN_SCENE_PATH'
	},
	@{
		Name = "title info opens as the left branch"
		Pass = $titleScreen -match 'selected_direction\s*==\s*Vector2i\.LEFT[\s\S]*menu_mode\s*=\s*MenuMode\.INFO' -and $titleScreen -match 'func\s+draw_info_menu\(' -and $titleScreen -match 'Vector2\.LEFT\s*\*\s*INFO_PANEL_OFFSET_X' -and $titleScreen -match 'A PUZZLE ABOUT MOVING DIRECTIONS' -and $titleScreen -match 'BUILT WITH GODOT ENGINE' -and $titleScreen -match 'ADDITIONAL SOUNDS FROM PIXABAY' -and $titleScreen -match "USES KENNEY'S UI AND SOUND ASSETS" -and $titleScreen -notmatch 'draw_centered_text\([\s\S]{0,80}"INFO"' -and $titleScreen -match 'func\s+info_line_height\(line:\s*Dictionary\)\s*->\s*float' -and $titleScreen -match 'draw_config_option\(\s*"BACK"' -and $titleScreen -match 'handle_info_input[\s\S]*move_right[\s\S]*play_config_action\(leave_info\)'
	},
	@{
		Name = "title info BACK is laid out from the same stack as its text, not a fixed offset"
		Pass = $titleScreen -match 'const\s+INFO_LINE_GAP\s*:=\s*22\.0' -and $titleScreen -match 'const\s+INFO_BACK_GAP\s*:=\s*40\.0' -and $titleScreen -notmatch 'INFO_BACK_OFFSET_Y' -and $titleScreen -match 'func\s+info_lines\(\)\s*->\s*Array\[Dictionary\]' -and $titleScreen -match 'func\s+info_text_block_height\(lines:\s*Array\[Dictionary\]\)\s*->\s*float' -and $titleScreen -match 'func\s+info_back_center\(panel_center:\s*Vector2\)\s*->\s*Vector2' -and $titleScreen -match 'func\s+draw_info_menu\(menu_center:\s*Vector2\)\s*->\s*void:(?:(?!
?
func\s)[\s\S])*?var\s+lines\s*:=\s*info_lines\(\)(?:(?!
?
func\s)[\s\S])*?var\s+text_height\s*:=\s*info_text_block_height\(lines\)(?:(?!
?
func\s)[\s\S])*?draw_config_option\(\s*
?
\s*"BACK"' -and $titleScreen -match 'func\s+info_back_rect\(\)\s*->\s*Rect2:(?:(?!
?
func\s)[\s\S])*?var\s+center\s*:=\s*info_back_center\(panel_center\)'
	},
	@{
		Name = "title config orders screen grid audio reset and back"
		Pass = $titleScreen -match 'func\s+config_labels\(\)[\s\S]*"FULLSCREEN\s+%s"[\s\S]*"GRID\s+%s"[\s\S]*"AUDIO"[\s\S]*"RESET PROGRESS\?"[\s\S]*"RESET PROGRESS"[\s\S]*"BACK"' -and $titleScreen -match 'CONFIG_PANEL_OFFSET_X\s*:=\s*370\.0' -and $titleScreen -match 'func\s+config_list_center\(\)[\s\S]*center\.x\s*\+\s*CONFIG_PANEL_OFFSET_X,\s*center\.y' -and $titleScreen -match 'func\s+config_option_center\(index:\s*int\)[\s\S]*float\(index\)\s*-\s*float\(option_count\s*-\s*1\)\s*/\s*2\.0' -and $titleScreen -match 'posmod\(config_index\s*-\s*1,\s*option_count\)[\s\S]*play_turn_feedback\(\)[\s\S]*posmod\(config_index\s*\+\s*1,\s*option_count\)[\s\S]*play_turn_feedback\(\)' -and $titleScreen -match 'func\s+draw_audio_option\(' -and $titleScreen -match 'AUDIO_SLIDER_SIZE\.x\s*\*\s*fill_ratio' -and $titleScreen -match 'func\s+audio_slider_rect\(\)\s*->\s*Rect2:' -and $titleScreen -match 'audio_slider_rect\(\)\.grow\(8\.0\)\.has_point\(pos\)' -and $titleScreen -match 'func\s+set_audio_volume_from_mouse\([^)]*\)[\s\S]*Campaign\.set_audio_volume\(volume_percent\)[\s\S]*play_confirm_feedback\(\)' -and $titleScreen -match 'func\s+adjust_config\(delta:\s*int,\s*allow_destructive_action:\s*bool\)[\s\S]*if\s+not\s+allow_destructive_action:[\s\S]*if\s+not\s+reset_progress_armed:[\s\S]*begin_reset_progress_transition\(\)' -and $titleScreen -match 'func\s+cancel_reset_progress_confirmation\(\)[\s\S]*reset_progress_armed\s*=\s*false' -and $titleScreen -match 'RESET_FADE_SECONDS\s*:=\s*0\.15' -and $titleScreen -match 'RESET_BLACK_HOLD_SECONDS\s*:=\s*0\.30' -and $titleScreen -match 'func\s+begin_reset_progress_transition\(\)[\s\S]*activation_locked\s*=\s*true[\s\S]*Campaign\.reset_progress\(\)[\s\S]*create_timer\(RESET_BLACK_HOLD_SECONDS\)[\s\S]*activation_locked\s*=\s*false' -and $titleScreen -match 'func\s+draw_reset_progress_feedback\([^)]*\)[\s\S]*draw_rect\(viewport_rect,\s*overlay_color\)' -and $titleScreen -notmatch 'PROGRESS RESET' -and $titleScreen -match 'func\s+play_config_action\(' -and $titleScreen -match '"config_action_offset"[\s\S]*-CONFIG_ACTION_RETREAT[\s\S]*CONFIG_ACTION_HOLD_SECONDS[\s\S]*CONFIG_ACTION_EXTEND[\s\S]*CONFIG_ACTION_RETURN_SECONDS' -and $titleScreen -match 'is_cancel_key\(event\)[\s\S]*MenuMode\.CONFIG:[\s\S]*play_confirm_feedback\(\)[\s\S]*play_config_action\(leave_config\)[\s\S]*MenuMode\.INFO:[\s\S]*play_confirm_feedback\(\)[\s\S]*play_config_action\(leave_info\)' -and $titleScreen -match 'play_config_action\(leave_config\)' -and $titleScreen -match 'toggle_fullscreen\(\)' -and $titleScreen -match 'Campaign\.grid_lines_visible\s*=\s*not Campaign\.grid_lines_visible' -and $titleScreen -match 'Campaign\.set_audio_volume\(' -and $titleScreen -match 'func\s+leave_config\(' -and $campaign -match 'var\s+grid_lines_visible\s*:=\s*false' -and $campaign -match 'func\s+set_audio_volume\([^)]*\)[\s\S]*AudioServer\.set_bus_mute\([\s\S]*AudioServer\.set_bus_volume_db\(' -and $mainEntry -match 'set_grid_lines_visible\(Campaign\.grid_lines_visible\)'
	},
	@{
		Name = "classic selector uses shared navigation and confirmation sounds"
		Pass = $classicLevelSelect -match 'NAVIGATION_STREAM:\s*AudioStream[\s\S]*click2\.ogg' -and $classicLevelSelect -match 'NAVIGATION_VOLUME_DB\s*:=\s*-8\.0' -and $classicLevelSelect -match 'CONFIRM_STREAM:\s*AudioStream[\s\S]*switch34\.ogg' -and $classicLevelSelect -match 'CONFIRM_VOLUME_DB\s*:=\s*-4\.0' -and $classicLevelSelect -match 'func\s+move_selection\([^)]*\)[\s\S]*selected_index\s*=\s*target_index[\s\S]*play_navigation_feedback\(\)' -and $classicLevelSelect -match 'func\s+switch_area\([^)]*\)[\s\S]*current_area_index\s*=\s*target_area_index[\s\S]*play_navigation_feedback\(\)' -and $classicLevelSelect -match 'func\s+start_selected_level\(\)[\s\S]*Campaign\.begin_level\([\s\S]*play_confirm_feedback\(\)[\s\S]*SceneTransition\.transition_to' -and $classicLevelSelect -match 'func\s+play_navigation_feedback\(\)[\s\S]*navigation_player\.play\(\)' -and $classicLevelSelect -match 'func\s+play_confirm_feedback\(\)[\s\S]*confirm_player\.play\(\)'
	},
	@{
		Name = "classic selector preserves single-level launch mode"
		Pass = $project -match 'launch_mode="(?:campaign|single_level)"' -and $titleScreen -match 'Campaign\.is_single_level_mode\(\)[\s\S]*call_deferred\("open_single_level_test"\)' -and $titleScreen -match 'func\s+open_single_level_test\(\)[\s\S]*SceneTransition\.transition_to\("res://scenes/main\.tscn"\)'
	},
	@{
		Name = "classic selector uses restrained white teal and dim state colors"
		Pass = $classicLevelSelect -match 'COMPLETED_COLOR\s*:=\s*Color\("#49c9a5"\)' -and $classicLevelSelect -match 'LOCKED_ALPHA\s*:=\s*0\.28' -and $classicLevelSelect -match 'border_color\s*=\s*palette\["label"\]'
	},
	@{
		Name = "classic selector keeps large responsive level tiles"
		Pass = $classicLevelSelect -match 'MAX_SLOT_SIZE\s*:=\s*216\.0' -and $classicLevelSelect -match 'SIDE_MARGIN_RATIO\s*:=\s*0\.07' -and $classicLevelSelect -match 'func\s+slot_size_for\(viewport_size:\s*Vector2\)\s*->\s*float' -and $classicLevelSelect -match 'func\s+side_margin_for\(viewport_width:\s*float\)\s*->\s*float'
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
	},
	@{
		Name = "title screen mouse hit-testing types dictionary offsets explicitly"
		Pass = $titleScreen -match 'func\s+main_option_rect\(direction:\s*Vector2i\)\s*->\s*Rect2:\s*\r?\n\s*var\s+offset:\s*Vector2\s*=\s*MAIN_OPTION_OFFSETS\[direction\]' -and $titleScreen -notmatch 'var\s+center\s*:=\s*compute_menu_center\(\)\s*\+\s*MAIN_OPTION_OFFSETS' -and $titleScreen -match 'func\s+handle_mouse_motion\(pos:\s*Vector2\)' -and $titleScreen -match 'func\s+handle_mouse_click\(pos:\s*Vector2\)' -and $titleScreen -match 'MenuMode\.MAIN:[\s\S]*?main_option_rect\(direction\)\.has_point\(pos\)[\s\S]*?select_direction\(direction\)' -and $titleScreen -notmatch 'hovered_direction'
	},
	@{
		Name = "classic level selector supports mouse hover and click alongside keyboard nav"
		Pass = $classicLevelSelect -match 'func\s+handle_mouse_motion\(pos:\s*Vector2\)' -and $classicLevelSelect -match 'func\s+handle_mouse_click\(pos:\s*Vector2\)' -and $classicLevelSelect -match 'func\s+title_button_rect\(\)\s*->\s*Rect2' -and $classicLevelSelect -match 'SceneTransition\.transition_to\(Campaign\.TITLE_SCREEN_SCENE_PATH\)' -and $classicLevelSelect -match 'func\s+draw_hovered_level_name\(\)[\s\S]*hovered_index\s*==\s*-1\s*or\s+hovered_index\s*==\s*selected_index' -and $classicLevelSelect -match 'elif\s+index\s*==\s*hovered_index\s+and\s+unlocked:' -and $classicLevelSelect -match 'const\s+AREA_ARROW_SCALE\s*:=\s*2\.0' -and $classicLevelSelect -match 'TITLE_BUTTON_ICON_SIZE\s*:=\s*54\.0' -and $classicLevelSelect -match 'func\s+draw_title_button\(\)[\s\S]*text_ascent[\s\S]*text_descent[\s\S]*text_baseline_y'
	},
	@{
		Name = "EXTRA combo meter uses four staged undirected energy slots"
		Pass = $extraHud -match 'var\s+energy_slots:\s*Array\[DIRExtraEnergySlot\]' -and $extraHud -match 'for\s+_i\s+in\s+4:' -and $extraHud -match 'func\s+update_energy\((?:(?!\r?\nfunc\s)[\s\S])*?clampi\(quarter_units\s*-\s*i\s*\*\s*4,\s*0,\s*4\)(?:(?!\r?\nfunc\s)[\s\S])*?float\(slot_quarter_units\)\s*/\s*4\.0' -and $extraHud -match 'energy_slots\[i\]\.set_full_charge_ready\(quarter_units\s*>=\s*16\)' -and $extraEnergySlot -match 'class_name\s+DIRExtraEnergySlot' -and $extraEnergySlot -match 'var\s+lower_right_quarter\s*:=\s*PackedVector2Array\(\[\s*center,\s*center\s*\+\s*Vector2\(0\.0,\s*RADIUS\),\s*center\s*\+\s*Vector2\(RADIUS,\s*0\.0\),' -and $extraEnergySlot -match 'var\s+upper_left_quarter\s*:=\s*PackedVector2Array\(\[\s*center,\s*center\s*\+\s*Vector2\(0\.0,\s*-RADIUS\),\s*center\s*\+\s*Vector2\(-RADIUS,\s*0\.0\),' -and $extraEnergySlot -match 'OUTLINE_COLOR\s*:=\s*Color\("#4A5058"\)' -and $extraEnergySlot -match 'FILL_COLOR\s*:=\s*Color\("#2FD9A0"\)' -and $extraEnergySlot -match 'FULL_FILL_COLOR\s*:=\s*Color\("#3BE8B4"\)' -and $extraEnergySlot -match 'FULL_OUTLINE_COLOR\s*:=\s*Color\("#DFFFE9"\)' -and $extraEnergySlot -match 'FULL_OUTLINE_WIDTH\s*:=\s*1\.5' -and $extraEnergySlot -match 'if\s+full_charge_ready:\s*\r?\n\s*outline_color\s*=\s*FULL_OUTLINE_COLOR' -and $extraPlayer -notmatch 'func\s+_draw_bonus_step_arrows\(\)' -and $extraPlayer -notmatch 'const\s+STEP_FRAME_COLOR' -and $extraPlayer -match 'BONUS_STEP_FRAME_COLOR\s*:=\s*Color\("#2FD9A0"\)' -and $extraPlayer -match 'STATE_FRAME_OUTER_WIDTH\s*:=\s*7\.5' -and $extraPlayer -match 'STATE_FRAME_GAP_WIDTH\s*:=\s*2\.5' -and $extraPlayer -match 'elif\s+not\s+bonus_step_directions\.is_empty\(\):(?:(?!func\s)[\s\S])*?BONUS_STEP_FRAME_COLOR(?:(?!func\s)[\s\S])*?STATE_FRAME_GAP_COLOR(?:(?!func\s)[\s\S])*?draw_polygon\(points' -and $extraPlayer -match 'var\s+arrow_color:\s*Color\s*=\s*BONUS_STEP_FRAME_COLOR\s+if\s+is_bonus_step_direction\s+else\s+ACTIVE_COLOR' -and $extraPlayer -notmatch 'BONUS_STEP_OUTER_WIDTH' -and $extraCell -match 'func\s+set_bonus_step_highlight\(enabled:\s*bool\)' -and $extraCell -match 'BONUS_STEP_HIGHLIGHT_COLOR\s*:=\s*Color\(0\.1843137,\s*0\.8509804,\s*0\.6274510,\s*0\.12\)' -and $extraBoard -match '_set_bonus_step_cell_highlights\(bonus_directions\)' -and $extraBoard -match 'func\s+_set_bonus_step_cell_highlights\(directions:\s*Array\[int\]\)' -and $extraHud -match 'STEP_AVAILABLE_COLOR\s*:=\s*Color\("#2FD9A0"\)' -and $extraHud -match 'STEP_UNAVAILABLE_COLOR\s*:=\s*Color\("#4A5058"\)' -and $extraSlashEffect -match 'SLASH_CORE_COLOR\s*:=\s*Color\("#EAFFF0"\)' -and $extraSlashEffect -match 'SLASH_OUTER_COLOR\s*:=\s*Color\("#33CC4D"\)'
	},
	@{
		Name = "EXTRA HUD emphasizes score heat and survival turns without break labels"
		Pass = $extraHud -match 'score_label\.add_theme_font_size_override\("font_size",\s*56\)' -and $extraHud -match 'combo_label\.text\s*=\s*"HEAT"' -and $extraHud -match 'var\s+heat_meter:\s*Control' -and $extraHud -match 'var\s+turn_label:\s*Label' -and $extraHud -match 'turn_label\.text\s*=\s*"TURN 0"' -and $extraHud -match 'func\s+update_turns\(turn_count:\s*int\)\s*->\s*void:\s*\r?\n\s*turn_label\.text\s*=\s*"TURN %d"\s*%\s*turn_count' -and $extraMain -match 'hud\.update_turns\(board\.survival_turns\)' -and $extraHud -notmatch 'defeats_label|BREAK 0|func\s+update_defeats'
	},
	@{
		Name = "EXTRA HUD exposes title and help controls above the lowered score block"
		Pass = $extraHud -match 'nav_label\.text\s*=\s*"\[ESC\] TITLE\s+\[F1\] HELP\s+\[R\] RESTART"' -and $extraHud -match 'nav_label\.add_theme_font_size_override\("font_size",\s*22\)' -and $extraHud -match 'NAV_ROW_WIDTH\s*:=\s*520\.0' -and $extraHud -match 'SCORE_ROW_TOP\s*:=\s*108\.0' -and $extraHud -match 'func\s+toggle_help\(\)' -and $extraHud -match 'func\s+is_help_visible\(\)' -and $extraMain -match 'KEY_F1(?:(?!\r?\n\s*if\s)[\s\S])*?hud\.toggle_help\(\)' -and $extraMain -match 'func\s+_process\(delta:\s*float\)(?:(?!\r?\nfunc\s)[\s\S])*?if\s+hud\.is_help_visible\(\):\s*\r?\n\s*return'
	},
	@{
		Name = "EXTRA anchors turn and bot diagnostics at the lower left"
		Pass = $extraHud -match 'BOTTOM_INFO_MARGIN\s*:=\s*18\.0' -and $extraHud -match 'BOTTOM_INFO_ROW_HEIGHT\s*:=\s*28\.0' -and $extraHud -match 'turn_label\.position\s*=\s*Vector2\((?:(?!\)\s*\r?\n)[\s\S])*?viewport_size\.y\s*-\s*BOTTOM_INFO_MARGIN\s*-\s*BOTTOM_INFO_ROW_HEIGHT\s*\*\s*2\.0' -and $extraHud -match 'ai_status_label\.position\s*=\s*Vector2\((?:(?!\)\s*\r?\n)[\s\S])*?viewport_size\.y\s*-\s*BOTTOM_INFO_MARGIN\s*-\s*BOTTOM_INFO_ROW_HEIGHT'
	},
	@{
		Name = "EXTRA groups score heat and status rows inside one colored frame"
		Pass = $extraHud -match 'STATUS_GROUP_TOP\s*:=\s*94\.0' -and $extraHud -match 'STATUS_GROUP_HEIGHT\s*:=\s*322\.0' -and $extraHud -match 'status_group_style\.bg_color\s*=\s*Color\("#10151A"\)' -and $extraHud -match 'status_group_style\.border_color\s*=\s*Color\("#24755E"\)' -and $extraHud -match 'inventory_panel\s*=\s*MarginContainer\.new\(\)' -and $extraHud -notmatch 'inventory_panel\s*=\s*PanelContainer\.new\(\)' -and $extraHud -match 'status_group_panel\.position\s*=\s*Vector2\(SIDEBAR_MARGIN,\s*STATUS_GROUP_TOP\)'
	},
	@{
		Name = "EXTRA Game Over reports the session max combo streak"
		Pass = $extraScoreManager -match 'var\s+max_tier5_streak:\s*int\s*=\s*0' -and $extraScoreManager -match 'max_tier5_streak\s*=\s*maxi\(max_tier5_streak,\s*tier5_streak\)' -and $extraHud -notmatch 'gameover_max_combo|MAX HEAT' -and $extraHud -match '"MAX COMBO %d"\s*%\s*max_tier5_streak' -and $extraMain -match 'hud\.show_game_over\(final_score,\s*board\.score_manager\.max_tier5_streak\)'
	},
	@{
		Name = "EXTRA uses a left three-row status panel and an enlarged adaptive board"
		Pass = $extraHud -match 'status_vbox\.add_child\(energy_row\)(?:(?!func\s)[\s\S])*?status_vbox\.add_child\(direction_row\)(?:(?!func\s)[\s\S])*?status_vbox\.add_child\(action_row\)' -and $extraHud -match 'energy_label\.text\s*=\s*"ENERGY"' -and $extraHud -match 'direction_label\.text\s*=\s*"DIR"' -and $extraHud -match 'direction_row\.add_child\(direction_label\)(?:(?!func\s)[\s\S])*?direction_row\.add_child\(inventory_container\)' -and $extraHud -match 'action_row\.add_child\(ultimate_action_label\)' -and $extraHud -match 'action_row\.add_child\(dash_action_label\)' -and $extraHud -notmatch 'VSeparator\.new\(\)' -and $extraHud -match 'DIRECTION_ACTIVE_COLOR\s*:=\s*Color\("#7FE85A"\)' -and $extraHud -match 'DIRECTION_EXPIRING_COLOR\s*:=\s*Color\("#AAB58A"\)' -and $extraHud -match 'DIRECTION_EMPTY_COLOR\s*:=\s*Color\("#4A5058"\)' -and $extraHud -match 'DASH_AVAILABLE_COLOR\s*:=\s*Color\("#DFFFE9"\)' -and $extraPlayer -match 'ACTIVE_COLOR\s*:=\s*Color\("#7FE85A"\)' -and $extraPlayer -match 'EXPIRING_COLOR\s*:=\s*Color\("#AAB58A"\)' -and $extraCell -match 'attack_color\s*:=\s*Color\("#7FE85A"\)' -and $extraHud -match 'var\s+step_available:\s*bool\s*=\s*quarter_units\s*>=\s*bonus_step_cost\s+or\s+bonus_step_armed' -and $extraHud -match 'STEP_AVAILABLE_COLOR\s+if\s+step_available\s+else\s+STEP_UNAVAILABLE_COLOR' -and $extraHud -match 'var\s+ultimate_available:\s*bool\s*=\s*quarter_units\s*>=\s*16\s+or\s+ultimate_steps\s*>\s*0' -and $extraHud -match 'DASH_AVAILABLE_COLOR\s+if\s+ultimate_available\s+else\s+DIRECTION_EMPTY_COLOR' -and $extraHud -notmatch 'Space/X:\s*Wait' -and $extraBoard -match 'BOARD_PREFERRED_SCALE\s*:=\s*1\.25' -and $extraBoard -match 'scale\s*=\s*Vector2\.ONE\s*\*\s*board_scale' -and $extraBoard -match 'BOARD_SIDEBAR_WIDTH\s*\+\s*\(content_width\s*-\s*scaled_width\)\s*\*\s*0\.5'
	},
	@{
		Name = "EXTRA F4 evaluates X as a direction-planned rollout macro"
		Pass = $extraMain -match 'KEY_F4' -and $extraMain -match 'ComboBotMCTSScript\s*=\s*preload\("res://scripts/extra_mode/ComboBotMCTS\.gd"\)' -and $extraMain -match 'combo_bot_mcts\s*=\s*ComboBotMCTSScript\.new\(\)' -and $extraMain -match '_toggle_bot\(combo_bot_mcts\)' -and $extraMain -match 'active_bot\.choose_action\(board\)' -and $extraComboBotMcts -match 'class_name\s+DIRExtraComboBotMCTS\s*\r?\nextends\s+DIRExtraComboBot' -and $extraComboBotMcts -match 'ROLLOUT_DEPTH\s*:=\s*[1-9]\d*' -and $extraComboBotMcts -match 'func\s+_root_candidates\(' -and $extraComboBotMcts -match 'func\s+_policy_candidates\(' -and $extraComboBotMcts -match 'func\s+_tactical_value\(' -and $extraComboBotMcts -match 'candidates\.append\(\{"kind":\s*ACTION_DASH,\s*"dir":\s*direction\}\)' -and $extraComboBotMcts -match 'func\s+_apply_macro\((?:(?!\r?\nfunc\s)[\s\S])*?ACTION_DASH:(?:(?!\r?\nfunc\s)[\s\S])*?sim\.try_energy_bonus_step\(\)\s+and\s+sim\.try_move\(direction,\s*rng\)' -and $extraComboBotMcts -match '_planned_bonus_direction\s*=\s*chosen_direction'
	},
	@{
		Name = "EXTRA F5 runs a CMA-ES-tuned bot, mutually exclusive with F4"
		Pass = $extraMain -match 'KEY_F5' -and $extraMain -match 'ComboBotTunedScript\s*=\s*preload\("res://scripts/extra_mode/ComboBotTuned\.gd"\)' -and $extraMain -match 'active_bot\s*=\s*null\s+if\s+active_bot\s*==\s*bot\s+else\s+bot' -and $extraMain -notmatch 'var\s+ai_enabled' -and $extraComboBotTuned -match 'class_name\s+DIRExtraComboBotTuned' -and $extraComboBotTuned -match 'extends\s+DIRExtraComboBot' -and $extraComboBotTuned -match 'func\s+_init\(\)\s*->\s*void:' -and $extraComboBot -match 'var\s+COMBO_GATE_FOR_STEP\s*:=\s*4' -and $extraComboBot -match 'var\s+ULT_CONTINUATION_VALUE\s*:=\s*1800\.0' -and $extraHud -match 'func\s+update_ai_status\(label:\s*String\)'
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
