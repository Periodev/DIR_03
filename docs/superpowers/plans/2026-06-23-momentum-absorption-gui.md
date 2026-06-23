# Momentum Absorption GUI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a minimal Godot 4 Sokoban-style GUI prototype that tests player momentum absorption after successful block pushes.

**Architecture:** Use a single Godot project with one main scene and one focused GDScript. The script owns the board state, input handling, push resolution, and debug rendering so the prototype stays small and easy to change.

**Tech Stack:** Godot 4.6.1, GDScript, Node2D, ColorRect, Label.

---

### Task 1: Project Scaffold

**Files:**
- Create: `project.godot`
- Create: `scenes/main.tscn`
- Create: `scripts/main.gd`

- [ ] **Step 1: Create the Godot project file**

Create `project.godot` with the app name, main scene, and default input mappings for arrow keys.

- [ ] **Step 2: Create the main scene**

Create `scenes/main.tscn` with a root `Node2D` using `scripts/main.gd`.

- [ ] **Step 3: Create the main script**

Create `scripts/main.gd` with board constants, player state, and rendering helpers.

- [ ] **Step 4: Run Godot headless parse check**

Run:

```powershell
& 'D:\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path D:\DIR_03 --quit
```

Expected: Godot exits without GDScript parse errors.

### Task 2: Grid Movement And Push Rules

**Files:**
- Modify: `scripts/main.gd`

- [ ] **Step 1: Add direction input handling**

Map arrow key actions to grid vectors.

- [ ] **Step 2: Add movement resolution**

If the target cell is empty, move the player without changing momentum.

- [ ] **Step 3: Add block push resolution**

If the target cell contains a block and the next cell is empty, move the block, move the player, and set `momentum_slot` to the push direction.

- [ ] **Step 4: Preserve momentum on failed moves**

If movement is blocked by a wall, board edge, or blocked block, leave all state unchanged.

### Task 3: GUI Feedback

**Files:**
- Modify: `scripts/main.gd`

- [ ] **Step 1: Draw the board**

Render floor, walls, blocks, and player with simple colored rectangles.

- [ ] **Step 2: Draw momentum state**

Show `Momentum: None` or `Momentum: Up/Down/Left/Right` in a label.

- [ ] **Step 3: Draw player momentum arrow**

When momentum exists, show a small arrow label above the player.

### Task 4: Verification And Commit

**Files:**
- Verify: `project.godot`
- Verify: `scenes/main.tscn`
- Verify: `scripts/main.gd`

- [ ] **Step 1: Run headless Godot verification**

Run:

```powershell
& 'D:\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path D:\DIR_03 --quit
```

Expected: no script parse errors.

- [ ] **Step 2: Check git status**

Run:

```powershell
git status --short --branch
```

Expected: only intended prototype files are changed.

- [ ] **Step 3: Commit**

Run:

```powershell
git add project.godot scenes/main.tscn scripts/main.gd docs/superpowers/specs/2026-06-23-momentum-absorption-gui-design.md docs/superpowers/plans/2026-06-23-momentum-absorption-gui.md
git commit -m "Add momentum absorption GUI prototype"
```
