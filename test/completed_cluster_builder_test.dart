import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/board_line_word_detector.dart';
import 'package:jam_pro/features/puzzle/domain/completed_cluster_builder.dart';

void main() {
  MatchedBoardLine line({
    required String answer,
    required List<BoardCellPosition> cells,
    required LineOrientation orientation,
  }) {
    final minCol = cells.map((cell) => cell.col).reduce((a, b) => a < b ? a : b);
    final maxCol = cells.map((cell) => cell.col).reduce((a, b) => a > b ? a : b);
    final minRow = cells.map((cell) => cell.row).reduce((a, b) => a < b ? a : b);
    final maxRow = cells.map((cell) => cell.row).reduce((a, b) => a > b ? a : b);

    final dedupeKey = orientation == LineOrientation.horizontal
        ? 'H:${cells.first.row}:$minCol-$maxCol'
        : 'V:${cells.first.col}:$minRow-$maxRow';

    return MatchedBoardLine(
      line: FormedBoardLine(
        text: answer,
        orientation: orientation,
        cellsInReadOrder: cells,
        dedupeKey: dedupeKey,
      ),
      answer: answer,
    );
  }

  test('overlapping horizontal and vertical words merge into one cluster', () {
    final matched = [
      line(
        answer: 'CAT',
        cells: const [
          BoardCellPosition(row: 0, col: 0),
          BoardCellPosition(row: 0, col: 1),
          BoardCellPosition(row: 0, col: 2),
        ],
        orientation: LineOrientation.horizontal,
      ),
      line(
        answer: 'CAR',
        cells: const [
          BoardCellPosition(row: 0, col: 0),
          BoardCellPosition(row: 1, col: 0),
          BoardCellPosition(row: 2, col: 0),
        ],
        orientation: LineOrientation.vertical,
      ),
    ];

    final clusters = buildCompletedClusters(matched);

    expect(clusters, hasLength(1));
    expect(clusters.first.answers, {'CAT', 'CAR'});
    expect(clusters.first.cells.length, 5);
  });

  test('disjoint completed words produce separate clusters', () {
    final matched = [
      line(
        answer: 'RED',
        cells: const [
          BoardCellPosition(row: 0, col: 0),
          BoardCellPosition(row: 0, col: 1),
          BoardCellPosition(row: 0, col: 2),
        ],
        orientation: LineOrientation.horizontal,
      ),
      line(
        answer: 'BLUE',
        cells: const [
          BoardCellPosition(row: 2, col: 0),
          BoardCellPosition(row: 2, col: 1),
          BoardCellPosition(row: 2, col: 2),
          BoardCellPosition(row: 2, col: 3),
        ],
        orientation: LineOrientation.horizontal,
      ),
    ];

    final clusters = buildCompletedClusters(matched);

    expect(clusters, hasLength(2));
  });
}
