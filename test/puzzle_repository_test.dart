import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/repositories/puzzle_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getNextEnabledPuzzleId returns next enabled puzzle id', () async {
    final repository = PuzzleRepository();

    expect(await repository.getNextEnabledPuzzleId(1), 2);
    expect(await repository.getNextEnabledPuzzleId(4), 5);
    expect(await repository.getNextEnabledPuzzleId(50), isNull);
    expect(await repository.getNextEnabledPuzzleId(999), isNull);
  });
}
