import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';

class GridWaveController {
  GridWaveController({
    required TickerProvider vsync,
    required this.waveDuration,
    required this.waveInterval,
    required this.onTick,
  }) : _vsync = vsync;

  final Duration waveDuration;
  final Duration waveInterval;
  final VoidCallback onTick;
  final TickerProvider _vsync;

  Ticker? _ticker;
  Duration _elapsed = Duration.zero;
  double _waveProgress = 0;
  bool _isRunning = false;

  double get waveProgress => _waveProgress;

  void start() {
    if (_isRunning) {
      return;
    }

    _isRunning = true;
    _elapsed = Duration.zero;
    _waveProgress = 0;

    _ticker = _vsync.createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsedSinceStart) {
    _elapsed = elapsedSinceStart;

    final cyclePosition =
        Duration(microseconds: _elapsed.inMicroseconds % waveInterval.inMicroseconds);

    if (cyclePosition < waveDuration) {
      final rawProgress = cyclePosition.inMicroseconds / waveDuration.inMicroseconds;
      _waveProgress = Curves.easeInOutCubic.transform(rawProgress);
    } else {
      _waveProgress = 0;
    }

    onTick();
  }

  void dispose() {
    _isRunning = false;
    _ticker?.dispose();
    _ticker = null;
  }
}
