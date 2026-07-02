import 'package:flutter/material.dart';

import '../../../../core/constants/puzzle_assets.dart';
import '../../../../core/constants/puzzle_ui_flags.dart';
import '../../../../core/theme/puzzle_theme.dart';
import '../../../../core/widgets/asset_icon.dart';
import 'puzzle_coin_pill.dart';

class PuzzleTopHeader extends StatelessWidget {
  const PuzzleTopHeader({
    super.key,
    required this.title,
    required this.coinBalance,
    required this.onBack,
    this.onAddCoins,
  });

  final String title;
  final int coinBalance;
  final VoidCallback onBack;
  final VoidCallback? onAddCoins;

  @override
  Widget build(BuildContext context) {
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
              _BackButton(onPressed: onBack),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.eco, color: PuzzleTheme.lightGreen, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title.toUpperCase(),
                        style: PuzzleTheme.headerTitleStyle(
                          MediaQuery.sizeOf(context).width,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.eco, color: PuzzleTheme.lightGreen, size: 16),
                  ],
                ),
              ),
              PuzzleCoinPill(
                coinBalance: coinBalance,
                onAddPressed: onAddCoins,
                showAddBadge: kShowCoinAddBadge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PuzzleTheme.mediumGreen,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: AssetIcon(
              assetPath: PuzzleAssets.back,
              fallbackIcon: Icons.arrow_back_rounded,
              size: 22,
              color: PuzzleTheme.yellow,
            ),
          ),
        ),
      ),
    );
  }
}
