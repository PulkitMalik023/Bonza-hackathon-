import 'package:flutter/material.dart';

class TutorialHandPointer extends StatelessWidget {
  const TutorialHandPointer({
    super.key,
    required this.position,
    required this.opacity,
    this.scale = 1,
  });

  final Offset position;
  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform.scale(
            scale: scale,
            child: const Icon(
              Icons.touch_app_rounded,
              size: 32,
              color: Color(0xCCFFFFFF),
              shadows: [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
