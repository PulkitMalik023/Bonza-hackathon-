import 'package:flutter/material.dart';

import '../../../../core/audio/ui_button_sound.dart';
import '../../../../core/theme/puzzle_theme.dart';

class HowToPlayButton extends StatelessWidget {
  const HowToPlayButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PuzzleTheme.mediumGreen,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: withButtonTap(onPressed),
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Icon(
              Icons.help_outline_rounded,
              color: PuzzleTheme.yellow,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
