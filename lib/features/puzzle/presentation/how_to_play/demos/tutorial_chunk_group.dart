import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../../core/theme/puzzle_theme.dart';
import '../../widgets/puzzle_node_tile.dart';

class TutorialCell {
  const TutorialCell({
    required this.letter,
    required this.col,
    required this.row,
  });

  final String letter;
  final int col;
  final int row;
}

class TutorialChunkGroup extends StatelessWidget {
  const TutorialChunkGroup({
    super.key,
    required this.cells,
    required this.tileSize,
    this.offset = Offset.zero,
    this.scale = 1,
    this.glow = false,
    this.wordGlow = false,
    this.isCompleted = false,
    this.isDragging = false,
    this.opacity = 1,
  });

  final List<TutorialCell> cells;
  final double tileSize;
  final Offset offset;
  final double scale;
  final bool glow;
  final bool wordGlow;
  final bool isCompleted;
  final bool isDragging;
  final double opacity;

  ({int maxCol, int maxRow}) _bounds() {
    var maxCol = 0;
    var maxRow = 0;
    for (final cell in cells) {
      maxCol = max(maxCol, cell.col);
      maxRow = max(maxRow, cell.row);
    }
    return (maxCol: maxCol, maxRow: maxRow);
  }

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return const SizedBox.shrink();
    }

    final bounds = _bounds();
    final width = (bounds.maxCol + 1) * tileSize;
    final height = (bounds.maxRow + 1) * tileSize;
    final showGlow = glow || wordGlow;

    Widget content = SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showGlow && wordGlow)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(PuzzleTheme.tileRadius + 2),
                    border: Border.all(
                      color: PuzzleTheme.lightGreen.withValues(alpha: 0.85),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PuzzleTheme.lightGreen.withValues(alpha: 0.45),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          for (final cell in cells)
            Positioned(
              left: cell.col * tileSize,
              top: cell.row * tileSize,
              child: PuzzleNodeTile(
                character: cell.letter,
                tileSize: tileSize,
                isDragging: isDragging,
                isCompleted: isCompleted || showGlow,
                showBorder: true,
              ),
            ),
          if (showGlow && !wordGlow)
            for (final cell in cells)
              Positioned(
                left: cell.col * tileSize - 2,
                top: cell.row * tileSize - 2,
                child: IgnorePointer(
                  child: Container(
                    width: tileSize + 4,
                    height: tileSize + 4,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(PuzzleTheme.tileRadius + 2),
                      border: Border.all(
                        color: PuzzleTheme.lightGreen.withValues(alpha: 0.85),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: PuzzleTheme.lightGreen.withValues(alpha: 0.45),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );

    if (scale != 1) {
      content = Transform.scale(
        scale: scale,
        alignment: Alignment.topLeft,
        child: content,
      );
    }

    return Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: content,
      ),
    );
  }
}
