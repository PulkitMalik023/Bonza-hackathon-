import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/audio/puzzle_audio_controller.dart';

void main() {
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

  test('loop audio context uses music focus for background playback', () {
    final context = PuzzleAudioController.loopAudioContext;

    expect(context.android.contentType, AndroidContentType.music);
    expect(context.android.usageType, AndroidUsageType.game);
    expect(context.android.audioFocus, AndroidAudioFocus.gain);
    expect(context.iOS.category, AVAudioSessionCategory.playback);
    expect(
      context.iOS.options,
      contains(AVAudioSessionOptions.mixWithOthers),
    );
  });

  test('sfx audio context avoids stealing loop focus', () {
    final context = PuzzleAudioController.sfxAudioContext;

    expect(context.android.contentType, AndroidContentType.sonification);
    expect(context.android.usageType, AndroidUsageType.game);
    expect(context.android.audioFocus, AndroidAudioFocus.none);
    expect(context.iOS.category, AVAudioSessionCategory.playback);
    expect(
      context.iOS.options,
      contains(AVAudioSessionOptions.mixWithOthers),
    );
  });
}
