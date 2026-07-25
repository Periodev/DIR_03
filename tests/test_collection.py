from __future__ import annotations

import unittest
from pathlib import Path

from solver.collection import load_level_collection, parse_level_collection
from solver.parser import LevelParseError

ROOT = Path(__file__).resolve().parents[1]


class CollectionTests(unittest.TestCase):
    def test_loads_all_first_area_levels_in_order(self) -> None:
        entries = load_level_collection(ROOT / "levels" / "area_01.txt")

        self.assertEqual(len(entries), 11)
        self.assertEqual(entries[0].name, "L 轉")
        self.assertEqual(entries[1].name, "轉移")
        self.assertEqual(entries[2].name, "拉回")
        self.assertEqual(entries[4].name, "隔欄轉移")
        self.assertEqual(entries[-2].name, "發條")
        self.assertEqual(entries[-1].name, "綜合")

    def test_loads_caterpillar_after_direct_collision(self) -> None:
        entries = load_level_collection(ROOT / "levels" / "area_02.txt")

        self.assertEqual(len(entries), 11)
        self.assertEqual(entries[0].name, "直接碰撞")
        self.assertEqual(entries[1].name, "毛蟲")
        self.assertEqual(entries[2].name, "對位碰撞")

    def test_loads_ship_lock_at_end_of_third_area(self) -> None:
        entries = load_level_collection(ROOT / "levels" / "area_03.txt")

        self.assertEqual(len(entries), 6)
        self.assertEqual(entries[0].name, "解鎖")
        self.assertEqual(entries[-2].name, "雙重鎖")
        self.assertEqual(entries[-1].name, "船閘")

    def test_wraps_level_parse_errors_with_the_level_name(self) -> None:
        with self.assertRaisesRegex(LevelParseError, "Broken"):
            parse_level_collection(
                """Broken
@?
"""
            )


if __name__ == "__main__":
    unittest.main()
