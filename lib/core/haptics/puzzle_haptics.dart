import 'package:flutter/services.dart';

abstract final class PuzzleHaptics {
  static void wordCompleted() {
    HapticFeedback.lightImpact();
  }

  static void puzzleCompleted() {
    HapticFeedback.heavyImpact();
  }
}
