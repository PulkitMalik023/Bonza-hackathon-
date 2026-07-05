import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_board_state.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

import 'word_resolution_test_helpers.dart';

List<String> _chunkIdsLeftToRight(PuzzleLayoutMetadata metadata) {
  final chunkIds = metadata.chunkById.keys.toList()
    ..sort((a, b) {
      final chunkA = metadata.chunkById[a]!.chunk;
      final chunkB = metadata.chunkById[b]!.chunk;
      final colCompare = chunkA.solvedMinCol.compareTo(chunkB.solvedMinCol);
      if (colCompare != 0) {
        return colCompare;
      }
      return chunkA.solvedMinRow.compareTo(chunkB.solvedMinRow);
    });
  return chunkIds;
}

PuzzlePiece _unmovedPieceAt(PuzzlePiece piece) {
  return PuzzlePiece(
    id: piece.id,
    chunkId: piece.chunkId,
    anchorRow: piece.anchorRow,
    anchorCol: piece.anchorCol,
    spawnAnchorRow: piece.anchorRow,
    spawnAnchorCol: piece.anchorCol,
    cells: piece.cells,
  );
}

void main() {
  test('activePlayAreaPieces includes on-grid pieces that were never moved', () {
    final piece = PuzzlePiece(
      id: 'ap',
      chunkId: 'ap',
      anchorRow: 0,
      anchorCol: 0,
      spawnAnchorRow: 0,
      spawnAnchorCol: 0,
      cells: const [],
    );

    expect(isPieceAtSpawn(piece), isTrue);
    expect(activePlayAreaPieces([piece]), [piece]);
  });

  test('APPLE completes when only trailing chunk moves next to unmoved lead chunk', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'APPLE',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);

    final chunkIds = _chunkIdsLeftToRight(metadata);
    expect(chunkIds.length, greaterThanOrEqualTo(2));

    final pieces = <PuzzlePiece>[];
    var col = 0;
    for (var index = 0; index < chunkIds.length; index++) {
      final chunk = metadata.chunkById[chunkIds[index]]!.chunk;
      final piece = PuzzlePiece.fromChunk(
        chunk,
        anchorRow: 0,
        anchorCol: col,
      );
      pieces.add(index == 0 ? _unmovedPieceAt(piece) : pieceMovedOnBoard(piece));
      col += chunk.width;
    }

    final movedChunkId = chunkIds.last;

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: [movedChunkId],
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, contains('APPLE'));
  });

  test('runInitialPuzzleResolution completes prefilled on-grid words before any move', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'APPLE',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);

    final pieces = connectedPiecesAtRow(metadata: metadata, row: 0)
        .map(_unmovedPieceAt)
        .toList();

    final result = runInitialPuzzleResolution(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, contains('APPLE'));
  });
}
