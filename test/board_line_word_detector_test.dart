import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/board_line_word_detector.dart';

void main() {
  test('horizontal APP + LE forms APPLE left to right', () {
    final board = {
      const BoardCellPosition(row: 2, col: 0): 'A',
      const BoardCellPosition(row: 2, col: 1): 'P',
      const BoardCellPosition(row: 2, col: 2): 'P',
      const BoardCellPosition(row: 2, col: 3): 'L',
      const BoardCellPosition(row: 2, col: 4): 'E',
    };

    final line = getHorizontalLineFromCell(2, 3, board);

    expect(line, isNotNull);
    expect(line!.text, 'APPLE');
    expect(line.dedupeKey, 'H:2:0-4');
  });

  test('horizontal LE + APP forms LEAPP left to right', () {
    final board = {
      const BoardCellPosition(row: 1, col: 0): 'L',
      const BoardCellPosition(row: 1, col: 1): 'E',
      const BoardCellPosition(row: 1, col: 2): 'A',
      const BoardCellPosition(row: 1, col: 3): 'P',
      const BoardCellPosition(row: 1, col: 4): 'P',
    };

    final line = getHorizontalLineFromCell(1, 0, board);

    expect(line, isNotNull);
    expect(line!.text, 'LEAPP');
  });

  test('vertical line reads top to bottom', () {
    final board = {
      const BoardCellPosition(row: 0, col: 2): 'R',
      const BoardCellPosition(row: 1, col: 2): 'E',
      const BoardCellPosition(row: 2, col: 2): 'D',
    };

    final line = getVerticalLineFromCell(1, 2, board);

    expect(line, isNotNull);
    expect(line!.text, 'RED');
    expect(line.dedupeKey, 'V:2:0-2');
  });

  test('collectCandidateLines deduplicates same horizontal line', () {
    final board = {
      const BoardCellPosition(row: 4, col: 0): 'B',
      const BoardCellPosition(row: 4, col: 1): 'L',
      const BoardCellPosition(row: 4, col: 2): 'U',
      const BoardCellPosition(row: 4, col: 3): 'E',
    };

    final candidates = collectCandidateLines(
      board: board,
      affectedCells: {
        const BoardCellPosition(row: 4, col: 0),
        const BoardCellPosition(row: 4, col: 2),
      },
    );

    expect(candidates.values.where((line) => line.orientation == LineOrientation.horizontal).length, 1);
    expect(candidates.values.firstWhere((line) => line.orientation == LineOrientation.horizontal).text, 'BLUE');
  });

  test('findNewlyCompletedLines matches target answers once', () {
    final board = {
      const BoardCellPosition(row: 0, col: 0): 'R',
      const BoardCellPosition(row: 0, col: 1): 'E',
      const BoardCellPosition(row: 0, col: 2): 'D',
      const BoardCellPosition(row: 1, col: 0): 'B',
      const BoardCellPosition(row: 1, col: 1): 'L',
      const BoardCellPosition(row: 1, col: 2): 'U',
      const BoardCellPosition(row: 1, col: 3): 'E',
    };

    final matched = findNewlyCompletedLines(
      board: board,
      affectedCells: {const BoardCellPosition(row: 0, col: 1)},
      targetAnswers: {'RED', 'BLUE', 'GREEN'},
      completedAnswers: {},
    );

    expect(matched.length, 1);
    expect(matched.first.answer, 'RED');
  });

  test('expandScanScopeWithLineSegments includes full horizontal run', () {
    final board = {
      const BoardCellPosition(row: 0, col: 0): 'F',
      const BoardCellPosition(row: 0, col: 1): 'O',
      const BoardCellPosition(row: 0, col: 2): 'R',
      const BoardCellPosition(row: 0, col: 3): 'K',
    };

    final expanded = expandScanScopeWithLineSegments(
      baseScope: {const BoardCellPosition(row: 0, col: 3)},
      board: board,
    );

    expect(expanded, board.keys.toSet());
  });
}
