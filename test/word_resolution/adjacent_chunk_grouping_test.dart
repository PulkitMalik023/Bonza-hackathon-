import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

import 'word_resolution_test_helpers.dart';

PuzzleLayoutMetadata appleNextMetadata() {
  return metadataForWords(const [
    PlacedWord(
      word: 'APPLE',
      row: 0,
      col: 0,
      direction: WordDirection.horizontal,
    ),
    PlacedWord(
      word: 'NEXT',
      row: 0,
      col: 5,
      direction: WordDirection.horizontal,
    ),
  ]);
}

PuzzlePiece pieceAtFinalCell({
  required PuzzleLayoutMetadata metadata,
  required PuzzleChunkRef ref,
  required String finalCellId,
  required int boardRow,
  required int boardCol,
}) {
  for (final entry in ref.chunk.localCells.entries) {
    final localRow = entry.key.row;
    final localCol = entry.key.col;
    final cellId = metadata.finalCellIdForChunkLocal(
      chunkId: ref.chunkId,
      localRow: localRow,
      localCol: localCol,
    );
    if (cellId == finalCellId) {
      return pieceMovedOnBoard(
        PuzzlePiece.fromChunk(
          ref.chunk,
          anchorRow: boardRow - localRow,
          anchorCol: boardCol - localCol,
        ),
      );
    }
  }

  throw StateError('Chunk ${ref.chunkId} does not contain $finalCellId');
}

void main() {
  test('APPLE completion does not absorb adjacent NEXT chunk placed beside lead chunk', () {
    final metadata = appleNextMetadata();
    final appleId = wordIdForText(metadata, 'APPLE')!;
    final nextId = wordIdForText(metadata, 'NEXT')!;
    final appleChunkIds = metadata.wordToChunkCoverage[appleId]!
        .map((entry) => entry.chunkId)
        .toSet();
    final tCellId = metadata.wordById[nextId]!.cellIds.last;
    final tChunkId = chunkRefForFinalCell(metadata, tCellId).chunkId;
    final leadCellId = metadata.wordById[appleId]!.cellIds.first;
    final leadLayout = metadata.finalCellById[leadCellId]!;

    final pieces = <PuzzlePiece>[];
    var trayCol = 0;
    const trayRow = 8;

    for (final ref in metadata.chunkById.values) {
      if (appleChunkIds.contains(ref.chunkId)) {
        pieces.add(
          pieceMovedOnBoard(
            PuzzlePiece.fromChunk(
              ref.chunk,
              anchorRow: ref.chunk.solvedMinRow,
              anchorCol: ref.chunk.solvedMinCol,
            ),
          ),
        );
        continue;
      }

      if (ref.chunkId == tChunkId) {
        pieces.add(
          pieceAtFinalCell(
            metadata: metadata,
            ref: chunkRefForFinalCell(metadata, tCellId),
            finalCellId: tCellId,
            boardRow: leadLayout.row + 1,
            boardCol: leadLayout.col,
          ),
        );
        continue;
      }

      pieces.add(
        PuzzlePiece.fromChunk(
          ref.chunk,
          anchorRow: trayRow,
          anchorCol: trayCol,
        ),
      );
      trayCol += ref.chunk.width + 1;
    }

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: {...appleChunkIds, tChunkId},
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, contains('APPLE'));
    expect(result.completedAnswers, isNot(contains('NEXT')));

    final adjacentNextChunk = result.pieces
        .where(
          (piece) => !piece.isCompletedWordGroup && piece.chunkId == tChunkId,
        )
        .toList();
    expect(
      adjacentNextChunk,
      hasLength(1),
      reason: 'Adjacent NEXT chunk must remain a separate active piece',
    );
    expect(
      adjacentNextChunk.first.cells.map((cell) => cell.letter).toSet(),
      contains('T'),
    );
  });
}
