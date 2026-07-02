import 'package:flutter/material.dart';

import '../../../../core/constants/puzzle_assets.dart';
import '../../../../core/theme/puzzle_theme.dart';
import '../../../../core/widgets/asset_icon.dart';

class PuzzleCoinPill extends StatelessWidget {
  const PuzzleCoinPill({
    super.key,
    required this.coinBalance,
    this.onAddPressed,
    this.showAddBadge = false,
  });

  final int coinBalance;
  final VoidCallback? onAddPressed;
  final bool showAddBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: PuzzleTheme.darkGreen.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PuzzleTheme.mediumGreen),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AssetIcon(
            assetPath: PuzzleAssets.coin,
            fallbackIcon: Icons.monetization_on_rounded,
            size: 22,
            color: PuzzleTheme.yellow,
          ),
          const SizedBox(width: 4),
          Text(
            '$coinBalance',
            style: const TextStyle(
              color: PuzzleTheme.coinText,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: PuzzleTheme.lightGreen,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onAddPressed,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: AssetIcon(
                        assetPath: PuzzleAssets.add,
                        fallbackIcon: Icons.add_rounded,
                        size: 18,
                        color: PuzzleTheme.darkGreen,
                      ),
                    ),
                  ),
                ),
              ),
              if (showAddBadge)
                const Positioned(
                  top: -4,
                  right: -4,
                  child: _Badge(label: '1'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: PuzzleTheme.badgeRed,
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
