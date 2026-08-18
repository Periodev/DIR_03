"""Regression cover for the EXTRA X-economy lab.

Two exploit vectors are pinned here, because the lab was wrong about the second
one until the lookahead bot found it:

* Energy. A flat-cost X whose kill refunds as much as it costs can be armed
  forever. `legacy` is that ruleset and must stay flagged.
* Combo. Score is `10 * combo` and combo only resets on a plain move, so any X
  that repositions at a fixed price lets a chain run forever and score grows
  quadratically. Only a price indexed to chain depth forces the chain to end.
"""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

import extra_x_lab as lab  # noqa: E402


def variant(name: str) -> lab.Variant:
    for candidate in lab.VARIANTS:
        if candidate.name == name:
            return candidate
    raise AssertionError("unknown variant %s" % name)


class EnergyAnalysisTest(unittest.TestCase):
    def test_legacy_rules_are_farmable(self):
        economy = lab.analyze(variant("legacy"))
        self.assertTrue(economy.farmable)
        self.assertEqual(economy.refund_max, 8)
        self.assertEqual(economy.net_first, 4)
        self.assertEqual(economy.frozen_cap, 0)  # the ladder never terminates

    def test_break_even_refund_is_still_farmable(self):
        # A refund that exactly matches the cost still lets X run forever.
        economy = lab.analyze(variant("half_charge"))
        self.assertEqual(economy.net_first, 0)
        self.assertTrue(economy.farmable)

    def test_shipped_rules_drain_on_every_x(self):
        economy = lab.analyze(variant("shipped"))
        self.assertFalse(economy.farmable)
        self.assertEqual(economy.refund_max, 0)
        self.assertEqual(economy.net_first, -4)
        self.assertEqual(economy.frozen_cap, lab.ENERGY_MAX // 4)

    def test_price_ladder_resets_are_accounted_for(self):
        # The earlier version of analyze() compared the refund against the last
        # rung only, which a player defeats by breaking the combo to reset the
        # price. The ladder walk has to start from the first rung.
        ladder = variant("ladder")
        self.assertEqual(ladder.cost(0), 4)
        self.assertEqual(ladder.cost(1), 8)
        self.assertEqual(ladder.cost(2), 12)
        self.assertEqual(ladder.cost(9), 12)  # last rung repeats
        self.assertFalse(lab.analyze(ladder).farmable)

    def test_move_only_cannot_refund(self):
        economy = lab.analyze(variant("move_only"))
        self.assertEqual(economy.refund_max, 0)
        self.assertFalse(economy.farmable)


class ComboFarmTest(unittest.TestCase):
    """The vector the energy analysis alone does not see.

    These two run the bot for real, so they are the slow tests in the suite.
    The turn cap matters: a runaway chain takes a few hundred turns to build,
    and a shorter run reports a small combo for a ruleset that farms perfectly
    well given room. Do not trim it to speed the suite up.
    """

    TURN_CAP = 600

    def _max_combo(self, name: str) -> int:
        # Across every benchmark seed, not one: whether a chain runs away is an
        # existence claim, and on some boards the bot dies before it can build
        # one. A single seed reported a combo of 5 for a ruleset that reaches
        # 52 given a board it survives on.
        return max(
            lab.farm(variant(name), turn_cap=self.TURN_CAP, seed=seed).max_combo
            for seed in lab.SEEDS
        )

    def test_an_uncapped_counter_runs_away(self):
        # X repositions without breaking combo, so with no ceiling on the
        # counter the chain never has to end and score grows quadratically.
        self.assertGreaterEqual(self._max_combo("sterile"), lab.COMBO_FARM_THRESHOLD)

    def test_the_combo_cap_is_never_exceeded(self):
        # Unlike the test above this asserts a rule, not a bot behaviour: the
        # counter cannot pass six however well or badly the bot plays.
        self.assertLessEqual(self._max_combo("shipped"), 6)


class EngineTest(unittest.TestCase):
    """Pins the model against hand-read behaviour from Board.gd."""

    def setUp(self):
        self.engine = lab.Engine(variant("shipped"))
        centre = (lab.ROWS // 2) * lab.COLS + lab.COLS // 2
        grid = [lab.LIVE] * lab.CELLS
        grid[centre + 1] = lab.DEAD  # dead cell to the right
        self.state = lab.State(
            grid=tuple(grid),
            pos=centre,
            queue=(lab.RIGHT,),
            energy=8,
            combo=3,
            cycle=0,
            cands=(),
            grace=0,
            armed=0,
            x_in_chain=0,
        )

    def test_normal_attack_consumes_ammo_and_charges(self):
        nxt, score = self.engine.apply(self.state, "D")
        self.assertEqual(nxt.combo, 4)
        self.assertNotIn(lab.RIGHT, nxt.queue)
        self.assertEqual(nxt.energy, 8 + 4)  # combo 4 grants one slot
        self.assertEqual(score, 50)  # combo 4 pays x5 on the 1/2/3/5/10/20 curve

    def test_x_attack_keeps_ammo_and_does_not_charge(self):
        armed, _ = self.engine.apply(self.state, "X")
        self.assertEqual(armed.energy, 8 - 4)
        nxt, score = self.engine.apply(armed, "D")
        self.assertEqual(nxt.combo, 4)
        self.assertIn(lab.RIGHT, nxt.queue)
        self.assertEqual(nxt.energy, 8 - 4)  # no refund
        self.assertEqual(score, 50)

    def test_the_combo_counter_stops_at_six(self):
        deep = self.state._replace(combo=6, queue=(lab.RIGHT,))
        nxt, score = self.engine.apply(deep, "D")
        self.assertEqual(nxt.combo, 6)
        self.assertEqual(score, 200)  # the x20 top rung, and no rung past it

    def test_the_multiplier_curve_matches_the_game(self):
        for combo, expected in enumerate(lab.COMBO_SCORE_MULTIPLIERS, start=1):
            deep = self.state._replace(combo=combo - 1, queue=(lab.RIGHT,))
            _, score = self.engine.apply(deep, "D")
            self.assertEqual(score, lab.BASE_KILL_SCORE * expected, "combo %d" % combo)

    def test_x_action_does_not_advance_the_spawn_clock(self):
        armed, _ = self.engine.apply(self.state, "X")
        nxt, _ = self.engine.apply(armed, "D")
        self.assertEqual(nxt.cycle, self.state.cycle)

    def test_normal_move_advances_the_spawn_clock_and_breaks_combo(self):
        nxt, _ = self.engine.apply(self.state, "W")
        self.assertEqual(nxt.combo, 0)
        self.assertEqual(nxt.cycle, 1)

    def test_x_move_banks_a_temporary_overflow_slot(self):
        full = self.state._replace(queue=(lab.UP, lab.DOWN, lab.LEFT))
        armed, _ = self.engine.apply(full, "X")
        nxt, _ = self.engine.apply(armed, "W")
        self.assertEqual(len(nxt.queue), lab.QUEUE_SIZE + 1)
        self.assertEqual(nxt.queue[0], lab.UP)  # oldest kept, not evicted
        trimmed, _ = self.engine.apply(nxt, "W")
        self.assertEqual(len(trimmed.queue), lab.QUEUE_SIZE)


if __name__ == "__main__":
    unittest.main()
