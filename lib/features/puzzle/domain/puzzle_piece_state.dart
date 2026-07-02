import 'dart:ui';

import 'board_cell_position.dart';
import 'board_geometry.dart';
import 'piece_cell.dart';
import 'puzzle_piece.dart';

/// Runtime state for a movable puzzle piece group.
class PuzzlePieceState {
  PuzzlePieceState({
    required this.id,
    required this.localCells,
    required this.anchorRow,
    required this.anchorCol,
    required this.spawnAnchorRow,
    required this.spawnAnchorCol,
  });

  final String id;
  final List<PieceCell> localCells;
  int anchorRow;
  int anchorCol;
  final int spawnAnchorRow;
  final int spawnAnchorCol;

  Offset pixelTopLeft(BoardGeometry geometry) {
    return geometry.boardCellTopLeft(
      BoardCellPosition(row: anchorRow, col: anchorCol),
    );
  }

  factory PuzzlePieceState.fromPiece(PuzzlePiece piece) {
    return PuzzlePieceState(
      id: piece.id,
      localCells: piece.cells,
      anchorRow: piece.anchorRow,
      anchorCol: piece.anchorCol,
      spawnAnchorRow: piece.spawnAnchorRow,
      spawnAnchorCol: piece.spawnAnchorCol,
    );
  }
}
