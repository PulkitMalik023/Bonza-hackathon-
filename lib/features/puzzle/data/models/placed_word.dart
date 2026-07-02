enum WordDirection {
  horizontal,
  vertical,
}

class PlacedWord {
  const PlacedWord({
    required this.word,
    required this.row,
    required this.col,
    required this.direction,
  });

  final String word;
  final int row;
  final int col;
  final WordDirection direction;

  @override
  String toString() => '$word @ ($row,$col) ${direction.name}';
}
