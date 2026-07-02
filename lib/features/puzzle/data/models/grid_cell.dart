class GridCell {
  const GridCell({
    required this.row,
    required this.col,
    required this.letter,
  });

  final int row;
  final int col;
  final String letter;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCell && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col):$letter';
}
