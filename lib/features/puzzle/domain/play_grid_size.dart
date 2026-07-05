import 'dart:math';

import '../../../core/constants/board_constants.dart';
import '../data/models/placed_word.dart';
import '../data/models/puzzle_layout.dart';

typedef PlayGridSize = ({int rows, int cols});

PlayGridSize computeMinimumPlayGridSize(PuzzleLayout layout) {
  var maxVertical = 1;
  var maxHorizontal = 1;

  for (final placed in layout.placedWords) {
    final length = placed.word.length;
    if (placed.direction == WordDirection.vertical) {
      maxVertical = max(maxVertical, length);
    } else {
      maxHorizontal = max(maxHorizontal, length);
    }
  }

  return (
    rows: max(BoardConstants.kPlayGridRows, maxVertical * 2),
    cols: max(BoardConstants.kPlayGridCols, maxHorizontal * 2),
  );
}

PlayGridSize computePlayGridSizeForViewport({
  required PuzzleLayout layout,
  required double playableWidth,
  required double playableHeight,
}) {
  final minimum = computeMinimumPlayGridSize(layout);
  if (playableWidth <= 0 || playableHeight <= 0) {
    return minimum;
  }

  final tileFromWidth = playableWidth / minimum.cols;
  final tileFromHeight = playableHeight / minimum.rows;

  if (tileFromWidth <= tileFromHeight) {
    final rows = max(minimum.rows, (playableHeight / tileFromWidth).floor());
    return (rows: rows, cols: minimum.cols);
  }

  final cols = max(minimum.cols, (playableWidth / tileFromHeight).floor());
  return (rows: minimum.rows, cols: cols);
}

double computePlayTileSize({
  required PlayGridSize gridSize,
  required double playableWidth,
  required double playableHeight,
}) {
  return min(
    playableWidth / gridSize.cols,
    playableHeight / gridSize.rows,
  );
}
