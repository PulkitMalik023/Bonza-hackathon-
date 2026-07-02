import 'package:flutter/foundation.dart';

import 'puzzle_audio_controller.dart';

VoidCallback? withButtonTap(VoidCallback? action) {
  if (action == null) {
    return null;
  }

  return () {
    PuzzleAudioController.instance.playButtonTapSound();
    action();
  };
}
