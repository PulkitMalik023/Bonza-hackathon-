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

    test('fork snap positions align FO and RK into one row', () {
      final foOrigin = tutorialWordOrigin(wordLength: 4);
      final rkEnd = attachRight(leftOrigin: foOrigin, leftTileCount: 2);

      expect(foOrigin.dy, rkEnd.dy);
      expect(rkEnd.dx - foOrigin.dx, kTutorialTileSize * 2);
    });

    test('spoon snap positions align SP and OON without overlap', () {
      final spOrigin = tutorialWordOrigin(wordLength: 5);
      final oonEnd = attachRight(leftOrigin: spOrigin, leftTileCount: 2);

      expect(oonEnd.dx - spOrigin.dx, kTutorialTileSize * 2);
      expect(oonEnd.dy, spOrigin.dy);
    });
  });
}
