"""Multi-restart driver for extra_cma.optimize(), to check whether a single
CMA-ES run's result is a stable finding or a lucky draw.

The 10-generation timing test found weights beating the shipped bot on held-
out seeds (12,205 vs 6,583), but that was one run with one random seed --
not evidence of anything reproducible on its own. This runs several
independent restarts (distinct CMA-ES + training seeds) at a shared
generation count and reports the spread on the SAME held-out validation set,
so a good result can be told apart from noise.

Usage: python tools/extra_cma_restarts.py [generations] [n_restarts]
"""

from __future__ import annotations

import statistics
import sys
import time

sys.path.insert(0, "tools")
import extra_cma as m  # noqa: E402


def main(argv: list[str]) -> int:
    generations = int(argv[1]) if len(argv) > 1 else 100
    n_restarts = int(argv[2]) if len(argv) > 2 else 5

    holdout = [__import__("random").Random(999).randrange(1, 2**31) for _ in range(24)]
    shipped_results = m.evaluate(
        m.Weights(), seeds=holdout, turn_cap=700, policy_cls=m.StructuredPolicy
    )
    shipped_mean = sum(r.score for r in shipped_results) / len(shipped_results)
    print(f"shipped baseline (structure+gate): mean_score={shipped_mean:.1f}")
    print(f"running {n_restarts} independent restarts x {generations} generations each")
    print()

    run_scores = []
    run_x_shares = []
    t_start = time.time()
    for i in range(1, n_restarts + 1):
        t0 = time.time()
        baseline, best = m.optimize(generations=generations, rng_seed=i)
        results = m.evaluate(best, seeds=holdout, turn_cap=700, policy_cls=m.UnifiedPolicy)
        mean_score = sum(r.score for r in results) / len(results)
        totals = {k: sum(r.action_counts[k] for r in results) for k in results[0].action_counts}
        x_energy = totals["x_arm"] * m.ENERGY_SLOT_COST
        z_energy = totals["z_arm"] * m.ENERGY_MAX
        x_share = x_energy / (x_energy + z_energy) * 100 if (x_energy + z_energy) else 0.0
        mean_turns = sum(r.turns for r in results) / len(results)
        elapsed = time.time() - t0
        run_scores.append(mean_score)
        run_x_shares.append(x_share)
        print(
            f"restart {i} (seed={i}, {elapsed:5.1f}s): "
            f"mean_score={mean_score:8.1f}  mean_turns={mean_turns:6.1f}  "
            f"energy_via_X={x_share:5.1f}%"
        )

    total_elapsed = time.time() - t_start
    print()
    print(f"total elapsed: {total_elapsed:.1f}s")
    print()
    print("=== stability across restarts ===")
    print(
        f"score:  mean={statistics.mean(run_scores):8.1f}  "
        f"median={statistics.median(run_scores):8.1f}  "
        f"stdev={statistics.stdev(run_scores) if len(run_scores) > 1 else 0:7.1f}  "
        f"min={min(run_scores):8.1f}  max={max(run_scores):8.1f}"
    )
    print(
        f"X share: mean={statistics.mean(run_x_shares):5.1f}%  "
        f"stdev={statistics.stdev(run_x_shares) if len(run_x_shares) > 1 else 0:5.1f}%  "
        f"min={min(run_x_shares):5.1f}%  max={max(run_x_shares):5.1f}%"
    )
    beats_shipped = sum(1 for s in run_scores if s > shipped_mean)
    print(f"restarts beating shipped baseline ({shipped_mean:.0f}): {beats_shipped}/{n_restarts}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
