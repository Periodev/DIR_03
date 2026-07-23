from __future__ import annotations

import unittest
from pathlib import Path

from solver.model import BlockKind
from solver.parser import LevelParseError, load_level, parse_level

ROOT = Path(__file__).resolve().parents[1]
KNOWN_LEVEL_PATH = ROOT / "tests" / "fixtures" / "known_31_step_level.txt"


class ParserTests(unittest.TestCase):
    def test_loads_fixed_regression_level(self) -> None:
        level = load_level(KNOWN_LEVEL_PATH)

        self.assertEqual((level.width, level.height), (4, 3))
        self.assertEqual(level.initial_state.player, (0, 1))
        self.assertEqual(
            tuple(block.position for block in level.initial_state.blocks),
            ((1, 0), (1, 1)),
        )
        self.assertEqual(level.goals, frozenset({(1, 0), (1, 2)}))
        self.assertTrue(level.has_fence((2, 0), (2, 1)))
        self.assertTrue(level.has_fence((3, 0), (3, 1)))

    def test_legacy_symbols_include_recovery_and_overlay_cells(self) -> None:
        level = parse_level(
            "\n".join(
                (
                    "r.+",
                    ".A*",
                )
            )
        )

        self.assertEqual(level.initial_state.player, (2, 0))
        self.assertEqual(level.goals, frozenset({(0, 0), (2, 0), (2, 1)}))
        self.assertEqual(level.block_specs[0].label, "R")
        self.assertEqual(level.block_specs[0].kind, BlockKind.RECOVERY)
        self.assertEqual(level.block_specs[1].kind, BlockKind.NORMAL)
        self.assertFalse(level.fences)

    def test_rejects_wrong_edge_dimensions(self) -> None:
        with self.assertRaisesRegex(LevelParseError, "horizontal_edges"):
            parse_level(
                """!cell-edge-v1
[cells]
@.
.*
[horizontal_edges]
.
[vertical_edges]
.
.
"""
            )

    def test_rejects_duplicate_block_labels_ignoring_case(self) -> None:
        with self.assertRaisesRegex(LevelParseError, "duplicated"):
            parse_level("@Aa")


if __name__ == "__main__":
    unittest.main()
