import 'package:flutter/material.dart';

import '../../../../core/theme/puzzle_theme.dart';
import 'how_to_play_steps.dart';

class HowToPlayStepCard extends StatelessWidget {
  const HowToPlayStepCard({
    super.key,
    required this.step,
    required this.isActive,
  });

  final HowToPlayStep step;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: step.demoBuilder(isActive: isActive),
        ),
        const SizedBox(height: 10),
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: PuzzleTheme.darkGreen,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PuzzleTheme.darkGreen.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
