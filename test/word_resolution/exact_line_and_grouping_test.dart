import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/candidate_word_scanner.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_runtime_state.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

import 'word_resolution_test_helpers.dart';

PuzzlePiece pieceAtFinalCell({
  required PuzzleLayoutMetadata metadata,
  required String finalCellId,
  required int boardRow,
  required int boardCol,
}) {
  final ref = chunkRefForFinalCell(metadata, finalCellId);
  for (final entry in ref.chunk.localCells.entries) {
    final localRow = entry.key.row;
    final localCol = entry.key.col;
    final cellId = metadata.finalCellIdForChunkLocal(
      chunkId: ref.chunkId,
      localRow: localRow,
      localCol: localCol,
    );
    if (cellId == finalCellId) {
      return PuzzlePiece.fromChunk(
        ref.chunk,
        anchorRow: boardRow - localRow,
        anchorCol: boardCol - localCol,
      );
    }
  }

  throw StateError('Chunk ${ref.chunkId} does not contain $finalCellId');
}

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

List<PuzzlePiece> applenConnectedPieces(PuzzleLayoutMetadata metadata) {
  final appleId = wordIdForText(metadata, 'APPLE')!;
  final nextId = wordIdForText(metadata, 'NEXT')!;
  final appleChunkIds = metadata.wordToChunkCoverage[appleId]!
      .map((entry) => entry.chunkId)
      .toSet();
  final nCellId = metadata.wordById[nextId]!.cellIds.first;
  final eCellId = metadata.wordById[appleId]!.cellIds.last;
  final eLayout = metadata.finalCellById[eCellId]!;
  final nChunkId = chunkRefForFinalCell(metadata, nCellId).chunkId;

  final pieces = <PuzzlePiece>[];
  var scatterRow = 12;
  var scatterCol = 0;

  for (final ref in metadata.chunkById.values) {
    if (appleChunkIds.contains(ref.chunkId)) {
      pieces.add(
        PuzzlePiece.fromChunk(
          ref.chunk,
          anchorRow: ref.chunk.solvedMinRow,
          anchorCol: ref.chunk.solvedMinCol,
        ),
      );
      continue;
    }

    if (ref.chunkId == nChunkId) {
      pieces.add(
        pieceAtFinalCell(
          metadata: metadata,
          finalCellId: nCellId,
          boardRow: eLayout.row,
          boardCol: eLayout.col + 1,
        ),
      );
      continue;
    }

    pieces.add(
      PuzzlePiece.fromChunk(
        ref.chunk,
        anchorRow: scatterRow,
        anchorCol: scatterCol,
      ),
    );
    scatterCol += ref.chunk.width.toInt() + 1;
  }

  return pieces;
}

List<PuzzlePiece> wonOnlyConnectedAntScattered(PuzzleLayoutMetadata metadata) {
  final antId = wordIdForText(metadata, 'ANT')!;
  final antChunkIds = metadata.wordToChunkCoverage[antId]!
      .map((entry) => entry.chunkId)
      .toSet();

  final pieces = <PuzzlePiece>[];
  var scatterRow = 12;
  var scatterCol = 0;

  for (final piece in connectedCrosswordPieces(metadata: metadata)) {
    if (antChunkIds.contains(piece.chunkId)) {
      pieces.add(
        PuzzlePiece(
          id: piece.id,
          chunkId: piece.chunkId,
          anchorRow: scatterRow,
          anchorCol: scatterCol,
          spawnAnchorRow: piece.spawnAnchorRow,
          spawnAnchorCol: piece.spawnAnchorCol,
          cells: piece.cells,
        ),
      );
      final ref = metadata.chunkById[piece.chunkId]!;
      scatterCol += ref.chunk.width.toInt() + 1;
      continue;
    }

    pieces.add(piece);
  }

  return pieces;
}

void main() {
  test('APPLEN line is filtered out by exact-target scan', () {
    final metadata = appleNextMetadata();

    final state = rebuildRuntimeBoardState(
      pieces: applenConnectedPieces(metadata),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final candidates = scanCandidateWordsForWholeBoard(
      state: state,
      metadata: metadata,
    );

    expect(candidates.any((candidate) => candidate.text == 'APPLEN'), isFalse);
    expect(candidates.any((candidate) => candidate.text == 'APPLE'), isFalse);
  });

  test('APPLEN connected board does not complete APPLE on tile release', () {
    final metadata = appleNextMetadata();

    final result = handlePuzzleStateAfterReconnect(
      pieces: applenConnectedPieces(metadata),
      metadata: metadata,
      movedChunkIds: {
        ...metadata.chunkById.keys,
      },
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, isNot(contains('APPLE')));
    expect(result.newlySolvedWordIds, isEmpty);
  });

  test('APPLE exact line completes when connected at runtime', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'APPLE',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);

    final pieces = connectedPiecesAtRow(metadata: metadata, row: 0);
    final movedChunkIds = metadata.chunkById.keys.take(1);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: movedChunkIds,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, contains('APPLE'));
    expect(result.newlySolvedWordIds, isNotEmpty);

    final completedGroups =
        result.pieces.where((piece) => piece.isCompletedWordGroup).toList();
    expect(completedGroups, hasLength(1));
    expect(completedGroups.first.cells.length, equals(5));
  });

  test('WON does not complete when ANT is disconnected and needs shared N', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'WON',
        row: 1,
        col: 0,
        direction: WordDirection.horizontal,
      ),
      PlacedWord(
        word: 'ANT',
        row: 0,
        col: 2,
        direction: WordDirection.vertical,
      ),
    ]);

    final pieces = wonOnlyConnectedAntScattered(metadata);
    final wonId = wordIdForText(metadata, 'WON')!;
    final movedChunkIds = metadata.wordToChunkCoverage[wonId]!
        .map((entry) => entry.chunkId)
        .take(1);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: movedChunkIds,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, isNot(contains('WON')));
    expect(result.newlySolvedWordIds, isEmpty);
  });

  test('NORTH SOUTH crossing accepts both when fully connected', () {
    final metadata = directionsMetadata();
    final pieces = connectedCrosswordPieces(metadata: metadata);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: metadata.chunkById.keys.take(1),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, containsAll(['NORTH', 'SOUTH']));
  });
}
