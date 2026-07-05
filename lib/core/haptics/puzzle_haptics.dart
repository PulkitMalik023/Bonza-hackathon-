import 'package:flutter/services.dart';

abstract final class PuzzleHaptics {
  static void puzzleCompleted() {
    HapticFeedback.heavyImpact();
  }
}
