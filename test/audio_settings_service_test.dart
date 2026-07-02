import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/audio/audio_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AudioSettingsService.instance.resetForTest();
  });

  group('AudioSettingsService', () {
    test('defaults to sound and music enabled', () async {
      await AudioSettingsService.instance.load();

      expect(AudioSettingsService.instance.sfxEnabled, isTrue);
      expect(AudioSettingsService.instance.musicEnabled, isTrue);
    });

    test('toggleSfx updates state and persists', () async {
      await AudioSettingsService.instance.load();
      await AudioSettingsService.instance.toggleSfx();

      expect(AudioSettingsService.instance.sfxEnabled, isFalse);

      await AudioSettingsService.instance.load();
      expect(AudioSettingsService.instance.sfxEnabled, isFalse);
    });

    test('toggleMusic updates state and persists', () async {
      await AudioSettingsService.instance.load();
      await AudioSettingsService.instance.toggleMusic();

      expect(AudioSettingsService.instance.musicEnabled, isFalse);

      await AudioSettingsService.instance.load();
      expect(AudioSettingsService.instance.musicEnabled, isFalse);
    });
    test('setMusicEnabled true attempts to start loop without puzzle session', () async {
      await AudioSettingsService.instance.resetForTest(musicEnabled: false);
      await AudioSettingsService.instance.setMusicEnabled(true);

      expect(AudioSettingsService.instance.musicEnabled, isTrue);
    });
  });
}
