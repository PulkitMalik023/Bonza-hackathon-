import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/audio/audio_settings_service.dart';
import 'package:jam_pro/core/audio/puzzle_audio_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AudioSettingsService.instance.resetForTest();
    PuzzleAudioController.resetGlobalAudioForTest();
  });

  test('shouldStartLoop prevents duplicate loop starts', () {
    expect(PuzzleAudioController.shouldStartLoop(false), isTrue);
    expect(PuzzleAudioController.shouldStartLoop(true), isFalse);
  });

  test('shouldRecoverLoop detects stale loop flag', () {
    expect(
      PuzzleAudioController.shouldRecoverLoop(
        loopPlaying: false,
        playerState: PlayerState.stopped,
      ),
      isTrue,
    );
    expect(
      PuzzleAudioController.shouldRecoverLoop(
        loopPlaying: true,
        playerState: PlayerState.playing,
      ),
      isFalse,
    );
    expect(
      PuzzleAudioController.shouldRecoverLoop(
        loopPlaying: true,
        playerState: PlayerState.stopped,
      ),
      isTrue,
    );
  });

  test('game audio context mixes with other audio sources', () {
    final context = PuzzleAudioController.gameAudioContext;

    expect(context.android.audioFocus, AndroidAudioFocus.none);
    expect(context.android.usageType, AndroidUsageType.media);
  });

  test('configureGlobalAudio is idempotent', () async {
    await PuzzleAudioController.instance.configureGlobalAudio();
    await PuzzleAudioController.instance.configureGlobalAudio();
  });

  test('playButtonTapSound returns early when sfx disabled', () async {
    await AudioSettingsService.instance.resetForTest(sfxEnabled: false);

    await PuzzleAudioController.instance.playButtonTapSound();
  });

  test('ensurePuzzleLoopPlaying returns early when music disabled', () async {
    await AudioSettingsService.instance.resetForTest(musicEnabled: false);

    await PuzzleAudioController.instance.ensurePuzzleLoopPlaying();

    expect(PuzzleAudioController.instance.isLoopPlaying, isFalse);
  });
}
