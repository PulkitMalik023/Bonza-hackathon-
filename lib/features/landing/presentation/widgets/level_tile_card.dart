import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LevelTileCard extends StatelessWidget {
  const LevelTileCard({
    super.key,
    required this.label,
    required this.onTap,
    this.width,
    this.height = 56,
  });

  final String label;
  final VoidCallback onTap;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tileWidth = width ?? screenWidth * 0.75;

    return Material(
      color: AppTheme.nodeBackgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: tileWidth,
          height: height,
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
