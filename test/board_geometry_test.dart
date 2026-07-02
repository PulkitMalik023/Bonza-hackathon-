import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/constants/board_constants.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/board_geometry.dart';

void main() {
  const cellSize = BoardConstants.kBoardTileSize;

  group('BoardGeometry', () {
    test('boardCellTopLeft maps row/col to pixel offsets from origin', () {
      const geometry = BoardGeometry(
        boardCellSize: cellSize,
        boardRows: 3,
        boardCols: 4,
        origin: Offset(96, 48),
      );

      expect(
        geometry.boardCellTopLeft(const BoardCellPosition(row: 0, col: 0)),
        const Offset(96, 48),
      );
      expect(
        geometry.boardCellTopLeft(const BoardCellPosition(row: 1, col: 2)),
        Offset(96 + 2 * cellSize, 48 + cellSize),
      );
    });

    test('boardCellRect uses boardCellSize for width and height', () {
      final geometry = BoardGeometry.local(
        boardRows: 2,
        boardCols: 2,
        boardCellSize: cellSize,
      );

      final rect = geometry.boardCellRect(
        const BoardCellPosition(row: 1, col: 1),
      );

      expect(rect.width, cellSize);
      expect(rect.height, cellSize);
      expect(rect.topLeft, Offset(cellSize, cellSize));
    });

    test('boardCellCenter is rect center', () {
      final geometry = BoardGeometry.local(
        boardRows: 2,
        boardCols: 2,
        boardCellSize: cellSize,
      );

      final center = geometry.boardCellCenter(
        const BoardCellPosition(row: 0, col: 1),
      );

      expect(center, Offset(1.5 * cellSize, 0.5 * cellSize));
    });

    test('boardPixelSize matches row/col count times cell size', () {
      final geometry = BoardGeometry.local(
        boardRows: 3,
        boardCols: 5,
        boardCellSize: cellSize,
      );

      expect(geometry.boardPixelSize, Size(5 * cellSize, 3 * cellSize));
    });

    test('fromLayoutBounds computes dimensions from layout bounds', () {
      final geometry = BoardGeometry.fromLayoutBounds(
        minRow: 0,
        maxRow: 2,
        minCol: 0,
        maxCol: 3,
        origin: Offset.zero,
      );

      expect(geometry.boardRows, 3);
      expect(geometry.boardCols, 4);
    });
  });
}
