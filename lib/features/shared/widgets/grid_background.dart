import 'package:flutter/material.dart';

import '../../../core/constants/board_constants.dart';
import '../../../core/theme/app_theme.dart';

class GridBackground extends StatelessWidget {
  const GridBackground({
    super.key,
    this.spacing = BoardConstants.kBoardTileSize,
    this.backgroundColor = AppTheme.gridBackgroundColor,
    this.lineColor = AppTheme.gridBackgroundLineColor,
    this.lineWidth = BoardConstants.kBoardGridLineWidth,
    this.child,
  });

  final double spacing;
  final Color backgroundColor;
  final Color lineColor;
  final double lineWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _GridBackgroundPainter(
            spacing: spacing,
            backgroundColor: backgroundColor,
            lineColor: lineColor,
            lineWidth: lineWidth,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
          child: child,
        );
      },
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  _GridBackgroundPainter({
    required this.spacing,
    required this.backgroundColor,
    required this.lineColor,
    required this.lineWidth,
  });

  final double spacing;
  final Color backgroundColor;
  final Color lineColor;
  final double lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth;

    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridBackgroundPainter oldDelegate) {
    return oldDelegate.spacing != spacing ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.lineWidth != lineWidth;
  }
}
