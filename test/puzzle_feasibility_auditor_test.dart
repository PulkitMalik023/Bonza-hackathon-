import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/chunk_signature.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/deconstruction_quality_validator.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_deconstructor.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_feasibility_auditor.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/data/models/deconstructed_puzzle.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_chunk.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_content.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_layout.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';

void main() {
  const validator = DeconstructionQualityValidator();
  final deconstructor = PuzzleDeconstructor();
  final auditor = PuzzleFeasibilityAuditor();

  test('horizontal NA and vertical AN have different signatures', () {
    final horizontal = signatureFromLocalCells({
      const BoardCellPosition(row: 0, col: 0): 'N',
      const BoardCellPosition(row: 0, col: 1): 'A',
    });
    final vertical = signatureFromLocalCells({
      const BoardCellPosition(row: 0, col: 0): 'A',
      const BoardCellPosition(row: 1, col: 0): 'N',
    });

    expect(horizontal, isNot(vertical));
  });

  test('duplicate chunk signatures are rejected', () {
    final layout = PuzzleLayout.fromPlacedWords(const [
      PlacedWord(
        word: 'NA',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
      PlacedWord(
        word: 'NA',
        row: 2,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);

    final deconstructed = DeconstructedPuzzle(
      sourceLayout: layout,
      chunks: [
        PuzzleChunk(
          id: 'chunk_a',
          solvedCells: {
            BoardCellPosition(row: 0, col: 0): 'N',
            BoardCellPosition(row: 0, col: 1): 'A',
          },
          localCells: {
            BoardCellPosition(row: 0, col: 0): 'N',
            BoardCellPosition(row: 0, col: 1): 'A',
          },
          solvedMinRow: 0,
          solvedMinCol: 0,
          solvedMaxRow: 0,
          solvedMaxCol: 1,
          width: 2,
          height: 1,
        ),
        PuzzleChunk(
          id: 'chunk_b',
          solvedCells: {
            BoardCellPosition(row: 2, col: 0): 'N',
            BoardCellPosition(row: 2, col: 1): 'A',
          },
          localCells: {
            BoardCellPosition(row: 0, col: 0): 'N',
            BoardCellPosition(row: 0, col: 1): 'A',
          },
          solvedMinRow: 2,
          solvedMinCol: 0,
          solvedMaxRow: 2,
          solvedMaxCol: 1,
          width: 2,
          height: 1,
        ),
      ],
    );

    expect(validator.hasDuplicateChunkSignatures(deconstructed), isTrue);
    expect(validator.isValid(layout: layout, deconstructed: deconstructed), isFalse);
  });

  test('DIRECTIONS puzzle is playable under new rules', () {
    final report = auditor.audit(
      const PuzzleContent(
        id: 1,
        category: 'Directions',
        words: ['NORTH', 'SOUTH', 'EAST', 'WEST'],
      ),
    );

    expect(report.canGenerateLayout, isTrue);
    expect(report.canDeconstruct, isTrue);
    expect(report.isPlayable, isTrue);
  });

  test('PINK and SINK deconstruction satisfies rules when found', () {
    final report = auditor.audit(
      const PuzzleContent(
        id: 99,
        category: 'Test',
        words: ['PINK', 'SINK'],
      ),
    );

    expect(report.canGenerateLayout, isTrue);

    if (report.canDeconstruct) {
      final layouts =
          PuzzleLayoutGenerator().generateAllLayouts(['PINK', 'SINK']);
      DeconstructedPuzzle? validDeconstructed;

      for (final layout in layouts) {
        final deconstructed = deconstructor.tryBuild(layout);
        if (deconstructed != null &&
            validator.isValid(layout: layout, deconstructed: deconstructed)) {
          validDeconstructed = deconstructed;
          break;
        }
      }

      expect(validDeconstructed, isNotNull);
      expect(validator.hasDuplicateChunkSignatures(validDeconstructed!), isFalse);
      expect(validator.hasSingletonChunks(validDeconstructed), isFalse);
    }
  });

  test('deconstruction uses only chunk sizes 2 and 3', () {
    final layouts =
        PuzzleLayoutGenerator().generateAllLayouts(['RED', 'BLUE', 'GREEN', 'PINK']);
    expect(layouts, isNotEmpty);

    final deconstructed = deconstructor.tryBuild(layouts.first);
    expect(deconstructed, isNotNull);

    for (final chunk in deconstructed!.chunks) {
      expect(chunk.solvedCells.length, inInclusiveRange(2, 3));
    }

    expect(validator.hasSingletonChunks(deconstructed), isFalse);
    expect(validator.hasDuplicateChunkSignatures(deconstructed), isFalse);
  });
}
