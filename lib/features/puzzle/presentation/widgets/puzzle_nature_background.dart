import 'package:flutter/material.dart';

import '../../../../core/theme/puzzle_theme.dart';

class PuzzleNatureBackground extends StatelessWidget {
  const PuzzleNatureBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: PuzzleTheme.natureBackgroundGradient,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: _softOrb(120, const Color(0x33FFFFFF)),
          ),
          Positioned(
            bottom: 80,
            left: -30,
            child: _softOrb(160, const Color(0x22FFFFFF)),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00A5D6A7),
                    Color(0x6681C784),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _softOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
