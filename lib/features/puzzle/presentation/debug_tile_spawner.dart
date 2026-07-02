import 'dart:math';
import 'dart:ui';

import '../domain/debug_draggable_tile.dart';

/// Spawns [count] single-cell debug tiles in a tray below the board.
List<DebugDraggableTile> spawnDebugTiles({
  required int boardRows,
  required int boardCols,
  required double tileSize,
  int count = 10,
}) {
  final trayStartRow = boardRows + 2;
  final trayCols = const [0, 2, 4, 6, 8];
  final tiles = <DebugDraggableTile>[];

  for (var i = 0; i < count; i++) {
    final trayRowIndex = i ~/ 5;
    final trayColIndex = i % 5;
    final row = trayStartRow + trayRowIndex * 2;
    final col = trayCols[trayColIndex];
    final position = Offset(col * tileSize, row * tileSize);

    tiles.add(
      DebugDraggableTile.spawn(
        id: 'debug_tile_${i + 1}',
        position: position,
        label: '${i + 1}',
      ),
    );
  }

  return tiles;
}

/// Canvas dimensions for debug single-cell tile mode.
({int canvasRows, int canvasCols}) debugCanvasSize({
  required int boardRows,
  required int boardCols,
}) {
  return (
    canvasCols: max(boardCols, 10),
    canvasRows: boardRows + 6,
  );
}
