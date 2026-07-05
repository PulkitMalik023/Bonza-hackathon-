import 'package:flutter/material.dart';

import '../../../../core/audio/ui_button_sound.dart';
import '../../../../core/constants/home_assets.dart';
import '../../../../core/theme/puzzle_theme.dart';
import '../../../../core/widgets/asset_icon.dart';

class HomeLevelCard extends StatelessWidget {
  const HomeLevelCard({
    super.key,
    required this.levelNumber,
    required this.category,
    required this.onTap,
  });

  final int levelNumber;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: withButtonTap(onTap),
        borderRadius: BorderRadius.circular(PuzzleTheme.levelCardRadius),
        child: Ink(
          decoration: BoxDecoration(
            gradient: PuzzleTheme.levelCardGradient,
            borderRadius: BorderRadius.circular(PuzzleTheme.levelCardRadius),
            boxShadow: PuzzleTheme.levelCardShadow,
            border: Border.all(
              color: PuzzleTheme.mediumGreen.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                _LevelBadge(levelNumber: levelNumber),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    category,
                    style: PuzzleTheme.levelCardTitleStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _ArrowButton(onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.levelNumber});

  final int levelNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: PuzzleTheme.mediumGreen,
        shape: BoxShape.circle,
        boxShadow: PuzzleTheme.tileRestShadow,
        border: Border.all(
          color: PuzzleTheme.lightGreen.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$levelNumber',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PuzzleTheme.darkGreen,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: withButtonTap(onTap),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: AssetIcon(
              assetPath: HomeAssets.arrowRight,
              fallbackIcon: Icons.arrow_forward_rounded,
              size: 22,
              color: PuzzleTheme.yellow,
            ),
          ),
        ),
      ),
    );
  }
}
