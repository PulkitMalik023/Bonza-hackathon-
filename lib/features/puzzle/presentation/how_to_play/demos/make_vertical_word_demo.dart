import 'package:flutter/material.dart';

import 'tutorial_chunk_group.dart';
import 'tutorial_demo_scaffold.dart';
import 'tutorial_hand_pointer.dart';
import 'tutorial_word_layout.dart';

const _kLoopDuration = Duration(milliseconds: 4500);

class MakeVerticalWordDemo extends StatefulWidget {
  const MakeVerticalWordDemo({super.key, required this.isActive});

  final bool isActive;

  @override
  State<MakeVerticalWordDemo> createState() => _MakeVerticalWordDemoState();
}

class _MakeVerticalWordDemoState extends State<MakeVerticalWordDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static final _soOrigin = tutorialWordOrigin(wordLength: 5, vertical: true);
  static final _uthStart = Offset(_soOrigin.dx + kTutorialTileSize * 1.5, 40);
  static final _uthEnd = attachBelow(
    topOrigin: _soOrigin,
    topTileCount: 2,
  );
  static final _wordOrigin = tutorialWordOrigin(wordLength: 5, vertical: true);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kLoopDuration)
      ..addStatusListener(_onStatus);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant MakeVerticalWordDemo oldWidget) {
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
        final uthOffset = Offset.lerp(
          _uthStart,
          _uthEnd,
          Curves.easeInOut.transform(drag),
        )!;
        final showWordFound = highlight > 0.25;

        final handPos = Offset.lerp(
          chunkHandPosition(_uthStart),
          chunkHandPosition(_uthEnd),
          Curves.easeInOut.transform(drag),
        )!;

        return TutorialDemoScaffold(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (!connected) ...[
                TutorialChunkGroup(
                  cells: verticalChunk('SO'),
                  tileSize: kTutorialTileSize,
                  offset: _soOrigin,
                ),
                TutorialChunkGroup(
                  cells: verticalChunk('UTH'),
                  tileSize: kTutorialTileSize,
                  offset: uthOffset,
                  scale: 1 + pickUp * 0.04,
                  isDragging: pickUp > 0.5 || (drag > 0 && drag < 1),
                ),
              ] else
                TutorialChunkGroup(
                  cells: verticalWord('SOUTH'),
                  tileSize: kTutorialTileSize,
                  offset: _wordOrigin,
                  wordGlow: showWordFound,
                  isCompleted: showWordFound,
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
