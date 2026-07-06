import 'board_cell_position.dart';
import 'board_line_word_detector.dart';
import 'puzzle_board_state.dart';
import 'puzzle_piece.dart';

class CompletedCluster {
  CompletedCluster({
    required this.answers,
    required Map<BoardCellPosition, String> cells,
  }) : cells = Map.unmodifiable(cells);

  final Set<String> answers;
  final Map<BoardCellPosition, String> cells;

  String get id => clusterKeyFromCells(cells);
}

List<CompletedCluster> buildCompletedClusters(
  List<MatchedBoardLine> matchedLines, {
  required List<PuzzlePiece> pieces,
  required Map<BoardCellPosition, String> playAreaBoard,
}) {
  if (matchedLines.isEmpty) {
    return const [];
  }

  final parent = List<int>.generate(matchedLines.length, (index) => index);

  int find(int index) {
    if (parent[index] != index) {
      parent[index] = find(parent[index]);
    }
    return parent[index];
  }

  void union(int left, int right) {
    final leftRoot = find(left);
    final rightRoot = find(right);
    if (leftRoot != rightRoot) {
      parent[rightRoot] = leftRoot;
    }
  }

  final lineCellSets = matchedLines
      .map((match) => match.line.cellsInReadOrder.toSet())
      .toList();

  for (var left = 0; left < matchedLines.length; left++) {
    for (var right = left + 1; right < matchedLines.length; right++) {
      final overlaps = lineCellSets[left].any(lineCellSets[right].contains);
      if (overlaps) {
        union(left, right);
      }
    }
  }

  final groupedAnswers = <int, Set<String>>{};
  final groupedMatchedCells = <int, Set<BoardCellPosition>>{};

  for (var index = 0; index < matchedLines.length; index++) {
    final root = find(index);
    final match = matchedLines[index];

    groupedAnswers[root] = {
      ...?groupedAnswers[root],
      match.answer,
    };
    groupedMatchedCells[root] = {
      ...?groupedMatchedCells[root],
      ...match.line.cellsInReadOrder,
    };
  }

  return groupedAnswers.entries.map((entry) {
    final matchedCells = groupedMatchedCells[entry.key]!;
    return CompletedCluster(
      answers: entry.value,
      cells: expandMatchedLineCellsToOwnerPieces(
        matchedCells: matchedCells,
        pieces: pieces,
        playAreaBoard: playAreaBoard,
      ),
    );
  }).toList();
}
