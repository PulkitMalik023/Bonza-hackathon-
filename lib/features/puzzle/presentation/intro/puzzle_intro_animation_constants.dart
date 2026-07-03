abstract final class PuzzleIntroAnimationConstants {
  static const ghostAppearDuration = Duration(milliseconds: 90);
  static const realEnterDuration = Duration(milliseconds: 220);
  static const settleDuration = Duration(milliseconds: 140);
  static const ghostFadeDuration = Duration(milliseconds: 120);
  static const pieceStaggerDelay = Duration(milliseconds: 70);

  static const realStartOffsetY = -24.0;
  static const realStartScale = 0.92;
  static const realOvershootScale = 1.06;

  static const ghostStartScale = 0.96;
  static const ghostEndScale = 1.0;
  static const ghostMaxOpacity = 0.32;

  static int get pieceIntroDurationMs =>
      ghostAppearDuration.inMilliseconds +
      realEnterDuration.inMilliseconds +
      settleDuration.inMilliseconds;
}
