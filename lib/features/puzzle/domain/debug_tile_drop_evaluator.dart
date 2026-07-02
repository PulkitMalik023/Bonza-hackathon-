import 'dart:ui';

import 'board_cell_position.dart';
import 'board_occupancy.dart';

enum DebugTileDropAction { snap, returnToOrigin }

class DebugTileDropResult {
  const DebugTileDropResult({
    required this.action,
    required this.center,
    this.targetCell,
    required this.overlapsBoard,
    required this.insideBoard,
    required this.occupied,
  });

  final DebugTileDropAction action;
  final Offset center;
  final BoardCellPosition? targetCell;
  final bool overlapsBoard;
  final bool insideBoard;
  final bool occupied;
}

Offset tileCenterFromTopLeft(Offset topLeft, double tileSize) {
  return topLeft + Offset(tileSize / 2, tileSize / 2);
}

Rect boardPixelRect({
  required int boardRows,
  required int boardCols,
  required double tileSize,
}) {
  return Rect.fromLTWH(0, 0, boardCols * tileSize, boardRows * tileSize);
}

Rect tilePixelRect(Offset topLeft, double tileSize) {
  return Rect.fromLTWH(topLeft.dx, topLeft.dy, tileSize, tileSize);
}

bool tileOverlapsBoard(
  Offset topLeft, {
  required int boardRows,
  required int boardCols,
  required double tileSize,
}) {
  return tilePixelRect(topLeft, tileSize).overlaps(
    boardPixelRect(
      boardRows: boardRows,
      boardCols: boardCols,
      tileSize: tileSize,
    ),
  );
}

bool isCellInsideBoard(
  BoardCellPosition cell, {
  required int boardRows,
  required int boardCols,
}) {
  return cell.row >= 0 &&
      cell.row < boardRows &&
      cell.col >= 0 &&
      cell.col < boardCols;
}

BoardCellPosition nearestBoardCellForCenter(
  Offset center, {
  required int boardRows,
  required int boardCols,
  required double tileSize,
}) {
  var bestRow = 0;
  var bestCol = 0;
  var bestDistance = double.infinity;

  for (var row = 0; row < boardRows; row++) {
    for (var col = 0; col < boardCols; col++) {
      final cellCenter = Offset(
        (col + 0.5) * tileSize,
        (row + 0.5) * tileSize,
      );
      final distance = (center - cellCenter).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestRow = row;
        bestCol = col;
      }
    }
  }

  return BoardCellPosition(row: bestRow, col: bestCol);
}

bool isCellOccupiedByAnotherTile(
  BoardOccupancy occupancy,
  BoardCellPosition cell,
  String tileId,
) {
  return occupancy.isOccupiedByAnotherTile(cell.row, cell.col, tileId);
}

DebugTileDropResult evaluateDrop({
  required Offset droppedTopLeft,
  required String tileId,
  required BoardOccupancy occupancy,
  required int boardRows,
  required int boardCols,
  required double tileSize,
}) {
  final center = tileCenterFromTopLeft(droppedTopLeft, tileSize);
  final overlapsBoard = tileOverlapsBoard(
    droppedTopLeft,
    boardRows: boardRows,
    boardCols: boardCols,
    tileSize: tileSize,
  );

  if (!overlapsBoard) {
    return DebugTileDropResult(
      action: DebugTileDropAction.returnToOrigin,
      center: center,
      overlapsBoard: false,
      insideBoard: false,
      occupied: false,
    );
  }

  final targetCell = nearestBoardCellForCenter(
    center,
    boardRows: boardRows,
    boardCols: boardCols,
    tileSize: tileSize,
  );

  final insideBoard = isCellInsideBoard(
    targetCell,
    boardRows: boardRows,
    boardCols: boardCols,
  );

  final occupied = isCellOccupiedByAnotherTile(occupancy, targetCell, tileId);

  final shouldSnap = insideBoard && !occupied;

  return DebugTileDropResult(
    action: shouldSnap ? DebugTileDropAction.snap : DebugTileDropAction.returnToOrigin,
    center: center,
    targetCell: targetCell,
    overlapsBoard: true,
    insideBoard: insideBoard,
    occupied: occupied,
  );
}

Offset snapTopLeftForCell(BoardCellPosition cell, double tileSize) {
  return Offset(cell.col * tileSize, cell.row * tileSize);
}
