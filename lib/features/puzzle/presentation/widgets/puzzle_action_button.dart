import 'package:flutter/material.dart';

import '../../../../core/audio/ui_button_sound.dart';
import '../../../../core/theme/puzzle_theme.dart';
import '../../../../core/widgets/asset_icon.dart';

class PuzzleActionButton extends StatelessWidget {
  const PuzzleActionButton({
    super.key,
    required this.label,
    required this.assetPath,
    required this.fallbackIcon,
    required this.onPressed,
    this.showBadge = false,
  });

  final String label;
  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback? onPressed;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: enabled
                  ? PuzzleTheme.lightGreen
                  : PuzzleTheme.lightGreen.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              elevation: enabled ? 4 : 0,
              child: InkWell(
                onTap: withButtonTap(onPressed),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: PuzzleTheme.actionButtonSize,
                  height: PuzzleTheme.actionButtonSize,
                  child: Center(
                    child: AssetIcon(
                      assetPath: assetPath,
                      fallbackIcon: fallbackIcon,
                      size: 26,
                      color: PuzzleTheme.darkGreen,
                    ),
                  ),
                ),
              ),
            ),
            if (showBadge && enabled)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: PuzzleTheme.badgeRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: PuzzleTheme.actionLabelStyle.copyWith(
            color: enabled
                ? PuzzleTheme.darkGreen
                : PuzzleTheme.darkGreen.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}
