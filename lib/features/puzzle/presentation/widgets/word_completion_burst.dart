import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/puzzle_theme.dart';

class WordCompletionBurst extends StatefulWidget {
  const WordCompletionBurst({
    super.key,
    required this.width,
    required this.height,
    this.onComplete,
  });

  final double width;
  final double height;
  final VoidCallback? onComplete;

  @override
  State<WordCompletionBurst> createState() => _WordCompletionBurstState();
}

class _BurstParticle {
  const _BurstParticle({
    required this.angle,
    required this.color,
    required this.size,
  });

  final double angle;
  final Color color;
  final double size;
}

class _WordCompletionBurstState extends State<WordCompletionBurst>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 450);
  static const _particleCount = 12;

  late final AnimationController _controller;
  late final List<_BurstParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    final random = Random(widget.width.hashCode + widget.height.hashCode);
    _particles = List.generate(_particleCount, (index) {
      final angle = random.nextDouble() * 2 * pi;
      final color = index.isEven ? PuzzleTheme.lightGreen : PuzzleTheme.yellow;
      final size = 2 + random.nextDouble() * 2;
      return _BurstParticle(angle: angle, color: color, size: size);
    });
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxRadius = max(widget.width, widget.height) * 0.55;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = Curves.easeOut.transform(_controller.value);
        final opacity = (1 - progress).clamp(0.0, 1.0);

        return IgnorePointer(
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final particle in _particles)
                  Positioned(
                    left: widget.width / 2 +
                        cos(particle.angle) * maxRadius * progress -
                        particle.size / 2,
                    top: widget.height / 2 +
                        sin(particle.angle) * maxRadius * progress -
                        particle.size / 2,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: particle.size,
                        height: particle.size,
                        decoration: BoxDecoration(
                          color: particle.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
