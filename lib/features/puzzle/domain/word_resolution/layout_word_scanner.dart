import 'puzzle_layout_metadata.dart';
import 'puzzle_runtime_state.dart';
import 'puzzle_solvability_solver.dart';
import 'word_assignment.dart';
import 'word_resolution_models.dart';

List<WordAssignmentOption> scanCompletedLayoutWords({
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final completed = <WordAssignmentOption>[];

  for (final wordId in metadata.targetWordIds) {
    if (state.solvedWordIds.contains(wordId)) {
      continue;
    }

    final assignments = getPossibleAssignmentsForWord_Strict(
      wordId: wordId,
      state: state,
      metadata: metadata,
    );

    if (assignments.isEmpty) {
      continue;
    }

    completed.add(
      _withGroupedBoardCells(
        assignment: assignments.first,
        state: state,
        metadata: metadata,
      ),
    );
  }

  return completed;
}

List<WordAssignmentOption> resolveAcceptedLayoutWords({
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final strictAssignments = scanCompletedLayoutWords(
    state: state,
    metadata: metadata,
  );

  if (strictAssignments.isEmpty) {
    return const [];
  }

  strictAssignments.sort((a, b) {
    final lenA = metadata.wordById[a.wordId]?.text.length ?? 0;
    final lenB = metadata.wordById[b.wordId]?.text.length ?? 0;
    return lenB.compareTo(lenA);
  });

  final accepted = <WordAssignmentOption>[];
  var workingState = state.clone();

  for (final assignment in strictAssignments) {
    if (workingState.solvedWordIds.contains(assignment.wordId)) {
      continue;
    }

    accepted.add(assignment);
    workingState = applyWordAssignmentToSolverState(
      state: workingState,
      assignment: assignment,
      metadata: metadata,
    );
  }

  return accepted;
}

WordAssignmentOption _withGroupedBoardCells({
  required WordAssignmentOption assignment,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final word = metadata.wordById[assignment.wordId];
  if (word == null) {
    return assignment;
  }

  final orderedBoardCells = <OrderedBoardCell>[];
  for (final cellId in word.cellIds) {
    final layoutCell = metadata.finalCellById[cellId];
    final placed = resolveCellForWord(
      cellId: cellId,
      wordId: assignment.wordId,
      state: state,
      metadata: metadata,
    );
    if (layoutCell == null || placed == null) {
      return assignment;
    }

    orderedBoardCells.add(
      OrderedBoardCell(
        finalCellId: cellId,
        boardRow: layoutCell.row,
        boardCol: layoutCell.col,
        chunkId: placed.chunkId,
        componentId: placed.componentId,
        letter: placed.letter,
      ),
    );
  }

  if (orderedBoardCells.length != word.cellIds.length) {
    return assignment;
  }

  return WordAssignmentOption(
    wordId: assignment.wordId,
    reservedFinalCellIds: assignment.reservedFinalCellIds,
    contributingFinalCellIds: assignment.contributingFinalCellIds,
    contributingChunkIds: assignment.contributingChunkIds,
    contributingComponentIds: assignment.contributingComponentIds,
    assignmentType: assignment.assignmentType,
    debugReason: assignment.debugReason,
    groupedBoardCells: orderedBoardCells,
  );
}
