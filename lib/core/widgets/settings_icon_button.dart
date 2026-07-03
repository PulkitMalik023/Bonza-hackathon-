import 'package:flutter/material.dart';

import '../audio/ui_button_sound.dart';
import '../constants/home_assets.dart';
import '../theme/puzzle_theme.dart';
import 'asset_icon.dart';

class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({super.key, this.onPressed});

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
