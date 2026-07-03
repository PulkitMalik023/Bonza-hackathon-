import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/puzzle_piece.dart';
import 'puzzle_intro_animation_constants.dart';
import 'puzzle_intro_animation_logger.dart';

class PuzzlePieceIntroValues {
  const PuzzlePieceIntroValues({
    required this.ghostOpacity,
    required this.ghostScale,
    required this.showGhost,
    required this.realOpacity,
    required this.realOffsetY,
    required this.realScale,
    required this.isIntroFinished,
  });

  static const initial = PuzzlePieceIntroValues(
    ghostOpacity: 0,
    ghostScale: PuzzleIntroAnimationConstants.ghostStartScale,
    showGhost: false,
    realOpacity: 0,
    realOffsetY: PuzzleIntroAnimationConstants.realStartOffsetY,
    realScale: PuzzleIntroAnimationConstants.realStartScale,
    isIntroFinished: false,
  );

  final double ghostOpacity;
  final double ghostScale;
  final bool showGhost;
  final double realOpacity;
  final double realOffsetY;
  final double realScale;
  final bool isIntroFinished;
}

class PuzzleChunkIntroCoordinator {
  PuzzleChunkIntroCoordinator({
    required TickerProvider vsync,
    required VoidCallback onUpdate,
    required VoidCallback onAllComplete,
  })  : _vsync = vsync,
        _onUpdate = onUpdate,
        _onAllComplete = onAllComplete;

  final TickerProvider _vsync;
  final VoidCallback _onUpdate;
  final VoidCallback _onAllComplete;

  Ticker? _ticker;
  Duration _elapsed = Duration.zero;
  List<PuzzlePiece> _pieces = const [];
  Map<String, PuzzlePieceIntroValues> _values = const {};
  final Set<int> _spawnSoundPlayed = {};
  final Set<int> _settleLogged = {};
  final Set<int> _chunkStartLogged = {};
  final Set<int> _ghostStartLogged = {};
  bool _isRunning = false;
  bool _completed = false;

  bool get isRunning => _isRunning;

  Map<String, PuzzlePieceIntroValues> get values => _values;

  void start(
    List<PuzzlePiece> pieces, {
    required VoidCallback onChunkSpawnSound,
    VoidCallback? onIntroStart,
  }) {
    disposeTicker();
    _pieces = List<PuzzlePiece>.from(pieces);
    _spawnSoundPlayed.clear();
    _settleLogged.clear();
    _chunkStartLogged.clear();
    _ghostStartLogged.clear();
    _completed = false;
    _elapsed = Duration.zero;
    _isRunning = _pieces.isNotEmpty;

    _values = {
      for (final piece in _pieces) piece.id: PuzzlePieceIntroValues.initial,
    };

    if (!_isRunning) {
      _onAllComplete();
      return;
    }

    PuzzleIntroAnimationLogger.introStarted(chunkCount: _pieces.length);
    onIntroStart?.call();

    _ticker = _vsync.createTicker((elapsed) {
      _elapsed = elapsed;
      _updateValues(onChunkSpawnSound: onChunkSpawnSound);

      if (_allIntroFinished()) {
        _finish();
        return;
      }

      _onUpdate();
    })
      ..start();

    _updateValues(onChunkSpawnSound: onChunkSpawnSound);
    _onUpdate();
  }

  void _updateValues({required VoidCallback onChunkSpawnSound}) {
    final elapsedMs = _elapsed.inMilliseconds;
    final nextValues = <String, PuzzlePieceIntroValues>{};

    for (var index = 0; index < _pieces.length; index++) {
      final piece = _pieces[index];
      final startMs =
          index * PuzzleIntroAnimationConstants.pieceStaggerDelay.inMilliseconds;
      final localMs = elapsedMs - startMs;

      if (localMs < 0) {
        nextValues[piece.id] = PuzzlePieceIntroValues.initial;
        continue;
      }

      if (localMs >= 0 && !_chunkStartLogged.contains(index)) {
        _chunkStartLogged.add(index);
        PuzzleIntroAnimationLogger.chunkStart(
          index: index,
          chunkId: piece.id,
        );
      }

      nextValues[piece.id] = _valuesForLocalTime(
        index: index,
        chunkId: piece.id,
        localMs: localMs,
        onChunkSpawnSound: onChunkSpawnSound,
      );
    }

    _values = nextValues;
  }

  PuzzlePieceIntroValues _valuesForLocalTime({
    required int index,
    required String chunkId,
    required int localMs,
    required VoidCallback onChunkSpawnSound,
  }) {
    final ghostAppearMs =
        PuzzleIntroAnimationConstants.ghostAppearDuration.inMilliseconds;
    final realEnterMs =
        PuzzleIntroAnimationConstants.realEnterDuration.inMilliseconds;
    final settleMs =
        PuzzleIntroAnimationConstants.settleDuration.inMilliseconds;
    final ghostFadeMs =
        PuzzleIntroAnimationConstants.ghostFadeDuration.inMilliseconds;

    final realEnterStartMs = ghostAppearMs;
    final settleStartMs = ghostAppearMs + realEnterMs;
    final totalMs = settleStartMs + settleMs;
    final ghostFadeStartMs = ghostAppearMs;

    if (localMs >= 0 && !_ghostStartLogged.contains(index)) {
      _ghostStartLogged.add(index);
      PuzzleIntroAnimationLogger.ghostStart(index: index);
    }

    if (localMs >= realEnterStartMs && !_spawnSoundPlayed.contains(index)) {
      _spawnSoundPlayed.add(index);
      PuzzleIntroAnimationLogger.realEnterStart(index: index);
      onChunkSpawnSound();
    }

    double ghostOpacity;
    double ghostScale;
    var showGhost = true;

    if (localMs <= ghostAppearMs) {
      final t = (localMs / ghostAppearMs).clamp(0.0, 1.0);
      ghostOpacity = PuzzleIntroAnimationConstants.ghostMaxOpacity * t;
      ghostScale = lerpDouble(
        PuzzleIntroAnimationConstants.ghostStartScale,
        PuzzleIntroAnimationConstants.ghostEndScale,
        t,
      )!;
    } else if (localMs < ghostFadeStartMs + ghostFadeMs) {
      final fadeT =
          ((localMs - ghostFadeStartMs) / ghostFadeMs).clamp(0.0, 1.0);
      ghostOpacity = PuzzleIntroAnimationConstants.ghostMaxOpacity * (1 - fadeT);
      ghostScale = PuzzleIntroAnimationConstants.ghostEndScale;
    } else {
      ghostOpacity = 0;
      ghostScale = PuzzleIntroAnimationConstants.ghostEndScale;
      showGhost = false;
    }

    double realOpacity;
    double realOffsetY;
    double realScale;

    if (localMs < realEnterStartMs) {
      realOpacity = 0;
      realOffsetY = PuzzleIntroAnimationConstants.realStartOffsetY;
      realScale = PuzzleIntroAnimationConstants.realStartScale;
    } else if (localMs < settleStartMs) {
      final t = Curves.easeOutCubic.transform(
        ((localMs - realEnterStartMs) / realEnterMs).clamp(0.0, 1.0),
      );
      realOpacity = t;
      realOffsetY = lerpDouble(
        PuzzleIntroAnimationConstants.realStartOffsetY,
        0,
        t,
      )!;
      realScale = lerpDouble(
        PuzzleIntroAnimationConstants.realStartScale,
        PuzzleIntroAnimationConstants.realOvershootScale,
        t,
      )!;
    } else if (localMs < totalMs) {
      final t = Curves.easeOutBack.transform(
        ((localMs - settleStartMs) / settleMs).clamp(0.0, 1.0),
      );
      realOpacity = 1;
      realOffsetY = 0;
      realScale = lerpDouble(
        PuzzleIntroAnimationConstants.realOvershootScale,
        1,
        t,
      )!;
    } else {
      realOpacity = 1;
      realOffsetY = 0;
      realScale = 1;
    }

    final isIntroFinished = localMs >= totalMs;
    if (isIntroFinished && !_settleLogged.contains(index)) {
      _settleLogged.add(index);
      PuzzleIntroAnimationLogger.settleComplete(index: index);
    }

    return PuzzlePieceIntroValues(
      ghostOpacity: ghostOpacity,
      ghostScale: ghostScale,
      showGhost: showGhost && ghostOpacity > 0,
      realOpacity: realOpacity,
      realOffsetY: realOffsetY,
      realScale: realScale,
      isIntroFinished: isIntroFinished,
    );
  }

  bool _allIntroFinished() {
    if (_values.isEmpty) {
      return true;
    }
    return _values.values.every((value) => value.isIntroFinished);
  }

  void _finish() {
    if (_completed) {
      return;
    }
    _completed = true;
    _isRunning = false;
    disposeTicker();
    _onUpdate();
    _onAllComplete();
  }

  void disposeTicker() {
    _ticker?.dispose();
    _ticker = null;
  }

  void dispose() {
    disposeTicker();
    _isRunning = false;
  }

  /// Test-only: compute intro values at a given elapsed time without a ticker.
  static Map<String, PuzzlePieceIntroValues> valuesAtElapsed({
    required List<PuzzlePiece> pieces,
    required Duration elapsed,
    List<int>? spawnSoundIndices,
  }) {
    final spawnSounds = spawnSoundIndices ?? <int>[];
    final coordinator = PuzzleChunkIntroCoordinator(
      vsync: _TestTickerProvider(),
      onUpdate: () {},
      onAllComplete: () {},
    );
    coordinator._pieces = List<PuzzlePiece>.from(pieces);
    coordinator._elapsed = elapsed;
    coordinator._values = {
      for (final piece in pieces) piece.id: PuzzlePieceIntroValues.initial,
    };
    coordinator._updateValues(
      onChunkSpawnSound: () {
        spawnSounds.add(coordinator._spawnSoundPlayed.length);
      },
    );
    return Map<String, PuzzlePieceIntroValues>.from(coordinator._values);
  }
}

class _TestTickerProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
