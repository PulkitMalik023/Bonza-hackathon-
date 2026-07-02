import 'dart:ui';

class GridCell {
  const GridCell({
    required this.row,
    required this.col,
    required this.center,
    required this.rect,
  });

  final int row;
  final int col;
  final Offset center;
  final Rect rect;
}

class GridLayout {
  GridLayout({
    required this.rows,
    required this.columns,
    required this.tileSize,
    required this.cells,
  });

  factory GridLayout.fromBoardSize({
    required Size boardSize,
    required double tileSize,
  }) {
    final rows = (boardSize.height / tileSize).ceil();
    final columns = (boardSize.width / tileSize).ceil();
    final cells = <List<GridCell>>[];

    for (var row = 0; row < rows; row++) {
      final rowCells = <GridCell>[];
      for (var col = 0; col < columns; col++) {
        final rect = Rect.fromLTWH(
          col * tileSize,
          row * tileSize,
          tileSize,
          tileSize,
        );
        rowCells.add(
          GridCell(
            row: row,
            col: col,
            center: rect.center,
            rect: rect,
          ),
        );
      }
      cells.add(rowCells);
    }

    return GridLayout(
      rows: rows,
      columns: columns,
      tileSize: tileSize,
      cells: cells,
    );
  }

  final int rows;
  final int columns;
  final double tileSize;
  final List<List<GridCell>> cells;

  Rect cellRect(int row, int col) => cells[row][col].rect;

  ({int row, int col}) snapCellFromTopLeft(Offset topLeft) {
    final col = (topLeft.dx / tileSize).round().clamp(0, columns - 1);
    final row = (topLeft.dy / tileSize).round().clamp(0, rows - 1);
    return (row: row, col: col);
  }

  ({int row, int col}) nearestBoardCellFromCenter(
    Offset center, {
    required int boardRows,
    required int boardCols,
  }) {
    var bestRow = 0;
    var bestCol = 0;
    var bestDistance = double.infinity;

    for (var row = 0; row < boardRows; row++) {
      for (var col = 0; col < boardCols; col++) {
        final cellCenter = cells[row][col].center;
        final distance = (cellCenter - center).distanceSquared;
        if (distance < bestDistance) {
          bestDistance = distance;
          bestRow = row;
          bestCol = col;
        }
      }
    }

    return (row: bestRow, col: bestCol);
  }
}
