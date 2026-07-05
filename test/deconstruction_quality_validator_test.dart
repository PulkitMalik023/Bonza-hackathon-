import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/deconstruction_quality_validator.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_deconstructor.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_layout_selector.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/data/models/deconstructed_puzzle.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_chunk.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_layout.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';

void main() {
  final validator = const DeconstructionQualityValidator();
  final deconstructor = PuzzleDeconstructor();

  test('rejects deconstruction with multi-cell ST and lone T', () {
    final layout = PuzzleLayout.fromPlacedWords(const [
      PlacedWord(
        word: 'EAST',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
      PlacedWord(
        word: 'WEST',
        row: 0,
        col: 2,
        direction: WordDirection.vertical,
      ),
    ]);

    final deconstructed = DeconstructedPuzzle(
      sourceLayout: layout,
      chunks: [
        PuzzleChunk(
          id: 'chunk_st',
          solvedCells: {
            BoardCellPosition(row: 1, col: 2): 'S',
            BoardCellPosition(row: 2, col: 2): 'T',
          },
          localCells: {
            BoardCellPosition(row: 0, col: 0): 'S',
            BoardCellPosition(row: 1, col: 0): 'T',
          },
          solvedMinRow: 1,
          solvedMinCol: 2,
          solvedMaxRow: 2,
          solvedMaxCol: 2,
          width: 1,
          height: 2,
        ),
        PuzzleChunk(
          id: 'chunk_lone_t',
          solvedCells: {
            BoardCellPosition(row: 3, col: 0): 'T',
          },
          localCells: {
            BoardCellPosition(row: 0, col: 0): 'T',
          },
          solvedMinRow: 3,
          solvedMinCol: 0,
          solvedMaxRow: 3,
          solvedMaxCol: 0,
          width: 1,
          height: 1,
        ),
      ],
    );

    expect(
      validator.isValid(layout: layout, deconstructed: deconstructed),
      isFalse,
    );
    expect(
      validator.hasSingletonAndMultiCellLetterConflict(deconstructed),
      isTrue,
    );
  });

  test('accepts deconstruction when T only appears in multi-cell chunks', () {
    final layout = PuzzleLayout.fromPlacedWords(const [
      PlacedWord(
        word: 'EAST',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
      PlacedWord(
        word: 'WEST',
        row: 0,
        col: 2,
        direction: WordDirection.vertical,
      ),
    ]);

    final deconstructed = DeconstructedPuzzle(
      sourceLayout: layout,
      chunks: [
        PuzzleChunk(
          id: 'chunk_st',
          solvedCells: {
            BoardCellPosition(row: 1, col: 2): 'S',
            BoardCellPosition(row: 2, col: 2): 'T',
          },
          localCells: {
            BoardCellPosition(row: 0, col: 0): 'S',
            BoardCellPosition(row: 1, col: 0): 'T',
          },
          solvedMinRow: 1,
          solvedMinCol: 2,
          solvedMaxRow: 2,
          solvedMaxCol: 2,
          width: 1,
          height: 2,
        ),
        PuzzleChunk(
          id: 'chunk_th',
          solvedCells: {
            BoardCellPosition(row: 3, col: 0): 'T',
            BoardCellPosition(row: 4, col: 0): 'H',
          },
          localCells: {
            BoardCellPosition(row: 0, col: 0): 'T',
            BoardCellPosition(row: 1, col: 0): 'H',
          },
          solvedMinRow: 3,
          solvedMinCol: 0,
          solvedMaxRow: 4,
          solvedMaxCol: 0,
          width: 1,
          height: 2,
        ),
      ],
    );

    expect(
      validator.isValid(layout: layout, deconstructed: deconstructed),
      isTrue,
    );
  });

  test('accepts Spectrum-style IAN chunk with separate lone N', () {
    final layout = PuzzleLayout.fromPlacedWords(const [
      PlacedWord(
        word: 'ORANGE',
        row: 4,
        col: 1,
        direction: WordDirection.horizontal,
      ),
      PlacedWord(
        word: 'INDIGO',
        row: 3,
        col: 4,
        direction: WordDirection.vertical,
      ),
      PlacedWord(
        word: 'GREEN',
        row: 2,
        col: 6,
        direction: WordDirection.vertical,
      ),
    ]);

    final deconstructed = DeconstructedPuzzle(
      sourceLayout: layout,
      chunks: [
        PuzzleChunk(
          id: 'chunk_ian',
          solvedCells: {
            BoardCellPosition(row: 3, col: 4): 'I',
            BoardCellPosition(row: 4, col: 3): 'A',
            BoardCellPosition(row: 4, col: 4): 'N',
          },
          localCells: {
            BoardCellPosition(row: 0, col: 1): 'I',
            BoardCellPosition(row: 1, col: 0): 'A',
            BoardCellPosition(row: 1, col: 1): 'N',
          },
          solvedMinRow: 3,
          solvedMinCol: 3,
          solvedMaxRow: 4,
          solvedMaxCol: 4,
          width: 2,
          height: 2,
        ),
        PuzzleChunk(
          id: 'chunk_lone_n',
          solvedCells: {
            BoardCellPosition(row: 6, col: 6): 'N',
          },
          localCells: {
            BoardCellPosition(row: 0, col: 0): 'N',
          },
          solvedMinRow: 6,
          solvedMinCol: 6,
          solvedMaxRow: 6,
          solvedMaxCol: 6,
          width: 1,
          height: 1,
        ),
      ],
    );

    expect(
      validator.isValid(layout: layout, deconstructed: deconstructed),
      isTrue,
    );
    expect(
      validator.hasSingletonAndMultiCellLetterConflict(deconstructed),
      isFalse,
    );
  });

  test('rejects singleton chunk at crossword crossing', () {
    final layout = PuzzleLayout.fromPlacedWords(const [
      PlacedWord(
        word: 'ORANGE',
        row: 1,
        col: 0,
        direction: WordDirection.horizontal,
      ),
      PlacedWord(
        word: 'INDIGO',
        row: 0,
        col: 3,
        direction: WordDirection.vertical,
      ),
    ]);

    final deconstructed = DeconstructedPuzzle(
      sourceLayout: layout,
      chunks: [
        PuzzleChunk(
          id: 'chunk_lone_n',
          solvedCells: {
            BoardCellPosition(row: 1, col: 3): 'N',
          },
          localCells: {
            BoardCellPosition(row: 0, col: 0): 'N',
          },
          solvedMinRow: 1,
          solvedMinCol: 3,
          solvedMaxRow: 1,
          solvedMaxCol: 3,
          width: 1,
          height: 1,
        ),
      ],
    );

    expect(
      validator.isValid(layout: layout, deconstructed: deconstructed),
      isFalse,
    );
    expect(
      validator.hasCrossingCellsInSingletonChunks(layout, deconstructed),
      isTrue,
    );
  });

  test('DIRECTIONS has at least one layout with valid deconstruction', () {
    final layouts = PuzzleLayoutGenerator()
        .generateAllLayouts(['NORTH', 'SOUTH', 'EAST', 'WEST']);
    final selector = PuzzleLayoutSelector();

    expect(layouts, isNotEmpty);
    expect(
      layouts.any(selector.hasValidDeconstruction),
      isTrue,
      reason: 'At least one DIRECTIONS layout should pass quality validation',
    );
  });

  test('prioritizeValidDeconstructionLayouts puts valid layouts first', () {
    final layouts = PuzzleLayoutGenerator()
        .generateAllLayouts(['NORTH', 'SOUTH', 'EAST', 'WEST']);
    final selector = PuzzleLayoutSelector();
    final prioritized =
        selector.prioritizeValidDeconstructionLayouts(layouts);

    expect(prioritized, isNotEmpty);
    expect(selector.hasValidDeconstruction(prioritized.first), isTrue);
  });

  test('actual DIRECTIONS deconstruction from generator can be validated', () {
    final layouts = PuzzleLayoutGenerator()
        .generateAllLayouts(['NORTH', 'SOUTH', 'EAST', 'WEST']);

    var sawDeconstruction = false;
    for (final layout in layouts) {
      final deconstructed = deconstructor.tryBuild(layout);
      if (deconstructed == null) {
        continue;
      }
      sawDeconstruction = true;
      final valid = validator.isValid(
        layout: layout,
        deconstructed: deconstructed,
      );
      if (!valid) {
        expect(
          validator.hasSingletonAndMultiCellLetterConflict(deconstructed),
          isTrue,
        );
      }
    }

    expect(sawDeconstruction, isTrue);
  });
}
