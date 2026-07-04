import '../../domain/board_cell_position.dart';
import 'chunk_signature.dart';
import '../models/deconstructed_puzzle.dart';
import '../models/placed_word.dart';
import '../models/puzzle_layout.dart';

/// Validates that a deconstructed puzzle avoids ambiguous duplicate tiles
/// (e.g. WEST ST chunk plus a separate lone T).
class DeconstructionQualityValidator {
  const DeconstructionQualityValidator();

  bool isValid({
    required PuzzleLayout layout,
    required DeconstructedPuzzle deconstructed,
  }) {
    return !hasSingletonChunks(deconstructed) &&
        !hasDuplicateChunkSignatures(deconstructed) &&
        !hasSingletonAndMultiCellLetterConflict(deconstructed) &&
        !hasCrossingCellsInSingletonChunks(layout, deconstructed);
  }

  bool hasSingletonChunks(DeconstructedPuzzle deconstructed) {
    return deconstructed.chunks.any((chunk) => chunk.solvedCells.length == 1);
  }

  bool hasDuplicateChunkSignatures(DeconstructedPuzzle deconstructed) {
    final seen = <String>{};
    for (final chunk in deconstructed.chunks) {
      final signature = signatureFromChunk(chunk);
      if (!seen.add(signature)) {
        return true;
      }
    }
    return false;
  }

  /// Rule 1: if a letter appears in any multi-cell chunk, it must not also
  /// appear in a single-cell chunk anywhere in the puzzle.
  bool hasSingletonAndMultiCellLetterConflict(DeconstructedPuzzle deconstructed) {
    final lettersInMultiCellChunks = <String>{};
    final lettersInSingleCellChunks = <String>{};

    for (final chunk in deconstructed.chunks) {
      final letters = chunk.solvedCells.values
          .map((letter) => letter.toUpperCase())
          .toSet();

      if (chunk.solvedCells.length > 1) {
        lettersInMultiCellChunks.addAll(letters);
      } else if (chunk.solvedCells.length == 1) {
        lettersInSingleCellChunks.add(letters.single);
      }
    }

    for (final letter in lettersInSingleCellChunks) {
      if (lettersInMultiCellChunks.contains(letter)) {
        return true;
      }
    }

    return false;
  }

  /// Rule 2: crossword intersection cells must not be isolated single-cell chunks.
  bool hasCrossingCellsInSingletonChunks(
    PuzzleLayout layout,
    DeconstructedPuzzle deconstructed,
  ) {
    final crossingPositions = _crossingPositions(layout);

    for (final chunk in deconstructed.chunks) {
      if (chunk.solvedCells.length != 1) {
        continue;
      }

      final position = chunk.solvedCells.keys.first;
      if (crossingPositions.contains(position)) {
        return true;
      }
    }

    return false;
  }

  Set<BoardCellPosition> _crossingPositions(PuzzleLayout layout) {
    final wordCountByPosition = <BoardCellPosition, int>{};

    for (final placed in layout.placedWords) {
      for (var index = 0; index < placed.word.length; index++) {
        final position = _layoutPositionForLetter(placed, index);
        wordCountByPosition[position] = (wordCountByPosition[position] ?? 0) + 1;
      }
    }

    return wordCountByPosition.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .toSet();
  }

  BoardCellPosition _layoutPositionForLetter(PlacedWord placed, int letterIndex) {
    switch (placed.direction) {
      case WordDirection.horizontal:
        return BoardCellPosition(row: placed.row, col: placed.col + letterIndex);
      case WordDirection.vertical:
        return BoardCellPosition(row: placed.row + letterIndex, col: placed.col);
    }
  }
}
