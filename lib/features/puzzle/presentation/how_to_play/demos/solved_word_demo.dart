import 'package:flutter/material.dart';

import 'tutorial_chunk_group.dart';
import 'tutorial_demo_scaffold.dart';
import 'tutorial_hand_pointer.dart';
import 'tutorial_word_layout.dart';

const _kLoopDuration = Duration(milliseconds: 4800);

class SolvedWordDemo extends StatefulWidget {
  const SolvedWordDemo({super.key, required this.isActive});

  final bool isActive;

  @override
  State<SolvedWordDemo> createState() => _SolvedWordDemoState();
}

class _SolvedWordDemoState extends State<SolvedWordDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static final _spOrigin = tutorialWordOrigin(wordLength: 5);
  static final _oonStart = Offset(_spOrigin.dx + kTutorialTileSize * 3.5, 105);
  static final _oonEnd = attachRight(
    leftOrigin: _spOrigin,
    leftTileCount: 2,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kLoopDuration)
      ..addStatusListener(_onStatus);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant SolvedWordDemo oldWidget) {
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
        final drag = _phase(0.18, 0.5);
        final connect = _phase(0.5, 0.62);
        final moveOut = _phase(0.65, 0.9);

        final connected = connect >= 1;
        final oonOffset = connected
            ? _oonEnd
            : Offset.lerp(
                _oonStart,
                _oonEnd,
                Curves.easeInOut.transform(drag),
              )!;

        final groupDy = -48 * Curves.easeInOut.transform(moveOut);
        final groupOpacity = 1 - moveOut;
        final showGlow = connected && moveOut < 0.85;

        final handPos = Offset.lerp(
          chunkHandPosition(_oonStart),
          chunkHandPosition(_oonEnd),
          Curves.easeInOut.transform(drag),
        )!;

        return TutorialDemoScaffold(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (!connected) ...[
                TutorialChunkGroup(
                  cells: horizontalChunk('SP'),
                  tileSize: kTutorialTileSize,
                  offset: _spOrigin,
                ),
                TutorialChunkGroup(
                  cells: horizontalChunk('OON'),
                  tileSize: kTutorialTileSize,
                  offset: oonOffset,
                  scale: 1 + pickUp * 0.04,
                  isDragging: pickUp > 0.5 || (drag > 0 && drag < 1),
                ),
              ] else
                Transform.translate(
                  offset: Offset(0, groupDy),
                  child: TutorialChunkGroup(
                    cells: horizontalWord('SPOON'),
                    tileSize: kTutorialTileSize,
                    offset: _spOrigin,
                    wordGlow: showGlow,
                    isCompleted: true,
                    opacity: groupOpacity,
                  ),
                ),
              if (handIn > 0 && !connected)
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
