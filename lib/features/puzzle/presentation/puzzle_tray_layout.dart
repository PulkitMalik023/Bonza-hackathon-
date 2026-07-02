import 'dart:math';
import 'dart:ui';

import '../../../core/constants/board_constants.dart';
import '../data/models/puzzle_chunk.dart';
import '../domain/board_geometry.dart';
import '../domain/puzzle_piece.dart';

class ChunkTrayAnchor {
  const ChunkTrayAnchor({
    required this.row,
    required this.col,
  });

  final int row;
  final int col;
}

class ChunkTrayLayoutResult {
  const ChunkTrayLayoutResult({
    required this.canvasRows,
    required this.canvasCols,
    required this.anchors,
  });

  final int canvasRows;
  final int canvasCols;
  final List<ChunkTrayAnchor> anchors;
}

class ChunkTrayLayoutService {
  static const _boardTrayGapRows = 1;

  ChunkTrayLayoutResult compute({
    required int boardRows,
    required int boardCols,
    required List<PuzzleChunk> chunks,
    required double tileSize,
    Size? viewportSize,
  }) {
    if (chunks.isEmpty) {
      return ChunkTrayLayoutResult(
        canvasRows: boardRows,
        canvasCols: boardCols,
        anchors: const [],
      );
    }

    ChunkTrayLayoutResult? bestResult;
    var bestCanvasArea = double.infinity;

    for (var chunksPerRow = 3; chunksPerRow >= 1; chunksPerRow--) {
      for (var rowGap = 2; rowGap >= 1; rowGap--) {
        final result = _computeWithLayout(
          boardRows: boardRows,
          boardCols: boardCols,
          chunks: chunks,
          chunksPerRow: chunksPerRow,
          rowGap: rowGap,
        );

        if (viewportSize == null) {
          return result;
        }

        final canvasArea = result.canvasRows * result.canvasCols;
        if (canvasArea < bestCanvasArea) {
          bestCanvasArea = canvasArea.toDouble();
          bestResult = result;
        }

        if (_fitsViewport(
          result: result,
          chunks: chunks,
          tileSize: tileSize,
          viewportSize: viewportSize,
        )) {
          return result;
        }
      }
    }

    return bestResult!;
  }

  ChunkTrayLayoutResult _computeWithLayout({
    required int boardRows,
    required int boardCols,
    required List<PuzzleChunk> chunks,
    required int chunksPerRow,
    required int rowGap,
  }) {
    final anchors = <ChunkTrayAnchor>[];
    var trayRowWidth = 0;
    var maxChunkHeight = 1;

    for (var index = 0; index < chunks.length; index++) {
      final chunk = chunks[index];
      maxChunkHeight = max(maxChunkHeight, chunk.height);

      final slotInRow = index % chunksPerRow;
      if (slotInRow == 0) {
        trayRowWidth = 0;
      }

      anchors.add(
        ChunkTrayAnchor(
          row: boardRows + _boardTrayGapRows + (index ~/ chunksPerRow) * rowGap,
          col: trayRowWidth,
        ),
      );

      trayRowWidth += chunk.width + 1;
    }

    final lastTrayRowIndex = (chunks.length - 1) ~/ chunksPerRow;
    var maxTrayRowWidth = 0;
    trayRowWidth = 0;
    for (var index = 0; index < chunks.length; index++) {
      final chunk = chunks[index];
      final slotInRow = index % chunksPerRow;

      if (slotInRow == 0) {
        maxTrayRowWidth = max(maxTrayRowWidth, trayRowWidth);
        trayRowWidth = 0;
      }

      trayRowWidth += chunk.width + 1;
    }
    maxTrayRowWidth = max(maxTrayRowWidth, trayRowWidth);

    final canvasCols = max(boardCols, maxTrayRowWidth);
    final canvasRows = boardRows +
        _boardTrayGapRows +
        lastTrayRowIndex * rowGap +
        maxChunkHeight;

    _assertWithinCanvas(
      chunks: chunks,
      anchors: anchors,
      canvasRows: canvasRows,
      canvasCols: canvasCols,
    );

    return ChunkTrayLayoutResult(
      canvasRows: canvasRows,
      canvasCols: canvasCols,
      anchors: anchors,
    );
  }

  bool _fitsViewport({
    required ChunkTrayLayoutResult result,
    required List<PuzzleChunk> chunks,
    required double tileSize,
    required Size viewportSize,
  }) {
    final canvasWidth = result.canvasCols * tileSize;
    final canvasHeight = result.canvasRows * tileSize;

    if (canvasWidth > viewportSize.width || canvasHeight > viewportSize.height) {
      return false;
    }

    return allChunksVisibleAfterCentering(
      chunks: chunks,
      anchors: result.anchors,
      canvasRows: result.canvasRows,
      canvasCols: result.canvasCols,
      tileSize: tileSize,
      viewportSize: viewportSize,
    );
  }

  void _assertWithinCanvas({
    required List<PuzzleChunk> chunks,
    required List<ChunkTrayAnchor> anchors,
    required int canvasRows,
    required int canvasCols,
  }) {
    assert(chunks.length == anchors.length);

    for (var index = 0; index < chunks.length; index++) {
      final chunk = chunks[index];
      final anchor = anchors[index];

      assert(anchor.row >= 0 && anchor.col >= 0);
      assert(anchor.row + chunk.height <= canvasRows);
      assert(anchor.col + chunk.width <= canvasCols);
    }
  }

  List<PuzzlePiece> buildPieces({
    required List<PuzzleChunk> chunks,
    required ChunkTrayLayoutResult layout,
  }) {
    return [
      for (var index = 0; index < chunks.length; index++)
        PuzzlePiece.fromChunk(
          chunks[index],
          anchorRow: layout.anchors[index].row,
          anchorCol: layout.anchors[index].col,
        ),
    ];
  }
}

/// Returns true when two pieces occupy any of the same grid cells.
bool piecesOverlapAtSpawn(PuzzlePiece a, PuzzlePiece b) {
  final aCells = a.getOccupiedCells().toSet();
  for (final cell in b.getOccupiedCells()) {
    if (aCells.contains(cell)) {
      return true;
    }
  }
  return false;
}

/// Returns true if every piece anchor + extent fits inside the canvas.
bool allPiecesFitCanvas({
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

/// Returns true when every chunk pixel rect is visible after canvas centering.
bool allChunksVisibleAfterCentering({
  required List<PuzzleChunk> chunks,
  required List<ChunkTrayAnchor> anchors,
  required int canvasRows,
  required int canvasCols,
  required double tileSize,
  required Size viewportSize,
}) {
  assert(chunks.length == anchors.length);

  final canvasWidth = canvasCols * tileSize;
  final canvasHeight = canvasRows * tileSize;
  final left = BoardConstants.snapToGrid((viewportSize.width - canvasWidth) / 2)
      .clamp(0.0, viewportSize.width);
  final top = BoardConstants.snapToGrid((viewportSize.height - canvasHeight) / 2)
      .clamp(0.0, viewportSize.height);
  final viewportRect = Rect.fromLTWH(0, 0, viewportSize.width, viewportSize.height);

  for (var index = 0; index < chunks.length; index++) {
    final chunk = chunks[index];
    final anchor = anchors[index];
    final topLeft = cellTopLeft(anchor.row, anchor.col, tileSize);
    final chunkRect = Rect.fromLTWH(
      left + topLeft.dx,
      top + topLeft.dy,
      chunk.width * tileSize,
      chunk.height * tileSize,
    );

    if (!viewportRect.contains(chunkRect.topLeft) ||
        chunkRect.right > viewportRect.right ||
        chunkRect.bottom > viewportRect.bottom) {
      return false;
    }
  }

  return true;
}
