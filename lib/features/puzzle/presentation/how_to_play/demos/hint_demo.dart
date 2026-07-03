import 'package:flutter/material.dart';

import '../../../../../core/constants/puzzle_assets.dart';
import '../../../../../core/theme/puzzle_theme.dart';
import '../../../../../core/widgets/asset_icon.dart';
import 'tutorial_chunk_group.dart';
import 'tutorial_demo_scaffold.dart';
import 'tutorial_hand_pointer.dart';

const _kTileSize = 36.0;
const _kLoopDuration = Duration(milliseconds: 4500);

class HintDemo extends StatefulWidget {
  const HintDemo({super.key, required this.isActive});

  final bool isActive;

  @override
  State<HintDemo> createState() => _HintDemoState();
}

class _HintDemoState extends State<HintDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _hintButtonRect = Rect.fromLTWH(118, 12, 88, 34);
  static const _targetGlowOrigin = Offset(72, 108);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kLoopDuration)
      ..addStatusListener(_onStatus);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant HintDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncAnimation();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (!mounted) {
      return;
    }
    if (status == AnimationStatus.completed && widget.isActive) {
      _controller.forward(from: 0);
    }
  }

  void _syncAnimation() {
    if (widget.isActive) {
      if (!_controller.isAnimating) {
        _controller.forward(from: 0);
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  double _phase(double start, double end) {
    final t = _controller.value;
    if (t < start) {
      return 0;
    }
    if (t > end) {
      return 1;
    }
    return (t - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = _phase(0.08, 0.35);
        final tap = _phase(0.35, 0.48);
        final reveal = _phase(0.5, 0.88);

        final hintScale = 1 + 0.06 * (pulse < 0.5 ? pulse * 2 : (1 - pulse) * 2);
        final showGlow = reveal > 0.15;

        final handPos = Offset(
          _hintButtonRect.center.dx - 8,
          _hintButtonRect.center.dy - 4,
        );

        return TutorialDemoScaffold(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              TutorialChunkGroup(
                cells: const [
                  TutorialCell(letter: 'F', col: 0, row: 0),
                  TutorialCell(letter: 'O', col: 1, row: 0),
                  TutorialCell(letter: 'R', col: 2, row: 0),
                ],
                tileSize: _kTileSize,
                offset: const Offset(72, 72),
              ),
              TutorialChunkGroup(
                cells: const [
                  TutorialCell(letter: 'K', col: 0, row: 0),
                ],
                tileSize: _kTileSize,
                offset: _targetGlowOrigin,
                glow: showGlow,
                opacity: showGlow ? 1 : 0.35,
              ),
              Positioned(
                left: _hintButtonRect.left,
                top: _hintButtonRect.top,
                child: Transform.scale(
                  scale: hintScale,
                  child: Material(
                    color: PuzzleTheme.yellow,
                    borderRadius: BorderRadius.circular(12),
                    elevation: tap > 0.3 ? 1 : 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AssetIcon(
                            assetPath: PuzzleAssets.hintBulb,
                            fallbackIcon: Icons.lightbulb_rounded,
                            size: 16,
                            color: PuzzleTheme.hintButtonText,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'HINT',
                            style: TextStyle(
                              color: PuzzleTheme.hintButtonText,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (tap > 0.1 && reveal < 0.75)
                TutorialHandPointer(
                  position: handPos,
                  opacity: tap,
                  scale: 0.9,
                ),
            ],
          ),
        );
      },
    );
  }
}
