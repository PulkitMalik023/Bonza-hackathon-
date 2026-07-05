#!/usr/bin/env python3
"""Validate screenshot-authored chunk JSON and emit a PUZZLES entry."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from puzzle_authoring import (
    Dir,
    make_definition,
    parse_chunk_cells,
    parse_placement,
    validate_puzzle,
)

ROOT = Path(__file__).resolve().parent.parent


def load_puzzle(path: Path) -> dict:
    return json.loads(path.read_text())


def format_placement(p) -> str:
    direction = "Dir.H" if p.direction == Dir.H else "Dir.V"
    return f'Placement("{p.word}", {p.row}, {p.col}, {direction})'


def format_chunk(chunk: list[tuple[int, int, str]]) -> str:
    cells = ", ".join(f'({r}, {c}, "{ch}")' for r, c, ch in chunk)
    return f"[{cells}]"


def emit_puzzles_entry(data: dict, placements, chunks) -> str:
    puzzle_id = int(data["puzzleId"])
    category = data["category"]
    words = data["words"]
    enabled = data.get("enabled", True)

    placement_lines = ",\n            ".join(
        format_placement(p) for p in placements
    )
    chunk_lines = ",\n            ".join(format_chunk(chunk) for chunk in chunks)

    return f"""    {{
        "id": {puzzle_id},
        "category": {json.dumps(category)},
        "words": {json.dumps(words)},
        "enabled": {json.dumps(enabled)},
        "placements": [
            {placement_lines}
        ],
        "chunks": [
            {chunk_lines}
        ],
    }}"""


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <puzzle.json>", file=sys.stderr)
        return 1

    path = Path(sys.argv[1])
    if not path.is_file():
        print(f"File not found: {path}", file=sys.stderr)
        return 1

    data = load_puzzle(path)

    required = ["puzzleId", "category", "words", "placements", "chunks"]
    missing = [key for key in required if key not in data]
    if missing:
        print(f"Missing required fields: {', '.join(missing)}", file=sys.stderr)
        return 1

    puzzle_id = int(data["puzzleId"])
    placements = [parse_placement(entry) for entry in data["placements"]]
    chunks = [parse_chunk_cells(chunk) for chunk in data["chunks"]]

    validate_puzzle(puzzle_id, placements, chunks)
    definition = make_definition(puzzle_id, placements, chunks)

    print(f"OK: puzzle {puzzle_id} ({data['category']})")
    print(f"  words: {len(data['words'])}")
    print(f"  chunks: {len(chunks)}")
    print(f"  layout cells: {len(definition['layout']['cells'])}")
    print()
    print("Paste this entry into PUZZLES in tool/build_screenshot_puzzles.py:")
    print(emit_puzzles_entry(data, placements, chunks))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
