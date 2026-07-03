import 'package:flutter/material.dart';

import 'tutorial_chunk_group.dart';
import 'tutorial_demo_scaffold.dart';
import 'tutorial_hand_pointer.dart';
import 'tutorial_word_layout.dart';

const _kLoopDuration = Duration(milliseconds: 5200);

/// L-shape demo: EAST + SOUTH solved; drag ES to complete vertical TEST.
class BetweenSolvedWordsDemo extends StatefulWidget {
  const BetweenSolvedWordsDemo({super.key, required this.isActive});

  final bool isActive;

  @override
  State<BetweenSolvedWordsDemo> createState() => _BetweenSolvedWordsDemoState();
}

class _BetweenSolvedWordsDemoState extends State<BetweenSolvedWordsDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _sharedCol = 3;
  static const _eastRow = 0;
  static const _southRow = 3;

  static final _gridOrigin = tutorialGridOrigin(cols: 5, rows: 8, topPadding: 28);
  static final _eastOrigin = cellOrigin(gridOrigin: _gridOrigin, col: 0, row: _eastRow);
  static final _southOrigin = cellOrigin(gridOrigin: _gridOrigin, col: 0, row: _southRow);
  static final _testsColOrigin = cellOrigin(
    gridOrigin: _gridOrigin,
    col: _sharedCol,
    row: _eastRow,
  );
  static final _esEnd = cellOrigin(gridOrigin: _gridOrigin, col: _sharedCol, row: 1);
  static final _esStart = Offset(_esEnd.dx + kTutorialTileSize * 2.5, _esEnd.dy + kTutorialTileSize);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kLoopDuration)
      ..addStatusListener(_onStatus);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant BetweenSolvedWordsDemo oldWidget) {
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
        final esOffset = Offset.lerp(
          _esStart,
          _esEnd,
          Curves.easeInOut.transform(drag),
        )!;
        final showGlow = highlight > 0.25;

        final handPos = Offset.lerp(
          chunkHandPosition(_esStart),
          chunkHandPosition(_esEnd),
          Curves.easeInOut.transform(drag),
        )!;

        return TutorialDemoScaffold(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              TutorialChunkGroup(
                cells: horizontalWordAt(startCol: 0, startRow: _eastRow, word: 'EAST'),
                tileSize: kTutorialTileSize,
                offset: _eastOrigin,
                isCompleted: true,
              ),
              TutorialChunkGroup(
                cells: horizontalWordAt(startCol: 0, startRow: _southRow, word: 'SOUTH'),
                tileSize: kTutorialTileSize,
                offset: _southOrigin,
                isCompleted: true,
              ),
              if (!connected)
                TutorialChunkGroup(
                  cells: verticalChunk('ES'),
                  tileSize: kTutorialTileSize,
                  offset: esOffset,
                  scale: 1 + pickUp * 0.04,
                  isDragging: pickUp > 0.5 || (drag > 0 && drag < 1),
                )
              else
                TutorialChunkGroup(
                  cells: verticalWordAt(
                    startCol: _sharedCol,
                    startRow: _eastRow,
                    word: 'TEST',
                  ),
                  tileSize: kTutorialTileSize,
                  offset: _testsColOrigin,
                  wordGlow: showGlow,
                  isCompleted: showGlow,
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
