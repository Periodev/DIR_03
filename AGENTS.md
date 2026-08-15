# DIR Engineering Conventions

These constraints apply to all project GDScript unless a narrower instruction
explicitly overrides them.

## Dynamic Type Boundaries

- Treat values obtained through an untyped object, `Dictionary`, or `Variant`
  as dynamic values.
- Do not use `:=` when the right-hand side crosses one of those dynamic
  boundaries and Godot cannot prove the resulting type.
- Add an explicit type annotation and, where needed, an explicit conversion at
  the boundary.

```gdscript
var block_index: int = int(game_board.find_block_index_by_id(block_id))
var block_cell: Vector2i = block["cell"]
```

## Regression Checks

- A fix for a GDScript parser or type-inference failure must add or update a
  focused static regression check when the failure has a stable textual
  signature.
- A gameplay-rule or level-parser change must update both implementations when
  applicable: the Godot rule path (`game_board.gd` / `ascii_map.gd`) and the
  Python rule path (`solver/engine.py` / `solver/parser.py` / `solver/model.py`).
- Add or update paired regression coverage for those changes in the Godot
  verification tools and the Python `tests/` suite. Do not treat coverage in
  only one runtime as sufficient proof of rule parity.
- Static checks supplement the Godot parser; they do not replace it.
- After gameplay rules, parsers, or level collections change, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify_v11_static.ps1
godot --headless --path . --editor --quit
python -m unittest discover -s tests -v
```

- Treat a nonzero Godot exit or a parser error as a failed verification.
  Sandbox-only editor cache errors are environmental when Godot still exits
  successfully and script registration completes.

## Player Animation Checks

- Animation changes must run `res://tools/verify_player_animation.gd` in the
  normal graphics runtime. The Windows headless game runtime can crash inside
  Godot 4.6.1 before reporting script results.
- Give Godot a log path inside the workspace; the default `user://` log path
  may be unavailable in sandboxed runs.
- The animation check must cover input locking, free release, collision
  release, and Reset cancellation without changing command depth.
