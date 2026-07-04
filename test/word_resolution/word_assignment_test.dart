import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/candidate_word_scanner.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_runtime_state.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_assignment.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_models.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

import 'word_resolution_test_helpers.dart';

void main() {
  test('strict assignment requires layout coordinates', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'FORK',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);
    final wordId = metadata.targetWordIds.first;

    final onLayout = rebuildRuntimeBoardState(
      pieces: piecesAtLayoutPositions(metadata),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final offLayout = rebuildRuntimeBoardState(
      pieces: connectedPiecesAtRow(metadata: metadata, row: 5),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(
      getPossibleAssignmentsForWord_Strict(
        wordId: wordId,
        state: onLayout,
        metadata: metadata,
      ),
      isNotEmpty,
    );
    expect(
      getPossibleAssignmentsForWord_Strict(
        wordId: wordId,
        state: offLayout,
        metadata: metadata,
      ),
      isEmpty,
    );
  });

  test('flexible assignment accepts runtime candidate at non-layout coordinates', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'FORK',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);
    final wordId = metadata.targetWordIds.first;

    final pieces = connectedPiecesAtRow(metadata: metadata, row: 2);

    final state = rebuildRuntimeBoardState(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final candidates = scanCandidateWordsForWholeBoard(
      state: state,
      metadata: metadata,
    );
    final forkCandidate = candidates.firstWhere(
      (candidate) => candidate.text == 'FORK',
    );

    final flexible = getPossibleAssignmentsForWord_Flexible(
      wordId: wordId,
      state: state,
      metadata: metadata,
      options: WordResolutionOptions(
        candidateWordInstances: [forkCandidate],
      ),
    );

    expect(flexible, isNotEmpty);
    expect(flexible.first.assignmentType, AssignmentType.flexibleIndependent);
  });

  test('shared intersection cell is not blocked for crossing word', () {
    final metadata = cutleryMetadata();
    final wordIds = metadata.targetWordIds;
    final spoonId = wordIds.firstWhere(
      (id) => metadata.wordById[id]!.text == 'SPOON',
    );
    final knifeId = wordIds.firstWhere(
      (id) => metadata.wordById[id]!.text == 'KNIFE',
    );
    final sharedCell = metadata.wordById[spoonId]!
        .cellIds
        .toSet()
        .intersection(metadata.wordById[knifeId]!.cellIds.toSet())
        .single;

    final pieces = connectedCrosswordPieces(metadata: metadata);
    final state = rebuildRuntimeBoardState(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: {spoonId},
      reservedCellIds: metadata.wordById[spoonId]!.cellIds.toSet(),
      solvedAssignments: {
        spoonId: SolvedAssignment(
          wordId: spoonId,
          assignedCellIds: metadata.wordById[spoonId]!.cellIds.toSet(),
          moveComponentId: 'cmp_test',
        ),
      },
    );

    expect(
      isSharedIntersectionCell(
        cellId: sharedCell,
        wordId: knifeId,
        state: state,
        metadata: metadata,
      ),
      isTrue,
    );
    expect(
      isCellBlockedByReservation(
        cellId: sharedCell,
        wordId: knifeId,
        state: state,
        metadata: metadata,
      ),
      isFalse,
    );
  });

  test('inventory passes when all letters on board but not contiguous', () {
    final metadata = cutleryMetadata();
    final spoonId = metadata.targetWordIds.firstWhere(
      (id) => metadata.wordById[id]!.text == 'SPOON',
    );

    final state = rebuildRuntimeBoardState(
      pieces: cutleryWithKnifeConnectedOnly(metadata),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(
      canWordBeSatisfiedFromBoardInventory(
        wordId: spoonId,
        state: state,
        metadata: metadata,
      ),
      isTrue,
    );
  });

  test('inventory fails when a required letter is missing from board', () {
    final metadata = cutleryMetadata();
    final spoonId = metadata.targetWordIds.firstWhere(
      (id) => metadata.wordById[id]!.text == 'SPOON',
    );

    final pieces = cutleryWithKnifeConnectedOnly(metadata)
        .where((piece) => !piece.cells.any((cell) => cell.letter == 'S'))
        .toList();

    final state = rebuildRuntimeBoardState(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(
      canWordBeSatisfiedFromBoardInventory(
        wordId: spoonId,
        state: state,
        metadata: metadata,
      ),
      isFalse,
    );
  });

  test('flexible assignment binds runtime candidate to word slots by letter order', () {
    final metadata = directionsMetadata();
    final westId = wordIdForText(metadata, 'WEST')!;
    final westCells = metadata.wordById[westId]!.cellIds;

    final eastLayout = directionsPiecesForEastFirstWestTest(metadata);
    final eastResult = handlePuzzleStateAfterReconnect(
      pieces: eastLayout,
      metadata: metadata,
      movedChunkIds: eastFirstWestMovedChunkIds(metadata),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final westLayout = directionsPiecesWithWestWeAboveCompletedEast(
      eastResult.pieces,
      metadata,
    );
    final state = rebuildRuntimeBoardState(
      pieces: westLayout,
      metadata: metadata,
      solvedWordIds: eastResult.solvedWordIds,
      reservedCellIds: eastResult.reservedCellIds,
      solvedAssignments: eastResult.solvedAssignments,
    );

    final candidates = scanCandidateWordsForWholeBoard(
      state: state,
      metadata: metadata,
    );
    final westCandidate = candidates.firstWhere(
      (candidate) => candidate.text == 'WEST',
    );

    expect(
      bindCandidateToWordSlots(
        wordId: westId,
        candidate: westCandidate,
        metadata: metadata,
      ),
      equals(westCells),
    );

    final flexible = getPossibleAssignmentsForWord_Flexible(
      wordId: westId,
      state: state,
      metadata: metadata,
      options: WordResolutionOptions(
        candidateWordInstances: [westCandidate],
      ),
    );

    expect(flexible, isNotEmpty);
    expect(flexible.first.reservedFinalCellIds, equals(westCells));
    expect(
      assignmentsForCandidate(
        wordId: westId,
        candidate: westCandidate,
        state: state,
        metadata: metadata,
        options: const WordResolutionOptions(),
      ),
      isNotEmpty,
    );
  });
}
