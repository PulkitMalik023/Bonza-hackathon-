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
    return !hasDuplicateChunkSignatures(deconstructed) &&
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

  /// Flags when a singleton letter also appears as a peelable leaf in a
  /// multi-cell chunk (e.g. ST + lone T), but allows cases like Spectrum's
  /// lone N + IAN where N is not a leaf in the multi-cell chunk.
  bool hasSingletonAndMultiCellLetterConflict(DeconstructedPuzzle deconstructed) {
    for (final chunk in deconstructed.chunks) {
      if (chunk.solvedCells.length != 1) {
        continue;
      }

      final singletonLetter =
          chunk.solvedCells.values.single.toUpperCase();

      for (final other in deconstructed.chunks) {
        if (other.solvedCells.length <= 1) {
          continue;
        }

        for (final entry in other.solvedCells.entries) {
          if (entry.value.toUpperCase() != singletonLetter) {
            continue;
          }

          if (_isLeafCell(entry.key, other.solvedCells.keys)) {
            return true;
          }
        }
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

  bool _isLeafCell(
    BoardCellPosition position,
    Iterable<BoardCellPosition> chunkCells,
  ) {
    final cellSet = chunkCells.toSet();
    var neighborCount = 0;

    for (final delta in const [
      (0, 1),
      (0, -1),
      (1, 0),
      (-1, 0),
    ]) {
      final neighbor = BoardCellPosition(
        row: position.row + delta.$1,
        col: position.col + delta.$2,
      );
      if (cellSet.contains(neighbor)) {
        neighborCount++;
      }
    }

    return neighborCount <= 1;
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
