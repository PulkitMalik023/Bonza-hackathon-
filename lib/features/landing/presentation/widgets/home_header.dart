import 'package:flutter/material.dart';

import '../../../../core/audio/ui_button_sound.dart';
import '../../../../core/constants/home_assets.dart';
import '../../../../core/theme/puzzle_theme.dart';
import '../../../../core/widgets/asset_icon.dart';
import '../../../puzzle/presentation/widgets/puzzle_coin_pill.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.coinBalance,
    this.onSettingsPressed,
  });

  final int coinBalance;
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
              _SettingsButton(onPressed: onSettingsPressed),
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
              PuzzleCoinPill(coinBalance: coinBalance),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PuzzleTheme.mediumGreen,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: withButtonTap(onPressed),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: AssetIcon(
              assetPath: HomeAssets.settings,
              fallbackIcon: Icons.settings_rounded,
              size: 22,
              color: PuzzleTheme.yellow,
            ),
          ),
        ),
      ),
    );
  }
}
