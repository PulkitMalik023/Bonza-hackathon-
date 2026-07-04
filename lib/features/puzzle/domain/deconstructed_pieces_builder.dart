import 'dart:math';

import '../data/deconstructors/puzzle_deconstructor.dart';
import '../data/models/deconstructed_puzzle.dart';
import '../data/models/puzzle_layout.dart';
import '../presentation/puzzle_tray_layout.dart';
import 'piece_spawn_layout.dart';
import 'puzzle_piece.dart';

List<PuzzlePiece> buildDeconstructedPlayPieces({
  required PuzzleLayout layout,
  required int canvasRows,
  required int canvasCols,
  Random? random,
}) {
  final deconstructed = PuzzleDeconstructor().build(layout);
  final pieces = deconstructed.chunks
      .map(
        (chunk) => PuzzlePiece.fromChunk(
          chunk,
          anchorRow: 0,
          anchorCol: 0,
        ),
      )
      .toList();

  final scatter = computeRandomScatter(
    pieces: pieces,
    canvasRows: canvasRows,
    canvasCols: canvasCols,
    random: random,
  );

  if (scatter.mode == ScatterPlacementMode.random) {
    return applySpawnAnchors(pieces, scatter.anchors);
  }

  final trayLayout = ChunkTrayLayoutService().compute(
    boardRows: canvasRows,
    boardCols: canvasCols,
    chunks: deconstructed.chunks,
    tileSize: 1,
  );

  if (trayLayout.fitsInBoard && trayLayout.anchors.length == pieces.length) {
    return ChunkTrayLayoutService().buildPieces(
      chunks: deconstructed.chunks,
      layout: trayLayout,
    );
  }

  return applySpawnAnchors(pieces, scatter.anchors);
}

List<PuzzlePiece> buildDeconstructedPlayPiecesFromDeconstruction({
  required DeconstructedPuzzle deconstructed,
  required int canvasRows,
  required int canvasCols,
  Random? random,
}) {
  final pieces = deconstructed.chunks
      .map(
        (chunk) => PuzzlePiece.fromChunk(
          chunk,
          anchorRow: 0,
          anchorCol: 0,
        ),
      )
      .toList();

  final scatter = computeRandomScatter(
    pieces: pieces,
    canvasRows: canvasRows,
    canvasCols: canvasCols,
    random: random,
  );

  if (scatter.mode == ScatterPlacementMode.random) {
    return applySpawnAnchors(pieces, scatter.anchors);
  }

  final trayLayout = ChunkTrayLayoutService().compute(
    boardRows: canvasRows,
    boardCols: canvasCols,
    chunks: deconstructed.chunks,
    tileSize: 1,
  );

  if (trayLayout.fitsInBoard && trayLayout.anchors.length == pieces.length) {
    return ChunkTrayLayoutService().buildPieces(
      chunks: deconstructed.chunks,
      layout: trayLayout,
    );
  }

  return applySpawnAnchors(pieces, scatter.anchors);
}
