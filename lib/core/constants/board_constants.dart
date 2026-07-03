abstract final class BoardConstants {
  static const double kBoardTileSize = 48;
  static const int kPlayGridRows = 16;
  static const int kPlayGridCols = 10;
  static const double kBoardGridLineWidth = 1;
  static const double kBoardOuterPadding = 24;
  static const double kLevelButtonWidthFactor = 0.75;
  static const double kLevelButtonHeight = 56;
  static const double kLevelButtonSpacing = 24;

  static double snapToGrid(double value, [double tileSize = kBoardTileSize]) {
    return (value / tileSize).round() * tileSize;
  }
}
