"""Immutable data model shared by the parser, rules engine, and solver."""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum
from typing import TypeAlias

Position: TypeAlias = tuple[int, int]
Edge: TypeAlias = tuple[Position, Position]


class Direction(StrEnum):
    UP = "Up"
    DOWN = "Down"
    LEFT = "Left"
    RIGHT = "Right"

    @property
    def delta(self) -> Position:
        return {
            Direction.UP: (0, -1),
            Direction.DOWN: (0, 1),
            Direction.LEFT: (-1, 0),
            Direction.RIGHT: (1, 0),
        }[self]


class Command(StrEnum):
    UP = "U"
    DOWN = "D"
    LEFT = "L"
    RIGHT = "R"
    INTERACT = "X"
    TRIGGER = "T"

    @property
    def direction(self) -> Direction | None:
        return {
            Command.UP: Direction.UP,
            Command.DOWN: Direction.DOWN,
            Command.LEFT: Direction.LEFT,
            Command.RIGHT: Direction.RIGHT,
        }.get(self)


class BlockKind(StrEnum):
    NORMAL = "normal"
    RECOVERY = "recovery"


@dataclass(frozen=True, slots=True)
class BlockSpec:
    id: int
    label: str
    kind: BlockKind

    def __post_init__(self) -> None:
        if self.id <= 0:
            raise ValueError("Block ids must be positive.")
        if len(self.label) != 1 or not self.label.isascii() or not self.label.isupper():
            raise ValueError("Block labels must be one uppercase ASCII letter.")


@dataclass(frozen=True, slots=True)
class BlockState:
    position: Position
    vector: Direction | None = None


@dataclass(frozen=True, slots=True)
class State:
    player: Position
    facing: Direction
    queue: Direction | None
    blocks: tuple[BlockState, ...]
    install_order: tuple[int, ...] = ()


def canonical_edge(first: Position, second: Position) -> Edge:
    distance = abs(first[0] - second[0]) + abs(first[1] - second[1])
    if distance != 1:
        raise ValueError("An edge must connect two orthogonally adjacent cells.")
    return (first, second) if first <= second else (second, first)


@dataclass(frozen=True, slots=True)
class Level:
    width: int
    height: int
    walls: frozenset[Position]
    goals: frozenset[Position]
    fences: frozenset[Edge]
    block_specs: tuple[BlockSpec, ...]
    initial_state: State

    def __post_init__(self) -> None:
        if self.width <= 0 or self.height <= 0:
            raise ValueError("Level dimensions must be positive.")

        expected_ids = tuple(range(1, len(self.block_specs) + 1))
        actual_ids = tuple(spec.id for spec in self.block_specs)
        if actual_ids != expected_ids:
            raise ValueError("Block specs must use sequential 1-based ids.")

        labels = tuple(spec.label for spec in self.block_specs)
        if len(labels) != len(set(labels)):
            raise ValueError("Block labels must be unique.")

        for cell in self.walls | self.goals:
            if not self.contains(cell):
                raise ValueError(f"Static cell is outside the level: {cell}.")

        for edge in self.fences:
            if edge != canonical_edge(*edge):
                raise ValueError(f"Fence is not in canonical order: {edge}.")
            if not self.contains(edge[0]) or not self.contains(edge[1]):
                raise ValueError(f"Fence endpoint is outside the level: {edge}.")

        self.validate_state(self.initial_state)

    def contains(self, position: Position) -> bool:
        x, y = position
        return 0 <= x < self.width and 0 <= y < self.height

    def has_fence(self, first: Position, second: Position) -> bool:
        return canonical_edge(first, second) in self.fences

    def block_spec(self, block_id: int) -> BlockSpec:
        if block_id <= 0 or block_id > len(self.block_specs):
            raise IndexError(f"Unknown block id: {block_id}.")
        return self.block_specs[block_id - 1]

    def validate_state(self, state: State) -> None:
        if len(state.blocks) != len(self.block_specs):
            raise ValueError("State block count does not match level block specs.")
        if not self.contains(state.player) or state.player in self.walls:
            raise ValueError("Player must occupy an in-bounds non-wall cell.")

        positions = tuple(block.position for block in state.blocks)
        if len(positions) != len(set(positions)):
            raise ValueError("Blocks cannot share a cell.")
        if state.player in positions:
            raise ValueError("Player and block cannot share a cell.")
        if any(not self.contains(position) or position in self.walls for position in positions):
            raise ValueError("Blocks must occupy in-bounds non-wall cells.")

        if len(state.install_order) != len(set(state.install_order)):
            raise ValueError("Install order cannot contain duplicate block ids.")
        if any(block_id <= 0 or block_id > len(state.blocks) for block_id in state.install_order):
            raise ValueError("Install order contains an unknown block id.")

        vector_block_ids = {
            block_id
            for block_id, block in enumerate(state.blocks, start=1)
            if block.vector is not None
        }
        if set(state.install_order) != vector_block_ids:
            raise ValueError("Install order must contain every vector-carrying block exactly once.")

    def is_solved(self, state: State) -> bool:
        if not self.goals:
            return False
        block_positions = {block.position for block in state.blocks}
        return self.goals <= block_positions
