import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_solved_checker.dart';

void main() {
  test('areAllTargetAnswersCompleted requires every answer', () {
    expect(
      areAllTargetAnswersCompleted(
        ['RED', 'BLUE', 'GREEN'],
        {'RED', 'BLUE'},
      ),
      isFalse,
    );

    expect(
      areAllTargetAnswersCompleted(
        ['RED', 'BLUE', 'GREEN'],
        {'RED', 'BLUE', 'GREEN'},
      ),
      isTrue,
    );
  });
}
