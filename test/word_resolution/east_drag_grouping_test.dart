import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

import 'word_resolution_test_helpers.dart';

void main() {
  test('EAST via WEST ST chunk groups all four letters in completed cluster', () {
    final metadata = directionsMetadata();
    final eastId = wordIdForText(metadata, 'EAST')!;

    final eastResult = handlePuzzleStateAfterReconnect(
      pieces: directionsPiecesForEastFirstWestTest(metadata),
      metadata: metadata,
      movedChunkIds: eastFirstWestMovedChunkIds(metadata),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(eastResult.completedAnswers, contains('EAST'));
    expect(eastResult.solvedWordIds, contains(eastId));

    final completedGroups =
        eastResult.pieces.where((piece) => piece.isCompletedWordGroup).toList();

    expect(completedGroups, hasLength(1));
    expect(completedGroups.first.completedAnswers, contains('EAST'));
    expect(completedGroups.first.cells.length, equals(4));
    expect(
      completedGroups.first.cells.map((cell) => cell.letter).join(),
      'EAST',
    );
  });

  test('EAST completed group moves as one piece with T included', () {
    final metadata = directionsMetadata();

    final eastResult = handlePuzzleStateAfterReconnect(
      pieces: directionsPiecesForEastFirstWestTest(metadata),
      metadata: metadata,
      movedChunkIds: eastFirstWestMovedChunkIds(metadata),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final completedGroup = eastResult.pieces
        .firstWhere((piece) => piece.isCompletedWordGroup);

    expect(
      completedGroup.cells.any((cell) => cell.letter == 'T'),
      isTrue,
      reason: 'T from WEST ST must be absorbed into EAST completed group',
    );

    final lettersOnBoard = <String>{};
    for (final piece in eastResult.pieces) {
      if (piece.isCompletedWordGroup) {
        continue;
      }
      for (final cell in piece.cells) {
        lettersOnBoard.add(cell.letter);
      }
    }

    expect(
      lettersOnBoard.where((letter) => letter == 'T').length,
      lessThan(2),
      reason: 'T should not remain as a separate active tile after EAST completes',
    );
  });

  test('WEST still solvable after EAST groups WEST ST letters', () {
    final metadata = directionsMetadata();
    final eastId = wordIdForText(metadata, 'EAST')!;
    final westId = wordIdForText(metadata, 'WEST')!;

    final eastResult = handlePuzzleStateAfterReconnect(
      pieces: directionsPiecesForEastFirstWestTest(metadata),
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
}
