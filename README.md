# DIR

**A puzzle about moving directions.**

Direction is a resource you can create, store, transfer, and release.

DIR is a minimalist grid puzzle built with Godot. Push blocks to capture a
direction, install that direction into another block, and remotely release
installed directions to reshape the board. The campaign contains 36 handmade
levels across three areas, with optional branches and persistent progress.

The project also includes **EXTRA / DIR Arcade**, an earlier score-driven form
of the same direction-as-resource idea.

## Controls

### Campaign

| Input | Action |
| --- | --- |
| Arrow keys / WASD | Move, turn, or push |
| `X` | Install the held direction into the faced block |
| `Space` | Release the oldest installed direction |
| `Z` | Undo |
| `R` | Reset the level |
| `Esc` | Return to level select |

Use the arrow keys or WASD to navigate menus. `Space` and `Enter` confirm a
selection.

### EXTRA / DIR Arcade

| Input | Action |
| --- | --- |
| Arrow keys / WASD | Move or attack |
| `Space` | Wait |
| `X` | Spend energy on STEP |
| `Z` | Spend full energy on DASH |
| `F1` | Open help |
| `R` | Restart |
| `Esc` | Return to title |

## Running the Project

DIR requires **Godot 4.6.1**.

1. Open `project.godot` in Godot.
2. Run the project with `F5` or the editor's **Run Project** button.

Campaign progress is saved automatically through Godot's `user://` storage.
The CONFIG menu can reset that progress.

## Development

The campaign runtime is implemented in GDScript. A matching Python 3.12 rules
engine and shortest-path solver are included for level verification and
difficulty analysis.

```powershell
python -m unittest discover -s tests -v
python -m solver levels/level_test.txt
python -m solver levels/area_01.txt --collection
```

Additional regression checks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify_v11_static.ps1
godot --headless --path . --editor --quit
```

The standalone editors in `tools/level_editor.html` and
`tools/world_map_editor.html` can be opened directly in a browser.

## Repository Layout

```text
assets/   Visual and audio assets
docs/     Current specifications and archived design notes
levels/   ASCII level collections and BFS results
scenes/   Godot scenes
scripts/  Campaign, presentation, and EXTRA mode GDScript
solver/   Headless Python rules engine and search algorithms
tests/    Python regression tests
tools/    Editors, benchmarks, and Godot verification scripts
```

## Audio Source Note

Three third-party samples used by the packaged EXTRA mode are intentionally
excluded from this public Git repository. Two use the Pixabay Content License,
which does not permit standalone redistribution; the third has a CC0 Freesound
source but is kept local with the same asset group. Local development may
provide compatible licensed audio at these ignored paths, or update the
corresponding resource references:

```text
assets/audio/sfx/extra_attack/slash_666herohero_21834.mp3
assets/audio/sfx/extra_attack/sword_freesound_36274.wav
assets/audio/sfx/extra_attack/sword_slash_54427377.wav
```

Do not commit those local files to the public repository.

## Credits and Licensing

- Built with [Godot Engine](https://godotengine.org/).
- Input prompt and interface assets by [Kenney](https://kenney.nl/), released
  under CC0. See `assets/input_prompts/LICENSE.txt`.
- Additional integrated sound effects are credited in the in-game INFO screen.

A repository-wide source license has not yet been declared. Asset-specific
licenses continue to apply to their respective files.
