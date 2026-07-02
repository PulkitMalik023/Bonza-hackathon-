import 'board_cell_position.dart';
import 'piece_cell.dart';

class PuzzlePiece {
  PuzzlePiece({
    required this.id,
    required this.anchorRow,
    required this.anchorCol,
    required this.cells,
  });

  final String id;
  int anchorRow;
  int anchorCol;
  final List<PieceCell> cells;

  List<BoardCellPosition> getOccupiedCells() =>
      getOccupiedCellsAt(anchorRow, anchorCol);

  List<BoardCellPosition> getOccupiedCellsAt(int anchorRow, int anchorCol) =>
      cells
          .map(
            (cell) => BoardCellPosition(
              row: anchorRow + cell.rowOffset,
              col: anchorCol + cell.colOffset,
            ),
          )
          .toList();
}
