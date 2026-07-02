import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/domain/deconstructed_pieces_builder.dart';
import 'package:jam_pro/features/puzzle/domain/piece_spawn_layout.dart';

void main() {
  final generator = PuzzleLayoutGenerator();

  group('buildDeconstructedPlayPieces', () {
    test('creates multiple pieces for a multi-word puzzle', () {
      final layouts = generator.generateAllLayouts(
        ['RED', 'BLUE', 'GREEN', 'PINK'],
      );
      expect(layouts, isNotEmpty);

      const canvasRows = 24;
      const canvasCols = 16;
      final pieces = buildDeconstructedPlayPieces(
        layout: layouts.first,
        canvasRows: canvasRows,
        canvasCols: canvasCols,
      );

      expect(pieces.length, greaterThan(1));
      for (final piece in pieces) {
        expect(piece.cells, isNotEmpty);
        expect(
          piece.cells.every((cell) => cell.rowOffset >= 0 && cell.colOffset >= 0),
          isTrue,
        );
      }
    });

    test('assigns non-overlapping spawn anchors inside canvas', () {
      final layouts = generator.generateAllLayouts(
        ['NORTH', 'SOUTH', 'EAST', 'WEST'],
      );
      expect(layouts, isNotEmpty);

      const canvasRows = 24;
      const canvasCols = 16;
      final pieces = buildDeconstructedPlayPieces(
        layout: layouts.first,
        canvasRows: canvasRows,
        canvasCols: canvasCols,
      );

      expect(pieceSpawnAnchorsAreNonOverlapping(pieces), isTrue);
      expect(
        piecesFitCanvas(
          pieces: pieces,
          canvasRows: canvasRows,
          canvasCols: canvasCols,
        ),
        isTrue,
      );
    });

    test('rebuilds with different chunk shapes when layout changes', () {
      final layouts = generator.generateAllLayouts(['RED', 'BLUE', 'GREEN']);
      if (layouts.length < 2) {
        return;
      }

      const canvasRows = 20;
      const canvasCols = 12;

      final first = buildDeconstructedPlayPieces(
        layout: layouts.first,
        canvasRows: canvasRows,
        canvasCols: canvasCols,
      );
      final second = buildDeconstructedPlayPieces(
        layout: layouts[1],
        canvasRows: canvasRows,
        canvasCols: canvasCols,
      );

      final firstShapes = first
          .map(
            (piece) => piece.cells
                .map((cell) => '${cell.rowOffset},${cell.colOffset}')
                .join('|'),
          )
          .toList()
        ..sort();
      final secondShapes = second
          .map(
            (piece) => piece.cells
                .map((cell) => '${cell.rowOffset},${cell.colOffset}')
                .join('|'),
          )
          .toList()
        ..sort();

      expect(firstShapes == secondShapes, isFalse);
    });
  });
}
