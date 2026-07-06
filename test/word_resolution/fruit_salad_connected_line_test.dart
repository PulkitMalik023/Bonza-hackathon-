import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

import 'word_resolution_test_helpers.dart';

List<PuzzlePiece> fruitSaladOrangeConnectedPieces(PuzzleLayoutMetadata metadata) {
  final orangeChunkIds = chunkIdsCoveringWord(metadata, 'ORANGE').toSet();
  final pieces = <PuzzlePiece>[
    ...piecesForChunkIds(metadata, orangeChunkIds),
  ];

  var trayCol = 0;
  const trayRow = 10;

  for (final chunkId in metadata.chunkById.keys) {
    if (orangeChunkIds.contains(chunkId)) {
      continue;
    }

    final ref = metadata.chunkById[chunkId]!;
    pieces.add(
      PuzzlePiece.fromChunk(
        ref.chunk,
        anchorRow: trayRow,
        anchorCol: trayCol,
      ),
    );
    trayCol += ref.chunk.width + 1;
  }

  return piecesMovedOnBoard(pieces);
}

void main() {
  test('Fruit Salad banana-only chunks complete only BANANA at layout', () {
    final metadata = fruitSaladMetadata();
    final pieces = fruitSaladBananaOnlyPieces(metadata);
    final movedChunkIds = chunkIdsCoveringWord(metadata, 'BANANA').take(1);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: movedChunkIds,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, contains('BANANA'));
    expect(result.completedAnswers, isNot(contains('ORANGE')));
    expect(result.completedAnswers, isNot(contains('APPLE')));
    expect(result.puzzleComplete, isFalse);
  });

  test('Fruit Salad banana completes on contiguous line at arbitrary row', () {
    final metadata = fruitSaladMetadata();
    final pieces = fruitSaladBananaLineAtRow(metadata, row: 10);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: chunkIdsCoveringWord(metadata, 'BANANA').take(1),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, contains('BANANA'));
    expect(result.puzzleComplete, isFalse);
  });

  test('Fruit Salad rejects gapped banana line', () {
    final metadata = fruitSaladMetadata();
    final pieces = fruitSaladGappedBananaLineAtRow(metadata, row: 10);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: chunkIdsCoveringWord(metadata, 'BANANA').take(1),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, isNot(contains('BANANA')));
  });

  test('Fruit Salad ORANGE groups full contributing chunks when connected at layout', () {
    final metadata = fruitSaladMetadata();
    final orangeChunkIds = chunkIdsCoveringWord(metadata, 'ORANGE').toSet();
    final pieces = fruitSaladOrangeConnectedPieces(metadata);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: orangeChunkIds,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, contains('ORANGE'));
    expect(result.completedAnswers, isNot(contains('BANANA')));
    expect(result.completedAnswers, isNot(contains('APPLE')));

    final completedGroups =
        result.pieces.where((piece) => piece.isCompletedWordGroup).toList();
    expect(completedGroups, hasLength(1));

    final groupedLetters =
        completedGroups.single.cells.map((cell) => cell.letter).toSet();
    expect(groupedLetters, containsAll(['O', 'R', 'A', 'N', 'G', 'E']));
    expect(
      groupedLetters,
      contains('B'),
      reason: 'Full OR/BAN chunk moves with ORANGE, not just ORANGE letters',
    );

    final activeChunkIds = result.pieces
        .where((piece) => !piece.isCompletedWordGroup)
        .map((piece) => piece.chunkId)
        .toSet();
    expect(activeChunkIds.intersection(orangeChunkIds), isEmpty);
    expect(activeChunkIds, isNotEmpty);
  });

  test('Fruit Salad full grid completes all three words in one pass', () {
    final metadata = fruitSaladMetadata();
    final pieces = fruitSaladAllPiecesAtLayout(metadata);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: metadata.chunkById.keys.take(1),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(
      result.completedAnswers,
      containsAll(['BANANA', 'ORANGE', 'APPLE']),
    );
    expect(result.puzzleComplete, isTrue);
  });

  test('Fruit Salad intersection cells group into one completed cluster', () {
    final metadata = fruitSaladMetadata();
    final pieces = fruitSaladAllPiecesAtLayout(metadata);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: metadata.chunkById.keys.take(1),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final completedGroups =
        result.pieces.where((piece) => piece.isCompletedWordGroup).toList();

    expect(completedGroups, hasLength(1));
    expect(
      completedGroups.single.completedAnswers,
      containsAll(['BANANA', 'ORANGE', 'APPLE']),
    );
    expect(totalCompletedGroupCellCount(result.pieces), 15);
  });
}
