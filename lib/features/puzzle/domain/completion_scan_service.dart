import 'board_cell_position.dart';
import 'board_line_word_detector.dart';
import 'completed_cluster_builder.dart';
import 'completed_word_grouper.dart';
import 'puzzle_board_state.dart';
import 'puzzle_piece.dart';
import 'puzzle_solved_checker.dart';
import 'word_completion_debug.dart';

enum CompletionScanSource { initialization, boardChange }

class CompletionScanResult {
  const CompletionScanResult({
    required this.pieces,
    required this.completedAnswers,
    required this.newlyCompletedAnswers,
    required this.allAnswersCompleted,
  });

  final List<PuzzlePiece> pieces;
  final Set<String> completedAnswers;
  final Set<String> newlyCompletedAnswers;
  final bool allAnswersCompleted;

  bool get hasChanges => newlyCompletedAnswers.isNotEmpty;
}

CompletionScanResult runCompletionScan({
  required List<PuzzlePiece> pieces,
  required Set<BoardCellPosition> scanScopeCells,
  required List<String> targetWords,
  required Set<String> completedAnswers,
  CompletionScanSource source = CompletionScanSource.boardChange,
  int? puzzleId,
  String? puzzleCategory,
  int? boardRows,
  int? boardCols,
}) {
  final targetAnswerSet = normalizeTargetAnswers(targetWords);
  final playAreaBoard = buildPlayAreaLetterMap(pieces);

  final scopedCells = scanScopeCells
      .where((cell) => playAreaBoard.containsKey(cell))
      .toSet();

  if (scopedCells.isEmpty) {
    return CompletionScanResult(
      pieces: pieces,
      completedAnswers: completedAnswers,
      newlyCompletedAnswers: const {},
      allAnswersCompleted: areAllTargetAnswersCompleted(
        targetWords,
        completedAnswers,
      ),
    );
  }

  final matchedLines = findNewlyCompletedLines(
    board: playAreaBoard,
    affectedCells: scopedCells,
    targetAnswers: targetAnswerSet,
    completedAnswers: completedAnswers,
  );

  logMatrixCompletionScan(
    targetWordsFromPuzzle: targetWords,
    targetAnswers: targetAnswerSet,
    completedAnswers: completedAnswers,
    scanScopeCells: scopedCells,
    playAreaBoard: playAreaBoard,
    matchedLines: matchedLines,
    pieces: pieces,
    source: source.name,
    puzzleId: puzzleId,
    puzzleCategory: puzzleCategory,
    boardRows: boardRows,
    boardCols: boardCols,
  );

  if (matchedLines.isEmpty) {
    return CompletionScanResult(
      pieces: pieces,
      completedAnswers: completedAnswers,
      newlyCompletedAnswers: const {},
      allAnswersCompleted: areAllTargetAnswersCompleted(
        targetWords,
        completedAnswers,
      ),
    );
  }

  final clusters = buildCompletedClusters(
    matchedLines,
    pieces: pieces,
    playAreaBoard: playAreaBoard,
  );
  var updatedPieces = pieces;
  final updatedAnswers = {...completedAnswers};
  final newlyCompleted = <String>{};

  for (final cluster in clusters) {
    updatedPieces = applyCompletedClusterGrouping(
      pieces: updatedPieces,
      cluster: cluster,
    );
    updatedAnswers.addAll(cluster.answers);
    newlyCompleted.addAll(cluster.answers);
  }

  final allAnswersCompleted = areAllTargetAnswersCompleted(
    targetWords,
    updatedAnswers,
  );

  logPuzzleAnswersCompletion(
    targetWords: targetWords,
    completedAnswers: updatedAnswers,
    isComplete: allAnswersCompleted,
  );

  return CompletionScanResult(
    pieces: updatedPieces,
    completedAnswers: updatedAnswers,
    newlyCompletedAnswers: newlyCompleted,
    allAnswersCompleted: allAnswersCompleted,
  );
}
