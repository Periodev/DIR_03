"""Shortest-path search for DIR levels."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass
from functools import lru_cache
from heapq import heappop, heappush
from itertools import count
from time import perf_counter

from .engine import COMMAND_ORDER, step
from .model import BlockKind, BlockState, Command, Direction, Level, Position, State


class SearchLimitReached(RuntimeError):
    pass


@dataclass(frozen=True, slots=True)
class SolveResult:
    commands: tuple[Command, ...] | None
    discovered_states: int
    expanded_states: int
    peak_frontier: int
    elapsed_seconds: float
    depth_limit: int | None

    @property
    def solved(self) -> bool:
        return self.commands is not None

    @property
    def command_text(self) -> str | None:
        if self.commands is None:
            return None
        return "".join(command.value for command in self.commands)

    @property
    def depth(self) -> int | None:
        return None if self.commands is None else len(self.commands)


Parent = tuple[State, Command] | None
INFINITE_DISTANCE = 1 << 30


def solve_bfs(
    level: Level,
    *,
    max_states: int | None = 2_000_000,
    max_depth: int | None = None,
) -> SolveResult:
    started = perf_counter()
    initial = level.initial_state
    if level.is_solved(initial):
        return SolveResult((), 1, 0, 1, perf_counter() - started, max_depth)

    frontier: deque[tuple[State, int]] = deque([(initial, 0)])
    parents: dict[State, Parent] = {initial: None}
    expanded_states = 0
    peak_frontier = 1

    while frontier:
        state, depth = frontier.popleft()
        expanded_states += 1
        if max_depth is not None and depth >= max_depth:
            continue

        for command in COMMAND_ORDER:
            next_state = step(level, state, command)
            if next_state == state or next_state in parents:
                continue

            parents[next_state] = (state, command)
            if max_states is not None and len(parents) > max_states:
                raise SearchLimitReached(
                    f"Search exceeded the {max_states:,}-state limit."
                )
            if level.is_solved(next_state):
                commands = _reconstruct_commands(parents, next_state)
                return SolveResult(
                    commands=commands,
                    discovered_states=len(parents),
                    expanded_states=expanded_states,
                    peak_frontier=max(peak_frontier, len(frontier) + 1),
                    elapsed_seconds=perf_counter() - started,
                    depth_limit=max_depth,
                )

            frontier.append((next_state, depth + 1))
        peak_frontier = max(peak_frontier, len(frontier))

    return SolveResult(
        commands=None,
        discovered_states=len(parents),
        expanded_states=expanded_states,
        peak_frontier=peak_frontier,
        elapsed_seconds=perf_counter() - started,
        depth_limit=max_depth,
    )


def solve_astar(
    level: Level,
    *,
    max_states: int | None = 2_000_000,
    upper_bound: int | None = None,
) -> SolveResult:
    """Find a shortest solution with an admissible block-to-goal heuristic."""
    if upper_bound is not None and upper_bound < 0:
        raise ValueError("upper_bound cannot be negative.")

    started = perf_counter()
    initial = _canonicalize_state(level, level.initial_state)
    if level.is_solved(initial):
        return SolveResult((), 1, 0, 1, perf_counter() - started, upper_bound)

    heuristic = _build_goal_matching_heuristic(level)
    initial_h = heuristic(initial)
    if initial_h == INFINITE_DISTANCE or (
        upper_bound is not None and initial_h > upper_bound
    ):
        return SolveResult(
            None,
            1,
            0,
            1,
            perf_counter() - started,
            upper_bound,
        )

    sequence = count()
    frontier: list[tuple[int, int, int, int, State]] = [
        (initial_h, initial_h, 0, next(sequence), initial)
    ]
    best_cost: dict[State, int] = {initial: 0}
    parents: dict[State, Parent] = {initial: None}
    expanded_states = 0
    peak_frontier = 1

    while frontier:
        _, _, cost, _, state = heappop(frontier)
        if best_cost.get(state) != cost:
            continue
        if level.is_solved(state):
            commands = _reconstruct_commands(parents, state)
            return SolveResult(
                commands=commands,
                discovered_states=len(best_cost),
                expanded_states=expanded_states,
                peak_frontier=peak_frontier,
                elapsed_seconds=perf_counter() - started,
                depth_limit=upper_bound,
            )

        expanded_states += 1
        if upper_bound is not None and cost >= upper_bound:
            continue

        next_cost = cost + 1
        for command in COMMAND_ORDER:
            next_state = _canonicalize_state(level, step(level, state, command))
            if next_state == state:
                continue
            previous_cost = best_cost.get(next_state)
            if previous_cost is not None and previous_cost <= next_cost:
                continue

            remaining_cost = heuristic(next_state)
            if remaining_cost == INFINITE_DISTANCE:
                continue
            estimated_total = next_cost + remaining_cost
            if upper_bound is not None and estimated_total > upper_bound:
                continue

            is_new_state = previous_cost is None
            best_cost[next_state] = next_cost
            parents[next_state] = (state, command)
            if is_new_state and max_states is not None and len(best_cost) > max_states:
                raise SearchLimitReached(
                    f"Search exceeded the {max_states:,}-state limit."
                )

            heappush(
                frontier,
                (
                    estimated_total,
                    remaining_cost,
                    next_cost,
                    next(sequence),
                    next_state,
                ),
            )
        peak_frontier = max(peak_frontier, len(frontier))

    return SolveResult(
        commands=None,
        discovered_states=len(best_cost),
        expanded_states=expanded_states,
        peak_frontier=peak_frontier,
        elapsed_seconds=perf_counter() - started,
        depth_limit=upper_bound,
    )


def _build_goal_matching_heuristic(level: Level):
    goals = tuple(sorted(level.goals))
    distances_by_goal = tuple(_static_distances_from(level, goal) for goal in goals)

    @lru_cache(maxsize=None)
    def matching_distance(positions: tuple[Position, ...]) -> int:
        if len(goals) > len(positions):
            return INFINITE_DISTANCE

        costs_by_mask: dict[int, int] = {0: 0}
        for distances in distances_by_goal:
            next_costs: dict[int, int] = {}
            for mask, cost in costs_by_mask.items():
                for block_index, position in enumerate(positions):
                    block_bit = 1 << block_index
                    if mask & block_bit:
                        continue
                    distance = distances.get(position)
                    if distance is None:
                        continue
                    next_mask = mask | block_bit
                    next_cost = cost + distance
                    current = next_costs.get(next_mask)
                    if current is None or next_cost < current:
                        next_costs[next_mask] = next_cost
            if not next_costs:
                return INFINITE_DISTANCE
            costs_by_mask = next_costs
        return min(costs_by_mask.values(), default=INFINITE_DISTANCE)

    def heuristic(state: State) -> int:
        positions = tuple(sorted(block.position for block in state.blocks))
        return matching_distance(positions)

    return heuristic


def _static_distances_from(level: Level, origin: Position) -> dict[Position, int]:
    distances = {origin: 0}
    frontier = deque([origin])
    while frontier:
        position = frontier.popleft()
        next_distance = distances[position] + 1
        for direction in Direction:
            dx, dy = direction.delta
            neighbor = position[0] + dx, position[1] + dy
            if (
                neighbor in distances
                or not level.contains(neighbor)
                or neighbor in level.walls
                or level.has_fence(position, neighbor)
            ):
                continue
            distances[neighbor] = next_distance
            frontier.append(neighbor)
    return distances


def _canonicalize_state(level: Level, state: State) -> State:
    indices_by_kind: dict[BlockKind, list[int]] = {}
    for index, spec in enumerate(level.block_specs):
        indices_by_kind.setdefault(spec.kind, []).append(index)
    if all(len(indices) <= 1 for indices in indices_by_kind.values()):
        return state

    blocks = list(state.blocks)
    remapped_ids: dict[int, int] = {}
    vector_order = {
        None: 0,
        Direction.UP: 1,
        Direction.DOWN: 2,
        Direction.LEFT: 3,
        Direction.RIGHT: 4,
    }
    for indices in indices_by_kind.values():
        sorted_blocks = sorted(
            ((state.blocks[index], index) for index in indices),
            key=lambda item: (
                item[0].position,
                vector_order[item[0].vector],
            ),
        )
        for target_index, (block, source_index) in zip(indices, sorted_blocks):
            blocks[target_index] = block
            remapped_ids[source_index + 1] = target_index + 1

    canonical = State(
        player=state.player,
        facing=state.facing,
        queue=state.queue,
        blocks=tuple(blocks),
        install_order=tuple(
            remapped_ids[block_id] for block_id in state.install_order
        ),
    )
    return canonical


def _reconstruct_commands(
    parents: dict[State, Parent],
    solved_state: State,
) -> tuple[Command, ...]:
    reversed_commands: list[Command] = []
    state = solved_state
    while parents[state] is not None:
        parent_state, command = parents[state]
        reversed_commands.append(command)
        state = parent_state
    reversed_commands.reverse()
    return tuple(reversed_commands)
