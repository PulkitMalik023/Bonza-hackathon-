import '../data/models/placed_word.dart';
import '../data/models/puzzle_layout.dart';
import 'piece_cell.dart';
import 'piece_spawn_layout.dart';
import 'puzzle_piece.dart';

List<PieceCell> cellsForPlacedWord(PlacedWord placed) {
  final word = placed.word.toUpperCase();

  return [
    for (var index = 0; index < word.length; index++)
      switch (placed.direction) {
        WordDirection.horizontal => PieceCell(
            letter: word[index],
            rowOffset: 0,
            colOffset: index,
          ),
        WordDirection.vertical => PieceCell(
            letter: word[index],
            rowOffset: index,
            colOffset: 0,
          ),
      },
  ];
}

List<PuzzlePiece> buildWordPiecesWithoutAnchors(PuzzleLayout layout) {
  final pieces = <PuzzlePiece>[];

  for (var index = 0; index < layout.placedWords.length; index++) {
    final placed = layout.placedWords[index];
    final id = 'word_${index}_${placed.word}';

    pieces.add(
      PuzzlePiece(
        id: id,
        chunkId: id,
        anchorRow: 0,
        anchorCol: 0,
        spawnAnchorRow: 0,
        spawnAnchorCol: 0,
        cells: cellsForPlacedWord(placed),
      ),
    );
  }

  return pieces;
}

List<PuzzlePiece> buildWordPieces({
  required PuzzleLayout layout,
  required int canvasRows,
  required int canvasCols,
}) {
  final pieces = buildWordPiecesWithoutAnchors(layout);
  final anchors = computePieceSpawnAnchors(
    pieces: pieces,
    canvasRows: canvasRows,
    canvasCols: canvasCols,
  );

  return applySpawnAnchors(pieces, anchors);
}

@Deprecated('Use pieceSpawnAnchorsAreNonOverlapping')
bool wordSpawnAnchorsAreNonOverlapping(List<PuzzlePiece> pieces) =>
    pieceSpawnAnchorsAreNonOverlapping(pieces);

@Deprecated('Use piecesFitCanvas')
bool wordPiecesFitCanvas({
  required List<PuzzlePiece> pieces,
  required int canvasRows,
  required int canvasCols,
}) =>
    piecesFitCanvas(
      pieces: pieces,
      canvasRows: canvasRows,
      canvasCols: canvasCols,
    );
