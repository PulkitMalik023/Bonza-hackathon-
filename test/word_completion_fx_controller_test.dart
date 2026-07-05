import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/presentation/word_completion_fx_controller.dart';

void main() {
  group('WordCompletionFxController', () {
    late WordCompletionFxController controller;

    setUp(() {
      controller = WordCompletionFxController();
    });

    test('returns reward for first newly completed word', () {
      final reward = controller.rewardForNewlyCompletedWords({'FORK'});

      expect(reward, isNotNull);
      expect(reward!.newlyCompletedWords, {'FORK'});
    });

    test('returns null when no new words were completed', () {
      controller.rewardForNewlyCompletedWords({'FORK'});

      final reward = controller.rewardForNewlyCompletedWords({'FORK'});

      expect(reward, isNull);
    });

    test('returns all new words when multiple complete in one move', () {
      final reward = controller.rewardForNewlyCompletedWords({'FORK', 'KNIFE'});

      expect(reward, isNotNull);
      expect(reward!.newlyCompletedWords, {'FORK', 'KNIFE'});
    });

    test('normalizes answer casing when tracking completions', () {
      controller.rewardForNewlyCompletedWords({'fork'});

      final reward = controller.rewardForNewlyCompletedWords({'FORK'});

      expect(reward, isNull);
    });

    test('reset allows the same words to reward again', () {
      controller.rewardForNewlyCompletedWords({'FORK'});
      controller.reset();

      final reward = controller.rewardForNewlyCompletedWords({'FORK'});

      expect(reward, isNotNull);
      expect(reward!.newlyCompletedWords, {'FORK'});
    });

    test('seedCompletedWords prevents re-reward after undo restore', () {
      controller.rewardForNewlyCompletedWords({'FORK', 'KNIFE'});
      controller.seedCompletedWords({'FORK'});

      final reward = controller.rewardForNewlyCompletedWords({'FORK', 'KNIFE'});

      expect(reward, isNotNull);
      expect(reward!.newlyCompletedWords, {'KNIFE'});
    });
  });
}
