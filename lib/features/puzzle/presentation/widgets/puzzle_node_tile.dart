import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PuzzleNodeTile extends StatelessWidget {
  const PuzzleNodeTile({
    super.key,
    required this.character,
    required this.tileSize,
    this.isDragging = false,
    this.showBorder = true,
  });

  final String character;
  final double tileSize;
  final bool isDragging;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final tile = SizedBox(
      width: tileSize,
      height: tileSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.nodeBackgroundColor,
          border: showBorder
              ? Border.all(
                  color: AppTheme.nodeBorderColor,
                  width: 1,
                )
              : null,
          boxShadow: isDragging
              ? const [
                  BoxShadow(
                    color: AppTheme.nodeDragShadowColor,
                    blurRadius: AppTheme.nodeDragShadowBlurRadius,
                    offset: AppTheme.nodeDragShadowOffset,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            character,
            style: TextStyle(
              color: AppTheme.nodeTextColor,
              fontSize: tileSize * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    if (!isDragging) {
      return tile;
    }

    return Transform.scale(
      scale: AppTheme.nodeDragScale,
      child: tile,
    );
  }
}
