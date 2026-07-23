from __future__ import annotations

import unittest
from dataclasses import replace
from pathlib import Path

from solver.engine import parse_commands, run_commands, step
from solver.model import BlockState, Command, Direction
from solver.parser import load_level, parse_level

ROOT = Path(__file__).resolve().parents[1]
KNOWN_LEVEL_PATH = ROOT / "tests" / "fixtures" / "known_31_step_level.txt"
KNOWN_SOLUTION = "RRUXTURRDRXDRRULLUXLLLUTTRXDDDT"


class EngineTests(unittest.TestCase):
    def test_first_press_only_turns_toward_an_adjacent_block(self) -> None:
        level = parse_level("*A@")
        initial = level.initial_state

        turned = step(level, initial, Command.LEFT)

        self.assertEqual(turned.player, initial.player)
        self.assertEqual(turned.blocks, initial.blocks)
        self.assertEqual(turned.facing, Direction.LEFT)

    def test_successful_push_keeps_player_still_and_overwrites_queue(self) -> None:
        level = parse_level("@A.*")
        initial = replace(level.initial_state, queue=Direction.UP)

        pushed = step(level, initial, Command.RIGHT)

        self.assertEqual(pushed.player, (0, 0))
        self.assertEqual(pushed.blocks[0].position, (2, 0))
        self.assertEqual(pushed.queue, Direction.RIGHT)

    def test_install_and_free_trigger_move_share_fifo_state(self) -> None:
        level = parse_level("@A.*")
        queued = replace(level.initial_state, queue=Direction.RIGHT)

        installed = step(level, queued, Command.INTERACT)
        triggered = step(level, installed, Command.TRIGGER)

        self.assertIsNone(installed.queue)
        self.assertEqual(installed.blocks[0].vector, Direction.RIGHT)
        self.assertEqual(installed.install_order, (1,))
        self.assertEqual(triggered.blocks[0], BlockState((2, 0)))
        self.assertEqual(triggered.install_order, ())

    def test_collision_trigger_anchors_carrier_and_moves_front_block(self) -> None:
        level = parse_level("@AB*")
        installed = replace(
            level.initial_state,
            blocks=(
                BlockState((1, 0), Direction.RIGHT),
                BlockState((2, 0)),
            ),
            install_order=(1,),
        )

        triggered = step(level, installed, Command.TRIGGER)

        self.assertEqual(triggered.blocks[0], BlockState((1, 0)))
        self.assertEqual(triggered.blocks[1], BlockState((3, 0)))
        self.assertFalse(triggered.install_order)

    def test_failed_trigger_keeps_vector_and_install_order(self) -> None:
        level = parse_level("@AB#")
        installed = replace(
            level.initial_state,
            blocks=(
                BlockState((1, 0), Direction.RIGHT),
                BlockState((2, 0)),
            ),
            install_order=(1,),
        )

        self.assertEqual(step(level, installed, Command.TRIGGER), installed)

    def test_empty_handed_player_retrieves_only_from_recovery_block(self) -> None:
        level = parse_level("@R.")
        installed = replace(
            level.initial_state,
            blocks=(BlockState((1, 0), Direction.DOWN),),
            install_order=(1,),
        )

        retrieved = step(level, installed, Command.INTERACT)

        self.assertEqual(retrieved.queue, Direction.DOWN)
        self.assertEqual(retrieved.blocks[0], BlockState((1, 0)))
        self.assertFalse(retrieved.install_order)

    def test_fence_blocks_movement_and_trigger(self) -> None:
        level = parse_level(
            """!cell-edge-v1
[cells]
@A
.*
[horizontal_edges]
.-
[vertical_edges]
|
.
"""
        )
        turned = step(level, level.initial_state, Command.RIGHT)
        blocked_push = step(level, turned, Command.RIGHT)
        self.assertEqual(blocked_push.blocks, level.initial_state.blocks)

        installed = replace(
            level.initial_state,
            blocks=(BlockState((1, 0), Direction.DOWN),),
            install_order=(1,),
        )
        self.assertEqual(step(level, installed, Command.TRIGGER), installed)

    def test_known_player_sequence_solves_fixed_regression_level(self) -> None:
        level = load_level(KNOWN_LEVEL_PATH)

        final_state = run_commands(level, KNOWN_SOLUTION)

        self.assertTrue(level.is_solved(final_state))
        self.assertEqual(len(parse_commands(KNOWN_SOLUTION)), 31)


if __name__ == "__main__":
    unittest.main()
