import 'dart:ui';

import 'board_cell_position.dart';
import 'board_geometry.dart';
import 'board_occupancy.dart';
import 'puzzle_piece.dart';

enum ChunkDropAction { snap, returnToOrigin }

class ChunkDropResult {
  const ChunkDropResult({
    required this.action,
    required this.droppedTopLeft,
    required this.center,
    this.targetAnchor,
    required this.overlapsBoard,
    required this.insideBoard,
    required this.occupied,
  });

  final ChunkDropAction action;
  final Offset droppedTopLeft;
  final Offset center;
  final BoardCellPosition? targetAnchor;
  final bool overlapsBoard;
  final bool insideBoard;
  final bool occupied;
}

bool isChunkPlacementOverlapping(
  BoardOccupancy occupancy,
  PuzzlePiece piece,
  BoardCellPosition anchor,
  String pieceId,
) {
  for (final cell in piece.getOccupiedCellsAt(anchor.row, anchor.col)) {
    if (occupancy.isOccupiedByAnotherTile(cell.row, cell.col, pieceId)) {
      return true;
    }
  }
  return false;
}

/// Returns true when [movingPiece] can be placed at [targetAnchorRow/Col].
bool canPlaceOnBoard({
  required PuzzlePiece movingPiece,
  required int targetAnchorRow,
  required int targetAnchorCol,
  required int boardRows,
  required int boardCols,
  required List<PuzzlePiece> pieces,
}) {
  final anchor = BoardCellPosition(row: targetAnchorRow, col: targetAnchorCol);
  if (!isChunkPlacementInsideBoard(
    movingPiece,
    anchor,
    boardRows: boardRows,
    boardCols: boardCols,
  )) {
    return false;
  }

  final occupancy = BoardOccupancy()
    ..rebuildFromPieces(
      pieces.where((piece) => piece.id != movingPiece.id).toList(),
      boardRows: boardRows,
      boardCols: boardCols,
    );

  return !isChunkPlacementOverlapping(
    occupancy,
    movingPiece,
    anchor,
    movingPiece.id,
  );
}

ChunkDropResult evaluateChunkDrop({
  required Offset droppedTopLeft,
  required PuzzlePiece piece,
  required BoardOccupancy occupancy,
  required int boardRows,
  required int boardCols,
  required double tileSize,
  int? canvasRows,
  int? canvasCols,
}) {
  final placementRows = canvasRows ?? boardRows;
  final placementCols = canvasCols ?? boardCols;

  final center = pieceCenterFromTopLeft(droppedTopLeft, piece, tileSize);
  final overlapsPlacement = pieceOverlapsBoard(
    droppedTopLeft,
    piece: piece,
    boardRows: placementRows,
    boardCols: placementCols,
    tileSize: tileSize,
  );

  if (!overlapsPlacement) {
    return ChunkDropResult(
      action: ChunkDropAction.returnToOrigin,
      droppedTopLeft: droppedTopLeft,
      center: center,
      overlapsBoard: false,
      insideBoard: false,
      occupied: false,
    );
  }

  final targetAnchor = nearestBoardAnchorForTopLeft(
    droppedTopLeft,
    piece: piece,
    boardRows: placementRows,
    boardCols: placementCols,
    tileSize: tileSize,
  );

  final insideBoard = isChunkPlacementInsideBoard(
    piece,
    targetAnchor,
    boardRows: placementRows,
    boardCols: placementCols,
  );

  final occupied = isChunkPlacementOverlapping(
    occupancy,
    piece,
    targetAnchor,
    piece.id,
  );

  final shouldSnap = insideBoard && !occupied;

  return ChunkDropResult(
    action: shouldSnap ? ChunkDropAction.snap : ChunkDropAction.returnToOrigin,
    droppedTopLeft: droppedTopLeft,
    center: center,
    targetAnchor: targetAnchor,
    overlapsBoard: true,
    insideBoard: insideBoard,
    occupied: occupied,
  );
}
