import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/presentation/puzzle_screen.dart';

void main() {
  group('nextLayoutIndex', () {
    test('cycles through layouts with wrap-around', () {
      expect(nextLayoutIndex(0, 3), 1);
      expect(nextLayoutIndex(1, 3), 2);
      expect(nextLayoutIndex(2, 3), 0);
    });

    test('returns same index when only one layout exists', () {
      expect(nextLayoutIndex(0, 1), 0);
      expect(nextLayoutIndex(0, 0), 0);
    });
  });
}
