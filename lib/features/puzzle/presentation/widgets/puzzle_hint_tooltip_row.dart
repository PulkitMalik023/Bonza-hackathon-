import 'package:flutter/material.dart';

import '../../../../core/constants/puzzle_assets.dart';
import '../../../../core/theme/puzzle_theme.dart';
import '../../../../core/widgets/asset_icon.dart';

class PuzzleHintTooltipRow extends StatelessWidget {
  const PuzzleHintTooltipRow({
    super.key,
    required this.onHintPressed,
    this.hintText,
  });

  final VoidCallback onHintPressed;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _HintTooltip(text: hintText ?? 'Use a hint'),
          ),
          const SizedBox(width: 8),
          Material(
            color: PuzzleTheme.yellow,
            borderRadius: BorderRadius.circular(12),
            elevation: 3,
            child: InkWell(
              onTap: onHintPressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AssetIcon(
                      assetPath: PuzzleAssets.hintBulb,
                      fallbackIcon: Icons.lightbulb_rounded,
                      size: 20,
                      color: PuzzleTheme.hintButtonText,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'HINT',
                      style: TextStyle(
                        color: PuzzleTheme.hintButtonText,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintTooltip extends StatelessWidget {
  const _HintTooltip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TooltipPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 22, 10),
        child: Text(
          text,
          style: const TextStyle(
            color: PuzzleTheme.tooltipText,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TooltipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const radius = 10.0;
    const arrowWidth = 10.0;
    const arrowHeight = 12.0;

    final bodyWidth = size.width - arrowWidth;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bodyWidth, size.height),
      const Radius.circular(radius),
    );

    final fill = Paint()..color = PuzzleTheme.tooltipBg;
    final shadow = Paint()
      ..color = const Color(0x22000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRRect(rect.shift(const Offset(0, 2)), shadow);
    canvas.drawRRect(rect, fill);

    final arrowPath = Path()
      ..moveTo(bodyWidth, size.height * 0.5 - arrowHeight * 0.5)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(bodyWidth, size.height * 0.5 + arrowHeight * 0.5)
      ..close();

    canvas.drawPath(arrowPath.shift(const Offset(0, 2)), shadow);
    canvas.drawPath(arrowPath, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
