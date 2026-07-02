import '../data/models/deconstructed_puzzle.dart';
import 'board_cell_position.dart';
import 'puzzle_piece.dart';

bool isPuzzleSolved({
  required DeconstructedPuzzle deconstructed,
  required List<PuzzlePiece> pieces,
  required int boardRows,
  required int boardCols,
}) {
  final targetCells = <BoardCellPosition, String>{};
  for (final cell in deconstructed.sourceLayout.occupiedCells) {
    targetCells[BoardCellPosition(row: cell.row, col: cell.col)] = cell.letter;
  }

  final placedCells = <BoardCellPosition, String>{};

  for (final piece in pieces) {
    for (var index = 0; index < piece.cells.length; index++) {
      final cell = piece.cells[index];
      final boardCell = BoardCellPosition(
        row: piece.anchorRow + cell.rowOffset,
        col: piece.anchorCol + cell.colOffset,
      );

      if (boardCell.row < 0 ||
          boardCell.row >= boardRows ||
          boardCell.col < 0 ||
          boardCell.col >= boardCols) {
        return false;
      }

      final existing = placedCells[boardCell];
      if (existing != null && existing != cell.letter) {
        return false;
      }
      placedCells[boardCell] = cell.letter;
    }
  }

  if (placedCells.length != targetCells.length) {
    return false;
  }

  for (final entry in targetCells.entries) {
    if (placedCells[entry.key] != entry.value) {
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
