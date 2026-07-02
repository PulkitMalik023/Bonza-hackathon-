class PieceCell {
  const PieceCell({
    required this.letter,
    required this.rowOffset,
    required this.colOffset,
  });

  final String letter;
  final int rowOffset;
  final int colOffset;
}
