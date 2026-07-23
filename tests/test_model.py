from __future__ import annotations

import unittest
from dataclasses import replace

from solver.model import (
    BlockKind,
    BlockSpec,
    BlockState,
    Command,
    Direction,
    Level,
    State,
    canonical_edge,
)


def make_level(
    *,
    goals: frozenset[tuple[int, int]] = frozenset({(2, 0)}),
    block_positions: tuple[tuple[int, int], ...] = ((1, 0),),
    block_vectors: tuple[Direction | None, ...] | None = None,
    install_order: tuple[int, ...] = (),
) -> Level:
    if block_vectors is None:
        block_vectors = (None,) * len(block_positions)
    specs = tuple(
        BlockSpec(index, chr(64 + index), BlockKind.NORMAL)
        for index in range(1, len(block_positions) + 1)
    )
    state = State(
        player=(0, 0),
        facing=Direction.RIGHT,
        queue=None,
        blocks=tuple(
            BlockState(position, vector)
            for position, vector in zip(block_positions, block_vectors, strict=True)
        ),
        install_order=install_order,
    )
    return Level(
        width=5,
        height=2,
        walls=frozenset(),
        goals=goals,
        fences=frozenset(),
        block_specs=specs,
        initial_state=state,
    )


class ModelTests(unittest.TestCase):
    def test_state_is_hashable(self) -> None:
        state = make_level().initial_state
        self.assertEqual({state: "seen"}[state], "seen")

    def test_command_exposes_direction_only_for_arrow_inputs(self) -> None:
        self.assertEqual(Command.LEFT.value, "L")
        self.assertEqual(Command.LEFT.direction, Direction.LEFT)
        self.assertIsNone(Command.INTERACT.direction)
        self.assertIsNone(Command.TRIGGER.direction)

    def test_fence_lookup_is_direction_independent(self) -> None:
        edge = canonical_edge((1, 0), (0, 0))
        level = replace(make_level(), fences=frozenset({edge}))
        self.assertTrue(level.has_fence((0, 0), (1, 0)))
        self.assertTrue(level.has_fence((1, 0), (0, 0)))

    def test_solved_requires_every_goal_to_contain_a_block(self) -> None:
        level = make_level(
            goals=frozenset({(2, 0), (3, 0)}),
            block_positions=((1, 0), (2, 0), (3, 0)),
        )
        self.assertTrue(level.is_solved(level.initial_state))

        unsolved = replace(
            level.initial_state,
            blocks=(
                BlockState((1, 0)),
                BlockState((2, 0)),
                BlockState((4, 0)),
            ),
        )
        self.assertFalse(level.is_solved(unsolved))

    def test_level_without_goals_is_not_solved(self) -> None:
        level = make_level(goals=frozenset())
        self.assertFalse(level.is_solved(level.initial_state))

    def test_install_order_must_match_vector_blocks(self) -> None:
        with self.assertRaisesRegex(ValueError, "every vector-carrying block"):
            make_level(block_vectors=(Direction.RIGHT,))

        level = make_level(
            block_vectors=(Direction.RIGHT,),
            install_order=(1,),
        )
        self.assertEqual(level.initial_state.install_order, (1,))


if __name__ == "__main__":
    unittest.main()
