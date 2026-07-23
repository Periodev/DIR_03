"""Named level collections separated by a line of nine hyphens."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from .model import Level
from .parser import LevelParseError, parse_level

COLLECTION_SEPARATOR = re.compile(r"(?m)^\s*---------\s*$")


@dataclass(frozen=True, slots=True)
class NamedLevel:
    name: str
    level: Level


def load_level_collection(path: str | Path) -> tuple[NamedLevel, ...]:
    return parse_level_collection(Path(path).read_text(encoding="utf-8-sig"))


def parse_level_collection(source: str) -> tuple[NamedLevel, ...]:
    chunks = COLLECTION_SEPARATOR.split(
        source.replace("\r\n", "\n").replace("\r", "\n").strip()
    )
    levels: list[NamedLevel] = []

    for index, chunk in enumerate(chunks, start=1):
        lines = chunk.strip().splitlines()
        if len(lines) < 2:
            raise LevelParseError(
                f"Collection entry {index} must contain a name and map data."
            )

        name = lines[0].strip()
        if not name:
            raise LevelParseError(f"Collection entry {index} has an empty name.")
        try:
            level = parse_level("\n".join(lines[1:]))
        except LevelParseError as error:
            raise LevelParseError(f"Level '{name}': {error}") from error
        levels.append(NamedLevel(name, level))

    if not levels:
        raise LevelParseError("Level collection is empty.")
    return tuple(levels)
