class WordCompletionReward {
  const WordCompletionReward({required this.newlyCompletedWords});

  final Set<String> newlyCompletedWords;
}

class WordCompletionFxController {
  final Set<String> _completedWordKeys = {};

  WordCompletionReward? rewardForNewlyCompletedWords(Set<String> currentCompleted) {
    final normalized = currentCompleted.map((word) => word.toUpperCase()).toSet();
    final newly = normalized.difference(_completedWordKeys);
    if (newly.isEmpty) {
      return null;
    }

    _completedWordKeys.addAll(newly);
    return WordCompletionReward(newlyCompletedWords: newly);
  }

  void seedCompletedWords(Set<String> alreadyCompleted) {
    _completedWordKeys
      ..clear()
      ..addAll(alreadyCompleted.map((word) => word.toUpperCase()));
  }

  void reset() {
    _completedWordKeys.clear();
  }
}
