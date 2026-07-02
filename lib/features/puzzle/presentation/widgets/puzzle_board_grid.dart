import 'package:flutter/material.dart';

import '../../../../core/constants/board_constants.dart';
import '../../../../core/theme/puzzle_theme.dart';

class PuzzleBoardGrid extends StatelessWidget {
  const PuzzleBoardGrid({
    super.key,
    this.spacing = BoardConstants.kBoardTileSize,
    this.child,
  });

  final double spacing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _PuzzleBoardGridPainter(
            spacing: spacing,
            backgroundColor: PuzzleTheme.boardBg,
            lineColor: const Color(0xFFDCE8DC),
          ),
          child: child ?? SizedBox.expand(),
        );
      },
    );
  }
}

class _PuzzleBoardGridPainter extends CustomPainter {
  _PuzzleBoardGridPainter({
    required this.spacing,
    required this.backgroundColor,
    required this.lineColor,
  });

  final double spacing;
  final Color backgroundColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = BoardConstants.kBoardGridLineWidth;

    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PuzzleBoardGridPainter oldDelegate) {
    return oldDelegate.spacing != spacing ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.lineColor != lineColor;
  }
}
