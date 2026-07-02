import 'package:flutter/material.dart';

import '../../../../core/theme/puzzle_theme.dart';

class PuzzleBoardContainer extends StatelessWidget {
  const PuzzleBoardContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: PuzzleTheme.boardBg,
          borderRadius: BorderRadius.circular(PuzzleTheme.boardRadius),
          boxShadow: PuzzleTheme.boardShadow,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PuzzleTheme.boardRadius - 2),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ),
      ),
    );
  }
}
