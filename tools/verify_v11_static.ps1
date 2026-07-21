$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $root "scripts/main.gd"
$asciiMapPath = Join-Path $root "scripts/ascii_map.gd"
$levelPath = Join-Path $root "levels/level_01.txt"
$projectPath = Join-Path $root "project.godot"

$main = Get-Content -LiteralPath $mainPath -Raw
$asciiMap = Get-Content -LiteralPath $asciiMapPath -Raw
$level = Get-Content -LiteralPath $levelPath -Raw
$project = Get-Content -LiteralPath $projectPath -Raw

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
		Pass = $main -match 'print\("\[DIR3\] %s" % line\)'
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
		Name = "main.gd has reset_level operation"
		Pass = $main -match "func\s+reset_level\(\)"
	},
	@{
		Name = "main.gd handles reset_level input"
		Pass = $main -match "is_action_pressed\(\""reset_level\""\)"
	},
	@{
		Name = "main.gd does not draw block labels in board cells"
		Pass = $main -notmatch "add_centered_label\(object_layer,\s*cell,\s*block_label"
	},
	@{
		Name = "main.gd draws installed vector arrows in board cells"
		Pass = $main -match "add_centered_label\(object_layer,\s*cell,\s*momentum_arrow\(vector_name\)"
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
		Name = "ASCII map parser supports players on targets"
		Pass = $asciiMap -match '"\+"' -and $asciiMap -match 'player on target'
	},
	@{
		Name = "main.gd draws block target markers"
		Pass = $main -match "goal_cells\.has\(cell\)" -and $main -match "GOAL_MARKER_COLOR"
	},
	@{
		Name = "main.gd highlights blocks on target markers"
		Pass = $main -match "GOAL_BLOCK_BORDER_COLOR" -and $main -match "if goal_cells\.has\(cell\):\s*add_rect\(object_layer"
	},
	@{
		Name = "main.gd loads the independent level file"
		Pass = $main -match 'INITIAL_LEVEL_PATH\s*:=\s*"res://levels/level_01\.txt"' -and $main -match "FileAccess\.open\(INITIAL_LEVEL_PATH"
	},
	@{
		Name = "level file contains a player start"
		Pass = $level -match "@"
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
