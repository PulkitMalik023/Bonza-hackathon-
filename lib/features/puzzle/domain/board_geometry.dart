import 'dart:math';
import 'dart:ui';

import '../../../core/constants/board_constants.dart';
import 'board_cell_position.dart';
import 'grid_layout.dart';
import 'piece_cell.dart';
import 'puzzle_piece.dart';

/// Single source of truth for board cell size, dimensions, and pixel mapping.
class BoardGeometry {
  const BoardGeometry({
    required this.boardCellSize,
    required this.boardRows,
    required this.boardCols,
    required this.origin,
  });

  final double boardCellSize;
  final int boardRows;
  final int boardCols;
  final Offset origin;

  Size get boardPixelSize =>
      Size(boardCols * boardCellSize, boardRows * boardCellSize);

  /// Board-local geometry with origin at [Offset.zero] for widgets inside the
  /// board container.
  factory BoardGeometry.local({
    required int boardRows,
    required int boardCols,
    double boardCellSize = BoardConstants.kBoardTileSize,
  }) {
    return BoardGeometry(
      boardCellSize: boardCellSize,
      boardRows: boardRows,
      boardCols: boardCols,
      origin: Offset.zero,
    );
  }

  factory BoardGeometry.fromLayoutBounds({
    required int minRow,
    required int maxRow,
    required int minCol,
    required int maxCol,
    required Offset origin,
    double boardCellSize = BoardConstants.kBoardTileSize,
  }) {
    return BoardGeometry(
      boardCellSize: boardCellSize,
      boardRows: maxRow - minRow + 1,
      boardCols: maxCol - minCol + 1,
      origin: origin,
    );
  }

  Offset boardCellTopLeft(BoardCellPosition cell) {
    return origin +
        Offset(cell.col * boardCellSize, cell.row * boardCellSize);
  }

  Rect boardCellRect(BoardCellPosition cell) {
    final topLeft = boardCellTopLeft(cell);
    return Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      boardCellSize,
      boardCellSize,
    );
  }

  Offset boardCellCenter(BoardCellPosition cell) {
    return boardCellRect(cell).center;
  }

  Rect boardPixelRect() {
    return Rect.fromLTWH(
      origin.dx,
      origin.dy,
      boardPixelSize.width,
      boardPixelSize.height,
    );
  }
}

Offset cellTopLeft(int row, int col, double tileSize) {
  return BoardGeometry.local(
    boardRows: 0,
    boardCols: 0,
    boardCellSize: tileSize,
  ).boardCellTopLeft(BoardCellPosition(row: row, col: col));
}

Rect boardPixelRect({
  required int boardRows,
  required int boardCols,
  required double tileSize,
}) {
  return BoardGeometry.local(
    boardRows: boardRows,
    boardCols: boardCols,
    boardCellSize: tileSize,
  ).boardPixelRect();
}

Rect piecePixelRectAt(Offset topLeft, PuzzlePiece piece, double tileSize) {
  final maxRowOffset = piece.cells.map((cell) => cell.rowOffset).reduce(max);
  final maxColOffset = piece.cells.map((cell) => cell.colOffset).reduce(max);

  return Rect.fromLTWH(
    topLeft.dx,
    topLeft.dy,
    (maxColOffset + 1) * tileSize,
    (maxRowOffset + 1) * tileSize,
  );
}

Offset pieceCenterFromTopLeft(
  Offset topLeft,
  PuzzlePiece piece,
  double tileSize,
) {
  final rect = piecePixelRectAt(topLeft, piece, tileSize);
  return rect.center;
}

bool pieceOverlapsBoard(
  Offset topLeft, {
  required PuzzlePiece piece,
  required int boardRows,
  required int boardCols,
  required double tileSize,
}) {
  return piecePixelRectAt(topLeft, piece, tileSize).overlaps(
    boardPixelRect(
      boardRows: boardRows,
      boardCols: boardCols,
      tileSize: tileSize,
    ),
  );
}

BoardCellPosition nearestBoardAnchorForTopLeft(
  Offset topLeft, {
  required PuzzlePiece piece,
  required int boardRows,
  required int boardCols,
  required double tileSize,
}) {
  final fromTopLeft = BoardCellPosition(
    row: (topLeft.dy / tileSize).round(),
    col: (topLeft.dx / tileSize).round(),
  );

  if (isChunkPlacementInsideBoard(
    piece,
    fromTopLeft,
    boardRows: boardRows,
    boardCols: boardCols,
  )) {
    return fromTopLeft;
  }

  final center = pieceCenterFromTopLeft(topLeft, piece, tileSize);
  final gridLayout = GridLayout.fromBoardSize(
    boardSize: Size(boardCols * tileSize, boardRows * tileSize),
    tileSize: tileSize,
  );
  final cell = gridLayout.nearestBoardCellFromCenter(
    center,
    boardRows: boardRows,
    boardCols: boardCols,
  );
  return BoardCellPosition(row: cell.row, col: cell.col);
}

bool isChunkPlacementInsideBoard(
  PuzzlePiece piece,
  BoardCellPosition anchor, {
  required int boardRows,
  required int boardCols,
}) {
  for (final cell in piece.getOccupiedCellsAt(anchor.row, anchor.col)) {
    if (cell.row < 0 ||
        cell.row >= boardRows ||
        cell.col < 0 ||
        cell.col >= boardCols) {
      return false;
    }
  }
  return true;
}

({double width, double height}) pieceGridSize(PuzzlePiece piece) {
  final maxRowOffset = piece.cells.map((cell) => cell.rowOffset).reduce(max);
  final maxColOffset = piece.cells.map((cell) => cell.colOffset).reduce(max);
  return (width: maxColOffset + 1, height: maxRowOffset + 1);
}

BoardCellPosition centeredPieceAnchor({
  required int canvasRows,
  required int canvasCols,
  required PuzzlePiece piece,
}) {
  final size = pieceGridSize(piece);
  final maxRow = max(0, canvasRows - size.height.toInt());
  final maxCol = max(0, canvasCols - size.width.toInt());
  return BoardCellPosition(
    row: maxRow ~/ 2,
    col: maxCol ~/ 2,
  );
}
