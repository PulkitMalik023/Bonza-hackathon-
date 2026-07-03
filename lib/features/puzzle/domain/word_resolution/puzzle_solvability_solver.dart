import '../board_cell_position.dart';
import 'puzzle_layout_metadata.dart';
import 'puzzle_runtime_state.dart';
import 'word_assignment.dart';
import 'word_resolution_logger.dart';
import 'word_resolution_models.dart';

bool _shouldKeepCellForUnsolvedIntersection({
  required String cellId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  return isCellNeededByUnsolvedWord(
    cellId: cellId,
    solvedWordIds: state.solvedWordIds,
    metadata: metadata,
  );
}

PuzzleRuntimeState applyWordAssignmentToSolverState({
  required PuzzleRuntimeState state,
  required WordAssignmentOption assignment,
  required PuzzleLayoutMetadata metadata,
}) {
  final placedCells = Map<String, PlacedRuntimeCell>.from(state.placedCellsByFinalId)
    ..removeWhere(
      (cellId, _) =>
          assignment.reservedFinalCellIds.contains(cellId) &&
          !_shouldKeepCellForUnsolvedIntersection(
            cellId: cellId,
            state: state,
            metadata: metadata,
          ),
    );

  final boardCellMap = Map<BoardCellPosition, BoardCellEntry>.from(
    state.boardCellMap,
  )..removeWhere(
      (_, entry) =>
          assignment.reservedFinalCellIds.contains(entry.finalCellId) &&
          !_shouldKeepCellForUnsolvedIntersection(
            cellId: entry.finalCellId,
            state: state,
            metadata: metadata,
          ),
    );

  final moveComponentId = assignment.contributingComponentIds.isNotEmpty
      ? assignment.contributingComponentIds.first
      : null;

  return PuzzleRuntimeState(
    placedCellsByFinalId: placedCells,
    boardCellMap: boardCellMap,
    componentsById: state.componentsById,
    solvedWordIds: {...state.solvedWordIds, assignment.wordId},
    reservedCellIds: {
      ...state.reservedCellIds,
      ...assignment.reservedFinalCellIds,
    },
    solvedAssignments: {
      ...state.solvedAssignments,
      assignment.wordId: SolvedAssignment(
        wordId: assignment.wordId,
        assignedCellIds: assignment.reservedFinalCellIds.toSet(),
        moveComponentId: moveComponentId,
      ),
    },
  );
}

bool canRemainingPuzzleBeSolved({
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
  WordResolutionOptions options = const WordResolutionOptions(),
}) {
  return solveRemainingWordsRecursive(
    state: state,
    metadata: metadata,
    options: options,
    depth: 0,
  );
}

String? getNextUnsolvedWordForSolver({
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
  WordResolutionOptions options = const WordResolutionOptions(),
}) {
  String? bestWordId;
  var bestCount = 1 << 30;

  for (final wordId in metadata.targetWordIds) {
    if (state.solvedWordIds.contains(wordId)) {
      continue;
    }

    final count = _assignmentCountForSolver(
      wordId: wordId,
      state: state,
      metadata: metadata,
      options: options,
    );

    if (count < bestCount) {
      bestCount = count;
      bestWordId = wordId;
    }
  }

  return bestWordId;
}

int _assignmentCountForSolver({
  required String wordId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
  required WordResolutionOptions options,
}) {
  final assignments = getPossibleAssignmentsForWord(
    wordId: wordId,
    state: state,
    metadata: metadata,
    options: options,
  );

  if (assignments.isNotEmpty) {
    return assignments.length;
  }

  if (canWordBeSatisfiedFromBoardInventory(
    wordId: wordId,
    state: state,
    metadata: metadata,
  )) {
    return 1;
  }

  return 0;
}

bool solveRemainingWordsRecursive({
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
  required WordResolutionOptions options,
  required int depth,
}) {
  final remaining = metadata.targetWordIds
      .where((wordId) => !state.solvedWordIds.contains(wordId))
      .toList();

  if (remaining.isEmpty) {
    logSolverSuccess(depth);
    return true;
  }

  if (depth > metadata.targetWordIds.length) {
    return false;
  }

  logSolverEnter(depth, state.solvedWordIds, remaining);

  final nextWordId = getNextUnsolvedWordForSolver(
    state: state,
    metadata: metadata,
    options: options,
  );

  if (nextWordId == null) {
    logSolverSuccess(depth);
    return true;
  }

  final assignments = getPossibleAssignmentsForWord(
    wordId: nextWordId,
    state: state,
    metadata: metadata,
    options: options,
  );

  logSolverNextWord(depth, nextWordId, assignments.length);

  if (assignments.isEmpty) {
    final inventoryAssignment = buildInventoryAssignmentForWord(
      wordId: nextWordId,
      state: state,
      metadata: metadata,
    );

    if (inventoryAssignment != null) {
      logSolverInventoryTry(
        depth,
        nextWordId,
        inventoryAssignment.reservedFinalCellIds,
      );
      logSolverTry(
        depth,
        nextWordId,
        inventoryAssignment.assignmentType,
        inventoryAssignment.reservedFinalCellIds,
      );

      final nextState = applyWordAssignmentToSolverState(
        state: state,
        assignment: inventoryAssignment,
        metadata: metadata,
      );

      if (solveRemainingWordsRecursive(
        state: nextState,
        metadata: metadata,
        options: options,
        depth: depth + 1,
      )) {
        return true;
      }

      logSolverBacktrack(depth, nextWordId, 'inventory_downstream_failure');
    }

    logSolverDeadEnd(depth, nextWordId, 'no_possible_assignments');
    return false;
  }

  for (final assignment in assignments) {
    logSolverTry(
      depth,
      nextWordId,
      assignment.assignmentType,
      assignment.reservedFinalCellIds,
    );

    final nextState = applyWordAssignmentToSolverState(
      state: state,
      assignment: assignment,
      metadata: metadata,
    );

    if (solveRemainingWordsRecursive(
      state: nextState,
      metadata: metadata,
      options: options,
      depth: depth + 1,
    )) {
      return true;
    }

    logSolverBacktrack(depth, nextWordId, 'downstream_failure');
  }

  logSolverDeadEnd(depth, nextWordId, 'all_assignments_failed');
  return false;
}
