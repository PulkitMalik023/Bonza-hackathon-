import 'dart:math';

import 'board_cell_position.dart';
import 'board_geometry.dart';
import 'puzzle_piece.dart';

const _colGap = 1;
const _rowGap = 1;

List<BoardCellPosition> computePieceSpawnAnchors({
  required List<PuzzlePiece> pieces,
  required int canvasRows,
  required int canvasCols,
}) {
  if (pieces.isEmpty) {
    return const [];
  }

  final anchors = <BoardCellPosition>[];
  var rowStart = canvasRows - 1;
  var colCursor = 0;
  var rowBlockHeight = 1;

  for (final piece in pieces) {
    final size = pieceGridSize(piece);
    final width = size.width.toInt();
    final height = size.height.toInt();

    if (colCursor + width > canvasCols) {
      rowStart -= rowBlockHeight + _rowGap;
      colCursor = 0;
      rowBlockHeight = 1;
    }

    final anchorRow =
        (rowStart - height + 1).clamp(0, max(0, canvasRows - height)).toInt();
    final anchorCol = colCursor.clamp(0, max(0, canvasCols - width)).toInt();

    anchors.add(BoardCellPosition(row: anchorRow, col: anchorCol));

    colCursor += width + _colGap;
    rowBlockHeight = max(rowBlockHeight, height);
  }

  return anchors;
}

List<PuzzlePiece> applySpawnAnchors(
  List<PuzzlePiece> pieces,
  List<BoardCellPosition> anchors,
) {
  final spawned = <PuzzlePiece>[];
  for (var index = 0; index < pieces.length; index++) {
    final piece = pieces[index];
    final anchor = anchors[index];

    spawned.add(
      PuzzlePiece(
        id: piece.id,
        chunkId: piece.chunkId,
        anchorRow: anchor.row,
        anchorCol: anchor.col,
        spawnAnchorRow: anchor.row,
        spawnAnchorCol: anchor.col,
        cells: piece.cells,
      ),
    );
  }

  return spawned;
}

/// Returns true when no two pieces occupy the same board cell at their anchors.
bool pieceSpawnAnchorsAreNonOverlapping(List<PuzzlePiece> pieces) {
  final occupied = <BoardCellPosition>{};

  for (final piece in pieces) {
    for (final cell in piece.getOccupiedCells()) {
      if (!occupied.add(cell)) {
        return false;
      }
    }
  }

  return true;
}

/// Returns true when every piece fits fully inside the canvas at its anchor.
bool piecesFitCanvas({
  required List<PuzzlePiece> pieces,
  required int canvasRows,
  required int canvasCols,
}) {
  for (final piece in pieces) {
    for (final cell in piece.getOccupiedCells()) {
      if (cell.row < 0 ||
          cell.row >= canvasRows ||
          cell.col < 0 ||
          cell.col >= canvasCols) {
        return false;
      }
    }
  }

  return true;
}
