import 'dart:math';

import 'package:flutter/foundation.dart';

import 'board_cell_position.dart';
import 'board_geometry.dart';
import 'chunk_drop_evaluator.dart';
import 'puzzle_piece.dart';

/// Minimum empty grid cells between any two chunk tiles at spawn.
const kSpawnSeparationCells = 1;

const _colGap = 2;
const _rowGap = 2;
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

  final separated = _tryScatterWithBuffer(
    pieces: pieces,
    canvasRows: canvasRows,
    canvasCols: canvasCols,
    random: rng,
    separationCells: kSpawnSeparationCells,
  );
  if (separated != null) {
    return RandomScatterResult(
      anchors: separated,
      mode: ScatterPlacementMode.random,
    );
  }

  final tight = _tryScatterWithBuffer(
    pieces: pieces,
    canvasRows: canvasRows,
    canvasCols: canvasCols,
    random: rng,
    separationCells: 0,
  );
  if (tight != null) {
    return RandomScatterResult(
      anchors: tight,
      mode: ScatterPlacementMode.random,
    );
  }

  if (kDebugMode) {
    debugPrint(
      '[PieceSpawnLayout] Random scatter failed for all pieces; '
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

List<BoardCellPosition>? _tryScatterWithBuffer({
  required List<PuzzlePiece> pieces,
  required int canvasRows,
  required int canvasCols,
  required Random random,
  required int separationCells,
}) {
  final order = List<int>.generate(pieces.length, (index) => index)
    ..shuffle(random);
  final anchors = List<BoardCellPosition?>.filled(pieces.length, null);
  final placedPieces = <PuzzlePiece>[];

  for (final index in order) {
    final piece = pieces[index];
    final anchor = _findRandomScatterAnchor(
          piece: piece,
          canvasRows: canvasRows,
          canvasCols: canvasCols,
          placedPieces: placedPieces,
          random: random,
          separationCells: separationCells,
        ) ??
        _findExhaustiveScatterAnchor(
          piece: piece,
          canvasRows: canvasRows,
          canvasCols: canvasCols,
          placedPieces: placedPieces,
          separationCells: separationCells,
        );

    if (anchor == null) {
      return null;
    }

    anchors[index] = anchor;
    placedPieces.add(_pieceAtAnchor(piece, anchor));
  }

  return [
    for (final anchor in anchors)
      anchor ?? const BoardCellPosition(row: 0, col: 0),
  ];
}

BoardCellPosition? _findRandomScatterAnchor({
  required PuzzlePiece piece,
  required int canvasRows,
  required int canvasCols,
  required List<PuzzlePiece> placedPieces,
  required Random random,
  required int separationCells,
}) {
  final size = pieceGridSize(piece);
  final maxRow = canvasRows - size.height.toInt();
  final maxCol = canvasCols - size.width.toInt();
  if (maxRow < 0 || maxCol < 0) {
    return null;
  }

  BoardCellPosition? bestAnchor;
  var bestMinDistance = -1.0;

  for (var attempt = 0; attempt < _maxRandomAttemptsPerPiece; attempt++) {
    final row = maxRow == 0 ? 0 : random.nextInt(maxRow + 1);
    final col = maxCol == 0 ? 0 : random.nextInt(maxCol + 1);
    final anchor = BoardCellPosition(row: row, col: col);
    if (!_canScatterPieceAt(
      piece: piece,
      anchor: anchor,
      canvasRows: canvasRows,
      canvasCols: canvasCols,
      placedPieces: placedPieces,
      separationCells: separationCells,
    )) {
      continue;
    }

    final minDistance = _minDistanceToPlacedPieces(
      piece: piece,
      anchor: anchor,
      placedPieces: placedPieces,
    );
    if (minDistance > bestMinDistance) {
      bestMinDistance = minDistance;
      bestAnchor = anchor;
    }
  }

  return bestAnchor;
}

BoardCellPosition? _findExhaustiveScatterAnchor({
  required PuzzlePiece piece,
  required int canvasRows,
  required int canvasCols,
  required List<PuzzlePiece> placedPieces,
  required int separationCells,
}) {
  final size = pieceGridSize(piece);
  final maxRow = canvasRows - size.height.toInt();
  final maxCol = canvasCols - size.width.toInt();
  if (maxRow < 0 || maxCol < 0) {
    return null;
  }

  BoardCellPosition? bestAnchor;
  var bestMinDistance = -1.0;

  for (var row = 0; row <= maxRow; row++) {
    for (var col = 0; col <= maxCol; col++) {
      final anchor = BoardCellPosition(row: row, col: col);
      if (!_canScatterPieceAt(
        piece: piece,
        anchor: anchor,
        canvasRows: canvasRows,
        canvasCols: canvasCols,
        placedPieces: placedPieces,
        separationCells: separationCells,
      )) {
        continue;
      }

      final minDistance = _minDistanceToPlacedPieces(
        piece: piece,
        anchor: anchor,
        placedPieces: placedPieces,
      );
      if (minDistance > bestMinDistance) {
        bestMinDistance = minDistance;
        bestAnchor = anchor;
      }
    }
  }

  return bestAnchor;
}

bool _canScatterPieceAt({
  required PuzzlePiece piece,
  required BoardCellPosition anchor,
  required int canvasRows,
  required int canvasCols,
  required List<PuzzlePiece> placedPieces,
  required int separationCells,
}) {
  if (!canPlaceOnBoard(
    movingPiece: piece,
    targetAnchorRow: anchor.row,
    targetAnchorCol: anchor.col,
    boardRows: canvasRows,
    boardCols: canvasCols,
    pieces: placedPieces,
  )) {
    return false;
  }

  if (separationCells <= 0) {
    return true;
  }

  final candidateBuffer = _occupiedCellsWithBuffer(
    piece.getOccupiedCellsAt(anchor.row, anchor.col),
    separationCells,
  );

  for (final placedPiece in placedPieces) {
    final placedBuffer = _occupiedCellsWithBuffer(
      placedPiece.getOccupiedCells(),
      separationCells,
    );
    for (final cell in candidateBuffer) {
      if (placedBuffer.contains(cell)) {
        return false;
      }
    }
  }

  return true;
}

Set<BoardCellPosition> _occupiedCellsWithBuffer(
  Iterable<BoardCellPosition> cells,
  int buffer,
) {
  if (buffer <= 0) {
    return cells.toSet();
  }

  final expanded = <BoardCellPosition>{};
  for (final cell in cells) {
    for (var row = cell.row - buffer; row <= cell.row + buffer; row++) {
      for (var col = cell.col - buffer; col <= cell.col + buffer; col++) {
        expanded.add(BoardCellPosition(row: row, col: col));
      }
    }
  }

  return expanded;
}

double _minDistanceToPlacedPieces({
  required PuzzlePiece piece,
  required BoardCellPosition anchor,
  required List<PuzzlePiece> placedPieces,
}) {
  if (placedPieces.isEmpty) {
    return double.infinity;
  }

  final candidateCells = piece.getOccupiedCellsAt(anchor.row, anchor.col);
  var minDistance = double.infinity;

  for (final placedPiece in placedPieces) {
    for (final placedCell in placedPiece.getOccupiedCells()) {
      for (final candidateCell in candidateCells) {
        final distance = max(
          (candidateCell.row - placedCell.row).abs(),
          (candidateCell.col - placedCell.col).abs(),
        ).toDouble();
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
    }
  }

  return minDistance;
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

/// Returns true when every pair of occupied cells from different pieces has
/// Chebyshev distance greater than [separationCells].
bool piecesHaveSpawnSeparation({
  required List<PuzzlePiece> pieces,
  int separationCells = kSpawnSeparationCells,
}) {
  if (separationCells <= 0 || pieces.length < 2) {
    return true;
  }

  final occupiedByPiece = <String, List<BoardCellPosition>>{};
  for (final piece in pieces) {
    occupiedByPiece[piece.id] = piece.getOccupiedCells();
  }

  final pieceIds = occupiedByPiece.keys.toList();
  for (var i = 0; i < pieceIds.length; i++) {
    for (var j = i + 1; j < pieceIds.length; j++) {
      for (final cellA in occupiedByPiece[pieceIds[i]]!) {
        for (final cellB in occupiedByPiece[pieceIds[j]]!) {
          final distance = max(
            (cellA.row - cellB.row).abs(),
            (cellA.col - cellB.col).abs(),
          );
          if (distance <= separationCells) {
            return false;
          }
        }
      }
    }
  }

  return true;
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
