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
- Static checks supplement the Godot parser; they do not replace it.
- After GDScript changes, run both:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify_v11_static.ps1
& 'D:\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe' --headless --path 'D:\DIR_03' --editor --quit
```

- Treat a nonzero Godot exit or a parser error as a failed verification.
  Sandbox-only editor cache errors are environmental when Godot still exits
  successfully and script registration completes.
