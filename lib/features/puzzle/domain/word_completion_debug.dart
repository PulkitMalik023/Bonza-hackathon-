import 'package:flutter/foundation.dart';

import '../../../core/constants/debug_flags.dart';
import 'board_cell_position.dart';
import 'board_line_word_detector.dart';
import 'chunk_drop_evaluator.dart';
import 'puzzle_board_state.dart';
import 'puzzle_piece.dart';

const _pulkitTag = '[Pulkit]';

void logCompletionSkipped(String reason) {
  if (!kLogPulkitWordCheck) {
    return;
  }
  debugPrint('$_pulkitTag SKIPPED $reason');
}

void logPiecePlacementResult({
  required PuzzlePiece piece,
  required ChunkDropResult result,
}) {
  if (!kLogPulkitWordCheck) {
    return;
  }

  final snapped = result.action == ChunkDropAction.snap;
  if (!snapped) {
    debugPrint(
      '$_pulkitTag TILE_RELEASE piece=${piece.id} returnedToSpawn '
      '(no word scan — piece not on play area)',
    );
    return;
  }

  final anchor = result.targetAnchor;
  final anchorText = anchor == null
      ? 'unknown'
      : 'row=${anchor.row} col=${anchor.col}';

  debugPrint(
    '$_pulkitTag TILE_RELEASE piece=${piece.id} snapped=true anchor=$anchorText '
    'cells=${_formatPieceCells(piece)}',
  );
}

void logMatrixCompletionScan({
  required List<String> targetWordsFromPuzzle,
  required Set<String> targetAnswers,
  required Set<String> completedAnswers,
  required Set<BoardCellPosition> scanScopeCells,
  required Map<BoardCellPosition, String> playAreaBoard,
  required List<MatchedBoardLine> matchedLines,
  required List<PuzzlePiece> pieces,
  String source = 'boardChange',
  int? puzzleId,
  String? puzzleCategory,
  int? boardRows,
  int? boardCols,
}) {
  if (!kLogPulkitWordCheck) {
    return;
  }

  final candidates = collectCandidateLines(
    board: playAreaBoard,
    affectedCells: scanScopeCells,
  );

  final horizontal = candidates.values
      .where((line) => line.orientation == LineOrientation.horizontal)
      .toList()
    ..sort((a, b) => a.dedupeKey.compareTo(b.dedupeKey));

  final vertical = candidates.values
      .where((line) => line.orientation == LineOrientation.vertical)
      .toList()
    ..sort((a, b) => a.dedupeKey.compareTo(b.dedupeKey));

  final sortedTargets = targetWordsFromPuzzle.map((w) => w.toUpperCase()).toList()
    ..sort();

  debugPrint('$_pulkitTag --- word check after tile release ---');
  debugPrint(
    '$_pulkitTag TARGETS source=PuzzleContent.words '
    '${puzzleId != null ? "puzzleId=$puzzleId " : ""}'
    '${puzzleCategory != null ? "category=$puzzleCategory " : ""}'
    'words=${sortedTargets.join(",")}',
  );
  debugPrint(
    '$_pulkitTag TARGETS note=formed word must exactly equal one target (full segment, not partial)',
  );
  debugPrint(
    '$_pulkitTag TARGETS alreadyCompleted=${completedAnswers.isEmpty ? "none" : completedAnswers.join(",")}',
  );

  if (playAreaBoard.isEmpty) {
    debugPrint('$_pulkitTag BOARD empty (no letters on grid yet)');
  } else {
    debugPrint(
      '$_pulkitTag BOARD letters=${_formatBoard(playAreaBoard)} '
      '(full grid map rebuilt from all piece positions)',
    );
  }

  _logBoardFull(playAreaBoard);
  _logBoardByPiece(pieces);
  _logBoardGrid(
    label: 'BOARD_GRID',
    playAreaBoard: playAreaBoard,
    boardRows: boardRows,
    boardCols: boardCols,
    emptyLabel: 'all letters on canvas used for word check',
  );

  _logFormedWordList(
    label: 'FORMED_HORIZONTAL',
    lines: horizontal,
    playAreaBoard: playAreaBoard,
  );
  _logFormedWordList(
    label: 'FORMED_VERTICAL',
    lines: vertical,
    playAreaBoard: playAreaBoard,
  );

  if (horizontal.isEmpty && vertical.isEmpty) {
    debugPrint('$_pulkitTag COMPARE no horizontal/vertical words to check');
  } else {
    debugPrint('$_pulkitTag COMPARE checking each formed word vs targets:');
    for (final line in [...horizontal, ...vertical]) {
      _logFormedWordComparison(
        line: line,
        targetAnswers: targetAnswers,
        completedAnswers: completedAnswers,
      );
    }
  }

  if (matchedLines.isEmpty) {
    debugPrint('$_pulkitTag NEW_MATCH none');
  } else {
    for (final match in matchedLines) {
      debugPrint(
        '$_pulkitTag NEW_MATCH answer=${match.answer} '
        'formed=${match.line.text} orient=${match.line.orientation.name} '
        'segment=${match.line.dedupeKey}',
      );
    }
  }

  final remaining = sortedTargets
      .where((word) => !completedAnswers.contains(word) && !matchedLines.any((m) => m.answer == word))
      .toList();
  final newlyCompleted = matchedLines.map((m) => m.answer).toSet();
  final allCompletedNow = {...completedAnswers, ...newlyCompleted};

  debugPrint(
    '$_pulkitTag PROGRESS completed=${allCompletedNow.length}/${sortedTargets.length} '
    'remaining=${remaining.isEmpty ? "none" : remaining.join(",")} '
    'trigger=$source',
  );
  debugPrint('$_pulkitTag --- end word check ---');
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
  // Pulkit logs focus on formed-word vs target comparison only.
}

void logPuzzleAnswersCompletion({
  required List<String> targetWords,
  required Set<String> completedAnswers,
  required bool isComplete,
}) {
  // Covered by PROGRESS line inside logMatrixCompletionScan.
}

void _logFormedWordList({
  required String label,
  required List<FormedBoardLine> lines,
  required Map<BoardCellPosition, String> playAreaBoard,
}) {
  if (lines.isEmpty) {
    debugPrint('$_pulkitTag $label count=0 words=none');
    return;
  }

  final summary = lines
      .map(
        (line) =>
            '${line.text}(${line.orientation.name[0]}:${line.dedupeKey})',
      )
      .join(', ');

  debugPrint('$_pulkitTag $label count=${lines.length} words=$summary');

  for (final line in lines) {
    final letters = line.cellsInReadOrder
        .map((cell) => playAreaBoard[cell] ?? '?')
        .join('');
    debugPrint(
      '$_pulkitTag $label word=$letters segment=${line.dedupeKey} '
      'cells=${line.cellsInReadOrder.map(_formatCell).join("->")}',
    );
  }
}

void _logFormedWordComparison({
  required FormedBoardLine line,
  required Set<String> targetAnswers,
  required Set<String> completedAnswers,
}) {
  final sortedTargets = targetAnswers.toList()..sort();
  final comparisons = sortedTargets
      .map((target) {
        final matches = line.text == target;
        return '$target=${matches ? "YES" : "no"}';
      })
      .join(' ');

  final exactTarget = targetAnswers.contains(line.text);
  final alreadyDone = completedAnswers.contains(line.text);
  final verdict = !exactTarget
      ? 'NOT_A_TARGET'
      : alreadyDone
          ? 'ALREADY_COMPLETED'
          : 'NEW_MATCH';

  debugPrint(
    '$_pulkitTag COMPARE formed=${line.text} '
    'orient=${line.orientation.name} '
    'segment=${line.dedupeKey} | $comparisons | verdict=$verdict',
  );
}

String _formatCell(BoardCellPosition cell) {
  return '(${cell.row},${cell.col})';
}

String _formatPieceCells(PuzzlePiece piece) {
  return piece.cells
      .map(
        (cell) =>
            '${cell.letter}@(${piece.anchorRow + cell.rowOffset},${piece.anchorCol + cell.colOffset})',
      )
      .join(' ');
}

String _formatBoard(Map<BoardCellPosition, String> playAreaBoard) {
  final sorted = _sortedBoardCells(playAreaBoard);
  return sorted
      .map((cell) => '${playAreaBoard[cell]}@(${cell.row},${cell.col})')
      .join(' ');
}

List<BoardCellPosition> _sortedBoardCells(
  Map<BoardCellPosition, String> playAreaBoard,
) {
  return playAreaBoard.keys.toList()
    ..sort((a, b) {
      final rowCompare = a.row.compareTo(b.row);
      if (rowCompare != 0) {
        return rowCompare;
      }
      return a.col.compareTo(b.col);
    });
}

void _logBoardFull(Map<BoardCellPosition, String> playAreaBoard) {
  if (playAreaBoard.isEmpty) {
    debugPrint('$_pulkitTag BOARD_FULL count=0 (grid empty)');
    return;
  }

  debugPrint('$_pulkitTag BOARD_FULL count=${playAreaBoard.length}');
  for (final cell in _sortedBoardCells(playAreaBoard)) {
    debugPrint(
      '$_pulkitTag BOARD_FULL   (${cell.row},${cell.col})=${playAreaBoard[cell]}',
    );
  }
}

void _logBoardByPiece(List<PuzzlePiece> pieces) {
  debugPrint('$_pulkitTag BOARD_BY_PIECE totalPieces=${pieces.length}');
  for (final piece in pieces) {
    final atHome = isPieceAtSpawn(piece);
    debugPrint(
      '$_pulkitTag BOARD_BY_PIECE   piece=${piece.id} '
      'atHome=${atHome ? "yes" : "no"} anchor=(${piece.anchorRow},${piece.anchorCol}) '
      'cells=${_formatPieceCells(piece)}',
    );
  }
}

void _logBoardGrid({
  required String label,
  required Map<BoardCellPosition, String> playAreaBoard,
  required int? boardRows,
  required int? boardCols,
  required String emptyLabel,
}) {
  final bounds = _resolveGridBounds(
    playAreaBoard: playAreaBoard,
    boardRows: boardRows,
    boardCols: boardCols,
  );

  if (bounds == null) {
    debugPrint('$_pulkitTag $label skipped (no canvas size and board empty)');
    return;
  }

  debugPrint(
    '$_pulkitTag $label rows=${bounds.minRow}-${bounds.maxRow} '
    'cols=${bounds.minCol}-${bounds.maxCol} (.=empty) note=$emptyLabel',
  );

  final header = StringBuffer('      ');
  for (var col = bounds.minCol; col <= bounds.maxCol; col++) {
    header.write('c$col'.padLeft(4));
  }
  debugPrint('$_pulkitTag $header');

  for (var row = bounds.minRow; row <= bounds.maxRow; row++) {
    final line = StringBuffer('r$row'.padLeft(5));
    for (var col = bounds.minCol; col <= bounds.maxCol; col++) {
      final letter =
          playAreaBoard[BoardCellPosition(row: row, col: col)] ?? '.';
      line.write(letter.padLeft(4));
    }
    debugPrint('$_pulkitTag $line');
  }
}

({int minRow, int maxRow, int minCol, int maxCol})? _resolveGridBounds({
  required Map<BoardCellPosition, String> playAreaBoard,
  required int? boardRows,
  required int? boardCols,
}) {
  if (boardRows != null &&
      boardCols != null &&
      boardRows > 0 &&
      boardCols > 0) {
    return (
      minRow: 0,
      maxRow: boardRows - 1,
      minCol: 0,
      maxCol: boardCols - 1,
    );
  }

  if (playAreaBoard.isEmpty) {
    return null;
  }

  var minRow = playAreaBoard.keys.first.row;
  var maxRow = minRow;
  var minCol = playAreaBoard.keys.first.col;
  var maxCol = minCol;

  for (final cell in playAreaBoard.keys) {
    if (cell.row < minRow) {
      minRow = cell.row;
    }
    if (cell.row > maxRow) {
      maxRow = cell.row;
    }
    if (cell.col < minCol) {
      minCol = cell.col;
    }
    if (cell.col > maxCol) {
      maxCol = cell.col;
    }
  }

  return (minRow: minRow, maxRow: maxRow, minCol: minCol, maxCol: maxCol);
}

/// Formats the play-area board as a readable grid (for tests and debug).
String formatPlayAreaBoardGrid({
  required Map<BoardCellPosition, String> playAreaBoard,
  int? boardRows,
  int? boardCols,
}) {
  final bounds = _resolveGridBounds(
    playAreaBoard: playAreaBoard,
    boardRows: boardRows,
    boardCols: boardCols,
  );
  if (bounds == null) {
    return '';
  }

  final lines = <String>[
    'rows=${bounds.minRow}-${bounds.maxRow} cols=${bounds.minCol}-${bounds.maxCol}',
  ];

  final header = StringBuffer('      ');
  for (var col = bounds.minCol; col <= bounds.maxCol; col++) {
    header.write('c$col'.padLeft(4));
  }
  lines.add(header.toString());

  for (var row = bounds.minRow; row <= bounds.maxRow; row++) {
    final line = StringBuffer('r$row'.padLeft(5));
    for (var col = bounds.minCol; col <= bounds.maxCol; col++) {
      final letter =
          playAreaBoard[BoardCellPosition(row: row, col: col)] ?? '.';
      line.write(letter.padLeft(4));
    }
    lines.add(line.toString());
  }

  return lines.join('\n');
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
