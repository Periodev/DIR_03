"""Breadth-first shortest-path search for DIR3 levels."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass
from time import perf_counter

from .engine import COMMAND_ORDER, step
from .model import Command, Level, State


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
