# Momentum Absorption GUI Prototype Design

Date: 2026-06-23
Project: DIR3
Engine: Godot 4.6.1

## Goal

Build a minimal Sokoban-style GUI prototype for testing the first DIR3 rule: successful pushing generates a direction momentum that the player absorbs.

## Confirmed Rules

- The player has one momentum slot.
- Moving into empty space does not generate or change momentum.
- Pushing air has no gameplay meaning.
- Successfully pushing a block generates momentum in the push direction.
- The player immediately absorbs that momentum.
- New successful pushes overwrite the existing momentum slot.
- Failed pushes do not change momentum.
- This prototype does not include momentum release, transfer, remote trigger, or DIV-style mechanics.

## Prototype Scene

- A small 2D grid is rendered on screen.
- The player is shown as a colored square.
- Pushable blocks are shown as colored squares.
- Walls are shown as solid dark cells.
- The current player momentum is shown as a text label and as an arrow marker above the player when present.

## Controls

- Arrow keys move the player.
- If the target cell is empty, the player moves and momentum stays unchanged.
- If the target cell contains a block and the cell beyond it is empty, the block moves, the player moves, and momentum becomes the movement direction.
- If the target cell is a wall, outside the board, or a blocked block, nothing moves and momentum stays unchanged.

## Success Criteria

- The project opens in Godot 4.6.1.
- The main scene runs without script errors.
- The player can move on the grid.
- The player can push blocks.
- Momentum changes only after a successful block push.
- Momentum remains unchanged after normal movement and failed pushes.
