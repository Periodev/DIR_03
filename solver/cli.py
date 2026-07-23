"""Command-line entry point for solving and replay verification."""

from __future__ import annotations

import argparse
from pathlib import Path

from .collection import load_level_collection
from .engine import parse_commands, run_commands
from .parser import LevelParseError, load_level
from .search import SearchLimitReached, SolveResult, solve_bfs


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="dir3-solve",
        description="Find a shortest UDLRXT solution for a DIR3 level.",
    )
    parser.add_argument("level", type=Path, help="ASCII level file to load.")
    parser.add_argument(
        "--verify",
        metavar="COMMANDS",
        help="Replay a command stream instead of searching.",
    )
    parser.add_argument(
        "--max-states",
        type=int,
        default=2_000_000,
        help="Abort after discovering this many states; use 0 for unlimited.",
    )
    parser.add_argument(
        "--max-depth",
        type=int,
        help="Do not search beyond this command count.",
    )
    parser.add_argument(
        "--collection",
        action="store_true",
        help="Treat the input as a named level collection.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="With --collection, solve only the first N levels.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.collection:
            return _solve_collection(args)
        if args.limit is not None:
            raise ValueError("--limit requires --collection.")

        level = load_level(args.level)
        if args.verify is not None:
            commands = parse_commands(args.verify)
            final_state = run_commands(level, commands)
            solved = level.is_solved(final_state)
            print(f"Commands: {''.join(command.value for command in commands)}")
            print(f"Command count: {len(commands)}")
            print(f"Solved: {'yes' if solved else 'no'}")
            return 0 if solved else 1

        max_states = None if args.max_states == 0 else args.max_states
        result = solve_bfs(
            level,
            max_states=max_states,
            max_depth=args.max_depth,
        )
    except (OSError, LevelParseError, ValueError, SearchLimitReached) as error:
        print(f"Error: {error}")
        return 2

    if not result.solved:
        depth_note = (
            f" within depth {args.max_depth}" if args.max_depth is not None else ""
        )
        print(f"No solution found{depth_note}.")
        _print_statistics(result)
        return 1

    print(f"Commands: {result.command_text}")
    print(f"Shortest command count: {result.depth}")
    _print_statistics(result)
    return 0


def _solve_collection(args: argparse.Namespace) -> int:
    if args.verify is not None:
        raise ValueError("--verify cannot be combined with --collection.")
    if args.limit is not None and args.limit <= 0:
        raise ValueError("--limit must be positive.")

    entries = load_level_collection(args.level)
    if args.limit is not None:
        entries = entries[: args.limit]

    max_states = None if args.max_states == 0 else args.max_states
    all_solved = True
    for index, entry in enumerate(entries, start=1):
        result = solve_bfs(
            entry.level,
            max_states=max_states,
            max_depth=args.max_depth,
        )
        print(f"[{index}] {entry.name}")
        if result.solved:
            print(f"Commands: {result.command_text}")
            print(f"Shortest command count: {result.depth}")
        else:
            print("No solution found.")
            all_solved = False
        _print_statistics(result)
        if index != len(entries):
            print()

    return 0 if all_solved else 1


def _print_statistics(result: SolveResult) -> None:
    print(f"States discovered: {result.discovered_states:,}")
    print(f"States expanded: {result.expanded_states:,}")
    print(f"Peak frontier: {result.peak_frontier:,}")
    print(f"Elapsed: {result.elapsed_seconds:.3f} s")
