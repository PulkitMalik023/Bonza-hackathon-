import 'package:flutter/material.dart';

import '../../../../core/constants/board_constants.dart';
import '../../../../core/theme/app_theme.dart';

class LevelButton extends StatelessWidget {
  const LevelButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tileWidth =
        MediaQuery.sizeOf(context).width * BoardConstants.kLevelButtonWidthFactor;

    return Material(
      color: AppTheme.nodeBackgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: tileWidth,
          height: BoardConstants.kLevelButtonHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.nodeBorderColor,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.nodeTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
