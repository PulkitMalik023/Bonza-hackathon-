import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/generated_puzzle_layout.dart';
import '../models/grid_cell.dart';
import '../models/puzzle_content.dart';
import '../models/word_placement.dart';

class PuzzleLayoutGenerator {
  GeneratedPuzzleLayout generate(PuzzleContent content) {
    final words = content.words.map((word) => word.toUpperCase()).toList();
    final puzzleId = content.id.toString();

    if (words.isEmpty) {
      throw StateError(
        'Could not generate connected layout for puzzle $puzzleId',
      );
    }

    if (!_canPotentiallyConnect(words)) {
      throw StateError(
        'Puzzle $puzzleId words cannot form a connected graph '
        '(no shared letters between components)',
      );
    }

    final sortedWords = [...words]
      ..sort((a, b) {
        final lengthCompare = b.length.compareTo(a.length);
        if (lengthCompare != 0) {
          return lengthCompare;
        }
        return a.compareTo(b);
      });

    debugPrint(
      '[PuzzleLayoutGenerator] Generating layout for $puzzleId '
      '(${content.category}) with words: $sortedWords',
    );

    final occupied = <String, String>{};
    final placements = <WordPlacement>[];

    final seedWord = sortedWords.first;
    final seedPlacement = WordPlacement(
      word: seedWord,
      startRow: 0,
      startCol: 0,
      direction: WordDirection.horizontal,
    );
    _applyWord(seedPlacement, occupied);
    placements.add(seedPlacement);
    debugPrint('[PuzzleLayoutGenerator] Seed placement: $seedPlacement');

    final remainingWords = sortedWords.sublist(1);
    final success = _backtrackPlaceWords(
      remainingWords: remainingWords,
      wordIndex: 0,
      placements: placements,
      occupied: occupied,
    );

    if (!success) {
      throw StateError(
        'Could not generate connected layout for puzzle $puzzleId',
      );
    }

    final occupiedCells = _buildOccupiedCells(occupied);
    final bounds = _computeBounds(occupiedCells);

    debugPrint('[PuzzleLayoutGenerator] Final placements for $puzzleId:');
    for (final placement in placements) {
      debugPrint('  $placement');
    }
    debugPrint(
      '[PuzzleLayoutGenerator] Bounds: '
      'rows ${bounds.minRow}..${bounds.maxRow}, '
      'cols ${bounds.minCol}..${bounds.maxCol}, '
      'occupied cells: ${occupiedCells.length}',
    );

    return GeneratedPuzzleLayout(
      puzzleId: puzzleId,
      category: content.category,
      words: sortedWords,
      placements: List.unmodifiable(placements),
      occupiedCells: List.unmodifiable(occupiedCells),
      minRow: bounds.minRow,
      maxRow: bounds.maxRow,
      minCol: bounds.minCol,
      maxCol: bounds.maxCol,
    );
  }

  bool _canPotentiallyConnect(List<String> words) {
    if (words.length <= 1) {
      return true;
    }

    final adjacency = List.generate(words.length, (_) => <int>{});

    for (var i = 0; i < words.length; i++) {
      final lettersI = words[i].split('').toSet();
      for (var j = i + 1; j < words.length; j++) {
        final lettersJ = words[j].split('').toSet();
        if (lettersI.intersection(lettersJ).isNotEmpty) {
          adjacency[i].add(j);
          adjacency[j].add(i);
        }
      }
    }

    final visited = <int>{0};
    final queue = <int>[0];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final neighbor in adjacency[current]) {
        if (visited.add(neighbor)) {
          queue.add(neighbor);
        }
      }
    }

    final connected = visited.length == words.length;
    debugPrint(
      '[PuzzleLayoutGenerator] Connectivity pre-check: '
      '${connected ? "passed" : "failed"} (${visited.length}/${words.length})',
    );
    return connected;
  }

  bool _backtrackPlaceWords({
    required List<String> remainingWords,
    required int wordIndex,
    required List<WordPlacement> placements,
    required Map<String, String> occupied,
  }) {
    if (wordIndex >= remainingWords.length) {
      return true;
    }

    final word = remainingWords[wordIndex];
    final candidates = _generateCandidates(word, placements);

    debugPrint(
      '[PuzzleLayoutGenerator] Placing "$word" with ${candidates.length} candidates',
    );

    for (final candidate in candidates) {
      if (!_canPlaceWord(word, candidate, occupied)) {
        continue;
      }

      _applyWord(candidate, occupied);
      placements.add(candidate);
      debugPrint('[PuzzleLayoutGenerator] Trying: $candidate');

      if (_backtrackPlaceWords(
        remainingWords: remainingWords,
        wordIndex: wordIndex + 1,
        placements: placements,
        occupied: occupied,
      )) {
        return true;
      }

      placements.removeLast();
      _removeWord(candidate, occupied, placements);
      debugPrint('[PuzzleLayoutGenerator] Backtracking from: $candidate');
    }

    return false;
  }

  List<WordPlacement> _generateCandidates(
    String newWord,
    List<WordPlacement> placements,
  ) {
    final candidates = <WordPlacement>[];
    final seen = <String>{};

    for (var placedIndex = 0; placedIndex < placements.length; placedIndex++) {
      final placed = placements[placedIndex];
      for (var newLetterIndex = 0; newLetterIndex < newWord.length; newLetterIndex++) {
        for (var placedLetterIndex = 0;
            placedLetterIndex < placed.word.length;
            placedLetterIndex++) {
          if (newWord[newLetterIndex] != placed.word[placedLetterIndex]) {
            continue;
          }

          final candidate = _buildPlacementFromCrossing(
            newWord: newWord,
            newLetterIndex: newLetterIndex,
            placed: placed,
            placedLetterIndex: placedLetterIndex,
          );

          final key =
              '${candidate.startRow},${candidate.startCol},${candidate.direction.index}';
          if (seen.add(key)) {
            candidates.add(candidate);
          }
        }
      }
    }

    candidates.sort((a, b) {
      final rowCompare = a.startRow.compareTo(b.startRow);
      if (rowCompare != 0) {
        return rowCompare;
      }
      final colCompare = a.startCol.compareTo(b.startCol);
      if (colCompare != 0) {
        return colCompare;
      }
      return a.direction.index.compareTo(b.direction.index);
    });

    return candidates;
  }

  WordPlacement _buildPlacementFromCrossing({
    required String newWord,
    required int newLetterIndex,
    required WordPlacement placed,
    required int placedLetterIndex,
  }) {
    if (placed.direction == WordDirection.horizontal) {
      final crossRow = placed.startRow;
      final crossCol = placed.startCol + placedLetterIndex;
      return WordPlacement(
        word: newWord,
        startRow: crossRow - newLetterIndex,
        startCol: crossCol,
        direction: WordDirection.vertical,
      );
    }

    final crossRow = placed.startRow + placedLetterIndex;
    final crossCol = placed.startCol;
    return WordPlacement(
      word: newWord,
      startRow: crossRow,
      startCol: crossCol - newLetterIndex,
      direction: WordDirection.horizontal,
    );
  }

  bool _canPlaceWord(
    String word,
    WordPlacement placement,
    Map<String, String> occupied,
  ) {
    for (var index = 0; index < word.length; index++) {
      final cell = _getCellForLetter(placement, index);
      final key = _cellKey(cell.row, cell.col);
      final existingLetter = occupied[key];

      if (existingLetter != null && existingLetter != word[index]) {
        return false;
      }

      if (existingLetter == null &&
          !_perpendicularNeighborsEmpty(
            cell.row,
            cell.col,
            placement.direction,
            occupied,
          )) {
        return false;
      }
    }

    return _endCapsEmpty(word, placement, occupied);
  }

  bool _perpendicularNeighborsEmpty(
    int row,
    int col,
    WordDirection direction,
    Map<String, String> occupied,
  ) {
    if (direction == WordDirection.horizontal) {
      return !occupied.containsKey(_cellKey(row - 1, col)) &&
          !occupied.containsKey(_cellKey(row + 1, col));
    }

    return !occupied.containsKey(_cellKey(row, col - 1)) &&
        !occupied.containsKey(_cellKey(row, col + 1));
  }

  bool _endCapsEmpty(
    String word,
    WordPlacement placement,
    Map<String, String> occupied,
  ) {
    if (placement.direction == WordDirection.horizontal) {
      return !occupied.containsKey(
            _cellKey(placement.startRow, placement.startCol - 1),
          ) &&
          !occupied.containsKey(
            _cellKey(
              placement.startRow,
              placement.startCol + word.length,
            ),
          );
    }

    return !occupied.containsKey(
          _cellKey(placement.startRow - 1, placement.startCol),
        ) &&
        !occupied.containsKey(
          _cellKey(
            placement.startRow + word.length,
            placement.startCol,
          ),
        );
  }

  ({int row, int col}) _getCellForLetter(
    WordPlacement placement,
    int letterIndex,
  ) {
    switch (placement.direction) {
      case WordDirection.horizontal:
        return (row: placement.startRow, col: placement.startCol + letterIndex);
      case WordDirection.vertical:
        return (row: placement.startRow + letterIndex, col: placement.startCol);
    }
  }

  void _applyWord(WordPlacement placement, Map<String, String> occupied) {
    for (var index = 0; index < placement.word.length; index++) {
      final cell = _getCellForLetter(placement, index);
      occupied[_cellKey(cell.row, cell.col)] = placement.word[index];
    }
  }

  void _removeWord(
    WordPlacement placement,
    Map<String, String> occupied,
    List<WordPlacement> remainingPlacements,
  ) {
    for (var index = 0; index < placement.word.length; index++) {
      final cell = _getCellForLetter(placement, index);
      final key = _cellKey(cell.row, cell.col);

      if (!_isCellUsedByAnyPlacement(cell.row, cell.col, remainingPlacements)) {
        occupied.remove(key);
      }
    }
  }

  bool _isCellUsedByAnyPlacement(
    int row,
    int col,
    List<WordPlacement> placements,
  ) {
    for (final placement in placements) {
      for (var index = 0; index < placement.word.length; index++) {
        final cell = _getCellForLetter(placement, index);
        if (cell.row == row && cell.col == col) {
          return true;
        }
      }
    }
    return false;
  }

  List<GridCell> _buildOccupiedCells(Map<String, String> occupied) {
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

    return cells;
  }

  ({
    int minRow,
    int maxRow,
    int minCol,
    int maxCol,
  }) _computeBounds(List<GridCell> cells) {
    if (cells.isEmpty) {
      return (minRow: 0, maxRow: 0, minCol: 0, maxCol: 0);
    }

    var minRow = cells.first.row;
    var maxRow = cells.first.row;
    var minCol = cells.first.col;
    var maxCol = cells.first.col;

    for (final cell in cells) {
      minRow = min(minRow, cell.row);
      maxRow = max(maxRow, cell.row);
      minCol = min(minCol, cell.col);
      maxCol = max(maxCol, cell.col);
    }

    return (
      minRow: minRow,
      maxRow: maxRow,
      minCol: minCol,
      maxCol: maxCol,
    );
  }

  String _cellKey(int row, int col) => '$row,$col';
}
