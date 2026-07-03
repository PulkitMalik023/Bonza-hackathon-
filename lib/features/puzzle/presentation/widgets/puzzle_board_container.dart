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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PuzzleTheme.boardBg,
      ),
      child: child,
    );
  }
}
