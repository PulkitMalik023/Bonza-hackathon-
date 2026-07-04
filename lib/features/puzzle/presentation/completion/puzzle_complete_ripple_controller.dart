import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/board_cell_position.dart';
import '../../domain/puzzle_complete_ripple.dart';

class PuzzleCompleteRippleController {
  PuzzleCompleteRippleController({
    required TickerProvider vsync,
    required Map<BoardCellPosition, int> hopDistances,
    required VoidCallback onTick,
    required VoidCallback onComplete,
  })  : _hopDistances = hopDistances,
        _maxHop = maxHopFromDistances(hopDistances),
        _onTick = onTick,
        _onComplete = onComplete {
    _controller = AnimationController(
      vsync: vsync,
      duration: computeRippleDuration(_maxHop),
    )
      ..addListener(_onTick)
      ..addStatusListener(_handleStatusChange);
  }

  final Map<BoardCellPosition, int> _hopDistances;
  final int _maxHop;
  final VoidCallback _onTick;
  final VoidCallback _onComplete;

  late final AnimationController _controller;

  double get progress => _controller.value;

  bool get isRunning =>
      _controller.status == AnimationStatus.forward ||
      _controller.status == AnimationStatus.reverse;

  double intensityAt(BoardCellPosition cell) {
    final hop = _hopDistances[cell];
    if (hop == null) {
      return 0;
    }

    return rippleIntensityForCell(
      hop: hop,
      globalProgress: _controller.value,
      maxHop: _maxHop,
    );
  }

  void start() {
    _controller.forward(from: 0);
  }

  void dispose() {
    _controller
      ..removeListener(_onTick)
      ..removeStatusListener(_handleStatusChange)
      ..dispose();
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _onComplete();
    }
  }
}
