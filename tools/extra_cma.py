"""CMA-ES weight search over DIRExtraComboBot's hand-scored evaluation.

Why this exists
----------------
ComboBot.gd's decision function is a lookahead search, but every term inside
it (energy value, full-bar insurance, combo payout multipliers, the ULT
continuation bonus...) is a constant someone picked by feel, never tuned
against the others. A benchmark after the heat-decay retune showed X (STEP)
armed only 356 times against 402 Z (ULT) activations across six seeds, fewer
than Z despite costing a quarter of the energy -- and reading the code shows
a structural reason: `choose_action()` evaluates Z activation before checking
for an immediate kill, X is gated behind `combo >= 4` while Z has no such
gate, and Z's terminal score adds `continuation_count * 1800` while X's best
single kill tops out at `combo_payout(5) * 60 = 1200`.

This module asks "are these constants well-chosen", not "replace the whole
policy": it is a from-scratch, faithful Python port of the CURRENT
Board.gd / ScoreManager.gd rules (heat decay -1, spawn-hit Heat resets, the
1/2/2/4/6 energy table, X/Z costs) plus a parameterised port of ComboBot.gd's
own scoring terms, so CMA-ES can search the SAME weight vector the bot
already uses, seeded at the bot's current values.

Deliberately a separate model from extra_x_lab.py, which encodes historical
rule *variants* (including deliberately wrong/exploitable ones) for
farmability proofs and was not part of this pass -- merging the two would
conflate exploit-detection fixtures with a live-rules policy sandbox.

Requires: pip install cma

Usage:
    python tools/extra_cma.py bench                 # baseline vs a quick eval
    python tools/extra_cma.py optimize [generations] [seeds]
"""

from __future__ import annotations

import random
import sys
from dataclasses import asdict, dataclass, field, fields
from multiprocessing import Pool
from typing import Optional

# ---------------------------------------------------------------------------
# Rules -- faithful to scripts/extra_mode/Board.gd and ScoreManager.gd at the
# current heat-decay and shield-cools-heat rules.
# ---------------------------------------------------------------------------

COLS = 5
ROWS = 5
SPAWN_CYCLE_STEPS = 2
SPAWNS_PER_CYCLE = 2
HIGH_SCORE_SPAWN_THRESHOLD = 10_000
HIGH_SCORE_SPAWNS_PER_CYCLE = 3
OPENING_GRACE_TURNS = 1
ENERGY_MAX = 16
ENERGY_SLOT_COST = 4
ULT_DASH_COUNT = 4
QUEUE_MAX = 3
ULT_COMPLETION_OVERFLOW = 1

LIVE, DEAD = 0, 1
UP, DOWN, LEFT, RIGHT = 1, 2, 3, 4
DIRS = (UP, DOWN, LEFT, RIGHT)
DIR_STEP = {UP: (0, -1), DOWN: (0, 1), LEFT: (-1, 0), RIGHT: (1, 0)}

MAX_COMBO_TIER = 5
COMBO_SCORE_MULTIPLIERS = (1, 2, 5, 10, 20)
BASE_KILL_SCORE = 1
TIER5_STREAK_THRESHOLD = 5
TIER5_STREAK_BONUS_BASE = 200
TIER5_STREAK_BONUS_STEP = 100
TIER5_STREAK_BONUS_CAP = 1000
BOARD_CLEAR_BONUS = 2000
_ENERGY_GAIN = {1: 1, 2: 2, 3: 2, 4: 4}


def energy_gain_for_combo(combo: int) -> int:
    if combo in _ENERGY_GAIN:
        return _ENERGY_GAIN[combo]
    return 6 if combo >= 5 else 0


def combo_tier(combo: int) -> int:
    return max(1, min(combo, MAX_COMBO_TIER))


def combo_multiplier(combo: int) -> int:
    return COMBO_SCORE_MULTIPLIERS[combo_tier(combo) - 1]


class Board:
    """One EXTRA-mode run. Mutable, mirroring Board.gd's own mutable state."""

    def __init__(self, rng: random.Random) -> None:
        self.rng = rng
        self.grid = [[LIVE] * COLS for _ in range(ROWS)]
        self.player = (COLS // 2, ROWS // 2)
        self.queue: list[int] = []
        self.energy = 0
        self.combo = 0
        self.score = 0
        self.max_combo = 0
        self.defeats = 0
        self.cycle_counter = 0
        self.cycle_resolved = False
        self.candidates: list[tuple[int, int]] = []
        self.opening_grace = OPENING_GRACE_TURNS
        self.bonus_step_armed = False
        self.ult_remaining = 0
        self.ult_chain_started = False
        self.survival_turns = 0
        self.game_over = False
        self.tier5_streak = 0

    # -- small helpers, one-to-one with Board.gd -------------------------
    def in_bounds(self, p: tuple[int, int]) -> bool:
        x, y = p
        return 0 <= x < COLS and 0 <= y < ROWS

    def neighbour(self, p: tuple[int, int], d: int) -> Optional[tuple[int, int]]:
        dx, dy = DIR_STEP[d]
        np = (p[0] + dx, p[1] + dy)
        return np if self.in_bounds(np) else None

    def push(self, d: int) -> None:
        while len(self.queue) >= QUEUE_MAX:
            self.queue.pop(0)
        self.queue.append(d)

    def push_ult_completion(self, d: int) -> None:
        limit = QUEUE_MAX + ULT_COMPLETION_OVERFLOW
        while len(self.queue) >= limit:
            self.queue.pop(0)
        self.queue.append(d)

    def advance_combo(self) -> None:
        self.combo = min(self.combo + 1, MAX_COMBO_TIER)

    def decay_combo(self) -> None:
        self.combo = max(0, self.combo - 1)
        self.tier5_streak = 0

    def reset_combo(self) -> None:
        self.combo = 0
        self.tier5_streak = 0

    def on_kill(self) -> int:
        self.max_combo = max(self.max_combo, self.combo)
        points = BASE_KILL_SCORE * combo_multiplier(self.combo)
        self.score += points
        if self.combo == MAX_COMBO_TIER:
            self.tier5_streak += 1
            if self.tier5_streak % TIER5_STREAK_THRESHOLD == 0:
                block = self.tier5_streak // TIER5_STREAK_THRESHOLD
                streak_bonus = min(
                    TIER5_STREAK_BONUS_BASE + TIER5_STREAK_BONUS_STEP * (block - 1),
                    TIER5_STREAK_BONUS_CAP,
                )
                points += streak_bonus
                self.score += streak_bonus
        self.defeats += 1
        return points

    def will_spawn_hit(self, target: tuple[int, int]) -> bool:
        if self.opening_grace > 0:
            return False
        if self.cycle_resolved:
            return False
        if self.cycle_counter + 1 < SPAWN_CYCLE_STEPS:
            return False
        return target in self.candidates

    def charge_energy(self, combo: int) -> None:
        self.energy = min(self.energy + energy_gain_for_combo(combo), ENERGY_MAX)

    def has_attack_direction(self, d: int) -> bool:
        if self.ult_remaining > 0:
            return True
        return d in self.queue

    def consume_attack_direction(self, d: int) -> bool:
        if self.ult_remaining > 0:
            self.ult_remaining -= 1
            self.ult_chain_started = True
            return True
        if d not in self.queue:
            return False
        self.queue.remove(d)
        return True

    # -- actions ----------------------------------------------------------
    def try_move(self, d: int) -> bool:
        if self.ult_remaining > 0:
            return self._try_ultimate_dash(d)
        is_bonus = self.bonus_step_armed
        target = self.neighbour(self.player, d)
        if target is None:
            return False
        tx, ty = target
        if self.grid[ty][tx] == LIVE:
            return self._complete_live_move(d, target, is_bonus)
        if is_bonus:
            if not self.has_attack_direction(d):
                return False
        elif not self.consume_attack_direction(d):
            return False
        origin = self.player
        bonus_kill_active = is_bonus
        self._kill_flow(target, energy_sterile=bonus_kill_active)
        killed = self.grid[ty][tx] == LIVE
        if killed:
            self.player = target
        if is_bonus:
            self.bonus_step_armed = False
            return self._finalize_turn(freeze=True, count_turn=False)
        return self._finalize_turn(freeze=False, count_turn=True)

    def _complete_live_move(
        self, d: int, target: tuple[int, int], is_bonus: bool
    ) -> bool:
        self.player = target
        if is_bonus:
            self.push(d)
            self.bonus_step_armed = False
            return self._finalize_turn(freeze=True, count_turn=False)
        self.decay_combo()
        if not self.will_spawn_hit(target):
            self.push(d)
        return self._finalize_turn(freeze=False, count_turn=True)

    def try_wait(self) -> bool:
        if self.bonus_step_armed or self.ult_remaining > 0:
            return False
        self.decay_combo()
        return self._finalize_turn(freeze=False, count_turn=True)

    def try_energy_bonus_step(self) -> bool:
        if self.bonus_step_armed or self.ult_remaining > 0:
            return False
        if self.energy < ENERGY_SLOT_COST:
            return False
        self.energy -= ENERGY_SLOT_COST
        self.bonus_step_armed = True
        return True

    def try_energy_ultimate(self) -> bool:
        if self.bonus_step_armed or self.ult_remaining > 0:
            return False
        if self.energy < ENERGY_MAX:
            return False
        self.energy = 0
        self.ult_remaining = ULT_DASH_COUNT
        self.ult_chain_started = False
        return True

    def _ult_destination(self, d: int) -> tuple[int, int]:
        step = DIR_STEP[d]
        cursor = (self.player[0] + step[0], self.player[1] + step[1])
        destination = self.player
        while self.in_bounds(cursor):
            destination = cursor
            if self.grid[cursor[1]][cursor[0]] != LIVE:
                break
            cursor = (cursor[0] + step[0], cursor[1] + step[1])
        return destination

    def _try_ultimate_dash(self, d: int) -> bool:
        if self.ult_remaining <= 0:
            return False
        origin = self.player
        destination = self._ult_destination(d)
        if destination == origin:
            return False
        hits_dead = self.grid[destination[1]][destination[0]] == DEAD
        if not self.consume_attack_direction(d):
            return False
        freeze = self.ult_remaining > 0
        completes = self.ult_remaining == 0
        if hits_dead:
            self._kill_flow(destination, energy_sterile=True)
            if self.grid[destination[1]][destination[0]] == LIVE:
                self.player = destination
        else:
            self.player = destination
        if completes:
            self.push_ult_completion(d)
        else:
            self.push(d)
        if self.ult_chain_started and self.ult_remaining == 0:
            self.ult_chain_started = False
        return self._finalize_turn(freeze=freeze, count_turn=False)

    def _kill_flow(self, pos: tuple[int, int], energy_sterile: bool) -> None:
        x, y = pos
        self.grid[y][x] = LIVE
        self.advance_combo()
        self.on_kill()
        if not energy_sterile:
            self.charge_energy(self.combo)
        if not any(DEAD in row for row in self.grid):
            self.score += BOARD_CLEAR_BONUS

    # -- turn / spawn clock -------------------------------------------------
    def _finalize_turn(self, freeze: bool, count_turn: bool) -> bool:
        if count_turn:
            self.survival_turns += 1
        if not freeze:
            if self.opening_grace > 0:
                self.opening_grace -= 1
            else:
                self._advance_cycle()
        self._check_game_over()
        return True

    def _start_new_cycle(self) -> None:
        available = [
            (x, y) for y in range(ROWS) for x in range(COLS) if self.grid[y][x] == LIVE
        ]
        self.rng.shuffle(available)
        self.candidates = available[: self.spawns_per_cycle()]

    def spawns_per_cycle(self) -> int:
        return (
            HIGH_SCORE_SPAWNS_PER_CYCLE
            if self.score >= HIGH_SCORE_SPAWN_THRESHOLD
            else SPAWNS_PER_CYCLE
        )

    def _advance_cycle(self) -> None:
        self.cycle_counter += 1
        if self.cycle_resolved:
            if self.cycle_counter >= SPAWN_CYCLE_STEPS:
                self.cycle_counter = 0
                self.cycle_resolved = False
            return
        if self.cycle_counter == 1:
            self._start_new_cycle()
        elif self.cycle_counter >= SPAWN_CYCLE_STEPS:
            self.candidates = [
                p for p in self.candidates if self.grid[p[1]][p[0]] == LIVE
            ]
            for pos in self.candidates:
                self._apply_candidate_spawn(pos)
            self.candidates = []
            self.cycle_counter = 0
            self.cycle_resolved = False

    def _apply_candidate_spawn(self, pos: tuple[int, int]) -> None:
        x, y = pos
        if self.grid[y][x] != LIVE:
            return
        if pos == self.player:
            self._resolve_player_spawn_hit(pos)
            return
        self.grid[y][x] = DEAD

    def _resolve_player_spawn_hit(self, pos: tuple[int, int]) -> None:
        x, y = pos
        if self.energy >= ENERGY_SLOT_COST:
            self.energy -= ENERGY_SLOT_COST
            self.reset_combo()
            self.on_kill()
            return
        consumed = 0
        for _ in range(min(2, len(self.queue))):
            self.queue.pop(0)
            consumed += 1
        if consumed >= 2:
            self.reset_combo()
            self.on_kill()
        else:
            self.grid[y][x] = DEAD

    def _check_game_over(self) -> None:
        px, py = self.player
        if self.grid[py][px] != LIVE:
            self.game_over = True
            return
        for d in DIRS:
            n = self.neighbour(self.player, d)
            if n is not None and self.grid[n[1]][n[0]] == LIVE:
                return
        if self.energy >= ENERGY_MAX:
            return
        for d in DIRS:
            n = self.neighbour(self.player, d)
            if n is not None and self.grid[n[1]][n[0]] != LIVE and self.has_attack_direction(d):
                return
        self.game_over = True


# ---------------------------------------------------------------------------
# Policy -- a parameterised port of ComboBot.gd. Field names match the .gd
# constants; defaults are the values currently shipped, so an unmodified
# Weights() reproduces the live bot's behaviour.
# ---------------------------------------------------------------------------

ACTION_NONE, ACTION_MOVE, ACTION_DASH, ACTION_ULT, ACTION_WAIT = range(5)


@dataclass
class Weights:
    lookahead_discount: float = 0.72
    energy_unit_value: float = 2.0
    full_bar_insurance: float = 800.0
    target_distance_weight: float = 8.0
    approach_match_bonus: float = 40.0
    energy_shield_value: float = 160.0
    direction_shield_value: float = 95.0
    energy_shield_spend_penalty: float = 110.0
    direction_shield_spend_penalty: float = 80.0
    spawn_hit_death_penalty: float = 5000.0
    combo_kill_mult: float = 60.0
    combo_hold_mult: float = 30.0
    combo_break_mult: float = 45.0
    live_exit_value: float = 55.0
    attack_exit_value: float = 95.0
    useful_direction_value: float = 45.0
    unique_direction_value: float = 16.0
    center_distance_penalty: float = 12.0
    single_exit_penalty: float = 420.0
    ult_continuation_value: float = 1800.0
    combo_gate_for_step: int = 4

    def as_vector(self) -> list[float]:
        return [float(getattr(self, f.name)) for f in fields(self) if f.name != "combo_gate_for_step"]

    @classmethod
    def from_vector(cls, vec, gate: int = 4) -> "Weights":
        names = [f.name for f in fields(cls) if f.name != "combo_gate_for_step"]
        kwargs = dict(zip(names, vec))
        kwargs["combo_gate_for_step"] = gate
        return cls(**kwargs)


LOOKAHEAD_DEPTH = 3


class StructuredPolicy:
    """The as-shipped ComboBot.gd decision structure, ported faithfully.

    choose_action() is a fixed priority chain (ULT follow-through, STEP
    follow-through, THEN check whether to fire Z, THEN check for an attack,
    THEN check whether to arm X, THEN fall back to Z, THEN move/wait) with a
    hard `combo >= combo_gate_for_step` gate before X is even considered. CMA-
    ES can retune every number in this file, but it cannot touch that
    ordering or that gate -- they are control flow, not weights. See
    UnifiedPolicy for a version with neither.
    """

    def __init__(self, w: Weights, depth: int = LOOKAHEAD_DEPTH) -> None:
        self.w = w
        # Reachable during training runs, where a shallower search is a fair
        # trade for evaluating far more (weights, seed) pairs per second.
        # Final/held-out reporting should always use the full depth.
        self.depth = depth

    def choose_action(self, b: Board) -> tuple[int, int]:
        """Returns (action, direction)."""
        if b.ult_remaining > 0:
            d = self._best_ultimate_direction(b)
            return (ACTION_MOVE, d) if d else (ACTION_NONE, 0)

        attacks = self._attack_directions(b)
        if b.bonus_step_armed:
            d = self._best_normal_direction(b, preserve_combo=True)
            return (ACTION_MOVE, d) if d else (ACTION_NONE, 0)

        combo = b.combo
        energy = b.energy
        if energy >= ENERGY_MAX and self._should_activate_ultimate(b, combo):
            return (ACTION_ULT, 0)

        if attacks:
            d = self._best_attack_direction(b, attacks)
            return (ACTION_MOVE, d)

        if self._should_spend_step(b, combo, energy):
            return (ACTION_DASH, 0)

        if energy >= ENERGY_MAX and self._count_ultimate_targets(b) > 0:
            return (ACTION_ULT, 0)

        d = self._best_normal_direction(b, preserve_combo=False)
        if d:
            return (ACTION_MOVE, d)
        return (ACTION_WAIT, 0)

    # -- X gating -----------------------------------------------------------
    def _attack_directions(self, b: Board) -> list[int]:
        out = []
        for d in DIRS:
            t = b.neighbour(b.player, d)
            if t and b.grid[t[1]][t[0]] != LIVE and d in b.queue:
                out.append(d)
        return out

    def _has_step_continuation(self, b: Board) -> bool:
        for d in DIRS:
            t = b.neighbour(b.player, d)
            if t is None or b.grid[t[1]][t[0]] != LIVE:
                continue
            if self._future_attack_count(b, t, d) > 0:
                return True
        return False

    def _should_spend_step(self, b: Board, combo: int, energy: int) -> bool:
        if combo < self.w.combo_gate_for_step or energy < ENERGY_SLOT_COST:
            return False
        return self._has_step_continuation(b)

    def _future_attack_count(self, b: Board, from_pos: tuple[int, int], gained: int) -> int:
        q = list(b.queue)
        if len(q) >= QUEUE_MAX:
            q.pop(0)
        q.append(gained)
        count = 0
        for d in DIRS:
            t = b.neighbour(from_pos, d)
            if t and b.grid[t[1]][t[0]] != LIVE and d in q:
                count += 1
        return count

    def _best_attack_direction(self, b: Board, directions: list[int]) -> int:
        best_d, best_s = 0, -1e18
        for d in directions:
            s = self._direction_plan_score(b, d, preserve_combo=b.bonus_step_armed)
            if s > best_s:
                best_s, best_d = s, d
        return best_d

    def _best_normal_direction(self, b: Board, preserve_combo: bool) -> int:
        attacks = self._attack_directions(b)
        if attacks:
            return self._best_attack_direction(b, attacks)
        best_d, best_s = 0, -1e18
        for d in DIRS:
            t = b.neighbour(b.player, d)
            if t is None or b.grid[t[1]][t[0]] != LIVE:
                continue
            s = self._direction_plan_score(b, d, preserve_combo)
            if s > best_s:
                best_s, best_d = s, d
        return best_d

    # -- lookahead ------------------------------------------------------
    def _combo_payout(self, combo: int) -> float:
        return float(COMBO_SCORE_MULTIPLIERS[combo_tier(combo) - 1])

    def _combo_kill_value(self, combo: int) -> float:
        return self._combo_payout(combo) * self.w.combo_kill_mult

    def _combo_hold_value(self, combo: int) -> float:
        return self._combo_payout(combo) * self.w.combo_hold_mult

    def _combo_break_penalty(self, combo: int) -> float:
        decayed = max(0, combo - 1)
        return max(0.0, self._combo_payout(combo) - self._combo_payout(decayed)) * self.w.combo_break_mult

    def _apply_simulated_spawn_hit(self, b: Board, position, queue, energy, combo):
        if not b.will_spawn_hit(position):
            return energy, combo, 0
        if energy >= ENERGY_SLOT_COST:
            return energy - ENERGY_SLOT_COST, 0, 1
        if len(queue) >= 2:
            queue.pop(0)
            queue.pop(0)
            return energy, 0, 2
        return energy, combo, -1

    def _direction_plan_score(self, b: Board, direction: int, preserve_combo: bool) -> float:
        target = b.neighbour(b.player, direction)
        grid = [row[:] for row in b.grid]
        queue = list(b.queue)
        combo = b.combo
        energy = b.energy
        reward = 0.0
        tx, ty = target
        if grid[ty][tx] == LIVE:
            self._push_sim(queue, direction)
            if not preserve_combo:
                reward -= self._combo_break_penalty(combo)
                combo = max(0, combo - 1)
        else:
            if direction not in queue:
                return -1e18
            if not preserve_combo:
                queue.remove(direction)
                energy = self._charged_energy(energy, min(combo + 1, MAX_COMBO_TIER))
            grid[ty][tx] = LIVE
            combo = min(combo + 1, MAX_COMBO_TIER)
            reward += self._combo_kill_value(combo)

        if not preserve_combo:
            energy, combo, kind = self._apply_simulated_spawn_hit(
                b, target, queue, energy, combo
            )
            if kind == 1:
                reward -= self.w.energy_shield_spend_penalty
            elif kind == 2:
                reward -= self.w.direction_shield_spend_penalty
            elif kind == -1:
                reward -= self.w.spawn_hit_death_penalty
            if target in b.candidates and kind == 0:
                reward -= 260.0
        return reward + self.w.lookahead_discount * self._lookahead(
            b, target, grid, queue, combo, energy, self.depth - 1
        )

    def _charged_energy(self, energy: int, combo: int) -> int:
        return min(energy + energy_gain_for_combo(combo), ENERGY_MAX)

    def _push_sim(self, queue: list[int], d: int) -> None:
        if len(queue) >= QUEUE_MAX:
            queue.pop(0)
        queue.append(d)

    def _lookahead(self, b, pos, grid, queue, combo, energy, depth) -> float:
        if depth <= 0:
            return self._simulated_state_score(b, pos, grid, queue, combo, energy)
        best = -1e18
        for d in DIRS:
            t = b.neighbour(pos, d)
            if t is None:
                continue
            tx, ty = t
            ng = [row[:] for row in grid]
            nq = list(queue)
            ncombo = combo
            nenergy = energy
            reward = 0.0
            if ng[ty][tx] == LIVE:
                self._push_sim(nq, d)
                reward -= self._combo_break_penalty(ncombo)
                ncombo = max(0, ncombo - 1)
                nenergy, ncombo, kind = self._apply_simulated_spawn_hit(
                    b, t, nq, nenergy, ncombo
                )
                if kind == 1:
                    reward -= self.w.energy_shield_spend_penalty
                elif kind == 2:
                    reward -= self.w.direction_shield_spend_penalty
                elif kind == -1:
                    reward -= self.w.spawn_hit_death_penalty
            else:
                if d not in nq:
                    continue
                nq.remove(d)
                ng[ty][tx] = LIVE
                ncombo = min(ncombo + 1, MAX_COMBO_TIER)
                nenergy = self._charged_energy(nenergy, ncombo)
                reward += self._combo_kill_value(ncombo)
            branch = reward + self.w.lookahead_discount * self._lookahead(
                b, t, ng, nq, ncombo, nenergy, depth - 1
            )
            best = max(best, branch)
        if best == -1e18:
            return self._simulated_state_score(b, pos, grid, queue, combo, energy) - 3000.0
        return best

    def _simulated_state_score(self, b, pos, grid, queue, combo, energy) -> float:
        live_exits = attack_exits = useful = 0
        for d in DIRS:
            t = b.neighbour(pos, d)
            if t is None:
                continue
            tx, ty = t
            if grid[ty][tx] == LIVE:
                live_exits += 1
            elif d in queue:
                attack_exits += 1
                useful += 1
        legal_exits = live_exits + attack_exits
        has_energy_shield = energy >= ENERGY_SLOT_COST
        has_direction_shield = len(queue) >= 2
        if legal_exits == 0 and energy < ENERGY_MAX and not has_energy_shield and not has_direction_shield:
            return -6000.0
        cx, cy = (COLS - 1) / 2.0, (ROWS - 1) / 2.0
        center_distance = ((pos[0] - cx) ** 2 + (pos[1] - cy) ** 2) ** 0.5
        score = live_exits * self.w.live_exit_value + attack_exits * self.w.attack_exit_value
        score += useful * self.w.useful_direction_value
        score += len(set(queue)) * self.w.unique_direction_value
        score += self._combo_hold_value(combo)
        score -= center_distance * self.w.center_distance_penalty
        if legal_exits == 1:
            score -= self.w.single_exit_penalty
        score += energy * self.w.energy_unit_value
        if has_energy_shield:
            score += self.w.energy_shield_value
        if has_direction_shield:
            score += self.w.direction_shield_value
        if energy >= ENERGY_MAX:
            score += self.w.full_bar_insurance

        nearest = -1
        approach = 0
        for y in range(ROWS):
            for x in range(COLS):
                if grid[y][x] == LIVE:
                    continue
                dist = abs(x - pos[0]) + abs(y - pos[1])
                if nearest >= 0 and dist >= nearest:
                    continue
                nearest = dist
                if x != pos[0]:
                    approach = RIGHT if x > pos[0] else LEFT
                elif y != pos[1]:
                    approach = DOWN if y > pos[1] else UP
                else:
                    approach = 0
        if nearest >= 0:
            score -= nearest * self.w.target_distance_weight
            if approach and approach in queue:
                score += self.w.approach_match_bonus
        return score

    # -- Z gating ---------------------------------------------------------
    def _should_activate_ultimate(self, b: Board, combo: int) -> bool:
        if self._count_dead_cells(b) == 0:
            return False
        return self._best_ultimate_plan_score(b) > self._combo_hold_value(combo)

    def _count_dead_cells(self, b: Board) -> int:
        return sum(1 for row in b.grid for cell in row if cell != LIVE)

    def _count_ultimate_targets(self, b: Board) -> int:
        count = 0
        for d in DIRS:
            dest = self._ult_destination_on_grid(b, b.player, b.grid, d)
            if dest != b.player and b.grid[dest[1]][dest[0]] != LIVE:
                count += 1
        return count

    def _ult_destination_on_grid(self, b, pos, grid, d):
        step = DIR_STEP[d]
        cursor = (pos[0] + step[0], pos[1] + step[1])
        destination = pos
        while b.in_bounds(cursor):
            destination = cursor
            if grid[cursor[1]][cursor[0]] != LIVE:
                break
            cursor = (cursor[0] + step[0], cursor[1] + step[1])
        return destination

    def _apply_simulated_ultimate_dash(self, b, destination, direction, grid, queue, combo, remaining):
        score = 0.0
        dx, dy = destination
        if grid[dy][dx] != LIVE:
            grid[dy][dx] = LIVE
            score += self._combo_kill_value(min(combo + 1, MAX_COMBO_TIER))
        limit = QUEUE_MAX + (1 if remaining == 1 else 0)
        while len(queue) >= limit:
            queue.pop(0)
        queue.append(direction)
        if remaining == 1 and b.will_spawn_hit(destination):
            score -= 5000.0
        return score

    def _ultimate_terminal_score(self, b, pos, grid, queue, combo) -> float:
        continuation = 0
        for d in DIRS:
            t = b.neighbour(pos, d)
            if t and grid[t[1]][t[0]] != LIVE and d in queue:
                continuation += 1
        return self._simulated_state_score(b, pos, grid, queue, combo, 0) + continuation * self.w.ult_continuation_value

    def _ultimate_sequence_score(self, b, pos, grid, queue, combo, remaining) -> float:
        if remaining <= 0:
            return self._ultimate_terminal_score(b, pos, grid, queue, combo)
        best = -1e18
        for d in DIRS:
            dest = self._ult_destination_on_grid(b, pos, grid, d)
            if dest == pos:
                continue
            ng = [row[:] for row in grid]
            nq = list(queue)
            ncombo = combo
            score = self._apply_simulated_ultimate_dash(b, dest, d, ng, nq, ncombo, remaining)
            if ng[dest[1]][dest[0]] == LIVE and grid[dest[1]][dest[0]] != LIVE:
                ncombo = min(ncombo + 1, MAX_COMBO_TIER)
            score += self._ultimate_sequence_score(b, dest, ng, nq, ncombo, remaining - 1)
            best = max(best, score)
        if best == -1e18:
            return self._ultimate_terminal_score(b, pos, grid, queue, combo) - 3000.0
        return best

    def _best_ultimate_plan_score(self, b: Board) -> float:
        best = -1e18
        for d in DIRS:
            dest = self._ult_destination_on_grid(b, b.player, b.grid, d)
            if dest == b.player:
                continue
            grid = [row[:] for row in b.grid]
            queue = list(b.queue)
            combo = b.combo
            score = self._apply_simulated_ultimate_dash(b, dest, d, grid, queue, combo, ULT_DASH_COUNT)
            if grid[dest[1]][dest[0]] == LIVE and b.grid[dest[1]][dest[0]] != LIVE:
                combo = min(combo + 1, MAX_COMBO_TIER)
            score += self._ultimate_sequence_score(b, dest, grid, queue, combo, ULT_DASH_COUNT - 1)
            best = max(best, score)
        return best

    def _best_ultimate_direction(self, b: Board) -> int:
        best_d, best_s = 0, -1e18
        for d in DIRS:
            dest = self._ult_destination_on_grid(b, b.player, b.grid, d)
            if dest == b.player:
                continue
            grid = [row[:] for row in b.grid]
            queue = list(b.queue)
            combo = b.combo
            score = self._apply_simulated_ultimate_dash(
                b, dest, d, grid, queue, combo, b.ult_remaining
            )
            if grid[dest[1]][dest[0]] == LIVE and b.grid[dest[1]][dest[0]] != LIVE:
                combo = min(combo + 1, MAX_COMBO_TIER)
            score += self._ultimate_sequence_score(b, dest, grid, queue, combo, b.ult_remaining - 1)
            if score > best_s:
                best_s, best_d = score, d
        return best_d


class UnifiedPolicy(StructuredPolicy):
    """Same weighted lookahead machinery, no hardcoded priority or gate.

    StructuredPolicy decides "should I fire Z" and "should I arm X" with
    separate hand-written yes/no rules, evaluated in a fixed order, before a
    kill is even considered. Here every legal option this turn -- the best
    move/attack, arming X, firing Z, waiting -- is scored on the SAME scale
    by the SAME weighted value function and the highest score wins. The only
    things still hard-coded are legality (can't arm X below its energy cost,
    can't fire Z below a full bar, can't attack a direction you don't hold):
    those are the game's rules, not a judgement about which action is better.

    Arming X has no immediate payoff of its own -- the kill happens on the
    FOLLOWING turn -- so its score is the best _direction_plan_score reachable
    once armed (preserve_combo=True), discounted once more to reflect that
    delay. This puts it on the same footing as a normal move/attack's
    immediate lookahead value.

    Z's plan score already covers its whole four-dash chain in one number
    (multiple kills, plus the terminal continuation bonus), which is an
    inherently bigger quantity than one move's single-turn lookahead -- the
    original hand-written comparison had this same asymmetry
    (`_should_activate_ultimate` compares it against `_combo_hold_value`, not
    against four rounds of the move lookahead). Left as-is here rather than
    rebuilt into a true multi-ply comparison, which would need a genuine
    N-turn rollout of the move policy to be fully apples-to-apples.
    """

    def choose_action(self, b: Board) -> tuple[int, int]:
        if b.ult_remaining > 0:
            d = self._best_ultimate_direction(b)
            return (ACTION_MOVE, d) if d else (ACTION_NONE, 0)
        if b.bonus_step_armed:
            d = self._best_normal_direction(b, preserve_combo=True)
            return (ACTION_MOVE, d) if d else (ACTION_NONE, 0)

        candidates: list[tuple[float, int, int]] = []

        move_dir, move_score = self._best_move_overall(b)
        if move_dir:
            candidates.append((move_score, ACTION_MOVE, move_dir))

        if b.energy >= ENERGY_SLOT_COST:
            step_score = self._score_arm_step(b)
            candidates.append((step_score, ACTION_DASH, 0))

        if b.energy >= ENERGY_MAX:
            ult_score = self._best_ultimate_plan_score(b)
            candidates.append((ult_score, ACTION_ULT, 0))

        candidates.append((self._combo_hold_value(b.combo), ACTION_WAIT, 0))

        if not candidates:
            return (ACTION_WAIT, 0)
        _, action, direction = max(candidates, key=lambda c: c[0])
        return (action, direction)

    def _best_move_overall(self, b: Board) -> tuple[int, float]:
        """Best direction across BOTH live moves and attacks, one comparison.

        StructuredPolicy checks attacks first and only falls back to a plain
        move if none exist -- attacks always win regardless of score. Here
        they compete on the same value function, so a bad attack (walking
        into a scheduled spawn hit) can lose to a safe plain move.
        """
        best_d, best_s = 0, -1e18
        for d in DIRS:
            t = b.neighbour(b.player, d)
            if t is None:
                continue
            tx, ty = t
            if b.grid[ty][tx] == LIVE or d in b.queue:
                s = self._direction_plan_score(b, d, preserve_combo=False)
                if s > best_s:
                    best_s, best_d = s, d
        return best_d, best_s

    def _score_arm_step(self, b: Board) -> float:
        best = -1e18
        for d in DIRS:
            t = b.neighbour(b.player, d)
            if t is None:
                continue
            tx, ty = t
            if b.grid[ty][tx] != LIVE and d not in b.queue:
                continue
            s = self._direction_plan_score(b, d, preserve_combo=True)
            best = max(best, s)
        if best == -1e18:
            return -1e9  # arming now would have no legal follow-up
        return self.w.lookahead_discount * best


# ---------------------------------------------------------------------------
# Episode runner + fitness
# ---------------------------------------------------------------------------


@dataclass
class EpisodeResult:
    score: int
    turns: int
    defeats: int
    max_combo: int
    action_counts: dict


def run_episode(
    weights: Weights,
    seed: int,
    turn_cap: int = 700,
    decision_cap: int = 3000,
    policy_cls=StructuredPolicy,
    depth: int = LOOKAHEAD_DEPTH,
) -> EpisodeResult:
    rng = random.Random(seed)
    b = Board(rng)
    policy = policy_cls(weights, depth=depth)
    counts = {"move": 0, "x_arm": 0, "x_follow": 0, "z_arm": 0, "z_dash": 0, "wait": 0}
    decisions = 0
    while b.survival_turns < turn_cap and decisions < decision_cap and not b.game_over:
        action, direction = policy.choose_action(b)
        if action == ACTION_NONE:
            break
        decisions += 1
        if action == ACTION_MOVE:
            if b.bonus_step_armed:
                counts["x_follow"] += 1
            elif b.ult_remaining > 0:
                counts["z_dash"] += 1
            else:
                counts["move"] += 1
            b.try_move(direction)
        elif action == ACTION_DASH:
            counts["x_arm"] += 1
            b.try_energy_bonus_step()
        elif action == ACTION_ULT:
            counts["z_arm"] += 1
            b.try_energy_ultimate()
        elif action == ACTION_WAIT:
            counts["wait"] += 1
            b.try_wait()
        if b.game_over:
            break
    return EpisodeResult(b.score, b.survival_turns, b.defeats, b.max_combo, counts)


BENCH_SEEDS = (20260811, 20260812, 20260813, 20260814, 20260815, 20260816)


def evaluate(
    weights: Weights,
    seeds=BENCH_SEEDS,
    turn_cap: int = 700,
    policy_cls=StructuredPolicy,
    depth: int = LOOKAHEAD_DEPTH,
) -> list[EpisodeResult]:
    return [
        run_episode(weights, s, turn_cap=turn_cap, policy_cls=policy_cls, depth=depth)
        for s in seeds
    ]


# ---------------------------------------------------------------------------
# Parallel evaluation. Each (candidate weights, seed) pair is an independent
# episode, so a generation's whole population x seed batch is an embarrassingly
# parallel workload -- this is the single biggest lever for iteration speed,
# since the search itself is pure CPU work with no shared state between runs.
# The worker must be a picklable module-level function (Windows multiprocessing
# uses spawn, not fork: closures and instance methods cannot cross the process
# boundary), and its arguments must be plain data, not Weights/Policy objects.
# ---------------------------------------------------------------------------


def _worker_episode(args) -> int:
    weights_dict, seed, turn_cap, depth, policy_name = args
    weights = Weights(**weights_dict)
    policy_cls = UnifiedPolicy if policy_name == "unified" else StructuredPolicy
    return run_episode(weights, seed, turn_cap=turn_cap, policy_cls=policy_cls, depth=depth).score


def summarize(label: str, results: list[EpisodeResult]) -> None:
    scores = [r.score for r in results]
    turns = [r.turns for r in results]
    totals = {k: sum(r.action_counts[k] for r in results) for k in results[0].action_counts}
    total_decisions = sum(totals.values())
    print(f"{label}: mean_score={sum(scores)/len(scores):8.1f}  mean_turns={sum(turns)/len(turns):7.1f}")
    # x_follow (the one move that consumes an armed STEP) was computed but
    # never shown here, while Z's equivalent follow-through (z_dash, up to
    # four dashes per activation) always was -- comparing "X-arm" against
    # "Z-arm + Z-dash" silently compared an activation count against a full
    # footprint. Both activation counts and full footprints (arm + every
    # follow-through step) are shown now so the two are never conflated.
    x_footprint = totals["x_arm"] + totals["x_follow"]
    z_footprint = totals["z_arm"] + totals["z_dash"]
    print(
        "  actions: move=%d(%.1f%%) X-arm=%d(%.1f%%) X-follow=%d(%.1f%%) "
        "Z-arm=%d(%.1f%%) Z-dash=%d(%.1f%%) wait=%d"
        % (
            totals["move"], totals["move"] / total_decisions * 100,
            totals["x_arm"], totals["x_arm"] / total_decisions * 100,
            totals["x_follow"], totals["x_follow"] / total_decisions * 100,
            totals["z_arm"], totals["z_arm"] / total_decisions * 100,
            totals["z_dash"], totals["z_dash"] / total_decisions * 100,
            totals["wait"],
        )
    )
    print(
        "  footprint (arm + every follow-through step): X=%d(%.1f%%)  Z=%d(%.1f%%)"
        % (
            x_footprint, x_footprint / total_decisions * 100,
            z_footprint, z_footprint / total_decisions * 100,
        )
    )
    x_energy = totals["x_arm"] * ENERGY_SLOT_COST
    z_energy = totals["z_arm"] * ENERGY_MAX
    if x_energy + z_energy:
        print(
            "  energy via X=%.1f%%  energy via Z=%.1f%%"
            % (x_energy / (x_energy + z_energy) * 100, z_energy / (x_energy + z_energy) * 100)
        )


def optimize(
    generations: int = 20,
    train_seeds_per_gen: int = 10,
    turn_cap: int = 200,
    train_depth: int = 2,
    popsize: Optional[int] = None,
    rng_seed: int = 1,
    policy_cls=UnifiedPolicy,
    workers: Optional[int] = None,
):
    # Fresh random training seeds every generation (not a fixed pool) so CMA-ES
    # cannot simply memorise which weights happen to suit a handful of specific
    # boards -- an earlier run trained and reported against the SAME six fixed
    # seeds and looked like it had roughly doubled the score, but on held-out
    # seeds the "optimised" weights scored HALF the baseline. That was pure
    # overfitting to those six seeds, not a real improvement.
    #
    # Training runs shallower (train_depth) and shorter (turn_cap) than final
    # reporting, and the whole generation's population x seed batch is
    # evaluated as one flat parallel map -- an episode doesn't care which
    # candidate or which seed it's running, so there's no reason to run them
    # one at a time on one core.
    import cma

    train_rng = random.Random(rng_seed)
    baseline = Weights()
    x0 = baseline.as_vector()
    sigma0 = 0.3
    scales = [max(abs(v), 1.0) for v in x0]
    x0_scaled = [v / s for v, s in zip(x0, scales)]
    # Tied to rng_seed (not left to system entropy) so a specific restart's
    # result is exactly reproducible by passing the same rng_seed again.
    opts = {"maxiter": generations, "verb_disp": 1, "seed": rng_seed}
    if popsize:
        opts["popsize"] = popsize
    es = cma.CMAEvolutionStrategy(x0_scaled, sigma0, opts)
    policy_name = "unified" if policy_cls is UnifiedPolicy else "structured"

    with Pool(workers) as pool:
        while not es.stop():
            solutions = es.ask()
            gen_seeds = [train_rng.randrange(1, 2**31) for _ in range(train_seeds_per_gen)]
            tasks = []
            for vec in solutions:
                scaled = [v * s for v, s in zip(vec, scales)]
                w = Weights.from_vector(scaled, gate=baseline.combo_gate_for_step)
                weights_dict = asdict(w)
                for s in gen_seeds:
                    tasks.append((weights_dict, s, turn_cap, train_depth, policy_name))
            scores = pool.map(_worker_episode, tasks)
            n = len(gen_seeds)
            fitnesses = [
                -sum(scores[i * n:(i + 1) * n]) / n for i in range(len(solutions))
            ]
            es.tell(solutions, fitnesses)
            es.disp()

    best_scaled = es.result.xbest
    best_vec = [v * s for v, s in zip(best_scaled, scales)]
    best_weights = Weights.from_vector(best_vec, gate=baseline.combo_gate_for_step)
    return baseline, best_weights


def main(argv: list[str]) -> int:
    mode = argv[1] if len(argv) > 1 else "bench"
    if mode == "bench":
        baseline = Weights()
        results = evaluate(baseline)
        summarize("baseline (current bot constants)", results)
        return 0
    if mode == "optimize":
        generations = int(argv[2]) if len(argv) > 2 else 20
        baseline, best = optimize(generations=generations, policy_cls=UnifiedPolicy)
        # A large, fixed validation pool disjoint from the randomly-sampled
        # training seeds -- this is the only number that should be trusted.
        holdout = [random.Random(999).randrange(1, 2**31) for _ in range(24)]
        print()
        print("=== held-out validation (24 seeds, never used in training) ===")
        # Three-way split so the two effects don't get conflated: how much
        # comes from dropping the hand-written priority/gate structure alone
        # (unchanged weights), and how much comes from additionally tuning
        # the weights on top of that.
        summarize(
            "shipped   (structure+gate, current weights)",
            evaluate(baseline, seeds=holdout, turn_cap=700, policy_cls=StructuredPolicy),
        )
        summarize(
            "unified   (no structure/gate, current weights)",
            evaluate(baseline, seeds=holdout, turn_cap=700, policy_cls=UnifiedPolicy),
        )
        summarize(
            "unified+cma (no structure/gate, tuned weights)",
            evaluate(best, seeds=holdout, turn_cap=700, policy_cls=UnifiedPolicy),
        )
        print()
        print("weight deltas (name: baseline -> optimized):")
        for f in fields(Weights):
            if f.name == "combo_gate_for_step":
                continue
            bv = getattr(baseline, f.name)
            ov = getattr(best, f.name)
            if abs(ov - bv) > 1e-6:
                print(f"  {f.name}: {bv:.2f} -> {ov:.2f}")
        return 0
    print(f"Unknown mode: {mode}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
