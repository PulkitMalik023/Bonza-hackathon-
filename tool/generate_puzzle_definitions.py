#!/usr/bin/env python3
"""Generate assets/data/puzzle_definitions.json from puzzle word lists."""

from __future__ import annotations

import json
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUZZLES_JSON = ROOT / "assets/data/puzzles.json"
OUTPUT_JSON = ROOT / "assets/data/puzzle_definitions.json"

LAYOUT_OVERRIDE: dict[int, int] = {
    11: 1,
    27: 6,
    34: 1,
}

# Hand-authored chunk partitions for layouts where auto-decon fails quality rules.
MANUAL_CHUNKS: dict[int, list[list[tuple[int, int]]]] = {
    25: [
        [(0, 5), (1, 5)],
        [(2, 0), (2, 1), (2, 2)],
        [(2, 3), (2, 4), (2, 5), (3, 3)],
        [(0, 3), (1, 3)],
        [(3, 0), (4, 0)],
        [(5, 0), (6, 0)],
    ],
}


class Dir(Enum):
    H = 0
    V = 1


@dataclass(frozen=True)
class Placed:
    word: str
    row: int
    col: int
    direction: Dir


def cell_for(p: Placed, i: int) -> tuple[int, int]:
    if p.direction == Dir.H:
        return p.row, p.col + i
    return p.row + i, p.col


def cell_key(r: int, c: int) -> str:
    return f"{r},{c}"


def normalize(placements: list[Placed]) -> tuple[list[Placed], int, int]:
    coords = [cell_for(p, i) for p in placements for i in range(len(p.word))]
    min_r = min(r for r, _ in coords)
    min_c = min(c for _, c in coords)
    max_r = max(r for r, _ in coords)
    max_c = max(c for _, c in coords)
    norm = [
        Placed(p.word, p.row - min_r, p.col - min_c, p.direction)
        for p in placements
    ]
    return norm, max_r - min_r, max_c - min_c


def signature(layout: list[Placed]) -> str:
    parts = sorted((p.word, p.row, p.col, p.direction.name) for p in layout)
    return ";".join(f"{w}|{r}|{c}|{d}" for w, r, c, d in parts)


def can_place(word: str, placement: Placed, occupied: dict[str, str]) -> bool:
    overlaps = False
    for i, ch in enumerate(word):
        r, c = cell_for(placement, i)
        existing = occupied.get(cell_key(r, c))
        if existing is not None:
            if existing != ch:
                return False
            overlaps = True
        elif placement.direction == Dir.H:
            if occupied.get(cell_key(r - 1, c)) or occupied.get(cell_key(r + 1, c)):
                return False
        else:
            if occupied.get(cell_key(r, c - 1)) or occupied.get(cell_key(r, c + 1)):
                return False
    if not overlaps:
        return False
    if placement.direction == Dir.H:
        return not occupied.get(cell_key(placement.row, placement.col - 1)) and not occupied.get(
            cell_key(placement.row, placement.col + len(word))
        )
    return not occupied.get(cell_key(placement.row - 1, placement.col)) and not occupied.get(
        cell_key(placement.row + len(word), placement.col)
    )


def apply_word(placement: Placed, occupied: dict[str, str]) -> None:
    for i, ch in enumerate(placement.word):
        r, c = cell_for(placement, i)
        occupied[cell_key(r, c)] = ch


def remove_word(
    placement: Placed,
    occupied: dict[str, str],
    remaining: list[Placed],
) -> None:
    for i in range(len(placement.word)):
        r, c = cell_for(placement, i)
        key = cell_key(r, c)
        if not any(cell_for(p, j) == (r, c) for p in remaining for j in range(len(p.word))):
            occupied.pop(key, None)


def candidates(new_word: str, placements: list[Placed]) -> list[Placed]:
    seen: set[tuple[int, int, Dir]] = set()
    out: list[Placed] = []
    for placed in placements:
        for ni, nc in enumerate(new_word):
            for pi, pc in enumerate(placed.word):
                if nc != pc:
                    continue
                if placed.direction == Dir.H:
                    cross_r, cross_c = placed.row, placed.col + pi
                    cand = Placed(new_word, cross_r - ni, cross_c, Dir.V)
                else:
                    cross_r, cross_c = placed.row + pi, placed.col
                    cand = Placed(new_word, cross_r, cross_c - ni, Dir.H)
                key = (cand.row, cand.col, cand.direction)
                if key not in seen:
                    seen.add(key)
                    out.append(cand)
    out.sort(key=lambda p: (p.row, p.col, p.direction.value))
    return out


def can_connect(words: list[str]) -> bool:
    if len(words) <= 1:
        return True
    adj = [set() for _ in words]
    for i, w in enumerate(words):
        letters = set(w)
        for j in range(i + 1, len(words)):
            if letters & set(words[j]):
                adj[i].add(j)
                adj[j].add(i)
    visited = {0}
    queue = [0]
    while queue:
        cur = queue.pop(0)
        for nxt in adj[cur]:
            if nxt not in visited:
                visited.add(nxt)
                queue.append(nxt)
    return len(visited) == len(words)


def generate_all_layouts(words: list[str]) -> list[list[Placed]]:
    normalized = [w.upper() for w in words]
    if not can_connect(normalized):
        return []
    sorted_words = sorted(normalized, key=lambda w: (-len(w), w))
    occupied: dict[str, str] = {}
    placements = [Placed(sorted_words[0], 0, 0, Dir.H)]
    apply_word(placements[0], occupied)
    results: list[list[Placed]] = []
    seen: set[str] = set()

    def backtrack(idx: int) -> None:
        if idx >= len(sorted_words) - 1:
            norm, _, _ = normalize(placements)
            sig = signature(norm)
            if sig not in seen:
                seen.add(sig)
                results.append(norm)
            return
        word = sorted_words[idx + 1]
        for cand in candidates(word, placements):
            if not can_place(word, cand, occupied):
                continue
            apply_word(cand, occupied)
            placements.append(cand)
            backtrack(idx + 1)
            placements.pop()
            remove_word(cand, occupied, placements)

    backtrack(0)
    return results


def cells_from_layout(layout: list[Placed]) -> dict[tuple[int, int], str]:
    cells: dict[tuple[int, int], str] = {}
    for placed in layout:
        for i, ch in enumerate(placed.word):
            cells[cell_for(placed, i)] = ch
    return cells


def crossing_positions(layout: list[Placed]) -> set[tuple[int, int]]:
    counts: dict[tuple[int, int], int] = {}
    for placed in layout:
        for i in range(len(placed.word)):
            pos = cell_for(placed, i)
            counts[pos] = counts.get(pos, 0) + 1
    return {pos for pos, count in counts.items() if count > 1}


def chunk_signature(
    chunk: list[tuple[int, int]],
    letter_map: dict[tuple[int, int], str],
) -> str:
    min_r = min(r for r, _ in chunk)
    min_c = min(c for _, c in chunk)
    entries = sorted(
        (r - min_r, c - min_c, letter_map[(r, c)].upper()) for r, c in chunk
    )
    return "|".join(f"{r},{c}:{ch}" for r, c, ch in entries)


def is_connected(cells: set[tuple[int, int]]) -> bool:
    if len(cells) <= 1:
        return True
    start = next(iter(cells))
    visited = {start}
    queue = [start]
    while queue:
        r, c = queue.pop(0)
        for nr, nc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
            if (nr, nc) in cells and (nr, nc) not in visited:
                visited.add((nr, nc))
                queue.append((nr, nc))
    return len(visited) == len(cells)


def validate_chunks(
    chunks: list[list[tuple[int, int]]],
    letter_map: dict[tuple[int, int], str],
    crossings: set[tuple[int, int]],
) -> tuple[bool, str]:
    all_cells = set(letter_map.keys())
    assigned: set[tuple[int, int]] = set()
    signatures: list[str] = []
    multi_letters: set[str] = set()
    single_letters: set[str] = set()

    for chunk in chunks:
        chunk_set = set(chunk)
        if not chunk_set or not chunk_set.issubset(all_cells):
            return False, "invalid cells"
        if not is_connected(chunk_set):
            return False, "disconnected chunk"
        if assigned & chunk_set:
            return False, "overlap"
        assigned |= chunk_set
        sig = chunk_signature(chunk, letter_map)
        if sig in signatures:
            return False, f"duplicate signature {sig}"
        signatures.append(sig)
        letters = {letter_map[c].upper() for c in chunk}
        if len(chunk) > 1:
            multi_letters |= letters
        else:
            single_letters |= letters
        if len(chunk) == 1 and chunk[0] in crossings:
            return False, "singleton crossing"

    if assigned != all_cells:
        return False, "incomplete coverage"
    if single_letters & multi_letters:
        return False, "ambiguous letters"
    return True, "ok"


def auto_deconstruct(
    letter_map: dict[tuple[int, int], str],
    crossings: set[tuple[int, int]],
) -> list[list[tuple[int, int]]] | None:
    remaining = set(letter_map.keys())

    def adjacent(cell: tuple[int, int]) -> list[tuple[int, int]]:
        r, c = cell
        return [
            (r - 1, c),
            (r + 1, c),
            (r, c - 1),
            (r, c + 1),
        ]

    def remainder_connected(candidate: set[tuple[int, int]], rem: set[tuple[int, int]]) -> bool:
        rest = rem - candidate
        return not rest or is_connected(rest)

    def grow(seed: tuple[int, int], rem: set[tuple[int, int]], target: int) -> set[tuple[int, int]] | None:
        cand = {seed}
        frontier = [seed]
        while len(cand) < target and frontier:
            neighbors = sorted(
                {
                    n
                    for cell in frontier
                    for n in adjacent(cell)
                    if n in rem and n not in cand
                }
            )
            if not neighbors:
                break
            nxt = neighbors[0]
            cand.add(nxt)
            frontier.append(nxt)
        if len(cand) == 1 and len(rem) > 1:
            return None
        return cand

    chunks: list[list[tuple[int, int]]] = []
    while remaining:
        seed = min(remaining)
        target = 2 if len(remaining) == 2 else (2 if len(remaining) % 2 == 0 else 3)
        if len(remaining) > 2 and len(remaining) % 3 == 0:
            target = 3
        cand = grow(seed, remaining, target)
        if cand is None or not is_connected(cand) or not remainder_connected(cand, remaining):
            cand_set = None
            for s in sorted(remaining):
                for size in (3, 2, 1):
                    trial = grow(s, remaining, size)
                    if (
                        trial
                        and is_connected(trial)
                        and remainder_connected(trial, remaining)
                    ):
                        cand_set = trial
                        break
                if cand_set:
                    break
            if not cand_set:
                return None
            cand = cand_set
        chunk = sorted(cand)
        chunks.append(chunk)
        remaining -= set(chunk)

    ok, _ = validate_chunks(chunks, letter_map, crossings)
    return chunks if ok else None


def build_manual_chunks(puzzle_id: int) -> list[list[tuple[int, int]]] | None:
    return MANUAL_CHUNKS.get(puzzle_id)


def layout_to_json(layout: list[Placed], chunks: list[list[tuple[int, int]]], letter_map):
    return {
        "placements": [
            {
                "word": p.word,
                "row": p.row,
                "col": p.col,
                "direction": p.direction.name.lower(),
            }
            for p in layout
        ],
        "cells": [
            {"row": r, "col": c, "letter": letter_map[(r, c)]}
            for r, c in sorted(letter_map.keys())
        ],
        "chunks": [
            {
                "id": f"chunk_{index}",
                "cells": [
                    {"row": r, "col": c, "letter": letter_map[(r, c)]}
                    for r, c in chunk
                ],
            }
            for index, chunk in enumerate(chunks)
        ],
    }


def select_layout_and_chunks(puzzle_id: int, words: list[str]):
    layouts = generate_all_layouts(words)
    if not layouts:
        raise ValueError(f"No layout for puzzle {puzzle_id}")

    candidates: list[tuple[list[Placed], dict, set, list[list[tuple[int, int]]] | None]] = []
    for layout in layouts:
        letter_map = cells_from_layout(layout)
        crossings = crossing_positions(layout)
        chunks = auto_deconstruct(letter_map, crossings)
        candidates.append((layout, letter_map, crossings, chunks))

    preferred_index = LAYOUT_OVERRIDE.get(puzzle_id, 0)
    search_order = list(range(len(candidates)))
    if preferred_index in search_order:
        search_order.remove(preferred_index)
        search_order.insert(0, preferred_index)

    for index in search_order:
        layout, letter_map, crossings, chunks = candidates[index]
        if chunks is None:
            continue
        ok, reason = validate_chunks(chunks, letter_map, crossings)
        if ok:
            return layout, chunks, letter_map

    manual = build_manual_chunks(puzzle_id)
    if manual:
        layout, letter_map, crossings, _ = candidates[preferred_index if preferred_index < len(candidates) else 0]
        ok, reason = validate_chunks(manual, letter_map, crossings)
        if ok:
            return layout, manual, letter_map
        raise ValueError(f"Manual chunks invalid for {puzzle_id}: {reason}")

    raise ValueError(f"No valid chunks for puzzle {puzzle_id}")


def main() -> None:
    puzzles = json.loads(PUZZLES_JSON.read_text())
    enabled = [p for p in puzzles if p.get("enabled")]

    definitions = []
    failures = []

    for puzzle in enabled:
        pid = puzzle["id"]
        try:
            layout, chunks, letter_map = select_layout_and_chunks(pid, puzzle["words"])
            definitions.append(
                {
                    "puzzleId": pid,
                    **build_manual_chunks_definition(layout, chunks, letter_map),
                }
            )
            print(f"OK puzzle {pid}: {len(chunks)} chunks")
        except ValueError as err:
            failures.append((pid, str(err)))
            print(f"FAIL puzzle {pid}: {err}")

    if failures:
        raise SystemExit(f"Failed {len(failures)} puzzles: {failures}")

    OUTPUT_JSON.write_text(json.dumps(definitions, indent=2) + "\n")
    print(f"Wrote {len(definitions)} definitions to {OUTPUT_JSON}")


def build_manual_chunks_definition(layout, chunks, letter_map):
    return {
        "layout": {
            "placements": [
                {
                    "word": p.word,
                    "row": p.row,
                    "col": p.col,
                    "direction": "horizontal"
                    if p.direction == Dir.H
                    else "vertical",
                }
                for p in layout
            ],
            "cells": [
                {"row": r, "col": c, "letter": letter_map[(r, c)]}
                for r, c in sorted(letter_map.keys())
            ],
        },
        "chunks": [
            {
                "id": f"chunk_{index}",
                "cells": [
                    {"row": r, "col": c, "letter": letter_map[(r, c)]}
                    for r, c in chunk
                ],
            }
            for index, chunk in enumerate(chunks)
        ],
    }


if __name__ == "__main__":
    main()
