import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'puzzle_audio_controller.dart';

class AudioSettingsService extends ChangeNotifier {
  AudioSettingsService._();

  static final AudioSettingsService instance = AudioSettingsService._();

  static const _sfxEnabledKey = 'audio_sfx_enabled';
  static const _musicEnabledKey = 'audio_music_enabled';

  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  bool _loaded = false;

  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _sfxEnabled = prefs.getBool(_sfxEnabledKey) ?? true;
    _musicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSfxEnabled(bool enabled) async {
    if (_sfxEnabled == enabled) {
      return;
    }
    _sfxEnabled = enabled;
    notifyListeners();
    await _save();
  }

  Future<void> toggleSfx() => setSfxEnabled(!_sfxEnabled);

  Future<void> setMusicEnabled(bool enabled) async {
    if (_musicEnabled == enabled) {
      return;
    }
    _musicEnabled = enabled;
    notifyListeners();
    await _save();

    if (!enabled) {
      await PuzzleAudioController.instance.stopPuzzleLoopSound();
      return;
    }

    await PuzzleAudioController.instance.ensurePuzzleLoopPlaying();
  }

  Future<void> toggleMusic() => setMusicEnabled(!_musicEnabled);

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxEnabledKey, _sfxEnabled);
    await prefs.setBool(_musicEnabledKey, _musicEnabled);
  }

  @visibleForTesting
  Future<void> resetForTest({
    bool sfxEnabled = true,
    bool musicEnabled = true,
  }) async {
    _sfxEnabled = sfxEnabled;
    _musicEnabled = musicEnabled;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxEnabledKey, _sfxEnabled);
    await prefs.setBool(_musicEnabledKey, _musicEnabled);
    notifyListeners();
  }
}
