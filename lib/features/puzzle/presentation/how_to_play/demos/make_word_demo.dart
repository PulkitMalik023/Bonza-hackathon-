import 'package:flutter/material.dart';

import '../../../../../core/theme/puzzle_theme.dart';
import 'tutorial_chunk_group.dart';
import 'tutorial_demo_scaffold.dart';
import 'tutorial_hand_pointer.dart';
import 'tutorial_word_layout.dart';

const _kLoopDuration = Duration(milliseconds: 4500);

class MakeWordDemo extends StatefulWidget {
  const MakeWordDemo({super.key, required this.isActive});

  final bool isActive;

  @override
  State<MakeWordDemo> createState() => _MakeWordDemoState();
}

class _MakeWordDemoState extends State<MakeWordDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static final _ifeOrigin = Offset(
    tutorialWordOrigin(wordLength: 5).dx + kTutorialTileSize * 2,
    tutorialWordOrigin(wordLength: 5).dy,
  );
  static final _knStart = Offset(_ifeOrigin.dx + kTutorialTileSize * 2.5, 105);
  static final _knEnd = attachLeft(
    rightOrigin: _ifeOrigin,
    movingTileCount: 2,
  );
  static final _wordOrigin = tutorialWordOrigin(wordLength: 5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kLoopDuration)
      ..addStatusListener(_onStatus);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant MakeWordDemo oldWidget) {
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
        final handIn = _phase(0.05, 0.12);
        final pickUp = _phase(0.12, 0.18);
        final drag = _phase(0.18, 0.52);
        final highlight = _phase(0.55, 0.88);

        final connected = drag >= 1;
        final knOffset = Offset.lerp(
          _knStart,
          _knEnd,
          Curves.easeInOut.transform(drag),
        )!;
        final showWordFound = highlight > 0.25;

        final handPos = Offset.lerp(
          chunkHandPosition(_knStart),
          chunkHandPosition(_knEnd),
          Curves.easeInOut.transform(drag),
        )!;

        return TutorialDemoScaffold(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (!connected) ...[
                TutorialChunkGroup(
                  cells: horizontalChunk('IFE'),
                  tileSize: kTutorialTileSize,
                  offset: _ifeOrigin,
                ),
                TutorialChunkGroup(
                  cells: horizontalChunk('KN'),
                  tileSize: kTutorialTileSize,
                  offset: knOffset,
                  scale: 1 + pickUp * 0.04,
                  isDragging: pickUp > 0.5 || (drag > 0 && drag < 1),
                ),
              ] else
                TutorialChunkGroup(
                  cells: horizontalWord('KNIFE'),
                  tileSize: kTutorialTileSize,
                  offset: _wordOrigin,
                  wordGlow: showWordFound,
                  isCompleted: showWordFound,
                ),
              if (showWordFound)
                Positioned(
                  top: 18,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: PuzzleTheme.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: PuzzleTheme.tileRestShadow,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Word found!',
                              style: TextStyle(
                                color: Colors.white,
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
              if (handIn > 0 && !connected && highlight < 0.7)
                TutorialHandPointer(
                  position: handPos,
                  opacity: handIn,
                  scale: 0.95 + pickUp * 0.05,
                ),
            ],
          ),
        );
      },
    );
  }
}
