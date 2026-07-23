"""Headless DIR3 command transition engine."""

from __future__ import annotations

from dataclasses import replace
from typing import Iterable

from .model import BlockKind, BlockState, Command, Direction, Level, Position, State

COMMAND_ORDER = tuple(Command)


def parse_commands(source: str) -> tuple[Command, ...]:
    commands: list[Command] = []
    for index, character in enumerate(source.upper(), start=1):
        if character in " \t\r\n,":
            continue
        try:
            commands.append(Command(character))
        except ValueError as error:
            raise ValueError(
                f"Unsupported command '{character}' at character {index}."
            ) from error
    if not commands:
        raise ValueError("Command stream is empty.")
    return tuple(commands)


def run_commands(
    level: Level,
    commands: str | Iterable[Command],
    *,
    stop_when_solved: bool = True,
) -> State:
    parsed_commands = parse_commands(commands) if isinstance(commands, str) else commands
    state = level.initial_state
    for command in parsed_commands:
        if stop_when_solved and level.is_solved(state):
            break
        state = step(level, state, command)
    return state


def step(level: Level, state: State, command: Command) -> State:
    if command.direction is not None:
        return _move(level, state, command.direction)
    if command is Command.INTERACT:
        return _interact(level, state)
    if command is Command.TRIGGER:
        return _trigger(level, state)
    raise ValueError(f"Unsupported command: {command!r}.")


def _move(level: Level, state: State, direction: Direction) -> State:
    target = _add(state.player, direction.delta)
    block_index = _find_block_at(state, target)

    if block_index is not None and state.facing is not direction:
        return replace(state, facing=direction)

    turned_state = replace(state, facing=direction)
    if not _player_can_cross(level, state.player, target):
        return turned_state

    if block_index is None:
        return replace(turned_state, player=target)

    block_target = _add(target, direction.delta)
    if not _block_can_move_to(level, state, target, block_target):
        return turned_state

    blocks = list(state.blocks)
    blocks[block_index] = replace(blocks[block_index], position=block_target)
    return replace(turned_state, queue=direction, blocks=tuple(blocks))


def _interact(level: Level, state: State) -> State:
    target = _add(state.player, state.facing.delta)
    block_index = _find_block_at(state, target)
    if block_index is None:
        return state

    block_id = block_index + 1
    block = state.blocks[block_index]
    if state.queue is None:
        spec = level.block_spec(block_id)
        if spec.kind is not BlockKind.RECOVERY or block.vector is None:
            return state

        blocks = list(state.blocks)
        blocks[block_index] = replace(block, vector=None)
        return replace(
            state,
            queue=block.vector,
            blocks=tuple(blocks),
            install_order=tuple(
                installed_id
                for installed_id in state.install_order
                if installed_id != block_id
            ),
        )

    if block.vector is not None:
        return state

    blocks = list(state.blocks)
    blocks[block_index] = replace(block, vector=state.queue)
    return replace(
        state,
        queue=None,
        blocks=tuple(blocks),
        install_order=state.install_order + (block_id,),
    )


def _trigger(level: Level, state: State) -> State:
    if not state.install_order:
        return state

    carrier_id = state.install_order[0]
    carrier_index = carrier_id - 1
    carrier = state.blocks[carrier_index]
    if carrier.vector is None:
        raise ValueError(
            f"State invariant broken: installed block {carrier_id} has no vector."
        )

    target = _add(carrier.position, carrier.vector.delta)
    if not _block_path_is_open(level, carrier.position, target):
        return state
    if target == state.player:
        return state

    front_block_index = _find_block_at(state, target)
    blocks = list(state.blocks)
    if front_block_index is None:
        blocks[carrier_index] = BlockState(target)
    else:
        pushed_target = _add(target, carrier.vector.delta)
        if not _block_can_move_to(level, state, target, pushed_target):
            return state
        blocks[front_block_index] = replace(
            blocks[front_block_index],
            position=pushed_target,
        )
        blocks[carrier_index] = replace(carrier, vector=None)

    return replace(
        state,
        blocks=tuple(blocks),
        install_order=state.install_order[1:],
    )


def _player_can_cross(level: Level, first: Position, second: Position) -> bool:
    return _block_path_is_open(level, first, second)


def _block_path_is_open(level: Level, first: Position, second: Position) -> bool:
    return (
        level.contains(second)
        and second not in level.walls
        and not level.has_fence(first, second)
    )


def _block_can_move_to(
    level: Level,
    state: State,
    first: Position,
    second: Position,
) -> bool:
    return (
        _block_path_is_open(level, first, second)
        and _find_block_at(state, second) is None
        and second != state.player
    )


def _find_block_at(state: State, position: Position) -> int | None:
    for index, block in enumerate(state.blocks):
        if block.position == position:
            return index
    return None


def _add(first: Position, second: Position) -> Position:
    return first[0] + second[0], first[1] + second[1]
