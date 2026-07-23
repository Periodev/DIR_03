from __future__ import annotations

import unittest
from pathlib import Path

from solver.engine import run_commands
from solver.parser import load_level, parse_level
from solver.search import solve_bfs

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

        result = solve_bfs(level)

        self.assertEqual(result.command_text, "LL")
        self.assertEqual(result.depth, 2)

    def test_solution_replay_reaches_fixed_regression_goals(self) -> None:
        level = load_level(KNOWN_LEVEL_PATH)

        result = solve_bfs(level)

        self.assertTrue(result.solved)
        self.assertLessEqual(result.depth, 31)
        self.assertTrue(level.is_solved(run_commands(level, result.commands or ())))


if __name__ == "__main__":
    unittest.main()
