import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/audio/ui_button_sound.dart';
import 'package:jam_pro/core/constants/puzzle_sounds.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jam_pro/core/audio/audio_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('withButtonTap', () {
    test('returns null when action is null', () {
      expect(withButtonTap(null), isNull);
    });

    test('plays tap sound and runs action', () async {
      SharedPreferences.setMockInitialValues({});
      await AudioSettingsService.instance.resetForTest();

      var tapped = false;
      final wrapped = withButtonTap(() {
        tapped = true;
      });

      expect(wrapped, isNotNull);
      wrapped!();

      expect(tapped, isTrue);
    });
  });

  test('buttonTap asset path is registered', () {
    expect(PuzzleSounds.buttonTap, 'assets/sounds/button_tap.mp3');
  });
}
