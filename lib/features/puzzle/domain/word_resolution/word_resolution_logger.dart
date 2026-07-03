import 'package:flutter/foundation.dart';

import '../../../../core/constants/debug_flags.dart';
import '../board_cell_position.dart';
import 'puzzle_runtime_state.dart';
import 'word_resolution_models.dart';

void _log(String message) {
  debugPrint('[impossible_logic] $message');
}

void logFlowStart({
  required String mode,
  required List<String> movedChunks,
  required Set<String> solvedWords,
  required Set<String> reserved,
}) {
  _log(
    '[FLOW_START] mode=$mode movedChunks=$movedChunks '
    'solvedWords=$solvedWords reserved=$reserved',
  );
}

void logBoardStateRebuild(PuzzleRuntimeState state) {
  for (final cell in state.placedCellsByFinalId.values) {
    _log(
      '[BOARD_STATE] placedCell finalCellId=${cell.finalCellId} '
      'letter=${cell.letter} row=${cell.boardRow} col=${cell.boardCol} '
      'chunk=${cell.chunkId} component=${cell.componentId}',
    );
  }
}

void logComponent(RuntimeComponent component) {
  _log(
    '[COMPONENT] component=${component.componentId} '
    'cells=${component.finalCellIds} chunks=${component.chunkIds}',
  );
}

void logCandidate(CandidateWordInstance candidate) {
  _log(
    '[CANDIDATE] text=${candidate.text} orientation=${candidate.orientation} '
    'cells=${candidate.finalCellIds} '
    'coords=${candidate.orderedBoardCells.map((cell) => '(${cell.boardRow},${cell.boardCol})').join(',')} '
    'components=${candidate.componentIds}',
  );
}

void logCandidateScanTotal(int count) {
  _log('[CANDIDATE] total=$count');
}

void logTargetMatch(String candidateText, List<String> matchedWordIds) {
  _log(
    '[TARGET_MATCH] candidateText=$candidateText matchedWordIds=$matchedWordIds',
  );
}

void logStrictAssignmentOk(String wordId, List<String> reserved) {
  _log('[STRICT_ASSIGNMENT_OK] wordId=$wordId reserved=$reserved');
}

void logStrictAssignmentFail(String wordId, String reason) {
  _log('[STRICT_ASSIGNMENT_FAIL] wordId=$wordId reason=$reason');
}

void logFlexAssignmentCandidate(String wordId, List<String> cells) {
  _log('[FLEX_ASSIGNMENT_CANDIDATE] wordId=$wordId cells=$cells');
}

void logFlexAssignmentReject(String wordId, String reason) {
  _log('[FLEX_ASSIGNMENT_REJECT] wordId=$wordId reason=$reason');
}

void logInventoryOk(String wordId, List<String> cellIds) {
  _log('[INVENTORY_OK] wordId=$wordId cells=$cellIds');
}

void logInventoryFail(String wordId, String reason) {
  _log('[INVENTORY_FAIL] wordId=$wordId reason=$reason');
}

void logSolverInventoryTry(int depth, String wordId, List<String> cellIds) {
  _log('[SOLVER_INVENTORY_TRY] depth=$depth wordId=$wordId cells=$cellIds');
}

void logSolverEnter(int depth, Set<String> solved, List<String> remaining) {
  _log(
    '[SOLVER_ENTER] depth=$depth solved=$solved remaining=$remaining',
  );
}

void logSolverNextWord(int depth, String wordId, int assignmentCount) {
  _log(
    '[SOLVER_NEXT_WORD] depth=$depth wordId=$wordId assignmentCount=$assignmentCount',
  );
}

void logSolverTry(int depth, String wordId, AssignmentType type, List<String> reserved) {
  _log(
    '[SOLVER_TRY] depth=$depth wordId=$wordId assignmentType=${type.name} '
    'reserved=$reserved',
  );
}

void logSolverBacktrack(int depth, String wordId, String reason) {
  _log('[SOLVER_BACKTRACK] depth=$depth wordId=$wordId reason=$reason');
}

void logSolverSuccess(int depth) {
  _log('[SOLVER_SUCCESS] depth=$depth all_words_solved=true');
}

void logSolverDeadEnd(int depth, String wordId, String reason) {
  _log('[SOLVER_DEAD_END] depth=$depth wordId=$wordId reason=$reason');
}

void logCandidateAccepted({
  required String candidateText,
  required String wordId,
  required AssignmentType assignmentType,
  required String moveComponent,
}) {
  _log(
    '[CANDIDATE_ACCEPTED] candidateText=$candidateText wordId=$wordId '
    'assignmentType=${assignmentType.name} moveComponent=$moveComponent',
  );
}

void logCandidateRejected({
  required String candidateText,
  required String wordId,
  required String reason,
}) {
  _log(
    '[CANDIDATE_REJECTED] candidateText=$candidateText wordId=$wordId reason=$reason',
  );
}

void logMoveStep({
  required int step,
  required Iterable<String> movedChunkIds,
  required int boardLetterCount,
}) {
  if (!kLogWordResolutionSteps) {
    return;
  }
  _log(
    '[MOVE_STEP] step=$step movedChunks=$movedChunkIds '
    'boardLetters=$boardLetterCount',
  );
}

void logExactLineRejected({
  required String candidateText,
  required String reason,
}) {
  _log('[EXACT_LINE_REJECT] candidateText=$candidateText reason=$reason');
}

void logSolvabilityReject({
  required String wordId,
  required String candidateText,
}) {
  _log(
    '[SOLVABILITY_REJECT] wordId=$wordId candidateText=$candidateText',
  );
}

void logBlockedWord(String wordId) {
  _log('[BLOCKED_WORD] wordId=$wordId');
}

void logGrouping({
  required List<String> wordIds,
  required int reservedCellCount,
}) {
  _log(
    '[GROUPING] words=$wordIds reservedCellCount=$reservedCellCount',
  );
}

void logMoveCluster(MoveCluster cluster) {
  _log(
    '[MOVE_CLUSTER] component=${cluster.moveComponentId} '
    'words=${cluster.assignmentWordIds} chunks=${cluster.contributingChunkIds}',
  );
}

void logSolveState(Set<String> solvedWords, Set<String> reserved) {
  _log('[SOLVE_STATE] solvedWords=$solvedWords reserved=$reserved');
}

void logPuzzleComplete(int solvedCount, int totalWords) {
  _log('[PUZZLE_COMPLETE] solvedCount=$solvedCount totalWords=$totalWords');
}

String formatWordAssignmentForLog(WordAssignmentOption assignment) {
  return 'wordId=${assignment.wordId} type=${assignment.assignmentType.name} '
      'reserved=${assignment.reservedFinalCellIds}';
}

String formatCandidateWordForLog(CandidateWordInstance candidate) {
  return '${candidate.orientation}:${candidate.text}:${candidate.finalCellIds.join(',')}';
}

String formatComponentForLog(RuntimeComponent component) {
  return '${component.componentId}:${component.finalCellIds.join(',')}';
}

String formatBoardCellForLog(BoardCellPosition position, BoardCellEntry entry) {
  return '(${position.row},${position.col}) ${entry.finalCellId} ${entry.letter}';
}
