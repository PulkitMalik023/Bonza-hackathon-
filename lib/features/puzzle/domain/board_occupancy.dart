import 'board_cell_position.dart';
import 'puzzle_piece.dart';
import 'puzzle_solved_checker.dart';

class BoardOccupancy {
  final Map<BoardCellPosition, String> cells = {};

  void rebuildFromTiles(Iterable<({String id, int? row, int? col})> tiles) {
    cells.clear();
    for (final tile in tiles) {
      if (tile.row == null || tile.col == null) {
        continue;
      }
      occupy(tile.row!, tile.col!, tile.id);
    }
  }

  void rebuildFromPieces(
    List<PuzzlePiece> pieces, {
    required int boardRows,
    required int boardCols,
  }) {
    cells.clear();
    for (final piece in pieces) {
      if (!isPieceOnBoard(piece, boardRows, boardCols)) {
        continue;
      }
      for (final cell in piece.getOccupiedCells()) {
        occupy(cell.row, cell.col, piece.id);
      }
    }
  }

  void clearPiece(String pieceId) {
    cells.removeWhere((_, id) => id == pieceId);
  }

  void clearTile(String tileId) => clearPiece(tileId);

  bool isFree(int row, int col, {String? exceptTileId}) {
    final key = BoardCellPosition(row: row, col: col);
    final occupant = cells[key];
    if (occupant == null) {
      return true;
    }
    return occupant == exceptTileId;
  }

  bool isOccupiedByAnotherTile(int row, int col, String tileId) {
    final occupant = cells[BoardCellPosition(row: row, col: col)];
    return occupant != null && occupant != tileId;
  }

  void occupy(int row, int col, String tileId) {
    cells[BoardCellPosition(row: row, col: col)] = tileId;
  }

  Map<BoardCellPosition, String> snapshot() => Map.unmodifiable(cells);
}
