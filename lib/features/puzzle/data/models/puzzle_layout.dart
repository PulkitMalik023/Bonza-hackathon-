import 'dart:math';

import 'grid_cell.dart';
import 'placed_word.dart';

class PuzzleLayout {
  const PuzzleLayout({
    required this.placedWords,
    required this.minRow,
    required this.maxRow,
    required this.minCol,
    required this.maxCol,
  });

  final List<PlacedWord> placedWords;
  final int minRow;
  final int maxRow;
  final int minCol;
  final int maxCol;

  List<GridCell> get occupiedCells => buildOccupiedCells(placedWords);

  static List<GridCell> buildOccupiedCells(List<PlacedWord> placements) {
    final occupied = <String, String>{};

    for (final placed in placements) {
      for (var index = 0; index < placed.word.length; index++) {
        final cell = _cellForLetter(placed, index);
        occupied['${cell.row},${cell.col}'] = placed.word[index];
      }
    }

    final cells = occupied.entries.map((entry) {
      final parts = entry.key.split(',');
      return GridCell(
        row: int.parse(parts[0]),
        col: int.parse(parts[1]),
        letter: entry.value,
      );
    }).toList();

    cells.sort((a, b) {
      final rowCompare = a.row.compareTo(b.row);
      if (rowCompare != 0) {
        return rowCompare;
      }
      return a.col.compareTo(b.col);
    });

    return List.unmodifiable(cells);
  }

  static ({int row, int col}) _cellForLetter(
    PlacedWord placed,
    int letterIndex,
  ) {
    switch (placed.direction) {
      case WordDirection.horizontal:
        return (row: placed.row, col: placed.col + letterIndex);
      case WordDirection.vertical:
        return (row: placed.row + letterIndex, col: placed.col);
    }
  }

  static PuzzleLayout fromPlacedWords(List<PlacedWord> rawPlacements) {
    return normalize(rawPlacements);
  }

  static PuzzleLayout normalize(List<PlacedWord> rawPlacements) {
    if (rawPlacements.isEmpty) {
      return const PuzzleLayout(
        placedWords: [],
        minRow: 0,
        maxRow: 0,
        minCol: 0,
        maxCol: 0,
      );
    }

    var minRow = rawPlacements.first.row;
    var maxRow = rawPlacements.first.row;
    var minCol = rawPlacements.first.col;
    var maxCol = rawPlacements.first.col;

    for (final placed in rawPlacements) {
      final endRow = placed.direction == WordDirection.horizontal
          ? placed.row
          : placed.row + placed.word.length - 1;
      final endCol = placed.direction == WordDirection.horizontal
          ? placed.col + placed.word.length - 1
          : placed.col;

      minRow = min(minRow, placed.row);
      maxRow = max(maxRow, endRow);
      minCol = min(minCol, placed.col);
      maxCol = max(maxCol, endCol);
    }

    final normalizedWords = rawPlacements
        .map(
          (placed) => PlacedWord(
            word: placed.word,
            row: placed.row - minRow,
            col: placed.col - minCol,
            direction: placed.direction,
          ),
        )
        .toList();

    return PuzzleLayout(
      placedWords: List.unmodifiable(normalizedWords),
      minRow: 0,
      maxRow: maxRow - minRow,
      minCol: 0,
      maxCol: maxCol - minCol,
    );
  }

  static String signature(PuzzleLayout layout) {
    final sorted = [...layout.placedWords]
      ..sort((a, b) {
        final wordCompare = a.word.compareTo(b.word);
        if (wordCompare != 0) {
          return wordCompare;
        }
        final rowCompare = a.row.compareTo(b.row);
        if (rowCompare != 0) {
          return rowCompare;
        }
        final colCompare = a.col.compareTo(b.col);
        if (colCompare != 0) {
          return colCompare;
        }
        return a.direction.index.compareTo(b.direction.index);
      });

    return sorted
        .map(
          (placed) =>
              '${placed.word}|${placed.row}|${placed.col}|${placed.direction.name}',
        )
        .join(';');
  }
}
