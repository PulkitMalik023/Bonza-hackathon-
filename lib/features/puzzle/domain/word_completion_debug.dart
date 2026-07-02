import 'package:flutter/foundation.dart';

import '../../../core/constants/debug_flags.dart';
import 'board_cell_position.dart';
import 'board_line_word_detector.dart';
import 'chunk_drop_evaluator.dart';
import 'completed_cluster_builder.dart';
import 'puzzle_piece.dart';

const _logTag = '[PuzzleCompletion]';

void logCompletionSkipped(String reason) {
  if (!kLogPuzzleCompletion) {
    return;
  }
  debugPrint('$_logTag skipped: $reason');
}

void logPiecePlacementResult({
  required PuzzlePiece piece,
  required ChunkDropResult result,
}) {
  if (!kLogPuzzleCompletion) {
    return;
  }

  final snapped = result.action == ChunkDropAction.snap;
  debugPrint(
    '$_logTag pieceDrop piece=${piece.id} '
    'action=${snapped ? "snap" : "returnToOrigin"} '
    'anchor=${result.targetAnchor} '
    'insideBoard=${result.insideBoard} '
    'occupied=${result.occupied} '
    'overlapsBoard=${result.overlapsBoard}',
  );
}

void logMatrixCompletionScan({
  required Set<String> targetAnswers,
  required Set<String> completedAnswers,
  required Set<BoardCellPosition> scanScopeCells,
  required Map<BoardCellPosition, String> playAreaBoard,
  required List<MatchedBoardLine> matchedLines,
  String source = 'boardChange',
}) {
  if (!kLogPuzzleCompletion) {
    return;
  }

  debugPrint(
    '$_logTag matrixScan source=$source '
    'targets=${targetAnswers.length} '
    'completed=${completedAnswers.length} '
    'scanScopeCells=${scanScopeCells.length} '
    'playAreaCells=${playAreaBoard.length}',
  );

  final candidates = collectCandidateLines(
    board: playAreaBoard,
    affectedCells: scanScopeCells,
  );

  for (final line in candidates.values) {
    final isMatch = targetAnswers.contains(line.text);
    final alreadyDone = completedAnswers.contains(line.text);
    debugPrint(
      '$_logTag candidate ${line.dedupeKey} '
      'orient=${line.orientation.name} formed=${line.text} '
      'match=$isMatch alreadyCompleted=$alreadyDone',
    );
  }

  for (final match in matchedLines) {
    debugPrint(
      '$_logTag matched answer=${match.answer} '
      'line=${match.line.dedupeKey} formed=${match.line.text}',
    );
  }
}

void logClusterGrouped({
  required String clusterId,
  required Set<String> answers,
  required String groupId,
  required int cellCount,
  required int piecesBefore,
  required int piecesAfter,
  List<String> strippedPieceIds = const [],
  List<String> mergedGroupIds = const [],
}) {
  if (!kLogPuzzleCompletion) {
    return;
  }

  debugPrint(
    '$_logTag grouped clusterId=$clusterId answers=${answers.join(",")} '
    'groupId=$groupId cells=$cellCount '
    'piecesBefore=$piecesBefore piecesAfter=$piecesAfter '
    'stripped=${strippedPieceIds.join(",")} '
    'merged=${mergedGroupIds.join(",")}',
  );
}

void logPuzzleAnswersCompletion({
  required List<String> targetWords,
  required Set<String> completedAnswers,
  required bool isComplete,
}) {
  if (!kLogPuzzleCompletion) {
    return;
  }

  debugPrint(
    '$_logTag puzzleAnswersComplete=$isComplete '
    'completed=${completedAnswers.length}/${targetWords.length} '
    'remaining=${targetWords.map((w) => w.toUpperCase()).where((w) => !completedAnswers.contains(w)).join(",")}',
  );
}

@Deprecated('Use logClusterGrouped')
void logWordGrouped({
  required String wordKey,
  required String groupId,
  required int cellCount,
  required int piecesBefore,
  required int piecesAfter,
  List<String> strippedPieceIds = const [],
  List<String> mergedGroupIds = const [],
}) {
  logClusterGrouped(
    clusterId: wordKey,
    answers: {wordKey},
    groupId: groupId,
    cellCount: cellCount,
    piecesBefore: piecesBefore,
    piecesAfter: piecesAfter,
    strippedPieceIds: strippedPieceIds,
    mergedGroupIds: mergedGroupIds,
  );
}
