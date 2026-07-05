#!/usr/bin/env python3
"""Build puzzles.json and puzzle_definitions.json from screenshot-authored puzzles."""

from __future__ import annotations

import json
from pathlib import Path

from puzzle_authoring import Dir, Placement, make_definition

ROOT = Path(__file__).resolve().parent.parent
PUZZLES_JSON = ROOT / "assets/data/puzzles.json"
OUTPUT_JSON = ROOT / "assets/data/puzzle_definitions.json"

PUZZLES = [
    {
        "id": 1,
        "category": "Fruit Salad",
        "words": ["BANANA", "ORANGE", "APPLE"],
        "enabled": True,
        "placements": [
            Placement("BANANA", 2, 0, Dir.H),
            Placement("ORANGE", 0, 1, Dir.V),
            Placement("APPLE", 2, 3, Dir.V),
        ],
        "chunks": [
            [(0, 1, "O"), (1, 1, "R"), (2, 0, "B"), (2, 1, "A"), (2, 2, "N")],
            [(2, 3, "A"), (2, 4, "N"), (2, 5, "A"), (3, 3, "P")],
            [(3, 1, "N"), (4, 1, "G"), (5, 1, "E")],
            [(4, 3, "P"), (5, 3, "L"), (6, 3, "E")],
        ],
    },
    {
        "id": 2,
        "category": "Compass",
        "words": ["NORTH", "SOUTH", "EAST", "WEST"],
        "enabled": True,
        "placements": [
            Placement("NORTH", 1, 2, Dir.H),
            Placement("SOUTH", 0, 3, Dir.V),
            Placement("WEST", 3, 0, Dir.H),
            Placement("EAST", 3, 1, Dir.V),
        ],
        "chunks": [
            [(0, 3, "S"), (1, 2, "N"), (1, 3, "O")],
            [(1, 4, "R"), (1, 5, "T"), (1, 6, "H")],
            [(3, 0, "W"), (3, 1, "E"), (4, 1, "A")],
            [(2, 3, "U"), (3, 2, "S"), (3, 3, "T"), (4, 3, "H")],
            [(5, 1, "S"), (6, 1, "T")],
        ],
    },
    {
        "id": 3,
        "category": "Flowers",
        "words": ["DAFFODIL", "DAISY", "ROSE", "TULIP"],
        "enabled": True,
        "placements": [
            Placement("DAFFODIL", 3, 0, Dir.H),
            Placement("DAISY", 2, 1, Dir.V),
            Placement("ROSE", 2, 4, Dir.V),
            Placement("TULIP", 0, 6, Dir.V),
        ],
        "chunks": [
            [(5, 1, "S"), (6, 1, "Y")],
            [(3, 0, "D"), (2, 1, "D"), (3, 1, "A"), (4, 1, "I")],
            [(2, 4, "R"), (3, 2, "F"), (3, 3, "F"), (3, 4, "O")],
            [(4, 4, "S"), (5, 4, "E")],
            [(3, 5, "D"), (3, 6, "I"), (3, 7, "L"), (4, 6, "P")],
            [(0, 6, "T"), (1, 6, "U"), (2, 6, "L")],
        ],
    },
    {
        "id": 4,
        "category": "Planets",
        "words": ["VENUS", "JUPITER", "NEPTUNE", "SATURN", "MARS"],
        "enabled": True,
        "placements": [
            Placement("VENUS", 0, 0, Dir.H),
            Placement("JUPITER", 2, 0, Dir.H),
            Placement("NEPTUNE", 0, 2, Dir.V),
            Placement("SATURN", 0, 4, Dir.V),
            Placement("MARS", 0, 6, Dir.V),
        ],
        "chunks": [
            [(0, 0, "V"), (0, 1, "E"), (0, 2, "N"), (1, 2, "E")],
            [(0, 3, "U"), (0, 4, "S"), (1, 4, "A")],
            [(0, 6, "M"), (1, 6, "A")],
            [(2, 0, "J"), (2, 1, "U"), (2, 2, "P"), (2, 3, "I"), (3, 2, "T")],
            [(2, 4, "T"), (2, 5, "E"), (2, 6, "R"), (3, 6, "S")],
            [(4, 2, "U"), (5, 2, "N"), (6, 2, "E")],
            [(3, 4, "U"), (4, 4, "R"), (5, 4, "N")],
        ],
    },
    {
        "id": 5,
        "category": "Battle of Hands",
        "words": ["SCISSORS", "ROCK", "PAPER"],
        "enabled": True,
        "placements": [
            Placement("SCISSORS", 4, 0, Dir.H),
            Placement("ROCK", 2, 1, Dir.V),
            Placement("PAPER", 0, 6, Dir.V),
        ],
        "chunks": [
            [(2, 1, "R"), (3, 1, "O")],
            [(0, 6, "P"), (1, 6, "A"), (2, 6, "P")],
            [(4, 0, "S"), (4, 1, "C"), (4, 2, "I"), (5, 1, "K")],
            [(4, 3, "S"), (4, 4, "S"), (4, 5, "O")],
            [(3, 6, "E"), (4, 6, "R"), (4, 7, "S")],
        ],
    },
    {
        "id": 6,
        "category": "Cutlery",
        "words": ["SPOON", "FORK", "KNIFE"],
        "enabled": True,
        "placements": [
            Placement("SPOON", 0, 1, Dir.V),
            Placement("FORK", 2, 0, Dir.H),
            Placement("KNIFE", 4, 0, Dir.H),
        ],
        "chunks": [
            [(0, 1, "S"), (1, 1, "P")],
            [(2, 0, "F"), (2, 1, "O"), (3, 1, "O")],
            [(2, 2, "R"), (2, 3, "K")],
            [(4, 0, "K"), (4, 1, "N")],
            [(4, 2, "I"), (4, 3, "F"), (4, 4, "E")],
        ],
    },
    {
        "id": 8,
        "category": "Nuts",
        "words": ["CASHEW", "ALMOND", "PEANUT"],
        "enabled": True,
        "placements": [
            Placement("PEANUT", 0, 4, Dir.V),
            Placement("CASHEW", 1, 0, Dir.H),
            Placement("ALMOND", 3, 0, Dir.H),
        ],
        "chunks": [
            [(4, 4, "U"), (5, 4, "T")],
            [(1, 0, "C"), (1, 1, "A"), (1, 2, "S")],
            [(3, 0, "A"), (3, 1, "L"), (3, 2, "M")],
            [(2, 4, "A"), (3, 3, "O"), (3, 4, "N"), (3, 5, "D")],
            [(0, 4, "P"), (1, 3, "H"), (1, 4, "E"), (1, 5, "W")],
        ],
    },
]


def main() -> None:
    puzzles_meta = []
    definitions = []

    for puzzle in PUZZLES:
        puzzles_meta.append(
            {
                "id": puzzle["id"],
                "category": puzzle["category"],
                "words": puzzle["words"],
                "enabled": puzzle["enabled"],
            }
        )
        definitions.append(
            make_definition(
                puzzle["id"],
                puzzle["placements"],
                puzzle["chunks"],
            )
        )

    PUZZLES_JSON.write_text(json.dumps(puzzles_meta, indent=2) + "\n")
    OUTPUT_JSON.write_text(json.dumps(definitions, indent=2) + "\n")
    print(f"Wrote {len(puzzles_meta)} puzzles to {PUZZLES_JSON}")
    print(f"Wrote {len(definitions)} definitions to {OUTPUT_JSON}")


if __name__ == "__main__":
    main()
