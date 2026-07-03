import 'package:flutter/material.dart';

import '../../../../core/theme/puzzle_theme.dart';
import '../../../../core/widgets/settings_icon_button.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.onSettingsPressed,
  });

  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: PuzzleTheme.headerGradient,
          borderRadius: BorderRadius.circular(PuzzleTheme.headerRadius),
          boxShadow: PuzzleTheme.headerShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.eco, color: PuzzleTheme.lightGreen, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'JAM PRO',
                        style: PuzzleTheme.displayTitleStyle(width),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.eco, color: PuzzleTheme.lightGreen, size: 18),
                  ],
                ),
              ),
              SettingsIconButton(onPressed: onSettingsPressed),
            ],
          ),
        ),
      ),
    );
  }
}
