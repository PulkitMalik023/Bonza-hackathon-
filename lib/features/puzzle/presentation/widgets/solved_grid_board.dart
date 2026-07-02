import 'package:flutter/material.dart';

import '../../../../core/constants/board_constants.dart';
import '../../data/models/generated_puzzle_layout.dart';
import 'puzzle_node_tile.dart';

class SolvedGridBoard extends StatelessWidget {
  const SolvedGridBoard({
    super.key,
    required this.layout,
    this.tileSize = BoardConstants.kBoardTileSize,
  });

  final GeneratedPuzzleLayout layout;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    final rowCount = layout.maxRow - layout.minRow + 1;
    final colCount = layout.maxCol - layout.minCol + 1;
    final width = colCount * tileSize;
    final height = rowCount * tileSize;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final cell in layout.occupiedCells)
            Positioned(
              left: (cell.col - layout.minCol) * tileSize,
              top: (cell.row - layout.minRow) * tileSize,
              child: PuzzleNodeTile(
                character: cell.letter,
                tileSize: tileSize,
              ),
            ),
        ],
      ),
    );
  }
}
