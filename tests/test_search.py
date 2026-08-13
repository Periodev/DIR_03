from __future__ import annotations

import unittest
from dataclasses import replace
from pathlib import Path

from solver.engine import run_commands
from solver.model import Direction
from solver.parser import load_level, parse_level
from solver.search import solve_astar, solve_bfs

ROOT = Path(__file__).resolve().parents[1]
KNOWN_LEVEL_PATH = ROOT / "tests" / "fixtures" / "known_31_step_level.txt"


class SearchTests(unittest.TestCase):
    def test_finds_one_press_push_solution(self) -> None:
        level = parse_level("@A*")

        result = solve_bfs(level)

        self.assertEqual(result.command_text, "R")
        self.assertEqual(result.depth, 1)

    def test_counts_turn_before_opposite_push(self) -> None:
        level = parse_level("*A@")
        level = replace(
            level,
            initial_state=replace(level.initial_state, facing=Direction.RIGHT),
        )

        result = solve_bfs(level)

        self.assertEqual(result.command_text, "LL")
        self.assertEqual(result.depth, 2)

    def test_solution_replay_reaches_fixed_regression_goals(self) -> None:
        level = load_level(KNOWN_LEVEL_PATH)

        result = solve_bfs(level)

        self.assertTrue(result.solved)
        self.assertLessEqual(result.depth, 31)
        self.assertTrue(level.is_solved(run_commands(level, result.commands or ())))

    def test_astar_finds_same_shortest_turning_solution(self) -> None:
        level = parse_level("*A@")
        level = replace(
            level,
            initial_state=replace(level.initial_state, facing=Direction.RIGHT),
        )

        result = solve_astar(level)

        self.assertEqual(result.command_text, "LL")
        self.assertEqual(result.depth, 2)

    def test_astar_respects_inclusive_upper_bound(self) -> None:
        level = parse_level("*A@")
        level = replace(
            level,
            initial_state=replace(level.initial_state, facing=Direction.RIGHT),
        )

        too_short = solve_astar(level, upper_bound=1)
        exact = solve_astar(level, upper_bound=2)

        self.assertFalse(too_short.solved)
        self.assertEqual(exact.command_text, "LL")

    def test_astar_solution_replays_after_normal_block_canonicalization(self) -> None:
        level = parse_level("@A.B**")

        result = solve_astar(level)

        self.assertTrue(result.solved)
        self.assertTrue(level.is_solved(run_commands(level, result.commands or ())))


if __name__ == "__main__":
    unittest.main()
