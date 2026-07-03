import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/presentation/how_to_play/demos/tutorial_word_layout.dart';

void main() {
  group('tutorial_word_layout', () {
    test('horizontalWord maps letters to row 0 columns', () {
      final cells = horizontalWord('FORK');

      expect(cells.length, 4);
      expect(cells[0].letter, 'F');
      expect(cells[0].col, 0);
      expect(cells[0].row, 0);
      expect(cells[3].letter, 'K');
      expect(cells[3].col, 3);
    });

    test('verticalWord maps letters to column 0 rows', () {
      final cells = verticalWord('SOUTH');

      expect(cells.length, 5);
      expect(cells[0].letter, 'S');
      expect(cells[0].col, 0);
      expect(cells[0].row, 0);
      expect(cells[4].letter, 'H');
      expect(cells[4].row, 4);
    });

    test('attachRight places chunk immediately after left chunk', () {
      const leftOrigin = Offset(54, 69);
      final right = attachRight(leftOrigin: leftOrigin, leftTileCount: 2);

      expect(right, const Offset(126, 69));
    });

    test('attachLeft places chunk immediately before right chunk', () {
      const rightOrigin = Offset(126, 69);
      final left = attachLeft(rightOrigin: rightOrigin, movingTileCount: 2);

      expect(left, const Offset(54, 69));
    });

    test('attachBelow places chunk immediately under top chunk', () {
      const topOrigin = Offset(100, 40);
      final below = attachBelow(topOrigin: topOrigin, topTileCount: 2);

      expect(below, const Offset(100, 112));
    });

    test('attachBetween places chunk after completed left word', () {
      const leftOrigin = Offset(50, 80);
      final between = attachBetween(
        leftCompletedOrigin: leftOrigin,
        leftCompletedTileCount: 3,
        movingTileCount: 2,
      );

      expect(between, const Offset(158, 80));
    });

    test('fork snap positions align FO and RK into one row', () {
      final foOrigin = tutorialWordOrigin(wordLength: 4);
      final rkEnd = attachRight(leftOrigin: foOrigin, leftTileCount: 2);

      expect(foOrigin.dy, rkEnd.dy);
      expect(rkEnd.dx - foOrigin.dx, kTutorialTileSize * 2);
    });

    test('south vertical snap positions align SO and UTH into one column', () {
      final soOrigin = tutorialWordOrigin(wordLength: 5, vertical: true);
      final uthEnd = attachBelow(topOrigin: soOrigin, topTileCount: 2);

      expect(uthEnd.dx, soOrigin.dx);
      expect(uthEnd.dy - soOrigin.dy, kTutorialTileSize * 2);
    });

    test('cellOrigin maps grid cell to pixel offset', () {
      const gridOrigin = Offset(40, 24);
      final origin = cellOrigin(gridOrigin: gridOrigin, col: 3, row: 2);

      expect(origin, const Offset(148, 96));
    });

    test('L-shape TEST column aligns with EAST and SOUTH shared T', () {
      const sharedCol = 3;
      const eastRow = 0;
      const southRow = 3;
      final gridOrigin = tutorialGridOrigin(cols: 5, rows: 8, topPadding: 20);
      final eastT = cellOrigin(gridOrigin: gridOrigin, col: sharedCol, row: eastRow);
      final southT = cellOrigin(gridOrigin: gridOrigin, col: sharedCol, row: southRow);
      final testsMid = cellOrigin(gridOrigin: gridOrigin, col: sharedCol, row: 2);

      expect(eastT.dx, southT.dx);
      expect(testsMid.dx, eastT.dx);
      expect(southT.dy - eastT.dy, kTutorialTileSize * southRow);
    });
  });
}
