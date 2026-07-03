import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_models.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

import 'word_resolution_test_helpers.dart';

void main() {
  test('Example E init resolution auto-completes prefilled word', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'FORK',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);

    final result = runInitialPuzzleResolution(
      pieces: piecesAtLayoutPositions(metadata),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.newlySolvedWordIds, isNotEmpty);
    expect(result.completedAnswers, contains('FORK'));
    expect(
      result.pieces.where((piece) => piece.isCompletedWordGroup),
      isNotEmpty,
    );
  });

  test('Example A FORK reconnect accepts connected runtime word', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'FORK',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);

    final pieces = connectedPiecesAtRow(metadata: metadata, row: 2);
    final movedChunkIds = metadata.chunkById.keys.take(1);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: movedChunkIds,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, contains('FORK'));
  });

  test('Example D separate words stay in separate completed groups', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'RED',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
      PlacedWord(
        word: 'DOG',
        row: 4,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);

    final result = runInitialPuzzleResolution(
      pieces: piecesAtLayoutPositions(metadata),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, containsAll(['RED', 'DOG']));
    expect(
      result.pieces.where((piece) => piece.isCompletedWordGroup),
      hasLength(2),
    );
  });

  test('Cutlery crossword accepts SPOON FORK KNIFE with shared intersections', () {
    final metadata = cutleryMetadata();
    final pieces = cutleryCrosswordConnected(metadata);
    final movedChunkIds = metadata.chunkById.keys.take(1);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: movedChunkIds,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, containsAll(['SPOON', 'FORK', 'KNIFE']));
    expect(result.puzzleComplete, isTrue);
  });

  test('Cutlery accepts KNIFE incrementally when remaining letters are on board', () {
    final metadata = cutleryMetadata();
    final pieces = cutleryWithKnifeConnectedOnly(metadata);
    final knifeId = knifeWordId(metadata)!;
    final movedChunkIds = knifeChunkIds(metadata).take(1);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: movedChunkIds,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.newlySolvedWordIds, contains(knifeId));
    expect(result.completedAnswers, contains('KNIFE'));
    expect(result.puzzleComplete, isFalse);
    expect(
      result.pieces.where((piece) => piece.isCompletedWordGroup),
      isNotEmpty,
    );
    expect(result.completedAnswers, isNot(contains('SPOON')));
  });

  test('KNIFE completes after FORK when connected on board', () {
    final metadata = cutleryMetadata();
    final knifeId = knifeWordId(metadata)!;
    final spoonId = metadata.targetWordIds.firstWhere(
      (id) => metadata.wordById[id]!.text == 'SPOON',
    );

    final forkOnly = completeForkOnlyInCutlery(
      metadata: metadata,
      pieces: cutleryWithForkConnectedOnly(metadata),
    );
    expect(forkOnly.completedAnswers, contains('FORK'));

    final lockedWordIds = {
      ...forkOnly.solvedWordIds,
      spoonId,
    };
    final lockedReservedCellIds = {
      ...forkOnly.reservedCellIds,
      ...metadata.wordById[spoonId]!.cellIds,
    };
    final lockedAssignments = {
      ...forkOnly.solvedAssignments,
      spoonId: SolvedAssignment(
        wordId: spoonId,
        assignedCellIds: metadata.wordById[spoonId]!.cellIds.toSet(),
        moveComponentId: 'cmp_test_spoon',
      ),
    };

    final pieces = cutleryKnifePiecesAfterForkCompleted(
      forkOnly.pieces,
      metadata,
    );
    final knifeMovedChunks = knifeChunkIds(metadata).take(1);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: knifeMovedChunks,
      solvedWordIds: lockedWordIds,
      reservedCellIds: lockedReservedCellIds,
      solvedAssignments: lockedAssignments,
    );

    expect(result.completedAnswers, containsAll(['FORK', 'KNIFE']));
    expect(result.solvedWordIds, containsAll([forkWordId(metadata)!, knifeId]));
  });
}
