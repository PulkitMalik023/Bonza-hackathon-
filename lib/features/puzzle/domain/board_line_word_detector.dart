import 'board_cell_position.dart';

enum LineOrientation { horizontal, vertical }

class FormedBoardLine {
  const FormedBoardLine({
    required this.text,
    required this.orientation,
    required this.cellsInReadOrder,
    required this.dedupeKey,
  });

  final String text;
  final LineOrientation orientation;
  final List<BoardCellPosition> cellsInReadOrder;
  final String dedupeKey;
}

class MatchedBoardLine {
  const MatchedBoardLine({
    required this.line,
    required this.answer,
  });

  final FormedBoardLine line;
  final String answer;
}

FormedBoardLine? getHorizontalLineFromCell(
  int row,
  int col,
  Map<BoardCellPosition, String> board,
) {
  final start = BoardCellPosition(row: row, col: col);
  if (!board.containsKey(start)) {
    return null;
  }

  var minCol = col;
  while (board.containsKey(BoardCellPosition(row: row, col: minCol - 1))) {
    minCol--;
  }

  var maxCol = col;
  while (board.containsKey(BoardCellPosition(row: row, col: maxCol + 1))) {
    maxCol++;
  }

  final cells = [
    for (var currentCol = minCol; currentCol <= maxCol; currentCol++)
      BoardCellPosition(row: row, col: currentCol),
  ];

  final text = cells.map((cell) => board[cell]!).join().toUpperCase();

  return FormedBoardLine(
    text: text,
    orientation: LineOrientation.horizontal,
    cellsInReadOrder: cells,
    dedupeKey: 'H:$row:$minCol-$maxCol',
  );
}

FormedBoardLine? getVerticalLineFromCell(
  int row,
  int col,
  Map<BoardCellPosition, String> board,
) {
  final start = BoardCellPosition(row: row, col: col);
  if (!board.containsKey(start)) {
    return null;
  }

  var minRow = row;
  while (board.containsKey(BoardCellPosition(row: minRow - 1, col: col))) {
    minRow--;
  }

  var maxRow = row;
  while (board.containsKey(BoardCellPosition(row: maxRow + 1, col: col))) {
    maxRow++;
  }

  final cells = [
    for (var currentRow = minRow; currentRow <= maxRow; currentRow++)
      BoardCellPosition(row: currentRow, col: col),
  ];

  final text = cells.map((cell) => board[cell]!).join().toUpperCase();

  return FormedBoardLine(
    text: text,
    orientation: LineOrientation.vertical,
    cellsInReadOrder: cells,
    dedupeKey: 'V:$col:$minRow-$maxRow',
  );
}

Map<String, FormedBoardLine> collectCandidateLines({
  required Map<BoardCellPosition, String> board,
  required Set<BoardCellPosition> affectedCells,
}) {
  final candidates = <String, FormedBoardLine>{};

  for (final cell in affectedCells) {
    final horizontal = getHorizontalLineFromCell(cell.row, cell.col, board);
    if (horizontal != null) {
      candidates[horizontal.dedupeKey] = horizontal;
    }

    final vertical = getVerticalLineFromCell(cell.row, cell.col, board);
    if (vertical != null) {
      candidates[vertical.dedupeKey] = vertical;
    }
  }

  return candidates;
}

List<MatchedBoardLine> findNewlyCompletedLines({
  required Map<BoardCellPosition, String> board,
  required Set<BoardCellPosition> affectedCells,
  required Set<String> targetAnswers,
  required Set<String> completedAnswers,
}) {
  final candidates = collectCandidateLines(
    board: board,
    affectedCells: affectedCells,
  );

  final matched = <MatchedBoardLine>[];
  final matchedAnswers = <String>{};

  for (final line in candidates.values) {
    if (!targetAnswers.contains(line.text)) {
      continue;
    }
    if (completedAnswers.contains(line.text)) {
      continue;
    }
    if (matchedAnswers.contains(line.text)) {
      continue;
    }

    matchedAnswers.add(line.text);
    matched.add(MatchedBoardLine(line: line, answer: line.text));
  }

  return matched;
}

Set<String> normalizeTargetAnswers(List<String> words) {
  return words.map((word) => word.toUpperCase()).toSet();
}
