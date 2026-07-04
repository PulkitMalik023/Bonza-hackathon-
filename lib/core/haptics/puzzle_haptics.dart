import 'package:flutter/services.dart';

abstract final class PuzzleHaptics {
  static void wordCompleted() {
    HapticFeedback.mediumImpact();
  }

  static void puzzleCompleted() {
    HapticFeedback.heavyImpact();
  }
}
