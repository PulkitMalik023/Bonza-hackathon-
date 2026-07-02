import 'package:flutter/foundation.dart';

import '../models/generated_puzzle_layout.dart';
import '../models/placed_word.dart';
import '../models/puzzle_content.dart';
import '../models/puzzle_layout.dart';

class PuzzleLayoutGenerator {
  List<PuzzleLayout> generateAllLayouts(List<String> words) {
    final normalizedWords = words.map((word) => word.toUpperCase()).toList();

    if (normalizedWords.isEmpty) {
      debugPrint('[PuzzleLayoutGenerator] No layouts found for words: []');
      return const [];
    }

    if (!_canPotentiallyConnect(normalizedWords)) {
      debugPrint(
        '[PuzzleLayoutGenerator] No layouts found for words: $normalizedWords '
        '(words cannot form a connected graph)',
      );
      return const [];
    }

    final sortedWords = [...normalizedWords]
      ..sort((a, b) {
        final lengthCompare = b.length.compareTo(a.length);
        if (lengthCompare != 0) {
          return lengthCompare;
        }
        return a.compareTo(b);
      });

    debugPrint(
      '[PuzzleLayoutGenerator] Generating all layouts for words: $sortedWords',
    );

    final occupied = <String, String>{};
    final placements = <PlacedWord>[];

    final seedWord = sortedWords.first;
    final seedPlacement = PlacedWord(
      word: seedWord,
      row: 0,
      col: 0,
      direction: WordDirection.horizontal,
    );
    _applyWord(seedPlacement, occupied);
    placements.add(seedPlacement);
    debugPrint('[PuzzleLayoutGenerator] Seed placement: $seedPlacement');

    final results = <PuzzleLayout>[];
    final seenSignatures = <String>{};

    _backtrackPlaceWords(
      remainingWords: sortedWords.sublist(1),
      wordIndex: 0,
      placements: placements,
      occupied: occupied,
      results: results,
      seenSignatures: seenSignatures,
    );

    debugPrint(
      '[PuzzleLayoutGenerator] Total unique layouts found: ${results.length}',
    );
    for (final layout in results) {
      debugPrint(
        '[PuzzleLayoutGenerator] Layout signature: ${PuzzleLayout.signature(layout)}',
      );
    }
    if (results.isEmpty) {
      debugPrint(
        '[PuzzleLayoutGenerator] No layouts found for words: $sortedWords',
      );
    }

    return List.unmodifiable(results);
  }

  PuzzleLayout? generateSingleLayout(List<String> words) {
    final layouts = generateAllLayouts(words);
    return layouts.isNotEmpty ? layouts.first : null;
  }

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

    debugPrint(
      '[PuzzleLayoutGenerator] Generating layout for $puzzleId '
      '(${content.category}) with words: $words',
    );

    final layouts = generateAllLayouts(words);
    if (layouts.isEmpty) {
      throw StateError(
        'Could not generate connected layout for puzzle $puzzleId',
      );
    }

    final layout = layouts.first;

    debugPrint('[PuzzleLayoutGenerator] Final placements for $puzzleId:');
    for (final placement in layout.placedWords) {
      debugPrint('  $placement');
    }
    debugPrint(
      '[PuzzleLayoutGenerator] Bounds: '
      'rows ${layout.minRow}..${layout.maxRow}, '
      'cols ${layout.minCol}..${layout.maxCol}',
    );

    return GeneratedPuzzleLayout.fromPuzzleContent(content, layout);
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

  void _backtrackPlaceWords({
    required List<String> remainingWords,
    required int wordIndex,
    required List<PlacedWord> placements,
    required Map<String, String> occupied,
    required List<PuzzleLayout> results,
    required Set<String> seenSignatures,
  }) {
    if (wordIndex >= remainingWords.length) {
      _storeIfUnique(placements, results, seenSignatures);
      return;
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

      _backtrackPlaceWords(
        remainingWords: remainingWords,
        wordIndex: wordIndex + 1,
        placements: placements,
        occupied: occupied,
        results: results,
        seenSignatures: seenSignatures,
      );

      placements.removeLast();
      _removeWord(candidate, occupied, placements);
      debugPrint('[PuzzleLayoutGenerator] Backtracking from: $candidate');
    }
  }

  void _storeIfUnique(
    List<PlacedWord> placements,
    List<PuzzleLayout> results,
    Set<String> seenSignatures,
  ) {
    final layout = PuzzleLayout.normalize(
      List<PlacedWord>.unmodifiable(placements),
    );
    final layoutSignature = PuzzleLayout.signature(layout);

    if (seenSignatures.add(layoutSignature)) {
      results.add(layout);
      debugPrint(
        '[PuzzleLayoutGenerator] Stored layout signature: $layoutSignature',
      );
    }
  }

  List<PlacedWord> _generateCandidates(
    String newWord,
    List<PlacedWord> placements,
  ) {
    final candidates = <PlacedWord>[];
    final seen = <String>{};

    for (final placed in placements) {
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

          final key = '${candidate.row},${candidate.col},${candidate.direction.index}';
          if (seen.add(key)) {
            candidates.add(candidate);
          }
        }
      }
    }

    candidates.sort((a, b) {
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

    return candidates;
  }

  PlacedWord _buildPlacementFromCrossing({
    required String newWord,
    required int newLetterIndex,
    required PlacedWord placed,
    required int placedLetterIndex,
  }) {
    if (placed.direction == WordDirection.horizontal) {
      final crossRow = placed.row;
      final crossCol = placed.col + placedLetterIndex;
      return PlacedWord(
        word: newWord,
        row: crossRow - newLetterIndex,
        col: crossCol,
        direction: WordDirection.vertical,
      );
    }

    final crossRow = placed.row + placedLetterIndex;
    final crossCol = placed.col;
    return PlacedWord(
      word: newWord,
      row: crossRow,
      col: crossCol - newLetterIndex,
      direction: WordDirection.horizontal,
    );
  }

  bool _canPlaceWord(
    String word,
    PlacedWord placement,
    Map<String, String> occupied,
  ) {
    var overlapsExisting = false;

    for (var index = 0; index < word.length; index++) {
      final cell = _getCellForLetter(placement, index);
      final key = _cellKey(cell.row, cell.col);
      final existingLetter = occupied[key];

      if (existingLetter != null) {
        if (existingLetter != word[index]) {
          return false;
        }
        overlapsExisting = true;
      } else if (!_perpendicularNeighborsEmpty(
        cell.row,
        cell.col,
        placement.direction,
        occupied,
      )) {
        return false;
      }
    }

    if (!overlapsExisting) {
      return false;
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
    PlacedWord placement,
    Map<String, String> occupied,
  ) {
    if (placement.direction == WordDirection.horizontal) {
      return !occupied.containsKey(
            _cellKey(placement.row, placement.col - 1),
          ) &&
          !occupied.containsKey(
            _cellKey(
              placement.row,
              placement.col + word.length,
            ),
          );
    }

    return !occupied.containsKey(
          _cellKey(placement.row - 1, placement.col),
        ) &&
        !occupied.containsKey(
          _cellKey(
            placement.row + word.length,
            placement.col,
          ),
        );
  }

  ({int row, int col}) _getCellForLetter(
    PlacedWord placement,
    int letterIndex,
  ) {
    switch (placement.direction) {
      case WordDirection.horizontal:
        return (row: placement.row, col: placement.col + letterIndex);
      case WordDirection.vertical:
        return (row: placement.row + letterIndex, col: placement.col);
    }
  }

  void _applyWord(PlacedWord placement, Map<String, String> occupied) {
    for (var index = 0; index < placement.word.length; index++) {
      final cell = _getCellForLetter(placement, index);
      occupied[_cellKey(cell.row, cell.col)] = placement.word[index];
    }
  }

  void _removeWord(
    PlacedWord placement,
    Map<String, String> occupied,
    List<PlacedWord> remainingPlacements,
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
    List<PlacedWord> placements,
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

  String _cellKey(int row, int col) => '$row,$col';
}
