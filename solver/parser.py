"""Parser for legacy ASCII maps and the !cell-edge-v1 format."""

from __future__ import annotations

from pathlib import Path

from .model import (
    BlockKind,
    BlockSpec,
    BlockState,
    Direction,
    Level,
    Position,
    State,
    canonical_edge,
)

EDGE_FORMAT_HEADER = "!cell-edge-v1"
SECTION_NAMES = ("cells", "horizontal_edges", "vertical_edges")


class LevelParseError(ValueError):
    """Raised when level text does not match a supported map format."""


def load_level(path: str | Path) -> Level:
    return parse_level(Path(path).read_text(encoding="utf-8-sig"))


def parse_level(source: str) -> Level:
    normalized = source.replace("\r\n", "\n").replace("\r", "\n").strip()
    if not normalized:
        raise LevelParseError("Map is empty.")

    lines = [line for line in normalized.split("\n") if line != ""]
    if lines[0].strip() == EDGE_FORMAT_HEADER:
        return _parse_cell_edge_map(lines)

    cells = _parse_cells(lines)
    return _build_level(cells)


def _parse_cell_edge_map(lines: list[str]) -> Level:
    sections: dict[str, list[str]] = {name: [] for name in SECTION_NAMES}
    seen_sections: set[str] = set()
    current_section: str | None = None

    for line_number, raw_line in enumerate(lines[1:], start=2):
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("[") and line.endswith("]"):
            section_name = line[1:-1]
            if section_name not in sections:
                raise LevelParseError(f"Unknown section '{line}'.")
            if section_name in seen_sections:
                raise LevelParseError(f"Section '{section_name}' appears more than once.")
            seen_sections.add(section_name)
            current_section = section_name
            continue
        if current_section is None:
            raise LevelParseError(
                f"Map data appears before a section header at line {line_number}."
            )
        sections[current_section].append(line)

    for section_name, section_lines in sections.items():
        if not section_lines:
            raise LevelParseError(f"Missing or empty section '[{section_name}]'.")

    cells = _parse_cells(sections["cells"])
    width = cells.width
    height = cells.height
    if width < 2 or height < 2:
        raise LevelParseError("!cell-edge-v1 maps must be at least 2 by 2 cells.")

    horizontal_rows = _parse_edge_rows(
        sections["horizontal_edges"],
        expected_rows=height - 1,
        expected_width=width,
        fence_symbol="-",
        section_name="horizontal_edges",
    )
    vertical_rows = _parse_edge_rows(
        sections["vertical_edges"],
        expected_rows=height,
        expected_width=width - 1,
        fence_symbol="|",
        section_name="vertical_edges",
    )

    fences: set[tuple[Position, Position]] = set()
    for y, row in enumerate(horizontal_rows):
        for x, has_fence in enumerate(row):
            if has_fence:
                fences.add(canonical_edge((x, y), (x, y + 1)))
    for y, row in enumerate(vertical_rows):
        for x, has_fence in enumerate(row):
            if has_fence:
                fences.add(canonical_edge((x, y), (x + 1, y)))

    return _build_level(cells, frozenset(fences))


class _ParsedCells:
    __slots__ = ("width", "height", "walls", "goals", "player", "specs", "blocks")

    def __init__(
        self,
        *,
        width: int,
        height: int,
        walls: frozenset[Position],
        goals: frozenset[Position],
        player: Position,
        specs: tuple[BlockSpec, ...],
        blocks: tuple[BlockState, ...],
    ) -> None:
        self.width = width
        self.height = height
        self.walls = walls
        self.goals = goals
        self.player = player
        self.specs = specs
        self.blocks = blocks


def _parse_cells(lines: list[str]) -> _ParsedCells:
    if not lines:
        raise LevelParseError("Map is empty.")

    stripped_lines = [line.strip() for line in lines]
    width = len(stripped_lines[0])
    if width <= 0:
        raise LevelParseError("Map rows cannot be empty.")

    walls: set[Position] = set()
    goals: set[Position] = set()
    player: Position | None = None
    specs: list[BlockSpec] = []
    blocks: list[BlockState] = []
    labels: set[str] = set()

    for y, line in enumerate(stripped_lines):
        if len(line) != width:
            raise LevelParseError(
                f"Map row {y} has width {len(line)}; expected {width}."
            )

        for x, symbol in enumerate(line):
            position = (x, y)
            if symbol == "#":
                walls.add(position)
            elif symbol == ".":
                continue
            elif symbol == "*":
                goals.add(position)
            elif symbol in ("@", "+"):
                if player is not None:
                    raise LevelParseError("Map contains more than one player (@ or +).")
                player = position
                if symbol == "+":
                    goals.add(position)
            elif symbol.isascii() and symbol.isalpha():
                label = symbol.upper()
                if label in labels:
                    raise LevelParseError(f"Block label '{label}' is duplicated.")
                labels.add(label)
                kind = BlockKind.RECOVERY if label >= "R" else BlockKind.NORMAL
                specs.append(BlockSpec(len(specs) + 1, label, kind))
                blocks.append(BlockState(position))
                if symbol.islower():
                    goals.add(position)
            else:
                raise LevelParseError(
                    f"Unsupported symbol '{symbol}' at ({x}, {y})."
                )

    if player is None:
        raise LevelParseError("Map must contain one player (@).")

    return _ParsedCells(
        width=width,
        height=len(stripped_lines),
        walls=frozenset(walls),
        goals=frozenset(goals),
        player=player,
        specs=tuple(specs),
        blocks=tuple(blocks),
    )


def _parse_edge_rows(
    lines: list[str],
    *,
    expected_rows: int,
    expected_width: int,
    fence_symbol: str,
    section_name: str,
) -> tuple[tuple[bool, ...], ...]:
    if len(lines) != expected_rows:
        raise LevelParseError(
            f"[{section_name}] has {len(lines)} rows; expected {expected_rows}."
        )

    result: list[tuple[bool, ...]] = []
    for y, line in enumerate(lines):
        if len(line) != expected_width:
            raise LevelParseError(
                f"[{section_name}] row {y} has width {len(line)}; "
                f"expected {expected_width}."
            )
        row: list[bool] = []
        for x, symbol in enumerate(line):
            if symbol == ".":
                row.append(False)
            elif symbol == fence_symbol:
                row.append(True)
            else:
                raise LevelParseError(
                    f"Unsupported [{section_name}] symbol '{symbol}' at ({x}, {y})."
                )
        result.append(tuple(row))
    return tuple(result)


def _build_level(
    cells: _ParsedCells,
    fences: frozenset[tuple[Position, Position]] = frozenset(),
) -> Level:
    initial_state = State(
        player=cells.player,
        facing=_facing_toward_nearest_block(cells.player, cells.blocks),
        queue=None,
        blocks=cells.blocks,
    )
    return Level(
        width=cells.width,
        height=cells.height,
        walls=cells.walls,
        goals=cells.goals,
        fences=fences,
        block_specs=cells.specs,
        initial_state=initial_state,
    )


def _facing_toward_nearest_block(
    player: Position,
    blocks: tuple[BlockState, ...],
) -> Direction:
    if not blocks:
        return Direction.RIGHT

    nearest = min(
        blocks,
        key=lambda block: abs(block.position[0] - player[0])
        + abs(block.position[1] - player[1]),
    )
    dx = nearest.position[0] - player[0]
    dy = nearest.position[1] - player[1]
    if abs(dx) >= abs(dy) and dx != 0:
        return Direction.RIGHT if dx > 0 else Direction.LEFT
    return Direction.DOWN if dy > 0 else Direction.UP
