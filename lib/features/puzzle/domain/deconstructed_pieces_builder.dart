import '../data/deconstructors/puzzle_deconstructor.dart';
import '../data/models/puzzle_layout.dart';
import 'piece_spawn_layout.dart';
import 'puzzle_piece.dart';

List<PuzzlePiece> buildDeconstructedPlayPieces({
  required PuzzleLayout layout,
  required int canvasRows,
  required int canvasCols,
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

  final anchors = computePieceSpawnAnchors(
    pieces: pieces,
    canvasRows: canvasRows,
    canvasCols: canvasCols,
  );

  return applySpawnAnchors(pieces, anchors);
}
