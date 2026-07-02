import 'package:flutter/material.dart';

import 'tutorial_chunk_group.dart';
import 'tutorial_demo_scaffold.dart';
import 'tutorial_hand_pointer.dart';
import 'tutorial_word_layout.dart';

const _kLoopDuration = Duration(milliseconds: 4500);

class ConnectTilesDemo extends StatefulWidget {
  const ConnectTilesDemo({super.key, required this.isActive});

  final bool isActive;

  @override
  State<ConnectTilesDemo> createState() => _ConnectTilesDemoState();
}

class _ConnectTilesDemoState extends State<ConnectTilesDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static final _foOrigin = tutorialWordOrigin(wordLength: 4);
  static final _rkStart = Offset(_foOrigin.dx + kTutorialTileSize * 3, 105);
  static final _rkEnd = attachRight(
    leftOrigin: _foOrigin,
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
  void didUpdateWidget(covariant ConnectTilesDemo oldWidget) {
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
        final snap = _phase(0.52, 0.62);
        final glow = _phase(0.62, 0.88);

        final connected = snap >= 1;
        final rkOffset = Offset.lerp(
          _rkStart,
          _rkEnd,
          Curves.easeInOut.transform(drag),
        )!;
        final rkScale = 1 + pickUp * 0.04;
        final isDragging = pickUp > 0.5 || (drag > 0 && drag < 1);
        final showGlow = glow > 0.2;

        final handPos = Offset.lerp(
          chunkHandPosition(_rkStart),
          chunkHandPosition(_rkEnd),
          Curves.easeInOut.transform(drag),
        )!;

        return TutorialDemoScaffold(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (!connected)
                TutorialChunkGroup(
                  cells: horizontalChunk('FO'),
                  tileSize: kTutorialTileSize,
                  offset: _foOrigin,
                ),
              if (!connected)
                TutorialChunkGroup(
                  cells: horizontalChunk('RK'),
                  tileSize: kTutorialTileSize,
                  offset: connected ? _rkEnd : rkOffset,
                  scale: rkScale,
                  isDragging: isDragging,
                )
              else
                TutorialChunkGroup(
                  cells: horizontalWord('FORK'),
                  tileSize: kTutorialTileSize,
                  offset: _foOrigin,
                  wordGlow: showGlow,
                  isCompleted: showGlow,
                ),
              if (handIn > 0 && !connected && glow < 0.85)
                TutorialHandPointer(
                  position: handPos,
                  opacity: handIn * (1 - snap * 0.5),
                  scale: 0.95 + pickUp * 0.05,
                ),
            ],
          ),
        );
      },
    );
  }
}
