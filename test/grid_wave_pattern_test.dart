import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/constants/board_constants.dart';
import 'package:jam_pro/core/widgets/animated_grid_background/grid_wave_pattern.dart';

void main() {
  group('gridWavePatternForCycle', () {
    test('cycles through all six patterns', () {
      expect(
        gridWavePatternForCycle(0),
        GridWavePattern.diagonalDownRight,
      );
      expect(gridWavePatternForCycle(1), GridWavePattern.topToBottom);
      expect(gridWavePatternForCycle(5), GridWavePattern.bubbleFromBottom);
      expect(gridWavePatternForCycle(6), GridWavePattern.diagonalDownRight);
    });
  });

  group('tileHighlight', () {
    const rows = BoardConstants.kPlayGridRows;
    const cols = BoardConstants.kPlayGridCols;
    const waveSpread = 3.0;

    test('diagonal pattern peaks at wave front tile', () {
      const progress = 0.5;
      final front = waveFrontForPattern(
        pattern: GridWavePattern.diagonalDownRight,
        waveProgress: progress,
        rows: rows,
        cols: cols,
      ).round();

      var frontRow = 0;
      var frontCol = front;
      if (frontCol >= cols) {
        frontCol = cols - 1;
        frontRow = front - frontCol;
      }

      final atFront = tileHighlight(
        pattern: GridWavePattern.diagonalDownRight,
        row: frontRow,
        col: frontCol,
        rows: rows,
        cols: cols,
        waveProgress: progress,
        waveSpread: waveSpread,
      );

      final awayFromFront = tileHighlight(
        pattern: GridWavePattern.diagonalDownRight,
        row: 0,
        col: 0,
        rows: rows,
        cols: cols,
        waveProgress: progress,
        waveSpread: waveSpread,
      );

      expect(atFront, greaterThan(awayFromFront));
      expect(atFront, greaterThan(0.5));
    });

    test('topToBottom pattern peaks on front row', () {
      const progress = 0.5;
      final frontRow = waveFrontForPattern(
        pattern: GridWavePattern.topToBottom,
        waveProgress: progress,
        rows: rows,
        cols: cols,
      ).round();

      final atFront = tileHighlight(
        pattern: GridWavePattern.topToBottom,
        row: frontRow,
        col: cols ~/ 2,
        rows: rows,
        cols: cols,
        waveProgress: progress,
        waveSpread: waveSpread,
      );

      expect(atFront, greaterThan(0.5));
    });

    test('leftToRight pattern peaks on front column', () {
      const progress = 0.5;
      final frontCol = waveFrontForPattern(
        pattern: GridWavePattern.leftToRight,
        waveProgress: progress,
        rows: rows,
        cols: cols,
      ).round();

      final atFront = tileHighlight(
        pattern: GridWavePattern.leftToRight,
        row: rows ~/ 2,
        col: frontCol,
        rows: rows,
        cols: cols,
        waveProgress: progress,
        waveSpread: waveSpread,
      );

      expect(atFront, closeTo(1, 0.01));
    });

    test('bubbleFromBottom pattern peaks near bottom center early in sweep', () {
      const progress = 0.08;
      final bottomCenterHighlight = tileHighlight(
        pattern: GridWavePattern.bubbleFromBottom,
        row: rows - 1,
        col: cols ~/ 2,
        rows: rows,
        cols: cols,
        waveProgress: progress,
        waveSpread: waveSpread,
      );
      final topCornerHighlight = tileHighlight(
        pattern: GridWavePattern.bubbleFromBottom,
        row: 0,
        col: 0,
        rows: rows,
        cols: cols,
        waveProgress: progress,
        waveSpread: waveSpread,
      );

      expect(bottomCenterHighlight, greaterThan(topCornerHighlight));
      expect(bottomCenterHighlight, greaterThan(0));
    });

    test('returns zero highlight when wave progress is zero', () {
      expect(
        tileHighlight(
          pattern: GridWavePattern.topToBottom,
          row: 0,
          col: 0,
          rows: rows,
          cols: cols,
          waveProgress: 0,
          waveSpread: waveSpread,
        ),
        0,
      );
    });
  });
}
