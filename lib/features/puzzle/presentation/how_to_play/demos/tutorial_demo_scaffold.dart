import 'package:flutter/material.dart';

import '../../../../../core/constants/board_constants.dart';
import '../../../../../core/theme/puzzle_theme.dart';

class TutorialDemoScaffold extends StatelessWidget {
  const TutorialDemoScaffold({
    super.key,
    required this.child,
    this.height = 175,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: PuzzleTheme.boardBg,
            border: Border.all(
              color: const Color(0xFFDCE8DC),
              width: 1,
            ),
          ),
          child: CustomPaint(
            painter: _TutorialGridPainter(),
            child: ClipRect(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 36.0;
    final paint = Paint()
      ..color = const Color(0xFFDCE8DC)
      ..strokeWidth = BoardConstants.kBoardGridLineWidth;

    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
