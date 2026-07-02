import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/solved_layout_piece_builder.dart';

void main() {
  final generator = PuzzleLayoutGenerator();

  group('buildSolvedPiece', () {
    test('creates one piece covering all occupied cells', () {
      final layouts = generator.generateAllLayouts(
        ['NORTH', 'SOUTH', 'EAST', 'WEST'],
      );
      expect(layouts, isNotEmpty);

      final layout = layouts.first;
      final pieceState = buildSolvedPiece(layout);
      final piece = PuzzlePiece.fromPieceState(pieceState);

      expect(pieceState.id, kSolvedPieceId);
      expect(pieceState.localCells.length, layout.occupiedCells.length);
      expect(pieceState.anchorRow, 0);
      expect(pieceState.anchorCol, 0);
      expect(pieceState.spawnAnchorRow, 0);
      expect(pieceState.spawnAnchorCol, 0);

      final occupied = piece.getOccupiedCells().toSet();
      final expected = layout.occupiedCells
          .map(
            (cell) => BoardCellPosition(row: cell.row, col: cell.col),
          )
          .toSet();

      expect(occupied, expected);
    });

    test('uses normalized local offsets from layout min row/col', () {
      final layouts = generator.generateAllLayouts(['CAT', 'CAR']);
      expect(layouts, isNotEmpty);

      final layout = layouts.first;
      final pieceState = buildSolvedPiece(layout);

      for (final localCell in pieceState.localCells) {
        expect(localCell.rowOffset, greaterThanOrEqualTo(0));
        expect(localCell.colOffset, greaterThanOrEqualTo(0));
      }
    });
  });
}
