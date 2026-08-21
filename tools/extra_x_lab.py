"""Headless lab for the EXTRA-mode X (STEP) economy.

Why this exists
---------------
Judging an X rule change by playing the Godot build is slow and cannot prove a
negative. This module re-implements the EXTRA turn/energy rules as a small
deterministic state machine so that thousands of action sequences can be
searched per second, and asks one question per rule variant:

    Is there a repeatable loop that uses X, ends with no less energy than it
    started with, and gains score?

If such a loop exists the player can press X forever, so the variant is
farmable and fails. If none exists the variant converges: every X must
eventually be paid for by a turn that advances the spawn clock, which is the
only thing that puts the player at risk.

Faithfulness to the Godot rules
-------------------------------
`_apply_move`, `_advance_cycle` and the charge table mirror
`scripts/extra_mode/Board.gd`. `tests/test_extra_x_lab.py` pins the shipped
variant against hand-computed traces taken from that file, and the lab is
deliberately *more* permissive than the real game in two ways, both of which
favour a would-be exploiter:

* Spawn placement is not random. `_pick_candidates` hands the player the two
  live cells nearest to them, which is the friendliest possible spawn pattern
  for chaining kills. A real RNG can only be worse for the farmer.
* Game-over checks are skipped. The search only walks legal actions, so a loop
  it finds never has to survive anything.

Both make a "no exploit found" verdict conservative: the real game is harder to
farm than the model.

ULT (Z) is modelled too. It was left out at first to keep the branching factor
down, but X and Z draw on the same bar, so any claim about which one a player
reaches for is meaningless while only one of them exists. Holding a full bar is
also a free escape from being surrounded in the real game, and that shows up
here for free: when every step is blocked, `Z` is still a legal action, so the
run survives exactly when the game would let it.

Usage
-----
    python tools/extra_x_lab.py            # sweep every variant
    python tools/extra_x_lab.py shipped    # one variant, with a trace
"""

from __future__ import annotations

import sys
from dataclasses import dataclass, field
from typing import Iterable, NamedTuple, Optional

COLS = 5
ROWS = 5
CELLS = COLS * ROWS
LIVE = 0
DEAD = 1

ENERGY_MAX = 16
ULT_DASH_COUNT = 4
# Three slots or more: the band where saving toward ULT competes with spending
# on X, which is where the two abilities are supposed to feel different.
ENERGY_QUARTER_UNITS_HIGH_BAND = 12
QUEUE_SIZE = 3
SPAWN_CYCLE_STEPS = 2
SPAWNS_PER_CYCLE = 2
OPENING_GRACE_TURNS = 1
BASE_KILL_SCORE = 1
# Mirrors ScoreManager.COMBO_SCORE_MULTIPLIERS.
COMBO_SCORE_MULTIPLIERS = (1, 2, 5, 10, 20)

UP, DOWN, LEFT, RIGHT = 1, 2, 3, 4
DIR_STEP = {UP: (0, -1), DOWN: (0, 1), LEFT: (-1, 0), RIGHT: (1, 0)}
DIR_KEY = {UP: "W", DOWN: "S", LEFT: "A", RIGHT: "D"}

# combo -> quarter units granted by a kill, mirroring _charge_energy_for_combo.
DEFAULT_CHARGE = {1: 1, 2: 2, 3: 4, 4: 4}
DEFAULT_CHARGE_HIGH = 6  # combo >= 5
DEFAULT_CHARGE_HIGH_FROM = 5


@dataclass(frozen=True)
class Variant:
    """One candidate ruleset for X."""

    name: str
    summary: str
    # Energy cost of arming X, indexed by how many X have been armed since the
    # combo chain started. The last entry repeats.
    cost_schedule: tuple[int, ...] = (4,)
    # Does a kill paid for by X charge energy?
    kill_charges_energy: bool = False
    # Does an X attack keep its direction token in the queue?
    keeps_ammo: bool = True
    # Extra queue slots the last ULT dash may bank beyond QUEUE_SIZE.
    ultimate_completion_overflow_slots: int = 1
    # May the X-paid action be an attack, or only a move onto a live cell?
    allows_attack: bool = True
    # Does the X-paid action skip the spawn clock?
    freezes_spawn: bool = True
    # Scale applied to charge amounts on an X-paid kill (only read when
    # kill_charges_energy is true).
    kill_charge_numerator: int = 1
    kill_charge_denominator: int = 1
    # Highest combo the score multiplier honours. 0 means uncapped; historical
    # variants use that mode while the shipping rules supply a multiplier table.
    score_multiplier_cap: int = 0
    # Ceiling on the combo counter itself. Capping the counter rather than just
    # its payout keeps the number on screen meaningful: it stops where the
    # rewards stop instead of climbing past them.
    combo_cap: int = 0
    # Score multiplier per combo step, mirroring ScoreManager. None keeps the
    # old flat `10 * combo` curve, which the historical variants need in order
    # to still reproduce the runaway they were written to demonstrate.
    multiplier_table: Optional[tuple[int, ...]] = None

    def kill_score(self, combo: int) -> int:
        multiplier = max(1, combo)
        if self.score_multiplier_cap:
            multiplier = min(multiplier, self.score_multiplier_cap)
        if self.multiplier_table:
            index = min(multiplier, len(self.multiplier_table)) - 1
            multiplier = self.multiplier_table[index]
        return BASE_KILL_SCORE * multiplier

    def cost(self, x_in_chain: int) -> int:
        index = min(x_in_chain, len(self.cost_schedule) - 1)
        return self.cost_schedule[index]

    def charge_for(self, combo: int, paid_by_x: bool) -> int:
        base = DEFAULT_CHARGE.get(
            combo,
            DEFAULT_CHARGE_HIGH if combo >= DEFAULT_CHARGE_HIGH_FROM else 0,
        )
        if not paid_by_x:
            return base
        if not self.kill_charges_energy:
            return 0
        return base * self.kill_charge_numerator // self.kill_charge_denominator


class State(NamedTuple):
    grid: tuple[int, ...]
    pos: int
    queue: tuple[int, ...]
    energy: int
    combo: int
    cycle: int
    cands: tuple[int, ...]
    grace: int
    armed: int
    x_in_chain: int
    ult: int = 0  # ULT dashes still owed

    def key(self) -> tuple:
        """Everything the future depends on except the scored resources."""
        return (
            self.grid,
            self.pos,
            self.queue,
            self.cycle,
            self.cands,
            self.grace,
            self.armed,
            self.x_in_chain,
            self.ult,
        )


def _xy(index: int) -> tuple[int, int]:
    return index % COLS, index // COLS


def _neighbour(index: int, direction: int) -> Optional[int]:
    x, y = _xy(index)
    dx, dy = DIR_STEP[direction]
    nx, ny = x + dx, y + dy
    if nx < 0 or nx >= COLS or ny < 0 or ny >= ROWS:
        return None
    return ny * COLS + nx


class Engine:
    """The EXTRA rules, parameterised over one X variant."""

    def __init__(self, variant: Variant) -> None:
        self.variant = variant
        # When set, spawns are drawn uniformly like the real game. When None,
        # the adversarial oracle below hands the player the nearest cells.
        self.rng = None

    # -- inventory -------------------------------------------------------
    def _push(self, queue: tuple[int, ...], direction: int) -> tuple[int, ...]:
        items = list(queue)
        while len(items) >= QUEUE_SIZE:
            items.pop(0)
        items.append(direction)
        return tuple(items)

    def _push_ultimate_completion(
        self, queue: tuple[int, ...], direction: int
    ) -> tuple[int, ...]:
        limit = QUEUE_SIZE + self.variant.ultimate_completion_overflow_slots
        items = list(queue)
        while len(items) >= limit:
            items.pop(0)
        items.append(direction)
        return tuple(items)

    def _drop(self, queue: tuple[int, ...], direction: int) -> tuple[int, ...]:
        items = list(queue)
        items.remove(direction)  # first occurrence, like Inventory.find_direction
        return tuple(items)

    # -- spawn clock -----------------------------------------------------
    def _pick_candidates(self, state: State) -> tuple[int, ...]:
        """Adversarial spawn oracle: the live cells nearest the player.

        The real game shuffles every live cell. Handing the farmer the closest
        targets instead can only make an exploit easier to find.
        """
        if self.rng is not None:
            available = [i for i in range(CELLS) if state.grid[i] == LIVE]
            self.rng.shuffle(available)
            return tuple(sorted(available[:SPAWNS_PER_CYCLE]))
        px, py = _xy(state.pos)
        ranked = sorted(
            (
                (abs(_xy(i)[0] - px) + abs(_xy(i)[1] - py), i)
                for i in range(CELLS)
                if state.grid[i] == LIVE and i != state.pos
            )
        )
        return tuple(sorted(index for _, index in ranked[:SPAWNS_PER_CYCLE]))

    def _advance_cycle(self, state: State) -> tuple[State, bool]:
        """Returns the state after one spawn-clock tick, and survival."""
        cycle = state.cycle + 1
        if cycle == 1:
            return state._replace(cycle=cycle, cands=self._pick_candidates(state)), True
        if cycle < SPAWN_CYCLE_STEPS:
            return state._replace(cycle=cycle), True

        grid = list(state.grid)
        queue = state.queue
        for cell in state.cands:
            if grid[cell] != LIVE:
                continue
            if cell == state.pos:
                if len(queue) >= 2:
                    queue = queue[2:]
                    continue
                grid[cell] = DEAD
                return state._replace(grid=tuple(grid), cycle=0, cands=()), False
            grid[cell] = DEAD
        return (
            state._replace(grid=tuple(grid), queue=queue, cycle=0, cands=()),
            True,
        )

    def _finalize(self, state: State, freeze: bool) -> tuple[Optional[State], bool]:
        if freeze:
            return state, True
        if state.grace > 0:
            return state._replace(grace=state.grace - 1), True
        nxt, alive = self._advance_cycle(state)
        return nxt, alive

    def _will_spawn_hit(self, state: State, target: int) -> bool:
        if state.grace > 0:
            return False
        if state.cycle + 1 < SPAWN_CYCLE_STEPS:
            return False
        return target in state.cands

    # -- actions ---------------------------------------------------------
    def apply(self, state: State, action: str) -> Optional[tuple[State, int]]:
        """Returns (next_state, score_gained) or None when the action is illegal."""
        if action == "X":
            return self._apply_arm(state)
        if action == "Z":
            return self._apply_ultimate(state)
        if action == ".":
            return self._apply_wait(state)
        if state.ult > 0:
            return self._apply_ultimate_dash(state, action)
        return self._apply_move(state, action)

    def _apply_ultimate(self, state: State) -> Optional[tuple[State, int]]:
        # Mirrors try_energy_ultimate: all four slots at once, and the board
        # refuses it while a STEP is armed or a chain is already running.
        if state.armed or state.ult > 0:
            return None
        if state.energy < ENERGY_MAX:
            return None
        return state._replace(energy=0, ult=ULT_DASH_COUNT), 0

    def _ultimate_destination(self, state: State, direction: int) -> int:
        """Travel until the first dead cell, or the board edge."""
        cursor = _neighbour(state.pos, direction)
        destination = state.pos
        while cursor is not None:
            destination = cursor
            if state.grid[cursor] == DEAD:
                break
            cursor = _neighbour(cursor, direction)
        return destination

    def _apply_ultimate_dash(self, state: State, action: str) -> Optional[tuple[State, int]]:
        direction = next(d for d, key in DIR_KEY.items() if key == action)
        destination = self._ultimate_destination(state, direction)
        if destination == state.pos:
            return None  # zero displacement is rejected by the board

        remaining = state.ult - 1
        # The freeze is computed after the decrement in Board.gd, so the last
        # dash of a chain does advance the spawn clock.
        freeze = remaining > 0
        grid = list(state.grid)
        combo = state.combo
        score = 0
        if grid[destination] == DEAD:
            grid[destination] = LIVE
            combo += 1
            if self.variant.combo_cap:
                combo = min(combo, self.variant.combo_cap)
            score = self.variant.kill_score(combo)
            # ULT kills are energy-sterile, like X-paid kills.
        moved = state._replace(
            grid=tuple(grid),
            pos=destination,
            queue=(
                self._push_ultimate_completion(state.queue, direction)
                if remaining == 0
                else self._push(state.queue, direction)
            ),
            combo=combo,
            ult=remaining,
        )
        nxt, alive = self._finalize(moved, freeze=freeze)
        if not alive:
            return None
        return nxt, score

    def _apply_arm(self, state: State) -> Optional[tuple[State, int]]:
        if state.armed or state.ult > 0:
            return None
        cost = self.variant.cost(state.x_in_chain)
        if state.energy < cost:
            return None
        return (
            state._replace(
                energy=state.energy - cost,
                armed=1,
                x_in_chain=state.x_in_chain + 1,
            ),
            0,
        )

    def _apply_wait(self, state: State) -> Optional[tuple[State, int]]:
        if state.armed or state.ult > 0:
            return None
        nxt, alive = self._finalize(
            state._replace(combo=max(0, state.combo - 1), x_in_chain=0), freeze=False
        )
        if not alive:
            return None
        return nxt, 0

    def _apply_move(self, state: State, action: str) -> Optional[tuple[State, int]]:
        direction = next(d for d, key in DIR_KEY.items() if key == action)
        target = _neighbour(state.pos, direction)
        if target is None:
            return None

        variant = self.variant
        bonus = bool(state.armed)
        freeze = bonus and variant.freezes_spawn
        score = 0

        if state.grid[target] == LIVE:
            queue = state.queue
            combo = state.combo
            x_in_chain = state.x_in_chain
            if bonus:
                queue = self._push(queue, direction)
            else:
                combo = max(0, combo - 1)
                x_in_chain = 0
                if not self._will_spawn_hit(state, target):
                    queue = self._push(queue, direction)
            moved = state._replace(
                pos=target,
                queue=queue,
                combo=combo,
                x_in_chain=x_in_chain,
                armed=0,
            )
        else:
            if bonus and not variant.allows_attack:
                return None
            if direction not in state.queue:
                return None
            queue = state.queue
            if not bonus or not variant.keeps_ammo:
                queue = self._drop(queue, direction)

            grid = list(state.grid)
            grid[target] = LIVE
            combo = state.combo + 1
            if variant.combo_cap:
                combo = min(combo, variant.combo_cap)
            score = variant.kill_score(combo)
            energy = min(
                ENERGY_MAX,
                state.energy + variant.charge_for(combo, paid_by_x=bonus),
            )
            moved = state._replace(
                grid=tuple(grid),
                pos=target,
                queue=queue,
                energy=energy,
                combo=combo,
                armed=0,
            )

        nxt, alive = self._finalize(moved, freeze=freeze)
        if not alive:
            return None
        return nxt, score

    def actions(self) -> tuple[str, ...]:
        return ("W", "S", "A", "D", "X", "Z", ".")


# ---------------------------------------------------------------------------
# Exploit search
# ---------------------------------------------------------------------------
#
# What counts as an exploit
# -------------------------
# Every X-paid action is free of the spawn clock, so the degenerate state is one
# where energy stops being a constraint: the player then gets a permanent extra
# action per clock tick and score grows without the board ever ageing faster.
# The detector is therefore a *rate* measurement, not a graph cycle. A farming
# bot plays a long game while pressing X at every opportunity, and the variant
# fails if the bot sustains X on nearly every turn while its energy floor never
# drops, i.e. the chain financed itself.


@dataclass
class FarmResult:
    variant: str
    turns: int = 0
    x_presses: int = 0
    score: int = 0
    kills: int = 0
    died: bool = False
    energy_floor: int = ENERGY_MAX
    energy_end: int = 0
    max_frozen_chain: int = 0
    max_combo: int = 0
    early_score: int = 0  # score banked in the first half of the run
    early_turns: int = 0
    z_activations: int = 0
    decisions: int = 0
    full_bar_decisions: int = 0  # decisions taken while the bar was full
    full_bar_holds: int = 0  # ... of those, ones that spent nothing
    x_low_band: int = 0  # X pressed below the ULT threshold
    x_high_band: int = 0  # X pressed at three slots or more

    @property
    def hold_rate(self) -> float:
        if self.full_bar_decisions <= 0:
            return 0.0
        return self.full_bar_holds / self.full_bar_decisions

    @property
    def acceleration(self) -> float:
        """Late score rate over early score rate.

        An endless arcade run is meant to be linear in time: you clear what
        spawns, so score per turn hovers around a constant. A ratio that climbs
        means each turn is worth more than the last, which is the signature of
        a chain the rules never force to end.
        """
        late_turns = self.turns - self.early_turns
        if self.early_turns <= 0 or late_turns <= 0 or self.early_score <= 0:
            return 1.0
        early_rate = self.early_score / self.early_turns
        late_rate = (self.score - self.early_score) / late_turns
        return late_rate / early_rate

    @property
    def x_rate(self) -> float:
        return self.x_presses / self.turns if self.turns else 0.0

    @property
    def self_financing(self) -> bool:
        """True when energy never actually limited the farmer."""
        return self.x_rate >= 0.9 and self.energy_floor >= ENERGY_SLOT_FLOOR


ENERGY_SLOT_FLOOR = 4  # one full slot still banked at the worst moment


class FarmBot:
    """Plays to press X as often as possible while keeping the chain alive.

    This is deliberately not a good survival bot. Its only job is to find the
    most X-hungry line the rules allow, so that a variant which lets X pay for
    itself shows up as a sustained press rate.
    """

    def __init__(self, engine: Engine) -> None:
        self.engine = engine

    def _attack_dirs(self, state: State) -> list[int]:
        out = []
        for direction in DIR_STEP:
            target = _neighbour(state.pos, direction)
            if target is None:
                continue
            if state.grid[target] == DEAD and direction in state.queue:
                out.append(direction)
        return out

    def _live_dirs(self, state: State) -> list[int]:
        out = []
        for direction in DIR_STEP:
            target = _neighbour(state.pos, direction)
            if target is None:
                continue
            if state.grid[target] == LIVE:
                out.append(direction)
        return out

    def _future_kills(self, state: State, direction: int) -> int:
        """Adjacent kills available after stepping onto a live cell."""
        target = _neighbour(state.pos, direction)
        if target is None:
            return -1
        queue = self.engine._push(state.queue, direction)
        count = 0
        for nxt in DIR_STEP:
            cell = _neighbour(target, nxt)
            if cell is None:
                continue
            if state.grid[cell] == DEAD and nxt in queue:
                count += 1
        return count

    def _hunt_dirs(self, state: State) -> list[int]:
        """Live-cell steps ordered by how well they close on a kill.

        Walking toward a dead cell also banks the direction token needed to
        attack it, so approach and ammo are the same problem.
        """
        targets = [i for i in range(CELLS) if state.grid[i] == DEAD]
        px, py = _xy(state.pos)

        def distance_after(direction: int) -> tuple:
            cell = _neighbour(state.pos, direction)
            if cell is None:
                return (99, 0, 0)
            cx, cy = _xy(cell)
            best = min(
                (abs(_xy(t)[0] - cx) + abs(_xy(t)[1] - cy) for t in targets),
                default=9,
            )
            danger = 1 if self.engine._will_spawn_hit(state, cell) else 0
            return (danger, best, -self._future_kills(state, direction))

        return sorted(self._live_dirs(state), key=distance_after)

    def choose_greedy(self, state: State) -> Optional[str]:
        attacks = self._attack_dirs(state)
        variant = self.engine.variant

        if state.armed:
            # The X action is already paid for: spend it on a kill when one is
            # in reach, otherwise on the approach step that keeps the chain.
            if attacks and variant.allows_attack:
                return DIR_KEY[attacks[0]]
            hunt = self._hunt_dirs(state)
            if not hunt:
                return None
            return DIR_KEY[hunt[0]]

        cost = variant.cost(state.x_in_chain)
        can_arm = state.energy >= cost

        # A kill is always the best real turn: it scores, it charges energy and
        # it never breaks the chain.
        if attacks:
            return DIR_KEY[attacks[0]]

        # No kill in reach. A normal step would reset the combo, so pay for an
        # X step instead whenever the chain is worth anything. This is the line
        # a self-financing X makes free, which is exactly what we are hunting.
        if can_arm and state.combo > 0:
            return "X"
        if can_arm and any(self._future_kills(state, d) > 0 for d in self._live_dirs(state)):
            return "X"

        hunt = self._hunt_dirs(state)
        if hunt:
            return DIR_KEY[hunt[0]]
        return "."

    # -- lookahead -------------------------------------------------------
    #
    # The greedy policy above dies inside forty turns, which is nowhere near
    # long enough to reach the combo-6 tier where an X exploit would live. This
    # search is the one that actually gets to press X in anger: it plays for
    # score, and if a variant makes X free it will find that on its own rather
    # than being told to.

    DISCOUNT = 0.85
    DEATH = -6000.0
    # Holding a full bar is a guaranteed escape from being surrounded, so the
    # last quarter unit before the cap is worth far more than the ones before
    # it. Pricing energy linearly makes the bot spend too eagerly and inflates
    # the measured X rate, which is the whole thing we are trying to read. This
    # covers the insurance only: the offensive value of ULT needs no term
    # because Z is a legal action the search can already take.
    FULL_BAR_INSURANCE = 800.0
    ENERGY_UNIT_VALUE = 2.0
    # Distance to the nearest kill. Without this nothing in the value function
    # can tell a one-cell STEP apart from a board-crossing dash.
    TARGET_DISTANCE_WEIGHT = 8.0
    # Holding the direction that points at the nearest kill is what makes X
    # usable at all; ULT ignores it entirely.
    APPROACH_MATCH_BONUS = 40.0

    def _value(self, state: State) -> float:
        live_exits = 0
        attack_exits = 0
        for direction in DIR_STEP:
            cell = _neighbour(state.pos, direction)
            if cell is None:
                continue
            if state.grid[cell] == LIVE:
                live_exits += 1
            elif direction in state.queue:
                attack_exits += 1
        if live_exits + attack_exits == 0 and state.energy < ENERGY_MAX:
            return self.DEATH
        px, py = _xy(state.pos)
        centre_distance = abs(px - COLS // 2) + abs(py - ROWS // 2)
        value = live_exits * 55.0 + attack_exits * 95.0
        value += state.combo * state.combo * 18.0
        value += len(set(state.queue)) * 16.0
        value -= centre_distance * 12.0
        if live_exits + attack_exits == 1:
            value -= 420.0

        value += state.energy * self.ENERGY_UNIT_VALUE
        if state.energy >= ENERGY_MAX:
            value += self.FULL_BAR_INSURANCE

        distance, approach = self._nearest_target(state)
        if distance is not None:
            value -= distance * self.TARGET_DISTANCE_WEIGHT
            if approach is not None and approach in state.queue:
                value += self.APPROACH_MATCH_BONUS
        return value

    def _nearest_target(self, state: State) -> tuple[Optional[int], Optional[int]]:
        """Distance to the closest dead cell and the first step toward it."""
        px, py = _xy(state.pos)
        best_distance = None
        best_cell = None
        for cell in range(CELLS):
            if state.grid[cell] != DEAD:
                continue
            cx, cy = _xy(cell)
            distance = abs(cx - px) + abs(cy - py)
            if best_distance is None or distance < best_distance:
                best_distance = distance
                best_cell = cell
        if best_cell is None:
            return None, None
        cx, cy = _xy(best_cell)
        if cx != px:
            approach = RIGHT if cx > px else LEFT
        elif cy != py:
            approach = DOWN if cy > py else UP
        else:
            approach = None
        return best_distance, approach

    def _search(self, state: State, depth: int) -> float:
        if depth <= 0:
            return self._value(state)
        best = None
        for action in self.engine.actions():
            outcome = self.engine.apply(state, action)
            if outcome is None:
                continue
            nxt, gained = outcome
            branch = gained * 34.0 + self.DISCOUNT * self._search(nxt, depth - 1)
            if best is None or branch > best:
                best = branch
        return self.DEATH if best is None else best

    def choose_lookahead(self, state: State, depth: int) -> Optional[str]:
        best_action = None
        best_value = None
        for action in self.engine.actions():
            outcome = self.engine.apply(state, action)
            if outcome is None:
                continue
            nxt, gained = outcome
            value = gained * 34.0 + self.DISCOUNT * self._search(nxt, depth - 1)
            if best_value is None or value > best_value:
                best_value = value
                best_action = action
        return best_action


def farm(
    variant: Variant,
    turn_cap: int = 600,
    seed: int = 20260818,
    depth: int = 4,
) -> FarmResult:
    """Run the farming bot until it dies or the turn cap is reached."""
    import random

    rng = random.Random(seed)
    engine = Engine(variant)
    engine.rng = rng  # random spawns instead of the adversarial oracle
    bot = FarmBot(engine)
    result = FarmResult(variant=variant.name)

    centre = (ROWS // 2) * COLS + COLS // 2
    state = State(
        grid=tuple([LIVE] * CELLS),
        pos=centre,
        queue=(),
        energy=0,
        combo=0,
        cycle=0,
        cands=(),
        grace=OPENING_GRACE_TURNS,
        armed=0,
        x_in_chain=0,
    )

    frozen = 0
    guard = turn_cap * 8
    while result.turns < turn_cap and guard > 0:
        guard -= 1
        action = bot.choose_lookahead(state, depth)
        if action is None:
            break
        outcome = engine.apply(state, action)
        if outcome is None:
            # The bot asked for something illegal; fall back to any legal action.
            for fallback in engine.actions():
                outcome = engine.apply(state, fallback)
                if outcome is not None:
                    action = fallback
                    break
            if outcome is None:
                result.died = True
                break
        nxt, gained = outcome

        result.decisions += 1
        if state.energy >= ENERGY_MAX and state.ult == 0 and not state.armed:
            result.full_bar_decisions += 1
            if action not in ("X", "Z"):
                result.full_bar_holds += 1

        if action == "X":
            result.x_presses += 1
            if state.energy >= ENERGY_QUARTER_UNITS_HIGH_BAND:
                result.x_high_band += 1
            else:
                result.x_low_band += 1
        elif action == "Z":
            result.z_activations += 1
        else:
            frozen_action = (
                bool(state.armed) and engine.variant.freezes_spawn
            ) or (state.ult > 0 and nxt.ult > 0)
            if frozen_action:
                frozen += 1
                result.max_frozen_chain = max(result.max_frozen_chain, frozen)
            else:
                frozen = 0
                result.turns += 1
            if gained:
                result.kills += 1
        result.score += gained
        state = nxt
        result.max_combo = max(result.max_combo, state.combo)
        if result.turns <= turn_cap // 2:
            result.early_score = result.score
            result.early_turns = result.turns
        if result.turns > 20:  # let the opening charge-up settle first
            result.energy_floor = min(result.energy_floor, state.energy)
        if state.grid[state.pos] == DEAD:
            result.died = True
            break

    result.energy_end = state.energy
    return result


# ---------------------------------------------------------------------------
# Variants under test
# ---------------------------------------------------------------------------

VARIANTS: tuple[Variant, ...] = (
    Variant(
        name="legacy",
        summary="Rules before this session: X kills charge energy, X attacks eat ammo.",
        kill_charges_energy=True,
        keeps_ammo=False,
        ultimate_completion_overflow_slots=0,
    ),
    Variant(
        name="shipped",
        summary="Implemented: heat caps at 5 on a 1/2/5/10/20 score curve, X flat 4 and sterile.",
        combo_cap=5,
        multiplier_table=COMBO_SCORE_MULTIPLIERS,
    ),
    Variant(
        name="flat_curve",
        summary="Same rules but a flat combo payout, for comparison.",
        combo_cap=6,
    ),
    Variant(
        name="ladder",
        summary="The rejected alternative: X costs 4/8/12 within a chain.",
        cost_schedule=(4, 8, 12),
        kill_charges_energy=True,
    ),
    Variant(
        name="sterile",
        summary="Sterile X under the shipping five-tier heat cap.",
        combo_cap=5,
    ),
    Variant(
        name="sterile_only",
        summary="Energy-sterile X kills alone, no ammo or slot help.",
        keeps_ammo=False,
        ultimate_completion_overflow_slots=0,
    ),
    Variant(
        name="ammo_only",
        summary="X keeps ammo but X kills still charge energy.",
        kill_charges_energy=True,
        ultimate_completion_overflow_slots=0,
    ),
    Variant(
        name="half_charge",
        summary="X kills charge half energy and keeps its direction token.",
        kill_charges_energy=True,
        kill_charge_numerator=1,
        kill_charge_denominator=2,
    ),
    Variant(
        name="gentle_ladder",
        summary="Gentler ladder 4/6/8/10/12, trading chain length for mobility.",
        cost_schedule=(4, 6, 8, 10, 12),
        kill_charges_energy=True,
    ),
    Variant(
        name="long_ladder",
        summary="Long gentle ladder 4/5/6/8/10/12/16, sterile after the cap.",
        cost_schedule=(4, 5, 6, 8, 10, 12, 16),
        kill_charges_energy=True,
    ),
    Variant(
        name="steep_ladder",
        summary="Steeper ladder 4/12/20, to see how much the slope buys.",
        cost_schedule=(4, 12, 20),
        kill_charges_energy=True,
    ),
    Variant(
        name="cheap_sterile",
        summary="Half-price X (2 quarters), energy-sterile, keeps its direction token.",
        cost_schedule=(2,),
    ),
    Variant(
        name="move_only",
        summary="The reverted experiment: X may only reposition onto a live cell.",
        allows_attack=False,
        keeps_ammo=False,
        ultimate_completion_overflow_slots=0,
    ),
    Variant(
        name="unfrozen_sterile",
        summary="X grants a free action but the spawn clock still ticks.",
        freezes_spawn=False,
    ),
    # -- score-curve experiments ----------------------------------------
    # The energy table already saturates at combo 6 (+8 and no higher), but the
    # score multiplier does not, so score is the only unbounded quantity in the
    # game. These variants ask what happens when the two curves agree.
    Variant(
        name="cap6_flat_refund",
        summary="Score multiplier caps at x6. X flat 4 with normal refunds.",
        kill_charges_energy=True,
        score_multiplier_cap=6,
    ),
    Variant(
        name="cap6_sterile",
        summary="Score multiplier caps at x6. X flat 4, X-paid kills sterile.",
        score_multiplier_cap=6,
    ),
    Variant(
        name="cap6_ladder",
        summary="Score multiplier caps at x6 and X still costs 4/8/12.",
        cost_schedule=(4, 8, 12),
        kill_charges_energy=True,
        score_multiplier_cap=6,
    ),
    Variant(
        name="cap12_sterile",
        summary="Score multiplier caps at x12, twice the energy saturation.",
        score_multiplier_cap=12,
    ),
    # -- combo counter capped at the energy saturation point -------------
    # Capping the counter itself, not just its payout, so the number on screen
    # stops exactly where the rewards stop.
    Variant(
        name="combo6_sterile",
        summary="Combo counter maxes at 6. X flat 4, X-paid kills sterile.",
        combo_cap=6,
    ),
    Variant(
        name="combo6_ladder",
        summary="Combo counter maxes at 6, X still costs 4/8/12 with refunds.",
        cost_schedule=(4, 8, 12),
        kill_charges_energy=True,
        combo_cap=6,
    ),
    Variant(
        name="combo6_flat_refund",
        summary="Combo counter maxes at 6 but X is flat 4 and still refunds.",
        kill_charges_energy=True,
        combo_cap=6,
    ),
)


# ---------------------------------------------------------------------------
# Closed-form convergence analysis
# ---------------------------------------------------------------------------
#
# The simulation above is only a sanity check. The convergence question itself
# is exact, because every X-paid action is settled by two numbers:
#
#   cost    the energy X takes to arm
#   refund  the most energy the X-paid action can hand back, which is the
#           charge for a kill at the top combo tier (0 when X-paid kills are
#           energy-sterile, or when X may not attack at all)
#
# If refund >= cost the chain pays for itself: the player can keep arming X
# forever and the spawn clock stops being the thing that limits them. If
# refund < cost every X is a strict drain, so the number of consecutive
# spawn-frozen actions is capped at ENERGY_MAX // cost and energy can only be
# rebuilt on turns that advance the clock. That is the convergence guarantee.


class Economy(NamedTuple):
    cost_first: int
    refund_max: int
    net_first: int
    frozen_cap: int  # 0 means unbounded
    chain_profit: int
    farmable: bool

    @property
    def verdict(self) -> str:
        return "FARMABLE" if self.farmable else "CONVERGES"


FROZEN_LADDER_LIMIT = 1000


def analyze(variant: Variant) -> Economy:
    """Walk the best case for a farmer and see whether the ladder terminates.

    An earlier version of this compared the refund against the *steady-state*
    cost only, which missed the obvious counter-play against an escalating
    price: break the combo and the price resets to the first rung. So the real
    question is not whether one price beats the refund, it is whether the run
    of consecutive spawn-frozen actions terminates at all. That is what
    `frozen_cap` walks, starting from a full bar and assuming every X-paid
    action is a kill at the top combo tier.

    `chain_profit` is reported alongside but is a balance number, not a safety
    one: a variant where each chain nets energy is fine as long as the frozen
    run still ends, because the player has to spend clock-advancing turns to
    rebuild the chain.
    """
    cost_first = variant.cost(0)
    if variant.allows_attack:
        # Highest tier a kill can reach; combo 6+ is the best case for a farmer.
        refund = variant.charge_for(6, paid_by_x=True)
    else:
        refund = 0  # an X-paid reposition can never kill, so it never charges

    energy = ENERGY_MAX
    depth = 0
    profit = 0
    best_prefix_profit = 0
    while depth < FROZEN_LADDER_LIMIT:
        cost = variant.cost(depth)
        if energy < cost:
            break
        energy = min(ENERGY_MAX, energy - cost + refund)
        profit += refund - cost
        best_prefix_profit = max(best_prefix_profit, profit)
        depth += 1

    unbounded = depth >= FROZEN_LADDER_LIMIT
    return Economy(
        cost_first=cost_first,
        refund_max=refund,
        net_first=refund - cost_first,
        frozen_cap=0 if unbounded else depth,
        chain_profit=best_prefix_profit,
        farmable=unbounded,
    )


SEEDS = (20260818, 20260819, 20260820)


def evaluate(variant: Variant) -> tuple[list[FarmResult], bool]:
    runs = [farm(variant, seed=seed) for seed in SEEDS]
    farmable = any(run.self_financing for run in runs)
    return runs, farmable


# A combo this deep can only come from a chain the rules never force to end.
COMBO_FARM_THRESHOLD = 40
# Score rate more than this much higher late than early means the run is
# accelerating rather than settling into a steady clear rate.
ACCELERATION_THRESHOLD = 3.0


def _format(variant: Variant, economy: Economy, runs: list[FarmResult]) -> str:
    cap = "inf" if economy.frozen_cap == 0 else str(economy.frozen_cap)
    x_rate = sum(r.x_rate for r in runs) / len(runs)
    turns = sum(r.turns for r in runs) // len(runs)
    score = sum(r.score for r in runs) // len(runs)
    combo = max(r.max_combo for r in runs)
    accel = max(r.acceleration for r in runs)
    verdict = economy.verdict
    if verdict == "CONVERGES":
        if accel >= ACCELERATION_THRESHOLD:
            verdict = "RUNAWAY"
        elif combo >= COMBO_FARM_THRESHOLD:
            verdict = "COMBO-FARM"
    z_total = sum(r.z_activations for r in runs)
    x_total = sum(r.x_presses for r in runs)
    x_high = sum(r.x_high_band for r in runs)
    hold = sum(r.hold_rate for r in runs) / len(runs)
    high_share = (x_high / x_total) if x_total else 0.0
    full_seen = sum(r.full_bar_decisions for r in runs)
    # Which ability the bar actually drains into, rather than which is pressed
    # more often: one Z costs four X.
    x_energy = x_total * variant.cost(0)
    z_energy = z_total * ENERGY_MAX
    x_energy_share = x_energy / (x_energy + z_energy) if (x_energy + z_energy) else 0.0
    return (
        f"{variant.name:<20} {verdict:<10} "
        f"frozen<={cap:<4} maxcombo={combo:>4} accel={accel:5.1f}x "
        f"turns={turns:>4} score={score:>8}\n"
        f"    X={x_total:<4} (high band {high_share:4.0%})  Z={z_total:<3}  "
        f"energy via X={x_energy_share:4.0%}  "
        f"full bar seen {full_seen:>4}x, held {hold:4.0%}\n"
        f"    {variant.summary}"
    )


def main(argv: list[str]) -> int:
    wanted = set(argv[1:])
    print(
        "cost1     energy to arm the first X in a chain\n"
        "refund    most energy an X-paid action can hand back (kill at combo 6+)\n"
        "net1      energy the first X of a chain nets; >0 means it profits\n"
        "chain$    best energy a single chain can bank by using X\n"
        "frozen<=  consecutive spawn-frozen actions from a full bar; inf = farmable\n"
        "bot ...   lookahead bot playing for score, as a check on the algebra\n"
    )
    for variant in VARIANTS:
        if wanted and variant.name not in wanted:
            continue
        economy = analyze(variant)
        runs, _ = evaluate(variant)
        print(_format(variant, economy, runs))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
