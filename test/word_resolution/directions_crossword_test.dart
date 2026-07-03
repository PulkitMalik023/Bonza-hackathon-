import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_runtime_state.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_assignment.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_models.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

import 'word_resolution_test_helpers.dart';

void main() {
  test('Directions crossword accepts NORTH SOUTH EAST WEST when connected', () {
    final metadata = directionsMetadata();
    final pieces = connectedCrosswordPieces(metadata: metadata);
    final movedChunkIds = metadata.chunkById.keys.take(1);

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: movedChunkIds,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, containsAll(['NORTH', 'SOUTH', 'EAST', 'WEST']));
    expect(result.puzzleComplete, isTrue);
  });

  test('SOUTH completion includes connected EA in completed group', () {
    final metadata = directionsMetadata();
    final eastId = wordIdForText(metadata, 'EAST')!;
    final eastCells = metadata.wordById[eastId]!.cellIds;
    final eastECell = eastCells[0];
    final eastACell = eastCells[1];

    final pieces = connectedCrosswordPieces(metadata: metadata);
    final southOnly = completeSouthOnlyInDirections(
      metadata: metadata,
      pieces: pieces,
    );

    final completedGroups =
        southOnly.pieces.where((piece) => piece.isCompletedWordGroup).toList();

    expect(completedGroups, hasLength(1));
    expect(completedGroups.first.completedAnswers, contains('SOUTH'));
    expect(completedGroups.first.cells.length, greaterThanOrEqualTo(7));
    expect(
      activePiecesContainFinalCell(
        pieces: southOnly.pieces,
        metadata: metadata,
        finalCellId: eastECell,
      ),
      isFalse,
    );
    expect(
      activePiecesContainFinalCell(
        pieces: southOnly.pieces,
        metadata: metadata,
        finalCellId: eastACell,
      ),
      isFalse,
    );
  });

  test('NORTH after SOUTH merges into one draggable completed group', () {
    final metadata = directionsMetadata();

    final pieces = connectedCrosswordPieces(metadata: metadata);
    final southOnly = completeSouthOnlyInDirections(
      metadata: metadata,
      pieces: pieces,
    );

    final bothWords = completeNorthOnlyInDirections(
      metadata: metadata,
      pieces: southOnly.pieces,
    );

    final completedGroups =
        bothWords.pieces.where((piece) => piece.isCompletedWordGroup).toList();

    expect(completedGroups, hasLength(1));
    expect(
      completedGroups.first.completedAnswers,
      containsAll(['NORTH', 'SOUTH']),
    );
    expect(completedGroups.first.cells.length, greaterThanOrEqualTo(7));
  });

  test('NORTH inventory passes after SOUTH completes with crossword connected', () {
    final metadata = directionsMetadata();
    final northId = wordIdForText(metadata, 'NORTH')!;
    final southId = wordIdForText(metadata, 'SOUTH')!;

    final pieces = connectedCrosswordPieces(metadata: metadata);
    final southOnly = completeSouthOnlyInDirections(
      metadata: metadata,
      pieces: pieces,
    );

    final state = rebuildRuntimeBoardState(
      pieces: southOnly.pieces,
      metadata: metadata,
      solvedWordIds: {southId},
      reservedCellIds: southOnly.reservedCellIds,
      solvedAssignments: southOnly.solvedAssignments,
    );

    expect(
      canWordBeSatisfiedFromBoardInventory(
        wordId: northId,
        state: state,
        metadata: metadata,
      ),
      isTrue,
    );
  });

  test('shared H is not blocked for SOUTH after NORTH completes', () {
    final metadata = directionsMetadata();
    final northId = wordIdForText(metadata, 'NORTH')!;
    final southId = wordIdForText(metadata, 'SOUTH')!;
    final sharedH = sharedCellBetween(metadata, 'NORTH', 'SOUTH')!;

    final pieces = connectedCrosswordPieces(metadata: metadata);
    final northOnly = completeNorthOnlyInDirections(
      metadata: metadata,
      pieces: pieces,
    );

    final state = rebuildRuntimeBoardState(
      pieces: northOnly.pieces,
      metadata: metadata,
      solvedWordIds: {northId},
      reservedCellIds: northOnly.reservedCellIds,
      solvedAssignments: northOnly.solvedAssignments,
    );

    expect(
      isSharedIntersectionCell(
        cellId: sharedH,
        wordId: southId,
        state: state,
        metadata: metadata,
      ),
      isTrue,
    );
    expect(
      isCellBlockedByReservation(
        cellId: sharedH,
        wordId: southId,
        state: state,
        metadata: metadata,
      ),
      isFalse,
    );
  });

  test('remaining Directions words solvable after SOUTH completes first', () {
    final metadata = directionsMetadata();

    final pieces = connectedCrosswordPieces(metadata: metadata);
    final southOnly = completeSouthOnlyInDirections(
      metadata: metadata,
      pieces: pieces,
    );

    final result = handlePuzzleStateAfterReconnect(
      pieces: southOnly.pieces,
      metadata: metadata,
      movedChunkIds: metadata.chunkById.keys,
      solvedWordIds: southOnly.solvedWordIds,
      reservedCellIds: southOnly.reservedCellIds,
      solvedAssignments: southOnly.solvedAssignments,
    );

    expect(result.completedAnswers, containsAll(['NORTH', 'EAST', 'WEST']));
    expect(result.puzzleComplete, isTrue);
  });

  test('WEST completes after EAST using S/T from completed group', () {
    final metadata = directionsMetadata();
    final eastId = wordIdForText(metadata, 'EAST')!;
    final westId = wordIdForText(metadata, 'WEST')!;

    final eastLayout = directionsPiecesForEastFirstWestTest(metadata);
    final eastResult = handlePuzzleStateAfterReconnect(
      pieces: eastLayout,
      metadata: metadata,
      movedChunkIds: eastFirstWestMovedChunkIds(metadata),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(eastResult.completedAnswers, contains('EAST'));
    expect(eastResult.solvedWordIds, contains(eastId));

    final westLayout = directionsPiecesWithWestWeAboveCompletedEast(
      eastResult.pieces,
      metadata,
    );
    final westWChunk = chunkRefForFinalCell(
      metadata,
      metadata.wordById[westId]!.cellIds[0],
    ).chunkId;

    final westResult = handlePuzzleStateAfterReconnect(
      pieces: westLayout,
      metadata: metadata,
      movedChunkIds: {westWChunk},
      solvedWordIds: eastResult.solvedWordIds,
      reservedCellIds: eastResult.reservedCellIds,
      solvedAssignments: eastResult.solvedAssignments,
    );

    expect(westResult.completedAnswers, containsAll(['EAST', 'WEST']));
    expect(westResult.solvedWordIds, containsAll([eastId, westId]));
  });

  test('EAST completes after WEST still works', () {
    final metadata = directionsMetadata();
    final eastId = wordIdForText(metadata, 'EAST')!;
    final westId = wordIdForText(metadata, 'WEST')!;

    final westLayout = directionsPiecesForWestFirstEastTest(metadata);
    final westMovedChunks = chunkIdsForFinalCells(
      metadata,
      metadata.wordById[westId]!.cellIds,
    );

    final westResult = handlePuzzleStateAfterReconnect(
      pieces: westLayout,
      metadata: metadata,
      movedChunkIds: westMovedChunks,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(westResult.completedAnswers, contains('WEST'));
    expect(westResult.solvedWordIds, contains(westId));

    final eastMovedChunks = chunkIdsForFinalCells(
      metadata,
      metadata.wordById[eastId]!.cellIds.take(2),
    );

    final eastResult = handlePuzzleStateAfterReconnect(
      pieces: westResult.pieces,
      metadata: metadata,
      movedChunkIds: eastMovedChunks,
      solvedWordIds: westResult.solvedWordIds,
      reservedCellIds: westResult.reservedCellIds,
      solvedAssignments: westResult.solvedAssignments,
    );

    expect(eastResult.completedAnswers, containsAll(['EAST', 'WEST']));
    expect(eastResult.solvedWordIds, containsAll([eastId, westId]));
  });

  test('SOUTH completes between locked words with O-U placed', () {
    final metadata = directionsMetadata();
    final eastId = wordIdForText(metadata, 'EAST')!;
    final northId = wordIdForText(metadata, 'NORTH')!;
    final westId = wordIdForText(metadata, 'WEST')!;
    final southId = wordIdForText(metadata, 'SOUTH')!;

    final eastOnly = completeEastOnlyInDirections(
      metadata: metadata,
      pieces: directionsPiecesForEastFirstWestTest(metadata),
    );

    expect(eastOnly.completedAnswers, contains('EAST'));

    final lockedWordIds = {
      ...eastOnly.solvedWordIds,
      northId,
      westId,
    };
    final lockedReservedCellIds = {
      ...eastOnly.reservedCellIds,
      ...metadata.wordById[northId]!.cellIds,
      ...metadata.wordById[westId]!.cellIds,
    };
    final lockedAssignments = {
      ...eastOnly.solvedAssignments,
      northId: SolvedAssignment(
        wordId: northId,
        assignedCellIds: metadata.wordById[northId]!.cellIds.toSet(),
        moveComponentId: 'cmp_test_north',
      ),
      westId: SolvedAssignment(
        wordId: westId,
        assignedCellIds: metadata.wordById[westId]!.cellIds.toSet(),
        moveComponentId: 'cmp_test_west',
      ),
    };

    final southLayout = directionsPiecesForSouthAfterEast(
      eastOnly.pieces,
      metadata,
    );

    final southResult = handlePuzzleStateAfterReconnect(
      pieces: southLayout,
      metadata: metadata,
      movedChunkIds: metadata.chunkById.keys,
      solvedWordIds: lockedWordIds,
      reservedCellIds: lockedReservedCellIds,
      solvedAssignments: lockedAssignments,
    );

    expect(southResult.completedAnswers, containsAll(['EAST', 'SOUTH']));
    expect(southResult.solvedWordIds, containsAll([eastId, southId]));
  });
}
