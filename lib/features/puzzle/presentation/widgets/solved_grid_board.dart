import 'package:flutter/material.dart';

import '../../../../core/constants/board_constants.dart';
import '../../data/models/generated_puzzle_layout.dart';
import '../../data/models/grid_cell.dart' as puzzle;
import '../../domain/board_cell_position.dart';
import '../../domain/board_geometry.dart';
import 'puzzle_node_tile.dart';

class SolvedGridBoard extends StatelessWidget {
  const SolvedGridBoard({
    super.key,
    required this.layout,
    this.geometry,
  });

  final GeneratedPuzzleLayout layout;
  final BoardGeometry? geometry;

  @override
  Widget build(BuildContext context) {
    final rowCount = layout.maxRow - layout.minRow + 1;
    final colCount = layout.maxCol - layout.minCol + 1;
    final boardGeometry = geometry ??
        BoardGeometry.local(
          boardRows: rowCount,
          boardCols: colCount,
          boardCellSize: BoardConstants.kBoardTileSize,
        );

    return SizedBox(
      width: boardGeometry.boardPixelSize.width,
      height: boardGeometry.boardPixelSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final cell in layout.occupiedCells)
            _buildCellTile(boardGeometry, cell),
        ],
      ),
    );
  }

  Widget _buildCellTile(BoardGeometry boardGeometry, puzzle.GridCell cell) {
    final topLeft = boardGeometry.boardCellTopLeft(
      BoardCellPosition(
        row: cell.row - layout.minRow,
        col: cell.col - layout.minCol,
      ),
    );

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      child: PuzzleNodeTile(
        character: cell.letter,
        tileSize: boardGeometry.boardCellSize,
        showBorder: false,
      ),
    );
  }
}
