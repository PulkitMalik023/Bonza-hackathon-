import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_deconstructor.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_board_state.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_solved_checker.dart';
import 'package:jam_pro/features/puzzle/domain/word_completion.dart';
import 'package:jam_pro/features/puzzle/domain/word_completion_debug.dart';

void main() {
  const banana = PlacedWord(
    word: 'BANANA',
    row: 0,
    col: 0,
    direction: WordDirection.horizontal,
  );

  test('evaluateWordCompletion reports missing and wrong slots', () {
    final board = {
      const BoardCellPosition(row: 0, col: 0): 'B',
      const BoardCellPosition(row: 0, col: 1): 'N',
      const BoardCellPosition(row: 0, col: 2): 'A',
    };

    final status = evaluateWordCompletion(
      word: banana,
      board: board,
      alreadyCompleted: {},
      key: wordKey(banana, 0),
    );

    expect(status.isComplete, isFalse);
    expect(status.formed, isNull);
    expect(status.missingSlots.length, 3);
    expect(status.wrongSlots.length, 2);
  });

  test('evaluatePuzzleSolved ignores off-layout spawn pieces', () {
    final generator = PuzzleLayoutGenerator();
    final deconstructor = PuzzleDeconstructor();
    final layouts = generator.generateAllLayouts(['RED', 'BLUE', 'GREEN', 'PINK']);
    expect(layouts, isNotEmpty);

    final layout = layouts.first;
    final deconstructed = deconstructor.build(layout);
    final solvedPieces = deconstructed.chunks
        .map(
          (chunk) => PuzzlePiece.fromChunk(
            chunk,
            anchorRow: chunk.solvedMinRow,
            anchorCol: chunk.solvedMinCol,
          ),
        )
        .toList();

    final withSpawnPiece = [
      ...solvedPieces,
      PuzzlePiece(
        id: 'spawn_extra',
        chunkId: 'spawn_extra',
        anchorRow: layout.maxRow + 5,
        anchorCol: layout.maxCol + 5,
        spawnAnchorRow: layout.maxRow + 5,
        spawnAnchorCol: layout.maxCol + 5,
        cells: const [
          PieceCell(letter: 'X', rowOffset: 0, colOffset: 0),
        ],
      ),
    ];

    final status = evaluatePuzzleSolved(
      deconstructed: deconstructed,
      pieces: withSpawnPiece,
      boardRows: layout.maxRow + 10,
      boardCols: layout.maxCol + 10,
    );

    expect(status.isSolved, isTrue);
    expect(status.excludedOffLayoutCount, 1);
  });

  test('formatPlayAreaBoardGrid renders occupied and empty cells', () {
    final board = {
      const BoardCellPosition(row: 1, col: 1): 'S',
      const BoardCellPosition(row: 2, col: 1): 'P',
      const BoardCellPosition(row: 3, col: 0): 'F',
      const BoardCellPosition(row: 3, col: 1): 'O',
      const BoardCellPosition(row: 4, col: 1): 'O',
    };

    final grid = formatPlayAreaBoardGrid(
      playAreaBoard: board,
      boardRows: 6,
      boardCols: 3,
    );

    expect(grid, contains('rows=0-5 cols=0-2'));
    expect(grid, contains('r1   .   S   .'));
    expect(grid, contains('r4   .   O   .'));
    expect(grid, contains('r5   .   .   .'));
  });
}
