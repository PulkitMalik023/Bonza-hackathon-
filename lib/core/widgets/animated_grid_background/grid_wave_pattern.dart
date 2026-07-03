import 'dart:math';

enum GridWavePattern {
  diagonalDownRight,
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
  bubbleFromBottom,
}

GridWavePattern gridWavePatternForCycle(int cycleIndex) {
  final patterns = GridWavePattern.values;
  return patterns[cycleIndex % patterns.length];
}

double waveFrontForPattern({
  required GridWavePattern pattern,
  required double waveProgress,
  required int rows,
  required int cols,
}) {
  if (rows <= 0 || cols <= 0) {
    return 0;
  }

  switch (pattern) {
    case GridWavePattern.diagonalDownRight:
      return waveProgress * (rows + cols - 2);
    case GridWavePattern.topToBottom:
    case GridWavePattern.bottomToTop:
      return waveProgress * max(1, rows - 1);
    case GridWavePattern.leftToRight:
    case GridWavePattern.rightToLeft:
      return waveProgress * max(1, cols - 1);
    case GridWavePattern.bubbleFromBottom:
      return waveProgress * _maxBubbleDistance(rows: rows, cols: cols);
  }
}

double tileWaveDistance({
  required GridWavePattern pattern,
  required int row,
  required int col,
  required int rows,
  required int cols,
}) {
  switch (pattern) {
    case GridWavePattern.diagonalDownRight:
      return (row + col).toDouble();
    case GridWavePattern.topToBottom:
      return row.toDouble();
    case GridWavePattern.bottomToTop:
      return (rows - 1 - row).toDouble();
    case GridWavePattern.leftToRight:
      return col.toDouble();
    case GridWavePattern.rightToLeft:
      return (cols - 1 - col).toDouble();
    case GridWavePattern.bubbleFromBottom:
      final centerCol = (cols - 1) / 2.0;
      const centerRow = 0.0;
      final tileRowFromBottom = (rows - 1 - row).toDouble();
      return sqrt(
        pow(col - centerCol, 2) + pow(tileRowFromBottom - centerRow, 2),
      );
  }
}

double tileHighlight({
  required GridWavePattern pattern,
  required int row,
  required int col,
  required int rows,
  required int cols,
  required double waveProgress,
  required double waveSpread,
}) {
  if (waveProgress <= 0 || rows <= 0 || cols <= 0) {
    return 0;
  }

  final waveFront = waveFrontForPattern(
    pattern: pattern,
    waveProgress: waveProgress,
    rows: rows,
    cols: cols,
  );
  final tileIndex = tileWaveDistance(
    pattern: pattern,
    row: row,
    col: col,
    rows: rows,
    cols: cols,
  );
  final distance = (tileIndex - waveFront).abs();
  return (1 - distance / waveSpread).clamp(0.0, 1.0);
}

double _maxBubbleDistance({required int rows, required int cols}) {
  if (rows <= 0 || cols <= 0) {
    return 1;
  }

  final centerCol = (cols - 1) / 2.0;
  var maxDistance = 1.0;

  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      final distance = tileWaveDistance(
        pattern: GridWavePattern.bubbleFromBottom,
        row: row,
        col: col,
        rows: rows,
        cols: cols,
      );
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }
  }

  return maxDistance;
}
