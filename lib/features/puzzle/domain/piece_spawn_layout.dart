import 'dart:math';

import 'package:flutter/foundation.dart';

import 'board_cell_position.dart';
import 'board_geometry.dart';
import 'chunk_drop_evaluator.dart';
import 'puzzle_piece.dart';

const _colGap = 1;
const _rowGap = 1;
const _maxRandomAttemptsPerPiece = 200;

/// Result of random scatter placement.
enum ScatterPlacementMode { random, trayFallback }

class RandomScatterResult {
  const RandomScatterResult({
    required this.anchors,
    required this.mode,
  });

  final List<BoardCellPosition> anchors;
  final ScatterPlacementMode mode;
}

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

List<BoardCellPosition> computeRandomScatterAnchors({
  required List<PuzzlePiece> pieces,
  required int canvasRows,
  required int canvasCols,
  Random? random,
}) {
  return computeRandomScatter(
    pieces: pieces,
    canvasRows: canvasRows,
    canvasCols: canvasCols,
    random: random,
  ).anchors;
}

RandomScatterResult computeRandomScatter({
  required List<PuzzlePiece> pieces,
  required int canvasRows,
  required int canvasCols,
  Random? random,
}) {
  if (pieces.isEmpty) {
    return const RandomScatterResult(
      anchors: [],
      mode: ScatterPlacementMode.random,
    );
  }

  final rng = random ?? Random();
  final order = List<int>.generate(pieces.length, (index) => index)..shuffle(rng);
  final anchors = List<BoardCellPosition?>.filled(pieces.length, null);
  final placedPieces = <PuzzlePiece>[];

  for (final index in order) {
    final piece = pieces[index];
    final anchor = _findRandomScatterAnchor(
      piece: piece,
      canvasRows: canvasRows,
      canvasCols: canvasCols,
      placedPieces: placedPieces,
      random: rng,
    ) ??
        _findExhaustiveScatterAnchor(
          piece: piece,
          canvasRows: canvasRows,
          canvasCols: canvasCols,
          placedPieces: placedPieces,
        );

    if (anchor == null) {
      if (kDebugMode) {
        debugPrint(
          '[PieceSpawnLayout] Random scatter failed for ${piece.id}; '
          'falling back to tray layout',
        );
      }
      return RandomScatterResult(
        anchors: computePieceSpawnAnchors(
          pieces: pieces,
          canvasRows: canvasRows,
          canvasCols: canvasCols,
        ),
        mode: ScatterPlacementMode.trayFallback,
      );
    }

    anchors[index] = anchor;
    placedPieces.add(_pieceAtAnchor(piece, anchor));
  }

  return RandomScatterResult(
    anchors: [
      for (final anchor in anchors)
        anchor ?? const BoardCellPosition(row: 0, col: 0),
    ],
    mode: ScatterPlacementMode.random,
  );
}

BoardCellPosition? _findRandomScatterAnchor({
  required PuzzlePiece piece,
  required int canvasRows,
  required int canvasCols,
  required List<PuzzlePiece> placedPieces,
  required Random random,
}) {
  final size = pieceGridSize(piece);
  final maxRow = canvasRows - size.height.toInt();
  final maxCol = canvasCols - size.width.toInt();
  if (maxRow < 0 || maxCol < 0) {
    return null;
  }

  for (var attempt = 0; attempt < _maxRandomAttemptsPerPiece; attempt++) {
    final row = maxRow == 0 ? 0 : random.nextInt(maxRow + 1);
    final col = maxCol == 0 ? 0 : random.nextInt(maxCol + 1);
    final anchor = BoardCellPosition(row: row, col: col);
    if (_canScatterPieceAt(
      piece: piece,
      anchor: anchor,
      canvasRows: canvasRows,
      canvasCols: canvasCols,
      placedPieces: placedPieces,
    )) {
      return anchor;
    }
  }

  return null;
}

BoardCellPosition? _findExhaustiveScatterAnchor({
  required PuzzlePiece piece,
  required int canvasRows,
  required int canvasCols,
  required List<PuzzlePiece> placedPieces,
}) {
  final size = pieceGridSize(piece);
  final maxRow = canvasRows - size.height.toInt();
  final maxCol = canvasCols - size.width.toInt();
  if (maxRow < 0 || maxCol < 0) {
    return null;
  }

  for (var row = 0; row <= maxRow; row++) {
    for (var col = 0; col <= maxCol; col++) {
      final anchor = BoardCellPosition(row: row, col: col);
      if (_canScatterPieceAt(
        piece: piece,
        anchor: anchor,
        canvasRows: canvasRows,
        canvasCols: canvasCols,
        placedPieces: placedPieces,
      )) {
        return anchor;
      }
    }
  }

  return null;
}

bool _canScatterPieceAt({
  required PuzzlePiece piece,
  required BoardCellPosition anchor,
  required int canvasRows,
  required int canvasCols,
  required List<PuzzlePiece> placedPieces,
}) {
  return canPlaceOnBoard(
    movingPiece: piece,
    targetAnchorRow: anchor.row,
    targetAnchorCol: anchor.col,
    boardRows: canvasRows,
    boardCols: canvasCols,
    pieces: placedPieces,
  );
}

PuzzlePiece _pieceAtAnchor(PuzzlePiece piece, BoardCellPosition anchor) {
  return PuzzlePiece(
    id: piece.id,
    chunkId: piece.chunkId,
    anchorRow: anchor.row,
    anchorCol: anchor.col,
    spawnAnchorRow: piece.spawnAnchorRow,
    spawnAnchorCol: piece.spawnAnchorCol,
    cells: piece.cells,
    isCompletedWordGroup: piece.isCompletedWordGroup,
    completedWordKey: piece.completedWordKey,
    completedAnswers: piece.completedAnswers,
  );
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
