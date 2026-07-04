import 'package:flutter/material.dart';

import '../../../../core/theme/puzzle_theme.dart';
import '../../domain/piece_cell.dart';
import 'puzzle_tile_edge_mask.dart';

class PuzzleCompletedGroupSeams extends StatelessWidget {
  const PuzzleCompletedGroupSeams({
    super.key,
    required this.cells,
    required this.tileSize,
    this.connectionSeamOpacity = 1,
  });

  final Iterable<PieceCell> cells;
  final double tileSize;
  final double connectionSeamOpacity;

  @override
  Widget build(BuildContext context) {
    if (connectionSeamOpacity <= 0) {
      return const SizedBox.shrink();
    }

    final cellList = cells.toList();
    if (cellList.isEmpty) {
      return const SizedBox.shrink();
    }

    final occupiedOffsets = occupiedOffsetsFromCells(
      cells: cellList.map(
        (cell) => (rowOffset: cell.rowOffset, colOffset: cell.colOffset),
      ),
    );

    final lineWidth = (tileSize * 0.04).clamp(1.5, 3.0);
    final seamColor = PuzzleTheme.lightGreen.withValues(alpha: 0.85);
    final seamWidgets = <Widget>[];

    for (final cell in cellList) {
      final row = cell.rowOffset;
      final col = cell.colOffset;

      if (occupiedOffsets.contains((row, col + 1))) {
        seamWidgets.add(
          Positioned(
            left: (col + 1) * tileSize - lineWidth / 2,
            top: row * tileSize,
            width: lineWidth,
            height: tileSize,
            child: ColoredBox(color: seamColor),
          ),
        );
      }

      if (occupiedOffsets.contains((row + 1, col))) {
        seamWidgets.add(
          Positioned(
            left: col * tileSize,
            top: (row + 1) * tileSize - lineWidth / 2,
            width: tileSize,
            height: lineWidth,
            child: ColoredBox(color: seamColor),
          ),
        );
      }
    }

    return IgnorePointer(
      child: Opacity(
        opacity: connectionSeamOpacity.clamp(0, 1),
        child: Stack(
          clipBehavior: Clip.none,
          children: seamWidgets,
        ),
      ),
    );
  }
}
