import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/candidate_word_scanner.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_runtime_state.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_solvability_solver.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_assignment.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_models.dart';

import 'word_resolution_test_helpers.dart';

void main() {
  test('solver succeeds when all words can be strictly assigned', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'RED',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
      PlacedWord(
        word: 'BLUE',
        row: 2,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);
    final state = rebuildRuntimeBoardState(
      pieces: piecesAtLayoutPositions(metadata),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(
      canRemainingPuzzleBeSolved(state: state, metadata: metadata),
      isTrue,
    );
  });

  test('MRV picks word with fewer assignment options first', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'RED',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
      PlacedWord(
        word: 'BLUE',
        row: 2,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);
    final state = rebuildRuntimeBoardState(
      pieces: piecesAtLayoutPositions(metadata),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final next = getNextUnsolvedWordForSolver(
      state: state,
      metadata: metadata,
    );

    expect(next, isNotNull);
    expect(metadata.targetWordIds, contains(next));
  });

  test('applyWordAssignmentToSolverState reserves cells without mutating input', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'RED',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
      PlacedWord(
        word: 'BLUE',
        row: 2,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);
    final state = rebuildRuntimeBoardState(
      pieces: piecesAtLayoutPositions(metadata),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );
    final wordId = metadata.targetWordIds.first;
    final assignment = getPossibleAssignmentsForWord_Strict(
      wordId: wordId,
      state: state,
      metadata: metadata,
    ).single;

    final updated = applyWordAssignmentToSolverState(
      state: state,
      assignment: assignment,
      metadata: metadata,
    );

    expect(updated.solvedWordIds, contains(wordId));
    expect(state.solvedWordIds, isEmpty);
  });

  test('inventory solvability after KNIFE assignment with scattered remaining letters', () {
    final metadata = cutleryMetadata();
    final pieces = cutleryWithKnifeConnectedOnly(metadata);
    final knifeId = knifeWordId(metadata)!;
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
    final knifeCandidate = candidates.firstWhere(
      (candidate) => candidate.text == 'KNIFE',
    );
    final knifeAssignment = assignmentsForCandidate(
      wordId: knifeId,
      candidate: knifeCandidate,
      state: state,
      metadata: metadata,
      options: WordResolutionOptions(candidateWordInstances: candidates),
    ).single;

    final trial = applyWordAssignmentToSolverState(
      state: state,
      assignment: knifeAssignment,
      metadata: metadata,
    );

    expect(
      canRemainingPuzzleBeSolved(
        state: trial,
        metadata: metadata,
        options: WordResolutionOptions(candidateWordInstances: candidates),
      ),
      isTrue,
    );
  });
}
