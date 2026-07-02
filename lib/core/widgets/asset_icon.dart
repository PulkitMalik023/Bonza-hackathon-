import 'package:flutter/material.dart';

class AssetIcon extends StatelessWidget {
  const AssetIcon({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    this.size = 24,
    this.color,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          fallbackIcon,
          size: size,
          color: color,
        );
      },
    );
  }
}
