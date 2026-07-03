import 'package:flutter/material.dart';

import '../../../../core/theme/puzzle_theme.dart';
import '../../domain/puzzle_piece.dart';
import 'puzzle_node_tile.dart';
import 'puzzle_tile_edge_mask.dart';

enum PuzzlePieceVisualMode { real, ghost }

class PuzzlePieceContent extends StatelessWidget {
  const PuzzlePieceContent({
    super.key,
    required this.piece,
    required this.tileSize,
    required this.pieceWidth,
    required this.pieceHeight,
    this.visualMode = PuzzlePieceVisualMode.real,
    this.isDragging = false,
    this.isCompleted = false,
    this.isHintHighlighted = false,
  });

  final PuzzlePiece piece;
  final double tileSize;
  final double pieceWidth;
  final double pieceHeight;
  final PuzzlePieceVisualMode visualMode;
  final bool isDragging;
  final bool isCompleted;
  final bool isHintHighlighted;

  @override
  Widget build(BuildContext context) {
    final isGhost = visualMode == PuzzlePieceVisualMode.ghost;
    final occupiedOffsets = occupiedOffsetsFromCells(
      cells: piece.cells.map(
        (cell) => (rowOffset: cell.rowOffset, colOffset: cell.colOffset),
      ),
    );
    final baseDepth = PuzzleTheme.tileBaseDepthFor(tileSize);

    return SizedBox(
      width: pieceWidth,
      height: pieceHeight + baseDepth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final cell in piece.cells)
            Positioned(
              left: cell.colOffset * tileSize,
              top: cell.rowOffset * tileSize,
              child: PuzzleNodeTile(
                character: cell.letter,
                tileSize: tileSize,
                isDragging: isDragging && !isGhost,
                showBorder: isGhost || isDragging || !isCompleted,
                isCompleted: isCompleted && !isGhost,
                isHintHighlighted: isHintHighlighted && !isGhost,
                isGhost: isGhost,
                edgeMask: edgeMaskForCell(
                  rowOffset: cell.rowOffset,
                  colOffset: cell.colOffset,
                  occupiedOffsets: occupiedOffsets,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
