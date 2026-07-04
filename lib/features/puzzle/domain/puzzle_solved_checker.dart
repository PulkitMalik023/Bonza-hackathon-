import '../data/models/deconstructed_puzzle.dart';
import '../data/models/puzzle_layout.dart';
import 'board_cell_position.dart';
import 'puzzle_board_state.dart';
import 'puzzle_piece.dart';

class PuzzleSolvedStatus {
  const PuzzleSolvedStatus({
    required this.isSolved,
    required this.failureReason,
    required this.placedInLayoutCount,
    required this.expectedCount,
    required this.excludedOffLayoutCount,
  });

  final bool isSolved;
  final String failureReason;
  final int placedInLayoutCount;
  final int expectedCount;
  final int excludedOffLayoutCount;
}

bool isPuzzleSolved({
  required DeconstructedPuzzle deconstructed,
  required List<PuzzlePiece> pieces,
  required int boardRows,
  required int boardCols,
}) {
  return evaluatePuzzleSolved(
    deconstructed: deconstructed,
    pieces: pieces,
    boardRows: boardRows,
    boardCols: boardCols,
  ).isSolved;
}

PuzzleSolvedStatus evaluatePuzzleSolved({
  required DeconstructedPuzzle deconstructed,
  required List<PuzzlePiece> pieces,
  required int boardRows,
  required int boardCols,
}) {
  final layout = deconstructed.sourceLayout;
  final targetCells = <BoardCellPosition, String>{};
  for (final cell in layout.occupiedCells) {
    targetCells[BoardCellPosition(row: cell.row, col: cell.col)] = cell.letter;
  }

  final placedInLayout = <BoardCellPosition, String>{};
  var excludedOffLayoutCount = 0;

  for (final piece in pieces) {
    for (final cell in piece.cells) {
      final boardCell = BoardCellPosition(
        row: piece.anchorRow + cell.rowOffset,
        col: piece.anchorCol + cell.colOffset,
      );

      if (!_isWithinLayoutBounds(boardCell, layout)) {
        excludedOffLayoutCount++;
        continue;
      }

      if (boardCell.row < 0 ||
          boardCell.row >= boardRows ||
          boardCell.col < 0 ||
          boardCell.col >= boardCols) {
        return PuzzleSolvedStatus(
          isSolved: false,
          failureReason: 'outOfCanvasBounds at (${boardCell.row},${boardCell.col})',
          placedInLayoutCount: placedInLayout.length,
          expectedCount: targetCells.length,
          excludedOffLayoutCount: excludedOffLayoutCount,
        );
      }

      final existing = placedInLayout[boardCell];
      if (existing != null && existing != cell.letter) {
        return PuzzleSolvedStatus(
          isSolved: false,
          failureReason: 'conflictingLetters at (${boardCell.row},${boardCell.col})',
          placedInLayoutCount: placedInLayout.length,
          expectedCount: targetCells.length,
          excludedOffLayoutCount: excludedOffLayoutCount,
        );
      }
      placedInLayout[boardCell] = cell.letter;
    }
  }

  if (placedInLayout.length != targetCells.length) {
    return PuzzleSolvedStatus(
      isSolved: false,
      failureReason: placedInLayout.length < targetCells.length
          ? 'missingCells count=${placedInLayout.length} expected=${targetCells.length}'
          : 'extraCells count=${placedInLayout.length} expected=${targetCells.length}',
      placedInLayoutCount: placedInLayout.length,
      expectedCount: targetCells.length,
      excludedOffLayoutCount: excludedOffLayoutCount,
    );
  }

  for (final entry in targetCells.entries) {
    if (placedInLayout[entry.key] != entry.value) {
      return PuzzleSolvedStatus(
        isSolved: false,
        failureReason:
            'wrongLetter at (${entry.key.row},${entry.key.col}) expected=${entry.value} actual=${placedInLayout[entry.key]}',
        placedInLayoutCount: placedInLayout.length,
        expectedCount: targetCells.length,
        excludedOffLayoutCount: excludedOffLayoutCount,
      );
    }
  }

  return PuzzleSolvedStatus(
    isSolved: true,
    failureReason: 'none',
    placedInLayoutCount: placedInLayout.length,
    expectedCount: targetCells.length,
    excludedOffLayoutCount: excludedOffLayoutCount,
  );
}

bool _isWithinLayoutBounds(BoardCellPosition cell, PuzzleLayout layout) {
  return cell.row >= layout.minRow &&
      cell.row <= layout.maxRow &&
      cell.col >= layout.minCol &&
      cell.col <= layout.maxCol;
}

bool areAllTargetAnswersCompleted(
  List<String> targetWords,
  Set<String> completedAnswers,
) {
  if (targetWords.isEmpty) {
    return false;
  }

  for (final word in targetWords) {
    if (!completedAnswers.contains(word.toUpperCase())) {
      return false;
    }
  }

  return true;
}

bool areAllWordsCompleted(
  PuzzleLayout layout,
  Set<String> completedWordKeys,
) {
  if (layout.placedWords.isEmpty) {
    return false;
  }

  for (var index = 0; index < layout.placedWords.length; index++) {
    if (!completedWordKeys.contains(wordKey(layout.placedWords[index], index))) {
      return false;
    }
  }

  return true;
}

bool isPieceOnBoard(PuzzlePiece piece, int boardRows, int boardCols) {
  return piece.getOccupiedCells().every(
        (cell) =>
            cell.row >= 0 &&
            cell.row < boardRows &&
            cell.col >= 0 &&
            cell.col < boardCols,
      );
}
