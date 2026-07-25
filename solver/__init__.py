"""Offline state-space analysis for DIR3 levels."""

from .collection import NamedLevel, load_level_collection, parse_level_collection
from .engine import COMMAND_ORDER, parse_commands, run_commands, step
from .model import (
    BlockKind,
    BlockSpec,
    BlockState,
    Command,
    Direction,
    Level,
    State,
)
from .parser import LevelParseError, load_level, parse_level
from .search import SearchLimitReached, SolveResult, solve_astar, solve_bfs

__all__ = [
    "BlockKind",
    "BlockSpec",
    "BlockState",
    "COMMAND_ORDER",
    "Command",
    "Direction",
    "Level",
    "LevelParseError",
    "NamedLevel",
    "SearchLimitReached",
    "SolveResult",
    "State",
    "load_level",
    "load_level_collection",
    "parse_commands",
    "parse_level",
    "parse_level_collection",
    "run_commands",
    "solve_astar",
    "solve_bfs",
    "step",
]
