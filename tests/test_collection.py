from __future__ import annotations

import unittest
from pathlib import Path

from solver.collection import load_level_collection, parse_level_collection
from solver.parser import LevelParseError

ROOT = Path(__file__).resolve().parents[1]


class CollectionTests(unittest.TestCase):
    def test_loads_all_first_area_levels_in_order(self) -> None:
        entries = load_level_collection(ROOT / "levels" / "area_01.txt")

        self.assertEqual(len(entries), 12)
        self.assertEqual(entries[0].name, "推動")
        self.assertEqual(entries[1].name, "L 轉")
        self.assertEqual(entries[2].name, "轉移")
        self.assertEqual(entries[3].name, "拉回")
        self.assertEqual(entries[5].name, "隔欄轉移")
        self.assertEqual(entries[-2].name, "發條")
        self.assertEqual(entries[-1].name, "綜合")

    def test_loads_caterpillar_after_direct_collision(self) -> None:
        entries = load_level_collection(ROOT / "levels" / "area_02.txt")

        self.assertEqual(len(entries), 12)
        self.assertEqual(entries[0].name, "直接碰撞")
        self.assertEqual(entries[1].name, "毛蟲")
        self.assertEqual(entries[2].name, "對位碰撞")

    def test_loads_current_third_area_lock_sequence(self) -> None:
        entries = load_level_collection(ROOT / "levels" / "area_03.txt")

        self.assertEqual(len(entries), 10)
        self.assertEqual(entries[0].name, "解鎖")
        self.assertEqual(entries[-3].name, "三聯鎖")
        self.assertEqual(entries[-2].name, "長廊")
        self.assertEqual(entries[-1].name, "三相鎖")

    def test_wraps_level_parse_errors_with_the_level_name(self) -> None:
        with self.assertRaisesRegex(LevelParseError, "Broken"):
            parse_level_collection(
                """Broken
@?
"""
            )


if __name__ == "__main__":
    unittest.main()
