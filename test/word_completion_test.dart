import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_board_state.dart';
import 'package:jam_pro/features/puzzle/domain/word_completion.dart';

void main() {
  const banana = PlacedWord(
    word: 'BANANA',
    row: 0,
    col: 0,
    direction: WordDirection.horizontal,
  );

  test('formedWordForPlacedWord returns null when a slot is missing', () {
    final board = {
      const BoardCellPosition(row: 0, col: 0): 'B',
      const BoardCellPosition(row: 0, col: 1): 'A',
      const BoardCellPosition(row: 0, col: 2): 'N',
    };

    expect(formedWordForPlacedWord(banana, board), isNull);
  });

  test('isWordCompleted is false for wrong letters or order', () {
    final partialBoard = {
      const BoardCellPosition(row: 0, col: 0): 'B',
      const BoardCellPosition(row: 0, col: 1): 'N',
      const BoardCellPosition(row: 0, col: 2): 'A',
      const BoardCellPosition(row: 0, col: 3): 'N',
      const BoardCellPosition(row: 0, col: 4): 'A',
      const BoardCellPosition(row: 0, col: 5): 'A',
    };

    expect(
      isWordCompleted(
        word: banana,
        board: partialBoard,
        alreadyCompleted: {},
        key: wordKey(banana, 0),
      ),
      isFalse,
    );
  });

  test('isWordCompleted is true only for exact match', () {
    final solvedBoard = {
      for (final slot in boardSlotsForPlacedWord(banana))
        slot.position: slot.letter,
    };

    expect(
      isWordCompleted(
        word: banana,
        board: solvedBoard,
        alreadyCompleted: {},
        key: wordKey(banana, 0),
      ),
      isTrue,
    );
  });

  test('isWordCompleted ignores already completed words', () {
    final solvedBoard = {
      for (final slot in boardSlotsForPlacedWord(banana))
        slot.position: slot.letter,
    };
    final key = wordKey(banana, 0);

    expect(
      isWordCompleted(
        word: banana,
        board: solvedBoard,
        alreadyCompleted: {key},
        key: key,
      ),
      isFalse,
    );
  });
}
