enum WordDirection {
  horizontal,
  vertical,
}

class WordPlacement {
  const WordPlacement({
    required this.word,
    required this.startRow,
    required this.startCol,
    required this.direction,
  });

  final String word;
  final int startRow;
  final int startCol;
  final WordDirection direction;

  @override
  String toString() =>
      '$word @ ($startRow,$startCol) ${direction.name}';
}
