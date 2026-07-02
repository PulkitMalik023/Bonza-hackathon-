import 'package:flutter/material.dart';

import '../../../../core/constants/board_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/puzzle_layout.dart';

class TargetBoardGrid extends StatelessWidget {
  const TargetBoardGrid({
    super.key,
    required this.layout,
    this.tileSize = BoardConstants.kBoardTileSize,
    this.showFullBoundingGrid = false,
  });

  final PuzzleLayout layout;
  final double tileSize;
  final bool showFullBoundingGrid;

  @override
  Widget build(BuildContext context) {
    final rowCount = layout.maxRow - layout.minRow + 1;
    final colCount = layout.maxCol - layout.minCol + 1;
    final width = colCount * tileSize;
    final height = rowCount * tileSize;

    final cells = showFullBoundingGrid
        ? [
            for (var row = 0; row < rowCount; row++)
              for (var col = 0; col < colCount; col++) (row: row, col: col),
          ]
        : layout.occupiedCells
            .map(
              (cell) => (
                row: cell.row - layout.minRow,
                col: cell.col - layout.minCol,
              ),
            )
            .toList();

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final cell in cells)
            Positioned(
              left: cell.col * tileSize,
              top: cell.row * tileSize,
              child: SizedBox(
                width: tileSize,
                height: tileSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.nodeBorderColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
