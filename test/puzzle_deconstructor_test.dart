import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_deconstructor.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_layout.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_solved_checker.dart';
import 'package:jam_pro/features/puzzle/presentation/puzzle_tray_layout.dart';

void main() {
  final generator = PuzzleLayoutGenerator();
  final deconstructor = PuzzleDeconstructor();

  PuzzleLayout layoutForWords(List<String> words) {
    final layouts = generator.generateAllLayouts(words);
    expect(layouts, isNotEmpty);
    return layouts.first;
  }

  test('deconstructs all occupied cells exactly once', () {
    final layout = layoutForWords(['NORTH', 'SOUTH', 'EAST', 'WEST']);
    final result = deconstructor.build(layout);

    final assigned = <BoardCellPosition>{};
    for (final chunk in result.chunks) {
      for (final cell in chunk.solvedCells.keys) {
        expect(assigned.add(cell), isTrue, reason: 'Duplicate cell $cell');
      }
    }

    expect(assigned.length, layout.occupiedCells.length);
  });

  test('every chunk is internally connected', () {
    final layout = layoutForWords(['VENUS', 'NEPTUNE', 'MARS', 'SATURN', 'JUPITER']);
    final result = deconstructor.build(layout);

    for (final chunk in result.chunks) {
      expect(
        PuzzleDeconstructor.isConnectedCellSet(chunk.solvedCells.keys.toSet()),
        isTrue,
        reason: 'Chunk ${chunk.id} is disconnected',
      );
    }
  });

  test('deconstruction is deterministic for the same layout', () {
    final layout = layoutForWords(['APPLE', 'MANGO', 'GRAPE', 'BANANA']);
    final first = deconstructor.build(layout);
    final second = deconstructor.build(layout);

    expect(first.chunks.length, second.chunks.length);
    for (var index = 0; index < first.chunks.length; index++) {
      expect(first.chunks[index].solvedCells, second.chunks[index].solvedCells);
    }
  });

  test('union of chunk solved cells matches layout occupied cells', () {
    final layout = layoutForWords(['RED', 'BLUE', 'GREEN', 'PINK']);
    final result = deconstructor.build(layout);

    final chunkLetters = <BoardCellPosition, String>{};
    for (final chunk in result.chunks) {
      chunkLetters.addAll(chunk.solvedCells);
    }

    final layoutLetters = {
      for (final cell in layout.occupiedCells)
        BoardCellPosition(row: cell.row, col: cell.col): cell.letter,
    };

    expect(chunkLetters, layoutLetters);
  });

  test('chunk sizes are limited to 1, 2, or 3 cells', () {
    final layout = layoutForWords(['RED', 'BLUE', 'GREEN', 'PINK']);
    final result = deconstructor.build(layout);

    for (final chunk in result.chunks) {
      final size = chunk.solvedCells.length;
      expect(size, inInclusiveRange(1, 3));
    }

    final multiCellChunks =
        result.chunks.where((chunk) => chunk.solvedCells.length > 1).length;
    expect(multiCellChunks, greaterThan(0));
  });

  test('isPuzzleSolved returns true when pieces match solved layout', () {
    final layout = layoutForWords(['SPOON', 'FORK', 'KNIFE']);
    final deconstructed = deconstructor.build(layout);
    final boardRows = layout.maxRow - layout.minRow + 1;
    final boardCols = layout.maxCol - layout.minCol + 1;

    final pieces = deconstructed.chunks
        .map(
          (chunk) => PuzzlePiece.fromChunk(
            chunk,
            anchorRow: chunk.solvedMinRow,
            anchorCol: chunk.solvedMinCol,
          ),
        )
        .toList();

    expect(
      isPuzzleSolved(
        deconstructed: deconstructed,
        pieces: pieces,
        boardRows: boardRows,
        boardCols: boardCols,
      ),
      isTrue,
    );
  });

    test('buildPieces places chunks below the board', () {
      final layout = layoutForWords(['NORTH', 'SOUTH', 'EAST', 'WEST']);
      final deconstructed = deconstructor.build(layout);
      final boardRows = layout.maxRow - layout.minRow + 1;
      final boardCols = layout.maxCol - layout.minCol + 1;
      final trayLayout = ChunkTrayLayoutService().compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: 48,
      );
      final pieces = ChunkTrayLayoutService().buildPieces(
        chunks: deconstructed.chunks,
        layout: trayLayout,
      );

      expect(pieces, hasLength(deconstructed.chunks.length));
      expect(
        allPiecesFitCanvas(
          pieces: pieces,
          canvasRows: trayLayout.canvasRows,
          canvasCols: trayLayout.canvasCols,
        ),
        isTrue,
      );
      for (final piece in pieces) {
        expect(piece.anchorRow, greaterThanOrEqualTo(boardRows + 1));
      }
    });
}
