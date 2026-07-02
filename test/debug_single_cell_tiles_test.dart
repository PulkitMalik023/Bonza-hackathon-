import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/constants/board_constants.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/board_occupancy.dart';
import 'package:jam_pro/features/puzzle/domain/debug_tile_drop_evaluator.dart';
import 'package:jam_pro/features/puzzle/domain/grid_layout.dart';
import 'package:jam_pro/features/puzzle/presentation/debug_tile_spawner.dart';

void main() {
  group('nearestBoardCellFromCenter', () {
    late GridLayout gridLayout;

    setUp(() {
      gridLayout = GridLayout.fromBoardSize(
        boardSize: const Size(480, 480),
        tileSize: BoardConstants.kBoardTileSize,
      );
    });

    test('picks cell (0, 0) for center near top-left', () {
      final cell = gridLayout.nearestBoardCellFromCenter(
        const Offset(24, 24),
        boardRows: 5,
        boardCols: 5,
      );

      expect(cell.row, 0);
      expect(cell.col, 0);
    });

    test('picks cell (1, 2) for center in that cell', () {
      final tileSize = BoardConstants.kBoardTileSize;
      final cell = gridLayout.nearestBoardCellFromCenter(
        Offset(2.5 * tileSize, 1.5 * tileSize),
        boardRows: 5,
        boardCols: 5,
      );

      expect(cell.row, 1);
      expect(cell.col, 2);
    });

    test('picks nearest cell when center is between cells', () {
      final tileSize = BoardConstants.kBoardTileSize;
      final cell = gridLayout.nearestBoardCellFromCenter(
        Offset(1.4 * tileSize, 0.6 * tileSize),
        boardRows: 5,
        boardCols: 5,
      );

      expect(cell.row, 0);
      expect(cell.col, 1);
    });
  });

  group('BoardOccupancy', () {
    test('rejects double-booking the same cell', () {
      final occupancy = BoardOccupancy();

      occupancy.occupy(0, 0, 'tile_a');
      expect(occupancy.isFree(0, 0), isFalse);
      expect(occupancy.isFree(0, 0, exceptTileId: 'tile_a'), isTrue);
      expect(occupancy.isFree(0, 0, exceptTileId: 'tile_b'), isFalse);

      occupancy.occupy(1, 1, 'tile_b');
      expect(occupancy.isFree(1, 1), isFalse);
      expect(occupancy.isFree(2, 2), isTrue);
    });

    test('clearTile removes occupant', () {
      final occupancy = BoardOccupancy();
      occupancy.occupy(0, 0, 'tile_a');
      occupancy.clearTile('tile_a');

      expect(occupancy.isFree(0, 0), isTrue);
    });

    test('rebuildFromTiles syncs map from snapped tiles', () {
      final occupancy = BoardOccupancy();
      occupancy.occupy(0, 0, 'old');

      occupancy.rebuildFromTiles([
        (id: 'tile_1', row: 1, col: 2),
        (id: 'tile_2', row: null, col: null),
      ]);

      expect(occupancy.isFree(0, 0), isTrue);
      expect(occupancy.isFree(1, 2), isFalse);
      expect(
        occupancy.snapshot()[const BoardCellPosition(row: 1, col: 2)],
        'tile_1',
      );
    });

    test('isOccupiedByAnotherTile ignores same tile id', () {
      final occupancy = BoardOccupancy();
      occupancy.occupy(0, 0, 'tile_a');

      expect(occupancy.isOccupiedByAnotherTile(0, 0, 'tile_a'), isFalse);
      expect(occupancy.isOccupiedByAnotherTile(0, 0, 'tile_b'), isTrue);
      expect(occupancy.isOccupiedByAnotherTile(1, 0, 'tile_a'), isFalse);
    });
  });

  group('DebugTileDropEvaluator', () {
    const boardRows = 5;
    const boardCols = 5;
    const tileSize = BoardConstants.kBoardTileSize;

    test('accepts snap when center is over empty cell', () {
      final occupancy = BoardOccupancy();
      final topLeft = Offset(2 * tileSize, 1 * tileSize);

      final result = evaluateDrop(
        droppedTopLeft: topLeft,
        tileId: 'tile_1',
        occupancy: occupancy,
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(result.action, DebugTileDropAction.snap);
      expect(result.targetCell, const BoardCellPosition(row: 1, col: 2));
      expect(result.overlapsBoard, isTrue);
      expect(result.insideBoard, isTrue);
      expect(result.occupied, isFalse);
    });

    test('rejects when target cell is occupied by another tile', () {
      final occupancy = BoardOccupancy()..occupy(1, 2, 'tile_other');
      final topLeft = Offset(2 * tileSize, 1 * tileSize);

      final result = evaluateDrop(
        droppedTopLeft: topLeft,
        tileId: 'tile_1',
        occupancy: occupancy,
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(result.action, DebugTileDropAction.returnToOrigin);
      expect(result.occupied, isTrue);
    });

    test('rejects when tile is fully in tray with no board overlap', () {
      final occupancy = BoardOccupancy();
      final topLeft = Offset(2 * tileSize, boardRows * tileSize + tileSize);

      final result = evaluateDrop(
        droppedTopLeft: topLeft,
        tileId: 'tile_1',
        occupancy: occupancy,
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(result.action, DebugTileDropAction.returnToOrigin);
      expect(result.overlapsBoard, isFalse);
      expect(result.targetCell, isNull);
    });

    test('accepts snap when tile overlaps board but center is below board', () {
      final occupancy = BoardOccupancy();
      // Bottom row top-left with center below board rect.
      final topLeft = Offset(2 * tileSize, (boardRows - 1) * tileSize + tileSize * 0.6);

      final result = evaluateDrop(
        droppedTopLeft: topLeft,
        tileId: 'tile_1',
        occupancy: occupancy,
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(result.overlapsBoard, isTrue);
      expect(result.action, DebugTileDropAction.snap);
      expect(result.targetCell, BoardCellPosition(row: boardRows - 1, col: 2));
    });

    test('tileOverlapsBoard detects partial overlap at board edge', () {
      final topLeft = Offset(2 * tileSize, (boardRows - 1) * tileSize + tileSize * 0.6);

      expect(
        tileOverlapsBoard(
          topLeft,
          boardRows: boardRows,
          boardCols: boardCols,
          tileSize: tileSize,
        ),
        isTrue,
      );
      expect(
        tileOverlapsBoard(
          Offset(2 * tileSize, boardRows * tileSize + 4),
          boardRows: boardRows,
          boardCols: boardCols,
          tileSize: tileSize,
        ),
        isFalse,
      );
    });

    test('clearing tile snap before drop allows re-placement', () {
      final occupancy = BoardOccupancy()..occupy(0, 0, 'tile_1');
      occupancy.clearTile('tile_1');

      final topLeft = Offset.zero;
      final result = evaluateDrop(
        droppedTopLeft: topLeft,
        tileId: 'tile_1',
        occupancy: occupancy,
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(result.action, DebugTileDropAction.snap);
      expect(result.targetCell, const BoardCellPosition(row: 0, col: 0));
    });

    test('snapTopLeftForCell aligns to grid', () {
      final topLeft = snapTopLeftForCell(
        const BoardCellPosition(row: 2, col: 3),
        tileSize,
      );

      expect(topLeft.dx % tileSize, 0);
      expect(topLeft.dy % tileSize, 0);
      expect(topLeft, Offset(3 * tileSize, 2 * tileSize));
    });
  });

  group('spawnDebugTiles', () {
    test('produces 10 tiles within canvas bounds', () {
      const boardRows = 5;
      const boardCols = 7;
      const tileSize = BoardConstants.kBoardTileSize;
      final canvas = debugCanvasSize(
        boardRows: boardRows,
        boardCols: boardCols,
      );
      final tiles = spawnDebugTiles(
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(tiles.length, 10);

      final maxX = (canvas.canvasCols - 1) * tileSize;
      final maxY = (canvas.canvasRows - 1) * tileSize;

      for (final tile in tiles) {
        expect(tile.position.dx, greaterThanOrEqualTo(0));
        expect(tile.position.dy, greaterThanOrEqualTo(0));
        expect(tile.position.dx, lessThanOrEqualTo(maxX));
        expect(tile.position.dy, lessThanOrEqualTo(maxY));
        expect(tile.position.dx % tileSize, 0);
        expect(tile.position.dy % tileSize, 0);
      }
    });

    test('labels tiles 1 through 10', () {
      final tiles = spawnDebugTiles(
        boardRows: 4,
        boardCols: 6,
        tileSize: BoardConstants.kBoardTileSize,
      );

      expect(tiles.map((t) => t.label).toList(), [
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '10',
      ]);
    });
  });
}
