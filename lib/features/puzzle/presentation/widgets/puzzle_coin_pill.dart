import 'package:flutter/material.dart';

import '../../../../core/constants/puzzle_assets.dart';
import '../../../../core/theme/puzzle_theme.dart';
import '../../../../core/widgets/asset_icon.dart';

class PuzzleCoinPill extends StatelessWidget {
  const PuzzleCoinPill({
    super.key,
    required this.coinBalance,
  });

  final int coinBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        ],
      ),
    );
  }
}
