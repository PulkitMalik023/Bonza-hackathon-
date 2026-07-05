"""Shared puzzle layout + chunk validation for screenshot-authored content."""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class Dir(Enum):
    H = "horizontal"
    V = "vertical"


@dataclass(frozen=True)
class Placement:
    word: str
    row: int
    col: int
    direction: Dir


def cells_for_placement(p: Placement) -> list[tuple[int, int, str]]:
    out: list[tuple[int, int, str]] = []
    for i, ch in enumerate(p.word):
        if p.direction == Dir.H:
            out.append((p.row, p.col + i, ch))
        else:
            out.append((p.row + i, p.col, ch))
    return out


def build_layout(placements: list[Placement]) -> tuple[list[dict], list[dict]]:
    cells: dict[tuple[int, int], str] = {}
    for placement in placements:
        for row, col, letter in cells_for_placement(placement):
            key = (row, col)
            if key in cells and cells[key] != letter:
                raise ValueError(f"Letter clash at {key}")
            cells[key] = letter

    placement_json = [
        {
            "word": p.word,
            "row": p.row,
            "col": p.col,
            "direction": p.direction.value,
        }
        for p in placements
    ]
    cells_json = [
        {"row": row, "col": col, "letter": letter}
        for (row, col), letter in sorted(cells.items())
    ]
    return placement_json, cells_json


def chunk_signature(cells: list[tuple[int, int, str]]) -> str:
    min_r = min(r for r, _, _ in cells)
    min_c = min(c for _, c, _ in cells)
    norm = sorted(
        ((r - min_r, c - min_c, ch.upper()) for r, c, ch in cells),
        key=lambda x: (x[0], x[1]),
    )
    return "|".join(f"{r},{c}:{ch}" for r, c, ch in norm)


def is_connected(coords: set[tuple[int, int]]) -> bool:
    if not coords:
        return False
    start = next(iter(coords))
    stack = [start]
    seen = {start}
    while stack:
        r, c = stack.pop()
        for dr, dc in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            n = (r + dr, c + dc)
            if n in coords and n not in seen:
                seen.add(n)
                stack.append(n)
    return seen == coords


def validate_puzzle(
    puzzle_id: int,
    placements: list[Placement],
    chunks: list[list[tuple[int, int, str]]],
) -> None:
    _, cells_json = build_layout(placements)
    letter_map = {(c["row"], c["col"]): c["letter"] for c in cells_json}
    all_cells = set(letter_map.keys())

    assigned: set[tuple[int, int]] = set()
    signatures: list[str] = []

    crossings: set[tuple[int, int]] = set()
    pos_count: dict[tuple[int, int], int] = {}
    for p in placements:
        for row, col, _ in cells_for_placement(p):
            pos_count[(row, col)] = pos_count.get((row, col), 0) + 1
    crossings = {pos for pos, count in pos_count.items() if count > 1}

    for i, chunk in enumerate(chunks):
        coords = {(r, c) for r, c, _ in chunk}
        if not coords.issubset(all_cells):
            missing = coords - all_cells
            raise ValueError(f"Puzzle {puzzle_id} chunk {i} has invalid cells {missing}")
        if not is_connected(coords):
            raise ValueError(f"Puzzle {puzzle_id} chunk {i} disconnected")
        if assigned & coords:
            raise ValueError(f"Puzzle {puzzle_id} chunk {i} overlaps")
        assigned |= coords

        for r, c, ch in chunk:
            if letter_map[(r, c)].upper() != ch.upper():
                raise ValueError(
                    f"Puzzle {puzzle_id} chunk {i} letter mismatch at {(r, c)}"
                )

        sig = chunk_signature(chunk)
        if sig in signatures:
            raise ValueError(f"Puzzle {puzzle_id} duplicate signature {sig}")
        signatures.append(sig)

        if len(chunk) == 1:
            pos = next(iter(coords))
            if pos in crossings:
                raise ValueError(f"Puzzle {puzzle_id} singleton at crossing {coords}")

    if assigned != all_cells:
        missing = all_cells - assigned
        raise ValueError(f"Puzzle {puzzle_id} incomplete coverage: {sorted(missing)}")

    _validate_singleton_letter_conflicts(puzzle_id, chunks)


def _chunk_neighbors(
    row: int, col: int, coords: set[tuple[int, int]]
) -> int:
    count = 0
    for dr, dc in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        if (row + dr, col + dc) in coords:
            count += 1
    return count


def _validate_singleton_letter_conflicts(
    puzzle_id: int,
    chunks: list[list[tuple[int, int, str]]],
) -> None:
    for i, chunk in enumerate(chunks):
        if len(chunk) != 1:
            continue

        singleton_letter = chunk[0][2].upper()

        for j, other in enumerate(chunks):
            if len(other) <= 1:
                continue

            coords = {(r, c) for r, c, _ in other}
            for row, col, letter in other:
                if letter.upper() != singleton_letter:
                    continue
                if _chunk_neighbors(row, col, coords) <= 1:
                    raise ValueError(
                        f"Puzzle {puzzle_id} ambiguous letters: {singleton_letter}"
                    )


def make_definition(
    puzzle_id: int,
    placements: list[Placement],
    chunks: list[list[tuple[int, int, str]]],
) -> dict:
    validate_puzzle(puzzle_id, placements, chunks)
    placement_json, cells_json = build_layout(placements)
    return {
        "puzzleId": puzzle_id,
        "layout": {
            "placements": placement_json,
            "cells": cells_json,
        },
        "chunks": [
            {
                "id": f"chunk_{i}",
                "cells": [
                    {"row": r, "col": c, "letter": ch}
                    for r, c, ch in chunk
                ],
            }
            for i, chunk in enumerate(chunks)
        ],
    }


def parse_direction(value: str) -> Dir:
    normalized = value.strip().lower()
    if normalized in {"horizontal", "h"}:
        return Dir.H
    if normalized in {"vertical", "v"}:
        return Dir.V
    raise ValueError(f"Unknown direction: {value}")


def parse_placement(entry: dict) -> Placement:
    return Placement(
        word=entry["word"],
        row=int(entry["row"]),
        col=int(entry["col"]),
        direction=parse_direction(entry["direction"]),
    )


def parse_chunk_cells(chunk: list) -> list[tuple[int, int, str]]:
    cells: list[tuple[int, int, str]] = []
    for cell in chunk:
        if isinstance(cell, list) and len(cell) == 3:
            row, col, letter = cell
            cells.append((int(row), int(col), str(letter)))
            continue
        if isinstance(cell, dict):
            cells.append(
                (int(cell["row"]), int(cell["col"]), str(cell["letter"]))
            )
            continue
        raise ValueError(f"Unsupported chunk cell format: {cell!r}")
    return cells
