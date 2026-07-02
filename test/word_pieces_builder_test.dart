import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/domain/word_pieces_builder.dart';

void main() {
  final generator = PuzzleLayoutGenerator();

  group('cellsForPlacedWord', () {
    test('builds horizontal cells with col offsets', () {
      const placed = PlacedWord(
        word: 'NORTH',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      );

      final cells = cellsForPlacedWord(placed);

      expect(cells.length, 5);
      expect(cells.first.rowOffset, 0);
      expect(cells.first.colOffset, 0);
      expect(cells.last.rowOffset, 0);
      expect(cells.last.colOffset, 4);
      expect(cells.map((cell) => cell.letter).join(), 'NORTH');
    });

    test('builds vertical cells with row offsets', () {
      const placed = PlacedWord(
        word: 'RED',
        row: 0,
        col: 0,
        direction: WordDirection.vertical,
      );

      final cells = cellsForPlacedWord(placed);

      expect(cells.length, 3);
      expect(cells.first.rowOffset, 0);
      expect(cells.first.colOffset, 0);
      expect(cells.last.rowOffset, 2);
      expect(cells.last.colOffset, 0);
    });
  });

  group('buildWordPieces', () {
    test('creates one piece per word for a four-word puzzle', () {
      final layouts = generator.generateAllLayouts(
        ['RED', 'BLUE', 'GREEN', 'PINK'],
      );
      expect(layouts, isNotEmpty);

      const canvasRows = 20;
      const canvasCols = 12;
      final pieces = buildWordPieces(
        layout: layouts.first,
        canvasRows: canvasRows,
        canvasCols: canvasCols,
      );

      expect(pieces.length, 4);
    });

    test('assigns non-overlapping spawn anchors inside canvas', () {
      final layouts = generator.generateAllLayouts(
        ['NORTH', 'SOUTH', 'EAST', 'WEST'],
      );
      expect(layouts, isNotEmpty);

      const canvasRows = 24;
      const canvasCols = 16;
      final pieces = buildWordPieces(
        layout: layouts.first,
        canvasRows: canvasRows,
        canvasCols: canvasCols,
      );

      expect(wordSpawnAnchorsAreNonOverlapping(pieces), isTrue);
      expect(
        wordPiecesFitCanvas(
          pieces: pieces,
          canvasRows: canvasRows,
          canvasCols: canvasCols,
        ),
        isTrue,
      );
    });

    test('uses layout direction for piece shape', () {
      final layouts = generator.generateAllLayouts(['CAT', 'CAR']);
      expect(layouts, isNotEmpty);

      final layout = layouts.first;
      final pieces = buildWordPieces(
        layout: layout,
        canvasRows: 20,
        canvasCols: 12,
      );

      for (var index = 0; index < layout.placedWords.length; index++) {
        final placed = layout.placedWords[index];
        final piece = pieces[index];

        if (placed.direction == WordDirection.horizontal) {
          expect(piece.cells.every((cell) => cell.rowOffset == 0), isTrue);
        } else {
          expect(piece.cells.every((cell) => cell.colOffset == 0), isTrue);
        }
      }
    });

    test('rebuilds with different orientations when layout changes', () {
      final layouts = generator.generateAllLayouts(['RED', 'BLUE', 'GREEN']);
      if (layouts.length < 2) {
        return;
      }

      final first = buildWordPieces(
        layout: layouts.first,
        canvasRows: 20,
        canvasCols: 12,
      );
      final second = buildWordPieces(
        layout: layouts[1],
        canvasRows: 20,
        canvasCols: 12,
      );

      expect(first.length, second.length);

      final firstShapes = first
          .map(
            (piece) => piece.cells
                .map((cell) => '${cell.rowOffset},${cell.colOffset}')
                .join('|'),
          )
          .toList();
      final secondShapes = second
          .map(
            (piece) => piece.cells
                .map((cell) => '${cell.rowOffset},${cell.colOffset}')
                .join('|'),
          )
          .toList();

      expect(firstShapes == secondShapes, isFalse);
    });
  });
}
