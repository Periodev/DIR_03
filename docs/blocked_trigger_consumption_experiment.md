# Blocked Trigger Consumption Decision

Status: **Accepted and implemented**

Originally tested on branch `codex/test-blocked-trigger-consumption`; now part
of the authoritative Godot and Python rules.

## Current rule

When the oldest installed vector cannot produce movement, `T` still consumes
that vector and removes its carrier from `install_order`. The board positions do
not change. This applies to:

- wall or board edge;
- fence;
- player occupying the target cell;
- collision target unable to move one cell.

An empty `install_order` remains a no-op.

## Adoption verification

- Python engine tests cover all four blocked cases.
- Godot runtime verification covers a carrier pointing into the board edge.
- All 33 campaign levels remain solvable.
- Every level keeps the same shortest command count and the same shortest
  command string recorded under the locked-vector rule.

## BFS comparison at adoption time

The following measurements cover the 33 campaign levels that existed when the
rule was evaluated. They are retained as historical decision evidence, not as
the current campaign level count.

| Area | Levels | Baseline discovered | Experimental discovered | Change |
|---|---:|---:|---:|---:|
| Area 1 | 12 | 26,612 | 27,067 | +455 (+1.71%) |
| Area 2 | 12 | 83,552 | 84,322 | +770 (+0.92%) |
| Area 3 | 9 | 3,084,991 | 3,091,026 | +6,035 (+0.20%) |
| Total | 33 | 3,195,155 | 3,202,415 | +7,260 (+0.23%) |

Largest absolute increases:

| Level | Baseline | Experimental | Change |
|---|---:|---:|---:|
| 3-9 長廊 | 2,057,410 | 2,060,094 | +2,684 |
| 3-3 翻牆 | 408,693 | 410,836 | +2,143 |
| 3-8 三聯鎖 | 604,234 | 605,087 | +853 |
| 2-6 碰撞 + 折返 | 2,281 | 2,487 | +206 |
| 2-10 折返反轉 + 十字接力 | 62,010 | 62,193 | +183 |

Largest relative increases occur in small teaching levels: 1-2 L 轉 and 2-3
對位碰撞 both rise 24.4%, while 1-4 拉回 rises 23.7%. These percentages
represent a few additional disposable-vector states, not longer solutions.

## Difficulty interpretation

The rule does not weaken the optimal solution structure of the current 33
levels. No shortest path uses blocked consumption, and no intended macro is
removed from a shortest solution.

Search complexity rises slightly because a blocked `T` changes state instead
of returning a self-loop. Human failure cost moves in the opposite direction:
a bad installation is no longer a permanent lock, so some reset-only traps
become recoverable. The current campaign therefore keeps its solution depth but
loses part of its irreversible-error pressure.

The reduced restart friction was accepted. Blocked release therefore remains a
state-changing action: positions stay fixed, while the oldest installed vector
is removed. Future rule changes must update both Godot and the Python solver.
