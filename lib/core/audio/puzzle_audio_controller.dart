import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../constants/puzzle_sounds.dart';
import 'audio_settings_service.dart';

class PuzzleAudioController {
  PuzzleAudioController._({
    AudioPlayer? loopPlayer,
    AudioPlayer? sfxPlayer,
  })  : _loopPlayer = loopPlayer,
        _sfxPlayer = sfxPlayer;

  @visibleForTesting
  factory PuzzleAudioController.test({
    AudioPlayer? loopPlayer,
    AudioPlayer? sfxPlayer,
  }) = PuzzleAudioController._;

  static final PuzzleAudioController instance = PuzzleAudioController._();

  static const _loopPlayerId = 'puzzle_loop';
  static const _sfxPlayerId = 'puzzle_sfx';

  static bool _globalAudioConfigured = false;

  AudioPlayer? _loopPlayer;
  AudioPlayer? _sfxPlayer;
  bool _loopPlaying = false;
  bool _configured = false;
  bool _disposed = false;
  AudioPlayer get _loop =>
      _loopPlayer ??= AudioPlayer(playerId: _loopPlayerId);
  AudioPlayer get _sfx => _sfxPlayer ??= AudioPlayer(playerId: _sfxPlayerId);

  bool get isLoopPlaying => _loopPlaying;

  Future<void> configureGlobalAudio() async {
    if (_globalAudioConfigured) {
      return;
    }

    try {
      await AudioPlayer.global.setAudioContext(gameAudioContext);
      _globalAudioConfigured = true;
    } catch (error, stackTrace) {
      debugPrint('[PuzzleAudioController] Global audio setup failed: $error');
      debugPrint('[PuzzleAudioController] $stackTrace');
    }
  }

  Future<void> ensurePuzzleLoopPlaying() async {
    if (_disposed) {
      return;
    }

    if (!AudioSettingsService.instance.musicEnabled) {
      return;
    }

    try {
      await _ensureConfigured();

      if (_loop.state == PlayerState.playing) {
        _loopPlaying = true;
        return;
      }

      if (_loop.state == PlayerState.paused && _loopPlaying) {
        await _loop.resume();
        return;
      }

      _loopPlaying = false;
      await playPuzzleLoopSound();
    } catch (error, stackTrace) {
      _loopPlaying = false;
      debugPrint('[PuzzleAudioController] Ensure loop failed: $error');
      debugPrint('[PuzzleAudioController] $stackTrace');
    }
  }

  Future<void> playPuzzleLoopSound() async {
    if (_disposed || _loopPlaying || !AudioSettingsService.instance.musicEnabled) {
      return;
    }

    try {
      await _ensureConfigured();
      await _loop.setReleaseMode(ReleaseMode.loop);
      await _loop.setVolume(0.35);
      await _loop.play(AssetSource(_assetPath(PuzzleSounds.gameplayLoop)));
      _loopPlaying = true;
    } catch (error, stackTrace) {
      _loopPlaying = false;
      debugPrint('[PuzzleAudioController] Loop failed: $error');
      debugPrint('[PuzzleAudioController] $stackTrace');
    }
  }

  Future<void> stopPuzzleLoopSound() async {
    if (_disposed) {
      return;
    }

    try {
      await _loop.stop();
    } catch (error) {
      debugPrint('[PuzzleAudioController] Stop loop failed: $error');
    } finally {
      _loopPlaying = false;
    }
  }

  Future<void> pausePuzzleLoopSound() async {
    if (_disposed || !_loopPlaying) {
      return;
    }

    try {
      await _loop.pause();
    } catch (error) {
      debugPrint('[PuzzleAudioController] Pause loop failed: $error');
    }
  }

  Future<void> resumePuzzleLoopSound() async {
    if (_disposed || !_loopPlaying) {
      return;
    }

    try {
      await _loop.resume();
    } catch (error) {
      debugPrint('[PuzzleAudioController] Resume loop failed: $error');
    }
  }

  Future<void> playTilePickSound() async {
    if (!AudioSettingsService.instance.sfxEnabled) {
      return;
    }
    await _playSfx(PuzzleSounds.tilePick);
  }

  Future<void> playTileDropSound() async {
    if (!AudioSettingsService.instance.sfxEnabled) {
      return;
    }
    await _playSfx(PuzzleSounds.tileDrop);
  }

  Future<void> playButtonTapSound() async {
    if (!AudioSettingsService.instance.sfxEnabled) {
      return;
    }
    await _playSfx(PuzzleSounds.buttonTap);
  }

  Future<void> _ensureConfigured() async {
    if (_configured || _disposed) {
      return;
    }

    try {
      await _loop.setPlayerMode(PlayerMode.mediaPlayer);
      await _loop.setAudioContext(loopAudioContext);

      await _sfx.setPlayerMode(PlayerMode.lowLatency);
      await _sfx.setAudioContext(sfxAudioContext);

      _configured = true;
    } catch (error, stackTrace) {
      debugPrint('[PuzzleAudioController] Player setup failed: $error');
      debugPrint('[PuzzleAudioController] $stackTrace');
    }
  }

  Future<void> _playSfx(String assetPath) async {
    if (_disposed) {
      return;
    }

    try {
      await _ensureConfigured();

      final sfxState = _sfx.state;
      if (sfxState == PlayerState.playing || sfxState == PlayerState.paused) {
        await _sfx.stop();
      }

      await _sfx.setReleaseMode(ReleaseMode.stop);
      await _sfx.setVolume(0.7);
      await _sfx.play(AssetSource(_assetPath(assetPath)));
      await _ensureLoopStillPlaying();
    } catch (error) {
      debugPrint('[PuzzleAudioController] SFX failed ($assetPath): $error');
    }
  }

  Future<void> _ensureLoopStillPlaying() async {
    if (!_loopPlaying || _disposed) {
      return;
    }

    try {
      if (_loop.state == PlayerState.playing) {
        return;
      }

      if (_loop.state == PlayerState.paused) {
        await _loop.resume();
        return;
      }

      await _loop.setReleaseMode(ReleaseMode.loop);
      await _loop.setVolume(0.35);
      await _loop.play(AssetSource(_assetPath(PuzzleSounds.gameplayLoop)));
    } catch (error) {
      debugPrint('[PuzzleAudioController] Ensure loop playing failed: $error');
    }
  }

  String _assetPath(String fullPath) {
    const prefix = 'assets/';
    if (fullPath.startsWith(prefix)) {
      return fullPath.substring(prefix.length);
    }
    return fullPath;
  }

  @visibleForTesting
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _loopPlaying = false;
    _configured = false;
    try {
      _loopPlayer?.dispose();
      _sfxPlayer?.dispose();
    } catch (error) {
      debugPrint('[PuzzleAudioController] Dispose failed: $error');
    }
    _loopPlayer = null;
    _sfxPlayer = null;
  }

  @visibleForTesting
  static bool shouldStartLoop(bool loopPlaying) => !loopPlaying;

  @visibleForTesting
  static bool shouldRecoverLoop({
    required bool loopPlaying,
    required PlayerState playerState,
  }) {
    if (!loopPlaying) {
      return true;
    }
    return playerState != PlayerState.playing;
  }

  @visibleForTesting
  static AudioContext get gameAudioContext => AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();

  @visibleForTesting
  static AudioContext get loopAudioContext => AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      );

  @visibleForTesting
  static AudioContext get sfxAudioContext => AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      );

  @visibleForTesting
  static void resetGlobalAudioForTest() {
    _globalAudioConfigured = false;
  }
}
